
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	9f013103          	ld	sp,-1552(sp) # 800089f0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	c6478793          	addi	a5,a5,-924 # 80005cc0 <timervec>
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
    800000aa:	e3c78793          	addi	a5,a5,-452 # 80000ee2 <main>
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
    80000110:	b28080e7          	jalr	-1240(ra) # 80000c34 <acquire>
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
    8000012a:	3b0080e7          	jalr	944(ra) # 800024d6 <either_copyin>
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
    80000152:	b9a080e7          	jalr	-1126(ra) # 80000ce8 <release>

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
    800001a2:	a96080e7          	jalr	-1386(ra) # 80000c34 <acquire>
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
    800001d2:	834080e7          	jalr	-1996(ra) # 80001a02 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	040080e7          	jalr	64(ra) # 8000221e <sleep>
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
    8000021e:	266080e7          	jalr	614(ra) # 80002480 <either_copyout>
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
    8000023a:	ab2080e7          	jalr	-1358(ra) # 80000ce8 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	a9c080e7          	jalr	-1380(ra) # 80000ce8 <release>
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
    800002e2:	956080e7          	jalr	-1706(ra) # 80000c34 <acquire>

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
    80000300:	230080e7          	jalr	560(ra) # 8000252c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	9dc080e7          	jalr	-1572(ra) # 80000ce8 <release>
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
    80000454:	f54080e7          	jalr	-172(ra) # 800023a4 <wakeup>
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
    80000476:	732080e7          	jalr	1842(ra) # 80000ba4 <initlock>

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
    8000060e:	62a080e7          	jalr	1578(ra) # 80000c34 <acquire>
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
    80000772:	57a080e7          	jalr	1402(ra) # 80000ce8 <release>
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
    80000798:	410080e7          	jalr	1040(ra) # 80000ba4 <initlock>
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
    800007ee:	3ba080e7          	jalr	954(ra) # 80000ba4 <initlock>
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
    8000080a:	3e2080e7          	jalr	994(ra) # 80000be8 <push_off>

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
    8000083c:	450080e7          	jalr	1104(ra) # 80000c88 <pop_off>
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
    800008ba:	aee080e7          	jalr	-1298(ra) # 800023a4 <wakeup>
    
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
    800008fe:	33a080e7          	jalr	826(ra) # 80000c34 <acquire>
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
    80000954:	8ce080e7          	jalr	-1842(ra) # 8000221e <sleep>
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
    80000998:	354080e7          	jalr	852(ra) # 80000ce8 <release>
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
    80000a04:	234080e7          	jalr	564(ra) # 80000c34 <acquire>
  uartstart();
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	e42080e7          	jalr	-446(ra) # 8000084a <uartstart>
  release(&uart_tx_lock);
    80000a10:	8526                	mv	a0,s1
    80000a12:	00000097          	auipc	ra,0x0
    80000a16:	2d6080e7          	jalr	726(ra) # 80000ce8 <release>
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
    80000a54:	2e0080e7          	jalr	736(ra) # 80000d30 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a58:	00011917          	auipc	s2,0x11
    80000a5c:	ed890913          	addi	s2,s2,-296 # 80011930 <kmem>
    80000a60:	854a                	mv	a0,s2
    80000a62:	00000097          	auipc	ra,0x0
    80000a66:	1d2080e7          	jalr	466(ra) # 80000c34 <acquire>
  r->next = kmem.freelist;
    80000a6a:	01893783          	ld	a5,24(s2)
    80000a6e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a70:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a74:	854a                	mv	a0,s2
    80000a76:	00000097          	auipc	ra,0x0
    80000a7a:	272080e7          	jalr	626(ra) # 80000ce8 <release>
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
    80000b00:	0a8080e7          	jalr	168(ra) # 80000ba4 <initlock>
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
    80000b38:	100080e7          	jalr	256(ra) # 80000c34 <acquire>
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
    80000b50:	19c080e7          	jalr	412(ra) # 80000ce8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b54:	6605                	lui	a2,0x1
    80000b56:	4595                	li	a1,5
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	1d6080e7          	jalr	470(ra) # 80000d30 <memset>
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
    80000b7a:	172080e7          	jalr	370(ra) # 80000ce8 <release>
  if(r)
    80000b7e:	b7d5                	j	80000b62 <kalloc+0x42>

0000000080000b80 <getfreespace>:

// check the amount of free memory in bytes
uint64
getfreespace(void)
{
    80000b80:	1141                	addi	sp,sp,-16
    80000b82:	e422                	sd	s0,8(sp)
    80000b84:	0800                	addi	s0,sp,16
  uint64 i = 0;
  struct run *ptr = kmem.freelist;
    80000b86:	00011797          	auipc	a5,0x11
    80000b8a:	dc27b783          	ld	a5,-574(a5) # 80011948 <kmem+0x18>
  while (ptr != 0)
    80000b8e:	cb89                	beqz	a5,80000ba0 <getfreespace+0x20>
  uint64 i = 0;
    80000b90:	4501                	li	a0,0
  {
    i++;
    80000b92:	0505                	addi	a0,a0,1
    ptr = ptr->next;
    80000b94:	639c                	ld	a5,0(a5)
  while (ptr != 0)
    80000b96:	fff5                	bnez	a5,80000b92 <getfreespace+0x12>
  }
  return i * PGSIZE;
    80000b98:	0532                	slli	a0,a0,0xc
    80000b9a:	6422                	ld	s0,8(sp)
    80000b9c:	0141                	addi	sp,sp,16
    80000b9e:	8082                	ret
  uint64 i = 0;
    80000ba0:	4501                	li	a0,0
    80000ba2:	bfdd                	j	80000b98 <getfreespace+0x18>

0000000080000ba4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000ba4:	1141                	addi	sp,sp,-16
    80000ba6:	e422                	sd	s0,8(sp)
    80000ba8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000baa:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bac:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000bb0:	00053823          	sd	zero,16(a0)
}
    80000bb4:	6422                	ld	s0,8(sp)
    80000bb6:	0141                	addi	sp,sp,16
    80000bb8:	8082                	ret

0000000080000bba <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000bba:	411c                	lw	a5,0(a0)
    80000bbc:	e399                	bnez	a5,80000bc2 <holding+0x8>
    80000bbe:	4501                	li	a0,0
  return r;
}
    80000bc0:	8082                	ret
{
    80000bc2:	1101                	addi	sp,sp,-32
    80000bc4:	ec06                	sd	ra,24(sp)
    80000bc6:	e822                	sd	s0,16(sp)
    80000bc8:	e426                	sd	s1,8(sp)
    80000bca:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bcc:	6904                	ld	s1,16(a0)
    80000bce:	00001097          	auipc	ra,0x1
    80000bd2:	e18080e7          	jalr	-488(ra) # 800019e6 <mycpu>
    80000bd6:	40a48533          	sub	a0,s1,a0
    80000bda:	00153513          	seqz	a0,a0
}
    80000bde:	60e2                	ld	ra,24(sp)
    80000be0:	6442                	ld	s0,16(sp)
    80000be2:	64a2                	ld	s1,8(sp)
    80000be4:	6105                	addi	sp,sp,32
    80000be6:	8082                	ret

0000000080000be8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000be8:	1101                	addi	sp,sp,-32
    80000bea:	ec06                	sd	ra,24(sp)
    80000bec:	e822                	sd	s0,16(sp)
    80000bee:	e426                	sd	s1,8(sp)
    80000bf0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bf2:	100024f3          	csrr	s1,sstatus
    80000bf6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000bfa:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000bfc:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c00:	00001097          	auipc	ra,0x1
    80000c04:	de6080e7          	jalr	-538(ra) # 800019e6 <mycpu>
    80000c08:	5d3c                	lw	a5,120(a0)
    80000c0a:	cf89                	beqz	a5,80000c24 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c0c:	00001097          	auipc	ra,0x1
    80000c10:	dda080e7          	jalr	-550(ra) # 800019e6 <mycpu>
    80000c14:	5d3c                	lw	a5,120(a0)
    80000c16:	2785                	addiw	a5,a5,1
    80000c18:	dd3c                	sw	a5,120(a0)
}
    80000c1a:	60e2                	ld	ra,24(sp)
    80000c1c:	6442                	ld	s0,16(sp)
    80000c1e:	64a2                	ld	s1,8(sp)
    80000c20:	6105                	addi	sp,sp,32
    80000c22:	8082                	ret
    mycpu()->intena = old;
    80000c24:	00001097          	auipc	ra,0x1
    80000c28:	dc2080e7          	jalr	-574(ra) # 800019e6 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c2c:	8085                	srli	s1,s1,0x1
    80000c2e:	8885                	andi	s1,s1,1
    80000c30:	dd64                	sw	s1,124(a0)
    80000c32:	bfe9                	j	80000c0c <push_off+0x24>

0000000080000c34 <acquire>:
{
    80000c34:	1101                	addi	sp,sp,-32
    80000c36:	ec06                	sd	ra,24(sp)
    80000c38:	e822                	sd	s0,16(sp)
    80000c3a:	e426                	sd	s1,8(sp)
    80000c3c:	1000                	addi	s0,sp,32
    80000c3e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	fa8080e7          	jalr	-88(ra) # 80000be8 <push_off>
  if(holding(lk))
    80000c48:	8526                	mv	a0,s1
    80000c4a:	00000097          	auipc	ra,0x0
    80000c4e:	f70080e7          	jalr	-144(ra) # 80000bba <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c52:	4705                	li	a4,1
  if(holding(lk))
    80000c54:	e115                	bnez	a0,80000c78 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c56:	87ba                	mv	a5,a4
    80000c58:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c5c:	2781                	sext.w	a5,a5
    80000c5e:	ffe5                	bnez	a5,80000c56 <acquire+0x22>
  __sync_synchronize();
    80000c60:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c64:	00001097          	auipc	ra,0x1
    80000c68:	d82080e7          	jalr	-638(ra) # 800019e6 <mycpu>
    80000c6c:	e888                	sd	a0,16(s1)
}
    80000c6e:	60e2                	ld	ra,24(sp)
    80000c70:	6442                	ld	s0,16(sp)
    80000c72:	64a2                	ld	s1,8(sp)
    80000c74:	6105                	addi	sp,sp,32
    80000c76:	8082                	ret
    panic("acquire");
    80000c78:	00007517          	auipc	a0,0x7
    80000c7c:	3f850513          	addi	a0,a0,1016 # 80008070 <digits+0x30>
    80000c80:	00000097          	auipc	ra,0x0
    80000c84:	8c8080e7          	jalr	-1848(ra) # 80000548 <panic>

0000000080000c88 <pop_off>:

void
pop_off(void)
{
    80000c88:	1141                	addi	sp,sp,-16
    80000c8a:	e406                	sd	ra,8(sp)
    80000c8c:	e022                	sd	s0,0(sp)
    80000c8e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c90:	00001097          	auipc	ra,0x1
    80000c94:	d56080e7          	jalr	-682(ra) # 800019e6 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c98:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c9c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c9e:	e78d                	bnez	a5,80000cc8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000ca0:	5d3c                	lw	a5,120(a0)
    80000ca2:	02f05b63          	blez	a5,80000cd8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ca6:	37fd                	addiw	a5,a5,-1
    80000ca8:	0007871b          	sext.w	a4,a5
    80000cac:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cae:	eb09                	bnez	a4,80000cc0 <pop_off+0x38>
    80000cb0:	5d7c                	lw	a5,124(a0)
    80000cb2:	c799                	beqz	a5,80000cc0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cb4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000cb8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cbc:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cc0:	60a2                	ld	ra,8(sp)
    80000cc2:	6402                	ld	s0,0(sp)
    80000cc4:	0141                	addi	sp,sp,16
    80000cc6:	8082                	ret
    panic("pop_off - interruptible");
    80000cc8:	00007517          	auipc	a0,0x7
    80000ccc:	3b050513          	addi	a0,a0,944 # 80008078 <digits+0x38>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	878080e7          	jalr	-1928(ra) # 80000548 <panic>
    panic("pop_off");
    80000cd8:	00007517          	auipc	a0,0x7
    80000cdc:	3b850513          	addi	a0,a0,952 # 80008090 <digits+0x50>
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	868080e7          	jalr	-1944(ra) # 80000548 <panic>

0000000080000ce8 <release>:
{
    80000ce8:	1101                	addi	sp,sp,-32
    80000cea:	ec06                	sd	ra,24(sp)
    80000cec:	e822                	sd	s0,16(sp)
    80000cee:	e426                	sd	s1,8(sp)
    80000cf0:	1000                	addi	s0,sp,32
    80000cf2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000cf4:	00000097          	auipc	ra,0x0
    80000cf8:	ec6080e7          	jalr	-314(ra) # 80000bba <holding>
    80000cfc:	c115                	beqz	a0,80000d20 <release+0x38>
  lk->cpu = 0;
    80000cfe:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d02:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d06:	0f50000f          	fence	iorw,ow
    80000d0a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d0e:	00000097          	auipc	ra,0x0
    80000d12:	f7a080e7          	jalr	-134(ra) # 80000c88 <pop_off>
}
    80000d16:	60e2                	ld	ra,24(sp)
    80000d18:	6442                	ld	s0,16(sp)
    80000d1a:	64a2                	ld	s1,8(sp)
    80000d1c:	6105                	addi	sp,sp,32
    80000d1e:	8082                	ret
    panic("release");
    80000d20:	00007517          	auipc	a0,0x7
    80000d24:	37850513          	addi	a0,a0,888 # 80008098 <digits+0x58>
    80000d28:	00000097          	auipc	ra,0x0
    80000d2c:	820080e7          	jalr	-2016(ra) # 80000548 <panic>

0000000080000d30 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d30:	1141                	addi	sp,sp,-16
    80000d32:	e422                	sd	s0,8(sp)
    80000d34:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d36:	ce09                	beqz	a2,80000d50 <memset+0x20>
    80000d38:	87aa                	mv	a5,a0
    80000d3a:	fff6071b          	addiw	a4,a2,-1
    80000d3e:	1702                	slli	a4,a4,0x20
    80000d40:	9301                	srli	a4,a4,0x20
    80000d42:	0705                	addi	a4,a4,1
    80000d44:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d46:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d4a:	0785                	addi	a5,a5,1
    80000d4c:	fee79de3          	bne	a5,a4,80000d46 <memset+0x16>
  }
  return dst;
}
    80000d50:	6422                	ld	s0,8(sp)
    80000d52:	0141                	addi	sp,sp,16
    80000d54:	8082                	ret

0000000080000d56 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d56:	1141                	addi	sp,sp,-16
    80000d58:	e422                	sd	s0,8(sp)
    80000d5a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d5c:	ca05                	beqz	a2,80000d8c <memcmp+0x36>
    80000d5e:	fff6069b          	addiw	a3,a2,-1
    80000d62:	1682                	slli	a3,a3,0x20
    80000d64:	9281                	srli	a3,a3,0x20
    80000d66:	0685                	addi	a3,a3,1
    80000d68:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d6a:	00054783          	lbu	a5,0(a0)
    80000d6e:	0005c703          	lbu	a4,0(a1)
    80000d72:	00e79863          	bne	a5,a4,80000d82 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d76:	0505                	addi	a0,a0,1
    80000d78:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d7a:	fed518e3          	bne	a0,a3,80000d6a <memcmp+0x14>
  }

  return 0;
    80000d7e:	4501                	li	a0,0
    80000d80:	a019                	j	80000d86 <memcmp+0x30>
      return *s1 - *s2;
    80000d82:	40e7853b          	subw	a0,a5,a4
}
    80000d86:	6422                	ld	s0,8(sp)
    80000d88:	0141                	addi	sp,sp,16
    80000d8a:	8082                	ret
  return 0;
    80000d8c:	4501                	li	a0,0
    80000d8e:	bfe5                	j	80000d86 <memcmp+0x30>

0000000080000d90 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d90:	1141                	addi	sp,sp,-16
    80000d92:	e422                	sd	s0,8(sp)
    80000d94:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d96:	00a5f963          	bgeu	a1,a0,80000da8 <memmove+0x18>
    80000d9a:	02061713          	slli	a4,a2,0x20
    80000d9e:	9301                	srli	a4,a4,0x20
    80000da0:	00e587b3          	add	a5,a1,a4
    80000da4:	02f56563          	bltu	a0,a5,80000dce <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000da8:	fff6069b          	addiw	a3,a2,-1
    80000dac:	ce11                	beqz	a2,80000dc8 <memmove+0x38>
    80000dae:	1682                	slli	a3,a3,0x20
    80000db0:	9281                	srli	a3,a3,0x20
    80000db2:	0685                	addi	a3,a3,1
    80000db4:	96ae                	add	a3,a3,a1
    80000db6:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000db8:	0585                	addi	a1,a1,1
    80000dba:	0785                	addi	a5,a5,1
    80000dbc:	fff5c703          	lbu	a4,-1(a1)
    80000dc0:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000dc4:	fed59ae3          	bne	a1,a3,80000db8 <memmove+0x28>

  return dst;
}
    80000dc8:	6422                	ld	s0,8(sp)
    80000dca:	0141                	addi	sp,sp,16
    80000dcc:	8082                	ret
    d += n;
    80000dce:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000dd0:	fff6069b          	addiw	a3,a2,-1
    80000dd4:	da75                	beqz	a2,80000dc8 <memmove+0x38>
    80000dd6:	02069613          	slli	a2,a3,0x20
    80000dda:	9201                	srli	a2,a2,0x20
    80000ddc:	fff64613          	not	a2,a2
    80000de0:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000de2:	17fd                	addi	a5,a5,-1
    80000de4:	177d                	addi	a4,a4,-1
    80000de6:	0007c683          	lbu	a3,0(a5)
    80000dea:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000dee:	fec79ae3          	bne	a5,a2,80000de2 <memmove+0x52>
    80000df2:	bfd9                	j	80000dc8 <memmove+0x38>

0000000080000df4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000df4:	1141                	addi	sp,sp,-16
    80000df6:	e406                	sd	ra,8(sp)
    80000df8:	e022                	sd	s0,0(sp)
    80000dfa:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	f94080e7          	jalr	-108(ra) # 80000d90 <memmove>
}
    80000e04:	60a2                	ld	ra,8(sp)
    80000e06:	6402                	ld	s0,0(sp)
    80000e08:	0141                	addi	sp,sp,16
    80000e0a:	8082                	ret

0000000080000e0c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e0c:	1141                	addi	sp,sp,-16
    80000e0e:	e422                	sd	s0,8(sp)
    80000e10:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e12:	ce11                	beqz	a2,80000e2e <strncmp+0x22>
    80000e14:	00054783          	lbu	a5,0(a0)
    80000e18:	cf89                	beqz	a5,80000e32 <strncmp+0x26>
    80000e1a:	0005c703          	lbu	a4,0(a1)
    80000e1e:	00f71a63          	bne	a4,a5,80000e32 <strncmp+0x26>
    n--, p++, q++;
    80000e22:	367d                	addiw	a2,a2,-1
    80000e24:	0505                	addi	a0,a0,1
    80000e26:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e28:	f675                	bnez	a2,80000e14 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e2a:	4501                	li	a0,0
    80000e2c:	a809                	j	80000e3e <strncmp+0x32>
    80000e2e:	4501                	li	a0,0
    80000e30:	a039                	j	80000e3e <strncmp+0x32>
  if(n == 0)
    80000e32:	ca09                	beqz	a2,80000e44 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e34:	00054503          	lbu	a0,0(a0)
    80000e38:	0005c783          	lbu	a5,0(a1)
    80000e3c:	9d1d                	subw	a0,a0,a5
}
    80000e3e:	6422                	ld	s0,8(sp)
    80000e40:	0141                	addi	sp,sp,16
    80000e42:	8082                	ret
    return 0;
    80000e44:	4501                	li	a0,0
    80000e46:	bfe5                	j	80000e3e <strncmp+0x32>

0000000080000e48 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e48:	1141                	addi	sp,sp,-16
    80000e4a:	e422                	sd	s0,8(sp)
    80000e4c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e4e:	872a                	mv	a4,a0
    80000e50:	8832                	mv	a6,a2
    80000e52:	367d                	addiw	a2,a2,-1
    80000e54:	01005963          	blez	a6,80000e66 <strncpy+0x1e>
    80000e58:	0705                	addi	a4,a4,1
    80000e5a:	0005c783          	lbu	a5,0(a1)
    80000e5e:	fef70fa3          	sb	a5,-1(a4)
    80000e62:	0585                	addi	a1,a1,1
    80000e64:	f7f5                	bnez	a5,80000e50 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e66:	00c05d63          	blez	a2,80000e80 <strncpy+0x38>
    80000e6a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000e6c:	0685                	addi	a3,a3,1
    80000e6e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e72:	fff6c793          	not	a5,a3
    80000e76:	9fb9                	addw	a5,a5,a4
    80000e78:	010787bb          	addw	a5,a5,a6
    80000e7c:	fef048e3          	bgtz	a5,80000e6c <strncpy+0x24>
  return os;
}
    80000e80:	6422                	ld	s0,8(sp)
    80000e82:	0141                	addi	sp,sp,16
    80000e84:	8082                	ret

0000000080000e86 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e86:	1141                	addi	sp,sp,-16
    80000e88:	e422                	sd	s0,8(sp)
    80000e8a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e8c:	02c05363          	blez	a2,80000eb2 <safestrcpy+0x2c>
    80000e90:	fff6069b          	addiw	a3,a2,-1
    80000e94:	1682                	slli	a3,a3,0x20
    80000e96:	9281                	srli	a3,a3,0x20
    80000e98:	96ae                	add	a3,a3,a1
    80000e9a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e9c:	00d58963          	beq	a1,a3,80000eae <safestrcpy+0x28>
    80000ea0:	0585                	addi	a1,a1,1
    80000ea2:	0785                	addi	a5,a5,1
    80000ea4:	fff5c703          	lbu	a4,-1(a1)
    80000ea8:	fee78fa3          	sb	a4,-1(a5)
    80000eac:	fb65                	bnez	a4,80000e9c <safestrcpy+0x16>
    ;
  *s = 0;
    80000eae:	00078023          	sb	zero,0(a5)
  return os;
}
    80000eb2:	6422                	ld	s0,8(sp)
    80000eb4:	0141                	addi	sp,sp,16
    80000eb6:	8082                	ret

0000000080000eb8 <strlen>:

int
strlen(const char *s)
{
    80000eb8:	1141                	addi	sp,sp,-16
    80000eba:	e422                	sd	s0,8(sp)
    80000ebc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000ebe:	00054783          	lbu	a5,0(a0)
    80000ec2:	cf91                	beqz	a5,80000ede <strlen+0x26>
    80000ec4:	0505                	addi	a0,a0,1
    80000ec6:	87aa                	mv	a5,a0
    80000ec8:	4685                	li	a3,1
    80000eca:	9e89                	subw	a3,a3,a0
    80000ecc:	00f6853b          	addw	a0,a3,a5
    80000ed0:	0785                	addi	a5,a5,1
    80000ed2:	fff7c703          	lbu	a4,-1(a5)
    80000ed6:	fb7d                	bnez	a4,80000ecc <strlen+0x14>
    ;
  return n;
}
    80000ed8:	6422                	ld	s0,8(sp)
    80000eda:	0141                	addi	sp,sp,16
    80000edc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ede:	4501                	li	a0,0
    80000ee0:	bfe5                	j	80000ed8 <strlen+0x20>

0000000080000ee2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ee2:	1141                	addi	sp,sp,-16
    80000ee4:	e406                	sd	ra,8(sp)
    80000ee6:	e022                	sd	s0,0(sp)
    80000ee8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eea:	00001097          	auipc	ra,0x1
    80000eee:	aec080e7          	jalr	-1300(ra) # 800019d6 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ef2:	00008717          	auipc	a4,0x8
    80000ef6:	11a70713          	addi	a4,a4,282 # 8000900c <started>
  if(cpuid() == 0){
    80000efa:	c139                	beqz	a0,80000f40 <main+0x5e>
    while(started == 0)
    80000efc:	431c                	lw	a5,0(a4)
    80000efe:	2781                	sext.w	a5,a5
    80000f00:	dff5                	beqz	a5,80000efc <main+0x1a>
      ;
    __sync_synchronize();
    80000f02:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f06:	00001097          	auipc	ra,0x1
    80000f0a:	ad0080e7          	jalr	-1328(ra) # 800019d6 <cpuid>
    80000f0e:	85aa                	mv	a1,a0
    80000f10:	00007517          	auipc	a0,0x7
    80000f14:	1a850513          	addi	a0,a0,424 # 800080b8 <digits+0x78>
    80000f18:	fffff097          	auipc	ra,0xfffff
    80000f1c:	67a080e7          	jalr	1658(ra) # 80000592 <printf>
    kvminithart();    // turn on paging
    80000f20:	00000097          	auipc	ra,0x0
    80000f24:	0d8080e7          	jalr	216(ra) # 80000ff8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f28:	00001097          	auipc	ra,0x1
    80000f2c:	772080e7          	jalr	1906(ra) # 8000269a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f30:	00005097          	auipc	ra,0x5
    80000f34:	dd0080e7          	jalr	-560(ra) # 80005d00 <plicinithart>
  }

  scheduler();        
    80000f38:	00001097          	auipc	ra,0x1
    80000f3c:	00a080e7          	jalr	10(ra) # 80001f42 <scheduler>
    consoleinit();
    80000f40:	fffff097          	auipc	ra,0xfffff
    80000f44:	51a080e7          	jalr	1306(ra) # 8000045a <consoleinit>
    printfinit();
    80000f48:	00000097          	auipc	ra,0x0
    80000f4c:	830080e7          	jalr	-2000(ra) # 80000778 <printfinit>
    printf("\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17850513          	addi	a0,a0,376 # 800080c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	63a080e7          	jalr	1594(ra) # 80000592 <printf>
    printf("xv6 kernel is booting\n");
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	14050513          	addi	a0,a0,320 # 800080a0 <digits+0x60>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	62a080e7          	jalr	1578(ra) # 80000592 <printf>
    printf("\n");
    80000f70:	00007517          	auipc	a0,0x7
    80000f74:	15850513          	addi	a0,a0,344 # 800080c8 <digits+0x88>
    80000f78:	fffff097          	auipc	ra,0xfffff
    80000f7c:	61a080e7          	jalr	1562(ra) # 80000592 <printf>
    kinit();         // physical page allocator
    80000f80:	00000097          	auipc	ra,0x0
    80000f84:	b64080e7          	jalr	-1180(ra) # 80000ae4 <kinit>
    kvminit();       // create kernel page table
    80000f88:	00000097          	auipc	ra,0x0
    80000f8c:	2a0080e7          	jalr	672(ra) # 80001228 <kvminit>
    kvminithart();   // turn on paging
    80000f90:	00000097          	auipc	ra,0x0
    80000f94:	068080e7          	jalr	104(ra) # 80000ff8 <kvminithart>
    procinit();      // process table
    80000f98:	00001097          	auipc	ra,0x1
    80000f9c:	96e080e7          	jalr	-1682(ra) # 80001906 <procinit>
    trapinit();      // trap vectors
    80000fa0:	00001097          	auipc	ra,0x1
    80000fa4:	6d2080e7          	jalr	1746(ra) # 80002672 <trapinit>
    trapinithart();  // install kernel trap vector
    80000fa8:	00001097          	auipc	ra,0x1
    80000fac:	6f2080e7          	jalr	1778(ra) # 8000269a <trapinithart>
    plicinit();      // set up interrupt controller
    80000fb0:	00005097          	auipc	ra,0x5
    80000fb4:	d3a080e7          	jalr	-710(ra) # 80005cea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000fb8:	00005097          	auipc	ra,0x5
    80000fbc:	d48080e7          	jalr	-696(ra) # 80005d00 <plicinithart>
    binit();         // buffer cache
    80000fc0:	00002097          	auipc	ra,0x2
    80000fc4:	eee080e7          	jalr	-274(ra) # 80002eae <binit>
    iinit();         // inode cache
    80000fc8:	00002097          	auipc	ra,0x2
    80000fcc:	57e080e7          	jalr	1406(ra) # 80003546 <iinit>
    fileinit();      // file table
    80000fd0:	00003097          	auipc	ra,0x3
    80000fd4:	518080e7          	jalr	1304(ra) # 800044e8 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fd8:	00005097          	auipc	ra,0x5
    80000fdc:	e30080e7          	jalr	-464(ra) # 80005e08 <virtio_disk_init>
    userinit();      // first user process
    80000fe0:	00001097          	auipc	ra,0x1
    80000fe4:	cf0080e7          	jalr	-784(ra) # 80001cd0 <userinit>
    __sync_synchronize();
    80000fe8:	0ff0000f          	fence
    started = 1;
    80000fec:	4785                	li	a5,1
    80000fee:	00008717          	auipc	a4,0x8
    80000ff2:	00f72f23          	sw	a5,30(a4) # 8000900c <started>
    80000ff6:	b789                	j	80000f38 <main+0x56>

0000000080000ff8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000ff8:	1141                	addi	sp,sp,-16
    80000ffa:	e422                	sd	s0,8(sp)
    80000ffc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80000ffe:	00008797          	auipc	a5,0x8
    80001002:	0127b783          	ld	a5,18(a5) # 80009010 <kernel_pagetable>
    80001006:	83b1                	srli	a5,a5,0xc
    80001008:	577d                	li	a4,-1
    8000100a:	177e                	slli	a4,a4,0x3f
    8000100c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000100e:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001012:	12000073          	sfence.vma
  sfence_vma();
}
    80001016:	6422                	ld	s0,8(sp)
    80001018:	0141                	addi	sp,sp,16
    8000101a:	8082                	ret

000000008000101c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000101c:	7139                	addi	sp,sp,-64
    8000101e:	fc06                	sd	ra,56(sp)
    80001020:	f822                	sd	s0,48(sp)
    80001022:	f426                	sd	s1,40(sp)
    80001024:	f04a                	sd	s2,32(sp)
    80001026:	ec4e                	sd	s3,24(sp)
    80001028:	e852                	sd	s4,16(sp)
    8000102a:	e456                	sd	s5,8(sp)
    8000102c:	e05a                	sd	s6,0(sp)
    8000102e:	0080                	addi	s0,sp,64
    80001030:	84aa                	mv	s1,a0
    80001032:	89ae                	mv	s3,a1
    80001034:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001036:	57fd                	li	a5,-1
    80001038:	83e9                	srli	a5,a5,0x1a
    8000103a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000103c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000103e:	04b7f263          	bgeu	a5,a1,80001082 <walk+0x66>
    panic("walk");
    80001042:	00007517          	auipc	a0,0x7
    80001046:	08e50513          	addi	a0,a0,142 # 800080d0 <digits+0x90>
    8000104a:	fffff097          	auipc	ra,0xfffff
    8000104e:	4fe080e7          	jalr	1278(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001052:	060a8663          	beqz	s5,800010be <walk+0xa2>
    80001056:	00000097          	auipc	ra,0x0
    8000105a:	aca080e7          	jalr	-1334(ra) # 80000b20 <kalloc>
    8000105e:	84aa                	mv	s1,a0
    80001060:	c529                	beqz	a0,800010aa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001062:	6605                	lui	a2,0x1
    80001064:	4581                	li	a1,0
    80001066:	00000097          	auipc	ra,0x0
    8000106a:	cca080e7          	jalr	-822(ra) # 80000d30 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000106e:	00c4d793          	srli	a5,s1,0xc
    80001072:	07aa                	slli	a5,a5,0xa
    80001074:	0017e793          	ori	a5,a5,1
    80001078:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000107c:	3a5d                	addiw	s4,s4,-9
    8000107e:	036a0063          	beq	s4,s6,8000109e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001082:	0149d933          	srl	s2,s3,s4
    80001086:	1ff97913          	andi	s2,s2,511
    8000108a:	090e                	slli	s2,s2,0x3
    8000108c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000108e:	00093483          	ld	s1,0(s2)
    80001092:	0014f793          	andi	a5,s1,1
    80001096:	dfd5                	beqz	a5,80001052 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001098:	80a9                	srli	s1,s1,0xa
    8000109a:	04b2                	slli	s1,s1,0xc
    8000109c:	b7c5                	j	8000107c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000109e:	00c9d513          	srli	a0,s3,0xc
    800010a2:	1ff57513          	andi	a0,a0,511
    800010a6:	050e                	slli	a0,a0,0x3
    800010a8:	9526                	add	a0,a0,s1
}
    800010aa:	70e2                	ld	ra,56(sp)
    800010ac:	7442                	ld	s0,48(sp)
    800010ae:	74a2                	ld	s1,40(sp)
    800010b0:	7902                	ld	s2,32(sp)
    800010b2:	69e2                	ld	s3,24(sp)
    800010b4:	6a42                	ld	s4,16(sp)
    800010b6:	6aa2                	ld	s5,8(sp)
    800010b8:	6b02                	ld	s6,0(sp)
    800010ba:	6121                	addi	sp,sp,64
    800010bc:	8082                	ret
        return 0;
    800010be:	4501                	li	a0,0
    800010c0:	b7ed                	j	800010aa <walk+0x8e>

00000000800010c2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010c2:	57fd                	li	a5,-1
    800010c4:	83e9                	srli	a5,a5,0x1a
    800010c6:	00b7f463          	bgeu	a5,a1,800010ce <walkaddr+0xc>
    return 0;
    800010ca:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010cc:	8082                	ret
{
    800010ce:	1141                	addi	sp,sp,-16
    800010d0:	e406                	sd	ra,8(sp)
    800010d2:	e022                	sd	s0,0(sp)
    800010d4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010d6:	4601                	li	a2,0
    800010d8:	00000097          	auipc	ra,0x0
    800010dc:	f44080e7          	jalr	-188(ra) # 8000101c <walk>
  if(pte == 0)
    800010e0:	c105                	beqz	a0,80001100 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010e2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010e4:	0117f693          	andi	a3,a5,17
    800010e8:	4745                	li	a4,17
    return 0;
    800010ea:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010ec:	00e68663          	beq	a3,a4,800010f8 <walkaddr+0x36>
}
    800010f0:	60a2                	ld	ra,8(sp)
    800010f2:	6402                	ld	s0,0(sp)
    800010f4:	0141                	addi	sp,sp,16
    800010f6:	8082                	ret
  pa = PTE2PA(*pte);
    800010f8:	00a7d513          	srli	a0,a5,0xa
    800010fc:	0532                	slli	a0,a0,0xc
  return pa;
    800010fe:	bfcd                	j	800010f0 <walkaddr+0x2e>
    return 0;
    80001100:	4501                	li	a0,0
    80001102:	b7fd                	j	800010f0 <walkaddr+0x2e>

0000000080001104 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001104:	1101                	addi	sp,sp,-32
    80001106:	ec06                	sd	ra,24(sp)
    80001108:	e822                	sd	s0,16(sp)
    8000110a:	e426                	sd	s1,8(sp)
    8000110c:	1000                	addi	s0,sp,32
    8000110e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001110:	1552                	slli	a0,a0,0x34
    80001112:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001116:	4601                	li	a2,0
    80001118:	00008517          	auipc	a0,0x8
    8000111c:	ef853503          	ld	a0,-264(a0) # 80009010 <kernel_pagetable>
    80001120:	00000097          	auipc	ra,0x0
    80001124:	efc080e7          	jalr	-260(ra) # 8000101c <walk>
  if(pte == 0)
    80001128:	cd09                	beqz	a0,80001142 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000112a:	6108                	ld	a0,0(a0)
    8000112c:	00157793          	andi	a5,a0,1
    80001130:	c38d                	beqz	a5,80001152 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001132:	8129                	srli	a0,a0,0xa
    80001134:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001136:	9526                	add	a0,a0,s1
    80001138:	60e2                	ld	ra,24(sp)
    8000113a:	6442                	ld	s0,16(sp)
    8000113c:	64a2                	ld	s1,8(sp)
    8000113e:	6105                	addi	sp,sp,32
    80001140:	8082                	ret
    panic("kvmpa");
    80001142:	00007517          	auipc	a0,0x7
    80001146:	f9650513          	addi	a0,a0,-106 # 800080d8 <digits+0x98>
    8000114a:	fffff097          	auipc	ra,0xfffff
    8000114e:	3fe080e7          	jalr	1022(ra) # 80000548 <panic>
    panic("kvmpa");
    80001152:	00007517          	auipc	a0,0x7
    80001156:	f8650513          	addi	a0,a0,-122 # 800080d8 <digits+0x98>
    8000115a:	fffff097          	auipc	ra,0xfffff
    8000115e:	3ee080e7          	jalr	1006(ra) # 80000548 <panic>

0000000080001162 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    80001162:	715d                	addi	sp,sp,-80
    80001164:	e486                	sd	ra,72(sp)
    80001166:	e0a2                	sd	s0,64(sp)
    80001168:	fc26                	sd	s1,56(sp)
    8000116a:	f84a                	sd	s2,48(sp)
    8000116c:	f44e                	sd	s3,40(sp)
    8000116e:	f052                	sd	s4,32(sp)
    80001170:	ec56                	sd	s5,24(sp)
    80001172:	e85a                	sd	s6,16(sp)
    80001174:	e45e                	sd	s7,8(sp)
    80001176:	0880                	addi	s0,sp,80
    80001178:	8aaa                	mv	s5,a0
    8000117a:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    8000117c:	777d                	lui	a4,0xfffff
    8000117e:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001182:	167d                	addi	a2,a2,-1
    80001184:	00b609b3          	add	s3,a2,a1
    80001188:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000118c:	893e                	mv	s2,a5
    8000118e:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001192:	6b85                	lui	s7,0x1
    80001194:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001198:	4605                	li	a2,1
    8000119a:	85ca                	mv	a1,s2
    8000119c:	8556                	mv	a0,s5
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	e7e080e7          	jalr	-386(ra) # 8000101c <walk>
    800011a6:	c51d                	beqz	a0,800011d4 <mappages+0x72>
    if(*pte & PTE_V)
    800011a8:	611c                	ld	a5,0(a0)
    800011aa:	8b85                	andi	a5,a5,1
    800011ac:	ef81                	bnez	a5,800011c4 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011ae:	80b1                	srli	s1,s1,0xc
    800011b0:	04aa                	slli	s1,s1,0xa
    800011b2:	0164e4b3          	or	s1,s1,s6
    800011b6:	0014e493          	ori	s1,s1,1
    800011ba:	e104                	sd	s1,0(a0)
    if(a == last)
    800011bc:	03390863          	beq	s2,s3,800011ec <mappages+0x8a>
    a += PGSIZE;
    800011c0:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    800011c2:	bfc9                	j	80001194 <mappages+0x32>
      panic("remap");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f1c50513          	addi	a0,a0,-228 # 800080e0 <digits+0xa0>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	37c080e7          	jalr	892(ra) # 80000548 <panic>
      return -1;
    800011d4:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    800011d6:	60a6                	ld	ra,72(sp)
    800011d8:	6406                	ld	s0,64(sp)
    800011da:	74e2                	ld	s1,56(sp)
    800011dc:	7942                	ld	s2,48(sp)
    800011de:	79a2                	ld	s3,40(sp)
    800011e0:	7a02                	ld	s4,32(sp)
    800011e2:	6ae2                	ld	s5,24(sp)
    800011e4:	6b42                	ld	s6,16(sp)
    800011e6:	6ba2                	ld	s7,8(sp)
    800011e8:	6161                	addi	sp,sp,80
    800011ea:	8082                	ret
  return 0;
    800011ec:	4501                	li	a0,0
    800011ee:	b7e5                	j	800011d6 <mappages+0x74>

00000000800011f0 <kvmmap>:
{
    800011f0:	1141                	addi	sp,sp,-16
    800011f2:	e406                	sd	ra,8(sp)
    800011f4:	e022                	sd	s0,0(sp)
    800011f6:	0800                	addi	s0,sp,16
    800011f8:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800011fa:	86ae                	mv	a3,a1
    800011fc:	85aa                	mv	a1,a0
    800011fe:	00008517          	auipc	a0,0x8
    80001202:	e1253503          	ld	a0,-494(a0) # 80009010 <kernel_pagetable>
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f5c080e7          	jalr	-164(ra) # 80001162 <mappages>
    8000120e:	e509                	bnez	a0,80001218 <kvmmap+0x28>
}
    80001210:	60a2                	ld	ra,8(sp)
    80001212:	6402                	ld	s0,0(sp)
    80001214:	0141                	addi	sp,sp,16
    80001216:	8082                	ret
    panic("kvmmap");
    80001218:	00007517          	auipc	a0,0x7
    8000121c:	ed050513          	addi	a0,a0,-304 # 800080e8 <digits+0xa8>
    80001220:	fffff097          	auipc	ra,0xfffff
    80001224:	328080e7          	jalr	808(ra) # 80000548 <panic>

0000000080001228 <kvminit>:
{
    80001228:	1101                	addi	sp,sp,-32
    8000122a:	ec06                	sd	ra,24(sp)
    8000122c:	e822                	sd	s0,16(sp)
    8000122e:	e426                	sd	s1,8(sp)
    80001230:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001232:	00000097          	auipc	ra,0x0
    80001236:	8ee080e7          	jalr	-1810(ra) # 80000b20 <kalloc>
    8000123a:	00008797          	auipc	a5,0x8
    8000123e:	dca7bb23          	sd	a0,-554(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001242:	6605                	lui	a2,0x1
    80001244:	4581                	li	a1,0
    80001246:	00000097          	auipc	ra,0x0
    8000124a:	aea080e7          	jalr	-1302(ra) # 80000d30 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000124e:	4699                	li	a3,6
    80001250:	6605                	lui	a2,0x1
    80001252:	100005b7          	lui	a1,0x10000
    80001256:	10000537          	lui	a0,0x10000
    8000125a:	00000097          	auipc	ra,0x0
    8000125e:	f96080e7          	jalr	-106(ra) # 800011f0 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001262:	4699                	li	a3,6
    80001264:	6605                	lui	a2,0x1
    80001266:	100015b7          	lui	a1,0x10001
    8000126a:	10001537          	lui	a0,0x10001
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f82080e7          	jalr	-126(ra) # 800011f0 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    80001276:	4699                	li	a3,6
    80001278:	6641                	lui	a2,0x10
    8000127a:	020005b7          	lui	a1,0x2000
    8000127e:	02000537          	lui	a0,0x2000
    80001282:	00000097          	auipc	ra,0x0
    80001286:	f6e080e7          	jalr	-146(ra) # 800011f0 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000128a:	4699                	li	a3,6
    8000128c:	00400637          	lui	a2,0x400
    80001290:	0c0005b7          	lui	a1,0xc000
    80001294:	0c000537          	lui	a0,0xc000
    80001298:	00000097          	auipc	ra,0x0
    8000129c:	f58080e7          	jalr	-168(ra) # 800011f0 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012a0:	00007497          	auipc	s1,0x7
    800012a4:	d6048493          	addi	s1,s1,-672 # 80008000 <etext>
    800012a8:	46a9                	li	a3,10
    800012aa:	80007617          	auipc	a2,0x80007
    800012ae:	d5660613          	addi	a2,a2,-682 # 8000 <_entry-0x7fff8000>
    800012b2:	4585                	li	a1,1
    800012b4:	05fe                	slli	a1,a1,0x1f
    800012b6:	852e                	mv	a0,a1
    800012b8:	00000097          	auipc	ra,0x0
    800012bc:	f38080e7          	jalr	-200(ra) # 800011f0 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800012c0:	4699                	li	a3,6
    800012c2:	4645                	li	a2,17
    800012c4:	066e                	slli	a2,a2,0x1b
    800012c6:	8e05                	sub	a2,a2,s1
    800012c8:	85a6                	mv	a1,s1
    800012ca:	8526                	mv	a0,s1
    800012cc:	00000097          	auipc	ra,0x0
    800012d0:	f24080e7          	jalr	-220(ra) # 800011f0 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800012d4:	46a9                	li	a3,10
    800012d6:	6605                	lui	a2,0x1
    800012d8:	00006597          	auipc	a1,0x6
    800012dc:	d2858593          	addi	a1,a1,-728 # 80007000 <_trampoline>
    800012e0:	04000537          	lui	a0,0x4000
    800012e4:	157d                	addi	a0,a0,-1
    800012e6:	0532                	slli	a0,a0,0xc
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f08080e7          	jalr	-248(ra) # 800011f0 <kvmmap>
}
    800012f0:	60e2                	ld	ra,24(sp)
    800012f2:	6442                	ld	s0,16(sp)
    800012f4:	64a2                	ld	s1,8(sp)
    800012f6:	6105                	addi	sp,sp,32
    800012f8:	8082                	ret

00000000800012fa <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012fa:	715d                	addi	sp,sp,-80
    800012fc:	e486                	sd	ra,72(sp)
    800012fe:	e0a2                	sd	s0,64(sp)
    80001300:	fc26                	sd	s1,56(sp)
    80001302:	f84a                	sd	s2,48(sp)
    80001304:	f44e                	sd	s3,40(sp)
    80001306:	f052                	sd	s4,32(sp)
    80001308:	ec56                	sd	s5,24(sp)
    8000130a:	e85a                	sd	s6,16(sp)
    8000130c:	e45e                	sd	s7,8(sp)
    8000130e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001310:	03459793          	slli	a5,a1,0x34
    80001314:	e795                	bnez	a5,80001340 <uvmunmap+0x46>
    80001316:	8a2a                	mv	s4,a0
    80001318:	892e                	mv	s2,a1
    8000131a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000131c:	0632                	slli	a2,a2,0xc
    8000131e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001322:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001324:	6b05                	lui	s6,0x1
    80001326:	0735e863          	bltu	a1,s3,80001396 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000132a:	60a6                	ld	ra,72(sp)
    8000132c:	6406                	ld	s0,64(sp)
    8000132e:	74e2                	ld	s1,56(sp)
    80001330:	7942                	ld	s2,48(sp)
    80001332:	79a2                	ld	s3,40(sp)
    80001334:	7a02                	ld	s4,32(sp)
    80001336:	6ae2                	ld	s5,24(sp)
    80001338:	6b42                	ld	s6,16(sp)
    8000133a:	6ba2                	ld	s7,8(sp)
    8000133c:	6161                	addi	sp,sp,80
    8000133e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001340:	00007517          	auipc	a0,0x7
    80001344:	db050513          	addi	a0,a0,-592 # 800080f0 <digits+0xb0>
    80001348:	fffff097          	auipc	ra,0xfffff
    8000134c:	200080e7          	jalr	512(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    80001350:	00007517          	auipc	a0,0x7
    80001354:	db850513          	addi	a0,a0,-584 # 80008108 <digits+0xc8>
    80001358:	fffff097          	auipc	ra,0xfffff
    8000135c:	1f0080e7          	jalr	496(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    80001360:	00007517          	auipc	a0,0x7
    80001364:	db850513          	addi	a0,a0,-584 # 80008118 <digits+0xd8>
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	1e0080e7          	jalr	480(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    80001370:	00007517          	auipc	a0,0x7
    80001374:	dc050513          	addi	a0,a0,-576 # 80008130 <digits+0xf0>
    80001378:	fffff097          	auipc	ra,0xfffff
    8000137c:	1d0080e7          	jalr	464(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    80001380:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001382:	0532                	slli	a0,a0,0xc
    80001384:	fffff097          	auipc	ra,0xfffff
    80001388:	6a0080e7          	jalr	1696(ra) # 80000a24 <kfree>
    *pte = 0;
    8000138c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001390:	995a                	add	s2,s2,s6
    80001392:	f9397ce3          	bgeu	s2,s3,8000132a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001396:	4601                	li	a2,0
    80001398:	85ca                	mv	a1,s2
    8000139a:	8552                	mv	a0,s4
    8000139c:	00000097          	auipc	ra,0x0
    800013a0:	c80080e7          	jalr	-896(ra) # 8000101c <walk>
    800013a4:	84aa                	mv	s1,a0
    800013a6:	d54d                	beqz	a0,80001350 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013a8:	6108                	ld	a0,0(a0)
    800013aa:	00157793          	andi	a5,a0,1
    800013ae:	dbcd                	beqz	a5,80001360 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    800013b0:	3ff57793          	andi	a5,a0,1023
    800013b4:	fb778ee3          	beq	a5,s7,80001370 <uvmunmap+0x76>
    if(do_free){
    800013b8:	fc0a8ae3          	beqz	s5,8000138c <uvmunmap+0x92>
    800013bc:	b7d1                	j	80001380 <uvmunmap+0x86>

00000000800013be <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800013be:	1101                	addi	sp,sp,-32
    800013c0:	ec06                	sd	ra,24(sp)
    800013c2:	e822                	sd	s0,16(sp)
    800013c4:	e426                	sd	s1,8(sp)
    800013c6:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	758080e7          	jalr	1880(ra) # 80000b20 <kalloc>
    800013d0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800013d2:	c519                	beqz	a0,800013e0 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800013d4:	6605                	lui	a2,0x1
    800013d6:	4581                	li	a1,0
    800013d8:	00000097          	auipc	ra,0x0
    800013dc:	958080e7          	jalr	-1704(ra) # 80000d30 <memset>
  return pagetable;
}
    800013e0:	8526                	mv	a0,s1
    800013e2:	60e2                	ld	ra,24(sp)
    800013e4:	6442                	ld	s0,16(sp)
    800013e6:	64a2                	ld	s1,8(sp)
    800013e8:	6105                	addi	sp,sp,32
    800013ea:	8082                	ret

00000000800013ec <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800013ec:	7179                	addi	sp,sp,-48
    800013ee:	f406                	sd	ra,40(sp)
    800013f0:	f022                	sd	s0,32(sp)
    800013f2:	ec26                	sd	s1,24(sp)
    800013f4:	e84a                	sd	s2,16(sp)
    800013f6:	e44e                	sd	s3,8(sp)
    800013f8:	e052                	sd	s4,0(sp)
    800013fa:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013fc:	6785                	lui	a5,0x1
    800013fe:	04f67863          	bgeu	a2,a5,8000144e <uvminit+0x62>
    80001402:	8a2a                	mv	s4,a0
    80001404:	89ae                	mv	s3,a1
    80001406:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001408:	fffff097          	auipc	ra,0xfffff
    8000140c:	718080e7          	jalr	1816(ra) # 80000b20 <kalloc>
    80001410:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001412:	6605                	lui	a2,0x1
    80001414:	4581                	li	a1,0
    80001416:	00000097          	auipc	ra,0x0
    8000141a:	91a080e7          	jalr	-1766(ra) # 80000d30 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000141e:	4779                	li	a4,30
    80001420:	86ca                	mv	a3,s2
    80001422:	6605                	lui	a2,0x1
    80001424:	4581                	li	a1,0
    80001426:	8552                	mv	a0,s4
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	d3a080e7          	jalr	-710(ra) # 80001162 <mappages>
  memmove(mem, src, sz);
    80001430:	8626                	mv	a2,s1
    80001432:	85ce                	mv	a1,s3
    80001434:	854a                	mv	a0,s2
    80001436:	00000097          	auipc	ra,0x0
    8000143a:	95a080e7          	jalr	-1702(ra) # 80000d90 <memmove>
}
    8000143e:	70a2                	ld	ra,40(sp)
    80001440:	7402                	ld	s0,32(sp)
    80001442:	64e2                	ld	s1,24(sp)
    80001444:	6942                	ld	s2,16(sp)
    80001446:	69a2                	ld	s3,8(sp)
    80001448:	6a02                	ld	s4,0(sp)
    8000144a:	6145                	addi	sp,sp,48
    8000144c:	8082                	ret
    panic("inituvm: more than a page");
    8000144e:	00007517          	auipc	a0,0x7
    80001452:	cfa50513          	addi	a0,a0,-774 # 80008148 <digits+0x108>
    80001456:	fffff097          	auipc	ra,0xfffff
    8000145a:	0f2080e7          	jalr	242(ra) # 80000548 <panic>

000000008000145e <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    8000145e:	1101                	addi	sp,sp,-32
    80001460:	ec06                	sd	ra,24(sp)
    80001462:	e822                	sd	s0,16(sp)
    80001464:	e426                	sd	s1,8(sp)
    80001466:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    80001468:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000146a:	00b67d63          	bgeu	a2,a1,80001484 <uvmdealloc+0x26>
    8000146e:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001470:	6785                	lui	a5,0x1
    80001472:	17fd                	addi	a5,a5,-1
    80001474:	00f60733          	add	a4,a2,a5
    80001478:	767d                	lui	a2,0xfffff
    8000147a:	8f71                	and	a4,a4,a2
    8000147c:	97ae                	add	a5,a5,a1
    8000147e:	8ff1                	and	a5,a5,a2
    80001480:	00f76863          	bltu	a4,a5,80001490 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001484:	8526                	mv	a0,s1
    80001486:	60e2                	ld	ra,24(sp)
    80001488:	6442                	ld	s0,16(sp)
    8000148a:	64a2                	ld	s1,8(sp)
    8000148c:	6105                	addi	sp,sp,32
    8000148e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001490:	8f99                	sub	a5,a5,a4
    80001492:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001494:	4685                	li	a3,1
    80001496:	0007861b          	sext.w	a2,a5
    8000149a:	85ba                	mv	a1,a4
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	e5e080e7          	jalr	-418(ra) # 800012fa <uvmunmap>
    800014a4:	b7c5                	j	80001484 <uvmdealloc+0x26>

00000000800014a6 <uvmalloc>:
  if(newsz < oldsz)
    800014a6:	0ab66163          	bltu	a2,a1,80001548 <uvmalloc+0xa2>
{
    800014aa:	7139                	addi	sp,sp,-64
    800014ac:	fc06                	sd	ra,56(sp)
    800014ae:	f822                	sd	s0,48(sp)
    800014b0:	f426                	sd	s1,40(sp)
    800014b2:	f04a                	sd	s2,32(sp)
    800014b4:	ec4e                	sd	s3,24(sp)
    800014b6:	e852                	sd	s4,16(sp)
    800014b8:	e456                	sd	s5,8(sp)
    800014ba:	0080                	addi	s0,sp,64
    800014bc:	8aaa                	mv	s5,a0
    800014be:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800014c0:	6985                	lui	s3,0x1
    800014c2:	19fd                	addi	s3,s3,-1
    800014c4:	95ce                	add	a1,a1,s3
    800014c6:	79fd                	lui	s3,0xfffff
    800014c8:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014cc:	08c9f063          	bgeu	s3,a2,8000154c <uvmalloc+0xa6>
    800014d0:	894e                	mv	s2,s3
    mem = kalloc();
    800014d2:	fffff097          	auipc	ra,0xfffff
    800014d6:	64e080e7          	jalr	1614(ra) # 80000b20 <kalloc>
    800014da:	84aa                	mv	s1,a0
    if(mem == 0){
    800014dc:	c51d                	beqz	a0,8000150a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800014de:	6605                	lui	a2,0x1
    800014e0:	4581                	li	a1,0
    800014e2:	00000097          	auipc	ra,0x0
    800014e6:	84e080e7          	jalr	-1970(ra) # 80000d30 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800014ea:	4779                	li	a4,30
    800014ec:	86a6                	mv	a3,s1
    800014ee:	6605                	lui	a2,0x1
    800014f0:	85ca                	mv	a1,s2
    800014f2:	8556                	mv	a0,s5
    800014f4:	00000097          	auipc	ra,0x0
    800014f8:	c6e080e7          	jalr	-914(ra) # 80001162 <mappages>
    800014fc:	e905                	bnez	a0,8000152c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014fe:	6785                	lui	a5,0x1
    80001500:	993e                	add	s2,s2,a5
    80001502:	fd4968e3          	bltu	s2,s4,800014d2 <uvmalloc+0x2c>
  return newsz;
    80001506:	8552                	mv	a0,s4
    80001508:	a809                	j	8000151a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000150a:	864e                	mv	a2,s3
    8000150c:	85ca                	mv	a1,s2
    8000150e:	8556                	mv	a0,s5
    80001510:	00000097          	auipc	ra,0x0
    80001514:	f4e080e7          	jalr	-178(ra) # 8000145e <uvmdealloc>
      return 0;
    80001518:	4501                	li	a0,0
}
    8000151a:	70e2                	ld	ra,56(sp)
    8000151c:	7442                	ld	s0,48(sp)
    8000151e:	74a2                	ld	s1,40(sp)
    80001520:	7902                	ld	s2,32(sp)
    80001522:	69e2                	ld	s3,24(sp)
    80001524:	6a42                	ld	s4,16(sp)
    80001526:	6aa2                	ld	s5,8(sp)
    80001528:	6121                	addi	sp,sp,64
    8000152a:	8082                	ret
      kfree(mem);
    8000152c:	8526                	mv	a0,s1
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	4f6080e7          	jalr	1270(ra) # 80000a24 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001536:	864e                	mv	a2,s3
    80001538:	85ca                	mv	a1,s2
    8000153a:	8556                	mv	a0,s5
    8000153c:	00000097          	auipc	ra,0x0
    80001540:	f22080e7          	jalr	-222(ra) # 8000145e <uvmdealloc>
      return 0;
    80001544:	4501                	li	a0,0
    80001546:	bfd1                	j	8000151a <uvmalloc+0x74>
    return oldsz;
    80001548:	852e                	mv	a0,a1
}
    8000154a:	8082                	ret
  return newsz;
    8000154c:	8532                	mv	a0,a2
    8000154e:	b7f1                	j	8000151a <uvmalloc+0x74>

0000000080001550 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001550:	7179                	addi	sp,sp,-48
    80001552:	f406                	sd	ra,40(sp)
    80001554:	f022                	sd	s0,32(sp)
    80001556:	ec26                	sd	s1,24(sp)
    80001558:	e84a                	sd	s2,16(sp)
    8000155a:	e44e                	sd	s3,8(sp)
    8000155c:	e052                	sd	s4,0(sp)
    8000155e:	1800                	addi	s0,sp,48
    80001560:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001562:	84aa                	mv	s1,a0
    80001564:	6905                	lui	s2,0x1
    80001566:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001568:	4985                	li	s3,1
    8000156a:	a821                	j	80001582 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    8000156c:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    8000156e:	0532                	slli	a0,a0,0xc
    80001570:	00000097          	auipc	ra,0x0
    80001574:	fe0080e7          	jalr	-32(ra) # 80001550 <freewalk>
      pagetable[i] = 0;
    80001578:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000157c:	04a1                	addi	s1,s1,8
    8000157e:	03248163          	beq	s1,s2,800015a0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001582:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001584:	00f57793          	andi	a5,a0,15
    80001588:	ff3782e3          	beq	a5,s3,8000156c <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000158c:	8905                	andi	a0,a0,1
    8000158e:	d57d                	beqz	a0,8000157c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001590:	00007517          	auipc	a0,0x7
    80001594:	bd850513          	addi	a0,a0,-1064 # 80008168 <digits+0x128>
    80001598:	fffff097          	auipc	ra,0xfffff
    8000159c:	fb0080e7          	jalr	-80(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015a0:	8552                	mv	a0,s4
    800015a2:	fffff097          	auipc	ra,0xfffff
    800015a6:	482080e7          	jalr	1154(ra) # 80000a24 <kfree>
}
    800015aa:	70a2                	ld	ra,40(sp)
    800015ac:	7402                	ld	s0,32(sp)
    800015ae:	64e2                	ld	s1,24(sp)
    800015b0:	6942                	ld	s2,16(sp)
    800015b2:	69a2                	ld	s3,8(sp)
    800015b4:	6a02                	ld	s4,0(sp)
    800015b6:	6145                	addi	sp,sp,48
    800015b8:	8082                	ret

00000000800015ba <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800015ba:	1101                	addi	sp,sp,-32
    800015bc:	ec06                	sd	ra,24(sp)
    800015be:	e822                	sd	s0,16(sp)
    800015c0:	e426                	sd	s1,8(sp)
    800015c2:	1000                	addi	s0,sp,32
    800015c4:	84aa                	mv	s1,a0
  if(sz > 0)
    800015c6:	e999                	bnez	a1,800015dc <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800015c8:	8526                	mv	a0,s1
    800015ca:	00000097          	auipc	ra,0x0
    800015ce:	f86080e7          	jalr	-122(ra) # 80001550 <freewalk>
}
    800015d2:	60e2                	ld	ra,24(sp)
    800015d4:	6442                	ld	s0,16(sp)
    800015d6:	64a2                	ld	s1,8(sp)
    800015d8:	6105                	addi	sp,sp,32
    800015da:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800015dc:	6605                	lui	a2,0x1
    800015de:	167d                	addi	a2,a2,-1
    800015e0:	962e                	add	a2,a2,a1
    800015e2:	4685                	li	a3,1
    800015e4:	8231                	srli	a2,a2,0xc
    800015e6:	4581                	li	a1,0
    800015e8:	00000097          	auipc	ra,0x0
    800015ec:	d12080e7          	jalr	-750(ra) # 800012fa <uvmunmap>
    800015f0:	bfe1                	j	800015c8 <uvmfree+0xe>

00000000800015f2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015f2:	c679                	beqz	a2,800016c0 <uvmcopy+0xce>
{
    800015f4:	715d                	addi	sp,sp,-80
    800015f6:	e486                	sd	ra,72(sp)
    800015f8:	e0a2                	sd	s0,64(sp)
    800015fa:	fc26                	sd	s1,56(sp)
    800015fc:	f84a                	sd	s2,48(sp)
    800015fe:	f44e                	sd	s3,40(sp)
    80001600:	f052                	sd	s4,32(sp)
    80001602:	ec56                	sd	s5,24(sp)
    80001604:	e85a                	sd	s6,16(sp)
    80001606:	e45e                	sd	s7,8(sp)
    80001608:	0880                	addi	s0,sp,80
    8000160a:	8b2a                	mv	s6,a0
    8000160c:	8aae                	mv	s5,a1
    8000160e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001610:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001612:	4601                	li	a2,0
    80001614:	85ce                	mv	a1,s3
    80001616:	855a                	mv	a0,s6
    80001618:	00000097          	auipc	ra,0x0
    8000161c:	a04080e7          	jalr	-1532(ra) # 8000101c <walk>
    80001620:	c531                	beqz	a0,8000166c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001622:	6118                	ld	a4,0(a0)
    80001624:	00177793          	andi	a5,a4,1
    80001628:	cbb1                	beqz	a5,8000167c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000162a:	00a75593          	srli	a1,a4,0xa
    8000162e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001632:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001636:	fffff097          	auipc	ra,0xfffff
    8000163a:	4ea080e7          	jalr	1258(ra) # 80000b20 <kalloc>
    8000163e:	892a                	mv	s2,a0
    80001640:	c939                	beqz	a0,80001696 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001642:	6605                	lui	a2,0x1
    80001644:	85de                	mv	a1,s7
    80001646:	fffff097          	auipc	ra,0xfffff
    8000164a:	74a080e7          	jalr	1866(ra) # 80000d90 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000164e:	8726                	mv	a4,s1
    80001650:	86ca                	mv	a3,s2
    80001652:	6605                	lui	a2,0x1
    80001654:	85ce                	mv	a1,s3
    80001656:	8556                	mv	a0,s5
    80001658:	00000097          	auipc	ra,0x0
    8000165c:	b0a080e7          	jalr	-1270(ra) # 80001162 <mappages>
    80001660:	e515                	bnez	a0,8000168c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001662:	6785                	lui	a5,0x1
    80001664:	99be                	add	s3,s3,a5
    80001666:	fb49e6e3          	bltu	s3,s4,80001612 <uvmcopy+0x20>
    8000166a:	a081                	j	800016aa <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000166c:	00007517          	auipc	a0,0x7
    80001670:	b0c50513          	addi	a0,a0,-1268 # 80008178 <digits+0x138>
    80001674:	fffff097          	auipc	ra,0xfffff
    80001678:	ed4080e7          	jalr	-300(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    8000167c:	00007517          	auipc	a0,0x7
    80001680:	b1c50513          	addi	a0,a0,-1252 # 80008198 <digits+0x158>
    80001684:	fffff097          	auipc	ra,0xfffff
    80001688:	ec4080e7          	jalr	-316(ra) # 80000548 <panic>
      kfree(mem);
    8000168c:	854a                	mv	a0,s2
    8000168e:	fffff097          	auipc	ra,0xfffff
    80001692:	396080e7          	jalr	918(ra) # 80000a24 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001696:	4685                	li	a3,1
    80001698:	00c9d613          	srli	a2,s3,0xc
    8000169c:	4581                	li	a1,0
    8000169e:	8556                	mv	a0,s5
    800016a0:	00000097          	auipc	ra,0x0
    800016a4:	c5a080e7          	jalr	-934(ra) # 800012fa <uvmunmap>
  return -1;
    800016a8:	557d                	li	a0,-1
}
    800016aa:	60a6                	ld	ra,72(sp)
    800016ac:	6406                	ld	s0,64(sp)
    800016ae:	74e2                	ld	s1,56(sp)
    800016b0:	7942                	ld	s2,48(sp)
    800016b2:	79a2                	ld	s3,40(sp)
    800016b4:	7a02                	ld	s4,32(sp)
    800016b6:	6ae2                	ld	s5,24(sp)
    800016b8:	6b42                	ld	s6,16(sp)
    800016ba:	6ba2                	ld	s7,8(sp)
    800016bc:	6161                	addi	sp,sp,80
    800016be:	8082                	ret
  return 0;
    800016c0:	4501                	li	a0,0
}
    800016c2:	8082                	ret

00000000800016c4 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800016c4:	1141                	addi	sp,sp,-16
    800016c6:	e406                	sd	ra,8(sp)
    800016c8:	e022                	sd	s0,0(sp)
    800016ca:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800016cc:	4601                	li	a2,0
    800016ce:	00000097          	auipc	ra,0x0
    800016d2:	94e080e7          	jalr	-1714(ra) # 8000101c <walk>
  if(pte == 0)
    800016d6:	c901                	beqz	a0,800016e6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800016d8:	611c                	ld	a5,0(a0)
    800016da:	9bbd                	andi	a5,a5,-17
    800016dc:	e11c                	sd	a5,0(a0)
}
    800016de:	60a2                	ld	ra,8(sp)
    800016e0:	6402                	ld	s0,0(sp)
    800016e2:	0141                	addi	sp,sp,16
    800016e4:	8082                	ret
    panic("uvmclear");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	ad250513          	addi	a0,a0,-1326 # 800081b8 <digits+0x178>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e5a080e7          	jalr	-422(ra) # 80000548 <panic>

00000000800016f6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f6:	c6bd                	beqz	a3,80001764 <copyout+0x6e>
{
    800016f8:	715d                	addi	sp,sp,-80
    800016fa:	e486                	sd	ra,72(sp)
    800016fc:	e0a2                	sd	s0,64(sp)
    800016fe:	fc26                	sd	s1,56(sp)
    80001700:	f84a                	sd	s2,48(sp)
    80001702:	f44e                	sd	s3,40(sp)
    80001704:	f052                	sd	s4,32(sp)
    80001706:	ec56                	sd	s5,24(sp)
    80001708:	e85a                	sd	s6,16(sp)
    8000170a:	e45e                	sd	s7,8(sp)
    8000170c:	e062                	sd	s8,0(sp)
    8000170e:	0880                	addi	s0,sp,80
    80001710:	8b2a                	mv	s6,a0
    80001712:	8c2e                	mv	s8,a1
    80001714:	8a32                	mv	s4,a2
    80001716:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001718:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000171a:	6a85                	lui	s5,0x1
    8000171c:	a015                	j	80001740 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000171e:	9562                	add	a0,a0,s8
    80001720:	0004861b          	sext.w	a2,s1
    80001724:	85d2                	mv	a1,s4
    80001726:	41250533          	sub	a0,a0,s2
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	666080e7          	jalr	1638(ra) # 80000d90 <memmove>

    len -= n;
    80001732:	409989b3          	sub	s3,s3,s1
    src += n;
    80001736:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001738:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000173c:	02098263          	beqz	s3,80001760 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001740:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001744:	85ca                	mv	a1,s2
    80001746:	855a                	mv	a0,s6
    80001748:	00000097          	auipc	ra,0x0
    8000174c:	97a080e7          	jalr	-1670(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    80001750:	cd01                	beqz	a0,80001768 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001752:	418904b3          	sub	s1,s2,s8
    80001756:	94d6                	add	s1,s1,s5
    if(n > len)
    80001758:	fc99f3e3          	bgeu	s3,s1,8000171e <copyout+0x28>
    8000175c:	84ce                	mv	s1,s3
    8000175e:	b7c1                	j	8000171e <copyout+0x28>
  }
  return 0;
    80001760:	4501                	li	a0,0
    80001762:	a021                	j	8000176a <copyout+0x74>
    80001764:	4501                	li	a0,0
}
    80001766:	8082                	ret
      return -1;
    80001768:	557d                	li	a0,-1
}
    8000176a:	60a6                	ld	ra,72(sp)
    8000176c:	6406                	ld	s0,64(sp)
    8000176e:	74e2                	ld	s1,56(sp)
    80001770:	7942                	ld	s2,48(sp)
    80001772:	79a2                	ld	s3,40(sp)
    80001774:	7a02                	ld	s4,32(sp)
    80001776:	6ae2                	ld	s5,24(sp)
    80001778:	6b42                	ld	s6,16(sp)
    8000177a:	6ba2                	ld	s7,8(sp)
    8000177c:	6c02                	ld	s8,0(sp)
    8000177e:	6161                	addi	sp,sp,80
    80001780:	8082                	ret

0000000080001782 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001782:	c6bd                	beqz	a3,800017f0 <copyin+0x6e>
{
    80001784:	715d                	addi	sp,sp,-80
    80001786:	e486                	sd	ra,72(sp)
    80001788:	e0a2                	sd	s0,64(sp)
    8000178a:	fc26                	sd	s1,56(sp)
    8000178c:	f84a                	sd	s2,48(sp)
    8000178e:	f44e                	sd	s3,40(sp)
    80001790:	f052                	sd	s4,32(sp)
    80001792:	ec56                	sd	s5,24(sp)
    80001794:	e85a                	sd	s6,16(sp)
    80001796:	e45e                	sd	s7,8(sp)
    80001798:	e062                	sd	s8,0(sp)
    8000179a:	0880                	addi	s0,sp,80
    8000179c:	8b2a                	mv	s6,a0
    8000179e:	8a2e                	mv	s4,a1
    800017a0:	8c32                	mv	s8,a2
    800017a2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017a4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a6:	6a85                	lui	s5,0x1
    800017a8:	a015                	j	800017cc <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017aa:	9562                	add	a0,a0,s8
    800017ac:	0004861b          	sext.w	a2,s1
    800017b0:	412505b3          	sub	a1,a0,s2
    800017b4:	8552                	mv	a0,s4
    800017b6:	fffff097          	auipc	ra,0xfffff
    800017ba:	5da080e7          	jalr	1498(ra) # 80000d90 <memmove>

    len -= n;
    800017be:	409989b3          	sub	s3,s3,s1
    dst += n;
    800017c2:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800017c4:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800017c8:	02098263          	beqz	s3,800017ec <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800017cc:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800017d0:	85ca                	mv	a1,s2
    800017d2:	855a                	mv	a0,s6
    800017d4:	00000097          	auipc	ra,0x0
    800017d8:	8ee080e7          	jalr	-1810(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    800017dc:	cd01                	beqz	a0,800017f4 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800017de:	418904b3          	sub	s1,s2,s8
    800017e2:	94d6                	add	s1,s1,s5
    if(n > len)
    800017e4:	fc99f3e3          	bgeu	s3,s1,800017aa <copyin+0x28>
    800017e8:	84ce                	mv	s1,s3
    800017ea:	b7c1                	j	800017aa <copyin+0x28>
  }
  return 0;
    800017ec:	4501                	li	a0,0
    800017ee:	a021                	j	800017f6 <copyin+0x74>
    800017f0:	4501                	li	a0,0
}
    800017f2:	8082                	ret
      return -1;
    800017f4:	557d                	li	a0,-1
}
    800017f6:	60a6                	ld	ra,72(sp)
    800017f8:	6406                	ld	s0,64(sp)
    800017fa:	74e2                	ld	s1,56(sp)
    800017fc:	7942                	ld	s2,48(sp)
    800017fe:	79a2                	ld	s3,40(sp)
    80001800:	7a02                	ld	s4,32(sp)
    80001802:	6ae2                	ld	s5,24(sp)
    80001804:	6b42                	ld	s6,16(sp)
    80001806:	6ba2                	ld	s7,8(sp)
    80001808:	6c02                	ld	s8,0(sp)
    8000180a:	6161                	addi	sp,sp,80
    8000180c:	8082                	ret

000000008000180e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000180e:	c6c5                	beqz	a3,800018b6 <copyinstr+0xa8>
{
    80001810:	715d                	addi	sp,sp,-80
    80001812:	e486                	sd	ra,72(sp)
    80001814:	e0a2                	sd	s0,64(sp)
    80001816:	fc26                	sd	s1,56(sp)
    80001818:	f84a                	sd	s2,48(sp)
    8000181a:	f44e                	sd	s3,40(sp)
    8000181c:	f052                	sd	s4,32(sp)
    8000181e:	ec56                	sd	s5,24(sp)
    80001820:	e85a                	sd	s6,16(sp)
    80001822:	e45e                	sd	s7,8(sp)
    80001824:	0880                	addi	s0,sp,80
    80001826:	8a2a                	mv	s4,a0
    80001828:	8b2e                	mv	s6,a1
    8000182a:	8bb2                	mv	s7,a2
    8000182c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000182e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001830:	6985                	lui	s3,0x1
    80001832:	a035                	j	8000185e <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001834:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001838:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000183a:	0017b793          	seqz	a5,a5
    8000183e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001842:	60a6                	ld	ra,72(sp)
    80001844:	6406                	ld	s0,64(sp)
    80001846:	74e2                	ld	s1,56(sp)
    80001848:	7942                	ld	s2,48(sp)
    8000184a:	79a2                	ld	s3,40(sp)
    8000184c:	7a02                	ld	s4,32(sp)
    8000184e:	6ae2                	ld	s5,24(sp)
    80001850:	6b42                	ld	s6,16(sp)
    80001852:	6ba2                	ld	s7,8(sp)
    80001854:	6161                	addi	sp,sp,80
    80001856:	8082                	ret
    srcva = va0 + PGSIZE;
    80001858:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000185c:	c8a9                	beqz	s1,800018ae <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    8000185e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001862:	85ca                	mv	a1,s2
    80001864:	8552                	mv	a0,s4
    80001866:	00000097          	auipc	ra,0x0
    8000186a:	85c080e7          	jalr	-1956(ra) # 800010c2 <walkaddr>
    if(pa0 == 0)
    8000186e:	c131                	beqz	a0,800018b2 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001870:	41790833          	sub	a6,s2,s7
    80001874:	984e                	add	a6,a6,s3
    if(n > max)
    80001876:	0104f363          	bgeu	s1,a6,8000187c <copyinstr+0x6e>
    8000187a:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000187c:	955e                	add	a0,a0,s7
    8000187e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001882:	fc080be3          	beqz	a6,80001858 <copyinstr+0x4a>
    80001886:	985a                	add	a6,a6,s6
    80001888:	87da                	mv	a5,s6
      if(*p == '\0'){
    8000188a:	41650633          	sub	a2,a0,s6
    8000188e:	14fd                	addi	s1,s1,-1
    80001890:	9b26                	add	s6,s6,s1
    80001892:	00f60733          	add	a4,a2,a5
    80001896:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd9000>
    8000189a:	df49                	beqz	a4,80001834 <copyinstr+0x26>
        *dst = *p;
    8000189c:	00e78023          	sb	a4,0(a5)
      --max;
    800018a0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018a4:	0785                	addi	a5,a5,1
    while(n > 0){
    800018a6:	ff0796e3          	bne	a5,a6,80001892 <copyinstr+0x84>
      dst++;
    800018aa:	8b42                	mv	s6,a6
    800018ac:	b775                	j	80001858 <copyinstr+0x4a>
    800018ae:	4781                	li	a5,0
    800018b0:	b769                	j	8000183a <copyinstr+0x2c>
      return -1;
    800018b2:	557d                	li	a0,-1
    800018b4:	b779                	j	80001842 <copyinstr+0x34>
  int got_null = 0;
    800018b6:	4781                	li	a5,0
  if(got_null){
    800018b8:	0017b793          	seqz	a5,a5
    800018bc:	40f00533          	neg	a0,a5
}
    800018c0:	8082                	ret

00000000800018c2 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    800018c2:	1101                	addi	sp,sp,-32
    800018c4:	ec06                	sd	ra,24(sp)
    800018c6:	e822                	sd	s0,16(sp)
    800018c8:	e426                	sd	s1,8(sp)
    800018ca:	1000                	addi	s0,sp,32
    800018cc:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800018ce:	fffff097          	auipc	ra,0xfffff
    800018d2:	2ec080e7          	jalr	748(ra) # 80000bba <holding>
    800018d6:	c909                	beqz	a0,800018e8 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    800018d8:	749c                	ld	a5,40(s1)
    800018da:	00978f63          	beq	a5,s1,800018f8 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    800018de:	60e2                	ld	ra,24(sp)
    800018e0:	6442                	ld	s0,16(sp)
    800018e2:	64a2                	ld	s1,8(sp)
    800018e4:	6105                	addi	sp,sp,32
    800018e6:	8082                	ret
    panic("wakeup1");
    800018e8:	00007517          	auipc	a0,0x7
    800018ec:	8e050513          	addi	a0,a0,-1824 # 800081c8 <digits+0x188>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	c58080e7          	jalr	-936(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    800018f8:	4c98                	lw	a4,24(s1)
    800018fa:	4785                	li	a5,1
    800018fc:	fef711e3          	bne	a4,a5,800018de <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001900:	4789                	li	a5,2
    80001902:	cc9c                	sw	a5,24(s1)
}
    80001904:	bfe9                	j	800018de <wakeup1+0x1c>

0000000080001906 <procinit>:
{
    80001906:	715d                	addi	sp,sp,-80
    80001908:	e486                	sd	ra,72(sp)
    8000190a:	e0a2                	sd	s0,64(sp)
    8000190c:	fc26                	sd	s1,56(sp)
    8000190e:	f84a                	sd	s2,48(sp)
    80001910:	f44e                	sd	s3,40(sp)
    80001912:	f052                	sd	s4,32(sp)
    80001914:	ec56                	sd	s5,24(sp)
    80001916:	e85a                	sd	s6,16(sp)
    80001918:	e45e                	sd	s7,8(sp)
    8000191a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000191c:	00007597          	auipc	a1,0x7
    80001920:	8b458593          	addi	a1,a1,-1868 # 800081d0 <digits+0x190>
    80001924:	00010517          	auipc	a0,0x10
    80001928:	02c50513          	addi	a0,a0,44 # 80011950 <pid_lock>
    8000192c:	fffff097          	auipc	ra,0xfffff
    80001930:	278080e7          	jalr	632(ra) # 80000ba4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001934:	00010917          	auipc	s2,0x10
    80001938:	43490913          	addi	s2,s2,1076 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000193c:	00007b97          	auipc	s7,0x7
    80001940:	89cb8b93          	addi	s7,s7,-1892 # 800081d8 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001944:	8b4a                	mv	s6,s2
    80001946:	00006a97          	auipc	s5,0x6
    8000194a:	6baa8a93          	addi	s5,s5,1722 # 80008000 <etext>
    8000194e:	040009b7          	lui	s3,0x4000
    80001952:	19fd                	addi	s3,s3,-1
    80001954:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001956:	00016a17          	auipc	s4,0x16
    8000195a:	012a0a13          	addi	s4,s4,18 # 80017968 <tickslock>
      initlock(&p->lock, "proc");
    8000195e:	85de                	mv	a1,s7
    80001960:	854a                	mv	a0,s2
    80001962:	fffff097          	auipc	ra,0xfffff
    80001966:	242080e7          	jalr	578(ra) # 80000ba4 <initlock>
      char *pa = kalloc();
    8000196a:	fffff097          	auipc	ra,0xfffff
    8000196e:	1b6080e7          	jalr	438(ra) # 80000b20 <kalloc>
    80001972:	85aa                	mv	a1,a0
      if(pa == 0)
    80001974:	c929                	beqz	a0,800019c6 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001976:	416904b3          	sub	s1,s2,s6
    8000197a:	8491                	srai	s1,s1,0x4
    8000197c:	000ab783          	ld	a5,0(s5)
    80001980:	02f484b3          	mul	s1,s1,a5
    80001984:	2485                	addiw	s1,s1,1
    80001986:	00d4949b          	slliw	s1,s1,0xd
    8000198a:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000198e:	4699                	li	a3,6
    80001990:	6605                	lui	a2,0x1
    80001992:	8526                	mv	a0,s1
    80001994:	00000097          	auipc	ra,0x0
    80001998:	85c080e7          	jalr	-1956(ra) # 800011f0 <kvmmap>
      p->kstack = va;
    8000199c:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a0:	17090913          	addi	s2,s2,368
    800019a4:	fb491de3          	bne	s2,s4,8000195e <procinit+0x58>
  kvminithart();
    800019a8:	fffff097          	auipc	ra,0xfffff
    800019ac:	650080e7          	jalr	1616(ra) # 80000ff8 <kvminithart>
}
    800019b0:	60a6                	ld	ra,72(sp)
    800019b2:	6406                	ld	s0,64(sp)
    800019b4:	74e2                	ld	s1,56(sp)
    800019b6:	7942                	ld	s2,48(sp)
    800019b8:	79a2                	ld	s3,40(sp)
    800019ba:	7a02                	ld	s4,32(sp)
    800019bc:	6ae2                	ld	s5,24(sp)
    800019be:	6b42                	ld	s6,16(sp)
    800019c0:	6ba2                	ld	s7,8(sp)
    800019c2:	6161                	addi	sp,sp,80
    800019c4:	8082                	ret
        panic("kalloc");
    800019c6:	00007517          	auipc	a0,0x7
    800019ca:	81a50513          	addi	a0,a0,-2022 # 800081e0 <digits+0x1a0>
    800019ce:	fffff097          	auipc	ra,0xfffff
    800019d2:	b7a080e7          	jalr	-1158(ra) # 80000548 <panic>

00000000800019d6 <cpuid>:
{
    800019d6:	1141                	addi	sp,sp,-16
    800019d8:	e422                	sd	s0,8(sp)
    800019da:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019dc:	8512                	mv	a0,tp
}
    800019de:	2501                	sext.w	a0,a0
    800019e0:	6422                	ld	s0,8(sp)
    800019e2:	0141                	addi	sp,sp,16
    800019e4:	8082                	ret

00000000800019e6 <mycpu>:
mycpu(void) {
    800019e6:	1141                	addi	sp,sp,-16
    800019e8:	e422                	sd	s0,8(sp)
    800019ea:	0800                	addi	s0,sp,16
    800019ec:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800019ee:	2781                	sext.w	a5,a5
    800019f0:	079e                	slli	a5,a5,0x7
}
    800019f2:	00010517          	auipc	a0,0x10
    800019f6:	f7650513          	addi	a0,a0,-138 # 80011968 <cpus>
    800019fa:	953e                	add	a0,a0,a5
    800019fc:	6422                	ld	s0,8(sp)
    800019fe:	0141                	addi	sp,sp,16
    80001a00:	8082                	ret

0000000080001a02 <myproc>:
myproc(void) {
    80001a02:	1101                	addi	sp,sp,-32
    80001a04:	ec06                	sd	ra,24(sp)
    80001a06:	e822                	sd	s0,16(sp)
    80001a08:	e426                	sd	s1,8(sp)
    80001a0a:	1000                	addi	s0,sp,32
  push_off();
    80001a0c:	fffff097          	auipc	ra,0xfffff
    80001a10:	1dc080e7          	jalr	476(ra) # 80000be8 <push_off>
    80001a14:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a16:	2781                	sext.w	a5,a5
    80001a18:	079e                	slli	a5,a5,0x7
    80001a1a:	00010717          	auipc	a4,0x10
    80001a1e:	f3670713          	addi	a4,a4,-202 # 80011950 <pid_lock>
    80001a22:	97ba                	add	a5,a5,a4
    80001a24:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a26:	fffff097          	auipc	ra,0xfffff
    80001a2a:	262080e7          	jalr	610(ra) # 80000c88 <pop_off>
}
    80001a2e:	8526                	mv	a0,s1
    80001a30:	60e2                	ld	ra,24(sp)
    80001a32:	6442                	ld	s0,16(sp)
    80001a34:	64a2                	ld	s1,8(sp)
    80001a36:	6105                	addi	sp,sp,32
    80001a38:	8082                	ret

0000000080001a3a <forkret>:
{
    80001a3a:	1141                	addi	sp,sp,-16
    80001a3c:	e406                	sd	ra,8(sp)
    80001a3e:	e022                	sd	s0,0(sp)
    80001a40:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a42:	00000097          	auipc	ra,0x0
    80001a46:	fc0080e7          	jalr	-64(ra) # 80001a02 <myproc>
    80001a4a:	fffff097          	auipc	ra,0xfffff
    80001a4e:	29e080e7          	jalr	670(ra) # 80000ce8 <release>
  if (first) {
    80001a52:	00007797          	auipc	a5,0x7
    80001a56:	f4e7a783          	lw	a5,-178(a5) # 800089a0 <first.1667>
    80001a5a:	eb89                	bnez	a5,80001a6c <forkret+0x32>
  usertrapret();
    80001a5c:	00001097          	auipc	ra,0x1
    80001a60:	c56080e7          	jalr	-938(ra) # 800026b2 <usertrapret>
}
    80001a64:	60a2                	ld	ra,8(sp)
    80001a66:	6402                	ld	s0,0(sp)
    80001a68:	0141                	addi	sp,sp,16
    80001a6a:	8082                	ret
    first = 0;
    80001a6c:	00007797          	auipc	a5,0x7
    80001a70:	f207aa23          	sw	zero,-204(a5) # 800089a0 <first.1667>
    fsinit(ROOTDEV);
    80001a74:	4505                	li	a0,1
    80001a76:	00002097          	auipc	ra,0x2
    80001a7a:	a50080e7          	jalr	-1456(ra) # 800034c6 <fsinit>
    80001a7e:	bff9                	j	80001a5c <forkret+0x22>

0000000080001a80 <allocpid>:
allocpid() {
    80001a80:	1101                	addi	sp,sp,-32
    80001a82:	ec06                	sd	ra,24(sp)
    80001a84:	e822                	sd	s0,16(sp)
    80001a86:	e426                	sd	s1,8(sp)
    80001a88:	e04a                	sd	s2,0(sp)
    80001a8a:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a8c:	00010917          	auipc	s2,0x10
    80001a90:	ec490913          	addi	s2,s2,-316 # 80011950 <pid_lock>
    80001a94:	854a                	mv	a0,s2
    80001a96:	fffff097          	auipc	ra,0xfffff
    80001a9a:	19e080e7          	jalr	414(ra) # 80000c34 <acquire>
  pid = nextpid;
    80001a9e:	00007797          	auipc	a5,0x7
    80001aa2:	f0678793          	addi	a5,a5,-250 # 800089a4 <nextpid>
    80001aa6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001aa8:	0014871b          	addiw	a4,s1,1
    80001aac:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aae:	854a                	mv	a0,s2
    80001ab0:	fffff097          	auipc	ra,0xfffff
    80001ab4:	238080e7          	jalr	568(ra) # 80000ce8 <release>
}
    80001ab8:	8526                	mv	a0,s1
    80001aba:	60e2                	ld	ra,24(sp)
    80001abc:	6442                	ld	s0,16(sp)
    80001abe:	64a2                	ld	s1,8(sp)
    80001ac0:	6902                	ld	s2,0(sp)
    80001ac2:	6105                	addi	sp,sp,32
    80001ac4:	8082                	ret

0000000080001ac6 <proc_pagetable>:
{
    80001ac6:	1101                	addi	sp,sp,-32
    80001ac8:	ec06                	sd	ra,24(sp)
    80001aca:	e822                	sd	s0,16(sp)
    80001acc:	e426                	sd	s1,8(sp)
    80001ace:	e04a                	sd	s2,0(sp)
    80001ad0:	1000                	addi	s0,sp,32
    80001ad2:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	8ea080e7          	jalr	-1814(ra) # 800013be <uvmcreate>
    80001adc:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ade:	c121                	beqz	a0,80001b1e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ae0:	4729                	li	a4,10
    80001ae2:	00005697          	auipc	a3,0x5
    80001ae6:	51e68693          	addi	a3,a3,1310 # 80007000 <_trampoline>
    80001aea:	6605                	lui	a2,0x1
    80001aec:	040005b7          	lui	a1,0x4000
    80001af0:	15fd                	addi	a1,a1,-1
    80001af2:	05b2                	slli	a1,a1,0xc
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	66e080e7          	jalr	1646(ra) # 80001162 <mappages>
    80001afc:	02054863          	bltz	a0,80001b2c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b00:	4719                	li	a4,6
    80001b02:	05893683          	ld	a3,88(s2)
    80001b06:	6605                	lui	a2,0x1
    80001b08:	020005b7          	lui	a1,0x2000
    80001b0c:	15fd                	addi	a1,a1,-1
    80001b0e:	05b6                	slli	a1,a1,0xd
    80001b10:	8526                	mv	a0,s1
    80001b12:	fffff097          	auipc	ra,0xfffff
    80001b16:	650080e7          	jalr	1616(ra) # 80001162 <mappages>
    80001b1a:	02054163          	bltz	a0,80001b3c <proc_pagetable+0x76>
}
    80001b1e:	8526                	mv	a0,s1
    80001b20:	60e2                	ld	ra,24(sp)
    80001b22:	6442                	ld	s0,16(sp)
    80001b24:	64a2                	ld	s1,8(sp)
    80001b26:	6902                	ld	s2,0(sp)
    80001b28:	6105                	addi	sp,sp,32
    80001b2a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b2c:	4581                	li	a1,0
    80001b2e:	8526                	mv	a0,s1
    80001b30:	00000097          	auipc	ra,0x0
    80001b34:	a8a080e7          	jalr	-1398(ra) # 800015ba <uvmfree>
    return 0;
    80001b38:	4481                	li	s1,0
    80001b3a:	b7d5                	j	80001b1e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b3c:	4681                	li	a3,0
    80001b3e:	4605                	li	a2,1
    80001b40:	040005b7          	lui	a1,0x4000
    80001b44:	15fd                	addi	a1,a1,-1
    80001b46:	05b2                	slli	a1,a1,0xc
    80001b48:	8526                	mv	a0,s1
    80001b4a:	fffff097          	auipc	ra,0xfffff
    80001b4e:	7b0080e7          	jalr	1968(ra) # 800012fa <uvmunmap>
    uvmfree(pagetable, 0);
    80001b52:	4581                	li	a1,0
    80001b54:	8526                	mv	a0,s1
    80001b56:	00000097          	auipc	ra,0x0
    80001b5a:	a64080e7          	jalr	-1436(ra) # 800015ba <uvmfree>
    return 0;
    80001b5e:	4481                	li	s1,0
    80001b60:	bf7d                	j	80001b1e <proc_pagetable+0x58>

0000000080001b62 <proc_freepagetable>:
{
    80001b62:	1101                	addi	sp,sp,-32
    80001b64:	ec06                	sd	ra,24(sp)
    80001b66:	e822                	sd	s0,16(sp)
    80001b68:	e426                	sd	s1,8(sp)
    80001b6a:	e04a                	sd	s2,0(sp)
    80001b6c:	1000                	addi	s0,sp,32
    80001b6e:	84aa                	mv	s1,a0
    80001b70:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b72:	4681                	li	a3,0
    80001b74:	4605                	li	a2,1
    80001b76:	040005b7          	lui	a1,0x4000
    80001b7a:	15fd                	addi	a1,a1,-1
    80001b7c:	05b2                	slli	a1,a1,0xc
    80001b7e:	fffff097          	auipc	ra,0xfffff
    80001b82:	77c080e7          	jalr	1916(ra) # 800012fa <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b86:	4681                	li	a3,0
    80001b88:	4605                	li	a2,1
    80001b8a:	020005b7          	lui	a1,0x2000
    80001b8e:	15fd                	addi	a1,a1,-1
    80001b90:	05b6                	slli	a1,a1,0xd
    80001b92:	8526                	mv	a0,s1
    80001b94:	fffff097          	auipc	ra,0xfffff
    80001b98:	766080e7          	jalr	1894(ra) # 800012fa <uvmunmap>
  uvmfree(pagetable, sz);
    80001b9c:	85ca                	mv	a1,s2
    80001b9e:	8526                	mv	a0,s1
    80001ba0:	00000097          	auipc	ra,0x0
    80001ba4:	a1a080e7          	jalr	-1510(ra) # 800015ba <uvmfree>
}
    80001ba8:	60e2                	ld	ra,24(sp)
    80001baa:	6442                	ld	s0,16(sp)
    80001bac:	64a2                	ld	s1,8(sp)
    80001bae:	6902                	ld	s2,0(sp)
    80001bb0:	6105                	addi	sp,sp,32
    80001bb2:	8082                	ret

0000000080001bb4 <freeproc>:
{
    80001bb4:	1101                	addi	sp,sp,-32
    80001bb6:	ec06                	sd	ra,24(sp)
    80001bb8:	e822                	sd	s0,16(sp)
    80001bba:	e426                	sd	s1,8(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bc0:	6d28                	ld	a0,88(a0)
    80001bc2:	c509                	beqz	a0,80001bcc <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bc4:	fffff097          	auipc	ra,0xfffff
    80001bc8:	e60080e7          	jalr	-416(ra) # 80000a24 <kfree>
  p->trapframe = 0;
    80001bcc:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bd0:	68a8                	ld	a0,80(s1)
    80001bd2:	c511                	beqz	a0,80001bde <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bd4:	64ac                	ld	a1,72(s1)
    80001bd6:	00000097          	auipc	ra,0x0
    80001bda:	f8c080e7          	jalr	-116(ra) # 80001b62 <proc_freepagetable>
  p->pagetable = 0;
    80001bde:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001be2:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001be6:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001bea:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001bee:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001bf2:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001bf6:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001bfa:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001bfe:	0004ac23          	sw	zero,24(s1)
  p->trace_mask = 0;
    80001c02:	1604a423          	sw	zero,360(s1)
}
    80001c06:	60e2                	ld	ra,24(sp)
    80001c08:	6442                	ld	s0,16(sp)
    80001c0a:	64a2                	ld	s1,8(sp)
    80001c0c:	6105                	addi	sp,sp,32
    80001c0e:	8082                	ret

0000000080001c10 <allocproc>:
{
    80001c10:	1101                	addi	sp,sp,-32
    80001c12:	ec06                	sd	ra,24(sp)
    80001c14:	e822                	sd	s0,16(sp)
    80001c16:	e426                	sd	s1,8(sp)
    80001c18:	e04a                	sd	s2,0(sp)
    80001c1a:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c1c:	00010497          	auipc	s1,0x10
    80001c20:	14c48493          	addi	s1,s1,332 # 80011d68 <proc>
    80001c24:	00016917          	auipc	s2,0x16
    80001c28:	d4490913          	addi	s2,s2,-700 # 80017968 <tickslock>
    acquire(&p->lock);
    80001c2c:	8526                	mv	a0,s1
    80001c2e:	fffff097          	auipc	ra,0xfffff
    80001c32:	006080e7          	jalr	6(ra) # 80000c34 <acquire>
    if(p->state == UNUSED) {
    80001c36:	4c9c                	lw	a5,24(s1)
    80001c38:	cf81                	beqz	a5,80001c50 <allocproc+0x40>
      release(&p->lock);
    80001c3a:	8526                	mv	a0,s1
    80001c3c:	fffff097          	auipc	ra,0xfffff
    80001c40:	0ac080e7          	jalr	172(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c44:	17048493          	addi	s1,s1,368
    80001c48:	ff2492e3          	bne	s1,s2,80001c2c <allocproc+0x1c>
  return 0;
    80001c4c:	4481                	li	s1,0
    80001c4e:	a0b9                	j	80001c9c <allocproc+0x8c>
  p->pid = allocpid();
    80001c50:	00000097          	auipc	ra,0x0
    80001c54:	e30080e7          	jalr	-464(ra) # 80001a80 <allocpid>
    80001c58:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c5a:	fffff097          	auipc	ra,0xfffff
    80001c5e:	ec6080e7          	jalr	-314(ra) # 80000b20 <kalloc>
    80001c62:	892a                	mv	s2,a0
    80001c64:	eca8                	sd	a0,88(s1)
    80001c66:	c131                	beqz	a0,80001caa <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    80001c68:	8526                	mv	a0,s1
    80001c6a:	00000097          	auipc	ra,0x0
    80001c6e:	e5c080e7          	jalr	-420(ra) # 80001ac6 <proc_pagetable>
    80001c72:	892a                	mv	s2,a0
    80001c74:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c76:	c129                	beqz	a0,80001cb8 <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    80001c78:	07000613          	li	a2,112
    80001c7c:	4581                	li	a1,0
    80001c7e:	06048513          	addi	a0,s1,96
    80001c82:	fffff097          	auipc	ra,0xfffff
    80001c86:	0ae080e7          	jalr	174(ra) # 80000d30 <memset>
  p->context.ra = (uint64)forkret;
    80001c8a:	00000797          	auipc	a5,0x0
    80001c8e:	db078793          	addi	a5,a5,-592 # 80001a3a <forkret>
    80001c92:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c94:	60bc                	ld	a5,64(s1)
    80001c96:	6705                	lui	a4,0x1
    80001c98:	97ba                	add	a5,a5,a4
    80001c9a:	f4bc                	sd	a5,104(s1)
}
    80001c9c:	8526                	mv	a0,s1
    80001c9e:	60e2                	ld	ra,24(sp)
    80001ca0:	6442                	ld	s0,16(sp)
    80001ca2:	64a2                	ld	s1,8(sp)
    80001ca4:	6902                	ld	s2,0(sp)
    80001ca6:	6105                	addi	sp,sp,32
    80001ca8:	8082                	ret
    release(&p->lock);
    80001caa:	8526                	mv	a0,s1
    80001cac:	fffff097          	auipc	ra,0xfffff
    80001cb0:	03c080e7          	jalr	60(ra) # 80000ce8 <release>
    return 0;
    80001cb4:	84ca                	mv	s1,s2
    80001cb6:	b7dd                	j	80001c9c <allocproc+0x8c>
    freeproc(p);
    80001cb8:	8526                	mv	a0,s1
    80001cba:	00000097          	auipc	ra,0x0
    80001cbe:	efa080e7          	jalr	-262(ra) # 80001bb4 <freeproc>
    release(&p->lock);
    80001cc2:	8526                	mv	a0,s1
    80001cc4:	fffff097          	auipc	ra,0xfffff
    80001cc8:	024080e7          	jalr	36(ra) # 80000ce8 <release>
    return 0;
    80001ccc:	84ca                	mv	s1,s2
    80001cce:	b7f9                	j	80001c9c <allocproc+0x8c>

0000000080001cd0 <userinit>:
{
    80001cd0:	1101                	addi	sp,sp,-32
    80001cd2:	ec06                	sd	ra,24(sp)
    80001cd4:	e822                	sd	s0,16(sp)
    80001cd6:	e426                	sd	s1,8(sp)
    80001cd8:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cda:	00000097          	auipc	ra,0x0
    80001cde:	f36080e7          	jalr	-202(ra) # 80001c10 <allocproc>
    80001ce2:	84aa                	mv	s1,a0
  initproc = p;
    80001ce4:	00007797          	auipc	a5,0x7
    80001ce8:	32a7ba23          	sd	a0,820(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001cec:	03400613          	li	a2,52
    80001cf0:	00007597          	auipc	a1,0x7
    80001cf4:	cc058593          	addi	a1,a1,-832 # 800089b0 <initcode>
    80001cf8:	6928                	ld	a0,80(a0)
    80001cfa:	fffff097          	auipc	ra,0xfffff
    80001cfe:	6f2080e7          	jalr	1778(ra) # 800013ec <uvminit>
  p->sz = PGSIZE;
    80001d02:	6785                	lui	a5,0x1
    80001d04:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d06:	6cb8                	ld	a4,88(s1)
    80001d08:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0c:	6cb8                	ld	a4,88(s1)
    80001d0e:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d10:	4641                	li	a2,16
    80001d12:	00006597          	auipc	a1,0x6
    80001d16:	4d658593          	addi	a1,a1,1238 # 800081e8 <digits+0x1a8>
    80001d1a:	15848513          	addi	a0,s1,344
    80001d1e:	fffff097          	auipc	ra,0xfffff
    80001d22:	168080e7          	jalr	360(ra) # 80000e86 <safestrcpy>
  p->cwd = namei("/");
    80001d26:	00006517          	auipc	a0,0x6
    80001d2a:	4d250513          	addi	a0,a0,1234 # 800081f8 <digits+0x1b8>
    80001d2e:	00002097          	auipc	ra,0x2
    80001d32:	1c0080e7          	jalr	448(ra) # 80003eee <namei>
    80001d36:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3a:	4789                	li	a5,2
    80001d3c:	cc9c                	sw	a5,24(s1)
  p->trace_mask = 0;
    80001d3e:	1604a423          	sw	zero,360(s1)
  release(&p->lock);
    80001d42:	8526                	mv	a0,s1
    80001d44:	fffff097          	auipc	ra,0xfffff
    80001d48:	fa4080e7          	jalr	-92(ra) # 80000ce8 <release>
}
    80001d4c:	60e2                	ld	ra,24(sp)
    80001d4e:	6442                	ld	s0,16(sp)
    80001d50:	64a2                	ld	s1,8(sp)
    80001d52:	6105                	addi	sp,sp,32
    80001d54:	8082                	ret

0000000080001d56 <growproc>:
{
    80001d56:	1101                	addi	sp,sp,-32
    80001d58:	ec06                	sd	ra,24(sp)
    80001d5a:	e822                	sd	s0,16(sp)
    80001d5c:	e426                	sd	s1,8(sp)
    80001d5e:	e04a                	sd	s2,0(sp)
    80001d60:	1000                	addi	s0,sp,32
    80001d62:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001d64:	00000097          	auipc	ra,0x0
    80001d68:	c9e080e7          	jalr	-866(ra) # 80001a02 <myproc>
    80001d6c:	892a                	mv	s2,a0
  sz = p->sz;
    80001d6e:	652c                	ld	a1,72(a0)
    80001d70:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001d74:	00904f63          	bgtz	s1,80001d92 <growproc+0x3c>
  } else if(n < 0){
    80001d78:	0204cc63          	bltz	s1,80001db0 <growproc+0x5a>
  p->sz = sz;
    80001d7c:	1602                	slli	a2,a2,0x20
    80001d7e:	9201                	srli	a2,a2,0x20
    80001d80:	04c93423          	sd	a2,72(s2)
  return 0;
    80001d84:	4501                	li	a0,0
}
    80001d86:	60e2                	ld	ra,24(sp)
    80001d88:	6442                	ld	s0,16(sp)
    80001d8a:	64a2                	ld	s1,8(sp)
    80001d8c:	6902                	ld	s2,0(sp)
    80001d8e:	6105                	addi	sp,sp,32
    80001d90:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001d92:	9e25                	addw	a2,a2,s1
    80001d94:	1602                	slli	a2,a2,0x20
    80001d96:	9201                	srli	a2,a2,0x20
    80001d98:	1582                	slli	a1,a1,0x20
    80001d9a:	9181                	srli	a1,a1,0x20
    80001d9c:	6928                	ld	a0,80(a0)
    80001d9e:	fffff097          	auipc	ra,0xfffff
    80001da2:	708080e7          	jalr	1800(ra) # 800014a6 <uvmalloc>
    80001da6:	0005061b          	sext.w	a2,a0
    80001daa:	fa69                	bnez	a2,80001d7c <growproc+0x26>
      return -1;
    80001dac:	557d                	li	a0,-1
    80001dae:	bfe1                	j	80001d86 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db0:	9e25                	addw	a2,a2,s1
    80001db2:	1602                	slli	a2,a2,0x20
    80001db4:	9201                	srli	a2,a2,0x20
    80001db6:	1582                	slli	a1,a1,0x20
    80001db8:	9181                	srli	a1,a1,0x20
    80001dba:	6928                	ld	a0,80(a0)
    80001dbc:	fffff097          	auipc	ra,0xfffff
    80001dc0:	6a2080e7          	jalr	1698(ra) # 8000145e <uvmdealloc>
    80001dc4:	0005061b          	sext.w	a2,a0
    80001dc8:	bf55                	j	80001d7c <growproc+0x26>

0000000080001dca <fork>:
{
    80001dca:	7179                	addi	sp,sp,-48
    80001dcc:	f406                	sd	ra,40(sp)
    80001dce:	f022                	sd	s0,32(sp)
    80001dd0:	ec26                	sd	s1,24(sp)
    80001dd2:	e84a                	sd	s2,16(sp)
    80001dd4:	e44e                	sd	s3,8(sp)
    80001dd6:	e052                	sd	s4,0(sp)
    80001dd8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001dda:	00000097          	auipc	ra,0x0
    80001dde:	c28080e7          	jalr	-984(ra) # 80001a02 <myproc>
    80001de2:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001de4:	00000097          	auipc	ra,0x0
    80001de8:	e2c080e7          	jalr	-468(ra) # 80001c10 <allocproc>
    80001dec:	c575                	beqz	a0,80001ed8 <fork+0x10e>
    80001dee:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001df0:	04893603          	ld	a2,72(s2)
    80001df4:	692c                	ld	a1,80(a0)
    80001df6:	05093503          	ld	a0,80(s2)
    80001dfa:	fffff097          	auipc	ra,0xfffff
    80001dfe:	7f8080e7          	jalr	2040(ra) # 800015f2 <uvmcopy>
    80001e02:	04054863          	bltz	a0,80001e52 <fork+0x88>
  np->sz = p->sz;
    80001e06:	04893783          	ld	a5,72(s2)
    80001e0a:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e0e:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e12:	05893683          	ld	a3,88(s2)
    80001e16:	87b6                	mv	a5,a3
    80001e18:	0589b703          	ld	a4,88(s3)
    80001e1c:	12068693          	addi	a3,a3,288
    80001e20:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e24:	6788                	ld	a0,8(a5)
    80001e26:	6b8c                	ld	a1,16(a5)
    80001e28:	6f90                	ld	a2,24(a5)
    80001e2a:	01073023          	sd	a6,0(a4)
    80001e2e:	e708                	sd	a0,8(a4)
    80001e30:	eb0c                	sd	a1,16(a4)
    80001e32:	ef10                	sd	a2,24(a4)
    80001e34:	02078793          	addi	a5,a5,32
    80001e38:	02070713          	addi	a4,a4,32
    80001e3c:	fed792e3          	bne	a5,a3,80001e20 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e40:	0589b783          	ld	a5,88(s3)
    80001e44:	0607b823          	sd	zero,112(a5)
    80001e48:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001e4c:	15000a13          	li	s4,336
    80001e50:	a03d                	j	80001e7e <fork+0xb4>
    freeproc(np);
    80001e52:	854e                	mv	a0,s3
    80001e54:	00000097          	auipc	ra,0x0
    80001e58:	d60080e7          	jalr	-672(ra) # 80001bb4 <freeproc>
    release(&np->lock);
    80001e5c:	854e                	mv	a0,s3
    80001e5e:	fffff097          	auipc	ra,0xfffff
    80001e62:	e8a080e7          	jalr	-374(ra) # 80000ce8 <release>
    return -1;
    80001e66:	54fd                	li	s1,-1
    80001e68:	a8b9                	j	80001ec6 <fork+0xfc>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e6a:	00002097          	auipc	ra,0x2
    80001e6e:	710080e7          	jalr	1808(ra) # 8000457a <filedup>
    80001e72:	009987b3          	add	a5,s3,s1
    80001e76:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001e78:	04a1                	addi	s1,s1,8
    80001e7a:	01448763          	beq	s1,s4,80001e88 <fork+0xbe>
    if(p->ofile[i])
    80001e7e:	009907b3          	add	a5,s2,s1
    80001e82:	6388                	ld	a0,0(a5)
    80001e84:	f17d                	bnez	a0,80001e6a <fork+0xa0>
    80001e86:	bfcd                	j	80001e78 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001e88:	15093503          	ld	a0,336(s2)
    80001e8c:	00002097          	auipc	ra,0x2
    80001e90:	874080e7          	jalr	-1932(ra) # 80003700 <idup>
    80001e94:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e98:	4641                	li	a2,16
    80001e9a:	15890593          	addi	a1,s2,344
    80001e9e:	15898513          	addi	a0,s3,344
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	fe4080e7          	jalr	-28(ra) # 80000e86 <safestrcpy>
  pid = np->pid;
    80001eaa:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001eae:	4789                	li	a5,2
    80001eb0:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e32080e7          	jalr	-462(ra) # 80000ce8 <release>
  np->trace_mask = p->trace_mask;
    80001ebe:	16892783          	lw	a5,360(s2)
    80001ec2:	16f9a423          	sw	a5,360(s3)
}
    80001ec6:	8526                	mv	a0,s1
    80001ec8:	70a2                	ld	ra,40(sp)
    80001eca:	7402                	ld	s0,32(sp)
    80001ecc:	64e2                	ld	s1,24(sp)
    80001ece:	6942                	ld	s2,16(sp)
    80001ed0:	69a2                	ld	s3,8(sp)
    80001ed2:	6a02                	ld	s4,0(sp)
    80001ed4:	6145                	addi	sp,sp,48
    80001ed6:	8082                	ret
    return -1;
    80001ed8:	54fd                	li	s1,-1
    80001eda:	b7f5                	j	80001ec6 <fork+0xfc>

0000000080001edc <reparent>:
{
    80001edc:	7179                	addi	sp,sp,-48
    80001ede:	f406                	sd	ra,40(sp)
    80001ee0:	f022                	sd	s0,32(sp)
    80001ee2:	ec26                	sd	s1,24(sp)
    80001ee4:	e84a                	sd	s2,16(sp)
    80001ee6:	e44e                	sd	s3,8(sp)
    80001ee8:	e052                	sd	s4,0(sp)
    80001eea:	1800                	addi	s0,sp,48
    80001eec:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001eee:	00010497          	auipc	s1,0x10
    80001ef2:	e7a48493          	addi	s1,s1,-390 # 80011d68 <proc>
      pp->parent = initproc;
    80001ef6:	00007a17          	auipc	s4,0x7
    80001efa:	122a0a13          	addi	s4,s4,290 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001efe:	00016997          	auipc	s3,0x16
    80001f02:	a6a98993          	addi	s3,s3,-1430 # 80017968 <tickslock>
    80001f06:	a029                	j	80001f10 <reparent+0x34>
    80001f08:	17048493          	addi	s1,s1,368
    80001f0c:	03348363          	beq	s1,s3,80001f32 <reparent+0x56>
    if(pp->parent == p){
    80001f10:	709c                	ld	a5,32(s1)
    80001f12:	ff279be3          	bne	a5,s2,80001f08 <reparent+0x2c>
      acquire(&pp->lock);
    80001f16:	8526                	mv	a0,s1
    80001f18:	fffff097          	auipc	ra,0xfffff
    80001f1c:	d1c080e7          	jalr	-740(ra) # 80000c34 <acquire>
      pp->parent = initproc;
    80001f20:	000a3783          	ld	a5,0(s4)
    80001f24:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f26:	8526                	mv	a0,s1
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	dc0080e7          	jalr	-576(ra) # 80000ce8 <release>
    80001f30:	bfe1                	j	80001f08 <reparent+0x2c>
}
    80001f32:	70a2                	ld	ra,40(sp)
    80001f34:	7402                	ld	s0,32(sp)
    80001f36:	64e2                	ld	s1,24(sp)
    80001f38:	6942                	ld	s2,16(sp)
    80001f3a:	69a2                	ld	s3,8(sp)
    80001f3c:	6a02                	ld	s4,0(sp)
    80001f3e:	6145                	addi	sp,sp,48
    80001f40:	8082                	ret

0000000080001f42 <scheduler>:
{
    80001f42:	715d                	addi	sp,sp,-80
    80001f44:	e486                	sd	ra,72(sp)
    80001f46:	e0a2                	sd	s0,64(sp)
    80001f48:	fc26                	sd	s1,56(sp)
    80001f4a:	f84a                	sd	s2,48(sp)
    80001f4c:	f44e                	sd	s3,40(sp)
    80001f4e:	f052                	sd	s4,32(sp)
    80001f50:	ec56                	sd	s5,24(sp)
    80001f52:	e85a                	sd	s6,16(sp)
    80001f54:	e45e                	sd	s7,8(sp)
    80001f56:	e062                	sd	s8,0(sp)
    80001f58:	0880                	addi	s0,sp,80
    80001f5a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f5c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f5e:	00779b13          	slli	s6,a5,0x7
    80001f62:	00010717          	auipc	a4,0x10
    80001f66:	9ee70713          	addi	a4,a4,-1554 # 80011950 <pid_lock>
    80001f6a:	975a                	add	a4,a4,s6
    80001f6c:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001f70:	00010717          	auipc	a4,0x10
    80001f74:	a0070713          	addi	a4,a4,-1536 # 80011970 <cpus+0x8>
    80001f78:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001f7a:	4c0d                	li	s8,3
        c->proc = p;
    80001f7c:	079e                	slli	a5,a5,0x7
    80001f7e:	00010a17          	auipc	s4,0x10
    80001f82:	9d2a0a13          	addi	s4,s4,-1582 # 80011950 <pid_lock>
    80001f86:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f88:	00016997          	auipc	s3,0x16
    80001f8c:	9e098993          	addi	s3,s3,-1568 # 80017968 <tickslock>
        found = 1;
    80001f90:	4b85                	li	s7,1
    80001f92:	a899                	j	80001fe8 <scheduler+0xa6>
        p->state = RUNNING;
    80001f94:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001f98:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001f9c:	06048593          	addi	a1,s1,96
    80001fa0:	855a                	mv	a0,s6
    80001fa2:	00000097          	auipc	ra,0x0
    80001fa6:	666080e7          	jalr	1638(ra) # 80002608 <swtch>
        c->proc = 0;
    80001faa:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001fae:	8ade                	mv	s5,s7
      release(&p->lock);
    80001fb0:	8526                	mv	a0,s1
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	d36080e7          	jalr	-714(ra) # 80000ce8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fba:	17048493          	addi	s1,s1,368
    80001fbe:	01348b63          	beq	s1,s3,80001fd4 <scheduler+0x92>
      acquire(&p->lock);
    80001fc2:	8526                	mv	a0,s1
    80001fc4:	fffff097          	auipc	ra,0xfffff
    80001fc8:	c70080e7          	jalr	-912(ra) # 80000c34 <acquire>
      if(p->state == RUNNABLE) {
    80001fcc:	4c9c                	lw	a5,24(s1)
    80001fce:	ff2791e3          	bne	a5,s2,80001fb0 <scheduler+0x6e>
    80001fd2:	b7c9                	j	80001f94 <scheduler+0x52>
    if(found == 0) {
    80001fd4:	000a9a63          	bnez	s5,80001fe8 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fdc:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001fe0:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80001fe4:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fe8:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001fec:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001ff0:	10079073          	csrw	sstatus,a5
    int found = 0;
    80001ff4:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80001ff6:	00010497          	auipc	s1,0x10
    80001ffa:	d7248493          	addi	s1,s1,-654 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    80001ffe:	4909                	li	s2,2
    80002000:	b7c9                	j	80001fc2 <scheduler+0x80>

0000000080002002 <sched>:
{
    80002002:	7179                	addi	sp,sp,-48
    80002004:	f406                	sd	ra,40(sp)
    80002006:	f022                	sd	s0,32(sp)
    80002008:	ec26                	sd	s1,24(sp)
    8000200a:	e84a                	sd	s2,16(sp)
    8000200c:	e44e                	sd	s3,8(sp)
    8000200e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002010:	00000097          	auipc	ra,0x0
    80002014:	9f2080e7          	jalr	-1550(ra) # 80001a02 <myproc>
    80002018:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000201a:	fffff097          	auipc	ra,0xfffff
    8000201e:	ba0080e7          	jalr	-1120(ra) # 80000bba <holding>
    80002022:	c93d                	beqz	a0,80002098 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002024:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002026:	2781                	sext.w	a5,a5
    80002028:	079e                	slli	a5,a5,0x7
    8000202a:	00010717          	auipc	a4,0x10
    8000202e:	92670713          	addi	a4,a4,-1754 # 80011950 <pid_lock>
    80002032:	97ba                	add	a5,a5,a4
    80002034:	0907a703          	lw	a4,144(a5)
    80002038:	4785                	li	a5,1
    8000203a:	06f71763          	bne	a4,a5,800020a8 <sched+0xa6>
  if(p->state == RUNNING)
    8000203e:	4c98                	lw	a4,24(s1)
    80002040:	478d                	li	a5,3
    80002042:	06f70b63          	beq	a4,a5,800020b8 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002046:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000204a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000204c:	efb5                	bnez	a5,800020c8 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000204e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002050:	00010917          	auipc	s2,0x10
    80002054:	90090913          	addi	s2,s2,-1792 # 80011950 <pid_lock>
    80002058:	2781                	sext.w	a5,a5
    8000205a:	079e                	slli	a5,a5,0x7
    8000205c:	97ca                	add	a5,a5,s2
    8000205e:	0947a983          	lw	s3,148(a5)
    80002062:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002064:	2781                	sext.w	a5,a5
    80002066:	079e                	slli	a5,a5,0x7
    80002068:	00010597          	auipc	a1,0x10
    8000206c:	90858593          	addi	a1,a1,-1784 # 80011970 <cpus+0x8>
    80002070:	95be                	add	a1,a1,a5
    80002072:	06048513          	addi	a0,s1,96
    80002076:	00000097          	auipc	ra,0x0
    8000207a:	592080e7          	jalr	1426(ra) # 80002608 <swtch>
    8000207e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002080:	2781                	sext.w	a5,a5
    80002082:	079e                	slli	a5,a5,0x7
    80002084:	97ca                	add	a5,a5,s2
    80002086:	0937aa23          	sw	s3,148(a5)
}
    8000208a:	70a2                	ld	ra,40(sp)
    8000208c:	7402                	ld	s0,32(sp)
    8000208e:	64e2                	ld	s1,24(sp)
    80002090:	6942                	ld	s2,16(sp)
    80002092:	69a2                	ld	s3,8(sp)
    80002094:	6145                	addi	sp,sp,48
    80002096:	8082                	ret
    panic("sched p->lock");
    80002098:	00006517          	auipc	a0,0x6
    8000209c:	16850513          	addi	a0,a0,360 # 80008200 <digits+0x1c0>
    800020a0:	ffffe097          	auipc	ra,0xffffe
    800020a4:	4a8080e7          	jalr	1192(ra) # 80000548 <panic>
    panic("sched locks");
    800020a8:	00006517          	auipc	a0,0x6
    800020ac:	16850513          	addi	a0,a0,360 # 80008210 <digits+0x1d0>
    800020b0:	ffffe097          	auipc	ra,0xffffe
    800020b4:	498080e7          	jalr	1176(ra) # 80000548 <panic>
    panic("sched running");
    800020b8:	00006517          	auipc	a0,0x6
    800020bc:	16850513          	addi	a0,a0,360 # 80008220 <digits+0x1e0>
    800020c0:	ffffe097          	auipc	ra,0xffffe
    800020c4:	488080e7          	jalr	1160(ra) # 80000548 <panic>
    panic("sched interruptible");
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	16850513          	addi	a0,a0,360 # 80008230 <digits+0x1f0>
    800020d0:	ffffe097          	auipc	ra,0xffffe
    800020d4:	478080e7          	jalr	1144(ra) # 80000548 <panic>

00000000800020d8 <exit>:
{
    800020d8:	7179                	addi	sp,sp,-48
    800020da:	f406                	sd	ra,40(sp)
    800020dc:	f022                	sd	s0,32(sp)
    800020de:	ec26                	sd	s1,24(sp)
    800020e0:	e84a                	sd	s2,16(sp)
    800020e2:	e44e                	sd	s3,8(sp)
    800020e4:	e052                	sd	s4,0(sp)
    800020e6:	1800                	addi	s0,sp,48
    800020e8:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800020ea:	00000097          	auipc	ra,0x0
    800020ee:	918080e7          	jalr	-1768(ra) # 80001a02 <myproc>
    800020f2:	89aa                	mv	s3,a0
  if(p == initproc)
    800020f4:	00007797          	auipc	a5,0x7
    800020f8:	f247b783          	ld	a5,-220(a5) # 80009018 <initproc>
    800020fc:	0d050493          	addi	s1,a0,208
    80002100:	15050913          	addi	s2,a0,336
    80002104:	02a79363          	bne	a5,a0,8000212a <exit+0x52>
    panic("init exiting");
    80002108:	00006517          	auipc	a0,0x6
    8000210c:	14050513          	addi	a0,a0,320 # 80008248 <digits+0x208>
    80002110:	ffffe097          	auipc	ra,0xffffe
    80002114:	438080e7          	jalr	1080(ra) # 80000548 <panic>
      fileclose(f);
    80002118:	00002097          	auipc	ra,0x2
    8000211c:	4b4080e7          	jalr	1204(ra) # 800045cc <fileclose>
      p->ofile[fd] = 0;
    80002120:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002124:	04a1                	addi	s1,s1,8
    80002126:	01248563          	beq	s1,s2,80002130 <exit+0x58>
    if(p->ofile[fd]){
    8000212a:	6088                	ld	a0,0(s1)
    8000212c:	f575                	bnez	a0,80002118 <exit+0x40>
    8000212e:	bfdd                	j	80002124 <exit+0x4c>
  begin_op();
    80002130:	00002097          	auipc	ra,0x2
    80002134:	fca080e7          	jalr	-54(ra) # 800040fa <begin_op>
  iput(p->cwd);
    80002138:	1509b503          	ld	a0,336(s3)
    8000213c:	00001097          	auipc	ra,0x1
    80002140:	7bc080e7          	jalr	1980(ra) # 800038f8 <iput>
  end_op();
    80002144:	00002097          	auipc	ra,0x2
    80002148:	036080e7          	jalr	54(ra) # 8000417a <end_op>
  p->cwd = 0;
    8000214c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002150:	00007497          	auipc	s1,0x7
    80002154:	ec848493          	addi	s1,s1,-312 # 80009018 <initproc>
    80002158:	6088                	ld	a0,0(s1)
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	ada080e7          	jalr	-1318(ra) # 80000c34 <acquire>
  wakeup1(initproc);
    80002162:	6088                	ld	a0,0(s1)
    80002164:	fffff097          	auipc	ra,0xfffff
    80002168:	75e080e7          	jalr	1886(ra) # 800018c2 <wakeup1>
  release(&initproc->lock);
    8000216c:	6088                	ld	a0,0(s1)
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b7a080e7          	jalr	-1158(ra) # 80000ce8 <release>
  acquire(&p->lock);
    80002176:	854e                	mv	a0,s3
    80002178:	fffff097          	auipc	ra,0xfffff
    8000217c:	abc080e7          	jalr	-1348(ra) # 80000c34 <acquire>
  struct proc *original_parent = p->parent;
    80002180:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002184:	854e                	mv	a0,s3
    80002186:	fffff097          	auipc	ra,0xfffff
    8000218a:	b62080e7          	jalr	-1182(ra) # 80000ce8 <release>
  acquire(&original_parent->lock);
    8000218e:	8526                	mv	a0,s1
    80002190:	fffff097          	auipc	ra,0xfffff
    80002194:	aa4080e7          	jalr	-1372(ra) # 80000c34 <acquire>
  acquire(&p->lock);
    80002198:	854e                	mv	a0,s3
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a9a080e7          	jalr	-1382(ra) # 80000c34 <acquire>
  reparent(p);
    800021a2:	854e                	mv	a0,s3
    800021a4:	00000097          	auipc	ra,0x0
    800021a8:	d38080e7          	jalr	-712(ra) # 80001edc <reparent>
  wakeup1(original_parent);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	714080e7          	jalr	1812(ra) # 800018c2 <wakeup1>
  p->xstate = status;
    800021b6:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    800021ba:	4791                	li	a5,4
    800021bc:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    800021c0:	8526                	mv	a0,s1
    800021c2:	fffff097          	auipc	ra,0xfffff
    800021c6:	b26080e7          	jalr	-1242(ra) # 80000ce8 <release>
  sched();
    800021ca:	00000097          	auipc	ra,0x0
    800021ce:	e38080e7          	jalr	-456(ra) # 80002002 <sched>
  panic("zombie exit");
    800021d2:	00006517          	auipc	a0,0x6
    800021d6:	08650513          	addi	a0,a0,134 # 80008258 <digits+0x218>
    800021da:	ffffe097          	auipc	ra,0xffffe
    800021de:	36e080e7          	jalr	878(ra) # 80000548 <panic>

00000000800021e2 <yield>:
{
    800021e2:	1101                	addi	sp,sp,-32
    800021e4:	ec06                	sd	ra,24(sp)
    800021e6:	e822                	sd	s0,16(sp)
    800021e8:	e426                	sd	s1,8(sp)
    800021ea:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800021ec:	00000097          	auipc	ra,0x0
    800021f0:	816080e7          	jalr	-2026(ra) # 80001a02 <myproc>
    800021f4:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800021f6:	fffff097          	auipc	ra,0xfffff
    800021fa:	a3e080e7          	jalr	-1474(ra) # 80000c34 <acquire>
  p->state = RUNNABLE;
    800021fe:	4789                	li	a5,2
    80002200:	cc9c                	sw	a5,24(s1)
  sched();
    80002202:	00000097          	auipc	ra,0x0
    80002206:	e00080e7          	jalr	-512(ra) # 80002002 <sched>
  release(&p->lock);
    8000220a:	8526                	mv	a0,s1
    8000220c:	fffff097          	auipc	ra,0xfffff
    80002210:	adc080e7          	jalr	-1316(ra) # 80000ce8 <release>
}
    80002214:	60e2                	ld	ra,24(sp)
    80002216:	6442                	ld	s0,16(sp)
    80002218:	64a2                	ld	s1,8(sp)
    8000221a:	6105                	addi	sp,sp,32
    8000221c:	8082                	ret

000000008000221e <sleep>:
{
    8000221e:	7179                	addi	sp,sp,-48
    80002220:	f406                	sd	ra,40(sp)
    80002222:	f022                	sd	s0,32(sp)
    80002224:	ec26                	sd	s1,24(sp)
    80002226:	e84a                	sd	s2,16(sp)
    80002228:	e44e                	sd	s3,8(sp)
    8000222a:	1800                	addi	s0,sp,48
    8000222c:	89aa                	mv	s3,a0
    8000222e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002230:	fffff097          	auipc	ra,0xfffff
    80002234:	7d2080e7          	jalr	2002(ra) # 80001a02 <myproc>
    80002238:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000223a:	05250663          	beq	a0,s2,80002286 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000223e:	fffff097          	auipc	ra,0xfffff
    80002242:	9f6080e7          	jalr	-1546(ra) # 80000c34 <acquire>
    release(lk);
    80002246:	854a                	mv	a0,s2
    80002248:	fffff097          	auipc	ra,0xfffff
    8000224c:	aa0080e7          	jalr	-1376(ra) # 80000ce8 <release>
  p->chan = chan;
    80002250:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002254:	4785                	li	a5,1
    80002256:	cc9c                	sw	a5,24(s1)
  sched();
    80002258:	00000097          	auipc	ra,0x0
    8000225c:	daa080e7          	jalr	-598(ra) # 80002002 <sched>
  p->chan = 0;
    80002260:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002264:	8526                	mv	a0,s1
    80002266:	fffff097          	auipc	ra,0xfffff
    8000226a:	a82080e7          	jalr	-1406(ra) # 80000ce8 <release>
    acquire(lk);
    8000226e:	854a                	mv	a0,s2
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	9c4080e7          	jalr	-1596(ra) # 80000c34 <acquire>
}
    80002278:	70a2                	ld	ra,40(sp)
    8000227a:	7402                	ld	s0,32(sp)
    8000227c:	64e2                	ld	s1,24(sp)
    8000227e:	6942                	ld	s2,16(sp)
    80002280:	69a2                	ld	s3,8(sp)
    80002282:	6145                	addi	sp,sp,48
    80002284:	8082                	ret
  p->chan = chan;
    80002286:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    8000228a:	4785                	li	a5,1
    8000228c:	cd1c                	sw	a5,24(a0)
  sched();
    8000228e:	00000097          	auipc	ra,0x0
    80002292:	d74080e7          	jalr	-652(ra) # 80002002 <sched>
  p->chan = 0;
    80002296:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    8000229a:	bff9                	j	80002278 <sleep+0x5a>

000000008000229c <wait>:
{
    8000229c:	715d                	addi	sp,sp,-80
    8000229e:	e486                	sd	ra,72(sp)
    800022a0:	e0a2                	sd	s0,64(sp)
    800022a2:	fc26                	sd	s1,56(sp)
    800022a4:	f84a                	sd	s2,48(sp)
    800022a6:	f44e                	sd	s3,40(sp)
    800022a8:	f052                	sd	s4,32(sp)
    800022aa:	ec56                	sd	s5,24(sp)
    800022ac:	e85a                	sd	s6,16(sp)
    800022ae:	e45e                	sd	s7,8(sp)
    800022b0:	e062                	sd	s8,0(sp)
    800022b2:	0880                	addi	s0,sp,80
    800022b4:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	74c080e7          	jalr	1868(ra) # 80001a02 <myproc>
    800022be:	892a                	mv	s2,a0
  acquire(&p->lock);
    800022c0:	8c2a                	mv	s8,a0
    800022c2:	fffff097          	auipc	ra,0xfffff
    800022c6:	972080e7          	jalr	-1678(ra) # 80000c34 <acquire>
    havekids = 0;
    800022ca:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    800022cc:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    800022ce:	00015997          	auipc	s3,0x15
    800022d2:	69a98993          	addi	s3,s3,1690 # 80017968 <tickslock>
        havekids = 1;
    800022d6:	4a85                	li	s5,1
    havekids = 0;
    800022d8:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    800022da:	00010497          	auipc	s1,0x10
    800022de:	a8e48493          	addi	s1,s1,-1394 # 80011d68 <proc>
    800022e2:	a08d                	j	80002344 <wait+0xa8>
          pid = np->pid;
    800022e4:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800022e8:	000b0e63          	beqz	s6,80002304 <wait+0x68>
    800022ec:	4691                	li	a3,4
    800022ee:	03448613          	addi	a2,s1,52
    800022f2:	85da                	mv	a1,s6
    800022f4:	05093503          	ld	a0,80(s2)
    800022f8:	fffff097          	auipc	ra,0xfffff
    800022fc:	3fe080e7          	jalr	1022(ra) # 800016f6 <copyout>
    80002300:	02054263          	bltz	a0,80002324 <wait+0x88>
          freeproc(np);
    80002304:	8526                	mv	a0,s1
    80002306:	00000097          	auipc	ra,0x0
    8000230a:	8ae080e7          	jalr	-1874(ra) # 80001bb4 <freeproc>
          release(&np->lock);
    8000230e:	8526                	mv	a0,s1
    80002310:	fffff097          	auipc	ra,0xfffff
    80002314:	9d8080e7          	jalr	-1576(ra) # 80000ce8 <release>
          release(&p->lock);
    80002318:	854a                	mv	a0,s2
    8000231a:	fffff097          	auipc	ra,0xfffff
    8000231e:	9ce080e7          	jalr	-1586(ra) # 80000ce8 <release>
          return pid;
    80002322:	a8a9                	j	8000237c <wait+0xe0>
            release(&np->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	9c2080e7          	jalr	-1598(ra) # 80000ce8 <release>
            release(&p->lock);
    8000232e:	854a                	mv	a0,s2
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	9b8080e7          	jalr	-1608(ra) # 80000ce8 <release>
            return -1;
    80002338:	59fd                	li	s3,-1
    8000233a:	a089                	j	8000237c <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000233c:	17048493          	addi	s1,s1,368
    80002340:	03348463          	beq	s1,s3,80002368 <wait+0xcc>
      if(np->parent == p){
    80002344:	709c                	ld	a5,32(s1)
    80002346:	ff279be3          	bne	a5,s2,8000233c <wait+0xa0>
        acquire(&np->lock);
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	8e8080e7          	jalr	-1816(ra) # 80000c34 <acquire>
        if(np->state == ZOMBIE){
    80002354:	4c9c                	lw	a5,24(s1)
    80002356:	f94787e3          	beq	a5,s4,800022e4 <wait+0x48>
        release(&np->lock);
    8000235a:	8526                	mv	a0,s1
    8000235c:	fffff097          	auipc	ra,0xfffff
    80002360:	98c080e7          	jalr	-1652(ra) # 80000ce8 <release>
        havekids = 1;
    80002364:	8756                	mv	a4,s5
    80002366:	bfd9                	j	8000233c <wait+0xa0>
    if(!havekids || p->killed){
    80002368:	c701                	beqz	a4,80002370 <wait+0xd4>
    8000236a:	03092783          	lw	a5,48(s2)
    8000236e:	c785                	beqz	a5,80002396 <wait+0xfa>
      release(&p->lock);
    80002370:	854a                	mv	a0,s2
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	976080e7          	jalr	-1674(ra) # 80000ce8 <release>
      return -1;
    8000237a:	59fd                	li	s3,-1
}
    8000237c:	854e                	mv	a0,s3
    8000237e:	60a6                	ld	ra,72(sp)
    80002380:	6406                	ld	s0,64(sp)
    80002382:	74e2                	ld	s1,56(sp)
    80002384:	7942                	ld	s2,48(sp)
    80002386:	79a2                	ld	s3,40(sp)
    80002388:	7a02                	ld	s4,32(sp)
    8000238a:	6ae2                	ld	s5,24(sp)
    8000238c:	6b42                	ld	s6,16(sp)
    8000238e:	6ba2                	ld	s7,8(sp)
    80002390:	6c02                	ld	s8,0(sp)
    80002392:	6161                	addi	sp,sp,80
    80002394:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002396:	85e2                	mv	a1,s8
    80002398:	854a                	mv	a0,s2
    8000239a:	00000097          	auipc	ra,0x0
    8000239e:	e84080e7          	jalr	-380(ra) # 8000221e <sleep>
    havekids = 0;
    800023a2:	bf1d                	j	800022d8 <wait+0x3c>

00000000800023a4 <wakeup>:
{
    800023a4:	7139                	addi	sp,sp,-64
    800023a6:	fc06                	sd	ra,56(sp)
    800023a8:	f822                	sd	s0,48(sp)
    800023aa:	f426                	sd	s1,40(sp)
    800023ac:	f04a                	sd	s2,32(sp)
    800023ae:	ec4e                	sd	s3,24(sp)
    800023b0:	e852                	sd	s4,16(sp)
    800023b2:	e456                	sd	s5,8(sp)
    800023b4:	0080                	addi	s0,sp,64
    800023b6:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    800023b8:	00010497          	auipc	s1,0x10
    800023bc:	9b048493          	addi	s1,s1,-1616 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    800023c0:	4985                	li	s3,1
      p->state = RUNNABLE;
    800023c2:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    800023c4:	00015917          	auipc	s2,0x15
    800023c8:	5a490913          	addi	s2,s2,1444 # 80017968 <tickslock>
    800023cc:	a821                	j	800023e4 <wakeup+0x40>
      p->state = RUNNABLE;
    800023ce:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    800023d2:	8526                	mv	a0,s1
    800023d4:	fffff097          	auipc	ra,0xfffff
    800023d8:	914080e7          	jalr	-1772(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800023dc:	17048493          	addi	s1,s1,368
    800023e0:	01248e63          	beq	s1,s2,800023fc <wakeup+0x58>
    acquire(&p->lock);
    800023e4:	8526                	mv	a0,s1
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	84e080e7          	jalr	-1970(ra) # 80000c34 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    800023ee:	4c9c                	lw	a5,24(s1)
    800023f0:	ff3791e3          	bne	a5,s3,800023d2 <wakeup+0x2e>
    800023f4:	749c                	ld	a5,40(s1)
    800023f6:	fd479ee3          	bne	a5,s4,800023d2 <wakeup+0x2e>
    800023fa:	bfd1                	j	800023ce <wakeup+0x2a>
}
    800023fc:	70e2                	ld	ra,56(sp)
    800023fe:	7442                	ld	s0,48(sp)
    80002400:	74a2                	ld	s1,40(sp)
    80002402:	7902                	ld	s2,32(sp)
    80002404:	69e2                	ld	s3,24(sp)
    80002406:	6a42                	ld	s4,16(sp)
    80002408:	6aa2                	ld	s5,8(sp)
    8000240a:	6121                	addi	sp,sp,64
    8000240c:	8082                	ret

000000008000240e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000240e:	7179                	addi	sp,sp,-48
    80002410:	f406                	sd	ra,40(sp)
    80002412:	f022                	sd	s0,32(sp)
    80002414:	ec26                	sd	s1,24(sp)
    80002416:	e84a                	sd	s2,16(sp)
    80002418:	e44e                	sd	s3,8(sp)
    8000241a:	1800                	addi	s0,sp,48
    8000241c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000241e:	00010497          	auipc	s1,0x10
    80002422:	94a48493          	addi	s1,s1,-1718 # 80011d68 <proc>
    80002426:	00015997          	auipc	s3,0x15
    8000242a:	54298993          	addi	s3,s3,1346 # 80017968 <tickslock>
    acquire(&p->lock);
    8000242e:	8526                	mv	a0,s1
    80002430:	fffff097          	auipc	ra,0xfffff
    80002434:	804080e7          	jalr	-2044(ra) # 80000c34 <acquire>
    if(p->pid == pid){
    80002438:	5c9c                	lw	a5,56(s1)
    8000243a:	01278d63          	beq	a5,s2,80002454 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000243e:	8526                	mv	a0,s1
    80002440:	fffff097          	auipc	ra,0xfffff
    80002444:	8a8080e7          	jalr	-1880(ra) # 80000ce8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002448:	17048493          	addi	s1,s1,368
    8000244c:	ff3491e3          	bne	s1,s3,8000242e <kill+0x20>
  }
  return -1;
    80002450:	557d                	li	a0,-1
    80002452:	a829                	j	8000246c <kill+0x5e>
      p->killed = 1;
    80002454:	4785                	li	a5,1
    80002456:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002458:	4c98                	lw	a4,24(s1)
    8000245a:	4785                	li	a5,1
    8000245c:	00f70f63          	beq	a4,a5,8000247a <kill+0x6c>
      release(&p->lock);
    80002460:	8526                	mv	a0,s1
    80002462:	fffff097          	auipc	ra,0xfffff
    80002466:	886080e7          	jalr	-1914(ra) # 80000ce8 <release>
      return 0;
    8000246a:	4501                	li	a0,0
}
    8000246c:	70a2                	ld	ra,40(sp)
    8000246e:	7402                	ld	s0,32(sp)
    80002470:	64e2                	ld	s1,24(sp)
    80002472:	6942                	ld	s2,16(sp)
    80002474:	69a2                	ld	s3,8(sp)
    80002476:	6145                	addi	sp,sp,48
    80002478:	8082                	ret
        p->state = RUNNABLE;
    8000247a:	4789                	li	a5,2
    8000247c:	cc9c                	sw	a5,24(s1)
    8000247e:	b7cd                	j	80002460 <kill+0x52>

0000000080002480 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002480:	7179                	addi	sp,sp,-48
    80002482:	f406                	sd	ra,40(sp)
    80002484:	f022                	sd	s0,32(sp)
    80002486:	ec26                	sd	s1,24(sp)
    80002488:	e84a                	sd	s2,16(sp)
    8000248a:	e44e                	sd	s3,8(sp)
    8000248c:	e052                	sd	s4,0(sp)
    8000248e:	1800                	addi	s0,sp,48
    80002490:	84aa                	mv	s1,a0
    80002492:	892e                	mv	s2,a1
    80002494:	89b2                	mv	s3,a2
    80002496:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	56a080e7          	jalr	1386(ra) # 80001a02 <myproc>
  if(user_dst){
    800024a0:	c08d                	beqz	s1,800024c2 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024a2:	86d2                	mv	a3,s4
    800024a4:	864e                	mv	a2,s3
    800024a6:	85ca                	mv	a1,s2
    800024a8:	6928                	ld	a0,80(a0)
    800024aa:	fffff097          	auipc	ra,0xfffff
    800024ae:	24c080e7          	jalr	588(ra) # 800016f6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024b2:	70a2                	ld	ra,40(sp)
    800024b4:	7402                	ld	s0,32(sp)
    800024b6:	64e2                	ld	s1,24(sp)
    800024b8:	6942                	ld	s2,16(sp)
    800024ba:	69a2                	ld	s3,8(sp)
    800024bc:	6a02                	ld	s4,0(sp)
    800024be:	6145                	addi	sp,sp,48
    800024c0:	8082                	ret
    memmove((char *)dst, src, len);
    800024c2:	000a061b          	sext.w	a2,s4
    800024c6:	85ce                	mv	a1,s3
    800024c8:	854a                	mv	a0,s2
    800024ca:	fffff097          	auipc	ra,0xfffff
    800024ce:	8c6080e7          	jalr	-1850(ra) # 80000d90 <memmove>
    return 0;
    800024d2:	8526                	mv	a0,s1
    800024d4:	bff9                	j	800024b2 <either_copyout+0x32>

00000000800024d6 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800024d6:	7179                	addi	sp,sp,-48
    800024d8:	f406                	sd	ra,40(sp)
    800024da:	f022                	sd	s0,32(sp)
    800024dc:	ec26                	sd	s1,24(sp)
    800024de:	e84a                	sd	s2,16(sp)
    800024e0:	e44e                	sd	s3,8(sp)
    800024e2:	e052                	sd	s4,0(sp)
    800024e4:	1800                	addi	s0,sp,48
    800024e6:	892a                	mv	s2,a0
    800024e8:	84ae                	mv	s1,a1
    800024ea:	89b2                	mv	s3,a2
    800024ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024ee:	fffff097          	auipc	ra,0xfffff
    800024f2:	514080e7          	jalr	1300(ra) # 80001a02 <myproc>
  if(user_src){
    800024f6:	c08d                	beqz	s1,80002518 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800024f8:	86d2                	mv	a3,s4
    800024fa:	864e                	mv	a2,s3
    800024fc:	85ca                	mv	a1,s2
    800024fe:	6928                	ld	a0,80(a0)
    80002500:	fffff097          	auipc	ra,0xfffff
    80002504:	282080e7          	jalr	642(ra) # 80001782 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002508:	70a2                	ld	ra,40(sp)
    8000250a:	7402                	ld	s0,32(sp)
    8000250c:	64e2                	ld	s1,24(sp)
    8000250e:	6942                	ld	s2,16(sp)
    80002510:	69a2                	ld	s3,8(sp)
    80002512:	6a02                	ld	s4,0(sp)
    80002514:	6145                	addi	sp,sp,48
    80002516:	8082                	ret
    memmove(dst, (char*)src, len);
    80002518:	000a061b          	sext.w	a2,s4
    8000251c:	85ce                	mv	a1,s3
    8000251e:	854a                	mv	a0,s2
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	870080e7          	jalr	-1936(ra) # 80000d90 <memmove>
    return 0;
    80002528:	8526                	mv	a0,s1
    8000252a:	bff9                	j	80002508 <either_copyin+0x32>

000000008000252c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000252c:	715d                	addi	sp,sp,-80
    8000252e:	e486                	sd	ra,72(sp)
    80002530:	e0a2                	sd	s0,64(sp)
    80002532:	fc26                	sd	s1,56(sp)
    80002534:	f84a                	sd	s2,48(sp)
    80002536:	f44e                	sd	s3,40(sp)
    80002538:	f052                	sd	s4,32(sp)
    8000253a:	ec56                	sd	s5,24(sp)
    8000253c:	e85a                	sd	s6,16(sp)
    8000253e:	e45e                	sd	s7,8(sp)
    80002540:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002542:	00006517          	auipc	a0,0x6
    80002546:	b8650513          	addi	a0,a0,-1146 # 800080c8 <digits+0x88>
    8000254a:	ffffe097          	auipc	ra,0xffffe
    8000254e:	048080e7          	jalr	72(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002552:	00010497          	auipc	s1,0x10
    80002556:	96e48493          	addi	s1,s1,-1682 # 80011ec0 <proc+0x158>
    8000255a:	00015917          	auipc	s2,0x15
    8000255e:	56690913          	addi	s2,s2,1382 # 80017ac0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002562:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002564:	00006997          	auipc	s3,0x6
    80002568:	d0498993          	addi	s3,s3,-764 # 80008268 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    8000256c:	00006a97          	auipc	s5,0x6
    80002570:	d04a8a93          	addi	s5,s5,-764 # 80008270 <digits+0x230>
    printf("\n");
    80002574:	00006a17          	auipc	s4,0x6
    80002578:	b54a0a13          	addi	s4,s4,-1196 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000257c:	00006b97          	auipc	s7,0x6
    80002580:	d2cb8b93          	addi	s7,s7,-724 # 800082a8 <states.1707>
    80002584:	a00d                	j	800025a6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002586:	ee06a583          	lw	a1,-288(a3)
    8000258a:	8556                	mv	a0,s5
    8000258c:	ffffe097          	auipc	ra,0xffffe
    80002590:	006080e7          	jalr	6(ra) # 80000592 <printf>
    printf("\n");
    80002594:	8552                	mv	a0,s4
    80002596:	ffffe097          	auipc	ra,0xffffe
    8000259a:	ffc080e7          	jalr	-4(ra) # 80000592 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000259e:	17048493          	addi	s1,s1,368
    800025a2:	03248163          	beq	s1,s2,800025c4 <procdump+0x98>
    if(p->state == UNUSED)
    800025a6:	86a6                	mv	a3,s1
    800025a8:	ec04a783          	lw	a5,-320(s1)
    800025ac:	dbed                	beqz	a5,8000259e <procdump+0x72>
      state = "???";
    800025ae:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b0:	fcfb6be3          	bltu	s6,a5,80002586 <procdump+0x5a>
    800025b4:	1782                	slli	a5,a5,0x20
    800025b6:	9381                	srli	a5,a5,0x20
    800025b8:	078e                	slli	a5,a5,0x3
    800025ba:	97de                	add	a5,a5,s7
    800025bc:	6390                	ld	a2,0(a5)
    800025be:	f661                	bnez	a2,80002586 <procdump+0x5a>
      state = "???";
    800025c0:	864e                	mv	a2,s3
    800025c2:	b7d1                	j	80002586 <procdump+0x5a>
  }
}
    800025c4:	60a6                	ld	ra,72(sp)
    800025c6:	6406                	ld	s0,64(sp)
    800025c8:	74e2                	ld	s1,56(sp)
    800025ca:	7942                	ld	s2,48(sp)
    800025cc:	79a2                	ld	s3,40(sp)
    800025ce:	7a02                	ld	s4,32(sp)
    800025d0:	6ae2                	ld	s5,24(sp)
    800025d2:	6b42                	ld	s6,16(sp)
    800025d4:	6ba2                	ld	s7,8(sp)
    800025d6:	6161                	addi	sp,sp,80
    800025d8:	8082                	ret

00000000800025da <countprocess>:

uint64 
countprocess(void)
{
    800025da:	1141                	addi	sp,sp,-16
    800025dc:	e422                	sd	s0,8(sp)
    800025de:	0800                	addi	s0,sp,16
  uint64 cnt = 0;
  int i;

  for (i = 0; i < NPROC; i++)
    800025e0:	0000f797          	auipc	a5,0xf
    800025e4:	7a078793          	addi	a5,a5,1952 # 80011d80 <proc+0x18>
    800025e8:	00015697          	auipc	a3,0x15
    800025ec:	39868693          	addi	a3,a3,920 # 80017980 <bcache>
  uint64 cnt = 0;
    800025f0:	4501                	li	a0,0
  {
    if (proc[i].state != UNUSED)
    800025f2:	4398                	lw	a4,0(a5)
      cnt++;
    800025f4:	00e03733          	snez	a4,a4
    800025f8:	953a                	add	a0,a0,a4
  for (i = 0; i < NPROC; i++)
    800025fa:	17078793          	addi	a5,a5,368
    800025fe:	fed79ae3          	bne	a5,a3,800025f2 <countprocess+0x18>
  }
  return cnt;
    80002602:	6422                	ld	s0,8(sp)
    80002604:	0141                	addi	sp,sp,16
    80002606:	8082                	ret

0000000080002608 <swtch>:
    80002608:	00153023          	sd	ra,0(a0)
    8000260c:	00253423          	sd	sp,8(a0)
    80002610:	e900                	sd	s0,16(a0)
    80002612:	ed04                	sd	s1,24(a0)
    80002614:	03253023          	sd	s2,32(a0)
    80002618:	03353423          	sd	s3,40(a0)
    8000261c:	03453823          	sd	s4,48(a0)
    80002620:	03553c23          	sd	s5,56(a0)
    80002624:	05653023          	sd	s6,64(a0)
    80002628:	05753423          	sd	s7,72(a0)
    8000262c:	05853823          	sd	s8,80(a0)
    80002630:	05953c23          	sd	s9,88(a0)
    80002634:	07a53023          	sd	s10,96(a0)
    80002638:	07b53423          	sd	s11,104(a0)
    8000263c:	0005b083          	ld	ra,0(a1)
    80002640:	0085b103          	ld	sp,8(a1)
    80002644:	6980                	ld	s0,16(a1)
    80002646:	6d84                	ld	s1,24(a1)
    80002648:	0205b903          	ld	s2,32(a1)
    8000264c:	0285b983          	ld	s3,40(a1)
    80002650:	0305ba03          	ld	s4,48(a1)
    80002654:	0385ba83          	ld	s5,56(a1)
    80002658:	0405bb03          	ld	s6,64(a1)
    8000265c:	0485bb83          	ld	s7,72(a1)
    80002660:	0505bc03          	ld	s8,80(a1)
    80002664:	0585bc83          	ld	s9,88(a1)
    80002668:	0605bd03          	ld	s10,96(a1)
    8000266c:	0685bd83          	ld	s11,104(a1)
    80002670:	8082                	ret

0000000080002672 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002672:	1141                	addi	sp,sp,-16
    80002674:	e406                	sd	ra,8(sp)
    80002676:	e022                	sd	s0,0(sp)
    80002678:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000267a:	00006597          	auipc	a1,0x6
    8000267e:	c5658593          	addi	a1,a1,-938 # 800082d0 <states.1707+0x28>
    80002682:	00015517          	auipc	a0,0x15
    80002686:	2e650513          	addi	a0,a0,742 # 80017968 <tickslock>
    8000268a:	ffffe097          	auipc	ra,0xffffe
    8000268e:	51a080e7          	jalr	1306(ra) # 80000ba4 <initlock>
}
    80002692:	60a2                	ld	ra,8(sp)
    80002694:	6402                	ld	s0,0(sp)
    80002696:	0141                	addi	sp,sp,16
    80002698:	8082                	ret

000000008000269a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000269a:	1141                	addi	sp,sp,-16
    8000269c:	e422                	sd	s0,8(sp)
    8000269e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026a0:	00003797          	auipc	a5,0x3
    800026a4:	59078793          	addi	a5,a5,1424 # 80005c30 <kernelvec>
    800026a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ac:	6422                	ld	s0,8(sp)
    800026ae:	0141                	addi	sp,sp,16
    800026b0:	8082                	ret

00000000800026b2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026b2:	1141                	addi	sp,sp,-16
    800026b4:	e406                	sd	ra,8(sp)
    800026b6:	e022                	sd	s0,0(sp)
    800026b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026ba:	fffff097          	auipc	ra,0xfffff
    800026be:	348080e7          	jalr	840(ra) # 80001a02 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026cc:	00005617          	auipc	a2,0x5
    800026d0:	93460613          	addi	a2,a2,-1740 # 80007000 <_trampoline>
    800026d4:	00005697          	auipc	a3,0x5
    800026d8:	92c68693          	addi	a3,a3,-1748 # 80007000 <_trampoline>
    800026dc:	8e91                	sub	a3,a3,a2
    800026de:	040007b7          	lui	a5,0x4000
    800026e2:	17fd                	addi	a5,a5,-1
    800026e4:	07b2                	slli	a5,a5,0xc
    800026e6:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026e8:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800026ec:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800026ee:	180026f3          	csrr	a3,satp
    800026f2:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800026f4:	6d38                	ld	a4,88(a0)
    800026f6:	6134                	ld	a3,64(a0)
    800026f8:	6585                	lui	a1,0x1
    800026fa:	96ae                	add	a3,a3,a1
    800026fc:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800026fe:	6d38                	ld	a4,88(a0)
    80002700:	00000697          	auipc	a3,0x0
    80002704:	13868693          	addi	a3,a3,312 # 80002838 <usertrap>
    80002708:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000270a:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000270c:	8692                	mv	a3,tp
    8000270e:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002710:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002714:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002718:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271c:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002720:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002722:	6f18                	ld	a4,24(a4)
    80002724:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002728:	692c                	ld	a1,80(a0)
    8000272a:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000272c:	00005717          	auipc	a4,0x5
    80002730:	96470713          	addi	a4,a4,-1692 # 80007090 <userret>
    80002734:	8f11                	sub	a4,a4,a2
    80002736:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002738:	577d                	li	a4,-1
    8000273a:	177e                	slli	a4,a4,0x3f
    8000273c:	8dd9                	or	a1,a1,a4
    8000273e:	02000537          	lui	a0,0x2000
    80002742:	157d                	addi	a0,a0,-1
    80002744:	0536                	slli	a0,a0,0xd
    80002746:	9782                	jalr	a5
}
    80002748:	60a2                	ld	ra,8(sp)
    8000274a:	6402                	ld	s0,0(sp)
    8000274c:	0141                	addi	sp,sp,16
    8000274e:	8082                	ret

0000000080002750 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002750:	1101                	addi	sp,sp,-32
    80002752:	ec06                	sd	ra,24(sp)
    80002754:	e822                	sd	s0,16(sp)
    80002756:	e426                	sd	s1,8(sp)
    80002758:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000275a:	00015497          	auipc	s1,0x15
    8000275e:	20e48493          	addi	s1,s1,526 # 80017968 <tickslock>
    80002762:	8526                	mv	a0,s1
    80002764:	ffffe097          	auipc	ra,0xffffe
    80002768:	4d0080e7          	jalr	1232(ra) # 80000c34 <acquire>
  ticks++;
    8000276c:	00007517          	auipc	a0,0x7
    80002770:	8b450513          	addi	a0,a0,-1868 # 80009020 <ticks>
    80002774:	411c                	lw	a5,0(a0)
    80002776:	2785                	addiw	a5,a5,1
    80002778:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000277a:	00000097          	auipc	ra,0x0
    8000277e:	c2a080e7          	jalr	-982(ra) # 800023a4 <wakeup>
  release(&tickslock);
    80002782:	8526                	mv	a0,s1
    80002784:	ffffe097          	auipc	ra,0xffffe
    80002788:	564080e7          	jalr	1380(ra) # 80000ce8 <release>
}
    8000278c:	60e2                	ld	ra,24(sp)
    8000278e:	6442                	ld	s0,16(sp)
    80002790:	64a2                	ld	s1,8(sp)
    80002792:	6105                	addi	sp,sp,32
    80002794:	8082                	ret

0000000080002796 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002796:	1101                	addi	sp,sp,-32
    80002798:	ec06                	sd	ra,24(sp)
    8000279a:	e822                	sd	s0,16(sp)
    8000279c:	e426                	sd	s1,8(sp)
    8000279e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027a0:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027a4:	00074d63          	bltz	a4,800027be <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027a8:	57fd                	li	a5,-1
    800027aa:	17fe                	slli	a5,a5,0x3f
    800027ac:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027ae:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027b0:	06f70363          	beq	a4,a5,80002816 <devintr+0x80>
  }
}
    800027b4:	60e2                	ld	ra,24(sp)
    800027b6:	6442                	ld	s0,16(sp)
    800027b8:	64a2                	ld	s1,8(sp)
    800027ba:	6105                	addi	sp,sp,32
    800027bc:	8082                	ret
     (scause & 0xff) == 9){
    800027be:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027c2:	46a5                	li	a3,9
    800027c4:	fed792e3          	bne	a5,a3,800027a8 <devintr+0x12>
    int irq = plic_claim();
    800027c8:	00003097          	auipc	ra,0x3
    800027cc:	570080e7          	jalr	1392(ra) # 80005d38 <plic_claim>
    800027d0:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027d2:	47a9                	li	a5,10
    800027d4:	02f50763          	beq	a0,a5,80002802 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027d8:	4785                	li	a5,1
    800027da:	02f50963          	beq	a0,a5,8000280c <devintr+0x76>
    return 1;
    800027de:	4505                	li	a0,1
    } else if(irq){
    800027e0:	d8f1                	beqz	s1,800027b4 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800027e2:	85a6                	mv	a1,s1
    800027e4:	00006517          	auipc	a0,0x6
    800027e8:	af450513          	addi	a0,a0,-1292 # 800082d8 <states.1707+0x30>
    800027ec:	ffffe097          	auipc	ra,0xffffe
    800027f0:	da6080e7          	jalr	-602(ra) # 80000592 <printf>
      plic_complete(irq);
    800027f4:	8526                	mv	a0,s1
    800027f6:	00003097          	auipc	ra,0x3
    800027fa:	566080e7          	jalr	1382(ra) # 80005d5c <plic_complete>
    return 1;
    800027fe:	4505                	li	a0,1
    80002800:	bf55                	j	800027b4 <devintr+0x1e>
      uartintr();
    80002802:	ffffe097          	auipc	ra,0xffffe
    80002806:	1d2080e7          	jalr	466(ra) # 800009d4 <uartintr>
    8000280a:	b7ed                	j	800027f4 <devintr+0x5e>
      virtio_disk_intr();
    8000280c:	00004097          	auipc	ra,0x4
    80002810:	9ea080e7          	jalr	-1558(ra) # 800061f6 <virtio_disk_intr>
    80002814:	b7c5                	j	800027f4 <devintr+0x5e>
    if(cpuid() == 0){
    80002816:	fffff097          	auipc	ra,0xfffff
    8000281a:	1c0080e7          	jalr	448(ra) # 800019d6 <cpuid>
    8000281e:	c901                	beqz	a0,8000282e <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002820:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002824:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002826:	14479073          	csrw	sip,a5
    return 2;
    8000282a:	4509                	li	a0,2
    8000282c:	b761                	j	800027b4 <devintr+0x1e>
      clockintr();
    8000282e:	00000097          	auipc	ra,0x0
    80002832:	f22080e7          	jalr	-222(ra) # 80002750 <clockintr>
    80002836:	b7ed                	j	80002820 <devintr+0x8a>

0000000080002838 <usertrap>:
{
    80002838:	1101                	addi	sp,sp,-32
    8000283a:	ec06                	sd	ra,24(sp)
    8000283c:	e822                	sd	s0,16(sp)
    8000283e:	e426                	sd	s1,8(sp)
    80002840:	e04a                	sd	s2,0(sp)
    80002842:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002844:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002848:	1007f793          	andi	a5,a5,256
    8000284c:	e3ad                	bnez	a5,800028ae <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000284e:	00003797          	auipc	a5,0x3
    80002852:	3e278793          	addi	a5,a5,994 # 80005c30 <kernelvec>
    80002856:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000285a:	fffff097          	auipc	ra,0xfffff
    8000285e:	1a8080e7          	jalr	424(ra) # 80001a02 <myproc>
    80002862:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002864:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002866:	14102773          	csrr	a4,sepc
    8000286a:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000286c:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002870:	47a1                	li	a5,8
    80002872:	04f71c63          	bne	a4,a5,800028ca <usertrap+0x92>
    if(p->killed)
    80002876:	591c                	lw	a5,48(a0)
    80002878:	e3b9                	bnez	a5,800028be <usertrap+0x86>
    p->trapframe->epc += 4;
    8000287a:	6cb8                	ld	a4,88(s1)
    8000287c:	6f1c                	ld	a5,24(a4)
    8000287e:	0791                	addi	a5,a5,4
    80002880:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002882:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002886:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000288a:	10079073          	csrw	sstatus,a5
    syscall();
    8000288e:	00000097          	auipc	ra,0x0
    80002892:	2e0080e7          	jalr	736(ra) # 80002b6e <syscall>
  if(p->killed)
    80002896:	589c                	lw	a5,48(s1)
    80002898:	ebc1                	bnez	a5,80002928 <usertrap+0xf0>
  usertrapret();
    8000289a:	00000097          	auipc	ra,0x0
    8000289e:	e18080e7          	jalr	-488(ra) # 800026b2 <usertrapret>
}
    800028a2:	60e2                	ld	ra,24(sp)
    800028a4:	6442                	ld	s0,16(sp)
    800028a6:	64a2                	ld	s1,8(sp)
    800028a8:	6902                	ld	s2,0(sp)
    800028aa:	6105                	addi	sp,sp,32
    800028ac:	8082                	ret
    panic("usertrap: not from user mode");
    800028ae:	00006517          	auipc	a0,0x6
    800028b2:	a4a50513          	addi	a0,a0,-1462 # 800082f8 <states.1707+0x50>
    800028b6:	ffffe097          	auipc	ra,0xffffe
    800028ba:	c92080e7          	jalr	-878(ra) # 80000548 <panic>
      exit(-1);
    800028be:	557d                	li	a0,-1
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	818080e7          	jalr	-2024(ra) # 800020d8 <exit>
    800028c8:	bf4d                	j	8000287a <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028ca:	00000097          	auipc	ra,0x0
    800028ce:	ecc080e7          	jalr	-308(ra) # 80002796 <devintr>
    800028d2:	892a                	mv	s2,a0
    800028d4:	c501                	beqz	a0,800028dc <usertrap+0xa4>
  if(p->killed)
    800028d6:	589c                	lw	a5,48(s1)
    800028d8:	c3a1                	beqz	a5,80002918 <usertrap+0xe0>
    800028da:	a815                	j	8000290e <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028dc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800028e0:	5c90                	lw	a2,56(s1)
    800028e2:	00006517          	auipc	a0,0x6
    800028e6:	a3650513          	addi	a0,a0,-1482 # 80008318 <states.1707+0x70>
    800028ea:	ffffe097          	auipc	ra,0xffffe
    800028ee:	ca8080e7          	jalr	-856(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028f2:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800028f6:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    800028fa:	00006517          	auipc	a0,0x6
    800028fe:	a4e50513          	addi	a0,a0,-1458 # 80008348 <states.1707+0xa0>
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	c90080e7          	jalr	-880(ra) # 80000592 <printf>
    p->killed = 1;
    8000290a:	4785                	li	a5,1
    8000290c:	d89c                	sw	a5,48(s1)
    exit(-1);
    8000290e:	557d                	li	a0,-1
    80002910:	fffff097          	auipc	ra,0xfffff
    80002914:	7c8080e7          	jalr	1992(ra) # 800020d8 <exit>
  if(which_dev == 2)
    80002918:	4789                	li	a5,2
    8000291a:	f8f910e3          	bne	s2,a5,8000289a <usertrap+0x62>
    yield();
    8000291e:	00000097          	auipc	ra,0x0
    80002922:	8c4080e7          	jalr	-1852(ra) # 800021e2 <yield>
    80002926:	bf95                	j	8000289a <usertrap+0x62>
  int which_dev = 0;
    80002928:	4901                	li	s2,0
    8000292a:	b7d5                	j	8000290e <usertrap+0xd6>

000000008000292c <kerneltrap>:
{
    8000292c:	7179                	addi	sp,sp,-48
    8000292e:	f406                	sd	ra,40(sp)
    80002930:	f022                	sd	s0,32(sp)
    80002932:	ec26                	sd	s1,24(sp)
    80002934:	e84a                	sd	s2,16(sp)
    80002936:	e44e                	sd	s3,8(sp)
    80002938:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000293a:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000293e:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002942:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002946:	1004f793          	andi	a5,s1,256
    8000294a:	cb85                	beqz	a5,8000297a <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000294c:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002950:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002952:	ef85                	bnez	a5,8000298a <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002954:	00000097          	auipc	ra,0x0
    80002958:	e42080e7          	jalr	-446(ra) # 80002796 <devintr>
    8000295c:	cd1d                	beqz	a0,8000299a <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000295e:	4789                	li	a5,2
    80002960:	06f50a63          	beq	a0,a5,800029d4 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002964:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002968:	10049073          	csrw	sstatus,s1
}
    8000296c:	70a2                	ld	ra,40(sp)
    8000296e:	7402                	ld	s0,32(sp)
    80002970:	64e2                	ld	s1,24(sp)
    80002972:	6942                	ld	s2,16(sp)
    80002974:	69a2                	ld	s3,8(sp)
    80002976:	6145                	addi	sp,sp,48
    80002978:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    8000297a:	00006517          	auipc	a0,0x6
    8000297e:	9ee50513          	addi	a0,a0,-1554 # 80008368 <states.1707+0xc0>
    80002982:	ffffe097          	auipc	ra,0xffffe
    80002986:	bc6080e7          	jalr	-1082(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    8000298a:	00006517          	auipc	a0,0x6
    8000298e:	a0650513          	addi	a0,a0,-1530 # 80008390 <states.1707+0xe8>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	bb6080e7          	jalr	-1098(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    8000299a:	85ce                	mv	a1,s3
    8000299c:	00006517          	auipc	a0,0x6
    800029a0:	a1450513          	addi	a0,a0,-1516 # 800083b0 <states.1707+0x108>
    800029a4:	ffffe097          	auipc	ra,0xffffe
    800029a8:	bee080e7          	jalr	-1042(ra) # 80000592 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029ac:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    800029b0:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    800029b4:	00006517          	auipc	a0,0x6
    800029b8:	a0c50513          	addi	a0,a0,-1524 # 800083c0 <states.1707+0x118>
    800029bc:	ffffe097          	auipc	ra,0xffffe
    800029c0:	bd6080e7          	jalr	-1066(ra) # 80000592 <printf>
    panic("kerneltrap");
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	a1450513          	addi	a0,a0,-1516 # 800083d8 <states.1707+0x130>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	b7c080e7          	jalr	-1156(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029d4:	fffff097          	auipc	ra,0xfffff
    800029d8:	02e080e7          	jalr	46(ra) # 80001a02 <myproc>
    800029dc:	d541                	beqz	a0,80002964 <kerneltrap+0x38>
    800029de:	fffff097          	auipc	ra,0xfffff
    800029e2:	024080e7          	jalr	36(ra) # 80001a02 <myproc>
    800029e6:	4d18                	lw	a4,24(a0)
    800029e8:	478d                	li	a5,3
    800029ea:	f6f71de3          	bne	a4,a5,80002964 <kerneltrap+0x38>
    yield();
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	7f4080e7          	jalr	2036(ra) # 800021e2 <yield>
    800029f6:	b7bd                	j	80002964 <kerneltrap+0x38>

00000000800029f8 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    800029f8:	1101                	addi	sp,sp,-32
    800029fa:	ec06                	sd	ra,24(sp)
    800029fc:	e822                	sd	s0,16(sp)
    800029fe:	e426                	sd	s1,8(sp)
    80002a00:	1000                	addi	s0,sp,32
    80002a02:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a04:	fffff097          	auipc	ra,0xfffff
    80002a08:	ffe080e7          	jalr	-2(ra) # 80001a02 <myproc>
  switch (n) {
    80002a0c:	4795                	li	a5,5
    80002a0e:	0497e163          	bltu	a5,s1,80002a50 <argraw+0x58>
    80002a12:	048a                	slli	s1,s1,0x2
    80002a14:	00006717          	auipc	a4,0x6
    80002a18:	ac470713          	addi	a4,a4,-1340 # 800084d8 <states.1707+0x230>
    80002a1c:	94ba                	add	s1,s1,a4
    80002a1e:	409c                	lw	a5,0(s1)
    80002a20:	97ba                	add	a5,a5,a4
    80002a22:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a24:	6d3c                	ld	a5,88(a0)
    80002a26:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a28:	60e2                	ld	ra,24(sp)
    80002a2a:	6442                	ld	s0,16(sp)
    80002a2c:	64a2                	ld	s1,8(sp)
    80002a2e:	6105                	addi	sp,sp,32
    80002a30:	8082                	ret
    return p->trapframe->a1;
    80002a32:	6d3c                	ld	a5,88(a0)
    80002a34:	7fa8                	ld	a0,120(a5)
    80002a36:	bfcd                	j	80002a28 <argraw+0x30>
    return p->trapframe->a2;
    80002a38:	6d3c                	ld	a5,88(a0)
    80002a3a:	63c8                	ld	a0,128(a5)
    80002a3c:	b7f5                	j	80002a28 <argraw+0x30>
    return p->trapframe->a3;
    80002a3e:	6d3c                	ld	a5,88(a0)
    80002a40:	67c8                	ld	a0,136(a5)
    80002a42:	b7dd                	j	80002a28 <argraw+0x30>
    return p->trapframe->a4;
    80002a44:	6d3c                	ld	a5,88(a0)
    80002a46:	6bc8                	ld	a0,144(a5)
    80002a48:	b7c5                	j	80002a28 <argraw+0x30>
    return p->trapframe->a5;
    80002a4a:	6d3c                	ld	a5,88(a0)
    80002a4c:	6fc8                	ld	a0,152(a5)
    80002a4e:	bfe9                	j	80002a28 <argraw+0x30>
  panic("argraw");
    80002a50:	00006517          	auipc	a0,0x6
    80002a54:	99850513          	addi	a0,a0,-1640 # 800083e8 <states.1707+0x140>
    80002a58:	ffffe097          	auipc	ra,0xffffe
    80002a5c:	af0080e7          	jalr	-1296(ra) # 80000548 <panic>

0000000080002a60 <fetchaddr>:
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	e04a                	sd	s2,0(sp)
    80002a6a:	1000                	addi	s0,sp,32
    80002a6c:	84aa                	mv	s1,a0
    80002a6e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002a70:	fffff097          	auipc	ra,0xfffff
    80002a74:	f92080e7          	jalr	-110(ra) # 80001a02 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002a78:	653c                	ld	a5,72(a0)
    80002a7a:	02f4f863          	bgeu	s1,a5,80002aaa <fetchaddr+0x4a>
    80002a7e:	00848713          	addi	a4,s1,8
    80002a82:	02e7e663          	bltu	a5,a4,80002aae <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002a86:	46a1                	li	a3,8
    80002a88:	8626                	mv	a2,s1
    80002a8a:	85ca                	mv	a1,s2
    80002a8c:	6928                	ld	a0,80(a0)
    80002a8e:	fffff097          	auipc	ra,0xfffff
    80002a92:	cf4080e7          	jalr	-780(ra) # 80001782 <copyin>
    80002a96:	00a03533          	snez	a0,a0
    80002a9a:	40a00533          	neg	a0,a0
}
    80002a9e:	60e2                	ld	ra,24(sp)
    80002aa0:	6442                	ld	s0,16(sp)
    80002aa2:	64a2                	ld	s1,8(sp)
    80002aa4:	6902                	ld	s2,0(sp)
    80002aa6:	6105                	addi	sp,sp,32
    80002aa8:	8082                	ret
    return -1;
    80002aaa:	557d                	li	a0,-1
    80002aac:	bfcd                	j	80002a9e <fetchaddr+0x3e>
    80002aae:	557d                	li	a0,-1
    80002ab0:	b7fd                	j	80002a9e <fetchaddr+0x3e>

0000000080002ab2 <fetchstr>:
{
    80002ab2:	7179                	addi	sp,sp,-48
    80002ab4:	f406                	sd	ra,40(sp)
    80002ab6:	f022                	sd	s0,32(sp)
    80002ab8:	ec26                	sd	s1,24(sp)
    80002aba:	e84a                	sd	s2,16(sp)
    80002abc:	e44e                	sd	s3,8(sp)
    80002abe:	1800                	addi	s0,sp,48
    80002ac0:	892a                	mv	s2,a0
    80002ac2:	84ae                	mv	s1,a1
    80002ac4:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002ac6:	fffff097          	auipc	ra,0xfffff
    80002aca:	f3c080e7          	jalr	-196(ra) # 80001a02 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002ace:	86ce                	mv	a3,s3
    80002ad0:	864a                	mv	a2,s2
    80002ad2:	85a6                	mv	a1,s1
    80002ad4:	6928                	ld	a0,80(a0)
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	d38080e7          	jalr	-712(ra) # 8000180e <copyinstr>
  if(err < 0)
    80002ade:	00054763          	bltz	a0,80002aec <fetchstr+0x3a>
  return strlen(buf);
    80002ae2:	8526                	mv	a0,s1
    80002ae4:	ffffe097          	auipc	ra,0xffffe
    80002ae8:	3d4080e7          	jalr	980(ra) # 80000eb8 <strlen>
}
    80002aec:	70a2                	ld	ra,40(sp)
    80002aee:	7402                	ld	s0,32(sp)
    80002af0:	64e2                	ld	s1,24(sp)
    80002af2:	6942                	ld	s2,16(sp)
    80002af4:	69a2                	ld	s3,8(sp)
    80002af6:	6145                	addi	sp,sp,48
    80002af8:	8082                	ret

0000000080002afa <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002afa:	1101                	addi	sp,sp,-32
    80002afc:	ec06                	sd	ra,24(sp)
    80002afe:	e822                	sd	s0,16(sp)
    80002b00:	e426                	sd	s1,8(sp)
    80002b02:	1000                	addi	s0,sp,32
    80002b04:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b06:	00000097          	auipc	ra,0x0
    80002b0a:	ef2080e7          	jalr	-270(ra) # 800029f8 <argraw>
    80002b0e:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b10:	4501                	li	a0,0
    80002b12:	60e2                	ld	ra,24(sp)
    80002b14:	6442                	ld	s0,16(sp)
    80002b16:	64a2                	ld	s1,8(sp)
    80002b18:	6105                	addi	sp,sp,32
    80002b1a:	8082                	ret

0000000080002b1c <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b1c:	1101                	addi	sp,sp,-32
    80002b1e:	ec06                	sd	ra,24(sp)
    80002b20:	e822                	sd	s0,16(sp)
    80002b22:	e426                	sd	s1,8(sp)
    80002b24:	1000                	addi	s0,sp,32
    80002b26:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b28:	00000097          	auipc	ra,0x0
    80002b2c:	ed0080e7          	jalr	-304(ra) # 800029f8 <argraw>
    80002b30:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b32:	4501                	li	a0,0
    80002b34:	60e2                	ld	ra,24(sp)
    80002b36:	6442                	ld	s0,16(sp)
    80002b38:	64a2                	ld	s1,8(sp)
    80002b3a:	6105                	addi	sp,sp,32
    80002b3c:	8082                	ret

0000000080002b3e <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002b3e:	1101                	addi	sp,sp,-32
    80002b40:	ec06                	sd	ra,24(sp)
    80002b42:	e822                	sd	s0,16(sp)
    80002b44:	e426                	sd	s1,8(sp)
    80002b46:	e04a                	sd	s2,0(sp)
    80002b48:	1000                	addi	s0,sp,32
    80002b4a:	84ae                	mv	s1,a1
    80002b4c:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002b4e:	00000097          	auipc	ra,0x0
    80002b52:	eaa080e7          	jalr	-342(ra) # 800029f8 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002b56:	864a                	mv	a2,s2
    80002b58:	85a6                	mv	a1,s1
    80002b5a:	00000097          	auipc	ra,0x0
    80002b5e:	f58080e7          	jalr	-168(ra) # 80002ab2 <fetchstr>
}
    80002b62:	60e2                	ld	ra,24(sp)
    80002b64:	6442                	ld	s0,16(sp)
    80002b66:	64a2                	ld	s1,8(sp)
    80002b68:	6902                	ld	s2,0(sp)
    80002b6a:	6105                	addi	sp,sp,32
    80002b6c:	8082                	ret

0000000080002b6e <syscall>:
[SYS_sysinfo] "sysinfo",
};

void
syscall(void)
{
    80002b6e:	7179                	addi	sp,sp,-48
    80002b70:	f406                	sd	ra,40(sp)
    80002b72:	f022                	sd	s0,32(sp)
    80002b74:	ec26                	sd	s1,24(sp)
    80002b76:	e84a                	sd	s2,16(sp)
    80002b78:	e44e                	sd	s3,8(sp)
    80002b7a:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002b7c:	fffff097          	auipc	ra,0xfffff
    80002b80:	e86080e7          	jalr	-378(ra) # 80001a02 <myproc>
    80002b84:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002b86:	05853903          	ld	s2,88(a0)
    80002b8a:	0a893783          	ld	a5,168(s2)
    80002b8e:	0007899b          	sext.w	s3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002b92:	37fd                	addiw	a5,a5,-1
    80002b94:	4759                	li	a4,22
    80002b96:	04f76863          	bltu	a4,a5,80002be6 <syscall+0x78>
    80002b9a:	00399713          	slli	a4,s3,0x3
    80002b9e:	00006797          	auipc	a5,0x6
    80002ba2:	95278793          	addi	a5,a5,-1710 # 800084f0 <syscalls>
    80002ba6:	97ba                	add	a5,a5,a4
    80002ba8:	639c                	ld	a5,0(a5)
    80002baa:	cf95                	beqz	a5,80002be6 <syscall+0x78>
    p->trapframe->a0 = syscalls[num]();
    80002bac:	9782                	jalr	a5
    80002bae:	06a93823          	sd	a0,112(s2)
    if (((1 << num) & p->trace_mask) != 0)
    80002bb2:	1684a783          	lw	a5,360(s1)
    80002bb6:	4137d7bb          	sraw	a5,a5,s3
    80002bba:	8b85                	andi	a5,a5,1
    80002bbc:	c7a1                	beqz	a5,80002c04 <syscall+0x96>
      printf("%d: syscall %s -> %d\n", p->pid, syscall_names[num], p->trapframe->a0);
    80002bbe:	6cb8                	ld	a4,88(s1)
    80002bc0:	098e                	slli	s3,s3,0x3
    80002bc2:	00006797          	auipc	a5,0x6
    80002bc6:	92e78793          	addi	a5,a5,-1746 # 800084f0 <syscalls>
    80002bca:	99be                	add	s3,s3,a5
    80002bcc:	7b34                	ld	a3,112(a4)
    80002bce:	0c09b603          	ld	a2,192(s3)
    80002bd2:	5c8c                	lw	a1,56(s1)
    80002bd4:	00006517          	auipc	a0,0x6
    80002bd8:	81c50513          	addi	a0,a0,-2020 # 800083f0 <states.1707+0x148>
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	9b6080e7          	jalr	-1610(ra) # 80000592 <printf>
    80002be4:	a005                	j	80002c04 <syscall+0x96>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002be6:	86ce                	mv	a3,s3
    80002be8:	15848613          	addi	a2,s1,344
    80002bec:	5c8c                	lw	a1,56(s1)
    80002bee:	00006517          	auipc	a0,0x6
    80002bf2:	81a50513          	addi	a0,a0,-2022 # 80008408 <states.1707+0x160>
    80002bf6:	ffffe097          	auipc	ra,0xffffe
    80002bfa:	99c080e7          	jalr	-1636(ra) # 80000592 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002bfe:	6cbc                	ld	a5,88(s1)
    80002c00:	577d                	li	a4,-1
    80002c02:	fbb8                	sd	a4,112(a5)
  }
} 
    80002c04:	70a2                	ld	ra,40(sp)
    80002c06:	7402                	ld	s0,32(sp)
    80002c08:	64e2                	ld	s1,24(sp)
    80002c0a:	6942                	ld	s2,16(sp)
    80002c0c:	69a2                	ld	s3,8(sp)
    80002c0e:	6145                	addi	sp,sp,48
    80002c10:	8082                	ret

0000000080002c12 <sys_exit>:
#include "proc.h"
#include "sysinfo.h"

uint64
sys_exit(void)
{
    80002c12:	1101                	addi	sp,sp,-32
    80002c14:	ec06                	sd	ra,24(sp)
    80002c16:	e822                	sd	s0,16(sp)
    80002c18:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c1a:	fec40593          	addi	a1,s0,-20
    80002c1e:	4501                	li	a0,0
    80002c20:	00000097          	auipc	ra,0x0
    80002c24:	eda080e7          	jalr	-294(ra) # 80002afa <argint>
    return -1;
    80002c28:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c2a:	00054963          	bltz	a0,80002c3c <sys_exit+0x2a>
  exit(n);
    80002c2e:	fec42503          	lw	a0,-20(s0)
    80002c32:	fffff097          	auipc	ra,0xfffff
    80002c36:	4a6080e7          	jalr	1190(ra) # 800020d8 <exit>
  return 0;  // not reached
    80002c3a:	4781                	li	a5,0
}
    80002c3c:	853e                	mv	a0,a5
    80002c3e:	60e2                	ld	ra,24(sp)
    80002c40:	6442                	ld	s0,16(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret

0000000080002c46 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c46:	1141                	addi	sp,sp,-16
    80002c48:	e406                	sd	ra,8(sp)
    80002c4a:	e022                	sd	s0,0(sp)
    80002c4c:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c4e:	fffff097          	auipc	ra,0xfffff
    80002c52:	db4080e7          	jalr	-588(ra) # 80001a02 <myproc>
}
    80002c56:	5d08                	lw	a0,56(a0)
    80002c58:	60a2                	ld	ra,8(sp)
    80002c5a:	6402                	ld	s0,0(sp)
    80002c5c:	0141                	addi	sp,sp,16
    80002c5e:	8082                	ret

0000000080002c60 <sys_fork>:

uint64
sys_fork(void)
{
    80002c60:	1141                	addi	sp,sp,-16
    80002c62:	e406                	sd	ra,8(sp)
    80002c64:	e022                	sd	s0,0(sp)
    80002c66:	0800                	addi	s0,sp,16
  return fork();
    80002c68:	fffff097          	auipc	ra,0xfffff
    80002c6c:	162080e7          	jalr	354(ra) # 80001dca <fork>
}
    80002c70:	60a2                	ld	ra,8(sp)
    80002c72:	6402                	ld	s0,0(sp)
    80002c74:	0141                	addi	sp,sp,16
    80002c76:	8082                	ret

0000000080002c78 <sys_wait>:

uint64
sys_wait(void)
{
    80002c78:	1101                	addi	sp,sp,-32
    80002c7a:	ec06                	sd	ra,24(sp)
    80002c7c:	e822                	sd	s0,16(sp)
    80002c7e:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002c80:	fe840593          	addi	a1,s0,-24
    80002c84:	4501                	li	a0,0
    80002c86:	00000097          	auipc	ra,0x0
    80002c8a:	e96080e7          	jalr	-362(ra) # 80002b1c <argaddr>
    80002c8e:	87aa                	mv	a5,a0
    return -1;
    80002c90:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002c92:	0007c863          	bltz	a5,80002ca2 <sys_wait+0x2a>
  return wait(p);
    80002c96:	fe843503          	ld	a0,-24(s0)
    80002c9a:	fffff097          	auipc	ra,0xfffff
    80002c9e:	602080e7          	jalr	1538(ra) # 8000229c <wait>
}
    80002ca2:	60e2                	ld	ra,24(sp)
    80002ca4:	6442                	ld	s0,16(sp)
    80002ca6:	6105                	addi	sp,sp,32
    80002ca8:	8082                	ret

0000000080002caa <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002caa:	7179                	addi	sp,sp,-48
    80002cac:	f406                	sd	ra,40(sp)
    80002cae:	f022                	sd	s0,32(sp)
    80002cb0:	ec26                	sd	s1,24(sp)
    80002cb2:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002cb4:	fdc40593          	addi	a1,s0,-36
    80002cb8:	4501                	li	a0,0
    80002cba:	00000097          	auipc	ra,0x0
    80002cbe:	e40080e7          	jalr	-448(ra) # 80002afa <argint>
    80002cc2:	87aa                	mv	a5,a0
    return -1;
    80002cc4:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cc6:	0207c063          	bltz	a5,80002ce6 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	d38080e7          	jalr	-712(ra) # 80001a02 <myproc>
    80002cd2:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002cd4:	fdc42503          	lw	a0,-36(s0)
    80002cd8:	fffff097          	auipc	ra,0xfffff
    80002cdc:	07e080e7          	jalr	126(ra) # 80001d56 <growproc>
    80002ce0:	00054863          	bltz	a0,80002cf0 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002ce4:	8526                	mv	a0,s1
}
    80002ce6:	70a2                	ld	ra,40(sp)
    80002ce8:	7402                	ld	s0,32(sp)
    80002cea:	64e2                	ld	s1,24(sp)
    80002cec:	6145                	addi	sp,sp,48
    80002cee:	8082                	ret
    return -1;
    80002cf0:	557d                	li	a0,-1
    80002cf2:	bfd5                	j	80002ce6 <sys_sbrk+0x3c>

0000000080002cf4 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002cf4:	7139                	addi	sp,sp,-64
    80002cf6:	fc06                	sd	ra,56(sp)
    80002cf8:	f822                	sd	s0,48(sp)
    80002cfa:	f426                	sd	s1,40(sp)
    80002cfc:	f04a                	sd	s2,32(sp)
    80002cfe:	ec4e                	sd	s3,24(sp)
    80002d00:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d02:	fcc40593          	addi	a1,s0,-52
    80002d06:	4501                	li	a0,0
    80002d08:	00000097          	auipc	ra,0x0
    80002d0c:	df2080e7          	jalr	-526(ra) # 80002afa <argint>
    return -1;
    80002d10:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d12:	06054563          	bltz	a0,80002d7c <sys_sleep+0x88>
  acquire(&tickslock);
    80002d16:	00015517          	auipc	a0,0x15
    80002d1a:	c5250513          	addi	a0,a0,-942 # 80017968 <tickslock>
    80002d1e:	ffffe097          	auipc	ra,0xffffe
    80002d22:	f16080e7          	jalr	-234(ra) # 80000c34 <acquire>
  ticks0 = ticks;
    80002d26:	00006917          	auipc	s2,0x6
    80002d2a:	2fa92903          	lw	s2,762(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d2e:	fcc42783          	lw	a5,-52(s0)
    80002d32:	cf85                	beqz	a5,80002d6a <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d34:	00015997          	auipc	s3,0x15
    80002d38:	c3498993          	addi	s3,s3,-972 # 80017968 <tickslock>
    80002d3c:	00006497          	auipc	s1,0x6
    80002d40:	2e448493          	addi	s1,s1,740 # 80009020 <ticks>
    if(myproc()->killed){
    80002d44:	fffff097          	auipc	ra,0xfffff
    80002d48:	cbe080e7          	jalr	-834(ra) # 80001a02 <myproc>
    80002d4c:	591c                	lw	a5,48(a0)
    80002d4e:	ef9d                	bnez	a5,80002d8c <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80002d50:	85ce                	mv	a1,s3
    80002d52:	8526                	mv	a0,s1
    80002d54:	fffff097          	auipc	ra,0xfffff
    80002d58:	4ca080e7          	jalr	1226(ra) # 8000221e <sleep>
  while(ticks - ticks0 < n){
    80002d5c:	409c                	lw	a5,0(s1)
    80002d5e:	412787bb          	subw	a5,a5,s2
    80002d62:	fcc42703          	lw	a4,-52(s0)
    80002d66:	fce7efe3          	bltu	a5,a4,80002d44 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d6a:	00015517          	auipc	a0,0x15
    80002d6e:	bfe50513          	addi	a0,a0,-1026 # 80017968 <tickslock>
    80002d72:	ffffe097          	auipc	ra,0xffffe
    80002d76:	f76080e7          	jalr	-138(ra) # 80000ce8 <release>
  return 0;
    80002d7a:	4781                	li	a5,0
}
    80002d7c:	853e                	mv	a0,a5
    80002d7e:	70e2                	ld	ra,56(sp)
    80002d80:	7442                	ld	s0,48(sp)
    80002d82:	74a2                	ld	s1,40(sp)
    80002d84:	7902                	ld	s2,32(sp)
    80002d86:	69e2                	ld	s3,24(sp)
    80002d88:	6121                	addi	sp,sp,64
    80002d8a:	8082                	ret
      release(&tickslock);
    80002d8c:	00015517          	auipc	a0,0x15
    80002d90:	bdc50513          	addi	a0,a0,-1060 # 80017968 <tickslock>
    80002d94:	ffffe097          	auipc	ra,0xffffe
    80002d98:	f54080e7          	jalr	-172(ra) # 80000ce8 <release>
      return -1;
    80002d9c:	57fd                	li	a5,-1
    80002d9e:	bff9                	j	80002d7c <sys_sleep+0x88>

0000000080002da0 <sys_kill>:

uint64
sys_kill(void)
{
    80002da0:	1101                	addi	sp,sp,-32
    80002da2:	ec06                	sd	ra,24(sp)
    80002da4:	e822                	sd	s0,16(sp)
    80002da6:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002da8:	fec40593          	addi	a1,s0,-20
    80002dac:	4501                	li	a0,0
    80002dae:	00000097          	auipc	ra,0x0
    80002db2:	d4c080e7          	jalr	-692(ra) # 80002afa <argint>
    80002db6:	87aa                	mv	a5,a0
    return -1;
    80002db8:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002dba:	0007c863          	bltz	a5,80002dca <sys_kill+0x2a>
  return kill(pid);
    80002dbe:	fec42503          	lw	a0,-20(s0)
    80002dc2:	fffff097          	auipc	ra,0xfffff
    80002dc6:	64c080e7          	jalr	1612(ra) # 8000240e <kill>
}
    80002dca:	60e2                	ld	ra,24(sp)
    80002dcc:	6442                	ld	s0,16(sp)
    80002dce:	6105                	addi	sp,sp,32
    80002dd0:	8082                	ret

0000000080002dd2 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002dd2:	1101                	addi	sp,sp,-32
    80002dd4:	ec06                	sd	ra,24(sp)
    80002dd6:	e822                	sd	s0,16(sp)
    80002dd8:	e426                	sd	s1,8(sp)
    80002dda:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002ddc:	00015517          	auipc	a0,0x15
    80002de0:	b8c50513          	addi	a0,a0,-1140 # 80017968 <tickslock>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	e50080e7          	jalr	-432(ra) # 80000c34 <acquire>
  xticks = ticks;
    80002dec:	00006497          	auipc	s1,0x6
    80002df0:	2344a483          	lw	s1,564(s1) # 80009020 <ticks>
  release(&tickslock);
    80002df4:	00015517          	auipc	a0,0x15
    80002df8:	b7450513          	addi	a0,a0,-1164 # 80017968 <tickslock>
    80002dfc:	ffffe097          	auipc	ra,0xffffe
    80002e00:	eec080e7          	jalr	-276(ra) # 80000ce8 <release>
  return xticks;
}
    80002e04:	02049513          	slli	a0,s1,0x20
    80002e08:	9101                	srli	a0,a0,0x20
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6105                	addi	sp,sp,32
    80002e12:	8082                	ret

0000000080002e14 <sys_trace>:

// add trace syscall
uint64
sys_trace(void)
{
    80002e14:	1101                	addi	sp,sp,-32
    80002e16:	ec06                	sd	ra,24(sp)
    80002e18:	e822                	sd	s0,16(sp)
    80002e1a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002e1c:	fec40593          	addi	a1,s0,-20
    80002e20:	4501                	li	a0,0
    80002e22:	00000097          	auipc	ra,0x0
    80002e26:	cd8080e7          	jalr	-808(ra) # 80002afa <argint>
    return -1;
    80002e2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002e2c:	00054e63          	bltz	a0,80002e48 <sys_trace+0x34>
  myproc()->trace_mask |= n;
    80002e30:	fffff097          	auipc	ra,0xfffff
    80002e34:	bd2080e7          	jalr	-1070(ra) # 80001a02 <myproc>
    80002e38:	16852783          	lw	a5,360(a0)
    80002e3c:	fec42703          	lw	a4,-20(s0)
    80002e40:	8fd9                	or	a5,a5,a4
    80002e42:	16f52423          	sw	a5,360(a0)
  return 0;
    80002e46:	4781                	li	a5,0
}
    80002e48:	853e                	mv	a0,a5
    80002e4a:	60e2                	ld	ra,24(sp)
    80002e4c:	6442                	ld	s0,16(sp)
    80002e4e:	6105                	addi	sp,sp,32
    80002e50:	8082                	ret

0000000080002e52 <sys_sysinfo>:

// add sysinfo syscall
uint64
sys_sysinfo(void)
{
    80002e52:	7179                	addi	sp,sp,-48
    80002e54:	f406                	sd	ra,40(sp)
    80002e56:	f022                	sd	s0,32(sp)
    80002e58:	1800                	addi	s0,sp,48
  uint64 usr_ptr;
  struct sysinfo info;

  if (argaddr(0, &usr_ptr) < 0)
    80002e5a:	fe840593          	addi	a1,s0,-24
    80002e5e:	4501                	li	a0,0
    80002e60:	00000097          	auipc	ra,0x0
    80002e64:	cbc080e7          	jalr	-836(ra) # 80002b1c <argaddr>
    80002e68:	87aa                	mv	a5,a0
    return -1;
    80002e6a:	557d                	li	a0,-1
  if (argaddr(0, &usr_ptr) < 0)
    80002e6c:	0207cd63          	bltz	a5,80002ea6 <sys_sysinfo+0x54>
  info.freemem = getfreespace();
    80002e70:	ffffe097          	auipc	ra,0xffffe
    80002e74:	d10080e7          	jalr	-752(ra) # 80000b80 <getfreespace>
    80002e78:	fca43c23          	sd	a0,-40(s0)
  info.nproc = countprocess();
    80002e7c:	fffff097          	auipc	ra,0xfffff
    80002e80:	75e080e7          	jalr	1886(ra) # 800025da <countprocess>
    80002e84:	fea43023          	sd	a0,-32(s0)
  if (copyout(myproc()->pagetable, usr_ptr, (char *)&info, sizeof(info)) < 0)
    80002e88:	fffff097          	auipc	ra,0xfffff
    80002e8c:	b7a080e7          	jalr	-1158(ra) # 80001a02 <myproc>
    80002e90:	46c1                	li	a3,16
    80002e92:	fd840613          	addi	a2,s0,-40
    80002e96:	fe843583          	ld	a1,-24(s0)
    80002e9a:	6928                	ld	a0,80(a0)
    80002e9c:	fffff097          	auipc	ra,0xfffff
    80002ea0:	85a080e7          	jalr	-1958(ra) # 800016f6 <copyout>
    80002ea4:	957d                	srai	a0,a0,0x3f
    return -1;
  return 0;
    80002ea6:	70a2                	ld	ra,40(sp)
    80002ea8:	7402                	ld	s0,32(sp)
    80002eaa:	6145                	addi	sp,sp,48
    80002eac:	8082                	ret

0000000080002eae <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eae:	7179                	addi	sp,sp,-48
    80002eb0:	f406                	sd	ra,40(sp)
    80002eb2:	f022                	sd	s0,32(sp)
    80002eb4:	ec26                	sd	s1,24(sp)
    80002eb6:	e84a                	sd	s2,16(sp)
    80002eb8:	e44e                	sd	s3,8(sp)
    80002eba:	e052                	sd	s4,0(sp)
    80002ebc:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002ebe:	00005597          	auipc	a1,0x5
    80002ec2:	7b258593          	addi	a1,a1,1970 # 80008670 <syscall_names+0xc0>
    80002ec6:	00015517          	auipc	a0,0x15
    80002eca:	aba50513          	addi	a0,a0,-1350 # 80017980 <bcache>
    80002ece:	ffffe097          	auipc	ra,0xffffe
    80002ed2:	cd6080e7          	jalr	-810(ra) # 80000ba4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002ed6:	0001d797          	auipc	a5,0x1d
    80002eda:	aaa78793          	addi	a5,a5,-1366 # 8001f980 <bcache+0x8000>
    80002ede:	0001d717          	auipc	a4,0x1d
    80002ee2:	d0a70713          	addi	a4,a4,-758 # 8001fbe8 <bcache+0x8268>
    80002ee6:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002eea:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002eee:	00015497          	auipc	s1,0x15
    80002ef2:	aaa48493          	addi	s1,s1,-1366 # 80017998 <bcache+0x18>
    b->next = bcache.head.next;
    80002ef6:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002ef8:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002efa:	00005a17          	auipc	s4,0x5
    80002efe:	77ea0a13          	addi	s4,s4,1918 # 80008678 <syscall_names+0xc8>
    b->next = bcache.head.next;
    80002f02:	2b893783          	ld	a5,696(s2)
    80002f06:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f08:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f0c:	85d2                	mv	a1,s4
    80002f0e:	01048513          	addi	a0,s1,16
    80002f12:	00001097          	auipc	ra,0x1
    80002f16:	4ac080e7          	jalr	1196(ra) # 800043be <initsleeplock>
    bcache.head.next->prev = b;
    80002f1a:	2b893783          	ld	a5,696(s2)
    80002f1e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f20:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f24:	45848493          	addi	s1,s1,1112
    80002f28:	fd349de3          	bne	s1,s3,80002f02 <binit+0x54>
  }
}
    80002f2c:	70a2                	ld	ra,40(sp)
    80002f2e:	7402                	ld	s0,32(sp)
    80002f30:	64e2                	ld	s1,24(sp)
    80002f32:	6942                	ld	s2,16(sp)
    80002f34:	69a2                	ld	s3,8(sp)
    80002f36:	6a02                	ld	s4,0(sp)
    80002f38:	6145                	addi	sp,sp,48
    80002f3a:	8082                	ret

0000000080002f3c <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f3c:	7179                	addi	sp,sp,-48
    80002f3e:	f406                	sd	ra,40(sp)
    80002f40:	f022                	sd	s0,32(sp)
    80002f42:	ec26                	sd	s1,24(sp)
    80002f44:	e84a                	sd	s2,16(sp)
    80002f46:	e44e                	sd	s3,8(sp)
    80002f48:	1800                	addi	s0,sp,48
    80002f4a:	89aa                	mv	s3,a0
    80002f4c:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f4e:	00015517          	auipc	a0,0x15
    80002f52:	a3250513          	addi	a0,a0,-1486 # 80017980 <bcache>
    80002f56:	ffffe097          	auipc	ra,0xffffe
    80002f5a:	cde080e7          	jalr	-802(ra) # 80000c34 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f5e:	0001d497          	auipc	s1,0x1d
    80002f62:	cda4b483          	ld	s1,-806(s1) # 8001fc38 <bcache+0x82b8>
    80002f66:	0001d797          	auipc	a5,0x1d
    80002f6a:	c8278793          	addi	a5,a5,-894 # 8001fbe8 <bcache+0x8268>
    80002f6e:	02f48f63          	beq	s1,a5,80002fac <bread+0x70>
    80002f72:	873e                	mv	a4,a5
    80002f74:	a021                	j	80002f7c <bread+0x40>
    80002f76:	68a4                	ld	s1,80(s1)
    80002f78:	02e48a63          	beq	s1,a4,80002fac <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002f7c:	449c                	lw	a5,8(s1)
    80002f7e:	ff379ce3          	bne	a5,s3,80002f76 <bread+0x3a>
    80002f82:	44dc                	lw	a5,12(s1)
    80002f84:	ff2799e3          	bne	a5,s2,80002f76 <bread+0x3a>
      b->refcnt++;
    80002f88:	40bc                	lw	a5,64(s1)
    80002f8a:	2785                	addiw	a5,a5,1
    80002f8c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002f8e:	00015517          	auipc	a0,0x15
    80002f92:	9f250513          	addi	a0,a0,-1550 # 80017980 <bcache>
    80002f96:	ffffe097          	auipc	ra,0xffffe
    80002f9a:	d52080e7          	jalr	-686(ra) # 80000ce8 <release>
      acquiresleep(&b->lock);
    80002f9e:	01048513          	addi	a0,s1,16
    80002fa2:	00001097          	auipc	ra,0x1
    80002fa6:	456080e7          	jalr	1110(ra) # 800043f8 <acquiresleep>
      return b;
    80002faa:	a8b9                	j	80003008 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fac:	0001d497          	auipc	s1,0x1d
    80002fb0:	c844b483          	ld	s1,-892(s1) # 8001fc30 <bcache+0x82b0>
    80002fb4:	0001d797          	auipc	a5,0x1d
    80002fb8:	c3478793          	addi	a5,a5,-972 # 8001fbe8 <bcache+0x8268>
    80002fbc:	00f48863          	beq	s1,a5,80002fcc <bread+0x90>
    80002fc0:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fc2:	40bc                	lw	a5,64(s1)
    80002fc4:	cf81                	beqz	a5,80002fdc <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fc6:	64a4                	ld	s1,72(s1)
    80002fc8:	fee49de3          	bne	s1,a4,80002fc2 <bread+0x86>
  panic("bget: no buffers");
    80002fcc:	00005517          	auipc	a0,0x5
    80002fd0:	6b450513          	addi	a0,a0,1716 # 80008680 <syscall_names+0xd0>
    80002fd4:	ffffd097          	auipc	ra,0xffffd
    80002fd8:	574080e7          	jalr	1396(ra) # 80000548 <panic>
      b->dev = dev;
    80002fdc:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80002fe0:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80002fe4:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80002fe8:	4785                	li	a5,1
    80002fea:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fec:	00015517          	auipc	a0,0x15
    80002ff0:	99450513          	addi	a0,a0,-1644 # 80017980 <bcache>
    80002ff4:	ffffe097          	auipc	ra,0xffffe
    80002ff8:	cf4080e7          	jalr	-780(ra) # 80000ce8 <release>
      acquiresleep(&b->lock);
    80002ffc:	01048513          	addi	a0,s1,16
    80003000:	00001097          	auipc	ra,0x1
    80003004:	3f8080e7          	jalr	1016(ra) # 800043f8 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003008:	409c                	lw	a5,0(s1)
    8000300a:	cb89                	beqz	a5,8000301c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000300c:	8526                	mv	a0,s1
    8000300e:	70a2                	ld	ra,40(sp)
    80003010:	7402                	ld	s0,32(sp)
    80003012:	64e2                	ld	s1,24(sp)
    80003014:	6942                	ld	s2,16(sp)
    80003016:	69a2                	ld	s3,8(sp)
    80003018:	6145                	addi	sp,sp,48
    8000301a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000301c:	4581                	li	a1,0
    8000301e:	8526                	mv	a0,s1
    80003020:	00003097          	auipc	ra,0x3
    80003024:	f2c080e7          	jalr	-212(ra) # 80005f4c <virtio_disk_rw>
    b->valid = 1;
    80003028:	4785                	li	a5,1
    8000302a:	c09c                	sw	a5,0(s1)
  return b;
    8000302c:	b7c5                	j	8000300c <bread+0xd0>

000000008000302e <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000302e:	1101                	addi	sp,sp,-32
    80003030:	ec06                	sd	ra,24(sp)
    80003032:	e822                	sd	s0,16(sp)
    80003034:	e426                	sd	s1,8(sp)
    80003036:	1000                	addi	s0,sp,32
    80003038:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000303a:	0541                	addi	a0,a0,16
    8000303c:	00001097          	auipc	ra,0x1
    80003040:	456080e7          	jalr	1110(ra) # 80004492 <holdingsleep>
    80003044:	cd01                	beqz	a0,8000305c <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003046:	4585                	li	a1,1
    80003048:	8526                	mv	a0,s1
    8000304a:	00003097          	auipc	ra,0x3
    8000304e:	f02080e7          	jalr	-254(ra) # 80005f4c <virtio_disk_rw>
}
    80003052:	60e2                	ld	ra,24(sp)
    80003054:	6442                	ld	s0,16(sp)
    80003056:	64a2                	ld	s1,8(sp)
    80003058:	6105                	addi	sp,sp,32
    8000305a:	8082                	ret
    panic("bwrite");
    8000305c:	00005517          	auipc	a0,0x5
    80003060:	63c50513          	addi	a0,a0,1596 # 80008698 <syscall_names+0xe8>
    80003064:	ffffd097          	auipc	ra,0xffffd
    80003068:	4e4080e7          	jalr	1252(ra) # 80000548 <panic>

000000008000306c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	e04a                	sd	s2,0(sp)
    80003076:	1000                	addi	s0,sp,32
    80003078:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000307a:	01050913          	addi	s2,a0,16
    8000307e:	854a                	mv	a0,s2
    80003080:	00001097          	auipc	ra,0x1
    80003084:	412080e7          	jalr	1042(ra) # 80004492 <holdingsleep>
    80003088:	c92d                	beqz	a0,800030fa <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000308a:	854a                	mv	a0,s2
    8000308c:	00001097          	auipc	ra,0x1
    80003090:	3c2080e7          	jalr	962(ra) # 8000444e <releasesleep>

  acquire(&bcache.lock);
    80003094:	00015517          	auipc	a0,0x15
    80003098:	8ec50513          	addi	a0,a0,-1812 # 80017980 <bcache>
    8000309c:	ffffe097          	auipc	ra,0xffffe
    800030a0:	b98080e7          	jalr	-1128(ra) # 80000c34 <acquire>
  b->refcnt--;
    800030a4:	40bc                	lw	a5,64(s1)
    800030a6:	37fd                	addiw	a5,a5,-1
    800030a8:	0007871b          	sext.w	a4,a5
    800030ac:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ae:	eb05                	bnez	a4,800030de <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030b0:	68bc                	ld	a5,80(s1)
    800030b2:	64b8                	ld	a4,72(s1)
    800030b4:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030b6:	64bc                	ld	a5,72(s1)
    800030b8:	68b8                	ld	a4,80(s1)
    800030ba:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030bc:	0001d797          	auipc	a5,0x1d
    800030c0:	8c478793          	addi	a5,a5,-1852 # 8001f980 <bcache+0x8000>
    800030c4:	2b87b703          	ld	a4,696(a5)
    800030c8:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030ca:	0001d717          	auipc	a4,0x1d
    800030ce:	b1e70713          	addi	a4,a4,-1250 # 8001fbe8 <bcache+0x8268>
    800030d2:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    800030d4:	2b87b703          	ld	a4,696(a5)
    800030d8:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    800030da:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    800030de:	00015517          	auipc	a0,0x15
    800030e2:	8a250513          	addi	a0,a0,-1886 # 80017980 <bcache>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	c02080e7          	jalr	-1022(ra) # 80000ce8 <release>
}
    800030ee:	60e2                	ld	ra,24(sp)
    800030f0:	6442                	ld	s0,16(sp)
    800030f2:	64a2                	ld	s1,8(sp)
    800030f4:	6902                	ld	s2,0(sp)
    800030f6:	6105                	addi	sp,sp,32
    800030f8:	8082                	ret
    panic("brelse");
    800030fa:	00005517          	auipc	a0,0x5
    800030fe:	5a650513          	addi	a0,a0,1446 # 800086a0 <syscall_names+0xf0>
    80003102:	ffffd097          	auipc	ra,0xffffd
    80003106:	446080e7          	jalr	1094(ra) # 80000548 <panic>

000000008000310a <bpin>:

void
bpin(struct buf *b) {
    8000310a:	1101                	addi	sp,sp,-32
    8000310c:	ec06                	sd	ra,24(sp)
    8000310e:	e822                	sd	s0,16(sp)
    80003110:	e426                	sd	s1,8(sp)
    80003112:	1000                	addi	s0,sp,32
    80003114:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003116:	00015517          	auipc	a0,0x15
    8000311a:	86a50513          	addi	a0,a0,-1942 # 80017980 <bcache>
    8000311e:	ffffe097          	auipc	ra,0xffffe
    80003122:	b16080e7          	jalr	-1258(ra) # 80000c34 <acquire>
  b->refcnt++;
    80003126:	40bc                	lw	a5,64(s1)
    80003128:	2785                	addiw	a5,a5,1
    8000312a:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000312c:	00015517          	auipc	a0,0x15
    80003130:	85450513          	addi	a0,a0,-1964 # 80017980 <bcache>
    80003134:	ffffe097          	auipc	ra,0xffffe
    80003138:	bb4080e7          	jalr	-1100(ra) # 80000ce8 <release>
}
    8000313c:	60e2                	ld	ra,24(sp)
    8000313e:	6442                	ld	s0,16(sp)
    80003140:	64a2                	ld	s1,8(sp)
    80003142:	6105                	addi	sp,sp,32
    80003144:	8082                	ret

0000000080003146 <bunpin>:

void
bunpin(struct buf *b) {
    80003146:	1101                	addi	sp,sp,-32
    80003148:	ec06                	sd	ra,24(sp)
    8000314a:	e822                	sd	s0,16(sp)
    8000314c:	e426                	sd	s1,8(sp)
    8000314e:	1000                	addi	s0,sp,32
    80003150:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003152:	00015517          	auipc	a0,0x15
    80003156:	82e50513          	addi	a0,a0,-2002 # 80017980 <bcache>
    8000315a:	ffffe097          	auipc	ra,0xffffe
    8000315e:	ada080e7          	jalr	-1318(ra) # 80000c34 <acquire>
  b->refcnt--;
    80003162:	40bc                	lw	a5,64(s1)
    80003164:	37fd                	addiw	a5,a5,-1
    80003166:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003168:	00015517          	auipc	a0,0x15
    8000316c:	81850513          	addi	a0,a0,-2024 # 80017980 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b78080e7          	jalr	-1160(ra) # 80000ce8 <release>
}
    80003178:	60e2                	ld	ra,24(sp)
    8000317a:	6442                	ld	s0,16(sp)
    8000317c:	64a2                	ld	s1,8(sp)
    8000317e:	6105                	addi	sp,sp,32
    80003180:	8082                	ret

0000000080003182 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003182:	1101                	addi	sp,sp,-32
    80003184:	ec06                	sd	ra,24(sp)
    80003186:	e822                	sd	s0,16(sp)
    80003188:	e426                	sd	s1,8(sp)
    8000318a:	e04a                	sd	s2,0(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003190:	00d5d59b          	srliw	a1,a1,0xd
    80003194:	0001d797          	auipc	a5,0x1d
    80003198:	ec87a783          	lw	a5,-312(a5) # 8002005c <sb+0x1c>
    8000319c:	9dbd                	addw	a1,a1,a5
    8000319e:	00000097          	auipc	ra,0x0
    800031a2:	d9e080e7          	jalr	-610(ra) # 80002f3c <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031a6:	0074f713          	andi	a4,s1,7
    800031aa:	4785                	li	a5,1
    800031ac:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031b0:	14ce                	slli	s1,s1,0x33
    800031b2:	90d9                	srli	s1,s1,0x36
    800031b4:	00950733          	add	a4,a0,s1
    800031b8:	05874703          	lbu	a4,88(a4)
    800031bc:	00e7f6b3          	and	a3,a5,a4
    800031c0:	c69d                	beqz	a3,800031ee <bfree+0x6c>
    800031c2:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031c4:	94aa                	add	s1,s1,a0
    800031c6:	fff7c793          	not	a5,a5
    800031ca:	8ff9                	and	a5,a5,a4
    800031cc:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    800031d0:	00001097          	auipc	ra,0x1
    800031d4:	100080e7          	jalr	256(ra) # 800042d0 <log_write>
  brelse(bp);
    800031d8:	854a                	mv	a0,s2
    800031da:	00000097          	auipc	ra,0x0
    800031de:	e92080e7          	jalr	-366(ra) # 8000306c <brelse>
}
    800031e2:	60e2                	ld	ra,24(sp)
    800031e4:	6442                	ld	s0,16(sp)
    800031e6:	64a2                	ld	s1,8(sp)
    800031e8:	6902                	ld	s2,0(sp)
    800031ea:	6105                	addi	sp,sp,32
    800031ec:	8082                	ret
    panic("freeing free block");
    800031ee:	00005517          	auipc	a0,0x5
    800031f2:	4ba50513          	addi	a0,a0,1210 # 800086a8 <syscall_names+0xf8>
    800031f6:	ffffd097          	auipc	ra,0xffffd
    800031fa:	352080e7          	jalr	850(ra) # 80000548 <panic>

00000000800031fe <balloc>:
{
    800031fe:	711d                	addi	sp,sp,-96
    80003200:	ec86                	sd	ra,88(sp)
    80003202:	e8a2                	sd	s0,80(sp)
    80003204:	e4a6                	sd	s1,72(sp)
    80003206:	e0ca                	sd	s2,64(sp)
    80003208:	fc4e                	sd	s3,56(sp)
    8000320a:	f852                	sd	s4,48(sp)
    8000320c:	f456                	sd	s5,40(sp)
    8000320e:	f05a                	sd	s6,32(sp)
    80003210:	ec5e                	sd	s7,24(sp)
    80003212:	e862                	sd	s8,16(sp)
    80003214:	e466                	sd	s9,8(sp)
    80003216:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003218:	0001d797          	auipc	a5,0x1d
    8000321c:	e2c7a783          	lw	a5,-468(a5) # 80020044 <sb+0x4>
    80003220:	cbd1                	beqz	a5,800032b4 <balloc+0xb6>
    80003222:	8baa                	mv	s7,a0
    80003224:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003226:	0001db17          	auipc	s6,0x1d
    8000322a:	e1ab0b13          	addi	s6,s6,-486 # 80020040 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000322e:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003230:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003232:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003234:	6c89                	lui	s9,0x2
    80003236:	a831                	j	80003252 <balloc+0x54>
    brelse(bp);
    80003238:	854a                	mv	a0,s2
    8000323a:	00000097          	auipc	ra,0x0
    8000323e:	e32080e7          	jalr	-462(ra) # 8000306c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003242:	015c87bb          	addw	a5,s9,s5
    80003246:	00078a9b          	sext.w	s5,a5
    8000324a:	004b2703          	lw	a4,4(s6)
    8000324e:	06eaf363          	bgeu	s5,a4,800032b4 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003252:	41fad79b          	sraiw	a5,s5,0x1f
    80003256:	0137d79b          	srliw	a5,a5,0x13
    8000325a:	015787bb          	addw	a5,a5,s5
    8000325e:	40d7d79b          	sraiw	a5,a5,0xd
    80003262:	01cb2583          	lw	a1,28(s6)
    80003266:	9dbd                	addw	a1,a1,a5
    80003268:	855e                	mv	a0,s7
    8000326a:	00000097          	auipc	ra,0x0
    8000326e:	cd2080e7          	jalr	-814(ra) # 80002f3c <bread>
    80003272:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003274:	004b2503          	lw	a0,4(s6)
    80003278:	000a849b          	sext.w	s1,s5
    8000327c:	8662                	mv	a2,s8
    8000327e:	faa4fde3          	bgeu	s1,a0,80003238 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003282:	41f6579b          	sraiw	a5,a2,0x1f
    80003286:	01d7d69b          	srliw	a3,a5,0x1d
    8000328a:	00c6873b          	addw	a4,a3,a2
    8000328e:	00777793          	andi	a5,a4,7
    80003292:	9f95                	subw	a5,a5,a3
    80003294:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003298:	4037571b          	sraiw	a4,a4,0x3
    8000329c:	00e906b3          	add	a3,s2,a4
    800032a0:	0586c683          	lbu	a3,88(a3)
    800032a4:	00d7f5b3          	and	a1,a5,a3
    800032a8:	cd91                	beqz	a1,800032c4 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032aa:	2605                	addiw	a2,a2,1
    800032ac:	2485                	addiw	s1,s1,1
    800032ae:	fd4618e3          	bne	a2,s4,8000327e <balloc+0x80>
    800032b2:	b759                	j	80003238 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032b4:	00005517          	auipc	a0,0x5
    800032b8:	40c50513          	addi	a0,a0,1036 # 800086c0 <syscall_names+0x110>
    800032bc:	ffffd097          	auipc	ra,0xffffd
    800032c0:	28c080e7          	jalr	652(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    800032c4:	974a                	add	a4,a4,s2
    800032c6:	8fd5                	or	a5,a5,a3
    800032c8:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    800032cc:	854a                	mv	a0,s2
    800032ce:	00001097          	auipc	ra,0x1
    800032d2:	002080e7          	jalr	2(ra) # 800042d0 <log_write>
        brelse(bp);
    800032d6:	854a                	mv	a0,s2
    800032d8:	00000097          	auipc	ra,0x0
    800032dc:	d94080e7          	jalr	-620(ra) # 8000306c <brelse>
  bp = bread(dev, bno);
    800032e0:	85a6                	mv	a1,s1
    800032e2:	855e                	mv	a0,s7
    800032e4:	00000097          	auipc	ra,0x0
    800032e8:	c58080e7          	jalr	-936(ra) # 80002f3c <bread>
    800032ec:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800032ee:	40000613          	li	a2,1024
    800032f2:	4581                	li	a1,0
    800032f4:	05850513          	addi	a0,a0,88
    800032f8:	ffffe097          	auipc	ra,0xffffe
    800032fc:	a38080e7          	jalr	-1480(ra) # 80000d30 <memset>
  log_write(bp);
    80003300:	854a                	mv	a0,s2
    80003302:	00001097          	auipc	ra,0x1
    80003306:	fce080e7          	jalr	-50(ra) # 800042d0 <log_write>
  brelse(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00000097          	auipc	ra,0x0
    80003310:	d60080e7          	jalr	-672(ra) # 8000306c <brelse>
}
    80003314:	8526                	mv	a0,s1
    80003316:	60e6                	ld	ra,88(sp)
    80003318:	6446                	ld	s0,80(sp)
    8000331a:	64a6                	ld	s1,72(sp)
    8000331c:	6906                	ld	s2,64(sp)
    8000331e:	79e2                	ld	s3,56(sp)
    80003320:	7a42                	ld	s4,48(sp)
    80003322:	7aa2                	ld	s5,40(sp)
    80003324:	7b02                	ld	s6,32(sp)
    80003326:	6be2                	ld	s7,24(sp)
    80003328:	6c42                	ld	s8,16(sp)
    8000332a:	6ca2                	ld	s9,8(sp)
    8000332c:	6125                	addi	sp,sp,96
    8000332e:	8082                	ret

0000000080003330 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003330:	7179                	addi	sp,sp,-48
    80003332:	f406                	sd	ra,40(sp)
    80003334:	f022                	sd	s0,32(sp)
    80003336:	ec26                	sd	s1,24(sp)
    80003338:	e84a                	sd	s2,16(sp)
    8000333a:	e44e                	sd	s3,8(sp)
    8000333c:	e052                	sd	s4,0(sp)
    8000333e:	1800                	addi	s0,sp,48
    80003340:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003342:	47ad                	li	a5,11
    80003344:	04b7fe63          	bgeu	a5,a1,800033a0 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003348:	ff45849b          	addiw	s1,a1,-12
    8000334c:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003350:	0ff00793          	li	a5,255
    80003354:	0ae7e363          	bltu	a5,a4,800033fa <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003358:	08052583          	lw	a1,128(a0)
    8000335c:	c5ad                	beqz	a1,800033c6 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000335e:	00092503          	lw	a0,0(s2)
    80003362:	00000097          	auipc	ra,0x0
    80003366:	bda080e7          	jalr	-1062(ra) # 80002f3c <bread>
    8000336a:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000336c:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003370:	02049593          	slli	a1,s1,0x20
    80003374:	9181                	srli	a1,a1,0x20
    80003376:	058a                	slli	a1,a1,0x2
    80003378:	00b784b3          	add	s1,a5,a1
    8000337c:	0004a983          	lw	s3,0(s1)
    80003380:	04098d63          	beqz	s3,800033da <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003384:	8552                	mv	a0,s4
    80003386:	00000097          	auipc	ra,0x0
    8000338a:	ce6080e7          	jalr	-794(ra) # 8000306c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    8000338e:	854e                	mv	a0,s3
    80003390:	70a2                	ld	ra,40(sp)
    80003392:	7402                	ld	s0,32(sp)
    80003394:	64e2                	ld	s1,24(sp)
    80003396:	6942                	ld	s2,16(sp)
    80003398:	69a2                	ld	s3,8(sp)
    8000339a:	6a02                	ld	s4,0(sp)
    8000339c:	6145                	addi	sp,sp,48
    8000339e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033a0:	02059493          	slli	s1,a1,0x20
    800033a4:	9081                	srli	s1,s1,0x20
    800033a6:	048a                	slli	s1,s1,0x2
    800033a8:	94aa                	add	s1,s1,a0
    800033aa:	0504a983          	lw	s3,80(s1)
    800033ae:	fe0990e3          	bnez	s3,8000338e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033b2:	4108                	lw	a0,0(a0)
    800033b4:	00000097          	auipc	ra,0x0
    800033b8:	e4a080e7          	jalr	-438(ra) # 800031fe <balloc>
    800033bc:	0005099b          	sext.w	s3,a0
    800033c0:	0534a823          	sw	s3,80(s1)
    800033c4:	b7e9                	j	8000338e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    800033c6:	4108                	lw	a0,0(a0)
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	e36080e7          	jalr	-458(ra) # 800031fe <balloc>
    800033d0:	0005059b          	sext.w	a1,a0
    800033d4:	08b92023          	sw	a1,128(s2)
    800033d8:	b759                	j	8000335e <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    800033da:	00092503          	lw	a0,0(s2)
    800033de:	00000097          	auipc	ra,0x0
    800033e2:	e20080e7          	jalr	-480(ra) # 800031fe <balloc>
    800033e6:	0005099b          	sext.w	s3,a0
    800033ea:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    800033ee:	8552                	mv	a0,s4
    800033f0:	00001097          	auipc	ra,0x1
    800033f4:	ee0080e7          	jalr	-288(ra) # 800042d0 <log_write>
    800033f8:	b771                	j	80003384 <bmap+0x54>
  panic("bmap: out of range");
    800033fa:	00005517          	auipc	a0,0x5
    800033fe:	2de50513          	addi	a0,a0,734 # 800086d8 <syscall_names+0x128>
    80003402:	ffffd097          	auipc	ra,0xffffd
    80003406:	146080e7          	jalr	326(ra) # 80000548 <panic>

000000008000340a <iget>:
{
    8000340a:	7179                	addi	sp,sp,-48
    8000340c:	f406                	sd	ra,40(sp)
    8000340e:	f022                	sd	s0,32(sp)
    80003410:	ec26                	sd	s1,24(sp)
    80003412:	e84a                	sd	s2,16(sp)
    80003414:	e44e                	sd	s3,8(sp)
    80003416:	e052                	sd	s4,0(sp)
    80003418:	1800                	addi	s0,sp,48
    8000341a:	89aa                	mv	s3,a0
    8000341c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000341e:	0001d517          	auipc	a0,0x1d
    80003422:	c4250513          	addi	a0,a0,-958 # 80020060 <icache>
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	80e080e7          	jalr	-2034(ra) # 80000c34 <acquire>
  empty = 0;
    8000342e:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003430:	0001d497          	auipc	s1,0x1d
    80003434:	c4848493          	addi	s1,s1,-952 # 80020078 <icache+0x18>
    80003438:	0001e697          	auipc	a3,0x1e
    8000343c:	6d068693          	addi	a3,a3,1744 # 80021b08 <log>
    80003440:	a039                	j	8000344e <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003442:	02090b63          	beqz	s2,80003478 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003446:	08848493          	addi	s1,s1,136
    8000344a:	02d48a63          	beq	s1,a3,8000347e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000344e:	449c                	lw	a5,8(s1)
    80003450:	fef059e3          	blez	a5,80003442 <iget+0x38>
    80003454:	4098                	lw	a4,0(s1)
    80003456:	ff3716e3          	bne	a4,s3,80003442 <iget+0x38>
    8000345a:	40d8                	lw	a4,4(s1)
    8000345c:	ff4713e3          	bne	a4,s4,80003442 <iget+0x38>
      ip->ref++;
    80003460:	2785                	addiw	a5,a5,1
    80003462:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003464:	0001d517          	auipc	a0,0x1d
    80003468:	bfc50513          	addi	a0,a0,-1028 # 80020060 <icache>
    8000346c:	ffffe097          	auipc	ra,0xffffe
    80003470:	87c080e7          	jalr	-1924(ra) # 80000ce8 <release>
      return ip;
    80003474:	8926                	mv	s2,s1
    80003476:	a03d                	j	800034a4 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003478:	f7f9                	bnez	a5,80003446 <iget+0x3c>
    8000347a:	8926                	mv	s2,s1
    8000347c:	b7e9                	j	80003446 <iget+0x3c>
  if(empty == 0)
    8000347e:	02090c63          	beqz	s2,800034b6 <iget+0xac>
  ip->dev = dev;
    80003482:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003486:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000348a:	4785                	li	a5,1
    8000348c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003490:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003494:	0001d517          	auipc	a0,0x1d
    80003498:	bcc50513          	addi	a0,a0,-1076 # 80020060 <icache>
    8000349c:	ffffe097          	auipc	ra,0xffffe
    800034a0:	84c080e7          	jalr	-1972(ra) # 80000ce8 <release>
}
    800034a4:	854a                	mv	a0,s2
    800034a6:	70a2                	ld	ra,40(sp)
    800034a8:	7402                	ld	s0,32(sp)
    800034aa:	64e2                	ld	s1,24(sp)
    800034ac:	6942                	ld	s2,16(sp)
    800034ae:	69a2                	ld	s3,8(sp)
    800034b0:	6a02                	ld	s4,0(sp)
    800034b2:	6145                	addi	sp,sp,48
    800034b4:	8082                	ret
    panic("iget: no inodes");
    800034b6:	00005517          	auipc	a0,0x5
    800034ba:	23a50513          	addi	a0,a0,570 # 800086f0 <syscall_names+0x140>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	08a080e7          	jalr	138(ra) # 80000548 <panic>

00000000800034c6 <fsinit>:
fsinit(int dev) {
    800034c6:	7179                	addi	sp,sp,-48
    800034c8:	f406                	sd	ra,40(sp)
    800034ca:	f022                	sd	s0,32(sp)
    800034cc:	ec26                	sd	s1,24(sp)
    800034ce:	e84a                	sd	s2,16(sp)
    800034d0:	e44e                	sd	s3,8(sp)
    800034d2:	1800                	addi	s0,sp,48
    800034d4:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800034d6:	4585                	li	a1,1
    800034d8:	00000097          	auipc	ra,0x0
    800034dc:	a64080e7          	jalr	-1436(ra) # 80002f3c <bread>
    800034e0:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800034e2:	0001d997          	auipc	s3,0x1d
    800034e6:	b5e98993          	addi	s3,s3,-1186 # 80020040 <sb>
    800034ea:	02000613          	li	a2,32
    800034ee:	05850593          	addi	a1,a0,88
    800034f2:	854e                	mv	a0,s3
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	89c080e7          	jalr	-1892(ra) # 80000d90 <memmove>
  brelse(bp);
    800034fc:	8526                	mv	a0,s1
    800034fe:	00000097          	auipc	ra,0x0
    80003502:	b6e080e7          	jalr	-1170(ra) # 8000306c <brelse>
  if(sb.magic != FSMAGIC)
    80003506:	0009a703          	lw	a4,0(s3)
    8000350a:	102037b7          	lui	a5,0x10203
    8000350e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003512:	02f71263          	bne	a4,a5,80003536 <fsinit+0x70>
  initlog(dev, &sb);
    80003516:	0001d597          	auipc	a1,0x1d
    8000351a:	b2a58593          	addi	a1,a1,-1238 # 80020040 <sb>
    8000351e:	854a                	mv	a0,s2
    80003520:	00001097          	auipc	ra,0x1
    80003524:	b38080e7          	jalr	-1224(ra) # 80004058 <initlog>
}
    80003528:	70a2                	ld	ra,40(sp)
    8000352a:	7402                	ld	s0,32(sp)
    8000352c:	64e2                	ld	s1,24(sp)
    8000352e:	6942                	ld	s2,16(sp)
    80003530:	69a2                	ld	s3,8(sp)
    80003532:	6145                	addi	sp,sp,48
    80003534:	8082                	ret
    panic("invalid file system");
    80003536:	00005517          	auipc	a0,0x5
    8000353a:	1ca50513          	addi	a0,a0,458 # 80008700 <syscall_names+0x150>
    8000353e:	ffffd097          	auipc	ra,0xffffd
    80003542:	00a080e7          	jalr	10(ra) # 80000548 <panic>

0000000080003546 <iinit>:
{
    80003546:	7179                	addi	sp,sp,-48
    80003548:	f406                	sd	ra,40(sp)
    8000354a:	f022                	sd	s0,32(sp)
    8000354c:	ec26                	sd	s1,24(sp)
    8000354e:	e84a                	sd	s2,16(sp)
    80003550:	e44e                	sd	s3,8(sp)
    80003552:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003554:	00005597          	auipc	a1,0x5
    80003558:	1c458593          	addi	a1,a1,452 # 80008718 <syscall_names+0x168>
    8000355c:	0001d517          	auipc	a0,0x1d
    80003560:	b0450513          	addi	a0,a0,-1276 # 80020060 <icache>
    80003564:	ffffd097          	auipc	ra,0xffffd
    80003568:	640080e7          	jalr	1600(ra) # 80000ba4 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000356c:	0001d497          	auipc	s1,0x1d
    80003570:	b1c48493          	addi	s1,s1,-1252 # 80020088 <icache+0x28>
    80003574:	0001e997          	auipc	s3,0x1e
    80003578:	5a498993          	addi	s3,s3,1444 # 80021b18 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    8000357c:	00005917          	auipc	s2,0x5
    80003580:	1a490913          	addi	s2,s2,420 # 80008720 <syscall_names+0x170>
    80003584:	85ca                	mv	a1,s2
    80003586:	8526                	mv	a0,s1
    80003588:	00001097          	auipc	ra,0x1
    8000358c:	e36080e7          	jalr	-458(ra) # 800043be <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003590:	08848493          	addi	s1,s1,136
    80003594:	ff3498e3          	bne	s1,s3,80003584 <iinit+0x3e>
}
    80003598:	70a2                	ld	ra,40(sp)
    8000359a:	7402                	ld	s0,32(sp)
    8000359c:	64e2                	ld	s1,24(sp)
    8000359e:	6942                	ld	s2,16(sp)
    800035a0:	69a2                	ld	s3,8(sp)
    800035a2:	6145                	addi	sp,sp,48
    800035a4:	8082                	ret

00000000800035a6 <ialloc>:
{
    800035a6:	715d                	addi	sp,sp,-80
    800035a8:	e486                	sd	ra,72(sp)
    800035aa:	e0a2                	sd	s0,64(sp)
    800035ac:	fc26                	sd	s1,56(sp)
    800035ae:	f84a                	sd	s2,48(sp)
    800035b0:	f44e                	sd	s3,40(sp)
    800035b2:	f052                	sd	s4,32(sp)
    800035b4:	ec56                	sd	s5,24(sp)
    800035b6:	e85a                	sd	s6,16(sp)
    800035b8:	e45e                	sd	s7,8(sp)
    800035ba:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035bc:	0001d717          	auipc	a4,0x1d
    800035c0:	a9072703          	lw	a4,-1392(a4) # 8002004c <sb+0xc>
    800035c4:	4785                	li	a5,1
    800035c6:	04e7fa63          	bgeu	a5,a4,8000361a <ialloc+0x74>
    800035ca:	8aaa                	mv	s5,a0
    800035cc:	8bae                	mv	s7,a1
    800035ce:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800035d0:	0001da17          	auipc	s4,0x1d
    800035d4:	a70a0a13          	addi	s4,s4,-1424 # 80020040 <sb>
    800035d8:	00048b1b          	sext.w	s6,s1
    800035dc:	0044d593          	srli	a1,s1,0x4
    800035e0:	018a2783          	lw	a5,24(s4)
    800035e4:	9dbd                	addw	a1,a1,a5
    800035e6:	8556                	mv	a0,s5
    800035e8:	00000097          	auipc	ra,0x0
    800035ec:	954080e7          	jalr	-1708(ra) # 80002f3c <bread>
    800035f0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800035f2:	05850993          	addi	s3,a0,88
    800035f6:	00f4f793          	andi	a5,s1,15
    800035fa:	079a                	slli	a5,a5,0x6
    800035fc:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800035fe:	00099783          	lh	a5,0(s3)
    80003602:	c785                	beqz	a5,8000362a <ialloc+0x84>
    brelse(bp);
    80003604:	00000097          	auipc	ra,0x0
    80003608:	a68080e7          	jalr	-1432(ra) # 8000306c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000360c:	0485                	addi	s1,s1,1
    8000360e:	00ca2703          	lw	a4,12(s4)
    80003612:	0004879b          	sext.w	a5,s1
    80003616:	fce7e1e3          	bltu	a5,a4,800035d8 <ialloc+0x32>
  panic("ialloc: no inodes");
    8000361a:	00005517          	auipc	a0,0x5
    8000361e:	10e50513          	addi	a0,a0,270 # 80008728 <syscall_names+0x178>
    80003622:	ffffd097          	auipc	ra,0xffffd
    80003626:	f26080e7          	jalr	-218(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    8000362a:	04000613          	li	a2,64
    8000362e:	4581                	li	a1,0
    80003630:	854e                	mv	a0,s3
    80003632:	ffffd097          	auipc	ra,0xffffd
    80003636:	6fe080e7          	jalr	1790(ra) # 80000d30 <memset>
      dip->type = type;
    8000363a:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000363e:	854a                	mv	a0,s2
    80003640:	00001097          	auipc	ra,0x1
    80003644:	c90080e7          	jalr	-880(ra) # 800042d0 <log_write>
      brelse(bp);
    80003648:	854a                	mv	a0,s2
    8000364a:	00000097          	auipc	ra,0x0
    8000364e:	a22080e7          	jalr	-1502(ra) # 8000306c <brelse>
      return iget(dev, inum);
    80003652:	85da                	mv	a1,s6
    80003654:	8556                	mv	a0,s5
    80003656:	00000097          	auipc	ra,0x0
    8000365a:	db4080e7          	jalr	-588(ra) # 8000340a <iget>
}
    8000365e:	60a6                	ld	ra,72(sp)
    80003660:	6406                	ld	s0,64(sp)
    80003662:	74e2                	ld	s1,56(sp)
    80003664:	7942                	ld	s2,48(sp)
    80003666:	79a2                	ld	s3,40(sp)
    80003668:	7a02                	ld	s4,32(sp)
    8000366a:	6ae2                	ld	s5,24(sp)
    8000366c:	6b42                	ld	s6,16(sp)
    8000366e:	6ba2                	ld	s7,8(sp)
    80003670:	6161                	addi	sp,sp,80
    80003672:	8082                	ret

0000000080003674 <iupdate>:
{
    80003674:	1101                	addi	sp,sp,-32
    80003676:	ec06                	sd	ra,24(sp)
    80003678:	e822                	sd	s0,16(sp)
    8000367a:	e426                	sd	s1,8(sp)
    8000367c:	e04a                	sd	s2,0(sp)
    8000367e:	1000                	addi	s0,sp,32
    80003680:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003682:	415c                	lw	a5,4(a0)
    80003684:	0047d79b          	srliw	a5,a5,0x4
    80003688:	0001d597          	auipc	a1,0x1d
    8000368c:	9d05a583          	lw	a1,-1584(a1) # 80020058 <sb+0x18>
    80003690:	9dbd                	addw	a1,a1,a5
    80003692:	4108                	lw	a0,0(a0)
    80003694:	00000097          	auipc	ra,0x0
    80003698:	8a8080e7          	jalr	-1880(ra) # 80002f3c <bread>
    8000369c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000369e:	05850793          	addi	a5,a0,88
    800036a2:	40c8                	lw	a0,4(s1)
    800036a4:	893d                	andi	a0,a0,15
    800036a6:	051a                	slli	a0,a0,0x6
    800036a8:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036aa:	04449703          	lh	a4,68(s1)
    800036ae:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036b2:	04649703          	lh	a4,70(s1)
    800036b6:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036ba:	04849703          	lh	a4,72(s1)
    800036be:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800036c2:	04a49703          	lh	a4,74(s1)
    800036c6:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800036ca:	44f8                	lw	a4,76(s1)
    800036cc:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800036ce:	03400613          	li	a2,52
    800036d2:	05048593          	addi	a1,s1,80
    800036d6:	0531                	addi	a0,a0,12
    800036d8:	ffffd097          	auipc	ra,0xffffd
    800036dc:	6b8080e7          	jalr	1720(ra) # 80000d90 <memmove>
  log_write(bp);
    800036e0:	854a                	mv	a0,s2
    800036e2:	00001097          	auipc	ra,0x1
    800036e6:	bee080e7          	jalr	-1042(ra) # 800042d0 <log_write>
  brelse(bp);
    800036ea:	854a                	mv	a0,s2
    800036ec:	00000097          	auipc	ra,0x0
    800036f0:	980080e7          	jalr	-1664(ra) # 8000306c <brelse>
}
    800036f4:	60e2                	ld	ra,24(sp)
    800036f6:	6442                	ld	s0,16(sp)
    800036f8:	64a2                	ld	s1,8(sp)
    800036fa:	6902                	ld	s2,0(sp)
    800036fc:	6105                	addi	sp,sp,32
    800036fe:	8082                	ret

0000000080003700 <idup>:
{
    80003700:	1101                	addi	sp,sp,-32
    80003702:	ec06                	sd	ra,24(sp)
    80003704:	e822                	sd	s0,16(sp)
    80003706:	e426                	sd	s1,8(sp)
    80003708:	1000                	addi	s0,sp,32
    8000370a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000370c:	0001d517          	auipc	a0,0x1d
    80003710:	95450513          	addi	a0,a0,-1708 # 80020060 <icache>
    80003714:	ffffd097          	auipc	ra,0xffffd
    80003718:	520080e7          	jalr	1312(ra) # 80000c34 <acquire>
  ip->ref++;
    8000371c:	449c                	lw	a5,8(s1)
    8000371e:	2785                	addiw	a5,a5,1
    80003720:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003722:	0001d517          	auipc	a0,0x1d
    80003726:	93e50513          	addi	a0,a0,-1730 # 80020060 <icache>
    8000372a:	ffffd097          	auipc	ra,0xffffd
    8000372e:	5be080e7          	jalr	1470(ra) # 80000ce8 <release>
}
    80003732:	8526                	mv	a0,s1
    80003734:	60e2                	ld	ra,24(sp)
    80003736:	6442                	ld	s0,16(sp)
    80003738:	64a2                	ld	s1,8(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret

000000008000373e <ilock>:
{
    8000373e:	1101                	addi	sp,sp,-32
    80003740:	ec06                	sd	ra,24(sp)
    80003742:	e822                	sd	s0,16(sp)
    80003744:	e426                	sd	s1,8(sp)
    80003746:	e04a                	sd	s2,0(sp)
    80003748:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000374a:	c115                	beqz	a0,8000376e <ilock+0x30>
    8000374c:	84aa                	mv	s1,a0
    8000374e:	451c                	lw	a5,8(a0)
    80003750:	00f05f63          	blez	a5,8000376e <ilock+0x30>
  acquiresleep(&ip->lock);
    80003754:	0541                	addi	a0,a0,16
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	ca2080e7          	jalr	-862(ra) # 800043f8 <acquiresleep>
  if(ip->valid == 0){
    8000375e:	40bc                	lw	a5,64(s1)
    80003760:	cf99                	beqz	a5,8000377e <ilock+0x40>
}
    80003762:	60e2                	ld	ra,24(sp)
    80003764:	6442                	ld	s0,16(sp)
    80003766:	64a2                	ld	s1,8(sp)
    80003768:	6902                	ld	s2,0(sp)
    8000376a:	6105                	addi	sp,sp,32
    8000376c:	8082                	ret
    panic("ilock");
    8000376e:	00005517          	auipc	a0,0x5
    80003772:	fd250513          	addi	a0,a0,-46 # 80008740 <syscall_names+0x190>
    80003776:	ffffd097          	auipc	ra,0xffffd
    8000377a:	dd2080e7          	jalr	-558(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    8000377e:	40dc                	lw	a5,4(s1)
    80003780:	0047d79b          	srliw	a5,a5,0x4
    80003784:	0001d597          	auipc	a1,0x1d
    80003788:	8d45a583          	lw	a1,-1836(a1) # 80020058 <sb+0x18>
    8000378c:	9dbd                	addw	a1,a1,a5
    8000378e:	4088                	lw	a0,0(s1)
    80003790:	fffff097          	auipc	ra,0xfffff
    80003794:	7ac080e7          	jalr	1964(ra) # 80002f3c <bread>
    80003798:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000379a:	05850593          	addi	a1,a0,88
    8000379e:	40dc                	lw	a5,4(s1)
    800037a0:	8bbd                	andi	a5,a5,15
    800037a2:	079a                	slli	a5,a5,0x6
    800037a4:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037a6:	00059783          	lh	a5,0(a1)
    800037aa:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ae:	00259783          	lh	a5,2(a1)
    800037b2:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037b6:	00459783          	lh	a5,4(a1)
    800037ba:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037be:	00659783          	lh	a5,6(a1)
    800037c2:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800037c6:	459c                	lw	a5,8(a1)
    800037c8:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800037ca:	03400613          	li	a2,52
    800037ce:	05b1                	addi	a1,a1,12
    800037d0:	05048513          	addi	a0,s1,80
    800037d4:	ffffd097          	auipc	ra,0xffffd
    800037d8:	5bc080e7          	jalr	1468(ra) # 80000d90 <memmove>
    brelse(bp);
    800037dc:	854a                	mv	a0,s2
    800037de:	00000097          	auipc	ra,0x0
    800037e2:	88e080e7          	jalr	-1906(ra) # 8000306c <brelse>
    ip->valid = 1;
    800037e6:	4785                	li	a5,1
    800037e8:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800037ea:	04449783          	lh	a5,68(s1)
    800037ee:	fbb5                	bnez	a5,80003762 <ilock+0x24>
      panic("ilock: no type");
    800037f0:	00005517          	auipc	a0,0x5
    800037f4:	f5850513          	addi	a0,a0,-168 # 80008748 <syscall_names+0x198>
    800037f8:	ffffd097          	auipc	ra,0xffffd
    800037fc:	d50080e7          	jalr	-688(ra) # 80000548 <panic>

0000000080003800 <iunlock>:
{
    80003800:	1101                	addi	sp,sp,-32
    80003802:	ec06                	sd	ra,24(sp)
    80003804:	e822                	sd	s0,16(sp)
    80003806:	e426                	sd	s1,8(sp)
    80003808:	e04a                	sd	s2,0(sp)
    8000380a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000380c:	c905                	beqz	a0,8000383c <iunlock+0x3c>
    8000380e:	84aa                	mv	s1,a0
    80003810:	01050913          	addi	s2,a0,16
    80003814:	854a                	mv	a0,s2
    80003816:	00001097          	auipc	ra,0x1
    8000381a:	c7c080e7          	jalr	-900(ra) # 80004492 <holdingsleep>
    8000381e:	cd19                	beqz	a0,8000383c <iunlock+0x3c>
    80003820:	449c                	lw	a5,8(s1)
    80003822:	00f05d63          	blez	a5,8000383c <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003826:	854a                	mv	a0,s2
    80003828:	00001097          	auipc	ra,0x1
    8000382c:	c26080e7          	jalr	-986(ra) # 8000444e <releasesleep>
}
    80003830:	60e2                	ld	ra,24(sp)
    80003832:	6442                	ld	s0,16(sp)
    80003834:	64a2                	ld	s1,8(sp)
    80003836:	6902                	ld	s2,0(sp)
    80003838:	6105                	addi	sp,sp,32
    8000383a:	8082                	ret
    panic("iunlock");
    8000383c:	00005517          	auipc	a0,0x5
    80003840:	f1c50513          	addi	a0,a0,-228 # 80008758 <syscall_names+0x1a8>
    80003844:	ffffd097          	auipc	ra,0xffffd
    80003848:	d04080e7          	jalr	-764(ra) # 80000548 <panic>

000000008000384c <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000384c:	7179                	addi	sp,sp,-48
    8000384e:	f406                	sd	ra,40(sp)
    80003850:	f022                	sd	s0,32(sp)
    80003852:	ec26                	sd	s1,24(sp)
    80003854:	e84a                	sd	s2,16(sp)
    80003856:	e44e                	sd	s3,8(sp)
    80003858:	e052                	sd	s4,0(sp)
    8000385a:	1800                	addi	s0,sp,48
    8000385c:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000385e:	05050493          	addi	s1,a0,80
    80003862:	08050913          	addi	s2,a0,128
    80003866:	a021                	j	8000386e <itrunc+0x22>
    80003868:	0491                	addi	s1,s1,4
    8000386a:	01248d63          	beq	s1,s2,80003884 <itrunc+0x38>
    if(ip->addrs[i]){
    8000386e:	408c                	lw	a1,0(s1)
    80003870:	dde5                	beqz	a1,80003868 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003872:	0009a503          	lw	a0,0(s3)
    80003876:	00000097          	auipc	ra,0x0
    8000387a:	90c080e7          	jalr	-1780(ra) # 80003182 <bfree>
      ip->addrs[i] = 0;
    8000387e:	0004a023          	sw	zero,0(s1)
    80003882:	b7dd                	j	80003868 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003884:	0809a583          	lw	a1,128(s3)
    80003888:	e185                	bnez	a1,800038a8 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000388a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000388e:	854e                	mv	a0,s3
    80003890:	00000097          	auipc	ra,0x0
    80003894:	de4080e7          	jalr	-540(ra) # 80003674 <iupdate>
}
    80003898:	70a2                	ld	ra,40(sp)
    8000389a:	7402                	ld	s0,32(sp)
    8000389c:	64e2                	ld	s1,24(sp)
    8000389e:	6942                	ld	s2,16(sp)
    800038a0:	69a2                	ld	s3,8(sp)
    800038a2:	6a02                	ld	s4,0(sp)
    800038a4:	6145                	addi	sp,sp,48
    800038a6:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038a8:	0009a503          	lw	a0,0(s3)
    800038ac:	fffff097          	auipc	ra,0xfffff
    800038b0:	690080e7          	jalr	1680(ra) # 80002f3c <bread>
    800038b4:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038b6:	05850493          	addi	s1,a0,88
    800038ba:	45850913          	addi	s2,a0,1112
    800038be:	a811                	j	800038d2 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038c0:	0009a503          	lw	a0,0(s3)
    800038c4:	00000097          	auipc	ra,0x0
    800038c8:	8be080e7          	jalr	-1858(ra) # 80003182 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800038cc:	0491                	addi	s1,s1,4
    800038ce:	01248563          	beq	s1,s2,800038d8 <itrunc+0x8c>
      if(a[j])
    800038d2:	408c                	lw	a1,0(s1)
    800038d4:	dde5                	beqz	a1,800038cc <itrunc+0x80>
    800038d6:	b7ed                	j	800038c0 <itrunc+0x74>
    brelse(bp);
    800038d8:	8552                	mv	a0,s4
    800038da:	fffff097          	auipc	ra,0xfffff
    800038de:	792080e7          	jalr	1938(ra) # 8000306c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800038e2:	0809a583          	lw	a1,128(s3)
    800038e6:	0009a503          	lw	a0,0(s3)
    800038ea:	00000097          	auipc	ra,0x0
    800038ee:	898080e7          	jalr	-1896(ra) # 80003182 <bfree>
    ip->addrs[NDIRECT] = 0;
    800038f2:	0809a023          	sw	zero,128(s3)
    800038f6:	bf51                	j	8000388a <itrunc+0x3e>

00000000800038f8 <iput>:
{
    800038f8:	1101                	addi	sp,sp,-32
    800038fa:	ec06                	sd	ra,24(sp)
    800038fc:	e822                	sd	s0,16(sp)
    800038fe:	e426                	sd	s1,8(sp)
    80003900:	e04a                	sd	s2,0(sp)
    80003902:	1000                	addi	s0,sp,32
    80003904:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003906:	0001c517          	auipc	a0,0x1c
    8000390a:	75a50513          	addi	a0,a0,1882 # 80020060 <icache>
    8000390e:	ffffd097          	auipc	ra,0xffffd
    80003912:	326080e7          	jalr	806(ra) # 80000c34 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003916:	4498                	lw	a4,8(s1)
    80003918:	4785                	li	a5,1
    8000391a:	02f70363          	beq	a4,a5,80003940 <iput+0x48>
  ip->ref--;
    8000391e:	449c                	lw	a5,8(s1)
    80003920:	37fd                	addiw	a5,a5,-1
    80003922:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003924:	0001c517          	auipc	a0,0x1c
    80003928:	73c50513          	addi	a0,a0,1852 # 80020060 <icache>
    8000392c:	ffffd097          	auipc	ra,0xffffd
    80003930:	3bc080e7          	jalr	956(ra) # 80000ce8 <release>
}
    80003934:	60e2                	ld	ra,24(sp)
    80003936:	6442                	ld	s0,16(sp)
    80003938:	64a2                	ld	s1,8(sp)
    8000393a:	6902                	ld	s2,0(sp)
    8000393c:	6105                	addi	sp,sp,32
    8000393e:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003940:	40bc                	lw	a5,64(s1)
    80003942:	dff1                	beqz	a5,8000391e <iput+0x26>
    80003944:	04a49783          	lh	a5,74(s1)
    80003948:	fbf9                	bnez	a5,8000391e <iput+0x26>
    acquiresleep(&ip->lock);
    8000394a:	01048913          	addi	s2,s1,16
    8000394e:	854a                	mv	a0,s2
    80003950:	00001097          	auipc	ra,0x1
    80003954:	aa8080e7          	jalr	-1368(ra) # 800043f8 <acquiresleep>
    release(&icache.lock);
    80003958:	0001c517          	auipc	a0,0x1c
    8000395c:	70850513          	addi	a0,a0,1800 # 80020060 <icache>
    80003960:	ffffd097          	auipc	ra,0xffffd
    80003964:	388080e7          	jalr	904(ra) # 80000ce8 <release>
    itrunc(ip);
    80003968:	8526                	mv	a0,s1
    8000396a:	00000097          	auipc	ra,0x0
    8000396e:	ee2080e7          	jalr	-286(ra) # 8000384c <itrunc>
    ip->type = 0;
    80003972:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003976:	8526                	mv	a0,s1
    80003978:	00000097          	auipc	ra,0x0
    8000397c:	cfc080e7          	jalr	-772(ra) # 80003674 <iupdate>
    ip->valid = 0;
    80003980:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003984:	854a                	mv	a0,s2
    80003986:	00001097          	auipc	ra,0x1
    8000398a:	ac8080e7          	jalr	-1336(ra) # 8000444e <releasesleep>
    acquire(&icache.lock);
    8000398e:	0001c517          	auipc	a0,0x1c
    80003992:	6d250513          	addi	a0,a0,1746 # 80020060 <icache>
    80003996:	ffffd097          	auipc	ra,0xffffd
    8000399a:	29e080e7          	jalr	670(ra) # 80000c34 <acquire>
    8000399e:	b741                	j	8000391e <iput+0x26>

00000000800039a0 <iunlockput>:
{
    800039a0:	1101                	addi	sp,sp,-32
    800039a2:	ec06                	sd	ra,24(sp)
    800039a4:	e822                	sd	s0,16(sp)
    800039a6:	e426                	sd	s1,8(sp)
    800039a8:	1000                	addi	s0,sp,32
    800039aa:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	e54080e7          	jalr	-428(ra) # 80003800 <iunlock>
  iput(ip);
    800039b4:	8526                	mv	a0,s1
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	f42080e7          	jalr	-190(ra) # 800038f8 <iput>
}
    800039be:	60e2                	ld	ra,24(sp)
    800039c0:	6442                	ld	s0,16(sp)
    800039c2:	64a2                	ld	s1,8(sp)
    800039c4:	6105                	addi	sp,sp,32
    800039c6:	8082                	ret

00000000800039c8 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800039c8:	1141                	addi	sp,sp,-16
    800039ca:	e422                	sd	s0,8(sp)
    800039cc:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800039ce:	411c                	lw	a5,0(a0)
    800039d0:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800039d2:	415c                	lw	a5,4(a0)
    800039d4:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800039d6:	04451783          	lh	a5,68(a0)
    800039da:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800039de:	04a51783          	lh	a5,74(a0)
    800039e2:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800039e6:	04c56783          	lwu	a5,76(a0)
    800039ea:	e99c                	sd	a5,16(a1)
}
    800039ec:	6422                	ld	s0,8(sp)
    800039ee:	0141                	addi	sp,sp,16
    800039f0:	8082                	ret

00000000800039f2 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800039f2:	457c                	lw	a5,76(a0)
    800039f4:	0ed7e863          	bltu	a5,a3,80003ae4 <readi+0xf2>
{
    800039f8:	7159                	addi	sp,sp,-112
    800039fa:	f486                	sd	ra,104(sp)
    800039fc:	f0a2                	sd	s0,96(sp)
    800039fe:	eca6                	sd	s1,88(sp)
    80003a00:	e8ca                	sd	s2,80(sp)
    80003a02:	e4ce                	sd	s3,72(sp)
    80003a04:	e0d2                	sd	s4,64(sp)
    80003a06:	fc56                	sd	s5,56(sp)
    80003a08:	f85a                	sd	s6,48(sp)
    80003a0a:	f45e                	sd	s7,40(sp)
    80003a0c:	f062                	sd	s8,32(sp)
    80003a0e:	ec66                	sd	s9,24(sp)
    80003a10:	e86a                	sd	s10,16(sp)
    80003a12:	e46e                	sd	s11,8(sp)
    80003a14:	1880                	addi	s0,sp,112
    80003a16:	8baa                	mv	s7,a0
    80003a18:	8c2e                	mv	s8,a1
    80003a1a:	8ab2                	mv	s5,a2
    80003a1c:	84b6                	mv	s1,a3
    80003a1e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a20:	9f35                	addw	a4,a4,a3
    return 0;
    80003a22:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a24:	08d76f63          	bltu	a4,a3,80003ac2 <readi+0xd0>
  if(off + n > ip->size)
    80003a28:	00e7f463          	bgeu	a5,a4,80003a30 <readi+0x3e>
    n = ip->size - off;
    80003a2c:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a30:	0a0b0863          	beqz	s6,80003ae0 <readi+0xee>
    80003a34:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a36:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a3a:	5cfd                	li	s9,-1
    80003a3c:	a82d                	j	80003a76 <readi+0x84>
    80003a3e:	020a1d93          	slli	s11,s4,0x20
    80003a42:	020ddd93          	srli	s11,s11,0x20
    80003a46:	05890613          	addi	a2,s2,88
    80003a4a:	86ee                	mv	a3,s11
    80003a4c:	963a                	add	a2,a2,a4
    80003a4e:	85d6                	mv	a1,s5
    80003a50:	8562                	mv	a0,s8
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	a2e080e7          	jalr	-1490(ra) # 80002480 <either_copyout>
    80003a5a:	05950d63          	beq	a0,s9,80003ab4 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a5e:	854a                	mv	a0,s2
    80003a60:	fffff097          	auipc	ra,0xfffff
    80003a64:	60c080e7          	jalr	1548(ra) # 8000306c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a68:	013a09bb          	addw	s3,s4,s3
    80003a6c:	009a04bb          	addw	s1,s4,s1
    80003a70:	9aee                	add	s5,s5,s11
    80003a72:	0569f663          	bgeu	s3,s6,80003abe <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003a76:	000ba903          	lw	s2,0(s7)
    80003a7a:	00a4d59b          	srliw	a1,s1,0xa
    80003a7e:	855e                	mv	a0,s7
    80003a80:	00000097          	auipc	ra,0x0
    80003a84:	8b0080e7          	jalr	-1872(ra) # 80003330 <bmap>
    80003a88:	0005059b          	sext.w	a1,a0
    80003a8c:	854a                	mv	a0,s2
    80003a8e:	fffff097          	auipc	ra,0xfffff
    80003a92:	4ae080e7          	jalr	1198(ra) # 80002f3c <bread>
    80003a96:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a98:	3ff4f713          	andi	a4,s1,1023
    80003a9c:	40ed07bb          	subw	a5,s10,a4
    80003aa0:	413b06bb          	subw	a3,s6,s3
    80003aa4:	8a3e                	mv	s4,a5
    80003aa6:	2781                	sext.w	a5,a5
    80003aa8:	0006861b          	sext.w	a2,a3
    80003aac:	f8f679e3          	bgeu	a2,a5,80003a3e <readi+0x4c>
    80003ab0:	8a36                	mv	s4,a3
    80003ab2:	b771                	j	80003a3e <readi+0x4c>
      brelse(bp);
    80003ab4:	854a                	mv	a0,s2
    80003ab6:	fffff097          	auipc	ra,0xfffff
    80003aba:	5b6080e7          	jalr	1462(ra) # 8000306c <brelse>
  }
  return tot;
    80003abe:	0009851b          	sext.w	a0,s3
}
    80003ac2:	70a6                	ld	ra,104(sp)
    80003ac4:	7406                	ld	s0,96(sp)
    80003ac6:	64e6                	ld	s1,88(sp)
    80003ac8:	6946                	ld	s2,80(sp)
    80003aca:	69a6                	ld	s3,72(sp)
    80003acc:	6a06                	ld	s4,64(sp)
    80003ace:	7ae2                	ld	s5,56(sp)
    80003ad0:	7b42                	ld	s6,48(sp)
    80003ad2:	7ba2                	ld	s7,40(sp)
    80003ad4:	7c02                	ld	s8,32(sp)
    80003ad6:	6ce2                	ld	s9,24(sp)
    80003ad8:	6d42                	ld	s10,16(sp)
    80003ada:	6da2                	ld	s11,8(sp)
    80003adc:	6165                	addi	sp,sp,112
    80003ade:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ae0:	89da                	mv	s3,s6
    80003ae2:	bff1                	j	80003abe <readi+0xcc>
    return 0;
    80003ae4:	4501                	li	a0,0
}
    80003ae6:	8082                	ret

0000000080003ae8 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ae8:	457c                	lw	a5,76(a0)
    80003aea:	10d7e663          	bltu	a5,a3,80003bf6 <writei+0x10e>
{
    80003aee:	7159                	addi	sp,sp,-112
    80003af0:	f486                	sd	ra,104(sp)
    80003af2:	f0a2                	sd	s0,96(sp)
    80003af4:	eca6                	sd	s1,88(sp)
    80003af6:	e8ca                	sd	s2,80(sp)
    80003af8:	e4ce                	sd	s3,72(sp)
    80003afa:	e0d2                	sd	s4,64(sp)
    80003afc:	fc56                	sd	s5,56(sp)
    80003afe:	f85a                	sd	s6,48(sp)
    80003b00:	f45e                	sd	s7,40(sp)
    80003b02:	f062                	sd	s8,32(sp)
    80003b04:	ec66                	sd	s9,24(sp)
    80003b06:	e86a                	sd	s10,16(sp)
    80003b08:	e46e                	sd	s11,8(sp)
    80003b0a:	1880                	addi	s0,sp,112
    80003b0c:	8baa                	mv	s7,a0
    80003b0e:	8c2e                	mv	s8,a1
    80003b10:	8ab2                	mv	s5,a2
    80003b12:	8936                	mv	s2,a3
    80003b14:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b16:	00e687bb          	addw	a5,a3,a4
    80003b1a:	0ed7e063          	bltu	a5,a3,80003bfa <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b1e:	00043737          	lui	a4,0x43
    80003b22:	0cf76e63          	bltu	a4,a5,80003bfe <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b26:	0a0b0763          	beqz	s6,80003bd4 <writei+0xec>
    80003b2a:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b2c:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b30:	5cfd                	li	s9,-1
    80003b32:	a091                	j	80003b76 <writei+0x8e>
    80003b34:	02099d93          	slli	s11,s3,0x20
    80003b38:	020ddd93          	srli	s11,s11,0x20
    80003b3c:	05848513          	addi	a0,s1,88
    80003b40:	86ee                	mv	a3,s11
    80003b42:	8656                	mv	a2,s5
    80003b44:	85e2                	mv	a1,s8
    80003b46:	953a                	add	a0,a0,a4
    80003b48:	fffff097          	auipc	ra,0xfffff
    80003b4c:	98e080e7          	jalr	-1650(ra) # 800024d6 <either_copyin>
    80003b50:	07950263          	beq	a0,s9,80003bb4 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b54:	8526                	mv	a0,s1
    80003b56:	00000097          	auipc	ra,0x0
    80003b5a:	77a080e7          	jalr	1914(ra) # 800042d0 <log_write>
    brelse(bp);
    80003b5e:	8526                	mv	a0,s1
    80003b60:	fffff097          	auipc	ra,0xfffff
    80003b64:	50c080e7          	jalr	1292(ra) # 8000306c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b68:	01498a3b          	addw	s4,s3,s4
    80003b6c:	0129893b          	addw	s2,s3,s2
    80003b70:	9aee                	add	s5,s5,s11
    80003b72:	056a7663          	bgeu	s4,s6,80003bbe <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003b76:	000ba483          	lw	s1,0(s7)
    80003b7a:	00a9559b          	srliw	a1,s2,0xa
    80003b7e:	855e                	mv	a0,s7
    80003b80:	fffff097          	auipc	ra,0xfffff
    80003b84:	7b0080e7          	jalr	1968(ra) # 80003330 <bmap>
    80003b88:	0005059b          	sext.w	a1,a0
    80003b8c:	8526                	mv	a0,s1
    80003b8e:	fffff097          	auipc	ra,0xfffff
    80003b92:	3ae080e7          	jalr	942(ra) # 80002f3c <bread>
    80003b96:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b98:	3ff97713          	andi	a4,s2,1023
    80003b9c:	40ed07bb          	subw	a5,s10,a4
    80003ba0:	414b06bb          	subw	a3,s6,s4
    80003ba4:	89be                	mv	s3,a5
    80003ba6:	2781                	sext.w	a5,a5
    80003ba8:	0006861b          	sext.w	a2,a3
    80003bac:	f8f674e3          	bgeu	a2,a5,80003b34 <writei+0x4c>
    80003bb0:	89b6                	mv	s3,a3
    80003bb2:	b749                	j	80003b34 <writei+0x4c>
      brelse(bp);
    80003bb4:	8526                	mv	a0,s1
    80003bb6:	fffff097          	auipc	ra,0xfffff
    80003bba:	4b6080e7          	jalr	1206(ra) # 8000306c <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bbe:	04cba783          	lw	a5,76(s7)
    80003bc2:	0127f463          	bgeu	a5,s2,80003bca <writei+0xe2>
      ip->size = off;
    80003bc6:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003bca:	855e                	mv	a0,s7
    80003bcc:	00000097          	auipc	ra,0x0
    80003bd0:	aa8080e7          	jalr	-1368(ra) # 80003674 <iupdate>
  }

  return n;
    80003bd4:	000b051b          	sext.w	a0,s6
}
    80003bd8:	70a6                	ld	ra,104(sp)
    80003bda:	7406                	ld	s0,96(sp)
    80003bdc:	64e6                	ld	s1,88(sp)
    80003bde:	6946                	ld	s2,80(sp)
    80003be0:	69a6                	ld	s3,72(sp)
    80003be2:	6a06                	ld	s4,64(sp)
    80003be4:	7ae2                	ld	s5,56(sp)
    80003be6:	7b42                	ld	s6,48(sp)
    80003be8:	7ba2                	ld	s7,40(sp)
    80003bea:	7c02                	ld	s8,32(sp)
    80003bec:	6ce2                	ld	s9,24(sp)
    80003bee:	6d42                	ld	s10,16(sp)
    80003bf0:	6da2                	ld	s11,8(sp)
    80003bf2:	6165                	addi	sp,sp,112
    80003bf4:	8082                	ret
    return -1;
    80003bf6:	557d                	li	a0,-1
}
    80003bf8:	8082                	ret
    return -1;
    80003bfa:	557d                	li	a0,-1
    80003bfc:	bff1                	j	80003bd8 <writei+0xf0>
    return -1;
    80003bfe:	557d                	li	a0,-1
    80003c00:	bfe1                	j	80003bd8 <writei+0xf0>

0000000080003c02 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c02:	1141                	addi	sp,sp,-16
    80003c04:	e406                	sd	ra,8(sp)
    80003c06:	e022                	sd	s0,0(sp)
    80003c08:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c0a:	4639                	li	a2,14
    80003c0c:	ffffd097          	auipc	ra,0xffffd
    80003c10:	200080e7          	jalr	512(ra) # 80000e0c <strncmp>
}
    80003c14:	60a2                	ld	ra,8(sp)
    80003c16:	6402                	ld	s0,0(sp)
    80003c18:	0141                	addi	sp,sp,16
    80003c1a:	8082                	ret

0000000080003c1c <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c1c:	7139                	addi	sp,sp,-64
    80003c1e:	fc06                	sd	ra,56(sp)
    80003c20:	f822                	sd	s0,48(sp)
    80003c22:	f426                	sd	s1,40(sp)
    80003c24:	f04a                	sd	s2,32(sp)
    80003c26:	ec4e                	sd	s3,24(sp)
    80003c28:	e852                	sd	s4,16(sp)
    80003c2a:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c2c:	04451703          	lh	a4,68(a0)
    80003c30:	4785                	li	a5,1
    80003c32:	00f71a63          	bne	a4,a5,80003c46 <dirlookup+0x2a>
    80003c36:	892a                	mv	s2,a0
    80003c38:	89ae                	mv	s3,a1
    80003c3a:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c3c:	457c                	lw	a5,76(a0)
    80003c3e:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c40:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c42:	e79d                	bnez	a5,80003c70 <dirlookup+0x54>
    80003c44:	a8a5                	j	80003cbc <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c46:	00005517          	auipc	a0,0x5
    80003c4a:	b1a50513          	addi	a0,a0,-1254 # 80008760 <syscall_names+0x1b0>
    80003c4e:	ffffd097          	auipc	ra,0xffffd
    80003c52:	8fa080e7          	jalr	-1798(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c56:	00005517          	auipc	a0,0x5
    80003c5a:	b2250513          	addi	a0,a0,-1246 # 80008778 <syscall_names+0x1c8>
    80003c5e:	ffffd097          	auipc	ra,0xffffd
    80003c62:	8ea080e7          	jalr	-1814(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c66:	24c1                	addiw	s1,s1,16
    80003c68:	04c92783          	lw	a5,76(s2)
    80003c6c:	04f4f763          	bgeu	s1,a5,80003cba <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003c70:	4741                	li	a4,16
    80003c72:	86a6                	mv	a3,s1
    80003c74:	fc040613          	addi	a2,s0,-64
    80003c78:	4581                	li	a1,0
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	00000097          	auipc	ra,0x0
    80003c80:	d76080e7          	jalr	-650(ra) # 800039f2 <readi>
    80003c84:	47c1                	li	a5,16
    80003c86:	fcf518e3          	bne	a0,a5,80003c56 <dirlookup+0x3a>
    if(de.inum == 0)
    80003c8a:	fc045783          	lhu	a5,-64(s0)
    80003c8e:	dfe1                	beqz	a5,80003c66 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003c90:	fc240593          	addi	a1,s0,-62
    80003c94:	854e                	mv	a0,s3
    80003c96:	00000097          	auipc	ra,0x0
    80003c9a:	f6c080e7          	jalr	-148(ra) # 80003c02 <namecmp>
    80003c9e:	f561                	bnez	a0,80003c66 <dirlookup+0x4a>
      if(poff)
    80003ca0:	000a0463          	beqz	s4,80003ca8 <dirlookup+0x8c>
        *poff = off;
    80003ca4:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ca8:	fc045583          	lhu	a1,-64(s0)
    80003cac:	00092503          	lw	a0,0(s2)
    80003cb0:	fffff097          	auipc	ra,0xfffff
    80003cb4:	75a080e7          	jalr	1882(ra) # 8000340a <iget>
    80003cb8:	a011                	j	80003cbc <dirlookup+0xa0>
  return 0;
    80003cba:	4501                	li	a0,0
}
    80003cbc:	70e2                	ld	ra,56(sp)
    80003cbe:	7442                	ld	s0,48(sp)
    80003cc0:	74a2                	ld	s1,40(sp)
    80003cc2:	7902                	ld	s2,32(sp)
    80003cc4:	69e2                	ld	s3,24(sp)
    80003cc6:	6a42                	ld	s4,16(sp)
    80003cc8:	6121                	addi	sp,sp,64
    80003cca:	8082                	ret

0000000080003ccc <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003ccc:	711d                	addi	sp,sp,-96
    80003cce:	ec86                	sd	ra,88(sp)
    80003cd0:	e8a2                	sd	s0,80(sp)
    80003cd2:	e4a6                	sd	s1,72(sp)
    80003cd4:	e0ca                	sd	s2,64(sp)
    80003cd6:	fc4e                	sd	s3,56(sp)
    80003cd8:	f852                	sd	s4,48(sp)
    80003cda:	f456                	sd	s5,40(sp)
    80003cdc:	f05a                	sd	s6,32(sp)
    80003cde:	ec5e                	sd	s7,24(sp)
    80003ce0:	e862                	sd	s8,16(sp)
    80003ce2:	e466                	sd	s9,8(sp)
    80003ce4:	1080                	addi	s0,sp,96
    80003ce6:	84aa                	mv	s1,a0
    80003ce8:	8b2e                	mv	s6,a1
    80003cea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003cec:	00054703          	lbu	a4,0(a0)
    80003cf0:	02f00793          	li	a5,47
    80003cf4:	02f70363          	beq	a4,a5,80003d1a <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003cf8:	ffffe097          	auipc	ra,0xffffe
    80003cfc:	d0a080e7          	jalr	-758(ra) # 80001a02 <myproc>
    80003d00:	15053503          	ld	a0,336(a0)
    80003d04:	00000097          	auipc	ra,0x0
    80003d08:	9fc080e7          	jalr	-1540(ra) # 80003700 <idup>
    80003d0c:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d0e:	02f00913          	li	s2,47
  len = path - s;
    80003d12:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d14:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d16:	4c05                	li	s8,1
    80003d18:	a865                	j	80003dd0 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d1a:	4585                	li	a1,1
    80003d1c:	4505                	li	a0,1
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	6ec080e7          	jalr	1772(ra) # 8000340a <iget>
    80003d26:	89aa                	mv	s3,a0
    80003d28:	b7dd                	j	80003d0e <namex+0x42>
      iunlockput(ip);
    80003d2a:	854e                	mv	a0,s3
    80003d2c:	00000097          	auipc	ra,0x0
    80003d30:	c74080e7          	jalr	-908(ra) # 800039a0 <iunlockput>
      return 0;
    80003d34:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d36:	854e                	mv	a0,s3
    80003d38:	60e6                	ld	ra,88(sp)
    80003d3a:	6446                	ld	s0,80(sp)
    80003d3c:	64a6                	ld	s1,72(sp)
    80003d3e:	6906                	ld	s2,64(sp)
    80003d40:	79e2                	ld	s3,56(sp)
    80003d42:	7a42                	ld	s4,48(sp)
    80003d44:	7aa2                	ld	s5,40(sp)
    80003d46:	7b02                	ld	s6,32(sp)
    80003d48:	6be2                	ld	s7,24(sp)
    80003d4a:	6c42                	ld	s8,16(sp)
    80003d4c:	6ca2                	ld	s9,8(sp)
    80003d4e:	6125                	addi	sp,sp,96
    80003d50:	8082                	ret
      iunlock(ip);
    80003d52:	854e                	mv	a0,s3
    80003d54:	00000097          	auipc	ra,0x0
    80003d58:	aac080e7          	jalr	-1364(ra) # 80003800 <iunlock>
      return ip;
    80003d5c:	bfe9                	j	80003d36 <namex+0x6a>
      iunlockput(ip);
    80003d5e:	854e                	mv	a0,s3
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	c40080e7          	jalr	-960(ra) # 800039a0 <iunlockput>
      return 0;
    80003d68:	89d2                	mv	s3,s4
    80003d6a:	b7f1                	j	80003d36 <namex+0x6a>
  len = path - s;
    80003d6c:	40b48633          	sub	a2,s1,a1
    80003d70:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003d74:	094cd463          	bge	s9,s4,80003dfc <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003d78:	4639                	li	a2,14
    80003d7a:	8556                	mv	a0,s5
    80003d7c:	ffffd097          	auipc	ra,0xffffd
    80003d80:	014080e7          	jalr	20(ra) # 80000d90 <memmove>
  while(*path == '/')
    80003d84:	0004c783          	lbu	a5,0(s1)
    80003d88:	01279763          	bne	a5,s2,80003d96 <namex+0xca>
    path++;
    80003d8c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003d8e:	0004c783          	lbu	a5,0(s1)
    80003d92:	ff278de3          	beq	a5,s2,80003d8c <namex+0xc0>
    ilock(ip);
    80003d96:	854e                	mv	a0,s3
    80003d98:	00000097          	auipc	ra,0x0
    80003d9c:	9a6080e7          	jalr	-1626(ra) # 8000373e <ilock>
    if(ip->type != T_DIR){
    80003da0:	04499783          	lh	a5,68(s3)
    80003da4:	f98793e3          	bne	a5,s8,80003d2a <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003da8:	000b0563          	beqz	s6,80003db2 <namex+0xe6>
    80003dac:	0004c783          	lbu	a5,0(s1)
    80003db0:	d3cd                	beqz	a5,80003d52 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003db2:	865e                	mv	a2,s7
    80003db4:	85d6                	mv	a1,s5
    80003db6:	854e                	mv	a0,s3
    80003db8:	00000097          	auipc	ra,0x0
    80003dbc:	e64080e7          	jalr	-412(ra) # 80003c1c <dirlookup>
    80003dc0:	8a2a                	mv	s4,a0
    80003dc2:	dd51                	beqz	a0,80003d5e <namex+0x92>
    iunlockput(ip);
    80003dc4:	854e                	mv	a0,s3
    80003dc6:	00000097          	auipc	ra,0x0
    80003dca:	bda080e7          	jalr	-1062(ra) # 800039a0 <iunlockput>
    ip = next;
    80003dce:	89d2                	mv	s3,s4
  while(*path == '/')
    80003dd0:	0004c783          	lbu	a5,0(s1)
    80003dd4:	05279763          	bne	a5,s2,80003e22 <namex+0x156>
    path++;
    80003dd8:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dda:	0004c783          	lbu	a5,0(s1)
    80003dde:	ff278de3          	beq	a5,s2,80003dd8 <namex+0x10c>
  if(*path == 0)
    80003de2:	c79d                	beqz	a5,80003e10 <namex+0x144>
    path++;
    80003de4:	85a6                	mv	a1,s1
  len = path - s;
    80003de6:	8a5e                	mv	s4,s7
    80003de8:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003dea:	01278963          	beq	a5,s2,80003dfc <namex+0x130>
    80003dee:	dfbd                	beqz	a5,80003d6c <namex+0xa0>
    path++;
    80003df0:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003df2:	0004c783          	lbu	a5,0(s1)
    80003df6:	ff279ce3          	bne	a5,s2,80003dee <namex+0x122>
    80003dfa:	bf8d                	j	80003d6c <namex+0xa0>
    memmove(name, s, len);
    80003dfc:	2601                	sext.w	a2,a2
    80003dfe:	8556                	mv	a0,s5
    80003e00:	ffffd097          	auipc	ra,0xffffd
    80003e04:	f90080e7          	jalr	-112(ra) # 80000d90 <memmove>
    name[len] = 0;
    80003e08:	9a56                	add	s4,s4,s5
    80003e0a:	000a0023          	sb	zero,0(s4)
    80003e0e:	bf9d                	j	80003d84 <namex+0xb8>
  if(nameiparent){
    80003e10:	f20b03e3          	beqz	s6,80003d36 <namex+0x6a>
    iput(ip);
    80003e14:	854e                	mv	a0,s3
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	ae2080e7          	jalr	-1310(ra) # 800038f8 <iput>
    return 0;
    80003e1e:	4981                	li	s3,0
    80003e20:	bf19                	j	80003d36 <namex+0x6a>
  if(*path == 0)
    80003e22:	d7fd                	beqz	a5,80003e10 <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e24:	0004c783          	lbu	a5,0(s1)
    80003e28:	85a6                	mv	a1,s1
    80003e2a:	b7d1                	j	80003dee <namex+0x122>

0000000080003e2c <dirlink>:
{
    80003e2c:	7139                	addi	sp,sp,-64
    80003e2e:	fc06                	sd	ra,56(sp)
    80003e30:	f822                	sd	s0,48(sp)
    80003e32:	f426                	sd	s1,40(sp)
    80003e34:	f04a                	sd	s2,32(sp)
    80003e36:	ec4e                	sd	s3,24(sp)
    80003e38:	e852                	sd	s4,16(sp)
    80003e3a:	0080                	addi	s0,sp,64
    80003e3c:	892a                	mv	s2,a0
    80003e3e:	8a2e                	mv	s4,a1
    80003e40:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e42:	4601                	li	a2,0
    80003e44:	00000097          	auipc	ra,0x0
    80003e48:	dd8080e7          	jalr	-552(ra) # 80003c1c <dirlookup>
    80003e4c:	e93d                	bnez	a0,80003ec2 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e4e:	04c92483          	lw	s1,76(s2)
    80003e52:	c49d                	beqz	s1,80003e80 <dirlink+0x54>
    80003e54:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e56:	4741                	li	a4,16
    80003e58:	86a6                	mv	a3,s1
    80003e5a:	fc040613          	addi	a2,s0,-64
    80003e5e:	4581                	li	a1,0
    80003e60:	854a                	mv	a0,s2
    80003e62:	00000097          	auipc	ra,0x0
    80003e66:	b90080e7          	jalr	-1136(ra) # 800039f2 <readi>
    80003e6a:	47c1                	li	a5,16
    80003e6c:	06f51163          	bne	a0,a5,80003ece <dirlink+0xa2>
    if(de.inum == 0)
    80003e70:	fc045783          	lhu	a5,-64(s0)
    80003e74:	c791                	beqz	a5,80003e80 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e76:	24c1                	addiw	s1,s1,16
    80003e78:	04c92783          	lw	a5,76(s2)
    80003e7c:	fcf4ede3          	bltu	s1,a5,80003e56 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003e80:	4639                	li	a2,14
    80003e82:	85d2                	mv	a1,s4
    80003e84:	fc240513          	addi	a0,s0,-62
    80003e88:	ffffd097          	auipc	ra,0xffffd
    80003e8c:	fc0080e7          	jalr	-64(ra) # 80000e48 <strncpy>
  de.inum = inum;
    80003e90:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e94:	4741                	li	a4,16
    80003e96:	86a6                	mv	a3,s1
    80003e98:	fc040613          	addi	a2,s0,-64
    80003e9c:	4581                	li	a1,0
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	c48080e7          	jalr	-952(ra) # 80003ae8 <writei>
    80003ea8:	872a                	mv	a4,a0
    80003eaa:	47c1                	li	a5,16
  return 0;
    80003eac:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eae:	02f71863          	bne	a4,a5,80003ede <dirlink+0xb2>
}
    80003eb2:	70e2                	ld	ra,56(sp)
    80003eb4:	7442                	ld	s0,48(sp)
    80003eb6:	74a2                	ld	s1,40(sp)
    80003eb8:	7902                	ld	s2,32(sp)
    80003eba:	69e2                	ld	s3,24(sp)
    80003ebc:	6a42                	ld	s4,16(sp)
    80003ebe:	6121                	addi	sp,sp,64
    80003ec0:	8082                	ret
    iput(ip);
    80003ec2:	00000097          	auipc	ra,0x0
    80003ec6:	a36080e7          	jalr	-1482(ra) # 800038f8 <iput>
    return -1;
    80003eca:	557d                	li	a0,-1
    80003ecc:	b7dd                	j	80003eb2 <dirlink+0x86>
      panic("dirlink read");
    80003ece:	00005517          	auipc	a0,0x5
    80003ed2:	8ba50513          	addi	a0,a0,-1862 # 80008788 <syscall_names+0x1d8>
    80003ed6:	ffffc097          	auipc	ra,0xffffc
    80003eda:	672080e7          	jalr	1650(ra) # 80000548 <panic>
    panic("dirlink");
    80003ede:	00005517          	auipc	a0,0x5
    80003ee2:	9c250513          	addi	a0,a0,-1598 # 800088a0 <syscall_names+0x2f0>
    80003ee6:	ffffc097          	auipc	ra,0xffffc
    80003eea:	662080e7          	jalr	1634(ra) # 80000548 <panic>

0000000080003eee <namei>:

struct inode*
namei(char *path)
{
    80003eee:	1101                	addi	sp,sp,-32
    80003ef0:	ec06                	sd	ra,24(sp)
    80003ef2:	e822                	sd	s0,16(sp)
    80003ef4:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003ef6:	fe040613          	addi	a2,s0,-32
    80003efa:	4581                	li	a1,0
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	dd0080e7          	jalr	-560(ra) # 80003ccc <namex>
}
    80003f04:	60e2                	ld	ra,24(sp)
    80003f06:	6442                	ld	s0,16(sp)
    80003f08:	6105                	addi	sp,sp,32
    80003f0a:	8082                	ret

0000000080003f0c <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f0c:	1141                	addi	sp,sp,-16
    80003f0e:	e406                	sd	ra,8(sp)
    80003f10:	e022                	sd	s0,0(sp)
    80003f12:	0800                	addi	s0,sp,16
    80003f14:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f16:	4585                	li	a1,1
    80003f18:	00000097          	auipc	ra,0x0
    80003f1c:	db4080e7          	jalr	-588(ra) # 80003ccc <namex>
}
    80003f20:	60a2                	ld	ra,8(sp)
    80003f22:	6402                	ld	s0,0(sp)
    80003f24:	0141                	addi	sp,sp,16
    80003f26:	8082                	ret

0000000080003f28 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f28:	1101                	addi	sp,sp,-32
    80003f2a:	ec06                	sd	ra,24(sp)
    80003f2c:	e822                	sd	s0,16(sp)
    80003f2e:	e426                	sd	s1,8(sp)
    80003f30:	e04a                	sd	s2,0(sp)
    80003f32:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f34:	0001e917          	auipc	s2,0x1e
    80003f38:	bd490913          	addi	s2,s2,-1068 # 80021b08 <log>
    80003f3c:	01892583          	lw	a1,24(s2)
    80003f40:	02892503          	lw	a0,40(s2)
    80003f44:	fffff097          	auipc	ra,0xfffff
    80003f48:	ff8080e7          	jalr	-8(ra) # 80002f3c <bread>
    80003f4c:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f4e:	02c92683          	lw	a3,44(s2)
    80003f52:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f54:	02d05763          	blez	a3,80003f82 <write_head+0x5a>
    80003f58:	0001e797          	auipc	a5,0x1e
    80003f5c:	be078793          	addi	a5,a5,-1056 # 80021b38 <log+0x30>
    80003f60:	05c50713          	addi	a4,a0,92
    80003f64:	36fd                	addiw	a3,a3,-1
    80003f66:	1682                	slli	a3,a3,0x20
    80003f68:	9281                	srli	a3,a3,0x20
    80003f6a:	068a                	slli	a3,a3,0x2
    80003f6c:	0001e617          	auipc	a2,0x1e
    80003f70:	bd060613          	addi	a2,a2,-1072 # 80021b3c <log+0x34>
    80003f74:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003f76:	4390                	lw	a2,0(a5)
    80003f78:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003f7a:	0791                	addi	a5,a5,4
    80003f7c:	0711                	addi	a4,a4,4
    80003f7e:	fed79ce3          	bne	a5,a3,80003f76 <write_head+0x4e>
  }
  bwrite(buf);
    80003f82:	8526                	mv	a0,s1
    80003f84:	fffff097          	auipc	ra,0xfffff
    80003f88:	0aa080e7          	jalr	170(ra) # 8000302e <bwrite>
  brelse(buf);
    80003f8c:	8526                	mv	a0,s1
    80003f8e:	fffff097          	auipc	ra,0xfffff
    80003f92:	0de080e7          	jalr	222(ra) # 8000306c <brelse>
}
    80003f96:	60e2                	ld	ra,24(sp)
    80003f98:	6442                	ld	s0,16(sp)
    80003f9a:	64a2                	ld	s1,8(sp)
    80003f9c:	6902                	ld	s2,0(sp)
    80003f9e:	6105                	addi	sp,sp,32
    80003fa0:	8082                	ret

0000000080003fa2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fa2:	0001e797          	auipc	a5,0x1e
    80003fa6:	b927a783          	lw	a5,-1134(a5) # 80021b34 <log+0x2c>
    80003faa:	0af05663          	blez	a5,80004056 <install_trans+0xb4>
{
    80003fae:	7139                	addi	sp,sp,-64
    80003fb0:	fc06                	sd	ra,56(sp)
    80003fb2:	f822                	sd	s0,48(sp)
    80003fb4:	f426                	sd	s1,40(sp)
    80003fb6:	f04a                	sd	s2,32(sp)
    80003fb8:	ec4e                	sd	s3,24(sp)
    80003fba:	e852                	sd	s4,16(sp)
    80003fbc:	e456                	sd	s5,8(sp)
    80003fbe:	0080                	addi	s0,sp,64
    80003fc0:	0001ea97          	auipc	s5,0x1e
    80003fc4:	b78a8a93          	addi	s5,s5,-1160 # 80021b38 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fc8:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80003fca:	0001e997          	auipc	s3,0x1e
    80003fce:	b3e98993          	addi	s3,s3,-1218 # 80021b08 <log>
    80003fd2:	0189a583          	lw	a1,24(s3)
    80003fd6:	014585bb          	addw	a1,a1,s4
    80003fda:	2585                	addiw	a1,a1,1
    80003fdc:	0289a503          	lw	a0,40(s3)
    80003fe0:	fffff097          	auipc	ra,0xfffff
    80003fe4:	f5c080e7          	jalr	-164(ra) # 80002f3c <bread>
    80003fe8:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80003fea:	000aa583          	lw	a1,0(s5)
    80003fee:	0289a503          	lw	a0,40(s3)
    80003ff2:	fffff097          	auipc	ra,0xfffff
    80003ff6:	f4a080e7          	jalr	-182(ra) # 80002f3c <bread>
    80003ffa:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80003ffc:	40000613          	li	a2,1024
    80004000:	05890593          	addi	a1,s2,88
    80004004:	05850513          	addi	a0,a0,88
    80004008:	ffffd097          	auipc	ra,0xffffd
    8000400c:	d88080e7          	jalr	-632(ra) # 80000d90 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004010:	8526                	mv	a0,s1
    80004012:	fffff097          	auipc	ra,0xfffff
    80004016:	01c080e7          	jalr	28(ra) # 8000302e <bwrite>
    bunpin(dbuf);
    8000401a:	8526                	mv	a0,s1
    8000401c:	fffff097          	auipc	ra,0xfffff
    80004020:	12a080e7          	jalr	298(ra) # 80003146 <bunpin>
    brelse(lbuf);
    80004024:	854a                	mv	a0,s2
    80004026:	fffff097          	auipc	ra,0xfffff
    8000402a:	046080e7          	jalr	70(ra) # 8000306c <brelse>
    brelse(dbuf);
    8000402e:	8526                	mv	a0,s1
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	03c080e7          	jalr	60(ra) # 8000306c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004038:	2a05                	addiw	s4,s4,1
    8000403a:	0a91                	addi	s5,s5,4
    8000403c:	02c9a783          	lw	a5,44(s3)
    80004040:	f8fa49e3          	blt	s4,a5,80003fd2 <install_trans+0x30>
}
    80004044:	70e2                	ld	ra,56(sp)
    80004046:	7442                	ld	s0,48(sp)
    80004048:	74a2                	ld	s1,40(sp)
    8000404a:	7902                	ld	s2,32(sp)
    8000404c:	69e2                	ld	s3,24(sp)
    8000404e:	6a42                	ld	s4,16(sp)
    80004050:	6aa2                	ld	s5,8(sp)
    80004052:	6121                	addi	sp,sp,64
    80004054:	8082                	ret
    80004056:	8082                	ret

0000000080004058 <initlog>:
{
    80004058:	7179                	addi	sp,sp,-48
    8000405a:	f406                	sd	ra,40(sp)
    8000405c:	f022                	sd	s0,32(sp)
    8000405e:	ec26                	sd	s1,24(sp)
    80004060:	e84a                	sd	s2,16(sp)
    80004062:	e44e                	sd	s3,8(sp)
    80004064:	1800                	addi	s0,sp,48
    80004066:	892a                	mv	s2,a0
    80004068:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000406a:	0001e497          	auipc	s1,0x1e
    8000406e:	a9e48493          	addi	s1,s1,-1378 # 80021b08 <log>
    80004072:	00004597          	auipc	a1,0x4
    80004076:	72658593          	addi	a1,a1,1830 # 80008798 <syscall_names+0x1e8>
    8000407a:	8526                	mv	a0,s1
    8000407c:	ffffd097          	auipc	ra,0xffffd
    80004080:	b28080e7          	jalr	-1240(ra) # 80000ba4 <initlock>
  log.start = sb->logstart;
    80004084:	0149a583          	lw	a1,20(s3)
    80004088:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000408a:	0109a783          	lw	a5,16(s3)
    8000408e:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004090:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004094:	854a                	mv	a0,s2
    80004096:	fffff097          	auipc	ra,0xfffff
    8000409a:	ea6080e7          	jalr	-346(ra) # 80002f3c <bread>
  log.lh.n = lh->n;
    8000409e:	4d3c                	lw	a5,88(a0)
    800040a0:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040a2:	02f05563          	blez	a5,800040cc <initlog+0x74>
    800040a6:	05c50713          	addi	a4,a0,92
    800040aa:	0001e697          	auipc	a3,0x1e
    800040ae:	a8e68693          	addi	a3,a3,-1394 # 80021b38 <log+0x30>
    800040b2:	37fd                	addiw	a5,a5,-1
    800040b4:	1782                	slli	a5,a5,0x20
    800040b6:	9381                	srli	a5,a5,0x20
    800040b8:	078a                	slli	a5,a5,0x2
    800040ba:	06050613          	addi	a2,a0,96
    800040be:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040c0:	4310                	lw	a2,0(a4)
    800040c2:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    800040c4:	0711                	addi	a4,a4,4
    800040c6:	0691                	addi	a3,a3,4
    800040c8:	fef71ce3          	bne	a4,a5,800040c0 <initlog+0x68>
  brelse(buf);
    800040cc:	fffff097          	auipc	ra,0xfffff
    800040d0:	fa0080e7          	jalr	-96(ra) # 8000306c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	ece080e7          	jalr	-306(ra) # 80003fa2 <install_trans>
  log.lh.n = 0;
    800040dc:	0001e797          	auipc	a5,0x1e
    800040e0:	a407ac23          	sw	zero,-1448(a5) # 80021b34 <log+0x2c>
  write_head(); // clear the log
    800040e4:	00000097          	auipc	ra,0x0
    800040e8:	e44080e7          	jalr	-444(ra) # 80003f28 <write_head>
}
    800040ec:	70a2                	ld	ra,40(sp)
    800040ee:	7402                	ld	s0,32(sp)
    800040f0:	64e2                	ld	s1,24(sp)
    800040f2:	6942                	ld	s2,16(sp)
    800040f4:	69a2                	ld	s3,8(sp)
    800040f6:	6145                	addi	sp,sp,48
    800040f8:	8082                	ret

00000000800040fa <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800040fa:	1101                	addi	sp,sp,-32
    800040fc:	ec06                	sd	ra,24(sp)
    800040fe:	e822                	sd	s0,16(sp)
    80004100:	e426                	sd	s1,8(sp)
    80004102:	e04a                	sd	s2,0(sp)
    80004104:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004106:	0001e517          	auipc	a0,0x1e
    8000410a:	a0250513          	addi	a0,a0,-1534 # 80021b08 <log>
    8000410e:	ffffd097          	auipc	ra,0xffffd
    80004112:	b26080e7          	jalr	-1242(ra) # 80000c34 <acquire>
  while(1){
    if(log.committing){
    80004116:	0001e497          	auipc	s1,0x1e
    8000411a:	9f248493          	addi	s1,s1,-1550 # 80021b08 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000411e:	4979                	li	s2,30
    80004120:	a039                	j	8000412e <begin_op+0x34>
      sleep(&log, &log.lock);
    80004122:	85a6                	mv	a1,s1
    80004124:	8526                	mv	a0,s1
    80004126:	ffffe097          	auipc	ra,0xffffe
    8000412a:	0f8080e7          	jalr	248(ra) # 8000221e <sleep>
    if(log.committing){
    8000412e:	50dc                	lw	a5,36(s1)
    80004130:	fbed                	bnez	a5,80004122 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004132:	509c                	lw	a5,32(s1)
    80004134:	0017871b          	addiw	a4,a5,1
    80004138:	0007069b          	sext.w	a3,a4
    8000413c:	0027179b          	slliw	a5,a4,0x2
    80004140:	9fb9                	addw	a5,a5,a4
    80004142:	0017979b          	slliw	a5,a5,0x1
    80004146:	54d8                	lw	a4,44(s1)
    80004148:	9fb9                	addw	a5,a5,a4
    8000414a:	00f95963          	bge	s2,a5,8000415c <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000414e:	85a6                	mv	a1,s1
    80004150:	8526                	mv	a0,s1
    80004152:	ffffe097          	auipc	ra,0xffffe
    80004156:	0cc080e7          	jalr	204(ra) # 8000221e <sleep>
    8000415a:	bfd1                	j	8000412e <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000415c:	0001e517          	auipc	a0,0x1e
    80004160:	9ac50513          	addi	a0,a0,-1620 # 80021b08 <log>
    80004164:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004166:	ffffd097          	auipc	ra,0xffffd
    8000416a:	b82080e7          	jalr	-1150(ra) # 80000ce8 <release>
      break;
    }
  }
}
    8000416e:	60e2                	ld	ra,24(sp)
    80004170:	6442                	ld	s0,16(sp)
    80004172:	64a2                	ld	s1,8(sp)
    80004174:	6902                	ld	s2,0(sp)
    80004176:	6105                	addi	sp,sp,32
    80004178:	8082                	ret

000000008000417a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000417a:	7139                	addi	sp,sp,-64
    8000417c:	fc06                	sd	ra,56(sp)
    8000417e:	f822                	sd	s0,48(sp)
    80004180:	f426                	sd	s1,40(sp)
    80004182:	f04a                	sd	s2,32(sp)
    80004184:	ec4e                	sd	s3,24(sp)
    80004186:	e852                	sd	s4,16(sp)
    80004188:	e456                	sd	s5,8(sp)
    8000418a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000418c:	0001e497          	auipc	s1,0x1e
    80004190:	97c48493          	addi	s1,s1,-1668 # 80021b08 <log>
    80004194:	8526                	mv	a0,s1
    80004196:	ffffd097          	auipc	ra,0xffffd
    8000419a:	a9e080e7          	jalr	-1378(ra) # 80000c34 <acquire>
  log.outstanding -= 1;
    8000419e:	509c                	lw	a5,32(s1)
    800041a0:	37fd                	addiw	a5,a5,-1
    800041a2:	0007891b          	sext.w	s2,a5
    800041a6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041a8:	50dc                	lw	a5,36(s1)
    800041aa:	efb9                	bnez	a5,80004208 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041ac:	06091663          	bnez	s2,80004218 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041b0:	0001e497          	auipc	s1,0x1e
    800041b4:	95848493          	addi	s1,s1,-1704 # 80021b08 <log>
    800041b8:	4785                	li	a5,1
    800041ba:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041bc:	8526                	mv	a0,s1
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	b2a080e7          	jalr	-1238(ra) # 80000ce8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800041c6:	54dc                	lw	a5,44(s1)
    800041c8:	06f04763          	bgtz	a5,80004236 <end_op+0xbc>
    acquire(&log.lock);
    800041cc:	0001e497          	auipc	s1,0x1e
    800041d0:	93c48493          	addi	s1,s1,-1732 # 80021b08 <log>
    800041d4:	8526                	mv	a0,s1
    800041d6:	ffffd097          	auipc	ra,0xffffd
    800041da:	a5e080e7          	jalr	-1442(ra) # 80000c34 <acquire>
    log.committing = 0;
    800041de:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800041e2:	8526                	mv	a0,s1
    800041e4:	ffffe097          	auipc	ra,0xffffe
    800041e8:	1c0080e7          	jalr	448(ra) # 800023a4 <wakeup>
    release(&log.lock);
    800041ec:	8526                	mv	a0,s1
    800041ee:	ffffd097          	auipc	ra,0xffffd
    800041f2:	afa080e7          	jalr	-1286(ra) # 80000ce8 <release>
}
    800041f6:	70e2                	ld	ra,56(sp)
    800041f8:	7442                	ld	s0,48(sp)
    800041fa:	74a2                	ld	s1,40(sp)
    800041fc:	7902                	ld	s2,32(sp)
    800041fe:	69e2                	ld	s3,24(sp)
    80004200:	6a42                	ld	s4,16(sp)
    80004202:	6aa2                	ld	s5,8(sp)
    80004204:	6121                	addi	sp,sp,64
    80004206:	8082                	ret
    panic("log.committing");
    80004208:	00004517          	auipc	a0,0x4
    8000420c:	59850513          	addi	a0,a0,1432 # 800087a0 <syscall_names+0x1f0>
    80004210:	ffffc097          	auipc	ra,0xffffc
    80004214:	338080e7          	jalr	824(ra) # 80000548 <panic>
    wakeup(&log);
    80004218:	0001e497          	auipc	s1,0x1e
    8000421c:	8f048493          	addi	s1,s1,-1808 # 80021b08 <log>
    80004220:	8526                	mv	a0,s1
    80004222:	ffffe097          	auipc	ra,0xffffe
    80004226:	182080e7          	jalr	386(ra) # 800023a4 <wakeup>
  release(&log.lock);
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	abc080e7          	jalr	-1348(ra) # 80000ce8 <release>
  if(do_commit){
    80004234:	b7c9                	j	800041f6 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004236:	0001ea97          	auipc	s5,0x1e
    8000423a:	902a8a93          	addi	s5,s5,-1790 # 80021b38 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000423e:	0001ea17          	auipc	s4,0x1e
    80004242:	8caa0a13          	addi	s4,s4,-1846 # 80021b08 <log>
    80004246:	018a2583          	lw	a1,24(s4)
    8000424a:	012585bb          	addw	a1,a1,s2
    8000424e:	2585                	addiw	a1,a1,1
    80004250:	028a2503          	lw	a0,40(s4)
    80004254:	fffff097          	auipc	ra,0xfffff
    80004258:	ce8080e7          	jalr	-792(ra) # 80002f3c <bread>
    8000425c:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000425e:	000aa583          	lw	a1,0(s5)
    80004262:	028a2503          	lw	a0,40(s4)
    80004266:	fffff097          	auipc	ra,0xfffff
    8000426a:	cd6080e7          	jalr	-810(ra) # 80002f3c <bread>
    8000426e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004270:	40000613          	li	a2,1024
    80004274:	05850593          	addi	a1,a0,88
    80004278:	05848513          	addi	a0,s1,88
    8000427c:	ffffd097          	auipc	ra,0xffffd
    80004280:	b14080e7          	jalr	-1260(ra) # 80000d90 <memmove>
    bwrite(to);  // write the log
    80004284:	8526                	mv	a0,s1
    80004286:	fffff097          	auipc	ra,0xfffff
    8000428a:	da8080e7          	jalr	-600(ra) # 8000302e <bwrite>
    brelse(from);
    8000428e:	854e                	mv	a0,s3
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	ddc080e7          	jalr	-548(ra) # 8000306c <brelse>
    brelse(to);
    80004298:	8526                	mv	a0,s1
    8000429a:	fffff097          	auipc	ra,0xfffff
    8000429e:	dd2080e7          	jalr	-558(ra) # 8000306c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042a2:	2905                	addiw	s2,s2,1
    800042a4:	0a91                	addi	s5,s5,4
    800042a6:	02ca2783          	lw	a5,44(s4)
    800042aa:	f8f94ee3          	blt	s2,a5,80004246 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	c7a080e7          	jalr	-902(ra) # 80003f28 <write_head>
    install_trans(); // Now install writes to home locations
    800042b6:	00000097          	auipc	ra,0x0
    800042ba:	cec080e7          	jalr	-788(ra) # 80003fa2 <install_trans>
    log.lh.n = 0;
    800042be:	0001e797          	auipc	a5,0x1e
    800042c2:	8607ab23          	sw	zero,-1930(a5) # 80021b34 <log+0x2c>
    write_head();    // Erase the transaction from the log
    800042c6:	00000097          	auipc	ra,0x0
    800042ca:	c62080e7          	jalr	-926(ra) # 80003f28 <write_head>
    800042ce:	bdfd                	j	800041cc <end_op+0x52>

00000000800042d0 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800042d0:	1101                	addi	sp,sp,-32
    800042d2:	ec06                	sd	ra,24(sp)
    800042d4:	e822                	sd	s0,16(sp)
    800042d6:	e426                	sd	s1,8(sp)
    800042d8:	e04a                	sd	s2,0(sp)
    800042da:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800042dc:	0001e717          	auipc	a4,0x1e
    800042e0:	85872703          	lw	a4,-1960(a4) # 80021b34 <log+0x2c>
    800042e4:	47f5                	li	a5,29
    800042e6:	08e7c063          	blt	a5,a4,80004366 <log_write+0x96>
    800042ea:	84aa                	mv	s1,a0
    800042ec:	0001e797          	auipc	a5,0x1e
    800042f0:	8387a783          	lw	a5,-1992(a5) # 80021b24 <log+0x1c>
    800042f4:	37fd                	addiw	a5,a5,-1
    800042f6:	06f75863          	bge	a4,a5,80004366 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800042fa:	0001e797          	auipc	a5,0x1e
    800042fe:	82e7a783          	lw	a5,-2002(a5) # 80021b28 <log+0x20>
    80004302:	06f05a63          	blez	a5,80004376 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004306:	0001e917          	auipc	s2,0x1e
    8000430a:	80290913          	addi	s2,s2,-2046 # 80021b08 <log>
    8000430e:	854a                	mv	a0,s2
    80004310:	ffffd097          	auipc	ra,0xffffd
    80004314:	924080e7          	jalr	-1756(ra) # 80000c34 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004318:	02c92603          	lw	a2,44(s2)
    8000431c:	06c05563          	blez	a2,80004386 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004320:	44cc                	lw	a1,12(s1)
    80004322:	0001e717          	auipc	a4,0x1e
    80004326:	81670713          	addi	a4,a4,-2026 # 80021b38 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000432a:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000432c:	4314                	lw	a3,0(a4)
    8000432e:	04b68d63          	beq	a3,a1,80004388 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004332:	2785                	addiw	a5,a5,1
    80004334:	0711                	addi	a4,a4,4
    80004336:	fec79be3          	bne	a5,a2,8000432c <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000433a:	0621                	addi	a2,a2,8
    8000433c:	060a                	slli	a2,a2,0x2
    8000433e:	0001d797          	auipc	a5,0x1d
    80004342:	7ca78793          	addi	a5,a5,1994 # 80021b08 <log>
    80004346:	963e                	add	a2,a2,a5
    80004348:	44dc                	lw	a5,12(s1)
    8000434a:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000434c:	8526                	mv	a0,s1
    8000434e:	fffff097          	auipc	ra,0xfffff
    80004352:	dbc080e7          	jalr	-580(ra) # 8000310a <bpin>
    log.lh.n++;
    80004356:	0001d717          	auipc	a4,0x1d
    8000435a:	7b270713          	addi	a4,a4,1970 # 80021b08 <log>
    8000435e:	575c                	lw	a5,44(a4)
    80004360:	2785                	addiw	a5,a5,1
    80004362:	d75c                	sw	a5,44(a4)
    80004364:	a83d                	j	800043a2 <log_write+0xd2>
    panic("too big a transaction");
    80004366:	00004517          	auipc	a0,0x4
    8000436a:	44a50513          	addi	a0,a0,1098 # 800087b0 <syscall_names+0x200>
    8000436e:	ffffc097          	auipc	ra,0xffffc
    80004372:	1da080e7          	jalr	474(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    80004376:	00004517          	auipc	a0,0x4
    8000437a:	45250513          	addi	a0,a0,1106 # 800087c8 <syscall_names+0x218>
    8000437e:	ffffc097          	auipc	ra,0xffffc
    80004382:	1ca080e7          	jalr	458(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004386:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004388:	00878713          	addi	a4,a5,8
    8000438c:	00271693          	slli	a3,a4,0x2
    80004390:	0001d717          	auipc	a4,0x1d
    80004394:	77870713          	addi	a4,a4,1912 # 80021b08 <log>
    80004398:	9736                	add	a4,a4,a3
    8000439a:	44d4                	lw	a3,12(s1)
    8000439c:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000439e:	faf607e3          	beq	a2,a5,8000434c <log_write+0x7c>
  }
  release(&log.lock);
    800043a2:	0001d517          	auipc	a0,0x1d
    800043a6:	76650513          	addi	a0,a0,1894 # 80021b08 <log>
    800043aa:	ffffd097          	auipc	ra,0xffffd
    800043ae:	93e080e7          	jalr	-1730(ra) # 80000ce8 <release>
}
    800043b2:	60e2                	ld	ra,24(sp)
    800043b4:	6442                	ld	s0,16(sp)
    800043b6:	64a2                	ld	s1,8(sp)
    800043b8:	6902                	ld	s2,0(sp)
    800043ba:	6105                	addi	sp,sp,32
    800043bc:	8082                	ret

00000000800043be <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043be:	1101                	addi	sp,sp,-32
    800043c0:	ec06                	sd	ra,24(sp)
    800043c2:	e822                	sd	s0,16(sp)
    800043c4:	e426                	sd	s1,8(sp)
    800043c6:	e04a                	sd	s2,0(sp)
    800043c8:	1000                	addi	s0,sp,32
    800043ca:	84aa                	mv	s1,a0
    800043cc:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800043ce:	00004597          	auipc	a1,0x4
    800043d2:	41a58593          	addi	a1,a1,1050 # 800087e8 <syscall_names+0x238>
    800043d6:	0521                	addi	a0,a0,8
    800043d8:	ffffc097          	auipc	ra,0xffffc
    800043dc:	7cc080e7          	jalr	1996(ra) # 80000ba4 <initlock>
  lk->name = name;
    800043e0:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800043e4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800043e8:	0204a423          	sw	zero,40(s1)
}
    800043ec:	60e2                	ld	ra,24(sp)
    800043ee:	6442                	ld	s0,16(sp)
    800043f0:	64a2                	ld	s1,8(sp)
    800043f2:	6902                	ld	s2,0(sp)
    800043f4:	6105                	addi	sp,sp,32
    800043f6:	8082                	ret

00000000800043f8 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800043f8:	1101                	addi	sp,sp,-32
    800043fa:	ec06                	sd	ra,24(sp)
    800043fc:	e822                	sd	s0,16(sp)
    800043fe:	e426                	sd	s1,8(sp)
    80004400:	e04a                	sd	s2,0(sp)
    80004402:	1000                	addi	s0,sp,32
    80004404:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004406:	00850913          	addi	s2,a0,8
    8000440a:	854a                	mv	a0,s2
    8000440c:	ffffd097          	auipc	ra,0xffffd
    80004410:	828080e7          	jalr	-2008(ra) # 80000c34 <acquire>
  while (lk->locked) {
    80004414:	409c                	lw	a5,0(s1)
    80004416:	cb89                	beqz	a5,80004428 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004418:	85ca                	mv	a1,s2
    8000441a:	8526                	mv	a0,s1
    8000441c:	ffffe097          	auipc	ra,0xffffe
    80004420:	e02080e7          	jalr	-510(ra) # 8000221e <sleep>
  while (lk->locked) {
    80004424:	409c                	lw	a5,0(s1)
    80004426:	fbed                	bnez	a5,80004418 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004428:	4785                	li	a5,1
    8000442a:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000442c:	ffffd097          	auipc	ra,0xffffd
    80004430:	5d6080e7          	jalr	1494(ra) # 80001a02 <myproc>
    80004434:	5d1c                	lw	a5,56(a0)
    80004436:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004438:	854a                	mv	a0,s2
    8000443a:	ffffd097          	auipc	ra,0xffffd
    8000443e:	8ae080e7          	jalr	-1874(ra) # 80000ce8 <release>
}
    80004442:	60e2                	ld	ra,24(sp)
    80004444:	6442                	ld	s0,16(sp)
    80004446:	64a2                	ld	s1,8(sp)
    80004448:	6902                	ld	s2,0(sp)
    8000444a:	6105                	addi	sp,sp,32
    8000444c:	8082                	ret

000000008000444e <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000444e:	1101                	addi	sp,sp,-32
    80004450:	ec06                	sd	ra,24(sp)
    80004452:	e822                	sd	s0,16(sp)
    80004454:	e426                	sd	s1,8(sp)
    80004456:	e04a                	sd	s2,0(sp)
    80004458:	1000                	addi	s0,sp,32
    8000445a:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000445c:	00850913          	addi	s2,a0,8
    80004460:	854a                	mv	a0,s2
    80004462:	ffffc097          	auipc	ra,0xffffc
    80004466:	7d2080e7          	jalr	2002(ra) # 80000c34 <acquire>
  lk->locked = 0;
    8000446a:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000446e:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004472:	8526                	mv	a0,s1
    80004474:	ffffe097          	auipc	ra,0xffffe
    80004478:	f30080e7          	jalr	-208(ra) # 800023a4 <wakeup>
  release(&lk->lk);
    8000447c:	854a                	mv	a0,s2
    8000447e:	ffffd097          	auipc	ra,0xffffd
    80004482:	86a080e7          	jalr	-1942(ra) # 80000ce8 <release>
}
    80004486:	60e2                	ld	ra,24(sp)
    80004488:	6442                	ld	s0,16(sp)
    8000448a:	64a2                	ld	s1,8(sp)
    8000448c:	6902                	ld	s2,0(sp)
    8000448e:	6105                	addi	sp,sp,32
    80004490:	8082                	ret

0000000080004492 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004492:	7179                	addi	sp,sp,-48
    80004494:	f406                	sd	ra,40(sp)
    80004496:	f022                	sd	s0,32(sp)
    80004498:	ec26                	sd	s1,24(sp)
    8000449a:	e84a                	sd	s2,16(sp)
    8000449c:	e44e                	sd	s3,8(sp)
    8000449e:	1800                	addi	s0,sp,48
    800044a0:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044a2:	00850913          	addi	s2,a0,8
    800044a6:	854a                	mv	a0,s2
    800044a8:	ffffc097          	auipc	ra,0xffffc
    800044ac:	78c080e7          	jalr	1932(ra) # 80000c34 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044b0:	409c                	lw	a5,0(s1)
    800044b2:	ef99                	bnez	a5,800044d0 <holdingsleep+0x3e>
    800044b4:	4481                	li	s1,0
  release(&lk->lk);
    800044b6:	854a                	mv	a0,s2
    800044b8:	ffffd097          	auipc	ra,0xffffd
    800044bc:	830080e7          	jalr	-2000(ra) # 80000ce8 <release>
  return r;
}
    800044c0:	8526                	mv	a0,s1
    800044c2:	70a2                	ld	ra,40(sp)
    800044c4:	7402                	ld	s0,32(sp)
    800044c6:	64e2                	ld	s1,24(sp)
    800044c8:	6942                	ld	s2,16(sp)
    800044ca:	69a2                	ld	s3,8(sp)
    800044cc:	6145                	addi	sp,sp,48
    800044ce:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800044d0:	0284a983          	lw	s3,40(s1)
    800044d4:	ffffd097          	auipc	ra,0xffffd
    800044d8:	52e080e7          	jalr	1326(ra) # 80001a02 <myproc>
    800044dc:	5d04                	lw	s1,56(a0)
    800044de:	413484b3          	sub	s1,s1,s3
    800044e2:	0014b493          	seqz	s1,s1
    800044e6:	bfc1                	j	800044b6 <holdingsleep+0x24>

00000000800044e8 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800044e8:	1141                	addi	sp,sp,-16
    800044ea:	e406                	sd	ra,8(sp)
    800044ec:	e022                	sd	s0,0(sp)
    800044ee:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800044f0:	00004597          	auipc	a1,0x4
    800044f4:	30858593          	addi	a1,a1,776 # 800087f8 <syscall_names+0x248>
    800044f8:	0001d517          	auipc	a0,0x1d
    800044fc:	75850513          	addi	a0,a0,1880 # 80021c50 <ftable>
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	6a4080e7          	jalr	1700(ra) # 80000ba4 <initlock>
}
    80004508:	60a2                	ld	ra,8(sp)
    8000450a:	6402                	ld	s0,0(sp)
    8000450c:	0141                	addi	sp,sp,16
    8000450e:	8082                	ret

0000000080004510 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004510:	1101                	addi	sp,sp,-32
    80004512:	ec06                	sd	ra,24(sp)
    80004514:	e822                	sd	s0,16(sp)
    80004516:	e426                	sd	s1,8(sp)
    80004518:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000451a:	0001d517          	auipc	a0,0x1d
    8000451e:	73650513          	addi	a0,a0,1846 # 80021c50 <ftable>
    80004522:	ffffc097          	auipc	ra,0xffffc
    80004526:	712080e7          	jalr	1810(ra) # 80000c34 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000452a:	0001d497          	auipc	s1,0x1d
    8000452e:	73e48493          	addi	s1,s1,1854 # 80021c68 <ftable+0x18>
    80004532:	0001e717          	auipc	a4,0x1e
    80004536:	6d670713          	addi	a4,a4,1750 # 80022c08 <ftable+0xfb8>
    if(f->ref == 0){
    8000453a:	40dc                	lw	a5,4(s1)
    8000453c:	cf99                	beqz	a5,8000455a <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000453e:	02848493          	addi	s1,s1,40
    80004542:	fee49ce3          	bne	s1,a4,8000453a <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004546:	0001d517          	auipc	a0,0x1d
    8000454a:	70a50513          	addi	a0,a0,1802 # 80021c50 <ftable>
    8000454e:	ffffc097          	auipc	ra,0xffffc
    80004552:	79a080e7          	jalr	1946(ra) # 80000ce8 <release>
  return 0;
    80004556:	4481                	li	s1,0
    80004558:	a819                	j	8000456e <filealloc+0x5e>
      f->ref = 1;
    8000455a:	4785                	li	a5,1
    8000455c:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000455e:	0001d517          	auipc	a0,0x1d
    80004562:	6f250513          	addi	a0,a0,1778 # 80021c50 <ftable>
    80004566:	ffffc097          	auipc	ra,0xffffc
    8000456a:	782080e7          	jalr	1922(ra) # 80000ce8 <release>
}
    8000456e:	8526                	mv	a0,s1
    80004570:	60e2                	ld	ra,24(sp)
    80004572:	6442                	ld	s0,16(sp)
    80004574:	64a2                	ld	s1,8(sp)
    80004576:	6105                	addi	sp,sp,32
    80004578:	8082                	ret

000000008000457a <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000457a:	1101                	addi	sp,sp,-32
    8000457c:	ec06                	sd	ra,24(sp)
    8000457e:	e822                	sd	s0,16(sp)
    80004580:	e426                	sd	s1,8(sp)
    80004582:	1000                	addi	s0,sp,32
    80004584:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004586:	0001d517          	auipc	a0,0x1d
    8000458a:	6ca50513          	addi	a0,a0,1738 # 80021c50 <ftable>
    8000458e:	ffffc097          	auipc	ra,0xffffc
    80004592:	6a6080e7          	jalr	1702(ra) # 80000c34 <acquire>
  if(f->ref < 1)
    80004596:	40dc                	lw	a5,4(s1)
    80004598:	02f05263          	blez	a5,800045bc <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000459c:	2785                	addiw	a5,a5,1
    8000459e:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045a0:	0001d517          	auipc	a0,0x1d
    800045a4:	6b050513          	addi	a0,a0,1712 # 80021c50 <ftable>
    800045a8:	ffffc097          	auipc	ra,0xffffc
    800045ac:	740080e7          	jalr	1856(ra) # 80000ce8 <release>
  return f;
}
    800045b0:	8526                	mv	a0,s1
    800045b2:	60e2                	ld	ra,24(sp)
    800045b4:	6442                	ld	s0,16(sp)
    800045b6:	64a2                	ld	s1,8(sp)
    800045b8:	6105                	addi	sp,sp,32
    800045ba:	8082                	ret
    panic("filedup");
    800045bc:	00004517          	auipc	a0,0x4
    800045c0:	24450513          	addi	a0,a0,580 # 80008800 <syscall_names+0x250>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	f84080e7          	jalr	-124(ra) # 80000548 <panic>

00000000800045cc <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800045cc:	7139                	addi	sp,sp,-64
    800045ce:	fc06                	sd	ra,56(sp)
    800045d0:	f822                	sd	s0,48(sp)
    800045d2:	f426                	sd	s1,40(sp)
    800045d4:	f04a                	sd	s2,32(sp)
    800045d6:	ec4e                	sd	s3,24(sp)
    800045d8:	e852                	sd	s4,16(sp)
    800045da:	e456                	sd	s5,8(sp)
    800045dc:	0080                	addi	s0,sp,64
    800045de:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800045e0:	0001d517          	auipc	a0,0x1d
    800045e4:	67050513          	addi	a0,a0,1648 # 80021c50 <ftable>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	64c080e7          	jalr	1612(ra) # 80000c34 <acquire>
  if(f->ref < 1)
    800045f0:	40dc                	lw	a5,4(s1)
    800045f2:	06f05163          	blez	a5,80004654 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800045f6:	37fd                	addiw	a5,a5,-1
    800045f8:	0007871b          	sext.w	a4,a5
    800045fc:	c0dc                	sw	a5,4(s1)
    800045fe:	06e04363          	bgtz	a4,80004664 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004602:	0004a903          	lw	s2,0(s1)
    80004606:	0094ca83          	lbu	s5,9(s1)
    8000460a:	0104ba03          	ld	s4,16(s1)
    8000460e:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004612:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004616:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	63650513          	addi	a0,a0,1590 # 80021c50 <ftable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	6c6080e7          	jalr	1734(ra) # 80000ce8 <release>

  if(ff.type == FD_PIPE){
    8000462a:	4785                	li	a5,1
    8000462c:	04f90d63          	beq	s2,a5,80004686 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004630:	3979                	addiw	s2,s2,-2
    80004632:	4785                	li	a5,1
    80004634:	0527e063          	bltu	a5,s2,80004674 <fileclose+0xa8>
    begin_op();
    80004638:	00000097          	auipc	ra,0x0
    8000463c:	ac2080e7          	jalr	-1342(ra) # 800040fa <begin_op>
    iput(ff.ip);
    80004640:	854e                	mv	a0,s3
    80004642:	fffff097          	auipc	ra,0xfffff
    80004646:	2b6080e7          	jalr	694(ra) # 800038f8 <iput>
    end_op();
    8000464a:	00000097          	auipc	ra,0x0
    8000464e:	b30080e7          	jalr	-1232(ra) # 8000417a <end_op>
    80004652:	a00d                	j	80004674 <fileclose+0xa8>
    panic("fileclose");
    80004654:	00004517          	auipc	a0,0x4
    80004658:	1b450513          	addi	a0,a0,436 # 80008808 <syscall_names+0x258>
    8000465c:	ffffc097          	auipc	ra,0xffffc
    80004660:	eec080e7          	jalr	-276(ra) # 80000548 <panic>
    release(&ftable.lock);
    80004664:	0001d517          	auipc	a0,0x1d
    80004668:	5ec50513          	addi	a0,a0,1516 # 80021c50 <ftable>
    8000466c:	ffffc097          	auipc	ra,0xffffc
    80004670:	67c080e7          	jalr	1660(ra) # 80000ce8 <release>
  }
}
    80004674:	70e2                	ld	ra,56(sp)
    80004676:	7442                	ld	s0,48(sp)
    80004678:	74a2                	ld	s1,40(sp)
    8000467a:	7902                	ld	s2,32(sp)
    8000467c:	69e2                	ld	s3,24(sp)
    8000467e:	6a42                	ld	s4,16(sp)
    80004680:	6aa2                	ld	s5,8(sp)
    80004682:	6121                	addi	sp,sp,64
    80004684:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004686:	85d6                	mv	a1,s5
    80004688:	8552                	mv	a0,s4
    8000468a:	00000097          	auipc	ra,0x0
    8000468e:	372080e7          	jalr	882(ra) # 800049fc <pipeclose>
    80004692:	b7cd                	j	80004674 <fileclose+0xa8>

0000000080004694 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004694:	715d                	addi	sp,sp,-80
    80004696:	e486                	sd	ra,72(sp)
    80004698:	e0a2                	sd	s0,64(sp)
    8000469a:	fc26                	sd	s1,56(sp)
    8000469c:	f84a                	sd	s2,48(sp)
    8000469e:	f44e                	sd	s3,40(sp)
    800046a0:	0880                	addi	s0,sp,80
    800046a2:	84aa                	mv	s1,a0
    800046a4:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046a6:	ffffd097          	auipc	ra,0xffffd
    800046aa:	35c080e7          	jalr	860(ra) # 80001a02 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ae:	409c                	lw	a5,0(s1)
    800046b0:	37f9                	addiw	a5,a5,-2
    800046b2:	4705                	li	a4,1
    800046b4:	04f76763          	bltu	a4,a5,80004702 <filestat+0x6e>
    800046b8:	892a                	mv	s2,a0
    ilock(f->ip);
    800046ba:	6c88                	ld	a0,24(s1)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	082080e7          	jalr	130(ra) # 8000373e <ilock>
    stati(f->ip, &st);
    800046c4:	fb840593          	addi	a1,s0,-72
    800046c8:	6c88                	ld	a0,24(s1)
    800046ca:	fffff097          	auipc	ra,0xfffff
    800046ce:	2fe080e7          	jalr	766(ra) # 800039c8 <stati>
    iunlock(f->ip);
    800046d2:	6c88                	ld	a0,24(s1)
    800046d4:	fffff097          	auipc	ra,0xfffff
    800046d8:	12c080e7          	jalr	300(ra) # 80003800 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800046dc:	46e1                	li	a3,24
    800046de:	fb840613          	addi	a2,s0,-72
    800046e2:	85ce                	mv	a1,s3
    800046e4:	05093503          	ld	a0,80(s2)
    800046e8:	ffffd097          	auipc	ra,0xffffd
    800046ec:	00e080e7          	jalr	14(ra) # 800016f6 <copyout>
    800046f0:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800046f4:	60a6                	ld	ra,72(sp)
    800046f6:	6406                	ld	s0,64(sp)
    800046f8:	74e2                	ld	s1,56(sp)
    800046fa:	7942                	ld	s2,48(sp)
    800046fc:	79a2                	ld	s3,40(sp)
    800046fe:	6161                	addi	sp,sp,80
    80004700:	8082                	ret
  return -1;
    80004702:	557d                	li	a0,-1
    80004704:	bfc5                	j	800046f4 <filestat+0x60>

0000000080004706 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004706:	7179                	addi	sp,sp,-48
    80004708:	f406                	sd	ra,40(sp)
    8000470a:	f022                	sd	s0,32(sp)
    8000470c:	ec26                	sd	s1,24(sp)
    8000470e:	e84a                	sd	s2,16(sp)
    80004710:	e44e                	sd	s3,8(sp)
    80004712:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004714:	00854783          	lbu	a5,8(a0)
    80004718:	c3d5                	beqz	a5,800047bc <fileread+0xb6>
    8000471a:	84aa                	mv	s1,a0
    8000471c:	89ae                	mv	s3,a1
    8000471e:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004720:	411c                	lw	a5,0(a0)
    80004722:	4705                	li	a4,1
    80004724:	04e78963          	beq	a5,a4,80004776 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004728:	470d                	li	a4,3
    8000472a:	04e78d63          	beq	a5,a4,80004784 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000472e:	4709                	li	a4,2
    80004730:	06e79e63          	bne	a5,a4,800047ac <fileread+0xa6>
    ilock(f->ip);
    80004734:	6d08                	ld	a0,24(a0)
    80004736:	fffff097          	auipc	ra,0xfffff
    8000473a:	008080e7          	jalr	8(ra) # 8000373e <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000473e:	874a                	mv	a4,s2
    80004740:	5094                	lw	a3,32(s1)
    80004742:	864e                	mv	a2,s3
    80004744:	4585                	li	a1,1
    80004746:	6c88                	ld	a0,24(s1)
    80004748:	fffff097          	auipc	ra,0xfffff
    8000474c:	2aa080e7          	jalr	682(ra) # 800039f2 <readi>
    80004750:	892a                	mv	s2,a0
    80004752:	00a05563          	blez	a0,8000475c <fileread+0x56>
      f->off += r;
    80004756:	509c                	lw	a5,32(s1)
    80004758:	9fa9                	addw	a5,a5,a0
    8000475a:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000475c:	6c88                	ld	a0,24(s1)
    8000475e:	fffff097          	auipc	ra,0xfffff
    80004762:	0a2080e7          	jalr	162(ra) # 80003800 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004766:	854a                	mv	a0,s2
    80004768:	70a2                	ld	ra,40(sp)
    8000476a:	7402                	ld	s0,32(sp)
    8000476c:	64e2                	ld	s1,24(sp)
    8000476e:	6942                	ld	s2,16(sp)
    80004770:	69a2                	ld	s3,8(sp)
    80004772:	6145                	addi	sp,sp,48
    80004774:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004776:	6908                	ld	a0,16(a0)
    80004778:	00000097          	auipc	ra,0x0
    8000477c:	418080e7          	jalr	1048(ra) # 80004b90 <piperead>
    80004780:	892a                	mv	s2,a0
    80004782:	b7d5                	j	80004766 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004784:	02451783          	lh	a5,36(a0)
    80004788:	03079693          	slli	a3,a5,0x30
    8000478c:	92c1                	srli	a3,a3,0x30
    8000478e:	4725                	li	a4,9
    80004790:	02d76863          	bltu	a4,a3,800047c0 <fileread+0xba>
    80004794:	0792                	slli	a5,a5,0x4
    80004796:	0001d717          	auipc	a4,0x1d
    8000479a:	41a70713          	addi	a4,a4,1050 # 80021bb0 <devsw>
    8000479e:	97ba                	add	a5,a5,a4
    800047a0:	639c                	ld	a5,0(a5)
    800047a2:	c38d                	beqz	a5,800047c4 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047a4:	4505                	li	a0,1
    800047a6:	9782                	jalr	a5
    800047a8:	892a                	mv	s2,a0
    800047aa:	bf75                	j	80004766 <fileread+0x60>
    panic("fileread");
    800047ac:	00004517          	auipc	a0,0x4
    800047b0:	06c50513          	addi	a0,a0,108 # 80008818 <syscall_names+0x268>
    800047b4:	ffffc097          	auipc	ra,0xffffc
    800047b8:	d94080e7          	jalr	-620(ra) # 80000548 <panic>
    return -1;
    800047bc:	597d                	li	s2,-1
    800047be:	b765                	j	80004766 <fileread+0x60>
      return -1;
    800047c0:	597d                	li	s2,-1
    800047c2:	b755                	j	80004766 <fileread+0x60>
    800047c4:	597d                	li	s2,-1
    800047c6:	b745                	j	80004766 <fileread+0x60>

00000000800047c8 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    800047c8:	00954783          	lbu	a5,9(a0)
    800047cc:	14078563          	beqz	a5,80004916 <filewrite+0x14e>
{
    800047d0:	715d                	addi	sp,sp,-80
    800047d2:	e486                	sd	ra,72(sp)
    800047d4:	e0a2                	sd	s0,64(sp)
    800047d6:	fc26                	sd	s1,56(sp)
    800047d8:	f84a                	sd	s2,48(sp)
    800047da:	f44e                	sd	s3,40(sp)
    800047dc:	f052                	sd	s4,32(sp)
    800047de:	ec56                	sd	s5,24(sp)
    800047e0:	e85a                	sd	s6,16(sp)
    800047e2:	e45e                	sd	s7,8(sp)
    800047e4:	e062                	sd	s8,0(sp)
    800047e6:	0880                	addi	s0,sp,80
    800047e8:	892a                	mv	s2,a0
    800047ea:	8aae                	mv	s5,a1
    800047ec:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800047ee:	411c                	lw	a5,0(a0)
    800047f0:	4705                	li	a4,1
    800047f2:	02e78263          	beq	a5,a4,80004816 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800047f6:	470d                	li	a4,3
    800047f8:	02e78563          	beq	a5,a4,80004822 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800047fc:	4709                	li	a4,2
    800047fe:	10e79463          	bne	a5,a4,80004906 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004802:	0ec05e63          	blez	a2,800048fe <filewrite+0x136>
    int i = 0;
    80004806:	4981                	li	s3,0
    80004808:	6b05                	lui	s6,0x1
    8000480a:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000480e:	6b85                	lui	s7,0x1
    80004810:	c00b8b9b          	addiw	s7,s7,-1024
    80004814:	a851                	j	800048a8 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004816:	6908                	ld	a0,16(a0)
    80004818:	00000097          	auipc	ra,0x0
    8000481c:	254080e7          	jalr	596(ra) # 80004a6c <pipewrite>
    80004820:	a85d                	j	800048d6 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004822:	02451783          	lh	a5,36(a0)
    80004826:	03079693          	slli	a3,a5,0x30
    8000482a:	92c1                	srli	a3,a3,0x30
    8000482c:	4725                	li	a4,9
    8000482e:	0ed76663          	bltu	a4,a3,8000491a <filewrite+0x152>
    80004832:	0792                	slli	a5,a5,0x4
    80004834:	0001d717          	auipc	a4,0x1d
    80004838:	37c70713          	addi	a4,a4,892 # 80021bb0 <devsw>
    8000483c:	97ba                	add	a5,a5,a4
    8000483e:	679c                	ld	a5,8(a5)
    80004840:	cff9                	beqz	a5,8000491e <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004842:	4505                	li	a0,1
    80004844:	9782                	jalr	a5
    80004846:	a841                	j	800048d6 <filewrite+0x10e>
    80004848:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000484c:	00000097          	auipc	ra,0x0
    80004850:	8ae080e7          	jalr	-1874(ra) # 800040fa <begin_op>
      ilock(f->ip);
    80004854:	01893503          	ld	a0,24(s2)
    80004858:	fffff097          	auipc	ra,0xfffff
    8000485c:	ee6080e7          	jalr	-282(ra) # 8000373e <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004860:	8762                	mv	a4,s8
    80004862:	02092683          	lw	a3,32(s2)
    80004866:	01598633          	add	a2,s3,s5
    8000486a:	4585                	li	a1,1
    8000486c:	01893503          	ld	a0,24(s2)
    80004870:	fffff097          	auipc	ra,0xfffff
    80004874:	278080e7          	jalr	632(ra) # 80003ae8 <writei>
    80004878:	84aa                	mv	s1,a0
    8000487a:	02a05f63          	blez	a0,800048b8 <filewrite+0xf0>
        f->off += r;
    8000487e:	02092783          	lw	a5,32(s2)
    80004882:	9fa9                	addw	a5,a5,a0
    80004884:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004888:	01893503          	ld	a0,24(s2)
    8000488c:	fffff097          	auipc	ra,0xfffff
    80004890:	f74080e7          	jalr	-140(ra) # 80003800 <iunlock>
      end_op();
    80004894:	00000097          	auipc	ra,0x0
    80004898:	8e6080e7          	jalr	-1818(ra) # 8000417a <end_op>

      if(r < 0)
        break;
      if(r != n1)
    8000489c:	049c1963          	bne	s8,s1,800048ee <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048a0:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048a4:	0349d663          	bge	s3,s4,800048d0 <filewrite+0x108>
      int n1 = n - i;
    800048a8:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048ac:	84be                	mv	s1,a5
    800048ae:	2781                	sext.w	a5,a5
    800048b0:	f8fb5ce3          	bge	s6,a5,80004848 <filewrite+0x80>
    800048b4:	84de                	mv	s1,s7
    800048b6:	bf49                	j	80004848 <filewrite+0x80>
      iunlock(f->ip);
    800048b8:	01893503          	ld	a0,24(s2)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	f44080e7          	jalr	-188(ra) # 80003800 <iunlock>
      end_op();
    800048c4:	00000097          	auipc	ra,0x0
    800048c8:	8b6080e7          	jalr	-1866(ra) # 8000417a <end_op>
      if(r < 0)
    800048cc:	fc04d8e3          	bgez	s1,8000489c <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    800048d0:	8552                	mv	a0,s4
    800048d2:	033a1863          	bne	s4,s3,80004902 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800048d6:	60a6                	ld	ra,72(sp)
    800048d8:	6406                	ld	s0,64(sp)
    800048da:	74e2                	ld	s1,56(sp)
    800048dc:	7942                	ld	s2,48(sp)
    800048de:	79a2                	ld	s3,40(sp)
    800048e0:	7a02                	ld	s4,32(sp)
    800048e2:	6ae2                	ld	s5,24(sp)
    800048e4:	6b42                	ld	s6,16(sp)
    800048e6:	6ba2                	ld	s7,8(sp)
    800048e8:	6c02                	ld	s8,0(sp)
    800048ea:	6161                	addi	sp,sp,80
    800048ec:	8082                	ret
        panic("short filewrite");
    800048ee:	00004517          	auipc	a0,0x4
    800048f2:	f3a50513          	addi	a0,a0,-198 # 80008828 <syscall_names+0x278>
    800048f6:	ffffc097          	auipc	ra,0xffffc
    800048fa:	c52080e7          	jalr	-942(ra) # 80000548 <panic>
    int i = 0;
    800048fe:	4981                	li	s3,0
    80004900:	bfc1                	j	800048d0 <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004902:	557d                	li	a0,-1
    80004904:	bfc9                	j	800048d6 <filewrite+0x10e>
    panic("filewrite");
    80004906:	00004517          	auipc	a0,0x4
    8000490a:	f3250513          	addi	a0,a0,-206 # 80008838 <syscall_names+0x288>
    8000490e:	ffffc097          	auipc	ra,0xffffc
    80004912:	c3a080e7          	jalr	-966(ra) # 80000548 <panic>
    return -1;
    80004916:	557d                	li	a0,-1
}
    80004918:	8082                	ret
      return -1;
    8000491a:	557d                	li	a0,-1
    8000491c:	bf6d                	j	800048d6 <filewrite+0x10e>
    8000491e:	557d                	li	a0,-1
    80004920:	bf5d                	j	800048d6 <filewrite+0x10e>

0000000080004922 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004922:	7179                	addi	sp,sp,-48
    80004924:	f406                	sd	ra,40(sp)
    80004926:	f022                	sd	s0,32(sp)
    80004928:	ec26                	sd	s1,24(sp)
    8000492a:	e84a                	sd	s2,16(sp)
    8000492c:	e44e                	sd	s3,8(sp)
    8000492e:	e052                	sd	s4,0(sp)
    80004930:	1800                	addi	s0,sp,48
    80004932:	84aa                	mv	s1,a0
    80004934:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004936:	0005b023          	sd	zero,0(a1)
    8000493a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000493e:	00000097          	auipc	ra,0x0
    80004942:	bd2080e7          	jalr	-1070(ra) # 80004510 <filealloc>
    80004946:	e088                	sd	a0,0(s1)
    80004948:	c551                	beqz	a0,800049d4 <pipealloc+0xb2>
    8000494a:	00000097          	auipc	ra,0x0
    8000494e:	bc6080e7          	jalr	-1082(ra) # 80004510 <filealloc>
    80004952:	00aa3023          	sd	a0,0(s4)
    80004956:	c92d                	beqz	a0,800049c8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004958:	ffffc097          	auipc	ra,0xffffc
    8000495c:	1c8080e7          	jalr	456(ra) # 80000b20 <kalloc>
    80004960:	892a                	mv	s2,a0
    80004962:	c125                	beqz	a0,800049c2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004964:	4985                	li	s3,1
    80004966:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000496a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000496e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004972:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004976:	00004597          	auipc	a1,0x4
    8000497a:	aca58593          	addi	a1,a1,-1334 # 80008440 <states.1707+0x198>
    8000497e:	ffffc097          	auipc	ra,0xffffc
    80004982:	226080e7          	jalr	550(ra) # 80000ba4 <initlock>
  (*f0)->type = FD_PIPE;
    80004986:	609c                	ld	a5,0(s1)
    80004988:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    8000498c:	609c                	ld	a5,0(s1)
    8000498e:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004992:	609c                	ld	a5,0(s1)
    80004994:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004998:	609c                	ld	a5,0(s1)
    8000499a:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000499e:	000a3783          	ld	a5,0(s4)
    800049a2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049a6:	000a3783          	ld	a5,0(s4)
    800049aa:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ae:	000a3783          	ld	a5,0(s4)
    800049b2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049b6:	000a3783          	ld	a5,0(s4)
    800049ba:	0127b823          	sd	s2,16(a5)
  return 0;
    800049be:	4501                	li	a0,0
    800049c0:	a025                	j	800049e8 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049c2:	6088                	ld	a0,0(s1)
    800049c4:	e501                	bnez	a0,800049cc <pipealloc+0xaa>
    800049c6:	a039                	j	800049d4 <pipealloc+0xb2>
    800049c8:	6088                	ld	a0,0(s1)
    800049ca:	c51d                	beqz	a0,800049f8 <pipealloc+0xd6>
    fileclose(*f0);
    800049cc:	00000097          	auipc	ra,0x0
    800049d0:	c00080e7          	jalr	-1024(ra) # 800045cc <fileclose>
  if(*f1)
    800049d4:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049d8:	557d                	li	a0,-1
  if(*f1)
    800049da:	c799                	beqz	a5,800049e8 <pipealloc+0xc6>
    fileclose(*f1);
    800049dc:	853e                	mv	a0,a5
    800049de:	00000097          	auipc	ra,0x0
    800049e2:	bee080e7          	jalr	-1042(ra) # 800045cc <fileclose>
  return -1;
    800049e6:	557d                	li	a0,-1
}
    800049e8:	70a2                	ld	ra,40(sp)
    800049ea:	7402                	ld	s0,32(sp)
    800049ec:	64e2                	ld	s1,24(sp)
    800049ee:	6942                	ld	s2,16(sp)
    800049f0:	69a2                	ld	s3,8(sp)
    800049f2:	6a02                	ld	s4,0(sp)
    800049f4:	6145                	addi	sp,sp,48
    800049f6:	8082                	ret
  return -1;
    800049f8:	557d                	li	a0,-1
    800049fa:	b7fd                	j	800049e8 <pipealloc+0xc6>

00000000800049fc <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800049fc:	1101                	addi	sp,sp,-32
    800049fe:	ec06                	sd	ra,24(sp)
    80004a00:	e822                	sd	s0,16(sp)
    80004a02:	e426                	sd	s1,8(sp)
    80004a04:	e04a                	sd	s2,0(sp)
    80004a06:	1000                	addi	s0,sp,32
    80004a08:	84aa                	mv	s1,a0
    80004a0a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a0c:	ffffc097          	auipc	ra,0xffffc
    80004a10:	228080e7          	jalr	552(ra) # 80000c34 <acquire>
  if(writable){
    80004a14:	02090d63          	beqz	s2,80004a4e <pipeclose+0x52>
    pi->writeopen = 0;
    80004a18:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a1c:	21848513          	addi	a0,s1,536
    80004a20:	ffffe097          	auipc	ra,0xffffe
    80004a24:	984080e7          	jalr	-1660(ra) # 800023a4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a28:	2204b783          	ld	a5,544(s1)
    80004a2c:	eb95                	bnez	a5,80004a60 <pipeclose+0x64>
    release(&pi->lock);
    80004a2e:	8526                	mv	a0,s1
    80004a30:	ffffc097          	auipc	ra,0xffffc
    80004a34:	2b8080e7          	jalr	696(ra) # 80000ce8 <release>
    kfree((char*)pi);
    80004a38:	8526                	mv	a0,s1
    80004a3a:	ffffc097          	auipc	ra,0xffffc
    80004a3e:	fea080e7          	jalr	-22(ra) # 80000a24 <kfree>
  } else
    release(&pi->lock);
}
    80004a42:	60e2                	ld	ra,24(sp)
    80004a44:	6442                	ld	s0,16(sp)
    80004a46:	64a2                	ld	s1,8(sp)
    80004a48:	6902                	ld	s2,0(sp)
    80004a4a:	6105                	addi	sp,sp,32
    80004a4c:	8082                	ret
    pi->readopen = 0;
    80004a4e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a52:	21c48513          	addi	a0,s1,540
    80004a56:	ffffe097          	auipc	ra,0xffffe
    80004a5a:	94e080e7          	jalr	-1714(ra) # 800023a4 <wakeup>
    80004a5e:	b7e9                	j	80004a28 <pipeclose+0x2c>
    release(&pi->lock);
    80004a60:	8526                	mv	a0,s1
    80004a62:	ffffc097          	auipc	ra,0xffffc
    80004a66:	286080e7          	jalr	646(ra) # 80000ce8 <release>
}
    80004a6a:	bfe1                	j	80004a42 <pipeclose+0x46>

0000000080004a6c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a6c:	7119                	addi	sp,sp,-128
    80004a6e:	fc86                	sd	ra,120(sp)
    80004a70:	f8a2                	sd	s0,112(sp)
    80004a72:	f4a6                	sd	s1,104(sp)
    80004a74:	f0ca                	sd	s2,96(sp)
    80004a76:	ecce                	sd	s3,88(sp)
    80004a78:	e8d2                	sd	s4,80(sp)
    80004a7a:	e4d6                	sd	s5,72(sp)
    80004a7c:	e0da                	sd	s6,64(sp)
    80004a7e:	fc5e                	sd	s7,56(sp)
    80004a80:	f862                	sd	s8,48(sp)
    80004a82:	f466                	sd	s9,40(sp)
    80004a84:	f06a                	sd	s10,32(sp)
    80004a86:	ec6e                	sd	s11,24(sp)
    80004a88:	0100                	addi	s0,sp,128
    80004a8a:	84aa                	mv	s1,a0
    80004a8c:	8cae                	mv	s9,a1
    80004a8e:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004a90:	ffffd097          	auipc	ra,0xffffd
    80004a94:	f72080e7          	jalr	-142(ra) # 80001a02 <myproc>
    80004a98:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004a9a:	8526                	mv	a0,s1
    80004a9c:	ffffc097          	auipc	ra,0xffffc
    80004aa0:	198080e7          	jalr	408(ra) # 80000c34 <acquire>
  for(i = 0; i < n; i++){
    80004aa4:	0d605963          	blez	s6,80004b76 <pipewrite+0x10a>
    80004aa8:	89a6                	mv	s3,s1
    80004aaa:	3b7d                	addiw	s6,s6,-1
    80004aac:	1b02                	slli	s6,s6,0x20
    80004aae:	020b5b13          	srli	s6,s6,0x20
    80004ab2:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004ab4:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ab8:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004abc:	5dfd                	li	s11,-1
    80004abe:	000b8d1b          	sext.w	s10,s7
    80004ac2:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004ac4:	2184a783          	lw	a5,536(s1)
    80004ac8:	21c4a703          	lw	a4,540(s1)
    80004acc:	2007879b          	addiw	a5,a5,512
    80004ad0:	02f71b63          	bne	a4,a5,80004b06 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004ad4:	2204a783          	lw	a5,544(s1)
    80004ad8:	cbad                	beqz	a5,80004b4a <pipewrite+0xde>
    80004ada:	03092783          	lw	a5,48(s2)
    80004ade:	e7b5                	bnez	a5,80004b4a <pipewrite+0xde>
      wakeup(&pi->nread);
    80004ae0:	8556                	mv	a0,s5
    80004ae2:	ffffe097          	auipc	ra,0xffffe
    80004ae6:	8c2080e7          	jalr	-1854(ra) # 800023a4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004aea:	85ce                	mv	a1,s3
    80004aec:	8552                	mv	a0,s4
    80004aee:	ffffd097          	auipc	ra,0xffffd
    80004af2:	730080e7          	jalr	1840(ra) # 8000221e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004af6:	2184a783          	lw	a5,536(s1)
    80004afa:	21c4a703          	lw	a4,540(s1)
    80004afe:	2007879b          	addiw	a5,a5,512
    80004b02:	fcf709e3          	beq	a4,a5,80004ad4 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b06:	4685                	li	a3,1
    80004b08:	019b8633          	add	a2,s7,s9
    80004b0c:	f8f40593          	addi	a1,s0,-113
    80004b10:	05093503          	ld	a0,80(s2)
    80004b14:	ffffd097          	auipc	ra,0xffffd
    80004b18:	c6e080e7          	jalr	-914(ra) # 80001782 <copyin>
    80004b1c:	05b50e63          	beq	a0,s11,80004b78 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b20:	21c4a783          	lw	a5,540(s1)
    80004b24:	0017871b          	addiw	a4,a5,1
    80004b28:	20e4ae23          	sw	a4,540(s1)
    80004b2c:	1ff7f793          	andi	a5,a5,511
    80004b30:	97a6                	add	a5,a5,s1
    80004b32:	f8f44703          	lbu	a4,-113(s0)
    80004b36:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b3a:	001d0c1b          	addiw	s8,s10,1
    80004b3e:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b42:	036b8b63          	beq	s7,s6,80004b78 <pipewrite+0x10c>
    80004b46:	8bbe                	mv	s7,a5
    80004b48:	bf9d                	j	80004abe <pipewrite+0x52>
        release(&pi->lock);
    80004b4a:	8526                	mv	a0,s1
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	19c080e7          	jalr	412(ra) # 80000ce8 <release>
        return -1;
    80004b54:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b56:	8562                	mv	a0,s8
    80004b58:	70e6                	ld	ra,120(sp)
    80004b5a:	7446                	ld	s0,112(sp)
    80004b5c:	74a6                	ld	s1,104(sp)
    80004b5e:	7906                	ld	s2,96(sp)
    80004b60:	69e6                	ld	s3,88(sp)
    80004b62:	6a46                	ld	s4,80(sp)
    80004b64:	6aa6                	ld	s5,72(sp)
    80004b66:	6b06                	ld	s6,64(sp)
    80004b68:	7be2                	ld	s7,56(sp)
    80004b6a:	7c42                	ld	s8,48(sp)
    80004b6c:	7ca2                	ld	s9,40(sp)
    80004b6e:	7d02                	ld	s10,32(sp)
    80004b70:	6de2                	ld	s11,24(sp)
    80004b72:	6109                	addi	sp,sp,128
    80004b74:	8082                	ret
  for(i = 0; i < n; i++){
    80004b76:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004b78:	21848513          	addi	a0,s1,536
    80004b7c:	ffffe097          	auipc	ra,0xffffe
    80004b80:	828080e7          	jalr	-2008(ra) # 800023a4 <wakeup>
  release(&pi->lock);
    80004b84:	8526                	mv	a0,s1
    80004b86:	ffffc097          	auipc	ra,0xffffc
    80004b8a:	162080e7          	jalr	354(ra) # 80000ce8 <release>
  return i;
    80004b8e:	b7e1                	j	80004b56 <pipewrite+0xea>

0000000080004b90 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b90:	715d                	addi	sp,sp,-80
    80004b92:	e486                	sd	ra,72(sp)
    80004b94:	e0a2                	sd	s0,64(sp)
    80004b96:	fc26                	sd	s1,56(sp)
    80004b98:	f84a                	sd	s2,48(sp)
    80004b9a:	f44e                	sd	s3,40(sp)
    80004b9c:	f052                	sd	s4,32(sp)
    80004b9e:	ec56                	sd	s5,24(sp)
    80004ba0:	e85a                	sd	s6,16(sp)
    80004ba2:	0880                	addi	s0,sp,80
    80004ba4:	84aa                	mv	s1,a0
    80004ba6:	892e                	mv	s2,a1
    80004ba8:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004baa:	ffffd097          	auipc	ra,0xffffd
    80004bae:	e58080e7          	jalr	-424(ra) # 80001a02 <myproc>
    80004bb2:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bb4:	8b26                	mv	s6,s1
    80004bb6:	8526                	mv	a0,s1
    80004bb8:	ffffc097          	auipc	ra,0xffffc
    80004bbc:	07c080e7          	jalr	124(ra) # 80000c34 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc0:	2184a703          	lw	a4,536(s1)
    80004bc4:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bc8:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bcc:	02f71463          	bne	a4,a5,80004bf4 <piperead+0x64>
    80004bd0:	2244a783          	lw	a5,548(s1)
    80004bd4:	c385                	beqz	a5,80004bf4 <piperead+0x64>
    if(pr->killed){
    80004bd6:	030a2783          	lw	a5,48(s4)
    80004bda:	ebc1                	bnez	a5,80004c6a <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bdc:	85da                	mv	a1,s6
    80004bde:	854e                	mv	a0,s3
    80004be0:	ffffd097          	auipc	ra,0xffffd
    80004be4:	63e080e7          	jalr	1598(ra) # 8000221e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be8:	2184a703          	lw	a4,536(s1)
    80004bec:	21c4a783          	lw	a5,540(s1)
    80004bf0:	fef700e3          	beq	a4,a5,80004bd0 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf4:	09505263          	blez	s5,80004c78 <piperead+0xe8>
    80004bf8:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bfa:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004bfc:	2184a783          	lw	a5,536(s1)
    80004c00:	21c4a703          	lw	a4,540(s1)
    80004c04:	02f70d63          	beq	a4,a5,80004c3e <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c08:	0017871b          	addiw	a4,a5,1
    80004c0c:	20e4ac23          	sw	a4,536(s1)
    80004c10:	1ff7f793          	andi	a5,a5,511
    80004c14:	97a6                	add	a5,a5,s1
    80004c16:	0187c783          	lbu	a5,24(a5)
    80004c1a:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c1e:	4685                	li	a3,1
    80004c20:	fbf40613          	addi	a2,s0,-65
    80004c24:	85ca                	mv	a1,s2
    80004c26:	050a3503          	ld	a0,80(s4)
    80004c2a:	ffffd097          	auipc	ra,0xffffd
    80004c2e:	acc080e7          	jalr	-1332(ra) # 800016f6 <copyout>
    80004c32:	01650663          	beq	a0,s6,80004c3e <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c36:	2985                	addiw	s3,s3,1
    80004c38:	0905                	addi	s2,s2,1
    80004c3a:	fd3a91e3          	bne	s5,s3,80004bfc <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3e:	21c48513          	addi	a0,s1,540
    80004c42:	ffffd097          	auipc	ra,0xffffd
    80004c46:	762080e7          	jalr	1890(ra) # 800023a4 <wakeup>
  release(&pi->lock);
    80004c4a:	8526                	mv	a0,s1
    80004c4c:	ffffc097          	auipc	ra,0xffffc
    80004c50:	09c080e7          	jalr	156(ra) # 80000ce8 <release>
  return i;
}
    80004c54:	854e                	mv	a0,s3
    80004c56:	60a6                	ld	ra,72(sp)
    80004c58:	6406                	ld	s0,64(sp)
    80004c5a:	74e2                	ld	s1,56(sp)
    80004c5c:	7942                	ld	s2,48(sp)
    80004c5e:	79a2                	ld	s3,40(sp)
    80004c60:	7a02                	ld	s4,32(sp)
    80004c62:	6ae2                	ld	s5,24(sp)
    80004c64:	6b42                	ld	s6,16(sp)
    80004c66:	6161                	addi	sp,sp,80
    80004c68:	8082                	ret
      release(&pi->lock);
    80004c6a:	8526                	mv	a0,s1
    80004c6c:	ffffc097          	auipc	ra,0xffffc
    80004c70:	07c080e7          	jalr	124(ra) # 80000ce8 <release>
      return -1;
    80004c74:	59fd                	li	s3,-1
    80004c76:	bff9                	j	80004c54 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c78:	4981                	li	s3,0
    80004c7a:	b7d1                	j	80004c3e <piperead+0xae>

0000000080004c7c <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004c7c:	df010113          	addi	sp,sp,-528
    80004c80:	20113423          	sd	ra,520(sp)
    80004c84:	20813023          	sd	s0,512(sp)
    80004c88:	ffa6                	sd	s1,504(sp)
    80004c8a:	fbca                	sd	s2,496(sp)
    80004c8c:	f7ce                	sd	s3,488(sp)
    80004c8e:	f3d2                	sd	s4,480(sp)
    80004c90:	efd6                	sd	s5,472(sp)
    80004c92:	ebda                	sd	s6,464(sp)
    80004c94:	e7de                	sd	s7,456(sp)
    80004c96:	e3e2                	sd	s8,448(sp)
    80004c98:	ff66                	sd	s9,440(sp)
    80004c9a:	fb6a                	sd	s10,432(sp)
    80004c9c:	f76e                	sd	s11,424(sp)
    80004c9e:	0c00                	addi	s0,sp,528
    80004ca0:	84aa                	mv	s1,a0
    80004ca2:	dea43c23          	sd	a0,-520(s0)
    80004ca6:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004caa:	ffffd097          	auipc	ra,0xffffd
    80004cae:	d58080e7          	jalr	-680(ra) # 80001a02 <myproc>
    80004cb2:	892a                	mv	s2,a0

  begin_op();
    80004cb4:	fffff097          	auipc	ra,0xfffff
    80004cb8:	446080e7          	jalr	1094(ra) # 800040fa <begin_op>

  if((ip = namei(path)) == 0){
    80004cbc:	8526                	mv	a0,s1
    80004cbe:	fffff097          	auipc	ra,0xfffff
    80004cc2:	230080e7          	jalr	560(ra) # 80003eee <namei>
    80004cc6:	c92d                	beqz	a0,80004d38 <exec+0xbc>
    80004cc8:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	a74080e7          	jalr	-1420(ra) # 8000373e <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004cd2:	04000713          	li	a4,64
    80004cd6:	4681                	li	a3,0
    80004cd8:	e4840613          	addi	a2,s0,-440
    80004cdc:	4581                	li	a1,0
    80004cde:	8526                	mv	a0,s1
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	d12080e7          	jalr	-750(ra) # 800039f2 <readi>
    80004ce8:	04000793          	li	a5,64
    80004cec:	00f51a63          	bne	a0,a5,80004d00 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004cf0:	e4842703          	lw	a4,-440(s0)
    80004cf4:	464c47b7          	lui	a5,0x464c4
    80004cf8:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004cfc:	04f70463          	beq	a4,a5,80004d44 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d00:	8526                	mv	a0,s1
    80004d02:	fffff097          	auipc	ra,0xfffff
    80004d06:	c9e080e7          	jalr	-866(ra) # 800039a0 <iunlockput>
    end_op();
    80004d0a:	fffff097          	auipc	ra,0xfffff
    80004d0e:	470080e7          	jalr	1136(ra) # 8000417a <end_op>
  }
  return -1;
    80004d12:	557d                	li	a0,-1
}
    80004d14:	20813083          	ld	ra,520(sp)
    80004d18:	20013403          	ld	s0,512(sp)
    80004d1c:	74fe                	ld	s1,504(sp)
    80004d1e:	795e                	ld	s2,496(sp)
    80004d20:	79be                	ld	s3,488(sp)
    80004d22:	7a1e                	ld	s4,480(sp)
    80004d24:	6afe                	ld	s5,472(sp)
    80004d26:	6b5e                	ld	s6,464(sp)
    80004d28:	6bbe                	ld	s7,456(sp)
    80004d2a:	6c1e                	ld	s8,448(sp)
    80004d2c:	7cfa                	ld	s9,440(sp)
    80004d2e:	7d5a                	ld	s10,432(sp)
    80004d30:	7dba                	ld	s11,424(sp)
    80004d32:	21010113          	addi	sp,sp,528
    80004d36:	8082                	ret
    end_op();
    80004d38:	fffff097          	auipc	ra,0xfffff
    80004d3c:	442080e7          	jalr	1090(ra) # 8000417a <end_op>
    return -1;
    80004d40:	557d                	li	a0,-1
    80004d42:	bfc9                	j	80004d14 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d44:	854a                	mv	a0,s2
    80004d46:	ffffd097          	auipc	ra,0xffffd
    80004d4a:	d80080e7          	jalr	-640(ra) # 80001ac6 <proc_pagetable>
    80004d4e:	8baa                	mv	s7,a0
    80004d50:	d945                	beqz	a0,80004d00 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d52:	e6842983          	lw	s3,-408(s0)
    80004d56:	e8045783          	lhu	a5,-384(s0)
    80004d5a:	c7ad                	beqz	a5,80004dc4 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d5c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d5e:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d60:	6c85                	lui	s9,0x1
    80004d62:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004d66:	def43823          	sd	a5,-528(s0)
    80004d6a:	a42d                	j	80004f94 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d6c:	00004517          	auipc	a0,0x4
    80004d70:	adc50513          	addi	a0,a0,-1316 # 80008848 <syscall_names+0x298>
    80004d74:	ffffb097          	auipc	ra,0xffffb
    80004d78:	7d4080e7          	jalr	2004(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d7c:	8756                	mv	a4,s5
    80004d7e:	012d86bb          	addw	a3,s11,s2
    80004d82:	4581                	li	a1,0
    80004d84:	8526                	mv	a0,s1
    80004d86:	fffff097          	auipc	ra,0xfffff
    80004d8a:	c6c080e7          	jalr	-916(ra) # 800039f2 <readi>
    80004d8e:	2501                	sext.w	a0,a0
    80004d90:	1aaa9963          	bne	s5,a0,80004f42 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004d94:	6785                	lui	a5,0x1
    80004d96:	0127893b          	addw	s2,a5,s2
    80004d9a:	77fd                	lui	a5,0xfffff
    80004d9c:	01478a3b          	addw	s4,a5,s4
    80004da0:	1f897163          	bgeu	s2,s8,80004f82 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004da4:	02091593          	slli	a1,s2,0x20
    80004da8:	9181                	srli	a1,a1,0x20
    80004daa:	95ea                	add	a1,a1,s10
    80004dac:	855e                	mv	a0,s7
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	314080e7          	jalr	788(ra) # 800010c2 <walkaddr>
    80004db6:	862a                	mv	a2,a0
    if(pa == 0)
    80004db8:	d955                	beqz	a0,80004d6c <exec+0xf0>
      n = PGSIZE;
    80004dba:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dbc:	fd9a70e3          	bgeu	s4,s9,80004d7c <exec+0x100>
      n = sz - i;
    80004dc0:	8ad2                	mv	s5,s4
    80004dc2:	bf6d                	j	80004d7c <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004dc4:	4901                	li	s2,0
  iunlockput(ip);
    80004dc6:	8526                	mv	a0,s1
    80004dc8:	fffff097          	auipc	ra,0xfffff
    80004dcc:	bd8080e7          	jalr	-1064(ra) # 800039a0 <iunlockput>
  end_op();
    80004dd0:	fffff097          	auipc	ra,0xfffff
    80004dd4:	3aa080e7          	jalr	938(ra) # 8000417a <end_op>
  p = myproc();
    80004dd8:	ffffd097          	auipc	ra,0xffffd
    80004ddc:	c2a080e7          	jalr	-982(ra) # 80001a02 <myproc>
    80004de0:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004de2:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004de6:	6785                	lui	a5,0x1
    80004de8:	17fd                	addi	a5,a5,-1
    80004dea:	993e                	add	s2,s2,a5
    80004dec:	757d                	lui	a0,0xfffff
    80004dee:	00a977b3          	and	a5,s2,a0
    80004df2:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004df6:	6609                	lui	a2,0x2
    80004df8:	963e                	add	a2,a2,a5
    80004dfa:	85be                	mv	a1,a5
    80004dfc:	855e                	mv	a0,s7
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	6a8080e7          	jalr	1704(ra) # 800014a6 <uvmalloc>
    80004e06:	8b2a                	mv	s6,a0
  ip = 0;
    80004e08:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e0a:	12050c63          	beqz	a0,80004f42 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e0e:	75f9                	lui	a1,0xffffe
    80004e10:	95aa                	add	a1,a1,a0
    80004e12:	855e                	mv	a0,s7
    80004e14:	ffffd097          	auipc	ra,0xffffd
    80004e18:	8b0080e7          	jalr	-1872(ra) # 800016c4 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e1c:	7c7d                	lui	s8,0xfffff
    80004e1e:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e20:	e0043783          	ld	a5,-512(s0)
    80004e24:	6388                	ld	a0,0(a5)
    80004e26:	c535                	beqz	a0,80004e92 <exec+0x216>
    80004e28:	e8840993          	addi	s3,s0,-376
    80004e2c:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e30:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e32:	ffffc097          	auipc	ra,0xffffc
    80004e36:	086080e7          	jalr	134(ra) # 80000eb8 <strlen>
    80004e3a:	2505                	addiw	a0,a0,1
    80004e3c:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e40:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e44:	13896363          	bltu	s2,s8,80004f6a <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e48:	e0043d83          	ld	s11,-512(s0)
    80004e4c:	000dba03          	ld	s4,0(s11)
    80004e50:	8552                	mv	a0,s4
    80004e52:	ffffc097          	auipc	ra,0xffffc
    80004e56:	066080e7          	jalr	102(ra) # 80000eb8 <strlen>
    80004e5a:	0015069b          	addiw	a3,a0,1
    80004e5e:	8652                	mv	a2,s4
    80004e60:	85ca                	mv	a1,s2
    80004e62:	855e                	mv	a0,s7
    80004e64:	ffffd097          	auipc	ra,0xffffd
    80004e68:	892080e7          	jalr	-1902(ra) # 800016f6 <copyout>
    80004e6c:	10054363          	bltz	a0,80004f72 <exec+0x2f6>
    ustack[argc] = sp;
    80004e70:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e74:	0485                	addi	s1,s1,1
    80004e76:	008d8793          	addi	a5,s11,8
    80004e7a:	e0f43023          	sd	a5,-512(s0)
    80004e7e:	008db503          	ld	a0,8(s11)
    80004e82:	c911                	beqz	a0,80004e96 <exec+0x21a>
    if(argc >= MAXARG)
    80004e84:	09a1                	addi	s3,s3,8
    80004e86:	fb3c96e3          	bne	s9,s3,80004e32 <exec+0x1b6>
  sz = sz1;
    80004e8a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004e8e:	4481                	li	s1,0
    80004e90:	a84d                	j	80004f42 <exec+0x2c6>
  sp = sz;
    80004e92:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e94:	4481                	li	s1,0
  ustack[argc] = 0;
    80004e96:	00349793          	slli	a5,s1,0x3
    80004e9a:	f9040713          	addi	a4,s0,-112
    80004e9e:	97ba                	add	a5,a5,a4
    80004ea0:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ea4:	00148693          	addi	a3,s1,1
    80004ea8:	068e                	slli	a3,a3,0x3
    80004eaa:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eae:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004eb2:	01897663          	bgeu	s2,s8,80004ebe <exec+0x242>
  sz = sz1;
    80004eb6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004eba:	4481                	li	s1,0
    80004ebc:	a059                	j	80004f42 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ebe:	e8840613          	addi	a2,s0,-376
    80004ec2:	85ca                	mv	a1,s2
    80004ec4:	855e                	mv	a0,s7
    80004ec6:	ffffd097          	auipc	ra,0xffffd
    80004eca:	830080e7          	jalr	-2000(ra) # 800016f6 <copyout>
    80004ece:	0a054663          	bltz	a0,80004f7a <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004ed2:	058ab783          	ld	a5,88(s5)
    80004ed6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004eda:	df843783          	ld	a5,-520(s0)
    80004ede:	0007c703          	lbu	a4,0(a5)
    80004ee2:	cf11                	beqz	a4,80004efe <exec+0x282>
    80004ee4:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004ee6:	02f00693          	li	a3,47
    80004eea:	a029                	j	80004ef4 <exec+0x278>
  for(last=s=path; *s; s++)
    80004eec:	0785                	addi	a5,a5,1
    80004eee:	fff7c703          	lbu	a4,-1(a5)
    80004ef2:	c711                	beqz	a4,80004efe <exec+0x282>
    if(*s == '/')
    80004ef4:	fed71ce3          	bne	a4,a3,80004eec <exec+0x270>
      last = s+1;
    80004ef8:	def43c23          	sd	a5,-520(s0)
    80004efc:	bfc5                	j	80004eec <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004efe:	4641                	li	a2,16
    80004f00:	df843583          	ld	a1,-520(s0)
    80004f04:	158a8513          	addi	a0,s5,344
    80004f08:	ffffc097          	auipc	ra,0xffffc
    80004f0c:	f7e080e7          	jalr	-130(ra) # 80000e86 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f10:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f14:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f18:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f1c:	058ab783          	ld	a5,88(s5)
    80004f20:	e6043703          	ld	a4,-416(s0)
    80004f24:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f26:	058ab783          	ld	a5,88(s5)
    80004f2a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f2e:	85ea                	mv	a1,s10
    80004f30:	ffffd097          	auipc	ra,0xffffd
    80004f34:	c32080e7          	jalr	-974(ra) # 80001b62 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f38:	0004851b          	sext.w	a0,s1
    80004f3c:	bbe1                	j	80004d14 <exec+0x98>
    80004f3e:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f42:	e0843583          	ld	a1,-504(s0)
    80004f46:	855e                	mv	a0,s7
    80004f48:	ffffd097          	auipc	ra,0xffffd
    80004f4c:	c1a080e7          	jalr	-998(ra) # 80001b62 <proc_freepagetable>
  if(ip){
    80004f50:	da0498e3          	bnez	s1,80004d00 <exec+0x84>
  return -1;
    80004f54:	557d                	li	a0,-1
    80004f56:	bb7d                	j	80004d14 <exec+0x98>
    80004f58:	e1243423          	sd	s2,-504(s0)
    80004f5c:	b7dd                	j	80004f42 <exec+0x2c6>
    80004f5e:	e1243423          	sd	s2,-504(s0)
    80004f62:	b7c5                	j	80004f42 <exec+0x2c6>
    80004f64:	e1243423          	sd	s2,-504(s0)
    80004f68:	bfe9                	j	80004f42 <exec+0x2c6>
  sz = sz1;
    80004f6a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f6e:	4481                	li	s1,0
    80004f70:	bfc9                	j	80004f42 <exec+0x2c6>
  sz = sz1;
    80004f72:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f76:	4481                	li	s1,0
    80004f78:	b7e9                	j	80004f42 <exec+0x2c6>
  sz = sz1;
    80004f7a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004f7e:	4481                	li	s1,0
    80004f80:	b7c9                	j	80004f42 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004f82:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004f86:	2b05                	addiw	s6,s6,1
    80004f88:	0389899b          	addiw	s3,s3,56
    80004f8c:	e8045783          	lhu	a5,-384(s0)
    80004f90:	e2fb5be3          	bge	s6,a5,80004dc6 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004f94:	2981                	sext.w	s3,s3
    80004f96:	03800713          	li	a4,56
    80004f9a:	86ce                	mv	a3,s3
    80004f9c:	e1040613          	addi	a2,s0,-496
    80004fa0:	4581                	li	a1,0
    80004fa2:	8526                	mv	a0,s1
    80004fa4:	fffff097          	auipc	ra,0xfffff
    80004fa8:	a4e080e7          	jalr	-1458(ra) # 800039f2 <readi>
    80004fac:	03800793          	li	a5,56
    80004fb0:	f8f517e3          	bne	a0,a5,80004f3e <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004fb4:	e1042783          	lw	a5,-496(s0)
    80004fb8:	4705                	li	a4,1
    80004fba:	fce796e3          	bne	a5,a4,80004f86 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004fbe:	e3843603          	ld	a2,-456(s0)
    80004fc2:	e3043783          	ld	a5,-464(s0)
    80004fc6:	f8f669e3          	bltu	a2,a5,80004f58 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80004fca:	e2043783          	ld	a5,-480(s0)
    80004fce:	963e                	add	a2,a2,a5
    80004fd0:	f8f667e3          	bltu	a2,a5,80004f5e <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fd4:	85ca                	mv	a1,s2
    80004fd6:	855e                	mv	a0,s7
    80004fd8:	ffffc097          	auipc	ra,0xffffc
    80004fdc:	4ce080e7          	jalr	1230(ra) # 800014a6 <uvmalloc>
    80004fe0:	e0a43423          	sd	a0,-504(s0)
    80004fe4:	d141                	beqz	a0,80004f64 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80004fe6:	e2043d03          	ld	s10,-480(s0)
    80004fea:	df043783          	ld	a5,-528(s0)
    80004fee:	00fd77b3          	and	a5,s10,a5
    80004ff2:	fba1                	bnez	a5,80004f42 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80004ff4:	e1842d83          	lw	s11,-488(s0)
    80004ff8:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80004ffc:	f80c03e3          	beqz	s8,80004f82 <exec+0x306>
    80005000:	8a62                	mv	s4,s8
    80005002:	4901                	li	s2,0
    80005004:	b345                	j	80004da4 <exec+0x128>

0000000080005006 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005006:	7179                	addi	sp,sp,-48
    80005008:	f406                	sd	ra,40(sp)
    8000500a:	f022                	sd	s0,32(sp)
    8000500c:	ec26                	sd	s1,24(sp)
    8000500e:	e84a                	sd	s2,16(sp)
    80005010:	1800                	addi	s0,sp,48
    80005012:	892e                	mv	s2,a1
    80005014:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005016:	fdc40593          	addi	a1,s0,-36
    8000501a:	ffffe097          	auipc	ra,0xffffe
    8000501e:	ae0080e7          	jalr	-1312(ra) # 80002afa <argint>
    80005022:	04054063          	bltz	a0,80005062 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005026:	fdc42703          	lw	a4,-36(s0)
    8000502a:	47bd                	li	a5,15
    8000502c:	02e7ed63          	bltu	a5,a4,80005066 <argfd+0x60>
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	9d2080e7          	jalr	-1582(ra) # 80001a02 <myproc>
    80005038:	fdc42703          	lw	a4,-36(s0)
    8000503c:	01a70793          	addi	a5,a4,26
    80005040:	078e                	slli	a5,a5,0x3
    80005042:	953e                	add	a0,a0,a5
    80005044:	611c                	ld	a5,0(a0)
    80005046:	c395                	beqz	a5,8000506a <argfd+0x64>
    return -1;
  if(pfd)
    80005048:	00090463          	beqz	s2,80005050 <argfd+0x4a>
    *pfd = fd;
    8000504c:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005050:	4501                	li	a0,0
  if(pf)
    80005052:	c091                	beqz	s1,80005056 <argfd+0x50>
    *pf = f;
    80005054:	e09c                	sd	a5,0(s1)
}
    80005056:	70a2                	ld	ra,40(sp)
    80005058:	7402                	ld	s0,32(sp)
    8000505a:	64e2                	ld	s1,24(sp)
    8000505c:	6942                	ld	s2,16(sp)
    8000505e:	6145                	addi	sp,sp,48
    80005060:	8082                	ret
    return -1;
    80005062:	557d                	li	a0,-1
    80005064:	bfcd                	j	80005056 <argfd+0x50>
    return -1;
    80005066:	557d                	li	a0,-1
    80005068:	b7fd                	j	80005056 <argfd+0x50>
    8000506a:	557d                	li	a0,-1
    8000506c:	b7ed                	j	80005056 <argfd+0x50>

000000008000506e <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    8000506e:	1101                	addi	sp,sp,-32
    80005070:	ec06                	sd	ra,24(sp)
    80005072:	e822                	sd	s0,16(sp)
    80005074:	e426                	sd	s1,8(sp)
    80005076:	1000                	addi	s0,sp,32
    80005078:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000507a:	ffffd097          	auipc	ra,0xffffd
    8000507e:	988080e7          	jalr	-1656(ra) # 80001a02 <myproc>
    80005082:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005084:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    80005088:	4501                	li	a0,0
    8000508a:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000508c:	6398                	ld	a4,0(a5)
    8000508e:	cb19                	beqz	a4,800050a4 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005090:	2505                	addiw	a0,a0,1
    80005092:	07a1                	addi	a5,a5,8
    80005094:	fed51ce3          	bne	a0,a3,8000508c <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005098:	557d                	li	a0,-1
}
    8000509a:	60e2                	ld	ra,24(sp)
    8000509c:	6442                	ld	s0,16(sp)
    8000509e:	64a2                	ld	s1,8(sp)
    800050a0:	6105                	addi	sp,sp,32
    800050a2:	8082                	ret
      p->ofile[fd] = f;
    800050a4:	01a50793          	addi	a5,a0,26
    800050a8:	078e                	slli	a5,a5,0x3
    800050aa:	963e                	add	a2,a2,a5
    800050ac:	e204                	sd	s1,0(a2)
      return fd;
    800050ae:	b7f5                	j	8000509a <fdalloc+0x2c>

00000000800050b0 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050b0:	715d                	addi	sp,sp,-80
    800050b2:	e486                	sd	ra,72(sp)
    800050b4:	e0a2                	sd	s0,64(sp)
    800050b6:	fc26                	sd	s1,56(sp)
    800050b8:	f84a                	sd	s2,48(sp)
    800050ba:	f44e                	sd	s3,40(sp)
    800050bc:	f052                	sd	s4,32(sp)
    800050be:	ec56                	sd	s5,24(sp)
    800050c0:	0880                	addi	s0,sp,80
    800050c2:	89ae                	mv	s3,a1
    800050c4:	8ab2                	mv	s5,a2
    800050c6:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800050c8:	fb040593          	addi	a1,s0,-80
    800050cc:	fffff097          	auipc	ra,0xfffff
    800050d0:	e40080e7          	jalr	-448(ra) # 80003f0c <nameiparent>
    800050d4:	892a                	mv	s2,a0
    800050d6:	12050f63          	beqz	a0,80005214 <create+0x164>
    return 0;

  ilock(dp);
    800050da:	ffffe097          	auipc	ra,0xffffe
    800050de:	664080e7          	jalr	1636(ra) # 8000373e <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800050e2:	4601                	li	a2,0
    800050e4:	fb040593          	addi	a1,s0,-80
    800050e8:	854a                	mv	a0,s2
    800050ea:	fffff097          	auipc	ra,0xfffff
    800050ee:	b32080e7          	jalr	-1230(ra) # 80003c1c <dirlookup>
    800050f2:	84aa                	mv	s1,a0
    800050f4:	c921                	beqz	a0,80005144 <create+0x94>
    iunlockput(dp);
    800050f6:	854a                	mv	a0,s2
    800050f8:	fffff097          	auipc	ra,0xfffff
    800050fc:	8a8080e7          	jalr	-1880(ra) # 800039a0 <iunlockput>
    ilock(ip);
    80005100:	8526                	mv	a0,s1
    80005102:	ffffe097          	auipc	ra,0xffffe
    80005106:	63c080e7          	jalr	1596(ra) # 8000373e <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000510a:	2981                	sext.w	s3,s3
    8000510c:	4789                	li	a5,2
    8000510e:	02f99463          	bne	s3,a5,80005136 <create+0x86>
    80005112:	0444d783          	lhu	a5,68(s1)
    80005116:	37f9                	addiw	a5,a5,-2
    80005118:	17c2                	slli	a5,a5,0x30
    8000511a:	93c1                	srli	a5,a5,0x30
    8000511c:	4705                	li	a4,1
    8000511e:	00f76c63          	bltu	a4,a5,80005136 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005122:	8526                	mv	a0,s1
    80005124:	60a6                	ld	ra,72(sp)
    80005126:	6406                	ld	s0,64(sp)
    80005128:	74e2                	ld	s1,56(sp)
    8000512a:	7942                	ld	s2,48(sp)
    8000512c:	79a2                	ld	s3,40(sp)
    8000512e:	7a02                	ld	s4,32(sp)
    80005130:	6ae2                	ld	s5,24(sp)
    80005132:	6161                	addi	sp,sp,80
    80005134:	8082                	ret
    iunlockput(ip);
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	868080e7          	jalr	-1944(ra) # 800039a0 <iunlockput>
    return 0;
    80005140:	4481                	li	s1,0
    80005142:	b7c5                	j	80005122 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005144:	85ce                	mv	a1,s3
    80005146:	00092503          	lw	a0,0(s2)
    8000514a:	ffffe097          	auipc	ra,0xffffe
    8000514e:	45c080e7          	jalr	1116(ra) # 800035a6 <ialloc>
    80005152:	84aa                	mv	s1,a0
    80005154:	c529                	beqz	a0,8000519e <create+0xee>
  ilock(ip);
    80005156:	ffffe097          	auipc	ra,0xffffe
    8000515a:	5e8080e7          	jalr	1512(ra) # 8000373e <ilock>
  ip->major = major;
    8000515e:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005162:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    80005166:	4785                	li	a5,1
    80005168:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000516c:	8526                	mv	a0,s1
    8000516e:	ffffe097          	auipc	ra,0xffffe
    80005172:	506080e7          	jalr	1286(ra) # 80003674 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005176:	2981                	sext.w	s3,s3
    80005178:	4785                	li	a5,1
    8000517a:	02f98a63          	beq	s3,a5,800051ae <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    8000517e:	40d0                	lw	a2,4(s1)
    80005180:	fb040593          	addi	a1,s0,-80
    80005184:	854a                	mv	a0,s2
    80005186:	fffff097          	auipc	ra,0xfffff
    8000518a:	ca6080e7          	jalr	-858(ra) # 80003e2c <dirlink>
    8000518e:	06054b63          	bltz	a0,80005204 <create+0x154>
  iunlockput(dp);
    80005192:	854a                	mv	a0,s2
    80005194:	fffff097          	auipc	ra,0xfffff
    80005198:	80c080e7          	jalr	-2036(ra) # 800039a0 <iunlockput>
  return ip;
    8000519c:	b759                	j	80005122 <create+0x72>
    panic("create: ialloc");
    8000519e:	00003517          	auipc	a0,0x3
    800051a2:	6ca50513          	addi	a0,a0,1738 # 80008868 <syscall_names+0x2b8>
    800051a6:	ffffb097          	auipc	ra,0xffffb
    800051aa:	3a2080e7          	jalr	930(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051ae:	04a95783          	lhu	a5,74(s2)
    800051b2:	2785                	addiw	a5,a5,1
    800051b4:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051b8:	854a                	mv	a0,s2
    800051ba:	ffffe097          	auipc	ra,0xffffe
    800051be:	4ba080e7          	jalr	1210(ra) # 80003674 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051c2:	40d0                	lw	a2,4(s1)
    800051c4:	00003597          	auipc	a1,0x3
    800051c8:	6b458593          	addi	a1,a1,1716 # 80008878 <syscall_names+0x2c8>
    800051cc:	8526                	mv	a0,s1
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	c5e080e7          	jalr	-930(ra) # 80003e2c <dirlink>
    800051d6:	00054f63          	bltz	a0,800051f4 <create+0x144>
    800051da:	00492603          	lw	a2,4(s2)
    800051de:	00003597          	auipc	a1,0x3
    800051e2:	6a258593          	addi	a1,a1,1698 # 80008880 <syscall_names+0x2d0>
    800051e6:	8526                	mv	a0,s1
    800051e8:	fffff097          	auipc	ra,0xfffff
    800051ec:	c44080e7          	jalr	-956(ra) # 80003e2c <dirlink>
    800051f0:	f80557e3          	bgez	a0,8000517e <create+0xce>
      panic("create dots");
    800051f4:	00003517          	auipc	a0,0x3
    800051f8:	69450513          	addi	a0,a0,1684 # 80008888 <syscall_names+0x2d8>
    800051fc:	ffffb097          	auipc	ra,0xffffb
    80005200:	34c080e7          	jalr	844(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005204:	00003517          	auipc	a0,0x3
    80005208:	69450513          	addi	a0,a0,1684 # 80008898 <syscall_names+0x2e8>
    8000520c:	ffffb097          	auipc	ra,0xffffb
    80005210:	33c080e7          	jalr	828(ra) # 80000548 <panic>
    return 0;
    80005214:	84aa                	mv	s1,a0
    80005216:	b731                	j	80005122 <create+0x72>

0000000080005218 <sys_dup>:
{
    80005218:	7179                	addi	sp,sp,-48
    8000521a:	f406                	sd	ra,40(sp)
    8000521c:	f022                	sd	s0,32(sp)
    8000521e:	ec26                	sd	s1,24(sp)
    80005220:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005222:	fd840613          	addi	a2,s0,-40
    80005226:	4581                	li	a1,0
    80005228:	4501                	li	a0,0
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	ddc080e7          	jalr	-548(ra) # 80005006 <argfd>
    return -1;
    80005232:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005234:	02054363          	bltz	a0,8000525a <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005238:	fd843503          	ld	a0,-40(s0)
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	e32080e7          	jalr	-462(ra) # 8000506e <fdalloc>
    80005244:	84aa                	mv	s1,a0
    return -1;
    80005246:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005248:	00054963          	bltz	a0,8000525a <sys_dup+0x42>
  filedup(f);
    8000524c:	fd843503          	ld	a0,-40(s0)
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	32a080e7          	jalr	810(ra) # 8000457a <filedup>
  return fd;
    80005258:	87a6                	mv	a5,s1
}
    8000525a:	853e                	mv	a0,a5
    8000525c:	70a2                	ld	ra,40(sp)
    8000525e:	7402                	ld	s0,32(sp)
    80005260:	64e2                	ld	s1,24(sp)
    80005262:	6145                	addi	sp,sp,48
    80005264:	8082                	ret

0000000080005266 <sys_read>:
{
    80005266:	7179                	addi	sp,sp,-48
    80005268:	f406                	sd	ra,40(sp)
    8000526a:	f022                	sd	s0,32(sp)
    8000526c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000526e:	fe840613          	addi	a2,s0,-24
    80005272:	4581                	li	a1,0
    80005274:	4501                	li	a0,0
    80005276:	00000097          	auipc	ra,0x0
    8000527a:	d90080e7          	jalr	-624(ra) # 80005006 <argfd>
    return -1;
    8000527e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005280:	04054163          	bltz	a0,800052c2 <sys_read+0x5c>
    80005284:	fe440593          	addi	a1,s0,-28
    80005288:	4509                	li	a0,2
    8000528a:	ffffe097          	auipc	ra,0xffffe
    8000528e:	870080e7          	jalr	-1936(ra) # 80002afa <argint>
    return -1;
    80005292:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005294:	02054763          	bltz	a0,800052c2 <sys_read+0x5c>
    80005298:	fd840593          	addi	a1,s0,-40
    8000529c:	4505                	li	a0,1
    8000529e:	ffffe097          	auipc	ra,0xffffe
    800052a2:	87e080e7          	jalr	-1922(ra) # 80002b1c <argaddr>
    return -1;
    800052a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052a8:	00054d63          	bltz	a0,800052c2 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ac:	fe442603          	lw	a2,-28(s0)
    800052b0:	fd843583          	ld	a1,-40(s0)
    800052b4:	fe843503          	ld	a0,-24(s0)
    800052b8:	fffff097          	auipc	ra,0xfffff
    800052bc:	44e080e7          	jalr	1102(ra) # 80004706 <fileread>
    800052c0:	87aa                	mv	a5,a0
}
    800052c2:	853e                	mv	a0,a5
    800052c4:	70a2                	ld	ra,40(sp)
    800052c6:	7402                	ld	s0,32(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret

00000000800052cc <sys_write>:
{
    800052cc:	7179                	addi	sp,sp,-48
    800052ce:	f406                	sd	ra,40(sp)
    800052d0:	f022                	sd	s0,32(sp)
    800052d2:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d4:	fe840613          	addi	a2,s0,-24
    800052d8:	4581                	li	a1,0
    800052da:	4501                	li	a0,0
    800052dc:	00000097          	auipc	ra,0x0
    800052e0:	d2a080e7          	jalr	-726(ra) # 80005006 <argfd>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	04054163          	bltz	a0,80005328 <sys_write+0x5c>
    800052ea:	fe440593          	addi	a1,s0,-28
    800052ee:	4509                	li	a0,2
    800052f0:	ffffe097          	auipc	ra,0xffffe
    800052f4:	80a080e7          	jalr	-2038(ra) # 80002afa <argint>
    return -1;
    800052f8:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052fa:	02054763          	bltz	a0,80005328 <sys_write+0x5c>
    800052fe:	fd840593          	addi	a1,s0,-40
    80005302:	4505                	li	a0,1
    80005304:	ffffe097          	auipc	ra,0xffffe
    80005308:	818080e7          	jalr	-2024(ra) # 80002b1c <argaddr>
    return -1;
    8000530c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000530e:	00054d63          	bltz	a0,80005328 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005312:	fe442603          	lw	a2,-28(s0)
    80005316:	fd843583          	ld	a1,-40(s0)
    8000531a:	fe843503          	ld	a0,-24(s0)
    8000531e:	fffff097          	auipc	ra,0xfffff
    80005322:	4aa080e7          	jalr	1194(ra) # 800047c8 <filewrite>
    80005326:	87aa                	mv	a5,a0
}
    80005328:	853e                	mv	a0,a5
    8000532a:	70a2                	ld	ra,40(sp)
    8000532c:	7402                	ld	s0,32(sp)
    8000532e:	6145                	addi	sp,sp,48
    80005330:	8082                	ret

0000000080005332 <sys_close>:
{
    80005332:	1101                	addi	sp,sp,-32
    80005334:	ec06                	sd	ra,24(sp)
    80005336:	e822                	sd	s0,16(sp)
    80005338:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    8000533a:	fe040613          	addi	a2,s0,-32
    8000533e:	fec40593          	addi	a1,s0,-20
    80005342:	4501                	li	a0,0
    80005344:	00000097          	auipc	ra,0x0
    80005348:	cc2080e7          	jalr	-830(ra) # 80005006 <argfd>
    return -1;
    8000534c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000534e:	02054463          	bltz	a0,80005376 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005352:	ffffc097          	auipc	ra,0xffffc
    80005356:	6b0080e7          	jalr	1712(ra) # 80001a02 <myproc>
    8000535a:	fec42783          	lw	a5,-20(s0)
    8000535e:	07e9                	addi	a5,a5,26
    80005360:	078e                	slli	a5,a5,0x3
    80005362:	97aa                	add	a5,a5,a0
    80005364:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005368:	fe043503          	ld	a0,-32(s0)
    8000536c:	fffff097          	auipc	ra,0xfffff
    80005370:	260080e7          	jalr	608(ra) # 800045cc <fileclose>
  return 0;
    80005374:	4781                	li	a5,0
}
    80005376:	853e                	mv	a0,a5
    80005378:	60e2                	ld	ra,24(sp)
    8000537a:	6442                	ld	s0,16(sp)
    8000537c:	6105                	addi	sp,sp,32
    8000537e:	8082                	ret

0000000080005380 <sys_fstat>:
{
    80005380:	1101                	addi	sp,sp,-32
    80005382:	ec06                	sd	ra,24(sp)
    80005384:	e822                	sd	s0,16(sp)
    80005386:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005388:	fe840613          	addi	a2,s0,-24
    8000538c:	4581                	li	a1,0
    8000538e:	4501                	li	a0,0
    80005390:	00000097          	auipc	ra,0x0
    80005394:	c76080e7          	jalr	-906(ra) # 80005006 <argfd>
    return -1;
    80005398:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000539a:	02054563          	bltz	a0,800053c4 <sys_fstat+0x44>
    8000539e:	fe040593          	addi	a1,s0,-32
    800053a2:	4505                	li	a0,1
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	778080e7          	jalr	1912(ra) # 80002b1c <argaddr>
    return -1;
    800053ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ae:	00054b63          	bltz	a0,800053c4 <sys_fstat+0x44>
  return filestat(f, st);
    800053b2:	fe043583          	ld	a1,-32(s0)
    800053b6:	fe843503          	ld	a0,-24(s0)
    800053ba:	fffff097          	auipc	ra,0xfffff
    800053be:	2da080e7          	jalr	730(ra) # 80004694 <filestat>
    800053c2:	87aa                	mv	a5,a0
}
    800053c4:	853e                	mv	a0,a5
    800053c6:	60e2                	ld	ra,24(sp)
    800053c8:	6442                	ld	s0,16(sp)
    800053ca:	6105                	addi	sp,sp,32
    800053cc:	8082                	ret

00000000800053ce <sys_link>:
{
    800053ce:	7169                	addi	sp,sp,-304
    800053d0:	f606                	sd	ra,296(sp)
    800053d2:	f222                	sd	s0,288(sp)
    800053d4:	ee26                	sd	s1,280(sp)
    800053d6:	ea4a                	sd	s2,272(sp)
    800053d8:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053da:	08000613          	li	a2,128
    800053de:	ed040593          	addi	a1,s0,-304
    800053e2:	4501                	li	a0,0
    800053e4:	ffffd097          	auipc	ra,0xffffd
    800053e8:	75a080e7          	jalr	1882(ra) # 80002b3e <argstr>
    return -1;
    800053ec:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800053ee:	10054e63          	bltz	a0,8000550a <sys_link+0x13c>
    800053f2:	08000613          	li	a2,128
    800053f6:	f5040593          	addi	a1,s0,-176
    800053fa:	4505                	li	a0,1
    800053fc:	ffffd097          	auipc	ra,0xffffd
    80005400:	742080e7          	jalr	1858(ra) # 80002b3e <argstr>
    return -1;
    80005404:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005406:	10054263          	bltz	a0,8000550a <sys_link+0x13c>
  begin_op();
    8000540a:	fffff097          	auipc	ra,0xfffff
    8000540e:	cf0080e7          	jalr	-784(ra) # 800040fa <begin_op>
  if((ip = namei(old)) == 0){
    80005412:	ed040513          	addi	a0,s0,-304
    80005416:	fffff097          	auipc	ra,0xfffff
    8000541a:	ad8080e7          	jalr	-1320(ra) # 80003eee <namei>
    8000541e:	84aa                	mv	s1,a0
    80005420:	c551                	beqz	a0,800054ac <sys_link+0xde>
  ilock(ip);
    80005422:	ffffe097          	auipc	ra,0xffffe
    80005426:	31c080e7          	jalr	796(ra) # 8000373e <ilock>
  if(ip->type == T_DIR){
    8000542a:	04449703          	lh	a4,68(s1)
    8000542e:	4785                	li	a5,1
    80005430:	08f70463          	beq	a4,a5,800054b8 <sys_link+0xea>
  ip->nlink++;
    80005434:	04a4d783          	lhu	a5,74(s1)
    80005438:	2785                	addiw	a5,a5,1
    8000543a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000543e:	8526                	mv	a0,s1
    80005440:	ffffe097          	auipc	ra,0xffffe
    80005444:	234080e7          	jalr	564(ra) # 80003674 <iupdate>
  iunlock(ip);
    80005448:	8526                	mv	a0,s1
    8000544a:	ffffe097          	auipc	ra,0xffffe
    8000544e:	3b6080e7          	jalr	950(ra) # 80003800 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005452:	fd040593          	addi	a1,s0,-48
    80005456:	f5040513          	addi	a0,s0,-176
    8000545a:	fffff097          	auipc	ra,0xfffff
    8000545e:	ab2080e7          	jalr	-1358(ra) # 80003f0c <nameiparent>
    80005462:	892a                	mv	s2,a0
    80005464:	c935                	beqz	a0,800054d8 <sys_link+0x10a>
  ilock(dp);
    80005466:	ffffe097          	auipc	ra,0xffffe
    8000546a:	2d8080e7          	jalr	728(ra) # 8000373e <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    8000546e:	00092703          	lw	a4,0(s2)
    80005472:	409c                	lw	a5,0(s1)
    80005474:	04f71d63          	bne	a4,a5,800054ce <sys_link+0x100>
    80005478:	40d0                	lw	a2,4(s1)
    8000547a:	fd040593          	addi	a1,s0,-48
    8000547e:	854a                	mv	a0,s2
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	9ac080e7          	jalr	-1620(ra) # 80003e2c <dirlink>
    80005488:	04054363          	bltz	a0,800054ce <sys_link+0x100>
  iunlockput(dp);
    8000548c:	854a                	mv	a0,s2
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	512080e7          	jalr	1298(ra) # 800039a0 <iunlockput>
  iput(ip);
    80005496:	8526                	mv	a0,s1
    80005498:	ffffe097          	auipc	ra,0xffffe
    8000549c:	460080e7          	jalr	1120(ra) # 800038f8 <iput>
  end_op();
    800054a0:	fffff097          	auipc	ra,0xfffff
    800054a4:	cda080e7          	jalr	-806(ra) # 8000417a <end_op>
  return 0;
    800054a8:	4781                	li	a5,0
    800054aa:	a085                	j	8000550a <sys_link+0x13c>
    end_op();
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	cce080e7          	jalr	-818(ra) # 8000417a <end_op>
    return -1;
    800054b4:	57fd                	li	a5,-1
    800054b6:	a891                	j	8000550a <sys_link+0x13c>
    iunlockput(ip);
    800054b8:	8526                	mv	a0,s1
    800054ba:	ffffe097          	auipc	ra,0xffffe
    800054be:	4e6080e7          	jalr	1254(ra) # 800039a0 <iunlockput>
    end_op();
    800054c2:	fffff097          	auipc	ra,0xfffff
    800054c6:	cb8080e7          	jalr	-840(ra) # 8000417a <end_op>
    return -1;
    800054ca:	57fd                	li	a5,-1
    800054cc:	a83d                	j	8000550a <sys_link+0x13c>
    iunlockput(dp);
    800054ce:	854a                	mv	a0,s2
    800054d0:	ffffe097          	auipc	ra,0xffffe
    800054d4:	4d0080e7          	jalr	1232(ra) # 800039a0 <iunlockput>
  ilock(ip);
    800054d8:	8526                	mv	a0,s1
    800054da:	ffffe097          	auipc	ra,0xffffe
    800054de:	264080e7          	jalr	612(ra) # 8000373e <ilock>
  ip->nlink--;
    800054e2:	04a4d783          	lhu	a5,74(s1)
    800054e6:	37fd                	addiw	a5,a5,-1
    800054e8:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800054ec:	8526                	mv	a0,s1
    800054ee:	ffffe097          	auipc	ra,0xffffe
    800054f2:	186080e7          	jalr	390(ra) # 80003674 <iupdate>
  iunlockput(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	4a8080e7          	jalr	1192(ra) # 800039a0 <iunlockput>
  end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	c7a080e7          	jalr	-902(ra) # 8000417a <end_op>
  return -1;
    80005508:	57fd                	li	a5,-1
}
    8000550a:	853e                	mv	a0,a5
    8000550c:	70b2                	ld	ra,296(sp)
    8000550e:	7412                	ld	s0,288(sp)
    80005510:	64f2                	ld	s1,280(sp)
    80005512:	6952                	ld	s2,272(sp)
    80005514:	6155                	addi	sp,sp,304
    80005516:	8082                	ret

0000000080005518 <sys_unlink>:
{
    80005518:	7151                	addi	sp,sp,-240
    8000551a:	f586                	sd	ra,232(sp)
    8000551c:	f1a2                	sd	s0,224(sp)
    8000551e:	eda6                	sd	s1,216(sp)
    80005520:	e9ca                	sd	s2,208(sp)
    80005522:	e5ce                	sd	s3,200(sp)
    80005524:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005526:	08000613          	li	a2,128
    8000552a:	f3040593          	addi	a1,s0,-208
    8000552e:	4501                	li	a0,0
    80005530:	ffffd097          	auipc	ra,0xffffd
    80005534:	60e080e7          	jalr	1550(ra) # 80002b3e <argstr>
    80005538:	18054163          	bltz	a0,800056ba <sys_unlink+0x1a2>
  begin_op();
    8000553c:	fffff097          	auipc	ra,0xfffff
    80005540:	bbe080e7          	jalr	-1090(ra) # 800040fa <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005544:	fb040593          	addi	a1,s0,-80
    80005548:	f3040513          	addi	a0,s0,-208
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	9c0080e7          	jalr	-1600(ra) # 80003f0c <nameiparent>
    80005554:	84aa                	mv	s1,a0
    80005556:	c979                	beqz	a0,8000562c <sys_unlink+0x114>
  ilock(dp);
    80005558:	ffffe097          	auipc	ra,0xffffe
    8000555c:	1e6080e7          	jalr	486(ra) # 8000373e <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005560:	00003597          	auipc	a1,0x3
    80005564:	31858593          	addi	a1,a1,792 # 80008878 <syscall_names+0x2c8>
    80005568:	fb040513          	addi	a0,s0,-80
    8000556c:	ffffe097          	auipc	ra,0xffffe
    80005570:	696080e7          	jalr	1686(ra) # 80003c02 <namecmp>
    80005574:	14050a63          	beqz	a0,800056c8 <sys_unlink+0x1b0>
    80005578:	00003597          	auipc	a1,0x3
    8000557c:	30858593          	addi	a1,a1,776 # 80008880 <syscall_names+0x2d0>
    80005580:	fb040513          	addi	a0,s0,-80
    80005584:	ffffe097          	auipc	ra,0xffffe
    80005588:	67e080e7          	jalr	1662(ra) # 80003c02 <namecmp>
    8000558c:	12050e63          	beqz	a0,800056c8 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005590:	f2c40613          	addi	a2,s0,-212
    80005594:	fb040593          	addi	a1,s0,-80
    80005598:	8526                	mv	a0,s1
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	682080e7          	jalr	1666(ra) # 80003c1c <dirlookup>
    800055a2:	892a                	mv	s2,a0
    800055a4:	12050263          	beqz	a0,800056c8 <sys_unlink+0x1b0>
  ilock(ip);
    800055a8:	ffffe097          	auipc	ra,0xffffe
    800055ac:	196080e7          	jalr	406(ra) # 8000373e <ilock>
  if(ip->nlink < 1)
    800055b0:	04a91783          	lh	a5,74(s2)
    800055b4:	08f05263          	blez	a5,80005638 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055b8:	04491703          	lh	a4,68(s2)
    800055bc:	4785                	li	a5,1
    800055be:	08f70563          	beq	a4,a5,80005648 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800055c2:	4641                	li	a2,16
    800055c4:	4581                	li	a1,0
    800055c6:	fc040513          	addi	a0,s0,-64
    800055ca:	ffffb097          	auipc	ra,0xffffb
    800055ce:	766080e7          	jalr	1894(ra) # 80000d30 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800055d2:	4741                	li	a4,16
    800055d4:	f2c42683          	lw	a3,-212(s0)
    800055d8:	fc040613          	addi	a2,s0,-64
    800055dc:	4581                	li	a1,0
    800055de:	8526                	mv	a0,s1
    800055e0:	ffffe097          	auipc	ra,0xffffe
    800055e4:	508080e7          	jalr	1288(ra) # 80003ae8 <writei>
    800055e8:	47c1                	li	a5,16
    800055ea:	0af51563          	bne	a0,a5,80005694 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800055ee:	04491703          	lh	a4,68(s2)
    800055f2:	4785                	li	a5,1
    800055f4:	0af70863          	beq	a4,a5,800056a4 <sys_unlink+0x18c>
  iunlockput(dp);
    800055f8:	8526                	mv	a0,s1
    800055fa:	ffffe097          	auipc	ra,0xffffe
    800055fe:	3a6080e7          	jalr	934(ra) # 800039a0 <iunlockput>
  ip->nlink--;
    80005602:	04a95783          	lhu	a5,74(s2)
    80005606:	37fd                	addiw	a5,a5,-1
    80005608:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000560c:	854a                	mv	a0,s2
    8000560e:	ffffe097          	auipc	ra,0xffffe
    80005612:	066080e7          	jalr	102(ra) # 80003674 <iupdate>
  iunlockput(ip);
    80005616:	854a                	mv	a0,s2
    80005618:	ffffe097          	auipc	ra,0xffffe
    8000561c:	388080e7          	jalr	904(ra) # 800039a0 <iunlockput>
  end_op();
    80005620:	fffff097          	auipc	ra,0xfffff
    80005624:	b5a080e7          	jalr	-1190(ra) # 8000417a <end_op>
  return 0;
    80005628:	4501                	li	a0,0
    8000562a:	a84d                	j	800056dc <sys_unlink+0x1c4>
    end_op();
    8000562c:	fffff097          	auipc	ra,0xfffff
    80005630:	b4e080e7          	jalr	-1202(ra) # 8000417a <end_op>
    return -1;
    80005634:	557d                	li	a0,-1
    80005636:	a05d                	j	800056dc <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005638:	00003517          	auipc	a0,0x3
    8000563c:	27050513          	addi	a0,a0,624 # 800088a8 <syscall_names+0x2f8>
    80005640:	ffffb097          	auipc	ra,0xffffb
    80005644:	f08080e7          	jalr	-248(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005648:	04c92703          	lw	a4,76(s2)
    8000564c:	02000793          	li	a5,32
    80005650:	f6e7f9e3          	bgeu	a5,a4,800055c2 <sys_unlink+0xaa>
    80005654:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005658:	4741                	li	a4,16
    8000565a:	86ce                	mv	a3,s3
    8000565c:	f1840613          	addi	a2,s0,-232
    80005660:	4581                	li	a1,0
    80005662:	854a                	mv	a0,s2
    80005664:	ffffe097          	auipc	ra,0xffffe
    80005668:	38e080e7          	jalr	910(ra) # 800039f2 <readi>
    8000566c:	47c1                	li	a5,16
    8000566e:	00f51b63          	bne	a0,a5,80005684 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005672:	f1845783          	lhu	a5,-232(s0)
    80005676:	e7a1                	bnez	a5,800056be <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005678:	29c1                	addiw	s3,s3,16
    8000567a:	04c92783          	lw	a5,76(s2)
    8000567e:	fcf9ede3          	bltu	s3,a5,80005658 <sys_unlink+0x140>
    80005682:	b781                	j	800055c2 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005684:	00003517          	auipc	a0,0x3
    80005688:	23c50513          	addi	a0,a0,572 # 800088c0 <syscall_names+0x310>
    8000568c:	ffffb097          	auipc	ra,0xffffb
    80005690:	ebc080e7          	jalr	-324(ra) # 80000548 <panic>
    panic("unlink: writei");
    80005694:	00003517          	auipc	a0,0x3
    80005698:	24450513          	addi	a0,a0,580 # 800088d8 <syscall_names+0x328>
    8000569c:	ffffb097          	auipc	ra,0xffffb
    800056a0:	eac080e7          	jalr	-340(ra) # 80000548 <panic>
    dp->nlink--;
    800056a4:	04a4d783          	lhu	a5,74(s1)
    800056a8:	37fd                	addiw	a5,a5,-1
    800056aa:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ae:	8526                	mv	a0,s1
    800056b0:	ffffe097          	auipc	ra,0xffffe
    800056b4:	fc4080e7          	jalr	-60(ra) # 80003674 <iupdate>
    800056b8:	b781                	j	800055f8 <sys_unlink+0xe0>
    return -1;
    800056ba:	557d                	li	a0,-1
    800056bc:	a005                	j	800056dc <sys_unlink+0x1c4>
    iunlockput(ip);
    800056be:	854a                	mv	a0,s2
    800056c0:	ffffe097          	auipc	ra,0xffffe
    800056c4:	2e0080e7          	jalr	736(ra) # 800039a0 <iunlockput>
  iunlockput(dp);
    800056c8:	8526                	mv	a0,s1
    800056ca:	ffffe097          	auipc	ra,0xffffe
    800056ce:	2d6080e7          	jalr	726(ra) # 800039a0 <iunlockput>
  end_op();
    800056d2:	fffff097          	auipc	ra,0xfffff
    800056d6:	aa8080e7          	jalr	-1368(ra) # 8000417a <end_op>
  return -1;
    800056da:	557d                	li	a0,-1
}
    800056dc:	70ae                	ld	ra,232(sp)
    800056de:	740e                	ld	s0,224(sp)
    800056e0:	64ee                	ld	s1,216(sp)
    800056e2:	694e                	ld	s2,208(sp)
    800056e4:	69ae                	ld	s3,200(sp)
    800056e6:	616d                	addi	sp,sp,240
    800056e8:	8082                	ret

00000000800056ea <sys_open>:

uint64
sys_open(void)
{
    800056ea:	7131                	addi	sp,sp,-192
    800056ec:	fd06                	sd	ra,184(sp)
    800056ee:	f922                	sd	s0,176(sp)
    800056f0:	f526                	sd	s1,168(sp)
    800056f2:	f14a                	sd	s2,160(sp)
    800056f4:	ed4e                	sd	s3,152(sp)
    800056f6:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    800056f8:	08000613          	li	a2,128
    800056fc:	f5040593          	addi	a1,s0,-176
    80005700:	4501                	li	a0,0
    80005702:	ffffd097          	auipc	ra,0xffffd
    80005706:	43c080e7          	jalr	1084(ra) # 80002b3e <argstr>
    return -1;
    8000570a:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000570c:	0c054163          	bltz	a0,800057ce <sys_open+0xe4>
    80005710:	f4c40593          	addi	a1,s0,-180
    80005714:	4505                	li	a0,1
    80005716:	ffffd097          	auipc	ra,0xffffd
    8000571a:	3e4080e7          	jalr	996(ra) # 80002afa <argint>
    8000571e:	0a054863          	bltz	a0,800057ce <sys_open+0xe4>

  begin_op();
    80005722:	fffff097          	auipc	ra,0xfffff
    80005726:	9d8080e7          	jalr	-1576(ra) # 800040fa <begin_op>

  if(omode & O_CREATE){
    8000572a:	f4c42783          	lw	a5,-180(s0)
    8000572e:	2007f793          	andi	a5,a5,512
    80005732:	cbdd                	beqz	a5,800057e8 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005734:	4681                	li	a3,0
    80005736:	4601                	li	a2,0
    80005738:	4589                	li	a1,2
    8000573a:	f5040513          	addi	a0,s0,-176
    8000573e:	00000097          	auipc	ra,0x0
    80005742:	972080e7          	jalr	-1678(ra) # 800050b0 <create>
    80005746:	892a                	mv	s2,a0
    if(ip == 0){
    80005748:	c959                	beqz	a0,800057de <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000574a:	04491703          	lh	a4,68(s2)
    8000574e:	478d                	li	a5,3
    80005750:	00f71763          	bne	a4,a5,8000575e <sys_open+0x74>
    80005754:	04695703          	lhu	a4,70(s2)
    80005758:	47a5                	li	a5,9
    8000575a:	0ce7ec63          	bltu	a5,a4,80005832 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000575e:	fffff097          	auipc	ra,0xfffff
    80005762:	db2080e7          	jalr	-590(ra) # 80004510 <filealloc>
    80005766:	89aa                	mv	s3,a0
    80005768:	10050263          	beqz	a0,8000586c <sys_open+0x182>
    8000576c:	00000097          	auipc	ra,0x0
    80005770:	902080e7          	jalr	-1790(ra) # 8000506e <fdalloc>
    80005774:	84aa                	mv	s1,a0
    80005776:	0e054663          	bltz	a0,80005862 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000577a:	04491703          	lh	a4,68(s2)
    8000577e:	478d                	li	a5,3
    80005780:	0cf70463          	beq	a4,a5,80005848 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005784:	4789                	li	a5,2
    80005786:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000578a:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    8000578e:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005792:	f4c42783          	lw	a5,-180(s0)
    80005796:	0017c713          	xori	a4,a5,1
    8000579a:	8b05                	andi	a4,a4,1
    8000579c:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057a0:	0037f713          	andi	a4,a5,3
    800057a4:	00e03733          	snez	a4,a4
    800057a8:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ac:	4007f793          	andi	a5,a5,1024
    800057b0:	c791                	beqz	a5,800057bc <sys_open+0xd2>
    800057b2:	04491703          	lh	a4,68(s2)
    800057b6:	4789                	li	a5,2
    800057b8:	08f70f63          	beq	a4,a5,80005856 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057bc:	854a                	mv	a0,s2
    800057be:	ffffe097          	auipc	ra,0xffffe
    800057c2:	042080e7          	jalr	66(ra) # 80003800 <iunlock>
  end_op();
    800057c6:	fffff097          	auipc	ra,0xfffff
    800057ca:	9b4080e7          	jalr	-1612(ra) # 8000417a <end_op>

  return fd;
}
    800057ce:	8526                	mv	a0,s1
    800057d0:	70ea                	ld	ra,184(sp)
    800057d2:	744a                	ld	s0,176(sp)
    800057d4:	74aa                	ld	s1,168(sp)
    800057d6:	790a                	ld	s2,160(sp)
    800057d8:	69ea                	ld	s3,152(sp)
    800057da:	6129                	addi	sp,sp,192
    800057dc:	8082                	ret
      end_op();
    800057de:	fffff097          	auipc	ra,0xfffff
    800057e2:	99c080e7          	jalr	-1636(ra) # 8000417a <end_op>
      return -1;
    800057e6:	b7e5                	j	800057ce <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800057e8:	f5040513          	addi	a0,s0,-176
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	702080e7          	jalr	1794(ra) # 80003eee <namei>
    800057f4:	892a                	mv	s2,a0
    800057f6:	c905                	beqz	a0,80005826 <sys_open+0x13c>
    ilock(ip);
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	f46080e7          	jalr	-186(ra) # 8000373e <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005800:	04491703          	lh	a4,68(s2)
    80005804:	4785                	li	a5,1
    80005806:	f4f712e3          	bne	a4,a5,8000574a <sys_open+0x60>
    8000580a:	f4c42783          	lw	a5,-180(s0)
    8000580e:	dba1                	beqz	a5,8000575e <sys_open+0x74>
      iunlockput(ip);
    80005810:	854a                	mv	a0,s2
    80005812:	ffffe097          	auipc	ra,0xffffe
    80005816:	18e080e7          	jalr	398(ra) # 800039a0 <iunlockput>
      end_op();
    8000581a:	fffff097          	auipc	ra,0xfffff
    8000581e:	960080e7          	jalr	-1696(ra) # 8000417a <end_op>
      return -1;
    80005822:	54fd                	li	s1,-1
    80005824:	b76d                	j	800057ce <sys_open+0xe4>
      end_op();
    80005826:	fffff097          	auipc	ra,0xfffff
    8000582a:	954080e7          	jalr	-1708(ra) # 8000417a <end_op>
      return -1;
    8000582e:	54fd                	li	s1,-1
    80005830:	bf79                	j	800057ce <sys_open+0xe4>
    iunlockput(ip);
    80005832:	854a                	mv	a0,s2
    80005834:	ffffe097          	auipc	ra,0xffffe
    80005838:	16c080e7          	jalr	364(ra) # 800039a0 <iunlockput>
    end_op();
    8000583c:	fffff097          	auipc	ra,0xfffff
    80005840:	93e080e7          	jalr	-1730(ra) # 8000417a <end_op>
    return -1;
    80005844:	54fd                	li	s1,-1
    80005846:	b761                	j	800057ce <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005848:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000584c:	04691783          	lh	a5,70(s2)
    80005850:	02f99223          	sh	a5,36(s3)
    80005854:	bf2d                	j	8000578e <sys_open+0xa4>
    itrunc(ip);
    80005856:	854a                	mv	a0,s2
    80005858:	ffffe097          	auipc	ra,0xffffe
    8000585c:	ff4080e7          	jalr	-12(ra) # 8000384c <itrunc>
    80005860:	bfb1                	j	800057bc <sys_open+0xd2>
      fileclose(f);
    80005862:	854e                	mv	a0,s3
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	d68080e7          	jalr	-664(ra) # 800045cc <fileclose>
    iunlockput(ip);
    8000586c:	854a                	mv	a0,s2
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	132080e7          	jalr	306(ra) # 800039a0 <iunlockput>
    end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	904080e7          	jalr	-1788(ra) # 8000417a <end_op>
    return -1;
    8000587e:	54fd                	li	s1,-1
    80005880:	b7b9                	j	800057ce <sys_open+0xe4>

0000000080005882 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005882:	7175                	addi	sp,sp,-144
    80005884:	e506                	sd	ra,136(sp)
    80005886:	e122                	sd	s0,128(sp)
    80005888:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	870080e7          	jalr	-1936(ra) # 800040fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005892:	08000613          	li	a2,128
    80005896:	f7040593          	addi	a1,s0,-144
    8000589a:	4501                	li	a0,0
    8000589c:	ffffd097          	auipc	ra,0xffffd
    800058a0:	2a2080e7          	jalr	674(ra) # 80002b3e <argstr>
    800058a4:	02054963          	bltz	a0,800058d6 <sys_mkdir+0x54>
    800058a8:	4681                	li	a3,0
    800058aa:	4601                	li	a2,0
    800058ac:	4585                	li	a1,1
    800058ae:	f7040513          	addi	a0,s0,-144
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	7fe080e7          	jalr	2046(ra) # 800050b0 <create>
    800058ba:	cd11                	beqz	a0,800058d6 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058bc:	ffffe097          	auipc	ra,0xffffe
    800058c0:	0e4080e7          	jalr	228(ra) # 800039a0 <iunlockput>
  end_op();
    800058c4:	fffff097          	auipc	ra,0xfffff
    800058c8:	8b6080e7          	jalr	-1866(ra) # 8000417a <end_op>
  return 0;
    800058cc:	4501                	li	a0,0
}
    800058ce:	60aa                	ld	ra,136(sp)
    800058d0:	640a                	ld	s0,128(sp)
    800058d2:	6149                	addi	sp,sp,144
    800058d4:	8082                	ret
    end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	8a4080e7          	jalr	-1884(ra) # 8000417a <end_op>
    return -1;
    800058de:	557d                	li	a0,-1
    800058e0:	b7fd                	j	800058ce <sys_mkdir+0x4c>

00000000800058e2 <sys_mknod>:

uint64
sys_mknod(void)
{
    800058e2:	7135                	addi	sp,sp,-160
    800058e4:	ed06                	sd	ra,152(sp)
    800058e6:	e922                	sd	s0,144(sp)
    800058e8:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800058ea:	fffff097          	auipc	ra,0xfffff
    800058ee:	810080e7          	jalr	-2032(ra) # 800040fa <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800058f2:	08000613          	li	a2,128
    800058f6:	f7040593          	addi	a1,s0,-144
    800058fa:	4501                	li	a0,0
    800058fc:	ffffd097          	auipc	ra,0xffffd
    80005900:	242080e7          	jalr	578(ra) # 80002b3e <argstr>
    80005904:	04054a63          	bltz	a0,80005958 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005908:	f6c40593          	addi	a1,s0,-148
    8000590c:	4505                	li	a0,1
    8000590e:	ffffd097          	auipc	ra,0xffffd
    80005912:	1ec080e7          	jalr	492(ra) # 80002afa <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005916:	04054163          	bltz	a0,80005958 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    8000591a:	f6840593          	addi	a1,s0,-152
    8000591e:	4509                	li	a0,2
    80005920:	ffffd097          	auipc	ra,0xffffd
    80005924:	1da080e7          	jalr	474(ra) # 80002afa <argint>
     argint(1, &major) < 0 ||
    80005928:	02054863          	bltz	a0,80005958 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000592c:	f6841683          	lh	a3,-152(s0)
    80005930:	f6c41603          	lh	a2,-148(s0)
    80005934:	458d                	li	a1,3
    80005936:	f7040513          	addi	a0,s0,-144
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	776080e7          	jalr	1910(ra) # 800050b0 <create>
     argint(2, &minor) < 0 ||
    80005942:	c919                	beqz	a0,80005958 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	05c080e7          	jalr	92(ra) # 800039a0 <iunlockput>
  end_op();
    8000594c:	fffff097          	auipc	ra,0xfffff
    80005950:	82e080e7          	jalr	-2002(ra) # 8000417a <end_op>
  return 0;
    80005954:	4501                	li	a0,0
    80005956:	a031                	j	80005962 <sys_mknod+0x80>
    end_op();
    80005958:	fffff097          	auipc	ra,0xfffff
    8000595c:	822080e7          	jalr	-2014(ra) # 8000417a <end_op>
    return -1;
    80005960:	557d                	li	a0,-1
}
    80005962:	60ea                	ld	ra,152(sp)
    80005964:	644a                	ld	s0,144(sp)
    80005966:	610d                	addi	sp,sp,160
    80005968:	8082                	ret

000000008000596a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000596a:	7135                	addi	sp,sp,-160
    8000596c:	ed06                	sd	ra,152(sp)
    8000596e:	e922                	sd	s0,144(sp)
    80005970:	e526                	sd	s1,136(sp)
    80005972:	e14a                	sd	s2,128(sp)
    80005974:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005976:	ffffc097          	auipc	ra,0xffffc
    8000597a:	08c080e7          	jalr	140(ra) # 80001a02 <myproc>
    8000597e:	892a                	mv	s2,a0
  
  begin_op();
    80005980:	ffffe097          	auipc	ra,0xffffe
    80005984:	77a080e7          	jalr	1914(ra) # 800040fa <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005988:	08000613          	li	a2,128
    8000598c:	f6040593          	addi	a1,s0,-160
    80005990:	4501                	li	a0,0
    80005992:	ffffd097          	auipc	ra,0xffffd
    80005996:	1ac080e7          	jalr	428(ra) # 80002b3e <argstr>
    8000599a:	04054b63          	bltz	a0,800059f0 <sys_chdir+0x86>
    8000599e:	f6040513          	addi	a0,s0,-160
    800059a2:	ffffe097          	auipc	ra,0xffffe
    800059a6:	54c080e7          	jalr	1356(ra) # 80003eee <namei>
    800059aa:	84aa                	mv	s1,a0
    800059ac:	c131                	beqz	a0,800059f0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	d90080e7          	jalr	-624(ra) # 8000373e <ilock>
  if(ip->type != T_DIR){
    800059b6:	04449703          	lh	a4,68(s1)
    800059ba:	4785                	li	a5,1
    800059bc:	04f71063          	bne	a4,a5,800059fc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059c0:	8526                	mv	a0,s1
    800059c2:	ffffe097          	auipc	ra,0xffffe
    800059c6:	e3e080e7          	jalr	-450(ra) # 80003800 <iunlock>
  iput(p->cwd);
    800059ca:	15093503          	ld	a0,336(s2)
    800059ce:	ffffe097          	auipc	ra,0xffffe
    800059d2:	f2a080e7          	jalr	-214(ra) # 800038f8 <iput>
  end_op();
    800059d6:	ffffe097          	auipc	ra,0xffffe
    800059da:	7a4080e7          	jalr	1956(ra) # 8000417a <end_op>
  p->cwd = ip;
    800059de:	14993823          	sd	s1,336(s2)
  return 0;
    800059e2:	4501                	li	a0,0
}
    800059e4:	60ea                	ld	ra,152(sp)
    800059e6:	644a                	ld	s0,144(sp)
    800059e8:	64aa                	ld	s1,136(sp)
    800059ea:	690a                	ld	s2,128(sp)
    800059ec:	610d                	addi	sp,sp,160
    800059ee:	8082                	ret
    end_op();
    800059f0:	ffffe097          	auipc	ra,0xffffe
    800059f4:	78a080e7          	jalr	1930(ra) # 8000417a <end_op>
    return -1;
    800059f8:	557d                	li	a0,-1
    800059fa:	b7ed                	j	800059e4 <sys_chdir+0x7a>
    iunlockput(ip);
    800059fc:	8526                	mv	a0,s1
    800059fe:	ffffe097          	auipc	ra,0xffffe
    80005a02:	fa2080e7          	jalr	-94(ra) # 800039a0 <iunlockput>
    end_op();
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	774080e7          	jalr	1908(ra) # 8000417a <end_op>
    return -1;
    80005a0e:	557d                	li	a0,-1
    80005a10:	bfd1                	j	800059e4 <sys_chdir+0x7a>

0000000080005a12 <sys_exec>:

uint64
sys_exec(void)
{
    80005a12:	7145                	addi	sp,sp,-464
    80005a14:	e786                	sd	ra,456(sp)
    80005a16:	e3a2                	sd	s0,448(sp)
    80005a18:	ff26                	sd	s1,440(sp)
    80005a1a:	fb4a                	sd	s2,432(sp)
    80005a1c:	f74e                	sd	s3,424(sp)
    80005a1e:	f352                	sd	s4,416(sp)
    80005a20:	ef56                	sd	s5,408(sp)
    80005a22:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a24:	08000613          	li	a2,128
    80005a28:	f4040593          	addi	a1,s0,-192
    80005a2c:	4501                	li	a0,0
    80005a2e:	ffffd097          	auipc	ra,0xffffd
    80005a32:	110080e7          	jalr	272(ra) # 80002b3e <argstr>
    return -1;
    80005a36:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a38:	0c054a63          	bltz	a0,80005b0c <sys_exec+0xfa>
    80005a3c:	e3840593          	addi	a1,s0,-456
    80005a40:	4505                	li	a0,1
    80005a42:	ffffd097          	auipc	ra,0xffffd
    80005a46:	0da080e7          	jalr	218(ra) # 80002b1c <argaddr>
    80005a4a:	0c054163          	bltz	a0,80005b0c <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a4e:	10000613          	li	a2,256
    80005a52:	4581                	li	a1,0
    80005a54:	e4040513          	addi	a0,s0,-448
    80005a58:	ffffb097          	auipc	ra,0xffffb
    80005a5c:	2d8080e7          	jalr	728(ra) # 80000d30 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a60:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a64:	89a6                	mv	s3,s1
    80005a66:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a68:	02000a13          	li	s4,32
    80005a6c:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005a70:	00391513          	slli	a0,s2,0x3
    80005a74:	e3040593          	addi	a1,s0,-464
    80005a78:	e3843783          	ld	a5,-456(s0)
    80005a7c:	953e                	add	a0,a0,a5
    80005a7e:	ffffd097          	auipc	ra,0xffffd
    80005a82:	fe2080e7          	jalr	-30(ra) # 80002a60 <fetchaddr>
    80005a86:	02054a63          	bltz	a0,80005aba <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005a8a:	e3043783          	ld	a5,-464(s0)
    80005a8e:	c3b9                	beqz	a5,80005ad4 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005a90:	ffffb097          	auipc	ra,0xffffb
    80005a94:	090080e7          	jalr	144(ra) # 80000b20 <kalloc>
    80005a98:	85aa                	mv	a1,a0
    80005a9a:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005a9e:	cd11                	beqz	a0,80005aba <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005aa0:	6605                	lui	a2,0x1
    80005aa2:	e3043503          	ld	a0,-464(s0)
    80005aa6:	ffffd097          	auipc	ra,0xffffd
    80005aaa:	00c080e7          	jalr	12(ra) # 80002ab2 <fetchstr>
    80005aae:	00054663          	bltz	a0,80005aba <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005ab2:	0905                	addi	s2,s2,1
    80005ab4:	09a1                	addi	s3,s3,8
    80005ab6:	fb491be3          	bne	s2,s4,80005a6c <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aba:	10048913          	addi	s2,s1,256
    80005abe:	6088                	ld	a0,0(s1)
    80005ac0:	c529                	beqz	a0,80005b0a <sys_exec+0xf8>
    kfree(argv[i]);
    80005ac2:	ffffb097          	auipc	ra,0xffffb
    80005ac6:	f62080e7          	jalr	-158(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005aca:	04a1                	addi	s1,s1,8
    80005acc:	ff2499e3          	bne	s1,s2,80005abe <sys_exec+0xac>
  return -1;
    80005ad0:	597d                	li	s2,-1
    80005ad2:	a82d                	j	80005b0c <sys_exec+0xfa>
      argv[i] = 0;
    80005ad4:	0a8e                	slli	s5,s5,0x3
    80005ad6:	fc040793          	addi	a5,s0,-64
    80005ada:	9abe                	add	s5,s5,a5
    80005adc:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ae0:	e4040593          	addi	a1,s0,-448
    80005ae4:	f4040513          	addi	a0,s0,-192
    80005ae8:	fffff097          	auipc	ra,0xfffff
    80005aec:	194080e7          	jalr	404(ra) # 80004c7c <exec>
    80005af0:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af2:	10048993          	addi	s3,s1,256
    80005af6:	6088                	ld	a0,0(s1)
    80005af8:	c911                	beqz	a0,80005b0c <sys_exec+0xfa>
    kfree(argv[i]);
    80005afa:	ffffb097          	auipc	ra,0xffffb
    80005afe:	f2a080e7          	jalr	-214(ra) # 80000a24 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b02:	04a1                	addi	s1,s1,8
    80005b04:	ff3499e3          	bne	s1,s3,80005af6 <sys_exec+0xe4>
    80005b08:	a011                	j	80005b0c <sys_exec+0xfa>
  return -1;
    80005b0a:	597d                	li	s2,-1
}
    80005b0c:	854a                	mv	a0,s2
    80005b0e:	60be                	ld	ra,456(sp)
    80005b10:	641e                	ld	s0,448(sp)
    80005b12:	74fa                	ld	s1,440(sp)
    80005b14:	795a                	ld	s2,432(sp)
    80005b16:	79ba                	ld	s3,424(sp)
    80005b18:	7a1a                	ld	s4,416(sp)
    80005b1a:	6afa                	ld	s5,408(sp)
    80005b1c:	6179                	addi	sp,sp,464
    80005b1e:	8082                	ret

0000000080005b20 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b20:	7139                	addi	sp,sp,-64
    80005b22:	fc06                	sd	ra,56(sp)
    80005b24:	f822                	sd	s0,48(sp)
    80005b26:	f426                	sd	s1,40(sp)
    80005b28:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b2a:	ffffc097          	auipc	ra,0xffffc
    80005b2e:	ed8080e7          	jalr	-296(ra) # 80001a02 <myproc>
    80005b32:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b34:	fd840593          	addi	a1,s0,-40
    80005b38:	4501                	li	a0,0
    80005b3a:	ffffd097          	auipc	ra,0xffffd
    80005b3e:	fe2080e7          	jalr	-30(ra) # 80002b1c <argaddr>
    return -1;
    80005b42:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b44:	0e054063          	bltz	a0,80005c24 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b48:	fc840593          	addi	a1,s0,-56
    80005b4c:	fd040513          	addi	a0,s0,-48
    80005b50:	fffff097          	auipc	ra,0xfffff
    80005b54:	dd2080e7          	jalr	-558(ra) # 80004922 <pipealloc>
    return -1;
    80005b58:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b5a:	0c054563          	bltz	a0,80005c24 <sys_pipe+0x104>
  fd0 = -1;
    80005b5e:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b62:	fd043503          	ld	a0,-48(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	508080e7          	jalr	1288(ra) # 8000506e <fdalloc>
    80005b6e:	fca42223          	sw	a0,-60(s0)
    80005b72:	08054c63          	bltz	a0,80005c0a <sys_pipe+0xea>
    80005b76:	fc843503          	ld	a0,-56(s0)
    80005b7a:	fffff097          	auipc	ra,0xfffff
    80005b7e:	4f4080e7          	jalr	1268(ra) # 8000506e <fdalloc>
    80005b82:	fca42023          	sw	a0,-64(s0)
    80005b86:	06054863          	bltz	a0,80005bf6 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005b8a:	4691                	li	a3,4
    80005b8c:	fc440613          	addi	a2,s0,-60
    80005b90:	fd843583          	ld	a1,-40(s0)
    80005b94:	68a8                	ld	a0,80(s1)
    80005b96:	ffffc097          	auipc	ra,0xffffc
    80005b9a:	b60080e7          	jalr	-1184(ra) # 800016f6 <copyout>
    80005b9e:	02054063          	bltz	a0,80005bbe <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005ba2:	4691                	li	a3,4
    80005ba4:	fc040613          	addi	a2,s0,-64
    80005ba8:	fd843583          	ld	a1,-40(s0)
    80005bac:	0591                	addi	a1,a1,4
    80005bae:	68a8                	ld	a0,80(s1)
    80005bb0:	ffffc097          	auipc	ra,0xffffc
    80005bb4:	b46080e7          	jalr	-1210(ra) # 800016f6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bb8:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bba:	06055563          	bgez	a0,80005c24 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bbe:	fc442783          	lw	a5,-60(s0)
    80005bc2:	07e9                	addi	a5,a5,26
    80005bc4:	078e                	slli	a5,a5,0x3
    80005bc6:	97a6                	add	a5,a5,s1
    80005bc8:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bcc:	fc042503          	lw	a0,-64(s0)
    80005bd0:	0569                	addi	a0,a0,26
    80005bd2:	050e                	slli	a0,a0,0x3
    80005bd4:	9526                	add	a0,a0,s1
    80005bd6:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005bda:	fd043503          	ld	a0,-48(s0)
    80005bde:	fffff097          	auipc	ra,0xfffff
    80005be2:	9ee080e7          	jalr	-1554(ra) # 800045cc <fileclose>
    fileclose(wf);
    80005be6:	fc843503          	ld	a0,-56(s0)
    80005bea:	fffff097          	auipc	ra,0xfffff
    80005bee:	9e2080e7          	jalr	-1566(ra) # 800045cc <fileclose>
    return -1;
    80005bf2:	57fd                	li	a5,-1
    80005bf4:	a805                	j	80005c24 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005bf6:	fc442783          	lw	a5,-60(s0)
    80005bfa:	0007c863          	bltz	a5,80005c0a <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005bfe:	01a78513          	addi	a0,a5,26
    80005c02:	050e                	slli	a0,a0,0x3
    80005c04:	9526                	add	a0,a0,s1
    80005c06:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c0a:	fd043503          	ld	a0,-48(s0)
    80005c0e:	fffff097          	auipc	ra,0xfffff
    80005c12:	9be080e7          	jalr	-1602(ra) # 800045cc <fileclose>
    fileclose(wf);
    80005c16:	fc843503          	ld	a0,-56(s0)
    80005c1a:	fffff097          	auipc	ra,0xfffff
    80005c1e:	9b2080e7          	jalr	-1614(ra) # 800045cc <fileclose>
    return -1;
    80005c22:	57fd                	li	a5,-1
}
    80005c24:	853e                	mv	a0,a5
    80005c26:	70e2                	ld	ra,56(sp)
    80005c28:	7442                	ld	s0,48(sp)
    80005c2a:	74a2                	ld	s1,40(sp)
    80005c2c:	6121                	addi	sp,sp,64
    80005c2e:	8082                	ret

0000000080005c30 <kernelvec>:
    80005c30:	7111                	addi	sp,sp,-256
    80005c32:	e006                	sd	ra,0(sp)
    80005c34:	e40a                	sd	sp,8(sp)
    80005c36:	e80e                	sd	gp,16(sp)
    80005c38:	ec12                	sd	tp,24(sp)
    80005c3a:	f016                	sd	t0,32(sp)
    80005c3c:	f41a                	sd	t1,40(sp)
    80005c3e:	f81e                	sd	t2,48(sp)
    80005c40:	fc22                	sd	s0,56(sp)
    80005c42:	e0a6                	sd	s1,64(sp)
    80005c44:	e4aa                	sd	a0,72(sp)
    80005c46:	e8ae                	sd	a1,80(sp)
    80005c48:	ecb2                	sd	a2,88(sp)
    80005c4a:	f0b6                	sd	a3,96(sp)
    80005c4c:	f4ba                	sd	a4,104(sp)
    80005c4e:	f8be                	sd	a5,112(sp)
    80005c50:	fcc2                	sd	a6,120(sp)
    80005c52:	e146                	sd	a7,128(sp)
    80005c54:	e54a                	sd	s2,136(sp)
    80005c56:	e94e                	sd	s3,144(sp)
    80005c58:	ed52                	sd	s4,152(sp)
    80005c5a:	f156                	sd	s5,160(sp)
    80005c5c:	f55a                	sd	s6,168(sp)
    80005c5e:	f95e                	sd	s7,176(sp)
    80005c60:	fd62                	sd	s8,184(sp)
    80005c62:	e1e6                	sd	s9,192(sp)
    80005c64:	e5ea                	sd	s10,200(sp)
    80005c66:	e9ee                	sd	s11,208(sp)
    80005c68:	edf2                	sd	t3,216(sp)
    80005c6a:	f1f6                	sd	t4,224(sp)
    80005c6c:	f5fa                	sd	t5,232(sp)
    80005c6e:	f9fe                	sd	t6,240(sp)
    80005c70:	cbdfc0ef          	jal	ra,8000292c <kerneltrap>
    80005c74:	6082                	ld	ra,0(sp)
    80005c76:	6122                	ld	sp,8(sp)
    80005c78:	61c2                	ld	gp,16(sp)
    80005c7a:	7282                	ld	t0,32(sp)
    80005c7c:	7322                	ld	t1,40(sp)
    80005c7e:	73c2                	ld	t2,48(sp)
    80005c80:	7462                	ld	s0,56(sp)
    80005c82:	6486                	ld	s1,64(sp)
    80005c84:	6526                	ld	a0,72(sp)
    80005c86:	65c6                	ld	a1,80(sp)
    80005c88:	6666                	ld	a2,88(sp)
    80005c8a:	7686                	ld	a3,96(sp)
    80005c8c:	7726                	ld	a4,104(sp)
    80005c8e:	77c6                	ld	a5,112(sp)
    80005c90:	7866                	ld	a6,120(sp)
    80005c92:	688a                	ld	a7,128(sp)
    80005c94:	692a                	ld	s2,136(sp)
    80005c96:	69ca                	ld	s3,144(sp)
    80005c98:	6a6a                	ld	s4,152(sp)
    80005c9a:	7a8a                	ld	s5,160(sp)
    80005c9c:	7b2a                	ld	s6,168(sp)
    80005c9e:	7bca                	ld	s7,176(sp)
    80005ca0:	7c6a                	ld	s8,184(sp)
    80005ca2:	6c8e                	ld	s9,192(sp)
    80005ca4:	6d2e                	ld	s10,200(sp)
    80005ca6:	6dce                	ld	s11,208(sp)
    80005ca8:	6e6e                	ld	t3,216(sp)
    80005caa:	7e8e                	ld	t4,224(sp)
    80005cac:	7f2e                	ld	t5,232(sp)
    80005cae:	7fce                	ld	t6,240(sp)
    80005cb0:	6111                	addi	sp,sp,256
    80005cb2:	10200073          	sret
    80005cb6:	00000013          	nop
    80005cba:	00000013          	nop
    80005cbe:	0001                	nop

0000000080005cc0 <timervec>:
    80005cc0:	34051573          	csrrw	a0,mscratch,a0
    80005cc4:	e10c                	sd	a1,0(a0)
    80005cc6:	e510                	sd	a2,8(a0)
    80005cc8:	e914                	sd	a3,16(a0)
    80005cca:	710c                	ld	a1,32(a0)
    80005ccc:	7510                	ld	a2,40(a0)
    80005cce:	6194                	ld	a3,0(a1)
    80005cd0:	96b2                	add	a3,a3,a2
    80005cd2:	e194                	sd	a3,0(a1)
    80005cd4:	4589                	li	a1,2
    80005cd6:	14459073          	csrw	sip,a1
    80005cda:	6914                	ld	a3,16(a0)
    80005cdc:	6510                	ld	a2,8(a0)
    80005cde:	610c                	ld	a1,0(a0)
    80005ce0:	34051573          	csrrw	a0,mscratch,a0
    80005ce4:	30200073          	mret
	...

0000000080005cea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005cea:	1141                	addi	sp,sp,-16
    80005cec:	e422                	sd	s0,8(sp)
    80005cee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005cf0:	0c0007b7          	lui	a5,0xc000
    80005cf4:	4705                	li	a4,1
    80005cf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005cf8:	c3d8                	sw	a4,4(a5)
}
    80005cfa:	6422                	ld	s0,8(sp)
    80005cfc:	0141                	addi	sp,sp,16
    80005cfe:	8082                	ret

0000000080005d00 <plicinithart>:

void
plicinithart(void)
{
    80005d00:	1141                	addi	sp,sp,-16
    80005d02:	e406                	sd	ra,8(sp)
    80005d04:	e022                	sd	s0,0(sp)
    80005d06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d08:	ffffc097          	auipc	ra,0xffffc
    80005d0c:	cce080e7          	jalr	-818(ra) # 800019d6 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d10:	0085171b          	slliw	a4,a0,0x8
    80005d14:	0c0027b7          	lui	a5,0xc002
    80005d18:	97ba                	add	a5,a5,a4
    80005d1a:	40200713          	li	a4,1026
    80005d1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d22:	00d5151b          	slliw	a0,a0,0xd
    80005d26:	0c2017b7          	lui	a5,0xc201
    80005d2a:	953e                	add	a0,a0,a5
    80005d2c:	00052023          	sw	zero,0(a0)
}
    80005d30:	60a2                	ld	ra,8(sp)
    80005d32:	6402                	ld	s0,0(sp)
    80005d34:	0141                	addi	sp,sp,16
    80005d36:	8082                	ret

0000000080005d38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d38:	1141                	addi	sp,sp,-16
    80005d3a:	e406                	sd	ra,8(sp)
    80005d3c:	e022                	sd	s0,0(sp)
    80005d3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d40:	ffffc097          	auipc	ra,0xffffc
    80005d44:	c96080e7          	jalr	-874(ra) # 800019d6 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d48:	00d5179b          	slliw	a5,a0,0xd
    80005d4c:	0c201537          	lui	a0,0xc201
    80005d50:	953e                	add	a0,a0,a5
  return irq;
}
    80005d52:	4148                	lw	a0,4(a0)
    80005d54:	60a2                	ld	ra,8(sp)
    80005d56:	6402                	ld	s0,0(sp)
    80005d58:	0141                	addi	sp,sp,16
    80005d5a:	8082                	ret

0000000080005d5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d5c:	1101                	addi	sp,sp,-32
    80005d5e:	ec06                	sd	ra,24(sp)
    80005d60:	e822                	sd	s0,16(sp)
    80005d62:	e426                	sd	s1,8(sp)
    80005d64:	1000                	addi	s0,sp,32
    80005d66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d68:	ffffc097          	auipc	ra,0xffffc
    80005d6c:	c6e080e7          	jalr	-914(ra) # 800019d6 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005d70:	00d5151b          	slliw	a0,a0,0xd
    80005d74:	0c2017b7          	lui	a5,0xc201
    80005d78:	97aa                	add	a5,a5,a0
    80005d7a:	c3c4                	sw	s1,4(a5)
}
    80005d7c:	60e2                	ld	ra,24(sp)
    80005d7e:	6442                	ld	s0,16(sp)
    80005d80:	64a2                	ld	s1,8(sp)
    80005d82:	6105                	addi	sp,sp,32
    80005d84:	8082                	ret

0000000080005d86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005d86:	1141                	addi	sp,sp,-16
    80005d88:	e406                	sd	ra,8(sp)
    80005d8a:	e022                	sd	s0,0(sp)
    80005d8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005d8e:	479d                	li	a5,7
    80005d90:	04a7cc63          	blt	a5,a0,80005de8 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005d94:	0001d797          	auipc	a5,0x1d
    80005d98:	26c78793          	addi	a5,a5,620 # 80023000 <disk>
    80005d9c:	00a78733          	add	a4,a5,a0
    80005da0:	6789                	lui	a5,0x2
    80005da2:	97ba                	add	a5,a5,a4
    80005da4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005da8:	eba1                	bnez	a5,80005df8 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005daa:	00451713          	slli	a4,a0,0x4
    80005dae:	0001f797          	auipc	a5,0x1f
    80005db2:	2527b783          	ld	a5,594(a5) # 80025000 <disk+0x2000>
    80005db6:	97ba                	add	a5,a5,a4
    80005db8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dbc:	0001d797          	auipc	a5,0x1d
    80005dc0:	24478793          	addi	a5,a5,580 # 80023000 <disk>
    80005dc4:	97aa                	add	a5,a5,a0
    80005dc6:	6509                	lui	a0,0x2
    80005dc8:	953e                	add	a0,a0,a5
    80005dca:	4785                	li	a5,1
    80005dcc:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005dd0:	0001f517          	auipc	a0,0x1f
    80005dd4:	24850513          	addi	a0,a0,584 # 80025018 <disk+0x2018>
    80005dd8:	ffffc097          	auipc	ra,0xffffc
    80005ddc:	5cc080e7          	jalr	1484(ra) # 800023a4 <wakeup>
}
    80005de0:	60a2                	ld	ra,8(sp)
    80005de2:	6402                	ld	s0,0(sp)
    80005de4:	0141                	addi	sp,sp,16
    80005de6:	8082                	ret
    panic("virtio_disk_intr 1");
    80005de8:	00003517          	auipc	a0,0x3
    80005dec:	b0050513          	addi	a0,a0,-1280 # 800088e8 <syscall_names+0x338>
    80005df0:	ffffa097          	auipc	ra,0xffffa
    80005df4:	758080e7          	jalr	1880(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005df8:	00003517          	auipc	a0,0x3
    80005dfc:	b0850513          	addi	a0,a0,-1272 # 80008900 <syscall_names+0x350>
    80005e00:	ffffa097          	auipc	ra,0xffffa
    80005e04:	748080e7          	jalr	1864(ra) # 80000548 <panic>

0000000080005e08 <virtio_disk_init>:
{
    80005e08:	1101                	addi	sp,sp,-32
    80005e0a:	ec06                	sd	ra,24(sp)
    80005e0c:	e822                	sd	s0,16(sp)
    80005e0e:	e426                	sd	s1,8(sp)
    80005e10:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e12:	00003597          	auipc	a1,0x3
    80005e16:	b0658593          	addi	a1,a1,-1274 # 80008918 <syscall_names+0x368>
    80005e1a:	0001f517          	auipc	a0,0x1f
    80005e1e:	28e50513          	addi	a0,a0,654 # 800250a8 <disk+0x20a8>
    80005e22:	ffffb097          	auipc	ra,0xffffb
    80005e26:	d82080e7          	jalr	-638(ra) # 80000ba4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e2a:	100017b7          	lui	a5,0x10001
    80005e2e:	4398                	lw	a4,0(a5)
    80005e30:	2701                	sext.w	a4,a4
    80005e32:	747277b7          	lui	a5,0x74727
    80005e36:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e3a:	0ef71163          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e3e:	100017b7          	lui	a5,0x10001
    80005e42:	43dc                	lw	a5,4(a5)
    80005e44:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e46:	4705                	li	a4,1
    80005e48:	0ce79a63          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e4c:	100017b7          	lui	a5,0x10001
    80005e50:	479c                	lw	a5,8(a5)
    80005e52:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e54:	4709                	li	a4,2
    80005e56:	0ce79363          	bne	a5,a4,80005f1c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e5a:	100017b7          	lui	a5,0x10001
    80005e5e:	47d8                	lw	a4,12(a5)
    80005e60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e62:	554d47b7          	lui	a5,0x554d4
    80005e66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e6a:	0af71963          	bne	a4,a5,80005f1c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e6e:	100017b7          	lui	a5,0x10001
    80005e72:	4705                	li	a4,1
    80005e74:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e76:	470d                	li	a4,3
    80005e78:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005e7a:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005e7c:	c7ffe737          	lui	a4,0xc7ffe
    80005e80:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    80005e84:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005e86:	2701                	sext.w	a4,a4
    80005e88:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8a:	472d                	li	a4,11
    80005e8c:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e8e:	473d                	li	a4,15
    80005e90:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005e92:	6705                	lui	a4,0x1
    80005e94:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005e96:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005e9a:	5bdc                	lw	a5,52(a5)
    80005e9c:	2781                	sext.w	a5,a5
  if(max == 0)
    80005e9e:	c7d9                	beqz	a5,80005f2c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ea0:	471d                	li	a4,7
    80005ea2:	08f77d63          	bgeu	a4,a5,80005f3c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ea6:	100014b7          	lui	s1,0x10001
    80005eaa:	47a1                	li	a5,8
    80005eac:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eae:	6609                	lui	a2,0x2
    80005eb0:	4581                	li	a1,0
    80005eb2:	0001d517          	auipc	a0,0x1d
    80005eb6:	14e50513          	addi	a0,a0,334 # 80023000 <disk>
    80005eba:	ffffb097          	auipc	ra,0xffffb
    80005ebe:	e76080e7          	jalr	-394(ra) # 80000d30 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005ec2:	0001d717          	auipc	a4,0x1d
    80005ec6:	13e70713          	addi	a4,a4,318 # 80023000 <disk>
    80005eca:	00c75793          	srli	a5,a4,0xc
    80005ece:	2781                	sext.w	a5,a5
    80005ed0:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005ed2:	0001f797          	auipc	a5,0x1f
    80005ed6:	12e78793          	addi	a5,a5,302 # 80025000 <disk+0x2000>
    80005eda:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005edc:	0001d717          	auipc	a4,0x1d
    80005ee0:	1a470713          	addi	a4,a4,420 # 80023080 <disk+0x80>
    80005ee4:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005ee6:	0001e717          	auipc	a4,0x1e
    80005eea:	11a70713          	addi	a4,a4,282 # 80024000 <disk+0x1000>
    80005eee:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005ef0:	4705                	li	a4,1
    80005ef2:	00e78c23          	sb	a4,24(a5)
    80005ef6:	00e78ca3          	sb	a4,25(a5)
    80005efa:	00e78d23          	sb	a4,26(a5)
    80005efe:	00e78da3          	sb	a4,27(a5)
    80005f02:	00e78e23          	sb	a4,28(a5)
    80005f06:	00e78ea3          	sb	a4,29(a5)
    80005f0a:	00e78f23          	sb	a4,30(a5)
    80005f0e:	00e78fa3          	sb	a4,31(a5)
}
    80005f12:	60e2                	ld	ra,24(sp)
    80005f14:	6442                	ld	s0,16(sp)
    80005f16:	64a2                	ld	s1,8(sp)
    80005f18:	6105                	addi	sp,sp,32
    80005f1a:	8082                	ret
    panic("could not find virtio disk");
    80005f1c:	00003517          	auipc	a0,0x3
    80005f20:	a0c50513          	addi	a0,a0,-1524 # 80008928 <syscall_names+0x378>
    80005f24:	ffffa097          	auipc	ra,0xffffa
    80005f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f2c:	00003517          	auipc	a0,0x3
    80005f30:	a1c50513          	addi	a0,a0,-1508 # 80008948 <syscall_names+0x398>
    80005f34:	ffffa097          	auipc	ra,0xffffa
    80005f38:	614080e7          	jalr	1556(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f3c:	00003517          	auipc	a0,0x3
    80005f40:	a2c50513          	addi	a0,a0,-1492 # 80008968 <syscall_names+0x3b8>
    80005f44:	ffffa097          	auipc	ra,0xffffa
    80005f48:	604080e7          	jalr	1540(ra) # 80000548 <panic>

0000000080005f4c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f4c:	7119                	addi	sp,sp,-128
    80005f4e:	fc86                	sd	ra,120(sp)
    80005f50:	f8a2                	sd	s0,112(sp)
    80005f52:	f4a6                	sd	s1,104(sp)
    80005f54:	f0ca                	sd	s2,96(sp)
    80005f56:	ecce                	sd	s3,88(sp)
    80005f58:	e8d2                	sd	s4,80(sp)
    80005f5a:	e4d6                	sd	s5,72(sp)
    80005f5c:	e0da                	sd	s6,64(sp)
    80005f5e:	fc5e                	sd	s7,56(sp)
    80005f60:	f862                	sd	s8,48(sp)
    80005f62:	f466                	sd	s9,40(sp)
    80005f64:	f06a                	sd	s10,32(sp)
    80005f66:	0100                	addi	s0,sp,128
    80005f68:	892a                	mv	s2,a0
    80005f6a:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005f6c:	00c52c83          	lw	s9,12(a0)
    80005f70:	001c9c9b          	slliw	s9,s9,0x1
    80005f74:	1c82                	slli	s9,s9,0x20
    80005f76:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005f7a:	0001f517          	auipc	a0,0x1f
    80005f7e:	12e50513          	addi	a0,a0,302 # 800250a8 <disk+0x20a8>
    80005f82:	ffffb097          	auipc	ra,0xffffb
    80005f86:	cb2080e7          	jalr	-846(ra) # 80000c34 <acquire>
  for(int i = 0; i < 3; i++){
    80005f8a:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005f8c:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005f8e:	0001db97          	auipc	s7,0x1d
    80005f92:	072b8b93          	addi	s7,s7,114 # 80023000 <disk>
    80005f96:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005f98:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005f9a:	8a4e                	mv	s4,s3
    80005f9c:	a051                	j	80006020 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005f9e:	00fb86b3          	add	a3,s7,a5
    80005fa2:	96da                	add	a3,a3,s6
    80005fa4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fa8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005faa:	0207c563          	bltz	a5,80005fd4 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fae:	2485                	addiw	s1,s1,1
    80005fb0:	0711                	addi	a4,a4,4
    80005fb2:	23548d63          	beq	s1,s5,800061ec <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005fb6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005fb8:	0001f697          	auipc	a3,0x1f
    80005fbc:	06068693          	addi	a3,a3,96 # 80025018 <disk+0x2018>
    80005fc0:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80005fc2:	0006c583          	lbu	a1,0(a3)
    80005fc6:	fde1                	bnez	a1,80005f9e <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80005fc8:	2785                	addiw	a5,a5,1
    80005fca:	0685                	addi	a3,a3,1
    80005fcc:	ff879be3          	bne	a5,s8,80005fc2 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80005fd0:	57fd                	li	a5,-1
    80005fd2:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80005fd4:	02905a63          	blez	s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fd8:	f9042503          	lw	a0,-112(s0)
    80005fdc:	00000097          	auipc	ra,0x0
    80005fe0:	daa080e7          	jalr	-598(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005fe4:	4785                	li	a5,1
    80005fe6:	0297d163          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005fea:	f9442503          	lw	a0,-108(s0)
    80005fee:	00000097          	auipc	ra,0x0
    80005ff2:	d98080e7          	jalr	-616(ra) # 80005d86 <free_desc>
      for(int j = 0; j < i; j++)
    80005ff6:	4789                	li	a5,2
    80005ff8:	0097d863          	bge	a5,s1,80006008 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80005ffc:	f9842503          	lw	a0,-104(s0)
    80006000:	00000097          	auipc	ra,0x0
    80006004:	d86080e7          	jalr	-634(ra) # 80005d86 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006008:	0001f597          	auipc	a1,0x1f
    8000600c:	0a058593          	addi	a1,a1,160 # 800250a8 <disk+0x20a8>
    80006010:	0001f517          	auipc	a0,0x1f
    80006014:	00850513          	addi	a0,a0,8 # 80025018 <disk+0x2018>
    80006018:	ffffc097          	auipc	ra,0xffffc
    8000601c:	206080e7          	jalr	518(ra) # 8000221e <sleep>
  for(int i = 0; i < 3; i++){
    80006020:	f9040713          	addi	a4,s0,-112
    80006024:	84ce                	mv	s1,s3
    80006026:	bf41                	j	80005fb6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006028:	4785                	li	a5,1
    8000602a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000602e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006032:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006036:	f9042983          	lw	s3,-112(s0)
    8000603a:	00499493          	slli	s1,s3,0x4
    8000603e:	0001fa17          	auipc	s4,0x1f
    80006042:	fc2a0a13          	addi	s4,s4,-62 # 80025000 <disk+0x2000>
    80006046:	000a3a83          	ld	s5,0(s4)
    8000604a:	9aa6                	add	s5,s5,s1
    8000604c:	f8040513          	addi	a0,s0,-128
    80006050:	ffffb097          	auipc	ra,0xffffb
    80006054:	0b4080e7          	jalr	180(ra) # 80001104 <kvmpa>
    80006058:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000605c:	000a3783          	ld	a5,0(s4)
    80006060:	97a6                	add	a5,a5,s1
    80006062:	4741                	li	a4,16
    80006064:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006066:	000a3783          	ld	a5,0(s4)
    8000606a:	97a6                	add	a5,a5,s1
    8000606c:	4705                	li	a4,1
    8000606e:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    80006072:	f9442703          	lw	a4,-108(s0)
    80006076:	000a3783          	ld	a5,0(s4)
    8000607a:	97a6                	add	a5,a5,s1
    8000607c:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006080:	0712                	slli	a4,a4,0x4
    80006082:	000a3783          	ld	a5,0(s4)
    80006086:	97ba                	add	a5,a5,a4
    80006088:	05890693          	addi	a3,s2,88
    8000608c:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    8000608e:	000a3783          	ld	a5,0(s4)
    80006092:	97ba                	add	a5,a5,a4
    80006094:	40000693          	li	a3,1024
    80006098:	c794                	sw	a3,8(a5)
  if(write)
    8000609a:	100d0a63          	beqz	s10,800061ae <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000609e:	0001f797          	auipc	a5,0x1f
    800060a2:	f627b783          	ld	a5,-158(a5) # 80025000 <disk+0x2000>
    800060a6:	97ba                	add	a5,a5,a4
    800060a8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ac:	0001d517          	auipc	a0,0x1d
    800060b0:	f5450513          	addi	a0,a0,-172 # 80023000 <disk>
    800060b4:	0001f797          	auipc	a5,0x1f
    800060b8:	f4c78793          	addi	a5,a5,-180 # 80025000 <disk+0x2000>
    800060bc:	6394                	ld	a3,0(a5)
    800060be:	96ba                	add	a3,a3,a4
    800060c0:	00c6d603          	lhu	a2,12(a3)
    800060c4:	00166613          	ori	a2,a2,1
    800060c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800060cc:	f9842683          	lw	a3,-104(s0)
    800060d0:	6390                	ld	a2,0(a5)
    800060d2:	9732                	add	a4,a4,a2
    800060d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    800060d8:	20098613          	addi	a2,s3,512
    800060dc:	0612                	slli	a2,a2,0x4
    800060de:	962a                	add	a2,a2,a0
    800060e0:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800060e4:	00469713          	slli	a4,a3,0x4
    800060e8:	6394                	ld	a3,0(a5)
    800060ea:	96ba                	add	a3,a3,a4
    800060ec:	6589                	lui	a1,0x2
    800060ee:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    800060f2:	94ae                	add	s1,s1,a1
    800060f4:	94aa                	add	s1,s1,a0
    800060f6:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    800060f8:	6394                	ld	a3,0(a5)
    800060fa:	96ba                	add	a3,a3,a4
    800060fc:	4585                	li	a1,1
    800060fe:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006100:	6394                	ld	a3,0(a5)
    80006102:	96ba                	add	a3,a3,a4
    80006104:	4509                	li	a0,2
    80006106:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000610a:	6394                	ld	a3,0(a5)
    8000610c:	9736                	add	a4,a4,a3
    8000610e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006112:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006116:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000611a:	6794                	ld	a3,8(a5)
    8000611c:	0026d703          	lhu	a4,2(a3)
    80006120:	8b1d                	andi	a4,a4,7
    80006122:	2709                	addiw	a4,a4,2
    80006124:	0706                	slli	a4,a4,0x1
    80006126:	9736                	add	a4,a4,a3
    80006128:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000612c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006130:	6798                	ld	a4,8(a5)
    80006132:	00275783          	lhu	a5,2(a4)
    80006136:	2785                	addiw	a5,a5,1
    80006138:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000613c:	100017b7          	lui	a5,0x10001
    80006140:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006144:	00492703          	lw	a4,4(s2)
    80006148:	4785                	li	a5,1
    8000614a:	02f71163          	bne	a4,a5,8000616c <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000614e:	0001f997          	auipc	s3,0x1f
    80006152:	f5a98993          	addi	s3,s3,-166 # 800250a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006156:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006158:	85ce                	mv	a1,s3
    8000615a:	854a                	mv	a0,s2
    8000615c:	ffffc097          	auipc	ra,0xffffc
    80006160:	0c2080e7          	jalr	194(ra) # 8000221e <sleep>
  while(b->disk == 1) {
    80006164:	00492783          	lw	a5,4(s2)
    80006168:	fe9788e3          	beq	a5,s1,80006158 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    8000616c:	f9042483          	lw	s1,-112(s0)
    80006170:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    80006174:	00479713          	slli	a4,a5,0x4
    80006178:	0001d797          	auipc	a5,0x1d
    8000617c:	e8878793          	addi	a5,a5,-376 # 80023000 <disk>
    80006180:	97ba                	add	a5,a5,a4
    80006182:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006186:	0001f917          	auipc	s2,0x1f
    8000618a:	e7a90913          	addi	s2,s2,-390 # 80025000 <disk+0x2000>
    free_desc(i);
    8000618e:	8526                	mv	a0,s1
    80006190:	00000097          	auipc	ra,0x0
    80006194:	bf6080e7          	jalr	-1034(ra) # 80005d86 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    80006198:	0492                	slli	s1,s1,0x4
    8000619a:	00093783          	ld	a5,0(s2)
    8000619e:	94be                	add	s1,s1,a5
    800061a0:	00c4d783          	lhu	a5,12(s1)
    800061a4:	8b85                	andi	a5,a5,1
    800061a6:	cf89                	beqz	a5,800061c0 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061a8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ac:	b7cd                	j	8000618e <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ae:	0001f797          	auipc	a5,0x1f
    800061b2:	e527b783          	ld	a5,-430(a5) # 80025000 <disk+0x2000>
    800061b6:	97ba                	add	a5,a5,a4
    800061b8:	4689                	li	a3,2
    800061ba:	00d79623          	sh	a3,12(a5)
    800061be:	b5fd                	j	800060ac <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800061c0:	0001f517          	auipc	a0,0x1f
    800061c4:	ee850513          	addi	a0,a0,-280 # 800250a8 <disk+0x20a8>
    800061c8:	ffffb097          	auipc	ra,0xffffb
    800061cc:	b20080e7          	jalr	-1248(ra) # 80000ce8 <release>
}
    800061d0:	70e6                	ld	ra,120(sp)
    800061d2:	7446                	ld	s0,112(sp)
    800061d4:	74a6                	ld	s1,104(sp)
    800061d6:	7906                	ld	s2,96(sp)
    800061d8:	69e6                	ld	s3,88(sp)
    800061da:	6a46                	ld	s4,80(sp)
    800061dc:	6aa6                	ld	s5,72(sp)
    800061de:	6b06                	ld	s6,64(sp)
    800061e0:	7be2                	ld	s7,56(sp)
    800061e2:	7c42                	ld	s8,48(sp)
    800061e4:	7ca2                	ld	s9,40(sp)
    800061e6:	7d02                	ld	s10,32(sp)
    800061e8:	6109                	addi	sp,sp,128
    800061ea:	8082                	ret
  if(write)
    800061ec:	e20d1ee3          	bnez	s10,80006028 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    800061f0:	f8042023          	sw	zero,-128(s0)
    800061f4:	bd2d                	j	8000602e <virtio_disk_rw+0xe2>

00000000800061f6 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800061f6:	1101                	addi	sp,sp,-32
    800061f8:	ec06                	sd	ra,24(sp)
    800061fa:	e822                	sd	s0,16(sp)
    800061fc:	e426                	sd	s1,8(sp)
    800061fe:	e04a                	sd	s2,0(sp)
    80006200:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006202:	0001f517          	auipc	a0,0x1f
    80006206:	ea650513          	addi	a0,a0,-346 # 800250a8 <disk+0x20a8>
    8000620a:	ffffb097          	auipc	ra,0xffffb
    8000620e:	a2a080e7          	jalr	-1494(ra) # 80000c34 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006212:	0001f717          	auipc	a4,0x1f
    80006216:	dee70713          	addi	a4,a4,-530 # 80025000 <disk+0x2000>
    8000621a:	02075783          	lhu	a5,32(a4)
    8000621e:	6b18                	ld	a4,16(a4)
    80006220:	00275683          	lhu	a3,2(a4)
    80006224:	8ebd                	xor	a3,a3,a5
    80006226:	8a9d                	andi	a3,a3,7
    80006228:	cab9                	beqz	a3,8000627e <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000622a:	0001d917          	auipc	s2,0x1d
    8000622e:	dd690913          	addi	s2,s2,-554 # 80023000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006232:	0001f497          	auipc	s1,0x1f
    80006236:	dce48493          	addi	s1,s1,-562 # 80025000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000623a:	078e                	slli	a5,a5,0x3
    8000623c:	97ba                	add	a5,a5,a4
    8000623e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006240:	20078713          	addi	a4,a5,512
    80006244:	0712                	slli	a4,a4,0x4
    80006246:	974a                	add	a4,a4,s2
    80006248:	03074703          	lbu	a4,48(a4)
    8000624c:	ef21                	bnez	a4,800062a4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000624e:	20078793          	addi	a5,a5,512
    80006252:	0792                	slli	a5,a5,0x4
    80006254:	97ca                	add	a5,a5,s2
    80006256:	7798                	ld	a4,40(a5)
    80006258:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000625c:	7788                	ld	a0,40(a5)
    8000625e:	ffffc097          	auipc	ra,0xffffc
    80006262:	146080e7          	jalr	326(ra) # 800023a4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006266:	0204d783          	lhu	a5,32(s1)
    8000626a:	2785                	addiw	a5,a5,1
    8000626c:	8b9d                	andi	a5,a5,7
    8000626e:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006272:	6898                	ld	a4,16(s1)
    80006274:	00275683          	lhu	a3,2(a4)
    80006278:	8a9d                	andi	a3,a3,7
    8000627a:	fcf690e3          	bne	a3,a5,8000623a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    8000627e:	10001737          	lui	a4,0x10001
    80006282:	533c                	lw	a5,96(a4)
    80006284:	8b8d                	andi	a5,a5,3
    80006286:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    80006288:	0001f517          	auipc	a0,0x1f
    8000628c:	e2050513          	addi	a0,a0,-480 # 800250a8 <disk+0x20a8>
    80006290:	ffffb097          	auipc	ra,0xffffb
    80006294:	a58080e7          	jalr	-1448(ra) # 80000ce8 <release>
}
    80006298:	60e2                	ld	ra,24(sp)
    8000629a:	6442                	ld	s0,16(sp)
    8000629c:	64a2                	ld	s1,8(sp)
    8000629e:	6902                	ld	s2,0(sp)
    800062a0:	6105                	addi	sp,sp,32
    800062a2:	8082                	ret
      panic("virtio_disk_intr status");
    800062a4:	00002517          	auipc	a0,0x2
    800062a8:	6e450513          	addi	a0,a0,1764 # 80008988 <syscall_names+0x3d8>
    800062ac:	ffffa097          	auipc	ra,0xffffa
    800062b0:	29c080e7          	jalr	668(ra) # 80000548 <panic>
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
