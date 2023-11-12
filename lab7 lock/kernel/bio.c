// Buffer cache.
//
// The buffer cache is a linked list of buf structures holding
// cached copies of disk block contents.  Caching disk blocks
// in memory reduces the number of disk reads and also provides
// a synchronization point for disk blocks used by multiple processes.
//
// Interface:
// * To get a buffer for a particular disk block, call bread.
// * After changing buffer data, call bwrite to write it to disk.
// * When done with the buffer, call brelse.
// * Do not use the buffer after calling brelse.
// * Only one process at a time can use a buffer,
//     so do not keep them longer than necessary.


#include "types.h"
#include "param.h"
#include "spinlock.h"
#include "sleeplock.h"
#include "riscv.h"
#include "defs.h"
#include "fs.h"
#include "buf.h"
#include "proc.h"

#define NBUCKET 31

struct {
  struct spinlock lock;
  struct buf buf[NBUF];
} bcache;

static int 
hash(uint dev, uint blockno)
{
  return blockno % NBUCKET;
}

struct 
{
  struct buf *bucket[NBUCKET];
  struct spinlock bucket_locks[NBUCKET];
} hashtable;


void
binit(void)
{
  struct buf *b;

  initlock(&bcache.lock, "bcache");

  
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
  {
    initsleeplock(&b->lock, "buffer");
  }
  for (int i = 0; i < NBUCKET; i++)
  {
    initlock(&hashtable.bucket_locks[i], "bcache bucket");
    hashtable.bucket[i] = 0;
  }
  // place bcache.buf[i] into hashtable.bucket[i]
  for (int i = 0; i < NBUF; i++)
  {
    hashtable.bucket[i] = &bcache.buf[i];
    bcache.buf[i].next = 0;
    bcache.buf[i].refcnt = 0;
    bcache.buf[i].timestamp = 0;
    bcache.buf[i].valid = 0;
    bcache.buf[i].blockno = i;
  }
}

// Look through buffer cache for block on device dev.
// If not found, allocate a buffer.
// In either case, return locked buffer.
static struct buf*
bget(uint dev, uint blockno)
{
  struct buf *b;
  int idx = hash(dev, blockno);
  acquire(&hashtable.bucket_locks[idx]);
  for (b = hashtable.bucket[idx]; b != 0; b = b->next)
  {
    if (b->dev == dev && b->blockno == blockno)
    {
      // already cached
      b->refcnt++;
      release(&hashtable.bucket_locks[idx]);
      acquiresleep(&b->lock);
      return b;
    }
  }

  // try to find a LRU block in current bucket
  uint lru = 0x8fffffff;
  struct buf *lru_buf = 0;
  for (b = hashtable.bucket[idx]; b != 0; b = b->next)
  {
    if (b->refcnt == 0 && b->timestamp < lru)
    {
      lru = b->timestamp;
      lru_buf = b;
    }
  }
  if (lru_buf)
  {
    // replace
    lru_buf->dev = dev;
    lru_buf->blockno = blockno;
    lru_buf->valid = 0;
    lru_buf->refcnt = 1;
    release(&hashtable.bucket_locks[idx]);
    acquiresleep(&lru_buf->lock);
    return lru_buf;
  }

  // try to find a LRU block in the entire bcache
  release(&hashtable.bucket_locks[idx]); // prevent deadlock
  struct spinlock *holding = 0;
  int i_holding = 0;
  int flag = 0;
  acquire(&bcache.lock);
  for (int i = 0; i < NBUCKET; i++)
    if (i != idx)
    {
      acquire(&hashtable.bucket_locks[i]);
      flag = 0;
      for (b = hashtable.bucket[i]; b != 0; b = b->next)
      {
        if (b->refcnt == 0 && b->timestamp < lru)
        {
          lru = b->timestamp;
          lru_buf = b;
          flag = 1;
        }
      }
      if (flag)
      {
        if (holding)
          release(holding);
        holding = &hashtable.bucket_locks[i];
        i_holding = i;
      }
      else
        release(&hashtable.bucket_locks[i]);
    }
  if (lru_buf)
  {
    acquire(&hashtable.bucket_locks[idx]); // prevent deadlock
    struct buf *prev = 0;
    for (b = hashtable.bucket[i_holding]; b != 0; b = b->next)
    {
      if (b == lru_buf)
        break;
      prev = b;
    }
    if (prev)
      prev->next = b->next;
    else
      hashtable.bucket[i_holding] = b->next;
    release(holding);
    lru_buf->next = hashtable.bucket[idx];
    hashtable.bucket[idx] = lru_buf;
    // replace
    lru_buf->dev = dev;
    lru_buf->blockno = blockno;
    lru_buf->valid = 0;
    lru_buf->refcnt = 1;
    release(&hashtable.bucket_locks[idx]);
    release(&bcache.lock);
    acquiresleep(&lru_buf->lock);
    return lru_buf;
  }
  panic("bget: no buffers");
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
  struct buf *b;
  b = bget(dev, blockno);
  if(!b->valid) {
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("bwrite");
  virtio_disk_rw(b, 1);
}

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
  if(!holdingsleep(&b->lock))
    panic("brelse");

  releasesleep(&b->lock);

  int idx = hash(b->dev, b->blockno);

  acquire(&hashtable.bucket_locks[idx]);
  b->refcnt--;
  if (b->refcnt == 0) {
    // no one is waiting for it.
    b->timestamp = ticks;
  }
  
  release(&hashtable.bucket_locks[idx]);
}

void
bpin(struct buf *b) {
  int idx = hash(b->dev, b->blockno);
  acquire(&hashtable.bucket_locks[idx]);
  b->refcnt++;
  release(&hashtable.bucket_locks[idx]);
}

void
bunpin(struct buf *b) {
  int idx = hash(b->dev, b->blockno);
  acquire(&hashtable.bucket_locks[idx]);
  b->refcnt--;
  release(&hashtable.bucket_locks[idx]);
}


