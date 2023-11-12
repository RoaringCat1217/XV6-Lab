
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8e013103          	ld	sp,-1824(sp) # 800088e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	f3478793          	addi	a5,a5,-204 # 80005f90 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd77df>
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
    8000012a:	72a080e7          	jalr	1834(ra) # 80002850 <either_copyin>
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
    800001d2:	9e6080e7          	jalr	-1562(ra) # 80001bb4 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	3ba080e7          	jalr	954(ra) # 80002598 <sleep>
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
    8000021e:	5e0080e7          	jalr	1504(ra) # 800027fa <either_copyout>
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
    80000300:	5aa080e7          	jalr	1450(ra) # 800028a6 <procdump>
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
    80000454:	2ce080e7          	jalr	718(ra) # 8000271e <wakeup>
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
    80000486:	72e78793          	addi	a5,a5,1838 # 80021bb0 <devsw>
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
    800008ba:	e68080e7          	jalr	-408(ra) # 8000271e <wakeup>
    
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
    80000954:	c48080e7          	jalr	-952(ra) # 80002598 <sleep>
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
    80000a38:	00026797          	auipc	a5,0x26
    80000a3c:	5e878793          	addi	a5,a5,1512 # 80027020 <end>
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
    80000b08:	00026517          	auipc	a0,0x26
    80000b0c:	51850513          	addi	a0,a0,1304 # 80027020 <end>
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
    80000bae:	fee080e7          	jalr	-18(ra) # 80001b98 <mycpu>
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
    80000be0:	fbc080e7          	jalr	-68(ra) # 80001b98 <mycpu>
    80000be4:	5d3c                	lw	a5,120(a0)
    80000be6:	cf89                	beqz	a5,80000c00 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000be8:	00001097          	auipc	ra,0x1
    80000bec:	fb0080e7          	jalr	-80(ra) # 80001b98 <mycpu>
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
    80000c04:	f98080e7          	jalr	-104(ra) # 80001b98 <mycpu>
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
    80000c44:	f58080e7          	jalr	-168(ra) # 80001b98 <mycpu>
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
    80000c70:	f2c080e7          	jalr	-212(ra) # 80001b98 <mycpu>
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
    80000eca:	cc2080e7          	jalr	-830(ra) # 80001b88 <cpuid>
#endif    
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
    80000ee6:	ca6080e7          	jalr	-858(ra) # 80001b88 <cpuid>
    80000eea:	85aa                	mv	a1,a0
    80000eec:	00007517          	auipc	a0,0x7
    80000ef0:	1cc50513          	addi	a0,a0,460 # 800080b8 <digits+0x78>
    80000ef4:	fffff097          	auipc	ra,0xfffff
    80000ef8:	69e080e7          	jalr	1694(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000efc:	00000097          	auipc	ra,0x0
    80000f00:	17c080e7          	jalr	380(ra) # 80001078 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f04:	00002097          	auipc	ra,0x2
    80000f08:	ae2080e7          	jalr	-1310(ra) # 800029e6 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f0c:	00005097          	auipc	ra,0x5
    80000f10:	0c4080e7          	jalr	196(ra) # 80005fd0 <plicinithart>
  }

  scheduler();        
    80000f14:	00001097          	auipc	ra,0x1
    80000f18:	36c080e7          	jalr	876(ra) # 80002280 <scheduler>
    consoleinit();
    80000f1c:	fffff097          	auipc	ra,0xfffff
    80000f20:	53e080e7          	jalr	1342(ra) # 8000045a <consoleinit>
    statsinit();
    80000f24:	00006097          	auipc	ra,0x6
    80000f28:	86e080e7          	jalr	-1938(ra) # 80006792 <statsinit>
    printfinit();
    80000f2c:	00000097          	auipc	ra,0x0
    80000f30:	84c080e7          	jalr	-1972(ra) # 80000778 <printfinit>
    printf("\n");
    80000f34:	00007517          	auipc	a0,0x7
    80000f38:	19450513          	addi	a0,a0,404 # 800080c8 <digits+0x88>
    80000f3c:	fffff097          	auipc	ra,0xfffff
    80000f40:	656080e7          	jalr	1622(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f44:	00007517          	auipc	a0,0x7
    80000f48:	15c50513          	addi	a0,a0,348 # 800080a0 <digits+0x60>
    80000f4c:	fffff097          	auipc	ra,0xfffff
    80000f50:	646080e7          	jalr	1606(ra) # 80000592 <printf>
    printf("\n");
    80000f54:	00007517          	auipc	a0,0x7
    80000f58:	17450513          	addi	a0,a0,372 # 800080c8 <digits+0x88>
    80000f5c:	fffff097          	auipc	ra,0xfffff
    80000f60:	636080e7          	jalr	1590(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f64:	00000097          	auipc	ra,0x0
    80000f68:	b80080e7          	jalr	-1152(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	6f4080e7          	jalr	1780(ra) # 80001660 <kvminit>
    kvminithart();   // turn on paging
    80000f74:	00000097          	auipc	ra,0x0
    80000f78:	104080e7          	jalr	260(ra) # 80001078 <kvminithart>
    procinit();      // process table
    80000f7c:	00001097          	auipc	ra,0x1
    80000f80:	ba4080e7          	jalr	-1116(ra) # 80001b20 <procinit>
    trapinit();      // trap vectors
    80000f84:	00002097          	auipc	ra,0x2
    80000f88:	a3a080e7          	jalr	-1478(ra) # 800029be <trapinit>
    trapinithart();  // install kernel trap vector
    80000f8c:	00002097          	auipc	ra,0x2
    80000f90:	a5a080e7          	jalr	-1446(ra) # 800029e6 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f94:	00005097          	auipc	ra,0x5
    80000f98:	026080e7          	jalr	38(ra) # 80005fba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f9c:	00005097          	auipc	ra,0x5
    80000fa0:	034080e7          	jalr	52(ra) # 80005fd0 <plicinithart>
    binit();         // buffer cache
    80000fa4:	00002097          	auipc	ra,0x2
    80000fa8:	184080e7          	jalr	388(ra) # 80003128 <binit>
    iinit();         // inode cache
    80000fac:	00003097          	auipc	ra,0x3
    80000fb0:	814080e7          	jalr	-2028(ra) # 800037c0 <iinit>
    fileinit();      // file table
    80000fb4:	00003097          	auipc	ra,0x3
    80000fb8:	7ae080e7          	jalr	1966(ra) # 80004762 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fbc:	00005097          	auipc	ra,0x5
    80000fc0:	11c080e7          	jalr	284(ra) # 800060d8 <virtio_disk_init>
    userinit();      // first user process
    80000fc4:	00001097          	auipc	ra,0x1
    80000fc8:	f9a080e7          	jalr	-102(ra) # 80001f5e <userinit>
    __sync_synchronize();
    80000fcc:	0ff0000f          	fence
    started = 1;
    80000fd0:	4785                	li	a5,1
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	02f72d23          	sw	a5,58(a4) # 8000900c <started>
    80000fda:	bf2d                	j	80000f14 <main+0x56>

0000000080000fdc <_kvmcopy_level>:

extern char trampoline[]; // trampoline.S

int
_kvmcopy_level(pagetable_t new, pagetable_t old, int level)
{
    80000fdc:	715d                	addi	sp,sp,-80
    80000fde:	e486                	sd	ra,72(sp)
    80000fe0:	e0a2                	sd	s0,64(sp)
    80000fe2:	fc26                	sd	s1,56(sp)
    80000fe4:	f84a                	sd	s2,48(sp)
    80000fe6:	f44e                	sd	s3,40(sp)
    80000fe8:	f052                	sd	s4,32(sp)
    80000fea:	ec56                	sd	s5,24(sp)
    80000fec:	e85a                	sd	s6,16(sp)
    80000fee:	e45e                	sd	s7,8(sp)
    80000ff0:	e062                	sd	s8,0(sp)
    80000ff2:	0880                	addi	s0,sp,80
    80000ff4:	8b32                	mv	s6,a2
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80000ff6:	84ae                	mv	s1,a1
    80000ff8:	892a                	mv	s2,a0
    80000ffa:	6a05                	lui	s4,0x1
    80000ffc:	9a2e                	add	s4,s4,a1
    pte_t pte = old[i];
    if(pte & PTE_V && level < 2)
    80000ffe:	4b85                	li	s7,1
      // this PTE points to a lower-level page table.
      pagetable_t child = (pagetable_t)kalloc();
      if (child == 0)
        return -1;
      new[i] = PA2PTE(child) | PTE_FLAGS(old[i]);
      if (_kvmcopy_level(child, (pagetable_t)PTE2PA(pte), level + 1) < 0)
    80001000:	00160c1b          	addiw	s8,a2,1
    80001004:	a039                	j	80001012 <_kvmcopy_level+0x36>
        return -1;
    } 
    else if(pte & PTE_V)
    {
      new[i] = old[i];
    80001006:	01393023          	sd	s3,0(s2)
  for(int i = 0; i < 512; i++){
    8000100a:	04a1                	addi	s1,s1,8
    8000100c:	0921                	addi	s2,s2,8
    8000100e:	05448663          	beq	s1,s4,8000105a <_kvmcopy_level+0x7e>
    pte_t pte = old[i];
    80001012:	0004b983          	ld	s3,0(s1)
    if(pte & PTE_V && level < 2)
    80001016:	0019f793          	andi	a5,s3,1
    8000101a:	cf8d                	beqz	a5,80001054 <_kvmcopy_level+0x78>
    8000101c:	ff6bc5e3          	blt	s7,s6,80001006 <_kvmcopy_level+0x2a>
      pagetable_t child = (pagetable_t)kalloc();
    80001020:	00000097          	auipc	ra,0x0
    80001024:	b00080e7          	jalr	-1280(ra) # 80000b20 <kalloc>
      if (child == 0)
    80001028:	c531                	beqz	a0,80001074 <_kvmcopy_level+0x98>
      new[i] = PA2PTE(child) | PTE_FLAGS(old[i]);
    8000102a:	00c55793          	srli	a5,a0,0xc
    8000102e:	07aa                	slli	a5,a5,0xa
    80001030:	6098                	ld	a4,0(s1)
    80001032:	3ff77713          	andi	a4,a4,1023
    80001036:	8fd9                	or	a5,a5,a4
    80001038:	00f93023          	sd	a5,0(s2)
      if (_kvmcopy_level(child, (pagetable_t)PTE2PA(pte), level + 1) < 0)
    8000103c:	00a9d593          	srli	a1,s3,0xa
    80001040:	8662                	mv	a2,s8
    80001042:	05b2                	slli	a1,a1,0xc
    80001044:	00000097          	auipc	ra,0x0
    80001048:	f98080e7          	jalr	-104(ra) # 80000fdc <_kvmcopy_level>
    8000104c:	fa055fe3          	bgez	a0,8000100a <_kvmcopy_level+0x2e>
        return -1;
    80001050:	557d                	li	a0,-1
    80001052:	a029                	j	8000105c <_kvmcopy_level+0x80>
    }
    else
    {
      new[i] = 0;
    80001054:	00093023          	sd	zero,0(s2)
    80001058:	bf4d                	j	8000100a <_kvmcopy_level+0x2e>
    }
  }
  return 0;
    8000105a:	4501                	li	a0,0
}
    8000105c:	60a6                	ld	ra,72(sp)
    8000105e:	6406                	ld	s0,64(sp)
    80001060:	74e2                	ld	s1,56(sp)
    80001062:	7942                	ld	s2,48(sp)
    80001064:	79a2                	ld	s3,40(sp)
    80001066:	7a02                	ld	s4,32(sp)
    80001068:	6ae2                	ld	s5,24(sp)
    8000106a:	6b42                	ld	s6,16(sp)
    8000106c:	6ba2                	ld	s7,8(sp)
    8000106e:	6c02                	ld	s8,0(sp)
    80001070:	6161                	addi	sp,sp,80
    80001072:	8082                	ret
        return -1;
    80001074:	557d                	li	a0,-1
    80001076:	b7dd                	j	8000105c <_kvmcopy_level+0x80>

0000000080001078 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001078:	1141                	addi	sp,sp,-16
    8000107a:	e422                	sd	s0,8(sp)
    8000107c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000107e:	00008797          	auipc	a5,0x8
    80001082:	f927b783          	ld	a5,-110(a5) # 80009010 <kernel_pagetable>
    80001086:	83b1                	srli	a5,a5,0xc
    80001088:	577d                	li	a4,-1
    8000108a:	177e                	slli	a4,a4,0x3f
    8000108c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000108e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001092:	12000073          	sfence.vma
  sfence_vma();
}
    80001096:	6422                	ld	s0,8(sp)
    80001098:	0141                	addi	sp,sp,16
    8000109a:	8082                	ret

000000008000109c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000109c:	7139                	addi	sp,sp,-64
    8000109e:	fc06                	sd	ra,56(sp)
    800010a0:	f822                	sd	s0,48(sp)
    800010a2:	f426                	sd	s1,40(sp)
    800010a4:	f04a                	sd	s2,32(sp)
    800010a6:	ec4e                	sd	s3,24(sp)
    800010a8:	e852                	sd	s4,16(sp)
    800010aa:	e456                	sd	s5,8(sp)
    800010ac:	e05a                	sd	s6,0(sp)
    800010ae:	0080                	addi	s0,sp,64
    800010b0:	84aa                	mv	s1,a0
    800010b2:	89ae                	mv	s3,a1
    800010b4:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    800010b6:	57fd                	li	a5,-1
    800010b8:	83e9                	srli	a5,a5,0x1a
    800010ba:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    800010bc:	4b31                	li	s6,12
  if(va >= MAXVA)
    800010be:	04b7f263          	bgeu	a5,a1,80001102 <walk+0x66>
    panic("walk");
    800010c2:	00007517          	auipc	a0,0x7
    800010c6:	00e50513          	addi	a0,a0,14 # 800080d0 <digits+0x90>
    800010ca:	fffff097          	auipc	ra,0xfffff
    800010ce:	47e080e7          	jalr	1150(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010d2:	060a8663          	beqz	s5,8000113e <walk+0xa2>
    800010d6:	00000097          	auipc	ra,0x0
    800010da:	a4a080e7          	jalr	-1462(ra) # 80000b20 <kalloc>
    800010de:	84aa                	mv	s1,a0
    800010e0:	c529                	beqz	a0,8000112a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010e2:	6605                	lui	a2,0x1
    800010e4:	4581                	li	a1,0
    800010e6:	00000097          	auipc	ra,0x0
    800010ea:	c26080e7          	jalr	-986(ra) # 80000d0c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010ee:	00c4d793          	srli	a5,s1,0xc
    800010f2:	07aa                	slli	a5,a5,0xa
    800010f4:	0017e793          	ori	a5,a5,1
    800010f8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010fc:	3a5d                	addiw	s4,s4,-9
    800010fe:	036a0063          	beq	s4,s6,8000111e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001102:	0149d933          	srl	s2,s3,s4
    80001106:	1ff97913          	andi	s2,s2,511
    8000110a:	090e                	slli	s2,s2,0x3
    8000110c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000110e:	00093483          	ld	s1,0(s2)
    80001112:	0014f793          	andi	a5,s1,1
    80001116:	dfd5                	beqz	a5,800010d2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001118:	80a9                	srli	s1,s1,0xa
    8000111a:	04b2                	slli	s1,s1,0xc
    8000111c:	b7c5                	j	800010fc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000111e:	00c9d513          	srli	a0,s3,0xc
    80001122:	1ff57513          	andi	a0,a0,511
    80001126:	050e                	slli	a0,a0,0x3
    80001128:	9526                	add	a0,a0,s1
}
    8000112a:	70e2                	ld	ra,56(sp)
    8000112c:	7442                	ld	s0,48(sp)
    8000112e:	74a2                	ld	s1,40(sp)
    80001130:	7902                	ld	s2,32(sp)
    80001132:	69e2                	ld	s3,24(sp)
    80001134:	6a42                	ld	s4,16(sp)
    80001136:	6aa2                	ld	s5,8(sp)
    80001138:	6b02                	ld	s6,0(sp)
    8000113a:	6121                	addi	sp,sp,64
    8000113c:	8082                	ret
        return 0;
    8000113e:	4501                	li	a0,0
    80001140:	b7ed                	j	8000112a <walk+0x8e>

0000000080001142 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001142:	57fd                	li	a5,-1
    80001144:	83e9                	srli	a5,a5,0x1a
    80001146:	00b7f463          	bgeu	a5,a1,8000114e <walkaddr+0xc>
    return 0;
    8000114a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000114c:	8082                	ret
{
    8000114e:	1141                	addi	sp,sp,-16
    80001150:	e406                	sd	ra,8(sp)
    80001152:	e022                	sd	s0,0(sp)
    80001154:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001156:	4601                	li	a2,0
    80001158:	00000097          	auipc	ra,0x0
    8000115c:	f44080e7          	jalr	-188(ra) # 8000109c <walk>
  if(pte == 0)
    80001160:	c105                	beqz	a0,80001180 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001162:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001164:	0117f693          	andi	a3,a5,17
    80001168:	4745                	li	a4,17
    return 0;
    8000116a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000116c:	00e68663          	beq	a3,a4,80001178 <walkaddr+0x36>
}
    80001170:	60a2                	ld	ra,8(sp)
    80001172:	6402                	ld	s0,0(sp)
    80001174:	0141                	addi	sp,sp,16
    80001176:	8082                	ret
  pa = PTE2PA(*pte);
    80001178:	00a7d513          	srli	a0,a5,0xa
    8000117c:	0532                	slli	a0,a0,0xc
  return pa;
    8000117e:	bfcd                	j	80001170 <walkaddr+0x2e>
    return 0;
    80001180:	4501                	li	a0,0
    80001182:	b7fd                	j	80001170 <walkaddr+0x2e>

0000000080001184 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001184:	1101                	addi	sp,sp,-32
    80001186:	ec06                	sd	ra,24(sp)
    80001188:	e822                	sd	s0,16(sp)
    8000118a:	e426                	sd	s1,8(sp)
    8000118c:	e04a                	sd	s2,0(sp)
    8000118e:	1000                	addi	s0,sp,32
    80001190:	84aa                	mv	s1,a0
  uint64 off = va % PGSIZE;
    80001192:	1552                	slli	a0,a0,0x34
    80001194:	03455913          	srli	s2,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(myproc()->kpagetable, va, 0);
    80001198:	00001097          	auipc	ra,0x1
    8000119c:	a1c080e7          	jalr	-1508(ra) # 80001bb4 <myproc>
    800011a0:	4601                	li	a2,0
    800011a2:	85a6                	mv	a1,s1
    800011a4:	6d28                	ld	a0,88(a0)
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	ef6080e7          	jalr	-266(ra) # 8000109c <walk>
  if(pte == 0)
    800011ae:	cd11                	beqz	a0,800011ca <kvmpa+0x46>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    800011b0:	6108                	ld	a0,0(a0)
    800011b2:	00157793          	andi	a5,a0,1
    800011b6:	c395                	beqz	a5,800011da <kvmpa+0x56>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    800011b8:	8129                	srli	a0,a0,0xa
    800011ba:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    800011bc:	954a                	add	a0,a0,s2
    800011be:	60e2                	ld	ra,24(sp)
    800011c0:	6442                	ld	s0,16(sp)
    800011c2:	64a2                	ld	s1,8(sp)
    800011c4:	6902                	ld	s2,0(sp)
    800011c6:	6105                	addi	sp,sp,32
    800011c8:	8082                	ret
    panic("kvmpa");
    800011ca:	00007517          	auipc	a0,0x7
    800011ce:	f0e50513          	addi	a0,a0,-242 # 800080d8 <digits+0x98>
    800011d2:	fffff097          	auipc	ra,0xfffff
    800011d6:	376080e7          	jalr	886(ra) # 80000548 <panic>
    panic("kvmpa");
    800011da:	00007517          	auipc	a0,0x7
    800011de:	efe50513          	addi	a0,a0,-258 # 800080d8 <digits+0x98>
    800011e2:	fffff097          	auipc	ra,0xfffff
    800011e6:	366080e7          	jalr	870(ra) # 80000548 <panic>

00000000800011ea <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011ea:	715d                	addi	sp,sp,-80
    800011ec:	e486                	sd	ra,72(sp)
    800011ee:	e0a2                	sd	s0,64(sp)
    800011f0:	fc26                	sd	s1,56(sp)
    800011f2:	f84a                	sd	s2,48(sp)
    800011f4:	f44e                	sd	s3,40(sp)
    800011f6:	f052                	sd	s4,32(sp)
    800011f8:	ec56                	sd	s5,24(sp)
    800011fa:	e85a                	sd	s6,16(sp)
    800011fc:	e45e                	sd	s7,8(sp)
    800011fe:	0880                	addi	s0,sp,80
    80001200:	8aaa                	mv	s5,a0
    80001202:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001204:	777d                	lui	a4,0xfffff
    80001206:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000120a:	167d                	addi	a2,a2,-1
    8000120c:	00b609b3          	add	s3,a2,a1
    80001210:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001214:	893e                	mv	s2,a5
    80001216:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000121a:	6b85                	lui	s7,0x1
    8000121c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001220:	4605                	li	a2,1
    80001222:	85ca                	mv	a1,s2
    80001224:	8556                	mv	a0,s5
    80001226:	00000097          	auipc	ra,0x0
    8000122a:	e76080e7          	jalr	-394(ra) # 8000109c <walk>
    8000122e:	c51d                	beqz	a0,8000125c <mappages+0x72>
    if(*pte & PTE_V)
    80001230:	611c                	ld	a5,0(a0)
    80001232:	8b85                	andi	a5,a5,1
    80001234:	ef81                	bnez	a5,8000124c <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001236:	80b1                	srli	s1,s1,0xc
    80001238:	04aa                	slli	s1,s1,0xa
    8000123a:	0164e4b3          	or	s1,s1,s6
    8000123e:	0014e493          	ori	s1,s1,1
    80001242:	e104                	sd	s1,0(a0)
    if(a == last)
    80001244:	03390863          	beq	s2,s3,80001274 <mappages+0x8a>
    a += PGSIZE;
    80001248:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000124a:	bfc9                	j	8000121c <mappages+0x32>
      panic("remap");
    8000124c:	00007517          	auipc	a0,0x7
    80001250:	e9450513          	addi	a0,a0,-364 # 800080e0 <digits+0xa0>
    80001254:	fffff097          	auipc	ra,0xfffff
    80001258:	2f4080e7          	jalr	756(ra) # 80000548 <panic>
      return -1;
    8000125c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000125e:	60a6                	ld	ra,72(sp)
    80001260:	6406                	ld	s0,64(sp)
    80001262:	74e2                	ld	s1,56(sp)
    80001264:	7942                	ld	s2,48(sp)
    80001266:	79a2                	ld	s3,40(sp)
    80001268:	7a02                	ld	s4,32(sp)
    8000126a:	6ae2                	ld	s5,24(sp)
    8000126c:	6b42                	ld	s6,16(sp)
    8000126e:	6ba2                	ld	s7,8(sp)
    80001270:	6161                	addi	sp,sp,80
    80001272:	8082                	ret
  return 0;
    80001274:	4501                	li	a0,0
    80001276:	b7e5                	j	8000125e <mappages+0x74>

0000000080001278 <kvmmap>:
{
    80001278:	1141                	addi	sp,sp,-16
    8000127a:	e406                	sd	ra,8(sp)
    8000127c:	e022                	sd	s0,0(sp)
    8000127e:	0800                	addi	s0,sp,16
    80001280:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    80001282:	86ae                	mv	a3,a1
    80001284:	85aa                	mv	a1,a0
    80001286:	00008517          	auipc	a0,0x8
    8000128a:	d8a53503          	ld	a0,-630(a0) # 80009010 <kernel_pagetable>
    8000128e:	00000097          	auipc	ra,0x0
    80001292:	f5c080e7          	jalr	-164(ra) # 800011ea <mappages>
    80001296:	e509                	bnez	a0,800012a0 <kvmmap+0x28>
}
    80001298:	60a2                	ld	ra,8(sp)
    8000129a:	6402                	ld	s0,0(sp)
    8000129c:	0141                	addi	sp,sp,16
    8000129e:	8082                	ret
    panic("kvmmap");
    800012a0:	00007517          	auipc	a0,0x7
    800012a4:	e4850513          	addi	a0,a0,-440 # 800080e8 <digits+0xa8>
    800012a8:	fffff097          	auipc	ra,0xfffff
    800012ac:	2a0080e7          	jalr	672(ra) # 80000548 <panic>

00000000800012b0 <kvmmap_usr>:
{
    800012b0:	1141                	addi	sp,sp,-16
    800012b2:	e406                	sd	ra,8(sp)
    800012b4:	e022                	sd	s0,0(sp)
    800012b6:	0800                	addi	s0,sp,16
    800012b8:	87b6                	mv	a5,a3
  if (mappages(kpagetable, va, sz, pa, perm) != 0)
    800012ba:	86b2                	mv	a3,a2
    800012bc:	863e                	mv	a2,a5
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f2c080e7          	jalr	-212(ra) # 800011ea <mappages>
    800012c6:	00a03533          	snez	a0,a0
}
    800012ca:	40a00533          	neg	a0,a0
    800012ce:	60a2                	ld	ra,8(sp)
    800012d0:	6402                	ld	s0,0(sp)
    800012d2:	0141                	addi	sp,sp,16
    800012d4:	8082                	ret

00000000800012d6 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012d6:	715d                	addi	sp,sp,-80
    800012d8:	e486                	sd	ra,72(sp)
    800012da:	e0a2                	sd	s0,64(sp)
    800012dc:	fc26                	sd	s1,56(sp)
    800012de:	f84a                	sd	s2,48(sp)
    800012e0:	f44e                	sd	s3,40(sp)
    800012e2:	f052                	sd	s4,32(sp)
    800012e4:	ec56                	sd	s5,24(sp)
    800012e6:	e85a                	sd	s6,16(sp)
    800012e8:	e45e                	sd	s7,8(sp)
    800012ea:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012ec:	03459793          	slli	a5,a1,0x34
    800012f0:	e795                	bnez	a5,8000131c <uvmunmap+0x46>
    800012f2:	8a2a                	mv	s4,a0
    800012f4:	892e                	mv	s2,a1
    800012f6:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012f8:	0632                	slli	a2,a2,0xc
    800012fa:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012fe:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001300:	6b05                	lui	s6,0x1
    80001302:	0735e863          	bltu	a1,s3,80001372 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001306:	60a6                	ld	ra,72(sp)
    80001308:	6406                	ld	s0,64(sp)
    8000130a:	74e2                	ld	s1,56(sp)
    8000130c:	7942                	ld	s2,48(sp)
    8000130e:	79a2                	ld	s3,40(sp)
    80001310:	7a02                	ld	s4,32(sp)
    80001312:	6ae2                	ld	s5,24(sp)
    80001314:	6b42                	ld	s6,16(sp)
    80001316:	6ba2                	ld	s7,8(sp)
    80001318:	6161                	addi	sp,sp,80
    8000131a:	8082                	ret
    panic("uvmunmap: not aligned");
    8000131c:	00007517          	auipc	a0,0x7
    80001320:	dd450513          	addi	a0,a0,-556 # 800080f0 <digits+0xb0>
    80001324:	fffff097          	auipc	ra,0xfffff
    80001328:	224080e7          	jalr	548(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    8000132c:	00007517          	auipc	a0,0x7
    80001330:	ddc50513          	addi	a0,a0,-548 # 80008108 <digits+0xc8>
    80001334:	fffff097          	auipc	ra,0xfffff
    80001338:	214080e7          	jalr	532(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    8000133c:	00007517          	auipc	a0,0x7
    80001340:	ddc50513          	addi	a0,a0,-548 # 80008118 <digits+0xd8>
    80001344:	fffff097          	auipc	ra,0xfffff
    80001348:	204080e7          	jalr	516(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    8000134c:	00007517          	auipc	a0,0x7
    80001350:	de450513          	addi	a0,a0,-540 # 80008130 <digits+0xf0>
    80001354:	fffff097          	auipc	ra,0xfffff
    80001358:	1f4080e7          	jalr	500(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    8000135c:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000135e:	0532                	slli	a0,a0,0xc
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	6c4080e7          	jalr	1732(ra) # 80000a24 <kfree>
    *pte = 0;
    80001368:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	995a                	add	s2,s2,s6
    8000136e:	f9397ce3          	bgeu	s2,s3,80001306 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001372:	4601                	li	a2,0
    80001374:	85ca                	mv	a1,s2
    80001376:	8552                	mv	a0,s4
    80001378:	00000097          	auipc	ra,0x0
    8000137c:	d24080e7          	jalr	-732(ra) # 8000109c <walk>
    80001380:	84aa                	mv	s1,a0
    80001382:	d54d                	beqz	a0,8000132c <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001384:	6108                	ld	a0,0(a0)
    80001386:	00157793          	andi	a5,a0,1
    8000138a:	dbcd                	beqz	a5,8000133c <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000138c:	3ff57793          	andi	a5,a0,1023
    80001390:	fb778ee3          	beq	a5,s7,8000134c <uvmunmap+0x76>
    if(do_free){
    80001394:	fc0a8ae3          	beqz	s5,80001368 <uvmunmap+0x92>
    80001398:	b7d1                	j	8000135c <uvmunmap+0x86>

000000008000139a <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000139a:	1101                	addi	sp,sp,-32
    8000139c:	ec06                	sd	ra,24(sp)
    8000139e:	e822                	sd	s0,16(sp)
    800013a0:	e426                	sd	s1,8(sp)
    800013a2:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013a4:	fffff097          	auipc	ra,0xfffff
    800013a8:	77c080e7          	jalr	1916(ra) # 80000b20 <kalloc>
    800013ac:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013ae:	c519                	beqz	a0,800013bc <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013b0:	6605                	lui	a2,0x1
    800013b2:	4581                	li	a1,0
    800013b4:	00000097          	auipc	ra,0x0
    800013b8:	958080e7          	jalr	-1704(ra) # 80000d0c <memset>
  return pagetable;
}
    800013bc:	8526                	mv	a0,s1
    800013be:	60e2                	ld	ra,24(sp)
    800013c0:	6442                	ld	s0,16(sp)
    800013c2:	64a2                	ld	s1,8(sp)
    800013c4:	6105                	addi	sp,sp,32
    800013c6:	8082                	ret

00000000800013c8 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013c8:	7179                	addi	sp,sp,-48
    800013ca:	f406                	sd	ra,40(sp)
    800013cc:	f022                	sd	s0,32(sp)
    800013ce:	ec26                	sd	s1,24(sp)
    800013d0:	e84a                	sd	s2,16(sp)
    800013d2:	e44e                	sd	s3,8(sp)
    800013d4:	e052                	sd	s4,0(sp)
    800013d6:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013d8:	6785                	lui	a5,0x1
    800013da:	04f67863          	bgeu	a2,a5,8000142a <uvminit+0x62>
    800013de:	8a2a                	mv	s4,a0
    800013e0:	89ae                	mv	s3,a1
    800013e2:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800013e4:	fffff097          	auipc	ra,0xfffff
    800013e8:	73c080e7          	jalr	1852(ra) # 80000b20 <kalloc>
    800013ec:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013ee:	6605                	lui	a2,0x1
    800013f0:	4581                	li	a1,0
    800013f2:	00000097          	auipc	ra,0x0
    800013f6:	91a080e7          	jalr	-1766(ra) # 80000d0c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013fa:	4779                	li	a4,30
    800013fc:	86ca                	mv	a3,s2
    800013fe:	6605                	lui	a2,0x1
    80001400:	4581                	li	a1,0
    80001402:	8552                	mv	a0,s4
    80001404:	00000097          	auipc	ra,0x0
    80001408:	de6080e7          	jalr	-538(ra) # 800011ea <mappages>
  memmove(mem, src, sz);
    8000140c:	8626                	mv	a2,s1
    8000140e:	85ce                	mv	a1,s3
    80001410:	854a                	mv	a0,s2
    80001412:	00000097          	auipc	ra,0x0
    80001416:	95a080e7          	jalr	-1702(ra) # 80000d6c <memmove>
}
    8000141a:	70a2                	ld	ra,40(sp)
    8000141c:	7402                	ld	s0,32(sp)
    8000141e:	64e2                	ld	s1,24(sp)
    80001420:	6942                	ld	s2,16(sp)
    80001422:	69a2                	ld	s3,8(sp)
    80001424:	6a02                	ld	s4,0(sp)
    80001426:	6145                	addi	sp,sp,48
    80001428:	8082                	ret
    panic("inituvm: more than a page");
    8000142a:	00007517          	auipc	a0,0x7
    8000142e:	d1e50513          	addi	a0,a0,-738 # 80008148 <digits+0x108>
    80001432:	fffff097          	auipc	ra,0xfffff
    80001436:	116080e7          	jalr	278(ra) # 80000548 <panic>

000000008000143a <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000143a:	1101                	addi	sp,sp,-32
    8000143c:	ec06                	sd	ra,24(sp)
    8000143e:	e822                	sd	s0,16(sp)
    80001440:	e426                	sd	s1,8(sp)
    80001442:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001444:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001446:	00b67d63          	bgeu	a2,a1,80001460 <uvmdealloc+0x26>
    8000144a:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    8000144c:	6785                	lui	a5,0x1
    8000144e:	17fd                	addi	a5,a5,-1
    80001450:	00f60733          	add	a4,a2,a5
    80001454:	767d                	lui	a2,0xfffff
    80001456:	8f71                	and	a4,a4,a2
    80001458:	97ae                	add	a5,a5,a1
    8000145a:	8ff1                	and	a5,a5,a2
    8000145c:	00f76863          	bltu	a4,a5,8000146c <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001460:	8526                	mv	a0,s1
    80001462:	60e2                	ld	ra,24(sp)
    80001464:	6442                	ld	s0,16(sp)
    80001466:	64a2                	ld	s1,8(sp)
    80001468:	6105                	addi	sp,sp,32
    8000146a:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    8000146c:	8f99                	sub	a5,a5,a4
    8000146e:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001470:	4685                	li	a3,1
    80001472:	0007861b          	sext.w	a2,a5
    80001476:	85ba                	mv	a1,a4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	e5e080e7          	jalr	-418(ra) # 800012d6 <uvmunmap>
    80001480:	b7c5                	j	80001460 <uvmdealloc+0x26>

0000000080001482 <uvmalloc>:
  if(newsz < oldsz)
    80001482:	0ab66163          	bltu	a2,a1,80001524 <uvmalloc+0xa2>
{
    80001486:	7139                	addi	sp,sp,-64
    80001488:	fc06                	sd	ra,56(sp)
    8000148a:	f822                	sd	s0,48(sp)
    8000148c:	f426                	sd	s1,40(sp)
    8000148e:	f04a                	sd	s2,32(sp)
    80001490:	ec4e                	sd	s3,24(sp)
    80001492:	e852                	sd	s4,16(sp)
    80001494:	e456                	sd	s5,8(sp)
    80001496:	0080                	addi	s0,sp,64
    80001498:	8aaa                	mv	s5,a0
    8000149a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000149c:	6985                	lui	s3,0x1
    8000149e:	19fd                	addi	s3,s3,-1
    800014a0:	95ce                	add	a1,a1,s3
    800014a2:	79fd                	lui	s3,0xfffff
    800014a4:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014a8:	08c9f063          	bgeu	s3,a2,80001528 <uvmalloc+0xa6>
    800014ac:	894e                	mv	s2,s3
    mem = kalloc();
    800014ae:	fffff097          	auipc	ra,0xfffff
    800014b2:	672080e7          	jalr	1650(ra) # 80000b20 <kalloc>
    800014b6:	84aa                	mv	s1,a0
    if(mem == 0){
    800014b8:	c51d                	beqz	a0,800014e6 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014ba:	6605                	lui	a2,0x1
    800014bc:	4581                	li	a1,0
    800014be:	00000097          	auipc	ra,0x0
    800014c2:	84e080e7          	jalr	-1970(ra) # 80000d0c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014c6:	4779                	li	a4,30
    800014c8:	86a6                	mv	a3,s1
    800014ca:	6605                	lui	a2,0x1
    800014cc:	85ca                	mv	a1,s2
    800014ce:	8556                	mv	a0,s5
    800014d0:	00000097          	auipc	ra,0x0
    800014d4:	d1a080e7          	jalr	-742(ra) # 800011ea <mappages>
    800014d8:	e905                	bnez	a0,80001508 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014da:	6785                	lui	a5,0x1
    800014dc:	993e                	add	s2,s2,a5
    800014de:	fd4968e3          	bltu	s2,s4,800014ae <uvmalloc+0x2c>
  return newsz;
    800014e2:	8552                	mv	a0,s4
    800014e4:	a809                	j	800014f6 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800014e6:	864e                	mv	a2,s3
    800014e8:	85ca                	mv	a1,s2
    800014ea:	8556                	mv	a0,s5
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	f4e080e7          	jalr	-178(ra) # 8000143a <uvmdealloc>
      return 0;
    800014f4:	4501                	li	a0,0
}
    800014f6:	70e2                	ld	ra,56(sp)
    800014f8:	7442                	ld	s0,48(sp)
    800014fa:	74a2                	ld	s1,40(sp)
    800014fc:	7902                	ld	s2,32(sp)
    800014fe:	69e2                	ld	s3,24(sp)
    80001500:	6a42                	ld	s4,16(sp)
    80001502:	6aa2                	ld	s5,8(sp)
    80001504:	6121                	addi	sp,sp,64
    80001506:	8082                	ret
      kfree(mem);
    80001508:	8526                	mv	a0,s1
    8000150a:	fffff097          	auipc	ra,0xfffff
    8000150e:	51a080e7          	jalr	1306(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001512:	864e                	mv	a2,s3
    80001514:	85ca                	mv	a1,s2
    80001516:	8556                	mv	a0,s5
    80001518:	00000097          	auipc	ra,0x0
    8000151c:	f22080e7          	jalr	-222(ra) # 8000143a <uvmdealloc>
      return 0;
    80001520:	4501                	li	a0,0
    80001522:	bfd1                	j	800014f6 <uvmalloc+0x74>
    return oldsz;
    80001524:	852e                	mv	a0,a1
}
    80001526:	8082                	ret
  return newsz;
    80001528:	8532                	mv	a0,a2
    8000152a:	b7f1                	j	800014f6 <uvmalloc+0x74>

000000008000152c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000152c:	7179                	addi	sp,sp,-48
    8000152e:	f406                	sd	ra,40(sp)
    80001530:	f022                	sd	s0,32(sp)
    80001532:	ec26                	sd	s1,24(sp)
    80001534:	e84a                	sd	s2,16(sp)
    80001536:	e44e                	sd	s3,8(sp)
    80001538:	e052                	sd	s4,0(sp)
    8000153a:	1800                	addi	s0,sp,48
    8000153c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000153e:	84aa                	mv	s1,a0
    80001540:	6905                	lui	s2,0x1
    80001542:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001544:	4985                	li	s3,1
    80001546:	a821                	j	8000155e <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001548:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000154a:	0532                	slli	a0,a0,0xc
    8000154c:	00000097          	auipc	ra,0x0
    80001550:	fe0080e7          	jalr	-32(ra) # 8000152c <freewalk>
      pagetable[i] = 0;
    80001554:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001558:	04a1                	addi	s1,s1,8
    8000155a:	03248163          	beq	s1,s2,8000157c <freewalk+0x50>
    pte_t pte = pagetable[i];
    8000155e:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001560:	00f57793          	andi	a5,a0,15
    80001564:	ff3782e3          	beq	a5,s3,80001548 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001568:	8905                	andi	a0,a0,1
    8000156a:	d57d                	beqz	a0,80001558 <freewalk+0x2c>
      panic("freewalk: leaf");
    8000156c:	00007517          	auipc	a0,0x7
    80001570:	bfc50513          	addi	a0,a0,-1028 # 80008168 <digits+0x128>
    80001574:	fffff097          	auipc	ra,0xfffff
    80001578:	fd4080e7          	jalr	-44(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    8000157c:	8552                	mv	a0,s4
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	4a6080e7          	jalr	1190(ra) # 80000a24 <kfree>
}
    80001586:	70a2                	ld	ra,40(sp)
    80001588:	7402                	ld	s0,32(sp)
    8000158a:	64e2                	ld	s1,24(sp)
    8000158c:	6942                	ld	s2,16(sp)
    8000158e:	69a2                	ld	s3,8(sp)
    80001590:	6a02                	ld	s4,0(sp)
    80001592:	6145                	addi	sp,sp,48
    80001594:	8082                	ret

0000000080001596 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001596:	1101                	addi	sp,sp,-32
    80001598:	ec06                	sd	ra,24(sp)
    8000159a:	e822                	sd	s0,16(sp)
    8000159c:	e426                	sd	s1,8(sp)
    8000159e:	1000                	addi	s0,sp,32
    800015a0:	84aa                	mv	s1,a0
  if(sz > 0)
    800015a2:	e999                	bnez	a1,800015b8 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015a4:	8526                	mv	a0,s1
    800015a6:	00000097          	auipc	ra,0x0
    800015aa:	f86080e7          	jalr	-122(ra) # 8000152c <freewalk>
}
    800015ae:	60e2                	ld	ra,24(sp)
    800015b0:	6442                	ld	s0,16(sp)
    800015b2:	64a2                	ld	s1,8(sp)
    800015b4:	6105                	addi	sp,sp,32
    800015b6:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	167d                	addi	a2,a2,-1
    800015bc:	962e                	add	a2,a2,a1
    800015be:	4685                	li	a3,1
    800015c0:	8231                	srli	a2,a2,0xc
    800015c2:	4581                	li	a1,0
    800015c4:	00000097          	auipc	ra,0x0
    800015c8:	d12080e7          	jalr	-750(ra) # 800012d6 <uvmunmap>
    800015cc:	bfe1                	j	800015a4 <uvmfree+0xe>

00000000800015ce <kvmfree>:

void
kvmfree(pagetable_t kpagetable)
{
    800015ce:	7139                	addi	sp,sp,-64
    800015d0:	fc06                	sd	ra,56(sp)
    800015d2:	f822                	sd	s0,48(sp)
    800015d4:	f426                	sd	s1,40(sp)
    800015d6:	f04a                	sd	s2,32(sp)
    800015d8:	ec4e                	sd	s3,24(sp)
    800015da:	e852                	sd	s4,16(sp)
    800015dc:	e456                	sd	s5,8(sp)
    800015de:	0080                	addi	s0,sp,64
    800015e0:	8aaa                	mv	s5,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++)
    800015e2:	84aa                	mv	s1,a0
    800015e4:	6985                	lui	s3,0x1
    800015e6:	99aa                	add	s3,s3,a0
  {
    pte_t pte = kpagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)
    800015e8:	4a05                	li	s4,1
    800015ea:	a821                	j	80001602 <kvmfree+0x34>
      // this PTE points to a lower-level page table.
      kvmfree((pagetable_t)PTE2PA(pte));
    800015ec:	8129                	srli	a0,a0,0xa
    800015ee:	0532                	slli	a0,a0,0xc
    800015f0:	00000097          	auipc	ra,0x0
    800015f4:	fde080e7          	jalr	-34(ra) # 800015ce <kvmfree>
    kpagetable[i] = 0;
    800015f8:	00093023          	sd	zero,0(s2) # 1000 <_entry-0x7ffff000>
  for(int i = 0; i < 512; i++)
    800015fc:	04a1                	addi	s1,s1,8
    800015fe:	01348963          	beq	s1,s3,80001610 <kvmfree+0x42>
    pte_t pte = kpagetable[i];
    80001602:	8926                	mv	s2,s1
    80001604:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0)
    80001606:	00f57793          	andi	a5,a0,15
    8000160a:	ff4797e3          	bne	a5,s4,800015f8 <kvmfree+0x2a>
    8000160e:	bff9                	j	800015ec <kvmfree+0x1e>
  }
  kfree((void*)kpagetable);
    80001610:	8556                	mv	a0,s5
    80001612:	fffff097          	auipc	ra,0xfffff
    80001616:	412080e7          	jalr	1042(ra) # 80000a24 <kfree>
}
    8000161a:	70e2                	ld	ra,56(sp)
    8000161c:	7442                	ld	s0,48(sp)
    8000161e:	74a2                	ld	s1,40(sp)
    80001620:	7902                	ld	s2,32(sp)
    80001622:	69e2                	ld	s3,24(sp)
    80001624:	6a42                	ld	s4,16(sp)
    80001626:	6aa2                	ld	s5,8(sp)
    80001628:	6121                	addi	sp,sp,64
    8000162a:	8082                	ret

000000008000162c <kvmcopy>:
{
    8000162c:	1101                	addi	sp,sp,-32
    8000162e:	ec06                	sd	ra,24(sp)
    80001630:	e822                	sd	s0,16(sp)
    80001632:	e426                	sd	s1,8(sp)
    80001634:	1000                	addi	s0,sp,32
    80001636:	84aa                	mv	s1,a0
  if (_kvmcopy_level(new, old, 0) < 0)
    80001638:	4601                	li	a2,0
    8000163a:	00000097          	auipc	ra,0x0
    8000163e:	9a2080e7          	jalr	-1630(ra) # 80000fdc <_kvmcopy_level>
    80001642:	00054863          	bltz	a0,80001652 <kvmcopy+0x26>
  return 0;
    80001646:	4501                	li	a0,0
}
    80001648:	60e2                	ld	ra,24(sp)
    8000164a:	6442                	ld	s0,16(sp)
    8000164c:	64a2                	ld	s1,8(sp)
    8000164e:	6105                	addi	sp,sp,32
    80001650:	8082                	ret
    kvmfree(new);
    80001652:	8526                	mv	a0,s1
    80001654:	00000097          	auipc	ra,0x0
    80001658:	f7a080e7          	jalr	-134(ra) # 800015ce <kvmfree>
    return -1;
    8000165c:	557d                	li	a0,-1
    8000165e:	b7ed                	j	80001648 <kvmcopy+0x1c>

0000000080001660 <kvminit>:
{
    80001660:	1101                	addi	sp,sp,-32
    80001662:	ec06                	sd	ra,24(sp)
    80001664:	e822                	sd	s0,16(sp)
    80001666:	e426                	sd	s1,8(sp)
    80001668:	e04a                	sd	s2,0(sp)
    8000166a:	1000                	addi	s0,sp,32
  if (kernel_pagetable)
    8000166c:	00008797          	auipc	a5,0x8
    80001670:	9a47b783          	ld	a5,-1628(a5) # 80009010 <kernel_pagetable>
    80001674:	c3a1                	beqz	a5,800016b4 <kvminit+0x54>
    pagetable_t kpagetable = (pagetable_t)kalloc();
    80001676:	fffff097          	auipc	ra,0xfffff
    8000167a:	4aa080e7          	jalr	1194(ra) # 80000b20 <kalloc>
    8000167e:	84aa                	mv	s1,a0
    if (kvmcopy(kpagetable, kernel_pagetable) < 0)
    80001680:	00008597          	auipc	a1,0x8
    80001684:	9905b583          	ld	a1,-1648(a1) # 80009010 <kernel_pagetable>
    80001688:	00000097          	auipc	ra,0x0
    8000168c:	fa4080e7          	jalr	-92(ra) # 8000162c <kvmcopy>
    80001690:	0e054663          	bltz	a0,8000177c <kvminit+0x11c>
    uvmunmap(kpagetable, CLINT, 0x10000 / PGSIZE, 0);
    80001694:	4681                	li	a3,0
    80001696:	4641                	li	a2,16
    80001698:	020005b7          	lui	a1,0x2000
    8000169c:	8526                	mv	a0,s1
    8000169e:	00000097          	auipc	ra,0x0
    800016a2:	c38080e7          	jalr	-968(ra) # 800012d6 <uvmunmap>
}
    800016a6:	8526                	mv	a0,s1
    800016a8:	60e2                	ld	ra,24(sp)
    800016aa:	6442                	ld	s0,16(sp)
    800016ac:	64a2                	ld	s1,8(sp)
    800016ae:	6902                	ld	s2,0(sp)
    800016b0:	6105                	addi	sp,sp,32
    800016b2:	8082                	ret
  kernel_pagetable = (pagetable_t) kalloc();
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	46c080e7          	jalr	1132(ra) # 80000b20 <kalloc>
    800016bc:	00008917          	auipc	s2,0x8
    800016c0:	95490913          	addi	s2,s2,-1708 # 80009010 <kernel_pagetable>
    800016c4:	00a93023          	sd	a0,0(s2)
  memset(kernel_pagetable, 0, PGSIZE);
    800016c8:	6605                	lui	a2,0x1
    800016ca:	4581                	li	a1,0
    800016cc:	fffff097          	auipc	ra,0xfffff
    800016d0:	640080e7          	jalr	1600(ra) # 80000d0c <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800016d4:	4699                	li	a3,6
    800016d6:	6605                	lui	a2,0x1
    800016d8:	100005b7          	lui	a1,0x10000
    800016dc:	10000537          	lui	a0,0x10000
    800016e0:	00000097          	auipc	ra,0x0
    800016e4:	b98080e7          	jalr	-1128(ra) # 80001278 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800016e8:	4699                	li	a3,6
    800016ea:	6605                	lui	a2,0x1
    800016ec:	100015b7          	lui	a1,0x10001
    800016f0:	10001537          	lui	a0,0x10001
    800016f4:	00000097          	auipc	ra,0x0
    800016f8:	b84080e7          	jalr	-1148(ra) # 80001278 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800016fc:	4699                	li	a3,6
    800016fe:	6641                	lui	a2,0x10
    80001700:	020005b7          	lui	a1,0x2000
    80001704:	02000537          	lui	a0,0x2000
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	b70080e7          	jalr	-1168(ra) # 80001278 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001710:	4699                	li	a3,6
    80001712:	00400637          	lui	a2,0x400
    80001716:	0c0005b7          	lui	a1,0xc000
    8000171a:	0c000537          	lui	a0,0xc000
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	b5a080e7          	jalr	-1190(ra) # 80001278 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001726:	00007497          	auipc	s1,0x7
    8000172a:	8da48493          	addi	s1,s1,-1830 # 80008000 <etext>
    8000172e:	46a9                	li	a3,10
    80001730:	80007617          	auipc	a2,0x80007
    80001734:	8d060613          	addi	a2,a2,-1840 # 8000 <_entry-0x7fff8000>
    80001738:	4585                	li	a1,1
    8000173a:	05fe                	slli	a1,a1,0x1f
    8000173c:	852e                	mv	a0,a1
    8000173e:	00000097          	auipc	ra,0x0
    80001742:	b3a080e7          	jalr	-1222(ra) # 80001278 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001746:	4699                	li	a3,6
    80001748:	4645                	li	a2,17
    8000174a:	066e                	slli	a2,a2,0x1b
    8000174c:	8e05                	sub	a2,a2,s1
    8000174e:	85a6                	mv	a1,s1
    80001750:	8526                	mv	a0,s1
    80001752:	00000097          	auipc	ra,0x0
    80001756:	b26080e7          	jalr	-1242(ra) # 80001278 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000175a:	46a9                	li	a3,10
    8000175c:	6605                	lui	a2,0x1
    8000175e:	00006597          	auipc	a1,0x6
    80001762:	8a258593          	addi	a1,a1,-1886 # 80007000 <_trampoline>
    80001766:	04000537          	lui	a0,0x4000
    8000176a:	157d                	addi	a0,a0,-1
    8000176c:	0532                	slli	a0,a0,0xc
    8000176e:	00000097          	auipc	ra,0x0
    80001772:	b0a080e7          	jalr	-1270(ra) # 80001278 <kvmmap>
  return kernel_pagetable;
    80001776:	00093483          	ld	s1,0(s2)
    8000177a:	b735                	j	800016a6 <kvminit+0x46>
      return 0;
    8000177c:	4481                	li	s1,0
    8000177e:	b725                	j	800016a6 <kvminit+0x46>

0000000080001780 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001780:	c679                	beqz	a2,8000184e <uvmcopy+0xce>
{
    80001782:	715d                	addi	sp,sp,-80
    80001784:	e486                	sd	ra,72(sp)
    80001786:	e0a2                	sd	s0,64(sp)
    80001788:	fc26                	sd	s1,56(sp)
    8000178a:	f84a                	sd	s2,48(sp)
    8000178c:	f44e                	sd	s3,40(sp)
    8000178e:	f052                	sd	s4,32(sp)
    80001790:	ec56                	sd	s5,24(sp)
    80001792:	e85a                	sd	s6,16(sp)
    80001794:	e45e                	sd	s7,8(sp)
    80001796:	0880                	addi	s0,sp,80
    80001798:	8b2a                	mv	s6,a0
    8000179a:	8aae                	mv	s5,a1
    8000179c:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    8000179e:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800017a0:	4601                	li	a2,0
    800017a2:	85ce                	mv	a1,s3
    800017a4:	855a                	mv	a0,s6
    800017a6:	00000097          	auipc	ra,0x0
    800017aa:	8f6080e7          	jalr	-1802(ra) # 8000109c <walk>
    800017ae:	c531                	beqz	a0,800017fa <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800017b0:	6118                	ld	a4,0(a0)
    800017b2:	00177793          	andi	a5,a4,1
    800017b6:	cbb1                	beqz	a5,8000180a <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800017b8:	00a75593          	srli	a1,a4,0xa
    800017bc:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800017c0:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800017c4:	fffff097          	auipc	ra,0xfffff
    800017c8:	35c080e7          	jalr	860(ra) # 80000b20 <kalloc>
    800017cc:	892a                	mv	s2,a0
    800017ce:	c939                	beqz	a0,80001824 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800017d0:	6605                	lui	a2,0x1
    800017d2:	85de                	mv	a1,s7
    800017d4:	fffff097          	auipc	ra,0xfffff
    800017d8:	598080e7          	jalr	1432(ra) # 80000d6c <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800017dc:	8726                	mv	a4,s1
    800017de:	86ca                	mv	a3,s2
    800017e0:	6605                	lui	a2,0x1
    800017e2:	85ce                	mv	a1,s3
    800017e4:	8556                	mv	a0,s5
    800017e6:	00000097          	auipc	ra,0x0
    800017ea:	a04080e7          	jalr	-1532(ra) # 800011ea <mappages>
    800017ee:	e515                	bnez	a0,8000181a <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800017f0:	6785                	lui	a5,0x1
    800017f2:	99be                	add	s3,s3,a5
    800017f4:	fb49e6e3          	bltu	s3,s4,800017a0 <uvmcopy+0x20>
    800017f8:	a081                	j	80001838 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800017fa:	00007517          	auipc	a0,0x7
    800017fe:	97e50513          	addi	a0,a0,-1666 # 80008178 <digits+0x138>
    80001802:	fffff097          	auipc	ra,0xfffff
    80001806:	d46080e7          	jalr	-698(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000180a:	00007517          	auipc	a0,0x7
    8000180e:	98e50513          	addi	a0,a0,-1650 # 80008198 <digits+0x158>
    80001812:	fffff097          	auipc	ra,0xfffff
    80001816:	d36080e7          	jalr	-714(ra) # 80000548 <panic>
      kfree(mem);
    8000181a:	854a                	mv	a0,s2
    8000181c:	fffff097          	auipc	ra,0xfffff
    80001820:	208080e7          	jalr	520(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001824:	4685                	li	a3,1
    80001826:	00c9d613          	srli	a2,s3,0xc
    8000182a:	4581                	li	a1,0
    8000182c:	8556                	mv	a0,s5
    8000182e:	00000097          	auipc	ra,0x0
    80001832:	aa8080e7          	jalr	-1368(ra) # 800012d6 <uvmunmap>
  return -1;
    80001836:	557d                	li	a0,-1
}
    80001838:	60a6                	ld	ra,72(sp)
    8000183a:	6406                	ld	s0,64(sp)
    8000183c:	74e2                	ld	s1,56(sp)
    8000183e:	7942                	ld	s2,48(sp)
    80001840:	79a2                	ld	s3,40(sp)
    80001842:	7a02                	ld	s4,32(sp)
    80001844:	6ae2                	ld	s5,24(sp)
    80001846:	6b42                	ld	s6,16(sp)
    80001848:	6ba2                	ld	s7,8(sp)
    8000184a:	6161                	addi	sp,sp,80
    8000184c:	8082                	ret
  return 0;
    8000184e:	4501                	li	a0,0
}
    80001850:	8082                	ret

0000000080001852 <u2kcopy>:

// copying from user pagetable to kernel pagetable
int
u2kcopy(pagetable_t pagetable, pagetable_t kpagetable, uint64 oldsz, uint64 newsz)
{
    80001852:	715d                	addi	sp,sp,-80
    80001854:	e486                	sd	ra,72(sp)
    80001856:	e0a2                	sd	s0,64(sp)
    80001858:	fc26                	sd	s1,56(sp)
    8000185a:	f84a                	sd	s2,48(sp)
    8000185c:	f44e                	sd	s3,40(sp)
    8000185e:	f052                	sd	s4,32(sp)
    80001860:	ec56                	sd	s5,24(sp)
    80001862:	e85a                	sd	s6,16(sp)
    80001864:	e45e                	sd	s7,8(sp)
    80001866:	0880                	addi	s0,sp,80
  pte_t *from, *to;
  uint64 pa, i;
  uint flags;

  oldsz = PGROUNDUP(oldsz);
    80001868:	6785                	lui	a5,0x1
    8000186a:	17fd                	addi	a5,a5,-1
    8000186c:	963e                	add	a2,a2,a5
    8000186e:	79fd                	lui	s3,0xfffff
    80001870:	013674b3          	and	s1,a2,s3
  newsz = PGROUNDUP(newsz);
    80001874:	96be                	add	a3,a3,a5
    80001876:	0136f9b3          	and	s3,a3,s3

  if (newsz >= PLIC)
    8000187a:	0c0007b7          	lui	a5,0xc000
    8000187e:	04f9fe63          	bgeu	s3,a5,800018da <u2kcopy+0x88>
    80001882:	8a2a                	mv	s4,a0
    80001884:	8aae                	mv	s5,a1
    return -1;

  for(i = oldsz; i < newsz; i += PGSIZE)
    80001886:	0534fc63          	bgeu	s1,s3,800018de <u2kcopy+0x8c>
      panic("u2kcopy");
    if ((to = walk(kpagetable, i, 1)) == 0)
      return -1;
    pa = PTE2PA(*from);
    flags = PTE_FLAGS(*from) & (~PTE_U);
    *to = PA2PTE(pa) | flags;
    8000188a:	7b7d                	lui	s6,0xfffff
    8000188c:	002b5b13          	srli	s6,s6,0x2
  for(i = oldsz; i < newsz; i += PGSIZE)
    80001890:	6b85                	lui	s7,0x1
    if ((from = walk(pagetable, i, 0)) == 0)
    80001892:	4601                	li	a2,0
    80001894:	85a6                	mv	a1,s1
    80001896:	8552                	mv	a0,s4
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	804080e7          	jalr	-2044(ra) # 8000109c <walk>
    800018a0:	892a                	mv	s2,a0
    800018a2:	c505                	beqz	a0,800018ca <u2kcopy+0x78>
    if ((to = walk(kpagetable, i, 1)) == 0)
    800018a4:	4605                	li	a2,1
    800018a6:	85a6                	mv	a1,s1
    800018a8:	8556                	mv	a0,s5
    800018aa:	fffff097          	auipc	ra,0xfffff
    800018ae:	7f2080e7          	jalr	2034(ra) # 8000109c <walk>
    800018b2:	c905                	beqz	a0,800018e2 <u2kcopy+0x90>
    pa = PTE2PA(*from);
    800018b4:	00093703          	ld	a4,0(s2)
    *to = PA2PTE(pa) | flags;
    800018b8:	3efb6793          	ori	a5,s6,1007
    800018bc:	8ff9                	and	a5,a5,a4
    800018be:	e11c                	sd	a5,0(a0)
  for(i = oldsz; i < newsz; i += PGSIZE)
    800018c0:	94de                	add	s1,s1,s7
    800018c2:	fd34e8e3          	bltu	s1,s3,80001892 <u2kcopy+0x40>
  }
  return 0;
    800018c6:	4501                	li	a0,0
    800018c8:	a831                	j	800018e4 <u2kcopy+0x92>
      panic("u2kcopy");
    800018ca:	00007517          	auipc	a0,0x7
    800018ce:	8ee50513          	addi	a0,a0,-1810 # 800081b8 <digits+0x178>
    800018d2:	fffff097          	auipc	ra,0xfffff
    800018d6:	c76080e7          	jalr	-906(ra) # 80000548 <panic>
    return -1;
    800018da:	557d                	li	a0,-1
    800018dc:	a021                	j	800018e4 <u2kcopy+0x92>
  return 0;
    800018de:	4501                	li	a0,0
    800018e0:	a011                	j	800018e4 <u2kcopy+0x92>
      return -1;
    800018e2:	557d                	li	a0,-1
}
    800018e4:	60a6                	ld	ra,72(sp)
    800018e6:	6406                	ld	s0,64(sp)
    800018e8:	74e2                	ld	s1,56(sp)
    800018ea:	7942                	ld	s2,48(sp)
    800018ec:	79a2                	ld	s3,40(sp)
    800018ee:	7a02                	ld	s4,32(sp)
    800018f0:	6ae2                	ld	s5,24(sp)
    800018f2:	6b42                	ld	s6,16(sp)
    800018f4:	6ba2                	ld	s7,8(sp)
    800018f6:	6161                	addi	sp,sp,80
    800018f8:	8082                	ret

00000000800018fa <uvmclear>:
// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800018fa:	1141                	addi	sp,sp,-16
    800018fc:	e406                	sd	ra,8(sp)
    800018fe:	e022                	sd	s0,0(sp)
    80001900:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001902:	4601                	li	a2,0
    80001904:	fffff097          	auipc	ra,0xfffff
    80001908:	798080e7          	jalr	1944(ra) # 8000109c <walk>
  if(pte == 0)
    8000190c:	c901                	beqz	a0,8000191c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000190e:	611c                	ld	a5,0(a0)
    80001910:	9bbd                	andi	a5,a5,-17
    80001912:	e11c                	sd	a5,0(a0)
}
    80001914:	60a2                	ld	ra,8(sp)
    80001916:	6402                	ld	s0,0(sp)
    80001918:	0141                	addi	sp,sp,16
    8000191a:	8082                	ret
    panic("uvmclear");
    8000191c:	00007517          	auipc	a0,0x7
    80001920:	8a450513          	addi	a0,a0,-1884 # 800081c0 <digits+0x180>
    80001924:	fffff097          	auipc	ra,0xfffff
    80001928:	c24080e7          	jalr	-988(ra) # 80000548 <panic>

000000008000192c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000192c:	c6bd                	beqz	a3,8000199a <copyout+0x6e>
{
    8000192e:	715d                	addi	sp,sp,-80
    80001930:	e486                	sd	ra,72(sp)
    80001932:	e0a2                	sd	s0,64(sp)
    80001934:	fc26                	sd	s1,56(sp)
    80001936:	f84a                	sd	s2,48(sp)
    80001938:	f44e                	sd	s3,40(sp)
    8000193a:	f052                	sd	s4,32(sp)
    8000193c:	ec56                	sd	s5,24(sp)
    8000193e:	e85a                	sd	s6,16(sp)
    80001940:	e45e                	sd	s7,8(sp)
    80001942:	e062                	sd	s8,0(sp)
    80001944:	0880                	addi	s0,sp,80
    80001946:	8b2a                	mv	s6,a0
    80001948:	8c2e                	mv	s8,a1
    8000194a:	8a32                	mv	s4,a2
    8000194c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000194e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001950:	6a85                	lui	s5,0x1
    80001952:	a015                	j	80001976 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001954:	9562                	add	a0,a0,s8
    80001956:	0004861b          	sext.w	a2,s1
    8000195a:	85d2                	mv	a1,s4
    8000195c:	41250533          	sub	a0,a0,s2
    80001960:	fffff097          	auipc	ra,0xfffff
    80001964:	40c080e7          	jalr	1036(ra) # 80000d6c <memmove>

    len -= n;
    80001968:	409989b3          	sub	s3,s3,s1
    src += n;
    8000196c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000196e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001972:	02098263          	beqz	s3,80001996 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001976:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000197a:	85ca                	mv	a1,s2
    8000197c:	855a                	mv	a0,s6
    8000197e:	fffff097          	auipc	ra,0xfffff
    80001982:	7c4080e7          	jalr	1988(ra) # 80001142 <walkaddr>
    if(pa0 == 0)
    80001986:	cd01                	beqz	a0,8000199e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001988:	418904b3          	sub	s1,s2,s8
    8000198c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000198e:	fc99f3e3          	bgeu	s3,s1,80001954 <copyout+0x28>
    80001992:	84ce                	mv	s1,s3
    80001994:	b7c1                	j	80001954 <copyout+0x28>
  }
  return 0;
    80001996:	4501                	li	a0,0
    80001998:	a021                	j	800019a0 <copyout+0x74>
    8000199a:	4501                	li	a0,0
}
    8000199c:	8082                	ret
      return -1;
    8000199e:	557d                	li	a0,-1
}
    800019a0:	60a6                	ld	ra,72(sp)
    800019a2:	6406                	ld	s0,64(sp)
    800019a4:	74e2                	ld	s1,56(sp)
    800019a6:	7942                	ld	s2,48(sp)
    800019a8:	79a2                	ld	s3,40(sp)
    800019aa:	7a02                	ld	s4,32(sp)
    800019ac:	6ae2                	ld	s5,24(sp)
    800019ae:	6b42                	ld	s6,16(sp)
    800019b0:	6ba2                	ld	s7,8(sp)
    800019b2:	6c02                	ld	s8,0(sp)
    800019b4:	6161                	addi	sp,sp,80
    800019b6:	8082                	ret

00000000800019b8 <copyin>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800019b8:	1141                	addi	sp,sp,-16
    800019ba:	e406                	sd	ra,8(sp)
    800019bc:	e022                	sd	s0,0(sp)
    800019be:	0800                	addi	s0,sp,16
  return copyin_new(pagetable, dst, srcva, len);
    800019c0:	00005097          	auipc	ra,0x5
    800019c4:	c20080e7          	jalr	-992(ra) # 800065e0 <copyin_new>
}
    800019c8:	60a2                	ld	ra,8(sp)
    800019ca:	6402                	ld	s0,0(sp)
    800019cc:	0141                	addi	sp,sp,16
    800019ce:	8082                	ret

00000000800019d0 <copyinstr>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    800019d0:	1141                	addi	sp,sp,-16
    800019d2:	e406                	sd	ra,8(sp)
    800019d4:	e022                	sd	s0,0(sp)
    800019d6:	0800                	addi	s0,sp,16
  return copyinstr_new(pagetable, dst, srcva, max);
    800019d8:	00005097          	auipc	ra,0x5
    800019dc:	c70080e7          	jalr	-912(ra) # 80006648 <copyinstr_new>
}
    800019e0:	60a2                	ld	ra,8(sp)
    800019e2:	6402                	ld	s0,0(sp)
    800019e4:	0141                	addi	sp,sp,16
    800019e6:	8082                	ret

00000000800019e8 <vmprint_level>:

void
vmprint_level(pagetable_t pagetable, int level)
{
    800019e8:	7159                	addi	sp,sp,-112
    800019ea:	f486                	sd	ra,104(sp)
    800019ec:	f0a2                	sd	s0,96(sp)
    800019ee:	eca6                	sd	s1,88(sp)
    800019f0:	e8ca                	sd	s2,80(sp)
    800019f2:	e4ce                	sd	s3,72(sp)
    800019f4:	e0d2                	sd	s4,64(sp)
    800019f6:	fc56                	sd	s5,56(sp)
    800019f8:	f85a                	sd	s6,48(sp)
    800019fa:	f45e                	sd	s7,40(sp)
    800019fc:	f062                	sd	s8,32(sp)
    800019fe:	ec66                	sd	s9,24(sp)
    80001a00:	e86a                	sd	s10,16(sp)
    80001a02:	e46e                	sd	s11,8(sp)
    80001a04:	1880                	addi	s0,sp,112
    80001a06:	8aae                	mv	s5,a1
  int i, j;
  pte_t pte;

  for (i = 0; i < 512; i++)
    80001a08:	89aa                	mv	s3,a0
    80001a0a:	4901                	li	s2,0
  {
    pte = pagetable[i];
    if (pte & PTE_V)
    {
      printf("..");
    80001a0c:	00006d17          	auipc	s10,0x6
    80001a10:	7c4d0d13          	addi	s10,s10,1988 # 800081d0 <digits+0x190>
      for (j = 0; j < level; j++)
        printf(" ..");
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001a14:	00006c97          	auipc	s9,0x6
    80001a18:	7ccc8c93          	addi	s9,s9,1996 # 800081e0 <digits+0x1a0>
      if (level + 1 <= 2)
    80001a1c:	4c05                	li	s8,1
        vmprint_level((pagetable_t)PTE2PA(pte), level + 1);
    80001a1e:	00158d9b          	addiw	s11,a1,1
        printf(" ..");
    80001a22:	00006b17          	auipc	s6,0x6
    80001a26:	7b6b0b13          	addi	s6,s6,1974 # 800081d8 <digits+0x198>
  for (i = 0; i < 512; i++)
    80001a2a:	20000b93          	li	s7,512
    80001a2e:	a029                	j	80001a38 <vmprint_level+0x50>
    80001a30:	2905                	addiw	s2,s2,1
    80001a32:	09a1                	addi	s3,s3,8
    80001a34:	05790b63          	beq	s2,s7,80001a8a <vmprint_level+0xa2>
    pte = pagetable[i];
    80001a38:	0009ba03          	ld	s4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    if (pte & PTE_V)
    80001a3c:	001a7793          	andi	a5,s4,1
    80001a40:	dbe5                	beqz	a5,80001a30 <vmprint_level+0x48>
      printf("..");
    80001a42:	856a                	mv	a0,s10
    80001a44:	fffff097          	auipc	ra,0xfffff
    80001a48:	b4e080e7          	jalr	-1202(ra) # 80000592 <printf>
      for (j = 0; j < level; j++)
    80001a4c:	01505b63          	blez	s5,80001a62 <vmprint_level+0x7a>
    80001a50:	4481                	li	s1,0
        printf(" ..");
    80001a52:	855a                	mv	a0,s6
    80001a54:	fffff097          	auipc	ra,0xfffff
    80001a58:	b3e080e7          	jalr	-1218(ra) # 80000592 <printf>
      for (j = 0; j < level; j++)
    80001a5c:	2485                	addiw	s1,s1,1
    80001a5e:	fe9a9ae3          	bne	s5,s1,80001a52 <vmprint_level+0x6a>
      printf("%d: pte %p pa %p\n", i, pte, PTE2PA(pte));
    80001a62:	00aa5493          	srli	s1,s4,0xa
    80001a66:	04b2                	slli	s1,s1,0xc
    80001a68:	86a6                	mv	a3,s1
    80001a6a:	8652                	mv	a2,s4
    80001a6c:	85ca                	mv	a1,s2
    80001a6e:	8566                	mv	a0,s9
    80001a70:	fffff097          	auipc	ra,0xfffff
    80001a74:	b22080e7          	jalr	-1246(ra) # 80000592 <printf>
      if (level + 1 <= 2)
    80001a78:	fb5c4ce3          	blt	s8,s5,80001a30 <vmprint_level+0x48>
        vmprint_level((pagetable_t)PTE2PA(pte), level + 1);
    80001a7c:	85ee                	mv	a1,s11
    80001a7e:	8526                	mv	a0,s1
    80001a80:	00000097          	auipc	ra,0x0
    80001a84:	f68080e7          	jalr	-152(ra) # 800019e8 <vmprint_level>
    80001a88:	b765                	j	80001a30 <vmprint_level+0x48>
    }
  }
}
    80001a8a:	70a6                	ld	ra,104(sp)
    80001a8c:	7406                	ld	s0,96(sp)
    80001a8e:	64e6                	ld	s1,88(sp)
    80001a90:	6946                	ld	s2,80(sp)
    80001a92:	69a6                	ld	s3,72(sp)
    80001a94:	6a06                	ld	s4,64(sp)
    80001a96:	7ae2                	ld	s5,56(sp)
    80001a98:	7b42                	ld	s6,48(sp)
    80001a9a:	7ba2                	ld	s7,40(sp)
    80001a9c:	7c02                	ld	s8,32(sp)
    80001a9e:	6ce2                	ld	s9,24(sp)
    80001aa0:	6d42                	ld	s10,16(sp)
    80001aa2:	6da2                	ld	s11,8(sp)
    80001aa4:	6165                	addi	sp,sp,112
    80001aa6:	8082                	ret

0000000080001aa8 <vmprint>:

void 
vmprint(pagetable_t pagetable)
{
    80001aa8:	1101                	addi	sp,sp,-32
    80001aaa:	ec06                	sd	ra,24(sp)
    80001aac:	e822                	sd	s0,16(sp)
    80001aae:	e426                	sd	s1,8(sp)
    80001ab0:	1000                	addi	s0,sp,32
    80001ab2:	84aa                	mv	s1,a0
  printf("page table %p\n", pagetable);
    80001ab4:	85aa                	mv	a1,a0
    80001ab6:	00006517          	auipc	a0,0x6
    80001aba:	74250513          	addi	a0,a0,1858 # 800081f8 <digits+0x1b8>
    80001abe:	fffff097          	auipc	ra,0xfffff
    80001ac2:	ad4080e7          	jalr	-1324(ra) # 80000592 <printf>
  vmprint_level(pagetable, 0);
    80001ac6:	4581                	li	a1,0
    80001ac8:	8526                	mv	a0,s1
    80001aca:	00000097          	auipc	ra,0x0
    80001ace:	f1e080e7          	jalr	-226(ra) # 800019e8 <vmprint_level>
    80001ad2:	60e2                	ld	ra,24(sp)
    80001ad4:	6442                	ld	s0,16(sp)
    80001ad6:	64a2                	ld	s1,8(sp)
    80001ad8:	6105                	addi	sp,sp,32
    80001ada:	8082                	ret

0000000080001adc <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001adc:	1101                	addi	sp,sp,-32
    80001ade:	ec06                	sd	ra,24(sp)
    80001ae0:	e822                	sd	s0,16(sp)
    80001ae2:	e426                	sd	s1,8(sp)
    80001ae4:	1000                	addi	s0,sp,32
    80001ae6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	0ae080e7          	jalr	174(ra) # 80000b96 <holding>
    80001af0:	c909                	beqz	a0,80001b02 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001af2:	749c                	ld	a5,40(s1)
    80001af4:	00978f63          	beq	a5,s1,80001b12 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001af8:	60e2                	ld	ra,24(sp)
    80001afa:	6442                	ld	s0,16(sp)
    80001afc:	64a2                	ld	s1,8(sp)
    80001afe:	6105                	addi	sp,sp,32
    80001b00:	8082                	ret
    panic("wakeup1");
    80001b02:	00006517          	auipc	a0,0x6
    80001b06:	70650513          	addi	a0,a0,1798 # 80008208 <digits+0x1c8>
    80001b0a:	fffff097          	auipc	ra,0xfffff
    80001b0e:	a3e080e7          	jalr	-1474(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001b12:	4c98                	lw	a4,24(s1)
    80001b14:	4785                	li	a5,1
    80001b16:	fef711e3          	bne	a4,a5,80001af8 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001b1a:	4789                	li	a5,2
    80001b1c:	cc9c                	sw	a5,24(s1)
}
    80001b1e:	bfe9                	j	80001af8 <wakeup1+0x1c>

0000000080001b20 <procinit>:
{
    80001b20:	7179                	addi	sp,sp,-48
    80001b22:	f406                	sd	ra,40(sp)
    80001b24:	f022                	sd	s0,32(sp)
    80001b26:	ec26                	sd	s1,24(sp)
    80001b28:	e84a                	sd	s2,16(sp)
    80001b2a:	e44e                	sd	s3,8(sp)
    80001b2c:	1800                	addi	s0,sp,48
  initlock(&pid_lock, "nextpid");
    80001b2e:	00006597          	auipc	a1,0x6
    80001b32:	6e258593          	addi	a1,a1,1762 # 80008210 <digits+0x1d0>
    80001b36:	00010517          	auipc	a0,0x10
    80001b3a:	e1a50513          	addi	a0,a0,-486 # 80011950 <pid_lock>
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	042080e7          	jalr	66(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b46:	00010497          	auipc	s1,0x10
    80001b4a:	22248493          	addi	s1,s1,546 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    80001b4e:	00006997          	auipc	s3,0x6
    80001b52:	6ca98993          	addi	s3,s3,1738 # 80008218 <digits+0x1d8>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b56:	00016917          	auipc	s2,0x16
    80001b5a:	e1290913          	addi	s2,s2,-494 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    80001b5e:	85ce                	mv	a1,s3
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	01e080e7          	jalr	30(ra) # 80000b80 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b6a:	17048493          	addi	s1,s1,368
    80001b6e:	ff2498e3          	bne	s1,s2,80001b5e <procinit+0x3e>
  kvminithart();
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	506080e7          	jalr	1286(ra) # 80001078 <kvminithart>
}
    80001b7a:	70a2                	ld	ra,40(sp)
    80001b7c:	7402                	ld	s0,32(sp)
    80001b7e:	64e2                	ld	s1,24(sp)
    80001b80:	6942                	ld	s2,16(sp)
    80001b82:	69a2                	ld	s3,8(sp)
    80001b84:	6145                	addi	sp,sp,48
    80001b86:	8082                	ret

0000000080001b88 <cpuid>:
{
    80001b88:	1141                	addi	sp,sp,-16
    80001b8a:	e422                	sd	s0,8(sp)
    80001b8c:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001b8e:	8512                	mv	a0,tp
}
    80001b90:	2501                	sext.w	a0,a0
    80001b92:	6422                	ld	s0,8(sp)
    80001b94:	0141                	addi	sp,sp,16
    80001b96:	8082                	ret

0000000080001b98 <mycpu>:
mycpu(void) {
    80001b98:	1141                	addi	sp,sp,-16
    80001b9a:	e422                	sd	s0,8(sp)
    80001b9c:	0800                	addi	s0,sp,16
    80001b9e:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001ba0:	2781                	sext.w	a5,a5
    80001ba2:	079e                	slli	a5,a5,0x7
}
    80001ba4:	00010517          	auipc	a0,0x10
    80001ba8:	dc450513          	addi	a0,a0,-572 # 80011968 <cpus>
    80001bac:	953e                	add	a0,a0,a5
    80001bae:	6422                	ld	s0,8(sp)
    80001bb0:	0141                	addi	sp,sp,16
    80001bb2:	8082                	ret

0000000080001bb4 <myproc>:
myproc(void) {
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
  push_off();
    80001bbe:	fffff097          	auipc	ra,0xfffff
    80001bc2:	006080e7          	jalr	6(ra) # 80000bc4 <push_off>
    80001bc6:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001bc8:	2781                	sext.w	a5,a5
    80001bca:	079e                	slli	a5,a5,0x7
    80001bcc:	00010717          	auipc	a4,0x10
    80001bd0:	d8470713          	addi	a4,a4,-636 # 80011950 <pid_lock>
    80001bd4:	97ba                	add	a5,a5,a4
    80001bd6:	6f84                	ld	s1,24(a5)
  pop_off();
    80001bd8:	fffff097          	auipc	ra,0xfffff
    80001bdc:	08c080e7          	jalr	140(ra) # 80000c64 <pop_off>
}
    80001be0:	8526                	mv	a0,s1
    80001be2:	60e2                	ld	ra,24(sp)
    80001be4:	6442                	ld	s0,16(sp)
    80001be6:	64a2                	ld	s1,8(sp)
    80001be8:	6105                	addi	sp,sp,32
    80001bea:	8082                	ret

0000000080001bec <forkret>:
{
    80001bec:	1141                	addi	sp,sp,-16
    80001bee:	e406                	sd	ra,8(sp)
    80001bf0:	e022                	sd	s0,0(sp)
    80001bf2:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001bf4:	00000097          	auipc	ra,0x0
    80001bf8:	fc0080e7          	jalr	-64(ra) # 80001bb4 <myproc>
    80001bfc:	fffff097          	auipc	ra,0xfffff
    80001c00:	0c8080e7          	jalr	200(ra) # 80000cc4 <release>
  if (first) {
    80001c04:	00007797          	auipc	a5,0x7
    80001c08:	c8c7a783          	lw	a5,-884(a5) # 80008890 <first.1698>
    80001c0c:	eb89                	bnez	a5,80001c1e <forkret+0x32>
  usertrapret();
    80001c0e:	00001097          	auipc	ra,0x1
    80001c12:	df0080e7          	jalr	-528(ra) # 800029fe <usertrapret>
}
    80001c16:	60a2                	ld	ra,8(sp)
    80001c18:	6402                	ld	s0,0(sp)
    80001c1a:	0141                	addi	sp,sp,16
    80001c1c:	8082                	ret
    first = 0;
    80001c1e:	00007797          	auipc	a5,0x7
    80001c22:	c607a923          	sw	zero,-910(a5) # 80008890 <first.1698>
    fsinit(ROOTDEV);
    80001c26:	4505                	li	a0,1
    80001c28:	00002097          	auipc	ra,0x2
    80001c2c:	b18080e7          	jalr	-1256(ra) # 80003740 <fsinit>
    80001c30:	bff9                	j	80001c0e <forkret+0x22>

0000000080001c32 <allocpid>:
allocpid() {
    80001c32:	1101                	addi	sp,sp,-32
    80001c34:	ec06                	sd	ra,24(sp)
    80001c36:	e822                	sd	s0,16(sp)
    80001c38:	e426                	sd	s1,8(sp)
    80001c3a:	e04a                	sd	s2,0(sp)
    80001c3c:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001c3e:	00010917          	auipc	s2,0x10
    80001c42:	d1290913          	addi	s2,s2,-750 # 80011950 <pid_lock>
    80001c46:	854a                	mv	a0,s2
    80001c48:	fffff097          	auipc	ra,0xfffff
    80001c4c:	fc8080e7          	jalr	-56(ra) # 80000c10 <acquire>
  pid = nextpid;
    80001c50:	00007797          	auipc	a5,0x7
    80001c54:	c4478793          	addi	a5,a5,-956 # 80008894 <nextpid>
    80001c58:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001c5a:	0014871b          	addiw	a4,s1,1
    80001c5e:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001c60:	854a                	mv	a0,s2
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	062080e7          	jalr	98(ra) # 80000cc4 <release>
}
    80001c6a:	8526                	mv	a0,s1
    80001c6c:	60e2                	ld	ra,24(sp)
    80001c6e:	6442                	ld	s0,16(sp)
    80001c70:	64a2                	ld	s1,8(sp)
    80001c72:	6902                	ld	s2,0(sp)
    80001c74:	6105                	addi	sp,sp,32
    80001c76:	8082                	ret

0000000080001c78 <proc_pagetable>:
{
    80001c78:	1101                	addi	sp,sp,-32
    80001c7a:	ec06                	sd	ra,24(sp)
    80001c7c:	e822                	sd	s0,16(sp)
    80001c7e:	e426                	sd	s1,8(sp)
    80001c80:	e04a                	sd	s2,0(sp)
    80001c82:	1000                	addi	s0,sp,32
    80001c84:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	714080e7          	jalr	1812(ra) # 8000139a <uvmcreate>
    80001c8e:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001c90:	c121                	beqz	a0,80001cd0 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001c92:	4729                	li	a4,10
    80001c94:	00005697          	auipc	a3,0x5
    80001c98:	36c68693          	addi	a3,a3,876 # 80007000 <_trampoline>
    80001c9c:	6605                	lui	a2,0x1
    80001c9e:	040005b7          	lui	a1,0x4000
    80001ca2:	15fd                	addi	a1,a1,-1
    80001ca4:	05b2                	slli	a1,a1,0xc
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	544080e7          	jalr	1348(ra) # 800011ea <mappages>
    80001cae:	02054863          	bltz	a0,80001cde <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001cb2:	4719                	li	a4,6
    80001cb4:	06093683          	ld	a3,96(s2)
    80001cb8:	6605                	lui	a2,0x1
    80001cba:	020005b7          	lui	a1,0x2000
    80001cbe:	15fd                	addi	a1,a1,-1
    80001cc0:	05b6                	slli	a1,a1,0xd
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	526080e7          	jalr	1318(ra) # 800011ea <mappages>
    80001ccc:	02054163          	bltz	a0,80001cee <proc_pagetable+0x76>
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret
    uvmfree(pagetable, 0);
    80001cde:	4581                	li	a1,0
    80001ce0:	8526                	mv	a0,s1
    80001ce2:	00000097          	auipc	ra,0x0
    80001ce6:	8b4080e7          	jalr	-1868(ra) # 80001596 <uvmfree>
    return 0;
    80001cea:	4481                	li	s1,0
    80001cec:	b7d5                	j	80001cd0 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001cee:	4681                	li	a3,0
    80001cf0:	4605                	li	a2,1
    80001cf2:	040005b7          	lui	a1,0x4000
    80001cf6:	15fd                	addi	a1,a1,-1
    80001cf8:	05b2                	slli	a1,a1,0xc
    80001cfa:	8526                	mv	a0,s1
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	5da080e7          	jalr	1498(ra) # 800012d6 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d04:	4581                	li	a1,0
    80001d06:	8526                	mv	a0,s1
    80001d08:	00000097          	auipc	ra,0x0
    80001d0c:	88e080e7          	jalr	-1906(ra) # 80001596 <uvmfree>
    return 0;
    80001d10:	4481                	li	s1,0
    80001d12:	bf7d                	j	80001cd0 <proc_pagetable+0x58>

0000000080001d14 <proc_freepagetable>:
{
    80001d14:	1101                	addi	sp,sp,-32
    80001d16:	ec06                	sd	ra,24(sp)
    80001d18:	e822                	sd	s0,16(sp)
    80001d1a:	e426                	sd	s1,8(sp)
    80001d1c:	e04a                	sd	s2,0(sp)
    80001d1e:	1000                	addi	s0,sp,32
    80001d20:	84aa                	mv	s1,a0
    80001d22:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d24:	4681                	li	a3,0
    80001d26:	4605                	li	a2,1
    80001d28:	040005b7          	lui	a1,0x4000
    80001d2c:	15fd                	addi	a1,a1,-1
    80001d2e:	05b2                	slli	a1,a1,0xc
    80001d30:	fffff097          	auipc	ra,0xfffff
    80001d34:	5a6080e7          	jalr	1446(ra) # 800012d6 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d38:	4681                	li	a3,0
    80001d3a:	4605                	li	a2,1
    80001d3c:	020005b7          	lui	a1,0x2000
    80001d40:	15fd                	addi	a1,a1,-1
    80001d42:	05b6                	slli	a1,a1,0xd
    80001d44:	8526                	mv	a0,s1
    80001d46:	fffff097          	auipc	ra,0xfffff
    80001d4a:	590080e7          	jalr	1424(ra) # 800012d6 <uvmunmap>
  uvmfree(pagetable, sz);
    80001d4e:	85ca                	mv	a1,s2
    80001d50:	8526                	mv	a0,s1
    80001d52:	00000097          	auipc	ra,0x0
    80001d56:	844080e7          	jalr	-1980(ra) # 80001596 <uvmfree>
}
    80001d5a:	60e2                	ld	ra,24(sp)
    80001d5c:	6442                	ld	s0,16(sp)
    80001d5e:	64a2                	ld	s1,8(sp)
    80001d60:	6902                	ld	s2,0(sp)
    80001d62:	6105                	addi	sp,sp,32
    80001d64:	8082                	ret

0000000080001d66 <freeproc>:
{
    80001d66:	1101                	addi	sp,sp,-32
    80001d68:	ec06                	sd	ra,24(sp)
    80001d6a:	e822                	sd	s0,16(sp)
    80001d6c:	e426                	sd	s1,8(sp)
    80001d6e:	1000                	addi	s0,sp,32
    80001d70:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001d72:	7128                	ld	a0,96(a0)
    80001d74:	c509                	beqz	a0,80001d7e <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001d76:	fffff097          	auipc	ra,0xfffff
    80001d7a:	cae080e7          	jalr	-850(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001d7e:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001d82:	68a8                	ld	a0,80(s1)
    80001d84:	c511                	beqz	a0,80001d90 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001d86:	64ac                	ld	a1,72(s1)
    80001d88:	00000097          	auipc	ra,0x0
    80001d8c:	f8c080e7          	jalr	-116(ra) # 80001d14 <proc_freepagetable>
  p->pagetable = 0;
    80001d90:	0404b823          	sd	zero,80(s1)
  if (p->kstack)
    80001d94:	60ac                	ld	a1,64(s1)
    80001d96:	e1a1                	bnez	a1,80001dd6 <freeproc+0x70>
  if (p->kpagetable)
    80001d98:	6ca8                	ld	a0,88(s1)
    80001d9a:	c509                	beqz	a0,80001da4 <freeproc+0x3e>
    kvmfree(p->kpagetable);
    80001d9c:	00000097          	auipc	ra,0x0
    80001da0:	832080e7          	jalr	-1998(ra) # 800015ce <kvmfree>
  p->pagetable = 0;
    80001da4:	0404b823          	sd	zero,80(s1)
  p->kpagetable = 0;
    80001da8:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001dac:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001db0:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001db4:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001db8:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001dbc:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001dc0:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001dc4:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001dc8:	0004ac23          	sw	zero,24(s1)
}
    80001dcc:	60e2                	ld	ra,24(sp)
    80001dce:	6442                	ld	s0,16(sp)
    80001dd0:	64a2                	ld	s1,8(sp)
    80001dd2:	6105                	addi	sp,sp,32
    80001dd4:	8082                	ret
    pte_t *pte = walk(p->kpagetable, p->kstack, 0);
    80001dd6:	4601                	li	a2,0
    80001dd8:	6ca8                	ld	a0,88(s1)
    80001dda:	fffff097          	auipc	ra,0xfffff
    80001dde:	2c2080e7          	jalr	706(ra) # 8000109c <walk>
    if (pte == 0 || (*pte & PTE_V) == 0)
    80001de2:	cd11                	beqz	a0,80001dfe <freeproc+0x98>
    80001de4:	6108                	ld	a0,0(a0)
    80001de6:	00157793          	andi	a5,a0,1
    80001dea:	cb91                	beqz	a5,80001dfe <freeproc+0x98>
    kfree((void *)PTE2PA(*pte));
    80001dec:	8129                	srli	a0,a0,0xa
    80001dee:	0532                	slli	a0,a0,0xc
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	c34080e7          	jalr	-972(ra) # 80000a24 <kfree>
    p->kstack = 0;
    80001df8:	0404b023          	sd	zero,64(s1)
    80001dfc:	bf71                	j	80001d98 <freeproc+0x32>
      panic("freeproc");
    80001dfe:	00006517          	auipc	a0,0x6
    80001e02:	42250513          	addi	a0,a0,1058 # 80008220 <digits+0x1e0>
    80001e06:	ffffe097          	auipc	ra,0xffffe
    80001e0a:	742080e7          	jalr	1858(ra) # 80000548 <panic>

0000000080001e0e <allocproc>:
{
    80001e0e:	7179                	addi	sp,sp,-48
    80001e10:	f406                	sd	ra,40(sp)
    80001e12:	f022                	sd	s0,32(sp)
    80001e14:	ec26                	sd	s1,24(sp)
    80001e16:	e84a                	sd	s2,16(sp)
    80001e18:	e44e                	sd	s3,8(sp)
    80001e1a:	1800                	addi	s0,sp,48
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e1c:	00010497          	auipc	s1,0x10
    80001e20:	f4c48493          	addi	s1,s1,-180 # 80011d68 <proc>
    80001e24:	00016917          	auipc	s2,0x16
    80001e28:	b4490913          	addi	s2,s2,-1212 # 80017968 <tickslock>
    acquire(&p->lock);
    80001e2c:	8526                	mv	a0,s1
    80001e2e:	fffff097          	auipc	ra,0xfffff
    80001e32:	de2080e7          	jalr	-542(ra) # 80000c10 <acquire>
    if(p->state == UNUSED) {
    80001e36:	4c9c                	lw	a5,24(s1)
    80001e38:	cf81                	beqz	a5,80001e50 <allocproc+0x42>
      release(&p->lock);
    80001e3a:	8526                	mv	a0,s1
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	e88080e7          	jalr	-376(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e44:	17048493          	addi	s1,s1,368
    80001e48:	ff2492e3          	bne	s1,s2,80001e2c <allocproc+0x1e>
  return 0;
    80001e4c:	4481                	li	s1,0
    80001e4e:	a06d                	j	80001ef8 <allocproc+0xea>
  p->pid = allocpid();
    80001e50:	00000097          	auipc	ra,0x0
    80001e54:	de2080e7          	jalr	-542(ra) # 80001c32 <allocpid>
    80001e58:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e5a:	fffff097          	auipc	ra,0xfffff
    80001e5e:	cc6080e7          	jalr	-826(ra) # 80000b20 <kalloc>
    80001e62:	892a                	mv	s2,a0
    80001e64:	f0a8                	sd	a0,96(s1)
    80001e66:	c14d                	beqz	a0,80001f08 <allocproc+0xfa>
  p->pagetable = proc_pagetable(p);
    80001e68:	8526                	mv	a0,s1
    80001e6a:	00000097          	auipc	ra,0x0
    80001e6e:	e0e080e7          	jalr	-498(ra) # 80001c78 <proc_pagetable>
    80001e72:	892a                	mv	s2,a0
    80001e74:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0)
    80001e76:	c145                	beqz	a0,80001f16 <allocproc+0x108>
  p->kpagetable = kvminit();
    80001e78:	fffff097          	auipc	ra,0xfffff
    80001e7c:	7e8080e7          	jalr	2024(ra) # 80001660 <kvminit>
    80001e80:	892a                	mv	s2,a0
    80001e82:	eca8                	sd	a0,88(s1)
  if(p->kpagetable == 0)
    80001e84:	c54d                	beqz	a0,80001f2e <allocproc+0x120>
  char *pa = kalloc();
    80001e86:	fffff097          	auipc	ra,0xfffff
    80001e8a:	c9a080e7          	jalr	-870(ra) # 80000b20 <kalloc>
    80001e8e:	89aa                	mv	s3,a0
  if (pa == 0)
    80001e90:	c95d                	beqz	a0,80001f46 <allocproc+0x138>
  uint64 va = KSTACK((int)(p - proc));
    80001e92:	00010797          	auipc	a5,0x10
    80001e96:	ed678793          	addi	a5,a5,-298 # 80011d68 <proc>
    80001e9a:	40f487b3          	sub	a5,s1,a5
    80001e9e:	8791                	srai	a5,a5,0x4
    80001ea0:	00006717          	auipc	a4,0x6
    80001ea4:	16073703          	ld	a4,352(a4) # 80008000 <etext>
    80001ea8:	02e787b3          	mul	a5,a5,a4
    80001eac:	2785                	addiw	a5,a5,1
    80001eae:	00d7979b          	slliw	a5,a5,0xd
    80001eb2:	04000937          	lui	s2,0x4000
    80001eb6:	197d                	addi	s2,s2,-1
    80001eb8:	0932                	slli	s2,s2,0xc
    80001eba:	40f90933          	sub	s2,s2,a5
  kvmmap_usr(p->kpagetable, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001ebe:	4719                	li	a4,6
    80001ec0:	6685                	lui	a3,0x1
    80001ec2:	862a                	mv	a2,a0
    80001ec4:	85ca                	mv	a1,s2
    80001ec6:	6ca8                	ld	a0,88(s1)
    80001ec8:	fffff097          	auipc	ra,0xfffff
    80001ecc:	3e8080e7          	jalr	1000(ra) # 800012b0 <kvmmap_usr>
  p->kstack = va;
    80001ed0:	0524b023          	sd	s2,64(s1)
  memset(&p->context, 0, sizeof(p->context));
    80001ed4:	07000613          	li	a2,112
    80001ed8:	4581                	li	a1,0
    80001eda:	06848513          	addi	a0,s1,104
    80001ede:	fffff097          	auipc	ra,0xfffff
    80001ee2:	e2e080e7          	jalr	-466(ra) # 80000d0c <memset>
  p->context.ra = (uint64)forkret;
    80001ee6:	00000797          	auipc	a5,0x0
    80001eea:	d0678793          	addi	a5,a5,-762 # 80001bec <forkret>
    80001eee:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ef0:	60bc                	ld	a5,64(s1)
    80001ef2:	6705                	lui	a4,0x1
    80001ef4:	97ba                	add	a5,a5,a4
    80001ef6:	f8bc                	sd	a5,112(s1)
}
    80001ef8:	8526                	mv	a0,s1
    80001efa:	70a2                	ld	ra,40(sp)
    80001efc:	7402                	ld	s0,32(sp)
    80001efe:	64e2                	ld	s1,24(sp)
    80001f00:	6942                	ld	s2,16(sp)
    80001f02:	69a2                	ld	s3,8(sp)
    80001f04:	6145                	addi	sp,sp,48
    80001f06:	8082                	ret
    release(&p->lock);
    80001f08:	8526                	mv	a0,s1
    80001f0a:	fffff097          	auipc	ra,0xfffff
    80001f0e:	dba080e7          	jalr	-582(ra) # 80000cc4 <release>
    return 0;
    80001f12:	84ca                	mv	s1,s2
    80001f14:	b7d5                	j	80001ef8 <allocproc+0xea>
    freeproc(p);
    80001f16:	8526                	mv	a0,s1
    80001f18:	00000097          	auipc	ra,0x0
    80001f1c:	e4e080e7          	jalr	-434(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001f20:	8526                	mv	a0,s1
    80001f22:	fffff097          	auipc	ra,0xfffff
    80001f26:	da2080e7          	jalr	-606(ra) # 80000cc4 <release>
    return 0;
    80001f2a:	84ca                	mv	s1,s2
    80001f2c:	b7f1                	j	80001ef8 <allocproc+0xea>
    freeproc(p);
    80001f2e:	8526                	mv	a0,s1
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	e36080e7          	jalr	-458(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	d8a080e7          	jalr	-630(ra) # 80000cc4 <release>
    return 0;
    80001f42:	84ca                	mv	s1,s2
    80001f44:	bf55                	j	80001ef8 <allocproc+0xea>
    freeproc(p);
    80001f46:	8526                	mv	a0,s1
    80001f48:	00000097          	auipc	ra,0x0
    80001f4c:	e1e080e7          	jalr	-482(ra) # 80001d66 <freeproc>
    release(&p->lock);
    80001f50:	8526                	mv	a0,s1
    80001f52:	fffff097          	auipc	ra,0xfffff
    80001f56:	d72080e7          	jalr	-654(ra) # 80000cc4 <release>
    return 0;
    80001f5a:	84ce                	mv	s1,s3
    80001f5c:	bf71                	j	80001ef8 <allocproc+0xea>

0000000080001f5e <userinit>:
{
    80001f5e:	1101                	addi	sp,sp,-32
    80001f60:	ec06                	sd	ra,24(sp)
    80001f62:	e822                	sd	s0,16(sp)
    80001f64:	e426                	sd	s1,8(sp)
    80001f66:	e04a                	sd	s2,0(sp)
    80001f68:	1000                	addi	s0,sp,32
  p = allocproc();
    80001f6a:	00000097          	auipc	ra,0x0
    80001f6e:	ea4080e7          	jalr	-348(ra) # 80001e0e <allocproc>
    80001f72:	84aa                	mv	s1,a0
  initproc = p;
    80001f74:	00007797          	auipc	a5,0x7
    80001f78:	0aa7b223          	sd	a0,164(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f7c:	03400613          	li	a2,52
    80001f80:	00007597          	auipc	a1,0x7
    80001f84:	92058593          	addi	a1,a1,-1760 # 800088a0 <initcode>
    80001f88:	6928                	ld	a0,80(a0)
    80001f8a:	fffff097          	auipc	ra,0xfffff
    80001f8e:	43e080e7          	jalr	1086(ra) # 800013c8 <uvminit>
  p->sz = PGSIZE;
    80001f92:	6905                	lui	s2,0x1
    80001f94:	0524b423          	sd	s2,72(s1)
  u2kcopy(p->pagetable, p->kpagetable, 0, p->sz);
    80001f98:	6685                	lui	a3,0x1
    80001f9a:	4601                	li	a2,0
    80001f9c:	6cac                	ld	a1,88(s1)
    80001f9e:	68a8                	ld	a0,80(s1)
    80001fa0:	00000097          	auipc	ra,0x0
    80001fa4:	8b2080e7          	jalr	-1870(ra) # 80001852 <u2kcopy>
  p->trapframe->epc = 0;      // user program counter
    80001fa8:	70bc                	ld	a5,96(s1)
    80001faa:	0007bc23          	sd	zero,24(a5)
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001fae:	70bc                	ld	a5,96(s1)
    80001fb0:	0327b823          	sd	s2,48(a5)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001fb4:	4641                	li	a2,16
    80001fb6:	00006597          	auipc	a1,0x6
    80001fba:	27a58593          	addi	a1,a1,634 # 80008230 <digits+0x1f0>
    80001fbe:	16048513          	addi	a0,s1,352
    80001fc2:	fffff097          	auipc	ra,0xfffff
    80001fc6:	ea0080e7          	jalr	-352(ra) # 80000e62 <safestrcpy>
  p->cwd = namei("/");
    80001fca:	00006517          	auipc	a0,0x6
    80001fce:	27650513          	addi	a0,a0,630 # 80008240 <digits+0x200>
    80001fd2:	00002097          	auipc	ra,0x2
    80001fd6:	196080e7          	jalr	406(ra) # 80004168 <namei>
    80001fda:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001fde:	4789                	li	a5,2
    80001fe0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001fe2:	8526                	mv	a0,s1
    80001fe4:	fffff097          	auipc	ra,0xfffff
    80001fe8:	ce0080e7          	jalr	-800(ra) # 80000cc4 <release>
}
    80001fec:	60e2                	ld	ra,24(sp)
    80001fee:	6442                	ld	s0,16(sp)
    80001ff0:	64a2                	ld	s1,8(sp)
    80001ff2:	6902                	ld	s2,0(sp)
    80001ff4:	6105                	addi	sp,sp,32
    80001ff6:	8082                	ret

0000000080001ff8 <growproc>:
{
    80001ff8:	7139                	addi	sp,sp,-64
    80001ffa:	fc06                	sd	ra,56(sp)
    80001ffc:	f822                	sd	s0,48(sp)
    80001ffe:	f426                	sd	s1,40(sp)
    80002000:	f04a                	sd	s2,32(sp)
    80002002:	ec4e                	sd	s3,24(sp)
    80002004:	e852                	sd	s4,16(sp)
    80002006:	e456                	sd	s5,8(sp)
    80002008:	0080                	addi	s0,sp,64
    8000200a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	ba8080e7          	jalr	-1112(ra) # 80001bb4 <myproc>
    80002014:	892a                	mv	s2,a0
  sz = p->sz;
    80002016:	652c                	ld	a1,72(a0)
  oldsz = PGROUNDUP(sz);
    80002018:	6785                	lui	a5,0x1
    8000201a:	37fd                	addiw	a5,a5,-1
    8000201c:	00b7863b          	addw	a2,a5,a1
    80002020:	777d                	lui	a4,0xfffff
    80002022:	8e79                	and	a2,a2,a4
    80002024:	00060a9b          	sext.w	s5,a2
  newsz = PGROUNDUP(sz + n);
    80002028:	00ba063b          	addw	a2,s4,a1
    8000202c:	00f604bb          	addw	s1,a2,a5
    80002030:	8cf9                	and	s1,s1,a4
    80002032:	2481                	sext.w	s1,s1
  if(n > 0){
    80002034:	07405263          	blez	s4,80002098 <growproc+0xa0>
    if (newsz >= PLIC)
    80002038:	0c0007b7          	lui	a5,0xc000
    8000203c:	08f4fc63          	bgeu	s1,a5,800020d4 <growproc+0xdc>
    if ((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) 
    80002040:	1602                	slli	a2,a2,0x20
    80002042:	9201                	srli	a2,a2,0x20
    80002044:	1582                	slli	a1,a1,0x20
    80002046:	9181                	srli	a1,a1,0x20
    80002048:	6928                	ld	a0,80(a0)
    8000204a:	fffff097          	auipc	ra,0xfffff
    8000204e:	438080e7          	jalr	1080(ra) # 80001482 <uvmalloc>
    80002052:	0005099b          	sext.w	s3,a0
    80002056:	08098163          	beqz	s3,800020d8 <growproc+0xe0>
    if (u2kcopy(p->pagetable, p->kpagetable, oldsz, newsz) < 0)
    8000205a:	02049693          	slli	a3,s1,0x20
    8000205e:	9281                	srli	a3,a3,0x20
    80002060:	020a9613          	slli	a2,s5,0x20
    80002064:	9201                	srli	a2,a2,0x20
    80002066:	05893583          	ld	a1,88(s2) # 1058 <_entry-0x7fffefa8>
    8000206a:	05093503          	ld	a0,80(s2)
    8000206e:	fffff097          	auipc	ra,0xfffff
    80002072:	7e4080e7          	jalr	2020(ra) # 80001852 <u2kcopy>
    80002076:	06054363          	bltz	a0,800020dc <growproc+0xe4>
  p->sz = sz;
    8000207a:	1982                	slli	s3,s3,0x20
    8000207c:	0209d993          	srli	s3,s3,0x20
    80002080:	05393423          	sd	s3,72(s2)
  return 0;
    80002084:	4501                	li	a0,0
}
    80002086:	70e2                	ld	ra,56(sp)
    80002088:	7442                	ld	s0,48(sp)
    8000208a:	74a2                	ld	s1,40(sp)
    8000208c:	7902                	ld	s2,32(sp)
    8000208e:	69e2                	ld	s3,24(sp)
    80002090:	6a42                	ld	s4,16(sp)
    80002092:	6aa2                	ld	s5,8(sp)
    80002094:	6121                	addi	sp,sp,64
    80002096:	8082                	ret
    80002098:	0005899b          	sext.w	s3,a1
  } else if(n < 0){
    8000209c:	fc0a5fe3          	bgez	s4,8000207a <growproc+0x82>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    800020a0:	1602                	slli	a2,a2,0x20
    800020a2:	9201                	srli	a2,a2,0x20
    800020a4:	1582                	slli	a1,a1,0x20
    800020a6:	9181                	srli	a1,a1,0x20
    800020a8:	6928                	ld	a0,80(a0)
    800020aa:	fffff097          	auipc	ra,0xfffff
    800020ae:	390080e7          	jalr	912(ra) # 8000143a <uvmdealloc>
    800020b2:	0005099b          	sext.w	s3,a0
    uvmunmap(p->kpagetable, newsz, (oldsz - newsz) / PGSIZE, 0);
    800020b6:	409a863b          	subw	a2,s5,s1
    800020ba:	4681                	li	a3,0
    800020bc:	00c6561b          	srliw	a2,a2,0xc
    800020c0:	02049593          	slli	a1,s1,0x20
    800020c4:	9181                	srli	a1,a1,0x20
    800020c6:	05893503          	ld	a0,88(s2)
    800020ca:	fffff097          	auipc	ra,0xfffff
    800020ce:	20c080e7          	jalr	524(ra) # 800012d6 <uvmunmap>
    800020d2:	b765                	j	8000207a <growproc+0x82>
      return -1;
    800020d4:	557d                	li	a0,-1
    800020d6:	bf45                	j	80002086 <growproc+0x8e>
      return -1;
    800020d8:	557d                	li	a0,-1
    800020da:	b775                	j	80002086 <growproc+0x8e>
      return -1;
    800020dc:	557d                	li	a0,-1
    800020de:	b765                	j	80002086 <growproc+0x8e>

00000000800020e0 <fork>:
{
    800020e0:	7179                	addi	sp,sp,-48
    800020e2:	f406                	sd	ra,40(sp)
    800020e4:	f022                	sd	s0,32(sp)
    800020e6:	ec26                	sd	s1,24(sp)
    800020e8:	e84a                	sd	s2,16(sp)
    800020ea:	e44e                	sd	s3,8(sp)
    800020ec:	e052                	sd	s4,0(sp)
    800020ee:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020f0:	00000097          	auipc	ra,0x0
    800020f4:	ac4080e7          	jalr	-1340(ra) # 80001bb4 <myproc>
    800020f8:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    800020fa:	00000097          	auipc	ra,0x0
    800020fe:	d14080e7          	jalr	-748(ra) # 80001e0e <allocproc>
    80002102:	10050a63          	beqz	a0,80002216 <fork+0x136>
    80002106:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002108:	04893603          	ld	a2,72(s2)
    8000210c:	692c                	ld	a1,80(a0)
    8000210e:	05093503          	ld	a0,80(s2)
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	66e080e7          	jalr	1646(ra) # 80001780 <uvmcopy>
    8000211a:	06054363          	bltz	a0,80002180 <fork+0xa0>
  np->sz = p->sz;
    8000211e:	04893683          	ld	a3,72(s2)
    80002122:	04d9b423          	sd	a3,72(s3)
  np->parent = p;
    80002126:	0329b023          	sd	s2,32(s3)
  if (u2kcopy(np->pagetable, np->kpagetable, 0, np->sz) < 0)
    8000212a:	4601                	li	a2,0
    8000212c:	0589b583          	ld	a1,88(s3)
    80002130:	0509b503          	ld	a0,80(s3)
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	71e080e7          	jalr	1822(ra) # 80001852 <u2kcopy>
    8000213c:	04054e63          	bltz	a0,80002198 <fork+0xb8>
  *(np->trapframe) = *(p->trapframe);
    80002140:	06093683          	ld	a3,96(s2)
    80002144:	87b6                	mv	a5,a3
    80002146:	0609b703          	ld	a4,96(s3)
    8000214a:	12068693          	addi	a3,a3,288 # 1120 <_entry-0x7fffeee0>
    8000214e:	0007b803          	ld	a6,0(a5) # c000000 <_entry-0x74000000>
    80002152:	6788                	ld	a0,8(a5)
    80002154:	6b8c                	ld	a1,16(a5)
    80002156:	6f90                	ld	a2,24(a5)
    80002158:	01073023          	sd	a6,0(a4) # fffffffffffff000 <end+0xffffffff7ffd7fe0>
    8000215c:	e708                	sd	a0,8(a4)
    8000215e:	eb0c                	sd	a1,16(a4)
    80002160:	ef10                	sd	a2,24(a4)
    80002162:	02078793          	addi	a5,a5,32
    80002166:	02070713          	addi	a4,a4,32
    8000216a:	fed792e3          	bne	a5,a3,8000214e <fork+0x6e>
  np->trapframe->a0 = 0;
    8000216e:	0609b783          	ld	a5,96(s3)
    80002172:	0607b823          	sd	zero,112(a5)
    80002176:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    8000217a:	15800a13          	li	s4,344
    8000217e:	a099                	j	800021c4 <fork+0xe4>
    freeproc(np);
    80002180:	854e                	mv	a0,s3
    80002182:	00000097          	auipc	ra,0x0
    80002186:	be4080e7          	jalr	-1052(ra) # 80001d66 <freeproc>
    release(&np->lock);
    8000218a:	854e                	mv	a0,s3
    8000218c:	fffff097          	auipc	ra,0xfffff
    80002190:	b38080e7          	jalr	-1224(ra) # 80000cc4 <release>
    return -1;
    80002194:	54fd                	li	s1,-1
    80002196:	a0bd                	j	80002204 <fork+0x124>
    freeproc(np);
    80002198:	854e                	mv	a0,s3
    8000219a:	00000097          	auipc	ra,0x0
    8000219e:	bcc080e7          	jalr	-1076(ra) # 80001d66 <freeproc>
    release(&np->lock);
    800021a2:	854e                	mv	a0,s3
    800021a4:	fffff097          	auipc	ra,0xfffff
    800021a8:	b20080e7          	jalr	-1248(ra) # 80000cc4 <release>
    return -1;
    800021ac:	54fd                	li	s1,-1
    800021ae:	a899                	j	80002204 <fork+0x124>
      np->ofile[i] = filedup(p->ofile[i]);
    800021b0:	00002097          	auipc	ra,0x2
    800021b4:	644080e7          	jalr	1604(ra) # 800047f4 <filedup>
    800021b8:	009987b3          	add	a5,s3,s1
    800021bc:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    800021be:	04a1                	addi	s1,s1,8
    800021c0:	01448763          	beq	s1,s4,800021ce <fork+0xee>
    if(p->ofile[i])
    800021c4:	009907b3          	add	a5,s2,s1
    800021c8:	6388                	ld	a0,0(a5)
    800021ca:	f17d                	bnez	a0,800021b0 <fork+0xd0>
    800021cc:	bfcd                	j	800021be <fork+0xde>
  np->cwd = idup(p->cwd);
    800021ce:	15893503          	ld	a0,344(s2)
    800021d2:	00001097          	auipc	ra,0x1
    800021d6:	7a8080e7          	jalr	1960(ra) # 8000397a <idup>
    800021da:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800021de:	4641                	li	a2,16
    800021e0:	16090593          	addi	a1,s2,352
    800021e4:	16098513          	addi	a0,s3,352
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	c7a080e7          	jalr	-902(ra) # 80000e62 <safestrcpy>
  pid = np->pid;
    800021f0:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    800021f4:	4789                	li	a5,2
    800021f6:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    800021fa:	854e                	mv	a0,s3
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	ac8080e7          	jalr	-1336(ra) # 80000cc4 <release>
}
    80002204:	8526                	mv	a0,s1
    80002206:	70a2                	ld	ra,40(sp)
    80002208:	7402                	ld	s0,32(sp)
    8000220a:	64e2                	ld	s1,24(sp)
    8000220c:	6942                	ld	s2,16(sp)
    8000220e:	69a2                	ld	s3,8(sp)
    80002210:	6a02                	ld	s4,0(sp)
    80002212:	6145                	addi	sp,sp,48
    80002214:	8082                	ret
    return -1;
    80002216:	54fd                	li	s1,-1
    80002218:	b7f5                	j	80002204 <fork+0x124>

000000008000221a <reparent>:
{
    8000221a:	7179                	addi	sp,sp,-48
    8000221c:	f406                	sd	ra,40(sp)
    8000221e:	f022                	sd	s0,32(sp)
    80002220:	ec26                	sd	s1,24(sp)
    80002222:	e84a                	sd	s2,16(sp)
    80002224:	e44e                	sd	s3,8(sp)
    80002226:	e052                	sd	s4,0(sp)
    80002228:	1800                	addi	s0,sp,48
    8000222a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000222c:	00010497          	auipc	s1,0x10
    80002230:	b3c48493          	addi	s1,s1,-1220 # 80011d68 <proc>
      pp->parent = initproc;
    80002234:	00007a17          	auipc	s4,0x7
    80002238:	de4a0a13          	addi	s4,s4,-540 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000223c:	00015997          	auipc	s3,0x15
    80002240:	72c98993          	addi	s3,s3,1836 # 80017968 <tickslock>
    80002244:	a029                	j	8000224e <reparent+0x34>
    80002246:	17048493          	addi	s1,s1,368
    8000224a:	03348363          	beq	s1,s3,80002270 <reparent+0x56>
    if(pp->parent == p){
    8000224e:	709c                	ld	a5,32(s1)
    80002250:	ff279be3          	bne	a5,s2,80002246 <reparent+0x2c>
      acquire(&pp->lock);
    80002254:	8526                	mv	a0,s1
    80002256:	fffff097          	auipc	ra,0xfffff
    8000225a:	9ba080e7          	jalr	-1606(ra) # 80000c10 <acquire>
      pp->parent = initproc;
    8000225e:	000a3783          	ld	a5,0(s4)
    80002262:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a5e080e7          	jalr	-1442(ra) # 80000cc4 <release>
    8000226e:	bfe1                	j	80002246 <reparent+0x2c>
}
    80002270:	70a2                	ld	ra,40(sp)
    80002272:	7402                	ld	s0,32(sp)
    80002274:	64e2                	ld	s1,24(sp)
    80002276:	6942                	ld	s2,16(sp)
    80002278:	69a2                	ld	s3,8(sp)
    8000227a:	6a02                	ld	s4,0(sp)
    8000227c:	6145                	addi	sp,sp,48
    8000227e:	8082                	ret

0000000080002280 <scheduler>:
{
    80002280:	715d                	addi	sp,sp,-80
    80002282:	e486                	sd	ra,72(sp)
    80002284:	e0a2                	sd	s0,64(sp)
    80002286:	fc26                	sd	s1,56(sp)
    80002288:	f84a                	sd	s2,48(sp)
    8000228a:	f44e                	sd	s3,40(sp)
    8000228c:	f052                	sd	s4,32(sp)
    8000228e:	ec56                	sd	s5,24(sp)
    80002290:	e85a                	sd	s6,16(sp)
    80002292:	e45e                	sd	s7,8(sp)
    80002294:	e062                	sd	s8,0(sp)
    80002296:	0880                	addi	s0,sp,80
    80002298:	8792                	mv	a5,tp
  int id = r_tp();
    8000229a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000229c:	00779b93          	slli	s7,a5,0x7
    800022a0:	0000f717          	auipc	a4,0xf
    800022a4:	6b070713          	addi	a4,a4,1712 # 80011950 <pid_lock>
    800022a8:	975e                	add	a4,a4,s7
    800022aa:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    800022ae:	0000f717          	auipc	a4,0xf
    800022b2:	6c270713          	addi	a4,a4,1730 # 80011970 <cpus+0x8>
    800022b6:	9bba                	add	s7,s7,a4
        c->proc = p;
    800022b8:	079e                	slli	a5,a5,0x7
    800022ba:	0000fa97          	auipc	s5,0xf
    800022be:	696a8a93          	addi	s5,s5,1686 # 80011950 <pid_lock>
    800022c2:	9abe                	add	s5,s5,a5
        w_satp(MAKE_SATP(p->kpagetable));
    800022c4:	5a7d                	li	s4,-1
    800022c6:	1a7e                	slli	s4,s4,0x3f
        w_satp(MAKE_SATP(kernel_pagetable));
    800022c8:	00007b17          	auipc	s6,0x7
    800022cc:	d48b0b13          	addi	s6,s6,-696 # 80009010 <kernel_pagetable>
    800022d0:	a069                	j	8000235a <scheduler+0xda>
        p->state = RUNNING;
    800022d2:	478d                	li	a5,3
    800022d4:	cc9c                	sw	a5,24(s1)
        c->proc = p;
    800022d6:	009abc23          	sd	s1,24(s5)
        w_satp(MAKE_SATP(p->kpagetable));
    800022da:	6cbc                	ld	a5,88(s1)
    800022dc:	83b1                	srli	a5,a5,0xc
    800022de:	0147e7b3          	or	a5,a5,s4
  asm volatile("csrw satp, %0" : : "r" (x));
    800022e2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    800022e6:	12000073          	sfence.vma
        swtch(&c->context, &p->context);
    800022ea:	06848593          	addi	a1,s1,104
    800022ee:	855e                	mv	a0,s7
    800022f0:	00000097          	auipc	ra,0x0
    800022f4:	664080e7          	jalr	1636(ra) # 80002954 <swtch>
        c->proc = 0;
    800022f8:	000abc23          	sd	zero,24(s5)
        w_satp(MAKE_SATP(kernel_pagetable));
    800022fc:	000b3783          	ld	a5,0(s6)
    80002300:	83b1                	srli	a5,a5,0xc
    80002302:	0147e7b3          	or	a5,a5,s4
  asm volatile("csrw satp, %0" : : "r" (x));
    80002306:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000230a:	12000073          	sfence.vma
        found = 1;
    8000230e:	4c05                	li	s8,1
      release(&p->lock);
    80002310:	8526                	mv	a0,s1
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	9b2080e7          	jalr	-1614(ra) # 80000cc4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000231a:	17048493          	addi	s1,s1,368
    8000231e:	01248b63          	beq	s1,s2,80002334 <scheduler+0xb4>
      acquire(&p->lock);
    80002322:	8526                	mv	a0,s1
    80002324:	fffff097          	auipc	ra,0xfffff
    80002328:	8ec080e7          	jalr	-1812(ra) # 80000c10 <acquire>
      if(p->state == RUNNABLE) {
    8000232c:	4c9c                	lw	a5,24(s1)
    8000232e:	ff3791e3          	bne	a5,s3,80002310 <scheduler+0x90>
    80002332:	b745                	j	800022d2 <scheduler+0x52>
    if(found == 0) {
    80002334:	020c1363          	bnez	s8,8000235a <scheduler+0xda>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002338:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000233c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002340:	10079073          	csrw	sstatus,a5
      w_satp(MAKE_SATP(kernel_pagetable));
    80002344:	000b3783          	ld	a5,0(s6)
    80002348:	83b1                	srli	a5,a5,0xc
    8000234a:	0147e7b3          	or	a5,a5,s4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000234e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80002352:	12000073          	sfence.vma
      asm volatile("wfi");
    80002356:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000235a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000235e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002362:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002366:	4c01                	li	s8,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002368:	00010497          	auipc	s1,0x10
    8000236c:	a0048493          	addi	s1,s1,-1536 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80002370:	4989                	li	s3,2
    for(p = proc; p < &proc[NPROC]; p++) {
    80002372:	00015917          	auipc	s2,0x15
    80002376:	5f690913          	addi	s2,s2,1526 # 80017968 <tickslock>
    8000237a:	b765                	j	80002322 <scheduler+0xa2>

000000008000237c <sched>:
{
    8000237c:	7179                	addi	sp,sp,-48
    8000237e:	f406                	sd	ra,40(sp)
    80002380:	f022                	sd	s0,32(sp)
    80002382:	ec26                	sd	s1,24(sp)
    80002384:	e84a                	sd	s2,16(sp)
    80002386:	e44e                	sd	s3,8(sp)
    80002388:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000238a:	00000097          	auipc	ra,0x0
    8000238e:	82a080e7          	jalr	-2006(ra) # 80001bb4 <myproc>
    80002392:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002394:	fffff097          	auipc	ra,0xfffff
    80002398:	802080e7          	jalr	-2046(ra) # 80000b96 <holding>
    8000239c:	c93d                	beqz	a0,80002412 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000239e:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023a0:	2781                	sext.w	a5,a5
    800023a2:	079e                	slli	a5,a5,0x7
    800023a4:	0000f717          	auipc	a4,0xf
    800023a8:	5ac70713          	addi	a4,a4,1452 # 80011950 <pid_lock>
    800023ac:	97ba                	add	a5,a5,a4
    800023ae:	0907a703          	lw	a4,144(a5)
    800023b2:	4785                	li	a5,1
    800023b4:	06f71763          	bne	a4,a5,80002422 <sched+0xa6>
  if(p->state == RUNNING)
    800023b8:	4c98                	lw	a4,24(s1)
    800023ba:	478d                	li	a5,3
    800023bc:	06f70b63          	beq	a4,a5,80002432 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023c0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023c4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023c6:	efb5                	bnez	a5,80002442 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023c8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023ca:	0000f917          	auipc	s2,0xf
    800023ce:	58690913          	addi	s2,s2,1414 # 80011950 <pid_lock>
    800023d2:	2781                	sext.w	a5,a5
    800023d4:	079e                	slli	a5,a5,0x7
    800023d6:	97ca                	add	a5,a5,s2
    800023d8:	0947a983          	lw	s3,148(a5)
    800023dc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023de:	2781                	sext.w	a5,a5
    800023e0:	079e                	slli	a5,a5,0x7
    800023e2:	0000f597          	auipc	a1,0xf
    800023e6:	58e58593          	addi	a1,a1,1422 # 80011970 <cpus+0x8>
    800023ea:	95be                	add	a1,a1,a5
    800023ec:	06848513          	addi	a0,s1,104
    800023f0:	00000097          	auipc	ra,0x0
    800023f4:	564080e7          	jalr	1380(ra) # 80002954 <swtch>
    800023f8:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800023fa:	2781                	sext.w	a5,a5
    800023fc:	079e                	slli	a5,a5,0x7
    800023fe:	97ca                	add	a5,a5,s2
    80002400:	0937aa23          	sw	s3,148(a5)
}
    80002404:	70a2                	ld	ra,40(sp)
    80002406:	7402                	ld	s0,32(sp)
    80002408:	64e2                	ld	s1,24(sp)
    8000240a:	6942                	ld	s2,16(sp)
    8000240c:	69a2                	ld	s3,8(sp)
    8000240e:	6145                	addi	sp,sp,48
    80002410:	8082                	ret
    panic("sched p->lock");
    80002412:	00006517          	auipc	a0,0x6
    80002416:	e3650513          	addi	a0,a0,-458 # 80008248 <digits+0x208>
    8000241a:	ffffe097          	auipc	ra,0xffffe
    8000241e:	12e080e7          	jalr	302(ra) # 80000548 <panic>
    panic("sched locks");
    80002422:	00006517          	auipc	a0,0x6
    80002426:	e3650513          	addi	a0,a0,-458 # 80008258 <digits+0x218>
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	11e080e7          	jalr	286(ra) # 80000548 <panic>
    panic("sched running");
    80002432:	00006517          	auipc	a0,0x6
    80002436:	e3650513          	addi	a0,a0,-458 # 80008268 <digits+0x228>
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	10e080e7          	jalr	270(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002442:	00006517          	auipc	a0,0x6
    80002446:	e3650513          	addi	a0,a0,-458 # 80008278 <digits+0x238>
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	0fe080e7          	jalr	254(ra) # 80000548 <panic>

0000000080002452 <exit>:
{
    80002452:	7179                	addi	sp,sp,-48
    80002454:	f406                	sd	ra,40(sp)
    80002456:	f022                	sd	s0,32(sp)
    80002458:	ec26                	sd	s1,24(sp)
    8000245a:	e84a                	sd	s2,16(sp)
    8000245c:	e44e                	sd	s3,8(sp)
    8000245e:	e052                	sd	s4,0(sp)
    80002460:	1800                	addi	s0,sp,48
    80002462:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	750080e7          	jalr	1872(ra) # 80001bb4 <myproc>
    8000246c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000246e:	00007797          	auipc	a5,0x7
    80002472:	baa7b783          	ld	a5,-1110(a5) # 80009018 <initproc>
    80002476:	0d850493          	addi	s1,a0,216
    8000247a:	15850913          	addi	s2,a0,344
    8000247e:	02a79363          	bne	a5,a0,800024a4 <exit+0x52>
    panic("init exiting");
    80002482:	00006517          	auipc	a0,0x6
    80002486:	e0e50513          	addi	a0,a0,-498 # 80008290 <digits+0x250>
    8000248a:	ffffe097          	auipc	ra,0xffffe
    8000248e:	0be080e7          	jalr	190(ra) # 80000548 <panic>
      fileclose(f);
    80002492:	00002097          	auipc	ra,0x2
    80002496:	3b4080e7          	jalr	948(ra) # 80004846 <fileclose>
      p->ofile[fd] = 0;
    8000249a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000249e:	04a1                	addi	s1,s1,8
    800024a0:	01248563          	beq	s1,s2,800024aa <exit+0x58>
    if(p->ofile[fd]){
    800024a4:	6088                	ld	a0,0(s1)
    800024a6:	f575                	bnez	a0,80002492 <exit+0x40>
    800024a8:	bfdd                	j	8000249e <exit+0x4c>
  begin_op();
    800024aa:	00002097          	auipc	ra,0x2
    800024ae:	eca080e7          	jalr	-310(ra) # 80004374 <begin_op>
  iput(p->cwd);
    800024b2:	1589b503          	ld	a0,344(s3)
    800024b6:	00001097          	auipc	ra,0x1
    800024ba:	6bc080e7          	jalr	1724(ra) # 80003b72 <iput>
  end_op();
    800024be:	00002097          	auipc	ra,0x2
    800024c2:	f36080e7          	jalr	-202(ra) # 800043f4 <end_op>
  p->cwd = 0;
    800024c6:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800024ca:	00007497          	auipc	s1,0x7
    800024ce:	b4e48493          	addi	s1,s1,-1202 # 80009018 <initproc>
    800024d2:	6088                	ld	a0,0(s1)
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	73c080e7          	jalr	1852(ra) # 80000c10 <acquire>
  wakeup1(initproc);
    800024dc:	6088                	ld	a0,0(s1)
    800024de:	fffff097          	auipc	ra,0xfffff
    800024e2:	5fe080e7          	jalr	1534(ra) # 80001adc <wakeup1>
  release(&initproc->lock);
    800024e6:	6088                	ld	a0,0(s1)
    800024e8:	ffffe097          	auipc	ra,0xffffe
    800024ec:	7dc080e7          	jalr	2012(ra) # 80000cc4 <release>
  acquire(&p->lock);
    800024f0:	854e                	mv	a0,s3
    800024f2:	ffffe097          	auipc	ra,0xffffe
    800024f6:	71e080e7          	jalr	1822(ra) # 80000c10 <acquire>
  struct proc *original_parent = p->parent;
    800024fa:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800024fe:	854e                	mv	a0,s3
    80002500:	ffffe097          	auipc	ra,0xffffe
    80002504:	7c4080e7          	jalr	1988(ra) # 80000cc4 <release>
  acquire(&original_parent->lock);
    80002508:	8526                	mv	a0,s1
    8000250a:	ffffe097          	auipc	ra,0xffffe
    8000250e:	706080e7          	jalr	1798(ra) # 80000c10 <acquire>
  acquire(&p->lock);
    80002512:	854e                	mv	a0,s3
    80002514:	ffffe097          	auipc	ra,0xffffe
    80002518:	6fc080e7          	jalr	1788(ra) # 80000c10 <acquire>
  reparent(p);
    8000251c:	854e                	mv	a0,s3
    8000251e:	00000097          	auipc	ra,0x0
    80002522:	cfc080e7          	jalr	-772(ra) # 8000221a <reparent>
  wakeup1(original_parent);
    80002526:	8526                	mv	a0,s1
    80002528:	fffff097          	auipc	ra,0xfffff
    8000252c:	5b4080e7          	jalr	1460(ra) # 80001adc <wakeup1>
  p->xstate = status;
    80002530:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002534:	4791                	li	a5,4
    80002536:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    8000253a:	8526                	mv	a0,s1
    8000253c:	ffffe097          	auipc	ra,0xffffe
    80002540:	788080e7          	jalr	1928(ra) # 80000cc4 <release>
  sched();
    80002544:	00000097          	auipc	ra,0x0
    80002548:	e38080e7          	jalr	-456(ra) # 8000237c <sched>
  panic("zombie exit");
    8000254c:	00006517          	auipc	a0,0x6
    80002550:	d5450513          	addi	a0,a0,-684 # 800082a0 <digits+0x260>
    80002554:	ffffe097          	auipc	ra,0xffffe
    80002558:	ff4080e7          	jalr	-12(ra) # 80000548 <panic>

000000008000255c <yield>:
{
    8000255c:	1101                	addi	sp,sp,-32
    8000255e:	ec06                	sd	ra,24(sp)
    80002560:	e822                	sd	s0,16(sp)
    80002562:	e426                	sd	s1,8(sp)
    80002564:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002566:	fffff097          	auipc	ra,0xfffff
    8000256a:	64e080e7          	jalr	1614(ra) # 80001bb4 <myproc>
    8000256e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002570:	ffffe097          	auipc	ra,0xffffe
    80002574:	6a0080e7          	jalr	1696(ra) # 80000c10 <acquire>
  p->state = RUNNABLE;
    80002578:	4789                	li	a5,2
    8000257a:	cc9c                	sw	a5,24(s1)
  sched();
    8000257c:	00000097          	auipc	ra,0x0
    80002580:	e00080e7          	jalr	-512(ra) # 8000237c <sched>
  release(&p->lock);
    80002584:	8526                	mv	a0,s1
    80002586:	ffffe097          	auipc	ra,0xffffe
    8000258a:	73e080e7          	jalr	1854(ra) # 80000cc4 <release>
}
    8000258e:	60e2                	ld	ra,24(sp)
    80002590:	6442                	ld	s0,16(sp)
    80002592:	64a2                	ld	s1,8(sp)
    80002594:	6105                	addi	sp,sp,32
    80002596:	8082                	ret

0000000080002598 <sleep>:
{
    80002598:	7179                	addi	sp,sp,-48
    8000259a:	f406                	sd	ra,40(sp)
    8000259c:	f022                	sd	s0,32(sp)
    8000259e:	ec26                	sd	s1,24(sp)
    800025a0:	e84a                	sd	s2,16(sp)
    800025a2:	e44e                	sd	s3,8(sp)
    800025a4:	1800                	addi	s0,sp,48
    800025a6:	89aa                	mv	s3,a0
    800025a8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025aa:	fffff097          	auipc	ra,0xfffff
    800025ae:	60a080e7          	jalr	1546(ra) # 80001bb4 <myproc>
    800025b2:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800025b4:	05250663          	beq	a0,s2,80002600 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800025b8:	ffffe097          	auipc	ra,0xffffe
    800025bc:	658080e7          	jalr	1624(ra) # 80000c10 <acquire>
    release(lk);
    800025c0:	854a                	mv	a0,s2
    800025c2:	ffffe097          	auipc	ra,0xffffe
    800025c6:	702080e7          	jalr	1794(ra) # 80000cc4 <release>
  p->chan = chan;
    800025ca:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800025ce:	4785                	li	a5,1
    800025d0:	cc9c                	sw	a5,24(s1)
  sched();
    800025d2:	00000097          	auipc	ra,0x0
    800025d6:	daa080e7          	jalr	-598(ra) # 8000237c <sched>
  p->chan = 0;
    800025da:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800025de:	8526                	mv	a0,s1
    800025e0:	ffffe097          	auipc	ra,0xffffe
    800025e4:	6e4080e7          	jalr	1764(ra) # 80000cc4 <release>
    acquire(lk);
    800025e8:	854a                	mv	a0,s2
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	626080e7          	jalr	1574(ra) # 80000c10 <acquire>
}
    800025f2:	70a2                	ld	ra,40(sp)
    800025f4:	7402                	ld	s0,32(sp)
    800025f6:	64e2                	ld	s1,24(sp)
    800025f8:	6942                	ld	s2,16(sp)
    800025fa:	69a2                	ld	s3,8(sp)
    800025fc:	6145                	addi	sp,sp,48
    800025fe:	8082                	ret
  p->chan = chan;
    80002600:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002604:	4785                	li	a5,1
    80002606:	cd1c                	sw	a5,24(a0)
  sched();
    80002608:	00000097          	auipc	ra,0x0
    8000260c:	d74080e7          	jalr	-652(ra) # 8000237c <sched>
  p->chan = 0;
    80002610:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002614:	bff9                	j	800025f2 <sleep+0x5a>

0000000080002616 <wait>:
{
    80002616:	715d                	addi	sp,sp,-80
    80002618:	e486                	sd	ra,72(sp)
    8000261a:	e0a2                	sd	s0,64(sp)
    8000261c:	fc26                	sd	s1,56(sp)
    8000261e:	f84a                	sd	s2,48(sp)
    80002620:	f44e                	sd	s3,40(sp)
    80002622:	f052                	sd	s4,32(sp)
    80002624:	ec56                	sd	s5,24(sp)
    80002626:	e85a                	sd	s6,16(sp)
    80002628:	e45e                	sd	s7,8(sp)
    8000262a:	e062                	sd	s8,0(sp)
    8000262c:	0880                	addi	s0,sp,80
    8000262e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002630:	fffff097          	auipc	ra,0xfffff
    80002634:	584080e7          	jalr	1412(ra) # 80001bb4 <myproc>
    80002638:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000263a:	8c2a                	mv	s8,a0
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	5d4080e7          	jalr	1492(ra) # 80000c10 <acquire>
    havekids = 0;
    80002644:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002646:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002648:	00015997          	auipc	s3,0x15
    8000264c:	32098993          	addi	s3,s3,800 # 80017968 <tickslock>
        havekids = 1;
    80002650:	4a85                	li	s5,1
    havekids = 0;
    80002652:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002654:	0000f497          	auipc	s1,0xf
    80002658:	71448493          	addi	s1,s1,1812 # 80011d68 <proc>
    8000265c:	a08d                	j	800026be <wait+0xa8>
          pid = np->pid;
    8000265e:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002662:	000b0e63          	beqz	s6,8000267e <wait+0x68>
    80002666:	4691                	li	a3,4
    80002668:	03448613          	addi	a2,s1,52
    8000266c:	85da                	mv	a1,s6
    8000266e:	05093503          	ld	a0,80(s2)
    80002672:	fffff097          	auipc	ra,0xfffff
    80002676:	2ba080e7          	jalr	698(ra) # 8000192c <copyout>
    8000267a:	02054263          	bltz	a0,8000269e <wait+0x88>
          freeproc(np);
    8000267e:	8526                	mv	a0,s1
    80002680:	fffff097          	auipc	ra,0xfffff
    80002684:	6e6080e7          	jalr	1766(ra) # 80001d66 <freeproc>
          release(&np->lock);
    80002688:	8526                	mv	a0,s1
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	63a080e7          	jalr	1594(ra) # 80000cc4 <release>
          release(&p->lock);
    80002692:	854a                	mv	a0,s2
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	630080e7          	jalr	1584(ra) # 80000cc4 <release>
          return pid;
    8000269c:	a8a9                	j	800026f6 <wait+0xe0>
            release(&np->lock);
    8000269e:	8526                	mv	a0,s1
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	624080e7          	jalr	1572(ra) # 80000cc4 <release>
            release(&p->lock);
    800026a8:	854a                	mv	a0,s2
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	61a080e7          	jalr	1562(ra) # 80000cc4 <release>
            return -1;
    800026b2:	59fd                	li	s3,-1
    800026b4:	a089                	j	800026f6 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800026b6:	17048493          	addi	s1,s1,368
    800026ba:	03348463          	beq	s1,s3,800026e2 <wait+0xcc>
      if(np->parent == p){
    800026be:	709c                	ld	a5,32(s1)
    800026c0:	ff279be3          	bne	a5,s2,800026b6 <wait+0xa0>
        acquire(&np->lock);
    800026c4:	8526                	mv	a0,s1
    800026c6:	ffffe097          	auipc	ra,0xffffe
    800026ca:	54a080e7          	jalr	1354(ra) # 80000c10 <acquire>
        if(np->state == ZOMBIE){
    800026ce:	4c9c                	lw	a5,24(s1)
    800026d0:	f94787e3          	beq	a5,s4,8000265e <wait+0x48>
        release(&np->lock);
    800026d4:	8526                	mv	a0,s1
    800026d6:	ffffe097          	auipc	ra,0xffffe
    800026da:	5ee080e7          	jalr	1518(ra) # 80000cc4 <release>
        havekids = 1;
    800026de:	8756                	mv	a4,s5
    800026e0:	bfd9                	j	800026b6 <wait+0xa0>
    if(!havekids || p->killed){
    800026e2:	c701                	beqz	a4,800026ea <wait+0xd4>
    800026e4:	03092783          	lw	a5,48(s2)
    800026e8:	c785                	beqz	a5,80002710 <wait+0xfa>
      release(&p->lock);
    800026ea:	854a                	mv	a0,s2
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	5d8080e7          	jalr	1496(ra) # 80000cc4 <release>
      return -1;
    800026f4:	59fd                	li	s3,-1
}
    800026f6:	854e                	mv	a0,s3
    800026f8:	60a6                	ld	ra,72(sp)
    800026fa:	6406                	ld	s0,64(sp)
    800026fc:	74e2                	ld	s1,56(sp)
    800026fe:	7942                	ld	s2,48(sp)
    80002700:	79a2                	ld	s3,40(sp)
    80002702:	7a02                	ld	s4,32(sp)
    80002704:	6ae2                	ld	s5,24(sp)
    80002706:	6b42                	ld	s6,16(sp)
    80002708:	6ba2                	ld	s7,8(sp)
    8000270a:	6c02                	ld	s8,0(sp)
    8000270c:	6161                	addi	sp,sp,80
    8000270e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002710:	85e2                	mv	a1,s8
    80002712:	854a                	mv	a0,s2
    80002714:	00000097          	auipc	ra,0x0
    80002718:	e84080e7          	jalr	-380(ra) # 80002598 <sleep>
    havekids = 0;
    8000271c:	bf1d                	j	80002652 <wait+0x3c>

000000008000271e <wakeup>:
{
    8000271e:	7139                	addi	sp,sp,-64
    80002720:	fc06                	sd	ra,56(sp)
    80002722:	f822                	sd	s0,48(sp)
    80002724:	f426                	sd	s1,40(sp)
    80002726:	f04a                	sd	s2,32(sp)
    80002728:	ec4e                	sd	s3,24(sp)
    8000272a:	e852                	sd	s4,16(sp)
    8000272c:	e456                	sd	s5,8(sp)
    8000272e:	0080                	addi	s0,sp,64
    80002730:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002732:	0000f497          	auipc	s1,0xf
    80002736:	63648493          	addi	s1,s1,1590 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000273a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000273c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000273e:	00015917          	auipc	s2,0x15
    80002742:	22a90913          	addi	s2,s2,554 # 80017968 <tickslock>
    80002746:	a821                	j	8000275e <wakeup+0x40>
      p->state = RUNNABLE;
    80002748:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    8000274c:	8526                	mv	a0,s1
    8000274e:	ffffe097          	auipc	ra,0xffffe
    80002752:	576080e7          	jalr	1398(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002756:	17048493          	addi	s1,s1,368
    8000275a:	01248e63          	beq	s1,s2,80002776 <wakeup+0x58>
    acquire(&p->lock);
    8000275e:	8526                	mv	a0,s1
    80002760:	ffffe097          	auipc	ra,0xffffe
    80002764:	4b0080e7          	jalr	1200(ra) # 80000c10 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002768:	4c9c                	lw	a5,24(s1)
    8000276a:	ff3791e3          	bne	a5,s3,8000274c <wakeup+0x2e>
    8000276e:	749c                	ld	a5,40(s1)
    80002770:	fd479ee3          	bne	a5,s4,8000274c <wakeup+0x2e>
    80002774:	bfd1                	j	80002748 <wakeup+0x2a>
}
    80002776:	70e2                	ld	ra,56(sp)
    80002778:	7442                	ld	s0,48(sp)
    8000277a:	74a2                	ld	s1,40(sp)
    8000277c:	7902                	ld	s2,32(sp)
    8000277e:	69e2                	ld	s3,24(sp)
    80002780:	6a42                	ld	s4,16(sp)
    80002782:	6aa2                	ld	s5,8(sp)
    80002784:	6121                	addi	sp,sp,64
    80002786:	8082                	ret

0000000080002788 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002788:	7179                	addi	sp,sp,-48
    8000278a:	f406                	sd	ra,40(sp)
    8000278c:	f022                	sd	s0,32(sp)
    8000278e:	ec26                	sd	s1,24(sp)
    80002790:	e84a                	sd	s2,16(sp)
    80002792:	e44e                	sd	s3,8(sp)
    80002794:	1800                	addi	s0,sp,48
    80002796:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002798:	0000f497          	auipc	s1,0xf
    8000279c:	5d048493          	addi	s1,s1,1488 # 80011d68 <proc>
    800027a0:	00015997          	auipc	s3,0x15
    800027a4:	1c898993          	addi	s3,s3,456 # 80017968 <tickslock>
    acquire(&p->lock);
    800027a8:	8526                	mv	a0,s1
    800027aa:	ffffe097          	auipc	ra,0xffffe
    800027ae:	466080e7          	jalr	1126(ra) # 80000c10 <acquire>
    if(p->pid == pid){
    800027b2:	5c9c                	lw	a5,56(s1)
    800027b4:	01278d63          	beq	a5,s2,800027ce <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027b8:	8526                	mv	a0,s1
    800027ba:	ffffe097          	auipc	ra,0xffffe
    800027be:	50a080e7          	jalr	1290(ra) # 80000cc4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c2:	17048493          	addi	s1,s1,368
    800027c6:	ff3491e3          	bne	s1,s3,800027a8 <kill+0x20>
  }
  return -1;
    800027ca:	557d                	li	a0,-1
    800027cc:	a829                	j	800027e6 <kill+0x5e>
      p->killed = 1;
    800027ce:	4785                	li	a5,1
    800027d0:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800027d2:	4c98                	lw	a4,24(s1)
    800027d4:	4785                	li	a5,1
    800027d6:	00f70f63          	beq	a4,a5,800027f4 <kill+0x6c>
      release(&p->lock);
    800027da:	8526                	mv	a0,s1
    800027dc:	ffffe097          	auipc	ra,0xffffe
    800027e0:	4e8080e7          	jalr	1256(ra) # 80000cc4 <release>
      return 0;
    800027e4:	4501                	li	a0,0
}
    800027e6:	70a2                	ld	ra,40(sp)
    800027e8:	7402                	ld	s0,32(sp)
    800027ea:	64e2                	ld	s1,24(sp)
    800027ec:	6942                	ld	s2,16(sp)
    800027ee:	69a2                	ld	s3,8(sp)
    800027f0:	6145                	addi	sp,sp,48
    800027f2:	8082                	ret
        p->state = RUNNABLE;
    800027f4:	4789                	li	a5,2
    800027f6:	cc9c                	sw	a5,24(s1)
    800027f8:	b7cd                	j	800027da <kill+0x52>

00000000800027fa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800027fa:	7179                	addi	sp,sp,-48
    800027fc:	f406                	sd	ra,40(sp)
    800027fe:	f022                	sd	s0,32(sp)
    80002800:	ec26                	sd	s1,24(sp)
    80002802:	e84a                	sd	s2,16(sp)
    80002804:	e44e                	sd	s3,8(sp)
    80002806:	e052                	sd	s4,0(sp)
    80002808:	1800                	addi	s0,sp,48
    8000280a:	84aa                	mv	s1,a0
    8000280c:	892e                	mv	s2,a1
    8000280e:	89b2                	mv	s3,a2
    80002810:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002812:	fffff097          	auipc	ra,0xfffff
    80002816:	3a2080e7          	jalr	930(ra) # 80001bb4 <myproc>
  if(user_dst){
    8000281a:	c08d                	beqz	s1,8000283c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000281c:	86d2                	mv	a3,s4
    8000281e:	864e                	mv	a2,s3
    80002820:	85ca                	mv	a1,s2
    80002822:	6928                	ld	a0,80(a0)
    80002824:	fffff097          	auipc	ra,0xfffff
    80002828:	108080e7          	jalr	264(ra) # 8000192c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000282c:	70a2                	ld	ra,40(sp)
    8000282e:	7402                	ld	s0,32(sp)
    80002830:	64e2                	ld	s1,24(sp)
    80002832:	6942                	ld	s2,16(sp)
    80002834:	69a2                	ld	s3,8(sp)
    80002836:	6a02                	ld	s4,0(sp)
    80002838:	6145                	addi	sp,sp,48
    8000283a:	8082                	ret
    memmove((char *)dst, src, len);
    8000283c:	000a061b          	sext.w	a2,s4
    80002840:	85ce                	mv	a1,s3
    80002842:	854a                	mv	a0,s2
    80002844:	ffffe097          	auipc	ra,0xffffe
    80002848:	528080e7          	jalr	1320(ra) # 80000d6c <memmove>
    return 0;
    8000284c:	8526                	mv	a0,s1
    8000284e:	bff9                	j	8000282c <either_copyout+0x32>

0000000080002850 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002850:	7179                	addi	sp,sp,-48
    80002852:	f406                	sd	ra,40(sp)
    80002854:	f022                	sd	s0,32(sp)
    80002856:	ec26                	sd	s1,24(sp)
    80002858:	e84a                	sd	s2,16(sp)
    8000285a:	e44e                	sd	s3,8(sp)
    8000285c:	e052                	sd	s4,0(sp)
    8000285e:	1800                	addi	s0,sp,48
    80002860:	892a                	mv	s2,a0
    80002862:	84ae                	mv	s1,a1
    80002864:	89b2                	mv	s3,a2
    80002866:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002868:	fffff097          	auipc	ra,0xfffff
    8000286c:	34c080e7          	jalr	844(ra) # 80001bb4 <myproc>
  if(user_src){
    80002870:	c08d                	beqz	s1,80002892 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002872:	86d2                	mv	a3,s4
    80002874:	864e                	mv	a2,s3
    80002876:	85ca                	mv	a1,s2
    80002878:	6928                	ld	a0,80(a0)
    8000287a:	fffff097          	auipc	ra,0xfffff
    8000287e:	13e080e7          	jalr	318(ra) # 800019b8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002882:	70a2                	ld	ra,40(sp)
    80002884:	7402                	ld	s0,32(sp)
    80002886:	64e2                	ld	s1,24(sp)
    80002888:	6942                	ld	s2,16(sp)
    8000288a:	69a2                	ld	s3,8(sp)
    8000288c:	6a02                	ld	s4,0(sp)
    8000288e:	6145                	addi	sp,sp,48
    80002890:	8082                	ret
    memmove(dst, (char*)src, len);
    80002892:	000a061b          	sext.w	a2,s4
    80002896:	85ce                	mv	a1,s3
    80002898:	854a                	mv	a0,s2
    8000289a:	ffffe097          	auipc	ra,0xffffe
    8000289e:	4d2080e7          	jalr	1234(ra) # 80000d6c <memmove>
    return 0;
    800028a2:	8526                	mv	a0,s1
    800028a4:	bff9                	j	80002882 <either_copyin+0x32>

00000000800028a6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028a6:	715d                	addi	sp,sp,-80
    800028a8:	e486                	sd	ra,72(sp)
    800028aa:	e0a2                	sd	s0,64(sp)
    800028ac:	fc26                	sd	s1,56(sp)
    800028ae:	f84a                	sd	s2,48(sp)
    800028b0:	f44e                	sd	s3,40(sp)
    800028b2:	f052                	sd	s4,32(sp)
    800028b4:	ec56                	sd	s5,24(sp)
    800028b6:	e85a                	sd	s6,16(sp)
    800028b8:	e45e                	sd	s7,8(sp)
    800028ba:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028bc:	00006517          	auipc	a0,0x6
    800028c0:	80c50513          	addi	a0,a0,-2036 # 800080c8 <digits+0x88>
    800028c4:	ffffe097          	auipc	ra,0xffffe
    800028c8:	cce080e7          	jalr	-818(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028cc:	0000f497          	auipc	s1,0xf
    800028d0:	5fc48493          	addi	s1,s1,1532 # 80011ec8 <proc+0x160>
    800028d4:	00015917          	auipc	s2,0x15
    800028d8:	1f490913          	addi	s2,s2,500 # 80017ac8 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028dc:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800028de:	00006997          	auipc	s3,0x6
    800028e2:	9d298993          	addi	s3,s3,-1582 # 800082b0 <digits+0x270>
    printf("%d %s %s", p->pid, state, p->name);
    800028e6:	00006a97          	auipc	s5,0x6
    800028ea:	9d2a8a93          	addi	s5,s5,-1582 # 800082b8 <digits+0x278>
    printf("\n");
    800028ee:	00005a17          	auipc	s4,0x5
    800028f2:	7daa0a13          	addi	s4,s4,2010 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028f6:	00006b97          	auipc	s7,0x6
    800028fa:	9fab8b93          	addi	s7,s7,-1542 # 800082f0 <states.1738>
    800028fe:	a00d                	j	80002920 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002900:	ed86a583          	lw	a1,-296(a3)
    80002904:	8556                	mv	a0,s5
    80002906:	ffffe097          	auipc	ra,0xffffe
    8000290a:	c8c080e7          	jalr	-884(ra) # 80000592 <printf>
    printf("\n");
    8000290e:	8552                	mv	a0,s4
    80002910:	ffffe097          	auipc	ra,0xffffe
    80002914:	c82080e7          	jalr	-894(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002918:	17048493          	addi	s1,s1,368
    8000291c:	03248163          	beq	s1,s2,8000293e <procdump+0x98>
    if(p->state == UNUSED)
    80002920:	86a6                	mv	a3,s1
    80002922:	eb84a783          	lw	a5,-328(s1)
    80002926:	dbed                	beqz	a5,80002918 <procdump+0x72>
      state = "???";
    80002928:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000292a:	fcfb6be3          	bltu	s6,a5,80002900 <procdump+0x5a>
    8000292e:	1782                	slli	a5,a5,0x20
    80002930:	9381                	srli	a5,a5,0x20
    80002932:	078e                	slli	a5,a5,0x3
    80002934:	97de                	add	a5,a5,s7
    80002936:	6390                	ld	a2,0(a5)
    80002938:	f661                	bnez	a2,80002900 <procdump+0x5a>
      state = "???";
    8000293a:	864e                	mv	a2,s3
    8000293c:	b7d1                	j	80002900 <procdump+0x5a>
  }
}
    8000293e:	60a6                	ld	ra,72(sp)
    80002940:	6406                	ld	s0,64(sp)
    80002942:	74e2                	ld	s1,56(sp)
    80002944:	7942                	ld	s2,48(sp)
    80002946:	79a2                	ld	s3,40(sp)
    80002948:	7a02                	ld	s4,32(sp)
    8000294a:	6ae2                	ld	s5,24(sp)
    8000294c:	6b42                	ld	s6,16(sp)
    8000294e:	6ba2                	ld	s7,8(sp)
    80002950:	6161                	addi	sp,sp,80
    80002952:	8082                	ret

0000000080002954 <swtch>:
    80002954:	00153023          	sd	ra,0(a0)
    80002958:	00253423          	sd	sp,8(a0)
    8000295c:	e900                	sd	s0,16(a0)
    8000295e:	ed04                	sd	s1,24(a0)
    80002960:	03253023          	sd	s2,32(a0)
    80002964:	03353423          	sd	s3,40(a0)
    80002968:	03453823          	sd	s4,48(a0)
    8000296c:	03553c23          	sd	s5,56(a0)
    80002970:	05653023          	sd	s6,64(a0)
    80002974:	05753423          	sd	s7,72(a0)
    80002978:	05853823          	sd	s8,80(a0)
    8000297c:	05953c23          	sd	s9,88(a0)
    80002980:	07a53023          	sd	s10,96(a0)
    80002984:	07b53423          	sd	s11,104(a0)
    80002988:	0005b083          	ld	ra,0(a1)
    8000298c:	0085b103          	ld	sp,8(a1)
    80002990:	6980                	ld	s0,16(a1)
    80002992:	6d84                	ld	s1,24(a1)
    80002994:	0205b903          	ld	s2,32(a1)
    80002998:	0285b983          	ld	s3,40(a1)
    8000299c:	0305ba03          	ld	s4,48(a1)
    800029a0:	0385ba83          	ld	s5,56(a1)
    800029a4:	0405bb03          	ld	s6,64(a1)
    800029a8:	0485bb83          	ld	s7,72(a1)
    800029ac:	0505bc03          	ld	s8,80(a1)
    800029b0:	0585bc83          	ld	s9,88(a1)
    800029b4:	0605bd03          	ld	s10,96(a1)
    800029b8:	0685bd83          	ld	s11,104(a1)
    800029bc:	8082                	ret

00000000800029be <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029be:	1141                	addi	sp,sp,-16
    800029c0:	e406                	sd	ra,8(sp)
    800029c2:	e022                	sd	s0,0(sp)
    800029c4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029c6:	00006597          	auipc	a1,0x6
    800029ca:	95258593          	addi	a1,a1,-1710 # 80008318 <states.1738+0x28>
    800029ce:	00015517          	auipc	a0,0x15
    800029d2:	f9a50513          	addi	a0,a0,-102 # 80017968 <tickslock>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	1aa080e7          	jalr	426(ra) # 80000b80 <initlock>
}
    800029de:	60a2                	ld	ra,8(sp)
    800029e0:	6402                	ld	s0,0(sp)
    800029e2:	0141                	addi	sp,sp,16
    800029e4:	8082                	ret

00000000800029e6 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800029e6:	1141                	addi	sp,sp,-16
    800029e8:	e422                	sd	s0,8(sp)
    800029ea:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029ec:	00003797          	auipc	a5,0x3
    800029f0:	51478793          	addi	a5,a5,1300 # 80005f00 <kernelvec>
    800029f4:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029f8:	6422                	ld	s0,8(sp)
    800029fa:	0141                	addi	sp,sp,16
    800029fc:	8082                	ret

00000000800029fe <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800029fe:	1141                	addi	sp,sp,-16
    80002a00:	e406                	sd	ra,8(sp)
    80002a02:	e022                	sd	s0,0(sp)
    80002a04:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a06:	fffff097          	auipc	ra,0xfffff
    80002a0a:	1ae080e7          	jalr	430(ra) # 80001bb4 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a0e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a12:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a14:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a18:	00004617          	auipc	a2,0x4
    80002a1c:	5e860613          	addi	a2,a2,1512 # 80007000 <_trampoline>
    80002a20:	00004697          	auipc	a3,0x4
    80002a24:	5e068693          	addi	a3,a3,1504 # 80007000 <_trampoline>
    80002a28:	8e91                	sub	a3,a3,a2
    80002a2a:	040007b7          	lui	a5,0x4000
    80002a2e:	17fd                	addi	a5,a5,-1
    80002a30:	07b2                	slli	a5,a5,0xc
    80002a32:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a34:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a38:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a3a:	180026f3          	csrr	a3,satp
    80002a3e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a40:	7138                	ld	a4,96(a0)
    80002a42:	6134                	ld	a3,64(a0)
    80002a44:	6585                	lui	a1,0x1
    80002a46:	96ae                	add	a3,a3,a1
    80002a48:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a4a:	7138                	ld	a4,96(a0)
    80002a4c:	00000697          	auipc	a3,0x0
    80002a50:	13868693          	addi	a3,a3,312 # 80002b84 <usertrap>
    80002a54:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a56:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a58:	8692                	mv	a3,tp
    80002a5a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a5c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a60:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a64:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a68:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a6c:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a6e:	6f18                	ld	a4,24(a4)
    80002a70:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a74:	692c                	ld	a1,80(a0)
    80002a76:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a78:	00004717          	auipc	a4,0x4
    80002a7c:	61870713          	addi	a4,a4,1560 # 80007090 <userret>
    80002a80:	8f11                	sub	a4,a4,a2
    80002a82:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002a84:	577d                	li	a4,-1
    80002a86:	177e                	slli	a4,a4,0x3f
    80002a88:	8dd9                	or	a1,a1,a4
    80002a8a:	02000537          	lui	a0,0x2000
    80002a8e:	157d                	addi	a0,a0,-1
    80002a90:	0536                	slli	a0,a0,0xd
    80002a92:	9782                	jalr	a5
}
    80002a94:	60a2                	ld	ra,8(sp)
    80002a96:	6402                	ld	s0,0(sp)
    80002a98:	0141                	addi	sp,sp,16
    80002a9a:	8082                	ret

0000000080002a9c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002a9c:	1101                	addi	sp,sp,-32
    80002a9e:	ec06                	sd	ra,24(sp)
    80002aa0:	e822                	sd	s0,16(sp)
    80002aa2:	e426                	sd	s1,8(sp)
    80002aa4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002aa6:	00015497          	auipc	s1,0x15
    80002aaa:	ec248493          	addi	s1,s1,-318 # 80017968 <tickslock>
    80002aae:	8526                	mv	a0,s1
    80002ab0:	ffffe097          	auipc	ra,0xffffe
    80002ab4:	160080e7          	jalr	352(ra) # 80000c10 <acquire>
  ticks++;
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	56850513          	addi	a0,a0,1384 # 80009020 <ticks>
    80002ac0:	411c                	lw	a5,0(a0)
    80002ac2:	2785                	addiw	a5,a5,1
    80002ac4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ac6:	00000097          	auipc	ra,0x0
    80002aca:	c58080e7          	jalr	-936(ra) # 8000271e <wakeup>
  release(&tickslock);
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	1f4080e7          	jalr	500(ra) # 80000cc4 <release>
}
    80002ad8:	60e2                	ld	ra,24(sp)
    80002ada:	6442                	ld	s0,16(sp)
    80002adc:	64a2                	ld	s1,8(sp)
    80002ade:	6105                	addi	sp,sp,32
    80002ae0:	8082                	ret

0000000080002ae2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002ae2:	1101                	addi	sp,sp,-32
    80002ae4:	ec06                	sd	ra,24(sp)
    80002ae6:	e822                	sd	s0,16(sp)
    80002ae8:	e426                	sd	s1,8(sp)
    80002aea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002af0:	00074d63          	bltz	a4,80002b0a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002af4:	57fd                	li	a5,-1
    80002af6:	17fe                	slli	a5,a5,0x3f
    80002af8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002afa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002afc:	06f70363          	beq	a4,a5,80002b62 <devintr+0x80>
  }
}
    80002b00:	60e2                	ld	ra,24(sp)
    80002b02:	6442                	ld	s0,16(sp)
    80002b04:	64a2                	ld	s1,8(sp)
    80002b06:	6105                	addi	sp,sp,32
    80002b08:	8082                	ret
     (scause & 0xff) == 9){
    80002b0a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b0e:	46a5                	li	a3,9
    80002b10:	fed792e3          	bne	a5,a3,80002af4 <devintr+0x12>
    int irq = plic_claim();
    80002b14:	00003097          	auipc	ra,0x3
    80002b18:	4f4080e7          	jalr	1268(ra) # 80006008 <plic_claim>
    80002b1c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b1e:	47a9                	li	a5,10
    80002b20:	02f50763          	beq	a0,a5,80002b4e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b24:	4785                	li	a5,1
    80002b26:	02f50963          	beq	a0,a5,80002b58 <devintr+0x76>
    return 1;
    80002b2a:	4505                	li	a0,1
    } else if(irq){
    80002b2c:	d8f1                	beqz	s1,80002b00 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b2e:	85a6                	mv	a1,s1
    80002b30:	00005517          	auipc	a0,0x5
    80002b34:	7f050513          	addi	a0,a0,2032 # 80008320 <states.1738+0x30>
    80002b38:	ffffe097          	auipc	ra,0xffffe
    80002b3c:	a5a080e7          	jalr	-1446(ra) # 80000592 <printf>
      plic_complete(irq);
    80002b40:	8526                	mv	a0,s1
    80002b42:	00003097          	auipc	ra,0x3
    80002b46:	4ea080e7          	jalr	1258(ra) # 8000602c <plic_complete>
    return 1;
    80002b4a:	4505                	li	a0,1
    80002b4c:	bf55                	j	80002b00 <devintr+0x1e>
      uartintr();
    80002b4e:	ffffe097          	auipc	ra,0xffffe
    80002b52:	e86080e7          	jalr	-378(ra) # 800009d4 <uartintr>
    80002b56:	b7ed                	j	80002b40 <devintr+0x5e>
      virtio_disk_intr();
    80002b58:	00004097          	auipc	ra,0x4
    80002b5c:	96e080e7          	jalr	-1682(ra) # 800064c6 <virtio_disk_intr>
    80002b60:	b7c5                	j	80002b40 <devintr+0x5e>
    if(cpuid() == 0){
    80002b62:	fffff097          	auipc	ra,0xfffff
    80002b66:	026080e7          	jalr	38(ra) # 80001b88 <cpuid>
    80002b6a:	c901                	beqz	a0,80002b7a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b6c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b70:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b72:	14479073          	csrw	sip,a5
    return 2;
    80002b76:	4509                	li	a0,2
    80002b78:	b761                	j	80002b00 <devintr+0x1e>
      clockintr();
    80002b7a:	00000097          	auipc	ra,0x0
    80002b7e:	f22080e7          	jalr	-222(ra) # 80002a9c <clockintr>
    80002b82:	b7ed                	j	80002b6c <devintr+0x8a>

0000000080002b84 <usertrap>:
{
    80002b84:	1101                	addi	sp,sp,-32
    80002b86:	ec06                	sd	ra,24(sp)
    80002b88:	e822                	sd	s0,16(sp)
    80002b8a:	e426                	sd	s1,8(sp)
    80002b8c:	e04a                	sd	s2,0(sp)
    80002b8e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b90:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002b94:	1007f793          	andi	a5,a5,256
    80002b98:	e3ad                	bnez	a5,80002bfa <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b9a:	00003797          	auipc	a5,0x3
    80002b9e:	36678793          	addi	a5,a5,870 # 80005f00 <kernelvec>
    80002ba2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002ba6:	fffff097          	auipc	ra,0xfffff
    80002baa:	00e080e7          	jalr	14(ra) # 80001bb4 <myproc>
    80002bae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bb0:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bb2:	14102773          	csrr	a4,sepc
    80002bb6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bb8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bbc:	47a1                	li	a5,8
    80002bbe:	04f71c63          	bne	a4,a5,80002c16 <usertrap+0x92>
    if(p->killed)
    80002bc2:	591c                	lw	a5,48(a0)
    80002bc4:	e3b9                	bnez	a5,80002c0a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002bc6:	70b8                	ld	a4,96(s1)
    80002bc8:	6f1c                	ld	a5,24(a4)
    80002bca:	0791                	addi	a5,a5,4
    80002bcc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bce:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bd2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bd6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bda:	00000097          	auipc	ra,0x0
    80002bde:	2e0080e7          	jalr	736(ra) # 80002eba <syscall>
  if(p->killed)
    80002be2:	589c                	lw	a5,48(s1)
    80002be4:	ebc1                	bnez	a5,80002c74 <usertrap+0xf0>
  usertrapret();
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	e18080e7          	jalr	-488(ra) # 800029fe <usertrapret>
}
    80002bee:	60e2                	ld	ra,24(sp)
    80002bf0:	6442                	ld	s0,16(sp)
    80002bf2:	64a2                	ld	s1,8(sp)
    80002bf4:	6902                	ld	s2,0(sp)
    80002bf6:	6105                	addi	sp,sp,32
    80002bf8:	8082                	ret
    panic("usertrap: not from user mode");
    80002bfa:	00005517          	auipc	a0,0x5
    80002bfe:	74650513          	addi	a0,a0,1862 # 80008340 <states.1738+0x50>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	946080e7          	jalr	-1722(ra) # 80000548 <panic>
      exit(-1);
    80002c0a:	557d                	li	a0,-1
    80002c0c:	00000097          	auipc	ra,0x0
    80002c10:	846080e7          	jalr	-1978(ra) # 80002452 <exit>
    80002c14:	bf4d                	j	80002bc6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c16:	00000097          	auipc	ra,0x0
    80002c1a:	ecc080e7          	jalr	-308(ra) # 80002ae2 <devintr>
    80002c1e:	892a                	mv	s2,a0
    80002c20:	c501                	beqz	a0,80002c28 <usertrap+0xa4>
  if(p->killed)
    80002c22:	589c                	lw	a5,48(s1)
    80002c24:	c3a1                	beqz	a5,80002c64 <usertrap+0xe0>
    80002c26:	a815                	j	80002c5a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c28:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c2c:	5c90                	lw	a2,56(s1)
    80002c2e:	00005517          	auipc	a0,0x5
    80002c32:	73250513          	addi	a0,a0,1842 # 80008360 <states.1738+0x70>
    80002c36:	ffffe097          	auipc	ra,0xffffe
    80002c3a:	95c080e7          	jalr	-1700(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c3e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c42:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c46:	00005517          	auipc	a0,0x5
    80002c4a:	74a50513          	addi	a0,a0,1866 # 80008390 <states.1738+0xa0>
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	944080e7          	jalr	-1724(ra) # 80000592 <printf>
    p->killed = 1;
    80002c56:	4785                	li	a5,1
    80002c58:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002c5a:	557d                	li	a0,-1
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	7f6080e7          	jalr	2038(ra) # 80002452 <exit>
  if(which_dev == 2)
    80002c64:	4789                	li	a5,2
    80002c66:	f8f910e3          	bne	s2,a5,80002be6 <usertrap+0x62>
    yield();
    80002c6a:	00000097          	auipc	ra,0x0
    80002c6e:	8f2080e7          	jalr	-1806(ra) # 8000255c <yield>
    80002c72:	bf95                	j	80002be6 <usertrap+0x62>
  int which_dev = 0;
    80002c74:	4901                	li	s2,0
    80002c76:	b7d5                	j	80002c5a <usertrap+0xd6>

0000000080002c78 <kerneltrap>:
{
    80002c78:	7179                	addi	sp,sp,-48
    80002c7a:	f406                	sd	ra,40(sp)
    80002c7c:	f022                	sd	s0,32(sp)
    80002c7e:	ec26                	sd	s1,24(sp)
    80002c80:	e84a                	sd	s2,16(sp)
    80002c82:	e44e                	sd	s3,8(sp)
    80002c84:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c86:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c8a:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c8e:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c92:	1004f793          	andi	a5,s1,256
    80002c96:	cb85                	beqz	a5,80002cc6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c9c:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c9e:	ef85                	bnez	a5,80002cd6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002ca0:	00000097          	auipc	ra,0x0
    80002ca4:	e42080e7          	jalr	-446(ra) # 80002ae2 <devintr>
    80002ca8:	cd1d                	beqz	a0,80002ce6 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002caa:	4789                	li	a5,2
    80002cac:	06f50a63          	beq	a0,a5,80002d20 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cb0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cb4:	10049073          	csrw	sstatus,s1
}
    80002cb8:	70a2                	ld	ra,40(sp)
    80002cba:	7402                	ld	s0,32(sp)
    80002cbc:	64e2                	ld	s1,24(sp)
    80002cbe:	6942                	ld	s2,16(sp)
    80002cc0:	69a2                	ld	s3,8(sp)
    80002cc2:	6145                	addi	sp,sp,48
    80002cc4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	6ea50513          	addi	a0,a0,1770 # 800083b0 <states.1738+0xc0>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	87a080e7          	jalr	-1926(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	70250513          	addi	a0,a0,1794 # 800083d8 <states.1738+0xe8>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	86a080e7          	jalr	-1942(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002ce6:	85ce                	mv	a1,s3
    80002ce8:	00005517          	auipc	a0,0x5
    80002cec:	71050513          	addi	a0,a0,1808 # 800083f8 <states.1738+0x108>
    80002cf0:	ffffe097          	auipc	ra,0xffffe
    80002cf4:	8a2080e7          	jalr	-1886(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cf8:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cfc:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d00:	00005517          	auipc	a0,0x5
    80002d04:	70850513          	addi	a0,a0,1800 # 80008408 <states.1738+0x118>
    80002d08:	ffffe097          	auipc	ra,0xffffe
    80002d0c:	88a080e7          	jalr	-1910(ra) # 80000592 <printf>
    panic("kerneltrap");
    80002d10:	00005517          	auipc	a0,0x5
    80002d14:	71050513          	addi	a0,a0,1808 # 80008420 <states.1738+0x130>
    80002d18:	ffffe097          	auipc	ra,0xffffe
    80002d1c:	830080e7          	jalr	-2000(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d20:	fffff097          	auipc	ra,0xfffff
    80002d24:	e94080e7          	jalr	-364(ra) # 80001bb4 <myproc>
    80002d28:	d541                	beqz	a0,80002cb0 <kerneltrap+0x38>
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	e8a080e7          	jalr	-374(ra) # 80001bb4 <myproc>
    80002d32:	4d18                	lw	a4,24(a0)
    80002d34:	478d                	li	a5,3
    80002d36:	f6f71de3          	bne	a4,a5,80002cb0 <kerneltrap+0x38>
    yield();
    80002d3a:	00000097          	auipc	ra,0x0
    80002d3e:	822080e7          	jalr	-2014(ra) # 8000255c <yield>
    80002d42:	b7bd                	j	80002cb0 <kerneltrap+0x38>

0000000080002d44 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d44:	1101                	addi	sp,sp,-32
    80002d46:	ec06                	sd	ra,24(sp)
    80002d48:	e822                	sd	s0,16(sp)
    80002d4a:	e426                	sd	s1,8(sp)
    80002d4c:	1000                	addi	s0,sp,32
    80002d4e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d50:	fffff097          	auipc	ra,0xfffff
    80002d54:	e64080e7          	jalr	-412(ra) # 80001bb4 <myproc>
  switch (n) {
    80002d58:	4795                	li	a5,5
    80002d5a:	0497e163          	bltu	a5,s1,80002d9c <argraw+0x58>
    80002d5e:	048a                	slli	s1,s1,0x2
    80002d60:	00005717          	auipc	a4,0x5
    80002d64:	6f870713          	addi	a4,a4,1784 # 80008458 <states.1738+0x168>
    80002d68:	94ba                	add	s1,s1,a4
    80002d6a:	409c                	lw	a5,0(s1)
    80002d6c:	97ba                	add	a5,a5,a4
    80002d6e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d70:	713c                	ld	a5,96(a0)
    80002d72:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d74:	60e2                	ld	ra,24(sp)
    80002d76:	6442                	ld	s0,16(sp)
    80002d78:	64a2                	ld	s1,8(sp)
    80002d7a:	6105                	addi	sp,sp,32
    80002d7c:	8082                	ret
    return p->trapframe->a1;
    80002d7e:	713c                	ld	a5,96(a0)
    80002d80:	7fa8                	ld	a0,120(a5)
    80002d82:	bfcd                	j	80002d74 <argraw+0x30>
    return p->trapframe->a2;
    80002d84:	713c                	ld	a5,96(a0)
    80002d86:	63c8                	ld	a0,128(a5)
    80002d88:	b7f5                	j	80002d74 <argraw+0x30>
    return p->trapframe->a3;
    80002d8a:	713c                	ld	a5,96(a0)
    80002d8c:	67c8                	ld	a0,136(a5)
    80002d8e:	b7dd                	j	80002d74 <argraw+0x30>
    return p->trapframe->a4;
    80002d90:	713c                	ld	a5,96(a0)
    80002d92:	6bc8                	ld	a0,144(a5)
    80002d94:	b7c5                	j	80002d74 <argraw+0x30>
    return p->trapframe->a5;
    80002d96:	713c                	ld	a5,96(a0)
    80002d98:	6fc8                	ld	a0,152(a5)
    80002d9a:	bfe9                	j	80002d74 <argraw+0x30>
  panic("argraw");
    80002d9c:	00005517          	auipc	a0,0x5
    80002da0:	69450513          	addi	a0,a0,1684 # 80008430 <states.1738+0x140>
    80002da4:	ffffd097          	auipc	ra,0xffffd
    80002da8:	7a4080e7          	jalr	1956(ra) # 80000548 <panic>

0000000080002dac <fetchaddr>:
{
    80002dac:	1101                	addi	sp,sp,-32
    80002dae:	ec06                	sd	ra,24(sp)
    80002db0:	e822                	sd	s0,16(sp)
    80002db2:	e426                	sd	s1,8(sp)
    80002db4:	e04a                	sd	s2,0(sp)
    80002db6:	1000                	addi	s0,sp,32
    80002db8:	84aa                	mv	s1,a0
    80002dba:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	df8080e7          	jalr	-520(ra) # 80001bb4 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002dc4:	653c                	ld	a5,72(a0)
    80002dc6:	02f4f863          	bgeu	s1,a5,80002df6 <fetchaddr+0x4a>
    80002dca:	00848713          	addi	a4,s1,8
    80002dce:	02e7e663          	bltu	a5,a4,80002dfa <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dd2:	46a1                	li	a3,8
    80002dd4:	8626                	mv	a2,s1
    80002dd6:	85ca                	mv	a1,s2
    80002dd8:	6928                	ld	a0,80(a0)
    80002dda:	fffff097          	auipc	ra,0xfffff
    80002dde:	bde080e7          	jalr	-1058(ra) # 800019b8 <copyin>
    80002de2:	00a03533          	snez	a0,a0
    80002de6:	40a00533          	neg	a0,a0
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	64a2                	ld	s1,8(sp)
    80002df0:	6902                	ld	s2,0(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret
    return -1;
    80002df6:	557d                	li	a0,-1
    80002df8:	bfcd                	j	80002dea <fetchaddr+0x3e>
    80002dfa:	557d                	li	a0,-1
    80002dfc:	b7fd                	j	80002dea <fetchaddr+0x3e>

0000000080002dfe <fetchstr>:
{
    80002dfe:	7179                	addi	sp,sp,-48
    80002e00:	f406                	sd	ra,40(sp)
    80002e02:	f022                	sd	s0,32(sp)
    80002e04:	ec26                	sd	s1,24(sp)
    80002e06:	e84a                	sd	s2,16(sp)
    80002e08:	e44e                	sd	s3,8(sp)
    80002e0a:	1800                	addi	s0,sp,48
    80002e0c:	892a                	mv	s2,a0
    80002e0e:	84ae                	mv	s1,a1
    80002e10:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e12:	fffff097          	auipc	ra,0xfffff
    80002e16:	da2080e7          	jalr	-606(ra) # 80001bb4 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e1a:	86ce                	mv	a3,s3
    80002e1c:	864a                	mv	a2,s2
    80002e1e:	85a6                	mv	a1,s1
    80002e20:	6928                	ld	a0,80(a0)
    80002e22:	fffff097          	auipc	ra,0xfffff
    80002e26:	bae080e7          	jalr	-1106(ra) # 800019d0 <copyinstr>
  if(err < 0)
    80002e2a:	00054763          	bltz	a0,80002e38 <fetchstr+0x3a>
  return strlen(buf);
    80002e2e:	8526                	mv	a0,s1
    80002e30:	ffffe097          	auipc	ra,0xffffe
    80002e34:	064080e7          	jalr	100(ra) # 80000e94 <strlen>
}
    80002e38:	70a2                	ld	ra,40(sp)
    80002e3a:	7402                	ld	s0,32(sp)
    80002e3c:	64e2                	ld	s1,24(sp)
    80002e3e:	6942                	ld	s2,16(sp)
    80002e40:	69a2                	ld	s3,8(sp)
    80002e42:	6145                	addi	sp,sp,48
    80002e44:	8082                	ret

0000000080002e46 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e46:	1101                	addi	sp,sp,-32
    80002e48:	ec06                	sd	ra,24(sp)
    80002e4a:	e822                	sd	s0,16(sp)
    80002e4c:	e426                	sd	s1,8(sp)
    80002e4e:	1000                	addi	s0,sp,32
    80002e50:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e52:	00000097          	auipc	ra,0x0
    80002e56:	ef2080e7          	jalr	-270(ra) # 80002d44 <argraw>
    80002e5a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e5c:	4501                	li	a0,0
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e68:	1101                	addi	sp,sp,-32
    80002e6a:	ec06                	sd	ra,24(sp)
    80002e6c:	e822                	sd	s0,16(sp)
    80002e6e:	e426                	sd	s1,8(sp)
    80002e70:	1000                	addi	s0,sp,32
    80002e72:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	ed0080e7          	jalr	-304(ra) # 80002d44 <argraw>
    80002e7c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e7e:	4501                	li	a0,0
    80002e80:	60e2                	ld	ra,24(sp)
    80002e82:	6442                	ld	s0,16(sp)
    80002e84:	64a2                	ld	s1,8(sp)
    80002e86:	6105                	addi	sp,sp,32
    80002e88:	8082                	ret

0000000080002e8a <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e8a:	1101                	addi	sp,sp,-32
    80002e8c:	ec06                	sd	ra,24(sp)
    80002e8e:	e822                	sd	s0,16(sp)
    80002e90:	e426                	sd	s1,8(sp)
    80002e92:	e04a                	sd	s2,0(sp)
    80002e94:	1000                	addi	s0,sp,32
    80002e96:	84ae                	mv	s1,a1
    80002e98:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e9a:	00000097          	auipc	ra,0x0
    80002e9e:	eaa080e7          	jalr	-342(ra) # 80002d44 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ea2:	864a                	mv	a2,s2
    80002ea4:	85a6                	mv	a1,s1
    80002ea6:	00000097          	auipc	ra,0x0
    80002eaa:	f58080e7          	jalr	-168(ra) # 80002dfe <fetchstr>
}
    80002eae:	60e2                	ld	ra,24(sp)
    80002eb0:	6442                	ld	s0,16(sp)
    80002eb2:	64a2                	ld	s1,8(sp)
    80002eb4:	6902                	ld	s2,0(sp)
    80002eb6:	6105                	addi	sp,sp,32
    80002eb8:	8082                	ret

0000000080002eba <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002eba:	1101                	addi	sp,sp,-32
    80002ebc:	ec06                	sd	ra,24(sp)
    80002ebe:	e822                	sd	s0,16(sp)
    80002ec0:	e426                	sd	s1,8(sp)
    80002ec2:	e04a                	sd	s2,0(sp)
    80002ec4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	cee080e7          	jalr	-786(ra) # 80001bb4 <myproc>
    80002ece:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ed0:	06053903          	ld	s2,96(a0)
    80002ed4:	0a893783          	ld	a5,168(s2)
    80002ed8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002edc:	37fd                	addiw	a5,a5,-1
    80002ede:	4751                	li	a4,20
    80002ee0:	00f76f63          	bltu	a4,a5,80002efe <syscall+0x44>
    80002ee4:	00369713          	slli	a4,a3,0x3
    80002ee8:	00005797          	auipc	a5,0x5
    80002eec:	58878793          	addi	a5,a5,1416 # 80008470 <syscalls>
    80002ef0:	97ba                	add	a5,a5,a4
    80002ef2:	639c                	ld	a5,0(a5)
    80002ef4:	c789                	beqz	a5,80002efe <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ef6:	9782                	jalr	a5
    80002ef8:	06a93823          	sd	a0,112(s2)
    80002efc:	a839                	j	80002f1a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002efe:	16048613          	addi	a2,s1,352
    80002f02:	5c8c                	lw	a1,56(s1)
    80002f04:	00005517          	auipc	a0,0x5
    80002f08:	53450513          	addi	a0,a0,1332 # 80008438 <states.1738+0x148>
    80002f0c:	ffffd097          	auipc	ra,0xffffd
    80002f10:	686080e7          	jalr	1670(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f14:	70bc                	ld	a5,96(s1)
    80002f16:	577d                	li	a4,-1
    80002f18:	fbb8                	sd	a4,112(a5)
  }
}
    80002f1a:	60e2                	ld	ra,24(sp)
    80002f1c:	6442                	ld	s0,16(sp)
    80002f1e:	64a2                	ld	s1,8(sp)
    80002f20:	6902                	ld	s2,0(sp)
    80002f22:	6105                	addi	sp,sp,32
    80002f24:	8082                	ret

0000000080002f26 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f2e:	fec40593          	addi	a1,s0,-20
    80002f32:	4501                	li	a0,0
    80002f34:	00000097          	auipc	ra,0x0
    80002f38:	f12080e7          	jalr	-238(ra) # 80002e46 <argint>
    return -1;
    80002f3c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f3e:	00054963          	bltz	a0,80002f50 <sys_exit+0x2a>
  exit(n);
    80002f42:	fec42503          	lw	a0,-20(s0)
    80002f46:	fffff097          	auipc	ra,0xfffff
    80002f4a:	50c080e7          	jalr	1292(ra) # 80002452 <exit>
  return 0;  // not reached
    80002f4e:	4781                	li	a5,0
}
    80002f50:	853e                	mv	a0,a5
    80002f52:	60e2                	ld	ra,24(sp)
    80002f54:	6442                	ld	s0,16(sp)
    80002f56:	6105                	addi	sp,sp,32
    80002f58:	8082                	ret

0000000080002f5a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f5a:	1141                	addi	sp,sp,-16
    80002f5c:	e406                	sd	ra,8(sp)
    80002f5e:	e022                	sd	s0,0(sp)
    80002f60:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f62:	fffff097          	auipc	ra,0xfffff
    80002f66:	c52080e7          	jalr	-942(ra) # 80001bb4 <myproc>
}
    80002f6a:	5d08                	lw	a0,56(a0)
    80002f6c:	60a2                	ld	ra,8(sp)
    80002f6e:	6402                	ld	s0,0(sp)
    80002f70:	0141                	addi	sp,sp,16
    80002f72:	8082                	ret

0000000080002f74 <sys_fork>:

uint64
sys_fork(void)
{
    80002f74:	1141                	addi	sp,sp,-16
    80002f76:	e406                	sd	ra,8(sp)
    80002f78:	e022                	sd	s0,0(sp)
    80002f7a:	0800                	addi	s0,sp,16
  return fork();
    80002f7c:	fffff097          	auipc	ra,0xfffff
    80002f80:	164080e7          	jalr	356(ra) # 800020e0 <fork>
}
    80002f84:	60a2                	ld	ra,8(sp)
    80002f86:	6402                	ld	s0,0(sp)
    80002f88:	0141                	addi	sp,sp,16
    80002f8a:	8082                	ret

0000000080002f8c <sys_wait>:

uint64
sys_wait(void)
{
    80002f8c:	1101                	addi	sp,sp,-32
    80002f8e:	ec06                	sd	ra,24(sp)
    80002f90:	e822                	sd	s0,16(sp)
    80002f92:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f94:	fe840593          	addi	a1,s0,-24
    80002f98:	4501                	li	a0,0
    80002f9a:	00000097          	auipc	ra,0x0
    80002f9e:	ece080e7          	jalr	-306(ra) # 80002e68 <argaddr>
    80002fa2:	87aa                	mv	a5,a0
    return -1;
    80002fa4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fa6:	0007c863          	bltz	a5,80002fb6 <sys_wait+0x2a>
  return wait(p);
    80002faa:	fe843503          	ld	a0,-24(s0)
    80002fae:	fffff097          	auipc	ra,0xfffff
    80002fb2:	668080e7          	jalr	1640(ra) # 80002616 <wait>
}
    80002fb6:	60e2                	ld	ra,24(sp)
    80002fb8:	6442                	ld	s0,16(sp)
    80002fba:	6105                	addi	sp,sp,32
    80002fbc:	8082                	ret

0000000080002fbe <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fbe:	7179                	addi	sp,sp,-48
    80002fc0:	f406                	sd	ra,40(sp)
    80002fc2:	f022                	sd	s0,32(sp)
    80002fc4:	ec26                	sd	s1,24(sp)
    80002fc6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fc8:	fdc40593          	addi	a1,s0,-36
    80002fcc:	4501                	li	a0,0
    80002fce:	00000097          	auipc	ra,0x0
    80002fd2:	e78080e7          	jalr	-392(ra) # 80002e46 <argint>
    80002fd6:	87aa                	mv	a5,a0
    return -1;
    80002fd8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fda:	0207c063          	bltz	a5,80002ffa <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fde:	fffff097          	auipc	ra,0xfffff
    80002fe2:	bd6080e7          	jalr	-1066(ra) # 80001bb4 <myproc>
    80002fe6:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fe8:	fdc42503          	lw	a0,-36(s0)
    80002fec:	fffff097          	auipc	ra,0xfffff
    80002ff0:	00c080e7          	jalr	12(ra) # 80001ff8 <growproc>
    80002ff4:	00054863          	bltz	a0,80003004 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ff8:	8526                	mv	a0,s1
}
    80002ffa:	70a2                	ld	ra,40(sp)
    80002ffc:	7402                	ld	s0,32(sp)
    80002ffe:	64e2                	ld	s1,24(sp)
    80003000:	6145                	addi	sp,sp,48
    80003002:	8082                	ret
    return -1;
    80003004:	557d                	li	a0,-1
    80003006:	bfd5                	j	80002ffa <sys_sbrk+0x3c>

0000000080003008 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003008:	7139                	addi	sp,sp,-64
    8000300a:	fc06                	sd	ra,56(sp)
    8000300c:	f822                	sd	s0,48(sp)
    8000300e:	f426                	sd	s1,40(sp)
    80003010:	f04a                	sd	s2,32(sp)
    80003012:	ec4e                	sd	s3,24(sp)
    80003014:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003016:	fcc40593          	addi	a1,s0,-52
    8000301a:	4501                	li	a0,0
    8000301c:	00000097          	auipc	ra,0x0
    80003020:	e2a080e7          	jalr	-470(ra) # 80002e46 <argint>
    return -1;
    80003024:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003026:	06054563          	bltz	a0,80003090 <sys_sleep+0x88>
  acquire(&tickslock);
    8000302a:	00015517          	auipc	a0,0x15
    8000302e:	93e50513          	addi	a0,a0,-1730 # 80017968 <tickslock>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	bde080e7          	jalr	-1058(ra) # 80000c10 <acquire>
  ticks0 = ticks;
    8000303a:	00006917          	auipc	s2,0x6
    8000303e:	fe692903          	lw	s2,-26(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003042:	fcc42783          	lw	a5,-52(s0)
    80003046:	cf85                	beqz	a5,8000307e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003048:	00015997          	auipc	s3,0x15
    8000304c:	92098993          	addi	s3,s3,-1760 # 80017968 <tickslock>
    80003050:	00006497          	auipc	s1,0x6
    80003054:	fd048493          	addi	s1,s1,-48 # 80009020 <ticks>
    if(myproc()->killed){
    80003058:	fffff097          	auipc	ra,0xfffff
    8000305c:	b5c080e7          	jalr	-1188(ra) # 80001bb4 <myproc>
    80003060:	591c                	lw	a5,48(a0)
    80003062:	ef9d                	bnez	a5,800030a0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003064:	85ce                	mv	a1,s3
    80003066:	8526                	mv	a0,s1
    80003068:	fffff097          	auipc	ra,0xfffff
    8000306c:	530080e7          	jalr	1328(ra) # 80002598 <sleep>
  while(ticks - ticks0 < n){
    80003070:	409c                	lw	a5,0(s1)
    80003072:	412787bb          	subw	a5,a5,s2
    80003076:	fcc42703          	lw	a4,-52(s0)
    8000307a:	fce7efe3          	bltu	a5,a4,80003058 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000307e:	00015517          	auipc	a0,0x15
    80003082:	8ea50513          	addi	a0,a0,-1814 # 80017968 <tickslock>
    80003086:	ffffe097          	auipc	ra,0xffffe
    8000308a:	c3e080e7          	jalr	-962(ra) # 80000cc4 <release>
  return 0;
    8000308e:	4781                	li	a5,0
}
    80003090:	853e                	mv	a0,a5
    80003092:	70e2                	ld	ra,56(sp)
    80003094:	7442                	ld	s0,48(sp)
    80003096:	74a2                	ld	s1,40(sp)
    80003098:	7902                	ld	s2,32(sp)
    8000309a:	69e2                	ld	s3,24(sp)
    8000309c:	6121                	addi	sp,sp,64
    8000309e:	8082                	ret
      release(&tickslock);
    800030a0:	00015517          	auipc	a0,0x15
    800030a4:	8c850513          	addi	a0,a0,-1848 # 80017968 <tickslock>
    800030a8:	ffffe097          	auipc	ra,0xffffe
    800030ac:	c1c080e7          	jalr	-996(ra) # 80000cc4 <release>
      return -1;
    800030b0:	57fd                	li	a5,-1
    800030b2:	bff9                	j	80003090 <sys_sleep+0x88>

00000000800030b4 <sys_kill>:

uint64
sys_kill(void)
{
    800030b4:	1101                	addi	sp,sp,-32
    800030b6:	ec06                	sd	ra,24(sp)
    800030b8:	e822                	sd	s0,16(sp)
    800030ba:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030bc:	fec40593          	addi	a1,s0,-20
    800030c0:	4501                	li	a0,0
    800030c2:	00000097          	auipc	ra,0x0
    800030c6:	d84080e7          	jalr	-636(ra) # 80002e46 <argint>
    800030ca:	87aa                	mv	a5,a0
    return -1;
    800030cc:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ce:	0007c863          	bltz	a5,800030de <sys_kill+0x2a>
  return kill(pid);
    800030d2:	fec42503          	lw	a0,-20(s0)
    800030d6:	fffff097          	auipc	ra,0xfffff
    800030da:	6b2080e7          	jalr	1714(ra) # 80002788 <kill>
}
    800030de:	60e2                	ld	ra,24(sp)
    800030e0:	6442                	ld	s0,16(sp)
    800030e2:	6105                	addi	sp,sp,32
    800030e4:	8082                	ret

00000000800030e6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030e6:	1101                	addi	sp,sp,-32
    800030e8:	ec06                	sd	ra,24(sp)
    800030ea:	e822                	sd	s0,16(sp)
    800030ec:	e426                	sd	s1,8(sp)
    800030ee:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030f0:	00015517          	auipc	a0,0x15
    800030f4:	87850513          	addi	a0,a0,-1928 # 80017968 <tickslock>
    800030f8:	ffffe097          	auipc	ra,0xffffe
    800030fc:	b18080e7          	jalr	-1256(ra) # 80000c10 <acquire>
  xticks = ticks;
    80003100:	00006497          	auipc	s1,0x6
    80003104:	f204a483          	lw	s1,-224(s1) # 80009020 <ticks>
  release(&tickslock);
    80003108:	00015517          	auipc	a0,0x15
    8000310c:	86050513          	addi	a0,a0,-1952 # 80017968 <tickslock>
    80003110:	ffffe097          	auipc	ra,0xffffe
    80003114:	bb4080e7          	jalr	-1100(ra) # 80000cc4 <release>
  return xticks;
}
    80003118:	02049513          	slli	a0,s1,0x20
    8000311c:	9101                	srli	a0,a0,0x20
    8000311e:	60e2                	ld	ra,24(sp)
    80003120:	6442                	ld	s0,16(sp)
    80003122:	64a2                	ld	s1,8(sp)
    80003124:	6105                	addi	sp,sp,32
    80003126:	8082                	ret

0000000080003128 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003128:	7179                	addi	sp,sp,-48
    8000312a:	f406                	sd	ra,40(sp)
    8000312c:	f022                	sd	s0,32(sp)
    8000312e:	ec26                	sd	s1,24(sp)
    80003130:	e84a                	sd	s2,16(sp)
    80003132:	e44e                	sd	s3,8(sp)
    80003134:	e052                	sd	s4,0(sp)
    80003136:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003138:	00005597          	auipc	a1,0x5
    8000313c:	3e858593          	addi	a1,a1,1000 # 80008520 <syscalls+0xb0>
    80003140:	00015517          	auipc	a0,0x15
    80003144:	84050513          	addi	a0,a0,-1984 # 80017980 <bcache>
    80003148:	ffffe097          	auipc	ra,0xffffe
    8000314c:	a38080e7          	jalr	-1480(ra) # 80000b80 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003150:	0001d797          	auipc	a5,0x1d
    80003154:	83078793          	addi	a5,a5,-2000 # 8001f980 <bcache+0x8000>
    80003158:	0001d717          	auipc	a4,0x1d
    8000315c:	a9070713          	addi	a4,a4,-1392 # 8001fbe8 <bcache+0x8268>
    80003160:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003164:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003168:	00015497          	auipc	s1,0x15
    8000316c:	83048493          	addi	s1,s1,-2000 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80003170:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003172:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003174:	00005a17          	auipc	s4,0x5
    80003178:	3b4a0a13          	addi	s4,s4,948 # 80008528 <syscalls+0xb8>
    b->next = bcache.head.next;
    8000317c:	2b893783          	ld	a5,696(s2)
    80003180:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003182:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003186:	85d2                	mv	a1,s4
    80003188:	01048513          	addi	a0,s1,16
    8000318c:	00001097          	auipc	ra,0x1
    80003190:	4ac080e7          	jalr	1196(ra) # 80004638 <initsleeplock>
    bcache.head.next->prev = b;
    80003194:	2b893783          	ld	a5,696(s2)
    80003198:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000319a:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000319e:	45848493          	addi	s1,s1,1112
    800031a2:	fd349de3          	bne	s1,s3,8000317c <binit+0x54>
  }
}
    800031a6:	70a2                	ld	ra,40(sp)
    800031a8:	7402                	ld	s0,32(sp)
    800031aa:	64e2                	ld	s1,24(sp)
    800031ac:	6942                	ld	s2,16(sp)
    800031ae:	69a2                	ld	s3,8(sp)
    800031b0:	6a02                	ld	s4,0(sp)
    800031b2:	6145                	addi	sp,sp,48
    800031b4:	8082                	ret

00000000800031b6 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031b6:	7179                	addi	sp,sp,-48
    800031b8:	f406                	sd	ra,40(sp)
    800031ba:	f022                	sd	s0,32(sp)
    800031bc:	ec26                	sd	s1,24(sp)
    800031be:	e84a                	sd	s2,16(sp)
    800031c0:	e44e                	sd	s3,8(sp)
    800031c2:	1800                	addi	s0,sp,48
    800031c4:	89aa                	mv	s3,a0
    800031c6:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031c8:	00014517          	auipc	a0,0x14
    800031cc:	7b850513          	addi	a0,a0,1976 # 80017980 <bcache>
    800031d0:	ffffe097          	auipc	ra,0xffffe
    800031d4:	a40080e7          	jalr	-1472(ra) # 80000c10 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031d8:	0001d497          	auipc	s1,0x1d
    800031dc:	a604b483          	ld	s1,-1440(s1) # 8001fc38 <bcache+0x82b8>
    800031e0:	0001d797          	auipc	a5,0x1d
    800031e4:	a0878793          	addi	a5,a5,-1528 # 8001fbe8 <bcache+0x8268>
    800031e8:	02f48f63          	beq	s1,a5,80003226 <bread+0x70>
    800031ec:	873e                	mv	a4,a5
    800031ee:	a021                	j	800031f6 <bread+0x40>
    800031f0:	68a4                	ld	s1,80(s1)
    800031f2:	02e48a63          	beq	s1,a4,80003226 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031f6:	449c                	lw	a5,8(s1)
    800031f8:	ff379ce3          	bne	a5,s3,800031f0 <bread+0x3a>
    800031fc:	44dc                	lw	a5,12(s1)
    800031fe:	ff2799e3          	bne	a5,s2,800031f0 <bread+0x3a>
      b->refcnt++;
    80003202:	40bc                	lw	a5,64(s1)
    80003204:	2785                	addiw	a5,a5,1
    80003206:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003208:	00014517          	auipc	a0,0x14
    8000320c:	77850513          	addi	a0,a0,1912 # 80017980 <bcache>
    80003210:	ffffe097          	auipc	ra,0xffffe
    80003214:	ab4080e7          	jalr	-1356(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80003218:	01048513          	addi	a0,s1,16
    8000321c:	00001097          	auipc	ra,0x1
    80003220:	456080e7          	jalr	1110(ra) # 80004672 <acquiresleep>
      return b;
    80003224:	a8b9                	j	80003282 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003226:	0001d497          	auipc	s1,0x1d
    8000322a:	a0a4b483          	ld	s1,-1526(s1) # 8001fc30 <bcache+0x82b0>
    8000322e:	0001d797          	auipc	a5,0x1d
    80003232:	9ba78793          	addi	a5,a5,-1606 # 8001fbe8 <bcache+0x8268>
    80003236:	00f48863          	beq	s1,a5,80003246 <bread+0x90>
    8000323a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000323c:	40bc                	lw	a5,64(s1)
    8000323e:	cf81                	beqz	a5,80003256 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003240:	64a4                	ld	s1,72(s1)
    80003242:	fee49de3          	bne	s1,a4,8000323c <bread+0x86>
  panic("bget: no buffers");
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	2ea50513          	addi	a0,a0,746 # 80008530 <syscalls+0xc0>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>
      b->dev = dev;
    80003256:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000325a:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000325e:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003262:	4785                	li	a5,1
    80003264:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	71a50513          	addi	a0,a0,1818 # 80017980 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	a56080e7          	jalr	-1450(ra) # 80000cc4 <release>
      acquiresleep(&b->lock);
    80003276:	01048513          	addi	a0,s1,16
    8000327a:	00001097          	auipc	ra,0x1
    8000327e:	3f8080e7          	jalr	1016(ra) # 80004672 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003282:	409c                	lw	a5,0(s1)
    80003284:	cb89                	beqz	a5,80003296 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003286:	8526                	mv	a0,s1
    80003288:	70a2                	ld	ra,40(sp)
    8000328a:	7402                	ld	s0,32(sp)
    8000328c:	64e2                	ld	s1,24(sp)
    8000328e:	6942                	ld	s2,16(sp)
    80003290:	69a2                	ld	s3,8(sp)
    80003292:	6145                	addi	sp,sp,48
    80003294:	8082                	ret
    virtio_disk_rw(b, 0);
    80003296:	4581                	li	a1,0
    80003298:	8526                	mv	a0,s1
    8000329a:	00003097          	auipc	ra,0x3
    8000329e:	f82080e7          	jalr	-126(ra) # 8000621c <virtio_disk_rw>
    b->valid = 1;
    800032a2:	4785                	li	a5,1
    800032a4:	c09c                	sw	a5,0(s1)
  return b;
    800032a6:	b7c5                	j	80003286 <bread+0xd0>

00000000800032a8 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800032a8:	1101                	addi	sp,sp,-32
    800032aa:	ec06                	sd	ra,24(sp)
    800032ac:	e822                	sd	s0,16(sp)
    800032ae:	e426                	sd	s1,8(sp)
    800032b0:	1000                	addi	s0,sp,32
    800032b2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032b4:	0541                	addi	a0,a0,16
    800032b6:	00001097          	auipc	ra,0x1
    800032ba:	456080e7          	jalr	1110(ra) # 8000470c <holdingsleep>
    800032be:	cd01                	beqz	a0,800032d6 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032c0:	4585                	li	a1,1
    800032c2:	8526                	mv	a0,s1
    800032c4:	00003097          	auipc	ra,0x3
    800032c8:	f58080e7          	jalr	-168(ra) # 8000621c <virtio_disk_rw>
}
    800032cc:	60e2                	ld	ra,24(sp)
    800032ce:	6442                	ld	s0,16(sp)
    800032d0:	64a2                	ld	s1,8(sp)
    800032d2:	6105                	addi	sp,sp,32
    800032d4:	8082                	ret
    panic("bwrite");
    800032d6:	00005517          	auipc	a0,0x5
    800032da:	27250513          	addi	a0,a0,626 # 80008548 <syscalls+0xd8>
    800032de:	ffffd097          	auipc	ra,0xffffd
    800032e2:	26a080e7          	jalr	618(ra) # 80000548 <panic>

00000000800032e6 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032e6:	1101                	addi	sp,sp,-32
    800032e8:	ec06                	sd	ra,24(sp)
    800032ea:	e822                	sd	s0,16(sp)
    800032ec:	e426                	sd	s1,8(sp)
    800032ee:	e04a                	sd	s2,0(sp)
    800032f0:	1000                	addi	s0,sp,32
    800032f2:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032f4:	01050913          	addi	s2,a0,16
    800032f8:	854a                	mv	a0,s2
    800032fa:	00001097          	auipc	ra,0x1
    800032fe:	412080e7          	jalr	1042(ra) # 8000470c <holdingsleep>
    80003302:	c92d                	beqz	a0,80003374 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003304:	854a                	mv	a0,s2
    80003306:	00001097          	auipc	ra,0x1
    8000330a:	3c2080e7          	jalr	962(ra) # 800046c8 <releasesleep>

  acquire(&bcache.lock);
    8000330e:	00014517          	auipc	a0,0x14
    80003312:	67250513          	addi	a0,a0,1650 # 80017980 <bcache>
    80003316:	ffffe097          	auipc	ra,0xffffe
    8000331a:	8fa080e7          	jalr	-1798(ra) # 80000c10 <acquire>
  b->refcnt--;
    8000331e:	40bc                	lw	a5,64(s1)
    80003320:	37fd                	addiw	a5,a5,-1
    80003322:	0007871b          	sext.w	a4,a5
    80003326:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003328:	eb05                	bnez	a4,80003358 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000332a:	68bc                	ld	a5,80(s1)
    8000332c:	64b8                	ld	a4,72(s1)
    8000332e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003330:	64bc                	ld	a5,72(s1)
    80003332:	68b8                	ld	a4,80(s1)
    80003334:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003336:	0001c797          	auipc	a5,0x1c
    8000333a:	64a78793          	addi	a5,a5,1610 # 8001f980 <bcache+0x8000>
    8000333e:	2b87b703          	ld	a4,696(a5)
    80003342:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003344:	0001d717          	auipc	a4,0x1d
    80003348:	8a470713          	addi	a4,a4,-1884 # 8001fbe8 <bcache+0x8268>
    8000334c:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000334e:	2b87b703          	ld	a4,696(a5)
    80003352:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003354:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003358:	00014517          	auipc	a0,0x14
    8000335c:	62850513          	addi	a0,a0,1576 # 80017980 <bcache>
    80003360:	ffffe097          	auipc	ra,0xffffe
    80003364:	964080e7          	jalr	-1692(ra) # 80000cc4 <release>
}
    80003368:	60e2                	ld	ra,24(sp)
    8000336a:	6442                	ld	s0,16(sp)
    8000336c:	64a2                	ld	s1,8(sp)
    8000336e:	6902                	ld	s2,0(sp)
    80003370:	6105                	addi	sp,sp,32
    80003372:	8082                	ret
    panic("brelse");
    80003374:	00005517          	auipc	a0,0x5
    80003378:	1dc50513          	addi	a0,a0,476 # 80008550 <syscalls+0xe0>
    8000337c:	ffffd097          	auipc	ra,0xffffd
    80003380:	1cc080e7          	jalr	460(ra) # 80000548 <panic>

0000000080003384 <bpin>:

void
bpin(struct buf *b) {
    80003384:	1101                	addi	sp,sp,-32
    80003386:	ec06                	sd	ra,24(sp)
    80003388:	e822                	sd	s0,16(sp)
    8000338a:	e426                	sd	s1,8(sp)
    8000338c:	1000                	addi	s0,sp,32
    8000338e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003390:	00014517          	auipc	a0,0x14
    80003394:	5f050513          	addi	a0,a0,1520 # 80017980 <bcache>
    80003398:	ffffe097          	auipc	ra,0xffffe
    8000339c:	878080e7          	jalr	-1928(ra) # 80000c10 <acquire>
  b->refcnt++;
    800033a0:	40bc                	lw	a5,64(s1)
    800033a2:	2785                	addiw	a5,a5,1
    800033a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033a6:	00014517          	auipc	a0,0x14
    800033aa:	5da50513          	addi	a0,a0,1498 # 80017980 <bcache>
    800033ae:	ffffe097          	auipc	ra,0xffffe
    800033b2:	916080e7          	jalr	-1770(ra) # 80000cc4 <release>
}
    800033b6:	60e2                	ld	ra,24(sp)
    800033b8:	6442                	ld	s0,16(sp)
    800033ba:	64a2                	ld	s1,8(sp)
    800033bc:	6105                	addi	sp,sp,32
    800033be:	8082                	ret

00000000800033c0 <bunpin>:

void
bunpin(struct buf *b) {
    800033c0:	1101                	addi	sp,sp,-32
    800033c2:	ec06                	sd	ra,24(sp)
    800033c4:	e822                	sd	s0,16(sp)
    800033c6:	e426                	sd	s1,8(sp)
    800033c8:	1000                	addi	s0,sp,32
    800033ca:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033cc:	00014517          	auipc	a0,0x14
    800033d0:	5b450513          	addi	a0,a0,1460 # 80017980 <bcache>
    800033d4:	ffffe097          	auipc	ra,0xffffe
    800033d8:	83c080e7          	jalr	-1988(ra) # 80000c10 <acquire>
  b->refcnt--;
    800033dc:	40bc                	lw	a5,64(s1)
    800033de:	37fd                	addiw	a5,a5,-1
    800033e0:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033e2:	00014517          	auipc	a0,0x14
    800033e6:	59e50513          	addi	a0,a0,1438 # 80017980 <bcache>
    800033ea:	ffffe097          	auipc	ra,0xffffe
    800033ee:	8da080e7          	jalr	-1830(ra) # 80000cc4 <release>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	64a2                	ld	s1,8(sp)
    800033f8:	6105                	addi	sp,sp,32
    800033fa:	8082                	ret

00000000800033fc <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033fc:	1101                	addi	sp,sp,-32
    800033fe:	ec06                	sd	ra,24(sp)
    80003400:	e822                	sd	s0,16(sp)
    80003402:	e426                	sd	s1,8(sp)
    80003404:	e04a                	sd	s2,0(sp)
    80003406:	1000                	addi	s0,sp,32
    80003408:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000340a:	00d5d59b          	srliw	a1,a1,0xd
    8000340e:	0001d797          	auipc	a5,0x1d
    80003412:	c4e7a783          	lw	a5,-946(a5) # 8002005c <sb+0x1c>
    80003416:	9dbd                	addw	a1,a1,a5
    80003418:	00000097          	auipc	ra,0x0
    8000341c:	d9e080e7          	jalr	-610(ra) # 800031b6 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003420:	0074f713          	andi	a4,s1,7
    80003424:	4785                	li	a5,1
    80003426:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000342a:	14ce                	slli	s1,s1,0x33
    8000342c:	90d9                	srli	s1,s1,0x36
    8000342e:	00950733          	add	a4,a0,s1
    80003432:	05874703          	lbu	a4,88(a4)
    80003436:	00e7f6b3          	and	a3,a5,a4
    8000343a:	c69d                	beqz	a3,80003468 <bfree+0x6c>
    8000343c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000343e:	94aa                	add	s1,s1,a0
    80003440:	fff7c793          	not	a5,a5
    80003444:	8ff9                	and	a5,a5,a4
    80003446:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000344a:	00001097          	auipc	ra,0x1
    8000344e:	100080e7          	jalr	256(ra) # 8000454a <log_write>
  brelse(bp);
    80003452:	854a                	mv	a0,s2
    80003454:	00000097          	auipc	ra,0x0
    80003458:	e92080e7          	jalr	-366(ra) # 800032e6 <brelse>
}
    8000345c:	60e2                	ld	ra,24(sp)
    8000345e:	6442                	ld	s0,16(sp)
    80003460:	64a2                	ld	s1,8(sp)
    80003462:	6902                	ld	s2,0(sp)
    80003464:	6105                	addi	sp,sp,32
    80003466:	8082                	ret
    panic("freeing free block");
    80003468:	00005517          	auipc	a0,0x5
    8000346c:	0f050513          	addi	a0,a0,240 # 80008558 <syscalls+0xe8>
    80003470:	ffffd097          	auipc	ra,0xffffd
    80003474:	0d8080e7          	jalr	216(ra) # 80000548 <panic>

0000000080003478 <balloc>:
{
    80003478:	711d                	addi	sp,sp,-96
    8000347a:	ec86                	sd	ra,88(sp)
    8000347c:	e8a2                	sd	s0,80(sp)
    8000347e:	e4a6                	sd	s1,72(sp)
    80003480:	e0ca                	sd	s2,64(sp)
    80003482:	fc4e                	sd	s3,56(sp)
    80003484:	f852                	sd	s4,48(sp)
    80003486:	f456                	sd	s5,40(sp)
    80003488:	f05a                	sd	s6,32(sp)
    8000348a:	ec5e                	sd	s7,24(sp)
    8000348c:	e862                	sd	s8,16(sp)
    8000348e:	e466                	sd	s9,8(sp)
    80003490:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003492:	0001d797          	auipc	a5,0x1d
    80003496:	bb27a783          	lw	a5,-1102(a5) # 80020044 <sb+0x4>
    8000349a:	cbd1                	beqz	a5,8000352e <balloc+0xb6>
    8000349c:	8baa                	mv	s7,a0
    8000349e:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800034a0:	0001db17          	auipc	s6,0x1d
    800034a4:	ba0b0b13          	addi	s6,s6,-1120 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034a8:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800034aa:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ac:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800034ae:	6c89                	lui	s9,0x2
    800034b0:	a831                	j	800034cc <balloc+0x54>
    brelse(bp);
    800034b2:	854a                	mv	a0,s2
    800034b4:	00000097          	auipc	ra,0x0
    800034b8:	e32080e7          	jalr	-462(ra) # 800032e6 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034bc:	015c87bb          	addw	a5,s9,s5
    800034c0:	00078a9b          	sext.w	s5,a5
    800034c4:	004b2703          	lw	a4,4(s6)
    800034c8:	06eaf363          	bgeu	s5,a4,8000352e <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034cc:	41fad79b          	sraiw	a5,s5,0x1f
    800034d0:	0137d79b          	srliw	a5,a5,0x13
    800034d4:	015787bb          	addw	a5,a5,s5
    800034d8:	40d7d79b          	sraiw	a5,a5,0xd
    800034dc:	01cb2583          	lw	a1,28(s6)
    800034e0:	9dbd                	addw	a1,a1,a5
    800034e2:	855e                	mv	a0,s7
    800034e4:	00000097          	auipc	ra,0x0
    800034e8:	cd2080e7          	jalr	-814(ra) # 800031b6 <bread>
    800034ec:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034ee:	004b2503          	lw	a0,4(s6)
    800034f2:	000a849b          	sext.w	s1,s5
    800034f6:	8662                	mv	a2,s8
    800034f8:	faa4fde3          	bgeu	s1,a0,800034b2 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034fc:	41f6579b          	sraiw	a5,a2,0x1f
    80003500:	01d7d69b          	srliw	a3,a5,0x1d
    80003504:	00c6873b          	addw	a4,a3,a2
    80003508:	00777793          	andi	a5,a4,7
    8000350c:	9f95                	subw	a5,a5,a3
    8000350e:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003512:	4037571b          	sraiw	a4,a4,0x3
    80003516:	00e906b3          	add	a3,s2,a4
    8000351a:	0586c683          	lbu	a3,88(a3)
    8000351e:	00d7f5b3          	and	a1,a5,a3
    80003522:	cd91                	beqz	a1,8000353e <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003524:	2605                	addiw	a2,a2,1
    80003526:	2485                	addiw	s1,s1,1
    80003528:	fd4618e3          	bne	a2,s4,800034f8 <balloc+0x80>
    8000352c:	b759                	j	800034b2 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000352e:	00005517          	auipc	a0,0x5
    80003532:	04250513          	addi	a0,a0,66 # 80008570 <syscalls+0x100>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	012080e7          	jalr	18(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000353e:	974a                	add	a4,a4,s2
    80003540:	8fd5                	or	a5,a5,a3
    80003542:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003546:	854a                	mv	a0,s2
    80003548:	00001097          	auipc	ra,0x1
    8000354c:	002080e7          	jalr	2(ra) # 8000454a <log_write>
        brelse(bp);
    80003550:	854a                	mv	a0,s2
    80003552:	00000097          	auipc	ra,0x0
    80003556:	d94080e7          	jalr	-620(ra) # 800032e6 <brelse>
  bp = bread(dev, bno);
    8000355a:	85a6                	mv	a1,s1
    8000355c:	855e                	mv	a0,s7
    8000355e:	00000097          	auipc	ra,0x0
    80003562:	c58080e7          	jalr	-936(ra) # 800031b6 <bread>
    80003566:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003568:	40000613          	li	a2,1024
    8000356c:	4581                	li	a1,0
    8000356e:	05850513          	addi	a0,a0,88
    80003572:	ffffd097          	auipc	ra,0xffffd
    80003576:	79a080e7          	jalr	1946(ra) # 80000d0c <memset>
  log_write(bp);
    8000357a:	854a                	mv	a0,s2
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	fce080e7          	jalr	-50(ra) # 8000454a <log_write>
  brelse(bp);
    80003584:	854a                	mv	a0,s2
    80003586:	00000097          	auipc	ra,0x0
    8000358a:	d60080e7          	jalr	-672(ra) # 800032e6 <brelse>
}
    8000358e:	8526                	mv	a0,s1
    80003590:	60e6                	ld	ra,88(sp)
    80003592:	6446                	ld	s0,80(sp)
    80003594:	64a6                	ld	s1,72(sp)
    80003596:	6906                	ld	s2,64(sp)
    80003598:	79e2                	ld	s3,56(sp)
    8000359a:	7a42                	ld	s4,48(sp)
    8000359c:	7aa2                	ld	s5,40(sp)
    8000359e:	7b02                	ld	s6,32(sp)
    800035a0:	6be2                	ld	s7,24(sp)
    800035a2:	6c42                	ld	s8,16(sp)
    800035a4:	6ca2                	ld	s9,8(sp)
    800035a6:	6125                	addi	sp,sp,96
    800035a8:	8082                	ret

00000000800035aa <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    800035aa:	7179                	addi	sp,sp,-48
    800035ac:	f406                	sd	ra,40(sp)
    800035ae:	f022                	sd	s0,32(sp)
    800035b0:	ec26                	sd	s1,24(sp)
    800035b2:	e84a                	sd	s2,16(sp)
    800035b4:	e44e                	sd	s3,8(sp)
    800035b6:	e052                	sd	s4,0(sp)
    800035b8:	1800                	addi	s0,sp,48
    800035ba:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035bc:	47ad                	li	a5,11
    800035be:	04b7fe63          	bgeu	a5,a1,8000361a <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035c2:	ff45849b          	addiw	s1,a1,-12
    800035c6:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035ca:	0ff00793          	li	a5,255
    800035ce:	0ae7e363          	bltu	a5,a4,80003674 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035d2:	08052583          	lw	a1,128(a0)
    800035d6:	c5ad                	beqz	a1,80003640 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035d8:	00092503          	lw	a0,0(s2)
    800035dc:	00000097          	auipc	ra,0x0
    800035e0:	bda080e7          	jalr	-1062(ra) # 800031b6 <bread>
    800035e4:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035e6:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035ea:	02049593          	slli	a1,s1,0x20
    800035ee:	9181                	srli	a1,a1,0x20
    800035f0:	058a                	slli	a1,a1,0x2
    800035f2:	00b784b3          	add	s1,a5,a1
    800035f6:	0004a983          	lw	s3,0(s1)
    800035fa:	04098d63          	beqz	s3,80003654 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035fe:	8552                	mv	a0,s4
    80003600:	00000097          	auipc	ra,0x0
    80003604:	ce6080e7          	jalr	-794(ra) # 800032e6 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003608:	854e                	mv	a0,s3
    8000360a:	70a2                	ld	ra,40(sp)
    8000360c:	7402                	ld	s0,32(sp)
    8000360e:	64e2                	ld	s1,24(sp)
    80003610:	6942                	ld	s2,16(sp)
    80003612:	69a2                	ld	s3,8(sp)
    80003614:	6a02                	ld	s4,0(sp)
    80003616:	6145                	addi	sp,sp,48
    80003618:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    8000361a:	02059493          	slli	s1,a1,0x20
    8000361e:	9081                	srli	s1,s1,0x20
    80003620:	048a                	slli	s1,s1,0x2
    80003622:	94aa                	add	s1,s1,a0
    80003624:	0504a983          	lw	s3,80(s1)
    80003628:	fe0990e3          	bnez	s3,80003608 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000362c:	4108                	lw	a0,0(a0)
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	e4a080e7          	jalr	-438(ra) # 80003478 <balloc>
    80003636:	0005099b          	sext.w	s3,a0
    8000363a:	0534a823          	sw	s3,80(s1)
    8000363e:	b7e9                	j	80003608 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003640:	4108                	lw	a0,0(a0)
    80003642:	00000097          	auipc	ra,0x0
    80003646:	e36080e7          	jalr	-458(ra) # 80003478 <balloc>
    8000364a:	0005059b          	sext.w	a1,a0
    8000364e:	08b92023          	sw	a1,128(s2)
    80003652:	b759                	j	800035d8 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003654:	00092503          	lw	a0,0(s2)
    80003658:	00000097          	auipc	ra,0x0
    8000365c:	e20080e7          	jalr	-480(ra) # 80003478 <balloc>
    80003660:	0005099b          	sext.w	s3,a0
    80003664:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003668:	8552                	mv	a0,s4
    8000366a:	00001097          	auipc	ra,0x1
    8000366e:	ee0080e7          	jalr	-288(ra) # 8000454a <log_write>
    80003672:	b771                	j	800035fe <bmap+0x54>
  panic("bmap: out of range");
    80003674:	00005517          	auipc	a0,0x5
    80003678:	f1450513          	addi	a0,a0,-236 # 80008588 <syscalls+0x118>
    8000367c:	ffffd097          	auipc	ra,0xffffd
    80003680:	ecc080e7          	jalr	-308(ra) # 80000548 <panic>

0000000080003684 <iget>:
{
    80003684:	7179                	addi	sp,sp,-48
    80003686:	f406                	sd	ra,40(sp)
    80003688:	f022                	sd	s0,32(sp)
    8000368a:	ec26                	sd	s1,24(sp)
    8000368c:	e84a                	sd	s2,16(sp)
    8000368e:	e44e                	sd	s3,8(sp)
    80003690:	e052                	sd	s4,0(sp)
    80003692:	1800                	addi	s0,sp,48
    80003694:	89aa                	mv	s3,a0
    80003696:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003698:	0001d517          	auipc	a0,0x1d
    8000369c:	9c850513          	addi	a0,a0,-1592 # 80020060 <icache>
    800036a0:	ffffd097          	auipc	ra,0xffffd
    800036a4:	570080e7          	jalr	1392(ra) # 80000c10 <acquire>
  empty = 0;
    800036a8:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036aa:	0001d497          	auipc	s1,0x1d
    800036ae:	9ce48493          	addi	s1,s1,-1586 # 80020078 <icache+0x18>
    800036b2:	0001e697          	auipc	a3,0x1e
    800036b6:	45668693          	addi	a3,a3,1110 # 80021b08 <log>
    800036ba:	a039                	j	800036c8 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036bc:	02090b63          	beqz	s2,800036f2 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    800036c0:	08848493          	addi	s1,s1,136
    800036c4:	02d48a63          	beq	s1,a3,800036f8 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036c8:	449c                	lw	a5,8(s1)
    800036ca:	fef059e3          	blez	a5,800036bc <iget+0x38>
    800036ce:	4098                	lw	a4,0(s1)
    800036d0:	ff3716e3          	bne	a4,s3,800036bc <iget+0x38>
    800036d4:	40d8                	lw	a4,4(s1)
    800036d6:	ff4713e3          	bne	a4,s4,800036bc <iget+0x38>
      ip->ref++;
    800036da:	2785                	addiw	a5,a5,1
    800036dc:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800036de:	0001d517          	auipc	a0,0x1d
    800036e2:	98250513          	addi	a0,a0,-1662 # 80020060 <icache>
    800036e6:	ffffd097          	auipc	ra,0xffffd
    800036ea:	5de080e7          	jalr	1502(ra) # 80000cc4 <release>
      return ip;
    800036ee:	8926                	mv	s2,s1
    800036f0:	a03d                	j	8000371e <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036f2:	f7f9                	bnez	a5,800036c0 <iget+0x3c>
    800036f4:	8926                	mv	s2,s1
    800036f6:	b7e9                	j	800036c0 <iget+0x3c>
  if(empty == 0)
    800036f8:	02090c63          	beqz	s2,80003730 <iget+0xac>
  ip->dev = dev;
    800036fc:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003700:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003704:	4785                	li	a5,1
    80003706:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000370a:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    8000370e:	0001d517          	auipc	a0,0x1d
    80003712:	95250513          	addi	a0,a0,-1710 # 80020060 <icache>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	5ae080e7          	jalr	1454(ra) # 80000cc4 <release>
}
    8000371e:	854a                	mv	a0,s2
    80003720:	70a2                	ld	ra,40(sp)
    80003722:	7402                	ld	s0,32(sp)
    80003724:	64e2                	ld	s1,24(sp)
    80003726:	6942                	ld	s2,16(sp)
    80003728:	69a2                	ld	s3,8(sp)
    8000372a:	6a02                	ld	s4,0(sp)
    8000372c:	6145                	addi	sp,sp,48
    8000372e:	8082                	ret
    panic("iget: no inodes");
    80003730:	00005517          	auipc	a0,0x5
    80003734:	e7050513          	addi	a0,a0,-400 # 800085a0 <syscalls+0x130>
    80003738:	ffffd097          	auipc	ra,0xffffd
    8000373c:	e10080e7          	jalr	-496(ra) # 80000548 <panic>

0000000080003740 <fsinit>:
fsinit(int dev) {
    80003740:	7179                	addi	sp,sp,-48
    80003742:	f406                	sd	ra,40(sp)
    80003744:	f022                	sd	s0,32(sp)
    80003746:	ec26                	sd	s1,24(sp)
    80003748:	e84a                	sd	s2,16(sp)
    8000374a:	e44e                	sd	s3,8(sp)
    8000374c:	1800                	addi	s0,sp,48
    8000374e:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003750:	4585                	li	a1,1
    80003752:	00000097          	auipc	ra,0x0
    80003756:	a64080e7          	jalr	-1436(ra) # 800031b6 <bread>
    8000375a:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000375c:	0001d997          	auipc	s3,0x1d
    80003760:	8e498993          	addi	s3,s3,-1820 # 80020040 <sb>
    80003764:	02000613          	li	a2,32
    80003768:	05850593          	addi	a1,a0,88
    8000376c:	854e                	mv	a0,s3
    8000376e:	ffffd097          	auipc	ra,0xffffd
    80003772:	5fe080e7          	jalr	1534(ra) # 80000d6c <memmove>
  brelse(bp);
    80003776:	8526                	mv	a0,s1
    80003778:	00000097          	auipc	ra,0x0
    8000377c:	b6e080e7          	jalr	-1170(ra) # 800032e6 <brelse>
  if(sb.magic != FSMAGIC)
    80003780:	0009a703          	lw	a4,0(s3)
    80003784:	102037b7          	lui	a5,0x10203
    80003788:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000378c:	02f71263          	bne	a4,a5,800037b0 <fsinit+0x70>
  initlog(dev, &sb);
    80003790:	0001d597          	auipc	a1,0x1d
    80003794:	8b058593          	addi	a1,a1,-1872 # 80020040 <sb>
    80003798:	854a                	mv	a0,s2
    8000379a:	00001097          	auipc	ra,0x1
    8000379e:	b38080e7          	jalr	-1224(ra) # 800042d2 <initlog>
}
    800037a2:	70a2                	ld	ra,40(sp)
    800037a4:	7402                	ld	s0,32(sp)
    800037a6:	64e2                	ld	s1,24(sp)
    800037a8:	6942                	ld	s2,16(sp)
    800037aa:	69a2                	ld	s3,8(sp)
    800037ac:	6145                	addi	sp,sp,48
    800037ae:	8082                	ret
    panic("invalid file system");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	e0050513          	addi	a0,a0,-512 # 800085b0 <syscalls+0x140>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d90080e7          	jalr	-624(ra) # 80000548 <panic>

00000000800037c0 <iinit>:
{
    800037c0:	7179                	addi	sp,sp,-48
    800037c2:	f406                	sd	ra,40(sp)
    800037c4:	f022                	sd	s0,32(sp)
    800037c6:	ec26                	sd	s1,24(sp)
    800037c8:	e84a                	sd	s2,16(sp)
    800037ca:	e44e                	sd	s3,8(sp)
    800037cc:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800037ce:	00005597          	auipc	a1,0x5
    800037d2:	dfa58593          	addi	a1,a1,-518 # 800085c8 <syscalls+0x158>
    800037d6:	0001d517          	auipc	a0,0x1d
    800037da:	88a50513          	addi	a0,a0,-1910 # 80020060 <icache>
    800037de:	ffffd097          	auipc	ra,0xffffd
    800037e2:	3a2080e7          	jalr	930(ra) # 80000b80 <initlock>
  for(i = 0; i < NINODE; i++) {
    800037e6:	0001d497          	auipc	s1,0x1d
    800037ea:	8a248493          	addi	s1,s1,-1886 # 80020088 <icache+0x28>
    800037ee:	0001e997          	auipc	s3,0x1e
    800037f2:	32a98993          	addi	s3,s3,810 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800037f6:	00005917          	auipc	s2,0x5
    800037fa:	dda90913          	addi	s2,s2,-550 # 800085d0 <syscalls+0x160>
    800037fe:	85ca                	mv	a1,s2
    80003800:	8526                	mv	a0,s1
    80003802:	00001097          	auipc	ra,0x1
    80003806:	e36080e7          	jalr	-458(ra) # 80004638 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000380a:	08848493          	addi	s1,s1,136
    8000380e:	ff3498e3          	bne	s1,s3,800037fe <iinit+0x3e>
}
    80003812:	70a2                	ld	ra,40(sp)
    80003814:	7402                	ld	s0,32(sp)
    80003816:	64e2                	ld	s1,24(sp)
    80003818:	6942                	ld	s2,16(sp)
    8000381a:	69a2                	ld	s3,8(sp)
    8000381c:	6145                	addi	sp,sp,48
    8000381e:	8082                	ret

0000000080003820 <ialloc>:
{
    80003820:	715d                	addi	sp,sp,-80
    80003822:	e486                	sd	ra,72(sp)
    80003824:	e0a2                	sd	s0,64(sp)
    80003826:	fc26                	sd	s1,56(sp)
    80003828:	f84a                	sd	s2,48(sp)
    8000382a:	f44e                	sd	s3,40(sp)
    8000382c:	f052                	sd	s4,32(sp)
    8000382e:	ec56                	sd	s5,24(sp)
    80003830:	e85a                	sd	s6,16(sp)
    80003832:	e45e                	sd	s7,8(sp)
    80003834:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003836:	0001d717          	auipc	a4,0x1d
    8000383a:	81672703          	lw	a4,-2026(a4) # 8002004c <sb+0xc>
    8000383e:	4785                	li	a5,1
    80003840:	04e7fa63          	bgeu	a5,a4,80003894 <ialloc+0x74>
    80003844:	8aaa                	mv	s5,a0
    80003846:	8bae                	mv	s7,a1
    80003848:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000384a:	0001ca17          	auipc	s4,0x1c
    8000384e:	7f6a0a13          	addi	s4,s4,2038 # 80020040 <sb>
    80003852:	00048b1b          	sext.w	s6,s1
    80003856:	0044d593          	srli	a1,s1,0x4
    8000385a:	018a2783          	lw	a5,24(s4)
    8000385e:	9dbd                	addw	a1,a1,a5
    80003860:	8556                	mv	a0,s5
    80003862:	00000097          	auipc	ra,0x0
    80003866:	954080e7          	jalr	-1708(ra) # 800031b6 <bread>
    8000386a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000386c:	05850993          	addi	s3,a0,88
    80003870:	00f4f793          	andi	a5,s1,15
    80003874:	079a                	slli	a5,a5,0x6
    80003876:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003878:	00099783          	lh	a5,0(s3)
    8000387c:	c785                	beqz	a5,800038a4 <ialloc+0x84>
    brelse(bp);
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	a68080e7          	jalr	-1432(ra) # 800032e6 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003886:	0485                	addi	s1,s1,1
    80003888:	00ca2703          	lw	a4,12(s4)
    8000388c:	0004879b          	sext.w	a5,s1
    80003890:	fce7e1e3          	bltu	a5,a4,80003852 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003894:	00005517          	auipc	a0,0x5
    80003898:	d4450513          	addi	a0,a0,-700 # 800085d8 <syscalls+0x168>
    8000389c:	ffffd097          	auipc	ra,0xffffd
    800038a0:	cac080e7          	jalr	-852(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    800038a4:	04000613          	li	a2,64
    800038a8:	4581                	li	a1,0
    800038aa:	854e                	mv	a0,s3
    800038ac:	ffffd097          	auipc	ra,0xffffd
    800038b0:	460080e7          	jalr	1120(ra) # 80000d0c <memset>
      dip->type = type;
    800038b4:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038b8:	854a                	mv	a0,s2
    800038ba:	00001097          	auipc	ra,0x1
    800038be:	c90080e7          	jalr	-880(ra) # 8000454a <log_write>
      brelse(bp);
    800038c2:	854a                	mv	a0,s2
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	a22080e7          	jalr	-1502(ra) # 800032e6 <brelse>
      return iget(dev, inum);
    800038cc:	85da                	mv	a1,s6
    800038ce:	8556                	mv	a0,s5
    800038d0:	00000097          	auipc	ra,0x0
    800038d4:	db4080e7          	jalr	-588(ra) # 80003684 <iget>
}
    800038d8:	60a6                	ld	ra,72(sp)
    800038da:	6406                	ld	s0,64(sp)
    800038dc:	74e2                	ld	s1,56(sp)
    800038de:	7942                	ld	s2,48(sp)
    800038e0:	79a2                	ld	s3,40(sp)
    800038e2:	7a02                	ld	s4,32(sp)
    800038e4:	6ae2                	ld	s5,24(sp)
    800038e6:	6b42                	ld	s6,16(sp)
    800038e8:	6ba2                	ld	s7,8(sp)
    800038ea:	6161                	addi	sp,sp,80
    800038ec:	8082                	ret

00000000800038ee <iupdate>:
{
    800038ee:	1101                	addi	sp,sp,-32
    800038f0:	ec06                	sd	ra,24(sp)
    800038f2:	e822                	sd	s0,16(sp)
    800038f4:	e426                	sd	s1,8(sp)
    800038f6:	e04a                	sd	s2,0(sp)
    800038f8:	1000                	addi	s0,sp,32
    800038fa:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038fc:	415c                	lw	a5,4(a0)
    800038fe:	0047d79b          	srliw	a5,a5,0x4
    80003902:	0001c597          	auipc	a1,0x1c
    80003906:	7565a583          	lw	a1,1878(a1) # 80020058 <sb+0x18>
    8000390a:	9dbd                	addw	a1,a1,a5
    8000390c:	4108                	lw	a0,0(a0)
    8000390e:	00000097          	auipc	ra,0x0
    80003912:	8a8080e7          	jalr	-1880(ra) # 800031b6 <bread>
    80003916:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003918:	05850793          	addi	a5,a0,88
    8000391c:	40c8                	lw	a0,4(s1)
    8000391e:	893d                	andi	a0,a0,15
    80003920:	051a                	slli	a0,a0,0x6
    80003922:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003924:	04449703          	lh	a4,68(s1)
    80003928:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000392c:	04649703          	lh	a4,70(s1)
    80003930:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003934:	04849703          	lh	a4,72(s1)
    80003938:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000393c:	04a49703          	lh	a4,74(s1)
    80003940:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003944:	44f8                	lw	a4,76(s1)
    80003946:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003948:	03400613          	li	a2,52
    8000394c:	05048593          	addi	a1,s1,80
    80003950:	0531                	addi	a0,a0,12
    80003952:	ffffd097          	auipc	ra,0xffffd
    80003956:	41a080e7          	jalr	1050(ra) # 80000d6c <memmove>
  log_write(bp);
    8000395a:	854a                	mv	a0,s2
    8000395c:	00001097          	auipc	ra,0x1
    80003960:	bee080e7          	jalr	-1042(ra) # 8000454a <log_write>
  brelse(bp);
    80003964:	854a                	mv	a0,s2
    80003966:	00000097          	auipc	ra,0x0
    8000396a:	980080e7          	jalr	-1664(ra) # 800032e6 <brelse>
}
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6902                	ld	s2,0(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret

000000008000397a <idup>:
{
    8000397a:	1101                	addi	sp,sp,-32
    8000397c:	ec06                	sd	ra,24(sp)
    8000397e:	e822                	sd	s0,16(sp)
    80003980:	e426                	sd	s1,8(sp)
    80003982:	1000                	addi	s0,sp,32
    80003984:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003986:	0001c517          	auipc	a0,0x1c
    8000398a:	6da50513          	addi	a0,a0,1754 # 80020060 <icache>
    8000398e:	ffffd097          	auipc	ra,0xffffd
    80003992:	282080e7          	jalr	642(ra) # 80000c10 <acquire>
  ip->ref++;
    80003996:	449c                	lw	a5,8(s1)
    80003998:	2785                	addiw	a5,a5,1
    8000399a:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    8000399c:	0001c517          	auipc	a0,0x1c
    800039a0:	6c450513          	addi	a0,a0,1732 # 80020060 <icache>
    800039a4:	ffffd097          	auipc	ra,0xffffd
    800039a8:	320080e7          	jalr	800(ra) # 80000cc4 <release>
}
    800039ac:	8526                	mv	a0,s1
    800039ae:	60e2                	ld	ra,24(sp)
    800039b0:	6442                	ld	s0,16(sp)
    800039b2:	64a2                	ld	s1,8(sp)
    800039b4:	6105                	addi	sp,sp,32
    800039b6:	8082                	ret

00000000800039b8 <ilock>:
{
    800039b8:	1101                	addi	sp,sp,-32
    800039ba:	ec06                	sd	ra,24(sp)
    800039bc:	e822                	sd	s0,16(sp)
    800039be:	e426                	sd	s1,8(sp)
    800039c0:	e04a                	sd	s2,0(sp)
    800039c2:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039c4:	c115                	beqz	a0,800039e8 <ilock+0x30>
    800039c6:	84aa                	mv	s1,a0
    800039c8:	451c                	lw	a5,8(a0)
    800039ca:	00f05f63          	blez	a5,800039e8 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039ce:	0541                	addi	a0,a0,16
    800039d0:	00001097          	auipc	ra,0x1
    800039d4:	ca2080e7          	jalr	-862(ra) # 80004672 <acquiresleep>
  if(ip->valid == 0){
    800039d8:	40bc                	lw	a5,64(s1)
    800039da:	cf99                	beqz	a5,800039f8 <ilock+0x40>
}
    800039dc:	60e2                	ld	ra,24(sp)
    800039de:	6442                	ld	s0,16(sp)
    800039e0:	64a2                	ld	s1,8(sp)
    800039e2:	6902                	ld	s2,0(sp)
    800039e4:	6105                	addi	sp,sp,32
    800039e6:	8082                	ret
    panic("ilock");
    800039e8:	00005517          	auipc	a0,0x5
    800039ec:	c0850513          	addi	a0,a0,-1016 # 800085f0 <syscalls+0x180>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	b58080e7          	jalr	-1192(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039f8:	40dc                	lw	a5,4(s1)
    800039fa:	0047d79b          	srliw	a5,a5,0x4
    800039fe:	0001c597          	auipc	a1,0x1c
    80003a02:	65a5a583          	lw	a1,1626(a1) # 80020058 <sb+0x18>
    80003a06:	9dbd                	addw	a1,a1,a5
    80003a08:	4088                	lw	a0,0(s1)
    80003a0a:	fffff097          	auipc	ra,0xfffff
    80003a0e:	7ac080e7          	jalr	1964(ra) # 800031b6 <bread>
    80003a12:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a14:	05850593          	addi	a1,a0,88
    80003a18:	40dc                	lw	a5,4(s1)
    80003a1a:	8bbd                	andi	a5,a5,15
    80003a1c:	079a                	slli	a5,a5,0x6
    80003a1e:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a20:	00059783          	lh	a5,0(a1)
    80003a24:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a28:	00259783          	lh	a5,2(a1)
    80003a2c:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a30:	00459783          	lh	a5,4(a1)
    80003a34:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a38:	00659783          	lh	a5,6(a1)
    80003a3c:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a40:	459c                	lw	a5,8(a1)
    80003a42:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a44:	03400613          	li	a2,52
    80003a48:	05b1                	addi	a1,a1,12
    80003a4a:	05048513          	addi	a0,s1,80
    80003a4e:	ffffd097          	auipc	ra,0xffffd
    80003a52:	31e080e7          	jalr	798(ra) # 80000d6c <memmove>
    brelse(bp);
    80003a56:	854a                	mv	a0,s2
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	88e080e7          	jalr	-1906(ra) # 800032e6 <brelse>
    ip->valid = 1;
    80003a60:	4785                	li	a5,1
    80003a62:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a64:	04449783          	lh	a5,68(s1)
    80003a68:	fbb5                	bnez	a5,800039dc <ilock+0x24>
      panic("ilock: no type");
    80003a6a:	00005517          	auipc	a0,0x5
    80003a6e:	b8e50513          	addi	a0,a0,-1138 # 800085f8 <syscalls+0x188>
    80003a72:	ffffd097          	auipc	ra,0xffffd
    80003a76:	ad6080e7          	jalr	-1322(ra) # 80000548 <panic>

0000000080003a7a <iunlock>:
{
    80003a7a:	1101                	addi	sp,sp,-32
    80003a7c:	ec06                	sd	ra,24(sp)
    80003a7e:	e822                	sd	s0,16(sp)
    80003a80:	e426                	sd	s1,8(sp)
    80003a82:	e04a                	sd	s2,0(sp)
    80003a84:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a86:	c905                	beqz	a0,80003ab6 <iunlock+0x3c>
    80003a88:	84aa                	mv	s1,a0
    80003a8a:	01050913          	addi	s2,a0,16
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	c7c080e7          	jalr	-900(ra) # 8000470c <holdingsleep>
    80003a98:	cd19                	beqz	a0,80003ab6 <iunlock+0x3c>
    80003a9a:	449c                	lw	a5,8(s1)
    80003a9c:	00f05d63          	blez	a5,80003ab6 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	00001097          	auipc	ra,0x1
    80003aa6:	c26080e7          	jalr	-986(ra) # 800046c8 <releasesleep>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6902                	ld	s2,0(sp)
    80003ab2:	6105                	addi	sp,sp,32
    80003ab4:	8082                	ret
    panic("iunlock");
    80003ab6:	00005517          	auipc	a0,0x5
    80003aba:	b5250513          	addi	a0,a0,-1198 # 80008608 <syscalls+0x198>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	a8a080e7          	jalr	-1398(ra) # 80000548 <panic>

0000000080003ac6 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ac6:	7179                	addi	sp,sp,-48
    80003ac8:	f406                	sd	ra,40(sp)
    80003aca:	f022                	sd	s0,32(sp)
    80003acc:	ec26                	sd	s1,24(sp)
    80003ace:	e84a                	sd	s2,16(sp)
    80003ad0:	e44e                	sd	s3,8(sp)
    80003ad2:	e052                	sd	s4,0(sp)
    80003ad4:	1800                	addi	s0,sp,48
    80003ad6:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ad8:	05050493          	addi	s1,a0,80
    80003adc:	08050913          	addi	s2,a0,128
    80003ae0:	a021                	j	80003ae8 <itrunc+0x22>
    80003ae2:	0491                	addi	s1,s1,4
    80003ae4:	01248d63          	beq	s1,s2,80003afe <itrunc+0x38>
    if(ip->addrs[i]){
    80003ae8:	408c                	lw	a1,0(s1)
    80003aea:	dde5                	beqz	a1,80003ae2 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003aec:	0009a503          	lw	a0,0(s3)
    80003af0:	00000097          	auipc	ra,0x0
    80003af4:	90c080e7          	jalr	-1780(ra) # 800033fc <bfree>
      ip->addrs[i] = 0;
    80003af8:	0004a023          	sw	zero,0(s1)
    80003afc:	b7dd                	j	80003ae2 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003afe:	0809a583          	lw	a1,128(s3)
    80003b02:	e185                	bnez	a1,80003b22 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003b04:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003b08:	854e                	mv	a0,s3
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	de4080e7          	jalr	-540(ra) # 800038ee <iupdate>
}
    80003b12:	70a2                	ld	ra,40(sp)
    80003b14:	7402                	ld	s0,32(sp)
    80003b16:	64e2                	ld	s1,24(sp)
    80003b18:	6942                	ld	s2,16(sp)
    80003b1a:	69a2                	ld	s3,8(sp)
    80003b1c:	6a02                	ld	s4,0(sp)
    80003b1e:	6145                	addi	sp,sp,48
    80003b20:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b22:	0009a503          	lw	a0,0(s3)
    80003b26:	fffff097          	auipc	ra,0xfffff
    80003b2a:	690080e7          	jalr	1680(ra) # 800031b6 <bread>
    80003b2e:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b30:	05850493          	addi	s1,a0,88
    80003b34:	45850913          	addi	s2,a0,1112
    80003b38:	a811                	j	80003b4c <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b3a:	0009a503          	lw	a0,0(s3)
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	8be080e7          	jalr	-1858(ra) # 800033fc <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b46:	0491                	addi	s1,s1,4
    80003b48:	01248563          	beq	s1,s2,80003b52 <itrunc+0x8c>
      if(a[j])
    80003b4c:	408c                	lw	a1,0(s1)
    80003b4e:	dde5                	beqz	a1,80003b46 <itrunc+0x80>
    80003b50:	b7ed                	j	80003b3a <itrunc+0x74>
    brelse(bp);
    80003b52:	8552                	mv	a0,s4
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	792080e7          	jalr	1938(ra) # 800032e6 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b5c:	0809a583          	lw	a1,128(s3)
    80003b60:	0009a503          	lw	a0,0(s3)
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	898080e7          	jalr	-1896(ra) # 800033fc <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b6c:	0809a023          	sw	zero,128(s3)
    80003b70:	bf51                	j	80003b04 <itrunc+0x3e>

0000000080003b72 <iput>:
{
    80003b72:	1101                	addi	sp,sp,-32
    80003b74:	ec06                	sd	ra,24(sp)
    80003b76:	e822                	sd	s0,16(sp)
    80003b78:	e426                	sd	s1,8(sp)
    80003b7a:	e04a                	sd	s2,0(sp)
    80003b7c:	1000                	addi	s0,sp,32
    80003b7e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b80:	0001c517          	auipc	a0,0x1c
    80003b84:	4e050513          	addi	a0,a0,1248 # 80020060 <icache>
    80003b88:	ffffd097          	auipc	ra,0xffffd
    80003b8c:	088080e7          	jalr	136(ra) # 80000c10 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b90:	4498                	lw	a4,8(s1)
    80003b92:	4785                	li	a5,1
    80003b94:	02f70363          	beq	a4,a5,80003bba <iput+0x48>
  ip->ref--;
    80003b98:	449c                	lw	a5,8(s1)
    80003b9a:	37fd                	addiw	a5,a5,-1
    80003b9c:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b9e:	0001c517          	auipc	a0,0x1c
    80003ba2:	4c250513          	addi	a0,a0,1218 # 80020060 <icache>
    80003ba6:	ffffd097          	auipc	ra,0xffffd
    80003baa:	11e080e7          	jalr	286(ra) # 80000cc4 <release>
}
    80003bae:	60e2                	ld	ra,24(sp)
    80003bb0:	6442                	ld	s0,16(sp)
    80003bb2:	64a2                	ld	s1,8(sp)
    80003bb4:	6902                	ld	s2,0(sp)
    80003bb6:	6105                	addi	sp,sp,32
    80003bb8:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003bba:	40bc                	lw	a5,64(s1)
    80003bbc:	dff1                	beqz	a5,80003b98 <iput+0x26>
    80003bbe:	04a49783          	lh	a5,74(s1)
    80003bc2:	fbf9                	bnez	a5,80003b98 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bc4:	01048913          	addi	s2,s1,16
    80003bc8:	854a                	mv	a0,s2
    80003bca:	00001097          	auipc	ra,0x1
    80003bce:	aa8080e7          	jalr	-1368(ra) # 80004672 <acquiresleep>
    release(&icache.lock);
    80003bd2:	0001c517          	auipc	a0,0x1c
    80003bd6:	48e50513          	addi	a0,a0,1166 # 80020060 <icache>
    80003bda:	ffffd097          	auipc	ra,0xffffd
    80003bde:	0ea080e7          	jalr	234(ra) # 80000cc4 <release>
    itrunc(ip);
    80003be2:	8526                	mv	a0,s1
    80003be4:	00000097          	auipc	ra,0x0
    80003be8:	ee2080e7          	jalr	-286(ra) # 80003ac6 <itrunc>
    ip->type = 0;
    80003bec:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bf0:	8526                	mv	a0,s1
    80003bf2:	00000097          	auipc	ra,0x0
    80003bf6:	cfc080e7          	jalr	-772(ra) # 800038ee <iupdate>
    ip->valid = 0;
    80003bfa:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bfe:	854a                	mv	a0,s2
    80003c00:	00001097          	auipc	ra,0x1
    80003c04:	ac8080e7          	jalr	-1336(ra) # 800046c8 <releasesleep>
    acquire(&icache.lock);
    80003c08:	0001c517          	auipc	a0,0x1c
    80003c0c:	45850513          	addi	a0,a0,1112 # 80020060 <icache>
    80003c10:	ffffd097          	auipc	ra,0xffffd
    80003c14:	000080e7          	jalr	ra # 80000c10 <acquire>
    80003c18:	b741                	j	80003b98 <iput+0x26>

0000000080003c1a <iunlockput>:
{
    80003c1a:	1101                	addi	sp,sp,-32
    80003c1c:	ec06                	sd	ra,24(sp)
    80003c1e:	e822                	sd	s0,16(sp)
    80003c20:	e426                	sd	s1,8(sp)
    80003c22:	1000                	addi	s0,sp,32
    80003c24:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c26:	00000097          	auipc	ra,0x0
    80003c2a:	e54080e7          	jalr	-428(ra) # 80003a7a <iunlock>
  iput(ip);
    80003c2e:	8526                	mv	a0,s1
    80003c30:	00000097          	auipc	ra,0x0
    80003c34:	f42080e7          	jalr	-190(ra) # 80003b72 <iput>
}
    80003c38:	60e2                	ld	ra,24(sp)
    80003c3a:	6442                	ld	s0,16(sp)
    80003c3c:	64a2                	ld	s1,8(sp)
    80003c3e:	6105                	addi	sp,sp,32
    80003c40:	8082                	ret

0000000080003c42 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c42:	1141                	addi	sp,sp,-16
    80003c44:	e422                	sd	s0,8(sp)
    80003c46:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c48:	411c                	lw	a5,0(a0)
    80003c4a:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c4c:	415c                	lw	a5,4(a0)
    80003c4e:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c50:	04451783          	lh	a5,68(a0)
    80003c54:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c58:	04a51783          	lh	a5,74(a0)
    80003c5c:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c60:	04c56783          	lwu	a5,76(a0)
    80003c64:	e99c                	sd	a5,16(a1)
}
    80003c66:	6422                	ld	s0,8(sp)
    80003c68:	0141                	addi	sp,sp,16
    80003c6a:	8082                	ret

0000000080003c6c <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c6c:	457c                	lw	a5,76(a0)
    80003c6e:	0ed7e863          	bltu	a5,a3,80003d5e <readi+0xf2>
{
    80003c72:	7159                	addi	sp,sp,-112
    80003c74:	f486                	sd	ra,104(sp)
    80003c76:	f0a2                	sd	s0,96(sp)
    80003c78:	eca6                	sd	s1,88(sp)
    80003c7a:	e8ca                	sd	s2,80(sp)
    80003c7c:	e4ce                	sd	s3,72(sp)
    80003c7e:	e0d2                	sd	s4,64(sp)
    80003c80:	fc56                	sd	s5,56(sp)
    80003c82:	f85a                	sd	s6,48(sp)
    80003c84:	f45e                	sd	s7,40(sp)
    80003c86:	f062                	sd	s8,32(sp)
    80003c88:	ec66                	sd	s9,24(sp)
    80003c8a:	e86a                	sd	s10,16(sp)
    80003c8c:	e46e                	sd	s11,8(sp)
    80003c8e:	1880                	addi	s0,sp,112
    80003c90:	8baa                	mv	s7,a0
    80003c92:	8c2e                	mv	s8,a1
    80003c94:	8ab2                	mv	s5,a2
    80003c96:	84b6                	mv	s1,a3
    80003c98:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c9a:	9f35                	addw	a4,a4,a3
    return 0;
    80003c9c:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c9e:	08d76f63          	bltu	a4,a3,80003d3c <readi+0xd0>
  if(off + n > ip->size)
    80003ca2:	00e7f463          	bgeu	a5,a4,80003caa <readi+0x3e>
    n = ip->size - off;
    80003ca6:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003caa:	0a0b0863          	beqz	s6,80003d5a <readi+0xee>
    80003cae:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cb0:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003cb4:	5cfd                	li	s9,-1
    80003cb6:	a82d                	j	80003cf0 <readi+0x84>
    80003cb8:	020a1d93          	slli	s11,s4,0x20
    80003cbc:	020ddd93          	srli	s11,s11,0x20
    80003cc0:	05890613          	addi	a2,s2,88
    80003cc4:	86ee                	mv	a3,s11
    80003cc6:	963a                	add	a2,a2,a4
    80003cc8:	85d6                	mv	a1,s5
    80003cca:	8562                	mv	a0,s8
    80003ccc:	fffff097          	auipc	ra,0xfffff
    80003cd0:	b2e080e7          	jalr	-1234(ra) # 800027fa <either_copyout>
    80003cd4:	05950d63          	beq	a0,s9,80003d2e <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003cd8:	854a                	mv	a0,s2
    80003cda:	fffff097          	auipc	ra,0xfffff
    80003cde:	60c080e7          	jalr	1548(ra) # 800032e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ce2:	013a09bb          	addw	s3,s4,s3
    80003ce6:	009a04bb          	addw	s1,s4,s1
    80003cea:	9aee                	add	s5,s5,s11
    80003cec:	0569f663          	bgeu	s3,s6,80003d38 <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cf0:	000ba903          	lw	s2,0(s7)
    80003cf4:	00a4d59b          	srliw	a1,s1,0xa
    80003cf8:	855e                	mv	a0,s7
    80003cfa:	00000097          	auipc	ra,0x0
    80003cfe:	8b0080e7          	jalr	-1872(ra) # 800035aa <bmap>
    80003d02:	0005059b          	sext.w	a1,a0
    80003d06:	854a                	mv	a0,s2
    80003d08:	fffff097          	auipc	ra,0xfffff
    80003d0c:	4ae080e7          	jalr	1198(ra) # 800031b6 <bread>
    80003d10:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d12:	3ff4f713          	andi	a4,s1,1023
    80003d16:	40ed07bb          	subw	a5,s10,a4
    80003d1a:	413b06bb          	subw	a3,s6,s3
    80003d1e:	8a3e                	mv	s4,a5
    80003d20:	2781                	sext.w	a5,a5
    80003d22:	0006861b          	sext.w	a2,a3
    80003d26:	f8f679e3          	bgeu	a2,a5,80003cb8 <readi+0x4c>
    80003d2a:	8a36                	mv	s4,a3
    80003d2c:	b771                	j	80003cb8 <readi+0x4c>
      brelse(bp);
    80003d2e:	854a                	mv	a0,s2
    80003d30:	fffff097          	auipc	ra,0xfffff
    80003d34:	5b6080e7          	jalr	1462(ra) # 800032e6 <brelse>
  }
  return tot;
    80003d38:	0009851b          	sext.w	a0,s3
}
    80003d3c:	70a6                	ld	ra,104(sp)
    80003d3e:	7406                	ld	s0,96(sp)
    80003d40:	64e6                	ld	s1,88(sp)
    80003d42:	6946                	ld	s2,80(sp)
    80003d44:	69a6                	ld	s3,72(sp)
    80003d46:	6a06                	ld	s4,64(sp)
    80003d48:	7ae2                	ld	s5,56(sp)
    80003d4a:	7b42                	ld	s6,48(sp)
    80003d4c:	7ba2                	ld	s7,40(sp)
    80003d4e:	7c02                	ld	s8,32(sp)
    80003d50:	6ce2                	ld	s9,24(sp)
    80003d52:	6d42                	ld	s10,16(sp)
    80003d54:	6da2                	ld	s11,8(sp)
    80003d56:	6165                	addi	sp,sp,112
    80003d58:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d5a:	89da                	mv	s3,s6
    80003d5c:	bff1                	j	80003d38 <readi+0xcc>
    return 0;
    80003d5e:	4501                	li	a0,0
}
    80003d60:	8082                	ret

0000000080003d62 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d62:	457c                	lw	a5,76(a0)
    80003d64:	10d7e663          	bltu	a5,a3,80003e70 <writei+0x10e>
{
    80003d68:	7159                	addi	sp,sp,-112
    80003d6a:	f486                	sd	ra,104(sp)
    80003d6c:	f0a2                	sd	s0,96(sp)
    80003d6e:	eca6                	sd	s1,88(sp)
    80003d70:	e8ca                	sd	s2,80(sp)
    80003d72:	e4ce                	sd	s3,72(sp)
    80003d74:	e0d2                	sd	s4,64(sp)
    80003d76:	fc56                	sd	s5,56(sp)
    80003d78:	f85a                	sd	s6,48(sp)
    80003d7a:	f45e                	sd	s7,40(sp)
    80003d7c:	f062                	sd	s8,32(sp)
    80003d7e:	ec66                	sd	s9,24(sp)
    80003d80:	e86a                	sd	s10,16(sp)
    80003d82:	e46e                	sd	s11,8(sp)
    80003d84:	1880                	addi	s0,sp,112
    80003d86:	8baa                	mv	s7,a0
    80003d88:	8c2e                	mv	s8,a1
    80003d8a:	8ab2                	mv	s5,a2
    80003d8c:	8936                	mv	s2,a3
    80003d8e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003d90:	00e687bb          	addw	a5,a3,a4
    80003d94:	0ed7e063          	bltu	a5,a3,80003e74 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d98:	00043737          	lui	a4,0x43
    80003d9c:	0cf76e63          	bltu	a4,a5,80003e78 <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003da0:	0a0b0763          	beqz	s6,80003e4e <writei+0xec>
    80003da4:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003da6:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003daa:	5cfd                	li	s9,-1
    80003dac:	a091                	j	80003df0 <writei+0x8e>
    80003dae:	02099d93          	slli	s11,s3,0x20
    80003db2:	020ddd93          	srli	s11,s11,0x20
    80003db6:	05848513          	addi	a0,s1,88
    80003dba:	86ee                	mv	a3,s11
    80003dbc:	8656                	mv	a2,s5
    80003dbe:	85e2                	mv	a1,s8
    80003dc0:	953a                	add	a0,a0,a4
    80003dc2:	fffff097          	auipc	ra,0xfffff
    80003dc6:	a8e080e7          	jalr	-1394(ra) # 80002850 <either_copyin>
    80003dca:	07950263          	beq	a0,s9,80003e2e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dce:	8526                	mv	a0,s1
    80003dd0:	00000097          	auipc	ra,0x0
    80003dd4:	77a080e7          	jalr	1914(ra) # 8000454a <log_write>
    brelse(bp);
    80003dd8:	8526                	mv	a0,s1
    80003dda:	fffff097          	auipc	ra,0xfffff
    80003dde:	50c080e7          	jalr	1292(ra) # 800032e6 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003de2:	01498a3b          	addw	s4,s3,s4
    80003de6:	0129893b          	addw	s2,s3,s2
    80003dea:	9aee                	add	s5,s5,s11
    80003dec:	056a7663          	bgeu	s4,s6,80003e38 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003df0:	000ba483          	lw	s1,0(s7)
    80003df4:	00a9559b          	srliw	a1,s2,0xa
    80003df8:	855e                	mv	a0,s7
    80003dfa:	fffff097          	auipc	ra,0xfffff
    80003dfe:	7b0080e7          	jalr	1968(ra) # 800035aa <bmap>
    80003e02:	0005059b          	sext.w	a1,a0
    80003e06:	8526                	mv	a0,s1
    80003e08:	fffff097          	auipc	ra,0xfffff
    80003e0c:	3ae080e7          	jalr	942(ra) # 800031b6 <bread>
    80003e10:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e12:	3ff97713          	andi	a4,s2,1023
    80003e16:	40ed07bb          	subw	a5,s10,a4
    80003e1a:	414b06bb          	subw	a3,s6,s4
    80003e1e:	89be                	mv	s3,a5
    80003e20:	2781                	sext.w	a5,a5
    80003e22:	0006861b          	sext.w	a2,a3
    80003e26:	f8f674e3          	bgeu	a2,a5,80003dae <writei+0x4c>
    80003e2a:	89b6                	mv	s3,a3
    80003e2c:	b749                	j	80003dae <writei+0x4c>
      brelse(bp);
    80003e2e:	8526                	mv	a0,s1
    80003e30:	fffff097          	auipc	ra,0xfffff
    80003e34:	4b6080e7          	jalr	1206(ra) # 800032e6 <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003e38:	04cba783          	lw	a5,76(s7)
    80003e3c:	0127f463          	bgeu	a5,s2,80003e44 <writei+0xe2>
      ip->size = off;
    80003e40:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003e44:	855e                	mv	a0,s7
    80003e46:	00000097          	auipc	ra,0x0
    80003e4a:	aa8080e7          	jalr	-1368(ra) # 800038ee <iupdate>
  }

  return n;
    80003e4e:	000b051b          	sext.w	a0,s6
}
    80003e52:	70a6                	ld	ra,104(sp)
    80003e54:	7406                	ld	s0,96(sp)
    80003e56:	64e6                	ld	s1,88(sp)
    80003e58:	6946                	ld	s2,80(sp)
    80003e5a:	69a6                	ld	s3,72(sp)
    80003e5c:	6a06                	ld	s4,64(sp)
    80003e5e:	7ae2                	ld	s5,56(sp)
    80003e60:	7b42                	ld	s6,48(sp)
    80003e62:	7ba2                	ld	s7,40(sp)
    80003e64:	7c02                	ld	s8,32(sp)
    80003e66:	6ce2                	ld	s9,24(sp)
    80003e68:	6d42                	ld	s10,16(sp)
    80003e6a:	6da2                	ld	s11,8(sp)
    80003e6c:	6165                	addi	sp,sp,112
    80003e6e:	8082                	ret
    return -1;
    80003e70:	557d                	li	a0,-1
}
    80003e72:	8082                	ret
    return -1;
    80003e74:	557d                	li	a0,-1
    80003e76:	bff1                	j	80003e52 <writei+0xf0>
    return -1;
    80003e78:	557d                	li	a0,-1
    80003e7a:	bfe1                	j	80003e52 <writei+0xf0>

0000000080003e7c <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e7c:	1141                	addi	sp,sp,-16
    80003e7e:	e406                	sd	ra,8(sp)
    80003e80:	e022                	sd	s0,0(sp)
    80003e82:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e84:	4639                	li	a2,14
    80003e86:	ffffd097          	auipc	ra,0xffffd
    80003e8a:	f62080e7          	jalr	-158(ra) # 80000de8 <strncmp>
}
    80003e8e:	60a2                	ld	ra,8(sp)
    80003e90:	6402                	ld	s0,0(sp)
    80003e92:	0141                	addi	sp,sp,16
    80003e94:	8082                	ret

0000000080003e96 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e96:	7139                	addi	sp,sp,-64
    80003e98:	fc06                	sd	ra,56(sp)
    80003e9a:	f822                	sd	s0,48(sp)
    80003e9c:	f426                	sd	s1,40(sp)
    80003e9e:	f04a                	sd	s2,32(sp)
    80003ea0:	ec4e                	sd	s3,24(sp)
    80003ea2:	e852                	sd	s4,16(sp)
    80003ea4:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003ea6:	04451703          	lh	a4,68(a0)
    80003eaa:	4785                	li	a5,1
    80003eac:	00f71a63          	bne	a4,a5,80003ec0 <dirlookup+0x2a>
    80003eb0:	892a                	mv	s2,a0
    80003eb2:	89ae                	mv	s3,a1
    80003eb4:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb6:	457c                	lw	a5,76(a0)
    80003eb8:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eba:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ebc:	e79d                	bnez	a5,80003eea <dirlookup+0x54>
    80003ebe:	a8a5                	j	80003f36 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003ec0:	00004517          	auipc	a0,0x4
    80003ec4:	75050513          	addi	a0,a0,1872 # 80008610 <syscalls+0x1a0>
    80003ec8:	ffffc097          	auipc	ra,0xffffc
    80003ecc:	680080e7          	jalr	1664(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003ed0:	00004517          	auipc	a0,0x4
    80003ed4:	75850513          	addi	a0,a0,1880 # 80008628 <syscalls+0x1b8>
    80003ed8:	ffffc097          	auipc	ra,0xffffc
    80003edc:	670080e7          	jalr	1648(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ee0:	24c1                	addiw	s1,s1,16
    80003ee2:	04c92783          	lw	a5,76(s2)
    80003ee6:	04f4f763          	bgeu	s1,a5,80003f34 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eea:	4741                	li	a4,16
    80003eec:	86a6                	mv	a3,s1
    80003eee:	fc040613          	addi	a2,s0,-64
    80003ef2:	4581                	li	a1,0
    80003ef4:	854a                	mv	a0,s2
    80003ef6:	00000097          	auipc	ra,0x0
    80003efa:	d76080e7          	jalr	-650(ra) # 80003c6c <readi>
    80003efe:	47c1                	li	a5,16
    80003f00:	fcf518e3          	bne	a0,a5,80003ed0 <dirlookup+0x3a>
    if(de.inum == 0)
    80003f04:	fc045783          	lhu	a5,-64(s0)
    80003f08:	dfe1                	beqz	a5,80003ee0 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003f0a:	fc240593          	addi	a1,s0,-62
    80003f0e:	854e                	mv	a0,s3
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	f6c080e7          	jalr	-148(ra) # 80003e7c <namecmp>
    80003f18:	f561                	bnez	a0,80003ee0 <dirlookup+0x4a>
      if(poff)
    80003f1a:	000a0463          	beqz	s4,80003f22 <dirlookup+0x8c>
        *poff = off;
    80003f1e:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f22:	fc045583          	lhu	a1,-64(s0)
    80003f26:	00092503          	lw	a0,0(s2)
    80003f2a:	fffff097          	auipc	ra,0xfffff
    80003f2e:	75a080e7          	jalr	1882(ra) # 80003684 <iget>
    80003f32:	a011                	j	80003f36 <dirlookup+0xa0>
  return 0;
    80003f34:	4501                	li	a0,0
}
    80003f36:	70e2                	ld	ra,56(sp)
    80003f38:	7442                	ld	s0,48(sp)
    80003f3a:	74a2                	ld	s1,40(sp)
    80003f3c:	7902                	ld	s2,32(sp)
    80003f3e:	69e2                	ld	s3,24(sp)
    80003f40:	6a42                	ld	s4,16(sp)
    80003f42:	6121                	addi	sp,sp,64
    80003f44:	8082                	ret

0000000080003f46 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f46:	711d                	addi	sp,sp,-96
    80003f48:	ec86                	sd	ra,88(sp)
    80003f4a:	e8a2                	sd	s0,80(sp)
    80003f4c:	e4a6                	sd	s1,72(sp)
    80003f4e:	e0ca                	sd	s2,64(sp)
    80003f50:	fc4e                	sd	s3,56(sp)
    80003f52:	f852                	sd	s4,48(sp)
    80003f54:	f456                	sd	s5,40(sp)
    80003f56:	f05a                	sd	s6,32(sp)
    80003f58:	ec5e                	sd	s7,24(sp)
    80003f5a:	e862                	sd	s8,16(sp)
    80003f5c:	e466                	sd	s9,8(sp)
    80003f5e:	1080                	addi	s0,sp,96
    80003f60:	84aa                	mv	s1,a0
    80003f62:	8b2e                	mv	s6,a1
    80003f64:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f66:	00054703          	lbu	a4,0(a0)
    80003f6a:	02f00793          	li	a5,47
    80003f6e:	02f70363          	beq	a4,a5,80003f94 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f72:	ffffe097          	auipc	ra,0xffffe
    80003f76:	c42080e7          	jalr	-958(ra) # 80001bb4 <myproc>
    80003f7a:	15853503          	ld	a0,344(a0)
    80003f7e:	00000097          	auipc	ra,0x0
    80003f82:	9fc080e7          	jalr	-1540(ra) # 8000397a <idup>
    80003f86:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f88:	02f00913          	li	s2,47
  len = path - s;
    80003f8c:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f8e:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f90:	4c05                	li	s8,1
    80003f92:	a865                	j	8000404a <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f94:	4585                	li	a1,1
    80003f96:	4505                	li	a0,1
    80003f98:	fffff097          	auipc	ra,0xfffff
    80003f9c:	6ec080e7          	jalr	1772(ra) # 80003684 <iget>
    80003fa0:	89aa                	mv	s3,a0
    80003fa2:	b7dd                	j	80003f88 <namex+0x42>
      iunlockput(ip);
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	00000097          	auipc	ra,0x0
    80003faa:	c74080e7          	jalr	-908(ra) # 80003c1a <iunlockput>
      return 0;
    80003fae:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fb0:	854e                	mv	a0,s3
    80003fb2:	60e6                	ld	ra,88(sp)
    80003fb4:	6446                	ld	s0,80(sp)
    80003fb6:	64a6                	ld	s1,72(sp)
    80003fb8:	6906                	ld	s2,64(sp)
    80003fba:	79e2                	ld	s3,56(sp)
    80003fbc:	7a42                	ld	s4,48(sp)
    80003fbe:	7aa2                	ld	s5,40(sp)
    80003fc0:	7b02                	ld	s6,32(sp)
    80003fc2:	6be2                	ld	s7,24(sp)
    80003fc4:	6c42                	ld	s8,16(sp)
    80003fc6:	6ca2                	ld	s9,8(sp)
    80003fc8:	6125                	addi	sp,sp,96
    80003fca:	8082                	ret
      iunlock(ip);
    80003fcc:	854e                	mv	a0,s3
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	aac080e7          	jalr	-1364(ra) # 80003a7a <iunlock>
      return ip;
    80003fd6:	bfe9                	j	80003fb0 <namex+0x6a>
      iunlockput(ip);
    80003fd8:	854e                	mv	a0,s3
    80003fda:	00000097          	auipc	ra,0x0
    80003fde:	c40080e7          	jalr	-960(ra) # 80003c1a <iunlockput>
      return 0;
    80003fe2:	89d2                	mv	s3,s4
    80003fe4:	b7f1                	j	80003fb0 <namex+0x6a>
  len = path - s;
    80003fe6:	40b48633          	sub	a2,s1,a1
    80003fea:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fee:	094cd463          	bge	s9,s4,80004076 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003ff2:	4639                	li	a2,14
    80003ff4:	8556                	mv	a0,s5
    80003ff6:	ffffd097          	auipc	ra,0xffffd
    80003ffa:	d76080e7          	jalr	-650(ra) # 80000d6c <memmove>
  while(*path == '/')
    80003ffe:	0004c783          	lbu	a5,0(s1)
    80004002:	01279763          	bne	a5,s2,80004010 <namex+0xca>
    path++;
    80004006:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004008:	0004c783          	lbu	a5,0(s1)
    8000400c:	ff278de3          	beq	a5,s2,80004006 <namex+0xc0>
    ilock(ip);
    80004010:	854e                	mv	a0,s3
    80004012:	00000097          	auipc	ra,0x0
    80004016:	9a6080e7          	jalr	-1626(ra) # 800039b8 <ilock>
    if(ip->type != T_DIR){
    8000401a:	04499783          	lh	a5,68(s3)
    8000401e:	f98793e3          	bne	a5,s8,80003fa4 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004022:	000b0563          	beqz	s6,8000402c <namex+0xe6>
    80004026:	0004c783          	lbu	a5,0(s1)
    8000402a:	d3cd                	beqz	a5,80003fcc <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000402c:	865e                	mv	a2,s7
    8000402e:	85d6                	mv	a1,s5
    80004030:	854e                	mv	a0,s3
    80004032:	00000097          	auipc	ra,0x0
    80004036:	e64080e7          	jalr	-412(ra) # 80003e96 <dirlookup>
    8000403a:	8a2a                	mv	s4,a0
    8000403c:	dd51                	beqz	a0,80003fd8 <namex+0x92>
    iunlockput(ip);
    8000403e:	854e                	mv	a0,s3
    80004040:	00000097          	auipc	ra,0x0
    80004044:	bda080e7          	jalr	-1062(ra) # 80003c1a <iunlockput>
    ip = next;
    80004048:	89d2                	mv	s3,s4
  while(*path == '/')
    8000404a:	0004c783          	lbu	a5,0(s1)
    8000404e:	05279763          	bne	a5,s2,8000409c <namex+0x156>
    path++;
    80004052:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004054:	0004c783          	lbu	a5,0(s1)
    80004058:	ff278de3          	beq	a5,s2,80004052 <namex+0x10c>
  if(*path == 0)
    8000405c:	c79d                	beqz	a5,8000408a <namex+0x144>
    path++;
    8000405e:	85a6                	mv	a1,s1
  len = path - s;
    80004060:	8a5e                	mv	s4,s7
    80004062:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004064:	01278963          	beq	a5,s2,80004076 <namex+0x130>
    80004068:	dfbd                	beqz	a5,80003fe6 <namex+0xa0>
    path++;
    8000406a:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000406c:	0004c783          	lbu	a5,0(s1)
    80004070:	ff279ce3          	bne	a5,s2,80004068 <namex+0x122>
    80004074:	bf8d                	j	80003fe6 <namex+0xa0>
    memmove(name, s, len);
    80004076:	2601                	sext.w	a2,a2
    80004078:	8556                	mv	a0,s5
    8000407a:	ffffd097          	auipc	ra,0xffffd
    8000407e:	cf2080e7          	jalr	-782(ra) # 80000d6c <memmove>
    name[len] = 0;
    80004082:	9a56                	add	s4,s4,s5
    80004084:	000a0023          	sb	zero,0(s4)
    80004088:	bf9d                	j	80003ffe <namex+0xb8>
  if(nameiparent){
    8000408a:	f20b03e3          	beqz	s6,80003fb0 <namex+0x6a>
    iput(ip);
    8000408e:	854e                	mv	a0,s3
    80004090:	00000097          	auipc	ra,0x0
    80004094:	ae2080e7          	jalr	-1310(ra) # 80003b72 <iput>
    return 0;
    80004098:	4981                	li	s3,0
    8000409a:	bf19                	j	80003fb0 <namex+0x6a>
  if(*path == 0)
    8000409c:	d7fd                	beqz	a5,8000408a <namex+0x144>
  while(*path != '/' && *path != 0)
    8000409e:	0004c783          	lbu	a5,0(s1)
    800040a2:	85a6                	mv	a1,s1
    800040a4:	b7d1                	j	80004068 <namex+0x122>

00000000800040a6 <dirlink>:
{
    800040a6:	7139                	addi	sp,sp,-64
    800040a8:	fc06                	sd	ra,56(sp)
    800040aa:	f822                	sd	s0,48(sp)
    800040ac:	f426                	sd	s1,40(sp)
    800040ae:	f04a                	sd	s2,32(sp)
    800040b0:	ec4e                	sd	s3,24(sp)
    800040b2:	e852                	sd	s4,16(sp)
    800040b4:	0080                	addi	s0,sp,64
    800040b6:	892a                	mv	s2,a0
    800040b8:	8a2e                	mv	s4,a1
    800040ba:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040bc:	4601                	li	a2,0
    800040be:	00000097          	auipc	ra,0x0
    800040c2:	dd8080e7          	jalr	-552(ra) # 80003e96 <dirlookup>
    800040c6:	e93d                	bnez	a0,8000413c <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040c8:	04c92483          	lw	s1,76(s2)
    800040cc:	c49d                	beqz	s1,800040fa <dirlink+0x54>
    800040ce:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040d0:	4741                	li	a4,16
    800040d2:	86a6                	mv	a3,s1
    800040d4:	fc040613          	addi	a2,s0,-64
    800040d8:	4581                	li	a1,0
    800040da:	854a                	mv	a0,s2
    800040dc:	00000097          	auipc	ra,0x0
    800040e0:	b90080e7          	jalr	-1136(ra) # 80003c6c <readi>
    800040e4:	47c1                	li	a5,16
    800040e6:	06f51163          	bne	a0,a5,80004148 <dirlink+0xa2>
    if(de.inum == 0)
    800040ea:	fc045783          	lhu	a5,-64(s0)
    800040ee:	c791                	beqz	a5,800040fa <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040f0:	24c1                	addiw	s1,s1,16
    800040f2:	04c92783          	lw	a5,76(s2)
    800040f6:	fcf4ede3          	bltu	s1,a5,800040d0 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040fa:	4639                	li	a2,14
    800040fc:	85d2                	mv	a1,s4
    800040fe:	fc240513          	addi	a0,s0,-62
    80004102:	ffffd097          	auipc	ra,0xffffd
    80004106:	d22080e7          	jalr	-734(ra) # 80000e24 <strncpy>
  de.inum = inum;
    8000410a:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000410e:	4741                	li	a4,16
    80004110:	86a6                	mv	a3,s1
    80004112:	fc040613          	addi	a2,s0,-64
    80004116:	4581                	li	a1,0
    80004118:	854a                	mv	a0,s2
    8000411a:	00000097          	auipc	ra,0x0
    8000411e:	c48080e7          	jalr	-952(ra) # 80003d62 <writei>
    80004122:	872a                	mv	a4,a0
    80004124:	47c1                	li	a5,16
  return 0;
    80004126:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004128:	02f71863          	bne	a4,a5,80004158 <dirlink+0xb2>
}
    8000412c:	70e2                	ld	ra,56(sp)
    8000412e:	7442                	ld	s0,48(sp)
    80004130:	74a2                	ld	s1,40(sp)
    80004132:	7902                	ld	s2,32(sp)
    80004134:	69e2                	ld	s3,24(sp)
    80004136:	6a42                	ld	s4,16(sp)
    80004138:	6121                	addi	sp,sp,64
    8000413a:	8082                	ret
    iput(ip);
    8000413c:	00000097          	auipc	ra,0x0
    80004140:	a36080e7          	jalr	-1482(ra) # 80003b72 <iput>
    return -1;
    80004144:	557d                	li	a0,-1
    80004146:	b7dd                	j	8000412c <dirlink+0x86>
      panic("dirlink read");
    80004148:	00004517          	auipc	a0,0x4
    8000414c:	4f050513          	addi	a0,a0,1264 # 80008638 <syscalls+0x1c8>
    80004150:	ffffc097          	auipc	ra,0xffffc
    80004154:	3f8080e7          	jalr	1016(ra) # 80000548 <panic>
    panic("dirlink");
    80004158:	00004517          	auipc	a0,0x4
    8000415c:	5f850513          	addi	a0,a0,1528 # 80008750 <syscalls+0x2e0>
    80004160:	ffffc097          	auipc	ra,0xffffc
    80004164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>

0000000080004168 <namei>:

struct inode*
namei(char *path)
{
    80004168:	1101                	addi	sp,sp,-32
    8000416a:	ec06                	sd	ra,24(sp)
    8000416c:	e822                	sd	s0,16(sp)
    8000416e:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004170:	fe040613          	addi	a2,s0,-32
    80004174:	4581                	li	a1,0
    80004176:	00000097          	auipc	ra,0x0
    8000417a:	dd0080e7          	jalr	-560(ra) # 80003f46 <namex>
}
    8000417e:	60e2                	ld	ra,24(sp)
    80004180:	6442                	ld	s0,16(sp)
    80004182:	6105                	addi	sp,sp,32
    80004184:	8082                	ret

0000000080004186 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004186:	1141                	addi	sp,sp,-16
    80004188:	e406                	sd	ra,8(sp)
    8000418a:	e022                	sd	s0,0(sp)
    8000418c:	0800                	addi	s0,sp,16
    8000418e:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004190:	4585                	li	a1,1
    80004192:	00000097          	auipc	ra,0x0
    80004196:	db4080e7          	jalr	-588(ra) # 80003f46 <namex>
}
    8000419a:	60a2                	ld	ra,8(sp)
    8000419c:	6402                	ld	s0,0(sp)
    8000419e:	0141                	addi	sp,sp,16
    800041a0:	8082                	ret

00000000800041a2 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800041a2:	1101                	addi	sp,sp,-32
    800041a4:	ec06                	sd	ra,24(sp)
    800041a6:	e822                	sd	s0,16(sp)
    800041a8:	e426                	sd	s1,8(sp)
    800041aa:	e04a                	sd	s2,0(sp)
    800041ac:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041ae:	0001e917          	auipc	s2,0x1e
    800041b2:	95a90913          	addi	s2,s2,-1702 # 80021b08 <log>
    800041b6:	01892583          	lw	a1,24(s2)
    800041ba:	02892503          	lw	a0,40(s2)
    800041be:	fffff097          	auipc	ra,0xfffff
    800041c2:	ff8080e7          	jalr	-8(ra) # 800031b6 <bread>
    800041c6:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041c8:	02c92683          	lw	a3,44(s2)
    800041cc:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041ce:	02d05763          	blez	a3,800041fc <write_head+0x5a>
    800041d2:	0001e797          	auipc	a5,0x1e
    800041d6:	96678793          	addi	a5,a5,-1690 # 80021b38 <log+0x30>
    800041da:	05c50713          	addi	a4,a0,92
    800041de:	36fd                	addiw	a3,a3,-1
    800041e0:	1682                	slli	a3,a3,0x20
    800041e2:	9281                	srli	a3,a3,0x20
    800041e4:	068a                	slli	a3,a3,0x2
    800041e6:	0001e617          	auipc	a2,0x1e
    800041ea:	95660613          	addi	a2,a2,-1706 # 80021b3c <log+0x34>
    800041ee:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041f0:	4390                	lw	a2,0(a5)
    800041f2:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041f4:	0791                	addi	a5,a5,4
    800041f6:	0711                	addi	a4,a4,4
    800041f8:	fed79ce3          	bne	a5,a3,800041f0 <write_head+0x4e>
  }
  bwrite(buf);
    800041fc:	8526                	mv	a0,s1
    800041fe:	fffff097          	auipc	ra,0xfffff
    80004202:	0aa080e7          	jalr	170(ra) # 800032a8 <bwrite>
  brelse(buf);
    80004206:	8526                	mv	a0,s1
    80004208:	fffff097          	auipc	ra,0xfffff
    8000420c:	0de080e7          	jalr	222(ra) # 800032e6 <brelse>
}
    80004210:	60e2                	ld	ra,24(sp)
    80004212:	6442                	ld	s0,16(sp)
    80004214:	64a2                	ld	s1,8(sp)
    80004216:	6902                	ld	s2,0(sp)
    80004218:	6105                	addi	sp,sp,32
    8000421a:	8082                	ret

000000008000421c <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    8000421c:	0001e797          	auipc	a5,0x1e
    80004220:	9187a783          	lw	a5,-1768(a5) # 80021b34 <log+0x2c>
    80004224:	0af05663          	blez	a5,800042d0 <install_trans+0xb4>
{
    80004228:	7139                	addi	sp,sp,-64
    8000422a:	fc06                	sd	ra,56(sp)
    8000422c:	f822                	sd	s0,48(sp)
    8000422e:	f426                	sd	s1,40(sp)
    80004230:	f04a                	sd	s2,32(sp)
    80004232:	ec4e                	sd	s3,24(sp)
    80004234:	e852                	sd	s4,16(sp)
    80004236:	e456                	sd	s5,8(sp)
    80004238:	0080                	addi	s0,sp,64
    8000423a:	0001ea97          	auipc	s5,0x1e
    8000423e:	8fea8a93          	addi	s5,s5,-1794 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004242:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004244:	0001e997          	auipc	s3,0x1e
    80004248:	8c498993          	addi	s3,s3,-1852 # 80021b08 <log>
    8000424c:	0189a583          	lw	a1,24(s3)
    80004250:	014585bb          	addw	a1,a1,s4
    80004254:	2585                	addiw	a1,a1,1
    80004256:	0289a503          	lw	a0,40(s3)
    8000425a:	fffff097          	auipc	ra,0xfffff
    8000425e:	f5c080e7          	jalr	-164(ra) # 800031b6 <bread>
    80004262:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004264:	000aa583          	lw	a1,0(s5)
    80004268:	0289a503          	lw	a0,40(s3)
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	f4a080e7          	jalr	-182(ra) # 800031b6 <bread>
    80004274:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004276:	40000613          	li	a2,1024
    8000427a:	05890593          	addi	a1,s2,88
    8000427e:	05850513          	addi	a0,a0,88
    80004282:	ffffd097          	auipc	ra,0xffffd
    80004286:	aea080e7          	jalr	-1302(ra) # 80000d6c <memmove>
    bwrite(dbuf);  // write dst to disk
    8000428a:	8526                	mv	a0,s1
    8000428c:	fffff097          	auipc	ra,0xfffff
    80004290:	01c080e7          	jalr	28(ra) # 800032a8 <bwrite>
    bunpin(dbuf);
    80004294:	8526                	mv	a0,s1
    80004296:	fffff097          	auipc	ra,0xfffff
    8000429a:	12a080e7          	jalr	298(ra) # 800033c0 <bunpin>
    brelse(lbuf);
    8000429e:	854a                	mv	a0,s2
    800042a0:	fffff097          	auipc	ra,0xfffff
    800042a4:	046080e7          	jalr	70(ra) # 800032e6 <brelse>
    brelse(dbuf);
    800042a8:	8526                	mv	a0,s1
    800042aa:	fffff097          	auipc	ra,0xfffff
    800042ae:	03c080e7          	jalr	60(ra) # 800032e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042b2:	2a05                	addiw	s4,s4,1
    800042b4:	0a91                	addi	s5,s5,4
    800042b6:	02c9a783          	lw	a5,44(s3)
    800042ba:	f8fa49e3          	blt	s4,a5,8000424c <install_trans+0x30>
}
    800042be:	70e2                	ld	ra,56(sp)
    800042c0:	7442                	ld	s0,48(sp)
    800042c2:	74a2                	ld	s1,40(sp)
    800042c4:	7902                	ld	s2,32(sp)
    800042c6:	69e2                	ld	s3,24(sp)
    800042c8:	6a42                	ld	s4,16(sp)
    800042ca:	6aa2                	ld	s5,8(sp)
    800042cc:	6121                	addi	sp,sp,64
    800042ce:	8082                	ret
    800042d0:	8082                	ret

00000000800042d2 <initlog>:
{
    800042d2:	7179                	addi	sp,sp,-48
    800042d4:	f406                	sd	ra,40(sp)
    800042d6:	f022                	sd	s0,32(sp)
    800042d8:	ec26                	sd	s1,24(sp)
    800042da:	e84a                	sd	s2,16(sp)
    800042dc:	e44e                	sd	s3,8(sp)
    800042de:	1800                	addi	s0,sp,48
    800042e0:	892a                	mv	s2,a0
    800042e2:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042e4:	0001e497          	auipc	s1,0x1e
    800042e8:	82448493          	addi	s1,s1,-2012 # 80021b08 <log>
    800042ec:	00004597          	auipc	a1,0x4
    800042f0:	35c58593          	addi	a1,a1,860 # 80008648 <syscalls+0x1d8>
    800042f4:	8526                	mv	a0,s1
    800042f6:	ffffd097          	auipc	ra,0xffffd
    800042fa:	88a080e7          	jalr	-1910(ra) # 80000b80 <initlock>
  log.start = sb->logstart;
    800042fe:	0149a583          	lw	a1,20(s3)
    80004302:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004304:	0109a783          	lw	a5,16(s3)
    80004308:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000430a:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    8000430e:	854a                	mv	a0,s2
    80004310:	fffff097          	auipc	ra,0xfffff
    80004314:	ea6080e7          	jalr	-346(ra) # 800031b6 <bread>
  log.lh.n = lh->n;
    80004318:	4d3c                	lw	a5,88(a0)
    8000431a:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000431c:	02f05563          	blez	a5,80004346 <initlog+0x74>
    80004320:	05c50713          	addi	a4,a0,92
    80004324:	0001e697          	auipc	a3,0x1e
    80004328:	81468693          	addi	a3,a3,-2028 # 80021b38 <log+0x30>
    8000432c:	37fd                	addiw	a5,a5,-1
    8000432e:	1782                	slli	a5,a5,0x20
    80004330:	9381                	srli	a5,a5,0x20
    80004332:	078a                	slli	a5,a5,0x2
    80004334:	06050613          	addi	a2,a0,96
    80004338:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000433a:	4310                	lw	a2,0(a4)
    8000433c:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000433e:	0711                	addi	a4,a4,4
    80004340:	0691                	addi	a3,a3,4
    80004342:	fef71ce3          	bne	a4,a5,8000433a <initlog+0x68>
  brelse(buf);
    80004346:	fffff097          	auipc	ra,0xfffff
    8000434a:	fa0080e7          	jalr	-96(ra) # 800032e6 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    8000434e:	00000097          	auipc	ra,0x0
    80004352:	ece080e7          	jalr	-306(ra) # 8000421c <install_trans>
  log.lh.n = 0;
    80004356:	0001d797          	auipc	a5,0x1d
    8000435a:	7c07af23          	sw	zero,2014(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    8000435e:	00000097          	auipc	ra,0x0
    80004362:	e44080e7          	jalr	-444(ra) # 800041a2 <write_head>
}
    80004366:	70a2                	ld	ra,40(sp)
    80004368:	7402                	ld	s0,32(sp)
    8000436a:	64e2                	ld	s1,24(sp)
    8000436c:	6942                	ld	s2,16(sp)
    8000436e:	69a2                	ld	s3,8(sp)
    80004370:	6145                	addi	sp,sp,48
    80004372:	8082                	ret

0000000080004374 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004374:	1101                	addi	sp,sp,-32
    80004376:	ec06                	sd	ra,24(sp)
    80004378:	e822                	sd	s0,16(sp)
    8000437a:	e426                	sd	s1,8(sp)
    8000437c:	e04a                	sd	s2,0(sp)
    8000437e:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004380:	0001d517          	auipc	a0,0x1d
    80004384:	78850513          	addi	a0,a0,1928 # 80021b08 <log>
    80004388:	ffffd097          	auipc	ra,0xffffd
    8000438c:	888080e7          	jalr	-1912(ra) # 80000c10 <acquire>
  while(1){
    if(log.committing){
    80004390:	0001d497          	auipc	s1,0x1d
    80004394:	77848493          	addi	s1,s1,1912 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004398:	4979                	li	s2,30
    8000439a:	a039                	j	800043a8 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000439c:	85a6                	mv	a1,s1
    8000439e:	8526                	mv	a0,s1
    800043a0:	ffffe097          	auipc	ra,0xffffe
    800043a4:	1f8080e7          	jalr	504(ra) # 80002598 <sleep>
    if(log.committing){
    800043a8:	50dc                	lw	a5,36(s1)
    800043aa:	fbed                	bnez	a5,8000439c <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043ac:	509c                	lw	a5,32(s1)
    800043ae:	0017871b          	addiw	a4,a5,1
    800043b2:	0007069b          	sext.w	a3,a4
    800043b6:	0027179b          	slliw	a5,a4,0x2
    800043ba:	9fb9                	addw	a5,a5,a4
    800043bc:	0017979b          	slliw	a5,a5,0x1
    800043c0:	54d8                	lw	a4,44(s1)
    800043c2:	9fb9                	addw	a5,a5,a4
    800043c4:	00f95963          	bge	s2,a5,800043d6 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043c8:	85a6                	mv	a1,s1
    800043ca:	8526                	mv	a0,s1
    800043cc:	ffffe097          	auipc	ra,0xffffe
    800043d0:	1cc080e7          	jalr	460(ra) # 80002598 <sleep>
    800043d4:	bfd1                	j	800043a8 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043d6:	0001d517          	auipc	a0,0x1d
    800043da:	73250513          	addi	a0,a0,1842 # 80021b08 <log>
    800043de:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043e0:	ffffd097          	auipc	ra,0xffffd
    800043e4:	8e4080e7          	jalr	-1820(ra) # 80000cc4 <release>
      break;
    }
  }
}
    800043e8:	60e2                	ld	ra,24(sp)
    800043ea:	6442                	ld	s0,16(sp)
    800043ec:	64a2                	ld	s1,8(sp)
    800043ee:	6902                	ld	s2,0(sp)
    800043f0:	6105                	addi	sp,sp,32
    800043f2:	8082                	ret

00000000800043f4 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043f4:	7139                	addi	sp,sp,-64
    800043f6:	fc06                	sd	ra,56(sp)
    800043f8:	f822                	sd	s0,48(sp)
    800043fa:	f426                	sd	s1,40(sp)
    800043fc:	f04a                	sd	s2,32(sp)
    800043fe:	ec4e                	sd	s3,24(sp)
    80004400:	e852                	sd	s4,16(sp)
    80004402:	e456                	sd	s5,8(sp)
    80004404:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004406:	0001d497          	auipc	s1,0x1d
    8000440a:	70248493          	addi	s1,s1,1794 # 80021b08 <log>
    8000440e:	8526                	mv	a0,s1
    80004410:	ffffd097          	auipc	ra,0xffffd
    80004414:	800080e7          	jalr	-2048(ra) # 80000c10 <acquire>
  log.outstanding -= 1;
    80004418:	509c                	lw	a5,32(s1)
    8000441a:	37fd                	addiw	a5,a5,-1
    8000441c:	0007891b          	sext.w	s2,a5
    80004420:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004422:	50dc                	lw	a5,36(s1)
    80004424:	efb9                	bnez	a5,80004482 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004426:	06091663          	bnez	s2,80004492 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000442a:	0001d497          	auipc	s1,0x1d
    8000442e:	6de48493          	addi	s1,s1,1758 # 80021b08 <log>
    80004432:	4785                	li	a5,1
    80004434:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004436:	8526                	mv	a0,s1
    80004438:	ffffd097          	auipc	ra,0xffffd
    8000443c:	88c080e7          	jalr	-1908(ra) # 80000cc4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004440:	54dc                	lw	a5,44(s1)
    80004442:	06f04763          	bgtz	a5,800044b0 <end_op+0xbc>
    acquire(&log.lock);
    80004446:	0001d497          	auipc	s1,0x1d
    8000444a:	6c248493          	addi	s1,s1,1730 # 80021b08 <log>
    8000444e:	8526                	mv	a0,s1
    80004450:	ffffc097          	auipc	ra,0xffffc
    80004454:	7c0080e7          	jalr	1984(ra) # 80000c10 <acquire>
    log.committing = 0;
    80004458:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    8000445c:	8526                	mv	a0,s1
    8000445e:	ffffe097          	auipc	ra,0xffffe
    80004462:	2c0080e7          	jalr	704(ra) # 8000271e <wakeup>
    release(&log.lock);
    80004466:	8526                	mv	a0,s1
    80004468:	ffffd097          	auipc	ra,0xffffd
    8000446c:	85c080e7          	jalr	-1956(ra) # 80000cc4 <release>
}
    80004470:	70e2                	ld	ra,56(sp)
    80004472:	7442                	ld	s0,48(sp)
    80004474:	74a2                	ld	s1,40(sp)
    80004476:	7902                	ld	s2,32(sp)
    80004478:	69e2                	ld	s3,24(sp)
    8000447a:	6a42                	ld	s4,16(sp)
    8000447c:	6aa2                	ld	s5,8(sp)
    8000447e:	6121                	addi	sp,sp,64
    80004480:	8082                	ret
    panic("log.committing");
    80004482:	00004517          	auipc	a0,0x4
    80004486:	1ce50513          	addi	a0,a0,462 # 80008650 <syscalls+0x1e0>
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	0be080e7          	jalr	190(ra) # 80000548 <panic>
    wakeup(&log);
    80004492:	0001d497          	auipc	s1,0x1d
    80004496:	67648493          	addi	s1,s1,1654 # 80021b08 <log>
    8000449a:	8526                	mv	a0,s1
    8000449c:	ffffe097          	auipc	ra,0xffffe
    800044a0:	282080e7          	jalr	642(ra) # 8000271e <wakeup>
  release(&log.lock);
    800044a4:	8526                	mv	a0,s1
    800044a6:	ffffd097          	auipc	ra,0xffffd
    800044aa:	81e080e7          	jalr	-2018(ra) # 80000cc4 <release>
  if(do_commit){
    800044ae:	b7c9                	j	80004470 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b0:	0001da97          	auipc	s5,0x1d
    800044b4:	688a8a93          	addi	s5,s5,1672 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044b8:	0001da17          	auipc	s4,0x1d
    800044bc:	650a0a13          	addi	s4,s4,1616 # 80021b08 <log>
    800044c0:	018a2583          	lw	a1,24(s4)
    800044c4:	012585bb          	addw	a1,a1,s2
    800044c8:	2585                	addiw	a1,a1,1
    800044ca:	028a2503          	lw	a0,40(s4)
    800044ce:	fffff097          	auipc	ra,0xfffff
    800044d2:	ce8080e7          	jalr	-792(ra) # 800031b6 <bread>
    800044d6:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044d8:	000aa583          	lw	a1,0(s5)
    800044dc:	028a2503          	lw	a0,40(s4)
    800044e0:	fffff097          	auipc	ra,0xfffff
    800044e4:	cd6080e7          	jalr	-810(ra) # 800031b6 <bread>
    800044e8:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ea:	40000613          	li	a2,1024
    800044ee:	05850593          	addi	a1,a0,88
    800044f2:	05848513          	addi	a0,s1,88
    800044f6:	ffffd097          	auipc	ra,0xffffd
    800044fa:	876080e7          	jalr	-1930(ra) # 80000d6c <memmove>
    bwrite(to);  // write the log
    800044fe:	8526                	mv	a0,s1
    80004500:	fffff097          	auipc	ra,0xfffff
    80004504:	da8080e7          	jalr	-600(ra) # 800032a8 <bwrite>
    brelse(from);
    80004508:	854e                	mv	a0,s3
    8000450a:	fffff097          	auipc	ra,0xfffff
    8000450e:	ddc080e7          	jalr	-548(ra) # 800032e6 <brelse>
    brelse(to);
    80004512:	8526                	mv	a0,s1
    80004514:	fffff097          	auipc	ra,0xfffff
    80004518:	dd2080e7          	jalr	-558(ra) # 800032e6 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000451c:	2905                	addiw	s2,s2,1
    8000451e:	0a91                	addi	s5,s5,4
    80004520:	02ca2783          	lw	a5,44(s4)
    80004524:	f8f94ee3          	blt	s2,a5,800044c0 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004528:	00000097          	auipc	ra,0x0
    8000452c:	c7a080e7          	jalr	-902(ra) # 800041a2 <write_head>
    install_trans(); // Now install writes to home locations
    80004530:	00000097          	auipc	ra,0x0
    80004534:	cec080e7          	jalr	-788(ra) # 8000421c <install_trans>
    log.lh.n = 0;
    80004538:	0001d797          	auipc	a5,0x1d
    8000453c:	5e07ae23          	sw	zero,1532(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004540:	00000097          	auipc	ra,0x0
    80004544:	c62080e7          	jalr	-926(ra) # 800041a2 <write_head>
    80004548:	bdfd                	j	80004446 <end_op+0x52>

000000008000454a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000454a:	1101                	addi	sp,sp,-32
    8000454c:	ec06                	sd	ra,24(sp)
    8000454e:	e822                	sd	s0,16(sp)
    80004550:	e426                	sd	s1,8(sp)
    80004552:	e04a                	sd	s2,0(sp)
    80004554:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004556:	0001d717          	auipc	a4,0x1d
    8000455a:	5de72703          	lw	a4,1502(a4) # 80021b34 <log+0x2c>
    8000455e:	47f5                	li	a5,29
    80004560:	08e7c063          	blt	a5,a4,800045e0 <log_write+0x96>
    80004564:	84aa                	mv	s1,a0
    80004566:	0001d797          	auipc	a5,0x1d
    8000456a:	5be7a783          	lw	a5,1470(a5) # 80021b24 <log+0x1c>
    8000456e:	37fd                	addiw	a5,a5,-1
    80004570:	06f75863          	bge	a4,a5,800045e0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004574:	0001d797          	auipc	a5,0x1d
    80004578:	5b47a783          	lw	a5,1460(a5) # 80021b28 <log+0x20>
    8000457c:	06f05a63          	blez	a5,800045f0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004580:	0001d917          	auipc	s2,0x1d
    80004584:	58890913          	addi	s2,s2,1416 # 80021b08 <log>
    80004588:	854a                	mv	a0,s2
    8000458a:	ffffc097          	auipc	ra,0xffffc
    8000458e:	686080e7          	jalr	1670(ra) # 80000c10 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004592:	02c92603          	lw	a2,44(s2)
    80004596:	06c05563          	blez	a2,80004600 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000459a:	44cc                	lw	a1,12(s1)
    8000459c:	0001d717          	auipc	a4,0x1d
    800045a0:	59c70713          	addi	a4,a4,1436 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    800045a6:	4314                	lw	a3,0(a4)
    800045a8:	04b68d63          	beq	a3,a1,80004602 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    800045ac:	2785                	addiw	a5,a5,1
    800045ae:	0711                	addi	a4,a4,4
    800045b0:	fec79be3          	bne	a5,a2,800045a6 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045b4:	0621                	addi	a2,a2,8
    800045b6:	060a                	slli	a2,a2,0x2
    800045b8:	0001d797          	auipc	a5,0x1d
    800045bc:	55078793          	addi	a5,a5,1360 # 80021b08 <log>
    800045c0:	963e                	add	a2,a2,a5
    800045c2:	44dc                	lw	a5,12(s1)
    800045c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045c6:	8526                	mv	a0,s1
    800045c8:	fffff097          	auipc	ra,0xfffff
    800045cc:	dbc080e7          	jalr	-580(ra) # 80003384 <bpin>
    log.lh.n++;
    800045d0:	0001d717          	auipc	a4,0x1d
    800045d4:	53870713          	addi	a4,a4,1336 # 80021b08 <log>
    800045d8:	575c                	lw	a5,44(a4)
    800045da:	2785                	addiw	a5,a5,1
    800045dc:	d75c                	sw	a5,44(a4)
    800045de:	a83d                	j	8000461c <log_write+0xd2>
    panic("too big a transaction");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	08050513          	addi	a0,a0,128 # 80008660 <syscalls+0x1f0>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f60080e7          	jalr	-160(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	08850513          	addi	a0,a0,136 # 80008678 <syscalls+0x208>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f50080e7          	jalr	-176(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004600:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004602:	00878713          	addi	a4,a5,8
    80004606:	00271693          	slli	a3,a4,0x2
    8000460a:	0001d717          	auipc	a4,0x1d
    8000460e:	4fe70713          	addi	a4,a4,1278 # 80021b08 <log>
    80004612:	9736                	add	a4,a4,a3
    80004614:	44d4                	lw	a3,12(s1)
    80004616:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004618:	faf607e3          	beq	a2,a5,800045c6 <log_write+0x7c>
  }
  release(&log.lock);
    8000461c:	0001d517          	auipc	a0,0x1d
    80004620:	4ec50513          	addi	a0,a0,1260 # 80021b08 <log>
    80004624:	ffffc097          	auipc	ra,0xffffc
    80004628:	6a0080e7          	jalr	1696(ra) # 80000cc4 <release>
}
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6902                	ld	s2,0(sp)
    80004634:	6105                	addi	sp,sp,32
    80004636:	8082                	ret

0000000080004638 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004638:	1101                	addi	sp,sp,-32
    8000463a:	ec06                	sd	ra,24(sp)
    8000463c:	e822                	sd	s0,16(sp)
    8000463e:	e426                	sd	s1,8(sp)
    80004640:	e04a                	sd	s2,0(sp)
    80004642:	1000                	addi	s0,sp,32
    80004644:	84aa                	mv	s1,a0
    80004646:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004648:	00004597          	auipc	a1,0x4
    8000464c:	05058593          	addi	a1,a1,80 # 80008698 <syscalls+0x228>
    80004650:	0521                	addi	a0,a0,8
    80004652:	ffffc097          	auipc	ra,0xffffc
    80004656:	52e080e7          	jalr	1326(ra) # 80000b80 <initlock>
  lk->name = name;
    8000465a:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000465e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004662:	0204a423          	sw	zero,40(s1)
}
    80004666:	60e2                	ld	ra,24(sp)
    80004668:	6442                	ld	s0,16(sp)
    8000466a:	64a2                	ld	s1,8(sp)
    8000466c:	6902                	ld	s2,0(sp)
    8000466e:	6105                	addi	sp,sp,32
    80004670:	8082                	ret

0000000080004672 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004672:	1101                	addi	sp,sp,-32
    80004674:	ec06                	sd	ra,24(sp)
    80004676:	e822                	sd	s0,16(sp)
    80004678:	e426                	sd	s1,8(sp)
    8000467a:	e04a                	sd	s2,0(sp)
    8000467c:	1000                	addi	s0,sp,32
    8000467e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004680:	00850913          	addi	s2,a0,8
    80004684:	854a                	mv	a0,s2
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	58a080e7          	jalr	1418(ra) # 80000c10 <acquire>
  while (lk->locked) {
    8000468e:	409c                	lw	a5,0(s1)
    80004690:	cb89                	beqz	a5,800046a2 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004692:	85ca                	mv	a1,s2
    80004694:	8526                	mv	a0,s1
    80004696:	ffffe097          	auipc	ra,0xffffe
    8000469a:	f02080e7          	jalr	-254(ra) # 80002598 <sleep>
  while (lk->locked) {
    8000469e:	409c                	lw	a5,0(s1)
    800046a0:	fbed                	bnez	a5,80004692 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046a2:	4785                	li	a5,1
    800046a4:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046a6:	ffffd097          	auipc	ra,0xffffd
    800046aa:	50e080e7          	jalr	1294(ra) # 80001bb4 <myproc>
    800046ae:	5d1c                	lw	a5,56(a0)
    800046b0:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046b2:	854a                	mv	a0,s2
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	610080e7          	jalr	1552(ra) # 80000cc4 <release>
}
    800046bc:	60e2                	ld	ra,24(sp)
    800046be:	6442                	ld	s0,16(sp)
    800046c0:	64a2                	ld	s1,8(sp)
    800046c2:	6902                	ld	s2,0(sp)
    800046c4:	6105                	addi	sp,sp,32
    800046c6:	8082                	ret

00000000800046c8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046c8:	1101                	addi	sp,sp,-32
    800046ca:	ec06                	sd	ra,24(sp)
    800046cc:	e822                	sd	s0,16(sp)
    800046ce:	e426                	sd	s1,8(sp)
    800046d0:	e04a                	sd	s2,0(sp)
    800046d2:	1000                	addi	s0,sp,32
    800046d4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046d6:	00850913          	addi	s2,a0,8
    800046da:	854a                	mv	a0,s2
    800046dc:	ffffc097          	auipc	ra,0xffffc
    800046e0:	534080e7          	jalr	1332(ra) # 80000c10 <acquire>
  lk->locked = 0;
    800046e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046e8:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ec:	8526                	mv	a0,s1
    800046ee:	ffffe097          	auipc	ra,0xffffe
    800046f2:	030080e7          	jalr	48(ra) # 8000271e <wakeup>
  release(&lk->lk);
    800046f6:	854a                	mv	a0,s2
    800046f8:	ffffc097          	auipc	ra,0xffffc
    800046fc:	5cc080e7          	jalr	1484(ra) # 80000cc4 <release>
}
    80004700:	60e2                	ld	ra,24(sp)
    80004702:	6442                	ld	s0,16(sp)
    80004704:	64a2                	ld	s1,8(sp)
    80004706:	6902                	ld	s2,0(sp)
    80004708:	6105                	addi	sp,sp,32
    8000470a:	8082                	ret

000000008000470c <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000470c:	7179                	addi	sp,sp,-48
    8000470e:	f406                	sd	ra,40(sp)
    80004710:	f022                	sd	s0,32(sp)
    80004712:	ec26                	sd	s1,24(sp)
    80004714:	e84a                	sd	s2,16(sp)
    80004716:	e44e                	sd	s3,8(sp)
    80004718:	1800                	addi	s0,sp,48
    8000471a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000471c:	00850913          	addi	s2,a0,8
    80004720:	854a                	mv	a0,s2
    80004722:	ffffc097          	auipc	ra,0xffffc
    80004726:	4ee080e7          	jalr	1262(ra) # 80000c10 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000472a:	409c                	lw	a5,0(s1)
    8000472c:	ef99                	bnez	a5,8000474a <holdingsleep+0x3e>
    8000472e:	4481                	li	s1,0
  release(&lk->lk);
    80004730:	854a                	mv	a0,s2
    80004732:	ffffc097          	auipc	ra,0xffffc
    80004736:	592080e7          	jalr	1426(ra) # 80000cc4 <release>
  return r;
}
    8000473a:	8526                	mv	a0,s1
    8000473c:	70a2                	ld	ra,40(sp)
    8000473e:	7402                	ld	s0,32(sp)
    80004740:	64e2                	ld	s1,24(sp)
    80004742:	6942                	ld	s2,16(sp)
    80004744:	69a2                	ld	s3,8(sp)
    80004746:	6145                	addi	sp,sp,48
    80004748:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000474a:	0284a983          	lw	s3,40(s1)
    8000474e:	ffffd097          	auipc	ra,0xffffd
    80004752:	466080e7          	jalr	1126(ra) # 80001bb4 <myproc>
    80004756:	5d04                	lw	s1,56(a0)
    80004758:	413484b3          	sub	s1,s1,s3
    8000475c:	0014b493          	seqz	s1,s1
    80004760:	bfc1                	j	80004730 <holdingsleep+0x24>

0000000080004762 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004762:	1141                	addi	sp,sp,-16
    80004764:	e406                	sd	ra,8(sp)
    80004766:	e022                	sd	s0,0(sp)
    80004768:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000476a:	00004597          	auipc	a1,0x4
    8000476e:	f3e58593          	addi	a1,a1,-194 # 800086a8 <syscalls+0x238>
    80004772:	0001d517          	auipc	a0,0x1d
    80004776:	4de50513          	addi	a0,a0,1246 # 80021c50 <ftable>
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	406080e7          	jalr	1030(ra) # 80000b80 <initlock>
}
    80004782:	60a2                	ld	ra,8(sp)
    80004784:	6402                	ld	s0,0(sp)
    80004786:	0141                	addi	sp,sp,16
    80004788:	8082                	ret

000000008000478a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000478a:	1101                	addi	sp,sp,-32
    8000478c:	ec06                	sd	ra,24(sp)
    8000478e:	e822                	sd	s0,16(sp)
    80004790:	e426                	sd	s1,8(sp)
    80004792:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004794:	0001d517          	auipc	a0,0x1d
    80004798:	4bc50513          	addi	a0,a0,1212 # 80021c50 <ftable>
    8000479c:	ffffc097          	auipc	ra,0xffffc
    800047a0:	474080e7          	jalr	1140(ra) # 80000c10 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047a4:	0001d497          	auipc	s1,0x1d
    800047a8:	4c448493          	addi	s1,s1,1220 # 80021c68 <ftable+0x18>
    800047ac:	0001e717          	auipc	a4,0x1e
    800047b0:	45c70713          	addi	a4,a4,1116 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    800047b4:	40dc                	lw	a5,4(s1)
    800047b6:	cf99                	beqz	a5,800047d4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047b8:	02848493          	addi	s1,s1,40
    800047bc:	fee49ce3          	bne	s1,a4,800047b4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047c0:	0001d517          	auipc	a0,0x1d
    800047c4:	49050513          	addi	a0,a0,1168 # 80021c50 <ftable>
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	4fc080e7          	jalr	1276(ra) # 80000cc4 <release>
  return 0;
    800047d0:	4481                	li	s1,0
    800047d2:	a819                	j	800047e8 <filealloc+0x5e>
      f->ref = 1;
    800047d4:	4785                	li	a5,1
    800047d6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047d8:	0001d517          	auipc	a0,0x1d
    800047dc:	47850513          	addi	a0,a0,1144 # 80021c50 <ftable>
    800047e0:	ffffc097          	auipc	ra,0xffffc
    800047e4:	4e4080e7          	jalr	1252(ra) # 80000cc4 <release>
}
    800047e8:	8526                	mv	a0,s1
    800047ea:	60e2                	ld	ra,24(sp)
    800047ec:	6442                	ld	s0,16(sp)
    800047ee:	64a2                	ld	s1,8(sp)
    800047f0:	6105                	addi	sp,sp,32
    800047f2:	8082                	ret

00000000800047f4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047f4:	1101                	addi	sp,sp,-32
    800047f6:	ec06                	sd	ra,24(sp)
    800047f8:	e822                	sd	s0,16(sp)
    800047fa:	e426                	sd	s1,8(sp)
    800047fc:	1000                	addi	s0,sp,32
    800047fe:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004800:	0001d517          	auipc	a0,0x1d
    80004804:	45050513          	addi	a0,a0,1104 # 80021c50 <ftable>
    80004808:	ffffc097          	auipc	ra,0xffffc
    8000480c:	408080e7          	jalr	1032(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    80004810:	40dc                	lw	a5,4(s1)
    80004812:	02f05263          	blez	a5,80004836 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004816:	2785                	addiw	a5,a5,1
    80004818:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000481a:	0001d517          	auipc	a0,0x1d
    8000481e:	43650513          	addi	a0,a0,1078 # 80021c50 <ftable>
    80004822:	ffffc097          	auipc	ra,0xffffc
    80004826:	4a2080e7          	jalr	1186(ra) # 80000cc4 <release>
  return f;
}
    8000482a:	8526                	mv	a0,s1
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6105                	addi	sp,sp,32
    80004834:	8082                	ret
    panic("filedup");
    80004836:	00004517          	auipc	a0,0x4
    8000483a:	e7a50513          	addi	a0,a0,-390 # 800086b0 <syscalls+0x240>
    8000483e:	ffffc097          	auipc	ra,0xffffc
    80004842:	d0a080e7          	jalr	-758(ra) # 80000548 <panic>

0000000080004846 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004846:	7139                	addi	sp,sp,-64
    80004848:	fc06                	sd	ra,56(sp)
    8000484a:	f822                	sd	s0,48(sp)
    8000484c:	f426                	sd	s1,40(sp)
    8000484e:	f04a                	sd	s2,32(sp)
    80004850:	ec4e                	sd	s3,24(sp)
    80004852:	e852                	sd	s4,16(sp)
    80004854:	e456                	sd	s5,8(sp)
    80004856:	0080                	addi	s0,sp,64
    80004858:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000485a:	0001d517          	auipc	a0,0x1d
    8000485e:	3f650513          	addi	a0,a0,1014 # 80021c50 <ftable>
    80004862:	ffffc097          	auipc	ra,0xffffc
    80004866:	3ae080e7          	jalr	942(ra) # 80000c10 <acquire>
  if(f->ref < 1)
    8000486a:	40dc                	lw	a5,4(s1)
    8000486c:	06f05163          	blez	a5,800048ce <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004870:	37fd                	addiw	a5,a5,-1
    80004872:	0007871b          	sext.w	a4,a5
    80004876:	c0dc                	sw	a5,4(s1)
    80004878:	06e04363          	bgtz	a4,800048de <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000487c:	0004a903          	lw	s2,0(s1)
    80004880:	0094ca83          	lbu	s5,9(s1)
    80004884:	0104ba03          	ld	s4,16(s1)
    80004888:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000488c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004890:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004894:	0001d517          	auipc	a0,0x1d
    80004898:	3bc50513          	addi	a0,a0,956 # 80021c50 <ftable>
    8000489c:	ffffc097          	auipc	ra,0xffffc
    800048a0:	428080e7          	jalr	1064(ra) # 80000cc4 <release>

  if(ff.type == FD_PIPE){
    800048a4:	4785                	li	a5,1
    800048a6:	04f90d63          	beq	s2,a5,80004900 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048aa:	3979                	addiw	s2,s2,-2
    800048ac:	4785                	li	a5,1
    800048ae:	0527e063          	bltu	a5,s2,800048ee <fileclose+0xa8>
    begin_op();
    800048b2:	00000097          	auipc	ra,0x0
    800048b6:	ac2080e7          	jalr	-1342(ra) # 80004374 <begin_op>
    iput(ff.ip);
    800048ba:	854e                	mv	a0,s3
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	2b6080e7          	jalr	694(ra) # 80003b72 <iput>
    end_op();
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	b30080e7          	jalr	-1232(ra) # 800043f4 <end_op>
    800048cc:	a00d                	j	800048ee <fileclose+0xa8>
    panic("fileclose");
    800048ce:	00004517          	auipc	a0,0x4
    800048d2:	dea50513          	addi	a0,a0,-534 # 800086b8 <syscalls+0x248>
    800048d6:	ffffc097          	auipc	ra,0xffffc
    800048da:	c72080e7          	jalr	-910(ra) # 80000548 <panic>
    release(&ftable.lock);
    800048de:	0001d517          	auipc	a0,0x1d
    800048e2:	37250513          	addi	a0,a0,882 # 80021c50 <ftable>
    800048e6:	ffffc097          	auipc	ra,0xffffc
    800048ea:	3de080e7          	jalr	990(ra) # 80000cc4 <release>
  }
}
    800048ee:	70e2                	ld	ra,56(sp)
    800048f0:	7442                	ld	s0,48(sp)
    800048f2:	74a2                	ld	s1,40(sp)
    800048f4:	7902                	ld	s2,32(sp)
    800048f6:	69e2                	ld	s3,24(sp)
    800048f8:	6a42                	ld	s4,16(sp)
    800048fa:	6aa2                	ld	s5,8(sp)
    800048fc:	6121                	addi	sp,sp,64
    800048fe:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004900:	85d6                	mv	a1,s5
    80004902:	8552                	mv	a0,s4
    80004904:	00000097          	auipc	ra,0x0
    80004908:	372080e7          	jalr	882(ra) # 80004c76 <pipeclose>
    8000490c:	b7cd                	j	800048ee <fileclose+0xa8>

000000008000490e <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000490e:	715d                	addi	sp,sp,-80
    80004910:	e486                	sd	ra,72(sp)
    80004912:	e0a2                	sd	s0,64(sp)
    80004914:	fc26                	sd	s1,56(sp)
    80004916:	f84a                	sd	s2,48(sp)
    80004918:	f44e                	sd	s3,40(sp)
    8000491a:	0880                	addi	s0,sp,80
    8000491c:	84aa                	mv	s1,a0
    8000491e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004920:	ffffd097          	auipc	ra,0xffffd
    80004924:	294080e7          	jalr	660(ra) # 80001bb4 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004928:	409c                	lw	a5,0(s1)
    8000492a:	37f9                	addiw	a5,a5,-2
    8000492c:	4705                	li	a4,1
    8000492e:	04f76763          	bltu	a4,a5,8000497c <filestat+0x6e>
    80004932:	892a                	mv	s2,a0
    ilock(f->ip);
    80004934:	6c88                	ld	a0,24(s1)
    80004936:	fffff097          	auipc	ra,0xfffff
    8000493a:	082080e7          	jalr	130(ra) # 800039b8 <ilock>
    stati(f->ip, &st);
    8000493e:	fb840593          	addi	a1,s0,-72
    80004942:	6c88                	ld	a0,24(s1)
    80004944:	fffff097          	auipc	ra,0xfffff
    80004948:	2fe080e7          	jalr	766(ra) # 80003c42 <stati>
    iunlock(f->ip);
    8000494c:	6c88                	ld	a0,24(s1)
    8000494e:	fffff097          	auipc	ra,0xfffff
    80004952:	12c080e7          	jalr	300(ra) # 80003a7a <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004956:	46e1                	li	a3,24
    80004958:	fb840613          	addi	a2,s0,-72
    8000495c:	85ce                	mv	a1,s3
    8000495e:	05093503          	ld	a0,80(s2)
    80004962:	ffffd097          	auipc	ra,0xffffd
    80004966:	fca080e7          	jalr	-54(ra) # 8000192c <copyout>
    8000496a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000496e:	60a6                	ld	ra,72(sp)
    80004970:	6406                	ld	s0,64(sp)
    80004972:	74e2                	ld	s1,56(sp)
    80004974:	7942                	ld	s2,48(sp)
    80004976:	79a2                	ld	s3,40(sp)
    80004978:	6161                	addi	sp,sp,80
    8000497a:	8082                	ret
  return -1;
    8000497c:	557d                	li	a0,-1
    8000497e:	bfc5                	j	8000496e <filestat+0x60>

0000000080004980 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004980:	7179                	addi	sp,sp,-48
    80004982:	f406                	sd	ra,40(sp)
    80004984:	f022                	sd	s0,32(sp)
    80004986:	ec26                	sd	s1,24(sp)
    80004988:	e84a                	sd	s2,16(sp)
    8000498a:	e44e                	sd	s3,8(sp)
    8000498c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000498e:	00854783          	lbu	a5,8(a0)
    80004992:	c3d5                	beqz	a5,80004a36 <fileread+0xb6>
    80004994:	84aa                	mv	s1,a0
    80004996:	89ae                	mv	s3,a1
    80004998:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000499a:	411c                	lw	a5,0(a0)
    8000499c:	4705                	li	a4,1
    8000499e:	04e78963          	beq	a5,a4,800049f0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a2:	470d                	li	a4,3
    800049a4:	04e78d63          	beq	a5,a4,800049fe <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a8:	4709                	li	a4,2
    800049aa:	06e79e63          	bne	a5,a4,80004a26 <fileread+0xa6>
    ilock(f->ip);
    800049ae:	6d08                	ld	a0,24(a0)
    800049b0:	fffff097          	auipc	ra,0xfffff
    800049b4:	008080e7          	jalr	8(ra) # 800039b8 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049b8:	874a                	mv	a4,s2
    800049ba:	5094                	lw	a3,32(s1)
    800049bc:	864e                	mv	a2,s3
    800049be:	4585                	li	a1,1
    800049c0:	6c88                	ld	a0,24(s1)
    800049c2:	fffff097          	auipc	ra,0xfffff
    800049c6:	2aa080e7          	jalr	682(ra) # 80003c6c <readi>
    800049ca:	892a                	mv	s2,a0
    800049cc:	00a05563          	blez	a0,800049d6 <fileread+0x56>
      f->off += r;
    800049d0:	509c                	lw	a5,32(s1)
    800049d2:	9fa9                	addw	a5,a5,a0
    800049d4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049d6:	6c88                	ld	a0,24(s1)
    800049d8:	fffff097          	auipc	ra,0xfffff
    800049dc:	0a2080e7          	jalr	162(ra) # 80003a7a <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049e0:	854a                	mv	a0,s2
    800049e2:	70a2                	ld	ra,40(sp)
    800049e4:	7402                	ld	s0,32(sp)
    800049e6:	64e2                	ld	s1,24(sp)
    800049e8:	6942                	ld	s2,16(sp)
    800049ea:	69a2                	ld	s3,8(sp)
    800049ec:	6145                	addi	sp,sp,48
    800049ee:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049f0:	6908                	ld	a0,16(a0)
    800049f2:	00000097          	auipc	ra,0x0
    800049f6:	418080e7          	jalr	1048(ra) # 80004e0a <piperead>
    800049fa:	892a                	mv	s2,a0
    800049fc:	b7d5                	j	800049e0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049fe:	02451783          	lh	a5,36(a0)
    80004a02:	03079693          	slli	a3,a5,0x30
    80004a06:	92c1                	srli	a3,a3,0x30
    80004a08:	4725                	li	a4,9
    80004a0a:	02d76863          	bltu	a4,a3,80004a3a <fileread+0xba>
    80004a0e:	0792                	slli	a5,a5,0x4
    80004a10:	0001d717          	auipc	a4,0x1d
    80004a14:	1a070713          	addi	a4,a4,416 # 80021bb0 <devsw>
    80004a18:	97ba                	add	a5,a5,a4
    80004a1a:	639c                	ld	a5,0(a5)
    80004a1c:	c38d                	beqz	a5,80004a3e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a1e:	4505                	li	a0,1
    80004a20:	9782                	jalr	a5
    80004a22:	892a                	mv	s2,a0
    80004a24:	bf75                	j	800049e0 <fileread+0x60>
    panic("fileread");
    80004a26:	00004517          	auipc	a0,0x4
    80004a2a:	ca250513          	addi	a0,a0,-862 # 800086c8 <syscalls+0x258>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	b1a080e7          	jalr	-1254(ra) # 80000548 <panic>
    return -1;
    80004a36:	597d                	li	s2,-1
    80004a38:	b765                	j	800049e0 <fileread+0x60>
      return -1;
    80004a3a:	597d                	li	s2,-1
    80004a3c:	b755                	j	800049e0 <fileread+0x60>
    80004a3e:	597d                	li	s2,-1
    80004a40:	b745                	j	800049e0 <fileread+0x60>

0000000080004a42 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004a42:	00954783          	lbu	a5,9(a0)
    80004a46:	14078563          	beqz	a5,80004b90 <filewrite+0x14e>
{
    80004a4a:	715d                	addi	sp,sp,-80
    80004a4c:	e486                	sd	ra,72(sp)
    80004a4e:	e0a2                	sd	s0,64(sp)
    80004a50:	fc26                	sd	s1,56(sp)
    80004a52:	f84a                	sd	s2,48(sp)
    80004a54:	f44e                	sd	s3,40(sp)
    80004a56:	f052                	sd	s4,32(sp)
    80004a58:	ec56                	sd	s5,24(sp)
    80004a5a:	e85a                	sd	s6,16(sp)
    80004a5c:	e45e                	sd	s7,8(sp)
    80004a5e:	e062                	sd	s8,0(sp)
    80004a60:	0880                	addi	s0,sp,80
    80004a62:	892a                	mv	s2,a0
    80004a64:	8aae                	mv	s5,a1
    80004a66:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a68:	411c                	lw	a5,0(a0)
    80004a6a:	4705                	li	a4,1
    80004a6c:	02e78263          	beq	a5,a4,80004a90 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a70:	470d                	li	a4,3
    80004a72:	02e78563          	beq	a5,a4,80004a9c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a76:	4709                	li	a4,2
    80004a78:	10e79463          	bne	a5,a4,80004b80 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a7c:	0ec05e63          	blez	a2,80004b78 <filewrite+0x136>
    int i = 0;
    80004a80:	4981                	li	s3,0
    80004a82:	6b05                	lui	s6,0x1
    80004a84:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a88:	6b85                	lui	s7,0x1
    80004a8a:	c00b8b9b          	addiw	s7,s7,-1024
    80004a8e:	a851                	j	80004b22 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004a90:	6908                	ld	a0,16(a0)
    80004a92:	00000097          	auipc	ra,0x0
    80004a96:	254080e7          	jalr	596(ra) # 80004ce6 <pipewrite>
    80004a9a:	a85d                	j	80004b50 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a9c:	02451783          	lh	a5,36(a0)
    80004aa0:	03079693          	slli	a3,a5,0x30
    80004aa4:	92c1                	srli	a3,a3,0x30
    80004aa6:	4725                	li	a4,9
    80004aa8:	0ed76663          	bltu	a4,a3,80004b94 <filewrite+0x152>
    80004aac:	0792                	slli	a5,a5,0x4
    80004aae:	0001d717          	auipc	a4,0x1d
    80004ab2:	10270713          	addi	a4,a4,258 # 80021bb0 <devsw>
    80004ab6:	97ba                	add	a5,a5,a4
    80004ab8:	679c                	ld	a5,8(a5)
    80004aba:	cff9                	beqz	a5,80004b98 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004abc:	4505                	li	a0,1
    80004abe:	9782                	jalr	a5
    80004ac0:	a841                	j	80004b50 <filewrite+0x10e>
    80004ac2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	8ae080e7          	jalr	-1874(ra) # 80004374 <begin_op>
      ilock(f->ip);
    80004ace:	01893503          	ld	a0,24(s2)
    80004ad2:	fffff097          	auipc	ra,0xfffff
    80004ad6:	ee6080e7          	jalr	-282(ra) # 800039b8 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004ada:	8762                	mv	a4,s8
    80004adc:	02092683          	lw	a3,32(s2)
    80004ae0:	01598633          	add	a2,s3,s5
    80004ae4:	4585                	li	a1,1
    80004ae6:	01893503          	ld	a0,24(s2)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	278080e7          	jalr	632(ra) # 80003d62 <writei>
    80004af2:	84aa                	mv	s1,a0
    80004af4:	02a05f63          	blez	a0,80004b32 <filewrite+0xf0>
        f->off += r;
    80004af8:	02092783          	lw	a5,32(s2)
    80004afc:	9fa9                	addw	a5,a5,a0
    80004afe:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b02:	01893503          	ld	a0,24(s2)
    80004b06:	fffff097          	auipc	ra,0xfffff
    80004b0a:	f74080e7          	jalr	-140(ra) # 80003a7a <iunlock>
      end_op();
    80004b0e:	00000097          	auipc	ra,0x0
    80004b12:	8e6080e7          	jalr	-1818(ra) # 800043f4 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004b16:	049c1963          	bne	s8,s1,80004b68 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004b1a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b1e:	0349d663          	bge	s3,s4,80004b4a <filewrite+0x108>
      int n1 = n - i;
    80004b22:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b26:	84be                	mv	s1,a5
    80004b28:	2781                	sext.w	a5,a5
    80004b2a:	f8fb5ce3          	bge	s6,a5,80004ac2 <filewrite+0x80>
    80004b2e:	84de                	mv	s1,s7
    80004b30:	bf49                	j	80004ac2 <filewrite+0x80>
      iunlock(f->ip);
    80004b32:	01893503          	ld	a0,24(s2)
    80004b36:	fffff097          	auipc	ra,0xfffff
    80004b3a:	f44080e7          	jalr	-188(ra) # 80003a7a <iunlock>
      end_op();
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	8b6080e7          	jalr	-1866(ra) # 800043f4 <end_op>
      if(r < 0)
    80004b46:	fc04d8e3          	bgez	s1,80004b16 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004b4a:	8552                	mv	a0,s4
    80004b4c:	033a1863          	bne	s4,s3,80004b7c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b50:	60a6                	ld	ra,72(sp)
    80004b52:	6406                	ld	s0,64(sp)
    80004b54:	74e2                	ld	s1,56(sp)
    80004b56:	7942                	ld	s2,48(sp)
    80004b58:	79a2                	ld	s3,40(sp)
    80004b5a:	7a02                	ld	s4,32(sp)
    80004b5c:	6ae2                	ld	s5,24(sp)
    80004b5e:	6b42                	ld	s6,16(sp)
    80004b60:	6ba2                	ld	s7,8(sp)
    80004b62:	6c02                	ld	s8,0(sp)
    80004b64:	6161                	addi	sp,sp,80
    80004b66:	8082                	ret
        panic("short filewrite");
    80004b68:	00004517          	auipc	a0,0x4
    80004b6c:	b7050513          	addi	a0,a0,-1168 # 800086d8 <syscalls+0x268>
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	9d8080e7          	jalr	-1576(ra) # 80000548 <panic>
    int i = 0;
    80004b78:	4981                	li	s3,0
    80004b7a:	bfc1                	j	80004b4a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004b7c:	557d                	li	a0,-1
    80004b7e:	bfc9                	j	80004b50 <filewrite+0x10e>
    panic("filewrite");
    80004b80:	00004517          	auipc	a0,0x4
    80004b84:	b6850513          	addi	a0,a0,-1176 # 800086e8 <syscalls+0x278>
    80004b88:	ffffc097          	auipc	ra,0xffffc
    80004b8c:	9c0080e7          	jalr	-1600(ra) # 80000548 <panic>
    return -1;
    80004b90:	557d                	li	a0,-1
}
    80004b92:	8082                	ret
      return -1;
    80004b94:	557d                	li	a0,-1
    80004b96:	bf6d                	j	80004b50 <filewrite+0x10e>
    80004b98:	557d                	li	a0,-1
    80004b9a:	bf5d                	j	80004b50 <filewrite+0x10e>

0000000080004b9c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004b9c:	7179                	addi	sp,sp,-48
    80004b9e:	f406                	sd	ra,40(sp)
    80004ba0:	f022                	sd	s0,32(sp)
    80004ba2:	ec26                	sd	s1,24(sp)
    80004ba4:	e84a                	sd	s2,16(sp)
    80004ba6:	e44e                	sd	s3,8(sp)
    80004ba8:	e052                	sd	s4,0(sp)
    80004baa:	1800                	addi	s0,sp,48
    80004bac:	84aa                	mv	s1,a0
    80004bae:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004bb0:	0005b023          	sd	zero,0(a1)
    80004bb4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004bb8:	00000097          	auipc	ra,0x0
    80004bbc:	bd2080e7          	jalr	-1070(ra) # 8000478a <filealloc>
    80004bc0:	e088                	sd	a0,0(s1)
    80004bc2:	c551                	beqz	a0,80004c4e <pipealloc+0xb2>
    80004bc4:	00000097          	auipc	ra,0x0
    80004bc8:	bc6080e7          	jalr	-1082(ra) # 8000478a <filealloc>
    80004bcc:	00aa3023          	sd	a0,0(s4)
    80004bd0:	c92d                	beqz	a0,80004c42 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004bd2:	ffffc097          	auipc	ra,0xffffc
    80004bd6:	f4e080e7          	jalr	-178(ra) # 80000b20 <kalloc>
    80004bda:	892a                	mv	s2,a0
    80004bdc:	c125                	beqz	a0,80004c3c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004bde:	4985                	li	s3,1
    80004be0:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004be4:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004be8:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004bec:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004bf0:	00004597          	auipc	a1,0x4
    80004bf4:	b0858593          	addi	a1,a1,-1272 # 800086f8 <syscalls+0x288>
    80004bf8:	ffffc097          	auipc	ra,0xffffc
    80004bfc:	f88080e7          	jalr	-120(ra) # 80000b80 <initlock>
  (*f0)->type = FD_PIPE;
    80004c00:	609c                	ld	a5,0(s1)
    80004c02:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004c06:	609c                	ld	a5,0(s1)
    80004c08:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004c0c:	609c                	ld	a5,0(s1)
    80004c0e:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004c12:	609c                	ld	a5,0(s1)
    80004c14:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004c18:	000a3783          	ld	a5,0(s4)
    80004c1c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004c20:	000a3783          	ld	a5,0(s4)
    80004c24:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004c28:	000a3783          	ld	a5,0(s4)
    80004c2c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004c30:	000a3783          	ld	a5,0(s4)
    80004c34:	0127b823          	sd	s2,16(a5)
  return 0;
    80004c38:	4501                	li	a0,0
    80004c3a:	a025                	j	80004c62 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004c3c:	6088                	ld	a0,0(s1)
    80004c3e:	e501                	bnez	a0,80004c46 <pipealloc+0xaa>
    80004c40:	a039                	j	80004c4e <pipealloc+0xb2>
    80004c42:	6088                	ld	a0,0(s1)
    80004c44:	c51d                	beqz	a0,80004c72 <pipealloc+0xd6>
    fileclose(*f0);
    80004c46:	00000097          	auipc	ra,0x0
    80004c4a:	c00080e7          	jalr	-1024(ra) # 80004846 <fileclose>
  if(*f1)
    80004c4e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004c52:	557d                	li	a0,-1
  if(*f1)
    80004c54:	c799                	beqz	a5,80004c62 <pipealloc+0xc6>
    fileclose(*f1);
    80004c56:	853e                	mv	a0,a5
    80004c58:	00000097          	auipc	ra,0x0
    80004c5c:	bee080e7          	jalr	-1042(ra) # 80004846 <fileclose>
  return -1;
    80004c60:	557d                	li	a0,-1
}
    80004c62:	70a2                	ld	ra,40(sp)
    80004c64:	7402                	ld	s0,32(sp)
    80004c66:	64e2                	ld	s1,24(sp)
    80004c68:	6942                	ld	s2,16(sp)
    80004c6a:	69a2                	ld	s3,8(sp)
    80004c6c:	6a02                	ld	s4,0(sp)
    80004c6e:	6145                	addi	sp,sp,48
    80004c70:	8082                	ret
  return -1;
    80004c72:	557d                	li	a0,-1
    80004c74:	b7fd                	j	80004c62 <pipealloc+0xc6>

0000000080004c76 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004c76:	1101                	addi	sp,sp,-32
    80004c78:	ec06                	sd	ra,24(sp)
    80004c7a:	e822                	sd	s0,16(sp)
    80004c7c:	e426                	sd	s1,8(sp)
    80004c7e:	e04a                	sd	s2,0(sp)
    80004c80:	1000                	addi	s0,sp,32
    80004c82:	84aa                	mv	s1,a0
    80004c84:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004c86:	ffffc097          	auipc	ra,0xffffc
    80004c8a:	f8a080e7          	jalr	-118(ra) # 80000c10 <acquire>
  if(writable){
    80004c8e:	02090d63          	beqz	s2,80004cc8 <pipeclose+0x52>
    pi->writeopen = 0;
    80004c92:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004c96:	21848513          	addi	a0,s1,536
    80004c9a:	ffffe097          	auipc	ra,0xffffe
    80004c9e:	a84080e7          	jalr	-1404(ra) # 8000271e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004ca2:	2204b783          	ld	a5,544(s1)
    80004ca6:	eb95                	bnez	a5,80004cda <pipeclose+0x64>
    release(&pi->lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	01a080e7          	jalr	26(ra) # 80000cc4 <release>
    kfree((char*)pi);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	d70080e7          	jalr	-656(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004cbc:	60e2                	ld	ra,24(sp)
    80004cbe:	6442                	ld	s0,16(sp)
    80004cc0:	64a2                	ld	s1,8(sp)
    80004cc2:	6902                	ld	s2,0(sp)
    80004cc4:	6105                	addi	sp,sp,32
    80004cc6:	8082                	ret
    pi->readopen = 0;
    80004cc8:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004ccc:	21c48513          	addi	a0,s1,540
    80004cd0:	ffffe097          	auipc	ra,0xffffe
    80004cd4:	a4e080e7          	jalr	-1458(ra) # 8000271e <wakeup>
    80004cd8:	b7e9                	j	80004ca2 <pipeclose+0x2c>
    release(&pi->lock);
    80004cda:	8526                	mv	a0,s1
    80004cdc:	ffffc097          	auipc	ra,0xffffc
    80004ce0:	fe8080e7          	jalr	-24(ra) # 80000cc4 <release>
}
    80004ce4:	bfe1                	j	80004cbc <pipeclose+0x46>

0000000080004ce6 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ce6:	7119                	addi	sp,sp,-128
    80004ce8:	fc86                	sd	ra,120(sp)
    80004cea:	f8a2                	sd	s0,112(sp)
    80004cec:	f4a6                	sd	s1,104(sp)
    80004cee:	f0ca                	sd	s2,96(sp)
    80004cf0:	ecce                	sd	s3,88(sp)
    80004cf2:	e8d2                	sd	s4,80(sp)
    80004cf4:	e4d6                	sd	s5,72(sp)
    80004cf6:	e0da                	sd	s6,64(sp)
    80004cf8:	fc5e                	sd	s7,56(sp)
    80004cfa:	f862                	sd	s8,48(sp)
    80004cfc:	f466                	sd	s9,40(sp)
    80004cfe:	f06a                	sd	s10,32(sp)
    80004d00:	ec6e                	sd	s11,24(sp)
    80004d02:	0100                	addi	s0,sp,128
    80004d04:	84aa                	mv	s1,a0
    80004d06:	8cae                	mv	s9,a1
    80004d08:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004d0a:	ffffd097          	auipc	ra,0xffffd
    80004d0e:	eaa080e7          	jalr	-342(ra) # 80001bb4 <myproc>
    80004d12:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004d14:	8526                	mv	a0,s1
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	efa080e7          	jalr	-262(ra) # 80000c10 <acquire>
  for(i = 0; i < n; i++){
    80004d1e:	0d605963          	blez	s6,80004df0 <pipewrite+0x10a>
    80004d22:	89a6                	mv	s3,s1
    80004d24:	3b7d                	addiw	s6,s6,-1
    80004d26:	1b02                	slli	s6,s6,0x20
    80004d28:	020b5b13          	srli	s6,s6,0x20
    80004d2c:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004d2e:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004d32:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d36:	5dfd                	li	s11,-1
    80004d38:	000b8d1b          	sext.w	s10,s7
    80004d3c:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d3e:	2184a783          	lw	a5,536(s1)
    80004d42:	21c4a703          	lw	a4,540(s1)
    80004d46:	2007879b          	addiw	a5,a5,512
    80004d4a:	02f71b63          	bne	a4,a5,80004d80 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004d4e:	2204a783          	lw	a5,544(s1)
    80004d52:	cbad                	beqz	a5,80004dc4 <pipewrite+0xde>
    80004d54:	03092783          	lw	a5,48(s2)
    80004d58:	e7b5                	bnez	a5,80004dc4 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004d5a:	8556                	mv	a0,s5
    80004d5c:	ffffe097          	auipc	ra,0xffffe
    80004d60:	9c2080e7          	jalr	-1598(ra) # 8000271e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004d64:	85ce                	mv	a1,s3
    80004d66:	8552                	mv	a0,s4
    80004d68:	ffffe097          	auipc	ra,0xffffe
    80004d6c:	830080e7          	jalr	-2000(ra) # 80002598 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004d70:	2184a783          	lw	a5,536(s1)
    80004d74:	21c4a703          	lw	a4,540(s1)
    80004d78:	2007879b          	addiw	a5,a5,512
    80004d7c:	fcf709e3          	beq	a4,a5,80004d4e <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004d80:	4685                	li	a3,1
    80004d82:	019b8633          	add	a2,s7,s9
    80004d86:	f8f40593          	addi	a1,s0,-113
    80004d8a:	05093503          	ld	a0,80(s2)
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	c2a080e7          	jalr	-982(ra) # 800019b8 <copyin>
    80004d96:	05b50e63          	beq	a0,s11,80004df2 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004d9a:	21c4a783          	lw	a5,540(s1)
    80004d9e:	0017871b          	addiw	a4,a5,1
    80004da2:	20e4ae23          	sw	a4,540(s1)
    80004da6:	1ff7f793          	andi	a5,a5,511
    80004daa:	97a6                	add	a5,a5,s1
    80004dac:	f8f44703          	lbu	a4,-113(s0)
    80004db0:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004db4:	001d0c1b          	addiw	s8,s10,1
    80004db8:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004dbc:	036b8b63          	beq	s7,s6,80004df2 <pipewrite+0x10c>
    80004dc0:	8bbe                	mv	s7,a5
    80004dc2:	bf9d                	j	80004d38 <pipewrite+0x52>
        release(&pi->lock);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	efe080e7          	jalr	-258(ra) # 80000cc4 <release>
        return -1;
    80004dce:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004dd0:	8562                	mv	a0,s8
    80004dd2:	70e6                	ld	ra,120(sp)
    80004dd4:	7446                	ld	s0,112(sp)
    80004dd6:	74a6                	ld	s1,104(sp)
    80004dd8:	7906                	ld	s2,96(sp)
    80004dda:	69e6                	ld	s3,88(sp)
    80004ddc:	6a46                	ld	s4,80(sp)
    80004dde:	6aa6                	ld	s5,72(sp)
    80004de0:	6b06                	ld	s6,64(sp)
    80004de2:	7be2                	ld	s7,56(sp)
    80004de4:	7c42                	ld	s8,48(sp)
    80004de6:	7ca2                	ld	s9,40(sp)
    80004de8:	7d02                	ld	s10,32(sp)
    80004dea:	6de2                	ld	s11,24(sp)
    80004dec:	6109                	addi	sp,sp,128
    80004dee:	8082                	ret
  for(i = 0; i < n; i++){
    80004df0:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004df2:	21848513          	addi	a0,s1,536
    80004df6:	ffffe097          	auipc	ra,0xffffe
    80004dfa:	928080e7          	jalr	-1752(ra) # 8000271e <wakeup>
  release(&pi->lock);
    80004dfe:	8526                	mv	a0,s1
    80004e00:	ffffc097          	auipc	ra,0xffffc
    80004e04:	ec4080e7          	jalr	-316(ra) # 80000cc4 <release>
  return i;
    80004e08:	b7e1                	j	80004dd0 <pipewrite+0xea>

0000000080004e0a <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004e0a:	715d                	addi	sp,sp,-80
    80004e0c:	e486                	sd	ra,72(sp)
    80004e0e:	e0a2                	sd	s0,64(sp)
    80004e10:	fc26                	sd	s1,56(sp)
    80004e12:	f84a                	sd	s2,48(sp)
    80004e14:	f44e                	sd	s3,40(sp)
    80004e16:	f052                	sd	s4,32(sp)
    80004e18:	ec56                	sd	s5,24(sp)
    80004e1a:	e85a                	sd	s6,16(sp)
    80004e1c:	0880                	addi	s0,sp,80
    80004e1e:	84aa                	mv	s1,a0
    80004e20:	892e                	mv	s2,a1
    80004e22:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004e24:	ffffd097          	auipc	ra,0xffffd
    80004e28:	d90080e7          	jalr	-624(ra) # 80001bb4 <myproc>
    80004e2c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004e2e:	8b26                	mv	s6,s1
    80004e30:	8526                	mv	a0,s1
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	dde080e7          	jalr	-546(ra) # 80000c10 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e3a:	2184a703          	lw	a4,536(s1)
    80004e3e:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e42:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e46:	02f71463          	bne	a4,a5,80004e6e <piperead+0x64>
    80004e4a:	2244a783          	lw	a5,548(s1)
    80004e4e:	c385                	beqz	a5,80004e6e <piperead+0x64>
    if(pr->killed){
    80004e50:	030a2783          	lw	a5,48(s4)
    80004e54:	ebc1                	bnez	a5,80004ee4 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004e56:	85da                	mv	a1,s6
    80004e58:	854e                	mv	a0,s3
    80004e5a:	ffffd097          	auipc	ra,0xffffd
    80004e5e:	73e080e7          	jalr	1854(ra) # 80002598 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004e62:	2184a703          	lw	a4,536(s1)
    80004e66:	21c4a783          	lw	a5,540(s1)
    80004e6a:	fef700e3          	beq	a4,a5,80004e4a <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004e6e:	09505263          	blez	s5,80004ef2 <piperead+0xe8>
    80004e72:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e74:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004e76:	2184a783          	lw	a5,536(s1)
    80004e7a:	21c4a703          	lw	a4,540(s1)
    80004e7e:	02f70d63          	beq	a4,a5,80004eb8 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004e82:	0017871b          	addiw	a4,a5,1
    80004e86:	20e4ac23          	sw	a4,536(s1)
    80004e8a:	1ff7f793          	andi	a5,a5,511
    80004e8e:	97a6                	add	a5,a5,s1
    80004e90:	0187c783          	lbu	a5,24(a5)
    80004e94:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004e98:	4685                	li	a3,1
    80004e9a:	fbf40613          	addi	a2,s0,-65
    80004e9e:	85ca                	mv	a1,s2
    80004ea0:	050a3503          	ld	a0,80(s4)
    80004ea4:	ffffd097          	auipc	ra,0xffffd
    80004ea8:	a88080e7          	jalr	-1400(ra) # 8000192c <copyout>
    80004eac:	01650663          	beq	a0,s6,80004eb8 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004eb0:	2985                	addiw	s3,s3,1
    80004eb2:	0905                	addi	s2,s2,1
    80004eb4:	fd3a91e3          	bne	s5,s3,80004e76 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004eb8:	21c48513          	addi	a0,s1,540
    80004ebc:	ffffe097          	auipc	ra,0xffffe
    80004ec0:	862080e7          	jalr	-1950(ra) # 8000271e <wakeup>
  release(&pi->lock);
    80004ec4:	8526                	mv	a0,s1
    80004ec6:	ffffc097          	auipc	ra,0xffffc
    80004eca:	dfe080e7          	jalr	-514(ra) # 80000cc4 <release>
  return i;
}
    80004ece:	854e                	mv	a0,s3
    80004ed0:	60a6                	ld	ra,72(sp)
    80004ed2:	6406                	ld	s0,64(sp)
    80004ed4:	74e2                	ld	s1,56(sp)
    80004ed6:	7942                	ld	s2,48(sp)
    80004ed8:	79a2                	ld	s3,40(sp)
    80004eda:	7a02                	ld	s4,32(sp)
    80004edc:	6ae2                	ld	s5,24(sp)
    80004ede:	6b42                	ld	s6,16(sp)
    80004ee0:	6161                	addi	sp,sp,80
    80004ee2:	8082                	ret
      release(&pi->lock);
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	dde080e7          	jalr	-546(ra) # 80000cc4 <release>
      return -1;
    80004eee:	59fd                	li	s3,-1
    80004ef0:	bff9                	j	80004ece <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ef2:	4981                	li	s3,0
    80004ef4:	b7d1                	j	80004eb8 <piperead+0xae>

0000000080004ef6 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004ef6:	df010113          	addi	sp,sp,-528
    80004efa:	20113423          	sd	ra,520(sp)
    80004efe:	20813023          	sd	s0,512(sp)
    80004f02:	ffa6                	sd	s1,504(sp)
    80004f04:	fbca                	sd	s2,496(sp)
    80004f06:	f7ce                	sd	s3,488(sp)
    80004f08:	f3d2                	sd	s4,480(sp)
    80004f0a:	efd6                	sd	s5,472(sp)
    80004f0c:	ebda                	sd	s6,464(sp)
    80004f0e:	e7de                	sd	s7,456(sp)
    80004f10:	e3e2                	sd	s8,448(sp)
    80004f12:	ff66                	sd	s9,440(sp)
    80004f14:	fb6a                	sd	s10,432(sp)
    80004f16:	f76e                	sd	s11,424(sp)
    80004f18:	0c00                	addi	s0,sp,528
    80004f1a:	84aa                	mv	s1,a0
    80004f1c:	dea43c23          	sd	a0,-520(s0)
    80004f20:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004f24:	ffffd097          	auipc	ra,0xffffd
    80004f28:	c90080e7          	jalr	-880(ra) # 80001bb4 <myproc>
    80004f2c:	892a                	mv	s2,a0

  begin_op();
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	446080e7          	jalr	1094(ra) # 80004374 <begin_op>

  if((ip = namei(path)) == 0){
    80004f36:	8526                	mv	a0,s1
    80004f38:	fffff097          	auipc	ra,0xfffff
    80004f3c:	230080e7          	jalr	560(ra) # 80004168 <namei>
    80004f40:	c92d                	beqz	a0,80004fb2 <exec+0xbc>
    80004f42:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004f44:	fffff097          	auipc	ra,0xfffff
    80004f48:	a74080e7          	jalr	-1420(ra) # 800039b8 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004f4c:	04000713          	li	a4,64
    80004f50:	4681                	li	a3,0
    80004f52:	e4840613          	addi	a2,s0,-440
    80004f56:	4581                	li	a1,0
    80004f58:	8526                	mv	a0,s1
    80004f5a:	fffff097          	auipc	ra,0xfffff
    80004f5e:	d12080e7          	jalr	-750(ra) # 80003c6c <readi>
    80004f62:	04000793          	li	a5,64
    80004f66:	00f51a63          	bne	a0,a5,80004f7a <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004f6a:	e4842703          	lw	a4,-440(s0)
    80004f6e:	464c47b7          	lui	a5,0x464c4
    80004f72:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004f76:	04f70463          	beq	a4,a5,80004fbe <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004f7a:	8526                	mv	a0,s1
    80004f7c:	fffff097          	auipc	ra,0xfffff
    80004f80:	c9e080e7          	jalr	-866(ra) # 80003c1a <iunlockput>
    end_op();
    80004f84:	fffff097          	auipc	ra,0xfffff
    80004f88:	470080e7          	jalr	1136(ra) # 800043f4 <end_op>
  }
  return -1;
    80004f8c:	557d                	li	a0,-1
}
    80004f8e:	20813083          	ld	ra,520(sp)
    80004f92:	20013403          	ld	s0,512(sp)
    80004f96:	74fe                	ld	s1,504(sp)
    80004f98:	795e                	ld	s2,496(sp)
    80004f9a:	79be                	ld	s3,488(sp)
    80004f9c:	7a1e                	ld	s4,480(sp)
    80004f9e:	6afe                	ld	s5,472(sp)
    80004fa0:	6b5e                	ld	s6,464(sp)
    80004fa2:	6bbe                	ld	s7,456(sp)
    80004fa4:	6c1e                	ld	s8,448(sp)
    80004fa6:	7cfa                	ld	s9,440(sp)
    80004fa8:	7d5a                	ld	s10,432(sp)
    80004faa:	7dba                	ld	s11,424(sp)
    80004fac:	21010113          	addi	sp,sp,528
    80004fb0:	8082                	ret
    end_op();
    80004fb2:	fffff097          	auipc	ra,0xfffff
    80004fb6:	442080e7          	jalr	1090(ra) # 800043f4 <end_op>
    return -1;
    80004fba:	557d                	li	a0,-1
    80004fbc:	bfc9                	j	80004f8e <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004fbe:	854a                	mv	a0,s2
    80004fc0:	ffffd097          	auipc	ra,0xffffd
    80004fc4:	cb8080e7          	jalr	-840(ra) # 80001c78 <proc_pagetable>
    80004fc8:	8baa                	mv	s7,a0
    80004fca:	d945                	beqz	a0,80004f7a <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fcc:	e6842983          	lw	s3,-408(s0)
    80004fd0:	e8045783          	lhu	a5,-384(s0)
    80004fd4:	c7ad                	beqz	a5,8000503e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004fd6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fd8:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004fda:	6c85                	lui	s9,0x1
    80004fdc:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004fe0:	def43823          	sd	a5,-528(s0)
    80004fe4:	ac95                	j	80005258 <exec+0x362>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004fe6:	00003517          	auipc	a0,0x3
    80004fea:	71a50513          	addi	a0,a0,1818 # 80008700 <syscalls+0x290>
    80004fee:	ffffb097          	auipc	ra,0xffffb
    80004ff2:	55a080e7          	jalr	1370(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004ff6:	8756                	mv	a4,s5
    80004ff8:	012d86bb          	addw	a3,s11,s2
    80004ffc:	4581                	li	a1,0
    80004ffe:	8526                	mv	a0,s1
    80005000:	fffff097          	auipc	ra,0xfffff
    80005004:	c6c080e7          	jalr	-916(ra) # 80003c6c <readi>
    80005008:	2501                	sext.w	a0,a0
    8000500a:	1eaa9a63          	bne	s5,a0,800051fe <exec+0x308>
  for(i = 0; i < sz; i += PGSIZE){
    8000500e:	6785                	lui	a5,0x1
    80005010:	0127893b          	addw	s2,a5,s2
    80005014:	77fd                	lui	a5,0xfffff
    80005016:	01478a3b          	addw	s4,a5,s4
    8000501a:	23897663          	bgeu	s2,s8,80005246 <exec+0x350>
    pa = walkaddr(pagetable, va + i);
    8000501e:	02091593          	slli	a1,s2,0x20
    80005022:	9181                	srli	a1,a1,0x20
    80005024:	95ea                	add	a1,a1,s10
    80005026:	855e                	mv	a0,s7
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	11a080e7          	jalr	282(ra) # 80001142 <walkaddr>
    80005030:	862a                	mv	a2,a0
    if(pa == 0)
    80005032:	d955                	beqz	a0,80004fe6 <exec+0xf0>
      n = PGSIZE;
    80005034:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005036:	fd9a70e3          	bgeu	s4,s9,80004ff6 <exec+0x100>
      n = sz - i;
    8000503a:	8ad2                	mv	s5,s4
    8000503c:	bf6d                	j	80004ff6 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000503e:	4901                	li	s2,0
  iunlockput(ip);
    80005040:	8526                	mv	a0,s1
    80005042:	fffff097          	auipc	ra,0xfffff
    80005046:	bd8080e7          	jalr	-1064(ra) # 80003c1a <iunlockput>
  end_op();
    8000504a:	fffff097          	auipc	ra,0xfffff
    8000504e:	3aa080e7          	jalr	938(ra) # 800043f4 <end_op>
  p = myproc();
    80005052:	ffffd097          	auipc	ra,0xffffd
    80005056:	b62080e7          	jalr	-1182(ra) # 80001bb4 <myproc>
    8000505a:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000505c:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005060:	6785                	lui	a5,0x1
    80005062:	17fd                	addi	a5,a5,-1
    80005064:	993e                	add	s2,s2,a5
    80005066:	757d                	lui	a0,0xfffff
    80005068:	00a977b3          	and	a5,s2,a0
    8000506c:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005070:	6609                	lui	a2,0x2
    80005072:	963e                	add	a2,a2,a5
    80005074:	85be                	mv	a1,a5
    80005076:	855e                	mv	a0,s7
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	40a080e7          	jalr	1034(ra) # 80001482 <uvmalloc>
    80005080:	8b2a                	mv	s6,a0
  ip = 0;
    80005082:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005084:	16050d63          	beqz	a0,800051fe <exec+0x308>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005088:	75f9                	lui	a1,0xffffe
    8000508a:	95aa                	add	a1,a1,a0
    8000508c:	855e                	mv	a0,s7
    8000508e:	ffffd097          	auipc	ra,0xffffd
    80005092:	86c080e7          	jalr	-1940(ra) # 800018fa <uvmclear>
  stackbase = sp - PGSIZE;
    80005096:	7c7d                	lui	s8,0xfffff
    80005098:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    8000509a:	e0043783          	ld	a5,-512(s0)
    8000509e:	6388                	ld	a0,0(a5)
    800050a0:	c535                	beqz	a0,8000510c <exec+0x216>
    800050a2:	e8840993          	addi	s3,s0,-376
    800050a6:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800050aa:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800050ac:	ffffc097          	auipc	ra,0xffffc
    800050b0:	de8080e7          	jalr	-536(ra) # 80000e94 <strlen>
    800050b4:	2505                	addiw	a0,a0,1
    800050b6:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800050ba:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800050be:	17896463          	bltu	s2,s8,80005226 <exec+0x330>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800050c2:	e0043d83          	ld	s11,-512(s0)
    800050c6:	000dba03          	ld	s4,0(s11)
    800050ca:	8552                	mv	a0,s4
    800050cc:	ffffc097          	auipc	ra,0xffffc
    800050d0:	dc8080e7          	jalr	-568(ra) # 80000e94 <strlen>
    800050d4:	0015069b          	addiw	a3,a0,1
    800050d8:	8652                	mv	a2,s4
    800050da:	85ca                	mv	a1,s2
    800050dc:	855e                	mv	a0,s7
    800050de:	ffffd097          	auipc	ra,0xffffd
    800050e2:	84e080e7          	jalr	-1970(ra) # 8000192c <copyout>
    800050e6:	14054463          	bltz	a0,8000522e <exec+0x338>
    ustack[argc] = sp;
    800050ea:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800050ee:	0485                	addi	s1,s1,1
    800050f0:	008d8793          	addi	a5,s11,8
    800050f4:	e0f43023          	sd	a5,-512(s0)
    800050f8:	008db503          	ld	a0,8(s11)
    800050fc:	c911                	beqz	a0,80005110 <exec+0x21a>
    if(argc >= MAXARG)
    800050fe:	09a1                	addi	s3,s3,8
    80005100:	fb3c96e3          	bne	s9,s3,800050ac <exec+0x1b6>
  sz = sz1;
    80005104:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005108:	4481                	li	s1,0
    8000510a:	a8d5                	j	800051fe <exec+0x308>
  sp = sz;
    8000510c:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000510e:	4481                	li	s1,0
  ustack[argc] = 0;
    80005110:	00349793          	slli	a5,s1,0x3
    80005114:	f9040713          	addi	a4,s0,-112
    80005118:	97ba                	add	a5,a5,a4
    8000511a:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    8000511e:	00148693          	addi	a3,s1,1
    80005122:	068e                	slli	a3,a3,0x3
    80005124:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005128:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    8000512c:	01897663          	bgeu	s2,s8,80005138 <exec+0x242>
  sz = sz1;
    80005130:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005134:	4481                	li	s1,0
    80005136:	a0e1                	j	800051fe <exec+0x308>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005138:	e8840613          	addi	a2,s0,-376
    8000513c:	85ca                	mv	a1,s2
    8000513e:	855e                	mv	a0,s7
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	7ec080e7          	jalr	2028(ra) # 8000192c <copyout>
    80005148:	0e054763          	bltz	a0,80005236 <exec+0x340>
  p->trapframe->a1 = sp;
    8000514c:	060ab783          	ld	a5,96(s5)
    80005150:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005154:	df843783          	ld	a5,-520(s0)
    80005158:	0007c703          	lbu	a4,0(a5)
    8000515c:	cf11                	beqz	a4,80005178 <exec+0x282>
    8000515e:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005160:	02f00693          	li	a3,47
    80005164:	a029                	j	8000516e <exec+0x278>
  for(last=s=path; *s; s++)
    80005166:	0785                	addi	a5,a5,1
    80005168:	fff7c703          	lbu	a4,-1(a5)
    8000516c:	c711                	beqz	a4,80005178 <exec+0x282>
    if(*s == '/')
    8000516e:	fed71ce3          	bne	a4,a3,80005166 <exec+0x270>
      last = s+1;
    80005172:	def43c23          	sd	a5,-520(s0)
    80005176:	bfc5                	j	80005166 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005178:	4641                	li	a2,16
    8000517a:	df843583          	ld	a1,-520(s0)
    8000517e:	160a8513          	addi	a0,s5,352
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	ce0080e7          	jalr	-800(ra) # 80000e62 <safestrcpy>
  oldpagetable = p->pagetable;
    8000518a:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000518e:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005192:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005196:	060ab783          	ld	a5,96(s5)
    8000519a:	e6043703          	ld	a4,-416(s0)
    8000519e:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800051a0:	060ab783          	ld	a5,96(s5)
    800051a4:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800051a8:	85ea                	mv	a1,s10
    800051aa:	ffffd097          	auipc	ra,0xffffd
    800051ae:	b6a080e7          	jalr	-1174(ra) # 80001d14 <proc_freepagetable>
  uvmunmap(p->kpagetable, 0, oldsz / PGSIZE, 0);
    800051b2:	4681                	li	a3,0
    800051b4:	00cd5613          	srli	a2,s10,0xc
    800051b8:	4581                	li	a1,0
    800051ba:	058ab503          	ld	a0,88(s5)
    800051be:	ffffc097          	auipc	ra,0xffffc
    800051c2:	118080e7          	jalr	280(ra) # 800012d6 <uvmunmap>
  if (u2kcopy(pagetable, p->kpagetable, 0, sz) < 0)
    800051c6:	86da                	mv	a3,s6
    800051c8:	4601                	li	a2,0
    800051ca:	058ab583          	ld	a1,88(s5)
    800051ce:	855e                	mv	a0,s7
    800051d0:	ffffc097          	auipc	ra,0xffffc
    800051d4:	682080e7          	jalr	1666(ra) # 80001852 <u2kcopy>
    800051d8:	06054363          	bltz	a0,8000523e <exec+0x348>
  if (p->pid == 1)
    800051dc:	038aa703          	lw	a4,56(s5)
    800051e0:	4785                	li	a5,1
    800051e2:	00f70563          	beq	a4,a5,800051ec <exec+0x2f6>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800051e6:	0004851b          	sext.w	a0,s1
    800051ea:	b355                	j	80004f8e <exec+0x98>
    vmprint(p->pagetable);
    800051ec:	050ab503          	ld	a0,80(s5)
    800051f0:	ffffd097          	auipc	ra,0xffffd
    800051f4:	8b8080e7          	jalr	-1864(ra) # 80001aa8 <vmprint>
    800051f8:	b7fd                	j	800051e6 <exec+0x2f0>
    800051fa:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800051fe:	e0843583          	ld	a1,-504(s0)
    80005202:	855e                	mv	a0,s7
    80005204:	ffffd097          	auipc	ra,0xffffd
    80005208:	b10080e7          	jalr	-1264(ra) # 80001d14 <proc_freepagetable>
  if(ip){
    8000520c:	d60497e3          	bnez	s1,80004f7a <exec+0x84>
  return -1;
    80005210:	557d                	li	a0,-1
    80005212:	bbb5                	j	80004f8e <exec+0x98>
    80005214:	e1243423          	sd	s2,-504(s0)
    80005218:	b7dd                	j	800051fe <exec+0x308>
    8000521a:	e1243423          	sd	s2,-504(s0)
    8000521e:	b7c5                	j	800051fe <exec+0x308>
    80005220:	e1243423          	sd	s2,-504(s0)
    80005224:	bfe9                	j	800051fe <exec+0x308>
  sz = sz1;
    80005226:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000522a:	4481                	li	s1,0
    8000522c:	bfc9                	j	800051fe <exec+0x308>
  sz = sz1;
    8000522e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005232:	4481                	li	s1,0
    80005234:	b7e9                	j	800051fe <exec+0x308>
  sz = sz1;
    80005236:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000523a:	4481                	li	s1,0
    8000523c:	b7c9                	j	800051fe <exec+0x308>
  sz = sz1;
    8000523e:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005242:	4481                	li	s1,0
    80005244:	bf6d                	j	800051fe <exec+0x308>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005246:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000524a:	2b05                	addiw	s6,s6,1
    8000524c:	0389899b          	addiw	s3,s3,56
    80005250:	e8045783          	lhu	a5,-384(s0)
    80005254:	defb56e3          	bge	s6,a5,80005040 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005258:	2981                	sext.w	s3,s3
    8000525a:	03800713          	li	a4,56
    8000525e:	86ce                	mv	a3,s3
    80005260:	e1040613          	addi	a2,s0,-496
    80005264:	4581                	li	a1,0
    80005266:	8526                	mv	a0,s1
    80005268:	fffff097          	auipc	ra,0xfffff
    8000526c:	a04080e7          	jalr	-1532(ra) # 80003c6c <readi>
    80005270:	03800793          	li	a5,56
    80005274:	f8f513e3          	bne	a0,a5,800051fa <exec+0x304>
    if(ph.type != ELF_PROG_LOAD)
    80005278:	e1042783          	lw	a5,-496(s0)
    8000527c:	4705                	li	a4,1
    8000527e:	fce796e3          	bne	a5,a4,8000524a <exec+0x354>
    if(ph.memsz < ph.filesz)
    80005282:	e3843603          	ld	a2,-456(s0)
    80005286:	e3043783          	ld	a5,-464(s0)
    8000528a:	f8f665e3          	bltu	a2,a5,80005214 <exec+0x31e>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000528e:	e2043783          	ld	a5,-480(s0)
    80005292:	963e                	add	a2,a2,a5
    80005294:	f8f663e3          	bltu	a2,a5,8000521a <exec+0x324>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005298:	85ca                	mv	a1,s2
    8000529a:	855e                	mv	a0,s7
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	1e6080e7          	jalr	486(ra) # 80001482 <uvmalloc>
    800052a4:	e0a43423          	sd	a0,-504(s0)
    800052a8:	dd25                	beqz	a0,80005220 <exec+0x32a>
    if(ph.vaddr % PGSIZE != 0)
    800052aa:	e2043d03          	ld	s10,-480(s0)
    800052ae:	df043783          	ld	a5,-528(s0)
    800052b2:	00fd77b3          	and	a5,s10,a5
    800052b6:	f7a1                	bnez	a5,800051fe <exec+0x308>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800052b8:	e1842d83          	lw	s11,-488(s0)
    800052bc:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800052c0:	f80c03e3          	beqz	s8,80005246 <exec+0x350>
    800052c4:	8a62                	mv	s4,s8
    800052c6:	4901                	li	s2,0
    800052c8:	bb99                	j	8000501e <exec+0x128>

00000000800052ca <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	ec26                	sd	s1,24(sp)
    800052d2:	e84a                	sd	s2,16(sp)
    800052d4:	1800                	addi	s0,sp,48
    800052d6:	892e                	mv	s2,a1
    800052d8:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    800052da:	fdc40593          	addi	a1,s0,-36
    800052de:	ffffe097          	auipc	ra,0xffffe
    800052e2:	b68080e7          	jalr	-1176(ra) # 80002e46 <argint>
    800052e6:	04054063          	bltz	a0,80005326 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800052ea:	fdc42703          	lw	a4,-36(s0)
    800052ee:	47bd                	li	a5,15
    800052f0:	02e7ed63          	bltu	a5,a4,8000532a <argfd+0x60>
    800052f4:	ffffd097          	auipc	ra,0xffffd
    800052f8:	8c0080e7          	jalr	-1856(ra) # 80001bb4 <myproc>
    800052fc:	fdc42703          	lw	a4,-36(s0)
    80005300:	01a70793          	addi	a5,a4,26
    80005304:	078e                	slli	a5,a5,0x3
    80005306:	953e                	add	a0,a0,a5
    80005308:	651c                	ld	a5,8(a0)
    8000530a:	c395                	beqz	a5,8000532e <argfd+0x64>
    return -1;
  if(pfd)
    8000530c:	00090463          	beqz	s2,80005314 <argfd+0x4a>
    *pfd = fd;
    80005310:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005314:	4501                	li	a0,0
  if(pf)
    80005316:	c091                	beqz	s1,8000531a <argfd+0x50>
    *pf = f;
    80005318:	e09c                	sd	a5,0(s1)
}
    8000531a:	70a2                	ld	ra,40(sp)
    8000531c:	7402                	ld	s0,32(sp)
    8000531e:	64e2                	ld	s1,24(sp)
    80005320:	6942                	ld	s2,16(sp)
    80005322:	6145                	addi	sp,sp,48
    80005324:	8082                	ret
    return -1;
    80005326:	557d                	li	a0,-1
    80005328:	bfcd                	j	8000531a <argfd+0x50>
    return -1;
    8000532a:	557d                	li	a0,-1
    8000532c:	b7fd                	j	8000531a <argfd+0x50>
    8000532e:	557d                	li	a0,-1
    80005330:	b7ed                	j	8000531a <argfd+0x50>

0000000080005332 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005332:	1101                	addi	sp,sp,-32
    80005334:	ec06                	sd	ra,24(sp)
    80005336:	e822                	sd	s0,16(sp)
    80005338:	e426                	sd	s1,8(sp)
    8000533a:	1000                	addi	s0,sp,32
    8000533c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000533e:	ffffd097          	auipc	ra,0xffffd
    80005342:	876080e7          	jalr	-1930(ra) # 80001bb4 <myproc>
    80005346:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005348:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd80b8>
    8000534c:	4501                	li	a0,0
    8000534e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005350:	6398                	ld	a4,0(a5)
    80005352:	cb19                	beqz	a4,80005368 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005354:	2505                	addiw	a0,a0,1
    80005356:	07a1                	addi	a5,a5,8
    80005358:	fed51ce3          	bne	a0,a3,80005350 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000535c:	557d                	li	a0,-1
}
    8000535e:	60e2                	ld	ra,24(sp)
    80005360:	6442                	ld	s0,16(sp)
    80005362:	64a2                	ld	s1,8(sp)
    80005364:	6105                	addi	sp,sp,32
    80005366:	8082                	ret
      p->ofile[fd] = f;
    80005368:	01a50793          	addi	a5,a0,26
    8000536c:	078e                	slli	a5,a5,0x3
    8000536e:	963e                	add	a2,a2,a5
    80005370:	e604                	sd	s1,8(a2)
      return fd;
    80005372:	b7f5                	j	8000535e <fdalloc+0x2c>

0000000080005374 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005374:	715d                	addi	sp,sp,-80
    80005376:	e486                	sd	ra,72(sp)
    80005378:	e0a2                	sd	s0,64(sp)
    8000537a:	fc26                	sd	s1,56(sp)
    8000537c:	f84a                	sd	s2,48(sp)
    8000537e:	f44e                	sd	s3,40(sp)
    80005380:	f052                	sd	s4,32(sp)
    80005382:	ec56                	sd	s5,24(sp)
    80005384:	0880                	addi	s0,sp,80
    80005386:	89ae                	mv	s3,a1
    80005388:	8ab2                	mv	s5,a2
    8000538a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000538c:	fb040593          	addi	a1,s0,-80
    80005390:	fffff097          	auipc	ra,0xfffff
    80005394:	df6080e7          	jalr	-522(ra) # 80004186 <nameiparent>
    80005398:	892a                	mv	s2,a0
    8000539a:	12050f63          	beqz	a0,800054d8 <create+0x164>
    return 0;

  ilock(dp);
    8000539e:	ffffe097          	auipc	ra,0xffffe
    800053a2:	61a080e7          	jalr	1562(ra) # 800039b8 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800053a6:	4601                	li	a2,0
    800053a8:	fb040593          	addi	a1,s0,-80
    800053ac:	854a                	mv	a0,s2
    800053ae:	fffff097          	auipc	ra,0xfffff
    800053b2:	ae8080e7          	jalr	-1304(ra) # 80003e96 <dirlookup>
    800053b6:	84aa                	mv	s1,a0
    800053b8:	c921                	beqz	a0,80005408 <create+0x94>
    iunlockput(dp);
    800053ba:	854a                	mv	a0,s2
    800053bc:	fffff097          	auipc	ra,0xfffff
    800053c0:	85e080e7          	jalr	-1954(ra) # 80003c1a <iunlockput>
    ilock(ip);
    800053c4:	8526                	mv	a0,s1
    800053c6:	ffffe097          	auipc	ra,0xffffe
    800053ca:	5f2080e7          	jalr	1522(ra) # 800039b8 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800053ce:	2981                	sext.w	s3,s3
    800053d0:	4789                	li	a5,2
    800053d2:	02f99463          	bne	s3,a5,800053fa <create+0x86>
    800053d6:	0444d783          	lhu	a5,68(s1)
    800053da:	37f9                	addiw	a5,a5,-2
    800053dc:	17c2                	slli	a5,a5,0x30
    800053de:	93c1                	srli	a5,a5,0x30
    800053e0:	4705                	li	a4,1
    800053e2:	00f76c63          	bltu	a4,a5,800053fa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    800053e6:	8526                	mv	a0,s1
    800053e8:	60a6                	ld	ra,72(sp)
    800053ea:	6406                	ld	s0,64(sp)
    800053ec:	74e2                	ld	s1,56(sp)
    800053ee:	7942                	ld	s2,48(sp)
    800053f0:	79a2                	ld	s3,40(sp)
    800053f2:	7a02                	ld	s4,32(sp)
    800053f4:	6ae2                	ld	s5,24(sp)
    800053f6:	6161                	addi	sp,sp,80
    800053f8:	8082                	ret
    iunlockput(ip);
    800053fa:	8526                	mv	a0,s1
    800053fc:	fffff097          	auipc	ra,0xfffff
    80005400:	81e080e7          	jalr	-2018(ra) # 80003c1a <iunlockput>
    return 0;
    80005404:	4481                	li	s1,0
    80005406:	b7c5                	j	800053e6 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005408:	85ce                	mv	a1,s3
    8000540a:	00092503          	lw	a0,0(s2)
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	412080e7          	jalr	1042(ra) # 80003820 <ialloc>
    80005416:	84aa                	mv	s1,a0
    80005418:	c529                	beqz	a0,80005462 <create+0xee>
  ilock(ip);
    8000541a:	ffffe097          	auipc	ra,0xffffe
    8000541e:	59e080e7          	jalr	1438(ra) # 800039b8 <ilock>
  ip->major = major;
    80005422:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005426:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000542a:	4785                	li	a5,1
    8000542c:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005430:	8526                	mv	a0,s1
    80005432:	ffffe097          	auipc	ra,0xffffe
    80005436:	4bc080e7          	jalr	1212(ra) # 800038ee <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000543a:	2981                	sext.w	s3,s3
    8000543c:	4785                	li	a5,1
    8000543e:	02f98a63          	beq	s3,a5,80005472 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005442:	40d0                	lw	a2,4(s1)
    80005444:	fb040593          	addi	a1,s0,-80
    80005448:	854a                	mv	a0,s2
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	c5c080e7          	jalr	-932(ra) # 800040a6 <dirlink>
    80005452:	06054b63          	bltz	a0,800054c8 <create+0x154>
  iunlockput(dp);
    80005456:	854a                	mv	a0,s2
    80005458:	ffffe097          	auipc	ra,0xffffe
    8000545c:	7c2080e7          	jalr	1986(ra) # 80003c1a <iunlockput>
  return ip;
    80005460:	b759                	j	800053e6 <create+0x72>
    panic("create: ialloc");
    80005462:	00003517          	auipc	a0,0x3
    80005466:	2be50513          	addi	a0,a0,702 # 80008720 <syscalls+0x2b0>
    8000546a:	ffffb097          	auipc	ra,0xffffb
    8000546e:	0de080e7          	jalr	222(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    80005472:	04a95783          	lhu	a5,74(s2)
    80005476:	2785                	addiw	a5,a5,1
    80005478:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    8000547c:	854a                	mv	a0,s2
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	470080e7          	jalr	1136(ra) # 800038ee <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005486:	40d0                	lw	a2,4(s1)
    80005488:	00003597          	auipc	a1,0x3
    8000548c:	2a858593          	addi	a1,a1,680 # 80008730 <syscalls+0x2c0>
    80005490:	8526                	mv	a0,s1
    80005492:	fffff097          	auipc	ra,0xfffff
    80005496:	c14080e7          	jalr	-1004(ra) # 800040a6 <dirlink>
    8000549a:	00054f63          	bltz	a0,800054b8 <create+0x144>
    8000549e:	00492603          	lw	a2,4(s2)
    800054a2:	00003597          	auipc	a1,0x3
    800054a6:	d2e58593          	addi	a1,a1,-722 # 800081d0 <digits+0x190>
    800054aa:	8526                	mv	a0,s1
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	bfa080e7          	jalr	-1030(ra) # 800040a6 <dirlink>
    800054b4:	f80557e3          	bgez	a0,80005442 <create+0xce>
      panic("create dots");
    800054b8:	00003517          	auipc	a0,0x3
    800054bc:	28050513          	addi	a0,a0,640 # 80008738 <syscalls+0x2c8>
    800054c0:	ffffb097          	auipc	ra,0xffffb
    800054c4:	088080e7          	jalr	136(ra) # 80000548 <panic>
    panic("create: dirlink");
    800054c8:	00003517          	auipc	a0,0x3
    800054cc:	28050513          	addi	a0,a0,640 # 80008748 <syscalls+0x2d8>
    800054d0:	ffffb097          	auipc	ra,0xffffb
    800054d4:	078080e7          	jalr	120(ra) # 80000548 <panic>
    return 0;
    800054d8:	84aa                	mv	s1,a0
    800054da:	b731                	j	800053e6 <create+0x72>

00000000800054dc <sys_dup>:
{
    800054dc:	7179                	addi	sp,sp,-48
    800054de:	f406                	sd	ra,40(sp)
    800054e0:	f022                	sd	s0,32(sp)
    800054e2:	ec26                	sd	s1,24(sp)
    800054e4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054e6:	fd840613          	addi	a2,s0,-40
    800054ea:	4581                	li	a1,0
    800054ec:	4501                	li	a0,0
    800054ee:	00000097          	auipc	ra,0x0
    800054f2:	ddc080e7          	jalr	-548(ra) # 800052ca <argfd>
    return -1;
    800054f6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054f8:	02054363          	bltz	a0,8000551e <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800054fc:	fd843503          	ld	a0,-40(s0)
    80005500:	00000097          	auipc	ra,0x0
    80005504:	e32080e7          	jalr	-462(ra) # 80005332 <fdalloc>
    80005508:	84aa                	mv	s1,a0
    return -1;
    8000550a:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000550c:	00054963          	bltz	a0,8000551e <sys_dup+0x42>
  filedup(f);
    80005510:	fd843503          	ld	a0,-40(s0)
    80005514:	fffff097          	auipc	ra,0xfffff
    80005518:	2e0080e7          	jalr	736(ra) # 800047f4 <filedup>
  return fd;
    8000551c:	87a6                	mv	a5,s1
}
    8000551e:	853e                	mv	a0,a5
    80005520:	70a2                	ld	ra,40(sp)
    80005522:	7402                	ld	s0,32(sp)
    80005524:	64e2                	ld	s1,24(sp)
    80005526:	6145                	addi	sp,sp,48
    80005528:	8082                	ret

000000008000552a <sys_read>:
{
    8000552a:	7179                	addi	sp,sp,-48
    8000552c:	f406                	sd	ra,40(sp)
    8000552e:	f022                	sd	s0,32(sp)
    80005530:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005532:	fe840613          	addi	a2,s0,-24
    80005536:	4581                	li	a1,0
    80005538:	4501                	li	a0,0
    8000553a:	00000097          	auipc	ra,0x0
    8000553e:	d90080e7          	jalr	-624(ra) # 800052ca <argfd>
    return -1;
    80005542:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005544:	04054163          	bltz	a0,80005586 <sys_read+0x5c>
    80005548:	fe440593          	addi	a1,s0,-28
    8000554c:	4509                	li	a0,2
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	8f8080e7          	jalr	-1800(ra) # 80002e46 <argint>
    return -1;
    80005556:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005558:	02054763          	bltz	a0,80005586 <sys_read+0x5c>
    8000555c:	fd840593          	addi	a1,s0,-40
    80005560:	4505                	li	a0,1
    80005562:	ffffe097          	auipc	ra,0xffffe
    80005566:	906080e7          	jalr	-1786(ra) # 80002e68 <argaddr>
    return -1;
    8000556a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000556c:	00054d63          	bltz	a0,80005586 <sys_read+0x5c>
  return fileread(f, p, n);
    80005570:	fe442603          	lw	a2,-28(s0)
    80005574:	fd843583          	ld	a1,-40(s0)
    80005578:	fe843503          	ld	a0,-24(s0)
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	404080e7          	jalr	1028(ra) # 80004980 <fileread>
    80005584:	87aa                	mv	a5,a0
}
    80005586:	853e                	mv	a0,a5
    80005588:	70a2                	ld	ra,40(sp)
    8000558a:	7402                	ld	s0,32(sp)
    8000558c:	6145                	addi	sp,sp,48
    8000558e:	8082                	ret

0000000080005590 <sys_write>:
{
    80005590:	7179                	addi	sp,sp,-48
    80005592:	f406                	sd	ra,40(sp)
    80005594:	f022                	sd	s0,32(sp)
    80005596:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005598:	fe840613          	addi	a2,s0,-24
    8000559c:	4581                	li	a1,0
    8000559e:	4501                	li	a0,0
    800055a0:	00000097          	auipc	ra,0x0
    800055a4:	d2a080e7          	jalr	-726(ra) # 800052ca <argfd>
    return -1;
    800055a8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055aa:	04054163          	bltz	a0,800055ec <sys_write+0x5c>
    800055ae:	fe440593          	addi	a1,s0,-28
    800055b2:	4509                	li	a0,2
    800055b4:	ffffe097          	auipc	ra,0xffffe
    800055b8:	892080e7          	jalr	-1902(ra) # 80002e46 <argint>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055be:	02054763          	bltz	a0,800055ec <sys_write+0x5c>
    800055c2:	fd840593          	addi	a1,s0,-40
    800055c6:	4505                	li	a0,1
    800055c8:	ffffe097          	auipc	ra,0xffffe
    800055cc:	8a0080e7          	jalr	-1888(ra) # 80002e68 <argaddr>
    return -1;
    800055d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800055d2:	00054d63          	bltz	a0,800055ec <sys_write+0x5c>
  return filewrite(f, p, n);
    800055d6:	fe442603          	lw	a2,-28(s0)
    800055da:	fd843583          	ld	a1,-40(s0)
    800055de:	fe843503          	ld	a0,-24(s0)
    800055e2:	fffff097          	auipc	ra,0xfffff
    800055e6:	460080e7          	jalr	1120(ra) # 80004a42 <filewrite>
    800055ea:	87aa                	mv	a5,a0
}
    800055ec:	853e                	mv	a0,a5
    800055ee:	70a2                	ld	ra,40(sp)
    800055f0:	7402                	ld	s0,32(sp)
    800055f2:	6145                	addi	sp,sp,48
    800055f4:	8082                	ret

00000000800055f6 <sys_close>:
{
    800055f6:	1101                	addi	sp,sp,-32
    800055f8:	ec06                	sd	ra,24(sp)
    800055fa:	e822                	sd	s0,16(sp)
    800055fc:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055fe:	fe040613          	addi	a2,s0,-32
    80005602:	fec40593          	addi	a1,s0,-20
    80005606:	4501                	li	a0,0
    80005608:	00000097          	auipc	ra,0x0
    8000560c:	cc2080e7          	jalr	-830(ra) # 800052ca <argfd>
    return -1;
    80005610:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005612:	02054463          	bltz	a0,8000563a <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005616:	ffffc097          	auipc	ra,0xffffc
    8000561a:	59e080e7          	jalr	1438(ra) # 80001bb4 <myproc>
    8000561e:	fec42783          	lw	a5,-20(s0)
    80005622:	07e9                	addi	a5,a5,26
    80005624:	078e                	slli	a5,a5,0x3
    80005626:	97aa                	add	a5,a5,a0
    80005628:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    8000562c:	fe043503          	ld	a0,-32(s0)
    80005630:	fffff097          	auipc	ra,0xfffff
    80005634:	216080e7          	jalr	534(ra) # 80004846 <fileclose>
  return 0;
    80005638:	4781                	li	a5,0
}
    8000563a:	853e                	mv	a0,a5
    8000563c:	60e2                	ld	ra,24(sp)
    8000563e:	6442                	ld	s0,16(sp)
    80005640:	6105                	addi	sp,sp,32
    80005642:	8082                	ret

0000000080005644 <sys_fstat>:
{
    80005644:	1101                	addi	sp,sp,-32
    80005646:	ec06                	sd	ra,24(sp)
    80005648:	e822                	sd	s0,16(sp)
    8000564a:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000564c:	fe840613          	addi	a2,s0,-24
    80005650:	4581                	li	a1,0
    80005652:	4501                	li	a0,0
    80005654:	00000097          	auipc	ra,0x0
    80005658:	c76080e7          	jalr	-906(ra) # 800052ca <argfd>
    return -1;
    8000565c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000565e:	02054563          	bltz	a0,80005688 <sys_fstat+0x44>
    80005662:	fe040593          	addi	a1,s0,-32
    80005666:	4505                	li	a0,1
    80005668:	ffffe097          	auipc	ra,0xffffe
    8000566c:	800080e7          	jalr	-2048(ra) # 80002e68 <argaddr>
    return -1;
    80005670:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005672:	00054b63          	bltz	a0,80005688 <sys_fstat+0x44>
  return filestat(f, st);
    80005676:	fe043583          	ld	a1,-32(s0)
    8000567a:	fe843503          	ld	a0,-24(s0)
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	290080e7          	jalr	656(ra) # 8000490e <filestat>
    80005686:	87aa                	mv	a5,a0
}
    80005688:	853e                	mv	a0,a5
    8000568a:	60e2                	ld	ra,24(sp)
    8000568c:	6442                	ld	s0,16(sp)
    8000568e:	6105                	addi	sp,sp,32
    80005690:	8082                	ret

0000000080005692 <sys_link>:
{
    80005692:	7169                	addi	sp,sp,-304
    80005694:	f606                	sd	ra,296(sp)
    80005696:	f222                	sd	s0,288(sp)
    80005698:	ee26                	sd	s1,280(sp)
    8000569a:	ea4a                	sd	s2,272(sp)
    8000569c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000569e:	08000613          	li	a2,128
    800056a2:	ed040593          	addi	a1,s0,-304
    800056a6:	4501                	li	a0,0
    800056a8:	ffffd097          	auipc	ra,0xffffd
    800056ac:	7e2080e7          	jalr	2018(ra) # 80002e8a <argstr>
    return -1;
    800056b0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056b2:	10054e63          	bltz	a0,800057ce <sys_link+0x13c>
    800056b6:	08000613          	li	a2,128
    800056ba:	f5040593          	addi	a1,s0,-176
    800056be:	4505                	li	a0,1
    800056c0:	ffffd097          	auipc	ra,0xffffd
    800056c4:	7ca080e7          	jalr	1994(ra) # 80002e8a <argstr>
    return -1;
    800056c8:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800056ca:	10054263          	bltz	a0,800057ce <sys_link+0x13c>
  begin_op();
    800056ce:	fffff097          	auipc	ra,0xfffff
    800056d2:	ca6080e7          	jalr	-858(ra) # 80004374 <begin_op>
  if((ip = namei(old)) == 0){
    800056d6:	ed040513          	addi	a0,s0,-304
    800056da:	fffff097          	auipc	ra,0xfffff
    800056de:	a8e080e7          	jalr	-1394(ra) # 80004168 <namei>
    800056e2:	84aa                	mv	s1,a0
    800056e4:	c551                	beqz	a0,80005770 <sys_link+0xde>
  ilock(ip);
    800056e6:	ffffe097          	auipc	ra,0xffffe
    800056ea:	2d2080e7          	jalr	722(ra) # 800039b8 <ilock>
  if(ip->type == T_DIR){
    800056ee:	04449703          	lh	a4,68(s1)
    800056f2:	4785                	li	a5,1
    800056f4:	08f70463          	beq	a4,a5,8000577c <sys_link+0xea>
  ip->nlink++;
    800056f8:	04a4d783          	lhu	a5,74(s1)
    800056fc:	2785                	addiw	a5,a5,1
    800056fe:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005702:	8526                	mv	a0,s1
    80005704:	ffffe097          	auipc	ra,0xffffe
    80005708:	1ea080e7          	jalr	490(ra) # 800038ee <iupdate>
  iunlock(ip);
    8000570c:	8526                	mv	a0,s1
    8000570e:	ffffe097          	auipc	ra,0xffffe
    80005712:	36c080e7          	jalr	876(ra) # 80003a7a <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005716:	fd040593          	addi	a1,s0,-48
    8000571a:	f5040513          	addi	a0,s0,-176
    8000571e:	fffff097          	auipc	ra,0xfffff
    80005722:	a68080e7          	jalr	-1432(ra) # 80004186 <nameiparent>
    80005726:	892a                	mv	s2,a0
    80005728:	c935                	beqz	a0,8000579c <sys_link+0x10a>
  ilock(dp);
    8000572a:	ffffe097          	auipc	ra,0xffffe
    8000572e:	28e080e7          	jalr	654(ra) # 800039b8 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005732:	00092703          	lw	a4,0(s2)
    80005736:	409c                	lw	a5,0(s1)
    80005738:	04f71d63          	bne	a4,a5,80005792 <sys_link+0x100>
    8000573c:	40d0                	lw	a2,4(s1)
    8000573e:	fd040593          	addi	a1,s0,-48
    80005742:	854a                	mv	a0,s2
    80005744:	fffff097          	auipc	ra,0xfffff
    80005748:	962080e7          	jalr	-1694(ra) # 800040a6 <dirlink>
    8000574c:	04054363          	bltz	a0,80005792 <sys_link+0x100>
  iunlockput(dp);
    80005750:	854a                	mv	a0,s2
    80005752:	ffffe097          	auipc	ra,0xffffe
    80005756:	4c8080e7          	jalr	1224(ra) # 80003c1a <iunlockput>
  iput(ip);
    8000575a:	8526                	mv	a0,s1
    8000575c:	ffffe097          	auipc	ra,0xffffe
    80005760:	416080e7          	jalr	1046(ra) # 80003b72 <iput>
  end_op();
    80005764:	fffff097          	auipc	ra,0xfffff
    80005768:	c90080e7          	jalr	-880(ra) # 800043f4 <end_op>
  return 0;
    8000576c:	4781                	li	a5,0
    8000576e:	a085                	j	800057ce <sys_link+0x13c>
    end_op();
    80005770:	fffff097          	auipc	ra,0xfffff
    80005774:	c84080e7          	jalr	-892(ra) # 800043f4 <end_op>
    return -1;
    80005778:	57fd                	li	a5,-1
    8000577a:	a891                	j	800057ce <sys_link+0x13c>
    iunlockput(ip);
    8000577c:	8526                	mv	a0,s1
    8000577e:	ffffe097          	auipc	ra,0xffffe
    80005782:	49c080e7          	jalr	1180(ra) # 80003c1a <iunlockput>
    end_op();
    80005786:	fffff097          	auipc	ra,0xfffff
    8000578a:	c6e080e7          	jalr	-914(ra) # 800043f4 <end_op>
    return -1;
    8000578e:	57fd                	li	a5,-1
    80005790:	a83d                	j	800057ce <sys_link+0x13c>
    iunlockput(dp);
    80005792:	854a                	mv	a0,s2
    80005794:	ffffe097          	auipc	ra,0xffffe
    80005798:	486080e7          	jalr	1158(ra) # 80003c1a <iunlockput>
  ilock(ip);
    8000579c:	8526                	mv	a0,s1
    8000579e:	ffffe097          	auipc	ra,0xffffe
    800057a2:	21a080e7          	jalr	538(ra) # 800039b8 <ilock>
  ip->nlink--;
    800057a6:	04a4d783          	lhu	a5,74(s1)
    800057aa:	37fd                	addiw	a5,a5,-1
    800057ac:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800057b0:	8526                	mv	a0,s1
    800057b2:	ffffe097          	auipc	ra,0xffffe
    800057b6:	13c080e7          	jalr	316(ra) # 800038ee <iupdate>
  iunlockput(ip);
    800057ba:	8526                	mv	a0,s1
    800057bc:	ffffe097          	auipc	ra,0xffffe
    800057c0:	45e080e7          	jalr	1118(ra) # 80003c1a <iunlockput>
  end_op();
    800057c4:	fffff097          	auipc	ra,0xfffff
    800057c8:	c30080e7          	jalr	-976(ra) # 800043f4 <end_op>
  return -1;
    800057cc:	57fd                	li	a5,-1
}
    800057ce:	853e                	mv	a0,a5
    800057d0:	70b2                	ld	ra,296(sp)
    800057d2:	7412                	ld	s0,288(sp)
    800057d4:	64f2                	ld	s1,280(sp)
    800057d6:	6952                	ld	s2,272(sp)
    800057d8:	6155                	addi	sp,sp,304
    800057da:	8082                	ret

00000000800057dc <sys_unlink>:
{
    800057dc:	7151                	addi	sp,sp,-240
    800057de:	f586                	sd	ra,232(sp)
    800057e0:	f1a2                	sd	s0,224(sp)
    800057e2:	eda6                	sd	s1,216(sp)
    800057e4:	e9ca                	sd	s2,208(sp)
    800057e6:	e5ce                	sd	s3,200(sp)
    800057e8:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800057ea:	08000613          	li	a2,128
    800057ee:	f3040593          	addi	a1,s0,-208
    800057f2:	4501                	li	a0,0
    800057f4:	ffffd097          	auipc	ra,0xffffd
    800057f8:	696080e7          	jalr	1686(ra) # 80002e8a <argstr>
    800057fc:	18054163          	bltz	a0,8000597e <sys_unlink+0x1a2>
  begin_op();
    80005800:	fffff097          	auipc	ra,0xfffff
    80005804:	b74080e7          	jalr	-1164(ra) # 80004374 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005808:	fb040593          	addi	a1,s0,-80
    8000580c:	f3040513          	addi	a0,s0,-208
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	976080e7          	jalr	-1674(ra) # 80004186 <nameiparent>
    80005818:	84aa                	mv	s1,a0
    8000581a:	c979                	beqz	a0,800058f0 <sys_unlink+0x114>
  ilock(dp);
    8000581c:	ffffe097          	auipc	ra,0xffffe
    80005820:	19c080e7          	jalr	412(ra) # 800039b8 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005824:	00003597          	auipc	a1,0x3
    80005828:	f0c58593          	addi	a1,a1,-244 # 80008730 <syscalls+0x2c0>
    8000582c:	fb040513          	addi	a0,s0,-80
    80005830:	ffffe097          	auipc	ra,0xffffe
    80005834:	64c080e7          	jalr	1612(ra) # 80003e7c <namecmp>
    80005838:	14050a63          	beqz	a0,8000598c <sys_unlink+0x1b0>
    8000583c:	00003597          	auipc	a1,0x3
    80005840:	99458593          	addi	a1,a1,-1644 # 800081d0 <digits+0x190>
    80005844:	fb040513          	addi	a0,s0,-80
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	634080e7          	jalr	1588(ra) # 80003e7c <namecmp>
    80005850:	12050e63          	beqz	a0,8000598c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005854:	f2c40613          	addi	a2,s0,-212
    80005858:	fb040593          	addi	a1,s0,-80
    8000585c:	8526                	mv	a0,s1
    8000585e:	ffffe097          	auipc	ra,0xffffe
    80005862:	638080e7          	jalr	1592(ra) # 80003e96 <dirlookup>
    80005866:	892a                	mv	s2,a0
    80005868:	12050263          	beqz	a0,8000598c <sys_unlink+0x1b0>
  ilock(ip);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	14c080e7          	jalr	332(ra) # 800039b8 <ilock>
  if(ip->nlink < 1)
    80005874:	04a91783          	lh	a5,74(s2)
    80005878:	08f05263          	blez	a5,800058fc <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000587c:	04491703          	lh	a4,68(s2)
    80005880:	4785                	li	a5,1
    80005882:	08f70563          	beq	a4,a5,8000590c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005886:	4641                	li	a2,16
    80005888:	4581                	li	a1,0
    8000588a:	fc040513          	addi	a0,s0,-64
    8000588e:	ffffb097          	auipc	ra,0xffffb
    80005892:	47e080e7          	jalr	1150(ra) # 80000d0c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005896:	4741                	li	a4,16
    80005898:	f2c42683          	lw	a3,-212(s0)
    8000589c:	fc040613          	addi	a2,s0,-64
    800058a0:	4581                	li	a1,0
    800058a2:	8526                	mv	a0,s1
    800058a4:	ffffe097          	auipc	ra,0xffffe
    800058a8:	4be080e7          	jalr	1214(ra) # 80003d62 <writei>
    800058ac:	47c1                	li	a5,16
    800058ae:	0af51563          	bne	a0,a5,80005958 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800058b2:	04491703          	lh	a4,68(s2)
    800058b6:	4785                	li	a5,1
    800058b8:	0af70863          	beq	a4,a5,80005968 <sys_unlink+0x18c>
  iunlockput(dp);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	35c080e7          	jalr	860(ra) # 80003c1a <iunlockput>
  ip->nlink--;
    800058c6:	04a95783          	lhu	a5,74(s2)
    800058ca:	37fd                	addiw	a5,a5,-1
    800058cc:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800058d0:	854a                	mv	a0,s2
    800058d2:	ffffe097          	auipc	ra,0xffffe
    800058d6:	01c080e7          	jalr	28(ra) # 800038ee <iupdate>
  iunlockput(ip);
    800058da:	854a                	mv	a0,s2
    800058dc:	ffffe097          	auipc	ra,0xffffe
    800058e0:	33e080e7          	jalr	830(ra) # 80003c1a <iunlockput>
  end_op();
    800058e4:	fffff097          	auipc	ra,0xfffff
    800058e8:	b10080e7          	jalr	-1264(ra) # 800043f4 <end_op>
  return 0;
    800058ec:	4501                	li	a0,0
    800058ee:	a84d                	j	800059a0 <sys_unlink+0x1c4>
    end_op();
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	b04080e7          	jalr	-1276(ra) # 800043f4 <end_op>
    return -1;
    800058f8:	557d                	li	a0,-1
    800058fa:	a05d                	j	800059a0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058fc:	00003517          	auipc	a0,0x3
    80005900:	e5c50513          	addi	a0,a0,-420 # 80008758 <syscalls+0x2e8>
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	c44080e7          	jalr	-956(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000590c:	04c92703          	lw	a4,76(s2)
    80005910:	02000793          	li	a5,32
    80005914:	f6e7f9e3          	bgeu	a5,a4,80005886 <sys_unlink+0xaa>
    80005918:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000591c:	4741                	li	a4,16
    8000591e:	86ce                	mv	a3,s3
    80005920:	f1840613          	addi	a2,s0,-232
    80005924:	4581                	li	a1,0
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	344080e7          	jalr	836(ra) # 80003c6c <readi>
    80005930:	47c1                	li	a5,16
    80005932:	00f51b63          	bne	a0,a5,80005948 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005936:	f1845783          	lhu	a5,-232(s0)
    8000593a:	e7a1                	bnez	a5,80005982 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000593c:	29c1                	addiw	s3,s3,16
    8000593e:	04c92783          	lw	a5,76(s2)
    80005942:	fcf9ede3          	bltu	s3,a5,8000591c <sys_unlink+0x140>
    80005946:	b781                	j	80005886 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005948:	00003517          	auipc	a0,0x3
    8000594c:	e2850513          	addi	a0,a0,-472 # 80008770 <syscalls+0x300>
    80005950:	ffffb097          	auipc	ra,0xffffb
    80005954:	bf8080e7          	jalr	-1032(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005958:	00003517          	auipc	a0,0x3
    8000595c:	e3050513          	addi	a0,a0,-464 # 80008788 <syscalls+0x318>
    80005960:	ffffb097          	auipc	ra,0xffffb
    80005964:	be8080e7          	jalr	-1048(ra) # 80000548 <panic>
    dp->nlink--;
    80005968:	04a4d783          	lhu	a5,74(s1)
    8000596c:	37fd                	addiw	a5,a5,-1
    8000596e:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005972:	8526                	mv	a0,s1
    80005974:	ffffe097          	auipc	ra,0xffffe
    80005978:	f7a080e7          	jalr	-134(ra) # 800038ee <iupdate>
    8000597c:	b781                	j	800058bc <sys_unlink+0xe0>
    return -1;
    8000597e:	557d                	li	a0,-1
    80005980:	a005                	j	800059a0 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005982:	854a                	mv	a0,s2
    80005984:	ffffe097          	auipc	ra,0xffffe
    80005988:	296080e7          	jalr	662(ra) # 80003c1a <iunlockput>
  iunlockput(dp);
    8000598c:	8526                	mv	a0,s1
    8000598e:	ffffe097          	auipc	ra,0xffffe
    80005992:	28c080e7          	jalr	652(ra) # 80003c1a <iunlockput>
  end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	a5e080e7          	jalr	-1442(ra) # 800043f4 <end_op>
  return -1;
    8000599e:	557d                	li	a0,-1
}
    800059a0:	70ae                	ld	ra,232(sp)
    800059a2:	740e                	ld	s0,224(sp)
    800059a4:	64ee                	ld	s1,216(sp)
    800059a6:	694e                	ld	s2,208(sp)
    800059a8:	69ae                	ld	s3,200(sp)
    800059aa:	616d                	addi	sp,sp,240
    800059ac:	8082                	ret

00000000800059ae <sys_open>:

uint64
sys_open(void)
{
    800059ae:	7131                	addi	sp,sp,-192
    800059b0:	fd06                	sd	ra,184(sp)
    800059b2:	f922                	sd	s0,176(sp)
    800059b4:	f526                	sd	s1,168(sp)
    800059b6:	f14a                	sd	s2,160(sp)
    800059b8:	ed4e                	sd	s3,152(sp)
    800059ba:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059bc:	08000613          	li	a2,128
    800059c0:	f5040593          	addi	a1,s0,-176
    800059c4:	4501                	li	a0,0
    800059c6:	ffffd097          	auipc	ra,0xffffd
    800059ca:	4c4080e7          	jalr	1220(ra) # 80002e8a <argstr>
    return -1;
    800059ce:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800059d0:	0c054163          	bltz	a0,80005a92 <sys_open+0xe4>
    800059d4:	f4c40593          	addi	a1,s0,-180
    800059d8:	4505                	li	a0,1
    800059da:	ffffd097          	auipc	ra,0xffffd
    800059de:	46c080e7          	jalr	1132(ra) # 80002e46 <argint>
    800059e2:	0a054863          	bltz	a0,80005a92 <sys_open+0xe4>

  begin_op();
    800059e6:	fffff097          	auipc	ra,0xfffff
    800059ea:	98e080e7          	jalr	-1650(ra) # 80004374 <begin_op>

  if(omode & O_CREATE){
    800059ee:	f4c42783          	lw	a5,-180(s0)
    800059f2:	2007f793          	andi	a5,a5,512
    800059f6:	cbdd                	beqz	a5,80005aac <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    800059f8:	4681                	li	a3,0
    800059fa:	4601                	li	a2,0
    800059fc:	4589                	li	a1,2
    800059fe:	f5040513          	addi	a0,s0,-176
    80005a02:	00000097          	auipc	ra,0x0
    80005a06:	972080e7          	jalr	-1678(ra) # 80005374 <create>
    80005a0a:	892a                	mv	s2,a0
    if(ip == 0){
    80005a0c:	c959                	beqz	a0,80005aa2 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005a0e:	04491703          	lh	a4,68(s2)
    80005a12:	478d                	li	a5,3
    80005a14:	00f71763          	bne	a4,a5,80005a22 <sys_open+0x74>
    80005a18:	04695703          	lhu	a4,70(s2)
    80005a1c:	47a5                	li	a5,9
    80005a1e:	0ce7ec63          	bltu	a5,a4,80005af6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005a22:	fffff097          	auipc	ra,0xfffff
    80005a26:	d68080e7          	jalr	-664(ra) # 8000478a <filealloc>
    80005a2a:	89aa                	mv	s3,a0
    80005a2c:	10050263          	beqz	a0,80005b30 <sys_open+0x182>
    80005a30:	00000097          	auipc	ra,0x0
    80005a34:	902080e7          	jalr	-1790(ra) # 80005332 <fdalloc>
    80005a38:	84aa                	mv	s1,a0
    80005a3a:	0e054663          	bltz	a0,80005b26 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005a3e:	04491703          	lh	a4,68(s2)
    80005a42:	478d                	li	a5,3
    80005a44:	0cf70463          	beq	a4,a5,80005b0c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005a48:	4789                	li	a5,2
    80005a4a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005a4e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005a52:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005a56:	f4c42783          	lw	a5,-180(s0)
    80005a5a:	0017c713          	xori	a4,a5,1
    80005a5e:	8b05                	andi	a4,a4,1
    80005a60:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a64:	0037f713          	andi	a4,a5,3
    80005a68:	00e03733          	snez	a4,a4
    80005a6c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a70:	4007f793          	andi	a5,a5,1024
    80005a74:	c791                	beqz	a5,80005a80 <sys_open+0xd2>
    80005a76:	04491703          	lh	a4,68(s2)
    80005a7a:	4789                	li	a5,2
    80005a7c:	08f70f63          	beq	a4,a5,80005b1a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	ff8080e7          	jalr	-8(ra) # 80003a7a <iunlock>
  end_op();
    80005a8a:	fffff097          	auipc	ra,0xfffff
    80005a8e:	96a080e7          	jalr	-1686(ra) # 800043f4 <end_op>

  return fd;
}
    80005a92:	8526                	mv	a0,s1
    80005a94:	70ea                	ld	ra,184(sp)
    80005a96:	744a                	ld	s0,176(sp)
    80005a98:	74aa                	ld	s1,168(sp)
    80005a9a:	790a                	ld	s2,160(sp)
    80005a9c:	69ea                	ld	s3,152(sp)
    80005a9e:	6129                	addi	sp,sp,192
    80005aa0:	8082                	ret
      end_op();
    80005aa2:	fffff097          	auipc	ra,0xfffff
    80005aa6:	952080e7          	jalr	-1710(ra) # 800043f4 <end_op>
      return -1;
    80005aaa:	b7e5                	j	80005a92 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005aac:	f5040513          	addi	a0,s0,-176
    80005ab0:	ffffe097          	auipc	ra,0xffffe
    80005ab4:	6b8080e7          	jalr	1720(ra) # 80004168 <namei>
    80005ab8:	892a                	mv	s2,a0
    80005aba:	c905                	beqz	a0,80005aea <sys_open+0x13c>
    ilock(ip);
    80005abc:	ffffe097          	auipc	ra,0xffffe
    80005ac0:	efc080e7          	jalr	-260(ra) # 800039b8 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005ac4:	04491703          	lh	a4,68(s2)
    80005ac8:	4785                	li	a5,1
    80005aca:	f4f712e3          	bne	a4,a5,80005a0e <sys_open+0x60>
    80005ace:	f4c42783          	lw	a5,-180(s0)
    80005ad2:	dba1                	beqz	a5,80005a22 <sys_open+0x74>
      iunlockput(ip);
    80005ad4:	854a                	mv	a0,s2
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	144080e7          	jalr	324(ra) # 80003c1a <iunlockput>
      end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	916080e7          	jalr	-1770(ra) # 800043f4 <end_op>
      return -1;
    80005ae6:	54fd                	li	s1,-1
    80005ae8:	b76d                	j	80005a92 <sys_open+0xe4>
      end_op();
    80005aea:	fffff097          	auipc	ra,0xfffff
    80005aee:	90a080e7          	jalr	-1782(ra) # 800043f4 <end_op>
      return -1;
    80005af2:	54fd                	li	s1,-1
    80005af4:	bf79                	j	80005a92 <sys_open+0xe4>
    iunlockput(ip);
    80005af6:	854a                	mv	a0,s2
    80005af8:	ffffe097          	auipc	ra,0xffffe
    80005afc:	122080e7          	jalr	290(ra) # 80003c1a <iunlockput>
    end_op();
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	8f4080e7          	jalr	-1804(ra) # 800043f4 <end_op>
    return -1;
    80005b08:	54fd                	li	s1,-1
    80005b0a:	b761                	j	80005a92 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005b0c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005b10:	04691783          	lh	a5,70(s2)
    80005b14:	02f99223          	sh	a5,36(s3)
    80005b18:	bf2d                	j	80005a52 <sys_open+0xa4>
    itrunc(ip);
    80005b1a:	854a                	mv	a0,s2
    80005b1c:	ffffe097          	auipc	ra,0xffffe
    80005b20:	faa080e7          	jalr	-86(ra) # 80003ac6 <itrunc>
    80005b24:	bfb1                	j	80005a80 <sys_open+0xd2>
      fileclose(f);
    80005b26:	854e                	mv	a0,s3
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	d1e080e7          	jalr	-738(ra) # 80004846 <fileclose>
    iunlockput(ip);
    80005b30:	854a                	mv	a0,s2
    80005b32:	ffffe097          	auipc	ra,0xffffe
    80005b36:	0e8080e7          	jalr	232(ra) # 80003c1a <iunlockput>
    end_op();
    80005b3a:	fffff097          	auipc	ra,0xfffff
    80005b3e:	8ba080e7          	jalr	-1862(ra) # 800043f4 <end_op>
    return -1;
    80005b42:	54fd                	li	s1,-1
    80005b44:	b7b9                	j	80005a92 <sys_open+0xe4>

0000000080005b46 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005b46:	7175                	addi	sp,sp,-144
    80005b48:	e506                	sd	ra,136(sp)
    80005b4a:	e122                	sd	s0,128(sp)
    80005b4c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005b4e:	fffff097          	auipc	ra,0xfffff
    80005b52:	826080e7          	jalr	-2010(ra) # 80004374 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005b56:	08000613          	li	a2,128
    80005b5a:	f7040593          	addi	a1,s0,-144
    80005b5e:	4501                	li	a0,0
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	32a080e7          	jalr	810(ra) # 80002e8a <argstr>
    80005b68:	02054963          	bltz	a0,80005b9a <sys_mkdir+0x54>
    80005b6c:	4681                	li	a3,0
    80005b6e:	4601                	li	a2,0
    80005b70:	4585                	li	a1,1
    80005b72:	f7040513          	addi	a0,s0,-144
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	7fe080e7          	jalr	2046(ra) # 80005374 <create>
    80005b7e:	cd11                	beqz	a0,80005b9a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b80:	ffffe097          	auipc	ra,0xffffe
    80005b84:	09a080e7          	jalr	154(ra) # 80003c1a <iunlockput>
  end_op();
    80005b88:	fffff097          	auipc	ra,0xfffff
    80005b8c:	86c080e7          	jalr	-1940(ra) # 800043f4 <end_op>
  return 0;
    80005b90:	4501                	li	a0,0
}
    80005b92:	60aa                	ld	ra,136(sp)
    80005b94:	640a                	ld	s0,128(sp)
    80005b96:	6149                	addi	sp,sp,144
    80005b98:	8082                	ret
    end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	85a080e7          	jalr	-1958(ra) # 800043f4 <end_op>
    return -1;
    80005ba2:	557d                	li	a0,-1
    80005ba4:	b7fd                	j	80005b92 <sys_mkdir+0x4c>

0000000080005ba6 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ba6:	7135                	addi	sp,sp,-160
    80005ba8:	ed06                	sd	ra,152(sp)
    80005baa:	e922                	sd	s0,144(sp)
    80005bac:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005bae:	ffffe097          	auipc	ra,0xffffe
    80005bb2:	7c6080e7          	jalr	1990(ra) # 80004374 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bb6:	08000613          	li	a2,128
    80005bba:	f7040593          	addi	a1,s0,-144
    80005bbe:	4501                	li	a0,0
    80005bc0:	ffffd097          	auipc	ra,0xffffd
    80005bc4:	2ca080e7          	jalr	714(ra) # 80002e8a <argstr>
    80005bc8:	04054a63          	bltz	a0,80005c1c <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005bcc:	f6c40593          	addi	a1,s0,-148
    80005bd0:	4505                	li	a0,1
    80005bd2:	ffffd097          	auipc	ra,0xffffd
    80005bd6:	274080e7          	jalr	628(ra) # 80002e46 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005bda:	04054163          	bltz	a0,80005c1c <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005bde:	f6840593          	addi	a1,s0,-152
    80005be2:	4509                	li	a0,2
    80005be4:	ffffd097          	auipc	ra,0xffffd
    80005be8:	262080e7          	jalr	610(ra) # 80002e46 <argint>
     argint(1, &major) < 0 ||
    80005bec:	02054863          	bltz	a0,80005c1c <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005bf0:	f6841683          	lh	a3,-152(s0)
    80005bf4:	f6c41603          	lh	a2,-148(s0)
    80005bf8:	458d                	li	a1,3
    80005bfa:	f7040513          	addi	a0,s0,-144
    80005bfe:	fffff097          	auipc	ra,0xfffff
    80005c02:	776080e7          	jalr	1910(ra) # 80005374 <create>
     argint(2, &minor) < 0 ||
    80005c06:	c919                	beqz	a0,80005c1c <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c08:	ffffe097          	auipc	ra,0xffffe
    80005c0c:	012080e7          	jalr	18(ra) # 80003c1a <iunlockput>
  end_op();
    80005c10:	ffffe097          	auipc	ra,0xffffe
    80005c14:	7e4080e7          	jalr	2020(ra) # 800043f4 <end_op>
  return 0;
    80005c18:	4501                	li	a0,0
    80005c1a:	a031                	j	80005c26 <sys_mknod+0x80>
    end_op();
    80005c1c:	ffffe097          	auipc	ra,0xffffe
    80005c20:	7d8080e7          	jalr	2008(ra) # 800043f4 <end_op>
    return -1;
    80005c24:	557d                	li	a0,-1
}
    80005c26:	60ea                	ld	ra,152(sp)
    80005c28:	644a                	ld	s0,144(sp)
    80005c2a:	610d                	addi	sp,sp,160
    80005c2c:	8082                	ret

0000000080005c2e <sys_chdir>:

uint64
sys_chdir(void)
{
    80005c2e:	7135                	addi	sp,sp,-160
    80005c30:	ed06                	sd	ra,152(sp)
    80005c32:	e922                	sd	s0,144(sp)
    80005c34:	e526                	sd	s1,136(sp)
    80005c36:	e14a                	sd	s2,128(sp)
    80005c38:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005c3a:	ffffc097          	auipc	ra,0xffffc
    80005c3e:	f7a080e7          	jalr	-134(ra) # 80001bb4 <myproc>
    80005c42:	892a                	mv	s2,a0
  
  begin_op();
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	730080e7          	jalr	1840(ra) # 80004374 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005c4c:	08000613          	li	a2,128
    80005c50:	f6040593          	addi	a1,s0,-160
    80005c54:	4501                	li	a0,0
    80005c56:	ffffd097          	auipc	ra,0xffffd
    80005c5a:	234080e7          	jalr	564(ra) # 80002e8a <argstr>
    80005c5e:	04054b63          	bltz	a0,80005cb4 <sys_chdir+0x86>
    80005c62:	f6040513          	addi	a0,s0,-160
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	502080e7          	jalr	1282(ra) # 80004168 <namei>
    80005c6e:	84aa                	mv	s1,a0
    80005c70:	c131                	beqz	a0,80005cb4 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c72:	ffffe097          	auipc	ra,0xffffe
    80005c76:	d46080e7          	jalr	-698(ra) # 800039b8 <ilock>
  if(ip->type != T_DIR){
    80005c7a:	04449703          	lh	a4,68(s1)
    80005c7e:	4785                	li	a5,1
    80005c80:	04f71063          	bne	a4,a5,80005cc0 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c84:	8526                	mv	a0,s1
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	df4080e7          	jalr	-524(ra) # 80003a7a <iunlock>
  iput(p->cwd);
    80005c8e:	15893503          	ld	a0,344(s2)
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	ee0080e7          	jalr	-288(ra) # 80003b72 <iput>
  end_op();
    80005c9a:	ffffe097          	auipc	ra,0xffffe
    80005c9e:	75a080e7          	jalr	1882(ra) # 800043f4 <end_op>
  p->cwd = ip;
    80005ca2:	14993c23          	sd	s1,344(s2)
  return 0;
    80005ca6:	4501                	li	a0,0
}
    80005ca8:	60ea                	ld	ra,152(sp)
    80005caa:	644a                	ld	s0,144(sp)
    80005cac:	64aa                	ld	s1,136(sp)
    80005cae:	690a                	ld	s2,128(sp)
    80005cb0:	610d                	addi	sp,sp,160
    80005cb2:	8082                	ret
    end_op();
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	740080e7          	jalr	1856(ra) # 800043f4 <end_op>
    return -1;
    80005cbc:	557d                	li	a0,-1
    80005cbe:	b7ed                	j	80005ca8 <sys_chdir+0x7a>
    iunlockput(ip);
    80005cc0:	8526                	mv	a0,s1
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	f58080e7          	jalr	-168(ra) # 80003c1a <iunlockput>
    end_op();
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	72a080e7          	jalr	1834(ra) # 800043f4 <end_op>
    return -1;
    80005cd2:	557d                	li	a0,-1
    80005cd4:	bfd1                	j	80005ca8 <sys_chdir+0x7a>

0000000080005cd6 <sys_exec>:

uint64
sys_exec(void)
{
    80005cd6:	7145                	addi	sp,sp,-464
    80005cd8:	e786                	sd	ra,456(sp)
    80005cda:	e3a2                	sd	s0,448(sp)
    80005cdc:	ff26                	sd	s1,440(sp)
    80005cde:	fb4a                	sd	s2,432(sp)
    80005ce0:	f74e                	sd	s3,424(sp)
    80005ce2:	f352                	sd	s4,416(sp)
    80005ce4:	ef56                	sd	s5,408(sp)
    80005ce6:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005ce8:	08000613          	li	a2,128
    80005cec:	f4040593          	addi	a1,s0,-192
    80005cf0:	4501                	li	a0,0
    80005cf2:	ffffd097          	auipc	ra,0xffffd
    80005cf6:	198080e7          	jalr	408(ra) # 80002e8a <argstr>
    return -1;
    80005cfa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005cfc:	0c054a63          	bltz	a0,80005dd0 <sys_exec+0xfa>
    80005d00:	e3840593          	addi	a1,s0,-456
    80005d04:	4505                	li	a0,1
    80005d06:	ffffd097          	auipc	ra,0xffffd
    80005d0a:	162080e7          	jalr	354(ra) # 80002e68 <argaddr>
    80005d0e:	0c054163          	bltz	a0,80005dd0 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005d12:	10000613          	li	a2,256
    80005d16:	4581                	li	a1,0
    80005d18:	e4040513          	addi	a0,s0,-448
    80005d1c:	ffffb097          	auipc	ra,0xffffb
    80005d20:	ff0080e7          	jalr	-16(ra) # 80000d0c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005d24:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005d28:	89a6                	mv	s3,s1
    80005d2a:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005d2c:	02000a13          	li	s4,32
    80005d30:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005d34:	00391513          	slli	a0,s2,0x3
    80005d38:	e3040593          	addi	a1,s0,-464
    80005d3c:	e3843783          	ld	a5,-456(s0)
    80005d40:	953e                	add	a0,a0,a5
    80005d42:	ffffd097          	auipc	ra,0xffffd
    80005d46:	06a080e7          	jalr	106(ra) # 80002dac <fetchaddr>
    80005d4a:	02054a63          	bltz	a0,80005d7e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005d4e:	e3043783          	ld	a5,-464(s0)
    80005d52:	c3b9                	beqz	a5,80005d98 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005d54:	ffffb097          	auipc	ra,0xffffb
    80005d58:	dcc080e7          	jalr	-564(ra) # 80000b20 <kalloc>
    80005d5c:	85aa                	mv	a1,a0
    80005d5e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005d62:	cd11                	beqz	a0,80005d7e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005d64:	6605                	lui	a2,0x1
    80005d66:	e3043503          	ld	a0,-464(s0)
    80005d6a:	ffffd097          	auipc	ra,0xffffd
    80005d6e:	094080e7          	jalr	148(ra) # 80002dfe <fetchstr>
    80005d72:	00054663          	bltz	a0,80005d7e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005d76:	0905                	addi	s2,s2,1
    80005d78:	09a1                	addi	s3,s3,8
    80005d7a:	fb491be3          	bne	s2,s4,80005d30 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d7e:	10048913          	addi	s2,s1,256
    80005d82:	6088                	ld	a0,0(s1)
    80005d84:	c529                	beqz	a0,80005dce <sys_exec+0xf8>
    kfree(argv[i]);
    80005d86:	ffffb097          	auipc	ra,0xffffb
    80005d8a:	c9e080e7          	jalr	-866(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d8e:	04a1                	addi	s1,s1,8
    80005d90:	ff2499e3          	bne	s1,s2,80005d82 <sys_exec+0xac>
  return -1;
    80005d94:	597d                	li	s2,-1
    80005d96:	a82d                	j	80005dd0 <sys_exec+0xfa>
      argv[i] = 0;
    80005d98:	0a8e                	slli	s5,s5,0x3
    80005d9a:	fc040793          	addi	a5,s0,-64
    80005d9e:	9abe                	add	s5,s5,a5
    80005da0:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005da4:	e4040593          	addi	a1,s0,-448
    80005da8:	f4040513          	addi	a0,s0,-192
    80005dac:	fffff097          	auipc	ra,0xfffff
    80005db0:	14a080e7          	jalr	330(ra) # 80004ef6 <exec>
    80005db4:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005db6:	10048993          	addi	s3,s1,256
    80005dba:	6088                	ld	a0,0(s1)
    80005dbc:	c911                	beqz	a0,80005dd0 <sys_exec+0xfa>
    kfree(argv[i]);
    80005dbe:	ffffb097          	auipc	ra,0xffffb
    80005dc2:	c66080e7          	jalr	-922(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005dc6:	04a1                	addi	s1,s1,8
    80005dc8:	ff3499e3          	bne	s1,s3,80005dba <sys_exec+0xe4>
    80005dcc:	a011                	j	80005dd0 <sys_exec+0xfa>
  return -1;
    80005dce:	597d                	li	s2,-1
}
    80005dd0:	854a                	mv	a0,s2
    80005dd2:	60be                	ld	ra,456(sp)
    80005dd4:	641e                	ld	s0,448(sp)
    80005dd6:	74fa                	ld	s1,440(sp)
    80005dd8:	795a                	ld	s2,432(sp)
    80005dda:	79ba                	ld	s3,424(sp)
    80005ddc:	7a1a                	ld	s4,416(sp)
    80005dde:	6afa                	ld	s5,408(sp)
    80005de0:	6179                	addi	sp,sp,464
    80005de2:	8082                	ret

0000000080005de4 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005de4:	7139                	addi	sp,sp,-64
    80005de6:	fc06                	sd	ra,56(sp)
    80005de8:	f822                	sd	s0,48(sp)
    80005dea:	f426                	sd	s1,40(sp)
    80005dec:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005dee:	ffffc097          	auipc	ra,0xffffc
    80005df2:	dc6080e7          	jalr	-570(ra) # 80001bb4 <myproc>
    80005df6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005df8:	fd840593          	addi	a1,s0,-40
    80005dfc:	4501                	li	a0,0
    80005dfe:	ffffd097          	auipc	ra,0xffffd
    80005e02:	06a080e7          	jalr	106(ra) # 80002e68 <argaddr>
    return -1;
    80005e06:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005e08:	0e054063          	bltz	a0,80005ee8 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005e0c:	fc840593          	addi	a1,s0,-56
    80005e10:	fd040513          	addi	a0,s0,-48
    80005e14:	fffff097          	auipc	ra,0xfffff
    80005e18:	d88080e7          	jalr	-632(ra) # 80004b9c <pipealloc>
    return -1;
    80005e1c:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005e1e:	0c054563          	bltz	a0,80005ee8 <sys_pipe+0x104>
  fd0 = -1;
    80005e22:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005e26:	fd043503          	ld	a0,-48(s0)
    80005e2a:	fffff097          	auipc	ra,0xfffff
    80005e2e:	508080e7          	jalr	1288(ra) # 80005332 <fdalloc>
    80005e32:	fca42223          	sw	a0,-60(s0)
    80005e36:	08054c63          	bltz	a0,80005ece <sys_pipe+0xea>
    80005e3a:	fc843503          	ld	a0,-56(s0)
    80005e3e:	fffff097          	auipc	ra,0xfffff
    80005e42:	4f4080e7          	jalr	1268(ra) # 80005332 <fdalloc>
    80005e46:	fca42023          	sw	a0,-64(s0)
    80005e4a:	06054863          	bltz	a0,80005eba <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e4e:	4691                	li	a3,4
    80005e50:	fc440613          	addi	a2,s0,-60
    80005e54:	fd843583          	ld	a1,-40(s0)
    80005e58:	68a8                	ld	a0,80(s1)
    80005e5a:	ffffc097          	auipc	ra,0xffffc
    80005e5e:	ad2080e7          	jalr	-1326(ra) # 8000192c <copyout>
    80005e62:	02054063          	bltz	a0,80005e82 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005e66:	4691                	li	a3,4
    80005e68:	fc040613          	addi	a2,s0,-64
    80005e6c:	fd843583          	ld	a1,-40(s0)
    80005e70:	0591                	addi	a1,a1,4
    80005e72:	68a8                	ld	a0,80(s1)
    80005e74:	ffffc097          	auipc	ra,0xffffc
    80005e78:	ab8080e7          	jalr	-1352(ra) # 8000192c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e7c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e7e:	06055563          	bgez	a0,80005ee8 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005e82:	fc442783          	lw	a5,-60(s0)
    80005e86:	07e9                	addi	a5,a5,26
    80005e88:	078e                	slli	a5,a5,0x3
    80005e8a:	97a6                	add	a5,a5,s1
    80005e8c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e90:	fc042503          	lw	a0,-64(s0)
    80005e94:	0569                	addi	a0,a0,26
    80005e96:	050e                	slli	a0,a0,0x3
    80005e98:	9526                	add	a0,a0,s1
    80005e9a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005e9e:	fd043503          	ld	a0,-48(s0)
    80005ea2:	fffff097          	auipc	ra,0xfffff
    80005ea6:	9a4080e7          	jalr	-1628(ra) # 80004846 <fileclose>
    fileclose(wf);
    80005eaa:	fc843503          	ld	a0,-56(s0)
    80005eae:	fffff097          	auipc	ra,0xfffff
    80005eb2:	998080e7          	jalr	-1640(ra) # 80004846 <fileclose>
    return -1;
    80005eb6:	57fd                	li	a5,-1
    80005eb8:	a805                	j	80005ee8 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005eba:	fc442783          	lw	a5,-60(s0)
    80005ebe:	0007c863          	bltz	a5,80005ece <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005ec2:	01a78513          	addi	a0,a5,26
    80005ec6:	050e                	slli	a0,a0,0x3
    80005ec8:	9526                	add	a0,a0,s1
    80005eca:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    80005ece:	fd043503          	ld	a0,-48(s0)
    80005ed2:	fffff097          	auipc	ra,0xfffff
    80005ed6:	974080e7          	jalr	-1676(ra) # 80004846 <fileclose>
    fileclose(wf);
    80005eda:	fc843503          	ld	a0,-56(s0)
    80005ede:	fffff097          	auipc	ra,0xfffff
    80005ee2:	968080e7          	jalr	-1688(ra) # 80004846 <fileclose>
    return -1;
    80005ee6:	57fd                	li	a5,-1
}
    80005ee8:	853e                	mv	a0,a5
    80005eea:	70e2                	ld	ra,56(sp)
    80005eec:	7442                	ld	s0,48(sp)
    80005eee:	74a2                	ld	s1,40(sp)
    80005ef0:	6121                	addi	sp,sp,64
    80005ef2:	8082                	ret
	...

0000000080005f00 <kernelvec>:
    80005f00:	7111                	addi	sp,sp,-256
    80005f02:	e006                	sd	ra,0(sp)
    80005f04:	e40a                	sd	sp,8(sp)
    80005f06:	e80e                	sd	gp,16(sp)
    80005f08:	ec12                	sd	tp,24(sp)
    80005f0a:	f016                	sd	t0,32(sp)
    80005f0c:	f41a                	sd	t1,40(sp)
    80005f0e:	f81e                	sd	t2,48(sp)
    80005f10:	fc22                	sd	s0,56(sp)
    80005f12:	e0a6                	sd	s1,64(sp)
    80005f14:	e4aa                	sd	a0,72(sp)
    80005f16:	e8ae                	sd	a1,80(sp)
    80005f18:	ecb2                	sd	a2,88(sp)
    80005f1a:	f0b6                	sd	a3,96(sp)
    80005f1c:	f4ba                	sd	a4,104(sp)
    80005f1e:	f8be                	sd	a5,112(sp)
    80005f20:	fcc2                	sd	a6,120(sp)
    80005f22:	e146                	sd	a7,128(sp)
    80005f24:	e54a                	sd	s2,136(sp)
    80005f26:	e94e                	sd	s3,144(sp)
    80005f28:	ed52                	sd	s4,152(sp)
    80005f2a:	f156                	sd	s5,160(sp)
    80005f2c:	f55a                	sd	s6,168(sp)
    80005f2e:	f95e                	sd	s7,176(sp)
    80005f30:	fd62                	sd	s8,184(sp)
    80005f32:	e1e6                	sd	s9,192(sp)
    80005f34:	e5ea                	sd	s10,200(sp)
    80005f36:	e9ee                	sd	s11,208(sp)
    80005f38:	edf2                	sd	t3,216(sp)
    80005f3a:	f1f6                	sd	t4,224(sp)
    80005f3c:	f5fa                	sd	t5,232(sp)
    80005f3e:	f9fe                	sd	t6,240(sp)
    80005f40:	d39fc0ef          	jal	ra,80002c78 <kerneltrap>
    80005f44:	6082                	ld	ra,0(sp)
    80005f46:	6122                	ld	sp,8(sp)
    80005f48:	61c2                	ld	gp,16(sp)
    80005f4a:	7282                	ld	t0,32(sp)
    80005f4c:	7322                	ld	t1,40(sp)
    80005f4e:	73c2                	ld	t2,48(sp)
    80005f50:	7462                	ld	s0,56(sp)
    80005f52:	6486                	ld	s1,64(sp)
    80005f54:	6526                	ld	a0,72(sp)
    80005f56:	65c6                	ld	a1,80(sp)
    80005f58:	6666                	ld	a2,88(sp)
    80005f5a:	7686                	ld	a3,96(sp)
    80005f5c:	7726                	ld	a4,104(sp)
    80005f5e:	77c6                	ld	a5,112(sp)
    80005f60:	7866                	ld	a6,120(sp)
    80005f62:	688a                	ld	a7,128(sp)
    80005f64:	692a                	ld	s2,136(sp)
    80005f66:	69ca                	ld	s3,144(sp)
    80005f68:	6a6a                	ld	s4,152(sp)
    80005f6a:	7a8a                	ld	s5,160(sp)
    80005f6c:	7b2a                	ld	s6,168(sp)
    80005f6e:	7bca                	ld	s7,176(sp)
    80005f70:	7c6a                	ld	s8,184(sp)
    80005f72:	6c8e                	ld	s9,192(sp)
    80005f74:	6d2e                	ld	s10,200(sp)
    80005f76:	6dce                	ld	s11,208(sp)
    80005f78:	6e6e                	ld	t3,216(sp)
    80005f7a:	7e8e                	ld	t4,224(sp)
    80005f7c:	7f2e                	ld	t5,232(sp)
    80005f7e:	7fce                	ld	t6,240(sp)
    80005f80:	6111                	addi	sp,sp,256
    80005f82:	10200073          	sret
    80005f86:	00000013          	nop
    80005f8a:	00000013          	nop
    80005f8e:	0001                	nop

0000000080005f90 <timervec>:
    80005f90:	34051573          	csrrw	a0,mscratch,a0
    80005f94:	e10c                	sd	a1,0(a0)
    80005f96:	e510                	sd	a2,8(a0)
    80005f98:	e914                	sd	a3,16(a0)
    80005f9a:	710c                	ld	a1,32(a0)
    80005f9c:	7510                	ld	a2,40(a0)
    80005f9e:	6194                	ld	a3,0(a1)
    80005fa0:	96b2                	add	a3,a3,a2
    80005fa2:	e194                	sd	a3,0(a1)
    80005fa4:	4589                	li	a1,2
    80005fa6:	14459073          	csrw	sip,a1
    80005faa:	6914                	ld	a3,16(a0)
    80005fac:	6510                	ld	a2,8(a0)
    80005fae:	610c                	ld	a1,0(a0)
    80005fb0:	34051573          	csrrw	a0,mscratch,a0
    80005fb4:	30200073          	mret
	...

0000000080005fba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005fba:	1141                	addi	sp,sp,-16
    80005fbc:	e422                	sd	s0,8(sp)
    80005fbe:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005fc0:	0c0007b7          	lui	a5,0xc000
    80005fc4:	4705                	li	a4,1
    80005fc6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005fc8:	c3d8                	sw	a4,4(a5)
}
    80005fca:	6422                	ld	s0,8(sp)
    80005fcc:	0141                	addi	sp,sp,16
    80005fce:	8082                	ret

0000000080005fd0 <plicinithart>:

void
plicinithart(void)
{
    80005fd0:	1141                	addi	sp,sp,-16
    80005fd2:	e406                	sd	ra,8(sp)
    80005fd4:	e022                	sd	s0,0(sp)
    80005fd6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fd8:	ffffc097          	auipc	ra,0xffffc
    80005fdc:	bb0080e7          	jalr	-1104(ra) # 80001b88 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005fe0:	0085171b          	slliw	a4,a0,0x8
    80005fe4:	0c0027b7          	lui	a5,0xc002
    80005fe8:	97ba                	add	a5,a5,a4
    80005fea:	40200713          	li	a4,1026
    80005fee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005ff2:	00d5151b          	slliw	a0,a0,0xd
    80005ff6:	0c2017b7          	lui	a5,0xc201
    80005ffa:	953e                	add	a0,a0,a5
    80005ffc:	00052023          	sw	zero,0(a0)
}
    80006000:	60a2                	ld	ra,8(sp)
    80006002:	6402                	ld	s0,0(sp)
    80006004:	0141                	addi	sp,sp,16
    80006006:	8082                	ret

0000000080006008 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006008:	1141                	addi	sp,sp,-16
    8000600a:	e406                	sd	ra,8(sp)
    8000600c:	e022                	sd	s0,0(sp)
    8000600e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006010:	ffffc097          	auipc	ra,0xffffc
    80006014:	b78080e7          	jalr	-1160(ra) # 80001b88 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006018:	00d5179b          	slliw	a5,a0,0xd
    8000601c:	0c201537          	lui	a0,0xc201
    80006020:	953e                	add	a0,a0,a5
  return irq;
}
    80006022:	4148                	lw	a0,4(a0)
    80006024:	60a2                	ld	ra,8(sp)
    80006026:	6402                	ld	s0,0(sp)
    80006028:	0141                	addi	sp,sp,16
    8000602a:	8082                	ret

000000008000602c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000602c:	1101                	addi	sp,sp,-32
    8000602e:	ec06                	sd	ra,24(sp)
    80006030:	e822                	sd	s0,16(sp)
    80006032:	e426                	sd	s1,8(sp)
    80006034:	1000                	addi	s0,sp,32
    80006036:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	b50080e7          	jalr	-1200(ra) # 80001b88 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006040:	00d5151b          	slliw	a0,a0,0xd
    80006044:	0c2017b7          	lui	a5,0xc201
    80006048:	97aa                	add	a5,a5,a0
    8000604a:	c3c4                	sw	s1,4(a5)
}
    8000604c:	60e2                	ld	ra,24(sp)
    8000604e:	6442                	ld	s0,16(sp)
    80006050:	64a2                	ld	s1,8(sp)
    80006052:	6105                	addi	sp,sp,32
    80006054:	8082                	ret

0000000080006056 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006056:	1141                	addi	sp,sp,-16
    80006058:	e406                	sd	ra,8(sp)
    8000605a:	e022                	sd	s0,0(sp)
    8000605c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000605e:	479d                	li	a5,7
    80006060:	04a7cc63          	blt	a5,a0,800060b8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80006064:	0001d797          	auipc	a5,0x1d
    80006068:	f9c78793          	addi	a5,a5,-100 # 80023000 <disk>
    8000606c:	00a78733          	add	a4,a5,a0
    80006070:	6789                	lui	a5,0x2
    80006072:	97ba                	add	a5,a5,a4
    80006074:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006078:	eba1                	bnez	a5,800060c8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    8000607a:	00451713          	slli	a4,a0,0x4
    8000607e:	0001f797          	auipc	a5,0x1f
    80006082:	f827b783          	ld	a5,-126(a5) # 80025000 <disk+0x2000>
    80006086:	97ba                	add	a5,a5,a4
    80006088:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    8000608c:	0001d797          	auipc	a5,0x1d
    80006090:	f7478793          	addi	a5,a5,-140 # 80023000 <disk>
    80006094:	97aa                	add	a5,a5,a0
    80006096:	6509                	lui	a0,0x2
    80006098:	953e                	add	a0,a0,a5
    8000609a:	4785                	li	a5,1
    8000609c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800060a0:	0001f517          	auipc	a0,0x1f
    800060a4:	f7850513          	addi	a0,a0,-136 # 80025018 <disk+0x2018>
    800060a8:	ffffc097          	auipc	ra,0xffffc
    800060ac:	676080e7          	jalr	1654(ra) # 8000271e <wakeup>
}
    800060b0:	60a2                	ld	ra,8(sp)
    800060b2:	6402                	ld	s0,0(sp)
    800060b4:	0141                	addi	sp,sp,16
    800060b6:	8082                	ret
    panic("virtio_disk_intr 1");
    800060b8:	00002517          	auipc	a0,0x2
    800060bc:	6e050513          	addi	a0,a0,1760 # 80008798 <syscalls+0x328>
    800060c0:	ffffa097          	auipc	ra,0xffffa
    800060c4:	488080e7          	jalr	1160(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    800060c8:	00002517          	auipc	a0,0x2
    800060cc:	6e850513          	addi	a0,a0,1768 # 800087b0 <syscalls+0x340>
    800060d0:	ffffa097          	auipc	ra,0xffffa
    800060d4:	478080e7          	jalr	1144(ra) # 80000548 <panic>

00000000800060d8 <virtio_disk_init>:
{
    800060d8:	1101                	addi	sp,sp,-32
    800060da:	ec06                	sd	ra,24(sp)
    800060dc:	e822                	sd	s0,16(sp)
    800060de:	e426                	sd	s1,8(sp)
    800060e0:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800060e2:	00002597          	auipc	a1,0x2
    800060e6:	6e658593          	addi	a1,a1,1766 # 800087c8 <syscalls+0x358>
    800060ea:	0001f517          	auipc	a0,0x1f
    800060ee:	fbe50513          	addi	a0,a0,-66 # 800250a8 <disk+0x20a8>
    800060f2:	ffffb097          	auipc	ra,0xffffb
    800060f6:	a8e080e7          	jalr	-1394(ra) # 80000b80 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060fa:	100017b7          	lui	a5,0x10001
    800060fe:	4398                	lw	a4,0(a5)
    80006100:	2701                	sext.w	a4,a4
    80006102:	747277b7          	lui	a5,0x74727
    80006106:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000610a:	0ef71163          	bne	a4,a5,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000610e:	100017b7          	lui	a5,0x10001
    80006112:	43dc                	lw	a5,4(a5)
    80006114:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006116:	4705                	li	a4,1
    80006118:	0ce79a63          	bne	a5,a4,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000611c:	100017b7          	lui	a5,0x10001
    80006120:	479c                	lw	a5,8(a5)
    80006122:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006124:	4709                	li	a4,2
    80006126:	0ce79363          	bne	a5,a4,800061ec <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000612a:	100017b7          	lui	a5,0x10001
    8000612e:	47d8                	lw	a4,12(a5)
    80006130:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006132:	554d47b7          	lui	a5,0x554d4
    80006136:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000613a:	0af71963          	bne	a4,a5,800061ec <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000613e:	100017b7          	lui	a5,0x10001
    80006142:	4705                	li	a4,1
    80006144:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006146:	470d                	li	a4,3
    80006148:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000614a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    8000614c:	c7ffe737          	lui	a4,0xc7ffe
    80006150:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd773f>
    80006154:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006156:	2701                	sext.w	a4,a4
    80006158:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615a:	472d                	li	a4,11
    8000615c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000615e:	473d                	li	a4,15
    80006160:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80006162:	6705                	lui	a4,0x1
    80006164:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006166:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000616a:	5bdc                	lw	a5,52(a5)
    8000616c:	2781                	sext.w	a5,a5
  if(max == 0)
    8000616e:	c7d9                	beqz	a5,800061fc <virtio_disk_init+0x124>
  if(max < NUM)
    80006170:	471d                	li	a4,7
    80006172:	08f77d63          	bgeu	a4,a5,8000620c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006176:	100014b7          	lui	s1,0x10001
    8000617a:	47a1                	li	a5,8
    8000617c:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    8000617e:	6609                	lui	a2,0x2
    80006180:	4581                	li	a1,0
    80006182:	0001d517          	auipc	a0,0x1d
    80006186:	e7e50513          	addi	a0,a0,-386 # 80023000 <disk>
    8000618a:	ffffb097          	auipc	ra,0xffffb
    8000618e:	b82080e7          	jalr	-1150(ra) # 80000d0c <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80006192:	0001d717          	auipc	a4,0x1d
    80006196:	e6e70713          	addi	a4,a4,-402 # 80023000 <disk>
    8000619a:	00c75793          	srli	a5,a4,0xc
    8000619e:	2781                	sext.w	a5,a5
    800061a0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    800061a2:	0001f797          	auipc	a5,0x1f
    800061a6:	e5e78793          	addi	a5,a5,-418 # 80025000 <disk+0x2000>
    800061aa:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    800061ac:	0001d717          	auipc	a4,0x1d
    800061b0:	ed470713          	addi	a4,a4,-300 # 80023080 <disk+0x80>
    800061b4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    800061b6:	0001e717          	auipc	a4,0x1e
    800061ba:	e4a70713          	addi	a4,a4,-438 # 80024000 <disk+0x1000>
    800061be:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800061c0:	4705                	li	a4,1
    800061c2:	00e78c23          	sb	a4,24(a5)
    800061c6:	00e78ca3          	sb	a4,25(a5)
    800061ca:	00e78d23          	sb	a4,26(a5)
    800061ce:	00e78da3          	sb	a4,27(a5)
    800061d2:	00e78e23          	sb	a4,28(a5)
    800061d6:	00e78ea3          	sb	a4,29(a5)
    800061da:	00e78f23          	sb	a4,30(a5)
    800061de:	00e78fa3          	sb	a4,31(a5)
}
    800061e2:	60e2                	ld	ra,24(sp)
    800061e4:	6442                	ld	s0,16(sp)
    800061e6:	64a2                	ld	s1,8(sp)
    800061e8:	6105                	addi	sp,sp,32
    800061ea:	8082                	ret
    panic("could not find virtio disk");
    800061ec:	00002517          	auipc	a0,0x2
    800061f0:	5ec50513          	addi	a0,a0,1516 # 800087d8 <syscalls+0x368>
    800061f4:	ffffa097          	auipc	ra,0xffffa
    800061f8:	354080e7          	jalr	852(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    800061fc:	00002517          	auipc	a0,0x2
    80006200:	5fc50513          	addi	a0,a0,1532 # 800087f8 <syscalls+0x388>
    80006204:	ffffa097          	auipc	ra,0xffffa
    80006208:	344080e7          	jalr	836(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    8000620c:	00002517          	auipc	a0,0x2
    80006210:	60c50513          	addi	a0,a0,1548 # 80008818 <syscalls+0x3a8>
    80006214:	ffffa097          	auipc	ra,0xffffa
    80006218:	334080e7          	jalr	820(ra) # 80000548 <panic>

000000008000621c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    8000621c:	7119                	addi	sp,sp,-128
    8000621e:	fc86                	sd	ra,120(sp)
    80006220:	f8a2                	sd	s0,112(sp)
    80006222:	f4a6                	sd	s1,104(sp)
    80006224:	f0ca                	sd	s2,96(sp)
    80006226:	ecce                	sd	s3,88(sp)
    80006228:	e8d2                	sd	s4,80(sp)
    8000622a:	e4d6                	sd	s5,72(sp)
    8000622c:	e0da                	sd	s6,64(sp)
    8000622e:	fc5e                	sd	s7,56(sp)
    80006230:	f862                	sd	s8,48(sp)
    80006232:	f466                	sd	s9,40(sp)
    80006234:	f06a                	sd	s10,32(sp)
    80006236:	0100                	addi	s0,sp,128
    80006238:	892a                	mv	s2,a0
    8000623a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    8000623c:	00c52c83          	lw	s9,12(a0)
    80006240:	001c9c9b          	slliw	s9,s9,0x1
    80006244:	1c82                	slli	s9,s9,0x20
    80006246:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    8000624a:	0001f517          	auipc	a0,0x1f
    8000624e:	e5e50513          	addi	a0,a0,-418 # 800250a8 <disk+0x20a8>
    80006252:	ffffb097          	auipc	ra,0xffffb
    80006256:	9be080e7          	jalr	-1602(ra) # 80000c10 <acquire>
  for(int i = 0; i < 3; i++){
    8000625a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    8000625c:	4c21                	li	s8,8
      disk.free[i] = 0;
    8000625e:	0001db97          	auipc	s7,0x1d
    80006262:	da2b8b93          	addi	s7,s7,-606 # 80023000 <disk>
    80006266:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006268:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    8000626a:	8a4e                	mv	s4,s3
    8000626c:	a051                	j	800062f0 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    8000626e:	00fb86b3          	add	a3,s7,a5
    80006272:	96da                	add	a3,a3,s6
    80006274:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006278:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    8000627a:	0207c563          	bltz	a5,800062a4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    8000627e:	2485                	addiw	s1,s1,1
    80006280:	0711                	addi	a4,a4,4
    80006282:	23548d63          	beq	s1,s5,800064bc <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80006286:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006288:	0001f697          	auipc	a3,0x1f
    8000628c:	d9068693          	addi	a3,a3,-624 # 80025018 <disk+0x2018>
    80006290:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006292:	0006c583          	lbu	a1,0(a3)
    80006296:	fde1                	bnez	a1,8000626e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006298:	2785                	addiw	a5,a5,1
    8000629a:	0685                	addi	a3,a3,1
    8000629c:	ff879be3          	bne	a5,s8,80006292 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800062a0:	57fd                	li	a5,-1
    800062a2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800062a4:	02905a63          	blez	s1,800062d8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062a8:	f9042503          	lw	a0,-112(s0)
    800062ac:	00000097          	auipc	ra,0x0
    800062b0:	daa080e7          	jalr	-598(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062b4:	4785                	li	a5,1
    800062b6:	0297d163          	bge	a5,s1,800062d8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062ba:	f9442503          	lw	a0,-108(s0)
    800062be:	00000097          	auipc	ra,0x0
    800062c2:	d98080e7          	jalr	-616(ra) # 80006056 <free_desc>
      for(int j = 0; j < i; j++)
    800062c6:	4789                	li	a5,2
    800062c8:	0097d863          	bge	a5,s1,800062d8 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800062cc:	f9842503          	lw	a0,-104(s0)
    800062d0:	00000097          	auipc	ra,0x0
    800062d4:	d86080e7          	jalr	-634(ra) # 80006056 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062d8:	0001f597          	auipc	a1,0x1f
    800062dc:	dd058593          	addi	a1,a1,-560 # 800250a8 <disk+0x20a8>
    800062e0:	0001f517          	auipc	a0,0x1f
    800062e4:	d3850513          	addi	a0,a0,-712 # 80025018 <disk+0x2018>
    800062e8:	ffffc097          	auipc	ra,0xffffc
    800062ec:	2b0080e7          	jalr	688(ra) # 80002598 <sleep>
  for(int i = 0; i < 3; i++){
    800062f0:	f9040713          	addi	a4,s0,-112
    800062f4:	84ce                	mv	s1,s3
    800062f6:	bf41                	j	80006286 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    800062f8:	4785                	li	a5,1
    800062fa:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    800062fe:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006302:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006306:	f9042983          	lw	s3,-112(s0)
    8000630a:	00499493          	slli	s1,s3,0x4
    8000630e:	0001fa17          	auipc	s4,0x1f
    80006312:	cf2a0a13          	addi	s4,s4,-782 # 80025000 <disk+0x2000>
    80006316:	000a3a83          	ld	s5,0(s4)
    8000631a:	9aa6                	add	s5,s5,s1
    8000631c:	f8040513          	addi	a0,s0,-128
    80006320:	ffffb097          	auipc	ra,0xffffb
    80006324:	e64080e7          	jalr	-412(ra) # 80001184 <kvmpa>
    80006328:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000632c:	000a3783          	ld	a5,0(s4)
    80006330:	97a6                	add	a5,a5,s1
    80006332:	4741                	li	a4,16
    80006334:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006336:	000a3783          	ld	a5,0(s4)
    8000633a:	97a6                	add	a5,a5,s1
    8000633c:	4705                	li	a4,1
    8000633e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006342:	f9442703          	lw	a4,-108(s0)
    80006346:	000a3783          	ld	a5,0(s4)
    8000634a:	97a6                	add	a5,a5,s1
    8000634c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006350:	0712                	slli	a4,a4,0x4
    80006352:	000a3783          	ld	a5,0(s4)
    80006356:	97ba                	add	a5,a5,a4
    80006358:	05890693          	addi	a3,s2,88
    8000635c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000635e:	000a3783          	ld	a5,0(s4)
    80006362:	97ba                	add	a5,a5,a4
    80006364:	40000693          	li	a3,1024
    80006368:	c794                	sw	a3,8(a5)
  if(write)
    8000636a:	100d0a63          	beqz	s10,8000647e <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000636e:	0001f797          	auipc	a5,0x1f
    80006372:	c927b783          	ld	a5,-878(a5) # 80025000 <disk+0x2000>
    80006376:	97ba                	add	a5,a5,a4
    80006378:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000637c:	0001d517          	auipc	a0,0x1d
    80006380:	c8450513          	addi	a0,a0,-892 # 80023000 <disk>
    80006384:	0001f797          	auipc	a5,0x1f
    80006388:	c7c78793          	addi	a5,a5,-900 # 80025000 <disk+0x2000>
    8000638c:	6394                	ld	a3,0(a5)
    8000638e:	96ba                	add	a3,a3,a4
    80006390:	00c6d603          	lhu	a2,12(a3)
    80006394:	00166613          	ori	a2,a2,1
    80006398:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000639c:	f9842683          	lw	a3,-104(s0)
    800063a0:	6390                	ld	a2,0(a5)
    800063a2:	9732                	add	a4,a4,a2
    800063a4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800063a8:	20098613          	addi	a2,s3,512
    800063ac:	0612                	slli	a2,a2,0x4
    800063ae:	962a                	add	a2,a2,a0
    800063b0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800063b4:	00469713          	slli	a4,a3,0x4
    800063b8:	6394                	ld	a3,0(a5)
    800063ba:	96ba                	add	a3,a3,a4
    800063bc:	6589                	lui	a1,0x2
    800063be:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800063c2:	94ae                	add	s1,s1,a1
    800063c4:	94aa                	add	s1,s1,a0
    800063c6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800063c8:	6394                	ld	a3,0(a5)
    800063ca:	96ba                	add	a3,a3,a4
    800063cc:	4585                	li	a1,1
    800063ce:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063d0:	6394                	ld	a3,0(a5)
    800063d2:	96ba                	add	a3,a3,a4
    800063d4:	4509                	li	a0,2
    800063d6:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    800063da:	6394                	ld	a3,0(a5)
    800063dc:	9736                	add	a4,a4,a3
    800063de:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063e2:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    800063e6:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    800063ea:	6794                	ld	a3,8(a5)
    800063ec:	0026d703          	lhu	a4,2(a3)
    800063f0:	8b1d                	andi	a4,a4,7
    800063f2:	2709                	addiw	a4,a4,2
    800063f4:	0706                	slli	a4,a4,0x1
    800063f6:	9736                	add	a4,a4,a3
    800063f8:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    800063fc:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006400:	6798                	ld	a4,8(a5)
    80006402:	00275783          	lhu	a5,2(a4)
    80006406:	2785                	addiw	a5,a5,1
    80006408:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000640c:	100017b7          	lui	a5,0x10001
    80006410:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006414:	00492703          	lw	a4,4(s2)
    80006418:	4785                	li	a5,1
    8000641a:	02f71163          	bne	a4,a5,8000643c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000641e:	0001f997          	auipc	s3,0x1f
    80006422:	c8a98993          	addi	s3,s3,-886 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006426:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006428:	85ce                	mv	a1,s3
    8000642a:	854a                	mv	a0,s2
    8000642c:	ffffc097          	auipc	ra,0xffffc
    80006430:	16c080e7          	jalr	364(ra) # 80002598 <sleep>
  while(b->disk == 1) {
    80006434:	00492783          	lw	a5,4(s2)
    80006438:	fe9788e3          	beq	a5,s1,80006428 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000643c:	f9042483          	lw	s1,-112(s0)
    80006440:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006444:	00479713          	slli	a4,a5,0x4
    80006448:	0001d797          	auipc	a5,0x1d
    8000644c:	bb878793          	addi	a5,a5,-1096 # 80023000 <disk>
    80006450:	97ba                	add	a5,a5,a4
    80006452:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006456:	0001f917          	auipc	s2,0x1f
    8000645a:	baa90913          	addi	s2,s2,-1110 # 80025000 <disk+0x2000>
    free_desc(i);
    8000645e:	8526                	mv	a0,s1
    80006460:	00000097          	auipc	ra,0x0
    80006464:	bf6080e7          	jalr	-1034(ra) # 80006056 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006468:	0492                	slli	s1,s1,0x4
    8000646a:	00093783          	ld	a5,0(s2)
    8000646e:	94be                	add	s1,s1,a5
    80006470:	00c4d783          	lhu	a5,12(s1)
    80006474:	8b85                	andi	a5,a5,1
    80006476:	cf89                	beqz	a5,80006490 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    80006478:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    8000647c:	b7cd                	j	8000645e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000647e:	0001f797          	auipc	a5,0x1f
    80006482:	b827b783          	ld	a5,-1150(a5) # 80025000 <disk+0x2000>
    80006486:	97ba                	add	a5,a5,a4
    80006488:	4689                	li	a3,2
    8000648a:	00d79623          	sh	a3,12(a5)
    8000648e:	b5fd                	j	8000637c <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006490:	0001f517          	auipc	a0,0x1f
    80006494:	c1850513          	addi	a0,a0,-1000 # 800250a8 <disk+0x20a8>
    80006498:	ffffb097          	auipc	ra,0xffffb
    8000649c:	82c080e7          	jalr	-2004(ra) # 80000cc4 <release>
}
    800064a0:	70e6                	ld	ra,120(sp)
    800064a2:	7446                	ld	s0,112(sp)
    800064a4:	74a6                	ld	s1,104(sp)
    800064a6:	7906                	ld	s2,96(sp)
    800064a8:	69e6                	ld	s3,88(sp)
    800064aa:	6a46                	ld	s4,80(sp)
    800064ac:	6aa6                	ld	s5,72(sp)
    800064ae:	6b06                	ld	s6,64(sp)
    800064b0:	7be2                	ld	s7,56(sp)
    800064b2:	7c42                	ld	s8,48(sp)
    800064b4:	7ca2                	ld	s9,40(sp)
    800064b6:	7d02                	ld	s10,32(sp)
    800064b8:	6109                	addi	sp,sp,128
    800064ba:	8082                	ret
  if(write)
    800064bc:	e20d1ee3          	bnez	s10,800062f8 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800064c0:	f8042023          	sw	zero,-128(s0)
    800064c4:	bd2d                	j	800062fe <virtio_disk_rw+0xe2>

00000000800064c6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800064c6:	1101                	addi	sp,sp,-32
    800064c8:	ec06                	sd	ra,24(sp)
    800064ca:	e822                	sd	s0,16(sp)
    800064cc:	e426                	sd	s1,8(sp)
    800064ce:	e04a                	sd	s2,0(sp)
    800064d0:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800064d2:	0001f517          	auipc	a0,0x1f
    800064d6:	bd650513          	addi	a0,a0,-1066 # 800250a8 <disk+0x20a8>
    800064da:	ffffa097          	auipc	ra,0xffffa
    800064de:	736080e7          	jalr	1846(ra) # 80000c10 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800064e2:	0001f717          	auipc	a4,0x1f
    800064e6:	b1e70713          	addi	a4,a4,-1250 # 80025000 <disk+0x2000>
    800064ea:	02075783          	lhu	a5,32(a4)
    800064ee:	6b18                	ld	a4,16(a4)
    800064f0:	00275683          	lhu	a3,2(a4)
    800064f4:	8ebd                	xor	a3,a3,a5
    800064f6:	8a9d                	andi	a3,a3,7
    800064f8:	cab9                	beqz	a3,8000654e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    800064fa:	0001d917          	auipc	s2,0x1d
    800064fe:	b0690913          	addi	s2,s2,-1274 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006502:	0001f497          	auipc	s1,0x1f
    80006506:	afe48493          	addi	s1,s1,-1282 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000650a:	078e                	slli	a5,a5,0x3
    8000650c:	97ba                	add	a5,a5,a4
    8000650e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006510:	20078713          	addi	a4,a5,512
    80006514:	0712                	slli	a4,a4,0x4
    80006516:	974a                	add	a4,a4,s2
    80006518:	03074703          	lbu	a4,48(a4)
    8000651c:	ef21                	bnez	a4,80006574 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000651e:	20078793          	addi	a5,a5,512
    80006522:	0792                	slli	a5,a5,0x4
    80006524:	97ca                	add	a5,a5,s2
    80006526:	7798                	ld	a4,40(a5)
    80006528:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000652c:	7788                	ld	a0,40(a5)
    8000652e:	ffffc097          	auipc	ra,0xffffc
    80006532:	1f0080e7          	jalr	496(ra) # 8000271e <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006536:	0204d783          	lhu	a5,32(s1)
    8000653a:	2785                	addiw	a5,a5,1
    8000653c:	8b9d                	andi	a5,a5,7
    8000653e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006542:	6898                	ld	a4,16(s1)
    80006544:	00275683          	lhu	a3,2(a4)
    80006548:	8a9d                	andi	a3,a3,7
    8000654a:	fcf690e3          	bne	a3,a5,8000650a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000654e:	10001737          	lui	a4,0x10001
    80006552:	533c                	lw	a5,96(a4)
    80006554:	8b8d                	andi	a5,a5,3
    80006556:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006558:	0001f517          	auipc	a0,0x1f
    8000655c:	b5050513          	addi	a0,a0,-1200 # 800250a8 <disk+0x20a8>
    80006560:	ffffa097          	auipc	ra,0xffffa
    80006564:	764080e7          	jalr	1892(ra) # 80000cc4 <release>
}
    80006568:	60e2                	ld	ra,24(sp)
    8000656a:	6442                	ld	s0,16(sp)
    8000656c:	64a2                	ld	s1,8(sp)
    8000656e:	6902                	ld	s2,0(sp)
    80006570:	6105                	addi	sp,sp,32
    80006572:	8082                	ret
      panic("virtio_disk_intr status");
    80006574:	00002517          	auipc	a0,0x2
    80006578:	2c450513          	addi	a0,a0,708 # 80008838 <syscalls+0x3c8>
    8000657c:	ffffa097          	auipc	ra,0xffffa
    80006580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>

0000000080006584 <statscopyin>:
  int ncopyin;
  int ncopyinstr;
} stats;

int
statscopyin(char *buf, int sz) {
    80006584:	7179                	addi	sp,sp,-48
    80006586:	f406                	sd	ra,40(sp)
    80006588:	f022                	sd	s0,32(sp)
    8000658a:	ec26                	sd	s1,24(sp)
    8000658c:	e84a                	sd	s2,16(sp)
    8000658e:	e44e                	sd	s3,8(sp)
    80006590:	e052                	sd	s4,0(sp)
    80006592:	1800                	addi	s0,sp,48
    80006594:	892a                	mv	s2,a0
    80006596:	89ae                	mv	s3,a1
  int n;
  n = snprintf(buf, sz, "copyin: %d\n", stats.ncopyin);
    80006598:	00003a17          	auipc	s4,0x3
    8000659c:	a90a0a13          	addi	s4,s4,-1392 # 80009028 <stats>
    800065a0:	000a2683          	lw	a3,0(s4)
    800065a4:	00002617          	auipc	a2,0x2
    800065a8:	2ac60613          	addi	a2,a2,684 # 80008850 <syscalls+0x3e0>
    800065ac:	00000097          	auipc	ra,0x0
    800065b0:	2c2080e7          	jalr	706(ra) # 8000686e <snprintf>
    800065b4:	84aa                	mv	s1,a0
  n += snprintf(buf+n, sz, "copyinstr: %d\n", stats.ncopyinstr);
    800065b6:	004a2683          	lw	a3,4(s4)
    800065ba:	00002617          	auipc	a2,0x2
    800065be:	2a660613          	addi	a2,a2,678 # 80008860 <syscalls+0x3f0>
    800065c2:	85ce                	mv	a1,s3
    800065c4:	954a                	add	a0,a0,s2
    800065c6:	00000097          	auipc	ra,0x0
    800065ca:	2a8080e7          	jalr	680(ra) # 8000686e <snprintf>
  return n;
}
    800065ce:	9d25                	addw	a0,a0,s1
    800065d0:	70a2                	ld	ra,40(sp)
    800065d2:	7402                	ld	s0,32(sp)
    800065d4:	64e2                	ld	s1,24(sp)
    800065d6:	6942                	ld	s2,16(sp)
    800065d8:	69a2                	ld	s3,8(sp)
    800065da:	6a02                	ld	s4,0(sp)
    800065dc:	6145                	addi	sp,sp,48
    800065de:	8082                	ret

00000000800065e0 <copyin_new>:
// Copy from user to kernel.
// Copy len bytes to dst from virtual address srcva in a given page table.
// Return 0 on success, -1 on error.
int
copyin_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
    800065e0:	7179                	addi	sp,sp,-48
    800065e2:	f406                	sd	ra,40(sp)
    800065e4:	f022                	sd	s0,32(sp)
    800065e6:	ec26                	sd	s1,24(sp)
    800065e8:	e84a                	sd	s2,16(sp)
    800065ea:	e44e                	sd	s3,8(sp)
    800065ec:	1800                	addi	s0,sp,48
    800065ee:	89ae                	mv	s3,a1
    800065f0:	84b2                	mv	s1,a2
    800065f2:	8936                	mv	s2,a3
  struct proc *p = myproc();
    800065f4:	ffffb097          	auipc	ra,0xffffb
    800065f8:	5c0080e7          	jalr	1472(ra) # 80001bb4 <myproc>

  if (srcva >= p->sz || srcva+len >= p->sz || srcva+len < srcva)
    800065fc:	653c                	ld	a5,72(a0)
    800065fe:	02f4ff63          	bgeu	s1,a5,8000663c <copyin_new+0x5c>
    80006602:	01248733          	add	a4,s1,s2
    80006606:	02f77d63          	bgeu	a4,a5,80006640 <copyin_new+0x60>
    8000660a:	02976d63          	bltu	a4,s1,80006644 <copyin_new+0x64>
    return -1;
  memmove((void *) dst, (void *)srcva, len);
    8000660e:	0009061b          	sext.w	a2,s2
    80006612:	85a6                	mv	a1,s1
    80006614:	854e                	mv	a0,s3
    80006616:	ffffa097          	auipc	ra,0xffffa
    8000661a:	756080e7          	jalr	1878(ra) # 80000d6c <memmove>
  stats.ncopyin++;   // XXX lock
    8000661e:	00003717          	auipc	a4,0x3
    80006622:	a0a70713          	addi	a4,a4,-1526 # 80009028 <stats>
    80006626:	431c                	lw	a5,0(a4)
    80006628:	2785                	addiw	a5,a5,1
    8000662a:	c31c                	sw	a5,0(a4)
  return 0;
    8000662c:	4501                	li	a0,0
}
    8000662e:	70a2                	ld	ra,40(sp)
    80006630:	7402                	ld	s0,32(sp)
    80006632:	64e2                	ld	s1,24(sp)
    80006634:	6942                	ld	s2,16(sp)
    80006636:	69a2                	ld	s3,8(sp)
    80006638:	6145                	addi	sp,sp,48
    8000663a:	8082                	ret
    return -1;
    8000663c:	557d                	li	a0,-1
    8000663e:	bfc5                	j	8000662e <copyin_new+0x4e>
    80006640:	557d                	li	a0,-1
    80006642:	b7f5                	j	8000662e <copyin_new+0x4e>
    80006644:	557d                	li	a0,-1
    80006646:	b7e5                	j	8000662e <copyin_new+0x4e>

0000000080006648 <copyinstr_new>:
// Copy bytes to dst from virtual address srcva in a given page table,
// until a '\0', or max.
// Return 0 on success, -1 on error.
int
copyinstr_new(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
    80006648:	7179                	addi	sp,sp,-48
    8000664a:	f406                	sd	ra,40(sp)
    8000664c:	f022                	sd	s0,32(sp)
    8000664e:	ec26                	sd	s1,24(sp)
    80006650:	e84a                	sd	s2,16(sp)
    80006652:	e44e                	sd	s3,8(sp)
    80006654:	1800                	addi	s0,sp,48
    80006656:	89ae                	mv	s3,a1
    80006658:	8932                	mv	s2,a2
    8000665a:	84b6                	mv	s1,a3
  struct proc *p = myproc();
    8000665c:	ffffb097          	auipc	ra,0xffffb
    80006660:	558080e7          	jalr	1368(ra) # 80001bb4 <myproc>
  char *s = (char *) srcva;
  
  stats.ncopyinstr++;   // XXX lock
    80006664:	00003717          	auipc	a4,0x3
    80006668:	9c470713          	addi	a4,a4,-1596 # 80009028 <stats>
    8000666c:	435c                	lw	a5,4(a4)
    8000666e:	2785                	addiw	a5,a5,1
    80006670:	c35c                	sw	a5,4(a4)
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006672:	cc85                	beqz	s1,800066aa <copyinstr_new+0x62>
    80006674:	00990833          	add	a6,s2,s1
    80006678:	87ca                	mv	a5,s2
    8000667a:	6538                	ld	a4,72(a0)
    8000667c:	00e7ff63          	bgeu	a5,a4,8000669a <copyinstr_new+0x52>
    dst[i] = s[i];
    80006680:	0007c683          	lbu	a3,0(a5)
    80006684:	41278733          	sub	a4,a5,s2
    80006688:	974e                	add	a4,a4,s3
    8000668a:	00d70023          	sb	a3,0(a4)
    if(s[i] == '\0')
    8000668e:	c285                	beqz	a3,800066ae <copyinstr_new+0x66>
  for(int i = 0; i < max && srcva + i < p->sz; i++){
    80006690:	0785                	addi	a5,a5,1
    80006692:	ff0794e3          	bne	a5,a6,8000667a <copyinstr_new+0x32>
      return 0;
  }
  return -1;
    80006696:	557d                	li	a0,-1
    80006698:	a011                	j	8000669c <copyinstr_new+0x54>
    8000669a:	557d                	li	a0,-1
}
    8000669c:	70a2                	ld	ra,40(sp)
    8000669e:	7402                	ld	s0,32(sp)
    800066a0:	64e2                	ld	s1,24(sp)
    800066a2:	6942                	ld	s2,16(sp)
    800066a4:	69a2                	ld	s3,8(sp)
    800066a6:	6145                	addi	sp,sp,48
    800066a8:	8082                	ret
  return -1;
    800066aa:	557d                	li	a0,-1
    800066ac:	bfc5                	j	8000669c <copyinstr_new+0x54>
      return 0;
    800066ae:	4501                	li	a0,0
    800066b0:	b7f5                	j	8000669c <copyinstr_new+0x54>

00000000800066b2 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    800066b2:	1141                	addi	sp,sp,-16
    800066b4:	e422                	sd	s0,8(sp)
    800066b6:	0800                	addi	s0,sp,16
  return -1;
}
    800066b8:	557d                	li	a0,-1
    800066ba:	6422                	ld	s0,8(sp)
    800066bc:	0141                	addi	sp,sp,16
    800066be:	8082                	ret

00000000800066c0 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    800066c0:	7179                	addi	sp,sp,-48
    800066c2:	f406                	sd	ra,40(sp)
    800066c4:	f022                	sd	s0,32(sp)
    800066c6:	ec26                	sd	s1,24(sp)
    800066c8:	e84a                	sd	s2,16(sp)
    800066ca:	e44e                	sd	s3,8(sp)
    800066cc:	e052                	sd	s4,0(sp)
    800066ce:	1800                	addi	s0,sp,48
    800066d0:	892a                	mv	s2,a0
    800066d2:	89ae                	mv	s3,a1
    800066d4:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800066d6:	00020517          	auipc	a0,0x20
    800066da:	92a50513          	addi	a0,a0,-1750 # 80026000 <stats>
    800066de:	ffffa097          	auipc	ra,0xffffa
    800066e2:	532080e7          	jalr	1330(ra) # 80000c10 <acquire>

  if(stats.sz == 0) {
    800066e6:	00021797          	auipc	a5,0x21
    800066ea:	9327a783          	lw	a5,-1742(a5) # 80027018 <stats+0x1018>
    800066ee:	cbb5                	beqz	a5,80006762 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800066f0:	00021797          	auipc	a5,0x21
    800066f4:	91078793          	addi	a5,a5,-1776 # 80027000 <stats+0x1000>
    800066f8:	4fd8                	lw	a4,28(a5)
    800066fa:	4f9c                	lw	a5,24(a5)
    800066fc:	9f99                	subw	a5,a5,a4
    800066fe:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    80006702:	06d05e63          	blez	a3,8000677e <statsread+0xbe>
    if(m > n)
    80006706:	8a3e                	mv	s4,a5
    80006708:	00d4d363          	bge	s1,a3,8000670e <statsread+0x4e>
    8000670c:	8a26                	mv	s4,s1
    8000670e:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    80006712:	86a6                	mv	a3,s1
    80006714:	00020617          	auipc	a2,0x20
    80006718:	90460613          	addi	a2,a2,-1788 # 80026018 <stats+0x18>
    8000671c:	963a                	add	a2,a2,a4
    8000671e:	85ce                	mv	a1,s3
    80006720:	854a                	mv	a0,s2
    80006722:	ffffc097          	auipc	ra,0xffffc
    80006726:	0d8080e7          	jalr	216(ra) # 800027fa <either_copyout>
    8000672a:	57fd                	li	a5,-1
    8000672c:	00f50a63          	beq	a0,a5,80006740 <statsread+0x80>
      stats.off += m;
    80006730:	00021717          	auipc	a4,0x21
    80006734:	8d070713          	addi	a4,a4,-1840 # 80027000 <stats+0x1000>
    80006738:	4f5c                	lw	a5,28(a4)
    8000673a:	014787bb          	addw	a5,a5,s4
    8000673e:	cf5c                	sw	a5,28(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006740:	00020517          	auipc	a0,0x20
    80006744:	8c050513          	addi	a0,a0,-1856 # 80026000 <stats>
    80006748:	ffffa097          	auipc	ra,0xffffa
    8000674c:	57c080e7          	jalr	1404(ra) # 80000cc4 <release>
  return m;
}
    80006750:	8526                	mv	a0,s1
    80006752:	70a2                	ld	ra,40(sp)
    80006754:	7402                	ld	s0,32(sp)
    80006756:	64e2                	ld	s1,24(sp)
    80006758:	6942                	ld	s2,16(sp)
    8000675a:	69a2                	ld	s3,8(sp)
    8000675c:	6a02                	ld	s4,0(sp)
    8000675e:	6145                	addi	sp,sp,48
    80006760:	8082                	ret
    stats.sz = statscopyin(stats.buf, BUFSZ);
    80006762:	6585                	lui	a1,0x1
    80006764:	00020517          	auipc	a0,0x20
    80006768:	8b450513          	addi	a0,a0,-1868 # 80026018 <stats+0x18>
    8000676c:	00000097          	auipc	ra,0x0
    80006770:	e18080e7          	jalr	-488(ra) # 80006584 <statscopyin>
    80006774:	00021797          	auipc	a5,0x21
    80006778:	8aa7a223          	sw	a0,-1884(a5) # 80027018 <stats+0x1018>
    8000677c:	bf95                	j	800066f0 <statsread+0x30>
    stats.sz = 0;
    8000677e:	00021797          	auipc	a5,0x21
    80006782:	88278793          	addi	a5,a5,-1918 # 80027000 <stats+0x1000>
    80006786:	0007ac23          	sw	zero,24(a5)
    stats.off = 0;
    8000678a:	0007ae23          	sw	zero,28(a5)
    m = -1;
    8000678e:	54fd                	li	s1,-1
    80006790:	bf45                	j	80006740 <statsread+0x80>

0000000080006792 <statsinit>:

void
statsinit(void)
{
    80006792:	1141                	addi	sp,sp,-16
    80006794:	e406                	sd	ra,8(sp)
    80006796:	e022                	sd	s0,0(sp)
    80006798:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000679a:	00002597          	auipc	a1,0x2
    8000679e:	0d658593          	addi	a1,a1,214 # 80008870 <syscalls+0x400>
    800067a2:	00020517          	auipc	a0,0x20
    800067a6:	85e50513          	addi	a0,a0,-1954 # 80026000 <stats>
    800067aa:	ffffa097          	auipc	ra,0xffffa
    800067ae:	3d6080e7          	jalr	982(ra) # 80000b80 <initlock>

  devsw[STATS].read = statsread;
    800067b2:	0001b797          	auipc	a5,0x1b
    800067b6:	3fe78793          	addi	a5,a5,1022 # 80021bb0 <devsw>
    800067ba:	00000717          	auipc	a4,0x0
    800067be:	f0670713          	addi	a4,a4,-250 # 800066c0 <statsread>
    800067c2:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    800067c4:	00000717          	auipc	a4,0x0
    800067c8:	eee70713          	addi	a4,a4,-274 # 800066b2 <statswrite>
    800067cc:	f798                	sd	a4,40(a5)
}
    800067ce:	60a2                	ld	ra,8(sp)
    800067d0:	6402                	ld	s0,0(sp)
    800067d2:	0141                	addi	sp,sp,16
    800067d4:	8082                	ret

00000000800067d6 <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800067d6:	1101                	addi	sp,sp,-32
    800067d8:	ec22                	sd	s0,24(sp)
    800067da:	1000                	addi	s0,sp,32
    800067dc:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800067de:	c299                	beqz	a3,800067e4 <sprintint+0xe>
    800067e0:	0805c163          	bltz	a1,80006862 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800067e4:	2581                	sext.w	a1,a1
    800067e6:	4301                	li	t1,0

  i = 0;
    800067e8:	fe040713          	addi	a4,s0,-32
    800067ec:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800067ee:	2601                	sext.w	a2,a2
    800067f0:	00002697          	auipc	a3,0x2
    800067f4:	08868693          	addi	a3,a3,136 # 80008878 <digits>
    800067f8:	88aa                	mv	a7,a0
    800067fa:	2505                	addiw	a0,a0,1
    800067fc:	02c5f7bb          	remuw	a5,a1,a2
    80006800:	1782                	slli	a5,a5,0x20
    80006802:	9381                	srli	a5,a5,0x20
    80006804:	97b6                	add	a5,a5,a3
    80006806:	0007c783          	lbu	a5,0(a5)
    8000680a:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    8000680e:	0005879b          	sext.w	a5,a1
    80006812:	02c5d5bb          	divuw	a1,a1,a2
    80006816:	0705                	addi	a4,a4,1
    80006818:	fec7f0e3          	bgeu	a5,a2,800067f8 <sprintint+0x22>

  if(sign)
    8000681c:	00030b63          	beqz	t1,80006832 <sprintint+0x5c>
    buf[i++] = '-';
    80006820:	ff040793          	addi	a5,s0,-16
    80006824:	97aa                	add	a5,a5,a0
    80006826:	02d00713          	li	a4,45
    8000682a:	fee78823          	sb	a4,-16(a5)
    8000682e:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006832:	02a05c63          	blez	a0,8000686a <sprintint+0x94>
    80006836:	fe040793          	addi	a5,s0,-32
    8000683a:	00a78733          	add	a4,a5,a0
    8000683e:	87c2                	mv	a5,a6
    80006840:	0805                	addi	a6,a6,1
    80006842:	fff5061b          	addiw	a2,a0,-1
    80006846:	1602                	slli	a2,a2,0x20
    80006848:	9201                	srli	a2,a2,0x20
    8000684a:	9642                	add	a2,a2,a6
  *s = c;
    8000684c:	fff74683          	lbu	a3,-1(a4)
    80006850:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006854:	177d                	addi	a4,a4,-1
    80006856:	0785                	addi	a5,a5,1
    80006858:	fec79ae3          	bne	a5,a2,8000684c <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    8000685c:	6462                	ld	s0,24(sp)
    8000685e:	6105                	addi	sp,sp,32
    80006860:	8082                	ret
    x = -xx;
    80006862:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    80006866:	4305                	li	t1,1
    x = -xx;
    80006868:	b741                	j	800067e8 <sprintint+0x12>
  while(--i >= 0)
    8000686a:	4501                	li	a0,0
    8000686c:	bfc5                	j	8000685c <sprintint+0x86>

000000008000686e <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    8000686e:	7171                	addi	sp,sp,-176
    80006870:	fc86                	sd	ra,120(sp)
    80006872:	f8a2                	sd	s0,112(sp)
    80006874:	f4a6                	sd	s1,104(sp)
    80006876:	f0ca                	sd	s2,96(sp)
    80006878:	ecce                	sd	s3,88(sp)
    8000687a:	e8d2                	sd	s4,80(sp)
    8000687c:	e4d6                	sd	s5,72(sp)
    8000687e:	e0da                	sd	s6,64(sp)
    80006880:	fc5e                	sd	s7,56(sp)
    80006882:	f862                	sd	s8,48(sp)
    80006884:	f466                	sd	s9,40(sp)
    80006886:	f06a                	sd	s10,32(sp)
    80006888:	ec6e                	sd	s11,24(sp)
    8000688a:	0100                	addi	s0,sp,128
    8000688c:	e414                	sd	a3,8(s0)
    8000688e:	e818                	sd	a4,16(s0)
    80006890:	ec1c                	sd	a5,24(s0)
    80006892:	03043023          	sd	a6,32(s0)
    80006896:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000689a:	ca0d                	beqz	a2,800068cc <snprintf+0x5e>
    8000689c:	8baa                	mv	s7,a0
    8000689e:	89ae                	mv	s3,a1
    800068a0:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    800068a2:	00840793          	addi	a5,s0,8
    800068a6:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    800068aa:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068ac:	4901                	li	s2,0
    800068ae:	02b05763          	blez	a1,800068dc <snprintf+0x6e>
    if(c != '%'){
    800068b2:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    800068b6:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    800068ba:	02800d93          	li	s11,40
  *s = c;
    800068be:	02500d13          	li	s10,37
    switch(c){
    800068c2:	07800c93          	li	s9,120
    800068c6:	06400c13          	li	s8,100
    800068ca:	a01d                	j	800068f0 <snprintf+0x82>
    panic("null fmt");
    800068cc:	00001517          	auipc	a0,0x1
    800068d0:	75c50513          	addi	a0,a0,1884 # 80008028 <etext+0x28>
    800068d4:	ffffa097          	auipc	ra,0xffffa
    800068d8:	c74080e7          	jalr	-908(ra) # 80000548 <panic>
  int off = 0;
    800068dc:	4481                	li	s1,0
    800068de:	a86d                	j	80006998 <snprintf+0x12a>
  *s = c;
    800068e0:	009b8733          	add	a4,s7,s1
    800068e4:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800068e8:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800068ea:	2905                	addiw	s2,s2,1
    800068ec:	0b34d663          	bge	s1,s3,80006998 <snprintf+0x12a>
    800068f0:	012a07b3          	add	a5,s4,s2
    800068f4:	0007c783          	lbu	a5,0(a5)
    800068f8:	0007871b          	sext.w	a4,a5
    800068fc:	cfd1                	beqz	a5,80006998 <snprintf+0x12a>
    if(c != '%'){
    800068fe:	ff5711e3          	bne	a4,s5,800068e0 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    80006902:	2905                	addiw	s2,s2,1
    80006904:	012a07b3          	add	a5,s4,s2
    80006908:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    8000690c:	c7d1                	beqz	a5,80006998 <snprintf+0x12a>
    switch(c){
    8000690e:	05678c63          	beq	a5,s6,80006966 <snprintf+0xf8>
    80006912:	02fb6763          	bltu	s6,a5,80006940 <snprintf+0xd2>
    80006916:	0b578763          	beq	a5,s5,800069c4 <snprintf+0x156>
    8000691a:	0b879b63          	bne	a5,s8,800069d0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    8000691e:	f8843783          	ld	a5,-120(s0)
    80006922:	00878713          	addi	a4,a5,8
    80006926:	f8e43423          	sd	a4,-120(s0)
    8000692a:	4685                	li	a3,1
    8000692c:	4629                	li	a2,10
    8000692e:	438c                	lw	a1,0(a5)
    80006930:	009b8533          	add	a0,s7,s1
    80006934:	00000097          	auipc	ra,0x0
    80006938:	ea2080e7          	jalr	-350(ra) # 800067d6 <sprintint>
    8000693c:	9ca9                	addw	s1,s1,a0
      break;
    8000693e:	b775                	j	800068ea <snprintf+0x7c>
    switch(c){
    80006940:	09979863          	bne	a5,s9,800069d0 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006944:	f8843783          	ld	a5,-120(s0)
    80006948:	00878713          	addi	a4,a5,8
    8000694c:	f8e43423          	sd	a4,-120(s0)
    80006950:	4685                	li	a3,1
    80006952:	4641                	li	a2,16
    80006954:	438c                	lw	a1,0(a5)
    80006956:	009b8533          	add	a0,s7,s1
    8000695a:	00000097          	auipc	ra,0x0
    8000695e:	e7c080e7          	jalr	-388(ra) # 800067d6 <sprintint>
    80006962:	9ca9                	addw	s1,s1,a0
      break;
    80006964:	b759                	j	800068ea <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006966:	f8843783          	ld	a5,-120(s0)
    8000696a:	00878713          	addi	a4,a5,8
    8000696e:	f8e43423          	sd	a4,-120(s0)
    80006972:	639c                	ld	a5,0(a5)
    80006974:	c3b1                	beqz	a5,800069b8 <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006976:	0007c703          	lbu	a4,0(a5)
    8000697a:	db25                	beqz	a4,800068ea <snprintf+0x7c>
    8000697c:	0134de63          	bge	s1,s3,80006998 <snprintf+0x12a>
    80006980:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006984:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006988:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    8000698a:	0785                	addi	a5,a5,1
    8000698c:	0007c703          	lbu	a4,0(a5)
    80006990:	df29                	beqz	a4,800068ea <snprintf+0x7c>
    80006992:	0685                	addi	a3,a3,1
    80006994:	fe9998e3          	bne	s3,s1,80006984 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006998:	8526                	mv	a0,s1
    8000699a:	70e6                	ld	ra,120(sp)
    8000699c:	7446                	ld	s0,112(sp)
    8000699e:	74a6                	ld	s1,104(sp)
    800069a0:	7906                	ld	s2,96(sp)
    800069a2:	69e6                	ld	s3,88(sp)
    800069a4:	6a46                	ld	s4,80(sp)
    800069a6:	6aa6                	ld	s5,72(sp)
    800069a8:	6b06                	ld	s6,64(sp)
    800069aa:	7be2                	ld	s7,56(sp)
    800069ac:	7c42                	ld	s8,48(sp)
    800069ae:	7ca2                	ld	s9,40(sp)
    800069b0:	7d02                	ld	s10,32(sp)
    800069b2:	6de2                	ld	s11,24(sp)
    800069b4:	614d                	addi	sp,sp,176
    800069b6:	8082                	ret
        s = "(null)";
    800069b8:	00001797          	auipc	a5,0x1
    800069bc:	66878793          	addi	a5,a5,1640 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    800069c0:	876e                	mv	a4,s11
    800069c2:	bf6d                	j	8000697c <snprintf+0x10e>
  *s = c;
    800069c4:	009b87b3          	add	a5,s7,s1
    800069c8:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    800069cc:	2485                	addiw	s1,s1,1
      break;
    800069ce:	bf31                	j	800068ea <snprintf+0x7c>
  *s = c;
    800069d0:	009b8733          	add	a4,s7,s1
    800069d4:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    800069d8:	0014871b          	addiw	a4,s1,1
  *s = c;
    800069dc:	975e                	add	a4,a4,s7
    800069de:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069e2:	2489                	addiw	s1,s1,2
      break;
    800069e4:	b719                	j	800068ea <snprintf+0x7c>
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
