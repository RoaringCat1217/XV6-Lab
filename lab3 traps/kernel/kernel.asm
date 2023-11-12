
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	89013103          	ld	sp,-1904(sp) # 80008890 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000060:	ca478793          	addi	a5,a5,-860 # 80005d00 <timervec>
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
    80000094:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd37ff>
    80000098:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    8000009a:	6705                	lui	a4,0x1
    8000009c:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a2:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000a6:	00001797          	auipc	a5,0x1
    800000aa:	e8c78793          	addi	a5,a5,-372 # 80000f32 <main>
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
    80000110:	b78080e7          	jalr	-1160(ra) # 80000c84 <acquire>
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
    8000012a:	400080e7          	jalr	1024(ra) # 80002526 <either_copyin>
    8000012e:	01550c63          	beq	a0,s5,80000146 <consolewrite+0x5a>
      break;
    uartputc(c);
    80000132:	fbf44503          	lbu	a0,-65(s0)
    80000136:	00001097          	auipc	ra,0x1
    8000013a:	81e080e7          	jalr	-2018(ra) # 80000954 <uartputc>
  for(i = 0; i < n; i++){
    8000013e:	2905                	addiw	s2,s2,1
    80000140:	0485                	addi	s1,s1,1
    80000142:	fd299de3          	bne	s3,s2,8000011c <consolewrite+0x30>
  }
  release(&cons.lock);
    80000146:	00011517          	auipc	a0,0x11
    8000014a:	6ea50513          	addi	a0,a0,1770 # 80011830 <cons>
    8000014e:	00001097          	auipc	ra,0x1
    80000152:	bea080e7          	jalr	-1046(ra) # 80000d38 <release>

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
    800001a2:	ae6080e7          	jalr	-1306(ra) # 80000c84 <acquire>
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
    800001d2:	884080e7          	jalr	-1916(ra) # 80001a52 <myproc>
    800001d6:	591c                	lw	a5,48(a0)
    800001d8:	e7b5                	bnez	a5,80000244 <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001da:	85ce                	mv	a1,s3
    800001dc:	854a                	mv	a0,s2
    800001de:	00002097          	auipc	ra,0x2
    800001e2:	090080e7          	jalr	144(ra) # 8000226e <sleep>
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
    8000021e:	2b6080e7          	jalr	694(ra) # 800024d0 <either_copyout>
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
    8000023a:	b02080e7          	jalr	-1278(ra) # 80000d38 <release>

  return target - n;
    8000023e:	414b853b          	subw	a0,s7,s4
    80000242:	a811                	j	80000256 <consoleread+0xe8>
        release(&cons.lock);
    80000244:	00011517          	auipc	a0,0x11
    80000248:	5ec50513          	addi	a0,a0,1516 # 80011830 <cons>
    8000024c:	00001097          	auipc	ra,0x1
    80000250:	aec080e7          	jalr	-1300(ra) # 80000d38 <release>
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
    8000029a:	5d8080e7          	jalr	1496(ra) # 8000086e <uartputc_sync>
}
    8000029e:	60a2                	ld	ra,8(sp)
    800002a0:	6402                	ld	s0,0(sp)
    800002a2:	0141                	addi	sp,sp,16
    800002a4:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a6:	4521                	li	a0,8
    800002a8:	00000097          	auipc	ra,0x0
    800002ac:	5c6080e7          	jalr	1478(ra) # 8000086e <uartputc_sync>
    800002b0:	02000513          	li	a0,32
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	5ba080e7          	jalr	1466(ra) # 8000086e <uartputc_sync>
    800002bc:	4521                	li	a0,8
    800002be:	00000097          	auipc	ra,0x0
    800002c2:	5b0080e7          	jalr	1456(ra) # 8000086e <uartputc_sync>
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
    800002e2:	9a6080e7          	jalr	-1626(ra) # 80000c84 <acquire>

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
    80000300:	280080e7          	jalr	640(ra) # 8000257c <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000304:	00011517          	auipc	a0,0x11
    80000308:	52c50513          	addi	a0,a0,1324 # 80011830 <cons>
    8000030c:	00001097          	auipc	ra,0x1
    80000310:	a2c080e7          	jalr	-1492(ra) # 80000d38 <release>
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
    80000454:	fa4080e7          	jalr	-92(ra) # 800023f4 <wakeup>
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
    80000476:	782080e7          	jalr	1922(ra) # 80000bf4 <initlock>

  uartinit();
    8000047a:	00000097          	auipc	ra,0x0
    8000047e:	3a4080e7          	jalr	932(ra) # 8000081e <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000482:	00026797          	auipc	a5,0x26
    80000486:	32e78793          	addi	a5,a5,814 # 800267b0 <devsw>
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
    800004c8:	b9460613          	addi	a2,a2,-1132 # 80008058 <digits>
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
  }
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
    80000568:	036080e7          	jalr	54(ra) # 8000059a <printf>
  printf(s);
    8000056c:	8526                	mv	a0,s1
    8000056e:	00000097          	auipc	ra,0x0
    80000572:	02c080e7          	jalr	44(ra) # 8000059a <printf>
  printf("\n");
    80000576:	00008517          	auipc	a0,0x8
    8000057a:	b6a50513          	addi	a0,a0,-1174 # 800080e0 <digits+0x88>
    8000057e:	00000097          	auipc	ra,0x0
    80000582:	01c080e7          	jalr	28(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000586:	4785                	li	a5,1
    80000588:	00009717          	auipc	a4,0x9
    8000058c:	a6f72c23          	sw	a5,-1416(a4) # 80009000 <panicked>
  backtrace();
    80000590:	00000097          	auipc	ra,0x0
    80000594:	1f0080e7          	jalr	496(ra) # 80000780 <backtrace>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x50>

000000008000059a <printf>:
{
    8000059a:	7131                	addi	sp,sp,-192
    8000059c:	fc86                	sd	ra,120(sp)
    8000059e:	f8a2                	sd	s0,112(sp)
    800005a0:	f4a6                	sd	s1,104(sp)
    800005a2:	f0ca                	sd	s2,96(sp)
    800005a4:	ecce                	sd	s3,88(sp)
    800005a6:	e8d2                	sd	s4,80(sp)
    800005a8:	e4d6                	sd	s5,72(sp)
    800005aa:	e0da                	sd	s6,64(sp)
    800005ac:	fc5e                	sd	s7,56(sp)
    800005ae:	f862                	sd	s8,48(sp)
    800005b0:	f466                	sd	s9,40(sp)
    800005b2:	f06a                	sd	s10,32(sp)
    800005b4:	ec6e                	sd	s11,24(sp)
    800005b6:	0100                	addi	s0,sp,128
    800005b8:	8a2a                	mv	s4,a0
    800005ba:	e40c                	sd	a1,8(s0)
    800005bc:	e810                	sd	a2,16(s0)
    800005be:	ec14                	sd	a3,24(s0)
    800005c0:	f018                	sd	a4,32(s0)
    800005c2:	f41c                	sd	a5,40(s0)
    800005c4:	03043823          	sd	a6,48(s0)
    800005c8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005cc:	00011d97          	auipc	s11,0x11
    800005d0:	324dad83          	lw	s11,804(s11) # 800118f0 <pr+0x18>
  if(locking)
    800005d4:	020d9b63          	bnez	s11,8000060a <printf+0x70>
  if (fmt == 0)
    800005d8:	040a0263          	beqz	s4,8000061c <printf+0x82>
  va_start(ap, fmt);
    800005dc:	00840793          	addi	a5,s0,8
    800005e0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005e4:	000a4503          	lbu	a0,0(s4)
    800005e8:	16050263          	beqz	a0,8000074c <printf+0x1b2>
    800005ec:	4481                	li	s1,0
    if(c != '%'){
    800005ee:	02500a93          	li	s5,37
    switch(c){
    800005f2:	07000b13          	li	s6,112
  consputc('x');
    800005f6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005f8:	00008b97          	auipc	s7,0x8
    800005fc:	a60b8b93          	addi	s7,s7,-1440 # 80008058 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	2ce50513          	addi	a0,a0,718 # 800118d8 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	672080e7          	jalr	1650(ra) # 80000c84 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f24080e7          	jalr	-220(ra) # 80000548 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c5a080e7          	jalr	-934(ra) # 80000286 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c503          	lbu	a0,0(a5)
    8000063e:	10050763          	beqz	a0,8000074c <printf+0x1b2>
    if(c != '%'){
    80000642:	ff5515e3          	bne	a0,s5,8000062c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000646:	2485                	addiw	s1,s1,1
    80000648:	009a07b3          	add	a5,s4,s1
    8000064c:	0007c783          	lbu	a5,0(a5)
    80000650:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000654:	cfe5                	beqz	a5,8000074c <printf+0x1b2>
    switch(c){
    80000656:	05678a63          	beq	a5,s6,800006aa <printf+0x110>
    8000065a:	02fb7663          	bgeu	s6,a5,80000686 <printf+0xec>
    8000065e:	09978963          	beq	a5,s9,800006f0 <printf+0x156>
    80000662:	07800713          	li	a4,120
    80000666:	0ce79863          	bne	a5,a4,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000066a:	f8843783          	ld	a5,-120(s0)
    8000066e:	00878713          	addi	a4,a5,8
    80000672:	f8e43423          	sd	a4,-120(s0)
    80000676:	4605                	li	a2,1
    80000678:	85ea                	mv	a1,s10
    8000067a:	4388                	lw	a0,0(a5)
    8000067c:	00000097          	auipc	ra,0x0
    80000680:	e2a080e7          	jalr	-470(ra) # 800004a6 <printint>
      break;
    80000684:	bf45                	j	80000634 <printf+0x9a>
    switch(c){
    80000686:	0b578263          	beq	a5,s5,8000072a <printf+0x190>
    8000068a:	0b879663          	bne	a5,s8,80000736 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000068e:	f8843783          	ld	a5,-120(s0)
    80000692:	00878713          	addi	a4,a5,8
    80000696:	f8e43423          	sd	a4,-120(s0)
    8000069a:	4605                	li	a2,1
    8000069c:	45a9                	li	a1,10
    8000069e:	4388                	lw	a0,0(a5)
    800006a0:	00000097          	auipc	ra,0x0
    800006a4:	e06080e7          	jalr	-506(ra) # 800004a6 <printint>
      break;
    800006a8:	b771                	j	80000634 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    800006aa:	f8843783          	ld	a5,-120(s0)
    800006ae:	00878713          	addi	a4,a5,8
    800006b2:	f8e43423          	sd	a4,-120(s0)
    800006b6:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ba:	03000513          	li	a0,48
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc8080e7          	jalr	-1080(ra) # 80000286 <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bbc080e7          	jalr	-1092(ra) # 80000286 <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	ba8080e7          	jalr	-1112(ra) # 80000286 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006e6:	0992                	slli	s3,s3,0x4
    800006e8:	397d                	addiw	s2,s2,-1
    800006ea:	fe0915e3          	bnez	s2,800006d4 <printf+0x13a>
    800006ee:	b799                	j	80000634 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006f0:	f8843783          	ld	a5,-120(s0)
    800006f4:	00878713          	addi	a4,a5,8
    800006f8:	f8e43423          	sd	a4,-120(s0)
    800006fc:	0007b903          	ld	s2,0(a5)
    80000700:	00090e63          	beqz	s2,8000071c <printf+0x182>
      for(; *s; s++)
    80000704:	00094503          	lbu	a0,0(s2)
    80000708:	d515                	beqz	a0,80000634 <printf+0x9a>
        consputc(*s);
    8000070a:	00000097          	auipc	ra,0x0
    8000070e:	b7c080e7          	jalr	-1156(ra) # 80000286 <consputc>
      for(; *s; s++)
    80000712:	0905                	addi	s2,s2,1
    80000714:	00094503          	lbu	a0,0(s2)
    80000718:	f96d                	bnez	a0,8000070a <printf+0x170>
    8000071a:	bf29                	j	80000634 <printf+0x9a>
        s = "(null)";
    8000071c:	00008917          	auipc	s2,0x8
    80000720:	90490913          	addi	s2,s2,-1788 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000724:	02800513          	li	a0,40
    80000728:	b7cd                	j	8000070a <printf+0x170>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b5a080e7          	jalr	-1190(ra) # 80000286 <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b4e080e7          	jalr	-1202(ra) # 80000286 <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b44080e7          	jalr	-1212(ra) # 80000286 <consputc>
      break;
    8000074a:	b5ed                	j	80000634 <printf+0x9a>
  if(locking)
    8000074c:	020d9163          	bnez	s11,8000076e <printf+0x1d4>
}
    80000750:	70e6                	ld	ra,120(sp)
    80000752:	7446                	ld	s0,112(sp)
    80000754:	74a6                	ld	s1,104(sp)
    80000756:	7906                	ld	s2,96(sp)
    80000758:	69e6                	ld	s3,88(sp)
    8000075a:	6a46                	ld	s4,80(sp)
    8000075c:	6aa6                	ld	s5,72(sp)
    8000075e:	6b06                	ld	s6,64(sp)
    80000760:	7be2                	ld	s7,56(sp)
    80000762:	7c42                	ld	s8,48(sp)
    80000764:	7ca2                	ld	s9,40(sp)
    80000766:	7d02                	ld	s10,32(sp)
    80000768:	6de2                	ld	s11,24(sp)
    8000076a:	6129                	addi	sp,sp,192
    8000076c:	8082                	ret
    release(&pr.lock);
    8000076e:	00011517          	auipc	a0,0x11
    80000772:	16a50513          	addi	a0,a0,362 # 800118d8 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	5c2080e7          	jalr	1474(ra) # 80000d38 <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <backtrace>:
{
    80000780:	7179                	addi	sp,sp,-48
    80000782:	f406                	sd	ra,40(sp)
    80000784:	f022                	sd	s0,32(sp)
    80000786:	ec26                	sd	s1,24(sp)
    80000788:	e84a                	sd	s2,16(sp)
    8000078a:	e44e                	sd	s3,8(sp)
    8000078c:	e052                	sd	s4,0(sp)
    8000078e:	1800                	addi	s0,sp,48
// read the current stack frame
static inline uint64
r_fp()
{
  uint64 x;
  asm volatile("mv %0, s0": "=r"(x));
    80000790:	84a2                	mv	s1,s0
  uint64 low_bound = PGROUNDDOWN(fp), high_bound = PGROUNDUP(fp);
    80000792:	77fd                	lui	a5,0xfffff
    80000794:	00f4f9b3          	and	s3,s1,a5
    80000798:	6905                	lui	s2,0x1
    8000079a:	197d                	addi	s2,s2,-1
    8000079c:	9926                	add	s2,s2,s1
    8000079e:	00f97933          	and	s2,s2,a5
  printf("backtrace:\n");
    800007a2:	00008517          	auipc	a0,0x8
    800007a6:	89650513          	addi	a0,a0,-1898 # 80008038 <etext+0x38>
    800007aa:	00000097          	auipc	ra,0x0
    800007ae:	df0080e7          	jalr	-528(ra) # 8000059a <printf>
  while (fp >= low_bound && fp < high_bound)
    800007b2:	0334e563          	bltu	s1,s3,800007dc <backtrace+0x5c>
    800007b6:	0324f363          	bgeu	s1,s2,800007dc <backtrace+0x5c>
    printf("%p\n", *(uint64 *)(fp - 8));
    800007ba:	00008a17          	auipc	s4,0x8
    800007be:	88ea0a13          	addi	s4,s4,-1906 # 80008048 <etext+0x48>
    800007c2:	ff84b583          	ld	a1,-8(s1)
    800007c6:	8552                	mv	a0,s4
    800007c8:	00000097          	auipc	ra,0x0
    800007cc:	dd2080e7          	jalr	-558(ra) # 8000059a <printf>
    fp = *(uint64 *)(fp - 16);
    800007d0:	ff04b483          	ld	s1,-16(s1)
  while (fp >= low_bound && fp < high_bound)
    800007d4:	0134e463          	bltu	s1,s3,800007dc <backtrace+0x5c>
    800007d8:	ff24e5e3          	bltu	s1,s2,800007c2 <backtrace+0x42>
}
    800007dc:	70a2                	ld	ra,40(sp)
    800007de:	7402                	ld	s0,32(sp)
    800007e0:	64e2                	ld	s1,24(sp)
    800007e2:	6942                	ld	s2,16(sp)
    800007e4:	69a2                	ld	s3,8(sp)
    800007e6:	6a02                	ld	s4,0(sp)
    800007e8:	6145                	addi	sp,sp,48
    800007ea:	8082                	ret

00000000800007ec <printfinit>:
    ;
}

void
printfinit(void)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    800007f6:	00011497          	auipc	s1,0x11
    800007fa:	0e248493          	addi	s1,s1,226 # 800118d8 <pr>
    800007fe:	00008597          	auipc	a1,0x8
    80000802:	85258593          	addi	a1,a1,-1966 # 80008050 <etext+0x50>
    80000806:	8526                	mv	a0,s1
    80000808:	00000097          	auipc	ra,0x0
    8000080c:	3ec080e7          	jalr	1004(ra) # 80000bf4 <initlock>
  pr.locking = 1;
    80000810:	4785                	li	a5,1
    80000812:	cc9c                	sw	a5,24(s1)
}
    80000814:	60e2                	ld	ra,24(sp)
    80000816:	6442                	ld	s0,16(sp)
    80000818:	64a2                	ld	s1,8(sp)
    8000081a:	6105                	addi	sp,sp,32
    8000081c:	8082                	ret

000000008000081e <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000081e:	1141                	addi	sp,sp,-16
    80000820:	e406                	sd	ra,8(sp)
    80000822:	e022                	sd	s0,0(sp)
    80000824:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    80000826:	100007b7          	lui	a5,0x10000
    8000082a:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    8000082e:	f8000713          	li	a4,-128
    80000832:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    80000836:	470d                	li	a4,3
    80000838:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    8000083c:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    80000840:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    80000844:	469d                	li	a3,7
    80000846:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    8000084a:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    8000084e:	00008597          	auipc	a1,0x8
    80000852:	82258593          	addi	a1,a1,-2014 # 80008070 <digits+0x18>
    80000856:	00011517          	auipc	a0,0x11
    8000085a:	0a250513          	addi	a0,a0,162 # 800118f8 <uart_tx_lock>
    8000085e:	00000097          	auipc	ra,0x0
    80000862:	396080e7          	jalr	918(ra) # 80000bf4 <initlock>
}
    80000866:	60a2                	ld	ra,8(sp)
    80000868:	6402                	ld	s0,0(sp)
    8000086a:	0141                	addi	sp,sp,16
    8000086c:	8082                	ret

000000008000086e <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    8000086e:	1101                	addi	sp,sp,-32
    80000870:	ec06                	sd	ra,24(sp)
    80000872:	e822                	sd	s0,16(sp)
    80000874:	e426                	sd	s1,8(sp)
    80000876:	1000                	addi	s0,sp,32
    80000878:	84aa                	mv	s1,a0
  push_off();
    8000087a:	00000097          	auipc	ra,0x0
    8000087e:	3be080e7          	jalr	958(ra) # 80000c38 <push_off>

  if(panicked){
    80000882:	00008797          	auipc	a5,0x8
    80000886:	77e7a783          	lw	a5,1918(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000088a:	10000737          	lui	a4,0x10000
  if(panicked){
    8000088e:	c391                	beqz	a5,80000892 <uartputc_sync+0x24>
    for(;;)
    80000890:	a001                	j	80000890 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000892:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000896:	0ff7f793          	andi	a5,a5,255
    8000089a:	0207f793          	andi	a5,a5,32
    8000089e:	dbf5                	beqz	a5,80000892 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    800008a0:	0ff4f793          	andi	a5,s1,255
    800008a4:	10000737          	lui	a4,0x10000
    800008a8:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    800008ac:	00000097          	auipc	ra,0x0
    800008b0:	42c080e7          	jalr	1068(ra) # 80000cd8 <pop_off>
}
    800008b4:	60e2                	ld	ra,24(sp)
    800008b6:	6442                	ld	s0,16(sp)
    800008b8:	64a2                	ld	s1,8(sp)
    800008ba:	6105                	addi	sp,sp,32
    800008bc:	8082                	ret

00000000800008be <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    800008be:	00008797          	auipc	a5,0x8
    800008c2:	7467a783          	lw	a5,1862(a5) # 80009004 <uart_tx_r>
    800008c6:	00008717          	auipc	a4,0x8
    800008ca:	74272703          	lw	a4,1858(a4) # 80009008 <uart_tx_w>
    800008ce:	08f70263          	beq	a4,a5,80000952 <uartstart+0x94>
{
    800008d2:	7139                	addi	sp,sp,-64
    800008d4:	fc06                	sd	ra,56(sp)
    800008d6:	f822                	sd	s0,48(sp)
    800008d8:	f426                	sd	s1,40(sp)
    800008da:	f04a                	sd	s2,32(sp)
    800008dc:	ec4e                	sd	s3,24(sp)
    800008de:	e852                	sd	s4,16(sp)
    800008e0:	e456                	sd	s5,8(sp)
    800008e2:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    800008e4:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    800008e8:	00011a17          	auipc	s4,0x11
    800008ec:	010a0a13          	addi	s4,s4,16 # 800118f8 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008f0:	00008497          	auipc	s1,0x8
    800008f4:	71448493          	addi	s1,s1,1812 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    800008f8:	00008997          	auipc	s3,0x8
    800008fc:	71098993          	addi	s3,s3,1808 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000900:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000904:	0ff77713          	andi	a4,a4,255
    80000908:	02077713          	andi	a4,a4,32
    8000090c:	cb15                	beqz	a4,80000940 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    8000090e:	00fa0733          	add	a4,s4,a5
    80000912:	01874a83          	lbu	s5,24(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000916:	2785                	addiw	a5,a5,1
    80000918:	41f7d71b          	sraiw	a4,a5,0x1f
    8000091c:	01b7571b          	srliw	a4,a4,0x1b
    80000920:	9fb9                	addw	a5,a5,a4
    80000922:	8bfd                	andi	a5,a5,31
    80000924:	9f99                	subw	a5,a5,a4
    80000926:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000928:	8526                	mv	a0,s1
    8000092a:	00002097          	auipc	ra,0x2
    8000092e:	aca080e7          	jalr	-1334(ra) # 800023f4 <wakeup>
    
    WriteReg(THR, c);
    80000932:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    80000936:	409c                	lw	a5,0(s1)
    80000938:	0009a703          	lw	a4,0(s3)
    8000093c:	fcf712e3          	bne	a4,a5,80000900 <uartstart+0x42>
  }
}
    80000940:	70e2                	ld	ra,56(sp)
    80000942:	7442                	ld	s0,48(sp)
    80000944:	74a2                	ld	s1,40(sp)
    80000946:	7902                	ld	s2,32(sp)
    80000948:	69e2                	ld	s3,24(sp)
    8000094a:	6a42                	ld	s4,16(sp)
    8000094c:	6aa2                	ld	s5,8(sp)
    8000094e:	6121                	addi	sp,sp,64
    80000950:	8082                	ret
    80000952:	8082                	ret

0000000080000954 <uartputc>:
{
    80000954:	7179                	addi	sp,sp,-48
    80000956:	f406                	sd	ra,40(sp)
    80000958:	f022                	sd	s0,32(sp)
    8000095a:	ec26                	sd	s1,24(sp)
    8000095c:	e84a                	sd	s2,16(sp)
    8000095e:	e44e                	sd	s3,8(sp)
    80000960:	e052                	sd	s4,0(sp)
    80000962:	1800                	addi	s0,sp,48
    80000964:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    80000966:	00011517          	auipc	a0,0x11
    8000096a:	f9250513          	addi	a0,a0,-110 # 800118f8 <uart_tx_lock>
    8000096e:	00000097          	auipc	ra,0x0
    80000972:	316080e7          	jalr	790(ra) # 80000c84 <acquire>
  if(panicked){
    80000976:	00008797          	auipc	a5,0x8
    8000097a:	68a7a783          	lw	a5,1674(a5) # 80009000 <panicked>
    8000097e:	c391                	beqz	a5,80000982 <uartputc+0x2e>
    for(;;)
    80000980:	a001                	j	80000980 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000982:	00008717          	auipc	a4,0x8
    80000986:	68672703          	lw	a4,1670(a4) # 80009008 <uart_tx_w>
    8000098a:	0017079b          	addiw	a5,a4,1
    8000098e:	41f7d69b          	sraiw	a3,a5,0x1f
    80000992:	01b6d69b          	srliw	a3,a3,0x1b
    80000996:	9fb5                	addw	a5,a5,a3
    80000998:	8bfd                	andi	a5,a5,31
    8000099a:	9f95                	subw	a5,a5,a3
    8000099c:	00008697          	auipc	a3,0x8
    800009a0:	6686a683          	lw	a3,1640(a3) # 80009004 <uart_tx_r>
    800009a4:	04f69263          	bne	a3,a5,800009e8 <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009a8:	00011a17          	auipc	s4,0x11
    800009ac:	f50a0a13          	addi	s4,s4,-176 # 800118f8 <uart_tx_lock>
    800009b0:	00008497          	auipc	s1,0x8
    800009b4:	65448493          	addi	s1,s1,1620 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009b8:	00008917          	auipc	s2,0x8
    800009bc:	65090913          	addi	s2,s2,1616 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    800009c0:	85d2                	mv	a1,s4
    800009c2:	8526                	mv	a0,s1
    800009c4:	00002097          	auipc	ra,0x2
    800009c8:	8aa080e7          	jalr	-1878(ra) # 8000226e <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    800009cc:	00092703          	lw	a4,0(s2)
    800009d0:	0017079b          	addiw	a5,a4,1
    800009d4:	41f7d69b          	sraiw	a3,a5,0x1f
    800009d8:	01b6d69b          	srliw	a3,a3,0x1b
    800009dc:	9fb5                	addw	a5,a5,a3
    800009de:	8bfd                	andi	a5,a5,31
    800009e0:	9f95                	subw	a5,a5,a3
    800009e2:	4094                	lw	a3,0(s1)
    800009e4:	fcf68ee3          	beq	a3,a5,800009c0 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    800009e8:	00011497          	auipc	s1,0x11
    800009ec:	f1048493          	addi	s1,s1,-240 # 800118f8 <uart_tx_lock>
    800009f0:	9726                	add	a4,a4,s1
    800009f2:	01370c23          	sb	s3,24(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    800009f6:	00008717          	auipc	a4,0x8
    800009fa:	60f72923          	sw	a5,1554(a4) # 80009008 <uart_tx_w>
      uartstart();
    800009fe:	00000097          	auipc	ra,0x0
    80000a02:	ec0080e7          	jalr	-320(ra) # 800008be <uartstart>
      release(&uart_tx_lock);
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	330080e7          	jalr	816(ra) # 80000d38 <release>
}
    80000a10:	70a2                	ld	ra,40(sp)
    80000a12:	7402                	ld	s0,32(sp)
    80000a14:	64e2                	ld	s1,24(sp)
    80000a16:	6942                	ld	s2,16(sp)
    80000a18:	69a2                	ld	s3,8(sp)
    80000a1a:	6a02                	ld	s4,0(sp)
    80000a1c:	6145                	addi	sp,sp,48
    80000a1e:	8082                	ret

0000000080000a20 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000a20:	1141                	addi	sp,sp,-16
    80000a22:	e422                	sd	s0,8(sp)
    80000a24:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000a26:	100007b7          	lui	a5,0x10000
    80000a2a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000a2e:	8b85                	andi	a5,a5,1
    80000a30:	cb91                	beqz	a5,80000a44 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000a32:	100007b7          	lui	a5,0x10000
    80000a36:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    80000a3a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000a3e:	6422                	ld	s0,8(sp)
    80000a40:	0141                	addi	sp,sp,16
    80000a42:	8082                	ret
    return -1;
    80000a44:	557d                	li	a0,-1
    80000a46:	bfe5                	j	80000a3e <uartgetc+0x1e>

0000000080000a48 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    80000a48:	1101                	addi	sp,sp,-32
    80000a4a:	ec06                	sd	ra,24(sp)
    80000a4c:	e822                	sd	s0,16(sp)
    80000a4e:	e426                	sd	s1,8(sp)
    80000a50:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    80000a52:	54fd                	li	s1,-1
    int c = uartgetc();
    80000a54:	00000097          	auipc	ra,0x0
    80000a58:	fcc080e7          	jalr	-52(ra) # 80000a20 <uartgetc>
    if(c == -1)
    80000a5c:	00950763          	beq	a0,s1,80000a6a <uartintr+0x22>
      break;
    consoleintr(c);
    80000a60:	00000097          	auipc	ra,0x0
    80000a64:	868080e7          	jalr	-1944(ra) # 800002c8 <consoleintr>
  while(1){
    80000a68:	b7f5                	j	80000a54 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    80000a6a:	00011497          	auipc	s1,0x11
    80000a6e:	e8e48493          	addi	s1,s1,-370 # 800118f8 <uart_tx_lock>
    80000a72:	8526                	mv	a0,s1
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	210080e7          	jalr	528(ra) # 80000c84 <acquire>
  uartstart();
    80000a7c:	00000097          	auipc	ra,0x0
    80000a80:	e42080e7          	jalr	-446(ra) # 800008be <uartstart>
  release(&uart_tx_lock);
    80000a84:	8526                	mv	a0,s1
    80000a86:	00000097          	auipc	ra,0x0
    80000a8a:	2b2080e7          	jalr	690(ra) # 80000d38 <release>
}
    80000a8e:	60e2                	ld	ra,24(sp)
    80000a90:	6442                	ld	s0,16(sp)
    80000a92:	64a2                	ld	s1,8(sp)
    80000a94:	6105                	addi	sp,sp,32
    80000a96:	8082                	ret

0000000080000a98 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a98:	1101                	addi	sp,sp,-32
    80000a9a:	ec06                	sd	ra,24(sp)
    80000a9c:	e822                	sd	s0,16(sp)
    80000a9e:	e426                	sd	s1,8(sp)
    80000aa0:	e04a                	sd	s2,0(sp)
    80000aa2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000aa4:	03451793          	slli	a5,a0,0x34
    80000aa8:	ebb9                	bnez	a5,80000afe <kfree+0x66>
    80000aaa:	84aa                	mv	s1,a0
    80000aac:	0002a797          	auipc	a5,0x2a
    80000ab0:	55478793          	addi	a5,a5,1364 # 8002b000 <end>
    80000ab4:	04f56563          	bltu	a0,a5,80000afe <kfree+0x66>
    80000ab8:	47c5                	li	a5,17
    80000aba:	07ee                	slli	a5,a5,0x1b
    80000abc:	04f57163          	bgeu	a0,a5,80000afe <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000ac0:	6605                	lui	a2,0x1
    80000ac2:	4585                	li	a1,1
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	2bc080e7          	jalr	700(ra) # 80000d80 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000acc:	00011917          	auipc	s2,0x11
    80000ad0:	e6490913          	addi	s2,s2,-412 # 80011930 <kmem>
    80000ad4:	854a                	mv	a0,s2
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	1ae080e7          	jalr	430(ra) # 80000c84 <acquire>
  r->next = kmem.freelist;
    80000ade:	01893783          	ld	a5,24(s2)
    80000ae2:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000ae4:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000ae8:	854a                	mv	a0,s2
    80000aea:	00000097          	auipc	ra,0x0
    80000aee:	24e080e7          	jalr	590(ra) # 80000d38 <release>
}
    80000af2:	60e2                	ld	ra,24(sp)
    80000af4:	6442                	ld	s0,16(sp)
    80000af6:	64a2                	ld	s1,8(sp)
    80000af8:	6902                	ld	s2,0(sp)
    80000afa:	6105                	addi	sp,sp,32
    80000afc:	8082                	ret
    panic("kfree");
    80000afe:	00007517          	auipc	a0,0x7
    80000b02:	57a50513          	addi	a0,a0,1402 # 80008078 <digits+0x20>
    80000b06:	00000097          	auipc	ra,0x0
    80000b0a:	a42080e7          	jalr	-1470(ra) # 80000548 <panic>

0000000080000b0e <freerange>:
{
    80000b0e:	7179                	addi	sp,sp,-48
    80000b10:	f406                	sd	ra,40(sp)
    80000b12:	f022                	sd	s0,32(sp)
    80000b14:	ec26                	sd	s1,24(sp)
    80000b16:	e84a                	sd	s2,16(sp)
    80000b18:	e44e                	sd	s3,8(sp)
    80000b1a:	e052                	sd	s4,0(sp)
    80000b1c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000b1e:	6785                	lui	a5,0x1
    80000b20:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000b24:	94aa                	add	s1,s1,a0
    80000b26:	757d                	lui	a0,0xfffff
    80000b28:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b2a:	94be                	add	s1,s1,a5
    80000b2c:	0095ee63          	bltu	a1,s1,80000b48 <freerange+0x3a>
    80000b30:	892e                	mv	s2,a1
    kfree(p);
    80000b32:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b34:	6985                	lui	s3,0x1
    kfree(p);
    80000b36:	01448533          	add	a0,s1,s4
    80000b3a:	00000097          	auipc	ra,0x0
    80000b3e:	f5e080e7          	jalr	-162(ra) # 80000a98 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b42:	94ce                	add	s1,s1,s3
    80000b44:	fe9979e3          	bgeu	s2,s1,80000b36 <freerange+0x28>
}
    80000b48:	70a2                	ld	ra,40(sp)
    80000b4a:	7402                	ld	s0,32(sp)
    80000b4c:	64e2                	ld	s1,24(sp)
    80000b4e:	6942                	ld	s2,16(sp)
    80000b50:	69a2                	ld	s3,8(sp)
    80000b52:	6a02                	ld	s4,0(sp)
    80000b54:	6145                	addi	sp,sp,48
    80000b56:	8082                	ret

0000000080000b58 <kinit>:
{
    80000b58:	1141                	addi	sp,sp,-16
    80000b5a:	e406                	sd	ra,8(sp)
    80000b5c:	e022                	sd	s0,0(sp)
    80000b5e:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000b60:	00007597          	auipc	a1,0x7
    80000b64:	52058593          	addi	a1,a1,1312 # 80008080 <digits+0x28>
    80000b68:	00011517          	auipc	a0,0x11
    80000b6c:	dc850513          	addi	a0,a0,-568 # 80011930 <kmem>
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	084080e7          	jalr	132(ra) # 80000bf4 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000b78:	45c5                	li	a1,17
    80000b7a:	05ee                	slli	a1,a1,0x1b
    80000b7c:	0002a517          	auipc	a0,0x2a
    80000b80:	48450513          	addi	a0,a0,1156 # 8002b000 <end>
    80000b84:	00000097          	auipc	ra,0x0
    80000b88:	f8a080e7          	jalr	-118(ra) # 80000b0e <freerange>
}
    80000b8c:	60a2                	ld	ra,8(sp)
    80000b8e:	6402                	ld	s0,0(sp)
    80000b90:	0141                	addi	sp,sp,16
    80000b92:	8082                	ret

0000000080000b94 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b94:	1101                	addi	sp,sp,-32
    80000b96:	ec06                	sd	ra,24(sp)
    80000b98:	e822                	sd	s0,16(sp)
    80000b9a:	e426                	sd	s1,8(sp)
    80000b9c:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000b9e:	00011497          	auipc	s1,0x11
    80000ba2:	d9248493          	addi	s1,s1,-622 # 80011930 <kmem>
    80000ba6:	8526                	mv	a0,s1
    80000ba8:	00000097          	auipc	ra,0x0
    80000bac:	0dc080e7          	jalr	220(ra) # 80000c84 <acquire>
  r = kmem.freelist;
    80000bb0:	6c84                	ld	s1,24(s1)
  if(r)
    80000bb2:	c885                	beqz	s1,80000be2 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000bb4:	609c                	ld	a5,0(s1)
    80000bb6:	00011517          	auipc	a0,0x11
    80000bba:	d7a50513          	addi	a0,a0,-646 # 80011930 <kmem>
    80000bbe:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000bc0:	00000097          	auipc	ra,0x0
    80000bc4:	178080e7          	jalr	376(ra) # 80000d38 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000bc8:	6605                	lui	a2,0x1
    80000bca:	4595                	li	a1,5
    80000bcc:	8526                	mv	a0,s1
    80000bce:	00000097          	auipc	ra,0x0
    80000bd2:	1b2080e7          	jalr	434(ra) # 80000d80 <memset>
  return (void*)r;
}
    80000bd6:	8526                	mv	a0,s1
    80000bd8:	60e2                	ld	ra,24(sp)
    80000bda:	6442                	ld	s0,16(sp)
    80000bdc:	64a2                	ld	s1,8(sp)
    80000bde:	6105                	addi	sp,sp,32
    80000be0:	8082                	ret
  release(&kmem.lock);
    80000be2:	00011517          	auipc	a0,0x11
    80000be6:	d4e50513          	addi	a0,a0,-690 # 80011930 <kmem>
    80000bea:	00000097          	auipc	ra,0x0
    80000bee:	14e080e7          	jalr	334(ra) # 80000d38 <release>
  if(r)
    80000bf2:	b7d5                	j	80000bd6 <kalloc+0x42>

0000000080000bf4 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000bf4:	1141                	addi	sp,sp,-16
    80000bf6:	e422                	sd	s0,8(sp)
    80000bf8:	0800                	addi	s0,sp,16
  lk->name = name;
    80000bfa:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000bfc:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c00:	00053823          	sd	zero,16(a0)
}
    80000c04:	6422                	ld	s0,8(sp)
    80000c06:	0141                	addi	sp,sp,16
    80000c08:	8082                	ret

0000000080000c0a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c0a:	411c                	lw	a5,0(a0)
    80000c0c:	e399                	bnez	a5,80000c12 <holding+0x8>
    80000c0e:	4501                	li	a0,0
  return r;
}
    80000c10:	8082                	ret
{
    80000c12:	1101                	addi	sp,sp,-32
    80000c14:	ec06                	sd	ra,24(sp)
    80000c16:	e822                	sd	s0,16(sp)
    80000c18:	e426                	sd	s1,8(sp)
    80000c1a:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000c1c:	6904                	ld	s1,16(a0)
    80000c1e:	00001097          	auipc	ra,0x1
    80000c22:	e18080e7          	jalr	-488(ra) # 80001a36 <mycpu>
    80000c26:	40a48533          	sub	a0,s1,a0
    80000c2a:	00153513          	seqz	a0,a0
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6105                	addi	sp,sp,32
    80000c36:	8082                	ret

0000000080000c38 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000c38:	1101                	addi	sp,sp,-32
    80000c3a:	ec06                	sd	ra,24(sp)
    80000c3c:	e822                	sd	s0,16(sp)
    80000c3e:	e426                	sd	s1,8(sp)
    80000c40:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c42:	100024f3          	csrr	s1,sstatus
    80000c46:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000c4a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c4c:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	de6080e7          	jalr	-538(ra) # 80001a36 <mycpu>
    80000c58:	5d3c                	lw	a5,120(a0)
    80000c5a:	cf89                	beqz	a5,80000c74 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000c5c:	00001097          	auipc	ra,0x1
    80000c60:	dda080e7          	jalr	-550(ra) # 80001a36 <mycpu>
    80000c64:	5d3c                	lw	a5,120(a0)
    80000c66:	2785                	addiw	a5,a5,1
    80000c68:	dd3c                	sw	a5,120(a0)
}
    80000c6a:	60e2                	ld	ra,24(sp)
    80000c6c:	6442                	ld	s0,16(sp)
    80000c6e:	64a2                	ld	s1,8(sp)
    80000c70:	6105                	addi	sp,sp,32
    80000c72:	8082                	ret
    mycpu()->intena = old;
    80000c74:	00001097          	auipc	ra,0x1
    80000c78:	dc2080e7          	jalr	-574(ra) # 80001a36 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c7c:	8085                	srli	s1,s1,0x1
    80000c7e:	8885                	andi	s1,s1,1
    80000c80:	dd64                	sw	s1,124(a0)
    80000c82:	bfe9                	j	80000c5c <push_off+0x24>

0000000080000c84 <acquire>:
{
    80000c84:	1101                	addi	sp,sp,-32
    80000c86:	ec06                	sd	ra,24(sp)
    80000c88:	e822                	sd	s0,16(sp)
    80000c8a:	e426                	sd	s1,8(sp)
    80000c8c:	1000                	addi	s0,sp,32
    80000c8e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	fa8080e7          	jalr	-88(ra) # 80000c38 <push_off>
  if(holding(lk))
    80000c98:	8526                	mv	a0,s1
    80000c9a:	00000097          	auipc	ra,0x0
    80000c9e:	f70080e7          	jalr	-144(ra) # 80000c0a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ca2:	4705                	li	a4,1
  if(holding(lk))
    80000ca4:	e115                	bnez	a0,80000cc8 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ca6:	87ba                	mv	a5,a4
    80000ca8:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000cac:	2781                	sext.w	a5,a5
    80000cae:	ffe5                	bnez	a5,80000ca6 <acquire+0x22>
  __sync_synchronize();
    80000cb0:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000cb4:	00001097          	auipc	ra,0x1
    80000cb8:	d82080e7          	jalr	-638(ra) # 80001a36 <mycpu>
    80000cbc:	e888                	sd	a0,16(s1)
}
    80000cbe:	60e2                	ld	ra,24(sp)
    80000cc0:	6442                	ld	s0,16(sp)
    80000cc2:	64a2                	ld	s1,8(sp)
    80000cc4:	6105                	addi	sp,sp,32
    80000cc6:	8082                	ret
    panic("acquire");
    80000cc8:	00007517          	auipc	a0,0x7
    80000ccc:	3c050513          	addi	a0,a0,960 # 80008088 <digits+0x30>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	878080e7          	jalr	-1928(ra) # 80000548 <panic>

0000000080000cd8 <pop_off>:

void
pop_off(void)
{
    80000cd8:	1141                	addi	sp,sp,-16
    80000cda:	e406                	sd	ra,8(sp)
    80000cdc:	e022                	sd	s0,0(sp)
    80000cde:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000ce0:	00001097          	auipc	ra,0x1
    80000ce4:	d56080e7          	jalr	-682(ra) # 80001a36 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ce8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000cec:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000cee:	e78d                	bnez	a5,80000d18 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000cf0:	5d3c                	lw	a5,120(a0)
    80000cf2:	02f05b63          	blez	a5,80000d28 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000cf6:	37fd                	addiw	a5,a5,-1
    80000cf8:	0007871b          	sext.w	a4,a5
    80000cfc:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000cfe:	eb09                	bnez	a4,80000d10 <pop_off+0x38>
    80000d00:	5d7c                	lw	a5,124(a0)
    80000d02:	c799                	beqz	a5,80000d10 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d04:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d08:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d0c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000d10:	60a2                	ld	ra,8(sp)
    80000d12:	6402                	ld	s0,0(sp)
    80000d14:	0141                	addi	sp,sp,16
    80000d16:	8082                	ret
    panic("pop_off - interruptible");
    80000d18:	00007517          	auipc	a0,0x7
    80000d1c:	37850513          	addi	a0,a0,888 # 80008090 <digits+0x38>
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	828080e7          	jalr	-2008(ra) # 80000548 <panic>
    panic("pop_off");
    80000d28:	00007517          	auipc	a0,0x7
    80000d2c:	38050513          	addi	a0,a0,896 # 800080a8 <digits+0x50>
    80000d30:	00000097          	auipc	ra,0x0
    80000d34:	818080e7          	jalr	-2024(ra) # 80000548 <panic>

0000000080000d38 <release>:
{
    80000d38:	1101                	addi	sp,sp,-32
    80000d3a:	ec06                	sd	ra,24(sp)
    80000d3c:	e822                	sd	s0,16(sp)
    80000d3e:	e426                	sd	s1,8(sp)
    80000d40:	1000                	addi	s0,sp,32
    80000d42:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000d44:	00000097          	auipc	ra,0x0
    80000d48:	ec6080e7          	jalr	-314(ra) # 80000c0a <holding>
    80000d4c:	c115                	beqz	a0,80000d70 <release+0x38>
  lk->cpu = 0;
    80000d4e:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000d52:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000d56:	0f50000f          	fence	iorw,ow
    80000d5a:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000d5e:	00000097          	auipc	ra,0x0
    80000d62:	f7a080e7          	jalr	-134(ra) # 80000cd8 <pop_off>
}
    80000d66:	60e2                	ld	ra,24(sp)
    80000d68:	6442                	ld	s0,16(sp)
    80000d6a:	64a2                	ld	s1,8(sp)
    80000d6c:	6105                	addi	sp,sp,32
    80000d6e:	8082                	ret
    panic("release");
    80000d70:	00007517          	auipc	a0,0x7
    80000d74:	34050513          	addi	a0,a0,832 # 800080b0 <digits+0x58>
    80000d78:	fffff097          	auipc	ra,0xfffff
    80000d7c:	7d0080e7          	jalr	2000(ra) # 80000548 <panic>

0000000080000d80 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d80:	1141                	addi	sp,sp,-16
    80000d82:	e422                	sd	s0,8(sp)
    80000d84:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d86:	ce09                	beqz	a2,80000da0 <memset+0x20>
    80000d88:	87aa                	mv	a5,a0
    80000d8a:	fff6071b          	addiw	a4,a2,-1
    80000d8e:	1702                	slli	a4,a4,0x20
    80000d90:	9301                	srli	a4,a4,0x20
    80000d92:	0705                	addi	a4,a4,1
    80000d94:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000d96:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d9a:	0785                	addi	a5,a5,1
    80000d9c:	fee79de3          	bne	a5,a4,80000d96 <memset+0x16>
  }
  return dst;
}
    80000da0:	6422                	ld	s0,8(sp)
    80000da2:	0141                	addi	sp,sp,16
    80000da4:	8082                	ret

0000000080000da6 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000da6:	1141                	addi	sp,sp,-16
    80000da8:	e422                	sd	s0,8(sp)
    80000daa:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000dac:	ca05                	beqz	a2,80000ddc <memcmp+0x36>
    80000dae:	fff6069b          	addiw	a3,a2,-1
    80000db2:	1682                	slli	a3,a3,0x20
    80000db4:	9281                	srli	a3,a3,0x20
    80000db6:	0685                	addi	a3,a3,1
    80000db8:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000dba:	00054783          	lbu	a5,0(a0)
    80000dbe:	0005c703          	lbu	a4,0(a1)
    80000dc2:	00e79863          	bne	a5,a4,80000dd2 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000dc6:	0505                	addi	a0,a0,1
    80000dc8:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000dca:	fed518e3          	bne	a0,a3,80000dba <memcmp+0x14>
  }

  return 0;
    80000dce:	4501                	li	a0,0
    80000dd0:	a019                	j	80000dd6 <memcmp+0x30>
      return *s1 - *s2;
    80000dd2:	40e7853b          	subw	a0,a5,a4
}
    80000dd6:	6422                	ld	s0,8(sp)
    80000dd8:	0141                	addi	sp,sp,16
    80000dda:	8082                	ret
  return 0;
    80000ddc:	4501                	li	a0,0
    80000dde:	bfe5                	j	80000dd6 <memcmp+0x30>

0000000080000de0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000de0:	1141                	addi	sp,sp,-16
    80000de2:	e422                	sd	s0,8(sp)
    80000de4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000de6:	00a5f963          	bgeu	a1,a0,80000df8 <memmove+0x18>
    80000dea:	02061713          	slli	a4,a2,0x20
    80000dee:	9301                	srli	a4,a4,0x20
    80000df0:	00e587b3          	add	a5,a1,a4
    80000df4:	02f56563          	bltu	a0,a5,80000e1e <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000df8:	fff6069b          	addiw	a3,a2,-1
    80000dfc:	ce11                	beqz	a2,80000e18 <memmove+0x38>
    80000dfe:	1682                	slli	a3,a3,0x20
    80000e00:	9281                	srli	a3,a3,0x20
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	96ae                	add	a3,a3,a1
    80000e06:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e08:	0585                	addi	a1,a1,1
    80000e0a:	0785                	addi	a5,a5,1
    80000e0c:	fff5c703          	lbu	a4,-1(a1)
    80000e10:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000e14:	fed59ae3          	bne	a1,a3,80000e08 <memmove+0x28>

  return dst;
}
    80000e18:	6422                	ld	s0,8(sp)
    80000e1a:	0141                	addi	sp,sp,16
    80000e1c:	8082                	ret
    d += n;
    80000e1e:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000e20:	fff6069b          	addiw	a3,a2,-1
    80000e24:	da75                	beqz	a2,80000e18 <memmove+0x38>
    80000e26:	02069613          	slli	a2,a3,0x20
    80000e2a:	9201                	srli	a2,a2,0x20
    80000e2c:	fff64613          	not	a2,a2
    80000e30:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000e32:	17fd                	addi	a5,a5,-1
    80000e34:	177d                	addi	a4,a4,-1
    80000e36:	0007c683          	lbu	a3,0(a5)
    80000e3a:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000e3e:	fec79ae3          	bne	a5,a2,80000e32 <memmove+0x52>
    80000e42:	bfd9                	j	80000e18 <memmove+0x38>

0000000080000e44 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000e44:	1141                	addi	sp,sp,-16
    80000e46:	e406                	sd	ra,8(sp)
    80000e48:	e022                	sd	s0,0(sp)
    80000e4a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000e4c:	00000097          	auipc	ra,0x0
    80000e50:	f94080e7          	jalr	-108(ra) # 80000de0 <memmove>
}
    80000e54:	60a2                	ld	ra,8(sp)
    80000e56:	6402                	ld	s0,0(sp)
    80000e58:	0141                	addi	sp,sp,16
    80000e5a:	8082                	ret

0000000080000e5c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000e5c:	1141                	addi	sp,sp,-16
    80000e5e:	e422                	sd	s0,8(sp)
    80000e60:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000e62:	ce11                	beqz	a2,80000e7e <strncmp+0x22>
    80000e64:	00054783          	lbu	a5,0(a0)
    80000e68:	cf89                	beqz	a5,80000e82 <strncmp+0x26>
    80000e6a:	0005c703          	lbu	a4,0(a1)
    80000e6e:	00f71a63          	bne	a4,a5,80000e82 <strncmp+0x26>
    n--, p++, q++;
    80000e72:	367d                	addiw	a2,a2,-1
    80000e74:	0505                	addi	a0,a0,1
    80000e76:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e78:	f675                	bnez	a2,80000e64 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e7a:	4501                	li	a0,0
    80000e7c:	a809                	j	80000e8e <strncmp+0x32>
    80000e7e:	4501                	li	a0,0
    80000e80:	a039                	j	80000e8e <strncmp+0x32>
  if(n == 0)
    80000e82:	ca09                	beqz	a2,80000e94 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e84:	00054503          	lbu	a0,0(a0)
    80000e88:	0005c783          	lbu	a5,0(a1)
    80000e8c:	9d1d                	subw	a0,a0,a5
}
    80000e8e:	6422                	ld	s0,8(sp)
    80000e90:	0141                	addi	sp,sp,16
    80000e92:	8082                	ret
    return 0;
    80000e94:	4501                	li	a0,0
    80000e96:	bfe5                	j	80000e8e <strncmp+0x32>

0000000080000e98 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e9e:	872a                	mv	a4,a0
    80000ea0:	8832                	mv	a6,a2
    80000ea2:	367d                	addiw	a2,a2,-1
    80000ea4:	01005963          	blez	a6,80000eb6 <strncpy+0x1e>
    80000ea8:	0705                	addi	a4,a4,1
    80000eaa:	0005c783          	lbu	a5,0(a1)
    80000eae:	fef70fa3          	sb	a5,-1(a4)
    80000eb2:	0585                	addi	a1,a1,1
    80000eb4:	f7f5                	bnez	a5,80000ea0 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000eb6:	00c05d63          	blez	a2,80000ed0 <strncpy+0x38>
    80000eba:	86ba                	mv	a3,a4
    *s++ = 0;
    80000ebc:	0685                	addi	a3,a3,1
    80000ebe:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000ec2:	fff6c793          	not	a5,a3
    80000ec6:	9fb9                	addw	a5,a5,a4
    80000ec8:	010787bb          	addw	a5,a5,a6
    80000ecc:	fef048e3          	bgtz	a5,80000ebc <strncpy+0x24>
  return os;
}
    80000ed0:	6422                	ld	s0,8(sp)
    80000ed2:	0141                	addi	sp,sp,16
    80000ed4:	8082                	ret

0000000080000ed6 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000ed6:	1141                	addi	sp,sp,-16
    80000ed8:	e422                	sd	s0,8(sp)
    80000eda:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000edc:	02c05363          	blez	a2,80000f02 <safestrcpy+0x2c>
    80000ee0:	fff6069b          	addiw	a3,a2,-1
    80000ee4:	1682                	slli	a3,a3,0x20
    80000ee6:	9281                	srli	a3,a3,0x20
    80000ee8:	96ae                	add	a3,a3,a1
    80000eea:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000eec:	00d58963          	beq	a1,a3,80000efe <safestrcpy+0x28>
    80000ef0:	0585                	addi	a1,a1,1
    80000ef2:	0785                	addi	a5,a5,1
    80000ef4:	fff5c703          	lbu	a4,-1(a1)
    80000ef8:	fee78fa3          	sb	a4,-1(a5)
    80000efc:	fb65                	bnez	a4,80000eec <safestrcpy+0x16>
    ;
  *s = 0;
    80000efe:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f02:	6422                	ld	s0,8(sp)
    80000f04:	0141                	addi	sp,sp,16
    80000f06:	8082                	ret

0000000080000f08 <strlen>:

int
strlen(const char *s)
{
    80000f08:	1141                	addi	sp,sp,-16
    80000f0a:	e422                	sd	s0,8(sp)
    80000f0c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f0e:	00054783          	lbu	a5,0(a0)
    80000f12:	cf91                	beqz	a5,80000f2e <strlen+0x26>
    80000f14:	0505                	addi	a0,a0,1
    80000f16:	87aa                	mv	a5,a0
    80000f18:	4685                	li	a3,1
    80000f1a:	9e89                	subw	a3,a3,a0
    80000f1c:	00f6853b          	addw	a0,a3,a5
    80000f20:	0785                	addi	a5,a5,1
    80000f22:	fff7c703          	lbu	a4,-1(a5)
    80000f26:	fb7d                	bnez	a4,80000f1c <strlen+0x14>
    ;
  return n;
}
    80000f28:	6422                	ld	s0,8(sp)
    80000f2a:	0141                	addi	sp,sp,16
    80000f2c:	8082                	ret
  for(n = 0; s[n]; n++)
    80000f2e:	4501                	li	a0,0
    80000f30:	bfe5                	j	80000f28 <strlen+0x20>

0000000080000f32 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000f32:	1141                	addi	sp,sp,-16
    80000f34:	e406                	sd	ra,8(sp)
    80000f36:	e022                	sd	s0,0(sp)
    80000f38:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000f3a:	00001097          	auipc	ra,0x1
    80000f3e:	aec080e7          	jalr	-1300(ra) # 80001a26 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000f42:	00008717          	auipc	a4,0x8
    80000f46:	0ca70713          	addi	a4,a4,202 # 8000900c <started>
  if(cpuid() == 0){
    80000f4a:	c139                	beqz	a0,80000f90 <main+0x5e>
    while(started == 0)
    80000f4c:	431c                	lw	a5,0(a4)
    80000f4e:	2781                	sext.w	a5,a5
    80000f50:	dff5                	beqz	a5,80000f4c <main+0x1a>
      ;
    __sync_synchronize();
    80000f52:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000f56:	00001097          	auipc	ra,0x1
    80000f5a:	ad0080e7          	jalr	-1328(ra) # 80001a26 <cpuid>
    80000f5e:	85aa                	mv	a1,a0
    80000f60:	00007517          	auipc	a0,0x7
    80000f64:	17050513          	addi	a0,a0,368 # 800080d0 <digits+0x78>
    80000f68:	fffff097          	auipc	ra,0xfffff
    80000f6c:	632080e7          	jalr	1586(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	0d8080e7          	jalr	216(ra) # 80001048 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	744080e7          	jalr	1860(ra) # 800026bc <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f80:	00005097          	auipc	ra,0x5
    80000f84:	dc0080e7          	jalr	-576(ra) # 80005d40 <plicinithart>
  }

  scheduler();        
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	00a080e7          	jalr	10(ra) # 80001f92 <scheduler>
    consoleinit();
    80000f90:	fffff097          	auipc	ra,0xfffff
    80000f94:	4ca080e7          	jalr	1226(ra) # 8000045a <consoleinit>
    printfinit();
    80000f98:	00000097          	auipc	ra,0x0
    80000f9c:	854080e7          	jalr	-1964(ra) # 800007ec <printfinit>
    printf("\n");
    80000fa0:	00007517          	auipc	a0,0x7
    80000fa4:	14050513          	addi	a0,a0,320 # 800080e0 <digits+0x88>
    80000fa8:	fffff097          	auipc	ra,0xfffff
    80000fac:	5f2080e7          	jalr	1522(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80000fb0:	00007517          	auipc	a0,0x7
    80000fb4:	10850513          	addi	a0,a0,264 # 800080b8 <digits+0x60>
    80000fb8:	fffff097          	auipc	ra,0xfffff
    80000fbc:	5e2080e7          	jalr	1506(ra) # 8000059a <printf>
    printf("\n");
    80000fc0:	00007517          	auipc	a0,0x7
    80000fc4:	12050513          	addi	a0,a0,288 # 800080e0 <digits+0x88>
    80000fc8:	fffff097          	auipc	ra,0xfffff
    80000fcc:	5d2080e7          	jalr	1490(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    80000fd0:	00000097          	auipc	ra,0x0
    80000fd4:	b88080e7          	jalr	-1144(ra) # 80000b58 <kinit>
    kvminit();       // create kernel page table
    80000fd8:	00000097          	auipc	ra,0x0
    80000fdc:	2a0080e7          	jalr	672(ra) # 80001278 <kvminit>
    kvminithart();   // turn on paging
    80000fe0:	00000097          	auipc	ra,0x0
    80000fe4:	068080e7          	jalr	104(ra) # 80001048 <kvminithart>
    procinit();      // process table
    80000fe8:	00001097          	auipc	ra,0x1
    80000fec:	96e080e7          	jalr	-1682(ra) # 80001956 <procinit>
    trapinit();      // trap vectors
    80000ff0:	00001097          	auipc	ra,0x1
    80000ff4:	6a4080e7          	jalr	1700(ra) # 80002694 <trapinit>
    trapinithart();  // install kernel trap vector
    80000ff8:	00001097          	auipc	ra,0x1
    80000ffc:	6c4080e7          	jalr	1732(ra) # 800026bc <trapinithart>
    plicinit();      // set up interrupt controller
    80001000:	00005097          	auipc	ra,0x5
    80001004:	d2a080e7          	jalr	-726(ra) # 80005d2a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001008:	00005097          	auipc	ra,0x5
    8000100c:	d38080e7          	jalr	-712(ra) # 80005d40 <plicinithart>
    binit();         // buffer cache
    80001010:	00002097          	auipc	ra,0x2
    80001014:	edc080e7          	jalr	-292(ra) # 80002eec <binit>
    iinit();         // inode cache
    80001018:	00002097          	auipc	ra,0x2
    8000101c:	56c080e7          	jalr	1388(ra) # 80003584 <iinit>
    fileinit();      // file table
    80001020:	00003097          	auipc	ra,0x3
    80001024:	506080e7          	jalr	1286(ra) # 80004526 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80001028:	00005097          	auipc	ra,0x5
    8000102c:	e20080e7          	jalr	-480(ra) # 80005e48 <virtio_disk_init>
    userinit();      // first user process
    80001030:	00001097          	auipc	ra,0x1
    80001034:	cfc080e7          	jalr	-772(ra) # 80001d2c <userinit>
    __sync_synchronize();
    80001038:	0ff0000f          	fence
    started = 1;
    8000103c:	4785                	li	a5,1
    8000103e:	00008717          	auipc	a4,0x8
    80001042:	fcf72723          	sw	a5,-50(a4) # 8000900c <started>
    80001046:	b789                	j	80000f88 <main+0x56>

0000000080001048 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80001048:	1141                	addi	sp,sp,-16
    8000104a:	e422                	sd	s0,8(sp)
    8000104c:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    8000104e:	00008797          	auipc	a5,0x8
    80001052:	fc27b783          	ld	a5,-62(a5) # 80009010 <kernel_pagetable>
    80001056:	83b1                	srli	a5,a5,0xc
    80001058:	577d                	li	a4,-1
    8000105a:	177e                	slli	a4,a4,0x3f
    8000105c:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    8000105e:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80001062:	12000073          	sfence.vma
  sfence_vma();
}
    80001066:	6422                	ld	s0,8(sp)
    80001068:	0141                	addi	sp,sp,16
    8000106a:	8082                	ret

000000008000106c <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    8000106c:	7139                	addi	sp,sp,-64
    8000106e:	fc06                	sd	ra,56(sp)
    80001070:	f822                	sd	s0,48(sp)
    80001072:	f426                	sd	s1,40(sp)
    80001074:	f04a                	sd	s2,32(sp)
    80001076:	ec4e                	sd	s3,24(sp)
    80001078:	e852                	sd	s4,16(sp)
    8000107a:	e456                	sd	s5,8(sp)
    8000107c:	e05a                	sd	s6,0(sp)
    8000107e:	0080                	addi	s0,sp,64
    80001080:	84aa                	mv	s1,a0
    80001082:	89ae                	mv	s3,a1
    80001084:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001086:	57fd                	li	a5,-1
    80001088:	83e9                	srli	a5,a5,0x1a
    8000108a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000108c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000108e:	04b7f263          	bgeu	a5,a1,800010d2 <walk+0x66>
    panic("walk");
    80001092:	00007517          	auipc	a0,0x7
    80001096:	05650513          	addi	a0,a0,86 # 800080e8 <digits+0x90>
    8000109a:	fffff097          	auipc	ra,0xfffff
    8000109e:	4ae080e7          	jalr	1198(ra) # 80000548 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    800010a2:	060a8663          	beqz	s5,8000110e <walk+0xa2>
    800010a6:	00000097          	auipc	ra,0x0
    800010aa:	aee080e7          	jalr	-1298(ra) # 80000b94 <kalloc>
    800010ae:	84aa                	mv	s1,a0
    800010b0:	c529                	beqz	a0,800010fa <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800010b2:	6605                	lui	a2,0x1
    800010b4:	4581                	li	a1,0
    800010b6:	00000097          	auipc	ra,0x0
    800010ba:	cca080e7          	jalr	-822(ra) # 80000d80 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800010be:	00c4d793          	srli	a5,s1,0xc
    800010c2:	07aa                	slli	a5,a5,0xa
    800010c4:	0017e793          	ori	a5,a5,1
    800010c8:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    800010cc:	3a5d                	addiw	s4,s4,-9
    800010ce:	036a0063          	beq	s4,s6,800010ee <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800010d2:	0149d933          	srl	s2,s3,s4
    800010d6:	1ff97913          	andi	s2,s2,511
    800010da:	090e                	slli	s2,s2,0x3
    800010dc:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800010de:	00093483          	ld	s1,0(s2)
    800010e2:	0014f793          	andi	a5,s1,1
    800010e6:	dfd5                	beqz	a5,800010a2 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800010e8:	80a9                	srli	s1,s1,0xa
    800010ea:	04b2                	slli	s1,s1,0xc
    800010ec:	b7c5                	j	800010cc <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800010ee:	00c9d513          	srli	a0,s3,0xc
    800010f2:	1ff57513          	andi	a0,a0,511
    800010f6:	050e                	slli	a0,a0,0x3
    800010f8:	9526                	add	a0,a0,s1
}
    800010fa:	70e2                	ld	ra,56(sp)
    800010fc:	7442                	ld	s0,48(sp)
    800010fe:	74a2                	ld	s1,40(sp)
    80001100:	7902                	ld	s2,32(sp)
    80001102:	69e2                	ld	s3,24(sp)
    80001104:	6a42                	ld	s4,16(sp)
    80001106:	6aa2                	ld	s5,8(sp)
    80001108:	6b02                	ld	s6,0(sp)
    8000110a:	6121                	addi	sp,sp,64
    8000110c:	8082                	ret
        return 0;
    8000110e:	4501                	li	a0,0
    80001110:	b7ed                	j	800010fa <walk+0x8e>

0000000080001112 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    80001112:	57fd                	li	a5,-1
    80001114:	83e9                	srli	a5,a5,0x1a
    80001116:	00b7f463          	bgeu	a5,a1,8000111e <walkaddr+0xc>
    return 0;
    8000111a:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    8000111c:	8082                	ret
{
    8000111e:	1141                	addi	sp,sp,-16
    80001120:	e406                	sd	ra,8(sp)
    80001122:	e022                	sd	s0,0(sp)
    80001124:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001126:	4601                	li	a2,0
    80001128:	00000097          	auipc	ra,0x0
    8000112c:	f44080e7          	jalr	-188(ra) # 8000106c <walk>
  if(pte == 0)
    80001130:	c105                	beqz	a0,80001150 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    80001132:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    80001134:	0117f693          	andi	a3,a5,17
    80001138:	4745                	li	a4,17
    return 0;
    8000113a:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    8000113c:	00e68663          	beq	a3,a4,80001148 <walkaddr+0x36>
}
    80001140:	60a2                	ld	ra,8(sp)
    80001142:	6402                	ld	s0,0(sp)
    80001144:	0141                	addi	sp,sp,16
    80001146:	8082                	ret
  pa = PTE2PA(*pte);
    80001148:	00a7d513          	srli	a0,a5,0xa
    8000114c:	0532                	slli	a0,a0,0xc
  return pa;
    8000114e:	bfcd                	j	80001140 <walkaddr+0x2e>
    return 0;
    80001150:	4501                	li	a0,0
    80001152:	b7fd                	j	80001140 <walkaddr+0x2e>

0000000080001154 <kvmpa>:
// a physical address. only needed for
// addresses on the stack.
// assumes va is page aligned.
uint64
kvmpa(uint64 va)
{
    80001154:	1101                	addi	sp,sp,-32
    80001156:	ec06                	sd	ra,24(sp)
    80001158:	e822                	sd	s0,16(sp)
    8000115a:	e426                	sd	s1,8(sp)
    8000115c:	1000                	addi	s0,sp,32
    8000115e:	85aa                	mv	a1,a0
  uint64 off = va % PGSIZE;
    80001160:	1552                	slli	a0,a0,0x34
    80001162:	03455493          	srli	s1,a0,0x34
  pte_t *pte;
  uint64 pa;
  
  pte = walk(kernel_pagetable, va, 0);
    80001166:	4601                	li	a2,0
    80001168:	00008517          	auipc	a0,0x8
    8000116c:	ea853503          	ld	a0,-344(a0) # 80009010 <kernel_pagetable>
    80001170:	00000097          	auipc	ra,0x0
    80001174:	efc080e7          	jalr	-260(ra) # 8000106c <walk>
  if(pte == 0)
    80001178:	cd09                	beqz	a0,80001192 <kvmpa+0x3e>
    panic("kvmpa");
  if((*pte & PTE_V) == 0)
    8000117a:	6108                	ld	a0,0(a0)
    8000117c:	00157793          	andi	a5,a0,1
    80001180:	c38d                	beqz	a5,800011a2 <kvmpa+0x4e>
    panic("kvmpa");
  pa = PTE2PA(*pte);
    80001182:	8129                	srli	a0,a0,0xa
    80001184:	0532                	slli	a0,a0,0xc
  return pa+off;
}
    80001186:	9526                	add	a0,a0,s1
    80001188:	60e2                	ld	ra,24(sp)
    8000118a:	6442                	ld	s0,16(sp)
    8000118c:	64a2                	ld	s1,8(sp)
    8000118e:	6105                	addi	sp,sp,32
    80001190:	8082                	ret
    panic("kvmpa");
    80001192:	00007517          	auipc	a0,0x7
    80001196:	f5e50513          	addi	a0,a0,-162 # 800080f0 <digits+0x98>
    8000119a:	fffff097          	auipc	ra,0xfffff
    8000119e:	3ae080e7          	jalr	942(ra) # 80000548 <panic>
    panic("kvmpa");
    800011a2:	00007517          	auipc	a0,0x7
    800011a6:	f4e50513          	addi	a0,a0,-178 # 800080f0 <digits+0x98>
    800011aa:	fffff097          	auipc	ra,0xfffff
    800011ae:	39e080e7          	jalr	926(ra) # 80000548 <panic>

00000000800011b2 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011b2:	715d                	addi	sp,sp,-80
    800011b4:	e486                	sd	ra,72(sp)
    800011b6:	e0a2                	sd	s0,64(sp)
    800011b8:	fc26                	sd	s1,56(sp)
    800011ba:	f84a                	sd	s2,48(sp)
    800011bc:	f44e                	sd	s3,40(sp)
    800011be:	f052                	sd	s4,32(sp)
    800011c0:	ec56                	sd	s5,24(sp)
    800011c2:	e85a                	sd	s6,16(sp)
    800011c4:	e45e                	sd	s7,8(sp)
    800011c6:	0880                	addi	s0,sp,80
    800011c8:	8aaa                	mv	s5,a0
    800011ca:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011cc:	777d                	lui	a4,0xfffff
    800011ce:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800011d2:	167d                	addi	a2,a2,-1
    800011d4:	00b609b3          	add	s3,a2,a1
    800011d8:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800011dc:	893e                	mv	s2,a5
    800011de:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800011e2:	6b85                	lui	s7,0x1
    800011e4:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800011e8:	4605                	li	a2,1
    800011ea:	85ca                	mv	a1,s2
    800011ec:	8556                	mv	a0,s5
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	e7e080e7          	jalr	-386(ra) # 8000106c <walk>
    800011f6:	c51d                	beqz	a0,80001224 <mappages+0x72>
    if(*pte & PTE_V)
    800011f8:	611c                	ld	a5,0(a0)
    800011fa:	8b85                	andi	a5,a5,1
    800011fc:	ef81                	bnez	a5,80001214 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800011fe:	80b1                	srli	s1,s1,0xc
    80001200:	04aa                	slli	s1,s1,0xa
    80001202:	0164e4b3          	or	s1,s1,s6
    80001206:	0014e493          	ori	s1,s1,1
    8000120a:	e104                	sd	s1,0(a0)
    if(a == last)
    8000120c:	03390863          	beq	s2,s3,8000123c <mappages+0x8a>
    a += PGSIZE;
    80001210:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001212:	bfc9                	j	800011e4 <mappages+0x32>
      panic("remap");
    80001214:	00007517          	auipc	a0,0x7
    80001218:	ee450513          	addi	a0,a0,-284 # 800080f8 <digits+0xa0>
    8000121c:	fffff097          	auipc	ra,0xfffff
    80001220:	32c080e7          	jalr	812(ra) # 80000548 <panic>
      return -1;
    80001224:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001226:	60a6                	ld	ra,72(sp)
    80001228:	6406                	ld	s0,64(sp)
    8000122a:	74e2                	ld	s1,56(sp)
    8000122c:	7942                	ld	s2,48(sp)
    8000122e:	79a2                	ld	s3,40(sp)
    80001230:	7a02                	ld	s4,32(sp)
    80001232:	6ae2                	ld	s5,24(sp)
    80001234:	6b42                	ld	s6,16(sp)
    80001236:	6ba2                	ld	s7,8(sp)
    80001238:	6161                	addi	sp,sp,80
    8000123a:	8082                	ret
  return 0;
    8000123c:	4501                	li	a0,0
    8000123e:	b7e5                	j	80001226 <mappages+0x74>

0000000080001240 <kvmmap>:
{
    80001240:	1141                	addi	sp,sp,-16
    80001242:	e406                	sd	ra,8(sp)
    80001244:	e022                	sd	s0,0(sp)
    80001246:	0800                	addi	s0,sp,16
    80001248:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    8000124a:	86ae                	mv	a3,a1
    8000124c:	85aa                	mv	a1,a0
    8000124e:	00008517          	auipc	a0,0x8
    80001252:	dc253503          	ld	a0,-574(a0) # 80009010 <kernel_pagetable>
    80001256:	00000097          	auipc	ra,0x0
    8000125a:	f5c080e7          	jalr	-164(ra) # 800011b2 <mappages>
    8000125e:	e509                	bnez	a0,80001268 <kvmmap+0x28>
}
    80001260:	60a2                	ld	ra,8(sp)
    80001262:	6402                	ld	s0,0(sp)
    80001264:	0141                	addi	sp,sp,16
    80001266:	8082                	ret
    panic("kvmmap");
    80001268:	00007517          	auipc	a0,0x7
    8000126c:	e9850513          	addi	a0,a0,-360 # 80008100 <digits+0xa8>
    80001270:	fffff097          	auipc	ra,0xfffff
    80001274:	2d8080e7          	jalr	728(ra) # 80000548 <panic>

0000000080001278 <kvminit>:
{
    80001278:	1101                	addi	sp,sp,-32
    8000127a:	ec06                	sd	ra,24(sp)
    8000127c:	e822                	sd	s0,16(sp)
    8000127e:	e426                	sd	s1,8(sp)
    80001280:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    80001282:	00000097          	auipc	ra,0x0
    80001286:	912080e7          	jalr	-1774(ra) # 80000b94 <kalloc>
    8000128a:	00008797          	auipc	a5,0x8
    8000128e:	d8a7b323          	sd	a0,-634(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    80001292:	6605                	lui	a2,0x1
    80001294:	4581                	li	a1,0
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	aea080e7          	jalr	-1302(ra) # 80000d80 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000129e:	4699                	li	a3,6
    800012a0:	6605                	lui	a2,0x1
    800012a2:	100005b7          	lui	a1,0x10000
    800012a6:	10000537          	lui	a0,0x10000
    800012aa:	00000097          	auipc	ra,0x0
    800012ae:	f96080e7          	jalr	-106(ra) # 80001240 <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012b2:	4699                	li	a3,6
    800012b4:	6605                	lui	a2,0x1
    800012b6:	100015b7          	lui	a1,0x10001
    800012ba:	10001537          	lui	a0,0x10001
    800012be:	00000097          	auipc	ra,0x0
    800012c2:	f82080e7          	jalr	-126(ra) # 80001240 <kvmmap>
  kvmmap(CLINT, CLINT, 0x10000, PTE_R | PTE_W);
    800012c6:	4699                	li	a3,6
    800012c8:	6641                	lui	a2,0x10
    800012ca:	020005b7          	lui	a1,0x2000
    800012ce:	02000537          	lui	a0,0x2000
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	f6e080e7          	jalr	-146(ra) # 80001240 <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012da:	4699                	li	a3,6
    800012dc:	00400637          	lui	a2,0x400
    800012e0:	0c0005b7          	lui	a1,0xc000
    800012e4:	0c000537          	lui	a0,0xc000
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f58080e7          	jalr	-168(ra) # 80001240 <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800012f0:	00007497          	auipc	s1,0x7
    800012f4:	d1048493          	addi	s1,s1,-752 # 80008000 <etext>
    800012f8:	46a9                	li	a3,10
    800012fa:	80007617          	auipc	a2,0x80007
    800012fe:	d0660613          	addi	a2,a2,-762 # 8000 <_entry-0x7fff8000>
    80001302:	4585                	li	a1,1
    80001304:	05fe                	slli	a1,a1,0x1f
    80001306:	852e                	mv	a0,a1
    80001308:	00000097          	auipc	ra,0x0
    8000130c:	f38080e7          	jalr	-200(ra) # 80001240 <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001310:	4699                	li	a3,6
    80001312:	4645                	li	a2,17
    80001314:	066e                	slli	a2,a2,0x1b
    80001316:	8e05                	sub	a2,a2,s1
    80001318:	85a6                	mv	a1,s1
    8000131a:	8526                	mv	a0,s1
    8000131c:	00000097          	auipc	ra,0x0
    80001320:	f24080e7          	jalr	-220(ra) # 80001240 <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001324:	46a9                	li	a3,10
    80001326:	6605                	lui	a2,0x1
    80001328:	00006597          	auipc	a1,0x6
    8000132c:	cd858593          	addi	a1,a1,-808 # 80007000 <_trampoline>
    80001330:	04000537          	lui	a0,0x4000
    80001334:	157d                	addi	a0,a0,-1
    80001336:	0532                	slli	a0,a0,0xc
    80001338:	00000097          	auipc	ra,0x0
    8000133c:	f08080e7          	jalr	-248(ra) # 80001240 <kvmmap>
}
    80001340:	60e2                	ld	ra,24(sp)
    80001342:	6442                	ld	s0,16(sp)
    80001344:	64a2                	ld	s1,8(sp)
    80001346:	6105                	addi	sp,sp,32
    80001348:	8082                	ret

000000008000134a <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    8000134a:	715d                	addi	sp,sp,-80
    8000134c:	e486                	sd	ra,72(sp)
    8000134e:	e0a2                	sd	s0,64(sp)
    80001350:	fc26                	sd	s1,56(sp)
    80001352:	f84a                	sd	s2,48(sp)
    80001354:	f44e                	sd	s3,40(sp)
    80001356:	f052                	sd	s4,32(sp)
    80001358:	ec56                	sd	s5,24(sp)
    8000135a:	e85a                	sd	s6,16(sp)
    8000135c:	e45e                	sd	s7,8(sp)
    8000135e:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    80001360:	03459793          	slli	a5,a1,0x34
    80001364:	e795                	bnez	a5,80001390 <uvmunmap+0x46>
    80001366:	8a2a                	mv	s4,a0
    80001368:	892e                	mv	s2,a1
    8000136a:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000136c:	0632                	slli	a2,a2,0xc
    8000136e:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001372:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001374:	6b05                	lui	s6,0x1
    80001376:	0735e863          	bltu	a1,s3,800013e6 <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    8000137a:	60a6                	ld	ra,72(sp)
    8000137c:	6406                	ld	s0,64(sp)
    8000137e:	74e2                	ld	s1,56(sp)
    80001380:	7942                	ld	s2,48(sp)
    80001382:	79a2                	ld	s3,40(sp)
    80001384:	7a02                	ld	s4,32(sp)
    80001386:	6ae2                	ld	s5,24(sp)
    80001388:	6b42                	ld	s6,16(sp)
    8000138a:	6ba2                	ld	s7,8(sp)
    8000138c:	6161                	addi	sp,sp,80
    8000138e:	8082                	ret
    panic("uvmunmap: not aligned");
    80001390:	00007517          	auipc	a0,0x7
    80001394:	d7850513          	addi	a0,a0,-648 # 80008108 <digits+0xb0>
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	1b0080e7          	jalr	432(ra) # 80000548 <panic>
      panic("uvmunmap: walk");
    800013a0:	00007517          	auipc	a0,0x7
    800013a4:	d8050513          	addi	a0,a0,-640 # 80008120 <digits+0xc8>
    800013a8:	fffff097          	auipc	ra,0xfffff
    800013ac:	1a0080e7          	jalr	416(ra) # 80000548 <panic>
      panic("uvmunmap: not mapped");
    800013b0:	00007517          	auipc	a0,0x7
    800013b4:	d8050513          	addi	a0,a0,-640 # 80008130 <digits+0xd8>
    800013b8:	fffff097          	auipc	ra,0xfffff
    800013bc:	190080e7          	jalr	400(ra) # 80000548 <panic>
      panic("uvmunmap: not a leaf");
    800013c0:	00007517          	auipc	a0,0x7
    800013c4:	d8850513          	addi	a0,a0,-632 # 80008148 <digits+0xf0>
    800013c8:	fffff097          	auipc	ra,0xfffff
    800013cc:	180080e7          	jalr	384(ra) # 80000548 <panic>
      uint64 pa = PTE2PA(*pte);
    800013d0:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    800013d2:	0532                	slli	a0,a0,0xc
    800013d4:	fffff097          	auipc	ra,0xfffff
    800013d8:	6c4080e7          	jalr	1732(ra) # 80000a98 <kfree>
    *pte = 0;
    800013dc:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013e0:	995a                	add	s2,s2,s6
    800013e2:	f9397ce3          	bgeu	s2,s3,8000137a <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800013e6:	4601                	li	a2,0
    800013e8:	85ca                	mv	a1,s2
    800013ea:	8552                	mv	a0,s4
    800013ec:	00000097          	auipc	ra,0x0
    800013f0:	c80080e7          	jalr	-896(ra) # 8000106c <walk>
    800013f4:	84aa                	mv	s1,a0
    800013f6:	d54d                	beqz	a0,800013a0 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    800013f8:	6108                	ld	a0,0(a0)
    800013fa:	00157793          	andi	a5,a0,1
    800013fe:	dbcd                	beqz	a5,800013b0 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001400:	3ff57793          	andi	a5,a0,1023
    80001404:	fb778ee3          	beq	a5,s7,800013c0 <uvmunmap+0x76>
    if(do_free){
    80001408:	fc0a8ae3          	beqz	s5,800013dc <uvmunmap+0x92>
    8000140c:	b7d1                	j	800013d0 <uvmunmap+0x86>

000000008000140e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000140e:	1101                	addi	sp,sp,-32
    80001410:	ec06                	sd	ra,24(sp)
    80001412:	e822                	sd	s0,16(sp)
    80001414:	e426                	sd	s1,8(sp)
    80001416:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001418:	fffff097          	auipc	ra,0xfffff
    8000141c:	77c080e7          	jalr	1916(ra) # 80000b94 <kalloc>
    80001420:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001422:	c519                	beqz	a0,80001430 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001424:	6605                	lui	a2,0x1
    80001426:	4581                	li	a1,0
    80001428:	00000097          	auipc	ra,0x0
    8000142c:	958080e7          	jalr	-1704(ra) # 80000d80 <memset>
  return pagetable;
}
    80001430:	8526                	mv	a0,s1
    80001432:	60e2                	ld	ra,24(sp)
    80001434:	6442                	ld	s0,16(sp)
    80001436:	64a2                	ld	s1,8(sp)
    80001438:	6105                	addi	sp,sp,32
    8000143a:	8082                	ret

000000008000143c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000143c:	7179                	addi	sp,sp,-48
    8000143e:	f406                	sd	ra,40(sp)
    80001440:	f022                	sd	s0,32(sp)
    80001442:	ec26                	sd	s1,24(sp)
    80001444:	e84a                	sd	s2,16(sp)
    80001446:	e44e                	sd	s3,8(sp)
    80001448:	e052                	sd	s4,0(sp)
    8000144a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000144c:	6785                	lui	a5,0x1
    8000144e:	04f67863          	bgeu	a2,a5,8000149e <uvminit+0x62>
    80001452:	8a2a                	mv	s4,a0
    80001454:	89ae                	mv	s3,a1
    80001456:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	73c080e7          	jalr	1852(ra) # 80000b94 <kalloc>
    80001460:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	91a080e7          	jalr	-1766(ra) # 80000d80 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    8000146e:	4779                	li	a4,30
    80001470:	86ca                	mv	a3,s2
    80001472:	6605                	lui	a2,0x1
    80001474:	4581                	li	a1,0
    80001476:	8552                	mv	a0,s4
    80001478:	00000097          	auipc	ra,0x0
    8000147c:	d3a080e7          	jalr	-710(ra) # 800011b2 <mappages>
  memmove(mem, src, sz);
    80001480:	8626                	mv	a2,s1
    80001482:	85ce                	mv	a1,s3
    80001484:	854a                	mv	a0,s2
    80001486:	00000097          	auipc	ra,0x0
    8000148a:	95a080e7          	jalr	-1702(ra) # 80000de0 <memmove>
}
    8000148e:	70a2                	ld	ra,40(sp)
    80001490:	7402                	ld	s0,32(sp)
    80001492:	64e2                	ld	s1,24(sp)
    80001494:	6942                	ld	s2,16(sp)
    80001496:	69a2                	ld	s3,8(sp)
    80001498:	6a02                	ld	s4,0(sp)
    8000149a:	6145                	addi	sp,sp,48
    8000149c:	8082                	ret
    panic("inituvm: more than a page");
    8000149e:	00007517          	auipc	a0,0x7
    800014a2:	cc250513          	addi	a0,a0,-830 # 80008160 <digits+0x108>
    800014a6:	fffff097          	auipc	ra,0xfffff
    800014aa:	0a2080e7          	jalr	162(ra) # 80000548 <panic>

00000000800014ae <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ae:	1101                	addi	sp,sp,-32
    800014b0:	ec06                	sd	ra,24(sp)
    800014b2:	e822                	sd	s0,16(sp)
    800014b4:	e426                	sd	s1,8(sp)
    800014b6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014b8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014ba:	00b67d63          	bgeu	a2,a1,800014d4 <uvmdealloc+0x26>
    800014be:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800014c0:	6785                	lui	a5,0x1
    800014c2:	17fd                	addi	a5,a5,-1
    800014c4:	00f60733          	add	a4,a2,a5
    800014c8:	767d                	lui	a2,0xfffff
    800014ca:	8f71                	and	a4,a4,a2
    800014cc:	97ae                	add	a5,a5,a1
    800014ce:	8ff1                	and	a5,a5,a2
    800014d0:	00f76863          	bltu	a4,a5,800014e0 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800014d4:	8526                	mv	a0,s1
    800014d6:	60e2                	ld	ra,24(sp)
    800014d8:	6442                	ld	s0,16(sp)
    800014da:	64a2                	ld	s1,8(sp)
    800014dc:	6105                	addi	sp,sp,32
    800014de:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800014e0:	8f99                	sub	a5,a5,a4
    800014e2:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800014e4:	4685                	li	a3,1
    800014e6:	0007861b          	sext.w	a2,a5
    800014ea:	85ba                	mv	a1,a4
    800014ec:	00000097          	auipc	ra,0x0
    800014f0:	e5e080e7          	jalr	-418(ra) # 8000134a <uvmunmap>
    800014f4:	b7c5                	j	800014d4 <uvmdealloc+0x26>

00000000800014f6 <uvmalloc>:
  if(newsz < oldsz)
    800014f6:	0ab66163          	bltu	a2,a1,80001598 <uvmalloc+0xa2>
{
    800014fa:	7139                	addi	sp,sp,-64
    800014fc:	fc06                	sd	ra,56(sp)
    800014fe:	f822                	sd	s0,48(sp)
    80001500:	f426                	sd	s1,40(sp)
    80001502:	f04a                	sd	s2,32(sp)
    80001504:	ec4e                	sd	s3,24(sp)
    80001506:	e852                	sd	s4,16(sp)
    80001508:	e456                	sd	s5,8(sp)
    8000150a:	0080                	addi	s0,sp,64
    8000150c:	8aaa                	mv	s5,a0
    8000150e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001510:	6985                	lui	s3,0x1
    80001512:	19fd                	addi	s3,s3,-1
    80001514:	95ce                	add	a1,a1,s3
    80001516:	79fd                	lui	s3,0xfffff
    80001518:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000151c:	08c9f063          	bgeu	s3,a2,8000159c <uvmalloc+0xa6>
    80001520:	894e                	mv	s2,s3
    mem = kalloc();
    80001522:	fffff097          	auipc	ra,0xfffff
    80001526:	672080e7          	jalr	1650(ra) # 80000b94 <kalloc>
    8000152a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000152c:	c51d                	beqz	a0,8000155a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000152e:	6605                	lui	a2,0x1
    80001530:	4581                	li	a1,0
    80001532:	00000097          	auipc	ra,0x0
    80001536:	84e080e7          	jalr	-1970(ra) # 80000d80 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000153a:	4779                	li	a4,30
    8000153c:	86a6                	mv	a3,s1
    8000153e:	6605                	lui	a2,0x1
    80001540:	85ca                	mv	a1,s2
    80001542:	8556                	mv	a0,s5
    80001544:	00000097          	auipc	ra,0x0
    80001548:	c6e080e7          	jalr	-914(ra) # 800011b2 <mappages>
    8000154c:	e905                	bnez	a0,8000157c <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000154e:	6785                	lui	a5,0x1
    80001550:	993e                	add	s2,s2,a5
    80001552:	fd4968e3          	bltu	s2,s4,80001522 <uvmalloc+0x2c>
  return newsz;
    80001556:	8552                	mv	a0,s4
    80001558:	a809                	j	8000156a <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000155a:	864e                	mv	a2,s3
    8000155c:	85ca                	mv	a1,s2
    8000155e:	8556                	mv	a0,s5
    80001560:	00000097          	auipc	ra,0x0
    80001564:	f4e080e7          	jalr	-178(ra) # 800014ae <uvmdealloc>
      return 0;
    80001568:	4501                	li	a0,0
}
    8000156a:	70e2                	ld	ra,56(sp)
    8000156c:	7442                	ld	s0,48(sp)
    8000156e:	74a2                	ld	s1,40(sp)
    80001570:	7902                	ld	s2,32(sp)
    80001572:	69e2                	ld	s3,24(sp)
    80001574:	6a42                	ld	s4,16(sp)
    80001576:	6aa2                	ld	s5,8(sp)
    80001578:	6121                	addi	sp,sp,64
    8000157a:	8082                	ret
      kfree(mem);
    8000157c:	8526                	mv	a0,s1
    8000157e:	fffff097          	auipc	ra,0xfffff
    80001582:	51a080e7          	jalr	1306(ra) # 80000a98 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001586:	864e                	mv	a2,s3
    80001588:	85ca                	mv	a1,s2
    8000158a:	8556                	mv	a0,s5
    8000158c:	00000097          	auipc	ra,0x0
    80001590:	f22080e7          	jalr	-222(ra) # 800014ae <uvmdealloc>
      return 0;
    80001594:	4501                	li	a0,0
    80001596:	bfd1                	j	8000156a <uvmalloc+0x74>
    return oldsz;
    80001598:	852e                	mv	a0,a1
}
    8000159a:	8082                	ret
  return newsz;
    8000159c:	8532                	mv	a0,a2
    8000159e:	b7f1                	j	8000156a <uvmalloc+0x74>

00000000800015a0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015a0:	7179                	addi	sp,sp,-48
    800015a2:	f406                	sd	ra,40(sp)
    800015a4:	f022                	sd	s0,32(sp)
    800015a6:	ec26                	sd	s1,24(sp)
    800015a8:	e84a                	sd	s2,16(sp)
    800015aa:	e44e                	sd	s3,8(sp)
    800015ac:	e052                	sd	s4,0(sp)
    800015ae:	1800                	addi	s0,sp,48
    800015b0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015b2:	84aa                	mv	s1,a0
    800015b4:	6905                	lui	s2,0x1
    800015b6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015b8:	4985                	li	s3,1
    800015ba:	a821                	j	800015d2 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015bc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015be:	0532                	slli	a0,a0,0xc
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	fe0080e7          	jalr	-32(ra) # 800015a0 <freewalk>
      pagetable[i] = 0;
    800015c8:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800015cc:	04a1                	addi	s1,s1,8
    800015ce:	03248163          	beq	s1,s2,800015f0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800015d2:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015d4:	00f57793          	andi	a5,a0,15
    800015d8:	ff3782e3          	beq	a5,s3,800015bc <freewalk+0x1c>
    } else if(pte & PTE_V){
    800015dc:	8905                	andi	a0,a0,1
    800015de:	d57d                	beqz	a0,800015cc <freewalk+0x2c>
      panic("freewalk: leaf");
    800015e0:	00007517          	auipc	a0,0x7
    800015e4:	ba050513          	addi	a0,a0,-1120 # 80008180 <digits+0x128>
    800015e8:	fffff097          	auipc	ra,0xfffff
    800015ec:	f60080e7          	jalr	-160(ra) # 80000548 <panic>
    }
  }
  kfree((void*)pagetable);
    800015f0:	8552                	mv	a0,s4
    800015f2:	fffff097          	auipc	ra,0xfffff
    800015f6:	4a6080e7          	jalr	1190(ra) # 80000a98 <kfree>
}
    800015fa:	70a2                	ld	ra,40(sp)
    800015fc:	7402                	ld	s0,32(sp)
    800015fe:	64e2                	ld	s1,24(sp)
    80001600:	6942                	ld	s2,16(sp)
    80001602:	69a2                	ld	s3,8(sp)
    80001604:	6a02                	ld	s4,0(sp)
    80001606:	6145                	addi	sp,sp,48
    80001608:	8082                	ret

000000008000160a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000160a:	1101                	addi	sp,sp,-32
    8000160c:	ec06                	sd	ra,24(sp)
    8000160e:	e822                	sd	s0,16(sp)
    80001610:	e426                	sd	s1,8(sp)
    80001612:	1000                	addi	s0,sp,32
    80001614:	84aa                	mv	s1,a0
  if(sz > 0)
    80001616:	e999                	bnez	a1,8000162c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001618:	8526                	mv	a0,s1
    8000161a:	00000097          	auipc	ra,0x0
    8000161e:	f86080e7          	jalr	-122(ra) # 800015a0 <freewalk>
}
    80001622:	60e2                	ld	ra,24(sp)
    80001624:	6442                	ld	s0,16(sp)
    80001626:	64a2                	ld	s1,8(sp)
    80001628:	6105                	addi	sp,sp,32
    8000162a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000162c:	6605                	lui	a2,0x1
    8000162e:	167d                	addi	a2,a2,-1
    80001630:	962e                	add	a2,a2,a1
    80001632:	4685                	li	a3,1
    80001634:	8231                	srli	a2,a2,0xc
    80001636:	4581                	li	a1,0
    80001638:	00000097          	auipc	ra,0x0
    8000163c:	d12080e7          	jalr	-750(ra) # 8000134a <uvmunmap>
    80001640:	bfe1                	j	80001618 <uvmfree+0xe>

0000000080001642 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001642:	c679                	beqz	a2,80001710 <uvmcopy+0xce>
{
    80001644:	715d                	addi	sp,sp,-80
    80001646:	e486                	sd	ra,72(sp)
    80001648:	e0a2                	sd	s0,64(sp)
    8000164a:	fc26                	sd	s1,56(sp)
    8000164c:	f84a                	sd	s2,48(sp)
    8000164e:	f44e                	sd	s3,40(sp)
    80001650:	f052                	sd	s4,32(sp)
    80001652:	ec56                	sd	s5,24(sp)
    80001654:	e85a                	sd	s6,16(sp)
    80001656:	e45e                	sd	s7,8(sp)
    80001658:	0880                	addi	s0,sp,80
    8000165a:	8b2a                	mv	s6,a0
    8000165c:	8aae                	mv	s5,a1
    8000165e:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001660:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001662:	4601                	li	a2,0
    80001664:	85ce                	mv	a1,s3
    80001666:	855a                	mv	a0,s6
    80001668:	00000097          	auipc	ra,0x0
    8000166c:	a04080e7          	jalr	-1532(ra) # 8000106c <walk>
    80001670:	c531                	beqz	a0,800016bc <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001672:	6118                	ld	a4,0(a0)
    80001674:	00177793          	andi	a5,a4,1
    80001678:	cbb1                	beqz	a5,800016cc <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    8000167a:	00a75593          	srli	a1,a4,0xa
    8000167e:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001682:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    80001686:	fffff097          	auipc	ra,0xfffff
    8000168a:	50e080e7          	jalr	1294(ra) # 80000b94 <kalloc>
    8000168e:	892a                	mv	s2,a0
    80001690:	c939                	beqz	a0,800016e6 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001692:	6605                	lui	a2,0x1
    80001694:	85de                	mv	a1,s7
    80001696:	fffff097          	auipc	ra,0xfffff
    8000169a:	74a080e7          	jalr	1866(ra) # 80000de0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000169e:	8726                	mv	a4,s1
    800016a0:	86ca                	mv	a3,s2
    800016a2:	6605                	lui	a2,0x1
    800016a4:	85ce                	mv	a1,s3
    800016a6:	8556                	mv	a0,s5
    800016a8:	00000097          	auipc	ra,0x0
    800016ac:	b0a080e7          	jalr	-1270(ra) # 800011b2 <mappages>
    800016b0:	e515                	bnez	a0,800016dc <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800016b2:	6785                	lui	a5,0x1
    800016b4:	99be                	add	s3,s3,a5
    800016b6:	fb49e6e3          	bltu	s3,s4,80001662 <uvmcopy+0x20>
    800016ba:	a081                	j	800016fa <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800016bc:	00007517          	auipc	a0,0x7
    800016c0:	ad450513          	addi	a0,a0,-1324 # 80008190 <digits+0x138>
    800016c4:	fffff097          	auipc	ra,0xfffff
    800016c8:	e84080e7          	jalr	-380(ra) # 80000548 <panic>
      panic("uvmcopy: page not present");
    800016cc:	00007517          	auipc	a0,0x7
    800016d0:	ae450513          	addi	a0,a0,-1308 # 800081b0 <digits+0x158>
    800016d4:	fffff097          	auipc	ra,0xfffff
    800016d8:	e74080e7          	jalr	-396(ra) # 80000548 <panic>
      kfree(mem);
    800016dc:	854a                	mv	a0,s2
    800016de:	fffff097          	auipc	ra,0xfffff
    800016e2:	3ba080e7          	jalr	954(ra) # 80000a98 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    800016e6:	4685                	li	a3,1
    800016e8:	00c9d613          	srli	a2,s3,0xc
    800016ec:	4581                	li	a1,0
    800016ee:	8556                	mv	a0,s5
    800016f0:	00000097          	auipc	ra,0x0
    800016f4:	c5a080e7          	jalr	-934(ra) # 8000134a <uvmunmap>
  return -1;
    800016f8:	557d                	li	a0,-1
}
    800016fa:	60a6                	ld	ra,72(sp)
    800016fc:	6406                	ld	s0,64(sp)
    800016fe:	74e2                	ld	s1,56(sp)
    80001700:	7942                	ld	s2,48(sp)
    80001702:	79a2                	ld	s3,40(sp)
    80001704:	7a02                	ld	s4,32(sp)
    80001706:	6ae2                	ld	s5,24(sp)
    80001708:	6b42                	ld	s6,16(sp)
    8000170a:	6ba2                	ld	s7,8(sp)
    8000170c:	6161                	addi	sp,sp,80
    8000170e:	8082                	ret
  return 0;
    80001710:	4501                	li	a0,0
}
    80001712:	8082                	ret

0000000080001714 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001714:	1141                	addi	sp,sp,-16
    80001716:	e406                	sd	ra,8(sp)
    80001718:	e022                	sd	s0,0(sp)
    8000171a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000171c:	4601                	li	a2,0
    8000171e:	00000097          	auipc	ra,0x0
    80001722:	94e080e7          	jalr	-1714(ra) # 8000106c <walk>
  if(pte == 0)
    80001726:	c901                	beqz	a0,80001736 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001728:	611c                	ld	a5,0(a0)
    8000172a:	9bbd                	andi	a5,a5,-17
    8000172c:	e11c                	sd	a5,0(a0)
}
    8000172e:	60a2                	ld	ra,8(sp)
    80001730:	6402                	ld	s0,0(sp)
    80001732:	0141                	addi	sp,sp,16
    80001734:	8082                	ret
    panic("uvmclear");
    80001736:	00007517          	auipc	a0,0x7
    8000173a:	a9a50513          	addi	a0,a0,-1382 # 800081d0 <digits+0x178>
    8000173e:	fffff097          	auipc	ra,0xfffff
    80001742:	e0a080e7          	jalr	-502(ra) # 80000548 <panic>

0000000080001746 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001746:	c6bd                	beqz	a3,800017b4 <copyout+0x6e>
{
    80001748:	715d                	addi	sp,sp,-80
    8000174a:	e486                	sd	ra,72(sp)
    8000174c:	e0a2                	sd	s0,64(sp)
    8000174e:	fc26                	sd	s1,56(sp)
    80001750:	f84a                	sd	s2,48(sp)
    80001752:	f44e                	sd	s3,40(sp)
    80001754:	f052                	sd	s4,32(sp)
    80001756:	ec56                	sd	s5,24(sp)
    80001758:	e85a                	sd	s6,16(sp)
    8000175a:	e45e                	sd	s7,8(sp)
    8000175c:	e062                	sd	s8,0(sp)
    8000175e:	0880                	addi	s0,sp,80
    80001760:	8b2a                	mv	s6,a0
    80001762:	8c2e                	mv	s8,a1
    80001764:	8a32                	mv	s4,a2
    80001766:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001768:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    8000176a:	6a85                	lui	s5,0x1
    8000176c:	a015                	j	80001790 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    8000176e:	9562                	add	a0,a0,s8
    80001770:	0004861b          	sext.w	a2,s1
    80001774:	85d2                	mv	a1,s4
    80001776:	41250533          	sub	a0,a0,s2
    8000177a:	fffff097          	auipc	ra,0xfffff
    8000177e:	666080e7          	jalr	1638(ra) # 80000de0 <memmove>

    len -= n;
    80001782:	409989b3          	sub	s3,s3,s1
    src += n;
    80001786:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001788:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000178c:	02098263          	beqz	s3,800017b0 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001790:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001794:	85ca                	mv	a1,s2
    80001796:	855a                	mv	a0,s6
    80001798:	00000097          	auipc	ra,0x0
    8000179c:	97a080e7          	jalr	-1670(ra) # 80001112 <walkaddr>
    if(pa0 == 0)
    800017a0:	cd01                	beqz	a0,800017b8 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800017a2:	418904b3          	sub	s1,s2,s8
    800017a6:	94d6                	add	s1,s1,s5
    if(n > len)
    800017a8:	fc99f3e3          	bgeu	s3,s1,8000176e <copyout+0x28>
    800017ac:	84ce                	mv	s1,s3
    800017ae:	b7c1                	j	8000176e <copyout+0x28>
  }
  return 0;
    800017b0:	4501                	li	a0,0
    800017b2:	a021                	j	800017ba <copyout+0x74>
    800017b4:	4501                	li	a0,0
}
    800017b6:	8082                	ret
      return -1;
    800017b8:	557d                	li	a0,-1
}
    800017ba:	60a6                	ld	ra,72(sp)
    800017bc:	6406                	ld	s0,64(sp)
    800017be:	74e2                	ld	s1,56(sp)
    800017c0:	7942                	ld	s2,48(sp)
    800017c2:	79a2                	ld	s3,40(sp)
    800017c4:	7a02                	ld	s4,32(sp)
    800017c6:	6ae2                	ld	s5,24(sp)
    800017c8:	6b42                	ld	s6,16(sp)
    800017ca:	6ba2                	ld	s7,8(sp)
    800017cc:	6c02                	ld	s8,0(sp)
    800017ce:	6161                	addi	sp,sp,80
    800017d0:	8082                	ret

00000000800017d2 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800017d2:	c6bd                	beqz	a3,80001840 <copyin+0x6e>
{
    800017d4:	715d                	addi	sp,sp,-80
    800017d6:	e486                	sd	ra,72(sp)
    800017d8:	e0a2                	sd	s0,64(sp)
    800017da:	fc26                	sd	s1,56(sp)
    800017dc:	f84a                	sd	s2,48(sp)
    800017de:	f44e                	sd	s3,40(sp)
    800017e0:	f052                	sd	s4,32(sp)
    800017e2:	ec56                	sd	s5,24(sp)
    800017e4:	e85a                	sd	s6,16(sp)
    800017e6:	e45e                	sd	s7,8(sp)
    800017e8:	e062                	sd	s8,0(sp)
    800017ea:	0880                	addi	s0,sp,80
    800017ec:	8b2a                	mv	s6,a0
    800017ee:	8a2e                	mv	s4,a1
    800017f0:	8c32                	mv	s8,a2
    800017f2:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    800017f4:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f6:	6a85                	lui	s5,0x1
    800017f8:	a015                	j	8000181c <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    800017fa:	9562                	add	a0,a0,s8
    800017fc:	0004861b          	sext.w	a2,s1
    80001800:	412505b3          	sub	a1,a0,s2
    80001804:	8552                	mv	a0,s4
    80001806:	fffff097          	auipc	ra,0xfffff
    8000180a:	5da080e7          	jalr	1498(ra) # 80000de0 <memmove>

    len -= n;
    8000180e:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001812:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001814:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001818:	02098263          	beqz	s3,8000183c <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    8000181c:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001820:	85ca                	mv	a1,s2
    80001822:	855a                	mv	a0,s6
    80001824:	00000097          	auipc	ra,0x0
    80001828:	8ee080e7          	jalr	-1810(ra) # 80001112 <walkaddr>
    if(pa0 == 0)
    8000182c:	cd01                	beqz	a0,80001844 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    8000182e:	418904b3          	sub	s1,s2,s8
    80001832:	94d6                	add	s1,s1,s5
    if(n > len)
    80001834:	fc99f3e3          	bgeu	s3,s1,800017fa <copyin+0x28>
    80001838:	84ce                	mv	s1,s3
    8000183a:	b7c1                	j	800017fa <copyin+0x28>
  }
  return 0;
    8000183c:	4501                	li	a0,0
    8000183e:	a021                	j	80001846 <copyin+0x74>
    80001840:	4501                	li	a0,0
}
    80001842:	8082                	ret
      return -1;
    80001844:	557d                	li	a0,-1
}
    80001846:	60a6                	ld	ra,72(sp)
    80001848:	6406                	ld	s0,64(sp)
    8000184a:	74e2                	ld	s1,56(sp)
    8000184c:	7942                	ld	s2,48(sp)
    8000184e:	79a2                	ld	s3,40(sp)
    80001850:	7a02                	ld	s4,32(sp)
    80001852:	6ae2                	ld	s5,24(sp)
    80001854:	6b42                	ld	s6,16(sp)
    80001856:	6ba2                	ld	s7,8(sp)
    80001858:	6c02                	ld	s8,0(sp)
    8000185a:	6161                	addi	sp,sp,80
    8000185c:	8082                	ret

000000008000185e <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    8000185e:	c6c5                	beqz	a3,80001906 <copyinstr+0xa8>
{
    80001860:	715d                	addi	sp,sp,-80
    80001862:	e486                	sd	ra,72(sp)
    80001864:	e0a2                	sd	s0,64(sp)
    80001866:	fc26                	sd	s1,56(sp)
    80001868:	f84a                	sd	s2,48(sp)
    8000186a:	f44e                	sd	s3,40(sp)
    8000186c:	f052                	sd	s4,32(sp)
    8000186e:	ec56                	sd	s5,24(sp)
    80001870:	e85a                	sd	s6,16(sp)
    80001872:	e45e                	sd	s7,8(sp)
    80001874:	0880                	addi	s0,sp,80
    80001876:	8a2a                	mv	s4,a0
    80001878:	8b2e                	mv	s6,a1
    8000187a:	8bb2                	mv	s7,a2
    8000187c:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    8000187e:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001880:	6985                	lui	s3,0x1
    80001882:	a035                	j	800018ae <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001884:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001888:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    8000188a:	0017b793          	seqz	a5,a5
    8000188e:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001892:	60a6                	ld	ra,72(sp)
    80001894:	6406                	ld	s0,64(sp)
    80001896:	74e2                	ld	s1,56(sp)
    80001898:	7942                	ld	s2,48(sp)
    8000189a:	79a2                	ld	s3,40(sp)
    8000189c:	7a02                	ld	s4,32(sp)
    8000189e:	6ae2                	ld	s5,24(sp)
    800018a0:	6b42                	ld	s6,16(sp)
    800018a2:	6ba2                	ld	s7,8(sp)
    800018a4:	6161                	addi	sp,sp,80
    800018a6:	8082                	ret
    srcva = va0 + PGSIZE;
    800018a8:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800018ac:	c8a9                	beqz	s1,800018fe <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    800018ae:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800018b2:	85ca                	mv	a1,s2
    800018b4:	8552                	mv	a0,s4
    800018b6:	00000097          	auipc	ra,0x0
    800018ba:	85c080e7          	jalr	-1956(ra) # 80001112 <walkaddr>
    if(pa0 == 0)
    800018be:	c131                	beqz	a0,80001902 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    800018c0:	41790833          	sub	a6,s2,s7
    800018c4:	984e                	add	a6,a6,s3
    if(n > max)
    800018c6:	0104f363          	bgeu	s1,a6,800018cc <copyinstr+0x6e>
    800018ca:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800018cc:	955e                	add	a0,a0,s7
    800018ce:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800018d2:	fc080be3          	beqz	a6,800018a8 <copyinstr+0x4a>
    800018d6:	985a                	add	a6,a6,s6
    800018d8:	87da                	mv	a5,s6
      if(*p == '\0'){
    800018da:	41650633          	sub	a2,a0,s6
    800018de:	14fd                	addi	s1,s1,-1
    800018e0:	9b26                	add	s6,s6,s1
    800018e2:	00f60733          	add	a4,a2,a5
    800018e6:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd4000>
    800018ea:	df49                	beqz	a4,80001884 <copyinstr+0x26>
        *dst = *p;
    800018ec:	00e78023          	sb	a4,0(a5)
      --max;
    800018f0:	40fb04b3          	sub	s1,s6,a5
      dst++;
    800018f4:	0785                	addi	a5,a5,1
    while(n > 0){
    800018f6:	ff0796e3          	bne	a5,a6,800018e2 <copyinstr+0x84>
      dst++;
    800018fa:	8b42                	mv	s6,a6
    800018fc:	b775                	j	800018a8 <copyinstr+0x4a>
    800018fe:	4781                	li	a5,0
    80001900:	b769                	j	8000188a <copyinstr+0x2c>
      return -1;
    80001902:	557d                	li	a0,-1
    80001904:	b779                	j	80001892 <copyinstr+0x34>
  int got_null = 0;
    80001906:	4781                	li	a5,0
  if(got_null){
    80001908:	0017b793          	seqz	a5,a5
    8000190c:	40f00533          	neg	a0,a5
}
    80001910:	8082                	ret

0000000080001912 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001912:	1101                	addi	sp,sp,-32
    80001914:	ec06                	sd	ra,24(sp)
    80001916:	e822                	sd	s0,16(sp)
    80001918:	e426                	sd	s1,8(sp)
    8000191a:	1000                	addi	s0,sp,32
    8000191c:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000191e:	fffff097          	auipc	ra,0xfffff
    80001922:	2ec080e7          	jalr	748(ra) # 80000c0a <holding>
    80001926:	c909                	beqz	a0,80001938 <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001928:	749c                	ld	a5,40(s1)
    8000192a:	00978f63          	beq	a5,s1,80001948 <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    8000192e:	60e2                	ld	ra,24(sp)
    80001930:	6442                	ld	s0,16(sp)
    80001932:	64a2                	ld	s1,8(sp)
    80001934:	6105                	addi	sp,sp,32
    80001936:	8082                	ret
    panic("wakeup1");
    80001938:	00007517          	auipc	a0,0x7
    8000193c:	8a850513          	addi	a0,a0,-1880 # 800081e0 <digits+0x188>
    80001940:	fffff097          	auipc	ra,0xfffff
    80001944:	c08080e7          	jalr	-1016(ra) # 80000548 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001948:	4c98                	lw	a4,24(s1)
    8000194a:	4785                	li	a5,1
    8000194c:	fef711e3          	bne	a4,a5,8000192e <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001950:	4789                	li	a5,2
    80001952:	cc9c                	sw	a5,24(s1)
}
    80001954:	bfe9                	j	8000192e <wakeup1+0x1c>

0000000080001956 <procinit>:
{
    80001956:	715d                	addi	sp,sp,-80
    80001958:	e486                	sd	ra,72(sp)
    8000195a:	e0a2                	sd	s0,64(sp)
    8000195c:	fc26                	sd	s1,56(sp)
    8000195e:	f84a                	sd	s2,48(sp)
    80001960:	f44e                	sd	s3,40(sp)
    80001962:	f052                	sd	s4,32(sp)
    80001964:	ec56                	sd	s5,24(sp)
    80001966:	e85a                	sd	s6,16(sp)
    80001968:	e45e                	sd	s7,8(sp)
    8000196a:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    8000196c:	00007597          	auipc	a1,0x7
    80001970:	87c58593          	addi	a1,a1,-1924 # 800081e8 <digits+0x190>
    80001974:	00010517          	auipc	a0,0x10
    80001978:	fdc50513          	addi	a0,a0,-36 # 80011950 <pid_lock>
    8000197c:	fffff097          	auipc	ra,0xfffff
    80001980:	278080e7          	jalr	632(ra) # 80000bf4 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001984:	00010917          	auipc	s2,0x10
    80001988:	3e490913          	addi	s2,s2,996 # 80011d68 <proc>
      initlock(&p->lock, "proc");
    8000198c:	00007b97          	auipc	s7,0x7
    80001990:	864b8b93          	addi	s7,s7,-1948 # 800081f0 <digits+0x198>
      uint64 va = KSTACK((int) (p - proc));
    80001994:	8b4a                	mv	s6,s2
    80001996:	00006a97          	auipc	s5,0x6
    8000199a:	66aa8a93          	addi	s5,s5,1642 # 80008000 <etext>
    8000199e:	040009b7          	lui	s3,0x4000
    800019a2:	19fd                	addi	s3,s3,-1
    800019a4:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800019a6:	0001ba17          	auipc	s4,0x1b
    800019aa:	bc2a0a13          	addi	s4,s4,-1086 # 8001c568 <tickslock>
      initlock(&p->lock, "proc");
    800019ae:	85de                	mv	a1,s7
    800019b0:	854a                	mv	a0,s2
    800019b2:	fffff097          	auipc	ra,0xfffff
    800019b6:	242080e7          	jalr	578(ra) # 80000bf4 <initlock>
      char *pa = kalloc();
    800019ba:	fffff097          	auipc	ra,0xfffff
    800019be:	1da080e7          	jalr	474(ra) # 80000b94 <kalloc>
    800019c2:	85aa                	mv	a1,a0
      if(pa == 0)
    800019c4:	c929                	beqz	a0,80001a16 <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    800019c6:	416904b3          	sub	s1,s2,s6
    800019ca:	8495                	srai	s1,s1,0x5
    800019cc:	000ab783          	ld	a5,0(s5)
    800019d0:	02f484b3          	mul	s1,s1,a5
    800019d4:	2485                	addiw	s1,s1,1
    800019d6:	00d4949b          	slliw	s1,s1,0xd
    800019da:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800019de:	4699                	li	a3,6
    800019e0:	6605                	lui	a2,0x1
    800019e2:	8526                	mv	a0,s1
    800019e4:	00000097          	auipc	ra,0x0
    800019e8:	85c080e7          	jalr	-1956(ra) # 80001240 <kvmmap>
      p->kstack = va;
    800019ec:	04993023          	sd	s1,64(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019f0:	2a090913          	addi	s2,s2,672
    800019f4:	fb491de3          	bne	s2,s4,800019ae <procinit+0x58>
  kvminithart();
    800019f8:	fffff097          	auipc	ra,0xfffff
    800019fc:	650080e7          	jalr	1616(ra) # 80001048 <kvminithart>
}
    80001a00:	60a6                	ld	ra,72(sp)
    80001a02:	6406                	ld	s0,64(sp)
    80001a04:	74e2                	ld	s1,56(sp)
    80001a06:	7942                	ld	s2,48(sp)
    80001a08:	79a2                	ld	s3,40(sp)
    80001a0a:	7a02                	ld	s4,32(sp)
    80001a0c:	6ae2                	ld	s5,24(sp)
    80001a0e:	6b42                	ld	s6,16(sp)
    80001a10:	6ba2                	ld	s7,8(sp)
    80001a12:	6161                	addi	sp,sp,80
    80001a14:	8082                	ret
        panic("kalloc");
    80001a16:	00006517          	auipc	a0,0x6
    80001a1a:	7e250513          	addi	a0,a0,2018 # 800081f8 <digits+0x1a0>
    80001a1e:	fffff097          	auipc	ra,0xfffff
    80001a22:	b2a080e7          	jalr	-1238(ra) # 80000548 <panic>

0000000080001a26 <cpuid>:
{
    80001a26:	1141                	addi	sp,sp,-16
    80001a28:	e422                	sd	s0,8(sp)
    80001a2a:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001a2c:	8512                	mv	a0,tp
}
    80001a2e:	2501                	sext.w	a0,a0
    80001a30:	6422                	ld	s0,8(sp)
    80001a32:	0141                	addi	sp,sp,16
    80001a34:	8082                	ret

0000000080001a36 <mycpu>:
mycpu(void) {
    80001a36:	1141                	addi	sp,sp,-16
    80001a38:	e422                	sd	s0,8(sp)
    80001a3a:	0800                	addi	s0,sp,16
    80001a3c:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001a3e:	2781                	sext.w	a5,a5
    80001a40:	079e                	slli	a5,a5,0x7
}
    80001a42:	00010517          	auipc	a0,0x10
    80001a46:	f2650513          	addi	a0,a0,-218 # 80011968 <cpus>
    80001a4a:	953e                	add	a0,a0,a5
    80001a4c:	6422                	ld	s0,8(sp)
    80001a4e:	0141                	addi	sp,sp,16
    80001a50:	8082                	ret

0000000080001a52 <myproc>:
myproc(void) {
    80001a52:	1101                	addi	sp,sp,-32
    80001a54:	ec06                	sd	ra,24(sp)
    80001a56:	e822                	sd	s0,16(sp)
    80001a58:	e426                	sd	s1,8(sp)
    80001a5a:	1000                	addi	s0,sp,32
  push_off();
    80001a5c:	fffff097          	auipc	ra,0xfffff
    80001a60:	1dc080e7          	jalr	476(ra) # 80000c38 <push_off>
    80001a64:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001a66:	2781                	sext.w	a5,a5
    80001a68:	079e                	slli	a5,a5,0x7
    80001a6a:	00010717          	auipc	a4,0x10
    80001a6e:	ee670713          	addi	a4,a4,-282 # 80011950 <pid_lock>
    80001a72:	97ba                	add	a5,a5,a4
    80001a74:	6f84                	ld	s1,24(a5)
  pop_off();
    80001a76:	fffff097          	auipc	ra,0xfffff
    80001a7a:	262080e7          	jalr	610(ra) # 80000cd8 <pop_off>
}
    80001a7e:	8526                	mv	a0,s1
    80001a80:	60e2                	ld	ra,24(sp)
    80001a82:	6442                	ld	s0,16(sp)
    80001a84:	64a2                	ld	s1,8(sp)
    80001a86:	6105                	addi	sp,sp,32
    80001a88:	8082                	ret

0000000080001a8a <forkret>:
{
    80001a8a:	1141                	addi	sp,sp,-16
    80001a8c:	e406                	sd	ra,8(sp)
    80001a8e:	e022                	sd	s0,0(sp)
    80001a90:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001a92:	00000097          	auipc	ra,0x0
    80001a96:	fc0080e7          	jalr	-64(ra) # 80001a52 <myproc>
    80001a9a:	fffff097          	auipc	ra,0xfffff
    80001a9e:	29e080e7          	jalr	670(ra) # 80000d38 <release>
  if (first) {
    80001aa2:	00007797          	auipc	a5,0x7
    80001aa6:	d9e7a783          	lw	a5,-610(a5) # 80008840 <first.1672>
    80001aaa:	eb89                	bnez	a5,80001abc <forkret+0x32>
  usertrapret();
    80001aac:	00001097          	auipc	ra,0x1
    80001ab0:	c28080e7          	jalr	-984(ra) # 800026d4 <usertrapret>
}
    80001ab4:	60a2                	ld	ra,8(sp)
    80001ab6:	6402                	ld	s0,0(sp)
    80001ab8:	0141                	addi	sp,sp,16
    80001aba:	8082                	ret
    first = 0;
    80001abc:	00007797          	auipc	a5,0x7
    80001ac0:	d807a223          	sw	zero,-636(a5) # 80008840 <first.1672>
    fsinit(ROOTDEV);
    80001ac4:	4505                	li	a0,1
    80001ac6:	00002097          	auipc	ra,0x2
    80001aca:	a3e080e7          	jalr	-1474(ra) # 80003504 <fsinit>
    80001ace:	bff9                	j	80001aac <forkret+0x22>

0000000080001ad0 <allocpid>:
allocpid() {
    80001ad0:	1101                	addi	sp,sp,-32
    80001ad2:	ec06                	sd	ra,24(sp)
    80001ad4:	e822                	sd	s0,16(sp)
    80001ad6:	e426                	sd	s1,8(sp)
    80001ad8:	e04a                	sd	s2,0(sp)
    80001ada:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001adc:	00010917          	auipc	s2,0x10
    80001ae0:	e7490913          	addi	s2,s2,-396 # 80011950 <pid_lock>
    80001ae4:	854a                	mv	a0,s2
    80001ae6:	fffff097          	auipc	ra,0xfffff
    80001aea:	19e080e7          	jalr	414(ra) # 80000c84 <acquire>
  pid = nextpid;
    80001aee:	00007797          	auipc	a5,0x7
    80001af2:	d5678793          	addi	a5,a5,-682 # 80008844 <nextpid>
    80001af6:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001af8:	0014871b          	addiw	a4,s1,1
    80001afc:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001afe:	854a                	mv	a0,s2
    80001b00:	fffff097          	auipc	ra,0xfffff
    80001b04:	238080e7          	jalr	568(ra) # 80000d38 <release>
}
    80001b08:	8526                	mv	a0,s1
    80001b0a:	60e2                	ld	ra,24(sp)
    80001b0c:	6442                	ld	s0,16(sp)
    80001b0e:	64a2                	ld	s1,8(sp)
    80001b10:	6902                	ld	s2,0(sp)
    80001b12:	6105                	addi	sp,sp,32
    80001b14:	8082                	ret

0000000080001b16 <proc_pagetable>:
{
    80001b16:	1101                	addi	sp,sp,-32
    80001b18:	ec06                	sd	ra,24(sp)
    80001b1a:	e822                	sd	s0,16(sp)
    80001b1c:	e426                	sd	s1,8(sp)
    80001b1e:	e04a                	sd	s2,0(sp)
    80001b20:	1000                	addi	s0,sp,32
    80001b22:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	8ea080e7          	jalr	-1814(ra) # 8000140e <uvmcreate>
    80001b2c:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001b2e:	c121                	beqz	a0,80001b6e <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001b30:	4729                	li	a4,10
    80001b32:	00005697          	auipc	a3,0x5
    80001b36:	4ce68693          	addi	a3,a3,1230 # 80007000 <_trampoline>
    80001b3a:	6605                	lui	a2,0x1
    80001b3c:	040005b7          	lui	a1,0x4000
    80001b40:	15fd                	addi	a1,a1,-1
    80001b42:	05b2                	slli	a1,a1,0xc
    80001b44:	fffff097          	auipc	ra,0xfffff
    80001b48:	66e080e7          	jalr	1646(ra) # 800011b2 <mappages>
    80001b4c:	02054863          	bltz	a0,80001b7c <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001b50:	4719                	li	a4,6
    80001b52:	05893683          	ld	a3,88(s2)
    80001b56:	6605                	lui	a2,0x1
    80001b58:	020005b7          	lui	a1,0x2000
    80001b5c:	15fd                	addi	a1,a1,-1
    80001b5e:	05b6                	slli	a1,a1,0xd
    80001b60:	8526                	mv	a0,s1
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	650080e7          	jalr	1616(ra) # 800011b2 <mappages>
    80001b6a:	02054163          	bltz	a0,80001b8c <proc_pagetable+0x76>
}
    80001b6e:	8526                	mv	a0,s1
    80001b70:	60e2                	ld	ra,24(sp)
    80001b72:	6442                	ld	s0,16(sp)
    80001b74:	64a2                	ld	s1,8(sp)
    80001b76:	6902                	ld	s2,0(sp)
    80001b78:	6105                	addi	sp,sp,32
    80001b7a:	8082                	ret
    uvmfree(pagetable, 0);
    80001b7c:	4581                	li	a1,0
    80001b7e:	8526                	mv	a0,s1
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	a8a080e7          	jalr	-1398(ra) # 8000160a <uvmfree>
    return 0;
    80001b88:	4481                	li	s1,0
    80001b8a:	b7d5                	j	80001b6e <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b8c:	4681                	li	a3,0
    80001b8e:	4605                	li	a2,1
    80001b90:	040005b7          	lui	a1,0x4000
    80001b94:	15fd                	addi	a1,a1,-1
    80001b96:	05b2                	slli	a1,a1,0xc
    80001b98:	8526                	mv	a0,s1
    80001b9a:	fffff097          	auipc	ra,0xfffff
    80001b9e:	7b0080e7          	jalr	1968(ra) # 8000134a <uvmunmap>
    uvmfree(pagetable, 0);
    80001ba2:	4581                	li	a1,0
    80001ba4:	8526                	mv	a0,s1
    80001ba6:	00000097          	auipc	ra,0x0
    80001baa:	a64080e7          	jalr	-1436(ra) # 8000160a <uvmfree>
    return 0;
    80001bae:	4481                	li	s1,0
    80001bb0:	bf7d                	j	80001b6e <proc_pagetable+0x58>

0000000080001bb2 <proc_freepagetable>:
{
    80001bb2:	1101                	addi	sp,sp,-32
    80001bb4:	ec06                	sd	ra,24(sp)
    80001bb6:	e822                	sd	s0,16(sp)
    80001bb8:	e426                	sd	s1,8(sp)
    80001bba:	e04a                	sd	s2,0(sp)
    80001bbc:	1000                	addi	s0,sp,32
    80001bbe:	84aa                	mv	s1,a0
    80001bc0:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001bc2:	4681                	li	a3,0
    80001bc4:	4605                	li	a2,1
    80001bc6:	040005b7          	lui	a1,0x4000
    80001bca:	15fd                	addi	a1,a1,-1
    80001bcc:	05b2                	slli	a1,a1,0xc
    80001bce:	fffff097          	auipc	ra,0xfffff
    80001bd2:	77c080e7          	jalr	1916(ra) # 8000134a <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001bd6:	4681                	li	a3,0
    80001bd8:	4605                	li	a2,1
    80001bda:	020005b7          	lui	a1,0x2000
    80001bde:	15fd                	addi	a1,a1,-1
    80001be0:	05b6                	slli	a1,a1,0xd
    80001be2:	8526                	mv	a0,s1
    80001be4:	fffff097          	auipc	ra,0xfffff
    80001be8:	766080e7          	jalr	1894(ra) # 8000134a <uvmunmap>
  uvmfree(pagetable, sz);
    80001bec:	85ca                	mv	a1,s2
    80001bee:	8526                	mv	a0,s1
    80001bf0:	00000097          	auipc	ra,0x0
    80001bf4:	a1a080e7          	jalr	-1510(ra) # 8000160a <uvmfree>
}
    80001bf8:	60e2                	ld	ra,24(sp)
    80001bfa:	6442                	ld	s0,16(sp)
    80001bfc:	64a2                	ld	s1,8(sp)
    80001bfe:	6902                	ld	s2,0(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <freeproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	1000                	addi	s0,sp,32
    80001c0e:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001c10:	6d28                	ld	a0,88(a0)
    80001c12:	c509                	beqz	a0,80001c1c <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001c14:	fffff097          	auipc	ra,0xfffff
    80001c18:	e84080e7          	jalr	-380(ra) # 80000a98 <kfree>
  p->trapframe = 0;
    80001c1c:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001c20:	68a8                	ld	a0,80(s1)
    80001c22:	c511                	beqz	a0,80001c2e <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001c24:	64ac                	ld	a1,72(s1)
    80001c26:	00000097          	auipc	ra,0x0
    80001c2a:	f8c080e7          	jalr	-116(ra) # 80001bb2 <proc_freepagetable>
  p->pagetable = 0;
    80001c2e:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001c32:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001c36:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    80001c3a:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    80001c3e:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001c42:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    80001c46:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    80001c4a:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    80001c4e:	0004ac23          	sw	zero,24(s1)
}
    80001c52:	60e2                	ld	ra,24(sp)
    80001c54:	6442                	ld	s0,16(sp)
    80001c56:	64a2                	ld	s1,8(sp)
    80001c58:	6105                	addi	sp,sp,32
    80001c5a:	8082                	ret

0000000080001c5c <allocproc>:
{
    80001c5c:	1101                	addi	sp,sp,-32
    80001c5e:	ec06                	sd	ra,24(sp)
    80001c60:	e822                	sd	s0,16(sp)
    80001c62:	e426                	sd	s1,8(sp)
    80001c64:	e04a                	sd	s2,0(sp)
    80001c66:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c68:	00010497          	auipc	s1,0x10
    80001c6c:	10048493          	addi	s1,s1,256 # 80011d68 <proc>
    80001c70:	0001b917          	auipc	s2,0x1b
    80001c74:	8f890913          	addi	s2,s2,-1800 # 8001c568 <tickslock>
    acquire(&p->lock);
    80001c78:	8526                	mv	a0,s1
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	00a080e7          	jalr	10(ra) # 80000c84 <acquire>
    if(p->state == UNUSED) {
    80001c82:	4c9c                	lw	a5,24(s1)
    80001c84:	cf81                	beqz	a5,80001c9c <allocproc+0x40>
      release(&p->lock);
    80001c86:	8526                	mv	a0,s1
    80001c88:	fffff097          	auipc	ra,0xfffff
    80001c8c:	0b0080e7          	jalr	176(ra) # 80000d38 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c90:	2a048493          	addi	s1,s1,672
    80001c94:	ff2492e3          	bne	s1,s2,80001c78 <allocproc+0x1c>
  return 0;
    80001c98:	4481                	li	s1,0
    80001c9a:	a8b9                	j	80001cf8 <allocproc+0x9c>
  p->pid = allocpid();
    80001c9c:	00000097          	auipc	ra,0x0
    80001ca0:	e34080e7          	jalr	-460(ra) # 80001ad0 <allocpid>
    80001ca4:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ca6:	fffff097          	auipc	ra,0xfffff
    80001caa:	eee080e7          	jalr	-274(ra) # 80000b94 <kalloc>
    80001cae:	892a                	mv	s2,a0
    80001cb0:	eca8                	sd	a0,88(s1)
    80001cb2:	c931                	beqz	a0,80001d06 <allocproc+0xaa>
  p->pagetable = proc_pagetable(p);
    80001cb4:	8526                	mv	a0,s1
    80001cb6:	00000097          	auipc	ra,0x0
    80001cba:	e60080e7          	jalr	-416(ra) # 80001b16 <proc_pagetable>
    80001cbe:	892a                	mv	s2,a0
    80001cc0:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001cc2:	c929                	beqz	a0,80001d14 <allocproc+0xb8>
  memset(&p->context, 0, sizeof(p->context));
    80001cc4:	07000613          	li	a2,112
    80001cc8:	4581                	li	a1,0
    80001cca:	06048513          	addi	a0,s1,96
    80001cce:	fffff097          	auipc	ra,0xfffff
    80001cd2:	0b2080e7          	jalr	178(ra) # 80000d80 <memset>
  p->context.ra = (uint64)forkret;
    80001cd6:	00000797          	auipc	a5,0x0
    80001cda:	db478793          	addi	a5,a5,-588 # 80001a8a <forkret>
    80001cde:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001ce0:	60bc                	ld	a5,64(s1)
    80001ce2:	6705                	lui	a4,0x1
    80001ce4:	97ba                	add	a5,a5,a4
    80001ce6:	f4bc                	sd	a5,104(s1)
  p->alarm_handler = 0;
    80001ce8:	1604b823          	sd	zero,368(s1)
  p->alarm_interval = 0;
    80001cec:	1604a423          	sw	zero,360(s1)
  p->passed_ticks = 0;
    80001cf0:	1604a623          	sw	zero,364(s1)
  p->block = 0;
    80001cf4:	1604ac23          	sw	zero,376(s1)
}
    80001cf8:	8526                	mv	a0,s1
    80001cfa:	60e2                	ld	ra,24(sp)
    80001cfc:	6442                	ld	s0,16(sp)
    80001cfe:	64a2                	ld	s1,8(sp)
    80001d00:	6902                	ld	s2,0(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret
    release(&p->lock);
    80001d06:	8526                	mv	a0,s1
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	030080e7          	jalr	48(ra) # 80000d38 <release>
    return 0;
    80001d10:	84ca                	mv	s1,s2
    80001d12:	b7dd                	j	80001cf8 <allocproc+0x9c>
    freeproc(p);
    80001d14:	8526                	mv	a0,s1
    80001d16:	00000097          	auipc	ra,0x0
    80001d1a:	eee080e7          	jalr	-274(ra) # 80001c04 <freeproc>
    release(&p->lock);
    80001d1e:	8526                	mv	a0,s1
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	018080e7          	jalr	24(ra) # 80000d38 <release>
    return 0;
    80001d28:	84ca                	mv	s1,s2
    80001d2a:	b7f9                	j	80001cf8 <allocproc+0x9c>

0000000080001d2c <userinit>:
{
    80001d2c:	1101                	addi	sp,sp,-32
    80001d2e:	ec06                	sd	ra,24(sp)
    80001d30:	e822                	sd	s0,16(sp)
    80001d32:	e426                	sd	s1,8(sp)
    80001d34:	1000                	addi	s0,sp,32
  p = allocproc();
    80001d36:	00000097          	auipc	ra,0x0
    80001d3a:	f26080e7          	jalr	-218(ra) # 80001c5c <allocproc>
    80001d3e:	84aa                	mv	s1,a0
  initproc = p;
    80001d40:	00007797          	auipc	a5,0x7
    80001d44:	2ca7bc23          	sd	a0,728(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001d48:	03400613          	li	a2,52
    80001d4c:	00007597          	auipc	a1,0x7
    80001d50:	b0458593          	addi	a1,a1,-1276 # 80008850 <initcode>
    80001d54:	6928                	ld	a0,80(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	6e6080e7          	jalr	1766(ra) # 8000143c <uvminit>
  p->sz = PGSIZE;
    80001d5e:	6785                	lui	a5,0x1
    80001d60:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d62:	6cb8                	ld	a4,88(s1)
    80001d64:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d68:	6cb8                	ld	a4,88(s1)
    80001d6a:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d6c:	4641                	li	a2,16
    80001d6e:	00006597          	auipc	a1,0x6
    80001d72:	49258593          	addi	a1,a1,1170 # 80008200 <digits+0x1a8>
    80001d76:	15848513          	addi	a0,s1,344
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	15c080e7          	jalr	348(ra) # 80000ed6 <safestrcpy>
  p->cwd = namei("/");
    80001d82:	00006517          	auipc	a0,0x6
    80001d86:	48e50513          	addi	a0,a0,1166 # 80008210 <digits+0x1b8>
    80001d8a:	00002097          	auipc	ra,0x2
    80001d8e:	1a2080e7          	jalr	418(ra) # 80003f2c <namei>
    80001d92:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d96:	4789                	li	a5,2
    80001d98:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d9a:	8526                	mv	a0,s1
    80001d9c:	fffff097          	auipc	ra,0xfffff
    80001da0:	f9c080e7          	jalr	-100(ra) # 80000d38 <release>
}
    80001da4:	60e2                	ld	ra,24(sp)
    80001da6:	6442                	ld	s0,16(sp)
    80001da8:	64a2                	ld	s1,8(sp)
    80001daa:	6105                	addi	sp,sp,32
    80001dac:	8082                	ret

0000000080001dae <growproc>:
{
    80001dae:	1101                	addi	sp,sp,-32
    80001db0:	ec06                	sd	ra,24(sp)
    80001db2:	e822                	sd	s0,16(sp)
    80001db4:	e426                	sd	s1,8(sp)
    80001db6:	e04a                	sd	s2,0(sp)
    80001db8:	1000                	addi	s0,sp,32
    80001dba:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001dbc:	00000097          	auipc	ra,0x0
    80001dc0:	c96080e7          	jalr	-874(ra) # 80001a52 <myproc>
    80001dc4:	892a                	mv	s2,a0
  sz = p->sz;
    80001dc6:	652c                	ld	a1,72(a0)
    80001dc8:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001dcc:	00904f63          	bgtz	s1,80001dea <growproc+0x3c>
  } else if(n < 0){
    80001dd0:	0204cc63          	bltz	s1,80001e08 <growproc+0x5a>
  p->sz = sz;
    80001dd4:	1602                	slli	a2,a2,0x20
    80001dd6:	9201                	srli	a2,a2,0x20
    80001dd8:	04c93423          	sd	a2,72(s2)
  return 0;
    80001ddc:	4501                	li	a0,0
}
    80001dde:	60e2                	ld	ra,24(sp)
    80001de0:	6442                	ld	s0,16(sp)
    80001de2:	64a2                	ld	s1,8(sp)
    80001de4:	6902                	ld	s2,0(sp)
    80001de6:	6105                	addi	sp,sp,32
    80001de8:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001dea:	9e25                	addw	a2,a2,s1
    80001dec:	1602                	slli	a2,a2,0x20
    80001dee:	9201                	srli	a2,a2,0x20
    80001df0:	1582                	slli	a1,a1,0x20
    80001df2:	9181                	srli	a1,a1,0x20
    80001df4:	6928                	ld	a0,80(a0)
    80001df6:	fffff097          	auipc	ra,0xfffff
    80001dfa:	700080e7          	jalr	1792(ra) # 800014f6 <uvmalloc>
    80001dfe:	0005061b          	sext.w	a2,a0
    80001e02:	fa69                	bnez	a2,80001dd4 <growproc+0x26>
      return -1;
    80001e04:	557d                	li	a0,-1
    80001e06:	bfe1                	j	80001dde <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001e08:	9e25                	addw	a2,a2,s1
    80001e0a:	1602                	slli	a2,a2,0x20
    80001e0c:	9201                	srli	a2,a2,0x20
    80001e0e:	1582                	slli	a1,a1,0x20
    80001e10:	9181                	srli	a1,a1,0x20
    80001e12:	6928                	ld	a0,80(a0)
    80001e14:	fffff097          	auipc	ra,0xfffff
    80001e18:	69a080e7          	jalr	1690(ra) # 800014ae <uvmdealloc>
    80001e1c:	0005061b          	sext.w	a2,a0
    80001e20:	bf55                	j	80001dd4 <growproc+0x26>

0000000080001e22 <fork>:
{
    80001e22:	7179                	addi	sp,sp,-48
    80001e24:	f406                	sd	ra,40(sp)
    80001e26:	f022                	sd	s0,32(sp)
    80001e28:	ec26                	sd	s1,24(sp)
    80001e2a:	e84a                	sd	s2,16(sp)
    80001e2c:	e44e                	sd	s3,8(sp)
    80001e2e:	e052                	sd	s4,0(sp)
    80001e30:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001e32:	00000097          	auipc	ra,0x0
    80001e36:	c20080e7          	jalr	-992(ra) # 80001a52 <myproc>
    80001e3a:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80001e3c:	00000097          	auipc	ra,0x0
    80001e40:	e20080e7          	jalr	-480(ra) # 80001c5c <allocproc>
    80001e44:	c175                	beqz	a0,80001f28 <fork+0x106>
    80001e46:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001e48:	04893603          	ld	a2,72(s2)
    80001e4c:	692c                	ld	a1,80(a0)
    80001e4e:	05093503          	ld	a0,80(s2)
    80001e52:	fffff097          	auipc	ra,0xfffff
    80001e56:	7f0080e7          	jalr	2032(ra) # 80001642 <uvmcopy>
    80001e5a:	04054863          	bltz	a0,80001eaa <fork+0x88>
  np->sz = p->sz;
    80001e5e:	04893783          	ld	a5,72(s2)
    80001e62:	04f9b423          	sd	a5,72(s3) # 4000048 <_entry-0x7bffffb8>
  np->parent = p;
    80001e66:	0329b023          	sd	s2,32(s3)
  *(np->trapframe) = *(p->trapframe);
    80001e6a:	05893683          	ld	a3,88(s2)
    80001e6e:	87b6                	mv	a5,a3
    80001e70:	0589b703          	ld	a4,88(s3)
    80001e74:	12068693          	addi	a3,a3,288
    80001e78:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e7c:	6788                	ld	a0,8(a5)
    80001e7e:	6b8c                	ld	a1,16(a5)
    80001e80:	6f90                	ld	a2,24(a5)
    80001e82:	01073023          	sd	a6,0(a4)
    80001e86:	e708                	sd	a0,8(a4)
    80001e88:	eb0c                	sd	a1,16(a4)
    80001e8a:	ef10                	sd	a2,24(a4)
    80001e8c:	02078793          	addi	a5,a5,32
    80001e90:	02070713          	addi	a4,a4,32
    80001e94:	fed792e3          	bne	a5,a3,80001e78 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e98:	0589b783          	ld	a5,88(s3)
    80001e9c:	0607b823          	sd	zero,112(a5)
    80001ea0:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    80001ea4:	15000a13          	li	s4,336
    80001ea8:	a03d                	j	80001ed6 <fork+0xb4>
    freeproc(np);
    80001eaa:	854e                	mv	a0,s3
    80001eac:	00000097          	auipc	ra,0x0
    80001eb0:	d58080e7          	jalr	-680(ra) # 80001c04 <freeproc>
    release(&np->lock);
    80001eb4:	854e                	mv	a0,s3
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e82080e7          	jalr	-382(ra) # 80000d38 <release>
    return -1;
    80001ebe:	54fd                	li	s1,-1
    80001ec0:	a899                	j	80001f16 <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001ec2:	00002097          	auipc	ra,0x2
    80001ec6:	6f6080e7          	jalr	1782(ra) # 800045b8 <filedup>
    80001eca:	009987b3          	add	a5,s3,s1
    80001ece:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80001ed0:	04a1                	addi	s1,s1,8
    80001ed2:	01448763          	beq	s1,s4,80001ee0 <fork+0xbe>
    if(p->ofile[i])
    80001ed6:	009907b3          	add	a5,s2,s1
    80001eda:	6388                	ld	a0,0(a5)
    80001edc:	f17d                	bnez	a0,80001ec2 <fork+0xa0>
    80001ede:	bfcd                	j	80001ed0 <fork+0xae>
  np->cwd = idup(p->cwd);
    80001ee0:	15093503          	ld	a0,336(s2)
    80001ee4:	00002097          	auipc	ra,0x2
    80001ee8:	85a080e7          	jalr	-1958(ra) # 8000373e <idup>
    80001eec:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001ef0:	4641                	li	a2,16
    80001ef2:	15890593          	addi	a1,s2,344
    80001ef6:	15898513          	addi	a0,s3,344
    80001efa:	fffff097          	auipc	ra,0xfffff
    80001efe:	fdc080e7          	jalr	-36(ra) # 80000ed6 <safestrcpy>
  pid = np->pid;
    80001f02:	0389a483          	lw	s1,56(s3)
  np->state = RUNNABLE;
    80001f06:	4789                	li	a5,2
    80001f08:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001f0c:	854e                	mv	a0,s3
    80001f0e:	fffff097          	auipc	ra,0xfffff
    80001f12:	e2a080e7          	jalr	-470(ra) # 80000d38 <release>
}
    80001f16:	8526                	mv	a0,s1
    80001f18:	70a2                	ld	ra,40(sp)
    80001f1a:	7402                	ld	s0,32(sp)
    80001f1c:	64e2                	ld	s1,24(sp)
    80001f1e:	6942                	ld	s2,16(sp)
    80001f20:	69a2                	ld	s3,8(sp)
    80001f22:	6a02                	ld	s4,0(sp)
    80001f24:	6145                	addi	sp,sp,48
    80001f26:	8082                	ret
    return -1;
    80001f28:	54fd                	li	s1,-1
    80001f2a:	b7f5                	j	80001f16 <fork+0xf4>

0000000080001f2c <reparent>:
{
    80001f2c:	7179                	addi	sp,sp,-48
    80001f2e:	f406                	sd	ra,40(sp)
    80001f30:	f022                	sd	s0,32(sp)
    80001f32:	ec26                	sd	s1,24(sp)
    80001f34:	e84a                	sd	s2,16(sp)
    80001f36:	e44e                	sd	s3,8(sp)
    80001f38:	e052                	sd	s4,0(sp)
    80001f3a:	1800                	addi	s0,sp,48
    80001f3c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f3e:	00010497          	auipc	s1,0x10
    80001f42:	e2a48493          	addi	s1,s1,-470 # 80011d68 <proc>
      pp->parent = initproc;
    80001f46:	00007a17          	auipc	s4,0x7
    80001f4a:	0d2a0a13          	addi	s4,s4,210 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80001f4e:	0001a997          	auipc	s3,0x1a
    80001f52:	61a98993          	addi	s3,s3,1562 # 8001c568 <tickslock>
    80001f56:	a029                	j	80001f60 <reparent+0x34>
    80001f58:	2a048493          	addi	s1,s1,672
    80001f5c:	03348363          	beq	s1,s3,80001f82 <reparent+0x56>
    if(pp->parent == p){
    80001f60:	709c                	ld	a5,32(s1)
    80001f62:	ff279be3          	bne	a5,s2,80001f58 <reparent+0x2c>
      acquire(&pp->lock);
    80001f66:	8526                	mv	a0,s1
    80001f68:	fffff097          	auipc	ra,0xfffff
    80001f6c:	d1c080e7          	jalr	-740(ra) # 80000c84 <acquire>
      pp->parent = initproc;
    80001f70:	000a3783          	ld	a5,0(s4)
    80001f74:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    80001f76:	8526                	mv	a0,s1
    80001f78:	fffff097          	auipc	ra,0xfffff
    80001f7c:	dc0080e7          	jalr	-576(ra) # 80000d38 <release>
    80001f80:	bfe1                	j	80001f58 <reparent+0x2c>
}
    80001f82:	70a2                	ld	ra,40(sp)
    80001f84:	7402                	ld	s0,32(sp)
    80001f86:	64e2                	ld	s1,24(sp)
    80001f88:	6942                	ld	s2,16(sp)
    80001f8a:	69a2                	ld	s3,8(sp)
    80001f8c:	6a02                	ld	s4,0(sp)
    80001f8e:	6145                	addi	sp,sp,48
    80001f90:	8082                	ret

0000000080001f92 <scheduler>:
{
    80001f92:	715d                	addi	sp,sp,-80
    80001f94:	e486                	sd	ra,72(sp)
    80001f96:	e0a2                	sd	s0,64(sp)
    80001f98:	fc26                	sd	s1,56(sp)
    80001f9a:	f84a                	sd	s2,48(sp)
    80001f9c:	f44e                	sd	s3,40(sp)
    80001f9e:	f052                	sd	s4,32(sp)
    80001fa0:	ec56                	sd	s5,24(sp)
    80001fa2:	e85a                	sd	s6,16(sp)
    80001fa4:	e45e                	sd	s7,8(sp)
    80001fa6:	e062                	sd	s8,0(sp)
    80001fa8:	0880                	addi	s0,sp,80
    80001faa:	8792                	mv	a5,tp
  int id = r_tp();
    80001fac:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001fae:	00779b13          	slli	s6,a5,0x7
    80001fb2:	00010717          	auipc	a4,0x10
    80001fb6:	99e70713          	addi	a4,a4,-1634 # 80011950 <pid_lock>
    80001fba:	975a                	add	a4,a4,s6
    80001fbc:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    80001fc0:	00010717          	auipc	a4,0x10
    80001fc4:	9b070713          	addi	a4,a4,-1616 # 80011970 <cpus+0x8>
    80001fc8:	9b3a                	add	s6,s6,a4
        p->state = RUNNING;
    80001fca:	4c0d                	li	s8,3
        c->proc = p;
    80001fcc:	079e                	slli	a5,a5,0x7
    80001fce:	00010a17          	auipc	s4,0x10
    80001fd2:	982a0a13          	addi	s4,s4,-1662 # 80011950 <pid_lock>
    80001fd6:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fd8:	0001a997          	auipc	s3,0x1a
    80001fdc:	59098993          	addi	s3,s3,1424 # 8001c568 <tickslock>
        found = 1;
    80001fe0:	4b85                	li	s7,1
    80001fe2:	a899                	j	80002038 <scheduler+0xa6>
        p->state = RUNNING;
    80001fe4:	0184ac23          	sw	s8,24(s1)
        c->proc = p;
    80001fe8:	009a3c23          	sd	s1,24(s4)
        swtch(&c->context, &p->context);
    80001fec:	06048593          	addi	a1,s1,96
    80001ff0:	855a                	mv	a0,s6
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	638080e7          	jalr	1592(ra) # 8000262a <swtch>
        c->proc = 0;
    80001ffa:	000a3c23          	sd	zero,24(s4)
        found = 1;
    80001ffe:	8ade                	mv	s5,s7
      release(&p->lock);
    80002000:	8526                	mv	a0,s1
    80002002:	fffff097          	auipc	ra,0xfffff
    80002006:	d36080e7          	jalr	-714(ra) # 80000d38 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    8000200a:	2a048493          	addi	s1,s1,672
    8000200e:	01348b63          	beq	s1,s3,80002024 <scheduler+0x92>
      acquire(&p->lock);
    80002012:	8526                	mv	a0,s1
    80002014:	fffff097          	auipc	ra,0xfffff
    80002018:	c70080e7          	jalr	-912(ra) # 80000c84 <acquire>
      if(p->state == RUNNABLE) {
    8000201c:	4c9c                	lw	a5,24(s1)
    8000201e:	ff2791e3          	bne	a5,s2,80002000 <scheduler+0x6e>
    80002022:	b7c9                	j	80001fe4 <scheduler+0x52>
    if(found == 0) {
    80002024:	000a9a63          	bnez	s5,80002038 <scheduler+0xa6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002028:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000202c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002030:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002034:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002038:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002040:	10079073          	csrw	sstatus,a5
    int found = 0;
    80002044:	4a81                	li	s5,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002046:	00010497          	auipc	s1,0x10
    8000204a:	d2248493          	addi	s1,s1,-734 # 80011d68 <proc>
      if(p->state == RUNNABLE) {
    8000204e:	4909                	li	s2,2
    80002050:	b7c9                	j	80002012 <scheduler+0x80>

0000000080002052 <sched>:
{
    80002052:	7179                	addi	sp,sp,-48
    80002054:	f406                	sd	ra,40(sp)
    80002056:	f022                	sd	s0,32(sp)
    80002058:	ec26                	sd	s1,24(sp)
    8000205a:	e84a                	sd	s2,16(sp)
    8000205c:	e44e                	sd	s3,8(sp)
    8000205e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002060:	00000097          	auipc	ra,0x0
    80002064:	9f2080e7          	jalr	-1550(ra) # 80001a52 <myproc>
    80002068:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    8000206a:	fffff097          	auipc	ra,0xfffff
    8000206e:	ba0080e7          	jalr	-1120(ra) # 80000c0a <holding>
    80002072:	c93d                	beqz	a0,800020e8 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002074:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002076:	2781                	sext.w	a5,a5
    80002078:	079e                	slli	a5,a5,0x7
    8000207a:	00010717          	auipc	a4,0x10
    8000207e:	8d670713          	addi	a4,a4,-1834 # 80011950 <pid_lock>
    80002082:	97ba                	add	a5,a5,a4
    80002084:	0907a703          	lw	a4,144(a5)
    80002088:	4785                	li	a5,1
    8000208a:	06f71763          	bne	a4,a5,800020f8 <sched+0xa6>
  if(p->state == RUNNING)
    8000208e:	4c98                	lw	a4,24(s1)
    80002090:	478d                	li	a5,3
    80002092:	06f70b63          	beq	a4,a5,80002108 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002096:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000209a:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000209c:	efb5                	bnez	a5,80002118 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000209e:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020a0:	00010917          	auipc	s2,0x10
    800020a4:	8b090913          	addi	s2,s2,-1872 # 80011950 <pid_lock>
    800020a8:	2781                	sext.w	a5,a5
    800020aa:	079e                	slli	a5,a5,0x7
    800020ac:	97ca                	add	a5,a5,s2
    800020ae:	0947a983          	lw	s3,148(a5)
    800020b2:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020b4:	2781                	sext.w	a5,a5
    800020b6:	079e                	slli	a5,a5,0x7
    800020b8:	00010597          	auipc	a1,0x10
    800020bc:	8b858593          	addi	a1,a1,-1864 # 80011970 <cpus+0x8>
    800020c0:	95be                	add	a1,a1,a5
    800020c2:	06048513          	addi	a0,s1,96
    800020c6:	00000097          	auipc	ra,0x0
    800020ca:	564080e7          	jalr	1380(ra) # 8000262a <swtch>
    800020ce:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	97ca                	add	a5,a5,s2
    800020d6:	0937aa23          	sw	s3,148(a5)
}
    800020da:	70a2                	ld	ra,40(sp)
    800020dc:	7402                	ld	s0,32(sp)
    800020de:	64e2                	ld	s1,24(sp)
    800020e0:	6942                	ld	s2,16(sp)
    800020e2:	69a2                	ld	s3,8(sp)
    800020e4:	6145                	addi	sp,sp,48
    800020e6:	8082                	ret
    panic("sched p->lock");
    800020e8:	00006517          	auipc	a0,0x6
    800020ec:	13050513          	addi	a0,a0,304 # 80008218 <digits+0x1c0>
    800020f0:	ffffe097          	auipc	ra,0xffffe
    800020f4:	458080e7          	jalr	1112(ra) # 80000548 <panic>
    panic("sched locks");
    800020f8:	00006517          	auipc	a0,0x6
    800020fc:	13050513          	addi	a0,a0,304 # 80008228 <digits+0x1d0>
    80002100:	ffffe097          	auipc	ra,0xffffe
    80002104:	448080e7          	jalr	1096(ra) # 80000548 <panic>
    panic("sched running");
    80002108:	00006517          	auipc	a0,0x6
    8000210c:	13050513          	addi	a0,a0,304 # 80008238 <digits+0x1e0>
    80002110:	ffffe097          	auipc	ra,0xffffe
    80002114:	438080e7          	jalr	1080(ra) # 80000548 <panic>
    panic("sched interruptible");
    80002118:	00006517          	auipc	a0,0x6
    8000211c:	13050513          	addi	a0,a0,304 # 80008248 <digits+0x1f0>
    80002120:	ffffe097          	auipc	ra,0xffffe
    80002124:	428080e7          	jalr	1064(ra) # 80000548 <panic>

0000000080002128 <exit>:
{
    80002128:	7179                	addi	sp,sp,-48
    8000212a:	f406                	sd	ra,40(sp)
    8000212c:	f022                	sd	s0,32(sp)
    8000212e:	ec26                	sd	s1,24(sp)
    80002130:	e84a                	sd	s2,16(sp)
    80002132:	e44e                	sd	s3,8(sp)
    80002134:	e052                	sd	s4,0(sp)
    80002136:	1800                	addi	s0,sp,48
    80002138:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000213a:	00000097          	auipc	ra,0x0
    8000213e:	918080e7          	jalr	-1768(ra) # 80001a52 <myproc>
    80002142:	89aa                	mv	s3,a0
  if(p == initproc)
    80002144:	00007797          	auipc	a5,0x7
    80002148:	ed47b783          	ld	a5,-300(a5) # 80009018 <initproc>
    8000214c:	0d050493          	addi	s1,a0,208
    80002150:	15050913          	addi	s2,a0,336
    80002154:	02a79363          	bne	a5,a0,8000217a <exit+0x52>
    panic("init exiting");
    80002158:	00006517          	auipc	a0,0x6
    8000215c:	10850513          	addi	a0,a0,264 # 80008260 <digits+0x208>
    80002160:	ffffe097          	auipc	ra,0xffffe
    80002164:	3e8080e7          	jalr	1000(ra) # 80000548 <panic>
      fileclose(f);
    80002168:	00002097          	auipc	ra,0x2
    8000216c:	4a2080e7          	jalr	1186(ra) # 8000460a <fileclose>
      p->ofile[fd] = 0;
    80002170:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002174:	04a1                	addi	s1,s1,8
    80002176:	01248563          	beq	s1,s2,80002180 <exit+0x58>
    if(p->ofile[fd]){
    8000217a:	6088                	ld	a0,0(s1)
    8000217c:	f575                	bnez	a0,80002168 <exit+0x40>
    8000217e:	bfdd                	j	80002174 <exit+0x4c>
  begin_op();
    80002180:	00002097          	auipc	ra,0x2
    80002184:	fb8080e7          	jalr	-72(ra) # 80004138 <begin_op>
  iput(p->cwd);
    80002188:	1509b503          	ld	a0,336(s3)
    8000218c:	00001097          	auipc	ra,0x1
    80002190:	7aa080e7          	jalr	1962(ra) # 80003936 <iput>
  end_op();
    80002194:	00002097          	auipc	ra,0x2
    80002198:	024080e7          	jalr	36(ra) # 800041b8 <end_op>
  p->cwd = 0;
    8000219c:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    800021a0:	00007497          	auipc	s1,0x7
    800021a4:	e7848493          	addi	s1,s1,-392 # 80009018 <initproc>
    800021a8:	6088                	ld	a0,0(s1)
    800021aa:	fffff097          	auipc	ra,0xfffff
    800021ae:	ada080e7          	jalr	-1318(ra) # 80000c84 <acquire>
  wakeup1(initproc);
    800021b2:	6088                	ld	a0,0(s1)
    800021b4:	fffff097          	auipc	ra,0xfffff
    800021b8:	75e080e7          	jalr	1886(ra) # 80001912 <wakeup1>
  release(&initproc->lock);
    800021bc:	6088                	ld	a0,0(s1)
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	b7a080e7          	jalr	-1158(ra) # 80000d38 <release>
  acquire(&p->lock);
    800021c6:	854e                	mv	a0,s3
    800021c8:	fffff097          	auipc	ra,0xfffff
    800021cc:	abc080e7          	jalr	-1348(ra) # 80000c84 <acquire>
  struct proc *original_parent = p->parent;
    800021d0:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    800021d4:	854e                	mv	a0,s3
    800021d6:	fffff097          	auipc	ra,0xfffff
    800021da:	b62080e7          	jalr	-1182(ra) # 80000d38 <release>
  acquire(&original_parent->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	aa4080e7          	jalr	-1372(ra) # 80000c84 <acquire>
  acquire(&p->lock);
    800021e8:	854e                	mv	a0,s3
    800021ea:	fffff097          	auipc	ra,0xfffff
    800021ee:	a9a080e7          	jalr	-1382(ra) # 80000c84 <acquire>
  reparent(p);
    800021f2:	854e                	mv	a0,s3
    800021f4:	00000097          	auipc	ra,0x0
    800021f8:	d38080e7          	jalr	-712(ra) # 80001f2c <reparent>
  wakeup1(original_parent);
    800021fc:	8526                	mv	a0,s1
    800021fe:	fffff097          	auipc	ra,0xfffff
    80002202:	714080e7          	jalr	1812(ra) # 80001912 <wakeup1>
  p->xstate = status;
    80002206:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    8000220a:	4791                	li	a5,4
    8000220c:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002210:	8526                	mv	a0,s1
    80002212:	fffff097          	auipc	ra,0xfffff
    80002216:	b26080e7          	jalr	-1242(ra) # 80000d38 <release>
  sched();
    8000221a:	00000097          	auipc	ra,0x0
    8000221e:	e38080e7          	jalr	-456(ra) # 80002052 <sched>
  panic("zombie exit");
    80002222:	00006517          	auipc	a0,0x6
    80002226:	04e50513          	addi	a0,a0,78 # 80008270 <digits+0x218>
    8000222a:	ffffe097          	auipc	ra,0xffffe
    8000222e:	31e080e7          	jalr	798(ra) # 80000548 <panic>

0000000080002232 <yield>:
{
    80002232:	1101                	addi	sp,sp,-32
    80002234:	ec06                	sd	ra,24(sp)
    80002236:	e822                	sd	s0,16(sp)
    80002238:	e426                	sd	s1,8(sp)
    8000223a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000223c:	00000097          	auipc	ra,0x0
    80002240:	816080e7          	jalr	-2026(ra) # 80001a52 <myproc>
    80002244:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002246:	fffff097          	auipc	ra,0xfffff
    8000224a:	a3e080e7          	jalr	-1474(ra) # 80000c84 <acquire>
  p->state = RUNNABLE;
    8000224e:	4789                	li	a5,2
    80002250:	cc9c                	sw	a5,24(s1)
  sched();
    80002252:	00000097          	auipc	ra,0x0
    80002256:	e00080e7          	jalr	-512(ra) # 80002052 <sched>
  release(&p->lock);
    8000225a:	8526                	mv	a0,s1
    8000225c:	fffff097          	auipc	ra,0xfffff
    80002260:	adc080e7          	jalr	-1316(ra) # 80000d38 <release>
}
    80002264:	60e2                	ld	ra,24(sp)
    80002266:	6442                	ld	s0,16(sp)
    80002268:	64a2                	ld	s1,8(sp)
    8000226a:	6105                	addi	sp,sp,32
    8000226c:	8082                	ret

000000008000226e <sleep>:
{
    8000226e:	7179                	addi	sp,sp,-48
    80002270:	f406                	sd	ra,40(sp)
    80002272:	f022                	sd	s0,32(sp)
    80002274:	ec26                	sd	s1,24(sp)
    80002276:	e84a                	sd	s2,16(sp)
    80002278:	e44e                	sd	s3,8(sp)
    8000227a:	1800                	addi	s0,sp,48
    8000227c:	89aa                	mv	s3,a0
    8000227e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	7d2080e7          	jalr	2002(ra) # 80001a52 <myproc>
    80002288:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    8000228a:	05250663          	beq	a0,s2,800022d6 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    8000228e:	fffff097          	auipc	ra,0xfffff
    80002292:	9f6080e7          	jalr	-1546(ra) # 80000c84 <acquire>
    release(lk);
    80002296:	854a                	mv	a0,s2
    80002298:	fffff097          	auipc	ra,0xfffff
    8000229c:	aa0080e7          	jalr	-1376(ra) # 80000d38 <release>
  p->chan = chan;
    800022a0:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    800022a4:	4785                	li	a5,1
    800022a6:	cc9c                	sw	a5,24(s1)
  sched();
    800022a8:	00000097          	auipc	ra,0x0
    800022ac:	daa080e7          	jalr	-598(ra) # 80002052 <sched>
  p->chan = 0;
    800022b0:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    800022b4:	8526                	mv	a0,s1
    800022b6:	fffff097          	auipc	ra,0xfffff
    800022ba:	a82080e7          	jalr	-1406(ra) # 80000d38 <release>
    acquire(lk);
    800022be:	854a                	mv	a0,s2
    800022c0:	fffff097          	auipc	ra,0xfffff
    800022c4:	9c4080e7          	jalr	-1596(ra) # 80000c84 <acquire>
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6145                	addi	sp,sp,48
    800022d4:	8082                	ret
  p->chan = chan;
    800022d6:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    800022da:	4785                	li	a5,1
    800022dc:	cd1c                	sw	a5,24(a0)
  sched();
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	d74080e7          	jalr	-652(ra) # 80002052 <sched>
  p->chan = 0;
    800022e6:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    800022ea:	bff9                	j	800022c8 <sleep+0x5a>

00000000800022ec <wait>:
{
    800022ec:	715d                	addi	sp,sp,-80
    800022ee:	e486                	sd	ra,72(sp)
    800022f0:	e0a2                	sd	s0,64(sp)
    800022f2:	fc26                	sd	s1,56(sp)
    800022f4:	f84a                	sd	s2,48(sp)
    800022f6:	f44e                	sd	s3,40(sp)
    800022f8:	f052                	sd	s4,32(sp)
    800022fa:	ec56                	sd	s5,24(sp)
    800022fc:	e85a                	sd	s6,16(sp)
    800022fe:	e45e                	sd	s7,8(sp)
    80002300:	e062                	sd	s8,0(sp)
    80002302:	0880                	addi	s0,sp,80
    80002304:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002306:	fffff097          	auipc	ra,0xfffff
    8000230a:	74c080e7          	jalr	1868(ra) # 80001a52 <myproc>
    8000230e:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002310:	8c2a                	mv	s8,a0
    80002312:	fffff097          	auipc	ra,0xfffff
    80002316:	972080e7          	jalr	-1678(ra) # 80000c84 <acquire>
    havekids = 0;
    8000231a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000231c:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    8000231e:	0001a997          	auipc	s3,0x1a
    80002322:	24a98993          	addi	s3,s3,586 # 8001c568 <tickslock>
        havekids = 1;
    80002326:	4a85                	li	s5,1
    havekids = 0;
    80002328:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    8000232a:	00010497          	auipc	s1,0x10
    8000232e:	a3e48493          	addi	s1,s1,-1474 # 80011d68 <proc>
    80002332:	a08d                	j	80002394 <wait+0xa8>
          pid = np->pid;
    80002334:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002338:	000b0e63          	beqz	s6,80002354 <wait+0x68>
    8000233c:	4691                	li	a3,4
    8000233e:	03448613          	addi	a2,s1,52
    80002342:	85da                	mv	a1,s6
    80002344:	05093503          	ld	a0,80(s2)
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	3fe080e7          	jalr	1022(ra) # 80001746 <copyout>
    80002350:	02054263          	bltz	a0,80002374 <wait+0x88>
          freeproc(np);
    80002354:	8526                	mv	a0,s1
    80002356:	00000097          	auipc	ra,0x0
    8000235a:	8ae080e7          	jalr	-1874(ra) # 80001c04 <freeproc>
          release(&np->lock);
    8000235e:	8526                	mv	a0,s1
    80002360:	fffff097          	auipc	ra,0xfffff
    80002364:	9d8080e7          	jalr	-1576(ra) # 80000d38 <release>
          release(&p->lock);
    80002368:	854a                	mv	a0,s2
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	9ce080e7          	jalr	-1586(ra) # 80000d38 <release>
          return pid;
    80002372:	a8a9                	j	800023cc <wait+0xe0>
            release(&np->lock);
    80002374:	8526                	mv	a0,s1
    80002376:	fffff097          	auipc	ra,0xfffff
    8000237a:	9c2080e7          	jalr	-1598(ra) # 80000d38 <release>
            release(&p->lock);
    8000237e:	854a                	mv	a0,s2
    80002380:	fffff097          	auipc	ra,0xfffff
    80002384:	9b8080e7          	jalr	-1608(ra) # 80000d38 <release>
            return -1;
    80002388:	59fd                	li	s3,-1
    8000238a:	a089                	j	800023cc <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    8000238c:	2a048493          	addi	s1,s1,672
    80002390:	03348463          	beq	s1,s3,800023b8 <wait+0xcc>
      if(np->parent == p){
    80002394:	709c                	ld	a5,32(s1)
    80002396:	ff279be3          	bne	a5,s2,8000238c <wait+0xa0>
        acquire(&np->lock);
    8000239a:	8526                	mv	a0,s1
    8000239c:	fffff097          	auipc	ra,0xfffff
    800023a0:	8e8080e7          	jalr	-1816(ra) # 80000c84 <acquire>
        if(np->state == ZOMBIE){
    800023a4:	4c9c                	lw	a5,24(s1)
    800023a6:	f94787e3          	beq	a5,s4,80002334 <wait+0x48>
        release(&np->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	98c080e7          	jalr	-1652(ra) # 80000d38 <release>
        havekids = 1;
    800023b4:	8756                	mv	a4,s5
    800023b6:	bfd9                	j	8000238c <wait+0xa0>
    if(!havekids || p->killed){
    800023b8:	c701                	beqz	a4,800023c0 <wait+0xd4>
    800023ba:	03092783          	lw	a5,48(s2)
    800023be:	c785                	beqz	a5,800023e6 <wait+0xfa>
      release(&p->lock);
    800023c0:	854a                	mv	a0,s2
    800023c2:	fffff097          	auipc	ra,0xfffff
    800023c6:	976080e7          	jalr	-1674(ra) # 80000d38 <release>
      return -1;
    800023ca:	59fd                	li	s3,-1
}
    800023cc:	854e                	mv	a0,s3
    800023ce:	60a6                	ld	ra,72(sp)
    800023d0:	6406                	ld	s0,64(sp)
    800023d2:	74e2                	ld	s1,56(sp)
    800023d4:	7942                	ld	s2,48(sp)
    800023d6:	79a2                	ld	s3,40(sp)
    800023d8:	7a02                	ld	s4,32(sp)
    800023da:	6ae2                	ld	s5,24(sp)
    800023dc:	6b42                	ld	s6,16(sp)
    800023de:	6ba2                	ld	s7,8(sp)
    800023e0:	6c02                	ld	s8,0(sp)
    800023e2:	6161                	addi	sp,sp,80
    800023e4:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    800023e6:	85e2                	mv	a1,s8
    800023e8:	854a                	mv	a0,s2
    800023ea:	00000097          	auipc	ra,0x0
    800023ee:	e84080e7          	jalr	-380(ra) # 8000226e <sleep>
    havekids = 0;
    800023f2:	bf1d                	j	80002328 <wait+0x3c>

00000000800023f4 <wakeup>:
{
    800023f4:	7139                	addi	sp,sp,-64
    800023f6:	fc06                	sd	ra,56(sp)
    800023f8:	f822                	sd	s0,48(sp)
    800023fa:	f426                	sd	s1,40(sp)
    800023fc:	f04a                	sd	s2,32(sp)
    800023fe:	ec4e                	sd	s3,24(sp)
    80002400:	e852                	sd	s4,16(sp)
    80002402:	e456                	sd	s5,8(sp)
    80002404:	0080                	addi	s0,sp,64
    80002406:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002408:	00010497          	auipc	s1,0x10
    8000240c:	96048493          	addi	s1,s1,-1696 # 80011d68 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002410:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002412:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002414:	0001a917          	auipc	s2,0x1a
    80002418:	15490913          	addi	s2,s2,340 # 8001c568 <tickslock>
    8000241c:	a821                	j	80002434 <wakeup+0x40>
      p->state = RUNNABLE;
    8000241e:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002422:	8526                	mv	a0,s1
    80002424:	fffff097          	auipc	ra,0xfffff
    80002428:	914080e7          	jalr	-1772(ra) # 80000d38 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000242c:	2a048493          	addi	s1,s1,672
    80002430:	01248e63          	beq	s1,s2,8000244c <wakeup+0x58>
    acquire(&p->lock);
    80002434:	8526                	mv	a0,s1
    80002436:	fffff097          	auipc	ra,0xfffff
    8000243a:	84e080e7          	jalr	-1970(ra) # 80000c84 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    8000243e:	4c9c                	lw	a5,24(s1)
    80002440:	ff3791e3          	bne	a5,s3,80002422 <wakeup+0x2e>
    80002444:	749c                	ld	a5,40(s1)
    80002446:	fd479ee3          	bne	a5,s4,80002422 <wakeup+0x2e>
    8000244a:	bfd1                	j	8000241e <wakeup+0x2a>
}
    8000244c:	70e2                	ld	ra,56(sp)
    8000244e:	7442                	ld	s0,48(sp)
    80002450:	74a2                	ld	s1,40(sp)
    80002452:	7902                	ld	s2,32(sp)
    80002454:	69e2                	ld	s3,24(sp)
    80002456:	6a42                	ld	s4,16(sp)
    80002458:	6aa2                	ld	s5,8(sp)
    8000245a:	6121                	addi	sp,sp,64
    8000245c:	8082                	ret

000000008000245e <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000245e:	7179                	addi	sp,sp,-48
    80002460:	f406                	sd	ra,40(sp)
    80002462:	f022                	sd	s0,32(sp)
    80002464:	ec26                	sd	s1,24(sp)
    80002466:	e84a                	sd	s2,16(sp)
    80002468:	e44e                	sd	s3,8(sp)
    8000246a:	1800                	addi	s0,sp,48
    8000246c:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000246e:	00010497          	auipc	s1,0x10
    80002472:	8fa48493          	addi	s1,s1,-1798 # 80011d68 <proc>
    80002476:	0001a997          	auipc	s3,0x1a
    8000247a:	0f298993          	addi	s3,s3,242 # 8001c568 <tickslock>
    acquire(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	804080e7          	jalr	-2044(ra) # 80000c84 <acquire>
    if(p->pid == pid){
    80002488:	5c9c                	lw	a5,56(s1)
    8000248a:	01278d63          	beq	a5,s2,800024a4 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	8a8080e7          	jalr	-1880(ra) # 80000d38 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002498:	2a048493          	addi	s1,s1,672
    8000249c:	ff3491e3          	bne	s1,s3,8000247e <kill+0x20>
  }
  return -1;
    800024a0:	557d                	li	a0,-1
    800024a2:	a829                	j	800024bc <kill+0x5e>
      p->killed = 1;
    800024a4:	4785                	li	a5,1
    800024a6:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    800024a8:	4c98                	lw	a4,24(s1)
    800024aa:	4785                	li	a5,1
    800024ac:	00f70f63          	beq	a4,a5,800024ca <kill+0x6c>
      release(&p->lock);
    800024b0:	8526                	mv	a0,s1
    800024b2:	fffff097          	auipc	ra,0xfffff
    800024b6:	886080e7          	jalr	-1914(ra) # 80000d38 <release>
      return 0;
    800024ba:	4501                	li	a0,0
}
    800024bc:	70a2                	ld	ra,40(sp)
    800024be:	7402                	ld	s0,32(sp)
    800024c0:	64e2                	ld	s1,24(sp)
    800024c2:	6942                	ld	s2,16(sp)
    800024c4:	69a2                	ld	s3,8(sp)
    800024c6:	6145                	addi	sp,sp,48
    800024c8:	8082                	ret
        p->state = RUNNABLE;
    800024ca:	4789                	li	a5,2
    800024cc:	cc9c                	sw	a5,24(s1)
    800024ce:	b7cd                	j	800024b0 <kill+0x52>

00000000800024d0 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024d0:	7179                	addi	sp,sp,-48
    800024d2:	f406                	sd	ra,40(sp)
    800024d4:	f022                	sd	s0,32(sp)
    800024d6:	ec26                	sd	s1,24(sp)
    800024d8:	e84a                	sd	s2,16(sp)
    800024da:	e44e                	sd	s3,8(sp)
    800024dc:	e052                	sd	s4,0(sp)
    800024de:	1800                	addi	s0,sp,48
    800024e0:	84aa                	mv	s1,a0
    800024e2:	892e                	mv	s2,a1
    800024e4:	89b2                	mv	s3,a2
    800024e6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024e8:	fffff097          	auipc	ra,0xfffff
    800024ec:	56a080e7          	jalr	1386(ra) # 80001a52 <myproc>
  if(user_dst){
    800024f0:	c08d                	beqz	s1,80002512 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024f2:	86d2                	mv	a3,s4
    800024f4:	864e                	mv	a2,s3
    800024f6:	85ca                	mv	a1,s2
    800024f8:	6928                	ld	a0,80(a0)
    800024fa:	fffff097          	auipc	ra,0xfffff
    800024fe:	24c080e7          	jalr	588(ra) # 80001746 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002502:	70a2                	ld	ra,40(sp)
    80002504:	7402                	ld	s0,32(sp)
    80002506:	64e2                	ld	s1,24(sp)
    80002508:	6942                	ld	s2,16(sp)
    8000250a:	69a2                	ld	s3,8(sp)
    8000250c:	6a02                	ld	s4,0(sp)
    8000250e:	6145                	addi	sp,sp,48
    80002510:	8082                	ret
    memmove((char *)dst, src, len);
    80002512:	000a061b          	sext.w	a2,s4
    80002516:	85ce                	mv	a1,s3
    80002518:	854a                	mv	a0,s2
    8000251a:	fffff097          	auipc	ra,0xfffff
    8000251e:	8c6080e7          	jalr	-1850(ra) # 80000de0 <memmove>
    return 0;
    80002522:	8526                	mv	a0,s1
    80002524:	bff9                	j	80002502 <either_copyout+0x32>

0000000080002526 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002526:	7179                	addi	sp,sp,-48
    80002528:	f406                	sd	ra,40(sp)
    8000252a:	f022                	sd	s0,32(sp)
    8000252c:	ec26                	sd	s1,24(sp)
    8000252e:	e84a                	sd	s2,16(sp)
    80002530:	e44e                	sd	s3,8(sp)
    80002532:	e052                	sd	s4,0(sp)
    80002534:	1800                	addi	s0,sp,48
    80002536:	892a                	mv	s2,a0
    80002538:	84ae                	mv	s1,a1
    8000253a:	89b2                	mv	s3,a2
    8000253c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000253e:	fffff097          	auipc	ra,0xfffff
    80002542:	514080e7          	jalr	1300(ra) # 80001a52 <myproc>
  if(user_src){
    80002546:	c08d                	beqz	s1,80002568 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002548:	86d2                	mv	a3,s4
    8000254a:	864e                	mv	a2,s3
    8000254c:	85ca                	mv	a1,s2
    8000254e:	6928                	ld	a0,80(a0)
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	282080e7          	jalr	642(ra) # 800017d2 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002558:	70a2                	ld	ra,40(sp)
    8000255a:	7402                	ld	s0,32(sp)
    8000255c:	64e2                	ld	s1,24(sp)
    8000255e:	6942                	ld	s2,16(sp)
    80002560:	69a2                	ld	s3,8(sp)
    80002562:	6a02                	ld	s4,0(sp)
    80002564:	6145                	addi	sp,sp,48
    80002566:	8082                	ret
    memmove(dst, (char*)src, len);
    80002568:	000a061b          	sext.w	a2,s4
    8000256c:	85ce                	mv	a1,s3
    8000256e:	854a                	mv	a0,s2
    80002570:	fffff097          	auipc	ra,0xfffff
    80002574:	870080e7          	jalr	-1936(ra) # 80000de0 <memmove>
    return 0;
    80002578:	8526                	mv	a0,s1
    8000257a:	bff9                	j	80002558 <either_copyin+0x32>

000000008000257c <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    8000257c:	715d                	addi	sp,sp,-80
    8000257e:	e486                	sd	ra,72(sp)
    80002580:	e0a2                	sd	s0,64(sp)
    80002582:	fc26                	sd	s1,56(sp)
    80002584:	f84a                	sd	s2,48(sp)
    80002586:	f44e                	sd	s3,40(sp)
    80002588:	f052                	sd	s4,32(sp)
    8000258a:	ec56                	sd	s5,24(sp)
    8000258c:	e85a                	sd	s6,16(sp)
    8000258e:	e45e                	sd	s7,8(sp)
    80002590:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002592:	00006517          	auipc	a0,0x6
    80002596:	b4e50513          	addi	a0,a0,-1202 # 800080e0 <digits+0x88>
    8000259a:	ffffe097          	auipc	ra,0xffffe
    8000259e:	000080e7          	jalr	ra # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025a2:	00010497          	auipc	s1,0x10
    800025a6:	91e48493          	addi	s1,s1,-1762 # 80011ec0 <proc+0x158>
    800025aa:	0001a917          	auipc	s2,0x1a
    800025ae:	11690913          	addi	s2,s2,278 # 8001c6c0 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025b2:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800025b4:	00006997          	auipc	s3,0x6
    800025b8:	ccc98993          	addi	s3,s3,-820 # 80008280 <digits+0x228>
    printf("%d %s %s", p->pid, state, p->name);
    800025bc:	00006a97          	auipc	s5,0x6
    800025c0:	ccca8a93          	addi	s5,s5,-820 # 80008288 <digits+0x230>
    printf("\n");
    800025c4:	00006a17          	auipc	s4,0x6
    800025c8:	b1ca0a13          	addi	s4,s4,-1252 # 800080e0 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025cc:	00006b97          	auipc	s7,0x6
    800025d0:	cf4b8b93          	addi	s7,s7,-780 # 800082c0 <states.1712>
    800025d4:	a00d                	j	800025f6 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025d6:	ee06a583          	lw	a1,-288(a3)
    800025da:	8556                	mv	a0,s5
    800025dc:	ffffe097          	auipc	ra,0xffffe
    800025e0:	fbe080e7          	jalr	-66(ra) # 8000059a <printf>
    printf("\n");
    800025e4:	8552                	mv	a0,s4
    800025e6:	ffffe097          	auipc	ra,0xffffe
    800025ea:	fb4080e7          	jalr	-76(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025ee:	2a048493          	addi	s1,s1,672
    800025f2:	03248163          	beq	s1,s2,80002614 <procdump+0x98>
    if(p->state == UNUSED)
    800025f6:	86a6                	mv	a3,s1
    800025f8:	ec04a783          	lw	a5,-320(s1)
    800025fc:	dbed                	beqz	a5,800025ee <procdump+0x72>
      state = "???";
    800025fe:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002600:	fcfb6be3          	bltu	s6,a5,800025d6 <procdump+0x5a>
    80002604:	1782                	slli	a5,a5,0x20
    80002606:	9381                	srli	a5,a5,0x20
    80002608:	078e                	slli	a5,a5,0x3
    8000260a:	97de                	add	a5,a5,s7
    8000260c:	6390                	ld	a2,0(a5)
    8000260e:	f661                	bnez	a2,800025d6 <procdump+0x5a>
      state = "???";
    80002610:	864e                	mv	a2,s3
    80002612:	b7d1                	j	800025d6 <procdump+0x5a>
  }
}
    80002614:	60a6                	ld	ra,72(sp)
    80002616:	6406                	ld	s0,64(sp)
    80002618:	74e2                	ld	s1,56(sp)
    8000261a:	7942                	ld	s2,48(sp)
    8000261c:	79a2                	ld	s3,40(sp)
    8000261e:	7a02                	ld	s4,32(sp)
    80002620:	6ae2                	ld	s5,24(sp)
    80002622:	6b42                	ld	s6,16(sp)
    80002624:	6ba2                	ld	s7,8(sp)
    80002626:	6161                	addi	sp,sp,80
    80002628:	8082                	ret

000000008000262a <swtch>:
    8000262a:	00153023          	sd	ra,0(a0)
    8000262e:	00253423          	sd	sp,8(a0)
    80002632:	e900                	sd	s0,16(a0)
    80002634:	ed04                	sd	s1,24(a0)
    80002636:	03253023          	sd	s2,32(a0)
    8000263a:	03353423          	sd	s3,40(a0)
    8000263e:	03453823          	sd	s4,48(a0)
    80002642:	03553c23          	sd	s5,56(a0)
    80002646:	05653023          	sd	s6,64(a0)
    8000264a:	05753423          	sd	s7,72(a0)
    8000264e:	05853823          	sd	s8,80(a0)
    80002652:	05953c23          	sd	s9,88(a0)
    80002656:	07a53023          	sd	s10,96(a0)
    8000265a:	07b53423          	sd	s11,104(a0)
    8000265e:	0005b083          	ld	ra,0(a1)
    80002662:	0085b103          	ld	sp,8(a1)
    80002666:	6980                	ld	s0,16(a1)
    80002668:	6d84                	ld	s1,24(a1)
    8000266a:	0205b903          	ld	s2,32(a1)
    8000266e:	0285b983          	ld	s3,40(a1)
    80002672:	0305ba03          	ld	s4,48(a1)
    80002676:	0385ba83          	ld	s5,56(a1)
    8000267a:	0405bb03          	ld	s6,64(a1)
    8000267e:	0485bb83          	ld	s7,72(a1)
    80002682:	0505bc03          	ld	s8,80(a1)
    80002686:	0585bc83          	ld	s9,88(a1)
    8000268a:	0605bd03          	ld	s10,96(a1)
    8000268e:	0685bd83          	ld	s11,104(a1)
    80002692:	8082                	ret

0000000080002694 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002694:	1141                	addi	sp,sp,-16
    80002696:	e406                	sd	ra,8(sp)
    80002698:	e022                	sd	s0,0(sp)
    8000269a:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000269c:	00006597          	auipc	a1,0x6
    800026a0:	c4c58593          	addi	a1,a1,-948 # 800082e8 <states.1712+0x28>
    800026a4:	0001a517          	auipc	a0,0x1a
    800026a8:	ec450513          	addi	a0,a0,-316 # 8001c568 <tickslock>
    800026ac:	ffffe097          	auipc	ra,0xffffe
    800026b0:	548080e7          	jalr	1352(ra) # 80000bf4 <initlock>
}
    800026b4:	60a2                	ld	ra,8(sp)
    800026b6:	6402                	ld	s0,0(sp)
    800026b8:	0141                	addi	sp,sp,16
    800026ba:	8082                	ret

00000000800026bc <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026bc:	1141                	addi	sp,sp,-16
    800026be:	e422                	sd	s0,8(sp)
    800026c0:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026c2:	00003797          	auipc	a5,0x3
    800026c6:	5ae78793          	addi	a5,a5,1454 # 80005c70 <kernelvec>
    800026ca:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800026ce:	6422                	ld	s0,8(sp)
    800026d0:	0141                	addi	sp,sp,16
    800026d2:	8082                	ret

00000000800026d4 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800026d4:	1141                	addi	sp,sp,-16
    800026d6:	e406                	sd	ra,8(sp)
    800026d8:	e022                	sd	s0,0(sp)
    800026da:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800026dc:	fffff097          	auipc	ra,0xfffff
    800026e0:	376080e7          	jalr	886(ra) # 80001a52 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800026e4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800026e8:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800026ea:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800026ee:	00005617          	auipc	a2,0x5
    800026f2:	91260613          	addi	a2,a2,-1774 # 80007000 <_trampoline>
    800026f6:	00005697          	auipc	a3,0x5
    800026fa:	90a68693          	addi	a3,a3,-1782 # 80007000 <_trampoline>
    800026fe:	8e91                	sub	a3,a3,a2
    80002700:	040007b7          	lui	a5,0x4000
    80002704:	17fd                	addi	a5,a5,-1
    80002706:	07b2                	slli	a5,a5,0xc
    80002708:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000270a:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    8000270e:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002710:	180026f3          	csrr	a3,satp
    80002714:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002716:	6d38                	ld	a4,88(a0)
    80002718:	6134                	ld	a3,64(a0)
    8000271a:	6585                	lui	a1,0x1
    8000271c:	96ae                	add	a3,a3,a1
    8000271e:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002720:	6d38                	ld	a4,88(a0)
    80002722:	00000697          	auipc	a3,0x0
    80002726:	13868693          	addi	a3,a3,312 # 8000285a <usertrap>
    8000272a:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000272c:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000272e:	8692                	mv	a3,tp
    80002730:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002732:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002736:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000273a:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000273e:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002742:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002744:	6f18                	ld	a4,24(a4)
    80002746:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000274a:	692c                	ld	a1,80(a0)
    8000274c:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    8000274e:	00005717          	auipc	a4,0x5
    80002752:	94270713          	addi	a4,a4,-1726 # 80007090 <userret>
    80002756:	8f11                	sub	a4,a4,a2
    80002758:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    8000275a:	577d                	li	a4,-1
    8000275c:	177e                	slli	a4,a4,0x3f
    8000275e:	8dd9                	or	a1,a1,a4
    80002760:	02000537          	lui	a0,0x2000
    80002764:	157d                	addi	a0,a0,-1
    80002766:	0536                	slli	a0,a0,0xd
    80002768:	9782                	jalr	a5
}
    8000276a:	60a2                	ld	ra,8(sp)
    8000276c:	6402                	ld	s0,0(sp)
    8000276e:	0141                	addi	sp,sp,16
    80002770:	8082                	ret

0000000080002772 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002772:	1101                	addi	sp,sp,-32
    80002774:	ec06                	sd	ra,24(sp)
    80002776:	e822                	sd	s0,16(sp)
    80002778:	e426                	sd	s1,8(sp)
    8000277a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    8000277c:	0001a497          	auipc	s1,0x1a
    80002780:	dec48493          	addi	s1,s1,-532 # 8001c568 <tickslock>
    80002784:	8526                	mv	a0,s1
    80002786:	ffffe097          	auipc	ra,0xffffe
    8000278a:	4fe080e7          	jalr	1278(ra) # 80000c84 <acquire>
  ticks++;
    8000278e:	00007517          	auipc	a0,0x7
    80002792:	89250513          	addi	a0,a0,-1902 # 80009020 <ticks>
    80002796:	411c                	lw	a5,0(a0)
    80002798:	2785                	addiw	a5,a5,1
    8000279a:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    8000279c:	00000097          	auipc	ra,0x0
    800027a0:	c58080e7          	jalr	-936(ra) # 800023f4 <wakeup>
  release(&tickslock);
    800027a4:	8526                	mv	a0,s1
    800027a6:	ffffe097          	auipc	ra,0xffffe
    800027aa:	592080e7          	jalr	1426(ra) # 80000d38 <release>
}
    800027ae:	60e2                	ld	ra,24(sp)
    800027b0:	6442                	ld	s0,16(sp)
    800027b2:	64a2                	ld	s1,8(sp)
    800027b4:	6105                	addi	sp,sp,32
    800027b6:	8082                	ret

00000000800027b8 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027b8:	1101                	addi	sp,sp,-32
    800027ba:	ec06                	sd	ra,24(sp)
    800027bc:	e822                	sd	s0,16(sp)
    800027be:	e426                	sd	s1,8(sp)
    800027c0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027c2:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027c6:	00074d63          	bltz	a4,800027e0 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027ca:	57fd                	li	a5,-1
    800027cc:	17fe                	slli	a5,a5,0x3f
    800027ce:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027d0:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027d2:	06f70363          	beq	a4,a5,80002838 <devintr+0x80>
  }
}
    800027d6:	60e2                	ld	ra,24(sp)
    800027d8:	6442                	ld	s0,16(sp)
    800027da:	64a2                	ld	s1,8(sp)
    800027dc:	6105                	addi	sp,sp,32
    800027de:	8082                	ret
     (scause & 0xff) == 9){
    800027e0:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800027e4:	46a5                	li	a3,9
    800027e6:	fed792e3          	bne	a5,a3,800027ca <devintr+0x12>
    int irq = plic_claim();
    800027ea:	00003097          	auipc	ra,0x3
    800027ee:	58e080e7          	jalr	1422(ra) # 80005d78 <plic_claim>
    800027f2:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800027f4:	47a9                	li	a5,10
    800027f6:	02f50763          	beq	a0,a5,80002824 <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800027fa:	4785                	li	a5,1
    800027fc:	02f50963          	beq	a0,a5,8000282e <devintr+0x76>
    return 1;
    80002800:	4505                	li	a0,1
    } else if(irq){
    80002802:	d8f1                	beqz	s1,800027d6 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002804:	85a6                	mv	a1,s1
    80002806:	00006517          	auipc	a0,0x6
    8000280a:	aea50513          	addi	a0,a0,-1302 # 800082f0 <states.1712+0x30>
    8000280e:	ffffe097          	auipc	ra,0xffffe
    80002812:	d8c080e7          	jalr	-628(ra) # 8000059a <printf>
      plic_complete(irq);
    80002816:	8526                	mv	a0,s1
    80002818:	00003097          	auipc	ra,0x3
    8000281c:	584080e7          	jalr	1412(ra) # 80005d9c <plic_complete>
    return 1;
    80002820:	4505                	li	a0,1
    80002822:	bf55                	j	800027d6 <devintr+0x1e>
      uartintr();
    80002824:	ffffe097          	auipc	ra,0xffffe
    80002828:	224080e7          	jalr	548(ra) # 80000a48 <uartintr>
    8000282c:	b7ed                	j	80002816 <devintr+0x5e>
      virtio_disk_intr();
    8000282e:	00004097          	auipc	ra,0x4
    80002832:	a08080e7          	jalr	-1528(ra) # 80006236 <virtio_disk_intr>
    80002836:	b7c5                	j	80002816 <devintr+0x5e>
    if(cpuid() == 0){
    80002838:	fffff097          	auipc	ra,0xfffff
    8000283c:	1ee080e7          	jalr	494(ra) # 80001a26 <cpuid>
    80002840:	c901                	beqz	a0,80002850 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002842:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002846:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002848:	14479073          	csrw	sip,a5
    return 2;
    8000284c:	4509                	li	a0,2
    8000284e:	b761                	j	800027d6 <devintr+0x1e>
      clockintr();
    80002850:	00000097          	auipc	ra,0x0
    80002854:	f22080e7          	jalr	-222(ra) # 80002772 <clockintr>
    80002858:	b7ed                	j	80002842 <devintr+0x8a>

000000008000285a <usertrap>:
{
    8000285a:	1101                	addi	sp,sp,-32
    8000285c:	ec06                	sd	ra,24(sp)
    8000285e:	e822                	sd	s0,16(sp)
    80002860:	e426                	sd	s1,8(sp)
    80002862:	e04a                	sd	s2,0(sp)
    80002864:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002866:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    8000286a:	1007f793          	andi	a5,a5,256
    8000286e:	e3ad                	bnez	a5,800028d0 <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002870:	00003797          	auipc	a5,0x3
    80002874:	40078793          	addi	a5,a5,1024 # 80005c70 <kernelvec>
    80002878:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    8000287c:	fffff097          	auipc	ra,0xfffff
    80002880:	1d6080e7          	jalr	470(ra) # 80001a52 <myproc>
    80002884:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002886:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002888:	14102773          	csrr	a4,sepc
    8000288c:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000288e:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002892:	47a1                	li	a5,8
    80002894:	04f71c63          	bne	a4,a5,800028ec <usertrap+0x92>
    if(p->killed)
    80002898:	591c                	lw	a5,48(a0)
    8000289a:	e3b9                	bnez	a5,800028e0 <usertrap+0x86>
    p->trapframe->epc += 4;
    8000289c:	6cb8                	ld	a4,88(s1)
    8000289e:	6f1c                	ld	a5,24(a4)
    800028a0:	0791                	addi	a5,a5,4
    800028a2:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028a4:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800028a8:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028ac:	10079073          	csrw	sstatus,a5
    syscall();
    800028b0:	00000097          	auipc	ra,0x0
    800028b4:	324080e7          	jalr	804(ra) # 80002bd4 <syscall>
  if(p->killed)
    800028b8:	589c                	lw	a5,48(s1)
    800028ba:	e7dd                	bnez	a5,80002968 <usertrap+0x10e>
  usertrapret();
    800028bc:	00000097          	auipc	ra,0x0
    800028c0:	e18080e7          	jalr	-488(ra) # 800026d4 <usertrapret>
}
    800028c4:	60e2                	ld	ra,24(sp)
    800028c6:	6442                	ld	s0,16(sp)
    800028c8:	64a2                	ld	s1,8(sp)
    800028ca:	6902                	ld	s2,0(sp)
    800028cc:	6105                	addi	sp,sp,32
    800028ce:	8082                	ret
    panic("usertrap: not from user mode");
    800028d0:	00006517          	auipc	a0,0x6
    800028d4:	a4050513          	addi	a0,a0,-1472 # 80008310 <states.1712+0x50>
    800028d8:	ffffe097          	auipc	ra,0xffffe
    800028dc:	c70080e7          	jalr	-912(ra) # 80000548 <panic>
      exit(-1);
    800028e0:	557d                	li	a0,-1
    800028e2:	00000097          	auipc	ra,0x0
    800028e6:	846080e7          	jalr	-1978(ra) # 80002128 <exit>
    800028ea:	bf4d                	j	8000289c <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	ecc080e7          	jalr	-308(ra) # 800027b8 <devintr>
    800028f4:	892a                	mv	s2,a0
    800028f6:	c501                	beqz	a0,800028fe <usertrap+0xa4>
  if(p->killed)
    800028f8:	589c                	lw	a5,48(s1)
    800028fa:	c3a1                	beqz	a5,8000293a <usertrap+0xe0>
    800028fc:	a815                	j	80002930 <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028fe:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002902:	5c90                	lw	a2,56(s1)
    80002904:	00006517          	auipc	a0,0x6
    80002908:	a2c50513          	addi	a0,a0,-1492 # 80008330 <states.1712+0x70>
    8000290c:	ffffe097          	auipc	ra,0xffffe
    80002910:	c8e080e7          	jalr	-882(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002914:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002918:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000291c:	00006517          	auipc	a0,0x6
    80002920:	a4450513          	addi	a0,a0,-1468 # 80008360 <states.1712+0xa0>
    80002924:	ffffe097          	auipc	ra,0xffffe
    80002928:	c76080e7          	jalr	-906(ra) # 8000059a <printf>
    p->killed = 1;
    8000292c:	4785                	li	a5,1
    8000292e:	d89c                	sw	a5,48(s1)
    exit(-1);
    80002930:	557d                	li	a0,-1
    80002932:	fffff097          	auipc	ra,0xfffff
    80002936:	7f6080e7          	jalr	2038(ra) # 80002128 <exit>
  if(which_dev == 2)
    8000293a:	4789                	li	a5,2
    8000293c:	f8f910e3          	bne	s2,a5,800028bc <usertrap+0x62>
    if (p->alarm_interval != 0 && !p->block)
    80002940:	1684a783          	lw	a5,360(s1)
    80002944:	cf89                	beqz	a5,8000295e <usertrap+0x104>
    80002946:	1784a703          	lw	a4,376(s1)
    8000294a:	eb11                	bnez	a4,8000295e <usertrap+0x104>
      p->passed_ticks++;
    8000294c:	16c4a703          	lw	a4,364(s1)
    80002950:	2705                	addiw	a4,a4,1
    80002952:	0007069b          	sext.w	a3,a4
      if (p->passed_ticks == p->alarm_interval)
    80002956:	00d78b63          	beq	a5,a3,8000296c <usertrap+0x112>
      p->passed_ticks++;
    8000295a:	16e4a623          	sw	a4,364(s1)
    yield();
    8000295e:	00000097          	auipc	ra,0x0
    80002962:	8d4080e7          	jalr	-1836(ra) # 80002232 <yield>
    80002966:	bf99                	j	800028bc <usertrap+0x62>
  int which_dev = 0;
    80002968:	4901                	li	s2,0
    8000296a:	b7d9                	j	80002930 <usertrap+0xd6>
        p->passed_ticks = 0;
    8000296c:	1604a623          	sw	zero,364(s1)
        p->block = 1;
    80002970:	4785                	li	a5,1
    80002972:	16f4ac23          	sw	a5,376(s1)
        memmove((void *)p->reg_buf, (void *)p->trapframe, sizeof(struct trapframe));
    80002976:	12000613          	li	a2,288
    8000297a:	6cac                	ld	a1,88(s1)
    8000297c:	17c48513          	addi	a0,s1,380
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	460080e7          	jalr	1120(ra) # 80000de0 <memmove>
        p->trapframe->epc = p->alarm_handler;
    80002988:	6cbc                	ld	a5,88(s1)
    8000298a:	1704b703          	ld	a4,368(s1)
    8000298e:	ef98                	sd	a4,24(a5)
    80002990:	b7f9                	j	8000295e <usertrap+0x104>

0000000080002992 <kerneltrap>:
{
    80002992:	7179                	addi	sp,sp,-48
    80002994:	f406                	sd	ra,40(sp)
    80002996:	f022                	sd	s0,32(sp)
    80002998:	ec26                	sd	s1,24(sp)
    8000299a:	e84a                	sd	s2,16(sp)
    8000299c:	e44e                	sd	s3,8(sp)
    8000299e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029a8:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ac:	1004f793          	andi	a5,s1,256
    800029b0:	cb85                	beqz	a5,800029e0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029b6:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029b8:	ef85                	bnez	a5,800029f0 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029ba:	00000097          	auipc	ra,0x0
    800029be:	dfe080e7          	jalr	-514(ra) # 800027b8 <devintr>
    800029c2:	cd1d                	beqz	a0,80002a00 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c4:	4789                	li	a5,2
    800029c6:	06f50a63          	beq	a0,a5,80002a3a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029ca:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029ce:	10049073          	csrw	sstatus,s1
}
    800029d2:	70a2                	ld	ra,40(sp)
    800029d4:	7402                	ld	s0,32(sp)
    800029d6:	64e2                	ld	s1,24(sp)
    800029d8:	6942                	ld	s2,16(sp)
    800029da:	69a2                	ld	s3,8(sp)
    800029dc:	6145                	addi	sp,sp,48
    800029de:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029e0:	00006517          	auipc	a0,0x6
    800029e4:	9a050513          	addi	a0,a0,-1632 # 80008380 <states.1712+0xc0>
    800029e8:	ffffe097          	auipc	ra,0xffffe
    800029ec:	b60080e7          	jalr	-1184(ra) # 80000548 <panic>
    panic("kerneltrap: interrupts enabled");
    800029f0:	00006517          	auipc	a0,0x6
    800029f4:	9b850513          	addi	a0,a0,-1608 # 800083a8 <states.1712+0xe8>
    800029f8:	ffffe097          	auipc	ra,0xffffe
    800029fc:	b50080e7          	jalr	-1200(ra) # 80000548 <panic>
    printf("scause %p\n", scause);
    80002a00:	85ce                	mv	a1,s3
    80002a02:	00006517          	auipc	a0,0x6
    80002a06:	9c650513          	addi	a0,a0,-1594 # 800083c8 <states.1712+0x108>
    80002a0a:	ffffe097          	auipc	ra,0xffffe
    80002a0e:	b90080e7          	jalr	-1136(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a16:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1a:	00006517          	auipc	a0,0x6
    80002a1e:	9be50513          	addi	a0,a0,-1602 # 800083d8 <states.1712+0x118>
    80002a22:	ffffe097          	auipc	ra,0xffffe
    80002a26:	b78080e7          	jalr	-1160(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002a2a:	00006517          	auipc	a0,0x6
    80002a2e:	9c650513          	addi	a0,a0,-1594 # 800083f0 <states.1712+0x130>
    80002a32:	ffffe097          	auipc	ra,0xffffe
    80002a36:	b16080e7          	jalr	-1258(ra) # 80000548 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a3a:	fffff097          	auipc	ra,0xfffff
    80002a3e:	018080e7          	jalr	24(ra) # 80001a52 <myproc>
    80002a42:	d541                	beqz	a0,800029ca <kerneltrap+0x38>
    80002a44:	fffff097          	auipc	ra,0xfffff
    80002a48:	00e080e7          	jalr	14(ra) # 80001a52 <myproc>
    80002a4c:	4d18                	lw	a4,24(a0)
    80002a4e:	478d                	li	a5,3
    80002a50:	f6f71de3          	bne	a4,a5,800029ca <kerneltrap+0x38>
    yield();
    80002a54:	fffff097          	auipc	ra,0xfffff
    80002a58:	7de080e7          	jalr	2014(ra) # 80002232 <yield>
    80002a5c:	b7bd                	j	800029ca <kerneltrap+0x38>

0000000080002a5e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a5e:	1101                	addi	sp,sp,-32
    80002a60:	ec06                	sd	ra,24(sp)
    80002a62:	e822                	sd	s0,16(sp)
    80002a64:	e426                	sd	s1,8(sp)
    80002a66:	1000                	addi	s0,sp,32
    80002a68:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a6a:	fffff097          	auipc	ra,0xfffff
    80002a6e:	fe8080e7          	jalr	-24(ra) # 80001a52 <myproc>
  switch (n) {
    80002a72:	4795                	li	a5,5
    80002a74:	0497e163          	bltu	a5,s1,80002ab6 <argraw+0x58>
    80002a78:	048a                	slli	s1,s1,0x2
    80002a7a:	00006717          	auipc	a4,0x6
    80002a7e:	9ae70713          	addi	a4,a4,-1618 # 80008428 <states.1712+0x168>
    80002a82:	94ba                	add	s1,s1,a4
    80002a84:	409c                	lw	a5,0(s1)
    80002a86:	97ba                	add	a5,a5,a4
    80002a88:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a8a:	6d3c                	ld	a5,88(a0)
    80002a8c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a8e:	60e2                	ld	ra,24(sp)
    80002a90:	6442                	ld	s0,16(sp)
    80002a92:	64a2                	ld	s1,8(sp)
    80002a94:	6105                	addi	sp,sp,32
    80002a96:	8082                	ret
    return p->trapframe->a1;
    80002a98:	6d3c                	ld	a5,88(a0)
    80002a9a:	7fa8                	ld	a0,120(a5)
    80002a9c:	bfcd                	j	80002a8e <argraw+0x30>
    return p->trapframe->a2;
    80002a9e:	6d3c                	ld	a5,88(a0)
    80002aa0:	63c8                	ld	a0,128(a5)
    80002aa2:	b7f5                	j	80002a8e <argraw+0x30>
    return p->trapframe->a3;
    80002aa4:	6d3c                	ld	a5,88(a0)
    80002aa6:	67c8                	ld	a0,136(a5)
    80002aa8:	b7dd                	j	80002a8e <argraw+0x30>
    return p->trapframe->a4;
    80002aaa:	6d3c                	ld	a5,88(a0)
    80002aac:	6bc8                	ld	a0,144(a5)
    80002aae:	b7c5                	j	80002a8e <argraw+0x30>
    return p->trapframe->a5;
    80002ab0:	6d3c                	ld	a5,88(a0)
    80002ab2:	6fc8                	ld	a0,152(a5)
    80002ab4:	bfe9                	j	80002a8e <argraw+0x30>
  panic("argraw");
    80002ab6:	00006517          	auipc	a0,0x6
    80002aba:	94a50513          	addi	a0,a0,-1718 # 80008400 <states.1712+0x140>
    80002abe:	ffffe097          	auipc	ra,0xffffe
    80002ac2:	a8a080e7          	jalr	-1398(ra) # 80000548 <panic>

0000000080002ac6 <fetchaddr>:
{
    80002ac6:	1101                	addi	sp,sp,-32
    80002ac8:	ec06                	sd	ra,24(sp)
    80002aca:	e822                	sd	s0,16(sp)
    80002acc:	e426                	sd	s1,8(sp)
    80002ace:	e04a                	sd	s2,0(sp)
    80002ad0:	1000                	addi	s0,sp,32
    80002ad2:	84aa                	mv	s1,a0
    80002ad4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ad6:	fffff097          	auipc	ra,0xfffff
    80002ada:	f7c080e7          	jalr	-132(ra) # 80001a52 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002ade:	653c                	ld	a5,72(a0)
    80002ae0:	02f4f863          	bgeu	s1,a5,80002b10 <fetchaddr+0x4a>
    80002ae4:	00848713          	addi	a4,s1,8
    80002ae8:	02e7e663          	bltu	a5,a4,80002b14 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aec:	46a1                	li	a3,8
    80002aee:	8626                	mv	a2,s1
    80002af0:	85ca                	mv	a1,s2
    80002af2:	6928                	ld	a0,80(a0)
    80002af4:	fffff097          	auipc	ra,0xfffff
    80002af8:	cde080e7          	jalr	-802(ra) # 800017d2 <copyin>
    80002afc:	00a03533          	snez	a0,a0
    80002b00:	40a00533          	neg	a0,a0
}
    80002b04:	60e2                	ld	ra,24(sp)
    80002b06:	6442                	ld	s0,16(sp)
    80002b08:	64a2                	ld	s1,8(sp)
    80002b0a:	6902                	ld	s2,0(sp)
    80002b0c:	6105                	addi	sp,sp,32
    80002b0e:	8082                	ret
    return -1;
    80002b10:	557d                	li	a0,-1
    80002b12:	bfcd                	j	80002b04 <fetchaddr+0x3e>
    80002b14:	557d                	li	a0,-1
    80002b16:	b7fd                	j	80002b04 <fetchaddr+0x3e>

0000000080002b18 <fetchstr>:
{
    80002b18:	7179                	addi	sp,sp,-48
    80002b1a:	f406                	sd	ra,40(sp)
    80002b1c:	f022                	sd	s0,32(sp)
    80002b1e:	ec26                	sd	s1,24(sp)
    80002b20:	e84a                	sd	s2,16(sp)
    80002b22:	e44e                	sd	s3,8(sp)
    80002b24:	1800                	addi	s0,sp,48
    80002b26:	892a                	mv	s2,a0
    80002b28:	84ae                	mv	s1,a1
    80002b2a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b2c:	fffff097          	auipc	ra,0xfffff
    80002b30:	f26080e7          	jalr	-218(ra) # 80001a52 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002b34:	86ce                	mv	a3,s3
    80002b36:	864a                	mv	a2,s2
    80002b38:	85a6                	mv	a1,s1
    80002b3a:	6928                	ld	a0,80(a0)
    80002b3c:	fffff097          	auipc	ra,0xfffff
    80002b40:	d22080e7          	jalr	-734(ra) # 8000185e <copyinstr>
  if(err < 0)
    80002b44:	00054763          	bltz	a0,80002b52 <fetchstr+0x3a>
  return strlen(buf);
    80002b48:	8526                	mv	a0,s1
    80002b4a:	ffffe097          	auipc	ra,0xffffe
    80002b4e:	3be080e7          	jalr	958(ra) # 80000f08 <strlen>
}
    80002b52:	70a2                	ld	ra,40(sp)
    80002b54:	7402                	ld	s0,32(sp)
    80002b56:	64e2                	ld	s1,24(sp)
    80002b58:	6942                	ld	s2,16(sp)
    80002b5a:	69a2                	ld	s3,8(sp)
    80002b5c:	6145                	addi	sp,sp,48
    80002b5e:	8082                	ret

0000000080002b60 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002b60:	1101                	addi	sp,sp,-32
    80002b62:	ec06                	sd	ra,24(sp)
    80002b64:	e822                	sd	s0,16(sp)
    80002b66:	e426                	sd	s1,8(sp)
    80002b68:	1000                	addi	s0,sp,32
    80002b6a:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b6c:	00000097          	auipc	ra,0x0
    80002b70:	ef2080e7          	jalr	-270(ra) # 80002a5e <argraw>
    80002b74:	c088                	sw	a0,0(s1)
  return 0;
}
    80002b76:	4501                	li	a0,0
    80002b78:	60e2                	ld	ra,24(sp)
    80002b7a:	6442                	ld	s0,16(sp)
    80002b7c:	64a2                	ld	s1,8(sp)
    80002b7e:	6105                	addi	sp,sp,32
    80002b80:	8082                	ret

0000000080002b82 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002b82:	1101                	addi	sp,sp,-32
    80002b84:	ec06                	sd	ra,24(sp)
    80002b86:	e822                	sd	s0,16(sp)
    80002b88:	e426                	sd	s1,8(sp)
    80002b8a:	1000                	addi	s0,sp,32
    80002b8c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b8e:	00000097          	auipc	ra,0x0
    80002b92:	ed0080e7          	jalr	-304(ra) # 80002a5e <argraw>
    80002b96:	e088                	sd	a0,0(s1)
  return 0;
}
    80002b98:	4501                	li	a0,0
    80002b9a:	60e2                	ld	ra,24(sp)
    80002b9c:	6442                	ld	s0,16(sp)
    80002b9e:	64a2                	ld	s1,8(sp)
    80002ba0:	6105                	addi	sp,sp,32
    80002ba2:	8082                	ret

0000000080002ba4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	e04a                	sd	s2,0(sp)
    80002bae:	1000                	addi	s0,sp,32
    80002bb0:	84ae                	mv	s1,a1
    80002bb2:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002bb4:	00000097          	auipc	ra,0x0
    80002bb8:	eaa080e7          	jalr	-342(ra) # 80002a5e <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002bbc:	864a                	mv	a2,s2
    80002bbe:	85a6                	mv	a1,s1
    80002bc0:	00000097          	auipc	ra,0x0
    80002bc4:	f58080e7          	jalr	-168(ra) # 80002b18 <fetchstr>
}
    80002bc8:	60e2                	ld	ra,24(sp)
    80002bca:	6442                	ld	s0,16(sp)
    80002bcc:	64a2                	ld	s1,8(sp)
    80002bce:	6902                	ld	s2,0(sp)
    80002bd0:	6105                	addi	sp,sp,32
    80002bd2:	8082                	ret

0000000080002bd4 <syscall>:
[SYS_sigreturn] sys_sigreturn
};

void
syscall(void)
{
    80002bd4:	1101                	addi	sp,sp,-32
    80002bd6:	ec06                	sd	ra,24(sp)
    80002bd8:	e822                	sd	s0,16(sp)
    80002bda:	e426                	sd	s1,8(sp)
    80002bdc:	e04a                	sd	s2,0(sp)
    80002bde:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002be0:	fffff097          	auipc	ra,0xfffff
    80002be4:	e72080e7          	jalr	-398(ra) # 80001a52 <myproc>
    80002be8:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bea:	05853903          	ld	s2,88(a0)
    80002bee:	0a893783          	ld	a5,168(s2)
    80002bf2:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002bf6:	37fd                	addiw	a5,a5,-1
    80002bf8:	4759                	li	a4,22
    80002bfa:	00f76f63          	bltu	a4,a5,80002c18 <syscall+0x44>
    80002bfe:	00369713          	slli	a4,a3,0x3
    80002c02:	00006797          	auipc	a5,0x6
    80002c06:	83e78793          	addi	a5,a5,-1986 # 80008440 <syscalls>
    80002c0a:	97ba                	add	a5,a5,a4
    80002c0c:	639c                	ld	a5,0(a5)
    80002c0e:	c789                	beqz	a5,80002c18 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002c10:	9782                	jalr	a5
    80002c12:	06a93823          	sd	a0,112(s2)
    80002c16:	a839                	j	80002c34 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c18:	15848613          	addi	a2,s1,344
    80002c1c:	5c8c                	lw	a1,56(s1)
    80002c1e:	00005517          	auipc	a0,0x5
    80002c22:	7ea50513          	addi	a0,a0,2026 # 80008408 <states.1712+0x148>
    80002c26:	ffffe097          	auipc	ra,0xffffe
    80002c2a:	974080e7          	jalr	-1676(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c2e:	6cbc                	ld	a5,88(s1)
    80002c30:	577d                	li	a4,-1
    80002c32:	fbb8                	sd	a4,112(a5)
  }
}
    80002c34:	60e2                	ld	ra,24(sp)
    80002c36:	6442                	ld	s0,16(sp)
    80002c38:	64a2                	ld	s1,8(sp)
    80002c3a:	6902                	ld	s2,0(sp)
    80002c3c:	6105                	addi	sp,sp,32
    80002c3e:	8082                	ret

0000000080002c40 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c40:	1101                	addi	sp,sp,-32
    80002c42:	ec06                	sd	ra,24(sp)
    80002c44:	e822                	sd	s0,16(sp)
    80002c46:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002c48:	fec40593          	addi	a1,s0,-20
    80002c4c:	4501                	li	a0,0
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	f12080e7          	jalr	-238(ra) # 80002b60 <argint>
    return -1;
    80002c56:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002c58:	00054963          	bltz	a0,80002c6a <sys_exit+0x2a>
  exit(n);
    80002c5c:	fec42503          	lw	a0,-20(s0)
    80002c60:	fffff097          	auipc	ra,0xfffff
    80002c64:	4c8080e7          	jalr	1224(ra) # 80002128 <exit>
  return 0;  // not reached
    80002c68:	4781                	li	a5,0
}
    80002c6a:	853e                	mv	a0,a5
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	6105                	addi	sp,sp,32
    80002c72:	8082                	ret

0000000080002c74 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002c74:	1141                	addi	sp,sp,-16
    80002c76:	e406                	sd	ra,8(sp)
    80002c78:	e022                	sd	s0,0(sp)
    80002c7a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	dd6080e7          	jalr	-554(ra) # 80001a52 <myproc>
}
    80002c84:	5d08                	lw	a0,56(a0)
    80002c86:	60a2                	ld	ra,8(sp)
    80002c88:	6402                	ld	s0,0(sp)
    80002c8a:	0141                	addi	sp,sp,16
    80002c8c:	8082                	ret

0000000080002c8e <sys_fork>:

uint64
sys_fork(void)
{
    80002c8e:	1141                	addi	sp,sp,-16
    80002c90:	e406                	sd	ra,8(sp)
    80002c92:	e022                	sd	s0,0(sp)
    80002c94:	0800                	addi	s0,sp,16
  return fork();
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	18c080e7          	jalr	396(ra) # 80001e22 <fork>
}
    80002c9e:	60a2                	ld	ra,8(sp)
    80002ca0:	6402                	ld	s0,0(sp)
    80002ca2:	0141                	addi	sp,sp,16
    80002ca4:	8082                	ret

0000000080002ca6 <sys_wait>:

uint64
sys_wait(void)
{
    80002ca6:	1101                	addi	sp,sp,-32
    80002ca8:	ec06                	sd	ra,24(sp)
    80002caa:	e822                	sd	s0,16(sp)
    80002cac:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002cae:	fe840593          	addi	a1,s0,-24
    80002cb2:	4501                	li	a0,0
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	ece080e7          	jalr	-306(ra) # 80002b82 <argaddr>
    80002cbc:	87aa                	mv	a5,a0
    return -1;
    80002cbe:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002cc0:	0007c863          	bltz	a5,80002cd0 <sys_wait+0x2a>
  return wait(p);
    80002cc4:	fe843503          	ld	a0,-24(s0)
    80002cc8:	fffff097          	auipc	ra,0xfffff
    80002ccc:	624080e7          	jalr	1572(ra) # 800022ec <wait>
}
    80002cd0:	60e2                	ld	ra,24(sp)
    80002cd2:	6442                	ld	s0,16(sp)
    80002cd4:	6105                	addi	sp,sp,32
    80002cd6:	8082                	ret

0000000080002cd8 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002cd8:	7179                	addi	sp,sp,-48
    80002cda:	f406                	sd	ra,40(sp)
    80002cdc:	f022                	sd	s0,32(sp)
    80002cde:	ec26                	sd	s1,24(sp)
    80002ce0:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002ce2:	fdc40593          	addi	a1,s0,-36
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	e78080e7          	jalr	-392(ra) # 80002b60 <argint>
    80002cf0:	87aa                	mv	a5,a0
    return -1;
    80002cf2:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002cf4:	0207c063          	bltz	a5,80002d14 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002cf8:	fffff097          	auipc	ra,0xfffff
    80002cfc:	d5a080e7          	jalr	-678(ra) # 80001a52 <myproc>
    80002d00:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002d02:	fdc42503          	lw	a0,-36(s0)
    80002d06:	fffff097          	auipc	ra,0xfffff
    80002d0a:	0a8080e7          	jalr	168(ra) # 80001dae <growproc>
    80002d0e:	00054863          	bltz	a0,80002d1e <sys_sbrk+0x46>
    return -1;
  return addr;
    80002d12:	8526                	mv	a0,s1
}
    80002d14:	70a2                	ld	ra,40(sp)
    80002d16:	7402                	ld	s0,32(sp)
    80002d18:	64e2                	ld	s1,24(sp)
    80002d1a:	6145                	addi	sp,sp,48
    80002d1c:	8082                	ret
    return -1;
    80002d1e:	557d                	li	a0,-1
    80002d20:	bfd5                	j	80002d14 <sys_sbrk+0x3c>

0000000080002d22 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d22:	7139                	addi	sp,sp,-64
    80002d24:	fc06                	sd	ra,56(sp)
    80002d26:	f822                	sd	s0,48(sp)
    80002d28:	f426                	sd	s1,40(sp)
    80002d2a:	f04a                	sd	s2,32(sp)
    80002d2c:	ec4e                	sd	s3,24(sp)
    80002d2e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80002d30:	fcc40593          	addi	a1,s0,-52
    80002d34:	4501                	li	a0,0
    80002d36:	00000097          	auipc	ra,0x0
    80002d3a:	e2a080e7          	jalr	-470(ra) # 80002b60 <argint>
    return -1;
    80002d3e:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002d40:	06054963          	bltz	a0,80002db2 <sys_sleep+0x90>
  acquire(&tickslock);
    80002d44:	0001a517          	auipc	a0,0x1a
    80002d48:	82450513          	addi	a0,a0,-2012 # 8001c568 <tickslock>
    80002d4c:	ffffe097          	auipc	ra,0xffffe
    80002d50:	f38080e7          	jalr	-200(ra) # 80000c84 <acquire>
  ticks0 = ticks;
    80002d54:	00006917          	auipc	s2,0x6
    80002d58:	2cc92903          	lw	s2,716(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80002d5c:	fcc42783          	lw	a5,-52(s0)
    80002d60:	cf85                	beqz	a5,80002d98 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d62:	0001a997          	auipc	s3,0x1a
    80002d66:	80698993          	addi	s3,s3,-2042 # 8001c568 <tickslock>
    80002d6a:	00006497          	auipc	s1,0x6
    80002d6e:	2b648493          	addi	s1,s1,694 # 80009020 <ticks>
    if(myproc()->killed){
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	ce0080e7          	jalr	-800(ra) # 80001a52 <myproc>
    80002d7a:	591c                	lw	a5,48(a0)
    80002d7c:	e3b9                	bnez	a5,80002dc2 <sys_sleep+0xa0>
    sleep(&ticks, &tickslock);
    80002d7e:	85ce                	mv	a1,s3
    80002d80:	8526                	mv	a0,s1
    80002d82:	fffff097          	auipc	ra,0xfffff
    80002d86:	4ec080e7          	jalr	1260(ra) # 8000226e <sleep>
  while(ticks - ticks0 < n){
    80002d8a:	409c                	lw	a5,0(s1)
    80002d8c:	412787bb          	subw	a5,a5,s2
    80002d90:	fcc42703          	lw	a4,-52(s0)
    80002d94:	fce7efe3          	bltu	a5,a4,80002d72 <sys_sleep+0x50>
  }
  release(&tickslock);
    80002d98:	00019517          	auipc	a0,0x19
    80002d9c:	7d050513          	addi	a0,a0,2000 # 8001c568 <tickslock>
    80002da0:	ffffe097          	auipc	ra,0xffffe
    80002da4:	f98080e7          	jalr	-104(ra) # 80000d38 <release>
  backtrace();
    80002da8:	ffffe097          	auipc	ra,0xffffe
    80002dac:	9d8080e7          	jalr	-1576(ra) # 80000780 <backtrace>
  return 0;
    80002db0:	4781                	li	a5,0
}
    80002db2:	853e                	mv	a0,a5
    80002db4:	70e2                	ld	ra,56(sp)
    80002db6:	7442                	ld	s0,48(sp)
    80002db8:	74a2                	ld	s1,40(sp)
    80002dba:	7902                	ld	s2,32(sp)
    80002dbc:	69e2                	ld	s3,24(sp)
    80002dbe:	6121                	addi	sp,sp,64
    80002dc0:	8082                	ret
      release(&tickslock);
    80002dc2:	00019517          	auipc	a0,0x19
    80002dc6:	7a650513          	addi	a0,a0,1958 # 8001c568 <tickslock>
    80002dca:	ffffe097          	auipc	ra,0xffffe
    80002dce:	f6e080e7          	jalr	-146(ra) # 80000d38 <release>
      return -1;
    80002dd2:	57fd                	li	a5,-1
    80002dd4:	bff9                	j	80002db2 <sys_sleep+0x90>

0000000080002dd6 <sys_kill>:

uint64
sys_kill(void)
{
    80002dd6:	1101                	addi	sp,sp,-32
    80002dd8:	ec06                	sd	ra,24(sp)
    80002dda:	e822                	sd	s0,16(sp)
    80002ddc:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    80002dde:	fec40593          	addi	a1,s0,-20
    80002de2:	4501                	li	a0,0
    80002de4:	00000097          	auipc	ra,0x0
    80002de8:	d7c080e7          	jalr	-644(ra) # 80002b60 <argint>
    80002dec:	87aa                	mv	a5,a0
    return -1;
    80002dee:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    80002df0:	0007c863          	bltz	a5,80002e00 <sys_kill+0x2a>
  return kill(pid);
    80002df4:	fec42503          	lw	a0,-20(s0)
    80002df8:	fffff097          	auipc	ra,0xfffff
    80002dfc:	666080e7          	jalr	1638(ra) # 8000245e <kill>
}
    80002e00:	60e2                	ld	ra,24(sp)
    80002e02:	6442                	ld	s0,16(sp)
    80002e04:	6105                	addi	sp,sp,32
    80002e06:	8082                	ret

0000000080002e08 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e08:	1101                	addi	sp,sp,-32
    80002e0a:	ec06                	sd	ra,24(sp)
    80002e0c:	e822                	sd	s0,16(sp)
    80002e0e:	e426                	sd	s1,8(sp)
    80002e10:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e12:	00019517          	auipc	a0,0x19
    80002e16:	75650513          	addi	a0,a0,1878 # 8001c568 <tickslock>
    80002e1a:	ffffe097          	auipc	ra,0xffffe
    80002e1e:	e6a080e7          	jalr	-406(ra) # 80000c84 <acquire>
  xticks = ticks;
    80002e22:	00006497          	auipc	s1,0x6
    80002e26:	1fe4a483          	lw	s1,510(s1) # 80009020 <ticks>
  release(&tickslock);
    80002e2a:	00019517          	auipc	a0,0x19
    80002e2e:	73e50513          	addi	a0,a0,1854 # 8001c568 <tickslock>
    80002e32:	ffffe097          	auipc	ra,0xffffe
    80002e36:	f06080e7          	jalr	-250(ra) # 80000d38 <release>
  return xticks;
}
    80002e3a:	02049513          	slli	a0,s1,0x20
    80002e3e:	9101                	srli	a0,a0,0x20
    80002e40:	60e2                	ld	ra,24(sp)
    80002e42:	6442                	ld	s0,16(sp)
    80002e44:	64a2                	ld	s1,8(sp)
    80002e46:	6105                	addi	sp,sp,32
    80002e48:	8082                	ret

0000000080002e4a <sys_sigalarm>:

uint64
sys_sigalarm(void)
{
    80002e4a:	1101                	addi	sp,sp,-32
    80002e4c:	ec06                	sd	ra,24(sp)
    80002e4e:	e822                	sd	s0,16(sp)
    80002e50:	1000                	addi	s0,sp,32
  int alarm_interval;
  uint64 alarm_handler;

  if (argint(0, &alarm_interval) < 0)
    80002e52:	fec40593          	addi	a1,s0,-20
    80002e56:	4501                	li	a0,0
    80002e58:	00000097          	auipc	ra,0x0
    80002e5c:	d08080e7          	jalr	-760(ra) # 80002b60 <argint>
    return -1;
    80002e60:	57fd                	li	a5,-1
  if (argint(0, &alarm_interval) < 0)
    80002e62:	02054d63          	bltz	a0,80002e9c <sys_sigalarm+0x52>
  if (argaddr(1, &alarm_handler) < 0)
    80002e66:	fe040593          	addi	a1,s0,-32
    80002e6a:	4505                	li	a0,1
    80002e6c:	00000097          	auipc	ra,0x0
    80002e70:	d16080e7          	jalr	-746(ra) # 80002b82 <argaddr>
    return -1;
    80002e74:	57fd                	li	a5,-1
  if (argaddr(1, &alarm_handler) < 0)
    80002e76:	02054363          	bltz	a0,80002e9c <sys_sigalarm+0x52>
  myproc()->alarm_interval = alarm_interval;
    80002e7a:	fffff097          	auipc	ra,0xfffff
    80002e7e:	bd8080e7          	jalr	-1064(ra) # 80001a52 <myproc>
    80002e82:	fec42783          	lw	a5,-20(s0)
    80002e86:	16f52423          	sw	a5,360(a0)
  myproc()->alarm_handler = alarm_handler;
    80002e8a:	fffff097          	auipc	ra,0xfffff
    80002e8e:	bc8080e7          	jalr	-1080(ra) # 80001a52 <myproc>
    80002e92:	fe043783          	ld	a5,-32(s0)
    80002e96:	16f53823          	sd	a5,368(a0)

  return 0;
    80002e9a:	4781                	li	a5,0
}
    80002e9c:	853e                	mv	a0,a5
    80002e9e:	60e2                	ld	ra,24(sp)
    80002ea0:	6442                	ld	s0,16(sp)
    80002ea2:	6105                	addi	sp,sp,32
    80002ea4:	8082                	ret

0000000080002ea6 <sys_sigreturn>:

uint64
sys_sigreturn(void)
{
    80002ea6:	1101                	addi	sp,sp,-32
    80002ea8:	ec06                	sd	ra,24(sp)
    80002eaa:	e822                	sd	s0,16(sp)
    80002eac:	e426                	sd	s1,8(sp)
    80002eae:	1000                	addi	s0,sp,32
  myproc()->block = 0;
    80002eb0:	fffff097          	auipc	ra,0xfffff
    80002eb4:	ba2080e7          	jalr	-1118(ra) # 80001a52 <myproc>
    80002eb8:	16052c23          	sw	zero,376(a0)
  // restore registers
  memmove((void *)myproc()->trapframe, (void *)myproc()->reg_buf, sizeof(struct trapframe));
    80002ebc:	fffff097          	auipc	ra,0xfffff
    80002ec0:	b96080e7          	jalr	-1130(ra) # 80001a52 <myproc>
    80002ec4:	6d24                	ld	s1,88(a0)
    80002ec6:	fffff097          	auipc	ra,0xfffff
    80002eca:	b8c080e7          	jalr	-1140(ra) # 80001a52 <myproc>
    80002ece:	12000613          	li	a2,288
    80002ed2:	17c50593          	addi	a1,a0,380
    80002ed6:	8526                	mv	a0,s1
    80002ed8:	ffffe097          	auipc	ra,0xffffe
    80002edc:	f08080e7          	jalr	-248(ra) # 80000de0 <memmove>

  return 0;
    80002ee0:	4501                	li	a0,0
    80002ee2:	60e2                	ld	ra,24(sp)
    80002ee4:	6442                	ld	s0,16(sp)
    80002ee6:	64a2                	ld	s1,8(sp)
    80002ee8:	6105                	addi	sp,sp,32
    80002eea:	8082                	ret

0000000080002eec <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eec:	7179                	addi	sp,sp,-48
    80002eee:	f406                	sd	ra,40(sp)
    80002ef0:	f022                	sd	s0,32(sp)
    80002ef2:	ec26                	sd	s1,24(sp)
    80002ef4:	e84a                	sd	s2,16(sp)
    80002ef6:	e44e                	sd	s3,8(sp)
    80002ef8:	e052                	sd	s4,0(sp)
    80002efa:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002efc:	00005597          	auipc	a1,0x5
    80002f00:	60458593          	addi	a1,a1,1540 # 80008500 <syscalls+0xc0>
    80002f04:	00019517          	auipc	a0,0x19
    80002f08:	67c50513          	addi	a0,a0,1660 # 8001c580 <bcache>
    80002f0c:	ffffe097          	auipc	ra,0xffffe
    80002f10:	ce8080e7          	jalr	-792(ra) # 80000bf4 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f14:	00021797          	auipc	a5,0x21
    80002f18:	66c78793          	addi	a5,a5,1644 # 80024580 <bcache+0x8000>
    80002f1c:	00022717          	auipc	a4,0x22
    80002f20:	8cc70713          	addi	a4,a4,-1844 # 800247e8 <bcache+0x8268>
    80002f24:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f28:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f2c:	00019497          	auipc	s1,0x19
    80002f30:	66c48493          	addi	s1,s1,1644 # 8001c598 <bcache+0x18>
    b->next = bcache.head.next;
    80002f34:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f36:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f38:	00005a17          	auipc	s4,0x5
    80002f3c:	5d0a0a13          	addi	s4,s4,1488 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80002f40:	2b893783          	ld	a5,696(s2)
    80002f44:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f46:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f4a:	85d2                	mv	a1,s4
    80002f4c:	01048513          	addi	a0,s1,16
    80002f50:	00001097          	auipc	ra,0x1
    80002f54:	4ac080e7          	jalr	1196(ra) # 800043fc <initsleeplock>
    bcache.head.next->prev = b;
    80002f58:	2b893783          	ld	a5,696(s2)
    80002f5c:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f5e:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f62:	45848493          	addi	s1,s1,1112
    80002f66:	fd349de3          	bne	s1,s3,80002f40 <binit+0x54>
  }
}
    80002f6a:	70a2                	ld	ra,40(sp)
    80002f6c:	7402                	ld	s0,32(sp)
    80002f6e:	64e2                	ld	s1,24(sp)
    80002f70:	6942                	ld	s2,16(sp)
    80002f72:	69a2                	ld	s3,8(sp)
    80002f74:	6a02                	ld	s4,0(sp)
    80002f76:	6145                	addi	sp,sp,48
    80002f78:	8082                	ret

0000000080002f7a <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f7a:	7179                	addi	sp,sp,-48
    80002f7c:	f406                	sd	ra,40(sp)
    80002f7e:	f022                	sd	s0,32(sp)
    80002f80:	ec26                	sd	s1,24(sp)
    80002f82:	e84a                	sd	s2,16(sp)
    80002f84:	e44e                	sd	s3,8(sp)
    80002f86:	1800                	addi	s0,sp,48
    80002f88:	89aa                	mv	s3,a0
    80002f8a:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80002f8c:	00019517          	auipc	a0,0x19
    80002f90:	5f450513          	addi	a0,a0,1524 # 8001c580 <bcache>
    80002f94:	ffffe097          	auipc	ra,0xffffe
    80002f98:	cf0080e7          	jalr	-784(ra) # 80000c84 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f9c:	00022497          	auipc	s1,0x22
    80002fa0:	89c4b483          	ld	s1,-1892(s1) # 80024838 <bcache+0x82b8>
    80002fa4:	00022797          	auipc	a5,0x22
    80002fa8:	84478793          	addi	a5,a5,-1980 # 800247e8 <bcache+0x8268>
    80002fac:	02f48f63          	beq	s1,a5,80002fea <bread+0x70>
    80002fb0:	873e                	mv	a4,a5
    80002fb2:	a021                	j	80002fba <bread+0x40>
    80002fb4:	68a4                	ld	s1,80(s1)
    80002fb6:	02e48a63          	beq	s1,a4,80002fea <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fba:	449c                	lw	a5,8(s1)
    80002fbc:	ff379ce3          	bne	a5,s3,80002fb4 <bread+0x3a>
    80002fc0:	44dc                	lw	a5,12(s1)
    80002fc2:	ff2799e3          	bne	a5,s2,80002fb4 <bread+0x3a>
      b->refcnt++;
    80002fc6:	40bc                	lw	a5,64(s1)
    80002fc8:	2785                	addiw	a5,a5,1
    80002fca:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fcc:	00019517          	auipc	a0,0x19
    80002fd0:	5b450513          	addi	a0,a0,1460 # 8001c580 <bcache>
    80002fd4:	ffffe097          	auipc	ra,0xffffe
    80002fd8:	d64080e7          	jalr	-668(ra) # 80000d38 <release>
      acquiresleep(&b->lock);
    80002fdc:	01048513          	addi	a0,s1,16
    80002fe0:	00001097          	auipc	ra,0x1
    80002fe4:	456080e7          	jalr	1110(ra) # 80004436 <acquiresleep>
      return b;
    80002fe8:	a8b9                	j	80003046 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fea:	00022497          	auipc	s1,0x22
    80002fee:	8464b483          	ld	s1,-1978(s1) # 80024830 <bcache+0x82b0>
    80002ff2:	00021797          	auipc	a5,0x21
    80002ff6:	7f678793          	addi	a5,a5,2038 # 800247e8 <bcache+0x8268>
    80002ffa:	00f48863          	beq	s1,a5,8000300a <bread+0x90>
    80002ffe:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003000:	40bc                	lw	a5,64(s1)
    80003002:	cf81                	beqz	a5,8000301a <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003004:	64a4                	ld	s1,72(s1)
    80003006:	fee49de3          	bne	s1,a4,80003000 <bread+0x86>
  panic("bget: no buffers");
    8000300a:	00005517          	auipc	a0,0x5
    8000300e:	50650513          	addi	a0,a0,1286 # 80008510 <syscalls+0xd0>
    80003012:	ffffd097          	auipc	ra,0xffffd
    80003016:	536080e7          	jalr	1334(ra) # 80000548 <panic>
      b->dev = dev;
    8000301a:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    8000301e:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003022:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003026:	4785                	li	a5,1
    80003028:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000302a:	00019517          	auipc	a0,0x19
    8000302e:	55650513          	addi	a0,a0,1366 # 8001c580 <bcache>
    80003032:	ffffe097          	auipc	ra,0xffffe
    80003036:	d06080e7          	jalr	-762(ra) # 80000d38 <release>
      acquiresleep(&b->lock);
    8000303a:	01048513          	addi	a0,s1,16
    8000303e:	00001097          	auipc	ra,0x1
    80003042:	3f8080e7          	jalr	1016(ra) # 80004436 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003046:	409c                	lw	a5,0(s1)
    80003048:	cb89                	beqz	a5,8000305a <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000304a:	8526                	mv	a0,s1
    8000304c:	70a2                	ld	ra,40(sp)
    8000304e:	7402                	ld	s0,32(sp)
    80003050:	64e2                	ld	s1,24(sp)
    80003052:	6942                	ld	s2,16(sp)
    80003054:	69a2                	ld	s3,8(sp)
    80003056:	6145                	addi	sp,sp,48
    80003058:	8082                	ret
    virtio_disk_rw(b, 0);
    8000305a:	4581                	li	a1,0
    8000305c:	8526                	mv	a0,s1
    8000305e:	00003097          	auipc	ra,0x3
    80003062:	f2e080e7          	jalr	-210(ra) # 80005f8c <virtio_disk_rw>
    b->valid = 1;
    80003066:	4785                	li	a5,1
    80003068:	c09c                	sw	a5,0(s1)
  return b;
    8000306a:	b7c5                	j	8000304a <bread+0xd0>

000000008000306c <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000306c:	1101                	addi	sp,sp,-32
    8000306e:	ec06                	sd	ra,24(sp)
    80003070:	e822                	sd	s0,16(sp)
    80003072:	e426                	sd	s1,8(sp)
    80003074:	1000                	addi	s0,sp,32
    80003076:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003078:	0541                	addi	a0,a0,16
    8000307a:	00001097          	auipc	ra,0x1
    8000307e:	456080e7          	jalr	1110(ra) # 800044d0 <holdingsleep>
    80003082:	cd01                	beqz	a0,8000309a <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003084:	4585                	li	a1,1
    80003086:	8526                	mv	a0,s1
    80003088:	00003097          	auipc	ra,0x3
    8000308c:	f04080e7          	jalr	-252(ra) # 80005f8c <virtio_disk_rw>
}
    80003090:	60e2                	ld	ra,24(sp)
    80003092:	6442                	ld	s0,16(sp)
    80003094:	64a2                	ld	s1,8(sp)
    80003096:	6105                	addi	sp,sp,32
    80003098:	8082                	ret
    panic("bwrite");
    8000309a:	00005517          	auipc	a0,0x5
    8000309e:	48e50513          	addi	a0,a0,1166 # 80008528 <syscalls+0xe8>
    800030a2:	ffffd097          	auipc	ra,0xffffd
    800030a6:	4a6080e7          	jalr	1190(ra) # 80000548 <panic>

00000000800030aa <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	e04a                	sd	s2,0(sp)
    800030b4:	1000                	addi	s0,sp,32
    800030b6:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030b8:	01050913          	addi	s2,a0,16
    800030bc:	854a                	mv	a0,s2
    800030be:	00001097          	auipc	ra,0x1
    800030c2:	412080e7          	jalr	1042(ra) # 800044d0 <holdingsleep>
    800030c6:	c92d                	beqz	a0,80003138 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030c8:	854a                	mv	a0,s2
    800030ca:	00001097          	auipc	ra,0x1
    800030ce:	3c2080e7          	jalr	962(ra) # 8000448c <releasesleep>

  acquire(&bcache.lock);
    800030d2:	00019517          	auipc	a0,0x19
    800030d6:	4ae50513          	addi	a0,a0,1198 # 8001c580 <bcache>
    800030da:	ffffe097          	auipc	ra,0xffffe
    800030de:	baa080e7          	jalr	-1110(ra) # 80000c84 <acquire>
  b->refcnt--;
    800030e2:	40bc                	lw	a5,64(s1)
    800030e4:	37fd                	addiw	a5,a5,-1
    800030e6:	0007871b          	sext.w	a4,a5
    800030ea:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030ec:	eb05                	bnez	a4,8000311c <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030ee:	68bc                	ld	a5,80(s1)
    800030f0:	64b8                	ld	a4,72(s1)
    800030f2:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030f4:	64bc                	ld	a5,72(s1)
    800030f6:	68b8                	ld	a4,80(s1)
    800030f8:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030fa:	00021797          	auipc	a5,0x21
    800030fe:	48678793          	addi	a5,a5,1158 # 80024580 <bcache+0x8000>
    80003102:	2b87b703          	ld	a4,696(a5)
    80003106:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003108:	00021717          	auipc	a4,0x21
    8000310c:	6e070713          	addi	a4,a4,1760 # 800247e8 <bcache+0x8268>
    80003110:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003112:	2b87b703          	ld	a4,696(a5)
    80003116:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003118:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000311c:	00019517          	auipc	a0,0x19
    80003120:	46450513          	addi	a0,a0,1124 # 8001c580 <bcache>
    80003124:	ffffe097          	auipc	ra,0xffffe
    80003128:	c14080e7          	jalr	-1004(ra) # 80000d38 <release>
}
    8000312c:	60e2                	ld	ra,24(sp)
    8000312e:	6442                	ld	s0,16(sp)
    80003130:	64a2                	ld	s1,8(sp)
    80003132:	6902                	ld	s2,0(sp)
    80003134:	6105                	addi	sp,sp,32
    80003136:	8082                	ret
    panic("brelse");
    80003138:	00005517          	auipc	a0,0x5
    8000313c:	3f850513          	addi	a0,a0,1016 # 80008530 <syscalls+0xf0>
    80003140:	ffffd097          	auipc	ra,0xffffd
    80003144:	408080e7          	jalr	1032(ra) # 80000548 <panic>

0000000080003148 <bpin>:

void
bpin(struct buf *b) {
    80003148:	1101                	addi	sp,sp,-32
    8000314a:	ec06                	sd	ra,24(sp)
    8000314c:	e822                	sd	s0,16(sp)
    8000314e:	e426                	sd	s1,8(sp)
    80003150:	1000                	addi	s0,sp,32
    80003152:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003154:	00019517          	auipc	a0,0x19
    80003158:	42c50513          	addi	a0,a0,1068 # 8001c580 <bcache>
    8000315c:	ffffe097          	auipc	ra,0xffffe
    80003160:	b28080e7          	jalr	-1240(ra) # 80000c84 <acquire>
  b->refcnt++;
    80003164:	40bc                	lw	a5,64(s1)
    80003166:	2785                	addiw	a5,a5,1
    80003168:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000316a:	00019517          	auipc	a0,0x19
    8000316e:	41650513          	addi	a0,a0,1046 # 8001c580 <bcache>
    80003172:	ffffe097          	auipc	ra,0xffffe
    80003176:	bc6080e7          	jalr	-1082(ra) # 80000d38 <release>
}
    8000317a:	60e2                	ld	ra,24(sp)
    8000317c:	6442                	ld	s0,16(sp)
    8000317e:	64a2                	ld	s1,8(sp)
    80003180:	6105                	addi	sp,sp,32
    80003182:	8082                	ret

0000000080003184 <bunpin>:

void
bunpin(struct buf *b) {
    80003184:	1101                	addi	sp,sp,-32
    80003186:	ec06                	sd	ra,24(sp)
    80003188:	e822                	sd	s0,16(sp)
    8000318a:	e426                	sd	s1,8(sp)
    8000318c:	1000                	addi	s0,sp,32
    8000318e:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003190:	00019517          	auipc	a0,0x19
    80003194:	3f050513          	addi	a0,a0,1008 # 8001c580 <bcache>
    80003198:	ffffe097          	auipc	ra,0xffffe
    8000319c:	aec080e7          	jalr	-1300(ra) # 80000c84 <acquire>
  b->refcnt--;
    800031a0:	40bc                	lw	a5,64(s1)
    800031a2:	37fd                	addiw	a5,a5,-1
    800031a4:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800031a6:	00019517          	auipc	a0,0x19
    800031aa:	3da50513          	addi	a0,a0,986 # 8001c580 <bcache>
    800031ae:	ffffe097          	auipc	ra,0xffffe
    800031b2:	b8a080e7          	jalr	-1142(ra) # 80000d38 <release>
}
    800031b6:	60e2                	ld	ra,24(sp)
    800031b8:	6442                	ld	s0,16(sp)
    800031ba:	64a2                	ld	s1,8(sp)
    800031bc:	6105                	addi	sp,sp,32
    800031be:	8082                	ret

00000000800031c0 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031c0:	1101                	addi	sp,sp,-32
    800031c2:	ec06                	sd	ra,24(sp)
    800031c4:	e822                	sd	s0,16(sp)
    800031c6:	e426                	sd	s1,8(sp)
    800031c8:	e04a                	sd	s2,0(sp)
    800031ca:	1000                	addi	s0,sp,32
    800031cc:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031ce:	00d5d59b          	srliw	a1,a1,0xd
    800031d2:	00022797          	auipc	a5,0x22
    800031d6:	a8a7a783          	lw	a5,-1398(a5) # 80024c5c <sb+0x1c>
    800031da:	9dbd                	addw	a1,a1,a5
    800031dc:	00000097          	auipc	ra,0x0
    800031e0:	d9e080e7          	jalr	-610(ra) # 80002f7a <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031e4:	0074f713          	andi	a4,s1,7
    800031e8:	4785                	li	a5,1
    800031ea:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031ee:	14ce                	slli	s1,s1,0x33
    800031f0:	90d9                	srli	s1,s1,0x36
    800031f2:	00950733          	add	a4,a0,s1
    800031f6:	05874703          	lbu	a4,88(a4)
    800031fa:	00e7f6b3          	and	a3,a5,a4
    800031fe:	c69d                	beqz	a3,8000322c <bfree+0x6c>
    80003200:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003202:	94aa                	add	s1,s1,a0
    80003204:	fff7c793          	not	a5,a5
    80003208:	8ff9                	and	a5,a5,a4
    8000320a:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    8000320e:	00001097          	auipc	ra,0x1
    80003212:	100080e7          	jalr	256(ra) # 8000430e <log_write>
  brelse(bp);
    80003216:	854a                	mv	a0,s2
    80003218:	00000097          	auipc	ra,0x0
    8000321c:	e92080e7          	jalr	-366(ra) # 800030aa <brelse>
}
    80003220:	60e2                	ld	ra,24(sp)
    80003222:	6442                	ld	s0,16(sp)
    80003224:	64a2                	ld	s1,8(sp)
    80003226:	6902                	ld	s2,0(sp)
    80003228:	6105                	addi	sp,sp,32
    8000322a:	8082                	ret
    panic("freeing free block");
    8000322c:	00005517          	auipc	a0,0x5
    80003230:	30c50513          	addi	a0,a0,780 # 80008538 <syscalls+0xf8>
    80003234:	ffffd097          	auipc	ra,0xffffd
    80003238:	314080e7          	jalr	788(ra) # 80000548 <panic>

000000008000323c <balloc>:
{
    8000323c:	711d                	addi	sp,sp,-96
    8000323e:	ec86                	sd	ra,88(sp)
    80003240:	e8a2                	sd	s0,80(sp)
    80003242:	e4a6                	sd	s1,72(sp)
    80003244:	e0ca                	sd	s2,64(sp)
    80003246:	fc4e                	sd	s3,56(sp)
    80003248:	f852                	sd	s4,48(sp)
    8000324a:	f456                	sd	s5,40(sp)
    8000324c:	f05a                	sd	s6,32(sp)
    8000324e:	ec5e                	sd	s7,24(sp)
    80003250:	e862                	sd	s8,16(sp)
    80003252:	e466                	sd	s9,8(sp)
    80003254:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003256:	00022797          	auipc	a5,0x22
    8000325a:	9ee7a783          	lw	a5,-1554(a5) # 80024c44 <sb+0x4>
    8000325e:	cbd1                	beqz	a5,800032f2 <balloc+0xb6>
    80003260:	8baa                	mv	s7,a0
    80003262:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003264:	00022b17          	auipc	s6,0x22
    80003268:	9dcb0b13          	addi	s6,s6,-1572 # 80024c40 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000326c:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000326e:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003270:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003272:	6c89                	lui	s9,0x2
    80003274:	a831                	j	80003290 <balloc+0x54>
    brelse(bp);
    80003276:	854a                	mv	a0,s2
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e32080e7          	jalr	-462(ra) # 800030aa <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003280:	015c87bb          	addw	a5,s9,s5
    80003284:	00078a9b          	sext.w	s5,a5
    80003288:	004b2703          	lw	a4,4(s6)
    8000328c:	06eaf363          	bgeu	s5,a4,800032f2 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003290:	41fad79b          	sraiw	a5,s5,0x1f
    80003294:	0137d79b          	srliw	a5,a5,0x13
    80003298:	015787bb          	addw	a5,a5,s5
    8000329c:	40d7d79b          	sraiw	a5,a5,0xd
    800032a0:	01cb2583          	lw	a1,28(s6)
    800032a4:	9dbd                	addw	a1,a1,a5
    800032a6:	855e                	mv	a0,s7
    800032a8:	00000097          	auipc	ra,0x0
    800032ac:	cd2080e7          	jalr	-814(ra) # 80002f7a <bread>
    800032b0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032b2:	004b2503          	lw	a0,4(s6)
    800032b6:	000a849b          	sext.w	s1,s5
    800032ba:	8662                	mv	a2,s8
    800032bc:	faa4fde3          	bgeu	s1,a0,80003276 <balloc+0x3a>
      m = 1 << (bi % 8);
    800032c0:	41f6579b          	sraiw	a5,a2,0x1f
    800032c4:	01d7d69b          	srliw	a3,a5,0x1d
    800032c8:	00c6873b          	addw	a4,a3,a2
    800032cc:	00777793          	andi	a5,a4,7
    800032d0:	9f95                	subw	a5,a5,a3
    800032d2:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800032d6:	4037571b          	sraiw	a4,a4,0x3
    800032da:	00e906b3          	add	a3,s2,a4
    800032de:	0586c683          	lbu	a3,88(a3)
    800032e2:	00d7f5b3          	and	a1,a5,a3
    800032e6:	cd91                	beqz	a1,80003302 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800032e8:	2605                	addiw	a2,a2,1
    800032ea:	2485                	addiw	s1,s1,1
    800032ec:	fd4618e3          	bne	a2,s4,800032bc <balloc+0x80>
    800032f0:	b759                	j	80003276 <balloc+0x3a>
  panic("balloc: out of blocks");
    800032f2:	00005517          	auipc	a0,0x5
    800032f6:	25e50513          	addi	a0,a0,606 # 80008550 <syscalls+0x110>
    800032fa:	ffffd097          	auipc	ra,0xffffd
    800032fe:	24e080e7          	jalr	590(ra) # 80000548 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003302:	974a                	add	a4,a4,s2
    80003304:	8fd5                	or	a5,a5,a3
    80003306:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    8000330a:	854a                	mv	a0,s2
    8000330c:	00001097          	auipc	ra,0x1
    80003310:	002080e7          	jalr	2(ra) # 8000430e <log_write>
        brelse(bp);
    80003314:	854a                	mv	a0,s2
    80003316:	00000097          	auipc	ra,0x0
    8000331a:	d94080e7          	jalr	-620(ra) # 800030aa <brelse>
  bp = bread(dev, bno);
    8000331e:	85a6                	mv	a1,s1
    80003320:	855e                	mv	a0,s7
    80003322:	00000097          	auipc	ra,0x0
    80003326:	c58080e7          	jalr	-936(ra) # 80002f7a <bread>
    8000332a:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000332c:	40000613          	li	a2,1024
    80003330:	4581                	li	a1,0
    80003332:	05850513          	addi	a0,a0,88
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	a4a080e7          	jalr	-1462(ra) # 80000d80 <memset>
  log_write(bp);
    8000333e:	854a                	mv	a0,s2
    80003340:	00001097          	auipc	ra,0x1
    80003344:	fce080e7          	jalr	-50(ra) # 8000430e <log_write>
  brelse(bp);
    80003348:	854a                	mv	a0,s2
    8000334a:	00000097          	auipc	ra,0x0
    8000334e:	d60080e7          	jalr	-672(ra) # 800030aa <brelse>
}
    80003352:	8526                	mv	a0,s1
    80003354:	60e6                	ld	ra,88(sp)
    80003356:	6446                	ld	s0,80(sp)
    80003358:	64a6                	ld	s1,72(sp)
    8000335a:	6906                	ld	s2,64(sp)
    8000335c:	79e2                	ld	s3,56(sp)
    8000335e:	7a42                	ld	s4,48(sp)
    80003360:	7aa2                	ld	s5,40(sp)
    80003362:	7b02                	ld	s6,32(sp)
    80003364:	6be2                	ld	s7,24(sp)
    80003366:	6c42                	ld	s8,16(sp)
    80003368:	6ca2                	ld	s9,8(sp)
    8000336a:	6125                	addi	sp,sp,96
    8000336c:	8082                	ret

000000008000336e <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    8000336e:	7179                	addi	sp,sp,-48
    80003370:	f406                	sd	ra,40(sp)
    80003372:	f022                	sd	s0,32(sp)
    80003374:	ec26                	sd	s1,24(sp)
    80003376:	e84a                	sd	s2,16(sp)
    80003378:	e44e                	sd	s3,8(sp)
    8000337a:	e052                	sd	s4,0(sp)
    8000337c:	1800                	addi	s0,sp,48
    8000337e:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003380:	47ad                	li	a5,11
    80003382:	04b7fe63          	bgeu	a5,a1,800033de <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003386:	ff45849b          	addiw	s1,a1,-12
    8000338a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000338e:	0ff00793          	li	a5,255
    80003392:	0ae7e363          	bltu	a5,a4,80003438 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003396:	08052583          	lw	a1,128(a0)
    8000339a:	c5ad                	beqz	a1,80003404 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    8000339c:	00092503          	lw	a0,0(s2)
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	bda080e7          	jalr	-1062(ra) # 80002f7a <bread>
    800033a8:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033aa:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033ae:	02049593          	slli	a1,s1,0x20
    800033b2:	9181                	srli	a1,a1,0x20
    800033b4:	058a                	slli	a1,a1,0x2
    800033b6:	00b784b3          	add	s1,a5,a1
    800033ba:	0004a983          	lw	s3,0(s1)
    800033be:	04098d63          	beqz	s3,80003418 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800033c2:	8552                	mv	a0,s4
    800033c4:	00000097          	auipc	ra,0x0
    800033c8:	ce6080e7          	jalr	-794(ra) # 800030aa <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800033cc:	854e                	mv	a0,s3
    800033ce:	70a2                	ld	ra,40(sp)
    800033d0:	7402                	ld	s0,32(sp)
    800033d2:	64e2                	ld	s1,24(sp)
    800033d4:	6942                	ld	s2,16(sp)
    800033d6:	69a2                	ld	s3,8(sp)
    800033d8:	6a02                	ld	s4,0(sp)
    800033da:	6145                	addi	sp,sp,48
    800033dc:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800033de:	02059493          	slli	s1,a1,0x20
    800033e2:	9081                	srli	s1,s1,0x20
    800033e4:	048a                	slli	s1,s1,0x2
    800033e6:	94aa                	add	s1,s1,a0
    800033e8:	0504a983          	lw	s3,80(s1)
    800033ec:	fe0990e3          	bnez	s3,800033cc <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    800033f0:	4108                	lw	a0,0(a0)
    800033f2:	00000097          	auipc	ra,0x0
    800033f6:	e4a080e7          	jalr	-438(ra) # 8000323c <balloc>
    800033fa:	0005099b          	sext.w	s3,a0
    800033fe:	0534a823          	sw	s3,80(s1)
    80003402:	b7e9                	j	800033cc <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003404:	4108                	lw	a0,0(a0)
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	e36080e7          	jalr	-458(ra) # 8000323c <balloc>
    8000340e:	0005059b          	sext.w	a1,a0
    80003412:	08b92023          	sw	a1,128(s2)
    80003416:	b759                	j	8000339c <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003418:	00092503          	lw	a0,0(s2)
    8000341c:	00000097          	auipc	ra,0x0
    80003420:	e20080e7          	jalr	-480(ra) # 8000323c <balloc>
    80003424:	0005099b          	sext.w	s3,a0
    80003428:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    8000342c:	8552                	mv	a0,s4
    8000342e:	00001097          	auipc	ra,0x1
    80003432:	ee0080e7          	jalr	-288(ra) # 8000430e <log_write>
    80003436:	b771                	j	800033c2 <bmap+0x54>
  panic("bmap: out of range");
    80003438:	00005517          	auipc	a0,0x5
    8000343c:	13050513          	addi	a0,a0,304 # 80008568 <syscalls+0x128>
    80003440:	ffffd097          	auipc	ra,0xffffd
    80003444:	108080e7          	jalr	264(ra) # 80000548 <panic>

0000000080003448 <iget>:
{
    80003448:	7179                	addi	sp,sp,-48
    8000344a:	f406                	sd	ra,40(sp)
    8000344c:	f022                	sd	s0,32(sp)
    8000344e:	ec26                	sd	s1,24(sp)
    80003450:	e84a                	sd	s2,16(sp)
    80003452:	e44e                	sd	s3,8(sp)
    80003454:	e052                	sd	s4,0(sp)
    80003456:	1800                	addi	s0,sp,48
    80003458:	89aa                	mv	s3,a0
    8000345a:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    8000345c:	00022517          	auipc	a0,0x22
    80003460:	80450513          	addi	a0,a0,-2044 # 80024c60 <icache>
    80003464:	ffffe097          	auipc	ra,0xffffe
    80003468:	820080e7          	jalr	-2016(ra) # 80000c84 <acquire>
  empty = 0;
    8000346c:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000346e:	00022497          	auipc	s1,0x22
    80003472:	80a48493          	addi	s1,s1,-2038 # 80024c78 <icache+0x18>
    80003476:	00023697          	auipc	a3,0x23
    8000347a:	29268693          	addi	a3,a3,658 # 80026708 <log>
    8000347e:	a039                	j	8000348c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003480:	02090b63          	beqz	s2,800034b6 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003484:	08848493          	addi	s1,s1,136
    80003488:	02d48a63          	beq	s1,a3,800034bc <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348c:	449c                	lw	a5,8(s1)
    8000348e:	fef059e3          	blez	a5,80003480 <iget+0x38>
    80003492:	4098                	lw	a4,0(s1)
    80003494:	ff3716e3          	bne	a4,s3,80003480 <iget+0x38>
    80003498:	40d8                	lw	a4,4(s1)
    8000349a:	ff4713e3          	bne	a4,s4,80003480 <iget+0x38>
      ip->ref++;
    8000349e:	2785                	addiw	a5,a5,1
    800034a0:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800034a2:	00021517          	auipc	a0,0x21
    800034a6:	7be50513          	addi	a0,a0,1982 # 80024c60 <icache>
    800034aa:	ffffe097          	auipc	ra,0xffffe
    800034ae:	88e080e7          	jalr	-1906(ra) # 80000d38 <release>
      return ip;
    800034b2:	8926                	mv	s2,s1
    800034b4:	a03d                	j	800034e2 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b6:	f7f9                	bnez	a5,80003484 <iget+0x3c>
    800034b8:	8926                	mv	s2,s1
    800034ba:	b7e9                	j	80003484 <iget+0x3c>
  if(empty == 0)
    800034bc:	02090c63          	beqz	s2,800034f4 <iget+0xac>
  ip->dev = dev;
    800034c0:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c4:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c8:	4785                	li	a5,1
    800034ca:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034ce:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    800034d2:	00021517          	auipc	a0,0x21
    800034d6:	78e50513          	addi	a0,a0,1934 # 80024c60 <icache>
    800034da:	ffffe097          	auipc	ra,0xffffe
    800034de:	85e080e7          	jalr	-1954(ra) # 80000d38 <release>
}
    800034e2:	854a                	mv	a0,s2
    800034e4:	70a2                	ld	ra,40(sp)
    800034e6:	7402                	ld	s0,32(sp)
    800034e8:	64e2                	ld	s1,24(sp)
    800034ea:	6942                	ld	s2,16(sp)
    800034ec:	69a2                	ld	s3,8(sp)
    800034ee:	6a02                	ld	s4,0(sp)
    800034f0:	6145                	addi	sp,sp,48
    800034f2:	8082                	ret
    panic("iget: no inodes");
    800034f4:	00005517          	auipc	a0,0x5
    800034f8:	08c50513          	addi	a0,a0,140 # 80008580 <syscalls+0x140>
    800034fc:	ffffd097          	auipc	ra,0xffffd
    80003500:	04c080e7          	jalr	76(ra) # 80000548 <panic>

0000000080003504 <fsinit>:
fsinit(int dev) {
    80003504:	7179                	addi	sp,sp,-48
    80003506:	f406                	sd	ra,40(sp)
    80003508:	f022                	sd	s0,32(sp)
    8000350a:	ec26                	sd	s1,24(sp)
    8000350c:	e84a                	sd	s2,16(sp)
    8000350e:	e44e                	sd	s3,8(sp)
    80003510:	1800                	addi	s0,sp,48
    80003512:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003514:	4585                	li	a1,1
    80003516:	00000097          	auipc	ra,0x0
    8000351a:	a64080e7          	jalr	-1436(ra) # 80002f7a <bread>
    8000351e:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003520:	00021997          	auipc	s3,0x21
    80003524:	72098993          	addi	s3,s3,1824 # 80024c40 <sb>
    80003528:	02000613          	li	a2,32
    8000352c:	05850593          	addi	a1,a0,88
    80003530:	854e                	mv	a0,s3
    80003532:	ffffe097          	auipc	ra,0xffffe
    80003536:	8ae080e7          	jalr	-1874(ra) # 80000de0 <memmove>
  brelse(bp);
    8000353a:	8526                	mv	a0,s1
    8000353c:	00000097          	auipc	ra,0x0
    80003540:	b6e080e7          	jalr	-1170(ra) # 800030aa <brelse>
  if(sb.magic != FSMAGIC)
    80003544:	0009a703          	lw	a4,0(s3)
    80003548:	102037b7          	lui	a5,0x10203
    8000354c:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003550:	02f71263          	bne	a4,a5,80003574 <fsinit+0x70>
  initlog(dev, &sb);
    80003554:	00021597          	auipc	a1,0x21
    80003558:	6ec58593          	addi	a1,a1,1772 # 80024c40 <sb>
    8000355c:	854a                	mv	a0,s2
    8000355e:	00001097          	auipc	ra,0x1
    80003562:	b38080e7          	jalr	-1224(ra) # 80004096 <initlog>
}
    80003566:	70a2                	ld	ra,40(sp)
    80003568:	7402                	ld	s0,32(sp)
    8000356a:	64e2                	ld	s1,24(sp)
    8000356c:	6942                	ld	s2,16(sp)
    8000356e:	69a2                	ld	s3,8(sp)
    80003570:	6145                	addi	sp,sp,48
    80003572:	8082                	ret
    panic("invalid file system");
    80003574:	00005517          	auipc	a0,0x5
    80003578:	01c50513          	addi	a0,a0,28 # 80008590 <syscalls+0x150>
    8000357c:	ffffd097          	auipc	ra,0xffffd
    80003580:	fcc080e7          	jalr	-52(ra) # 80000548 <panic>

0000000080003584 <iinit>:
{
    80003584:	7179                	addi	sp,sp,-48
    80003586:	f406                	sd	ra,40(sp)
    80003588:	f022                	sd	s0,32(sp)
    8000358a:	ec26                	sd	s1,24(sp)
    8000358c:	e84a                	sd	s2,16(sp)
    8000358e:	e44e                	sd	s3,8(sp)
    80003590:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003592:	00005597          	auipc	a1,0x5
    80003596:	01658593          	addi	a1,a1,22 # 800085a8 <syscalls+0x168>
    8000359a:	00021517          	auipc	a0,0x21
    8000359e:	6c650513          	addi	a0,a0,1734 # 80024c60 <icache>
    800035a2:	ffffd097          	auipc	ra,0xffffd
    800035a6:	652080e7          	jalr	1618(ra) # 80000bf4 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035aa:	00021497          	auipc	s1,0x21
    800035ae:	6de48493          	addi	s1,s1,1758 # 80024c88 <icache+0x28>
    800035b2:	00023997          	auipc	s3,0x23
    800035b6:	16698993          	addi	s3,s3,358 # 80026718 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800035ba:	00005917          	auipc	s2,0x5
    800035be:	ff690913          	addi	s2,s2,-10 # 800085b0 <syscalls+0x170>
    800035c2:	85ca                	mv	a1,s2
    800035c4:	8526                	mv	a0,s1
    800035c6:	00001097          	auipc	ra,0x1
    800035ca:	e36080e7          	jalr	-458(ra) # 800043fc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035ce:	08848493          	addi	s1,s1,136
    800035d2:	ff3498e3          	bne	s1,s3,800035c2 <iinit+0x3e>
}
    800035d6:	70a2                	ld	ra,40(sp)
    800035d8:	7402                	ld	s0,32(sp)
    800035da:	64e2                	ld	s1,24(sp)
    800035dc:	6942                	ld	s2,16(sp)
    800035de:	69a2                	ld	s3,8(sp)
    800035e0:	6145                	addi	sp,sp,48
    800035e2:	8082                	ret

00000000800035e4 <ialloc>:
{
    800035e4:	715d                	addi	sp,sp,-80
    800035e6:	e486                	sd	ra,72(sp)
    800035e8:	e0a2                	sd	s0,64(sp)
    800035ea:	fc26                	sd	s1,56(sp)
    800035ec:	f84a                	sd	s2,48(sp)
    800035ee:	f44e                	sd	s3,40(sp)
    800035f0:	f052                	sd	s4,32(sp)
    800035f2:	ec56                	sd	s5,24(sp)
    800035f4:	e85a                	sd	s6,16(sp)
    800035f6:	e45e                	sd	s7,8(sp)
    800035f8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035fa:	00021717          	auipc	a4,0x21
    800035fe:	65272703          	lw	a4,1618(a4) # 80024c4c <sb+0xc>
    80003602:	4785                	li	a5,1
    80003604:	04e7fa63          	bgeu	a5,a4,80003658 <ialloc+0x74>
    80003608:	8aaa                	mv	s5,a0
    8000360a:	8bae                	mv	s7,a1
    8000360c:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000360e:	00021a17          	auipc	s4,0x21
    80003612:	632a0a13          	addi	s4,s4,1586 # 80024c40 <sb>
    80003616:	00048b1b          	sext.w	s6,s1
    8000361a:	0044d593          	srli	a1,s1,0x4
    8000361e:	018a2783          	lw	a5,24(s4)
    80003622:	9dbd                	addw	a1,a1,a5
    80003624:	8556                	mv	a0,s5
    80003626:	00000097          	auipc	ra,0x0
    8000362a:	954080e7          	jalr	-1708(ra) # 80002f7a <bread>
    8000362e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003630:	05850993          	addi	s3,a0,88
    80003634:	00f4f793          	andi	a5,s1,15
    80003638:	079a                	slli	a5,a5,0x6
    8000363a:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000363c:	00099783          	lh	a5,0(s3)
    80003640:	c785                	beqz	a5,80003668 <ialloc+0x84>
    brelse(bp);
    80003642:	00000097          	auipc	ra,0x0
    80003646:	a68080e7          	jalr	-1432(ra) # 800030aa <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    8000364a:	0485                	addi	s1,s1,1
    8000364c:	00ca2703          	lw	a4,12(s4)
    80003650:	0004879b          	sext.w	a5,s1
    80003654:	fce7e1e3          	bltu	a5,a4,80003616 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003658:	00005517          	auipc	a0,0x5
    8000365c:	f6050513          	addi	a0,a0,-160 # 800085b8 <syscalls+0x178>
    80003660:	ffffd097          	auipc	ra,0xffffd
    80003664:	ee8080e7          	jalr	-280(ra) # 80000548 <panic>
      memset(dip, 0, sizeof(*dip));
    80003668:	04000613          	li	a2,64
    8000366c:	4581                	li	a1,0
    8000366e:	854e                	mv	a0,s3
    80003670:	ffffd097          	auipc	ra,0xffffd
    80003674:	710080e7          	jalr	1808(ra) # 80000d80 <memset>
      dip->type = type;
    80003678:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    8000367c:	854a                	mv	a0,s2
    8000367e:	00001097          	auipc	ra,0x1
    80003682:	c90080e7          	jalr	-880(ra) # 8000430e <log_write>
      brelse(bp);
    80003686:	854a                	mv	a0,s2
    80003688:	00000097          	auipc	ra,0x0
    8000368c:	a22080e7          	jalr	-1502(ra) # 800030aa <brelse>
      return iget(dev, inum);
    80003690:	85da                	mv	a1,s6
    80003692:	8556                	mv	a0,s5
    80003694:	00000097          	auipc	ra,0x0
    80003698:	db4080e7          	jalr	-588(ra) # 80003448 <iget>
}
    8000369c:	60a6                	ld	ra,72(sp)
    8000369e:	6406                	ld	s0,64(sp)
    800036a0:	74e2                	ld	s1,56(sp)
    800036a2:	7942                	ld	s2,48(sp)
    800036a4:	79a2                	ld	s3,40(sp)
    800036a6:	7a02                	ld	s4,32(sp)
    800036a8:	6ae2                	ld	s5,24(sp)
    800036aa:	6b42                	ld	s6,16(sp)
    800036ac:	6ba2                	ld	s7,8(sp)
    800036ae:	6161                	addi	sp,sp,80
    800036b0:	8082                	ret

00000000800036b2 <iupdate>:
{
    800036b2:	1101                	addi	sp,sp,-32
    800036b4:	ec06                	sd	ra,24(sp)
    800036b6:	e822                	sd	s0,16(sp)
    800036b8:	e426                	sd	s1,8(sp)
    800036ba:	e04a                	sd	s2,0(sp)
    800036bc:	1000                	addi	s0,sp,32
    800036be:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036c0:	415c                	lw	a5,4(a0)
    800036c2:	0047d79b          	srliw	a5,a5,0x4
    800036c6:	00021597          	auipc	a1,0x21
    800036ca:	5925a583          	lw	a1,1426(a1) # 80024c58 <sb+0x18>
    800036ce:	9dbd                	addw	a1,a1,a5
    800036d0:	4108                	lw	a0,0(a0)
    800036d2:	00000097          	auipc	ra,0x0
    800036d6:	8a8080e7          	jalr	-1880(ra) # 80002f7a <bread>
    800036da:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036dc:	05850793          	addi	a5,a0,88
    800036e0:	40c8                	lw	a0,4(s1)
    800036e2:	893d                	andi	a0,a0,15
    800036e4:	051a                	slli	a0,a0,0x6
    800036e6:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    800036e8:	04449703          	lh	a4,68(s1)
    800036ec:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800036f0:	04649703          	lh	a4,70(s1)
    800036f4:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800036f8:	04849703          	lh	a4,72(s1)
    800036fc:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003700:	04a49703          	lh	a4,74(s1)
    80003704:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003708:	44f8                	lw	a4,76(s1)
    8000370a:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000370c:	03400613          	li	a2,52
    80003710:	05048593          	addi	a1,s1,80
    80003714:	0531                	addi	a0,a0,12
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	6ca080e7          	jalr	1738(ra) # 80000de0 <memmove>
  log_write(bp);
    8000371e:	854a                	mv	a0,s2
    80003720:	00001097          	auipc	ra,0x1
    80003724:	bee080e7          	jalr	-1042(ra) # 8000430e <log_write>
  brelse(bp);
    80003728:	854a                	mv	a0,s2
    8000372a:	00000097          	auipc	ra,0x0
    8000372e:	980080e7          	jalr	-1664(ra) # 800030aa <brelse>
}
    80003732:	60e2                	ld	ra,24(sp)
    80003734:	6442                	ld	s0,16(sp)
    80003736:	64a2                	ld	s1,8(sp)
    80003738:	6902                	ld	s2,0(sp)
    8000373a:	6105                	addi	sp,sp,32
    8000373c:	8082                	ret

000000008000373e <idup>:
{
    8000373e:	1101                	addi	sp,sp,-32
    80003740:	ec06                	sd	ra,24(sp)
    80003742:	e822                	sd	s0,16(sp)
    80003744:	e426                	sd	s1,8(sp)
    80003746:	1000                	addi	s0,sp,32
    80003748:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    8000374a:	00021517          	auipc	a0,0x21
    8000374e:	51650513          	addi	a0,a0,1302 # 80024c60 <icache>
    80003752:	ffffd097          	auipc	ra,0xffffd
    80003756:	532080e7          	jalr	1330(ra) # 80000c84 <acquire>
  ip->ref++;
    8000375a:	449c                	lw	a5,8(s1)
    8000375c:	2785                	addiw	a5,a5,1
    8000375e:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003760:	00021517          	auipc	a0,0x21
    80003764:	50050513          	addi	a0,a0,1280 # 80024c60 <icache>
    80003768:	ffffd097          	auipc	ra,0xffffd
    8000376c:	5d0080e7          	jalr	1488(ra) # 80000d38 <release>
}
    80003770:	8526                	mv	a0,s1
    80003772:	60e2                	ld	ra,24(sp)
    80003774:	6442                	ld	s0,16(sp)
    80003776:	64a2                	ld	s1,8(sp)
    80003778:	6105                	addi	sp,sp,32
    8000377a:	8082                	ret

000000008000377c <ilock>:
{
    8000377c:	1101                	addi	sp,sp,-32
    8000377e:	ec06                	sd	ra,24(sp)
    80003780:	e822                	sd	s0,16(sp)
    80003782:	e426                	sd	s1,8(sp)
    80003784:	e04a                	sd	s2,0(sp)
    80003786:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003788:	c115                	beqz	a0,800037ac <ilock+0x30>
    8000378a:	84aa                	mv	s1,a0
    8000378c:	451c                	lw	a5,8(a0)
    8000378e:	00f05f63          	blez	a5,800037ac <ilock+0x30>
  acquiresleep(&ip->lock);
    80003792:	0541                	addi	a0,a0,16
    80003794:	00001097          	auipc	ra,0x1
    80003798:	ca2080e7          	jalr	-862(ra) # 80004436 <acquiresleep>
  if(ip->valid == 0){
    8000379c:	40bc                	lw	a5,64(s1)
    8000379e:	cf99                	beqz	a5,800037bc <ilock+0x40>
}
    800037a0:	60e2                	ld	ra,24(sp)
    800037a2:	6442                	ld	s0,16(sp)
    800037a4:	64a2                	ld	s1,8(sp)
    800037a6:	6902                	ld	s2,0(sp)
    800037a8:	6105                	addi	sp,sp,32
    800037aa:	8082                	ret
    panic("ilock");
    800037ac:	00005517          	auipc	a0,0x5
    800037b0:	e2450513          	addi	a0,a0,-476 # 800085d0 <syscalls+0x190>
    800037b4:	ffffd097          	auipc	ra,0xffffd
    800037b8:	d94080e7          	jalr	-620(ra) # 80000548 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037bc:	40dc                	lw	a5,4(s1)
    800037be:	0047d79b          	srliw	a5,a5,0x4
    800037c2:	00021597          	auipc	a1,0x21
    800037c6:	4965a583          	lw	a1,1174(a1) # 80024c58 <sb+0x18>
    800037ca:	9dbd                	addw	a1,a1,a5
    800037cc:	4088                	lw	a0,0(s1)
    800037ce:	fffff097          	auipc	ra,0xfffff
    800037d2:	7ac080e7          	jalr	1964(ra) # 80002f7a <bread>
    800037d6:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037d8:	05850593          	addi	a1,a0,88
    800037dc:	40dc                	lw	a5,4(s1)
    800037de:	8bbd                	andi	a5,a5,15
    800037e0:	079a                	slli	a5,a5,0x6
    800037e2:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037e4:	00059783          	lh	a5,0(a1)
    800037e8:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037ec:	00259783          	lh	a5,2(a1)
    800037f0:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037f4:	00459783          	lh	a5,4(a1)
    800037f8:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800037fc:	00659783          	lh	a5,6(a1)
    80003800:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003804:	459c                	lw	a5,8(a1)
    80003806:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003808:	03400613          	li	a2,52
    8000380c:	05b1                	addi	a1,a1,12
    8000380e:	05048513          	addi	a0,s1,80
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	5ce080e7          	jalr	1486(ra) # 80000de0 <memmove>
    brelse(bp);
    8000381a:	854a                	mv	a0,s2
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	88e080e7          	jalr	-1906(ra) # 800030aa <brelse>
    ip->valid = 1;
    80003824:	4785                	li	a5,1
    80003826:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003828:	04449783          	lh	a5,68(s1)
    8000382c:	fbb5                	bnez	a5,800037a0 <ilock+0x24>
      panic("ilock: no type");
    8000382e:	00005517          	auipc	a0,0x5
    80003832:	daa50513          	addi	a0,a0,-598 # 800085d8 <syscalls+0x198>
    80003836:	ffffd097          	auipc	ra,0xffffd
    8000383a:	d12080e7          	jalr	-750(ra) # 80000548 <panic>

000000008000383e <iunlock>:
{
    8000383e:	1101                	addi	sp,sp,-32
    80003840:	ec06                	sd	ra,24(sp)
    80003842:	e822                	sd	s0,16(sp)
    80003844:	e426                	sd	s1,8(sp)
    80003846:	e04a                	sd	s2,0(sp)
    80003848:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000384a:	c905                	beqz	a0,8000387a <iunlock+0x3c>
    8000384c:	84aa                	mv	s1,a0
    8000384e:	01050913          	addi	s2,a0,16
    80003852:	854a                	mv	a0,s2
    80003854:	00001097          	auipc	ra,0x1
    80003858:	c7c080e7          	jalr	-900(ra) # 800044d0 <holdingsleep>
    8000385c:	cd19                	beqz	a0,8000387a <iunlock+0x3c>
    8000385e:	449c                	lw	a5,8(s1)
    80003860:	00f05d63          	blez	a5,8000387a <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003864:	854a                	mv	a0,s2
    80003866:	00001097          	auipc	ra,0x1
    8000386a:	c26080e7          	jalr	-986(ra) # 8000448c <releasesleep>
}
    8000386e:	60e2                	ld	ra,24(sp)
    80003870:	6442                	ld	s0,16(sp)
    80003872:	64a2                	ld	s1,8(sp)
    80003874:	6902                	ld	s2,0(sp)
    80003876:	6105                	addi	sp,sp,32
    80003878:	8082                	ret
    panic("iunlock");
    8000387a:	00005517          	auipc	a0,0x5
    8000387e:	d6e50513          	addi	a0,a0,-658 # 800085e8 <syscalls+0x1a8>
    80003882:	ffffd097          	auipc	ra,0xffffd
    80003886:	cc6080e7          	jalr	-826(ra) # 80000548 <panic>

000000008000388a <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000388a:	7179                	addi	sp,sp,-48
    8000388c:	f406                	sd	ra,40(sp)
    8000388e:	f022                	sd	s0,32(sp)
    80003890:	ec26                	sd	s1,24(sp)
    80003892:	e84a                	sd	s2,16(sp)
    80003894:	e44e                	sd	s3,8(sp)
    80003896:	e052                	sd	s4,0(sp)
    80003898:	1800                	addi	s0,sp,48
    8000389a:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    8000389c:	05050493          	addi	s1,a0,80
    800038a0:	08050913          	addi	s2,a0,128
    800038a4:	a021                	j	800038ac <itrunc+0x22>
    800038a6:	0491                	addi	s1,s1,4
    800038a8:	01248d63          	beq	s1,s2,800038c2 <itrunc+0x38>
    if(ip->addrs[i]){
    800038ac:	408c                	lw	a1,0(s1)
    800038ae:	dde5                	beqz	a1,800038a6 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038b0:	0009a503          	lw	a0,0(s3)
    800038b4:	00000097          	auipc	ra,0x0
    800038b8:	90c080e7          	jalr	-1780(ra) # 800031c0 <bfree>
      ip->addrs[i] = 0;
    800038bc:	0004a023          	sw	zero,0(s1)
    800038c0:	b7dd                	j	800038a6 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038c2:	0809a583          	lw	a1,128(s3)
    800038c6:	e185                	bnez	a1,800038e6 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038c8:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038cc:	854e                	mv	a0,s3
    800038ce:	00000097          	auipc	ra,0x0
    800038d2:	de4080e7          	jalr	-540(ra) # 800036b2 <iupdate>
}
    800038d6:	70a2                	ld	ra,40(sp)
    800038d8:	7402                	ld	s0,32(sp)
    800038da:	64e2                	ld	s1,24(sp)
    800038dc:	6942                	ld	s2,16(sp)
    800038de:	69a2                	ld	s3,8(sp)
    800038e0:	6a02                	ld	s4,0(sp)
    800038e2:	6145                	addi	sp,sp,48
    800038e4:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038e6:	0009a503          	lw	a0,0(s3)
    800038ea:	fffff097          	auipc	ra,0xfffff
    800038ee:	690080e7          	jalr	1680(ra) # 80002f7a <bread>
    800038f2:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038f4:	05850493          	addi	s1,a0,88
    800038f8:	45850913          	addi	s2,a0,1112
    800038fc:	a811                	j	80003910 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800038fe:	0009a503          	lw	a0,0(s3)
    80003902:	00000097          	auipc	ra,0x0
    80003906:	8be080e7          	jalr	-1858(ra) # 800031c0 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000390a:	0491                	addi	s1,s1,4
    8000390c:	01248563          	beq	s1,s2,80003916 <itrunc+0x8c>
      if(a[j])
    80003910:	408c                	lw	a1,0(s1)
    80003912:	dde5                	beqz	a1,8000390a <itrunc+0x80>
    80003914:	b7ed                	j	800038fe <itrunc+0x74>
    brelse(bp);
    80003916:	8552                	mv	a0,s4
    80003918:	fffff097          	auipc	ra,0xfffff
    8000391c:	792080e7          	jalr	1938(ra) # 800030aa <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003920:	0809a583          	lw	a1,128(s3)
    80003924:	0009a503          	lw	a0,0(s3)
    80003928:	00000097          	auipc	ra,0x0
    8000392c:	898080e7          	jalr	-1896(ra) # 800031c0 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003930:	0809a023          	sw	zero,128(s3)
    80003934:	bf51                	j	800038c8 <itrunc+0x3e>

0000000080003936 <iput>:
{
    80003936:	1101                	addi	sp,sp,-32
    80003938:	ec06                	sd	ra,24(sp)
    8000393a:	e822                	sd	s0,16(sp)
    8000393c:	e426                	sd	s1,8(sp)
    8000393e:	e04a                	sd	s2,0(sp)
    80003940:	1000                	addi	s0,sp,32
    80003942:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003944:	00021517          	auipc	a0,0x21
    80003948:	31c50513          	addi	a0,a0,796 # 80024c60 <icache>
    8000394c:	ffffd097          	auipc	ra,0xffffd
    80003950:	338080e7          	jalr	824(ra) # 80000c84 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003954:	4498                	lw	a4,8(s1)
    80003956:	4785                	li	a5,1
    80003958:	02f70363          	beq	a4,a5,8000397e <iput+0x48>
  ip->ref--;
    8000395c:	449c                	lw	a5,8(s1)
    8000395e:	37fd                	addiw	a5,a5,-1
    80003960:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003962:	00021517          	auipc	a0,0x21
    80003966:	2fe50513          	addi	a0,a0,766 # 80024c60 <icache>
    8000396a:	ffffd097          	auipc	ra,0xffffd
    8000396e:	3ce080e7          	jalr	974(ra) # 80000d38 <release>
}
    80003972:	60e2                	ld	ra,24(sp)
    80003974:	6442                	ld	s0,16(sp)
    80003976:	64a2                	ld	s1,8(sp)
    80003978:	6902                	ld	s2,0(sp)
    8000397a:	6105                	addi	sp,sp,32
    8000397c:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000397e:	40bc                	lw	a5,64(s1)
    80003980:	dff1                	beqz	a5,8000395c <iput+0x26>
    80003982:	04a49783          	lh	a5,74(s1)
    80003986:	fbf9                	bnez	a5,8000395c <iput+0x26>
    acquiresleep(&ip->lock);
    80003988:	01048913          	addi	s2,s1,16
    8000398c:	854a                	mv	a0,s2
    8000398e:	00001097          	auipc	ra,0x1
    80003992:	aa8080e7          	jalr	-1368(ra) # 80004436 <acquiresleep>
    release(&icache.lock);
    80003996:	00021517          	auipc	a0,0x21
    8000399a:	2ca50513          	addi	a0,a0,714 # 80024c60 <icache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	39a080e7          	jalr	922(ra) # 80000d38 <release>
    itrunc(ip);
    800039a6:	8526                	mv	a0,s1
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	ee2080e7          	jalr	-286(ra) # 8000388a <itrunc>
    ip->type = 0;
    800039b0:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039b4:	8526                	mv	a0,s1
    800039b6:	00000097          	auipc	ra,0x0
    800039ba:	cfc080e7          	jalr	-772(ra) # 800036b2 <iupdate>
    ip->valid = 0;
    800039be:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039c2:	854a                	mv	a0,s2
    800039c4:	00001097          	auipc	ra,0x1
    800039c8:	ac8080e7          	jalr	-1336(ra) # 8000448c <releasesleep>
    acquire(&icache.lock);
    800039cc:	00021517          	auipc	a0,0x21
    800039d0:	29450513          	addi	a0,a0,660 # 80024c60 <icache>
    800039d4:	ffffd097          	auipc	ra,0xffffd
    800039d8:	2b0080e7          	jalr	688(ra) # 80000c84 <acquire>
    800039dc:	b741                	j	8000395c <iput+0x26>

00000000800039de <iunlockput>:
{
    800039de:	1101                	addi	sp,sp,-32
    800039e0:	ec06                	sd	ra,24(sp)
    800039e2:	e822                	sd	s0,16(sp)
    800039e4:	e426                	sd	s1,8(sp)
    800039e6:	1000                	addi	s0,sp,32
    800039e8:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ea:	00000097          	auipc	ra,0x0
    800039ee:	e54080e7          	jalr	-428(ra) # 8000383e <iunlock>
  iput(ip);
    800039f2:	8526                	mv	a0,s1
    800039f4:	00000097          	auipc	ra,0x0
    800039f8:	f42080e7          	jalr	-190(ra) # 80003936 <iput>
}
    800039fc:	60e2                	ld	ra,24(sp)
    800039fe:	6442                	ld	s0,16(sp)
    80003a00:	64a2                	ld	s1,8(sp)
    80003a02:	6105                	addi	sp,sp,32
    80003a04:	8082                	ret

0000000080003a06 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a06:	1141                	addi	sp,sp,-16
    80003a08:	e422                	sd	s0,8(sp)
    80003a0a:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a0c:	411c                	lw	a5,0(a0)
    80003a0e:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a10:	415c                	lw	a5,4(a0)
    80003a12:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a14:	04451783          	lh	a5,68(a0)
    80003a18:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a1c:	04a51783          	lh	a5,74(a0)
    80003a20:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a24:	04c56783          	lwu	a5,76(a0)
    80003a28:	e99c                	sd	a5,16(a1)
}
    80003a2a:	6422                	ld	s0,8(sp)
    80003a2c:	0141                	addi	sp,sp,16
    80003a2e:	8082                	ret

0000000080003a30 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a30:	457c                	lw	a5,76(a0)
    80003a32:	0ed7e863          	bltu	a5,a3,80003b22 <readi+0xf2>
{
    80003a36:	7159                	addi	sp,sp,-112
    80003a38:	f486                	sd	ra,104(sp)
    80003a3a:	f0a2                	sd	s0,96(sp)
    80003a3c:	eca6                	sd	s1,88(sp)
    80003a3e:	e8ca                	sd	s2,80(sp)
    80003a40:	e4ce                	sd	s3,72(sp)
    80003a42:	e0d2                	sd	s4,64(sp)
    80003a44:	fc56                	sd	s5,56(sp)
    80003a46:	f85a                	sd	s6,48(sp)
    80003a48:	f45e                	sd	s7,40(sp)
    80003a4a:	f062                	sd	s8,32(sp)
    80003a4c:	ec66                	sd	s9,24(sp)
    80003a4e:	e86a                	sd	s10,16(sp)
    80003a50:	e46e                	sd	s11,8(sp)
    80003a52:	1880                	addi	s0,sp,112
    80003a54:	8baa                	mv	s7,a0
    80003a56:	8c2e                	mv	s8,a1
    80003a58:	8ab2                	mv	s5,a2
    80003a5a:	84b6                	mv	s1,a3
    80003a5c:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003a5e:	9f35                	addw	a4,a4,a3
    return 0;
    80003a60:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a62:	08d76f63          	bltu	a4,a3,80003b00 <readi+0xd0>
  if(off + n > ip->size)
    80003a66:	00e7f463          	bgeu	a5,a4,80003a6e <readi+0x3e>
    n = ip->size - off;
    80003a6a:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a6e:	0a0b0863          	beqz	s6,80003b1e <readi+0xee>
    80003a72:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a74:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a78:	5cfd                	li	s9,-1
    80003a7a:	a82d                	j	80003ab4 <readi+0x84>
    80003a7c:	020a1d93          	slli	s11,s4,0x20
    80003a80:	020ddd93          	srli	s11,s11,0x20
    80003a84:	05890613          	addi	a2,s2,88
    80003a88:	86ee                	mv	a3,s11
    80003a8a:	963a                	add	a2,a2,a4
    80003a8c:	85d6                	mv	a1,s5
    80003a8e:	8562                	mv	a0,s8
    80003a90:	fffff097          	auipc	ra,0xfffff
    80003a94:	a40080e7          	jalr	-1472(ra) # 800024d0 <either_copyout>
    80003a98:	05950d63          	beq	a0,s9,80003af2 <readi+0xc2>
      brelse(bp);
      break;
    }
    brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	fffff097          	auipc	ra,0xfffff
    80003aa2:	60c080e7          	jalr	1548(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aa6:	013a09bb          	addw	s3,s4,s3
    80003aaa:	009a04bb          	addw	s1,s4,s1
    80003aae:	9aee                	add	s5,s5,s11
    80003ab0:	0569f663          	bgeu	s3,s6,80003afc <readi+0xcc>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003ab4:	000ba903          	lw	s2,0(s7)
    80003ab8:	00a4d59b          	srliw	a1,s1,0xa
    80003abc:	855e                	mv	a0,s7
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	8b0080e7          	jalr	-1872(ra) # 8000336e <bmap>
    80003ac6:	0005059b          	sext.w	a1,a0
    80003aca:	854a                	mv	a0,s2
    80003acc:	fffff097          	auipc	ra,0xfffff
    80003ad0:	4ae080e7          	jalr	1198(ra) # 80002f7a <bread>
    80003ad4:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ad6:	3ff4f713          	andi	a4,s1,1023
    80003ada:	40ed07bb          	subw	a5,s10,a4
    80003ade:	413b06bb          	subw	a3,s6,s3
    80003ae2:	8a3e                	mv	s4,a5
    80003ae4:	2781                	sext.w	a5,a5
    80003ae6:	0006861b          	sext.w	a2,a3
    80003aea:	f8f679e3          	bgeu	a2,a5,80003a7c <readi+0x4c>
    80003aee:	8a36                	mv	s4,a3
    80003af0:	b771                	j	80003a7c <readi+0x4c>
      brelse(bp);
    80003af2:	854a                	mv	a0,s2
    80003af4:	fffff097          	auipc	ra,0xfffff
    80003af8:	5b6080e7          	jalr	1462(ra) # 800030aa <brelse>
  }
  return tot;
    80003afc:	0009851b          	sext.w	a0,s3
}
    80003b00:	70a6                	ld	ra,104(sp)
    80003b02:	7406                	ld	s0,96(sp)
    80003b04:	64e6                	ld	s1,88(sp)
    80003b06:	6946                	ld	s2,80(sp)
    80003b08:	69a6                	ld	s3,72(sp)
    80003b0a:	6a06                	ld	s4,64(sp)
    80003b0c:	7ae2                	ld	s5,56(sp)
    80003b0e:	7b42                	ld	s6,48(sp)
    80003b10:	7ba2                	ld	s7,40(sp)
    80003b12:	7c02                	ld	s8,32(sp)
    80003b14:	6ce2                	ld	s9,24(sp)
    80003b16:	6d42                	ld	s10,16(sp)
    80003b18:	6da2                	ld	s11,8(sp)
    80003b1a:	6165                	addi	sp,sp,112
    80003b1c:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b1e:	89da                	mv	s3,s6
    80003b20:	bff1                	j	80003afc <readi+0xcc>
    return 0;
    80003b22:	4501                	li	a0,0
}
    80003b24:	8082                	ret

0000000080003b26 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b26:	457c                	lw	a5,76(a0)
    80003b28:	10d7e663          	bltu	a5,a3,80003c34 <writei+0x10e>
{
    80003b2c:	7159                	addi	sp,sp,-112
    80003b2e:	f486                	sd	ra,104(sp)
    80003b30:	f0a2                	sd	s0,96(sp)
    80003b32:	eca6                	sd	s1,88(sp)
    80003b34:	e8ca                	sd	s2,80(sp)
    80003b36:	e4ce                	sd	s3,72(sp)
    80003b38:	e0d2                	sd	s4,64(sp)
    80003b3a:	fc56                	sd	s5,56(sp)
    80003b3c:	f85a                	sd	s6,48(sp)
    80003b3e:	f45e                	sd	s7,40(sp)
    80003b40:	f062                	sd	s8,32(sp)
    80003b42:	ec66                	sd	s9,24(sp)
    80003b44:	e86a                	sd	s10,16(sp)
    80003b46:	e46e                	sd	s11,8(sp)
    80003b48:	1880                	addi	s0,sp,112
    80003b4a:	8baa                	mv	s7,a0
    80003b4c:	8c2e                	mv	s8,a1
    80003b4e:	8ab2                	mv	s5,a2
    80003b50:	8936                	mv	s2,a3
    80003b52:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b54:	00e687bb          	addw	a5,a3,a4
    80003b58:	0ed7e063          	bltu	a5,a3,80003c38 <writei+0x112>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b5c:	00043737          	lui	a4,0x43
    80003b60:	0cf76e63          	bltu	a4,a5,80003c3c <writei+0x116>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b64:	0a0b0763          	beqz	s6,80003c12 <writei+0xec>
    80003b68:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b6a:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b6e:	5cfd                	li	s9,-1
    80003b70:	a091                	j	80003bb4 <writei+0x8e>
    80003b72:	02099d93          	slli	s11,s3,0x20
    80003b76:	020ddd93          	srli	s11,s11,0x20
    80003b7a:	05848513          	addi	a0,s1,88
    80003b7e:	86ee                	mv	a3,s11
    80003b80:	8656                	mv	a2,s5
    80003b82:	85e2                	mv	a1,s8
    80003b84:	953a                	add	a0,a0,a4
    80003b86:	fffff097          	auipc	ra,0xfffff
    80003b8a:	9a0080e7          	jalr	-1632(ra) # 80002526 <either_copyin>
    80003b8e:	07950263          	beq	a0,s9,80003bf2 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b92:	8526                	mv	a0,s1
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	77a080e7          	jalr	1914(ra) # 8000430e <log_write>
    brelse(bp);
    80003b9c:	8526                	mv	a0,s1
    80003b9e:	fffff097          	auipc	ra,0xfffff
    80003ba2:	50c080e7          	jalr	1292(ra) # 800030aa <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ba6:	01498a3b          	addw	s4,s3,s4
    80003baa:	0129893b          	addw	s2,s3,s2
    80003bae:	9aee                	add	s5,s5,s11
    80003bb0:	056a7663          	bgeu	s4,s6,80003bfc <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003bb4:	000ba483          	lw	s1,0(s7)
    80003bb8:	00a9559b          	srliw	a1,s2,0xa
    80003bbc:	855e                	mv	a0,s7
    80003bbe:	fffff097          	auipc	ra,0xfffff
    80003bc2:	7b0080e7          	jalr	1968(ra) # 8000336e <bmap>
    80003bc6:	0005059b          	sext.w	a1,a0
    80003bca:	8526                	mv	a0,s1
    80003bcc:	fffff097          	auipc	ra,0xfffff
    80003bd0:	3ae080e7          	jalr	942(ra) # 80002f7a <bread>
    80003bd4:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bd6:	3ff97713          	andi	a4,s2,1023
    80003bda:	40ed07bb          	subw	a5,s10,a4
    80003bde:	414b06bb          	subw	a3,s6,s4
    80003be2:	89be                	mv	s3,a5
    80003be4:	2781                	sext.w	a5,a5
    80003be6:	0006861b          	sext.w	a2,a3
    80003bea:	f8f674e3          	bgeu	a2,a5,80003b72 <writei+0x4c>
    80003bee:	89b6                	mv	s3,a3
    80003bf0:	b749                	j	80003b72 <writei+0x4c>
      brelse(bp);
    80003bf2:	8526                	mv	a0,s1
    80003bf4:	fffff097          	auipc	ra,0xfffff
    80003bf8:	4b6080e7          	jalr	1206(ra) # 800030aa <brelse>
  }

  if(n > 0){
    if(off > ip->size)
    80003bfc:	04cba783          	lw	a5,76(s7)
    80003c00:	0127f463          	bgeu	a5,s2,80003c08 <writei+0xe2>
      ip->size = off;
    80003c04:	052ba623          	sw	s2,76(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80003c08:	855e                	mv	a0,s7
    80003c0a:	00000097          	auipc	ra,0x0
    80003c0e:	aa8080e7          	jalr	-1368(ra) # 800036b2 <iupdate>
  }

  return n;
    80003c12:	000b051b          	sext.w	a0,s6
}
    80003c16:	70a6                	ld	ra,104(sp)
    80003c18:	7406                	ld	s0,96(sp)
    80003c1a:	64e6                	ld	s1,88(sp)
    80003c1c:	6946                	ld	s2,80(sp)
    80003c1e:	69a6                	ld	s3,72(sp)
    80003c20:	6a06                	ld	s4,64(sp)
    80003c22:	7ae2                	ld	s5,56(sp)
    80003c24:	7b42                	ld	s6,48(sp)
    80003c26:	7ba2                	ld	s7,40(sp)
    80003c28:	7c02                	ld	s8,32(sp)
    80003c2a:	6ce2                	ld	s9,24(sp)
    80003c2c:	6d42                	ld	s10,16(sp)
    80003c2e:	6da2                	ld	s11,8(sp)
    80003c30:	6165                	addi	sp,sp,112
    80003c32:	8082                	ret
    return -1;
    80003c34:	557d                	li	a0,-1
}
    80003c36:	8082                	ret
    return -1;
    80003c38:	557d                	li	a0,-1
    80003c3a:	bff1                	j	80003c16 <writei+0xf0>
    return -1;
    80003c3c:	557d                	li	a0,-1
    80003c3e:	bfe1                	j	80003c16 <writei+0xf0>

0000000080003c40 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c40:	1141                	addi	sp,sp,-16
    80003c42:	e406                	sd	ra,8(sp)
    80003c44:	e022                	sd	s0,0(sp)
    80003c46:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c48:	4639                	li	a2,14
    80003c4a:	ffffd097          	auipc	ra,0xffffd
    80003c4e:	212080e7          	jalr	530(ra) # 80000e5c <strncmp>
}
    80003c52:	60a2                	ld	ra,8(sp)
    80003c54:	6402                	ld	s0,0(sp)
    80003c56:	0141                	addi	sp,sp,16
    80003c58:	8082                	ret

0000000080003c5a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c5a:	7139                	addi	sp,sp,-64
    80003c5c:	fc06                	sd	ra,56(sp)
    80003c5e:	f822                	sd	s0,48(sp)
    80003c60:	f426                	sd	s1,40(sp)
    80003c62:	f04a                	sd	s2,32(sp)
    80003c64:	ec4e                	sd	s3,24(sp)
    80003c66:	e852                	sd	s4,16(sp)
    80003c68:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c6a:	04451703          	lh	a4,68(a0)
    80003c6e:	4785                	li	a5,1
    80003c70:	00f71a63          	bne	a4,a5,80003c84 <dirlookup+0x2a>
    80003c74:	892a                	mv	s2,a0
    80003c76:	89ae                	mv	s3,a1
    80003c78:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c7a:	457c                	lw	a5,76(a0)
    80003c7c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c7e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c80:	e79d                	bnez	a5,80003cae <dirlookup+0x54>
    80003c82:	a8a5                	j	80003cfa <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c84:	00005517          	auipc	a0,0x5
    80003c88:	96c50513          	addi	a0,a0,-1684 # 800085f0 <syscalls+0x1b0>
    80003c8c:	ffffd097          	auipc	ra,0xffffd
    80003c90:	8bc080e7          	jalr	-1860(ra) # 80000548 <panic>
      panic("dirlookup read");
    80003c94:	00005517          	auipc	a0,0x5
    80003c98:	97450513          	addi	a0,a0,-1676 # 80008608 <syscalls+0x1c8>
    80003c9c:	ffffd097          	auipc	ra,0xffffd
    80003ca0:	8ac080e7          	jalr	-1876(ra) # 80000548 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ca4:	24c1                	addiw	s1,s1,16
    80003ca6:	04c92783          	lw	a5,76(s2)
    80003caa:	04f4f763          	bgeu	s1,a5,80003cf8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cae:	4741                	li	a4,16
    80003cb0:	86a6                	mv	a3,s1
    80003cb2:	fc040613          	addi	a2,s0,-64
    80003cb6:	4581                	li	a1,0
    80003cb8:	854a                	mv	a0,s2
    80003cba:	00000097          	auipc	ra,0x0
    80003cbe:	d76080e7          	jalr	-650(ra) # 80003a30 <readi>
    80003cc2:	47c1                	li	a5,16
    80003cc4:	fcf518e3          	bne	a0,a5,80003c94 <dirlookup+0x3a>
    if(de.inum == 0)
    80003cc8:	fc045783          	lhu	a5,-64(s0)
    80003ccc:	dfe1                	beqz	a5,80003ca4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cce:	fc240593          	addi	a1,s0,-62
    80003cd2:	854e                	mv	a0,s3
    80003cd4:	00000097          	auipc	ra,0x0
    80003cd8:	f6c080e7          	jalr	-148(ra) # 80003c40 <namecmp>
    80003cdc:	f561                	bnez	a0,80003ca4 <dirlookup+0x4a>
      if(poff)
    80003cde:	000a0463          	beqz	s4,80003ce6 <dirlookup+0x8c>
        *poff = off;
    80003ce2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003ce6:	fc045583          	lhu	a1,-64(s0)
    80003cea:	00092503          	lw	a0,0(s2)
    80003cee:	fffff097          	auipc	ra,0xfffff
    80003cf2:	75a080e7          	jalr	1882(ra) # 80003448 <iget>
    80003cf6:	a011                	j	80003cfa <dirlookup+0xa0>
  return 0;
    80003cf8:	4501                	li	a0,0
}
    80003cfa:	70e2                	ld	ra,56(sp)
    80003cfc:	7442                	ld	s0,48(sp)
    80003cfe:	74a2                	ld	s1,40(sp)
    80003d00:	7902                	ld	s2,32(sp)
    80003d02:	69e2                	ld	s3,24(sp)
    80003d04:	6a42                	ld	s4,16(sp)
    80003d06:	6121                	addi	sp,sp,64
    80003d08:	8082                	ret

0000000080003d0a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d0a:	711d                	addi	sp,sp,-96
    80003d0c:	ec86                	sd	ra,88(sp)
    80003d0e:	e8a2                	sd	s0,80(sp)
    80003d10:	e4a6                	sd	s1,72(sp)
    80003d12:	e0ca                	sd	s2,64(sp)
    80003d14:	fc4e                	sd	s3,56(sp)
    80003d16:	f852                	sd	s4,48(sp)
    80003d18:	f456                	sd	s5,40(sp)
    80003d1a:	f05a                	sd	s6,32(sp)
    80003d1c:	ec5e                	sd	s7,24(sp)
    80003d1e:	e862                	sd	s8,16(sp)
    80003d20:	e466                	sd	s9,8(sp)
    80003d22:	1080                	addi	s0,sp,96
    80003d24:	84aa                	mv	s1,a0
    80003d26:	8b2e                	mv	s6,a1
    80003d28:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d2a:	00054703          	lbu	a4,0(a0)
    80003d2e:	02f00793          	li	a5,47
    80003d32:	02f70363          	beq	a4,a5,80003d58 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d36:	ffffe097          	auipc	ra,0xffffe
    80003d3a:	d1c080e7          	jalr	-740(ra) # 80001a52 <myproc>
    80003d3e:	15053503          	ld	a0,336(a0)
    80003d42:	00000097          	auipc	ra,0x0
    80003d46:	9fc080e7          	jalr	-1540(ra) # 8000373e <idup>
    80003d4a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003d4c:	02f00913          	li	s2,47
  len = path - s;
    80003d50:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003d52:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d54:	4c05                	li	s8,1
    80003d56:	a865                	j	80003e0e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003d58:	4585                	li	a1,1
    80003d5a:	4505                	li	a0,1
    80003d5c:	fffff097          	auipc	ra,0xfffff
    80003d60:	6ec080e7          	jalr	1772(ra) # 80003448 <iget>
    80003d64:	89aa                	mv	s3,a0
    80003d66:	b7dd                	j	80003d4c <namex+0x42>
      iunlockput(ip);
    80003d68:	854e                	mv	a0,s3
    80003d6a:	00000097          	auipc	ra,0x0
    80003d6e:	c74080e7          	jalr	-908(ra) # 800039de <iunlockput>
      return 0;
    80003d72:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d74:	854e                	mv	a0,s3
    80003d76:	60e6                	ld	ra,88(sp)
    80003d78:	6446                	ld	s0,80(sp)
    80003d7a:	64a6                	ld	s1,72(sp)
    80003d7c:	6906                	ld	s2,64(sp)
    80003d7e:	79e2                	ld	s3,56(sp)
    80003d80:	7a42                	ld	s4,48(sp)
    80003d82:	7aa2                	ld	s5,40(sp)
    80003d84:	7b02                	ld	s6,32(sp)
    80003d86:	6be2                	ld	s7,24(sp)
    80003d88:	6c42                	ld	s8,16(sp)
    80003d8a:	6ca2                	ld	s9,8(sp)
    80003d8c:	6125                	addi	sp,sp,96
    80003d8e:	8082                	ret
      iunlock(ip);
    80003d90:	854e                	mv	a0,s3
    80003d92:	00000097          	auipc	ra,0x0
    80003d96:	aac080e7          	jalr	-1364(ra) # 8000383e <iunlock>
      return ip;
    80003d9a:	bfe9                	j	80003d74 <namex+0x6a>
      iunlockput(ip);
    80003d9c:	854e                	mv	a0,s3
    80003d9e:	00000097          	auipc	ra,0x0
    80003da2:	c40080e7          	jalr	-960(ra) # 800039de <iunlockput>
      return 0;
    80003da6:	89d2                	mv	s3,s4
    80003da8:	b7f1                	j	80003d74 <namex+0x6a>
  len = path - s;
    80003daa:	40b48633          	sub	a2,s1,a1
    80003dae:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003db2:	094cd463          	bge	s9,s4,80003e3a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003db6:	4639                	li	a2,14
    80003db8:	8556                	mv	a0,s5
    80003dba:	ffffd097          	auipc	ra,0xffffd
    80003dbe:	026080e7          	jalr	38(ra) # 80000de0 <memmove>
  while(*path == '/')
    80003dc2:	0004c783          	lbu	a5,0(s1)
    80003dc6:	01279763          	bne	a5,s2,80003dd4 <namex+0xca>
    path++;
    80003dca:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dcc:	0004c783          	lbu	a5,0(s1)
    80003dd0:	ff278de3          	beq	a5,s2,80003dca <namex+0xc0>
    ilock(ip);
    80003dd4:	854e                	mv	a0,s3
    80003dd6:	00000097          	auipc	ra,0x0
    80003dda:	9a6080e7          	jalr	-1626(ra) # 8000377c <ilock>
    if(ip->type != T_DIR){
    80003dde:	04499783          	lh	a5,68(s3)
    80003de2:	f98793e3          	bne	a5,s8,80003d68 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80003de6:	000b0563          	beqz	s6,80003df0 <namex+0xe6>
    80003dea:	0004c783          	lbu	a5,0(s1)
    80003dee:	d3cd                	beqz	a5,80003d90 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003df0:	865e                	mv	a2,s7
    80003df2:	85d6                	mv	a1,s5
    80003df4:	854e                	mv	a0,s3
    80003df6:	00000097          	auipc	ra,0x0
    80003dfa:	e64080e7          	jalr	-412(ra) # 80003c5a <dirlookup>
    80003dfe:	8a2a                	mv	s4,a0
    80003e00:	dd51                	beqz	a0,80003d9c <namex+0x92>
    iunlockput(ip);
    80003e02:	854e                	mv	a0,s3
    80003e04:	00000097          	auipc	ra,0x0
    80003e08:	bda080e7          	jalr	-1062(ra) # 800039de <iunlockput>
    ip = next;
    80003e0c:	89d2                	mv	s3,s4
  while(*path == '/')
    80003e0e:	0004c783          	lbu	a5,0(s1)
    80003e12:	05279763          	bne	a5,s2,80003e60 <namex+0x156>
    path++;
    80003e16:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e18:	0004c783          	lbu	a5,0(s1)
    80003e1c:	ff278de3          	beq	a5,s2,80003e16 <namex+0x10c>
  if(*path == 0)
    80003e20:	c79d                	beqz	a5,80003e4e <namex+0x144>
    path++;
    80003e22:	85a6                	mv	a1,s1
  len = path - s;
    80003e24:	8a5e                	mv	s4,s7
    80003e26:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e28:	01278963          	beq	a5,s2,80003e3a <namex+0x130>
    80003e2c:	dfbd                	beqz	a5,80003daa <namex+0xa0>
    path++;
    80003e2e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80003e30:	0004c783          	lbu	a5,0(s1)
    80003e34:	ff279ce3          	bne	a5,s2,80003e2c <namex+0x122>
    80003e38:	bf8d                	j	80003daa <namex+0xa0>
    memmove(name, s, len);
    80003e3a:	2601                	sext.w	a2,a2
    80003e3c:	8556                	mv	a0,s5
    80003e3e:	ffffd097          	auipc	ra,0xffffd
    80003e42:	fa2080e7          	jalr	-94(ra) # 80000de0 <memmove>
    name[len] = 0;
    80003e46:	9a56                	add	s4,s4,s5
    80003e48:	000a0023          	sb	zero,0(s4)
    80003e4c:	bf9d                	j	80003dc2 <namex+0xb8>
  if(nameiparent){
    80003e4e:	f20b03e3          	beqz	s6,80003d74 <namex+0x6a>
    iput(ip);
    80003e52:	854e                	mv	a0,s3
    80003e54:	00000097          	auipc	ra,0x0
    80003e58:	ae2080e7          	jalr	-1310(ra) # 80003936 <iput>
    return 0;
    80003e5c:	4981                	li	s3,0
    80003e5e:	bf19                	j	80003d74 <namex+0x6a>
  if(*path == 0)
    80003e60:	d7fd                	beqz	a5,80003e4e <namex+0x144>
  while(*path != '/' && *path != 0)
    80003e62:	0004c783          	lbu	a5,0(s1)
    80003e66:	85a6                	mv	a1,s1
    80003e68:	b7d1                	j	80003e2c <namex+0x122>

0000000080003e6a <dirlink>:
{
    80003e6a:	7139                	addi	sp,sp,-64
    80003e6c:	fc06                	sd	ra,56(sp)
    80003e6e:	f822                	sd	s0,48(sp)
    80003e70:	f426                	sd	s1,40(sp)
    80003e72:	f04a                	sd	s2,32(sp)
    80003e74:	ec4e                	sd	s3,24(sp)
    80003e76:	e852                	sd	s4,16(sp)
    80003e78:	0080                	addi	s0,sp,64
    80003e7a:	892a                	mv	s2,a0
    80003e7c:	8a2e                	mv	s4,a1
    80003e7e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e80:	4601                	li	a2,0
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	dd8080e7          	jalr	-552(ra) # 80003c5a <dirlookup>
    80003e8a:	e93d                	bnez	a0,80003f00 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e8c:	04c92483          	lw	s1,76(s2)
    80003e90:	c49d                	beqz	s1,80003ebe <dirlink+0x54>
    80003e92:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e94:	4741                	li	a4,16
    80003e96:	86a6                	mv	a3,s1
    80003e98:	fc040613          	addi	a2,s0,-64
    80003e9c:	4581                	li	a1,0
    80003e9e:	854a                	mv	a0,s2
    80003ea0:	00000097          	auipc	ra,0x0
    80003ea4:	b90080e7          	jalr	-1136(ra) # 80003a30 <readi>
    80003ea8:	47c1                	li	a5,16
    80003eaa:	06f51163          	bne	a0,a5,80003f0c <dirlink+0xa2>
    if(de.inum == 0)
    80003eae:	fc045783          	lhu	a5,-64(s0)
    80003eb2:	c791                	beqz	a5,80003ebe <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb4:	24c1                	addiw	s1,s1,16
    80003eb6:	04c92783          	lw	a5,76(s2)
    80003eba:	fcf4ede3          	bltu	s1,a5,80003e94 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ebe:	4639                	li	a2,14
    80003ec0:	85d2                	mv	a1,s4
    80003ec2:	fc240513          	addi	a0,s0,-62
    80003ec6:	ffffd097          	auipc	ra,0xffffd
    80003eca:	fd2080e7          	jalr	-46(ra) # 80000e98 <strncpy>
  de.inum = inum;
    80003ece:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ed2:	4741                	li	a4,16
    80003ed4:	86a6                	mv	a3,s1
    80003ed6:	fc040613          	addi	a2,s0,-64
    80003eda:	4581                	li	a1,0
    80003edc:	854a                	mv	a0,s2
    80003ede:	00000097          	auipc	ra,0x0
    80003ee2:	c48080e7          	jalr	-952(ra) # 80003b26 <writei>
    80003ee6:	872a                	mv	a4,a0
    80003ee8:	47c1                	li	a5,16
  return 0;
    80003eea:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003eec:	02f71863          	bne	a4,a5,80003f1c <dirlink+0xb2>
}
    80003ef0:	70e2                	ld	ra,56(sp)
    80003ef2:	7442                	ld	s0,48(sp)
    80003ef4:	74a2                	ld	s1,40(sp)
    80003ef6:	7902                	ld	s2,32(sp)
    80003ef8:	69e2                	ld	s3,24(sp)
    80003efa:	6a42                	ld	s4,16(sp)
    80003efc:	6121                	addi	sp,sp,64
    80003efe:	8082                	ret
    iput(ip);
    80003f00:	00000097          	auipc	ra,0x0
    80003f04:	a36080e7          	jalr	-1482(ra) # 80003936 <iput>
    return -1;
    80003f08:	557d                	li	a0,-1
    80003f0a:	b7dd                	j	80003ef0 <dirlink+0x86>
      panic("dirlink read");
    80003f0c:	00004517          	auipc	a0,0x4
    80003f10:	70c50513          	addi	a0,a0,1804 # 80008618 <syscalls+0x1d8>
    80003f14:	ffffc097          	auipc	ra,0xffffc
    80003f18:	634080e7          	jalr	1588(ra) # 80000548 <panic>
    panic("dirlink");
    80003f1c:	00005517          	auipc	a0,0x5
    80003f20:	81c50513          	addi	a0,a0,-2020 # 80008738 <syscalls+0x2f8>
    80003f24:	ffffc097          	auipc	ra,0xffffc
    80003f28:	624080e7          	jalr	1572(ra) # 80000548 <panic>

0000000080003f2c <namei>:

struct inode*
namei(char *path)
{
    80003f2c:	1101                	addi	sp,sp,-32
    80003f2e:	ec06                	sd	ra,24(sp)
    80003f30:	e822                	sd	s0,16(sp)
    80003f32:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f34:	fe040613          	addi	a2,s0,-32
    80003f38:	4581                	li	a1,0
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	dd0080e7          	jalr	-560(ra) # 80003d0a <namex>
}
    80003f42:	60e2                	ld	ra,24(sp)
    80003f44:	6442                	ld	s0,16(sp)
    80003f46:	6105                	addi	sp,sp,32
    80003f48:	8082                	ret

0000000080003f4a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f4a:	1141                	addi	sp,sp,-16
    80003f4c:	e406                	sd	ra,8(sp)
    80003f4e:	e022                	sd	s0,0(sp)
    80003f50:	0800                	addi	s0,sp,16
    80003f52:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f54:	4585                	li	a1,1
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	db4080e7          	jalr	-588(ra) # 80003d0a <namex>
}
    80003f5e:	60a2                	ld	ra,8(sp)
    80003f60:	6402                	ld	s0,0(sp)
    80003f62:	0141                	addi	sp,sp,16
    80003f64:	8082                	ret

0000000080003f66 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f66:	1101                	addi	sp,sp,-32
    80003f68:	ec06                	sd	ra,24(sp)
    80003f6a:	e822                	sd	s0,16(sp)
    80003f6c:	e426                	sd	s1,8(sp)
    80003f6e:	e04a                	sd	s2,0(sp)
    80003f70:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f72:	00022917          	auipc	s2,0x22
    80003f76:	79690913          	addi	s2,s2,1942 # 80026708 <log>
    80003f7a:	01892583          	lw	a1,24(s2)
    80003f7e:	02892503          	lw	a0,40(s2)
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	ff8080e7          	jalr	-8(ra) # 80002f7a <bread>
    80003f8a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f8c:	02c92683          	lw	a3,44(s2)
    80003f90:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f92:	02d05763          	blez	a3,80003fc0 <write_head+0x5a>
    80003f96:	00022797          	auipc	a5,0x22
    80003f9a:	7a278793          	addi	a5,a5,1954 # 80026738 <log+0x30>
    80003f9e:	05c50713          	addi	a4,a0,92
    80003fa2:	36fd                	addiw	a3,a3,-1
    80003fa4:	1682                	slli	a3,a3,0x20
    80003fa6:	9281                	srli	a3,a3,0x20
    80003fa8:	068a                	slli	a3,a3,0x2
    80003faa:	00022617          	auipc	a2,0x22
    80003fae:	79260613          	addi	a2,a2,1938 # 8002673c <log+0x34>
    80003fb2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fb4:	4390                	lw	a2,0(a5)
    80003fb6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fb8:	0791                	addi	a5,a5,4
    80003fba:	0711                	addi	a4,a4,4
    80003fbc:	fed79ce3          	bne	a5,a3,80003fb4 <write_head+0x4e>
  }
  bwrite(buf);
    80003fc0:	8526                	mv	a0,s1
    80003fc2:	fffff097          	auipc	ra,0xfffff
    80003fc6:	0aa080e7          	jalr	170(ra) # 8000306c <bwrite>
  brelse(buf);
    80003fca:	8526                	mv	a0,s1
    80003fcc:	fffff097          	auipc	ra,0xfffff
    80003fd0:	0de080e7          	jalr	222(ra) # 800030aa <brelse>
}
    80003fd4:	60e2                	ld	ra,24(sp)
    80003fd6:	6442                	ld	s0,16(sp)
    80003fd8:	64a2                	ld	s1,8(sp)
    80003fda:	6902                	ld	s2,0(sp)
    80003fdc:	6105                	addi	sp,sp,32
    80003fde:	8082                	ret

0000000080003fe0 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fe0:	00022797          	auipc	a5,0x22
    80003fe4:	7547a783          	lw	a5,1876(a5) # 80026734 <log+0x2c>
    80003fe8:	0af05663          	blez	a5,80004094 <install_trans+0xb4>
{
    80003fec:	7139                	addi	sp,sp,-64
    80003fee:	fc06                	sd	ra,56(sp)
    80003ff0:	f822                	sd	s0,48(sp)
    80003ff2:	f426                	sd	s1,40(sp)
    80003ff4:	f04a                	sd	s2,32(sp)
    80003ff6:	ec4e                	sd	s3,24(sp)
    80003ff8:	e852                	sd	s4,16(sp)
    80003ffa:	e456                	sd	s5,8(sp)
    80003ffc:	0080                	addi	s0,sp,64
    80003ffe:	00022a97          	auipc	s5,0x22
    80004002:	73aa8a93          	addi	s5,s5,1850 # 80026738 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004006:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004008:	00022997          	auipc	s3,0x22
    8000400c:	70098993          	addi	s3,s3,1792 # 80026708 <log>
    80004010:	0189a583          	lw	a1,24(s3)
    80004014:	014585bb          	addw	a1,a1,s4
    80004018:	2585                	addiw	a1,a1,1
    8000401a:	0289a503          	lw	a0,40(s3)
    8000401e:	fffff097          	auipc	ra,0xfffff
    80004022:	f5c080e7          	jalr	-164(ra) # 80002f7a <bread>
    80004026:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004028:	000aa583          	lw	a1,0(s5)
    8000402c:	0289a503          	lw	a0,40(s3)
    80004030:	fffff097          	auipc	ra,0xfffff
    80004034:	f4a080e7          	jalr	-182(ra) # 80002f7a <bread>
    80004038:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000403a:	40000613          	li	a2,1024
    8000403e:	05890593          	addi	a1,s2,88
    80004042:	05850513          	addi	a0,a0,88
    80004046:	ffffd097          	auipc	ra,0xffffd
    8000404a:	d9a080e7          	jalr	-614(ra) # 80000de0 <memmove>
    bwrite(dbuf);  // write dst to disk
    8000404e:	8526                	mv	a0,s1
    80004050:	fffff097          	auipc	ra,0xfffff
    80004054:	01c080e7          	jalr	28(ra) # 8000306c <bwrite>
    bunpin(dbuf);
    80004058:	8526                	mv	a0,s1
    8000405a:	fffff097          	auipc	ra,0xfffff
    8000405e:	12a080e7          	jalr	298(ra) # 80003184 <bunpin>
    brelse(lbuf);
    80004062:	854a                	mv	a0,s2
    80004064:	fffff097          	auipc	ra,0xfffff
    80004068:	046080e7          	jalr	70(ra) # 800030aa <brelse>
    brelse(dbuf);
    8000406c:	8526                	mv	a0,s1
    8000406e:	fffff097          	auipc	ra,0xfffff
    80004072:	03c080e7          	jalr	60(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004076:	2a05                	addiw	s4,s4,1
    80004078:	0a91                	addi	s5,s5,4
    8000407a:	02c9a783          	lw	a5,44(s3)
    8000407e:	f8fa49e3          	blt	s4,a5,80004010 <install_trans+0x30>
}
    80004082:	70e2                	ld	ra,56(sp)
    80004084:	7442                	ld	s0,48(sp)
    80004086:	74a2                	ld	s1,40(sp)
    80004088:	7902                	ld	s2,32(sp)
    8000408a:	69e2                	ld	s3,24(sp)
    8000408c:	6a42                	ld	s4,16(sp)
    8000408e:	6aa2                	ld	s5,8(sp)
    80004090:	6121                	addi	sp,sp,64
    80004092:	8082                	ret
    80004094:	8082                	ret

0000000080004096 <initlog>:
{
    80004096:	7179                	addi	sp,sp,-48
    80004098:	f406                	sd	ra,40(sp)
    8000409a:	f022                	sd	s0,32(sp)
    8000409c:	ec26                	sd	s1,24(sp)
    8000409e:	e84a                	sd	s2,16(sp)
    800040a0:	e44e                	sd	s3,8(sp)
    800040a2:	1800                	addi	s0,sp,48
    800040a4:	892a                	mv	s2,a0
    800040a6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040a8:	00022497          	auipc	s1,0x22
    800040ac:	66048493          	addi	s1,s1,1632 # 80026708 <log>
    800040b0:	00004597          	auipc	a1,0x4
    800040b4:	57858593          	addi	a1,a1,1400 # 80008628 <syscalls+0x1e8>
    800040b8:	8526                	mv	a0,s1
    800040ba:	ffffd097          	auipc	ra,0xffffd
    800040be:	b3a080e7          	jalr	-1222(ra) # 80000bf4 <initlock>
  log.start = sb->logstart;
    800040c2:	0149a583          	lw	a1,20(s3)
    800040c6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040c8:	0109a783          	lw	a5,16(s3)
    800040cc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040ce:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040d2:	854a                	mv	a0,s2
    800040d4:	fffff097          	auipc	ra,0xfffff
    800040d8:	ea6080e7          	jalr	-346(ra) # 80002f7a <bread>
  log.lh.n = lh->n;
    800040dc:	4d3c                	lw	a5,88(a0)
    800040de:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040e0:	02f05563          	blez	a5,8000410a <initlog+0x74>
    800040e4:	05c50713          	addi	a4,a0,92
    800040e8:	00022697          	auipc	a3,0x22
    800040ec:	65068693          	addi	a3,a3,1616 # 80026738 <log+0x30>
    800040f0:	37fd                	addiw	a5,a5,-1
    800040f2:	1782                	slli	a5,a5,0x20
    800040f4:	9381                	srli	a5,a5,0x20
    800040f6:	078a                	slli	a5,a5,0x2
    800040f8:	06050613          	addi	a2,a0,96
    800040fc:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    800040fe:	4310                	lw	a2,0(a4)
    80004100:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004102:	0711                	addi	a4,a4,4
    80004104:	0691                	addi	a3,a3,4
    80004106:	fef71ce3          	bne	a4,a5,800040fe <initlog+0x68>
  brelse(buf);
    8000410a:	fffff097          	auipc	ra,0xfffff
    8000410e:	fa0080e7          	jalr	-96(ra) # 800030aa <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(); // if committed, copy from log to disk
    80004112:	00000097          	auipc	ra,0x0
    80004116:	ece080e7          	jalr	-306(ra) # 80003fe0 <install_trans>
  log.lh.n = 0;
    8000411a:	00022797          	auipc	a5,0x22
    8000411e:	6007ad23          	sw	zero,1562(a5) # 80026734 <log+0x2c>
  write_head(); // clear the log
    80004122:	00000097          	auipc	ra,0x0
    80004126:	e44080e7          	jalr	-444(ra) # 80003f66 <write_head>
}
    8000412a:	70a2                	ld	ra,40(sp)
    8000412c:	7402                	ld	s0,32(sp)
    8000412e:	64e2                	ld	s1,24(sp)
    80004130:	6942                	ld	s2,16(sp)
    80004132:	69a2                	ld	s3,8(sp)
    80004134:	6145                	addi	sp,sp,48
    80004136:	8082                	ret

0000000080004138 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004138:	1101                	addi	sp,sp,-32
    8000413a:	ec06                	sd	ra,24(sp)
    8000413c:	e822                	sd	s0,16(sp)
    8000413e:	e426                	sd	s1,8(sp)
    80004140:	e04a                	sd	s2,0(sp)
    80004142:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004144:	00022517          	auipc	a0,0x22
    80004148:	5c450513          	addi	a0,a0,1476 # 80026708 <log>
    8000414c:	ffffd097          	auipc	ra,0xffffd
    80004150:	b38080e7          	jalr	-1224(ra) # 80000c84 <acquire>
  while(1){
    if(log.committing){
    80004154:	00022497          	auipc	s1,0x22
    80004158:	5b448493          	addi	s1,s1,1460 # 80026708 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000415c:	4979                	li	s2,30
    8000415e:	a039                	j	8000416c <begin_op+0x34>
      sleep(&log, &log.lock);
    80004160:	85a6                	mv	a1,s1
    80004162:	8526                	mv	a0,s1
    80004164:	ffffe097          	auipc	ra,0xffffe
    80004168:	10a080e7          	jalr	266(ra) # 8000226e <sleep>
    if(log.committing){
    8000416c:	50dc                	lw	a5,36(s1)
    8000416e:	fbed                	bnez	a5,80004160 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004170:	509c                	lw	a5,32(s1)
    80004172:	0017871b          	addiw	a4,a5,1
    80004176:	0007069b          	sext.w	a3,a4
    8000417a:	0027179b          	slliw	a5,a4,0x2
    8000417e:	9fb9                	addw	a5,a5,a4
    80004180:	0017979b          	slliw	a5,a5,0x1
    80004184:	54d8                	lw	a4,44(s1)
    80004186:	9fb9                	addw	a5,a5,a4
    80004188:	00f95963          	bge	s2,a5,8000419a <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000418c:	85a6                	mv	a1,s1
    8000418e:	8526                	mv	a0,s1
    80004190:	ffffe097          	auipc	ra,0xffffe
    80004194:	0de080e7          	jalr	222(ra) # 8000226e <sleep>
    80004198:	bfd1                	j	8000416c <begin_op+0x34>
    } else {
      log.outstanding += 1;
    8000419a:	00022517          	auipc	a0,0x22
    8000419e:	56e50513          	addi	a0,a0,1390 # 80026708 <log>
    800041a2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041a4:	ffffd097          	auipc	ra,0xffffd
    800041a8:	b94080e7          	jalr	-1132(ra) # 80000d38 <release>
      break;
    }
  }
}
    800041ac:	60e2                	ld	ra,24(sp)
    800041ae:	6442                	ld	s0,16(sp)
    800041b0:	64a2                	ld	s1,8(sp)
    800041b2:	6902                	ld	s2,0(sp)
    800041b4:	6105                	addi	sp,sp,32
    800041b6:	8082                	ret

00000000800041b8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041b8:	7139                	addi	sp,sp,-64
    800041ba:	fc06                	sd	ra,56(sp)
    800041bc:	f822                	sd	s0,48(sp)
    800041be:	f426                	sd	s1,40(sp)
    800041c0:	f04a                	sd	s2,32(sp)
    800041c2:	ec4e                	sd	s3,24(sp)
    800041c4:	e852                	sd	s4,16(sp)
    800041c6:	e456                	sd	s5,8(sp)
    800041c8:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041ca:	00022497          	auipc	s1,0x22
    800041ce:	53e48493          	addi	s1,s1,1342 # 80026708 <log>
    800041d2:	8526                	mv	a0,s1
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	ab0080e7          	jalr	-1360(ra) # 80000c84 <acquire>
  log.outstanding -= 1;
    800041dc:	509c                	lw	a5,32(s1)
    800041de:	37fd                	addiw	a5,a5,-1
    800041e0:	0007891b          	sext.w	s2,a5
    800041e4:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041e6:	50dc                	lw	a5,36(s1)
    800041e8:	efb9                	bnez	a5,80004246 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041ea:	06091663          	bnez	s2,80004256 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    800041ee:	00022497          	auipc	s1,0x22
    800041f2:	51a48493          	addi	s1,s1,1306 # 80026708 <log>
    800041f6:	4785                	li	a5,1
    800041f8:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800041fa:	8526                	mv	a0,s1
    800041fc:	ffffd097          	auipc	ra,0xffffd
    80004200:	b3c080e7          	jalr	-1220(ra) # 80000d38 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004204:	54dc                	lw	a5,44(s1)
    80004206:	06f04763          	bgtz	a5,80004274 <end_op+0xbc>
    acquire(&log.lock);
    8000420a:	00022497          	auipc	s1,0x22
    8000420e:	4fe48493          	addi	s1,s1,1278 # 80026708 <log>
    80004212:	8526                	mv	a0,s1
    80004214:	ffffd097          	auipc	ra,0xffffd
    80004218:	a70080e7          	jalr	-1424(ra) # 80000c84 <acquire>
    log.committing = 0;
    8000421c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004220:	8526                	mv	a0,s1
    80004222:	ffffe097          	auipc	ra,0xffffe
    80004226:	1d2080e7          	jalr	466(ra) # 800023f4 <wakeup>
    release(&log.lock);
    8000422a:	8526                	mv	a0,s1
    8000422c:	ffffd097          	auipc	ra,0xffffd
    80004230:	b0c080e7          	jalr	-1268(ra) # 80000d38 <release>
}
    80004234:	70e2                	ld	ra,56(sp)
    80004236:	7442                	ld	s0,48(sp)
    80004238:	74a2                	ld	s1,40(sp)
    8000423a:	7902                	ld	s2,32(sp)
    8000423c:	69e2                	ld	s3,24(sp)
    8000423e:	6a42                	ld	s4,16(sp)
    80004240:	6aa2                	ld	s5,8(sp)
    80004242:	6121                	addi	sp,sp,64
    80004244:	8082                	ret
    panic("log.committing");
    80004246:	00004517          	auipc	a0,0x4
    8000424a:	3ea50513          	addi	a0,a0,1002 # 80008630 <syscalls+0x1f0>
    8000424e:	ffffc097          	auipc	ra,0xffffc
    80004252:	2fa080e7          	jalr	762(ra) # 80000548 <panic>
    wakeup(&log);
    80004256:	00022497          	auipc	s1,0x22
    8000425a:	4b248493          	addi	s1,s1,1202 # 80026708 <log>
    8000425e:	8526                	mv	a0,s1
    80004260:	ffffe097          	auipc	ra,0xffffe
    80004264:	194080e7          	jalr	404(ra) # 800023f4 <wakeup>
  release(&log.lock);
    80004268:	8526                	mv	a0,s1
    8000426a:	ffffd097          	auipc	ra,0xffffd
    8000426e:	ace080e7          	jalr	-1330(ra) # 80000d38 <release>
  if(do_commit){
    80004272:	b7c9                	j	80004234 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004274:	00022a97          	auipc	s5,0x22
    80004278:	4c4a8a93          	addi	s5,s5,1220 # 80026738 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000427c:	00022a17          	auipc	s4,0x22
    80004280:	48ca0a13          	addi	s4,s4,1164 # 80026708 <log>
    80004284:	018a2583          	lw	a1,24(s4)
    80004288:	012585bb          	addw	a1,a1,s2
    8000428c:	2585                	addiw	a1,a1,1
    8000428e:	028a2503          	lw	a0,40(s4)
    80004292:	fffff097          	auipc	ra,0xfffff
    80004296:	ce8080e7          	jalr	-792(ra) # 80002f7a <bread>
    8000429a:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    8000429c:	000aa583          	lw	a1,0(s5)
    800042a0:	028a2503          	lw	a0,40(s4)
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	cd6080e7          	jalr	-810(ra) # 80002f7a <bread>
    800042ac:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042ae:	40000613          	li	a2,1024
    800042b2:	05850593          	addi	a1,a0,88
    800042b6:	05848513          	addi	a0,s1,88
    800042ba:	ffffd097          	auipc	ra,0xffffd
    800042be:	b26080e7          	jalr	-1242(ra) # 80000de0 <memmove>
    bwrite(to);  // write the log
    800042c2:	8526                	mv	a0,s1
    800042c4:	fffff097          	auipc	ra,0xfffff
    800042c8:	da8080e7          	jalr	-600(ra) # 8000306c <bwrite>
    brelse(from);
    800042cc:	854e                	mv	a0,s3
    800042ce:	fffff097          	auipc	ra,0xfffff
    800042d2:	ddc080e7          	jalr	-548(ra) # 800030aa <brelse>
    brelse(to);
    800042d6:	8526                	mv	a0,s1
    800042d8:	fffff097          	auipc	ra,0xfffff
    800042dc:	dd2080e7          	jalr	-558(ra) # 800030aa <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042e0:	2905                	addiw	s2,s2,1
    800042e2:	0a91                	addi	s5,s5,4
    800042e4:	02ca2783          	lw	a5,44(s4)
    800042e8:	f8f94ee3          	blt	s2,a5,80004284 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042ec:	00000097          	auipc	ra,0x0
    800042f0:	c7a080e7          	jalr	-902(ra) # 80003f66 <write_head>
    install_trans(); // Now install writes to home locations
    800042f4:	00000097          	auipc	ra,0x0
    800042f8:	cec080e7          	jalr	-788(ra) # 80003fe0 <install_trans>
    log.lh.n = 0;
    800042fc:	00022797          	auipc	a5,0x22
    80004300:	4207ac23          	sw	zero,1080(a5) # 80026734 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004304:	00000097          	auipc	ra,0x0
    80004308:	c62080e7          	jalr	-926(ra) # 80003f66 <write_head>
    8000430c:	bdfd                	j	8000420a <end_op+0x52>

000000008000430e <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000430e:	1101                	addi	sp,sp,-32
    80004310:	ec06                	sd	ra,24(sp)
    80004312:	e822                	sd	s0,16(sp)
    80004314:	e426                	sd	s1,8(sp)
    80004316:	e04a                	sd	s2,0(sp)
    80004318:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    8000431a:	00022717          	auipc	a4,0x22
    8000431e:	41a72703          	lw	a4,1050(a4) # 80026734 <log+0x2c>
    80004322:	47f5                	li	a5,29
    80004324:	08e7c063          	blt	a5,a4,800043a4 <log_write+0x96>
    80004328:	84aa                	mv	s1,a0
    8000432a:	00022797          	auipc	a5,0x22
    8000432e:	3fa7a783          	lw	a5,1018(a5) # 80026724 <log+0x1c>
    80004332:	37fd                	addiw	a5,a5,-1
    80004334:	06f75863          	bge	a4,a5,800043a4 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004338:	00022797          	auipc	a5,0x22
    8000433c:	3f07a783          	lw	a5,1008(a5) # 80026728 <log+0x20>
    80004340:	06f05a63          	blez	a5,800043b4 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004344:	00022917          	auipc	s2,0x22
    80004348:	3c490913          	addi	s2,s2,964 # 80026708 <log>
    8000434c:	854a                	mv	a0,s2
    8000434e:	ffffd097          	auipc	ra,0xffffd
    80004352:	936080e7          	jalr	-1738(ra) # 80000c84 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004356:	02c92603          	lw	a2,44(s2)
    8000435a:	06c05563          	blez	a2,800043c4 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000435e:	44cc                	lw	a1,12(s1)
    80004360:	00022717          	auipc	a4,0x22
    80004364:	3d870713          	addi	a4,a4,984 # 80026738 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004368:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000436a:	4314                	lw	a3,0(a4)
    8000436c:	04b68d63          	beq	a3,a1,800043c6 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004370:	2785                	addiw	a5,a5,1
    80004372:	0711                	addi	a4,a4,4
    80004374:	fec79be3          	bne	a5,a2,8000436a <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004378:	0621                	addi	a2,a2,8
    8000437a:	060a                	slli	a2,a2,0x2
    8000437c:	00022797          	auipc	a5,0x22
    80004380:	38c78793          	addi	a5,a5,908 # 80026708 <log>
    80004384:	963e                	add	a2,a2,a5
    80004386:	44dc                	lw	a5,12(s1)
    80004388:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000438a:	8526                	mv	a0,s1
    8000438c:	fffff097          	auipc	ra,0xfffff
    80004390:	dbc080e7          	jalr	-580(ra) # 80003148 <bpin>
    log.lh.n++;
    80004394:	00022717          	auipc	a4,0x22
    80004398:	37470713          	addi	a4,a4,884 # 80026708 <log>
    8000439c:	575c                	lw	a5,44(a4)
    8000439e:	2785                	addiw	a5,a5,1
    800043a0:	d75c                	sw	a5,44(a4)
    800043a2:	a83d                	j	800043e0 <log_write+0xd2>
    panic("too big a transaction");
    800043a4:	00004517          	auipc	a0,0x4
    800043a8:	29c50513          	addi	a0,a0,668 # 80008640 <syscalls+0x200>
    800043ac:	ffffc097          	auipc	ra,0xffffc
    800043b0:	19c080e7          	jalr	412(ra) # 80000548 <panic>
    panic("log_write outside of trans");
    800043b4:	00004517          	auipc	a0,0x4
    800043b8:	2a450513          	addi	a0,a0,676 # 80008658 <syscalls+0x218>
    800043bc:	ffffc097          	auipc	ra,0xffffc
    800043c0:	18c080e7          	jalr	396(ra) # 80000548 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800043c4:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800043c6:	00878713          	addi	a4,a5,8
    800043ca:	00271693          	slli	a3,a4,0x2
    800043ce:	00022717          	auipc	a4,0x22
    800043d2:	33a70713          	addi	a4,a4,826 # 80026708 <log>
    800043d6:	9736                	add	a4,a4,a3
    800043d8:	44d4                	lw	a3,12(s1)
    800043da:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043dc:	faf607e3          	beq	a2,a5,8000438a <log_write+0x7c>
  }
  release(&log.lock);
    800043e0:	00022517          	auipc	a0,0x22
    800043e4:	32850513          	addi	a0,a0,808 # 80026708 <log>
    800043e8:	ffffd097          	auipc	ra,0xffffd
    800043ec:	950080e7          	jalr	-1712(ra) # 80000d38 <release>
}
    800043f0:	60e2                	ld	ra,24(sp)
    800043f2:	6442                	ld	s0,16(sp)
    800043f4:	64a2                	ld	s1,8(sp)
    800043f6:	6902                	ld	s2,0(sp)
    800043f8:	6105                	addi	sp,sp,32
    800043fa:	8082                	ret

00000000800043fc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800043fc:	1101                	addi	sp,sp,-32
    800043fe:	ec06                	sd	ra,24(sp)
    80004400:	e822                	sd	s0,16(sp)
    80004402:	e426                	sd	s1,8(sp)
    80004404:	e04a                	sd	s2,0(sp)
    80004406:	1000                	addi	s0,sp,32
    80004408:	84aa                	mv	s1,a0
    8000440a:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000440c:	00004597          	auipc	a1,0x4
    80004410:	26c58593          	addi	a1,a1,620 # 80008678 <syscalls+0x238>
    80004414:	0521                	addi	a0,a0,8
    80004416:	ffffc097          	auipc	ra,0xffffc
    8000441a:	7de080e7          	jalr	2014(ra) # 80000bf4 <initlock>
  lk->name = name;
    8000441e:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004422:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004426:	0204a423          	sw	zero,40(s1)
}
    8000442a:	60e2                	ld	ra,24(sp)
    8000442c:	6442                	ld	s0,16(sp)
    8000442e:	64a2                	ld	s1,8(sp)
    80004430:	6902                	ld	s2,0(sp)
    80004432:	6105                	addi	sp,sp,32
    80004434:	8082                	ret

0000000080004436 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004436:	1101                	addi	sp,sp,-32
    80004438:	ec06                	sd	ra,24(sp)
    8000443a:	e822                	sd	s0,16(sp)
    8000443c:	e426                	sd	s1,8(sp)
    8000443e:	e04a                	sd	s2,0(sp)
    80004440:	1000                	addi	s0,sp,32
    80004442:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004444:	00850913          	addi	s2,a0,8
    80004448:	854a                	mv	a0,s2
    8000444a:	ffffd097          	auipc	ra,0xffffd
    8000444e:	83a080e7          	jalr	-1990(ra) # 80000c84 <acquire>
  while (lk->locked) {
    80004452:	409c                	lw	a5,0(s1)
    80004454:	cb89                	beqz	a5,80004466 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004456:	85ca                	mv	a1,s2
    80004458:	8526                	mv	a0,s1
    8000445a:	ffffe097          	auipc	ra,0xffffe
    8000445e:	e14080e7          	jalr	-492(ra) # 8000226e <sleep>
  while (lk->locked) {
    80004462:	409c                	lw	a5,0(s1)
    80004464:	fbed                	bnez	a5,80004456 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004466:	4785                	li	a5,1
    80004468:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000446a:	ffffd097          	auipc	ra,0xffffd
    8000446e:	5e8080e7          	jalr	1512(ra) # 80001a52 <myproc>
    80004472:	5d1c                	lw	a5,56(a0)
    80004474:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004476:	854a                	mv	a0,s2
    80004478:	ffffd097          	auipc	ra,0xffffd
    8000447c:	8c0080e7          	jalr	-1856(ra) # 80000d38 <release>
}
    80004480:	60e2                	ld	ra,24(sp)
    80004482:	6442                	ld	s0,16(sp)
    80004484:	64a2                	ld	s1,8(sp)
    80004486:	6902                	ld	s2,0(sp)
    80004488:	6105                	addi	sp,sp,32
    8000448a:	8082                	ret

000000008000448c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000448c:	1101                	addi	sp,sp,-32
    8000448e:	ec06                	sd	ra,24(sp)
    80004490:	e822                	sd	s0,16(sp)
    80004492:	e426                	sd	s1,8(sp)
    80004494:	e04a                	sd	s2,0(sp)
    80004496:	1000                	addi	s0,sp,32
    80004498:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000449a:	00850913          	addi	s2,a0,8
    8000449e:	854a                	mv	a0,s2
    800044a0:	ffffc097          	auipc	ra,0xffffc
    800044a4:	7e4080e7          	jalr	2020(ra) # 80000c84 <acquire>
  lk->locked = 0;
    800044a8:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044ac:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044b0:	8526                	mv	a0,s1
    800044b2:	ffffe097          	auipc	ra,0xffffe
    800044b6:	f42080e7          	jalr	-190(ra) # 800023f4 <wakeup>
  release(&lk->lk);
    800044ba:	854a                	mv	a0,s2
    800044bc:	ffffd097          	auipc	ra,0xffffd
    800044c0:	87c080e7          	jalr	-1924(ra) # 80000d38 <release>
}
    800044c4:	60e2                	ld	ra,24(sp)
    800044c6:	6442                	ld	s0,16(sp)
    800044c8:	64a2                	ld	s1,8(sp)
    800044ca:	6902                	ld	s2,0(sp)
    800044cc:	6105                	addi	sp,sp,32
    800044ce:	8082                	ret

00000000800044d0 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044d0:	7179                	addi	sp,sp,-48
    800044d2:	f406                	sd	ra,40(sp)
    800044d4:	f022                	sd	s0,32(sp)
    800044d6:	ec26                	sd	s1,24(sp)
    800044d8:	e84a                	sd	s2,16(sp)
    800044da:	e44e                	sd	s3,8(sp)
    800044dc:	1800                	addi	s0,sp,48
    800044de:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044e0:	00850913          	addi	s2,a0,8
    800044e4:	854a                	mv	a0,s2
    800044e6:	ffffc097          	auipc	ra,0xffffc
    800044ea:	79e080e7          	jalr	1950(ra) # 80000c84 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044ee:	409c                	lw	a5,0(s1)
    800044f0:	ef99                	bnez	a5,8000450e <holdingsleep+0x3e>
    800044f2:	4481                	li	s1,0
  release(&lk->lk);
    800044f4:	854a                	mv	a0,s2
    800044f6:	ffffd097          	auipc	ra,0xffffd
    800044fa:	842080e7          	jalr	-1982(ra) # 80000d38 <release>
  return r;
}
    800044fe:	8526                	mv	a0,s1
    80004500:	70a2                	ld	ra,40(sp)
    80004502:	7402                	ld	s0,32(sp)
    80004504:	64e2                	ld	s1,24(sp)
    80004506:	6942                	ld	s2,16(sp)
    80004508:	69a2                	ld	s3,8(sp)
    8000450a:	6145                	addi	sp,sp,48
    8000450c:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000450e:	0284a983          	lw	s3,40(s1)
    80004512:	ffffd097          	auipc	ra,0xffffd
    80004516:	540080e7          	jalr	1344(ra) # 80001a52 <myproc>
    8000451a:	5d04                	lw	s1,56(a0)
    8000451c:	413484b3          	sub	s1,s1,s3
    80004520:	0014b493          	seqz	s1,s1
    80004524:	bfc1                	j	800044f4 <holdingsleep+0x24>

0000000080004526 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004526:	1141                	addi	sp,sp,-16
    80004528:	e406                	sd	ra,8(sp)
    8000452a:	e022                	sd	s0,0(sp)
    8000452c:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000452e:	00004597          	auipc	a1,0x4
    80004532:	15a58593          	addi	a1,a1,346 # 80008688 <syscalls+0x248>
    80004536:	00022517          	auipc	a0,0x22
    8000453a:	31a50513          	addi	a0,a0,794 # 80026850 <ftable>
    8000453e:	ffffc097          	auipc	ra,0xffffc
    80004542:	6b6080e7          	jalr	1718(ra) # 80000bf4 <initlock>
}
    80004546:	60a2                	ld	ra,8(sp)
    80004548:	6402                	ld	s0,0(sp)
    8000454a:	0141                	addi	sp,sp,16
    8000454c:	8082                	ret

000000008000454e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000454e:	1101                	addi	sp,sp,-32
    80004550:	ec06                	sd	ra,24(sp)
    80004552:	e822                	sd	s0,16(sp)
    80004554:	e426                	sd	s1,8(sp)
    80004556:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004558:	00022517          	auipc	a0,0x22
    8000455c:	2f850513          	addi	a0,a0,760 # 80026850 <ftable>
    80004560:	ffffc097          	auipc	ra,0xffffc
    80004564:	724080e7          	jalr	1828(ra) # 80000c84 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004568:	00022497          	auipc	s1,0x22
    8000456c:	30048493          	addi	s1,s1,768 # 80026868 <ftable+0x18>
    80004570:	00023717          	auipc	a4,0x23
    80004574:	29870713          	addi	a4,a4,664 # 80027808 <ftable+0xfb8>
    if(f->ref == 0){
    80004578:	40dc                	lw	a5,4(s1)
    8000457a:	cf99                	beqz	a5,80004598 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000457c:	02848493          	addi	s1,s1,40
    80004580:	fee49ce3          	bne	s1,a4,80004578 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004584:	00022517          	auipc	a0,0x22
    80004588:	2cc50513          	addi	a0,a0,716 # 80026850 <ftable>
    8000458c:	ffffc097          	auipc	ra,0xffffc
    80004590:	7ac080e7          	jalr	1964(ra) # 80000d38 <release>
  return 0;
    80004594:	4481                	li	s1,0
    80004596:	a819                	j	800045ac <filealloc+0x5e>
      f->ref = 1;
    80004598:	4785                	li	a5,1
    8000459a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000459c:	00022517          	auipc	a0,0x22
    800045a0:	2b450513          	addi	a0,a0,692 # 80026850 <ftable>
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	794080e7          	jalr	1940(ra) # 80000d38 <release>
}
    800045ac:	8526                	mv	a0,s1
    800045ae:	60e2                	ld	ra,24(sp)
    800045b0:	6442                	ld	s0,16(sp)
    800045b2:	64a2                	ld	s1,8(sp)
    800045b4:	6105                	addi	sp,sp,32
    800045b6:	8082                	ret

00000000800045b8 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045b8:	1101                	addi	sp,sp,-32
    800045ba:	ec06                	sd	ra,24(sp)
    800045bc:	e822                	sd	s0,16(sp)
    800045be:	e426                	sd	s1,8(sp)
    800045c0:	1000                	addi	s0,sp,32
    800045c2:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045c4:	00022517          	auipc	a0,0x22
    800045c8:	28c50513          	addi	a0,a0,652 # 80026850 <ftable>
    800045cc:	ffffc097          	auipc	ra,0xffffc
    800045d0:	6b8080e7          	jalr	1720(ra) # 80000c84 <acquire>
  if(f->ref < 1)
    800045d4:	40dc                	lw	a5,4(s1)
    800045d6:	02f05263          	blez	a5,800045fa <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045da:	2785                	addiw	a5,a5,1
    800045dc:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045de:	00022517          	auipc	a0,0x22
    800045e2:	27250513          	addi	a0,a0,626 # 80026850 <ftable>
    800045e6:	ffffc097          	auipc	ra,0xffffc
    800045ea:	752080e7          	jalr	1874(ra) # 80000d38 <release>
  return f;
}
    800045ee:	8526                	mv	a0,s1
    800045f0:	60e2                	ld	ra,24(sp)
    800045f2:	6442                	ld	s0,16(sp)
    800045f4:	64a2                	ld	s1,8(sp)
    800045f6:	6105                	addi	sp,sp,32
    800045f8:	8082                	ret
    panic("filedup");
    800045fa:	00004517          	auipc	a0,0x4
    800045fe:	09650513          	addi	a0,a0,150 # 80008690 <syscalls+0x250>
    80004602:	ffffc097          	auipc	ra,0xffffc
    80004606:	f46080e7          	jalr	-186(ra) # 80000548 <panic>

000000008000460a <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    8000460a:	7139                	addi	sp,sp,-64
    8000460c:	fc06                	sd	ra,56(sp)
    8000460e:	f822                	sd	s0,48(sp)
    80004610:	f426                	sd	s1,40(sp)
    80004612:	f04a                	sd	s2,32(sp)
    80004614:	ec4e                	sd	s3,24(sp)
    80004616:	e852                	sd	s4,16(sp)
    80004618:	e456                	sd	s5,8(sp)
    8000461a:	0080                	addi	s0,sp,64
    8000461c:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000461e:	00022517          	auipc	a0,0x22
    80004622:	23250513          	addi	a0,a0,562 # 80026850 <ftable>
    80004626:	ffffc097          	auipc	ra,0xffffc
    8000462a:	65e080e7          	jalr	1630(ra) # 80000c84 <acquire>
  if(f->ref < 1)
    8000462e:	40dc                	lw	a5,4(s1)
    80004630:	06f05163          	blez	a5,80004692 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004634:	37fd                	addiw	a5,a5,-1
    80004636:	0007871b          	sext.w	a4,a5
    8000463a:	c0dc                	sw	a5,4(s1)
    8000463c:	06e04363          	bgtz	a4,800046a2 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004640:	0004a903          	lw	s2,0(s1)
    80004644:	0094ca83          	lbu	s5,9(s1)
    80004648:	0104ba03          	ld	s4,16(s1)
    8000464c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004650:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004654:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004658:	00022517          	auipc	a0,0x22
    8000465c:	1f850513          	addi	a0,a0,504 # 80026850 <ftable>
    80004660:	ffffc097          	auipc	ra,0xffffc
    80004664:	6d8080e7          	jalr	1752(ra) # 80000d38 <release>

  if(ff.type == FD_PIPE){
    80004668:	4785                	li	a5,1
    8000466a:	04f90d63          	beq	s2,a5,800046c4 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000466e:	3979                	addiw	s2,s2,-2
    80004670:	4785                	li	a5,1
    80004672:	0527e063          	bltu	a5,s2,800046b2 <fileclose+0xa8>
    begin_op();
    80004676:	00000097          	auipc	ra,0x0
    8000467a:	ac2080e7          	jalr	-1342(ra) # 80004138 <begin_op>
    iput(ff.ip);
    8000467e:	854e                	mv	a0,s3
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	2b6080e7          	jalr	694(ra) # 80003936 <iput>
    end_op();
    80004688:	00000097          	auipc	ra,0x0
    8000468c:	b30080e7          	jalr	-1232(ra) # 800041b8 <end_op>
    80004690:	a00d                	j	800046b2 <fileclose+0xa8>
    panic("fileclose");
    80004692:	00004517          	auipc	a0,0x4
    80004696:	00650513          	addi	a0,a0,6 # 80008698 <syscalls+0x258>
    8000469a:	ffffc097          	auipc	ra,0xffffc
    8000469e:	eae080e7          	jalr	-338(ra) # 80000548 <panic>
    release(&ftable.lock);
    800046a2:	00022517          	auipc	a0,0x22
    800046a6:	1ae50513          	addi	a0,a0,430 # 80026850 <ftable>
    800046aa:	ffffc097          	auipc	ra,0xffffc
    800046ae:	68e080e7          	jalr	1678(ra) # 80000d38 <release>
  }
}
    800046b2:	70e2                	ld	ra,56(sp)
    800046b4:	7442                	ld	s0,48(sp)
    800046b6:	74a2                	ld	s1,40(sp)
    800046b8:	7902                	ld	s2,32(sp)
    800046ba:	69e2                	ld	s3,24(sp)
    800046bc:	6a42                	ld	s4,16(sp)
    800046be:	6aa2                	ld	s5,8(sp)
    800046c0:	6121                	addi	sp,sp,64
    800046c2:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046c4:	85d6                	mv	a1,s5
    800046c6:	8552                	mv	a0,s4
    800046c8:	00000097          	auipc	ra,0x0
    800046cc:	372080e7          	jalr	882(ra) # 80004a3a <pipeclose>
    800046d0:	b7cd                	j	800046b2 <fileclose+0xa8>

00000000800046d2 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046d2:	715d                	addi	sp,sp,-80
    800046d4:	e486                	sd	ra,72(sp)
    800046d6:	e0a2                	sd	s0,64(sp)
    800046d8:	fc26                	sd	s1,56(sp)
    800046da:	f84a                	sd	s2,48(sp)
    800046dc:	f44e                	sd	s3,40(sp)
    800046de:	0880                	addi	s0,sp,80
    800046e0:	84aa                	mv	s1,a0
    800046e2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	36e080e7          	jalr	878(ra) # 80001a52 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046ec:	409c                	lw	a5,0(s1)
    800046ee:	37f9                	addiw	a5,a5,-2
    800046f0:	4705                	li	a4,1
    800046f2:	04f76763          	bltu	a4,a5,80004740 <filestat+0x6e>
    800046f6:	892a                	mv	s2,a0
    ilock(f->ip);
    800046f8:	6c88                	ld	a0,24(s1)
    800046fa:	fffff097          	auipc	ra,0xfffff
    800046fe:	082080e7          	jalr	130(ra) # 8000377c <ilock>
    stati(f->ip, &st);
    80004702:	fb840593          	addi	a1,s0,-72
    80004706:	6c88                	ld	a0,24(s1)
    80004708:	fffff097          	auipc	ra,0xfffff
    8000470c:	2fe080e7          	jalr	766(ra) # 80003a06 <stati>
    iunlock(f->ip);
    80004710:	6c88                	ld	a0,24(s1)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	12c080e7          	jalr	300(ra) # 8000383e <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    8000471a:	46e1                	li	a3,24
    8000471c:	fb840613          	addi	a2,s0,-72
    80004720:	85ce                	mv	a1,s3
    80004722:	05093503          	ld	a0,80(s2)
    80004726:	ffffd097          	auipc	ra,0xffffd
    8000472a:	020080e7          	jalr	32(ra) # 80001746 <copyout>
    8000472e:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004732:	60a6                	ld	ra,72(sp)
    80004734:	6406                	ld	s0,64(sp)
    80004736:	74e2                	ld	s1,56(sp)
    80004738:	7942                	ld	s2,48(sp)
    8000473a:	79a2                	ld	s3,40(sp)
    8000473c:	6161                	addi	sp,sp,80
    8000473e:	8082                	ret
  return -1;
    80004740:	557d                	li	a0,-1
    80004742:	bfc5                	j	80004732 <filestat+0x60>

0000000080004744 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004744:	7179                	addi	sp,sp,-48
    80004746:	f406                	sd	ra,40(sp)
    80004748:	f022                	sd	s0,32(sp)
    8000474a:	ec26                	sd	s1,24(sp)
    8000474c:	e84a                	sd	s2,16(sp)
    8000474e:	e44e                	sd	s3,8(sp)
    80004750:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004752:	00854783          	lbu	a5,8(a0)
    80004756:	c3d5                	beqz	a5,800047fa <fileread+0xb6>
    80004758:	84aa                	mv	s1,a0
    8000475a:	89ae                	mv	s3,a1
    8000475c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000475e:	411c                	lw	a5,0(a0)
    80004760:	4705                	li	a4,1
    80004762:	04e78963          	beq	a5,a4,800047b4 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004766:	470d                	li	a4,3
    80004768:	04e78d63          	beq	a5,a4,800047c2 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000476c:	4709                	li	a4,2
    8000476e:	06e79e63          	bne	a5,a4,800047ea <fileread+0xa6>
    ilock(f->ip);
    80004772:	6d08                	ld	a0,24(a0)
    80004774:	fffff097          	auipc	ra,0xfffff
    80004778:	008080e7          	jalr	8(ra) # 8000377c <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000477c:	874a                	mv	a4,s2
    8000477e:	5094                	lw	a3,32(s1)
    80004780:	864e                	mv	a2,s3
    80004782:	4585                	li	a1,1
    80004784:	6c88                	ld	a0,24(s1)
    80004786:	fffff097          	auipc	ra,0xfffff
    8000478a:	2aa080e7          	jalr	682(ra) # 80003a30 <readi>
    8000478e:	892a                	mv	s2,a0
    80004790:	00a05563          	blez	a0,8000479a <fileread+0x56>
      f->off += r;
    80004794:	509c                	lw	a5,32(s1)
    80004796:	9fa9                	addw	a5,a5,a0
    80004798:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000479a:	6c88                	ld	a0,24(s1)
    8000479c:	fffff097          	auipc	ra,0xfffff
    800047a0:	0a2080e7          	jalr	162(ra) # 8000383e <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047a4:	854a                	mv	a0,s2
    800047a6:	70a2                	ld	ra,40(sp)
    800047a8:	7402                	ld	s0,32(sp)
    800047aa:	64e2                	ld	s1,24(sp)
    800047ac:	6942                	ld	s2,16(sp)
    800047ae:	69a2                	ld	s3,8(sp)
    800047b0:	6145                	addi	sp,sp,48
    800047b2:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047b4:	6908                	ld	a0,16(a0)
    800047b6:	00000097          	auipc	ra,0x0
    800047ba:	418080e7          	jalr	1048(ra) # 80004bce <piperead>
    800047be:	892a                	mv	s2,a0
    800047c0:	b7d5                	j	800047a4 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047c2:	02451783          	lh	a5,36(a0)
    800047c6:	03079693          	slli	a3,a5,0x30
    800047ca:	92c1                	srli	a3,a3,0x30
    800047cc:	4725                	li	a4,9
    800047ce:	02d76863          	bltu	a4,a3,800047fe <fileread+0xba>
    800047d2:	0792                	slli	a5,a5,0x4
    800047d4:	00022717          	auipc	a4,0x22
    800047d8:	fdc70713          	addi	a4,a4,-36 # 800267b0 <devsw>
    800047dc:	97ba                	add	a5,a5,a4
    800047de:	639c                	ld	a5,0(a5)
    800047e0:	c38d                	beqz	a5,80004802 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047e2:	4505                	li	a0,1
    800047e4:	9782                	jalr	a5
    800047e6:	892a                	mv	s2,a0
    800047e8:	bf75                	j	800047a4 <fileread+0x60>
    panic("fileread");
    800047ea:	00004517          	auipc	a0,0x4
    800047ee:	ebe50513          	addi	a0,a0,-322 # 800086a8 <syscalls+0x268>
    800047f2:	ffffc097          	auipc	ra,0xffffc
    800047f6:	d56080e7          	jalr	-682(ra) # 80000548 <panic>
    return -1;
    800047fa:	597d                	li	s2,-1
    800047fc:	b765                	j	800047a4 <fileread+0x60>
      return -1;
    800047fe:	597d                	li	s2,-1
    80004800:	b755                	j	800047a4 <fileread+0x60>
    80004802:	597d                	li	s2,-1
    80004804:	b745                	j	800047a4 <fileread+0x60>

0000000080004806 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004806:	00954783          	lbu	a5,9(a0)
    8000480a:	14078563          	beqz	a5,80004954 <filewrite+0x14e>
{
    8000480e:	715d                	addi	sp,sp,-80
    80004810:	e486                	sd	ra,72(sp)
    80004812:	e0a2                	sd	s0,64(sp)
    80004814:	fc26                	sd	s1,56(sp)
    80004816:	f84a                	sd	s2,48(sp)
    80004818:	f44e                	sd	s3,40(sp)
    8000481a:	f052                	sd	s4,32(sp)
    8000481c:	ec56                	sd	s5,24(sp)
    8000481e:	e85a                	sd	s6,16(sp)
    80004820:	e45e                	sd	s7,8(sp)
    80004822:	e062                	sd	s8,0(sp)
    80004824:	0880                	addi	s0,sp,80
    80004826:	892a                	mv	s2,a0
    80004828:	8aae                	mv	s5,a1
    8000482a:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    8000482c:	411c                	lw	a5,0(a0)
    8000482e:	4705                	li	a4,1
    80004830:	02e78263          	beq	a5,a4,80004854 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004834:	470d                	li	a4,3
    80004836:	02e78563          	beq	a5,a4,80004860 <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    8000483a:	4709                	li	a4,2
    8000483c:	10e79463          	bne	a5,a4,80004944 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004840:	0ec05e63          	blez	a2,8000493c <filewrite+0x136>
    int i = 0;
    80004844:	4981                	li	s3,0
    80004846:	6b05                	lui	s6,0x1
    80004848:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    8000484c:	6b85                	lui	s7,0x1
    8000484e:	c00b8b9b          	addiw	s7,s7,-1024
    80004852:	a851                	j	800048e6 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004854:	6908                	ld	a0,16(a0)
    80004856:	00000097          	auipc	ra,0x0
    8000485a:	254080e7          	jalr	596(ra) # 80004aaa <pipewrite>
    8000485e:	a85d                	j	80004914 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004860:	02451783          	lh	a5,36(a0)
    80004864:	03079693          	slli	a3,a5,0x30
    80004868:	92c1                	srli	a3,a3,0x30
    8000486a:	4725                	li	a4,9
    8000486c:	0ed76663          	bltu	a4,a3,80004958 <filewrite+0x152>
    80004870:	0792                	slli	a5,a5,0x4
    80004872:	00022717          	auipc	a4,0x22
    80004876:	f3e70713          	addi	a4,a4,-194 # 800267b0 <devsw>
    8000487a:	97ba                	add	a5,a5,a4
    8000487c:	679c                	ld	a5,8(a5)
    8000487e:	cff9                	beqz	a5,8000495c <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004880:	4505                	li	a0,1
    80004882:	9782                	jalr	a5
    80004884:	a841                	j	80004914 <filewrite+0x10e>
    80004886:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000488a:	00000097          	auipc	ra,0x0
    8000488e:	8ae080e7          	jalr	-1874(ra) # 80004138 <begin_op>
      ilock(f->ip);
    80004892:	01893503          	ld	a0,24(s2)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	ee6080e7          	jalr	-282(ra) # 8000377c <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    8000489e:	8762                	mv	a4,s8
    800048a0:	02092683          	lw	a3,32(s2)
    800048a4:	01598633          	add	a2,s3,s5
    800048a8:	4585                	li	a1,1
    800048aa:	01893503          	ld	a0,24(s2)
    800048ae:	fffff097          	auipc	ra,0xfffff
    800048b2:	278080e7          	jalr	632(ra) # 80003b26 <writei>
    800048b6:	84aa                	mv	s1,a0
    800048b8:	02a05f63          	blez	a0,800048f6 <filewrite+0xf0>
        f->off += r;
    800048bc:	02092783          	lw	a5,32(s2)
    800048c0:	9fa9                	addw	a5,a5,a0
    800048c2:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048c6:	01893503          	ld	a0,24(s2)
    800048ca:	fffff097          	auipc	ra,0xfffff
    800048ce:	f74080e7          	jalr	-140(ra) # 8000383e <iunlock>
      end_op();
    800048d2:	00000097          	auipc	ra,0x0
    800048d6:	8e6080e7          	jalr	-1818(ra) # 800041b8 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    800048da:	049c1963          	bne	s8,s1,8000492c <filewrite+0x126>
        panic("short filewrite");
      i += r;
    800048de:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048e2:	0349d663          	bge	s3,s4,8000490e <filewrite+0x108>
      int n1 = n - i;
    800048e6:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800048ea:	84be                	mv	s1,a5
    800048ec:	2781                	sext.w	a5,a5
    800048ee:	f8fb5ce3          	bge	s6,a5,80004886 <filewrite+0x80>
    800048f2:	84de                	mv	s1,s7
    800048f4:	bf49                	j	80004886 <filewrite+0x80>
      iunlock(f->ip);
    800048f6:	01893503          	ld	a0,24(s2)
    800048fa:	fffff097          	auipc	ra,0xfffff
    800048fe:	f44080e7          	jalr	-188(ra) # 8000383e <iunlock>
      end_op();
    80004902:	00000097          	auipc	ra,0x0
    80004906:	8b6080e7          	jalr	-1866(ra) # 800041b8 <end_op>
      if(r < 0)
    8000490a:	fc04d8e3          	bgez	s1,800048da <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    8000490e:	8552                	mv	a0,s4
    80004910:	033a1863          	bne	s4,s3,80004940 <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004914:	60a6                	ld	ra,72(sp)
    80004916:	6406                	ld	s0,64(sp)
    80004918:	74e2                	ld	s1,56(sp)
    8000491a:	7942                	ld	s2,48(sp)
    8000491c:	79a2                	ld	s3,40(sp)
    8000491e:	7a02                	ld	s4,32(sp)
    80004920:	6ae2                	ld	s5,24(sp)
    80004922:	6b42                	ld	s6,16(sp)
    80004924:	6ba2                	ld	s7,8(sp)
    80004926:	6c02                	ld	s8,0(sp)
    80004928:	6161                	addi	sp,sp,80
    8000492a:	8082                	ret
        panic("short filewrite");
    8000492c:	00004517          	auipc	a0,0x4
    80004930:	d8c50513          	addi	a0,a0,-628 # 800086b8 <syscalls+0x278>
    80004934:	ffffc097          	auipc	ra,0xffffc
    80004938:	c14080e7          	jalr	-1004(ra) # 80000548 <panic>
    int i = 0;
    8000493c:	4981                	li	s3,0
    8000493e:	bfc1                	j	8000490e <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004940:	557d                	li	a0,-1
    80004942:	bfc9                	j	80004914 <filewrite+0x10e>
    panic("filewrite");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	d8450513          	addi	a0,a0,-636 # 800086c8 <syscalls+0x288>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bfc080e7          	jalr	-1028(ra) # 80000548 <panic>
    return -1;
    80004954:	557d                	li	a0,-1
}
    80004956:	8082                	ret
      return -1;
    80004958:	557d                	li	a0,-1
    8000495a:	bf6d                	j	80004914 <filewrite+0x10e>
    8000495c:	557d                	li	a0,-1
    8000495e:	bf5d                	j	80004914 <filewrite+0x10e>

0000000080004960 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004960:	7179                	addi	sp,sp,-48
    80004962:	f406                	sd	ra,40(sp)
    80004964:	f022                	sd	s0,32(sp)
    80004966:	ec26                	sd	s1,24(sp)
    80004968:	e84a                	sd	s2,16(sp)
    8000496a:	e44e                	sd	s3,8(sp)
    8000496c:	e052                	sd	s4,0(sp)
    8000496e:	1800                	addi	s0,sp,48
    80004970:	84aa                	mv	s1,a0
    80004972:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004974:	0005b023          	sd	zero,0(a1)
    80004978:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000497c:	00000097          	auipc	ra,0x0
    80004980:	bd2080e7          	jalr	-1070(ra) # 8000454e <filealloc>
    80004984:	e088                	sd	a0,0(s1)
    80004986:	c551                	beqz	a0,80004a12 <pipealloc+0xb2>
    80004988:	00000097          	auipc	ra,0x0
    8000498c:	bc6080e7          	jalr	-1082(ra) # 8000454e <filealloc>
    80004990:	00aa3023          	sd	a0,0(s4)
    80004994:	c92d                	beqz	a0,80004a06 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004996:	ffffc097          	auipc	ra,0xffffc
    8000499a:	1fe080e7          	jalr	510(ra) # 80000b94 <kalloc>
    8000499e:	892a                	mv	s2,a0
    800049a0:	c125                	beqz	a0,80004a00 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800049a2:	4985                	li	s3,1
    800049a4:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800049a8:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800049ac:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800049b0:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800049b4:	00004597          	auipc	a1,0x4
    800049b8:	d2458593          	addi	a1,a1,-732 # 800086d8 <syscalls+0x298>
    800049bc:	ffffc097          	auipc	ra,0xffffc
    800049c0:	238080e7          	jalr	568(ra) # 80000bf4 <initlock>
  (*f0)->type = FD_PIPE;
    800049c4:	609c                	ld	a5,0(s1)
    800049c6:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ca:	609c                	ld	a5,0(s1)
    800049cc:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049d0:	609c                	ld	a5,0(s1)
    800049d2:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049d6:	609c                	ld	a5,0(s1)
    800049d8:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049dc:	000a3783          	ld	a5,0(s4)
    800049e0:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049e4:	000a3783          	ld	a5,0(s4)
    800049e8:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049ec:	000a3783          	ld	a5,0(s4)
    800049f0:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049f4:	000a3783          	ld	a5,0(s4)
    800049f8:	0127b823          	sd	s2,16(a5)
  return 0;
    800049fc:	4501                	li	a0,0
    800049fe:	a025                	j	80004a26 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004a00:	6088                	ld	a0,0(s1)
    80004a02:	e501                	bnez	a0,80004a0a <pipealloc+0xaa>
    80004a04:	a039                	j	80004a12 <pipealloc+0xb2>
    80004a06:	6088                	ld	a0,0(s1)
    80004a08:	c51d                	beqz	a0,80004a36 <pipealloc+0xd6>
    fileclose(*f0);
    80004a0a:	00000097          	auipc	ra,0x0
    80004a0e:	c00080e7          	jalr	-1024(ra) # 8000460a <fileclose>
  if(*f1)
    80004a12:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004a16:	557d                	li	a0,-1
  if(*f1)
    80004a18:	c799                	beqz	a5,80004a26 <pipealloc+0xc6>
    fileclose(*f1);
    80004a1a:	853e                	mv	a0,a5
    80004a1c:	00000097          	auipc	ra,0x0
    80004a20:	bee080e7          	jalr	-1042(ra) # 8000460a <fileclose>
  return -1;
    80004a24:	557d                	li	a0,-1
}
    80004a26:	70a2                	ld	ra,40(sp)
    80004a28:	7402                	ld	s0,32(sp)
    80004a2a:	64e2                	ld	s1,24(sp)
    80004a2c:	6942                	ld	s2,16(sp)
    80004a2e:	69a2                	ld	s3,8(sp)
    80004a30:	6a02                	ld	s4,0(sp)
    80004a32:	6145                	addi	sp,sp,48
    80004a34:	8082                	ret
  return -1;
    80004a36:	557d                	li	a0,-1
    80004a38:	b7fd                	j	80004a26 <pipealloc+0xc6>

0000000080004a3a <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a3a:	1101                	addi	sp,sp,-32
    80004a3c:	ec06                	sd	ra,24(sp)
    80004a3e:	e822                	sd	s0,16(sp)
    80004a40:	e426                	sd	s1,8(sp)
    80004a42:	e04a                	sd	s2,0(sp)
    80004a44:	1000                	addi	s0,sp,32
    80004a46:	84aa                	mv	s1,a0
    80004a48:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a4a:	ffffc097          	auipc	ra,0xffffc
    80004a4e:	23a080e7          	jalr	570(ra) # 80000c84 <acquire>
  if(writable){
    80004a52:	02090d63          	beqz	s2,80004a8c <pipeclose+0x52>
    pi->writeopen = 0;
    80004a56:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a5a:	21848513          	addi	a0,s1,536
    80004a5e:	ffffe097          	auipc	ra,0xffffe
    80004a62:	996080e7          	jalr	-1642(ra) # 800023f4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a66:	2204b783          	ld	a5,544(s1)
    80004a6a:	eb95                	bnez	a5,80004a9e <pipeclose+0x64>
    release(&pi->lock);
    80004a6c:	8526                	mv	a0,s1
    80004a6e:	ffffc097          	auipc	ra,0xffffc
    80004a72:	2ca080e7          	jalr	714(ra) # 80000d38 <release>
    kfree((char*)pi);
    80004a76:	8526                	mv	a0,s1
    80004a78:	ffffc097          	auipc	ra,0xffffc
    80004a7c:	020080e7          	jalr	32(ra) # 80000a98 <kfree>
  } else
    release(&pi->lock);
}
    80004a80:	60e2                	ld	ra,24(sp)
    80004a82:	6442                	ld	s0,16(sp)
    80004a84:	64a2                	ld	s1,8(sp)
    80004a86:	6902                	ld	s2,0(sp)
    80004a88:	6105                	addi	sp,sp,32
    80004a8a:	8082                	ret
    pi->readopen = 0;
    80004a8c:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a90:	21c48513          	addi	a0,s1,540
    80004a94:	ffffe097          	auipc	ra,0xffffe
    80004a98:	960080e7          	jalr	-1696(ra) # 800023f4 <wakeup>
    80004a9c:	b7e9                	j	80004a66 <pipeclose+0x2c>
    release(&pi->lock);
    80004a9e:	8526                	mv	a0,s1
    80004aa0:	ffffc097          	auipc	ra,0xffffc
    80004aa4:	298080e7          	jalr	664(ra) # 80000d38 <release>
}
    80004aa8:	bfe1                	j	80004a80 <pipeclose+0x46>

0000000080004aaa <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004aaa:	7119                	addi	sp,sp,-128
    80004aac:	fc86                	sd	ra,120(sp)
    80004aae:	f8a2                	sd	s0,112(sp)
    80004ab0:	f4a6                	sd	s1,104(sp)
    80004ab2:	f0ca                	sd	s2,96(sp)
    80004ab4:	ecce                	sd	s3,88(sp)
    80004ab6:	e8d2                	sd	s4,80(sp)
    80004ab8:	e4d6                	sd	s5,72(sp)
    80004aba:	e0da                	sd	s6,64(sp)
    80004abc:	fc5e                	sd	s7,56(sp)
    80004abe:	f862                	sd	s8,48(sp)
    80004ac0:	f466                	sd	s9,40(sp)
    80004ac2:	f06a                	sd	s10,32(sp)
    80004ac4:	ec6e                	sd	s11,24(sp)
    80004ac6:	0100                	addi	s0,sp,128
    80004ac8:	84aa                	mv	s1,a0
    80004aca:	8cae                	mv	s9,a1
    80004acc:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004ace:	ffffd097          	auipc	ra,0xffffd
    80004ad2:	f84080e7          	jalr	-124(ra) # 80001a52 <myproc>
    80004ad6:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004ad8:	8526                	mv	a0,s1
    80004ada:	ffffc097          	auipc	ra,0xffffc
    80004ade:	1aa080e7          	jalr	426(ra) # 80000c84 <acquire>
  for(i = 0; i < n; i++){
    80004ae2:	0d605963          	blez	s6,80004bb4 <pipewrite+0x10a>
    80004ae6:	89a6                	mv	s3,s1
    80004ae8:	3b7d                	addiw	s6,s6,-1
    80004aea:	1b02                	slli	s6,s6,0x20
    80004aec:	020b5b13          	srli	s6,s6,0x20
    80004af0:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004af2:	21848a93          	addi	s5,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004af6:	21c48a13          	addi	s4,s1,540
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004afa:	5dfd                	li	s11,-1
    80004afc:	000b8d1b          	sext.w	s10,s7
    80004b00:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b02:	2184a783          	lw	a5,536(s1)
    80004b06:	21c4a703          	lw	a4,540(s1)
    80004b0a:	2007879b          	addiw	a5,a5,512
    80004b0e:	02f71b63          	bne	a4,a5,80004b44 <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004b12:	2204a783          	lw	a5,544(s1)
    80004b16:	cbad                	beqz	a5,80004b88 <pipewrite+0xde>
    80004b18:	03092783          	lw	a5,48(s2)
    80004b1c:	e7b5                	bnez	a5,80004b88 <pipewrite+0xde>
      wakeup(&pi->nread);
    80004b1e:	8556                	mv	a0,s5
    80004b20:	ffffe097          	auipc	ra,0xffffe
    80004b24:	8d4080e7          	jalr	-1836(ra) # 800023f4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b28:	85ce                	mv	a1,s3
    80004b2a:	8552                	mv	a0,s4
    80004b2c:	ffffd097          	auipc	ra,0xffffd
    80004b30:	742080e7          	jalr	1858(ra) # 8000226e <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004b34:	2184a783          	lw	a5,536(s1)
    80004b38:	21c4a703          	lw	a4,540(s1)
    80004b3c:	2007879b          	addiw	a5,a5,512
    80004b40:	fcf709e3          	beq	a4,a5,80004b12 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b44:	4685                	li	a3,1
    80004b46:	019b8633          	add	a2,s7,s9
    80004b4a:	f8f40593          	addi	a1,s0,-113
    80004b4e:	05093503          	ld	a0,80(s2)
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	c80080e7          	jalr	-896(ra) # 800017d2 <copyin>
    80004b5a:	05b50e63          	beq	a0,s11,80004bb6 <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b5e:	21c4a783          	lw	a5,540(s1)
    80004b62:	0017871b          	addiw	a4,a5,1
    80004b66:	20e4ae23          	sw	a4,540(s1)
    80004b6a:	1ff7f793          	andi	a5,a5,511
    80004b6e:	97a6                	add	a5,a5,s1
    80004b70:	f8f44703          	lbu	a4,-113(s0)
    80004b74:	00e78c23          	sb	a4,24(a5)
  for(i = 0; i < n; i++){
    80004b78:	001d0c1b          	addiw	s8,s10,1
    80004b7c:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004b80:	036b8b63          	beq	s7,s6,80004bb6 <pipewrite+0x10c>
    80004b84:	8bbe                	mv	s7,a5
    80004b86:	bf9d                	j	80004afc <pipewrite+0x52>
        release(&pi->lock);
    80004b88:	8526                	mv	a0,s1
    80004b8a:	ffffc097          	auipc	ra,0xffffc
    80004b8e:	1ae080e7          	jalr	430(ra) # 80000d38 <release>
        return -1;
    80004b92:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004b94:	8562                	mv	a0,s8
    80004b96:	70e6                	ld	ra,120(sp)
    80004b98:	7446                	ld	s0,112(sp)
    80004b9a:	74a6                	ld	s1,104(sp)
    80004b9c:	7906                	ld	s2,96(sp)
    80004b9e:	69e6                	ld	s3,88(sp)
    80004ba0:	6a46                	ld	s4,80(sp)
    80004ba2:	6aa6                	ld	s5,72(sp)
    80004ba4:	6b06                	ld	s6,64(sp)
    80004ba6:	7be2                	ld	s7,56(sp)
    80004ba8:	7c42                	ld	s8,48(sp)
    80004baa:	7ca2                	ld	s9,40(sp)
    80004bac:	7d02                	ld	s10,32(sp)
    80004bae:	6de2                	ld	s11,24(sp)
    80004bb0:	6109                	addi	sp,sp,128
    80004bb2:	8082                	ret
  for(i = 0; i < n; i++){
    80004bb4:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004bb6:	21848513          	addi	a0,s1,536
    80004bba:	ffffe097          	auipc	ra,0xffffe
    80004bbe:	83a080e7          	jalr	-1990(ra) # 800023f4 <wakeup>
  release(&pi->lock);
    80004bc2:	8526                	mv	a0,s1
    80004bc4:	ffffc097          	auipc	ra,0xffffc
    80004bc8:	174080e7          	jalr	372(ra) # 80000d38 <release>
  return i;
    80004bcc:	b7e1                	j	80004b94 <pipewrite+0xea>

0000000080004bce <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004bce:	715d                	addi	sp,sp,-80
    80004bd0:	e486                	sd	ra,72(sp)
    80004bd2:	e0a2                	sd	s0,64(sp)
    80004bd4:	fc26                	sd	s1,56(sp)
    80004bd6:	f84a                	sd	s2,48(sp)
    80004bd8:	f44e                	sd	s3,40(sp)
    80004bda:	f052                	sd	s4,32(sp)
    80004bdc:	ec56                	sd	s5,24(sp)
    80004bde:	e85a                	sd	s6,16(sp)
    80004be0:	0880                	addi	s0,sp,80
    80004be2:	84aa                	mv	s1,a0
    80004be4:	892e                	mv	s2,a1
    80004be6:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004be8:	ffffd097          	auipc	ra,0xffffd
    80004bec:	e6a080e7          	jalr	-406(ra) # 80001a52 <myproc>
    80004bf0:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004bf2:	8b26                	mv	s6,s1
    80004bf4:	8526                	mv	a0,s1
    80004bf6:	ffffc097          	auipc	ra,0xffffc
    80004bfa:	08e080e7          	jalr	142(ra) # 80000c84 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bfe:	2184a703          	lw	a4,536(s1)
    80004c02:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c06:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c0a:	02f71463          	bne	a4,a5,80004c32 <piperead+0x64>
    80004c0e:	2244a783          	lw	a5,548(s1)
    80004c12:	c385                	beqz	a5,80004c32 <piperead+0x64>
    if(pr->killed){
    80004c14:	030a2783          	lw	a5,48(s4)
    80004c18:	ebc1                	bnez	a5,80004ca8 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004c1a:	85da                	mv	a1,s6
    80004c1c:	854e                	mv	a0,s3
    80004c1e:	ffffd097          	auipc	ra,0xffffd
    80004c22:	650080e7          	jalr	1616(ra) # 8000226e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004c26:	2184a703          	lw	a4,536(s1)
    80004c2a:	21c4a783          	lw	a5,540(s1)
    80004c2e:	fef700e3          	beq	a4,a5,80004c0e <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c32:	09505263          	blez	s5,80004cb6 <piperead+0xe8>
    80004c36:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c38:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80004c3a:	2184a783          	lw	a5,536(s1)
    80004c3e:	21c4a703          	lw	a4,540(s1)
    80004c42:	02f70d63          	beq	a4,a5,80004c7c <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c46:	0017871b          	addiw	a4,a5,1
    80004c4a:	20e4ac23          	sw	a4,536(s1)
    80004c4e:	1ff7f793          	andi	a5,a5,511
    80004c52:	97a6                	add	a5,a5,s1
    80004c54:	0187c783          	lbu	a5,24(a5)
    80004c58:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c5c:	4685                	li	a3,1
    80004c5e:	fbf40613          	addi	a2,s0,-65
    80004c62:	85ca                	mv	a1,s2
    80004c64:	050a3503          	ld	a0,80(s4)
    80004c68:	ffffd097          	auipc	ra,0xffffd
    80004c6c:	ade080e7          	jalr	-1314(ra) # 80001746 <copyout>
    80004c70:	01650663          	beq	a0,s6,80004c7c <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c74:	2985                	addiw	s3,s3,1
    80004c76:	0905                	addi	s2,s2,1
    80004c78:	fd3a91e3          	bne	s5,s3,80004c3a <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c7c:	21c48513          	addi	a0,s1,540
    80004c80:	ffffd097          	auipc	ra,0xffffd
    80004c84:	774080e7          	jalr	1908(ra) # 800023f4 <wakeup>
  release(&pi->lock);
    80004c88:	8526                	mv	a0,s1
    80004c8a:	ffffc097          	auipc	ra,0xffffc
    80004c8e:	0ae080e7          	jalr	174(ra) # 80000d38 <release>
  return i;
}
    80004c92:	854e                	mv	a0,s3
    80004c94:	60a6                	ld	ra,72(sp)
    80004c96:	6406                	ld	s0,64(sp)
    80004c98:	74e2                	ld	s1,56(sp)
    80004c9a:	7942                	ld	s2,48(sp)
    80004c9c:	79a2                	ld	s3,40(sp)
    80004c9e:	7a02                	ld	s4,32(sp)
    80004ca0:	6ae2                	ld	s5,24(sp)
    80004ca2:	6b42                	ld	s6,16(sp)
    80004ca4:	6161                	addi	sp,sp,80
    80004ca6:	8082                	ret
      release(&pi->lock);
    80004ca8:	8526                	mv	a0,s1
    80004caa:	ffffc097          	auipc	ra,0xffffc
    80004cae:	08e080e7          	jalr	142(ra) # 80000d38 <release>
      return -1;
    80004cb2:	59fd                	li	s3,-1
    80004cb4:	bff9                	j	80004c92 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004cb6:	4981                	li	s3,0
    80004cb8:	b7d1                	j	80004c7c <piperead+0xae>

0000000080004cba <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80004cba:	df010113          	addi	sp,sp,-528
    80004cbe:	20113423          	sd	ra,520(sp)
    80004cc2:	20813023          	sd	s0,512(sp)
    80004cc6:	ffa6                	sd	s1,504(sp)
    80004cc8:	fbca                	sd	s2,496(sp)
    80004cca:	f7ce                	sd	s3,488(sp)
    80004ccc:	f3d2                	sd	s4,480(sp)
    80004cce:	efd6                	sd	s5,472(sp)
    80004cd0:	ebda                	sd	s6,464(sp)
    80004cd2:	e7de                	sd	s7,456(sp)
    80004cd4:	e3e2                	sd	s8,448(sp)
    80004cd6:	ff66                	sd	s9,440(sp)
    80004cd8:	fb6a                	sd	s10,432(sp)
    80004cda:	f76e                	sd	s11,424(sp)
    80004cdc:	0c00                	addi	s0,sp,528
    80004cde:	84aa                	mv	s1,a0
    80004ce0:	dea43c23          	sd	a0,-520(s0)
    80004ce4:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004ce8:	ffffd097          	auipc	ra,0xffffd
    80004cec:	d6a080e7          	jalr	-662(ra) # 80001a52 <myproc>
    80004cf0:	892a                	mv	s2,a0

  begin_op();
    80004cf2:	fffff097          	auipc	ra,0xfffff
    80004cf6:	446080e7          	jalr	1094(ra) # 80004138 <begin_op>

  if((ip = namei(path)) == 0){
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	fffff097          	auipc	ra,0xfffff
    80004d00:	230080e7          	jalr	560(ra) # 80003f2c <namei>
    80004d04:	c92d                	beqz	a0,80004d76 <exec+0xbc>
    80004d06:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004d08:	fffff097          	auipc	ra,0xfffff
    80004d0c:	a74080e7          	jalr	-1420(ra) # 8000377c <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004d10:	04000713          	li	a4,64
    80004d14:	4681                	li	a3,0
    80004d16:	e4840613          	addi	a2,s0,-440
    80004d1a:	4581                	li	a1,0
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	fffff097          	auipc	ra,0xfffff
    80004d22:	d12080e7          	jalr	-750(ra) # 80003a30 <readi>
    80004d26:	04000793          	li	a5,64
    80004d2a:	00f51a63          	bne	a0,a5,80004d3e <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80004d2e:	e4842703          	lw	a4,-440(s0)
    80004d32:	464c47b7          	lui	a5,0x464c4
    80004d36:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d3a:	04f70463          	beq	a4,a5,80004d82 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d3e:	8526                	mv	a0,s1
    80004d40:	fffff097          	auipc	ra,0xfffff
    80004d44:	c9e080e7          	jalr	-866(ra) # 800039de <iunlockput>
    end_op();
    80004d48:	fffff097          	auipc	ra,0xfffff
    80004d4c:	470080e7          	jalr	1136(ra) # 800041b8 <end_op>
  }
  return -1;
    80004d50:	557d                	li	a0,-1
}
    80004d52:	20813083          	ld	ra,520(sp)
    80004d56:	20013403          	ld	s0,512(sp)
    80004d5a:	74fe                	ld	s1,504(sp)
    80004d5c:	795e                	ld	s2,496(sp)
    80004d5e:	79be                	ld	s3,488(sp)
    80004d60:	7a1e                	ld	s4,480(sp)
    80004d62:	6afe                	ld	s5,472(sp)
    80004d64:	6b5e                	ld	s6,464(sp)
    80004d66:	6bbe                	ld	s7,456(sp)
    80004d68:	6c1e                	ld	s8,448(sp)
    80004d6a:	7cfa                	ld	s9,440(sp)
    80004d6c:	7d5a                	ld	s10,432(sp)
    80004d6e:	7dba                	ld	s11,424(sp)
    80004d70:	21010113          	addi	sp,sp,528
    80004d74:	8082                	ret
    end_op();
    80004d76:	fffff097          	auipc	ra,0xfffff
    80004d7a:	442080e7          	jalr	1090(ra) # 800041b8 <end_op>
    return -1;
    80004d7e:	557d                	li	a0,-1
    80004d80:	bfc9                	j	80004d52 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d82:	854a                	mv	a0,s2
    80004d84:	ffffd097          	auipc	ra,0xffffd
    80004d88:	d92080e7          	jalr	-622(ra) # 80001b16 <proc_pagetable>
    80004d8c:	8baa                	mv	s7,a0
    80004d8e:	d945                	beqz	a0,80004d3e <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d90:	e6842983          	lw	s3,-408(s0)
    80004d94:	e8045783          	lhu	a5,-384(s0)
    80004d98:	c7ad                	beqz	a5,80004e02 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004d9a:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d9c:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    80004d9e:	6c85                	lui	s9,0x1
    80004da0:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80004da4:	def43823          	sd	a5,-528(s0)
    80004da8:	a42d                	j	80004fd2 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004daa:	00004517          	auipc	a0,0x4
    80004dae:	93650513          	addi	a0,a0,-1738 # 800086e0 <syscalls+0x2a0>
    80004db2:	ffffb097          	auipc	ra,0xffffb
    80004db6:	796080e7          	jalr	1942(ra) # 80000548 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004dba:	8756                	mv	a4,s5
    80004dbc:	012d86bb          	addw	a3,s11,s2
    80004dc0:	4581                	li	a1,0
    80004dc2:	8526                	mv	a0,s1
    80004dc4:	fffff097          	auipc	ra,0xfffff
    80004dc8:	c6c080e7          	jalr	-916(ra) # 80003a30 <readi>
    80004dcc:	2501                	sext.w	a0,a0
    80004dce:	1aaa9963          	bne	s5,a0,80004f80 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80004dd2:	6785                	lui	a5,0x1
    80004dd4:	0127893b          	addw	s2,a5,s2
    80004dd8:	77fd                	lui	a5,0xfffff
    80004dda:	01478a3b          	addw	s4,a5,s4
    80004dde:	1f897163          	bgeu	s2,s8,80004fc0 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80004de2:	02091593          	slli	a1,s2,0x20
    80004de6:	9181                	srli	a1,a1,0x20
    80004de8:	95ea                	add	a1,a1,s10
    80004dea:	855e                	mv	a0,s7
    80004dec:	ffffc097          	auipc	ra,0xffffc
    80004df0:	326080e7          	jalr	806(ra) # 80001112 <walkaddr>
    80004df4:	862a                	mv	a2,a0
    if(pa == 0)
    80004df6:	d955                	beqz	a0,80004daa <exec+0xf0>
      n = PGSIZE;
    80004df8:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80004dfa:	fd9a70e3          	bgeu	s4,s9,80004dba <exec+0x100>
      n = sz - i;
    80004dfe:	8ad2                	mv	s5,s4
    80004e00:	bf6d                	j	80004dba <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80004e02:	4901                	li	s2,0
  iunlockput(ip);
    80004e04:	8526                	mv	a0,s1
    80004e06:	fffff097          	auipc	ra,0xfffff
    80004e0a:	bd8080e7          	jalr	-1064(ra) # 800039de <iunlockput>
  end_op();
    80004e0e:	fffff097          	auipc	ra,0xfffff
    80004e12:	3aa080e7          	jalr	938(ra) # 800041b8 <end_op>
  p = myproc();
    80004e16:	ffffd097          	auipc	ra,0xffffd
    80004e1a:	c3c080e7          	jalr	-964(ra) # 80001a52 <myproc>
    80004e1e:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80004e20:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e24:	6785                	lui	a5,0x1
    80004e26:	17fd                	addi	a5,a5,-1
    80004e28:	993e                	add	s2,s2,a5
    80004e2a:	757d                	lui	a0,0xfffff
    80004e2c:	00a977b3          	and	a5,s2,a0
    80004e30:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e34:	6609                	lui	a2,0x2
    80004e36:	963e                	add	a2,a2,a5
    80004e38:	85be                	mv	a1,a5
    80004e3a:	855e                	mv	a0,s7
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	6ba080e7          	jalr	1722(ra) # 800014f6 <uvmalloc>
    80004e44:	8b2a                	mv	s6,a0
  ip = 0;
    80004e46:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80004e48:	12050c63          	beqz	a0,80004f80 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e4c:	75f9                	lui	a1,0xffffe
    80004e4e:	95aa                	add	a1,a1,a0
    80004e50:	855e                	mv	a0,s7
    80004e52:	ffffd097          	auipc	ra,0xffffd
    80004e56:	8c2080e7          	jalr	-1854(ra) # 80001714 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e5a:	7c7d                	lui	s8,0xfffff
    80004e5c:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80004e5e:	e0043783          	ld	a5,-512(s0)
    80004e62:	6388                	ld	a0,0(a5)
    80004e64:	c535                	beqz	a0,80004ed0 <exec+0x216>
    80004e66:	e8840993          	addi	s3,s0,-376
    80004e6a:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80004e6e:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80004e70:	ffffc097          	auipc	ra,0xffffc
    80004e74:	098080e7          	jalr	152(ra) # 80000f08 <strlen>
    80004e78:	2505                	addiw	a0,a0,1
    80004e7a:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e7e:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80004e82:	13896363          	bltu	s2,s8,80004fa8 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e86:	e0043d83          	ld	s11,-512(s0)
    80004e8a:	000dba03          	ld	s4,0(s11)
    80004e8e:	8552                	mv	a0,s4
    80004e90:	ffffc097          	auipc	ra,0xffffc
    80004e94:	078080e7          	jalr	120(ra) # 80000f08 <strlen>
    80004e98:	0015069b          	addiw	a3,a0,1
    80004e9c:	8652                	mv	a2,s4
    80004e9e:	85ca                	mv	a1,s2
    80004ea0:	855e                	mv	a0,s7
    80004ea2:	ffffd097          	auipc	ra,0xffffd
    80004ea6:	8a4080e7          	jalr	-1884(ra) # 80001746 <copyout>
    80004eaa:	10054363          	bltz	a0,80004fb0 <exec+0x2f6>
    ustack[argc] = sp;
    80004eae:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004eb2:	0485                	addi	s1,s1,1
    80004eb4:	008d8793          	addi	a5,s11,8
    80004eb8:	e0f43023          	sd	a5,-512(s0)
    80004ebc:	008db503          	ld	a0,8(s11)
    80004ec0:	c911                	beqz	a0,80004ed4 <exec+0x21a>
    if(argc >= MAXARG)
    80004ec2:	09a1                	addi	s3,s3,8
    80004ec4:	fb3c96e3          	bne	s9,s3,80004e70 <exec+0x1b6>
  sz = sz1;
    80004ec8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ecc:	4481                	li	s1,0
    80004ece:	a84d                	j	80004f80 <exec+0x2c6>
  sp = sz;
    80004ed0:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80004ed2:	4481                	li	s1,0
  ustack[argc] = 0;
    80004ed4:	00349793          	slli	a5,s1,0x3
    80004ed8:	f9040713          	addi	a4,s0,-112
    80004edc:	97ba                	add	a5,a5,a4
    80004ede:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80004ee2:	00148693          	addi	a3,s1,1
    80004ee6:	068e                	slli	a3,a3,0x3
    80004ee8:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004eec:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ef0:	01897663          	bgeu	s2,s8,80004efc <exec+0x242>
  sz = sz1;
    80004ef4:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004ef8:	4481                	li	s1,0
    80004efa:	a059                	j	80004f80 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004efc:	e8840613          	addi	a2,s0,-376
    80004f00:	85ca                	mv	a1,s2
    80004f02:	855e                	mv	a0,s7
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	842080e7          	jalr	-1982(ra) # 80001746 <copyout>
    80004f0c:	0a054663          	bltz	a0,80004fb8 <exec+0x2fe>
  p->trapframe->a1 = sp;
    80004f10:	058ab783          	ld	a5,88(s5)
    80004f14:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004f18:	df843783          	ld	a5,-520(s0)
    80004f1c:	0007c703          	lbu	a4,0(a5)
    80004f20:	cf11                	beqz	a4,80004f3c <exec+0x282>
    80004f22:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f24:	02f00693          	li	a3,47
    80004f28:	a029                	j	80004f32 <exec+0x278>
  for(last=s=path; *s; s++)
    80004f2a:	0785                	addi	a5,a5,1
    80004f2c:	fff7c703          	lbu	a4,-1(a5)
    80004f30:	c711                	beqz	a4,80004f3c <exec+0x282>
    if(*s == '/')
    80004f32:	fed71ce3          	bne	a4,a3,80004f2a <exec+0x270>
      last = s+1;
    80004f36:	def43c23          	sd	a5,-520(s0)
    80004f3a:	bfc5                	j	80004f2a <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f3c:	4641                	li	a2,16
    80004f3e:	df843583          	ld	a1,-520(s0)
    80004f42:	158a8513          	addi	a0,s5,344
    80004f46:	ffffc097          	auipc	ra,0xffffc
    80004f4a:	f90080e7          	jalr	-112(ra) # 80000ed6 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f4e:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    80004f52:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80004f56:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f5a:	058ab783          	ld	a5,88(s5)
    80004f5e:	e6043703          	ld	a4,-416(s0)
    80004f62:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f64:	058ab783          	ld	a5,88(s5)
    80004f68:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f6c:	85ea                	mv	a1,s10
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	c44080e7          	jalr	-956(ra) # 80001bb2 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f76:	0004851b          	sext.w	a0,s1
    80004f7a:	bbe1                	j	80004d52 <exec+0x98>
    80004f7c:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80004f80:	e0843583          	ld	a1,-504(s0)
    80004f84:	855e                	mv	a0,s7
    80004f86:	ffffd097          	auipc	ra,0xffffd
    80004f8a:	c2c080e7          	jalr	-980(ra) # 80001bb2 <proc_freepagetable>
  if(ip){
    80004f8e:	da0498e3          	bnez	s1,80004d3e <exec+0x84>
  return -1;
    80004f92:	557d                	li	a0,-1
    80004f94:	bb7d                	j	80004d52 <exec+0x98>
    80004f96:	e1243423          	sd	s2,-504(s0)
    80004f9a:	b7dd                	j	80004f80 <exec+0x2c6>
    80004f9c:	e1243423          	sd	s2,-504(s0)
    80004fa0:	b7c5                	j	80004f80 <exec+0x2c6>
    80004fa2:	e1243423          	sd	s2,-504(s0)
    80004fa6:	bfe9                	j	80004f80 <exec+0x2c6>
  sz = sz1;
    80004fa8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fac:	4481                	li	s1,0
    80004fae:	bfc9                	j	80004f80 <exec+0x2c6>
  sz = sz1;
    80004fb0:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fb4:	4481                	li	s1,0
    80004fb6:	b7e9                	j	80004f80 <exec+0x2c6>
  sz = sz1;
    80004fb8:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80004fbc:	4481                	li	s1,0
    80004fbe:	b7c9                	j	80004f80 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80004fc0:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fc4:	2b05                	addiw	s6,s6,1
    80004fc6:	0389899b          	addiw	s3,s3,56
    80004fca:	e8045783          	lhu	a5,-384(s0)
    80004fce:	e2fb5be3          	bge	s6,a5,80004e04 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fd2:	2981                	sext.w	s3,s3
    80004fd4:	03800713          	li	a4,56
    80004fd8:	86ce                	mv	a3,s3
    80004fda:	e1040613          	addi	a2,s0,-496
    80004fde:	4581                	li	a1,0
    80004fe0:	8526                	mv	a0,s1
    80004fe2:	fffff097          	auipc	ra,0xfffff
    80004fe6:	a4e080e7          	jalr	-1458(ra) # 80003a30 <readi>
    80004fea:	03800793          	li	a5,56
    80004fee:	f8f517e3          	bne	a0,a5,80004f7c <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80004ff2:	e1042783          	lw	a5,-496(s0)
    80004ff6:	4705                	li	a4,1
    80004ff8:	fce796e3          	bne	a5,a4,80004fc4 <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80004ffc:	e3843603          	ld	a2,-456(s0)
    80005000:	e3043783          	ld	a5,-464(s0)
    80005004:	f8f669e3          	bltu	a2,a5,80004f96 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005008:	e2043783          	ld	a5,-480(s0)
    8000500c:	963e                	add	a2,a2,a5
    8000500e:	f8f667e3          	bltu	a2,a5,80004f9c <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005012:	85ca                	mv	a1,s2
    80005014:	855e                	mv	a0,s7
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	4e0080e7          	jalr	1248(ra) # 800014f6 <uvmalloc>
    8000501e:	e0a43423          	sd	a0,-504(s0)
    80005022:	d141                	beqz	a0,80004fa2 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    80005024:	e2043d03          	ld	s10,-480(s0)
    80005028:	df043783          	ld	a5,-528(s0)
    8000502c:	00fd77b3          	and	a5,s10,a5
    80005030:	fba1                	bnez	a5,80004f80 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005032:	e1842d83          	lw	s11,-488(s0)
    80005036:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    8000503a:	f80c03e3          	beqz	s8,80004fc0 <exec+0x306>
    8000503e:	8a62                	mv	s4,s8
    80005040:	4901                	li	s2,0
    80005042:	b345                	j	80004de2 <exec+0x128>

0000000080005044 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005044:	7179                	addi	sp,sp,-48
    80005046:	f406                	sd	ra,40(sp)
    80005048:	f022                	sd	s0,32(sp)
    8000504a:	ec26                	sd	s1,24(sp)
    8000504c:	e84a                	sd	s2,16(sp)
    8000504e:	1800                	addi	s0,sp,48
    80005050:	892e                	mv	s2,a1
    80005052:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    80005054:	fdc40593          	addi	a1,s0,-36
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	b08080e7          	jalr	-1272(ra) # 80002b60 <argint>
    80005060:	04054063          	bltz	a0,800050a0 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005064:	fdc42703          	lw	a4,-36(s0)
    80005068:	47bd                	li	a5,15
    8000506a:	02e7ed63          	bltu	a5,a4,800050a4 <argfd+0x60>
    8000506e:	ffffd097          	auipc	ra,0xffffd
    80005072:	9e4080e7          	jalr	-1564(ra) # 80001a52 <myproc>
    80005076:	fdc42703          	lw	a4,-36(s0)
    8000507a:	01a70793          	addi	a5,a4,26
    8000507e:	078e                	slli	a5,a5,0x3
    80005080:	953e                	add	a0,a0,a5
    80005082:	611c                	ld	a5,0(a0)
    80005084:	c395                	beqz	a5,800050a8 <argfd+0x64>
    return -1;
  if(pfd)
    80005086:	00090463          	beqz	s2,8000508e <argfd+0x4a>
    *pfd = fd;
    8000508a:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    8000508e:	4501                	li	a0,0
  if(pf)
    80005090:	c091                	beqz	s1,80005094 <argfd+0x50>
    *pf = f;
    80005092:	e09c                	sd	a5,0(s1)
}
    80005094:	70a2                	ld	ra,40(sp)
    80005096:	7402                	ld	s0,32(sp)
    80005098:	64e2                	ld	s1,24(sp)
    8000509a:	6942                	ld	s2,16(sp)
    8000509c:	6145                	addi	sp,sp,48
    8000509e:	8082                	ret
    return -1;
    800050a0:	557d                	li	a0,-1
    800050a2:	bfcd                	j	80005094 <argfd+0x50>
    return -1;
    800050a4:	557d                	li	a0,-1
    800050a6:	b7fd                	j	80005094 <argfd+0x50>
    800050a8:	557d                	li	a0,-1
    800050aa:	b7ed                	j	80005094 <argfd+0x50>

00000000800050ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050ac:	1101                	addi	sp,sp,-32
    800050ae:	ec06                	sd	ra,24(sp)
    800050b0:	e822                	sd	s0,16(sp)
    800050b2:	e426                	sd	s1,8(sp)
    800050b4:	1000                	addi	s0,sp,32
    800050b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	99a080e7          	jalr	-1638(ra) # 80001a52 <myproc>
    800050c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c2:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd40d0>
    800050c6:	4501                	li	a0,0
    800050c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ca:	6398                	ld	a4,0(a5)
    800050cc:	cb19                	beqz	a4,800050e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050ce:	2505                	addiw	a0,a0,1
    800050d0:	07a1                	addi	a5,a5,8
    800050d2:	fed51ce3          	bne	a0,a3,800050ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d6:	557d                	li	a0,-1
}
    800050d8:	60e2                	ld	ra,24(sp)
    800050da:	6442                	ld	s0,16(sp)
    800050dc:	64a2                	ld	s1,8(sp)
    800050de:	6105                	addi	sp,sp,32
    800050e0:	8082                	ret
      p->ofile[fd] = f;
    800050e2:	01a50793          	addi	a5,a0,26
    800050e6:	078e                	slli	a5,a5,0x3
    800050e8:	963e                	add	a2,a2,a5
    800050ea:	e204                	sd	s1,0(a2)
      return fd;
    800050ec:	b7f5                	j	800050d8 <fdalloc+0x2c>

00000000800050ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ee:	715d                	addi	sp,sp,-80
    800050f0:	e486                	sd	ra,72(sp)
    800050f2:	e0a2                	sd	s0,64(sp)
    800050f4:	fc26                	sd	s1,56(sp)
    800050f6:	f84a                	sd	s2,48(sp)
    800050f8:	f44e                	sd	s3,40(sp)
    800050fa:	f052                	sd	s4,32(sp)
    800050fc:	ec56                	sd	s5,24(sp)
    800050fe:	0880                	addi	s0,sp,80
    80005100:	89ae                	mv	s3,a1
    80005102:	8ab2                	mv	s5,a2
    80005104:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005106:	fb040593          	addi	a1,s0,-80
    8000510a:	fffff097          	auipc	ra,0xfffff
    8000510e:	e40080e7          	jalr	-448(ra) # 80003f4a <nameiparent>
    80005112:	892a                	mv	s2,a0
    80005114:	12050f63          	beqz	a0,80005252 <create+0x164>
    return 0;

  ilock(dp);
    80005118:	ffffe097          	auipc	ra,0xffffe
    8000511c:	664080e7          	jalr	1636(ra) # 8000377c <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005120:	4601                	li	a2,0
    80005122:	fb040593          	addi	a1,s0,-80
    80005126:	854a                	mv	a0,s2
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	b32080e7          	jalr	-1230(ra) # 80003c5a <dirlookup>
    80005130:	84aa                	mv	s1,a0
    80005132:	c921                	beqz	a0,80005182 <create+0x94>
    iunlockput(dp);
    80005134:	854a                	mv	a0,s2
    80005136:	fffff097          	auipc	ra,0xfffff
    8000513a:	8a8080e7          	jalr	-1880(ra) # 800039de <iunlockput>
    ilock(ip);
    8000513e:	8526                	mv	a0,s1
    80005140:	ffffe097          	auipc	ra,0xffffe
    80005144:	63c080e7          	jalr	1596(ra) # 8000377c <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005148:	2981                	sext.w	s3,s3
    8000514a:	4789                	li	a5,2
    8000514c:	02f99463          	bne	s3,a5,80005174 <create+0x86>
    80005150:	0444d783          	lhu	a5,68(s1)
    80005154:	37f9                	addiw	a5,a5,-2
    80005156:	17c2                	slli	a5,a5,0x30
    80005158:	93c1                	srli	a5,a5,0x30
    8000515a:	4705                	li	a4,1
    8000515c:	00f76c63          	bltu	a4,a5,80005174 <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005160:	8526                	mv	a0,s1
    80005162:	60a6                	ld	ra,72(sp)
    80005164:	6406                	ld	s0,64(sp)
    80005166:	74e2                	ld	s1,56(sp)
    80005168:	7942                	ld	s2,48(sp)
    8000516a:	79a2                	ld	s3,40(sp)
    8000516c:	7a02                	ld	s4,32(sp)
    8000516e:	6ae2                	ld	s5,24(sp)
    80005170:	6161                	addi	sp,sp,80
    80005172:	8082                	ret
    iunlockput(ip);
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	868080e7          	jalr	-1944(ra) # 800039de <iunlockput>
    return 0;
    8000517e:	4481                	li	s1,0
    80005180:	b7c5                	j	80005160 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    80005182:	85ce                	mv	a1,s3
    80005184:	00092503          	lw	a0,0(s2)
    80005188:	ffffe097          	auipc	ra,0xffffe
    8000518c:	45c080e7          	jalr	1116(ra) # 800035e4 <ialloc>
    80005190:	84aa                	mv	s1,a0
    80005192:	c529                	beqz	a0,800051dc <create+0xee>
  ilock(ip);
    80005194:	ffffe097          	auipc	ra,0xffffe
    80005198:	5e8080e7          	jalr	1512(ra) # 8000377c <ilock>
  ip->major = major;
    8000519c:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800051a0:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800051a4:	4785                	li	a5,1
    800051a6:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800051aa:	8526                	mv	a0,s1
    800051ac:	ffffe097          	auipc	ra,0xffffe
    800051b0:	506080e7          	jalr	1286(ra) # 800036b2 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051b4:	2981                	sext.w	s3,s3
    800051b6:	4785                	li	a5,1
    800051b8:	02f98a63          	beq	s3,a5,800051ec <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800051bc:	40d0                	lw	a2,4(s1)
    800051be:	fb040593          	addi	a1,s0,-80
    800051c2:	854a                	mv	a0,s2
    800051c4:	fffff097          	auipc	ra,0xfffff
    800051c8:	ca6080e7          	jalr	-858(ra) # 80003e6a <dirlink>
    800051cc:	06054b63          	bltz	a0,80005242 <create+0x154>
  iunlockput(dp);
    800051d0:	854a                	mv	a0,s2
    800051d2:	fffff097          	auipc	ra,0xfffff
    800051d6:	80c080e7          	jalr	-2036(ra) # 800039de <iunlockput>
  return ip;
    800051da:	b759                	j	80005160 <create+0x72>
    panic("create: ialloc");
    800051dc:	00003517          	auipc	a0,0x3
    800051e0:	52450513          	addi	a0,a0,1316 # 80008700 <syscalls+0x2c0>
    800051e4:	ffffb097          	auipc	ra,0xffffb
    800051e8:	364080e7          	jalr	868(ra) # 80000548 <panic>
    dp->nlink++;  // for ".."
    800051ec:	04a95783          	lhu	a5,74(s2)
    800051f0:	2785                	addiw	a5,a5,1
    800051f2:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800051f6:	854a                	mv	a0,s2
    800051f8:	ffffe097          	auipc	ra,0xffffe
    800051fc:	4ba080e7          	jalr	1210(ra) # 800036b2 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005200:	40d0                	lw	a2,4(s1)
    80005202:	00003597          	auipc	a1,0x3
    80005206:	50e58593          	addi	a1,a1,1294 # 80008710 <syscalls+0x2d0>
    8000520a:	8526                	mv	a0,s1
    8000520c:	fffff097          	auipc	ra,0xfffff
    80005210:	c5e080e7          	jalr	-930(ra) # 80003e6a <dirlink>
    80005214:	00054f63          	bltz	a0,80005232 <create+0x144>
    80005218:	00492603          	lw	a2,4(s2)
    8000521c:	00003597          	auipc	a1,0x3
    80005220:	4fc58593          	addi	a1,a1,1276 # 80008718 <syscalls+0x2d8>
    80005224:	8526                	mv	a0,s1
    80005226:	fffff097          	auipc	ra,0xfffff
    8000522a:	c44080e7          	jalr	-956(ra) # 80003e6a <dirlink>
    8000522e:	f80557e3          	bgez	a0,800051bc <create+0xce>
      panic("create dots");
    80005232:	00003517          	auipc	a0,0x3
    80005236:	4ee50513          	addi	a0,a0,1262 # 80008720 <syscalls+0x2e0>
    8000523a:	ffffb097          	auipc	ra,0xffffb
    8000523e:	30e080e7          	jalr	782(ra) # 80000548 <panic>
    panic("create: dirlink");
    80005242:	00003517          	auipc	a0,0x3
    80005246:	4ee50513          	addi	a0,a0,1262 # 80008730 <syscalls+0x2f0>
    8000524a:	ffffb097          	auipc	ra,0xffffb
    8000524e:	2fe080e7          	jalr	766(ra) # 80000548 <panic>
    return 0;
    80005252:	84aa                	mv	s1,a0
    80005254:	b731                	j	80005160 <create+0x72>

0000000080005256 <sys_dup>:
{
    80005256:	7179                	addi	sp,sp,-48
    80005258:	f406                	sd	ra,40(sp)
    8000525a:	f022                	sd	s0,32(sp)
    8000525c:	ec26                	sd	s1,24(sp)
    8000525e:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005260:	fd840613          	addi	a2,s0,-40
    80005264:	4581                	li	a1,0
    80005266:	4501                	li	a0,0
    80005268:	00000097          	auipc	ra,0x0
    8000526c:	ddc080e7          	jalr	-548(ra) # 80005044 <argfd>
    return -1;
    80005270:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005272:	02054363          	bltz	a0,80005298 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005276:	fd843503          	ld	a0,-40(s0)
    8000527a:	00000097          	auipc	ra,0x0
    8000527e:	e32080e7          	jalr	-462(ra) # 800050ac <fdalloc>
    80005282:	84aa                	mv	s1,a0
    return -1;
    80005284:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005286:	00054963          	bltz	a0,80005298 <sys_dup+0x42>
  filedup(f);
    8000528a:	fd843503          	ld	a0,-40(s0)
    8000528e:	fffff097          	auipc	ra,0xfffff
    80005292:	32a080e7          	jalr	810(ra) # 800045b8 <filedup>
  return fd;
    80005296:	87a6                	mv	a5,s1
}
    80005298:	853e                	mv	a0,a5
    8000529a:	70a2                	ld	ra,40(sp)
    8000529c:	7402                	ld	s0,32(sp)
    8000529e:	64e2                	ld	s1,24(sp)
    800052a0:	6145                	addi	sp,sp,48
    800052a2:	8082                	ret

00000000800052a4 <sys_read>:
{
    800052a4:	7179                	addi	sp,sp,-48
    800052a6:	f406                	sd	ra,40(sp)
    800052a8:	f022                	sd	s0,32(sp)
    800052aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052ac:	fe840613          	addi	a2,s0,-24
    800052b0:	4581                	li	a1,0
    800052b2:	4501                	li	a0,0
    800052b4:	00000097          	auipc	ra,0x0
    800052b8:	d90080e7          	jalr	-624(ra) # 80005044 <argfd>
    return -1;
    800052bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052be:	04054163          	bltz	a0,80005300 <sys_read+0x5c>
    800052c2:	fe440593          	addi	a1,s0,-28
    800052c6:	4509                	li	a0,2
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	898080e7          	jalr	-1896(ra) # 80002b60 <argint>
    return -1;
    800052d0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052d2:	02054763          	bltz	a0,80005300 <sys_read+0x5c>
    800052d6:	fd840593          	addi	a1,s0,-40
    800052da:	4505                	li	a0,1
    800052dc:	ffffe097          	auipc	ra,0xffffe
    800052e0:	8a6080e7          	jalr	-1882(ra) # 80002b82 <argaddr>
    return -1;
    800052e4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800052e6:	00054d63          	bltz	a0,80005300 <sys_read+0x5c>
  return fileread(f, p, n);
    800052ea:	fe442603          	lw	a2,-28(s0)
    800052ee:	fd843583          	ld	a1,-40(s0)
    800052f2:	fe843503          	ld	a0,-24(s0)
    800052f6:	fffff097          	auipc	ra,0xfffff
    800052fa:	44e080e7          	jalr	1102(ra) # 80004744 <fileread>
    800052fe:	87aa                	mv	a5,a0
}
    80005300:	853e                	mv	a0,a5
    80005302:	70a2                	ld	ra,40(sp)
    80005304:	7402                	ld	s0,32(sp)
    80005306:	6145                	addi	sp,sp,48
    80005308:	8082                	ret

000000008000530a <sys_write>:
{
    8000530a:	7179                	addi	sp,sp,-48
    8000530c:	f406                	sd	ra,40(sp)
    8000530e:	f022                	sd	s0,32(sp)
    80005310:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005312:	fe840613          	addi	a2,s0,-24
    80005316:	4581                	li	a1,0
    80005318:	4501                	li	a0,0
    8000531a:	00000097          	auipc	ra,0x0
    8000531e:	d2a080e7          	jalr	-726(ra) # 80005044 <argfd>
    return -1;
    80005322:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005324:	04054163          	bltz	a0,80005366 <sys_write+0x5c>
    80005328:	fe440593          	addi	a1,s0,-28
    8000532c:	4509                	li	a0,2
    8000532e:	ffffe097          	auipc	ra,0xffffe
    80005332:	832080e7          	jalr	-1998(ra) # 80002b60 <argint>
    return -1;
    80005336:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005338:	02054763          	bltz	a0,80005366 <sys_write+0x5c>
    8000533c:	fd840593          	addi	a1,s0,-40
    80005340:	4505                	li	a0,1
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	840080e7          	jalr	-1984(ra) # 80002b82 <argaddr>
    return -1;
    8000534a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000534c:	00054d63          	bltz	a0,80005366 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005350:	fe442603          	lw	a2,-28(s0)
    80005354:	fd843583          	ld	a1,-40(s0)
    80005358:	fe843503          	ld	a0,-24(s0)
    8000535c:	fffff097          	auipc	ra,0xfffff
    80005360:	4aa080e7          	jalr	1194(ra) # 80004806 <filewrite>
    80005364:	87aa                	mv	a5,a0
}
    80005366:	853e                	mv	a0,a5
    80005368:	70a2                	ld	ra,40(sp)
    8000536a:	7402                	ld	s0,32(sp)
    8000536c:	6145                	addi	sp,sp,48
    8000536e:	8082                	ret

0000000080005370 <sys_close>:
{
    80005370:	1101                	addi	sp,sp,-32
    80005372:	ec06                	sd	ra,24(sp)
    80005374:	e822                	sd	s0,16(sp)
    80005376:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005378:	fe040613          	addi	a2,s0,-32
    8000537c:	fec40593          	addi	a1,s0,-20
    80005380:	4501                	li	a0,0
    80005382:	00000097          	auipc	ra,0x0
    80005386:	cc2080e7          	jalr	-830(ra) # 80005044 <argfd>
    return -1;
    8000538a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000538c:	02054463          	bltz	a0,800053b4 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005390:	ffffc097          	auipc	ra,0xffffc
    80005394:	6c2080e7          	jalr	1730(ra) # 80001a52 <myproc>
    80005398:	fec42783          	lw	a5,-20(s0)
    8000539c:	07e9                	addi	a5,a5,26
    8000539e:	078e                	slli	a5,a5,0x3
    800053a0:	97aa                	add	a5,a5,a0
    800053a2:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    800053a6:	fe043503          	ld	a0,-32(s0)
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	260080e7          	jalr	608(ra) # 8000460a <fileclose>
  return 0;
    800053b2:	4781                	li	a5,0
}
    800053b4:	853e                	mv	a0,a5
    800053b6:	60e2                	ld	ra,24(sp)
    800053b8:	6442                	ld	s0,16(sp)
    800053ba:	6105                	addi	sp,sp,32
    800053bc:	8082                	ret

00000000800053be <sys_fstat>:
{
    800053be:	1101                	addi	sp,sp,-32
    800053c0:	ec06                	sd	ra,24(sp)
    800053c2:	e822                	sd	s0,16(sp)
    800053c4:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053c6:	fe840613          	addi	a2,s0,-24
    800053ca:	4581                	li	a1,0
    800053cc:	4501                	li	a0,0
    800053ce:	00000097          	auipc	ra,0x0
    800053d2:	c76080e7          	jalr	-906(ra) # 80005044 <argfd>
    return -1;
    800053d6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053d8:	02054563          	bltz	a0,80005402 <sys_fstat+0x44>
    800053dc:	fe040593          	addi	a1,s0,-32
    800053e0:	4505                	li	a0,1
    800053e2:	ffffd097          	auipc	ra,0xffffd
    800053e6:	7a0080e7          	jalr	1952(ra) # 80002b82 <argaddr>
    return -1;
    800053ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800053ec:	00054b63          	bltz	a0,80005402 <sys_fstat+0x44>
  return filestat(f, st);
    800053f0:	fe043583          	ld	a1,-32(s0)
    800053f4:	fe843503          	ld	a0,-24(s0)
    800053f8:	fffff097          	auipc	ra,0xfffff
    800053fc:	2da080e7          	jalr	730(ra) # 800046d2 <filestat>
    80005400:	87aa                	mv	a5,a0
}
    80005402:	853e                	mv	a0,a5
    80005404:	60e2                	ld	ra,24(sp)
    80005406:	6442                	ld	s0,16(sp)
    80005408:	6105                	addi	sp,sp,32
    8000540a:	8082                	ret

000000008000540c <sys_link>:
{
    8000540c:	7169                	addi	sp,sp,-304
    8000540e:	f606                	sd	ra,296(sp)
    80005410:	f222                	sd	s0,288(sp)
    80005412:	ee26                	sd	s1,280(sp)
    80005414:	ea4a                	sd	s2,272(sp)
    80005416:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005418:	08000613          	li	a2,128
    8000541c:	ed040593          	addi	a1,s0,-304
    80005420:	4501                	li	a0,0
    80005422:	ffffd097          	auipc	ra,0xffffd
    80005426:	782080e7          	jalr	1922(ra) # 80002ba4 <argstr>
    return -1;
    8000542a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542c:	10054e63          	bltz	a0,80005548 <sys_link+0x13c>
    80005430:	08000613          	li	a2,128
    80005434:	f5040593          	addi	a1,s0,-176
    80005438:	4505                	li	a0,1
    8000543a:	ffffd097          	auipc	ra,0xffffd
    8000543e:	76a080e7          	jalr	1898(ra) # 80002ba4 <argstr>
    return -1;
    80005442:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005444:	10054263          	bltz	a0,80005548 <sys_link+0x13c>
  begin_op();
    80005448:	fffff097          	auipc	ra,0xfffff
    8000544c:	cf0080e7          	jalr	-784(ra) # 80004138 <begin_op>
  if((ip = namei(old)) == 0){
    80005450:	ed040513          	addi	a0,s0,-304
    80005454:	fffff097          	auipc	ra,0xfffff
    80005458:	ad8080e7          	jalr	-1320(ra) # 80003f2c <namei>
    8000545c:	84aa                	mv	s1,a0
    8000545e:	c551                	beqz	a0,800054ea <sys_link+0xde>
  ilock(ip);
    80005460:	ffffe097          	auipc	ra,0xffffe
    80005464:	31c080e7          	jalr	796(ra) # 8000377c <ilock>
  if(ip->type == T_DIR){
    80005468:	04449703          	lh	a4,68(s1)
    8000546c:	4785                	li	a5,1
    8000546e:	08f70463          	beq	a4,a5,800054f6 <sys_link+0xea>
  ip->nlink++;
    80005472:	04a4d783          	lhu	a5,74(s1)
    80005476:	2785                	addiw	a5,a5,1
    80005478:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547c:	8526                	mv	a0,s1
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	234080e7          	jalr	564(ra) # 800036b2 <iupdate>
  iunlock(ip);
    80005486:	8526                	mv	a0,s1
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	3b6080e7          	jalr	950(ra) # 8000383e <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005490:	fd040593          	addi	a1,s0,-48
    80005494:	f5040513          	addi	a0,s0,-176
    80005498:	fffff097          	auipc	ra,0xfffff
    8000549c:	ab2080e7          	jalr	-1358(ra) # 80003f4a <nameiparent>
    800054a0:	892a                	mv	s2,a0
    800054a2:	c935                	beqz	a0,80005516 <sys_link+0x10a>
  ilock(dp);
    800054a4:	ffffe097          	auipc	ra,0xffffe
    800054a8:	2d8080e7          	jalr	728(ra) # 8000377c <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ac:	00092703          	lw	a4,0(s2)
    800054b0:	409c                	lw	a5,0(s1)
    800054b2:	04f71d63          	bne	a4,a5,8000550c <sys_link+0x100>
    800054b6:	40d0                	lw	a2,4(s1)
    800054b8:	fd040593          	addi	a1,s0,-48
    800054bc:	854a                	mv	a0,s2
    800054be:	fffff097          	auipc	ra,0xfffff
    800054c2:	9ac080e7          	jalr	-1620(ra) # 80003e6a <dirlink>
    800054c6:	04054363          	bltz	a0,8000550c <sys_link+0x100>
  iunlockput(dp);
    800054ca:	854a                	mv	a0,s2
    800054cc:	ffffe097          	auipc	ra,0xffffe
    800054d0:	512080e7          	jalr	1298(ra) # 800039de <iunlockput>
  iput(ip);
    800054d4:	8526                	mv	a0,s1
    800054d6:	ffffe097          	auipc	ra,0xffffe
    800054da:	460080e7          	jalr	1120(ra) # 80003936 <iput>
  end_op();
    800054de:	fffff097          	auipc	ra,0xfffff
    800054e2:	cda080e7          	jalr	-806(ra) # 800041b8 <end_op>
  return 0;
    800054e6:	4781                	li	a5,0
    800054e8:	a085                	j	80005548 <sys_link+0x13c>
    end_op();
    800054ea:	fffff097          	auipc	ra,0xfffff
    800054ee:	cce080e7          	jalr	-818(ra) # 800041b8 <end_op>
    return -1;
    800054f2:	57fd                	li	a5,-1
    800054f4:	a891                	j	80005548 <sys_link+0x13c>
    iunlockput(ip);
    800054f6:	8526                	mv	a0,s1
    800054f8:	ffffe097          	auipc	ra,0xffffe
    800054fc:	4e6080e7          	jalr	1254(ra) # 800039de <iunlockput>
    end_op();
    80005500:	fffff097          	auipc	ra,0xfffff
    80005504:	cb8080e7          	jalr	-840(ra) # 800041b8 <end_op>
    return -1;
    80005508:	57fd                	li	a5,-1
    8000550a:	a83d                	j	80005548 <sys_link+0x13c>
    iunlockput(dp);
    8000550c:	854a                	mv	a0,s2
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	4d0080e7          	jalr	1232(ra) # 800039de <iunlockput>
  ilock(ip);
    80005516:	8526                	mv	a0,s1
    80005518:	ffffe097          	auipc	ra,0xffffe
    8000551c:	264080e7          	jalr	612(ra) # 8000377c <ilock>
  ip->nlink--;
    80005520:	04a4d783          	lhu	a5,74(s1)
    80005524:	37fd                	addiw	a5,a5,-1
    80005526:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552a:	8526                	mv	a0,s1
    8000552c:	ffffe097          	auipc	ra,0xffffe
    80005530:	186080e7          	jalr	390(ra) # 800036b2 <iupdate>
  iunlockput(ip);
    80005534:	8526                	mv	a0,s1
    80005536:	ffffe097          	auipc	ra,0xffffe
    8000553a:	4a8080e7          	jalr	1192(ra) # 800039de <iunlockput>
  end_op();
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	c7a080e7          	jalr	-902(ra) # 800041b8 <end_op>
  return -1;
    80005546:	57fd                	li	a5,-1
}
    80005548:	853e                	mv	a0,a5
    8000554a:	70b2                	ld	ra,296(sp)
    8000554c:	7412                	ld	s0,288(sp)
    8000554e:	64f2                	ld	s1,280(sp)
    80005550:	6952                	ld	s2,272(sp)
    80005552:	6155                	addi	sp,sp,304
    80005554:	8082                	ret

0000000080005556 <sys_unlink>:
{
    80005556:	7151                	addi	sp,sp,-240
    80005558:	f586                	sd	ra,232(sp)
    8000555a:	f1a2                	sd	s0,224(sp)
    8000555c:	eda6                	sd	s1,216(sp)
    8000555e:	e9ca                	sd	s2,208(sp)
    80005560:	e5ce                	sd	s3,200(sp)
    80005562:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005564:	08000613          	li	a2,128
    80005568:	f3040593          	addi	a1,s0,-208
    8000556c:	4501                	li	a0,0
    8000556e:	ffffd097          	auipc	ra,0xffffd
    80005572:	636080e7          	jalr	1590(ra) # 80002ba4 <argstr>
    80005576:	18054163          	bltz	a0,800056f8 <sys_unlink+0x1a2>
  begin_op();
    8000557a:	fffff097          	auipc	ra,0xfffff
    8000557e:	bbe080e7          	jalr	-1090(ra) # 80004138 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005582:	fb040593          	addi	a1,s0,-80
    80005586:	f3040513          	addi	a0,s0,-208
    8000558a:	fffff097          	auipc	ra,0xfffff
    8000558e:	9c0080e7          	jalr	-1600(ra) # 80003f4a <nameiparent>
    80005592:	84aa                	mv	s1,a0
    80005594:	c979                	beqz	a0,8000566a <sys_unlink+0x114>
  ilock(dp);
    80005596:	ffffe097          	auipc	ra,0xffffe
    8000559a:	1e6080e7          	jalr	486(ra) # 8000377c <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    8000559e:	00003597          	auipc	a1,0x3
    800055a2:	17258593          	addi	a1,a1,370 # 80008710 <syscalls+0x2d0>
    800055a6:	fb040513          	addi	a0,s0,-80
    800055aa:	ffffe097          	auipc	ra,0xffffe
    800055ae:	696080e7          	jalr	1686(ra) # 80003c40 <namecmp>
    800055b2:	14050a63          	beqz	a0,80005706 <sys_unlink+0x1b0>
    800055b6:	00003597          	auipc	a1,0x3
    800055ba:	16258593          	addi	a1,a1,354 # 80008718 <syscalls+0x2d8>
    800055be:	fb040513          	addi	a0,s0,-80
    800055c2:	ffffe097          	auipc	ra,0xffffe
    800055c6:	67e080e7          	jalr	1662(ra) # 80003c40 <namecmp>
    800055ca:	12050e63          	beqz	a0,80005706 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055ce:	f2c40613          	addi	a2,s0,-212
    800055d2:	fb040593          	addi	a1,s0,-80
    800055d6:	8526                	mv	a0,s1
    800055d8:	ffffe097          	auipc	ra,0xffffe
    800055dc:	682080e7          	jalr	1666(ra) # 80003c5a <dirlookup>
    800055e0:	892a                	mv	s2,a0
    800055e2:	12050263          	beqz	a0,80005706 <sys_unlink+0x1b0>
  ilock(ip);
    800055e6:	ffffe097          	auipc	ra,0xffffe
    800055ea:	196080e7          	jalr	406(ra) # 8000377c <ilock>
  if(ip->nlink < 1)
    800055ee:	04a91783          	lh	a5,74(s2)
    800055f2:	08f05263          	blez	a5,80005676 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f6:	04491703          	lh	a4,68(s2)
    800055fa:	4785                	li	a5,1
    800055fc:	08f70563          	beq	a4,a5,80005686 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005600:	4641                	li	a2,16
    80005602:	4581                	li	a1,0
    80005604:	fc040513          	addi	a0,s0,-64
    80005608:	ffffb097          	auipc	ra,0xffffb
    8000560c:	778080e7          	jalr	1912(ra) # 80000d80 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005610:	4741                	li	a4,16
    80005612:	f2c42683          	lw	a3,-212(s0)
    80005616:	fc040613          	addi	a2,s0,-64
    8000561a:	4581                	li	a1,0
    8000561c:	8526                	mv	a0,s1
    8000561e:	ffffe097          	auipc	ra,0xffffe
    80005622:	508080e7          	jalr	1288(ra) # 80003b26 <writei>
    80005626:	47c1                	li	a5,16
    80005628:	0af51563          	bne	a0,a5,800056d2 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000562c:	04491703          	lh	a4,68(s2)
    80005630:	4785                	li	a5,1
    80005632:	0af70863          	beq	a4,a5,800056e2 <sys_unlink+0x18c>
  iunlockput(dp);
    80005636:	8526                	mv	a0,s1
    80005638:	ffffe097          	auipc	ra,0xffffe
    8000563c:	3a6080e7          	jalr	934(ra) # 800039de <iunlockput>
  ip->nlink--;
    80005640:	04a95783          	lhu	a5,74(s2)
    80005644:	37fd                	addiw	a5,a5,-1
    80005646:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564a:	854a                	mv	a0,s2
    8000564c:	ffffe097          	auipc	ra,0xffffe
    80005650:	066080e7          	jalr	102(ra) # 800036b2 <iupdate>
  iunlockput(ip);
    80005654:	854a                	mv	a0,s2
    80005656:	ffffe097          	auipc	ra,0xffffe
    8000565a:	388080e7          	jalr	904(ra) # 800039de <iunlockput>
  end_op();
    8000565e:	fffff097          	auipc	ra,0xfffff
    80005662:	b5a080e7          	jalr	-1190(ra) # 800041b8 <end_op>
  return 0;
    80005666:	4501                	li	a0,0
    80005668:	a84d                	j	8000571a <sys_unlink+0x1c4>
    end_op();
    8000566a:	fffff097          	auipc	ra,0xfffff
    8000566e:	b4e080e7          	jalr	-1202(ra) # 800041b8 <end_op>
    return -1;
    80005672:	557d                	li	a0,-1
    80005674:	a05d                	j	8000571a <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005676:	00003517          	auipc	a0,0x3
    8000567a:	0ca50513          	addi	a0,a0,202 # 80008740 <syscalls+0x300>
    8000567e:	ffffb097          	auipc	ra,0xffffb
    80005682:	eca080e7          	jalr	-310(ra) # 80000548 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005686:	04c92703          	lw	a4,76(s2)
    8000568a:	02000793          	li	a5,32
    8000568e:	f6e7f9e3          	bgeu	a5,a4,80005600 <sys_unlink+0xaa>
    80005692:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005696:	4741                	li	a4,16
    80005698:	86ce                	mv	a3,s3
    8000569a:	f1840613          	addi	a2,s0,-232
    8000569e:	4581                	li	a1,0
    800056a0:	854a                	mv	a0,s2
    800056a2:	ffffe097          	auipc	ra,0xffffe
    800056a6:	38e080e7          	jalr	910(ra) # 80003a30 <readi>
    800056aa:	47c1                	li	a5,16
    800056ac:	00f51b63          	bne	a0,a5,800056c2 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b0:	f1845783          	lhu	a5,-232(s0)
    800056b4:	e7a1                	bnez	a5,800056fc <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b6:	29c1                	addiw	s3,s3,16
    800056b8:	04c92783          	lw	a5,76(s2)
    800056bc:	fcf9ede3          	bltu	s3,a5,80005696 <sys_unlink+0x140>
    800056c0:	b781                	j	80005600 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c2:	00003517          	auipc	a0,0x3
    800056c6:	09650513          	addi	a0,a0,150 # 80008758 <syscalls+0x318>
    800056ca:	ffffb097          	auipc	ra,0xffffb
    800056ce:	e7e080e7          	jalr	-386(ra) # 80000548 <panic>
    panic("unlink: writei");
    800056d2:	00003517          	auipc	a0,0x3
    800056d6:	09e50513          	addi	a0,a0,158 # 80008770 <syscalls+0x330>
    800056da:	ffffb097          	auipc	ra,0xffffb
    800056de:	e6e080e7          	jalr	-402(ra) # 80000548 <panic>
    dp->nlink--;
    800056e2:	04a4d783          	lhu	a5,74(s1)
    800056e6:	37fd                	addiw	a5,a5,-1
    800056e8:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ec:	8526                	mv	a0,s1
    800056ee:	ffffe097          	auipc	ra,0xffffe
    800056f2:	fc4080e7          	jalr	-60(ra) # 800036b2 <iupdate>
    800056f6:	b781                	j	80005636 <sys_unlink+0xe0>
    return -1;
    800056f8:	557d                	li	a0,-1
    800056fa:	a005                	j	8000571a <sys_unlink+0x1c4>
    iunlockput(ip);
    800056fc:	854a                	mv	a0,s2
    800056fe:	ffffe097          	auipc	ra,0xffffe
    80005702:	2e0080e7          	jalr	736(ra) # 800039de <iunlockput>
  iunlockput(dp);
    80005706:	8526                	mv	a0,s1
    80005708:	ffffe097          	auipc	ra,0xffffe
    8000570c:	2d6080e7          	jalr	726(ra) # 800039de <iunlockput>
  end_op();
    80005710:	fffff097          	auipc	ra,0xfffff
    80005714:	aa8080e7          	jalr	-1368(ra) # 800041b8 <end_op>
  return -1;
    80005718:	557d                	li	a0,-1
}
    8000571a:	70ae                	ld	ra,232(sp)
    8000571c:	740e                	ld	s0,224(sp)
    8000571e:	64ee                	ld	s1,216(sp)
    80005720:	694e                	ld	s2,208(sp)
    80005722:	69ae                	ld	s3,200(sp)
    80005724:	616d                	addi	sp,sp,240
    80005726:	8082                	ret

0000000080005728 <sys_open>:

uint64
sys_open(void)
{
    80005728:	7131                	addi	sp,sp,-192
    8000572a:	fd06                	sd	ra,184(sp)
    8000572c:	f922                	sd	s0,176(sp)
    8000572e:	f526                	sd	s1,168(sp)
    80005730:	f14a                	sd	s2,160(sp)
    80005732:	ed4e                	sd	s3,152(sp)
    80005734:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005736:	08000613          	li	a2,128
    8000573a:	f5040593          	addi	a1,s0,-176
    8000573e:	4501                	li	a0,0
    80005740:	ffffd097          	auipc	ra,0xffffd
    80005744:	464080e7          	jalr	1124(ra) # 80002ba4 <argstr>
    return -1;
    80005748:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    8000574a:	0c054163          	bltz	a0,8000580c <sys_open+0xe4>
    8000574e:	f4c40593          	addi	a1,s0,-180
    80005752:	4505                	li	a0,1
    80005754:	ffffd097          	auipc	ra,0xffffd
    80005758:	40c080e7          	jalr	1036(ra) # 80002b60 <argint>
    8000575c:	0a054863          	bltz	a0,8000580c <sys_open+0xe4>

  begin_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	9d8080e7          	jalr	-1576(ra) # 80004138 <begin_op>

  if(omode & O_CREATE){
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	2007f793          	andi	a5,a5,512
    80005770:	cbdd                	beqz	a5,80005826 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005772:	4681                	li	a3,0
    80005774:	4601                	li	a2,0
    80005776:	4589                	li	a1,2
    80005778:	f5040513          	addi	a0,s0,-176
    8000577c:	00000097          	auipc	ra,0x0
    80005780:	972080e7          	jalr	-1678(ra) # 800050ee <create>
    80005784:	892a                	mv	s2,a0
    if(ip == 0){
    80005786:	c959                	beqz	a0,8000581c <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005788:	04491703          	lh	a4,68(s2)
    8000578c:	478d                	li	a5,3
    8000578e:	00f71763          	bne	a4,a5,8000579c <sys_open+0x74>
    80005792:	04695703          	lhu	a4,70(s2)
    80005796:	47a5                	li	a5,9
    80005798:	0ce7ec63          	bltu	a5,a4,80005870 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	db2080e7          	jalr	-590(ra) # 8000454e <filealloc>
    800057a4:	89aa                	mv	s3,a0
    800057a6:	10050263          	beqz	a0,800058aa <sys_open+0x182>
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	902080e7          	jalr	-1790(ra) # 800050ac <fdalloc>
    800057b2:	84aa                	mv	s1,a0
    800057b4:	0e054663          	bltz	a0,800058a0 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b8:	04491703          	lh	a4,68(s2)
    800057bc:	478d                	li	a5,3
    800057be:	0cf70463          	beq	a4,a5,80005886 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c2:	4789                	li	a5,2
    800057c4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057cc:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d0:	f4c42783          	lw	a5,-180(s0)
    800057d4:	0017c713          	xori	a4,a5,1
    800057d8:	8b05                	andi	a4,a4,1
    800057da:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057de:	0037f713          	andi	a4,a5,3
    800057e2:	00e03733          	snez	a4,a4
    800057e6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ea:	4007f793          	andi	a5,a5,1024
    800057ee:	c791                	beqz	a5,800057fa <sys_open+0xd2>
    800057f0:	04491703          	lh	a4,68(s2)
    800057f4:	4789                	li	a5,2
    800057f6:	08f70f63          	beq	a4,a5,80005894 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057fa:	854a                	mv	a0,s2
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	042080e7          	jalr	66(ra) # 8000383e <iunlock>
  end_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	9b4080e7          	jalr	-1612(ra) # 800041b8 <end_op>

  return fd;
}
    8000580c:	8526                	mv	a0,s1
    8000580e:	70ea                	ld	ra,184(sp)
    80005810:	744a                	ld	s0,176(sp)
    80005812:	74aa                	ld	s1,168(sp)
    80005814:	790a                	ld	s2,160(sp)
    80005816:	69ea                	ld	s3,152(sp)
    80005818:	6129                	addi	sp,sp,192
    8000581a:	8082                	ret
      end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	99c080e7          	jalr	-1636(ra) # 800041b8 <end_op>
      return -1;
    80005824:	b7e5                	j	8000580c <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005826:	f5040513          	addi	a0,s0,-176
    8000582a:	ffffe097          	auipc	ra,0xffffe
    8000582e:	702080e7          	jalr	1794(ra) # 80003f2c <namei>
    80005832:	892a                	mv	s2,a0
    80005834:	c905                	beqz	a0,80005864 <sys_open+0x13c>
    ilock(ip);
    80005836:	ffffe097          	auipc	ra,0xffffe
    8000583a:	f46080e7          	jalr	-186(ra) # 8000377c <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    8000583e:	04491703          	lh	a4,68(s2)
    80005842:	4785                	li	a5,1
    80005844:	f4f712e3          	bne	a4,a5,80005788 <sys_open+0x60>
    80005848:	f4c42783          	lw	a5,-180(s0)
    8000584c:	dba1                	beqz	a5,8000579c <sys_open+0x74>
      iunlockput(ip);
    8000584e:	854a                	mv	a0,s2
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	18e080e7          	jalr	398(ra) # 800039de <iunlockput>
      end_op();
    80005858:	fffff097          	auipc	ra,0xfffff
    8000585c:	960080e7          	jalr	-1696(ra) # 800041b8 <end_op>
      return -1;
    80005860:	54fd                	li	s1,-1
    80005862:	b76d                	j	8000580c <sys_open+0xe4>
      end_op();
    80005864:	fffff097          	auipc	ra,0xfffff
    80005868:	954080e7          	jalr	-1708(ra) # 800041b8 <end_op>
      return -1;
    8000586c:	54fd                	li	s1,-1
    8000586e:	bf79                	j	8000580c <sys_open+0xe4>
    iunlockput(ip);
    80005870:	854a                	mv	a0,s2
    80005872:	ffffe097          	auipc	ra,0xffffe
    80005876:	16c080e7          	jalr	364(ra) # 800039de <iunlockput>
    end_op();
    8000587a:	fffff097          	auipc	ra,0xfffff
    8000587e:	93e080e7          	jalr	-1730(ra) # 800041b8 <end_op>
    return -1;
    80005882:	54fd                	li	s1,-1
    80005884:	b761                	j	8000580c <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005886:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000588a:	04691783          	lh	a5,70(s2)
    8000588e:	02f99223          	sh	a5,36(s3)
    80005892:	bf2d                	j	800057cc <sys_open+0xa4>
    itrunc(ip);
    80005894:	854a                	mv	a0,s2
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	ff4080e7          	jalr	-12(ra) # 8000388a <itrunc>
    8000589e:	bfb1                	j	800057fa <sys_open+0xd2>
      fileclose(f);
    800058a0:	854e                	mv	a0,s3
    800058a2:	fffff097          	auipc	ra,0xfffff
    800058a6:	d68080e7          	jalr	-664(ra) # 8000460a <fileclose>
    iunlockput(ip);
    800058aa:	854a                	mv	a0,s2
    800058ac:	ffffe097          	auipc	ra,0xffffe
    800058b0:	132080e7          	jalr	306(ra) # 800039de <iunlockput>
    end_op();
    800058b4:	fffff097          	auipc	ra,0xfffff
    800058b8:	904080e7          	jalr	-1788(ra) # 800041b8 <end_op>
    return -1;
    800058bc:	54fd                	li	s1,-1
    800058be:	b7b9                	j	8000580c <sys_open+0xe4>

00000000800058c0 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c0:	7175                	addi	sp,sp,-144
    800058c2:	e506                	sd	ra,136(sp)
    800058c4:	e122                	sd	s0,128(sp)
    800058c6:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	870080e7          	jalr	-1936(ra) # 80004138 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d0:	08000613          	li	a2,128
    800058d4:	f7040593          	addi	a1,s0,-144
    800058d8:	4501                	li	a0,0
    800058da:	ffffd097          	auipc	ra,0xffffd
    800058de:	2ca080e7          	jalr	714(ra) # 80002ba4 <argstr>
    800058e2:	02054963          	bltz	a0,80005914 <sys_mkdir+0x54>
    800058e6:	4681                	li	a3,0
    800058e8:	4601                	li	a2,0
    800058ea:	4585                	li	a1,1
    800058ec:	f7040513          	addi	a0,s0,-144
    800058f0:	fffff097          	auipc	ra,0xfffff
    800058f4:	7fe080e7          	jalr	2046(ra) # 800050ee <create>
    800058f8:	cd11                	beqz	a0,80005914 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fa:	ffffe097          	auipc	ra,0xffffe
    800058fe:	0e4080e7          	jalr	228(ra) # 800039de <iunlockput>
  end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	8b6080e7          	jalr	-1866(ra) # 800041b8 <end_op>
  return 0;
    8000590a:	4501                	li	a0,0
}
    8000590c:	60aa                	ld	ra,136(sp)
    8000590e:	640a                	ld	s0,128(sp)
    80005910:	6149                	addi	sp,sp,144
    80005912:	8082                	ret
    end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	8a4080e7          	jalr	-1884(ra) # 800041b8 <end_op>
    return -1;
    8000591c:	557d                	li	a0,-1
    8000591e:	b7fd                	j	8000590c <sys_mkdir+0x4c>

0000000080005920 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005920:	7135                	addi	sp,sp,-160
    80005922:	ed06                	sd	ra,152(sp)
    80005924:	e922                	sd	s0,144(sp)
    80005926:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005928:	fffff097          	auipc	ra,0xfffff
    8000592c:	810080e7          	jalr	-2032(ra) # 80004138 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005930:	08000613          	li	a2,128
    80005934:	f7040593          	addi	a1,s0,-144
    80005938:	4501                	li	a0,0
    8000593a:	ffffd097          	auipc	ra,0xffffd
    8000593e:	26a080e7          	jalr	618(ra) # 80002ba4 <argstr>
    80005942:	04054a63          	bltz	a0,80005996 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005946:	f6c40593          	addi	a1,s0,-148
    8000594a:	4505                	li	a0,1
    8000594c:	ffffd097          	auipc	ra,0xffffd
    80005950:	214080e7          	jalr	532(ra) # 80002b60 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005954:	04054163          	bltz	a0,80005996 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005958:	f6840593          	addi	a1,s0,-152
    8000595c:	4509                	li	a0,2
    8000595e:	ffffd097          	auipc	ra,0xffffd
    80005962:	202080e7          	jalr	514(ra) # 80002b60 <argint>
     argint(1, &major) < 0 ||
    80005966:	02054863          	bltz	a0,80005996 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    8000596a:	f6841683          	lh	a3,-152(s0)
    8000596e:	f6c41603          	lh	a2,-148(s0)
    80005972:	458d                	li	a1,3
    80005974:	f7040513          	addi	a0,s0,-144
    80005978:	fffff097          	auipc	ra,0xfffff
    8000597c:	776080e7          	jalr	1910(ra) # 800050ee <create>
     argint(2, &minor) < 0 ||
    80005980:	c919                	beqz	a0,80005996 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005982:	ffffe097          	auipc	ra,0xffffe
    80005986:	05c080e7          	jalr	92(ra) # 800039de <iunlockput>
  end_op();
    8000598a:	fffff097          	auipc	ra,0xfffff
    8000598e:	82e080e7          	jalr	-2002(ra) # 800041b8 <end_op>
  return 0;
    80005992:	4501                	li	a0,0
    80005994:	a031                	j	800059a0 <sys_mknod+0x80>
    end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	822080e7          	jalr	-2014(ra) # 800041b8 <end_op>
    return -1;
    8000599e:	557d                	li	a0,-1
}
    800059a0:	60ea                	ld	ra,152(sp)
    800059a2:	644a                	ld	s0,144(sp)
    800059a4:	610d                	addi	sp,sp,160
    800059a6:	8082                	ret

00000000800059a8 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a8:	7135                	addi	sp,sp,-160
    800059aa:	ed06                	sd	ra,152(sp)
    800059ac:	e922                	sd	s0,144(sp)
    800059ae:	e526                	sd	s1,136(sp)
    800059b0:	e14a                	sd	s2,128(sp)
    800059b2:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059b4:	ffffc097          	auipc	ra,0xffffc
    800059b8:	09e080e7          	jalr	158(ra) # 80001a52 <myproc>
    800059bc:	892a                	mv	s2,a0
  
  begin_op();
    800059be:	ffffe097          	auipc	ra,0xffffe
    800059c2:	77a080e7          	jalr	1914(ra) # 80004138 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c6:	08000613          	li	a2,128
    800059ca:	f6040593          	addi	a1,s0,-160
    800059ce:	4501                	li	a0,0
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	1d4080e7          	jalr	468(ra) # 80002ba4 <argstr>
    800059d8:	04054b63          	bltz	a0,80005a2e <sys_chdir+0x86>
    800059dc:	f6040513          	addi	a0,s0,-160
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	54c080e7          	jalr	1356(ra) # 80003f2c <namei>
    800059e8:	84aa                	mv	s1,a0
    800059ea:	c131                	beqz	a0,80005a2e <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059ec:	ffffe097          	auipc	ra,0xffffe
    800059f0:	d90080e7          	jalr	-624(ra) # 8000377c <ilock>
  if(ip->type != T_DIR){
    800059f4:	04449703          	lh	a4,68(s1)
    800059f8:	4785                	li	a5,1
    800059fa:	04f71063          	bne	a4,a5,80005a3a <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	e3e080e7          	jalr	-450(ra) # 8000383e <iunlock>
  iput(p->cwd);
    80005a08:	15093503          	ld	a0,336(s2)
    80005a0c:	ffffe097          	auipc	ra,0xffffe
    80005a10:	f2a080e7          	jalr	-214(ra) # 80003936 <iput>
  end_op();
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	7a4080e7          	jalr	1956(ra) # 800041b8 <end_op>
  p->cwd = ip;
    80005a1c:	14993823          	sd	s1,336(s2)
  return 0;
    80005a20:	4501                	li	a0,0
}
    80005a22:	60ea                	ld	ra,152(sp)
    80005a24:	644a                	ld	s0,144(sp)
    80005a26:	64aa                	ld	s1,136(sp)
    80005a28:	690a                	ld	s2,128(sp)
    80005a2a:	610d                	addi	sp,sp,160
    80005a2c:	8082                	ret
    end_op();
    80005a2e:	ffffe097          	auipc	ra,0xffffe
    80005a32:	78a080e7          	jalr	1930(ra) # 800041b8 <end_op>
    return -1;
    80005a36:	557d                	li	a0,-1
    80005a38:	b7ed                	j	80005a22 <sys_chdir+0x7a>
    iunlockput(ip);
    80005a3a:	8526                	mv	a0,s1
    80005a3c:	ffffe097          	auipc	ra,0xffffe
    80005a40:	fa2080e7          	jalr	-94(ra) # 800039de <iunlockput>
    end_op();
    80005a44:	ffffe097          	auipc	ra,0xffffe
    80005a48:	774080e7          	jalr	1908(ra) # 800041b8 <end_op>
    return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	bfd1                	j	80005a22 <sys_chdir+0x7a>

0000000080005a50 <sys_exec>:

uint64
sys_exec(void)
{
    80005a50:	7145                	addi	sp,sp,-464
    80005a52:	e786                	sd	ra,456(sp)
    80005a54:	e3a2                	sd	s0,448(sp)
    80005a56:	ff26                	sd	s1,440(sp)
    80005a58:	fb4a                	sd	s2,432(sp)
    80005a5a:	f74e                	sd	s3,424(sp)
    80005a5c:	f352                	sd	s4,416(sp)
    80005a5e:	ef56                	sd	s5,408(sp)
    80005a60:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a62:	08000613          	li	a2,128
    80005a66:	f4040593          	addi	a1,s0,-192
    80005a6a:	4501                	li	a0,0
    80005a6c:	ffffd097          	auipc	ra,0xffffd
    80005a70:	138080e7          	jalr	312(ra) # 80002ba4 <argstr>
    return -1;
    80005a74:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005a76:	0c054a63          	bltz	a0,80005b4a <sys_exec+0xfa>
    80005a7a:	e3840593          	addi	a1,s0,-456
    80005a7e:	4505                	li	a0,1
    80005a80:	ffffd097          	auipc	ra,0xffffd
    80005a84:	102080e7          	jalr	258(ra) # 80002b82 <argaddr>
    80005a88:	0c054163          	bltz	a0,80005b4a <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005a8c:	10000613          	li	a2,256
    80005a90:	4581                	li	a1,0
    80005a92:	e4040513          	addi	a0,s0,-448
    80005a96:	ffffb097          	auipc	ra,0xffffb
    80005a9a:	2ea080e7          	jalr	746(ra) # 80000d80 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a9e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005aa2:	89a6                	mv	s3,s1
    80005aa4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005aa6:	02000a13          	li	s4,32
    80005aaa:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aae:	00391513          	slli	a0,s2,0x3
    80005ab2:	e3040593          	addi	a1,s0,-464
    80005ab6:	e3843783          	ld	a5,-456(s0)
    80005aba:	953e                	add	a0,a0,a5
    80005abc:	ffffd097          	auipc	ra,0xffffd
    80005ac0:	00a080e7          	jalr	10(ra) # 80002ac6 <fetchaddr>
    80005ac4:	02054a63          	bltz	a0,80005af8 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005ac8:	e3043783          	ld	a5,-464(s0)
    80005acc:	c3b9                	beqz	a5,80005b12 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ace:	ffffb097          	auipc	ra,0xffffb
    80005ad2:	0c6080e7          	jalr	198(ra) # 80000b94 <kalloc>
    80005ad6:	85aa                	mv	a1,a0
    80005ad8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005adc:	cd11                	beqz	a0,80005af8 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ade:	6605                	lui	a2,0x1
    80005ae0:	e3043503          	ld	a0,-464(s0)
    80005ae4:	ffffd097          	auipc	ra,0xffffd
    80005ae8:	034080e7          	jalr	52(ra) # 80002b18 <fetchstr>
    80005aec:	00054663          	bltz	a0,80005af8 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005af0:	0905                	addi	s2,s2,1
    80005af2:	09a1                	addi	s3,s3,8
    80005af4:	fb491be3          	bne	s2,s4,80005aaa <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af8:	10048913          	addi	s2,s1,256
    80005afc:	6088                	ld	a0,0(s1)
    80005afe:	c529                	beqz	a0,80005b48 <sys_exec+0xf8>
    kfree(argv[i]);
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	f98080e7          	jalr	-104(ra) # 80000a98 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b08:	04a1                	addi	s1,s1,8
    80005b0a:	ff2499e3          	bne	s1,s2,80005afc <sys_exec+0xac>
  return -1;
    80005b0e:	597d                	li	s2,-1
    80005b10:	a82d                	j	80005b4a <sys_exec+0xfa>
      argv[i] = 0;
    80005b12:	0a8e                	slli	s5,s5,0x3
    80005b14:	fc040793          	addi	a5,s0,-64
    80005b18:	9abe                	add	s5,s5,a5
    80005b1a:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b1e:	e4040593          	addi	a1,s0,-448
    80005b22:	f4040513          	addi	a0,s0,-192
    80005b26:	fffff097          	auipc	ra,0xfffff
    80005b2a:	194080e7          	jalr	404(ra) # 80004cba <exec>
    80005b2e:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b30:	10048993          	addi	s3,s1,256
    80005b34:	6088                	ld	a0,0(s1)
    80005b36:	c911                	beqz	a0,80005b4a <sys_exec+0xfa>
    kfree(argv[i]);
    80005b38:	ffffb097          	auipc	ra,0xffffb
    80005b3c:	f60080e7          	jalr	-160(ra) # 80000a98 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b40:	04a1                	addi	s1,s1,8
    80005b42:	ff3499e3          	bne	s1,s3,80005b34 <sys_exec+0xe4>
    80005b46:	a011                	j	80005b4a <sys_exec+0xfa>
  return -1;
    80005b48:	597d                	li	s2,-1
}
    80005b4a:	854a                	mv	a0,s2
    80005b4c:	60be                	ld	ra,456(sp)
    80005b4e:	641e                	ld	s0,448(sp)
    80005b50:	74fa                	ld	s1,440(sp)
    80005b52:	795a                	ld	s2,432(sp)
    80005b54:	79ba                	ld	s3,424(sp)
    80005b56:	7a1a                	ld	s4,416(sp)
    80005b58:	6afa                	ld	s5,408(sp)
    80005b5a:	6179                	addi	sp,sp,464
    80005b5c:	8082                	ret

0000000080005b5e <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b5e:	7139                	addi	sp,sp,-64
    80005b60:	fc06                	sd	ra,56(sp)
    80005b62:	f822                	sd	s0,48(sp)
    80005b64:	f426                	sd	s1,40(sp)
    80005b66:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b68:	ffffc097          	auipc	ra,0xffffc
    80005b6c:	eea080e7          	jalr	-278(ra) # 80001a52 <myproc>
    80005b70:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005b72:	fd840593          	addi	a1,s0,-40
    80005b76:	4501                	li	a0,0
    80005b78:	ffffd097          	auipc	ra,0xffffd
    80005b7c:	00a080e7          	jalr	10(ra) # 80002b82 <argaddr>
    return -1;
    80005b80:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005b82:	0e054063          	bltz	a0,80005c62 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005b86:	fc840593          	addi	a1,s0,-56
    80005b8a:	fd040513          	addi	a0,s0,-48
    80005b8e:	fffff097          	auipc	ra,0xfffff
    80005b92:	dd2080e7          	jalr	-558(ra) # 80004960 <pipealloc>
    return -1;
    80005b96:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b98:	0c054563          	bltz	a0,80005c62 <sys_pipe+0x104>
  fd0 = -1;
    80005b9c:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005ba0:	fd043503          	ld	a0,-48(s0)
    80005ba4:	fffff097          	auipc	ra,0xfffff
    80005ba8:	508080e7          	jalr	1288(ra) # 800050ac <fdalloc>
    80005bac:	fca42223          	sw	a0,-60(s0)
    80005bb0:	08054c63          	bltz	a0,80005c48 <sys_pipe+0xea>
    80005bb4:	fc843503          	ld	a0,-56(s0)
    80005bb8:	fffff097          	auipc	ra,0xfffff
    80005bbc:	4f4080e7          	jalr	1268(ra) # 800050ac <fdalloc>
    80005bc0:	fca42023          	sw	a0,-64(s0)
    80005bc4:	06054863          	bltz	a0,80005c34 <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bc8:	4691                	li	a3,4
    80005bca:	fc440613          	addi	a2,s0,-60
    80005bce:	fd843583          	ld	a1,-40(s0)
    80005bd2:	68a8                	ld	a0,80(s1)
    80005bd4:	ffffc097          	auipc	ra,0xffffc
    80005bd8:	b72080e7          	jalr	-1166(ra) # 80001746 <copyout>
    80005bdc:	02054063          	bltz	a0,80005bfc <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005be0:	4691                	li	a3,4
    80005be2:	fc040613          	addi	a2,s0,-64
    80005be6:	fd843583          	ld	a1,-40(s0)
    80005bea:	0591                	addi	a1,a1,4
    80005bec:	68a8                	ld	a0,80(s1)
    80005bee:	ffffc097          	auipc	ra,0xffffc
    80005bf2:	b58080e7          	jalr	-1192(ra) # 80001746 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bf6:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bf8:	06055563          	bgez	a0,80005c62 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005bfc:	fc442783          	lw	a5,-60(s0)
    80005c00:	07e9                	addi	a5,a5,26
    80005c02:	078e                	slli	a5,a5,0x3
    80005c04:	97a6                	add	a5,a5,s1
    80005c06:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005c0a:	fc042503          	lw	a0,-64(s0)
    80005c0e:	0569                	addi	a0,a0,26
    80005c10:	050e                	slli	a0,a0,0x3
    80005c12:	9526                	add	a0,a0,s1
    80005c14:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c18:	fd043503          	ld	a0,-48(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	9ee080e7          	jalr	-1554(ra) # 8000460a <fileclose>
    fileclose(wf);
    80005c24:	fc843503          	ld	a0,-56(s0)
    80005c28:	fffff097          	auipc	ra,0xfffff
    80005c2c:	9e2080e7          	jalr	-1566(ra) # 8000460a <fileclose>
    return -1;
    80005c30:	57fd                	li	a5,-1
    80005c32:	a805                	j	80005c62 <sys_pipe+0x104>
    if(fd0 >= 0)
    80005c34:	fc442783          	lw	a5,-60(s0)
    80005c38:	0007c863          	bltz	a5,80005c48 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80005c3c:	01a78513          	addi	a0,a5,26
    80005c40:	050e                	slli	a0,a0,0x3
    80005c42:	9526                	add	a0,a0,s1
    80005c44:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005c48:	fd043503          	ld	a0,-48(s0)
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	9be080e7          	jalr	-1602(ra) # 8000460a <fileclose>
    fileclose(wf);
    80005c54:	fc843503          	ld	a0,-56(s0)
    80005c58:	fffff097          	auipc	ra,0xfffff
    80005c5c:	9b2080e7          	jalr	-1614(ra) # 8000460a <fileclose>
    return -1;
    80005c60:	57fd                	li	a5,-1
}
    80005c62:	853e                	mv	a0,a5
    80005c64:	70e2                	ld	ra,56(sp)
    80005c66:	7442                	ld	s0,48(sp)
    80005c68:	74a2                	ld	s1,40(sp)
    80005c6a:	6121                	addi	sp,sp,64
    80005c6c:	8082                	ret
	...

0000000080005c70 <kernelvec>:
    80005c70:	7111                	addi	sp,sp,-256
    80005c72:	e006                	sd	ra,0(sp)
    80005c74:	e40a                	sd	sp,8(sp)
    80005c76:	e80e                	sd	gp,16(sp)
    80005c78:	ec12                	sd	tp,24(sp)
    80005c7a:	f016                	sd	t0,32(sp)
    80005c7c:	f41a                	sd	t1,40(sp)
    80005c7e:	f81e                	sd	t2,48(sp)
    80005c80:	fc22                	sd	s0,56(sp)
    80005c82:	e0a6                	sd	s1,64(sp)
    80005c84:	e4aa                	sd	a0,72(sp)
    80005c86:	e8ae                	sd	a1,80(sp)
    80005c88:	ecb2                	sd	a2,88(sp)
    80005c8a:	f0b6                	sd	a3,96(sp)
    80005c8c:	f4ba                	sd	a4,104(sp)
    80005c8e:	f8be                	sd	a5,112(sp)
    80005c90:	fcc2                	sd	a6,120(sp)
    80005c92:	e146                	sd	a7,128(sp)
    80005c94:	e54a                	sd	s2,136(sp)
    80005c96:	e94e                	sd	s3,144(sp)
    80005c98:	ed52                	sd	s4,152(sp)
    80005c9a:	f156                	sd	s5,160(sp)
    80005c9c:	f55a                	sd	s6,168(sp)
    80005c9e:	f95e                	sd	s7,176(sp)
    80005ca0:	fd62                	sd	s8,184(sp)
    80005ca2:	e1e6                	sd	s9,192(sp)
    80005ca4:	e5ea                	sd	s10,200(sp)
    80005ca6:	e9ee                	sd	s11,208(sp)
    80005ca8:	edf2                	sd	t3,216(sp)
    80005caa:	f1f6                	sd	t4,224(sp)
    80005cac:	f5fa                	sd	t5,232(sp)
    80005cae:	f9fe                	sd	t6,240(sp)
    80005cb0:	ce3fc0ef          	jal	ra,80002992 <kerneltrap>
    80005cb4:	6082                	ld	ra,0(sp)
    80005cb6:	6122                	ld	sp,8(sp)
    80005cb8:	61c2                	ld	gp,16(sp)
    80005cba:	7282                	ld	t0,32(sp)
    80005cbc:	7322                	ld	t1,40(sp)
    80005cbe:	73c2                	ld	t2,48(sp)
    80005cc0:	7462                	ld	s0,56(sp)
    80005cc2:	6486                	ld	s1,64(sp)
    80005cc4:	6526                	ld	a0,72(sp)
    80005cc6:	65c6                	ld	a1,80(sp)
    80005cc8:	6666                	ld	a2,88(sp)
    80005cca:	7686                	ld	a3,96(sp)
    80005ccc:	7726                	ld	a4,104(sp)
    80005cce:	77c6                	ld	a5,112(sp)
    80005cd0:	7866                	ld	a6,120(sp)
    80005cd2:	688a                	ld	a7,128(sp)
    80005cd4:	692a                	ld	s2,136(sp)
    80005cd6:	69ca                	ld	s3,144(sp)
    80005cd8:	6a6a                	ld	s4,152(sp)
    80005cda:	7a8a                	ld	s5,160(sp)
    80005cdc:	7b2a                	ld	s6,168(sp)
    80005cde:	7bca                	ld	s7,176(sp)
    80005ce0:	7c6a                	ld	s8,184(sp)
    80005ce2:	6c8e                	ld	s9,192(sp)
    80005ce4:	6d2e                	ld	s10,200(sp)
    80005ce6:	6dce                	ld	s11,208(sp)
    80005ce8:	6e6e                	ld	t3,216(sp)
    80005cea:	7e8e                	ld	t4,224(sp)
    80005cec:	7f2e                	ld	t5,232(sp)
    80005cee:	7fce                	ld	t6,240(sp)
    80005cf0:	6111                	addi	sp,sp,256
    80005cf2:	10200073          	sret
    80005cf6:	00000013          	nop
    80005cfa:	00000013          	nop
    80005cfe:	0001                	nop

0000000080005d00 <timervec>:
    80005d00:	34051573          	csrrw	a0,mscratch,a0
    80005d04:	e10c                	sd	a1,0(a0)
    80005d06:	e510                	sd	a2,8(a0)
    80005d08:	e914                	sd	a3,16(a0)
    80005d0a:	710c                	ld	a1,32(a0)
    80005d0c:	7510                	ld	a2,40(a0)
    80005d0e:	6194                	ld	a3,0(a1)
    80005d10:	96b2                	add	a3,a3,a2
    80005d12:	e194                	sd	a3,0(a1)
    80005d14:	4589                	li	a1,2
    80005d16:	14459073          	csrw	sip,a1
    80005d1a:	6914                	ld	a3,16(a0)
    80005d1c:	6510                	ld	a2,8(a0)
    80005d1e:	610c                	ld	a1,0(a0)
    80005d20:	34051573          	csrrw	a0,mscratch,a0
    80005d24:	30200073          	mret
	...

0000000080005d2a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d2a:	1141                	addi	sp,sp,-16
    80005d2c:	e422                	sd	s0,8(sp)
    80005d2e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d30:	0c0007b7          	lui	a5,0xc000
    80005d34:	4705                	li	a4,1
    80005d36:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d38:	c3d8                	sw	a4,4(a5)
}
    80005d3a:	6422                	ld	s0,8(sp)
    80005d3c:	0141                	addi	sp,sp,16
    80005d3e:	8082                	ret

0000000080005d40 <plicinithart>:

void
plicinithart(void)
{
    80005d40:	1141                	addi	sp,sp,-16
    80005d42:	e406                	sd	ra,8(sp)
    80005d44:	e022                	sd	s0,0(sp)
    80005d46:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d48:	ffffc097          	auipc	ra,0xffffc
    80005d4c:	cde080e7          	jalr	-802(ra) # 80001a26 <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d50:	0085171b          	slliw	a4,a0,0x8
    80005d54:	0c0027b7          	lui	a5,0xc002
    80005d58:	97ba                	add	a5,a5,a4
    80005d5a:	40200713          	li	a4,1026
    80005d5e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d62:	00d5151b          	slliw	a0,a0,0xd
    80005d66:	0c2017b7          	lui	a5,0xc201
    80005d6a:	953e                	add	a0,a0,a5
    80005d6c:	00052023          	sw	zero,0(a0)
}
    80005d70:	60a2                	ld	ra,8(sp)
    80005d72:	6402                	ld	s0,0(sp)
    80005d74:	0141                	addi	sp,sp,16
    80005d76:	8082                	ret

0000000080005d78 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d78:	1141                	addi	sp,sp,-16
    80005d7a:	e406                	sd	ra,8(sp)
    80005d7c:	e022                	sd	s0,0(sp)
    80005d7e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d80:	ffffc097          	auipc	ra,0xffffc
    80005d84:	ca6080e7          	jalr	-858(ra) # 80001a26 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d88:	00d5179b          	slliw	a5,a0,0xd
    80005d8c:	0c201537          	lui	a0,0xc201
    80005d90:	953e                	add	a0,a0,a5
  return irq;
}
    80005d92:	4148                	lw	a0,4(a0)
    80005d94:	60a2                	ld	ra,8(sp)
    80005d96:	6402                	ld	s0,0(sp)
    80005d98:	0141                	addi	sp,sp,16
    80005d9a:	8082                	ret

0000000080005d9c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d9c:	1101                	addi	sp,sp,-32
    80005d9e:	ec06                	sd	ra,24(sp)
    80005da0:	e822                	sd	s0,16(sp)
    80005da2:	e426                	sd	s1,8(sp)
    80005da4:	1000                	addi	s0,sp,32
    80005da6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005da8:	ffffc097          	auipc	ra,0xffffc
    80005dac:	c7e080e7          	jalr	-898(ra) # 80001a26 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005db0:	00d5151b          	slliw	a0,a0,0xd
    80005db4:	0c2017b7          	lui	a5,0xc201
    80005db8:	97aa                	add	a5,a5,a0
    80005dba:	c3c4                	sw	s1,4(a5)
}
    80005dbc:	60e2                	ld	ra,24(sp)
    80005dbe:	6442                	ld	s0,16(sp)
    80005dc0:	64a2                	ld	s1,8(sp)
    80005dc2:	6105                	addi	sp,sp,32
    80005dc4:	8082                	ret

0000000080005dc6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005dc6:	1141                	addi	sp,sp,-16
    80005dc8:	e406                	sd	ra,8(sp)
    80005dca:	e022                	sd	s0,0(sp)
    80005dcc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dce:	479d                	li	a5,7
    80005dd0:	04a7cc63          	blt	a5,a0,80005e28 <free_desc+0x62>
    panic("virtio_disk_intr 1");
  if(disk.free[i])
    80005dd4:	00022797          	auipc	a5,0x22
    80005dd8:	22c78793          	addi	a5,a5,556 # 80028000 <disk>
    80005ddc:	00a78733          	add	a4,a5,a0
    80005de0:	6789                	lui	a5,0x2
    80005de2:	97ba                	add	a5,a5,a4
    80005de4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80005de8:	eba1                	bnez	a5,80005e38 <free_desc+0x72>
    panic("virtio_disk_intr 2");
  disk.desc[i].addr = 0;
    80005dea:	00451713          	slli	a4,a0,0x4
    80005dee:	00024797          	auipc	a5,0x24
    80005df2:	2127b783          	ld	a5,530(a5) # 8002a000 <disk+0x2000>
    80005df6:	97ba                	add	a5,a5,a4
    80005df8:	0007b023          	sd	zero,0(a5)
  disk.free[i] = 1;
    80005dfc:	00022797          	auipc	a5,0x22
    80005e00:	20478793          	addi	a5,a5,516 # 80028000 <disk>
    80005e04:	97aa                	add	a5,a5,a0
    80005e06:	6509                	lui	a0,0x2
    80005e08:	953e                	add	a0,a0,a5
    80005e0a:	4785                	li	a5,1
    80005e0c:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    80005e10:	00024517          	auipc	a0,0x24
    80005e14:	20850513          	addi	a0,a0,520 # 8002a018 <disk+0x2018>
    80005e18:	ffffc097          	auipc	ra,0xffffc
    80005e1c:	5dc080e7          	jalr	1500(ra) # 800023f4 <wakeup>
}
    80005e20:	60a2                	ld	ra,8(sp)
    80005e22:	6402                	ld	s0,0(sp)
    80005e24:	0141                	addi	sp,sp,16
    80005e26:	8082                	ret
    panic("virtio_disk_intr 1");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	95850513          	addi	a0,a0,-1704 # 80008780 <syscalls+0x340>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	718080e7          	jalr	1816(ra) # 80000548 <panic>
    panic("virtio_disk_intr 2");
    80005e38:	00003517          	auipc	a0,0x3
    80005e3c:	96050513          	addi	a0,a0,-1696 # 80008798 <syscalls+0x358>
    80005e40:	ffffa097          	auipc	ra,0xffffa
    80005e44:	708080e7          	jalr	1800(ra) # 80000548 <panic>

0000000080005e48 <virtio_disk_init>:
{
    80005e48:	1101                	addi	sp,sp,-32
    80005e4a:	ec06                	sd	ra,24(sp)
    80005e4c:	e822                	sd	s0,16(sp)
    80005e4e:	e426                	sd	s1,8(sp)
    80005e50:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e52:	00003597          	auipc	a1,0x3
    80005e56:	95e58593          	addi	a1,a1,-1698 # 800087b0 <syscalls+0x370>
    80005e5a:	00024517          	auipc	a0,0x24
    80005e5e:	24e50513          	addi	a0,a0,590 # 8002a0a8 <disk+0x20a8>
    80005e62:	ffffb097          	auipc	ra,0xffffb
    80005e66:	d92080e7          	jalr	-622(ra) # 80000bf4 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e6a:	100017b7          	lui	a5,0x10001
    80005e6e:	4398                	lw	a4,0(a5)
    80005e70:	2701                	sext.w	a4,a4
    80005e72:	747277b7          	lui	a5,0x74727
    80005e76:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e7a:	0ef71163          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	43dc                	lw	a5,4(a5)
    80005e84:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e86:	4705                	li	a4,1
    80005e88:	0ce79a63          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e8c:	100017b7          	lui	a5,0x10001
    80005e90:	479c                	lw	a5,8(a5)
    80005e92:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80005e94:	4709                	li	a4,2
    80005e96:	0ce79363          	bne	a5,a4,80005f5c <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e9a:	100017b7          	lui	a5,0x10001
    80005e9e:	47d8                	lw	a4,12(a5)
    80005ea0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005ea2:	554d47b7          	lui	a5,0x554d4
    80005ea6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005eaa:	0af71963          	bne	a4,a5,80005f5c <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eae:	100017b7          	lui	a5,0x10001
    80005eb2:	4705                	li	a4,1
    80005eb4:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eb6:	470d                	li	a4,3
    80005eb8:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eba:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80005ebc:	c7ffe737          	lui	a4,0xc7ffe
    80005ec0:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd375f>
    80005ec4:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005ec6:	2701                	sext.w	a4,a4
    80005ec8:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eca:	472d                	li	a4,11
    80005ecc:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ece:	473d                	li	a4,15
    80005ed0:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    80005ed2:	6705                	lui	a4,0x1
    80005ed4:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ed6:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005eda:	5bdc                	lw	a5,52(a5)
    80005edc:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ede:	c7d9                	beqz	a5,80005f6c <virtio_disk_init+0x124>
  if(max < NUM)
    80005ee0:	471d                	li	a4,7
    80005ee2:	08f77d63          	bgeu	a4,a5,80005f7c <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005ee6:	100014b7          	lui	s1,0x10001
    80005eea:	47a1                	li	a5,8
    80005eec:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80005eee:	6609                	lui	a2,0x2
    80005ef0:	4581                	li	a1,0
    80005ef2:	00022517          	auipc	a0,0x22
    80005ef6:	10e50513          	addi	a0,a0,270 # 80028000 <disk>
    80005efa:	ffffb097          	auipc	ra,0xffffb
    80005efe:	e86080e7          	jalr	-378(ra) # 80000d80 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    80005f02:	00022717          	auipc	a4,0x22
    80005f06:	0fe70713          	addi	a4,a4,254 # 80028000 <disk>
    80005f0a:	00c75793          	srli	a5,a4,0xc
    80005f0e:	2781                	sext.w	a5,a5
    80005f10:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct VRingDesc *) disk.pages;
    80005f12:	00024797          	auipc	a5,0x24
    80005f16:	0ee78793          	addi	a5,a5,238 # 8002a000 <disk+0x2000>
    80005f1a:	e398                	sd	a4,0(a5)
  disk.avail = (uint16*)(((char*)disk.desc) + NUM*sizeof(struct VRingDesc));
    80005f1c:	00022717          	auipc	a4,0x22
    80005f20:	16470713          	addi	a4,a4,356 # 80028080 <disk+0x80>
    80005f24:	e798                	sd	a4,8(a5)
  disk.used = (struct UsedArea *) (disk.pages + PGSIZE);
    80005f26:	00023717          	auipc	a4,0x23
    80005f2a:	0da70713          	addi	a4,a4,218 # 80029000 <disk+0x1000>
    80005f2e:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    80005f30:	4705                	li	a4,1
    80005f32:	00e78c23          	sb	a4,24(a5)
    80005f36:	00e78ca3          	sb	a4,25(a5)
    80005f3a:	00e78d23          	sb	a4,26(a5)
    80005f3e:	00e78da3          	sb	a4,27(a5)
    80005f42:	00e78e23          	sb	a4,28(a5)
    80005f46:	00e78ea3          	sb	a4,29(a5)
    80005f4a:	00e78f23          	sb	a4,30(a5)
    80005f4e:	00e78fa3          	sb	a4,31(a5)
}
    80005f52:	60e2                	ld	ra,24(sp)
    80005f54:	6442                	ld	s0,16(sp)
    80005f56:	64a2                	ld	s1,8(sp)
    80005f58:	6105                	addi	sp,sp,32
    80005f5a:	8082                	ret
    panic("could not find virtio disk");
    80005f5c:	00003517          	auipc	a0,0x3
    80005f60:	86450513          	addi	a0,a0,-1948 # 800087c0 <syscalls+0x380>
    80005f64:	ffffa097          	auipc	ra,0xffffa
    80005f68:	5e4080e7          	jalr	1508(ra) # 80000548 <panic>
    panic("virtio disk has no queue 0");
    80005f6c:	00003517          	auipc	a0,0x3
    80005f70:	87450513          	addi	a0,a0,-1932 # 800087e0 <syscalls+0x3a0>
    80005f74:	ffffa097          	auipc	ra,0xffffa
    80005f78:	5d4080e7          	jalr	1492(ra) # 80000548 <panic>
    panic("virtio disk max queue too short");
    80005f7c:	00003517          	auipc	a0,0x3
    80005f80:	88450513          	addi	a0,a0,-1916 # 80008800 <syscalls+0x3c0>
    80005f84:	ffffa097          	auipc	ra,0xffffa
    80005f88:	5c4080e7          	jalr	1476(ra) # 80000548 <panic>

0000000080005f8c <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80005f8c:	7119                	addi	sp,sp,-128
    80005f8e:	fc86                	sd	ra,120(sp)
    80005f90:	f8a2                	sd	s0,112(sp)
    80005f92:	f4a6                	sd	s1,104(sp)
    80005f94:	f0ca                	sd	s2,96(sp)
    80005f96:	ecce                	sd	s3,88(sp)
    80005f98:	e8d2                	sd	s4,80(sp)
    80005f9a:	e4d6                	sd	s5,72(sp)
    80005f9c:	e0da                	sd	s6,64(sp)
    80005f9e:	fc5e                	sd	s7,56(sp)
    80005fa0:	f862                	sd	s8,48(sp)
    80005fa2:	f466                	sd	s9,40(sp)
    80005fa4:	f06a                	sd	s10,32(sp)
    80005fa6:	0100                	addi	s0,sp,128
    80005fa8:	892a                	mv	s2,a0
    80005faa:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80005fac:	00c52c83          	lw	s9,12(a0)
    80005fb0:	001c9c9b          	slliw	s9,s9,0x1
    80005fb4:	1c82                	slli	s9,s9,0x20
    80005fb6:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80005fba:	00024517          	auipc	a0,0x24
    80005fbe:	0ee50513          	addi	a0,a0,238 # 8002a0a8 <disk+0x20a8>
    80005fc2:	ffffb097          	auipc	ra,0xffffb
    80005fc6:	cc2080e7          	jalr	-830(ra) # 80000c84 <acquire>
  for(int i = 0; i < 3; i++){
    80005fca:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80005fcc:	4c21                	li	s8,8
      disk.free[i] = 0;
    80005fce:	00022b97          	auipc	s7,0x22
    80005fd2:	032b8b93          	addi	s7,s7,50 # 80028000 <disk>
    80005fd6:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80005fd8:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80005fda:	8a4e                	mv	s4,s3
    80005fdc:	a051                	j	80006060 <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80005fde:	00fb86b3          	add	a3,s7,a5
    80005fe2:	96da                	add	a3,a3,s6
    80005fe4:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80005fe8:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80005fea:	0207c563          	bltz	a5,80006014 <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80005fee:	2485                	addiw	s1,s1,1
    80005ff0:	0711                	addi	a4,a4,4
    80005ff2:	23548d63          	beq	s1,s5,8000622c <virtio_disk_rw+0x2a0>
    idx[i] = alloc_desc();
    80005ff6:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80005ff8:	00024697          	auipc	a3,0x24
    80005ffc:	02068693          	addi	a3,a3,32 # 8002a018 <disk+0x2018>
    80006000:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006002:	0006c583          	lbu	a1,0(a3)
    80006006:	fde1                	bnez	a1,80005fde <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006008:	2785                	addiw	a5,a5,1
    8000600a:	0685                	addi	a3,a3,1
    8000600c:	ff879be3          	bne	a5,s8,80006002 <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    80006010:	57fd                	li	a5,-1
    80006012:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006014:	02905a63          	blez	s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006018:	f9042503          	lw	a0,-112(s0)
    8000601c:	00000097          	auipc	ra,0x0
    80006020:	daa080e7          	jalr	-598(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006024:	4785                	li	a5,1
    80006026:	0297d163          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000602a:	f9442503          	lw	a0,-108(s0)
    8000602e:	00000097          	auipc	ra,0x0
    80006032:	d98080e7          	jalr	-616(ra) # 80005dc6 <free_desc>
      for(int j = 0; j < i; j++)
    80006036:	4789                	li	a5,2
    80006038:	0097d863          	bge	a5,s1,80006048 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    8000603c:	f9842503          	lw	a0,-104(s0)
    80006040:	00000097          	auipc	ra,0x0
    80006044:	d86080e7          	jalr	-634(ra) # 80005dc6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006048:	00024597          	auipc	a1,0x24
    8000604c:	06058593          	addi	a1,a1,96 # 8002a0a8 <disk+0x20a8>
    80006050:	00024517          	auipc	a0,0x24
    80006054:	fc850513          	addi	a0,a0,-56 # 8002a018 <disk+0x2018>
    80006058:	ffffc097          	auipc	ra,0xffffc
    8000605c:	216080e7          	jalr	534(ra) # 8000226e <sleep>
  for(int i = 0; i < 3; i++){
    80006060:	f9040713          	addi	a4,s0,-112
    80006064:	84ce                	mv	s1,s3
    80006066:	bf41                	j	80005ff6 <virtio_disk_rw+0x6a>
    uint32 reserved;
    uint64 sector;
  } buf0;

  if(write)
    buf0.type = VIRTIO_BLK_T_OUT; // write the disk
    80006068:	4785                	li	a5,1
    8000606a:	f8f42023          	sw	a5,-128(s0)
  else
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
  buf0.reserved = 0;
    8000606e:	f8042223          	sw	zero,-124(s0)
  buf0.sector = sector;
    80006072:	f9943423          	sd	s9,-120(s0)

  // buf0 is on a kernel stack, which is not direct mapped,
  // thus the call to kvmpa().
  disk.desc[idx[0]].addr = (uint64) kvmpa((uint64) &buf0);
    80006076:	f9042983          	lw	s3,-112(s0)
    8000607a:	00499493          	slli	s1,s3,0x4
    8000607e:	00024a17          	auipc	s4,0x24
    80006082:	f82a0a13          	addi	s4,s4,-126 # 8002a000 <disk+0x2000>
    80006086:	000a3a83          	ld	s5,0(s4)
    8000608a:	9aa6                	add	s5,s5,s1
    8000608c:	f8040513          	addi	a0,s0,-128
    80006090:	ffffb097          	auipc	ra,0xffffb
    80006094:	0c4080e7          	jalr	196(ra) # 80001154 <kvmpa>
    80006098:	00aab023          	sd	a0,0(s5)
  disk.desc[idx[0]].len = sizeof(buf0);
    8000609c:	000a3783          	ld	a5,0(s4)
    800060a0:	97a6                	add	a5,a5,s1
    800060a2:	4741                	li	a4,16
    800060a4:	c798                	sw	a4,8(a5)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800060a6:	000a3783          	ld	a5,0(s4)
    800060aa:	97a6                	add	a5,a5,s1
    800060ac:	4705                	li	a4,1
    800060ae:	00e79623          	sh	a4,12(a5)
  disk.desc[idx[0]].next = idx[1];
    800060b2:	f9442703          	lw	a4,-108(s0)
    800060b6:	000a3783          	ld	a5,0(s4)
    800060ba:	97a6                	add	a5,a5,s1
    800060bc:	00e79723          	sh	a4,14(a5)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800060c0:	0712                	slli	a4,a4,0x4
    800060c2:	000a3783          	ld	a5,0(s4)
    800060c6:	97ba                	add	a5,a5,a4
    800060c8:	05890693          	addi	a3,s2,88
    800060cc:	e394                	sd	a3,0(a5)
  disk.desc[idx[1]].len = BSIZE;
    800060ce:	000a3783          	ld	a5,0(s4)
    800060d2:	97ba                	add	a5,a5,a4
    800060d4:	40000693          	li	a3,1024
    800060d8:	c794                	sw	a3,8(a5)
  if(write)
    800060da:	100d0a63          	beqz	s10,800061ee <virtio_disk_rw+0x262>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    800060de:	00024797          	auipc	a5,0x24
    800060e2:	f227b783          	ld	a5,-222(a5) # 8002a000 <disk+0x2000>
    800060e6:	97ba                	add	a5,a5,a4
    800060e8:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800060ec:	00022517          	auipc	a0,0x22
    800060f0:	f1450513          	addi	a0,a0,-236 # 80028000 <disk>
    800060f4:	00024797          	auipc	a5,0x24
    800060f8:	f0c78793          	addi	a5,a5,-244 # 8002a000 <disk+0x2000>
    800060fc:	6394                	ld	a3,0(a5)
    800060fe:	96ba                	add	a3,a3,a4
    80006100:	00c6d603          	lhu	a2,12(a3)
    80006104:	00166613          	ori	a2,a2,1
    80006108:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000610c:	f9842683          	lw	a3,-104(s0)
    80006110:	6390                	ld	a2,0(a5)
    80006112:	9732                	add	a4,a4,a2
    80006114:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0;
    80006118:	20098613          	addi	a2,s3,512
    8000611c:	0612                	slli	a2,a2,0x4
    8000611e:	962a                	add	a2,a2,a0
    80006120:	02060823          	sb	zero,48(a2) # 2030 <_entry-0x7fffdfd0>
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006124:	00469713          	slli	a4,a3,0x4
    80006128:	6394                	ld	a3,0(a5)
    8000612a:	96ba                	add	a3,a3,a4
    8000612c:	6589                	lui	a1,0x2
    8000612e:	03058593          	addi	a1,a1,48 # 2030 <_entry-0x7fffdfd0>
    80006132:	94ae                	add	s1,s1,a1
    80006134:	94aa                	add	s1,s1,a0
    80006136:	e284                	sd	s1,0(a3)
  disk.desc[idx[2]].len = 1;
    80006138:	6394                	ld	a3,0(a5)
    8000613a:	96ba                	add	a3,a3,a4
    8000613c:	4585                	li	a1,1
    8000613e:	c68c                	sw	a1,8(a3)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006140:	6394                	ld	a3,0(a5)
    80006142:	96ba                	add	a3,a3,a4
    80006144:	4509                	li	a0,2
    80006146:	00a69623          	sh	a0,12(a3)
  disk.desc[idx[2]].next = 0;
    8000614a:	6394                	ld	a3,0(a5)
    8000614c:	9736                	add	a4,a4,a3
    8000614e:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006152:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006156:	03263423          	sd	s2,40(a2)

  // avail[0] is flags
  // avail[1] tells the device how far to look in avail[2...].
  // avail[2...] are desc[] indices the device should process.
  // we only tell device the first index in our chain of descriptors.
  disk.avail[2 + (disk.avail[1] % NUM)] = idx[0];
    8000615a:	6794                	ld	a3,8(a5)
    8000615c:	0026d703          	lhu	a4,2(a3)
    80006160:	8b1d                	andi	a4,a4,7
    80006162:	2709                	addiw	a4,a4,2
    80006164:	0706                	slli	a4,a4,0x1
    80006166:	9736                	add	a4,a4,a3
    80006168:	01371023          	sh	s3,0(a4)
  __sync_synchronize();
    8000616c:	0ff0000f          	fence
  disk.avail[1] = disk.avail[1] + 1;
    80006170:	6798                	ld	a4,8(a5)
    80006172:	00275783          	lhu	a5,2(a4)
    80006176:	2785                	addiw	a5,a5,1
    80006178:	00f71123          	sh	a5,2(a4)

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000617c:	100017b7          	lui	a5,0x10001
    80006180:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006184:	00492703          	lw	a4,4(s2)
    80006188:	4785                	li	a5,1
    8000618a:	02f71163          	bne	a4,a5,800061ac <virtio_disk_rw+0x220>
    sleep(b, &disk.vdisk_lock);
    8000618e:	00024997          	auipc	s3,0x24
    80006192:	f1a98993          	addi	s3,s3,-230 # 8002a0a8 <disk+0x20a8>
  while(b->disk == 1) {
    80006196:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006198:	85ce                	mv	a1,s3
    8000619a:	854a                	mv	a0,s2
    8000619c:	ffffc097          	auipc	ra,0xffffc
    800061a0:	0d2080e7          	jalr	210(ra) # 8000226e <sleep>
  while(b->disk == 1) {
    800061a4:	00492783          	lw	a5,4(s2)
    800061a8:	fe9788e3          	beq	a5,s1,80006198 <virtio_disk_rw+0x20c>
  }

  disk.info[idx[0]].b = 0;
    800061ac:	f9042483          	lw	s1,-112(s0)
    800061b0:	20048793          	addi	a5,s1,512 # 10001200 <_entry-0x6fffee00>
    800061b4:	00479713          	slli	a4,a5,0x4
    800061b8:	00022797          	auipc	a5,0x22
    800061bc:	e4878793          	addi	a5,a5,-440 # 80028000 <disk>
    800061c0:	97ba                	add	a5,a5,a4
    800061c2:	0207b423          	sd	zero,40(a5)
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061c6:	00024917          	auipc	s2,0x24
    800061ca:	e3a90913          	addi	s2,s2,-454 # 8002a000 <disk+0x2000>
    free_desc(i);
    800061ce:	8526                	mv	a0,s1
    800061d0:	00000097          	auipc	ra,0x0
    800061d4:	bf6080e7          	jalr	-1034(ra) # 80005dc6 <free_desc>
    if(disk.desc[i].flags & VRING_DESC_F_NEXT)
    800061d8:	0492                	slli	s1,s1,0x4
    800061da:	00093783          	ld	a5,0(s2)
    800061de:	94be                	add	s1,s1,a5
    800061e0:	00c4d783          	lhu	a5,12(s1)
    800061e4:	8b85                	andi	a5,a5,1
    800061e6:	cf89                	beqz	a5,80006200 <virtio_disk_rw+0x274>
      i = disk.desc[i].next;
    800061e8:	00e4d483          	lhu	s1,14(s1)
    free_desc(i);
    800061ec:	b7cd                	j	800061ce <virtio_disk_rw+0x242>
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800061ee:	00024797          	auipc	a5,0x24
    800061f2:	e127b783          	ld	a5,-494(a5) # 8002a000 <disk+0x2000>
    800061f6:	97ba                	add	a5,a5,a4
    800061f8:	4689                	li	a3,2
    800061fa:	00d79623          	sh	a3,12(a5)
    800061fe:	b5fd                	j	800060ec <virtio_disk_rw+0x160>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006200:	00024517          	auipc	a0,0x24
    80006204:	ea850513          	addi	a0,a0,-344 # 8002a0a8 <disk+0x20a8>
    80006208:	ffffb097          	auipc	ra,0xffffb
    8000620c:	b30080e7          	jalr	-1232(ra) # 80000d38 <release>
}
    80006210:	70e6                	ld	ra,120(sp)
    80006212:	7446                	ld	s0,112(sp)
    80006214:	74a6                	ld	s1,104(sp)
    80006216:	7906                	ld	s2,96(sp)
    80006218:	69e6                	ld	s3,88(sp)
    8000621a:	6a46                	ld	s4,80(sp)
    8000621c:	6aa6                	ld	s5,72(sp)
    8000621e:	6b06                	ld	s6,64(sp)
    80006220:	7be2                	ld	s7,56(sp)
    80006222:	7c42                	ld	s8,48(sp)
    80006224:	7ca2                	ld	s9,40(sp)
    80006226:	7d02                	ld	s10,32(sp)
    80006228:	6109                	addi	sp,sp,128
    8000622a:	8082                	ret
  if(write)
    8000622c:	e20d1ee3          	bnez	s10,80006068 <virtio_disk_rw+0xdc>
    buf0.type = VIRTIO_BLK_T_IN; // read the disk
    80006230:	f8042023          	sw	zero,-128(s0)
    80006234:	bd2d                	j	8000606e <virtio_disk_rw+0xe2>

0000000080006236 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006236:	1101                	addi	sp,sp,-32
    80006238:	ec06                	sd	ra,24(sp)
    8000623a:	e822                	sd	s0,16(sp)
    8000623c:	e426                	sd	s1,8(sp)
    8000623e:	e04a                	sd	s2,0(sp)
    80006240:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006242:	00024517          	auipc	a0,0x24
    80006246:	e6650513          	addi	a0,a0,-410 # 8002a0a8 <disk+0x20a8>
    8000624a:	ffffb097          	auipc	ra,0xffffb
    8000624e:	a3a080e7          	jalr	-1478(ra) # 80000c84 <acquire>

  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    80006252:	00024717          	auipc	a4,0x24
    80006256:	dae70713          	addi	a4,a4,-594 # 8002a000 <disk+0x2000>
    8000625a:	02075783          	lhu	a5,32(a4)
    8000625e:	6b18                	ld	a4,16(a4)
    80006260:	00275683          	lhu	a3,2(a4)
    80006264:	8ebd                	xor	a3,a3,a5
    80006266:	8a9d                	andi	a3,a3,7
    80006268:	cab9                	beqz	a3,800062be <virtio_disk_intr+0x88>
    int id = disk.used->elems[disk.used_idx].id;

    if(disk.info[id].status != 0)
    8000626a:	00022917          	auipc	s2,0x22
    8000626e:	d9690913          	addi	s2,s2,-618 # 80028000 <disk>
      panic("virtio_disk_intr status");
    
    disk.info[id].b->disk = 0;   // disk is done with buf
    wakeup(disk.info[id].b);

    disk.used_idx = (disk.used_idx + 1) % NUM;
    80006272:	00024497          	auipc	s1,0x24
    80006276:	d8e48493          	addi	s1,s1,-626 # 8002a000 <disk+0x2000>
    int id = disk.used->elems[disk.used_idx].id;
    8000627a:	078e                	slli	a5,a5,0x3
    8000627c:	97ba                	add	a5,a5,a4
    8000627e:	43dc                	lw	a5,4(a5)
    if(disk.info[id].status != 0)
    80006280:	20078713          	addi	a4,a5,512
    80006284:	0712                	slli	a4,a4,0x4
    80006286:	974a                	add	a4,a4,s2
    80006288:	03074703          	lbu	a4,48(a4)
    8000628c:	ef21                	bnez	a4,800062e4 <virtio_disk_intr+0xae>
    disk.info[id].b->disk = 0;   // disk is done with buf
    8000628e:	20078793          	addi	a5,a5,512
    80006292:	0792                	slli	a5,a5,0x4
    80006294:	97ca                	add	a5,a5,s2
    80006296:	7798                	ld	a4,40(a5)
    80006298:	00072223          	sw	zero,4(a4)
    wakeup(disk.info[id].b);
    8000629c:	7788                	ld	a0,40(a5)
    8000629e:	ffffc097          	auipc	ra,0xffffc
    800062a2:	156080e7          	jalr	342(ra) # 800023f4 <wakeup>
    disk.used_idx = (disk.used_idx + 1) % NUM;
    800062a6:	0204d783          	lhu	a5,32(s1)
    800062aa:	2785                	addiw	a5,a5,1
    800062ac:	8b9d                	andi	a5,a5,7
    800062ae:	02f49023          	sh	a5,32(s1)
  while((disk.used_idx % NUM) != (disk.used->id % NUM)){
    800062b2:	6898                	ld	a4,16(s1)
    800062b4:	00275683          	lhu	a3,2(a4)
    800062b8:	8a9d                	andi	a3,a3,7
    800062ba:	fcf690e3          	bne	a3,a5,8000627a <virtio_disk_intr+0x44>
  }
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800062be:	10001737          	lui	a4,0x10001
    800062c2:	533c                	lw	a5,96(a4)
    800062c4:	8b8d                	andi	a5,a5,3
    800062c6:	d37c                	sw	a5,100(a4)

  release(&disk.vdisk_lock);
    800062c8:	00024517          	auipc	a0,0x24
    800062cc:	de050513          	addi	a0,a0,-544 # 8002a0a8 <disk+0x20a8>
    800062d0:	ffffb097          	auipc	ra,0xffffb
    800062d4:	a68080e7          	jalr	-1432(ra) # 80000d38 <release>
}
    800062d8:	60e2                	ld	ra,24(sp)
    800062da:	6442                	ld	s0,16(sp)
    800062dc:	64a2                	ld	s1,8(sp)
    800062de:	6902                	ld	s2,0(sp)
    800062e0:	6105                	addi	sp,sp,32
    800062e2:	8082                	ret
      panic("virtio_disk_intr status");
    800062e4:	00002517          	auipc	a0,0x2
    800062e8:	53c50513          	addi	a0,a0,1340 # 80008820 <syscalls+0x3e0>
    800062ec:	ffffa097          	auipc	ra,0xffffa
    800062f0:	25c080e7          	jalr	604(ra) # 80000548 <panic>
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
