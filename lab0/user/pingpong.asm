
user/_pingpong：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	7179                	addi	sp,sp,-48
   2:	f406                	sd	ra,40(sp)
   4:	f022                	sd	s0,32(sp)
   6:	1800                	addi	s0,sp,48
    if(argc != 1)
   8:	4785                	li	a5,1
   a:	02f50063          	beq	a0,a5,2a <main+0x2a>
    {
        fprintf(2, "usage: pingpong\n");
   e:	00001597          	auipc	a1,0x1
  12:	8ea58593          	addi	a1,a1,-1814 # 8f8 <malloc+0xe4>
  16:	4509                	li	a0,2
  18:	00000097          	auipc	ra,0x0
  1c:	710080e7          	jalr	1808(ra) # 728 <fprintf>
        exit(1);
  20:	4505                	li	a0,1
  22:	00000097          	auipc	ra,0x0
  26:	3bc080e7          	jalr	956(ra) # 3de <exit>
    }   
    int pipe1[2], pipe2[2], pid;
    char byte = 0x7f;
  2a:	07f00793          	li	a5,127
  2e:	fcf40fa3          	sb	a5,-33(s0)
    pipe(pipe1);
  32:	fe840513          	addi	a0,s0,-24
  36:	00000097          	auipc	ra,0x0
  3a:	3b8080e7          	jalr	952(ra) # 3ee <pipe>
    pipe(pipe2);
  3e:	fe040513          	addi	a0,s0,-32
  42:	00000097          	auipc	ra,0x0
  46:	3ac080e7          	jalr	940(ra) # 3ee <pipe>
    if((pid = fork()) < 0)
  4a:	00000097          	auipc	ra,0x0
  4e:	38c080e7          	jalr	908(ra) # 3d6 <fork>
  52:	08054063          	bltz	a0,d2 <main+0xd2>
    {
        fprintf(2, "pingpong: fork error!\n");
        exit(1);
    }
    else if(pid == 0)
  56:	ed41                	bnez	a0,ee <main+0xee>
    {
        close(pipe1[1]);
  58:	fec42503          	lw	a0,-20(s0)
  5c:	00000097          	auipc	ra,0x0
  60:	3aa080e7          	jalr	938(ra) # 406 <close>
        close(pipe2[0]);
  64:	fe042503          	lw	a0,-32(s0)
  68:	00000097          	auipc	ra,0x0
  6c:	39e080e7          	jalr	926(ra) # 406 <close>
        char rec;
        read(pipe1[0], &rec, 1);
  70:	4605                	li	a2,1
  72:	fde40593          	addi	a1,s0,-34
  76:	fe842503          	lw	a0,-24(s0)
  7a:	00000097          	auipc	ra,0x0
  7e:	37c080e7          	jalr	892(ra) # 3f6 <read>
        pid = getpid();
  82:	00000097          	auipc	ra,0x0
  86:	3dc080e7          	jalr	988(ra) # 45e <getpid>
  8a:	862a                	mv	a2,a0
        fprintf(1, "<%d>: received ping\n", pid);
  8c:	00001597          	auipc	a1,0x1
  90:	89c58593          	addi	a1,a1,-1892 # 928 <malloc+0x114>
  94:	4505                	li	a0,1
  96:	00000097          	auipc	ra,0x0
  9a:	692080e7          	jalr	1682(ra) # 728 <fprintf>
        write(pipe2[1], &rec, 1);
  9e:	4605                	li	a2,1
  a0:	fde40593          	addi	a1,s0,-34
  a4:	fe442503          	lw	a0,-28(s0)
  a8:	00000097          	auipc	ra,0x0
  ac:	356080e7          	jalr	854(ra) # 3fe <write>
        close(pipe1[0]);
  b0:	fe842503          	lw	a0,-24(s0)
  b4:	00000097          	auipc	ra,0x0
  b8:	352080e7          	jalr	850(ra) # 406 <close>
        close(pipe2[1]);
  bc:	fe442503          	lw	a0,-28(s0)
  c0:	00000097          	auipc	ra,0x0
  c4:	346080e7          	jalr	838(ra) # 406 <close>
        exit(0);
  c8:	4501                	li	a0,0
  ca:	00000097          	auipc	ra,0x0
  ce:	314080e7          	jalr	788(ra) # 3de <exit>
        fprintf(2, "pingpong: fork error!\n");
  d2:	00001597          	auipc	a1,0x1
  d6:	83e58593          	addi	a1,a1,-1986 # 910 <malloc+0xfc>
  da:	4509                	li	a0,2
  dc:	00000097          	auipc	ra,0x0
  e0:	64c080e7          	jalr	1612(ra) # 728 <fprintf>
        exit(1);
  e4:	4505                	li	a0,1
  e6:	00000097          	auipc	ra,0x0
  ea:	2f8080e7          	jalr	760(ra) # 3de <exit>
    }
    else
    {
        char rec;
        close(pipe1[0]);
  ee:	fe842503          	lw	a0,-24(s0)
  f2:	00000097          	auipc	ra,0x0
  f6:	314080e7          	jalr	788(ra) # 406 <close>
        close(pipe2[1]);
  fa:	fe442503          	lw	a0,-28(s0)
  fe:	00000097          	auipc	ra,0x0
 102:	308080e7          	jalr	776(ra) # 406 <close>
        write(pipe1[1], &byte, 1);
 106:	4605                	li	a2,1
 108:	fdf40593          	addi	a1,s0,-33
 10c:	fec42503          	lw	a0,-20(s0)
 110:	00000097          	auipc	ra,0x0
 114:	2ee080e7          	jalr	750(ra) # 3fe <write>
        read(pipe2[0], &rec, 1);
 118:	4605                	li	a2,1
 11a:	fde40593          	addi	a1,s0,-34
 11e:	fe042503          	lw	a0,-32(s0)
 122:	00000097          	auipc	ra,0x0
 126:	2d4080e7          	jalr	724(ra) # 3f6 <read>
        pid = getpid();
 12a:	00000097          	auipc	ra,0x0
 12e:	334080e7          	jalr	820(ra) # 45e <getpid>
 132:	862a                	mv	a2,a0
        fprintf(1, "<%d>: received pong\n", pid);
 134:	00001597          	auipc	a1,0x1
 138:	80c58593          	addi	a1,a1,-2036 # 940 <malloc+0x12c>
 13c:	4505                	li	a0,1
 13e:	00000097          	auipc	ra,0x0
 142:	5ea080e7          	jalr	1514(ra) # 728 <fprintf>
        close(pipe1[1]);
 146:	fec42503          	lw	a0,-20(s0)
 14a:	00000097          	auipc	ra,0x0
 14e:	2bc080e7          	jalr	700(ra) # 406 <close>
        close(pipe2[0]);
 152:	fe042503          	lw	a0,-32(s0)
 156:	00000097          	auipc	ra,0x0
 15a:	2b0080e7          	jalr	688(ra) # 406 <close>
        exit(0);
 15e:	4501                	li	a0,0
 160:	00000097          	auipc	ra,0x0
 164:	27e080e7          	jalr	638(ra) # 3de <exit>

0000000000000168 <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 168:	1141                	addi	sp,sp,-16
 16a:	e422                	sd	s0,8(sp)
 16c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 16e:	87aa                	mv	a5,a0
 170:	0585                	addi	a1,a1,1
 172:	0785                	addi	a5,a5,1
 174:	fff5c703          	lbu	a4,-1(a1)
 178:	fee78fa3          	sb	a4,-1(a5)
 17c:	fb75                	bnez	a4,170 <strcpy+0x8>
    ;
  return os;
}
 17e:	6422                	ld	s0,8(sp)
 180:	0141                	addi	sp,sp,16
 182:	8082                	ret

0000000000000184 <strcmp>:

int
strcmp(const char *p, const char *q)
{
 184:	1141                	addi	sp,sp,-16
 186:	e422                	sd	s0,8(sp)
 188:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 18a:	00054783          	lbu	a5,0(a0)
 18e:	cb91                	beqz	a5,1a2 <strcmp+0x1e>
 190:	0005c703          	lbu	a4,0(a1)
 194:	00f71763          	bne	a4,a5,1a2 <strcmp+0x1e>
    p++, q++;
 198:	0505                	addi	a0,a0,1
 19a:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 19c:	00054783          	lbu	a5,0(a0)
 1a0:	fbe5                	bnez	a5,190 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 1a2:	0005c503          	lbu	a0,0(a1)
}
 1a6:	40a7853b          	subw	a0,a5,a0
 1aa:	6422                	ld	s0,8(sp)
 1ac:	0141                	addi	sp,sp,16
 1ae:	8082                	ret

00000000000001b0 <strlen>:

uint
strlen(const char *s)
{
 1b0:	1141                	addi	sp,sp,-16
 1b2:	e422                	sd	s0,8(sp)
 1b4:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 1b6:	00054783          	lbu	a5,0(a0)
 1ba:	cf91                	beqz	a5,1d6 <strlen+0x26>
 1bc:	0505                	addi	a0,a0,1
 1be:	87aa                	mv	a5,a0
 1c0:	4685                	li	a3,1
 1c2:	9e89                	subw	a3,a3,a0
 1c4:	00f6853b          	addw	a0,a3,a5
 1c8:	0785                	addi	a5,a5,1
 1ca:	fff7c703          	lbu	a4,-1(a5)
 1ce:	fb7d                	bnez	a4,1c4 <strlen+0x14>
    ;
  return n;
}
 1d0:	6422                	ld	s0,8(sp)
 1d2:	0141                	addi	sp,sp,16
 1d4:	8082                	ret
  for(n = 0; s[n]; n++)
 1d6:	4501                	li	a0,0
 1d8:	bfe5                	j	1d0 <strlen+0x20>

00000000000001da <memset>:

void*
memset(void *dst, int c, uint n)
{
 1da:	1141                	addi	sp,sp,-16
 1dc:	e422                	sd	s0,8(sp)
 1de:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 1e0:	ce09                	beqz	a2,1fa <memset+0x20>
 1e2:	87aa                	mv	a5,a0
 1e4:	fff6071b          	addiw	a4,a2,-1
 1e8:	1702                	slli	a4,a4,0x20
 1ea:	9301                	srli	a4,a4,0x20
 1ec:	0705                	addi	a4,a4,1
 1ee:	972a                	add	a4,a4,a0
    cdst[i] = c;
 1f0:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 1f4:	0785                	addi	a5,a5,1
 1f6:	fee79de3          	bne	a5,a4,1f0 <memset+0x16>
  }
  return dst;
}
 1fa:	6422                	ld	s0,8(sp)
 1fc:	0141                	addi	sp,sp,16
 1fe:	8082                	ret

0000000000000200 <strchr>:

char*
strchr(const char *s, char c)
{
 200:	1141                	addi	sp,sp,-16
 202:	e422                	sd	s0,8(sp)
 204:	0800                	addi	s0,sp,16
  for(; *s; s++)
 206:	00054783          	lbu	a5,0(a0)
 20a:	cb99                	beqz	a5,220 <strchr+0x20>
    if(*s == c)
 20c:	00f58763          	beq	a1,a5,21a <strchr+0x1a>
  for(; *s; s++)
 210:	0505                	addi	a0,a0,1
 212:	00054783          	lbu	a5,0(a0)
 216:	fbfd                	bnez	a5,20c <strchr+0xc>
      return (char*)s;
  return 0;
 218:	4501                	li	a0,0
}
 21a:	6422                	ld	s0,8(sp)
 21c:	0141                	addi	sp,sp,16
 21e:	8082                	ret
  return 0;
 220:	4501                	li	a0,0
 222:	bfe5                	j	21a <strchr+0x1a>

0000000000000224 <gets>:

char*
gets(char *buf, int max)
{
 224:	711d                	addi	sp,sp,-96
 226:	ec86                	sd	ra,88(sp)
 228:	e8a2                	sd	s0,80(sp)
 22a:	e4a6                	sd	s1,72(sp)
 22c:	e0ca                	sd	s2,64(sp)
 22e:	fc4e                	sd	s3,56(sp)
 230:	f852                	sd	s4,48(sp)
 232:	f456                	sd	s5,40(sp)
 234:	f05a                	sd	s6,32(sp)
 236:	ec5e                	sd	s7,24(sp)
 238:	1080                	addi	s0,sp,96
 23a:	8baa                	mv	s7,a0
 23c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 23e:	892a                	mv	s2,a0
 240:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 242:	4aa9                	li	s5,10
 244:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 246:	89a6                	mv	s3,s1
 248:	2485                	addiw	s1,s1,1
 24a:	0344d863          	bge	s1,s4,27a <gets+0x56>
    cc = read(0, &c, 1);
 24e:	4605                	li	a2,1
 250:	faf40593          	addi	a1,s0,-81
 254:	4501                	li	a0,0
 256:	00000097          	auipc	ra,0x0
 25a:	1a0080e7          	jalr	416(ra) # 3f6 <read>
    if(cc < 1)
 25e:	00a05e63          	blez	a0,27a <gets+0x56>
    buf[i++] = c;
 262:	faf44783          	lbu	a5,-81(s0)
 266:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 26a:	01578763          	beq	a5,s5,278 <gets+0x54>
 26e:	0905                	addi	s2,s2,1
 270:	fd679be3          	bne	a5,s6,246 <gets+0x22>
  for(i=0; i+1 < max; ){
 274:	89a6                	mv	s3,s1
 276:	a011                	j	27a <gets+0x56>
 278:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 27a:	99de                	add	s3,s3,s7
 27c:	00098023          	sb	zero,0(s3)
  return buf;
}
 280:	855e                	mv	a0,s7
 282:	60e6                	ld	ra,88(sp)
 284:	6446                	ld	s0,80(sp)
 286:	64a6                	ld	s1,72(sp)
 288:	6906                	ld	s2,64(sp)
 28a:	79e2                	ld	s3,56(sp)
 28c:	7a42                	ld	s4,48(sp)
 28e:	7aa2                	ld	s5,40(sp)
 290:	7b02                	ld	s6,32(sp)
 292:	6be2                	ld	s7,24(sp)
 294:	6125                	addi	sp,sp,96
 296:	8082                	ret

0000000000000298 <stat>:

int
stat(const char *n, struct stat *st)
{
 298:	1101                	addi	sp,sp,-32
 29a:	ec06                	sd	ra,24(sp)
 29c:	e822                	sd	s0,16(sp)
 29e:	e426                	sd	s1,8(sp)
 2a0:	e04a                	sd	s2,0(sp)
 2a2:	1000                	addi	s0,sp,32
 2a4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 2a6:	4581                	li	a1,0
 2a8:	00000097          	auipc	ra,0x0
 2ac:	176080e7          	jalr	374(ra) # 41e <open>
  if(fd < 0)
 2b0:	02054563          	bltz	a0,2da <stat+0x42>
 2b4:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 2b6:	85ca                	mv	a1,s2
 2b8:	00000097          	auipc	ra,0x0
 2bc:	17e080e7          	jalr	382(ra) # 436 <fstat>
 2c0:	892a                	mv	s2,a0
  close(fd);
 2c2:	8526                	mv	a0,s1
 2c4:	00000097          	auipc	ra,0x0
 2c8:	142080e7          	jalr	322(ra) # 406 <close>
  return r;
}
 2cc:	854a                	mv	a0,s2
 2ce:	60e2                	ld	ra,24(sp)
 2d0:	6442                	ld	s0,16(sp)
 2d2:	64a2                	ld	s1,8(sp)
 2d4:	6902                	ld	s2,0(sp)
 2d6:	6105                	addi	sp,sp,32
 2d8:	8082                	ret
    return -1;
 2da:	597d                	li	s2,-1
 2dc:	bfc5                	j	2cc <stat+0x34>

00000000000002de <atoi>:

int
atoi(const char *s)
{
 2de:	1141                	addi	sp,sp,-16
 2e0:	e422                	sd	s0,8(sp)
 2e2:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 2e4:	00054603          	lbu	a2,0(a0)
 2e8:	fd06079b          	addiw	a5,a2,-48
 2ec:	0ff7f793          	andi	a5,a5,255
 2f0:	4725                	li	a4,9
 2f2:	02f76963          	bltu	a4,a5,324 <atoi+0x46>
 2f6:	86aa                	mv	a3,a0
  n = 0;
 2f8:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 2fa:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 2fc:	0685                	addi	a3,a3,1
 2fe:	0025179b          	slliw	a5,a0,0x2
 302:	9fa9                	addw	a5,a5,a0
 304:	0017979b          	slliw	a5,a5,0x1
 308:	9fb1                	addw	a5,a5,a2
 30a:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 30e:	0006c603          	lbu	a2,0(a3)
 312:	fd06071b          	addiw	a4,a2,-48
 316:	0ff77713          	andi	a4,a4,255
 31a:	fee5f1e3          	bgeu	a1,a4,2fc <atoi+0x1e>
  return n;
}
 31e:	6422                	ld	s0,8(sp)
 320:	0141                	addi	sp,sp,16
 322:	8082                	ret
  n = 0;
 324:	4501                	li	a0,0
 326:	bfe5                	j	31e <atoi+0x40>

0000000000000328 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 328:	1141                	addi	sp,sp,-16
 32a:	e422                	sd	s0,8(sp)
 32c:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 32e:	02b57663          	bgeu	a0,a1,35a <memmove+0x32>
    while(n-- > 0)
 332:	02c05163          	blez	a2,354 <memmove+0x2c>
 336:	fff6079b          	addiw	a5,a2,-1
 33a:	1782                	slli	a5,a5,0x20
 33c:	9381                	srli	a5,a5,0x20
 33e:	0785                	addi	a5,a5,1
 340:	97aa                	add	a5,a5,a0
  dst = vdst;
 342:	872a                	mv	a4,a0
      *dst++ = *src++;
 344:	0585                	addi	a1,a1,1
 346:	0705                	addi	a4,a4,1
 348:	fff5c683          	lbu	a3,-1(a1)
 34c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 350:	fee79ae3          	bne	a5,a4,344 <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 354:	6422                	ld	s0,8(sp)
 356:	0141                	addi	sp,sp,16
 358:	8082                	ret
    dst += n;
 35a:	00c50733          	add	a4,a0,a2
    src += n;
 35e:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 360:	fec05ae3          	blez	a2,354 <memmove+0x2c>
 364:	fff6079b          	addiw	a5,a2,-1
 368:	1782                	slli	a5,a5,0x20
 36a:	9381                	srli	a5,a5,0x20
 36c:	fff7c793          	not	a5,a5
 370:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 372:	15fd                	addi	a1,a1,-1
 374:	177d                	addi	a4,a4,-1
 376:	0005c683          	lbu	a3,0(a1)
 37a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 37e:	fee79ae3          	bne	a5,a4,372 <memmove+0x4a>
 382:	bfc9                	j	354 <memmove+0x2c>

0000000000000384 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 384:	1141                	addi	sp,sp,-16
 386:	e422                	sd	s0,8(sp)
 388:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 38a:	ca05                	beqz	a2,3ba <memcmp+0x36>
 38c:	fff6069b          	addiw	a3,a2,-1
 390:	1682                	slli	a3,a3,0x20
 392:	9281                	srli	a3,a3,0x20
 394:	0685                	addi	a3,a3,1
 396:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 398:	00054783          	lbu	a5,0(a0)
 39c:	0005c703          	lbu	a4,0(a1)
 3a0:	00e79863          	bne	a5,a4,3b0 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 3a4:	0505                	addi	a0,a0,1
    p2++;
 3a6:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 3a8:	fed518e3          	bne	a0,a3,398 <memcmp+0x14>
  }
  return 0;
 3ac:	4501                	li	a0,0
 3ae:	a019                	j	3b4 <memcmp+0x30>
      return *p1 - *p2;
 3b0:	40e7853b          	subw	a0,a5,a4
}
 3b4:	6422                	ld	s0,8(sp)
 3b6:	0141                	addi	sp,sp,16
 3b8:	8082                	ret
  return 0;
 3ba:	4501                	li	a0,0
 3bc:	bfe5                	j	3b4 <memcmp+0x30>

00000000000003be <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 3be:	1141                	addi	sp,sp,-16
 3c0:	e406                	sd	ra,8(sp)
 3c2:	e022                	sd	s0,0(sp)
 3c4:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 3c6:	00000097          	auipc	ra,0x0
 3ca:	f62080e7          	jalr	-158(ra) # 328 <memmove>
}
 3ce:	60a2                	ld	ra,8(sp)
 3d0:	6402                	ld	s0,0(sp)
 3d2:	0141                	addi	sp,sp,16
 3d4:	8082                	ret

00000000000003d6 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 3d6:	4885                	li	a7,1
 ecall
 3d8:	00000073          	ecall
 ret
 3dc:	8082                	ret

00000000000003de <exit>:
.global exit
exit:
 li a7, SYS_exit
 3de:	4889                	li	a7,2
 ecall
 3e0:	00000073          	ecall
 ret
 3e4:	8082                	ret

00000000000003e6 <wait>:
.global wait
wait:
 li a7, SYS_wait
 3e6:	488d                	li	a7,3
 ecall
 3e8:	00000073          	ecall
 ret
 3ec:	8082                	ret

00000000000003ee <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 3ee:	4891                	li	a7,4
 ecall
 3f0:	00000073          	ecall
 ret
 3f4:	8082                	ret

00000000000003f6 <read>:
.global read
read:
 li a7, SYS_read
 3f6:	4895                	li	a7,5
 ecall
 3f8:	00000073          	ecall
 ret
 3fc:	8082                	ret

00000000000003fe <write>:
.global write
write:
 li a7, SYS_write
 3fe:	48c1                	li	a7,16
 ecall
 400:	00000073          	ecall
 ret
 404:	8082                	ret

0000000000000406 <close>:
.global close
close:
 li a7, SYS_close
 406:	48d5                	li	a7,21
 ecall
 408:	00000073          	ecall
 ret
 40c:	8082                	ret

000000000000040e <kill>:
.global kill
kill:
 li a7, SYS_kill
 40e:	4899                	li	a7,6
 ecall
 410:	00000073          	ecall
 ret
 414:	8082                	ret

0000000000000416 <exec>:
.global exec
exec:
 li a7, SYS_exec
 416:	489d                	li	a7,7
 ecall
 418:	00000073          	ecall
 ret
 41c:	8082                	ret

000000000000041e <open>:
.global open
open:
 li a7, SYS_open
 41e:	48bd                	li	a7,15
 ecall
 420:	00000073          	ecall
 ret
 424:	8082                	ret

0000000000000426 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 426:	48c5                	li	a7,17
 ecall
 428:	00000073          	ecall
 ret
 42c:	8082                	ret

000000000000042e <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 42e:	48c9                	li	a7,18
 ecall
 430:	00000073          	ecall
 ret
 434:	8082                	ret

0000000000000436 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 436:	48a1                	li	a7,8
 ecall
 438:	00000073          	ecall
 ret
 43c:	8082                	ret

000000000000043e <link>:
.global link
link:
 li a7, SYS_link
 43e:	48cd                	li	a7,19
 ecall
 440:	00000073          	ecall
 ret
 444:	8082                	ret

0000000000000446 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 446:	48d1                	li	a7,20
 ecall
 448:	00000073          	ecall
 ret
 44c:	8082                	ret

000000000000044e <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 44e:	48a5                	li	a7,9
 ecall
 450:	00000073          	ecall
 ret
 454:	8082                	ret

0000000000000456 <dup>:
.global dup
dup:
 li a7, SYS_dup
 456:	48a9                	li	a7,10
 ecall
 458:	00000073          	ecall
 ret
 45c:	8082                	ret

000000000000045e <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 45e:	48ad                	li	a7,11
 ecall
 460:	00000073          	ecall
 ret
 464:	8082                	ret

0000000000000466 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 466:	48b1                	li	a7,12
 ecall
 468:	00000073          	ecall
 ret
 46c:	8082                	ret

000000000000046e <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 46e:	48b5                	li	a7,13
 ecall
 470:	00000073          	ecall
 ret
 474:	8082                	ret

0000000000000476 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 476:	48b9                	li	a7,14
 ecall
 478:	00000073          	ecall
 ret
 47c:	8082                	ret

000000000000047e <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 47e:	1101                	addi	sp,sp,-32
 480:	ec06                	sd	ra,24(sp)
 482:	e822                	sd	s0,16(sp)
 484:	1000                	addi	s0,sp,32
 486:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 48a:	4605                	li	a2,1
 48c:	fef40593          	addi	a1,s0,-17
 490:	00000097          	auipc	ra,0x0
 494:	f6e080e7          	jalr	-146(ra) # 3fe <write>
}
 498:	60e2                	ld	ra,24(sp)
 49a:	6442                	ld	s0,16(sp)
 49c:	6105                	addi	sp,sp,32
 49e:	8082                	ret

00000000000004a0 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 4a0:	7139                	addi	sp,sp,-64
 4a2:	fc06                	sd	ra,56(sp)
 4a4:	f822                	sd	s0,48(sp)
 4a6:	f426                	sd	s1,40(sp)
 4a8:	f04a                	sd	s2,32(sp)
 4aa:	ec4e                	sd	s3,24(sp)
 4ac:	0080                	addi	s0,sp,64
 4ae:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 4b0:	c299                	beqz	a3,4b6 <printint+0x16>
 4b2:	0805c863          	bltz	a1,542 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 4b6:	2581                	sext.w	a1,a1
  neg = 0;
 4b8:	4881                	li	a7,0
 4ba:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 4be:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 4c0:	2601                	sext.w	a2,a2
 4c2:	00000517          	auipc	a0,0x0
 4c6:	49e50513          	addi	a0,a0,1182 # 960 <digits>
 4ca:	883a                	mv	a6,a4
 4cc:	2705                	addiw	a4,a4,1
 4ce:	02c5f7bb          	remuw	a5,a1,a2
 4d2:	1782                	slli	a5,a5,0x20
 4d4:	9381                	srli	a5,a5,0x20
 4d6:	97aa                	add	a5,a5,a0
 4d8:	0007c783          	lbu	a5,0(a5)
 4dc:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 4e0:	0005879b          	sext.w	a5,a1
 4e4:	02c5d5bb          	divuw	a1,a1,a2
 4e8:	0685                	addi	a3,a3,1
 4ea:	fec7f0e3          	bgeu	a5,a2,4ca <printint+0x2a>
  if(neg)
 4ee:	00088b63          	beqz	a7,504 <printint+0x64>
    buf[i++] = '-';
 4f2:	fd040793          	addi	a5,s0,-48
 4f6:	973e                	add	a4,a4,a5
 4f8:	02d00793          	li	a5,45
 4fc:	fef70823          	sb	a5,-16(a4)
 500:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 504:	02e05863          	blez	a4,534 <printint+0x94>
 508:	fc040793          	addi	a5,s0,-64
 50c:	00e78933          	add	s2,a5,a4
 510:	fff78993          	addi	s3,a5,-1
 514:	99ba                	add	s3,s3,a4
 516:	377d                	addiw	a4,a4,-1
 518:	1702                	slli	a4,a4,0x20
 51a:	9301                	srli	a4,a4,0x20
 51c:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 520:	fff94583          	lbu	a1,-1(s2)
 524:	8526                	mv	a0,s1
 526:	00000097          	auipc	ra,0x0
 52a:	f58080e7          	jalr	-168(ra) # 47e <putc>
  while(--i >= 0)
 52e:	197d                	addi	s2,s2,-1
 530:	ff3918e3          	bne	s2,s3,520 <printint+0x80>
}
 534:	70e2                	ld	ra,56(sp)
 536:	7442                	ld	s0,48(sp)
 538:	74a2                	ld	s1,40(sp)
 53a:	7902                	ld	s2,32(sp)
 53c:	69e2                	ld	s3,24(sp)
 53e:	6121                	addi	sp,sp,64
 540:	8082                	ret
    x = -xx;
 542:	40b005bb          	negw	a1,a1
    neg = 1;
 546:	4885                	li	a7,1
    x = -xx;
 548:	bf8d                	j	4ba <printint+0x1a>

000000000000054a <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 54a:	7119                	addi	sp,sp,-128
 54c:	fc86                	sd	ra,120(sp)
 54e:	f8a2                	sd	s0,112(sp)
 550:	f4a6                	sd	s1,104(sp)
 552:	f0ca                	sd	s2,96(sp)
 554:	ecce                	sd	s3,88(sp)
 556:	e8d2                	sd	s4,80(sp)
 558:	e4d6                	sd	s5,72(sp)
 55a:	e0da                	sd	s6,64(sp)
 55c:	fc5e                	sd	s7,56(sp)
 55e:	f862                	sd	s8,48(sp)
 560:	f466                	sd	s9,40(sp)
 562:	f06a                	sd	s10,32(sp)
 564:	ec6e                	sd	s11,24(sp)
 566:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 568:	0005c903          	lbu	s2,0(a1)
 56c:	18090f63          	beqz	s2,70a <vprintf+0x1c0>
 570:	8aaa                	mv	s5,a0
 572:	8b32                	mv	s6,a2
 574:	00158493          	addi	s1,a1,1
  state = 0;
 578:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 57a:	02500a13          	li	s4,37
      if(c == 'd'){
 57e:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 582:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 586:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 58a:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 58e:	00000b97          	auipc	s7,0x0
 592:	3d2b8b93          	addi	s7,s7,978 # 960 <digits>
 596:	a839                	j	5b4 <vprintf+0x6a>
        putc(fd, c);
 598:	85ca                	mv	a1,s2
 59a:	8556                	mv	a0,s5
 59c:	00000097          	auipc	ra,0x0
 5a0:	ee2080e7          	jalr	-286(ra) # 47e <putc>
 5a4:	a019                	j	5aa <vprintf+0x60>
    } else if(state == '%'){
 5a6:	01498f63          	beq	s3,s4,5c4 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 5aa:	0485                	addi	s1,s1,1
 5ac:	fff4c903          	lbu	s2,-1(s1)
 5b0:	14090d63          	beqz	s2,70a <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 5b4:	0009079b          	sext.w	a5,s2
    if(state == 0){
 5b8:	fe0997e3          	bnez	s3,5a6 <vprintf+0x5c>
      if(c == '%'){
 5bc:	fd479ee3          	bne	a5,s4,598 <vprintf+0x4e>
        state = '%';
 5c0:	89be                	mv	s3,a5
 5c2:	b7e5                	j	5aa <vprintf+0x60>
      if(c == 'd'){
 5c4:	05878063          	beq	a5,s8,604 <vprintf+0xba>
      } else if(c == 'l') {
 5c8:	05978c63          	beq	a5,s9,620 <vprintf+0xd6>
      } else if(c == 'x') {
 5cc:	07a78863          	beq	a5,s10,63c <vprintf+0xf2>
      } else if(c == 'p') {
 5d0:	09b78463          	beq	a5,s11,658 <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 5d4:	07300713          	li	a4,115
 5d8:	0ce78663          	beq	a5,a4,6a4 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 5dc:	06300713          	li	a4,99
 5e0:	0ee78e63          	beq	a5,a4,6dc <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 5e4:	11478863          	beq	a5,s4,6f4 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 5e8:	85d2                	mv	a1,s4
 5ea:	8556                	mv	a0,s5
 5ec:	00000097          	auipc	ra,0x0
 5f0:	e92080e7          	jalr	-366(ra) # 47e <putc>
        putc(fd, c);
 5f4:	85ca                	mv	a1,s2
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	e86080e7          	jalr	-378(ra) # 47e <putc>
      }
      state = 0;
 600:	4981                	li	s3,0
 602:	b765                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 604:	008b0913          	addi	s2,s6,8
 608:	4685                	li	a3,1
 60a:	4629                	li	a2,10
 60c:	000b2583          	lw	a1,0(s6)
 610:	8556                	mv	a0,s5
 612:	00000097          	auipc	ra,0x0
 616:	e8e080e7          	jalr	-370(ra) # 4a0 <printint>
 61a:	8b4a                	mv	s6,s2
      state = 0;
 61c:	4981                	li	s3,0
 61e:	b771                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 620:	008b0913          	addi	s2,s6,8
 624:	4681                	li	a3,0
 626:	4629                	li	a2,10
 628:	000b2583          	lw	a1,0(s6)
 62c:	8556                	mv	a0,s5
 62e:	00000097          	auipc	ra,0x0
 632:	e72080e7          	jalr	-398(ra) # 4a0 <printint>
 636:	8b4a                	mv	s6,s2
      state = 0;
 638:	4981                	li	s3,0
 63a:	bf85                	j	5aa <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 63c:	008b0913          	addi	s2,s6,8
 640:	4681                	li	a3,0
 642:	4641                	li	a2,16
 644:	000b2583          	lw	a1,0(s6)
 648:	8556                	mv	a0,s5
 64a:	00000097          	auipc	ra,0x0
 64e:	e56080e7          	jalr	-426(ra) # 4a0 <printint>
 652:	8b4a                	mv	s6,s2
      state = 0;
 654:	4981                	li	s3,0
 656:	bf91                	j	5aa <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 658:	008b0793          	addi	a5,s6,8
 65c:	f8f43423          	sd	a5,-120(s0)
 660:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 664:	03000593          	li	a1,48
 668:	8556                	mv	a0,s5
 66a:	00000097          	auipc	ra,0x0
 66e:	e14080e7          	jalr	-492(ra) # 47e <putc>
  putc(fd, 'x');
 672:	85ea                	mv	a1,s10
 674:	8556                	mv	a0,s5
 676:	00000097          	auipc	ra,0x0
 67a:	e08080e7          	jalr	-504(ra) # 47e <putc>
 67e:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 680:	03c9d793          	srli	a5,s3,0x3c
 684:	97de                	add	a5,a5,s7
 686:	0007c583          	lbu	a1,0(a5)
 68a:	8556                	mv	a0,s5
 68c:	00000097          	auipc	ra,0x0
 690:	df2080e7          	jalr	-526(ra) # 47e <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 694:	0992                	slli	s3,s3,0x4
 696:	397d                	addiw	s2,s2,-1
 698:	fe0914e3          	bnez	s2,680 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 69c:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 6a0:	4981                	li	s3,0
 6a2:	b721                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 6a4:	008b0993          	addi	s3,s6,8
 6a8:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 6ac:	02090163          	beqz	s2,6ce <vprintf+0x184>
        while(*s != 0){
 6b0:	00094583          	lbu	a1,0(s2)
 6b4:	c9a1                	beqz	a1,704 <vprintf+0x1ba>
          putc(fd, *s);
 6b6:	8556                	mv	a0,s5
 6b8:	00000097          	auipc	ra,0x0
 6bc:	dc6080e7          	jalr	-570(ra) # 47e <putc>
          s++;
 6c0:	0905                	addi	s2,s2,1
        while(*s != 0){
 6c2:	00094583          	lbu	a1,0(s2)
 6c6:	f9e5                	bnez	a1,6b6 <vprintf+0x16c>
        s = va_arg(ap, char*);
 6c8:	8b4e                	mv	s6,s3
      state = 0;
 6ca:	4981                	li	s3,0
 6cc:	bdf9                	j	5aa <vprintf+0x60>
          s = "(null)";
 6ce:	00000917          	auipc	s2,0x0
 6d2:	28a90913          	addi	s2,s2,650 # 958 <malloc+0x144>
        while(*s != 0){
 6d6:	02800593          	li	a1,40
 6da:	bff1                	j	6b6 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 6dc:	008b0913          	addi	s2,s6,8
 6e0:	000b4583          	lbu	a1,0(s6)
 6e4:	8556                	mv	a0,s5
 6e6:	00000097          	auipc	ra,0x0
 6ea:	d98080e7          	jalr	-616(ra) # 47e <putc>
 6ee:	8b4a                	mv	s6,s2
      state = 0;
 6f0:	4981                	li	s3,0
 6f2:	bd65                	j	5aa <vprintf+0x60>
        putc(fd, c);
 6f4:	85d2                	mv	a1,s4
 6f6:	8556                	mv	a0,s5
 6f8:	00000097          	auipc	ra,0x0
 6fc:	d86080e7          	jalr	-634(ra) # 47e <putc>
      state = 0;
 700:	4981                	li	s3,0
 702:	b565                	j	5aa <vprintf+0x60>
        s = va_arg(ap, char*);
 704:	8b4e                	mv	s6,s3
      state = 0;
 706:	4981                	li	s3,0
 708:	b54d                	j	5aa <vprintf+0x60>
    }
  }
}
 70a:	70e6                	ld	ra,120(sp)
 70c:	7446                	ld	s0,112(sp)
 70e:	74a6                	ld	s1,104(sp)
 710:	7906                	ld	s2,96(sp)
 712:	69e6                	ld	s3,88(sp)
 714:	6a46                	ld	s4,80(sp)
 716:	6aa6                	ld	s5,72(sp)
 718:	6b06                	ld	s6,64(sp)
 71a:	7be2                	ld	s7,56(sp)
 71c:	7c42                	ld	s8,48(sp)
 71e:	7ca2                	ld	s9,40(sp)
 720:	7d02                	ld	s10,32(sp)
 722:	6de2                	ld	s11,24(sp)
 724:	6109                	addi	sp,sp,128
 726:	8082                	ret

0000000000000728 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 728:	715d                	addi	sp,sp,-80
 72a:	ec06                	sd	ra,24(sp)
 72c:	e822                	sd	s0,16(sp)
 72e:	1000                	addi	s0,sp,32
 730:	e010                	sd	a2,0(s0)
 732:	e414                	sd	a3,8(s0)
 734:	e818                	sd	a4,16(s0)
 736:	ec1c                	sd	a5,24(s0)
 738:	03043023          	sd	a6,32(s0)
 73c:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 740:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 744:	8622                	mv	a2,s0
 746:	00000097          	auipc	ra,0x0
 74a:	e04080e7          	jalr	-508(ra) # 54a <vprintf>
}
 74e:	60e2                	ld	ra,24(sp)
 750:	6442                	ld	s0,16(sp)
 752:	6161                	addi	sp,sp,80
 754:	8082                	ret

0000000000000756 <printf>:

void
printf(const char *fmt, ...)
{
 756:	711d                	addi	sp,sp,-96
 758:	ec06                	sd	ra,24(sp)
 75a:	e822                	sd	s0,16(sp)
 75c:	1000                	addi	s0,sp,32
 75e:	e40c                	sd	a1,8(s0)
 760:	e810                	sd	a2,16(s0)
 762:	ec14                	sd	a3,24(s0)
 764:	f018                	sd	a4,32(s0)
 766:	f41c                	sd	a5,40(s0)
 768:	03043823          	sd	a6,48(s0)
 76c:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 770:	00840613          	addi	a2,s0,8
 774:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 778:	85aa                	mv	a1,a0
 77a:	4505                	li	a0,1
 77c:	00000097          	auipc	ra,0x0
 780:	dce080e7          	jalr	-562(ra) # 54a <vprintf>
}
 784:	60e2                	ld	ra,24(sp)
 786:	6442                	ld	s0,16(sp)
 788:	6125                	addi	sp,sp,96
 78a:	8082                	ret

000000000000078c <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 78c:	1141                	addi	sp,sp,-16
 78e:	e422                	sd	s0,8(sp)
 790:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 792:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 796:	00000797          	auipc	a5,0x0
 79a:	1e27b783          	ld	a5,482(a5) # 978 <freep>
 79e:	a805                	j	7ce <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 7a0:	4618                	lw	a4,8(a2)
 7a2:	9db9                	addw	a1,a1,a4
 7a4:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 7a8:	6398                	ld	a4,0(a5)
 7aa:	6318                	ld	a4,0(a4)
 7ac:	fee53823          	sd	a4,-16(a0)
 7b0:	a091                	j	7f4 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 7b2:	ff852703          	lw	a4,-8(a0)
 7b6:	9e39                	addw	a2,a2,a4
 7b8:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 7ba:	ff053703          	ld	a4,-16(a0)
 7be:	e398                	sd	a4,0(a5)
 7c0:	a099                	j	806 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7c2:	6398                	ld	a4,0(a5)
 7c4:	00e7e463          	bltu	a5,a4,7cc <free+0x40>
 7c8:	00e6ea63          	bltu	a3,a4,7dc <free+0x50>
{
 7cc:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 7ce:	fed7fae3          	bgeu	a5,a3,7c2 <free+0x36>
 7d2:	6398                	ld	a4,0(a5)
 7d4:	00e6e463          	bltu	a3,a4,7dc <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 7d8:	fee7eae3          	bltu	a5,a4,7cc <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 7dc:	ff852583          	lw	a1,-8(a0)
 7e0:	6390                	ld	a2,0(a5)
 7e2:	02059713          	slli	a4,a1,0x20
 7e6:	9301                	srli	a4,a4,0x20
 7e8:	0712                	slli	a4,a4,0x4
 7ea:	9736                	add	a4,a4,a3
 7ec:	fae60ae3          	beq	a2,a4,7a0 <free+0x14>
    bp->s.ptr = p->s.ptr;
 7f0:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 7f4:	4790                	lw	a2,8(a5)
 7f6:	02061713          	slli	a4,a2,0x20
 7fa:	9301                	srli	a4,a4,0x20
 7fc:	0712                	slli	a4,a4,0x4
 7fe:	973e                	add	a4,a4,a5
 800:	fae689e3          	beq	a3,a4,7b2 <free+0x26>
  } else
    p->s.ptr = bp;
 804:	e394                	sd	a3,0(a5)
  freep = p;
 806:	00000717          	auipc	a4,0x0
 80a:	16f73923          	sd	a5,370(a4) # 978 <freep>
}
 80e:	6422                	ld	s0,8(sp)
 810:	0141                	addi	sp,sp,16
 812:	8082                	ret

0000000000000814 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 814:	7139                	addi	sp,sp,-64
 816:	fc06                	sd	ra,56(sp)
 818:	f822                	sd	s0,48(sp)
 81a:	f426                	sd	s1,40(sp)
 81c:	f04a                	sd	s2,32(sp)
 81e:	ec4e                	sd	s3,24(sp)
 820:	e852                	sd	s4,16(sp)
 822:	e456                	sd	s5,8(sp)
 824:	e05a                	sd	s6,0(sp)
 826:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 828:	02051493          	slli	s1,a0,0x20
 82c:	9081                	srli	s1,s1,0x20
 82e:	04bd                	addi	s1,s1,15
 830:	8091                	srli	s1,s1,0x4
 832:	0014899b          	addiw	s3,s1,1
 836:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 838:	00000517          	auipc	a0,0x0
 83c:	14053503          	ld	a0,320(a0) # 978 <freep>
 840:	c515                	beqz	a0,86c <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 842:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 844:	4798                	lw	a4,8(a5)
 846:	02977f63          	bgeu	a4,s1,884 <malloc+0x70>
 84a:	8a4e                	mv	s4,s3
 84c:	0009871b          	sext.w	a4,s3
 850:	6685                	lui	a3,0x1
 852:	00d77363          	bgeu	a4,a3,858 <malloc+0x44>
 856:	6a05                	lui	s4,0x1
 858:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 85c:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 860:	00000917          	auipc	s2,0x0
 864:	11890913          	addi	s2,s2,280 # 978 <freep>
  if(p == (char*)-1)
 868:	5afd                	li	s5,-1
 86a:	a88d                	j	8dc <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 86c:	00000797          	auipc	a5,0x0
 870:	11478793          	addi	a5,a5,276 # 980 <base>
 874:	00000717          	auipc	a4,0x0
 878:	10f73223          	sd	a5,260(a4) # 978 <freep>
 87c:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 87e:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 882:	b7e1                	j	84a <malloc+0x36>
      if(p->s.size == nunits)
 884:	02e48b63          	beq	s1,a4,8ba <malloc+0xa6>
        p->s.size -= nunits;
 888:	4137073b          	subw	a4,a4,s3
 88c:	c798                	sw	a4,8(a5)
        p += p->s.size;
 88e:	1702                	slli	a4,a4,0x20
 890:	9301                	srli	a4,a4,0x20
 892:	0712                	slli	a4,a4,0x4
 894:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 896:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 89a:	00000717          	auipc	a4,0x0
 89e:	0ca73f23          	sd	a0,222(a4) # 978 <freep>
      return (void*)(p + 1);
 8a2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 8a6:	70e2                	ld	ra,56(sp)
 8a8:	7442                	ld	s0,48(sp)
 8aa:	74a2                	ld	s1,40(sp)
 8ac:	7902                	ld	s2,32(sp)
 8ae:	69e2                	ld	s3,24(sp)
 8b0:	6a42                	ld	s4,16(sp)
 8b2:	6aa2                	ld	s5,8(sp)
 8b4:	6b02                	ld	s6,0(sp)
 8b6:	6121                	addi	sp,sp,64
 8b8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 8ba:	6398                	ld	a4,0(a5)
 8bc:	e118                	sd	a4,0(a0)
 8be:	bff1                	j	89a <malloc+0x86>
  hp->s.size = nu;
 8c0:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 8c4:	0541                	addi	a0,a0,16
 8c6:	00000097          	auipc	ra,0x0
 8ca:	ec6080e7          	jalr	-314(ra) # 78c <free>
  return freep;
 8ce:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 8d2:	d971                	beqz	a0,8a6 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 8d4:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 8d6:	4798                	lw	a4,8(a5)
 8d8:	fa9776e3          	bgeu	a4,s1,884 <malloc+0x70>
    if(p == freep)
 8dc:	00093703          	ld	a4,0(s2)
 8e0:	853e                	mv	a0,a5
 8e2:	fef719e3          	bne	a4,a5,8d4 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 8e6:	8552                	mv	a0,s4
 8e8:	00000097          	auipc	ra,0x0
 8ec:	b7e080e7          	jalr	-1154(ra) # 466 <sbrk>
  if(p == (char*)-1)
 8f0:	fd5518e3          	bne	a0,s5,8c0 <malloc+0xac>
        return 0;
 8f4:	4501                	li	a0,0
 8f6:	bf45                	j	8a6 <malloc+0x92>
