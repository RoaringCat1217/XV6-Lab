
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	83013103          	ld	sp,-2000(sp) # 80008830 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	cf478793          	addi	a5,a5,-780 # 80005d50 <timervec>
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
    800000aa:	e1878793          	addi	a5,a5,-488 # 80000ebe <main>
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
    80000110:	b04080e7          	jalr	-1276(ra) # 80000c10 <acquire>
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
    8000012a:	4ca080e7          	jalr	1226(ra) # 800025f0 <either_copyin>
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
    80000152:	b76080e7          	jalr	-1162(ra) # 80000cc4 <release>

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
    800001a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
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
    800001d2:	95a080e7          	jalr	-1702(ra) # 80001b28 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	15a080e7          	jalr	346(ra) # 80002338 <sleep>
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
    8000021e:	380080e7          	jalr	896(ra) # 8000259a <either_copyout>
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
    8000023a:	a8e080e7          	jalr	-1394(ra) # 80000cc4 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a78080e7          	jalr	-1416(ra) # 80000cc4 <release>
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
    800002e2:	932080e7          	jalr	-1742(ra) # 80000c10 <acquire>

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
    80000300:	34a080e7          	jalr	842(ra) # 80002646 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9b8080e7          	jalr	-1608(ra) # 80000cc4 <release>
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
    80000454:	06e080e7          	jalr	110(ra) # 800024be <wakeup>
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
    80000476:	70e080e7          	jalr	1806(ra) # 80000b80 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	330080e7          	jalr	816(ra) # 800007aa <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00021797          	auipc	a5,0x21
    80000486:	52e78793          	addi	a5,a5,1326 # 800219b0 <devsw>
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
    8000060e:	606080e7          	jalr	1542(ra) # 80000c10 <acquire>
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
    80000772:	556080e7          	jalr	1366(ra) # 80000cc4 <release>
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
    80000798:	3ec080e7          	jalr	1004(ra) # 80000b80 <initlock>
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
    800007ee:	396080e7          	jalr	918(ra) # 80000b80 <initlock>
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
    8000080a:	3be080e7          	jalr	958(ra) # 80000bc4 <push_off>

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
    8000083c:	42c080e7          	jalr	1068(ra) # 80000c64 <pop_off>
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
    800008ba:	c08080e7          	jalr	-1016(ra) # 800024be <wakeup>
    
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
    800008fe:	316080e7          	jalr	790(ra) # 80000c10 <acquire>
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
    80000954:	9e8080e7          	jalr	-1560(ra) # 80002338 <sleep>
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
    80000998:	330080e7          	jalr	816(ra) # 80000cc4 <release>
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
    80000a04:	210080e7          	jalr	528(ra) # 80000c10 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2b2080e7          	jalr	690(ra) # 80000cc4 <release>
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
    80000a34:	ebb9                	bnez	a5,80000a8a <kfree+0x66>
    80000a36:	84aa                	mv	s1,a0
    80000a38:	00025797          	auipc	a5,0x25
    80000a3c:	5c878793          	addi	a5,a5,1480 # 80026000 <end>
    80000a40:	04f56563          	bltu	a0,a5,80000a8a <kfree+0x66>
    80000a44:	47c5                	li	a5,17
    80000a46:	07ee                	slli	a5,a5,0x1b
    80000a48:	04f57163          	bgeu	a0,a5,80000a8a <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a4c:	6605                	lui	a2,0x1
    80000a4e:	4585                	li	a1,1
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	2bc080e7          	jalr	700(ra) # 80000d0c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1ae080e7          	jalr	430(ra) # 80000c10 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	24e080e7          	jalr	590(ra) # 80000cc4 <release>
}
    80000a7e:	60e2                	ld	ra,24(sp)
    80000a80:	6442                	ld	s0,16(sp)
    80000a82:	64a2                	ld	s1,8(sp)
    80000a84:	6902                	ld	s2,0(sp)
    80000a86:	6105                	addi	sp,sp,32
    80000a88:	8082                	ret
    panic("kfree");
    80000a8a:	00007517          	auipc	a0,0x7
    80000a8e:	5d650513          	addi	a0,a0,1494 # 80008060 <digits+0x20>
    80000a92:	00000097          	auipc	ra,0x0
    80000a96:	ab6080e7          	jalr	-1354(ra) # 80000548 <panic>

0000000080000a9a <freerange>:
{
    80000a9a:	7179                	addi	sp,sp,-48
    80000a9c:	f406                	sd	ra,40(sp)
    80000a9e:	f022                	sd	s0,32(sp)
    80000aa0:	ec26                	sd	s1,24(sp)
    80000aa2:	e84a                	sd	s2,16(sp)
    80000aa4:	e44e                	sd	s3,8(sp)
    80000aa6:	e052                	sd	s4,0(sp)
    80000aa8:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000aaa:	6785                	lui	a5,0x1
    80000aac:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ab0:	94aa                	add	s1,s1,a0
    80000ab2:	757d                	lui	a0,0xfffff
    80000ab4:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ab6:	94be                	add	s1,s1,a5
    80000ab8:	0095ee63          	bltu	a1,s1,80000ad4 <freerange+0x3a>
    80000abc:	892e                	mv	s2,a1
    kfree(p);
    80000abe:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ac0:	6985                	lui	s3,0x1
    kfree(p);
    80000ac2:	01448533          	add	a0,s1,s4
    80000ac6:	00000097          	auipc	ra,0x0
    80000aca:	f5e080e7          	jalr	-162(ra) # 80000a24 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000ace:	94ce                	add	s1,s1,s3
    80000ad0:	fe9979e3          	bgeu	s2,s1,80000ac2 <freerange+0x28>
}
    80000ad4:	70a2                	ld	ra,40(sp)
    80000ad6:	7402                	ld	s0,32(sp)
    80000ad8:	64e2                	ld	s1,24(sp)
    80000ada:	6942                	ld	s2,16(sp)
    80000adc:	69a2                	ld	s3,8(sp)
    80000ade:	6a02                	ld	s4,0(sp)
    80000ae0:	6145                	addi	sp,sp,48
    80000ae2:	8082                	ret

0000000080000ae4 <kinit>:
{
    80000ae4:	1141                	addi	sp,sp,-16
    80000ae6:	e406                	sd	ra,8(sp)
    80000ae8:	e022                	sd	s0,0(sp)
    80000aea:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000aec:	00007597          	auipc	a1,0x7
    80000af0:	57c58593          	addi	a1,a1,1404 # 80008068 <digits+0x28>
    80000af4:	00011517          	auipc	a0,0x11
    80000af8:	e3c50513          	addi	a0,a0,-452 # 80011930 <kmem>
    80000afc:	00000097          	auipc	ra,0x0
    80000b00:	084080e7          	jalr	132(ra) # 80000b80 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b04:	45c5                	li	a1,17
    80000b06:	05ee                	slli	a1,a1,0x1b
    80000b08:	00025517          	auipc	a0,0x25
    80000b0c:	4f850513          	addi	a0,a0,1272 # 80026000 <end>
    80000b10:	00000097          	auipc	ra,0x0
    80000b14:	f8a080e7          	jalr	-118(ra) # 80000a9a <freerange>
}
    80000b18:	60a2                	ld	ra,8(sp)
    80000b1a:	6402                	ld	s0,0(sp)
    80000b1c:	0141                	addi	sp,sp,16
    80000b1e:	8082                	ret

0000000080000b20 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b20:	1101                	addi	sp,sp,-32
    80000b22:	ec06                	sd	ra,24(sp)
    80000b24:	e822                	sd	s0,16(sp)
    80000b26:	e426                	sd	s1,8(sp)
    80000b28:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b2a:	00011497          	auipc	s1,0x11
    80000b2e:	e0648493          	addi	s1,s1,-506 # 80011930 <kmem>
    80000b32:	8526                	mv	a0,s1
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	0dc080e7          	jalr	220(ra) # 80000c10 <acquire>
  r = kmem.freelist;
    80000b3c:	6c84                	ld	s1,24(s1)
  if(r)
    80000b3e:	c885                	beqz	s1,80000b6e <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b40:	609c                	ld	a5,0(s1)
    80000b42:	00011517          	auipc	a0,0x11
    80000b46:	dee50513          	addi	a0,a0,-530 # 80011930 <kmem>
    80000b4a:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	178080e7          	jalr	376(ra) # 80000cc4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1b2080e7          	jalr	434(ra) # 80000d0c <memset>
  return (void*)r;
}
    80000b62:	8526                	mv	a0,s1
    80000b64:	60e2                	ld	ra,24(sp)
    80000b66:	6442                	ld	s0,16(sp)
    80000b68:	64a2                	ld	s1,8(sp)
    80000b6a:	6105                	addi	sp,sp,32
    80000b6c:	8082                	ret
  release(&kmem.lock);
    80000b6e:	00011517          	auipc	a0,0x11
    80000b72:	dc250513          	addi	a0,a0,-574 # 80011930 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	14e080e7          	jalr	334(ra) # 80000cc4 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b86:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b88:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b8c:	00053823          	sd	zero,16(a0)
}
    80000b90:	6422                	ld	s0,8(sp)
    80000b92:	0141                	addi	sp,sp,16
    80000b94:	8082                	ret

0000000080000b96 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b96:	411c                	lw	a5,0(a0)
    80000b98:	e399                	bnez	a5,80000b9e <holding+0x8>
    80000b9a:	4501                	li	a0,0
  return r;
}
    80000b9c:	8082                	ret
{
    80000b9e:	1101                	addi	sp,sp,-32
    80000ba0:	ec06                	sd	ra,24(sp)
    80000ba2:	e822                	sd	s0,16(sp)
    80000ba4:	e426                	sd	s1,8(sp)
    80000ba6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000ba8:	6904                	ld	s1,16(a0)
    80000baa:	00001097          	auipc	ra,0x1
    80000bae:	f62080e7          	jalr	-158(ra) # 80001b0c <mycpu>
    80000bb2:	40a48533          	sub	a0,s1,a0
    80000bb6:	00153513          	seqz	a0,a0
}
    80000bba:	60e2                	ld	ra,24(sp)
    80000bbc:	6442                	ld	s0,16(sp)
    80000bbe:	64a2                	ld	s1,8(sp)
    80000bc0:	6105                	addi	sp,sp,32
    80000bc2:	8082                	ret

0000000080000bc4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bc4:	1101                	addi	sp,sp,-32
    80000bc6:	ec06                	sd	ra,24(sp)
    80000bc8:	e822                	sd	s0,16(sp)
    80000bca:	e426                	sd	s1,8(sp)
    80000bcc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bce:	100024f3          	csrr	s1,sstatus
    80000bd2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bd6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bd8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bdc:	00001097          	auipc	ra,0x1
    80000be0:	f30080e7          	jalr	-208(ra) # 80001b0c <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	f24080e7          	jalr	-220(ra) # 80001b0c <mycpu>
    80000bf0:	5d3c                	lw	a5,120(a0)
    80000bf2:	2785                	addiw	a5,a5,1
    80000bf4:	dd3c                	sw	a5,120(a0)
}
    80000bf6:	60e2                	ld	ra,24(sp)
    80000bf8:	6442                	ld	s0,16(sp)
    80000bfa:	64a2                	ld	s1,8(sp)
    80000bfc:	6105                	addi	sp,sp,32
    80000bfe:	8082                	ret
    mycpu()->intena = old;
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	f0c080e7          	jalr	-244(ra) # 80001b0c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c08:	8085                	srli	s1,s1,0x1
    80000c0a:	8885                	andi	s1,s1,1
    80000c0c:	dd64                	sw	s1,124(a0)
    80000c0e:	bfe9                	j	80000be8 <push_off+0x24>

0000000080000c10 <acquire>:
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
    80000c1a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c1c:	00000097          	auipc	ra,0x0
    80000c20:	fa8080e7          	jalr	-88(ra) # 80000bc4 <push_off>
  if(holding(lk))
    80000c24:	8526                	mv	a0,s1
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	f70080e7          	jalr	-144(ra) # 80000b96 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c2e:	4705                	li	a4,1
  if(holding(lk))
    80000c30:	e115                	bnez	a0,80000c54 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c32:	87ba                	mv	a5,a4
    80000c34:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c38:	2781                	sext.w	a5,a5
    80000c3a:	ffe5                	bnez	a5,80000c32 <acquire+0x22>
  __sync_synchronize();
    80000c3c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c40:	00001097          	auipc	ra,0x1
    80000c44:	ecc080e7          	jalr	-308(ra) # 80001b0c <mycpu>
    80000c48:	e888                	sd	a0,16(s1)
}
    80000c4a:	60e2                	ld	ra,24(sp)
    80000c4c:	6442                	ld	s0,16(sp)
    80000c4e:	64a2                	ld	s1,8(sp)
    80000c50:	6105                	addi	sp,sp,32
    80000c52:	8082                	ret
    panic("acquire");
    80000c54:	00007517          	auipc	a0,0x7
    80000c58:	41c50513          	addi	a0,a0,1052 # 80008070 <digits+0x30>
    80000c5c:	00000097          	auipc	ra,0x0
    80000c60:	8ec080e7          	jalr	-1812(ra) # 80000548 <panic>

0000000080000c64 <pop_off>:

void
pop_off(void)
{
    80000c64:	1141                	addi	sp,sp,-16
    80000c66:	e406                	sd	ra,8(sp)
    80000c68:	e022                	sd	s0,0(sp)
    80000c6a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c6c:	00001097          	auipc	ra,0x1
    80000c70:	ea0080e7          	jalr	-352(ra) # 80001b0c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c74:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c78:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c7a:	e78d                	bnez	a5,80000ca4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c7c:	5d3c                	lw	a5,120(a0)
    80000c7e:	02f05b63          	blez	a5,80000cb4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c82:	37fd                	addiw	a5,a5,-1
    80000c84:	0007871b          	sext.w	a4,a5
    80000c88:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c8a:	eb09                	bnez	a4,80000c9c <pop_off+0x38>
    80000c8c:	5d7c                	lw	a5,124(a0)
    80000c8e:	c799                	beqz	a5,80000c9c <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c90:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c94:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c98:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c9c:	60a2                	ld	ra,8(sp)
    80000c9e:	6402                	ld	s0,0(sp)
    80000ca0:	0141                	addi	sp,sp,16
    80000ca2:	8082                	ret
    panic("pop_off - interruptible");
    80000ca4:	00007517          	auipc	a0,0x7
    80000ca8:	3d450513          	addi	a0,a0,980 # 80008078 <digits+0x38>
    80000cac:	00000097          	auipc	ra,0x0
    80000cb0:	89c080e7          	jalr	-1892(ra) # 80000548 <panic>
    panic("pop_off");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3dc50513          	addi	a0,a0,988 # 80008090 <digits+0x50>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	88c080e7          	jalr	-1908(ra) # 80000548 <panic>

0000000080000cc4 <release>:
{
    80000cc4:	1101                	addi	sp,sp,-32
    80000cc6:	ec06                	sd	ra,24(sp)
    80000cc8:	e822                	sd	s0,16(sp)
    80000cca:	e426                	sd	s1,8(sp)
    80000ccc:	1000                	addi	s0,sp,32
    80000cce:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	ec6080e7          	jalr	-314(ra) # 80000b96 <holding>
    80000cd8:	c115                	beqz	a0,80000cfc <release+0x38>
  lk->cpu = 0;
    80000cda:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cde:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ce2:	0f50000f          	fence	iorw,ow
    80000ce6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cea:	00000097          	auipc	ra,0x0
    80000cee:	f7a080e7          	jalr	-134(ra) # 80000c64 <pop_off>
}
    80000cf2:	60e2                	ld	ra,24(sp)
    80000cf4:	6442                	ld	s0,16(sp)
    80000cf6:	64a2                	ld	s1,8(sp)
    80000cf8:	6105                	addi	sp,sp,32
    80000cfa:	8082                	ret
    panic("release");
    80000cfc:	00007517          	auipc	a0,0x7
    80000d00:	39c50513          	addi	a0,a0,924 # 80008098 <digits+0x58>
    80000d04:	00000097          	auipc	ra,0x0
    80000d08:	844080e7          	jalr	-1980(ra) # 80000548 <panic>

0000000080000d0c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d0c:	1141                	addi	sp,sp,-16
    80000d0e:	e422                	sd	s0,8(sp)
    80000d10:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d12:	ce09                	beqz	a2,80000d2c <memset+0x20>
    80000d14:	87aa                	mv	a5,a0
    80000d16:	fff6071b          	addiw	a4,a2,-1
    80000d1a:	1702                	slli	a4,a4,0x20
    80000d1c:	9301                	srli	a4,a4,0x20
    80000d1e:	0705                	addi	a4,a4,1
    80000d20:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d22:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d26:	0785                	addi	a5,a5,1
    80000d28:	fee79de3          	bne	a5,a4,80000d22 <memset+0x16>
  }
  return dst;
}
    80000d2c:	6422                	ld	s0,8(sp)
    80000d2e:	0141                	addi	sp,sp,16
    80000d30:	8082                	ret

0000000080000d32 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d32:	1141                	addi	sp,sp,-16
    80000d34:	e422                	sd	s0,8(sp)
    80000d36:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d38:	ca05                	beqz	a2,80000d68 <memcmp+0x36>
    80000d3a:	fff6069b          	addiw	a3,a2,-1
    80000d3e:	1682                	slli	a3,a3,0x20
    80000d40:	9281                	srli	a3,a3,0x20
    80000d42:	0685                	addi	a3,a3,1
    80000d44:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d46:	00054783          	lbu	a5,0(a0)
    80000d4a:	0005c703          	lbu	a4,0(a1)
    80000d4e:	00e79863          	bne	a5,a4,80000d5e <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d52:	0505                	addi	a0,a0,1
    80000d54:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d56:	fed518e3          	bne	a0,a3,80000d46 <memcmp+0x14>
  }

  return 0;
    80000d5a:	4501                	li	a0,0
    80000d5c:	a019                	j	80000d62 <memcmp+0x30>
      return *s1 - *s2;
    80000d5e:	40e7853b          	subw	a0,a5,a4
}
    80000d62:	6422                	ld	s0,8(sp)
    80000d64:	0141                	addi	sp,sp,16
    80000d66:	8082                	ret
  return 0;
    80000d68:	4501                	li	a0,0
    80000d6a:	bfe5                	j	80000d62 <memcmp+0x30>

0000000080000d6c <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d72:	00a5f963          	bgeu	a1,a0,80000d84 <memmove+0x18>
    80000d76:	02061713          	slli	a4,a2,0x20
    80000d7a:	9301                	srli	a4,a4,0x20
    80000d7c:	00e587b3          	add	a5,a1,a4
    80000d80:	02f56563          	bltu	a0,a5,80000daa <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	fff6069b          	addiw	a3,a2,-1
    80000d88:	ce11                	beqz	a2,80000da4 <memmove+0x38>
    80000d8a:	1682                	slli	a3,a3,0x20
    80000d8c:	9281                	srli	a3,a3,0x20
    80000d8e:	0685                	addi	a3,a3,1
    80000d90:	96ae                	add	a3,a3,a1
    80000d92:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000d94:	0585                	addi	a1,a1,1
    80000d96:	0785                	addi	a5,a5,1
    80000d98:	fff5c703          	lbu	a4,-1(a1)
    80000d9c:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000da0:	fed59ae3          	bne	a1,a3,80000d94 <memmove+0x28>

  return dst;
}
    80000da4:	6422                	ld	s0,8(sp)
    80000da6:	0141                	addi	sp,sp,16
    80000da8:	8082                	ret
    d += n;
    80000daa:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dac:	fff6069b          	addiw	a3,a2,-1
    80000db0:	da75                	beqz	a2,80000da4 <memmove+0x38>
    80000db2:	02069613          	slli	a2,a3,0x20
    80000db6:	9201                	srli	a2,a2,0x20
    80000db8:	fff64613          	not	a2,a2
    80000dbc:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000dbe:	17fd                	addi	a5,a5,-1
    80000dc0:	177d                	addi	a4,a4,-1
    80000dc2:	0007c683          	lbu	a3,0(a5)
    80000dc6:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dca:	fec79ae3          	bne	a5,a2,80000dbe <memmove+0x52>
    80000dce:	bfd9                	j	80000da4 <memmove+0x38>

0000000080000dd0 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dd8:	00000097          	auipc	ra,0x0
    80000ddc:	f94080e7          	jalr	-108(ra) # 80000d6c <memmove>
}
    80000de0:	60a2                	ld	ra,8(sp)
    80000de2:	6402                	ld	s0,0(sp)
    80000de4:	0141                	addi	sp,sp,16
    80000de6:	8082                	ret

0000000080000de8 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000de8:	1141                	addi	sp,sp,-16
    80000dea:	e422                	sd	s0,8(sp)
    80000dec:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000dee:	ce11                	beqz	a2,80000e0a <strncmp+0x22>
    80000df0:	00054783          	lbu	a5,0(a0)
    80000df4:	cf89                	beqz	a5,80000e0e <strncmp+0x26>
    80000df6:	0005c703          	lbu	a4,0(a1)
    80000dfa:	00f71a63          	bne	a4,a5,80000e0e <strncmp+0x26>
    n--, p++, q++;
    80000dfe:	367d                	addiw	a2,a2,-1
    80000e00:	0505                	addi	a0,a0,1
    80000e02:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e04:	f675                	bnez	a2,80000df0 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e06:	4501                	li	a0,0
    80000e08:	a809                	j	80000e1a <strncmp+0x32>
    80000e0a:	4501                	li	a0,0
    80000e0c:	a039                	j	80000e1a <strncmp+0x32>
  if(n == 0)
    80000e0e:	ca09                	beqz	a2,80000e20 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e10:	00054503          	lbu	a0,0(a0)
    80000e14:	0005c783          	lbu	a5,0(a1)
    80000e18:	9d1d                	subw	a0,a0,a5
}
    80000e1a:	6422                	ld	s0,8(sp)
    80000e1c:	0141                	addi	sp,sp,16
    80000e1e:	8082                	ret
    return 0;
    80000e20:	4501                	li	a0,0
    80000e22:	bfe5                	j	80000e1a <strncmp+0x32>

0000000080000e24 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e24:	1141                	addi	sp,sp,-16
    80000e26:	e422                	sd	s0,8(sp)
    80000e28:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2a:	872a                	mv	a4,a0
    80000e2c:	8832                	mv	a6,a2
    80000e2e:	367d                	addiw	a2,a2,-1
    80000e30:	01005963          	blez	a6,80000e42 <strncpy+0x1e>
    80000e34:	0705                	addi	a4,a4,1
    80000e36:	0005c783          	lbu	a5,0(a1)
    80000e3a:	fef70fa3          	sb	a5,-1(a4)
    80000e3e:	0585                	addi	a1,a1,1
    80000e40:	f7f5                	bnez	a5,80000e2c <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e42:	00c05d63          	blez	a2,80000e5c <strncpy+0x38>
    80000e46:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e48:	0685                	addi	a3,a3,1
    80000e4a:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e4e:	fff6c793          	not	a5,a3
    80000e52:	9fb9                	addw	a5,a5,a4
    80000e54:	010787bb          	addw	a5,a5,a6
    80000e58:	fef048e3          	bgtz	a5,80000e48 <strncpy+0x24>
  return os;
}
    80000e5c:	6422                	ld	s0,8(sp)
    80000e5e:	0141                	addi	sp,sp,16
    80000e60:	8082                	ret

0000000080000e62 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e62:	1141                	addi	sp,sp,-16
    80000e64:	e422                	sd	s0,8(sp)
    80000e66:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e68:	02c05363          	blez	a2,80000e8e <safestrcpy+0x2c>
    80000e6c:	fff6069b          	addiw	a3,a2,-1
    80000e70:	1682                	slli	a3,a3,0x20
    80000e72:	9281                	srli	a3,a3,0x20
    80000e74:	96ae                	add	a3,a3,a1
    80000e76:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e78:	00d58963          	beq	a1,a3,80000e8a <safestrcpy+0x28>
    80000e7c:	0585                	addi	a1,a1,1
    80000e7e:	0785                	addi	a5,a5,1
    80000e80:	fff5c703          	lbu	a4,-1(a1)
    80000e84:	fee78fa3          	sb	a4,-1(a5)
    80000e88:	fb65                	bnez	a4,80000e78 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8a:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret

0000000080000e94 <strlen>:

int
strlen(const char *s)
{
    80000e94:	1141                	addi	sp,sp,-16
    80000e96:	e422                	sd	s0,8(sp)
    80000e98:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9a:	00054783          	lbu	a5,0(a0)
    80000e9e:	cf91                	beqz	a5,80000eba <strlen+0x26>
    80000ea0:	0505                	addi	a0,a0,1
    80000ea2:	87aa                	mv	a5,a0
    80000ea4:	4685                	li	a3,1
    80000ea6:	9e89                	subw	a3,a3,a0
    80000ea8:	00f6853b          	addw	a0,a3,a5
    80000eac:	0785                	addi	a5,a5,1
    80000eae:	fff7c703          	lbu	a4,-1(a5)
    80000eb2:	fb7d                	bnez	a4,80000ea8 <strlen+0x14>
    ;
  return n;
}
    80000eb4:	6422                	ld	s0,8(sp)
    80000eb6:	0141                	addi	sp,sp,16
    80000eb8:	8082                	ret
  for(n = 0; s[n]; n++)
    80000eba:	4501                	li	a0,0
    80000ebc:	bfe5                	j	80000eb4 <strlen+0x20>

0000000080000ebe <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ebe:	1141                	addi	sp,sp,-16
    80000ec0:	e406                	sd	ra,8(sp)
    80000ec2:	e022                	sd	s0,0(sp)
    80000ec4:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000ec6:	00001097          	auipc	ra,0x1
    80000eca:	c36080e7          	jalr	-970(ra) # 80001afc <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ece:	00008717          	auipc	a4,0x8
    80000ed2:	13e70713          	addi	a4,a4,318 # 8000900c <started>
  if(cpuid() == 0){
    80000ed6:	c139                	beqz	a0,80000f1c <main+0x5e>
    while(started == 0)
    80000ed8:	431c                	lw	a5,0(a4)
    80000eda:	2781                	sext.w	a5,a5
    80000edc:	dff5                	beqz	a5,80000ed8 <main+0x1a>
      ;
    __sync_synchronize();
    80000ede:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee2:	00001097          	auipc	ra,0x1
    80000ee6:	c1a080e7          	jalr	-998(ra) # 80001afc <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	0d8080e7          	jalr	216(ra) # 80000fd4 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	882080e7          	jalr	-1918(ra) # 80002786 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	e84080e7          	jalr	-380(ra) # 80005d90 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	144080e7          	jalr	324(ra) # 80002058 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    printfinit();
    80000f24:	00000097          	auipc	ra,0x0
    80000f28:	854080e7          	jalr	-1964(ra) # 80000778 <printfinit>
    printf("\n");
    80000f2c:	00007517          	auipc	a0,0x7
    80000f30:	19c50513          	addi	a0,a0,412 # 800080c8 <digits+0x88>
    80000f34:	fffff097          	auipc	ra,0xfffff
    80000f38:	65e080e7          	jalr	1630(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f3c:	00007517          	auipc	a0,0x7
    80000f40:	16450513          	addi	a0,a0,356 # 800080a0 <digits+0x60>
    80000f44:	fffff097          	auipc	ra,0xfffff
    80000f48:	64e080e7          	jalr	1614(ra) # 80000592 <printf>
    printf("\n");
    80000f4c:	00007517          	auipc	a0,0x7
    80000f50:	17c50513          	addi	a0,a0,380 # 800080c8 <digits+0x88>
    80000f54:	fffff097          	auipc	ra,0xfffff
    80000f58:	63e080e7          	jalr	1598(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f5c:	00000097          	auipc	ra,0x0
    80000f60:	b88080e7          	jalr	-1144(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	2a0080e7          	jalr	672(ra) # 80001204 <kvminit>
    kvminithart();   // turn on paging
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	068080e7          	jalr	104(ra) # 80000fd4 <kvminithart>
    procinit();      // process table
    80000f74:	00001097          	auipc	ra,0x1
    80000f78:	ab8080e7          	jalr	-1352(ra) # 80001a2c <procinit>
    trapinit();      // trap vectors
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	7e2080e7          	jalr	2018(ra) # 8000275e <trapinit>
    trapinithart();  // install kernel trap vector
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	802080e7          	jalr	-2046(ra) # 80002786 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f8c:	00005097          	auipc	ra,0x5
    80000f90:	dee080e7          	jalr	-530(ra) # 80005d7a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	dfc080e7          	jalr	-516(ra) # 80005d90 <plicinithart>
    binit();         // buffer cache
    80000f9c:	00002097          	auipc	ra,0x2
    80000fa0:	f92080e7          	jalr	-110(ra) # 80002f2e <binit>
    iinit();         // inode cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	622080e7          	jalr	1570(ra) # 800035c6 <iinit>
    fileinit();      // file table
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	5c0080e7          	jalr	1472(ra) # 8000456c <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb4:	00005097          	auipc	ra,0x5
    80000fb8:	ee4080e7          	jalr	-284(ra) # 80005e98 <virtio_disk_init>
    userinit();      // first user process
    80000fbc:	00001097          	auipc	ra,0x1
    80000fc0:	e36080e7          	jalr	-458(ra) # 80001df2 <userinit>
    __sync_synchronize();
    80000fc4:	0ff0000f          	fence
    started = 1;
    80000fc8:	4785                	li	a5,1
    80000fca:	00008717          	auipc	a4,0x8
    80000fce:	04f72123          	sw	a5,66(a4) # 8000900c <started>
    80000fd2:	b789                	j	80000f14 <main+0x56>

0000000080000fd4 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd4:	1141                	addi	sp,sp,-16
    80000fd6:	e422                	sd	s0,8(sp)
    80000fd8:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000fda:	00008797          	auipc	a5,0x8
    80000fde:	0367b783          	ld	a5,54(a5) # 80009010 <kernel_pagetable>
    80000fe2:	83b1                	srli	a5,a5,0xc
    80000fe4:	577d                	li	a4,-1
    80000fe6:	177e                	slli	a4,a4,0x3f
    80000fe8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fea:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fee:	12000073          	sfence.vma
  sfence_vma();
}
    80000ff2:	6422                	ld	s0,8(sp)
    80000ff4:	0141                	addi	sp,sp,16
    80000ff6:	8082                	ret

0000000080000ff8 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000ff8:	7139                	addi	sp,sp,-64
    80000ffa:	fc06                	sd	ra,56(sp)
    80000ffc:	f822                	sd	s0,48(sp)
    80000ffe:	f426                	sd	s1,40(sp)
    80001000:	f04a                	sd	s2,32(sp)
    80001002:	ec4e                	sd	s3,24(sp)
    80001004:	e852                	sd	s4,16(sp)
    80001006:	e456                	sd	s5,8(sp)
    80001008:	e05a                	sd	s6,0(sp)
    8000100a:	0080                	addi	s0,sp,64
    8000100c:	84aa                	mv	s1,a0
    8000100e:	89ae                	mv	s3,a1
    80001010:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001012:	57fd                	li	a5,-1
    80001014:	83e9                	srli	a5,a5,0x1a
    80001016:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001018:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000101a:	04b7f263          	bgeu	a5,a1,8000105e <walk+0x66>
    panic("walk");
    8000101e:	00007517          	auipc	a0,0x7
    80001022:	0b250513          	addi	a0,a0,178 # 800080d0 <digits+0x90>
    80001026:	fffff097          	auipc	ra,0xfffff
    8000102a:	522080e7          	jalr	1314(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    8000102e:	060a8663          	beqz	s5,8000109a <walk+0xa2>
    80001032:	00000097          	auipc	ra,0x0
    80001036:	aee080e7          	jalr	-1298(ra) # 80000b20 <kalloc>
    8000103a:	84aa                	mv	s1,a0
    8000103c:	c529                	beqz	a0,80001086 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    8000103e:	6605                	lui	a2,0x1
    80001040:	4581                	li	a1,0
    80001042:	00000097          	auipc	ra,0x0
    80001046:	cca080e7          	jalr	-822(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000104a:	00c4d793          	srli	a5,s1,0xc
    8000104e:	07aa                	slli	a5,a5,0xa
    80001050:	0017e793          	ori	a5,a5,1
    80001054:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001058:	3a5d                	addiw	s4,s4,-9
    8000105a:	036a0063          	beq	s4,s6,8000107a <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000105e:	0149d933          	srl	s2,s3,s4
    80001062:	1ff97913          	andi	s2,s2,511
    80001066:	090e                	slli	s2,s2,0x3
    80001068:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000106a:	00093483          	ld	s1,0(s2)
    8000106e:	0014f793          	andi	a5,s1,1
    80001072:	dfd5                	beqz	a5,8000102e <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001074:	80a9                	srli	s1,s1,0xa
    80001076:	04b2                	slli	s1,s1,0xc
    80001078:	b7c5                	j	80001058 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000107a:	00c9d513          	srli	a0,s3,0xc
    8000107e:	1ff57513          	andi	a0,a0,511
    80001082:	050e                	slli	a0,a0,0x3
    80001084:	9526                	add	a0,a0,s1
}
    80001086:	70e2                	ld	ra,56(sp)
    80001088:	7442                	ld	s0,48(sp)
    8000108a:	74a2                	ld	s1,40(sp)
    8000108c:	7902                	ld	s2,32(sp)
    8000108e:	69e2                	ld	s3,24(sp)
    80001090:	6a42                	ld	s4,16(sp)
    80001092:	6aa2                	ld	s5,8(sp)
    80001094:	6b02                	ld	s6,0(sp)
    80001096:	6121                	addi	sp,sp,64
    80001098:	8082                	ret
        return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7ed                	j	80001086 <walk+0x8e>

000000008000109e <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000109e:	57fd                	li	a5,-1
    800010a0:	83e9                	srli	a5,a5,0x1a
    800010a2:	00b7f463          	bgeu	a5,a1,800010aa <walkaddr+0xc>
    return 0;
    800010a6:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010a8:	8082                	ret
{
    800010aa:	1141                	addi	sp,sp,-16
    800010ac:	e406                	sd	ra,8(sp)
    800010ae:	e022                	sd	s0,0(sp)
    800010b0:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010b2:	4601                	li	a2,0
    800010b4:	00000097          	auipc	ra,0x0
    800010b8:	f44080e7          	jalr	-188(ra) # 80000ff8 <walk>
  if(pte == 0)
    800010bc:	c105                	beqz	a0,800010dc <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010be:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c0:	0117f693          	andi	a3,a5,17
    800010c4:	4745                	li	a4,17
    return 0;
    800010c6:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010c8:	00e68663          	beq	a3,a4,800010d4 <walkaddr+0x36>
}
    800010cc:	60a2                	ld	ra,8(sp)
    800010ce:	6402                	ld	s0,0(sp)
    800010d0:	0141                	addi	sp,sp,16
    800010d2:	8082                	ret
  pa = PTE2PA(*pte);
    800010d4:	00a7d513          	srli	a0,a5,0xa
    800010d8:	0532                	slli	a0,a0,0xc
  return pa;
    800010da:	bfcd                	j	800010cc <walkaddr+0x2e>
    return 0;
    800010dc:	4501                	li	a0,0
    800010de:	b7fd                	j	800010cc <walkaddr+0x2e>

00000000800010e0 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    800010e0:	1101                	addi	sp,sp,-32
    800010e2:	ec06                	sd	ra,24(sp)
    800010e4:	e822                	sd	s0,16(sp)
    800010e6:	e426                	sd	s1,8(sp)
    800010e8:	1000                	addi	s0,sp,32
    800010ea:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    800010ec:	1552                	slli	a0,a0,0x34
    800010ee:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    800010f2:	4601                	li	a2,0
    800010f4:	00008517          	auipc	a0,0x8
    800010f8:	f1c53503          	ld	a0,-228(a0) # 80009010 <kernel_pagetable>
    800010fc:	00000097          	auipc	ra,0x0
    80001100:	efc080e7          	jalr	-260(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001104:	cd09                	beqz	a0,8000111e <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    80001106:	6108                	ld	a0,0(a0)
    80001108:	00157793          	andi	a5,a0,1
    8000110c:	c38d                	beqz	a5,8000112e <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    8000110e:	8129                	srli	a0,a0,0xa
    80001110:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001112:	9526                	add	a0,a0,s1
    80001114:	60e2                	ld	ra,24(sp)
    80001116:	6442                	ld	s0,16(sp)
    80001118:	64a2                	ld	s1,8(sp)
    8000111a:	6105                	addi	sp,sp,32
    8000111c:	8082                	ret
    panic("kvmpa");
    8000111e:	00007517          	auipc	a0,0x7
    80001122:	fba50513          	addi	a0,a0,-70 # 800080d8 <digits+0x98>
    80001126:	fffff097          	auipc	ra,0xfffff
    8000112a:	422080e7          	jalr	1058(ra) # 80000548 <panic>
    panic("kvmpa");
    8000112e:	00007517          	auipc	a0,0x7
    80001132:	faa50513          	addi	a0,a0,-86 # 800080d8 <digits+0x98>
    80001136:	fffff097          	auipc	ra,0xfffff
    8000113a:	412080e7          	jalr	1042(ra) # 80000548 <panic>

000000008000113e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000113e:	715d                	addi	sp,sp,-80
    80001140:	e486                	sd	ra,72(sp)
    80001142:	e0a2                	sd	s0,64(sp)
    80001144:	fc26                	sd	s1,56(sp)
    80001146:	f84a                	sd	s2,48(sp)
    80001148:	f44e                	sd	s3,40(sp)
    8000114a:	f052                	sd	s4,32(sp)
    8000114c:	ec56                	sd	s5,24(sp)
    8000114e:	e85a                	sd	s6,16(sp)
    80001150:	e45e                	sd	s7,8(sp)
    80001152:	0880                	addi	s0,sp,80
    80001154:	8aaa                	mv	s5,a0
    80001156:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001158:	777d                	lui	a4,0xfffff
    8000115a:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000115e:	167d                	addi	a2,a2,-1
    80001160:	00b609b3          	add	s3,a2,a1
    80001164:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001168:	893e                	mv	s2,a5
    8000116a:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000116e:	6b85                	lui	s7,0x1
    80001170:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001174:	4605                	li	a2,1
    80001176:	85ca                	mv	a1,s2
    80001178:	8556                	mv	a0,s5
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	e7e080e7          	jalr	-386(ra) # 80000ff8 <walk>
    80001182:	c51d                	beqz	a0,800011b0 <mappages+0x72>
    if(*pte & PTE_V)
    80001184:	611c                	ld	a5,0(a0)
    80001186:	8b85                	andi	a5,a5,1
    80001188:	ef81                	bnez	a5,800011a0 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000118a:	80b1                	srli	s1,s1,0xc
    8000118c:	04aa                	slli	s1,s1,0xa
    8000118e:	0164e4b3          	or	s1,s1,s6
    80001192:	0014e493          	ori	s1,s1,1
    80001196:	e104                	sd	s1,0(a0)
    if(a == last)
    80001198:	03390863          	beq	s2,s3,800011c8 <mappages+0x8a>
    a += PGSIZE;
    8000119c:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000119e:	bfc9                	j	80001170 <mappages+0x32>
      panic("remap");
    800011a0:	00007517          	auipc	a0,0x7
    800011a4:	f4050513          	addi	a0,a0,-192 # 800080e0 <digits+0xa0>
    800011a8:	fffff097          	auipc	ra,0xfffff
    800011ac:	3a0080e7          	jalr	928(ra) # 80000548 <panic>
      return -1;
    800011b0:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011b2:	60a6                	ld	ra,72(sp)
    800011b4:	6406                	ld	s0,64(sp)
    800011b6:	74e2                	ld	s1,56(sp)
    800011b8:	7942                	ld	s2,48(sp)
    800011ba:	79a2                	ld	s3,40(sp)
    800011bc:	7a02                	ld	s4,32(sp)
    800011be:	6ae2                	ld	s5,24(sp)
    800011c0:	6b42                	ld	s6,16(sp)
    800011c2:	6ba2                	ld	s7,8(sp)
    800011c4:	6161                	addi	sp,sp,80
    800011c6:	8082                	ret
  return 0;
    800011c8:	4501                	li	a0,0
    800011ca:	b7e5                	j	800011b2 <mappages+0x74>

00000000800011cc <kvmmap>:
{
    800011cc:	1141                	addi	sp,sp,-16
    800011ce:	e406                	sd	ra,8(sp)
    800011d0:	e022                	sd	s0,0(sp)
    800011d2:	0800                	addi	s0,sp,16
    800011d4:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011d6:	86ae                	mv	a3,a1
    800011d8:	85aa                	mv	a1,a0
    800011da:	00008517          	auipc	a0,0x8
    800011de:	e3653503          	ld	a0,-458(a0) # 80009010 <kernel_pagetable>
    800011e2:	00000097          	auipc	ra,0x0
    800011e6:	f5c080e7          	jalr	-164(ra) # 8000113e <mappages>
    800011ea:	e509                	bnez	a0,800011f4 <kvmmap+0x28>
}
    800011ec:	60a2                	ld	ra,8(sp)
    800011ee:	6402                	ld	s0,0(sp)
    800011f0:	0141                	addi	sp,sp,16
    800011f2:	8082                	ret
    panic("kvmmap");
    800011f4:	00007517          	auipc	a0,0x7
    800011f8:	ef450513          	addi	a0,a0,-268 # 800080e8 <digits+0xa8>
    800011fc:	fffff097          	auipc	ra,0xfffff
    80001200:	34c080e7          	jalr	844(ra) # 80000548 <panic>

0000000080001204 <kvminit>:
{
    80001204:	1101                	addi	sp,sp,-32
    80001206:	ec06                	sd	ra,24(sp)
    80001208:	e822                	sd	s0,16(sp)
    8000120a:	e426                	sd	s1,8(sp)
    8000120c:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    8000120e:	00000097          	auipc	ra,0x0
    80001212:	912080e7          	jalr	-1774(ra) # 80000b20 <kalloc>
    80001216:	00008797          	auipc	a5,0x8
    8000121a:	dea7bd23          	sd	a0,-518(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    8000121e:	6605                	lui	a2,0x1
    80001220:	4581                	li	a1,0
    80001222:	00000097          	auipc	ra,0x0
    80001226:	aea080e7          	jalr	-1302(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000122a:	4699                	li	a3,6
    8000122c:	6605                	lui	a2,0x1
    8000122e:	100005b7          	lui	a1,0x10000
    80001232:	10000537          	lui	a0,0x10000
    80001236:	00000097          	auipc	ra,0x0
    8000123a:	f96080e7          	jalr	-106(ra) # 800011cc <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000123e:	4699                	li	a3,6
    80001240:	6605                	lui	a2,0x1
    80001242:	100015b7          	lui	a1,0x10001
    80001246:	10001537          	lui	a0,0x10001
    8000124a:	00000097          	auipc	ra,0x0
    8000124e:	f82080e7          	jalr	-126(ra) # 800011cc <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001252:	4699                	li	a3,6
    80001254:	6641                	lui	a2,0x10
    80001256:	020005b7          	lui	a1,0x2000
    8000125a:	02000537          	lui	a0,0x2000
    8000125e:	00000097          	auipc	ra,0x0
    80001262:	f6e080e7          	jalr	-146(ra) # 800011cc <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001266:	4699                	li	a3,6
    80001268:	00400637          	lui	a2,0x400
    8000126c:	0c0005b7          	lui	a1,0xc000
    80001270:	0c000537          	lui	a0,0xc000
    80001274:	00000097          	auipc	ra,0x0
    80001278:	f58080e7          	jalr	-168(ra) # 800011cc <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000127c:	00007497          	auipc	s1,0x7
    80001280:	d8448493          	addi	s1,s1,-636 # 80008000 <etext>
    80001284:	46a9                	li	a3,10
    80001286:	80007617          	auipc	a2,0x80007
    8000128a:	d7a60613          	addi	a2,a2,-646 # 8000 <_entry-0x7fff8000>
    8000128e:	4585                	li	a1,1
    80001290:	05fe                	slli	a1,a1,0x1f
    80001292:	852e                	mv	a0,a1
    80001294:	00000097          	auipc	ra,0x0
    80001298:	f38080e7          	jalr	-200(ra) # 800011cc <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000129c:	4699                	li	a3,6
    8000129e:	4645                	li	a2,17
    800012a0:	066e                	slli	a2,a2,0x1b
    800012a2:	8e05                	sub	a2,a2,s1
    800012a4:	85a6                	mv	a1,s1
    800012a6:	8526                	mv	a0,s1
    800012a8:	00000097          	auipc	ra,0x0
    800012ac:	f24080e7          	jalr	-220(ra) # 800011cc <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012b0:	46a9                	li	a3,10
    800012b2:	6605                	lui	a2,0x1
    800012b4:	00006597          	auipc	a1,0x6
    800012b8:	d4c58593          	addi	a1,a1,-692 # 80007000 <_trampoline>
    800012bc:	04000537          	lui	a0,0x4000
    800012c0:	157d                	addi	a0,a0,-1
    800012c2:	0532                	slli	a0,a0,0xc
    800012c4:	00000097          	auipc	ra,0x0
    800012c8:	f08080e7          	jalr	-248(ra) # 800011cc <kvmmap>
}
    800012cc:	60e2                	ld	ra,24(sp)
    800012ce:	6442                	ld	s0,16(sp)
    800012d0:	64a2                	ld	s1,8(sp)
    800012d2:	6105                	addi	sp,sp,32
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	7139                	addi	sp,sp,-64
    800012d8:	fc06                	sd	ra,56(sp)
    800012da:	f822                	sd	s0,48(sp)
    800012dc:	f426                	sd	s1,40(sp)
    800012de:	f04a                	sd	s2,32(sp)
    800012e0:	ec4e                	sd	s3,24(sp)
    800012e2:	e852                	sd	s4,16(sp)
    800012e4:	e456                	sd	s5,8(sp)
    800012e6:	e05a                	sd	s6,0(sp)
    800012e8:	0080                	addi	s0,sp,64
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ea:	03459793          	slli	a5,a1,0x34
    800012ee:	e785                	bnez	a5,80001316 <uvmunmap+0x40>
    800012f0:	8a2a                	mv	s4,a0
    800012f2:	892e                	mv	s2,a1
    800012f4:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f6:	0632                	slli	a2,a2,0xc
    800012f8:	00b609b3          	add	s3,a2,a1
    800012fc:	6b05                	lui	s6,0x1
    800012fe:	0735e063          	bltu	a1,s3,8000135e <uvmunmap+0x88>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001302:	70e2                	ld	ra,56(sp)
    80001304:	7442                	ld	s0,48(sp)
    80001306:	74a2                	ld	s1,40(sp)
    80001308:	7902                	ld	s2,32(sp)
    8000130a:	69e2                	ld	s3,24(sp)
    8000130c:	6a42                	ld	s4,16(sp)
    8000130e:	6aa2                	ld	s5,8(sp)
    80001310:	6b02                	ld	s6,0(sp)
    80001312:	6121                	addi	sp,sp,64
    80001314:	8082                	ret
    panic("uvmunmap: not aligned");
    80001316:	00007517          	auipc	a0,0x7
    8000131a:	dda50513          	addi	a0,a0,-550 # 800080f0 <digits+0xb0>
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	22a080e7          	jalr	554(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001326:	00007517          	auipc	a0,0x7
    8000132a:	de250513          	addi	a0,a0,-542 # 80008108 <digits+0xc8>
    8000132e:	fffff097          	auipc	ra,0xfffff
    80001332:	21a080e7          	jalr	538(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001336:	00007517          	auipc	a0,0x7
    8000133a:	de250513          	addi	a0,a0,-542 # 80008118 <digits+0xd8>
    8000133e:	fffff097          	auipc	ra,0xfffff
    80001342:	20a080e7          	jalr	522(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001346:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001348:	00c79513          	slli	a0,a5,0xc
    8000134c:	fffff097          	auipc	ra,0xfffff
    80001350:	6d8080e7          	jalr	1752(ra) # 80000a24 <kfree>
    *pte = 0;
    80001354:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001358:	995a                	add	s2,s2,s6
    8000135a:	fb3974e3          	bgeu	s2,s3,80001302 <uvmunmap+0x2c>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000135e:	4601                	li	a2,0
    80001360:	85ca                	mv	a1,s2
    80001362:	8552                	mv	a0,s4
    80001364:	00000097          	auipc	ra,0x0
    80001368:	c94080e7          	jalr	-876(ra) # 80000ff8 <walk>
    8000136c:	84aa                	mv	s1,a0
    8000136e:	dd45                	beqz	a0,80001326 <uvmunmap+0x50>
    if(PTE_FLAGS(*pte) == PTE_V || PTE_FLAGS(*pte) == 0) 
    80001370:	611c                	ld	a5,0(a0)
    80001372:	3fe7f713          	andi	a4,a5,1022
    80001376:	d361                	beqz	a4,80001336 <uvmunmap+0x60>
    if(do_free && (*pte & PTE_V)){
    80001378:	fc0a8ee3          	beqz	s5,80001354 <uvmunmap+0x7e>
    8000137c:	0017f713          	andi	a4,a5,1
    80001380:	db71                	beqz	a4,80001354 <uvmunmap+0x7e>
    80001382:	b7d1                	j	80001346 <uvmunmap+0x70>

0000000080001384 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001384:	1101                	addi	sp,sp,-32
    80001386:	ec06                	sd	ra,24(sp)
    80001388:	e822                	sd	s0,16(sp)
    8000138a:	e426                	sd	s1,8(sp)
    8000138c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000138e:	fffff097          	auipc	ra,0xfffff
    80001392:	792080e7          	jalr	1938(ra) # 80000b20 <kalloc>
    80001396:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001398:	c519                	beqz	a0,800013a6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000139a:	6605                	lui	a2,0x1
    8000139c:	4581                	li	a1,0
    8000139e:	00000097          	auipc	ra,0x0
    800013a2:	96e080e7          	jalr	-1682(ra) # 80000d0c <memset>
  return pagetable;
}
    800013a6:	8526                	mv	a0,s1
    800013a8:	60e2                	ld	ra,24(sp)
    800013aa:	6442                	ld	s0,16(sp)
    800013ac:	64a2                	ld	s1,8(sp)
    800013ae:	6105                	addi	sp,sp,32
    800013b0:	8082                	ret

00000000800013b2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013b2:	7179                	addi	sp,sp,-48
    800013b4:	f406                	sd	ra,40(sp)
    800013b6:	f022                	sd	s0,32(sp)
    800013b8:	ec26                	sd	s1,24(sp)
    800013ba:	e84a                	sd	s2,16(sp)
    800013bc:	e44e                	sd	s3,8(sp)
    800013be:	e052                	sd	s4,0(sp)
    800013c0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013c2:	6785                	lui	a5,0x1
    800013c4:	04f67863          	bgeu	a2,a5,80001414 <uvminit+0x62>
    800013c8:	8a2a                	mv	s4,a0
    800013ca:	89ae                	mv	s3,a1
    800013cc:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013ce:	fffff097          	auipc	ra,0xfffff
    800013d2:	752080e7          	jalr	1874(ra) # 80000b20 <kalloc>
    800013d6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013d8:	6605                	lui	a2,0x1
    800013da:	4581                	li	a1,0
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	930080e7          	jalr	-1744(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013e4:	4779                	li	a4,30
    800013e6:	86ca                	mv	a3,s2
    800013e8:	6605                	lui	a2,0x1
    800013ea:	4581                	li	a1,0
    800013ec:	8552                	mv	a0,s4
    800013ee:	00000097          	auipc	ra,0x0
    800013f2:	d50080e7          	jalr	-688(ra) # 8000113e <mappages>
  memmove(mem, src, sz);
    800013f6:	8626                	mv	a2,s1
    800013f8:	85ce                	mv	a1,s3
    800013fa:	854a                	mv	a0,s2
    800013fc:	00000097          	auipc	ra,0x0
    80001400:	970080e7          	jalr	-1680(ra) # 80000d6c <memmove>
}
    80001404:	70a2                	ld	ra,40(sp)
    80001406:	7402                	ld	s0,32(sp)
    80001408:	64e2                	ld	s1,24(sp)
    8000140a:	6942                	ld	s2,16(sp)
    8000140c:	69a2                	ld	s3,8(sp)
    8000140e:	6a02                	ld	s4,0(sp)
    80001410:	6145                	addi	sp,sp,48
    80001412:	8082                	ret
    panic("inituvm: more than a page");
    80001414:	00007517          	auipc	a0,0x7
    80001418:	d1c50513          	addi	a0,a0,-740 # 80008130 <digits+0xf0>
    8000141c:	fffff097          	auipc	ra,0xfffff
    80001420:	12c080e7          	jalr	300(ra) # 80000548 <panic>

0000000080001424 <lazymappages>:
  return newsz;
}

int
lazymappages(pagetable_t pagetable, uint64 va, uint64 size, int perm)
{
    80001424:	1101                	addi	sp,sp,-32
    80001426:	ec06                	sd	ra,24(sp)
    80001428:	e822                	sd	s0,16(sp)
    8000142a:	e426                	sd	s1,8(sp)
    8000142c:	1000                	addi	s0,sp,32
    8000142e:	84b6                	mv	s1,a3
  pte_t *pte;

  if((pte = walk(pagetable, va, 1)) == 0)
    80001430:	4605                	li	a2,1
    80001432:	00000097          	auipc	ra,0x0
    80001436:	bc6080e7          	jalr	-1082(ra) # 80000ff8 <walk>
    8000143a:	c11d                	beqz	a0,80001460 <lazymappages+0x3c>
    return -1;
  if(*pte & PTE_V)
    8000143c:	611c                	ld	a5,0(a0)
    8000143e:	8b85                	andi	a5,a5,1
    80001440:	eb81                	bnez	a5,80001450 <lazymappages+0x2c>
    panic("remap");
  *pte = (uint64)perm;
    80001442:	e104                	sd	s1,0(a0)
  return 0;
    80001444:	4501                	li	a0,0
}
    80001446:	60e2                	ld	ra,24(sp)
    80001448:	6442                	ld	s0,16(sp)
    8000144a:	64a2                	ld	s1,8(sp)
    8000144c:	6105                	addi	sp,sp,32
    8000144e:	8082                	ret
    panic("remap");
    80001450:	00007517          	auipc	a0,0x7
    80001454:	c9050513          	addi	a0,a0,-880 # 800080e0 <digits+0xa0>
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	0f0080e7          	jalr	240(ra) # 80000548 <panic>
    return -1;
    80001460:	557d                	li	a0,-1
    80001462:	b7d5                	j	80001446 <lazymappages+0x22>

0000000080001464 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001464:	1101                	addi	sp,sp,-32
    80001466:	ec06                	sd	ra,24(sp)
    80001468:	e822                	sd	s0,16(sp)
    8000146a:	e426                	sd	s1,8(sp)
    8000146c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000146e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001470:	00b67d63          	bgeu	a2,a1,8000148a <uvmdealloc+0x26>
    80001474:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001476:	6785                	lui	a5,0x1
    80001478:	17fd                	addi	a5,a5,-1
    8000147a:	00f60733          	add	a4,a2,a5
    8000147e:	767d                	lui	a2,0xfffff
    80001480:	8f71                	and	a4,a4,a2
    80001482:	97ae                	add	a5,a5,a1
    80001484:	8ff1                	and	a5,a5,a2
    80001486:	00f76863          	bltu	a4,a5,80001496 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000148a:	8526                	mv	a0,s1
    8000148c:	60e2                	ld	ra,24(sp)
    8000148e:	6442                	ld	s0,16(sp)
    80001490:	64a2                	ld	s1,8(sp)
    80001492:	6105                	addi	sp,sp,32
    80001494:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001496:	8f99                	sub	a5,a5,a4
    80001498:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000149a:	4685                	li	a3,1
    8000149c:	0007861b          	sext.w	a2,a5
    800014a0:	85ba                	mv	a1,a4
    800014a2:	00000097          	auipc	ra,0x0
    800014a6:	e34080e7          	jalr	-460(ra) # 800012d6 <uvmunmap>
    800014aa:	b7c5                	j	8000148a <uvmdealloc+0x26>

00000000800014ac <uvmalloc>:
  if(newsz < oldsz)
    800014ac:	0ab66163          	bltu	a2,a1,8000154e <uvmalloc+0xa2>
{
    800014b0:	7139                	addi	sp,sp,-64
    800014b2:	fc06                	sd	ra,56(sp)
    800014b4:	f822                	sd	s0,48(sp)
    800014b6:	f426                	sd	s1,40(sp)
    800014b8:	f04a                	sd	s2,32(sp)
    800014ba:	ec4e                	sd	s3,24(sp)
    800014bc:	e852                	sd	s4,16(sp)
    800014be:	e456                	sd	s5,8(sp)
    800014c0:	0080                	addi	s0,sp,64
    800014c2:	8aaa                	mv	s5,a0
    800014c4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014c6:	6985                	lui	s3,0x1
    800014c8:	19fd                	addi	s3,s3,-1
    800014ca:	95ce                	add	a1,a1,s3
    800014cc:	79fd                	lui	s3,0xfffff
    800014ce:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014d2:	08c9f063          	bgeu	s3,a2,80001552 <uvmalloc+0xa6>
    800014d6:	894e                	mv	s2,s3
    mem = kalloc();
    800014d8:	fffff097          	auipc	ra,0xfffff
    800014dc:	648080e7          	jalr	1608(ra) # 80000b20 <kalloc>
    800014e0:	84aa                	mv	s1,a0
    if(mem == 0){
    800014e2:	c51d                	beqz	a0,80001510 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014e4:	6605                	lui	a2,0x1
    800014e6:	4581                	li	a1,0
    800014e8:	00000097          	auipc	ra,0x0
    800014ec:	824080e7          	jalr	-2012(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014f0:	4779                	li	a4,30
    800014f2:	86a6                	mv	a3,s1
    800014f4:	6605                	lui	a2,0x1
    800014f6:	85ca                	mv	a1,s2
    800014f8:	8556                	mv	a0,s5
    800014fa:	00000097          	auipc	ra,0x0
    800014fe:	c44080e7          	jalr	-956(ra) # 8000113e <mappages>
    80001502:	e905                	bnez	a0,80001532 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001504:	6785                	lui	a5,0x1
    80001506:	993e                	add	s2,s2,a5
    80001508:	fd4968e3          	bltu	s2,s4,800014d8 <uvmalloc+0x2c>
  return newsz;
    8000150c:	8552                	mv	a0,s4
    8000150e:	a809                	j	80001520 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    80001510:	864e                	mv	a2,s3
    80001512:	85ca                	mv	a1,s2
    80001514:	8556                	mv	a0,s5
    80001516:	00000097          	auipc	ra,0x0
    8000151a:	f4e080e7          	jalr	-178(ra) # 80001464 <uvmdealloc>
      return 0;
    8000151e:	4501                	li	a0,0
}
    80001520:	70e2                	ld	ra,56(sp)
    80001522:	7442                	ld	s0,48(sp)
    80001524:	74a2                	ld	s1,40(sp)
    80001526:	7902                	ld	s2,32(sp)
    80001528:	69e2                	ld	s3,24(sp)
    8000152a:	6a42                	ld	s4,16(sp)
    8000152c:	6aa2                	ld	s5,8(sp)
    8000152e:	6121                	addi	sp,sp,64
    80001530:	8082                	ret
      kfree(mem);
    80001532:	8526                	mv	a0,s1
    80001534:	fffff097          	auipc	ra,0xfffff
    80001538:	4f0080e7          	jalr	1264(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000153c:	864e                	mv	a2,s3
    8000153e:	85ca                	mv	a1,s2
    80001540:	8556                	mv	a0,s5
    80001542:	00000097          	auipc	ra,0x0
    80001546:	f22080e7          	jalr	-222(ra) # 80001464 <uvmdealloc>
      return 0;
    8000154a:	4501                	li	a0,0
    8000154c:	bfd1                	j	80001520 <uvmalloc+0x74>
    return oldsz;
    8000154e:	852e                	mv	a0,a1
}
    80001550:	8082                	ret
  return newsz;
    80001552:	8532                	mv	a0,a2
    80001554:	b7f1                	j	80001520 <uvmalloc+0x74>

0000000080001556 <lazyalloc>:
  if(newsz < oldsz)
    80001556:	06b66463          	bltu	a2,a1,800015be <lazyalloc+0x68>
{
    8000155a:	7179                	addi	sp,sp,-48
    8000155c:	f406                	sd	ra,40(sp)
    8000155e:	f022                	sd	s0,32(sp)
    80001560:	ec26                	sd	s1,24(sp)
    80001562:	e84a                	sd	s2,16(sp)
    80001564:	e44e                	sd	s3,8(sp)
    80001566:	e052                	sd	s4,0(sp)
    80001568:	1800                	addi	s0,sp,48
    8000156a:	8a2a                	mv	s4,a0
    8000156c:	89b2                	mv	s3,a2
  oldsz = PGROUNDUP(oldsz);
    8000156e:	6905                	lui	s2,0x1
    80001570:	197d                	addi	s2,s2,-1
    80001572:	95ca                	add	a1,a1,s2
    80001574:	797d                	lui	s2,0xfffff
    80001576:	0125f933          	and	s2,a1,s2
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000157a:	04c97463          	bgeu	s2,a2,800015c2 <lazyalloc+0x6c>
    8000157e:	84ca                	mv	s1,s2
    if(lazymappages(pagetable, a, PGSIZE, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001580:	46f9                	li	a3,30
    80001582:	6605                	lui	a2,0x1
    80001584:	85a6                	mv	a1,s1
    80001586:	8552                	mv	a0,s4
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	e9c080e7          	jalr	-356(ra) # 80001424 <lazymappages>
    80001590:	e519                	bnez	a0,8000159e <lazyalloc+0x48>
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001592:	6785                	lui	a5,0x1
    80001594:	94be                	add	s1,s1,a5
    80001596:	ff34e5e3          	bltu	s1,s3,80001580 <lazyalloc+0x2a>
  return newsz;
    8000159a:	854e                	mv	a0,s3
    8000159c:	a809                	j	800015ae <lazyalloc+0x58>
      uvmdealloc(pagetable, a, oldsz);
    8000159e:	864a                	mv	a2,s2
    800015a0:	85a6                	mv	a1,s1
    800015a2:	8552                	mv	a0,s4
    800015a4:	00000097          	auipc	ra,0x0
    800015a8:	ec0080e7          	jalr	-320(ra) # 80001464 <uvmdealloc>
      return 0;
    800015ac:	4501                	li	a0,0
}
    800015ae:	70a2                	ld	ra,40(sp)
    800015b0:	7402                	ld	s0,32(sp)
    800015b2:	64e2                	ld	s1,24(sp)
    800015b4:	6942                	ld	s2,16(sp)
    800015b6:	69a2                	ld	s3,8(sp)
    800015b8:	6a02                	ld	s4,0(sp)
    800015ba:	6145                	addi	sp,sp,48
    800015bc:	8082                	ret
    return oldsz;
    800015be:	852e                	mv	a0,a1
}
    800015c0:	8082                	ret
  return newsz;
    800015c2:	8532                	mv	a0,a2
    800015c4:	b7ed                	j	800015ae <lazyalloc+0x58>

00000000800015c6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015c6:	7179                	addi	sp,sp,-48
    800015c8:	f406                	sd	ra,40(sp)
    800015ca:	f022                	sd	s0,32(sp)
    800015cc:	ec26                	sd	s1,24(sp)
    800015ce:	e84a                	sd	s2,16(sp)
    800015d0:	e44e                	sd	s3,8(sp)
    800015d2:	e052                	sd	s4,0(sp)
    800015d4:	1800                	addi	s0,sp,48
    800015d6:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015d8:	84aa                	mv	s1,a0
    800015da:	6905                	lui	s2,0x1
    800015dc:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015de:	4985                	li	s3,1
    800015e0:	a821                	j	800015f8 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015e2:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015e4:	0532                	slli	a0,a0,0xc
    800015e6:	00000097          	auipc	ra,0x0
    800015ea:	fe0080e7          	jalr	-32(ra) # 800015c6 <freewalk>
      pagetable[i] = 0;
    800015ee:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015f2:	04a1                	addi	s1,s1,8
    800015f4:	03248163          	beq	s1,s2,80001616 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015f8:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015fa:	00f57793          	andi	a5,a0,15
    800015fe:	ff3782e3          	beq	a5,s3,800015e2 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001602:	8905                	andi	a0,a0,1
    80001604:	d57d                	beqz	a0,800015f2 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001606:	00007517          	auipc	a0,0x7
    8000160a:	b4a50513          	addi	a0,a0,-1206 # 80008150 <digits+0x110>
    8000160e:	fffff097          	auipc	ra,0xfffff
    80001612:	f3a080e7          	jalr	-198(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    80001616:	8552                	mv	a0,s4
    80001618:	fffff097          	auipc	ra,0xfffff
    8000161c:	40c080e7          	jalr	1036(ra) # 80000a24 <kfree>
}
    80001620:	70a2                	ld	ra,40(sp)
    80001622:	7402                	ld	s0,32(sp)
    80001624:	64e2                	ld	s1,24(sp)
    80001626:	6942                	ld	s2,16(sp)
    80001628:	69a2                	ld	s3,8(sp)
    8000162a:	6a02                	ld	s4,0(sp)
    8000162c:	6145                	addi	sp,sp,48
    8000162e:	8082                	ret

0000000080001630 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001630:	1101                	addi	sp,sp,-32
    80001632:	ec06                	sd	ra,24(sp)
    80001634:	e822                	sd	s0,16(sp)
    80001636:	e426                	sd	s1,8(sp)
    80001638:	1000                	addi	s0,sp,32
    8000163a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000163c:	e999                	bnez	a1,80001652 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000163e:	8526                	mv	a0,s1
    80001640:	00000097          	auipc	ra,0x0
    80001644:	f86080e7          	jalr	-122(ra) # 800015c6 <freewalk>
}
    80001648:	60e2                	ld	ra,24(sp)
    8000164a:	6442                	ld	s0,16(sp)
    8000164c:	64a2                	ld	s1,8(sp)
    8000164e:	6105                	addi	sp,sp,32
    80001650:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001652:	6605                	lui	a2,0x1
    80001654:	167d                	addi	a2,a2,-1
    80001656:	962e                	add	a2,a2,a1
    80001658:	4685                	li	a3,1
    8000165a:	8231                	srli	a2,a2,0xc
    8000165c:	4581                	li	a1,0
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	c78080e7          	jalr	-904(ra) # 800012d6 <uvmunmap>
    80001666:	bfe1                	j	8000163e <uvmfree+0xe>

0000000080001668 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001668:	ce61                	beqz	a2,80001740 <uvmcopy+0xd8>
{
    8000166a:	715d                	addi	sp,sp,-80
    8000166c:	e486                	sd	ra,72(sp)
    8000166e:	e0a2                	sd	s0,64(sp)
    80001670:	fc26                	sd	s1,56(sp)
    80001672:	f84a                	sd	s2,48(sp)
    80001674:	f44e                	sd	s3,40(sp)
    80001676:	f052                	sd	s4,32(sp)
    80001678:	ec56                	sd	s5,24(sp)
    8000167a:	e85a                	sd	s6,16(sp)
    8000167c:	e45e                	sd	s7,8(sp)
    8000167e:	0880                	addi	s0,sp,80
    80001680:	8b2a                	mv	s6,a0
    80001682:	8aae                	mv	s5,a1
    80001684:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001686:	4481                	li	s1,0
    80001688:	a889                	j	800016da <uvmcopy+0x72>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    8000168a:	00007517          	auipc	a0,0x7
    8000168e:	ad650513          	addi	a0,a0,-1322 # 80008160 <digits+0x120>
    80001692:	fffff097          	auipc	ra,0xfffff
    80001696:	eb6080e7          	jalr	-330(ra) # 80000548 <panic>
      if (lazymappages(new, i, PGSIZE, flags) != 0)
        goto err;
    }
    else
    {
      pa = PTE2PA(*pte);
    8000169a:	00a6d593          	srli	a1,a3,0xa
    8000169e:	00c59b93          	slli	s7,a1,0xc
      flags = PTE_FLAGS(*pte);
    800016a2:	3ff6f913          	andi	s2,a3,1023
      if((mem = kalloc()) == 0)
    800016a6:	fffff097          	auipc	ra,0xfffff
    800016aa:	47a080e7          	jalr	1146(ra) # 80000b20 <kalloc>
    800016ae:	89aa                	mv	s3,a0
    800016b0:	c939                	beqz	a0,80001706 <uvmcopy+0x9e>
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    800016b2:	6605                	lui	a2,0x1
    800016b4:	85de                	mv	a1,s7
    800016b6:	fffff097          	auipc	ra,0xfffff
    800016ba:	6b6080e7          	jalr	1718(ra) # 80000d6c <memmove>
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0)
    800016be:	874a                	mv	a4,s2
    800016c0:	86ce                	mv	a3,s3
    800016c2:	6605                	lui	a2,0x1
    800016c4:	85a6                	mv	a1,s1
    800016c6:	8556                	mv	a0,s5
    800016c8:	00000097          	auipc	ra,0x0
    800016cc:	a76080e7          	jalr	-1418(ra) # 8000113e <mappages>
    800016d0:	e125                	bnez	a0,80001730 <uvmcopy+0xc8>
  for(i = 0; i < sz; i += PGSIZE){
    800016d2:	6785                	lui	a5,0x1
    800016d4:	94be                	add	s1,s1,a5
    800016d6:	0744f363          	bgeu	s1,s4,8000173c <uvmcopy+0xd4>
    if((pte = walk(old, i, 0)) == 0)
    800016da:	4601                	li	a2,0
    800016dc:	85a6                	mv	a1,s1
    800016de:	855a                	mv	a0,s6
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	918080e7          	jalr	-1768(ra) # 80000ff8 <walk>
    800016e8:	d14d                	beqz	a0,8000168a <uvmcopy+0x22>
    if((*pte & PTE_V) == 0)
    800016ea:	6114                	ld	a3,0(a0)
    800016ec:	0016f793          	andi	a5,a3,1
    800016f0:	f7cd                	bnez	a5,8000169a <uvmcopy+0x32>
      if (lazymappages(new, i, PGSIZE, flags) != 0)
    800016f2:	3ff6f693          	andi	a3,a3,1023
    800016f6:	6605                	lui	a2,0x1
    800016f8:	85a6                	mv	a1,s1
    800016fa:	8556                	mv	a0,s5
    800016fc:	00000097          	auipc	ra,0x0
    80001700:	d28080e7          	jalr	-728(ra) # 80001424 <lazymappages>
    80001704:	d579                	beqz	a0,800016d2 <uvmcopy+0x6a>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001706:	4685                	li	a3,1
    80001708:	00c4d613          	srli	a2,s1,0xc
    8000170c:	4581                	li	a1,0
    8000170e:	8556                	mv	a0,s5
    80001710:	00000097          	auipc	ra,0x0
    80001714:	bc6080e7          	jalr	-1082(ra) # 800012d6 <uvmunmap>
  return -1;
    80001718:	557d                	li	a0,-1
}
    8000171a:	60a6                	ld	ra,72(sp)
    8000171c:	6406                	ld	s0,64(sp)
    8000171e:	74e2                	ld	s1,56(sp)
    80001720:	7942                	ld	s2,48(sp)
    80001722:	79a2                	ld	s3,40(sp)
    80001724:	7a02                	ld	s4,32(sp)
    80001726:	6ae2                	ld	s5,24(sp)
    80001728:	6b42                	ld	s6,16(sp)
    8000172a:	6ba2                	ld	s7,8(sp)
    8000172c:	6161                	addi	sp,sp,80
    8000172e:	8082                	ret
        kfree(mem);
    80001730:	854e                	mv	a0,s3
    80001732:	fffff097          	auipc	ra,0xfffff
    80001736:	2f2080e7          	jalr	754(ra) # 80000a24 <kfree>
        goto err;
    8000173a:	b7f1                	j	80001706 <uvmcopy+0x9e>
  return 0;
    8000173c:	4501                	li	a0,0
    8000173e:	bff1                	j	8000171a <uvmcopy+0xb2>
    80001740:	4501                	li	a0,0
}
    80001742:	8082                	ret

0000000080001744 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001744:	1141                	addi	sp,sp,-16
    80001746:	e406                	sd	ra,8(sp)
    80001748:	e022                	sd	s0,0(sp)
    8000174a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000174c:	4601                	li	a2,0
    8000174e:	00000097          	auipc	ra,0x0
    80001752:	8aa080e7          	jalr	-1878(ra) # 80000ff8 <walk>
  if(pte == 0)
    80001756:	c901                	beqz	a0,80001766 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001758:	611c                	ld	a5,0(a0)
    8000175a:	9bbd                	andi	a5,a5,-17
    8000175c:	e11c                	sd	a5,0(a0)
}
    8000175e:	60a2                	ld	ra,8(sp)
    80001760:	6402                	ld	s0,0(sp)
    80001762:	0141                	addi	sp,sp,16
    80001764:	8082                	ret
    panic("uvmclear");
    80001766:	00007517          	auipc	a0,0x7
    8000176a:	a1a50513          	addi	a0,a0,-1510 # 80008180 <digits+0x140>
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	dda080e7          	jalr	-550(ra) # 80000548 <panic>

0000000080001776 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001776:	c6c5                	beqz	a3,8000181e <copyinstr+0xa8>
{
    80001778:	715d                	addi	sp,sp,-80
    8000177a:	e486                	sd	ra,72(sp)
    8000177c:	e0a2                	sd	s0,64(sp)
    8000177e:	fc26                	sd	s1,56(sp)
    80001780:	f84a                	sd	s2,48(sp)
    80001782:	f44e                	sd	s3,40(sp)
    80001784:	f052                	sd	s4,32(sp)
    80001786:	ec56                	sd	s5,24(sp)
    80001788:	e85a                	sd	s6,16(sp)
    8000178a:	e45e                	sd	s7,8(sp)
    8000178c:	0880                	addi	s0,sp,80
    8000178e:	8a2a                	mv	s4,a0
    80001790:	8b2e                	mv	s6,a1
    80001792:	8bb2                	mv	s7,a2
    80001794:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001796:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001798:	6985                	lui	s3,0x1
    8000179a:	a035                	j	800017c6 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    8000179c:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017a0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017a2:	0017b793          	seqz	a5,a5
    800017a6:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017aa:	60a6                	ld	ra,72(sp)
    800017ac:	6406                	ld	s0,64(sp)
    800017ae:	74e2                	ld	s1,56(sp)
    800017b0:	7942                	ld	s2,48(sp)
    800017b2:	79a2                	ld	s3,40(sp)
    800017b4:	7a02                	ld	s4,32(sp)
    800017b6:	6ae2                	ld	s5,24(sp)
    800017b8:	6b42                	ld	s6,16(sp)
    800017ba:	6ba2                	ld	s7,8(sp)
    800017bc:	6161                	addi	sp,sp,80
    800017be:	8082                	ret
    srcva = va0 + PGSIZE;
    800017c0:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017c4:	c8a9                	beqz	s1,80001816 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800017c6:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017ca:	85ca                	mv	a1,s2
    800017cc:	8552                	mv	a0,s4
    800017ce:	00000097          	auipc	ra,0x0
    800017d2:	8d0080e7          	jalr	-1840(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800017d6:	c131                	beqz	a0,8000181a <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800017d8:	41790833          	sub	a6,s2,s7
    800017dc:	984e                	add	a6,a6,s3
    if(n > max)
    800017de:	0104f363          	bgeu	s1,a6,800017e4 <copyinstr+0x6e>
    800017e2:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017e4:	955e                	add	a0,a0,s7
    800017e6:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017ea:	fc080be3          	beqz	a6,800017c0 <copyinstr+0x4a>
    800017ee:	985a                	add	a6,a6,s6
    800017f0:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017f2:	41650633          	sub	a2,a0,s6
    800017f6:	14fd                	addi	s1,s1,-1
    800017f8:	9b26                	add	s6,s6,s1
    800017fa:	00f60733          	add	a4,a2,a5
    800017fe:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001802:	df49                	beqz	a4,8000179c <copyinstr+0x26>
        *dst = *p;
    80001804:	00e78023          	sb	a4,0(a5)
      --max;
    80001808:	40fb04b3          	sub	s1,s6,a5
      dst++;
    8000180c:	0785                	addi	a5,a5,1
    while(n > 0){
    8000180e:	ff0796e3          	bne	a5,a6,800017fa <copyinstr+0x84>
      dst++;
    80001812:	8b42                	mv	s6,a6
    80001814:	b775                	j	800017c0 <copyinstr+0x4a>
    80001816:	4781                	li	a5,0
    80001818:	b769                	j	800017a2 <copyinstr+0x2c>
      return -1;
    8000181a:	557d                	li	a0,-1
    8000181c:	b779                	j	800017aa <copyinstr+0x34>
  int got_null = 0;
    8000181e:	4781                	li	a5,0
  if(got_null){
    80001820:	0017b793          	seqz	a5,a5
    80001824:	40f00533          	neg	a0,a5
}
    80001828:	8082                	ret

000000008000182a <pagefault_handler>:
pagefault_handler(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  char *pa;

  if(va >= MAXVA)
    8000182a:	57fd                	li	a5,-1
    8000182c:	83e9                	srli	a5,a5,0x1a
    8000182e:	06b7e163          	bltu	a5,a1,80001890 <pagefault_handler+0x66>
{
    80001832:	1101                	addi	sp,sp,-32
    80001834:	ec06                	sd	ra,24(sp)
    80001836:	e822                	sd	s0,16(sp)
    80001838:	e426                	sd	s1,8(sp)
    8000183a:	e04a                	sd	s2,0(sp)
    8000183c:	1000                	addi	s0,sp,32
    return -1;
  if ((pte = walk(pagetable, va, 0)) == 0)
    8000183e:	4601                	li	a2,0
    80001840:	fffff097          	auipc	ra,0xfffff
    80001844:	7b8080e7          	jalr	1976(ra) # 80000ff8 <walk>
    80001848:	892a                	mv	s2,a0
    8000184a:	c529                	beqz	a0,80001894 <pagefault_handler+0x6a>
    return -1;
  if ((*pte & PTE_U) == 0)
    8000184c:	611c                	ld	a5,0(a0)
    8000184e:	8bc1                	andi	a5,a5,16
    return -1;
    80001850:	557d                	li	a0,-1
  if ((*pte & PTE_U) == 0)
    80001852:	cb8d                	beqz	a5,80001884 <pagefault_handler+0x5a>
  pa = kalloc();
    80001854:	fffff097          	auipc	ra,0xfffff
    80001858:	2cc080e7          	jalr	716(ra) # 80000b20 <kalloc>
    8000185c:	84aa                	mv	s1,a0
  if (pa == 0)
    8000185e:	cd0d                	beqz	a0,80001898 <pagefault_handler+0x6e>
    return -1;
  memset(pa, 0, PGSIZE);
    80001860:	6605                	lui	a2,0x1
    80001862:	4581                	li	a1,0
    80001864:	fffff097          	auipc	ra,0xfffff
    80001868:	4a8080e7          	jalr	1192(ra) # 80000d0c <memset>
  *pte = PA2PTE(pa) | PTE_FLAGS(*pte) | PTE_V;
    8000186c:	80b1                	srli	s1,s1,0xc
    8000186e:	04aa                	slli	s1,s1,0xa
    80001870:	00093783          	ld	a5,0(s2) # 1000 <_entry-0x7ffff000>
    80001874:	3ff7f793          	andi	a5,a5,1023
    80001878:	8cdd                	or	s1,s1,a5
    8000187a:	0014e493          	ori	s1,s1,1
    8000187e:	00993023          	sd	s1,0(s2)
  return 0;
    80001882:	4501                	li	a0,0
    80001884:	60e2                	ld	ra,24(sp)
    80001886:	6442                	ld	s0,16(sp)
    80001888:	64a2                	ld	s1,8(sp)
    8000188a:	6902                	ld	s2,0(sp)
    8000188c:	6105                	addi	sp,sp,32
    8000188e:	8082                	ret
    return -1;
    80001890:	557d                	li	a0,-1
    80001892:	8082                	ret
    return -1;
    80001894:	557d                	li	a0,-1
    80001896:	b7fd                	j	80001884 <pagefault_handler+0x5a>
    return -1;
    80001898:	557d                	li	a0,-1
    8000189a:	b7ed                	j	80001884 <pagefault_handler+0x5a>

000000008000189c <copyout>:
  while(len > 0){
    8000189c:	ced9                	beqz	a3,8000193a <copyout+0x9e>
{
    8000189e:	715d                	addi	sp,sp,-80
    800018a0:	e486                	sd	ra,72(sp)
    800018a2:	e0a2                	sd	s0,64(sp)
    800018a4:	fc26                	sd	s1,56(sp)
    800018a6:	f84a                	sd	s2,48(sp)
    800018a8:	f44e                	sd	s3,40(sp)
    800018aa:	f052                	sd	s4,32(sp)
    800018ac:	ec56                	sd	s5,24(sp)
    800018ae:	e85a                	sd	s6,16(sp)
    800018b0:	e45e                	sd	s7,8(sp)
    800018b2:	e062                	sd	s8,0(sp)
    800018b4:	0880                	addi	s0,sp,80
    800018b6:	8b2a                	mv	s6,a0
    800018b8:	892e                	mv	s2,a1
    800018ba:	8ab2                	mv	s5,a2
    800018bc:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    800018be:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (dstva - va0);
    800018c0:	6b85                	lui	s7,0x1
    800018c2:	a805                	j	800018f2 <copyout+0x56>
    800018c4:	412984b3          	sub	s1,s3,s2
    800018c8:	94de                	add	s1,s1,s7
    if(n > len)
    800018ca:	009a7363          	bgeu	s4,s1,800018d0 <copyout+0x34>
    800018ce:	84d2                	mv	s1,s4
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800018d0:	41390933          	sub	s2,s2,s3
    800018d4:	0004861b          	sext.w	a2,s1
    800018d8:	85d6                	mv	a1,s5
    800018da:	954a                	add	a0,a0,s2
    800018dc:	fffff097          	auipc	ra,0xfffff
    800018e0:	490080e7          	jalr	1168(ra) # 80000d6c <memmove>
    len -= n;
    800018e4:	409a0a33          	sub	s4,s4,s1
    src += n;
    800018e8:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    800018ea:	01798933          	add	s2,s3,s7
  while(len > 0){
    800018ee:	020a0963          	beqz	s4,80001920 <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    800018f2:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    800018f6:	85ce                	mv	a1,s3
    800018f8:	855a                	mv	a0,s6
    800018fa:	fffff097          	auipc	ra,0xfffff
    800018fe:	7a4080e7          	jalr	1956(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    80001902:	f169                	bnez	a0,800018c4 <copyout+0x28>
      if (pagefault_handler(pagetable, va0) != 0)
    80001904:	85ce                	mv	a1,s3
    80001906:	855a                	mv	a0,s6
    80001908:	00000097          	auipc	ra,0x0
    8000190c:	f22080e7          	jalr	-222(ra) # 8000182a <pagefault_handler>
    80001910:	e51d                	bnez	a0,8000193e <copyout+0xa2>
      pa0 = walkaddr(pagetable, va0);
    80001912:	85ce                	mv	a1,s3
    80001914:	855a                	mv	a0,s6
    80001916:	fffff097          	auipc	ra,0xfffff
    8000191a:	788080e7          	jalr	1928(ra) # 8000109e <walkaddr>
    8000191e:	b75d                	j	800018c4 <copyout+0x28>
  return 0;
    80001920:	4501                	li	a0,0
}
    80001922:	60a6                	ld	ra,72(sp)
    80001924:	6406                	ld	s0,64(sp)
    80001926:	74e2                	ld	s1,56(sp)
    80001928:	7942                	ld	s2,48(sp)
    8000192a:	79a2                	ld	s3,40(sp)
    8000192c:	7a02                	ld	s4,32(sp)
    8000192e:	6ae2                	ld	s5,24(sp)
    80001930:	6b42                	ld	s6,16(sp)
    80001932:	6ba2                	ld	s7,8(sp)
    80001934:	6c02                	ld	s8,0(sp)
    80001936:	6161                	addi	sp,sp,80
    80001938:	8082                	ret
  return 0;
    8000193a:	4501                	li	a0,0
}
    8000193c:	8082                	ret
        return -1;
    8000193e:	557d                	li	a0,-1
    80001940:	b7cd                	j	80001922 <copyout+0x86>

0000000080001942 <copyin>:
  while(len > 0){
    80001942:	ced9                	beqz	a3,800019e0 <copyin+0x9e>
{
    80001944:	715d                	addi	sp,sp,-80
    80001946:	e486                	sd	ra,72(sp)
    80001948:	e0a2                	sd	s0,64(sp)
    8000194a:	fc26                	sd	s1,56(sp)
    8000194c:	f84a                	sd	s2,48(sp)
    8000194e:	f44e                	sd	s3,40(sp)
    80001950:	f052                	sd	s4,32(sp)
    80001952:	ec56                	sd	s5,24(sp)
    80001954:	e85a                	sd	s6,16(sp)
    80001956:	e45e                	sd	s7,8(sp)
    80001958:	e062                	sd	s8,0(sp)
    8000195a:	0880                	addi	s0,sp,80
    8000195c:	8b2a                	mv	s6,a0
    8000195e:	8aae                	mv	s5,a1
    80001960:	8932                	mv	s2,a2
    80001962:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001964:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001966:	6b85                	lui	s7,0x1
    80001968:	a805                	j	80001998 <copyin+0x56>
    8000196a:	412984b3          	sub	s1,s3,s2
    8000196e:	94de                	add	s1,s1,s7
    if(n > len)
    80001970:	009a7363          	bgeu	s4,s1,80001976 <copyin+0x34>
    80001974:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001976:	413905b3          	sub	a1,s2,s3
    8000197a:	0004861b          	sext.w	a2,s1
    8000197e:	95aa                	add	a1,a1,a0
    80001980:	8556                	mv	a0,s5
    80001982:	fffff097          	auipc	ra,0xfffff
    80001986:	3ea080e7          	jalr	1002(ra) # 80000d6c <memmove>
    len -= n;
    8000198a:	409a0a33          	sub	s4,s4,s1
    dst += n;
    8000198e:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001990:	01798933          	add	s2,s3,s7
  while(len > 0){
    80001994:	020a0963          	beqz	s4,800019c6 <copyin+0x84>
    va0 = PGROUNDDOWN(srcva);
    80001998:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    8000199c:	85ce                	mv	a1,s3
    8000199e:	855a                	mv	a0,s6
    800019a0:	fffff097          	auipc	ra,0xfffff
    800019a4:	6fe080e7          	jalr	1790(ra) # 8000109e <walkaddr>
    if(pa0 == 0)
    800019a8:	f169                	bnez	a0,8000196a <copyin+0x28>
      if (pagefault_handler(pagetable, va0) != 0)
    800019aa:	85ce                	mv	a1,s3
    800019ac:	855a                	mv	a0,s6
    800019ae:	00000097          	auipc	ra,0x0
    800019b2:	e7c080e7          	jalr	-388(ra) # 8000182a <pagefault_handler>
    800019b6:	e51d                	bnez	a0,800019e4 <copyin+0xa2>
      pa0 = walkaddr(pagetable, va0);
    800019b8:	85ce                	mv	a1,s3
    800019ba:	855a                	mv	a0,s6
    800019bc:	fffff097          	auipc	ra,0xfffff
    800019c0:	6e2080e7          	jalr	1762(ra) # 8000109e <walkaddr>
    800019c4:	b75d                	j	8000196a <copyin+0x28>
  return 0;
    800019c6:	4501                	li	a0,0
}
    800019c8:	60a6                	ld	ra,72(sp)
    800019ca:	6406                	ld	s0,64(sp)
    800019cc:	74e2                	ld	s1,56(sp)
    800019ce:	7942                	ld	s2,48(sp)
    800019d0:	79a2                	ld	s3,40(sp)
    800019d2:	7a02                	ld	s4,32(sp)
    800019d4:	6ae2                	ld	s5,24(sp)
    800019d6:	6b42                	ld	s6,16(sp)
    800019d8:	6ba2                	ld	s7,8(sp)
    800019da:	6c02                	ld	s8,0(sp)
    800019dc:	6161                	addi	sp,sp,80
    800019de:	8082                	ret
  return 0;
    800019e0:	4501                	li	a0,0
}
    800019e2:	8082                	ret
        return -1;
    800019e4:	557d                	li	a0,-1
    800019e6:	b7cd                	j	800019c8 <copyin+0x86>

00000000800019e8 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800019e8:	1101                	addi	sp,sp,-32
    800019ea:	ec06                	sd	ra,24(sp)
    800019ec:	e822                	sd	s0,16(sp)
    800019ee:	e426                	sd	s1,8(sp)
    800019f0:	1000                	addi	s0,sp,32
    800019f2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	1a2080e7          	jalr	418(ra) # 80000b96 <holding>
    800019fc:	c909                	beqz	a0,80001a0e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800019fe:	749c                	ld	a5,40(s1)
    80001a00:	00978f63          	beq	a5,s1,80001a1e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001a04:	60e2                	ld	ra,24(sp)
    80001a06:	6442                	ld	s0,16(sp)
    80001a08:	64a2                	ld	s1,8(sp)
    80001a0a:	6105                	addi	sp,sp,32
    80001a0c:	8082                	ret
    panic("wakeup1");
    80001a0e:	00006517          	auipc	a0,0x6
    80001a12:	78250513          	addi	a0,a0,1922 # 80008190 <digits+0x150>
    80001a16:	fffff097          	auipc	ra,0xfffff
    80001a1a:	b32080e7          	jalr	-1230(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001a1e:	4c98                	lw	a4,24(s1)
    80001a20:	4785                	li	a5,1
    80001a22:	fef711e3          	bne	a4,a5,80001a04 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001a26:	4789                	li	a5,2
    80001a28:	cc9c                	sw	a5,24(s1)
}
    80001a2a:	bfe9                	j	80001a04 <wakeup1+0x1c>

0000000080001a2c <procinit>:
{
    80001a2c:	715d                	addi	sp,sp,-80
    80001a2e:	e486                	sd	ra,72(sp)
    80001a30:	e0a2                	sd	s0,64(sp)
    80001a32:	fc26                	sd	s1,56(sp)
    80001a34:	f84a                	sd	s2,48(sp)
    80001a36:	f44e                	sd	s3,40(sp)
    80001a38:	f052                	sd	s4,32(sp)
    80001a3a:	ec56                	sd	s5,24(sp)
    80001a3c:	e85a                	sd	s6,16(sp)
    80001a3e:	e45e                	sd	s7,8(sp)
    80001a40:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001a42:	00006597          	auipc	a1,0x6
    80001a46:	75658593          	addi	a1,a1,1878 # 80008198 <digits+0x158>
    80001a4a:	00010517          	auipc	a0,0x10
    80001a4e:	f0650513          	addi	a0,a0,-250 # 80011950 <pid_lock>
    80001a52:	fffff097          	auipc	ra,0xfffff
    80001a56:	12e080e7          	jalr	302(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a5a:	00010917          	auipc	s2,0x10
    80001a5e:	30e90913          	addi	s2,s2,782 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001a62:	00006b97          	auipc	s7,0x6
    80001a66:	73eb8b93          	addi	s7,s7,1854 # 800081a0 <digits+0x160>
      uint64 va = KSTACK((int) (p - proc));
    80001a6a:	8b4a                	mv	s6,s2
    80001a6c:	00006a97          	auipc	s5,0x6
    80001a70:	594a8a93          	addi	s5,s5,1428 # 80008000 <etext>
    80001a74:	040009b7          	lui	s3,0x4000
    80001a78:	19fd                	addi	s3,s3,-1
    80001a7a:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001a7c:	00016a17          	auipc	s4,0x16
    80001a80:	ceca0a13          	addi	s4,s4,-788 # 80017768 <tickslock>
      initlock(&p->lock, "proc");
    80001a84:	85de                	mv	a1,s7
    80001a86:	854a                	mv	a0,s2
    80001a88:	fffff097          	auipc	ra,0xfffff
    80001a8c:	0f8080e7          	jalr	248(ra) # 80000b80 <initlock>
      char *pa = kalloc();
    80001a90:	fffff097          	auipc	ra,0xfffff
    80001a94:	090080e7          	jalr	144(ra) # 80000b20 <kalloc>
    80001a98:	85aa                	mv	a1,a0
      if(pa == 0)
    80001a9a:	c929                	beqz	a0,80001aec <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001a9c:	416904b3          	sub	s1,s2,s6
    80001aa0:	848d                	srai	s1,s1,0x3
    80001aa2:	000ab783          	ld	a5,0(s5)
    80001aa6:	02f484b3          	mul	s1,s1,a5
    80001aaa:	2485                	addiw	s1,s1,1
    80001aac:	00d4949b          	slliw	s1,s1,0xd
    80001ab0:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ab4:	4699                	li	a3,6
    80001ab6:	6605                	lui	a2,0x1
    80001ab8:	8526                	mv	a0,s1
    80001aba:	fffff097          	auipc	ra,0xfffff
    80001abe:	712080e7          	jalr	1810(ra) # 800011cc <kvmmap>
      p->kstack = va;
    80001ac2:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ac6:	16890913          	addi	s2,s2,360
    80001aca:	fb491de3          	bne	s2,s4,80001a84 <procinit+0x58>
  kvminithart();
    80001ace:	fffff097          	auipc	ra,0xfffff
    80001ad2:	506080e7          	jalr	1286(ra) # 80000fd4 <kvminithart>
}
    80001ad6:	60a6                	ld	ra,72(sp)
    80001ad8:	6406                	ld	s0,64(sp)
    80001ada:	74e2                	ld	s1,56(sp)
    80001adc:	7942                	ld	s2,48(sp)
    80001ade:	79a2                	ld	s3,40(sp)
    80001ae0:	7a02                	ld	s4,32(sp)
    80001ae2:	6ae2                	ld	s5,24(sp)
    80001ae4:	6b42                	ld	s6,16(sp)
    80001ae6:	6ba2                	ld	s7,8(sp)
    80001ae8:	6161                	addi	sp,sp,80
    80001aea:	8082                	ret
        panic("kalloc");
    80001aec:	00006517          	auipc	a0,0x6
    80001af0:	6bc50513          	addi	a0,a0,1724 # 800081a8 <digits+0x168>
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	a54080e7          	jalr	-1452(ra) # 80000548 <panic>

0000000080001afc <cpuid>:
{
    80001afc:	1141                	addi	sp,sp,-16
    80001afe:	e422                	sd	s0,8(sp)
    80001b00:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b02:	8512                	mv	a0,tp
}
    80001b04:	2501                	sext.w	a0,a0
    80001b06:	6422                	ld	s0,8(sp)
    80001b08:	0141                	addi	sp,sp,16
    80001b0a:	8082                	ret

0000000080001b0c <mycpu>:
mycpu(void) {
    80001b0c:	1141                	addi	sp,sp,-16
    80001b0e:	e422                	sd	s0,8(sp)
    80001b10:	0800                	addi	s0,sp,16
    80001b12:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001b14:	2781                	sext.w	a5,a5
    80001b16:	079e                	slli	a5,a5,0x7
}
    80001b18:	00010517          	auipc	a0,0x10
    80001b1c:	e5050513          	addi	a0,a0,-432 # 80011968 <cpus>
    80001b20:	953e                	add	a0,a0,a5
    80001b22:	6422                	ld	s0,8(sp)
    80001b24:	0141                	addi	sp,sp,16
    80001b26:	8082                	ret

0000000080001b28 <myproc>:
myproc(void) {
    80001b28:	1101                	addi	sp,sp,-32
    80001b2a:	ec06                	sd	ra,24(sp)
    80001b2c:	e822                	sd	s0,16(sp)
    80001b2e:	e426                	sd	s1,8(sp)
    80001b30:	1000                	addi	s0,sp,32
  push_off();
    80001b32:	fffff097          	auipc	ra,0xfffff
    80001b36:	092080e7          	jalr	146(ra) # 80000bc4 <push_off>
    80001b3a:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001b3c:	2781                	sext.w	a5,a5
    80001b3e:	079e                	slli	a5,a5,0x7
    80001b40:	00010717          	auipc	a4,0x10
    80001b44:	e1070713          	addi	a4,a4,-496 # 80011950 <pid_lock>
    80001b48:	97ba                	add	a5,a5,a4
    80001b4a:	6f84                	ld	s1,24(a5)
  pop_off();
    80001b4c:	fffff097          	auipc	ra,0xfffff
    80001b50:	118080e7          	jalr	280(ra) # 80000c64 <pop_off>
}
    80001b54:	8526                	mv	a0,s1
    80001b56:	60e2                	ld	ra,24(sp)
    80001b58:	6442                	ld	s0,16(sp)
    80001b5a:	64a2                	ld	s1,8(sp)
    80001b5c:	6105                	addi	sp,sp,32
    80001b5e:	8082                	ret

0000000080001b60 <forkret>:
{
    80001b60:	1141                	addi	sp,sp,-16
    80001b62:	e406                	sd	ra,8(sp)
    80001b64:	e022                	sd	s0,0(sp)
    80001b66:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001b68:	00000097          	auipc	ra,0x0
    80001b6c:	fc0080e7          	jalr	-64(ra) # 80001b28 <myproc>
    80001b70:	fffff097          	auipc	ra,0xfffff
    80001b74:	154080e7          	jalr	340(ra) # 80000cc4 <release>
  if (first) {
    80001b78:	00007797          	auipc	a5,0x7
    80001b7c:	c687a783          	lw	a5,-920(a5) # 800087e0 <first.1678>
    80001b80:	eb89                	bnez	a5,80001b92 <forkret+0x32>
  usertrapret();
    80001b82:	00001097          	auipc	ra,0x1
    80001b86:	c1c080e7          	jalr	-996(ra) # 8000279e <usertrapret>
}
    80001b8a:	60a2                	ld	ra,8(sp)
    80001b8c:	6402                	ld	s0,0(sp)
    80001b8e:	0141                	addi	sp,sp,16
    80001b90:	8082                	ret
    first = 0;
    80001b92:	00007797          	auipc	a5,0x7
    80001b96:	c407a723          	sw	zero,-946(a5) # 800087e0 <first.1678>
    fsinit(ROOTDEV);
    80001b9a:	4505                	li	a0,1
    80001b9c:	00002097          	auipc	ra,0x2
    80001ba0:	9aa080e7          	jalr	-1622(ra) # 80003546 <fsinit>
    80001ba4:	bff9                	j	80001b82 <forkret+0x22>

0000000080001ba6 <allocpid>:
allocpid() {
    80001ba6:	1101                	addi	sp,sp,-32
    80001ba8:	ec06                	sd	ra,24(sp)
    80001baa:	e822                	sd	s0,16(sp)
    80001bac:	e426                	sd	s1,8(sp)
    80001bae:	e04a                	sd	s2,0(sp)
    80001bb0:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001bb2:	00010917          	auipc	s2,0x10
    80001bb6:	d9e90913          	addi	s2,s2,-610 # 80011950 <pid_lock>
    80001bba:	854a                	mv	a0,s2
    80001bbc:	fffff097          	auipc	ra,0xfffff
    80001bc0:	054080e7          	jalr	84(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001bc4:	00007797          	auipc	a5,0x7
    80001bc8:	c2078793          	addi	a5,a5,-992 # 800087e4 <nextpid>
    80001bcc:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001bce:	0014871b          	addiw	a4,s1,1
    80001bd2:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001bd4:	854a                	mv	a0,s2
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	0ee080e7          	jalr	238(ra) # 80000cc4 <release>
}
    80001bde:	8526                	mv	a0,s1
    80001be0:	60e2                	ld	ra,24(sp)
    80001be2:	6442                	ld	s0,16(sp)
    80001be4:	64a2                	ld	s1,8(sp)
    80001be6:	6902                	ld	s2,0(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <proc_pagetable>:
{
    80001bec:	1101                	addi	sp,sp,-32
    80001bee:	ec06                	sd	ra,24(sp)
    80001bf0:	e822                	sd	s0,16(sp)
    80001bf2:	e426                	sd	s1,8(sp)
    80001bf4:	e04a                	sd	s2,0(sp)
    80001bf6:	1000                	addi	s0,sp,32
    80001bf8:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001bfa:	fffff097          	auipc	ra,0xfffff
    80001bfe:	78a080e7          	jalr	1930(ra) # 80001384 <uvmcreate>
    80001c02:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c04:	c121                	beqz	a0,80001c44 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c06:	4729                	li	a4,10
    80001c08:	00005697          	auipc	a3,0x5
    80001c0c:	3f868693          	addi	a3,a3,1016 # 80007000 <_trampoline>
    80001c10:	6605                	lui	a2,0x1
    80001c12:	040005b7          	lui	a1,0x4000
    80001c16:	15fd                	addi	a1,a1,-1
    80001c18:	05b2                	slli	a1,a1,0xc
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	524080e7          	jalr	1316(ra) # 8000113e <mappages>
    80001c22:	02054863          	bltz	a0,80001c52 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001c26:	4719                	li	a4,6
    80001c28:	05893683          	ld	a3,88(s2)
    80001c2c:	6605                	lui	a2,0x1
    80001c2e:	020005b7          	lui	a1,0x2000
    80001c32:	15fd                	addi	a1,a1,-1
    80001c34:	05b6                	slli	a1,a1,0xd
    80001c36:	8526                	mv	a0,s1
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	506080e7          	jalr	1286(ra) # 8000113e <mappages>
    80001c40:	02054163          	bltz	a0,80001c62 <proc_pagetable+0x76>
}
    80001c44:	8526                	mv	a0,s1
    80001c46:	60e2                	ld	ra,24(sp)
    80001c48:	6442                	ld	s0,16(sp)
    80001c4a:	64a2                	ld	s1,8(sp)
    80001c4c:	6902                	ld	s2,0(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret
    uvmfree(pagetable, 0);
    80001c52:	4581                	li	a1,0
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	9da080e7          	jalr	-1574(ra) # 80001630 <uvmfree>
    return 0;
    80001c5e:	4481                	li	s1,0
    80001c60:	b7d5                	j	80001c44 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c62:	4681                	li	a3,0
    80001c64:	4605                	li	a2,1
    80001c66:	040005b7          	lui	a1,0x4000
    80001c6a:	15fd                	addi	a1,a1,-1
    80001c6c:	05b2                	slli	a1,a1,0xc
    80001c6e:	8526                	mv	a0,s1
    80001c70:	fffff097          	auipc	ra,0xfffff
    80001c74:	666080e7          	jalr	1638(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001c78:	4581                	li	a1,0
    80001c7a:	8526                	mv	a0,s1
    80001c7c:	00000097          	auipc	ra,0x0
    80001c80:	9b4080e7          	jalr	-1612(ra) # 80001630 <uvmfree>
    return 0;
    80001c84:	4481                	li	s1,0
    80001c86:	bf7d                	j	80001c44 <proc_pagetable+0x58>

0000000080001c88 <proc_freepagetable>:
{
    80001c88:	1101                	addi	sp,sp,-32
    80001c8a:	ec06                	sd	ra,24(sp)
    80001c8c:	e822                	sd	s0,16(sp)
    80001c8e:	e426                	sd	s1,8(sp)
    80001c90:	e04a                	sd	s2,0(sp)
    80001c92:	1000                	addi	s0,sp,32
    80001c94:	84aa                	mv	s1,a0
    80001c96:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001c98:	4681                	li	a3,0
    80001c9a:	4605                	li	a2,1
    80001c9c:	040005b7          	lui	a1,0x4000
    80001ca0:	15fd                	addi	a1,a1,-1
    80001ca2:	05b2                	slli	a1,a1,0xc
    80001ca4:	fffff097          	auipc	ra,0xfffff
    80001ca8:	632080e7          	jalr	1586(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001cac:	4681                	li	a3,0
    80001cae:	4605                	li	a2,1
    80001cb0:	020005b7          	lui	a1,0x2000
    80001cb4:	15fd                	addi	a1,a1,-1
    80001cb6:	05b6                	slli	a1,a1,0xd
    80001cb8:	8526                	mv	a0,s1
    80001cba:	fffff097          	auipc	ra,0xfffff
    80001cbe:	61c080e7          	jalr	1564(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001cc2:	85ca                	mv	a1,s2
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	00000097          	auipc	ra,0x0
    80001cca:	96a080e7          	jalr	-1686(ra) # 80001630 <uvmfree>
}
    80001cce:	60e2                	ld	ra,24(sp)
    80001cd0:	6442                	ld	s0,16(sp)
    80001cd2:	64a2                	ld	s1,8(sp)
    80001cd4:	6902                	ld	s2,0(sp)
    80001cd6:	6105                	addi	sp,sp,32
    80001cd8:	8082                	ret

0000000080001cda <freeproc>:
{
    80001cda:	1101                	addi	sp,sp,-32
    80001cdc:	ec06                	sd	ra,24(sp)
    80001cde:	e822                	sd	s0,16(sp)
    80001ce0:	e426                	sd	s1,8(sp)
    80001ce2:	1000                	addi	s0,sp,32
    80001ce4:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001ce6:	6d28                	ld	a0,88(a0)
    80001ce8:	c509                	beqz	a0,80001cf2 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001cea:	fffff097          	auipc	ra,0xfffff
    80001cee:	d3a080e7          	jalr	-710(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001cf2:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001cf6:	68a8                	ld	a0,80(s1)
    80001cf8:	c511                	beqz	a0,80001d04 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001cfa:	64ac                	ld	a1,72(s1)
    80001cfc:	00000097          	auipc	ra,0x0
    80001d00:	f8c080e7          	jalr	-116(ra) # 80001c88 <proc_freepagetable>
  p->pagetable = 0;
    80001d04:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001d08:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001d0c:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001d10:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001d14:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001d18:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001d1c:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001d20:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001d24:	0004ac23          	sw	zero,24(s1)
}
    80001d28:	60e2                	ld	ra,24(sp)
    80001d2a:	6442                	ld	s0,16(sp)
    80001d2c:	64a2                	ld	s1,8(sp)
    80001d2e:	6105                	addi	sp,sp,32
    80001d30:	8082                	ret

0000000080001d32 <allocproc>:
{
    80001d32:	1101                	addi	sp,sp,-32
    80001d34:	ec06                	sd	ra,24(sp)
    80001d36:	e822                	sd	s0,16(sp)
    80001d38:	e426                	sd	s1,8(sp)
    80001d3a:	e04a                	sd	s2,0(sp)
    80001d3c:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d3e:	00010497          	auipc	s1,0x10
    80001d42:	02a48493          	addi	s1,s1,42 # 80011d68 <proc>
    80001d46:	00016917          	auipc	s2,0x16
    80001d4a:	a2290913          	addi	s2,s2,-1502 # 80017768 <tickslock>
    acquire(&p->lock);
    80001d4e:	8526                	mv	a0,s1
    80001d50:	fffff097          	auipc	ra,0xfffff
    80001d54:	ec0080e7          	jalr	-320(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001d58:	4c9c                	lw	a5,24(s1)
    80001d5a:	cf81                	beqz	a5,80001d72 <allocproc+0x40>
      release(&p->lock);
    80001d5c:	8526                	mv	a0,s1
    80001d5e:	fffff097          	auipc	ra,0xfffff
    80001d62:	f66080e7          	jalr	-154(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d66:	16848493          	addi	s1,s1,360
    80001d6a:	ff2492e3          	bne	s1,s2,80001d4e <allocproc+0x1c>
  return 0;
    80001d6e:	4481                	li	s1,0
    80001d70:	a0b9                	j	80001dbe <allocproc+0x8c>
  p->pid = allocpid();
    80001d72:	00000097          	auipc	ra,0x0
    80001d76:	e34080e7          	jalr	-460(ra) # 80001ba6 <allocpid>
    80001d7a:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001d7c:	fffff097          	auipc	ra,0xfffff
    80001d80:	da4080e7          	jalr	-604(ra) # 80000b20 <kalloc>
    80001d84:	892a                	mv	s2,a0
    80001d86:	eca8                	sd	a0,88(s1)
    80001d88:	c131                	beqz	a0,80001dcc <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001d8a:	8526                	mv	a0,s1
    80001d8c:	00000097          	auipc	ra,0x0
    80001d90:	e60080e7          	jalr	-416(ra) # 80001bec <proc_pagetable>
    80001d94:	892a                	mv	s2,a0
    80001d96:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001d98:	c129                	beqz	a0,80001dda <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001d9a:	07000613          	li	a2,112
    80001d9e:	4581                	li	a1,0
    80001da0:	06048513          	addi	a0,s1,96
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	f68080e7          	jalr	-152(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001dac:	00000797          	auipc	a5,0x0
    80001db0:	db478793          	addi	a5,a5,-588 # 80001b60 <forkret>
    80001db4:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001db6:	60bc                	ld	a5,64(s1)
    80001db8:	6705                	lui	a4,0x1
    80001dba:	97ba                	add	a5,a5,a4
    80001dbc:	f4bc                	sd	a5,104(s1)
}
    80001dbe:	8526                	mv	a0,s1
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6902                	ld	s2,0(sp)
    80001dc8:	6105                	addi	sp,sp,32
    80001dca:	8082                	ret
    release(&p->lock);
    80001dcc:	8526                	mv	a0,s1
    80001dce:	fffff097          	auipc	ra,0xfffff
    80001dd2:	ef6080e7          	jalr	-266(ra) # 80000cc4 <release>
    return 0;
    80001dd6:	84ca                	mv	s1,s2
    80001dd8:	b7dd                	j	80001dbe <allocproc+0x8c>
    freeproc(p);
    80001dda:	8526                	mv	a0,s1
    80001ddc:	00000097          	auipc	ra,0x0
    80001de0:	efe080e7          	jalr	-258(ra) # 80001cda <freeproc>
    release(&p->lock);
    80001de4:	8526                	mv	a0,s1
    80001de6:	fffff097          	auipc	ra,0xfffff
    80001dea:	ede080e7          	jalr	-290(ra) # 80000cc4 <release>
    return 0;
    80001dee:	84ca                	mv	s1,s2
    80001df0:	b7f9                	j	80001dbe <allocproc+0x8c>

0000000080001df2 <userinit>:
{
    80001df2:	1101                	addi	sp,sp,-32
    80001df4:	ec06                	sd	ra,24(sp)
    80001df6:	e822                	sd	s0,16(sp)
    80001df8:	e426                	sd	s1,8(sp)
    80001dfa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	f36080e7          	jalr	-202(ra) # 80001d32 <allocproc>
    80001e04:	84aa                	mv	s1,a0
  initproc = p;
    80001e06:	00007797          	auipc	a5,0x7
    80001e0a:	20a7b923          	sd	a0,530(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001e0e:	03400613          	li	a2,52
    80001e12:	00007597          	auipc	a1,0x7
    80001e16:	9de58593          	addi	a1,a1,-1570 # 800087f0 <initcode>
    80001e1a:	6928                	ld	a0,80(a0)
    80001e1c:	fffff097          	auipc	ra,0xfffff
    80001e20:	596080e7          	jalr	1430(ra) # 800013b2 <uvminit>
  p->sz = PGSIZE;
    80001e24:	6785                	lui	a5,0x1
    80001e26:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001e28:	6cb8                	ld	a4,88(s1)
    80001e2a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001e2e:	6cb8                	ld	a4,88(s1)
    80001e30:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001e32:	4641                	li	a2,16
    80001e34:	00006597          	auipc	a1,0x6
    80001e38:	37c58593          	addi	a1,a1,892 # 800081b0 <digits+0x170>
    80001e3c:	15848513          	addi	a0,s1,344
    80001e40:	fffff097          	auipc	ra,0xfffff
    80001e44:	022080e7          	jalr	34(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001e48:	00006517          	auipc	a0,0x6
    80001e4c:	37850513          	addi	a0,a0,888 # 800081c0 <digits+0x180>
    80001e50:	00002097          	auipc	ra,0x2
    80001e54:	122080e7          	jalr	290(ra) # 80003f72 <namei>
    80001e58:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001e5c:	4789                	li	a5,2
    80001e5e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001e60:	8526                	mv	a0,s1
    80001e62:	fffff097          	auipc	ra,0xfffff
    80001e66:	e62080e7          	jalr	-414(ra) # 80000cc4 <release>
}
    80001e6a:	60e2                	ld	ra,24(sp)
    80001e6c:	6442                	ld	s0,16(sp)
    80001e6e:	64a2                	ld	s1,8(sp)
    80001e70:	6105                	addi	sp,sp,32
    80001e72:	8082                	ret

0000000080001e74 <growproc>:
{
    80001e74:	1101                	addi	sp,sp,-32
    80001e76:	ec06                	sd	ra,24(sp)
    80001e78:	e822                	sd	s0,16(sp)
    80001e7a:	e426                	sd	s1,8(sp)
    80001e7c:	e04a                	sd	s2,0(sp)
    80001e7e:	1000                	addi	s0,sp,32
    80001e80:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	ca6080e7          	jalr	-858(ra) # 80001b28 <myproc>
    80001e8a:	892a                	mv	s2,a0
  sz = p->sz;
    80001e8c:	652c                	ld	a1,72(a0)
    80001e8e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001e92:	00904f63          	bgtz	s1,80001eb0 <growproc+0x3c>
  } else if(n < 0){
    80001e96:	0204cc63          	bltz	s1,80001ece <growproc+0x5a>
  p->sz = sz;
    80001e9a:	1602                	slli	a2,a2,0x20
    80001e9c:	9201                	srli	a2,a2,0x20
    80001e9e:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ea2:	4501                	li	a0,0
}
    80001ea4:	60e2                	ld	ra,24(sp)
    80001ea6:	6442                	ld	s0,16(sp)
    80001ea8:	64a2                	ld	s1,8(sp)
    80001eaa:	6902                	ld	s2,0(sp)
    80001eac:	6105                	addi	sp,sp,32
    80001eae:	8082                	ret
    if((sz = lazyalloc(p->pagetable, sz, sz + n)) == 0) {
    80001eb0:	9e25                	addw	a2,a2,s1
    80001eb2:	1602                	slli	a2,a2,0x20
    80001eb4:	9201                	srli	a2,a2,0x20
    80001eb6:	1582                	slli	a1,a1,0x20
    80001eb8:	9181                	srli	a1,a1,0x20
    80001eba:	6928                	ld	a0,80(a0)
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	69a080e7          	jalr	1690(ra) # 80001556 <lazyalloc>
    80001ec4:	0005061b          	sext.w	a2,a0
    80001ec8:	fa69                	bnez	a2,80001e9a <growproc+0x26>
      return -1;
    80001eca:	557d                	li	a0,-1
    80001ecc:	bfe1                	j	80001ea4 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001ece:	9e25                	addw	a2,a2,s1
    80001ed0:	1602                	slli	a2,a2,0x20
    80001ed2:	9201                	srli	a2,a2,0x20
    80001ed4:	1582                	slli	a1,a1,0x20
    80001ed6:	9181                	srli	a1,a1,0x20
    80001ed8:	6928                	ld	a0,80(a0)
    80001eda:	fffff097          	auipc	ra,0xfffff
    80001ede:	58a080e7          	jalr	1418(ra) # 80001464 <uvmdealloc>
    80001ee2:	0005061b          	sext.w	a2,a0
    80001ee6:	bf55                	j	80001e9a <growproc+0x26>

0000000080001ee8 <fork>:
{
    80001ee8:	7179                	addi	sp,sp,-48
    80001eea:	f406                	sd	ra,40(sp)
    80001eec:	f022                	sd	s0,32(sp)
    80001eee:	ec26                	sd	s1,24(sp)
    80001ef0:	e84a                	sd	s2,16(sp)
    80001ef2:	e44e                	sd	s3,8(sp)
    80001ef4:	e052                	sd	s4,0(sp)
    80001ef6:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ef8:	00000097          	auipc	ra,0x0
    80001efc:	c30080e7          	jalr	-976(ra) # 80001b28 <myproc>
    80001f00:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001f02:	00000097          	auipc	ra,0x0
    80001f06:	e30080e7          	jalr	-464(ra) # 80001d32 <allocproc>
    80001f0a:	c175                	beqz	a0,80001fee <fork+0x106>
    80001f0c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001f0e:	04893603          	ld	a2,72(s2)
    80001f12:	692c                	ld	a1,80(a0)
    80001f14:	05093503          	ld	a0,80(s2)
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	750080e7          	jalr	1872(ra) # 80001668 <uvmcopy>
    80001f20:	04054863          	bltz	a0,80001f70 <fork+0x88>
  np->sz = p->sz;
    80001f24:	04893783          	ld	a5,72(s2)
    80001f28:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001f2c:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001f30:	05893683          	ld	a3,88(s2)
    80001f34:	87b6                	mv	a5,a3
    80001f36:	0589b703          	ld	a4,88(s3)
    80001f3a:	12068693          	addi	a3,a3,288
    80001f3e:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001f42:	6788                	ld	a0,8(a5)
    80001f44:	6b8c                	ld	a1,16(a5)
    80001f46:	6f90                	ld	a2,24(a5)
    80001f48:	01073023          	sd	a6,0(a4)
    80001f4c:	e708                	sd	a0,8(a4)
    80001f4e:	eb0c                	sd	a1,16(a4)
    80001f50:	ef10                	sd	a2,24(a4)
    80001f52:	02078793          	addi	a5,a5,32
    80001f56:	02070713          	addi	a4,a4,32
    80001f5a:	fed792e3          	bne	a5,a3,80001f3e <fork+0x56>
  np->trapframe->a0 = 0;
    80001f5e:	0589b783          	ld	a5,88(s3)
    80001f62:	0607b823          	sd	zero,112(a5)
    80001f66:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001f6a:	15000a13          	li	s4,336
    80001f6e:	a03d                	j	80001f9c <fork+0xb4>
    freeproc(np);
    80001f70:	854e                	mv	a0,s3
    80001f72:	00000097          	auipc	ra,0x0
    80001f76:	d68080e7          	jalr	-664(ra) # 80001cda <freeproc>
    release(&np->lock);
    80001f7a:	854e                	mv	a0,s3
    80001f7c:	fffff097          	auipc	ra,0xfffff
    80001f80:	d48080e7          	jalr	-696(ra) # 80000cc4 <release>
    return -1;
    80001f84:	54fd                	li	s1,-1
    80001f86:	a899                	j	80001fdc <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001f88:	00002097          	auipc	ra,0x2
    80001f8c:	676080e7          	jalr	1654(ra) # 800045fe <filedup>
    80001f90:	009987b3          	add	a5,s3,s1
    80001f94:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001f96:	04a1                	addi	s1,s1,8
    80001f98:	01448763          	beq	s1,s4,80001fa6 <fork+0xbe>
    if(p->ofile[i])
    80001f9c:	009907b3          	add	a5,s2,s1
    80001fa0:	6388                	ld	a0,0(a5)
    80001fa2:	f17d                	bnez	a0,80001f88 <fork+0xa0>
    80001fa4:	bfcd                	j	80001f96 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001fa6:	15093503          	ld	a0,336(s2)
    80001faa:	00001097          	auipc	ra,0x1
    80001fae:	7d6080e7          	jalr	2006(ra) # 80003780 <idup>
    80001fb2:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001fb6:	4641                	li	a2,16
    80001fb8:	15890593          	addi	a1,s2,344
    80001fbc:	15898513          	addi	a0,s3,344
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	ea2080e7          	jalr	-350(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    80001fc8:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001fcc:	4789                	li	a5,2
    80001fce:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001fd2:	854e                	mv	a0,s3
    80001fd4:	fffff097          	auipc	ra,0xfffff
    80001fd8:	cf0080e7          	jalr	-784(ra) # 80000cc4 <release>
}
    80001fdc:	8526                	mv	a0,s1
    80001fde:	70a2                	ld	ra,40(sp)
    80001fe0:	7402                	ld	s0,32(sp)
    80001fe2:	64e2                	ld	s1,24(sp)
    80001fe4:	6942                	ld	s2,16(sp)
    80001fe6:	69a2                	ld	s3,8(sp)
    80001fe8:	6a02                	ld	s4,0(sp)
    80001fea:	6145                	addi	sp,sp,48
    80001fec:	8082                	ret
    return -1;
    80001fee:	54fd                	li	s1,-1
    80001ff0:	b7f5                	j	80001fdc <fork+0xf4>

0000000080001ff2 <reparent>:
{
    80001ff2:	7179                	addi	sp,sp,-48
    80001ff4:	f406                	sd	ra,40(sp)
    80001ff6:	f022                	sd	s0,32(sp)
    80001ff8:	ec26                	sd	s1,24(sp)
    80001ffa:	e84a                	sd	s2,16(sp)
    80001ffc:	e44e                	sd	s3,8(sp)
    80001ffe:	e052                	sd	s4,0(sp)
    80002000:	1800                	addi	s0,sp,48
    80002002:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002004:	00010497          	auipc	s1,0x10
    80002008:	d6448493          	addi	s1,s1,-668 # 80011d68 <proc>
      pp->parent = initproc;
    8000200c:	00007a17          	auipc	s4,0x7
    80002010:	00ca0a13          	addi	s4,s4,12 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002014:	00015997          	auipc	s3,0x15
    80002018:	75498993          	addi	s3,s3,1876 # 80017768 <tickslock>
    8000201c:	a029                	j	80002026 <reparent+0x34>
    8000201e:	16848493          	addi	s1,s1,360
    80002022:	03348363          	beq	s1,s3,80002048 <reparent+0x56>
    if(pp->parent == p){
    80002026:	709c                	ld	a5,32(s1)
    80002028:	ff279be3          	bne	a5,s2,8000201e <reparent+0x2c>
      acquire(&pp->lock);
    8000202c:	8526                	mv	a0,s1
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	be2080e7          	jalr	-1054(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    80002036:	000a3783          	ld	a5,0(s4)
    8000203a:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    8000203c:	8526                	mv	a0,s1
    8000203e:	fffff097          	auipc	ra,0xfffff
    80002042:	c86080e7          	jalr	-890(ra) # 80000cc4 <release>
    80002046:	bfe1                	j	8000201e <reparent+0x2c>
}
    80002048:	70a2                	ld	ra,40(sp)
    8000204a:	7402                	ld	s0,32(sp)
    8000204c:	64e2                	ld	s1,24(sp)
    8000204e:	6942                	ld	s2,16(sp)
    80002050:	69a2                	ld	s3,8(sp)
    80002052:	6a02                	ld	s4,0(sp)
    80002054:	6145                	addi	sp,sp,48
    80002056:	8082                	ret

0000000080002058 <scheduler>:
{
    80002058:	711d                	addi	sp,sp,-96
    8000205a:	ec86                	sd	ra,88(sp)
    8000205c:	e8a2                	sd	s0,80(sp)
    8000205e:	e4a6                	sd	s1,72(sp)
    80002060:	e0ca                	sd	s2,64(sp)
    80002062:	fc4e                	sd	s3,56(sp)
    80002064:	f852                	sd	s4,48(sp)
    80002066:	f456                	sd	s5,40(sp)
    80002068:	f05a                	sd	s6,32(sp)
    8000206a:	ec5e                	sd	s7,24(sp)
    8000206c:	e862                	sd	s8,16(sp)
    8000206e:	e466                	sd	s9,8(sp)
    80002070:	1080                	addi	s0,sp,96
    80002072:	8792                	mv	a5,tp
  int id = r_tp();
    80002074:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002076:	00779c13          	slli	s8,a5,0x7
    8000207a:	00010717          	auipc	a4,0x10
    8000207e:	8d670713          	addi	a4,a4,-1834 # 80011950 <pid_lock>
    80002082:	9762                	add	a4,a4,s8
    80002084:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80002088:	00010717          	auipc	a4,0x10
    8000208c:	8e870713          	addi	a4,a4,-1816 # 80011970 <cpus+0x8>
    80002090:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002092:	4a89                	li	s5,2
        c->proc = p;
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	00010b17          	auipc	s6,0x10
    8000209a:	8bab0b13          	addi	s6,s6,-1862 # 80011950 <pid_lock>
    8000209e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    800020a0:	00015a17          	auipc	s4,0x15
    800020a4:	6c8a0a13          	addi	s4,s4,1736 # 80017768 <tickslock>
    int nproc = 0;
    800020a8:	4c81                	li	s9,0
    800020aa:	a8a1                	j	80002102 <scheduler+0xaa>
        p->state = RUNNING;
    800020ac:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    800020b0:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    800020b4:	06048593          	addi	a1,s1,96
    800020b8:	8562                	mv	a0,s8
    800020ba:	00000097          	auipc	ra,0x0
    800020be:	63a080e7          	jalr	1594(ra) # 800026f4 <swtch>
        c->proc = 0;
    800020c2:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    800020c6:	8526                	mv	a0,s1
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	bfc080e7          	jalr	-1028(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800020d0:	16848493          	addi	s1,s1,360
    800020d4:	01448d63          	beq	s1,s4,800020ee <scheduler+0x96>
      acquire(&p->lock);
    800020d8:	8526                	mv	a0,s1
    800020da:	fffff097          	auipc	ra,0xfffff
    800020de:	b36080e7          	jalr	-1226(ra) # 80000c10 <acquire>
      if(p->state != UNUSED) {
    800020e2:	4c9c                	lw	a5,24(s1)
    800020e4:	d3ed                	beqz	a5,800020c6 <scheduler+0x6e>
        nproc++;
    800020e6:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    800020e8:	fd579fe3          	bne	a5,s5,800020c6 <scheduler+0x6e>
    800020ec:	b7c1                	j	800020ac <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    800020ee:	013aca63          	blt	s5,s3,80002102 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800020f6:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800020fa:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    800020fe:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002102:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002106:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000210a:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000210e:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002110:	00010497          	auipc	s1,0x10
    80002114:	c5848493          	addi	s1,s1,-936 # 80011d68 <proc>
        p->state = RUNNING;
    80002118:	4b8d                	li	s7,3
    8000211a:	bf7d                	j	800020d8 <scheduler+0x80>

000000008000211c <sched>:
{
    8000211c:	7179                	addi	sp,sp,-48
    8000211e:	f406                	sd	ra,40(sp)
    80002120:	f022                	sd	s0,32(sp)
    80002122:	ec26                	sd	s1,24(sp)
    80002124:	e84a                	sd	s2,16(sp)
    80002126:	e44e                	sd	s3,8(sp)
    80002128:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000212a:	00000097          	auipc	ra,0x0
    8000212e:	9fe080e7          	jalr	-1538(ra) # 80001b28 <myproc>
    80002132:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	a62080e7          	jalr	-1438(ra) # 80000b96 <holding>
    8000213c:	c93d                	beqz	a0,800021b2 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000213e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002140:	2781                	sext.w	a5,a5
    80002142:	079e                	slli	a5,a5,0x7
    80002144:	00010717          	auipc	a4,0x10
    80002148:	80c70713          	addi	a4,a4,-2036 # 80011950 <pid_lock>
    8000214c:	97ba                	add	a5,a5,a4
    8000214e:	0907a703          	lw	a4,144(a5)
    80002152:	4785                	li	a5,1
    80002154:	06f71763          	bne	a4,a5,800021c2 <sched+0xa6>
  if(p->state == RUNNING)
    80002158:	4c98                	lw	a4,24(s1)
    8000215a:	478d                	li	a5,3
    8000215c:	06f70b63          	beq	a4,a5,800021d2 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002160:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002164:	8b89                	andi	a5,a5,2
  if(intr_get())
    80002166:	efb5                	bnez	a5,800021e2 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002168:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000216a:	0000f917          	auipc	s2,0xf
    8000216e:	7e690913          	addi	s2,s2,2022 # 80011950 <pid_lock>
    80002172:	2781                	sext.w	a5,a5
    80002174:	079e                	slli	a5,a5,0x7
    80002176:	97ca                	add	a5,a5,s2
    80002178:	0947a983          	lw	s3,148(a5)
    8000217c:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    8000217e:	2781                	sext.w	a5,a5
    80002180:	079e                	slli	a5,a5,0x7
    80002182:	0000f597          	auipc	a1,0xf
    80002186:	7ee58593          	addi	a1,a1,2030 # 80011970 <cpus+0x8>
    8000218a:	95be                	add	a1,a1,a5
    8000218c:	06048513          	addi	a0,s1,96
    80002190:	00000097          	auipc	ra,0x0
    80002194:	564080e7          	jalr	1380(ra) # 800026f4 <swtch>
    80002198:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000219a:	2781                	sext.w	a5,a5
    8000219c:	079e                	slli	a5,a5,0x7
    8000219e:	97ca                	add	a5,a5,s2
    800021a0:	0937aa23          	sw	s3,148(a5)
}
    800021a4:	70a2                	ld	ra,40(sp)
    800021a6:	7402                	ld	s0,32(sp)
    800021a8:	64e2                	ld	s1,24(sp)
    800021aa:	6942                	ld	s2,16(sp)
    800021ac:	69a2                	ld	s3,8(sp)
    800021ae:	6145                	addi	sp,sp,48
    800021b0:	8082                	ret
    panic("sched p->lock");
    800021b2:	00006517          	auipc	a0,0x6
    800021b6:	01650513          	addi	a0,a0,22 # 800081c8 <digits+0x188>
    800021ba:	ffffe097          	auipc	ra,0xffffe
    800021be:	38e080e7          	jalr	910(ra) # 80000548 <panic>
    panic("sched locks");
    800021c2:	00006517          	auipc	a0,0x6
    800021c6:	01650513          	addi	a0,a0,22 # 800081d8 <digits+0x198>
    800021ca:	ffffe097          	auipc	ra,0xffffe
    800021ce:	37e080e7          	jalr	894(ra) # 80000548 <panic>
    panic("sched running");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	01650513          	addi	a0,a0,22 # 800081e8 <digits+0x1a8>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	36e080e7          	jalr	878(ra) # 80000548 <panic>
    panic("sched interruptible");
    800021e2:	00006517          	auipc	a0,0x6
    800021e6:	01650513          	addi	a0,a0,22 # 800081f8 <digits+0x1b8>
    800021ea:	ffffe097          	auipc	ra,0xffffe
    800021ee:	35e080e7          	jalr	862(ra) # 80000548 <panic>

00000000800021f2 <exit>:
{
    800021f2:	7179                	addi	sp,sp,-48
    800021f4:	f406                	sd	ra,40(sp)
    800021f6:	f022                	sd	s0,32(sp)
    800021f8:	ec26                	sd	s1,24(sp)
    800021fa:	e84a                	sd	s2,16(sp)
    800021fc:	e44e                	sd	s3,8(sp)
    800021fe:	e052                	sd	s4,0(sp)
    80002200:	1800                	addi	s0,sp,48
    80002202:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002204:	00000097          	auipc	ra,0x0
    80002208:	924080e7          	jalr	-1756(ra) # 80001b28 <myproc>
    8000220c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000220e:	00007797          	auipc	a5,0x7
    80002212:	e0a7b783          	ld	a5,-502(a5) # 80009018 <initproc>
    80002216:	0d050493          	addi	s1,a0,208
    8000221a:	15050913          	addi	s2,a0,336
    8000221e:	02a79363          	bne	a5,a0,80002244 <exit+0x52>
    panic("init exiting");
    80002222:	00006517          	auipc	a0,0x6
    80002226:	fee50513          	addi	a0,a0,-18 # 80008210 <digits+0x1d0>
    8000222a:	ffffe097          	auipc	ra,0xffffe
    8000222e:	31e080e7          	jalr	798(ra) # 80000548 <panic>
      fileclose(f);
    80002232:	00002097          	auipc	ra,0x2
    80002236:	41e080e7          	jalr	1054(ra) # 80004650 <fileclose>
      p->ofile[fd] = 0;
    8000223a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000223e:	04a1                	addi	s1,s1,8
    80002240:	01248563          	beq	s1,s2,8000224a <exit+0x58>
    if(p->ofile[fd]){
    80002244:	6088                	ld	a0,0(s1)
    80002246:	f575                	bnez	a0,80002232 <exit+0x40>
    80002248:	bfdd                	j	8000223e <exit+0x4c>
  begin_op();
    8000224a:	00002097          	auipc	ra,0x2
    8000224e:	f34080e7          	jalr	-204(ra) # 8000417e <begin_op>
  iput(p->cwd);
    80002252:	1509b503          	ld	a0,336(s3)
    80002256:	00001097          	auipc	ra,0x1
    8000225a:	722080e7          	jalr	1826(ra) # 80003978 <iput>
  end_op();
    8000225e:	00002097          	auipc	ra,0x2
    80002262:	fa0080e7          	jalr	-96(ra) # 800041fe <end_op>
  p->cwd = 0;
    80002266:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    8000226a:	00007497          	auipc	s1,0x7
    8000226e:	dae48493          	addi	s1,s1,-594 # 80009018 <initproc>
    80002272:	6088                	ld	a0,0(s1)
    80002274:	fffff097          	auipc	ra,0xfffff
    80002278:	99c080e7          	jalr	-1636(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    8000227c:	6088                	ld	a0,0(s1)
    8000227e:	fffff097          	auipc	ra,0xfffff
    80002282:	76a080e7          	jalr	1898(ra) # 800019e8 <wakeup1>
  release(&initproc->lock);
    80002286:	6088                	ld	a0,0(s1)
    80002288:	fffff097          	auipc	ra,0xfffff
    8000228c:	a3c080e7          	jalr	-1476(ra) # 80000cc4 <release>
  acquire(&p->lock);
    80002290:	854e                	mv	a0,s3
    80002292:	fffff097          	auipc	ra,0xfffff
    80002296:	97e080e7          	jalr	-1666(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    8000229a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    8000229e:	854e                	mv	a0,s3
    800022a0:	fffff097          	auipc	ra,0xfffff
    800022a4:	a24080e7          	jalr	-1500(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    800022a8:	8526                	mv	a0,s1
    800022aa:	fffff097          	auipc	ra,0xfffff
    800022ae:	966080e7          	jalr	-1690(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    800022b2:	854e                	mv	a0,s3
    800022b4:	fffff097          	auipc	ra,0xfffff
    800022b8:	95c080e7          	jalr	-1700(ra) # 80000c10 <acquire>
  reparent(p);
    800022bc:	854e                	mv	a0,s3
    800022be:	00000097          	auipc	ra,0x0
    800022c2:	d34080e7          	jalr	-716(ra) # 80001ff2 <reparent>
  wakeup1(original_parent);
    800022c6:	8526                	mv	a0,s1
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	720080e7          	jalr	1824(ra) # 800019e8 <wakeup1>
  p->xstate = status;
    800022d0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800022d4:	4791                	li	a5,4
    800022d6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800022da:	8526                	mv	a0,s1
    800022dc:	fffff097          	auipc	ra,0xfffff
    800022e0:	9e8080e7          	jalr	-1560(ra) # 80000cc4 <release>
  sched();
    800022e4:	00000097          	auipc	ra,0x0
    800022e8:	e38080e7          	jalr	-456(ra) # 8000211c <sched>
  panic("zombie exit");
    800022ec:	00006517          	auipc	a0,0x6
    800022f0:	f3450513          	addi	a0,a0,-204 # 80008220 <digits+0x1e0>
    800022f4:	ffffe097          	auipc	ra,0xffffe
    800022f8:	254080e7          	jalr	596(ra) # 80000548 <panic>

00000000800022fc <yield>:
{
    800022fc:	1101                	addi	sp,sp,-32
    800022fe:	ec06                	sd	ra,24(sp)
    80002300:	e822                	sd	s0,16(sp)
    80002302:	e426                	sd	s1,8(sp)
    80002304:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	822080e7          	jalr	-2014(ra) # 80001b28 <myproc>
    8000230e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	900080e7          	jalr	-1792(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    80002318:	4789                	li	a5,2
    8000231a:	cc9c                	sw	a5,24(s1)
  sched();
    8000231c:	00000097          	auipc	ra,0x0
    80002320:	e00080e7          	jalr	-512(ra) # 8000211c <sched>
  release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	99e080e7          	jalr	-1634(ra) # 80000cc4 <release>
}
    8000232e:	60e2                	ld	ra,24(sp)
    80002330:	6442                	ld	s0,16(sp)
    80002332:	64a2                	ld	s1,8(sp)
    80002334:	6105                	addi	sp,sp,32
    80002336:	8082                	ret

0000000080002338 <sleep>:
{
    80002338:	7179                	addi	sp,sp,-48
    8000233a:	f406                	sd	ra,40(sp)
    8000233c:	f022                	sd	s0,32(sp)
    8000233e:	ec26                	sd	s1,24(sp)
    80002340:	e84a                	sd	s2,16(sp)
    80002342:	e44e                	sd	s3,8(sp)
    80002344:	1800                	addi	s0,sp,48
    80002346:	89aa                	mv	s3,a0
    80002348:	892e                	mv	s2,a1
  struct proc *p = myproc();
    8000234a:	fffff097          	auipc	ra,0xfffff
    8000234e:	7de080e7          	jalr	2014(ra) # 80001b28 <myproc>
    80002352:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002354:	05250663          	beq	a0,s2,800023a0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	8b8080e7          	jalr	-1864(ra) # 80000c10 <acquire>
    release(lk);
    80002360:	854a                	mv	a0,s2
    80002362:	fffff097          	auipc	ra,0xfffff
    80002366:	962080e7          	jalr	-1694(ra) # 80000cc4 <release>
  p->chan = chan;
    8000236a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    8000236e:	4785                	li	a5,1
    80002370:	cc9c                	sw	a5,24(s1)
  sched();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	daa080e7          	jalr	-598(ra) # 8000211c <sched>
  p->chan = 0;
    8000237a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    8000237e:	8526                	mv	a0,s1
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	944080e7          	jalr	-1724(ra) # 80000cc4 <release>
    acquire(lk);
    80002388:	854a                	mv	a0,s2
    8000238a:	fffff097          	auipc	ra,0xfffff
    8000238e:	886080e7          	jalr	-1914(ra) # 80000c10 <acquire>
}
    80002392:	70a2                	ld	ra,40(sp)
    80002394:	7402                	ld	s0,32(sp)
    80002396:	64e2                	ld	s1,24(sp)
    80002398:	6942                	ld	s2,16(sp)
    8000239a:	69a2                	ld	s3,8(sp)
    8000239c:	6145                	addi	sp,sp,48
    8000239e:	8082                	ret
  p->chan = chan;
    800023a0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800023a4:	4785                	li	a5,1
    800023a6:	cd1c                	sw	a5,24(a0)
  sched();
    800023a8:	00000097          	auipc	ra,0x0
    800023ac:	d74080e7          	jalr	-652(ra) # 8000211c <sched>
  p->chan = 0;
    800023b0:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800023b4:	bff9                	j	80002392 <sleep+0x5a>

00000000800023b6 <wait>:
{
    800023b6:	715d                	addi	sp,sp,-80
    800023b8:	e486                	sd	ra,72(sp)
    800023ba:	e0a2                	sd	s0,64(sp)
    800023bc:	fc26                	sd	s1,56(sp)
    800023be:	f84a                	sd	s2,48(sp)
    800023c0:	f44e                	sd	s3,40(sp)
    800023c2:	f052                	sd	s4,32(sp)
    800023c4:	ec56                	sd	s5,24(sp)
    800023c6:	e85a                	sd	s6,16(sp)
    800023c8:	e45e                	sd	s7,8(sp)
    800023ca:	e062                	sd	s8,0(sp)
    800023cc:	0880                	addi	s0,sp,80
    800023ce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800023d0:	fffff097          	auipc	ra,0xfffff
    800023d4:	758080e7          	jalr	1880(ra) # 80001b28 <myproc>
    800023d8:	892a                	mv	s2,a0
  acquire(&p->lock);
    800023da:	8c2a                	mv	s8,a0
    800023dc:	fffff097          	auipc	ra,0xfffff
    800023e0:	834080e7          	jalr	-1996(ra) # 80000c10 <acquire>
    havekids = 0;
    800023e4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800023e6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800023e8:	00015997          	auipc	s3,0x15
    800023ec:	38098993          	addi	s3,s3,896 # 80017768 <tickslock>
        havekids = 1;
    800023f0:	4a85                	li	s5,1
    havekids = 0;
    800023f2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800023f4:	00010497          	auipc	s1,0x10
    800023f8:	97448493          	addi	s1,s1,-1676 # 80011d68 <proc>
    800023fc:	a08d                	j	8000245e <wait+0xa8>
          pid = np->pid;
    800023fe:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002402:	000b0e63          	beqz	s6,8000241e <wait+0x68>
    80002406:	4691                	li	a3,4
    80002408:	03448613          	addi	a2,s1,52
    8000240c:	85da                	mv	a1,s6
    8000240e:	05093503          	ld	a0,80(s2)
    80002412:	fffff097          	auipc	ra,0xfffff
    80002416:	48a080e7          	jalr	1162(ra) # 8000189c <copyout>
    8000241a:	02054263          	bltz	a0,8000243e <wait+0x88>
          freeproc(np);
    8000241e:	8526                	mv	a0,s1
    80002420:	00000097          	auipc	ra,0x0
    80002424:	8ba080e7          	jalr	-1862(ra) # 80001cda <freeproc>
          release(&np->lock);
    80002428:	8526                	mv	a0,s1
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	89a080e7          	jalr	-1894(ra) # 80000cc4 <release>
          release(&p->lock);
    80002432:	854a                	mv	a0,s2
    80002434:	fffff097          	auipc	ra,0xfffff
    80002438:	890080e7          	jalr	-1904(ra) # 80000cc4 <release>
          return pid;
    8000243c:	a8a9                	j	80002496 <wait+0xe0>
            release(&np->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	884080e7          	jalr	-1916(ra) # 80000cc4 <release>
            release(&p->lock);
    80002448:	854a                	mv	a0,s2
    8000244a:	fffff097          	auipc	ra,0xfffff
    8000244e:	87a080e7          	jalr	-1926(ra) # 80000cc4 <release>
            return -1;
    80002452:	59fd                	li	s3,-1
    80002454:	a089                	j	80002496 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002456:	16848493          	addi	s1,s1,360
    8000245a:	03348463          	beq	s1,s3,80002482 <wait+0xcc>
      if(np->parent == p){
    8000245e:	709c                	ld	a5,32(s1)
    80002460:	ff279be3          	bne	a5,s2,80002456 <wait+0xa0>
        acquire(&np->lock);
    80002464:	8526                	mv	a0,s1
    80002466:	ffffe097          	auipc	ra,0xffffe
    8000246a:	7aa080e7          	jalr	1962(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    8000246e:	4c9c                	lw	a5,24(s1)
    80002470:	f94787e3          	beq	a5,s4,800023fe <wait+0x48>
        release(&np->lock);
    80002474:	8526                	mv	a0,s1
    80002476:	fffff097          	auipc	ra,0xfffff
    8000247a:	84e080e7          	jalr	-1970(ra) # 80000cc4 <release>
        havekids = 1;
    8000247e:	8756                	mv	a4,s5
    80002480:	bfd9                	j	80002456 <wait+0xa0>
    if(!havekids || p->killed){
    80002482:	c701                	beqz	a4,8000248a <wait+0xd4>
    80002484:	03092783          	lw	a5,48(s2)
    80002488:	c785                	beqz	a5,800024b0 <wait+0xfa>
      release(&p->lock);
    8000248a:	854a                	mv	a0,s2
    8000248c:	fffff097          	auipc	ra,0xfffff
    80002490:	838080e7          	jalr	-1992(ra) # 80000cc4 <release>
      return -1;
    80002494:	59fd                	li	s3,-1
}
    80002496:	854e                	mv	a0,s3
    80002498:	60a6                	ld	ra,72(sp)
    8000249a:	6406                	ld	s0,64(sp)
    8000249c:	74e2                	ld	s1,56(sp)
    8000249e:	7942                	ld	s2,48(sp)
    800024a0:	79a2                	ld	s3,40(sp)
    800024a2:	7a02                	ld	s4,32(sp)
    800024a4:	6ae2                	ld	s5,24(sp)
    800024a6:	6b42                	ld	s6,16(sp)
    800024a8:	6ba2                	ld	s7,8(sp)
    800024aa:	6c02                	ld	s8,0(sp)
    800024ac:	6161                	addi	sp,sp,80
    800024ae:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800024b0:	85e2                	mv	a1,s8
    800024b2:	854a                	mv	a0,s2
    800024b4:	00000097          	auipc	ra,0x0
    800024b8:	e84080e7          	jalr	-380(ra) # 80002338 <sleep>
    havekids = 0;
    800024bc:	bf1d                	j	800023f2 <wait+0x3c>

00000000800024be <wakeup>:
{
    800024be:	7139                	addi	sp,sp,-64
    800024c0:	fc06                	sd	ra,56(sp)
    800024c2:	f822                	sd	s0,48(sp)
    800024c4:	f426                	sd	s1,40(sp)
    800024c6:	f04a                	sd	s2,32(sp)
    800024c8:	ec4e                	sd	s3,24(sp)
    800024ca:	e852                	sd	s4,16(sp)
    800024cc:	e456                	sd	s5,8(sp)
    800024ce:	0080                	addi	s0,sp,64
    800024d0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800024d2:	00010497          	auipc	s1,0x10
    800024d6:	89648493          	addi	s1,s1,-1898 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800024da:	4985                	li	s3,1
      p->state = RUNNABLE;
    800024dc:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800024de:	00015917          	auipc	s2,0x15
    800024e2:	28a90913          	addi	s2,s2,650 # 80017768 <tickslock>
    800024e6:	a821                	j	800024fe <wakeup+0x40>
      p->state = RUNNABLE;
    800024e8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800024ec:	8526                	mv	a0,s1
    800024ee:	ffffe097          	auipc	ra,0xffffe
    800024f2:	7d6080e7          	jalr	2006(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024f6:	16848493          	addi	s1,s1,360
    800024fa:	01248e63          	beq	s1,s2,80002516 <wakeup+0x58>
    acquire(&p->lock);
    800024fe:	8526                	mv	a0,s1
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	710080e7          	jalr	1808(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002508:	4c9c                	lw	a5,24(s1)
    8000250a:	ff3791e3          	bne	a5,s3,800024ec <wakeup+0x2e>
    8000250e:	749c                	ld	a5,40(s1)
    80002510:	fd479ee3          	bne	a5,s4,800024ec <wakeup+0x2e>
    80002514:	bfd1                	j	800024e8 <wakeup+0x2a>
}
    80002516:	70e2                	ld	ra,56(sp)
    80002518:	7442                	ld	s0,48(sp)
    8000251a:	74a2                	ld	s1,40(sp)
    8000251c:	7902                	ld	s2,32(sp)
    8000251e:	69e2                	ld	s3,24(sp)
    80002520:	6a42                	ld	s4,16(sp)
    80002522:	6aa2                	ld	s5,8(sp)
    80002524:	6121                	addi	sp,sp,64
    80002526:	8082                	ret

0000000080002528 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002528:	7179                	addi	sp,sp,-48
    8000252a:	f406                	sd	ra,40(sp)
    8000252c:	f022                	sd	s0,32(sp)
    8000252e:	ec26                	sd	s1,24(sp)
    80002530:	e84a                	sd	s2,16(sp)
    80002532:	e44e                	sd	s3,8(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002538:	00010497          	auipc	s1,0x10
    8000253c:	83048493          	addi	s1,s1,-2000 # 80011d68 <proc>
    80002540:	00015997          	auipc	s3,0x15
    80002544:	22898993          	addi	s3,s3,552 # 80017768 <tickslock>
    acquire(&p->lock);
    80002548:	8526                	mv	a0,s1
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	6c6080e7          	jalr	1734(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    80002552:	5c9c                	lw	a5,56(s1)
    80002554:	01278d63          	beq	a5,s2,8000256e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002558:	8526                	mv	a0,s1
    8000255a:	ffffe097          	auipc	ra,0xffffe
    8000255e:	76a080e7          	jalr	1898(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002562:	16848493          	addi	s1,s1,360
    80002566:	ff3491e3          	bne	s1,s3,80002548 <kill+0x20>
  }
  return -1;
    8000256a:	557d                	li	a0,-1
    8000256c:	a829                	j	80002586 <kill+0x5e>
      p->killed = 1;
    8000256e:	4785                	li	a5,1
    80002570:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002572:	4c98                	lw	a4,24(s1)
    80002574:	4785                	li	a5,1
    80002576:	00f70f63          	beq	a4,a5,80002594 <kill+0x6c>
      release(&p->lock);
    8000257a:	8526                	mv	a0,s1
    8000257c:	ffffe097          	auipc	ra,0xffffe
    80002580:	748080e7          	jalr	1864(ra) # 80000cc4 <release>
      return 0;
    80002584:	4501                	li	a0,0
}
    80002586:	70a2                	ld	ra,40(sp)
    80002588:	7402                	ld	s0,32(sp)
    8000258a:	64e2                	ld	s1,24(sp)
    8000258c:	6942                	ld	s2,16(sp)
    8000258e:	69a2                	ld	s3,8(sp)
    80002590:	6145                	addi	sp,sp,48
    80002592:	8082                	ret
        p->state = RUNNABLE;
    80002594:	4789                	li	a5,2
    80002596:	cc9c                	sw	a5,24(s1)
    80002598:	b7cd                	j	8000257a <kill+0x52>

000000008000259a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000259a:	7179                	addi	sp,sp,-48
    8000259c:	f406                	sd	ra,40(sp)
    8000259e:	f022                	sd	s0,32(sp)
    800025a0:	ec26                	sd	s1,24(sp)
    800025a2:	e84a                	sd	s2,16(sp)
    800025a4:	e44e                	sd	s3,8(sp)
    800025a6:	e052                	sd	s4,0(sp)
    800025a8:	1800                	addi	s0,sp,48
    800025aa:	84aa                	mv	s1,a0
    800025ac:	892e                	mv	s2,a1
    800025ae:	89b2                	mv	s3,a2
    800025b0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	576080e7          	jalr	1398(ra) # 80001b28 <myproc>
  if(user_dst){
    800025ba:	c08d                	beqz	s1,800025dc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025bc:	86d2                	mv	a3,s4
    800025be:	864e                	mv	a2,s3
    800025c0:	85ca                	mv	a1,s2
    800025c2:	6928                	ld	a0,80(a0)
    800025c4:	fffff097          	auipc	ra,0xfffff
    800025c8:	2d8080e7          	jalr	728(ra) # 8000189c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025cc:	70a2                	ld	ra,40(sp)
    800025ce:	7402                	ld	s0,32(sp)
    800025d0:	64e2                	ld	s1,24(sp)
    800025d2:	6942                	ld	s2,16(sp)
    800025d4:	69a2                	ld	s3,8(sp)
    800025d6:	6a02                	ld	s4,0(sp)
    800025d8:	6145                	addi	sp,sp,48
    800025da:	8082                	ret
    memmove((char *)dst, src, len);
    800025dc:	000a061b          	sext.w	a2,s4
    800025e0:	85ce                	mv	a1,s3
    800025e2:	854a                	mv	a0,s2
    800025e4:	ffffe097          	auipc	ra,0xffffe
    800025e8:	788080e7          	jalr	1928(ra) # 80000d6c <memmove>
    return 0;
    800025ec:	8526                	mv	a0,s1
    800025ee:	bff9                	j	800025cc <either_copyout+0x32>

00000000800025f0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025f0:	7179                	addi	sp,sp,-48
    800025f2:	f406                	sd	ra,40(sp)
    800025f4:	f022                	sd	s0,32(sp)
    800025f6:	ec26                	sd	s1,24(sp)
    800025f8:	e84a                	sd	s2,16(sp)
    800025fa:	e44e                	sd	s3,8(sp)
    800025fc:	e052                	sd	s4,0(sp)
    800025fe:	1800                	addi	s0,sp,48
    80002600:	892a                	mv	s2,a0
    80002602:	84ae                	mv	s1,a1
    80002604:	89b2                	mv	s3,a2
    80002606:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	520080e7          	jalr	1312(ra) # 80001b28 <myproc>
  if(user_src){
    80002610:	c08d                	beqz	s1,80002632 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002612:	86d2                	mv	a3,s4
    80002614:	864e                	mv	a2,s3
    80002616:	85ca                	mv	a1,s2
    80002618:	6928                	ld	a0,80(a0)
    8000261a:	fffff097          	auipc	ra,0xfffff
    8000261e:	328080e7          	jalr	808(ra) # 80001942 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002622:	70a2                	ld	ra,40(sp)
    80002624:	7402                	ld	s0,32(sp)
    80002626:	64e2                	ld	s1,24(sp)
    80002628:	6942                	ld	s2,16(sp)
    8000262a:	69a2                	ld	s3,8(sp)
    8000262c:	6a02                	ld	s4,0(sp)
    8000262e:	6145                	addi	sp,sp,48
    80002630:	8082                	ret
    memmove(dst, (char*)src, len);
    80002632:	000a061b          	sext.w	a2,s4
    80002636:	85ce                	mv	a1,s3
    80002638:	854a                	mv	a0,s2
    8000263a:	ffffe097          	auipc	ra,0xffffe
    8000263e:	732080e7          	jalr	1842(ra) # 80000d6c <memmove>
    return 0;
    80002642:	8526                	mv	a0,s1
    80002644:	bff9                	j	80002622 <either_copyin+0x32>

0000000080002646 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002646:	715d                	addi	sp,sp,-80
    80002648:	e486                	sd	ra,72(sp)
    8000264a:	e0a2                	sd	s0,64(sp)
    8000264c:	fc26                	sd	s1,56(sp)
    8000264e:	f84a                	sd	s2,48(sp)
    80002650:	f44e                	sd	s3,40(sp)
    80002652:	f052                	sd	s4,32(sp)
    80002654:	ec56                	sd	s5,24(sp)
    80002656:	e85a                	sd	s6,16(sp)
    80002658:	e45e                	sd	s7,8(sp)
    8000265a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000265c:	00006517          	auipc	a0,0x6
    80002660:	a6c50513          	addi	a0,a0,-1428 # 800080c8 <digits+0x88>
    80002664:	ffffe097          	auipc	ra,0xffffe
    80002668:	f2e080e7          	jalr	-210(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000266c:	00010497          	auipc	s1,0x10
    80002670:	85448493          	addi	s1,s1,-1964 # 80011ec0 <proc+0x158>
    80002674:	00015917          	auipc	s2,0x15
    80002678:	24c90913          	addi	s2,s2,588 # 800178c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000267c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    8000267e:	00006997          	auipc	s3,0x6
    80002682:	bb298993          	addi	s3,s3,-1102 # 80008230 <digits+0x1f0>
    printf("%d %s %s", p->pid, state, p->name);
    80002686:	00006a97          	auipc	s5,0x6
    8000268a:	bb2a8a93          	addi	s5,s5,-1102 # 80008238 <digits+0x1f8>
    printf("\n");
    8000268e:	00006a17          	auipc	s4,0x6
    80002692:	a3aa0a13          	addi	s4,s4,-1478 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002696:	00006b97          	auipc	s7,0x6
    8000269a:	bdab8b93          	addi	s7,s7,-1062 # 80008270 <states.1718>
    8000269e:	a00d                	j	800026c0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026a0:	ee06a583          	lw	a1,-288(a3)
    800026a4:	8556                	mv	a0,s5
    800026a6:	ffffe097          	auipc	ra,0xffffe
    800026aa:	eec080e7          	jalr	-276(ra) # 80000592 <printf>
    printf("\n");
    800026ae:	8552                	mv	a0,s4
    800026b0:	ffffe097          	auipc	ra,0xffffe
    800026b4:	ee2080e7          	jalr	-286(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026b8:	16848493          	addi	s1,s1,360
    800026bc:	03248163          	beq	s1,s2,800026de <procdump+0x98>
    if(p->state == UNUSED)
    800026c0:	86a6                	mv	a3,s1
    800026c2:	ec04a783          	lw	a5,-320(s1)
    800026c6:	dbed                	beqz	a5,800026b8 <procdump+0x72>
      state = "???";
    800026c8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026ca:	fcfb6be3          	bltu	s6,a5,800026a0 <procdump+0x5a>
    800026ce:	1782                	slli	a5,a5,0x20
    800026d0:	9381                	srli	a5,a5,0x20
    800026d2:	078e                	slli	a5,a5,0x3
    800026d4:	97de                	add	a5,a5,s7
    800026d6:	6390                	ld	a2,0(a5)
    800026d8:	f661                	bnez	a2,800026a0 <procdump+0x5a>
      state = "???";
    800026da:	864e                	mv	a2,s3
    800026dc:	b7d1                	j	800026a0 <procdump+0x5a>
  }
}
    800026de:	60a6                	ld	ra,72(sp)
    800026e0:	6406                	ld	s0,64(sp)
    800026e2:	74e2                	ld	s1,56(sp)
    800026e4:	7942                	ld	s2,48(sp)
    800026e6:	79a2                	ld	s3,40(sp)
    800026e8:	7a02                	ld	s4,32(sp)
    800026ea:	6ae2                	ld	s5,24(sp)
    800026ec:	6b42                	ld	s6,16(sp)
    800026ee:	6ba2                	ld	s7,8(sp)
    800026f0:	6161                	addi	sp,sp,80
    800026f2:	8082                	ret

00000000800026f4 <swtch>:
    800026f4:	00153023          	sd	ra,0(a0)
    800026f8:	00253423          	sd	sp,8(a0)
    800026fc:	e900                	sd	s0,16(a0)
    800026fe:	ed04                	sd	s1,24(a0)
    80002700:	03253023          	sd	s2,32(a0)
    80002704:	03353423          	sd	s3,40(a0)
    80002708:	03453823          	sd	s4,48(a0)
    8000270c:	03553c23          	sd	s5,56(a0)
    80002710:	05653023          	sd	s6,64(a0)
    80002714:	05753423          	sd	s7,72(a0)
    80002718:	05853823          	sd	s8,80(a0)
    8000271c:	05953c23          	sd	s9,88(a0)
    80002720:	07a53023          	sd	s10,96(a0)
    80002724:	07b53423          	sd	s11,104(a0)
    80002728:	0005b083          	ld	ra,0(a1)
    8000272c:	0085b103          	ld	sp,8(a1)
    80002730:	6980                	ld	s0,16(a1)
    80002732:	6d84                	ld	s1,24(a1)
    80002734:	0205b903          	ld	s2,32(a1)
    80002738:	0285b983          	ld	s3,40(a1)
    8000273c:	0305ba03          	ld	s4,48(a1)
    80002740:	0385ba83          	ld	s5,56(a1)
    80002744:	0405bb03          	ld	s6,64(a1)
    80002748:	0485bb83          	ld	s7,72(a1)
    8000274c:	0505bc03          	ld	s8,80(a1)
    80002750:	0585bc83          	ld	s9,88(a1)
    80002754:	0605bd03          	ld	s10,96(a1)
    80002758:	0685bd83          	ld	s11,104(a1)
    8000275c:	8082                	ret

000000008000275e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000275e:	1141                	addi	sp,sp,-16
    80002760:	e406                	sd	ra,8(sp)
    80002762:	e022                	sd	s0,0(sp)
    80002764:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002766:	00006597          	auipc	a1,0x6
    8000276a:	b3258593          	addi	a1,a1,-1230 # 80008298 <states.1718+0x28>
    8000276e:	00015517          	auipc	a0,0x15
    80002772:	ffa50513          	addi	a0,a0,-6 # 80017768 <tickslock>
    80002776:	ffffe097          	auipc	ra,0xffffe
    8000277a:	40a080e7          	jalr	1034(ra) # 80000b80 <initlock>
}
    8000277e:	60a2                	ld	ra,8(sp)
    80002780:	6402                	ld	s0,0(sp)
    80002782:	0141                	addi	sp,sp,16
    80002784:	8082                	ret

0000000080002786 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002786:	1141                	addi	sp,sp,-16
    80002788:	e422                	sd	s0,8(sp)
    8000278a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000278c:	00003797          	auipc	a5,0x3
    80002790:	53478793          	addi	a5,a5,1332 # 80005cc0 <kernelvec>
    80002794:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002798:	6422                	ld	s0,8(sp)
    8000279a:	0141                	addi	sp,sp,16
    8000279c:	8082                	ret

000000008000279e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000279e:	1141                	addi	sp,sp,-16
    800027a0:	e406                	sd	ra,8(sp)
    800027a2:	e022                	sd	s0,0(sp)
    800027a4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800027a6:	fffff097          	auipc	ra,0xfffff
    800027aa:	382080e7          	jalr	898(ra) # 80001b28 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027ae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800027b2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800027b4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800027b8:	00005617          	auipc	a2,0x5
    800027bc:	84860613          	addi	a2,a2,-1976 # 80007000 <_trampoline>
    800027c0:	00005697          	auipc	a3,0x5
    800027c4:	84068693          	addi	a3,a3,-1984 # 80007000 <_trampoline>
    800027c8:	8e91                	sub	a3,a3,a2
    800027ca:	040007b7          	lui	a5,0x4000
    800027ce:	17fd                	addi	a5,a5,-1
    800027d0:	07b2                	slli	a5,a5,0xc
    800027d2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800027d4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800027d8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800027da:	180026f3          	csrr	a3,satp
    800027de:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800027e0:	6d38                	ld	a4,88(a0)
    800027e2:	6134                	ld	a3,64(a0)
    800027e4:	6585                	lui	a1,0x1
    800027e6:	96ae                	add	a3,a3,a1
    800027e8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800027ea:	6d38                	ld	a4,88(a0)
    800027ec:	00000697          	auipc	a3,0x0
    800027f0:	13868693          	addi	a3,a3,312 # 80002924 <usertrap>
    800027f4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800027f6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800027f8:	8692                	mv	a3,tp
    800027fa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800027fc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002800:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002804:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002808:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000280c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000280e:	6f18                	ld	a4,24(a4)
    80002810:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002814:	692c                	ld	a1,80(a0)
    80002816:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002818:	00005717          	auipc	a4,0x5
    8000281c:	87870713          	addi	a4,a4,-1928 # 80007090 <userret>
    80002820:	8f11                	sub	a4,a4,a2
    80002822:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002824:	577d                	li	a4,-1
    80002826:	177e                	slli	a4,a4,0x3f
    80002828:	8dd9                	or	a1,a1,a4
    8000282a:	02000537          	lui	a0,0x2000
    8000282e:	157d                	addi	a0,a0,-1
    80002830:	0536                	slli	a0,a0,0xd
    80002832:	9782                	jalr	a5
}
    80002834:	60a2                	ld	ra,8(sp)
    80002836:	6402                	ld	s0,0(sp)
    80002838:	0141                	addi	sp,sp,16
    8000283a:	8082                	ret

000000008000283c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000283c:	1101                	addi	sp,sp,-32
    8000283e:	ec06                	sd	ra,24(sp)
    80002840:	e822                	sd	s0,16(sp)
    80002842:	e426                	sd	s1,8(sp)
    80002844:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002846:	00015497          	auipc	s1,0x15
    8000284a:	f2248493          	addi	s1,s1,-222 # 80017768 <tickslock>
    8000284e:	8526                	mv	a0,s1
    80002850:	ffffe097          	auipc	ra,0xffffe
    80002854:	3c0080e7          	jalr	960(ra) # 80000c10 <acquire>
  ticks++;
    80002858:	00006517          	auipc	a0,0x6
    8000285c:	7c850513          	addi	a0,a0,1992 # 80009020 <ticks>
    80002860:	411c                	lw	a5,0(a0)
    80002862:	2785                	addiw	a5,a5,1
    80002864:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002866:	00000097          	auipc	ra,0x0
    8000286a:	c58080e7          	jalr	-936(ra) # 800024be <wakeup>
  release(&tickslock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	454080e7          	jalr	1108(ra) # 80000cc4 <release>
}
    80002878:	60e2                	ld	ra,24(sp)
    8000287a:	6442                	ld	s0,16(sp)
    8000287c:	64a2                	ld	s1,8(sp)
    8000287e:	6105                	addi	sp,sp,32
    80002880:	8082                	ret

0000000080002882 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002882:	1101                	addi	sp,sp,-32
    80002884:	ec06                	sd	ra,24(sp)
    80002886:	e822                	sd	s0,16(sp)
    80002888:	e426                	sd	s1,8(sp)
    8000288a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002890:	00074d63          	bltz	a4,800028aa <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002894:	57fd                	li	a5,-1
    80002896:	17fe                	slli	a5,a5,0x3f
    80002898:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000289a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000289c:	06f70363          	beq	a4,a5,80002902 <devintr+0x80>
  }
}
    800028a0:	60e2                	ld	ra,24(sp)
    800028a2:	6442                	ld	s0,16(sp)
    800028a4:	64a2                	ld	s1,8(sp)
    800028a6:	6105                	addi	sp,sp,32
    800028a8:	8082                	ret
     (scause & 0xff) == 9){
    800028aa:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800028ae:	46a5                	li	a3,9
    800028b0:	fed792e3          	bne	a5,a3,80002894 <devintr+0x12>
    int irq = plic_claim();
    800028b4:	00003097          	auipc	ra,0x3
    800028b8:	514080e7          	jalr	1300(ra) # 80005dc8 <plic_claim>
    800028bc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800028be:	47a9                	li	a5,10
    800028c0:	02f50763          	beq	a0,a5,800028ee <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800028c4:	4785                	li	a5,1
    800028c6:	02f50963          	beq	a0,a5,800028f8 <devintr+0x76>
    return 1;
    800028ca:	4505                	li	a0,1
    } else if(irq){
    800028cc:	d8f1                	beqz	s1,800028a0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800028ce:	85a6                	mv	a1,s1
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	9d050513          	addi	a0,a0,-1584 # 800082a0 <states.1718+0x30>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	cba080e7          	jalr	-838(ra) # 80000592 <printf>
      plic_complete(irq);
    800028e0:	8526                	mv	a0,s1
    800028e2:	00003097          	auipc	ra,0x3
    800028e6:	50a080e7          	jalr	1290(ra) # 80005dec <plic_complete>
    return 1;
    800028ea:	4505                	li	a0,1
    800028ec:	bf55                	j	800028a0 <devintr+0x1e>
      uartintr();
    800028ee:	ffffe097          	auipc	ra,0xffffe
    800028f2:	0e6080e7          	jalr	230(ra) # 800009d4 <uartintr>
    800028f6:	b7ed                	j	800028e0 <devintr+0x5e>
      virtio_disk_intr();
    800028f8:	00004097          	auipc	ra,0x4
    800028fc:	98e080e7          	jalr	-1650(ra) # 80006286 <virtio_disk_intr>
    80002900:	b7c5                	j	800028e0 <devintr+0x5e>
    if(cpuid() == 0){
    80002902:	fffff097          	auipc	ra,0xfffff
    80002906:	1fa080e7          	jalr	506(ra) # 80001afc <cpuid>
    8000290a:	c901                	beqz	a0,8000291a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000290c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002910:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002912:	14479073          	csrw	sip,a5
    return 2;
    80002916:	4509                	li	a0,2
    80002918:	b761                	j	800028a0 <devintr+0x1e>
      clockintr();
    8000291a:	00000097          	auipc	ra,0x0
    8000291e:	f22080e7          	jalr	-222(ra) # 8000283c <clockintr>
    80002922:	b7ed                	j	8000290c <devintr+0x8a>

0000000080002924 <usertrap>:
{
    80002924:	7179                	addi	sp,sp,-48
    80002926:	f406                	sd	ra,40(sp)
    80002928:	f022                	sd	s0,32(sp)
    8000292a:	ec26                	sd	s1,24(sp)
    8000292c:	e84a                	sd	s2,16(sp)
    8000292e:	e44e                	sd	s3,8(sp)
    80002930:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002932:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002936:	1007f793          	andi	a5,a5,256
    8000293a:	e3b5                	bnez	a5,8000299e <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000293c:	00003797          	auipc	a5,0x3
    80002940:	38478793          	addi	a5,a5,900 # 80005cc0 <kernelvec>
    80002944:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002948:	fffff097          	auipc	ra,0xfffff
    8000294c:	1e0080e7          	jalr	480(ra) # 80001b28 <myproc>
    80002950:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002952:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002954:	14102773          	csrr	a4,sepc
    80002958:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000295a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000295e:	47a1                	li	a5,8
    80002960:	04f71d63          	bne	a4,a5,800029ba <usertrap+0x96>
    if(p->killed)
    80002964:	591c                	lw	a5,48(a0)
    80002966:	e7a1                	bnez	a5,800029ae <usertrap+0x8a>
    p->trapframe->epc += 4;
    80002968:	6cb8                	ld	a4,88(s1)
    8000296a:	6f1c                	ld	a5,24(a4)
    8000296c:	0791                	addi	a5,a5,4
    8000296e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002970:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002974:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002978:	10079073          	csrw	sstatus,a5
    syscall();
    8000297c:	00000097          	auipc	ra,0x0
    80002980:	344080e7          	jalr	836(ra) # 80002cc0 <syscall>
  if(p->killed)
    80002984:	589c                	lw	a5,48(s1)
    80002986:	eff1                	bnez	a5,80002a62 <usertrap+0x13e>
  usertrapret();
    80002988:	00000097          	auipc	ra,0x0
    8000298c:	e16080e7          	jalr	-490(ra) # 8000279e <usertrapret>
}
    80002990:	70a2                	ld	ra,40(sp)
    80002992:	7402                	ld	s0,32(sp)
    80002994:	64e2                	ld	s1,24(sp)
    80002996:	6942                	ld	s2,16(sp)
    80002998:	69a2                	ld	s3,8(sp)
    8000299a:	6145                	addi	sp,sp,48
    8000299c:	8082                	ret
    panic("usertrap: not from user mode");
    8000299e:	00006517          	auipc	a0,0x6
    800029a2:	92250513          	addi	a0,a0,-1758 # 800082c0 <states.1718+0x50>
    800029a6:	ffffe097          	auipc	ra,0xffffe
    800029aa:	ba2080e7          	jalr	-1118(ra) # 80000548 <panic>
      exit(-1);
    800029ae:	557d                	li	a0,-1
    800029b0:	00000097          	auipc	ra,0x0
    800029b4:	842080e7          	jalr	-1982(ra) # 800021f2 <exit>
    800029b8:	bf45                	j	80002968 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	ec8080e7          	jalr	-312(ra) # 80002882 <devintr>
    800029c2:	892a                	mv	s2,a0
    800029c4:	ed41                	bnez	a0,80002a5c <usertrap+0x138>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029c6:	14202773          	csrr	a4,scause
  } else if (r_scause() == 13 || r_scause() == 15){
    800029ca:	47b5                	li	a5,13
    800029cc:	00f70763          	beq	a4,a5,800029da <usertrap+0xb6>
    800029d0:	14202773          	csrr	a4,scause
    800029d4:	47bd                	li	a5,15
    800029d6:	04f71963          	bne	a4,a5,80002a28 <usertrap+0x104>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029da:	143029f3          	csrr	s3,stval
    if (pagefault_handler(myproc()->pagetable, va) != 0)
    800029de:	fffff097          	auipc	ra,0xfffff
    800029e2:	14a080e7          	jalr	330(ra) # 80001b28 <myproc>
    800029e6:	85ce                	mv	a1,s3
    800029e8:	6928                	ld	a0,80(a0)
    800029ea:	fffff097          	auipc	ra,0xfffff
    800029ee:	e40080e7          	jalr	-448(ra) # 8000182a <pagefault_handler>
    800029f2:	d949                	beqz	a0,80002984 <usertrap+0x60>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029f4:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800029f8:	5c90                	lw	a2,56(s1)
    800029fa:	00006517          	auipc	a0,0x6
    800029fe:	8e650513          	addi	a0,a0,-1818 # 800082e0 <states.1718+0x70>
    80002a02:	ffffe097          	auipc	ra,0xffffe
    80002a06:	b90080e7          	jalr	-1136(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a0a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a0e:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a12:	00006517          	auipc	a0,0x6
    80002a16:	8fe50513          	addi	a0,a0,-1794 # 80008310 <states.1718+0xa0>
    80002a1a:	ffffe097          	auipc	ra,0xffffe
    80002a1e:	b78080e7          	jalr	-1160(ra) # 80000592 <printf>
      p->killed = 1;
    80002a22:	4785                	li	a5,1
    80002a24:	d89c                	sw	a5,48(s1)
    80002a26:	a83d                	j	80002a64 <usertrap+0x140>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a28:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002a2c:	5c90                	lw	a2,56(s1)
    80002a2e:	00006517          	auipc	a0,0x6
    80002a32:	8b250513          	addi	a0,a0,-1870 # 800082e0 <states.1718+0x70>
    80002a36:	ffffe097          	auipc	ra,0xffffe
    80002a3a:	b5c080e7          	jalr	-1188(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a42:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a46:	00006517          	auipc	a0,0x6
    80002a4a:	8ca50513          	addi	a0,a0,-1846 # 80008310 <states.1718+0xa0>
    80002a4e:	ffffe097          	auipc	ra,0xffffe
    80002a52:	b44080e7          	jalr	-1212(ra) # 80000592 <printf>
    p->killed = 1;
    80002a56:	4785                	li	a5,1
    80002a58:	d89c                	sw	a5,48(s1)
    80002a5a:	a029                	j	80002a64 <usertrap+0x140>
  if(p->killed)
    80002a5c:	589c                	lw	a5,48(s1)
    80002a5e:	cb81                	beqz	a5,80002a6e <usertrap+0x14a>
    80002a60:	a011                	j	80002a64 <usertrap+0x140>
    80002a62:	4901                	li	s2,0
    exit(-1);
    80002a64:	557d                	li	a0,-1
    80002a66:	fffff097          	auipc	ra,0xfffff
    80002a6a:	78c080e7          	jalr	1932(ra) # 800021f2 <exit>
  if(which_dev == 2)
    80002a6e:	4789                	li	a5,2
    80002a70:	f0f91ce3          	bne	s2,a5,80002988 <usertrap+0x64>
    yield();
    80002a74:	00000097          	auipc	ra,0x0
    80002a78:	888080e7          	jalr	-1912(ra) # 800022fc <yield>
    80002a7c:	b731                	j	80002988 <usertrap+0x64>

0000000080002a7e <kerneltrap>:
{
    80002a7e:	7179                	addi	sp,sp,-48
    80002a80:	f406                	sd	ra,40(sp)
    80002a82:	f022                	sd	s0,32(sp)
    80002a84:	ec26                	sd	s1,24(sp)
    80002a86:	e84a                	sd	s2,16(sp)
    80002a88:	e44e                	sd	s3,8(sp)
    80002a8a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a8c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a90:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a94:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002a98:	1004f793          	andi	a5,s1,256
    80002a9c:	cb85                	beqz	a5,80002acc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a9e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002aa2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002aa4:	ef85                	bnez	a5,80002adc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002aa6:	00000097          	auipc	ra,0x0
    80002aaa:	ddc080e7          	jalr	-548(ra) # 80002882 <devintr>
    80002aae:	cd1d                	beqz	a0,80002aec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002ab0:	4789                	li	a5,2
    80002ab2:	06f50a63          	beq	a0,a5,80002b26 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002ab6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002aba:	10049073          	csrw	sstatus,s1
}
    80002abe:	70a2                	ld	ra,40(sp)
    80002ac0:	7402                	ld	s0,32(sp)
    80002ac2:	64e2                	ld	s1,24(sp)
    80002ac4:	6942                	ld	s2,16(sp)
    80002ac6:	69a2                	ld	s3,8(sp)
    80002ac8:	6145                	addi	sp,sp,48
    80002aca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002acc:	00006517          	auipc	a0,0x6
    80002ad0:	86450513          	addi	a0,a0,-1948 # 80008330 <states.1718+0xc0>
    80002ad4:	ffffe097          	auipc	ra,0xffffe
    80002ad8:	a74080e7          	jalr	-1420(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002adc:	00006517          	auipc	a0,0x6
    80002ae0:	87c50513          	addi	a0,a0,-1924 # 80008358 <states.1718+0xe8>
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	a64080e7          	jalr	-1436(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002aec:	85ce                	mv	a1,s3
    80002aee:	00006517          	auipc	a0,0x6
    80002af2:	88a50513          	addi	a0,a0,-1910 # 80008378 <states.1718+0x108>
    80002af6:	ffffe097          	auipc	ra,0xffffe
    80002afa:	a9c080e7          	jalr	-1380(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002afe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b02:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b06:	00006517          	auipc	a0,0x6
    80002b0a:	88250513          	addi	a0,a0,-1918 # 80008388 <states.1718+0x118>
    80002b0e:	ffffe097          	auipc	ra,0xffffe
    80002b12:	a84080e7          	jalr	-1404(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002b16:	00006517          	auipc	a0,0x6
    80002b1a:	88a50513          	addi	a0,a0,-1910 # 800083a0 <states.1718+0x130>
    80002b1e:	ffffe097          	auipc	ra,0xffffe
    80002b22:	a2a080e7          	jalr	-1494(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b26:	fffff097          	auipc	ra,0xfffff
    80002b2a:	002080e7          	jalr	2(ra) # 80001b28 <myproc>
    80002b2e:	d541                	beqz	a0,80002ab6 <kerneltrap+0x38>
    80002b30:	fffff097          	auipc	ra,0xfffff
    80002b34:	ff8080e7          	jalr	-8(ra) # 80001b28 <myproc>
    80002b38:	4d18                	lw	a4,24(a0)
    80002b3a:	478d                	li	a5,3
    80002b3c:	f6f71de3          	bne	a4,a5,80002ab6 <kerneltrap+0x38>
    yield();
    80002b40:	fffff097          	auipc	ra,0xfffff
    80002b44:	7bc080e7          	jalr	1980(ra) # 800022fc <yield>
    80002b48:	b7bd                	j	80002ab6 <kerneltrap+0x38>

0000000080002b4a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002b4a:	1101                	addi	sp,sp,-32
    80002b4c:	ec06                	sd	ra,24(sp)
    80002b4e:	e822                	sd	s0,16(sp)
    80002b50:	e426                	sd	s1,8(sp)
    80002b52:	1000                	addi	s0,sp,32
    80002b54:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002b56:	fffff097          	auipc	ra,0xfffff
    80002b5a:	fd2080e7          	jalr	-46(ra) # 80001b28 <myproc>
  switch (n) {
    80002b5e:	4795                	li	a5,5
    80002b60:	0497e163          	bltu	a5,s1,80002ba2 <argraw+0x58>
    80002b64:	048a                	slli	s1,s1,0x2
    80002b66:	00006717          	auipc	a4,0x6
    80002b6a:	87270713          	addi	a4,a4,-1934 # 800083d8 <states.1718+0x168>
    80002b6e:	94ba                	add	s1,s1,a4
    80002b70:	409c                	lw	a5,0(s1)
    80002b72:	97ba                	add	a5,a5,a4
    80002b74:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002b76:	6d3c                	ld	a5,88(a0)
    80002b78:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002b7a:	60e2                	ld	ra,24(sp)
    80002b7c:	6442                	ld	s0,16(sp)
    80002b7e:	64a2                	ld	s1,8(sp)
    80002b80:	6105                	addi	sp,sp,32
    80002b82:	8082                	ret
    return p->trapframe->a1;
    80002b84:	6d3c                	ld	a5,88(a0)
    80002b86:	7fa8                	ld	a0,120(a5)
    80002b88:	bfcd                	j	80002b7a <argraw+0x30>
    return p->trapframe->a2;
    80002b8a:	6d3c                	ld	a5,88(a0)
    80002b8c:	63c8                	ld	a0,128(a5)
    80002b8e:	b7f5                	j	80002b7a <argraw+0x30>
    return p->trapframe->a3;
    80002b90:	6d3c                	ld	a5,88(a0)
    80002b92:	67c8                	ld	a0,136(a5)
    80002b94:	b7dd                	j	80002b7a <argraw+0x30>
    return p->trapframe->a4;
    80002b96:	6d3c                	ld	a5,88(a0)
    80002b98:	6bc8                	ld	a0,144(a5)
    80002b9a:	b7c5                	j	80002b7a <argraw+0x30>
    return p->trapframe->a5;
    80002b9c:	6d3c                	ld	a5,88(a0)
    80002b9e:	6fc8                	ld	a0,152(a5)
    80002ba0:	bfe9                	j	80002b7a <argraw+0x30>
  panic("argraw");
    80002ba2:	00006517          	auipc	a0,0x6
    80002ba6:	80e50513          	addi	a0,a0,-2034 # 800083b0 <states.1718+0x140>
    80002baa:	ffffe097          	auipc	ra,0xffffe
    80002bae:	99e080e7          	jalr	-1634(ra) # 80000548 <panic>

0000000080002bb2 <fetchaddr>:
{
    80002bb2:	1101                	addi	sp,sp,-32
    80002bb4:	ec06                	sd	ra,24(sp)
    80002bb6:	e822                	sd	s0,16(sp)
    80002bb8:	e426                	sd	s1,8(sp)
    80002bba:	e04a                	sd	s2,0(sp)
    80002bbc:	1000                	addi	s0,sp,32
    80002bbe:	84aa                	mv	s1,a0
    80002bc0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002bc2:	fffff097          	auipc	ra,0xfffff
    80002bc6:	f66080e7          	jalr	-154(ra) # 80001b28 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002bca:	653c                	ld	a5,72(a0)
    80002bcc:	02f4f863          	bgeu	s1,a5,80002bfc <fetchaddr+0x4a>
    80002bd0:	00848713          	addi	a4,s1,8
    80002bd4:	02e7e663          	bltu	a5,a4,80002c00 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002bd8:	46a1                	li	a3,8
    80002bda:	8626                	mv	a2,s1
    80002bdc:	85ca                	mv	a1,s2
    80002bde:	6928                	ld	a0,80(a0)
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	d62080e7          	jalr	-670(ra) # 80001942 <copyin>
    80002be8:	00a03533          	snez	a0,a0
    80002bec:	40a00533          	neg	a0,a0
}
    80002bf0:	60e2                	ld	ra,24(sp)
    80002bf2:	6442                	ld	s0,16(sp)
    80002bf4:	64a2                	ld	s1,8(sp)
    80002bf6:	6902                	ld	s2,0(sp)
    80002bf8:	6105                	addi	sp,sp,32
    80002bfa:	8082                	ret
    return -1;
    80002bfc:	557d                	li	a0,-1
    80002bfe:	bfcd                	j	80002bf0 <fetchaddr+0x3e>
    80002c00:	557d                	li	a0,-1
    80002c02:	b7fd                	j	80002bf0 <fetchaddr+0x3e>

0000000080002c04 <fetchstr>:
{
    80002c04:	7179                	addi	sp,sp,-48
    80002c06:	f406                	sd	ra,40(sp)
    80002c08:	f022                	sd	s0,32(sp)
    80002c0a:	ec26                	sd	s1,24(sp)
    80002c0c:	e84a                	sd	s2,16(sp)
    80002c0e:	e44e                	sd	s3,8(sp)
    80002c10:	1800                	addi	s0,sp,48
    80002c12:	892a                	mv	s2,a0
    80002c14:	84ae                	mv	s1,a1
    80002c16:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	f10080e7          	jalr	-240(ra) # 80001b28 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002c20:	86ce                	mv	a3,s3
    80002c22:	864a                	mv	a2,s2
    80002c24:	85a6                	mv	a1,s1
    80002c26:	6928                	ld	a0,80(a0)
    80002c28:	fffff097          	auipc	ra,0xfffff
    80002c2c:	b4e080e7          	jalr	-1202(ra) # 80001776 <copyinstr>
  if(err < 0)
    80002c30:	00054763          	bltz	a0,80002c3e <fetchstr+0x3a>
  return strlen(buf);
    80002c34:	8526                	mv	a0,s1
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	25e080e7          	jalr	606(ra) # 80000e94 <strlen>
}
    80002c3e:	70a2                	ld	ra,40(sp)
    80002c40:	7402                	ld	s0,32(sp)
    80002c42:	64e2                	ld	s1,24(sp)
    80002c44:	6942                	ld	s2,16(sp)
    80002c46:	69a2                	ld	s3,8(sp)
    80002c48:	6145                	addi	sp,sp,48
    80002c4a:	8082                	ret

0000000080002c4c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002c4c:	1101                	addi	sp,sp,-32
    80002c4e:	ec06                	sd	ra,24(sp)
    80002c50:	e822                	sd	s0,16(sp)
    80002c52:	e426                	sd	s1,8(sp)
    80002c54:	1000                	addi	s0,sp,32
    80002c56:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c58:	00000097          	auipc	ra,0x0
    80002c5c:	ef2080e7          	jalr	-270(ra) # 80002b4a <argraw>
    80002c60:	c088                	sw	a0,0(s1)
  return 0;
}
    80002c62:	4501                	li	a0,0
    80002c64:	60e2                	ld	ra,24(sp)
    80002c66:	6442                	ld	s0,16(sp)
    80002c68:	64a2                	ld	s1,8(sp)
    80002c6a:	6105                	addi	sp,sp,32
    80002c6c:	8082                	ret

0000000080002c6e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002c6e:	1101                	addi	sp,sp,-32
    80002c70:	ec06                	sd	ra,24(sp)
    80002c72:	e822                	sd	s0,16(sp)
    80002c74:	e426                	sd	s1,8(sp)
    80002c76:	1000                	addi	s0,sp,32
    80002c78:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002c7a:	00000097          	auipc	ra,0x0
    80002c7e:	ed0080e7          	jalr	-304(ra) # 80002b4a <argraw>
    80002c82:	e088                	sd	a0,0(s1)
  return 0;
}
    80002c84:	4501                	li	a0,0
    80002c86:	60e2                	ld	ra,24(sp)
    80002c88:	6442                	ld	s0,16(sp)
    80002c8a:	64a2                	ld	s1,8(sp)
    80002c8c:	6105                	addi	sp,sp,32
    80002c8e:	8082                	ret

0000000080002c90 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002c90:	1101                	addi	sp,sp,-32
    80002c92:	ec06                	sd	ra,24(sp)
    80002c94:	e822                	sd	s0,16(sp)
    80002c96:	e426                	sd	s1,8(sp)
    80002c98:	e04a                	sd	s2,0(sp)
    80002c9a:	1000                	addi	s0,sp,32
    80002c9c:	84ae                	mv	s1,a1
    80002c9e:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	eaa080e7          	jalr	-342(ra) # 80002b4a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ca8:	864a                	mv	a2,s2
    80002caa:	85a6                	mv	a1,s1
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	f58080e7          	jalr	-168(ra) # 80002c04 <fetchstr>
}
    80002cb4:	60e2                	ld	ra,24(sp)
    80002cb6:	6442                	ld	s0,16(sp)
    80002cb8:	64a2                	ld	s1,8(sp)
    80002cba:	6902                	ld	s2,0(sp)
    80002cbc:	6105                	addi	sp,sp,32
    80002cbe:	8082                	ret

0000000080002cc0 <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002cc0:	1101                	addi	sp,sp,-32
    80002cc2:	ec06                	sd	ra,24(sp)
    80002cc4:	e822                	sd	s0,16(sp)
    80002cc6:	e426                	sd	s1,8(sp)
    80002cc8:	e04a                	sd	s2,0(sp)
    80002cca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ccc:	fffff097          	auipc	ra,0xfffff
    80002cd0:	e5c080e7          	jalr	-420(ra) # 80001b28 <myproc>
    80002cd4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002cd6:	05853903          	ld	s2,88(a0)
    80002cda:	0a893783          	ld	a5,168(s2)
    80002cde:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ce2:	37fd                	addiw	a5,a5,-1
    80002ce4:	4751                	li	a4,20
    80002ce6:	00f76f63          	bltu	a4,a5,80002d04 <syscall+0x44>
    80002cea:	00369713          	slli	a4,a3,0x3
    80002cee:	00005797          	auipc	a5,0x5
    80002cf2:	70278793          	addi	a5,a5,1794 # 800083f0 <syscalls>
    80002cf6:	97ba                	add	a5,a5,a4
    80002cf8:	639c                	ld	a5,0(a5)
    80002cfa:	c789                	beqz	a5,80002d04 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002cfc:	9782                	jalr	a5
    80002cfe:	06a93823          	sd	a0,112(s2)
    80002d02:	a839                	j	80002d20 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002d04:	15848613          	addi	a2,s1,344
    80002d08:	5c8c                	lw	a1,56(s1)
    80002d0a:	00005517          	auipc	a0,0x5
    80002d0e:	6ae50513          	addi	a0,a0,1710 # 800083b8 <states.1718+0x148>
    80002d12:	ffffe097          	auipc	ra,0xffffe
    80002d16:	880080e7          	jalr	-1920(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002d1a:	6cbc                	ld	a5,88(s1)
    80002d1c:	577d                	li	a4,-1
    80002d1e:	fbb8                	sd	a4,112(a5)
  }
}
    80002d20:	60e2                	ld	ra,24(sp)
    80002d22:	6442                	ld	s0,16(sp)
    80002d24:	64a2                	ld	s1,8(sp)
    80002d26:	6902                	ld	s2,0(sp)
    80002d28:	6105                	addi	sp,sp,32
    80002d2a:	8082                	ret

0000000080002d2c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002d2c:	1101                	addi	sp,sp,-32
    80002d2e:	ec06                	sd	ra,24(sp)
    80002d30:	e822                	sd	s0,16(sp)
    80002d32:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002d34:	fec40593          	addi	a1,s0,-20
    80002d38:	4501                	li	a0,0
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	f12080e7          	jalr	-238(ra) # 80002c4c <argint>
    return -1;
    80002d42:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d44:	00054963          	bltz	a0,80002d56 <sys_exit+0x2a>
  exit(n);
    80002d48:	fec42503          	lw	a0,-20(s0)
    80002d4c:	fffff097          	auipc	ra,0xfffff
    80002d50:	4a6080e7          	jalr	1190(ra) # 800021f2 <exit>
  return 0;  // not reached
    80002d54:	4781                	li	a5,0
}
    80002d56:	853e                	mv	a0,a5
    80002d58:	60e2                	ld	ra,24(sp)
    80002d5a:	6442                	ld	s0,16(sp)
    80002d5c:	6105                	addi	sp,sp,32
    80002d5e:	8082                	ret

0000000080002d60 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002d60:	1141                	addi	sp,sp,-16
    80002d62:	e406                	sd	ra,8(sp)
    80002d64:	e022                	sd	s0,0(sp)
    80002d66:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002d68:	fffff097          	auipc	ra,0xfffff
    80002d6c:	dc0080e7          	jalr	-576(ra) # 80001b28 <myproc>
}
    80002d70:	5d08                	lw	a0,56(a0)
    80002d72:	60a2                	ld	ra,8(sp)
    80002d74:	6402                	ld	s0,0(sp)
    80002d76:	0141                	addi	sp,sp,16
    80002d78:	8082                	ret

0000000080002d7a <sys_fork>:

uint64
sys_fork(void)
{
    80002d7a:	1141                	addi	sp,sp,-16
    80002d7c:	e406                	sd	ra,8(sp)
    80002d7e:	e022                	sd	s0,0(sp)
    80002d80:	0800                	addi	s0,sp,16
  return fork();
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	166080e7          	jalr	358(ra) # 80001ee8 <fork>
}
    80002d8a:	60a2                	ld	ra,8(sp)
    80002d8c:	6402                	ld	s0,0(sp)
    80002d8e:	0141                	addi	sp,sp,16
    80002d90:	8082                	ret

0000000080002d92 <sys_wait>:

uint64
sys_wait(void)
{
    80002d92:	1101                	addi	sp,sp,-32
    80002d94:	ec06                	sd	ra,24(sp)
    80002d96:	e822                	sd	s0,16(sp)
    80002d98:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002d9a:	fe840593          	addi	a1,s0,-24
    80002d9e:	4501                	li	a0,0
    80002da0:	00000097          	auipc	ra,0x0
    80002da4:	ece080e7          	jalr	-306(ra) # 80002c6e <argaddr>
    80002da8:	87aa                	mv	a5,a0
    return -1;
    80002daa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002dac:	0007c863          	bltz	a5,80002dbc <sys_wait+0x2a>
  return wait(p);
    80002db0:	fe843503          	ld	a0,-24(s0)
    80002db4:	fffff097          	auipc	ra,0xfffff
    80002db8:	602080e7          	jalr	1538(ra) # 800023b6 <wait>
}
    80002dbc:	60e2                	ld	ra,24(sp)
    80002dbe:	6442                	ld	s0,16(sp)
    80002dc0:	6105                	addi	sp,sp,32
    80002dc2:	8082                	ret

0000000080002dc4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002dc4:	7179                	addi	sp,sp,-48
    80002dc6:	f406                	sd	ra,40(sp)
    80002dc8:	f022                	sd	s0,32(sp)
    80002dca:	ec26                	sd	s1,24(sp)
    80002dcc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002dce:	fdc40593          	addi	a1,s0,-36
    80002dd2:	4501                	li	a0,0
    80002dd4:	00000097          	auipc	ra,0x0
    80002dd8:	e78080e7          	jalr	-392(ra) # 80002c4c <argint>
    80002ddc:	87aa                	mv	a5,a0
    return -1;
    80002dde:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002de0:	0207c063          	bltz	a5,80002e00 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002de4:	fffff097          	auipc	ra,0xfffff
    80002de8:	d44080e7          	jalr	-700(ra) # 80001b28 <myproc>
    80002dec:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002dee:	fdc42503          	lw	a0,-36(s0)
    80002df2:	fffff097          	auipc	ra,0xfffff
    80002df6:	082080e7          	jalr	130(ra) # 80001e74 <growproc>
    80002dfa:	00054863          	bltz	a0,80002e0a <sys_sbrk+0x46>
    return -1;
  return addr;
    80002dfe:	8526                	mv	a0,s1
}
    80002e00:	70a2                	ld	ra,40(sp)
    80002e02:	7402                	ld	s0,32(sp)
    80002e04:	64e2                	ld	s1,24(sp)
    80002e06:	6145                	addi	sp,sp,48
    80002e08:	8082                	ret
    return -1;
    80002e0a:	557d                	li	a0,-1
    80002e0c:	bfd5                	j	80002e00 <sys_sbrk+0x3c>

0000000080002e0e <sys_sleep>:

uint64
sys_sleep(void)
{
    80002e0e:	7139                	addi	sp,sp,-64
    80002e10:	fc06                	sd	ra,56(sp)
    80002e12:	f822                	sd	s0,48(sp)
    80002e14:	f426                	sd	s1,40(sp)
    80002e16:	f04a                	sd	s2,32(sp)
    80002e18:	ec4e                	sd	s3,24(sp)
    80002e1a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002e1c:	fcc40593          	addi	a1,s0,-52
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	e2a080e7          	jalr	-470(ra) # 80002c4c <argint>
    return -1;
    80002e2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e2c:	06054563          	bltz	a0,80002e96 <sys_sleep+0x88>
  acquire(&tickslock);
    80002e30:	00015517          	auipc	a0,0x15
    80002e34:	93850513          	addi	a0,a0,-1736 # 80017768 <tickslock>
    80002e38:	ffffe097          	auipc	ra,0xffffe
    80002e3c:	dd8080e7          	jalr	-552(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    80002e40:	00006917          	auipc	s2,0x6
    80002e44:	1e092903          	lw	s2,480(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002e48:	fcc42783          	lw	a5,-52(s0)
    80002e4c:	cf85                	beqz	a5,80002e84 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002e4e:	00015997          	auipc	s3,0x15
    80002e52:	91a98993          	addi	s3,s3,-1766 # 80017768 <tickslock>
    80002e56:	00006497          	auipc	s1,0x6
    80002e5a:	1ca48493          	addi	s1,s1,458 # 80009020 <ticks>
    if(myproc()->killed){
    80002e5e:	fffff097          	auipc	ra,0xfffff
    80002e62:	cca080e7          	jalr	-822(ra) # 80001b28 <myproc>
    80002e66:	591c                	lw	a5,48(a0)
    80002e68:	ef9d                	bnez	a5,80002ea6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002e6a:	85ce                	mv	a1,s3
    80002e6c:	8526                	mv	a0,s1
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	4ca080e7          	jalr	1226(ra) # 80002338 <sleep>
  while(ticks - ticks0 < n){
    80002e76:	409c                	lw	a5,0(s1)
    80002e78:	412787bb          	subw	a5,a5,s2
    80002e7c:	fcc42703          	lw	a4,-52(s0)
    80002e80:	fce7efe3          	bltu	a5,a4,80002e5e <sys_sleep+0x50>
  }
  release(&tickslock);
    80002e84:	00015517          	auipc	a0,0x15
    80002e88:	8e450513          	addi	a0,a0,-1820 # 80017768 <tickslock>
    80002e8c:	ffffe097          	auipc	ra,0xffffe
    80002e90:	e38080e7          	jalr	-456(ra) # 80000cc4 <release>
  return 0;
    80002e94:	4781                	li	a5,0
}
    80002e96:	853e                	mv	a0,a5
    80002e98:	70e2                	ld	ra,56(sp)
    80002e9a:	7442                	ld	s0,48(sp)
    80002e9c:	74a2                	ld	s1,40(sp)
    80002e9e:	7902                	ld	s2,32(sp)
    80002ea0:	69e2                	ld	s3,24(sp)
    80002ea2:	6121                	addi	sp,sp,64
    80002ea4:	8082                	ret
      release(&tickslock);
    80002ea6:	00015517          	auipc	a0,0x15
    80002eaa:	8c250513          	addi	a0,a0,-1854 # 80017768 <tickslock>
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	e16080e7          	jalr	-490(ra) # 80000cc4 <release>
      return -1;
    80002eb6:	57fd                	li	a5,-1
    80002eb8:	bff9                	j	80002e96 <sys_sleep+0x88>

0000000080002eba <sys_kill>:

uint64
sys_kill(void)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002ec2:	fec40593          	addi	a1,s0,-20
    80002ec6:	4501                	li	a0,0
    80002ec8:	00000097          	auipc	ra,0x0
    80002ecc:	d84080e7          	jalr	-636(ra) # 80002c4c <argint>
    80002ed0:	87aa                	mv	a5,a0
    return -1;
    80002ed2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002ed4:	0007c863          	bltz	a5,80002ee4 <sys_kill+0x2a>
  return kill(pid);
    80002ed8:	fec42503          	lw	a0,-20(s0)
    80002edc:	fffff097          	auipc	ra,0xfffff
    80002ee0:	64c080e7          	jalr	1612(ra) # 80002528 <kill>
}
    80002ee4:	60e2                	ld	ra,24(sp)
    80002ee6:	6442                	ld	s0,16(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret

0000000080002eec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002eec:	1101                	addi	sp,sp,-32
    80002eee:	ec06                	sd	ra,24(sp)
    80002ef0:	e822                	sd	s0,16(sp)
    80002ef2:	e426                	sd	s1,8(sp)
    80002ef4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ef6:	00015517          	auipc	a0,0x15
    80002efa:	87250513          	addi	a0,a0,-1934 # 80017768 <tickslock>
    80002efe:	ffffe097          	auipc	ra,0xffffe
    80002f02:	d12080e7          	jalr	-750(ra) # 80000c10 <acquire>
  xticks = ticks;
    80002f06:	00006497          	auipc	s1,0x6
    80002f0a:	11a4a483          	lw	s1,282(s1) # 80009020 <ticks>
  release(&tickslock);
    80002f0e:	00015517          	auipc	a0,0x15
    80002f12:	85a50513          	addi	a0,a0,-1958 # 80017768 <tickslock>
    80002f16:	ffffe097          	auipc	ra,0xffffe
    80002f1a:	dae080e7          	jalr	-594(ra) # 80000cc4 <release>
  return xticks;
}
    80002f1e:	02049513          	slli	a0,s1,0x20
    80002f22:	9101                	srli	a0,a0,0x20
    80002f24:	60e2                	ld	ra,24(sp)
    80002f26:	6442                	ld	s0,16(sp)
    80002f28:	64a2                	ld	s1,8(sp)
    80002f2a:	6105                	addi	sp,sp,32
    80002f2c:	8082                	ret

0000000080002f2e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002f2e:	7179                	addi	sp,sp,-48
    80002f30:	f406                	sd	ra,40(sp)
    80002f32:	f022                	sd	s0,32(sp)
    80002f34:	ec26                	sd	s1,24(sp)
    80002f36:	e84a                	sd	s2,16(sp)
    80002f38:	e44e                	sd	s3,8(sp)
    80002f3a:	e052                	sd	s4,0(sp)
    80002f3c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002f3e:	00005597          	auipc	a1,0x5
    80002f42:	56258593          	addi	a1,a1,1378 # 800084a0 <syscalls+0xb0>
    80002f46:	00015517          	auipc	a0,0x15
    80002f4a:	83a50513          	addi	a0,a0,-1990 # 80017780 <bcache>
    80002f4e:	ffffe097          	auipc	ra,0xffffe
    80002f52:	c32080e7          	jalr	-974(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f56:	0001d797          	auipc	a5,0x1d
    80002f5a:	82a78793          	addi	a5,a5,-2006 # 8001f780 <bcache+0x8000>
    80002f5e:	0001d717          	auipc	a4,0x1d
    80002f62:	a8a70713          	addi	a4,a4,-1398 # 8001f9e8 <bcache+0x8268>
    80002f66:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f6a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f6e:	00015497          	auipc	s1,0x15
    80002f72:	82a48493          	addi	s1,s1,-2006 # 80017798 <bcache+0x18>
    b->next = bcache.head.next;
    80002f76:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f78:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f7a:	00005a17          	auipc	s4,0x5
    80002f7e:	52ea0a13          	addi	s4,s4,1326 # 800084a8 <syscalls+0xb8>
    b->next = bcache.head.next;
    80002f82:	2b893783          	ld	a5,696(s2)
    80002f86:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f88:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f8c:	85d2                	mv	a1,s4
    80002f8e:	01048513          	addi	a0,s1,16
    80002f92:	00001097          	auipc	ra,0x1
    80002f96:	4b0080e7          	jalr	1200(ra) # 80004442 <initsleeplock>
    bcache.head.next->prev = b;
    80002f9a:	2b893783          	ld	a5,696(s2)
    80002f9e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002fa0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002fa4:	45848493          	addi	s1,s1,1112
    80002fa8:	fd349de3          	bne	s1,s3,80002f82 <binit+0x54>
  }
}
    80002fac:	70a2                	ld	ra,40(sp)
    80002fae:	7402                	ld	s0,32(sp)
    80002fb0:	64e2                	ld	s1,24(sp)
    80002fb2:	6942                	ld	s2,16(sp)
    80002fb4:	69a2                	ld	s3,8(sp)
    80002fb6:	6a02                	ld	s4,0(sp)
    80002fb8:	6145                	addi	sp,sp,48
    80002fba:	8082                	ret

0000000080002fbc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002fbc:	7179                	addi	sp,sp,-48
    80002fbe:	f406                	sd	ra,40(sp)
    80002fc0:	f022                	sd	s0,32(sp)
    80002fc2:	ec26                	sd	s1,24(sp)
    80002fc4:	e84a                	sd	s2,16(sp)
    80002fc6:	e44e                	sd	s3,8(sp)
    80002fc8:	1800                	addi	s0,sp,48
    80002fca:	89aa                	mv	s3,a0
    80002fcc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002fce:	00014517          	auipc	a0,0x14
    80002fd2:	7b250513          	addi	a0,a0,1970 # 80017780 <bcache>
    80002fd6:	ffffe097          	auipc	ra,0xffffe
    80002fda:	c3a080e7          	jalr	-966(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002fde:	0001d497          	auipc	s1,0x1d
    80002fe2:	a5a4b483          	ld	s1,-1446(s1) # 8001fa38 <bcache+0x82b8>
    80002fe6:	0001d797          	auipc	a5,0x1d
    80002fea:	a0278793          	addi	a5,a5,-1534 # 8001f9e8 <bcache+0x8268>
    80002fee:	02f48f63          	beq	s1,a5,8000302c <bread+0x70>
    80002ff2:	873e                	mv	a4,a5
    80002ff4:	a021                	j	80002ffc <bread+0x40>
    80002ff6:	68a4                	ld	s1,80(s1)
    80002ff8:	02e48a63          	beq	s1,a4,8000302c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002ffc:	449c                	lw	a5,8(s1)
    80002ffe:	ff379ce3          	bne	a5,s3,80002ff6 <bread+0x3a>
    80003002:	44dc                	lw	a5,12(s1)
    80003004:	ff2799e3          	bne	a5,s2,80002ff6 <bread+0x3a>
      b->refcnt++;
    80003008:	40bc                	lw	a5,64(s1)
    8000300a:	2785                	addiw	a5,a5,1
    8000300c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000300e:	00014517          	auipc	a0,0x14
    80003012:	77250513          	addi	a0,a0,1906 # 80017780 <bcache>
    80003016:	ffffe097          	auipc	ra,0xffffe
    8000301a:	cae080e7          	jalr	-850(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000301e:	01048513          	addi	a0,s1,16
    80003022:	00001097          	auipc	ra,0x1
    80003026:	45a080e7          	jalr	1114(ra) # 8000447c <acquiresleep>
      return b;
    8000302a:	a8b9                	j	80003088 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000302c:	0001d497          	auipc	s1,0x1d
    80003030:	a044b483          	ld	s1,-1532(s1) # 8001fa30 <bcache+0x82b0>
    80003034:	0001d797          	auipc	a5,0x1d
    80003038:	9b478793          	addi	a5,a5,-1612 # 8001f9e8 <bcache+0x8268>
    8000303c:	00f48863          	beq	s1,a5,8000304c <bread+0x90>
    80003040:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003042:	40bc                	lw	a5,64(s1)
    80003044:	cf81                	beqz	a5,8000305c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003046:	64a4                	ld	s1,72(s1)
    80003048:	fee49de3          	bne	s1,a4,80003042 <bread+0x86>
  panic("bget: no buffers");
    8000304c:	00005517          	auipc	a0,0x5
    80003050:	46450513          	addi	a0,a0,1124 # 800084b0 <syscalls+0xc0>
    80003054:	ffffd097          	auipc	ra,0xffffd
    80003058:	4f4080e7          	jalr	1268(ra) # 80000548 <panic>
      b->dev = dev;
    8000305c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003060:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003064:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003068:	4785                	li	a5,1
    8000306a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	71450513          	addi	a0,a0,1812 # 80017780 <bcache>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c50080e7          	jalr	-944(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    8000307c:	01048513          	addi	a0,s1,16
    80003080:	00001097          	auipc	ra,0x1
    80003084:	3fc080e7          	jalr	1020(ra) # 8000447c <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003088:	409c                	lw	a5,0(s1)
    8000308a:	cb89                	beqz	a5,8000309c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000308c:	8526                	mv	a0,s1
    8000308e:	70a2                	ld	ra,40(sp)
    80003090:	7402                	ld	s0,32(sp)
    80003092:	64e2                	ld	s1,24(sp)
    80003094:	6942                	ld	s2,16(sp)
    80003096:	69a2                	ld	s3,8(sp)
    80003098:	6145                	addi	sp,sp,48
    8000309a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000309c:	4581                	li	a1,0
    8000309e:	8526                	mv	a0,s1
    800030a0:	00003097          	auipc	ra,0x3
    800030a4:	f3c080e7          	jalr	-196(ra) # 80005fdc <virtio_disk_rw>
    b->valid = 1;
    800030a8:	4785                	li	a5,1
    800030aa:	c09c                	sw	a5,0(s1)
  return b;
    800030ac:	b7c5                	j	8000308c <bread+0xd0>

00000000800030ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800030ae:	1101                	addi	sp,sp,-32
    800030b0:	ec06                	sd	ra,24(sp)
    800030b2:	e822                	sd	s0,16(sp)
    800030b4:	e426                	sd	s1,8(sp)
    800030b6:	1000                	addi	s0,sp,32
    800030b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030ba:	0541                	addi	a0,a0,16
    800030bc:	00001097          	auipc	ra,0x1
    800030c0:	45a080e7          	jalr	1114(ra) # 80004516 <holdingsleep>
    800030c4:	cd01                	beqz	a0,800030dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800030c6:	4585                	li	a1,1
    800030c8:	8526                	mv	a0,s1
    800030ca:	00003097          	auipc	ra,0x3
    800030ce:	f12080e7          	jalr	-238(ra) # 80005fdc <virtio_disk_rw>
}
    800030d2:	60e2                	ld	ra,24(sp)
    800030d4:	6442                	ld	s0,16(sp)
    800030d6:	64a2                	ld	s1,8(sp)
    800030d8:	6105                	addi	sp,sp,32
    800030da:	8082                	ret
    panic("bwrite");
    800030dc:	00005517          	auipc	a0,0x5
    800030e0:	3ec50513          	addi	a0,a0,1004 # 800084c8 <syscalls+0xd8>
    800030e4:	ffffd097          	auipc	ra,0xffffd
    800030e8:	464080e7          	jalr	1124(ra) # 80000548 <panic>

00000000800030ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030ec:	1101                	addi	sp,sp,-32
    800030ee:	ec06                	sd	ra,24(sp)
    800030f0:	e822                	sd	s0,16(sp)
    800030f2:	e426                	sd	s1,8(sp)
    800030f4:	e04a                	sd	s2,0(sp)
    800030f6:	1000                	addi	s0,sp,32
    800030f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030fa:	01050913          	addi	s2,a0,16
    800030fe:	854a                	mv	a0,s2
    80003100:	00001097          	auipc	ra,0x1
    80003104:	416080e7          	jalr	1046(ra) # 80004516 <holdingsleep>
    80003108:	c92d                	beqz	a0,8000317a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000310a:	854a                	mv	a0,s2
    8000310c:	00001097          	auipc	ra,0x1
    80003110:	3c6080e7          	jalr	966(ra) # 800044d2 <releasesleep>

  acquire(&bcache.lock);
    80003114:	00014517          	auipc	a0,0x14
    80003118:	66c50513          	addi	a0,a0,1644 # 80017780 <bcache>
    8000311c:	ffffe097          	auipc	ra,0xffffe
    80003120:	af4080e7          	jalr	-1292(ra) # 80000c10 <acquire>
  b->refcnt--;
    80003124:	40bc                	lw	a5,64(s1)
    80003126:	37fd                	addiw	a5,a5,-1
    80003128:	0007871b          	sext.w	a4,a5
    8000312c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000312e:	eb05                	bnez	a4,8000315e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003130:	68bc                	ld	a5,80(s1)
    80003132:	64b8                	ld	a4,72(s1)
    80003134:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003136:	64bc                	ld	a5,72(s1)
    80003138:	68b8                	ld	a4,80(s1)
    8000313a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000313c:	0001c797          	auipc	a5,0x1c
    80003140:	64478793          	addi	a5,a5,1604 # 8001f780 <bcache+0x8000>
    80003144:	2b87b703          	ld	a4,696(a5)
    80003148:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000314a:	0001d717          	auipc	a4,0x1d
    8000314e:	89e70713          	addi	a4,a4,-1890 # 8001f9e8 <bcache+0x8268>
    80003152:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003154:	2b87b703          	ld	a4,696(a5)
    80003158:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000315a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000315e:	00014517          	auipc	a0,0x14
    80003162:	62250513          	addi	a0,a0,1570 # 80017780 <bcache>
    80003166:	ffffe097          	auipc	ra,0xffffe
    8000316a:	b5e080e7          	jalr	-1186(ra) # 80000cc4 <release>
}
    8000316e:	60e2                	ld	ra,24(sp)
    80003170:	6442                	ld	s0,16(sp)
    80003172:	64a2                	ld	s1,8(sp)
    80003174:	6902                	ld	s2,0(sp)
    80003176:	6105                	addi	sp,sp,32
    80003178:	8082                	ret
    panic("brelse");
    8000317a:	00005517          	auipc	a0,0x5
    8000317e:	35650513          	addi	a0,a0,854 # 800084d0 <syscalls+0xe0>
    80003182:	ffffd097          	auipc	ra,0xffffd
    80003186:	3c6080e7          	jalr	966(ra) # 80000548 <panic>

000000008000318a <bpin>:

void
bpin(struct buf *b) {
    8000318a:	1101                	addi	sp,sp,-32
    8000318c:	ec06                	sd	ra,24(sp)
    8000318e:	e822                	sd	s0,16(sp)
    80003190:	e426                	sd	s1,8(sp)
    80003192:	1000                	addi	s0,sp,32
    80003194:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003196:	00014517          	auipc	a0,0x14
    8000319a:	5ea50513          	addi	a0,a0,1514 # 80017780 <bcache>
    8000319e:	ffffe097          	auipc	ra,0xffffe
    800031a2:	a72080e7          	jalr	-1422(ra) # 80000c10 <acquire>
  b->refcnt++;
    800031a6:	40bc                	lw	a5,64(s1)
    800031a8:	2785                	addiw	a5,a5,1
    800031aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031ac:	00014517          	auipc	a0,0x14
    800031b0:	5d450513          	addi	a0,a0,1492 # 80017780 <bcache>
    800031b4:	ffffe097          	auipc	ra,0xffffe
    800031b8:	b10080e7          	jalr	-1264(ra) # 80000cc4 <release>
}
    800031bc:	60e2                	ld	ra,24(sp)
    800031be:	6442                	ld	s0,16(sp)
    800031c0:	64a2                	ld	s1,8(sp)
    800031c2:	6105                	addi	sp,sp,32
    800031c4:	8082                	ret

00000000800031c6 <bunpin>:

void
bunpin(struct buf *b) {
    800031c6:	1101                	addi	sp,sp,-32
    800031c8:	ec06                	sd	ra,24(sp)
    800031ca:	e822                	sd	s0,16(sp)
    800031cc:	e426                	sd	s1,8(sp)
    800031ce:	1000                	addi	s0,sp,32
    800031d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800031d2:	00014517          	auipc	a0,0x14
    800031d6:	5ae50513          	addi	a0,a0,1454 # 80017780 <bcache>
    800031da:	ffffe097          	auipc	ra,0xffffe
    800031de:	a36080e7          	jalr	-1482(ra) # 80000c10 <acquire>
  b->refcnt--;
    800031e2:	40bc                	lw	a5,64(s1)
    800031e4:	37fd                	addiw	a5,a5,-1
    800031e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031e8:	00014517          	auipc	a0,0x14
    800031ec:	59850513          	addi	a0,a0,1432 # 80017780 <bcache>
    800031f0:	ffffe097          	auipc	ra,0xffffe
    800031f4:	ad4080e7          	jalr	-1324(ra) # 80000cc4 <release>
}
    800031f8:	60e2                	ld	ra,24(sp)
    800031fa:	6442                	ld	s0,16(sp)
    800031fc:	64a2                	ld	s1,8(sp)
    800031fe:	6105                	addi	sp,sp,32
    80003200:	8082                	ret

0000000080003202 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003202:	1101                	addi	sp,sp,-32
    80003204:	ec06                	sd	ra,24(sp)
    80003206:	e822                	sd	s0,16(sp)
    80003208:	e426                	sd	s1,8(sp)
    8000320a:	e04a                	sd	s2,0(sp)
    8000320c:	1000                	addi	s0,sp,32
    8000320e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003210:	00d5d59b          	srliw	a1,a1,0xd
    80003214:	0001d797          	auipc	a5,0x1d
    80003218:	c487a783          	lw	a5,-952(a5) # 8001fe5c <sb+0x1c>
    8000321c:	9dbd                	addw	a1,a1,a5
    8000321e:	00000097          	auipc	ra,0x0
    80003222:	d9e080e7          	jalr	-610(ra) # 80002fbc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003226:	0074f713          	andi	a4,s1,7
    8000322a:	4785                	li	a5,1
    8000322c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003230:	14ce                	slli	s1,s1,0x33
    80003232:	90d9                	srli	s1,s1,0x36
    80003234:	00950733          	add	a4,a0,s1
    80003238:	05874703          	lbu	a4,88(a4)
    8000323c:	00e7f6b3          	and	a3,a5,a4
    80003240:	c69d                	beqz	a3,8000326e <bfree+0x6c>
    80003242:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003244:	94aa                	add	s1,s1,a0
    80003246:	fff7c793          	not	a5,a5
    8000324a:	8ff9                	and	a5,a5,a4
    8000324c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003250:	00001097          	auipc	ra,0x1
    80003254:	104080e7          	jalr	260(ra) # 80004354 <log_write>
  brelse(bp);
    80003258:	854a                	mv	a0,s2
    8000325a:	00000097          	auipc	ra,0x0
    8000325e:	e92080e7          	jalr	-366(ra) # 800030ec <brelse>
}
    80003262:	60e2                	ld	ra,24(sp)
    80003264:	6442                	ld	s0,16(sp)
    80003266:	64a2                	ld	s1,8(sp)
    80003268:	6902                	ld	s2,0(sp)
    8000326a:	6105                	addi	sp,sp,32
    8000326c:	8082                	ret
    panic("freeing free block");
    8000326e:	00005517          	auipc	a0,0x5
    80003272:	26a50513          	addi	a0,a0,618 # 800084d8 <syscalls+0xe8>
    80003276:	ffffd097          	auipc	ra,0xffffd
    8000327a:	2d2080e7          	jalr	722(ra) # 80000548 <panic>

000000008000327e <balloc>:
{
    8000327e:	711d                	addi	sp,sp,-96
    80003280:	ec86                	sd	ra,88(sp)
    80003282:	e8a2                	sd	s0,80(sp)
    80003284:	e4a6                	sd	s1,72(sp)
    80003286:	e0ca                	sd	s2,64(sp)
    80003288:	fc4e                	sd	s3,56(sp)
    8000328a:	f852                	sd	s4,48(sp)
    8000328c:	f456                	sd	s5,40(sp)
    8000328e:	f05a                	sd	s6,32(sp)
    80003290:	ec5e                	sd	s7,24(sp)
    80003292:	e862                	sd	s8,16(sp)
    80003294:	e466                	sd	s9,8(sp)
    80003296:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003298:	0001d797          	auipc	a5,0x1d
    8000329c:	bac7a783          	lw	a5,-1108(a5) # 8001fe44 <sb+0x4>
    800032a0:	cbd1                	beqz	a5,80003334 <balloc+0xb6>
    800032a2:	8baa                	mv	s7,a0
    800032a4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800032a6:	0001db17          	auipc	s6,0x1d
    800032aa:	b9ab0b13          	addi	s6,s6,-1126 # 8001fe40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032ae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800032b0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800032b4:	6c89                	lui	s9,0x2
    800032b6:	a831                	j	800032d2 <balloc+0x54>
    brelse(bp);
    800032b8:	854a                	mv	a0,s2
    800032ba:	00000097          	auipc	ra,0x0
    800032be:	e32080e7          	jalr	-462(ra) # 800030ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032c2:	015c87bb          	addw	a5,s9,s5
    800032c6:	00078a9b          	sext.w	s5,a5
    800032ca:	004b2703          	lw	a4,4(s6)
    800032ce:	06eaf363          	bgeu	s5,a4,80003334 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800032d2:	41fad79b          	sraiw	a5,s5,0x1f
    800032d6:	0137d79b          	srliw	a5,a5,0x13
    800032da:	015787bb          	addw	a5,a5,s5
    800032de:	40d7d79b          	sraiw	a5,a5,0xd
    800032e2:	01cb2583          	lw	a1,28(s6)
    800032e6:	9dbd                	addw	a1,a1,a5
    800032e8:	855e                	mv	a0,s7
    800032ea:	00000097          	auipc	ra,0x0
    800032ee:	cd2080e7          	jalr	-814(ra) # 80002fbc <bread>
    800032f2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032f4:	004b2503          	lw	a0,4(s6)
    800032f8:	000a849b          	sext.w	s1,s5
    800032fc:	8662                	mv	a2,s8
    800032fe:	faa4fde3          	bgeu	s1,a0,800032b8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003302:	41f6579b          	sraiw	a5,a2,0x1f
    80003306:	01d7d69b          	srliw	a3,a5,0x1d
    8000330a:	00c6873b          	addw	a4,a3,a2
    8000330e:	00777793          	andi	a5,a4,7
    80003312:	9f95                	subw	a5,a5,a3
    80003314:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003318:	4037571b          	sraiw	a4,a4,0x3
    8000331c:	00e906b3          	add	a3,s2,a4
    80003320:	0586c683          	lbu	a3,88(a3)
    80003324:	00d7f5b3          	and	a1,a5,a3
    80003328:	cd91                	beqz	a1,80003344 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000332a:	2605                	addiw	a2,a2,1
    8000332c:	2485                	addiw	s1,s1,1
    8000332e:	fd4618e3          	bne	a2,s4,800032fe <balloc+0x80>
    80003332:	b759                	j	800032b8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003334:	00005517          	auipc	a0,0x5
    80003338:	1bc50513          	addi	a0,a0,444 # 800084f0 <syscalls+0x100>
    8000333c:	ffffd097          	auipc	ra,0xffffd
    80003340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003344:	974a                	add	a4,a4,s2
    80003346:	8fd5                	or	a5,a5,a3
    80003348:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000334c:	854a                	mv	a0,s2
    8000334e:	00001097          	auipc	ra,0x1
    80003352:	006080e7          	jalr	6(ra) # 80004354 <log_write>
        brelse(bp);
    80003356:	854a                	mv	a0,s2
    80003358:	00000097          	auipc	ra,0x0
    8000335c:	d94080e7          	jalr	-620(ra) # 800030ec <brelse>
  bp = bread(dev, bno);
    80003360:	85a6                	mv	a1,s1
    80003362:	855e                	mv	a0,s7
    80003364:	00000097          	auipc	ra,0x0
    80003368:	c58080e7          	jalr	-936(ra) # 80002fbc <bread>
    8000336c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000336e:	40000613          	li	a2,1024
    80003372:	4581                	li	a1,0
    80003374:	05850513          	addi	a0,a0,88
    80003378:	ffffe097          	auipc	ra,0xffffe
    8000337c:	994080e7          	jalr	-1644(ra) # 80000d0c <memset>
  log_write(bp);
    80003380:	854a                	mv	a0,s2
    80003382:	00001097          	auipc	ra,0x1
    80003386:	fd2080e7          	jalr	-46(ra) # 80004354 <log_write>
  brelse(bp);
    8000338a:	854a                	mv	a0,s2
    8000338c:	00000097          	auipc	ra,0x0
    80003390:	d60080e7          	jalr	-672(ra) # 800030ec <brelse>
}
    80003394:	8526                	mv	a0,s1
    80003396:	60e6                	ld	ra,88(sp)
    80003398:	6446                	ld	s0,80(sp)
    8000339a:	64a6                	ld	s1,72(sp)
    8000339c:	6906                	ld	s2,64(sp)
    8000339e:	79e2                	ld	s3,56(sp)
    800033a0:	7a42                	ld	s4,48(sp)
    800033a2:	7aa2                	ld	s5,40(sp)
    800033a4:	7b02                	ld	s6,32(sp)
    800033a6:	6be2                	ld	s7,24(sp)
    800033a8:	6c42                	ld	s8,16(sp)
    800033aa:	6ca2                	ld	s9,8(sp)
    800033ac:	6125                	addi	sp,sp,96
    800033ae:	8082                	ret

00000000800033b0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800033b0:	7179                	addi	sp,sp,-48
    800033b2:	f406                	sd	ra,40(sp)
    800033b4:	f022                	sd	s0,32(sp)
    800033b6:	ec26                	sd	s1,24(sp)
    800033b8:	e84a                	sd	s2,16(sp)
    800033ba:	e44e                	sd	s3,8(sp)
    800033bc:	e052                	sd	s4,0(sp)
    800033be:	1800                	addi	s0,sp,48
    800033c0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800033c2:	47ad                	li	a5,11
    800033c4:	04b7fe63          	bgeu	a5,a1,80003420 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800033c8:	ff45849b          	addiw	s1,a1,-12
    800033cc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033d0:	0ff00793          	li	a5,255
    800033d4:	0ae7e363          	bltu	a5,a4,8000347a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800033d8:	08052583          	lw	a1,128(a0)
    800033dc:	c5ad                	beqz	a1,80003446 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800033de:	00092503          	lw	a0,0(s2)
    800033e2:	00000097          	auipc	ra,0x0
    800033e6:	bda080e7          	jalr	-1062(ra) # 80002fbc <bread>
    800033ea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033ec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033f0:	02049593          	slli	a1,s1,0x20
    800033f4:	9181                	srli	a1,a1,0x20
    800033f6:	058a                	slli	a1,a1,0x2
    800033f8:	00b784b3          	add	s1,a5,a1
    800033fc:	0004a983          	lw	s3,0(s1)
    80003400:	04098d63          	beqz	s3,8000345a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003404:	8552                	mv	a0,s4
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	ce6080e7          	jalr	-794(ra) # 800030ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000340e:	854e                	mv	a0,s3
    80003410:	70a2                	ld	ra,40(sp)
    80003412:	7402                	ld	s0,32(sp)
    80003414:	64e2                	ld	s1,24(sp)
    80003416:	6942                	ld	s2,16(sp)
    80003418:	69a2                	ld	s3,8(sp)
    8000341a:	6a02                	ld	s4,0(sp)
    8000341c:	6145                	addi	sp,sp,48
    8000341e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003420:	02059493          	slli	s1,a1,0x20
    80003424:	9081                	srli	s1,s1,0x20
    80003426:	048a                	slli	s1,s1,0x2
    80003428:	94aa                	add	s1,s1,a0
    8000342a:	0504a983          	lw	s3,80(s1)
    8000342e:	fe0990e3          	bnez	s3,8000340e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003432:	4108                	lw	a0,0(a0)
    80003434:	00000097          	auipc	ra,0x0
    80003438:	e4a080e7          	jalr	-438(ra) # 8000327e <balloc>
    8000343c:	0005099b          	sext.w	s3,a0
    80003440:	0534a823          	sw	s3,80(s1)
    80003444:	b7e9                	j	8000340e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003446:	4108                	lw	a0,0(a0)
    80003448:	00000097          	auipc	ra,0x0
    8000344c:	e36080e7          	jalr	-458(ra) # 8000327e <balloc>
    80003450:	0005059b          	sext.w	a1,a0
    80003454:	08b92023          	sw	a1,128(s2)
    80003458:	b759                	j	800033de <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000345a:	00092503          	lw	a0,0(s2)
    8000345e:	00000097          	auipc	ra,0x0
    80003462:	e20080e7          	jalr	-480(ra) # 8000327e <balloc>
    80003466:	0005099b          	sext.w	s3,a0
    8000346a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000346e:	8552                	mv	a0,s4
    80003470:	00001097          	auipc	ra,0x1
    80003474:	ee4080e7          	jalr	-284(ra) # 80004354 <log_write>
    80003478:	b771                	j	80003404 <bmap+0x54>
  panic("bmap: out of range");
    8000347a:	00005517          	auipc	a0,0x5
    8000347e:	08e50513          	addi	a0,a0,142 # 80008508 <syscalls+0x118>
    80003482:	ffffd097          	auipc	ra,0xffffd
    80003486:	0c6080e7          	jalr	198(ra) # 80000548 <panic>

000000008000348a <iget>:
{
    8000348a:	7179                	addi	sp,sp,-48
    8000348c:	f406                	sd	ra,40(sp)
    8000348e:	f022                	sd	s0,32(sp)
    80003490:	ec26                	sd	s1,24(sp)
    80003492:	e84a                	sd	s2,16(sp)
    80003494:	e44e                	sd	s3,8(sp)
    80003496:	e052                	sd	s4,0(sp)
    80003498:	1800                	addi	s0,sp,48
    8000349a:	89aa                	mv	s3,a0
    8000349c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000349e:	0001d517          	auipc	a0,0x1d
    800034a2:	9c250513          	addi	a0,a0,-1598 # 8001fe60 <icache>
    800034a6:	ffffd097          	auipc	ra,0xffffd
    800034aa:	76a080e7          	jalr	1898(ra) # 80000c10 <acquire>
  empty = 0;
    800034ae:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034b0:	0001d497          	auipc	s1,0x1d
    800034b4:	9c848493          	addi	s1,s1,-1592 # 8001fe78 <icache+0x18>
    800034b8:	0001e697          	auipc	a3,0x1e
    800034bc:	45068693          	addi	a3,a3,1104 # 80021908 <log>
    800034c0:	a039                	j	800034ce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034c2:	02090b63          	beqz	s2,800034f8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800034c6:	08848493          	addi	s1,s1,136
    800034ca:	02d48a63          	beq	s1,a3,800034fe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800034ce:	449c                	lw	a5,8(s1)
    800034d0:	fef059e3          	blez	a5,800034c2 <iget+0x38>
    800034d4:	4098                	lw	a4,0(s1)
    800034d6:	ff3716e3          	bne	a4,s3,800034c2 <iget+0x38>
    800034da:	40d8                	lw	a4,4(s1)
    800034dc:	ff4713e3          	bne	a4,s4,800034c2 <iget+0x38>
      ip->ref++;
    800034e0:	2785                	addiw	a5,a5,1
    800034e2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034e4:	0001d517          	auipc	a0,0x1d
    800034e8:	97c50513          	addi	a0,a0,-1668 # 8001fe60 <icache>
    800034ec:	ffffd097          	auipc	ra,0xffffd
    800034f0:	7d8080e7          	jalr	2008(ra) # 80000cc4 <release>
      return ip;
    800034f4:	8926                	mv	s2,s1
    800034f6:	a03d                	j	80003524 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034f8:	f7f9                	bnez	a5,800034c6 <iget+0x3c>
    800034fa:	8926                	mv	s2,s1
    800034fc:	b7e9                	j	800034c6 <iget+0x3c>
  if(empty == 0)
    800034fe:	02090c63          	beqz	s2,80003536 <iget+0xac>
  ip->dev = dev;
    80003502:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003506:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000350a:	4785                	li	a5,1
    8000350c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003510:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003514:	0001d517          	auipc	a0,0x1d
    80003518:	94c50513          	addi	a0,a0,-1716 # 8001fe60 <icache>
    8000351c:	ffffd097          	auipc	ra,0xffffd
    80003520:	7a8080e7          	jalr	1960(ra) # 80000cc4 <release>
}
    80003524:	854a                	mv	a0,s2
    80003526:	70a2                	ld	ra,40(sp)
    80003528:	7402                	ld	s0,32(sp)
    8000352a:	64e2                	ld	s1,24(sp)
    8000352c:	6942                	ld	s2,16(sp)
    8000352e:	69a2                	ld	s3,8(sp)
    80003530:	6a02                	ld	s4,0(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    panic("iget: no inodes");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	fea50513          	addi	a0,a0,-22 # 80008520 <syscalls+0x130>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	00a080e7          	jalr	10(ra) # 80000548 <panic>

0000000080003546 <fsinit>:
fsinit(int dev) {
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	1800                	addi	s0,sp,48
    80003554:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003556:	4585                	li	a1,1
    80003558:	00000097          	auipc	ra,0x0
    8000355c:	a64080e7          	jalr	-1436(ra) # 80002fbc <bread>
    80003560:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003562:	0001d997          	auipc	s3,0x1d
    80003566:	8de98993          	addi	s3,s3,-1826 # 8001fe40 <sb>
    8000356a:	02000613          	li	a2,32
    8000356e:	05850593          	addi	a1,a0,88
    80003572:	854e                	mv	a0,s3
    80003574:	ffffd097          	auipc	ra,0xffffd
    80003578:	7f8080e7          	jalr	2040(ra) # 80000d6c <memmove>
  brelse(bp);
    8000357c:	8526                	mv	a0,s1
    8000357e:	00000097          	auipc	ra,0x0
    80003582:	b6e080e7          	jalr	-1170(ra) # 800030ec <brelse>
  if(sb.magic != FSMAGIC)
    80003586:	0009a703          	lw	a4,0(s3)
    8000358a:	102037b7          	lui	a5,0x10203
    8000358e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003592:	02f71263          	bne	a4,a5,800035b6 <fsinit+0x70>
  initlog(dev, &sb);
    80003596:	0001d597          	auipc	a1,0x1d
    8000359a:	8aa58593          	addi	a1,a1,-1878 # 8001fe40 <sb>
    8000359e:	854a                	mv	a0,s2
    800035a0:	00001097          	auipc	ra,0x1
    800035a4:	b3c080e7          	jalr	-1220(ra) # 800040dc <initlog>
}
    800035a8:	70a2                	ld	ra,40(sp)
    800035aa:	7402                	ld	s0,32(sp)
    800035ac:	64e2                	ld	s1,24(sp)
    800035ae:	6942                	ld	s2,16(sp)
    800035b0:	69a2                	ld	s3,8(sp)
    800035b2:	6145                	addi	sp,sp,48
    800035b4:	8082                	ret
    panic("invalid file system");
    800035b6:	00005517          	auipc	a0,0x5
    800035ba:	f7a50513          	addi	a0,a0,-134 # 80008530 <syscalls+0x140>
    800035be:	ffffd097          	auipc	ra,0xffffd
    800035c2:	f8a080e7          	jalr	-118(ra) # 80000548 <panic>

00000000800035c6 <iinit>:
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800035d4:	00005597          	auipc	a1,0x5
    800035d8:	f7458593          	addi	a1,a1,-140 # 80008548 <syscalls+0x158>
    800035dc:	0001d517          	auipc	a0,0x1d
    800035e0:	88450513          	addi	a0,a0,-1916 # 8001fe60 <icache>
    800035e4:	ffffd097          	auipc	ra,0xffffd
    800035e8:	59c080e7          	jalr	1436(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035ec:	0001d497          	auipc	s1,0x1d
    800035f0:	89c48493          	addi	s1,s1,-1892 # 8001fe88 <icache+0x28>
    800035f4:	0001e997          	auipc	s3,0x1e
    800035f8:	32498993          	addi	s3,s3,804 # 80021918 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035fc:	00005917          	auipc	s2,0x5
    80003600:	f5490913          	addi	s2,s2,-172 # 80008550 <syscalls+0x160>
    80003604:	85ca                	mv	a1,s2
    80003606:	8526                	mv	a0,s1
    80003608:	00001097          	auipc	ra,0x1
    8000360c:	e3a080e7          	jalr	-454(ra) # 80004442 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003610:	08848493          	addi	s1,s1,136
    80003614:	ff3498e3          	bne	s1,s3,80003604 <iinit+0x3e>
}
    80003618:	70a2                	ld	ra,40(sp)
    8000361a:	7402                	ld	s0,32(sp)
    8000361c:	64e2                	ld	s1,24(sp)
    8000361e:	6942                	ld	s2,16(sp)
    80003620:	69a2                	ld	s3,8(sp)
    80003622:	6145                	addi	sp,sp,48
    80003624:	8082                	ret

0000000080003626 <ialloc>:
{
    80003626:	715d                	addi	sp,sp,-80
    80003628:	e486                	sd	ra,72(sp)
    8000362a:	e0a2                	sd	s0,64(sp)
    8000362c:	fc26                	sd	s1,56(sp)
    8000362e:	f84a                	sd	s2,48(sp)
    80003630:	f44e                	sd	s3,40(sp)
    80003632:	f052                	sd	s4,32(sp)
    80003634:	ec56                	sd	s5,24(sp)
    80003636:	e85a                	sd	s6,16(sp)
    80003638:	e45e                	sd	s7,8(sp)
    8000363a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000363c:	0001d717          	auipc	a4,0x1d
    80003640:	81072703          	lw	a4,-2032(a4) # 8001fe4c <sb+0xc>
    80003644:	4785                	li	a5,1
    80003646:	04e7fa63          	bgeu	a5,a4,8000369a <ialloc+0x74>
    8000364a:	8aaa                	mv	s5,a0
    8000364c:	8bae                	mv	s7,a1
    8000364e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003650:	0001ca17          	auipc	s4,0x1c
    80003654:	7f0a0a13          	addi	s4,s4,2032 # 8001fe40 <sb>
    80003658:	00048b1b          	sext.w	s6,s1
    8000365c:	0044d593          	srli	a1,s1,0x4
    80003660:	018a2783          	lw	a5,24(s4)
    80003664:	9dbd                	addw	a1,a1,a5
    80003666:	8556                	mv	a0,s5
    80003668:	00000097          	auipc	ra,0x0
    8000366c:	954080e7          	jalr	-1708(ra) # 80002fbc <bread>
    80003670:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003672:	05850993          	addi	s3,a0,88
    80003676:	00f4f793          	andi	a5,s1,15
    8000367a:	079a                	slli	a5,a5,0x6
    8000367c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000367e:	00099783          	lh	a5,0(s3)
    80003682:	c785                	beqz	a5,800036aa <ialloc+0x84>
    brelse(bp);
    80003684:	00000097          	auipc	ra,0x0
    80003688:	a68080e7          	jalr	-1432(ra) # 800030ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000368c:	0485                	addi	s1,s1,1
    8000368e:	00ca2703          	lw	a4,12(s4)
    80003692:	0004879b          	sext.w	a5,s1
    80003696:	fce7e1e3          	bltu	a5,a4,80003658 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	ebe50513          	addi	a0,a0,-322 # 80008558 <syscalls+0x168>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	ea6080e7          	jalr	-346(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800036aa:	04000613          	li	a2,64
    800036ae:	4581                	li	a1,0
    800036b0:	854e                	mv	a0,s3
    800036b2:	ffffd097          	auipc	ra,0xffffd
    800036b6:	65a080e7          	jalr	1626(ra) # 80000d0c <memset>
      dip->type = type;
    800036ba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800036be:	854a                	mv	a0,s2
    800036c0:	00001097          	auipc	ra,0x1
    800036c4:	c94080e7          	jalr	-876(ra) # 80004354 <log_write>
      brelse(bp);
    800036c8:	854a                	mv	a0,s2
    800036ca:	00000097          	auipc	ra,0x0
    800036ce:	a22080e7          	jalr	-1502(ra) # 800030ec <brelse>
      return iget(dev, inum);
    800036d2:	85da                	mv	a1,s6
    800036d4:	8556                	mv	a0,s5
    800036d6:	00000097          	auipc	ra,0x0
    800036da:	db4080e7          	jalr	-588(ra) # 8000348a <iget>
}
    800036de:	60a6                	ld	ra,72(sp)
    800036e0:	6406                	ld	s0,64(sp)
    800036e2:	74e2                	ld	s1,56(sp)
    800036e4:	7942                	ld	s2,48(sp)
    800036e6:	79a2                	ld	s3,40(sp)
    800036e8:	7a02                	ld	s4,32(sp)
    800036ea:	6ae2                	ld	s5,24(sp)
    800036ec:	6b42                	ld	s6,16(sp)
    800036ee:	6ba2                	ld	s7,8(sp)
    800036f0:	6161                	addi	sp,sp,80
    800036f2:	8082                	ret

00000000800036f4 <iupdate>:
{
    800036f4:	1101                	addi	sp,sp,-32
    800036f6:	ec06                	sd	ra,24(sp)
    800036f8:	e822                	sd	s0,16(sp)
    800036fa:	e426                	sd	s1,8(sp)
    800036fc:	e04a                	sd	s2,0(sp)
    800036fe:	1000                	addi	s0,sp,32
    80003700:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003702:	415c                	lw	a5,4(a0)
    80003704:	0047d79b          	srliw	a5,a5,0x4
    80003708:	0001c597          	auipc	a1,0x1c
    8000370c:	7505a583          	lw	a1,1872(a1) # 8001fe58 <sb+0x18>
    80003710:	9dbd                	addw	a1,a1,a5
    80003712:	4108                	lw	a0,0(a0)
    80003714:	00000097          	auipc	ra,0x0
    80003718:	8a8080e7          	jalr	-1880(ra) # 80002fbc <bread>
    8000371c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000371e:	05850793          	addi	a5,a0,88
    80003722:	40c8                	lw	a0,4(s1)
    80003724:	893d                	andi	a0,a0,15
    80003726:	051a                	slli	a0,a0,0x6
    80003728:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000372a:	04449703          	lh	a4,68(s1)
    8000372e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003732:	04649703          	lh	a4,70(s1)
    80003736:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    8000373a:	04849703          	lh	a4,72(s1)
    8000373e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003742:	04a49703          	lh	a4,74(s1)
    80003746:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    8000374a:	44f8                	lw	a4,76(s1)
    8000374c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000374e:	03400613          	li	a2,52
    80003752:	05048593          	addi	a1,s1,80
    80003756:	0531                	addi	a0,a0,12
    80003758:	ffffd097          	auipc	ra,0xffffd
    8000375c:	614080e7          	jalr	1556(ra) # 80000d6c <memmove>
  log_write(bp);
    80003760:	854a                	mv	a0,s2
    80003762:	00001097          	auipc	ra,0x1
    80003766:	bf2080e7          	jalr	-1038(ra) # 80004354 <log_write>
  brelse(bp);
    8000376a:	854a                	mv	a0,s2
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	980080e7          	jalr	-1664(ra) # 800030ec <brelse>
}
    80003774:	60e2                	ld	ra,24(sp)
    80003776:	6442                	ld	s0,16(sp)
    80003778:	64a2                	ld	s1,8(sp)
    8000377a:	6902                	ld	s2,0(sp)
    8000377c:	6105                	addi	sp,sp,32
    8000377e:	8082                	ret

0000000080003780 <idup>:
{
    80003780:	1101                	addi	sp,sp,-32
    80003782:	ec06                	sd	ra,24(sp)
    80003784:	e822                	sd	s0,16(sp)
    80003786:	e426                	sd	s1,8(sp)
    80003788:	1000                	addi	s0,sp,32
    8000378a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000378c:	0001c517          	auipc	a0,0x1c
    80003790:	6d450513          	addi	a0,a0,1748 # 8001fe60 <icache>
    80003794:	ffffd097          	auipc	ra,0xffffd
    80003798:	47c080e7          	jalr	1148(ra) # 80000c10 <acquire>
  ip->ref++;
    8000379c:	449c                	lw	a5,8(s1)
    8000379e:	2785                	addiw	a5,a5,1
    800037a0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800037a2:	0001c517          	auipc	a0,0x1c
    800037a6:	6be50513          	addi	a0,a0,1726 # 8001fe60 <icache>
    800037aa:	ffffd097          	auipc	ra,0xffffd
    800037ae:	51a080e7          	jalr	1306(ra) # 80000cc4 <release>
}
    800037b2:	8526                	mv	a0,s1
    800037b4:	60e2                	ld	ra,24(sp)
    800037b6:	6442                	ld	s0,16(sp)
    800037b8:	64a2                	ld	s1,8(sp)
    800037ba:	6105                	addi	sp,sp,32
    800037bc:	8082                	ret

00000000800037be <ilock>:
{
    800037be:	1101                	addi	sp,sp,-32
    800037c0:	ec06                	sd	ra,24(sp)
    800037c2:	e822                	sd	s0,16(sp)
    800037c4:	e426                	sd	s1,8(sp)
    800037c6:	e04a                	sd	s2,0(sp)
    800037c8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800037ca:	c115                	beqz	a0,800037ee <ilock+0x30>
    800037cc:	84aa                	mv	s1,a0
    800037ce:	451c                	lw	a5,8(a0)
    800037d0:	00f05f63          	blez	a5,800037ee <ilock+0x30>
  acquiresleep(&ip->lock);
    800037d4:	0541                	addi	a0,a0,16
    800037d6:	00001097          	auipc	ra,0x1
    800037da:	ca6080e7          	jalr	-858(ra) # 8000447c <acquiresleep>
  if(ip->valid == 0){
    800037de:	40bc                	lw	a5,64(s1)
    800037e0:	cf99                	beqz	a5,800037fe <ilock+0x40>
}
    800037e2:	60e2                	ld	ra,24(sp)
    800037e4:	6442                	ld	s0,16(sp)
    800037e6:	64a2                	ld	s1,8(sp)
    800037e8:	6902                	ld	s2,0(sp)
    800037ea:	6105                	addi	sp,sp,32
    800037ec:	8082                	ret
    panic("ilock");
    800037ee:	00005517          	auipc	a0,0x5
    800037f2:	d8250513          	addi	a0,a0,-638 # 80008570 <syscalls+0x180>
    800037f6:	ffffd097          	auipc	ra,0xffffd
    800037fa:	d52080e7          	jalr	-686(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037fe:	40dc                	lw	a5,4(s1)
    80003800:	0047d79b          	srliw	a5,a5,0x4
    80003804:	0001c597          	auipc	a1,0x1c
    80003808:	6545a583          	lw	a1,1620(a1) # 8001fe58 <sb+0x18>
    8000380c:	9dbd                	addw	a1,a1,a5
    8000380e:	4088                	lw	a0,0(s1)
    80003810:	fffff097          	auipc	ra,0xfffff
    80003814:	7ac080e7          	jalr	1964(ra) # 80002fbc <bread>
    80003818:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000381a:	05850593          	addi	a1,a0,88
    8000381e:	40dc                	lw	a5,4(s1)
    80003820:	8bbd                	andi	a5,a5,15
    80003822:	079a                	slli	a5,a5,0x6
    80003824:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003826:	00059783          	lh	a5,0(a1)
    8000382a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000382e:	00259783          	lh	a5,2(a1)
    80003832:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003836:	00459783          	lh	a5,4(a1)
    8000383a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000383e:	00659783          	lh	a5,6(a1)
    80003842:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003846:	459c                	lw	a5,8(a1)
    80003848:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000384a:	03400613          	li	a2,52
    8000384e:	05b1                	addi	a1,a1,12
    80003850:	05048513          	addi	a0,s1,80
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	518080e7          	jalr	1304(ra) # 80000d6c <memmove>
    brelse(bp);
    8000385c:	854a                	mv	a0,s2
    8000385e:	00000097          	auipc	ra,0x0
    80003862:	88e080e7          	jalr	-1906(ra) # 800030ec <brelse>
    ip->valid = 1;
    80003866:	4785                	li	a5,1
    80003868:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000386a:	04449783          	lh	a5,68(s1)
    8000386e:	fbb5                	bnez	a5,800037e2 <ilock+0x24>
      panic("ilock: no type");
    80003870:	00005517          	auipc	a0,0x5
    80003874:	d0850513          	addi	a0,a0,-760 # 80008578 <syscalls+0x188>
    80003878:	ffffd097          	auipc	ra,0xffffd
    8000387c:	cd0080e7          	jalr	-816(ra) # 80000548 <panic>

0000000080003880 <iunlock>:
{
    80003880:	1101                	addi	sp,sp,-32
    80003882:	ec06                	sd	ra,24(sp)
    80003884:	e822                	sd	s0,16(sp)
    80003886:	e426                	sd	s1,8(sp)
    80003888:	e04a                	sd	s2,0(sp)
    8000388a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000388c:	c905                	beqz	a0,800038bc <iunlock+0x3c>
    8000388e:	84aa                	mv	s1,a0
    80003890:	01050913          	addi	s2,a0,16
    80003894:	854a                	mv	a0,s2
    80003896:	00001097          	auipc	ra,0x1
    8000389a:	c80080e7          	jalr	-896(ra) # 80004516 <holdingsleep>
    8000389e:	cd19                	beqz	a0,800038bc <iunlock+0x3c>
    800038a0:	449c                	lw	a5,8(s1)
    800038a2:	00f05d63          	blez	a5,800038bc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800038a6:	854a                	mv	a0,s2
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	c2a080e7          	jalr	-982(ra) # 800044d2 <releasesleep>
}
    800038b0:	60e2                	ld	ra,24(sp)
    800038b2:	6442                	ld	s0,16(sp)
    800038b4:	64a2                	ld	s1,8(sp)
    800038b6:	6902                	ld	s2,0(sp)
    800038b8:	6105                	addi	sp,sp,32
    800038ba:	8082                	ret
    panic("iunlock");
    800038bc:	00005517          	auipc	a0,0x5
    800038c0:	ccc50513          	addi	a0,a0,-820 # 80008588 <syscalls+0x198>
    800038c4:	ffffd097          	auipc	ra,0xffffd
    800038c8:	c84080e7          	jalr	-892(ra) # 80000548 <panic>

00000000800038cc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800038cc:	7179                	addi	sp,sp,-48
    800038ce:	f406                	sd	ra,40(sp)
    800038d0:	f022                	sd	s0,32(sp)
    800038d2:	ec26                	sd	s1,24(sp)
    800038d4:	e84a                	sd	s2,16(sp)
    800038d6:	e44e                	sd	s3,8(sp)
    800038d8:	e052                	sd	s4,0(sp)
    800038da:	1800                	addi	s0,sp,48
    800038dc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038de:	05050493          	addi	s1,a0,80
    800038e2:	08050913          	addi	s2,a0,128
    800038e6:	a021                	j	800038ee <itrunc+0x22>
    800038e8:	0491                	addi	s1,s1,4
    800038ea:	01248d63          	beq	s1,s2,80003904 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ee:	408c                	lw	a1,0(s1)
    800038f0:	dde5                	beqz	a1,800038e8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038f2:	0009a503          	lw	a0,0(s3)
    800038f6:	00000097          	auipc	ra,0x0
    800038fa:	90c080e7          	jalr	-1780(ra) # 80003202 <bfree>
      ip->addrs[i] = 0;
    800038fe:	0004a023          	sw	zero,0(s1)
    80003902:	b7dd                	j	800038e8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003904:	0809a583          	lw	a1,128(s3)
    80003908:	e185                	bnez	a1,80003928 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000390a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000390e:	854e                	mv	a0,s3
    80003910:	00000097          	auipc	ra,0x0
    80003914:	de4080e7          	jalr	-540(ra) # 800036f4 <iupdate>
}
    80003918:	70a2                	ld	ra,40(sp)
    8000391a:	7402                	ld	s0,32(sp)
    8000391c:	64e2                	ld	s1,24(sp)
    8000391e:	6942                	ld	s2,16(sp)
    80003920:	69a2                	ld	s3,8(sp)
    80003922:	6a02                	ld	s4,0(sp)
    80003924:	6145                	addi	sp,sp,48
    80003926:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003928:	0009a503          	lw	a0,0(s3)
    8000392c:	fffff097          	auipc	ra,0xfffff
    80003930:	690080e7          	jalr	1680(ra) # 80002fbc <bread>
    80003934:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003936:	05850493          	addi	s1,a0,88
    8000393a:	45850913          	addi	s2,a0,1112
    8000393e:	a811                	j	80003952 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003940:	0009a503          	lw	a0,0(s3)
    80003944:	00000097          	auipc	ra,0x0
    80003948:	8be080e7          	jalr	-1858(ra) # 80003202 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000394c:	0491                	addi	s1,s1,4
    8000394e:	01248563          	beq	s1,s2,80003958 <itrunc+0x8c>
      if(a[j])
    80003952:	408c                	lw	a1,0(s1)
    80003954:	dde5                	beqz	a1,8000394c <itrunc+0x80>
    80003956:	b7ed                	j	80003940 <itrunc+0x74>
    brelse(bp);
    80003958:	8552                	mv	a0,s4
    8000395a:	fffff097          	auipc	ra,0xfffff
    8000395e:	792080e7          	jalr	1938(ra) # 800030ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003962:	0809a583          	lw	a1,128(s3)
    80003966:	0009a503          	lw	a0,0(s3)
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	898080e7          	jalr	-1896(ra) # 80003202 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003972:	0809a023          	sw	zero,128(s3)
    80003976:	bf51                	j	8000390a <itrunc+0x3e>

0000000080003978 <iput>:
{
    80003978:	1101                	addi	sp,sp,-32
    8000397a:	ec06                	sd	ra,24(sp)
    8000397c:	e822                	sd	s0,16(sp)
    8000397e:	e426                	sd	s1,8(sp)
    80003980:	e04a                	sd	s2,0(sp)
    80003982:	1000                	addi	s0,sp,32
    80003984:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003986:	0001c517          	auipc	a0,0x1c
    8000398a:	4da50513          	addi	a0,a0,1242 # 8001fe60 <icache>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	282080e7          	jalr	642(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003996:	4498                	lw	a4,8(s1)
    80003998:	4785                	li	a5,1
    8000399a:	02f70363          	beq	a4,a5,800039c0 <iput+0x48>
  ip->ref--;
    8000399e:	449c                	lw	a5,8(s1)
    800039a0:	37fd                	addiw	a5,a5,-1
    800039a2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800039a4:	0001c517          	auipc	a0,0x1c
    800039a8:	4bc50513          	addi	a0,a0,1212 # 8001fe60 <icache>
    800039ac:	ffffd097          	auipc	ra,0xffffd
    800039b0:	318080e7          	jalr	792(ra) # 80000cc4 <release>
}
    800039b4:	60e2                	ld	ra,24(sp)
    800039b6:	6442                	ld	s0,16(sp)
    800039b8:	64a2                	ld	s1,8(sp)
    800039ba:	6902                	ld	s2,0(sp)
    800039bc:	6105                	addi	sp,sp,32
    800039be:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800039c0:	40bc                	lw	a5,64(s1)
    800039c2:	dff1                	beqz	a5,8000399e <iput+0x26>
    800039c4:	04a49783          	lh	a5,74(s1)
    800039c8:	fbf9                	bnez	a5,8000399e <iput+0x26>
    acquiresleep(&ip->lock);
    800039ca:	01048913          	addi	s2,s1,16
    800039ce:	854a                	mv	a0,s2
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	aac080e7          	jalr	-1364(ra) # 8000447c <acquiresleep>
    release(&icache.lock);
    800039d8:	0001c517          	auipc	a0,0x1c
    800039dc:	48850513          	addi	a0,a0,1160 # 8001fe60 <icache>
    800039e0:	ffffd097          	auipc	ra,0xffffd
    800039e4:	2e4080e7          	jalr	740(ra) # 80000cc4 <release>
    itrunc(ip);
    800039e8:	8526                	mv	a0,s1
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	ee2080e7          	jalr	-286(ra) # 800038cc <itrunc>
    ip->type = 0;
    800039f2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	cfc080e7          	jalr	-772(ra) # 800036f4 <iupdate>
    ip->valid = 0;
    80003a00:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003a04:	854a                	mv	a0,s2
    80003a06:	00001097          	auipc	ra,0x1
    80003a0a:	acc080e7          	jalr	-1332(ra) # 800044d2 <releasesleep>
    acquire(&icache.lock);
    80003a0e:	0001c517          	auipc	a0,0x1c
    80003a12:	45250513          	addi	a0,a0,1106 # 8001fe60 <icache>
    80003a16:	ffffd097          	auipc	ra,0xffffd
    80003a1a:	1fa080e7          	jalr	506(ra) # 80000c10 <acquire>
    80003a1e:	b741                	j	8000399e <iput+0x26>

0000000080003a20 <iunlockput>:
{
    80003a20:	1101                	addi	sp,sp,-32
    80003a22:	ec06                	sd	ra,24(sp)
    80003a24:	e822                	sd	s0,16(sp)
    80003a26:	e426                	sd	s1,8(sp)
    80003a28:	1000                	addi	s0,sp,32
    80003a2a:	84aa                	mv	s1,a0
  iunlock(ip);
    80003a2c:	00000097          	auipc	ra,0x0
    80003a30:	e54080e7          	jalr	-428(ra) # 80003880 <iunlock>
  iput(ip);
    80003a34:	8526                	mv	a0,s1
    80003a36:	00000097          	auipc	ra,0x0
    80003a3a:	f42080e7          	jalr	-190(ra) # 80003978 <iput>
}
    80003a3e:	60e2                	ld	ra,24(sp)
    80003a40:	6442                	ld	s0,16(sp)
    80003a42:	64a2                	ld	s1,8(sp)
    80003a44:	6105                	addi	sp,sp,32
    80003a46:	8082                	ret

0000000080003a48 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a48:	1141                	addi	sp,sp,-16
    80003a4a:	e422                	sd	s0,8(sp)
    80003a4c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a4e:	411c                	lw	a5,0(a0)
    80003a50:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a52:	415c                	lw	a5,4(a0)
    80003a54:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a56:	04451783          	lh	a5,68(a0)
    80003a5a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a5e:	04a51783          	lh	a5,74(a0)
    80003a62:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a66:	04c56783          	lwu	a5,76(a0)
    80003a6a:	e99c                	sd	a5,16(a1)
}
    80003a6c:	6422                	ld	s0,8(sp)
    80003a6e:	0141                	addi	sp,sp,16
    80003a70:	8082                	ret

0000000080003a72 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a72:	457c                	lw	a5,76(a0)
    80003a74:	0ed7e963          	bltu	a5,a3,80003b66 <readi+0xf4>
{
    80003a78:	7159                	addi	sp,sp,-112
    80003a7a:	f486                	sd	ra,104(sp)
    80003a7c:	f0a2                	sd	s0,96(sp)
    80003a7e:	eca6                	sd	s1,88(sp)
    80003a80:	e8ca                	sd	s2,80(sp)
    80003a82:	e4ce                	sd	s3,72(sp)
    80003a84:	e0d2                	sd	s4,64(sp)
    80003a86:	fc56                	sd	s5,56(sp)
    80003a88:	f85a                	sd	s6,48(sp)
    80003a8a:	f45e                	sd	s7,40(sp)
    80003a8c:	f062                	sd	s8,32(sp)
    80003a8e:	ec66                	sd	s9,24(sp)
    80003a90:	e86a                	sd	s10,16(sp)
    80003a92:	e46e                	sd	s11,8(sp)
    80003a94:	1880                	addi	s0,sp,112
    80003a96:	8baa                	mv	s7,a0
    80003a98:	8c2e                	mv	s8,a1
    80003a9a:	8ab2                	mv	s5,a2
    80003a9c:	84b6                	mv	s1,a3
    80003a9e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003aa0:	9f35                	addw	a4,a4,a3
    return 0;
    80003aa2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003aa4:	0ad76063          	bltu	a4,a3,80003b44 <readi+0xd2>
  if(off + n > ip->size)
    80003aa8:	00e7f463          	bgeu	a5,a4,80003ab0 <readi+0x3e>
    n = ip->size - off;
    80003aac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ab0:	0a0b0963          	beqz	s6,80003b62 <readi+0xf0>
    80003ab4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ab6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003aba:	5cfd                	li	s9,-1
    80003abc:	a82d                	j	80003af6 <readi+0x84>
    80003abe:	020a1d93          	slli	s11,s4,0x20
    80003ac2:	020ddd93          	srli	s11,s11,0x20
    80003ac6:	05890613          	addi	a2,s2,88
    80003aca:	86ee                	mv	a3,s11
    80003acc:	963a                	add	a2,a2,a4
    80003ace:	85d6                	mv	a1,s5
    80003ad0:	8562                	mv	a0,s8
    80003ad2:	fffff097          	auipc	ra,0xfffff
    80003ad6:	ac8080e7          	jalr	-1336(ra) # 8000259a <either_copyout>
    80003ada:	05950d63          	beq	a0,s9,80003b34 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003ade:	854a                	mv	a0,s2
    80003ae0:	fffff097          	auipc	ra,0xfffff
    80003ae4:	60c080e7          	jalr	1548(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae8:	013a09bb          	addw	s3,s4,s3
    80003aec:	009a04bb          	addw	s1,s4,s1
    80003af0:	9aee                	add	s5,s5,s11
    80003af2:	0569f763          	bgeu	s3,s6,80003b40 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003af6:	000ba903          	lw	s2,0(s7)
    80003afa:	00a4d59b          	srliw	a1,s1,0xa
    80003afe:	855e                	mv	a0,s7
    80003b00:	00000097          	auipc	ra,0x0
    80003b04:	8b0080e7          	jalr	-1872(ra) # 800033b0 <bmap>
    80003b08:	0005059b          	sext.w	a1,a0
    80003b0c:	854a                	mv	a0,s2
    80003b0e:	fffff097          	auipc	ra,0xfffff
    80003b12:	4ae080e7          	jalr	1198(ra) # 80002fbc <bread>
    80003b16:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b18:	3ff4f713          	andi	a4,s1,1023
    80003b1c:	40ed07bb          	subw	a5,s10,a4
    80003b20:	413b06bb          	subw	a3,s6,s3
    80003b24:	8a3e                	mv	s4,a5
    80003b26:	2781                	sext.w	a5,a5
    80003b28:	0006861b          	sext.w	a2,a3
    80003b2c:	f8f679e3          	bgeu	a2,a5,80003abe <readi+0x4c>
    80003b30:	8a36                	mv	s4,a3
    80003b32:	b771                	j	80003abe <readi+0x4c>
      brelse(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	fffff097          	auipc	ra,0xfffff
    80003b3a:	5b6080e7          	jalr	1462(ra) # 800030ec <brelse>
      tot = -1;
    80003b3e:	59fd                	li	s3,-1
  }
  return tot;
    80003b40:	0009851b          	sext.w	a0,s3
}
    80003b44:	70a6                	ld	ra,104(sp)
    80003b46:	7406                	ld	s0,96(sp)
    80003b48:	64e6                	ld	s1,88(sp)
    80003b4a:	6946                	ld	s2,80(sp)
    80003b4c:	69a6                	ld	s3,72(sp)
    80003b4e:	6a06                	ld	s4,64(sp)
    80003b50:	7ae2                	ld	s5,56(sp)
    80003b52:	7b42                	ld	s6,48(sp)
    80003b54:	7ba2                	ld	s7,40(sp)
    80003b56:	7c02                	ld	s8,32(sp)
    80003b58:	6ce2                	ld	s9,24(sp)
    80003b5a:	6d42                	ld	s10,16(sp)
    80003b5c:	6da2                	ld	s11,8(sp)
    80003b5e:	6165                	addi	sp,sp,112
    80003b60:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b62:	89da                	mv	s3,s6
    80003b64:	bff1                	j	80003b40 <readi+0xce>
    return 0;
    80003b66:	4501                	li	a0,0
}
    80003b68:	8082                	ret

0000000080003b6a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b6a:	457c                	lw	a5,76(a0)
    80003b6c:	10d7e763          	bltu	a5,a3,80003c7a <writei+0x110>
{
    80003b70:	7159                	addi	sp,sp,-112
    80003b72:	f486                	sd	ra,104(sp)
    80003b74:	f0a2                	sd	s0,96(sp)
    80003b76:	eca6                	sd	s1,88(sp)
    80003b78:	e8ca                	sd	s2,80(sp)
    80003b7a:	e4ce                	sd	s3,72(sp)
    80003b7c:	e0d2                	sd	s4,64(sp)
    80003b7e:	fc56                	sd	s5,56(sp)
    80003b80:	f85a                	sd	s6,48(sp)
    80003b82:	f45e                	sd	s7,40(sp)
    80003b84:	f062                	sd	s8,32(sp)
    80003b86:	ec66                	sd	s9,24(sp)
    80003b88:	e86a                	sd	s10,16(sp)
    80003b8a:	e46e                	sd	s11,8(sp)
    80003b8c:	1880                	addi	s0,sp,112
    80003b8e:	8baa                	mv	s7,a0
    80003b90:	8c2e                	mv	s8,a1
    80003b92:	8ab2                	mv	s5,a2
    80003b94:	8936                	mv	s2,a3
    80003b96:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b98:	00e687bb          	addw	a5,a3,a4
    80003b9c:	0ed7e163          	bltu	a5,a3,80003c7e <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ba0:	00043737          	lui	a4,0x43
    80003ba4:	0cf76f63          	bltu	a4,a5,80003c82 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba8:	0a0b0863          	beqz	s6,80003c58 <writei+0xee>
    80003bac:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bae:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003bb2:	5cfd                	li	s9,-1
    80003bb4:	a091                	j	80003bf8 <writei+0x8e>
    80003bb6:	02099d93          	slli	s11,s3,0x20
    80003bba:	020ddd93          	srli	s11,s11,0x20
    80003bbe:	05848513          	addi	a0,s1,88
    80003bc2:	86ee                	mv	a3,s11
    80003bc4:	8656                	mv	a2,s5
    80003bc6:	85e2                	mv	a1,s8
    80003bc8:	953a                	add	a0,a0,a4
    80003bca:	fffff097          	auipc	ra,0xfffff
    80003bce:	a26080e7          	jalr	-1498(ra) # 800025f0 <either_copyin>
    80003bd2:	07950263          	beq	a0,s9,80003c36 <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003bd6:	8526                	mv	a0,s1
    80003bd8:	00000097          	auipc	ra,0x0
    80003bdc:	77c080e7          	jalr	1916(ra) # 80004354 <log_write>
    brelse(bp);
    80003be0:	8526                	mv	a0,s1
    80003be2:	fffff097          	auipc	ra,0xfffff
    80003be6:	50a080e7          	jalr	1290(ra) # 800030ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bea:	01498a3b          	addw	s4,s3,s4
    80003bee:	0129893b          	addw	s2,s3,s2
    80003bf2:	9aee                	add	s5,s5,s11
    80003bf4:	056a7763          	bgeu	s4,s6,80003c42 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bf8:	000ba483          	lw	s1,0(s7)
    80003bfc:	00a9559b          	srliw	a1,s2,0xa
    80003c00:	855e                	mv	a0,s7
    80003c02:	fffff097          	auipc	ra,0xfffff
    80003c06:	7ae080e7          	jalr	1966(ra) # 800033b0 <bmap>
    80003c0a:	0005059b          	sext.w	a1,a0
    80003c0e:	8526                	mv	a0,s1
    80003c10:	fffff097          	auipc	ra,0xfffff
    80003c14:	3ac080e7          	jalr	940(ra) # 80002fbc <bread>
    80003c18:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c1a:	3ff97713          	andi	a4,s2,1023
    80003c1e:	40ed07bb          	subw	a5,s10,a4
    80003c22:	414b06bb          	subw	a3,s6,s4
    80003c26:	89be                	mv	s3,a5
    80003c28:	2781                	sext.w	a5,a5
    80003c2a:	0006861b          	sext.w	a2,a3
    80003c2e:	f8f674e3          	bgeu	a2,a5,80003bb6 <writei+0x4c>
    80003c32:	89b6                	mv	s3,a3
    80003c34:	b749                	j	80003bb6 <writei+0x4c>
      brelse(bp);
    80003c36:	8526                	mv	a0,s1
    80003c38:	fffff097          	auipc	ra,0xfffff
    80003c3c:	4b4080e7          	jalr	1204(ra) # 800030ec <brelse>
      n = -1;
    80003c40:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80003c42:	04cba783          	lw	a5,76(s7)
    80003c46:	0127f463          	bgeu	a5,s2,80003c4e <writei+0xe4>
      ip->size = off;
    80003c4a:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c4e:	855e                	mv	a0,s7
    80003c50:	00000097          	auipc	ra,0x0
    80003c54:	aa4080e7          	jalr	-1372(ra) # 800036f4 <iupdate>
  }

  return n;
    80003c58:	000b051b          	sext.w	a0,s6
}
    80003c5c:	70a6                	ld	ra,104(sp)
    80003c5e:	7406                	ld	s0,96(sp)
    80003c60:	64e6                	ld	s1,88(sp)
    80003c62:	6946                	ld	s2,80(sp)
    80003c64:	69a6                	ld	s3,72(sp)
    80003c66:	6a06                	ld	s4,64(sp)
    80003c68:	7ae2                	ld	s5,56(sp)
    80003c6a:	7b42                	ld	s6,48(sp)
    80003c6c:	7ba2                	ld	s7,40(sp)
    80003c6e:	7c02                	ld	s8,32(sp)
    80003c70:	6ce2                	ld	s9,24(sp)
    80003c72:	6d42                	ld	s10,16(sp)
    80003c74:	6da2                	ld	s11,8(sp)
    80003c76:	6165                	addi	sp,sp,112
    80003c78:	8082                	ret
    return -1;
    80003c7a:	557d                	li	a0,-1
}
    80003c7c:	8082                	ret
    return -1;
    80003c7e:	557d                	li	a0,-1
    80003c80:	bff1                	j	80003c5c <writei+0xf2>
    return -1;
    80003c82:	557d                	li	a0,-1
    80003c84:	bfe1                	j	80003c5c <writei+0xf2>

0000000080003c86 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c86:	1141                	addi	sp,sp,-16
    80003c88:	e406                	sd	ra,8(sp)
    80003c8a:	e022                	sd	s0,0(sp)
    80003c8c:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c8e:	4639                	li	a2,14
    80003c90:	ffffd097          	auipc	ra,0xffffd
    80003c94:	158080e7          	jalr	344(ra) # 80000de8 <strncmp>
}
    80003c98:	60a2                	ld	ra,8(sp)
    80003c9a:	6402                	ld	s0,0(sp)
    80003c9c:	0141                	addi	sp,sp,16
    80003c9e:	8082                	ret

0000000080003ca0 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003ca0:	7139                	addi	sp,sp,-64
    80003ca2:	fc06                	sd	ra,56(sp)
    80003ca4:	f822                	sd	s0,48(sp)
    80003ca6:	f426                	sd	s1,40(sp)
    80003ca8:	f04a                	sd	s2,32(sp)
    80003caa:	ec4e                	sd	s3,24(sp)
    80003cac:	e852                	sd	s4,16(sp)
    80003cae:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003cb0:	04451703          	lh	a4,68(a0)
    80003cb4:	4785                	li	a5,1
    80003cb6:	00f71a63          	bne	a4,a5,80003cca <dirlookup+0x2a>
    80003cba:	892a                	mv	s2,a0
    80003cbc:	89ae                	mv	s3,a1
    80003cbe:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc0:	457c                	lw	a5,76(a0)
    80003cc2:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003cc4:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cc6:	e79d                	bnez	a5,80003cf4 <dirlookup+0x54>
    80003cc8:	a8a5                	j	80003d40 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003cca:	00005517          	auipc	a0,0x5
    80003cce:	8c650513          	addi	a0,a0,-1850 # 80008590 <syscalls+0x1a0>
    80003cd2:	ffffd097          	auipc	ra,0xffffd
    80003cd6:	876080e7          	jalr	-1930(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003cda:	00005517          	auipc	a0,0x5
    80003cde:	8ce50513          	addi	a0,a0,-1842 # 800085a8 <syscalls+0x1b8>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	866080e7          	jalr	-1946(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cea:	24c1                	addiw	s1,s1,16
    80003cec:	04c92783          	lw	a5,76(s2)
    80003cf0:	04f4f763          	bgeu	s1,a5,80003d3e <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cf4:	4741                	li	a4,16
    80003cf6:	86a6                	mv	a3,s1
    80003cf8:	fc040613          	addi	a2,s0,-64
    80003cfc:	4581                	li	a1,0
    80003cfe:	854a                	mv	a0,s2
    80003d00:	00000097          	auipc	ra,0x0
    80003d04:	d72080e7          	jalr	-654(ra) # 80003a72 <readi>
    80003d08:	47c1                	li	a5,16
    80003d0a:	fcf518e3          	bne	a0,a5,80003cda <dirlookup+0x3a>
    if(de.inum == 0)
    80003d0e:	fc045783          	lhu	a5,-64(s0)
    80003d12:	dfe1                	beqz	a5,80003cea <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003d14:	fc240593          	addi	a1,s0,-62
    80003d18:	854e                	mv	a0,s3
    80003d1a:	00000097          	auipc	ra,0x0
    80003d1e:	f6c080e7          	jalr	-148(ra) # 80003c86 <namecmp>
    80003d22:	f561                	bnez	a0,80003cea <dirlookup+0x4a>
      if(poff)
    80003d24:	000a0463          	beqz	s4,80003d2c <dirlookup+0x8c>
        *poff = off;
    80003d28:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003d2c:	fc045583          	lhu	a1,-64(s0)
    80003d30:	00092503          	lw	a0,0(s2)
    80003d34:	fffff097          	auipc	ra,0xfffff
    80003d38:	756080e7          	jalr	1878(ra) # 8000348a <iget>
    80003d3c:	a011                	j	80003d40 <dirlookup+0xa0>
  return 0;
    80003d3e:	4501                	li	a0,0
}
    80003d40:	70e2                	ld	ra,56(sp)
    80003d42:	7442                	ld	s0,48(sp)
    80003d44:	74a2                	ld	s1,40(sp)
    80003d46:	7902                	ld	s2,32(sp)
    80003d48:	69e2                	ld	s3,24(sp)
    80003d4a:	6a42                	ld	s4,16(sp)
    80003d4c:	6121                	addi	sp,sp,64
    80003d4e:	8082                	ret

0000000080003d50 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d50:	711d                	addi	sp,sp,-96
    80003d52:	ec86                	sd	ra,88(sp)
    80003d54:	e8a2                	sd	s0,80(sp)
    80003d56:	e4a6                	sd	s1,72(sp)
    80003d58:	e0ca                	sd	s2,64(sp)
    80003d5a:	fc4e                	sd	s3,56(sp)
    80003d5c:	f852                	sd	s4,48(sp)
    80003d5e:	f456                	sd	s5,40(sp)
    80003d60:	f05a                	sd	s6,32(sp)
    80003d62:	ec5e                	sd	s7,24(sp)
    80003d64:	e862                	sd	s8,16(sp)
    80003d66:	e466                	sd	s9,8(sp)
    80003d68:	1080                	addi	s0,sp,96
    80003d6a:	84aa                	mv	s1,a0
    80003d6c:	8b2e                	mv	s6,a1
    80003d6e:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d70:	00054703          	lbu	a4,0(a0)
    80003d74:	02f00793          	li	a5,47
    80003d78:	02f70363          	beq	a4,a5,80003d9e <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d7c:	ffffe097          	auipc	ra,0xffffe
    80003d80:	dac080e7          	jalr	-596(ra) # 80001b28 <myproc>
    80003d84:	15053503          	ld	a0,336(a0)
    80003d88:	00000097          	auipc	ra,0x0
    80003d8c:	9f8080e7          	jalr	-1544(ra) # 80003780 <idup>
    80003d90:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d92:	02f00913          	li	s2,47
  len = path - s;
    80003d96:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d98:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d9a:	4c05                	li	s8,1
    80003d9c:	a865                	j	80003e54 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d9e:	4585                	li	a1,1
    80003da0:	4505                	li	a0,1
    80003da2:	fffff097          	auipc	ra,0xfffff
    80003da6:	6e8080e7          	jalr	1768(ra) # 8000348a <iget>
    80003daa:	89aa                	mv	s3,a0
    80003dac:	b7dd                	j	80003d92 <namex+0x42>
      iunlockput(ip);
    80003dae:	854e                	mv	a0,s3
    80003db0:	00000097          	auipc	ra,0x0
    80003db4:	c70080e7          	jalr	-912(ra) # 80003a20 <iunlockput>
      return 0;
    80003db8:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003dba:	854e                	mv	a0,s3
    80003dbc:	60e6                	ld	ra,88(sp)
    80003dbe:	6446                	ld	s0,80(sp)
    80003dc0:	64a6                	ld	s1,72(sp)
    80003dc2:	6906                	ld	s2,64(sp)
    80003dc4:	79e2                	ld	s3,56(sp)
    80003dc6:	7a42                	ld	s4,48(sp)
    80003dc8:	7aa2                	ld	s5,40(sp)
    80003dca:	7b02                	ld	s6,32(sp)
    80003dcc:	6be2                	ld	s7,24(sp)
    80003dce:	6c42                	ld	s8,16(sp)
    80003dd0:	6ca2                	ld	s9,8(sp)
    80003dd2:	6125                	addi	sp,sp,96
    80003dd4:	8082                	ret
      iunlock(ip);
    80003dd6:	854e                	mv	a0,s3
    80003dd8:	00000097          	auipc	ra,0x0
    80003ddc:	aa8080e7          	jalr	-1368(ra) # 80003880 <iunlock>
      return ip;
    80003de0:	bfe9                	j	80003dba <namex+0x6a>
      iunlockput(ip);
    80003de2:	854e                	mv	a0,s3
    80003de4:	00000097          	auipc	ra,0x0
    80003de8:	c3c080e7          	jalr	-964(ra) # 80003a20 <iunlockput>
      return 0;
    80003dec:	89d2                	mv	s3,s4
    80003dee:	b7f1                	j	80003dba <namex+0x6a>
  len = path - s;
    80003df0:	40b48633          	sub	a2,s1,a1
    80003df4:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003df8:	094cd463          	bge	s9,s4,80003e80 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003dfc:	4639                	li	a2,14
    80003dfe:	8556                	mv	a0,s5
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	f6c080e7          	jalr	-148(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003e08:	0004c783          	lbu	a5,0(s1)
    80003e0c:	01279763          	bne	a5,s2,80003e1a <namex+0xca>
    path++;
    80003e10:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e12:	0004c783          	lbu	a5,0(s1)
    80003e16:	ff278de3          	beq	a5,s2,80003e10 <namex+0xc0>
    ilock(ip);
    80003e1a:	854e                	mv	a0,s3
    80003e1c:	00000097          	auipc	ra,0x0
    80003e20:	9a2080e7          	jalr	-1630(ra) # 800037be <ilock>
    if(ip->type != T_DIR){
    80003e24:	04499783          	lh	a5,68(s3)
    80003e28:	f98793e3          	bne	a5,s8,80003dae <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003e2c:	000b0563          	beqz	s6,80003e36 <namex+0xe6>
    80003e30:	0004c783          	lbu	a5,0(s1)
    80003e34:	d3cd                	beqz	a5,80003dd6 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e36:	865e                	mv	a2,s7
    80003e38:	85d6                	mv	a1,s5
    80003e3a:	854e                	mv	a0,s3
    80003e3c:	00000097          	auipc	ra,0x0
    80003e40:	e64080e7          	jalr	-412(ra) # 80003ca0 <dirlookup>
    80003e44:	8a2a                	mv	s4,a0
    80003e46:	dd51                	beqz	a0,80003de2 <namex+0x92>
    iunlockput(ip);
    80003e48:	854e                	mv	a0,s3
    80003e4a:	00000097          	auipc	ra,0x0
    80003e4e:	bd6080e7          	jalr	-1066(ra) # 80003a20 <iunlockput>
    ip = next;
    80003e52:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e54:	0004c783          	lbu	a5,0(s1)
    80003e58:	05279763          	bne	a5,s2,80003ea6 <namex+0x156>
    path++;
    80003e5c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e5e:	0004c783          	lbu	a5,0(s1)
    80003e62:	ff278de3          	beq	a5,s2,80003e5c <namex+0x10c>
  if(*path == 0)
    80003e66:	c79d                	beqz	a5,80003e94 <namex+0x144>
    path++;
    80003e68:	85a6                	mv	a1,s1
  len = path - s;
    80003e6a:	8a5e                	mv	s4,s7
    80003e6c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e6e:	01278963          	beq	a5,s2,80003e80 <namex+0x130>
    80003e72:	dfbd                	beqz	a5,80003df0 <namex+0xa0>
    path++;
    80003e74:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e76:	0004c783          	lbu	a5,0(s1)
    80003e7a:	ff279ce3          	bne	a5,s2,80003e72 <namex+0x122>
    80003e7e:	bf8d                	j	80003df0 <namex+0xa0>
    memmove(name, s, len);
    80003e80:	2601                	sext.w	a2,a2
    80003e82:	8556                	mv	a0,s5
    80003e84:	ffffd097          	auipc	ra,0xffffd
    80003e88:	ee8080e7          	jalr	-280(ra) # 80000d6c <memmove>
    name[len] = 0;
    80003e8c:	9a56                	add	s4,s4,s5
    80003e8e:	000a0023          	sb	zero,0(s4)
    80003e92:	bf9d                	j	80003e08 <namex+0xb8>
  if(nameiparent){
    80003e94:	f20b03e3          	beqz	s6,80003dba <namex+0x6a>
    iput(ip);
    80003e98:	854e                	mv	a0,s3
    80003e9a:	00000097          	auipc	ra,0x0
    80003e9e:	ade080e7          	jalr	-1314(ra) # 80003978 <iput>
    return 0;
    80003ea2:	4981                	li	s3,0
    80003ea4:	bf19                	j	80003dba <namex+0x6a>
  if(*path == 0)
    80003ea6:	d7fd                	beqz	a5,80003e94 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003ea8:	0004c783          	lbu	a5,0(s1)
    80003eac:	85a6                	mv	a1,s1
    80003eae:	b7d1                	j	80003e72 <namex+0x122>

0000000080003eb0 <dirlink>:
{
    80003eb0:	7139                	addi	sp,sp,-64
    80003eb2:	fc06                	sd	ra,56(sp)
    80003eb4:	f822                	sd	s0,48(sp)
    80003eb6:	f426                	sd	s1,40(sp)
    80003eb8:	f04a                	sd	s2,32(sp)
    80003eba:	ec4e                	sd	s3,24(sp)
    80003ebc:	e852                	sd	s4,16(sp)
    80003ebe:	0080                	addi	s0,sp,64
    80003ec0:	892a                	mv	s2,a0
    80003ec2:	8a2e                	mv	s4,a1
    80003ec4:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003ec6:	4601                	li	a2,0
    80003ec8:	00000097          	auipc	ra,0x0
    80003ecc:	dd8080e7          	jalr	-552(ra) # 80003ca0 <dirlookup>
    80003ed0:	e93d                	bnez	a0,80003f46 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed2:	04c92483          	lw	s1,76(s2)
    80003ed6:	c49d                	beqz	s1,80003f04 <dirlink+0x54>
    80003ed8:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eda:	4741                	li	a4,16
    80003edc:	86a6                	mv	a3,s1
    80003ede:	fc040613          	addi	a2,s0,-64
    80003ee2:	4581                	li	a1,0
    80003ee4:	854a                	mv	a0,s2
    80003ee6:	00000097          	auipc	ra,0x0
    80003eea:	b8c080e7          	jalr	-1140(ra) # 80003a72 <readi>
    80003eee:	47c1                	li	a5,16
    80003ef0:	06f51163          	bne	a0,a5,80003f52 <dirlink+0xa2>
    if(de.inum == 0)
    80003ef4:	fc045783          	lhu	a5,-64(s0)
    80003ef8:	c791                	beqz	a5,80003f04 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003efa:	24c1                	addiw	s1,s1,16
    80003efc:	04c92783          	lw	a5,76(s2)
    80003f00:	fcf4ede3          	bltu	s1,a5,80003eda <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003f04:	4639                	li	a2,14
    80003f06:	85d2                	mv	a1,s4
    80003f08:	fc240513          	addi	a0,s0,-62
    80003f0c:	ffffd097          	auipc	ra,0xffffd
    80003f10:	f18080e7          	jalr	-232(ra) # 80000e24 <strncpy>
  de.inum = inum;
    80003f14:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f18:	4741                	li	a4,16
    80003f1a:	86a6                	mv	a3,s1
    80003f1c:	fc040613          	addi	a2,s0,-64
    80003f20:	4581                	li	a1,0
    80003f22:	854a                	mv	a0,s2
    80003f24:	00000097          	auipc	ra,0x0
    80003f28:	c46080e7          	jalr	-954(ra) # 80003b6a <writei>
    80003f2c:	872a                	mv	a4,a0
    80003f2e:	47c1                	li	a5,16
  return 0;
    80003f30:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003f32:	02f71863          	bne	a4,a5,80003f62 <dirlink+0xb2>
}
    80003f36:	70e2                	ld	ra,56(sp)
    80003f38:	7442                	ld	s0,48(sp)
    80003f3a:	74a2                	ld	s1,40(sp)
    80003f3c:	7902                	ld	s2,32(sp)
    80003f3e:	69e2                	ld	s3,24(sp)
    80003f40:	6a42                	ld	s4,16(sp)
    80003f42:	6121                	addi	sp,sp,64
    80003f44:	8082                	ret
    iput(ip);
    80003f46:	00000097          	auipc	ra,0x0
    80003f4a:	a32080e7          	jalr	-1486(ra) # 80003978 <iput>
    return -1;
    80003f4e:	557d                	li	a0,-1
    80003f50:	b7dd                	j	80003f36 <dirlink+0x86>
      panic("dirlink read");
    80003f52:	00004517          	auipc	a0,0x4
    80003f56:	66650513          	addi	a0,a0,1638 # 800085b8 <syscalls+0x1c8>
    80003f5a:	ffffc097          	auipc	ra,0xffffc
    80003f5e:	5ee080e7          	jalr	1518(ra) # 80000548 <panic>
    panic("dirlink");
    80003f62:	00004517          	auipc	a0,0x4
    80003f66:	77650513          	addi	a0,a0,1910 # 800086d8 <syscalls+0x2e8>
    80003f6a:	ffffc097          	auipc	ra,0xffffc
    80003f6e:	5de080e7          	jalr	1502(ra) # 80000548 <panic>

0000000080003f72 <namei>:

struct inode*
namei(char *path)
{
    80003f72:	1101                	addi	sp,sp,-32
    80003f74:	ec06                	sd	ra,24(sp)
    80003f76:	e822                	sd	s0,16(sp)
    80003f78:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f7a:	fe040613          	addi	a2,s0,-32
    80003f7e:	4581                	li	a1,0
    80003f80:	00000097          	auipc	ra,0x0
    80003f84:	dd0080e7          	jalr	-560(ra) # 80003d50 <namex>
}
    80003f88:	60e2                	ld	ra,24(sp)
    80003f8a:	6442                	ld	s0,16(sp)
    80003f8c:	6105                	addi	sp,sp,32
    80003f8e:	8082                	ret

0000000080003f90 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f90:	1141                	addi	sp,sp,-16
    80003f92:	e406                	sd	ra,8(sp)
    80003f94:	e022                	sd	s0,0(sp)
    80003f96:	0800                	addi	s0,sp,16
    80003f98:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f9a:	4585                	li	a1,1
    80003f9c:	00000097          	auipc	ra,0x0
    80003fa0:	db4080e7          	jalr	-588(ra) # 80003d50 <namex>
}
    80003fa4:	60a2                	ld	ra,8(sp)
    80003fa6:	6402                	ld	s0,0(sp)
    80003fa8:	0141                	addi	sp,sp,16
    80003faa:	8082                	ret

0000000080003fac <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003fac:	1101                	addi	sp,sp,-32
    80003fae:	ec06                	sd	ra,24(sp)
    80003fb0:	e822                	sd	s0,16(sp)
    80003fb2:	e426                	sd	s1,8(sp)
    80003fb4:	e04a                	sd	s2,0(sp)
    80003fb6:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003fb8:	0001e917          	auipc	s2,0x1e
    80003fbc:	95090913          	addi	s2,s2,-1712 # 80021908 <log>
    80003fc0:	01892583          	lw	a1,24(s2)
    80003fc4:	02892503          	lw	a0,40(s2)
    80003fc8:	fffff097          	auipc	ra,0xfffff
    80003fcc:	ff4080e7          	jalr	-12(ra) # 80002fbc <bread>
    80003fd0:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003fd2:	02c92683          	lw	a3,44(s2)
    80003fd6:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003fd8:	02d05763          	blez	a3,80004006 <write_head+0x5a>
    80003fdc:	0001e797          	auipc	a5,0x1e
    80003fe0:	95c78793          	addi	a5,a5,-1700 # 80021938 <log+0x30>
    80003fe4:	05c50713          	addi	a4,a0,92
    80003fe8:	36fd                	addiw	a3,a3,-1
    80003fea:	1682                	slli	a3,a3,0x20
    80003fec:	9281                	srli	a3,a3,0x20
    80003fee:	068a                	slli	a3,a3,0x2
    80003ff0:	0001e617          	auipc	a2,0x1e
    80003ff4:	94c60613          	addi	a2,a2,-1716 # 8002193c <log+0x34>
    80003ff8:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003ffa:	4390                	lw	a2,0(a5)
    80003ffc:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003ffe:	0791                	addi	a5,a5,4
    80004000:	0711                	addi	a4,a4,4
    80004002:	fed79ce3          	bne	a5,a3,80003ffa <write_head+0x4e>
  }
  bwrite(buf);
    80004006:	8526                	mv	a0,s1
    80004008:	fffff097          	auipc	ra,0xfffff
    8000400c:	0a6080e7          	jalr	166(ra) # 800030ae <bwrite>
  brelse(buf);
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	0da080e7          	jalr	218(ra) # 800030ec <brelse>
}
    8000401a:	60e2                	ld	ra,24(sp)
    8000401c:	6442                	ld	s0,16(sp)
    8000401e:	64a2                	ld	s1,8(sp)
    80004020:	6902                	ld	s2,0(sp)
    80004022:	6105                	addi	sp,sp,32
    80004024:	8082                	ret

0000000080004026 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004026:	0001e797          	auipc	a5,0x1e
    8000402a:	90e7a783          	lw	a5,-1778(a5) # 80021934 <log+0x2c>
    8000402e:	0af05663          	blez	a5,800040da <install_trans+0xb4>
{
    80004032:	7139                	addi	sp,sp,-64
    80004034:	fc06                	sd	ra,56(sp)
    80004036:	f822                	sd	s0,48(sp)
    80004038:	f426                	sd	s1,40(sp)
    8000403a:	f04a                	sd	s2,32(sp)
    8000403c:	ec4e                	sd	s3,24(sp)
    8000403e:	e852                	sd	s4,16(sp)
    80004040:	e456                	sd	s5,8(sp)
    80004042:	0080                	addi	s0,sp,64
    80004044:	0001ea97          	auipc	s5,0x1e
    80004048:	8f4a8a93          	addi	s5,s5,-1804 # 80021938 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000404c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000404e:	0001e997          	auipc	s3,0x1e
    80004052:	8ba98993          	addi	s3,s3,-1862 # 80021908 <log>
    80004056:	0189a583          	lw	a1,24(s3)
    8000405a:	014585bb          	addw	a1,a1,s4
    8000405e:	2585                	addiw	a1,a1,1
    80004060:	0289a503          	lw	a0,40(s3)
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	f58080e7          	jalr	-168(ra) # 80002fbc <bread>
    8000406c:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    8000406e:	000aa583          	lw	a1,0(s5)
    80004072:	0289a503          	lw	a0,40(s3)
    80004076:	fffff097          	auipc	ra,0xfffff
    8000407a:	f46080e7          	jalr	-186(ra) # 80002fbc <bread>
    8000407e:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004080:	40000613          	li	a2,1024
    80004084:	05890593          	addi	a1,s2,88
    80004088:	05850513          	addi	a0,a0,88
    8000408c:	ffffd097          	auipc	ra,0xffffd
    80004090:	ce0080e7          	jalr	-800(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    80004094:	8526                	mv	a0,s1
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	018080e7          	jalr	24(ra) # 800030ae <bwrite>
    bunpin(dbuf);
    8000409e:	8526                	mv	a0,s1
    800040a0:	fffff097          	auipc	ra,0xfffff
    800040a4:	126080e7          	jalr	294(ra) # 800031c6 <bunpin>
    brelse(lbuf);
    800040a8:	854a                	mv	a0,s2
    800040aa:	fffff097          	auipc	ra,0xfffff
    800040ae:	042080e7          	jalr	66(ra) # 800030ec <brelse>
    brelse(dbuf);
    800040b2:	8526                	mv	a0,s1
    800040b4:	fffff097          	auipc	ra,0xfffff
    800040b8:	038080e7          	jalr	56(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800040bc:	2a05                	addiw	s4,s4,1
    800040be:	0a91                	addi	s5,s5,4
    800040c0:	02c9a783          	lw	a5,44(s3)
    800040c4:	f8fa49e3          	blt	s4,a5,80004056 <install_trans+0x30>
}
    800040c8:	70e2                	ld	ra,56(sp)
    800040ca:	7442                	ld	s0,48(sp)
    800040cc:	74a2                	ld	s1,40(sp)
    800040ce:	7902                	ld	s2,32(sp)
    800040d0:	69e2                	ld	s3,24(sp)
    800040d2:	6a42                	ld	s4,16(sp)
    800040d4:	6aa2                	ld	s5,8(sp)
    800040d6:	6121                	addi	sp,sp,64
    800040d8:	8082                	ret
    800040da:	8082                	ret

00000000800040dc <initlog>:
{
    800040dc:	7179                	addi	sp,sp,-48
    800040de:	f406                	sd	ra,40(sp)
    800040e0:	f022                	sd	s0,32(sp)
    800040e2:	ec26                	sd	s1,24(sp)
    800040e4:	e84a                	sd	s2,16(sp)
    800040e6:	e44e                	sd	s3,8(sp)
    800040e8:	1800                	addi	s0,sp,48
    800040ea:	892a                	mv	s2,a0
    800040ec:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040ee:	0001e497          	auipc	s1,0x1e
    800040f2:	81a48493          	addi	s1,s1,-2022 # 80021908 <log>
    800040f6:	00004597          	auipc	a1,0x4
    800040fa:	4d258593          	addi	a1,a1,1234 # 800085c8 <syscalls+0x1d8>
    800040fe:	8526                	mv	a0,s1
    80004100:	ffffd097          	auipc	ra,0xffffd
    80004104:	a80080e7          	jalr	-1408(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    80004108:	0149a583          	lw	a1,20(s3)
    8000410c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000410e:	0109a783          	lw	a5,16(s3)
    80004112:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004114:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004118:	854a                	mv	a0,s2
    8000411a:	fffff097          	auipc	ra,0xfffff
    8000411e:	ea2080e7          	jalr	-350(ra) # 80002fbc <bread>
  log.lh.n = lh->n;
    80004122:	4d3c                	lw	a5,88(a0)
    80004124:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004126:	02f05563          	blez	a5,80004150 <initlog+0x74>
    8000412a:	05c50713          	addi	a4,a0,92
    8000412e:	0001e697          	auipc	a3,0x1e
    80004132:	80a68693          	addi	a3,a3,-2038 # 80021938 <log+0x30>
    80004136:	37fd                	addiw	a5,a5,-1
    80004138:	1782                	slli	a5,a5,0x20
    8000413a:	9381                	srli	a5,a5,0x20
    8000413c:	078a                	slli	a5,a5,0x2
    8000413e:	06050613          	addi	a2,a0,96
    80004142:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004144:	4310                	lw	a2,0(a4)
    80004146:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004148:	0711                	addi	a4,a4,4
    8000414a:	0691                	addi	a3,a3,4
    8000414c:	fef71ce3          	bne	a4,a5,80004144 <initlog+0x68>
  brelse(buf);
    80004150:	fffff097          	auipc	ra,0xfffff
    80004154:	f9c080e7          	jalr	-100(ra) # 800030ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004158:	00000097          	auipc	ra,0x0
    8000415c:	ece080e7          	jalr	-306(ra) # 80004026 <install_trans>
  log.lh.n = 0;
    80004160:	0001d797          	auipc	a5,0x1d
    80004164:	7c07aa23          	sw	zero,2004(a5) # 80021934 <log+0x2c>
  write_head(); // clear the log
    80004168:	00000097          	auipc	ra,0x0
    8000416c:	e44080e7          	jalr	-444(ra) # 80003fac <write_head>
}
    80004170:	70a2                	ld	ra,40(sp)
    80004172:	7402                	ld	s0,32(sp)
    80004174:	64e2                	ld	s1,24(sp)
    80004176:	6942                	ld	s2,16(sp)
    80004178:	69a2                	ld	s3,8(sp)
    8000417a:	6145                	addi	sp,sp,48
    8000417c:	8082                	ret

000000008000417e <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000417e:	1101                	addi	sp,sp,-32
    80004180:	ec06                	sd	ra,24(sp)
    80004182:	e822                	sd	s0,16(sp)
    80004184:	e426                	sd	s1,8(sp)
    80004186:	e04a                	sd	s2,0(sp)
    80004188:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000418a:	0001d517          	auipc	a0,0x1d
    8000418e:	77e50513          	addi	a0,a0,1918 # 80021908 <log>
    80004192:	ffffd097          	auipc	ra,0xffffd
    80004196:	a7e080e7          	jalr	-1410(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    8000419a:	0001d497          	auipc	s1,0x1d
    8000419e:	76e48493          	addi	s1,s1,1902 # 80021908 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041a2:	4979                	li	s2,30
    800041a4:	a039                	j	800041b2 <begin_op+0x34>
      sleep(&log, &log.lock);
    800041a6:	85a6                	mv	a1,s1
    800041a8:	8526                	mv	a0,s1
    800041aa:	ffffe097          	auipc	ra,0xffffe
    800041ae:	18e080e7          	jalr	398(ra) # 80002338 <sleep>
    if(log.committing){
    800041b2:	50dc                	lw	a5,36(s1)
    800041b4:	fbed                	bnez	a5,800041a6 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800041b6:	509c                	lw	a5,32(s1)
    800041b8:	0017871b          	addiw	a4,a5,1
    800041bc:	0007069b          	sext.w	a3,a4
    800041c0:	0027179b          	slliw	a5,a4,0x2
    800041c4:	9fb9                	addw	a5,a5,a4
    800041c6:	0017979b          	slliw	a5,a5,0x1
    800041ca:	54d8                	lw	a4,44(s1)
    800041cc:	9fb9                	addw	a5,a5,a4
    800041ce:	00f95963          	bge	s2,a5,800041e0 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800041d2:	85a6                	mv	a1,s1
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffe097          	auipc	ra,0xffffe
    800041da:	162080e7          	jalr	354(ra) # 80002338 <sleep>
    800041de:	bfd1                	j	800041b2 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041e0:	0001d517          	auipc	a0,0x1d
    800041e4:	72850513          	addi	a0,a0,1832 # 80021908 <log>
    800041e8:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041ea:	ffffd097          	auipc	ra,0xffffd
    800041ee:	ada080e7          	jalr	-1318(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800041f2:	60e2                	ld	ra,24(sp)
    800041f4:	6442                	ld	s0,16(sp)
    800041f6:	64a2                	ld	s1,8(sp)
    800041f8:	6902                	ld	s2,0(sp)
    800041fa:	6105                	addi	sp,sp,32
    800041fc:	8082                	ret

00000000800041fe <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041fe:	7139                	addi	sp,sp,-64
    80004200:	fc06                	sd	ra,56(sp)
    80004202:	f822                	sd	s0,48(sp)
    80004204:	f426                	sd	s1,40(sp)
    80004206:	f04a                	sd	s2,32(sp)
    80004208:	ec4e                	sd	s3,24(sp)
    8000420a:	e852                	sd	s4,16(sp)
    8000420c:	e456                	sd	s5,8(sp)
    8000420e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004210:	0001d497          	auipc	s1,0x1d
    80004214:	6f848493          	addi	s1,s1,1784 # 80021908 <log>
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	9f6080e7          	jalr	-1546(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004222:	509c                	lw	a5,32(s1)
    80004224:	37fd                	addiw	a5,a5,-1
    80004226:	0007891b          	sext.w	s2,a5
    8000422a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000422c:	50dc                	lw	a5,36(s1)
    8000422e:	efb9                	bnez	a5,8000428c <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004230:	06091663          	bnez	s2,8000429c <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004234:	0001d497          	auipc	s1,0x1d
    80004238:	6d448493          	addi	s1,s1,1748 # 80021908 <log>
    8000423c:	4785                	li	a5,1
    8000423e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004240:	8526                	mv	a0,s1
    80004242:	ffffd097          	auipc	ra,0xffffd
    80004246:	a82080e7          	jalr	-1406(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000424a:	54dc                	lw	a5,44(s1)
    8000424c:	06f04763          	bgtz	a5,800042ba <end_op+0xbc>
    acquire(&log.lock);
    80004250:	0001d497          	auipc	s1,0x1d
    80004254:	6b848493          	addi	s1,s1,1720 # 80021908 <log>
    80004258:	8526                	mv	a0,s1
    8000425a:	ffffd097          	auipc	ra,0xffffd
    8000425e:	9b6080e7          	jalr	-1610(ra) # 80000c10 <acquire>
    log.committing = 0;
    80004262:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004266:	8526                	mv	a0,s1
    80004268:	ffffe097          	auipc	ra,0xffffe
    8000426c:	256080e7          	jalr	598(ra) # 800024be <wakeup>
    release(&log.lock);
    80004270:	8526                	mv	a0,s1
    80004272:	ffffd097          	auipc	ra,0xffffd
    80004276:	a52080e7          	jalr	-1454(ra) # 80000cc4 <release>
}
    8000427a:	70e2                	ld	ra,56(sp)
    8000427c:	7442                	ld	s0,48(sp)
    8000427e:	74a2                	ld	s1,40(sp)
    80004280:	7902                	ld	s2,32(sp)
    80004282:	69e2                	ld	s3,24(sp)
    80004284:	6a42                	ld	s4,16(sp)
    80004286:	6aa2                	ld	s5,8(sp)
    80004288:	6121                	addi	sp,sp,64
    8000428a:	8082                	ret
    panic("log.committing");
    8000428c:	00004517          	auipc	a0,0x4
    80004290:	34450513          	addi	a0,a0,836 # 800085d0 <syscalls+0x1e0>
    80004294:	ffffc097          	auipc	ra,0xffffc
    80004298:	2b4080e7          	jalr	692(ra) # 80000548 <panic>
    wakeup(&log);
    8000429c:	0001d497          	auipc	s1,0x1d
    800042a0:	66c48493          	addi	s1,s1,1644 # 80021908 <log>
    800042a4:	8526                	mv	a0,s1
    800042a6:	ffffe097          	auipc	ra,0xffffe
    800042aa:	218080e7          	jalr	536(ra) # 800024be <wakeup>
  release(&log.lock);
    800042ae:	8526                	mv	a0,s1
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	a14080e7          	jalr	-1516(ra) # 80000cc4 <release>
  if(do_commit){
    800042b8:	b7c9                	j	8000427a <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042ba:	0001da97          	auipc	s5,0x1d
    800042be:	67ea8a93          	addi	s5,s5,1662 # 80021938 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800042c2:	0001da17          	auipc	s4,0x1d
    800042c6:	646a0a13          	addi	s4,s4,1606 # 80021908 <log>
    800042ca:	018a2583          	lw	a1,24(s4)
    800042ce:	012585bb          	addw	a1,a1,s2
    800042d2:	2585                	addiw	a1,a1,1
    800042d4:	028a2503          	lw	a0,40(s4)
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	ce4080e7          	jalr	-796(ra) # 80002fbc <bread>
    800042e0:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042e2:	000aa583          	lw	a1,0(s5)
    800042e6:	028a2503          	lw	a0,40(s4)
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	cd2080e7          	jalr	-814(ra) # 80002fbc <bread>
    800042f2:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042f4:	40000613          	li	a2,1024
    800042f8:	05850593          	addi	a1,a0,88
    800042fc:	05848513          	addi	a0,s1,88
    80004300:	ffffd097          	auipc	ra,0xffffd
    80004304:	a6c080e7          	jalr	-1428(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    80004308:	8526                	mv	a0,s1
    8000430a:	fffff097          	auipc	ra,0xfffff
    8000430e:	da4080e7          	jalr	-604(ra) # 800030ae <bwrite>
    brelse(from);
    80004312:	854e                	mv	a0,s3
    80004314:	fffff097          	auipc	ra,0xfffff
    80004318:	dd8080e7          	jalr	-552(ra) # 800030ec <brelse>
    brelse(to);
    8000431c:	8526                	mv	a0,s1
    8000431e:	fffff097          	auipc	ra,0xfffff
    80004322:	dce080e7          	jalr	-562(ra) # 800030ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004326:	2905                	addiw	s2,s2,1
    80004328:	0a91                	addi	s5,s5,4
    8000432a:	02ca2783          	lw	a5,44(s4)
    8000432e:	f8f94ee3          	blt	s2,a5,800042ca <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004332:	00000097          	auipc	ra,0x0
    80004336:	c7a080e7          	jalr	-902(ra) # 80003fac <write_head>
    install_trans(); // Now install writes to home locations
    8000433a:	00000097          	auipc	ra,0x0
    8000433e:	cec080e7          	jalr	-788(ra) # 80004026 <install_trans>
    log.lh.n = 0;
    80004342:	0001d797          	auipc	a5,0x1d
    80004346:	5e07a923          	sw	zero,1522(a5) # 80021934 <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000434a:	00000097          	auipc	ra,0x0
    8000434e:	c62080e7          	jalr	-926(ra) # 80003fac <write_head>
    80004352:	bdfd                	j	80004250 <end_op+0x52>

0000000080004354 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004354:	1101                	addi	sp,sp,-32
    80004356:	ec06                	sd	ra,24(sp)
    80004358:	e822                	sd	s0,16(sp)
    8000435a:	e426                	sd	s1,8(sp)
    8000435c:	e04a                	sd	s2,0(sp)
    8000435e:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004360:	0001d717          	auipc	a4,0x1d
    80004364:	5d472703          	lw	a4,1492(a4) # 80021934 <log+0x2c>
    80004368:	47f5                	li	a5,29
    8000436a:	08e7c063          	blt	a5,a4,800043ea <log_write+0x96>
    8000436e:	84aa                	mv	s1,a0
    80004370:	0001d797          	auipc	a5,0x1d
    80004374:	5b47a783          	lw	a5,1460(a5) # 80021924 <log+0x1c>
    80004378:	37fd                	addiw	a5,a5,-1
    8000437a:	06f75863          	bge	a4,a5,800043ea <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000437e:	0001d797          	auipc	a5,0x1d
    80004382:	5aa7a783          	lw	a5,1450(a5) # 80021928 <log+0x20>
    80004386:	06f05a63          	blez	a5,800043fa <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    8000438a:	0001d917          	auipc	s2,0x1d
    8000438e:	57e90913          	addi	s2,s2,1406 # 80021908 <log>
    80004392:	854a                	mv	a0,s2
    80004394:	ffffd097          	auipc	ra,0xffffd
    80004398:	87c080e7          	jalr	-1924(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    8000439c:	02c92603          	lw	a2,44(s2)
    800043a0:	06c05563          	blez	a2,8000440a <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043a4:	44cc                	lw	a1,12(s1)
    800043a6:	0001d717          	auipc	a4,0x1d
    800043aa:	59270713          	addi	a4,a4,1426 # 80021938 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800043ae:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800043b0:	4314                	lw	a3,0(a4)
    800043b2:	04b68d63          	beq	a3,a1,8000440c <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800043b6:	2785                	addiw	a5,a5,1
    800043b8:	0711                	addi	a4,a4,4
    800043ba:	fec79be3          	bne	a5,a2,800043b0 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800043be:	0621                	addi	a2,a2,8
    800043c0:	060a                	slli	a2,a2,0x2
    800043c2:	0001d797          	auipc	a5,0x1d
    800043c6:	54678793          	addi	a5,a5,1350 # 80021908 <log>
    800043ca:	963e                	add	a2,a2,a5
    800043cc:	44dc                	lw	a5,12(s1)
    800043ce:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800043d0:	8526                	mv	a0,s1
    800043d2:	fffff097          	auipc	ra,0xfffff
    800043d6:	db8080e7          	jalr	-584(ra) # 8000318a <bpin>
    log.lh.n++;
    800043da:	0001d717          	auipc	a4,0x1d
    800043de:	52e70713          	addi	a4,a4,1326 # 80021908 <log>
    800043e2:	575c                	lw	a5,44(a4)
    800043e4:	2785                	addiw	a5,a5,1
    800043e6:	d75c                	sw	a5,44(a4)
    800043e8:	a83d                	j	80004426 <log_write+0xd2>
    panic("too big a transaction");
    800043ea:	00004517          	auipc	a0,0x4
    800043ee:	1f650513          	addi	a0,a0,502 # 800085e0 <syscalls+0x1f0>
    800043f2:	ffffc097          	auipc	ra,0xffffc
    800043f6:	156080e7          	jalr	342(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043fa:	00004517          	auipc	a0,0x4
    800043fe:	1fe50513          	addi	a0,a0,510 # 800085f8 <syscalls+0x208>
    80004402:	ffffc097          	auipc	ra,0xffffc
    80004406:	146080e7          	jalr	326(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    8000440a:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    8000440c:	00878713          	addi	a4,a5,8
    80004410:	00271693          	slli	a3,a4,0x2
    80004414:	0001d717          	auipc	a4,0x1d
    80004418:	4f470713          	addi	a4,a4,1268 # 80021908 <log>
    8000441c:	9736                	add	a4,a4,a3
    8000441e:	44d4                	lw	a3,12(s1)
    80004420:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004422:	faf607e3          	beq	a2,a5,800043d0 <log_write+0x7c>
  }
  release(&log.lock);
    80004426:	0001d517          	auipc	a0,0x1d
    8000442a:	4e250513          	addi	a0,a0,1250 # 80021908 <log>
    8000442e:	ffffd097          	auipc	ra,0xffffd
    80004432:	896080e7          	jalr	-1898(ra) # 80000cc4 <release>
}
    80004436:	60e2                	ld	ra,24(sp)
    80004438:	6442                	ld	s0,16(sp)
    8000443a:	64a2                	ld	s1,8(sp)
    8000443c:	6902                	ld	s2,0(sp)
    8000443e:	6105                	addi	sp,sp,32
    80004440:	8082                	ret

0000000080004442 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004442:	1101                	addi	sp,sp,-32
    80004444:	ec06                	sd	ra,24(sp)
    80004446:	e822                	sd	s0,16(sp)
    80004448:	e426                	sd	s1,8(sp)
    8000444a:	e04a                	sd	s2,0(sp)
    8000444c:	1000                	addi	s0,sp,32
    8000444e:	84aa                	mv	s1,a0
    80004450:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004452:	00004597          	auipc	a1,0x4
    80004456:	1c658593          	addi	a1,a1,454 # 80008618 <syscalls+0x228>
    8000445a:	0521                	addi	a0,a0,8
    8000445c:	ffffc097          	auipc	ra,0xffffc
    80004460:	724080e7          	jalr	1828(ra) # 80000b80 <initlock>
  lk->name = name;
    80004464:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004468:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446c:	0204a423          	sw	zero,40(s1)
}
    80004470:	60e2                	ld	ra,24(sp)
    80004472:	6442                	ld	s0,16(sp)
    80004474:	64a2                	ld	s1,8(sp)
    80004476:	6902                	ld	s2,0(sp)
    80004478:	6105                	addi	sp,sp,32
    8000447a:	8082                	ret

000000008000447c <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    8000447c:	1101                	addi	sp,sp,-32
    8000447e:	ec06                	sd	ra,24(sp)
    80004480:	e822                	sd	s0,16(sp)
    80004482:	e426                	sd	s1,8(sp)
    80004484:	e04a                	sd	s2,0(sp)
    80004486:	1000                	addi	s0,sp,32
    80004488:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000448a:	00850913          	addi	s2,a0,8
    8000448e:	854a                	mv	a0,s2
    80004490:	ffffc097          	auipc	ra,0xffffc
    80004494:	780080e7          	jalr	1920(ra) # 80000c10 <acquire>
  while (lk->locked) {
    80004498:	409c                	lw	a5,0(s1)
    8000449a:	cb89                	beqz	a5,800044ac <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000449c:	85ca                	mv	a1,s2
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffe097          	auipc	ra,0xffffe
    800044a4:	e98080e7          	jalr	-360(ra) # 80002338 <sleep>
  while (lk->locked) {
    800044a8:	409c                	lw	a5,0(s1)
    800044aa:	fbed                	bnez	a5,8000449c <acquiresleep+0x20>
  }
  lk->locked = 1;
    800044ac:	4785                	li	a5,1
    800044ae:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800044b0:	ffffd097          	auipc	ra,0xffffd
    800044b4:	678080e7          	jalr	1656(ra) # 80001b28 <myproc>
    800044b8:	5d1c                	lw	a5,56(a0)
    800044ba:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800044bc:	854a                	mv	a0,s2
    800044be:	ffffd097          	auipc	ra,0xffffd
    800044c2:	806080e7          	jalr	-2042(ra) # 80000cc4 <release>
}
    800044c6:	60e2                	ld	ra,24(sp)
    800044c8:	6442                	ld	s0,16(sp)
    800044ca:	64a2                	ld	s1,8(sp)
    800044cc:	6902                	ld	s2,0(sp)
    800044ce:	6105                	addi	sp,sp,32
    800044d0:	8082                	ret

00000000800044d2 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800044d2:	1101                	addi	sp,sp,-32
    800044d4:	ec06                	sd	ra,24(sp)
    800044d6:	e822                	sd	s0,16(sp)
    800044d8:	e426                	sd	s1,8(sp)
    800044da:	e04a                	sd	s2,0(sp)
    800044dc:	1000                	addi	s0,sp,32
    800044de:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044e0:	00850913          	addi	s2,a0,8
    800044e4:	854a                	mv	a0,s2
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	72a080e7          	jalr	1834(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800044ee:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044f2:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044f6:	8526                	mv	a0,s1
    800044f8:	ffffe097          	auipc	ra,0xffffe
    800044fc:	fc6080e7          	jalr	-58(ra) # 800024be <wakeup>
  release(&lk->lk);
    80004500:	854a                	mv	a0,s2
    80004502:	ffffc097          	auipc	ra,0xffffc
    80004506:	7c2080e7          	jalr	1986(ra) # 80000cc4 <release>
}
    8000450a:	60e2                	ld	ra,24(sp)
    8000450c:	6442                	ld	s0,16(sp)
    8000450e:	64a2                	ld	s1,8(sp)
    80004510:	6902                	ld	s2,0(sp)
    80004512:	6105                	addi	sp,sp,32
    80004514:	8082                	ret

0000000080004516 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004516:	7179                	addi	sp,sp,-48
    80004518:	f406                	sd	ra,40(sp)
    8000451a:	f022                	sd	s0,32(sp)
    8000451c:	ec26                	sd	s1,24(sp)
    8000451e:	e84a                	sd	s2,16(sp)
    80004520:	e44e                	sd	s3,8(sp)
    80004522:	1800                	addi	s0,sp,48
    80004524:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004526:	00850913          	addi	s2,a0,8
    8000452a:	854a                	mv	a0,s2
    8000452c:	ffffc097          	auipc	ra,0xffffc
    80004530:	6e4080e7          	jalr	1764(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004534:	409c                	lw	a5,0(s1)
    80004536:	ef99                	bnez	a5,80004554 <holdingsleep+0x3e>
    80004538:	4481                	li	s1,0
  release(&lk->lk);
    8000453a:	854a                	mv	a0,s2
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	788080e7          	jalr	1928(ra) # 80000cc4 <release>
  return r;
}
    80004544:	8526                	mv	a0,s1
    80004546:	70a2                	ld	ra,40(sp)
    80004548:	7402                	ld	s0,32(sp)
    8000454a:	64e2                	ld	s1,24(sp)
    8000454c:	6942                	ld	s2,16(sp)
    8000454e:	69a2                	ld	s3,8(sp)
    80004550:	6145                	addi	sp,sp,48
    80004552:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004554:	0284a983          	lw	s3,40(s1)
    80004558:	ffffd097          	auipc	ra,0xffffd
    8000455c:	5d0080e7          	jalr	1488(ra) # 80001b28 <myproc>
    80004560:	5d04                	lw	s1,56(a0)
    80004562:	413484b3          	sub	s1,s1,s3
    80004566:	0014b493          	seqz	s1,s1
    8000456a:	bfc1                	j	8000453a <holdingsleep+0x24>

000000008000456c <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    8000456c:	1141                	addi	sp,sp,-16
    8000456e:	e406                	sd	ra,8(sp)
    80004570:	e022                	sd	s0,0(sp)
    80004572:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004574:	00004597          	auipc	a1,0x4
    80004578:	0b458593          	addi	a1,a1,180 # 80008628 <syscalls+0x238>
    8000457c:	0001d517          	auipc	a0,0x1d
    80004580:	4d450513          	addi	a0,a0,1236 # 80021a50 <ftable>
    80004584:	ffffc097          	auipc	ra,0xffffc
    80004588:	5fc080e7          	jalr	1532(ra) # 80000b80 <initlock>
}
    8000458c:	60a2                	ld	ra,8(sp)
    8000458e:	6402                	ld	s0,0(sp)
    80004590:	0141                	addi	sp,sp,16
    80004592:	8082                	ret

0000000080004594 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004594:	1101                	addi	sp,sp,-32
    80004596:	ec06                	sd	ra,24(sp)
    80004598:	e822                	sd	s0,16(sp)
    8000459a:	e426                	sd	s1,8(sp)
    8000459c:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000459e:	0001d517          	auipc	a0,0x1d
    800045a2:	4b250513          	addi	a0,a0,1202 # 80021a50 <ftable>
    800045a6:	ffffc097          	auipc	ra,0xffffc
    800045aa:	66a080e7          	jalr	1642(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045ae:	0001d497          	auipc	s1,0x1d
    800045b2:	4ba48493          	addi	s1,s1,1210 # 80021a68 <ftable+0x18>
    800045b6:	0001e717          	auipc	a4,0x1e
    800045ba:	45270713          	addi	a4,a4,1106 # 80022a08 <ftable+0xfb8>
    if(f->ref == 0){
    800045be:	40dc                	lw	a5,4(s1)
    800045c0:	cf99                	beqz	a5,800045de <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800045c2:	02848493          	addi	s1,s1,40
    800045c6:	fee49ce3          	bne	s1,a4,800045be <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800045ca:	0001d517          	auipc	a0,0x1d
    800045ce:	48650513          	addi	a0,a0,1158 # 80021a50 <ftable>
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6f2080e7          	jalr	1778(ra) # 80000cc4 <release>
  return 0;
    800045da:	4481                	li	s1,0
    800045dc:	a819                	j	800045f2 <filealloc+0x5e>
      f->ref = 1;
    800045de:	4785                	li	a5,1
    800045e0:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045e2:	0001d517          	auipc	a0,0x1d
    800045e6:	46e50513          	addi	a0,a0,1134 # 80021a50 <ftable>
    800045ea:	ffffc097          	auipc	ra,0xffffc
    800045ee:	6da080e7          	jalr	1754(ra) # 80000cc4 <release>
}
    800045f2:	8526                	mv	a0,s1
    800045f4:	60e2                	ld	ra,24(sp)
    800045f6:	6442                	ld	s0,16(sp)
    800045f8:	64a2                	ld	s1,8(sp)
    800045fa:	6105                	addi	sp,sp,32
    800045fc:	8082                	ret

00000000800045fe <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045fe:	1101                	addi	sp,sp,-32
    80004600:	ec06                	sd	ra,24(sp)
    80004602:	e822                	sd	s0,16(sp)
    80004604:	e426                	sd	s1,8(sp)
    80004606:	1000                	addi	s0,sp,32
    80004608:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000460a:	0001d517          	auipc	a0,0x1d
    8000460e:	44650513          	addi	a0,a0,1094 # 80021a50 <ftable>
    80004612:	ffffc097          	auipc	ra,0xffffc
    80004616:	5fe080e7          	jalr	1534(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000461a:	40dc                	lw	a5,4(s1)
    8000461c:	02f05263          	blez	a5,80004640 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004620:	2785                	addiw	a5,a5,1
    80004622:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004624:	0001d517          	auipc	a0,0x1d
    80004628:	42c50513          	addi	a0,a0,1068 # 80021a50 <ftable>
    8000462c:	ffffc097          	auipc	ra,0xffffc
    80004630:	698080e7          	jalr	1688(ra) # 80000cc4 <release>
  return f;
}
    80004634:	8526                	mv	a0,s1
    80004636:	60e2                	ld	ra,24(sp)
    80004638:	6442                	ld	s0,16(sp)
    8000463a:	64a2                	ld	s1,8(sp)
    8000463c:	6105                	addi	sp,sp,32
    8000463e:	8082                	ret
    panic("filedup");
    80004640:	00004517          	auipc	a0,0x4
    80004644:	ff050513          	addi	a0,a0,-16 # 80008630 <syscalls+0x240>
    80004648:	ffffc097          	auipc	ra,0xffffc
    8000464c:	f00080e7          	jalr	-256(ra) # 80000548 <panic>

0000000080004650 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004650:	7139                	addi	sp,sp,-64
    80004652:	fc06                	sd	ra,56(sp)
    80004654:	f822                	sd	s0,48(sp)
    80004656:	f426                	sd	s1,40(sp)
    80004658:	f04a                	sd	s2,32(sp)
    8000465a:	ec4e                	sd	s3,24(sp)
    8000465c:	e852                	sd	s4,16(sp)
    8000465e:	e456                	sd	s5,8(sp)
    80004660:	0080                	addi	s0,sp,64
    80004662:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	3ec50513          	addi	a0,a0,1004 # 80021a50 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	5a4080e7          	jalr	1444(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004674:	40dc                	lw	a5,4(s1)
    80004676:	06f05163          	blez	a5,800046d8 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000467a:	37fd                	addiw	a5,a5,-1
    8000467c:	0007871b          	sext.w	a4,a5
    80004680:	c0dc                	sw	a5,4(s1)
    80004682:	06e04363          	bgtz	a4,800046e8 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004686:	0004a903          	lw	s2,0(s1)
    8000468a:	0094ca83          	lbu	s5,9(s1)
    8000468e:	0104ba03          	ld	s4,16(s1)
    80004692:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004696:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000469a:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000469e:	0001d517          	auipc	a0,0x1d
    800046a2:	3b250513          	addi	a0,a0,946 # 80021a50 <ftable>
    800046a6:	ffffc097          	auipc	ra,0xffffc
    800046aa:	61e080e7          	jalr	1566(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800046ae:	4785                	li	a5,1
    800046b0:	04f90d63          	beq	s2,a5,8000470a <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800046b4:	3979                	addiw	s2,s2,-2
    800046b6:	4785                	li	a5,1
    800046b8:	0527e063          	bltu	a5,s2,800046f8 <fileclose+0xa8>
    begin_op();
    800046bc:	00000097          	auipc	ra,0x0
    800046c0:	ac2080e7          	jalr	-1342(ra) # 8000417e <begin_op>
    iput(ff.ip);
    800046c4:	854e                	mv	a0,s3
    800046c6:	fffff097          	auipc	ra,0xfffff
    800046ca:	2b2080e7          	jalr	690(ra) # 80003978 <iput>
    end_op();
    800046ce:	00000097          	auipc	ra,0x0
    800046d2:	b30080e7          	jalr	-1232(ra) # 800041fe <end_op>
    800046d6:	a00d                	j	800046f8 <fileclose+0xa8>
    panic("fileclose");
    800046d8:	00004517          	auipc	a0,0x4
    800046dc:	f6050513          	addi	a0,a0,-160 # 80008638 <syscalls+0x248>
    800046e0:	ffffc097          	auipc	ra,0xffffc
    800046e4:	e68080e7          	jalr	-408(ra) # 80000548 <panic>
    release(&ftable.lock);
    800046e8:	0001d517          	auipc	a0,0x1d
    800046ec:	36850513          	addi	a0,a0,872 # 80021a50 <ftable>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	5d4080e7          	jalr	1492(ra) # 80000cc4 <release>
  }
}
    800046f8:	70e2                	ld	ra,56(sp)
    800046fa:	7442                	ld	s0,48(sp)
    800046fc:	74a2                	ld	s1,40(sp)
    800046fe:	7902                	ld	s2,32(sp)
    80004700:	69e2                	ld	s3,24(sp)
    80004702:	6a42                	ld	s4,16(sp)
    80004704:	6aa2                	ld	s5,8(sp)
    80004706:	6121                	addi	sp,sp,64
    80004708:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000470a:	85d6                	mv	a1,s5
    8000470c:	8552                	mv	a0,s4
    8000470e:	00000097          	auipc	ra,0x0
    80004712:	372080e7          	jalr	882(ra) # 80004a80 <pipeclose>
    80004716:	b7cd                	j	800046f8 <fileclose+0xa8>

0000000080004718 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004718:	715d                	addi	sp,sp,-80
    8000471a:	e486                	sd	ra,72(sp)
    8000471c:	e0a2                	sd	s0,64(sp)
    8000471e:	fc26                	sd	s1,56(sp)
    80004720:	f84a                	sd	s2,48(sp)
    80004722:	f44e                	sd	s3,40(sp)
    80004724:	0880                	addi	s0,sp,80
    80004726:	84aa                	mv	s1,a0
    80004728:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000472a:	ffffd097          	auipc	ra,0xffffd
    8000472e:	3fe080e7          	jalr	1022(ra) # 80001b28 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004732:	409c                	lw	a5,0(s1)
    80004734:	37f9                	addiw	a5,a5,-2
    80004736:	4705                	li	a4,1
    80004738:	04f76763          	bltu	a4,a5,80004786 <filestat+0x6e>
    8000473c:	892a                	mv	s2,a0
    ilock(f->ip);
    8000473e:	6c88                	ld	a0,24(s1)
    80004740:	fffff097          	auipc	ra,0xfffff
    80004744:	07e080e7          	jalr	126(ra) # 800037be <ilock>
    stati(f->ip, &st);
    80004748:	fb840593          	addi	a1,s0,-72
    8000474c:	6c88                	ld	a0,24(s1)
    8000474e:	fffff097          	auipc	ra,0xfffff
    80004752:	2fa080e7          	jalr	762(ra) # 80003a48 <stati>
    iunlock(f->ip);
    80004756:	6c88                	ld	a0,24(s1)
    80004758:	fffff097          	auipc	ra,0xfffff
    8000475c:	128080e7          	jalr	296(ra) # 80003880 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004760:	46e1                	li	a3,24
    80004762:	fb840613          	addi	a2,s0,-72
    80004766:	85ce                	mv	a1,s3
    80004768:	05093503          	ld	a0,80(s2)
    8000476c:	ffffd097          	auipc	ra,0xffffd
    80004770:	130080e7          	jalr	304(ra) # 8000189c <copyout>
    80004774:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004778:	60a6                	ld	ra,72(sp)
    8000477a:	6406                	ld	s0,64(sp)
    8000477c:	74e2                	ld	s1,56(sp)
    8000477e:	7942                	ld	s2,48(sp)
    80004780:	79a2                	ld	s3,40(sp)
    80004782:	6161                	addi	sp,sp,80
    80004784:	8082                	ret
  return -1;
    80004786:	557d                	li	a0,-1
    80004788:	bfc5                	j	80004778 <filestat+0x60>

000000008000478a <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000478a:	7179                	addi	sp,sp,-48
    8000478c:	f406                	sd	ra,40(sp)
    8000478e:	f022                	sd	s0,32(sp)
    80004790:	ec26                	sd	s1,24(sp)
    80004792:	e84a                	sd	s2,16(sp)
    80004794:	e44e                	sd	s3,8(sp)
    80004796:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004798:	00854783          	lbu	a5,8(a0)
    8000479c:	c3d5                	beqz	a5,80004840 <fileread+0xb6>
    8000479e:	84aa                	mv	s1,a0
    800047a0:	89ae                	mv	s3,a1
    800047a2:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800047a4:	411c                	lw	a5,0(a0)
    800047a6:	4705                	li	a4,1
    800047a8:	04e78963          	beq	a5,a4,800047fa <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047ac:	470d                	li	a4,3
    800047ae:	04e78d63          	beq	a5,a4,80004808 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800047b2:	4709                	li	a4,2
    800047b4:	06e79e63          	bne	a5,a4,80004830 <fileread+0xa6>
    ilock(f->ip);
    800047b8:	6d08                	ld	a0,24(a0)
    800047ba:	fffff097          	auipc	ra,0xfffff
    800047be:	004080e7          	jalr	4(ra) # 800037be <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800047c2:	874a                	mv	a4,s2
    800047c4:	5094                	lw	a3,32(s1)
    800047c6:	864e                	mv	a2,s3
    800047c8:	4585                	li	a1,1
    800047ca:	6c88                	ld	a0,24(s1)
    800047cc:	fffff097          	auipc	ra,0xfffff
    800047d0:	2a6080e7          	jalr	678(ra) # 80003a72 <readi>
    800047d4:	892a                	mv	s2,a0
    800047d6:	00a05563          	blez	a0,800047e0 <fileread+0x56>
      f->off += r;
    800047da:	509c                	lw	a5,32(s1)
    800047dc:	9fa9                	addw	a5,a5,a0
    800047de:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047e0:	6c88                	ld	a0,24(s1)
    800047e2:	fffff097          	auipc	ra,0xfffff
    800047e6:	09e080e7          	jalr	158(ra) # 80003880 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ea:	854a                	mv	a0,s2
    800047ec:	70a2                	ld	ra,40(sp)
    800047ee:	7402                	ld	s0,32(sp)
    800047f0:	64e2                	ld	s1,24(sp)
    800047f2:	6942                	ld	s2,16(sp)
    800047f4:	69a2                	ld	s3,8(sp)
    800047f6:	6145                	addi	sp,sp,48
    800047f8:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047fa:	6908                	ld	a0,16(a0)
    800047fc:	00000097          	auipc	ra,0x0
    80004800:	418080e7          	jalr	1048(ra) # 80004c14 <piperead>
    80004804:	892a                	mv	s2,a0
    80004806:	b7d5                	j	800047ea <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004808:	02451783          	lh	a5,36(a0)
    8000480c:	03079693          	slli	a3,a5,0x30
    80004810:	92c1                	srli	a3,a3,0x30
    80004812:	4725                	li	a4,9
    80004814:	02d76863          	bltu	a4,a3,80004844 <fileread+0xba>
    80004818:	0792                	slli	a5,a5,0x4
    8000481a:	0001d717          	auipc	a4,0x1d
    8000481e:	19670713          	addi	a4,a4,406 # 800219b0 <devsw>
    80004822:	97ba                	add	a5,a5,a4
    80004824:	639c                	ld	a5,0(a5)
    80004826:	c38d                	beqz	a5,80004848 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004828:	4505                	li	a0,1
    8000482a:	9782                	jalr	a5
    8000482c:	892a                	mv	s2,a0
    8000482e:	bf75                	j	800047ea <fileread+0x60>
    panic("fileread");
    80004830:	00004517          	auipc	a0,0x4
    80004834:	e1850513          	addi	a0,a0,-488 # 80008648 <syscalls+0x258>
    80004838:	ffffc097          	auipc	ra,0xffffc
    8000483c:	d10080e7          	jalr	-752(ra) # 80000548 <panic>
    return -1;
    80004840:	597d                	li	s2,-1
    80004842:	b765                	j	800047ea <fileread+0x60>
      return -1;
    80004844:	597d                	li	s2,-1
    80004846:	b755                	j	800047ea <fileread+0x60>
    80004848:	597d                	li	s2,-1
    8000484a:	b745                	j	800047ea <fileread+0x60>

000000008000484c <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    8000484c:	00954783          	lbu	a5,9(a0)
    80004850:	14078563          	beqz	a5,8000499a <filewrite+0x14e>
{
    80004854:	715d                	addi	sp,sp,-80
    80004856:	e486                	sd	ra,72(sp)
    80004858:	e0a2                	sd	s0,64(sp)
    8000485a:	fc26                	sd	s1,56(sp)
    8000485c:	f84a                	sd	s2,48(sp)
    8000485e:	f44e                	sd	s3,40(sp)
    80004860:	f052                	sd	s4,32(sp)
    80004862:	ec56                	sd	s5,24(sp)
    80004864:	e85a                	sd	s6,16(sp)
    80004866:	e45e                	sd	s7,8(sp)
    80004868:	e062                	sd	s8,0(sp)
    8000486a:	0880                	addi	s0,sp,80
    8000486c:	892a                	mv	s2,a0
    8000486e:	8aae                	mv	s5,a1
    80004870:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004872:	411c                	lw	a5,0(a0)
    80004874:	4705                	li	a4,1
    80004876:	02e78263          	beq	a5,a4,8000489a <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000487a:	470d                	li	a4,3
    8000487c:	02e78563          	beq	a5,a4,800048a6 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004880:	4709                	li	a4,2
    80004882:	10e79463          	bne	a5,a4,8000498a <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004886:	0ec05e63          	blez	a2,80004982 <filewrite+0x136>
    int i = 0;
    8000488a:	4981                	li	s3,0
    8000488c:	6b05                	lui	s6,0x1
    8000488e:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004892:	6b85                	lui	s7,0x1
    80004894:	c00b8b9b          	addiw	s7,s7,-1024
    80004898:	a851                	j	8000492c <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    8000489a:	6908                	ld	a0,16(a0)
    8000489c:	00000097          	auipc	ra,0x0
    800048a0:	254080e7          	jalr	596(ra) # 80004af0 <pipewrite>
    800048a4:	a85d                	j	8000495a <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800048a6:	02451783          	lh	a5,36(a0)
    800048aa:	03079693          	slli	a3,a5,0x30
    800048ae:	92c1                	srli	a3,a3,0x30
    800048b0:	4725                	li	a4,9
    800048b2:	0ed76663          	bltu	a4,a3,8000499e <filewrite+0x152>
    800048b6:	0792                	slli	a5,a5,0x4
    800048b8:	0001d717          	auipc	a4,0x1d
    800048bc:	0f870713          	addi	a4,a4,248 # 800219b0 <devsw>
    800048c0:	97ba                	add	a5,a5,a4
    800048c2:	679c                	ld	a5,8(a5)
    800048c4:	cff9                	beqz	a5,800049a2 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    800048c6:	4505                	li	a0,1
    800048c8:	9782                	jalr	a5
    800048ca:	a841                	j	8000495a <filewrite+0x10e>
    800048cc:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800048d0:	00000097          	auipc	ra,0x0
    800048d4:	8ae080e7          	jalr	-1874(ra) # 8000417e <begin_op>
      ilock(f->ip);
    800048d8:	01893503          	ld	a0,24(s2)
    800048dc:	fffff097          	auipc	ra,0xfffff
    800048e0:	ee2080e7          	jalr	-286(ra) # 800037be <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048e4:	8762                	mv	a4,s8
    800048e6:	02092683          	lw	a3,32(s2)
    800048ea:	01598633          	add	a2,s3,s5
    800048ee:	4585                	li	a1,1
    800048f0:	01893503          	ld	a0,24(s2)
    800048f4:	fffff097          	auipc	ra,0xfffff
    800048f8:	276080e7          	jalr	630(ra) # 80003b6a <writei>
    800048fc:	84aa                	mv	s1,a0
    800048fe:	02a05f63          	blez	a0,8000493c <filewrite+0xf0>
        f->off += r;
    80004902:	02092783          	lw	a5,32(s2)
    80004906:	9fa9                	addw	a5,a5,a0
    80004908:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000490c:	01893503          	ld	a0,24(s2)
    80004910:	fffff097          	auipc	ra,0xfffff
    80004914:	f70080e7          	jalr	-144(ra) # 80003880 <iunlock>
      end_op();
    80004918:	00000097          	auipc	ra,0x0
    8000491c:	8e6080e7          	jalr	-1818(ra) # 800041fe <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004920:	049c1963          	bne	s8,s1,80004972 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004924:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004928:	0349d663          	bge	s3,s4,80004954 <filewrite+0x108>
      int n1 = n - i;
    8000492c:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004930:	84be                	mv	s1,a5
    80004932:	2781                	sext.w	a5,a5
    80004934:	f8fb5ce3          	bge	s6,a5,800048cc <filewrite+0x80>
    80004938:	84de                	mv	s1,s7
    8000493a:	bf49                	j	800048cc <filewrite+0x80>
      iunlock(f->ip);
    8000493c:	01893503          	ld	a0,24(s2)
    80004940:	fffff097          	auipc	ra,0xfffff
    80004944:	f40080e7          	jalr	-192(ra) # 80003880 <iunlock>
      end_op();
    80004948:	00000097          	auipc	ra,0x0
    8000494c:	8b6080e7          	jalr	-1866(ra) # 800041fe <end_op>
      if(r < 0)
    80004950:	fc04d8e3          	bgez	s1,80004920 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004954:	8552                	mv	a0,s4
    80004956:	033a1863          	bne	s4,s3,80004986 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000495a:	60a6                	ld	ra,72(sp)
    8000495c:	6406                	ld	s0,64(sp)
    8000495e:	74e2                	ld	s1,56(sp)
    80004960:	7942                	ld	s2,48(sp)
    80004962:	79a2                	ld	s3,40(sp)
    80004964:	7a02                	ld	s4,32(sp)
    80004966:	6ae2                	ld	s5,24(sp)
    80004968:	6b42                	ld	s6,16(sp)
    8000496a:	6ba2                	ld	s7,8(sp)
    8000496c:	6c02                	ld	s8,0(sp)
    8000496e:	6161                	addi	sp,sp,80
    80004970:	8082                	ret
        panic("short filewrite");
    80004972:	00004517          	auipc	a0,0x4
    80004976:	ce650513          	addi	a0,a0,-794 # 80008658 <syscalls+0x268>
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	bce080e7          	jalr	-1074(ra) # 80000548 <panic>
    int i = 0;
    80004982:	4981                	li	s3,0
    80004984:	bfc1                	j	80004954 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004986:	557d                	li	a0,-1
    80004988:	bfc9                	j	8000495a <filewrite+0x10e>
    panic("filewrite");
    8000498a:	00004517          	auipc	a0,0x4
    8000498e:	cde50513          	addi	a0,a0,-802 # 80008668 <syscalls+0x278>
    80004992:	ffffc097          	auipc	ra,0xffffc
    80004996:	bb6080e7          	jalr	-1098(ra) # 80000548 <panic>
    return -1;
    8000499a:	557d                	li	a0,-1
}
    8000499c:	8082                	ret
      return -1;
    8000499e:	557d                	li	a0,-1
    800049a0:	bf6d                	j	8000495a <filewrite+0x10e>
    800049a2:	557d                	li	a0,-1
    800049a4:	bf5d                	j	8000495a <filewrite+0x10e>

00000000800049a6 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800049a6:	7179                	addi	sp,sp,-48
    800049a8:	f406                	sd	ra,40(sp)
    800049aa:	f022                	sd	s0,32(sp)
    800049ac:	ec26                	sd	s1,24(sp)
    800049ae:	e84a                	sd	s2,16(sp)
    800049b0:	e44e                	sd	s3,8(sp)
    800049b2:	e052                	sd	s4,0(sp)
    800049b4:	1800                	addi	s0,sp,48
    800049b6:	84aa                	mv	s1,a0
    800049b8:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800049ba:	0005b023          	sd	zero,0(a1)
    800049be:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800049c2:	00000097          	auipc	ra,0x0
    800049c6:	bd2080e7          	jalr	-1070(ra) # 80004594 <filealloc>
    800049ca:	e088                	sd	a0,0(s1)
    800049cc:	c551                	beqz	a0,80004a58 <pipealloc+0xb2>
    800049ce:	00000097          	auipc	ra,0x0
    800049d2:	bc6080e7          	jalr	-1082(ra) # 80004594 <filealloc>
    800049d6:	00aa3023          	sd	a0,0(s4)
    800049da:	c92d                	beqz	a0,80004a4c <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800049dc:	ffffc097          	auipc	ra,0xffffc
    800049e0:	144080e7          	jalr	324(ra) # 80000b20 <kalloc>
    800049e4:	892a                	mv	s2,a0
    800049e6:	c125                	beqz	a0,80004a46 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049e8:	4985                	li	s3,1
    800049ea:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049ee:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049f2:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049f6:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049fa:	00004597          	auipc	a1,0x4
    800049fe:	c7e58593          	addi	a1,a1,-898 # 80008678 <syscalls+0x288>
    80004a02:	ffffc097          	auipc	ra,0xffffc
    80004a06:	17e080e7          	jalr	382(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004a0a:	609c                	ld	a5,0(s1)
    80004a0c:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004a10:	609c                	ld	a5,0(s1)
    80004a12:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004a16:	609c                	ld	a5,0(s1)
    80004a18:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004a1c:	609c                	ld	a5,0(s1)
    80004a1e:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004a22:	000a3783          	ld	a5,0(s4)
    80004a26:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004a2a:	000a3783          	ld	a5,0(s4)
    80004a2e:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004a32:	000a3783          	ld	a5,0(s4)
    80004a36:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004a3a:	000a3783          	ld	a5,0(s4)
    80004a3e:	0127b823          	sd	s2,16(a5)
  return 0;
    80004a42:	4501                	li	a0,0
    80004a44:	a025                	j	80004a6c <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a46:	6088                	ld	a0,0(s1)
    80004a48:	e501                	bnez	a0,80004a50 <pipealloc+0xaa>
    80004a4a:	a039                	j	80004a58 <pipealloc+0xb2>
    80004a4c:	6088                	ld	a0,0(s1)
    80004a4e:	c51d                	beqz	a0,80004a7c <pipealloc+0xd6>
    fileclose(*f0);
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	c00080e7          	jalr	-1024(ra) # 80004650 <fileclose>
  if(*f1)
    80004a58:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a5c:	557d                	li	a0,-1
  if(*f1)
    80004a5e:	c799                	beqz	a5,80004a6c <pipealloc+0xc6>
    fileclose(*f1);
    80004a60:	853e                	mv	a0,a5
    80004a62:	00000097          	auipc	ra,0x0
    80004a66:	bee080e7          	jalr	-1042(ra) # 80004650 <fileclose>
  return -1;
    80004a6a:	557d                	li	a0,-1
}
    80004a6c:	70a2                	ld	ra,40(sp)
    80004a6e:	7402                	ld	s0,32(sp)
    80004a70:	64e2                	ld	s1,24(sp)
    80004a72:	6942                	ld	s2,16(sp)
    80004a74:	69a2                	ld	s3,8(sp)
    80004a76:	6a02                	ld	s4,0(sp)
    80004a78:	6145                	addi	sp,sp,48
    80004a7a:	8082                	ret
  return -1;
    80004a7c:	557d                	li	a0,-1
    80004a7e:	b7fd                	j	80004a6c <pipealloc+0xc6>

0000000080004a80 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a80:	1101                	addi	sp,sp,-32
    80004a82:	ec06                	sd	ra,24(sp)
    80004a84:	e822                	sd	s0,16(sp)
    80004a86:	e426                	sd	s1,8(sp)
    80004a88:	e04a                	sd	s2,0(sp)
    80004a8a:	1000                	addi	s0,sp,32
    80004a8c:	84aa                	mv	s1,a0
    80004a8e:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a90:	ffffc097          	auipc	ra,0xffffc
    80004a94:	180080e7          	jalr	384(ra) # 80000c10 <acquire>
  if(writable){
    80004a98:	02090d63          	beqz	s2,80004ad2 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a9c:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004aa0:	21848513          	addi	a0,s1,536
    80004aa4:	ffffe097          	auipc	ra,0xffffe
    80004aa8:	a1a080e7          	jalr	-1510(ra) # 800024be <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004aac:	2204b783          	ld	a5,544(s1)
    80004ab0:	eb95                	bnez	a5,80004ae4 <pipeclose+0x64>
    release(&pi->lock);
    80004ab2:	8526                	mv	a0,s1
    80004ab4:	ffffc097          	auipc	ra,0xffffc
    80004ab8:	210080e7          	jalr	528(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004abc:	8526                	mv	a0,s1
    80004abe:	ffffc097          	auipc	ra,0xffffc
    80004ac2:	f66080e7          	jalr	-154(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004ac6:	60e2                	ld	ra,24(sp)
    80004ac8:	6442                	ld	s0,16(sp)
    80004aca:	64a2                	ld	s1,8(sp)
    80004acc:	6902                	ld	s2,0(sp)
    80004ace:	6105                	addi	sp,sp,32
    80004ad0:	8082                	ret
    pi->readopen = 0;
    80004ad2:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ad6:	21c48513          	addi	a0,s1,540
    80004ada:	ffffe097          	auipc	ra,0xffffe
    80004ade:	9e4080e7          	jalr	-1564(ra) # 800024be <wakeup>
    80004ae2:	b7e9                	j	80004aac <pipeclose+0x2c>
    release(&pi->lock);
    80004ae4:	8526                	mv	a0,s1
    80004ae6:	ffffc097          	auipc	ra,0xffffc
    80004aea:	1de080e7          	jalr	478(ra) # 80000cc4 <release>
}
    80004aee:	bfe1                	j	80004ac6 <pipeclose+0x46>

0000000080004af0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004af0:	7119                	addi	sp,sp,-128
    80004af2:	fc86                	sd	ra,120(sp)
    80004af4:	f8a2                	sd	s0,112(sp)
    80004af6:	f4a6                	sd	s1,104(sp)
    80004af8:	f0ca                	sd	s2,96(sp)
    80004afa:	ecce                	sd	s3,88(sp)
    80004afc:	e8d2                	sd	s4,80(sp)
    80004afe:	e4d6                	sd	s5,72(sp)
    80004b00:	e0da                	sd	s6,64(sp)
    80004b02:	fc5e                	sd	s7,56(sp)
    80004b04:	f862                	sd	s8,48(sp)
    80004b06:	f466                	sd	s9,40(sp)
    80004b08:	f06a                	sd	s10,32(sp)
    80004b0a:	ec6e                	sd	s11,24(sp)
    80004b0c:	0100                	addi	s0,sp,128
    80004b0e:	84aa                	mv	s1,a0
    80004b10:	8cae                	mv	s9,a1
    80004b12:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	014080e7          	jalr	20(ra) # 80001b28 <myproc>
    80004b1c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004b1e:	8526                	mv	a0,s1
    80004b20:	ffffc097          	auipc	ra,0xffffc
    80004b24:	0f0080e7          	jalr	240(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004b28:	0d605963          	blez	s6,80004bfa <pipewrite+0x10a>
    80004b2c:	89a6                	mv	s3,s1
    80004b2e:	3b7d                	addiw	s6,s6,-1
    80004b30:	1b02                	slli	s6,s6,0x20
    80004b32:	020b5b13          	srli	s6,s6,0x20
    80004b36:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004b38:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004b3c:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b40:	5dfd                	li	s11,-1
    80004b42:	000b8d1b          	sext.w	s10,s7
    80004b46:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b48:	2184a783          	lw	a5,536(s1)
    80004b4c:	21c4a703          	lw	a4,540(s1)
    80004b50:	2007879b          	addiw	a5,a5,512
    80004b54:	02f71b63          	bne	a4,a5,80004b8a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b58:	2204a783          	lw	a5,544(s1)
    80004b5c:	cbad                	beqz	a5,80004bce <pipewrite+0xde>
    80004b5e:	03092783          	lw	a5,48(s2)
    80004b62:	e7b5                	bnez	a5,80004bce <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b64:	8556                	mv	a0,s5
    80004b66:	ffffe097          	auipc	ra,0xffffe
    80004b6a:	958080e7          	jalr	-1704(ra) # 800024be <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b6e:	85ce                	mv	a1,s3
    80004b70:	8552                	mv	a0,s4
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	7c6080e7          	jalr	1990(ra) # 80002338 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b7a:	2184a783          	lw	a5,536(s1)
    80004b7e:	21c4a703          	lw	a4,540(s1)
    80004b82:	2007879b          	addiw	a5,a5,512
    80004b86:	fcf709e3          	beq	a4,a5,80004b58 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b8a:	4685                	li	a3,1
    80004b8c:	019b8633          	add	a2,s7,s9
    80004b90:	f8f40593          	addi	a1,s0,-113
    80004b94:	05093503          	ld	a0,80(s2)
    80004b98:	ffffd097          	auipc	ra,0xffffd
    80004b9c:	daa080e7          	jalr	-598(ra) # 80001942 <copyin>
    80004ba0:	05b50e63          	beq	a0,s11,80004bfc <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ba4:	21c4a783          	lw	a5,540(s1)
    80004ba8:	0017871b          	addiw	a4,a5,1
    80004bac:	20e4ae23          	sw	a4,540(s1)
    80004bb0:	1ff7f793          	andi	a5,a5,511
    80004bb4:	97a6                	add	a5,a5,s1
    80004bb6:	f8f44703          	lbu	a4,-113(s0)
    80004bba:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004bbe:	001d0c1b          	addiw	s8,s10,1
    80004bc2:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004bc6:	036b8b63          	beq	s7,s6,80004bfc <pipewrite+0x10c>
    80004bca:	8bbe                	mv	s7,a5
    80004bcc:	bf9d                	j	80004b42 <pipewrite+0x52>
        release(&pi->lock);
    80004bce:	8526                	mv	a0,s1
    80004bd0:	ffffc097          	auipc	ra,0xffffc
    80004bd4:	0f4080e7          	jalr	244(ra) # 80000cc4 <release>
        return -1;
    80004bd8:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004bda:	8562                	mv	a0,s8
    80004bdc:	70e6                	ld	ra,120(sp)
    80004bde:	7446                	ld	s0,112(sp)
    80004be0:	74a6                	ld	s1,104(sp)
    80004be2:	7906                	ld	s2,96(sp)
    80004be4:	69e6                	ld	s3,88(sp)
    80004be6:	6a46                	ld	s4,80(sp)
    80004be8:	6aa6                	ld	s5,72(sp)
    80004bea:	6b06                	ld	s6,64(sp)
    80004bec:	7be2                	ld	s7,56(sp)
    80004bee:	7c42                	ld	s8,48(sp)
    80004bf0:	7ca2                	ld	s9,40(sp)
    80004bf2:	7d02                	ld	s10,32(sp)
    80004bf4:	6de2                	ld	s11,24(sp)
    80004bf6:	6109                	addi	sp,sp,128
    80004bf8:	8082                	ret
  for(i = 0; i < n; i++){
    80004bfa:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bfc:	21848513          	addi	a0,s1,536
    80004c00:	ffffe097          	auipc	ra,0xffffe
    80004c04:	8be080e7          	jalr	-1858(ra) # 800024be <wakeup>
  release(&pi->lock);
    80004c08:	8526                	mv	a0,s1
    80004c0a:	ffffc097          	auipc	ra,0xffffc
    80004c0e:	0ba080e7          	jalr	186(ra) # 80000cc4 <release>
  return i;
    80004c12:	b7e1                	j	80004bda <pipewrite+0xea>

0000000080004c14 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004c14:	715d                	addi	sp,sp,-80
    80004c16:	e486                	sd	ra,72(sp)
    80004c18:	e0a2                	sd	s0,64(sp)
    80004c1a:	fc26                	sd	s1,56(sp)
    80004c1c:	f84a                	sd	s2,48(sp)
    80004c1e:	f44e                	sd	s3,40(sp)
    80004c20:	f052                	sd	s4,32(sp)
    80004c22:	ec56                	sd	s5,24(sp)
    80004c24:	e85a                	sd	s6,16(sp)
    80004c26:	0880                	addi	s0,sp,80
    80004c28:	84aa                	mv	s1,a0
    80004c2a:	892e                	mv	s2,a1
    80004c2c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004c2e:	ffffd097          	auipc	ra,0xffffd
    80004c32:	efa080e7          	jalr	-262(ra) # 80001b28 <myproc>
    80004c36:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004c38:	8b26                	mv	s6,s1
    80004c3a:	8526                	mv	a0,s1
    80004c3c:	ffffc097          	auipc	ra,0xffffc
    80004c40:	fd4080e7          	jalr	-44(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c44:	2184a703          	lw	a4,536(s1)
    80004c48:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c4c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c50:	02f71463          	bne	a4,a5,80004c78 <piperead+0x64>
    80004c54:	2244a783          	lw	a5,548(s1)
    80004c58:	c385                	beqz	a5,80004c78 <piperead+0x64>
    if(pr->killed){
    80004c5a:	030a2783          	lw	a5,48(s4)
    80004c5e:	ebc1                	bnez	a5,80004cee <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c60:	85da                	mv	a1,s6
    80004c62:	854e                	mv	a0,s3
    80004c64:	ffffd097          	auipc	ra,0xffffd
    80004c68:	6d4080e7          	jalr	1748(ra) # 80002338 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c6c:	2184a703          	lw	a4,536(s1)
    80004c70:	21c4a783          	lw	a5,540(s1)
    80004c74:	fef700e3          	beq	a4,a5,80004c54 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c78:	09505263          	blez	s5,80004cfc <piperead+0xe8>
    80004c7c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c7e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c80:	2184a783          	lw	a5,536(s1)
    80004c84:	21c4a703          	lw	a4,540(s1)
    80004c88:	02f70d63          	beq	a4,a5,80004cc2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c8c:	0017871b          	addiw	a4,a5,1
    80004c90:	20e4ac23          	sw	a4,536(s1)
    80004c94:	1ff7f793          	andi	a5,a5,511
    80004c98:	97a6                	add	a5,a5,s1
    80004c9a:	0187c783          	lbu	a5,24(a5)
    80004c9e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004ca2:	4685                	li	a3,1
    80004ca4:	fbf40613          	addi	a2,s0,-65
    80004ca8:	85ca                	mv	a1,s2
    80004caa:	050a3503          	ld	a0,80(s4)
    80004cae:	ffffd097          	auipc	ra,0xffffd
    80004cb2:	bee080e7          	jalr	-1042(ra) # 8000189c <copyout>
    80004cb6:	01650663          	beq	a0,s6,80004cc2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cba:	2985                	addiw	s3,s3,1
    80004cbc:	0905                	addi	s2,s2,1
    80004cbe:	fd3a91e3          	bne	s5,s3,80004c80 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004cc2:	21c48513          	addi	a0,s1,540
    80004cc6:	ffffd097          	auipc	ra,0xffffd
    80004cca:	7f8080e7          	jalr	2040(ra) # 800024be <wakeup>
  release(&pi->lock);
    80004cce:	8526                	mv	a0,s1
    80004cd0:	ffffc097          	auipc	ra,0xffffc
    80004cd4:	ff4080e7          	jalr	-12(ra) # 80000cc4 <release>
  return i;
}
    80004cd8:	854e                	mv	a0,s3
    80004cda:	60a6                	ld	ra,72(sp)
    80004cdc:	6406                	ld	s0,64(sp)
    80004cde:	74e2                	ld	s1,56(sp)
    80004ce0:	7942                	ld	s2,48(sp)
    80004ce2:	79a2                	ld	s3,40(sp)
    80004ce4:	7a02                	ld	s4,32(sp)
    80004ce6:	6ae2                	ld	s5,24(sp)
    80004ce8:	6b42                	ld	s6,16(sp)
    80004cea:	6161                	addi	sp,sp,80
    80004cec:	8082                	ret
      release(&pi->lock);
    80004cee:	8526                	mv	a0,s1
    80004cf0:	ffffc097          	auipc	ra,0xffffc
    80004cf4:	fd4080e7          	jalr	-44(ra) # 80000cc4 <release>
      return -1;
    80004cf8:	59fd                	li	s3,-1
    80004cfa:	bff9                	j	80004cd8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cfc:	4981                	li	s3,0
    80004cfe:	b7d1                	j	80004cc2 <piperead+0xae>

0000000080004d00 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004d00:	df010113          	addi	sp,sp,-528
    80004d04:	20113423          	sd	ra,520(sp)
    80004d08:	20813023          	sd	s0,512(sp)
    80004d0c:	ffa6                	sd	s1,504(sp)
    80004d0e:	fbca                	sd	s2,496(sp)
    80004d10:	f7ce                	sd	s3,488(sp)
    80004d12:	f3d2                	sd	s4,480(sp)
    80004d14:	efd6                	sd	s5,472(sp)
    80004d16:	ebda                	sd	s6,464(sp)
    80004d18:	e7de                	sd	s7,456(sp)
    80004d1a:	e3e2                	sd	s8,448(sp)
    80004d1c:	ff66                	sd	s9,440(sp)
    80004d1e:	fb6a                	sd	s10,432(sp)
    80004d20:	f76e                	sd	s11,424(sp)
    80004d22:	0c00                	addi	s0,sp,528
    80004d24:	84aa                	mv	s1,a0
    80004d26:	dea43c23          	sd	a0,-520(s0)
    80004d2a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004d2e:	ffffd097          	auipc	ra,0xffffd
    80004d32:	dfa080e7          	jalr	-518(ra) # 80001b28 <myproc>
    80004d36:	892a                	mv	s2,a0

  begin_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	446080e7          	jalr	1094(ra) # 8000417e <begin_op>

  if((ip = namei(path)) == 0){
    80004d40:	8526                	mv	a0,s1
    80004d42:	fffff097          	auipc	ra,0xfffff
    80004d46:	230080e7          	jalr	560(ra) # 80003f72 <namei>
    80004d4a:	c92d                	beqz	a0,80004dbc <exec+0xbc>
    80004d4c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d4e:	fffff097          	auipc	ra,0xfffff
    80004d52:	a70080e7          	jalr	-1424(ra) # 800037be <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d56:	04000713          	li	a4,64
    80004d5a:	4681                	li	a3,0
    80004d5c:	e4840613          	addi	a2,s0,-440
    80004d60:	4581                	li	a1,0
    80004d62:	8526                	mv	a0,s1
    80004d64:	fffff097          	auipc	ra,0xfffff
    80004d68:	d0e080e7          	jalr	-754(ra) # 80003a72 <readi>
    80004d6c:	04000793          	li	a5,64
    80004d70:	00f51a63          	bne	a0,a5,80004d84 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d74:	e4842703          	lw	a4,-440(s0)
    80004d78:	464c47b7          	lui	a5,0x464c4
    80004d7c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d80:	04f70463          	beq	a4,a5,80004dc8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d84:	8526                	mv	a0,s1
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	c9a080e7          	jalr	-870(ra) # 80003a20 <iunlockput>
    end_op();
    80004d8e:	fffff097          	auipc	ra,0xfffff
    80004d92:	470080e7          	jalr	1136(ra) # 800041fe <end_op>
  }
  return -1;
    80004d96:	557d                	li	a0,-1
}
    80004d98:	20813083          	ld	ra,520(sp)
    80004d9c:	20013403          	ld	s0,512(sp)
    80004da0:	74fe                	ld	s1,504(sp)
    80004da2:	795e                	ld	s2,496(sp)
    80004da4:	79be                	ld	s3,488(sp)
    80004da6:	7a1e                	ld	s4,480(sp)
    80004da8:	6afe                	ld	s5,472(sp)
    80004daa:	6b5e                	ld	s6,464(sp)
    80004dac:	6bbe                	ld	s7,456(sp)
    80004dae:	6c1e                	ld	s8,448(sp)
    80004db0:	7cfa                	ld	s9,440(sp)
    80004db2:	7d5a                	ld	s10,432(sp)
    80004db4:	7dba                	ld	s11,424(sp)
    80004db6:	21010113          	addi	sp,sp,528
    80004dba:	8082                	ret
    end_op();
    80004dbc:	fffff097          	auipc	ra,0xfffff
    80004dc0:	442080e7          	jalr	1090(ra) # 800041fe <end_op>
    return -1;
    80004dc4:	557d                	li	a0,-1
    80004dc6:	bfc9                	j	80004d98 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004dc8:	854a                	mv	a0,s2
    80004dca:	ffffd097          	auipc	ra,0xffffd
    80004dce:	e22080e7          	jalr	-478(ra) # 80001bec <proc_pagetable>
    80004dd2:	8baa                	mv	s7,a0
    80004dd4:	d945                	beqz	a0,80004d84 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004dd6:	e6842983          	lw	s3,-408(s0)
    80004dda:	e8045783          	lhu	a5,-384(s0)
    80004dde:	c7ad                	beqz	a5,80004e48 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004de0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004de2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004de4:	6c85                	lui	s9,0x1
    80004de6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004dea:	def43823          	sd	a5,-528(s0)
    80004dee:	a42d                	j	80005018 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004df0:	00004517          	auipc	a0,0x4
    80004df4:	89050513          	addi	a0,a0,-1904 # 80008680 <syscalls+0x290>
    80004df8:	ffffb097          	auipc	ra,0xffffb
    80004dfc:	750080e7          	jalr	1872(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004e00:	8756                	mv	a4,s5
    80004e02:	012d86bb          	addw	a3,s11,s2
    80004e06:	4581                	li	a1,0
    80004e08:	8526                	mv	a0,s1
    80004e0a:	fffff097          	auipc	ra,0xfffff
    80004e0e:	c68080e7          	jalr	-920(ra) # 80003a72 <readi>
    80004e12:	2501                	sext.w	a0,a0
    80004e14:	1aaa9963          	bne	s5,a0,80004fc6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004e18:	6785                	lui	a5,0x1
    80004e1a:	0127893b          	addw	s2,a5,s2
    80004e1e:	77fd                	lui	a5,0xfffff
    80004e20:	01478a3b          	addw	s4,a5,s4
    80004e24:	1f897163          	bgeu	s2,s8,80005006 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004e28:	02091593          	slli	a1,s2,0x20
    80004e2c:	9181                	srli	a1,a1,0x20
    80004e2e:	95ea                	add	a1,a1,s10
    80004e30:	855e                	mv	a0,s7
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	26c080e7          	jalr	620(ra) # 8000109e <walkaddr>
    80004e3a:	862a                	mv	a2,a0
    if(pa == 0)
    80004e3c:	d955                	beqz	a0,80004df0 <exec+0xf0>
      n = PGSIZE;
    80004e3e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004e40:	fd9a70e3          	bgeu	s4,s9,80004e00 <exec+0x100>
      n = sz - i;
    80004e44:	8ad2                	mv	s5,s4
    80004e46:	bf6d                	j	80004e00 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e48:	4901                	li	s2,0
  iunlockput(ip);
    80004e4a:	8526                	mv	a0,s1
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	bd4080e7          	jalr	-1068(ra) # 80003a20 <iunlockput>
  end_op();
    80004e54:	fffff097          	auipc	ra,0xfffff
    80004e58:	3aa080e7          	jalr	938(ra) # 800041fe <end_op>
  p = myproc();
    80004e5c:	ffffd097          	auipc	ra,0xffffd
    80004e60:	ccc080e7          	jalr	-820(ra) # 80001b28 <myproc>
    80004e64:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e66:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e6a:	6785                	lui	a5,0x1
    80004e6c:	17fd                	addi	a5,a5,-1
    80004e6e:	993e                	add	s2,s2,a5
    80004e70:	757d                	lui	a0,0xfffff
    80004e72:	00a977b3          	and	a5,s2,a0
    80004e76:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e7a:	6609                	lui	a2,0x2
    80004e7c:	963e                	add	a2,a2,a5
    80004e7e:	85be                	mv	a1,a5
    80004e80:	855e                	mv	a0,s7
    80004e82:	ffffc097          	auipc	ra,0xffffc
    80004e86:	62a080e7          	jalr	1578(ra) # 800014ac <uvmalloc>
    80004e8a:	8b2a                	mv	s6,a0
  ip = 0;
    80004e8c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e8e:	12050c63          	beqz	a0,80004fc6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e92:	75f9                	lui	a1,0xffffe
    80004e94:	95aa                	add	a1,a1,a0
    80004e96:	855e                	mv	a0,s7
    80004e98:	ffffd097          	auipc	ra,0xffffd
    80004e9c:	8ac080e7          	jalr	-1876(ra) # 80001744 <uvmclear>
  stackbase = sp - PGSIZE;
    80004ea0:	7c7d                	lui	s8,0xfffff
    80004ea2:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ea4:	e0043783          	ld	a5,-512(s0)
    80004ea8:	6388                	ld	a0,0(a5)
    80004eaa:	c535                	beqz	a0,80004f16 <exec+0x216>
    80004eac:	e8840993          	addi	s3,s0,-376
    80004eb0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004eb4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004eb6:	ffffc097          	auipc	ra,0xffffc
    80004eba:	fde080e7          	jalr	-34(ra) # 80000e94 <strlen>
    80004ebe:	2505                	addiw	a0,a0,1
    80004ec0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004ec4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004ec8:	13896363          	bltu	s2,s8,80004fee <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004ecc:	e0043d83          	ld	s11,-512(s0)
    80004ed0:	000dba03          	ld	s4,0(s11)
    80004ed4:	8552                	mv	a0,s4
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	fbe080e7          	jalr	-66(ra) # 80000e94 <strlen>
    80004ede:	0015069b          	addiw	a3,a0,1
    80004ee2:	8652                	mv	a2,s4
    80004ee4:	85ca                	mv	a1,s2
    80004ee6:	855e                	mv	a0,s7
    80004ee8:	ffffd097          	auipc	ra,0xffffd
    80004eec:	9b4080e7          	jalr	-1612(ra) # 8000189c <copyout>
    80004ef0:	10054363          	bltz	a0,80004ff6 <exec+0x2f6>
    ustack[argc] = sp;
    80004ef4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004ef8:	0485                	addi	s1,s1,1
    80004efa:	008d8793          	addi	a5,s11,8
    80004efe:	e0f43023          	sd	a5,-512(s0)
    80004f02:	008db503          	ld	a0,8(s11)
    80004f06:	c911                	beqz	a0,80004f1a <exec+0x21a>
    if(argc >= MAXARG)
    80004f08:	09a1                	addi	s3,s3,8
    80004f0a:	fb3c96e3          	bne	s9,s3,80004eb6 <exec+0x1b6>
  sz = sz1;
    80004f0e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f12:	4481                	li	s1,0
    80004f14:	a84d                	j	80004fc6 <exec+0x2c6>
  sp = sz;
    80004f16:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004f18:	4481                	li	s1,0
  ustack[argc] = 0;
    80004f1a:	00349793          	slli	a5,s1,0x3
    80004f1e:	f9040713          	addi	a4,s0,-112
    80004f22:	97ba                	add	a5,a5,a4
    80004f24:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004f28:	00148693          	addi	a3,s1,1
    80004f2c:	068e                	slli	a3,a3,0x3
    80004f2e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004f32:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004f36:	01897663          	bgeu	s2,s8,80004f42 <exec+0x242>
  sz = sz1;
    80004f3a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f3e:	4481                	li	s1,0
    80004f40:	a059                	j	80004fc6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004f42:	e8840613          	addi	a2,s0,-376
    80004f46:	85ca                	mv	a1,s2
    80004f48:	855e                	mv	a0,s7
    80004f4a:	ffffd097          	auipc	ra,0xffffd
    80004f4e:	952080e7          	jalr	-1710(ra) # 8000189c <copyout>
    80004f52:	0a054663          	bltz	a0,80004ffe <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f56:	058ab783          	ld	a5,88(s5)
    80004f5a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f5e:	df843783          	ld	a5,-520(s0)
    80004f62:	0007c703          	lbu	a4,0(a5)
    80004f66:	cf11                	beqz	a4,80004f82 <exec+0x282>
    80004f68:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f6a:	02f00693          	li	a3,47
    80004f6e:	a029                	j	80004f78 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f70:	0785                	addi	a5,a5,1
    80004f72:	fff7c703          	lbu	a4,-1(a5)
    80004f76:	c711                	beqz	a4,80004f82 <exec+0x282>
    if(*s == '/')
    80004f78:	fed71ce3          	bne	a4,a3,80004f70 <exec+0x270>
      last = s+1;
    80004f7c:	def43c23          	sd	a5,-520(s0)
    80004f80:	bfc5                	j	80004f70 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f82:	4641                	li	a2,16
    80004f84:	df843583          	ld	a1,-520(s0)
    80004f88:	158a8513          	addi	a0,s5,344
    80004f8c:	ffffc097          	auipc	ra,0xffffc
    80004f90:	ed6080e7          	jalr	-298(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f94:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f98:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f9c:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004fa0:	058ab783          	ld	a5,88(s5)
    80004fa4:	e6043703          	ld	a4,-416(s0)
    80004fa8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004faa:	058ab783          	ld	a5,88(s5)
    80004fae:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004fb2:	85ea                	mv	a1,s10
    80004fb4:	ffffd097          	auipc	ra,0xffffd
    80004fb8:	cd4080e7          	jalr	-812(ra) # 80001c88 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004fbc:	0004851b          	sext.w	a0,s1
    80004fc0:	bbe1                	j	80004d98 <exec+0x98>
    80004fc2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004fc6:	e0843583          	ld	a1,-504(s0)
    80004fca:	855e                	mv	a0,s7
    80004fcc:	ffffd097          	auipc	ra,0xffffd
    80004fd0:	cbc080e7          	jalr	-836(ra) # 80001c88 <proc_freepagetable>
  if(ip){
    80004fd4:	da0498e3          	bnez	s1,80004d84 <exec+0x84>
  return -1;
    80004fd8:	557d                	li	a0,-1
    80004fda:	bb7d                	j	80004d98 <exec+0x98>
    80004fdc:	e1243423          	sd	s2,-504(s0)
    80004fe0:	b7dd                	j	80004fc6 <exec+0x2c6>
    80004fe2:	e1243423          	sd	s2,-504(s0)
    80004fe6:	b7c5                	j	80004fc6 <exec+0x2c6>
    80004fe8:	e1243423          	sd	s2,-504(s0)
    80004fec:	bfe9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004fee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ff2:	4481                	li	s1,0
    80004ff4:	bfc9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004ff6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ffa:	4481                	li	s1,0
    80004ffc:	b7e9                	j	80004fc6 <exec+0x2c6>
  sz = sz1;
    80004ffe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005002:	4481                	li	s1,0
    80005004:	b7c9                	j	80004fc6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005006:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000500a:	2b05                	addiw	s6,s6,1
    8000500c:	0389899b          	addiw	s3,s3,56
    80005010:	e8045783          	lhu	a5,-384(s0)
    80005014:	e2fb5be3          	bge	s6,a5,80004e4a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005018:	2981                	sext.w	s3,s3
    8000501a:	03800713          	li	a4,56
    8000501e:	86ce                	mv	a3,s3
    80005020:	e1040613          	addi	a2,s0,-496
    80005024:	4581                	li	a1,0
    80005026:	8526                	mv	a0,s1
    80005028:	fffff097          	auipc	ra,0xfffff
    8000502c:	a4a080e7          	jalr	-1462(ra) # 80003a72 <readi>
    80005030:	03800793          	li	a5,56
    80005034:	f8f517e3          	bne	a0,a5,80004fc2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005038:	e1042783          	lw	a5,-496(s0)
    8000503c:	4705                	li	a4,1
    8000503e:	fce796e3          	bne	a5,a4,8000500a <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005042:	e3843603          	ld	a2,-456(s0)
    80005046:	e3043783          	ld	a5,-464(s0)
    8000504a:	f8f669e3          	bltu	a2,a5,80004fdc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000504e:	e2043783          	ld	a5,-480(s0)
    80005052:	963e                	add	a2,a2,a5
    80005054:	f8f667e3          	bltu	a2,a5,80004fe2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005058:	85ca                	mv	a1,s2
    8000505a:	855e                	mv	a0,s7
    8000505c:	ffffc097          	auipc	ra,0xffffc
    80005060:	450080e7          	jalr	1104(ra) # 800014ac <uvmalloc>
    80005064:	e0a43423          	sd	a0,-504(s0)
    80005068:	d141                	beqz	a0,80004fe8 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000506a:	e2043d03          	ld	s10,-480(s0)
    8000506e:	df043783          	ld	a5,-528(s0)
    80005072:	00fd77b3          	and	a5,s10,a5
    80005076:	fba1                	bnez	a5,80004fc6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005078:	e1842d83          	lw	s11,-488(s0)
    8000507c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005080:	f80c03e3          	beqz	s8,80005006 <exec+0x306>
    80005084:	8a62                	mv	s4,s8
    80005086:	4901                	li	s2,0
    80005088:	b345                	j	80004e28 <exec+0x128>

000000008000508a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000508a:	7179                	addi	sp,sp,-48
    8000508c:	f406                	sd	ra,40(sp)
    8000508e:	f022                	sd	s0,32(sp)
    80005090:	ec26                	sd	s1,24(sp)
    80005092:	e84a                	sd	s2,16(sp)
    80005094:	1800                	addi	s0,sp,48
    80005096:	892e                	mv	s2,a1
    80005098:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000509a:	fdc40593          	addi	a1,s0,-36
    8000509e:	ffffe097          	auipc	ra,0xffffe
    800050a2:	bae080e7          	jalr	-1106(ra) # 80002c4c <argint>
    800050a6:	04054063          	bltz	a0,800050e6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800050aa:	fdc42703          	lw	a4,-36(s0)
    800050ae:	47bd                	li	a5,15
    800050b0:	02e7ed63          	bltu	a5,a4,800050ea <argfd+0x60>
    800050b4:	ffffd097          	auipc	ra,0xffffd
    800050b8:	a74080e7          	jalr	-1420(ra) # 80001b28 <myproc>
    800050bc:	fdc42703          	lw	a4,-36(s0)
    800050c0:	01a70793          	addi	a5,a4,26
    800050c4:	078e                	slli	a5,a5,0x3
    800050c6:	953e                	add	a0,a0,a5
    800050c8:	611c                	ld	a5,0(a0)
    800050ca:	c395                	beqz	a5,800050ee <argfd+0x64>
    return -1;
  if(pfd)
    800050cc:	00090463          	beqz	s2,800050d4 <argfd+0x4a>
    *pfd = fd;
    800050d0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800050d4:	4501                	li	a0,0
  if(pf)
    800050d6:	c091                	beqz	s1,800050da <argfd+0x50>
    *pf = f;
    800050d8:	e09c                	sd	a5,0(s1)
}
    800050da:	70a2                	ld	ra,40(sp)
    800050dc:	7402                	ld	s0,32(sp)
    800050de:	64e2                	ld	s1,24(sp)
    800050e0:	6942                	ld	s2,16(sp)
    800050e2:	6145                	addi	sp,sp,48
    800050e4:	8082                	ret
    return -1;
    800050e6:	557d                	li	a0,-1
    800050e8:	bfcd                	j	800050da <argfd+0x50>
    return -1;
    800050ea:	557d                	li	a0,-1
    800050ec:	b7fd                	j	800050da <argfd+0x50>
    800050ee:	557d                	li	a0,-1
    800050f0:	b7ed                	j	800050da <argfd+0x50>

00000000800050f2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050f2:	1101                	addi	sp,sp,-32
    800050f4:	ec06                	sd	ra,24(sp)
    800050f6:	e822                	sd	s0,16(sp)
    800050f8:	e426                	sd	s1,8(sp)
    800050fa:	1000                	addi	s0,sp,32
    800050fc:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050fe:	ffffd097          	auipc	ra,0xffffd
    80005102:	a2a080e7          	jalr	-1494(ra) # 80001b28 <myproc>
    80005106:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005108:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    8000510c:	4501                	li	a0,0
    8000510e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005110:	6398                	ld	a4,0(a5)
    80005112:	cb19                	beqz	a4,80005128 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005114:	2505                	addiw	a0,a0,1
    80005116:	07a1                	addi	a5,a5,8
    80005118:	fed51ce3          	bne	a0,a3,80005110 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000511c:	557d                	li	a0,-1
}
    8000511e:	60e2                	ld	ra,24(sp)
    80005120:	6442                	ld	s0,16(sp)
    80005122:	64a2                	ld	s1,8(sp)
    80005124:	6105                	addi	sp,sp,32
    80005126:	8082                	ret
      p->ofile[fd] = f;
    80005128:	01a50793          	addi	a5,a0,26
    8000512c:	078e                	slli	a5,a5,0x3
    8000512e:	963e                	add	a2,a2,a5
    80005130:	e204                	sd	s1,0(a2)
      return fd;
    80005132:	b7f5                	j	8000511e <fdalloc+0x2c>

0000000080005134 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005134:	715d                	addi	sp,sp,-80
    80005136:	e486                	sd	ra,72(sp)
    80005138:	e0a2                	sd	s0,64(sp)
    8000513a:	fc26                	sd	s1,56(sp)
    8000513c:	f84a                	sd	s2,48(sp)
    8000513e:	f44e                	sd	s3,40(sp)
    80005140:	f052                	sd	s4,32(sp)
    80005142:	ec56                	sd	s5,24(sp)
    80005144:	0880                	addi	s0,sp,80
    80005146:	89ae                	mv	s3,a1
    80005148:	8ab2                	mv	s5,a2
    8000514a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000514c:	fb040593          	addi	a1,s0,-80
    80005150:	fffff097          	auipc	ra,0xfffff
    80005154:	e40080e7          	jalr	-448(ra) # 80003f90 <nameiparent>
    80005158:	892a                	mv	s2,a0
    8000515a:	12050f63          	beqz	a0,80005298 <create+0x164>
    return 0;

  ilock(dp);
    8000515e:	ffffe097          	auipc	ra,0xffffe
    80005162:	660080e7          	jalr	1632(ra) # 800037be <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005166:	4601                	li	a2,0
    80005168:	fb040593          	addi	a1,s0,-80
    8000516c:	854a                	mv	a0,s2
    8000516e:	fffff097          	auipc	ra,0xfffff
    80005172:	b32080e7          	jalr	-1230(ra) # 80003ca0 <dirlookup>
    80005176:	84aa                	mv	s1,a0
    80005178:	c921                	beqz	a0,800051c8 <create+0x94>
    iunlockput(dp);
    8000517a:	854a                	mv	a0,s2
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	8a4080e7          	jalr	-1884(ra) # 80003a20 <iunlockput>
    ilock(ip);
    80005184:	8526                	mv	a0,s1
    80005186:	ffffe097          	auipc	ra,0xffffe
    8000518a:	638080e7          	jalr	1592(ra) # 800037be <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000518e:	2981                	sext.w	s3,s3
    80005190:	4789                	li	a5,2
    80005192:	02f99463          	bne	s3,a5,800051ba <create+0x86>
    80005196:	0444d783          	lhu	a5,68(s1)
    8000519a:	37f9                	addiw	a5,a5,-2
    8000519c:	17c2                	slli	a5,a5,0x30
    8000519e:	93c1                	srli	a5,a5,0x30
    800051a0:	4705                	li	a4,1
    800051a2:	00f76c63          	bltu	a4,a5,800051ba <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800051a6:	8526                	mv	a0,s1
    800051a8:	60a6                	ld	ra,72(sp)
    800051aa:	6406                	ld	s0,64(sp)
    800051ac:	74e2                	ld	s1,56(sp)
    800051ae:	7942                	ld	s2,48(sp)
    800051b0:	79a2                	ld	s3,40(sp)
    800051b2:	7a02                	ld	s4,32(sp)
    800051b4:	6ae2                	ld	s5,24(sp)
    800051b6:	6161                	addi	sp,sp,80
    800051b8:	8082                	ret
    iunlockput(ip);
    800051ba:	8526                	mv	a0,s1
    800051bc:	fffff097          	auipc	ra,0xfffff
    800051c0:	864080e7          	jalr	-1948(ra) # 80003a20 <iunlockput>
    return 0;
    800051c4:	4481                	li	s1,0
    800051c6:	b7c5                	j	800051a6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800051c8:	85ce                	mv	a1,s3
    800051ca:	00092503          	lw	a0,0(s2)
    800051ce:	ffffe097          	auipc	ra,0xffffe
    800051d2:	458080e7          	jalr	1112(ra) # 80003626 <ialloc>
    800051d6:	84aa                	mv	s1,a0
    800051d8:	c529                	beqz	a0,80005222 <create+0xee>
  ilock(ip);
    800051da:	ffffe097          	auipc	ra,0xffffe
    800051de:	5e4080e7          	jalr	1508(ra) # 800037be <ilock>
  ip->major = major;
    800051e2:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051e6:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051ea:	4785                	li	a5,1
    800051ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051f0:	8526                	mv	a0,s1
    800051f2:	ffffe097          	auipc	ra,0xffffe
    800051f6:	502080e7          	jalr	1282(ra) # 800036f4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051fa:	2981                	sext.w	s3,s3
    800051fc:	4785                	li	a5,1
    800051fe:	02f98a63          	beq	s3,a5,80005232 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005202:	40d0                	lw	a2,4(s1)
    80005204:	fb040593          	addi	a1,s0,-80
    80005208:	854a                	mv	a0,s2
    8000520a:	fffff097          	auipc	ra,0xfffff
    8000520e:	ca6080e7          	jalr	-858(ra) # 80003eb0 <dirlink>
    80005212:	06054b63          	bltz	a0,80005288 <create+0x154>
  iunlockput(dp);
    80005216:	854a                	mv	a0,s2
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	808080e7          	jalr	-2040(ra) # 80003a20 <iunlockput>
  return ip;
    80005220:	b759                	j	800051a6 <create+0x72>
    panic("create: ialloc");
    80005222:	00003517          	auipc	a0,0x3
    80005226:	47e50513          	addi	a0,a0,1150 # 800086a0 <syscalls+0x2b0>
    8000522a:	ffffb097          	auipc	ra,0xffffb
    8000522e:	31e080e7          	jalr	798(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005232:	04a95783          	lhu	a5,74(s2)
    80005236:	2785                	addiw	a5,a5,1
    80005238:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000523c:	854a                	mv	a0,s2
    8000523e:	ffffe097          	auipc	ra,0xffffe
    80005242:	4b6080e7          	jalr	1206(ra) # 800036f4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005246:	40d0                	lw	a2,4(s1)
    80005248:	00003597          	auipc	a1,0x3
    8000524c:	46858593          	addi	a1,a1,1128 # 800086b0 <syscalls+0x2c0>
    80005250:	8526                	mv	a0,s1
    80005252:	fffff097          	auipc	ra,0xfffff
    80005256:	c5e080e7          	jalr	-930(ra) # 80003eb0 <dirlink>
    8000525a:	00054f63          	bltz	a0,80005278 <create+0x144>
    8000525e:	00492603          	lw	a2,4(s2)
    80005262:	00003597          	auipc	a1,0x3
    80005266:	45658593          	addi	a1,a1,1110 # 800086b8 <syscalls+0x2c8>
    8000526a:	8526                	mv	a0,s1
    8000526c:	fffff097          	auipc	ra,0xfffff
    80005270:	c44080e7          	jalr	-956(ra) # 80003eb0 <dirlink>
    80005274:	f80557e3          	bgez	a0,80005202 <create+0xce>
      panic("create dots");
    80005278:	00003517          	auipc	a0,0x3
    8000527c:	44850513          	addi	a0,a0,1096 # 800086c0 <syscalls+0x2d0>
    80005280:	ffffb097          	auipc	ra,0xffffb
    80005284:	2c8080e7          	jalr	712(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005288:	00003517          	auipc	a0,0x3
    8000528c:	44850513          	addi	a0,a0,1096 # 800086d0 <syscalls+0x2e0>
    80005290:	ffffb097          	auipc	ra,0xffffb
    80005294:	2b8080e7          	jalr	696(ra) # 80000548 <panic>
    return 0;
    80005298:	84aa                	mv	s1,a0
    8000529a:	b731                	j	800051a6 <create+0x72>

000000008000529c <sys_dup>:
{
    8000529c:	7179                	addi	sp,sp,-48
    8000529e:	f406                	sd	ra,40(sp)
    800052a0:	f022                	sd	s0,32(sp)
    800052a2:	ec26                	sd	s1,24(sp)
    800052a4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800052a6:	fd840613          	addi	a2,s0,-40
    800052aa:	4581                	li	a1,0
    800052ac:	4501                	li	a0,0
    800052ae:	00000097          	auipc	ra,0x0
    800052b2:	ddc080e7          	jalr	-548(ra) # 8000508a <argfd>
    return -1;
    800052b6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800052b8:	02054363          	bltz	a0,800052de <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800052bc:	fd843503          	ld	a0,-40(s0)
    800052c0:	00000097          	auipc	ra,0x0
    800052c4:	e32080e7          	jalr	-462(ra) # 800050f2 <fdalloc>
    800052c8:	84aa                	mv	s1,a0
    return -1;
    800052ca:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052cc:	00054963          	bltz	a0,800052de <sys_dup+0x42>
  filedup(f);
    800052d0:	fd843503          	ld	a0,-40(s0)
    800052d4:	fffff097          	auipc	ra,0xfffff
    800052d8:	32a080e7          	jalr	810(ra) # 800045fe <filedup>
  return fd;
    800052dc:	87a6                	mv	a5,s1
}
    800052de:	853e                	mv	a0,a5
    800052e0:	70a2                	ld	ra,40(sp)
    800052e2:	7402                	ld	s0,32(sp)
    800052e4:	64e2                	ld	s1,24(sp)
    800052e6:	6145                	addi	sp,sp,48
    800052e8:	8082                	ret

00000000800052ea <sys_read>:
{
    800052ea:	7179                	addi	sp,sp,-48
    800052ec:	f406                	sd	ra,40(sp)
    800052ee:	f022                	sd	s0,32(sp)
    800052f0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052f2:	fe840613          	addi	a2,s0,-24
    800052f6:	4581                	li	a1,0
    800052f8:	4501                	li	a0,0
    800052fa:	00000097          	auipc	ra,0x0
    800052fe:	d90080e7          	jalr	-624(ra) # 8000508a <argfd>
    return -1;
    80005302:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005304:	04054163          	bltz	a0,80005346 <sys_read+0x5c>
    80005308:	fe440593          	addi	a1,s0,-28
    8000530c:	4509                	li	a0,2
    8000530e:	ffffe097          	auipc	ra,0xffffe
    80005312:	93e080e7          	jalr	-1730(ra) # 80002c4c <argint>
    return -1;
    80005316:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005318:	02054763          	bltz	a0,80005346 <sys_read+0x5c>
    8000531c:	fd840593          	addi	a1,s0,-40
    80005320:	4505                	li	a0,1
    80005322:	ffffe097          	auipc	ra,0xffffe
    80005326:	94c080e7          	jalr	-1716(ra) # 80002c6e <argaddr>
    return -1;
    8000532a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000532c:	00054d63          	bltz	a0,80005346 <sys_read+0x5c>
  return fileread(f, p, n);
    80005330:	fe442603          	lw	a2,-28(s0)
    80005334:	fd843583          	ld	a1,-40(s0)
    80005338:	fe843503          	ld	a0,-24(s0)
    8000533c:	fffff097          	auipc	ra,0xfffff
    80005340:	44e080e7          	jalr	1102(ra) # 8000478a <fileread>
    80005344:	87aa                	mv	a5,a0
}
    80005346:	853e                	mv	a0,a5
    80005348:	70a2                	ld	ra,40(sp)
    8000534a:	7402                	ld	s0,32(sp)
    8000534c:	6145                	addi	sp,sp,48
    8000534e:	8082                	ret

0000000080005350 <sys_write>:
{
    80005350:	7179                	addi	sp,sp,-48
    80005352:	f406                	sd	ra,40(sp)
    80005354:	f022                	sd	s0,32(sp)
    80005356:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005358:	fe840613          	addi	a2,s0,-24
    8000535c:	4581                	li	a1,0
    8000535e:	4501                	li	a0,0
    80005360:	00000097          	auipc	ra,0x0
    80005364:	d2a080e7          	jalr	-726(ra) # 8000508a <argfd>
    return -1;
    80005368:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000536a:	04054163          	bltz	a0,800053ac <sys_write+0x5c>
    8000536e:	fe440593          	addi	a1,s0,-28
    80005372:	4509                	li	a0,2
    80005374:	ffffe097          	auipc	ra,0xffffe
    80005378:	8d8080e7          	jalr	-1832(ra) # 80002c4c <argint>
    return -1;
    8000537c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000537e:	02054763          	bltz	a0,800053ac <sys_write+0x5c>
    80005382:	fd840593          	addi	a1,s0,-40
    80005386:	4505                	li	a0,1
    80005388:	ffffe097          	auipc	ra,0xffffe
    8000538c:	8e6080e7          	jalr	-1818(ra) # 80002c6e <argaddr>
    return -1;
    80005390:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005392:	00054d63          	bltz	a0,800053ac <sys_write+0x5c>
  return filewrite(f, p, n);
    80005396:	fe442603          	lw	a2,-28(s0)
    8000539a:	fd843583          	ld	a1,-40(s0)
    8000539e:	fe843503          	ld	a0,-24(s0)
    800053a2:	fffff097          	auipc	ra,0xfffff
    800053a6:	4aa080e7          	jalr	1194(ra) # 8000484c <filewrite>
    800053aa:	87aa                	mv	a5,a0
}
    800053ac:	853e                	mv	a0,a5
    800053ae:	70a2                	ld	ra,40(sp)
    800053b0:	7402                	ld	s0,32(sp)
    800053b2:	6145                	addi	sp,sp,48
    800053b4:	8082                	ret

00000000800053b6 <sys_close>:
{
    800053b6:	1101                	addi	sp,sp,-32
    800053b8:	ec06                	sd	ra,24(sp)
    800053ba:	e822                	sd	s0,16(sp)
    800053bc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800053be:	fe040613          	addi	a2,s0,-32
    800053c2:	fec40593          	addi	a1,s0,-20
    800053c6:	4501                	li	a0,0
    800053c8:	00000097          	auipc	ra,0x0
    800053cc:	cc2080e7          	jalr	-830(ra) # 8000508a <argfd>
    return -1;
    800053d0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800053d2:	02054463          	bltz	a0,800053fa <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800053d6:	ffffc097          	auipc	ra,0xffffc
    800053da:	752080e7          	jalr	1874(ra) # 80001b28 <myproc>
    800053de:	fec42783          	lw	a5,-20(s0)
    800053e2:	07e9                	addi	a5,a5,26
    800053e4:	078e                	slli	a5,a5,0x3
    800053e6:	97aa                	add	a5,a5,a0
    800053e8:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053ec:	fe043503          	ld	a0,-32(s0)
    800053f0:	fffff097          	auipc	ra,0xfffff
    800053f4:	260080e7          	jalr	608(ra) # 80004650 <fileclose>
  return 0;
    800053f8:	4781                	li	a5,0
}
    800053fa:	853e                	mv	a0,a5
    800053fc:	60e2                	ld	ra,24(sp)
    800053fe:	6442                	ld	s0,16(sp)
    80005400:	6105                	addi	sp,sp,32
    80005402:	8082                	ret

0000000080005404 <sys_fstat>:
{
    80005404:	1101                	addi	sp,sp,-32
    80005406:	ec06                	sd	ra,24(sp)
    80005408:	e822                	sd	s0,16(sp)
    8000540a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000540c:	fe840613          	addi	a2,s0,-24
    80005410:	4581                	li	a1,0
    80005412:	4501                	li	a0,0
    80005414:	00000097          	auipc	ra,0x0
    80005418:	c76080e7          	jalr	-906(ra) # 8000508a <argfd>
    return -1;
    8000541c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000541e:	02054563          	bltz	a0,80005448 <sys_fstat+0x44>
    80005422:	fe040593          	addi	a1,s0,-32
    80005426:	4505                	li	a0,1
    80005428:	ffffe097          	auipc	ra,0xffffe
    8000542c:	846080e7          	jalr	-1978(ra) # 80002c6e <argaddr>
    return -1;
    80005430:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005432:	00054b63          	bltz	a0,80005448 <sys_fstat+0x44>
  return filestat(f, st);
    80005436:	fe043583          	ld	a1,-32(s0)
    8000543a:	fe843503          	ld	a0,-24(s0)
    8000543e:	fffff097          	auipc	ra,0xfffff
    80005442:	2da080e7          	jalr	730(ra) # 80004718 <filestat>
    80005446:	87aa                	mv	a5,a0
}
    80005448:	853e                	mv	a0,a5
    8000544a:	60e2                	ld	ra,24(sp)
    8000544c:	6442                	ld	s0,16(sp)
    8000544e:	6105                	addi	sp,sp,32
    80005450:	8082                	ret

0000000080005452 <sys_link>:
{
    80005452:	7169                	addi	sp,sp,-304
    80005454:	f606                	sd	ra,296(sp)
    80005456:	f222                	sd	s0,288(sp)
    80005458:	ee26                	sd	s1,280(sp)
    8000545a:	ea4a                	sd	s2,272(sp)
    8000545c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000545e:	08000613          	li	a2,128
    80005462:	ed040593          	addi	a1,s0,-304
    80005466:	4501                	li	a0,0
    80005468:	ffffe097          	auipc	ra,0xffffe
    8000546c:	828080e7          	jalr	-2008(ra) # 80002c90 <argstr>
    return -1;
    80005470:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005472:	10054e63          	bltz	a0,8000558e <sys_link+0x13c>
    80005476:	08000613          	li	a2,128
    8000547a:	f5040593          	addi	a1,s0,-176
    8000547e:	4505                	li	a0,1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	810080e7          	jalr	-2032(ra) # 80002c90 <argstr>
    return -1;
    80005488:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000548a:	10054263          	bltz	a0,8000558e <sys_link+0x13c>
  begin_op();
    8000548e:	fffff097          	auipc	ra,0xfffff
    80005492:	cf0080e7          	jalr	-784(ra) # 8000417e <begin_op>
  if((ip = namei(old)) == 0){
    80005496:	ed040513          	addi	a0,s0,-304
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	ad8080e7          	jalr	-1320(ra) # 80003f72 <namei>
    800054a2:	84aa                	mv	s1,a0
    800054a4:	c551                	beqz	a0,80005530 <sys_link+0xde>
  ilock(ip);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	318080e7          	jalr	792(ra) # 800037be <ilock>
  if(ip->type == T_DIR){
    800054ae:	04449703          	lh	a4,68(s1)
    800054b2:	4785                	li	a5,1
    800054b4:	08f70463          	beq	a4,a5,8000553c <sys_link+0xea>
  ip->nlink++;
    800054b8:	04a4d783          	lhu	a5,74(s1)
    800054bc:	2785                	addiw	a5,a5,1
    800054be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054c2:	8526                	mv	a0,s1
    800054c4:	ffffe097          	auipc	ra,0xffffe
    800054c8:	230080e7          	jalr	560(ra) # 800036f4 <iupdate>
  iunlock(ip);
    800054cc:	8526                	mv	a0,s1
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	3b2080e7          	jalr	946(ra) # 80003880 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800054d6:	fd040593          	addi	a1,s0,-48
    800054da:	f5040513          	addi	a0,s0,-176
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	ab2080e7          	jalr	-1358(ra) # 80003f90 <nameiparent>
    800054e6:	892a                	mv	s2,a0
    800054e8:	c935                	beqz	a0,8000555c <sys_link+0x10a>
  ilock(dp);
    800054ea:	ffffe097          	auipc	ra,0xffffe
    800054ee:	2d4080e7          	jalr	724(ra) # 800037be <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054f2:	00092703          	lw	a4,0(s2)
    800054f6:	409c                	lw	a5,0(s1)
    800054f8:	04f71d63          	bne	a4,a5,80005552 <sys_link+0x100>
    800054fc:	40d0                	lw	a2,4(s1)
    800054fe:	fd040593          	addi	a1,s0,-48
    80005502:	854a                	mv	a0,s2
    80005504:	fffff097          	auipc	ra,0xfffff
    80005508:	9ac080e7          	jalr	-1620(ra) # 80003eb0 <dirlink>
    8000550c:	04054363          	bltz	a0,80005552 <sys_link+0x100>
  iunlockput(dp);
    80005510:	854a                	mv	a0,s2
    80005512:	ffffe097          	auipc	ra,0xffffe
    80005516:	50e080e7          	jalr	1294(ra) # 80003a20 <iunlockput>
  iput(ip);
    8000551a:	8526                	mv	a0,s1
    8000551c:	ffffe097          	auipc	ra,0xffffe
    80005520:	45c080e7          	jalr	1116(ra) # 80003978 <iput>
  end_op();
    80005524:	fffff097          	auipc	ra,0xfffff
    80005528:	cda080e7          	jalr	-806(ra) # 800041fe <end_op>
  return 0;
    8000552c:	4781                	li	a5,0
    8000552e:	a085                	j	8000558e <sys_link+0x13c>
    end_op();
    80005530:	fffff097          	auipc	ra,0xfffff
    80005534:	cce080e7          	jalr	-818(ra) # 800041fe <end_op>
    return -1;
    80005538:	57fd                	li	a5,-1
    8000553a:	a891                	j	8000558e <sys_link+0x13c>
    iunlockput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	4e2080e7          	jalr	1250(ra) # 80003a20 <iunlockput>
    end_op();
    80005546:	fffff097          	auipc	ra,0xfffff
    8000554a:	cb8080e7          	jalr	-840(ra) # 800041fe <end_op>
    return -1;
    8000554e:	57fd                	li	a5,-1
    80005550:	a83d                	j	8000558e <sys_link+0x13c>
    iunlockput(dp);
    80005552:	854a                	mv	a0,s2
    80005554:	ffffe097          	auipc	ra,0xffffe
    80005558:	4cc080e7          	jalr	1228(ra) # 80003a20 <iunlockput>
  ilock(ip);
    8000555c:	8526                	mv	a0,s1
    8000555e:	ffffe097          	auipc	ra,0xffffe
    80005562:	260080e7          	jalr	608(ra) # 800037be <ilock>
  ip->nlink--;
    80005566:	04a4d783          	lhu	a5,74(s1)
    8000556a:	37fd                	addiw	a5,a5,-1
    8000556c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005570:	8526                	mv	a0,s1
    80005572:	ffffe097          	auipc	ra,0xffffe
    80005576:	182080e7          	jalr	386(ra) # 800036f4 <iupdate>
  iunlockput(ip);
    8000557a:	8526                	mv	a0,s1
    8000557c:	ffffe097          	auipc	ra,0xffffe
    80005580:	4a4080e7          	jalr	1188(ra) # 80003a20 <iunlockput>
  end_op();
    80005584:	fffff097          	auipc	ra,0xfffff
    80005588:	c7a080e7          	jalr	-902(ra) # 800041fe <end_op>
  return -1;
    8000558c:	57fd                	li	a5,-1
}
    8000558e:	853e                	mv	a0,a5
    80005590:	70b2                	ld	ra,296(sp)
    80005592:	7412                	ld	s0,288(sp)
    80005594:	64f2                	ld	s1,280(sp)
    80005596:	6952                	ld	s2,272(sp)
    80005598:	6155                	addi	sp,sp,304
    8000559a:	8082                	ret

000000008000559c <sys_unlink>:
{
    8000559c:	7151                	addi	sp,sp,-240
    8000559e:	f586                	sd	ra,232(sp)
    800055a0:	f1a2                	sd	s0,224(sp)
    800055a2:	eda6                	sd	s1,216(sp)
    800055a4:	e9ca                	sd	s2,208(sp)
    800055a6:	e5ce                	sd	s3,200(sp)
    800055a8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800055aa:	08000613          	li	a2,128
    800055ae:	f3040593          	addi	a1,s0,-208
    800055b2:	4501                	li	a0,0
    800055b4:	ffffd097          	auipc	ra,0xffffd
    800055b8:	6dc080e7          	jalr	1756(ra) # 80002c90 <argstr>
    800055bc:	18054163          	bltz	a0,8000573e <sys_unlink+0x1a2>
  begin_op();
    800055c0:	fffff097          	auipc	ra,0xfffff
    800055c4:	bbe080e7          	jalr	-1090(ra) # 8000417e <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800055c8:	fb040593          	addi	a1,s0,-80
    800055cc:	f3040513          	addi	a0,s0,-208
    800055d0:	fffff097          	auipc	ra,0xfffff
    800055d4:	9c0080e7          	jalr	-1600(ra) # 80003f90 <nameiparent>
    800055d8:	84aa                	mv	s1,a0
    800055da:	c979                	beqz	a0,800056b0 <sys_unlink+0x114>
  ilock(dp);
    800055dc:	ffffe097          	auipc	ra,0xffffe
    800055e0:	1e2080e7          	jalr	482(ra) # 800037be <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055e4:	00003597          	auipc	a1,0x3
    800055e8:	0cc58593          	addi	a1,a1,204 # 800086b0 <syscalls+0x2c0>
    800055ec:	fb040513          	addi	a0,s0,-80
    800055f0:	ffffe097          	auipc	ra,0xffffe
    800055f4:	696080e7          	jalr	1686(ra) # 80003c86 <namecmp>
    800055f8:	14050a63          	beqz	a0,8000574c <sys_unlink+0x1b0>
    800055fc:	00003597          	auipc	a1,0x3
    80005600:	0bc58593          	addi	a1,a1,188 # 800086b8 <syscalls+0x2c8>
    80005604:	fb040513          	addi	a0,s0,-80
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	67e080e7          	jalr	1662(ra) # 80003c86 <namecmp>
    80005610:	12050e63          	beqz	a0,8000574c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005614:	f2c40613          	addi	a2,s0,-212
    80005618:	fb040593          	addi	a1,s0,-80
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	682080e7          	jalr	1666(ra) # 80003ca0 <dirlookup>
    80005626:	892a                	mv	s2,a0
    80005628:	12050263          	beqz	a0,8000574c <sys_unlink+0x1b0>
  ilock(ip);
    8000562c:	ffffe097          	auipc	ra,0xffffe
    80005630:	192080e7          	jalr	402(ra) # 800037be <ilock>
  if(ip->nlink < 1)
    80005634:	04a91783          	lh	a5,74(s2)
    80005638:	08f05263          	blez	a5,800056bc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000563c:	04491703          	lh	a4,68(s2)
    80005640:	4785                	li	a5,1
    80005642:	08f70563          	beq	a4,a5,800056cc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005646:	4641                	li	a2,16
    80005648:	4581                	li	a1,0
    8000564a:	fc040513          	addi	a0,s0,-64
    8000564e:	ffffb097          	auipc	ra,0xffffb
    80005652:	6be080e7          	jalr	1726(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005656:	4741                	li	a4,16
    80005658:	f2c42683          	lw	a3,-212(s0)
    8000565c:	fc040613          	addi	a2,s0,-64
    80005660:	4581                	li	a1,0
    80005662:	8526                	mv	a0,s1
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	506080e7          	jalr	1286(ra) # 80003b6a <writei>
    8000566c:	47c1                	li	a5,16
    8000566e:	0af51563          	bne	a0,a5,80005718 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005672:	04491703          	lh	a4,68(s2)
    80005676:	4785                	li	a5,1
    80005678:	0af70863          	beq	a4,a5,80005728 <sys_unlink+0x18c>
  iunlockput(dp);
    8000567c:	8526                	mv	a0,s1
    8000567e:	ffffe097          	auipc	ra,0xffffe
    80005682:	3a2080e7          	jalr	930(ra) # 80003a20 <iunlockput>
  ip->nlink--;
    80005686:	04a95783          	lhu	a5,74(s2)
    8000568a:	37fd                	addiw	a5,a5,-1
    8000568c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005690:	854a                	mv	a0,s2
    80005692:	ffffe097          	auipc	ra,0xffffe
    80005696:	062080e7          	jalr	98(ra) # 800036f4 <iupdate>
  iunlockput(ip);
    8000569a:	854a                	mv	a0,s2
    8000569c:	ffffe097          	auipc	ra,0xffffe
    800056a0:	384080e7          	jalr	900(ra) # 80003a20 <iunlockput>
  end_op();
    800056a4:	fffff097          	auipc	ra,0xfffff
    800056a8:	b5a080e7          	jalr	-1190(ra) # 800041fe <end_op>
  return 0;
    800056ac:	4501                	li	a0,0
    800056ae:	a84d                	j	80005760 <sys_unlink+0x1c4>
    end_op();
    800056b0:	fffff097          	auipc	ra,0xfffff
    800056b4:	b4e080e7          	jalr	-1202(ra) # 800041fe <end_op>
    return -1;
    800056b8:	557d                	li	a0,-1
    800056ba:	a05d                	j	80005760 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800056bc:	00003517          	auipc	a0,0x3
    800056c0:	02450513          	addi	a0,a0,36 # 800086e0 <syscalls+0x2f0>
    800056c4:	ffffb097          	auipc	ra,0xffffb
    800056c8:	e84080e7          	jalr	-380(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056cc:	04c92703          	lw	a4,76(s2)
    800056d0:	02000793          	li	a5,32
    800056d4:	f6e7f9e3          	bgeu	a5,a4,80005646 <sys_unlink+0xaa>
    800056d8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800056dc:	4741                	li	a4,16
    800056de:	86ce                	mv	a3,s3
    800056e0:	f1840613          	addi	a2,s0,-232
    800056e4:	4581                	li	a1,0
    800056e6:	854a                	mv	a0,s2
    800056e8:	ffffe097          	auipc	ra,0xffffe
    800056ec:	38a080e7          	jalr	906(ra) # 80003a72 <readi>
    800056f0:	47c1                	li	a5,16
    800056f2:	00f51b63          	bne	a0,a5,80005708 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056f6:	f1845783          	lhu	a5,-232(s0)
    800056fa:	e7a1                	bnez	a5,80005742 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056fc:	29c1                	addiw	s3,s3,16
    800056fe:	04c92783          	lw	a5,76(s2)
    80005702:	fcf9ede3          	bltu	s3,a5,800056dc <sys_unlink+0x140>
    80005706:	b781                	j	80005646 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005708:	00003517          	auipc	a0,0x3
    8000570c:	ff050513          	addi	a0,a0,-16 # 800086f8 <syscalls+0x308>
    80005710:	ffffb097          	auipc	ra,0xffffb
    80005714:	e38080e7          	jalr	-456(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005718:	00003517          	auipc	a0,0x3
    8000571c:	ff850513          	addi	a0,a0,-8 # 80008710 <syscalls+0x320>
    80005720:	ffffb097          	auipc	ra,0xffffb
    80005724:	e28080e7          	jalr	-472(ra) # 80000548 <panic>
    dp->nlink--;
    80005728:	04a4d783          	lhu	a5,74(s1)
    8000572c:	37fd                	addiw	a5,a5,-1
    8000572e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005732:	8526                	mv	a0,s1
    80005734:	ffffe097          	auipc	ra,0xffffe
    80005738:	fc0080e7          	jalr	-64(ra) # 800036f4 <iupdate>
    8000573c:	b781                	j	8000567c <sys_unlink+0xe0>
    return -1;
    8000573e:	557d                	li	a0,-1
    80005740:	a005                	j	80005760 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005742:	854a                	mv	a0,s2
    80005744:	ffffe097          	auipc	ra,0xffffe
    80005748:	2dc080e7          	jalr	732(ra) # 80003a20 <iunlockput>
  iunlockput(dp);
    8000574c:	8526                	mv	a0,s1
    8000574e:	ffffe097          	auipc	ra,0xffffe
    80005752:	2d2080e7          	jalr	722(ra) # 80003a20 <iunlockput>
  end_op();
    80005756:	fffff097          	auipc	ra,0xfffff
    8000575a:	aa8080e7          	jalr	-1368(ra) # 800041fe <end_op>
  return -1;
    8000575e:	557d                	li	a0,-1
}
    80005760:	70ae                	ld	ra,232(sp)
    80005762:	740e                	ld	s0,224(sp)
    80005764:	64ee                	ld	s1,216(sp)
    80005766:	694e                	ld	s2,208(sp)
    80005768:	69ae                	ld	s3,200(sp)
    8000576a:	616d                	addi	sp,sp,240
    8000576c:	8082                	ret

000000008000576e <sys_open>:

uint64
sys_open(void)
{
    8000576e:	7131                	addi	sp,sp,-192
    80005770:	fd06                	sd	ra,184(sp)
    80005772:	f922                	sd	s0,176(sp)
    80005774:	f526                	sd	s1,168(sp)
    80005776:	f14a                	sd	s2,160(sp)
    80005778:	ed4e                	sd	s3,152(sp)
    8000577a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000577c:	08000613          	li	a2,128
    80005780:	f5040593          	addi	a1,s0,-176
    80005784:	4501                	li	a0,0
    80005786:	ffffd097          	auipc	ra,0xffffd
    8000578a:	50a080e7          	jalr	1290(ra) # 80002c90 <argstr>
    return -1;
    8000578e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005790:	0c054163          	bltz	a0,80005852 <sys_open+0xe4>
    80005794:	f4c40593          	addi	a1,s0,-180
    80005798:	4505                	li	a0,1
    8000579a:	ffffd097          	auipc	ra,0xffffd
    8000579e:	4b2080e7          	jalr	1202(ra) # 80002c4c <argint>
    800057a2:	0a054863          	bltz	a0,80005852 <sys_open+0xe4>

  begin_op();
    800057a6:	fffff097          	auipc	ra,0xfffff
    800057aa:	9d8080e7          	jalr	-1576(ra) # 8000417e <begin_op>

  if(omode & O_CREATE){
    800057ae:	f4c42783          	lw	a5,-180(s0)
    800057b2:	2007f793          	andi	a5,a5,512
    800057b6:	cbdd                	beqz	a5,8000586c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800057b8:	4681                	li	a3,0
    800057ba:	4601                	li	a2,0
    800057bc:	4589                	li	a1,2
    800057be:	f5040513          	addi	a0,s0,-176
    800057c2:	00000097          	auipc	ra,0x0
    800057c6:	972080e7          	jalr	-1678(ra) # 80005134 <create>
    800057ca:	892a                	mv	s2,a0
    if(ip == 0){
    800057cc:	c959                	beqz	a0,80005862 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800057ce:	04491703          	lh	a4,68(s2)
    800057d2:	478d                	li	a5,3
    800057d4:	00f71763          	bne	a4,a5,800057e2 <sys_open+0x74>
    800057d8:	04695703          	lhu	a4,70(s2)
    800057dc:	47a5                	li	a5,9
    800057de:	0ce7ec63          	bltu	a5,a4,800058b6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800057e2:	fffff097          	auipc	ra,0xfffff
    800057e6:	db2080e7          	jalr	-590(ra) # 80004594 <filealloc>
    800057ea:	89aa                	mv	s3,a0
    800057ec:	10050263          	beqz	a0,800058f0 <sys_open+0x182>
    800057f0:	00000097          	auipc	ra,0x0
    800057f4:	902080e7          	jalr	-1790(ra) # 800050f2 <fdalloc>
    800057f8:	84aa                	mv	s1,a0
    800057fa:	0e054663          	bltz	a0,800058e6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057fe:	04491703          	lh	a4,68(s2)
    80005802:	478d                	li	a5,3
    80005804:	0cf70463          	beq	a4,a5,800058cc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005808:	4789                	li	a5,2
    8000580a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000580e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005812:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005816:	f4c42783          	lw	a5,-180(s0)
    8000581a:	0017c713          	xori	a4,a5,1
    8000581e:	8b05                	andi	a4,a4,1
    80005820:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005824:	0037f713          	andi	a4,a5,3
    80005828:	00e03733          	snez	a4,a4
    8000582c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005830:	4007f793          	andi	a5,a5,1024
    80005834:	c791                	beqz	a5,80005840 <sys_open+0xd2>
    80005836:	04491703          	lh	a4,68(s2)
    8000583a:	4789                	li	a5,2
    8000583c:	08f70f63          	beq	a4,a5,800058da <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005840:	854a                	mv	a0,s2
    80005842:	ffffe097          	auipc	ra,0xffffe
    80005846:	03e080e7          	jalr	62(ra) # 80003880 <iunlock>
  end_op();
    8000584a:	fffff097          	auipc	ra,0xfffff
    8000584e:	9b4080e7          	jalr	-1612(ra) # 800041fe <end_op>

  return fd;
}
    80005852:	8526                	mv	a0,s1
    80005854:	70ea                	ld	ra,184(sp)
    80005856:	744a                	ld	s0,176(sp)
    80005858:	74aa                	ld	s1,168(sp)
    8000585a:	790a                	ld	s2,160(sp)
    8000585c:	69ea                	ld	s3,152(sp)
    8000585e:	6129                	addi	sp,sp,192
    80005860:	8082                	ret
      end_op();
    80005862:	fffff097          	auipc	ra,0xfffff
    80005866:	99c080e7          	jalr	-1636(ra) # 800041fe <end_op>
      return -1;
    8000586a:	b7e5                	j	80005852 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    8000586c:	f5040513          	addi	a0,s0,-176
    80005870:	ffffe097          	auipc	ra,0xffffe
    80005874:	702080e7          	jalr	1794(ra) # 80003f72 <namei>
    80005878:	892a                	mv	s2,a0
    8000587a:	c905                	beqz	a0,800058aa <sys_open+0x13c>
    ilock(ip);
    8000587c:	ffffe097          	auipc	ra,0xffffe
    80005880:	f42080e7          	jalr	-190(ra) # 800037be <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005884:	04491703          	lh	a4,68(s2)
    80005888:	4785                	li	a5,1
    8000588a:	f4f712e3          	bne	a4,a5,800057ce <sys_open+0x60>
    8000588e:	f4c42783          	lw	a5,-180(s0)
    80005892:	dba1                	beqz	a5,800057e2 <sys_open+0x74>
      iunlockput(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	18a080e7          	jalr	394(ra) # 80003a20 <iunlockput>
      end_op();
    8000589e:	fffff097          	auipc	ra,0xfffff
    800058a2:	960080e7          	jalr	-1696(ra) # 800041fe <end_op>
      return -1;
    800058a6:	54fd                	li	s1,-1
    800058a8:	b76d                	j	80005852 <sys_open+0xe4>
      end_op();
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	954080e7          	jalr	-1708(ra) # 800041fe <end_op>
      return -1;
    800058b2:	54fd                	li	s1,-1
    800058b4:	bf79                	j	80005852 <sys_open+0xe4>
    iunlockput(ip);
    800058b6:	854a                	mv	a0,s2
    800058b8:	ffffe097          	auipc	ra,0xffffe
    800058bc:	168080e7          	jalr	360(ra) # 80003a20 <iunlockput>
    end_op();
    800058c0:	fffff097          	auipc	ra,0xfffff
    800058c4:	93e080e7          	jalr	-1730(ra) # 800041fe <end_op>
    return -1;
    800058c8:	54fd                	li	s1,-1
    800058ca:	b761                	j	80005852 <sys_open+0xe4>
    f->type = FD_DEVICE;
    800058cc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    800058d0:	04691783          	lh	a5,70(s2)
    800058d4:	02f99223          	sh	a5,36(s3)
    800058d8:	bf2d                	j	80005812 <sys_open+0xa4>
    itrunc(ip);
    800058da:	854a                	mv	a0,s2
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	ff0080e7          	jalr	-16(ra) # 800038cc <itrunc>
    800058e4:	bfb1                	j	80005840 <sys_open+0xd2>
      fileclose(f);
    800058e6:	854e                	mv	a0,s3
    800058e8:	fffff097          	auipc	ra,0xfffff
    800058ec:	d68080e7          	jalr	-664(ra) # 80004650 <fileclose>
    iunlockput(ip);
    800058f0:	854a                	mv	a0,s2
    800058f2:	ffffe097          	auipc	ra,0xffffe
    800058f6:	12e080e7          	jalr	302(ra) # 80003a20 <iunlockput>
    end_op();
    800058fa:	fffff097          	auipc	ra,0xfffff
    800058fe:	904080e7          	jalr	-1788(ra) # 800041fe <end_op>
    return -1;
    80005902:	54fd                	li	s1,-1
    80005904:	b7b9                	j	80005852 <sys_open+0xe4>

0000000080005906 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005906:	7175                	addi	sp,sp,-144
    80005908:	e506                	sd	ra,136(sp)
    8000590a:	e122                	sd	s0,128(sp)
    8000590c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000590e:	fffff097          	auipc	ra,0xfffff
    80005912:	870080e7          	jalr	-1936(ra) # 8000417e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005916:	08000613          	li	a2,128
    8000591a:	f7040593          	addi	a1,s0,-144
    8000591e:	4501                	li	a0,0
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	370080e7          	jalr	880(ra) # 80002c90 <argstr>
    80005928:	02054963          	bltz	a0,8000595a <sys_mkdir+0x54>
    8000592c:	4681                	li	a3,0
    8000592e:	4601                	li	a2,0
    80005930:	4585                	li	a1,1
    80005932:	f7040513          	addi	a0,s0,-144
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	7fe080e7          	jalr	2046(ra) # 80005134 <create>
    8000593e:	cd11                	beqz	a0,8000595a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005940:	ffffe097          	auipc	ra,0xffffe
    80005944:	0e0080e7          	jalr	224(ra) # 80003a20 <iunlockput>
  end_op();
    80005948:	fffff097          	auipc	ra,0xfffff
    8000594c:	8b6080e7          	jalr	-1866(ra) # 800041fe <end_op>
  return 0;
    80005950:	4501                	li	a0,0
}
    80005952:	60aa                	ld	ra,136(sp)
    80005954:	640a                	ld	s0,128(sp)
    80005956:	6149                	addi	sp,sp,144
    80005958:	8082                	ret
    end_op();
    8000595a:	fffff097          	auipc	ra,0xfffff
    8000595e:	8a4080e7          	jalr	-1884(ra) # 800041fe <end_op>
    return -1;
    80005962:	557d                	li	a0,-1
    80005964:	b7fd                	j	80005952 <sys_mkdir+0x4c>

0000000080005966 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005966:	7135                	addi	sp,sp,-160
    80005968:	ed06                	sd	ra,152(sp)
    8000596a:	e922                	sd	s0,144(sp)
    8000596c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000596e:	fffff097          	auipc	ra,0xfffff
    80005972:	810080e7          	jalr	-2032(ra) # 8000417e <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005976:	08000613          	li	a2,128
    8000597a:	f7040593          	addi	a1,s0,-144
    8000597e:	4501                	li	a0,0
    80005980:	ffffd097          	auipc	ra,0xffffd
    80005984:	310080e7          	jalr	784(ra) # 80002c90 <argstr>
    80005988:	04054a63          	bltz	a0,800059dc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    8000598c:	f6c40593          	addi	a1,s0,-148
    80005990:	4505                	li	a0,1
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	2ba080e7          	jalr	698(ra) # 80002c4c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000599a:	04054163          	bltz	a0,800059dc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000599e:	f6840593          	addi	a1,s0,-152
    800059a2:	4509                	li	a0,2
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	2a8080e7          	jalr	680(ra) # 80002c4c <argint>
     argint(1, &major) < 0 ||
    800059ac:	02054863          	bltz	a0,800059dc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800059b0:	f6841683          	lh	a3,-152(s0)
    800059b4:	f6c41603          	lh	a2,-148(s0)
    800059b8:	458d                	li	a1,3
    800059ba:	f7040513          	addi	a0,s0,-144
    800059be:	fffff097          	auipc	ra,0xfffff
    800059c2:	776080e7          	jalr	1910(ra) # 80005134 <create>
     argint(2, &minor) < 0 ||
    800059c6:	c919                	beqz	a0,800059dc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800059c8:	ffffe097          	auipc	ra,0xffffe
    800059cc:	058080e7          	jalr	88(ra) # 80003a20 <iunlockput>
  end_op();
    800059d0:	fffff097          	auipc	ra,0xfffff
    800059d4:	82e080e7          	jalr	-2002(ra) # 800041fe <end_op>
  return 0;
    800059d8:	4501                	li	a0,0
    800059da:	a031                	j	800059e6 <sys_mknod+0x80>
    end_op();
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	822080e7          	jalr	-2014(ra) # 800041fe <end_op>
    return -1;
    800059e4:	557d                	li	a0,-1
}
    800059e6:	60ea                	ld	ra,152(sp)
    800059e8:	644a                	ld	s0,144(sp)
    800059ea:	610d                	addi	sp,sp,160
    800059ec:	8082                	ret

00000000800059ee <sys_chdir>:

uint64
sys_chdir(void)
{
    800059ee:	7135                	addi	sp,sp,-160
    800059f0:	ed06                	sd	ra,152(sp)
    800059f2:	e922                	sd	s0,144(sp)
    800059f4:	e526                	sd	s1,136(sp)
    800059f6:	e14a                	sd	s2,128(sp)
    800059f8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059fa:	ffffc097          	auipc	ra,0xffffc
    800059fe:	12e080e7          	jalr	302(ra) # 80001b28 <myproc>
    80005a02:	892a                	mv	s2,a0
  
  begin_op();
    80005a04:	ffffe097          	auipc	ra,0xffffe
    80005a08:	77a080e7          	jalr	1914(ra) # 8000417e <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005a0c:	08000613          	li	a2,128
    80005a10:	f6040593          	addi	a1,s0,-160
    80005a14:	4501                	li	a0,0
    80005a16:	ffffd097          	auipc	ra,0xffffd
    80005a1a:	27a080e7          	jalr	634(ra) # 80002c90 <argstr>
    80005a1e:	04054b63          	bltz	a0,80005a74 <sys_chdir+0x86>
    80005a22:	f6040513          	addi	a0,s0,-160
    80005a26:	ffffe097          	auipc	ra,0xffffe
    80005a2a:	54c080e7          	jalr	1356(ra) # 80003f72 <namei>
    80005a2e:	84aa                	mv	s1,a0
    80005a30:	c131                	beqz	a0,80005a74 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005a32:	ffffe097          	auipc	ra,0xffffe
    80005a36:	d8c080e7          	jalr	-628(ra) # 800037be <ilock>
  if(ip->type != T_DIR){
    80005a3a:	04449703          	lh	a4,68(s1)
    80005a3e:	4785                	li	a5,1
    80005a40:	04f71063          	bne	a4,a5,80005a80 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005a44:	8526                	mv	a0,s1
    80005a46:	ffffe097          	auipc	ra,0xffffe
    80005a4a:	e3a080e7          	jalr	-454(ra) # 80003880 <iunlock>
  iput(p->cwd);
    80005a4e:	15093503          	ld	a0,336(s2)
    80005a52:	ffffe097          	auipc	ra,0xffffe
    80005a56:	f26080e7          	jalr	-218(ra) # 80003978 <iput>
  end_op();
    80005a5a:	ffffe097          	auipc	ra,0xffffe
    80005a5e:	7a4080e7          	jalr	1956(ra) # 800041fe <end_op>
  p->cwd = ip;
    80005a62:	14993823          	sd	s1,336(s2)
  return 0;
    80005a66:	4501                	li	a0,0
}
    80005a68:	60ea                	ld	ra,152(sp)
    80005a6a:	644a                	ld	s0,144(sp)
    80005a6c:	64aa                	ld	s1,136(sp)
    80005a6e:	690a                	ld	s2,128(sp)
    80005a70:	610d                	addi	sp,sp,160
    80005a72:	8082                	ret
    end_op();
    80005a74:	ffffe097          	auipc	ra,0xffffe
    80005a78:	78a080e7          	jalr	1930(ra) # 800041fe <end_op>
    return -1;
    80005a7c:	557d                	li	a0,-1
    80005a7e:	b7ed                	j	80005a68 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a80:	8526                	mv	a0,s1
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	f9e080e7          	jalr	-98(ra) # 80003a20 <iunlockput>
    end_op();
    80005a8a:	ffffe097          	auipc	ra,0xffffe
    80005a8e:	774080e7          	jalr	1908(ra) # 800041fe <end_op>
    return -1;
    80005a92:	557d                	li	a0,-1
    80005a94:	bfd1                	j	80005a68 <sys_chdir+0x7a>

0000000080005a96 <sys_exec>:

uint64
sys_exec(void)
{
    80005a96:	7145                	addi	sp,sp,-464
    80005a98:	e786                	sd	ra,456(sp)
    80005a9a:	e3a2                	sd	s0,448(sp)
    80005a9c:	ff26                	sd	s1,440(sp)
    80005a9e:	fb4a                	sd	s2,432(sp)
    80005aa0:	f74e                	sd	s3,424(sp)
    80005aa2:	f352                	sd	s4,416(sp)
    80005aa4:	ef56                	sd	s5,408(sp)
    80005aa6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005aa8:	08000613          	li	a2,128
    80005aac:	f4040593          	addi	a1,s0,-192
    80005ab0:	4501                	li	a0,0
    80005ab2:	ffffd097          	auipc	ra,0xffffd
    80005ab6:	1de080e7          	jalr	478(ra) # 80002c90 <argstr>
    return -1;
    80005aba:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005abc:	0c054a63          	bltz	a0,80005b90 <sys_exec+0xfa>
    80005ac0:	e3840593          	addi	a1,s0,-456
    80005ac4:	4505                	li	a0,1
    80005ac6:	ffffd097          	auipc	ra,0xffffd
    80005aca:	1a8080e7          	jalr	424(ra) # 80002c6e <argaddr>
    80005ace:	0c054163          	bltz	a0,80005b90 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ad2:	10000613          	li	a2,256
    80005ad6:	4581                	li	a1,0
    80005ad8:	e4040513          	addi	a0,s0,-448
    80005adc:	ffffb097          	auipc	ra,0xffffb
    80005ae0:	230080e7          	jalr	560(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ae4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ae8:	89a6                	mv	s3,s1
    80005aea:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aec:	02000a13          	li	s4,32
    80005af0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005af4:	00391513          	slli	a0,s2,0x3
    80005af8:	e3040593          	addi	a1,s0,-464
    80005afc:	e3843783          	ld	a5,-456(s0)
    80005b00:	953e                	add	a0,a0,a5
    80005b02:	ffffd097          	auipc	ra,0xffffd
    80005b06:	0b0080e7          	jalr	176(ra) # 80002bb2 <fetchaddr>
    80005b0a:	02054a63          	bltz	a0,80005b3e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005b0e:	e3043783          	ld	a5,-464(s0)
    80005b12:	c3b9                	beqz	a5,80005b58 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005b14:	ffffb097          	auipc	ra,0xffffb
    80005b18:	00c080e7          	jalr	12(ra) # 80000b20 <kalloc>
    80005b1c:	85aa                	mv	a1,a0
    80005b1e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005b22:	cd11                	beqz	a0,80005b3e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005b24:	6605                	lui	a2,0x1
    80005b26:	e3043503          	ld	a0,-464(s0)
    80005b2a:	ffffd097          	auipc	ra,0xffffd
    80005b2e:	0da080e7          	jalr	218(ra) # 80002c04 <fetchstr>
    80005b32:	00054663          	bltz	a0,80005b3e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005b36:	0905                	addi	s2,s2,1
    80005b38:	09a1                	addi	s3,s3,8
    80005b3a:	fb491be3          	bne	s2,s4,80005af0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3e:	10048913          	addi	s2,s1,256
    80005b42:	6088                	ld	a0,0(s1)
    80005b44:	c529                	beqz	a0,80005b8e <sys_exec+0xf8>
    kfree(argv[i]);
    80005b46:	ffffb097          	auipc	ra,0xffffb
    80005b4a:	ede080e7          	jalr	-290(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b4e:	04a1                	addi	s1,s1,8
    80005b50:	ff2499e3          	bne	s1,s2,80005b42 <sys_exec+0xac>
  return -1;
    80005b54:	597d                	li	s2,-1
    80005b56:	a82d                	j	80005b90 <sys_exec+0xfa>
      argv[i] = 0;
    80005b58:	0a8e                	slli	s5,s5,0x3
    80005b5a:	fc040793          	addi	a5,s0,-64
    80005b5e:	9abe                	add	s5,s5,a5
    80005b60:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b64:	e4040593          	addi	a1,s0,-448
    80005b68:	f4040513          	addi	a0,s0,-192
    80005b6c:	fffff097          	auipc	ra,0xfffff
    80005b70:	194080e7          	jalr	404(ra) # 80004d00 <exec>
    80005b74:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b76:	10048993          	addi	s3,s1,256
    80005b7a:	6088                	ld	a0,0(s1)
    80005b7c:	c911                	beqz	a0,80005b90 <sys_exec+0xfa>
    kfree(argv[i]);
    80005b7e:	ffffb097          	auipc	ra,0xffffb
    80005b82:	ea6080e7          	jalr	-346(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b86:	04a1                	addi	s1,s1,8
    80005b88:	ff3499e3          	bne	s1,s3,80005b7a <sys_exec+0xe4>
    80005b8c:	a011                	j	80005b90 <sys_exec+0xfa>
  return -1;
    80005b8e:	597d                	li	s2,-1
}
    80005b90:	854a                	mv	a0,s2
    80005b92:	60be                	ld	ra,456(sp)
    80005b94:	641e                	ld	s0,448(sp)
    80005b96:	74fa                	ld	s1,440(sp)
    80005b98:	795a                	ld	s2,432(sp)
    80005b9a:	79ba                	ld	s3,424(sp)
    80005b9c:	7a1a                	ld	s4,416(sp)
    80005b9e:	6afa                	ld	s5,408(sp)
    80005ba0:	6179                	addi	sp,sp,464
    80005ba2:	8082                	ret

0000000080005ba4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005ba4:	7139                	addi	sp,sp,-64
    80005ba6:	fc06                	sd	ra,56(sp)
    80005ba8:	f822                	sd	s0,48(sp)
    80005baa:	f426                	sd	s1,40(sp)
    80005bac:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005bae:	ffffc097          	auipc	ra,0xffffc
    80005bb2:	f7a080e7          	jalr	-134(ra) # 80001b28 <myproc>
    80005bb6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005bb8:	fd840593          	addi	a1,s0,-40
    80005bbc:	4501                	li	a0,0
    80005bbe:	ffffd097          	auipc	ra,0xffffd
    80005bc2:	0b0080e7          	jalr	176(ra) # 80002c6e <argaddr>
    return -1;
    80005bc6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005bc8:	0e054063          	bltz	a0,80005ca8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005bcc:	fc840593          	addi	a1,s0,-56
    80005bd0:	fd040513          	addi	a0,s0,-48
    80005bd4:	fffff097          	auipc	ra,0xfffff
    80005bd8:	dd2080e7          	jalr	-558(ra) # 800049a6 <pipealloc>
    return -1;
    80005bdc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005bde:	0c054563          	bltz	a0,80005ca8 <sys_pipe+0x104>
  fd0 = -1;
    80005be2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005be6:	fd043503          	ld	a0,-48(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	508080e7          	jalr	1288(ra) # 800050f2 <fdalloc>
    80005bf2:	fca42223          	sw	a0,-60(s0)
    80005bf6:	08054c63          	bltz	a0,80005c8e <sys_pipe+0xea>
    80005bfa:	fc843503          	ld	a0,-56(s0)
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	4f4080e7          	jalr	1268(ra) # 800050f2 <fdalloc>
    80005c06:	fca42023          	sw	a0,-64(s0)
    80005c0a:	06054863          	bltz	a0,80005c7a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c0e:	4691                	li	a3,4
    80005c10:	fc440613          	addi	a2,s0,-60
    80005c14:	fd843583          	ld	a1,-40(s0)
    80005c18:	68a8                	ld	a0,80(s1)
    80005c1a:	ffffc097          	auipc	ra,0xffffc
    80005c1e:	c82080e7          	jalr	-894(ra) # 8000189c <copyout>
    80005c22:	02054063          	bltz	a0,80005c42 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005c26:	4691                	li	a3,4
    80005c28:	fc040613          	addi	a2,s0,-64
    80005c2c:	fd843583          	ld	a1,-40(s0)
    80005c30:	0591                	addi	a1,a1,4
    80005c32:	68a8                	ld	a0,80(s1)
    80005c34:	ffffc097          	auipc	ra,0xffffc
    80005c38:	c68080e7          	jalr	-920(ra) # 8000189c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005c3c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005c3e:	06055563          	bgez	a0,80005ca8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005c42:	fc442783          	lw	a5,-60(s0)
    80005c46:	07e9                	addi	a5,a5,26
    80005c48:	078e                	slli	a5,a5,0x3
    80005c4a:	97a6                	add	a5,a5,s1
    80005c4c:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c50:	fc042503          	lw	a0,-64(s0)
    80005c54:	0569                	addi	a0,a0,26
    80005c56:	050e                	slli	a0,a0,0x3
    80005c58:	9526                	add	a0,a0,s1
    80005c5a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c5e:	fd043503          	ld	a0,-48(s0)
    80005c62:	fffff097          	auipc	ra,0xfffff
    80005c66:	9ee080e7          	jalr	-1554(ra) # 80004650 <fileclose>
    fileclose(wf);
    80005c6a:	fc843503          	ld	a0,-56(s0)
    80005c6e:	fffff097          	auipc	ra,0xfffff
    80005c72:	9e2080e7          	jalr	-1566(ra) # 80004650 <fileclose>
    return -1;
    80005c76:	57fd                	li	a5,-1
    80005c78:	a805                	j	80005ca8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c7a:	fc442783          	lw	a5,-60(s0)
    80005c7e:	0007c863          	bltz	a5,80005c8e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c82:	01a78513          	addi	a0,a5,26
    80005c86:	050e                	slli	a0,a0,0x3
    80005c88:	9526                	add	a0,a0,s1
    80005c8a:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c8e:	fd043503          	ld	a0,-48(s0)
    80005c92:	fffff097          	auipc	ra,0xfffff
    80005c96:	9be080e7          	jalr	-1602(ra) # 80004650 <fileclose>
    fileclose(wf);
    80005c9a:	fc843503          	ld	a0,-56(s0)
    80005c9e:	fffff097          	auipc	ra,0xfffff
    80005ca2:	9b2080e7          	jalr	-1614(ra) # 80004650 <fileclose>
    return -1;
    80005ca6:	57fd                	li	a5,-1
}
    80005ca8:	853e                	mv	a0,a5
    80005caa:	70e2                	ld	ra,56(sp)
    80005cac:	7442                	ld	s0,48(sp)
    80005cae:	74a2                	ld	s1,40(sp)
    80005cb0:	6121                	addi	sp,sp,64
    80005cb2:	8082                	ret
	...

0000000080005cc0 <kernelvec>:
    80005cc0:	7111                	addi	sp,sp,-256
    80005cc2:	e006                	sd	ra,0(sp)
    80005cc4:	e40a                	sd	sp,8(sp)
    80005cc6:	e80e                	sd	gp,16(sp)
    80005cc8:	ec12                	sd	tp,24(sp)
    80005cca:	f016                	sd	t0,32(sp)
    80005ccc:	f41a                	sd	t1,40(sp)
    80005cce:	f81e                	sd	t2,48(sp)
    80005cd0:	fc22                	sd	s0,56(sp)
    80005cd2:	e0a6                	sd	s1,64(sp)
    80005cd4:	e4aa                	sd	a0,72(sp)
    80005cd6:	e8ae                	sd	a1,80(sp)
    80005cd8:	ecb2                	sd	a2,88(sp)
    80005cda:	f0b6                	sd	a3,96(sp)
    80005cdc:	f4ba                	sd	a4,104(sp)
    80005cde:	f8be                	sd	a5,112(sp)
    80005ce0:	fcc2                	sd	a6,120(sp)
    80005ce2:	e146                	sd	a7,128(sp)
    80005ce4:	e54a                	sd	s2,136(sp)
    80005ce6:	e94e                	sd	s3,144(sp)
    80005ce8:	ed52                	sd	s4,152(sp)
    80005cea:	f156                	sd	s5,160(sp)
    80005cec:	f55a                	sd	s6,168(sp)
    80005cee:	f95e                	sd	s7,176(sp)
    80005cf0:	fd62                	sd	s8,184(sp)
    80005cf2:	e1e6                	sd	s9,192(sp)
    80005cf4:	e5ea                	sd	s10,200(sp)
    80005cf6:	e9ee                	sd	s11,208(sp)
    80005cf8:	edf2                	sd	t3,216(sp)
    80005cfa:	f1f6                	sd	t4,224(sp)
    80005cfc:	f5fa                	sd	t5,232(sp)
    80005cfe:	f9fe                	sd	t6,240(sp)
    80005d00:	d7ffc0ef          	jal	ra,80002a7e <kerneltrap>
    80005d04:	6082                	ld	ra,0(sp)
    80005d06:	6122                	ld	sp,8(sp)
    80005d08:	61c2                	ld	gp,16(sp)
    80005d0a:	7282                	ld	t0,32(sp)
    80005d0c:	7322                	ld	t1,40(sp)
    80005d0e:	73c2                	ld	t2,48(sp)
    80005d10:	7462                	ld	s0,56(sp)
    80005d12:	6486                	ld	s1,64(sp)
    80005d14:	6526                	ld	a0,72(sp)
    80005d16:	65c6                	ld	a1,80(sp)
    80005d18:	6666                	ld	a2,88(sp)
    80005d1a:	7686                	ld	a3,96(sp)
    80005d1c:	7726                	ld	a4,104(sp)
    80005d1e:	77c6                	ld	a5,112(sp)
    80005d20:	7866                	ld	a6,120(sp)
    80005d22:	688a                	ld	a7,128(sp)
    80005d24:	692a                	ld	s2,136(sp)
    80005d26:	69ca                	ld	s3,144(sp)
    80005d28:	6a6a                	ld	s4,152(sp)
    80005d2a:	7a8a                	ld	s5,160(sp)
    80005d2c:	7b2a                	ld	s6,168(sp)
    80005d2e:	7bca                	ld	s7,176(sp)
    80005d30:	7c6a                	ld	s8,184(sp)
    80005d32:	6c8e                	ld	s9,192(sp)
    80005d34:	6d2e                	ld	s10,200(sp)
    80005d36:	6dce                	ld	s11,208(sp)
    80005d38:	6e6e                	ld	t3,216(sp)
    80005d3a:	7e8e                	ld	t4,224(sp)
    80005d3c:	7f2e                	ld	t5,232(sp)
    80005d3e:	7fce                	ld	t6,240(sp)
    80005d40:	6111                	addi	sp,sp,256
    80005d42:	10200073          	sret
    80005d46:	00000013          	nop
    80005d4a:	00000013          	nop
    80005d4e:	0001                	nop

0000000080005d50 <timervec>:
    80005d50:	34051573          	csrrw	a0,mscratch,a0
    80005d54:	e10c                	sd	a1,0(a0)
    80005d56:	e510                	sd	a2,8(a0)
    80005d58:	e914                	sd	a3,16(a0)
    80005d5a:	710c                	ld	a1,32(a0)
    80005d5c:	7510                	ld	a2,40(a0)
    80005d5e:	6194                	ld	a3,0(a1)
    80005d60:	96b2                	add	a3,a3,a2
    80005d62:	e194                	sd	a3,0(a1)
    80005d64:	4589                	li	a1,2
    80005d66:	14459073          	csrw	sip,a1
    80005d6a:	6914                	ld	a3,16(a0)
    80005d6c:	6510                	ld	a2,8(a0)
    80005d6e:	610c                	ld	a1,0(a0)
    80005d70:	34051573          	csrrw	a0,mscratch,a0
    80005d74:	30200073          	mret
	...

0000000080005d7a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d7a:	1141                	addi	sp,sp,-16
    80005d7c:	e422                	sd	s0,8(sp)
    80005d7e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d80:	0c0007b7          	lui	a5,0xc000
    80005d84:	4705                	li	a4,1
    80005d86:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d88:	c3d8                	sw	a4,4(a5)
}
    80005d8a:	6422                	ld	s0,8(sp)
    80005d8c:	0141                	addi	sp,sp,16
    80005d8e:	8082                	ret

0000000080005d90 <plicinithart>:

void
plicinithart(void)
{
    80005d90:	1141                	addi	sp,sp,-16
    80005d92:	e406                	sd	ra,8(sp)
    80005d94:	e022                	sd	s0,0(sp)
    80005d96:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	d64080e7          	jalr	-668(ra) # 80001afc <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005da0:	0085171b          	slliw	a4,a0,0x8
    80005da4:	0c0027b7          	lui	a5,0xc002
    80005da8:	97ba                	add	a5,a5,a4
    80005daa:	40200713          	li	a4,1026
    80005dae:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005db2:	00d5151b          	slliw	a0,a0,0xd
    80005db6:	0c2017b7          	lui	a5,0xc201
    80005dba:	953e                	add	a0,a0,a5
    80005dbc:	00052023          	sw	zero,0(a0)
}
    80005dc0:	60a2                	ld	ra,8(sp)
    80005dc2:	6402                	ld	s0,0(sp)
    80005dc4:	0141                	addi	sp,sp,16
    80005dc6:	8082                	ret

0000000080005dc8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005dc8:	1141                	addi	sp,sp,-16
    80005dca:	e406                	sd	ra,8(sp)
    80005dcc:	e022                	sd	s0,0(sp)
    80005dce:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005dd0:	ffffc097          	auipc	ra,0xffffc
    80005dd4:	d2c080e7          	jalr	-724(ra) # 80001afc <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005dd8:	00d5179b          	slliw	a5,a0,0xd
    80005ddc:	0c201537          	lui	a0,0xc201
    80005de0:	953e                	add	a0,a0,a5
  return irq;
}
    80005de2:	4148                	lw	a0,4(a0)
    80005de4:	60a2                	ld	ra,8(sp)
    80005de6:	6402                	ld	s0,0(sp)
    80005de8:	0141                	addi	sp,sp,16
    80005dea:	8082                	ret

0000000080005dec <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005dec:	1101                	addi	sp,sp,-32
    80005dee:	ec06                	sd	ra,24(sp)
    80005df0:	e822                	sd	s0,16(sp)
    80005df2:	e426                	sd	s1,8(sp)
    80005df4:	1000                	addi	s0,sp,32
    80005df6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005df8:	ffffc097          	auipc	ra,0xffffc
    80005dfc:	d04080e7          	jalr	-764(ra) # 80001afc <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005e00:	00d5151b          	slliw	a0,a0,0xd
    80005e04:	0c2017b7          	lui	a5,0xc201
    80005e08:	97aa                	add	a5,a5,a0
    80005e0a:	c3c4                	sw	s1,4(a5)
}
    80005e0c:	60e2                	ld	ra,24(sp)
    80005e0e:	6442                	ld	s0,16(sp)
    80005e10:	64a2                	ld	s1,8(sp)
    80005e12:	6105                	addi	sp,sp,32
    80005e14:	8082                	ret

0000000080005e16 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005e16:	1141                	addi	sp,sp,-16
    80005e18:	e406                	sd	ra,8(sp)
    80005e1a:	e022                	sd	s0,0(sp)
    80005e1c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005e1e:	479d                	li	a5,7
    80005e20:	04a7cc63          	blt	a5,a0,80005e78 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005e24:	0001d797          	auipc	a5,0x1d
    80005e28:	1dc78793          	addi	a5,a5,476 # 80023000 <disk>
    80005e2c:	00a78733          	add	a4,a5,a0
    80005e30:	6789                	lui	a5,0x2
    80005e32:	97ba                	add	a5,a5,a4
    80005e34:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005e38:	eba1                	bnez	a5,80005e88 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005e3a:	00451713          	slli	a4,a0,0x4
    80005e3e:	0001f797          	auipc	a5,0x1f
    80005e42:	1c27b783          	ld	a5,450(a5) # 80025000 <disk+0x2000>
    80005e46:	97ba                	add	a5,a5,a4
    80005e48:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005e4c:	0001d797          	auipc	a5,0x1d
    80005e50:	1b478793          	addi	a5,a5,436 # 80023000 <disk>
    80005e54:	97aa                	add	a5,a5,a0
    80005e56:	6509                	lui	a0,0x2
    80005e58:	953e                	add	a0,a0,a5
    80005e5a:	4785                	li	a5,1
    80005e5c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e60:	0001f517          	auipc	a0,0x1f
    80005e64:	1b850513          	addi	a0,a0,440 # 80025018 <disk+0x2018>
    80005e68:	ffffc097          	auipc	ra,0xffffc
    80005e6c:	656080e7          	jalr	1622(ra) # 800024be <wakeup>
}
    80005e70:	60a2                	ld	ra,8(sp)
    80005e72:	6402                	ld	s0,0(sp)
    80005e74:	0141                	addi	sp,sp,16
    80005e76:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e78:	00003517          	auipc	a0,0x3
    80005e7c:	8a850513          	addi	a0,a0,-1880 # 80008720 <syscalls+0x330>
    80005e80:	ffffa097          	auipc	ra,0xffffa
    80005e84:	6c8080e7          	jalr	1736(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e88:	00003517          	auipc	a0,0x3
    80005e8c:	8b050513          	addi	a0,a0,-1872 # 80008738 <syscalls+0x348>
    80005e90:	ffffa097          	auipc	ra,0xffffa
    80005e94:	6b8080e7          	jalr	1720(ra) # 80000548 <panic>

0000000080005e98 <virtio_disk_init>:
{
    80005e98:	1101                	addi	sp,sp,-32
    80005e9a:	ec06                	sd	ra,24(sp)
    80005e9c:	e822                	sd	s0,16(sp)
    80005e9e:	e426                	sd	s1,8(sp)
    80005ea0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005ea2:	00003597          	auipc	a1,0x3
    80005ea6:	8ae58593          	addi	a1,a1,-1874 # 80008750 <syscalls+0x360>
    80005eaa:	0001f517          	auipc	a0,0x1f
    80005eae:	1fe50513          	addi	a0,a0,510 # 800250a8 <disk+0x20a8>
    80005eb2:	ffffb097          	auipc	ra,0xffffb
    80005eb6:	cce080e7          	jalr	-818(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005eba:	100017b7          	lui	a5,0x10001
    80005ebe:	4398                	lw	a4,0(a5)
    80005ec0:	2701                	sext.w	a4,a4
    80005ec2:	747277b7          	lui	a5,0x74727
    80005ec6:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005eca:	0ef71163          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ece:	100017b7          	lui	a5,0x10001
    80005ed2:	43dc                	lw	a5,4(a5)
    80005ed4:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005ed6:	4705                	li	a4,1
    80005ed8:	0ce79a63          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	479c                	lw	a5,8(a5)
    80005ee2:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005ee4:	4709                	li	a4,2
    80005ee6:	0ce79363          	bne	a5,a4,80005fac <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005eea:	100017b7          	lui	a5,0x10001
    80005eee:	47d8                	lw	a4,12(a5)
    80005ef0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ef2:	554d47b7          	lui	a5,0x554d4
    80005ef6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005efa:	0af71963          	bne	a4,a5,80005fac <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005efe:	100017b7          	lui	a5,0x10001
    80005f02:	4705                	li	a4,1
    80005f04:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f06:	470d                	li	a4,3
    80005f08:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005f0a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005f0c:	c7ffe737          	lui	a4,0xc7ffe
    80005f10:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005f14:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005f16:	2701                	sext.w	a4,a4
    80005f18:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1a:	472d                	li	a4,11
    80005f1c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005f1e:	473d                	li	a4,15
    80005f20:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005f22:	6705                	lui	a4,0x1
    80005f24:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005f26:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005f2a:	5bdc                	lw	a5,52(a5)
    80005f2c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005f2e:	c7d9                	beqz	a5,80005fbc <virtio_disk_init+0x124>
  if(max < NUM)
    80005f30:	471d                	li	a4,7
    80005f32:	08f77d63          	bgeu	a4,a5,80005fcc <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f36:	100014b7          	lui	s1,0x10001
    80005f3a:	47a1                	li	a5,8
    80005f3c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005f3e:	6609                	lui	a2,0x2
    80005f40:	4581                	li	a1,0
    80005f42:	0001d517          	auipc	a0,0x1d
    80005f46:	0be50513          	addi	a0,a0,190 # 80023000 <disk>
    80005f4a:	ffffb097          	auipc	ra,0xffffb
    80005f4e:	dc2080e7          	jalr	-574(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f52:	0001d717          	auipc	a4,0x1d
    80005f56:	0ae70713          	addi	a4,a4,174 # 80023000 <disk>
    80005f5a:	00c75793          	srli	a5,a4,0xc
    80005f5e:	2781                	sext.w	a5,a5
    80005f60:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f62:	0001f797          	auipc	a5,0x1f
    80005f66:	09e78793          	addi	a5,a5,158 # 80025000 <disk+0x2000>
    80005f6a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f6c:	0001d717          	auipc	a4,0x1d
    80005f70:	11470713          	addi	a4,a4,276 # 80023080 <disk+0x80>
    80005f74:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f76:	0001e717          	auipc	a4,0x1e
    80005f7a:	08a70713          	addi	a4,a4,138 # 80024000 <disk+0x1000>
    80005f7e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f80:	4705                	li	a4,1
    80005f82:	00e78c23          	sb	a4,24(a5)
    80005f86:	00e78ca3          	sb	a4,25(a5)
    80005f8a:	00e78d23          	sb	a4,26(a5)
    80005f8e:	00e78da3          	sb	a4,27(a5)
    80005f92:	00e78e23          	sb	a4,28(a5)
    80005f96:	00e78ea3          	sb	a4,29(a5)
    80005f9a:	00e78f23          	sb	a4,30(a5)
    80005f9e:	00e78fa3          	sb	a4,31(a5)
}
    80005fa2:	60e2                	ld	ra,24(sp)
    80005fa4:	6442                	ld	s0,16(sp)
    80005fa6:	64a2                	ld	s1,8(sp)
    80005fa8:	6105                	addi	sp,sp,32
    80005faa:	8082                	ret
    panic("could not find virtio disk");
    80005fac:	00002517          	auipc	a0,0x2
    80005fb0:	7b450513          	addi	a0,a0,1972 # 80008760 <syscalls+0x370>
    80005fb4:	ffffa097          	auipc	ra,0xffffa
    80005fb8:	594080e7          	jalr	1428(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005fbc:	00002517          	auipc	a0,0x2
    80005fc0:	7c450513          	addi	a0,a0,1988 # 80008780 <syscalls+0x390>
    80005fc4:	ffffa097          	auipc	ra,0xffffa
    80005fc8:	584080e7          	jalr	1412(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005fcc:	00002517          	auipc	a0,0x2
    80005fd0:	7d450513          	addi	a0,a0,2004 # 800087a0 <syscalls+0x3b0>
    80005fd4:	ffffa097          	auipc	ra,0xffffa
    80005fd8:	574080e7          	jalr	1396(ra) # 80000548 <panic>

0000000080005fdc <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005fdc:	7119                	addi	sp,sp,-128
    80005fde:	fc86                	sd	ra,120(sp)
    80005fe0:	f8a2                	sd	s0,112(sp)
    80005fe2:	f4a6                	sd	s1,104(sp)
    80005fe4:	f0ca                	sd	s2,96(sp)
    80005fe6:	ecce                	sd	s3,88(sp)
    80005fe8:	e8d2                	sd	s4,80(sp)
    80005fea:	e4d6                	sd	s5,72(sp)
    80005fec:	e0da                	sd	s6,64(sp)
    80005fee:	fc5e                	sd	s7,56(sp)
    80005ff0:	f862                	sd	s8,48(sp)
    80005ff2:	f466                	sd	s9,40(sp)
    80005ff4:	f06a                	sd	s10,32(sp)
    80005ff6:	0100                	addi	s0,sp,128
    80005ff8:	892a                	mv	s2,a0
    80005ffa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005ffc:	00c52c83          	lw	s9,12(a0)
    80006000:	001c9c9b          	slliw	s9,s9,0x1
    80006004:	1c82                	slli	s9,s9,0x20
    80006006:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000600a:	0001f517          	auipc	a0,0x1f
    8000600e:	09e50513          	addi	a0,a0,158 # 800250a8 <disk+0x20a8>
    80006012:	ffffb097          	auipc	ra,0xffffb
    80006016:	bfe080e7          	jalr	-1026(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000601a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000601c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000601e:	0001db97          	auipc	s7,0x1d
    80006022:	fe2b8b93          	addi	s7,s7,-30 # 80023000 <disk>
    80006026:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006028:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000602a:	8a4e                	mv	s4,s3
    8000602c:	a051                	j	800060b0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000602e:	00fb86b3          	add	a3,s7,a5
    80006032:	96da                	add	a3,a3,s6
    80006034:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006038:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000603a:	0207c563          	bltz	a5,80006064 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000603e:	2485                	addiw	s1,s1,1
    80006040:	0711                	addi	a4,a4,4
    80006042:	23548d63          	beq	s1,s5,8000627c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006046:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006048:	0001f697          	auipc	a3,0x1f
    8000604c:	fd068693          	addi	a3,a3,-48 # 80025018 <disk+0x2018>
    80006050:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006052:	0006c583          	lbu	a1,0(a3)
    80006056:	fde1                	bnez	a1,8000602e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006058:	2785                	addiw	a5,a5,1
    8000605a:	0685                	addi	a3,a3,1
    8000605c:	ff879be3          	bne	a5,s8,80006052 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006060:	57fd                	li	a5,-1
    80006062:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006064:	02905a63          	blez	s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006068:	f9042503          	lw	a0,-112(s0)
    8000606c:	00000097          	auipc	ra,0x0
    80006070:	daa080e7          	jalr	-598(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006074:	4785                	li	a5,1
    80006076:	0297d163          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000607a:	f9442503          	lw	a0,-108(s0)
    8000607e:	00000097          	auipc	ra,0x0
    80006082:	d98080e7          	jalr	-616(ra) # 80005e16 <free_desc>
      for(int j = 0; j < i; j++)
    80006086:	4789                	li	a5,2
    80006088:	0097d863          	bge	a5,s1,80006098 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000608c:	f9842503          	lw	a0,-104(s0)
    80006090:	00000097          	auipc	ra,0x0
    80006094:	d86080e7          	jalr	-634(ra) # 80005e16 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006098:	0001f597          	auipc	a1,0x1f
    8000609c:	01058593          	addi	a1,a1,16 # 800250a8 <disk+0x20a8>
    800060a0:	0001f517          	auipc	a0,0x1f
    800060a4:	f7850513          	addi	a0,a0,-136 # 80025018 <disk+0x2018>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	290080e7          	jalr	656(ra) # 80002338 <sleep>
  for(int i = 0; i < 3; i++){
    800060b0:	f9040713          	addi	a4,s0,-112
    800060b4:	84ce                	mv	s1,s3
    800060b6:	bf41                	j	80006046 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800060b8:	4785                	li	a5,1
    800060ba:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800060be:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    800060c2:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    800060c6:	f9042983          	lw	s3,-112(s0)
    800060ca:	00499493          	slli	s1,s3,0x4
    800060ce:	0001fa17          	auipc	s4,0x1f
    800060d2:	f32a0a13          	addi	s4,s4,-206 # 80025000 <disk+0x2000>
    800060d6:	000a3a83          	ld	s5,0(s4)
    800060da:	9aa6                	add	s5,s5,s1
    800060dc:	f8040513          	addi	a0,s0,-128
    800060e0:	ffffb097          	auipc	ra,0xffffb
    800060e4:	000080e7          	jalr	ra # 800010e0 <kvmpa>
    800060e8:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    800060ec:	000a3783          	ld	a5,0(s4)
    800060f0:	97a6                	add	a5,a5,s1
    800060f2:	4741                	li	a4,16
    800060f4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060f6:	000a3783          	ld	a5,0(s4)
    800060fa:	97a6                	add	a5,a5,s1
    800060fc:	4705                	li	a4,1
    800060fe:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006102:	f9442703          	lw	a4,-108(s0)
    80006106:	000a3783          	ld	a5,0(s4)
    8000610a:	97a6                	add	a5,a5,s1
    8000610c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006110:	0712                	slli	a4,a4,0x4
    80006112:	000a3783          	ld	a5,0(s4)
    80006116:	97ba                	add	a5,a5,a4
    80006118:	05890693          	addi	a3,s2,88
    8000611c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000611e:	000a3783          	ld	a5,0(s4)
    80006122:	97ba                	add	a5,a5,a4
    80006124:	40000693          	li	a3,1024
    80006128:	c794                	sw	a3,8(a5)
  if(write)
    8000612a:	100d0a63          	beqz	s10,8000623e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000612e:	0001f797          	auipc	a5,0x1f
    80006132:	ed27b783          	ld	a5,-302(a5) # 80025000 <disk+0x2000>
    80006136:	97ba                	add	a5,a5,a4
    80006138:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000613c:	0001d517          	auipc	a0,0x1d
    80006140:	ec450513          	addi	a0,a0,-316 # 80023000 <disk>
    80006144:	0001f797          	auipc	a5,0x1f
    80006148:	ebc78793          	addi	a5,a5,-324 # 80025000 <disk+0x2000>
    8000614c:	6394                	ld	a3,0(a5)
    8000614e:	96ba                	add	a3,a3,a4
    80006150:	00c6d603          	lhu	a2,12(a3)
    80006154:	00166613          	ori	a2,a2,1
    80006158:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000615c:	f9842683          	lw	a3,-104(s0)
    80006160:	6390                	ld	a2,0(a5)
    80006162:	9732                	add	a4,a4,a2
    80006164:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006168:	20098613          	addi	a2,s3,512
    8000616c:	0612                	slli	a2,a2,0x4
    8000616e:	962a                	add	a2,a2,a0
    80006170:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006174:	00469713          	slli	a4,a3,0x4
    80006178:	6394                	ld	a3,0(a5)
    8000617a:	96ba                	add	a3,a3,a4
    8000617c:	6589                	lui	a1,0x2
    8000617e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006182:	94ae                	add	s1,s1,a1
    80006184:	94aa                	add	s1,s1,a0
    80006186:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006188:	6394                	ld	a3,0(a5)
    8000618a:	96ba                	add	a3,a3,a4
    8000618c:	4585                	li	a1,1
    8000618e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006190:	6394                	ld	a3,0(a5)
    80006192:	96ba                	add	a3,a3,a4
    80006194:	4509                	li	a0,2
    80006196:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000619a:	6394                	ld	a3,0(a5)
    8000619c:	9736                	add	a4,a4,a3
    8000619e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800061a2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800061a6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800061aa:	6794                	ld	a3,8(a5)
    800061ac:	0026d703          	lhu	a4,2(a3)
    800061b0:	8b1d                	andi	a4,a4,7
    800061b2:	2709                	addiw	a4,a4,2
    800061b4:	0706                	slli	a4,a4,0x1
    800061b6:	9736                	add	a4,a4,a3
    800061b8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800061bc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    800061c0:	6798                	ld	a4,8(a5)
    800061c2:	00275783          	lhu	a5,2(a4)
    800061c6:	2785                	addiw	a5,a5,1
    800061c8:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061cc:	100017b7          	lui	a5,0x10001
    800061d0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061d4:	00492703          	lw	a4,4(s2)
    800061d8:	4785                	li	a5,1
    800061da:	02f71163          	bne	a4,a5,800061fc <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    800061de:	0001f997          	auipc	s3,0x1f
    800061e2:	eca98993          	addi	s3,s3,-310 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    800061e6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800061e8:	85ce                	mv	a1,s3
    800061ea:	854a                	mv	a0,s2
    800061ec:	ffffc097          	auipc	ra,0xffffc
    800061f0:	14c080e7          	jalr	332(ra) # 80002338 <sleep>
  while(b->disk == 1) {
    800061f4:	00492783          	lw	a5,4(s2)
    800061f8:	fe9788e3          	beq	a5,s1,800061e8 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061fc:	f9042483          	lw	s1,-112(s0)
    80006200:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006204:	00479713          	slli	a4,a5,0x4
    80006208:	0001d797          	auipc	a5,0x1d
    8000620c:	df878793          	addi	a5,a5,-520 # 80023000 <disk>
    80006210:	97ba                	add	a5,a5,a4
    80006212:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006216:	0001f917          	auipc	s2,0x1f
    8000621a:	dea90913          	addi	s2,s2,-534 # 80025000 <disk+0x2000>
    free_desc(i);
    8000621e:	8526                	mv	a0,s1
    80006220:	00000097          	auipc	ra,0x0
    80006224:	bf6080e7          	jalr	-1034(ra) # 80005e16 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006228:	0492                	slli	s1,s1,0x4
    8000622a:	00093783          	ld	a5,0(s2)
    8000622e:	94be                	add	s1,s1,a5
    80006230:	00c4d783          	lhu	a5,12(s1)
    80006234:	8b85                	andi	a5,a5,1
    80006236:	cf89                	beqz	a5,80006250 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006238:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000623c:	b7cd                	j	8000621e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000623e:	0001f797          	auipc	a5,0x1f
    80006242:	dc27b783          	ld	a5,-574(a5) # 80025000 <disk+0x2000>
    80006246:	97ba                	add	a5,a5,a4
    80006248:	4689                	li	a3,2
    8000624a:	00d79623          	sh	a3,12(a5)
    8000624e:	b5fd                	j	8000613c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006250:	0001f517          	auipc	a0,0x1f
    80006254:	e5850513          	addi	a0,a0,-424 # 800250a8 <disk+0x20a8>
    80006258:	ffffb097          	auipc	ra,0xffffb
    8000625c:	a6c080e7          	jalr	-1428(ra) # 80000cc4 <release>
}
    80006260:	70e6                	ld	ra,120(sp)
    80006262:	7446                	ld	s0,112(sp)
    80006264:	74a6                	ld	s1,104(sp)
    80006266:	7906                	ld	s2,96(sp)
    80006268:	69e6                	ld	s3,88(sp)
    8000626a:	6a46                	ld	s4,80(sp)
    8000626c:	6aa6                	ld	s5,72(sp)
    8000626e:	6b06                	ld	s6,64(sp)
    80006270:	7be2                	ld	s7,56(sp)
    80006272:	7c42                	ld	s8,48(sp)
    80006274:	7ca2                	ld	s9,40(sp)
    80006276:	7d02                	ld	s10,32(sp)
    80006278:	6109                	addi	sp,sp,128
    8000627a:	8082                	ret
  if(write)
    8000627c:	e20d1ee3          	bnez	s10,800060b8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006280:	f8042023          	sw	zero,-128(s0)
    80006284:	bd2d                	j	800060be <virtio_disk_rw+0xe2>

0000000080006286 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006286:	1101                	addi	sp,sp,-32
    80006288:	ec06                	sd	ra,24(sp)
    8000628a:	e822                	sd	s0,16(sp)
    8000628c:	e426                	sd	s1,8(sp)
    8000628e:	e04a                	sd	s2,0(sp)
    80006290:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006292:	0001f517          	auipc	a0,0x1f
    80006296:	e1650513          	addi	a0,a0,-490 # 800250a8 <disk+0x20a8>
    8000629a:	ffffb097          	auipc	ra,0xffffb
    8000629e:	976080e7          	jalr	-1674(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062a2:	0001f717          	auipc	a4,0x1f
    800062a6:	d5e70713          	addi	a4,a4,-674 # 80025000 <disk+0x2000>
    800062aa:	02075783          	lhu	a5,32(a4)
    800062ae:	6b18                	ld	a4,16(a4)
    800062b0:	00275683          	lhu	a3,2(a4)
    800062b4:	8ebd                	xor	a3,a3,a5
    800062b6:	8a9d                	andi	a3,a3,7
    800062b8:	cab9                	beqz	a3,8000630e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800062ba:	0001d917          	auipc	s2,0x1d
    800062be:	d4690913          	addi	s2,s2,-698 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062c2:	0001f497          	auipc	s1,0x1f
    800062c6:	d3e48493          	addi	s1,s1,-706 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    800062ca:	078e                	slli	a5,a5,0x3
    800062cc:	97ba                	add	a5,a5,a4
    800062ce:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    800062d0:	20078713          	addi	a4,a5,512
    800062d4:	0712                	slli	a4,a4,0x4
    800062d6:	974a                	add	a4,a4,s2
    800062d8:	03074703          	lbu	a4,48(a4)
    800062dc:	ef21                	bnez	a4,80006334 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    800062de:	20078793          	addi	a5,a5,512
    800062e2:	0792                	slli	a5,a5,0x4
    800062e4:	97ca                	add	a5,a5,s2
    800062e6:	7798                	ld	a4,40(a5)
    800062e8:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    800062ec:	7788                	ld	a0,40(a5)
    800062ee:	ffffc097          	auipc	ra,0xffffc
    800062f2:	1d0080e7          	jalr	464(ra) # 800024be <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062f6:	0204d783          	lhu	a5,32(s1)
    800062fa:	2785                	addiw	a5,a5,1
    800062fc:	8b9d                	andi	a5,a5,7
    800062fe:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006302:	6898                	ld	a4,16(s1)
    80006304:	00275683          	lhu	a3,2(a4)
    80006308:	8a9d                	andi	a3,a3,7
    8000630a:	fcf690e3          	bne	a3,a5,800062ca <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000630e:	10001737          	lui	a4,0x10001
    80006312:	533c                	lw	a5,96(a4)
    80006314:	8b8d                	andi	a5,a5,3
    80006316:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006318:	0001f517          	auipc	a0,0x1f
    8000631c:	d9050513          	addi	a0,a0,-624 # 800250a8 <disk+0x20a8>
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	9a4080e7          	jalr	-1628(ra) # 80000cc4 <release>
}
    80006328:	60e2                	ld	ra,24(sp)
    8000632a:	6442                	ld	s0,16(sp)
    8000632c:	64a2                	ld	s1,8(sp)
    8000632e:	6902                	ld	s2,0(sp)
    80006330:	6105                	addi	sp,sp,32
    80006332:	8082                	ret
      panic("virtio_disk_intr status");
    80006334:	00002517          	auipc	a0,0x2
    80006338:	48c50513          	addi	a0,a0,1164 # 800087c0 <syscalls+0x3d0>
    8000633c:	ffffa097          	auipc	ra,0xffffa
    80006340:	20c080e7          	jalr	524(ra) # 80000548 <panic>
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
