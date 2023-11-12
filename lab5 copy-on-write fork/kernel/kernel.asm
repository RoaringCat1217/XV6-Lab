
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	86013103          	ld	sp,-1952(sp) # 80008860 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	070000ef          	jal	ra,80000086 <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    80000026:	0037969b          	slliw	a3,a5,0x3
    8000002a:	02004737          	lui	a4,0x2004
    8000002e:	96ba                	add	a3,a3,a4
    80000030:	0200c737          	lui	a4,0x200c
    80000034:	ff873603          	ld	a2,-8(a4) # 200bff8 <_entry-0x7dff4008>
    80000038:	000f4737          	lui	a4,0xf4
    8000003c:	24070713          	addi	a4,a4,576 # f4240 <_entry-0x7ff0bdc0>
    80000040:	963a                	add	a2,a2,a4
    80000042:	e290                	sd	a2,0(a3)

  // prepare information in scratch[] for timervec.
  // scratch[0..3] : space for timervec to save registers.
  // scratch[4] : address of CLINT MTIMECMP register.
  // scratch[5] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &mscratch0[32 * id];
    80000044:	0057979b          	slliw	a5,a5,0x5
    80000048:	078e                	slli	a5,a5,0x3
    8000004a:	00009617          	auipc	a2,0x9
    8000004e:	fe660613          	addi	a2,a2,-26 # 80009030 <mscratch0>
    80000052:	97b2                	add	a5,a5,a2
  scratch[4] = CLINT_MTIMECMP(id);
    80000054:	f394                	sd	a3,32(a5)
  scratch[5] = interval;
    80000056:	f798                	sd	a4,40(a5)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000058:	34079073          	csrw	mscratch,a5
  asm volatile("csrw mtvec, %0" : : "r" (x));
    8000005c:	00006797          	auipc	a5,0x6
    80000060:	d5478793          	addi	a5,a5,-684 # 80005db0 <timervec>
    80000064:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000068:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    8000006c:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000070:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    80000074:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000078:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    8000007c:	30479073          	csrw	mie,a5
}
    80000080:	6422                	ld	s0,8(sp)
    80000082:	0141                	addi	sp,sp,16
    80000084:	8082                	ret

0000000080000086 <start>:
{
    80000086:	1141                	addi	sp,sp,-16
    80000088:	e406                	sd	ra,8(sp)
    8000008a:	e022                	sd	s0,0(sp)
    8000008c:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000008e:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000092:	7779                	lui	a4,0xffffe
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	ede78793          	addi	a5,a5,-290 # 80000f84 <main>
    800000ae:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b2:	4781                	li	a5,0
    800000b4:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000b8:	67c1                	lui	a5,0x10
    800000ba:	17fd                	addi	a5,a5,-1
    800000bc:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c0:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000c4:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000c8:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000cc:	10479073          	csrw	sie,a5
  timerinit();
    800000d0:	00000097          	auipc	ra,0x0
    800000d4:	f4c080e7          	jalr	-180(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000d8:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000dc:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000de:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e0:	30200073          	mret
}
    800000e4:	60a2                	ld	ra,8(sp)
    800000e6:	6402                	ld	s0,0(sp)
    800000e8:	0141                	addi	sp,sp,16
    800000ea:	8082                	ret

00000000800000ec <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000ec:	715d                	addi	sp,sp,-80
    800000ee:	e486                	sd	ra,72(sp)
    800000f0:	e0a2                	sd	s0,64(sp)
    800000f2:	fc26                	sd	s1,56(sp)
    800000f4:	f84a                	sd	s2,48(sp)
    800000f6:	f44e                	sd	s3,40(sp)
    800000f8:	f052                	sd	s4,32(sp)
    800000fa:	ec56                	sd	s5,24(sp)
    800000fc:	0880                	addi	s0,sp,80
    800000fe:	8a2a                	mv	s4,a0
    80000100:	84ae                	mv	s1,a1
    80000102:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    80000104:	00011517          	auipc	a0,0x11
    80000108:	72c50513          	addi	a0,a0,1836 # 80011830 <cons>
    8000010c:	00001097          	auipc	ra,0x1
    80000110:	bca080e7          	jalr	-1078(ra) # 80000cd6 <acquire>
  for(i = 0; i < n; i++){
    80000114:	05305b63          	blez	s3,8000016a <consolewrite+0x7e>
    80000118:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011a:	5afd                	li	s5,-1
    8000011c:	4685                	li	a3,1
    8000011e:	8626                	mv	a2,s1
    80000120:	85d2                	mv	a1,s4
    80000122:	fbf40513          	addi	a0,s0,-65
    80000126:	00002097          	auipc	ra,0x2
    8000012a:	52e080e7          	jalr	1326(ra) # 80002654 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00000097          	auipc	ra,0x0
    8000013a:	7aa080e7          	jalr	1962(ra) # 800008e0 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	c3c080e7          	jalr	-964(ra) # 80000d8a <release>

  return i;
}
    80000156:	854a                	mv	a0,s2
    80000158:	60a6                	ld	ra,72(sp)
    8000015a:	6406                	ld	s0,64(sp)
    8000015c:	74e2                	ld	s1,56(sp)
    8000015e:	7942                	ld	s2,48(sp)
    80000160:	79a2                	ld	s3,40(sp)
    80000162:	7a02                	ld	s4,32(sp)
    80000164:	6ae2                	ld	s5,24(sp)
    80000166:	6161                	addi	sp,sp,80
    80000168:	8082                	ret
  for(i = 0; i < n; i++){
    8000016a:	4901                	li	s2,0
    8000016c:	bfe9                	j	80000146 <consolewrite+0x5a>

000000008000016e <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    8000016e:	7119                	addi	sp,sp,-128
    80000170:	fc86                	sd	ra,120(sp)
    80000172:	f8a2                	sd	s0,112(sp)
    80000174:	f4a6                	sd	s1,104(sp)
    80000176:	f0ca                	sd	s2,96(sp)
    80000178:	ecce                	sd	s3,88(sp)
    8000017a:	e8d2                	sd	s4,80(sp)
    8000017c:	e4d6                	sd	s5,72(sp)
    8000017e:	e0da                	sd	s6,64(sp)
    80000180:	fc5e                	sd	s7,56(sp)
    80000182:	f862                	sd	s8,48(sp)
    80000184:	f466                	sd	s9,40(sp)
    80000186:	f06a                	sd	s10,32(sp)
    80000188:	ec6e                	sd	s11,24(sp)
    8000018a:	0100                	addi	s0,sp,128
    8000018c:	8b2a                	mv	s6,a0
    8000018e:	8aae                	mv	s5,a1
    80000190:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000192:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    80000196:	00011517          	auipc	a0,0x11
    8000019a:	69a50513          	addi	a0,a0,1690 # 80011830 <cons>
    8000019e:	00001097          	auipc	ra,0x1
    800001a2:	b38080e7          	jalr	-1224(ra) # 80000cd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001a6:	00011497          	auipc	s1,0x11
    800001aa:	68a48493          	addi	s1,s1,1674 # 80011830 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001ae:	89a6                	mv	s3,s1
    800001b0:	00011917          	auipc	s2,0x11
    800001b4:	71890913          	addi	s2,s2,1816 # 800118c8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001b8:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ba:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001bc:	4da9                	li	s11,10
  while(n > 0){
    800001be:	07405863          	blez	s4,8000022e <consoleread+0xc0>
    while(cons.r == cons.w){
    800001c2:	0984a783          	lw	a5,152(s1)
    800001c6:	09c4a703          	lw	a4,156(s1)
    800001ca:	02f71463          	bne	a4,a5,800001f2 <consoleread+0x84>
      if(myproc()->killed){
    800001ce:	00002097          	auipc	ra,0x2
    800001d2:	9be080e7          	jalr	-1602(ra) # 80001b8c <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	1be080e7          	jalr	446(ra) # 8000239c <sleep>
    while(cons.r == cons.w){
    800001e6:	0984a783          	lw	a5,152(s1)
    800001ea:	09c4a703          	lw	a4,156(s1)
    800001ee:	fef700e3          	beq	a4,a5,800001ce <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001f2:	0017871b          	addiw	a4,a5,1
    800001f6:	08e4ac23          	sw	a4,152(s1)
    800001fa:	07f7f713          	andi	a4,a5,127
    800001fe:	9726                	add	a4,a4,s1
    80000200:	01874703          	lbu	a4,24(a4)
    80000204:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000208:	079c0663          	beq	s8,s9,80000274 <consoleread+0x106>
    cbuf = c;
    8000020c:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000210:	4685                	li	a3,1
    80000212:	f8f40613          	addi	a2,s0,-113
    80000216:	85d6                	mv	a1,s5
    80000218:	855a                	mv	a0,s6
    8000021a:	00002097          	auipc	ra,0x2
    8000021e:	3e4080e7          	jalr	996(ra) # 800025fe <either_copyout>
    80000222:	01a50663          	beq	a0,s10,8000022e <consoleread+0xc0>
    dst++;
    80000226:	0a85                	addi	s5,s5,1
    --n;
    80000228:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    8000022a:	f9bc1ae3          	bne	s8,s11,800001be <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022e:	00011517          	auipc	a0,0x11
    80000232:	60250513          	addi	a0,a0,1538 # 80011830 <cons>
    80000236:	00001097          	auipc	ra,0x1
    8000023a:	b54080e7          	jalr	-1196(ra) # 80000d8a <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	b3e080e7          	jalr	-1218(ra) # 80000d8a <release>
        return -1;
    80000254:	557d                	li	a0,-1
}
    80000256:	70e6                	ld	ra,120(sp)
    80000258:	7446                	ld	s0,112(sp)
    8000025a:	74a6                	ld	s1,104(sp)
    8000025c:	7906                	ld	s2,96(sp)
    8000025e:	69e6                	ld	s3,88(sp)
    80000260:	6a46                	ld	s4,80(sp)
    80000262:	6aa6                	ld	s5,72(sp)
    80000264:	6b06                	ld	s6,64(sp)
    80000266:	7be2                	ld	s7,56(sp)
    80000268:	7c42                	ld	s8,48(sp)
    8000026a:	7ca2                	ld	s9,40(sp)
    8000026c:	7d02                	ld	s10,32(sp)
    8000026e:	6de2                	ld	s11,24(sp)
    80000270:	6109                	addi	sp,sp,128
    80000272:	8082                	ret
      if(n < target){
    80000274:	000a071b          	sext.w	a4,s4
    80000278:	fb777be3          	bgeu	a4,s7,8000022e <consoleread+0xc0>
        cons.r--;
    8000027c:	00011717          	auipc	a4,0x11
    80000280:	64f72623          	sw	a5,1612(a4) # 800118c8 <cons+0x98>
    80000284:	b76d                	j	8000022e <consoleread+0xc0>

0000000080000286 <consputc>:
{
    80000286:	1141                	addi	sp,sp,-16
    80000288:	e406                	sd	ra,8(sp)
    8000028a:	e022                	sd	s0,0(sp)
    8000028c:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028e:	10000793          	li	a5,256
    80000292:	00f50a63          	beq	a0,a5,800002a6 <consputc+0x20>
    uartputc_sync(c);
    80000296:	00000097          	auipc	ra,0x0
    8000029a:	564080e7          	jalr	1380(ra) # 800007fa <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	552080e7          	jalr	1362(ra) # 800007fa <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	546080e7          	jalr	1350(ra) # 800007fa <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	53c080e7          	jalr	1340(ra) # 800007fa <uartputc_sync>
    800002c6:	bfe1                	j	8000029e <consputc+0x18>

00000000800002c8 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c8:	1101                	addi	sp,sp,-32
    800002ca:	ec06                	sd	ra,24(sp)
    800002cc:	e822                	sd	s0,16(sp)
    800002ce:	e426                	sd	s1,8(sp)
    800002d0:	e04a                	sd	s2,0(sp)
    800002d2:	1000                	addi	s0,sp,32
    800002d4:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d6:	00011517          	auipc	a0,0x11
    800002da:	55a50513          	addi	a0,a0,1370 # 80011830 <cons>
    800002de:	00001097          	auipc	ra,0x1
    800002e2:	9f8080e7          	jalr	-1544(ra) # 80000cd6 <acquire>

  switch(c){
    800002e6:	47d5                	li	a5,21
    800002e8:	0af48663          	beq	s1,a5,80000394 <consoleintr+0xcc>
    800002ec:	0297ca63          	blt	a5,s1,80000320 <consoleintr+0x58>
    800002f0:	47a1                	li	a5,8
    800002f2:	0ef48763          	beq	s1,a5,800003e0 <consoleintr+0x118>
    800002f6:	47c1                	li	a5,16
    800002f8:	10f49a63          	bne	s1,a5,8000040c <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002fc:	00002097          	auipc	ra,0x2
    80000300:	3ae080e7          	jalr	942(ra) # 800026aa <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a7e080e7          	jalr	-1410(ra) # 80000d8a <release>
}
    80000314:	60e2                	ld	ra,24(sp)
    80000316:	6442                	ld	s0,16(sp)
    80000318:	64a2                	ld	s1,8(sp)
    8000031a:	6902                	ld	s2,0(sp)
    8000031c:	6105                	addi	sp,sp,32
    8000031e:	8082                	ret
  switch(c){
    80000320:	07f00793          	li	a5,127
    80000324:	0af48e63          	beq	s1,a5,800003e0 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000328:	00011717          	auipc	a4,0x11
    8000032c:	50870713          	addi	a4,a4,1288 # 80011830 <cons>
    80000330:	0a072783          	lw	a5,160(a4)
    80000334:	09872703          	lw	a4,152(a4)
    80000338:	9f99                	subw	a5,a5,a4
    8000033a:	07f00713          	li	a4,127
    8000033e:	fcf763e3          	bltu	a4,a5,80000304 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000342:	47b5                	li	a5,13
    80000344:	0cf48763          	beq	s1,a5,80000412 <consoleintr+0x14a>
      consputc(c);
    80000348:	8526                	mv	a0,s1
    8000034a:	00000097          	auipc	ra,0x0
    8000034e:	f3c080e7          	jalr	-196(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000352:	00011797          	auipc	a5,0x11
    80000356:	4de78793          	addi	a5,a5,1246 # 80011830 <cons>
    8000035a:	0a07a703          	lw	a4,160(a5)
    8000035e:	0017069b          	addiw	a3,a4,1
    80000362:	0006861b          	sext.w	a2,a3
    80000366:	0ad7a023          	sw	a3,160(a5)
    8000036a:	07f77713          	andi	a4,a4,127
    8000036e:	97ba                	add	a5,a5,a4
    80000370:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    80000374:	47a9                	li	a5,10
    80000376:	0cf48563          	beq	s1,a5,80000440 <consoleintr+0x178>
    8000037a:	4791                	li	a5,4
    8000037c:	0cf48263          	beq	s1,a5,80000440 <consoleintr+0x178>
    80000380:	00011797          	auipc	a5,0x11
    80000384:	5487a783          	lw	a5,1352(a5) # 800118c8 <cons+0x98>
    80000388:	0807879b          	addiw	a5,a5,128
    8000038c:	f6f61ce3          	bne	a2,a5,80000304 <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000390:	863e                	mv	a2,a5
    80000392:	a07d                	j	80000440 <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000394:	00011717          	auipc	a4,0x11
    80000398:	49c70713          	addi	a4,a4,1180 # 80011830 <cons>
    8000039c:	0a072783          	lw	a5,160(a4)
    800003a0:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003a4:	00011497          	auipc	s1,0x11
    800003a8:	48c48493          	addi	s1,s1,1164 # 80011830 <cons>
    while(cons.e != cons.w &&
    800003ac:	4929                	li	s2,10
    800003ae:	f4f70be3          	beq	a4,a5,80000304 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003b2:	37fd                	addiw	a5,a5,-1
    800003b4:	07f7f713          	andi	a4,a5,127
    800003b8:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003ba:	01874703          	lbu	a4,24(a4)
    800003be:	f52703e3          	beq	a4,s2,80000304 <consoleintr+0x3c>
      cons.e--;
    800003c2:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c6:	10000513          	li	a0,256
    800003ca:	00000097          	auipc	ra,0x0
    800003ce:	ebc080e7          	jalr	-324(ra) # 80000286 <consputc>
    while(cons.e != cons.w &&
    800003d2:	0a04a783          	lw	a5,160(s1)
    800003d6:	09c4a703          	lw	a4,156(s1)
    800003da:	fcf71ce3          	bne	a4,a5,800003b2 <consoleintr+0xea>
    800003de:	b71d                	j	80000304 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e0:	00011717          	auipc	a4,0x11
    800003e4:	45070713          	addi	a4,a4,1104 # 80011830 <cons>
    800003e8:	0a072783          	lw	a5,160(a4)
    800003ec:	09c72703          	lw	a4,156(a4)
    800003f0:	f0f70ae3          	beq	a4,a5,80000304 <consoleintr+0x3c>
      cons.e--;
    800003f4:	37fd                	addiw	a5,a5,-1
    800003f6:	00011717          	auipc	a4,0x11
    800003fa:	4cf72d23          	sw	a5,1242(a4) # 800118d0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fe:	10000513          	li	a0,256
    80000402:	00000097          	auipc	ra,0x0
    80000406:	e84080e7          	jalr	-380(ra) # 80000286 <consputc>
    8000040a:	bded                	j	80000304 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000040c:	ee048ce3          	beqz	s1,80000304 <consoleintr+0x3c>
    80000410:	bf21                	j	80000328 <consoleintr+0x60>
      consputc(c);
    80000412:	4529                	li	a0,10
    80000414:	00000097          	auipc	ra,0x0
    80000418:	e72080e7          	jalr	-398(ra) # 80000286 <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000041c:	00011797          	auipc	a5,0x11
    80000420:	41478793          	addi	a5,a5,1044 # 80011830 <cons>
    80000424:	0a07a703          	lw	a4,160(a5)
    80000428:	0017069b          	addiw	a3,a4,1
    8000042c:	0006861b          	sext.w	a2,a3
    80000430:	0ad7a023          	sw	a3,160(a5)
    80000434:	07f77713          	andi	a4,a4,127
    80000438:	97ba                	add	a5,a5,a4
    8000043a:	4729                	li	a4,10
    8000043c:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000440:	00011797          	auipc	a5,0x11
    80000444:	48c7a623          	sw	a2,1164(a5) # 800118cc <cons+0x9c>
        wakeup(&cons.r);
    80000448:	00011517          	auipc	a0,0x11
    8000044c:	48050513          	addi	a0,a0,1152 # 800118c8 <cons+0x98>
    80000450:	00002097          	auipc	ra,0x2
    80000454:	0d2080e7          	jalr	210(ra) # 80002522 <wakeup>
    80000458:	b575                	j	80000304 <consoleintr+0x3c>

000000008000045a <consoleinit>:

void
consoleinit(void)
{
    8000045a:	1141                	addi	sp,sp,-16
    8000045c:	e406                	sd	ra,8(sp)
    8000045e:	e022                	sd	s0,0(sp)
    80000460:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000462:	00008597          	auipc	a1,0x8
    80000466:	bae58593          	addi	a1,a1,-1106 # 80008010 <etext+0x10>
    8000046a:	00011517          	auipc	a0,0x11
    8000046e:	3c650513          	addi	a0,a0,966 # 80011830 <cons>
    80000472:	00000097          	auipc	ra,0x0
    80000476:	7d4080e7          	jalr	2004(ra) # 80000c46 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	53678793          	addi	a5,a5,1334 # 800219b8 <devsw>
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	ce470713          	addi	a4,a4,-796 # 8000016e <consoleread>
    80000492:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000494:	00000717          	auipc	a4,0x0
    80000498:	c5870713          	addi	a4,a4,-936 # 800000ec <consolewrite>
    8000049c:	ef98                	sd	a4,24(a5)
}
    8000049e:	60a2                	ld	ra,8(sp)
    800004a0:	6402                	ld	s0,0(sp)
    800004a2:	0141                	addi	sp,sp,16
    800004a4:	8082                	ret

00000000800004a6 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a6:	7179                	addi	sp,sp,-48
    800004a8:	f406                	sd	ra,40(sp)
    800004aa:	f022                	sd	s0,32(sp)
    800004ac:	ec26                	sd	s1,24(sp)
    800004ae:	e84a                	sd	s2,16(sp)
    800004b0:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004b2:	c219                	beqz	a2,800004b8 <printint+0x12>
    800004b4:	08054663          	bltz	a0,80000540 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b8:	2501                	sext.w	a0,a0
    800004ba:	4881                	li	a7,0
    800004bc:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c0:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004c2:	2581                	sext.w	a1,a1
    800004c4:	00008617          	auipc	a2,0x8
    800004c8:	b7c60613          	addi	a2,a2,-1156 # 80008040 <digits>
    800004cc:	883a                	mv	a6,a4
    800004ce:	2705                	addiw	a4,a4,1
    800004d0:	02b577bb          	remuw	a5,a0,a1
    800004d4:	1782                	slli	a5,a5,0x20
    800004d6:	9381                	srli	a5,a5,0x20
    800004d8:	97b2                	add	a5,a5,a2
    800004da:	0007c783          	lbu	a5,0(a5)
    800004de:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004e2:	0005079b          	sext.w	a5,a0
    800004e6:	02b5553b          	divuw	a0,a0,a1
    800004ea:	0685                	addi	a3,a3,1
    800004ec:	feb7f0e3          	bgeu	a5,a1,800004cc <printint+0x26>

  if(sign)
    800004f0:	00088b63          	beqz	a7,80000506 <printint+0x60>
    buf[i++] = '-';
    800004f4:	fe040793          	addi	a5,s0,-32
    800004f8:	973e                	add	a4,a4,a5
    800004fa:	02d00793          	li	a5,45
    800004fe:	fef70823          	sb	a5,-16(a4)
    80000502:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000506:	02e05763          	blez	a4,80000534 <printint+0x8e>
    8000050a:	fd040793          	addi	a5,s0,-48
    8000050e:	00e784b3          	add	s1,a5,a4
    80000512:	fff78913          	addi	s2,a5,-1
    80000516:	993a                	add	s2,s2,a4
    80000518:	377d                	addiw	a4,a4,-1
    8000051a:	1702                	slli	a4,a4,0x20
    8000051c:	9301                	srli	a4,a4,0x20
    8000051e:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000522:	fff4c503          	lbu	a0,-1(s1)
    80000526:	00000097          	auipc	ra,0x0
    8000052a:	d60080e7          	jalr	-672(ra) # 80000286 <consputc>
  while(--i >= 0)
    8000052e:	14fd                	addi	s1,s1,-1
    80000530:	ff2499e3          	bne	s1,s2,80000522 <printint+0x7c>
}
    80000534:	70a2                	ld	ra,40(sp)
    80000536:	7402                	ld	s0,32(sp)
    80000538:	64e2                	ld	s1,24(sp)
    8000053a:	6942                	ld	s2,16(sp)
    8000053c:	6145                	addi	sp,sp,48
    8000053e:	8082                	ret
    x = -xx;
    80000540:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000544:	4885                	li	a7,1
    x = -xx;
    80000546:	bf9d                	j	800004bc <printint+0x16>

0000000080000548 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000548:	1101                	addi	sp,sp,-32
    8000054a:	ec06                	sd	ra,24(sp)
    8000054c:	e822                	sd	s0,16(sp)
    8000054e:	e426                	sd	s1,8(sp)
    80000550:	1000                	addi	s0,sp,32
    80000552:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000554:	00011797          	auipc	a5,0x11
    80000558:	3807ae23          	sw	zero,924(a5) # 800118f0 <pr+0x18>
  printf("panic: ");
    8000055c:	00008517          	auipc	a0,0x8
    80000560:	abc50513          	addi	a0,a0,-1348 # 80008018 <etext+0x18>
    80000564:	00000097          	auipc	ra,0x0
    80000568:	02e080e7          	jalr	46(ra) # 80000592 <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	024080e7          	jalr	36(ra) # 80000592 <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b5250513          	addi	a0,a0,-1198 # 800080c8 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	014080e7          	jalr	20(ra) # 80000592 <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  for(;;)
    80000590:	a001                	j	80000590 <panic+0x48>

0000000080000592 <printf>:
{
    80000592:	7131                	addi	sp,sp,-192
    80000594:	fc86                	sd	ra,120(sp)
    80000596:	f8a2                	sd	s0,112(sp)
    80000598:	f4a6                	sd	s1,104(sp)
    8000059a:	f0ca                	sd	s2,96(sp)
    8000059c:	ecce                	sd	s3,88(sp)
    8000059e:	e8d2                	sd	s4,80(sp)
    800005a0:	e4d6                	sd	s5,72(sp)
    800005a2:	e0da                	sd	s6,64(sp)
    800005a4:	fc5e                	sd	s7,56(sp)
    800005a6:	f862                	sd	s8,48(sp)
    800005a8:	f466                	sd	s9,40(sp)
    800005aa:	f06a                	sd	s10,32(sp)
    800005ac:	ec6e                	sd	s11,24(sp)
    800005ae:	0100                	addi	s0,sp,128
    800005b0:	8a2a                	mv	s4,a0
    800005b2:	e40c                	sd	a1,8(s0)
    800005b4:	e810                	sd	a2,16(s0)
    800005b6:	ec14                	sd	a3,24(s0)
    800005b8:	f018                	sd	a4,32(s0)
    800005ba:	f41c                	sd	a5,40(s0)
    800005bc:	03043823          	sd	a6,48(s0)
    800005c0:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c4:	00011d97          	auipc	s11,0x11
    800005c8:	32cdad83          	lw	s11,812(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005cc:	020d9b63          	bnez	s11,80000602 <printf+0x70>
  if (fmt == 0)
    800005d0:	040a0263          	beqz	s4,80000614 <printf+0x82>
  va_start(ap, fmt);
    800005d4:	00840793          	addi	a5,s0,8
    800005d8:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005dc:	000a4503          	lbu	a0,0(s4)
    800005e0:	16050263          	beqz	a0,80000744 <printf+0x1b2>
    800005e4:	4481                	li	s1,0
    if(c != '%'){
    800005e6:	02500a93          	li	s5,37
    switch(c){
    800005ea:	07000b13          	li	s6,112
  consputc('x');
    800005ee:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f0:	00008b97          	auipc	s7,0x8
    800005f4:	a50b8b93          	addi	s7,s7,-1456 # 80008040 <digits>
    switch(c){
    800005f8:	07300c93          	li	s9,115
    800005fc:	06400c13          	li	s8,100
    80000600:	a82d                	j	8000063a <printf+0xa8>
    acquire(&pr.lock);
    80000602:	00011517          	auipc	a0,0x11
    80000606:	2d650513          	addi	a0,a0,726 # 800118d8 <pr>
    8000060a:	00000097          	auipc	ra,0x0
    8000060e:	6cc080e7          	jalr	1740(ra) # 80000cd6 <acquire>
    80000612:	bf7d                	j	800005d0 <printf+0x3e>
    panic("null fmt");
    80000614:	00008517          	auipc	a0,0x8
    80000618:	a1450513          	addi	a0,a0,-1516 # 80008028 <etext+0x28>
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	f2c080e7          	jalr	-212(ra) # 80000548 <panic>
      consputc(c);
    80000624:	00000097          	auipc	ra,0x0
    80000628:	c62080e7          	jalr	-926(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    8000062c:	2485                	addiw	s1,s1,1
    8000062e:	009a07b3          	add	a5,s4,s1
    80000632:	0007c503          	lbu	a0,0(a5)
    80000636:	10050763          	beqz	a0,80000744 <printf+0x1b2>
    if(c != '%'){
    8000063a:	ff5515e3          	bne	a0,s5,80000624 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063e:	2485                	addiw	s1,s1,1
    80000640:	009a07b3          	add	a5,s4,s1
    80000644:	0007c783          	lbu	a5,0(a5)
    80000648:	0007891b          	sext.w	s2,a5
    if(c == 0)
    8000064c:	cfe5                	beqz	a5,80000744 <printf+0x1b2>
    switch(c){
    8000064e:	05678a63          	beq	a5,s6,800006a2 <printf+0x110>
    80000652:	02fb7663          	bgeu	s6,a5,8000067e <printf+0xec>
    80000656:	09978963          	beq	a5,s9,800006e8 <printf+0x156>
    8000065a:	07800713          	li	a4,120
    8000065e:	0ce79863          	bne	a5,a4,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000662:	f8843783          	ld	a5,-120(s0)
    80000666:	00878713          	addi	a4,a5,8
    8000066a:	f8e43423          	sd	a4,-120(s0)
    8000066e:	4605                	li	a2,1
    80000670:	85ea                	mv	a1,s10
    80000672:	4388                	lw	a0,0(a5)
    80000674:	00000097          	auipc	ra,0x0
    80000678:	e32080e7          	jalr	-462(ra) # 800004a6 <printint>
      break;
    8000067c:	bf45                	j	8000062c <printf+0x9a>
    switch(c){
    8000067e:	0b578263          	beq	a5,s5,80000722 <printf+0x190>
    80000682:	0b879663          	bne	a5,s8,8000072e <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000686:	f8843783          	ld	a5,-120(s0)
    8000068a:	00878713          	addi	a4,a5,8
    8000068e:	f8e43423          	sd	a4,-120(s0)
    80000692:	4605                	li	a2,1
    80000694:	45a9                	li	a1,10
    80000696:	4388                	lw	a0,0(a5)
    80000698:	00000097          	auipc	ra,0x0
    8000069c:	e0e080e7          	jalr	-498(ra) # 800004a6 <printint>
      break;
    800006a0:	b771                	j	8000062c <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006a2:	f8843783          	ld	a5,-120(s0)
    800006a6:	00878713          	addi	a4,a5,8
    800006aa:	f8e43423          	sd	a4,-120(s0)
    800006ae:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006b2:	03000513          	li	a0,48
    800006b6:	00000097          	auipc	ra,0x0
    800006ba:	bd0080e7          	jalr	-1072(ra) # 80000286 <consputc>
  consputc('x');
    800006be:	07800513          	li	a0,120
    800006c2:	00000097          	auipc	ra,0x0
    800006c6:	bc4080e7          	jalr	-1084(ra) # 80000286 <consputc>
    800006ca:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006cc:	03c9d793          	srli	a5,s3,0x3c
    800006d0:	97de                	add	a5,a5,s7
    800006d2:	0007c503          	lbu	a0,0(a5)
    800006d6:	00000097          	auipc	ra,0x0
    800006da:	bb0080e7          	jalr	-1104(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006de:	0992                	slli	s3,s3,0x4
    800006e0:	397d                	addiw	s2,s2,-1
    800006e2:	fe0915e3          	bnez	s2,800006cc <printf+0x13a>
    800006e6:	b799                	j	8000062c <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e8:	f8843783          	ld	a5,-120(s0)
    800006ec:	00878713          	addi	a4,a5,8
    800006f0:	f8e43423          	sd	a4,-120(s0)
    800006f4:	0007b903          	ld	s2,0(a5)
    800006f8:	00090e63          	beqz	s2,80000714 <printf+0x182>
      for(; *s; s++)
    800006fc:	00094503          	lbu	a0,0(s2)
    80000700:	d515                	beqz	a0,8000062c <printf+0x9a>
        consputc(*s);
    80000702:	00000097          	auipc	ra,0x0
    80000706:	b84080e7          	jalr	-1148(ra) # 80000286 <consputc>
      for(; *s; s++)
    8000070a:	0905                	addi	s2,s2,1
    8000070c:	00094503          	lbu	a0,0(s2)
    80000710:	f96d                	bnez	a0,80000702 <printf+0x170>
    80000712:	bf29                	j	8000062c <printf+0x9a>
        s = "(null)";
    80000714:	00008917          	auipc	s2,0x8
    80000718:	90c90913          	addi	s2,s2,-1780 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000071c:	02800513          	li	a0,40
    80000720:	b7cd                	j	80000702 <printf+0x170>
      consputc('%');
    80000722:	8556                	mv	a0,s5
    80000724:	00000097          	auipc	ra,0x0
    80000728:	b62080e7          	jalr	-1182(ra) # 80000286 <consputc>
      break;
    8000072c:	b701                	j	8000062c <printf+0x9a>
      consputc('%');
    8000072e:	8556                	mv	a0,s5
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b56080e7          	jalr	-1194(ra) # 80000286 <consputc>
      consputc(c);
    80000738:	854a                	mv	a0,s2
    8000073a:	00000097          	auipc	ra,0x0
    8000073e:	b4c080e7          	jalr	-1204(ra) # 80000286 <consputc>
      break;
    80000742:	b5ed                	j	8000062c <printf+0x9a>
  if(locking)
    80000744:	020d9163          	bnez	s11,80000766 <printf+0x1d4>
}
    80000748:	70e6                	ld	ra,120(sp)
    8000074a:	7446                	ld	s0,112(sp)
    8000074c:	74a6                	ld	s1,104(sp)
    8000074e:	7906                	ld	s2,96(sp)
    80000750:	69e6                	ld	s3,88(sp)
    80000752:	6a46                	ld	s4,80(sp)
    80000754:	6aa6                	ld	s5,72(sp)
    80000756:	6b06                	ld	s6,64(sp)
    80000758:	7be2                	ld	s7,56(sp)
    8000075a:	7c42                	ld	s8,48(sp)
    8000075c:	7ca2                	ld	s9,40(sp)
    8000075e:	7d02                	ld	s10,32(sp)
    80000760:	6de2                	ld	s11,24(sp)
    80000762:	6129                	addi	sp,sp,192
    80000764:	8082                	ret
    release(&pr.lock);
    80000766:	00011517          	auipc	a0,0x11
    8000076a:	17250513          	addi	a0,a0,370 # 800118d8 <pr>
    8000076e:	00000097          	auipc	ra,0x0
    80000772:	61c080e7          	jalr	1564(ra) # 80000d8a <release>
}
    80000776:	bfc9                	j	80000748 <printf+0x1b6>

0000000080000778 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000778:	1101                	addi	sp,sp,-32
    8000077a:	ec06                	sd	ra,24(sp)
    8000077c:	e822                	sd	s0,16(sp)
    8000077e:	e426                	sd	s1,8(sp)
    80000780:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000782:	00011497          	auipc	s1,0x11
    80000786:	15648493          	addi	s1,s1,342 # 800118d8 <pr>
    8000078a:	00008597          	auipc	a1,0x8
    8000078e:	8ae58593          	addi	a1,a1,-1874 # 80008038 <etext+0x38>
    80000792:	8526                	mv	a0,s1
    80000794:	00000097          	auipc	ra,0x0
    80000798:	4b2080e7          	jalr	1202(ra) # 80000c46 <initlock>
  pr.locking = 1;
    8000079c:	4785                	li	a5,1
    8000079e:	cc9c                	sw	a5,24(s1)
}
    800007a0:	60e2                	ld	ra,24(sp)
    800007a2:	6442                	ld	s0,16(sp)
    800007a4:	64a2                	ld	s1,8(sp)
    800007a6:	6105                	addi	sp,sp,32
    800007a8:	8082                	ret

00000000800007aa <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007aa:	1141                	addi	sp,sp,-16
    800007ac:	e406                	sd	ra,8(sp)
    800007ae:	e022                	sd	s0,0(sp)
    800007b0:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007b2:	100007b7          	lui	a5,0x10000
    800007b6:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ba:	f8000713          	li	a4,-128
    800007be:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007c2:	470d                	li	a4,3
    800007c4:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c8:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007cc:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d0:	469d                	li	a3,7
    800007d2:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d6:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007da:	00008597          	auipc	a1,0x8
    800007de:	87e58593          	addi	a1,a1,-1922 # 80008058 <digits+0x18>
    800007e2:	00011517          	auipc	a0,0x11
    800007e6:	11650513          	addi	a0,a0,278 # 800118f8 <uart_tx_lock>
    800007ea:	00000097          	auipc	ra,0x0
    800007ee:	45c080e7          	jalr	1116(ra) # 80000c46 <initlock>
}
    800007f2:	60a2                	ld	ra,8(sp)
    800007f4:	6402                	ld	s0,0(sp)
    800007f6:	0141                	addi	sp,sp,16
    800007f8:	8082                	ret

00000000800007fa <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007fa:	1101                	addi	sp,sp,-32
    800007fc:	ec06                	sd	ra,24(sp)
    800007fe:	e822                	sd	s0,16(sp)
    80000800:	e426                	sd	s1,8(sp)
    80000802:	1000                	addi	s0,sp,32
    80000804:	84aa                	mv	s1,a0
  push_off();
    80000806:	00000097          	auipc	ra,0x0
    8000080a:	484080e7          	jalr	1156(ra) # 80000c8a <push_off>

  if(panicked){
    8000080e:	00008797          	auipc	a5,0x8
    80000812:	7f27a783          	lw	a5,2034(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000816:	10000737          	lui	a4,0x10000
  if(panicked){
    8000081a:	c391                	beqz	a5,8000081e <uartputc_sync+0x24>
    for(;;)
    8000081c:	a001                	j	8000081c <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000822:	0ff7f793          	andi	a5,a5,255
    80000826:	0207f793          	andi	a5,a5,32
    8000082a:	dbf5                	beqz	a5,8000081e <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000082c:	0ff4f793          	andi	a5,s1,255
    80000830:	10000737          	lui	a4,0x10000
    80000834:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000838:	00000097          	auipc	ra,0x0
    8000083c:	4f2080e7          	jalr	1266(ra) # 80000d2a <pop_off>
}
    80000840:	60e2                	ld	ra,24(sp)
    80000842:	6442                	ld	s0,16(sp)
    80000844:	64a2                	ld	s1,8(sp)
    80000846:	6105                	addi	sp,sp,32
    80000848:	8082                	ret

000000008000084a <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    8000084a:	00008797          	auipc	a5,0x8
    8000084e:	7ba7a783          	lw	a5,1978(a5) # 80009004 <uart_tx_r>
    80000852:	00008717          	auipc	a4,0x8
    80000856:	7b672703          	lw	a4,1974(a4) # 80009008 <uart_tx_w>
    8000085a:	08f70263          	beq	a4,a5,800008de <uartstart+0x94>
{
    8000085e:	7139                	addi	sp,sp,-64
    80000860:	fc06                	sd	ra,56(sp)
    80000862:	f822                	sd	s0,48(sp)
    80000864:	f426                	sd	s1,40(sp)
    80000866:	f04a                	sd	s2,32(sp)
    80000868:	ec4e                	sd	s3,24(sp)
    8000086a:	e852                	sd	s4,16(sp)
    8000086c:	e456                	sd	s5,8(sp)
    8000086e:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000870:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    80000874:	00011a17          	auipc	s4,0x11
    80000878:	084a0a13          	addi	s4,s4,132 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    8000087c:	00008497          	auipc	s1,0x8
    80000880:	78848493          	addi	s1,s1,1928 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000884:	00008997          	auipc	s3,0x8
    80000888:	78498993          	addi	s3,s3,1924 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000088c:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000890:	0ff77713          	andi	a4,a4,255
    80000894:	02077713          	andi	a4,a4,32
    80000898:	cb15                	beqz	a4,800008cc <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000089a:	00fa0733          	add	a4,s4,a5
    8000089e:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008a2:	2785                	addiw	a5,a5,1
    800008a4:	41f7d71b          	sraiw	a4,a5,0x1f
    800008a8:	01b7571b          	srliw	a4,a4,0x1b
    800008ac:	9fb9                	addw	a5,a5,a4
    800008ae:	8bfd                	andi	a5,a5,31
    800008b0:	9f99                	subw	a5,a5,a4
    800008b2:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008b4:	8526                	mv	a0,s1
    800008b6:	00002097          	auipc	ra,0x2
    800008ba:	c6c080e7          	jalr	-916(ra) # 80002522 <wakeup>
    
    WriteReg(THR, c);
    800008be:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008c2:	409c                	lw	a5,0(s1)
    800008c4:	0009a703          	lw	a4,0(s3)
    800008c8:	fcf712e3          	bne	a4,a5,8000088c <uartstart+0x42>
  }
}
    800008cc:	70e2                	ld	ra,56(sp)
    800008ce:	7442                	ld	s0,48(sp)
    800008d0:	74a2                	ld	s1,40(sp)
    800008d2:	7902                	ld	s2,32(sp)
    800008d4:	69e2                	ld	s3,24(sp)
    800008d6:	6a42                	ld	s4,16(sp)
    800008d8:	6aa2                	ld	s5,8(sp)
    800008da:	6121                	addi	sp,sp,64
    800008dc:	8082                	ret
    800008de:	8082                	ret

00000000800008e0 <uartputc>:
{
    800008e0:	7179                	addi	sp,sp,-48
    800008e2:	f406                	sd	ra,40(sp)
    800008e4:	f022                	sd	s0,32(sp)
    800008e6:	ec26                	sd	s1,24(sp)
    800008e8:	e84a                	sd	s2,16(sp)
    800008ea:	e44e                	sd	s3,8(sp)
    800008ec:	e052                	sd	s4,0(sp)
    800008ee:	1800                	addi	s0,sp,48
    800008f0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008f2:	00011517          	auipc	a0,0x11
    800008f6:	00650513          	addi	a0,a0,6 # 800118f8 <uart_tx_lock>
    800008fa:	00000097          	auipc	ra,0x0
    800008fe:	3dc080e7          	jalr	988(ra) # 80000cd6 <acquire>
  if(panicked){
    80000902:	00008797          	auipc	a5,0x8
    80000906:	6fe7a783          	lw	a5,1790(a5) # 80009000 <panicked>
    8000090a:	c391                	beqz	a5,8000090e <uartputc+0x2e>
    for(;;)
    8000090c:	a001                	j	8000090c <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000090e:	00008717          	auipc	a4,0x8
    80000912:	6fa72703          	lw	a4,1786(a4) # 80009008 <uart_tx_w>
    80000916:	0017079b          	addiw	a5,a4,1
    8000091a:	41f7d69b          	sraiw	a3,a5,0x1f
    8000091e:	01b6d69b          	srliw	a3,a3,0x1b
    80000922:	9fb5                	addw	a5,a5,a3
    80000924:	8bfd                	andi	a5,a5,31
    80000926:	9f95                	subw	a5,a5,a3
    80000928:	00008697          	auipc	a3,0x8
    8000092c:	6dc6a683          	lw	a3,1756(a3) # 80009004 <uart_tx_r>
    80000930:	04f69263          	bne	a3,a5,80000974 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000934:	00011a17          	auipc	s4,0x11
    80000938:	fc4a0a13          	addi	s4,s4,-60 # 800118f8 <uart_tx_lock>
    8000093c:	00008497          	auipc	s1,0x8
    80000940:	6c848493          	addi	s1,s1,1736 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000944:	00008917          	auipc	s2,0x8
    80000948:	6c490913          	addi	s2,s2,1732 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000094c:	85d2                	mv	a1,s4
    8000094e:	8526                	mv	a0,s1
    80000950:	00002097          	auipc	ra,0x2
    80000954:	a4c080e7          	jalr	-1460(ra) # 8000239c <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000958:	00092703          	lw	a4,0(s2)
    8000095c:	0017079b          	addiw	a5,a4,1
    80000960:	41f7d69b          	sraiw	a3,a5,0x1f
    80000964:	01b6d69b          	srliw	a3,a3,0x1b
    80000968:	9fb5                	addw	a5,a5,a3
    8000096a:	8bfd                	andi	a5,a5,31
    8000096c:	9f95                	subw	a5,a5,a3
    8000096e:	4094                	lw	a3,0(s1)
    80000970:	fcf68ee3          	beq	a3,a5,8000094c <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    80000974:	00011497          	auipc	s1,0x11
    80000978:	f8448493          	addi	s1,s1,-124 # 800118f8 <uart_tx_lock>
    8000097c:	9726                	add	a4,a4,s1
    8000097e:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68f72323          	sw	a5,1670(a4) # 80009008 <uart_tx_w>
      uartstart();
    8000098a:	00000097          	auipc	ra,0x0
    8000098e:	ec0080e7          	jalr	-320(ra) # 8000084a <uartstart>
      release(&uart_tx_lock);
    80000992:	8526                	mv	a0,s1
    80000994:	00000097          	auipc	ra,0x0
    80000998:	3f6080e7          	jalr	1014(ra) # 80000d8a <release>
}
    8000099c:	70a2                	ld	ra,40(sp)
    8000099e:	7402                	ld	s0,32(sp)
    800009a0:	64e2                	ld	s1,24(sp)
    800009a2:	6942                	ld	s2,16(sp)
    800009a4:	69a2                	ld	s3,8(sp)
    800009a6:	6a02                	ld	s4,0(sp)
    800009a8:	6145                	addi	sp,sp,48
    800009aa:	8082                	ret

00000000800009ac <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009ac:	1141                	addi	sp,sp,-16
    800009ae:	e422                	sd	s0,8(sp)
    800009b0:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009b2:	100007b7          	lui	a5,0x10000
    800009b6:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009ba:	8b85                	andi	a5,a5,1
    800009bc:	cb91                	beqz	a5,800009d0 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009be:	100007b7          	lui	a5,0x10000
    800009c2:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009c6:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009ca:	6422                	ld	s0,8(sp)
    800009cc:	0141                	addi	sp,sp,16
    800009ce:	8082                	ret
    return -1;
    800009d0:	557d                	li	a0,-1
    800009d2:	bfe5                	j	800009ca <uartgetc+0x1e>

00000000800009d4 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009d4:	1101                	addi	sp,sp,-32
    800009d6:	ec06                	sd	ra,24(sp)
    800009d8:	e822                	sd	s0,16(sp)
    800009da:	e426                	sd	s1,8(sp)
    800009dc:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009de:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e0:	00000097          	auipc	ra,0x0
    800009e4:	fcc080e7          	jalr	-52(ra) # 800009ac <uartgetc>
    if(c == -1)
    800009e8:	00950763          	beq	a0,s1,800009f6 <uartintr+0x22>
      break;
    consoleintr(c);
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	8dc080e7          	jalr	-1828(ra) # 800002c8 <consoleintr>
  while(1){
    800009f4:	b7f5                	j	800009e0 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009f6:	00011497          	auipc	s1,0x11
    800009fa:	f0248493          	addi	s1,s1,-254 # 800118f8 <uart_tx_lock>
    800009fe:	8526                	mv	a0,s1
    80000a00:	00000097          	auipc	ra,0x0
    80000a04:	2d6080e7          	jalr	726(ra) # 80000cd6 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	378080e7          	jalr	888(ra) # 80000d8a <release>
}
    80000a1a:	60e2                	ld	ra,24(sp)
    80000a1c:	6442                	ld	s0,16(sp)
    80000a1e:	64a2                	ld	s1,8(sp)
    80000a20:	6105                	addi	sp,sp,32
    80000a22:	8082                	ret

0000000080000a24 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a24:	1101                	addi	sp,sp,-32
    80000a26:	ec06                	sd	ra,24(sp)
    80000a28:	e822                	sd	s0,16(sp)
    80000a2a:	e426                	sd	s1,8(sp)
    80000a2c:	e04a                	sd	s2,0(sp)
    80000a2e:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a30:	03451793          	slli	a5,a0,0x34
    80000a34:	e7b5                	bnez	a5,80000aa0 <kfree+0x7c>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	06f56063          	bltu	a0,a5,80000aa0 <kfree+0x7c>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57c63          	bgeu	a0,a5,80000aa0 <kfree+0x7c>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  int page_idx = ((uint64)pa - KERNBASE) / PGSIZE;
  acquire(&kmem.lock);
    80000a4c:	00011917          	auipc	s2,0x11
    80000a50:	ee490913          	addi	s2,s2,-284 # 80011930 <kmem>
    80000a54:	854a                	mv	a0,s2
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	280080e7          	jalr	640(ra) # 80000cd6 <acquire>
  int page_idx = ((uint64)pa - KERNBASE) / PGSIZE;
    80000a5e:	800007b7          	lui	a5,0x80000
    80000a62:	97a6                	add	a5,a5,s1
    80000a64:	83b1                	srli	a5,a5,0xc
  kmem.ref_cnt[page_idx]--;
    80000a66:	2781                	sext.w	a5,a5
    80000a68:	02093703          	ld	a4,32(s2)
    80000a6c:	973e                	add	a4,a4,a5
    80000a6e:	00074683          	lbu	a3,0(a4)
    80000a72:	36fd                	addiw	a3,a3,-1
    80000a74:	00d70023          	sb	a3,0(a4)
  if (kmem.ref_cnt[page_idx] == 0)
    80000a78:	02093703          	ld	a4,32(s2)
    80000a7c:	97ba                	add	a5,a5,a4
    80000a7e:	0007c783          	lbu	a5,0(a5) # ffffffff80000000 <end+0xfffffffefffda000>
    80000a82:	c79d                	beqz	a5,80000ab0 <kfree+0x8c>
    memset(pa, 1, PGSIZE);
    r = (struct run*)pa;
    r->next = kmem.freelist;
    kmem.freelist = r;
  }
  release(&kmem.lock);
    80000a84:	00011517          	auipc	a0,0x11
    80000a88:	eac50513          	addi	a0,a0,-340 # 80011930 <kmem>
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	2fe080e7          	jalr	766(ra) # 80000d8a <release>
}
    80000a94:	60e2                	ld	ra,24(sp)
    80000a96:	6442                	ld	s0,16(sp)
    80000a98:	64a2                	ld	s1,8(sp)
    80000a9a:	6902                	ld	s2,0(sp)
    80000a9c:	6105                	addi	sp,sp,32
    80000a9e:	8082                	ret
    panic("kfree");
    80000aa0:	00007517          	auipc	a0,0x7
    80000aa4:	5c050513          	addi	a0,a0,1472 # 80008060 <digits+0x20>
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	aa0080e7          	jalr	-1376(ra) # 80000548 <panic>
    memset(pa, 1, PGSIZE);
    80000ab0:	6605                	lui	a2,0x1
    80000ab2:	4585                	li	a1,1
    80000ab4:	8526                	mv	a0,s1
    80000ab6:	00000097          	auipc	ra,0x0
    80000aba:	31c080e7          	jalr	796(ra) # 80000dd2 <memset>
    r->next = kmem.freelist;
    80000abe:	01893703          	ld	a4,24(s2)
    80000ac2:	e098                	sd	a4,0(s1)
    kmem.freelist = r;
    80000ac4:	00993c23          	sd	s1,24(s2)
    80000ac8:	bf75                	j	80000a84 <kfree+0x60>

0000000080000aca <freerange>:
{
    80000aca:	7179                	addi	sp,sp,-48
    80000acc:	f406                	sd	ra,40(sp)
    80000ace:	f022                	sd	s0,32(sp)
    80000ad0:	ec26                	sd	s1,24(sp)
    80000ad2:	e84a                	sd	s2,16(sp)
    80000ad4:	e44e                	sd	s3,8(sp)
    80000ad6:	e052                	sd	s4,0(sp)
    80000ad8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ada:	6785                	lui	a5,0x1
    80000adc:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ae0:	94aa                	add	s1,s1,a0
    80000ae2:	757d                	lui	a0,0xfffff
    80000ae4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ae6:	94be                	add	s1,s1,a5
    80000ae8:	0095ee63          	bltu	a1,s1,80000b04 <freerange+0x3a>
    80000aec:	892e                	mv	s2,a1
    kfree(p);
    80000aee:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af0:	6985                	lui	s3,0x1
    kfree(p);
    80000af2:	01448533          	add	a0,s1,s4
    80000af6:	00000097          	auipc	ra,0x0
    80000afa:	f2e080e7          	jalr	-210(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000afe:	94ce                	add	s1,s1,s3
    80000b00:	fe9979e3          	bgeu	s2,s1,80000af2 <freerange+0x28>
}
    80000b04:	70a2                	ld	ra,40(sp)
    80000b06:	7402                	ld	s0,32(sp)
    80000b08:	64e2                	ld	s1,24(sp)
    80000b0a:	6942                	ld	s2,16(sp)
    80000b0c:	69a2                	ld	s3,8(sp)
    80000b0e:	6a02                	ld	s4,0(sp)
    80000b10:	6145                	addi	sp,sp,48
    80000b12:	8082                	ret

0000000080000b14 <kinit>:
{
    80000b14:	1101                	addi	sp,sp,-32
    80000b16:	ec06                	sd	ra,24(sp)
    80000b18:	e822                	sd	s0,16(sp)
    80000b1a:	e426                	sd	s1,8(sp)
    80000b1c:	e04a                	sd	s2,0(sp)
    80000b1e:	1000                	addi	s0,sp,32
  initlock(&kmem.lock, "kmem");
    80000b20:	00011917          	auipc	s2,0x11
    80000b24:	e1090913          	addi	s2,s2,-496 # 80011930 <kmem>
    80000b28:	00007597          	auipc	a1,0x7
    80000b2c:	54058593          	addi	a1,a1,1344 # 80008068 <digits+0x28>
    80000b30:	854a                	mv	a0,s2
    80000b32:	00000097          	auipc	ra,0x0
    80000b36:	114080e7          	jalr	276(ra) # 80000c46 <initlock>
  p = (uint8*)PGROUNDUP((uint64)end);
    80000b3a:	00026497          	auipc	s1,0x26
    80000b3e:	4c548493          	addi	s1,s1,1221 # 80026fff <end+0xfff>
    80000b42:	77fd                	lui	a5,0xfffff
    80000b44:	8cfd                	and	s1,s1,a5
  kmem.ref_cnt = p;
    80000b46:	02993023          	sd	s1,32(s2)
  kmem.freelist = 0;
    80000b4a:	00093c23          	sd	zero,24(s2)
  memset(p, 1, 8 * PGSIZE);
    80000b4e:	6621                	lui	a2,0x8
    80000b50:	4585                	li	a1,1
    80000b52:	8526                	mv	a0,s1
    80000b54:	00000097          	auipc	ra,0x0
    80000b58:	27e080e7          	jalr	638(ra) # 80000dd2 <memset>
  freerange(p, (void*)PHYSTOP);
    80000b5c:	45c5                	li	a1,17
    80000b5e:	05ee                	slli	a1,a1,0x1b
    80000b60:	6521                	lui	a0,0x8
    80000b62:	9526                	add	a0,a0,s1
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	f66080e7          	jalr	-154(ra) # 80000aca <freerange>
}
    80000b6c:	60e2                	ld	ra,24(sp)
    80000b6e:	6442                	ld	s0,16(sp)
    80000b70:	64a2                	ld	s1,8(sp)
    80000b72:	6902                	ld	s2,0(sp)
    80000b74:	6105                	addi	sp,sp,32
    80000b76:	8082                	ret

0000000080000b78 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b78:	1101                	addi	sp,sp,-32
    80000b7a:	ec06                	sd	ra,24(sp)
    80000b7c:	e822                	sd	s0,16(sp)
    80000b7e:	e426                	sd	s1,8(sp)
    80000b80:	e04a                	sd	s2,0(sp)
    80000b82:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b84:	00011497          	auipc	s1,0x11
    80000b88:	dac48493          	addi	s1,s1,-596 # 80011930 <kmem>
    80000b8c:	8526                	mv	a0,s1
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	148080e7          	jalr	328(ra) # 80000cd6 <acquire>
  r = kmem.freelist;
    80000b96:	6c84                	ld	s1,24(s1)
  if(r)
    80000b98:	c4b9                	beqz	s1,80000be6 <kalloc+0x6e>
  {
    kmem.freelist = r->next;
    80000b9a:	609c                	ld	a5,0(s1)
    80000b9c:	00011917          	auipc	s2,0x11
    80000ba0:	d9490913          	addi	s2,s2,-620 # 80011930 <kmem>
    80000ba4:	00f93c23          	sd	a5,24(s2)
  }
    
  release(&kmem.lock);
    80000ba8:	854a                	mv	a0,s2
    80000baa:	00000097          	auipc	ra,0x0
    80000bae:	1e0080e7          	jalr	480(ra) # 80000d8a <release>

  if(r)
  {
    memset((char*)r, 5, PGSIZE); // fill with junk   
    80000bb2:	6605                	lui	a2,0x1
    80000bb4:	4595                	li	a1,5
    80000bb6:	8526                	mv	a0,s1
    80000bb8:	00000097          	auipc	ra,0x0
    80000bbc:	21a080e7          	jalr	538(ra) # 80000dd2 <memset>
    kmem.ref_cnt[((uint64)r - KERNBASE) / PGSIZE]++;
    80000bc0:	800007b7          	lui	a5,0x80000
    80000bc4:	97a6                	add	a5,a5,s1
    80000bc6:	83b1                	srli	a5,a5,0xc
    80000bc8:	02093703          	ld	a4,32(s2)
    80000bcc:	97ba                	add	a5,a5,a4
    80000bce:	0007c703          	lbu	a4,0(a5) # ffffffff80000000 <end+0xfffffffefffda000>
    80000bd2:	2705                	addiw	a4,a4,1
    80000bd4:	00e78023          	sb	a4,0(a5)
  }
     
  return (void*)r;
}
    80000bd8:	8526                	mv	a0,s1
    80000bda:	60e2                	ld	ra,24(sp)
    80000bdc:	6442                	ld	s0,16(sp)
    80000bde:	64a2                	ld	s1,8(sp)
    80000be0:	6902                	ld	s2,0(sp)
    80000be2:	6105                	addi	sp,sp,32
    80000be4:	8082                	ret
  release(&kmem.lock);
    80000be6:	00011517          	auipc	a0,0x11
    80000bea:	d4a50513          	addi	a0,a0,-694 # 80011930 <kmem>
    80000bee:	00000097          	auipc	ra,0x0
    80000bf2:	19c080e7          	jalr	412(ra) # 80000d8a <release>
  if(r)
    80000bf6:	b7cd                	j	80000bd8 <kalloc+0x60>

0000000080000bf8 <cow_alloc>:

void
cow_alloc(uint64 pa)
{
    80000bf8:	1101                	addi	sp,sp,-32
    80000bfa:	ec06                	sd	ra,24(sp)
    80000bfc:	e822                	sd	s0,16(sp)
    80000bfe:	e426                	sd	s1,8(sp)
    80000c00:	e04a                	sd	s2,0(sp)
    80000c02:	1000                	addi	s0,sp,32
    80000c04:	84aa                	mv	s1,a0
  acquire(&kmem.lock);
    80000c06:	00011917          	auipc	s2,0x11
    80000c0a:	d2a90913          	addi	s2,s2,-726 # 80011930 <kmem>
    80000c0e:	854a                	mv	a0,s2
    80000c10:	00000097          	auipc	ra,0x0
    80000c14:	0c6080e7          	jalr	198(ra) # 80000cd6 <acquire>
  kmem.ref_cnt[(pa - KERNBASE) / PGSIZE]++;
    80000c18:	80000537          	lui	a0,0x80000
    80000c1c:	94aa                	add	s1,s1,a0
    80000c1e:	80b1                	srli	s1,s1,0xc
    80000c20:	02093783          	ld	a5,32(s2)
    80000c24:	94be                	add	s1,s1,a5
    80000c26:	0004c783          	lbu	a5,0(s1)
    80000c2a:	2785                	addiw	a5,a5,1
    80000c2c:	00f48023          	sb	a5,0(s1)
  release(&kmem.lock);
    80000c30:	854a                	mv	a0,s2
    80000c32:	00000097          	auipc	ra,0x0
    80000c36:	158080e7          	jalr	344(ra) # 80000d8a <release>
    80000c3a:	60e2                	ld	ra,24(sp)
    80000c3c:	6442                	ld	s0,16(sp)
    80000c3e:	64a2                	ld	s1,8(sp)
    80000c40:	6902                	ld	s2,0(sp)
    80000c42:	6105                	addi	sp,sp,32
    80000c44:	8082                	ret

0000000080000c46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c46:	1141                	addi	sp,sp,-16
    80000c48:	e422                	sd	s0,8(sp)
    80000c4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c4e:	00052023          	sw	zero,0(a0) # ffffffff80000000 <end+0xfffffffefffda000>
  lk->cpu = 0;
    80000c52:	00053823          	sd	zero,16(a0)
}
    80000c56:	6422                	ld	s0,8(sp)
    80000c58:	0141                	addi	sp,sp,16
    80000c5a:	8082                	ret

0000000080000c5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c5c:	411c                	lw	a5,0(a0)
    80000c5e:	e399                	bnez	a5,80000c64 <holding+0x8>
    80000c60:	4501                	li	a0,0
  return r;
}
    80000c62:	8082                	ret
{
    80000c64:	1101                	addi	sp,sp,-32
    80000c66:	ec06                	sd	ra,24(sp)
    80000c68:	e822                	sd	s0,16(sp)
    80000c6a:	e426                	sd	s1,8(sp)
    80000c6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c6e:	6904                	ld	s1,16(a0)
    80000c70:	00001097          	auipc	ra,0x1
    80000c74:	f00080e7          	jalr	-256(ra) # 80001b70 <mycpu>
    80000c78:	40a48533          	sub	a0,s1,a0
    80000c7c:	00153513          	seqz	a0,a0
}
    80000c80:	60e2                	ld	ra,24(sp)
    80000c82:	6442                	ld	s0,16(sp)
    80000c84:	64a2                	ld	s1,8(sp)
    80000c86:	6105                	addi	sp,sp,32
    80000c88:	8082                	ret

0000000080000c8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c94:	100024f3          	csrr	s1,sstatus
    80000c98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ca2:	00001097          	auipc	ra,0x1
    80000ca6:	ece080e7          	jalr	-306(ra) # 80001b70 <mycpu>
    80000caa:	5d3c                	lw	a5,120(a0)
    80000cac:	cf89                	beqz	a5,80000cc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cae:	00001097          	auipc	ra,0x1
    80000cb2:	ec2080e7          	jalr	-318(ra) # 80001b70 <mycpu>
    80000cb6:	5d3c                	lw	a5,120(a0)
    80000cb8:	2785                	addiw	a5,a5,1
    80000cba:	dd3c                	sw	a5,120(a0)
}
    80000cbc:	60e2                	ld	ra,24(sp)
    80000cbe:	6442                	ld	s0,16(sp)
    80000cc0:	64a2                	ld	s1,8(sp)
    80000cc2:	6105                	addi	sp,sp,32
    80000cc4:	8082                	ret
    mycpu()->intena = old;
    80000cc6:	00001097          	auipc	ra,0x1
    80000cca:	eaa080e7          	jalr	-342(ra) # 80001b70 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000cce:	8085                	srli	s1,s1,0x1
    80000cd0:	8885                	andi	s1,s1,1
    80000cd2:	dd64                	sw	s1,124(a0)
    80000cd4:	bfe9                	j	80000cae <push_off+0x24>

0000000080000cd6 <acquire>:
{
    80000cd6:	1101                	addi	sp,sp,-32
    80000cd8:	ec06                	sd	ra,24(sp)
    80000cda:	e822                	sd	s0,16(sp)
    80000cdc:	e426                	sd	s1,8(sp)
    80000cde:	1000                	addi	s0,sp,32
    80000ce0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000ce2:	00000097          	auipc	ra,0x0
    80000ce6:	fa8080e7          	jalr	-88(ra) # 80000c8a <push_off>
  if(holding(lk))
    80000cea:	8526                	mv	a0,s1
    80000cec:	00000097          	auipc	ra,0x0
    80000cf0:	f70080e7          	jalr	-144(ra) # 80000c5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cf4:	4705                	li	a4,1
  if(holding(lk))
    80000cf6:	e115                	bnez	a0,80000d1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000cf8:	87ba                	mv	a5,a4
    80000cfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cfe:	2781                	sext.w	a5,a5
    80000d00:	ffe5                	bnez	a5,80000cf8 <acquire+0x22>
  __sync_synchronize();
    80000d02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d06:	00001097          	auipc	ra,0x1
    80000d0a:	e6a080e7          	jalr	-406(ra) # 80001b70 <mycpu>
    80000d0e:	e888                	sd	a0,16(s1)
}
    80000d10:	60e2                	ld	ra,24(sp)
    80000d12:	6442                	ld	s0,16(sp)
    80000d14:	64a2                	ld	s1,8(sp)
    80000d16:	6105                	addi	sp,sp,32
    80000d18:	8082                	ret
    panic("acquire");
    80000d1a:	00007517          	auipc	a0,0x7
    80000d1e:	35650513          	addi	a0,a0,854 # 80008070 <digits+0x30>
    80000d22:	00000097          	auipc	ra,0x0
    80000d26:	826080e7          	jalr	-2010(ra) # 80000548 <panic>

0000000080000d2a <pop_off>:

void
pop_off(void)
{
    80000d2a:	1141                	addi	sp,sp,-16
    80000d2c:	e406                	sd	ra,8(sp)
    80000d2e:	e022                	sd	s0,0(sp)
    80000d30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d32:	00001097          	auipc	ra,0x1
    80000d36:	e3e080e7          	jalr	-450(ra) # 80001b70 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d40:	e78d                	bnez	a5,80000d6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d42:	5d3c                	lw	a5,120(a0)
    80000d44:	02f05b63          	blez	a5,80000d7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d48:	37fd                	addiw	a5,a5,-1
    80000d4a:	0007871b          	sext.w	a4,a5
    80000d4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d50:	eb09                	bnez	a4,80000d62 <pop_off+0x38>
    80000d52:	5d7c                	lw	a5,124(a0)
    80000d54:	c799                	beqz	a5,80000d62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d62:	60a2                	ld	ra,8(sp)
    80000d64:	6402                	ld	s0,0(sp)
    80000d66:	0141                	addi	sp,sp,16
    80000d68:	8082                	ret
    panic("pop_off - interruptible");
    80000d6a:	00007517          	auipc	a0,0x7
    80000d6e:	30e50513          	addi	a0,a0,782 # 80008078 <digits+0x38>
    80000d72:	fffff097          	auipc	ra,0xfffff
    80000d76:	7d6080e7          	jalr	2006(ra) # 80000548 <panic>
    panic("pop_off");
    80000d7a:	00007517          	auipc	a0,0x7
    80000d7e:	31650513          	addi	a0,a0,790 # 80008090 <digits+0x50>
    80000d82:	fffff097          	auipc	ra,0xfffff
    80000d86:	7c6080e7          	jalr	1990(ra) # 80000548 <panic>

0000000080000d8a <release>:
{
    80000d8a:	1101                	addi	sp,sp,-32
    80000d8c:	ec06                	sd	ra,24(sp)
    80000d8e:	e822                	sd	s0,16(sp)
    80000d90:	e426                	sd	s1,8(sp)
    80000d92:	1000                	addi	s0,sp,32
    80000d94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d96:	00000097          	auipc	ra,0x0
    80000d9a:	ec6080e7          	jalr	-314(ra) # 80000c5c <holding>
    80000d9e:	c115                	beqz	a0,80000dc2 <release+0x38>
  lk->cpu = 0;
    80000da0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000da4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000da8:	0f50000f          	fence	iorw,ow
    80000dac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000db0:	00000097          	auipc	ra,0x0
    80000db4:	f7a080e7          	jalr	-134(ra) # 80000d2a <pop_off>
}
    80000db8:	60e2                	ld	ra,24(sp)
    80000dba:	6442                	ld	s0,16(sp)
    80000dbc:	64a2                	ld	s1,8(sp)
    80000dbe:	6105                	addi	sp,sp,32
    80000dc0:	8082                	ret
    panic("release");
    80000dc2:	00007517          	auipc	a0,0x7
    80000dc6:	2d650513          	addi	a0,a0,726 # 80008098 <digits+0x58>
    80000dca:	fffff097          	auipc	ra,0xfffff
    80000dce:	77e080e7          	jalr	1918(ra) # 80000548 <panic>

0000000080000dd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000dd2:	1141                	addi	sp,sp,-16
    80000dd4:	e422                	sd	s0,8(sp)
    80000dd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000dd8:	ce09                	beqz	a2,80000df2 <memset+0x20>
    80000dda:	87aa                	mv	a5,a0
    80000ddc:	fff6071b          	addiw	a4,a2,-1
    80000de0:	1702                	slli	a4,a4,0x20
    80000de2:	9301                	srli	a4,a4,0x20
    80000de4:	0705                	addi	a4,a4,1
    80000de6:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000de8:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000dec:	0785                	addi	a5,a5,1
    80000dee:	fee79de3          	bne	a5,a4,80000de8 <memset+0x16>
  }
  return dst;
}
    80000df2:	6422                	ld	s0,8(sp)
    80000df4:	0141                	addi	sp,sp,16
    80000df6:	8082                	ret

0000000080000df8 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000df8:	1141                	addi	sp,sp,-16
    80000dfa:	e422                	sd	s0,8(sp)
    80000dfc:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dfe:	ca05                	beqz	a2,80000e2e <memcmp+0x36>
    80000e00:	fff6069b          	addiw	a3,a2,-1
    80000e04:	1682                	slli	a3,a3,0x20
    80000e06:	9281                	srli	a3,a3,0x20
    80000e08:	0685                	addi	a3,a3,1
    80000e0a:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e0c:	00054783          	lbu	a5,0(a0)
    80000e10:	0005c703          	lbu	a4,0(a1)
    80000e14:	00e79863          	bne	a5,a4,80000e24 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e18:	0505                	addi	a0,a0,1
    80000e1a:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e1c:	fed518e3          	bne	a0,a3,80000e0c <memcmp+0x14>
  }

  return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	a019                	j	80000e28 <memcmp+0x30>
      return *s1 - *s2;
    80000e24:	40e7853b          	subw	a0,a5,a4
}
    80000e28:	6422                	ld	s0,8(sp)
    80000e2a:	0141                	addi	sp,sp,16
    80000e2c:	8082                	ret
  return 0;
    80000e2e:	4501                	li	a0,0
    80000e30:	bfe5                	j	80000e28 <memcmp+0x30>

0000000080000e32 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e32:	1141                	addi	sp,sp,-16
    80000e34:	e422                	sd	s0,8(sp)
    80000e36:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e38:	00a5f963          	bgeu	a1,a0,80000e4a <memmove+0x18>
    80000e3c:	02061713          	slli	a4,a2,0x20
    80000e40:	9301                	srli	a4,a4,0x20
    80000e42:	00e587b3          	add	a5,a1,a4
    80000e46:	02f56563          	bltu	a0,a5,80000e70 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e4a:	fff6069b          	addiw	a3,a2,-1
    80000e4e:	ce11                	beqz	a2,80000e6a <memmove+0x38>
    80000e50:	1682                	slli	a3,a3,0x20
    80000e52:	9281                	srli	a3,a3,0x20
    80000e54:	0685                	addi	a3,a3,1
    80000e56:	96ae                	add	a3,a3,a1
    80000e58:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e5a:	0585                	addi	a1,a1,1
    80000e5c:	0785                	addi	a5,a5,1
    80000e5e:	fff5c703          	lbu	a4,-1(a1)
    80000e62:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e66:	fed59ae3          	bne	a1,a3,80000e5a <memmove+0x28>

  return dst;
}
    80000e6a:	6422                	ld	s0,8(sp)
    80000e6c:	0141                	addi	sp,sp,16
    80000e6e:	8082                	ret
    d += n;
    80000e70:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e72:	fff6069b          	addiw	a3,a2,-1
    80000e76:	da75                	beqz	a2,80000e6a <memmove+0x38>
    80000e78:	02069613          	slli	a2,a3,0x20
    80000e7c:	9201                	srli	a2,a2,0x20
    80000e7e:	fff64613          	not	a2,a2
    80000e82:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e84:	17fd                	addi	a5,a5,-1
    80000e86:	177d                	addi	a4,a4,-1
    80000e88:	0007c683          	lbu	a3,0(a5)
    80000e8c:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e90:	fec79ae3          	bne	a5,a2,80000e84 <memmove+0x52>
    80000e94:	bfd9                	j	80000e6a <memmove+0x38>

0000000080000e96 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e96:	1141                	addi	sp,sp,-16
    80000e98:	e406                	sd	ra,8(sp)
    80000e9a:	e022                	sd	s0,0(sp)
    80000e9c:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e9e:	00000097          	auipc	ra,0x0
    80000ea2:	f94080e7          	jalr	-108(ra) # 80000e32 <memmove>
}
    80000ea6:	60a2                	ld	ra,8(sp)
    80000ea8:	6402                	ld	s0,0(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret

0000000080000eae <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eae:	1141                	addi	sp,sp,-16
    80000eb0:	e422                	sd	s0,8(sp)
    80000eb2:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000eb4:	ce11                	beqz	a2,80000ed0 <strncmp+0x22>
    80000eb6:	00054783          	lbu	a5,0(a0)
    80000eba:	cf89                	beqz	a5,80000ed4 <strncmp+0x26>
    80000ebc:	0005c703          	lbu	a4,0(a1)
    80000ec0:	00f71a63          	bne	a4,a5,80000ed4 <strncmp+0x26>
    n--, p++, q++;
    80000ec4:	367d                	addiw	a2,a2,-1
    80000ec6:	0505                	addi	a0,a0,1
    80000ec8:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000eca:	f675                	bnez	a2,80000eb6 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000ecc:	4501                	li	a0,0
    80000ece:	a809                	j	80000ee0 <strncmp+0x32>
    80000ed0:	4501                	li	a0,0
    80000ed2:	a039                	j	80000ee0 <strncmp+0x32>
  if(n == 0)
    80000ed4:	ca09                	beqz	a2,80000ee6 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000ed6:	00054503          	lbu	a0,0(a0)
    80000eda:	0005c783          	lbu	a5,0(a1)
    80000ede:	9d1d                	subw	a0,a0,a5
}
    80000ee0:	6422                	ld	s0,8(sp)
    80000ee2:	0141                	addi	sp,sp,16
    80000ee4:	8082                	ret
    return 0;
    80000ee6:	4501                	li	a0,0
    80000ee8:	bfe5                	j	80000ee0 <strncmp+0x32>

0000000080000eea <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000eea:	1141                	addi	sp,sp,-16
    80000eec:	e422                	sd	s0,8(sp)
    80000eee:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000ef0:	872a                	mv	a4,a0
    80000ef2:	8832                	mv	a6,a2
    80000ef4:	367d                	addiw	a2,a2,-1
    80000ef6:	01005963          	blez	a6,80000f08 <strncpy+0x1e>
    80000efa:	0705                	addi	a4,a4,1
    80000efc:	0005c783          	lbu	a5,0(a1)
    80000f00:	fef70fa3          	sb	a5,-1(a4)
    80000f04:	0585                	addi	a1,a1,1
    80000f06:	f7f5                	bnez	a5,80000ef2 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f08:	00c05d63          	blez	a2,80000f22 <strncpy+0x38>
    80000f0c:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f0e:	0685                	addi	a3,a3,1
    80000f10:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f14:	fff6c793          	not	a5,a3
    80000f18:	9fb9                	addw	a5,a5,a4
    80000f1a:	010787bb          	addw	a5,a5,a6
    80000f1e:	fef048e3          	bgtz	a5,80000f0e <strncpy+0x24>
  return os;
}
    80000f22:	6422                	ld	s0,8(sp)
    80000f24:	0141                	addi	sp,sp,16
    80000f26:	8082                	ret

0000000080000f28 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f28:	1141                	addi	sp,sp,-16
    80000f2a:	e422                	sd	s0,8(sp)
    80000f2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f2e:	02c05363          	blez	a2,80000f54 <safestrcpy+0x2c>
    80000f32:	fff6069b          	addiw	a3,a2,-1
    80000f36:	1682                	slli	a3,a3,0x20
    80000f38:	9281                	srli	a3,a3,0x20
    80000f3a:	96ae                	add	a3,a3,a1
    80000f3c:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f3e:	00d58963          	beq	a1,a3,80000f50 <safestrcpy+0x28>
    80000f42:	0585                	addi	a1,a1,1
    80000f44:	0785                	addi	a5,a5,1
    80000f46:	fff5c703          	lbu	a4,-1(a1)
    80000f4a:	fee78fa3          	sb	a4,-1(a5)
    80000f4e:	fb65                	bnez	a4,80000f3e <safestrcpy+0x16>
    ;
  *s = 0;
    80000f50:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f54:	6422                	ld	s0,8(sp)
    80000f56:	0141                	addi	sp,sp,16
    80000f58:	8082                	ret

0000000080000f5a <strlen>:

int
strlen(const char *s)
{
    80000f5a:	1141                	addi	sp,sp,-16
    80000f5c:	e422                	sd	s0,8(sp)
    80000f5e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f60:	00054783          	lbu	a5,0(a0)
    80000f64:	cf91                	beqz	a5,80000f80 <strlen+0x26>
    80000f66:	0505                	addi	a0,a0,1
    80000f68:	87aa                	mv	a5,a0
    80000f6a:	4685                	li	a3,1
    80000f6c:	9e89                	subw	a3,a3,a0
    80000f6e:	00f6853b          	addw	a0,a3,a5
    80000f72:	0785                	addi	a5,a5,1
    80000f74:	fff7c703          	lbu	a4,-1(a5)
    80000f78:	fb7d                	bnez	a4,80000f6e <strlen+0x14>
    ;
  return n;
}
    80000f7a:	6422                	ld	s0,8(sp)
    80000f7c:	0141                	addi	sp,sp,16
    80000f7e:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f80:	4501                	li	a0,0
    80000f82:	bfe5                	j	80000f7a <strlen+0x20>

0000000080000f84 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f84:	1141                	addi	sp,sp,-16
    80000f86:	e406                	sd	ra,8(sp)
    80000f88:	e022                	sd	s0,0(sp)
    80000f8a:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f8c:	00001097          	auipc	ra,0x1
    80000f90:	bd4080e7          	jalr	-1068(ra) # 80001b60 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f94:	00008717          	auipc	a4,0x8
    80000f98:	07870713          	addi	a4,a4,120 # 8000900c <started>
  if(cpuid() == 0){
    80000f9c:	c139                	beqz	a0,80000fe2 <main+0x5e>
    while(started == 0)
    80000f9e:	431c                	lw	a5,0(a4)
    80000fa0:	2781                	sext.w	a5,a5
    80000fa2:	dff5                	beqz	a5,80000f9e <main+0x1a>
      ;
    __sync_synchronize();
    80000fa4:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fa8:	00001097          	auipc	ra,0x1
    80000fac:	bb8080e7          	jalr	-1096(ra) # 80001b60 <cpuid>
    80000fb0:	85aa                	mv	a1,a0
    80000fb2:	00007517          	auipc	a0,0x7
    80000fb6:	10650513          	addi	a0,a0,262 # 800080b8 <digits+0x78>
    80000fba:	fffff097          	auipc	ra,0xfffff
    80000fbe:	5d8080e7          	jalr	1496(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000fc2:	00000097          	auipc	ra,0x0
    80000fc6:	0d8080e7          	jalr	216(ra) # 8000109a <kvminithart>
    trapinithart();   // install kernel trap vector
    80000fca:	00002097          	auipc	ra,0x2
    80000fce:	820080e7          	jalr	-2016(ra) # 800027ea <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000fd2:	00005097          	auipc	ra,0x5
    80000fd6:	e1e080e7          	jalr	-482(ra) # 80005df0 <plicinithart>
  }

  scheduler();        
    80000fda:	00001097          	auipc	ra,0x1
    80000fde:	0e2080e7          	jalr	226(ra) # 800020bc <scheduler>
    consoleinit();
    80000fe2:	fffff097          	auipc	ra,0xfffff
    80000fe6:	478080e7          	jalr	1144(ra) # 8000045a <consoleinit>
    printfinit();
    80000fea:	fffff097          	auipc	ra,0xfffff
    80000fee:	78e080e7          	jalr	1934(ra) # 80000778 <printfinit>
    printf("\n");
    80000ff2:	00007517          	auipc	a0,0x7
    80000ff6:	0d650513          	addi	a0,a0,214 # 800080c8 <digits+0x88>
    80000ffa:	fffff097          	auipc	ra,0xfffff
    80000ffe:	598080e7          	jalr	1432(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80001002:	00007517          	auipc	a0,0x7
    80001006:	09e50513          	addi	a0,a0,158 # 800080a0 <digits+0x60>
    8000100a:	fffff097          	auipc	ra,0xfffff
    8000100e:	588080e7          	jalr	1416(ra) # 80000592 <printf>
    printf("\n");
    80001012:	00007517          	auipc	a0,0x7
    80001016:	0b650513          	addi	a0,a0,182 # 800080c8 <digits+0x88>
    8000101a:	fffff097          	auipc	ra,0xfffff
    8000101e:	578080e7          	jalr	1400(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80001022:	00000097          	auipc	ra,0x0
    80001026:	af2080e7          	jalr	-1294(ra) # 80000b14 <kinit>
    kvminit();       // create kernel page table
    8000102a:	00000097          	auipc	ra,0x0
    8000102e:	2a0080e7          	jalr	672(ra) # 800012ca <kvminit>
    kvminithart();   // turn on paging
    80001032:	00000097          	auipc	ra,0x0
    80001036:	068080e7          	jalr	104(ra) # 8000109a <kvminithart>
    procinit();      // process table
    8000103a:	00001097          	auipc	ra,0x1
    8000103e:	a56080e7          	jalr	-1450(ra) # 80001a90 <procinit>
    trapinit();      // trap vectors
    80001042:	00001097          	auipc	ra,0x1
    80001046:	780080e7          	jalr	1920(ra) # 800027c2 <trapinit>
    trapinithart();  // install kernel trap vector
    8000104a:	00001097          	auipc	ra,0x1
    8000104e:	7a0080e7          	jalr	1952(ra) # 800027ea <trapinithart>
    plicinit();      // set up interrupt controller
    80001052:	00005097          	auipc	ra,0x5
    80001056:	d88080e7          	jalr	-632(ra) # 80005dda <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000105a:	00005097          	auipc	ra,0x5
    8000105e:	d96080e7          	jalr	-618(ra) # 80005df0 <plicinithart>
    binit();         // buffer cache
    80001062:	00002097          	auipc	ra,0x2
    80001066:	f30080e7          	jalr	-208(ra) # 80002f92 <binit>
    iinit();         // inode cache
    8000106a:	00002097          	auipc	ra,0x2
    8000106e:	5c0080e7          	jalr	1472(ra) # 8000362a <iinit>
    fileinit();      // file table
    80001072:	00003097          	auipc	ra,0x3
    80001076:	55e080e7          	jalr	1374(ra) # 800045d0 <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000107a:	00005097          	auipc	ra,0x5
    8000107e:	e7e080e7          	jalr	-386(ra) # 80005ef8 <virtio_disk_init>
    userinit();      // first user process
    80001082:	00001097          	auipc	ra,0x1
    80001086:	dd4080e7          	jalr	-556(ra) # 80001e56 <userinit>
    __sync_synchronize();
    8000108a:	0ff0000f          	fence
    started = 1;
    8000108e:	4785                	li	a5,1
    80001090:	00008717          	auipc	a4,0x8
    80001094:	f6f72e23          	sw	a5,-132(a4) # 8000900c <started>
    80001098:	b789                	j	80000fda <main+0x56>

000000008000109a <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000109a:	1141                	addi	sp,sp,-16
    8000109c:	e422                	sd	s0,8(sp)
    8000109e:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010a0:	00008797          	auipc	a5,0x8
    800010a4:	f707b783          	ld	a5,-144(a5) # 80009010 <kernel_pagetable>
    800010a8:	83b1                	srli	a5,a5,0xc
    800010aa:	577d                	li	a4,-1
    800010ac:	177e                	slli	a4,a4,0x3f
    800010ae:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010b0:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010b4:	12000073          	sfence.vma
  sfence_vma();
}
    800010b8:	6422                	ld	s0,8(sp)
    800010ba:	0141                	addi	sp,sp,16
    800010bc:	8082                	ret

00000000800010be <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010be:	7139                	addi	sp,sp,-64
    800010c0:	fc06                	sd	ra,56(sp)
    800010c2:	f822                	sd	s0,48(sp)
    800010c4:	f426                	sd	s1,40(sp)
    800010c6:	f04a                	sd	s2,32(sp)
    800010c8:	ec4e                	sd	s3,24(sp)
    800010ca:	e852                	sd	s4,16(sp)
    800010cc:	e456                	sd	s5,8(sp)
    800010ce:	e05a                	sd	s6,0(sp)
    800010d0:	0080                	addi	s0,sp,64
    800010d2:	84aa                	mv	s1,a0
    800010d4:	89ae                	mv	s3,a1
    800010d6:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010d8:	57fd                	li	a5,-1
    800010da:	83e9                	srli	a5,a5,0x1a
    800010dc:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010de:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010e0:	04b7f263          	bgeu	a5,a1,80001124 <walk+0x66>
    panic("walk");
    800010e4:	00007517          	auipc	a0,0x7
    800010e8:	fec50513          	addi	a0,a0,-20 # 800080d0 <digits+0x90>
    800010ec:	fffff097          	auipc	ra,0xfffff
    800010f0:	45c080e7          	jalr	1116(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010f4:	060a8663          	beqz	s5,80001160 <walk+0xa2>
    800010f8:	00000097          	auipc	ra,0x0
    800010fc:	a80080e7          	jalr	-1408(ra) # 80000b78 <kalloc>
    80001100:	84aa                	mv	s1,a0
    80001102:	c529                	beqz	a0,8000114c <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001104:	6605                	lui	a2,0x1
    80001106:	4581                	li	a1,0
    80001108:	00000097          	auipc	ra,0x0
    8000110c:	cca080e7          	jalr	-822(ra) # 80000dd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001110:	00c4d793          	srli	a5,s1,0xc
    80001114:	07aa                	slli	a5,a5,0xa
    80001116:	0017e793          	ori	a5,a5,1
    8000111a:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000111e:	3a5d                	addiw	s4,s4,-9
    80001120:	036a0063          	beq	s4,s6,80001140 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001124:	0149d933          	srl	s2,s3,s4
    80001128:	1ff97913          	andi	s2,s2,511
    8000112c:	090e                	slli	s2,s2,0x3
    8000112e:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001130:	00093483          	ld	s1,0(s2)
    80001134:	0014f793          	andi	a5,s1,1
    80001138:	dfd5                	beqz	a5,800010f4 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000113a:	80a9                	srli	s1,s1,0xa
    8000113c:	04b2                	slli	s1,s1,0xc
    8000113e:	b7c5                	j	8000111e <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001140:	00c9d513          	srli	a0,s3,0xc
    80001144:	1ff57513          	andi	a0,a0,511
    80001148:	050e                	slli	a0,a0,0x3
    8000114a:	9526                	add	a0,a0,s1
}
    8000114c:	70e2                	ld	ra,56(sp)
    8000114e:	7442                	ld	s0,48(sp)
    80001150:	74a2                	ld	s1,40(sp)
    80001152:	7902                	ld	s2,32(sp)
    80001154:	69e2                	ld	s3,24(sp)
    80001156:	6a42                	ld	s4,16(sp)
    80001158:	6aa2                	ld	s5,8(sp)
    8000115a:	6b02                	ld	s6,0(sp)
    8000115c:	6121                	addi	sp,sp,64
    8000115e:	8082                	ret
        return 0;
    80001160:	4501                	li	a0,0
    80001162:	b7ed                	j	8000114c <walk+0x8e>

0000000080001164 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001164:	57fd                	li	a5,-1
    80001166:	83e9                	srli	a5,a5,0x1a
    80001168:	00b7f463          	bgeu	a5,a1,80001170 <walkaddr+0xc>
    return 0;
    8000116c:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000116e:	8082                	ret
{
    80001170:	1141                	addi	sp,sp,-16
    80001172:	e406                	sd	ra,8(sp)
    80001174:	e022                	sd	s0,0(sp)
    80001176:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001178:	4601                	li	a2,0
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	f44080e7          	jalr	-188(ra) # 800010be <walk>
  if(pte == 0)
    80001182:	c105                	beqz	a0,800011a2 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001184:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001186:	0117f693          	andi	a3,a5,17
    8000118a:	4745                	li	a4,17
    return 0;
    8000118c:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000118e:	00e68663          	beq	a3,a4,8000119a <walkaddr+0x36>
}
    80001192:	60a2                	ld	ra,8(sp)
    80001194:	6402                	ld	s0,0(sp)
    80001196:	0141                	addi	sp,sp,16
    80001198:	8082                	ret
  pa = PTE2PA(*pte);
    8000119a:	00a7d513          	srli	a0,a5,0xa
    8000119e:	0532                	slli	a0,a0,0xc
  return pa;
    800011a0:	bfcd                	j	80001192 <walkaddr+0x2e>
    return 0;
    800011a2:	4501                	li	a0,0
    800011a4:	b7fd                	j	80001192 <walkaddr+0x2e>

00000000800011a6 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800011a6:	1101                	addi	sp,sp,-32
    800011a8:	ec06                	sd	ra,24(sp)
    800011aa:	e822                	sd	s0,16(sp)
    800011ac:	e426                	sd	s1,8(sp)
    800011ae:	1000                	addi	s0,sp,32
    800011b0:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800011b2:	1552                	slli	a0,a0,0x34
    800011b4:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800011b8:	4601                	li	a2,0
    800011ba:	00008517          	auipc	a0,0x8
    800011be:	e5653503          	ld	a0,-426(a0) # 80009010 <kernel_pagetable>
    800011c2:	00000097          	auipc	ra,0x0
    800011c6:	efc080e7          	jalr	-260(ra) # 800010be <walk>
  if(pte == 0)
    800011ca:	cd09                	beqz	a0,800011e4 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011cc:	6108                	ld	a0,0(a0)
    800011ce:	00157793          	andi	a5,a0,1
    800011d2:	c38d                	beqz	a5,800011f4 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011d4:	8129                	srli	a0,a0,0xa
    800011d6:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800011d8:	9526                	add	a0,a0,s1
    800011da:	60e2                	ld	ra,24(sp)
    800011dc:	6442                	ld	s0,16(sp)
    800011de:	64a2                	ld	s1,8(sp)
    800011e0:	6105                	addi	sp,sp,32
    800011e2:	8082                	ret
    panic("kvmpa");
    800011e4:	00007517          	auipc	a0,0x7
    800011e8:	ef450513          	addi	a0,a0,-268 # 800080d8 <digits+0x98>
    800011ec:	fffff097          	auipc	ra,0xfffff
    800011f0:	35c080e7          	jalr	860(ra) # 80000548 <panic>
    panic("kvmpa");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ee450513          	addi	a0,a0,-284 # 800080d8 <digits+0x98>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001204:	715d                	addi	sp,sp,-80
    80001206:	e486                	sd	ra,72(sp)
    80001208:	e0a2                	sd	s0,64(sp)
    8000120a:	fc26                	sd	s1,56(sp)
    8000120c:	f84a                	sd	s2,48(sp)
    8000120e:	f44e                	sd	s3,40(sp)
    80001210:	f052                	sd	s4,32(sp)
    80001212:	ec56                	sd	s5,24(sp)
    80001214:	e85a                	sd	s6,16(sp)
    80001216:	e45e                	sd	s7,8(sp)
    80001218:	0880                	addi	s0,sp,80
    8000121a:	8aaa                	mv	s5,a0
    8000121c:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000121e:	777d                	lui	a4,0xfffff
    80001220:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001224:	167d                	addi	a2,a2,-1
    80001226:	00b609b3          	add	s3,a2,a1
    8000122a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000122e:	893e                	mv	s2,a5
    80001230:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001234:	6b85                	lui	s7,0x1
    80001236:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000123a:	4605                	li	a2,1
    8000123c:	85ca                	mv	a1,s2
    8000123e:	8556                	mv	a0,s5
    80001240:	00000097          	auipc	ra,0x0
    80001244:	e7e080e7          	jalr	-386(ra) # 800010be <walk>
    80001248:	c51d                	beqz	a0,80001276 <mappages+0x72>
    if(*pte & PTE_V)
    8000124a:	611c                	ld	a5,0(a0)
    8000124c:	8b85                	andi	a5,a5,1
    8000124e:	ef81                	bnez	a5,80001266 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001250:	80b1                	srli	s1,s1,0xc
    80001252:	04aa                	slli	s1,s1,0xa
    80001254:	0164e4b3          	or	s1,s1,s6
    80001258:	0014e493          	ori	s1,s1,1
    8000125c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000125e:	03390863          	beq	s2,s3,8000128e <mappages+0x8a>
    a += PGSIZE;
    80001262:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001264:	bfc9                	j	80001236 <mappages+0x32>
      panic("remap");
    80001266:	00007517          	auipc	a0,0x7
    8000126a:	e7a50513          	addi	a0,a0,-390 # 800080e0 <digits+0xa0>
    8000126e:	fffff097          	auipc	ra,0xfffff
    80001272:	2da080e7          	jalr	730(ra) # 80000548 <panic>
      return -1;
    80001276:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001278:	60a6                	ld	ra,72(sp)
    8000127a:	6406                	ld	s0,64(sp)
    8000127c:	74e2                	ld	s1,56(sp)
    8000127e:	7942                	ld	s2,48(sp)
    80001280:	79a2                	ld	s3,40(sp)
    80001282:	7a02                	ld	s4,32(sp)
    80001284:	6ae2                	ld	s5,24(sp)
    80001286:	6b42                	ld	s6,16(sp)
    80001288:	6ba2                	ld	s7,8(sp)
    8000128a:	6161                	addi	sp,sp,80
    8000128c:	8082                	ret
  return 0;
    8000128e:	4501                	li	a0,0
    80001290:	b7e5                	j	80001278 <mappages+0x74>

0000000080001292 <kvmmap>:
{
    80001292:	1141                	addi	sp,sp,-16
    80001294:	e406                	sd	ra,8(sp)
    80001296:	e022                	sd	s0,0(sp)
    80001298:	0800                	addi	s0,sp,16
    8000129a:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000129c:	86ae                	mv	a3,a1
    8000129e:	85aa                	mv	a1,a0
    800012a0:	00008517          	auipc	a0,0x8
    800012a4:	d7053503          	ld	a0,-656(a0) # 80009010 <kernel_pagetable>
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f5c080e7          	jalr	-164(ra) # 80001204 <mappages>
    800012b0:	e509                	bnez	a0,800012ba <kvmmap+0x28>
}
    800012b2:	60a2                	ld	ra,8(sp)
    800012b4:	6402                	ld	s0,0(sp)
    800012b6:	0141                	addi	sp,sp,16
    800012b8:	8082                	ret
    panic("kvmmap");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e2e50513          	addi	a0,a0,-466 # 800080e8 <digits+0xa8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	286080e7          	jalr	646(ra) # 80000548 <panic>

00000000800012ca <kvminit>:
{
    800012ca:	1101                	addi	sp,sp,-32
    800012cc:	ec06                	sd	ra,24(sp)
    800012ce:	e822                	sd	s0,16(sp)
    800012d0:	e426                	sd	s1,8(sp)
    800012d2:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800012d4:	00000097          	auipc	ra,0x0
    800012d8:	8a4080e7          	jalr	-1884(ra) # 80000b78 <kalloc>
    800012dc:	00008797          	auipc	a5,0x8
    800012e0:	d2a7ba23          	sd	a0,-716(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800012e4:	6605                	lui	a2,0x1
    800012e6:	4581                	li	a1,0
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	aea080e7          	jalr	-1302(ra) # 80000dd2 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012f0:	4699                	li	a3,6
    800012f2:	6605                	lui	a2,0x1
    800012f4:	100005b7          	lui	a1,0x10000
    800012f8:	10000537          	lui	a0,0x10000
    800012fc:	00000097          	auipc	ra,0x0
    80001300:	f96080e7          	jalr	-106(ra) # 80001292 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001304:	4699                	li	a3,6
    80001306:	6605                	lui	a2,0x1
    80001308:	100015b7          	lui	a1,0x10001
    8000130c:	10001537          	lui	a0,0x10001
    80001310:	00000097          	auipc	ra,0x0
    80001314:	f82080e7          	jalr	-126(ra) # 80001292 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001318:	4699                	li	a3,6
    8000131a:	6641                	lui	a2,0x10
    8000131c:	020005b7          	lui	a1,0x2000
    80001320:	02000537          	lui	a0,0x2000
    80001324:	00000097          	auipc	ra,0x0
    80001328:	f6e080e7          	jalr	-146(ra) # 80001292 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000132c:	4699                	li	a3,6
    8000132e:	00400637          	lui	a2,0x400
    80001332:	0c0005b7          	lui	a1,0xc000
    80001336:	0c000537          	lui	a0,0xc000
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f58080e7          	jalr	-168(ra) # 80001292 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001342:	00007497          	auipc	s1,0x7
    80001346:	cbe48493          	addi	s1,s1,-834 # 80008000 <etext>
    8000134a:	46a9                	li	a3,10
    8000134c:	80007617          	auipc	a2,0x80007
    80001350:	cb460613          	addi	a2,a2,-844 # 8000 <_entry-0x7fff8000>
    80001354:	4585                	li	a1,1
    80001356:	05fe                	slli	a1,a1,0x1f
    80001358:	852e                	mv	a0,a1
    8000135a:	00000097          	auipc	ra,0x0
    8000135e:	f38080e7          	jalr	-200(ra) # 80001292 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001362:	4699                	li	a3,6
    80001364:	4645                	li	a2,17
    80001366:	066e                	slli	a2,a2,0x1b
    80001368:	8e05                	sub	a2,a2,s1
    8000136a:	85a6                	mv	a1,s1
    8000136c:	8526                	mv	a0,s1
    8000136e:	00000097          	auipc	ra,0x0
    80001372:	f24080e7          	jalr	-220(ra) # 80001292 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001376:	46a9                	li	a3,10
    80001378:	6605                	lui	a2,0x1
    8000137a:	00006597          	auipc	a1,0x6
    8000137e:	c8658593          	addi	a1,a1,-890 # 80007000 <_trampoline>
    80001382:	04000537          	lui	a0,0x4000
    80001386:	157d                	addi	a0,a0,-1
    80001388:	0532                	slli	a0,a0,0xc
    8000138a:	00000097          	auipc	ra,0x0
    8000138e:	f08080e7          	jalr	-248(ra) # 80001292 <kvmmap>
}
    80001392:	60e2                	ld	ra,24(sp)
    80001394:	6442                	ld	s0,16(sp)
    80001396:	64a2                	ld	s1,8(sp)
    80001398:	6105                	addi	sp,sp,32
    8000139a:	8082                	ret

000000008000139c <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000139c:	715d                	addi	sp,sp,-80
    8000139e:	e486                	sd	ra,72(sp)
    800013a0:	e0a2                	sd	s0,64(sp)
    800013a2:	fc26                	sd	s1,56(sp)
    800013a4:	f84a                	sd	s2,48(sp)
    800013a6:	f44e                	sd	s3,40(sp)
    800013a8:	f052                	sd	s4,32(sp)
    800013aa:	ec56                	sd	s5,24(sp)
    800013ac:	e85a                	sd	s6,16(sp)
    800013ae:	e45e                	sd	s7,8(sp)
    800013b0:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013b2:	03459793          	slli	a5,a1,0x34
    800013b6:	e795                	bnez	a5,800013e2 <uvmunmap+0x46>
    800013b8:	8a2a                	mv	s4,a0
    800013ba:	892e                	mv	s2,a1
    800013bc:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013be:	0632                	slli	a2,a2,0xc
    800013c0:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800013c4:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c6:	6b05                	lui	s6,0x1
    800013c8:	0735e863          	bltu	a1,s3,80001438 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013cc:	60a6                	ld	ra,72(sp)
    800013ce:	6406                	ld	s0,64(sp)
    800013d0:	74e2                	ld	s1,56(sp)
    800013d2:	7942                	ld	s2,48(sp)
    800013d4:	79a2                	ld	s3,40(sp)
    800013d6:	7a02                	ld	s4,32(sp)
    800013d8:	6ae2                	ld	s5,24(sp)
    800013da:	6b42                	ld	s6,16(sp)
    800013dc:	6ba2                	ld	s7,8(sp)
    800013de:	6161                	addi	sp,sp,80
    800013e0:	8082                	ret
    panic("uvmunmap: not aligned");
    800013e2:	00007517          	auipc	a0,0x7
    800013e6:	d0e50513          	addi	a0,a0,-754 # 800080f0 <digits+0xb0>
    800013ea:	fffff097          	auipc	ra,0xfffff
    800013ee:	15e080e7          	jalr	350(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    800013f2:	00007517          	auipc	a0,0x7
    800013f6:	d1650513          	addi	a0,a0,-746 # 80008108 <digits+0xc8>
    800013fa:	fffff097          	auipc	ra,0xfffff
    800013fe:	14e080e7          	jalr	334(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d1650513          	addi	a0,a0,-746 # 80008118 <digits+0xd8>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	13e080e7          	jalr	318(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001412:	00007517          	auipc	a0,0x7
    80001416:	d1e50513          	addi	a0,a0,-738 # 80008130 <digits+0xf0>
    8000141a:	fffff097          	auipc	ra,0xfffff
    8000141e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001422:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001424:	0532                	slli	a0,a0,0xc
    80001426:	fffff097          	auipc	ra,0xfffff
    8000142a:	5fe080e7          	jalr	1534(ra) # 80000a24 <kfree>
    *pte = 0;
    8000142e:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001432:	995a                	add	s2,s2,s6
    80001434:	f9397ce3          	bgeu	s2,s3,800013cc <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001438:	4601                	li	a2,0
    8000143a:	85ca                	mv	a1,s2
    8000143c:	8552                	mv	a0,s4
    8000143e:	00000097          	auipc	ra,0x0
    80001442:	c80080e7          	jalr	-896(ra) # 800010be <walk>
    80001446:	84aa                	mv	s1,a0
    80001448:	d54d                	beqz	a0,800013f2 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000144a:	6108                	ld	a0,0(a0)
    8000144c:	00157793          	andi	a5,a0,1
    80001450:	dbcd                	beqz	a5,80001402 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001452:	3ff57793          	andi	a5,a0,1023
    80001456:	fb778ee3          	beq	a5,s7,80001412 <uvmunmap+0x76>
    if(do_free){
    8000145a:	fc0a8ae3          	beqz	s5,8000142e <uvmunmap+0x92>
    8000145e:	b7d1                	j	80001422 <uvmunmap+0x86>

0000000080001460 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001460:	1101                	addi	sp,sp,-32
    80001462:	ec06                	sd	ra,24(sp)
    80001464:	e822                	sd	s0,16(sp)
    80001466:	e426                	sd	s1,8(sp)
    80001468:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000146a:	fffff097          	auipc	ra,0xfffff
    8000146e:	70e080e7          	jalr	1806(ra) # 80000b78 <kalloc>
    80001472:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001474:	c519                	beqz	a0,80001482 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001476:	6605                	lui	a2,0x1
    80001478:	4581                	li	a1,0
    8000147a:	00000097          	auipc	ra,0x0
    8000147e:	958080e7          	jalr	-1704(ra) # 80000dd2 <memset>
  return pagetable;
}
    80001482:	8526                	mv	a0,s1
    80001484:	60e2                	ld	ra,24(sp)
    80001486:	6442                	ld	s0,16(sp)
    80001488:	64a2                	ld	s1,8(sp)
    8000148a:	6105                	addi	sp,sp,32
    8000148c:	8082                	ret

000000008000148e <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000148e:	7179                	addi	sp,sp,-48
    80001490:	f406                	sd	ra,40(sp)
    80001492:	f022                	sd	s0,32(sp)
    80001494:	ec26                	sd	s1,24(sp)
    80001496:	e84a                	sd	s2,16(sp)
    80001498:	e44e                	sd	s3,8(sp)
    8000149a:	e052                	sd	s4,0(sp)
    8000149c:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000149e:	6785                	lui	a5,0x1
    800014a0:	04f67863          	bgeu	a2,a5,800014f0 <uvminit+0x62>
    800014a4:	8a2a                	mv	s4,a0
    800014a6:	89ae                	mv	s3,a1
    800014a8:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800014aa:	fffff097          	auipc	ra,0xfffff
    800014ae:	6ce080e7          	jalr	1742(ra) # 80000b78 <kalloc>
    800014b2:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014b4:	6605                	lui	a2,0x1
    800014b6:	4581                	li	a1,0
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	91a080e7          	jalr	-1766(ra) # 80000dd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014c0:	4779                	li	a4,30
    800014c2:	86ca                	mv	a3,s2
    800014c4:	6605                	lui	a2,0x1
    800014c6:	4581                	li	a1,0
    800014c8:	8552                	mv	a0,s4
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	d3a080e7          	jalr	-710(ra) # 80001204 <mappages>
  memmove(mem, src, sz);
    800014d2:	8626                	mv	a2,s1
    800014d4:	85ce                	mv	a1,s3
    800014d6:	854a                	mv	a0,s2
    800014d8:	00000097          	auipc	ra,0x0
    800014dc:	95a080e7          	jalr	-1702(ra) # 80000e32 <memmove>
}
    800014e0:	70a2                	ld	ra,40(sp)
    800014e2:	7402                	ld	s0,32(sp)
    800014e4:	64e2                	ld	s1,24(sp)
    800014e6:	6942                	ld	s2,16(sp)
    800014e8:	69a2                	ld	s3,8(sp)
    800014ea:	6a02                	ld	s4,0(sp)
    800014ec:	6145                	addi	sp,sp,48
    800014ee:	8082                	ret
    panic("inituvm: more than a page");
    800014f0:	00007517          	auipc	a0,0x7
    800014f4:	c5850513          	addi	a0,a0,-936 # 80008148 <digits+0x108>
    800014f8:	fffff097          	auipc	ra,0xfffff
    800014fc:	050080e7          	jalr	80(ra) # 80000548 <panic>

0000000080001500 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001500:	1101                	addi	sp,sp,-32
    80001502:	ec06                	sd	ra,24(sp)
    80001504:	e822                	sd	s0,16(sp)
    80001506:	e426                	sd	s1,8(sp)
    80001508:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000150a:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000150c:	00b67d63          	bgeu	a2,a1,80001526 <uvmdealloc+0x26>
    80001510:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001512:	6785                	lui	a5,0x1
    80001514:	17fd                	addi	a5,a5,-1
    80001516:	00f60733          	add	a4,a2,a5
    8000151a:	767d                	lui	a2,0xfffff
    8000151c:	8f71                	and	a4,a4,a2
    8000151e:	97ae                	add	a5,a5,a1
    80001520:	8ff1                	and	a5,a5,a2
    80001522:	00f76863          	bltu	a4,a5,80001532 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001526:	8526                	mv	a0,s1
    80001528:	60e2                	ld	ra,24(sp)
    8000152a:	6442                	ld	s0,16(sp)
    8000152c:	64a2                	ld	s1,8(sp)
    8000152e:	6105                	addi	sp,sp,32
    80001530:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001532:	8f99                	sub	a5,a5,a4
    80001534:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001536:	4685                	li	a3,1
    80001538:	0007861b          	sext.w	a2,a5
    8000153c:	85ba                	mv	a1,a4
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	e5e080e7          	jalr	-418(ra) # 8000139c <uvmunmap>
    80001546:	b7c5                	j	80001526 <uvmdealloc+0x26>

0000000080001548 <uvmalloc>:
  if(newsz < oldsz)
    80001548:	0ab66163          	bltu	a2,a1,800015ea <uvmalloc+0xa2>
{
    8000154c:	7139                	addi	sp,sp,-64
    8000154e:	fc06                	sd	ra,56(sp)
    80001550:	f822                	sd	s0,48(sp)
    80001552:	f426                	sd	s1,40(sp)
    80001554:	f04a                	sd	s2,32(sp)
    80001556:	ec4e                	sd	s3,24(sp)
    80001558:	e852                	sd	s4,16(sp)
    8000155a:	e456                	sd	s5,8(sp)
    8000155c:	0080                	addi	s0,sp,64
    8000155e:	8aaa                	mv	s5,a0
    80001560:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001562:	6985                	lui	s3,0x1
    80001564:	19fd                	addi	s3,s3,-1
    80001566:	95ce                	add	a1,a1,s3
    80001568:	79fd                	lui	s3,0xfffff
    8000156a:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000156e:	08c9f063          	bgeu	s3,a2,800015ee <uvmalloc+0xa6>
    80001572:	894e                	mv	s2,s3
    mem = kalloc();
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	604080e7          	jalr	1540(ra) # 80000b78 <kalloc>
    8000157c:	84aa                	mv	s1,a0
    if(mem == 0){
    8000157e:	c51d                	beqz	a0,800015ac <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001580:	6605                	lui	a2,0x1
    80001582:	4581                	li	a1,0
    80001584:	00000097          	auipc	ra,0x0
    80001588:	84e080e7          	jalr	-1970(ra) # 80000dd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000158c:	4779                	li	a4,30
    8000158e:	86a6                	mv	a3,s1
    80001590:	6605                	lui	a2,0x1
    80001592:	85ca                	mv	a1,s2
    80001594:	8556                	mv	a0,s5
    80001596:	00000097          	auipc	ra,0x0
    8000159a:	c6e080e7          	jalr	-914(ra) # 80001204 <mappages>
    8000159e:	e905                	bnez	a0,800015ce <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800015a0:	6785                	lui	a5,0x1
    800015a2:	993e                	add	s2,s2,a5
    800015a4:	fd4968e3          	bltu	s2,s4,80001574 <uvmalloc+0x2c>
  return newsz;
    800015a8:	8552                	mv	a0,s4
    800015aa:	a809                	j	800015bc <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800015ac:	864e                	mv	a2,s3
    800015ae:	85ca                	mv	a1,s2
    800015b0:	8556                	mv	a0,s5
    800015b2:	00000097          	auipc	ra,0x0
    800015b6:	f4e080e7          	jalr	-178(ra) # 80001500 <uvmdealloc>
      return 0;
    800015ba:	4501                	li	a0,0
}
    800015bc:	70e2                	ld	ra,56(sp)
    800015be:	7442                	ld	s0,48(sp)
    800015c0:	74a2                	ld	s1,40(sp)
    800015c2:	7902                	ld	s2,32(sp)
    800015c4:	69e2                	ld	s3,24(sp)
    800015c6:	6a42                	ld	s4,16(sp)
    800015c8:	6aa2                	ld	s5,8(sp)
    800015ca:	6121                	addi	sp,sp,64
    800015cc:	8082                	ret
      kfree(mem);
    800015ce:	8526                	mv	a0,s1
    800015d0:	fffff097          	auipc	ra,0xfffff
    800015d4:	454080e7          	jalr	1108(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015d8:	864e                	mv	a2,s3
    800015da:	85ca                	mv	a1,s2
    800015dc:	8556                	mv	a0,s5
    800015de:	00000097          	auipc	ra,0x0
    800015e2:	f22080e7          	jalr	-222(ra) # 80001500 <uvmdealloc>
      return 0;
    800015e6:	4501                	li	a0,0
    800015e8:	bfd1                	j	800015bc <uvmalloc+0x74>
    return oldsz;
    800015ea:	852e                	mv	a0,a1
}
    800015ec:	8082                	ret
  return newsz;
    800015ee:	8532                	mv	a0,a2
    800015f0:	b7f1                	j	800015bc <uvmalloc+0x74>

00000000800015f2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015f2:	7179                	addi	sp,sp,-48
    800015f4:	f406                	sd	ra,40(sp)
    800015f6:	f022                	sd	s0,32(sp)
    800015f8:	ec26                	sd	s1,24(sp)
    800015fa:	e84a                	sd	s2,16(sp)
    800015fc:	e44e                	sd	s3,8(sp)
    800015fe:	e052                	sd	s4,0(sp)
    80001600:	1800                	addi	s0,sp,48
    80001602:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001604:	84aa                	mv	s1,a0
    80001606:	6905                	lui	s2,0x1
    80001608:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000160a:	4985                	li	s3,1
    8000160c:	a821                	j	80001624 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000160e:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001610:	0532                	slli	a0,a0,0xc
    80001612:	00000097          	auipc	ra,0x0
    80001616:	fe0080e7          	jalr	-32(ra) # 800015f2 <freewalk>
      pagetable[i] = 0;
    8000161a:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000161e:	04a1                	addi	s1,s1,8
    80001620:	03248163          	beq	s1,s2,80001642 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001624:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001626:	00f57793          	andi	a5,a0,15
    8000162a:	ff3782e3          	beq	a5,s3,8000160e <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000162e:	8905                	andi	a0,a0,1
    80001630:	d57d                	beqz	a0,8000161e <freewalk+0x2c>
      panic("freewalk: leaf");
    80001632:	00007517          	auipc	a0,0x7
    80001636:	b3650513          	addi	a0,a0,-1226 # 80008168 <digits+0x128>
    8000163a:	fffff097          	auipc	ra,0xfffff
    8000163e:	f0e080e7          	jalr	-242(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001642:	8552                	mv	a0,s4
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	3e0080e7          	jalr	992(ra) # 80000a24 <kfree>
}
    8000164c:	70a2                	ld	ra,40(sp)
    8000164e:	7402                	ld	s0,32(sp)
    80001650:	64e2                	ld	s1,24(sp)
    80001652:	6942                	ld	s2,16(sp)
    80001654:	69a2                	ld	s3,8(sp)
    80001656:	6a02                	ld	s4,0(sp)
    80001658:	6145                	addi	sp,sp,48
    8000165a:	8082                	ret

000000008000165c <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000165c:	1101                	addi	sp,sp,-32
    8000165e:	ec06                	sd	ra,24(sp)
    80001660:	e822                	sd	s0,16(sp)
    80001662:	e426                	sd	s1,8(sp)
    80001664:	1000                	addi	s0,sp,32
    80001666:	84aa                	mv	s1,a0
  if(sz > 0)
    80001668:	e999                	bnez	a1,8000167e <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000166a:	8526                	mv	a0,s1
    8000166c:	00000097          	auipc	ra,0x0
    80001670:	f86080e7          	jalr	-122(ra) # 800015f2 <freewalk>
}
    80001674:	60e2                	ld	ra,24(sp)
    80001676:	6442                	ld	s0,16(sp)
    80001678:	64a2                	ld	s1,8(sp)
    8000167a:	6105                	addi	sp,sp,32
    8000167c:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000167e:	6605                	lui	a2,0x1
    80001680:	167d                	addi	a2,a2,-1
    80001682:	962e                	add	a2,a2,a1
    80001684:	4685                	li	a3,1
    80001686:	8231                	srli	a2,a2,0xc
    80001688:	4581                	li	a1,0
    8000168a:	00000097          	auipc	ra,0x0
    8000168e:	d12080e7          	jalr	-750(ra) # 8000139c <uvmunmap>
    80001692:	bfe1                	j	8000166a <uvmfree+0xe>

0000000080001694 <uvmcopy>:
{
  pte_t *pte;
  uint64 pa, i;
  uint flags;

  for(i = 0; i < sz; i += PGSIZE){
    80001694:	c671                	beqz	a2,80001760 <uvmcopy+0xcc>
{
    80001696:	7139                	addi	sp,sp,-64
    80001698:	fc06                	sd	ra,56(sp)
    8000169a:	f822                	sd	s0,48(sp)
    8000169c:	f426                	sd	s1,40(sp)
    8000169e:	f04a                	sd	s2,32(sp)
    800016a0:	ec4e                	sd	s3,24(sp)
    800016a2:	e852                	sd	s4,16(sp)
    800016a4:	e456                	sd	s5,8(sp)
    800016a6:	e05a                	sd	s6,0(sp)
    800016a8:	0080                	addi	s0,sp,64
    800016aa:	8aaa                	mv	s5,a0
    800016ac:	8a2e                	mv	s4,a1
    800016ae:	89b2                	mv	s3,a2
  for(i = 0; i < sz; i += PGSIZE){
    800016b0:	4901                	li	s2,0
    800016b2:	a891                	j	80001706 <uvmcopy+0x72>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800016b4:	00007517          	auipc	a0,0x7
    800016b8:	ac450513          	addi	a0,a0,-1340 # 80008178 <digits+0x138>
    800016bc:	fffff097          	auipc	ra,0xfffff
    800016c0:	e8c080e7          	jalr	-372(ra) # 80000548 <panic>
    if((*pte & PTE_V) == 0)
      panic("uvmcopy: page not present");
    800016c4:	00007517          	auipc	a0,0x7
    800016c8:	ad450513          	addi	a0,a0,-1324 # 80008198 <digits+0x158>
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	e7c080e7          	jalr	-388(ra) # 80000548 <panic>
    if (*pte & PTE_W)
    {
      *pte = *pte & (~PTE_W);
      *pte = *pte | PTE_RSW;
    }
    pa = PTE2PA(*pte);
    800016d4:	00053b03          	ld	s6,0(a0)
    800016d8:	00ab5493          	srli	s1,s6,0xa
    800016dc:	04b2                	slli	s1,s1,0xc
    flags = PTE_FLAGS(*pte);
    cow_alloc(pa);
    800016de:	8526                	mv	a0,s1
    800016e0:	fffff097          	auipc	ra,0xfffff
    800016e4:	518080e7          	jalr	1304(ra) # 80000bf8 <cow_alloc>
    if(mappages(new, i, PGSIZE, pa, flags) != 0){
    800016e8:	3ffb7713          	andi	a4,s6,1023
    800016ec:	86a6                	mv	a3,s1
    800016ee:	6605                	lui	a2,0x1
    800016f0:	85ca                	mv	a1,s2
    800016f2:	8552                	mv	a0,s4
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	b10080e7          	jalr	-1264(ra) # 80001204 <mappages>
    800016fc:	e90d                	bnez	a0,8000172e <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016fe:	6785                	lui	a5,0x1
    80001700:	993e                	add	s2,s2,a5
    80001702:	05397563          	bgeu	s2,s3,8000174c <uvmcopy+0xb8>
    if((pte = walk(old, i, 0)) == 0)
    80001706:	4601                	li	a2,0
    80001708:	85ca                	mv	a1,s2
    8000170a:	8556                	mv	a0,s5
    8000170c:	00000097          	auipc	ra,0x0
    80001710:	9b2080e7          	jalr	-1614(ra) # 800010be <walk>
    80001714:	d145                	beqz	a0,800016b4 <uvmcopy+0x20>
    if((*pte & PTE_V) == 0)
    80001716:	611c                	ld	a5,0(a0)
    80001718:	0017f713          	andi	a4,a5,1
    8000171c:	d745                	beqz	a4,800016c4 <uvmcopy+0x30>
    if (*pte & PTE_W)
    8000171e:	0047f713          	andi	a4,a5,4
    80001722:	db4d                	beqz	a4,800016d4 <uvmcopy+0x40>
      *pte = *pte & (~PTE_W);
    80001724:	9bed                	andi	a5,a5,-5
      *pte = *pte | PTE_RSW;
    80001726:	1007e793          	ori	a5,a5,256
    8000172a:	e11c                	sd	a5,0(a0)
    8000172c:	b765                	j	800016d4 <uvmcopy+0x40>
      kfree((void *)pa);
    8000172e:	8526                	mv	a0,s1
    80001730:	fffff097          	auipc	ra,0xfffff
    80001734:	2f4080e7          	jalr	756(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001738:	4685                	li	a3,1
    8000173a:	00c95613          	srli	a2,s2,0xc
    8000173e:	4581                	li	a1,0
    80001740:	8552                	mv	a0,s4
    80001742:	00000097          	auipc	ra,0x0
    80001746:	c5a080e7          	jalr	-934(ra) # 8000139c <uvmunmap>
  return -1;
    8000174a:	557d                	li	a0,-1
}
    8000174c:	70e2                	ld	ra,56(sp)
    8000174e:	7442                	ld	s0,48(sp)
    80001750:	74a2                	ld	s1,40(sp)
    80001752:	7902                	ld	s2,32(sp)
    80001754:	69e2                	ld	s3,24(sp)
    80001756:	6a42                	ld	s4,16(sp)
    80001758:	6aa2                	ld	s5,8(sp)
    8000175a:	6b02                	ld	s6,0(sp)
    8000175c:	6121                	addi	sp,sp,64
    8000175e:	8082                	ret
  return 0;
    80001760:	4501                	li	a0,0
}
    80001762:	8082                	ret

0000000080001764 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001764:	1141                	addi	sp,sp,-16
    80001766:	e406                	sd	ra,8(sp)
    80001768:	e022                	sd	s0,0(sp)
    8000176a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000176c:	4601                	li	a2,0
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	950080e7          	jalr	-1712(ra) # 800010be <walk>
  if(pte == 0)
    80001776:	c901                	beqz	a0,80001786 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001778:	611c                	ld	a5,0(a0)
    8000177a:	9bbd                	andi	a5,a5,-17
    8000177c:	e11c                	sd	a5,0(a0)
}
    8000177e:	60a2                	ld	ra,8(sp)
    80001780:	6402                	ld	s0,0(sp)
    80001782:	0141                	addi	sp,sp,16
    80001784:	8082                	ret
    panic("uvmclear");
    80001786:	00007517          	auipc	a0,0x7
    8000178a:	a3250513          	addi	a0,a0,-1486 # 800081b8 <digits+0x178>
    8000178e:	fffff097          	auipc	ra,0xfffff
    80001792:	dba080e7          	jalr	-582(ra) # 80000548 <panic>

0000000080001796 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001796:	c6bd                	beqz	a3,80001804 <copyin+0x6e>
{
    80001798:	715d                	addi	sp,sp,-80
    8000179a:	e486                	sd	ra,72(sp)
    8000179c:	e0a2                	sd	s0,64(sp)
    8000179e:	fc26                	sd	s1,56(sp)
    800017a0:	f84a                	sd	s2,48(sp)
    800017a2:	f44e                	sd	s3,40(sp)
    800017a4:	f052                	sd	s4,32(sp)
    800017a6:	ec56                	sd	s5,24(sp)
    800017a8:	e85a                	sd	s6,16(sp)
    800017aa:	e45e                	sd	s7,8(sp)
    800017ac:	e062                	sd	s8,0(sp)
    800017ae:	0880                	addi	s0,sp,80
    800017b0:	8b2a                	mv	s6,a0
    800017b2:	8a2e                	mv	s4,a1
    800017b4:	8c32                	mv	s8,a2
    800017b6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017b8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017ba:	6a85                	lui	s5,0x1
    800017bc:	a015                	j	800017e0 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017be:	9562                	add	a0,a0,s8
    800017c0:	0004861b          	sext.w	a2,s1
    800017c4:	412505b3          	sub	a1,a0,s2
    800017c8:	8552                	mv	a0,s4
    800017ca:	fffff097          	auipc	ra,0xfffff
    800017ce:	668080e7          	jalr	1640(ra) # 80000e32 <memmove>

    len -= n;
    800017d2:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017d6:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017d8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017dc:	02098263          	beqz	s3,80001800 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017e0:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017e4:	85ca                	mv	a1,s2
    800017e6:	855a                	mv	a0,s6
    800017e8:	00000097          	auipc	ra,0x0
    800017ec:	97c080e7          	jalr	-1668(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    800017f0:	cd01                	beqz	a0,80001808 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017f2:	418904b3          	sub	s1,s2,s8
    800017f6:	94d6                	add	s1,s1,s5
    if(n > len)
    800017f8:	fc99f3e3          	bgeu	s3,s1,800017be <copyin+0x28>
    800017fc:	84ce                	mv	s1,s3
    800017fe:	b7c1                	j	800017be <copyin+0x28>
  }
  return 0;
    80001800:	4501                	li	a0,0
    80001802:	a021                	j	8000180a <copyin+0x74>
    80001804:	4501                	li	a0,0
}
    80001806:	8082                	ret
      return -1;
    80001808:	557d                	li	a0,-1
}
    8000180a:	60a6                	ld	ra,72(sp)
    8000180c:	6406                	ld	s0,64(sp)
    8000180e:	74e2                	ld	s1,56(sp)
    80001810:	7942                	ld	s2,48(sp)
    80001812:	79a2                	ld	s3,40(sp)
    80001814:	7a02                	ld	s4,32(sp)
    80001816:	6ae2                	ld	s5,24(sp)
    80001818:	6b42                	ld	s6,16(sp)
    8000181a:	6ba2                	ld	s7,8(sp)
    8000181c:	6c02                	ld	s8,0(sp)
    8000181e:	6161                	addi	sp,sp,80
    80001820:	8082                	ret

0000000080001822 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001822:	c6c5                	beqz	a3,800018ca <copyinstr+0xa8>
{
    80001824:	715d                	addi	sp,sp,-80
    80001826:	e486                	sd	ra,72(sp)
    80001828:	e0a2                	sd	s0,64(sp)
    8000182a:	fc26                	sd	s1,56(sp)
    8000182c:	f84a                	sd	s2,48(sp)
    8000182e:	f44e                	sd	s3,40(sp)
    80001830:	f052                	sd	s4,32(sp)
    80001832:	ec56                	sd	s5,24(sp)
    80001834:	e85a                	sd	s6,16(sp)
    80001836:	e45e                	sd	s7,8(sp)
    80001838:	0880                	addi	s0,sp,80
    8000183a:	8a2a                	mv	s4,a0
    8000183c:	8b2e                	mv	s6,a1
    8000183e:	8bb2                	mv	s7,a2
    80001840:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001842:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001844:	6985                	lui	s3,0x1
    80001846:	a035                	j	80001872 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001848:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    8000184c:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000184e:	0017b793          	seqz	a5,a5
    80001852:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001856:	60a6                	ld	ra,72(sp)
    80001858:	6406                	ld	s0,64(sp)
    8000185a:	74e2                	ld	s1,56(sp)
    8000185c:	7942                	ld	s2,48(sp)
    8000185e:	79a2                	ld	s3,40(sp)
    80001860:	7a02                	ld	s4,32(sp)
    80001862:	6ae2                	ld	s5,24(sp)
    80001864:	6b42                	ld	s6,16(sp)
    80001866:	6ba2                	ld	s7,8(sp)
    80001868:	6161                	addi	sp,sp,80
    8000186a:	8082                	ret
    srcva = va0 + PGSIZE;
    8000186c:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001870:	c8a9                	beqz	s1,800018c2 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001872:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001876:	85ca                	mv	a1,s2
    80001878:	8552                	mv	a0,s4
    8000187a:	00000097          	auipc	ra,0x0
    8000187e:	8ea080e7          	jalr	-1814(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    80001882:	c131                	beqz	a0,800018c6 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001884:	41790833          	sub	a6,s2,s7
    80001888:	984e                	add	a6,a6,s3
    if(n > max)
    8000188a:	0104f363          	bgeu	s1,a6,80001890 <copyinstr+0x6e>
    8000188e:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001890:	955e                	add	a0,a0,s7
    80001892:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001896:	fc080be3          	beqz	a6,8000186c <copyinstr+0x4a>
    8000189a:	985a                	add	a6,a6,s6
    8000189c:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000189e:	41650633          	sub	a2,a0,s6
    800018a2:	14fd                	addi	s1,s1,-1
    800018a4:	9b26                	add	s6,s6,s1
    800018a6:	00f60733          	add	a4,a2,a5
    800018aa:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    800018ae:	df49                	beqz	a4,80001848 <copyinstr+0x26>
        *dst = *p;
    800018b0:	00e78023          	sb	a4,0(a5)
      --max;
    800018b4:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018b8:	0785                	addi	a5,a5,1
    while(n > 0){
    800018ba:	ff0796e3          	bne	a5,a6,800018a6 <copyinstr+0x84>
      dst++;
    800018be:	8b42                	mv	s6,a6
    800018c0:	b775                	j	8000186c <copyinstr+0x4a>
    800018c2:	4781                	li	a5,0
    800018c4:	b769                	j	8000184e <copyinstr+0x2c>
      return -1;
    800018c6:	557d                	li	a0,-1
    800018c8:	b779                	j	80001856 <copyinstr+0x34>
  int got_null = 0;
    800018ca:	4781                	li	a5,0
  if(got_null){
    800018cc:	0017b793          	seqz	a5,a5
    800018d0:	40f00533          	neg	a0,a5
}
    800018d4:	8082                	ret

00000000800018d6 <pagefault_handler>:
pagefault_handler(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  char *old_pa, *new_pa;

  if(va >= MAXVA)
    800018d6:	57fd                	li	a5,-1
    800018d8:	83e9                	srli	a5,a5,0x1a
    800018da:	08b7ea63          	bltu	a5,a1,8000196e <pagefault_handler+0x98>
{
    800018de:	7179                	addi	sp,sp,-48
    800018e0:	f406                	sd	ra,40(sp)
    800018e2:	f022                	sd	s0,32(sp)
    800018e4:	ec26                	sd	s1,24(sp)
    800018e6:	e84a                	sd	s2,16(sp)
    800018e8:	e44e                	sd	s3,8(sp)
    800018ea:	1800                	addi	s0,sp,48
    return -1;
  if ((pte = walk(pagetable, va, 0)) == 0)
    800018ec:	4601                	li	a2,0
    800018ee:	fffff097          	auipc	ra,0xfffff
    800018f2:	7d0080e7          	jalr	2000(ra) # 800010be <walk>
    800018f6:	84aa                	mv	s1,a0
    800018f8:	cd2d                	beqz	a0,80001972 <pagefault_handler+0x9c>
    return -1;
  if (!(*pte & PTE_V) || !(*pte & PTE_U))
    800018fa:	00053903          	ld	s2,0(a0)
    800018fe:	01197713          	andi	a4,s2,17
    80001902:	47c5                	li	a5,17
    return -1;
    80001904:	557d                	li	a0,-1
  if (!(*pte & PTE_V) || !(*pte & PTE_U))
    80001906:	00f71863          	bne	a4,a5,80001916 <pagefault_handler+0x40>
  if (!(*pte & PTE_W) && (*pte & PTE_RSW))
    8000190a:	10497793          	andi	a5,s2,260
    8000190e:	10000713          	li	a4,256
    80001912:	00e78963          	beq	a5,a4,80001924 <pagefault_handler+0x4e>
    *pte = *pte & (~PTE_RSW);
    *pte = *pte | (PTE_W);
    return 0;
  }
  return -1;
    80001916:	70a2                	ld	ra,40(sp)
    80001918:	7402                	ld	s0,32(sp)
    8000191a:	64e2                	ld	s1,24(sp)
    8000191c:	6942                	ld	s2,16(sp)
    8000191e:	69a2                	ld	s3,8(sp)
    80001920:	6145                	addi	sp,sp,48
    80001922:	8082                	ret
    new_pa = kalloc();
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	254080e7          	jalr	596(ra) # 80000b78 <kalloc>
    8000192c:	89aa                	mv	s3,a0
      return -1;
    8000192e:	557d                	li	a0,-1
    if (new_pa == 0)
    80001930:	fe0983e3          	beqz	s3,80001916 <pagefault_handler+0x40>
    old_pa = (char *)PTE2PA(*pte);
    80001934:	00a95913          	srli	s2,s2,0xa
    80001938:	0932                	slli	s2,s2,0xc
    memmove(new_pa, old_pa, PGSIZE);
    8000193a:	6605                	lui	a2,0x1
    8000193c:	85ca                	mv	a1,s2
    8000193e:	854e                	mv	a0,s3
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	4f2080e7          	jalr	1266(ra) # 80000e32 <memmove>
    kfree(old_pa);
    80001948:	854a                	mv	a0,s2
    8000194a:	fffff097          	auipc	ra,0xfffff
    8000194e:	0da080e7          	jalr	218(ra) # 80000a24 <kfree>
    *pte = PA2PTE(new_pa) | PTE_FLAGS(*pte);
    80001952:	00c9d993          	srli	s3,s3,0xc
    80001956:	09aa                	slli	s3,s3,0xa
    80001958:	609c                	ld	a5,0(s1)
    8000195a:	2ff7f793          	andi	a5,a5,767
    *pte = *pte & (~PTE_RSW);
    8000195e:	0137e9b3          	or	s3,a5,s3
    *pte = *pte | (PTE_W);
    80001962:	0049e993          	ori	s3,s3,4
    80001966:	0134b023          	sd	s3,0(s1)
    return 0;
    8000196a:	4501                	li	a0,0
    8000196c:	b76d                	j	80001916 <pagefault_handler+0x40>
    return -1;
    8000196e:	557d                	li	a0,-1
    80001970:	8082                	ret
    return -1;
    80001972:	557d                	li	a0,-1
    80001974:	b74d                	j	80001916 <pagefault_handler+0x40>

0000000080001976 <copyout>:
  while(len > 0){
    80001976:	c6c5                	beqz	a3,80001a1e <copyout+0xa8>
{
    80001978:	711d                	addi	sp,sp,-96
    8000197a:	ec86                	sd	ra,88(sp)
    8000197c:	e8a2                	sd	s0,80(sp)
    8000197e:	e4a6                	sd	s1,72(sp)
    80001980:	e0ca                	sd	s2,64(sp)
    80001982:	fc4e                	sd	s3,56(sp)
    80001984:	f852                	sd	s4,48(sp)
    80001986:	f456                	sd	s5,40(sp)
    80001988:	f05a                	sd	s6,32(sp)
    8000198a:	ec5e                	sd	s7,24(sp)
    8000198c:	e862                	sd	s8,16(sp)
    8000198e:	e466                	sd	s9,8(sp)
    80001990:	e06a                	sd	s10,0(sp)
    80001992:	1080                	addi	s0,sp,96
    80001994:	8b2a                	mv	s6,a0
    80001996:	8a2e                	mv	s4,a1
    80001998:	8ab2                	mv	s5,a2
    8000199a:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000199c:	74fd                	lui	s1,0xfffff
    8000199e:	8ced                	and	s1,s1,a1
    if (va0 >= MAXVA)
    800019a0:	57fd                	li	a5,-1
    800019a2:	83e9                	srli	a5,a5,0x1a
    800019a4:	0697ef63          	bltu	a5,s1,80001a22 <copyout+0xac>
    if (!(*pte & PTE_V) || !(*pte & PTE_U) || !(*pte & PTE_W))
    800019a8:	4c55                	li	s8,21
    800019aa:	6c85                	lui	s9,0x1
    if (va0 >= MAXVA)
    800019ac:	8bbe                	mv	s7,a5
    800019ae:	a81d                	j	800019e4 <copyout+0x6e>
      if (pagefault_handler(pagetable, va0) < 0)
    800019b0:	85a6                	mv	a1,s1
    800019b2:	855a                	mv	a0,s6
    800019b4:	00000097          	auipc	ra,0x0
    800019b8:	f22080e7          	jalr	-222(ra) # 800018d6 <pagefault_handler>
    800019bc:	a081                	j	800019fc <copyout+0x86>
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800019be:	409a04b3          	sub	s1,s4,s1
    800019c2:	0009061b          	sext.w	a2,s2
    800019c6:	85d6                	mv	a1,s5
    800019c8:	9526                	add	a0,a0,s1
    800019ca:	fffff097          	auipc	ra,0xfffff
    800019ce:	468080e7          	jalr	1128(ra) # 80000e32 <memmove>
    len -= n;
    800019d2:	412989b3          	sub	s3,s3,s2
    src += n;
    800019d6:	9aca                	add	s5,s5,s2
  while(len > 0){
    800019d8:	04098163          	beqz	s3,80001a1a <copyout+0xa4>
    if (va0 >= MAXVA)
    800019dc:	05abe563          	bltu	s7,s10,80001a26 <copyout+0xb0>
    va0 = PGROUNDDOWN(dstva);
    800019e0:	84ea                	mv	s1,s10
    dstva = va0 + PGSIZE;
    800019e2:	8a6a                	mv	s4,s10
    pte = walk(pagetable, va0, 0);
    800019e4:	4601                	li	a2,0
    800019e6:	85a6                	mv	a1,s1
    800019e8:	855a                	mv	a0,s6
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	6d4080e7          	jalr	1748(ra) # 800010be <walk>
    if (pte == 0)
    800019f2:	cd05                	beqz	a0,80001a2a <copyout+0xb4>
    if (!(*pte & PTE_V) || !(*pte & PTE_U) || !(*pte & PTE_W))
    800019f4:	611c                	ld	a5,0(a0)
    800019f6:	8bd5                	andi	a5,a5,21
    800019f8:	fb879ce3          	bne	a5,s8,800019b0 <copyout+0x3a>
    pa0 = walkaddr(pagetable, va0);
    800019fc:	85a6                	mv	a1,s1
    800019fe:	855a                	mv	a0,s6
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	764080e7          	jalr	1892(ra) # 80001164 <walkaddr>
    if(pa0 == 0)
    80001a08:	c121                	beqz	a0,80001a48 <copyout+0xd2>
    n = PGSIZE - (dstva - va0);
    80001a0a:	01948d33          	add	s10,s1,s9
    80001a0e:	414d0933          	sub	s2,s10,s4
    if(n > len)
    80001a12:	fb29f6e3          	bgeu	s3,s2,800019be <copyout+0x48>
    80001a16:	894e                	mv	s2,s3
    80001a18:	b75d                	j	800019be <copyout+0x48>
  return 0;
    80001a1a:	4501                	li	a0,0
    80001a1c:	a801                	j	80001a2c <copyout+0xb6>
    80001a1e:	4501                	li	a0,0
}
    80001a20:	8082                	ret
      return -1;
    80001a22:	557d                	li	a0,-1
    80001a24:	a021                	j	80001a2c <copyout+0xb6>
    80001a26:	557d                	li	a0,-1
    80001a28:	a011                	j	80001a2c <copyout+0xb6>
      return -1;
    80001a2a:	557d                	li	a0,-1
}
    80001a2c:	60e6                	ld	ra,88(sp)
    80001a2e:	6446                	ld	s0,80(sp)
    80001a30:	64a6                	ld	s1,72(sp)
    80001a32:	6906                	ld	s2,64(sp)
    80001a34:	79e2                	ld	s3,56(sp)
    80001a36:	7a42                	ld	s4,48(sp)
    80001a38:	7aa2                	ld	s5,40(sp)
    80001a3a:	7b02                	ld	s6,32(sp)
    80001a3c:	6be2                	ld	s7,24(sp)
    80001a3e:	6c42                	ld	s8,16(sp)
    80001a40:	6ca2                	ld	s9,8(sp)
    80001a42:	6d02                	ld	s10,0(sp)
    80001a44:	6125                	addi	sp,sp,96
    80001a46:	8082                	ret
      return -1;
    80001a48:	557d                	li	a0,-1
    80001a4a:	b7cd                	j	80001a2c <copyout+0xb6>

0000000080001a4c <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001a4c:	1101                	addi	sp,sp,-32
    80001a4e:	ec06                	sd	ra,24(sp)
    80001a50:	e822                	sd	s0,16(sp)
    80001a52:	e426                	sd	s1,8(sp)
    80001a54:	1000                	addi	s0,sp,32
    80001a56:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001a58:	fffff097          	auipc	ra,0xfffff
    80001a5c:	204080e7          	jalr	516(ra) # 80000c5c <holding>
    80001a60:	c909                	beqz	a0,80001a72 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001a62:	749c                	ld	a5,40(s1)
    80001a64:	00978f63          	beq	a5,s1,80001a82 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a68:	60e2                	ld	ra,24(sp)
    80001a6a:	6442                	ld	s0,16(sp)
    80001a6c:	64a2                	ld	s1,8(sp)
    80001a6e:	6105                	addi	sp,sp,32
    80001a70:	8082                	ret
    panic("wakeup1");
    80001a72:	00006517          	auipc	a0,0x6
    80001a76:	75650513          	addi	a0,a0,1878 # 800081c8 <digits+0x188>
    80001a7a:	fffff097          	auipc	ra,0xfffff
    80001a7e:	ace080e7          	jalr	-1330(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a82:	4c98                	lw	a4,24(s1)
    80001a84:	4785                	li	a5,1
    80001a86:	fef711e3          	bne	a4,a5,80001a68 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a8a:	4789                	li	a5,2
    80001a8c:	cc9c                	sw	a5,24(s1)
}
    80001a8e:	bfe9                	j	80001a68 <wakeup1+0x1c>

0000000080001a90 <procinit>:
{
    80001a90:	715d                	addi	sp,sp,-80
    80001a92:	e486                	sd	ra,72(sp)
    80001a94:	e0a2                	sd	s0,64(sp)
    80001a96:	fc26                	sd	s1,56(sp)
    80001a98:	f84a                	sd	s2,48(sp)
    80001a9a:	f44e                	sd	s3,40(sp)
    80001a9c:	f052                	sd	s4,32(sp)
    80001a9e:	ec56                	sd	s5,24(sp)
    80001aa0:	e85a                	sd	s6,16(sp)
    80001aa2:	e45e                	sd	s7,8(sp)
    80001aa4:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001aa6:	00006597          	auipc	a1,0x6
    80001aaa:	72a58593          	addi	a1,a1,1834 # 800081d0 <digits+0x190>
    80001aae:	00010517          	auipc	a0,0x10
    80001ab2:	eaa50513          	addi	a0,a0,-342 # 80011958 <pid_lock>
    80001ab6:	fffff097          	auipc	ra,0xfffff
    80001aba:	190080e7          	jalr	400(ra) # 80000c46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001abe:	00010917          	auipc	s2,0x10
    80001ac2:	2b290913          	addi	s2,s2,690 # 80011d70 <proc>
      initlock(&p->lock, "proc");
    80001ac6:	00006b97          	auipc	s7,0x6
    80001aca:	712b8b93          	addi	s7,s7,1810 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001ace:	8b4a                	mv	s6,s2
    80001ad0:	00006a97          	auipc	s5,0x6
    80001ad4:	530a8a93          	addi	s5,s5,1328 # 80008000 <etext>
    80001ad8:	040009b7          	lui	s3,0x4000
    80001adc:	19fd                	addi	s3,s3,-1
    80001ade:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ae0:	00016a17          	auipc	s4,0x16
    80001ae4:	c90a0a13          	addi	s4,s4,-880 # 80017770 <tickslock>
      initlock(&p->lock, "proc");
    80001ae8:	85de                	mv	a1,s7
    80001aea:	854a                	mv	a0,s2
    80001aec:	fffff097          	auipc	ra,0xfffff
    80001af0:	15a080e7          	jalr	346(ra) # 80000c46 <initlock>
      char *pa = kalloc();
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	084080e7          	jalr	132(ra) # 80000b78 <kalloc>
    80001afc:	85aa                	mv	a1,a0
      if(pa == 0)
    80001afe:	c929                	beqz	a0,80001b50 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001b00:	416904b3          	sub	s1,s2,s6
    80001b04:	848d                	srai	s1,s1,0x3
    80001b06:	000ab783          	ld	a5,0(s5)
    80001b0a:	02f484b3          	mul	s1,s1,a5
    80001b0e:	2485                	addiw	s1,s1,1
    80001b10:	00d4949b          	slliw	s1,s1,0xd
    80001b14:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b18:	4699                	li	a3,6
    80001b1a:	6605                	lui	a2,0x1
    80001b1c:	8526                	mv	a0,s1
    80001b1e:	fffff097          	auipc	ra,0xfffff
    80001b22:	774080e7          	jalr	1908(ra) # 80001292 <kvmmap>
      p->kstack = va;
    80001b26:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b2a:	16890913          	addi	s2,s2,360
    80001b2e:	fb491de3          	bne	s2,s4,80001ae8 <procinit+0x58>
  kvminithart();
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	568080e7          	jalr	1384(ra) # 8000109a <kvminithart>
}
    80001b3a:	60a6                	ld	ra,72(sp)
    80001b3c:	6406                	ld	s0,64(sp)
    80001b3e:	74e2                	ld	s1,56(sp)
    80001b40:	7942                	ld	s2,48(sp)
    80001b42:	79a2                	ld	s3,40(sp)
    80001b44:	7a02                	ld	s4,32(sp)
    80001b46:	6ae2                	ld	s5,24(sp)
    80001b48:	6b42                	ld	s6,16(sp)
    80001b4a:	6ba2                	ld	s7,8(sp)
    80001b4c:	6161                	addi	sp,sp,80
    80001b4e:	8082                	ret
        panic("kalloc");
    80001b50:	00006517          	auipc	a0,0x6
    80001b54:	69050513          	addi	a0,a0,1680 # 800081e0 <digits+0x1a0>
    80001b58:	fffff097          	auipc	ra,0xfffff
    80001b5c:	9f0080e7          	jalr	-1552(ra) # 80000548 <panic>

0000000080001b60 <cpuid>:
{
    80001b60:	1141                	addi	sp,sp,-16
    80001b62:	e422                	sd	s0,8(sp)
    80001b64:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b66:	8512                	mv	a0,tp
}
    80001b68:	2501                	sext.w	a0,a0
    80001b6a:	6422                	ld	s0,8(sp)
    80001b6c:	0141                	addi	sp,sp,16
    80001b6e:	8082                	ret

0000000080001b70 <mycpu>:
mycpu(void) {
    80001b70:	1141                	addi	sp,sp,-16
    80001b72:	e422                	sd	s0,8(sp)
    80001b74:	0800                	addi	s0,sp,16
    80001b76:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b78:	2781                	sext.w	a5,a5
    80001b7a:	079e                	slli	a5,a5,0x7
}
    80001b7c:	00010517          	auipc	a0,0x10
    80001b80:	df450513          	addi	a0,a0,-524 # 80011970 <cpus>
    80001b84:	953e                	add	a0,a0,a5
    80001b86:	6422                	ld	s0,8(sp)
    80001b88:	0141                	addi	sp,sp,16
    80001b8a:	8082                	ret

0000000080001b8c <myproc>:
myproc(void) {
    80001b8c:	1101                	addi	sp,sp,-32
    80001b8e:	ec06                	sd	ra,24(sp)
    80001b90:	e822                	sd	s0,16(sp)
    80001b92:	e426                	sd	s1,8(sp)
    80001b94:	1000                	addi	s0,sp,32
  push_off();
    80001b96:	fffff097          	auipc	ra,0xfffff
    80001b9a:	0f4080e7          	jalr	244(ra) # 80000c8a <push_off>
    80001b9e:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001ba0:	2781                	sext.w	a5,a5
    80001ba2:	079e                	slli	a5,a5,0x7
    80001ba4:	00010717          	auipc	a4,0x10
    80001ba8:	db470713          	addi	a4,a4,-588 # 80011958 <pid_lock>
    80001bac:	97ba                	add	a5,a5,a4
    80001bae:	6f84                	ld	s1,24(a5)
  pop_off();
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	17a080e7          	jalr	378(ra) # 80000d2a <pop_off>
}
    80001bb8:	8526                	mv	a0,s1
    80001bba:	60e2                	ld	ra,24(sp)
    80001bbc:	6442                	ld	s0,16(sp)
    80001bbe:	64a2                	ld	s1,8(sp)
    80001bc0:	6105                	addi	sp,sp,32
    80001bc2:	8082                	ret

0000000080001bc4 <forkret>:
{
    80001bc4:	1141                	addi	sp,sp,-16
    80001bc6:	e406                	sd	ra,8(sp)
    80001bc8:	e022                	sd	s0,0(sp)
    80001bca:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001bcc:	00000097          	auipc	ra,0x0
    80001bd0:	fc0080e7          	jalr	-64(ra) # 80001b8c <myproc>
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	1b6080e7          	jalr	438(ra) # 80000d8a <release>
  if (first) {
    80001bdc:	00007797          	auipc	a5,0x7
    80001be0:	c347a783          	lw	a5,-972(a5) # 80008810 <first.1671>
    80001be4:	eb89                	bnez	a5,80001bf6 <forkret+0x32>
  usertrapret();
    80001be6:	00001097          	auipc	ra,0x1
    80001bea:	c1c080e7          	jalr	-996(ra) # 80002802 <usertrapret>
}
    80001bee:	60a2                	ld	ra,8(sp)
    80001bf0:	6402                	ld	s0,0(sp)
    80001bf2:	0141                	addi	sp,sp,16
    80001bf4:	8082                	ret
    first = 0;
    80001bf6:	00007797          	auipc	a5,0x7
    80001bfa:	c007ad23          	sw	zero,-998(a5) # 80008810 <first.1671>
    fsinit(ROOTDEV);
    80001bfe:	4505                	li	a0,1
    80001c00:	00002097          	auipc	ra,0x2
    80001c04:	9aa080e7          	jalr	-1622(ra) # 800035aa <fsinit>
    80001c08:	bff9                	j	80001be6 <forkret+0x22>

0000000080001c0a <allocpid>:
allocpid() {
    80001c0a:	1101                	addi	sp,sp,-32
    80001c0c:	ec06                	sd	ra,24(sp)
    80001c0e:	e822                	sd	s0,16(sp)
    80001c10:	e426                	sd	s1,8(sp)
    80001c12:	e04a                	sd	s2,0(sp)
    80001c14:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c16:	00010917          	auipc	s2,0x10
    80001c1a:	d4290913          	addi	s2,s2,-702 # 80011958 <pid_lock>
    80001c1e:	854a                	mv	a0,s2
    80001c20:	fffff097          	auipc	ra,0xfffff
    80001c24:	0b6080e7          	jalr	182(ra) # 80000cd6 <acquire>
  pid = nextpid;
    80001c28:	00007797          	auipc	a5,0x7
    80001c2c:	bec78793          	addi	a5,a5,-1044 # 80008814 <nextpid>
    80001c30:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c32:	0014871b          	addiw	a4,s1,1
    80001c36:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c38:	854a                	mv	a0,s2
    80001c3a:	fffff097          	auipc	ra,0xfffff
    80001c3e:	150080e7          	jalr	336(ra) # 80000d8a <release>
}
    80001c42:	8526                	mv	a0,s1
    80001c44:	60e2                	ld	ra,24(sp)
    80001c46:	6442                	ld	s0,16(sp)
    80001c48:	64a2                	ld	s1,8(sp)
    80001c4a:	6902                	ld	s2,0(sp)
    80001c4c:	6105                	addi	sp,sp,32
    80001c4e:	8082                	ret

0000000080001c50 <proc_pagetable>:
{
    80001c50:	1101                	addi	sp,sp,-32
    80001c52:	ec06                	sd	ra,24(sp)
    80001c54:	e822                	sd	s0,16(sp)
    80001c56:	e426                	sd	s1,8(sp)
    80001c58:	e04a                	sd	s2,0(sp)
    80001c5a:	1000                	addi	s0,sp,32
    80001c5c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c5e:	00000097          	auipc	ra,0x0
    80001c62:	802080e7          	jalr	-2046(ra) # 80001460 <uvmcreate>
    80001c66:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c68:	c121                	beqz	a0,80001ca8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c6a:	4729                	li	a4,10
    80001c6c:	00005697          	auipc	a3,0x5
    80001c70:	39468693          	addi	a3,a3,916 # 80007000 <_trampoline>
    80001c74:	6605                	lui	a2,0x1
    80001c76:	040005b7          	lui	a1,0x4000
    80001c7a:	15fd                	addi	a1,a1,-1
    80001c7c:	05b2                	slli	a1,a1,0xc
    80001c7e:	fffff097          	auipc	ra,0xfffff
    80001c82:	586080e7          	jalr	1414(ra) # 80001204 <mappages>
    80001c86:	02054863          	bltz	a0,80001cb6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c8a:	4719                	li	a4,6
    80001c8c:	05893683          	ld	a3,88(s2)
    80001c90:	6605                	lui	a2,0x1
    80001c92:	020005b7          	lui	a1,0x2000
    80001c96:	15fd                	addi	a1,a1,-1
    80001c98:	05b6                	slli	a1,a1,0xd
    80001c9a:	8526                	mv	a0,s1
    80001c9c:	fffff097          	auipc	ra,0xfffff
    80001ca0:	568080e7          	jalr	1384(ra) # 80001204 <mappages>
    80001ca4:	02054163          	bltz	a0,80001cc6 <proc_pagetable+0x76>
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret
    uvmfree(pagetable, 0);
    80001cb6:	4581                	li	a1,0
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	9a2080e7          	jalr	-1630(ra) # 8000165c <uvmfree>
    return 0;
    80001cc2:	4481                	li	s1,0
    80001cc4:	b7d5                	j	80001ca8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cc6:	4681                	li	a3,0
    80001cc8:	4605                	li	a2,1
    80001cca:	040005b7          	lui	a1,0x4000
    80001cce:	15fd                	addi	a1,a1,-1
    80001cd0:	05b2                	slli	a1,a1,0xc
    80001cd2:	8526                	mv	a0,s1
    80001cd4:	fffff097          	auipc	ra,0xfffff
    80001cd8:	6c8080e7          	jalr	1736(ra) # 8000139c <uvmunmap>
    uvmfree(pagetable, 0);
    80001cdc:	4581                	li	a1,0
    80001cde:	8526                	mv	a0,s1
    80001ce0:	00000097          	auipc	ra,0x0
    80001ce4:	97c080e7          	jalr	-1668(ra) # 8000165c <uvmfree>
    return 0;
    80001ce8:	4481                	li	s1,0
    80001cea:	bf7d                	j	80001ca8 <proc_pagetable+0x58>

0000000080001cec <proc_freepagetable>:
{
    80001cec:	1101                	addi	sp,sp,-32
    80001cee:	ec06                	sd	ra,24(sp)
    80001cf0:	e822                	sd	s0,16(sp)
    80001cf2:	e426                	sd	s1,8(sp)
    80001cf4:	e04a                	sd	s2,0(sp)
    80001cf6:	1000                	addi	s0,sp,32
    80001cf8:	84aa                	mv	s1,a0
    80001cfa:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cfc:	4681                	li	a3,0
    80001cfe:	4605                	li	a2,1
    80001d00:	040005b7          	lui	a1,0x4000
    80001d04:	15fd                	addi	a1,a1,-1
    80001d06:	05b2                	slli	a1,a1,0xc
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	694080e7          	jalr	1684(ra) # 8000139c <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d10:	4681                	li	a3,0
    80001d12:	4605                	li	a2,1
    80001d14:	020005b7          	lui	a1,0x2000
    80001d18:	15fd                	addi	a1,a1,-1
    80001d1a:	05b6                	slli	a1,a1,0xd
    80001d1c:	8526                	mv	a0,s1
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	67e080e7          	jalr	1662(ra) # 8000139c <uvmunmap>
  uvmfree(pagetable, sz);
    80001d26:	85ca                	mv	a1,s2
    80001d28:	8526                	mv	a0,s1
    80001d2a:	00000097          	auipc	ra,0x0
    80001d2e:	932080e7          	jalr	-1742(ra) # 8000165c <uvmfree>
}
    80001d32:	60e2                	ld	ra,24(sp)
    80001d34:	6442                	ld	s0,16(sp)
    80001d36:	64a2                	ld	s1,8(sp)
    80001d38:	6902                	ld	s2,0(sp)
    80001d3a:	6105                	addi	sp,sp,32
    80001d3c:	8082                	ret

0000000080001d3e <freeproc>:
{
    80001d3e:	1101                	addi	sp,sp,-32
    80001d40:	ec06                	sd	ra,24(sp)
    80001d42:	e822                	sd	s0,16(sp)
    80001d44:	e426                	sd	s1,8(sp)
    80001d46:	1000                	addi	s0,sp,32
    80001d48:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d4a:	6d28                	ld	a0,88(a0)
    80001d4c:	c509                	beqz	a0,80001d56 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	cd6080e7          	jalr	-810(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001d56:	0404bc23          	sd	zero,88(s1) # fffffffffffff058 <end+0xffffffff7ffd9058>
  if(p->pagetable)
    80001d5a:	68a8                	ld	a0,80(s1)
    80001d5c:	c511                	beqz	a0,80001d68 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d5e:	64ac                	ld	a1,72(s1)
    80001d60:	00000097          	auipc	ra,0x0
    80001d64:	f8c080e7          	jalr	-116(ra) # 80001cec <proc_freepagetable>
  p->pagetable = 0;
    80001d68:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d6c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d70:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d74:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d78:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d7c:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d80:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d84:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d88:	0004ac23          	sw	zero,24(s1)
}
    80001d8c:	60e2                	ld	ra,24(sp)
    80001d8e:	6442                	ld	s0,16(sp)
    80001d90:	64a2                	ld	s1,8(sp)
    80001d92:	6105                	addi	sp,sp,32
    80001d94:	8082                	ret

0000000080001d96 <allocproc>:
{
    80001d96:	1101                	addi	sp,sp,-32
    80001d98:	ec06                	sd	ra,24(sp)
    80001d9a:	e822                	sd	s0,16(sp)
    80001d9c:	e426                	sd	s1,8(sp)
    80001d9e:	e04a                	sd	s2,0(sp)
    80001da0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001da2:	00010497          	auipc	s1,0x10
    80001da6:	fce48493          	addi	s1,s1,-50 # 80011d70 <proc>
    80001daa:	00016917          	auipc	s2,0x16
    80001dae:	9c690913          	addi	s2,s2,-1594 # 80017770 <tickslock>
    acquire(&p->lock);
    80001db2:	8526                	mv	a0,s1
    80001db4:	fffff097          	auipc	ra,0xfffff
    80001db8:	f22080e7          	jalr	-222(ra) # 80000cd6 <acquire>
    if(p->state == UNUSED) {
    80001dbc:	4c9c                	lw	a5,24(s1)
    80001dbe:	cf81                	beqz	a5,80001dd6 <allocproc+0x40>
      release(&p->lock);
    80001dc0:	8526                	mv	a0,s1
    80001dc2:	fffff097          	auipc	ra,0xfffff
    80001dc6:	fc8080e7          	jalr	-56(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001dca:	16848493          	addi	s1,s1,360
    80001dce:	ff2492e3          	bne	s1,s2,80001db2 <allocproc+0x1c>
  return 0;
    80001dd2:	4481                	li	s1,0
    80001dd4:	a0b9                	j	80001e22 <allocproc+0x8c>
  p->pid = allocpid();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	e34080e7          	jalr	-460(ra) # 80001c0a <allocpid>
    80001dde:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001de0:	fffff097          	auipc	ra,0xfffff
    80001de4:	d98080e7          	jalr	-616(ra) # 80000b78 <kalloc>
    80001de8:	892a                	mv	s2,a0
    80001dea:	eca8                	sd	a0,88(s1)
    80001dec:	c131                	beqz	a0,80001e30 <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001dee:	8526                	mv	a0,s1
    80001df0:	00000097          	auipc	ra,0x0
    80001df4:	e60080e7          	jalr	-416(ra) # 80001c50 <proc_pagetable>
    80001df8:	892a                	mv	s2,a0
    80001dfa:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001dfc:	c129                	beqz	a0,80001e3e <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001dfe:	07000613          	li	a2,112
    80001e02:	4581                	li	a1,0
    80001e04:	06048513          	addi	a0,s1,96
    80001e08:	fffff097          	auipc	ra,0xfffff
    80001e0c:	fca080e7          	jalr	-54(ra) # 80000dd2 <memset>
  p->context.ra = (uint64)forkret;
    80001e10:	00000797          	auipc	a5,0x0
    80001e14:	db478793          	addi	a5,a5,-588 # 80001bc4 <forkret>
    80001e18:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001e1a:	60bc                	ld	a5,64(s1)
    80001e1c:	6705                	lui	a4,0x1
    80001e1e:	97ba                	add	a5,a5,a4
    80001e20:	f4bc                	sd	a5,104(s1)
}
    80001e22:	8526                	mv	a0,s1
    80001e24:	60e2                	ld	ra,24(sp)
    80001e26:	6442                	ld	s0,16(sp)
    80001e28:	64a2                	ld	s1,8(sp)
    80001e2a:	6902                	ld	s2,0(sp)
    80001e2c:	6105                	addi	sp,sp,32
    80001e2e:	8082                	ret
    release(&p->lock);
    80001e30:	8526                	mv	a0,s1
    80001e32:	fffff097          	auipc	ra,0xfffff
    80001e36:	f58080e7          	jalr	-168(ra) # 80000d8a <release>
    return 0;
    80001e3a:	84ca                	mv	s1,s2
    80001e3c:	b7dd                	j	80001e22 <allocproc+0x8c>
    freeproc(p);
    80001e3e:	8526                	mv	a0,s1
    80001e40:	00000097          	auipc	ra,0x0
    80001e44:	efe080e7          	jalr	-258(ra) # 80001d3e <freeproc>
    release(&p->lock);
    80001e48:	8526                	mv	a0,s1
    80001e4a:	fffff097          	auipc	ra,0xfffff
    80001e4e:	f40080e7          	jalr	-192(ra) # 80000d8a <release>
    return 0;
    80001e52:	84ca                	mv	s1,s2
    80001e54:	b7f9                	j	80001e22 <allocproc+0x8c>

0000000080001e56 <userinit>:
{
    80001e56:	1101                	addi	sp,sp,-32
    80001e58:	ec06                	sd	ra,24(sp)
    80001e5a:	e822                	sd	s0,16(sp)
    80001e5c:	e426                	sd	s1,8(sp)
    80001e5e:	1000                	addi	s0,sp,32
  p = allocproc();
    80001e60:	00000097          	auipc	ra,0x0
    80001e64:	f36080e7          	jalr	-202(ra) # 80001d96 <allocproc>
    80001e68:	84aa                	mv	s1,a0
  initproc = p;
    80001e6a:	00007797          	auipc	a5,0x7
    80001e6e:	1aa7b723          	sd	a0,430(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e72:	03400613          	li	a2,52
    80001e76:	00007597          	auipc	a1,0x7
    80001e7a:	9aa58593          	addi	a1,a1,-1622 # 80008820 <initcode>
    80001e7e:	6928                	ld	a0,80(a0)
    80001e80:	fffff097          	auipc	ra,0xfffff
    80001e84:	60e080e7          	jalr	1550(ra) # 8000148e <uvminit>
  p->sz = PGSIZE;
    80001e88:	6785                	lui	a5,0x1
    80001e8a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e8c:	6cb8                	ld	a4,88(s1)
    80001e8e:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e92:	6cb8                	ld	a4,88(s1)
    80001e94:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e96:	4641                	li	a2,16
    80001e98:	00006597          	auipc	a1,0x6
    80001e9c:	35058593          	addi	a1,a1,848 # 800081e8 <digits+0x1a8>
    80001ea0:	15848513          	addi	a0,s1,344
    80001ea4:	fffff097          	auipc	ra,0xfffff
    80001ea8:	084080e7          	jalr	132(ra) # 80000f28 <safestrcpy>
  p->cwd = namei("/");
    80001eac:	00006517          	auipc	a0,0x6
    80001eb0:	34c50513          	addi	a0,a0,844 # 800081f8 <digits+0x1b8>
    80001eb4:	00002097          	auipc	ra,0x2
    80001eb8:	122080e7          	jalr	290(ra) # 80003fd6 <namei>
    80001ebc:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001ec0:	4789                	li	a5,2
    80001ec2:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	fffff097          	auipc	ra,0xfffff
    80001eca:	ec4080e7          	jalr	-316(ra) # 80000d8a <release>
}
    80001ece:	60e2                	ld	ra,24(sp)
    80001ed0:	6442                	ld	s0,16(sp)
    80001ed2:	64a2                	ld	s1,8(sp)
    80001ed4:	6105                	addi	sp,sp,32
    80001ed6:	8082                	ret

0000000080001ed8 <growproc>:
{
    80001ed8:	1101                	addi	sp,sp,-32
    80001eda:	ec06                	sd	ra,24(sp)
    80001edc:	e822                	sd	s0,16(sp)
    80001ede:	e426                	sd	s1,8(sp)
    80001ee0:	e04a                	sd	s2,0(sp)
    80001ee2:	1000                	addi	s0,sp,32
    80001ee4:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001ee6:	00000097          	auipc	ra,0x0
    80001eea:	ca6080e7          	jalr	-858(ra) # 80001b8c <myproc>
    80001eee:	892a                	mv	s2,a0
  sz = p->sz;
    80001ef0:	652c                	ld	a1,72(a0)
    80001ef2:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001ef6:	00904f63          	bgtz	s1,80001f14 <growproc+0x3c>
  } else if(n < 0){
    80001efa:	0204cc63          	bltz	s1,80001f32 <growproc+0x5a>
  p->sz = sz;
    80001efe:	1602                	slli	a2,a2,0x20
    80001f00:	9201                	srli	a2,a2,0x20
    80001f02:	04c93423          	sd	a2,72(s2)
  return 0;
    80001f06:	4501                	li	a0,0
}
    80001f08:	60e2                	ld	ra,24(sp)
    80001f0a:	6442                	ld	s0,16(sp)
    80001f0c:	64a2                	ld	s1,8(sp)
    80001f0e:	6902                	ld	s2,0(sp)
    80001f10:	6105                	addi	sp,sp,32
    80001f12:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001f14:	9e25                	addw	a2,a2,s1
    80001f16:	1602                	slli	a2,a2,0x20
    80001f18:	9201                	srli	a2,a2,0x20
    80001f1a:	1582                	slli	a1,a1,0x20
    80001f1c:	9181                	srli	a1,a1,0x20
    80001f1e:	6928                	ld	a0,80(a0)
    80001f20:	fffff097          	auipc	ra,0xfffff
    80001f24:	628080e7          	jalr	1576(ra) # 80001548 <uvmalloc>
    80001f28:	0005061b          	sext.w	a2,a0
    80001f2c:	fa69                	bnez	a2,80001efe <growproc+0x26>
      return -1;
    80001f2e:	557d                	li	a0,-1
    80001f30:	bfe1                	j	80001f08 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001f32:	9e25                	addw	a2,a2,s1
    80001f34:	1602                	slli	a2,a2,0x20
    80001f36:	9201                	srli	a2,a2,0x20
    80001f38:	1582                	slli	a1,a1,0x20
    80001f3a:	9181                	srli	a1,a1,0x20
    80001f3c:	6928                	ld	a0,80(a0)
    80001f3e:	fffff097          	auipc	ra,0xfffff
    80001f42:	5c2080e7          	jalr	1474(ra) # 80001500 <uvmdealloc>
    80001f46:	0005061b          	sext.w	a2,a0
    80001f4a:	bf55                	j	80001efe <growproc+0x26>

0000000080001f4c <fork>:
{
    80001f4c:	7179                	addi	sp,sp,-48
    80001f4e:	f406                	sd	ra,40(sp)
    80001f50:	f022                	sd	s0,32(sp)
    80001f52:	ec26                	sd	s1,24(sp)
    80001f54:	e84a                	sd	s2,16(sp)
    80001f56:	e44e                	sd	s3,8(sp)
    80001f58:	e052                	sd	s4,0(sp)
    80001f5a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f5c:	00000097          	auipc	ra,0x0
    80001f60:	c30080e7          	jalr	-976(ra) # 80001b8c <myproc>
    80001f64:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f66:	00000097          	auipc	ra,0x0
    80001f6a:	e30080e7          	jalr	-464(ra) # 80001d96 <allocproc>
    80001f6e:	c175                	beqz	a0,80002052 <fork+0x106>
    80001f70:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f72:	04893603          	ld	a2,72(s2)
    80001f76:	692c                	ld	a1,80(a0)
    80001f78:	05093503          	ld	a0,80(s2)
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	718080e7          	jalr	1816(ra) # 80001694 <uvmcopy>
    80001f84:	04054863          	bltz	a0,80001fd4 <fork+0x88>
  np->sz = p->sz;
    80001f88:	04893783          	ld	a5,72(s2)
    80001f8c:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f90:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f94:	05893683          	ld	a3,88(s2)
    80001f98:	87b6                	mv	a5,a3
    80001f9a:	0589b703          	ld	a4,88(s3)
    80001f9e:	12068693          	addi	a3,a3,288
    80001fa2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001fa6:	6788                	ld	a0,8(a5)
    80001fa8:	6b8c                	ld	a1,16(a5)
    80001faa:	6f90                	ld	a2,24(a5)
    80001fac:	01073023          	sd	a6,0(a4)
    80001fb0:	e708                	sd	a0,8(a4)
    80001fb2:	eb0c                	sd	a1,16(a4)
    80001fb4:	ef10                	sd	a2,24(a4)
    80001fb6:	02078793          	addi	a5,a5,32
    80001fba:	02070713          	addi	a4,a4,32
    80001fbe:	fed792e3          	bne	a5,a3,80001fa2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001fc2:	0589b783          	ld	a5,88(s3)
    80001fc6:	0607b823          	sd	zero,112(a5)
    80001fca:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001fce:	15000a13          	li	s4,336
    80001fd2:	a03d                	j	80002000 <fork+0xb4>
    freeproc(np);
    80001fd4:	854e                	mv	a0,s3
    80001fd6:	00000097          	auipc	ra,0x0
    80001fda:	d68080e7          	jalr	-664(ra) # 80001d3e <freeproc>
    release(&np->lock);
    80001fde:	854e                	mv	a0,s3
    80001fe0:	fffff097          	auipc	ra,0xfffff
    80001fe4:	daa080e7          	jalr	-598(ra) # 80000d8a <release>
    return -1;
    80001fe8:	54fd                	li	s1,-1
    80001fea:	a899                	j	80002040 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001fec:	00002097          	auipc	ra,0x2
    80001ff0:	676080e7          	jalr	1654(ra) # 80004662 <filedup>
    80001ff4:	009987b3          	add	a5,s3,s1
    80001ff8:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ffa:	04a1                	addi	s1,s1,8
    80001ffc:	01448763          	beq	s1,s4,8000200a <fork+0xbe>
    if(p->ofile[i])
    80002000:	009907b3          	add	a5,s2,s1
    80002004:	6388                	ld	a0,0(a5)
    80002006:	f17d                	bnez	a0,80001fec <fork+0xa0>
    80002008:	bfcd                	j	80001ffa <fork+0xae>
  np->cwd = idup(p->cwd);
    8000200a:	15093503          	ld	a0,336(s2)
    8000200e:	00001097          	auipc	ra,0x1
    80002012:	7d6080e7          	jalr	2006(ra) # 800037e4 <idup>
    80002016:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000201a:	4641                	li	a2,16
    8000201c:	15890593          	addi	a1,s2,344
    80002020:	15898513          	addi	a0,s3,344
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	f04080e7          	jalr	-252(ra) # 80000f28 <safestrcpy>
  pid = np->pid;
    8000202c:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80002030:	4789                	li	a5,2
    80002032:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002036:	854e                	mv	a0,s3
    80002038:	fffff097          	auipc	ra,0xfffff
    8000203c:	d52080e7          	jalr	-686(ra) # 80000d8a <release>
}
    80002040:	8526                	mv	a0,s1
    80002042:	70a2                	ld	ra,40(sp)
    80002044:	7402                	ld	s0,32(sp)
    80002046:	64e2                	ld	s1,24(sp)
    80002048:	6942                	ld	s2,16(sp)
    8000204a:	69a2                	ld	s3,8(sp)
    8000204c:	6a02                	ld	s4,0(sp)
    8000204e:	6145                	addi	sp,sp,48
    80002050:	8082                	ret
    return -1;
    80002052:	54fd                	li	s1,-1
    80002054:	b7f5                	j	80002040 <fork+0xf4>

0000000080002056 <reparent>:
{
    80002056:	7179                	addi	sp,sp,-48
    80002058:	f406                	sd	ra,40(sp)
    8000205a:	f022                	sd	s0,32(sp)
    8000205c:	ec26                	sd	s1,24(sp)
    8000205e:	e84a                	sd	s2,16(sp)
    80002060:	e44e                	sd	s3,8(sp)
    80002062:	e052                	sd	s4,0(sp)
    80002064:	1800                	addi	s0,sp,48
    80002066:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002068:	00010497          	auipc	s1,0x10
    8000206c:	d0848493          	addi	s1,s1,-760 # 80011d70 <proc>
      pp->parent = initproc;
    80002070:	00007a17          	auipc	s4,0x7
    80002074:	fa8a0a13          	addi	s4,s4,-88 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002078:	00015997          	auipc	s3,0x15
    8000207c:	6f898993          	addi	s3,s3,1784 # 80017770 <tickslock>
    80002080:	a029                	j	8000208a <reparent+0x34>
    80002082:	16848493          	addi	s1,s1,360
    80002086:	03348363          	beq	s1,s3,800020ac <reparent+0x56>
    if(pp->parent == p){
    8000208a:	709c                	ld	a5,32(s1)
    8000208c:	ff279be3          	bne	a5,s2,80002082 <reparent+0x2c>
      acquire(&pp->lock);
    80002090:	8526                	mv	a0,s1
    80002092:	fffff097          	auipc	ra,0xfffff
    80002096:	c44080e7          	jalr	-956(ra) # 80000cd6 <acquire>
      pp->parent = initproc;
    8000209a:	000a3783          	ld	a5,0(s4)
    8000209e:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800020a0:	8526                	mv	a0,s1
    800020a2:	fffff097          	auipc	ra,0xfffff
    800020a6:	ce8080e7          	jalr	-792(ra) # 80000d8a <release>
    800020aa:	bfe1                	j	80002082 <reparent+0x2c>
}
    800020ac:	70a2                	ld	ra,40(sp)
    800020ae:	7402                	ld	s0,32(sp)
    800020b0:	64e2                	ld	s1,24(sp)
    800020b2:	6942                	ld	s2,16(sp)
    800020b4:	69a2                	ld	s3,8(sp)
    800020b6:	6a02                	ld	s4,0(sp)
    800020b8:	6145                	addi	sp,sp,48
    800020ba:	8082                	ret

00000000800020bc <scheduler>:
{
    800020bc:	711d                	addi	sp,sp,-96
    800020be:	ec86                	sd	ra,88(sp)
    800020c0:	e8a2                	sd	s0,80(sp)
    800020c2:	e4a6                	sd	s1,72(sp)
    800020c4:	e0ca                	sd	s2,64(sp)
    800020c6:	fc4e                	sd	s3,56(sp)
    800020c8:	f852                	sd	s4,48(sp)
    800020ca:	f456                	sd	s5,40(sp)
    800020cc:	f05a                	sd	s6,32(sp)
    800020ce:	ec5e                	sd	s7,24(sp)
    800020d0:	e862                	sd	s8,16(sp)
    800020d2:	e466                	sd	s9,8(sp)
    800020d4:	1080                	addi	s0,sp,96
    800020d6:	8792                	mv	a5,tp
  int id = r_tp();
    800020d8:	2781                	sext.w	a5,a5
  c->proc = 0;
    800020da:	00779c13          	slli	s8,a5,0x7
    800020de:	00010717          	auipc	a4,0x10
    800020e2:	87a70713          	addi	a4,a4,-1926 # 80011958 <pid_lock>
    800020e6:	9762                	add	a4,a4,s8
    800020e8:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800020ec:	00010717          	auipc	a4,0x10
    800020f0:	88c70713          	addi	a4,a4,-1908 # 80011978 <cpus+0x8>
    800020f4:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    800020f6:	4a89                	li	s5,2
        c->proc = p;
    800020f8:	079e                	slli	a5,a5,0x7
    800020fa:	00010b17          	auipc	s6,0x10
    800020fe:	85eb0b13          	addi	s6,s6,-1954 # 80011958 <pid_lock>
    80002102:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002104:	00015a17          	auipc	s4,0x15
    80002108:	66ca0a13          	addi	s4,s4,1644 # 80017770 <tickslock>
    int nproc = 0;
    8000210c:	4c81                	li	s9,0
    8000210e:	a8a1                	j	80002166 <scheduler+0xaa>
        p->state = RUNNING;
    80002110:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002114:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    80002118:	06048593          	addi	a1,s1,96
    8000211c:	8562                	mv	a0,s8
    8000211e:	00000097          	auipc	ra,0x0
    80002122:	63a080e7          	jalr	1594(ra) # 80002758 <swtch>
        c->proc = 0;
    80002126:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000212a:	8526                	mv	a0,s1
    8000212c:	fffff097          	auipc	ra,0xfffff
    80002130:	c5e080e7          	jalr	-930(ra) # 80000d8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002134:	16848493          	addi	s1,s1,360
    80002138:	01448d63          	beq	s1,s4,80002152 <scheduler+0x96>
      acquire(&p->lock);
    8000213c:	8526                	mv	a0,s1
    8000213e:	fffff097          	auipc	ra,0xfffff
    80002142:	b98080e7          	jalr	-1128(ra) # 80000cd6 <acquire>
      if(p->state != UNUSED) {
    80002146:	4c9c                	lw	a5,24(s1)
    80002148:	d3ed                	beqz	a5,8000212a <scheduler+0x6e>
        nproc++;
    8000214a:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000214c:	fd579fe3          	bne	a5,s5,8000212a <scheduler+0x6e>
    80002150:	b7c1                	j	80002110 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002152:	013aca63          	blt	s5,s3,80002166 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002156:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000215a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000215e:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002162:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002166:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000216a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000216e:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    80002172:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002174:	00010497          	auipc	s1,0x10
    80002178:	bfc48493          	addi	s1,s1,-1028 # 80011d70 <proc>
        p->state = RUNNING;
    8000217c:	4b8d                	li	s7,3
    8000217e:	bf7d                	j	8000213c <scheduler+0x80>

0000000080002180 <sched>:
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000218e:	00000097          	auipc	ra,0x0
    80002192:	9fe080e7          	jalr	-1538(ra) # 80001b8c <myproc>
    80002196:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002198:	fffff097          	auipc	ra,0xfffff
    8000219c:	ac4080e7          	jalr	-1340(ra) # 80000c5c <holding>
    800021a0:	c93d                	beqz	a0,80002216 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021a2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021a4:	2781                	sext.w	a5,a5
    800021a6:	079e                	slli	a5,a5,0x7
    800021a8:	0000f717          	auipc	a4,0xf
    800021ac:	7b070713          	addi	a4,a4,1968 # 80011958 <pid_lock>
    800021b0:	97ba                	add	a5,a5,a4
    800021b2:	0907a703          	lw	a4,144(a5)
    800021b6:	4785                	li	a5,1
    800021b8:	06f71763          	bne	a4,a5,80002226 <sched+0xa6>
  if(p->state == RUNNING)
    800021bc:	4c98                	lw	a4,24(s1)
    800021be:	478d                	li	a5,3
    800021c0:	06f70b63          	beq	a4,a5,80002236 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800021c4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800021c8:	8b89                	andi	a5,a5,2
  if(intr_get())
    800021ca:	efb5                	bnez	a5,80002246 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021cc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800021ce:	0000f917          	auipc	s2,0xf
    800021d2:	78a90913          	addi	s2,s2,1930 # 80011958 <pid_lock>
    800021d6:	2781                	sext.w	a5,a5
    800021d8:	079e                	slli	a5,a5,0x7
    800021da:	97ca                	add	a5,a5,s2
    800021dc:	0947a983          	lw	s3,148(a5)
    800021e0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800021e2:	2781                	sext.w	a5,a5
    800021e4:	079e                	slli	a5,a5,0x7
    800021e6:	0000f597          	auipc	a1,0xf
    800021ea:	79258593          	addi	a1,a1,1938 # 80011978 <cpus+0x8>
    800021ee:	95be                	add	a1,a1,a5
    800021f0:	06048513          	addi	a0,s1,96
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	564080e7          	jalr	1380(ra) # 80002758 <swtch>
    800021fc:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800021fe:	2781                	sext.w	a5,a5
    80002200:	079e                	slli	a5,a5,0x7
    80002202:	97ca                	add	a5,a5,s2
    80002204:	0937aa23          	sw	s3,148(a5)
}
    80002208:	70a2                	ld	ra,40(sp)
    8000220a:	7402                	ld	s0,32(sp)
    8000220c:	64e2                	ld	s1,24(sp)
    8000220e:	6942                	ld	s2,16(sp)
    80002210:	69a2                	ld	s3,8(sp)
    80002212:	6145                	addi	sp,sp,48
    80002214:	8082                	ret
    panic("sched p->lock");
    80002216:	00006517          	auipc	a0,0x6
    8000221a:	fea50513          	addi	a0,a0,-22 # 80008200 <digits+0x1c0>
    8000221e:	ffffe097          	auipc	ra,0xffffe
    80002222:	32a080e7          	jalr	810(ra) # 80000548 <panic>
    panic("sched locks");
    80002226:	00006517          	auipc	a0,0x6
    8000222a:	fea50513          	addi	a0,a0,-22 # 80008210 <digits+0x1d0>
    8000222e:	ffffe097          	auipc	ra,0xffffe
    80002232:	31a080e7          	jalr	794(ra) # 80000548 <panic>
    panic("sched running");
    80002236:	00006517          	auipc	a0,0x6
    8000223a:	fea50513          	addi	a0,a0,-22 # 80008220 <digits+0x1e0>
    8000223e:	ffffe097          	auipc	ra,0xffffe
    80002242:	30a080e7          	jalr	778(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002246:	00006517          	auipc	a0,0x6
    8000224a:	fea50513          	addi	a0,a0,-22 # 80008230 <digits+0x1f0>
    8000224e:	ffffe097          	auipc	ra,0xffffe
    80002252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>

0000000080002256 <exit>:
{
    80002256:	7179                	addi	sp,sp,-48
    80002258:	f406                	sd	ra,40(sp)
    8000225a:	f022                	sd	s0,32(sp)
    8000225c:	ec26                	sd	s1,24(sp)
    8000225e:	e84a                	sd	s2,16(sp)
    80002260:	e44e                	sd	s3,8(sp)
    80002262:	e052                	sd	s4,0(sp)
    80002264:	1800                	addi	s0,sp,48
    80002266:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	924080e7          	jalr	-1756(ra) # 80001b8c <myproc>
    80002270:	89aa                	mv	s3,a0
  if(p == initproc)
    80002272:	00007797          	auipc	a5,0x7
    80002276:	da67b783          	ld	a5,-602(a5) # 80009018 <initproc>
    8000227a:	0d050493          	addi	s1,a0,208
    8000227e:	15050913          	addi	s2,a0,336
    80002282:	02a79363          	bne	a5,a0,800022a8 <exit+0x52>
    panic("init exiting");
    80002286:	00006517          	auipc	a0,0x6
    8000228a:	fc250513          	addi	a0,a0,-62 # 80008248 <digits+0x208>
    8000228e:	ffffe097          	auipc	ra,0xffffe
    80002292:	2ba080e7          	jalr	698(ra) # 80000548 <panic>
      fileclose(f);
    80002296:	00002097          	auipc	ra,0x2
    8000229a:	41e080e7          	jalr	1054(ra) # 800046b4 <fileclose>
      p->ofile[fd] = 0;
    8000229e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800022a2:	04a1                	addi	s1,s1,8
    800022a4:	01248563          	beq	s1,s2,800022ae <exit+0x58>
    if(p->ofile[fd]){
    800022a8:	6088                	ld	a0,0(s1)
    800022aa:	f575                	bnez	a0,80002296 <exit+0x40>
    800022ac:	bfdd                	j	800022a2 <exit+0x4c>
  begin_op();
    800022ae:	00002097          	auipc	ra,0x2
    800022b2:	f34080e7          	jalr	-204(ra) # 800041e2 <begin_op>
  iput(p->cwd);
    800022b6:	1509b503          	ld	a0,336(s3)
    800022ba:	00001097          	auipc	ra,0x1
    800022be:	722080e7          	jalr	1826(ra) # 800039dc <iput>
  end_op();
    800022c2:	00002097          	auipc	ra,0x2
    800022c6:	fa0080e7          	jalr	-96(ra) # 80004262 <end_op>
  p->cwd = 0;
    800022ca:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800022ce:	00007497          	auipc	s1,0x7
    800022d2:	d4a48493          	addi	s1,s1,-694 # 80009018 <initproc>
    800022d6:	6088                	ld	a0,0(s1)
    800022d8:	fffff097          	auipc	ra,0xfffff
    800022dc:	9fe080e7          	jalr	-1538(ra) # 80000cd6 <acquire>
  wakeup1(initproc);
    800022e0:	6088                	ld	a0,0(s1)
    800022e2:	fffff097          	auipc	ra,0xfffff
    800022e6:	76a080e7          	jalr	1898(ra) # 80001a4c <wakeup1>
  release(&initproc->lock);
    800022ea:	6088                	ld	a0,0(s1)
    800022ec:	fffff097          	auipc	ra,0xfffff
    800022f0:	a9e080e7          	jalr	-1378(ra) # 80000d8a <release>
  acquire(&p->lock);
    800022f4:	854e                	mv	a0,s3
    800022f6:	fffff097          	auipc	ra,0xfffff
    800022fa:	9e0080e7          	jalr	-1568(ra) # 80000cd6 <acquire>
  struct proc *original_parent = p->parent;
    800022fe:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002302:	854e                	mv	a0,s3
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	a86080e7          	jalr	-1402(ra) # 80000d8a <release>
  acquire(&original_parent->lock);
    8000230c:	8526                	mv	a0,s1
    8000230e:	fffff097          	auipc	ra,0xfffff
    80002312:	9c8080e7          	jalr	-1592(ra) # 80000cd6 <acquire>
  acquire(&p->lock);
    80002316:	854e                	mv	a0,s3
    80002318:	fffff097          	auipc	ra,0xfffff
    8000231c:	9be080e7          	jalr	-1602(ra) # 80000cd6 <acquire>
  reparent(p);
    80002320:	854e                	mv	a0,s3
    80002322:	00000097          	auipc	ra,0x0
    80002326:	d34080e7          	jalr	-716(ra) # 80002056 <reparent>
  wakeup1(original_parent);
    8000232a:	8526                	mv	a0,s1
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	720080e7          	jalr	1824(ra) # 80001a4c <wakeup1>
  p->xstate = status;
    80002334:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002338:	4791                	li	a5,4
    8000233a:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000233e:	8526                	mv	a0,s1
    80002340:	fffff097          	auipc	ra,0xfffff
    80002344:	a4a080e7          	jalr	-1462(ra) # 80000d8a <release>
  sched();
    80002348:	00000097          	auipc	ra,0x0
    8000234c:	e38080e7          	jalr	-456(ra) # 80002180 <sched>
  panic("zombie exit");
    80002350:	00006517          	auipc	a0,0x6
    80002354:	f0850513          	addi	a0,a0,-248 # 80008258 <digits+0x218>
    80002358:	ffffe097          	auipc	ra,0xffffe
    8000235c:	1f0080e7          	jalr	496(ra) # 80000548 <panic>

0000000080002360 <yield>:
{
    80002360:	1101                	addi	sp,sp,-32
    80002362:	ec06                	sd	ra,24(sp)
    80002364:	e822                	sd	s0,16(sp)
    80002366:	e426                	sd	s1,8(sp)
    80002368:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000236a:	00000097          	auipc	ra,0x0
    8000236e:	822080e7          	jalr	-2014(ra) # 80001b8c <myproc>
    80002372:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	962080e7          	jalr	-1694(ra) # 80000cd6 <acquire>
  p->state = RUNNABLE;
    8000237c:	4789                	li	a5,2
    8000237e:	cc9c                	sw	a5,24(s1)
  sched();
    80002380:	00000097          	auipc	ra,0x0
    80002384:	e00080e7          	jalr	-512(ra) # 80002180 <sched>
  release(&p->lock);
    80002388:	8526                	mv	a0,s1
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	a00080e7          	jalr	-1536(ra) # 80000d8a <release>
}
    80002392:	60e2                	ld	ra,24(sp)
    80002394:	6442                	ld	s0,16(sp)
    80002396:	64a2                	ld	s1,8(sp)
    80002398:	6105                	addi	sp,sp,32
    8000239a:	8082                	ret

000000008000239c <sleep>:
{
    8000239c:	7179                	addi	sp,sp,-48
    8000239e:	f406                	sd	ra,40(sp)
    800023a0:	f022                	sd	s0,32(sp)
    800023a2:	ec26                	sd	s1,24(sp)
    800023a4:	e84a                	sd	s2,16(sp)
    800023a6:	e44e                	sd	s3,8(sp)
    800023a8:	1800                	addi	s0,sp,48
    800023aa:	89aa                	mv	s3,a0
    800023ac:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800023ae:	fffff097          	auipc	ra,0xfffff
    800023b2:	7de080e7          	jalr	2014(ra) # 80001b8c <myproc>
    800023b6:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800023b8:	05250663          	beq	a0,s2,80002404 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	91a080e7          	jalr	-1766(ra) # 80000cd6 <acquire>
    release(lk);
    800023c4:	854a                	mv	a0,s2
    800023c6:	fffff097          	auipc	ra,0xfffff
    800023ca:	9c4080e7          	jalr	-1596(ra) # 80000d8a <release>
  p->chan = chan;
    800023ce:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800023d2:	4785                	li	a5,1
    800023d4:	cc9c                	sw	a5,24(s1)
  sched();
    800023d6:	00000097          	auipc	ra,0x0
    800023da:	daa080e7          	jalr	-598(ra) # 80002180 <sched>
  p->chan = 0;
    800023de:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	9a6080e7          	jalr	-1626(ra) # 80000d8a <release>
    acquire(lk);
    800023ec:	854a                	mv	a0,s2
    800023ee:	fffff097          	auipc	ra,0xfffff
    800023f2:	8e8080e7          	jalr	-1816(ra) # 80000cd6 <acquire>
}
    800023f6:	70a2                	ld	ra,40(sp)
    800023f8:	7402                	ld	s0,32(sp)
    800023fa:	64e2                	ld	s1,24(sp)
    800023fc:	6942                	ld	s2,16(sp)
    800023fe:	69a2                	ld	s3,8(sp)
    80002400:	6145                	addi	sp,sp,48
    80002402:	8082                	ret
  p->chan = chan;
    80002404:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002408:	4785                	li	a5,1
    8000240a:	cd1c                	sw	a5,24(a0)
  sched();
    8000240c:	00000097          	auipc	ra,0x0
    80002410:	d74080e7          	jalr	-652(ra) # 80002180 <sched>
  p->chan = 0;
    80002414:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002418:	bff9                	j	800023f6 <sleep+0x5a>

000000008000241a <wait>:
{
    8000241a:	715d                	addi	sp,sp,-80
    8000241c:	e486                	sd	ra,72(sp)
    8000241e:	e0a2                	sd	s0,64(sp)
    80002420:	fc26                	sd	s1,56(sp)
    80002422:	f84a                	sd	s2,48(sp)
    80002424:	f44e                	sd	s3,40(sp)
    80002426:	f052                	sd	s4,32(sp)
    80002428:	ec56                	sd	s5,24(sp)
    8000242a:	e85a                	sd	s6,16(sp)
    8000242c:	e45e                	sd	s7,8(sp)
    8000242e:	e062                	sd	s8,0(sp)
    80002430:	0880                	addi	s0,sp,80
    80002432:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	758080e7          	jalr	1880(ra) # 80001b8c <myproc>
    8000243c:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000243e:	8c2a                	mv	s8,a0
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	896080e7          	jalr	-1898(ra) # 80000cd6 <acquire>
    havekids = 0;
    80002448:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000244a:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000244c:	00015997          	auipc	s3,0x15
    80002450:	32498993          	addi	s3,s3,804 # 80017770 <tickslock>
        havekids = 1;
    80002454:	4a85                	li	s5,1
    havekids = 0;
    80002456:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002458:	00010497          	auipc	s1,0x10
    8000245c:	91848493          	addi	s1,s1,-1768 # 80011d70 <proc>
    80002460:	a08d                	j	800024c2 <wait+0xa8>
          pid = np->pid;
    80002462:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002466:	000b0e63          	beqz	s6,80002482 <wait+0x68>
    8000246a:	4691                	li	a3,4
    8000246c:	03448613          	addi	a2,s1,52
    80002470:	85da                	mv	a1,s6
    80002472:	05093503          	ld	a0,80(s2)
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	500080e7          	jalr	1280(ra) # 80001976 <copyout>
    8000247e:	02054263          	bltz	a0,800024a2 <wait+0x88>
          freeproc(np);
    80002482:	8526                	mv	a0,s1
    80002484:	00000097          	auipc	ra,0x0
    80002488:	8ba080e7          	jalr	-1862(ra) # 80001d3e <freeproc>
          release(&np->lock);
    8000248c:	8526                	mv	a0,s1
    8000248e:	fffff097          	auipc	ra,0xfffff
    80002492:	8fc080e7          	jalr	-1796(ra) # 80000d8a <release>
          release(&p->lock);
    80002496:	854a                	mv	a0,s2
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	8f2080e7          	jalr	-1806(ra) # 80000d8a <release>
          return pid;
    800024a0:	a8a9                	j	800024fa <wait+0xe0>
            release(&np->lock);
    800024a2:	8526                	mv	a0,s1
    800024a4:	fffff097          	auipc	ra,0xfffff
    800024a8:	8e6080e7          	jalr	-1818(ra) # 80000d8a <release>
            release(&p->lock);
    800024ac:	854a                	mv	a0,s2
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	8dc080e7          	jalr	-1828(ra) # 80000d8a <release>
            return -1;
    800024b6:	59fd                	li	s3,-1
    800024b8:	a089                	j	800024fa <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800024ba:	16848493          	addi	s1,s1,360
    800024be:	03348463          	beq	s1,s3,800024e6 <wait+0xcc>
      if(np->parent == p){
    800024c2:	709c                	ld	a5,32(s1)
    800024c4:	ff279be3          	bne	a5,s2,800024ba <wait+0xa0>
        acquire(&np->lock);
    800024c8:	8526                	mv	a0,s1
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	80c080e7          	jalr	-2036(ra) # 80000cd6 <acquire>
        if(np->state == ZOMBIE){
    800024d2:	4c9c                	lw	a5,24(s1)
    800024d4:	f94787e3          	beq	a5,s4,80002462 <wait+0x48>
        release(&np->lock);
    800024d8:	8526                	mv	a0,s1
    800024da:	fffff097          	auipc	ra,0xfffff
    800024de:	8b0080e7          	jalr	-1872(ra) # 80000d8a <release>
        havekids = 1;
    800024e2:	8756                	mv	a4,s5
    800024e4:	bfd9                	j	800024ba <wait+0xa0>
    if(!havekids || p->killed){
    800024e6:	c701                	beqz	a4,800024ee <wait+0xd4>
    800024e8:	03092783          	lw	a5,48(s2)
    800024ec:	c785                	beqz	a5,80002514 <wait+0xfa>
      release(&p->lock);
    800024ee:	854a                	mv	a0,s2
    800024f0:	fffff097          	auipc	ra,0xfffff
    800024f4:	89a080e7          	jalr	-1894(ra) # 80000d8a <release>
      return -1;
    800024f8:	59fd                	li	s3,-1
}
    800024fa:	854e                	mv	a0,s3
    800024fc:	60a6                	ld	ra,72(sp)
    800024fe:	6406                	ld	s0,64(sp)
    80002500:	74e2                	ld	s1,56(sp)
    80002502:	7942                	ld	s2,48(sp)
    80002504:	79a2                	ld	s3,40(sp)
    80002506:	7a02                	ld	s4,32(sp)
    80002508:	6ae2                	ld	s5,24(sp)
    8000250a:	6b42                	ld	s6,16(sp)
    8000250c:	6ba2                	ld	s7,8(sp)
    8000250e:	6c02                	ld	s8,0(sp)
    80002510:	6161                	addi	sp,sp,80
    80002512:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002514:	85e2                	mv	a1,s8
    80002516:	854a                	mv	a0,s2
    80002518:	00000097          	auipc	ra,0x0
    8000251c:	e84080e7          	jalr	-380(ra) # 8000239c <sleep>
    havekids = 0;
    80002520:	bf1d                	j	80002456 <wait+0x3c>

0000000080002522 <wakeup>:
{
    80002522:	7139                	addi	sp,sp,-64
    80002524:	fc06                	sd	ra,56(sp)
    80002526:	f822                	sd	s0,48(sp)
    80002528:	f426                	sd	s1,40(sp)
    8000252a:	f04a                	sd	s2,32(sp)
    8000252c:	ec4e                	sd	s3,24(sp)
    8000252e:	e852                	sd	s4,16(sp)
    80002530:	e456                	sd	s5,8(sp)
    80002532:	0080                	addi	s0,sp,64
    80002534:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002536:	00010497          	auipc	s1,0x10
    8000253a:	83a48493          	addi	s1,s1,-1990 # 80011d70 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000253e:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002540:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002542:	00015917          	auipc	s2,0x15
    80002546:	22e90913          	addi	s2,s2,558 # 80017770 <tickslock>
    8000254a:	a821                	j	80002562 <wakeup+0x40>
      p->state = RUNNABLE;
    8000254c:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002550:	8526                	mv	a0,s1
    80002552:	fffff097          	auipc	ra,0xfffff
    80002556:	838080e7          	jalr	-1992(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000255a:	16848493          	addi	s1,s1,360
    8000255e:	01248e63          	beq	s1,s2,8000257a <wakeup+0x58>
    acquire(&p->lock);
    80002562:	8526                	mv	a0,s1
    80002564:	ffffe097          	auipc	ra,0xffffe
    80002568:	772080e7          	jalr	1906(ra) # 80000cd6 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000256c:	4c9c                	lw	a5,24(s1)
    8000256e:	ff3791e3          	bne	a5,s3,80002550 <wakeup+0x2e>
    80002572:	749c                	ld	a5,40(s1)
    80002574:	fd479ee3          	bne	a5,s4,80002550 <wakeup+0x2e>
    80002578:	bfd1                	j	8000254c <wakeup+0x2a>
}
    8000257a:	70e2                	ld	ra,56(sp)
    8000257c:	7442                	ld	s0,48(sp)
    8000257e:	74a2                	ld	s1,40(sp)
    80002580:	7902                	ld	s2,32(sp)
    80002582:	69e2                	ld	s3,24(sp)
    80002584:	6a42                	ld	s4,16(sp)
    80002586:	6aa2                	ld	s5,8(sp)
    80002588:	6121                	addi	sp,sp,64
    8000258a:	8082                	ret

000000008000258c <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000258c:	7179                	addi	sp,sp,-48
    8000258e:	f406                	sd	ra,40(sp)
    80002590:	f022                	sd	s0,32(sp)
    80002592:	ec26                	sd	s1,24(sp)
    80002594:	e84a                	sd	s2,16(sp)
    80002596:	e44e                	sd	s3,8(sp)
    80002598:	1800                	addi	s0,sp,48
    8000259a:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000259c:	0000f497          	auipc	s1,0xf
    800025a0:	7d448493          	addi	s1,s1,2004 # 80011d70 <proc>
    800025a4:	00015997          	auipc	s3,0x15
    800025a8:	1cc98993          	addi	s3,s3,460 # 80017770 <tickslock>
    acquire(&p->lock);
    800025ac:	8526                	mv	a0,s1
    800025ae:	ffffe097          	auipc	ra,0xffffe
    800025b2:	728080e7          	jalr	1832(ra) # 80000cd6 <acquire>
    if(p->pid == pid){
    800025b6:	5c9c                	lw	a5,56(s1)
    800025b8:	01278d63          	beq	a5,s2,800025d2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800025bc:	8526                	mv	a0,s1
    800025be:	ffffe097          	auipc	ra,0xffffe
    800025c2:	7cc080e7          	jalr	1996(ra) # 80000d8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c6:	16848493          	addi	s1,s1,360
    800025ca:	ff3491e3          	bne	s1,s3,800025ac <kill+0x20>
  }
  return -1;
    800025ce:	557d                	li	a0,-1
    800025d0:	a829                	j	800025ea <kill+0x5e>
      p->killed = 1;
    800025d2:	4785                	li	a5,1
    800025d4:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800025d6:	4c98                	lw	a4,24(s1)
    800025d8:	4785                	li	a5,1
    800025da:	00f70f63          	beq	a4,a5,800025f8 <kill+0x6c>
      release(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	7aa080e7          	jalr	1962(ra) # 80000d8a <release>
      return 0;
    800025e8:	4501                	li	a0,0
}
    800025ea:	70a2                	ld	ra,40(sp)
    800025ec:	7402                	ld	s0,32(sp)
    800025ee:	64e2                	ld	s1,24(sp)
    800025f0:	6942                	ld	s2,16(sp)
    800025f2:	69a2                	ld	s3,8(sp)
    800025f4:	6145                	addi	sp,sp,48
    800025f6:	8082                	ret
        p->state = RUNNABLE;
    800025f8:	4789                	li	a5,2
    800025fa:	cc9c                	sw	a5,24(s1)
    800025fc:	b7cd                	j	800025de <kill+0x52>

00000000800025fe <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025fe:	7179                	addi	sp,sp,-48
    80002600:	f406                	sd	ra,40(sp)
    80002602:	f022                	sd	s0,32(sp)
    80002604:	ec26                	sd	s1,24(sp)
    80002606:	e84a                	sd	s2,16(sp)
    80002608:	e44e                	sd	s3,8(sp)
    8000260a:	e052                	sd	s4,0(sp)
    8000260c:	1800                	addi	s0,sp,48
    8000260e:	84aa                	mv	s1,a0
    80002610:	892e                	mv	s2,a1
    80002612:	89b2                	mv	s3,a2
    80002614:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002616:	fffff097          	auipc	ra,0xfffff
    8000261a:	576080e7          	jalr	1398(ra) # 80001b8c <myproc>
  if(user_dst){
    8000261e:	c08d                	beqz	s1,80002640 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002620:	86d2                	mv	a3,s4
    80002622:	864e                	mv	a2,s3
    80002624:	85ca                	mv	a1,s2
    80002626:	6928                	ld	a0,80(a0)
    80002628:	fffff097          	auipc	ra,0xfffff
    8000262c:	34e080e7          	jalr	846(ra) # 80001976 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002630:	70a2                	ld	ra,40(sp)
    80002632:	7402                	ld	s0,32(sp)
    80002634:	64e2                	ld	s1,24(sp)
    80002636:	6942                	ld	s2,16(sp)
    80002638:	69a2                	ld	s3,8(sp)
    8000263a:	6a02                	ld	s4,0(sp)
    8000263c:	6145                	addi	sp,sp,48
    8000263e:	8082                	ret
    memmove((char *)dst, src, len);
    80002640:	000a061b          	sext.w	a2,s4
    80002644:	85ce                	mv	a1,s3
    80002646:	854a                	mv	a0,s2
    80002648:	ffffe097          	auipc	ra,0xffffe
    8000264c:	7ea080e7          	jalr	2026(ra) # 80000e32 <memmove>
    return 0;
    80002650:	8526                	mv	a0,s1
    80002652:	bff9                	j	80002630 <either_copyout+0x32>

0000000080002654 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002654:	7179                	addi	sp,sp,-48
    80002656:	f406                	sd	ra,40(sp)
    80002658:	f022                	sd	s0,32(sp)
    8000265a:	ec26                	sd	s1,24(sp)
    8000265c:	e84a                	sd	s2,16(sp)
    8000265e:	e44e                	sd	s3,8(sp)
    80002660:	e052                	sd	s4,0(sp)
    80002662:	1800                	addi	s0,sp,48
    80002664:	892a                	mv	s2,a0
    80002666:	84ae                	mv	s1,a1
    80002668:	89b2                	mv	s3,a2
    8000266a:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000266c:	fffff097          	auipc	ra,0xfffff
    80002670:	520080e7          	jalr	1312(ra) # 80001b8c <myproc>
  if(user_src){
    80002674:	c08d                	beqz	s1,80002696 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002676:	86d2                	mv	a3,s4
    80002678:	864e                	mv	a2,s3
    8000267a:	85ca                	mv	a1,s2
    8000267c:	6928                	ld	a0,80(a0)
    8000267e:	fffff097          	auipc	ra,0xfffff
    80002682:	118080e7          	jalr	280(ra) # 80001796 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002686:	70a2                	ld	ra,40(sp)
    80002688:	7402                	ld	s0,32(sp)
    8000268a:	64e2                	ld	s1,24(sp)
    8000268c:	6942                	ld	s2,16(sp)
    8000268e:	69a2                	ld	s3,8(sp)
    80002690:	6a02                	ld	s4,0(sp)
    80002692:	6145                	addi	sp,sp,48
    80002694:	8082                	ret
    memmove(dst, (char*)src, len);
    80002696:	000a061b          	sext.w	a2,s4
    8000269a:	85ce                	mv	a1,s3
    8000269c:	854a                	mv	a0,s2
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	794080e7          	jalr	1940(ra) # 80000e32 <memmove>
    return 0;
    800026a6:	8526                	mv	a0,s1
    800026a8:	bff9                	j	80002686 <either_copyin+0x32>

00000000800026aa <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800026aa:	715d                	addi	sp,sp,-80
    800026ac:	e486                	sd	ra,72(sp)
    800026ae:	e0a2                	sd	s0,64(sp)
    800026b0:	fc26                	sd	s1,56(sp)
    800026b2:	f84a                	sd	s2,48(sp)
    800026b4:	f44e                	sd	s3,40(sp)
    800026b6:	f052                	sd	s4,32(sp)
    800026b8:	ec56                	sd	s5,24(sp)
    800026ba:	e85a                	sd	s6,16(sp)
    800026bc:	e45e                	sd	s7,8(sp)
    800026be:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800026c0:	00006517          	auipc	a0,0x6
    800026c4:	a0850513          	addi	a0,a0,-1528 # 800080c8 <digits+0x88>
    800026c8:	ffffe097          	auipc	ra,0xffffe
    800026cc:	eca080e7          	jalr	-310(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026d0:	0000f497          	auipc	s1,0xf
    800026d4:	7f848493          	addi	s1,s1,2040 # 80011ec8 <proc+0x158>
    800026d8:	00015917          	auipc	s2,0x15
    800026dc:	1f090913          	addi	s2,s2,496 # 800178c8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026e0:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800026e2:	00006997          	auipc	s3,0x6
    800026e6:	b8698993          	addi	s3,s3,-1146 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800026ea:	00006a97          	auipc	s5,0x6
    800026ee:	b86a8a93          	addi	s5,s5,-1146 # 80008270 <digits+0x230>
    printf("\n");
    800026f2:	00006a17          	auipc	s4,0x6
    800026f6:	9d6a0a13          	addi	s4,s4,-1578 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026fa:	00006b97          	auipc	s7,0x6
    800026fe:	baeb8b93          	addi	s7,s7,-1106 # 800082a8 <states.1711>
    80002702:	a00d                	j	80002724 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002704:	ee06a583          	lw	a1,-288(a3)
    80002708:	8556                	mv	a0,s5
    8000270a:	ffffe097          	auipc	ra,0xffffe
    8000270e:	e88080e7          	jalr	-376(ra) # 80000592 <printf>
    printf("\n");
    80002712:	8552                	mv	a0,s4
    80002714:	ffffe097          	auipc	ra,0xffffe
    80002718:	e7e080e7          	jalr	-386(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000271c:	16848493          	addi	s1,s1,360
    80002720:	03248163          	beq	s1,s2,80002742 <procdump+0x98>
    if(p->state == UNUSED)
    80002724:	86a6                	mv	a3,s1
    80002726:	ec04a783          	lw	a5,-320(s1)
    8000272a:	dbed                	beqz	a5,8000271c <procdump+0x72>
      state = "???";
    8000272c:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000272e:	fcfb6be3          	bltu	s6,a5,80002704 <procdump+0x5a>
    80002732:	1782                	slli	a5,a5,0x20
    80002734:	9381                	srli	a5,a5,0x20
    80002736:	078e                	slli	a5,a5,0x3
    80002738:	97de                	add	a5,a5,s7
    8000273a:	6390                	ld	a2,0(a5)
    8000273c:	f661                	bnez	a2,80002704 <procdump+0x5a>
      state = "???";
    8000273e:	864e                	mv	a2,s3
    80002740:	b7d1                	j	80002704 <procdump+0x5a>
  }
}
    80002742:	60a6                	ld	ra,72(sp)
    80002744:	6406                	ld	s0,64(sp)
    80002746:	74e2                	ld	s1,56(sp)
    80002748:	7942                	ld	s2,48(sp)
    8000274a:	79a2                	ld	s3,40(sp)
    8000274c:	7a02                	ld	s4,32(sp)
    8000274e:	6ae2                	ld	s5,24(sp)
    80002750:	6b42                	ld	s6,16(sp)
    80002752:	6ba2                	ld	s7,8(sp)
    80002754:	6161                	addi	sp,sp,80
    80002756:	8082                	ret

0000000080002758 <swtch>:
    80002758:	00153023          	sd	ra,0(a0)
    8000275c:	00253423          	sd	sp,8(a0)
    80002760:	e900                	sd	s0,16(a0)
    80002762:	ed04                	sd	s1,24(a0)
    80002764:	03253023          	sd	s2,32(a0)
    80002768:	03353423          	sd	s3,40(a0)
    8000276c:	03453823          	sd	s4,48(a0)
    80002770:	03553c23          	sd	s5,56(a0)
    80002774:	05653023          	sd	s6,64(a0)
    80002778:	05753423          	sd	s7,72(a0)
    8000277c:	05853823          	sd	s8,80(a0)
    80002780:	05953c23          	sd	s9,88(a0)
    80002784:	07a53023          	sd	s10,96(a0)
    80002788:	07b53423          	sd	s11,104(a0)
    8000278c:	0005b083          	ld	ra,0(a1)
    80002790:	0085b103          	ld	sp,8(a1)
    80002794:	6980                	ld	s0,16(a1)
    80002796:	6d84                	ld	s1,24(a1)
    80002798:	0205b903          	ld	s2,32(a1)
    8000279c:	0285b983          	ld	s3,40(a1)
    800027a0:	0305ba03          	ld	s4,48(a1)
    800027a4:	0385ba83          	ld	s5,56(a1)
    800027a8:	0405bb03          	ld	s6,64(a1)
    800027ac:	0485bb83          	ld	s7,72(a1)
    800027b0:	0505bc03          	ld	s8,80(a1)
    800027b4:	0585bc83          	ld	s9,88(a1)
    800027b8:	0605bd03          	ld	s10,96(a1)
    800027bc:	0685bd83          	ld	s11,104(a1)
    800027c0:	8082                	ret

00000000800027c2 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800027c2:	1141                	addi	sp,sp,-16
    800027c4:	e406                	sd	ra,8(sp)
    800027c6:	e022                	sd	s0,0(sp)
    800027c8:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800027ca:	00006597          	auipc	a1,0x6
    800027ce:	b0658593          	addi	a1,a1,-1274 # 800082d0 <states.1711+0x28>
    800027d2:	00015517          	auipc	a0,0x15
    800027d6:	f9e50513          	addi	a0,a0,-98 # 80017770 <tickslock>
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	46c080e7          	jalr	1132(ra) # 80000c46 <initlock>
}
    800027e2:	60a2                	ld	ra,8(sp)
    800027e4:	6402                	ld	s0,0(sp)
    800027e6:	0141                	addi	sp,sp,16
    800027e8:	8082                	ret

00000000800027ea <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800027ea:	1141                	addi	sp,sp,-16
    800027ec:	e422                	sd	s0,8(sp)
    800027ee:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027f0:	00003797          	auipc	a5,0x3
    800027f4:	53078793          	addi	a5,a5,1328 # 80005d20 <kernelvec>
    800027f8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800027fc:	6422                	ld	s0,8(sp)
    800027fe:	0141                	addi	sp,sp,16
    80002800:	8082                	ret

0000000080002802 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002802:	1141                	addi	sp,sp,-16
    80002804:	e406                	sd	ra,8(sp)
    80002806:	e022                	sd	s0,0(sp)
    80002808:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000280a:	fffff097          	auipc	ra,0xfffff
    8000280e:	382080e7          	jalr	898(ra) # 80001b8c <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002812:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002816:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002818:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    8000281c:	00004617          	auipc	a2,0x4
    80002820:	7e460613          	addi	a2,a2,2020 # 80007000 <_trampoline>
    80002824:	00004697          	auipc	a3,0x4
    80002828:	7dc68693          	addi	a3,a3,2012 # 80007000 <_trampoline>
    8000282c:	8e91                	sub	a3,a3,a2
    8000282e:	040007b7          	lui	a5,0x4000
    80002832:	17fd                	addi	a5,a5,-1
    80002834:	07b2                	slli	a5,a5,0xc
    80002836:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002838:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000283c:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    8000283e:	180026f3          	csrr	a3,satp
    80002842:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002844:	6d38                	ld	a4,88(a0)
    80002846:	6134                	ld	a3,64(a0)
    80002848:	6585                	lui	a1,0x1
    8000284a:	96ae                	add	a3,a3,a1
    8000284c:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    8000284e:	6d38                	ld	a4,88(a0)
    80002850:	00000697          	auipc	a3,0x0
    80002854:	13868693          	addi	a3,a3,312 # 80002988 <usertrap>
    80002858:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000285a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000285c:	8692                	mv	a3,tp
    8000285e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002860:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002864:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002868:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000286c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002870:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002872:	6f18                	ld	a4,24(a4)
    80002874:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002878:	692c                	ld	a1,80(a0)
    8000287a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000287c:	00005717          	auipc	a4,0x5
    80002880:	81470713          	addi	a4,a4,-2028 # 80007090 <userret>
    80002884:	8f11                	sub	a4,a4,a2
    80002886:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002888:	577d                	li	a4,-1
    8000288a:	177e                	slli	a4,a4,0x3f
    8000288c:	8dd9                	or	a1,a1,a4
    8000288e:	02000537          	lui	a0,0x2000
    80002892:	157d                	addi	a0,a0,-1
    80002894:	0536                	slli	a0,a0,0xd
    80002896:	9782                	jalr	a5
}
    80002898:	60a2                	ld	ra,8(sp)
    8000289a:	6402                	ld	s0,0(sp)
    8000289c:	0141                	addi	sp,sp,16
    8000289e:	8082                	ret

00000000800028a0 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    800028a0:	1101                	addi	sp,sp,-32
    800028a2:	ec06                	sd	ra,24(sp)
    800028a4:	e822                	sd	s0,16(sp)
    800028a6:	e426                	sd	s1,8(sp)
    800028a8:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800028aa:	00015497          	auipc	s1,0x15
    800028ae:	ec648493          	addi	s1,s1,-314 # 80017770 <tickslock>
    800028b2:	8526                	mv	a0,s1
    800028b4:	ffffe097          	auipc	ra,0xffffe
    800028b8:	422080e7          	jalr	1058(ra) # 80000cd6 <acquire>
  ticks++;
    800028bc:	00006517          	auipc	a0,0x6
    800028c0:	76450513          	addi	a0,a0,1892 # 80009020 <ticks>
    800028c4:	411c                	lw	a5,0(a0)
    800028c6:	2785                	addiw	a5,a5,1
    800028c8:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	c58080e7          	jalr	-936(ra) # 80002522 <wakeup>
  release(&tickslock);
    800028d2:	8526                	mv	a0,s1
    800028d4:	ffffe097          	auipc	ra,0xffffe
    800028d8:	4b6080e7          	jalr	1206(ra) # 80000d8a <release>
}
    800028dc:	60e2                	ld	ra,24(sp)
    800028de:	6442                	ld	s0,16(sp)
    800028e0:	64a2                	ld	s1,8(sp)
    800028e2:	6105                	addi	sp,sp,32
    800028e4:	8082                	ret

00000000800028e6 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800028e6:	1101                	addi	sp,sp,-32
    800028e8:	ec06                	sd	ra,24(sp)
    800028ea:	e822                	sd	s0,16(sp)
    800028ec:	e426                	sd	s1,8(sp)
    800028ee:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028f0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800028f4:	00074d63          	bltz	a4,8000290e <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800028f8:	57fd                	li	a5,-1
    800028fa:	17fe                	slli	a5,a5,0x3f
    800028fc:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800028fe:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002900:	06f70363          	beq	a4,a5,80002966 <devintr+0x80>
  }
}
    80002904:	60e2                	ld	ra,24(sp)
    80002906:	6442                	ld	s0,16(sp)
    80002908:	64a2                	ld	s1,8(sp)
    8000290a:	6105                	addi	sp,sp,32
    8000290c:	8082                	ret
     (scause & 0xff) == 9){
    8000290e:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002912:	46a5                	li	a3,9
    80002914:	fed792e3          	bne	a5,a3,800028f8 <devintr+0x12>
    int irq = plic_claim();
    80002918:	00003097          	auipc	ra,0x3
    8000291c:	510080e7          	jalr	1296(ra) # 80005e28 <plic_claim>
    80002920:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002922:	47a9                	li	a5,10
    80002924:	02f50763          	beq	a0,a5,80002952 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002928:	4785                	li	a5,1
    8000292a:	02f50963          	beq	a0,a5,8000295c <devintr+0x76>
    return 1;
    8000292e:	4505                	li	a0,1
    } else if(irq){
    80002930:	d8f1                	beqz	s1,80002904 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002932:	85a6                	mv	a1,s1
    80002934:	00006517          	auipc	a0,0x6
    80002938:	9a450513          	addi	a0,a0,-1628 # 800082d8 <states.1711+0x30>
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	c56080e7          	jalr	-938(ra) # 80000592 <printf>
      plic_complete(irq);
    80002944:	8526                	mv	a0,s1
    80002946:	00003097          	auipc	ra,0x3
    8000294a:	506080e7          	jalr	1286(ra) # 80005e4c <plic_complete>
    return 1;
    8000294e:	4505                	li	a0,1
    80002950:	bf55                	j	80002904 <devintr+0x1e>
      uartintr();
    80002952:	ffffe097          	auipc	ra,0xffffe
    80002956:	082080e7          	jalr	130(ra) # 800009d4 <uartintr>
    8000295a:	b7ed                	j	80002944 <devintr+0x5e>
      virtio_disk_intr();
    8000295c:	00004097          	auipc	ra,0x4
    80002960:	98a080e7          	jalr	-1654(ra) # 800062e6 <virtio_disk_intr>
    80002964:	b7c5                	j	80002944 <devintr+0x5e>
    if(cpuid() == 0){
    80002966:	fffff097          	auipc	ra,0xfffff
    8000296a:	1fa080e7          	jalr	506(ra) # 80001b60 <cpuid>
    8000296e:	c901                	beqz	a0,8000297e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002970:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002974:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002976:	14479073          	csrw	sip,a5
    return 2;
    8000297a:	4509                	li	a0,2
    8000297c:	b761                	j	80002904 <devintr+0x1e>
      clockintr();
    8000297e:	00000097          	auipc	ra,0x0
    80002982:	f22080e7          	jalr	-222(ra) # 800028a0 <clockintr>
    80002986:	b7ed                	j	80002970 <devintr+0x8a>

0000000080002988 <usertrap>:
{
    80002988:	7179                	addi	sp,sp,-48
    8000298a:	f406                	sd	ra,40(sp)
    8000298c:	f022                	sd	s0,32(sp)
    8000298e:	ec26                	sd	s1,24(sp)
    80002990:	e84a                	sd	s2,16(sp)
    80002992:	e44e                	sd	s3,8(sp)
    80002994:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002996:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000299a:	1007f793          	andi	a5,a5,256
    8000299e:	e3b5                	bnez	a5,80002a02 <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a0:	00003797          	auipc	a5,0x3
    800029a4:	38078793          	addi	a5,a5,896 # 80005d20 <kernelvec>
    800029a8:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800029ac:	fffff097          	auipc	ra,0xfffff
    800029b0:	1e0080e7          	jalr	480(ra) # 80001b8c <myproc>
    800029b4:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800029b6:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029b8:	14102773          	csrr	a4,sepc
    800029bc:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029be:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800029c2:	47a1                	li	a5,8
    800029c4:	04f71d63          	bne	a4,a5,80002a1e <usertrap+0x96>
    if(p->killed)
    800029c8:	591c                	lw	a5,48(a0)
    800029ca:	e7a1                	bnez	a5,80002a12 <usertrap+0x8a>
    p->trapframe->epc += 4;
    800029cc:	6cb8                	ld	a4,88(s1)
    800029ce:	6f1c                	ld	a5,24(a4)
    800029d0:	0791                	addi	a5,a5,4
    800029d2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029d4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800029d8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029dc:	10079073          	csrw	sstatus,a5
    syscall();
    800029e0:	00000097          	auipc	ra,0x0
    800029e4:	344080e7          	jalr	836(ra) # 80002d24 <syscall>
  if(p->killed)
    800029e8:	589c                	lw	a5,48(s1)
    800029ea:	eff1                	bnez	a5,80002ac6 <usertrap+0x13e>
  usertrapret();
    800029ec:	00000097          	auipc	ra,0x0
    800029f0:	e16080e7          	jalr	-490(ra) # 80002802 <usertrapret>
}
    800029f4:	70a2                	ld	ra,40(sp)
    800029f6:	7402                	ld	s0,32(sp)
    800029f8:	64e2                	ld	s1,24(sp)
    800029fa:	6942                	ld	s2,16(sp)
    800029fc:	69a2                	ld	s3,8(sp)
    800029fe:	6145                	addi	sp,sp,48
    80002a00:	8082                	ret
    panic("usertrap: not from user mode");
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	8f650513          	addi	a0,a0,-1802 # 800082f8 <states.1711+0x50>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b3e080e7          	jalr	-1218(ra) # 80000548 <panic>
      exit(-1);
    80002a12:	557d                	li	a0,-1
    80002a14:	00000097          	auipc	ra,0x0
    80002a18:	842080e7          	jalr	-1982(ra) # 80002256 <exit>
    80002a1c:	bf45                	j	800029cc <usertrap+0x44>
  else if((which_dev = devintr()) != 0){
    80002a1e:	00000097          	auipc	ra,0x0
    80002a22:	ec8080e7          	jalr	-312(ra) # 800028e6 <devintr>
    80002a26:	892a                	mv	s2,a0
    80002a28:	ed41                	bnez	a0,80002ac0 <usertrap+0x138>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a2a:	14202773          	csrr	a4,scause
  else if (r_scause() == 13 || r_scause() == 15)
    80002a2e:	47b5                	li	a5,13
    80002a30:	00f70763          	beq	a4,a5,80002a3e <usertrap+0xb6>
    80002a34:	14202773          	csrr	a4,scause
    80002a38:	47bd                	li	a5,15
    80002a3a:	04f71963          	bne	a4,a5,80002a8c <usertrap+0x104>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a3e:	143029f3          	csrr	s3,stval
    pagetable_t pagetable = myproc()->pagetable;
    80002a42:	fffff097          	auipc	ra,0xfffff
    80002a46:	14a080e7          	jalr	330(ra) # 80001b8c <myproc>
    if (pagefault_handler(pagetable, va) != 0)
    80002a4a:	85ce                	mv	a1,s3
    80002a4c:	6928                	ld	a0,80(a0)
    80002a4e:	fffff097          	auipc	ra,0xfffff
    80002a52:	e88080e7          	jalr	-376(ra) # 800018d6 <pagefault_handler>
    80002a56:	d949                	beqz	a0,800029e8 <usertrap+0x60>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a58:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a5c:	5c90                	lw	a2,56(s1)
    80002a5e:	00006517          	auipc	a0,0x6
    80002a62:	8ba50513          	addi	a0,a0,-1862 # 80008318 <states.1711+0x70>
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	b2c080e7          	jalr	-1236(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a6e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a72:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a76:	00006517          	auipc	a0,0x6
    80002a7a:	8d250513          	addi	a0,a0,-1838 # 80008348 <states.1711+0xa0>
    80002a7e:	ffffe097          	auipc	ra,0xffffe
    80002a82:	b14080e7          	jalr	-1260(ra) # 80000592 <printf>
      p->killed = 1;
    80002a86:	4785                	li	a5,1
    80002a88:	d89c                	sw	a5,48(s1)
    80002a8a:	a83d                	j	80002ac8 <usertrap+0x140>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a8c:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a90:	5c90                	lw	a2,56(s1)
    80002a92:	00006517          	auipc	a0,0x6
    80002a96:	88650513          	addi	a0,a0,-1914 # 80008318 <states.1711+0x70>
    80002a9a:	ffffe097          	auipc	ra,0xffffe
    80002a9e:	af8080e7          	jalr	-1288(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002aa2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002aa6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002aaa:	00006517          	auipc	a0,0x6
    80002aae:	89e50513          	addi	a0,a0,-1890 # 80008348 <states.1711+0xa0>
    80002ab2:	ffffe097          	auipc	ra,0xffffe
    80002ab6:	ae0080e7          	jalr	-1312(ra) # 80000592 <printf>
    p->killed = 1;
    80002aba:	4785                	li	a5,1
    80002abc:	d89c                	sw	a5,48(s1)
    80002abe:	a029                	j	80002ac8 <usertrap+0x140>
  if(p->killed)
    80002ac0:	589c                	lw	a5,48(s1)
    80002ac2:	cb81                	beqz	a5,80002ad2 <usertrap+0x14a>
    80002ac4:	a011                	j	80002ac8 <usertrap+0x140>
    80002ac6:	4901                	li	s2,0
    exit(-1);
    80002ac8:	557d                	li	a0,-1
    80002aca:	fffff097          	auipc	ra,0xfffff
    80002ace:	78c080e7          	jalr	1932(ra) # 80002256 <exit>
  if(which_dev == 2)
    80002ad2:	4789                	li	a5,2
    80002ad4:	f0f91ce3          	bne	s2,a5,800029ec <usertrap+0x64>
    yield();
    80002ad8:	00000097          	auipc	ra,0x0
    80002adc:	888080e7          	jalr	-1912(ra) # 80002360 <yield>
    80002ae0:	b731                	j	800029ec <usertrap+0x64>

0000000080002ae2 <kerneltrap>:
{
    80002ae2:	7179                	addi	sp,sp,-48
    80002ae4:	f406                	sd	ra,40(sp)
    80002ae6:	f022                	sd	s0,32(sp)
    80002ae8:	ec26                	sd	s1,24(sp)
    80002aea:	e84a                	sd	s2,16(sp)
    80002aec:	e44e                	sd	s3,8(sp)
    80002aee:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002af0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002af4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002af8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002afc:	1004f793          	andi	a5,s1,256
    80002b00:	cb85                	beqz	a5,80002b30 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b02:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b06:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b08:	ef85                	bnez	a5,80002b40 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b0a:	00000097          	auipc	ra,0x0
    80002b0e:	ddc080e7          	jalr	-548(ra) # 800028e6 <devintr>
    80002b12:	cd1d                	beqz	a0,80002b50 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b14:	4789                	li	a5,2
    80002b16:	06f50a63          	beq	a0,a5,80002b8a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b1a:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b1e:	10049073          	csrw	sstatus,s1
}
    80002b22:	70a2                	ld	ra,40(sp)
    80002b24:	7402                	ld	s0,32(sp)
    80002b26:	64e2                	ld	s1,24(sp)
    80002b28:	6942                	ld	s2,16(sp)
    80002b2a:	69a2                	ld	s3,8(sp)
    80002b2c:	6145                	addi	sp,sp,48
    80002b2e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b30:	00006517          	auipc	a0,0x6
    80002b34:	83850513          	addi	a0,a0,-1992 # 80008368 <states.1711+0xc0>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a10080e7          	jalr	-1520(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b40:	00006517          	auipc	a0,0x6
    80002b44:	85050513          	addi	a0,a0,-1968 # 80008390 <states.1711+0xe8>
    80002b48:	ffffe097          	auipc	ra,0xffffe
    80002b4c:	a00080e7          	jalr	-1536(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002b50:	85ce                	mv	a1,s3
    80002b52:	00006517          	auipc	a0,0x6
    80002b56:	85e50513          	addi	a0,a0,-1954 # 800083b0 <states.1711+0x108>
    80002b5a:	ffffe097          	auipc	ra,0xffffe
    80002b5e:	a38080e7          	jalr	-1480(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b62:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b66:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b6a:	00006517          	auipc	a0,0x6
    80002b6e:	85650513          	addi	a0,a0,-1962 # 800083c0 <states.1711+0x118>
    80002b72:	ffffe097          	auipc	ra,0xffffe
    80002b76:	a20080e7          	jalr	-1504(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	85e50513          	addi	a0,a0,-1954 # 800083d8 <states.1711+0x130>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	9c6080e7          	jalr	-1594(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b8a:	fffff097          	auipc	ra,0xfffff
    80002b8e:	002080e7          	jalr	2(ra) # 80001b8c <myproc>
    80002b92:	d541                	beqz	a0,80002b1a <kerneltrap+0x38>
    80002b94:	fffff097          	auipc	ra,0xfffff
    80002b98:	ff8080e7          	jalr	-8(ra) # 80001b8c <myproc>
    80002b9c:	4d18                	lw	a4,24(a0)
    80002b9e:	478d                	li	a5,3
    80002ba0:	f6f71de3          	bne	a4,a5,80002b1a <kerneltrap+0x38>
    yield();
    80002ba4:	fffff097          	auipc	ra,0xfffff
    80002ba8:	7bc080e7          	jalr	1980(ra) # 80002360 <yield>
    80002bac:	b7bd                	j	80002b1a <kerneltrap+0x38>

0000000080002bae <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002bae:	1101                	addi	sp,sp,-32
    80002bb0:	ec06                	sd	ra,24(sp)
    80002bb2:	e822                	sd	s0,16(sp)
    80002bb4:	e426                	sd	s1,8(sp)
    80002bb6:	1000                	addi	s0,sp,32
    80002bb8:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002bba:	fffff097          	auipc	ra,0xfffff
    80002bbe:	fd2080e7          	jalr	-46(ra) # 80001b8c <myproc>
  switch (n) {
    80002bc2:	4795                	li	a5,5
    80002bc4:	0497e163          	bltu	a5,s1,80002c06 <argraw+0x58>
    80002bc8:	048a                	slli	s1,s1,0x2
    80002bca:	00006717          	auipc	a4,0x6
    80002bce:	84670713          	addi	a4,a4,-1978 # 80008410 <states.1711+0x168>
    80002bd2:	94ba                	add	s1,s1,a4
    80002bd4:	409c                	lw	a5,0(s1)
    80002bd6:	97ba                	add	a5,a5,a4
    80002bd8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002bda:	6d3c                	ld	a5,88(a0)
    80002bdc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002bde:	60e2                	ld	ra,24(sp)
    80002be0:	6442                	ld	s0,16(sp)
    80002be2:	64a2                	ld	s1,8(sp)
    80002be4:	6105                	addi	sp,sp,32
    80002be6:	8082                	ret
    return p->trapframe->a1;
    80002be8:	6d3c                	ld	a5,88(a0)
    80002bea:	7fa8                	ld	a0,120(a5)
    80002bec:	bfcd                	j	80002bde <argraw+0x30>
    return p->trapframe->a2;
    80002bee:	6d3c                	ld	a5,88(a0)
    80002bf0:	63c8                	ld	a0,128(a5)
    80002bf2:	b7f5                	j	80002bde <argraw+0x30>
    return p->trapframe->a3;
    80002bf4:	6d3c                	ld	a5,88(a0)
    80002bf6:	67c8                	ld	a0,136(a5)
    80002bf8:	b7dd                	j	80002bde <argraw+0x30>
    return p->trapframe->a4;
    80002bfa:	6d3c                	ld	a5,88(a0)
    80002bfc:	6bc8                	ld	a0,144(a5)
    80002bfe:	b7c5                	j	80002bde <argraw+0x30>
    return p->trapframe->a5;
    80002c00:	6d3c                	ld	a5,88(a0)
    80002c02:	6fc8                	ld	a0,152(a5)
    80002c04:	bfe9                	j	80002bde <argraw+0x30>
  panic("argraw");
    80002c06:	00005517          	auipc	a0,0x5
    80002c0a:	7e250513          	addi	a0,a0,2018 # 800083e8 <states.1711+0x140>
    80002c0e:	ffffe097          	auipc	ra,0xffffe
    80002c12:	93a080e7          	jalr	-1734(ra) # 80000548 <panic>

0000000080002c16 <fetchaddr>:
{
    80002c16:	1101                	addi	sp,sp,-32
    80002c18:	ec06                	sd	ra,24(sp)
    80002c1a:	e822                	sd	s0,16(sp)
    80002c1c:	e426                	sd	s1,8(sp)
    80002c1e:	e04a                	sd	s2,0(sp)
    80002c20:	1000                	addi	s0,sp,32
    80002c22:	84aa                	mv	s1,a0
    80002c24:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c26:	fffff097          	auipc	ra,0xfffff
    80002c2a:	f66080e7          	jalr	-154(ra) # 80001b8c <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002c2e:	653c                	ld	a5,72(a0)
    80002c30:	02f4f863          	bgeu	s1,a5,80002c60 <fetchaddr+0x4a>
    80002c34:	00848713          	addi	a4,s1,8
    80002c38:	02e7e663          	bltu	a5,a4,80002c64 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c3c:	46a1                	li	a3,8
    80002c3e:	8626                	mv	a2,s1
    80002c40:	85ca                	mv	a1,s2
    80002c42:	6928                	ld	a0,80(a0)
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	b52080e7          	jalr	-1198(ra) # 80001796 <copyin>
    80002c4c:	00a03533          	snez	a0,a0
    80002c50:	40a00533          	neg	a0,a0
}
    80002c54:	60e2                	ld	ra,24(sp)
    80002c56:	6442                	ld	s0,16(sp)
    80002c58:	64a2                	ld	s1,8(sp)
    80002c5a:	6902                	ld	s2,0(sp)
    80002c5c:	6105                	addi	sp,sp,32
    80002c5e:	8082                	ret
    return -1;
    80002c60:	557d                	li	a0,-1
    80002c62:	bfcd                	j	80002c54 <fetchaddr+0x3e>
    80002c64:	557d                	li	a0,-1
    80002c66:	b7fd                	j	80002c54 <fetchaddr+0x3e>

0000000080002c68 <fetchstr>:
{
    80002c68:	7179                	addi	sp,sp,-48
    80002c6a:	f406                	sd	ra,40(sp)
    80002c6c:	f022                	sd	s0,32(sp)
    80002c6e:	ec26                	sd	s1,24(sp)
    80002c70:	e84a                	sd	s2,16(sp)
    80002c72:	e44e                	sd	s3,8(sp)
    80002c74:	1800                	addi	s0,sp,48
    80002c76:	892a                	mv	s2,a0
    80002c78:	84ae                	mv	s1,a1
    80002c7a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	f10080e7          	jalr	-240(ra) # 80001b8c <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c84:	86ce                	mv	a3,s3
    80002c86:	864a                	mv	a2,s2
    80002c88:	85a6                	mv	a1,s1
    80002c8a:	6928                	ld	a0,80(a0)
    80002c8c:	fffff097          	auipc	ra,0xfffff
    80002c90:	b96080e7          	jalr	-1130(ra) # 80001822 <copyinstr>
  if(err < 0)
    80002c94:	00054763          	bltz	a0,80002ca2 <fetchstr+0x3a>
  return strlen(buf);
    80002c98:	8526                	mv	a0,s1
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	2c0080e7          	jalr	704(ra) # 80000f5a <strlen>
}
    80002ca2:	70a2                	ld	ra,40(sp)
    80002ca4:	7402                	ld	s0,32(sp)
    80002ca6:	64e2                	ld	s1,24(sp)
    80002ca8:	6942                	ld	s2,16(sp)
    80002caa:	69a2                	ld	s3,8(sp)
    80002cac:	6145                	addi	sp,sp,48
    80002cae:	8082                	ret

0000000080002cb0 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002cb0:	1101                	addi	sp,sp,-32
    80002cb2:	ec06                	sd	ra,24(sp)
    80002cb4:	e822                	sd	s0,16(sp)
    80002cb6:	e426                	sd	s1,8(sp)
    80002cb8:	1000                	addi	s0,sp,32
    80002cba:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cbc:	00000097          	auipc	ra,0x0
    80002cc0:	ef2080e7          	jalr	-270(ra) # 80002bae <argraw>
    80002cc4:	c088                	sw	a0,0(s1)
  return 0;
}
    80002cc6:	4501                	li	a0,0
    80002cc8:	60e2                	ld	ra,24(sp)
    80002cca:	6442                	ld	s0,16(sp)
    80002ccc:	64a2                	ld	s1,8(sp)
    80002cce:	6105                	addi	sp,sp,32
    80002cd0:	8082                	ret

0000000080002cd2 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002cd2:	1101                	addi	sp,sp,-32
    80002cd4:	ec06                	sd	ra,24(sp)
    80002cd6:	e822                	sd	s0,16(sp)
    80002cd8:	e426                	sd	s1,8(sp)
    80002cda:	1000                	addi	s0,sp,32
    80002cdc:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002cde:	00000097          	auipc	ra,0x0
    80002ce2:	ed0080e7          	jalr	-304(ra) # 80002bae <argraw>
    80002ce6:	e088                	sd	a0,0(s1)
  return 0;
}
    80002ce8:	4501                	li	a0,0
    80002cea:	60e2                	ld	ra,24(sp)
    80002cec:	6442                	ld	s0,16(sp)
    80002cee:	64a2                	ld	s1,8(sp)
    80002cf0:	6105                	addi	sp,sp,32
    80002cf2:	8082                	ret

0000000080002cf4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002cf4:	1101                	addi	sp,sp,-32
    80002cf6:	ec06                	sd	ra,24(sp)
    80002cf8:	e822                	sd	s0,16(sp)
    80002cfa:	e426                	sd	s1,8(sp)
    80002cfc:	e04a                	sd	s2,0(sp)
    80002cfe:	1000                	addi	s0,sp,32
    80002d00:	84ae                	mv	s1,a1
    80002d02:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002d04:	00000097          	auipc	ra,0x0
    80002d08:	eaa080e7          	jalr	-342(ra) # 80002bae <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002d0c:	864a                	mv	a2,s2
    80002d0e:	85a6                	mv	a1,s1
    80002d10:	00000097          	auipc	ra,0x0
    80002d14:	f58080e7          	jalr	-168(ra) # 80002c68 <fetchstr>
}
    80002d18:	60e2                	ld	ra,24(sp)
    80002d1a:	6442                	ld	s0,16(sp)
    80002d1c:	64a2                	ld	s1,8(sp)
    80002d1e:	6902                	ld	s2,0(sp)
    80002d20:	6105                	addi	sp,sp,32
    80002d22:	8082                	ret

0000000080002d24 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002d24:	1101                	addi	sp,sp,-32
    80002d26:	ec06                	sd	ra,24(sp)
    80002d28:	e822                	sd	s0,16(sp)
    80002d2a:	e426                	sd	s1,8(sp)
    80002d2c:	e04a                	sd	s2,0(sp)
    80002d2e:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d30:	fffff097          	auipc	ra,0xfffff
    80002d34:	e5c080e7          	jalr	-420(ra) # 80001b8c <myproc>
    80002d38:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002d3a:	05853903          	ld	s2,88(a0)
    80002d3e:	0a893783          	ld	a5,168(s2)
    80002d42:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002d46:	37fd                	addiw	a5,a5,-1
    80002d48:	4751                	li	a4,20
    80002d4a:	00f76f63          	bltu	a4,a5,80002d68 <syscall+0x44>
    80002d4e:	00369713          	slli	a4,a3,0x3
    80002d52:	00005797          	auipc	a5,0x5
    80002d56:	6d678793          	addi	a5,a5,1750 # 80008428 <syscalls>
    80002d5a:	97ba                	add	a5,a5,a4
    80002d5c:	639c                	ld	a5,0(a5)
    80002d5e:	c789                	beqz	a5,80002d68 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002d60:	9782                	jalr	a5
    80002d62:	06a93823          	sd	a0,112(s2)
    80002d66:	a839                	j	80002d84 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d68:	15848613          	addi	a2,s1,344
    80002d6c:	5c8c                	lw	a1,56(s1)
    80002d6e:	00005517          	auipc	a0,0x5
    80002d72:	68250513          	addi	a0,a0,1666 # 800083f0 <states.1711+0x148>
    80002d76:	ffffe097          	auipc	ra,0xffffe
    80002d7a:	81c080e7          	jalr	-2020(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d7e:	6cbc                	ld	a5,88(s1)
    80002d80:	577d                	li	a4,-1
    80002d82:	fbb8                	sd	a4,112(a5)
  }
}
    80002d84:	60e2                	ld	ra,24(sp)
    80002d86:	6442                	ld	s0,16(sp)
    80002d88:	64a2                	ld	s1,8(sp)
    80002d8a:	6902                	ld	s2,0(sp)
    80002d8c:	6105                	addi	sp,sp,32
    80002d8e:	8082                	ret

0000000080002d90 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d90:	1101                	addi	sp,sp,-32
    80002d92:	ec06                	sd	ra,24(sp)
    80002d94:	e822                	sd	s0,16(sp)
    80002d96:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d98:	fec40593          	addi	a1,s0,-20
    80002d9c:	4501                	li	a0,0
    80002d9e:	00000097          	auipc	ra,0x0
    80002da2:	f12080e7          	jalr	-238(ra) # 80002cb0 <argint>
    return -1;
    80002da6:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002da8:	00054963          	bltz	a0,80002dba <sys_exit+0x2a>
  exit(n);
    80002dac:	fec42503          	lw	a0,-20(s0)
    80002db0:	fffff097          	auipc	ra,0xfffff
    80002db4:	4a6080e7          	jalr	1190(ra) # 80002256 <exit>
  return 0;  // not reached
    80002db8:	4781                	li	a5,0
}
    80002dba:	853e                	mv	a0,a5
    80002dbc:	60e2                	ld	ra,24(sp)
    80002dbe:	6442                	ld	s0,16(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002dc4:	1141                	addi	sp,sp,-16
    80002dc6:	e406                	sd	ra,8(sp)
    80002dc8:	e022                	sd	s0,0(sp)
    80002dca:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002dcc:	fffff097          	auipc	ra,0xfffff
    80002dd0:	dc0080e7          	jalr	-576(ra) # 80001b8c <myproc>
}
    80002dd4:	5d08                	lw	a0,56(a0)
    80002dd6:	60a2                	ld	ra,8(sp)
    80002dd8:	6402                	ld	s0,0(sp)
    80002dda:	0141                	addi	sp,sp,16
    80002ddc:	8082                	ret

0000000080002dde <sys_fork>:

uint64
sys_fork(void)
{
    80002dde:	1141                	addi	sp,sp,-16
    80002de0:	e406                	sd	ra,8(sp)
    80002de2:	e022                	sd	s0,0(sp)
    80002de4:	0800                	addi	s0,sp,16
  return fork();
    80002de6:	fffff097          	auipc	ra,0xfffff
    80002dea:	166080e7          	jalr	358(ra) # 80001f4c <fork>
}
    80002dee:	60a2                	ld	ra,8(sp)
    80002df0:	6402                	ld	s0,0(sp)
    80002df2:	0141                	addi	sp,sp,16
    80002df4:	8082                	ret

0000000080002df6 <sys_wait>:

uint64
sys_wait(void)
{
    80002df6:	1101                	addi	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002dfe:	fe840593          	addi	a1,s0,-24
    80002e02:	4501                	li	a0,0
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	ece080e7          	jalr	-306(ra) # 80002cd2 <argaddr>
    80002e0c:	87aa                	mv	a5,a0
    return -1;
    80002e0e:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002e10:	0007c863          	bltz	a5,80002e20 <sys_wait+0x2a>
  return wait(p);
    80002e14:	fe843503          	ld	a0,-24(s0)
    80002e18:	fffff097          	auipc	ra,0xfffff
    80002e1c:	602080e7          	jalr	1538(ra) # 8000241a <wait>
}
    80002e20:	60e2                	ld	ra,24(sp)
    80002e22:	6442                	ld	s0,16(sp)
    80002e24:	6105                	addi	sp,sp,32
    80002e26:	8082                	ret

0000000080002e28 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e28:	7179                	addi	sp,sp,-48
    80002e2a:	f406                	sd	ra,40(sp)
    80002e2c:	f022                	sd	s0,32(sp)
    80002e2e:	ec26                	sd	s1,24(sp)
    80002e30:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002e32:	fdc40593          	addi	a1,s0,-36
    80002e36:	4501                	li	a0,0
    80002e38:	00000097          	auipc	ra,0x0
    80002e3c:	e78080e7          	jalr	-392(ra) # 80002cb0 <argint>
    80002e40:	87aa                	mv	a5,a0
    return -1;
    80002e42:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002e44:	0207c063          	bltz	a5,80002e64 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002e48:	fffff097          	auipc	ra,0xfffff
    80002e4c:	d44080e7          	jalr	-700(ra) # 80001b8c <myproc>
    80002e50:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002e52:	fdc42503          	lw	a0,-36(s0)
    80002e56:	fffff097          	auipc	ra,0xfffff
    80002e5a:	082080e7          	jalr	130(ra) # 80001ed8 <growproc>
    80002e5e:	00054863          	bltz	a0,80002e6e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002e62:	8526                	mv	a0,s1
}
    80002e64:	70a2                	ld	ra,40(sp)
    80002e66:	7402                	ld	s0,32(sp)
    80002e68:	64e2                	ld	s1,24(sp)
    80002e6a:	6145                	addi	sp,sp,48
    80002e6c:	8082                	ret
    return -1;
    80002e6e:	557d                	li	a0,-1
    80002e70:	bfd5                	j	80002e64 <sys_sbrk+0x3c>

0000000080002e72 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e72:	7139                	addi	sp,sp,-64
    80002e74:	fc06                	sd	ra,56(sp)
    80002e76:	f822                	sd	s0,48(sp)
    80002e78:	f426                	sd	s1,40(sp)
    80002e7a:	f04a                	sd	s2,32(sp)
    80002e7c:	ec4e                	sd	s3,24(sp)
    80002e7e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e80:	fcc40593          	addi	a1,s0,-52
    80002e84:	4501                	li	a0,0
    80002e86:	00000097          	auipc	ra,0x0
    80002e8a:	e2a080e7          	jalr	-470(ra) # 80002cb0 <argint>
    return -1;
    80002e8e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e90:	06054563          	bltz	a0,80002efa <sys_sleep+0x88>
  acquire(&tickslock);
    80002e94:	00015517          	auipc	a0,0x15
    80002e98:	8dc50513          	addi	a0,a0,-1828 # 80017770 <tickslock>
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	e3a080e7          	jalr	-454(ra) # 80000cd6 <acquire>
  ticks0 = ticks;
    80002ea4:	00006917          	auipc	s2,0x6
    80002ea8:	17c92903          	lw	s2,380(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002eac:	fcc42783          	lw	a5,-52(s0)
    80002eb0:	cf85                	beqz	a5,80002ee8 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002eb2:	00015997          	auipc	s3,0x15
    80002eb6:	8be98993          	addi	s3,s3,-1858 # 80017770 <tickslock>
    80002eba:	00006497          	auipc	s1,0x6
    80002ebe:	16648493          	addi	s1,s1,358 # 80009020 <ticks>
    if(myproc()->killed){
    80002ec2:	fffff097          	auipc	ra,0xfffff
    80002ec6:	cca080e7          	jalr	-822(ra) # 80001b8c <myproc>
    80002eca:	591c                	lw	a5,48(a0)
    80002ecc:	ef9d                	bnez	a5,80002f0a <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002ece:	85ce                	mv	a1,s3
    80002ed0:	8526                	mv	a0,s1
    80002ed2:	fffff097          	auipc	ra,0xfffff
    80002ed6:	4ca080e7          	jalr	1226(ra) # 8000239c <sleep>
  while(ticks - ticks0 < n){
    80002eda:	409c                	lw	a5,0(s1)
    80002edc:	412787bb          	subw	a5,a5,s2
    80002ee0:	fcc42703          	lw	a4,-52(s0)
    80002ee4:	fce7efe3          	bltu	a5,a4,80002ec2 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002ee8:	00015517          	auipc	a0,0x15
    80002eec:	88850513          	addi	a0,a0,-1912 # 80017770 <tickslock>
    80002ef0:	ffffe097          	auipc	ra,0xffffe
    80002ef4:	e9a080e7          	jalr	-358(ra) # 80000d8a <release>
  return 0;
    80002ef8:	4781                	li	a5,0
}
    80002efa:	853e                	mv	a0,a5
    80002efc:	70e2                	ld	ra,56(sp)
    80002efe:	7442                	ld	s0,48(sp)
    80002f00:	74a2                	ld	s1,40(sp)
    80002f02:	7902                	ld	s2,32(sp)
    80002f04:	69e2                	ld	s3,24(sp)
    80002f06:	6121                	addi	sp,sp,64
    80002f08:	8082                	ret
      release(&tickslock);
    80002f0a:	00015517          	auipc	a0,0x15
    80002f0e:	86650513          	addi	a0,a0,-1946 # 80017770 <tickslock>
    80002f12:	ffffe097          	auipc	ra,0xffffe
    80002f16:	e78080e7          	jalr	-392(ra) # 80000d8a <release>
      return -1;
    80002f1a:	57fd                	li	a5,-1
    80002f1c:	bff9                	j	80002efa <sys_sleep+0x88>

0000000080002f1e <sys_kill>:

uint64
sys_kill(void)
{
    80002f1e:	1101                	addi	sp,sp,-32
    80002f20:	ec06                	sd	ra,24(sp)
    80002f22:	e822                	sd	s0,16(sp)
    80002f24:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002f26:	fec40593          	addi	a1,s0,-20
    80002f2a:	4501                	li	a0,0
    80002f2c:	00000097          	auipc	ra,0x0
    80002f30:	d84080e7          	jalr	-636(ra) # 80002cb0 <argint>
    80002f34:	87aa                	mv	a5,a0
    return -1;
    80002f36:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002f38:	0007c863          	bltz	a5,80002f48 <sys_kill+0x2a>
  return kill(pid);
    80002f3c:	fec42503          	lw	a0,-20(s0)
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	64c080e7          	jalr	1612(ra) # 8000258c <kill>
}
    80002f48:	60e2                	ld	ra,24(sp)
    80002f4a:	6442                	ld	s0,16(sp)
    80002f4c:	6105                	addi	sp,sp,32
    80002f4e:	8082                	ret

0000000080002f50 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f50:	1101                	addi	sp,sp,-32
    80002f52:	ec06                	sd	ra,24(sp)
    80002f54:	e822                	sd	s0,16(sp)
    80002f56:	e426                	sd	s1,8(sp)
    80002f58:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f5a:	00015517          	auipc	a0,0x15
    80002f5e:	81650513          	addi	a0,a0,-2026 # 80017770 <tickslock>
    80002f62:	ffffe097          	auipc	ra,0xffffe
    80002f66:	d74080e7          	jalr	-652(ra) # 80000cd6 <acquire>
  xticks = ticks;
    80002f6a:	00006497          	auipc	s1,0x6
    80002f6e:	0b64a483          	lw	s1,182(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f72:	00014517          	auipc	a0,0x14
    80002f76:	7fe50513          	addi	a0,a0,2046 # 80017770 <tickslock>
    80002f7a:	ffffe097          	auipc	ra,0xffffe
    80002f7e:	e10080e7          	jalr	-496(ra) # 80000d8a <release>
  return xticks;
}
    80002f82:	02049513          	slli	a0,s1,0x20
    80002f86:	9101                	srli	a0,a0,0x20
    80002f88:	60e2                	ld	ra,24(sp)
    80002f8a:	6442                	ld	s0,16(sp)
    80002f8c:	64a2                	ld	s1,8(sp)
    80002f8e:	6105                	addi	sp,sp,32
    80002f90:	8082                	ret

0000000080002f92 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f92:	7179                	addi	sp,sp,-48
    80002f94:	f406                	sd	ra,40(sp)
    80002f96:	f022                	sd	s0,32(sp)
    80002f98:	ec26                	sd	s1,24(sp)
    80002f9a:	e84a                	sd	s2,16(sp)
    80002f9c:	e44e                	sd	s3,8(sp)
    80002f9e:	e052                	sd	s4,0(sp)
    80002fa0:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002fa2:	00005597          	auipc	a1,0x5
    80002fa6:	53658593          	addi	a1,a1,1334 # 800084d8 <syscalls+0xb0>
    80002faa:	00014517          	auipc	a0,0x14
    80002fae:	7de50513          	addi	a0,a0,2014 # 80017788 <bcache>
    80002fb2:	ffffe097          	auipc	ra,0xffffe
    80002fb6:	c94080e7          	jalr	-876(ra) # 80000c46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002fba:	0001c797          	auipc	a5,0x1c
    80002fbe:	7ce78793          	addi	a5,a5,1998 # 8001f788 <bcache+0x8000>
    80002fc2:	0001d717          	auipc	a4,0x1d
    80002fc6:	a2e70713          	addi	a4,a4,-1490 # 8001f9f0 <bcache+0x8268>
    80002fca:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002fce:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fd2:	00014497          	auipc	s1,0x14
    80002fd6:	7ce48493          	addi	s1,s1,1998 # 800177a0 <bcache+0x18>
    b->next = bcache.head.next;
    80002fda:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002fdc:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002fde:	00005a17          	auipc	s4,0x5
    80002fe2:	502a0a13          	addi	s4,s4,1282 # 800084e0 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002fe6:	2b893783          	ld	a5,696(s2)
    80002fea:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002fec:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002ff0:	85d2                	mv	a1,s4
    80002ff2:	01048513          	addi	a0,s1,16
    80002ff6:	00001097          	auipc	ra,0x1
    80002ffa:	4b0080e7          	jalr	1200(ra) # 800044a6 <initsleeplock>
    bcache.head.next->prev = b;
    80002ffe:	2b893783          	ld	a5,696(s2)
    80003002:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003004:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003008:	45848493          	addi	s1,s1,1112
    8000300c:	fd349de3          	bne	s1,s3,80002fe6 <binit+0x54>
  }
}
    80003010:	70a2                	ld	ra,40(sp)
    80003012:	7402                	ld	s0,32(sp)
    80003014:	64e2                	ld	s1,24(sp)
    80003016:	6942                	ld	s2,16(sp)
    80003018:	69a2                	ld	s3,8(sp)
    8000301a:	6a02                	ld	s4,0(sp)
    8000301c:	6145                	addi	sp,sp,48
    8000301e:	8082                	ret

0000000080003020 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003020:	7179                	addi	sp,sp,-48
    80003022:	f406                	sd	ra,40(sp)
    80003024:	f022                	sd	s0,32(sp)
    80003026:	ec26                	sd	s1,24(sp)
    80003028:	e84a                	sd	s2,16(sp)
    8000302a:	e44e                	sd	s3,8(sp)
    8000302c:	1800                	addi	s0,sp,48
    8000302e:	89aa                	mv	s3,a0
    80003030:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003032:	00014517          	auipc	a0,0x14
    80003036:	75650513          	addi	a0,a0,1878 # 80017788 <bcache>
    8000303a:	ffffe097          	auipc	ra,0xffffe
    8000303e:	c9c080e7          	jalr	-868(ra) # 80000cd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003042:	0001d497          	auipc	s1,0x1d
    80003046:	9fe4b483          	ld	s1,-1538(s1) # 8001fa40 <bcache+0x82b8>
    8000304a:	0001d797          	auipc	a5,0x1d
    8000304e:	9a678793          	addi	a5,a5,-1626 # 8001f9f0 <bcache+0x8268>
    80003052:	02f48f63          	beq	s1,a5,80003090 <bread+0x70>
    80003056:	873e                	mv	a4,a5
    80003058:	a021                	j	80003060 <bread+0x40>
    8000305a:	68a4                	ld	s1,80(s1)
    8000305c:	02e48a63          	beq	s1,a4,80003090 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003060:	449c                	lw	a5,8(s1)
    80003062:	ff379ce3          	bne	a5,s3,8000305a <bread+0x3a>
    80003066:	44dc                	lw	a5,12(s1)
    80003068:	ff2799e3          	bne	a5,s2,8000305a <bread+0x3a>
      b->refcnt++;
    8000306c:	40bc                	lw	a5,64(s1)
    8000306e:	2785                	addiw	a5,a5,1
    80003070:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003072:	00014517          	auipc	a0,0x14
    80003076:	71650513          	addi	a0,a0,1814 # 80017788 <bcache>
    8000307a:	ffffe097          	auipc	ra,0xffffe
    8000307e:	d10080e7          	jalr	-752(ra) # 80000d8a <release>
      acquiresleep(&b->lock);
    80003082:	01048513          	addi	a0,s1,16
    80003086:	00001097          	auipc	ra,0x1
    8000308a:	45a080e7          	jalr	1114(ra) # 800044e0 <acquiresleep>
      return b;
    8000308e:	a8b9                	j	800030ec <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003090:	0001d497          	auipc	s1,0x1d
    80003094:	9a84b483          	ld	s1,-1624(s1) # 8001fa38 <bcache+0x82b0>
    80003098:	0001d797          	auipc	a5,0x1d
    8000309c:	95878793          	addi	a5,a5,-1704 # 8001f9f0 <bcache+0x8268>
    800030a0:	00f48863          	beq	s1,a5,800030b0 <bread+0x90>
    800030a4:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    800030a6:	40bc                	lw	a5,64(s1)
    800030a8:	cf81                	beqz	a5,800030c0 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    800030aa:	64a4                	ld	s1,72(s1)
    800030ac:	fee49de3          	bne	s1,a4,800030a6 <bread+0x86>
  panic("bget: no buffers");
    800030b0:	00005517          	auipc	a0,0x5
    800030b4:	43850513          	addi	a0,a0,1080 # 800084e8 <syscalls+0xc0>
    800030b8:	ffffd097          	auipc	ra,0xffffd
    800030bc:	490080e7          	jalr	1168(ra) # 80000548 <panic>
      b->dev = dev;
    800030c0:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    800030c4:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    800030c8:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    800030cc:	4785                	li	a5,1
    800030ce:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800030d0:	00014517          	auipc	a0,0x14
    800030d4:	6b850513          	addi	a0,a0,1720 # 80017788 <bcache>
    800030d8:	ffffe097          	auipc	ra,0xffffe
    800030dc:	cb2080e7          	jalr	-846(ra) # 80000d8a <release>
      acquiresleep(&b->lock);
    800030e0:	01048513          	addi	a0,s1,16
    800030e4:	00001097          	auipc	ra,0x1
    800030e8:	3fc080e7          	jalr	1020(ra) # 800044e0 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800030ec:	409c                	lw	a5,0(s1)
    800030ee:	cb89                	beqz	a5,80003100 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800030f0:	8526                	mv	a0,s1
    800030f2:	70a2                	ld	ra,40(sp)
    800030f4:	7402                	ld	s0,32(sp)
    800030f6:	64e2                	ld	s1,24(sp)
    800030f8:	6942                	ld	s2,16(sp)
    800030fa:	69a2                	ld	s3,8(sp)
    800030fc:	6145                	addi	sp,sp,48
    800030fe:	8082                	ret
    virtio_disk_rw(b, 0);
    80003100:	4581                	li	a1,0
    80003102:	8526                	mv	a0,s1
    80003104:	00003097          	auipc	ra,0x3
    80003108:	f38080e7          	jalr	-200(ra) # 8000603c <virtio_disk_rw>
    b->valid = 1;
    8000310c:	4785                	li	a5,1
    8000310e:	c09c                	sw	a5,0(s1)
  return b;
    80003110:	b7c5                	j	800030f0 <bread+0xd0>

0000000080003112 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003112:	1101                	addi	sp,sp,-32
    80003114:	ec06                	sd	ra,24(sp)
    80003116:	e822                	sd	s0,16(sp)
    80003118:	e426                	sd	s1,8(sp)
    8000311a:	1000                	addi	s0,sp,32
    8000311c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000311e:	0541                	addi	a0,a0,16
    80003120:	00001097          	auipc	ra,0x1
    80003124:	45a080e7          	jalr	1114(ra) # 8000457a <holdingsleep>
    80003128:	cd01                	beqz	a0,80003140 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000312a:	4585                	li	a1,1
    8000312c:	8526                	mv	a0,s1
    8000312e:	00003097          	auipc	ra,0x3
    80003132:	f0e080e7          	jalr	-242(ra) # 8000603c <virtio_disk_rw>
}
    80003136:	60e2                	ld	ra,24(sp)
    80003138:	6442                	ld	s0,16(sp)
    8000313a:	64a2                	ld	s1,8(sp)
    8000313c:	6105                	addi	sp,sp,32
    8000313e:	8082                	ret
    panic("bwrite");
    80003140:	00005517          	auipc	a0,0x5
    80003144:	3c050513          	addi	a0,a0,960 # 80008500 <syscalls+0xd8>
    80003148:	ffffd097          	auipc	ra,0xffffd
    8000314c:	400080e7          	jalr	1024(ra) # 80000548 <panic>

0000000080003150 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003150:	1101                	addi	sp,sp,-32
    80003152:	ec06                	sd	ra,24(sp)
    80003154:	e822                	sd	s0,16(sp)
    80003156:	e426                	sd	s1,8(sp)
    80003158:	e04a                	sd	s2,0(sp)
    8000315a:	1000                	addi	s0,sp,32
    8000315c:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000315e:	01050913          	addi	s2,a0,16
    80003162:	854a                	mv	a0,s2
    80003164:	00001097          	auipc	ra,0x1
    80003168:	416080e7          	jalr	1046(ra) # 8000457a <holdingsleep>
    8000316c:	c92d                	beqz	a0,800031de <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000316e:	854a                	mv	a0,s2
    80003170:	00001097          	auipc	ra,0x1
    80003174:	3c6080e7          	jalr	966(ra) # 80004536 <releasesleep>

  acquire(&bcache.lock);
    80003178:	00014517          	auipc	a0,0x14
    8000317c:	61050513          	addi	a0,a0,1552 # 80017788 <bcache>
    80003180:	ffffe097          	auipc	ra,0xffffe
    80003184:	b56080e7          	jalr	-1194(ra) # 80000cd6 <acquire>
  b->refcnt--;
    80003188:	40bc                	lw	a5,64(s1)
    8000318a:	37fd                	addiw	a5,a5,-1
    8000318c:	0007871b          	sext.w	a4,a5
    80003190:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003192:	eb05                	bnez	a4,800031c2 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003194:	68bc                	ld	a5,80(s1)
    80003196:	64b8                	ld	a4,72(s1)
    80003198:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000319a:	64bc                	ld	a5,72(s1)
    8000319c:	68b8                	ld	a4,80(s1)
    8000319e:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800031a0:	0001c797          	auipc	a5,0x1c
    800031a4:	5e878793          	addi	a5,a5,1512 # 8001f788 <bcache+0x8000>
    800031a8:	2b87b703          	ld	a4,696(a5)
    800031ac:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800031ae:	0001d717          	auipc	a4,0x1d
    800031b2:	84270713          	addi	a4,a4,-1982 # 8001f9f0 <bcache+0x8268>
    800031b6:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800031b8:	2b87b703          	ld	a4,696(a5)
    800031bc:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800031be:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800031c2:	00014517          	auipc	a0,0x14
    800031c6:	5c650513          	addi	a0,a0,1478 # 80017788 <bcache>
    800031ca:	ffffe097          	auipc	ra,0xffffe
    800031ce:	bc0080e7          	jalr	-1088(ra) # 80000d8a <release>
}
    800031d2:	60e2                	ld	ra,24(sp)
    800031d4:	6442                	ld	s0,16(sp)
    800031d6:	64a2                	ld	s1,8(sp)
    800031d8:	6902                	ld	s2,0(sp)
    800031da:	6105                	addi	sp,sp,32
    800031dc:	8082                	ret
    panic("brelse");
    800031de:	00005517          	auipc	a0,0x5
    800031e2:	32a50513          	addi	a0,a0,810 # 80008508 <syscalls+0xe0>
    800031e6:	ffffd097          	auipc	ra,0xffffd
    800031ea:	362080e7          	jalr	866(ra) # 80000548 <panic>

00000000800031ee <bpin>:

void
bpin(struct buf *b) {
    800031ee:	1101                	addi	sp,sp,-32
    800031f0:	ec06                	sd	ra,24(sp)
    800031f2:	e822                	sd	s0,16(sp)
    800031f4:	e426                	sd	s1,8(sp)
    800031f6:	1000                	addi	s0,sp,32
    800031f8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031fa:	00014517          	auipc	a0,0x14
    800031fe:	58e50513          	addi	a0,a0,1422 # 80017788 <bcache>
    80003202:	ffffe097          	auipc	ra,0xffffe
    80003206:	ad4080e7          	jalr	-1324(ra) # 80000cd6 <acquire>
  b->refcnt++;
    8000320a:	40bc                	lw	a5,64(s1)
    8000320c:	2785                	addiw	a5,a5,1
    8000320e:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	57850513          	addi	a0,a0,1400 # 80017788 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	b72080e7          	jalr	-1166(ra) # 80000d8a <release>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6105                	addi	sp,sp,32
    80003228:	8082                	ret

000000008000322a <bunpin>:

void
bunpin(struct buf *b) {
    8000322a:	1101                	addi	sp,sp,-32
    8000322c:	ec06                	sd	ra,24(sp)
    8000322e:	e822                	sd	s0,16(sp)
    80003230:	e426                	sd	s1,8(sp)
    80003232:	1000                	addi	s0,sp,32
    80003234:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003236:	00014517          	auipc	a0,0x14
    8000323a:	55250513          	addi	a0,a0,1362 # 80017788 <bcache>
    8000323e:	ffffe097          	auipc	ra,0xffffe
    80003242:	a98080e7          	jalr	-1384(ra) # 80000cd6 <acquire>
  b->refcnt--;
    80003246:	40bc                	lw	a5,64(s1)
    80003248:	37fd                	addiw	a5,a5,-1
    8000324a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000324c:	00014517          	auipc	a0,0x14
    80003250:	53c50513          	addi	a0,a0,1340 # 80017788 <bcache>
    80003254:	ffffe097          	auipc	ra,0xffffe
    80003258:	b36080e7          	jalr	-1226(ra) # 80000d8a <release>
}
    8000325c:	60e2                	ld	ra,24(sp)
    8000325e:	6442                	ld	s0,16(sp)
    80003260:	64a2                	ld	s1,8(sp)
    80003262:	6105                	addi	sp,sp,32
    80003264:	8082                	ret

0000000080003266 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003266:	1101                	addi	sp,sp,-32
    80003268:	ec06                	sd	ra,24(sp)
    8000326a:	e822                	sd	s0,16(sp)
    8000326c:	e426                	sd	s1,8(sp)
    8000326e:	e04a                	sd	s2,0(sp)
    80003270:	1000                	addi	s0,sp,32
    80003272:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003274:	00d5d59b          	srliw	a1,a1,0xd
    80003278:	0001d797          	auipc	a5,0x1d
    8000327c:	bec7a783          	lw	a5,-1044(a5) # 8001fe64 <sb+0x1c>
    80003280:	9dbd                	addw	a1,a1,a5
    80003282:	00000097          	auipc	ra,0x0
    80003286:	d9e080e7          	jalr	-610(ra) # 80003020 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000328a:	0074f713          	andi	a4,s1,7
    8000328e:	4785                	li	a5,1
    80003290:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003294:	14ce                	slli	s1,s1,0x33
    80003296:	90d9                	srli	s1,s1,0x36
    80003298:	00950733          	add	a4,a0,s1
    8000329c:	05874703          	lbu	a4,88(a4)
    800032a0:	00e7f6b3          	and	a3,a5,a4
    800032a4:	c69d                	beqz	a3,800032d2 <bfree+0x6c>
    800032a6:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800032a8:	94aa                	add	s1,s1,a0
    800032aa:	fff7c793          	not	a5,a5
    800032ae:	8ff9                	and	a5,a5,a4
    800032b0:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800032b4:	00001097          	auipc	ra,0x1
    800032b8:	104080e7          	jalr	260(ra) # 800043b8 <log_write>
  brelse(bp);
    800032bc:	854a                	mv	a0,s2
    800032be:	00000097          	auipc	ra,0x0
    800032c2:	e92080e7          	jalr	-366(ra) # 80003150 <brelse>
}
    800032c6:	60e2                	ld	ra,24(sp)
    800032c8:	6442                	ld	s0,16(sp)
    800032ca:	64a2                	ld	s1,8(sp)
    800032cc:	6902                	ld	s2,0(sp)
    800032ce:	6105                	addi	sp,sp,32
    800032d0:	8082                	ret
    panic("freeing free block");
    800032d2:	00005517          	auipc	a0,0x5
    800032d6:	23e50513          	addi	a0,a0,574 # 80008510 <syscalls+0xe8>
    800032da:	ffffd097          	auipc	ra,0xffffd
    800032de:	26e080e7          	jalr	622(ra) # 80000548 <panic>

00000000800032e2 <balloc>:
{
    800032e2:	711d                	addi	sp,sp,-96
    800032e4:	ec86                	sd	ra,88(sp)
    800032e6:	e8a2                	sd	s0,80(sp)
    800032e8:	e4a6                	sd	s1,72(sp)
    800032ea:	e0ca                	sd	s2,64(sp)
    800032ec:	fc4e                	sd	s3,56(sp)
    800032ee:	f852                	sd	s4,48(sp)
    800032f0:	f456                	sd	s5,40(sp)
    800032f2:	f05a                	sd	s6,32(sp)
    800032f4:	ec5e                	sd	s7,24(sp)
    800032f6:	e862                	sd	s8,16(sp)
    800032f8:	e466                	sd	s9,8(sp)
    800032fa:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800032fc:	0001d797          	auipc	a5,0x1d
    80003300:	b507a783          	lw	a5,-1200(a5) # 8001fe4c <sb+0x4>
    80003304:	cbd1                	beqz	a5,80003398 <balloc+0xb6>
    80003306:	8baa                	mv	s7,a0
    80003308:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000330a:	0001db17          	auipc	s6,0x1d
    8000330e:	b3eb0b13          	addi	s6,s6,-1218 # 8001fe48 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003312:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003314:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003316:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003318:	6c89                	lui	s9,0x2
    8000331a:	a831                	j	80003336 <balloc+0x54>
    brelse(bp);
    8000331c:	854a                	mv	a0,s2
    8000331e:	00000097          	auipc	ra,0x0
    80003322:	e32080e7          	jalr	-462(ra) # 80003150 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003326:	015c87bb          	addw	a5,s9,s5
    8000332a:	00078a9b          	sext.w	s5,a5
    8000332e:	004b2703          	lw	a4,4(s6)
    80003332:	06eaf363          	bgeu	s5,a4,80003398 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003336:	41fad79b          	sraiw	a5,s5,0x1f
    8000333a:	0137d79b          	srliw	a5,a5,0x13
    8000333e:	015787bb          	addw	a5,a5,s5
    80003342:	40d7d79b          	sraiw	a5,a5,0xd
    80003346:	01cb2583          	lw	a1,28(s6)
    8000334a:	9dbd                	addw	a1,a1,a5
    8000334c:	855e                	mv	a0,s7
    8000334e:	00000097          	auipc	ra,0x0
    80003352:	cd2080e7          	jalr	-814(ra) # 80003020 <bread>
    80003356:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003358:	004b2503          	lw	a0,4(s6)
    8000335c:	000a849b          	sext.w	s1,s5
    80003360:	8662                	mv	a2,s8
    80003362:	faa4fde3          	bgeu	s1,a0,8000331c <balloc+0x3a>
      m = 1 << (bi % 8);
    80003366:	41f6579b          	sraiw	a5,a2,0x1f
    8000336a:	01d7d69b          	srliw	a3,a5,0x1d
    8000336e:	00c6873b          	addw	a4,a3,a2
    80003372:	00777793          	andi	a5,a4,7
    80003376:	9f95                	subw	a5,a5,a3
    80003378:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    8000337c:	4037571b          	sraiw	a4,a4,0x3
    80003380:	00e906b3          	add	a3,s2,a4
    80003384:	0586c683          	lbu	a3,88(a3)
    80003388:	00d7f5b3          	and	a1,a5,a3
    8000338c:	cd91                	beqz	a1,800033a8 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000338e:	2605                	addiw	a2,a2,1
    80003390:	2485                	addiw	s1,s1,1
    80003392:	fd4618e3          	bne	a2,s4,80003362 <balloc+0x80>
    80003396:	b759                	j	8000331c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003398:	00005517          	auipc	a0,0x5
    8000339c:	19050513          	addi	a0,a0,400 # 80008528 <syscalls+0x100>
    800033a0:	ffffd097          	auipc	ra,0xffffd
    800033a4:	1a8080e7          	jalr	424(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033a8:	974a                	add	a4,a4,s2
    800033aa:	8fd5                	or	a5,a5,a3
    800033ac:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800033b0:	854a                	mv	a0,s2
    800033b2:	00001097          	auipc	ra,0x1
    800033b6:	006080e7          	jalr	6(ra) # 800043b8 <log_write>
        brelse(bp);
    800033ba:	854a                	mv	a0,s2
    800033bc:	00000097          	auipc	ra,0x0
    800033c0:	d94080e7          	jalr	-620(ra) # 80003150 <brelse>
  bp = bread(dev, bno);
    800033c4:	85a6                	mv	a1,s1
    800033c6:	855e                	mv	a0,s7
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	c58080e7          	jalr	-936(ra) # 80003020 <bread>
    800033d0:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033d2:	40000613          	li	a2,1024
    800033d6:	4581                	li	a1,0
    800033d8:	05850513          	addi	a0,a0,88
    800033dc:	ffffe097          	auipc	ra,0xffffe
    800033e0:	9f6080e7          	jalr	-1546(ra) # 80000dd2 <memset>
  log_write(bp);
    800033e4:	854a                	mv	a0,s2
    800033e6:	00001097          	auipc	ra,0x1
    800033ea:	fd2080e7          	jalr	-46(ra) # 800043b8 <log_write>
  brelse(bp);
    800033ee:	854a                	mv	a0,s2
    800033f0:	00000097          	auipc	ra,0x0
    800033f4:	d60080e7          	jalr	-672(ra) # 80003150 <brelse>
}
    800033f8:	8526                	mv	a0,s1
    800033fa:	60e6                	ld	ra,88(sp)
    800033fc:	6446                	ld	s0,80(sp)
    800033fe:	64a6                	ld	s1,72(sp)
    80003400:	6906                	ld	s2,64(sp)
    80003402:	79e2                	ld	s3,56(sp)
    80003404:	7a42                	ld	s4,48(sp)
    80003406:	7aa2                	ld	s5,40(sp)
    80003408:	7b02                	ld	s6,32(sp)
    8000340a:	6be2                	ld	s7,24(sp)
    8000340c:	6c42                	ld	s8,16(sp)
    8000340e:	6ca2                	ld	s9,8(sp)
    80003410:	6125                	addi	sp,sp,96
    80003412:	8082                	ret

0000000080003414 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003414:	7179                	addi	sp,sp,-48
    80003416:	f406                	sd	ra,40(sp)
    80003418:	f022                	sd	s0,32(sp)
    8000341a:	ec26                	sd	s1,24(sp)
    8000341c:	e84a                	sd	s2,16(sp)
    8000341e:	e44e                	sd	s3,8(sp)
    80003420:	e052                	sd	s4,0(sp)
    80003422:	1800                	addi	s0,sp,48
    80003424:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003426:	47ad                	li	a5,11
    80003428:	04b7fe63          	bgeu	a5,a1,80003484 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000342c:	ff45849b          	addiw	s1,a1,-12
    80003430:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003434:	0ff00793          	li	a5,255
    80003438:	0ae7e363          	bltu	a5,a4,800034de <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    8000343c:	08052583          	lw	a1,128(a0)
    80003440:	c5ad                	beqz	a1,800034aa <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003442:	00092503          	lw	a0,0(s2)
    80003446:	00000097          	auipc	ra,0x0
    8000344a:	bda080e7          	jalr	-1062(ra) # 80003020 <bread>
    8000344e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003450:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003454:	02049593          	slli	a1,s1,0x20
    80003458:	9181                	srli	a1,a1,0x20
    8000345a:	058a                	slli	a1,a1,0x2
    8000345c:	00b784b3          	add	s1,a5,a1
    80003460:	0004a983          	lw	s3,0(s1)
    80003464:	04098d63          	beqz	s3,800034be <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003468:	8552                	mv	a0,s4
    8000346a:	00000097          	auipc	ra,0x0
    8000346e:	ce6080e7          	jalr	-794(ra) # 80003150 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003472:	854e                	mv	a0,s3
    80003474:	70a2                	ld	ra,40(sp)
    80003476:	7402                	ld	s0,32(sp)
    80003478:	64e2                	ld	s1,24(sp)
    8000347a:	6942                	ld	s2,16(sp)
    8000347c:	69a2                	ld	s3,8(sp)
    8000347e:	6a02                	ld	s4,0(sp)
    80003480:	6145                	addi	sp,sp,48
    80003482:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003484:	02059493          	slli	s1,a1,0x20
    80003488:	9081                	srli	s1,s1,0x20
    8000348a:	048a                	slli	s1,s1,0x2
    8000348c:	94aa                	add	s1,s1,a0
    8000348e:	0504a983          	lw	s3,80(s1)
    80003492:	fe0990e3          	bnez	s3,80003472 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003496:	4108                	lw	a0,0(a0)
    80003498:	00000097          	auipc	ra,0x0
    8000349c:	e4a080e7          	jalr	-438(ra) # 800032e2 <balloc>
    800034a0:	0005099b          	sext.w	s3,a0
    800034a4:	0534a823          	sw	s3,80(s1)
    800034a8:	b7e9                	j	80003472 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800034aa:	4108                	lw	a0,0(a0)
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	e36080e7          	jalr	-458(ra) # 800032e2 <balloc>
    800034b4:	0005059b          	sext.w	a1,a0
    800034b8:	08b92023          	sw	a1,128(s2)
    800034bc:	b759                	j	80003442 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800034be:	00092503          	lw	a0,0(s2)
    800034c2:	00000097          	auipc	ra,0x0
    800034c6:	e20080e7          	jalr	-480(ra) # 800032e2 <balloc>
    800034ca:	0005099b          	sext.w	s3,a0
    800034ce:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800034d2:	8552                	mv	a0,s4
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	ee4080e7          	jalr	-284(ra) # 800043b8 <log_write>
    800034dc:	b771                	j	80003468 <bmap+0x54>
  panic("bmap: out of range");
    800034de:	00005517          	auipc	a0,0x5
    800034e2:	06250513          	addi	a0,a0,98 # 80008540 <syscalls+0x118>
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	062080e7          	jalr	98(ra) # 80000548 <panic>

00000000800034ee <iget>:
{
    800034ee:	7179                	addi	sp,sp,-48
    800034f0:	f406                	sd	ra,40(sp)
    800034f2:	f022                	sd	s0,32(sp)
    800034f4:	ec26                	sd	s1,24(sp)
    800034f6:	e84a                	sd	s2,16(sp)
    800034f8:	e44e                	sd	s3,8(sp)
    800034fa:	e052                	sd	s4,0(sp)
    800034fc:	1800                	addi	s0,sp,48
    800034fe:	89aa                	mv	s3,a0
    80003500:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003502:	0001d517          	auipc	a0,0x1d
    80003506:	96650513          	addi	a0,a0,-1690 # 8001fe68 <icache>
    8000350a:	ffffd097          	auipc	ra,0xffffd
    8000350e:	7cc080e7          	jalr	1996(ra) # 80000cd6 <acquire>
  empty = 0;
    80003512:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003514:	0001d497          	auipc	s1,0x1d
    80003518:	96c48493          	addi	s1,s1,-1684 # 8001fe80 <icache+0x18>
    8000351c:	0001e697          	auipc	a3,0x1e
    80003520:	3f468693          	addi	a3,a3,1012 # 80021910 <log>
    80003524:	a039                	j	80003532 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003526:	02090b63          	beqz	s2,8000355c <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000352a:	08848493          	addi	s1,s1,136
    8000352e:	02d48a63          	beq	s1,a3,80003562 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003532:	449c                	lw	a5,8(s1)
    80003534:	fef059e3          	blez	a5,80003526 <iget+0x38>
    80003538:	4098                	lw	a4,0(s1)
    8000353a:	ff3716e3          	bne	a4,s3,80003526 <iget+0x38>
    8000353e:	40d8                	lw	a4,4(s1)
    80003540:	ff4713e3          	bne	a4,s4,80003526 <iget+0x38>
      ip->ref++;
    80003544:	2785                	addiw	a5,a5,1
    80003546:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003548:	0001d517          	auipc	a0,0x1d
    8000354c:	92050513          	addi	a0,a0,-1760 # 8001fe68 <icache>
    80003550:	ffffe097          	auipc	ra,0xffffe
    80003554:	83a080e7          	jalr	-1990(ra) # 80000d8a <release>
      return ip;
    80003558:	8926                	mv	s2,s1
    8000355a:	a03d                	j	80003588 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000355c:	f7f9                	bnez	a5,8000352a <iget+0x3c>
    8000355e:	8926                	mv	s2,s1
    80003560:	b7e9                	j	8000352a <iget+0x3c>
  if(empty == 0)
    80003562:	02090c63          	beqz	s2,8000359a <iget+0xac>
  ip->dev = dev;
    80003566:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    8000356a:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000356e:	4785                	li	a5,1
    80003570:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003574:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003578:	0001d517          	auipc	a0,0x1d
    8000357c:	8f050513          	addi	a0,a0,-1808 # 8001fe68 <icache>
    80003580:	ffffe097          	auipc	ra,0xffffe
    80003584:	80a080e7          	jalr	-2038(ra) # 80000d8a <release>
}
    80003588:	854a                	mv	a0,s2
    8000358a:	70a2                	ld	ra,40(sp)
    8000358c:	7402                	ld	s0,32(sp)
    8000358e:	64e2                	ld	s1,24(sp)
    80003590:	6942                	ld	s2,16(sp)
    80003592:	69a2                	ld	s3,8(sp)
    80003594:	6a02                	ld	s4,0(sp)
    80003596:	6145                	addi	sp,sp,48
    80003598:	8082                	ret
    panic("iget: no inodes");
    8000359a:	00005517          	auipc	a0,0x5
    8000359e:	fbe50513          	addi	a0,a0,-66 # 80008558 <syscalls+0x130>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	fa6080e7          	jalr	-90(ra) # 80000548 <panic>

00000000800035aa <fsinit>:
fsinit(int dev) {
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	1800                	addi	s0,sp,48
    800035b8:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800035ba:	4585                	li	a1,1
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	a64080e7          	jalr	-1436(ra) # 80003020 <bread>
    800035c4:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800035c6:	0001d997          	auipc	s3,0x1d
    800035ca:	88298993          	addi	s3,s3,-1918 # 8001fe48 <sb>
    800035ce:	02000613          	li	a2,32
    800035d2:	05850593          	addi	a1,a0,88
    800035d6:	854e                	mv	a0,s3
    800035d8:	ffffe097          	auipc	ra,0xffffe
    800035dc:	85a080e7          	jalr	-1958(ra) # 80000e32 <memmove>
  brelse(bp);
    800035e0:	8526                	mv	a0,s1
    800035e2:	00000097          	auipc	ra,0x0
    800035e6:	b6e080e7          	jalr	-1170(ra) # 80003150 <brelse>
  if(sb.magic != FSMAGIC)
    800035ea:	0009a703          	lw	a4,0(s3)
    800035ee:	102037b7          	lui	a5,0x10203
    800035f2:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800035f6:	02f71263          	bne	a4,a5,8000361a <fsinit+0x70>
  initlog(dev, &sb);
    800035fa:	0001d597          	auipc	a1,0x1d
    800035fe:	84e58593          	addi	a1,a1,-1970 # 8001fe48 <sb>
    80003602:	854a                	mv	a0,s2
    80003604:	00001097          	auipc	ra,0x1
    80003608:	b3c080e7          	jalr	-1220(ra) # 80004140 <initlog>
}
    8000360c:	70a2                	ld	ra,40(sp)
    8000360e:	7402                	ld	s0,32(sp)
    80003610:	64e2                	ld	s1,24(sp)
    80003612:	6942                	ld	s2,16(sp)
    80003614:	69a2                	ld	s3,8(sp)
    80003616:	6145                	addi	sp,sp,48
    80003618:	8082                	ret
    panic("invalid file system");
    8000361a:	00005517          	auipc	a0,0x5
    8000361e:	f4e50513          	addi	a0,a0,-178 # 80008568 <syscalls+0x140>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f26080e7          	jalr	-218(ra) # 80000548 <panic>

000000008000362a <iinit>:
{
    8000362a:	7179                	addi	sp,sp,-48
    8000362c:	f406                	sd	ra,40(sp)
    8000362e:	f022                	sd	s0,32(sp)
    80003630:	ec26                	sd	s1,24(sp)
    80003632:	e84a                	sd	s2,16(sp)
    80003634:	e44e                	sd	s3,8(sp)
    80003636:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003638:	00005597          	auipc	a1,0x5
    8000363c:	f4858593          	addi	a1,a1,-184 # 80008580 <syscalls+0x158>
    80003640:	0001d517          	auipc	a0,0x1d
    80003644:	82850513          	addi	a0,a0,-2008 # 8001fe68 <icache>
    80003648:	ffffd097          	auipc	ra,0xffffd
    8000364c:	5fe080e7          	jalr	1534(ra) # 80000c46 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003650:	0001d497          	auipc	s1,0x1d
    80003654:	84048493          	addi	s1,s1,-1984 # 8001fe90 <icache+0x28>
    80003658:	0001e997          	auipc	s3,0x1e
    8000365c:	2c898993          	addi	s3,s3,712 # 80021920 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003660:	00005917          	auipc	s2,0x5
    80003664:	f2890913          	addi	s2,s2,-216 # 80008588 <syscalls+0x160>
    80003668:	85ca                	mv	a1,s2
    8000366a:	8526                	mv	a0,s1
    8000366c:	00001097          	auipc	ra,0x1
    80003670:	e3a080e7          	jalr	-454(ra) # 800044a6 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003674:	08848493          	addi	s1,s1,136
    80003678:	ff3498e3          	bne	s1,s3,80003668 <iinit+0x3e>
}
    8000367c:	70a2                	ld	ra,40(sp)
    8000367e:	7402                	ld	s0,32(sp)
    80003680:	64e2                	ld	s1,24(sp)
    80003682:	6942                	ld	s2,16(sp)
    80003684:	69a2                	ld	s3,8(sp)
    80003686:	6145                	addi	sp,sp,48
    80003688:	8082                	ret

000000008000368a <ialloc>:
{
    8000368a:	715d                	addi	sp,sp,-80
    8000368c:	e486                	sd	ra,72(sp)
    8000368e:	e0a2                	sd	s0,64(sp)
    80003690:	fc26                	sd	s1,56(sp)
    80003692:	f84a                	sd	s2,48(sp)
    80003694:	f44e                	sd	s3,40(sp)
    80003696:	f052                	sd	s4,32(sp)
    80003698:	ec56                	sd	s5,24(sp)
    8000369a:	e85a                	sd	s6,16(sp)
    8000369c:	e45e                	sd	s7,8(sp)
    8000369e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800036a0:	0001c717          	auipc	a4,0x1c
    800036a4:	7b472703          	lw	a4,1972(a4) # 8001fe54 <sb+0xc>
    800036a8:	4785                	li	a5,1
    800036aa:	04e7fa63          	bgeu	a5,a4,800036fe <ialloc+0x74>
    800036ae:	8aaa                	mv	s5,a0
    800036b0:	8bae                	mv	s7,a1
    800036b2:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800036b4:	0001ca17          	auipc	s4,0x1c
    800036b8:	794a0a13          	addi	s4,s4,1940 # 8001fe48 <sb>
    800036bc:	00048b1b          	sext.w	s6,s1
    800036c0:	0044d593          	srli	a1,s1,0x4
    800036c4:	018a2783          	lw	a5,24(s4)
    800036c8:	9dbd                	addw	a1,a1,a5
    800036ca:	8556                	mv	a0,s5
    800036cc:	00000097          	auipc	ra,0x0
    800036d0:	954080e7          	jalr	-1708(ra) # 80003020 <bread>
    800036d4:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800036d6:	05850993          	addi	s3,a0,88
    800036da:	00f4f793          	andi	a5,s1,15
    800036de:	079a                	slli	a5,a5,0x6
    800036e0:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800036e2:	00099783          	lh	a5,0(s3)
    800036e6:	c785                	beqz	a5,8000370e <ialloc+0x84>
    brelse(bp);
    800036e8:	00000097          	auipc	ra,0x0
    800036ec:	a68080e7          	jalr	-1432(ra) # 80003150 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800036f0:	0485                	addi	s1,s1,1
    800036f2:	00ca2703          	lw	a4,12(s4)
    800036f6:	0004879b          	sext.w	a5,s1
    800036fa:	fce7e1e3          	bltu	a5,a4,800036bc <ialloc+0x32>
  panic("ialloc: no inodes");
    800036fe:	00005517          	auipc	a0,0x5
    80003702:	e9250513          	addi	a0,a0,-366 # 80008590 <syscalls+0x168>
    80003706:	ffffd097          	auipc	ra,0xffffd
    8000370a:	e42080e7          	jalr	-446(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000370e:	04000613          	li	a2,64
    80003712:	4581                	li	a1,0
    80003714:	854e                	mv	a0,s3
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	6bc080e7          	jalr	1724(ra) # 80000dd2 <memset>
      dip->type = type;
    8000371e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	c94080e7          	jalr	-876(ra) # 800043b8 <log_write>
      brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	a22080e7          	jalr	-1502(ra) # 80003150 <brelse>
      return iget(dev, inum);
    80003736:	85da                	mv	a1,s6
    80003738:	8556                	mv	a0,s5
    8000373a:	00000097          	auipc	ra,0x0
    8000373e:	db4080e7          	jalr	-588(ra) # 800034ee <iget>
}
    80003742:	60a6                	ld	ra,72(sp)
    80003744:	6406                	ld	s0,64(sp)
    80003746:	74e2                	ld	s1,56(sp)
    80003748:	7942                	ld	s2,48(sp)
    8000374a:	79a2                	ld	s3,40(sp)
    8000374c:	7a02                	ld	s4,32(sp)
    8000374e:	6ae2                	ld	s5,24(sp)
    80003750:	6b42                	ld	s6,16(sp)
    80003752:	6ba2                	ld	s7,8(sp)
    80003754:	6161                	addi	sp,sp,80
    80003756:	8082                	ret

0000000080003758 <iupdate>:
{
    80003758:	1101                	addi	sp,sp,-32
    8000375a:	ec06                	sd	ra,24(sp)
    8000375c:	e822                	sd	s0,16(sp)
    8000375e:	e426                	sd	s1,8(sp)
    80003760:	e04a                	sd	s2,0(sp)
    80003762:	1000                	addi	s0,sp,32
    80003764:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003766:	415c                	lw	a5,4(a0)
    80003768:	0047d79b          	srliw	a5,a5,0x4
    8000376c:	0001c597          	auipc	a1,0x1c
    80003770:	6f45a583          	lw	a1,1780(a1) # 8001fe60 <sb+0x18>
    80003774:	9dbd                	addw	a1,a1,a5
    80003776:	4108                	lw	a0,0(a0)
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	8a8080e7          	jalr	-1880(ra) # 80003020 <bread>
    80003780:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003782:	05850793          	addi	a5,a0,88
    80003786:	40c8                	lw	a0,4(s1)
    80003788:	893d                	andi	a0,a0,15
    8000378a:	051a                	slli	a0,a0,0x6
    8000378c:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000378e:	04449703          	lh	a4,68(s1)
    80003792:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003796:	04649703          	lh	a4,70(s1)
    8000379a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000379e:	04849703          	lh	a4,72(s1)
    800037a2:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800037a6:	04a49703          	lh	a4,74(s1)
    800037aa:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800037ae:	44f8                	lw	a4,76(s1)
    800037b0:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800037b2:	03400613          	li	a2,52
    800037b6:	05048593          	addi	a1,s1,80
    800037ba:	0531                	addi	a0,a0,12
    800037bc:	ffffd097          	auipc	ra,0xffffd
    800037c0:	676080e7          	jalr	1654(ra) # 80000e32 <memmove>
  log_write(bp);
    800037c4:	854a                	mv	a0,s2
    800037c6:	00001097          	auipc	ra,0x1
    800037ca:	bf2080e7          	jalr	-1038(ra) # 800043b8 <log_write>
  brelse(bp);
    800037ce:	854a                	mv	a0,s2
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	980080e7          	jalr	-1664(ra) # 80003150 <brelse>
}
    800037d8:	60e2                	ld	ra,24(sp)
    800037da:	6442                	ld	s0,16(sp)
    800037dc:	64a2                	ld	s1,8(sp)
    800037de:	6902                	ld	s2,0(sp)
    800037e0:	6105                	addi	sp,sp,32
    800037e2:	8082                	ret

00000000800037e4 <idup>:
{
    800037e4:	1101                	addi	sp,sp,-32
    800037e6:	ec06                	sd	ra,24(sp)
    800037e8:	e822                	sd	s0,16(sp)
    800037ea:	e426                	sd	s1,8(sp)
    800037ec:	1000                	addi	s0,sp,32
    800037ee:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800037f0:	0001c517          	auipc	a0,0x1c
    800037f4:	67850513          	addi	a0,a0,1656 # 8001fe68 <icache>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	4de080e7          	jalr	1246(ra) # 80000cd6 <acquire>
  ip->ref++;
    80003800:	449c                	lw	a5,8(s1)
    80003802:	2785                	addiw	a5,a5,1
    80003804:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003806:	0001c517          	auipc	a0,0x1c
    8000380a:	66250513          	addi	a0,a0,1634 # 8001fe68 <icache>
    8000380e:	ffffd097          	auipc	ra,0xffffd
    80003812:	57c080e7          	jalr	1404(ra) # 80000d8a <release>
}
    80003816:	8526                	mv	a0,s1
    80003818:	60e2                	ld	ra,24(sp)
    8000381a:	6442                	ld	s0,16(sp)
    8000381c:	64a2                	ld	s1,8(sp)
    8000381e:	6105                	addi	sp,sp,32
    80003820:	8082                	ret

0000000080003822 <ilock>:
{
    80003822:	1101                	addi	sp,sp,-32
    80003824:	ec06                	sd	ra,24(sp)
    80003826:	e822                	sd	s0,16(sp)
    80003828:	e426                	sd	s1,8(sp)
    8000382a:	e04a                	sd	s2,0(sp)
    8000382c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000382e:	c115                	beqz	a0,80003852 <ilock+0x30>
    80003830:	84aa                	mv	s1,a0
    80003832:	451c                	lw	a5,8(a0)
    80003834:	00f05f63          	blez	a5,80003852 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003838:	0541                	addi	a0,a0,16
    8000383a:	00001097          	auipc	ra,0x1
    8000383e:	ca6080e7          	jalr	-858(ra) # 800044e0 <acquiresleep>
  if(ip->valid == 0){
    80003842:	40bc                	lw	a5,64(s1)
    80003844:	cf99                	beqz	a5,80003862 <ilock+0x40>
}
    80003846:	60e2                	ld	ra,24(sp)
    80003848:	6442                	ld	s0,16(sp)
    8000384a:	64a2                	ld	s1,8(sp)
    8000384c:	6902                	ld	s2,0(sp)
    8000384e:	6105                	addi	sp,sp,32
    80003850:	8082                	ret
    panic("ilock");
    80003852:	00005517          	auipc	a0,0x5
    80003856:	d5650513          	addi	a0,a0,-682 # 800085a8 <syscalls+0x180>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	cee080e7          	jalr	-786(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003862:	40dc                	lw	a5,4(s1)
    80003864:	0047d79b          	srliw	a5,a5,0x4
    80003868:	0001c597          	auipc	a1,0x1c
    8000386c:	5f85a583          	lw	a1,1528(a1) # 8001fe60 <sb+0x18>
    80003870:	9dbd                	addw	a1,a1,a5
    80003872:	4088                	lw	a0,0(s1)
    80003874:	fffff097          	auipc	ra,0xfffff
    80003878:	7ac080e7          	jalr	1964(ra) # 80003020 <bread>
    8000387c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000387e:	05850593          	addi	a1,a0,88
    80003882:	40dc                	lw	a5,4(s1)
    80003884:	8bbd                	andi	a5,a5,15
    80003886:	079a                	slli	a5,a5,0x6
    80003888:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000388a:	00059783          	lh	a5,0(a1)
    8000388e:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003892:	00259783          	lh	a5,2(a1)
    80003896:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    8000389a:	00459783          	lh	a5,4(a1)
    8000389e:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800038a2:	00659783          	lh	a5,6(a1)
    800038a6:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800038aa:	459c                	lw	a5,8(a1)
    800038ac:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800038ae:	03400613          	li	a2,52
    800038b2:	05b1                	addi	a1,a1,12
    800038b4:	05048513          	addi	a0,s1,80
    800038b8:	ffffd097          	auipc	ra,0xffffd
    800038bc:	57a080e7          	jalr	1402(ra) # 80000e32 <memmove>
    brelse(bp);
    800038c0:	854a                	mv	a0,s2
    800038c2:	00000097          	auipc	ra,0x0
    800038c6:	88e080e7          	jalr	-1906(ra) # 80003150 <brelse>
    ip->valid = 1;
    800038ca:	4785                	li	a5,1
    800038cc:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800038ce:	04449783          	lh	a5,68(s1)
    800038d2:	fbb5                	bnez	a5,80003846 <ilock+0x24>
      panic("ilock: no type");
    800038d4:	00005517          	auipc	a0,0x5
    800038d8:	cdc50513          	addi	a0,a0,-804 # 800085b0 <syscalls+0x188>
    800038dc:	ffffd097          	auipc	ra,0xffffd
    800038e0:	c6c080e7          	jalr	-916(ra) # 80000548 <panic>

00000000800038e4 <iunlock>:
{
    800038e4:	1101                	addi	sp,sp,-32
    800038e6:	ec06                	sd	ra,24(sp)
    800038e8:	e822                	sd	s0,16(sp)
    800038ea:	e426                	sd	s1,8(sp)
    800038ec:	e04a                	sd	s2,0(sp)
    800038ee:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800038f0:	c905                	beqz	a0,80003920 <iunlock+0x3c>
    800038f2:	84aa                	mv	s1,a0
    800038f4:	01050913          	addi	s2,a0,16
    800038f8:	854a                	mv	a0,s2
    800038fa:	00001097          	auipc	ra,0x1
    800038fe:	c80080e7          	jalr	-896(ra) # 8000457a <holdingsleep>
    80003902:	cd19                	beqz	a0,80003920 <iunlock+0x3c>
    80003904:	449c                	lw	a5,8(s1)
    80003906:	00f05d63          	blez	a5,80003920 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000390a:	854a                	mv	a0,s2
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	c2a080e7          	jalr	-982(ra) # 80004536 <releasesleep>
}
    80003914:	60e2                	ld	ra,24(sp)
    80003916:	6442                	ld	s0,16(sp)
    80003918:	64a2                	ld	s1,8(sp)
    8000391a:	6902                	ld	s2,0(sp)
    8000391c:	6105                	addi	sp,sp,32
    8000391e:	8082                	ret
    panic("iunlock");
    80003920:	00005517          	auipc	a0,0x5
    80003924:	ca050513          	addi	a0,a0,-864 # 800085c0 <syscalls+0x198>
    80003928:	ffffd097          	auipc	ra,0xffffd
    8000392c:	c20080e7          	jalr	-992(ra) # 80000548 <panic>

0000000080003930 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003930:	7179                	addi	sp,sp,-48
    80003932:	f406                	sd	ra,40(sp)
    80003934:	f022                	sd	s0,32(sp)
    80003936:	ec26                	sd	s1,24(sp)
    80003938:	e84a                	sd	s2,16(sp)
    8000393a:	e44e                	sd	s3,8(sp)
    8000393c:	e052                	sd	s4,0(sp)
    8000393e:	1800                	addi	s0,sp,48
    80003940:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003942:	05050493          	addi	s1,a0,80
    80003946:	08050913          	addi	s2,a0,128
    8000394a:	a021                	j	80003952 <itrunc+0x22>
    8000394c:	0491                	addi	s1,s1,4
    8000394e:	01248d63          	beq	s1,s2,80003968 <itrunc+0x38>
    if(ip->addrs[i]){
    80003952:	408c                	lw	a1,0(s1)
    80003954:	dde5                	beqz	a1,8000394c <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003956:	0009a503          	lw	a0,0(s3)
    8000395a:	00000097          	auipc	ra,0x0
    8000395e:	90c080e7          	jalr	-1780(ra) # 80003266 <bfree>
      ip->addrs[i] = 0;
    80003962:	0004a023          	sw	zero,0(s1)
    80003966:	b7dd                	j	8000394c <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003968:	0809a583          	lw	a1,128(s3)
    8000396c:	e185                	bnez	a1,8000398c <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000396e:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003972:	854e                	mv	a0,s3
    80003974:	00000097          	auipc	ra,0x0
    80003978:	de4080e7          	jalr	-540(ra) # 80003758 <iupdate>
}
    8000397c:	70a2                	ld	ra,40(sp)
    8000397e:	7402                	ld	s0,32(sp)
    80003980:	64e2                	ld	s1,24(sp)
    80003982:	6942                	ld	s2,16(sp)
    80003984:	69a2                	ld	s3,8(sp)
    80003986:	6a02                	ld	s4,0(sp)
    80003988:	6145                	addi	sp,sp,48
    8000398a:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000398c:	0009a503          	lw	a0,0(s3)
    80003990:	fffff097          	auipc	ra,0xfffff
    80003994:	690080e7          	jalr	1680(ra) # 80003020 <bread>
    80003998:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    8000399a:	05850493          	addi	s1,a0,88
    8000399e:	45850913          	addi	s2,a0,1112
    800039a2:	a811                	j	800039b6 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800039a4:	0009a503          	lw	a0,0(s3)
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	8be080e7          	jalr	-1858(ra) # 80003266 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800039b0:	0491                	addi	s1,s1,4
    800039b2:	01248563          	beq	s1,s2,800039bc <itrunc+0x8c>
      if(a[j])
    800039b6:	408c                	lw	a1,0(s1)
    800039b8:	dde5                	beqz	a1,800039b0 <itrunc+0x80>
    800039ba:	b7ed                	j	800039a4 <itrunc+0x74>
    brelse(bp);
    800039bc:	8552                	mv	a0,s4
    800039be:	fffff097          	auipc	ra,0xfffff
    800039c2:	792080e7          	jalr	1938(ra) # 80003150 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800039c6:	0809a583          	lw	a1,128(s3)
    800039ca:	0009a503          	lw	a0,0(s3)
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	898080e7          	jalr	-1896(ra) # 80003266 <bfree>
    ip->addrs[NDIRECT] = 0;
    800039d6:	0809a023          	sw	zero,128(s3)
    800039da:	bf51                	j	8000396e <itrunc+0x3e>

00000000800039dc <iput>:
{
    800039dc:	1101                	addi	sp,sp,-32
    800039de:	ec06                	sd	ra,24(sp)
    800039e0:	e822                	sd	s0,16(sp)
    800039e2:	e426                	sd	s1,8(sp)
    800039e4:	e04a                	sd	s2,0(sp)
    800039e6:	1000                	addi	s0,sp,32
    800039e8:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    800039ea:	0001c517          	auipc	a0,0x1c
    800039ee:	47e50513          	addi	a0,a0,1150 # 8001fe68 <icache>
    800039f2:	ffffd097          	auipc	ra,0xffffd
    800039f6:	2e4080e7          	jalr	740(ra) # 80000cd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039fa:	4498                	lw	a4,8(s1)
    800039fc:	4785                	li	a5,1
    800039fe:	02f70363          	beq	a4,a5,80003a24 <iput+0x48>
  ip->ref--;
    80003a02:	449c                	lw	a5,8(s1)
    80003a04:	37fd                	addiw	a5,a5,-1
    80003a06:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003a08:	0001c517          	auipc	a0,0x1c
    80003a0c:	46050513          	addi	a0,a0,1120 # 8001fe68 <icache>
    80003a10:	ffffd097          	auipc	ra,0xffffd
    80003a14:	37a080e7          	jalr	890(ra) # 80000d8a <release>
}
    80003a18:	60e2                	ld	ra,24(sp)
    80003a1a:	6442                	ld	s0,16(sp)
    80003a1c:	64a2                	ld	s1,8(sp)
    80003a1e:	6902                	ld	s2,0(sp)
    80003a20:	6105                	addi	sp,sp,32
    80003a22:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003a24:	40bc                	lw	a5,64(s1)
    80003a26:	dff1                	beqz	a5,80003a02 <iput+0x26>
    80003a28:	04a49783          	lh	a5,74(s1)
    80003a2c:	fbf9                	bnez	a5,80003a02 <iput+0x26>
    acquiresleep(&ip->lock);
    80003a2e:	01048913          	addi	s2,s1,16
    80003a32:	854a                	mv	a0,s2
    80003a34:	00001097          	auipc	ra,0x1
    80003a38:	aac080e7          	jalr	-1364(ra) # 800044e0 <acquiresleep>
    release(&icache.lock);
    80003a3c:	0001c517          	auipc	a0,0x1c
    80003a40:	42c50513          	addi	a0,a0,1068 # 8001fe68 <icache>
    80003a44:	ffffd097          	auipc	ra,0xffffd
    80003a48:	346080e7          	jalr	838(ra) # 80000d8a <release>
    itrunc(ip);
    80003a4c:	8526                	mv	a0,s1
    80003a4e:	00000097          	auipc	ra,0x0
    80003a52:	ee2080e7          	jalr	-286(ra) # 80003930 <itrunc>
    ip->type = 0;
    80003a56:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003a5a:	8526                	mv	a0,s1
    80003a5c:	00000097          	auipc	ra,0x0
    80003a60:	cfc080e7          	jalr	-772(ra) # 80003758 <iupdate>
    ip->valid = 0;
    80003a64:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a68:	854a                	mv	a0,s2
    80003a6a:	00001097          	auipc	ra,0x1
    80003a6e:	acc080e7          	jalr	-1332(ra) # 80004536 <releasesleep>
    acquire(&icache.lock);
    80003a72:	0001c517          	auipc	a0,0x1c
    80003a76:	3f650513          	addi	a0,a0,1014 # 8001fe68 <icache>
    80003a7a:	ffffd097          	auipc	ra,0xffffd
    80003a7e:	25c080e7          	jalr	604(ra) # 80000cd6 <acquire>
    80003a82:	b741                	j	80003a02 <iput+0x26>

0000000080003a84 <iunlockput>:
{
    80003a84:	1101                	addi	sp,sp,-32
    80003a86:	ec06                	sd	ra,24(sp)
    80003a88:	e822                	sd	s0,16(sp)
    80003a8a:	e426                	sd	s1,8(sp)
    80003a8c:	1000                	addi	s0,sp,32
    80003a8e:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a90:	00000097          	auipc	ra,0x0
    80003a94:	e54080e7          	jalr	-428(ra) # 800038e4 <iunlock>
  iput(ip);
    80003a98:	8526                	mv	a0,s1
    80003a9a:	00000097          	auipc	ra,0x0
    80003a9e:	f42080e7          	jalr	-190(ra) # 800039dc <iput>
}
    80003aa2:	60e2                	ld	ra,24(sp)
    80003aa4:	6442                	ld	s0,16(sp)
    80003aa6:	64a2                	ld	s1,8(sp)
    80003aa8:	6105                	addi	sp,sp,32
    80003aaa:	8082                	ret

0000000080003aac <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003aac:	1141                	addi	sp,sp,-16
    80003aae:	e422                	sd	s0,8(sp)
    80003ab0:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003ab2:	411c                	lw	a5,0(a0)
    80003ab4:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003ab6:	415c                	lw	a5,4(a0)
    80003ab8:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003aba:	04451783          	lh	a5,68(a0)
    80003abe:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003ac2:	04a51783          	lh	a5,74(a0)
    80003ac6:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003aca:	04c56783          	lwu	a5,76(a0)
    80003ace:	e99c                	sd	a5,16(a1)
}
    80003ad0:	6422                	ld	s0,8(sp)
    80003ad2:	0141                	addi	sp,sp,16
    80003ad4:	8082                	ret

0000000080003ad6 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ad6:	457c                	lw	a5,76(a0)
    80003ad8:	0ed7e963          	bltu	a5,a3,80003bca <readi+0xf4>
{
    80003adc:	7159                	addi	sp,sp,-112
    80003ade:	f486                	sd	ra,104(sp)
    80003ae0:	f0a2                	sd	s0,96(sp)
    80003ae2:	eca6                	sd	s1,88(sp)
    80003ae4:	e8ca                	sd	s2,80(sp)
    80003ae6:	e4ce                	sd	s3,72(sp)
    80003ae8:	e0d2                	sd	s4,64(sp)
    80003aea:	fc56                	sd	s5,56(sp)
    80003aec:	f85a                	sd	s6,48(sp)
    80003aee:	f45e                	sd	s7,40(sp)
    80003af0:	f062                	sd	s8,32(sp)
    80003af2:	ec66                	sd	s9,24(sp)
    80003af4:	e86a                	sd	s10,16(sp)
    80003af6:	e46e                	sd	s11,8(sp)
    80003af8:	1880                	addi	s0,sp,112
    80003afa:	8baa                	mv	s7,a0
    80003afc:	8c2e                	mv	s8,a1
    80003afe:	8ab2                	mv	s5,a2
    80003b00:	84b6                	mv	s1,a3
    80003b02:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b04:	9f35                	addw	a4,a4,a3
    return 0;
    80003b06:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003b08:	0ad76063          	bltu	a4,a3,80003ba8 <readi+0xd2>
  if(off + n > ip->size)
    80003b0c:	00e7f463          	bgeu	a5,a4,80003b14 <readi+0x3e>
    n = ip->size - off;
    80003b10:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b14:	0a0b0963          	beqz	s6,80003bc6 <readi+0xf0>
    80003b18:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b1a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003b1e:	5cfd                	li	s9,-1
    80003b20:	a82d                	j	80003b5a <readi+0x84>
    80003b22:	020a1d93          	slli	s11,s4,0x20
    80003b26:	020ddd93          	srli	s11,s11,0x20
    80003b2a:	05890613          	addi	a2,s2,88
    80003b2e:	86ee                	mv	a3,s11
    80003b30:	963a                	add	a2,a2,a4
    80003b32:	85d6                	mv	a1,s5
    80003b34:	8562                	mv	a0,s8
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	ac8080e7          	jalr	-1336(ra) # 800025fe <either_copyout>
    80003b3e:	05950d63          	beq	a0,s9,80003b98 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003b42:	854a                	mv	a0,s2
    80003b44:	fffff097          	auipc	ra,0xfffff
    80003b48:	60c080e7          	jalr	1548(ra) # 80003150 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b4c:	013a09bb          	addw	s3,s4,s3
    80003b50:	009a04bb          	addw	s1,s4,s1
    80003b54:	9aee                	add	s5,s5,s11
    80003b56:	0569f763          	bgeu	s3,s6,80003ba4 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b5a:	000ba903          	lw	s2,0(s7)
    80003b5e:	00a4d59b          	srliw	a1,s1,0xa
    80003b62:	855e                	mv	a0,s7
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	8b0080e7          	jalr	-1872(ra) # 80003414 <bmap>
    80003b6c:	0005059b          	sext.w	a1,a0
    80003b70:	854a                	mv	a0,s2
    80003b72:	fffff097          	auipc	ra,0xfffff
    80003b76:	4ae080e7          	jalr	1198(ra) # 80003020 <bread>
    80003b7a:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b7c:	3ff4f713          	andi	a4,s1,1023
    80003b80:	40ed07bb          	subw	a5,s10,a4
    80003b84:	413b06bb          	subw	a3,s6,s3
    80003b88:	8a3e                	mv	s4,a5
    80003b8a:	2781                	sext.w	a5,a5
    80003b8c:	0006861b          	sext.w	a2,a3
    80003b90:	f8f679e3          	bgeu	a2,a5,80003b22 <readi+0x4c>
    80003b94:	8a36                	mv	s4,a3
    80003b96:	b771                	j	80003b22 <readi+0x4c>
      brelse(bp);
    80003b98:	854a                	mv	a0,s2
    80003b9a:	fffff097          	auipc	ra,0xfffff
    80003b9e:	5b6080e7          	jalr	1462(ra) # 80003150 <brelse>
      tot = -1;
    80003ba2:	59fd                	li	s3,-1
  }
  return tot;
    80003ba4:	0009851b          	sext.w	a0,s3
}
    80003ba8:	70a6                	ld	ra,104(sp)
    80003baa:	7406                	ld	s0,96(sp)
    80003bac:	64e6                	ld	s1,88(sp)
    80003bae:	6946                	ld	s2,80(sp)
    80003bb0:	69a6                	ld	s3,72(sp)
    80003bb2:	6a06                	ld	s4,64(sp)
    80003bb4:	7ae2                	ld	s5,56(sp)
    80003bb6:	7b42                	ld	s6,48(sp)
    80003bb8:	7ba2                	ld	s7,40(sp)
    80003bba:	7c02                	ld	s8,32(sp)
    80003bbc:	6ce2                	ld	s9,24(sp)
    80003bbe:	6d42                	ld	s10,16(sp)
    80003bc0:	6da2                	ld	s11,8(sp)
    80003bc2:	6165                	addi	sp,sp,112
    80003bc4:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc6:	89da                	mv	s3,s6
    80003bc8:	bff1                	j	80003ba4 <readi+0xce>
    return 0;
    80003bca:	4501                	li	a0,0
}
    80003bcc:	8082                	ret

0000000080003bce <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003bce:	457c                	lw	a5,76(a0)
    80003bd0:	10d7e763          	bltu	a5,a3,80003cde <writei+0x110>
{
    80003bd4:	7159                	addi	sp,sp,-112
    80003bd6:	f486                	sd	ra,104(sp)
    80003bd8:	f0a2                	sd	s0,96(sp)
    80003bda:	eca6                	sd	s1,88(sp)
    80003bdc:	e8ca                	sd	s2,80(sp)
    80003bde:	e4ce                	sd	s3,72(sp)
    80003be0:	e0d2                	sd	s4,64(sp)
    80003be2:	fc56                	sd	s5,56(sp)
    80003be4:	f85a                	sd	s6,48(sp)
    80003be6:	f45e                	sd	s7,40(sp)
    80003be8:	f062                	sd	s8,32(sp)
    80003bea:	ec66                	sd	s9,24(sp)
    80003bec:	e86a                	sd	s10,16(sp)
    80003bee:	e46e                	sd	s11,8(sp)
    80003bf0:	1880                	addi	s0,sp,112
    80003bf2:	8baa                	mv	s7,a0
    80003bf4:	8c2e                	mv	s8,a1
    80003bf6:	8ab2                	mv	s5,a2
    80003bf8:	8936                	mv	s2,a3
    80003bfa:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003bfc:	00e687bb          	addw	a5,a3,a4
    80003c00:	0ed7e163          	bltu	a5,a3,80003ce2 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003c04:	00043737          	lui	a4,0x43
    80003c08:	0cf76f63          	bltu	a4,a5,80003ce6 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c0c:	0a0b0863          	beqz	s6,80003cbc <writei+0xee>
    80003c10:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c12:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003c16:	5cfd                	li	s9,-1
    80003c18:	a091                	j	80003c5c <writei+0x8e>
    80003c1a:	02099d93          	slli	s11,s3,0x20
    80003c1e:	020ddd93          	srli	s11,s11,0x20
    80003c22:	05848513          	addi	a0,s1,88
    80003c26:	86ee                	mv	a3,s11
    80003c28:	8656                	mv	a2,s5
    80003c2a:	85e2                	mv	a1,s8
    80003c2c:	953a                	add	a0,a0,a4
    80003c2e:	fffff097          	auipc	ra,0xfffff
    80003c32:	a26080e7          	jalr	-1498(ra) # 80002654 <either_copyin>
    80003c36:	07950263          	beq	a0,s9,80003c9a <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003c3a:	8526                	mv	a0,s1
    80003c3c:	00000097          	auipc	ra,0x0
    80003c40:	77c080e7          	jalr	1916(ra) # 800043b8 <log_write>
    brelse(bp);
    80003c44:	8526                	mv	a0,s1
    80003c46:	fffff097          	auipc	ra,0xfffff
    80003c4a:	50a080e7          	jalr	1290(ra) # 80003150 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c4e:	01498a3b          	addw	s4,s3,s4
    80003c52:	0129893b          	addw	s2,s3,s2
    80003c56:	9aee                	add	s5,s5,s11
    80003c58:	056a7763          	bgeu	s4,s6,80003ca6 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003c5c:	000ba483          	lw	s1,0(s7)
    80003c60:	00a9559b          	srliw	a1,s2,0xa
    80003c64:	855e                	mv	a0,s7
    80003c66:	fffff097          	auipc	ra,0xfffff
    80003c6a:	7ae080e7          	jalr	1966(ra) # 80003414 <bmap>
    80003c6e:	0005059b          	sext.w	a1,a0
    80003c72:	8526                	mv	a0,s1
    80003c74:	fffff097          	auipc	ra,0xfffff
    80003c78:	3ac080e7          	jalr	940(ra) # 80003020 <bread>
    80003c7c:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c7e:	3ff97713          	andi	a4,s2,1023
    80003c82:	40ed07bb          	subw	a5,s10,a4
    80003c86:	414b06bb          	subw	a3,s6,s4
    80003c8a:	89be                	mv	s3,a5
    80003c8c:	2781                	sext.w	a5,a5
    80003c8e:	0006861b          	sext.w	a2,a3
    80003c92:	f8f674e3          	bgeu	a2,a5,80003c1a <writei+0x4c>
    80003c96:	89b6                	mv	s3,a3
    80003c98:	b749                	j	80003c1a <writei+0x4c>
      brelse(bp);
    80003c9a:	8526                	mv	a0,s1
    80003c9c:	fffff097          	auipc	ra,0xfffff
    80003ca0:	4b4080e7          	jalr	1204(ra) # 80003150 <brelse>
      n = -1;
    80003ca4:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003ca6:	04cba783          	lw	a5,76(s7)
    80003caa:	0127f463          	bgeu	a5,s2,80003cb2 <writei+0xe4>
      ip->size = off;
    80003cae:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003cb2:	855e                	mv	a0,s7
    80003cb4:	00000097          	auipc	ra,0x0
    80003cb8:	aa4080e7          	jalr	-1372(ra) # 80003758 <iupdate>
  }

  return n;
    80003cbc:	000b051b          	sext.w	a0,s6
}
    80003cc0:	70a6                	ld	ra,104(sp)
    80003cc2:	7406                	ld	s0,96(sp)
    80003cc4:	64e6                	ld	s1,88(sp)
    80003cc6:	6946                	ld	s2,80(sp)
    80003cc8:	69a6                	ld	s3,72(sp)
    80003cca:	6a06                	ld	s4,64(sp)
    80003ccc:	7ae2                	ld	s5,56(sp)
    80003cce:	7b42                	ld	s6,48(sp)
    80003cd0:	7ba2                	ld	s7,40(sp)
    80003cd2:	7c02                	ld	s8,32(sp)
    80003cd4:	6ce2                	ld	s9,24(sp)
    80003cd6:	6d42                	ld	s10,16(sp)
    80003cd8:	6da2                	ld	s11,8(sp)
    80003cda:	6165                	addi	sp,sp,112
    80003cdc:	8082                	ret
    return -1;
    80003cde:	557d                	li	a0,-1
}
    80003ce0:	8082                	ret
    return -1;
    80003ce2:	557d                	li	a0,-1
    80003ce4:	bff1                	j	80003cc0 <writei+0xf2>
    return -1;
    80003ce6:	557d                	li	a0,-1
    80003ce8:	bfe1                	j	80003cc0 <writei+0xf2>

0000000080003cea <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003cea:	1141                	addi	sp,sp,-16
    80003cec:	e406                	sd	ra,8(sp)
    80003cee:	e022                	sd	s0,0(sp)
    80003cf0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003cf2:	4639                	li	a2,14
    80003cf4:	ffffd097          	auipc	ra,0xffffd
    80003cf8:	1ba080e7          	jalr	442(ra) # 80000eae <strncmp>
}
    80003cfc:	60a2                	ld	ra,8(sp)
    80003cfe:	6402                	ld	s0,0(sp)
    80003d00:	0141                	addi	sp,sp,16
    80003d02:	8082                	ret

0000000080003d04 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003d04:	7139                	addi	sp,sp,-64
    80003d06:	fc06                	sd	ra,56(sp)
    80003d08:	f822                	sd	s0,48(sp)
    80003d0a:	f426                	sd	s1,40(sp)
    80003d0c:	f04a                	sd	s2,32(sp)
    80003d0e:	ec4e                	sd	s3,24(sp)
    80003d10:	e852                	sd	s4,16(sp)
    80003d12:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003d14:	04451703          	lh	a4,68(a0)
    80003d18:	4785                	li	a5,1
    80003d1a:	00f71a63          	bne	a4,a5,80003d2e <dirlookup+0x2a>
    80003d1e:	892a                	mv	s2,a0
    80003d20:	89ae                	mv	s3,a1
    80003d22:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d24:	457c                	lw	a5,76(a0)
    80003d26:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003d28:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d2a:	e79d                	bnez	a5,80003d58 <dirlookup+0x54>
    80003d2c:	a8a5                	j	80003da4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003d2e:	00005517          	auipc	a0,0x5
    80003d32:	89a50513          	addi	a0,a0,-1894 # 800085c8 <syscalls+0x1a0>
    80003d36:	ffffd097          	auipc	ra,0xffffd
    80003d3a:	812080e7          	jalr	-2030(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003d3e:	00005517          	auipc	a0,0x5
    80003d42:	8a250513          	addi	a0,a0,-1886 # 800085e0 <syscalls+0x1b8>
    80003d46:	ffffd097          	auipc	ra,0xffffd
    80003d4a:	802080e7          	jalr	-2046(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003d4e:	24c1                	addiw	s1,s1,16
    80003d50:	04c92783          	lw	a5,76(s2)
    80003d54:	04f4f763          	bgeu	s1,a5,80003da2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003d58:	4741                	li	a4,16
    80003d5a:	86a6                	mv	a3,s1
    80003d5c:	fc040613          	addi	a2,s0,-64
    80003d60:	4581                	li	a1,0
    80003d62:	854a                	mv	a0,s2
    80003d64:	00000097          	auipc	ra,0x0
    80003d68:	d72080e7          	jalr	-654(ra) # 80003ad6 <readi>
    80003d6c:	47c1                	li	a5,16
    80003d6e:	fcf518e3          	bne	a0,a5,80003d3e <dirlookup+0x3a>
    if(de.inum == 0)
    80003d72:	fc045783          	lhu	a5,-64(s0)
    80003d76:	dfe1                	beqz	a5,80003d4e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d78:	fc240593          	addi	a1,s0,-62
    80003d7c:	854e                	mv	a0,s3
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	f6c080e7          	jalr	-148(ra) # 80003cea <namecmp>
    80003d86:	f561                	bnez	a0,80003d4e <dirlookup+0x4a>
      if(poff)
    80003d88:	000a0463          	beqz	s4,80003d90 <dirlookup+0x8c>
        *poff = off;
    80003d8c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d90:	fc045583          	lhu	a1,-64(s0)
    80003d94:	00092503          	lw	a0,0(s2)
    80003d98:	fffff097          	auipc	ra,0xfffff
    80003d9c:	756080e7          	jalr	1878(ra) # 800034ee <iget>
    80003da0:	a011                	j	80003da4 <dirlookup+0xa0>
  return 0;
    80003da2:	4501                	li	a0,0
}
    80003da4:	70e2                	ld	ra,56(sp)
    80003da6:	7442                	ld	s0,48(sp)
    80003da8:	74a2                	ld	s1,40(sp)
    80003daa:	7902                	ld	s2,32(sp)
    80003dac:	69e2                	ld	s3,24(sp)
    80003dae:	6a42                	ld	s4,16(sp)
    80003db0:	6121                	addi	sp,sp,64
    80003db2:	8082                	ret

0000000080003db4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003db4:	711d                	addi	sp,sp,-96
    80003db6:	ec86                	sd	ra,88(sp)
    80003db8:	e8a2                	sd	s0,80(sp)
    80003dba:	e4a6                	sd	s1,72(sp)
    80003dbc:	e0ca                	sd	s2,64(sp)
    80003dbe:	fc4e                	sd	s3,56(sp)
    80003dc0:	f852                	sd	s4,48(sp)
    80003dc2:	f456                	sd	s5,40(sp)
    80003dc4:	f05a                	sd	s6,32(sp)
    80003dc6:	ec5e                	sd	s7,24(sp)
    80003dc8:	e862                	sd	s8,16(sp)
    80003dca:	e466                	sd	s9,8(sp)
    80003dcc:	1080                	addi	s0,sp,96
    80003dce:	84aa                	mv	s1,a0
    80003dd0:	8b2e                	mv	s6,a1
    80003dd2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003dd4:	00054703          	lbu	a4,0(a0)
    80003dd8:	02f00793          	li	a5,47
    80003ddc:	02f70363          	beq	a4,a5,80003e02 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003de0:	ffffe097          	auipc	ra,0xffffe
    80003de4:	dac080e7          	jalr	-596(ra) # 80001b8c <myproc>
    80003de8:	15053503          	ld	a0,336(a0)
    80003dec:	00000097          	auipc	ra,0x0
    80003df0:	9f8080e7          	jalr	-1544(ra) # 800037e4 <idup>
    80003df4:	89aa                	mv	s3,a0
  while(*path == '/')
    80003df6:	02f00913          	li	s2,47
  len = path - s;
    80003dfa:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003dfc:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003dfe:	4c05                	li	s8,1
    80003e00:	a865                	j	80003eb8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003e02:	4585                	li	a1,1
    80003e04:	4505                	li	a0,1
    80003e06:	fffff097          	auipc	ra,0xfffff
    80003e0a:	6e8080e7          	jalr	1768(ra) # 800034ee <iget>
    80003e0e:	89aa                	mv	s3,a0
    80003e10:	b7dd                	j	80003df6 <namex+0x42>
      iunlockput(ip);
    80003e12:	854e                	mv	a0,s3
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	c70080e7          	jalr	-912(ra) # 80003a84 <iunlockput>
      return 0;
    80003e1c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003e1e:	854e                	mv	a0,s3
    80003e20:	60e6                	ld	ra,88(sp)
    80003e22:	6446                	ld	s0,80(sp)
    80003e24:	64a6                	ld	s1,72(sp)
    80003e26:	6906                	ld	s2,64(sp)
    80003e28:	79e2                	ld	s3,56(sp)
    80003e2a:	7a42                	ld	s4,48(sp)
    80003e2c:	7aa2                	ld	s5,40(sp)
    80003e2e:	7b02                	ld	s6,32(sp)
    80003e30:	6be2                	ld	s7,24(sp)
    80003e32:	6c42                	ld	s8,16(sp)
    80003e34:	6ca2                	ld	s9,8(sp)
    80003e36:	6125                	addi	sp,sp,96
    80003e38:	8082                	ret
      iunlock(ip);
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	aa8080e7          	jalr	-1368(ra) # 800038e4 <iunlock>
      return ip;
    80003e44:	bfe9                	j	80003e1e <namex+0x6a>
      iunlockput(ip);
    80003e46:	854e                	mv	a0,s3
    80003e48:	00000097          	auipc	ra,0x0
    80003e4c:	c3c080e7          	jalr	-964(ra) # 80003a84 <iunlockput>
      return 0;
    80003e50:	89d2                	mv	s3,s4
    80003e52:	b7f1                	j	80003e1e <namex+0x6a>
  len = path - s;
    80003e54:	40b48633          	sub	a2,s1,a1
    80003e58:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003e5c:	094cd463          	bge	s9,s4,80003ee4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003e60:	4639                	li	a2,14
    80003e62:	8556                	mv	a0,s5
    80003e64:	ffffd097          	auipc	ra,0xffffd
    80003e68:	fce080e7          	jalr	-50(ra) # 80000e32 <memmove>
  while(*path == '/')
    80003e6c:	0004c783          	lbu	a5,0(s1)
    80003e70:	01279763          	bne	a5,s2,80003e7e <namex+0xca>
    path++;
    80003e74:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e76:	0004c783          	lbu	a5,0(s1)
    80003e7a:	ff278de3          	beq	a5,s2,80003e74 <namex+0xc0>
    ilock(ip);
    80003e7e:	854e                	mv	a0,s3
    80003e80:	00000097          	auipc	ra,0x0
    80003e84:	9a2080e7          	jalr	-1630(ra) # 80003822 <ilock>
    if(ip->type != T_DIR){
    80003e88:	04499783          	lh	a5,68(s3)
    80003e8c:	f98793e3          	bne	a5,s8,80003e12 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e90:	000b0563          	beqz	s6,80003e9a <namex+0xe6>
    80003e94:	0004c783          	lbu	a5,0(s1)
    80003e98:	d3cd                	beqz	a5,80003e3a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e9a:	865e                	mv	a2,s7
    80003e9c:	85d6                	mv	a1,s5
    80003e9e:	854e                	mv	a0,s3
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	e64080e7          	jalr	-412(ra) # 80003d04 <dirlookup>
    80003ea8:	8a2a                	mv	s4,a0
    80003eaa:	dd51                	beqz	a0,80003e46 <namex+0x92>
    iunlockput(ip);
    80003eac:	854e                	mv	a0,s3
    80003eae:	00000097          	auipc	ra,0x0
    80003eb2:	bd6080e7          	jalr	-1066(ra) # 80003a84 <iunlockput>
    ip = next;
    80003eb6:	89d2                	mv	s3,s4
  while(*path == '/')
    80003eb8:	0004c783          	lbu	a5,0(s1)
    80003ebc:	05279763          	bne	a5,s2,80003f0a <namex+0x156>
    path++;
    80003ec0:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ec2:	0004c783          	lbu	a5,0(s1)
    80003ec6:	ff278de3          	beq	a5,s2,80003ec0 <namex+0x10c>
  if(*path == 0)
    80003eca:	c79d                	beqz	a5,80003ef8 <namex+0x144>
    path++;
    80003ecc:	85a6                	mv	a1,s1
  len = path - s;
    80003ece:	8a5e                	mv	s4,s7
    80003ed0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003ed2:	01278963          	beq	a5,s2,80003ee4 <namex+0x130>
    80003ed6:	dfbd                	beqz	a5,80003e54 <namex+0xa0>
    path++;
    80003ed8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003eda:	0004c783          	lbu	a5,0(s1)
    80003ede:	ff279ce3          	bne	a5,s2,80003ed6 <namex+0x122>
    80003ee2:	bf8d                	j	80003e54 <namex+0xa0>
    memmove(name, s, len);
    80003ee4:	2601                	sext.w	a2,a2
    80003ee6:	8556                	mv	a0,s5
    80003ee8:	ffffd097          	auipc	ra,0xffffd
    80003eec:	f4a080e7          	jalr	-182(ra) # 80000e32 <memmove>
    name[len] = 0;
    80003ef0:	9a56                	add	s4,s4,s5
    80003ef2:	000a0023          	sb	zero,0(s4)
    80003ef6:	bf9d                	j	80003e6c <namex+0xb8>
  if(nameiparent){
    80003ef8:	f20b03e3          	beqz	s6,80003e1e <namex+0x6a>
    iput(ip);
    80003efc:	854e                	mv	a0,s3
    80003efe:	00000097          	auipc	ra,0x0
    80003f02:	ade080e7          	jalr	-1314(ra) # 800039dc <iput>
    return 0;
    80003f06:	4981                	li	s3,0
    80003f08:	bf19                	j	80003e1e <namex+0x6a>
  if(*path == 0)
    80003f0a:	d7fd                	beqz	a5,80003ef8 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003f0c:	0004c783          	lbu	a5,0(s1)
    80003f10:	85a6                	mv	a1,s1
    80003f12:	b7d1                	j	80003ed6 <namex+0x122>

0000000080003f14 <dirlink>:
{
    80003f14:	7139                	addi	sp,sp,-64
    80003f16:	fc06                	sd	ra,56(sp)
    80003f18:	f822                	sd	s0,48(sp)
    80003f1a:	f426                	sd	s1,40(sp)
    80003f1c:	f04a                	sd	s2,32(sp)
    80003f1e:	ec4e                	sd	s3,24(sp)
    80003f20:	e852                	sd	s4,16(sp)
    80003f22:	0080                	addi	s0,sp,64
    80003f24:	892a                	mv	s2,a0
    80003f26:	8a2e                	mv	s4,a1
    80003f28:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003f2a:	4601                	li	a2,0
    80003f2c:	00000097          	auipc	ra,0x0
    80003f30:	dd8080e7          	jalr	-552(ra) # 80003d04 <dirlookup>
    80003f34:	e93d                	bnez	a0,80003faa <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f36:	04c92483          	lw	s1,76(s2)
    80003f3a:	c49d                	beqz	s1,80003f68 <dirlink+0x54>
    80003f3c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f3e:	4741                	li	a4,16
    80003f40:	86a6                	mv	a3,s1
    80003f42:	fc040613          	addi	a2,s0,-64
    80003f46:	4581                	li	a1,0
    80003f48:	854a                	mv	a0,s2
    80003f4a:	00000097          	auipc	ra,0x0
    80003f4e:	b8c080e7          	jalr	-1140(ra) # 80003ad6 <readi>
    80003f52:	47c1                	li	a5,16
    80003f54:	06f51163          	bne	a0,a5,80003fb6 <dirlink+0xa2>
    if(de.inum == 0)
    80003f58:	fc045783          	lhu	a5,-64(s0)
    80003f5c:	c791                	beqz	a5,80003f68 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003f5e:	24c1                	addiw	s1,s1,16
    80003f60:	04c92783          	lw	a5,76(s2)
    80003f64:	fcf4ede3          	bltu	s1,a5,80003f3e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f68:	4639                	li	a2,14
    80003f6a:	85d2                	mv	a1,s4
    80003f6c:	fc240513          	addi	a0,s0,-62
    80003f70:	ffffd097          	auipc	ra,0xffffd
    80003f74:	f7a080e7          	jalr	-134(ra) # 80000eea <strncpy>
  de.inum = inum;
    80003f78:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f7c:	4741                	li	a4,16
    80003f7e:	86a6                	mv	a3,s1
    80003f80:	fc040613          	addi	a2,s0,-64
    80003f84:	4581                	li	a1,0
    80003f86:	854a                	mv	a0,s2
    80003f88:	00000097          	auipc	ra,0x0
    80003f8c:	c46080e7          	jalr	-954(ra) # 80003bce <writei>
    80003f90:	872a                	mv	a4,a0
    80003f92:	47c1                	li	a5,16
  return 0;
    80003f94:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f96:	02f71863          	bne	a4,a5,80003fc6 <dirlink+0xb2>
}
    80003f9a:	70e2                	ld	ra,56(sp)
    80003f9c:	7442                	ld	s0,48(sp)
    80003f9e:	74a2                	ld	s1,40(sp)
    80003fa0:	7902                	ld	s2,32(sp)
    80003fa2:	69e2                	ld	s3,24(sp)
    80003fa4:	6a42                	ld	s4,16(sp)
    80003fa6:	6121                	addi	sp,sp,64
    80003fa8:	8082                	ret
    iput(ip);
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	a32080e7          	jalr	-1486(ra) # 800039dc <iput>
    return -1;
    80003fb2:	557d                	li	a0,-1
    80003fb4:	b7dd                	j	80003f9a <dirlink+0x86>
      panic("dirlink read");
    80003fb6:	00004517          	auipc	a0,0x4
    80003fba:	63a50513          	addi	a0,a0,1594 # 800085f0 <syscalls+0x1c8>
    80003fbe:	ffffc097          	auipc	ra,0xffffc
    80003fc2:	58a080e7          	jalr	1418(ra) # 80000548 <panic>
    panic("dirlink");
    80003fc6:	00004517          	auipc	a0,0x4
    80003fca:	74a50513          	addi	a0,a0,1866 # 80008710 <syscalls+0x2e8>
    80003fce:	ffffc097          	auipc	ra,0xffffc
    80003fd2:	57a080e7          	jalr	1402(ra) # 80000548 <panic>

0000000080003fd6 <namei>:

struct inode*
namei(char *path)
{
    80003fd6:	1101                	addi	sp,sp,-32
    80003fd8:	ec06                	sd	ra,24(sp)
    80003fda:	e822                	sd	s0,16(sp)
    80003fdc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003fde:	fe040613          	addi	a2,s0,-32
    80003fe2:	4581                	li	a1,0
    80003fe4:	00000097          	auipc	ra,0x0
    80003fe8:	dd0080e7          	jalr	-560(ra) # 80003db4 <namex>
}
    80003fec:	60e2                	ld	ra,24(sp)
    80003fee:	6442                	ld	s0,16(sp)
    80003ff0:	6105                	addi	sp,sp,32
    80003ff2:	8082                	ret

0000000080003ff4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003ff4:	1141                	addi	sp,sp,-16
    80003ff6:	e406                	sd	ra,8(sp)
    80003ff8:	e022                	sd	s0,0(sp)
    80003ffa:	0800                	addi	s0,sp,16
    80003ffc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003ffe:	4585                	li	a1,1
    80004000:	00000097          	auipc	ra,0x0
    80004004:	db4080e7          	jalr	-588(ra) # 80003db4 <namex>
}
    80004008:	60a2                	ld	ra,8(sp)
    8000400a:	6402                	ld	s0,0(sp)
    8000400c:	0141                	addi	sp,sp,16
    8000400e:	8082                	ret

0000000080004010 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004010:	1101                	addi	sp,sp,-32
    80004012:	ec06                	sd	ra,24(sp)
    80004014:	e822                	sd	s0,16(sp)
    80004016:	e426                	sd	s1,8(sp)
    80004018:	e04a                	sd	s2,0(sp)
    8000401a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000401c:	0001e917          	auipc	s2,0x1e
    80004020:	8f490913          	addi	s2,s2,-1804 # 80021910 <log>
    80004024:	01892583          	lw	a1,24(s2)
    80004028:	02892503          	lw	a0,40(s2)
    8000402c:	fffff097          	auipc	ra,0xfffff
    80004030:	ff4080e7          	jalr	-12(ra) # 80003020 <bread>
    80004034:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004036:	02c92683          	lw	a3,44(s2)
    8000403a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    8000403c:	02d05763          	blez	a3,8000406a <write_head+0x5a>
    80004040:	0001e797          	auipc	a5,0x1e
    80004044:	90078793          	addi	a5,a5,-1792 # 80021940 <log+0x30>
    80004048:	05c50713          	addi	a4,a0,92
    8000404c:	36fd                	addiw	a3,a3,-1
    8000404e:	1682                	slli	a3,a3,0x20
    80004050:	9281                	srli	a3,a3,0x20
    80004052:	068a                	slli	a3,a3,0x2
    80004054:	0001e617          	auipc	a2,0x1e
    80004058:	8f060613          	addi	a2,a2,-1808 # 80021944 <log+0x34>
    8000405c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000405e:	4390                	lw	a2,0(a5)
    80004060:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004062:	0791                	addi	a5,a5,4
    80004064:	0711                	addi	a4,a4,4
    80004066:	fed79ce3          	bne	a5,a3,8000405e <write_head+0x4e>
  }
  bwrite(buf);
    8000406a:	8526                	mv	a0,s1
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	0a6080e7          	jalr	166(ra) # 80003112 <bwrite>
  brelse(buf);
    80004074:	8526                	mv	a0,s1
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	0da080e7          	jalr	218(ra) # 80003150 <brelse>
}
    8000407e:	60e2                	ld	ra,24(sp)
    80004080:	6442                	ld	s0,16(sp)
    80004082:	64a2                	ld	s1,8(sp)
    80004084:	6902                	ld	s2,0(sp)
    80004086:	6105                	addi	sp,sp,32
    80004088:	8082                	ret

000000008000408a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000408a:	0001e797          	auipc	a5,0x1e
    8000408e:	8b27a783          	lw	a5,-1870(a5) # 8002193c <log+0x2c>
    80004092:	0af05663          	blez	a5,8000413e <install_trans+0xb4>
{
    80004096:	7139                	addi	sp,sp,-64
    80004098:	fc06                	sd	ra,56(sp)
    8000409a:	f822                	sd	s0,48(sp)
    8000409c:	f426                	sd	s1,40(sp)
    8000409e:	f04a                	sd	s2,32(sp)
    800040a0:	ec4e                	sd	s3,24(sp)
    800040a2:	e852                	sd	s4,16(sp)
    800040a4:	e456                	sd	s5,8(sp)
    800040a6:	0080                	addi	s0,sp,64
    800040a8:	0001ea97          	auipc	s5,0x1e
    800040ac:	898a8a93          	addi	s5,s5,-1896 # 80021940 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040b0:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800040b2:	0001e997          	auipc	s3,0x1e
    800040b6:	85e98993          	addi	s3,s3,-1954 # 80021910 <log>
    800040ba:	0189a583          	lw	a1,24(s3)
    800040be:	014585bb          	addw	a1,a1,s4
    800040c2:	2585                	addiw	a1,a1,1
    800040c4:	0289a503          	lw	a0,40(s3)
    800040c8:	fffff097          	auipc	ra,0xfffff
    800040cc:	f58080e7          	jalr	-168(ra) # 80003020 <bread>
    800040d0:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800040d2:	000aa583          	lw	a1,0(s5)
    800040d6:	0289a503          	lw	a0,40(s3)
    800040da:	fffff097          	auipc	ra,0xfffff
    800040de:	f46080e7          	jalr	-186(ra) # 80003020 <bread>
    800040e2:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800040e4:	40000613          	li	a2,1024
    800040e8:	05890593          	addi	a1,s2,88
    800040ec:	05850513          	addi	a0,a0,88
    800040f0:	ffffd097          	auipc	ra,0xffffd
    800040f4:	d42080e7          	jalr	-702(ra) # 80000e32 <memmove>
    bwrite(dbuf);  // write dst to disk
    800040f8:	8526                	mv	a0,s1
    800040fa:	fffff097          	auipc	ra,0xfffff
    800040fe:	018080e7          	jalr	24(ra) # 80003112 <bwrite>
    bunpin(dbuf);
    80004102:	8526                	mv	a0,s1
    80004104:	fffff097          	auipc	ra,0xfffff
    80004108:	126080e7          	jalr	294(ra) # 8000322a <bunpin>
    brelse(lbuf);
    8000410c:	854a                	mv	a0,s2
    8000410e:	fffff097          	auipc	ra,0xfffff
    80004112:	042080e7          	jalr	66(ra) # 80003150 <brelse>
    brelse(dbuf);
    80004116:	8526                	mv	a0,s1
    80004118:	fffff097          	auipc	ra,0xfffff
    8000411c:	038080e7          	jalr	56(ra) # 80003150 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004120:	2a05                	addiw	s4,s4,1
    80004122:	0a91                	addi	s5,s5,4
    80004124:	02c9a783          	lw	a5,44(s3)
    80004128:	f8fa49e3          	blt	s4,a5,800040ba <install_trans+0x30>
}
    8000412c:	70e2                	ld	ra,56(sp)
    8000412e:	7442                	ld	s0,48(sp)
    80004130:	74a2                	ld	s1,40(sp)
    80004132:	7902                	ld	s2,32(sp)
    80004134:	69e2                	ld	s3,24(sp)
    80004136:	6a42                	ld	s4,16(sp)
    80004138:	6aa2                	ld	s5,8(sp)
    8000413a:	6121                	addi	sp,sp,64
    8000413c:	8082                	ret
    8000413e:	8082                	ret

0000000080004140 <initlog>:
{
    80004140:	7179                	addi	sp,sp,-48
    80004142:	f406                	sd	ra,40(sp)
    80004144:	f022                	sd	s0,32(sp)
    80004146:	ec26                	sd	s1,24(sp)
    80004148:	e84a                	sd	s2,16(sp)
    8000414a:	e44e                	sd	s3,8(sp)
    8000414c:	1800                	addi	s0,sp,48
    8000414e:	892a                	mv	s2,a0
    80004150:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004152:	0001d497          	auipc	s1,0x1d
    80004156:	7be48493          	addi	s1,s1,1982 # 80021910 <log>
    8000415a:	00004597          	auipc	a1,0x4
    8000415e:	4a658593          	addi	a1,a1,1190 # 80008600 <syscalls+0x1d8>
    80004162:	8526                	mv	a0,s1
    80004164:	ffffd097          	auipc	ra,0xffffd
    80004168:	ae2080e7          	jalr	-1310(ra) # 80000c46 <initlock>
  log.start = sb->logstart;
    8000416c:	0149a583          	lw	a1,20(s3)
    80004170:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004172:	0109a783          	lw	a5,16(s3)
    80004176:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004178:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000417c:	854a                	mv	a0,s2
    8000417e:	fffff097          	auipc	ra,0xfffff
    80004182:	ea2080e7          	jalr	-350(ra) # 80003020 <bread>
  log.lh.n = lh->n;
    80004186:	4d3c                	lw	a5,88(a0)
    80004188:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000418a:	02f05563          	blez	a5,800041b4 <initlog+0x74>
    8000418e:	05c50713          	addi	a4,a0,92
    80004192:	0001d697          	auipc	a3,0x1d
    80004196:	7ae68693          	addi	a3,a3,1966 # 80021940 <log+0x30>
    8000419a:	37fd                	addiw	a5,a5,-1
    8000419c:	1782                	slli	a5,a5,0x20
    8000419e:	9381                	srli	a5,a5,0x20
    800041a0:	078a                	slli	a5,a5,0x2
    800041a2:	06050613          	addi	a2,a0,96
    800041a6:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800041a8:	4310                	lw	a2,0(a4)
    800041aa:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800041ac:	0711                	addi	a4,a4,4
    800041ae:	0691                	addi	a3,a3,4
    800041b0:	fef71ce3          	bne	a4,a5,800041a8 <initlog+0x68>
  brelse(buf);
    800041b4:	fffff097          	auipc	ra,0xfffff
    800041b8:	f9c080e7          	jalr	-100(ra) # 80003150 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800041bc:	00000097          	auipc	ra,0x0
    800041c0:	ece080e7          	jalr	-306(ra) # 8000408a <install_trans>
  log.lh.n = 0;
    800041c4:	0001d797          	auipc	a5,0x1d
    800041c8:	7607ac23          	sw	zero,1912(a5) # 8002193c <log+0x2c>
  write_head(); // clear the log
    800041cc:	00000097          	auipc	ra,0x0
    800041d0:	e44080e7          	jalr	-444(ra) # 80004010 <write_head>
}
    800041d4:	70a2                	ld	ra,40(sp)
    800041d6:	7402                	ld	s0,32(sp)
    800041d8:	64e2                	ld	s1,24(sp)
    800041da:	6942                	ld	s2,16(sp)
    800041dc:	69a2                	ld	s3,8(sp)
    800041de:	6145                	addi	sp,sp,48
    800041e0:	8082                	ret

00000000800041e2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800041e2:	1101                	addi	sp,sp,-32
    800041e4:	ec06                	sd	ra,24(sp)
    800041e6:	e822                	sd	s0,16(sp)
    800041e8:	e426                	sd	s1,8(sp)
    800041ea:	e04a                	sd	s2,0(sp)
    800041ec:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800041ee:	0001d517          	auipc	a0,0x1d
    800041f2:	72250513          	addi	a0,a0,1826 # 80021910 <log>
    800041f6:	ffffd097          	auipc	ra,0xffffd
    800041fa:	ae0080e7          	jalr	-1312(ra) # 80000cd6 <acquire>
  while(1){
    if(log.committing){
    800041fe:	0001d497          	auipc	s1,0x1d
    80004202:	71248493          	addi	s1,s1,1810 # 80021910 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004206:	4979                	li	s2,30
    80004208:	a039                	j	80004216 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000420a:	85a6                	mv	a1,s1
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffe097          	auipc	ra,0xffffe
    80004212:	18e080e7          	jalr	398(ra) # 8000239c <sleep>
    if(log.committing){
    80004216:	50dc                	lw	a5,36(s1)
    80004218:	fbed                	bnez	a5,8000420a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000421a:	509c                	lw	a5,32(s1)
    8000421c:	0017871b          	addiw	a4,a5,1
    80004220:	0007069b          	sext.w	a3,a4
    80004224:	0027179b          	slliw	a5,a4,0x2
    80004228:	9fb9                	addw	a5,a5,a4
    8000422a:	0017979b          	slliw	a5,a5,0x1
    8000422e:	54d8                	lw	a4,44(s1)
    80004230:	9fb9                	addw	a5,a5,a4
    80004232:	00f95963          	bge	s2,a5,80004244 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004236:	85a6                	mv	a1,s1
    80004238:	8526                	mv	a0,s1
    8000423a:	ffffe097          	auipc	ra,0xffffe
    8000423e:	162080e7          	jalr	354(ra) # 8000239c <sleep>
    80004242:	bfd1                	j	80004216 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004244:	0001d517          	auipc	a0,0x1d
    80004248:	6cc50513          	addi	a0,a0,1740 # 80021910 <log>
    8000424c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000424e:	ffffd097          	auipc	ra,0xffffd
    80004252:	b3c080e7          	jalr	-1220(ra) # 80000d8a <release>
      break;
    }
  }
}
    80004256:	60e2                	ld	ra,24(sp)
    80004258:	6442                	ld	s0,16(sp)
    8000425a:	64a2                	ld	s1,8(sp)
    8000425c:	6902                	ld	s2,0(sp)
    8000425e:	6105                	addi	sp,sp,32
    80004260:	8082                	ret

0000000080004262 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004262:	7139                	addi	sp,sp,-64
    80004264:	fc06                	sd	ra,56(sp)
    80004266:	f822                	sd	s0,48(sp)
    80004268:	f426                	sd	s1,40(sp)
    8000426a:	f04a                	sd	s2,32(sp)
    8000426c:	ec4e                	sd	s3,24(sp)
    8000426e:	e852                	sd	s4,16(sp)
    80004270:	e456                	sd	s5,8(sp)
    80004272:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004274:	0001d497          	auipc	s1,0x1d
    80004278:	69c48493          	addi	s1,s1,1692 # 80021910 <log>
    8000427c:	8526                	mv	a0,s1
    8000427e:	ffffd097          	auipc	ra,0xffffd
    80004282:	a58080e7          	jalr	-1448(ra) # 80000cd6 <acquire>
  log.outstanding -= 1;
    80004286:	509c                	lw	a5,32(s1)
    80004288:	37fd                	addiw	a5,a5,-1
    8000428a:	0007891b          	sext.w	s2,a5
    8000428e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004290:	50dc                	lw	a5,36(s1)
    80004292:	efb9                	bnez	a5,800042f0 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004294:	06091663          	bnez	s2,80004300 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004298:	0001d497          	auipc	s1,0x1d
    8000429c:	67848493          	addi	s1,s1,1656 # 80021910 <log>
    800042a0:	4785                	li	a5,1
    800042a2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	ae4080e7          	jalr	-1308(ra) # 80000d8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800042ae:	54dc                	lw	a5,44(s1)
    800042b0:	06f04763          	bgtz	a5,8000431e <end_op+0xbc>
    acquire(&log.lock);
    800042b4:	0001d497          	auipc	s1,0x1d
    800042b8:	65c48493          	addi	s1,s1,1628 # 80021910 <log>
    800042bc:	8526                	mv	a0,s1
    800042be:	ffffd097          	auipc	ra,0xffffd
    800042c2:	a18080e7          	jalr	-1512(ra) # 80000cd6 <acquire>
    log.committing = 0;
    800042c6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800042ca:	8526                	mv	a0,s1
    800042cc:	ffffe097          	auipc	ra,0xffffe
    800042d0:	256080e7          	jalr	598(ra) # 80002522 <wakeup>
    release(&log.lock);
    800042d4:	8526                	mv	a0,s1
    800042d6:	ffffd097          	auipc	ra,0xffffd
    800042da:	ab4080e7          	jalr	-1356(ra) # 80000d8a <release>
}
    800042de:	70e2                	ld	ra,56(sp)
    800042e0:	7442                	ld	s0,48(sp)
    800042e2:	74a2                	ld	s1,40(sp)
    800042e4:	7902                	ld	s2,32(sp)
    800042e6:	69e2                	ld	s3,24(sp)
    800042e8:	6a42                	ld	s4,16(sp)
    800042ea:	6aa2                	ld	s5,8(sp)
    800042ec:	6121                	addi	sp,sp,64
    800042ee:	8082                	ret
    panic("log.committing");
    800042f0:	00004517          	auipc	a0,0x4
    800042f4:	31850513          	addi	a0,a0,792 # 80008608 <syscalls+0x1e0>
    800042f8:	ffffc097          	auipc	ra,0xffffc
    800042fc:	250080e7          	jalr	592(ra) # 80000548 <panic>
    wakeup(&log);
    80004300:	0001d497          	auipc	s1,0x1d
    80004304:	61048493          	addi	s1,s1,1552 # 80021910 <log>
    80004308:	8526                	mv	a0,s1
    8000430a:	ffffe097          	auipc	ra,0xffffe
    8000430e:	218080e7          	jalr	536(ra) # 80002522 <wakeup>
  release(&log.lock);
    80004312:	8526                	mv	a0,s1
    80004314:	ffffd097          	auipc	ra,0xffffd
    80004318:	a76080e7          	jalr	-1418(ra) # 80000d8a <release>
  if(do_commit){
    8000431c:	b7c9                	j	800042de <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000431e:	0001da97          	auipc	s5,0x1d
    80004322:	622a8a93          	addi	s5,s5,1570 # 80021940 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004326:	0001da17          	auipc	s4,0x1d
    8000432a:	5eaa0a13          	addi	s4,s4,1514 # 80021910 <log>
    8000432e:	018a2583          	lw	a1,24(s4)
    80004332:	012585bb          	addw	a1,a1,s2
    80004336:	2585                	addiw	a1,a1,1
    80004338:	028a2503          	lw	a0,40(s4)
    8000433c:	fffff097          	auipc	ra,0xfffff
    80004340:	ce4080e7          	jalr	-796(ra) # 80003020 <bread>
    80004344:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004346:	000aa583          	lw	a1,0(s5)
    8000434a:	028a2503          	lw	a0,40(s4)
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	cd2080e7          	jalr	-814(ra) # 80003020 <bread>
    80004356:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004358:	40000613          	li	a2,1024
    8000435c:	05850593          	addi	a1,a0,88
    80004360:	05848513          	addi	a0,s1,88
    80004364:	ffffd097          	auipc	ra,0xffffd
    80004368:	ace080e7          	jalr	-1330(ra) # 80000e32 <memmove>
    bwrite(to);  // write the log
    8000436c:	8526                	mv	a0,s1
    8000436e:	fffff097          	auipc	ra,0xfffff
    80004372:	da4080e7          	jalr	-604(ra) # 80003112 <bwrite>
    brelse(from);
    80004376:	854e                	mv	a0,s3
    80004378:	fffff097          	auipc	ra,0xfffff
    8000437c:	dd8080e7          	jalr	-552(ra) # 80003150 <brelse>
    brelse(to);
    80004380:	8526                	mv	a0,s1
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	dce080e7          	jalr	-562(ra) # 80003150 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000438a:	2905                	addiw	s2,s2,1
    8000438c:	0a91                	addi	s5,s5,4
    8000438e:	02ca2783          	lw	a5,44(s4)
    80004392:	f8f94ee3          	blt	s2,a5,8000432e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004396:	00000097          	auipc	ra,0x0
    8000439a:	c7a080e7          	jalr	-902(ra) # 80004010 <write_head>
    install_trans(); // Now install writes to home locations
    8000439e:	00000097          	auipc	ra,0x0
    800043a2:	cec080e7          	jalr	-788(ra) # 8000408a <install_trans>
    log.lh.n = 0;
    800043a6:	0001d797          	auipc	a5,0x1d
    800043aa:	5807ab23          	sw	zero,1430(a5) # 8002193c <log+0x2c>
    write_head();    // Erase the transaction from the log
    800043ae:	00000097          	auipc	ra,0x0
    800043b2:	c62080e7          	jalr	-926(ra) # 80004010 <write_head>
    800043b6:	bdfd                	j	800042b4 <end_op+0x52>

00000000800043b8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800043b8:	1101                	addi	sp,sp,-32
    800043ba:	ec06                	sd	ra,24(sp)
    800043bc:	e822                	sd	s0,16(sp)
    800043be:	e426                	sd	s1,8(sp)
    800043c0:	e04a                	sd	s2,0(sp)
    800043c2:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800043c4:	0001d717          	auipc	a4,0x1d
    800043c8:	57872703          	lw	a4,1400(a4) # 8002193c <log+0x2c>
    800043cc:	47f5                	li	a5,29
    800043ce:	08e7c063          	blt	a5,a4,8000444e <log_write+0x96>
    800043d2:	84aa                	mv	s1,a0
    800043d4:	0001d797          	auipc	a5,0x1d
    800043d8:	5587a783          	lw	a5,1368(a5) # 8002192c <log+0x1c>
    800043dc:	37fd                	addiw	a5,a5,-1
    800043de:	06f75863          	bge	a4,a5,8000444e <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800043e2:	0001d797          	auipc	a5,0x1d
    800043e6:	54e7a783          	lw	a5,1358(a5) # 80021930 <log+0x20>
    800043ea:	06f05a63          	blez	a5,8000445e <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    800043ee:	0001d917          	auipc	s2,0x1d
    800043f2:	52290913          	addi	s2,s2,1314 # 80021910 <log>
    800043f6:	854a                	mv	a0,s2
    800043f8:	ffffd097          	auipc	ra,0xffffd
    800043fc:	8de080e7          	jalr	-1826(ra) # 80000cd6 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004400:	02c92603          	lw	a2,44(s2)
    80004404:	06c05563          	blez	a2,8000446e <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004408:	44cc                	lw	a1,12(s1)
    8000440a:	0001d717          	auipc	a4,0x1d
    8000440e:	53670713          	addi	a4,a4,1334 # 80021940 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004412:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004414:	4314                	lw	a3,0(a4)
    80004416:	04b68d63          	beq	a3,a1,80004470 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000441a:	2785                	addiw	a5,a5,1
    8000441c:	0711                	addi	a4,a4,4
    8000441e:	fec79be3          	bne	a5,a2,80004414 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004422:	0621                	addi	a2,a2,8
    80004424:	060a                	slli	a2,a2,0x2
    80004426:	0001d797          	auipc	a5,0x1d
    8000442a:	4ea78793          	addi	a5,a5,1258 # 80021910 <log>
    8000442e:	963e                	add	a2,a2,a5
    80004430:	44dc                	lw	a5,12(s1)
    80004432:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004434:	8526                	mv	a0,s1
    80004436:	fffff097          	auipc	ra,0xfffff
    8000443a:	db8080e7          	jalr	-584(ra) # 800031ee <bpin>
    log.lh.n++;
    8000443e:	0001d717          	auipc	a4,0x1d
    80004442:	4d270713          	addi	a4,a4,1234 # 80021910 <log>
    80004446:	575c                	lw	a5,44(a4)
    80004448:	2785                	addiw	a5,a5,1
    8000444a:	d75c                	sw	a5,44(a4)
    8000444c:	a83d                	j	8000448a <log_write+0xd2>
    panic("too big a transaction");
    8000444e:	00004517          	auipc	a0,0x4
    80004452:	1ca50513          	addi	a0,a0,458 # 80008618 <syscalls+0x1f0>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	0f2080e7          	jalr	242(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    8000445e:	00004517          	auipc	a0,0x4
    80004462:	1d250513          	addi	a0,a0,466 # 80008630 <syscalls+0x208>
    80004466:	ffffc097          	auipc	ra,0xffffc
    8000446a:	0e2080e7          	jalr	226(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000446e:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004470:	00878713          	addi	a4,a5,8
    80004474:	00271693          	slli	a3,a4,0x2
    80004478:	0001d717          	auipc	a4,0x1d
    8000447c:	49870713          	addi	a4,a4,1176 # 80021910 <log>
    80004480:	9736                	add	a4,a4,a3
    80004482:	44d4                	lw	a3,12(s1)
    80004484:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004486:	faf607e3          	beq	a2,a5,80004434 <log_write+0x7c>
  }
  release(&log.lock);
    8000448a:	0001d517          	auipc	a0,0x1d
    8000448e:	48650513          	addi	a0,a0,1158 # 80021910 <log>
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	8f8080e7          	jalr	-1800(ra) # 80000d8a <release>
}
    8000449a:	60e2                	ld	ra,24(sp)
    8000449c:	6442                	ld	s0,16(sp)
    8000449e:	64a2                	ld	s1,8(sp)
    800044a0:	6902                	ld	s2,0(sp)
    800044a2:	6105                	addi	sp,sp,32
    800044a4:	8082                	ret

00000000800044a6 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800044a6:	1101                	addi	sp,sp,-32
    800044a8:	ec06                	sd	ra,24(sp)
    800044aa:	e822                	sd	s0,16(sp)
    800044ac:	e426                	sd	s1,8(sp)
    800044ae:	e04a                	sd	s2,0(sp)
    800044b0:	1000                	addi	s0,sp,32
    800044b2:	84aa                	mv	s1,a0
    800044b4:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800044b6:	00004597          	auipc	a1,0x4
    800044ba:	19a58593          	addi	a1,a1,410 # 80008650 <syscalls+0x228>
    800044be:	0521                	addi	a0,a0,8
    800044c0:	ffffc097          	auipc	ra,0xffffc
    800044c4:	786080e7          	jalr	1926(ra) # 80000c46 <initlock>
  lk->name = name;
    800044c8:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800044cc:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044d0:	0204a423          	sw	zero,40(s1)
}
    800044d4:	60e2                	ld	ra,24(sp)
    800044d6:	6442                	ld	s0,16(sp)
    800044d8:	64a2                	ld	s1,8(sp)
    800044da:	6902                	ld	s2,0(sp)
    800044dc:	6105                	addi	sp,sp,32
    800044de:	8082                	ret

00000000800044e0 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800044e0:	1101                	addi	sp,sp,-32
    800044e2:	ec06                	sd	ra,24(sp)
    800044e4:	e822                	sd	s0,16(sp)
    800044e6:	e426                	sd	s1,8(sp)
    800044e8:	e04a                	sd	s2,0(sp)
    800044ea:	1000                	addi	s0,sp,32
    800044ec:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044ee:	00850913          	addi	s2,a0,8
    800044f2:	854a                	mv	a0,s2
    800044f4:	ffffc097          	auipc	ra,0xffffc
    800044f8:	7e2080e7          	jalr	2018(ra) # 80000cd6 <acquire>
  while (lk->locked) {
    800044fc:	409c                	lw	a5,0(s1)
    800044fe:	cb89                	beqz	a5,80004510 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004500:	85ca                	mv	a1,s2
    80004502:	8526                	mv	a0,s1
    80004504:	ffffe097          	auipc	ra,0xffffe
    80004508:	e98080e7          	jalr	-360(ra) # 8000239c <sleep>
  while (lk->locked) {
    8000450c:	409c                	lw	a5,0(s1)
    8000450e:	fbed                	bnez	a5,80004500 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004510:	4785                	li	a5,1
    80004512:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004514:	ffffd097          	auipc	ra,0xffffd
    80004518:	678080e7          	jalr	1656(ra) # 80001b8c <myproc>
    8000451c:	5d1c                	lw	a5,56(a0)
    8000451e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004520:	854a                	mv	a0,s2
    80004522:	ffffd097          	auipc	ra,0xffffd
    80004526:	868080e7          	jalr	-1944(ra) # 80000d8a <release>
}
    8000452a:	60e2                	ld	ra,24(sp)
    8000452c:	6442                	ld	s0,16(sp)
    8000452e:	64a2                	ld	s1,8(sp)
    80004530:	6902                	ld	s2,0(sp)
    80004532:	6105                	addi	sp,sp,32
    80004534:	8082                	ret

0000000080004536 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004536:	1101                	addi	sp,sp,-32
    80004538:	ec06                	sd	ra,24(sp)
    8000453a:	e822                	sd	s0,16(sp)
    8000453c:	e426                	sd	s1,8(sp)
    8000453e:	e04a                	sd	s2,0(sp)
    80004540:	1000                	addi	s0,sp,32
    80004542:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004544:	00850913          	addi	s2,a0,8
    80004548:	854a                	mv	a0,s2
    8000454a:	ffffc097          	auipc	ra,0xffffc
    8000454e:	78c080e7          	jalr	1932(ra) # 80000cd6 <acquire>
  lk->locked = 0;
    80004552:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004556:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000455a:	8526                	mv	a0,s1
    8000455c:	ffffe097          	auipc	ra,0xffffe
    80004560:	fc6080e7          	jalr	-58(ra) # 80002522 <wakeup>
  release(&lk->lk);
    80004564:	854a                	mv	a0,s2
    80004566:	ffffd097          	auipc	ra,0xffffd
    8000456a:	824080e7          	jalr	-2012(ra) # 80000d8a <release>
}
    8000456e:	60e2                	ld	ra,24(sp)
    80004570:	6442                	ld	s0,16(sp)
    80004572:	64a2                	ld	s1,8(sp)
    80004574:	6902                	ld	s2,0(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000457a:	7179                	addi	sp,sp,-48
    8000457c:	f406                	sd	ra,40(sp)
    8000457e:	f022                	sd	s0,32(sp)
    80004580:	ec26                	sd	s1,24(sp)
    80004582:	e84a                	sd	s2,16(sp)
    80004584:	e44e                	sd	s3,8(sp)
    80004586:	1800                	addi	s0,sp,48
    80004588:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000458a:	00850913          	addi	s2,a0,8
    8000458e:	854a                	mv	a0,s2
    80004590:	ffffc097          	auipc	ra,0xffffc
    80004594:	746080e7          	jalr	1862(ra) # 80000cd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004598:	409c                	lw	a5,0(s1)
    8000459a:	ef99                	bnez	a5,800045b8 <holdingsleep+0x3e>
    8000459c:	4481                	li	s1,0
  release(&lk->lk);
    8000459e:	854a                	mv	a0,s2
    800045a0:	ffffc097          	auipc	ra,0xffffc
    800045a4:	7ea080e7          	jalr	2026(ra) # 80000d8a <release>
  return r;
}
    800045a8:	8526                	mv	a0,s1
    800045aa:	70a2                	ld	ra,40(sp)
    800045ac:	7402                	ld	s0,32(sp)
    800045ae:	64e2                	ld	s1,24(sp)
    800045b0:	6942                	ld	s2,16(sp)
    800045b2:	69a2                	ld	s3,8(sp)
    800045b4:	6145                	addi	sp,sp,48
    800045b6:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800045b8:	0284a983          	lw	s3,40(s1)
    800045bc:	ffffd097          	auipc	ra,0xffffd
    800045c0:	5d0080e7          	jalr	1488(ra) # 80001b8c <myproc>
    800045c4:	5d04                	lw	s1,56(a0)
    800045c6:	413484b3          	sub	s1,s1,s3
    800045ca:	0014b493          	seqz	s1,s1
    800045ce:	bfc1                	j	8000459e <holdingsleep+0x24>

00000000800045d0 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800045d0:	1141                	addi	sp,sp,-16
    800045d2:	e406                	sd	ra,8(sp)
    800045d4:	e022                	sd	s0,0(sp)
    800045d6:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800045d8:	00004597          	auipc	a1,0x4
    800045dc:	08858593          	addi	a1,a1,136 # 80008660 <syscalls+0x238>
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	47850513          	addi	a0,a0,1144 # 80021a58 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	65e080e7          	jalr	1630(ra) # 80000c46 <initlock>
}
    800045f0:	60a2                	ld	ra,8(sp)
    800045f2:	6402                	ld	s0,0(sp)
    800045f4:	0141                	addi	sp,sp,16
    800045f6:	8082                	ret

00000000800045f8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004602:	0001d517          	auipc	a0,0x1d
    80004606:	45650513          	addi	a0,a0,1110 # 80021a58 <ftable>
    8000460a:	ffffc097          	auipc	ra,0xffffc
    8000460e:	6cc080e7          	jalr	1740(ra) # 80000cd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004612:	0001d497          	auipc	s1,0x1d
    80004616:	45e48493          	addi	s1,s1,1118 # 80021a70 <ftable+0x18>
    8000461a:	0001e717          	auipc	a4,0x1e
    8000461e:	3f670713          	addi	a4,a4,1014 # 80022a10 <ftable+0xfb8>
    if(f->ref == 0){
    80004622:	40dc                	lw	a5,4(s1)
    80004624:	cf99                	beqz	a5,80004642 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004626:	02848493          	addi	s1,s1,40
    8000462a:	fee49ce3          	bne	s1,a4,80004622 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000462e:	0001d517          	auipc	a0,0x1d
    80004632:	42a50513          	addi	a0,a0,1066 # 80021a58 <ftable>
    80004636:	ffffc097          	auipc	ra,0xffffc
    8000463a:	754080e7          	jalr	1876(ra) # 80000d8a <release>
  return 0;
    8000463e:	4481                	li	s1,0
    80004640:	a819                	j	80004656 <filealloc+0x5e>
      f->ref = 1;
    80004642:	4785                	li	a5,1
    80004644:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004646:	0001d517          	auipc	a0,0x1d
    8000464a:	41250513          	addi	a0,a0,1042 # 80021a58 <ftable>
    8000464e:	ffffc097          	auipc	ra,0xffffc
    80004652:	73c080e7          	jalr	1852(ra) # 80000d8a <release>
}
    80004656:	8526                	mv	a0,s1
    80004658:	60e2                	ld	ra,24(sp)
    8000465a:	6442                	ld	s0,16(sp)
    8000465c:	64a2                	ld	s1,8(sp)
    8000465e:	6105                	addi	sp,sp,32
    80004660:	8082                	ret

0000000080004662 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004662:	1101                	addi	sp,sp,-32
    80004664:	ec06                	sd	ra,24(sp)
    80004666:	e822                	sd	s0,16(sp)
    80004668:	e426                	sd	s1,8(sp)
    8000466a:	1000                	addi	s0,sp,32
    8000466c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000466e:	0001d517          	auipc	a0,0x1d
    80004672:	3ea50513          	addi	a0,a0,1002 # 80021a58 <ftable>
    80004676:	ffffc097          	auipc	ra,0xffffc
    8000467a:	660080e7          	jalr	1632(ra) # 80000cd6 <acquire>
  if(f->ref < 1)
    8000467e:	40dc                	lw	a5,4(s1)
    80004680:	02f05263          	blez	a5,800046a4 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004684:	2785                	addiw	a5,a5,1
    80004686:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004688:	0001d517          	auipc	a0,0x1d
    8000468c:	3d050513          	addi	a0,a0,976 # 80021a58 <ftable>
    80004690:	ffffc097          	auipc	ra,0xffffc
    80004694:	6fa080e7          	jalr	1786(ra) # 80000d8a <release>
  return f;
}
    80004698:	8526                	mv	a0,s1
    8000469a:	60e2                	ld	ra,24(sp)
    8000469c:	6442                	ld	s0,16(sp)
    8000469e:	64a2                	ld	s1,8(sp)
    800046a0:	6105                	addi	sp,sp,32
    800046a2:	8082                	ret
    panic("filedup");
    800046a4:	00004517          	auipc	a0,0x4
    800046a8:	fc450513          	addi	a0,a0,-60 # 80008668 <syscalls+0x240>
    800046ac:	ffffc097          	auipc	ra,0xffffc
    800046b0:	e9c080e7          	jalr	-356(ra) # 80000548 <panic>

00000000800046b4 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800046b4:	7139                	addi	sp,sp,-64
    800046b6:	fc06                	sd	ra,56(sp)
    800046b8:	f822                	sd	s0,48(sp)
    800046ba:	f426                	sd	s1,40(sp)
    800046bc:	f04a                	sd	s2,32(sp)
    800046be:	ec4e                	sd	s3,24(sp)
    800046c0:	e852                	sd	s4,16(sp)
    800046c2:	e456                	sd	s5,8(sp)
    800046c4:	0080                	addi	s0,sp,64
    800046c6:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800046c8:	0001d517          	auipc	a0,0x1d
    800046cc:	39050513          	addi	a0,a0,912 # 80021a58 <ftable>
    800046d0:	ffffc097          	auipc	ra,0xffffc
    800046d4:	606080e7          	jalr	1542(ra) # 80000cd6 <acquire>
  if(f->ref < 1)
    800046d8:	40dc                	lw	a5,4(s1)
    800046da:	06f05163          	blez	a5,8000473c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800046de:	37fd                	addiw	a5,a5,-1
    800046e0:	0007871b          	sext.w	a4,a5
    800046e4:	c0dc                	sw	a5,4(s1)
    800046e6:	06e04363          	bgtz	a4,8000474c <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800046ea:	0004a903          	lw	s2,0(s1)
    800046ee:	0094ca83          	lbu	s5,9(s1)
    800046f2:	0104ba03          	ld	s4,16(s1)
    800046f6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800046fa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800046fe:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004702:	0001d517          	auipc	a0,0x1d
    80004706:	35650513          	addi	a0,a0,854 # 80021a58 <ftable>
    8000470a:	ffffc097          	auipc	ra,0xffffc
    8000470e:	680080e7          	jalr	1664(ra) # 80000d8a <release>

  if(ff.type == FD_PIPE){
    80004712:	4785                	li	a5,1
    80004714:	04f90d63          	beq	s2,a5,8000476e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004718:	3979                	addiw	s2,s2,-2
    8000471a:	4785                	li	a5,1
    8000471c:	0527e063          	bltu	a5,s2,8000475c <fileclose+0xa8>
    begin_op();
    80004720:	00000097          	auipc	ra,0x0
    80004724:	ac2080e7          	jalr	-1342(ra) # 800041e2 <begin_op>
    iput(ff.ip);
    80004728:	854e                	mv	a0,s3
    8000472a:	fffff097          	auipc	ra,0xfffff
    8000472e:	2b2080e7          	jalr	690(ra) # 800039dc <iput>
    end_op();
    80004732:	00000097          	auipc	ra,0x0
    80004736:	b30080e7          	jalr	-1232(ra) # 80004262 <end_op>
    8000473a:	a00d                	j	8000475c <fileclose+0xa8>
    panic("fileclose");
    8000473c:	00004517          	auipc	a0,0x4
    80004740:	f3450513          	addi	a0,a0,-204 # 80008670 <syscalls+0x248>
    80004744:	ffffc097          	auipc	ra,0xffffc
    80004748:	e04080e7          	jalr	-508(ra) # 80000548 <panic>
    release(&ftable.lock);
    8000474c:	0001d517          	auipc	a0,0x1d
    80004750:	30c50513          	addi	a0,a0,780 # 80021a58 <ftable>
    80004754:	ffffc097          	auipc	ra,0xffffc
    80004758:	636080e7          	jalr	1590(ra) # 80000d8a <release>
  }
}
    8000475c:	70e2                	ld	ra,56(sp)
    8000475e:	7442                	ld	s0,48(sp)
    80004760:	74a2                	ld	s1,40(sp)
    80004762:	7902                	ld	s2,32(sp)
    80004764:	69e2                	ld	s3,24(sp)
    80004766:	6a42                	ld	s4,16(sp)
    80004768:	6aa2                	ld	s5,8(sp)
    8000476a:	6121                	addi	sp,sp,64
    8000476c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000476e:	85d6                	mv	a1,s5
    80004770:	8552                	mv	a0,s4
    80004772:	00000097          	auipc	ra,0x0
    80004776:	372080e7          	jalr	882(ra) # 80004ae4 <pipeclose>
    8000477a:	b7cd                	j	8000475c <fileclose+0xa8>

000000008000477c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000477c:	715d                	addi	sp,sp,-80
    8000477e:	e486                	sd	ra,72(sp)
    80004780:	e0a2                	sd	s0,64(sp)
    80004782:	fc26                	sd	s1,56(sp)
    80004784:	f84a                	sd	s2,48(sp)
    80004786:	f44e                	sd	s3,40(sp)
    80004788:	0880                	addi	s0,sp,80
    8000478a:	84aa                	mv	s1,a0
    8000478c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000478e:	ffffd097          	auipc	ra,0xffffd
    80004792:	3fe080e7          	jalr	1022(ra) # 80001b8c <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004796:	409c                	lw	a5,0(s1)
    80004798:	37f9                	addiw	a5,a5,-2
    8000479a:	4705                	li	a4,1
    8000479c:	04f76763          	bltu	a4,a5,800047ea <filestat+0x6e>
    800047a0:	892a                	mv	s2,a0
    ilock(f->ip);
    800047a2:	6c88                	ld	a0,24(s1)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	07e080e7          	jalr	126(ra) # 80003822 <ilock>
    stati(f->ip, &st);
    800047ac:	fb840593          	addi	a1,s0,-72
    800047b0:	6c88                	ld	a0,24(s1)
    800047b2:	fffff097          	auipc	ra,0xfffff
    800047b6:	2fa080e7          	jalr	762(ra) # 80003aac <stati>
    iunlock(f->ip);
    800047ba:	6c88                	ld	a0,24(s1)
    800047bc:	fffff097          	auipc	ra,0xfffff
    800047c0:	128080e7          	jalr	296(ra) # 800038e4 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800047c4:	46e1                	li	a3,24
    800047c6:	fb840613          	addi	a2,s0,-72
    800047ca:	85ce                	mv	a1,s3
    800047cc:	05093503          	ld	a0,80(s2)
    800047d0:	ffffd097          	auipc	ra,0xffffd
    800047d4:	1a6080e7          	jalr	422(ra) # 80001976 <copyout>
    800047d8:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800047dc:	60a6                	ld	ra,72(sp)
    800047de:	6406                	ld	s0,64(sp)
    800047e0:	74e2                	ld	s1,56(sp)
    800047e2:	7942                	ld	s2,48(sp)
    800047e4:	79a2                	ld	s3,40(sp)
    800047e6:	6161                	addi	sp,sp,80
    800047e8:	8082                	ret
  return -1;
    800047ea:	557d                	li	a0,-1
    800047ec:	bfc5                	j	800047dc <filestat+0x60>

00000000800047ee <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800047ee:	7179                	addi	sp,sp,-48
    800047f0:	f406                	sd	ra,40(sp)
    800047f2:	f022                	sd	s0,32(sp)
    800047f4:	ec26                	sd	s1,24(sp)
    800047f6:	e84a                	sd	s2,16(sp)
    800047f8:	e44e                	sd	s3,8(sp)
    800047fa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800047fc:	00854783          	lbu	a5,8(a0)
    80004800:	c3d5                	beqz	a5,800048a4 <fileread+0xb6>
    80004802:	84aa                	mv	s1,a0
    80004804:	89ae                	mv	s3,a1
    80004806:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004808:	411c                	lw	a5,0(a0)
    8000480a:	4705                	li	a4,1
    8000480c:	04e78963          	beq	a5,a4,8000485e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004810:	470d                	li	a4,3
    80004812:	04e78d63          	beq	a5,a4,8000486c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004816:	4709                	li	a4,2
    80004818:	06e79e63          	bne	a5,a4,80004894 <fileread+0xa6>
    ilock(f->ip);
    8000481c:	6d08                	ld	a0,24(a0)
    8000481e:	fffff097          	auipc	ra,0xfffff
    80004822:	004080e7          	jalr	4(ra) # 80003822 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004826:	874a                	mv	a4,s2
    80004828:	5094                	lw	a3,32(s1)
    8000482a:	864e                	mv	a2,s3
    8000482c:	4585                	li	a1,1
    8000482e:	6c88                	ld	a0,24(s1)
    80004830:	fffff097          	auipc	ra,0xfffff
    80004834:	2a6080e7          	jalr	678(ra) # 80003ad6 <readi>
    80004838:	892a                	mv	s2,a0
    8000483a:	00a05563          	blez	a0,80004844 <fileread+0x56>
      f->off += r;
    8000483e:	509c                	lw	a5,32(s1)
    80004840:	9fa9                	addw	a5,a5,a0
    80004842:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004844:	6c88                	ld	a0,24(s1)
    80004846:	fffff097          	auipc	ra,0xfffff
    8000484a:	09e080e7          	jalr	158(ra) # 800038e4 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    8000484e:	854a                	mv	a0,s2
    80004850:	70a2                	ld	ra,40(sp)
    80004852:	7402                	ld	s0,32(sp)
    80004854:	64e2                	ld	s1,24(sp)
    80004856:	6942                	ld	s2,16(sp)
    80004858:	69a2                	ld	s3,8(sp)
    8000485a:	6145                	addi	sp,sp,48
    8000485c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000485e:	6908                	ld	a0,16(a0)
    80004860:	00000097          	auipc	ra,0x0
    80004864:	418080e7          	jalr	1048(ra) # 80004c78 <piperead>
    80004868:	892a                	mv	s2,a0
    8000486a:	b7d5                	j	8000484e <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000486c:	02451783          	lh	a5,36(a0)
    80004870:	03079693          	slli	a3,a5,0x30
    80004874:	92c1                	srli	a3,a3,0x30
    80004876:	4725                	li	a4,9
    80004878:	02d76863          	bltu	a4,a3,800048a8 <fileread+0xba>
    8000487c:	0792                	slli	a5,a5,0x4
    8000487e:	0001d717          	auipc	a4,0x1d
    80004882:	13a70713          	addi	a4,a4,314 # 800219b8 <devsw>
    80004886:	97ba                	add	a5,a5,a4
    80004888:	639c                	ld	a5,0(a5)
    8000488a:	c38d                	beqz	a5,800048ac <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000488c:	4505                	li	a0,1
    8000488e:	9782                	jalr	a5
    80004890:	892a                	mv	s2,a0
    80004892:	bf75                	j	8000484e <fileread+0x60>
    panic("fileread");
    80004894:	00004517          	auipc	a0,0x4
    80004898:	dec50513          	addi	a0,a0,-532 # 80008680 <syscalls+0x258>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
    return -1;
    800048a4:	597d                	li	s2,-1
    800048a6:	b765                	j	8000484e <fileread+0x60>
      return -1;
    800048a8:	597d                	li	s2,-1
    800048aa:	b755                	j	8000484e <fileread+0x60>
    800048ac:	597d                	li	s2,-1
    800048ae:	b745                	j	8000484e <fileread+0x60>

00000000800048b0 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800048b0:	00954783          	lbu	a5,9(a0)
    800048b4:	14078563          	beqz	a5,800049fe <filewrite+0x14e>
{
    800048b8:	715d                	addi	sp,sp,-80
    800048ba:	e486                	sd	ra,72(sp)
    800048bc:	e0a2                	sd	s0,64(sp)
    800048be:	fc26                	sd	s1,56(sp)
    800048c0:	f84a                	sd	s2,48(sp)
    800048c2:	f44e                	sd	s3,40(sp)
    800048c4:	f052                	sd	s4,32(sp)
    800048c6:	ec56                	sd	s5,24(sp)
    800048c8:	e85a                	sd	s6,16(sp)
    800048ca:	e45e                	sd	s7,8(sp)
    800048cc:	e062                	sd	s8,0(sp)
    800048ce:	0880                	addi	s0,sp,80
    800048d0:	892a                	mv	s2,a0
    800048d2:	8aae                	mv	s5,a1
    800048d4:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800048d6:	411c                	lw	a5,0(a0)
    800048d8:	4705                	li	a4,1
    800048da:	02e78263          	beq	a5,a4,800048fe <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048de:	470d                	li	a4,3
    800048e0:	02e78563          	beq	a5,a4,8000490a <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800048e4:	4709                	li	a4,2
    800048e6:	10e79463          	bne	a5,a4,800049ee <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800048ea:	0ec05e63          	blez	a2,800049e6 <filewrite+0x136>
    int i = 0;
    800048ee:	4981                	li	s3,0
    800048f0:	6b05                	lui	s6,0x1
    800048f2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800048f6:	6b85                	lui	s7,0x1
    800048f8:	c00b8b9b          	addiw	s7,s7,-1024
    800048fc:	a851                	j	80004990 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    800048fe:	6908                	ld	a0,16(a0)
    80004900:	00000097          	auipc	ra,0x0
    80004904:	254080e7          	jalr	596(ra) # 80004b54 <pipewrite>
    80004908:	a85d                	j	800049be <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000490a:	02451783          	lh	a5,36(a0)
    8000490e:	03079693          	slli	a3,a5,0x30
    80004912:	92c1                	srli	a3,a3,0x30
    80004914:	4725                	li	a4,9
    80004916:	0ed76663          	bltu	a4,a3,80004a02 <filewrite+0x152>
    8000491a:	0792                	slli	a5,a5,0x4
    8000491c:	0001d717          	auipc	a4,0x1d
    80004920:	09c70713          	addi	a4,a4,156 # 800219b8 <devsw>
    80004924:	97ba                	add	a5,a5,a4
    80004926:	679c                	ld	a5,8(a5)
    80004928:	cff9                	beqz	a5,80004a06 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    8000492a:	4505                	li	a0,1
    8000492c:	9782                	jalr	a5
    8000492e:	a841                	j	800049be <filewrite+0x10e>
    80004930:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004934:	00000097          	auipc	ra,0x0
    80004938:	8ae080e7          	jalr	-1874(ra) # 800041e2 <begin_op>
      ilock(f->ip);
    8000493c:	01893503          	ld	a0,24(s2)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	ee2080e7          	jalr	-286(ra) # 80003822 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004948:	8762                	mv	a4,s8
    8000494a:	02092683          	lw	a3,32(s2)
    8000494e:	01598633          	add	a2,s3,s5
    80004952:	4585                	li	a1,1
    80004954:	01893503          	ld	a0,24(s2)
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	276080e7          	jalr	630(ra) # 80003bce <writei>
    80004960:	84aa                	mv	s1,a0
    80004962:	02a05f63          	blez	a0,800049a0 <filewrite+0xf0>
        f->off += r;
    80004966:	02092783          	lw	a5,32(s2)
    8000496a:	9fa9                	addw	a5,a5,a0
    8000496c:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004970:	01893503          	ld	a0,24(s2)
    80004974:	fffff097          	auipc	ra,0xfffff
    80004978:	f70080e7          	jalr	-144(ra) # 800038e4 <iunlock>
      end_op();
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	8e6080e7          	jalr	-1818(ra) # 80004262 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004984:	049c1963          	bne	s8,s1,800049d6 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004988:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000498c:	0349d663          	bge	s3,s4,800049b8 <filewrite+0x108>
      int n1 = n - i;
    80004990:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004994:	84be                	mv	s1,a5
    80004996:	2781                	sext.w	a5,a5
    80004998:	f8fb5ce3          	bge	s6,a5,80004930 <filewrite+0x80>
    8000499c:	84de                	mv	s1,s7
    8000499e:	bf49                	j	80004930 <filewrite+0x80>
      iunlock(f->ip);
    800049a0:	01893503          	ld	a0,24(s2)
    800049a4:	fffff097          	auipc	ra,0xfffff
    800049a8:	f40080e7          	jalr	-192(ra) # 800038e4 <iunlock>
      end_op();
    800049ac:	00000097          	auipc	ra,0x0
    800049b0:	8b6080e7          	jalr	-1866(ra) # 80004262 <end_op>
      if(r < 0)
    800049b4:	fc04d8e3          	bgez	s1,80004984 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800049b8:	8552                	mv	a0,s4
    800049ba:	033a1863          	bne	s4,s3,800049ea <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800049be:	60a6                	ld	ra,72(sp)
    800049c0:	6406                	ld	s0,64(sp)
    800049c2:	74e2                	ld	s1,56(sp)
    800049c4:	7942                	ld	s2,48(sp)
    800049c6:	79a2                	ld	s3,40(sp)
    800049c8:	7a02                	ld	s4,32(sp)
    800049ca:	6ae2                	ld	s5,24(sp)
    800049cc:	6b42                	ld	s6,16(sp)
    800049ce:	6ba2                	ld	s7,8(sp)
    800049d0:	6c02                	ld	s8,0(sp)
    800049d2:	6161                	addi	sp,sp,80
    800049d4:	8082                	ret
        panic("short filewrite");
    800049d6:	00004517          	auipc	a0,0x4
    800049da:	cba50513          	addi	a0,a0,-838 # 80008690 <syscalls+0x268>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	b6a080e7          	jalr	-1174(ra) # 80000548 <panic>
    int i = 0;
    800049e6:	4981                	li	s3,0
    800049e8:	bfc1                	j	800049b8 <filewrite+0x108>
    ret = (i == n ? n : -1);
    800049ea:	557d                	li	a0,-1
    800049ec:	bfc9                	j	800049be <filewrite+0x10e>
    panic("filewrite");
    800049ee:	00004517          	auipc	a0,0x4
    800049f2:	cb250513          	addi	a0,a0,-846 # 800086a0 <syscalls+0x278>
    800049f6:	ffffc097          	auipc	ra,0xffffc
    800049fa:	b52080e7          	jalr	-1198(ra) # 80000548 <panic>
    return -1;
    800049fe:	557d                	li	a0,-1
}
    80004a00:	8082                	ret
      return -1;
    80004a02:	557d                	li	a0,-1
    80004a04:	bf6d                	j	800049be <filewrite+0x10e>
    80004a06:	557d                	li	a0,-1
    80004a08:	bf5d                	j	800049be <filewrite+0x10e>

0000000080004a0a <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a0a:	7179                	addi	sp,sp,-48
    80004a0c:	f406                	sd	ra,40(sp)
    80004a0e:	f022                	sd	s0,32(sp)
    80004a10:	ec26                	sd	s1,24(sp)
    80004a12:	e84a                	sd	s2,16(sp)
    80004a14:	e44e                	sd	s3,8(sp)
    80004a16:	e052                	sd	s4,0(sp)
    80004a18:	1800                	addi	s0,sp,48
    80004a1a:	84aa                	mv	s1,a0
    80004a1c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004a1e:	0005b023          	sd	zero,0(a1)
    80004a22:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004a26:	00000097          	auipc	ra,0x0
    80004a2a:	bd2080e7          	jalr	-1070(ra) # 800045f8 <filealloc>
    80004a2e:	e088                	sd	a0,0(s1)
    80004a30:	c551                	beqz	a0,80004abc <pipealloc+0xb2>
    80004a32:	00000097          	auipc	ra,0x0
    80004a36:	bc6080e7          	jalr	-1082(ra) # 800045f8 <filealloc>
    80004a3a:	00aa3023          	sd	a0,0(s4)
    80004a3e:	c92d                	beqz	a0,80004ab0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004a40:	ffffc097          	auipc	ra,0xffffc
    80004a44:	138080e7          	jalr	312(ra) # 80000b78 <kalloc>
    80004a48:	892a                	mv	s2,a0
    80004a4a:	c125                	beqz	a0,80004aaa <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004a4c:	4985                	li	s3,1
    80004a4e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004a52:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004a56:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004a5a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004a5e:	00004597          	auipc	a1,0x4
    80004a62:	c5258593          	addi	a1,a1,-942 # 800086b0 <syscalls+0x288>
    80004a66:	ffffc097          	auipc	ra,0xffffc
    80004a6a:	1e0080e7          	jalr	480(ra) # 80000c46 <initlock>
  (*f0)->type = FD_PIPE;
    80004a6e:	609c                	ld	a5,0(s1)
    80004a70:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a74:	609c                	ld	a5,0(s1)
    80004a76:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a7a:	609c                	ld	a5,0(s1)
    80004a7c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a80:	609c                	ld	a5,0(s1)
    80004a82:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a86:	000a3783          	ld	a5,0(s4)
    80004a8a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a8e:	000a3783          	ld	a5,0(s4)
    80004a92:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a96:	000a3783          	ld	a5,0(s4)
    80004a9a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a9e:	000a3783          	ld	a5,0(s4)
    80004aa2:	0127b823          	sd	s2,16(a5)
  return 0;
    80004aa6:	4501                	li	a0,0
    80004aa8:	a025                	j	80004ad0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004aaa:	6088                	ld	a0,0(s1)
    80004aac:	e501                	bnez	a0,80004ab4 <pipealloc+0xaa>
    80004aae:	a039                	j	80004abc <pipealloc+0xb2>
    80004ab0:	6088                	ld	a0,0(s1)
    80004ab2:	c51d                	beqz	a0,80004ae0 <pipealloc+0xd6>
    fileclose(*f0);
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	c00080e7          	jalr	-1024(ra) # 800046b4 <fileclose>
  if(*f1)
    80004abc:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004ac0:	557d                	li	a0,-1
  if(*f1)
    80004ac2:	c799                	beqz	a5,80004ad0 <pipealloc+0xc6>
    fileclose(*f1);
    80004ac4:	853e                	mv	a0,a5
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	bee080e7          	jalr	-1042(ra) # 800046b4 <fileclose>
  return -1;
    80004ace:	557d                	li	a0,-1
}
    80004ad0:	70a2                	ld	ra,40(sp)
    80004ad2:	7402                	ld	s0,32(sp)
    80004ad4:	64e2                	ld	s1,24(sp)
    80004ad6:	6942                	ld	s2,16(sp)
    80004ad8:	69a2                	ld	s3,8(sp)
    80004ada:	6a02                	ld	s4,0(sp)
    80004adc:	6145                	addi	sp,sp,48
    80004ade:	8082                	ret
  return -1;
    80004ae0:	557d                	li	a0,-1
    80004ae2:	b7fd                	j	80004ad0 <pipealloc+0xc6>

0000000080004ae4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004ae4:	1101                	addi	sp,sp,-32
    80004ae6:	ec06                	sd	ra,24(sp)
    80004ae8:	e822                	sd	s0,16(sp)
    80004aea:	e426                	sd	s1,8(sp)
    80004aec:	e04a                	sd	s2,0(sp)
    80004aee:	1000                	addi	s0,sp,32
    80004af0:	84aa                	mv	s1,a0
    80004af2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004af4:	ffffc097          	auipc	ra,0xffffc
    80004af8:	1e2080e7          	jalr	482(ra) # 80000cd6 <acquire>
  if(writable){
    80004afc:	02090d63          	beqz	s2,80004b36 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b00:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b04:	21848513          	addi	a0,s1,536
    80004b08:	ffffe097          	auipc	ra,0xffffe
    80004b0c:	a1a080e7          	jalr	-1510(ra) # 80002522 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b10:	2204b783          	ld	a5,544(s1)
    80004b14:	eb95                	bnez	a5,80004b48 <pipeclose+0x64>
    release(&pi->lock);
    80004b16:	8526                	mv	a0,s1
    80004b18:	ffffc097          	auipc	ra,0xffffc
    80004b1c:	272080e7          	jalr	626(ra) # 80000d8a <release>
    kfree((char*)pi);
    80004b20:	8526                	mv	a0,s1
    80004b22:	ffffc097          	auipc	ra,0xffffc
    80004b26:	f02080e7          	jalr	-254(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004b2a:	60e2                	ld	ra,24(sp)
    80004b2c:	6442                	ld	s0,16(sp)
    80004b2e:	64a2                	ld	s1,8(sp)
    80004b30:	6902                	ld	s2,0(sp)
    80004b32:	6105                	addi	sp,sp,32
    80004b34:	8082                	ret
    pi->readopen = 0;
    80004b36:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004b3a:	21c48513          	addi	a0,s1,540
    80004b3e:	ffffe097          	auipc	ra,0xffffe
    80004b42:	9e4080e7          	jalr	-1564(ra) # 80002522 <wakeup>
    80004b46:	b7e9                	j	80004b10 <pipeclose+0x2c>
    release(&pi->lock);
    80004b48:	8526                	mv	a0,s1
    80004b4a:	ffffc097          	auipc	ra,0xffffc
    80004b4e:	240080e7          	jalr	576(ra) # 80000d8a <release>
}
    80004b52:	bfe1                	j	80004b2a <pipeclose+0x46>

0000000080004b54 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004b54:	7119                	addi	sp,sp,-128
    80004b56:	fc86                	sd	ra,120(sp)
    80004b58:	f8a2                	sd	s0,112(sp)
    80004b5a:	f4a6                	sd	s1,104(sp)
    80004b5c:	f0ca                	sd	s2,96(sp)
    80004b5e:	ecce                	sd	s3,88(sp)
    80004b60:	e8d2                	sd	s4,80(sp)
    80004b62:	e4d6                	sd	s5,72(sp)
    80004b64:	e0da                	sd	s6,64(sp)
    80004b66:	fc5e                	sd	s7,56(sp)
    80004b68:	f862                	sd	s8,48(sp)
    80004b6a:	f466                	sd	s9,40(sp)
    80004b6c:	f06a                	sd	s10,32(sp)
    80004b6e:	ec6e                	sd	s11,24(sp)
    80004b70:	0100                	addi	s0,sp,128
    80004b72:	84aa                	mv	s1,a0
    80004b74:	8cae                	mv	s9,a1
    80004b76:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b78:	ffffd097          	auipc	ra,0xffffd
    80004b7c:	014080e7          	jalr	20(ra) # 80001b8c <myproc>
    80004b80:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b82:	8526                	mv	a0,s1
    80004b84:	ffffc097          	auipc	ra,0xffffc
    80004b88:	152080e7          	jalr	338(ra) # 80000cd6 <acquire>
  for(i = 0; i < n; i++){
    80004b8c:	0d605963          	blez	s6,80004c5e <pipewrite+0x10a>
    80004b90:	89a6                	mv	s3,s1
    80004b92:	3b7d                	addiw	s6,s6,-1
    80004b94:	1b02                	slli	s6,s6,0x20
    80004b96:	020b5b13          	srli	s6,s6,0x20
    80004b9a:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b9c:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ba0:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ba4:	5dfd                	li	s11,-1
    80004ba6:	000b8d1b          	sext.w	s10,s7
    80004baa:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bac:	2184a783          	lw	a5,536(s1)
    80004bb0:	21c4a703          	lw	a4,540(s1)
    80004bb4:	2007879b          	addiw	a5,a5,512
    80004bb8:	02f71b63          	bne	a4,a5,80004bee <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004bbc:	2204a783          	lw	a5,544(s1)
    80004bc0:	cbad                	beqz	a5,80004c32 <pipewrite+0xde>
    80004bc2:	03092783          	lw	a5,48(s2)
    80004bc6:	e7b5                	bnez	a5,80004c32 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004bc8:	8556                	mv	a0,s5
    80004bca:	ffffe097          	auipc	ra,0xffffe
    80004bce:	958080e7          	jalr	-1704(ra) # 80002522 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004bd2:	85ce                	mv	a1,s3
    80004bd4:	8552                	mv	a0,s4
    80004bd6:	ffffd097          	auipc	ra,0xffffd
    80004bda:	7c6080e7          	jalr	1990(ra) # 8000239c <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004bde:	2184a783          	lw	a5,536(s1)
    80004be2:	21c4a703          	lw	a4,540(s1)
    80004be6:	2007879b          	addiw	a5,a5,512
    80004bea:	fcf709e3          	beq	a4,a5,80004bbc <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004bee:	4685                	li	a3,1
    80004bf0:	019b8633          	add	a2,s7,s9
    80004bf4:	f8f40593          	addi	a1,s0,-113
    80004bf8:	05093503          	ld	a0,80(s2)
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	b9a080e7          	jalr	-1126(ra) # 80001796 <copyin>
    80004c04:	05b50e63          	beq	a0,s11,80004c60 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c08:	21c4a783          	lw	a5,540(s1)
    80004c0c:	0017871b          	addiw	a4,a5,1
    80004c10:	20e4ae23          	sw	a4,540(s1)
    80004c14:	1ff7f793          	andi	a5,a5,511
    80004c18:	97a6                	add	a5,a5,s1
    80004c1a:	f8f44703          	lbu	a4,-113(s0)
    80004c1e:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004c22:	001d0c1b          	addiw	s8,s10,1
    80004c26:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004c2a:	036b8b63          	beq	s7,s6,80004c60 <pipewrite+0x10c>
    80004c2e:	8bbe                	mv	s7,a5
    80004c30:	bf9d                	j	80004ba6 <pipewrite+0x52>
        release(&pi->lock);
    80004c32:	8526                	mv	a0,s1
    80004c34:	ffffc097          	auipc	ra,0xffffc
    80004c38:	156080e7          	jalr	342(ra) # 80000d8a <release>
        return -1;
    80004c3c:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004c3e:	8562                	mv	a0,s8
    80004c40:	70e6                	ld	ra,120(sp)
    80004c42:	7446                	ld	s0,112(sp)
    80004c44:	74a6                	ld	s1,104(sp)
    80004c46:	7906                	ld	s2,96(sp)
    80004c48:	69e6                	ld	s3,88(sp)
    80004c4a:	6a46                	ld	s4,80(sp)
    80004c4c:	6aa6                	ld	s5,72(sp)
    80004c4e:	6b06                	ld	s6,64(sp)
    80004c50:	7be2                	ld	s7,56(sp)
    80004c52:	7c42                	ld	s8,48(sp)
    80004c54:	7ca2                	ld	s9,40(sp)
    80004c56:	7d02                	ld	s10,32(sp)
    80004c58:	6de2                	ld	s11,24(sp)
    80004c5a:	6109                	addi	sp,sp,128
    80004c5c:	8082                	ret
  for(i = 0; i < n; i++){
    80004c5e:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004c60:	21848513          	addi	a0,s1,536
    80004c64:	ffffe097          	auipc	ra,0xffffe
    80004c68:	8be080e7          	jalr	-1858(ra) # 80002522 <wakeup>
  release(&pi->lock);
    80004c6c:	8526                	mv	a0,s1
    80004c6e:	ffffc097          	auipc	ra,0xffffc
    80004c72:	11c080e7          	jalr	284(ra) # 80000d8a <release>
  return i;
    80004c76:	b7e1                	j	80004c3e <pipewrite+0xea>

0000000080004c78 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c78:	715d                	addi	sp,sp,-80
    80004c7a:	e486                	sd	ra,72(sp)
    80004c7c:	e0a2                	sd	s0,64(sp)
    80004c7e:	fc26                	sd	s1,56(sp)
    80004c80:	f84a                	sd	s2,48(sp)
    80004c82:	f44e                	sd	s3,40(sp)
    80004c84:	f052                	sd	s4,32(sp)
    80004c86:	ec56                	sd	s5,24(sp)
    80004c88:	e85a                	sd	s6,16(sp)
    80004c8a:	0880                	addi	s0,sp,80
    80004c8c:	84aa                	mv	s1,a0
    80004c8e:	892e                	mv	s2,a1
    80004c90:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	efa080e7          	jalr	-262(ra) # 80001b8c <myproc>
    80004c9a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c9c:	8b26                	mv	s6,s1
    80004c9e:	8526                	mv	a0,s1
    80004ca0:	ffffc097          	auipc	ra,0xffffc
    80004ca4:	036080e7          	jalr	54(ra) # 80000cd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004ca8:	2184a703          	lw	a4,536(s1)
    80004cac:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cb0:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cb4:	02f71463          	bne	a4,a5,80004cdc <piperead+0x64>
    80004cb8:	2244a783          	lw	a5,548(s1)
    80004cbc:	c385                	beqz	a5,80004cdc <piperead+0x64>
    if(pr->killed){
    80004cbe:	030a2783          	lw	a5,48(s4)
    80004cc2:	ebc1                	bnez	a5,80004d52 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004cc4:	85da                	mv	a1,s6
    80004cc6:	854e                	mv	a0,s3
    80004cc8:	ffffd097          	auipc	ra,0xffffd
    80004ccc:	6d4080e7          	jalr	1748(ra) # 8000239c <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004cd0:	2184a703          	lw	a4,536(s1)
    80004cd4:	21c4a783          	lw	a5,540(s1)
    80004cd8:	fef700e3          	beq	a4,a5,80004cb8 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cdc:	09505263          	blez	s5,80004d60 <piperead+0xe8>
    80004ce0:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ce2:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004ce4:	2184a783          	lw	a5,536(s1)
    80004ce8:	21c4a703          	lw	a4,540(s1)
    80004cec:	02f70d63          	beq	a4,a5,80004d26 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004cf0:	0017871b          	addiw	a4,a5,1
    80004cf4:	20e4ac23          	sw	a4,536(s1)
    80004cf8:	1ff7f793          	andi	a5,a5,511
    80004cfc:	97a6                	add	a5,a5,s1
    80004cfe:	0187c783          	lbu	a5,24(a5)
    80004d02:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d06:	4685                	li	a3,1
    80004d08:	fbf40613          	addi	a2,s0,-65
    80004d0c:	85ca                	mv	a1,s2
    80004d0e:	050a3503          	ld	a0,80(s4)
    80004d12:	ffffd097          	auipc	ra,0xffffd
    80004d16:	c64080e7          	jalr	-924(ra) # 80001976 <copyout>
    80004d1a:	01650663          	beq	a0,s6,80004d26 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d1e:	2985                	addiw	s3,s3,1
    80004d20:	0905                	addi	s2,s2,1
    80004d22:	fd3a91e3          	bne	s5,s3,80004ce4 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d26:	21c48513          	addi	a0,s1,540
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	7f8080e7          	jalr	2040(ra) # 80002522 <wakeup>
  release(&pi->lock);
    80004d32:	8526                	mv	a0,s1
    80004d34:	ffffc097          	auipc	ra,0xffffc
    80004d38:	056080e7          	jalr	86(ra) # 80000d8a <release>
  return i;
}
    80004d3c:	854e                	mv	a0,s3
    80004d3e:	60a6                	ld	ra,72(sp)
    80004d40:	6406                	ld	s0,64(sp)
    80004d42:	74e2                	ld	s1,56(sp)
    80004d44:	7942                	ld	s2,48(sp)
    80004d46:	79a2                	ld	s3,40(sp)
    80004d48:	7a02                	ld	s4,32(sp)
    80004d4a:	6ae2                	ld	s5,24(sp)
    80004d4c:	6b42                	ld	s6,16(sp)
    80004d4e:	6161                	addi	sp,sp,80
    80004d50:	8082                	ret
      release(&pi->lock);
    80004d52:	8526                	mv	a0,s1
    80004d54:	ffffc097          	auipc	ra,0xffffc
    80004d58:	036080e7          	jalr	54(ra) # 80000d8a <release>
      return -1;
    80004d5c:	59fd                	li	s3,-1
    80004d5e:	bff9                	j	80004d3c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d60:	4981                	li	s3,0
    80004d62:	b7d1                	j	80004d26 <piperead+0xae>

0000000080004d64 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d64:	df010113          	addi	sp,sp,-528
    80004d68:	20113423          	sd	ra,520(sp)
    80004d6c:	20813023          	sd	s0,512(sp)
    80004d70:	ffa6                	sd	s1,504(sp)
    80004d72:	fbca                	sd	s2,496(sp)
    80004d74:	f7ce                	sd	s3,488(sp)
    80004d76:	f3d2                	sd	s4,480(sp)
    80004d78:	efd6                	sd	s5,472(sp)
    80004d7a:	ebda                	sd	s6,464(sp)
    80004d7c:	e7de                	sd	s7,456(sp)
    80004d7e:	e3e2                	sd	s8,448(sp)
    80004d80:	ff66                	sd	s9,440(sp)
    80004d82:	fb6a                	sd	s10,432(sp)
    80004d84:	f76e                	sd	s11,424(sp)
    80004d86:	0c00                	addi	s0,sp,528
    80004d88:	84aa                	mv	s1,a0
    80004d8a:	dea43c23          	sd	a0,-520(s0)
    80004d8e:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d92:	ffffd097          	auipc	ra,0xffffd
    80004d96:	dfa080e7          	jalr	-518(ra) # 80001b8c <myproc>
    80004d9a:	892a                	mv	s2,a0

  begin_op();
    80004d9c:	fffff097          	auipc	ra,0xfffff
    80004da0:	446080e7          	jalr	1094(ra) # 800041e2 <begin_op>

  if((ip = namei(path)) == 0){
    80004da4:	8526                	mv	a0,s1
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	230080e7          	jalr	560(ra) # 80003fd6 <namei>
    80004dae:	c92d                	beqz	a0,80004e20 <exec+0xbc>
    80004db0:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004db2:	fffff097          	auipc	ra,0xfffff
    80004db6:	a70080e7          	jalr	-1424(ra) # 80003822 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004dba:	04000713          	li	a4,64
    80004dbe:	4681                	li	a3,0
    80004dc0:	e4840613          	addi	a2,s0,-440
    80004dc4:	4581                	li	a1,0
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	d0e080e7          	jalr	-754(ra) # 80003ad6 <readi>
    80004dd0:	04000793          	li	a5,64
    80004dd4:	00f51a63          	bne	a0,a5,80004de8 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004dd8:	e4842703          	lw	a4,-440(s0)
    80004ddc:	464c47b7          	lui	a5,0x464c4
    80004de0:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004de4:	04f70463          	beq	a4,a5,80004e2c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004de8:	8526                	mv	a0,s1
    80004dea:	fffff097          	auipc	ra,0xfffff
    80004dee:	c9a080e7          	jalr	-870(ra) # 80003a84 <iunlockput>
    end_op();
    80004df2:	fffff097          	auipc	ra,0xfffff
    80004df6:	470080e7          	jalr	1136(ra) # 80004262 <end_op>
  }
  return -1;
    80004dfa:	557d                	li	a0,-1
}
    80004dfc:	20813083          	ld	ra,520(sp)
    80004e00:	20013403          	ld	s0,512(sp)
    80004e04:	74fe                	ld	s1,504(sp)
    80004e06:	795e                	ld	s2,496(sp)
    80004e08:	79be                	ld	s3,488(sp)
    80004e0a:	7a1e                	ld	s4,480(sp)
    80004e0c:	6afe                	ld	s5,472(sp)
    80004e0e:	6b5e                	ld	s6,464(sp)
    80004e10:	6bbe                	ld	s7,456(sp)
    80004e12:	6c1e                	ld	s8,448(sp)
    80004e14:	7cfa                	ld	s9,440(sp)
    80004e16:	7d5a                	ld	s10,432(sp)
    80004e18:	7dba                	ld	s11,424(sp)
    80004e1a:	21010113          	addi	sp,sp,528
    80004e1e:	8082                	ret
    end_op();
    80004e20:	fffff097          	auipc	ra,0xfffff
    80004e24:	442080e7          	jalr	1090(ra) # 80004262 <end_op>
    return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	bfc9                	j	80004dfc <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004e2c:	854a                	mv	a0,s2
    80004e2e:	ffffd097          	auipc	ra,0xffffd
    80004e32:	e22080e7          	jalr	-478(ra) # 80001c50 <proc_pagetable>
    80004e36:	8baa                	mv	s7,a0
    80004e38:	d945                	beqz	a0,80004de8 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e3a:	e6842983          	lw	s3,-408(s0)
    80004e3e:	e8045783          	lhu	a5,-384(s0)
    80004e42:	c7ad                	beqz	a5,80004eac <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e44:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004e46:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004e48:	6c85                	lui	s9,0x1
    80004e4a:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004e4e:	def43823          	sd	a5,-528(s0)
    80004e52:	a42d                	j	8000507c <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004e54:	00004517          	auipc	a0,0x4
    80004e58:	86450513          	addi	a0,a0,-1948 # 800086b8 <syscalls+0x290>
    80004e5c:	ffffb097          	auipc	ra,0xffffb
    80004e60:	6ec080e7          	jalr	1772(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e64:	8756                	mv	a4,s5
    80004e66:	012d86bb          	addw	a3,s11,s2
    80004e6a:	4581                	li	a1,0
    80004e6c:	8526                	mv	a0,s1
    80004e6e:	fffff097          	auipc	ra,0xfffff
    80004e72:	c68080e7          	jalr	-920(ra) # 80003ad6 <readi>
    80004e76:	2501                	sext.w	a0,a0
    80004e78:	1aaa9963          	bne	s5,a0,8000502a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e7c:	6785                	lui	a5,0x1
    80004e7e:	0127893b          	addw	s2,a5,s2
    80004e82:	77fd                	lui	a5,0xfffff
    80004e84:	01478a3b          	addw	s4,a5,s4
    80004e88:	1f897163          	bgeu	s2,s8,8000506a <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e8c:	02091593          	slli	a1,s2,0x20
    80004e90:	9181                	srli	a1,a1,0x20
    80004e92:	95ea                	add	a1,a1,s10
    80004e94:	855e                	mv	a0,s7
    80004e96:	ffffc097          	auipc	ra,0xffffc
    80004e9a:	2ce080e7          	jalr	718(ra) # 80001164 <walkaddr>
    80004e9e:	862a                	mv	a2,a0
    if(pa == 0)
    80004ea0:	d955                	beqz	a0,80004e54 <exec+0xf0>
      n = PGSIZE;
    80004ea2:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004ea4:	fd9a70e3          	bgeu	s4,s9,80004e64 <exec+0x100>
      n = sz - i;
    80004ea8:	8ad2                	mv	s5,s4
    80004eaa:	bf6d                	j	80004e64 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004eac:	4901                	li	s2,0
  iunlockput(ip);
    80004eae:	8526                	mv	a0,s1
    80004eb0:	fffff097          	auipc	ra,0xfffff
    80004eb4:	bd4080e7          	jalr	-1068(ra) # 80003a84 <iunlockput>
  end_op();
    80004eb8:	fffff097          	auipc	ra,0xfffff
    80004ebc:	3aa080e7          	jalr	938(ra) # 80004262 <end_op>
  p = myproc();
    80004ec0:	ffffd097          	auipc	ra,0xffffd
    80004ec4:	ccc080e7          	jalr	-820(ra) # 80001b8c <myproc>
    80004ec8:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004eca:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004ece:	6785                	lui	a5,0x1
    80004ed0:	17fd                	addi	a5,a5,-1
    80004ed2:	993e                	add	s2,s2,a5
    80004ed4:	757d                	lui	a0,0xfffff
    80004ed6:	00a977b3          	and	a5,s2,a0
    80004eda:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ede:	6609                	lui	a2,0x2
    80004ee0:	963e                	add	a2,a2,a5
    80004ee2:	85be                	mv	a1,a5
    80004ee4:	855e                	mv	a0,s7
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	662080e7          	jalr	1634(ra) # 80001548 <uvmalloc>
    80004eee:	8b2a                	mv	s6,a0
  ip = 0;
    80004ef0:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004ef2:	12050c63          	beqz	a0,8000502a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004ef6:	75f9                	lui	a1,0xffffe
    80004ef8:	95aa                	add	a1,a1,a0
    80004efa:	855e                	mv	a0,s7
    80004efc:	ffffd097          	auipc	ra,0xffffd
    80004f00:	868080e7          	jalr	-1944(ra) # 80001764 <uvmclear>
  stackbase = sp - PGSIZE;
    80004f04:	7c7d                	lui	s8,0xfffff
    80004f06:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f08:	e0043783          	ld	a5,-512(s0)
    80004f0c:	6388                	ld	a0,0(a5)
    80004f0e:	c535                	beqz	a0,80004f7a <exec+0x216>
    80004f10:	e8840993          	addi	s3,s0,-376
    80004f14:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004f18:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	040080e7          	jalr	64(ra) # 80000f5a <strlen>
    80004f22:	2505                	addiw	a0,a0,1
    80004f24:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004f28:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004f2c:	13896363          	bltu	s2,s8,80005052 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004f30:	e0043d83          	ld	s11,-512(s0)
    80004f34:	000dba03          	ld	s4,0(s11)
    80004f38:	8552                	mv	a0,s4
    80004f3a:	ffffc097          	auipc	ra,0xffffc
    80004f3e:	020080e7          	jalr	32(ra) # 80000f5a <strlen>
    80004f42:	0015069b          	addiw	a3,a0,1
    80004f46:	8652                	mv	a2,s4
    80004f48:	85ca                	mv	a1,s2
    80004f4a:	855e                	mv	a0,s7
    80004f4c:	ffffd097          	auipc	ra,0xffffd
    80004f50:	a2a080e7          	jalr	-1494(ra) # 80001976 <copyout>
    80004f54:	10054363          	bltz	a0,8000505a <exec+0x2f6>
    ustack[argc] = sp;
    80004f58:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004f5c:	0485                	addi	s1,s1,1
    80004f5e:	008d8793          	addi	a5,s11,8
    80004f62:	e0f43023          	sd	a5,-512(s0)
    80004f66:	008db503          	ld	a0,8(s11)
    80004f6a:	c911                	beqz	a0,80004f7e <exec+0x21a>
    if(argc >= MAXARG)
    80004f6c:	09a1                	addi	s3,s3,8
    80004f6e:	fb3c96e3          	bne	s9,s3,80004f1a <exec+0x1b6>
  sz = sz1;
    80004f72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f76:	4481                	li	s1,0
    80004f78:	a84d                	j	8000502a <exec+0x2c6>
  sp = sz;
    80004f7a:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f7c:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f7e:	00349793          	slli	a5,s1,0x3
    80004f82:	f9040713          	addi	a4,s0,-112
    80004f86:	97ba                	add	a5,a5,a4
    80004f88:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f8c:	00148693          	addi	a3,s1,1
    80004f90:	068e                	slli	a3,a3,0x3
    80004f92:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f96:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f9a:	01897663          	bgeu	s2,s8,80004fa6 <exec+0x242>
  sz = sz1;
    80004f9e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fa2:	4481                	li	s1,0
    80004fa4:	a059                	j	8000502a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004fa6:	e8840613          	addi	a2,s0,-376
    80004faa:	85ca                	mv	a1,s2
    80004fac:	855e                	mv	a0,s7
    80004fae:	ffffd097          	auipc	ra,0xffffd
    80004fb2:	9c8080e7          	jalr	-1592(ra) # 80001976 <copyout>
    80004fb6:	0a054663          	bltz	a0,80005062 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004fba:	058ab783          	ld	a5,88(s5)
    80004fbe:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004fc2:	df843783          	ld	a5,-520(s0)
    80004fc6:	0007c703          	lbu	a4,0(a5)
    80004fca:	cf11                	beqz	a4,80004fe6 <exec+0x282>
    80004fcc:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004fce:	02f00693          	li	a3,47
    80004fd2:	a029                	j	80004fdc <exec+0x278>
  for(last=s=path; *s; s++)
    80004fd4:	0785                	addi	a5,a5,1
    80004fd6:	fff7c703          	lbu	a4,-1(a5)
    80004fda:	c711                	beqz	a4,80004fe6 <exec+0x282>
    if(*s == '/')
    80004fdc:	fed71ce3          	bne	a4,a3,80004fd4 <exec+0x270>
      last = s+1;
    80004fe0:	def43c23          	sd	a5,-520(s0)
    80004fe4:	bfc5                	j	80004fd4 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004fe6:	4641                	li	a2,16
    80004fe8:	df843583          	ld	a1,-520(s0)
    80004fec:	158a8513          	addi	a0,s5,344
    80004ff0:	ffffc097          	auipc	ra,0xffffc
    80004ff4:	f38080e7          	jalr	-200(ra) # 80000f28 <safestrcpy>
  oldpagetable = p->pagetable;
    80004ff8:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004ffc:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005000:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005004:	058ab783          	ld	a5,88(s5)
    80005008:	e6043703          	ld	a4,-416(s0)
    8000500c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000500e:	058ab783          	ld	a5,88(s5)
    80005012:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005016:	85ea                	mv	a1,s10
    80005018:	ffffd097          	auipc	ra,0xffffd
    8000501c:	cd4080e7          	jalr	-812(ra) # 80001cec <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005020:	0004851b          	sext.w	a0,s1
    80005024:	bbe1                	j	80004dfc <exec+0x98>
    80005026:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000502a:	e0843583          	ld	a1,-504(s0)
    8000502e:	855e                	mv	a0,s7
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	cbc080e7          	jalr	-836(ra) # 80001cec <proc_freepagetable>
  if(ip){
    80005038:	da0498e3          	bnez	s1,80004de8 <exec+0x84>
  return -1;
    8000503c:	557d                	li	a0,-1
    8000503e:	bb7d                	j	80004dfc <exec+0x98>
    80005040:	e1243423          	sd	s2,-504(s0)
    80005044:	b7dd                	j	8000502a <exec+0x2c6>
    80005046:	e1243423          	sd	s2,-504(s0)
    8000504a:	b7c5                	j	8000502a <exec+0x2c6>
    8000504c:	e1243423          	sd	s2,-504(s0)
    80005050:	bfe9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    80005052:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005056:	4481                	li	s1,0
    80005058:	bfc9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    8000505a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000505e:	4481                	li	s1,0
    80005060:	b7e9                	j	8000502a <exec+0x2c6>
  sz = sz1;
    80005062:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005066:	4481                	li	s1,0
    80005068:	b7c9                	j	8000502a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000506a:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000506e:	2b05                	addiw	s6,s6,1
    80005070:	0389899b          	addiw	s3,s3,56
    80005074:	e8045783          	lhu	a5,-384(s0)
    80005078:	e2fb5be3          	bge	s6,a5,80004eae <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000507c:	2981                	sext.w	s3,s3
    8000507e:	03800713          	li	a4,56
    80005082:	86ce                	mv	a3,s3
    80005084:	e1040613          	addi	a2,s0,-496
    80005088:	4581                	li	a1,0
    8000508a:	8526                	mv	a0,s1
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	a4a080e7          	jalr	-1462(ra) # 80003ad6 <readi>
    80005094:	03800793          	li	a5,56
    80005098:	f8f517e3          	bne	a0,a5,80005026 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    8000509c:	e1042783          	lw	a5,-496(s0)
    800050a0:	4705                	li	a4,1
    800050a2:	fce796e3          	bne	a5,a4,8000506e <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800050a6:	e3843603          	ld	a2,-456(s0)
    800050aa:	e3043783          	ld	a5,-464(s0)
    800050ae:	f8f669e3          	bltu	a2,a5,80005040 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800050b2:	e2043783          	ld	a5,-480(s0)
    800050b6:	963e                	add	a2,a2,a5
    800050b8:	f8f667e3          	bltu	a2,a5,80005046 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800050bc:	85ca                	mv	a1,s2
    800050be:	855e                	mv	a0,s7
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	488080e7          	jalr	1160(ra) # 80001548 <uvmalloc>
    800050c8:	e0a43423          	sd	a0,-504(s0)
    800050cc:	d141                	beqz	a0,8000504c <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    800050ce:	e2043d03          	ld	s10,-480(s0)
    800050d2:	df043783          	ld	a5,-528(s0)
    800050d6:	00fd77b3          	and	a5,s10,a5
    800050da:	fba1                	bnez	a5,8000502a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800050dc:	e1842d83          	lw	s11,-488(s0)
    800050e0:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800050e4:	f80c03e3          	beqz	s8,8000506a <exec+0x306>
    800050e8:	8a62                	mv	s4,s8
    800050ea:	4901                	li	s2,0
    800050ec:	b345                	j	80004e8c <exec+0x128>

00000000800050ee <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800050ee:	7179                	addi	sp,sp,-48
    800050f0:	f406                	sd	ra,40(sp)
    800050f2:	f022                	sd	s0,32(sp)
    800050f4:	ec26                	sd	s1,24(sp)
    800050f6:	e84a                	sd	s2,16(sp)
    800050f8:	1800                	addi	s0,sp,48
    800050fa:	892e                	mv	s2,a1
    800050fc:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800050fe:	fdc40593          	addi	a1,s0,-36
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	bae080e7          	jalr	-1106(ra) # 80002cb0 <argint>
    8000510a:	04054063          	bltz	a0,8000514a <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000510e:	fdc42703          	lw	a4,-36(s0)
    80005112:	47bd                	li	a5,15
    80005114:	02e7ed63          	bltu	a5,a4,8000514e <argfd+0x60>
    80005118:	ffffd097          	auipc	ra,0xffffd
    8000511c:	a74080e7          	jalr	-1420(ra) # 80001b8c <myproc>
    80005120:	fdc42703          	lw	a4,-36(s0)
    80005124:	01a70793          	addi	a5,a4,26
    80005128:	078e                	slli	a5,a5,0x3
    8000512a:	953e                	add	a0,a0,a5
    8000512c:	611c                	ld	a5,0(a0)
    8000512e:	c395                	beqz	a5,80005152 <argfd+0x64>
    return -1;
  if(pfd)
    80005130:	00090463          	beqz	s2,80005138 <argfd+0x4a>
    *pfd = fd;
    80005134:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005138:	4501                	li	a0,0
  if(pf)
    8000513a:	c091                	beqz	s1,8000513e <argfd+0x50>
    *pf = f;
    8000513c:	e09c                	sd	a5,0(s1)
}
    8000513e:	70a2                	ld	ra,40(sp)
    80005140:	7402                	ld	s0,32(sp)
    80005142:	64e2                	ld	s1,24(sp)
    80005144:	6942                	ld	s2,16(sp)
    80005146:	6145                	addi	sp,sp,48
    80005148:	8082                	ret
    return -1;
    8000514a:	557d                	li	a0,-1
    8000514c:	bfcd                	j	8000513e <argfd+0x50>
    return -1;
    8000514e:	557d                	li	a0,-1
    80005150:	b7fd                	j	8000513e <argfd+0x50>
    80005152:	557d                	li	a0,-1
    80005154:	b7ed                	j	8000513e <argfd+0x50>

0000000080005156 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005156:	1101                	addi	sp,sp,-32
    80005158:	ec06                	sd	ra,24(sp)
    8000515a:	e822                	sd	s0,16(sp)
    8000515c:	e426                	sd	s1,8(sp)
    8000515e:	1000                	addi	s0,sp,32
    80005160:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005162:	ffffd097          	auipc	ra,0xffffd
    80005166:	a2a080e7          	jalr	-1494(ra) # 80001b8c <myproc>
    8000516a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000516c:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005170:	4501                	li	a0,0
    80005172:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005174:	6398                	ld	a4,0(a5)
    80005176:	cb19                	beqz	a4,8000518c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005178:	2505                	addiw	a0,a0,1
    8000517a:	07a1                	addi	a5,a5,8
    8000517c:	fed51ce3          	bne	a0,a3,80005174 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005180:	557d                	li	a0,-1
}
    80005182:	60e2                	ld	ra,24(sp)
    80005184:	6442                	ld	s0,16(sp)
    80005186:	64a2                	ld	s1,8(sp)
    80005188:	6105                	addi	sp,sp,32
    8000518a:	8082                	ret
      p->ofile[fd] = f;
    8000518c:	01a50793          	addi	a5,a0,26
    80005190:	078e                	slli	a5,a5,0x3
    80005192:	963e                	add	a2,a2,a5
    80005194:	e204                	sd	s1,0(a2)
      return fd;
    80005196:	b7f5                	j	80005182 <fdalloc+0x2c>

0000000080005198 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005198:	715d                	addi	sp,sp,-80
    8000519a:	e486                	sd	ra,72(sp)
    8000519c:	e0a2                	sd	s0,64(sp)
    8000519e:	fc26                	sd	s1,56(sp)
    800051a0:	f84a                	sd	s2,48(sp)
    800051a2:	f44e                	sd	s3,40(sp)
    800051a4:	f052                	sd	s4,32(sp)
    800051a6:	ec56                	sd	s5,24(sp)
    800051a8:	0880                	addi	s0,sp,80
    800051aa:	89ae                	mv	s3,a1
    800051ac:	8ab2                	mv	s5,a2
    800051ae:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800051b0:	fb040593          	addi	a1,s0,-80
    800051b4:	fffff097          	auipc	ra,0xfffff
    800051b8:	e40080e7          	jalr	-448(ra) # 80003ff4 <nameiparent>
    800051bc:	892a                	mv	s2,a0
    800051be:	12050f63          	beqz	a0,800052fc <create+0x164>
    return 0;

  ilock(dp);
    800051c2:	ffffe097          	auipc	ra,0xffffe
    800051c6:	660080e7          	jalr	1632(ra) # 80003822 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800051ca:	4601                	li	a2,0
    800051cc:	fb040593          	addi	a1,s0,-80
    800051d0:	854a                	mv	a0,s2
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	b32080e7          	jalr	-1230(ra) # 80003d04 <dirlookup>
    800051da:	84aa                	mv	s1,a0
    800051dc:	c921                	beqz	a0,8000522c <create+0x94>
    iunlockput(dp);
    800051de:	854a                	mv	a0,s2
    800051e0:	fffff097          	auipc	ra,0xfffff
    800051e4:	8a4080e7          	jalr	-1884(ra) # 80003a84 <iunlockput>
    ilock(ip);
    800051e8:	8526                	mv	a0,s1
    800051ea:	ffffe097          	auipc	ra,0xffffe
    800051ee:	638080e7          	jalr	1592(ra) # 80003822 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800051f2:	2981                	sext.w	s3,s3
    800051f4:	4789                	li	a5,2
    800051f6:	02f99463          	bne	s3,a5,8000521e <create+0x86>
    800051fa:	0444d783          	lhu	a5,68(s1)
    800051fe:	37f9                	addiw	a5,a5,-2
    80005200:	17c2                	slli	a5,a5,0x30
    80005202:	93c1                	srli	a5,a5,0x30
    80005204:	4705                	li	a4,1
    80005206:	00f76c63          	bltu	a4,a5,8000521e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000520a:	8526                	mv	a0,s1
    8000520c:	60a6                	ld	ra,72(sp)
    8000520e:	6406                	ld	s0,64(sp)
    80005210:	74e2                	ld	s1,56(sp)
    80005212:	7942                	ld	s2,48(sp)
    80005214:	79a2                	ld	s3,40(sp)
    80005216:	7a02                	ld	s4,32(sp)
    80005218:	6ae2                	ld	s5,24(sp)
    8000521a:	6161                	addi	sp,sp,80
    8000521c:	8082                	ret
    iunlockput(ip);
    8000521e:	8526                	mv	a0,s1
    80005220:	fffff097          	auipc	ra,0xfffff
    80005224:	864080e7          	jalr	-1948(ra) # 80003a84 <iunlockput>
    return 0;
    80005228:	4481                	li	s1,0
    8000522a:	b7c5                	j	8000520a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000522c:	85ce                	mv	a1,s3
    8000522e:	00092503          	lw	a0,0(s2)
    80005232:	ffffe097          	auipc	ra,0xffffe
    80005236:	458080e7          	jalr	1112(ra) # 8000368a <ialloc>
    8000523a:	84aa                	mv	s1,a0
    8000523c:	c529                	beqz	a0,80005286 <create+0xee>
  ilock(ip);
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	5e4080e7          	jalr	1508(ra) # 80003822 <ilock>
  ip->major = major;
    80005246:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    8000524a:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000524e:	4785                	li	a5,1
    80005250:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005254:	8526                	mv	a0,s1
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	502080e7          	jalr	1282(ra) # 80003758 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000525e:	2981                	sext.w	s3,s3
    80005260:	4785                	li	a5,1
    80005262:	02f98a63          	beq	s3,a5,80005296 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005266:	40d0                	lw	a2,4(s1)
    80005268:	fb040593          	addi	a1,s0,-80
    8000526c:	854a                	mv	a0,s2
    8000526e:	fffff097          	auipc	ra,0xfffff
    80005272:	ca6080e7          	jalr	-858(ra) # 80003f14 <dirlink>
    80005276:	06054b63          	bltz	a0,800052ec <create+0x154>
  iunlockput(dp);
    8000527a:	854a                	mv	a0,s2
    8000527c:	fffff097          	auipc	ra,0xfffff
    80005280:	808080e7          	jalr	-2040(ra) # 80003a84 <iunlockput>
  return ip;
    80005284:	b759                	j	8000520a <create+0x72>
    panic("create: ialloc");
    80005286:	00003517          	auipc	a0,0x3
    8000528a:	45250513          	addi	a0,a0,1106 # 800086d8 <syscalls+0x2b0>
    8000528e:	ffffb097          	auipc	ra,0xffffb
    80005292:	2ba080e7          	jalr	698(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005296:	04a95783          	lhu	a5,74(s2)
    8000529a:	2785                	addiw	a5,a5,1
    8000529c:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800052a0:	854a                	mv	a0,s2
    800052a2:	ffffe097          	auipc	ra,0xffffe
    800052a6:	4b6080e7          	jalr	1206(ra) # 80003758 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800052aa:	40d0                	lw	a2,4(s1)
    800052ac:	00003597          	auipc	a1,0x3
    800052b0:	43c58593          	addi	a1,a1,1084 # 800086e8 <syscalls+0x2c0>
    800052b4:	8526                	mv	a0,s1
    800052b6:	fffff097          	auipc	ra,0xfffff
    800052ba:	c5e080e7          	jalr	-930(ra) # 80003f14 <dirlink>
    800052be:	00054f63          	bltz	a0,800052dc <create+0x144>
    800052c2:	00492603          	lw	a2,4(s2)
    800052c6:	00003597          	auipc	a1,0x3
    800052ca:	42a58593          	addi	a1,a1,1066 # 800086f0 <syscalls+0x2c8>
    800052ce:	8526                	mv	a0,s1
    800052d0:	fffff097          	auipc	ra,0xfffff
    800052d4:	c44080e7          	jalr	-956(ra) # 80003f14 <dirlink>
    800052d8:	f80557e3          	bgez	a0,80005266 <create+0xce>
      panic("create dots");
    800052dc:	00003517          	auipc	a0,0x3
    800052e0:	41c50513          	addi	a0,a0,1052 # 800086f8 <syscalls+0x2d0>
    800052e4:	ffffb097          	auipc	ra,0xffffb
    800052e8:	264080e7          	jalr	612(ra) # 80000548 <panic>
    panic("create: dirlink");
    800052ec:	00003517          	auipc	a0,0x3
    800052f0:	41c50513          	addi	a0,a0,1052 # 80008708 <syscalls+0x2e0>
    800052f4:	ffffb097          	auipc	ra,0xffffb
    800052f8:	254080e7          	jalr	596(ra) # 80000548 <panic>
    return 0;
    800052fc:	84aa                	mv	s1,a0
    800052fe:	b731                	j	8000520a <create+0x72>

0000000080005300 <sys_dup>:
{
    80005300:	7179                	addi	sp,sp,-48
    80005302:	f406                	sd	ra,40(sp)
    80005304:	f022                	sd	s0,32(sp)
    80005306:	ec26                	sd	s1,24(sp)
    80005308:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000530a:	fd840613          	addi	a2,s0,-40
    8000530e:	4581                	li	a1,0
    80005310:	4501                	li	a0,0
    80005312:	00000097          	auipc	ra,0x0
    80005316:	ddc080e7          	jalr	-548(ra) # 800050ee <argfd>
    return -1;
    8000531a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000531c:	02054363          	bltz	a0,80005342 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005320:	fd843503          	ld	a0,-40(s0)
    80005324:	00000097          	auipc	ra,0x0
    80005328:	e32080e7          	jalr	-462(ra) # 80005156 <fdalloc>
    8000532c:	84aa                	mv	s1,a0
    return -1;
    8000532e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005330:	00054963          	bltz	a0,80005342 <sys_dup+0x42>
  filedup(f);
    80005334:	fd843503          	ld	a0,-40(s0)
    80005338:	fffff097          	auipc	ra,0xfffff
    8000533c:	32a080e7          	jalr	810(ra) # 80004662 <filedup>
  return fd;
    80005340:	87a6                	mv	a5,s1
}
    80005342:	853e                	mv	a0,a5
    80005344:	70a2                	ld	ra,40(sp)
    80005346:	7402                	ld	s0,32(sp)
    80005348:	64e2                	ld	s1,24(sp)
    8000534a:	6145                	addi	sp,sp,48
    8000534c:	8082                	ret

000000008000534e <sys_read>:
{
    8000534e:	7179                	addi	sp,sp,-48
    80005350:	f406                	sd	ra,40(sp)
    80005352:	f022                	sd	s0,32(sp)
    80005354:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005356:	fe840613          	addi	a2,s0,-24
    8000535a:	4581                	li	a1,0
    8000535c:	4501                	li	a0,0
    8000535e:	00000097          	auipc	ra,0x0
    80005362:	d90080e7          	jalr	-624(ra) # 800050ee <argfd>
    return -1;
    80005366:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005368:	04054163          	bltz	a0,800053aa <sys_read+0x5c>
    8000536c:	fe440593          	addi	a1,s0,-28
    80005370:	4509                	li	a0,2
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	93e080e7          	jalr	-1730(ra) # 80002cb0 <argint>
    return -1;
    8000537a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537c:	02054763          	bltz	a0,800053aa <sys_read+0x5c>
    80005380:	fd840593          	addi	a1,s0,-40
    80005384:	4505                	li	a0,1
    80005386:	ffffe097          	auipc	ra,0xffffe
    8000538a:	94c080e7          	jalr	-1716(ra) # 80002cd2 <argaddr>
    return -1;
    8000538e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005390:	00054d63          	bltz	a0,800053aa <sys_read+0x5c>
  return fileread(f, p, n);
    80005394:	fe442603          	lw	a2,-28(s0)
    80005398:	fd843583          	ld	a1,-40(s0)
    8000539c:	fe843503          	ld	a0,-24(s0)
    800053a0:	fffff097          	auipc	ra,0xfffff
    800053a4:	44e080e7          	jalr	1102(ra) # 800047ee <fileread>
    800053a8:	87aa                	mv	a5,a0
}
    800053aa:	853e                	mv	a0,a5
    800053ac:	70a2                	ld	ra,40(sp)
    800053ae:	7402                	ld	s0,32(sp)
    800053b0:	6145                	addi	sp,sp,48
    800053b2:	8082                	ret

00000000800053b4 <sys_write>:
{
    800053b4:	7179                	addi	sp,sp,-48
    800053b6:	f406                	sd	ra,40(sp)
    800053b8:	f022                	sd	s0,32(sp)
    800053ba:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053bc:	fe840613          	addi	a2,s0,-24
    800053c0:	4581                	li	a1,0
    800053c2:	4501                	li	a0,0
    800053c4:	00000097          	auipc	ra,0x0
    800053c8:	d2a080e7          	jalr	-726(ra) # 800050ee <argfd>
    return -1;
    800053cc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053ce:	04054163          	bltz	a0,80005410 <sys_write+0x5c>
    800053d2:	fe440593          	addi	a1,s0,-28
    800053d6:	4509                	li	a0,2
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	8d8080e7          	jalr	-1832(ra) # 80002cb0 <argint>
    return -1;
    800053e0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053e2:	02054763          	bltz	a0,80005410 <sys_write+0x5c>
    800053e6:	fd840593          	addi	a1,s0,-40
    800053ea:	4505                	li	a0,1
    800053ec:	ffffe097          	auipc	ra,0xffffe
    800053f0:	8e6080e7          	jalr	-1818(ra) # 80002cd2 <argaddr>
    return -1;
    800053f4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800053f6:	00054d63          	bltz	a0,80005410 <sys_write+0x5c>
  return filewrite(f, p, n);
    800053fa:	fe442603          	lw	a2,-28(s0)
    800053fe:	fd843583          	ld	a1,-40(s0)
    80005402:	fe843503          	ld	a0,-24(s0)
    80005406:	fffff097          	auipc	ra,0xfffff
    8000540a:	4aa080e7          	jalr	1194(ra) # 800048b0 <filewrite>
    8000540e:	87aa                	mv	a5,a0
}
    80005410:	853e                	mv	a0,a5
    80005412:	70a2                	ld	ra,40(sp)
    80005414:	7402                	ld	s0,32(sp)
    80005416:	6145                	addi	sp,sp,48
    80005418:	8082                	ret

000000008000541a <sys_close>:
{
    8000541a:	1101                	addi	sp,sp,-32
    8000541c:	ec06                	sd	ra,24(sp)
    8000541e:	e822                	sd	s0,16(sp)
    80005420:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005422:	fe040613          	addi	a2,s0,-32
    80005426:	fec40593          	addi	a1,s0,-20
    8000542a:	4501                	li	a0,0
    8000542c:	00000097          	auipc	ra,0x0
    80005430:	cc2080e7          	jalr	-830(ra) # 800050ee <argfd>
    return -1;
    80005434:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005436:	02054463          	bltz	a0,8000545e <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000543a:	ffffc097          	auipc	ra,0xffffc
    8000543e:	752080e7          	jalr	1874(ra) # 80001b8c <myproc>
    80005442:	fec42783          	lw	a5,-20(s0)
    80005446:	07e9                	addi	a5,a5,26
    80005448:	078e                	slli	a5,a5,0x3
    8000544a:	97aa                	add	a5,a5,a0
    8000544c:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005450:	fe043503          	ld	a0,-32(s0)
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	260080e7          	jalr	608(ra) # 800046b4 <fileclose>
  return 0;
    8000545c:	4781                	li	a5,0
}
    8000545e:	853e                	mv	a0,a5
    80005460:	60e2                	ld	ra,24(sp)
    80005462:	6442                	ld	s0,16(sp)
    80005464:	6105                	addi	sp,sp,32
    80005466:	8082                	ret

0000000080005468 <sys_fstat>:
{
    80005468:	1101                	addi	sp,sp,-32
    8000546a:	ec06                	sd	ra,24(sp)
    8000546c:	e822                	sd	s0,16(sp)
    8000546e:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005470:	fe840613          	addi	a2,s0,-24
    80005474:	4581                	li	a1,0
    80005476:	4501                	li	a0,0
    80005478:	00000097          	auipc	ra,0x0
    8000547c:	c76080e7          	jalr	-906(ra) # 800050ee <argfd>
    return -1;
    80005480:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005482:	02054563          	bltz	a0,800054ac <sys_fstat+0x44>
    80005486:	fe040593          	addi	a1,s0,-32
    8000548a:	4505                	li	a0,1
    8000548c:	ffffe097          	auipc	ra,0xffffe
    80005490:	846080e7          	jalr	-1978(ra) # 80002cd2 <argaddr>
    return -1;
    80005494:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005496:	00054b63          	bltz	a0,800054ac <sys_fstat+0x44>
  return filestat(f, st);
    8000549a:	fe043583          	ld	a1,-32(s0)
    8000549e:	fe843503          	ld	a0,-24(s0)
    800054a2:	fffff097          	auipc	ra,0xfffff
    800054a6:	2da080e7          	jalr	730(ra) # 8000477c <filestat>
    800054aa:	87aa                	mv	a5,a0
}
    800054ac:	853e                	mv	a0,a5
    800054ae:	60e2                	ld	ra,24(sp)
    800054b0:	6442                	ld	s0,16(sp)
    800054b2:	6105                	addi	sp,sp,32
    800054b4:	8082                	ret

00000000800054b6 <sys_link>:
{
    800054b6:	7169                	addi	sp,sp,-304
    800054b8:	f606                	sd	ra,296(sp)
    800054ba:	f222                	sd	s0,288(sp)
    800054bc:	ee26                	sd	s1,280(sp)
    800054be:	ea4a                	sd	s2,272(sp)
    800054c0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054c2:	08000613          	li	a2,128
    800054c6:	ed040593          	addi	a1,s0,-304
    800054ca:	4501                	li	a0,0
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	828080e7          	jalr	-2008(ra) # 80002cf4 <argstr>
    return -1;
    800054d4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054d6:	10054e63          	bltz	a0,800055f2 <sys_link+0x13c>
    800054da:	08000613          	li	a2,128
    800054de:	f5040593          	addi	a1,s0,-176
    800054e2:	4505                	li	a0,1
    800054e4:	ffffe097          	auipc	ra,0xffffe
    800054e8:	810080e7          	jalr	-2032(ra) # 80002cf4 <argstr>
    return -1;
    800054ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800054ee:	10054263          	bltz	a0,800055f2 <sys_link+0x13c>
  begin_op();
    800054f2:	fffff097          	auipc	ra,0xfffff
    800054f6:	cf0080e7          	jalr	-784(ra) # 800041e2 <begin_op>
  if((ip = namei(old)) == 0){
    800054fa:	ed040513          	addi	a0,s0,-304
    800054fe:	fffff097          	auipc	ra,0xfffff
    80005502:	ad8080e7          	jalr	-1320(ra) # 80003fd6 <namei>
    80005506:	84aa                	mv	s1,a0
    80005508:	c551                	beqz	a0,80005594 <sys_link+0xde>
  ilock(ip);
    8000550a:	ffffe097          	auipc	ra,0xffffe
    8000550e:	318080e7          	jalr	792(ra) # 80003822 <ilock>
  if(ip->type == T_DIR){
    80005512:	04449703          	lh	a4,68(s1)
    80005516:	4785                	li	a5,1
    80005518:	08f70463          	beq	a4,a5,800055a0 <sys_link+0xea>
  ip->nlink++;
    8000551c:	04a4d783          	lhu	a5,74(s1)
    80005520:	2785                	addiw	a5,a5,1
    80005522:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005526:	8526                	mv	a0,s1
    80005528:	ffffe097          	auipc	ra,0xffffe
    8000552c:	230080e7          	jalr	560(ra) # 80003758 <iupdate>
  iunlock(ip);
    80005530:	8526                	mv	a0,s1
    80005532:	ffffe097          	auipc	ra,0xffffe
    80005536:	3b2080e7          	jalr	946(ra) # 800038e4 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000553a:	fd040593          	addi	a1,s0,-48
    8000553e:	f5040513          	addi	a0,s0,-176
    80005542:	fffff097          	auipc	ra,0xfffff
    80005546:	ab2080e7          	jalr	-1358(ra) # 80003ff4 <nameiparent>
    8000554a:	892a                	mv	s2,a0
    8000554c:	c935                	beqz	a0,800055c0 <sys_link+0x10a>
  ilock(dp);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	2d4080e7          	jalr	724(ra) # 80003822 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005556:	00092703          	lw	a4,0(s2)
    8000555a:	409c                	lw	a5,0(s1)
    8000555c:	04f71d63          	bne	a4,a5,800055b6 <sys_link+0x100>
    80005560:	40d0                	lw	a2,4(s1)
    80005562:	fd040593          	addi	a1,s0,-48
    80005566:	854a                	mv	a0,s2
    80005568:	fffff097          	auipc	ra,0xfffff
    8000556c:	9ac080e7          	jalr	-1620(ra) # 80003f14 <dirlink>
    80005570:	04054363          	bltz	a0,800055b6 <sys_link+0x100>
  iunlockput(dp);
    80005574:	854a                	mv	a0,s2
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	50e080e7          	jalr	1294(ra) # 80003a84 <iunlockput>
  iput(ip);
    8000557e:	8526                	mv	a0,s1
    80005580:	ffffe097          	auipc	ra,0xffffe
    80005584:	45c080e7          	jalr	1116(ra) # 800039dc <iput>
  end_op();
    80005588:	fffff097          	auipc	ra,0xfffff
    8000558c:	cda080e7          	jalr	-806(ra) # 80004262 <end_op>
  return 0;
    80005590:	4781                	li	a5,0
    80005592:	a085                	j	800055f2 <sys_link+0x13c>
    end_op();
    80005594:	fffff097          	auipc	ra,0xfffff
    80005598:	cce080e7          	jalr	-818(ra) # 80004262 <end_op>
    return -1;
    8000559c:	57fd                	li	a5,-1
    8000559e:	a891                	j	800055f2 <sys_link+0x13c>
    iunlockput(ip);
    800055a0:	8526                	mv	a0,s1
    800055a2:	ffffe097          	auipc	ra,0xffffe
    800055a6:	4e2080e7          	jalr	1250(ra) # 80003a84 <iunlockput>
    end_op();
    800055aa:	fffff097          	auipc	ra,0xfffff
    800055ae:	cb8080e7          	jalr	-840(ra) # 80004262 <end_op>
    return -1;
    800055b2:	57fd                	li	a5,-1
    800055b4:	a83d                	j	800055f2 <sys_link+0x13c>
    iunlockput(dp);
    800055b6:	854a                	mv	a0,s2
    800055b8:	ffffe097          	auipc	ra,0xffffe
    800055bc:	4cc080e7          	jalr	1228(ra) # 80003a84 <iunlockput>
  ilock(ip);
    800055c0:	8526                	mv	a0,s1
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	260080e7          	jalr	608(ra) # 80003822 <ilock>
  ip->nlink--;
    800055ca:	04a4d783          	lhu	a5,74(s1)
    800055ce:	37fd                	addiw	a5,a5,-1
    800055d0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800055d4:	8526                	mv	a0,s1
    800055d6:	ffffe097          	auipc	ra,0xffffe
    800055da:	182080e7          	jalr	386(ra) # 80003758 <iupdate>
  iunlockput(ip);
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	4a4080e7          	jalr	1188(ra) # 80003a84 <iunlockput>
  end_op();
    800055e8:	fffff097          	auipc	ra,0xfffff
    800055ec:	c7a080e7          	jalr	-902(ra) # 80004262 <end_op>
  return -1;
    800055f0:	57fd                	li	a5,-1
}
    800055f2:	853e                	mv	a0,a5
    800055f4:	70b2                	ld	ra,296(sp)
    800055f6:	7412                	ld	s0,288(sp)
    800055f8:	64f2                	ld	s1,280(sp)
    800055fa:	6952                	ld	s2,272(sp)
    800055fc:	6155                	addi	sp,sp,304
    800055fe:	8082                	ret

0000000080005600 <sys_unlink>:
{
    80005600:	7151                	addi	sp,sp,-240
    80005602:	f586                	sd	ra,232(sp)
    80005604:	f1a2                	sd	s0,224(sp)
    80005606:	eda6                	sd	s1,216(sp)
    80005608:	e9ca                	sd	s2,208(sp)
    8000560a:	e5ce                	sd	s3,200(sp)
    8000560c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000560e:	08000613          	li	a2,128
    80005612:	f3040593          	addi	a1,s0,-208
    80005616:	4501                	li	a0,0
    80005618:	ffffd097          	auipc	ra,0xffffd
    8000561c:	6dc080e7          	jalr	1756(ra) # 80002cf4 <argstr>
    80005620:	18054163          	bltz	a0,800057a2 <sys_unlink+0x1a2>
  begin_op();
    80005624:	fffff097          	auipc	ra,0xfffff
    80005628:	bbe080e7          	jalr	-1090(ra) # 800041e2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000562c:	fb040593          	addi	a1,s0,-80
    80005630:	f3040513          	addi	a0,s0,-208
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	9c0080e7          	jalr	-1600(ra) # 80003ff4 <nameiparent>
    8000563c:	84aa                	mv	s1,a0
    8000563e:	c979                	beqz	a0,80005714 <sys_unlink+0x114>
  ilock(dp);
    80005640:	ffffe097          	auipc	ra,0xffffe
    80005644:	1e2080e7          	jalr	482(ra) # 80003822 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005648:	00003597          	auipc	a1,0x3
    8000564c:	0a058593          	addi	a1,a1,160 # 800086e8 <syscalls+0x2c0>
    80005650:	fb040513          	addi	a0,s0,-80
    80005654:	ffffe097          	auipc	ra,0xffffe
    80005658:	696080e7          	jalr	1686(ra) # 80003cea <namecmp>
    8000565c:	14050a63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
    80005660:	00003597          	auipc	a1,0x3
    80005664:	09058593          	addi	a1,a1,144 # 800086f0 <syscalls+0x2c8>
    80005668:	fb040513          	addi	a0,s0,-80
    8000566c:	ffffe097          	auipc	ra,0xffffe
    80005670:	67e080e7          	jalr	1662(ra) # 80003cea <namecmp>
    80005674:	12050e63          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005678:	f2c40613          	addi	a2,s0,-212
    8000567c:	fb040593          	addi	a1,s0,-80
    80005680:	8526                	mv	a0,s1
    80005682:	ffffe097          	auipc	ra,0xffffe
    80005686:	682080e7          	jalr	1666(ra) # 80003d04 <dirlookup>
    8000568a:	892a                	mv	s2,a0
    8000568c:	12050263          	beqz	a0,800057b0 <sys_unlink+0x1b0>
  ilock(ip);
    80005690:	ffffe097          	auipc	ra,0xffffe
    80005694:	192080e7          	jalr	402(ra) # 80003822 <ilock>
  if(ip->nlink < 1)
    80005698:	04a91783          	lh	a5,74(s2)
    8000569c:	08f05263          	blez	a5,80005720 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800056a0:	04491703          	lh	a4,68(s2)
    800056a4:	4785                	li	a5,1
    800056a6:	08f70563          	beq	a4,a5,80005730 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800056aa:	4641                	li	a2,16
    800056ac:	4581                	li	a1,0
    800056ae:	fc040513          	addi	a0,s0,-64
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	720080e7          	jalr	1824(ra) # 80000dd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056ba:	4741                	li	a4,16
    800056bc:	f2c42683          	lw	a3,-212(s0)
    800056c0:	fc040613          	addi	a2,s0,-64
    800056c4:	4581                	li	a1,0
    800056c6:	8526                	mv	a0,s1
    800056c8:	ffffe097          	auipc	ra,0xffffe
    800056cc:	506080e7          	jalr	1286(ra) # 80003bce <writei>
    800056d0:	47c1                	li	a5,16
    800056d2:	0af51563          	bne	a0,a5,8000577c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800056d6:	04491703          	lh	a4,68(s2)
    800056da:	4785                	li	a5,1
    800056dc:	0af70863          	beq	a4,a5,8000578c <sys_unlink+0x18c>
  iunlockput(dp);
    800056e0:	8526                	mv	a0,s1
    800056e2:	ffffe097          	auipc	ra,0xffffe
    800056e6:	3a2080e7          	jalr	930(ra) # 80003a84 <iunlockput>
  ip->nlink--;
    800056ea:	04a95783          	lhu	a5,74(s2)
    800056ee:	37fd                	addiw	a5,a5,-1
    800056f0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	062080e7          	jalr	98(ra) # 80003758 <iupdate>
  iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	384080e7          	jalr	900(ra) # 80003a84 <iunlockput>
  end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	b5a080e7          	jalr	-1190(ra) # 80004262 <end_op>
  return 0;
    80005710:	4501                	li	a0,0
    80005712:	a84d                	j	800057c4 <sys_unlink+0x1c4>
    end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	b4e080e7          	jalr	-1202(ra) # 80004262 <end_op>
    return -1;
    8000571c:	557d                	li	a0,-1
    8000571e:	a05d                	j	800057c4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005720:	00003517          	auipc	a0,0x3
    80005724:	ff850513          	addi	a0,a0,-8 # 80008718 <syscalls+0x2f0>
    80005728:	ffffb097          	auipc	ra,0xffffb
    8000572c:	e20080e7          	jalr	-480(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005730:	04c92703          	lw	a4,76(s2)
    80005734:	02000793          	li	a5,32
    80005738:	f6e7f9e3          	bgeu	a5,a4,800056aa <sys_unlink+0xaa>
    8000573c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005740:	4741                	li	a4,16
    80005742:	86ce                	mv	a3,s3
    80005744:	f1840613          	addi	a2,s0,-232
    80005748:	4581                	li	a1,0
    8000574a:	854a                	mv	a0,s2
    8000574c:	ffffe097          	auipc	ra,0xffffe
    80005750:	38a080e7          	jalr	906(ra) # 80003ad6 <readi>
    80005754:	47c1                	li	a5,16
    80005756:	00f51b63          	bne	a0,a5,8000576c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000575a:	f1845783          	lhu	a5,-232(s0)
    8000575e:	e7a1                	bnez	a5,800057a6 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005760:	29c1                	addiw	s3,s3,16
    80005762:	04c92783          	lw	a5,76(s2)
    80005766:	fcf9ede3          	bltu	s3,a5,80005740 <sys_unlink+0x140>
    8000576a:	b781                	j	800056aa <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000576c:	00003517          	auipc	a0,0x3
    80005770:	fc450513          	addi	a0,a0,-60 # 80008730 <syscalls+0x308>
    80005774:	ffffb097          	auipc	ra,0xffffb
    80005778:	dd4080e7          	jalr	-556(ra) # 80000548 <panic>
    panic("unlink: writei");
    8000577c:	00003517          	auipc	a0,0x3
    80005780:	fcc50513          	addi	a0,a0,-52 # 80008748 <syscalls+0x320>
    80005784:	ffffb097          	auipc	ra,0xffffb
    80005788:	dc4080e7          	jalr	-572(ra) # 80000548 <panic>
    dp->nlink--;
    8000578c:	04a4d783          	lhu	a5,74(s1)
    80005790:	37fd                	addiw	a5,a5,-1
    80005792:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005796:	8526                	mv	a0,s1
    80005798:	ffffe097          	auipc	ra,0xffffe
    8000579c:	fc0080e7          	jalr	-64(ra) # 80003758 <iupdate>
    800057a0:	b781                	j	800056e0 <sys_unlink+0xe0>
    return -1;
    800057a2:	557d                	li	a0,-1
    800057a4:	a005                	j	800057c4 <sys_unlink+0x1c4>
    iunlockput(ip);
    800057a6:	854a                	mv	a0,s2
    800057a8:	ffffe097          	auipc	ra,0xffffe
    800057ac:	2dc080e7          	jalr	732(ra) # 80003a84 <iunlockput>
  iunlockput(dp);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	2d2080e7          	jalr	722(ra) # 80003a84 <iunlockput>
  end_op();
    800057ba:	fffff097          	auipc	ra,0xfffff
    800057be:	aa8080e7          	jalr	-1368(ra) # 80004262 <end_op>
  return -1;
    800057c2:	557d                	li	a0,-1
}
    800057c4:	70ae                	ld	ra,232(sp)
    800057c6:	740e                	ld	s0,224(sp)
    800057c8:	64ee                	ld	s1,216(sp)
    800057ca:	694e                	ld	s2,208(sp)
    800057cc:	69ae                	ld	s3,200(sp)
    800057ce:	616d                	addi	sp,sp,240
    800057d0:	8082                	ret

00000000800057d2 <sys_open>:

uint64
sys_open(void)
{
    800057d2:	7131                	addi	sp,sp,-192
    800057d4:	fd06                	sd	ra,184(sp)
    800057d6:	f922                	sd	s0,176(sp)
    800057d8:	f526                	sd	s1,168(sp)
    800057da:	f14a                	sd	s2,160(sp)
    800057dc:	ed4e                	sd	s3,152(sp)
    800057de:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	f5040593          	addi	a1,s0,-176
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	50a080e7          	jalr	1290(ra) # 80002cf4 <argstr>
    return -1;
    800057f2:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800057f4:	0c054163          	bltz	a0,800058b6 <sys_open+0xe4>
    800057f8:	f4c40593          	addi	a1,s0,-180
    800057fc:	4505                	li	a0,1
    800057fe:	ffffd097          	auipc	ra,0xffffd
    80005802:	4b2080e7          	jalr	1202(ra) # 80002cb0 <argint>
    80005806:	0a054863          	bltz	a0,800058b6 <sys_open+0xe4>

  begin_op();
    8000580a:	fffff097          	auipc	ra,0xfffff
    8000580e:	9d8080e7          	jalr	-1576(ra) # 800041e2 <begin_op>

  if(omode & O_CREATE){
    80005812:	f4c42783          	lw	a5,-180(s0)
    80005816:	2007f793          	andi	a5,a5,512
    8000581a:	cbdd                	beqz	a5,800058d0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000581c:	4681                	li	a3,0
    8000581e:	4601                	li	a2,0
    80005820:	4589                	li	a1,2
    80005822:	f5040513          	addi	a0,s0,-176
    80005826:	00000097          	auipc	ra,0x0
    8000582a:	972080e7          	jalr	-1678(ra) # 80005198 <create>
    8000582e:	892a                	mv	s2,a0
    if(ip == 0){
    80005830:	c959                	beqz	a0,800058c6 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005832:	04491703          	lh	a4,68(s2)
    80005836:	478d                	li	a5,3
    80005838:	00f71763          	bne	a4,a5,80005846 <sys_open+0x74>
    8000583c:	04695703          	lhu	a4,70(s2)
    80005840:	47a5                	li	a5,9
    80005842:	0ce7ec63          	bltu	a5,a4,8000591a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005846:	fffff097          	auipc	ra,0xfffff
    8000584a:	db2080e7          	jalr	-590(ra) # 800045f8 <filealloc>
    8000584e:	89aa                	mv	s3,a0
    80005850:	10050263          	beqz	a0,80005954 <sys_open+0x182>
    80005854:	00000097          	auipc	ra,0x0
    80005858:	902080e7          	jalr	-1790(ra) # 80005156 <fdalloc>
    8000585c:	84aa                	mv	s1,a0
    8000585e:	0e054663          	bltz	a0,8000594a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005862:	04491703          	lh	a4,68(s2)
    80005866:	478d                	li	a5,3
    80005868:	0cf70463          	beq	a4,a5,80005930 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000586c:	4789                	li	a5,2
    8000586e:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005872:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005876:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    8000587a:	f4c42783          	lw	a5,-180(s0)
    8000587e:	0017c713          	xori	a4,a5,1
    80005882:	8b05                	andi	a4,a4,1
    80005884:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005888:	0037f713          	andi	a4,a5,3
    8000588c:	00e03733          	snez	a4,a4
    80005890:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005894:	4007f793          	andi	a5,a5,1024
    80005898:	c791                	beqz	a5,800058a4 <sys_open+0xd2>
    8000589a:	04491703          	lh	a4,68(s2)
    8000589e:	4789                	li	a5,2
    800058a0:	08f70f63          	beq	a4,a5,8000593e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	03e080e7          	jalr	62(ra) # 800038e4 <iunlock>
  end_op();
    800058ae:	fffff097          	auipc	ra,0xfffff
    800058b2:	9b4080e7          	jalr	-1612(ra) # 80004262 <end_op>

  return fd;
}
    800058b6:	8526                	mv	a0,s1
    800058b8:	70ea                	ld	ra,184(sp)
    800058ba:	744a                	ld	s0,176(sp)
    800058bc:	74aa                	ld	s1,168(sp)
    800058be:	790a                	ld	s2,160(sp)
    800058c0:	69ea                	ld	s3,152(sp)
    800058c2:	6129                	addi	sp,sp,192
    800058c4:	8082                	ret
      end_op();
    800058c6:	fffff097          	auipc	ra,0xfffff
    800058ca:	99c080e7          	jalr	-1636(ra) # 80004262 <end_op>
      return -1;
    800058ce:	b7e5                	j	800058b6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800058d0:	f5040513          	addi	a0,s0,-176
    800058d4:	ffffe097          	auipc	ra,0xffffe
    800058d8:	702080e7          	jalr	1794(ra) # 80003fd6 <namei>
    800058dc:	892a                	mv	s2,a0
    800058de:	c905                	beqz	a0,8000590e <sys_open+0x13c>
    ilock(ip);
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	f42080e7          	jalr	-190(ra) # 80003822 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800058e8:	04491703          	lh	a4,68(s2)
    800058ec:	4785                	li	a5,1
    800058ee:	f4f712e3          	bne	a4,a5,80005832 <sys_open+0x60>
    800058f2:	f4c42783          	lw	a5,-180(s0)
    800058f6:	dba1                	beqz	a5,80005846 <sys_open+0x74>
      iunlockput(ip);
    800058f8:	854a                	mv	a0,s2
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	18a080e7          	jalr	394(ra) # 80003a84 <iunlockput>
      end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	960080e7          	jalr	-1696(ra) # 80004262 <end_op>
      return -1;
    8000590a:	54fd                	li	s1,-1
    8000590c:	b76d                	j	800058b6 <sys_open+0xe4>
      end_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	954080e7          	jalr	-1708(ra) # 80004262 <end_op>
      return -1;
    80005916:	54fd                	li	s1,-1
    80005918:	bf79                	j	800058b6 <sys_open+0xe4>
    iunlockput(ip);
    8000591a:	854a                	mv	a0,s2
    8000591c:	ffffe097          	auipc	ra,0xffffe
    80005920:	168080e7          	jalr	360(ra) # 80003a84 <iunlockput>
    end_op();
    80005924:	fffff097          	auipc	ra,0xfffff
    80005928:	93e080e7          	jalr	-1730(ra) # 80004262 <end_op>
    return -1;
    8000592c:	54fd                	li	s1,-1
    8000592e:	b761                	j	800058b6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005930:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005934:	04691783          	lh	a5,70(s2)
    80005938:	02f99223          	sh	a5,36(s3)
    8000593c:	bf2d                	j	80005876 <sys_open+0xa4>
    itrunc(ip);
    8000593e:	854a                	mv	a0,s2
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	ff0080e7          	jalr	-16(ra) # 80003930 <itrunc>
    80005948:	bfb1                	j	800058a4 <sys_open+0xd2>
      fileclose(f);
    8000594a:	854e                	mv	a0,s3
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	d68080e7          	jalr	-664(ra) # 800046b4 <fileclose>
    iunlockput(ip);
    80005954:	854a                	mv	a0,s2
    80005956:	ffffe097          	auipc	ra,0xffffe
    8000595a:	12e080e7          	jalr	302(ra) # 80003a84 <iunlockput>
    end_op();
    8000595e:	fffff097          	auipc	ra,0xfffff
    80005962:	904080e7          	jalr	-1788(ra) # 80004262 <end_op>
    return -1;
    80005966:	54fd                	li	s1,-1
    80005968:	b7b9                	j	800058b6 <sys_open+0xe4>

000000008000596a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000596a:	7175                	addi	sp,sp,-144
    8000596c:	e506                	sd	ra,136(sp)
    8000596e:	e122                	sd	s0,128(sp)
    80005970:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	870080e7          	jalr	-1936(ra) # 800041e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000597a:	08000613          	li	a2,128
    8000597e:	f7040593          	addi	a1,s0,-144
    80005982:	4501                	li	a0,0
    80005984:	ffffd097          	auipc	ra,0xffffd
    80005988:	370080e7          	jalr	880(ra) # 80002cf4 <argstr>
    8000598c:	02054963          	bltz	a0,800059be <sys_mkdir+0x54>
    80005990:	4681                	li	a3,0
    80005992:	4601                	li	a2,0
    80005994:	4585                	li	a1,1
    80005996:	f7040513          	addi	a0,s0,-144
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	7fe080e7          	jalr	2046(ra) # 80005198 <create>
    800059a2:	cd11                	beqz	a0,800059be <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059a4:	ffffe097          	auipc	ra,0xffffe
    800059a8:	0e0080e7          	jalr	224(ra) # 80003a84 <iunlockput>
  end_op();
    800059ac:	fffff097          	auipc	ra,0xfffff
    800059b0:	8b6080e7          	jalr	-1866(ra) # 80004262 <end_op>
  return 0;
    800059b4:	4501                	li	a0,0
}
    800059b6:	60aa                	ld	ra,136(sp)
    800059b8:	640a                	ld	s0,128(sp)
    800059ba:	6149                	addi	sp,sp,144
    800059bc:	8082                	ret
    end_op();
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	8a4080e7          	jalr	-1884(ra) # 80004262 <end_op>
    return -1;
    800059c6:	557d                	li	a0,-1
    800059c8:	b7fd                	j	800059b6 <sys_mkdir+0x4c>

00000000800059ca <sys_mknod>:

uint64
sys_mknod(void)
{
    800059ca:	7135                	addi	sp,sp,-160
    800059cc:	ed06                	sd	ra,152(sp)
    800059ce:	e922                	sd	s0,144(sp)
    800059d0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800059d2:	fffff097          	auipc	ra,0xfffff
    800059d6:	810080e7          	jalr	-2032(ra) # 800041e2 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059da:	08000613          	li	a2,128
    800059de:	f7040593          	addi	a1,s0,-144
    800059e2:	4501                	li	a0,0
    800059e4:	ffffd097          	auipc	ra,0xffffd
    800059e8:	310080e7          	jalr	784(ra) # 80002cf4 <argstr>
    800059ec:	04054a63          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    800059f0:	f6c40593          	addi	a1,s0,-148
    800059f4:	4505                	li	a0,1
    800059f6:	ffffd097          	auipc	ra,0xffffd
    800059fa:	2ba080e7          	jalr	698(ra) # 80002cb0 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800059fe:	04054163          	bltz	a0,80005a40 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005a02:	f6840593          	addi	a1,s0,-152
    80005a06:	4509                	li	a0,2
    80005a08:	ffffd097          	auipc	ra,0xffffd
    80005a0c:	2a8080e7          	jalr	680(ra) # 80002cb0 <argint>
     argint(1, &major) < 0 ||
    80005a10:	02054863          	bltz	a0,80005a40 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005a14:	f6841683          	lh	a3,-152(s0)
    80005a18:	f6c41603          	lh	a2,-148(s0)
    80005a1c:	458d                	li	a1,3
    80005a1e:	f7040513          	addi	a0,s0,-144
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	776080e7          	jalr	1910(ra) # 80005198 <create>
     argint(2, &minor) < 0 ||
    80005a2a:	c919                	beqz	a0,80005a40 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005a2c:	ffffe097          	auipc	ra,0xffffe
    80005a30:	058080e7          	jalr	88(ra) # 80003a84 <iunlockput>
  end_op();
    80005a34:	fffff097          	auipc	ra,0xfffff
    80005a38:	82e080e7          	jalr	-2002(ra) # 80004262 <end_op>
  return 0;
    80005a3c:	4501                	li	a0,0
    80005a3e:	a031                	j	80005a4a <sys_mknod+0x80>
    end_op();
    80005a40:	fffff097          	auipc	ra,0xfffff
    80005a44:	822080e7          	jalr	-2014(ra) # 80004262 <end_op>
    return -1;
    80005a48:	557d                	li	a0,-1
}
    80005a4a:	60ea                	ld	ra,152(sp)
    80005a4c:	644a                	ld	s0,144(sp)
    80005a4e:	610d                	addi	sp,sp,160
    80005a50:	8082                	ret

0000000080005a52 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005a52:	7135                	addi	sp,sp,-160
    80005a54:	ed06                	sd	ra,152(sp)
    80005a56:	e922                	sd	s0,144(sp)
    80005a58:	e526                	sd	s1,136(sp)
    80005a5a:	e14a                	sd	s2,128(sp)
    80005a5c:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005a5e:	ffffc097          	auipc	ra,0xffffc
    80005a62:	12e080e7          	jalr	302(ra) # 80001b8c <myproc>
    80005a66:	892a                	mv	s2,a0
  
  begin_op();
    80005a68:	ffffe097          	auipc	ra,0xffffe
    80005a6c:	77a080e7          	jalr	1914(ra) # 800041e2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a70:	08000613          	li	a2,128
    80005a74:	f6040593          	addi	a1,s0,-160
    80005a78:	4501                	li	a0,0
    80005a7a:	ffffd097          	auipc	ra,0xffffd
    80005a7e:	27a080e7          	jalr	634(ra) # 80002cf4 <argstr>
    80005a82:	04054b63          	bltz	a0,80005ad8 <sys_chdir+0x86>
    80005a86:	f6040513          	addi	a0,s0,-160
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	54c080e7          	jalr	1356(ra) # 80003fd6 <namei>
    80005a92:	84aa                	mv	s1,a0
    80005a94:	c131                	beqz	a0,80005ad8 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	d8c080e7          	jalr	-628(ra) # 80003822 <ilock>
  if(ip->type != T_DIR){
    80005a9e:	04449703          	lh	a4,68(s1)
    80005aa2:	4785                	li	a5,1
    80005aa4:	04f71063          	bne	a4,a5,80005ae4 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005aa8:	8526                	mv	a0,s1
    80005aaa:	ffffe097          	auipc	ra,0xffffe
    80005aae:	e3a080e7          	jalr	-454(ra) # 800038e4 <iunlock>
  iput(p->cwd);
    80005ab2:	15093503          	ld	a0,336(s2)
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	f26080e7          	jalr	-218(ra) # 800039dc <iput>
  end_op();
    80005abe:	ffffe097          	auipc	ra,0xffffe
    80005ac2:	7a4080e7          	jalr	1956(ra) # 80004262 <end_op>
  p->cwd = ip;
    80005ac6:	14993823          	sd	s1,336(s2)
  return 0;
    80005aca:	4501                	li	a0,0
}
    80005acc:	60ea                	ld	ra,152(sp)
    80005ace:	644a                	ld	s0,144(sp)
    80005ad0:	64aa                	ld	s1,136(sp)
    80005ad2:	690a                	ld	s2,128(sp)
    80005ad4:	610d                	addi	sp,sp,160
    80005ad6:	8082                	ret
    end_op();
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	78a080e7          	jalr	1930(ra) # 80004262 <end_op>
    return -1;
    80005ae0:	557d                	li	a0,-1
    80005ae2:	b7ed                	j	80005acc <sys_chdir+0x7a>
    iunlockput(ip);
    80005ae4:	8526                	mv	a0,s1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	f9e080e7          	jalr	-98(ra) # 80003a84 <iunlockput>
    end_op();
    80005aee:	ffffe097          	auipc	ra,0xffffe
    80005af2:	774080e7          	jalr	1908(ra) # 80004262 <end_op>
    return -1;
    80005af6:	557d                	li	a0,-1
    80005af8:	bfd1                	j	80005acc <sys_chdir+0x7a>

0000000080005afa <sys_exec>:

uint64
sys_exec(void)
{
    80005afa:	7145                	addi	sp,sp,-464
    80005afc:	e786                	sd	ra,456(sp)
    80005afe:	e3a2                	sd	s0,448(sp)
    80005b00:	ff26                	sd	s1,440(sp)
    80005b02:	fb4a                	sd	s2,432(sp)
    80005b04:	f74e                	sd	s3,424(sp)
    80005b06:	f352                	sd	s4,416(sp)
    80005b08:	ef56                	sd	s5,408(sp)
    80005b0a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b0c:	08000613          	li	a2,128
    80005b10:	f4040593          	addi	a1,s0,-192
    80005b14:	4501                	li	a0,0
    80005b16:	ffffd097          	auipc	ra,0xffffd
    80005b1a:	1de080e7          	jalr	478(ra) # 80002cf4 <argstr>
    return -1;
    80005b1e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005b20:	0c054a63          	bltz	a0,80005bf4 <sys_exec+0xfa>
    80005b24:	e3840593          	addi	a1,s0,-456
    80005b28:	4505                	li	a0,1
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	1a8080e7          	jalr	424(ra) # 80002cd2 <argaddr>
    80005b32:	0c054163          	bltz	a0,80005bf4 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005b36:	10000613          	li	a2,256
    80005b3a:	4581                	li	a1,0
    80005b3c:	e4040513          	addi	a0,s0,-448
    80005b40:	ffffb097          	auipc	ra,0xffffb
    80005b44:	292080e7          	jalr	658(ra) # 80000dd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005b48:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005b4c:	89a6                	mv	s3,s1
    80005b4e:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005b50:	02000a13          	li	s4,32
    80005b54:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005b58:	00391513          	slli	a0,s2,0x3
    80005b5c:	e3040593          	addi	a1,s0,-464
    80005b60:	e3843783          	ld	a5,-456(s0)
    80005b64:	953e                	add	a0,a0,a5
    80005b66:	ffffd097          	auipc	ra,0xffffd
    80005b6a:	0b0080e7          	jalr	176(ra) # 80002c16 <fetchaddr>
    80005b6e:	02054a63          	bltz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b72:	e3043783          	ld	a5,-464(s0)
    80005b76:	c3b9                	beqz	a5,80005bbc <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b78:	ffffb097          	auipc	ra,0xffffb
    80005b7c:	000080e7          	jalr	ra # 80000b78 <kalloc>
    80005b80:	85aa                	mv	a1,a0
    80005b82:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b86:	cd11                	beqz	a0,80005ba2 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b88:	6605                	lui	a2,0x1
    80005b8a:	e3043503          	ld	a0,-464(s0)
    80005b8e:	ffffd097          	auipc	ra,0xffffd
    80005b92:	0da080e7          	jalr	218(ra) # 80002c68 <fetchstr>
    80005b96:	00054663          	bltz	a0,80005ba2 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b9a:	0905                	addi	s2,s2,1
    80005b9c:	09a1                	addi	s3,s3,8
    80005b9e:	fb491be3          	bne	s2,s4,80005b54 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ba2:	10048913          	addi	s2,s1,256
    80005ba6:	6088                	ld	a0,0(s1)
    80005ba8:	c529                	beqz	a0,80005bf2 <sys_exec+0xf8>
    kfree(argv[i]);
    80005baa:	ffffb097          	auipc	ra,0xffffb
    80005bae:	e7a080e7          	jalr	-390(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bb2:	04a1                	addi	s1,s1,8
    80005bb4:	ff2499e3          	bne	s1,s2,80005ba6 <sys_exec+0xac>
  return -1;
    80005bb8:	597d                	li	s2,-1
    80005bba:	a82d                	j	80005bf4 <sys_exec+0xfa>
      argv[i] = 0;
    80005bbc:	0a8e                	slli	s5,s5,0x3
    80005bbe:	fc040793          	addi	a5,s0,-64
    80005bc2:	9abe                	add	s5,s5,a5
    80005bc4:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005bc8:	e4040593          	addi	a1,s0,-448
    80005bcc:	f4040513          	addi	a0,s0,-192
    80005bd0:	fffff097          	auipc	ra,0xfffff
    80005bd4:	194080e7          	jalr	404(ra) # 80004d64 <exec>
    80005bd8:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bda:	10048993          	addi	s3,s1,256
    80005bde:	6088                	ld	a0,0(s1)
    80005be0:	c911                	beqz	a0,80005bf4 <sys_exec+0xfa>
    kfree(argv[i]);
    80005be2:	ffffb097          	auipc	ra,0xffffb
    80005be6:	e42080e7          	jalr	-446(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005bea:	04a1                	addi	s1,s1,8
    80005bec:	ff3499e3          	bne	s1,s3,80005bde <sys_exec+0xe4>
    80005bf0:	a011                	j	80005bf4 <sys_exec+0xfa>
  return -1;
    80005bf2:	597d                	li	s2,-1
}
    80005bf4:	854a                	mv	a0,s2
    80005bf6:	60be                	ld	ra,456(sp)
    80005bf8:	641e                	ld	s0,448(sp)
    80005bfa:	74fa                	ld	s1,440(sp)
    80005bfc:	795a                	ld	s2,432(sp)
    80005bfe:	79ba                	ld	s3,424(sp)
    80005c00:	7a1a                	ld	s4,416(sp)
    80005c02:	6afa                	ld	s5,408(sp)
    80005c04:	6179                	addi	sp,sp,464
    80005c06:	8082                	ret

0000000080005c08 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005c08:	7139                	addi	sp,sp,-64
    80005c0a:	fc06                	sd	ra,56(sp)
    80005c0c:	f822                	sd	s0,48(sp)
    80005c0e:	f426                	sd	s1,40(sp)
    80005c10:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005c12:	ffffc097          	auipc	ra,0xffffc
    80005c16:	f7a080e7          	jalr	-134(ra) # 80001b8c <myproc>
    80005c1a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005c1c:	fd840593          	addi	a1,s0,-40
    80005c20:	4501                	li	a0,0
    80005c22:	ffffd097          	auipc	ra,0xffffd
    80005c26:	0b0080e7          	jalr	176(ra) # 80002cd2 <argaddr>
    return -1;
    80005c2a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005c2c:	0e054063          	bltz	a0,80005d0c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005c30:	fc840593          	addi	a1,s0,-56
    80005c34:	fd040513          	addi	a0,s0,-48
    80005c38:	fffff097          	auipc	ra,0xfffff
    80005c3c:	dd2080e7          	jalr	-558(ra) # 80004a0a <pipealloc>
    return -1;
    80005c40:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005c42:	0c054563          	bltz	a0,80005d0c <sys_pipe+0x104>
  fd0 = -1;
    80005c46:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005c4a:	fd043503          	ld	a0,-48(s0)
    80005c4e:	fffff097          	auipc	ra,0xfffff
    80005c52:	508080e7          	jalr	1288(ra) # 80005156 <fdalloc>
    80005c56:	fca42223          	sw	a0,-60(s0)
    80005c5a:	08054c63          	bltz	a0,80005cf2 <sys_pipe+0xea>
    80005c5e:	fc843503          	ld	a0,-56(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	4f4080e7          	jalr	1268(ra) # 80005156 <fdalloc>
    80005c6a:	fca42023          	sw	a0,-64(s0)
    80005c6e:	06054863          	bltz	a0,80005cde <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c72:	4691                	li	a3,4
    80005c74:	fc440613          	addi	a2,s0,-60
    80005c78:	fd843583          	ld	a1,-40(s0)
    80005c7c:	68a8                	ld	a0,80(s1)
    80005c7e:	ffffc097          	auipc	ra,0xffffc
    80005c82:	cf8080e7          	jalr	-776(ra) # 80001976 <copyout>
    80005c86:	02054063          	bltz	a0,80005ca6 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c8a:	4691                	li	a3,4
    80005c8c:	fc040613          	addi	a2,s0,-64
    80005c90:	fd843583          	ld	a1,-40(s0)
    80005c94:	0591                	addi	a1,a1,4
    80005c96:	68a8                	ld	a0,80(s1)
    80005c98:	ffffc097          	auipc	ra,0xffffc
    80005c9c:	cde080e7          	jalr	-802(ra) # 80001976 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005ca0:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ca2:	06055563          	bgez	a0,80005d0c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005ca6:	fc442783          	lw	a5,-60(s0)
    80005caa:	07e9                	addi	a5,a5,26
    80005cac:	078e                	slli	a5,a5,0x3
    80005cae:	97a6                	add	a5,a5,s1
    80005cb0:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005cb4:	fc042503          	lw	a0,-64(s0)
    80005cb8:	0569                	addi	a0,a0,26
    80005cba:	050e                	slli	a0,a0,0x3
    80005cbc:	9526                	add	a0,a0,s1
    80005cbe:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cc2:	fd043503          	ld	a0,-48(s0)
    80005cc6:	fffff097          	auipc	ra,0xfffff
    80005cca:	9ee080e7          	jalr	-1554(ra) # 800046b4 <fileclose>
    fileclose(wf);
    80005cce:	fc843503          	ld	a0,-56(s0)
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	9e2080e7          	jalr	-1566(ra) # 800046b4 <fileclose>
    return -1;
    80005cda:	57fd                	li	a5,-1
    80005cdc:	a805                	j	80005d0c <sys_pipe+0x104>
    if(fd0 >= 0)
    80005cde:	fc442783          	lw	a5,-60(s0)
    80005ce2:	0007c863          	bltz	a5,80005cf2 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ce6:	01a78513          	addi	a0,a5,26
    80005cea:	050e                	slli	a0,a0,0x3
    80005cec:	9526                	add	a0,a0,s1
    80005cee:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005cf2:	fd043503          	ld	a0,-48(s0)
    80005cf6:	fffff097          	auipc	ra,0xfffff
    80005cfa:	9be080e7          	jalr	-1602(ra) # 800046b4 <fileclose>
    fileclose(wf);
    80005cfe:	fc843503          	ld	a0,-56(s0)
    80005d02:	fffff097          	auipc	ra,0xfffff
    80005d06:	9b2080e7          	jalr	-1614(ra) # 800046b4 <fileclose>
    return -1;
    80005d0a:	57fd                	li	a5,-1
}
    80005d0c:	853e                	mv	a0,a5
    80005d0e:	70e2                	ld	ra,56(sp)
    80005d10:	7442                	ld	s0,48(sp)
    80005d12:	74a2                	ld	s1,40(sp)
    80005d14:	6121                	addi	sp,sp,64
    80005d16:	8082                	ret
	...

0000000080005d20 <kernelvec>:
    80005d20:	7111                	addi	sp,sp,-256
    80005d22:	e006                	sd	ra,0(sp)
    80005d24:	e40a                	sd	sp,8(sp)
    80005d26:	e80e                	sd	gp,16(sp)
    80005d28:	ec12                	sd	tp,24(sp)
    80005d2a:	f016                	sd	t0,32(sp)
    80005d2c:	f41a                	sd	t1,40(sp)
    80005d2e:	f81e                	sd	t2,48(sp)
    80005d30:	fc22                	sd	s0,56(sp)
    80005d32:	e0a6                	sd	s1,64(sp)
    80005d34:	e4aa                	sd	a0,72(sp)
    80005d36:	e8ae                	sd	a1,80(sp)
    80005d38:	ecb2                	sd	a2,88(sp)
    80005d3a:	f0b6                	sd	a3,96(sp)
    80005d3c:	f4ba                	sd	a4,104(sp)
    80005d3e:	f8be                	sd	a5,112(sp)
    80005d40:	fcc2                	sd	a6,120(sp)
    80005d42:	e146                	sd	a7,128(sp)
    80005d44:	e54a                	sd	s2,136(sp)
    80005d46:	e94e                	sd	s3,144(sp)
    80005d48:	ed52                	sd	s4,152(sp)
    80005d4a:	f156                	sd	s5,160(sp)
    80005d4c:	f55a                	sd	s6,168(sp)
    80005d4e:	f95e                	sd	s7,176(sp)
    80005d50:	fd62                	sd	s8,184(sp)
    80005d52:	e1e6                	sd	s9,192(sp)
    80005d54:	e5ea                	sd	s10,200(sp)
    80005d56:	e9ee                	sd	s11,208(sp)
    80005d58:	edf2                	sd	t3,216(sp)
    80005d5a:	f1f6                	sd	t4,224(sp)
    80005d5c:	f5fa                	sd	t5,232(sp)
    80005d5e:	f9fe                	sd	t6,240(sp)
    80005d60:	d83fc0ef          	jal	ra,80002ae2 <kerneltrap>
    80005d64:	6082                	ld	ra,0(sp)
    80005d66:	6122                	ld	sp,8(sp)
    80005d68:	61c2                	ld	gp,16(sp)
    80005d6a:	7282                	ld	t0,32(sp)
    80005d6c:	7322                	ld	t1,40(sp)
    80005d6e:	73c2                	ld	t2,48(sp)
    80005d70:	7462                	ld	s0,56(sp)
    80005d72:	6486                	ld	s1,64(sp)
    80005d74:	6526                	ld	a0,72(sp)
    80005d76:	65c6                	ld	a1,80(sp)
    80005d78:	6666                	ld	a2,88(sp)
    80005d7a:	7686                	ld	a3,96(sp)
    80005d7c:	7726                	ld	a4,104(sp)
    80005d7e:	77c6                	ld	a5,112(sp)
    80005d80:	7866                	ld	a6,120(sp)
    80005d82:	688a                	ld	a7,128(sp)
    80005d84:	692a                	ld	s2,136(sp)
    80005d86:	69ca                	ld	s3,144(sp)
    80005d88:	6a6a                	ld	s4,152(sp)
    80005d8a:	7a8a                	ld	s5,160(sp)
    80005d8c:	7b2a                	ld	s6,168(sp)
    80005d8e:	7bca                	ld	s7,176(sp)
    80005d90:	7c6a                	ld	s8,184(sp)
    80005d92:	6c8e                	ld	s9,192(sp)
    80005d94:	6d2e                	ld	s10,200(sp)
    80005d96:	6dce                	ld	s11,208(sp)
    80005d98:	6e6e                	ld	t3,216(sp)
    80005d9a:	7e8e                	ld	t4,224(sp)
    80005d9c:	7f2e                	ld	t5,232(sp)
    80005d9e:	7fce                	ld	t6,240(sp)
    80005da0:	6111                	addi	sp,sp,256
    80005da2:	10200073          	sret
    80005da6:	00000013          	nop
    80005daa:	00000013          	nop
    80005dae:	0001                	nop

0000000080005db0 <timervec>:
    80005db0:	34051573          	csrrw	a0,mscratch,a0
    80005db4:	e10c                	sd	a1,0(a0)
    80005db6:	e510                	sd	a2,8(a0)
    80005db8:	e914                	sd	a3,16(a0)
    80005dba:	710c                	ld	a1,32(a0)
    80005dbc:	7510                	ld	a2,40(a0)
    80005dbe:	6194                	ld	a3,0(a1)
    80005dc0:	96b2                	add	a3,a3,a2
    80005dc2:	e194                	sd	a3,0(a1)
    80005dc4:	4589                	li	a1,2
    80005dc6:	14459073          	csrw	sip,a1
    80005dca:	6914                	ld	a3,16(a0)
    80005dcc:	6510                	ld	a2,8(a0)
    80005dce:	610c                	ld	a1,0(a0)
    80005dd0:	34051573          	csrrw	a0,mscratch,a0
    80005dd4:	30200073          	mret
	...

0000000080005dda <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005dda:	1141                	addi	sp,sp,-16
    80005ddc:	e422                	sd	s0,8(sp)
    80005dde:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005de0:	0c0007b7          	lui	a5,0xc000
    80005de4:	4705                	li	a4,1
    80005de6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005de8:	c3d8                	sw	a4,4(a5)
}
    80005dea:	6422                	ld	s0,8(sp)
    80005dec:	0141                	addi	sp,sp,16
    80005dee:	8082                	ret

0000000080005df0 <plicinithart>:

void
plicinithart(void)
{
    80005df0:	1141                	addi	sp,sp,-16
    80005df2:	e406                	sd	ra,8(sp)
    80005df4:	e022                	sd	s0,0(sp)
    80005df6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	d68080e7          	jalr	-664(ra) # 80001b60 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005e00:	0085171b          	slliw	a4,a0,0x8
    80005e04:	0c0027b7          	lui	a5,0xc002
    80005e08:	97ba                	add	a5,a5,a4
    80005e0a:	40200713          	li	a4,1026
    80005e0e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005e12:	00d5151b          	slliw	a0,a0,0xd
    80005e16:	0c2017b7          	lui	a5,0xc201
    80005e1a:	953e                	add	a0,a0,a5
    80005e1c:	00052023          	sw	zero,0(a0)
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret

0000000080005e28 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005e28:	1141                	addi	sp,sp,-16
    80005e2a:	e406                	sd	ra,8(sp)
    80005e2c:	e022                	sd	s0,0(sp)
    80005e2e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005e30:	ffffc097          	auipc	ra,0xffffc
    80005e34:	d30080e7          	jalr	-720(ra) # 80001b60 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005e38:	00d5179b          	slliw	a5,a0,0xd
    80005e3c:	0c201537          	lui	a0,0xc201
    80005e40:	953e                	add	a0,a0,a5
  return irq;
}
    80005e42:	4148                	lw	a0,4(a0)
    80005e44:	60a2                	ld	ra,8(sp)
    80005e46:	6402                	ld	s0,0(sp)
    80005e48:	0141                	addi	sp,sp,16
    80005e4a:	8082                	ret

0000000080005e4c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005e4c:	1101                	addi	sp,sp,-32
    80005e4e:	ec06                	sd	ra,24(sp)
    80005e50:	e822                	sd	s0,16(sp)
    80005e52:	e426                	sd	s1,8(sp)
    80005e54:	1000                	addi	s0,sp,32
    80005e56:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005e58:	ffffc097          	auipc	ra,0xffffc
    80005e5c:	d08080e7          	jalr	-760(ra) # 80001b60 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e60:	00d5151b          	slliw	a0,a0,0xd
    80005e64:	0c2017b7          	lui	a5,0xc201
    80005e68:	97aa                	add	a5,a5,a0
    80005e6a:	c3c4                	sw	s1,4(a5)
}
    80005e6c:	60e2                	ld	ra,24(sp)
    80005e6e:	6442                	ld	s0,16(sp)
    80005e70:	64a2                	ld	s1,8(sp)
    80005e72:	6105                	addi	sp,sp,32
    80005e74:	8082                	ret

0000000080005e76 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e76:	1141                	addi	sp,sp,-16
    80005e78:	e406                	sd	ra,8(sp)
    80005e7a:	e022                	sd	s0,0(sp)
    80005e7c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e7e:	479d                	li	a5,7
    80005e80:	04a7cc63          	blt	a5,a0,80005ed8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e84:	0001d797          	auipc	a5,0x1d
    80005e88:	17c78793          	addi	a5,a5,380 # 80023000 <disk>
    80005e8c:	00a78733          	add	a4,a5,a0
    80005e90:	6789                	lui	a5,0x2
    80005e92:	97ba                	add	a5,a5,a4
    80005e94:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e98:	eba1                	bnez	a5,80005ee8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e9a:	00451713          	slli	a4,a0,0x4
    80005e9e:	0001f797          	auipc	a5,0x1f
    80005ea2:	1627b783          	ld	a5,354(a5) # 80025000 <disk+0x2000>
    80005ea6:	97ba                	add	a5,a5,a4
    80005ea8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005eac:	0001d797          	auipc	a5,0x1d
    80005eb0:	15478793          	addi	a5,a5,340 # 80023000 <disk>
    80005eb4:	97aa                	add	a5,a5,a0
    80005eb6:	6509                	lui	a0,0x2
    80005eb8:	953e                	add	a0,a0,a5
    80005eba:	4785                	li	a5,1
    80005ebc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005ec0:	0001f517          	auipc	a0,0x1f
    80005ec4:	15850513          	addi	a0,a0,344 # 80025018 <disk+0x2018>
    80005ec8:	ffffc097          	auipc	ra,0xffffc
    80005ecc:	65a080e7          	jalr	1626(ra) # 80002522 <wakeup>
}
    80005ed0:	60a2                	ld	ra,8(sp)
    80005ed2:	6402                	ld	s0,0(sp)
    80005ed4:	0141                	addi	sp,sp,16
    80005ed6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005ed8:	00003517          	auipc	a0,0x3
    80005edc:	88050513          	addi	a0,a0,-1920 # 80008758 <syscalls+0x330>
    80005ee0:	ffffa097          	auipc	ra,0xffffa
    80005ee4:	668080e7          	jalr	1640(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005ee8:	00003517          	auipc	a0,0x3
    80005eec:	88850513          	addi	a0,a0,-1912 # 80008770 <syscalls+0x348>
    80005ef0:	ffffa097          	auipc	ra,0xffffa
    80005ef4:	658080e7          	jalr	1624(ra) # 80000548 <panic>

0000000080005ef8 <virtio_disk_init>:
{
    80005ef8:	1101                	addi	sp,sp,-32
    80005efa:	ec06                	sd	ra,24(sp)
    80005efc:	e822                	sd	s0,16(sp)
    80005efe:	e426                	sd	s1,8(sp)
    80005f00:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005f02:	00003597          	auipc	a1,0x3
    80005f06:	88658593          	addi	a1,a1,-1914 # 80008788 <syscalls+0x360>
    80005f0a:	0001f517          	auipc	a0,0x1f
    80005f0e:	19e50513          	addi	a0,a0,414 # 800250a8 <disk+0x20a8>
    80005f12:	ffffb097          	auipc	ra,0xffffb
    80005f16:	d34080e7          	jalr	-716(ra) # 80000c46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f1a:	100017b7          	lui	a5,0x10001
    80005f1e:	4398                	lw	a4,0(a5)
    80005f20:	2701                	sext.w	a4,a4
    80005f22:	747277b7          	lui	a5,0x74727
    80005f26:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005f2a:	0ef71163          	bne	a4,a5,8000600c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f2e:	100017b7          	lui	a5,0x10001
    80005f32:	43dc                	lw	a5,4(a5)
    80005f34:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005f36:	4705                	li	a4,1
    80005f38:	0ce79a63          	bne	a5,a4,8000600c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f3c:	100017b7          	lui	a5,0x10001
    80005f40:	479c                	lw	a5,8(a5)
    80005f42:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005f44:	4709                	li	a4,2
    80005f46:	0ce79363          	bne	a5,a4,8000600c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005f4a:	100017b7          	lui	a5,0x10001
    80005f4e:	47d8                	lw	a4,12(a5)
    80005f50:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005f52:	554d47b7          	lui	a5,0x554d4
    80005f56:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005f5a:	0af71963          	bne	a4,a5,8000600c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f5e:	100017b7          	lui	a5,0x10001
    80005f62:	4705                	li	a4,1
    80005f64:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f66:	470d                	li	a4,3
    80005f68:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f6a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f6c:	c7ffe737          	lui	a4,0xc7ffe
    80005f70:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f74:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f76:	2701                	sext.w	a4,a4
    80005f78:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f7a:	472d                	li	a4,11
    80005f7c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f7e:	473d                	li	a4,15
    80005f80:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f82:	6705                	lui	a4,0x1
    80005f84:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f86:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f8a:	5bdc                	lw	a5,52(a5)
    80005f8c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f8e:	c7d9                	beqz	a5,8000601c <virtio_disk_init+0x124>
  if(max < NUM)
    80005f90:	471d                	li	a4,7
    80005f92:	08f77d63          	bgeu	a4,a5,8000602c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f96:	100014b7          	lui	s1,0x10001
    80005f9a:	47a1                	li	a5,8
    80005f9c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f9e:	6609                	lui	a2,0x2
    80005fa0:	4581                	li	a1,0
    80005fa2:	0001d517          	auipc	a0,0x1d
    80005fa6:	05e50513          	addi	a0,a0,94 # 80023000 <disk>
    80005faa:	ffffb097          	auipc	ra,0xffffb
    80005fae:	e28080e7          	jalr	-472(ra) # 80000dd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005fb2:	0001d717          	auipc	a4,0x1d
    80005fb6:	04e70713          	addi	a4,a4,78 # 80023000 <disk>
    80005fba:	00c75793          	srli	a5,a4,0xc
    80005fbe:	2781                	sext.w	a5,a5
    80005fc0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005fc2:	0001f797          	auipc	a5,0x1f
    80005fc6:	03e78793          	addi	a5,a5,62 # 80025000 <disk+0x2000>
    80005fca:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005fcc:	0001d717          	auipc	a4,0x1d
    80005fd0:	0b470713          	addi	a4,a4,180 # 80023080 <disk+0x80>
    80005fd4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005fd6:	0001e717          	auipc	a4,0x1e
    80005fda:	02a70713          	addi	a4,a4,42 # 80024000 <disk+0x1000>
    80005fde:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005fe0:	4705                	li	a4,1
    80005fe2:	00e78c23          	sb	a4,24(a5)
    80005fe6:	00e78ca3          	sb	a4,25(a5)
    80005fea:	00e78d23          	sb	a4,26(a5)
    80005fee:	00e78da3          	sb	a4,27(a5)
    80005ff2:	00e78e23          	sb	a4,28(a5)
    80005ff6:	00e78ea3          	sb	a4,29(a5)
    80005ffa:	00e78f23          	sb	a4,30(a5)
    80005ffe:	00e78fa3          	sb	a4,31(a5)
}
    80006002:	60e2                	ld	ra,24(sp)
    80006004:	6442                	ld	s0,16(sp)
    80006006:	64a2                	ld	s1,8(sp)
    80006008:	6105                	addi	sp,sp,32
    8000600a:	8082                	ret
    panic("could not find virtio disk");
    8000600c:	00002517          	auipc	a0,0x2
    80006010:	78c50513          	addi	a0,a0,1932 # 80008798 <syscalls+0x370>
    80006014:	ffffa097          	auipc	ra,0xffffa
    80006018:	534080e7          	jalr	1332(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    8000601c:	00002517          	auipc	a0,0x2
    80006020:	79c50513          	addi	a0,a0,1948 # 800087b8 <syscalls+0x390>
    80006024:	ffffa097          	auipc	ra,0xffffa
    80006028:	524080e7          	jalr	1316(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000602c:	00002517          	auipc	a0,0x2
    80006030:	7ac50513          	addi	a0,a0,1964 # 800087d8 <syscalls+0x3b0>
    80006034:	ffffa097          	auipc	ra,0xffffa
    80006038:	514080e7          	jalr	1300(ra) # 80000548 <panic>

000000008000603c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000603c:	7119                	addi	sp,sp,-128
    8000603e:	fc86                	sd	ra,120(sp)
    80006040:	f8a2                	sd	s0,112(sp)
    80006042:	f4a6                	sd	s1,104(sp)
    80006044:	f0ca                	sd	s2,96(sp)
    80006046:	ecce                	sd	s3,88(sp)
    80006048:	e8d2                	sd	s4,80(sp)
    8000604a:	e4d6                	sd	s5,72(sp)
    8000604c:	e0da                	sd	s6,64(sp)
    8000604e:	fc5e                	sd	s7,56(sp)
    80006050:	f862                	sd	s8,48(sp)
    80006052:	f466                	sd	s9,40(sp)
    80006054:	f06a                	sd	s10,32(sp)
    80006056:	0100                	addi	s0,sp,128
    80006058:	892a                	mv	s2,a0
    8000605a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000605c:	00c52c83          	lw	s9,12(a0)
    80006060:	001c9c9b          	slliw	s9,s9,0x1
    80006064:	1c82                	slli	s9,s9,0x20
    80006066:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000606a:	0001f517          	auipc	a0,0x1f
    8000606e:	03e50513          	addi	a0,a0,62 # 800250a8 <disk+0x20a8>
    80006072:	ffffb097          	auipc	ra,0xffffb
    80006076:	c64080e7          	jalr	-924(ra) # 80000cd6 <acquire>
  for(int i = 0; i < 3; i++){
    8000607a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000607c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000607e:	0001db97          	auipc	s7,0x1d
    80006082:	f82b8b93          	addi	s7,s7,-126 # 80023000 <disk>
    80006086:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006088:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000608a:	8a4e                	mv	s4,s3
    8000608c:	a051                	j	80006110 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000608e:	00fb86b3          	add	a3,s7,a5
    80006092:	96da                	add	a3,a3,s6
    80006094:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006098:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000609a:	0207c563          	bltz	a5,800060c4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000609e:	2485                	addiw	s1,s1,1
    800060a0:	0711                	addi	a4,a4,4
    800060a2:	23548d63          	beq	s1,s5,800062dc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    800060a6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800060a8:	0001f697          	auipc	a3,0x1f
    800060ac:	f7068693          	addi	a3,a3,-144 # 80025018 <disk+0x2018>
    800060b0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800060b2:	0006c583          	lbu	a1,0(a3)
    800060b6:	fde1                	bnez	a1,8000608e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800060b8:	2785                	addiw	a5,a5,1
    800060ba:	0685                	addi	a3,a3,1
    800060bc:	ff879be3          	bne	a5,s8,800060b2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800060c0:	57fd                	li	a5,-1
    800060c2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800060c4:	02905a63          	blez	s1,800060f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060c8:	f9042503          	lw	a0,-112(s0)
    800060cc:	00000097          	auipc	ra,0x0
    800060d0:	daa080e7          	jalr	-598(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    800060d4:	4785                	li	a5,1
    800060d6:	0297d163          	bge	a5,s1,800060f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060da:	f9442503          	lw	a0,-108(s0)
    800060de:	00000097          	auipc	ra,0x0
    800060e2:	d98080e7          	jalr	-616(ra) # 80005e76 <free_desc>
      for(int j = 0; j < i; j++)
    800060e6:	4789                	li	a5,2
    800060e8:	0097d863          	bge	a5,s1,800060f8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800060ec:	f9842503          	lw	a0,-104(s0)
    800060f0:	00000097          	auipc	ra,0x0
    800060f4:	d86080e7          	jalr	-634(ra) # 80005e76 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060f8:	0001f597          	auipc	a1,0x1f
    800060fc:	fb058593          	addi	a1,a1,-80 # 800250a8 <disk+0x20a8>
    80006100:	0001f517          	auipc	a0,0x1f
    80006104:	f1850513          	addi	a0,a0,-232 # 80025018 <disk+0x2018>
    80006108:	ffffc097          	auipc	ra,0xffffc
    8000610c:	294080e7          	jalr	660(ra) # 8000239c <sleep>
  for(int i = 0; i < 3; i++){
    80006110:	f9040713          	addi	a4,s0,-112
    80006114:	84ce                	mv	s1,s3
    80006116:	bf41                	j	800060a6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006118:	4785                	li	a5,1
    8000611a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000611e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006122:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006126:	f9042983          	lw	s3,-112(s0)
    8000612a:	00499493          	slli	s1,s3,0x4
    8000612e:	0001fa17          	auipc	s4,0x1f
    80006132:	ed2a0a13          	addi	s4,s4,-302 # 80025000 <disk+0x2000>
    80006136:	000a3a83          	ld	s5,0(s4)
    8000613a:	9aa6                	add	s5,s5,s1
    8000613c:	f8040513          	addi	a0,s0,-128
    80006140:	ffffb097          	auipc	ra,0xffffb
    80006144:	066080e7          	jalr	102(ra) # 800011a6 <kvmpa>
    80006148:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000614c:	000a3783          	ld	a5,0(s4)
    80006150:	97a6                	add	a5,a5,s1
    80006152:	4741                	li	a4,16
    80006154:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006156:	000a3783          	ld	a5,0(s4)
    8000615a:	97a6                	add	a5,a5,s1
    8000615c:	4705                	li	a4,1
    8000615e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006162:	f9442703          	lw	a4,-108(s0)
    80006166:	000a3783          	ld	a5,0(s4)
    8000616a:	97a6                	add	a5,a5,s1
    8000616c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006170:	0712                	slli	a4,a4,0x4
    80006172:	000a3783          	ld	a5,0(s4)
    80006176:	97ba                	add	a5,a5,a4
    80006178:	05890693          	addi	a3,s2,88
    8000617c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000617e:	000a3783          	ld	a5,0(s4)
    80006182:	97ba                	add	a5,a5,a4
    80006184:	40000693          	li	a3,1024
    80006188:	c794                	sw	a3,8(a5)
  if(write)
    8000618a:	100d0a63          	beqz	s10,8000629e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000618e:	0001f797          	auipc	a5,0x1f
    80006192:	e727b783          	ld	a5,-398(a5) # 80025000 <disk+0x2000>
    80006196:	97ba                	add	a5,a5,a4
    80006198:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000619c:	0001d517          	auipc	a0,0x1d
    800061a0:	e6450513          	addi	a0,a0,-412 # 80023000 <disk>
    800061a4:	0001f797          	auipc	a5,0x1f
    800061a8:	e5c78793          	addi	a5,a5,-420 # 80025000 <disk+0x2000>
    800061ac:	6394                	ld	a3,0(a5)
    800061ae:	96ba                	add	a3,a3,a4
    800061b0:	00c6d603          	lhu	a2,12(a3)
    800061b4:	00166613          	ori	a2,a2,1
    800061b8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800061bc:	f9842683          	lw	a3,-104(s0)
    800061c0:	6390                	ld	a2,0(a5)
    800061c2:	9732                	add	a4,a4,a2
    800061c4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800061c8:	20098613          	addi	a2,s3,512
    800061cc:	0612                	slli	a2,a2,0x4
    800061ce:	962a                	add	a2,a2,a0
    800061d0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800061d4:	00469713          	slli	a4,a3,0x4
    800061d8:	6394                	ld	a3,0(a5)
    800061da:	96ba                	add	a3,a3,a4
    800061dc:	6589                	lui	a1,0x2
    800061de:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800061e2:	94ae                	add	s1,s1,a1
    800061e4:	94aa                	add	s1,s1,a0
    800061e6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800061e8:	6394                	ld	a3,0(a5)
    800061ea:	96ba                	add	a3,a3,a4
    800061ec:	4585                	li	a1,1
    800061ee:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800061f0:	6394                	ld	a3,0(a5)
    800061f2:	96ba                	add	a3,a3,a4
    800061f4:	4509                	li	a0,2
    800061f6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800061fa:	6394                	ld	a3,0(a5)
    800061fc:	9736                	add	a4,a4,a3
    800061fe:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006202:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006206:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000620a:	6794                	ld	a3,8(a5)
    8000620c:	0026d703          	lhu	a4,2(a3)
    80006210:	8b1d                	andi	a4,a4,7
    80006212:	2709                	addiw	a4,a4,2
    80006214:	0706                	slli	a4,a4,0x1
    80006216:	9736                	add	a4,a4,a3
    80006218:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000621c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006220:	6798                	ld	a4,8(a5)
    80006222:	00275783          	lhu	a5,2(a4)
    80006226:	2785                	addiw	a5,a5,1
    80006228:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000622c:	100017b7          	lui	a5,0x10001
    80006230:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006234:	00492703          	lw	a4,4(s2)
    80006238:	4785                	li	a5,1
    8000623a:	02f71163          	bne	a4,a5,8000625c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000623e:	0001f997          	auipc	s3,0x1f
    80006242:	e6a98993          	addi	s3,s3,-406 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006246:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006248:	85ce                	mv	a1,s3
    8000624a:	854a                	mv	a0,s2
    8000624c:	ffffc097          	auipc	ra,0xffffc
    80006250:	150080e7          	jalr	336(ra) # 8000239c <sleep>
  while(b->disk == 1) {
    80006254:	00492783          	lw	a5,4(s2)
    80006258:	fe9788e3          	beq	a5,s1,80006248 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000625c:	f9042483          	lw	s1,-112(s0)
    80006260:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006264:	00479713          	slli	a4,a5,0x4
    80006268:	0001d797          	auipc	a5,0x1d
    8000626c:	d9878793          	addi	a5,a5,-616 # 80023000 <disk>
    80006270:	97ba                	add	a5,a5,a4
    80006272:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006276:	0001f917          	auipc	s2,0x1f
    8000627a:	d8a90913          	addi	s2,s2,-630 # 80025000 <disk+0x2000>
    free_desc(i);
    8000627e:	8526                	mv	a0,s1
    80006280:	00000097          	auipc	ra,0x0
    80006284:	bf6080e7          	jalr	-1034(ra) # 80005e76 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006288:	0492                	slli	s1,s1,0x4
    8000628a:	00093783          	ld	a5,0(s2)
    8000628e:	94be                	add	s1,s1,a5
    80006290:	00c4d783          	lhu	a5,12(s1)
    80006294:	8b85                	andi	a5,a5,1
    80006296:	cf89                	beqz	a5,800062b0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006298:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000629c:	b7cd                	j	8000627e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000629e:	0001f797          	auipc	a5,0x1f
    800062a2:	d627b783          	ld	a5,-670(a5) # 80025000 <disk+0x2000>
    800062a6:	97ba                	add	a5,a5,a4
    800062a8:	4689                	li	a3,2
    800062aa:	00d79623          	sh	a3,12(a5)
    800062ae:	b5fd                	j	8000619c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800062b0:	0001f517          	auipc	a0,0x1f
    800062b4:	df850513          	addi	a0,a0,-520 # 800250a8 <disk+0x20a8>
    800062b8:	ffffb097          	auipc	ra,0xffffb
    800062bc:	ad2080e7          	jalr	-1326(ra) # 80000d8a <release>
}
    800062c0:	70e6                	ld	ra,120(sp)
    800062c2:	7446                	ld	s0,112(sp)
    800062c4:	74a6                	ld	s1,104(sp)
    800062c6:	7906                	ld	s2,96(sp)
    800062c8:	69e6                	ld	s3,88(sp)
    800062ca:	6a46                	ld	s4,80(sp)
    800062cc:	6aa6                	ld	s5,72(sp)
    800062ce:	6b06                	ld	s6,64(sp)
    800062d0:	7be2                	ld	s7,56(sp)
    800062d2:	7c42                	ld	s8,48(sp)
    800062d4:	7ca2                	ld	s9,40(sp)
    800062d6:	7d02                	ld	s10,32(sp)
    800062d8:	6109                	addi	sp,sp,128
    800062da:	8082                	ret
  if(write)
    800062dc:	e20d1ee3          	bnez	s10,80006118 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800062e0:	f8042023          	sw	zero,-128(s0)
    800062e4:	bd2d                	j	8000611e <virtio_disk_rw+0xe2>

00000000800062e6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800062e6:	1101                	addi	sp,sp,-32
    800062e8:	ec06                	sd	ra,24(sp)
    800062ea:	e822                	sd	s0,16(sp)
    800062ec:	e426                	sd	s1,8(sp)
    800062ee:	e04a                	sd	s2,0(sp)
    800062f0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800062f2:	0001f517          	auipc	a0,0x1f
    800062f6:	db650513          	addi	a0,a0,-586 # 800250a8 <disk+0x20a8>
    800062fa:	ffffb097          	auipc	ra,0xffffb
    800062fe:	9dc080e7          	jalr	-1572(ra) # 80000cd6 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006302:	0001f717          	auipc	a4,0x1f
    80006306:	cfe70713          	addi	a4,a4,-770 # 80025000 <disk+0x2000>
    8000630a:	02075783          	lhu	a5,32(a4)
    8000630e:	6b18                	ld	a4,16(a4)
    80006310:	00275683          	lhu	a3,2(a4)
    80006314:	8ebd                	xor	a3,a3,a5
    80006316:	8a9d                	andi	a3,a3,7
    80006318:	cab9                	beqz	a3,8000636e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000631a:	0001d917          	auipc	s2,0x1d
    8000631e:	ce690913          	addi	s2,s2,-794 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006322:	0001f497          	auipc	s1,0x1f
    80006326:	cde48493          	addi	s1,s1,-802 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000632a:	078e                	slli	a5,a5,0x3
    8000632c:	97ba                	add	a5,a5,a4
    8000632e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006330:	20078713          	addi	a4,a5,512
    80006334:	0712                	slli	a4,a4,0x4
    80006336:	974a                	add	a4,a4,s2
    80006338:	03074703          	lbu	a4,48(a4)
    8000633c:	ef21                	bnez	a4,80006394 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000633e:	20078793          	addi	a5,a5,512
    80006342:	0792                	slli	a5,a5,0x4
    80006344:	97ca                	add	a5,a5,s2
    80006346:	7798                	ld	a4,40(a5)
    80006348:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000634c:	7788                	ld	a0,40(a5)
    8000634e:	ffffc097          	auipc	ra,0xffffc
    80006352:	1d4080e7          	jalr	468(ra) # 80002522 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006356:	0204d783          	lhu	a5,32(s1)
    8000635a:	2785                	addiw	a5,a5,1
    8000635c:	8b9d                	andi	a5,a5,7
    8000635e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006362:	6898                	ld	a4,16(s1)
    80006364:	00275683          	lhu	a3,2(a4)
    80006368:	8a9d                	andi	a3,a3,7
    8000636a:	fcf690e3          	bne	a3,a5,8000632a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000636e:	10001737          	lui	a4,0x10001
    80006372:	533c                	lw	a5,96(a4)
    80006374:	8b8d                	andi	a5,a5,3
    80006376:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006378:	0001f517          	auipc	a0,0x1f
    8000637c:	d3050513          	addi	a0,a0,-720 # 800250a8 <disk+0x20a8>
    80006380:	ffffb097          	auipc	ra,0xffffb
    80006384:	a0a080e7          	jalr	-1526(ra) # 80000d8a <release>
}
    80006388:	60e2                	ld	ra,24(sp)
    8000638a:	6442                	ld	s0,16(sp)
    8000638c:	64a2                	ld	s1,8(sp)
    8000638e:	6902                	ld	s2,0(sp)
    80006390:	6105                	addi	sp,sp,32
    80006392:	8082                	ret
      panic("virtio_disk_intr status");
    80006394:	00002517          	auipc	a0,0x2
    80006398:	46450513          	addi	a0,a0,1124 # 800087f8 <syscalls+0x3d0>
    8000639c:	ffffa097          	auipc	ra,0xffffa
    800063a0:	1ac080e7          	jalr	428(ra) # 80000548 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
