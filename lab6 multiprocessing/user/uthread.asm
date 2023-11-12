
user/_uthread：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000000000000 <thread_init>:
struct thread *current_thread;
extern void thread_switch(uint64 old, uint64 new);
              
void 
thread_init(void)
{
   0:	1141                	addi	sp,sp,-16
   2:	e422                	sd	s0,8(sp)
   4:	0800                	addi	s0,sp,16
  // main() is thread 0, which will make the first invocation to
  // thread_schedule().  it needs a stack so that the first thread_switch() can
  // save thread 0's state.  thread_schedule() won't run the main thread ever
  // again, because its state is set to RUNNING, and thread_schedule() selects
  // a RUNNABLE thread.
  current_thread = &all_thread[0];
   6:	00001797          	auipc	a5,0x1
   a:	d4278793          	addi	a5,a5,-702 # d48 <all_thread>
   e:	00001717          	auipc	a4,0x1
  12:	d2f73523          	sd	a5,-726(a4) # d38 <current_thread>
  current_thread->state = RUNNING;
  16:	4785                	li	a5,1
  18:	00003717          	auipc	a4,0x3
  1c:	daf72023          	sw	a5,-608(a4) # 2db8 <__global_pointer$+0x189f>
}
  20:	6422                	ld	s0,8(sp)
  22:	0141                	addi	sp,sp,16
  24:	8082                	ret

0000000000000026 <thread_schedule>:

void 
thread_schedule(void)
{
  26:	1141                	addi	sp,sp,-16
  28:	e406                	sd	ra,8(sp)
  2a:	e022                	sd	s0,0(sp)
  2c:	0800                	addi	s0,sp,16
  struct thread *t, *next_thread;
  /* Find another runnable thread. */
  next_thread = 0;
  t = current_thread + 1;
  2e:	00001517          	auipc	a0,0x1
  32:	d0a53503          	ld	a0,-758(a0) # d38 <current_thread>
  36:	6589                	lui	a1,0x2
  38:	07858593          	addi	a1,a1,120 # 2078 <__global_pointer$+0xb5f>
  3c:	95aa                	add	a1,a1,a0
  3e:	4791                	li	a5,4
  for(int i = 0; i < MAX_THREAD; i++){
    if(t >= all_thread + MAX_THREAD)
  40:	00009817          	auipc	a6,0x9
  44:	ee880813          	addi	a6,a6,-280 # 8f28 <base>
      t = all_thread;
    if(t->state == RUNNABLE) {
  48:	6689                	lui	a3,0x2
  4a:	4609                	li	a2,2
      next_thread = t;
      break;
    }
    t = t + 1;
  4c:	07868893          	addi	a7,a3,120 # 2078 <__global_pointer$+0xb5f>
  50:	a809                	j	62 <thread_schedule+0x3c>
    if(t->state == RUNNABLE) {
  52:	00d58733          	add	a4,a1,a3
  56:	5b38                	lw	a4,112(a4)
  58:	02c70963          	beq	a4,a2,8a <thread_schedule+0x64>
    t = t + 1;
  5c:	95c6                	add	a1,a1,a7
  for(int i = 0; i < MAX_THREAD; i++){
  5e:	37fd                	addiw	a5,a5,-1
  60:	cb81                	beqz	a5,70 <thread_schedule+0x4a>
    if(t >= all_thread + MAX_THREAD)
  62:	ff05e8e3          	bltu	a1,a6,52 <thread_schedule+0x2c>
      t = all_thread;
  66:	00001597          	auipc	a1,0x1
  6a:	ce258593          	addi	a1,a1,-798 # d48 <all_thread>
  6e:	b7d5                	j	52 <thread_schedule+0x2c>
  }

  if (next_thread == 0) {
    printf("thread_schedule: no runnable threads\n");
  70:	00001517          	auipc	a0,0x1
  74:	b9050513          	addi	a0,a0,-1136 # c00 <malloc+0xe6>
  78:	00001097          	auipc	ra,0x1
  7c:	9e4080e7          	jalr	-1564(ra) # a5c <printf>
    exit(-1);
  80:	557d                	li	a0,-1
  82:	00000097          	auipc	ra,0x0
  86:	662080e7          	jalr	1634(ra) # 6e4 <exit>
  }

  if (current_thread != next_thread) {         /* switch threads?  */
  8a:	00b50e63          	beq	a0,a1,a6 <thread_schedule+0x80>
    next_thread->state = RUNNING;
  8e:	6789                	lui	a5,0x2
  90:	97ae                	add	a5,a5,a1
  92:	4705                	li	a4,1
  94:	dbb8                	sw	a4,112(a5)
    t = current_thread;
    current_thread = next_thread;
  96:	00001797          	auipc	a5,0x1
  9a:	cab7b123          	sd	a1,-862(a5) # d38 <current_thread>
    /* YOUR CODE HERE
     * Invoke thread_switch to switch from t to next_thread:
     * thread_switch(??, ??);
     */
    thread_switch((uint64)t, (uint64)current_thread);
  9e:	00000097          	auipc	ra,0x0
  a2:	366080e7          	jalr	870(ra) # 404 <thread_switch>
  } else
    next_thread = 0;
}
  a6:	60a2                	ld	ra,8(sp)
  a8:	6402                	ld	s0,0(sp)
  aa:	0141                	addi	sp,sp,16
  ac:	8082                	ret

00000000000000ae <thread_create>:

void 
thread_create(void (*func)())
{
  ae:	1141                	addi	sp,sp,-16
  b0:	e422                	sd	s0,8(sp)
  b2:	0800                	addi	s0,sp,16
  struct thread *t;

  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  b4:	00001797          	auipc	a5,0x1
  b8:	c9478793          	addi	a5,a5,-876 # d48 <all_thread>
    if (t->state == FREE) break;
  bc:	6709                	lui	a4,0x2
  be:	07070613          	addi	a2,a4,112 # 2070 <__global_pointer$+0xb57>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  c2:	07870713          	addi	a4,a4,120
  c6:	00009597          	auipc	a1,0x9
  ca:	e6258593          	addi	a1,a1,-414 # 8f28 <base>
    if (t->state == FREE) break;
  ce:	00c786b3          	add	a3,a5,a2
  d2:	4294                	lw	a3,0(a3)
  d4:	c681                	beqz	a3,dc <thread_create+0x2e>
  for (t = all_thread; t < all_thread + MAX_THREAD; t++) {
  d6:	97ba                	add	a5,a5,a4
  d8:	feb79be3          	bne	a5,a1,ce <thread_create+0x20>
  }
  t->state = RUNNABLE;
  dc:	6709                	lui	a4,0x2
  de:	00e786b3          	add	a3,a5,a4
  e2:	4609                	li	a2,2
  e4:	dab0                	sw	a2,112(a3)
  // YOUR CODE HERE
  t->saved_regs.ra = (uint64)func;
  e6:	e388                	sd	a0,0(a5)
  t->saved_regs.sp = (uint64)(t->stack + STACK_SIZE);
  e8:	07070713          	addi	a4,a4,112 # 2070 <__global_pointer$+0xb57>
  ec:	973e                	add	a4,a4,a5
  ee:	e798                	sd	a4,8(a5)
}
  f0:	6422                	ld	s0,8(sp)
  f2:	0141                	addi	sp,sp,16
  f4:	8082                	ret

00000000000000f6 <thread_yield>:

void 
thread_yield(void)
{
  f6:	1141                	addi	sp,sp,-16
  f8:	e406                	sd	ra,8(sp)
  fa:	e022                	sd	s0,0(sp)
  fc:	0800                	addi	s0,sp,16
  current_thread->state = RUNNABLE;
  fe:	00001797          	auipc	a5,0x1
 102:	c3a7b783          	ld	a5,-966(a5) # d38 <current_thread>
 106:	6709                	lui	a4,0x2
 108:	97ba                	add	a5,a5,a4
 10a:	4709                	li	a4,2
 10c:	dbb8                	sw	a4,112(a5)
  thread_schedule();
 10e:	00000097          	auipc	ra,0x0
 112:	f18080e7          	jalr	-232(ra) # 26 <thread_schedule>
}
 116:	60a2                	ld	ra,8(sp)
 118:	6402                	ld	s0,0(sp)
 11a:	0141                	addi	sp,sp,16
 11c:	8082                	ret

000000000000011e <thread_a>:
volatile int a_started, b_started, c_started;
volatile int a_n, b_n, c_n;

void 
thread_a(void)
{
 11e:	7179                	addi	sp,sp,-48
 120:	f406                	sd	ra,40(sp)
 122:	f022                	sd	s0,32(sp)
 124:	ec26                	sd	s1,24(sp)
 126:	e84a                	sd	s2,16(sp)
 128:	e44e                	sd	s3,8(sp)
 12a:	e052                	sd	s4,0(sp)
 12c:	1800                	addi	s0,sp,48
  int i;
  printf("thread_a started\n");
 12e:	00001517          	auipc	a0,0x1
 132:	afa50513          	addi	a0,a0,-1286 # c28 <malloc+0x10e>
 136:	00001097          	auipc	ra,0x1
 13a:	926080e7          	jalr	-1754(ra) # a5c <printf>
  a_started = 1;
 13e:	4785                	li	a5,1
 140:	00001717          	auipc	a4,0x1
 144:	bef72a23          	sw	a5,-1036(a4) # d34 <a_started>
  while(b_started == 0 || c_started == 0)
 148:	00001497          	auipc	s1,0x1
 14c:	be848493          	addi	s1,s1,-1048 # d30 <b_started>
 150:	00001917          	auipc	s2,0x1
 154:	bdc90913          	addi	s2,s2,-1060 # d2c <c_started>
 158:	a029                	j	162 <thread_a+0x44>
    thread_yield();
 15a:	00000097          	auipc	ra,0x0
 15e:	f9c080e7          	jalr	-100(ra) # f6 <thread_yield>
  while(b_started == 0 || c_started == 0)
 162:	409c                	lw	a5,0(s1)
 164:	2781                	sext.w	a5,a5
 166:	dbf5                	beqz	a5,15a <thread_a+0x3c>
 168:	00092783          	lw	a5,0(s2)
 16c:	2781                	sext.w	a5,a5
 16e:	d7f5                	beqz	a5,15a <thread_a+0x3c>
  
  for (i = 0; i < 100; i++) {
 170:	4481                	li	s1,0
    printf("thread_a %d\n", i);
 172:	00001a17          	auipc	s4,0x1
 176:	acea0a13          	addi	s4,s4,-1330 # c40 <malloc+0x126>
    a_n += 1;
 17a:	00001917          	auipc	s2,0x1
 17e:	bae90913          	addi	s2,s2,-1106 # d28 <a_n>
  for (i = 0; i < 100; i++) {
 182:	06400993          	li	s3,100
    printf("thread_a %d\n", i);
 186:	85a6                	mv	a1,s1
 188:	8552                	mv	a0,s4
 18a:	00001097          	auipc	ra,0x1
 18e:	8d2080e7          	jalr	-1838(ra) # a5c <printf>
    a_n += 1;
 192:	00092783          	lw	a5,0(s2)
 196:	2785                	addiw	a5,a5,1
 198:	00f92023          	sw	a5,0(s2)
    thread_yield();
 19c:	00000097          	auipc	ra,0x0
 1a0:	f5a080e7          	jalr	-166(ra) # f6 <thread_yield>
  for (i = 0; i < 100; i++) {
 1a4:	2485                	addiw	s1,s1,1
 1a6:	ff3490e3          	bne	s1,s3,186 <thread_a+0x68>
  }
  printf("thread_a: exit after %d\n", a_n);
 1aa:	00001597          	auipc	a1,0x1
 1ae:	b7e5a583          	lw	a1,-1154(a1) # d28 <a_n>
 1b2:	00001517          	auipc	a0,0x1
 1b6:	a9e50513          	addi	a0,a0,-1378 # c50 <malloc+0x136>
 1ba:	00001097          	auipc	ra,0x1
 1be:	8a2080e7          	jalr	-1886(ra) # a5c <printf>

  current_thread->state = FREE;
 1c2:	00001797          	auipc	a5,0x1
 1c6:	b767b783          	ld	a5,-1162(a5) # d38 <current_thread>
 1ca:	6709                	lui	a4,0x2
 1cc:	97ba                	add	a5,a5,a4
 1ce:	0607a823          	sw	zero,112(a5)
  thread_schedule();
 1d2:	00000097          	auipc	ra,0x0
 1d6:	e54080e7          	jalr	-428(ra) # 26 <thread_schedule>
}
 1da:	70a2                	ld	ra,40(sp)
 1dc:	7402                	ld	s0,32(sp)
 1de:	64e2                	ld	s1,24(sp)
 1e0:	6942                	ld	s2,16(sp)
 1e2:	69a2                	ld	s3,8(sp)
 1e4:	6a02                	ld	s4,0(sp)
 1e6:	6145                	addi	sp,sp,48
 1e8:	8082                	ret

00000000000001ea <thread_b>:

void 
thread_b(void)
{
 1ea:	7179                	addi	sp,sp,-48
 1ec:	f406                	sd	ra,40(sp)
 1ee:	f022                	sd	s0,32(sp)
 1f0:	ec26                	sd	s1,24(sp)
 1f2:	e84a                	sd	s2,16(sp)
 1f4:	e44e                	sd	s3,8(sp)
 1f6:	e052                	sd	s4,0(sp)
 1f8:	1800                	addi	s0,sp,48
  int i;
  printf("thread_b started\n");
 1fa:	00001517          	auipc	a0,0x1
 1fe:	a7650513          	addi	a0,a0,-1418 # c70 <malloc+0x156>
 202:	00001097          	auipc	ra,0x1
 206:	85a080e7          	jalr	-1958(ra) # a5c <printf>
  b_started = 1;
 20a:	4785                	li	a5,1
 20c:	00001717          	auipc	a4,0x1
 210:	b2f72223          	sw	a5,-1244(a4) # d30 <b_started>
  while(a_started == 0 || c_started == 0)
 214:	00001497          	auipc	s1,0x1
 218:	b2048493          	addi	s1,s1,-1248 # d34 <a_started>
 21c:	00001917          	auipc	s2,0x1
 220:	b1090913          	addi	s2,s2,-1264 # d2c <c_started>
 224:	a029                	j	22e <thread_b+0x44>
    thread_yield();
 226:	00000097          	auipc	ra,0x0
 22a:	ed0080e7          	jalr	-304(ra) # f6 <thread_yield>
  while(a_started == 0 || c_started == 0)
 22e:	409c                	lw	a5,0(s1)
 230:	2781                	sext.w	a5,a5
 232:	dbf5                	beqz	a5,226 <thread_b+0x3c>
 234:	00092783          	lw	a5,0(s2)
 238:	2781                	sext.w	a5,a5
 23a:	d7f5                	beqz	a5,226 <thread_b+0x3c>
  
  for (i = 0; i < 100; i++) {
 23c:	4481                	li	s1,0
    printf("thread_b %d\n", i);
 23e:	00001a17          	auipc	s4,0x1
 242:	a4aa0a13          	addi	s4,s4,-1462 # c88 <malloc+0x16e>
    b_n += 1;
 246:	00001917          	auipc	s2,0x1
 24a:	ade90913          	addi	s2,s2,-1314 # d24 <b_n>
  for (i = 0; i < 100; i++) {
 24e:	06400993          	li	s3,100
    printf("thread_b %d\n", i);
 252:	85a6                	mv	a1,s1
 254:	8552                	mv	a0,s4
 256:	00001097          	auipc	ra,0x1
 25a:	806080e7          	jalr	-2042(ra) # a5c <printf>
    b_n += 1;
 25e:	00092783          	lw	a5,0(s2)
 262:	2785                	addiw	a5,a5,1
 264:	00f92023          	sw	a5,0(s2)
    thread_yield();
 268:	00000097          	auipc	ra,0x0
 26c:	e8e080e7          	jalr	-370(ra) # f6 <thread_yield>
  for (i = 0; i < 100; i++) {
 270:	2485                	addiw	s1,s1,1
 272:	ff3490e3          	bne	s1,s3,252 <thread_b+0x68>
  }
  printf("thread_b: exit after %d\n", b_n);
 276:	00001597          	auipc	a1,0x1
 27a:	aae5a583          	lw	a1,-1362(a1) # d24 <b_n>
 27e:	00001517          	auipc	a0,0x1
 282:	a1a50513          	addi	a0,a0,-1510 # c98 <malloc+0x17e>
 286:	00000097          	auipc	ra,0x0
 28a:	7d6080e7          	jalr	2006(ra) # a5c <printf>

  current_thread->state = FREE;
 28e:	00001797          	auipc	a5,0x1
 292:	aaa7b783          	ld	a5,-1366(a5) # d38 <current_thread>
 296:	6709                	lui	a4,0x2
 298:	97ba                	add	a5,a5,a4
 29a:	0607a823          	sw	zero,112(a5)
  thread_schedule();
 29e:	00000097          	auipc	ra,0x0
 2a2:	d88080e7          	jalr	-632(ra) # 26 <thread_schedule>
}
 2a6:	70a2                	ld	ra,40(sp)
 2a8:	7402                	ld	s0,32(sp)
 2aa:	64e2                	ld	s1,24(sp)
 2ac:	6942                	ld	s2,16(sp)
 2ae:	69a2                	ld	s3,8(sp)
 2b0:	6a02                	ld	s4,0(sp)
 2b2:	6145                	addi	sp,sp,48
 2b4:	8082                	ret

00000000000002b6 <thread_c>:

void 
thread_c(void)
{
 2b6:	7179                	addi	sp,sp,-48
 2b8:	f406                	sd	ra,40(sp)
 2ba:	f022                	sd	s0,32(sp)
 2bc:	ec26                	sd	s1,24(sp)
 2be:	e84a                	sd	s2,16(sp)
 2c0:	e44e                	sd	s3,8(sp)
 2c2:	e052                	sd	s4,0(sp)
 2c4:	1800                	addi	s0,sp,48
  int i;
  printf("thread_c started\n");
 2c6:	00001517          	auipc	a0,0x1
 2ca:	9f250513          	addi	a0,a0,-1550 # cb8 <malloc+0x19e>
 2ce:	00000097          	auipc	ra,0x0
 2d2:	78e080e7          	jalr	1934(ra) # a5c <printf>
  c_started = 1;
 2d6:	4785                	li	a5,1
 2d8:	00001717          	auipc	a4,0x1
 2dc:	a4f72a23          	sw	a5,-1452(a4) # d2c <c_started>
  while(a_started == 0 || b_started == 0)
 2e0:	00001497          	auipc	s1,0x1
 2e4:	a5448493          	addi	s1,s1,-1452 # d34 <a_started>
 2e8:	00001917          	auipc	s2,0x1
 2ec:	a4890913          	addi	s2,s2,-1464 # d30 <b_started>
 2f0:	a029                	j	2fa <thread_c+0x44>
  {
    thread_yield();
 2f2:	00000097          	auipc	ra,0x0
 2f6:	e04080e7          	jalr	-508(ra) # f6 <thread_yield>
  while(a_started == 0 || b_started == 0)
 2fa:	409c                	lw	a5,0(s1)
 2fc:	2781                	sext.w	a5,a5
 2fe:	dbf5                	beqz	a5,2f2 <thread_c+0x3c>
 300:	00092783          	lw	a5,0(s2)
 304:	2781                	sext.w	a5,a5
 306:	d7f5                	beqz	a5,2f2 <thread_c+0x3c>
  }
  
  for (i = 0; i < 100; i++) {
 308:	4481                	li	s1,0
    printf("thread_c %d\n", i);
 30a:	00001a17          	auipc	s4,0x1
 30e:	9c6a0a13          	addi	s4,s4,-1594 # cd0 <malloc+0x1b6>
    c_n += 1;
 312:	00001917          	auipc	s2,0x1
 316:	a0e90913          	addi	s2,s2,-1522 # d20 <c_n>
  for (i = 0; i < 100; i++) {
 31a:	06400993          	li	s3,100
    printf("thread_c %d\n", i);
 31e:	85a6                	mv	a1,s1
 320:	8552                	mv	a0,s4
 322:	00000097          	auipc	ra,0x0
 326:	73a080e7          	jalr	1850(ra) # a5c <printf>
    c_n += 1;
 32a:	00092783          	lw	a5,0(s2)
 32e:	2785                	addiw	a5,a5,1
 330:	00f92023          	sw	a5,0(s2)
    thread_yield();
 334:	00000097          	auipc	ra,0x0
 338:	dc2080e7          	jalr	-574(ra) # f6 <thread_yield>
  for (i = 0; i < 100; i++) {
 33c:	2485                	addiw	s1,s1,1
 33e:	ff3490e3          	bne	s1,s3,31e <thread_c+0x68>
  }
  printf("thread_c: exit after %d\n", c_n);
 342:	00001597          	auipc	a1,0x1
 346:	9de5a583          	lw	a1,-1570(a1) # d20 <c_n>
 34a:	00001517          	auipc	a0,0x1
 34e:	99650513          	addi	a0,a0,-1642 # ce0 <malloc+0x1c6>
 352:	00000097          	auipc	ra,0x0
 356:	70a080e7          	jalr	1802(ra) # a5c <printf>

  current_thread->state = FREE;
 35a:	00001797          	auipc	a5,0x1
 35e:	9de7b783          	ld	a5,-1570(a5) # d38 <current_thread>
 362:	6709                	lui	a4,0x2
 364:	97ba                	add	a5,a5,a4
 366:	0607a823          	sw	zero,112(a5)
  thread_schedule();
 36a:	00000097          	auipc	ra,0x0
 36e:	cbc080e7          	jalr	-836(ra) # 26 <thread_schedule>
}
 372:	70a2                	ld	ra,40(sp)
 374:	7402                	ld	s0,32(sp)
 376:	64e2                	ld	s1,24(sp)
 378:	6942                	ld	s2,16(sp)
 37a:	69a2                	ld	s3,8(sp)
 37c:	6a02                	ld	s4,0(sp)
 37e:	6145                	addi	sp,sp,48
 380:	8082                	ret

0000000000000382 <main>:

int 
main(int argc, char *argv[]) 
{
 382:	1141                	addi	sp,sp,-16
 384:	e406                	sd	ra,8(sp)
 386:	e022                	sd	s0,0(sp)
 388:	0800                	addi	s0,sp,16
  a_started = b_started = c_started = 0;
 38a:	00001797          	auipc	a5,0x1
 38e:	9a07a123          	sw	zero,-1630(a5) # d2c <c_started>
 392:	00001797          	auipc	a5,0x1
 396:	9807af23          	sw	zero,-1634(a5) # d30 <b_started>
 39a:	00001797          	auipc	a5,0x1
 39e:	9807ad23          	sw	zero,-1638(a5) # d34 <a_started>
  a_n = b_n = c_n = 0;
 3a2:	00001797          	auipc	a5,0x1
 3a6:	9607af23          	sw	zero,-1666(a5) # d20 <c_n>
 3aa:	00001797          	auipc	a5,0x1
 3ae:	9607ad23          	sw	zero,-1670(a5) # d24 <b_n>
 3b2:	00001797          	auipc	a5,0x1
 3b6:	9607ab23          	sw	zero,-1674(a5) # d28 <a_n>
  thread_init();
 3ba:	00000097          	auipc	ra,0x0
 3be:	c46080e7          	jalr	-954(ra) # 0 <thread_init>
  thread_create(thread_a);
 3c2:	00000517          	auipc	a0,0x0
 3c6:	d5c50513          	addi	a0,a0,-676 # 11e <thread_a>
 3ca:	00000097          	auipc	ra,0x0
 3ce:	ce4080e7          	jalr	-796(ra) # ae <thread_create>
  thread_create(thread_b);
 3d2:	00000517          	auipc	a0,0x0
 3d6:	e1850513          	addi	a0,a0,-488 # 1ea <thread_b>
 3da:	00000097          	auipc	ra,0x0
 3de:	cd4080e7          	jalr	-812(ra) # ae <thread_create>
  thread_create(thread_c);
 3e2:	00000517          	auipc	a0,0x0
 3e6:	ed450513          	addi	a0,a0,-300 # 2b6 <thread_c>
 3ea:	00000097          	auipc	ra,0x0
 3ee:	cc4080e7          	jalr	-828(ra) # ae <thread_create>
  thread_schedule();
 3f2:	00000097          	auipc	ra,0x0
 3f6:	c34080e7          	jalr	-972(ra) # 26 <thread_schedule>
  exit(0);
 3fa:	4501                	li	a0,0
 3fc:	00000097          	auipc	ra,0x0
 400:	2e8080e7          	jalr	744(ra) # 6e4 <exit>

0000000000000404 <thread_switch>:
         */

	.globl thread_switch
thread_switch:
	/* YOUR CODE HERE */
	sd ra, 0(a0)
 404:	00153023          	sd	ra,0(a0)
	sd sp, 8(a0)
 408:	00253423          	sd	sp,8(a0)
	sd s0, 16(a0)
 40c:	e900                	sd	s0,16(a0)
	sd s1, 24(a0)
 40e:	ed04                	sd	s1,24(a0)
	sd s2, 32(a0)
 410:	03253023          	sd	s2,32(a0)
	sd s3, 40(a0)
 414:	03353423          	sd	s3,40(a0)
	sd s4, 48(a0)
 418:	03453823          	sd	s4,48(a0)
	sd s5, 56(a0)
 41c:	03553c23          	sd	s5,56(a0)
	sd s6, 64(a0)
 420:	05653023          	sd	s6,64(a0)
	sd s7, 72(a0)
 424:	05753423          	sd	s7,72(a0)
	sd s8, 80(a0)
 428:	05853823          	sd	s8,80(a0)
	sd s9, 88(a0)
 42c:	05953c23          	sd	s9,88(a0)
	sd s10, 96(a0)
 430:	07a53023          	sd	s10,96(a0)
	sd s11, 104(a0)
 434:	07b53423          	sd	s11,104(a0)

	ld ra, 0(a1)
 438:	0005b083          	ld	ra,0(a1)
	ld sp, 8(a1)
 43c:	0085b103          	ld	sp,8(a1)
	ld s0, 16(a1)
 440:	6980                	ld	s0,16(a1)
	ld s1, 24(a1)
 442:	6d84                	ld	s1,24(a1)
	ld s2, 32(a1)
 444:	0205b903          	ld	s2,32(a1)
	ld s3, 40(a1)
 448:	0285b983          	ld	s3,40(a1)
	ld s4, 48(a1)
 44c:	0305ba03          	ld	s4,48(a1)
	ld s5, 56(a1)
 450:	0385ba83          	ld	s5,56(a1)
	ld s6, 64(a1)
 454:	0405bb03          	ld	s6,64(a1)
	ld s7, 72(a1)
 458:	0485bb83          	ld	s7,72(a1)
	ld s8, 80(a1)
 45c:	0505bc03          	ld	s8,80(a1)
	ld s9, 88(a1)
 460:	0585bc83          	ld	s9,88(a1)
	ld s10, 96(a1)
 464:	0605bd03          	ld	s10,96(a1)
	ld s11, 104(a1)
 468:	0685bd83          	ld	s11,104(a1)
	ret    /* return to ra */
 46c:	8082                	ret

000000000000046e <strcpy>:
#include "kernel/fcntl.h"
#include "user/user.h"

char*
strcpy(char *s, const char *t)
{
 46e:	1141                	addi	sp,sp,-16
 470:	e422                	sd	s0,8(sp)
 472:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
 474:	87aa                	mv	a5,a0
 476:	0585                	addi	a1,a1,1
 478:	0785                	addi	a5,a5,1
 47a:	fff5c703          	lbu	a4,-1(a1)
 47e:	fee78fa3          	sb	a4,-1(a5)
 482:	fb75                	bnez	a4,476 <strcpy+0x8>
    ;
  return os;
}
 484:	6422                	ld	s0,8(sp)
 486:	0141                	addi	sp,sp,16
 488:	8082                	ret

000000000000048a <strcmp>:

int
strcmp(const char *p, const char *q)
{
 48a:	1141                	addi	sp,sp,-16
 48c:	e422                	sd	s0,8(sp)
 48e:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
 490:	00054783          	lbu	a5,0(a0)
 494:	cb91                	beqz	a5,4a8 <strcmp+0x1e>
 496:	0005c703          	lbu	a4,0(a1)
 49a:	00f71763          	bne	a4,a5,4a8 <strcmp+0x1e>
    p++, q++;
 49e:	0505                	addi	a0,a0,1
 4a0:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
 4a2:	00054783          	lbu	a5,0(a0)
 4a6:	fbe5                	bnez	a5,496 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
 4a8:	0005c503          	lbu	a0,0(a1)
}
 4ac:	40a7853b          	subw	a0,a5,a0
 4b0:	6422                	ld	s0,8(sp)
 4b2:	0141                	addi	sp,sp,16
 4b4:	8082                	ret

00000000000004b6 <strlen>:

uint
strlen(const char *s)
{
 4b6:	1141                	addi	sp,sp,-16
 4b8:	e422                	sd	s0,8(sp)
 4ba:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 4bc:	00054783          	lbu	a5,0(a0)
 4c0:	cf91                	beqz	a5,4dc <strlen+0x26>
 4c2:	0505                	addi	a0,a0,1
 4c4:	87aa                	mv	a5,a0
 4c6:	4685                	li	a3,1
 4c8:	9e89                	subw	a3,a3,a0
 4ca:	00f6853b          	addw	a0,a3,a5
 4ce:	0785                	addi	a5,a5,1
 4d0:	fff7c703          	lbu	a4,-1(a5)
 4d4:	fb7d                	bnez	a4,4ca <strlen+0x14>
    ;
  return n;
}
 4d6:	6422                	ld	s0,8(sp)
 4d8:	0141                	addi	sp,sp,16
 4da:	8082                	ret
  for(n = 0; s[n]; n++)
 4dc:	4501                	li	a0,0
 4de:	bfe5                	j	4d6 <strlen+0x20>

00000000000004e0 <memset>:

void*
memset(void *dst, int c, uint n)
{
 4e0:	1141                	addi	sp,sp,-16
 4e2:	e422                	sd	s0,8(sp)
 4e4:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 4e6:	ce09                	beqz	a2,500 <memset+0x20>
 4e8:	87aa                	mv	a5,a0
 4ea:	fff6071b          	addiw	a4,a2,-1
 4ee:	1702                	slli	a4,a4,0x20
 4f0:	9301                	srli	a4,a4,0x20
 4f2:	0705                	addi	a4,a4,1
 4f4:	972a                	add	a4,a4,a0
    cdst[i] = c;
 4f6:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 4fa:	0785                	addi	a5,a5,1
 4fc:	fee79de3          	bne	a5,a4,4f6 <memset+0x16>
  }
  return dst;
}
 500:	6422                	ld	s0,8(sp)
 502:	0141                	addi	sp,sp,16
 504:	8082                	ret

0000000000000506 <strchr>:

char*
strchr(const char *s, char c)
{
 506:	1141                	addi	sp,sp,-16
 508:	e422                	sd	s0,8(sp)
 50a:	0800                	addi	s0,sp,16
  for(; *s; s++)
 50c:	00054783          	lbu	a5,0(a0)
 510:	cb99                	beqz	a5,526 <strchr+0x20>
    if(*s == c)
 512:	00f58763          	beq	a1,a5,520 <strchr+0x1a>
  for(; *s; s++)
 516:	0505                	addi	a0,a0,1
 518:	00054783          	lbu	a5,0(a0)
 51c:	fbfd                	bnez	a5,512 <strchr+0xc>
      return (char*)s;
  return 0;
 51e:	4501                	li	a0,0
}
 520:	6422                	ld	s0,8(sp)
 522:	0141                	addi	sp,sp,16
 524:	8082                	ret
  return 0;
 526:	4501                	li	a0,0
 528:	bfe5                	j	520 <strchr+0x1a>

000000000000052a <gets>:

char*
gets(char *buf, int max)
{
 52a:	711d                	addi	sp,sp,-96
 52c:	ec86                	sd	ra,88(sp)
 52e:	e8a2                	sd	s0,80(sp)
 530:	e4a6                	sd	s1,72(sp)
 532:	e0ca                	sd	s2,64(sp)
 534:	fc4e                	sd	s3,56(sp)
 536:	f852                	sd	s4,48(sp)
 538:	f456                	sd	s5,40(sp)
 53a:	f05a                	sd	s6,32(sp)
 53c:	ec5e                	sd	s7,24(sp)
 53e:	1080                	addi	s0,sp,96
 540:	8baa                	mv	s7,a0
 542:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 544:	892a                	mv	s2,a0
 546:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 548:	4aa9                	li	s5,10
 54a:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 54c:	89a6                	mv	s3,s1
 54e:	2485                	addiw	s1,s1,1
 550:	0344d863          	bge	s1,s4,580 <gets+0x56>
    cc = read(0, &c, 1);
 554:	4605                	li	a2,1
 556:	faf40593          	addi	a1,s0,-81
 55a:	4501                	li	a0,0
 55c:	00000097          	auipc	ra,0x0
 560:	1a0080e7          	jalr	416(ra) # 6fc <read>
    if(cc < 1)
 564:	00a05e63          	blez	a0,580 <gets+0x56>
    buf[i++] = c;
 568:	faf44783          	lbu	a5,-81(s0)
 56c:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 570:	01578763          	beq	a5,s5,57e <gets+0x54>
 574:	0905                	addi	s2,s2,1
 576:	fd679be3          	bne	a5,s6,54c <gets+0x22>
  for(i=0; i+1 < max; ){
 57a:	89a6                	mv	s3,s1
 57c:	a011                	j	580 <gets+0x56>
 57e:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 580:	99de                	add	s3,s3,s7
 582:	00098023          	sb	zero,0(s3)
  return buf;
}
 586:	855e                	mv	a0,s7
 588:	60e6                	ld	ra,88(sp)
 58a:	6446                	ld	s0,80(sp)
 58c:	64a6                	ld	s1,72(sp)
 58e:	6906                	ld	s2,64(sp)
 590:	79e2                	ld	s3,56(sp)
 592:	7a42                	ld	s4,48(sp)
 594:	7aa2                	ld	s5,40(sp)
 596:	7b02                	ld	s6,32(sp)
 598:	6be2                	ld	s7,24(sp)
 59a:	6125                	addi	sp,sp,96
 59c:	8082                	ret

000000000000059e <stat>:

int
stat(const char *n, struct stat *st)
{
 59e:	1101                	addi	sp,sp,-32
 5a0:	ec06                	sd	ra,24(sp)
 5a2:	e822                	sd	s0,16(sp)
 5a4:	e426                	sd	s1,8(sp)
 5a6:	e04a                	sd	s2,0(sp)
 5a8:	1000                	addi	s0,sp,32
 5aa:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 5ac:	4581                	li	a1,0
 5ae:	00000097          	auipc	ra,0x0
 5b2:	176080e7          	jalr	374(ra) # 724 <open>
  if(fd < 0)
 5b6:	02054563          	bltz	a0,5e0 <stat+0x42>
 5ba:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 5bc:	85ca                	mv	a1,s2
 5be:	00000097          	auipc	ra,0x0
 5c2:	17e080e7          	jalr	382(ra) # 73c <fstat>
 5c6:	892a                	mv	s2,a0
  close(fd);
 5c8:	8526                	mv	a0,s1
 5ca:	00000097          	auipc	ra,0x0
 5ce:	142080e7          	jalr	322(ra) # 70c <close>
  return r;
}
 5d2:	854a                	mv	a0,s2
 5d4:	60e2                	ld	ra,24(sp)
 5d6:	6442                	ld	s0,16(sp)
 5d8:	64a2                	ld	s1,8(sp)
 5da:	6902                	ld	s2,0(sp)
 5dc:	6105                	addi	sp,sp,32
 5de:	8082                	ret
    return -1;
 5e0:	597d                	li	s2,-1
 5e2:	bfc5                	j	5d2 <stat+0x34>

00000000000005e4 <atoi>:

int
atoi(const char *s)
{
 5e4:	1141                	addi	sp,sp,-16
 5e6:	e422                	sd	s0,8(sp)
 5e8:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 5ea:	00054603          	lbu	a2,0(a0)
 5ee:	fd06079b          	addiw	a5,a2,-48
 5f2:	0ff7f793          	andi	a5,a5,255
 5f6:	4725                	li	a4,9
 5f8:	02f76963          	bltu	a4,a5,62a <atoi+0x46>
 5fc:	86aa                	mv	a3,a0
  n = 0;
 5fe:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 600:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 602:	0685                	addi	a3,a3,1
 604:	0025179b          	slliw	a5,a0,0x2
 608:	9fa9                	addw	a5,a5,a0
 60a:	0017979b          	slliw	a5,a5,0x1
 60e:	9fb1                	addw	a5,a5,a2
 610:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 614:	0006c603          	lbu	a2,0(a3)
 618:	fd06071b          	addiw	a4,a2,-48
 61c:	0ff77713          	andi	a4,a4,255
 620:	fee5f1e3          	bgeu	a1,a4,602 <atoi+0x1e>
  return n;
}
 624:	6422                	ld	s0,8(sp)
 626:	0141                	addi	sp,sp,16
 628:	8082                	ret
  n = 0;
 62a:	4501                	li	a0,0
 62c:	bfe5                	j	624 <atoi+0x40>

000000000000062e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 62e:	1141                	addi	sp,sp,-16
 630:	e422                	sd	s0,8(sp)
 632:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 634:	02b57663          	bgeu	a0,a1,660 <memmove+0x32>
    while(n-- > 0)
 638:	02c05163          	blez	a2,65a <memmove+0x2c>
 63c:	fff6079b          	addiw	a5,a2,-1
 640:	1782                	slli	a5,a5,0x20
 642:	9381                	srli	a5,a5,0x20
 644:	0785                	addi	a5,a5,1
 646:	97aa                	add	a5,a5,a0
  dst = vdst;
 648:	872a                	mv	a4,a0
      *dst++ = *src++;
 64a:	0585                	addi	a1,a1,1
 64c:	0705                	addi	a4,a4,1
 64e:	fff5c683          	lbu	a3,-1(a1)
 652:	fed70fa3          	sb	a3,-1(a4) # 1fff <__global_pointer$+0xae6>
    while(n-- > 0)
 656:	fee79ae3          	bne	a5,a4,64a <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 65a:	6422                	ld	s0,8(sp)
 65c:	0141                	addi	sp,sp,16
 65e:	8082                	ret
    dst += n;
 660:	00c50733          	add	a4,a0,a2
    src += n;
 664:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 666:	fec05ae3          	blez	a2,65a <memmove+0x2c>
 66a:	fff6079b          	addiw	a5,a2,-1
 66e:	1782                	slli	a5,a5,0x20
 670:	9381                	srli	a5,a5,0x20
 672:	fff7c793          	not	a5,a5
 676:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 678:	15fd                	addi	a1,a1,-1
 67a:	177d                	addi	a4,a4,-1
 67c:	0005c683          	lbu	a3,0(a1)
 680:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 684:	fee79ae3          	bne	a5,a4,678 <memmove+0x4a>
 688:	bfc9                	j	65a <memmove+0x2c>

000000000000068a <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 68a:	1141                	addi	sp,sp,-16
 68c:	e422                	sd	s0,8(sp)
 68e:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 690:	ca05                	beqz	a2,6c0 <memcmp+0x36>
 692:	fff6069b          	addiw	a3,a2,-1
 696:	1682                	slli	a3,a3,0x20
 698:	9281                	srli	a3,a3,0x20
 69a:	0685                	addi	a3,a3,1
 69c:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 69e:	00054783          	lbu	a5,0(a0)
 6a2:	0005c703          	lbu	a4,0(a1)
 6a6:	00e79863          	bne	a5,a4,6b6 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 6aa:	0505                	addi	a0,a0,1
    p2++;
 6ac:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 6ae:	fed518e3          	bne	a0,a3,69e <memcmp+0x14>
  }
  return 0;
 6b2:	4501                	li	a0,0
 6b4:	a019                	j	6ba <memcmp+0x30>
      return *p1 - *p2;
 6b6:	40e7853b          	subw	a0,a5,a4
}
 6ba:	6422                	ld	s0,8(sp)
 6bc:	0141                	addi	sp,sp,16
 6be:	8082                	ret
  return 0;
 6c0:	4501                	li	a0,0
 6c2:	bfe5                	j	6ba <memcmp+0x30>

00000000000006c4 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 6c4:	1141                	addi	sp,sp,-16
 6c6:	e406                	sd	ra,8(sp)
 6c8:	e022                	sd	s0,0(sp)
 6ca:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 6cc:	00000097          	auipc	ra,0x0
 6d0:	f62080e7          	jalr	-158(ra) # 62e <memmove>
}
 6d4:	60a2                	ld	ra,8(sp)
 6d6:	6402                	ld	s0,0(sp)
 6d8:	0141                	addi	sp,sp,16
 6da:	8082                	ret

00000000000006dc <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 6dc:	4885                	li	a7,1
 ecall
 6de:	00000073          	ecall
 ret
 6e2:	8082                	ret

00000000000006e4 <exit>:
.global exit
exit:
 li a7, SYS_exit
 6e4:	4889                	li	a7,2
 ecall
 6e6:	00000073          	ecall
 ret
 6ea:	8082                	ret

00000000000006ec <wait>:
.global wait
wait:
 li a7, SYS_wait
 6ec:	488d                	li	a7,3
 ecall
 6ee:	00000073          	ecall
 ret
 6f2:	8082                	ret

00000000000006f4 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 6f4:	4891                	li	a7,4
 ecall
 6f6:	00000073          	ecall
 ret
 6fa:	8082                	ret

00000000000006fc <read>:
.global read
read:
 li a7, SYS_read
 6fc:	4895                	li	a7,5
 ecall
 6fe:	00000073          	ecall
 ret
 702:	8082                	ret

0000000000000704 <write>:
.global write
write:
 li a7, SYS_write
 704:	48c1                	li	a7,16
 ecall
 706:	00000073          	ecall
 ret
 70a:	8082                	ret

000000000000070c <close>:
.global close
close:
 li a7, SYS_close
 70c:	48d5                	li	a7,21
 ecall
 70e:	00000073          	ecall
 ret
 712:	8082                	ret

0000000000000714 <kill>:
.global kill
kill:
 li a7, SYS_kill
 714:	4899                	li	a7,6
 ecall
 716:	00000073          	ecall
 ret
 71a:	8082                	ret

000000000000071c <exec>:
.global exec
exec:
 li a7, SYS_exec
 71c:	489d                	li	a7,7
 ecall
 71e:	00000073          	ecall
 ret
 722:	8082                	ret

0000000000000724 <open>:
.global open
open:
 li a7, SYS_open
 724:	48bd                	li	a7,15
 ecall
 726:	00000073          	ecall
 ret
 72a:	8082                	ret

000000000000072c <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 72c:	48c5                	li	a7,17
 ecall
 72e:	00000073          	ecall
 ret
 732:	8082                	ret

0000000000000734 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 734:	48c9                	li	a7,18
 ecall
 736:	00000073          	ecall
 ret
 73a:	8082                	ret

000000000000073c <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 73c:	48a1                	li	a7,8
 ecall
 73e:	00000073          	ecall
 ret
 742:	8082                	ret

0000000000000744 <link>:
.global link
link:
 li a7, SYS_link
 744:	48cd                	li	a7,19
 ecall
 746:	00000073          	ecall
 ret
 74a:	8082                	ret

000000000000074c <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 74c:	48d1                	li	a7,20
 ecall
 74e:	00000073          	ecall
 ret
 752:	8082                	ret

0000000000000754 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 754:	48a5                	li	a7,9
 ecall
 756:	00000073          	ecall
 ret
 75a:	8082                	ret

000000000000075c <dup>:
.global dup
dup:
 li a7, SYS_dup
 75c:	48a9                	li	a7,10
 ecall
 75e:	00000073          	ecall
 ret
 762:	8082                	ret

0000000000000764 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 764:	48ad                	li	a7,11
 ecall
 766:	00000073          	ecall
 ret
 76a:	8082                	ret

000000000000076c <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 76c:	48b1                	li	a7,12
 ecall
 76e:	00000073          	ecall
 ret
 772:	8082                	ret

0000000000000774 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 774:	48b5                	li	a7,13
 ecall
 776:	00000073          	ecall
 ret
 77a:	8082                	ret

000000000000077c <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 77c:	48b9                	li	a7,14
 ecall
 77e:	00000073          	ecall
 ret
 782:	8082                	ret

0000000000000784 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 784:	1101                	addi	sp,sp,-32
 786:	ec06                	sd	ra,24(sp)
 788:	e822                	sd	s0,16(sp)
 78a:	1000                	addi	s0,sp,32
 78c:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 790:	4605                	li	a2,1
 792:	fef40593          	addi	a1,s0,-17
 796:	00000097          	auipc	ra,0x0
 79a:	f6e080e7          	jalr	-146(ra) # 704 <write>
}
 79e:	60e2                	ld	ra,24(sp)
 7a0:	6442                	ld	s0,16(sp)
 7a2:	6105                	addi	sp,sp,32
 7a4:	8082                	ret

00000000000007a6 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 7a6:	7139                	addi	sp,sp,-64
 7a8:	fc06                	sd	ra,56(sp)
 7aa:	f822                	sd	s0,48(sp)
 7ac:	f426                	sd	s1,40(sp)
 7ae:	f04a                	sd	s2,32(sp)
 7b0:	ec4e                	sd	s3,24(sp)
 7b2:	0080                	addi	s0,sp,64
 7b4:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 7b6:	c299                	beqz	a3,7bc <printint+0x16>
 7b8:	0805c863          	bltz	a1,848 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 7bc:	2581                	sext.w	a1,a1
  neg = 0;
 7be:	4881                	li	a7,0
 7c0:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 7c4:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 7c6:	2601                	sext.w	a2,a2
 7c8:	00000517          	auipc	a0,0x0
 7cc:	54050513          	addi	a0,a0,1344 # d08 <digits>
 7d0:	883a                	mv	a6,a4
 7d2:	2705                	addiw	a4,a4,1
 7d4:	02c5f7bb          	remuw	a5,a1,a2
 7d8:	1782                	slli	a5,a5,0x20
 7da:	9381                	srli	a5,a5,0x20
 7dc:	97aa                	add	a5,a5,a0
 7de:	0007c783          	lbu	a5,0(a5)
 7e2:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 7e6:	0005879b          	sext.w	a5,a1
 7ea:	02c5d5bb          	divuw	a1,a1,a2
 7ee:	0685                	addi	a3,a3,1
 7f0:	fec7f0e3          	bgeu	a5,a2,7d0 <printint+0x2a>
  if(neg)
 7f4:	00088b63          	beqz	a7,80a <printint+0x64>
    buf[i++] = '-';
 7f8:	fd040793          	addi	a5,s0,-48
 7fc:	973e                	add	a4,a4,a5
 7fe:	02d00793          	li	a5,45
 802:	fef70823          	sb	a5,-16(a4)
 806:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 80a:	02e05863          	blez	a4,83a <printint+0x94>
 80e:	fc040793          	addi	a5,s0,-64
 812:	00e78933          	add	s2,a5,a4
 816:	fff78993          	addi	s3,a5,-1
 81a:	99ba                	add	s3,s3,a4
 81c:	377d                	addiw	a4,a4,-1
 81e:	1702                	slli	a4,a4,0x20
 820:	9301                	srli	a4,a4,0x20
 822:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 826:	fff94583          	lbu	a1,-1(s2)
 82a:	8526                	mv	a0,s1
 82c:	00000097          	auipc	ra,0x0
 830:	f58080e7          	jalr	-168(ra) # 784 <putc>
  while(--i >= 0)
 834:	197d                	addi	s2,s2,-1
 836:	ff3918e3          	bne	s2,s3,826 <printint+0x80>
}
 83a:	70e2                	ld	ra,56(sp)
 83c:	7442                	ld	s0,48(sp)
 83e:	74a2                	ld	s1,40(sp)
 840:	7902                	ld	s2,32(sp)
 842:	69e2                	ld	s3,24(sp)
 844:	6121                	addi	sp,sp,64
 846:	8082                	ret
    x = -xx;
 848:	40b005bb          	negw	a1,a1
    neg = 1;
 84c:	4885                	li	a7,1
    x = -xx;
 84e:	bf8d                	j	7c0 <printint+0x1a>

0000000000000850 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 850:	7119                	addi	sp,sp,-128
 852:	fc86                	sd	ra,120(sp)
 854:	f8a2                	sd	s0,112(sp)
 856:	f4a6                	sd	s1,104(sp)
 858:	f0ca                	sd	s2,96(sp)
 85a:	ecce                	sd	s3,88(sp)
 85c:	e8d2                	sd	s4,80(sp)
 85e:	e4d6                	sd	s5,72(sp)
 860:	e0da                	sd	s6,64(sp)
 862:	fc5e                	sd	s7,56(sp)
 864:	f862                	sd	s8,48(sp)
 866:	f466                	sd	s9,40(sp)
 868:	f06a                	sd	s10,32(sp)
 86a:	ec6e                	sd	s11,24(sp)
 86c:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 86e:	0005c903          	lbu	s2,0(a1)
 872:	18090f63          	beqz	s2,a10 <vprintf+0x1c0>
 876:	8aaa                	mv	s5,a0
 878:	8b32                	mv	s6,a2
 87a:	00158493          	addi	s1,a1,1
  state = 0;
 87e:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 880:	02500a13          	li	s4,37
      if(c == 'd'){
 884:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 888:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 88c:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 890:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 894:	00000b97          	auipc	s7,0x0
 898:	474b8b93          	addi	s7,s7,1140 # d08 <digits>
 89c:	a839                	j	8ba <vprintf+0x6a>
        putc(fd, c);
 89e:	85ca                	mv	a1,s2
 8a0:	8556                	mv	a0,s5
 8a2:	00000097          	auipc	ra,0x0
 8a6:	ee2080e7          	jalr	-286(ra) # 784 <putc>
 8aa:	a019                	j	8b0 <vprintf+0x60>
    } else if(state == '%'){
 8ac:	01498f63          	beq	s3,s4,8ca <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 8b0:	0485                	addi	s1,s1,1
 8b2:	fff4c903          	lbu	s2,-1(s1)
 8b6:	14090d63          	beqz	s2,a10 <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 8ba:	0009079b          	sext.w	a5,s2
    if(state == 0){
 8be:	fe0997e3          	bnez	s3,8ac <vprintf+0x5c>
      if(c == '%'){
 8c2:	fd479ee3          	bne	a5,s4,89e <vprintf+0x4e>
        state = '%';
 8c6:	89be                	mv	s3,a5
 8c8:	b7e5                	j	8b0 <vprintf+0x60>
      if(c == 'd'){
 8ca:	05878063          	beq	a5,s8,90a <vprintf+0xba>
      } else if(c == 'l') {
 8ce:	05978c63          	beq	a5,s9,926 <vprintf+0xd6>
      } else if(c == 'x') {
 8d2:	07a78863          	beq	a5,s10,942 <vprintf+0xf2>
      } else if(c == 'p') {
 8d6:	09b78463          	beq	a5,s11,95e <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 8da:	07300713          	li	a4,115
 8de:	0ce78663          	beq	a5,a4,9aa <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 8e2:	06300713          	li	a4,99
 8e6:	0ee78e63          	beq	a5,a4,9e2 <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 8ea:	11478863          	beq	a5,s4,9fa <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 8ee:	85d2                	mv	a1,s4
 8f0:	8556                	mv	a0,s5
 8f2:	00000097          	auipc	ra,0x0
 8f6:	e92080e7          	jalr	-366(ra) # 784 <putc>
        putc(fd, c);
 8fa:	85ca                	mv	a1,s2
 8fc:	8556                	mv	a0,s5
 8fe:	00000097          	auipc	ra,0x0
 902:	e86080e7          	jalr	-378(ra) # 784 <putc>
      }
      state = 0;
 906:	4981                	li	s3,0
 908:	b765                	j	8b0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 90a:	008b0913          	addi	s2,s6,8
 90e:	4685                	li	a3,1
 910:	4629                	li	a2,10
 912:	000b2583          	lw	a1,0(s6)
 916:	8556                	mv	a0,s5
 918:	00000097          	auipc	ra,0x0
 91c:	e8e080e7          	jalr	-370(ra) # 7a6 <printint>
 920:	8b4a                	mv	s6,s2
      state = 0;
 922:	4981                	li	s3,0
 924:	b771                	j	8b0 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 926:	008b0913          	addi	s2,s6,8
 92a:	4681                	li	a3,0
 92c:	4629                	li	a2,10
 92e:	000b2583          	lw	a1,0(s6)
 932:	8556                	mv	a0,s5
 934:	00000097          	auipc	ra,0x0
 938:	e72080e7          	jalr	-398(ra) # 7a6 <printint>
 93c:	8b4a                	mv	s6,s2
      state = 0;
 93e:	4981                	li	s3,0
 940:	bf85                	j	8b0 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 942:	008b0913          	addi	s2,s6,8
 946:	4681                	li	a3,0
 948:	4641                	li	a2,16
 94a:	000b2583          	lw	a1,0(s6)
 94e:	8556                	mv	a0,s5
 950:	00000097          	auipc	ra,0x0
 954:	e56080e7          	jalr	-426(ra) # 7a6 <printint>
 958:	8b4a                	mv	s6,s2
      state = 0;
 95a:	4981                	li	s3,0
 95c:	bf91                	j	8b0 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 95e:	008b0793          	addi	a5,s6,8
 962:	f8f43423          	sd	a5,-120(s0)
 966:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 96a:	03000593          	li	a1,48
 96e:	8556                	mv	a0,s5
 970:	00000097          	auipc	ra,0x0
 974:	e14080e7          	jalr	-492(ra) # 784 <putc>
  putc(fd, 'x');
 978:	85ea                	mv	a1,s10
 97a:	8556                	mv	a0,s5
 97c:	00000097          	auipc	ra,0x0
 980:	e08080e7          	jalr	-504(ra) # 784 <putc>
 984:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 986:	03c9d793          	srli	a5,s3,0x3c
 98a:	97de                	add	a5,a5,s7
 98c:	0007c583          	lbu	a1,0(a5)
 990:	8556                	mv	a0,s5
 992:	00000097          	auipc	ra,0x0
 996:	df2080e7          	jalr	-526(ra) # 784 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 99a:	0992                	slli	s3,s3,0x4
 99c:	397d                	addiw	s2,s2,-1
 99e:	fe0914e3          	bnez	s2,986 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 9a2:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 9a6:	4981                	li	s3,0
 9a8:	b721                	j	8b0 <vprintf+0x60>
        s = va_arg(ap, char*);
 9aa:	008b0993          	addi	s3,s6,8
 9ae:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 9b2:	02090163          	beqz	s2,9d4 <vprintf+0x184>
        while(*s != 0){
 9b6:	00094583          	lbu	a1,0(s2)
 9ba:	c9a1                	beqz	a1,a0a <vprintf+0x1ba>
          putc(fd, *s);
 9bc:	8556                	mv	a0,s5
 9be:	00000097          	auipc	ra,0x0
 9c2:	dc6080e7          	jalr	-570(ra) # 784 <putc>
          s++;
 9c6:	0905                	addi	s2,s2,1
        while(*s != 0){
 9c8:	00094583          	lbu	a1,0(s2)
 9cc:	f9e5                	bnez	a1,9bc <vprintf+0x16c>
        s = va_arg(ap, char*);
 9ce:	8b4e                	mv	s6,s3
      state = 0;
 9d0:	4981                	li	s3,0
 9d2:	bdf9                	j	8b0 <vprintf+0x60>
          s = "(null)";
 9d4:	00000917          	auipc	s2,0x0
 9d8:	32c90913          	addi	s2,s2,812 # d00 <malloc+0x1e6>
        while(*s != 0){
 9dc:	02800593          	li	a1,40
 9e0:	bff1                	j	9bc <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 9e2:	008b0913          	addi	s2,s6,8
 9e6:	000b4583          	lbu	a1,0(s6)
 9ea:	8556                	mv	a0,s5
 9ec:	00000097          	auipc	ra,0x0
 9f0:	d98080e7          	jalr	-616(ra) # 784 <putc>
 9f4:	8b4a                	mv	s6,s2
      state = 0;
 9f6:	4981                	li	s3,0
 9f8:	bd65                	j	8b0 <vprintf+0x60>
        putc(fd, c);
 9fa:	85d2                	mv	a1,s4
 9fc:	8556                	mv	a0,s5
 9fe:	00000097          	auipc	ra,0x0
 a02:	d86080e7          	jalr	-634(ra) # 784 <putc>
      state = 0;
 a06:	4981                	li	s3,0
 a08:	b565                	j	8b0 <vprintf+0x60>
        s = va_arg(ap, char*);
 a0a:	8b4e                	mv	s6,s3
      state = 0;
 a0c:	4981                	li	s3,0
 a0e:	b54d                	j	8b0 <vprintf+0x60>
    }
  }
}
 a10:	70e6                	ld	ra,120(sp)
 a12:	7446                	ld	s0,112(sp)
 a14:	74a6                	ld	s1,104(sp)
 a16:	7906                	ld	s2,96(sp)
 a18:	69e6                	ld	s3,88(sp)
 a1a:	6a46                	ld	s4,80(sp)
 a1c:	6aa6                	ld	s5,72(sp)
 a1e:	6b06                	ld	s6,64(sp)
 a20:	7be2                	ld	s7,56(sp)
 a22:	7c42                	ld	s8,48(sp)
 a24:	7ca2                	ld	s9,40(sp)
 a26:	7d02                	ld	s10,32(sp)
 a28:	6de2                	ld	s11,24(sp)
 a2a:	6109                	addi	sp,sp,128
 a2c:	8082                	ret

0000000000000a2e <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 a2e:	715d                	addi	sp,sp,-80
 a30:	ec06                	sd	ra,24(sp)
 a32:	e822                	sd	s0,16(sp)
 a34:	1000                	addi	s0,sp,32
 a36:	e010                	sd	a2,0(s0)
 a38:	e414                	sd	a3,8(s0)
 a3a:	e818                	sd	a4,16(s0)
 a3c:	ec1c                	sd	a5,24(s0)
 a3e:	03043023          	sd	a6,32(s0)
 a42:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 a46:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 a4a:	8622                	mv	a2,s0
 a4c:	00000097          	auipc	ra,0x0
 a50:	e04080e7          	jalr	-508(ra) # 850 <vprintf>
}
 a54:	60e2                	ld	ra,24(sp)
 a56:	6442                	ld	s0,16(sp)
 a58:	6161                	addi	sp,sp,80
 a5a:	8082                	ret

0000000000000a5c <printf>:

void
printf(const char *fmt, ...)
{
 a5c:	711d                	addi	sp,sp,-96
 a5e:	ec06                	sd	ra,24(sp)
 a60:	e822                	sd	s0,16(sp)
 a62:	1000                	addi	s0,sp,32
 a64:	e40c                	sd	a1,8(s0)
 a66:	e810                	sd	a2,16(s0)
 a68:	ec14                	sd	a3,24(s0)
 a6a:	f018                	sd	a4,32(s0)
 a6c:	f41c                	sd	a5,40(s0)
 a6e:	03043823          	sd	a6,48(s0)
 a72:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 a76:	00840613          	addi	a2,s0,8
 a7a:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 a7e:	85aa                	mv	a1,a0
 a80:	4505                	li	a0,1
 a82:	00000097          	auipc	ra,0x0
 a86:	dce080e7          	jalr	-562(ra) # 850 <vprintf>
}
 a8a:	60e2                	ld	ra,24(sp)
 a8c:	6442                	ld	s0,16(sp)
 a8e:	6125                	addi	sp,sp,96
 a90:	8082                	ret

0000000000000a92 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 a92:	1141                	addi	sp,sp,-16
 a94:	e422                	sd	s0,8(sp)
 a96:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 a98:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 a9c:	00000797          	auipc	a5,0x0
 aa0:	2a47b783          	ld	a5,676(a5) # d40 <freep>
 aa4:	a805                	j	ad4 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 aa6:	4618                	lw	a4,8(a2)
 aa8:	9db9                	addw	a1,a1,a4
 aaa:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 aae:	6398                	ld	a4,0(a5)
 ab0:	6318                	ld	a4,0(a4)
 ab2:	fee53823          	sd	a4,-16(a0)
 ab6:	a091                	j	afa <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 ab8:	ff852703          	lw	a4,-8(a0)
 abc:	9e39                	addw	a2,a2,a4
 abe:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 ac0:	ff053703          	ld	a4,-16(a0)
 ac4:	e398                	sd	a4,0(a5)
 ac6:	a099                	j	b0c <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ac8:	6398                	ld	a4,0(a5)
 aca:	00e7e463          	bltu	a5,a4,ad2 <free+0x40>
 ace:	00e6ea63          	bltu	a3,a4,ae2 <free+0x50>
{
 ad2:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 ad4:	fed7fae3          	bgeu	a5,a3,ac8 <free+0x36>
 ad8:	6398                	ld	a4,0(a5)
 ada:	00e6e463          	bltu	a3,a4,ae2 <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 ade:	fee7eae3          	bltu	a5,a4,ad2 <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 ae2:	ff852583          	lw	a1,-8(a0)
 ae6:	6390                	ld	a2,0(a5)
 ae8:	02059713          	slli	a4,a1,0x20
 aec:	9301                	srli	a4,a4,0x20
 aee:	0712                	slli	a4,a4,0x4
 af0:	9736                	add	a4,a4,a3
 af2:	fae60ae3          	beq	a2,a4,aa6 <free+0x14>
    bp->s.ptr = p->s.ptr;
 af6:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 afa:	4790                	lw	a2,8(a5)
 afc:	02061713          	slli	a4,a2,0x20
 b00:	9301                	srli	a4,a4,0x20
 b02:	0712                	slli	a4,a4,0x4
 b04:	973e                	add	a4,a4,a5
 b06:	fae689e3          	beq	a3,a4,ab8 <free+0x26>
  } else
    p->s.ptr = bp;
 b0a:	e394                	sd	a3,0(a5)
  freep = p;
 b0c:	00000717          	auipc	a4,0x0
 b10:	22f73a23          	sd	a5,564(a4) # d40 <freep>
}
 b14:	6422                	ld	s0,8(sp)
 b16:	0141                	addi	sp,sp,16
 b18:	8082                	ret

0000000000000b1a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 b1a:	7139                	addi	sp,sp,-64
 b1c:	fc06                	sd	ra,56(sp)
 b1e:	f822                	sd	s0,48(sp)
 b20:	f426                	sd	s1,40(sp)
 b22:	f04a                	sd	s2,32(sp)
 b24:	ec4e                	sd	s3,24(sp)
 b26:	e852                	sd	s4,16(sp)
 b28:	e456                	sd	s5,8(sp)
 b2a:	e05a                	sd	s6,0(sp)
 b2c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 b2e:	02051493          	slli	s1,a0,0x20
 b32:	9081                	srli	s1,s1,0x20
 b34:	04bd                	addi	s1,s1,15
 b36:	8091                	srli	s1,s1,0x4
 b38:	0014899b          	addiw	s3,s1,1
 b3c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 b3e:	00000517          	auipc	a0,0x0
 b42:	20253503          	ld	a0,514(a0) # d40 <freep>
 b46:	c515                	beqz	a0,b72 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 b48:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 b4a:	4798                	lw	a4,8(a5)
 b4c:	02977f63          	bgeu	a4,s1,b8a <malloc+0x70>
 b50:	8a4e                	mv	s4,s3
 b52:	0009871b          	sext.w	a4,s3
 b56:	6685                	lui	a3,0x1
 b58:	00d77363          	bgeu	a4,a3,b5e <malloc+0x44>
 b5c:	6a05                	lui	s4,0x1
 b5e:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 b62:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 b66:	00000917          	auipc	s2,0x0
 b6a:	1da90913          	addi	s2,s2,474 # d40 <freep>
  if(p == (char*)-1)
 b6e:	5afd                	li	s5,-1
 b70:	a88d                	j	be2 <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 b72:	00008797          	auipc	a5,0x8
 b76:	3b678793          	addi	a5,a5,950 # 8f28 <base>
 b7a:	00000717          	auipc	a4,0x0
 b7e:	1cf73323          	sd	a5,454(a4) # d40 <freep>
 b82:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 b84:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 b88:	b7e1                	j	b50 <malloc+0x36>
      if(p->s.size == nunits)
 b8a:	02e48b63          	beq	s1,a4,bc0 <malloc+0xa6>
        p->s.size -= nunits;
 b8e:	4137073b          	subw	a4,a4,s3
 b92:	c798                	sw	a4,8(a5)
        p += p->s.size;
 b94:	1702                	slli	a4,a4,0x20
 b96:	9301                	srli	a4,a4,0x20
 b98:	0712                	slli	a4,a4,0x4
 b9a:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 b9c:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 ba0:	00000717          	auipc	a4,0x0
 ba4:	1aa73023          	sd	a0,416(a4) # d40 <freep>
      return (void*)(p + 1);
 ba8:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 bac:	70e2                	ld	ra,56(sp)
 bae:	7442                	ld	s0,48(sp)
 bb0:	74a2                	ld	s1,40(sp)
 bb2:	7902                	ld	s2,32(sp)
 bb4:	69e2                	ld	s3,24(sp)
 bb6:	6a42                	ld	s4,16(sp)
 bb8:	6aa2                	ld	s5,8(sp)
 bba:	6b02                	ld	s6,0(sp)
 bbc:	6121                	addi	sp,sp,64
 bbe:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 bc0:	6398                	ld	a4,0(a5)
 bc2:	e118                	sd	a4,0(a0)
 bc4:	bff1                	j	ba0 <malloc+0x86>
  hp->s.size = nu;
 bc6:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 bca:	0541                	addi	a0,a0,16
 bcc:	00000097          	auipc	ra,0x0
 bd0:	ec6080e7          	jalr	-314(ra) # a92 <free>
  return freep;
 bd4:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 bd8:	d971                	beqz	a0,bac <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 bda:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 bdc:	4798                	lw	a4,8(a5)
 bde:	fa9776e3          	bgeu	a4,s1,b8a <malloc+0x70>
    if(p == freep)
 be2:	00093703          	ld	a4,0(s2)
 be6:	853e                	mv	a0,a5
 be8:	fef719e3          	bne	a4,a5,bda <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 bec:	8552                	mv	a0,s4
 bee:	00000097          	auipc	ra,0x0
 bf2:	b7e080e7          	jalr	-1154(ra) # 76c <sbrk>
  if(p == (char*)-1)
 bf6:	fd5518e3          	bne	a0,s5,bc6 <malloc+0xac>
        return 0;
 bfa:	4501                	li	a0,0
 bfc:	bf45                	j	bac <malloc+0x92>
