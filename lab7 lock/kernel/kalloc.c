// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run {
  struct run *next;
};

struct {
  struct spinlock lock;
  struct run *freelist;
} kmem[NCPU];

static char names[NCPU][7] = 
{
  "kmem 0", 
  "kmem 1",
  "kmem 2",
  "kmem 3",
  "kmem 4",
  "kmem 5",
  "kmem 6",
  "kmem 7"
};

void
kinit()
{
  for (int i = 0; i < NCPU; i++)
    initlock(&kmem[i].lock, names[i]);
  
  freerange(end, (void*)PHYSTOP);
}

void
freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char*)PGROUNDUP((uint64)pa_start);
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    kfree(p);
}

// Free the page of physical memory pointed at by v,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);

  r = (struct run*)pa;

  // get hartid
  push_off();
  int i = cpuid();

  acquire(&kmem[i].lock);
  r->next = kmem[i].freelist;
  kmem[i].freelist = r;
  release(&kmem[i].lock);
  pop_off();
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r, *r_other, *p;
  int len, steal, remain, ok;

  // get hartid
  push_off();
  int i = cpuid();

  acquire(&kmem[i].lock);
  r = kmem[i].freelist;
  if(r)
    kmem[i].freelist = r->next;
  else
  {
    ok = 0;
    // search for another cpu whose freelist is not empty
    for (int j = i + 1; j != i; j = (j + 1) % NCPU)
    {
        acquire(&kmem[j].lock);
        r_other = kmem[j].freelist;
        if (r_other)
        {
          // count list length
          len = 0;
          for (; r_other != 0; r_other = r_other->next)
            len++;
          // steal half of the list, rounding up
          remain = len / 2;
          steal = len - remain;
          r_other = kmem[j].freelist;
          for (; steal > 0; steal--)
          {
            p = r_other->next;
            if (steal == 1)
              r_other->next = 0;
            r_other = p;
          }   
          // allocate the first block, insert the reset to i's freelist
          r = kmem[j].freelist;
          kmem[i].freelist = r->next;
          // update j's freelist
          kmem[j].freelist = r_other;
          ok = 1;
        }
        release(&kmem[j].lock);
        if (ok)
          break;
    }
  }
  release(&kmem[i].lock);
  pop_off(); 

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
  return (void*)r;
}
