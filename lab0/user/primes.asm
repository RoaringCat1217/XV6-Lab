
user/_primes：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <work_fn>:
    }
    work_fn(prime, upstream, downstream);
}

void work_fn(int prime, int upstream, int downstream)
{
   0:	715d                	addi	sp,sp,-80
   2:	e486                	sd	ra,72(sp)
   4:	e0a2                	sd	s0,64(sp)
   6:	fc26                	sd	s1,56(sp)
   8:	f84a                	sd	s2,48(sp)
   a:	f44e                	sd	s3,40(sp)
   c:	f052                	sd	s4,32(sp)
   e:	ec56                	sd	s5,24(sp)
  10:	0880                	addi	s0,sp,80
  12:	84aa                	mv	s1,a0
  14:	892e                	mv	s2,a1
  16:	89b2                	mv	s3,a2
    int buf;
    while (read(upstream, &buf, sizeof(buf)) != 0)
    {
        if (buf % prime != 0 || buf == prime)
        {
            if (downstream == -1)
  18:	5a7d                	li	s4,-1
                fprintf(1, "prime %d\n", buf);
  1a:	00001a97          	auipc	s5,0x1
  1e:	92ea8a93          	addi	s5,s5,-1746 # 948 <malloc+0xe8>
    while (read(upstream, &buf, sizeof(buf)) != 0)
  22:	a819                	j	38 <work_fn+0x38>
            if (downstream == -1)
  24:	03498b63          	beq	s3,s4,5a <work_fn+0x5a>
            else
                write(downstream, &buf, sizeof(buf));
  28:	4611                	li	a2,4
  2a:	fbc40593          	addi	a1,s0,-68
  2e:	854e                	mv	a0,s3
  30:	00000097          	auipc	ra,0x0
  34:	41a080e7          	jalr	1050(ra) # 44a <write>
    while (read(upstream, &buf, sizeof(buf)) != 0)
  38:	4611                	li	a2,4
  3a:	fbc40593          	addi	a1,s0,-68
  3e:	854a                	mv	a0,s2
  40:	00000097          	auipc	ra,0x0
  44:	402080e7          	jalr	1026(ra) # 442 <read>
  48:	c105                	beqz	a0,68 <work_fn+0x68>
        if (buf % prime != 0 || buf == prime)
  4a:	fbc42603          	lw	a2,-68(s0)
  4e:	029667bb          	remw	a5,a2,s1
  52:	fbe9                	bnez	a5,24 <work_fn+0x24>
  54:	fe9612e3          	bne	a2,s1,38 <work_fn+0x38>
  58:	b7f1                	j	24 <work_fn+0x24>
                fprintf(1, "prime %d\n", buf);
  5a:	85d6                	mv	a1,s5
  5c:	4505                	li	a0,1
  5e:	00000097          	auipc	ra,0x0
  62:	716080e7          	jalr	1814(ra) # 774 <fprintf>
  66:	bfc9                	j	38 <work_fn+0x38>
        }
    }
    close(upstream);
  68:	854a                	mv	a0,s2
  6a:	00000097          	auipc	ra,0x0
  6e:	3e8080e7          	jalr	1000(ra) # 452 <close>
    close(downstream);
  72:	854e                	mv	a0,s3
  74:	00000097          	auipc	ra,0x0
  78:	3de080e7          	jalr	990(ra) # 452 <close>
    wait(0);
  7c:	4501                	li	a0,0
  7e:	00000097          	auipc	ra,0x0
  82:	3b4080e7          	jalr	948(ra) # 432 <wait>
    exit(0);
  86:	4501                	li	a0,0
  88:	00000097          	auipc	ra,0x0
  8c:	3a2080e7          	jalr	930(ra) # 42a <exit>

0000000000000090 <setup_fn>:
{
  90:	7139                	addi	sp,sp,-64
  92:	fc06                	sd	ra,56(sp)
  94:	f822                	sd	s0,48(sp)
  96:	f426                	sd	s1,40(sp)
  98:	f04a                	sd	s2,32(sp)
  9a:	ec4e                	sd	s3,24(sp)
  9c:	e852                	sd	s4,16(sp)
  9e:	0080                	addi	s0,sp,64
  a0:	89b2                	mv	s3,a2
    int prime = primes[idx], p[2], downstream = -1;
  a2:	00259793          	slli	a5,a1,0x2
  a6:	97aa                	add	a5,a5,a0
  a8:	0007aa03          	lw	s4,0(a5)
    if (idx < N_PRIMES - 1)
  ac:	4785                	li	a5,1
    int prime = primes[idx], p[2], downstream = -1;
  ae:	567d                	li	a2,-1
    if (idx < N_PRIMES - 1)
  b0:	00b7d863          	bge	a5,a1,c0 <setup_fn+0x30>
    work_fn(prime, upstream, downstream);
  b4:	85ce                	mv	a1,s3
  b6:	8552                	mv	a0,s4
  b8:	00000097          	auipc	ra,0x0
  bc:	f48080e7          	jalr	-184(ra) # 0 <work_fn>
  c0:	892a                	mv	s2,a0
  c2:	84ae                	mv	s1,a1
        pipe(p);
  c4:	fc840513          	addi	a0,s0,-56
  c8:	00000097          	auipc	ra,0x0
  cc:	372080e7          	jalr	882(ra) # 43a <pipe>
        if (fork() == 0)
  d0:	00000097          	auipc	ra,0x0
  d4:	352080e7          	jalr	850(ra) # 422 <fork>
  d8:	c911                	beqz	a0,ec <setup_fn+0x5c>
        close(p[0]);
  da:	fc842503          	lw	a0,-56(s0)
  de:	00000097          	auipc	ra,0x0
  e2:	374080e7          	jalr	884(ra) # 452 <close>
        downstream = p[1];
  e6:	fcc42603          	lw	a2,-52(s0)
  ea:	b7e9                	j	b4 <setup_fn+0x24>
            close(p[1]);
  ec:	fcc42503          	lw	a0,-52(s0)
  f0:	00000097          	auipc	ra,0x0
  f4:	362080e7          	jalr	866(ra) # 452 <close>
            setup_fn(primes, idx + 1, p[0]);
  f8:	fc842603          	lw	a2,-56(s0)
  fc:	0014859b          	addiw	a1,s1,1
 100:	854a                	mv	a0,s2
 102:	00000097          	auipc	ra,0x0
 106:	f8e080e7          	jalr	-114(ra) # 90 <setup_fn>

000000000000010a <main>:
}

int main(int argc, char *argv[])
{
 10a:	7139                	addi	sp,sp,-64
 10c:	fc06                	sd	ra,56(sp)
 10e:	f822                	sd	s0,48(sp)
 110:	f426                	sd	s1,40(sp)
 112:	0080                	addi	s0,sp,64
    int primes[] = {2, 3, 5}, p[2], i;
 114:	4789                	li	a5,2
 116:	fcf42823          	sw	a5,-48(s0)
 11a:	478d                	li	a5,3
 11c:	fcf42a23          	sw	a5,-44(s0)
 120:	4795                	li	a5,5
 122:	fcf42c23          	sw	a5,-40(s0)
    pipe(p);
 126:	fc840513          	addi	a0,s0,-56
 12a:	00000097          	auipc	ra,0x0
 12e:	310080e7          	jalr	784(ra) # 43a <pipe>
    if (fork() == 0)
 132:	00000097          	auipc	ra,0x0
 136:	2f0080e7          	jalr	752(ra) # 422 <fork>
 13a:	e105                	bnez	a0,15a <main+0x50>
    {
        close(p[1]);
 13c:	fcc42503          	lw	a0,-52(s0)
 140:	00000097          	auipc	ra,0x0
 144:	312080e7          	jalr	786(ra) # 452 <close>
        setup_fn(primes, 0, p[0]);
 148:	fc842603          	lw	a2,-56(s0)
 14c:	4581                	li	a1,0
 14e:	fd040513          	addi	a0,s0,-48
 152:	00000097          	auipc	ra,0x0
 156:	f3e080e7          	jalr	-194(ra) # 90 <setup_fn>
    }
    else
    {
        close(p[0]);
 15a:	fc842503          	lw	a0,-56(s0)
 15e:	00000097          	auipc	ra,0x0
 162:	2f4080e7          	jalr	756(ra) # 452 <close>
        for (i = 2; i <= 35; i++)
 166:	4789                	li	a5,2
 168:	fcf42223          	sw	a5,-60(s0)
 16c:	02300493          	li	s1,35
            write(p[1], &i, sizeof(i));
 170:	4611                	li	a2,4
 172:	fc440593          	addi	a1,s0,-60
 176:	fcc42503          	lw	a0,-52(s0)
 17a:	00000097          	auipc	ra,0x0
 17e:	2d0080e7          	jalr	720(ra) # 44a <write>
        for (i = 2; i <= 35; i++)
 182:	fc442783          	lw	a5,-60(s0)
 186:	2785                	addiw	a5,a5,1
 188:	0007871b          	sext.w	a4,a5
 18c:	fcf42223          	sw	a5,-60(s0)
 190:	fee4d0e3          	bge	s1,a4,170 <main+0x66>
    }
    close(p[1]);
 194:	fcc42503          	lw	a0,-52(s0)
 198:	00000097          	auipc	ra,0x0
 19c:	2ba080e7          	jalr	698(ra) # 452 <close>
    wait(0);
 1a0:	4501                	li	a0,0
 1a2:	00000097          	auipc	ra,0x0
 1a6:	290080e7          	jalr	656(ra) # 432 <wait>
    exit(0);
 1aa:	4501                	li	a0,0
 1ac:	00000097          	auipc	ra,0x0
 1b0:	27e080e7          	jalr	638(ra) # 42a <exit>

00000000000001b4 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 1b4:	1141                	addi	sp,sp,-16
 1b6:	e422                	sd	s0,8(sp)
 1b8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 1ba:	87aa                	mv	a5,a0
 1bc:	0585                	addi	a1,a1,1
 1be:	0785                	addi	a5,a5,1
 1c0:	fff5c703          	lbu	a4,-1(a1)
 1c4:	fee78fa3          	sb	a4,-1(a5)
 1c8:	fb75                	bnez	a4,1bc <strcpy+0x8>
    ;
  return os;
}
 1ca:	6422                	ld	s0,8(sp)
 1cc:	0141                	addi	sp,sp,16
 1ce:	8082                	ret

00000000000001d0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 1d0:	1141                	addi	sp,sp,-16
 1d2:	e422                	sd	s0,8(sp)
 1d4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 1d6:	00054783          	lbu	a5,0(a0)
 1da:	cb91                	beqz	a5,1ee <strcmp+0x1e>
 1dc:	0005c703          	lbu	a4,0(a1)
 1e0:	00f71763          	bne	a4,a5,1ee <strcmp+0x1e>
    p++, q++;
 1e4:	0505                	addi	a0,a0,1
 1e6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 1e8:	00054783          	lbu	a5,0(a0)
 1ec:	fbe5                	bnez	a5,1dc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1ee:	0005c503          	lbu	a0,0(a1)
}
 1f2:	40a7853b          	subw	a0,a5,a0
 1f6:	6422                	ld	s0,8(sp)
 1f8:	0141                	addi	sp,sp,16
 1fa:	8082                	ret

00000000000001fc <strlen>:

uint
strlen(const char *s)
{
 1fc:	1141                	addi	sp,sp,-16
 1fe:	e422                	sd	s0,8(sp)
 200:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 202:	00054783          	lbu	a5,0(a0)
 206:	cf91                	beqz	a5,222 <strlen+0x26>
 208:	0505                	addi	a0,a0,1
 20a:	87aa                	mv	a5,a0
 20c:	4685                	li	a3,1
 20e:	9e89                	subw	a3,a3,a0
 210:	00f6853b          	addw	a0,a3,a5
 214:	0785                	addi	a5,a5,1
 216:	fff7c703          	lbu	a4,-1(a5)
 21a:	fb7d                	bnez	a4,210 <strlen+0x14>
    ;
  return n;
}
 21c:	6422                	ld	s0,8(sp)
 21e:	0141                	addi	sp,sp,16
 220:	8082                	ret
  for(n = 0; s[n]; n++)
 222:	4501                	li	a0,0
 224:	bfe5                	j	21c <strlen+0x20>

0000000000000226 <memset>:

void*
memset(void *dst, int c, uint n)
{
 226:	1141                	addi	sp,sp,-16
 228:	e422                	sd	s0,8(sp)
 22a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 22c:	ce09                	beqz	a2,246 <memset+0x20>
 22e:	87aa                	mv	a5,a0
 230:	fff6071b          	addiw	a4,a2,-1
 234:	1702                	slli	a4,a4,0x20
 236:	9301                	srli	a4,a4,0x20
 238:	0705                	addi	a4,a4,1
 23a:	972a                	add	a4,a4,a0
    cdst[i] = c;
 23c:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 240:	0785                	addi	a5,a5,1
 242:	fee79de3          	bne	a5,a4,23c <memset+0x16>
  }
  return dst;
}
 246:	6422                	ld	s0,8(sp)
 248:	0141                	addi	sp,sp,16
 24a:	8082                	ret

000000000000024c <strchr>:

char*
strchr(const char *s, char c)
{
 24c:	1141                	addi	sp,sp,-16
 24e:	e422                	sd	s0,8(sp)
 250:	0800                	addi	s0,sp,16
  for(; *s; s++)
 252:	00054783          	lbu	a5,0(a0)
 256:	cb99                	beqz	a5,26c <strchr+0x20>
    if(*s == c)
 258:	00f58763          	beq	a1,a5,266 <strchr+0x1a>
  for(; *s; s++)
 25c:	0505                	addi	a0,a0,1
 25e:	00054783          	lbu	a5,0(a0)
 262:	fbfd                	bnez	a5,258 <strchr+0xc>
      return (char*)s;
  return 0;
 264:	4501                	li	a0,0
}
 266:	6422                	ld	s0,8(sp)
 268:	0141                	addi	sp,sp,16
 26a:	8082                	ret
  return 0;
 26c:	4501                	li	a0,0
 26e:	bfe5                	j	266 <strchr+0x1a>

0000000000000270 <gets>:

char*
gets(char *buf, int max)
{
 270:	711d                	addi	sp,sp,-96
 272:	ec86                	sd	ra,88(sp)
 274:	e8a2                	sd	s0,80(sp)
 276:	e4a6                	sd	s1,72(sp)
 278:	e0ca                	sd	s2,64(sp)
 27a:	fc4e                	sd	s3,56(sp)
 27c:	f852                	sd	s4,48(sp)
 27e:	f456                	sd	s5,40(sp)
 280:	f05a                	sd	s6,32(sp)
 282:	ec5e                	sd	s7,24(sp)
 284:	1080                	addi	s0,sp,96
 286:	8baa                	mv	s7,a0
 288:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 28a:	892a                	mv	s2,a0
 28c:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 28e:	4aa9                	li	s5,10
 290:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 292:	89a6                	mv	s3,s1
 294:	2485                	addiw	s1,s1,1
 296:	0344d863          	bge	s1,s4,2c6 <gets+0x56>
    cc = read(0, &c, 1);
 29a:	4605                	li	a2,1
 29c:	faf40593          	addi	a1,s0,-81
 2a0:	4501                	li	a0,0
 2a2:	00000097          	auipc	ra,0x0
 2a6:	1a0080e7          	jalr	416(ra) # 442 <read>
    if(cc < 1)
 2aa:	00a05e63          	blez	a0,2c6 <gets+0x56>
    buf[i++] = c;
 2ae:	faf44783          	lbu	a5,-81(s0)
 2b2:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 2b6:	01578763          	beq	a5,s5,2c4 <gets+0x54>
 2ba:	0905                	addi	s2,s2,1
 2bc:	fd679be3          	bne	a5,s6,292 <gets+0x22>
  for(i=0; i+1 < max; ){
 2c0:	89a6                	mv	s3,s1
 2c2:	a011                	j	2c6 <gets+0x56>
 2c4:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 2c6:	99de                	add	s3,s3,s7
 2c8:	00098023          	sb	zero,0(s3)
  return buf;
}
 2cc:	855e                	mv	a0,s7
 2ce:	60e6                	ld	ra,88(sp)
 2d0:	6446                	ld	s0,80(sp)
 2d2:	64a6                	ld	s1,72(sp)
 2d4:	6906                	ld	s2,64(sp)
 2d6:	79e2                	ld	s3,56(sp)
 2d8:	7a42                	ld	s4,48(sp)
 2da:	7aa2                	ld	s5,40(sp)
 2dc:	7b02                	ld	s6,32(sp)
 2de:	6be2                	ld	s7,24(sp)
 2e0:	6125                	addi	sp,sp,96
 2e2:	8082                	ret

00000000000002e4 <stat>:

int
stat(const char *n, struct stat *st)
{
 2e4:	1101                	addi	sp,sp,-32
 2e6:	ec06                	sd	ra,24(sp)
 2e8:	e822                	sd	s0,16(sp)
 2ea:	e426                	sd	s1,8(sp)
 2ec:	e04a                	sd	s2,0(sp)
 2ee:	1000                	addi	s0,sp,32
 2f0:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2f2:	4581                	li	a1,0
 2f4:	00000097          	auipc	ra,0x0
 2f8:	176080e7          	jalr	374(ra) # 46a <open>
  if(fd < 0)
 2fc:	02054563          	bltz	a0,326 <stat+0x42>
 300:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 302:	85ca                	mv	a1,s2
 304:	00000097          	auipc	ra,0x0
 308:	17e080e7          	jalr	382(ra) # 482 <fstat>
 30c:	892a                	mv	s2,a0
  close(fd);
 30e:	8526                	mv	a0,s1
 310:	00000097          	auipc	ra,0x0
 314:	142080e7          	jalr	322(ra) # 452 <close>
  return r;
}
 318:	854a                	mv	a0,s2
 31a:	60e2                	ld	ra,24(sp)
 31c:	6442                	ld	s0,16(sp)
 31e:	64a2                	ld	s1,8(sp)
 320:	6902                	ld	s2,0(sp)
 322:	6105                	addi	sp,sp,32
 324:	8082                	ret
    return -1;
 326:	597d                	li	s2,-1
 328:	bfc5                	j	318 <stat+0x34>

000000000000032a <atoi>:

int
atoi(const char *s)
{
 32a:	1141                	addi	sp,sp,-16
 32c:	e422                	sd	s0,8(sp)
 32e:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 330:	00054603          	lbu	a2,0(a0)
 334:	fd06079b          	addiw	a5,a2,-48
 338:	0ff7f793          	andi	a5,a5,255
 33c:	4725                	li	a4,9
 33e:	02f76963          	bltu	a4,a5,370 <atoi+0x46>
 342:	86aa                	mv	a3,a0
  n = 0;
 344:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 346:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 348:	0685                	addi	a3,a3,1
 34a:	0025179b          	slliw	a5,a0,0x2
 34e:	9fa9                	addw	a5,a5,a0
 350:	0017979b          	slliw	a5,a5,0x1
 354:	9fb1                	addw	a5,a5,a2
 356:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 35a:	0006c603          	lbu	a2,0(a3)
 35e:	fd06071b          	addiw	a4,a2,-48
 362:	0ff77713          	andi	a4,a4,255
 366:	fee5f1e3          	bgeu	a1,a4,348 <atoi+0x1e>
  return n;
}
 36a:	6422                	ld	s0,8(sp)
 36c:	0141                	addi	sp,sp,16
 36e:	8082                	ret
  n = 0;
 370:	4501                	li	a0,0
 372:	bfe5                	j	36a <atoi+0x40>

0000000000000374 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 374:	1141                	addi	sp,sp,-16
 376:	e422                	sd	s0,8(sp)
 378:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 37a:	02b57663          	bgeu	a0,a1,3a6 <memmove+0x32>
    while(n-- > 0)
 37e:	02c05163          	blez	a2,3a0 <memmove+0x2c>
 382:	fff6079b          	addiw	a5,a2,-1
 386:	1782                	slli	a5,a5,0x20
 388:	9381                	srli	a5,a5,0x20
 38a:	0785                	addi	a5,a5,1
 38c:	97aa                	add	a5,a5,a0
  dst = vdst;
 38e:	872a                	mv	a4,a0
      *dst++ = *src++;
 390:	0585                	addi	a1,a1,1
 392:	0705                	addi	a4,a4,1
 394:	fff5c683          	lbu	a3,-1(a1)
 398:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 39c:	fee79ae3          	bne	a5,a4,390 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 3a0:	6422                	ld	s0,8(sp)
 3a2:	0141                	addi	sp,sp,16
 3a4:	8082                	ret
    dst += n;
 3a6:	00c50733          	add	a4,a0,a2
    src += n;
 3aa:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 3ac:	fec05ae3          	blez	a2,3a0 <memmove+0x2c>
 3b0:	fff6079b          	addiw	a5,a2,-1
 3b4:	1782                	slli	a5,a5,0x20
 3b6:	9381                	srli	a5,a5,0x20
 3b8:	fff7c793          	not	a5,a5
 3bc:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 3be:	15fd                	addi	a1,a1,-1
 3c0:	177d                	addi	a4,a4,-1
 3c2:	0005c683          	lbu	a3,0(a1)
 3c6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 3ca:	fee79ae3          	bne	a5,a4,3be <memmove+0x4a>
 3ce:	bfc9                	j	3a0 <memmove+0x2c>

00000000000003d0 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 3d0:	1141                	addi	sp,sp,-16
 3d2:	e422                	sd	s0,8(sp)
 3d4:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 3d6:	ca05                	beqz	a2,406 <memcmp+0x36>
 3d8:	fff6069b          	addiw	a3,a2,-1
 3dc:	1682                	slli	a3,a3,0x20
 3de:	9281                	srli	a3,a3,0x20
 3e0:	0685                	addi	a3,a3,1
 3e2:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 3e4:	00054783          	lbu	a5,0(a0)
 3e8:	0005c703          	lbu	a4,0(a1)
 3ec:	00e79863          	bne	a5,a4,3fc <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3f0:	0505                	addi	a0,a0,1
    p2++;
 3f2:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3f4:	fed518e3          	bne	a0,a3,3e4 <memcmp+0x14>
  }
  return 0;
 3f8:	4501                	li	a0,0
 3fa:	a019                	j	400 <memcmp+0x30>
      return *p1 - *p2;
 3fc:	40e7853b          	subw	a0,a5,a4
}
 400:	6422                	ld	s0,8(sp)
 402:	0141                	addi	sp,sp,16
 404:	8082                	ret
  return 0;
 406:	4501                	li	a0,0
 408:	bfe5                	j	400 <memcmp+0x30>

000000000000040a <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 40a:	1141                	addi	sp,sp,-16
 40c:	e406                	sd	ra,8(sp)
 40e:	e022                	sd	s0,0(sp)
 410:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 412:	00000097          	auipc	ra,0x0
 416:	f62080e7          	jalr	-158(ra) # 374 <memmove>
}
 41a:	60a2                	ld	ra,8(sp)
 41c:	6402                	ld	s0,0(sp)
 41e:	0141                	addi	sp,sp,16
 420:	8082                	ret

0000000000000422 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 422:	4885                	li	a7,1
 ecall
 424:	00000073          	ecall
 ret
 428:	8082                	ret

000000000000042a <exit>:
.global exit
exit:
 li a7, SYS_exit
 42a:	4889                	li	a7,2
 ecall
 42c:	00000073          	ecall
 ret
 430:	8082                	ret

0000000000000432 <wait>:
.global wait
wait:
 li a7, SYS_wait
 432:	488d                	li	a7,3
 ecall
 434:	00000073          	ecall
 ret
 438:	8082                	ret

000000000000043a <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 43a:	4891                	li	a7,4
 ecall
 43c:	00000073          	ecall
 ret
 440:	8082                	ret

0000000000000442 <read>:
.global read
read:
 li a7, SYS_read
 442:	4895                	li	a7,5
 ecall
 444:	00000073          	ecall
 ret
 448:	8082                	ret

000000000000044a <write>:
.global write
write:
 li a7, SYS_write
 44a:	48c1                	li	a7,16
 ecall
 44c:	00000073          	ecall
 ret
 450:	8082                	ret

0000000000000452 <close>:
.global close
close:
 li a7, SYS_close
 452:	48d5                	li	a7,21
 ecall
 454:	00000073          	ecall
 ret
 458:	8082                	ret

000000000000045a <kill>:
.global kill
kill:
 li a7, SYS_kill
 45a:	4899                	li	a7,6
 ecall
 45c:	00000073          	ecall
 ret
 460:	8082                	ret

0000000000000462 <exec>:
.global exec
exec:
 li a7, SYS_exec
 462:	489d                	li	a7,7
 ecall
 464:	00000073          	ecall
 ret
 468:	8082                	ret

000000000000046a <open>:
.global open
open:
 li a7, SYS_open
 46a:	48bd                	li	a7,15
 ecall
 46c:	00000073          	ecall
 ret
 470:	8082                	ret

0000000000000472 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 472:	48c5                	li	a7,17
 ecall
 474:	00000073          	ecall
 ret
 478:	8082                	ret

000000000000047a <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 47a:	48c9                	li	a7,18
 ecall
 47c:	00000073          	ecall
 ret
 480:	8082                	ret

0000000000000482 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 482:	48a1                	li	a7,8
 ecall
 484:	00000073          	ecall
 ret
 488:	8082                	ret

000000000000048a <link>:
.global link
link:
 li a7, SYS_link
 48a:	48cd                	li	a7,19
 ecall
 48c:	00000073          	ecall
 ret
 490:	8082                	ret

0000000000000492 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 492:	48d1                	li	a7,20
 ecall
 494:	00000073          	ecall
 ret
 498:	8082                	ret

000000000000049a <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 49a:	48a5                	li	a7,9
 ecall
 49c:	00000073          	ecall
 ret
 4a0:	8082                	ret

00000000000004a2 <dup>:
.global dup
dup:
 li a7, SYS_dup
 4a2:	48a9                	li	a7,10
 ecall
 4a4:	00000073          	ecall
 ret
 4a8:	8082                	ret

00000000000004aa <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 4aa:	48ad                	li	a7,11
 ecall
 4ac:	00000073          	ecall
 ret
 4b0:	8082                	ret

00000000000004b2 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 4b2:	48b1                	li	a7,12
 ecall
 4b4:	00000073          	ecall
 ret
 4b8:	8082                	ret

00000000000004ba <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 4ba:	48b5                	li	a7,13
 ecall
 4bc:	00000073          	ecall
 ret
 4c0:	8082                	ret

00000000000004c2 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 4c2:	48b9                	li	a7,14
 ecall
 4c4:	00000073          	ecall
 ret
 4c8:	8082                	ret

00000000000004ca <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 4ca:	1101                	addi	sp,sp,-32
 4cc:	ec06                	sd	ra,24(sp)
 4ce:	e822                	sd	s0,16(sp)
 4d0:	1000                	addi	s0,sp,32
 4d2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 4d6:	4605                	li	a2,1
 4d8:	fef40593          	addi	a1,s0,-17
 4dc:	00000097          	auipc	ra,0x0
 4e0:	f6e080e7          	jalr	-146(ra) # 44a <write>
}
 4e4:	60e2                	ld	ra,24(sp)
 4e6:	6442                	ld	s0,16(sp)
 4e8:	6105                	addi	sp,sp,32
 4ea:	8082                	ret

00000000000004ec <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4ec:	7139                	addi	sp,sp,-64
 4ee:	fc06                	sd	ra,56(sp)
 4f0:	f822                	sd	s0,48(sp)
 4f2:	f426                	sd	s1,40(sp)
 4f4:	f04a                	sd	s2,32(sp)
 4f6:	ec4e                	sd	s3,24(sp)
 4f8:	0080                	addi	s0,sp,64
 4fa:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4fc:	c299                	beqz	a3,502 <printint+0x16>
 4fe:	0805c863          	bltz	a1,58e <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 502:	2581                	sext.w	a1,a1
  neg = 0;
 504:	4881                	li	a7,0
 506:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 50a:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 50c:	2601                	sext.w	a2,a2
 50e:	00000517          	auipc	a0,0x0
 512:	45250513          	addi	a0,a0,1106 # 960 <digits>
 516:	883a                	mv	a6,a4
 518:	2705                	addiw	a4,a4,1
 51a:	02c5f7bb          	remuw	a5,a1,a2
 51e:	1782                	slli	a5,a5,0x20
 520:	9381                	srli	a5,a5,0x20
 522:	97aa                	add	a5,a5,a0
 524:	0007c783          	lbu	a5,0(a5)
 528:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 52c:	0005879b          	sext.w	a5,a1
 530:	02c5d5bb          	divuw	a1,a1,a2
 534:	0685                	addi	a3,a3,1
 536:	fec7f0e3          	bgeu	a5,a2,516 <printint+0x2a>
  if(neg)
 53a:	00088b63          	beqz	a7,550 <printint+0x64>
    buf[i++] = '-';
 53e:	fd040793          	addi	a5,s0,-48
 542:	973e                	add	a4,a4,a5
 544:	02d00793          	li	a5,45
 548:	fef70823          	sb	a5,-16(a4)
 54c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 550:	02e05863          	blez	a4,580 <printint+0x94>
 554:	fc040793          	addi	a5,s0,-64
 558:	00e78933          	add	s2,a5,a4
 55c:	fff78993          	addi	s3,a5,-1
 560:	99ba                	add	s3,s3,a4
 562:	377d                	addiw	a4,a4,-1
 564:	1702                	slli	a4,a4,0x20
 566:	9301                	srli	a4,a4,0x20
 568:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 56c:	fff94583          	lbu	a1,-1(s2)
 570:	8526                	mv	a0,s1
 572:	00000097          	auipc	ra,0x0
 576:	f58080e7          	jalr	-168(ra) # 4ca <putc>
  while(--i >= 0)
 57a:	197d                	addi	s2,s2,-1
 57c:	ff3918e3          	bne	s2,s3,56c <printint+0x80>
}
 580:	70e2                	ld	ra,56(sp)
 582:	7442                	ld	s0,48(sp)
 584:	74a2                	ld	s1,40(sp)
 586:	7902                	ld	s2,32(sp)
 588:	69e2                	ld	s3,24(sp)
 58a:	6121                	addi	sp,sp,64
 58c:	8082                	ret
    x = -xx;
 58e:	40b005bb          	negw	a1,a1
    neg = 1;
 592:	4885                	li	a7,1
    x = -xx;
 594:	bf8d                	j	506 <printint+0x1a>

0000000000000596 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 596:	7119                	addi	sp,sp,-128
 598:	fc86                	sd	ra,120(sp)
 59a:	f8a2                	sd	s0,112(sp)
 59c:	f4a6                	sd	s1,104(sp)
 59e:	f0ca                	sd	s2,96(sp)
 5a0:	ecce                	sd	s3,88(sp)
 5a2:	e8d2                	sd	s4,80(sp)
 5a4:	e4d6                	sd	s5,72(sp)
 5a6:	e0da                	sd	s6,64(sp)
 5a8:	fc5e                	sd	s7,56(sp)
 5aa:	f862                	sd	s8,48(sp)
 5ac:	f466                	sd	s9,40(sp)
 5ae:	f06a                	sd	s10,32(sp)
 5b0:	ec6e                	sd	s11,24(sp)
 5b2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 5b4:	0005c903          	lbu	s2,0(a1)
 5b8:	18090f63          	beqz	s2,756 <vprintf+0x1c0>
 5bc:	8aaa                	mv	s5,a0
 5be:	8b32                	mv	s6,a2
 5c0:	00158493          	addi	s1,a1,1
  state = 0;
 5c4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 5c6:	02500a13          	li	s4,37
      if(c == 'd'){
 5ca:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 5ce:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 5d2:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 5d6:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5da:	00000b97          	auipc	s7,0x0
 5de:	386b8b93          	addi	s7,s7,902 # 960 <digits>
 5e2:	a839                	j	600 <vprintf+0x6a>
        putc(fd, c);
 5e4:	85ca                	mv	a1,s2
 5e6:	8556                	mv	a0,s5
 5e8:	00000097          	auipc	ra,0x0
 5ec:	ee2080e7          	jalr	-286(ra) # 4ca <putc>
 5f0:	a019                	j	5f6 <vprintf+0x60>
    } else if(state == '%'){
 5f2:	01498f63          	beq	s3,s4,610 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5f6:	0485                	addi	s1,s1,1
 5f8:	fff4c903          	lbu	s2,-1(s1)
 5fc:	14090d63          	beqz	s2,756 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 600:	0009079b          	sext.w	a5,s2
    if(state == 0){
 604:	fe0997e3          	bnez	s3,5f2 <vprintf+0x5c>
      if(c == '%'){
 608:	fd479ee3          	bne	a5,s4,5e4 <vprintf+0x4e>
        state = '%';
 60c:	89be                	mv	s3,a5
 60e:	b7e5                	j	5f6 <vprintf+0x60>
      if(c == 'd'){
 610:	05878063          	beq	a5,s8,650 <vprintf+0xba>
      } else if(c == 'l') {
 614:	05978c63          	beq	a5,s9,66c <vprintf+0xd6>
      } else if(c == 'x') {
 618:	07a78863          	beq	a5,s10,688 <vprintf+0xf2>
      } else if(c == 'p') {
 61c:	09b78463          	beq	a5,s11,6a4 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 620:	07300713          	li	a4,115
 624:	0ce78663          	beq	a5,a4,6f0 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 628:	06300713          	li	a4,99
 62c:	0ee78e63          	beq	a5,a4,728 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 630:	11478863          	beq	a5,s4,740 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 634:	85d2                	mv	a1,s4
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	e92080e7          	jalr	-366(ra) # 4ca <putc>
        putc(fd, c);
 640:	85ca                	mv	a1,s2
 642:	8556                	mv	a0,s5
 644:	00000097          	auipc	ra,0x0
 648:	e86080e7          	jalr	-378(ra) # 4ca <putc>
      }
      state = 0;
 64c:	4981                	li	s3,0
 64e:	b765                	j	5f6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 650:	008b0913          	addi	s2,s6,8
 654:	4685                	li	a3,1
 656:	4629                	li	a2,10
 658:	000b2583          	lw	a1,0(s6)
 65c:	8556                	mv	a0,s5
 65e:	00000097          	auipc	ra,0x0
 662:	e8e080e7          	jalr	-370(ra) # 4ec <printint>
 666:	8b4a                	mv	s6,s2
      state = 0;
 668:	4981                	li	s3,0
 66a:	b771                	j	5f6 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 66c:	008b0913          	addi	s2,s6,8
 670:	4681                	li	a3,0
 672:	4629                	li	a2,10
 674:	000b2583          	lw	a1,0(s6)
 678:	8556                	mv	a0,s5
 67a:	00000097          	auipc	ra,0x0
 67e:	e72080e7          	jalr	-398(ra) # 4ec <printint>
 682:	8b4a                	mv	s6,s2
      state = 0;
 684:	4981                	li	s3,0
 686:	bf85                	j	5f6 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 688:	008b0913          	addi	s2,s6,8
 68c:	4681                	li	a3,0
 68e:	4641                	li	a2,16
 690:	000b2583          	lw	a1,0(s6)
 694:	8556                	mv	a0,s5
 696:	00000097          	auipc	ra,0x0
 69a:	e56080e7          	jalr	-426(ra) # 4ec <printint>
 69e:	8b4a                	mv	s6,s2
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	bf91                	j	5f6 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 6a4:	008b0793          	addi	a5,s6,8
 6a8:	f8f43423          	sd	a5,-120(s0)
 6ac:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 6b0:	03000593          	li	a1,48
 6b4:	8556                	mv	a0,s5
 6b6:	00000097          	auipc	ra,0x0
 6ba:	e14080e7          	jalr	-492(ra) # 4ca <putc>
  putc(fd, 'x');
 6be:	85ea                	mv	a1,s10
 6c0:	8556                	mv	a0,s5
 6c2:	00000097          	auipc	ra,0x0
 6c6:	e08080e7          	jalr	-504(ra) # 4ca <putc>
 6ca:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 6cc:	03c9d793          	srli	a5,s3,0x3c
 6d0:	97de                	add	a5,a5,s7
 6d2:	0007c583          	lbu	a1,0(a5)
 6d6:	8556                	mv	a0,s5
 6d8:	00000097          	auipc	ra,0x0
 6dc:	df2080e7          	jalr	-526(ra) # 4ca <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 6e0:	0992                	slli	s3,s3,0x4
 6e2:	397d                	addiw	s2,s2,-1
 6e4:	fe0914e3          	bnez	s2,6cc <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 6e8:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6ec:	4981                	li	s3,0
 6ee:	b721                	j	5f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 6f0:	008b0993          	addi	s3,s6,8
 6f4:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6f8:	02090163          	beqz	s2,71a <vprintf+0x184>
        while(*s != 0){
 6fc:	00094583          	lbu	a1,0(s2)
 700:	c9a1                	beqz	a1,750 <vprintf+0x1ba>
          putc(fd, *s);
 702:	8556                	mv	a0,s5
 704:	00000097          	auipc	ra,0x0
 708:	dc6080e7          	jalr	-570(ra) # 4ca <putc>
          s++;
 70c:	0905                	addi	s2,s2,1
        while(*s != 0){
 70e:	00094583          	lbu	a1,0(s2)
 712:	f9e5                	bnez	a1,702 <vprintf+0x16c>
        s = va_arg(ap, char*);
 714:	8b4e                	mv	s6,s3
      state = 0;
 716:	4981                	li	s3,0
 718:	bdf9                	j	5f6 <vprintf+0x60>
          s = "(null)";
 71a:	00000917          	auipc	s2,0x0
 71e:	23e90913          	addi	s2,s2,574 # 958 <malloc+0xf8>
        while(*s != 0){
 722:	02800593          	li	a1,40
 726:	bff1                	j	702 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 728:	008b0913          	addi	s2,s6,8
 72c:	000b4583          	lbu	a1,0(s6)
 730:	8556                	mv	a0,s5
 732:	00000097          	auipc	ra,0x0
 736:	d98080e7          	jalr	-616(ra) # 4ca <putc>
 73a:	8b4a                	mv	s6,s2
      state = 0;
 73c:	4981                	li	s3,0
 73e:	bd65                	j	5f6 <vprintf+0x60>
        putc(fd, c);
 740:	85d2                	mv	a1,s4
 742:	8556                	mv	a0,s5
 744:	00000097          	auipc	ra,0x0
 748:	d86080e7          	jalr	-634(ra) # 4ca <putc>
      state = 0;
 74c:	4981                	li	s3,0
 74e:	b565                	j	5f6 <vprintf+0x60>
        s = va_arg(ap, char*);
 750:	8b4e                	mv	s6,s3
      state = 0;
 752:	4981                	li	s3,0
 754:	b54d                	j	5f6 <vprintf+0x60>
    }
  }
}
 756:	70e6                	ld	ra,120(sp)
 758:	7446                	ld	s0,112(sp)
 75a:	74a6                	ld	s1,104(sp)
 75c:	7906                	ld	s2,96(sp)
 75e:	69e6                	ld	s3,88(sp)
 760:	6a46                	ld	s4,80(sp)
 762:	6aa6                	ld	s5,72(sp)
 764:	6b06                	ld	s6,64(sp)
 766:	7be2                	ld	s7,56(sp)
 768:	7c42                	ld	s8,48(sp)
 76a:	7ca2                	ld	s9,40(sp)
 76c:	7d02                	ld	s10,32(sp)
 76e:	6de2                	ld	s11,24(sp)
 770:	6109                	addi	sp,sp,128
 772:	8082                	ret

0000000000000774 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 774:	715d                	addi	sp,sp,-80
 776:	ec06                	sd	ra,24(sp)
 778:	e822                	sd	s0,16(sp)
 77a:	1000                	addi	s0,sp,32
 77c:	e010                	sd	a2,0(s0)
 77e:	e414                	sd	a3,8(s0)
 780:	e818                	sd	a4,16(s0)
 782:	ec1c                	sd	a5,24(s0)
 784:	03043023          	sd	a6,32(s0)
 788:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 78c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 790:	8622                	mv	a2,s0
 792:	00000097          	auipc	ra,0x0
 796:	e04080e7          	jalr	-508(ra) # 596 <vprintf>
}
 79a:	60e2                	ld	ra,24(sp)
 79c:	6442                	ld	s0,16(sp)
 79e:	6161                	addi	sp,sp,80
 7a0:	8082                	ret

00000000000007a2 <printf>:

void
printf(const char *fmt, ...)
{
 7a2:	711d                	addi	sp,sp,-96
 7a4:	ec06                	sd	ra,24(sp)
 7a6:	e822                	sd	s0,16(sp)
 7a8:	1000                	addi	s0,sp,32
 7aa:	e40c                	sd	a1,8(s0)
 7ac:	e810                	sd	a2,16(s0)
 7ae:	ec14                	sd	a3,24(s0)
 7b0:	f018                	sd	a4,32(s0)
 7b2:	f41c                	sd	a5,40(s0)
 7b4:	03043823          	sd	a6,48(s0)
 7b8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 7bc:	00840613          	addi	a2,s0,8
 7c0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 7c4:	85aa                	mv	a1,a0
 7c6:	4505                	li	a0,1
 7c8:	00000097          	auipc	ra,0x0
 7cc:	dce080e7          	jalr	-562(ra) # 596 <vprintf>
}
 7d0:	60e2                	ld	ra,24(sp)
 7d2:	6442                	ld	s0,16(sp)
 7d4:	6125                	addi	sp,sp,96
 7d6:	8082                	ret

00000000000007d8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 7d8:	1141                	addi	sp,sp,-16
 7da:	e422                	sd	s0,8(sp)
 7dc:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 7de:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7e2:	00000797          	auipc	a5,0x0
 7e6:	1967b783          	ld	a5,406(a5) # 978 <freep>
 7ea:	a805                	j	81a <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7ec:	4618                	lw	a4,8(a2)
 7ee:	9db9                	addw	a1,a1,a4
 7f0:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7f4:	6398                	ld	a4,0(a5)
 7f6:	6318                	ld	a4,0(a4)
 7f8:	fee53823          	sd	a4,-16(a0)
 7fc:	a091                	j	840 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7fe:	ff852703          	lw	a4,-8(a0)
 802:	9e39                	addw	a2,a2,a4
 804:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 806:	ff053703          	ld	a4,-16(a0)
 80a:	e398                	sd	a4,0(a5)
 80c:	a099                	j	852 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 80e:	6398                	ld	a4,0(a5)
 810:	00e7e463          	bltu	a5,a4,818 <free+0x40>
 814:	00e6ea63          	bltu	a3,a4,828 <free+0x50>
{
 818:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 81a:	fed7fae3          	bgeu	a5,a3,80e <free+0x36>
 81e:	6398                	ld	a4,0(a5)
 820:	00e6e463          	bltu	a3,a4,828 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 824:	fee7eae3          	bltu	a5,a4,818 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 828:	ff852583          	lw	a1,-8(a0)
 82c:	6390                	ld	a2,0(a5)
 82e:	02059713          	slli	a4,a1,0x20
 832:	9301                	srli	a4,a4,0x20
 834:	0712                	slli	a4,a4,0x4
 836:	9736                	add	a4,a4,a3
 838:	fae60ae3          	beq	a2,a4,7ec <free+0x14>
    bp->s.ptr = p->s.ptr;
 83c:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 840:	4790                	lw	a2,8(a5)
 842:	02061713          	slli	a4,a2,0x20
 846:	9301                	srli	a4,a4,0x20
 848:	0712                	slli	a4,a4,0x4
 84a:	973e                	add	a4,a4,a5
 84c:	fae689e3          	beq	a3,a4,7fe <free+0x26>
  } else
    p->s.ptr = bp;
 850:	e394                	sd	a3,0(a5)
  freep = p;
 852:	00000717          	auipc	a4,0x0
 856:	12f73323          	sd	a5,294(a4) # 978 <freep>
}
 85a:	6422                	ld	s0,8(sp)
 85c:	0141                	addi	sp,sp,16
 85e:	8082                	ret

0000000000000860 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 860:	7139                	addi	sp,sp,-64
 862:	fc06                	sd	ra,56(sp)
 864:	f822                	sd	s0,48(sp)
 866:	f426                	sd	s1,40(sp)
 868:	f04a                	sd	s2,32(sp)
 86a:	ec4e                	sd	s3,24(sp)
 86c:	e852                	sd	s4,16(sp)
 86e:	e456                	sd	s5,8(sp)
 870:	e05a                	sd	s6,0(sp)
 872:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 874:	02051493          	slli	s1,a0,0x20
 878:	9081                	srli	s1,s1,0x20
 87a:	04bd                	addi	s1,s1,15
 87c:	8091                	srli	s1,s1,0x4
 87e:	0014899b          	addiw	s3,s1,1
 882:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 884:	00000517          	auipc	a0,0x0
 888:	0f453503          	ld	a0,244(a0) # 978 <freep>
 88c:	c515                	beqz	a0,8b8 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 88e:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 890:	4798                	lw	a4,8(a5)
 892:	02977f63          	bgeu	a4,s1,8d0 <malloc+0x70>
 896:	8a4e                	mv	s4,s3
 898:	0009871b          	sext.w	a4,s3
 89c:	6685                	lui	a3,0x1
 89e:	00d77363          	bgeu	a4,a3,8a4 <malloc+0x44>
 8a2:	6a05                	lui	s4,0x1
 8a4:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 8a8:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 8ac:	00000917          	auipc	s2,0x0
 8b0:	0cc90913          	addi	s2,s2,204 # 978 <freep>
  if(p == (char*)-1)
 8b4:	5afd                	li	s5,-1
 8b6:	a88d                	j	928 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 8b8:	00000797          	auipc	a5,0x0
 8bc:	0c878793          	addi	a5,a5,200 # 980 <base>
 8c0:	00000717          	auipc	a4,0x0
 8c4:	0af73c23          	sd	a5,184(a4) # 978 <freep>
 8c8:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 8ca:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 8ce:	b7e1                	j	896 <malloc+0x36>
      if(p->s.size == nunits)
 8d0:	02e48b63          	beq	s1,a4,906 <malloc+0xa6>
        p->s.size -= nunits;
 8d4:	4137073b          	subw	a4,a4,s3
 8d8:	c798                	sw	a4,8(a5)
        p += p->s.size;
 8da:	1702                	slli	a4,a4,0x20
 8dc:	9301                	srli	a4,a4,0x20
 8de:	0712                	slli	a4,a4,0x4
 8e0:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 8e2:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 8e6:	00000717          	auipc	a4,0x0
 8ea:	08a73923          	sd	a0,146(a4) # 978 <freep>
      return (void*)(p + 1);
 8ee:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8f2:	70e2                	ld	ra,56(sp)
 8f4:	7442                	ld	s0,48(sp)
 8f6:	74a2                	ld	s1,40(sp)
 8f8:	7902                	ld	s2,32(sp)
 8fa:	69e2                	ld	s3,24(sp)
 8fc:	6a42                	ld	s4,16(sp)
 8fe:	6aa2                	ld	s5,8(sp)
 900:	6b02                	ld	s6,0(sp)
 902:	6121                	addi	sp,sp,64
 904:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 906:	6398                	ld	a4,0(a5)
 908:	e118                	sd	a4,0(a0)
 90a:	bff1                	j	8e6 <malloc+0x86>
  hp->s.size = nu;
 90c:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 910:	0541                	addi	a0,a0,16
 912:	00000097          	auipc	ra,0x0
 916:	ec6080e7          	jalr	-314(ra) # 7d8 <free>
  return freep;
 91a:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 91e:	d971                	beqz	a0,8f2 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 920:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 922:	4798                	lw	a4,8(a5)
 924:	fa9776e3          	bgeu	a4,s1,8d0 <malloc+0x70>
    if(p == freep)
 928:	00093703          	ld	a4,0(s2)
 92c:	853e                	mv	a0,a5
 92e:	fef719e3          	bne	a4,a5,920 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 932:	8552                	mv	a0,s4
 934:	00000097          	auipc	ra,0x0
 938:	b7e080e7          	jalr	-1154(ra) # 4b2 <sbrk>
  if(p == (char*)-1)
 93c:	fd5518e3          	bne	a0,s5,90c <malloc+0xac>
        return 0;
 940:	4501                	li	a0,0
 942:	bf45                	j	8f2 <malloc+0x92>
