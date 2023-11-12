
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	94813103          	ld	sp,-1720(sp) # 80008948 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	fde70713          	addi	a4,a4,-34 # 80009030 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00006797          	auipc	a5,0x6
    80000068:	0dc78793          	addi	a5,a5,220 # 80006140 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd67d7>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	24478793          	addi	a5,a5,580 # 800012f2 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  timerinit();
    800000d8:	00000097          	auipc	ra,0x0
    800000dc:	f44080e7          	jalr	-188(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000e0:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000e4:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000e6:	823e                	mv	tp,a5
  asm volatile("mret");
    800000e8:	30200073          	mret
}
    800000ec:	60a2                	ld	ra,8(sp)
    800000ee:	6402                	ld	s0,0(sp)
    800000f0:	0141                	addi	sp,sp,16
    800000f2:	8082                	ret

00000000800000f4 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    800000f4:	715d                	addi	sp,sp,-80
    800000f6:	e486                	sd	ra,72(sp)
    800000f8:	e0a2                	sd	s0,64(sp)
    800000fa:	fc26                	sd	s1,56(sp)
    800000fc:	f84a                	sd	s2,48(sp)
    800000fe:	f44e                	sd	s3,40(sp)
    80000100:	f052                	sd	s4,32(sp)
    80000102:	ec56                	sd	s5,24(sp)
    80000104:	0880                	addi	s0,sp,80
    80000106:	8a2a                	mv	s4,a0
    80000108:	84ae                	mv	s1,a1
    8000010a:	89b2                	mv	s3,a2
  int i;

  acquire(&cons.lock);
    8000010c:	00011517          	auipc	a0,0x11
    80000110:	06450513          	addi	a0,a0,100 # 80011170 <cons>
    80000114:	00001097          	auipc	ra,0x1
    80000118:	c4c080e7          	jalr	-948(ra) # 80000d60 <acquire>
  for(i = 0; i < n; i++){
    8000011c:	05305b63          	blez	s3,80000172 <consolewrite+0x7e>
    80000120:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000122:	5afd                	li	s5,-1
    80000124:	4685                	li	a3,1
    80000126:	8626                	mv	a2,s1
    80000128:	85d2                	mv	a1,s4
    8000012a:	fbf40513          	addi	a0,s0,-65
    8000012e:	00002097          	auipc	ra,0x2
    80000132:	742080e7          	jalr	1858(ra) # 80002870 <either_copyin>
    80000136:	01550c63          	beq	a0,s5,8000014e <consolewrite+0x5a>
      break;
    uartputc(c);
    8000013a:	fbf44503          	lbu	a0,-65(s0)
    8000013e:	00000097          	auipc	ra,0x0
    80000142:	7aa080e7          	jalr	1962(ra) # 800008e8 <uartputc>
  for(i = 0; i < n; i++){
    80000146:	2905                	addiw	s2,s2,1
    80000148:	0485                	addi	s1,s1,1
    8000014a:	fd299de3          	bne	s3,s2,80000124 <consolewrite+0x30>
  }
  release(&cons.lock);
    8000014e:	00011517          	auipc	a0,0x11
    80000152:	02250513          	addi	a0,a0,34 # 80011170 <cons>
    80000156:	00001097          	auipc	ra,0x1
    8000015a:	cda080e7          	jalr	-806(ra) # 80000e30 <release>

  return i;
}
    8000015e:	854a                	mv	a0,s2
    80000160:	60a6                	ld	ra,72(sp)
    80000162:	6406                	ld	s0,64(sp)
    80000164:	74e2                	ld	s1,56(sp)
    80000166:	7942                	ld	s2,48(sp)
    80000168:	79a2                	ld	s3,40(sp)
    8000016a:	7a02                	ld	s4,32(sp)
    8000016c:	6ae2                	ld	s5,24(sp)
    8000016e:	6161                	addi	sp,sp,80
    80000170:	8082                	ret
  for(i = 0; i < n; i++){
    80000172:	4901                	li	s2,0
    80000174:	bfe9                	j	8000014e <consolewrite+0x5a>

0000000080000176 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000176:	7119                	addi	sp,sp,-128
    80000178:	fc86                	sd	ra,120(sp)
    8000017a:	f8a2                	sd	s0,112(sp)
    8000017c:	f4a6                	sd	s1,104(sp)
    8000017e:	f0ca                	sd	s2,96(sp)
    80000180:	ecce                	sd	s3,88(sp)
    80000182:	e8d2                	sd	s4,80(sp)
    80000184:	e4d6                	sd	s5,72(sp)
    80000186:	e0da                	sd	s6,64(sp)
    80000188:	fc5e                	sd	s7,56(sp)
    8000018a:	f862                	sd	s8,48(sp)
    8000018c:	f466                	sd	s9,40(sp)
    8000018e:	f06a                	sd	s10,32(sp)
    80000190:	ec6e                	sd	s11,24(sp)
    80000192:	0100                	addi	s0,sp,128
    80000194:	8b2a                	mv	s6,a0
    80000196:	8aae                	mv	s5,a1
    80000198:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000019a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000019e:	00011517          	auipc	a0,0x11
    800001a2:	fd250513          	addi	a0,a0,-46 # 80011170 <cons>
    800001a6:	00001097          	auipc	ra,0x1
    800001aa:	bba080e7          	jalr	-1094(ra) # 80000d60 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    800001ae:	00011497          	auipc	s1,0x11
    800001b2:	fc248493          	addi	s1,s1,-62 # 80011170 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001b6:	89a6                	mv	s3,s1
    800001b8:	00011917          	auipc	s2,0x11
    800001bc:	05890913          	addi	s2,s2,88 # 80011210 <cons+0xa0>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001c0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001c2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001c4:	4da9                	li	s11,10
  while(n > 0){
    800001c6:	07405863          	blez	s4,80000236 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001ca:	0a04a783          	lw	a5,160(s1)
    800001ce:	0a44a703          	lw	a4,164(s1)
    800001d2:	02f71463          	bne	a4,a5,800001fa <consoleread+0x84>
      if(myproc()->killed){
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	bd2080e7          	jalr	-1070(ra) # 80001da8 <myproc>
    800001de:	5d1c                	lw	a5,56(a0)
    800001e0:	e7b5                	bnez	a5,8000024c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001e2:	85ce                	mv	a1,s3
    800001e4:	854a                	mv	a0,s2
    800001e6:	00002097          	auipc	ra,0x2
    800001ea:	3d2080e7          	jalr	978(ra) # 800025b8 <sleep>
    while(cons.r == cons.w){
    800001ee:	0a04a783          	lw	a5,160(s1)
    800001f2:	0a44a703          	lw	a4,164(s1)
    800001f6:	fef700e3          	beq	a4,a5,800001d6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001fa:	0017871b          	addiw	a4,a5,1
    800001fe:	0ae4a023          	sw	a4,160(s1)
    80000202:	07f7f713          	andi	a4,a5,127
    80000206:	9726                	add	a4,a4,s1
    80000208:	02074703          	lbu	a4,32(a4)
    8000020c:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000210:	079c0663          	beq	s8,s9,8000027c <consoleread+0x106>
    cbuf = c;
    80000214:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000218:	4685                	li	a3,1
    8000021a:	f8f40613          	addi	a2,s0,-113
    8000021e:	85d6                	mv	a1,s5
    80000220:	855a                	mv	a0,s6
    80000222:	00002097          	auipc	ra,0x2
    80000226:	5f8080e7          	jalr	1528(ra) # 8000281a <either_copyout>
    8000022a:	01a50663          	beq	a0,s10,80000236 <consoleread+0xc0>
    dst++;
    8000022e:	0a85                	addi	s5,s5,1
    --n;
    80000230:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000232:	f9bc1ae3          	bne	s8,s11,800001c6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000236:	00011517          	auipc	a0,0x11
    8000023a:	f3a50513          	addi	a0,a0,-198 # 80011170 <cons>
    8000023e:	00001097          	auipc	ra,0x1
    80000242:	bf2080e7          	jalr	-1038(ra) # 80000e30 <release>

  return target - n;
    80000246:	414b853b          	subw	a0,s7,s4
    8000024a:	a811                	j	8000025e <consoleread+0xe8>
        release(&cons.lock);
    8000024c:	00011517          	auipc	a0,0x11
    80000250:	f2450513          	addi	a0,a0,-220 # 80011170 <cons>
    80000254:	00001097          	auipc	ra,0x1
    80000258:	bdc080e7          	jalr	-1060(ra) # 80000e30 <release>
        return -1;
    8000025c:	557d                	li	a0,-1
}
    8000025e:	70e6                	ld	ra,120(sp)
    80000260:	7446                	ld	s0,112(sp)
    80000262:	74a6                	ld	s1,104(sp)
    80000264:	7906                	ld	s2,96(sp)
    80000266:	69e6                	ld	s3,88(sp)
    80000268:	6a46                	ld	s4,80(sp)
    8000026a:	6aa6                	ld	s5,72(sp)
    8000026c:	6b06                	ld	s6,64(sp)
    8000026e:	7be2                	ld	s7,56(sp)
    80000270:	7c42                	ld	s8,48(sp)
    80000272:	7ca2                	ld	s9,40(sp)
    80000274:	7d02                	ld	s10,32(sp)
    80000276:	6de2                	ld	s11,24(sp)
    80000278:	6109                	addi	sp,sp,128
    8000027a:	8082                	ret
      if(n < target){
    8000027c:	000a071b          	sext.w	a4,s4
    80000280:	fb777be3          	bgeu	a4,s7,80000236 <consoleread+0xc0>
        cons.r--;
    80000284:	00011717          	auipc	a4,0x11
    80000288:	f8f72623          	sw	a5,-116(a4) # 80011210 <cons+0xa0>
    8000028c:	b76d                	j	80000236 <consoleread+0xc0>

000000008000028e <consputc>:
{
    8000028e:	1141                	addi	sp,sp,-16
    80000290:	e406                	sd	ra,8(sp)
    80000292:	e022                	sd	s0,0(sp)
    80000294:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000296:	10000793          	li	a5,256
    8000029a:	00f50a63          	beq	a0,a5,800002ae <consputc+0x20>
    uartputc_sync(c);
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	564080e7          	jalr	1380(ra) # 80000802 <uartputc_sync>
}
    800002a6:	60a2                	ld	ra,8(sp)
    800002a8:	6402                	ld	s0,0(sp)
    800002aa:	0141                	addi	sp,sp,16
    800002ac:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002ae:	4521                	li	a0,8
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	552080e7          	jalr	1362(ra) # 80000802 <uartputc_sync>
    800002b8:	02000513          	li	a0,32
    800002bc:	00000097          	auipc	ra,0x0
    800002c0:	546080e7          	jalr	1350(ra) # 80000802 <uartputc_sync>
    800002c4:	4521                	li	a0,8
    800002c6:	00000097          	auipc	ra,0x0
    800002ca:	53c080e7          	jalr	1340(ra) # 80000802 <uartputc_sync>
    800002ce:	bfe1                	j	800002a6 <consputc+0x18>

00000000800002d0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002d0:	1101                	addi	sp,sp,-32
    800002d2:	ec06                	sd	ra,24(sp)
    800002d4:	e822                	sd	s0,16(sp)
    800002d6:	e426                	sd	s1,8(sp)
    800002d8:	e04a                	sd	s2,0(sp)
    800002da:	1000                	addi	s0,sp,32
    800002dc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002de:	00011517          	auipc	a0,0x11
    800002e2:	e9250513          	addi	a0,a0,-366 # 80011170 <cons>
    800002e6:	00001097          	auipc	ra,0x1
    800002ea:	a7a080e7          	jalr	-1414(ra) # 80000d60 <acquire>

  switch(c){
    800002ee:	47d5                	li	a5,21
    800002f0:	0af48663          	beq	s1,a5,8000039c <consoleintr+0xcc>
    800002f4:	0297ca63          	blt	a5,s1,80000328 <consoleintr+0x58>
    800002f8:	47a1                	li	a5,8
    800002fa:	0ef48763          	beq	s1,a5,800003e8 <consoleintr+0x118>
    800002fe:	47c1                	li	a5,16
    80000300:	10f49a63          	bne	s1,a5,80000414 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    80000304:	00002097          	auipc	ra,0x2
    80000308:	5c2080e7          	jalr	1474(ra) # 800028c6 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    8000030c:	00011517          	auipc	a0,0x11
    80000310:	e6450513          	addi	a0,a0,-412 # 80011170 <cons>
    80000314:	00001097          	auipc	ra,0x1
    80000318:	b1c080e7          	jalr	-1252(ra) # 80000e30 <release>
}
    8000031c:	60e2                	ld	ra,24(sp)
    8000031e:	6442                	ld	s0,16(sp)
    80000320:	64a2                	ld	s1,8(sp)
    80000322:	6902                	ld	s2,0(sp)
    80000324:	6105                	addi	sp,sp,32
    80000326:	8082                	ret
  switch(c){
    80000328:	07f00793          	li	a5,127
    8000032c:	0af48e63          	beq	s1,a5,800003e8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000330:	00011717          	auipc	a4,0x11
    80000334:	e4070713          	addi	a4,a4,-448 # 80011170 <cons>
    80000338:	0a872783          	lw	a5,168(a4)
    8000033c:	0a072703          	lw	a4,160(a4)
    80000340:	9f99                	subw	a5,a5,a4
    80000342:	07f00713          	li	a4,127
    80000346:	fcf763e3          	bltu	a4,a5,8000030c <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000034a:	47b5                	li	a5,13
    8000034c:	0cf48763          	beq	s1,a5,8000041a <consoleintr+0x14a>
      consputc(c);
    80000350:	8526                	mv	a0,s1
    80000352:	00000097          	auipc	ra,0x0
    80000356:	f3c080e7          	jalr	-196(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000035a:	00011797          	auipc	a5,0x11
    8000035e:	e1678793          	addi	a5,a5,-490 # 80011170 <cons>
    80000362:	0a87a703          	lw	a4,168(a5)
    80000366:	0017069b          	addiw	a3,a4,1
    8000036a:	0006861b          	sext.w	a2,a3
    8000036e:	0ad7a423          	sw	a3,168(a5)
    80000372:	07f77713          	andi	a4,a4,127
    80000376:	97ba                	add	a5,a5,a4
    80000378:	02978023          	sb	s1,32(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000037c:	47a9                	li	a5,10
    8000037e:	0cf48563          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000382:	4791                	li	a5,4
    80000384:	0cf48263          	beq	s1,a5,80000448 <consoleintr+0x178>
    80000388:	00011797          	auipc	a5,0x11
    8000038c:	e887a783          	lw	a5,-376(a5) # 80011210 <cons+0xa0>
    80000390:	0807879b          	addiw	a5,a5,128
    80000394:	f6f61ce3          	bne	a2,a5,8000030c <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000398:	863e                	mv	a2,a5
    8000039a:	a07d                	j	80000448 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000039c:	00011717          	auipc	a4,0x11
    800003a0:	dd470713          	addi	a4,a4,-556 # 80011170 <cons>
    800003a4:	0a872783          	lw	a5,168(a4)
    800003a8:	0a472703          	lw	a4,164(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ac:	00011497          	auipc	s1,0x11
    800003b0:	dc448493          	addi	s1,s1,-572 # 80011170 <cons>
    while(cons.e != cons.w &&
    800003b4:	4929                	li	s2,10
    800003b6:	f4f70be3          	beq	a4,a5,8000030c <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    800003ba:	37fd                	addiw	a5,a5,-1
    800003bc:	07f7f713          	andi	a4,a5,127
    800003c0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003c2:	02074703          	lbu	a4,32(a4)
    800003c6:	f52703e3          	beq	a4,s2,8000030c <consoleintr+0x3c>
      cons.e--;
    800003ca:	0af4a423          	sw	a5,168(s1)
      consputc(BACKSPACE);
    800003ce:	10000513          	li	a0,256
    800003d2:	00000097          	auipc	ra,0x0
    800003d6:	ebc080e7          	jalr	-324(ra) # 8000028e <consputc>
    while(cons.e != cons.w &&
    800003da:	0a84a783          	lw	a5,168(s1)
    800003de:	0a44a703          	lw	a4,164(s1)
    800003e2:	fcf71ce3          	bne	a4,a5,800003ba <consoleintr+0xea>
    800003e6:	b71d                	j	8000030c <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003e8:	00011717          	auipc	a4,0x11
    800003ec:	d8870713          	addi	a4,a4,-632 # 80011170 <cons>
    800003f0:	0a872783          	lw	a5,168(a4)
    800003f4:	0a472703          	lw	a4,164(a4)
    800003f8:	f0f70ae3          	beq	a4,a5,8000030c <consoleintr+0x3c>
      cons.e--;
    800003fc:	37fd                	addiw	a5,a5,-1
    800003fe:	00011717          	auipc	a4,0x11
    80000402:	e0f72d23          	sw	a5,-486(a4) # 80011218 <cons+0xa8>
      consputc(BACKSPACE);
    80000406:	10000513          	li	a0,256
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e84080e7          	jalr	-380(ra) # 8000028e <consputc>
    80000412:	bded                	j	8000030c <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000414:	ee048ce3          	beqz	s1,8000030c <consoleintr+0x3c>
    80000418:	bf21                	j	80000330 <consoleintr+0x60>
      consputc(c);
    8000041a:	4529                	li	a0,10
    8000041c:	00000097          	auipc	ra,0x0
    80000420:	e72080e7          	jalr	-398(ra) # 8000028e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000424:	00011797          	auipc	a5,0x11
    80000428:	d4c78793          	addi	a5,a5,-692 # 80011170 <cons>
    8000042c:	0a87a703          	lw	a4,168(a5)
    80000430:	0017069b          	addiw	a3,a4,1
    80000434:	0006861b          	sext.w	a2,a3
    80000438:	0ad7a423          	sw	a3,168(a5)
    8000043c:	07f77713          	andi	a4,a4,127
    80000440:	97ba                	add	a5,a5,a4
    80000442:	4729                	li	a4,10
    80000444:	02e78023          	sb	a4,32(a5)
        cons.w = cons.e;
    80000448:	00011797          	auipc	a5,0x11
    8000044c:	dcc7a623          	sw	a2,-564(a5) # 80011214 <cons+0xa4>
        wakeup(&cons.r);
    80000450:	00011517          	auipc	a0,0x11
    80000454:	dc050513          	addi	a0,a0,-576 # 80011210 <cons+0xa0>
    80000458:	00002097          	auipc	ra,0x2
    8000045c:	2e6080e7          	jalr	742(ra) # 8000273e <wakeup>
    80000460:	b575                	j	8000030c <consoleintr+0x3c>

0000000080000462 <consoleinit>:

void
consoleinit(void)
{
    80000462:	1141                	addi	sp,sp,-16
    80000464:	e406                	sd	ra,8(sp)
    80000466:	e022                	sd	s0,0(sp)
    80000468:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000046a:	00008597          	auipc	a1,0x8
    8000046e:	ba658593          	addi	a1,a1,-1114 # 80008010 <etext+0x10>
    80000472:	00011517          	auipc	a0,0x11
    80000476:	cfe50513          	addi	a0,a0,-770 # 80011170 <cons>
    8000047a:	00001097          	auipc	ra,0x1
    8000047e:	a62080e7          	jalr	-1438(ra) # 80000edc <initlock>

  uartinit();
    80000482:	00000097          	auipc	ra,0x0
    80000486:	330080e7          	jalr	816(ra) # 800007b2 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000048a:	00022797          	auipc	a5,0x22
    8000048e:	48678793          	addi	a5,a5,1158 # 80022910 <devsw>
    80000492:	00000717          	auipc	a4,0x0
    80000496:	ce470713          	addi	a4,a4,-796 # 80000176 <consoleread>
    8000049a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000049c:	00000717          	auipc	a4,0x0
    800004a0:	c5870713          	addi	a4,a4,-936 # 800000f4 <consolewrite>
    800004a4:	ef98                	sd	a4,24(a5)
}
    800004a6:	60a2                	ld	ra,8(sp)
    800004a8:	6402                	ld	s0,0(sp)
    800004aa:	0141                	addi	sp,sp,16
    800004ac:	8082                	ret

00000000800004ae <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004ae:	7179                	addi	sp,sp,-48
    800004b0:	f406                	sd	ra,40(sp)
    800004b2:	f022                	sd	s0,32(sp)
    800004b4:	ec26                	sd	s1,24(sp)
    800004b6:	e84a                	sd	s2,16(sp)
    800004b8:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ba:	c219                	beqz	a2,800004c0 <printint+0x12>
    800004bc:	08054663          	bltz	a0,80000548 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004c0:	2501                	sext.w	a0,a0
    800004c2:	4881                	li	a7,0
    800004c4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004c8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004ca:	2581                	sext.w	a1,a1
    800004cc:	00008617          	auipc	a2,0x8
    800004d0:	b7460613          	addi	a2,a2,-1164 # 80008040 <digits>
    800004d4:	883a                	mv	a6,a4
    800004d6:	2705                	addiw	a4,a4,1
    800004d8:	02b577bb          	remuw	a5,a0,a1
    800004dc:	1782                	slli	a5,a5,0x20
    800004de:	9381                	srli	a5,a5,0x20
    800004e0:	97b2                	add	a5,a5,a2
    800004e2:	0007c783          	lbu	a5,0(a5)
    800004e6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ea:	0005079b          	sext.w	a5,a0
    800004ee:	02b5553b          	divuw	a0,a0,a1
    800004f2:	0685                	addi	a3,a3,1
    800004f4:	feb7f0e3          	bgeu	a5,a1,800004d4 <printint+0x26>

  if(sign)
    800004f8:	00088b63          	beqz	a7,8000050e <printint+0x60>
    buf[i++] = '-';
    800004fc:	fe040793          	addi	a5,s0,-32
    80000500:	973e                	add	a4,a4,a5
    80000502:	02d00793          	li	a5,45
    80000506:	fef70823          	sb	a5,-16(a4)
    8000050a:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    8000050e:	02e05763          	blez	a4,8000053c <printint+0x8e>
    80000512:	fd040793          	addi	a5,s0,-48
    80000516:	00e784b3          	add	s1,a5,a4
    8000051a:	fff78913          	addi	s2,a5,-1
    8000051e:	993a                	add	s2,s2,a4
    80000520:	377d                	addiw	a4,a4,-1
    80000522:	1702                	slli	a4,a4,0x20
    80000524:	9301                	srli	a4,a4,0x20
    80000526:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000052a:	fff4c503          	lbu	a0,-1(s1)
    8000052e:	00000097          	auipc	ra,0x0
    80000532:	d60080e7          	jalr	-672(ra) # 8000028e <consputc>
  while(--i >= 0)
    80000536:	14fd                	addi	s1,s1,-1
    80000538:	ff2499e3          	bne	s1,s2,8000052a <printint+0x7c>
}
    8000053c:	70a2                	ld	ra,40(sp)
    8000053e:	7402                	ld	s0,32(sp)
    80000540:	64e2                	ld	s1,24(sp)
    80000542:	6942                	ld	s2,16(sp)
    80000544:	6145                	addi	sp,sp,48
    80000546:	8082                	ret
    x = -xx;
    80000548:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000054c:	4885                	li	a7,1
    x = -xx;
    8000054e:	bf9d                	j	800004c4 <printint+0x16>

0000000080000550 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000550:	1101                	addi	sp,sp,-32
    80000552:	ec06                	sd	ra,24(sp)
    80000554:	e822                	sd	s0,16(sp)
    80000556:	e426                	sd	s1,8(sp)
    80000558:	1000                	addi	s0,sp,32
    8000055a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000055c:	00011797          	auipc	a5,0x11
    80000560:	ce07a223          	sw	zero,-796(a5) # 80011240 <pr+0x20>
  printf("panic: ");
    80000564:	00008517          	auipc	a0,0x8
    80000568:	ab450513          	addi	a0,a0,-1356 # 80008018 <etext+0x18>
    8000056c:	00000097          	auipc	ra,0x0
    80000570:	02e080e7          	jalr	46(ra) # 8000059a <printf>
  printf(s);
    80000574:	8526                	mv	a0,s1
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	024080e7          	jalr	36(ra) # 8000059a <printf>
  printf("\n");
    8000057e:	00008517          	auipc	a0,0x8
    80000582:	be250513          	addi	a0,a0,-1054 # 80008160 <digits+0x120>
    80000586:	00000097          	auipc	ra,0x0
    8000058a:	014080e7          	jalr	20(ra) # 8000059a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000058e:	4785                	li	a5,1
    80000590:	00009717          	auipc	a4,0x9
    80000594:	a6f72823          	sw	a5,-1424(a4) # 80009000 <panicked>
  for(;;)
    80000598:	a001                	j	80000598 <panic+0x48>

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
    800005d0:	c74dad83          	lw	s11,-908(s11) # 80011240 <pr+0x20>
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
    800005fc:	a48b8b93          	addi	s7,s7,-1464 # 80008040 <digits>
    switch(c){
    80000600:	07300c93          	li	s9,115
    80000604:	06400c13          	li	s8,100
    80000608:	a82d                	j	80000642 <printf+0xa8>
    acquire(&pr.lock);
    8000060a:	00011517          	auipc	a0,0x11
    8000060e:	c1650513          	addi	a0,a0,-1002 # 80011220 <pr>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	74e080e7          	jalr	1870(ra) # 80000d60 <acquire>
    8000061a:	bf7d                	j	800005d8 <printf+0x3e>
    panic("null fmt");
    8000061c:	00008517          	auipc	a0,0x8
    80000620:	a0c50513          	addi	a0,a0,-1524 # 80008028 <etext+0x28>
    80000624:	00000097          	auipc	ra,0x0
    80000628:	f2c080e7          	jalr	-212(ra) # 80000550 <panic>
      consputc(c);
    8000062c:	00000097          	auipc	ra,0x0
    80000630:	c62080e7          	jalr	-926(ra) # 8000028e <consputc>
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
    80000680:	e32080e7          	jalr	-462(ra) # 800004ae <printint>
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
    800006a4:	e0e080e7          	jalr	-498(ra) # 800004ae <printint>
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
    800006c2:	bd0080e7          	jalr	-1072(ra) # 8000028e <consputc>
  consputc('x');
    800006c6:	07800513          	li	a0,120
    800006ca:	00000097          	auipc	ra,0x0
    800006ce:	bc4080e7          	jalr	-1084(ra) # 8000028e <consputc>
    800006d2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006d4:	03c9d793          	srli	a5,s3,0x3c
    800006d8:	97de                	add	a5,a5,s7
    800006da:	0007c503          	lbu	a0,0(a5)
    800006de:	00000097          	auipc	ra,0x0
    800006e2:	bb0080e7          	jalr	-1104(ra) # 8000028e <consputc>
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
    8000070e:	b84080e7          	jalr	-1148(ra) # 8000028e <consputc>
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
    80000730:	b62080e7          	jalr	-1182(ra) # 8000028e <consputc>
      break;
    80000734:	b701                	j	80000634 <printf+0x9a>
      consputc('%');
    80000736:	8556                	mv	a0,s5
    80000738:	00000097          	auipc	ra,0x0
    8000073c:	b56080e7          	jalr	-1194(ra) # 8000028e <consputc>
      consputc(c);
    80000740:	854a                	mv	a0,s2
    80000742:	00000097          	auipc	ra,0x0
    80000746:	b4c080e7          	jalr	-1204(ra) # 8000028e <consputc>
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
    80000772:	ab250513          	addi	a0,a0,-1358 # 80011220 <pr>
    80000776:	00000097          	auipc	ra,0x0
    8000077a:	6ba080e7          	jalr	1722(ra) # 80000e30 <release>
}
    8000077e:	bfc9                	j	80000750 <printf+0x1b6>

0000000080000780 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000780:	1101                	addi	sp,sp,-32
    80000782:	ec06                	sd	ra,24(sp)
    80000784:	e822                	sd	s0,16(sp)
    80000786:	e426                	sd	s1,8(sp)
    80000788:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000078a:	00011497          	auipc	s1,0x11
    8000078e:	a9648493          	addi	s1,s1,-1386 # 80011220 <pr>
    80000792:	00008597          	auipc	a1,0x8
    80000796:	8a658593          	addi	a1,a1,-1882 # 80008038 <etext+0x38>
    8000079a:	8526                	mv	a0,s1
    8000079c:	00000097          	auipc	ra,0x0
    800007a0:	740080e7          	jalr	1856(ra) # 80000edc <initlock>
  pr.locking = 1;
    800007a4:	4785                	li	a5,1
    800007a6:	d09c                	sw	a5,32(s1)
}
    800007a8:	60e2                	ld	ra,24(sp)
    800007aa:	6442                	ld	s0,16(sp)
    800007ac:	64a2                	ld	s1,8(sp)
    800007ae:	6105                	addi	sp,sp,32
    800007b0:	8082                	ret

00000000800007b2 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007b2:	1141                	addi	sp,sp,-16
    800007b4:	e406                	sd	ra,8(sp)
    800007b6:	e022                	sd	s0,0(sp)
    800007b8:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ba:	100007b7          	lui	a5,0x10000
    800007be:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007c2:	f8000713          	li	a4,-128
    800007c6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007ca:	470d                	li	a4,3
    800007cc:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007d0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007d4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007d8:	469d                	li	a3,7
    800007da:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007de:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007e2:	00008597          	auipc	a1,0x8
    800007e6:	87658593          	addi	a1,a1,-1930 # 80008058 <digits+0x18>
    800007ea:	00011517          	auipc	a0,0x11
    800007ee:	a5e50513          	addi	a0,a0,-1442 # 80011248 <uart_tx_lock>
    800007f2:	00000097          	auipc	ra,0x0
    800007f6:	6ea080e7          	jalr	1770(ra) # 80000edc <initlock>
}
    800007fa:	60a2                	ld	ra,8(sp)
    800007fc:	6402                	ld	s0,0(sp)
    800007fe:	0141                	addi	sp,sp,16
    80000800:	8082                	ret

0000000080000802 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    80000802:	1101                	addi	sp,sp,-32
    80000804:	ec06                	sd	ra,24(sp)
    80000806:	e822                	sd	s0,16(sp)
    80000808:	e426                	sd	s1,8(sp)
    8000080a:	1000                	addi	s0,sp,32
    8000080c:	84aa                	mv	s1,a0
  push_off();
    8000080e:	00000097          	auipc	ra,0x0
    80000812:	506080e7          	jalr	1286(ra) # 80000d14 <push_off>

  if(panicked){
    80000816:	00008797          	auipc	a5,0x8
    8000081a:	7ea7a783          	lw	a5,2026(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081e:	10000737          	lui	a4,0x10000
  if(panicked){
    80000822:	c391                	beqz	a5,80000826 <uartputc_sync+0x24>
    for(;;)
    80000824:	a001                	j	80000824 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000826:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000082a:	0ff7f793          	andi	a5,a5,255
    8000082e:	0207f793          	andi	a5,a5,32
    80000832:	dbf5                	beqz	a5,80000826 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000834:	0ff4f793          	andi	a5,s1,255
    80000838:	10000737          	lui	a4,0x10000
    8000083c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000840:	00000097          	auipc	ra,0x0
    80000844:	590080e7          	jalr	1424(ra) # 80000dd0 <pop_off>
}
    80000848:	60e2                	ld	ra,24(sp)
    8000084a:	6442                	ld	s0,16(sp)
    8000084c:	64a2                	ld	s1,8(sp)
    8000084e:	6105                	addi	sp,sp,32
    80000850:	8082                	ret

0000000080000852 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000852:	00008797          	auipc	a5,0x8
    80000856:	7b27a783          	lw	a5,1970(a5) # 80009004 <uart_tx_r>
    8000085a:	00008717          	auipc	a4,0x8
    8000085e:	7ae72703          	lw	a4,1966(a4) # 80009008 <uart_tx_w>
    80000862:	08f70263          	beq	a4,a5,800008e6 <uartstart+0x94>
{
    80000866:	7139                	addi	sp,sp,-64
    80000868:	fc06                	sd	ra,56(sp)
    8000086a:	f822                	sd	s0,48(sp)
    8000086c:	f426                	sd	s1,40(sp)
    8000086e:	f04a                	sd	s2,32(sp)
    80000870:	ec4e                	sd	s3,24(sp)
    80000872:	e852                	sd	s4,16(sp)
    80000874:	e456                	sd	s5,8(sp)
    80000876:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000878:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r];
    8000087c:	00011a17          	auipc	s4,0x11
    80000880:	9cca0a13          	addi	s4,s4,-1588 # 80011248 <uart_tx_lock>
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    80000884:	00008497          	auipc	s1,0x8
    80000888:	78048493          	addi	s1,s1,1920 # 80009004 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000088c:	00008997          	auipc	s3,0x8
    80000890:	77c98993          	addi	s3,s3,1916 # 80009008 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000894:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000898:	0ff77713          	andi	a4,a4,255
    8000089c:	02077713          	andi	a4,a4,32
    800008a0:	cb15                	beqz	a4,800008d4 <uartstart+0x82>
    int c = uart_tx_buf[uart_tx_r];
    800008a2:	00fa0733          	add	a4,s4,a5
    800008a6:	02074a83          	lbu	s5,32(a4)
    uart_tx_r = (uart_tx_r + 1) % UART_TX_BUF_SIZE;
    800008aa:	2785                	addiw	a5,a5,1
    800008ac:	41f7d71b          	sraiw	a4,a5,0x1f
    800008b0:	01b7571b          	srliw	a4,a4,0x1b
    800008b4:	9fb9                	addw	a5,a5,a4
    800008b6:	8bfd                	andi	a5,a5,31
    800008b8:	9f99                	subw	a5,a5,a4
    800008ba:	c09c                	sw	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008bc:	8526                	mv	a0,s1
    800008be:	00002097          	auipc	ra,0x2
    800008c2:	e80080e7          	jalr	-384(ra) # 8000273e <wakeup>
    
    WriteReg(THR, c);
    800008c6:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ca:	409c                	lw	a5,0(s1)
    800008cc:	0009a703          	lw	a4,0(s3)
    800008d0:	fcf712e3          	bne	a4,a5,80000894 <uartstart+0x42>
  }
}
    800008d4:	70e2                	ld	ra,56(sp)
    800008d6:	7442                	ld	s0,48(sp)
    800008d8:	74a2                	ld	s1,40(sp)
    800008da:	7902                	ld	s2,32(sp)
    800008dc:	69e2                	ld	s3,24(sp)
    800008de:	6a42                	ld	s4,16(sp)
    800008e0:	6aa2                	ld	s5,8(sp)
    800008e2:	6121                	addi	sp,sp,64
    800008e4:	8082                	ret
    800008e6:	8082                	ret

00000000800008e8 <uartputc>:
{
    800008e8:	7179                	addi	sp,sp,-48
    800008ea:	f406                	sd	ra,40(sp)
    800008ec:	f022                	sd	s0,32(sp)
    800008ee:	ec26                	sd	s1,24(sp)
    800008f0:	e84a                	sd	s2,16(sp)
    800008f2:	e44e                	sd	s3,8(sp)
    800008f4:	e052                	sd	s4,0(sp)
    800008f6:	1800                	addi	s0,sp,48
    800008f8:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008fa:	00011517          	auipc	a0,0x11
    800008fe:	94e50513          	addi	a0,a0,-1714 # 80011248 <uart_tx_lock>
    80000902:	00000097          	auipc	ra,0x0
    80000906:	45e080e7          	jalr	1118(ra) # 80000d60 <acquire>
  if(panicked){
    8000090a:	00008797          	auipc	a5,0x8
    8000090e:	6f67a783          	lw	a5,1782(a5) # 80009000 <panicked>
    80000912:	c391                	beqz	a5,80000916 <uartputc+0x2e>
    for(;;)
    80000914:	a001                	j	80000914 <uartputc+0x2c>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000916:	00008717          	auipc	a4,0x8
    8000091a:	6f272703          	lw	a4,1778(a4) # 80009008 <uart_tx_w>
    8000091e:	0017079b          	addiw	a5,a4,1
    80000922:	41f7d69b          	sraiw	a3,a5,0x1f
    80000926:	01b6d69b          	srliw	a3,a3,0x1b
    8000092a:	9fb5                	addw	a5,a5,a3
    8000092c:	8bfd                	andi	a5,a5,31
    8000092e:	9f95                	subw	a5,a5,a3
    80000930:	00008697          	auipc	a3,0x8
    80000934:	6d46a683          	lw	a3,1748(a3) # 80009004 <uart_tx_r>
    80000938:	04f69263          	bne	a3,a5,8000097c <uartputc+0x94>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000093c:	00011a17          	auipc	s4,0x11
    80000940:	90ca0a13          	addi	s4,s4,-1780 # 80011248 <uart_tx_lock>
    80000944:	00008497          	auipc	s1,0x8
    80000948:	6c048493          	addi	s1,s1,1728 # 80009004 <uart_tx_r>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    8000094c:	00008917          	auipc	s2,0x8
    80000950:	6bc90913          	addi	s2,s2,1724 # 80009008 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000954:	85d2                	mv	a1,s4
    80000956:	8526                	mv	a0,s1
    80000958:	00002097          	auipc	ra,0x2
    8000095c:	c60080e7          	jalr	-928(ra) # 800025b8 <sleep>
    if(((uart_tx_w + 1) % UART_TX_BUF_SIZE) == uart_tx_r){
    80000960:	00092703          	lw	a4,0(s2)
    80000964:	0017079b          	addiw	a5,a4,1
    80000968:	41f7d69b          	sraiw	a3,a5,0x1f
    8000096c:	01b6d69b          	srliw	a3,a3,0x1b
    80000970:	9fb5                	addw	a5,a5,a3
    80000972:	8bfd                	andi	a5,a5,31
    80000974:	9f95                	subw	a5,a5,a3
    80000976:	4094                	lw	a3,0(s1)
    80000978:	fcf68ee3          	beq	a3,a5,80000954 <uartputc+0x6c>
      uart_tx_buf[uart_tx_w] = c;
    8000097c:	00011497          	auipc	s1,0x11
    80000980:	8cc48493          	addi	s1,s1,-1844 # 80011248 <uart_tx_lock>
    80000984:	9726                	add	a4,a4,s1
    80000986:	03370023          	sb	s3,32(a4)
      uart_tx_w = (uart_tx_w + 1) % UART_TX_BUF_SIZE;
    8000098a:	00008717          	auipc	a4,0x8
    8000098e:	66f72f23          	sw	a5,1662(a4) # 80009008 <uart_tx_w>
      uartstart();
    80000992:	00000097          	auipc	ra,0x0
    80000996:	ec0080e7          	jalr	-320(ra) # 80000852 <uartstart>
      release(&uart_tx_lock);
    8000099a:	8526                	mv	a0,s1
    8000099c:	00000097          	auipc	ra,0x0
    800009a0:	494080e7          	jalr	1172(ra) # 80000e30 <release>
}
    800009a4:	70a2                	ld	ra,40(sp)
    800009a6:	7402                	ld	s0,32(sp)
    800009a8:	64e2                	ld	s1,24(sp)
    800009aa:	6942                	ld	s2,16(sp)
    800009ac:	69a2                	ld	s3,8(sp)
    800009ae:	6a02                	ld	s4,0(sp)
    800009b0:	6145                	addi	sp,sp,48
    800009b2:	8082                	ret

00000000800009b4 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    800009b4:	1141                	addi	sp,sp,-16
    800009b6:	e422                	sd	s0,8(sp)
    800009b8:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    800009ba:	100007b7          	lui	a5,0x10000
    800009be:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    800009c2:	8b85                	andi	a5,a5,1
    800009c4:	cb91                	beqz	a5,800009d8 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    800009c6:	100007b7          	lui	a5,0x10000
    800009ca:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009ce:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009d2:	6422                	ld	s0,8(sp)
    800009d4:	0141                	addi	sp,sp,16
    800009d6:	8082                	ret
    return -1;
    800009d8:	557d                	li	a0,-1
    800009da:	bfe5                	j	800009d2 <uartgetc+0x1e>

00000000800009dc <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009dc:	1101                	addi	sp,sp,-32
    800009de:	ec06                	sd	ra,24(sp)
    800009e0:	e822                	sd	s0,16(sp)
    800009e2:	e426                	sd	s1,8(sp)
    800009e4:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009e6:	54fd                	li	s1,-1
    int c = uartgetc();
    800009e8:	00000097          	auipc	ra,0x0
    800009ec:	fcc080e7          	jalr	-52(ra) # 800009b4 <uartgetc>
    if(c == -1)
    800009f0:	00950763          	beq	a0,s1,800009fe <uartintr+0x22>
      break;
    consoleintr(c);
    800009f4:	00000097          	auipc	ra,0x0
    800009f8:	8dc080e7          	jalr	-1828(ra) # 800002d0 <consoleintr>
  while(1){
    800009fc:	b7f5                	j	800009e8 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009fe:	00011497          	auipc	s1,0x11
    80000a02:	84a48493          	addi	s1,s1,-1974 # 80011248 <uart_tx_lock>
    80000a06:	8526                	mv	a0,s1
    80000a08:	00000097          	auipc	ra,0x0
    80000a0c:	358080e7          	jalr	856(ra) # 80000d60 <acquire>
  uartstart();
    80000a10:	00000097          	auipc	ra,0x0
    80000a14:	e42080e7          	jalr	-446(ra) # 80000852 <uartstart>
  release(&uart_tx_lock);
    80000a18:	8526                	mv	a0,s1
    80000a1a:	00000097          	auipc	ra,0x0
    80000a1e:	416080e7          	jalr	1046(ra) # 80000e30 <release>
}
    80000a22:	60e2                	ld	ra,24(sp)
    80000a24:	6442                	ld	s0,16(sp)
    80000a26:	64a2                	ld	s1,8(sp)
    80000a28:	6105                	addi	sp,sp,32
    80000a2a:	8082                	ret

0000000080000a2c <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000a2c:	7139                	addi	sp,sp,-64
    80000a2e:	fc06                	sd	ra,56(sp)
    80000a30:	f822                	sd	s0,48(sp)
    80000a32:	f426                	sd	s1,40(sp)
    80000a34:	f04a                	sd	s2,32(sp)
    80000a36:	ec4e                	sd	s3,24(sp)
    80000a38:	e852                	sd	s4,16(sp)
    80000a3a:	e456                	sd	s5,8(sp)
    80000a3c:	0080                	addi	s0,sp,64
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a3e:	03451793          	slli	a5,a0,0x34
    80000a42:	e3c1                	bnez	a5,80000ac2 <kfree+0x96>
    80000a44:	84aa                	mv	s1,a0
    80000a46:	00027797          	auipc	a5,0x27
    80000a4a:	5e278793          	addi	a5,a5,1506 # 80028028 <end>
    80000a4e:	06f56a63          	bltu	a0,a5,80000ac2 <kfree+0x96>
    80000a52:	47c5                	li	a5,17
    80000a54:	07ee                	slli	a5,a5,0x1b
    80000a56:	06f57663          	bgeu	a0,a5,80000ac2 <kfree+0x96>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a5a:	6605                	lui	a2,0x1
    80000a5c:	4585                	li	a1,1
    80000a5e:	00000097          	auipc	ra,0x0
    80000a62:	6e2080e7          	jalr	1762(ra) # 80001140 <memset>

  r = (struct run*)pa;

  // get hartid
  push_off();
    80000a66:	00000097          	auipc	ra,0x0
    80000a6a:	2ae080e7          	jalr	686(ra) # 80000d14 <push_off>
  int i = cpuid();
    80000a6e:	00001097          	auipc	ra,0x1
    80000a72:	30e080e7          	jalr	782(ra) # 80001d7c <cpuid>

  acquire(&kmem[i].lock);
    80000a76:	00011a97          	auipc	s5,0x11
    80000a7a:	812a8a93          	addi	s5,s5,-2030 # 80011288 <kmem>
    80000a7e:	00251993          	slli	s3,a0,0x2
    80000a82:	00a98933          	add	s2,s3,a0
    80000a86:	090e                	slli	s2,s2,0x3
    80000a88:	9956                	add	s2,s2,s5
    80000a8a:	854a                	mv	a0,s2
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	2d4080e7          	jalr	724(ra) # 80000d60 <acquire>
  r->next = kmem[i].freelist;
    80000a94:	02093783          	ld	a5,32(s2)
    80000a98:	e09c                	sd	a5,0(s1)
  kmem[i].freelist = r;
    80000a9a:	02993023          	sd	s1,32(s2)
  release(&kmem[i].lock);
    80000a9e:	854a                	mv	a0,s2
    80000aa0:	00000097          	auipc	ra,0x0
    80000aa4:	390080e7          	jalr	912(ra) # 80000e30 <release>
  pop_off();
    80000aa8:	00000097          	auipc	ra,0x0
    80000aac:	328080e7          	jalr	808(ra) # 80000dd0 <pop_off>
}
    80000ab0:	70e2                	ld	ra,56(sp)
    80000ab2:	7442                	ld	s0,48(sp)
    80000ab4:	74a2                	ld	s1,40(sp)
    80000ab6:	7902                	ld	s2,32(sp)
    80000ab8:	69e2                	ld	s3,24(sp)
    80000aba:	6a42                	ld	s4,16(sp)
    80000abc:	6aa2                	ld	s5,8(sp)
    80000abe:	6121                	addi	sp,sp,64
    80000ac0:	8082                	ret
    panic("kfree");
    80000ac2:	00007517          	auipc	a0,0x7
    80000ac6:	59e50513          	addi	a0,a0,1438 # 80008060 <digits+0x20>
    80000aca:	00000097          	auipc	ra,0x0
    80000ace:	a86080e7          	jalr	-1402(ra) # 80000550 <panic>

0000000080000ad2 <freerange>:
{
    80000ad2:	7179                	addi	sp,sp,-48
    80000ad4:	f406                	sd	ra,40(sp)
    80000ad6:	f022                	sd	s0,32(sp)
    80000ad8:	ec26                	sd	s1,24(sp)
    80000ada:	e84a                	sd	s2,16(sp)
    80000adc:	e44e                	sd	s3,8(sp)
    80000ade:	e052                	sd	s4,0(sp)
    80000ae0:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000ae2:	6785                	lui	a5,0x1
    80000ae4:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000ae8:	94aa                	add	s1,s1,a0
    80000aea:	757d                	lui	a0,0xfffff
    80000aec:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aee:	94be                	add	s1,s1,a5
    80000af0:	0095ee63          	bltu	a1,s1,80000b0c <freerange+0x3a>
    80000af4:	892e                	mv	s2,a1
    kfree(p);
    80000af6:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000af8:	6985                	lui	s3,0x1
    kfree(p);
    80000afa:	01448533          	add	a0,s1,s4
    80000afe:	00000097          	auipc	ra,0x0
    80000b02:	f2e080e7          	jalr	-210(ra) # 80000a2c <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000b06:	94ce                	add	s1,s1,s3
    80000b08:	fe9979e3          	bgeu	s2,s1,80000afa <freerange+0x28>
}
    80000b0c:	70a2                	ld	ra,40(sp)
    80000b0e:	7402                	ld	s0,32(sp)
    80000b10:	64e2                	ld	s1,24(sp)
    80000b12:	6942                	ld	s2,16(sp)
    80000b14:	69a2                	ld	s3,8(sp)
    80000b16:	6a02                	ld	s4,0(sp)
    80000b18:	6145                	addi	sp,sp,48
    80000b1a:	8082                	ret

0000000080000b1c <kinit>:
{
    80000b1c:	7179                	addi	sp,sp,-48
    80000b1e:	f406                	sd	ra,40(sp)
    80000b20:	f022                	sd	s0,32(sp)
    80000b22:	ec26                	sd	s1,24(sp)
    80000b24:	e84a                	sd	s2,16(sp)
    80000b26:	e44e                	sd	s3,8(sp)
    80000b28:	1800                	addi	s0,sp,48
  for (int i = 0; i < NCPU; i++)
    80000b2a:	00010497          	auipc	s1,0x10
    80000b2e:	75e48493          	addi	s1,s1,1886 # 80011288 <kmem>
    80000b32:	00008917          	auipc	s2,0x8
    80000b36:	d9e90913          	addi	s2,s2,-610 # 800088d0 <names>
    80000b3a:	00011997          	auipc	s3,0x11
    80000b3e:	88e98993          	addi	s3,s3,-1906 # 800113c8 <lock_locks>
    initlock(&kmem[i].lock, names[i]);
    80000b42:	85ca                	mv	a1,s2
    80000b44:	8526                	mv	a0,s1
    80000b46:	00000097          	auipc	ra,0x0
    80000b4a:	396080e7          	jalr	918(ra) # 80000edc <initlock>
  for (int i = 0; i < NCPU; i++)
    80000b4e:	02848493          	addi	s1,s1,40
    80000b52:	091d                	addi	s2,s2,7
    80000b54:	ff3497e3          	bne	s1,s3,80000b42 <kinit+0x26>
  freerange(end, (void*)PHYSTOP);
    80000b58:	45c5                	li	a1,17
    80000b5a:	05ee                	slli	a1,a1,0x1b
    80000b5c:	00027517          	auipc	a0,0x27
    80000b60:	4cc50513          	addi	a0,a0,1228 # 80028028 <end>
    80000b64:	00000097          	auipc	ra,0x0
    80000b68:	f6e080e7          	jalr	-146(ra) # 80000ad2 <freerange>
}
    80000b6c:	70a2                	ld	ra,40(sp)
    80000b6e:	7402                	ld	s0,32(sp)
    80000b70:	64e2                	ld	s1,24(sp)
    80000b72:	6942                	ld	s2,16(sp)
    80000b74:	69a2                	ld	s3,8(sp)
    80000b76:	6145                	addi	sp,sp,48
    80000b78:	8082                	ret

0000000080000b7a <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000b7a:	7139                	addi	sp,sp,-64
    80000b7c:	fc06                	sd	ra,56(sp)
    80000b7e:	f822                	sd	s0,48(sp)
    80000b80:	f426                	sd	s1,40(sp)
    80000b82:	f04a                	sd	s2,32(sp)
    80000b84:	ec4e                	sd	s3,24(sp)
    80000b86:	e852                	sd	s4,16(sp)
    80000b88:	e456                	sd	s5,8(sp)
    80000b8a:	e05a                	sd	s6,0(sp)
    80000b8c:	0080                	addi	s0,sp,64
  struct run *r, *r_other, *p;
  int len, steal, remain, ok;

  // get hartid
  push_off();
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	186080e7          	jalr	390(ra) # 80000d14 <push_off>
  int i = cpuid();
    80000b96:	00001097          	auipc	ra,0x1
    80000b9a:	1e6080e7          	jalr	486(ra) # 80001d7c <cpuid>
    80000b9e:	8a2a                	mv	s4,a0

  acquire(&kmem[i].lock);
    80000ba0:	00251a93          	slli	s5,a0,0x2
    80000ba4:	9aaa                	add	s5,s5,a0
    80000ba6:	003a9793          	slli	a5,s5,0x3
    80000baa:	00010a97          	auipc	s5,0x10
    80000bae:	6dea8a93          	addi	s5,s5,1758 # 80011288 <kmem>
    80000bb2:	9abe                	add	s5,s5,a5
    80000bb4:	8556                	mv	a0,s5
    80000bb6:	00000097          	auipc	ra,0x0
    80000bba:	1aa080e7          	jalr	426(ra) # 80000d60 <acquire>
  r = kmem[i].freelist;
    80000bbe:	020abb03          	ld	s6,32(s5)
  if(r)
    80000bc2:	020b0063          	beqz	s6,80000be2 <kalloc+0x68>
    kmem[i].freelist = r->next;
    80000bc6:	000b3703          	ld	a4,0(s6)
    80000bca:	02eab023          	sd	a4,32(s5)
        release(&kmem[j].lock);
        if (ok)
          break;
    }
  }
  release(&kmem[i].lock);
    80000bce:	8556                	mv	a0,s5
    80000bd0:	00000097          	auipc	ra,0x0
    80000bd4:	260080e7          	jalr	608(ra) # 80000e30 <release>
  pop_off(); 
    80000bd8:	00000097          	auipc	ra,0x0
    80000bdc:	1f8080e7          	jalr	504(ra) # 80000dd0 <pop_off>

  if(r)
    80000be0:	a885                	j	80000c50 <kalloc+0xd6>
    for (int j = i + 1; j != i; j = (j + 1) % NCPU)
    80000be2:	001a091b          	addiw	s2,s4,1
        acquire(&kmem[j].lock);
    80000be6:	00010b17          	auipc	s6,0x10
    80000bea:	6a2b0b13          	addi	s6,s6,1698 # 80011288 <kmem>
    80000bee:	a06d                	j	80000c98 <kalloc+0x11e>
          for (; steal > 0; steal--)
    80000bf0:	37fd                	addiw	a5,a5,-1
    80000bf2:	c799                	beqz	a5,80000c00 <kalloc+0x86>
            p = r_other->next;
    80000bf4:	8726                	mv	a4,s1
    80000bf6:	6084                	ld	s1,0(s1)
            if (steal == 1)
    80000bf8:	fed79ce3          	bne	a5,a3,80000bf0 <kalloc+0x76>
              r_other->next = 0;
    80000bfc:	00073023          	sd	zero,0(a4)
          r = kmem[j].freelist;
    80000c00:	00010717          	auipc	a4,0x10
    80000c04:	68870713          	addi	a4,a4,1672 # 80011288 <kmem>
    80000c08:	00291793          	slli	a5,s2,0x2
    80000c0c:	012786b3          	add	a3,a5,s2
    80000c10:	068e                	slli	a3,a3,0x3
    80000c12:	96ba                	add	a3,a3,a4
    80000c14:	0206bb03          	ld	s6,32(a3)
          kmem[i].freelist = r->next;
    80000c18:	000b3683          	ld	a3,0(s6)
    80000c1c:	002a1513          	slli	a0,s4,0x2
    80000c20:	9a2a                	add	s4,s4,a0
    80000c22:	0a0e                	slli	s4,s4,0x3
    80000c24:	9a3a                	add	s4,s4,a4
    80000c26:	02da3023          	sd	a3,32(s4) # fffffffffffff020 <end+0xffffffff7ffd6ff8>
          kmem[j].freelist = r_other;
    80000c2a:	993e                	add	s2,s2,a5
    80000c2c:	090e                	slli	s2,s2,0x3
    80000c2e:	993a                	add	s2,s2,a4
    80000c30:	02993023          	sd	s1,32(s2)
        release(&kmem[j].lock);
    80000c34:	854e                	mv	a0,s3
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	1fa080e7          	jalr	506(ra) # 80000e30 <release>
  release(&kmem[i].lock);
    80000c3e:	8556                	mv	a0,s5
    80000c40:	00000097          	auipc	ra,0x0
    80000c44:	1f0080e7          	jalr	496(ra) # 80000e30 <release>
  pop_off(); 
    80000c48:	00000097          	auipc	ra,0x0
    80000c4c:	188080e7          	jalr	392(ra) # 80000dd0 <pop_off>
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000c50:	6605                	lui	a2,0x1
    80000c52:	4595                	li	a1,5
    80000c54:	855a                	mv	a0,s6
    80000c56:	00000097          	auipc	ra,0x0
    80000c5a:	4ea080e7          	jalr	1258(ra) # 80001140 <memset>
  return (void*)r;
}
    80000c5e:	855a                	mv	a0,s6
    80000c60:	70e2                	ld	ra,56(sp)
    80000c62:	7442                	ld	s0,48(sp)
    80000c64:	74a2                	ld	s1,40(sp)
    80000c66:	7902                	ld	s2,32(sp)
    80000c68:	69e2                	ld	s3,24(sp)
    80000c6a:	6a42                	ld	s4,16(sp)
    80000c6c:	6aa2                	ld	s5,8(sp)
    80000c6e:	6b02                	ld	s6,0(sp)
    80000c70:	6121                	addi	sp,sp,64
    80000c72:	8082                	ret
        release(&kmem[j].lock);
    80000c74:	854e                	mv	a0,s3
    80000c76:	00000097          	auipc	ra,0x0
    80000c7a:	1ba080e7          	jalr	442(ra) # 80000e30 <release>
    for (int j = i + 1; j != i; j = (j + 1) % NCPU)
    80000c7e:	2905                	addiw	s2,s2,1
    80000c80:	41f9579b          	sraiw	a5,s2,0x1f
    80000c84:	01d7d79b          	srliw	a5,a5,0x1d
    80000c88:	00f9093b          	addw	s2,s2,a5
    80000c8c:	00797913          	andi	s2,s2,7
    80000c90:	40f9093b          	subw	s2,s2,a5
    80000c94:	032a0e63          	beq	s4,s2,80000cd0 <kalloc+0x156>
        acquire(&kmem[j].lock);
    80000c98:	00291993          	slli	s3,s2,0x2
    80000c9c:	99ca                	add	s3,s3,s2
    80000c9e:	098e                	slli	s3,s3,0x3
    80000ca0:	99da                	add	s3,s3,s6
    80000ca2:	854e                	mv	a0,s3
    80000ca4:	00000097          	auipc	ra,0x0
    80000ca8:	0bc080e7          	jalr	188(ra) # 80000d60 <acquire>
        r_other = kmem[j].freelist;
    80000cac:	0209b483          	ld	s1,32(s3)
        if (r_other)
    80000cb0:	d0f1                	beqz	s1,80000c74 <kalloc+0xfa>
        r_other = kmem[j].freelist;
    80000cb2:	8726                	mv	a4,s1
          len = 0;
    80000cb4:	4781                	li	a5,0
            len++;
    80000cb6:	2785                	addiw	a5,a5,1
          for (; r_other != 0; r_other = r_other->next)
    80000cb8:	6318                	ld	a4,0(a4)
    80000cba:	ff75                	bnez	a4,80000cb6 <kalloc+0x13c>
          remain = len / 2;
    80000cbc:	01f7d71b          	srliw	a4,a5,0x1f
    80000cc0:	9f3d                	addw	a4,a4,a5
    80000cc2:	4017571b          	sraiw	a4,a4,0x1
          steal = len - remain;
    80000cc6:	9f99                	subw	a5,a5,a4
          for (; steal > 0; steal--)
    80000cc8:	f2f05ce3          	blez	a5,80000c00 <kalloc+0x86>
            if (steal == 1)
    80000ccc:	4685                	li	a3,1
    80000cce:	b71d                	j	80000bf4 <kalloc+0x7a>
  release(&kmem[i].lock);
    80000cd0:	8556                	mv	a0,s5
    80000cd2:	00000097          	auipc	ra,0x0
    80000cd6:	15e080e7          	jalr	350(ra) # 80000e30 <release>
  pop_off(); 
    80000cda:	00000097          	auipc	ra,0x0
    80000cde:	0f6080e7          	jalr	246(ra) # 80000dd0 <pop_off>
    80000ce2:	8b26                	mv	s6,s1
    80000ce4:	bfad                	j	80000c5e <kalloc+0xe4>

0000000080000ce6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ce6:	411c                	lw	a5,0(a0)
    80000ce8:	e399                	bnez	a5,80000cee <holding+0x8>
    80000cea:	4501                	li	a0,0
  return r;
}
    80000cec:	8082                	ret
{
    80000cee:	1101                	addi	sp,sp,-32
    80000cf0:	ec06                	sd	ra,24(sp)
    80000cf2:	e822                	sd	s0,16(sp)
    80000cf4:	e426                	sd	s1,8(sp)
    80000cf6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cf8:	6904                	ld	s1,16(a0)
    80000cfa:	00001097          	auipc	ra,0x1
    80000cfe:	092080e7          	jalr	146(ra) # 80001d8c <mycpu>
    80000d02:	40a48533          	sub	a0,s1,a0
    80000d06:	00153513          	seqz	a0,a0
}
    80000d0a:	60e2                	ld	ra,24(sp)
    80000d0c:	6442                	ld	s0,16(sp)
    80000d0e:	64a2                	ld	s1,8(sp)
    80000d10:	6105                	addi	sp,sp,32
    80000d12:	8082                	ret

0000000080000d14 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000d14:	1101                	addi	sp,sp,-32
    80000d16:	ec06                	sd	ra,24(sp)
    80000d18:	e822                	sd	s0,16(sp)
    80000d1a:	e426                	sd	s1,8(sp)
    80000d1c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d1e:	100024f3          	csrr	s1,sstatus
    80000d22:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000d26:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d28:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000d2c:	00001097          	auipc	ra,0x1
    80000d30:	060080e7          	jalr	96(ra) # 80001d8c <mycpu>
    80000d34:	5d3c                	lw	a5,120(a0)
    80000d36:	cf89                	beqz	a5,80000d50 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000d38:	00001097          	auipc	ra,0x1
    80000d3c:	054080e7          	jalr	84(ra) # 80001d8c <mycpu>
    80000d40:	5d3c                	lw	a5,120(a0)
    80000d42:	2785                	addiw	a5,a5,1
    80000d44:	dd3c                	sw	a5,120(a0)
}
    80000d46:	60e2                	ld	ra,24(sp)
    80000d48:	6442                	ld	s0,16(sp)
    80000d4a:	64a2                	ld	s1,8(sp)
    80000d4c:	6105                	addi	sp,sp,32
    80000d4e:	8082                	ret
    mycpu()->intena = old;
    80000d50:	00001097          	auipc	ra,0x1
    80000d54:	03c080e7          	jalr	60(ra) # 80001d8c <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d58:	8085                	srli	s1,s1,0x1
    80000d5a:	8885                	andi	s1,s1,1
    80000d5c:	dd64                	sw	s1,124(a0)
    80000d5e:	bfe9                	j	80000d38 <push_off+0x24>

0000000080000d60 <acquire>:
{
    80000d60:	1101                	addi	sp,sp,-32
    80000d62:	ec06                	sd	ra,24(sp)
    80000d64:	e822                	sd	s0,16(sp)
    80000d66:	e426                	sd	s1,8(sp)
    80000d68:	1000                	addi	s0,sp,32
    80000d6a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d6c:	00000097          	auipc	ra,0x0
    80000d70:	fa8080e7          	jalr	-88(ra) # 80000d14 <push_off>
  if(holding(lk))
    80000d74:	8526                	mv	a0,s1
    80000d76:	00000097          	auipc	ra,0x0
    80000d7a:	f70080e7          	jalr	-144(ra) # 80000ce6 <holding>
    80000d7e:	e911                	bnez	a0,80000d92 <acquire+0x32>
    __sync_fetch_and_add(&(lk->n), 1);
    80000d80:	4785                	li	a5,1
    80000d82:	01c48713          	addi	a4,s1,28
    80000d86:	0f50000f          	fence	iorw,ow
    80000d8a:	04f7202f          	amoadd.w.aq	zero,a5,(a4)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000d8e:	4705                	li	a4,1
    80000d90:	a839                	j	80000dae <acquire+0x4e>
    panic("acquire");
    80000d92:	00007517          	auipc	a0,0x7
    80000d96:	2d650513          	addi	a0,a0,726 # 80008068 <digits+0x28>
    80000d9a:	fffff097          	auipc	ra,0xfffff
    80000d9e:	7b6080e7          	jalr	1974(ra) # 80000550 <panic>
    __sync_fetch_and_add(&(lk->nts), 1);
    80000da2:	01848793          	addi	a5,s1,24
    80000da6:	0f50000f          	fence	iorw,ow
    80000daa:	04e7a02f          	amoadd.w.aq	zero,a4,(a5)
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0) {
    80000dae:	87ba                	mv	a5,a4
    80000db0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000db4:	2781                	sext.w	a5,a5
    80000db6:	f7f5                	bnez	a5,80000da2 <acquire+0x42>
  __sync_synchronize();
    80000db8:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000dbc:	00001097          	auipc	ra,0x1
    80000dc0:	fd0080e7          	jalr	-48(ra) # 80001d8c <mycpu>
    80000dc4:	e888                	sd	a0,16(s1)
}
    80000dc6:	60e2                	ld	ra,24(sp)
    80000dc8:	6442                	ld	s0,16(sp)
    80000dca:	64a2                	ld	s1,8(sp)
    80000dcc:	6105                	addi	sp,sp,32
    80000dce:	8082                	ret

0000000080000dd0 <pop_off>:

void
pop_off(void)
{
    80000dd0:	1141                	addi	sp,sp,-16
    80000dd2:	e406                	sd	ra,8(sp)
    80000dd4:	e022                	sd	s0,0(sp)
    80000dd6:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000dd8:	00001097          	auipc	ra,0x1
    80000ddc:	fb4080e7          	jalr	-76(ra) # 80001d8c <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000de0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000de4:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000de6:	e78d                	bnez	a5,80000e10 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000de8:	5d3c                	lw	a5,120(a0)
    80000dea:	02f05b63          	blez	a5,80000e20 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000dee:	37fd                	addiw	a5,a5,-1
    80000df0:	0007871b          	sext.w	a4,a5
    80000df4:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000df6:	eb09                	bnez	a4,80000e08 <pop_off+0x38>
    80000df8:	5d7c                	lw	a5,124(a0)
    80000dfa:	c799                	beqz	a5,80000e08 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000dfc:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000e00:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e04:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000e08:	60a2                	ld	ra,8(sp)
    80000e0a:	6402                	ld	s0,0(sp)
    80000e0c:	0141                	addi	sp,sp,16
    80000e0e:	8082                	ret
    panic("pop_off - interruptible");
    80000e10:	00007517          	auipc	a0,0x7
    80000e14:	26050513          	addi	a0,a0,608 # 80008070 <digits+0x30>
    80000e18:	fffff097          	auipc	ra,0xfffff
    80000e1c:	738080e7          	jalr	1848(ra) # 80000550 <panic>
    panic("pop_off");
    80000e20:	00007517          	auipc	a0,0x7
    80000e24:	26850513          	addi	a0,a0,616 # 80008088 <digits+0x48>
    80000e28:	fffff097          	auipc	ra,0xfffff
    80000e2c:	728080e7          	jalr	1832(ra) # 80000550 <panic>

0000000080000e30 <release>:
{
    80000e30:	1101                	addi	sp,sp,-32
    80000e32:	ec06                	sd	ra,24(sp)
    80000e34:	e822                	sd	s0,16(sp)
    80000e36:	e426                	sd	s1,8(sp)
    80000e38:	1000                	addi	s0,sp,32
    80000e3a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000e3c:	00000097          	auipc	ra,0x0
    80000e40:	eaa080e7          	jalr	-342(ra) # 80000ce6 <holding>
    80000e44:	c115                	beqz	a0,80000e68 <release+0x38>
  lk->cpu = 0;
    80000e46:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000e4a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000e4e:	0f50000f          	fence	iorw,ow
    80000e52:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000e56:	00000097          	auipc	ra,0x0
    80000e5a:	f7a080e7          	jalr	-134(ra) # 80000dd0 <pop_off>
}
    80000e5e:	60e2                	ld	ra,24(sp)
    80000e60:	6442                	ld	s0,16(sp)
    80000e62:	64a2                	ld	s1,8(sp)
    80000e64:	6105                	addi	sp,sp,32
    80000e66:	8082                	ret
    panic("release");
    80000e68:	00007517          	auipc	a0,0x7
    80000e6c:	22850513          	addi	a0,a0,552 # 80008090 <digits+0x50>
    80000e70:	fffff097          	auipc	ra,0xfffff
    80000e74:	6e0080e7          	jalr	1760(ra) # 80000550 <panic>

0000000080000e78 <freelock>:
{
    80000e78:	1101                	addi	sp,sp,-32
    80000e7a:	ec06                	sd	ra,24(sp)
    80000e7c:	e822                	sd	s0,16(sp)
    80000e7e:	e426                	sd	s1,8(sp)
    80000e80:	1000                	addi	s0,sp,32
    80000e82:	84aa                	mv	s1,a0
  acquire(&lock_locks);
    80000e84:	00010517          	auipc	a0,0x10
    80000e88:	54450513          	addi	a0,a0,1348 # 800113c8 <lock_locks>
    80000e8c:	00000097          	auipc	ra,0x0
    80000e90:	ed4080e7          	jalr	-300(ra) # 80000d60 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000e94:	00010717          	auipc	a4,0x10
    80000e98:	55470713          	addi	a4,a4,1364 # 800113e8 <locks>
    80000e9c:	4781                	li	a5,0
    80000e9e:	1f400613          	li	a2,500
    if(locks[i] == lk) {
    80000ea2:	6314                	ld	a3,0(a4)
    80000ea4:	00968763          	beq	a3,s1,80000eb2 <freelock+0x3a>
  for (i = 0; i < NLOCK; i++) {
    80000ea8:	2785                	addiw	a5,a5,1
    80000eaa:	0721                	addi	a4,a4,8
    80000eac:	fec79be3          	bne	a5,a2,80000ea2 <freelock+0x2a>
    80000eb0:	a809                	j	80000ec2 <freelock+0x4a>
      locks[i] = 0;
    80000eb2:	078e                	slli	a5,a5,0x3
    80000eb4:	00010717          	auipc	a4,0x10
    80000eb8:	53470713          	addi	a4,a4,1332 # 800113e8 <locks>
    80000ebc:	97ba                	add	a5,a5,a4
    80000ebe:	0007b023          	sd	zero,0(a5)
  release(&lock_locks);
    80000ec2:	00010517          	auipc	a0,0x10
    80000ec6:	50650513          	addi	a0,a0,1286 # 800113c8 <lock_locks>
    80000eca:	00000097          	auipc	ra,0x0
    80000ece:	f66080e7          	jalr	-154(ra) # 80000e30 <release>
}
    80000ed2:	60e2                	ld	ra,24(sp)
    80000ed4:	6442                	ld	s0,16(sp)
    80000ed6:	64a2                	ld	s1,8(sp)
    80000ed8:	6105                	addi	sp,sp,32
    80000eda:	8082                	ret

0000000080000edc <initlock>:
{
    80000edc:	1101                	addi	sp,sp,-32
    80000ede:	ec06                	sd	ra,24(sp)
    80000ee0:	e822                	sd	s0,16(sp)
    80000ee2:	e426                	sd	s1,8(sp)
    80000ee4:	1000                	addi	s0,sp,32
    80000ee6:	84aa                	mv	s1,a0
  lk->name = name;
    80000ee8:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000eea:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000eee:	00053823          	sd	zero,16(a0)
  lk->nts = 0;
    80000ef2:	00052c23          	sw	zero,24(a0)
  lk->n = 0;
    80000ef6:	00052e23          	sw	zero,28(a0)
  acquire(&lock_locks);
    80000efa:	00010517          	auipc	a0,0x10
    80000efe:	4ce50513          	addi	a0,a0,1230 # 800113c8 <lock_locks>
    80000f02:	00000097          	auipc	ra,0x0
    80000f06:	e5e080e7          	jalr	-418(ra) # 80000d60 <acquire>
  for (i = 0; i < NLOCK; i++) {
    80000f0a:	00010717          	auipc	a4,0x10
    80000f0e:	4de70713          	addi	a4,a4,1246 # 800113e8 <locks>
    80000f12:	4781                	li	a5,0
    80000f14:	1f400693          	li	a3,500
    if(locks[i] == 0) {
    80000f18:	6310                	ld	a2,0(a4)
    80000f1a:	ce09                	beqz	a2,80000f34 <initlock+0x58>
  for (i = 0; i < NLOCK; i++) {
    80000f1c:	2785                	addiw	a5,a5,1
    80000f1e:	0721                	addi	a4,a4,8
    80000f20:	fed79ce3          	bne	a5,a3,80000f18 <initlock+0x3c>
  panic("findslot");
    80000f24:	00007517          	auipc	a0,0x7
    80000f28:	17450513          	addi	a0,a0,372 # 80008098 <digits+0x58>
    80000f2c:	fffff097          	auipc	ra,0xfffff
    80000f30:	624080e7          	jalr	1572(ra) # 80000550 <panic>
      locks[i] = lk;
    80000f34:	078e                	slli	a5,a5,0x3
    80000f36:	00010717          	auipc	a4,0x10
    80000f3a:	4b270713          	addi	a4,a4,1202 # 800113e8 <locks>
    80000f3e:	97ba                	add	a5,a5,a4
    80000f40:	e384                	sd	s1,0(a5)
      release(&lock_locks);
    80000f42:	00010517          	auipc	a0,0x10
    80000f46:	48650513          	addi	a0,a0,1158 # 800113c8 <lock_locks>
    80000f4a:	00000097          	auipc	ra,0x0
    80000f4e:	ee6080e7          	jalr	-282(ra) # 80000e30 <release>
}
    80000f52:	60e2                	ld	ra,24(sp)
    80000f54:	6442                	ld	s0,16(sp)
    80000f56:	64a2                	ld	s1,8(sp)
    80000f58:	6105                	addi	sp,sp,32
    80000f5a:	8082                	ret

0000000080000f5c <snprint_lock>:
#ifdef LAB_LOCK
int
snprint_lock(char *buf, int sz, struct spinlock *lk)
{
  int n = 0;
  if(lk->n > 0) {
    80000f5c:	4e5c                	lw	a5,28(a2)
    80000f5e:	00f04463          	bgtz	a5,80000f66 <snprint_lock+0xa>
  int n = 0;
    80000f62:	4501                	li	a0,0
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
                 lk->name, lk->nts, lk->n);
  }
  return n;
}
    80000f64:	8082                	ret
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e406                	sd	ra,8(sp)
    80000f6a:	e022                	sd	s0,0(sp)
    80000f6c:	0800                	addi	s0,sp,16
    n = snprintf(buf, sz, "lock: %s: #fetch-and-add %d #acquire() %d\n",
    80000f6e:	4e18                	lw	a4,24(a2)
    80000f70:	6614                	ld	a3,8(a2)
    80000f72:	00007617          	auipc	a2,0x7
    80000f76:	13660613          	addi	a2,a2,310 # 800080a8 <digits+0x68>
    80000f7a:	00006097          	auipc	ra,0x6
    80000f7e:	9c8080e7          	jalr	-1592(ra) # 80006942 <snprintf>
}
    80000f82:	60a2                	ld	ra,8(sp)
    80000f84:	6402                	ld	s0,0(sp)
    80000f86:	0141                	addi	sp,sp,16
    80000f88:	8082                	ret

0000000080000f8a <statslock>:

int
statslock(char *buf, int sz) {
    80000f8a:	7159                	addi	sp,sp,-112
    80000f8c:	f486                	sd	ra,104(sp)
    80000f8e:	f0a2                	sd	s0,96(sp)
    80000f90:	eca6                	sd	s1,88(sp)
    80000f92:	e8ca                	sd	s2,80(sp)
    80000f94:	e4ce                	sd	s3,72(sp)
    80000f96:	e0d2                	sd	s4,64(sp)
    80000f98:	fc56                	sd	s5,56(sp)
    80000f9a:	f85a                	sd	s6,48(sp)
    80000f9c:	f45e                	sd	s7,40(sp)
    80000f9e:	f062                	sd	s8,32(sp)
    80000fa0:	ec66                	sd	s9,24(sp)
    80000fa2:	e86a                	sd	s10,16(sp)
    80000fa4:	e46e                	sd	s11,8(sp)
    80000fa6:	1880                	addi	s0,sp,112
    80000fa8:	8aaa                	mv	s5,a0
    80000faa:	8b2e                	mv	s6,a1
  int n;
  int tot = 0;

  acquire(&lock_locks);
    80000fac:	00010517          	auipc	a0,0x10
    80000fb0:	41c50513          	addi	a0,a0,1052 # 800113c8 <lock_locks>
    80000fb4:	00000097          	auipc	ra,0x0
    80000fb8:	dac080e7          	jalr	-596(ra) # 80000d60 <acquire>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fbc:	00007617          	auipc	a2,0x7
    80000fc0:	11c60613          	addi	a2,a2,284 # 800080d8 <digits+0x98>
    80000fc4:	85da                	mv	a1,s6
    80000fc6:	8556                	mv	a0,s5
    80000fc8:	00006097          	auipc	ra,0x6
    80000fcc:	97a080e7          	jalr	-1670(ra) # 80006942 <snprintf>
    80000fd0:	892a                	mv	s2,a0
  for(int i = 0; i < NLOCK; i++) {
    80000fd2:	00010c97          	auipc	s9,0x10
    80000fd6:	416c8c93          	addi	s9,s9,1046 # 800113e8 <locks>
    80000fda:	00011c17          	auipc	s8,0x11
    80000fde:	3aec0c13          	addi	s8,s8,942 # 80012388 <pid_lock>
  n = snprintf(buf, sz, "--- lock kmem/bcache stats\n");
    80000fe2:	84e6                	mv	s1,s9
  int tot = 0;
    80000fe4:	4a01                	li	s4,0
    if(locks[i] == 0)
      break;
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80000fe6:	00007b97          	auipc	s7,0x7
    80000fea:	112b8b93          	addi	s7,s7,274 # 800080f8 <digits+0xb8>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80000fee:	00007d17          	auipc	s10,0x7
    80000ff2:	112d0d13          	addi	s10,s10,274 # 80008100 <digits+0xc0>
    80000ff6:	a01d                	j	8000101c <statslock+0x92>
      tot += locks[i]->nts;
    80000ff8:	0009b603          	ld	a2,0(s3)
    80000ffc:	4e1c                	lw	a5,24(a2)
    80000ffe:	01478a3b          	addw	s4,a5,s4
      n += snprint_lock(buf +n, sz-n, locks[i]);
    80001002:	412b05bb          	subw	a1,s6,s2
    80001006:	012a8533          	add	a0,s5,s2
    8000100a:	00000097          	auipc	ra,0x0
    8000100e:	f52080e7          	jalr	-174(ra) # 80000f5c <snprint_lock>
    80001012:	0125093b          	addw	s2,a0,s2
  for(int i = 0; i < NLOCK; i++) {
    80001016:	04a1                	addi	s1,s1,8
    80001018:	05848763          	beq	s1,s8,80001066 <statslock+0xdc>
    if(locks[i] == 0)
    8000101c:	89a6                	mv	s3,s1
    8000101e:	609c                	ld	a5,0(s1)
    80001020:	c3b9                	beqz	a5,80001066 <statslock+0xdc>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001022:	0087bd83          	ld	s11,8(a5)
    80001026:	855e                	mv	a0,s7
    80001028:	00000097          	auipc	ra,0x0
    8000102c:	2a0080e7          	jalr	672(ra) # 800012c8 <strlen>
    80001030:	0005061b          	sext.w	a2,a0
    80001034:	85de                	mv	a1,s7
    80001036:	856e                	mv	a0,s11
    80001038:	00000097          	auipc	ra,0x0
    8000103c:	1e4080e7          	jalr	484(ra) # 8000121c <strncmp>
    80001040:	dd45                	beqz	a0,80000ff8 <statslock+0x6e>
       strncmp(locks[i]->name, "kmem", strlen("kmem")) == 0) {
    80001042:	609c                	ld	a5,0(s1)
    80001044:	0087bd83          	ld	s11,8(a5)
    80001048:	856a                	mv	a0,s10
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	27e080e7          	jalr	638(ra) # 800012c8 <strlen>
    80001052:	0005061b          	sext.w	a2,a0
    80001056:	85ea                	mv	a1,s10
    80001058:	856e                	mv	a0,s11
    8000105a:	00000097          	auipc	ra,0x0
    8000105e:	1c2080e7          	jalr	450(ra) # 8000121c <strncmp>
    if(strncmp(locks[i]->name, "bcache", strlen("bcache")) == 0 ||
    80001062:	f955                	bnez	a0,80001016 <statslock+0x8c>
    80001064:	bf51                	j	80000ff8 <statslock+0x6e>
    }
  }
  
  n += snprintf(buf+n, sz-n, "--- top 5 contended locks:\n");
    80001066:	00007617          	auipc	a2,0x7
    8000106a:	0a260613          	addi	a2,a2,162 # 80008108 <digits+0xc8>
    8000106e:	412b05bb          	subw	a1,s6,s2
    80001072:	012a8533          	add	a0,s5,s2
    80001076:	00006097          	auipc	ra,0x6
    8000107a:	8cc080e7          	jalr	-1844(ra) # 80006942 <snprintf>
    8000107e:	012509bb          	addw	s3,a0,s2
    80001082:	4b95                	li	s7,5
  int last = 100000000;
    80001084:	05f5e537          	lui	a0,0x5f5e
    80001088:	10050513          	addi	a0,a0,256 # 5f5e100 <_entry-0x7a0a1f00>
  // stupid way to compute top 5 contended locks
  for(int t = 0; t < 5; t++) {
    int top = 0;
    for(int i = 0; i < NLOCK; i++) {
    8000108c:	4c01                	li	s8,0
      if(locks[i] == 0)
        break;
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    8000108e:	00010497          	auipc	s1,0x10
    80001092:	35a48493          	addi	s1,s1,858 # 800113e8 <locks>
    for(int i = 0; i < NLOCK; i++) {
    80001096:	1f400913          	li	s2,500
    8000109a:	a881                	j	800010ea <statslock+0x160>
    8000109c:	2705                	addiw	a4,a4,1
    8000109e:	06a1                	addi	a3,a3,8
    800010a0:	03270063          	beq	a4,s2,800010c0 <statslock+0x136>
      if(locks[i] == 0)
    800010a4:	629c                	ld	a5,0(a3)
    800010a6:	cf89                	beqz	a5,800010c0 <statslock+0x136>
      if(locks[i]->nts > locks[top]->nts && locks[i]->nts < last) {
    800010a8:	4f90                	lw	a2,24(a5)
    800010aa:	00359793          	slli	a5,a1,0x3
    800010ae:	97a6                	add	a5,a5,s1
    800010b0:	639c                	ld	a5,0(a5)
    800010b2:	4f9c                	lw	a5,24(a5)
    800010b4:	fec7d4e3          	bge	a5,a2,8000109c <statslock+0x112>
    800010b8:	fea652e3          	bge	a2,a0,8000109c <statslock+0x112>
    800010bc:	85ba                	mv	a1,a4
    800010be:	bff9                	j	8000109c <statslock+0x112>
        top = i;
      }
    }
    n += snprint_lock(buf+n, sz-n, locks[top]);
    800010c0:	058e                	slli	a1,a1,0x3
    800010c2:	00b48d33          	add	s10,s1,a1
    800010c6:	000d3603          	ld	a2,0(s10)
    800010ca:	413b05bb          	subw	a1,s6,s3
    800010ce:	013a8533          	add	a0,s5,s3
    800010d2:	00000097          	auipc	ra,0x0
    800010d6:	e8a080e7          	jalr	-374(ra) # 80000f5c <snprint_lock>
    800010da:	013509bb          	addw	s3,a0,s3
    last = locks[top]->nts;
    800010de:	000d3783          	ld	a5,0(s10)
    800010e2:	4f88                	lw	a0,24(a5)
  for(int t = 0; t < 5; t++) {
    800010e4:	3bfd                	addiw	s7,s7,-1
    800010e6:	000b8663          	beqz	s7,800010f2 <statslock+0x168>
  int tot = 0;
    800010ea:	86e6                	mv	a3,s9
    for(int i = 0; i < NLOCK; i++) {
    800010ec:	8762                	mv	a4,s8
    int top = 0;
    800010ee:	85e2                	mv	a1,s8
    800010f0:	bf55                	j	800010a4 <statslock+0x11a>
  }
  n += snprintf(buf+n, sz-n, "tot= %d\n", tot);
    800010f2:	86d2                	mv	a3,s4
    800010f4:	00007617          	auipc	a2,0x7
    800010f8:	03460613          	addi	a2,a2,52 # 80008128 <digits+0xe8>
    800010fc:	413b05bb          	subw	a1,s6,s3
    80001100:	013a8533          	add	a0,s5,s3
    80001104:	00006097          	auipc	ra,0x6
    80001108:	83e080e7          	jalr	-1986(ra) # 80006942 <snprintf>
    8000110c:	013509bb          	addw	s3,a0,s3
  release(&lock_locks);  
    80001110:	00010517          	auipc	a0,0x10
    80001114:	2b850513          	addi	a0,a0,696 # 800113c8 <lock_locks>
    80001118:	00000097          	auipc	ra,0x0
    8000111c:	d18080e7          	jalr	-744(ra) # 80000e30 <release>
  return n;
}
    80001120:	854e                	mv	a0,s3
    80001122:	70a6                	ld	ra,104(sp)
    80001124:	7406                	ld	s0,96(sp)
    80001126:	64e6                	ld	s1,88(sp)
    80001128:	6946                	ld	s2,80(sp)
    8000112a:	69a6                	ld	s3,72(sp)
    8000112c:	6a06                	ld	s4,64(sp)
    8000112e:	7ae2                	ld	s5,56(sp)
    80001130:	7b42                	ld	s6,48(sp)
    80001132:	7ba2                	ld	s7,40(sp)
    80001134:	7c02                	ld	s8,32(sp)
    80001136:	6ce2                	ld	s9,24(sp)
    80001138:	6d42                	ld	s10,16(sp)
    8000113a:	6da2                	ld	s11,8(sp)
    8000113c:	6165                	addi	sp,sp,112
    8000113e:	8082                	ret

0000000080001140 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80001140:	1141                	addi	sp,sp,-16
    80001142:	e422                	sd	s0,8(sp)
    80001144:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80001146:	ce09                	beqz	a2,80001160 <memset+0x20>
    80001148:	87aa                	mv	a5,a0
    8000114a:	fff6071b          	addiw	a4,a2,-1
    8000114e:	1702                	slli	a4,a4,0x20
    80001150:	9301                	srli	a4,a4,0x20
    80001152:	0705                	addi	a4,a4,1
    80001154:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80001156:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    8000115a:	0785                	addi	a5,a5,1
    8000115c:	fee79de3          	bne	a5,a4,80001156 <memset+0x16>
  }
  return dst;
}
    80001160:	6422                	ld	s0,8(sp)
    80001162:	0141                	addi	sp,sp,16
    80001164:	8082                	ret

0000000080001166 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80001166:	1141                	addi	sp,sp,-16
    80001168:	e422                	sd	s0,8(sp)
    8000116a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    8000116c:	ca05                	beqz	a2,8000119c <memcmp+0x36>
    8000116e:	fff6069b          	addiw	a3,a2,-1
    80001172:	1682                	slli	a3,a3,0x20
    80001174:	9281                	srli	a3,a3,0x20
    80001176:	0685                	addi	a3,a3,1
    80001178:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    8000117a:	00054783          	lbu	a5,0(a0)
    8000117e:	0005c703          	lbu	a4,0(a1)
    80001182:	00e79863          	bne	a5,a4,80001192 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80001186:	0505                	addi	a0,a0,1
    80001188:	0585                	addi	a1,a1,1
  while(n-- > 0){
    8000118a:	fed518e3          	bne	a0,a3,8000117a <memcmp+0x14>
  }

  return 0;
    8000118e:	4501                	li	a0,0
    80001190:	a019                	j	80001196 <memcmp+0x30>
      return *s1 - *s2;
    80001192:	40e7853b          	subw	a0,a5,a4
}
    80001196:	6422                	ld	s0,8(sp)
    80001198:	0141                	addi	sp,sp,16
    8000119a:	8082                	ret
  return 0;
    8000119c:	4501                	li	a0,0
    8000119e:	bfe5                	j	80001196 <memcmp+0x30>

00000000800011a0 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    800011a0:	1141                	addi	sp,sp,-16
    800011a2:	e422                	sd	s0,8(sp)
    800011a4:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    800011a6:	00a5f963          	bgeu	a1,a0,800011b8 <memmove+0x18>
    800011aa:	02061713          	slli	a4,a2,0x20
    800011ae:	9301                	srli	a4,a4,0x20
    800011b0:	00e587b3          	add	a5,a1,a4
    800011b4:	02f56563          	bltu	a0,a5,800011de <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    800011b8:	fff6069b          	addiw	a3,a2,-1
    800011bc:	ce11                	beqz	a2,800011d8 <memmove+0x38>
    800011be:	1682                	slli	a3,a3,0x20
    800011c0:	9281                	srli	a3,a3,0x20
    800011c2:	0685                	addi	a3,a3,1
    800011c4:	96ae                	add	a3,a3,a1
    800011c6:	87aa                	mv	a5,a0
      *d++ = *s++;
    800011c8:	0585                	addi	a1,a1,1
    800011ca:	0785                	addi	a5,a5,1
    800011cc:	fff5c703          	lbu	a4,-1(a1)
    800011d0:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    800011d4:	fed59ae3          	bne	a1,a3,800011c8 <memmove+0x28>

  return dst;
}
    800011d8:	6422                	ld	s0,8(sp)
    800011da:	0141                	addi	sp,sp,16
    800011dc:	8082                	ret
    d += n;
    800011de:	972a                	add	a4,a4,a0
    while(n-- > 0)
    800011e0:	fff6069b          	addiw	a3,a2,-1
    800011e4:	da75                	beqz	a2,800011d8 <memmove+0x38>
    800011e6:	02069613          	slli	a2,a3,0x20
    800011ea:	9201                	srli	a2,a2,0x20
    800011ec:	fff64613          	not	a2,a2
    800011f0:	963e                	add	a2,a2,a5
      *--d = *--s;
    800011f2:	17fd                	addi	a5,a5,-1
    800011f4:	177d                	addi	a4,a4,-1
    800011f6:	0007c683          	lbu	a3,0(a5)
    800011fa:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    800011fe:	fec79ae3          	bne	a5,a2,800011f2 <memmove+0x52>
    80001202:	bfd9                	j	800011d8 <memmove+0x38>

0000000080001204 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001204:	1141                	addi	sp,sp,-16
    80001206:	e406                	sd	ra,8(sp)
    80001208:	e022                	sd	s0,0(sp)
    8000120a:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    8000120c:	00000097          	auipc	ra,0x0
    80001210:	f94080e7          	jalr	-108(ra) # 800011a0 <memmove>
}
    80001214:	60a2                	ld	ra,8(sp)
    80001216:	6402                	ld	s0,0(sp)
    80001218:	0141                	addi	sp,sp,16
    8000121a:	8082                	ret

000000008000121c <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    8000121c:	1141                	addi	sp,sp,-16
    8000121e:	e422                	sd	s0,8(sp)
    80001220:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001222:	ce11                	beqz	a2,8000123e <strncmp+0x22>
    80001224:	00054783          	lbu	a5,0(a0)
    80001228:	cf89                	beqz	a5,80001242 <strncmp+0x26>
    8000122a:	0005c703          	lbu	a4,0(a1)
    8000122e:	00f71a63          	bne	a4,a5,80001242 <strncmp+0x26>
    n--, p++, q++;
    80001232:	367d                	addiw	a2,a2,-1
    80001234:	0505                	addi	a0,a0,1
    80001236:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80001238:	f675                	bnez	a2,80001224 <strncmp+0x8>
  if(n == 0)
    return 0;
    8000123a:	4501                	li	a0,0
    8000123c:	a809                	j	8000124e <strncmp+0x32>
    8000123e:	4501                	li	a0,0
    80001240:	a039                	j	8000124e <strncmp+0x32>
  if(n == 0)
    80001242:	ca09                	beqz	a2,80001254 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80001244:	00054503          	lbu	a0,0(a0)
    80001248:	0005c783          	lbu	a5,0(a1)
    8000124c:	9d1d                	subw	a0,a0,a5
}
    8000124e:	6422                	ld	s0,8(sp)
    80001250:	0141                	addi	sp,sp,16
    80001252:	8082                	ret
    return 0;
    80001254:	4501                	li	a0,0
    80001256:	bfe5                	j	8000124e <strncmp+0x32>

0000000080001258 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80001258:	1141                	addi	sp,sp,-16
    8000125a:	e422                	sd	s0,8(sp)
    8000125c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    8000125e:	872a                	mv	a4,a0
    80001260:	8832                	mv	a6,a2
    80001262:	367d                	addiw	a2,a2,-1
    80001264:	01005963          	blez	a6,80001276 <strncpy+0x1e>
    80001268:	0705                	addi	a4,a4,1
    8000126a:	0005c783          	lbu	a5,0(a1)
    8000126e:	fef70fa3          	sb	a5,-1(a4)
    80001272:	0585                	addi	a1,a1,1
    80001274:	f7f5                	bnez	a5,80001260 <strncpy+0x8>
    ;
  while(n-- > 0)
    80001276:	00c05d63          	blez	a2,80001290 <strncpy+0x38>
    8000127a:	86ba                	mv	a3,a4
    *s++ = 0;
    8000127c:	0685                	addi	a3,a3,1
    8000127e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001282:	fff6c793          	not	a5,a3
    80001286:	9fb9                	addw	a5,a5,a4
    80001288:	010787bb          	addw	a5,a5,a6
    8000128c:	fef048e3          	bgtz	a5,8000127c <strncpy+0x24>
  return os;
}
    80001290:	6422                	ld	s0,8(sp)
    80001292:	0141                	addi	sp,sp,16
    80001294:	8082                	ret

0000000080001296 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80001296:	1141                	addi	sp,sp,-16
    80001298:	e422                	sd	s0,8(sp)
    8000129a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    8000129c:	02c05363          	blez	a2,800012c2 <safestrcpy+0x2c>
    800012a0:	fff6069b          	addiw	a3,a2,-1
    800012a4:	1682                	slli	a3,a3,0x20
    800012a6:	9281                	srli	a3,a3,0x20
    800012a8:	96ae                	add	a3,a3,a1
    800012aa:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800012ac:	00d58963          	beq	a1,a3,800012be <safestrcpy+0x28>
    800012b0:	0585                	addi	a1,a1,1
    800012b2:	0785                	addi	a5,a5,1
    800012b4:	fff5c703          	lbu	a4,-1(a1)
    800012b8:	fee78fa3          	sb	a4,-1(a5)
    800012bc:	fb65                	bnez	a4,800012ac <safestrcpy+0x16>
    ;
  *s = 0;
    800012be:	00078023          	sb	zero,0(a5)
  return os;
}
    800012c2:	6422                	ld	s0,8(sp)
    800012c4:	0141                	addi	sp,sp,16
    800012c6:	8082                	ret

00000000800012c8 <strlen>:

int
strlen(const char *s)
{
    800012c8:	1141                	addi	sp,sp,-16
    800012ca:	e422                	sd	s0,8(sp)
    800012cc:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800012ce:	00054783          	lbu	a5,0(a0)
    800012d2:	cf91                	beqz	a5,800012ee <strlen+0x26>
    800012d4:	0505                	addi	a0,a0,1
    800012d6:	87aa                	mv	a5,a0
    800012d8:	4685                	li	a3,1
    800012da:	9e89                	subw	a3,a3,a0
    800012dc:	00f6853b          	addw	a0,a3,a5
    800012e0:	0785                	addi	a5,a5,1
    800012e2:	fff7c703          	lbu	a4,-1(a5)
    800012e6:	fb7d                	bnez	a4,800012dc <strlen+0x14>
    ;
  return n;
}
    800012e8:	6422                	ld	s0,8(sp)
    800012ea:	0141                	addi	sp,sp,16
    800012ec:	8082                	ret
  for(n = 0; s[n]; n++)
    800012ee:	4501                	li	a0,0
    800012f0:	bfe5                	j	800012e8 <strlen+0x20>

00000000800012f2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800012f2:	1141                	addi	sp,sp,-16
    800012f4:	e406                	sd	ra,8(sp)
    800012f6:	e022                	sd	s0,0(sp)
    800012f8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    800012fa:	00001097          	auipc	ra,0x1
    800012fe:	a82080e7          	jalr	-1406(ra) # 80001d7c <cpuid>
#endif    
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001302:	00008717          	auipc	a4,0x8
    80001306:	d0a70713          	addi	a4,a4,-758 # 8000900c <started>
  if(cpuid() == 0){
    8000130a:	c139                	beqz	a0,80001350 <main+0x5e>
    while(started == 0)
    8000130c:	431c                	lw	a5,0(a4)
    8000130e:	2781                	sext.w	a5,a5
    80001310:	dff5                	beqz	a5,8000130c <main+0x1a>
      ;
    __sync_synchronize();
    80001312:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80001316:	00001097          	auipc	ra,0x1
    8000131a:	a66080e7          	jalr	-1434(ra) # 80001d7c <cpuid>
    8000131e:	85aa                	mv	a1,a0
    80001320:	00007517          	auipc	a0,0x7
    80001324:	e3050513          	addi	a0,a0,-464 # 80008150 <digits+0x110>
    80001328:	fffff097          	auipc	ra,0xfffff
    8000132c:	272080e7          	jalr	626(ra) # 8000059a <printf>
    kvminithart();    // turn on paging
    80001330:	00000097          	auipc	ra,0x0
    80001334:	186080e7          	jalr	390(ra) # 800014b6 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001338:	00001097          	auipc	ra,0x1
    8000133c:	6ce080e7          	jalr	1742(ra) # 80002a06 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001340:	00005097          	auipc	ra,0x5
    80001344:	e40080e7          	jalr	-448(ra) # 80006180 <plicinithart>
  }

  scheduler();        
    80001348:	00001097          	auipc	ra,0x1
    8000134c:	f90080e7          	jalr	-112(ra) # 800022d8 <scheduler>
    consoleinit();
    80001350:	fffff097          	auipc	ra,0xfffff
    80001354:	112080e7          	jalr	274(ra) # 80000462 <consoleinit>
    statsinit();
    80001358:	00005097          	auipc	ra,0x5
    8000135c:	50e080e7          	jalr	1294(ra) # 80006866 <statsinit>
    printfinit();
    80001360:	fffff097          	auipc	ra,0xfffff
    80001364:	420080e7          	jalr	1056(ra) # 80000780 <printfinit>
    printf("\n");
    80001368:	00007517          	auipc	a0,0x7
    8000136c:	df850513          	addi	a0,a0,-520 # 80008160 <digits+0x120>
    80001370:	fffff097          	auipc	ra,0xfffff
    80001374:	22a080e7          	jalr	554(ra) # 8000059a <printf>
    printf("xv6 kernel is booting\n");
    80001378:	00007517          	auipc	a0,0x7
    8000137c:	dc050513          	addi	a0,a0,-576 # 80008138 <digits+0xf8>
    80001380:	fffff097          	auipc	ra,0xfffff
    80001384:	21a080e7          	jalr	538(ra) # 8000059a <printf>
    printf("\n");
    80001388:	00007517          	auipc	a0,0x7
    8000138c:	dd850513          	addi	a0,a0,-552 # 80008160 <digits+0x120>
    80001390:	fffff097          	auipc	ra,0xfffff
    80001394:	20a080e7          	jalr	522(ra) # 8000059a <printf>
    kinit();         // physical page allocator
    80001398:	fffff097          	auipc	ra,0xfffff
    8000139c:	784080e7          	jalr	1924(ra) # 80000b1c <kinit>
    kvminit();       // create kernel page table
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	242080e7          	jalr	578(ra) # 800015e2 <kvminit>
    kvminithart();   // turn on paging
    800013a8:	00000097          	auipc	ra,0x0
    800013ac:	10e080e7          	jalr	270(ra) # 800014b6 <kvminithart>
    procinit();      // process table
    800013b0:	00001097          	auipc	ra,0x1
    800013b4:	8fc080e7          	jalr	-1796(ra) # 80001cac <procinit>
    trapinit();      // trap vectors
    800013b8:	00001097          	auipc	ra,0x1
    800013bc:	626080e7          	jalr	1574(ra) # 800029de <trapinit>
    trapinithart();  // install kernel trap vector
    800013c0:	00001097          	auipc	ra,0x1
    800013c4:	646080e7          	jalr	1606(ra) # 80002a06 <trapinithart>
    plicinit();      // set up interrupt controller
    800013c8:	00005097          	auipc	ra,0x5
    800013cc:	da2080e7          	jalr	-606(ra) # 8000616a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800013d0:	00005097          	auipc	ra,0x5
    800013d4:	db0080e7          	jalr	-592(ra) # 80006180 <plicinithart>
    binit();         // buffer cache
    800013d8:	00002097          	auipc	ra,0x2
    800013dc:	d70080e7          	jalr	-656(ra) # 80003148 <binit>
    iinit();         // inode cache
    800013e0:	00002097          	auipc	ra,0x2
    800013e4:	5ba080e7          	jalr	1466(ra) # 8000399a <iinit>
    fileinit();      // file table
    800013e8:	00003097          	auipc	ra,0x3
    800013ec:	56a080e7          	jalr	1386(ra) # 80004952 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800013f0:	00005097          	auipc	ra,0x5
    800013f4:	eb2080e7          	jalr	-334(ra) # 800062a2 <virtio_disk_init>
    userinit();      // first user process
    800013f8:	00001097          	auipc	ra,0x1
    800013fc:	c7a080e7          	jalr	-902(ra) # 80002072 <userinit>
    __sync_synchronize();
    80001400:	0ff0000f          	fence
    started = 1;
    80001404:	4785                	li	a5,1
    80001406:	00008717          	auipc	a4,0x8
    8000140a:	c0f72323          	sw	a5,-1018(a4) # 8000900c <started>
    8000140e:	bf2d                	j	80001348 <main+0x56>

0000000080001410 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
static pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001410:	7139                	addi	sp,sp,-64
    80001412:	fc06                	sd	ra,56(sp)
    80001414:	f822                	sd	s0,48(sp)
    80001416:	f426                	sd	s1,40(sp)
    80001418:	f04a                	sd	s2,32(sp)
    8000141a:	ec4e                	sd	s3,24(sp)
    8000141c:	e852                	sd	s4,16(sp)
    8000141e:	e456                	sd	s5,8(sp)
    80001420:	e05a                	sd	s6,0(sp)
    80001422:	0080                	addi	s0,sp,64
    80001424:	84aa                	mv	s1,a0
    80001426:	89ae                	mv	s3,a1
    80001428:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000142a:	57fd                	li	a5,-1
    8000142c:	83e9                	srli	a5,a5,0x1a
    8000142e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001430:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001432:	04b7f263          	bgeu	a5,a1,80001476 <walk+0x66>
    panic("walk");
    80001436:	00007517          	auipc	a0,0x7
    8000143a:	d3250513          	addi	a0,a0,-718 # 80008168 <digits+0x128>
    8000143e:	fffff097          	auipc	ra,0xfffff
    80001442:	112080e7          	jalr	274(ra) # 80000550 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001446:	060a8663          	beqz	s5,800014b2 <walk+0xa2>
    8000144a:	fffff097          	auipc	ra,0xfffff
    8000144e:	730080e7          	jalr	1840(ra) # 80000b7a <kalloc>
    80001452:	84aa                	mv	s1,a0
    80001454:	c529                	beqz	a0,8000149e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001456:	6605                	lui	a2,0x1
    80001458:	4581                	li	a1,0
    8000145a:	00000097          	auipc	ra,0x0
    8000145e:	ce6080e7          	jalr	-794(ra) # 80001140 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001462:	00c4d793          	srli	a5,s1,0xc
    80001466:	07aa                	slli	a5,a5,0xa
    80001468:	0017e793          	ori	a5,a5,1
    8000146c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001470:	3a5d                	addiw	s4,s4,-9
    80001472:	036a0063          	beq	s4,s6,80001492 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001476:	0149d933          	srl	s2,s3,s4
    8000147a:	1ff97913          	andi	s2,s2,511
    8000147e:	090e                	slli	s2,s2,0x3
    80001480:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001482:	00093483          	ld	s1,0(s2)
    80001486:	0014f793          	andi	a5,s1,1
    8000148a:	dfd5                	beqz	a5,80001446 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000148c:	80a9                	srli	s1,s1,0xa
    8000148e:	04b2                	slli	s1,s1,0xc
    80001490:	b7c5                	j	80001470 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001492:	00c9d513          	srli	a0,s3,0xc
    80001496:	1ff57513          	andi	a0,a0,511
    8000149a:	050e                	slli	a0,a0,0x3
    8000149c:	9526                	add	a0,a0,s1
}
    8000149e:	70e2                	ld	ra,56(sp)
    800014a0:	7442                	ld	s0,48(sp)
    800014a2:	74a2                	ld	s1,40(sp)
    800014a4:	7902                	ld	s2,32(sp)
    800014a6:	69e2                	ld	s3,24(sp)
    800014a8:	6a42                	ld	s4,16(sp)
    800014aa:	6aa2                	ld	s5,8(sp)
    800014ac:	6b02                	ld	s6,0(sp)
    800014ae:	6121                	addi	sp,sp,64
    800014b0:	8082                	ret
        return 0;
    800014b2:	4501                	li	a0,0
    800014b4:	b7ed                	j	8000149e <walk+0x8e>

00000000800014b6 <kvminithart>:
{
    800014b6:	1141                	addi	sp,sp,-16
    800014b8:	e422                	sd	s0,8(sp)
    800014ba:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800014bc:	00008797          	auipc	a5,0x8
    800014c0:	b547b783          	ld	a5,-1196(a5) # 80009010 <kernel_pagetable>
    800014c4:	83b1                	srli	a5,a5,0xc
    800014c6:	577d                	li	a4,-1
    800014c8:	177e                	slli	a4,a4,0x3f
    800014ca:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800014cc:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800014d0:	12000073          	sfence.vma
}
    800014d4:	6422                	ld	s0,8(sp)
    800014d6:	0141                	addi	sp,sp,16
    800014d8:	8082                	ret

00000000800014da <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800014da:	57fd                	li	a5,-1
    800014dc:	83e9                	srli	a5,a5,0x1a
    800014de:	00b7f463          	bgeu	a5,a1,800014e6 <walkaddr+0xc>
    return 0;
    800014e2:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800014e4:	8082                	ret
{
    800014e6:	1141                	addi	sp,sp,-16
    800014e8:	e406                	sd	ra,8(sp)
    800014ea:	e022                	sd	s0,0(sp)
    800014ec:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800014ee:	4601                	li	a2,0
    800014f0:	00000097          	auipc	ra,0x0
    800014f4:	f20080e7          	jalr	-224(ra) # 80001410 <walk>
  if(pte == 0)
    800014f8:	c105                	beqz	a0,80001518 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800014fa:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800014fc:	0117f693          	andi	a3,a5,17
    80001500:	4745                	li	a4,17
    return 0;
    80001502:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001504:	00e68663          	beq	a3,a4,80001510 <walkaddr+0x36>
}
    80001508:	60a2                	ld	ra,8(sp)
    8000150a:	6402                	ld	s0,0(sp)
    8000150c:	0141                	addi	sp,sp,16
    8000150e:	8082                	ret
  pa = PTE2PA(*pte);
    80001510:	00a7d513          	srli	a0,a5,0xa
    80001514:	0532                	slli	a0,a0,0xc
  return pa;
    80001516:	bfcd                	j	80001508 <walkaddr+0x2e>
    return 0;
    80001518:	4501                	li	a0,0
    8000151a:	b7fd                	j	80001508 <walkaddr+0x2e>

000000008000151c <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000151c:	715d                	addi	sp,sp,-80
    8000151e:	e486                	sd	ra,72(sp)
    80001520:	e0a2                	sd	s0,64(sp)
    80001522:	fc26                	sd	s1,56(sp)
    80001524:	f84a                	sd	s2,48(sp)
    80001526:	f44e                	sd	s3,40(sp)
    80001528:	f052                	sd	s4,32(sp)
    8000152a:	ec56                	sd	s5,24(sp)
    8000152c:	e85a                	sd	s6,16(sp)
    8000152e:	e45e                	sd	s7,8(sp)
    80001530:	0880                	addi	s0,sp,80
    80001532:	8aaa                	mv	s5,a0
    80001534:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    80001536:	777d                	lui	a4,0xfffff
    80001538:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000153c:	167d                	addi	a2,a2,-1
    8000153e:	00b609b3          	add	s3,a2,a1
    80001542:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001546:	893e                	mv	s2,a5
    80001548:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000154c:	6b85                	lui	s7,0x1
    8000154e:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001552:	4605                	li	a2,1
    80001554:	85ca                	mv	a1,s2
    80001556:	8556                	mv	a0,s5
    80001558:	00000097          	auipc	ra,0x0
    8000155c:	eb8080e7          	jalr	-328(ra) # 80001410 <walk>
    80001560:	c51d                	beqz	a0,8000158e <mappages+0x72>
    if(*pte & PTE_V)
    80001562:	611c                	ld	a5,0(a0)
    80001564:	8b85                	andi	a5,a5,1
    80001566:	ef81                	bnez	a5,8000157e <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001568:	80b1                	srli	s1,s1,0xc
    8000156a:	04aa                	slli	s1,s1,0xa
    8000156c:	0164e4b3          	or	s1,s1,s6
    80001570:	0014e493          	ori	s1,s1,1
    80001574:	e104                	sd	s1,0(a0)
    if(a == last)
    80001576:	03390863          	beq	s2,s3,800015a6 <mappages+0x8a>
    a += PGSIZE;
    8000157a:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000157c:	bfc9                	j	8000154e <mappages+0x32>
      panic("remap");
    8000157e:	00007517          	auipc	a0,0x7
    80001582:	bf250513          	addi	a0,a0,-1038 # 80008170 <digits+0x130>
    80001586:	fffff097          	auipc	ra,0xfffff
    8000158a:	fca080e7          	jalr	-54(ra) # 80000550 <panic>
      return -1;
    8000158e:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001590:	60a6                	ld	ra,72(sp)
    80001592:	6406                	ld	s0,64(sp)
    80001594:	74e2                	ld	s1,56(sp)
    80001596:	7942                	ld	s2,48(sp)
    80001598:	79a2                	ld	s3,40(sp)
    8000159a:	7a02                	ld	s4,32(sp)
    8000159c:	6ae2                	ld	s5,24(sp)
    8000159e:	6b42                	ld	s6,16(sp)
    800015a0:	6ba2                	ld	s7,8(sp)
    800015a2:	6161                	addi	sp,sp,80
    800015a4:	8082                	ret
  return 0;
    800015a6:	4501                	li	a0,0
    800015a8:	b7e5                	j	80001590 <mappages+0x74>

00000000800015aa <kvmmap>:
{
    800015aa:	1141                	addi	sp,sp,-16
    800015ac:	e406                	sd	ra,8(sp)
    800015ae:	e022                	sd	s0,0(sp)
    800015b0:	0800                	addi	s0,sp,16
    800015b2:	8736                	mv	a4,a3
  if(mappages(kernel_pagetable, va, sz, pa, perm) != 0)
    800015b4:	86ae                	mv	a3,a1
    800015b6:	85aa                	mv	a1,a0
    800015b8:	00008517          	auipc	a0,0x8
    800015bc:	a5853503          	ld	a0,-1448(a0) # 80009010 <kernel_pagetable>
    800015c0:	00000097          	auipc	ra,0x0
    800015c4:	f5c080e7          	jalr	-164(ra) # 8000151c <mappages>
    800015c8:	e509                	bnez	a0,800015d2 <kvmmap+0x28>
}
    800015ca:	60a2                	ld	ra,8(sp)
    800015cc:	6402                	ld	s0,0(sp)
    800015ce:	0141                	addi	sp,sp,16
    800015d0:	8082                	ret
    panic("kvmmap");
    800015d2:	00007517          	auipc	a0,0x7
    800015d6:	ba650513          	addi	a0,a0,-1114 # 80008178 <digits+0x138>
    800015da:	fffff097          	auipc	ra,0xfffff
    800015de:	f76080e7          	jalr	-138(ra) # 80000550 <panic>

00000000800015e2 <kvminit>:
{
    800015e2:	1101                	addi	sp,sp,-32
    800015e4:	ec06                	sd	ra,24(sp)
    800015e6:	e822                	sd	s0,16(sp)
    800015e8:	e426                	sd	s1,8(sp)
    800015ea:	1000                	addi	s0,sp,32
  kernel_pagetable = (pagetable_t) kalloc();
    800015ec:	fffff097          	auipc	ra,0xfffff
    800015f0:	58e080e7          	jalr	1422(ra) # 80000b7a <kalloc>
    800015f4:	00008797          	auipc	a5,0x8
    800015f8:	a0a7be23          	sd	a0,-1508(a5) # 80009010 <kernel_pagetable>
  memset(kernel_pagetable, 0, PGSIZE);
    800015fc:	6605                	lui	a2,0x1
    800015fe:	4581                	li	a1,0
    80001600:	00000097          	auipc	ra,0x0
    80001604:	b40080e7          	jalr	-1216(ra) # 80001140 <memset>
  kvmmap(UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001608:	4699                	li	a3,6
    8000160a:	6605                	lui	a2,0x1
    8000160c:	100005b7          	lui	a1,0x10000
    80001610:	10000537          	lui	a0,0x10000
    80001614:	00000097          	auipc	ra,0x0
    80001618:	f96080e7          	jalr	-106(ra) # 800015aa <kvmmap>
  kvmmap(VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    8000161c:	4699                	li	a3,6
    8000161e:	6605                	lui	a2,0x1
    80001620:	100015b7          	lui	a1,0x10001
    80001624:	10001537          	lui	a0,0x10001
    80001628:	00000097          	auipc	ra,0x0
    8000162c:	f82080e7          	jalr	-126(ra) # 800015aa <kvmmap>
  kvmmap(PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001630:	4699                	li	a3,6
    80001632:	00400637          	lui	a2,0x400
    80001636:	0c0005b7          	lui	a1,0xc000
    8000163a:	0c000537          	lui	a0,0xc000
    8000163e:	00000097          	auipc	ra,0x0
    80001642:	f6c080e7          	jalr	-148(ra) # 800015aa <kvmmap>
  kvmmap(KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001646:	00007497          	auipc	s1,0x7
    8000164a:	9ba48493          	addi	s1,s1,-1606 # 80008000 <etext>
    8000164e:	46a9                	li	a3,10
    80001650:	80007617          	auipc	a2,0x80007
    80001654:	9b060613          	addi	a2,a2,-1616 # 8000 <_entry-0x7fff8000>
    80001658:	4585                	li	a1,1
    8000165a:	05fe                	slli	a1,a1,0x1f
    8000165c:	852e                	mv	a0,a1
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	f4c080e7          	jalr	-180(ra) # 800015aa <kvmmap>
  kvmmap((uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001666:	4699                	li	a3,6
    80001668:	4645                	li	a2,17
    8000166a:	066e                	slli	a2,a2,0x1b
    8000166c:	8e05                	sub	a2,a2,s1
    8000166e:	85a6                	mv	a1,s1
    80001670:	8526                	mv	a0,s1
    80001672:	00000097          	auipc	ra,0x0
    80001676:	f38080e7          	jalr	-200(ra) # 800015aa <kvmmap>
  kvmmap(TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000167a:	46a9                	li	a3,10
    8000167c:	6605                	lui	a2,0x1
    8000167e:	00006597          	auipc	a1,0x6
    80001682:	98258593          	addi	a1,a1,-1662 # 80007000 <_trampoline>
    80001686:	04000537          	lui	a0,0x4000
    8000168a:	157d                	addi	a0,a0,-1
    8000168c:	0532                	slli	a0,a0,0xc
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	f1c080e7          	jalr	-228(ra) # 800015aa <kvmmap>
}
    80001696:	60e2                	ld	ra,24(sp)
    80001698:	6442                	ld	s0,16(sp)
    8000169a:	64a2                	ld	s1,8(sp)
    8000169c:	6105                	addi	sp,sp,32
    8000169e:	8082                	ret

00000000800016a0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800016a0:	715d                	addi	sp,sp,-80
    800016a2:	e486                	sd	ra,72(sp)
    800016a4:	e0a2                	sd	s0,64(sp)
    800016a6:	fc26                	sd	s1,56(sp)
    800016a8:	f84a                	sd	s2,48(sp)
    800016aa:	f44e                	sd	s3,40(sp)
    800016ac:	f052                	sd	s4,32(sp)
    800016ae:	ec56                	sd	s5,24(sp)
    800016b0:	e85a                	sd	s6,16(sp)
    800016b2:	e45e                	sd	s7,8(sp)
    800016b4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800016b6:	03459793          	slli	a5,a1,0x34
    800016ba:	e795                	bnez	a5,800016e6 <uvmunmap+0x46>
    800016bc:	8a2a                	mv	s4,a0
    800016be:	892e                	mv	s2,a1
    800016c0:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016c2:	0632                	slli	a2,a2,0xc
    800016c4:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800016c8:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800016ca:	6b05                	lui	s6,0x1
    800016cc:	0735e863          	bltu	a1,s3,8000173c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800016d0:	60a6                	ld	ra,72(sp)
    800016d2:	6406                	ld	s0,64(sp)
    800016d4:	74e2                	ld	s1,56(sp)
    800016d6:	7942                	ld	s2,48(sp)
    800016d8:	79a2                	ld	s3,40(sp)
    800016da:	7a02                	ld	s4,32(sp)
    800016dc:	6ae2                	ld	s5,24(sp)
    800016de:	6b42                	ld	s6,16(sp)
    800016e0:	6ba2                	ld	s7,8(sp)
    800016e2:	6161                	addi	sp,sp,80
    800016e4:	8082                	ret
    panic("uvmunmap: not aligned");
    800016e6:	00007517          	auipc	a0,0x7
    800016ea:	a9a50513          	addi	a0,a0,-1382 # 80008180 <digits+0x140>
    800016ee:	fffff097          	auipc	ra,0xfffff
    800016f2:	e62080e7          	jalr	-414(ra) # 80000550 <panic>
      panic("uvmunmap: walk");
    800016f6:	00007517          	auipc	a0,0x7
    800016fa:	aa250513          	addi	a0,a0,-1374 # 80008198 <digits+0x158>
    800016fe:	fffff097          	auipc	ra,0xfffff
    80001702:	e52080e7          	jalr	-430(ra) # 80000550 <panic>
      panic("uvmunmap: not mapped");
    80001706:	00007517          	auipc	a0,0x7
    8000170a:	aa250513          	addi	a0,a0,-1374 # 800081a8 <digits+0x168>
    8000170e:	fffff097          	auipc	ra,0xfffff
    80001712:	e42080e7          	jalr	-446(ra) # 80000550 <panic>
      panic("uvmunmap: not a leaf");
    80001716:	00007517          	auipc	a0,0x7
    8000171a:	aaa50513          	addi	a0,a0,-1366 # 800081c0 <digits+0x180>
    8000171e:	fffff097          	auipc	ra,0xfffff
    80001722:	e32080e7          	jalr	-462(ra) # 80000550 <panic>
      uint64 pa = PTE2PA(*pte);
    80001726:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001728:	0532                	slli	a0,a0,0xc
    8000172a:	fffff097          	auipc	ra,0xfffff
    8000172e:	302080e7          	jalr	770(ra) # 80000a2c <kfree>
    *pte = 0;
    80001732:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001736:	995a                	add	s2,s2,s6
    80001738:	f9397ce3          	bgeu	s2,s3,800016d0 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000173c:	4601                	li	a2,0
    8000173e:	85ca                	mv	a1,s2
    80001740:	8552                	mv	a0,s4
    80001742:	00000097          	auipc	ra,0x0
    80001746:	cce080e7          	jalr	-818(ra) # 80001410 <walk>
    8000174a:	84aa                	mv	s1,a0
    8000174c:	d54d                	beqz	a0,800016f6 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000174e:	6108                	ld	a0,0(a0)
    80001750:	00157793          	andi	a5,a0,1
    80001754:	dbcd                	beqz	a5,80001706 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001756:	3ff57793          	andi	a5,a0,1023
    8000175a:	fb778ee3          	beq	a5,s7,80001716 <uvmunmap+0x76>
    if(do_free){
    8000175e:	fc0a8ae3          	beqz	s5,80001732 <uvmunmap+0x92>
    80001762:	b7d1                	j	80001726 <uvmunmap+0x86>

0000000080001764 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001764:	1101                	addi	sp,sp,-32
    80001766:	ec06                	sd	ra,24(sp)
    80001768:	e822                	sd	s0,16(sp)
    8000176a:	e426                	sd	s1,8(sp)
    8000176c:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000176e:	fffff097          	auipc	ra,0xfffff
    80001772:	40c080e7          	jalr	1036(ra) # 80000b7a <kalloc>
    80001776:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001778:	c519                	beqz	a0,80001786 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000177a:	6605                	lui	a2,0x1
    8000177c:	4581                	li	a1,0
    8000177e:	00000097          	auipc	ra,0x0
    80001782:	9c2080e7          	jalr	-1598(ra) # 80001140 <memset>
  return pagetable;
}
    80001786:	8526                	mv	a0,s1
    80001788:	60e2                	ld	ra,24(sp)
    8000178a:	6442                	ld	s0,16(sp)
    8000178c:	64a2                	ld	s1,8(sp)
    8000178e:	6105                	addi	sp,sp,32
    80001790:	8082                	ret

0000000080001792 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    80001792:	7179                	addi	sp,sp,-48
    80001794:	f406                	sd	ra,40(sp)
    80001796:	f022                	sd	s0,32(sp)
    80001798:	ec26                	sd	s1,24(sp)
    8000179a:	e84a                	sd	s2,16(sp)
    8000179c:	e44e                	sd	s3,8(sp)
    8000179e:	e052                	sd	s4,0(sp)
    800017a0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800017a2:	6785                	lui	a5,0x1
    800017a4:	04f67863          	bgeu	a2,a5,800017f4 <uvminit+0x62>
    800017a8:	8a2a                	mv	s4,a0
    800017aa:	89ae                	mv	s3,a1
    800017ac:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800017ae:	fffff097          	auipc	ra,0xfffff
    800017b2:	3cc080e7          	jalr	972(ra) # 80000b7a <kalloc>
    800017b6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800017b8:	6605                	lui	a2,0x1
    800017ba:	4581                	li	a1,0
    800017bc:	00000097          	auipc	ra,0x0
    800017c0:	984080e7          	jalr	-1660(ra) # 80001140 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800017c4:	4779                	li	a4,30
    800017c6:	86ca                	mv	a3,s2
    800017c8:	6605                	lui	a2,0x1
    800017ca:	4581                	li	a1,0
    800017cc:	8552                	mv	a0,s4
    800017ce:	00000097          	auipc	ra,0x0
    800017d2:	d4e080e7          	jalr	-690(ra) # 8000151c <mappages>
  memmove(mem, src, sz);
    800017d6:	8626                	mv	a2,s1
    800017d8:	85ce                	mv	a1,s3
    800017da:	854a                	mv	a0,s2
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	9c4080e7          	jalr	-1596(ra) # 800011a0 <memmove>
}
    800017e4:	70a2                	ld	ra,40(sp)
    800017e6:	7402                	ld	s0,32(sp)
    800017e8:	64e2                	ld	s1,24(sp)
    800017ea:	6942                	ld	s2,16(sp)
    800017ec:	69a2                	ld	s3,8(sp)
    800017ee:	6a02                	ld	s4,0(sp)
    800017f0:	6145                	addi	sp,sp,48
    800017f2:	8082                	ret
    panic("inituvm: more than a page");
    800017f4:	00007517          	auipc	a0,0x7
    800017f8:	9e450513          	addi	a0,a0,-1564 # 800081d8 <digits+0x198>
    800017fc:	fffff097          	auipc	ra,0xfffff
    80001800:	d54080e7          	jalr	-684(ra) # 80000550 <panic>

0000000080001804 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001804:	1101                	addi	sp,sp,-32
    80001806:	ec06                	sd	ra,24(sp)
    80001808:	e822                	sd	s0,16(sp)
    8000180a:	e426                	sd	s1,8(sp)
    8000180c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000180e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001810:	00b67d63          	bgeu	a2,a1,8000182a <uvmdealloc+0x26>
    80001814:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001816:	6785                	lui	a5,0x1
    80001818:	17fd                	addi	a5,a5,-1
    8000181a:	00f60733          	add	a4,a2,a5
    8000181e:	767d                	lui	a2,0xfffff
    80001820:	8f71                	and	a4,a4,a2
    80001822:	97ae                	add	a5,a5,a1
    80001824:	8ff1                	and	a5,a5,a2
    80001826:	00f76863          	bltu	a4,a5,80001836 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000182a:	8526                	mv	a0,s1
    8000182c:	60e2                	ld	ra,24(sp)
    8000182e:	6442                	ld	s0,16(sp)
    80001830:	64a2                	ld	s1,8(sp)
    80001832:	6105                	addi	sp,sp,32
    80001834:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001836:	8f99                	sub	a5,a5,a4
    80001838:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000183a:	4685                	li	a3,1
    8000183c:	0007861b          	sext.w	a2,a5
    80001840:	85ba                	mv	a1,a4
    80001842:	00000097          	auipc	ra,0x0
    80001846:	e5e080e7          	jalr	-418(ra) # 800016a0 <uvmunmap>
    8000184a:	b7c5                	j	8000182a <uvmdealloc+0x26>

000000008000184c <uvmalloc>:
  if(newsz < oldsz)
    8000184c:	0ab66163          	bltu	a2,a1,800018ee <uvmalloc+0xa2>
{
    80001850:	7139                	addi	sp,sp,-64
    80001852:	fc06                	sd	ra,56(sp)
    80001854:	f822                	sd	s0,48(sp)
    80001856:	f426                	sd	s1,40(sp)
    80001858:	f04a                	sd	s2,32(sp)
    8000185a:	ec4e                	sd	s3,24(sp)
    8000185c:	e852                	sd	s4,16(sp)
    8000185e:	e456                	sd	s5,8(sp)
    80001860:	0080                	addi	s0,sp,64
    80001862:	8aaa                	mv	s5,a0
    80001864:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001866:	6985                	lui	s3,0x1
    80001868:	19fd                	addi	s3,s3,-1
    8000186a:	95ce                	add	a1,a1,s3
    8000186c:	79fd                	lui	s3,0xfffff
    8000186e:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001872:	08c9f063          	bgeu	s3,a2,800018f2 <uvmalloc+0xa6>
    80001876:	894e                	mv	s2,s3
    mem = kalloc();
    80001878:	fffff097          	auipc	ra,0xfffff
    8000187c:	302080e7          	jalr	770(ra) # 80000b7a <kalloc>
    80001880:	84aa                	mv	s1,a0
    if(mem == 0){
    80001882:	c51d                	beqz	a0,800018b0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    80001884:	6605                	lui	a2,0x1
    80001886:	4581                	li	a1,0
    80001888:	00000097          	auipc	ra,0x0
    8000188c:	8b8080e7          	jalr	-1864(ra) # 80001140 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    80001890:	4779                	li	a4,30
    80001892:	86a6                	mv	a3,s1
    80001894:	6605                	lui	a2,0x1
    80001896:	85ca                	mv	a1,s2
    80001898:	8556                	mv	a0,s5
    8000189a:	00000097          	auipc	ra,0x0
    8000189e:	c82080e7          	jalr	-894(ra) # 8000151c <mappages>
    800018a2:	e905                	bnez	a0,800018d2 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800018a4:	6785                	lui	a5,0x1
    800018a6:	993e                	add	s2,s2,a5
    800018a8:	fd4968e3          	bltu	s2,s4,80001878 <uvmalloc+0x2c>
  return newsz;
    800018ac:	8552                	mv	a0,s4
    800018ae:	a809                	j	800018c0 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800018b0:	864e                	mv	a2,s3
    800018b2:	85ca                	mv	a1,s2
    800018b4:	8556                	mv	a0,s5
    800018b6:	00000097          	auipc	ra,0x0
    800018ba:	f4e080e7          	jalr	-178(ra) # 80001804 <uvmdealloc>
      return 0;
    800018be:	4501                	li	a0,0
}
    800018c0:	70e2                	ld	ra,56(sp)
    800018c2:	7442                	ld	s0,48(sp)
    800018c4:	74a2                	ld	s1,40(sp)
    800018c6:	7902                	ld	s2,32(sp)
    800018c8:	69e2                	ld	s3,24(sp)
    800018ca:	6a42                	ld	s4,16(sp)
    800018cc:	6aa2                	ld	s5,8(sp)
    800018ce:	6121                	addi	sp,sp,64
    800018d0:	8082                	ret
      kfree(mem);
    800018d2:	8526                	mv	a0,s1
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	158080e7          	jalr	344(ra) # 80000a2c <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800018dc:	864e                	mv	a2,s3
    800018de:	85ca                	mv	a1,s2
    800018e0:	8556                	mv	a0,s5
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	f22080e7          	jalr	-222(ra) # 80001804 <uvmdealloc>
      return 0;
    800018ea:	4501                	li	a0,0
    800018ec:	bfd1                	j	800018c0 <uvmalloc+0x74>
    return oldsz;
    800018ee:	852e                	mv	a0,a1
}
    800018f0:	8082                	ret
  return newsz;
    800018f2:	8532                	mv	a0,a2
    800018f4:	b7f1                	j	800018c0 <uvmalloc+0x74>

00000000800018f6 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800018f6:	7179                	addi	sp,sp,-48
    800018f8:	f406                	sd	ra,40(sp)
    800018fa:	f022                	sd	s0,32(sp)
    800018fc:	ec26                	sd	s1,24(sp)
    800018fe:	e84a                	sd	s2,16(sp)
    80001900:	e44e                	sd	s3,8(sp)
    80001902:	e052                	sd	s4,0(sp)
    80001904:	1800                	addi	s0,sp,48
    80001906:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001908:	84aa                	mv	s1,a0
    8000190a:	6905                	lui	s2,0x1
    8000190c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000190e:	4985                	li	s3,1
    80001910:	a821                	j	80001928 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001912:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001914:	0532                	slli	a0,a0,0xc
    80001916:	00000097          	auipc	ra,0x0
    8000191a:	fe0080e7          	jalr	-32(ra) # 800018f6 <freewalk>
      pagetable[i] = 0;
    8000191e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001922:	04a1                	addi	s1,s1,8
    80001924:	03248163          	beq	s1,s2,80001946 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001928:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000192a:	00f57793          	andi	a5,a0,15
    8000192e:	ff3782e3          	beq	a5,s3,80001912 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001932:	8905                	andi	a0,a0,1
    80001934:	d57d                	beqz	a0,80001922 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001936:	00007517          	auipc	a0,0x7
    8000193a:	8c250513          	addi	a0,a0,-1854 # 800081f8 <digits+0x1b8>
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	c12080e7          	jalr	-1006(ra) # 80000550 <panic>
    }
  }
  kfree((void*)pagetable);
    80001946:	8552                	mv	a0,s4
    80001948:	fffff097          	auipc	ra,0xfffff
    8000194c:	0e4080e7          	jalr	228(ra) # 80000a2c <kfree>
}
    80001950:	70a2                	ld	ra,40(sp)
    80001952:	7402                	ld	s0,32(sp)
    80001954:	64e2                	ld	s1,24(sp)
    80001956:	6942                	ld	s2,16(sp)
    80001958:	69a2                	ld	s3,8(sp)
    8000195a:	6a02                	ld	s4,0(sp)
    8000195c:	6145                	addi	sp,sp,48
    8000195e:	8082                	ret

0000000080001960 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001960:	1101                	addi	sp,sp,-32
    80001962:	ec06                	sd	ra,24(sp)
    80001964:	e822                	sd	s0,16(sp)
    80001966:	e426                	sd	s1,8(sp)
    80001968:	1000                	addi	s0,sp,32
    8000196a:	84aa                	mv	s1,a0
  if(sz > 0)
    8000196c:	e999                	bnez	a1,80001982 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000196e:	8526                	mv	a0,s1
    80001970:	00000097          	auipc	ra,0x0
    80001974:	f86080e7          	jalr	-122(ra) # 800018f6 <freewalk>
}
    80001978:	60e2                	ld	ra,24(sp)
    8000197a:	6442                	ld	s0,16(sp)
    8000197c:	64a2                	ld	s1,8(sp)
    8000197e:	6105                	addi	sp,sp,32
    80001980:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001982:	6605                	lui	a2,0x1
    80001984:	167d                	addi	a2,a2,-1
    80001986:	962e                	add	a2,a2,a1
    80001988:	4685                	li	a3,1
    8000198a:	8231                	srli	a2,a2,0xc
    8000198c:	4581                	li	a1,0
    8000198e:	00000097          	auipc	ra,0x0
    80001992:	d12080e7          	jalr	-750(ra) # 800016a0 <uvmunmap>
    80001996:	bfe1                	j	8000196e <uvmfree+0xe>

0000000080001998 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001998:	c679                	beqz	a2,80001a66 <uvmcopy+0xce>
{
    8000199a:	715d                	addi	sp,sp,-80
    8000199c:	e486                	sd	ra,72(sp)
    8000199e:	e0a2                	sd	s0,64(sp)
    800019a0:	fc26                	sd	s1,56(sp)
    800019a2:	f84a                	sd	s2,48(sp)
    800019a4:	f44e                	sd	s3,40(sp)
    800019a6:	f052                	sd	s4,32(sp)
    800019a8:	ec56                	sd	s5,24(sp)
    800019aa:	e85a                	sd	s6,16(sp)
    800019ac:	e45e                	sd	s7,8(sp)
    800019ae:	0880                	addi	s0,sp,80
    800019b0:	8b2a                	mv	s6,a0
    800019b2:	8aae                	mv	s5,a1
    800019b4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800019b6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800019b8:	4601                	li	a2,0
    800019ba:	85ce                	mv	a1,s3
    800019bc:	855a                	mv	a0,s6
    800019be:	00000097          	auipc	ra,0x0
    800019c2:	a52080e7          	jalr	-1454(ra) # 80001410 <walk>
    800019c6:	c531                	beqz	a0,80001a12 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800019c8:	6118                	ld	a4,0(a0)
    800019ca:	00177793          	andi	a5,a4,1
    800019ce:	cbb1                	beqz	a5,80001a22 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800019d0:	00a75593          	srli	a1,a4,0xa
    800019d4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800019d8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800019dc:	fffff097          	auipc	ra,0xfffff
    800019e0:	19e080e7          	jalr	414(ra) # 80000b7a <kalloc>
    800019e4:	892a                	mv	s2,a0
    800019e6:	c939                	beqz	a0,80001a3c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800019e8:	6605                	lui	a2,0x1
    800019ea:	85de                	mv	a1,s7
    800019ec:	fffff097          	auipc	ra,0xfffff
    800019f0:	7b4080e7          	jalr	1972(ra) # 800011a0 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800019f4:	8726                	mv	a4,s1
    800019f6:	86ca                	mv	a3,s2
    800019f8:	6605                	lui	a2,0x1
    800019fa:	85ce                	mv	a1,s3
    800019fc:	8556                	mv	a0,s5
    800019fe:	00000097          	auipc	ra,0x0
    80001a02:	b1e080e7          	jalr	-1250(ra) # 8000151c <mappages>
    80001a06:	e515                	bnez	a0,80001a32 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001a08:	6785                	lui	a5,0x1
    80001a0a:	99be                	add	s3,s3,a5
    80001a0c:	fb49e6e3          	bltu	s3,s4,800019b8 <uvmcopy+0x20>
    80001a10:	a081                	j	80001a50 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001a12:	00006517          	auipc	a0,0x6
    80001a16:	7f650513          	addi	a0,a0,2038 # 80008208 <digits+0x1c8>
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	b36080e7          	jalr	-1226(ra) # 80000550 <panic>
      panic("uvmcopy: page not present");
    80001a22:	00007517          	auipc	a0,0x7
    80001a26:	80650513          	addi	a0,a0,-2042 # 80008228 <digits+0x1e8>
    80001a2a:	fffff097          	auipc	ra,0xfffff
    80001a2e:	b26080e7          	jalr	-1242(ra) # 80000550 <panic>
      kfree(mem);
    80001a32:	854a                	mv	a0,s2
    80001a34:	fffff097          	auipc	ra,0xfffff
    80001a38:	ff8080e7          	jalr	-8(ra) # 80000a2c <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001a3c:	4685                	li	a3,1
    80001a3e:	00c9d613          	srli	a2,s3,0xc
    80001a42:	4581                	li	a1,0
    80001a44:	8556                	mv	a0,s5
    80001a46:	00000097          	auipc	ra,0x0
    80001a4a:	c5a080e7          	jalr	-934(ra) # 800016a0 <uvmunmap>
  return -1;
    80001a4e:	557d                	li	a0,-1
}
    80001a50:	60a6                	ld	ra,72(sp)
    80001a52:	6406                	ld	s0,64(sp)
    80001a54:	74e2                	ld	s1,56(sp)
    80001a56:	7942                	ld	s2,48(sp)
    80001a58:	79a2                	ld	s3,40(sp)
    80001a5a:	7a02                	ld	s4,32(sp)
    80001a5c:	6ae2                	ld	s5,24(sp)
    80001a5e:	6b42                	ld	s6,16(sp)
    80001a60:	6ba2                	ld	s7,8(sp)
    80001a62:	6161                	addi	sp,sp,80
    80001a64:	8082                	ret
  return 0;
    80001a66:	4501                	li	a0,0
}
    80001a68:	8082                	ret

0000000080001a6a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001a6a:	1141                	addi	sp,sp,-16
    80001a6c:	e406                	sd	ra,8(sp)
    80001a6e:	e022                	sd	s0,0(sp)
    80001a70:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001a72:	4601                	li	a2,0
    80001a74:	00000097          	auipc	ra,0x0
    80001a78:	99c080e7          	jalr	-1636(ra) # 80001410 <walk>
  if(pte == 0)
    80001a7c:	c901                	beqz	a0,80001a8c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001a7e:	611c                	ld	a5,0(a0)
    80001a80:	9bbd                	andi	a5,a5,-17
    80001a82:	e11c                	sd	a5,0(a0)
}
    80001a84:	60a2                	ld	ra,8(sp)
    80001a86:	6402                	ld	s0,0(sp)
    80001a88:	0141                	addi	sp,sp,16
    80001a8a:	8082                	ret
    panic("uvmclear");
    80001a8c:	00006517          	auipc	a0,0x6
    80001a90:	7bc50513          	addi	a0,a0,1980 # 80008248 <digits+0x208>
    80001a94:	fffff097          	auipc	ra,0xfffff
    80001a98:	abc080e7          	jalr	-1348(ra) # 80000550 <panic>

0000000080001a9c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001a9c:	c6bd                	beqz	a3,80001b0a <copyout+0x6e>
{
    80001a9e:	715d                	addi	sp,sp,-80
    80001aa0:	e486                	sd	ra,72(sp)
    80001aa2:	e0a2                	sd	s0,64(sp)
    80001aa4:	fc26                	sd	s1,56(sp)
    80001aa6:	f84a                	sd	s2,48(sp)
    80001aa8:	f44e                	sd	s3,40(sp)
    80001aaa:	f052                	sd	s4,32(sp)
    80001aac:	ec56                	sd	s5,24(sp)
    80001aae:	e85a                	sd	s6,16(sp)
    80001ab0:	e45e                	sd	s7,8(sp)
    80001ab2:	e062                	sd	s8,0(sp)
    80001ab4:	0880                	addi	s0,sp,80
    80001ab6:	8b2a                	mv	s6,a0
    80001ab8:	8c2e                	mv	s8,a1
    80001aba:	8a32                	mv	s4,a2
    80001abc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    80001abe:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001ac0:	6a85                	lui	s5,0x1
    80001ac2:	a015                	j	80001ae6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001ac4:	9562                	add	a0,a0,s8
    80001ac6:	0004861b          	sext.w	a2,s1
    80001aca:	85d2                	mv	a1,s4
    80001acc:	41250533          	sub	a0,a0,s2
    80001ad0:	fffff097          	auipc	ra,0xfffff
    80001ad4:	6d0080e7          	jalr	1744(ra) # 800011a0 <memmove>

    len -= n;
    80001ad8:	409989b3          	sub	s3,s3,s1
    src += n;
    80001adc:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    80001ade:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001ae2:	02098263          	beqz	s3,80001b06 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001ae6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001aea:	85ca                	mv	a1,s2
    80001aec:	855a                	mv	a0,s6
    80001aee:	00000097          	auipc	ra,0x0
    80001af2:	9ec080e7          	jalr	-1556(ra) # 800014da <walkaddr>
    if(pa0 == 0)
    80001af6:	cd01                	beqz	a0,80001b0e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001af8:	418904b3          	sub	s1,s2,s8
    80001afc:	94d6                	add	s1,s1,s5
    if(n > len)
    80001afe:	fc99f3e3          	bgeu	s3,s1,80001ac4 <copyout+0x28>
    80001b02:	84ce                	mv	s1,s3
    80001b04:	b7c1                	j	80001ac4 <copyout+0x28>
  }
  return 0;
    80001b06:	4501                	li	a0,0
    80001b08:	a021                	j	80001b10 <copyout+0x74>
    80001b0a:	4501                	li	a0,0
}
    80001b0c:	8082                	ret
      return -1;
    80001b0e:	557d                	li	a0,-1
}
    80001b10:	60a6                	ld	ra,72(sp)
    80001b12:	6406                	ld	s0,64(sp)
    80001b14:	74e2                	ld	s1,56(sp)
    80001b16:	7942                	ld	s2,48(sp)
    80001b18:	79a2                	ld	s3,40(sp)
    80001b1a:	7a02                	ld	s4,32(sp)
    80001b1c:	6ae2                	ld	s5,24(sp)
    80001b1e:	6b42                	ld	s6,16(sp)
    80001b20:	6ba2                	ld	s7,8(sp)
    80001b22:	6c02                	ld	s8,0(sp)
    80001b24:	6161                	addi	sp,sp,80
    80001b26:	8082                	ret

0000000080001b28 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001b28:	c6bd                	beqz	a3,80001b96 <copyin+0x6e>
{
    80001b2a:	715d                	addi	sp,sp,-80
    80001b2c:	e486                	sd	ra,72(sp)
    80001b2e:	e0a2                	sd	s0,64(sp)
    80001b30:	fc26                	sd	s1,56(sp)
    80001b32:	f84a                	sd	s2,48(sp)
    80001b34:	f44e                	sd	s3,40(sp)
    80001b36:	f052                	sd	s4,32(sp)
    80001b38:	ec56                	sd	s5,24(sp)
    80001b3a:	e85a                	sd	s6,16(sp)
    80001b3c:	e45e                	sd	s7,8(sp)
    80001b3e:	e062                	sd	s8,0(sp)
    80001b40:	0880                	addi	s0,sp,80
    80001b42:	8b2a                	mv	s6,a0
    80001b44:	8a2e                	mv	s4,a1
    80001b46:	8c32                	mv	s8,a2
    80001b48:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001b4a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001b4c:	6a85                	lui	s5,0x1
    80001b4e:	a015                	j	80001b72 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001b50:	9562                	add	a0,a0,s8
    80001b52:	0004861b          	sext.w	a2,s1
    80001b56:	412505b3          	sub	a1,a0,s2
    80001b5a:	8552                	mv	a0,s4
    80001b5c:	fffff097          	auipc	ra,0xfffff
    80001b60:	644080e7          	jalr	1604(ra) # 800011a0 <memmove>

    len -= n;
    80001b64:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001b68:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001b6a:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001b6e:	02098263          	beqz	s3,80001b92 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001b72:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001b76:	85ca                	mv	a1,s2
    80001b78:	855a                	mv	a0,s6
    80001b7a:	00000097          	auipc	ra,0x0
    80001b7e:	960080e7          	jalr	-1696(ra) # 800014da <walkaddr>
    if(pa0 == 0)
    80001b82:	cd01                	beqz	a0,80001b9a <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001b84:	418904b3          	sub	s1,s2,s8
    80001b88:	94d6                	add	s1,s1,s5
    if(n > len)
    80001b8a:	fc99f3e3          	bgeu	s3,s1,80001b50 <copyin+0x28>
    80001b8e:	84ce                	mv	s1,s3
    80001b90:	b7c1                	j	80001b50 <copyin+0x28>
  }
  return 0;
    80001b92:	4501                	li	a0,0
    80001b94:	a021                	j	80001b9c <copyin+0x74>
    80001b96:	4501                	li	a0,0
}
    80001b98:	8082                	ret
      return -1;
    80001b9a:	557d                	li	a0,-1
}
    80001b9c:	60a6                	ld	ra,72(sp)
    80001b9e:	6406                	ld	s0,64(sp)
    80001ba0:	74e2                	ld	s1,56(sp)
    80001ba2:	7942                	ld	s2,48(sp)
    80001ba4:	79a2                	ld	s3,40(sp)
    80001ba6:	7a02                	ld	s4,32(sp)
    80001ba8:	6ae2                	ld	s5,24(sp)
    80001baa:	6b42                	ld	s6,16(sp)
    80001bac:	6ba2                	ld	s7,8(sp)
    80001bae:	6c02                	ld	s8,0(sp)
    80001bb0:	6161                	addi	sp,sp,80
    80001bb2:	8082                	ret

0000000080001bb4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001bb4:	c6c5                	beqz	a3,80001c5c <copyinstr+0xa8>
{
    80001bb6:	715d                	addi	sp,sp,-80
    80001bb8:	e486                	sd	ra,72(sp)
    80001bba:	e0a2                	sd	s0,64(sp)
    80001bbc:	fc26                	sd	s1,56(sp)
    80001bbe:	f84a                	sd	s2,48(sp)
    80001bc0:	f44e                	sd	s3,40(sp)
    80001bc2:	f052                	sd	s4,32(sp)
    80001bc4:	ec56                	sd	s5,24(sp)
    80001bc6:	e85a                	sd	s6,16(sp)
    80001bc8:	e45e                	sd	s7,8(sp)
    80001bca:	0880                	addi	s0,sp,80
    80001bcc:	8a2a                	mv	s4,a0
    80001bce:	8b2e                	mv	s6,a1
    80001bd0:	8bb2                	mv	s7,a2
    80001bd2:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001bd4:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001bd6:	6985                	lui	s3,0x1
    80001bd8:	a035                	j	80001c04 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001bda:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001bde:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001be0:	0017b793          	seqz	a5,a5
    80001be4:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001be8:	60a6                	ld	ra,72(sp)
    80001bea:	6406                	ld	s0,64(sp)
    80001bec:	74e2                	ld	s1,56(sp)
    80001bee:	7942                	ld	s2,48(sp)
    80001bf0:	79a2                	ld	s3,40(sp)
    80001bf2:	7a02                	ld	s4,32(sp)
    80001bf4:	6ae2                	ld	s5,24(sp)
    80001bf6:	6b42                	ld	s6,16(sp)
    80001bf8:	6ba2                	ld	s7,8(sp)
    80001bfa:	6161                	addi	sp,sp,80
    80001bfc:	8082                	ret
    srcva = va0 + PGSIZE;
    80001bfe:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001c02:	c8a9                	beqz	s1,80001c54 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001c04:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001c08:	85ca                	mv	a1,s2
    80001c0a:	8552                	mv	a0,s4
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	8ce080e7          	jalr	-1842(ra) # 800014da <walkaddr>
    if(pa0 == 0)
    80001c14:	c131                	beqz	a0,80001c58 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001c16:	41790833          	sub	a6,s2,s7
    80001c1a:	984e                	add	a6,a6,s3
    if(n > max)
    80001c1c:	0104f363          	bgeu	s1,a6,80001c22 <copyinstr+0x6e>
    80001c20:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001c22:	955e                	add	a0,a0,s7
    80001c24:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001c28:	fc080be3          	beqz	a6,80001bfe <copyinstr+0x4a>
    80001c2c:	985a                	add	a6,a6,s6
    80001c2e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001c30:	41650633          	sub	a2,a0,s6
    80001c34:	14fd                	addi	s1,s1,-1
    80001c36:	9b26                	add	s6,s6,s1
    80001c38:	00f60733          	add	a4,a2,a5
    80001c3c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffd6fd8>
    80001c40:	df49                	beqz	a4,80001bda <copyinstr+0x26>
        *dst = *p;
    80001c42:	00e78023          	sb	a4,0(a5)
      --max;
    80001c46:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001c4a:	0785                	addi	a5,a5,1
    while(n > 0){
    80001c4c:	ff0796e3          	bne	a5,a6,80001c38 <copyinstr+0x84>
      dst++;
    80001c50:	8b42                	mv	s6,a6
    80001c52:	b775                	j	80001bfe <copyinstr+0x4a>
    80001c54:	4781                	li	a5,0
    80001c56:	b769                	j	80001be0 <copyinstr+0x2c>
      return -1;
    80001c58:	557d                	li	a0,-1
    80001c5a:	b779                	j	80001be8 <copyinstr+0x34>
  int got_null = 0;
    80001c5c:	4781                	li	a5,0
  if(got_null){
    80001c5e:	0017b793          	seqz	a5,a5
    80001c62:	40f00533          	neg	a0,a5
}
    80001c66:	8082                	ret

0000000080001c68 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80001c68:	1101                	addi	sp,sp,-32
    80001c6a:	ec06                	sd	ra,24(sp)
    80001c6c:	e822                	sd	s0,16(sp)
    80001c6e:	e426                	sd	s1,8(sp)
    80001c70:	1000                	addi	s0,sp,32
    80001c72:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001c74:	fffff097          	auipc	ra,0xfffff
    80001c78:	072080e7          	jalr	114(ra) # 80000ce6 <holding>
    80001c7c:	c909                	beqz	a0,80001c8e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    80001c7e:	789c                	ld	a5,48(s1)
    80001c80:	00978f63          	beq	a5,s1,80001c9e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80001c84:	60e2                	ld	ra,24(sp)
    80001c86:	6442                	ld	s0,16(sp)
    80001c88:	64a2                	ld	s1,8(sp)
    80001c8a:	6105                	addi	sp,sp,32
    80001c8c:	8082                	ret
    panic("wakeup1");
    80001c8e:	00006517          	auipc	a0,0x6
    80001c92:	5ca50513          	addi	a0,a0,1482 # 80008258 <digits+0x218>
    80001c96:	fffff097          	auipc	ra,0xfffff
    80001c9a:	8ba080e7          	jalr	-1862(ra) # 80000550 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    80001c9e:	5098                	lw	a4,32(s1)
    80001ca0:	4785                	li	a5,1
    80001ca2:	fef711e3          	bne	a4,a5,80001c84 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80001ca6:	4789                	li	a5,2
    80001ca8:	d09c                	sw	a5,32(s1)
}
    80001caa:	bfe9                	j	80001c84 <wakeup1+0x1c>

0000000080001cac <procinit>:
{
    80001cac:	715d                	addi	sp,sp,-80
    80001cae:	e486                	sd	ra,72(sp)
    80001cb0:	e0a2                	sd	s0,64(sp)
    80001cb2:	fc26                	sd	s1,56(sp)
    80001cb4:	f84a                	sd	s2,48(sp)
    80001cb6:	f44e                	sd	s3,40(sp)
    80001cb8:	f052                	sd	s4,32(sp)
    80001cba:	ec56                	sd	s5,24(sp)
    80001cbc:	e85a                	sd	s6,16(sp)
    80001cbe:	e45e                	sd	s7,8(sp)
    80001cc0:	0880                	addi	s0,sp,80
  initlock(&pid_lock, "nextpid");
    80001cc2:	00006597          	auipc	a1,0x6
    80001cc6:	59e58593          	addi	a1,a1,1438 # 80008260 <digits+0x220>
    80001cca:	00010517          	auipc	a0,0x10
    80001cce:	6be50513          	addi	a0,a0,1726 # 80012388 <pid_lock>
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	20a080e7          	jalr	522(ra) # 80000edc <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cda:	00011917          	auipc	s2,0x11
    80001cde:	ace90913          	addi	s2,s2,-1330 # 800127a8 <proc>
      initlock(&p->lock, "proc");
    80001ce2:	00006b97          	auipc	s7,0x6
    80001ce6:	586b8b93          	addi	s7,s7,1414 # 80008268 <digits+0x228>
      uint64 va = KSTACK((int) (p - proc));
    80001cea:	8b4a                	mv	s6,s2
    80001cec:	00006a97          	auipc	s5,0x6
    80001cf0:	314a8a93          	addi	s5,s5,788 # 80008000 <etext>
    80001cf4:	040009b7          	lui	s3,0x4000
    80001cf8:	19fd                	addi	s3,s3,-1
    80001cfa:	09b2                	slli	s3,s3,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001cfc:	00016a17          	auipc	s4,0x16
    80001d00:	6aca0a13          	addi	s4,s4,1708 # 800183a8 <tickslock>
      initlock(&p->lock, "proc");
    80001d04:	85de                	mv	a1,s7
    80001d06:	854a                	mv	a0,s2
    80001d08:	fffff097          	auipc	ra,0xfffff
    80001d0c:	1d4080e7          	jalr	468(ra) # 80000edc <initlock>
      char *pa = kalloc();
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	e6a080e7          	jalr	-406(ra) # 80000b7a <kalloc>
    80001d18:	85aa                	mv	a1,a0
      if(pa == 0)
    80001d1a:	c929                	beqz	a0,80001d6c <procinit+0xc0>
      uint64 va = KSTACK((int) (p - proc));
    80001d1c:	416904b3          	sub	s1,s2,s6
    80001d20:	8491                	srai	s1,s1,0x4
    80001d22:	000ab783          	ld	a5,0(s5)
    80001d26:	02f484b3          	mul	s1,s1,a5
    80001d2a:	2485                	addiw	s1,s1,1
    80001d2c:	00d4949b          	slliw	s1,s1,0xd
    80001d30:	409984b3          	sub	s1,s3,s1
      kvmmap(va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001d34:	4699                	li	a3,6
    80001d36:	6605                	lui	a2,0x1
    80001d38:	8526                	mv	a0,s1
    80001d3a:	00000097          	auipc	ra,0x0
    80001d3e:	870080e7          	jalr	-1936(ra) # 800015aa <kvmmap>
      p->kstack = va;
    80001d42:	04993423          	sd	s1,72(s2)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001d46:	17090913          	addi	s2,s2,368
    80001d4a:	fb491de3          	bne	s2,s4,80001d04 <procinit+0x58>
  kvminithart();
    80001d4e:	fffff097          	auipc	ra,0xfffff
    80001d52:	768080e7          	jalr	1896(ra) # 800014b6 <kvminithart>
}
    80001d56:	60a6                	ld	ra,72(sp)
    80001d58:	6406                	ld	s0,64(sp)
    80001d5a:	74e2                	ld	s1,56(sp)
    80001d5c:	7942                	ld	s2,48(sp)
    80001d5e:	79a2                	ld	s3,40(sp)
    80001d60:	7a02                	ld	s4,32(sp)
    80001d62:	6ae2                	ld	s5,24(sp)
    80001d64:	6b42                	ld	s6,16(sp)
    80001d66:	6ba2                	ld	s7,8(sp)
    80001d68:	6161                	addi	sp,sp,80
    80001d6a:	8082                	ret
        panic("kalloc");
    80001d6c:	00006517          	auipc	a0,0x6
    80001d70:	50450513          	addi	a0,a0,1284 # 80008270 <digits+0x230>
    80001d74:	ffffe097          	auipc	ra,0xffffe
    80001d78:	7dc080e7          	jalr	2012(ra) # 80000550 <panic>

0000000080001d7c <cpuid>:
{
    80001d7c:	1141                	addi	sp,sp,-16
    80001d7e:	e422                	sd	s0,8(sp)
    80001d80:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001d82:	8512                	mv	a0,tp
}
    80001d84:	2501                	sext.w	a0,a0
    80001d86:	6422                	ld	s0,8(sp)
    80001d88:	0141                	addi	sp,sp,16
    80001d8a:	8082                	ret

0000000080001d8c <mycpu>:
mycpu(void) {
    80001d8c:	1141                	addi	sp,sp,-16
    80001d8e:	e422                	sd	s0,8(sp)
    80001d90:	0800                	addi	s0,sp,16
    80001d92:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    80001d94:	2781                	sext.w	a5,a5
    80001d96:	079e                	slli	a5,a5,0x7
}
    80001d98:	00010517          	auipc	a0,0x10
    80001d9c:	61050513          	addi	a0,a0,1552 # 800123a8 <cpus>
    80001da0:	953e                	add	a0,a0,a5
    80001da2:	6422                	ld	s0,8(sp)
    80001da4:	0141                	addi	sp,sp,16
    80001da6:	8082                	ret

0000000080001da8 <myproc>:
myproc(void) {
    80001da8:	1101                	addi	sp,sp,-32
    80001daa:	ec06                	sd	ra,24(sp)
    80001dac:	e822                	sd	s0,16(sp)
    80001dae:	e426                	sd	s1,8(sp)
    80001db0:	1000                	addi	s0,sp,32
  push_off();
    80001db2:	fffff097          	auipc	ra,0xfffff
    80001db6:	f62080e7          	jalr	-158(ra) # 80000d14 <push_off>
    80001dba:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    80001dbc:	2781                	sext.w	a5,a5
    80001dbe:	079e                	slli	a5,a5,0x7
    80001dc0:	00010717          	auipc	a4,0x10
    80001dc4:	5c870713          	addi	a4,a4,1480 # 80012388 <pid_lock>
    80001dc8:	97ba                	add	a5,a5,a4
    80001dca:	7384                	ld	s1,32(a5)
  pop_off();
    80001dcc:	fffff097          	auipc	ra,0xfffff
    80001dd0:	004080e7          	jalr	4(ra) # 80000dd0 <pop_off>
}
    80001dd4:	8526                	mv	a0,s1
    80001dd6:	60e2                	ld	ra,24(sp)
    80001dd8:	6442                	ld	s0,16(sp)
    80001dda:	64a2                	ld	s1,8(sp)
    80001ddc:	6105                	addi	sp,sp,32
    80001dde:	8082                	ret

0000000080001de0 <forkret>:
{
    80001de0:	1141                	addi	sp,sp,-16
    80001de2:	e406                	sd	ra,8(sp)
    80001de4:	e022                	sd	s0,0(sp)
    80001de6:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80001de8:	00000097          	auipc	ra,0x0
    80001dec:	fc0080e7          	jalr	-64(ra) # 80001da8 <myproc>
    80001df0:	fffff097          	auipc	ra,0xfffff
    80001df4:	040080e7          	jalr	64(ra) # 80000e30 <release>
  if (first) {
    80001df8:	00007797          	auipc	a5,0x7
    80001dfc:	ac87a783          	lw	a5,-1336(a5) # 800088c0 <first.1672>
    80001e00:	eb89                	bnez	a5,80001e12 <forkret+0x32>
  usertrapret();
    80001e02:	00001097          	auipc	ra,0x1
    80001e06:	c1c080e7          	jalr	-996(ra) # 80002a1e <usertrapret>
}
    80001e0a:	60a2                	ld	ra,8(sp)
    80001e0c:	6402                	ld	s0,0(sp)
    80001e0e:	0141                	addi	sp,sp,16
    80001e10:	8082                	ret
    first = 0;
    80001e12:	00007797          	auipc	a5,0x7
    80001e16:	aa07a723          	sw	zero,-1362(a5) # 800088c0 <first.1672>
    fsinit(ROOTDEV);
    80001e1a:	4505                	li	a0,1
    80001e1c:	00002097          	auipc	ra,0x2
    80001e20:	afe080e7          	jalr	-1282(ra) # 8000391a <fsinit>
    80001e24:	bff9                	j	80001e02 <forkret+0x22>

0000000080001e26 <allocpid>:
allocpid() {
    80001e26:	1101                	addi	sp,sp,-32
    80001e28:	ec06                	sd	ra,24(sp)
    80001e2a:	e822                	sd	s0,16(sp)
    80001e2c:	e426                	sd	s1,8(sp)
    80001e2e:	e04a                	sd	s2,0(sp)
    80001e30:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001e32:	00010917          	auipc	s2,0x10
    80001e36:	55690913          	addi	s2,s2,1366 # 80012388 <pid_lock>
    80001e3a:	854a                	mv	a0,s2
    80001e3c:	fffff097          	auipc	ra,0xfffff
    80001e40:	f24080e7          	jalr	-220(ra) # 80000d60 <acquire>
  pid = nextpid;
    80001e44:	00007797          	auipc	a5,0x7
    80001e48:	a8078793          	addi	a5,a5,-1408 # 800088c4 <nextpid>
    80001e4c:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001e4e:	0014871b          	addiw	a4,s1,1
    80001e52:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001e54:	854a                	mv	a0,s2
    80001e56:	fffff097          	auipc	ra,0xfffff
    80001e5a:	fda080e7          	jalr	-38(ra) # 80000e30 <release>
}
    80001e5e:	8526                	mv	a0,s1
    80001e60:	60e2                	ld	ra,24(sp)
    80001e62:	6442                	ld	s0,16(sp)
    80001e64:	64a2                	ld	s1,8(sp)
    80001e66:	6902                	ld	s2,0(sp)
    80001e68:	6105                	addi	sp,sp,32
    80001e6a:	8082                	ret

0000000080001e6c <proc_pagetable>:
{
    80001e6c:	1101                	addi	sp,sp,-32
    80001e6e:	ec06                	sd	ra,24(sp)
    80001e70:	e822                	sd	s0,16(sp)
    80001e72:	e426                	sd	s1,8(sp)
    80001e74:	e04a                	sd	s2,0(sp)
    80001e76:	1000                	addi	s0,sp,32
    80001e78:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001e7a:	00000097          	auipc	ra,0x0
    80001e7e:	8ea080e7          	jalr	-1814(ra) # 80001764 <uvmcreate>
    80001e82:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001e84:	c121                	beqz	a0,80001ec4 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001e86:	4729                	li	a4,10
    80001e88:	00005697          	auipc	a3,0x5
    80001e8c:	17868693          	addi	a3,a3,376 # 80007000 <_trampoline>
    80001e90:	6605                	lui	a2,0x1
    80001e92:	040005b7          	lui	a1,0x4000
    80001e96:	15fd                	addi	a1,a1,-1
    80001e98:	05b2                	slli	a1,a1,0xc
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	682080e7          	jalr	1666(ra) # 8000151c <mappages>
    80001ea2:	02054863          	bltz	a0,80001ed2 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001ea6:	4719                	li	a4,6
    80001ea8:	06093683          	ld	a3,96(s2)
    80001eac:	6605                	lui	a2,0x1
    80001eae:	020005b7          	lui	a1,0x2000
    80001eb2:	15fd                	addi	a1,a1,-1
    80001eb4:	05b6                	slli	a1,a1,0xd
    80001eb6:	8526                	mv	a0,s1
    80001eb8:	fffff097          	auipc	ra,0xfffff
    80001ebc:	664080e7          	jalr	1636(ra) # 8000151c <mappages>
    80001ec0:	02054163          	bltz	a0,80001ee2 <proc_pagetable+0x76>
}
    80001ec4:	8526                	mv	a0,s1
    80001ec6:	60e2                	ld	ra,24(sp)
    80001ec8:	6442                	ld	s0,16(sp)
    80001eca:	64a2                	ld	s1,8(sp)
    80001ecc:	6902                	ld	s2,0(sp)
    80001ece:	6105                	addi	sp,sp,32
    80001ed0:	8082                	ret
    uvmfree(pagetable, 0);
    80001ed2:	4581                	li	a1,0
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	00000097          	auipc	ra,0x0
    80001eda:	a8a080e7          	jalr	-1398(ra) # 80001960 <uvmfree>
    return 0;
    80001ede:	4481                	li	s1,0
    80001ee0:	b7d5                	j	80001ec4 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ee2:	4681                	li	a3,0
    80001ee4:	4605                	li	a2,1
    80001ee6:	040005b7          	lui	a1,0x4000
    80001eea:	15fd                	addi	a1,a1,-1
    80001eec:	05b2                	slli	a1,a1,0xc
    80001eee:	8526                	mv	a0,s1
    80001ef0:	fffff097          	auipc	ra,0xfffff
    80001ef4:	7b0080e7          	jalr	1968(ra) # 800016a0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001ef8:	4581                	li	a1,0
    80001efa:	8526                	mv	a0,s1
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	a64080e7          	jalr	-1436(ra) # 80001960 <uvmfree>
    return 0;
    80001f04:	4481                	li	s1,0
    80001f06:	bf7d                	j	80001ec4 <proc_pagetable+0x58>

0000000080001f08 <proc_freepagetable>:
{
    80001f08:	1101                	addi	sp,sp,-32
    80001f0a:	ec06                	sd	ra,24(sp)
    80001f0c:	e822                	sd	s0,16(sp)
    80001f0e:	e426                	sd	s1,8(sp)
    80001f10:	e04a                	sd	s2,0(sp)
    80001f12:	1000                	addi	s0,sp,32
    80001f14:	84aa                	mv	s1,a0
    80001f16:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f18:	4681                	li	a3,0
    80001f1a:	4605                	li	a2,1
    80001f1c:	040005b7          	lui	a1,0x4000
    80001f20:	15fd                	addi	a1,a1,-1
    80001f22:	05b2                	slli	a1,a1,0xc
    80001f24:	fffff097          	auipc	ra,0xfffff
    80001f28:	77c080e7          	jalr	1916(ra) # 800016a0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001f2c:	4681                	li	a3,0
    80001f2e:	4605                	li	a2,1
    80001f30:	020005b7          	lui	a1,0x2000
    80001f34:	15fd                	addi	a1,a1,-1
    80001f36:	05b6                	slli	a1,a1,0xd
    80001f38:	8526                	mv	a0,s1
    80001f3a:	fffff097          	auipc	ra,0xfffff
    80001f3e:	766080e7          	jalr	1894(ra) # 800016a0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001f42:	85ca                	mv	a1,s2
    80001f44:	8526                	mv	a0,s1
    80001f46:	00000097          	auipc	ra,0x0
    80001f4a:	a1a080e7          	jalr	-1510(ra) # 80001960 <uvmfree>
}
    80001f4e:	60e2                	ld	ra,24(sp)
    80001f50:	6442                	ld	s0,16(sp)
    80001f52:	64a2                	ld	s1,8(sp)
    80001f54:	6902                	ld	s2,0(sp)
    80001f56:	6105                	addi	sp,sp,32
    80001f58:	8082                	ret

0000000080001f5a <freeproc>:
{
    80001f5a:	1101                	addi	sp,sp,-32
    80001f5c:	ec06                	sd	ra,24(sp)
    80001f5e:	e822                	sd	s0,16(sp)
    80001f60:	e426                	sd	s1,8(sp)
    80001f62:	1000                	addi	s0,sp,32
    80001f64:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001f66:	7128                	ld	a0,96(a0)
    80001f68:	c509                	beqz	a0,80001f72 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001f6a:	fffff097          	auipc	ra,0xfffff
    80001f6e:	ac2080e7          	jalr	-1342(ra) # 80000a2c <kfree>
  p->trapframe = 0;
    80001f72:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001f76:	6ca8                	ld	a0,88(s1)
    80001f78:	c511                	beqz	a0,80001f84 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001f7a:	68ac                	ld	a1,80(s1)
    80001f7c:	00000097          	auipc	ra,0x0
    80001f80:	f8c080e7          	jalr	-116(ra) # 80001f08 <proc_freepagetable>
  p->pagetable = 0;
    80001f84:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001f88:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001f8c:	0404a023          	sw	zero,64(s1)
  p->parent = 0;
    80001f90:	0204b423          	sd	zero,40(s1)
  p->name[0] = 0;
    80001f94:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001f98:	0204b823          	sd	zero,48(s1)
  p->killed = 0;
    80001f9c:	0204ac23          	sw	zero,56(s1)
  p->xstate = 0;
    80001fa0:	0204ae23          	sw	zero,60(s1)
  p->state = UNUSED;
    80001fa4:	0204a023          	sw	zero,32(s1)
}
    80001fa8:	60e2                	ld	ra,24(sp)
    80001faa:	6442                	ld	s0,16(sp)
    80001fac:	64a2                	ld	s1,8(sp)
    80001fae:	6105                	addi	sp,sp,32
    80001fb0:	8082                	ret

0000000080001fb2 <allocproc>:
{
    80001fb2:	1101                	addi	sp,sp,-32
    80001fb4:	ec06                	sd	ra,24(sp)
    80001fb6:	e822                	sd	s0,16(sp)
    80001fb8:	e426                	sd	s1,8(sp)
    80001fba:	e04a                	sd	s2,0(sp)
    80001fbc:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fbe:	00010497          	auipc	s1,0x10
    80001fc2:	7ea48493          	addi	s1,s1,2026 # 800127a8 <proc>
    80001fc6:	00016917          	auipc	s2,0x16
    80001fca:	3e290913          	addi	s2,s2,994 # 800183a8 <tickslock>
    acquire(&p->lock);
    80001fce:	8526                	mv	a0,s1
    80001fd0:	fffff097          	auipc	ra,0xfffff
    80001fd4:	d90080e7          	jalr	-624(ra) # 80000d60 <acquire>
    if(p->state == UNUSED) {
    80001fd8:	509c                	lw	a5,32(s1)
    80001fda:	cf81                	beqz	a5,80001ff2 <allocproc+0x40>
      release(&p->lock);
    80001fdc:	8526                	mv	a0,s1
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	e52080e7          	jalr	-430(ra) # 80000e30 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001fe6:	17048493          	addi	s1,s1,368
    80001fea:	ff2492e3          	bne	s1,s2,80001fce <allocproc+0x1c>
  return 0;
    80001fee:	4481                	li	s1,0
    80001ff0:	a0b9                	j	8000203e <allocproc+0x8c>
  p->pid = allocpid();
    80001ff2:	00000097          	auipc	ra,0x0
    80001ff6:	e34080e7          	jalr	-460(ra) # 80001e26 <allocpid>
    80001ffa:	c0a8                	sw	a0,64(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001ffc:	fffff097          	auipc	ra,0xfffff
    80002000:	b7e080e7          	jalr	-1154(ra) # 80000b7a <kalloc>
    80002004:	892a                	mv	s2,a0
    80002006:	f0a8                	sd	a0,96(s1)
    80002008:	c131                	beqz	a0,8000204c <allocproc+0x9a>
  p->pagetable = proc_pagetable(p);
    8000200a:	8526                	mv	a0,s1
    8000200c:	00000097          	auipc	ra,0x0
    80002010:	e60080e7          	jalr	-416(ra) # 80001e6c <proc_pagetable>
    80002014:	892a                	mv	s2,a0
    80002016:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80002018:	c129                	beqz	a0,8000205a <allocproc+0xa8>
  memset(&p->context, 0, sizeof(p->context));
    8000201a:	07000613          	li	a2,112
    8000201e:	4581                	li	a1,0
    80002020:	06848513          	addi	a0,s1,104
    80002024:	fffff097          	auipc	ra,0xfffff
    80002028:	11c080e7          	jalr	284(ra) # 80001140 <memset>
  p->context.ra = (uint64)forkret;
    8000202c:	00000797          	auipc	a5,0x0
    80002030:	db478793          	addi	a5,a5,-588 # 80001de0 <forkret>
    80002034:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002036:	64bc                	ld	a5,72(s1)
    80002038:	6705                	lui	a4,0x1
    8000203a:	97ba                	add	a5,a5,a4
    8000203c:	f8bc                	sd	a5,112(s1)
}
    8000203e:	8526                	mv	a0,s1
    80002040:	60e2                	ld	ra,24(sp)
    80002042:	6442                	ld	s0,16(sp)
    80002044:	64a2                	ld	s1,8(sp)
    80002046:	6902                	ld	s2,0(sp)
    80002048:	6105                	addi	sp,sp,32
    8000204a:	8082                	ret
    release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	de2080e7          	jalr	-542(ra) # 80000e30 <release>
    return 0;
    80002056:	84ca                	mv	s1,s2
    80002058:	b7dd                	j	8000203e <allocproc+0x8c>
    freeproc(p);
    8000205a:	8526                	mv	a0,s1
    8000205c:	00000097          	auipc	ra,0x0
    80002060:	efe080e7          	jalr	-258(ra) # 80001f5a <freeproc>
    release(&p->lock);
    80002064:	8526                	mv	a0,s1
    80002066:	fffff097          	auipc	ra,0xfffff
    8000206a:	dca080e7          	jalr	-566(ra) # 80000e30 <release>
    return 0;
    8000206e:	84ca                	mv	s1,s2
    80002070:	b7f9                	j	8000203e <allocproc+0x8c>

0000000080002072 <userinit>:
{
    80002072:	1101                	addi	sp,sp,-32
    80002074:	ec06                	sd	ra,24(sp)
    80002076:	e822                	sd	s0,16(sp)
    80002078:	e426                	sd	s1,8(sp)
    8000207a:	1000                	addi	s0,sp,32
  p = allocproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	f36080e7          	jalr	-202(ra) # 80001fb2 <allocproc>
    80002084:	84aa                	mv	s1,a0
  initproc = p;
    80002086:	00007797          	auipc	a5,0x7
    8000208a:	f8a7b923          	sd	a0,-110(a5) # 80009018 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    8000208e:	03400613          	li	a2,52
    80002092:	00007597          	auipc	a1,0x7
    80002096:	87658593          	addi	a1,a1,-1930 # 80008908 <initcode>
    8000209a:	6d28                	ld	a0,88(a0)
    8000209c:	fffff097          	auipc	ra,0xfffff
    800020a0:	6f6080e7          	jalr	1782(ra) # 80001792 <uvminit>
  p->sz = PGSIZE;
    800020a4:	6785                	lui	a5,0x1
    800020a6:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    800020a8:	70b8                	ld	a4,96(s1)
    800020aa:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800020ae:	70b8                	ld	a4,96(s1)
    800020b0:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800020b2:	4641                	li	a2,16
    800020b4:	00006597          	auipc	a1,0x6
    800020b8:	1c458593          	addi	a1,a1,452 # 80008278 <digits+0x238>
    800020bc:	16048513          	addi	a0,s1,352
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	1d6080e7          	jalr	470(ra) # 80001296 <safestrcpy>
  p->cwd = namei("/");
    800020c8:	00006517          	auipc	a0,0x6
    800020cc:	1c050513          	addi	a0,a0,448 # 80008288 <digits+0x248>
    800020d0:	00002097          	auipc	ra,0x2
    800020d4:	276080e7          	jalr	630(ra) # 80004346 <namei>
    800020d8:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800020dc:	4789                	li	a5,2
    800020de:	d09c                	sw	a5,32(s1)
  release(&p->lock);
    800020e0:	8526                	mv	a0,s1
    800020e2:	fffff097          	auipc	ra,0xfffff
    800020e6:	d4e080e7          	jalr	-690(ra) # 80000e30 <release>
}
    800020ea:	60e2                	ld	ra,24(sp)
    800020ec:	6442                	ld	s0,16(sp)
    800020ee:	64a2                	ld	s1,8(sp)
    800020f0:	6105                	addi	sp,sp,32
    800020f2:	8082                	ret

00000000800020f4 <growproc>:
{
    800020f4:	1101                	addi	sp,sp,-32
    800020f6:	ec06                	sd	ra,24(sp)
    800020f8:	e822                	sd	s0,16(sp)
    800020fa:	e426                	sd	s1,8(sp)
    800020fc:	e04a                	sd	s2,0(sp)
    800020fe:	1000                	addi	s0,sp,32
    80002100:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002102:	00000097          	auipc	ra,0x0
    80002106:	ca6080e7          	jalr	-858(ra) # 80001da8 <myproc>
    8000210a:	892a                	mv	s2,a0
  sz = p->sz;
    8000210c:	692c                	ld	a1,80(a0)
    8000210e:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002112:	00904f63          	bgtz	s1,80002130 <growproc+0x3c>
  } else if(n < 0){
    80002116:	0204cc63          	bltz	s1,8000214e <growproc+0x5a>
  p->sz = sz;
    8000211a:	1602                	slli	a2,a2,0x20
    8000211c:	9201                	srli	a2,a2,0x20
    8000211e:	04c93823          	sd	a2,80(s2)
  return 0;
    80002122:	4501                	li	a0,0
}
    80002124:	60e2                	ld	ra,24(sp)
    80002126:	6442                	ld	s0,16(sp)
    80002128:	64a2                	ld	s1,8(sp)
    8000212a:	6902                	ld	s2,0(sp)
    8000212c:	6105                	addi	sp,sp,32
    8000212e:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002130:	9e25                	addw	a2,a2,s1
    80002132:	1602                	slli	a2,a2,0x20
    80002134:	9201                	srli	a2,a2,0x20
    80002136:	1582                	slli	a1,a1,0x20
    80002138:	9181                	srli	a1,a1,0x20
    8000213a:	6d28                	ld	a0,88(a0)
    8000213c:	fffff097          	auipc	ra,0xfffff
    80002140:	710080e7          	jalr	1808(ra) # 8000184c <uvmalloc>
    80002144:	0005061b          	sext.w	a2,a0
    80002148:	fa69                	bnez	a2,8000211a <growproc+0x26>
      return -1;
    8000214a:	557d                	li	a0,-1
    8000214c:	bfe1                	j	80002124 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000214e:	9e25                	addw	a2,a2,s1
    80002150:	1602                	slli	a2,a2,0x20
    80002152:	9201                	srli	a2,a2,0x20
    80002154:	1582                	slli	a1,a1,0x20
    80002156:	9181                	srli	a1,a1,0x20
    80002158:	6d28                	ld	a0,88(a0)
    8000215a:	fffff097          	auipc	ra,0xfffff
    8000215e:	6aa080e7          	jalr	1706(ra) # 80001804 <uvmdealloc>
    80002162:	0005061b          	sext.w	a2,a0
    80002166:	bf55                	j	8000211a <growproc+0x26>

0000000080002168 <fork>:
{
    80002168:	7179                	addi	sp,sp,-48
    8000216a:	f406                	sd	ra,40(sp)
    8000216c:	f022                	sd	s0,32(sp)
    8000216e:	ec26                	sd	s1,24(sp)
    80002170:	e84a                	sd	s2,16(sp)
    80002172:	e44e                	sd	s3,8(sp)
    80002174:	e052                	sd	s4,0(sp)
    80002176:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002178:	00000097          	auipc	ra,0x0
    8000217c:	c30080e7          	jalr	-976(ra) # 80001da8 <myproc>
    80002180:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002182:	00000097          	auipc	ra,0x0
    80002186:	e30080e7          	jalr	-464(ra) # 80001fb2 <allocproc>
    8000218a:	c175                	beqz	a0,8000226e <fork+0x106>
    8000218c:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    8000218e:	05093603          	ld	a2,80(s2)
    80002192:	6d2c                	ld	a1,88(a0)
    80002194:	05893503          	ld	a0,88(s2)
    80002198:	00000097          	auipc	ra,0x0
    8000219c:	800080e7          	jalr	-2048(ra) # 80001998 <uvmcopy>
    800021a0:	04054863          	bltz	a0,800021f0 <fork+0x88>
  np->sz = p->sz;
    800021a4:	05093783          	ld	a5,80(s2)
    800021a8:	04f9b823          	sd	a5,80(s3) # 4000050 <_entry-0x7bffffb0>
  np->parent = p;
    800021ac:	0329b423          	sd	s2,40(s3)
  *(np->trapframe) = *(p->trapframe);
    800021b0:	06093683          	ld	a3,96(s2)
    800021b4:	87b6                	mv	a5,a3
    800021b6:	0609b703          	ld	a4,96(s3)
    800021ba:	12068693          	addi	a3,a3,288
    800021be:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800021c2:	6788                	ld	a0,8(a5)
    800021c4:	6b8c                	ld	a1,16(a5)
    800021c6:	6f90                	ld	a2,24(a5)
    800021c8:	01073023          	sd	a6,0(a4)
    800021cc:	e708                	sd	a0,8(a4)
    800021ce:	eb0c                	sd	a1,16(a4)
    800021d0:	ef10                	sd	a2,24(a4)
    800021d2:	02078793          	addi	a5,a5,32
    800021d6:	02070713          	addi	a4,a4,32
    800021da:	fed792e3          	bne	a5,a3,800021be <fork+0x56>
  np->trapframe->a0 = 0;
    800021de:	0609b783          	ld	a5,96(s3)
    800021e2:	0607b823          	sd	zero,112(a5)
    800021e6:	0d800493          	li	s1,216
  for(i = 0; i < NOFILE; i++)
    800021ea:	15800a13          	li	s4,344
    800021ee:	a03d                	j	8000221c <fork+0xb4>
    freeproc(np);
    800021f0:	854e                	mv	a0,s3
    800021f2:	00000097          	auipc	ra,0x0
    800021f6:	d68080e7          	jalr	-664(ra) # 80001f5a <freeproc>
    release(&np->lock);
    800021fa:	854e                	mv	a0,s3
    800021fc:	fffff097          	auipc	ra,0xfffff
    80002200:	c34080e7          	jalr	-972(ra) # 80000e30 <release>
    return -1;
    80002204:	54fd                	li	s1,-1
    80002206:	a899                	j	8000225c <fork+0xf4>
      np->ofile[i] = filedup(p->ofile[i]);
    80002208:	00002097          	auipc	ra,0x2
    8000220c:	7dc080e7          	jalr	2012(ra) # 800049e4 <filedup>
    80002210:	009987b3          	add	a5,s3,s1
    80002214:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002216:	04a1                	addi	s1,s1,8
    80002218:	01448763          	beq	s1,s4,80002226 <fork+0xbe>
    if(p->ofile[i])
    8000221c:	009907b3          	add	a5,s2,s1
    80002220:	6388                	ld	a0,0(a5)
    80002222:	f17d                	bnez	a0,80002208 <fork+0xa0>
    80002224:	bfcd                	j	80002216 <fork+0xae>
  np->cwd = idup(p->cwd);
    80002226:	15893503          	ld	a0,344(s2)
    8000222a:	00002097          	auipc	ra,0x2
    8000222e:	92a080e7          	jalr	-1750(ra) # 80003b54 <idup>
    80002232:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002236:	4641                	li	a2,16
    80002238:	16090593          	addi	a1,s2,352
    8000223c:	16098513          	addi	a0,s3,352
    80002240:	fffff097          	auipc	ra,0xfffff
    80002244:	056080e7          	jalr	86(ra) # 80001296 <safestrcpy>
  pid = np->pid;
    80002248:	0409a483          	lw	s1,64(s3)
  np->state = RUNNABLE;
    8000224c:	4789                	li	a5,2
    8000224e:	02f9a023          	sw	a5,32(s3)
  release(&np->lock);
    80002252:	854e                	mv	a0,s3
    80002254:	fffff097          	auipc	ra,0xfffff
    80002258:	bdc080e7          	jalr	-1060(ra) # 80000e30 <release>
}
    8000225c:	8526                	mv	a0,s1
    8000225e:	70a2                	ld	ra,40(sp)
    80002260:	7402                	ld	s0,32(sp)
    80002262:	64e2                	ld	s1,24(sp)
    80002264:	6942                	ld	s2,16(sp)
    80002266:	69a2                	ld	s3,8(sp)
    80002268:	6a02                	ld	s4,0(sp)
    8000226a:	6145                	addi	sp,sp,48
    8000226c:	8082                	ret
    return -1;
    8000226e:	54fd                	li	s1,-1
    80002270:	b7f5                	j	8000225c <fork+0xf4>

0000000080002272 <reparent>:
{
    80002272:	7179                	addi	sp,sp,-48
    80002274:	f406                	sd	ra,40(sp)
    80002276:	f022                	sd	s0,32(sp)
    80002278:	ec26                	sd	s1,24(sp)
    8000227a:	e84a                	sd	s2,16(sp)
    8000227c:	e44e                	sd	s3,8(sp)
    8000227e:	e052                	sd	s4,0(sp)
    80002280:	1800                	addi	s0,sp,48
    80002282:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002284:	00010497          	auipc	s1,0x10
    80002288:	52448493          	addi	s1,s1,1316 # 800127a8 <proc>
      pp->parent = initproc;
    8000228c:	00007a17          	auipc	s4,0x7
    80002290:	d8ca0a13          	addi	s4,s4,-628 # 80009018 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002294:	00016997          	auipc	s3,0x16
    80002298:	11498993          	addi	s3,s3,276 # 800183a8 <tickslock>
    8000229c:	a029                	j	800022a6 <reparent+0x34>
    8000229e:	17048493          	addi	s1,s1,368
    800022a2:	03348363          	beq	s1,s3,800022c8 <reparent+0x56>
    if(pp->parent == p){
    800022a6:	749c                	ld	a5,40(s1)
    800022a8:	ff279be3          	bne	a5,s2,8000229e <reparent+0x2c>
      acquire(&pp->lock);
    800022ac:	8526                	mv	a0,s1
    800022ae:	fffff097          	auipc	ra,0xfffff
    800022b2:	ab2080e7          	jalr	-1358(ra) # 80000d60 <acquire>
      pp->parent = initproc;
    800022b6:	000a3783          	ld	a5,0(s4)
    800022ba:	f49c                	sd	a5,40(s1)
      release(&pp->lock);
    800022bc:	8526                	mv	a0,s1
    800022be:	fffff097          	auipc	ra,0xfffff
    800022c2:	b72080e7          	jalr	-1166(ra) # 80000e30 <release>
    800022c6:	bfe1                	j	8000229e <reparent+0x2c>
}
    800022c8:	70a2                	ld	ra,40(sp)
    800022ca:	7402                	ld	s0,32(sp)
    800022cc:	64e2                	ld	s1,24(sp)
    800022ce:	6942                	ld	s2,16(sp)
    800022d0:	69a2                	ld	s3,8(sp)
    800022d2:	6a02                	ld	s4,0(sp)
    800022d4:	6145                	addi	sp,sp,48
    800022d6:	8082                	ret

00000000800022d8 <scheduler>:
{
    800022d8:	711d                	addi	sp,sp,-96
    800022da:	ec86                	sd	ra,88(sp)
    800022dc:	e8a2                	sd	s0,80(sp)
    800022de:	e4a6                	sd	s1,72(sp)
    800022e0:	e0ca                	sd	s2,64(sp)
    800022e2:	fc4e                	sd	s3,56(sp)
    800022e4:	f852                	sd	s4,48(sp)
    800022e6:	f456                	sd	s5,40(sp)
    800022e8:	f05a                	sd	s6,32(sp)
    800022ea:	ec5e                	sd	s7,24(sp)
    800022ec:	e862                	sd	s8,16(sp)
    800022ee:	e466                	sd	s9,8(sp)
    800022f0:	1080                	addi	s0,sp,96
    800022f2:	8792                	mv	a5,tp
  int id = r_tp();
    800022f4:	2781                	sext.w	a5,a5
  c->proc = 0;
    800022f6:	00779c13          	slli	s8,a5,0x7
    800022fa:	00010717          	auipc	a4,0x10
    800022fe:	08e70713          	addi	a4,a4,142 # 80012388 <pid_lock>
    80002302:	9762                	add	a4,a4,s8
    80002304:	02073023          	sd	zero,32(a4)
        swtch(&c->context, &p->context);
    80002308:	00010717          	auipc	a4,0x10
    8000230c:	0a870713          	addi	a4,a4,168 # 800123b0 <cpus+0x8>
    80002310:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002312:	4a89                	li	s5,2
        c->proc = p;
    80002314:	079e                	slli	a5,a5,0x7
    80002316:	00010b17          	auipc	s6,0x10
    8000231a:	072b0b13          	addi	s6,s6,114 # 80012388 <pid_lock>
    8000231e:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002320:	00016a17          	auipc	s4,0x16
    80002324:	088a0a13          	addi	s4,s4,136 # 800183a8 <tickslock>
    int nproc = 0;
    80002328:	4c81                	li	s9,0
    8000232a:	a8a1                	j	80002382 <scheduler+0xaa>
        p->state = RUNNING;
    8000232c:	0374a023          	sw	s7,32(s1)
        c->proc = p;
    80002330:	029b3023          	sd	s1,32(s6)
        swtch(&c->context, &p->context);
    80002334:	06848593          	addi	a1,s1,104
    80002338:	8562                	mv	a0,s8
    8000233a:	00000097          	auipc	ra,0x0
    8000233e:	63a080e7          	jalr	1594(ra) # 80002974 <swtch>
        c->proc = 0;
    80002342:	020b3023          	sd	zero,32(s6)
      release(&p->lock);
    80002346:	8526                	mv	a0,s1
    80002348:	fffff097          	auipc	ra,0xfffff
    8000234c:	ae8080e7          	jalr	-1304(ra) # 80000e30 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002350:	17048493          	addi	s1,s1,368
    80002354:	01448d63          	beq	s1,s4,8000236e <scheduler+0x96>
      acquire(&p->lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	a06080e7          	jalr	-1530(ra) # 80000d60 <acquire>
      if(p->state != UNUSED) {
    80002362:	509c                	lw	a5,32(s1)
    80002364:	d3ed                	beqz	a5,80002346 <scheduler+0x6e>
        nproc++;
    80002366:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    80002368:	fd579fe3          	bne	a5,s5,80002346 <scheduler+0x6e>
    8000236c:	b7c1                	j	8000232c <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    8000236e:	013aca63          	blt	s5,s3,80002382 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002372:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002376:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000237a:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    8000237e:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002382:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002386:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000238a:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    8000238e:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    80002390:	00010497          	auipc	s1,0x10
    80002394:	41848493          	addi	s1,s1,1048 # 800127a8 <proc>
        p->state = RUNNING;
    80002398:	4b8d                	li	s7,3
    8000239a:	bf7d                	j	80002358 <scheduler+0x80>

000000008000239c <sched>:
{
    8000239c:	7179                	addi	sp,sp,-48
    8000239e:	f406                	sd	ra,40(sp)
    800023a0:	f022                	sd	s0,32(sp)
    800023a2:	ec26                	sd	s1,24(sp)
    800023a4:	e84a                	sd	s2,16(sp)
    800023a6:	e44e                	sd	s3,8(sp)
    800023a8:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	9fe080e7          	jalr	-1538(ra) # 80001da8 <myproc>
    800023b2:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	932080e7          	jalr	-1742(ra) # 80000ce6 <holding>
    800023bc:	c93d                	beqz	a0,80002432 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023be:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800023c0:	2781                	sext.w	a5,a5
    800023c2:	079e                	slli	a5,a5,0x7
    800023c4:	00010717          	auipc	a4,0x10
    800023c8:	fc470713          	addi	a4,a4,-60 # 80012388 <pid_lock>
    800023cc:	97ba                	add	a5,a5,a4
    800023ce:	0987a703          	lw	a4,152(a5)
    800023d2:	4785                	li	a5,1
    800023d4:	06f71763          	bne	a4,a5,80002442 <sched+0xa6>
  if(p->state == RUNNING)
    800023d8:	5098                	lw	a4,32(s1)
    800023da:	478d                	li	a5,3
    800023dc:	06f70b63          	beq	a4,a5,80002452 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800023e0:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800023e4:	8b89                	andi	a5,a5,2
  if(intr_get())
    800023e6:	efb5                	bnez	a5,80002462 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800023e8:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800023ea:	00010917          	auipc	s2,0x10
    800023ee:	f9e90913          	addi	s2,s2,-98 # 80012388 <pid_lock>
    800023f2:	2781                	sext.w	a5,a5
    800023f4:	079e                	slli	a5,a5,0x7
    800023f6:	97ca                	add	a5,a5,s2
    800023f8:	09c7a983          	lw	s3,156(a5)
    800023fc:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800023fe:	2781                	sext.w	a5,a5
    80002400:	079e                	slli	a5,a5,0x7
    80002402:	00010597          	auipc	a1,0x10
    80002406:	fae58593          	addi	a1,a1,-82 # 800123b0 <cpus+0x8>
    8000240a:	95be                	add	a1,a1,a5
    8000240c:	06848513          	addi	a0,s1,104
    80002410:	00000097          	auipc	ra,0x0
    80002414:	564080e7          	jalr	1380(ra) # 80002974 <swtch>
    80002418:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000241a:	2781                	sext.w	a5,a5
    8000241c:	079e                	slli	a5,a5,0x7
    8000241e:	97ca                	add	a5,a5,s2
    80002420:	0937ae23          	sw	s3,156(a5)
}
    80002424:	70a2                	ld	ra,40(sp)
    80002426:	7402                	ld	s0,32(sp)
    80002428:	64e2                	ld	s1,24(sp)
    8000242a:	6942                	ld	s2,16(sp)
    8000242c:	69a2                	ld	s3,8(sp)
    8000242e:	6145                	addi	sp,sp,48
    80002430:	8082                	ret
    panic("sched p->lock");
    80002432:	00006517          	auipc	a0,0x6
    80002436:	e5e50513          	addi	a0,a0,-418 # 80008290 <digits+0x250>
    8000243a:	ffffe097          	auipc	ra,0xffffe
    8000243e:	116080e7          	jalr	278(ra) # 80000550 <panic>
    panic("sched locks");
    80002442:	00006517          	auipc	a0,0x6
    80002446:	e5e50513          	addi	a0,a0,-418 # 800082a0 <digits+0x260>
    8000244a:	ffffe097          	auipc	ra,0xffffe
    8000244e:	106080e7          	jalr	262(ra) # 80000550 <panic>
    panic("sched running");
    80002452:	00006517          	auipc	a0,0x6
    80002456:	e5e50513          	addi	a0,a0,-418 # 800082b0 <digits+0x270>
    8000245a:	ffffe097          	auipc	ra,0xffffe
    8000245e:	0f6080e7          	jalr	246(ra) # 80000550 <panic>
    panic("sched interruptible");
    80002462:	00006517          	auipc	a0,0x6
    80002466:	e5e50513          	addi	a0,a0,-418 # 800082c0 <digits+0x280>
    8000246a:	ffffe097          	auipc	ra,0xffffe
    8000246e:	0e6080e7          	jalr	230(ra) # 80000550 <panic>

0000000080002472 <exit>:
{
    80002472:	7179                	addi	sp,sp,-48
    80002474:	f406                	sd	ra,40(sp)
    80002476:	f022                	sd	s0,32(sp)
    80002478:	ec26                	sd	s1,24(sp)
    8000247a:	e84a                	sd	s2,16(sp)
    8000247c:	e44e                	sd	s3,8(sp)
    8000247e:	e052                	sd	s4,0(sp)
    80002480:	1800                	addi	s0,sp,48
    80002482:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002484:	00000097          	auipc	ra,0x0
    80002488:	924080e7          	jalr	-1756(ra) # 80001da8 <myproc>
    8000248c:	89aa                	mv	s3,a0
  if(p == initproc)
    8000248e:	00007797          	auipc	a5,0x7
    80002492:	b8a7b783          	ld	a5,-1142(a5) # 80009018 <initproc>
    80002496:	0d850493          	addi	s1,a0,216
    8000249a:	15850913          	addi	s2,a0,344
    8000249e:	02a79363          	bne	a5,a0,800024c4 <exit+0x52>
    panic("init exiting");
    800024a2:	00006517          	auipc	a0,0x6
    800024a6:	e3650513          	addi	a0,a0,-458 # 800082d8 <digits+0x298>
    800024aa:	ffffe097          	auipc	ra,0xffffe
    800024ae:	0a6080e7          	jalr	166(ra) # 80000550 <panic>
      fileclose(f);
    800024b2:	00002097          	auipc	ra,0x2
    800024b6:	584080e7          	jalr	1412(ra) # 80004a36 <fileclose>
      p->ofile[fd] = 0;
    800024ba:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    800024be:	04a1                	addi	s1,s1,8
    800024c0:	01248563          	beq	s1,s2,800024ca <exit+0x58>
    if(p->ofile[fd]){
    800024c4:	6088                	ld	a0,0(s1)
    800024c6:	f575                	bnez	a0,800024b2 <exit+0x40>
    800024c8:	bfdd                	j	800024be <exit+0x4c>
  begin_op();
    800024ca:	00002097          	auipc	ra,0x2
    800024ce:	098080e7          	jalr	152(ra) # 80004562 <begin_op>
  iput(p->cwd);
    800024d2:	1589b503          	ld	a0,344(s3)
    800024d6:	00002097          	auipc	ra,0x2
    800024da:	876080e7          	jalr	-1930(ra) # 80003d4c <iput>
  end_op();
    800024de:	00002097          	auipc	ra,0x2
    800024e2:	104080e7          	jalr	260(ra) # 800045e2 <end_op>
  p->cwd = 0;
    800024e6:	1409bc23          	sd	zero,344(s3)
  acquire(&initproc->lock);
    800024ea:	00007497          	auipc	s1,0x7
    800024ee:	b2e48493          	addi	s1,s1,-1234 # 80009018 <initproc>
    800024f2:	6088                	ld	a0,0(s1)
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	86c080e7          	jalr	-1940(ra) # 80000d60 <acquire>
  wakeup1(initproc);
    800024fc:	6088                	ld	a0,0(s1)
    800024fe:	fffff097          	auipc	ra,0xfffff
    80002502:	76a080e7          	jalr	1898(ra) # 80001c68 <wakeup1>
  release(&initproc->lock);
    80002506:	6088                	ld	a0,0(s1)
    80002508:	fffff097          	auipc	ra,0xfffff
    8000250c:	928080e7          	jalr	-1752(ra) # 80000e30 <release>
  acquire(&p->lock);
    80002510:	854e                	mv	a0,s3
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	84e080e7          	jalr	-1970(ra) # 80000d60 <acquire>
  struct proc *original_parent = p->parent;
    8000251a:	0289b483          	ld	s1,40(s3)
  release(&p->lock);
    8000251e:	854e                	mv	a0,s3
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	910080e7          	jalr	-1776(ra) # 80000e30 <release>
  acquire(&original_parent->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	836080e7          	jalr	-1994(ra) # 80000d60 <acquire>
  acquire(&p->lock);
    80002532:	854e                	mv	a0,s3
    80002534:	fffff097          	auipc	ra,0xfffff
    80002538:	82c080e7          	jalr	-2004(ra) # 80000d60 <acquire>
  reparent(p);
    8000253c:	854e                	mv	a0,s3
    8000253e:	00000097          	auipc	ra,0x0
    80002542:	d34080e7          	jalr	-716(ra) # 80002272 <reparent>
  wakeup1(original_parent);
    80002546:	8526                	mv	a0,s1
    80002548:	fffff097          	auipc	ra,0xfffff
    8000254c:	720080e7          	jalr	1824(ra) # 80001c68 <wakeup1>
  p->xstate = status;
    80002550:	0349ae23          	sw	s4,60(s3)
  p->state = ZOMBIE;
    80002554:	4791                	li	a5,4
    80002556:	02f9a023          	sw	a5,32(s3)
  release(&original_parent->lock);
    8000255a:	8526                	mv	a0,s1
    8000255c:	fffff097          	auipc	ra,0xfffff
    80002560:	8d4080e7          	jalr	-1836(ra) # 80000e30 <release>
  sched();
    80002564:	00000097          	auipc	ra,0x0
    80002568:	e38080e7          	jalr	-456(ra) # 8000239c <sched>
  panic("zombie exit");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	d7c50513          	addi	a0,a0,-644 # 800082e8 <digits+0x2a8>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	fdc080e7          	jalr	-36(ra) # 80000550 <panic>

000000008000257c <yield>:
{
    8000257c:	1101                	addi	sp,sp,-32
    8000257e:	ec06                	sd	ra,24(sp)
    80002580:	e822                	sd	s0,16(sp)
    80002582:	e426                	sd	s1,8(sp)
    80002584:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002586:	00000097          	auipc	ra,0x0
    8000258a:	822080e7          	jalr	-2014(ra) # 80001da8 <myproc>
    8000258e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002590:	ffffe097          	auipc	ra,0xffffe
    80002594:	7d0080e7          	jalr	2000(ra) # 80000d60 <acquire>
  p->state = RUNNABLE;
    80002598:	4789                	li	a5,2
    8000259a:	d09c                	sw	a5,32(s1)
  sched();
    8000259c:	00000097          	auipc	ra,0x0
    800025a0:	e00080e7          	jalr	-512(ra) # 8000239c <sched>
  release(&p->lock);
    800025a4:	8526                	mv	a0,s1
    800025a6:	fffff097          	auipc	ra,0xfffff
    800025aa:	88a080e7          	jalr	-1910(ra) # 80000e30 <release>
}
    800025ae:	60e2                	ld	ra,24(sp)
    800025b0:	6442                	ld	s0,16(sp)
    800025b2:	64a2                	ld	s1,8(sp)
    800025b4:	6105                	addi	sp,sp,32
    800025b6:	8082                	ret

00000000800025b8 <sleep>:
{
    800025b8:	7179                	addi	sp,sp,-48
    800025ba:	f406                	sd	ra,40(sp)
    800025bc:	f022                	sd	s0,32(sp)
    800025be:	ec26                	sd	s1,24(sp)
    800025c0:	e84a                	sd	s2,16(sp)
    800025c2:	e44e                	sd	s3,8(sp)
    800025c4:	1800                	addi	s0,sp,48
    800025c6:	89aa                	mv	s3,a0
    800025c8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800025ca:	fffff097          	auipc	ra,0xfffff
    800025ce:	7de080e7          	jalr	2014(ra) # 80001da8 <myproc>
    800025d2:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    800025d4:	05250663          	beq	a0,s2,80002620 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    800025d8:	ffffe097          	auipc	ra,0xffffe
    800025dc:	788080e7          	jalr	1928(ra) # 80000d60 <acquire>
    release(lk);
    800025e0:	854a                	mv	a0,s2
    800025e2:	fffff097          	auipc	ra,0xfffff
    800025e6:	84e080e7          	jalr	-1970(ra) # 80000e30 <release>
  p->chan = chan;
    800025ea:	0334b823          	sd	s3,48(s1)
  p->state = SLEEPING;
    800025ee:	4785                	li	a5,1
    800025f0:	d09c                	sw	a5,32(s1)
  sched();
    800025f2:	00000097          	auipc	ra,0x0
    800025f6:	daa080e7          	jalr	-598(ra) # 8000239c <sched>
  p->chan = 0;
    800025fa:	0204b823          	sd	zero,48(s1)
    release(&p->lock);
    800025fe:	8526                	mv	a0,s1
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	830080e7          	jalr	-2000(ra) # 80000e30 <release>
    acquire(lk);
    80002608:	854a                	mv	a0,s2
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	756080e7          	jalr	1878(ra) # 80000d60 <acquire>
}
    80002612:	70a2                	ld	ra,40(sp)
    80002614:	7402                	ld	s0,32(sp)
    80002616:	64e2                	ld	s1,24(sp)
    80002618:	6942                	ld	s2,16(sp)
    8000261a:	69a2                	ld	s3,8(sp)
    8000261c:	6145                	addi	sp,sp,48
    8000261e:	8082                	ret
  p->chan = chan;
    80002620:	03353823          	sd	s3,48(a0)
  p->state = SLEEPING;
    80002624:	4785                	li	a5,1
    80002626:	d11c                	sw	a5,32(a0)
  sched();
    80002628:	00000097          	auipc	ra,0x0
    8000262c:	d74080e7          	jalr	-652(ra) # 8000239c <sched>
  p->chan = 0;
    80002630:	0204b823          	sd	zero,48(s1)
  if(lk != &p->lock){
    80002634:	bff9                	j	80002612 <sleep+0x5a>

0000000080002636 <wait>:
{
    80002636:	715d                	addi	sp,sp,-80
    80002638:	e486                	sd	ra,72(sp)
    8000263a:	e0a2                	sd	s0,64(sp)
    8000263c:	fc26                	sd	s1,56(sp)
    8000263e:	f84a                	sd	s2,48(sp)
    80002640:	f44e                	sd	s3,40(sp)
    80002642:	f052                	sd	s4,32(sp)
    80002644:	ec56                	sd	s5,24(sp)
    80002646:	e85a                	sd	s6,16(sp)
    80002648:	e45e                	sd	s7,8(sp)
    8000264a:	e062                	sd	s8,0(sp)
    8000264c:	0880                	addi	s0,sp,80
    8000264e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	758080e7          	jalr	1880(ra) # 80001da8 <myproc>
    80002658:	892a                	mv	s2,a0
  acquire(&p->lock);
    8000265a:	8c2a                	mv	s8,a0
    8000265c:	ffffe097          	auipc	ra,0xffffe
    80002660:	704080e7          	jalr	1796(ra) # 80000d60 <acquire>
    havekids = 0;
    80002664:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002666:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002668:	00016997          	auipc	s3,0x16
    8000266c:	d4098993          	addi	s3,s3,-704 # 800183a8 <tickslock>
        havekids = 1;
    80002670:	4a85                	li	s5,1
    havekids = 0;
    80002672:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002674:	00010497          	auipc	s1,0x10
    80002678:	13448493          	addi	s1,s1,308 # 800127a8 <proc>
    8000267c:	a08d                	j	800026de <wait+0xa8>
          pid = np->pid;
    8000267e:	0404a983          	lw	s3,64(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002682:	000b0e63          	beqz	s6,8000269e <wait+0x68>
    80002686:	4691                	li	a3,4
    80002688:	03c48613          	addi	a2,s1,60
    8000268c:	85da                	mv	a1,s6
    8000268e:	05893503          	ld	a0,88(s2)
    80002692:	fffff097          	auipc	ra,0xfffff
    80002696:	40a080e7          	jalr	1034(ra) # 80001a9c <copyout>
    8000269a:	02054263          	bltz	a0,800026be <wait+0x88>
          freeproc(np);
    8000269e:	8526                	mv	a0,s1
    800026a0:	00000097          	auipc	ra,0x0
    800026a4:	8ba080e7          	jalr	-1862(ra) # 80001f5a <freeproc>
          release(&np->lock);
    800026a8:	8526                	mv	a0,s1
    800026aa:	ffffe097          	auipc	ra,0xffffe
    800026ae:	786080e7          	jalr	1926(ra) # 80000e30 <release>
          release(&p->lock);
    800026b2:	854a                	mv	a0,s2
    800026b4:	ffffe097          	auipc	ra,0xffffe
    800026b8:	77c080e7          	jalr	1916(ra) # 80000e30 <release>
          return pid;
    800026bc:	a8a9                	j	80002716 <wait+0xe0>
            release(&np->lock);
    800026be:	8526                	mv	a0,s1
    800026c0:	ffffe097          	auipc	ra,0xffffe
    800026c4:	770080e7          	jalr	1904(ra) # 80000e30 <release>
            release(&p->lock);
    800026c8:	854a                	mv	a0,s2
    800026ca:	ffffe097          	auipc	ra,0xffffe
    800026ce:	766080e7          	jalr	1894(ra) # 80000e30 <release>
            return -1;
    800026d2:	59fd                	li	s3,-1
    800026d4:	a089                	j	80002716 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    800026d6:	17048493          	addi	s1,s1,368
    800026da:	03348463          	beq	s1,s3,80002702 <wait+0xcc>
      if(np->parent == p){
    800026de:	749c                	ld	a5,40(s1)
    800026e0:	ff279be3          	bne	a5,s2,800026d6 <wait+0xa0>
        acquire(&np->lock);
    800026e4:	8526                	mv	a0,s1
    800026e6:	ffffe097          	auipc	ra,0xffffe
    800026ea:	67a080e7          	jalr	1658(ra) # 80000d60 <acquire>
        if(np->state == ZOMBIE){
    800026ee:	509c                	lw	a5,32(s1)
    800026f0:	f94787e3          	beq	a5,s4,8000267e <wait+0x48>
        release(&np->lock);
    800026f4:	8526                	mv	a0,s1
    800026f6:	ffffe097          	auipc	ra,0xffffe
    800026fa:	73a080e7          	jalr	1850(ra) # 80000e30 <release>
        havekids = 1;
    800026fe:	8756                	mv	a4,s5
    80002700:	bfd9                	j	800026d6 <wait+0xa0>
    if(!havekids || p->killed){
    80002702:	c701                	beqz	a4,8000270a <wait+0xd4>
    80002704:	03892783          	lw	a5,56(s2)
    80002708:	c785                	beqz	a5,80002730 <wait+0xfa>
      release(&p->lock);
    8000270a:	854a                	mv	a0,s2
    8000270c:	ffffe097          	auipc	ra,0xffffe
    80002710:	724080e7          	jalr	1828(ra) # 80000e30 <release>
      return -1;
    80002714:	59fd                	li	s3,-1
}
    80002716:	854e                	mv	a0,s3
    80002718:	60a6                	ld	ra,72(sp)
    8000271a:	6406                	ld	s0,64(sp)
    8000271c:	74e2                	ld	s1,56(sp)
    8000271e:	7942                	ld	s2,48(sp)
    80002720:	79a2                	ld	s3,40(sp)
    80002722:	7a02                	ld	s4,32(sp)
    80002724:	6ae2                	ld	s5,24(sp)
    80002726:	6b42                	ld	s6,16(sp)
    80002728:	6ba2                	ld	s7,8(sp)
    8000272a:	6c02                	ld	s8,0(sp)
    8000272c:	6161                	addi	sp,sp,80
    8000272e:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002730:	85e2                	mv	a1,s8
    80002732:	854a                	mv	a0,s2
    80002734:	00000097          	auipc	ra,0x0
    80002738:	e84080e7          	jalr	-380(ra) # 800025b8 <sleep>
    havekids = 0;
    8000273c:	bf1d                	j	80002672 <wait+0x3c>

000000008000273e <wakeup>:
{
    8000273e:	7139                	addi	sp,sp,-64
    80002740:	fc06                	sd	ra,56(sp)
    80002742:	f822                	sd	s0,48(sp)
    80002744:	f426                	sd	s1,40(sp)
    80002746:	f04a                	sd	s2,32(sp)
    80002748:	ec4e                	sd	s3,24(sp)
    8000274a:	e852                	sd	s4,16(sp)
    8000274c:	e456                	sd	s5,8(sp)
    8000274e:	0080                	addi	s0,sp,64
    80002750:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002752:	00010497          	auipc	s1,0x10
    80002756:	05648493          	addi	s1,s1,86 # 800127a8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    8000275a:	4985                	li	s3,1
      p->state = RUNNABLE;
    8000275c:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    8000275e:	00016917          	auipc	s2,0x16
    80002762:	c4a90913          	addi	s2,s2,-950 # 800183a8 <tickslock>
    80002766:	a821                	j	8000277e <wakeup+0x40>
      p->state = RUNNABLE;
    80002768:	0354a023          	sw	s5,32(s1)
    release(&p->lock);
    8000276c:	8526                	mv	a0,s1
    8000276e:	ffffe097          	auipc	ra,0xffffe
    80002772:	6c2080e7          	jalr	1730(ra) # 80000e30 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002776:	17048493          	addi	s1,s1,368
    8000277a:	01248e63          	beq	s1,s2,80002796 <wakeup+0x58>
    acquire(&p->lock);
    8000277e:	8526                	mv	a0,s1
    80002780:	ffffe097          	auipc	ra,0xffffe
    80002784:	5e0080e7          	jalr	1504(ra) # 80000d60 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002788:	509c                	lw	a5,32(s1)
    8000278a:	ff3791e3          	bne	a5,s3,8000276c <wakeup+0x2e>
    8000278e:	789c                	ld	a5,48(s1)
    80002790:	fd479ee3          	bne	a5,s4,8000276c <wakeup+0x2e>
    80002794:	bfd1                	j	80002768 <wakeup+0x2a>
}
    80002796:	70e2                	ld	ra,56(sp)
    80002798:	7442                	ld	s0,48(sp)
    8000279a:	74a2                	ld	s1,40(sp)
    8000279c:	7902                	ld	s2,32(sp)
    8000279e:	69e2                	ld	s3,24(sp)
    800027a0:	6a42                	ld	s4,16(sp)
    800027a2:	6aa2                	ld	s5,8(sp)
    800027a4:	6121                	addi	sp,sp,64
    800027a6:	8082                	ret

00000000800027a8 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800027a8:	7179                	addi	sp,sp,-48
    800027aa:	f406                	sd	ra,40(sp)
    800027ac:	f022                	sd	s0,32(sp)
    800027ae:	ec26                	sd	s1,24(sp)
    800027b0:	e84a                	sd	s2,16(sp)
    800027b2:	e44e                	sd	s3,8(sp)
    800027b4:	1800                	addi	s0,sp,48
    800027b6:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800027b8:	00010497          	auipc	s1,0x10
    800027bc:	ff048493          	addi	s1,s1,-16 # 800127a8 <proc>
    800027c0:	00016997          	auipc	s3,0x16
    800027c4:	be898993          	addi	s3,s3,-1048 # 800183a8 <tickslock>
    acquire(&p->lock);
    800027c8:	8526                	mv	a0,s1
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	596080e7          	jalr	1430(ra) # 80000d60 <acquire>
    if(p->pid == pid){
    800027d2:	40bc                	lw	a5,64(s1)
    800027d4:	01278d63          	beq	a5,s2,800027ee <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800027d8:	8526                	mv	a0,s1
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	656080e7          	jalr	1622(ra) # 80000e30 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027e2:	17048493          	addi	s1,s1,368
    800027e6:	ff3491e3          	bne	s1,s3,800027c8 <kill+0x20>
  }
  return -1;
    800027ea:	557d                	li	a0,-1
    800027ec:	a829                	j	80002806 <kill+0x5e>
      p->killed = 1;
    800027ee:	4785                	li	a5,1
    800027f0:	dc9c                	sw	a5,56(s1)
      if(p->state == SLEEPING){
    800027f2:	5098                	lw	a4,32(s1)
    800027f4:	4785                	li	a5,1
    800027f6:	00f70f63          	beq	a4,a5,80002814 <kill+0x6c>
      release(&p->lock);
    800027fa:	8526                	mv	a0,s1
    800027fc:	ffffe097          	auipc	ra,0xffffe
    80002800:	634080e7          	jalr	1588(ra) # 80000e30 <release>
      return 0;
    80002804:	4501                	li	a0,0
}
    80002806:	70a2                	ld	ra,40(sp)
    80002808:	7402                	ld	s0,32(sp)
    8000280a:	64e2                	ld	s1,24(sp)
    8000280c:	6942                	ld	s2,16(sp)
    8000280e:	69a2                	ld	s3,8(sp)
    80002810:	6145                	addi	sp,sp,48
    80002812:	8082                	ret
        p->state = RUNNABLE;
    80002814:	4789                	li	a5,2
    80002816:	d09c                	sw	a5,32(s1)
    80002818:	b7cd                	j	800027fa <kill+0x52>

000000008000281a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000281a:	7179                	addi	sp,sp,-48
    8000281c:	f406                	sd	ra,40(sp)
    8000281e:	f022                	sd	s0,32(sp)
    80002820:	ec26                	sd	s1,24(sp)
    80002822:	e84a                	sd	s2,16(sp)
    80002824:	e44e                	sd	s3,8(sp)
    80002826:	e052                	sd	s4,0(sp)
    80002828:	1800                	addi	s0,sp,48
    8000282a:	84aa                	mv	s1,a0
    8000282c:	892e                	mv	s2,a1
    8000282e:	89b2                	mv	s3,a2
    80002830:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002832:	fffff097          	auipc	ra,0xfffff
    80002836:	576080e7          	jalr	1398(ra) # 80001da8 <myproc>
  if(user_dst){
    8000283a:	c08d                	beqz	s1,8000285c <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    8000283c:	86d2                	mv	a3,s4
    8000283e:	864e                	mv	a2,s3
    80002840:	85ca                	mv	a1,s2
    80002842:	6d28                	ld	a0,88(a0)
    80002844:	fffff097          	auipc	ra,0xfffff
    80002848:	258080e7          	jalr	600(ra) # 80001a9c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    8000284c:	70a2                	ld	ra,40(sp)
    8000284e:	7402                	ld	s0,32(sp)
    80002850:	64e2                	ld	s1,24(sp)
    80002852:	6942                	ld	s2,16(sp)
    80002854:	69a2                	ld	s3,8(sp)
    80002856:	6a02                	ld	s4,0(sp)
    80002858:	6145                	addi	sp,sp,48
    8000285a:	8082                	ret
    memmove((char *)dst, src, len);
    8000285c:	000a061b          	sext.w	a2,s4
    80002860:	85ce                	mv	a1,s3
    80002862:	854a                	mv	a0,s2
    80002864:	fffff097          	auipc	ra,0xfffff
    80002868:	93c080e7          	jalr	-1732(ra) # 800011a0 <memmove>
    return 0;
    8000286c:	8526                	mv	a0,s1
    8000286e:	bff9                	j	8000284c <either_copyout+0x32>

0000000080002870 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002870:	7179                	addi	sp,sp,-48
    80002872:	f406                	sd	ra,40(sp)
    80002874:	f022                	sd	s0,32(sp)
    80002876:	ec26                	sd	s1,24(sp)
    80002878:	e84a                	sd	s2,16(sp)
    8000287a:	e44e                	sd	s3,8(sp)
    8000287c:	e052                	sd	s4,0(sp)
    8000287e:	1800                	addi	s0,sp,48
    80002880:	892a                	mv	s2,a0
    80002882:	84ae                	mv	s1,a1
    80002884:	89b2                	mv	s3,a2
    80002886:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002888:	fffff097          	auipc	ra,0xfffff
    8000288c:	520080e7          	jalr	1312(ra) # 80001da8 <myproc>
  if(user_src){
    80002890:	c08d                	beqz	s1,800028b2 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002892:	86d2                	mv	a3,s4
    80002894:	864e                	mv	a2,s3
    80002896:	85ca                	mv	a1,s2
    80002898:	6d28                	ld	a0,88(a0)
    8000289a:	fffff097          	auipc	ra,0xfffff
    8000289e:	28e080e7          	jalr	654(ra) # 80001b28 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    800028a2:	70a2                	ld	ra,40(sp)
    800028a4:	7402                	ld	s0,32(sp)
    800028a6:	64e2                	ld	s1,24(sp)
    800028a8:	6942                	ld	s2,16(sp)
    800028aa:	69a2                	ld	s3,8(sp)
    800028ac:	6a02                	ld	s4,0(sp)
    800028ae:	6145                	addi	sp,sp,48
    800028b0:	8082                	ret
    memmove(dst, (char*)src, len);
    800028b2:	000a061b          	sext.w	a2,s4
    800028b6:	85ce                	mv	a1,s3
    800028b8:	854a                	mv	a0,s2
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	8e6080e7          	jalr	-1818(ra) # 800011a0 <memmove>
    return 0;
    800028c2:	8526                	mv	a0,s1
    800028c4:	bff9                	j	800028a2 <either_copyin+0x32>

00000000800028c6 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    800028c6:	715d                	addi	sp,sp,-80
    800028c8:	e486                	sd	ra,72(sp)
    800028ca:	e0a2                	sd	s0,64(sp)
    800028cc:	fc26                	sd	s1,56(sp)
    800028ce:	f84a                	sd	s2,48(sp)
    800028d0:	f44e                	sd	s3,40(sp)
    800028d2:	f052                	sd	s4,32(sp)
    800028d4:	ec56                	sd	s5,24(sp)
    800028d6:	e85a                	sd	s6,16(sp)
    800028d8:	e45e                	sd	s7,8(sp)
    800028da:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	88450513          	addi	a0,a0,-1916 # 80008160 <digits+0x120>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	cb6080e7          	jalr	-842(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800028ec:	00010497          	auipc	s1,0x10
    800028f0:	01c48493          	addi	s1,s1,28 # 80012908 <proc+0x160>
    800028f4:	00016917          	auipc	s2,0x16
    800028f8:	c1490913          	addi	s2,s2,-1004 # 80018508 <hashtable+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800028fc:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    800028fe:	00006997          	auipc	s3,0x6
    80002902:	9fa98993          	addi	s3,s3,-1542 # 800082f8 <digits+0x2b8>
    printf("%d %s %s", p->pid, state, p->name);
    80002906:	00006a97          	auipc	s5,0x6
    8000290a:	9faa8a93          	addi	s5,s5,-1542 # 80008300 <digits+0x2c0>
    printf("\n");
    8000290e:	00006a17          	auipc	s4,0x6
    80002912:	852a0a13          	addi	s4,s4,-1966 # 80008160 <digits+0x120>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002916:	00006b97          	auipc	s7,0x6
    8000291a:	a22b8b93          	addi	s7,s7,-1502 # 80008338 <states.1712>
    8000291e:	a00d                	j	80002940 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002920:	ee06a583          	lw	a1,-288(a3)
    80002924:	8556                	mv	a0,s5
    80002926:	ffffe097          	auipc	ra,0xffffe
    8000292a:	c74080e7          	jalr	-908(ra) # 8000059a <printf>
    printf("\n");
    8000292e:	8552                	mv	a0,s4
    80002930:	ffffe097          	auipc	ra,0xffffe
    80002934:	c6a080e7          	jalr	-918(ra) # 8000059a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002938:	17048493          	addi	s1,s1,368
    8000293c:	03248163          	beq	s1,s2,8000295e <procdump+0x98>
    if(p->state == UNUSED)
    80002940:	86a6                	mv	a3,s1
    80002942:	ec04a783          	lw	a5,-320(s1)
    80002946:	dbed                	beqz	a5,80002938 <procdump+0x72>
      state = "???";
    80002948:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000294a:	fcfb6be3          	bltu	s6,a5,80002920 <procdump+0x5a>
    8000294e:	1782                	slli	a5,a5,0x20
    80002950:	9381                	srli	a5,a5,0x20
    80002952:	078e                	slli	a5,a5,0x3
    80002954:	97de                	add	a5,a5,s7
    80002956:	6390                	ld	a2,0(a5)
    80002958:	f661                	bnez	a2,80002920 <procdump+0x5a>
      state = "???";
    8000295a:	864e                	mv	a2,s3
    8000295c:	b7d1                	j	80002920 <procdump+0x5a>
  }
}
    8000295e:	60a6                	ld	ra,72(sp)
    80002960:	6406                	ld	s0,64(sp)
    80002962:	74e2                	ld	s1,56(sp)
    80002964:	7942                	ld	s2,48(sp)
    80002966:	79a2                	ld	s3,40(sp)
    80002968:	7a02                	ld	s4,32(sp)
    8000296a:	6ae2                	ld	s5,24(sp)
    8000296c:	6b42                	ld	s6,16(sp)
    8000296e:	6ba2                	ld	s7,8(sp)
    80002970:	6161                	addi	sp,sp,80
    80002972:	8082                	ret

0000000080002974 <swtch>:
    80002974:	00153023          	sd	ra,0(a0)
    80002978:	00253423          	sd	sp,8(a0)
    8000297c:	e900                	sd	s0,16(a0)
    8000297e:	ed04                	sd	s1,24(a0)
    80002980:	03253023          	sd	s2,32(a0)
    80002984:	03353423          	sd	s3,40(a0)
    80002988:	03453823          	sd	s4,48(a0)
    8000298c:	03553c23          	sd	s5,56(a0)
    80002990:	05653023          	sd	s6,64(a0)
    80002994:	05753423          	sd	s7,72(a0)
    80002998:	05853823          	sd	s8,80(a0)
    8000299c:	05953c23          	sd	s9,88(a0)
    800029a0:	07a53023          	sd	s10,96(a0)
    800029a4:	07b53423          	sd	s11,104(a0)
    800029a8:	0005b083          	ld	ra,0(a1)
    800029ac:	0085b103          	ld	sp,8(a1)
    800029b0:	6980                	ld	s0,16(a1)
    800029b2:	6d84                	ld	s1,24(a1)
    800029b4:	0205b903          	ld	s2,32(a1)
    800029b8:	0285b983          	ld	s3,40(a1)
    800029bc:	0305ba03          	ld	s4,48(a1)
    800029c0:	0385ba83          	ld	s5,56(a1)
    800029c4:	0405bb03          	ld	s6,64(a1)
    800029c8:	0485bb83          	ld	s7,72(a1)
    800029cc:	0505bc03          	ld	s8,80(a1)
    800029d0:	0585bc83          	ld	s9,88(a1)
    800029d4:	0605bd03          	ld	s10,96(a1)
    800029d8:	0685bd83          	ld	s11,104(a1)
    800029dc:	8082                	ret

00000000800029de <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800029de:	1141                	addi	sp,sp,-16
    800029e0:	e406                	sd	ra,8(sp)
    800029e2:	e022                	sd	s0,0(sp)
    800029e4:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800029e6:	00006597          	auipc	a1,0x6
    800029ea:	97a58593          	addi	a1,a1,-1670 # 80008360 <states.1712+0x28>
    800029ee:	00016517          	auipc	a0,0x16
    800029f2:	9ba50513          	addi	a0,a0,-1606 # 800183a8 <tickslock>
    800029f6:	ffffe097          	auipc	ra,0xffffe
    800029fa:	4e6080e7          	jalr	1254(ra) # 80000edc <initlock>
}
    800029fe:	60a2                	ld	ra,8(sp)
    80002a00:	6402                	ld	s0,0(sp)
    80002a02:	0141                	addi	sp,sp,16
    80002a04:	8082                	ret

0000000080002a06 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002a06:	1141                	addi	sp,sp,-16
    80002a08:	e422                	sd	s0,8(sp)
    80002a0a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a0c:	00003797          	auipc	a5,0x3
    80002a10:	6a478793          	addi	a5,a5,1700 # 800060b0 <kernelvec>
    80002a14:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002a18:	6422                	ld	s0,8(sp)
    80002a1a:	0141                	addi	sp,sp,16
    80002a1c:	8082                	ret

0000000080002a1e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002a1e:	1141                	addi	sp,sp,-16
    80002a20:	e406                	sd	ra,8(sp)
    80002a22:	e022                	sd	s0,0(sp)
    80002a24:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002a26:	fffff097          	auipc	ra,0xfffff
    80002a2a:	382080e7          	jalr	898(ra) # 80001da8 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a2e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002a32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a34:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002a38:	00004617          	auipc	a2,0x4
    80002a3c:	5c860613          	addi	a2,a2,1480 # 80007000 <_trampoline>
    80002a40:	00004697          	auipc	a3,0x4
    80002a44:	5c068693          	addi	a3,a3,1472 # 80007000 <_trampoline>
    80002a48:	8e91                	sub	a3,a3,a2
    80002a4a:	040007b7          	lui	a5,0x4000
    80002a4e:	17fd                	addi	a5,a5,-1
    80002a50:	07b2                	slli	a5,a5,0xc
    80002a52:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a54:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002a58:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002a5a:	180026f3          	csrr	a3,satp
    80002a5e:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002a60:	7138                	ld	a4,96(a0)
    80002a62:	6534                	ld	a3,72(a0)
    80002a64:	6585                	lui	a1,0x1
    80002a66:	96ae                	add	a3,a3,a1
    80002a68:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a6a:	7138                	ld	a4,96(a0)
    80002a6c:	00000697          	auipc	a3,0x0
    80002a70:	13868693          	addi	a3,a3,312 # 80002ba4 <usertrap>
    80002a74:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002a76:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a78:	8692                	mv	a3,tp
    80002a7a:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a7c:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a80:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a84:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a88:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a8c:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a8e:	6f18                	ld	a4,24(a4)
    80002a90:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a94:	6d2c                	ld	a1,88(a0)
    80002a96:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002a98:	00004717          	auipc	a4,0x4
    80002a9c:	5f870713          	addi	a4,a4,1528 # 80007090 <userret>
    80002aa0:	8f11                	sub	a4,a4,a2
    80002aa2:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002aa4:	577d                	li	a4,-1
    80002aa6:	177e                	slli	a4,a4,0x3f
    80002aa8:	8dd9                	or	a1,a1,a4
    80002aaa:	02000537          	lui	a0,0x2000
    80002aae:	157d                	addi	a0,a0,-1
    80002ab0:	0536                	slli	a0,a0,0xd
    80002ab2:	9782                	jalr	a5
}
    80002ab4:	60a2                	ld	ra,8(sp)
    80002ab6:	6402                	ld	s0,0(sp)
    80002ab8:	0141                	addi	sp,sp,16
    80002aba:	8082                	ret

0000000080002abc <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002abc:	1101                	addi	sp,sp,-32
    80002abe:	ec06                	sd	ra,24(sp)
    80002ac0:	e822                	sd	s0,16(sp)
    80002ac2:	e426                	sd	s1,8(sp)
    80002ac4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002ac6:	00016497          	auipc	s1,0x16
    80002aca:	8e248493          	addi	s1,s1,-1822 # 800183a8 <tickslock>
    80002ace:	8526                	mv	a0,s1
    80002ad0:	ffffe097          	auipc	ra,0xffffe
    80002ad4:	290080e7          	jalr	656(ra) # 80000d60 <acquire>
  ticks++;
    80002ad8:	00006517          	auipc	a0,0x6
    80002adc:	54850513          	addi	a0,a0,1352 # 80009020 <ticks>
    80002ae0:	411c                	lw	a5,0(a0)
    80002ae2:	2785                	addiw	a5,a5,1
    80002ae4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002ae6:	00000097          	auipc	ra,0x0
    80002aea:	c58080e7          	jalr	-936(ra) # 8000273e <wakeup>
  release(&tickslock);
    80002aee:	8526                	mv	a0,s1
    80002af0:	ffffe097          	auipc	ra,0xffffe
    80002af4:	340080e7          	jalr	832(ra) # 80000e30 <release>
}
    80002af8:	60e2                	ld	ra,24(sp)
    80002afa:	6442                	ld	s0,16(sp)
    80002afc:	64a2                	ld	s1,8(sp)
    80002afe:	6105                	addi	sp,sp,32
    80002b00:	8082                	ret

0000000080002b02 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80002b02:	1101                	addi	sp,sp,-32
    80002b04:	ec06                	sd	ra,24(sp)
    80002b06:	e822                	sd	s0,16(sp)
    80002b08:	e426                	sd	s1,8(sp)
    80002b0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b0c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80002b10:	00074d63          	bltz	a4,80002b2a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002b14:	57fd                	li	a5,-1
    80002b16:	17fe                	slli	a5,a5,0x3f
    80002b18:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002b1a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002b1c:	06f70363          	beq	a4,a5,80002b82 <devintr+0x80>
  }
}
    80002b20:	60e2                	ld	ra,24(sp)
    80002b22:	6442                	ld	s0,16(sp)
    80002b24:	64a2                	ld	s1,8(sp)
    80002b26:	6105                	addi	sp,sp,32
    80002b28:	8082                	ret
     (scause & 0xff) == 9){
    80002b2a:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    80002b2e:	46a5                	li	a3,9
    80002b30:	fed792e3          	bne	a5,a3,80002b14 <devintr+0x12>
    int irq = plic_claim();
    80002b34:	00003097          	auipc	ra,0x3
    80002b38:	684080e7          	jalr	1668(ra) # 800061b8 <plic_claim>
    80002b3c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    80002b3e:	47a9                	li	a5,10
    80002b40:	02f50763          	beq	a0,a5,80002b6e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002b44:	4785                	li	a5,1
    80002b46:	02f50963          	beq	a0,a5,80002b78 <devintr+0x76>
    return 1;
    80002b4a:	4505                	li	a0,1
    } else if(irq){
    80002b4c:	d8f1                	beqz	s1,80002b20 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002b4e:	85a6                	mv	a1,s1
    80002b50:	00006517          	auipc	a0,0x6
    80002b54:	81850513          	addi	a0,a0,-2024 # 80008368 <states.1712+0x30>
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	a42080e7          	jalr	-1470(ra) # 8000059a <printf>
      plic_complete(irq);
    80002b60:	8526                	mv	a0,s1
    80002b62:	00003097          	auipc	ra,0x3
    80002b66:	67a080e7          	jalr	1658(ra) # 800061dc <plic_complete>
    return 1;
    80002b6a:	4505                	li	a0,1
    80002b6c:	bf55                	j	80002b20 <devintr+0x1e>
      uartintr();
    80002b6e:	ffffe097          	auipc	ra,0xffffe
    80002b72:	e6e080e7          	jalr	-402(ra) # 800009dc <uartintr>
    80002b76:	b7ed                	j	80002b60 <devintr+0x5e>
      virtio_disk_intr();
    80002b78:	00004097          	auipc	ra,0x4
    80002b7c:	b44080e7          	jalr	-1212(ra) # 800066bc <virtio_disk_intr>
    80002b80:	b7c5                	j	80002b60 <devintr+0x5e>
    if(cpuid() == 0){
    80002b82:	fffff097          	auipc	ra,0xfffff
    80002b86:	1fa080e7          	jalr	506(ra) # 80001d7c <cpuid>
    80002b8a:	c901                	beqz	a0,80002b9a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b8c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b90:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b92:	14479073          	csrw	sip,a5
    return 2;
    80002b96:	4509                	li	a0,2
    80002b98:	b761                	j	80002b20 <devintr+0x1e>
      clockintr();
    80002b9a:	00000097          	auipc	ra,0x0
    80002b9e:	f22080e7          	jalr	-222(ra) # 80002abc <clockintr>
    80002ba2:	b7ed                	j	80002b8c <devintr+0x8a>

0000000080002ba4 <usertrap>:
{
    80002ba4:	1101                	addi	sp,sp,-32
    80002ba6:	ec06                	sd	ra,24(sp)
    80002ba8:	e822                	sd	s0,16(sp)
    80002baa:	e426                	sd	s1,8(sp)
    80002bac:	e04a                	sd	s2,0(sp)
    80002bae:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bb0:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002bb4:	1007f793          	andi	a5,a5,256
    80002bb8:	e3ad                	bnez	a5,80002c1a <usertrap+0x76>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002bba:	00003797          	auipc	a5,0x3
    80002bbe:	4f678793          	addi	a5,a5,1270 # 800060b0 <kernelvec>
    80002bc2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002bc6:	fffff097          	auipc	ra,0xfffff
    80002bca:	1e2080e7          	jalr	482(ra) # 80001da8 <myproc>
    80002bce:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002bd0:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bd2:	14102773          	csrr	a4,sepc
    80002bd6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002bd8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002bdc:	47a1                	li	a5,8
    80002bde:	04f71c63          	bne	a4,a5,80002c36 <usertrap+0x92>
    if(p->killed)
    80002be2:	5d1c                	lw	a5,56(a0)
    80002be4:	e3b9                	bnez	a5,80002c2a <usertrap+0x86>
    p->trapframe->epc += 4;
    80002be6:	70b8                	ld	a4,96(s1)
    80002be8:	6f1c                	ld	a5,24(a4)
    80002bea:	0791                	addi	a5,a5,4
    80002bec:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bee:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bf2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bf6:	10079073          	csrw	sstatus,a5
    syscall();
    80002bfa:	00000097          	auipc	ra,0x0
    80002bfe:	2e0080e7          	jalr	736(ra) # 80002eda <syscall>
  if(p->killed)
    80002c02:	5c9c                	lw	a5,56(s1)
    80002c04:	ebc1                	bnez	a5,80002c94 <usertrap+0xf0>
  usertrapret();
    80002c06:	00000097          	auipc	ra,0x0
    80002c0a:	e18080e7          	jalr	-488(ra) # 80002a1e <usertrapret>
}
    80002c0e:	60e2                	ld	ra,24(sp)
    80002c10:	6442                	ld	s0,16(sp)
    80002c12:	64a2                	ld	s1,8(sp)
    80002c14:	6902                	ld	s2,0(sp)
    80002c16:	6105                	addi	sp,sp,32
    80002c18:	8082                	ret
    panic("usertrap: not from user mode");
    80002c1a:	00005517          	auipc	a0,0x5
    80002c1e:	76e50513          	addi	a0,a0,1902 # 80008388 <states.1712+0x50>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	92e080e7          	jalr	-1746(ra) # 80000550 <panic>
      exit(-1);
    80002c2a:	557d                	li	a0,-1
    80002c2c:	00000097          	auipc	ra,0x0
    80002c30:	846080e7          	jalr	-1978(ra) # 80002472 <exit>
    80002c34:	bf4d                	j	80002be6 <usertrap+0x42>
  } else if((which_dev = devintr()) != 0){
    80002c36:	00000097          	auipc	ra,0x0
    80002c3a:	ecc080e7          	jalr	-308(ra) # 80002b02 <devintr>
    80002c3e:	892a                	mv	s2,a0
    80002c40:	c501                	beqz	a0,80002c48 <usertrap+0xa4>
  if(p->killed)
    80002c42:	5c9c                	lw	a5,56(s1)
    80002c44:	c3a1                	beqz	a5,80002c84 <usertrap+0xe0>
    80002c46:	a815                	j	80002c7a <usertrap+0xd6>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c48:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c4c:	40b0                	lw	a2,64(s1)
    80002c4e:	00005517          	auipc	a0,0x5
    80002c52:	75a50513          	addi	a0,a0,1882 # 800083a8 <states.1712+0x70>
    80002c56:	ffffe097          	auipc	ra,0xffffe
    80002c5a:	944080e7          	jalr	-1724(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c5e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c62:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c66:	00005517          	auipc	a0,0x5
    80002c6a:	77250513          	addi	a0,a0,1906 # 800083d8 <states.1712+0xa0>
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	92c080e7          	jalr	-1748(ra) # 8000059a <printf>
    p->killed = 1;
    80002c76:	4785                	li	a5,1
    80002c78:	dc9c                	sw	a5,56(s1)
    exit(-1);
    80002c7a:	557d                	li	a0,-1
    80002c7c:	fffff097          	auipc	ra,0xfffff
    80002c80:	7f6080e7          	jalr	2038(ra) # 80002472 <exit>
  if(which_dev == 2)
    80002c84:	4789                	li	a5,2
    80002c86:	f8f910e3          	bne	s2,a5,80002c06 <usertrap+0x62>
    yield();
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	8f2080e7          	jalr	-1806(ra) # 8000257c <yield>
    80002c92:	bf95                	j	80002c06 <usertrap+0x62>
  int which_dev = 0;
    80002c94:	4901                	li	s2,0
    80002c96:	b7d5                	j	80002c7a <usertrap+0xd6>

0000000080002c98 <kerneltrap>:
{
    80002c98:	7179                	addi	sp,sp,-48
    80002c9a:	f406                	sd	ra,40(sp)
    80002c9c:	f022                	sd	s0,32(sp)
    80002c9e:	ec26                	sd	s1,24(sp)
    80002ca0:	e84a                	sd	s2,16(sp)
    80002ca2:	e44e                	sd	s3,8(sp)
    80002ca4:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ca6:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002caa:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002cae:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002cb2:	1004f793          	andi	a5,s1,256
    80002cb6:	cb85                	beqz	a5,80002ce6 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002cb8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002cbc:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002cbe:	ef85                	bnez	a5,80002cf6 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002cc0:	00000097          	auipc	ra,0x0
    80002cc4:	e42080e7          	jalr	-446(ra) # 80002b02 <devintr>
    80002cc8:	cd1d                	beqz	a0,80002d06 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cca:	4789                	li	a5,2
    80002ccc:	06f50a63          	beq	a0,a5,80002d40 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002cd0:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002cd4:	10049073          	csrw	sstatus,s1
}
    80002cd8:	70a2                	ld	ra,40(sp)
    80002cda:	7402                	ld	s0,32(sp)
    80002cdc:	64e2                	ld	s1,24(sp)
    80002cde:	6942                	ld	s2,16(sp)
    80002ce0:	69a2                	ld	s3,8(sp)
    80002ce2:	6145                	addi	sp,sp,48
    80002ce4:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ce6:	00005517          	auipc	a0,0x5
    80002cea:	71250513          	addi	a0,a0,1810 # 800083f8 <states.1712+0xc0>
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	862080e7          	jalr	-1950(ra) # 80000550 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cf6:	00005517          	auipc	a0,0x5
    80002cfa:	72a50513          	addi	a0,a0,1834 # 80008420 <states.1712+0xe8>
    80002cfe:	ffffe097          	auipc	ra,0xffffe
    80002d02:	852080e7          	jalr	-1966(ra) # 80000550 <panic>
    printf("scause %p\n", scause);
    80002d06:	85ce                	mv	a1,s3
    80002d08:	00005517          	auipc	a0,0x5
    80002d0c:	73850513          	addi	a0,a0,1848 # 80008440 <states.1712+0x108>
    80002d10:	ffffe097          	auipc	ra,0xffffe
    80002d14:	88a080e7          	jalr	-1910(ra) # 8000059a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002d18:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002d1c:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002d20:	00005517          	auipc	a0,0x5
    80002d24:	73050513          	addi	a0,a0,1840 # 80008450 <states.1712+0x118>
    80002d28:	ffffe097          	auipc	ra,0xffffe
    80002d2c:	872080e7          	jalr	-1934(ra) # 8000059a <printf>
    panic("kerneltrap");
    80002d30:	00005517          	auipc	a0,0x5
    80002d34:	73850513          	addi	a0,a0,1848 # 80008468 <states.1712+0x130>
    80002d38:	ffffe097          	auipc	ra,0xffffe
    80002d3c:	818080e7          	jalr	-2024(ra) # 80000550 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d40:	fffff097          	auipc	ra,0xfffff
    80002d44:	068080e7          	jalr	104(ra) # 80001da8 <myproc>
    80002d48:	d541                	beqz	a0,80002cd0 <kerneltrap+0x38>
    80002d4a:	fffff097          	auipc	ra,0xfffff
    80002d4e:	05e080e7          	jalr	94(ra) # 80001da8 <myproc>
    80002d52:	5118                	lw	a4,32(a0)
    80002d54:	478d                	li	a5,3
    80002d56:	f6f71de3          	bne	a4,a5,80002cd0 <kerneltrap+0x38>
    yield();
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	822080e7          	jalr	-2014(ra) # 8000257c <yield>
    80002d62:	b7bd                	j	80002cd0 <kerneltrap+0x38>

0000000080002d64 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d64:	1101                	addi	sp,sp,-32
    80002d66:	ec06                	sd	ra,24(sp)
    80002d68:	e822                	sd	s0,16(sp)
    80002d6a:	e426                	sd	s1,8(sp)
    80002d6c:	1000                	addi	s0,sp,32
    80002d6e:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d70:	fffff097          	auipc	ra,0xfffff
    80002d74:	038080e7          	jalr	56(ra) # 80001da8 <myproc>
  switch (n) {
    80002d78:	4795                	li	a5,5
    80002d7a:	0497e163          	bltu	a5,s1,80002dbc <argraw+0x58>
    80002d7e:	048a                	slli	s1,s1,0x2
    80002d80:	00005717          	auipc	a4,0x5
    80002d84:	72070713          	addi	a4,a4,1824 # 800084a0 <states.1712+0x168>
    80002d88:	94ba                	add	s1,s1,a4
    80002d8a:	409c                	lw	a5,0(s1)
    80002d8c:	97ba                	add	a5,a5,a4
    80002d8e:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d90:	713c                	ld	a5,96(a0)
    80002d92:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d94:	60e2                	ld	ra,24(sp)
    80002d96:	6442                	ld	s0,16(sp)
    80002d98:	64a2                	ld	s1,8(sp)
    80002d9a:	6105                	addi	sp,sp,32
    80002d9c:	8082                	ret
    return p->trapframe->a1;
    80002d9e:	713c                	ld	a5,96(a0)
    80002da0:	7fa8                	ld	a0,120(a5)
    80002da2:	bfcd                	j	80002d94 <argraw+0x30>
    return p->trapframe->a2;
    80002da4:	713c                	ld	a5,96(a0)
    80002da6:	63c8                	ld	a0,128(a5)
    80002da8:	b7f5                	j	80002d94 <argraw+0x30>
    return p->trapframe->a3;
    80002daa:	713c                	ld	a5,96(a0)
    80002dac:	67c8                	ld	a0,136(a5)
    80002dae:	b7dd                	j	80002d94 <argraw+0x30>
    return p->trapframe->a4;
    80002db0:	713c                	ld	a5,96(a0)
    80002db2:	6bc8                	ld	a0,144(a5)
    80002db4:	b7c5                	j	80002d94 <argraw+0x30>
    return p->trapframe->a5;
    80002db6:	713c                	ld	a5,96(a0)
    80002db8:	6fc8                	ld	a0,152(a5)
    80002dba:	bfe9                	j	80002d94 <argraw+0x30>
  panic("argraw");
    80002dbc:	00005517          	auipc	a0,0x5
    80002dc0:	6bc50513          	addi	a0,a0,1724 # 80008478 <states.1712+0x140>
    80002dc4:	ffffd097          	auipc	ra,0xffffd
    80002dc8:	78c080e7          	jalr	1932(ra) # 80000550 <panic>

0000000080002dcc <fetchaddr>:
{
    80002dcc:	1101                	addi	sp,sp,-32
    80002dce:	ec06                	sd	ra,24(sp)
    80002dd0:	e822                	sd	s0,16(sp)
    80002dd2:	e426                	sd	s1,8(sp)
    80002dd4:	e04a                	sd	s2,0(sp)
    80002dd6:	1000                	addi	s0,sp,32
    80002dd8:	84aa                	mv	s1,a0
    80002dda:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ddc:	fffff097          	auipc	ra,0xfffff
    80002de0:	fcc080e7          	jalr	-52(ra) # 80001da8 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002de4:	693c                	ld	a5,80(a0)
    80002de6:	02f4f863          	bgeu	s1,a5,80002e16 <fetchaddr+0x4a>
    80002dea:	00848713          	addi	a4,s1,8
    80002dee:	02e7e663          	bltu	a5,a4,80002e1a <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002df2:	46a1                	li	a3,8
    80002df4:	8626                	mv	a2,s1
    80002df6:	85ca                	mv	a1,s2
    80002df8:	6d28                	ld	a0,88(a0)
    80002dfa:	fffff097          	auipc	ra,0xfffff
    80002dfe:	d2e080e7          	jalr	-722(ra) # 80001b28 <copyin>
    80002e02:	00a03533          	snez	a0,a0
    80002e06:	40a00533          	neg	a0,a0
}
    80002e0a:	60e2                	ld	ra,24(sp)
    80002e0c:	6442                	ld	s0,16(sp)
    80002e0e:	64a2                	ld	s1,8(sp)
    80002e10:	6902                	ld	s2,0(sp)
    80002e12:	6105                	addi	sp,sp,32
    80002e14:	8082                	ret
    return -1;
    80002e16:	557d                	li	a0,-1
    80002e18:	bfcd                	j	80002e0a <fetchaddr+0x3e>
    80002e1a:	557d                	li	a0,-1
    80002e1c:	b7fd                	j	80002e0a <fetchaddr+0x3e>

0000000080002e1e <fetchstr>:
{
    80002e1e:	7179                	addi	sp,sp,-48
    80002e20:	f406                	sd	ra,40(sp)
    80002e22:	f022                	sd	s0,32(sp)
    80002e24:	ec26                	sd	s1,24(sp)
    80002e26:	e84a                	sd	s2,16(sp)
    80002e28:	e44e                	sd	s3,8(sp)
    80002e2a:	1800                	addi	s0,sp,48
    80002e2c:	892a                	mv	s2,a0
    80002e2e:	84ae                	mv	s1,a1
    80002e30:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e32:	fffff097          	auipc	ra,0xfffff
    80002e36:	f76080e7          	jalr	-138(ra) # 80001da8 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e3a:	86ce                	mv	a3,s3
    80002e3c:	864a                	mv	a2,s2
    80002e3e:	85a6                	mv	a1,s1
    80002e40:	6d28                	ld	a0,88(a0)
    80002e42:	fffff097          	auipc	ra,0xfffff
    80002e46:	d72080e7          	jalr	-654(ra) # 80001bb4 <copyinstr>
  if(err < 0)
    80002e4a:	00054763          	bltz	a0,80002e58 <fetchstr+0x3a>
  return strlen(buf);
    80002e4e:	8526                	mv	a0,s1
    80002e50:	ffffe097          	auipc	ra,0xffffe
    80002e54:	478080e7          	jalr	1144(ra) # 800012c8 <strlen>
}
    80002e58:	70a2                	ld	ra,40(sp)
    80002e5a:	7402                	ld	s0,32(sp)
    80002e5c:	64e2                	ld	s1,24(sp)
    80002e5e:	6942                	ld	s2,16(sp)
    80002e60:	69a2                	ld	s3,8(sp)
    80002e62:	6145                	addi	sp,sp,48
    80002e64:	8082                	ret

0000000080002e66 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e66:	1101                	addi	sp,sp,-32
    80002e68:	ec06                	sd	ra,24(sp)
    80002e6a:	e822                	sd	s0,16(sp)
    80002e6c:	e426                	sd	s1,8(sp)
    80002e6e:	1000                	addi	s0,sp,32
    80002e70:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	ef2080e7          	jalr	-270(ra) # 80002d64 <argraw>
    80002e7a:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e7c:	4501                	li	a0,0
    80002e7e:	60e2                	ld	ra,24(sp)
    80002e80:	6442                	ld	s0,16(sp)
    80002e82:	64a2                	ld	s1,8(sp)
    80002e84:	6105                	addi	sp,sp,32
    80002e86:	8082                	ret

0000000080002e88 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e88:	1101                	addi	sp,sp,-32
    80002e8a:	ec06                	sd	ra,24(sp)
    80002e8c:	e822                	sd	s0,16(sp)
    80002e8e:	e426                	sd	s1,8(sp)
    80002e90:	1000                	addi	s0,sp,32
    80002e92:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	ed0080e7          	jalr	-304(ra) # 80002d64 <argraw>
    80002e9c:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e9e:	4501                	li	a0,0
    80002ea0:	60e2                	ld	ra,24(sp)
    80002ea2:	6442                	ld	s0,16(sp)
    80002ea4:	64a2                	ld	s1,8(sp)
    80002ea6:	6105                	addi	sp,sp,32
    80002ea8:	8082                	ret

0000000080002eaa <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002eaa:	1101                	addi	sp,sp,-32
    80002eac:	ec06                	sd	ra,24(sp)
    80002eae:	e822                	sd	s0,16(sp)
    80002eb0:	e426                	sd	s1,8(sp)
    80002eb2:	e04a                	sd	s2,0(sp)
    80002eb4:	1000                	addi	s0,sp,32
    80002eb6:	84ae                	mv	s1,a1
    80002eb8:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002eba:	00000097          	auipc	ra,0x0
    80002ebe:	eaa080e7          	jalr	-342(ra) # 80002d64 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002ec2:	864a                	mv	a2,s2
    80002ec4:	85a6                	mv	a1,s1
    80002ec6:	00000097          	auipc	ra,0x0
    80002eca:	f58080e7          	jalr	-168(ra) # 80002e1e <fetchstr>
}
    80002ece:	60e2                	ld	ra,24(sp)
    80002ed0:	6442                	ld	s0,16(sp)
    80002ed2:	64a2                	ld	s1,8(sp)
    80002ed4:	6902                	ld	s2,0(sp)
    80002ed6:	6105                	addi	sp,sp,32
    80002ed8:	8082                	ret

0000000080002eda <syscall>:
[SYS_close]   sys_close,
};

void
syscall(void)
{
    80002eda:	1101                	addi	sp,sp,-32
    80002edc:	ec06                	sd	ra,24(sp)
    80002ede:	e822                	sd	s0,16(sp)
    80002ee0:	e426                	sd	s1,8(sp)
    80002ee2:	e04a                	sd	s2,0(sp)
    80002ee4:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002ee6:	fffff097          	auipc	ra,0xfffff
    80002eea:	ec2080e7          	jalr	-318(ra) # 80001da8 <myproc>
    80002eee:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ef0:	06053903          	ld	s2,96(a0)
    80002ef4:	0a893783          	ld	a5,168(s2)
    80002ef8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002efc:	37fd                	addiw	a5,a5,-1
    80002efe:	4751                	li	a4,20
    80002f00:	00f76f63          	bltu	a4,a5,80002f1e <syscall+0x44>
    80002f04:	00369713          	slli	a4,a3,0x3
    80002f08:	00005797          	auipc	a5,0x5
    80002f0c:	5b078793          	addi	a5,a5,1456 # 800084b8 <syscalls>
    80002f10:	97ba                	add	a5,a5,a4
    80002f12:	639c                	ld	a5,0(a5)
    80002f14:	c789                	beqz	a5,80002f1e <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002f16:	9782                	jalr	a5
    80002f18:	06a93823          	sd	a0,112(s2)
    80002f1c:	a839                	j	80002f3a <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002f1e:	16048613          	addi	a2,s1,352
    80002f22:	40ac                	lw	a1,64(s1)
    80002f24:	00005517          	auipc	a0,0x5
    80002f28:	55c50513          	addi	a0,a0,1372 # 80008480 <states.1712+0x148>
    80002f2c:	ffffd097          	auipc	ra,0xffffd
    80002f30:	66e080e7          	jalr	1646(ra) # 8000059a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f34:	70bc                	ld	a5,96(s1)
    80002f36:	577d                	li	a4,-1
    80002f38:	fbb8                	sd	a4,112(a5)
  }
}
    80002f3a:	60e2                	ld	ra,24(sp)
    80002f3c:	6442                	ld	s0,16(sp)
    80002f3e:	64a2                	ld	s1,8(sp)
    80002f40:	6902                	ld	s2,0(sp)
    80002f42:	6105                	addi	sp,sp,32
    80002f44:	8082                	ret

0000000080002f46 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f46:	1101                	addi	sp,sp,-32
    80002f48:	ec06                	sd	ra,24(sp)
    80002f4a:	e822                	sd	s0,16(sp)
    80002f4c:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f4e:	fec40593          	addi	a1,s0,-20
    80002f52:	4501                	li	a0,0
    80002f54:	00000097          	auipc	ra,0x0
    80002f58:	f12080e7          	jalr	-238(ra) # 80002e66 <argint>
    return -1;
    80002f5c:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f5e:	00054963          	bltz	a0,80002f70 <sys_exit+0x2a>
  exit(n);
    80002f62:	fec42503          	lw	a0,-20(s0)
    80002f66:	fffff097          	auipc	ra,0xfffff
    80002f6a:	50c080e7          	jalr	1292(ra) # 80002472 <exit>
  return 0;  // not reached
    80002f6e:	4781                	li	a5,0
}
    80002f70:	853e                	mv	a0,a5
    80002f72:	60e2                	ld	ra,24(sp)
    80002f74:	6442                	ld	s0,16(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret

0000000080002f7a <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f7a:	1141                	addi	sp,sp,-16
    80002f7c:	e406                	sd	ra,8(sp)
    80002f7e:	e022                	sd	s0,0(sp)
    80002f80:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f82:	fffff097          	auipc	ra,0xfffff
    80002f86:	e26080e7          	jalr	-474(ra) # 80001da8 <myproc>
}
    80002f8a:	4128                	lw	a0,64(a0)
    80002f8c:	60a2                	ld	ra,8(sp)
    80002f8e:	6402                	ld	s0,0(sp)
    80002f90:	0141                	addi	sp,sp,16
    80002f92:	8082                	ret

0000000080002f94 <sys_fork>:

uint64
sys_fork(void)
{
    80002f94:	1141                	addi	sp,sp,-16
    80002f96:	e406                	sd	ra,8(sp)
    80002f98:	e022                	sd	s0,0(sp)
    80002f9a:	0800                	addi	s0,sp,16
  return fork();
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	1cc080e7          	jalr	460(ra) # 80002168 <fork>
}
    80002fa4:	60a2                	ld	ra,8(sp)
    80002fa6:	6402                	ld	s0,0(sp)
    80002fa8:	0141                	addi	sp,sp,16
    80002faa:	8082                	ret

0000000080002fac <sys_wait>:

uint64
sys_wait(void)
{
    80002fac:	1101                	addi	sp,sp,-32
    80002fae:	ec06                	sd	ra,24(sp)
    80002fb0:	e822                	sd	s0,16(sp)
    80002fb2:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002fb4:	fe840593          	addi	a1,s0,-24
    80002fb8:	4501                	li	a0,0
    80002fba:	00000097          	auipc	ra,0x0
    80002fbe:	ece080e7          	jalr	-306(ra) # 80002e88 <argaddr>
    80002fc2:	87aa                	mv	a5,a0
    return -1;
    80002fc4:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002fc6:	0007c863          	bltz	a5,80002fd6 <sys_wait+0x2a>
  return wait(p);
    80002fca:	fe843503          	ld	a0,-24(s0)
    80002fce:	fffff097          	auipc	ra,0xfffff
    80002fd2:	668080e7          	jalr	1640(ra) # 80002636 <wait>
}
    80002fd6:	60e2                	ld	ra,24(sp)
    80002fd8:	6442                	ld	s0,16(sp)
    80002fda:	6105                	addi	sp,sp,32
    80002fdc:	8082                	ret

0000000080002fde <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fde:	7179                	addi	sp,sp,-48
    80002fe0:	f406                	sd	ra,40(sp)
    80002fe2:	f022                	sd	s0,32(sp)
    80002fe4:	ec26                	sd	s1,24(sp)
    80002fe6:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fe8:	fdc40593          	addi	a1,s0,-36
    80002fec:	4501                	li	a0,0
    80002fee:	00000097          	auipc	ra,0x0
    80002ff2:	e78080e7          	jalr	-392(ra) # 80002e66 <argint>
    80002ff6:	87aa                	mv	a5,a0
    return -1;
    80002ff8:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002ffa:	0207c063          	bltz	a5,8000301a <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002ffe:	fffff097          	auipc	ra,0xfffff
    80003002:	daa080e7          	jalr	-598(ra) # 80001da8 <myproc>
    80003006:	4924                	lw	s1,80(a0)
  if(growproc(n) < 0)
    80003008:	fdc42503          	lw	a0,-36(s0)
    8000300c:	fffff097          	auipc	ra,0xfffff
    80003010:	0e8080e7          	jalr	232(ra) # 800020f4 <growproc>
    80003014:	00054863          	bltz	a0,80003024 <sys_sbrk+0x46>
    return -1;
  return addr;
    80003018:	8526                	mv	a0,s1
}
    8000301a:	70a2                	ld	ra,40(sp)
    8000301c:	7402                	ld	s0,32(sp)
    8000301e:	64e2                	ld	s1,24(sp)
    80003020:	6145                	addi	sp,sp,48
    80003022:	8082                	ret
    return -1;
    80003024:	557d                	li	a0,-1
    80003026:	bfd5                	j	8000301a <sys_sbrk+0x3c>

0000000080003028 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003028:	7139                	addi	sp,sp,-64
    8000302a:	fc06                	sd	ra,56(sp)
    8000302c:	f822                	sd	s0,48(sp)
    8000302e:	f426                	sd	s1,40(sp)
    80003030:	f04a                	sd	s2,32(sp)
    80003032:	ec4e                	sd	s3,24(sp)
    80003034:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003036:	fcc40593          	addi	a1,s0,-52
    8000303a:	4501                	li	a0,0
    8000303c:	00000097          	auipc	ra,0x0
    80003040:	e2a080e7          	jalr	-470(ra) # 80002e66 <argint>
    return -1;
    80003044:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003046:	06054563          	bltz	a0,800030b0 <sys_sleep+0x88>
  acquire(&tickslock);
    8000304a:	00015517          	auipc	a0,0x15
    8000304e:	35e50513          	addi	a0,a0,862 # 800183a8 <tickslock>
    80003052:	ffffe097          	auipc	ra,0xffffe
    80003056:	d0e080e7          	jalr	-754(ra) # 80000d60 <acquire>
  ticks0 = ticks;
    8000305a:	00006917          	auipc	s2,0x6
    8000305e:	fc692903          	lw	s2,-58(s2) # 80009020 <ticks>
  while(ticks - ticks0 < n){
    80003062:	fcc42783          	lw	a5,-52(s0)
    80003066:	cf85                	beqz	a5,8000309e <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003068:	00015997          	auipc	s3,0x15
    8000306c:	34098993          	addi	s3,s3,832 # 800183a8 <tickslock>
    80003070:	00006497          	auipc	s1,0x6
    80003074:	fb048493          	addi	s1,s1,-80 # 80009020 <ticks>
    if(myproc()->killed){
    80003078:	fffff097          	auipc	ra,0xfffff
    8000307c:	d30080e7          	jalr	-720(ra) # 80001da8 <myproc>
    80003080:	5d1c                	lw	a5,56(a0)
    80003082:	ef9d                	bnez	a5,800030c0 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003084:	85ce                	mv	a1,s3
    80003086:	8526                	mv	a0,s1
    80003088:	fffff097          	auipc	ra,0xfffff
    8000308c:	530080e7          	jalr	1328(ra) # 800025b8 <sleep>
  while(ticks - ticks0 < n){
    80003090:	409c                	lw	a5,0(s1)
    80003092:	412787bb          	subw	a5,a5,s2
    80003096:	fcc42703          	lw	a4,-52(s0)
    8000309a:	fce7efe3          	bltu	a5,a4,80003078 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000309e:	00015517          	auipc	a0,0x15
    800030a2:	30a50513          	addi	a0,a0,778 # 800183a8 <tickslock>
    800030a6:	ffffe097          	auipc	ra,0xffffe
    800030aa:	d8a080e7          	jalr	-630(ra) # 80000e30 <release>
  return 0;
    800030ae:	4781                	li	a5,0
}
    800030b0:	853e                	mv	a0,a5
    800030b2:	70e2                	ld	ra,56(sp)
    800030b4:	7442                	ld	s0,48(sp)
    800030b6:	74a2                	ld	s1,40(sp)
    800030b8:	7902                	ld	s2,32(sp)
    800030ba:	69e2                	ld	s3,24(sp)
    800030bc:	6121                	addi	sp,sp,64
    800030be:	8082                	ret
      release(&tickslock);
    800030c0:	00015517          	auipc	a0,0x15
    800030c4:	2e850513          	addi	a0,a0,744 # 800183a8 <tickslock>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	d68080e7          	jalr	-664(ra) # 80000e30 <release>
      return -1;
    800030d0:	57fd                	li	a5,-1
    800030d2:	bff9                	j	800030b0 <sys_sleep+0x88>

00000000800030d4 <sys_kill>:

uint64
sys_kill(void)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030dc:	fec40593          	addi	a1,s0,-20
    800030e0:	4501                	li	a0,0
    800030e2:	00000097          	auipc	ra,0x0
    800030e6:	d84080e7          	jalr	-636(ra) # 80002e66 <argint>
    800030ea:	87aa                	mv	a5,a0
    return -1;
    800030ec:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030ee:	0007c863          	bltz	a5,800030fe <sys_kill+0x2a>
  return kill(pid);
    800030f2:	fec42503          	lw	a0,-20(s0)
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	6b2080e7          	jalr	1714(ra) # 800027a8 <kill>
}
    800030fe:	60e2                	ld	ra,24(sp)
    80003100:	6442                	ld	s0,16(sp)
    80003102:	6105                	addi	sp,sp,32
    80003104:	8082                	ret

0000000080003106 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003106:	1101                	addi	sp,sp,-32
    80003108:	ec06                	sd	ra,24(sp)
    8000310a:	e822                	sd	s0,16(sp)
    8000310c:	e426                	sd	s1,8(sp)
    8000310e:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003110:	00015517          	auipc	a0,0x15
    80003114:	29850513          	addi	a0,a0,664 # 800183a8 <tickslock>
    80003118:	ffffe097          	auipc	ra,0xffffe
    8000311c:	c48080e7          	jalr	-952(ra) # 80000d60 <acquire>
  xticks = ticks;
    80003120:	00006497          	auipc	s1,0x6
    80003124:	f004a483          	lw	s1,-256(s1) # 80009020 <ticks>
  release(&tickslock);
    80003128:	00015517          	auipc	a0,0x15
    8000312c:	28050513          	addi	a0,a0,640 # 800183a8 <tickslock>
    80003130:	ffffe097          	auipc	ra,0xffffe
    80003134:	d00080e7          	jalr	-768(ra) # 80000e30 <release>
  return xticks;
}
    80003138:	02049513          	slli	a0,s1,0x20
    8000313c:	9101                	srli	a0,a0,0x20
    8000313e:	60e2                	ld	ra,24(sp)
    80003140:	6442                	ld	s0,16(sp)
    80003142:	64a2                	ld	s1,8(sp)
    80003144:	6105                	addi	sp,sp,32
    80003146:	8082                	ret

0000000080003148 <binit>:
} hashtable;


void
binit(void)
{
    80003148:	7139                	addi	sp,sp,-64
    8000314a:	fc06                	sd	ra,56(sp)
    8000314c:	f822                	sd	s0,48(sp)
    8000314e:	f426                	sd	s1,40(sp)
    80003150:	f04a                	sd	s2,32(sp)
    80003152:	ec4e                	sd	s3,24(sp)
    80003154:	e852                	sd	s4,16(sp)
    80003156:	e456                	sd	s5,8(sp)
    80003158:	0080                	addi	s0,sp,64
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000315a:	00005597          	auipc	a1,0x5
    8000315e:	f9e58593          	addi	a1,a1,-98 # 800080f8 <digits+0xb8>
    80003162:	00015517          	auipc	a0,0x15
    80003166:	73e50513          	addi	a0,a0,1854 # 800188a0 <bcache>
    8000316a:	ffffe097          	auipc	ra,0xffffe
    8000316e:	d72080e7          	jalr	-654(ra) # 80000edc <initlock>

  
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003172:	00015497          	auipc	s1,0x15
    80003176:	75e48493          	addi	s1,s1,1886 # 800188d0 <bcache+0x30>
    8000317a:	0001e997          	auipc	s3,0x1e
    8000317e:	a9698993          	addi	s3,s3,-1386 # 80020c10 <sb+0x10>
  {
    initsleeplock(&b->lock, "buffer");
    80003182:	00005917          	auipc	s2,0x5
    80003186:	3e690913          	addi	s2,s2,998 # 80008568 <syscalls+0xb0>
    8000318a:	85ca                	mv	a1,s2
    8000318c:	8526                	mv	a0,s1
    8000318e:	00001097          	auipc	ra,0x1
    80003192:	69a080e7          	jalr	1690(ra) # 80004828 <initsleeplock>
  for (b = bcache.buf; b < bcache.buf + NBUF; b++)
    80003196:	46048493          	addi	s1,s1,1120
    8000319a:	ff3498e3          	bne	s1,s3,8000318a <binit+0x42>
    8000319e:	00015497          	auipc	s1,0x15
    800031a2:	22a48493          	addi	s1,s1,554 # 800183c8 <hashtable>
    800031a6:	00015917          	auipc	s2,0x15
    800031aa:	31a90913          	addi	s2,s2,794 # 800184c0 <hashtable+0xf8>
    800031ae:	89a6                	mv	s3,s1
    800031b0:	8aca                	mv	s5,s2
  }
  for (int i = 0; i < NBUCKET; i++)
  {
    initlock(&hashtable.bucket_locks[i], "bcache bucket");
    800031b2:	00005a17          	auipc	s4,0x5
    800031b6:	3bea0a13          	addi	s4,s4,958 # 80008570 <syscalls+0xb8>
    800031ba:	85d2                	mv	a1,s4
    800031bc:	854a                	mv	a0,s2
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	d1e080e7          	jalr	-738(ra) # 80000edc <initlock>
    hashtable.bucket[i] = 0;
    800031c6:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < NBUCKET; i++)
    800031ca:	02090913          	addi	s2,s2,32
    800031ce:	04a1                	addi	s1,s1,8
    800031d0:	ff5495e3          	bne	s1,s5,800031ba <binit+0x72>
    800031d4:	00015797          	auipc	a5,0x15
    800031d8:	6ec78793          	addi	a5,a5,1772 # 800188c0 <bcache+0x20>
  }
  // place bcache.buf[i] into hashtable.bucket[i]
  for (int i = 0; i < NBUF; i++)
    800031dc:	4701                	li	a4,0
    800031de:	46f9                	li	a3,30
  {
    hashtable.bucket[i] = &bcache.buf[i];
    800031e0:	00f9b023          	sd	a5,0(s3)
    bcache.buf[i].next = 0;
    800031e4:	0407b823          	sd	zero,80(a5)
    bcache.buf[i].refcnt = 0;
    800031e8:	0407a423          	sw	zero,72(a5)
    bcache.buf[i].timestamp = 0;
    800031ec:	4407ac23          	sw	zero,1112(a5)
    bcache.buf[i].valid = 0;
    800031f0:	0007a023          	sw	zero,0(a5)
    bcache.buf[i].blockno = i;
    800031f4:	c7d8                	sw	a4,12(a5)
  for (int i = 0; i < NBUF; i++)
    800031f6:	2705                	addiw	a4,a4,1
    800031f8:	46078793          	addi	a5,a5,1120
    800031fc:	09a1                	addi	s3,s3,8
    800031fe:	fed711e3          	bne	a4,a3,800031e0 <binit+0x98>
  }
}
    80003202:	70e2                	ld	ra,56(sp)
    80003204:	7442                	ld	s0,48(sp)
    80003206:	74a2                	ld	s1,40(sp)
    80003208:	7902                	ld	s2,32(sp)
    8000320a:	69e2                	ld	s3,24(sp)
    8000320c:	6a42                	ld	s4,16(sp)
    8000320e:	6aa2                	ld	s5,8(sp)
    80003210:	6121                	addi	sp,sp,64
    80003212:	8082                	ret

0000000080003214 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003214:	7119                	addi	sp,sp,-128
    80003216:	fc86                	sd	ra,120(sp)
    80003218:	f8a2                	sd	s0,112(sp)
    8000321a:	f4a6                	sd	s1,104(sp)
    8000321c:	f0ca                	sd	s2,96(sp)
    8000321e:	ecce                	sd	s3,88(sp)
    80003220:	e8d2                	sd	s4,80(sp)
    80003222:	e4d6                	sd	s5,72(sp)
    80003224:	e0da                	sd	s6,64(sp)
    80003226:	fc5e                	sd	s7,56(sp)
    80003228:	f862                	sd	s8,48(sp)
    8000322a:	f466                	sd	s9,40(sp)
    8000322c:	f06a                	sd	s10,32(sp)
    8000322e:	ec6e                	sd	s11,24(sp)
    80003230:	0100                	addi	s0,sp,128
    80003232:	8baa                	mv	s7,a0
    80003234:	8b2e                	mv	s6,a1
  return blockno % NBUCKET;
    80003236:	49fd                	li	s3,31
    80003238:	0335f9bb          	remuw	s3,a1,s3
  acquire(&hashtable.bucket_locks[idx]);
    8000323c:	00015497          	auipc	s1,0x15
    80003240:	18c48493          	addi	s1,s1,396 # 800183c8 <hashtable>
    80003244:	00599913          	slli	s2,s3,0x5
    80003248:	0f890913          	addi	s2,s2,248
    8000324c:	9926                	add	s2,s2,s1
    8000324e:	854a                	mv	a0,s2
    80003250:	ffffe097          	auipc	ra,0xffffe
    80003254:	b10080e7          	jalr	-1264(ra) # 80000d60 <acquire>
  for (b = hashtable.bucket[idx]; b != 0; b = b->next)
    80003258:	00399793          	slli	a5,s3,0x3
    8000325c:	94be                	add	s1,s1,a5
    8000325e:	609c                	ld	a5,0(s1)
    80003260:	c3c5                	beqz	a5,80003300 <bread+0xec>
    80003262:	84be                	mv	s1,a5
    80003264:	a019                	j	8000326a <bread+0x56>
    80003266:	68a4                	ld	s1,80(s1)
    80003268:	c495                	beqz	s1,80003294 <bread+0x80>
    if (b->dev == dev && b->blockno == blockno)
    8000326a:	4498                	lw	a4,8(s1)
    8000326c:	ff771de3          	bne	a4,s7,80003266 <bread+0x52>
    80003270:	44d8                	lw	a4,12(s1)
    80003272:	ff671ae3          	bne	a4,s6,80003266 <bread+0x52>
      b->refcnt++;
    80003276:	44bc                	lw	a5,72(s1)
    80003278:	2785                	addiw	a5,a5,1
    8000327a:	c4bc                	sw	a5,72(s1)
      release(&hashtable.bucket_locks[idx]);
    8000327c:	854a                	mv	a0,s2
    8000327e:	ffffe097          	auipc	ra,0xffffe
    80003282:	bb2080e7          	jalr	-1102(ra) # 80000e30 <release>
      acquiresleep(&b->lock);
    80003286:	01048513          	addi	a0,s1,16
    8000328a:	00001097          	auipc	ra,0x1
    8000328e:	5d8080e7          	jalr	1496(ra) # 80004862 <acquiresleep>
      return b;
    80003292:	a0a1                	j	800032da <bread+0xc6>
    80003294:	90000ab7          	lui	s5,0x90000
    80003298:	1afd                	addi	s5,s5,-1
    8000329a:	a019                	j	800032a0 <bread+0x8c>
  for (b = hashtable.bucket[idx]; b != 0; b = b->next)
    8000329c:	6bbc                	ld	a5,80(a5)
    8000329e:	cb91                	beqz	a5,800032b2 <bread+0x9e>
    if (b->refcnt == 0 && b->timestamp < lru)
    800032a0:	47b8                	lw	a4,72(a5)
    800032a2:	ff6d                	bnez	a4,8000329c <bread+0x88>
    800032a4:	4587a703          	lw	a4,1112(a5)
    800032a8:	ff577ae3          	bgeu	a4,s5,8000329c <bread+0x88>
    800032ac:	84be                	mv	s1,a5
      lru = b->timestamp;
    800032ae:	8aba                	mv	s5,a4
    800032b0:	b7f5                	j	8000329c <bread+0x88>
  if (lru_buf)
    800032b2:	c8b1                	beqz	s1,80003306 <bread+0xf2>
    lru_buf->dev = dev;
    800032b4:	0174a423          	sw	s7,8(s1)
    lru_buf->blockno = blockno;
    800032b8:	0164a623          	sw	s6,12(s1)
    lru_buf->valid = 0;
    800032bc:	0004a023          	sw	zero,0(s1)
    lru_buf->refcnt = 1;
    800032c0:	4785                	li	a5,1
    800032c2:	c4bc                	sw	a5,72(s1)
    release(&hashtable.bucket_locks[idx]);
    800032c4:	854a                	mv	a0,s2
    800032c6:	ffffe097          	auipc	ra,0xffffe
    800032ca:	b6a080e7          	jalr	-1174(ra) # 80000e30 <release>
    acquiresleep(&lru_buf->lock);
    800032ce:	01048513          	addi	a0,s1,16
    800032d2:	00001097          	auipc	ra,0x1
    800032d6:	590080e7          	jalr	1424(ra) # 80004862 <acquiresleep>
  struct buf *b;
  b = bget(dev, blockno);
  if(!b->valid) {
    800032da:	409c                	lw	a5,0(s1)
    800032dc:	16078863          	beqz	a5,8000344c <bread+0x238>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800032e0:	8526                	mv	a0,s1
    800032e2:	70e6                	ld	ra,120(sp)
    800032e4:	7446                	ld	s0,112(sp)
    800032e6:	74a6                	ld	s1,104(sp)
    800032e8:	7906                	ld	s2,96(sp)
    800032ea:	69e6                	ld	s3,88(sp)
    800032ec:	6a46                	ld	s4,80(sp)
    800032ee:	6aa6                	ld	s5,72(sp)
    800032f0:	6b06                	ld	s6,64(sp)
    800032f2:	7be2                	ld	s7,56(sp)
    800032f4:	7c42                	ld	s8,48(sp)
    800032f6:	7ca2                	ld	s9,40(sp)
    800032f8:	7d02                	ld	s10,32(sp)
    800032fa:	6de2                	ld	s11,24(sp)
    800032fc:	6109                	addi	sp,sp,128
    800032fe:	8082                	ret
  uint lru = 0x8fffffff;
    80003300:	90000ab7          	lui	s5,0x90000
    80003304:	1afd                	addi	s5,s5,-1
  release(&hashtable.bucket_locks[idx]); // prevent deadlock
    80003306:	854a                	mv	a0,s2
    80003308:	ffffe097          	auipc	ra,0xffffe
    8000330c:	b28080e7          	jalr	-1240(ra) # 80000e30 <release>
  acquire(&bcache.lock);
    80003310:	00015517          	auipc	a0,0x15
    80003314:	59050513          	addi	a0,a0,1424 # 800188a0 <bcache>
    80003318:	ffffe097          	auipc	ra,0xffffe
    8000331c:	a48080e7          	jalr	-1464(ra) # 80000d60 <acquire>
  for (int i = 0; i < NBUCKET; i++)
    80003320:	00015c97          	auipc	s9,0x15
    80003324:	1a0c8c93          	addi	s9,s9,416 # 800184c0 <hashtable+0xf8>
    80003328:	00015d97          	auipc	s11,0x15
    8000332c:	0a0d8d93          	addi	s11,s11,160 # 800183c8 <hashtable>
  int i_holding = 0;
    80003330:	f8043023          	sd	zero,-128(s0)
  acquire(&bcache.lock);
    80003334:	4481                	li	s1,0
  struct spinlock *holding = 0;
    80003336:	4c01                	li	s8,0
  for (int i = 0; i < NBUCKET; i++)
    80003338:	4a01                	li	s4,0
    8000333a:	4d7d                	li	s10,31
    8000333c:	a83d                	j	8000337a <bread+0x166>
      for (b = hashtable.bucket[i]; b != 0; b = b->next)
    8000333e:	6bbc                	ld	a5,80(a5)
    80003340:	cb99                	beqz	a5,80003356 <bread+0x142>
        if (b->refcnt == 0 && b->timestamp < lru)
    80003342:	47b4                	lw	a3,72(a5)
    80003344:	feed                	bnez	a3,8000333e <bread+0x12a>
    80003346:	4587a683          	lw	a3,1112(a5)
    8000334a:	ff56fae3          	bgeu	a3,s5,8000333e <bread+0x12a>
    8000334e:	84be                	mv	s1,a5
          lru = b->timestamp;
    80003350:	8ab6                	mv	s5,a3
          flag = 1;
    80003352:	4705                	li	a4,1
    80003354:	b7ed                	j	8000333e <bread+0x12a>
      if (flag)
    80003356:	c321                	beqz	a4,80003396 <bread+0x182>
        if (holding)
    80003358:	040c0663          	beqz	s8,800033a4 <bread+0x190>
          release(holding);
    8000335c:	8562                	mv	a0,s8
    8000335e:	ffffe097          	auipc	ra,0xffffe
    80003362:	ad2080e7          	jalr	-1326(ra) # 80000e30 <release>
    80003366:	f9443023          	sd	s4,-128(s0)
        holding = &hashtable.bucket_locks[i];
    8000336a:	f8843c03          	ld	s8,-120(s0)
  for (int i = 0; i < NBUCKET; i++)
    8000336e:	2a05                	addiw	s4,s4,1
    80003370:	020c8c93          	addi	s9,s9,32
    80003374:	0da1                	addi	s11,s11,8
    80003376:	03aa0c63          	beq	s4,s10,800033ae <bread+0x19a>
    if (i != idx)
    8000337a:	ff498ae3          	beq	s3,s4,8000336e <bread+0x15a>
      acquire(&hashtable.bucket_locks[i]);
    8000337e:	f9943423          	sd	s9,-120(s0)
    80003382:	8566                	mv	a0,s9
    80003384:	ffffe097          	auipc	ra,0xffffe
    80003388:	9dc080e7          	jalr	-1572(ra) # 80000d60 <acquire>
      for (b = hashtable.bucket[i]; b != 0; b = b->next)
    8000338c:	000db783          	ld	a5,0(s11)
    80003390:	c399                	beqz	a5,80003396 <bread+0x182>
      flag = 0;
    80003392:	4701                	li	a4,0
    80003394:	b77d                	j	80003342 <bread+0x12e>
        release(&hashtable.bucket_locks[i]);
    80003396:	f8843503          	ld	a0,-120(s0)
    8000339a:	ffffe097          	auipc	ra,0xffffe
    8000339e:	a96080e7          	jalr	-1386(ra) # 80000e30 <release>
    800033a2:	b7f1                	j	8000336e <bread+0x15a>
    800033a4:	f9443023          	sd	s4,-128(s0)
        holding = &hashtable.bucket_locks[i];
    800033a8:	f8843c03          	ld	s8,-120(s0)
    800033ac:	b7c9                	j	8000336e <bread+0x15a>
  if (lru_buf)
    800033ae:	c4d9                	beqz	s1,8000343c <bread+0x228>
    acquire(&hashtable.bucket_locks[idx]); // prevent deadlock
    800033b0:	854a                	mv	a0,s2
    800033b2:	ffffe097          	auipc	ra,0xffffe
    800033b6:	9ae080e7          	jalr	-1618(ra) # 80000d60 <acquire>
    for (b = hashtable.bucket[i_holding]; b != 0; b = b->next)
    800033ba:	f8043783          	ld	a5,-128(s0)
    800033be:	00379713          	slli	a4,a5,0x3
    800033c2:	00015797          	auipc	a5,0x15
    800033c6:	00678793          	addi	a5,a5,6 # 800183c8 <hashtable>
    800033ca:	97ba                	add	a5,a5,a4
    800033cc:	639c                	ld	a5,0(a5)
    800033ce:	cbc9                	beqz	a5,80003460 <bread+0x24c>
      if (b == lru_buf)
    800033d0:	08978763          	beq	a5,s1,8000345e <bread+0x24a>
    for (b = hashtable.bucket[i_holding]; b != 0; b = b->next)
    800033d4:	873e                	mv	a4,a5
    800033d6:	6bbc                	ld	a5,80(a5)
    800033d8:	c781                	beqz	a5,800033e0 <bread+0x1cc>
      if (b == lru_buf)
    800033da:	fe979de3          	bne	a5,s1,800033d4 <bread+0x1c0>
    800033de:	87a6                	mv	a5,s1
      prev->next = b->next;
    800033e0:	6bbc                	ld	a5,80(a5)
    800033e2:	eb3c                	sd	a5,80(a4)
    release(holding);
    800033e4:	8562                	mv	a0,s8
    800033e6:	ffffe097          	auipc	ra,0xffffe
    800033ea:	a4a080e7          	jalr	-1462(ra) # 80000e30 <release>
    lru_buf->next = hashtable.bucket[idx];
    800033ee:	098e                	slli	s3,s3,0x3
    800033f0:	00015797          	auipc	a5,0x15
    800033f4:	fd878793          	addi	a5,a5,-40 # 800183c8 <hashtable>
    800033f8:	99be                	add	s3,s3,a5
    800033fa:	0009b783          	ld	a5,0(s3)
    800033fe:	e8bc                	sd	a5,80(s1)
    hashtable.bucket[idx] = lru_buf;
    80003400:	0099b023          	sd	s1,0(s3)
    lru_buf->dev = dev;
    80003404:	0174a423          	sw	s7,8(s1)
    lru_buf->blockno = blockno;
    80003408:	0164a623          	sw	s6,12(s1)
    lru_buf->valid = 0;
    8000340c:	0004a023          	sw	zero,0(s1)
    lru_buf->refcnt = 1;
    80003410:	4785                	li	a5,1
    80003412:	c4bc                	sw	a5,72(s1)
    release(&hashtable.bucket_locks[idx]);
    80003414:	854a                	mv	a0,s2
    80003416:	ffffe097          	auipc	ra,0xffffe
    8000341a:	a1a080e7          	jalr	-1510(ra) # 80000e30 <release>
    release(&bcache.lock);
    8000341e:	00015517          	auipc	a0,0x15
    80003422:	48250513          	addi	a0,a0,1154 # 800188a0 <bcache>
    80003426:	ffffe097          	auipc	ra,0xffffe
    8000342a:	a0a080e7          	jalr	-1526(ra) # 80000e30 <release>
    acquiresleep(&lru_buf->lock);
    8000342e:	01048513          	addi	a0,s1,16
    80003432:	00001097          	auipc	ra,0x1
    80003436:	430080e7          	jalr	1072(ra) # 80004862 <acquiresleep>
    return lru_buf;
    8000343a:	b545                	j	800032da <bread+0xc6>
  panic("bget: no buffers");
    8000343c:	00005517          	auipc	a0,0x5
    80003440:	14450513          	addi	a0,a0,324 # 80008580 <syscalls+0xc8>
    80003444:	ffffd097          	auipc	ra,0xffffd
    80003448:	10c080e7          	jalr	268(ra) # 80000550 <panic>
    virtio_disk_rw(b, 0);
    8000344c:	4581                	li	a1,0
    8000344e:	8526                	mv	a0,s1
    80003450:	00003097          	auipc	ra,0x3
    80003454:	f96080e7          	jalr	-106(ra) # 800063e6 <virtio_disk_rw>
    b->valid = 1;
    80003458:	4785                	li	a5,1
    8000345a:	c09c                	sw	a5,0(s1)
  return b;
    8000345c:	b551                	j	800032e0 <bread+0xcc>
      if (b == lru_buf)
    8000345e:	87a6                	mv	a5,s1
      hashtable.bucket[i_holding] = b->next;
    80003460:	6bb4                	ld	a3,80(a5)
    80003462:	f8043783          	ld	a5,-128(s0)
    80003466:	078e                	slli	a5,a5,0x3
    80003468:	00015717          	auipc	a4,0x15
    8000346c:	f6070713          	addi	a4,a4,-160 # 800183c8 <hashtable>
    80003470:	97ba                	add	a5,a5,a4
    80003472:	e394                	sd	a3,0(a5)
    80003474:	bf85                	j	800033e4 <bread+0x1d0>

0000000080003476 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003476:	1101                	addi	sp,sp,-32
    80003478:	ec06                	sd	ra,24(sp)
    8000347a:	e822                	sd	s0,16(sp)
    8000347c:	e426                	sd	s1,8(sp)
    8000347e:	1000                	addi	s0,sp,32
    80003480:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003482:	0541                	addi	a0,a0,16
    80003484:	00001097          	auipc	ra,0x1
    80003488:	478080e7          	jalr	1144(ra) # 800048fc <holdingsleep>
    8000348c:	cd01                	beqz	a0,800034a4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    8000348e:	4585                	li	a1,1
    80003490:	8526                	mv	a0,s1
    80003492:	00003097          	auipc	ra,0x3
    80003496:	f54080e7          	jalr	-172(ra) # 800063e6 <virtio_disk_rw>
}
    8000349a:	60e2                	ld	ra,24(sp)
    8000349c:	6442                	ld	s0,16(sp)
    8000349e:	64a2                	ld	s1,8(sp)
    800034a0:	6105                	addi	sp,sp,32
    800034a2:	8082                	ret
    panic("bwrite");
    800034a4:	00005517          	auipc	a0,0x5
    800034a8:	0f450513          	addi	a0,a0,244 # 80008598 <syscalls+0xe0>
    800034ac:	ffffd097          	auipc	ra,0xffffd
    800034b0:	0a4080e7          	jalr	164(ra) # 80000550 <panic>

00000000800034b4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800034b4:	1101                	addi	sp,sp,-32
    800034b6:	ec06                	sd	ra,24(sp)
    800034b8:	e822                	sd	s0,16(sp)
    800034ba:	e426                	sd	s1,8(sp)
    800034bc:	e04a                	sd	s2,0(sp)
    800034be:	1000                	addi	s0,sp,32
    800034c0:	892a                	mv	s2,a0
  if(!holdingsleep(&b->lock))
    800034c2:	01050493          	addi	s1,a0,16
    800034c6:	8526                	mv	a0,s1
    800034c8:	00001097          	auipc	ra,0x1
    800034cc:	434080e7          	jalr	1076(ra) # 800048fc <holdingsleep>
    800034d0:	cd39                	beqz	a0,8000352e <brelse+0x7a>
    panic("brelse");

  releasesleep(&b->lock);
    800034d2:	8526                	mv	a0,s1
    800034d4:	00001097          	auipc	ra,0x1
    800034d8:	3e4080e7          	jalr	996(ra) # 800048b8 <releasesleep>
  return blockno % NBUCKET;
    800034dc:	00c92483          	lw	s1,12(s2)

  int idx = hash(b->dev, b->blockno);

  acquire(&hashtable.bucket_locks[idx]);
    800034e0:	47fd                	li	a5,31
    800034e2:	02f4f4bb          	remuw	s1,s1,a5
    800034e6:	0496                	slli	s1,s1,0x5
    800034e8:	00015797          	auipc	a5,0x15
    800034ec:	fd878793          	addi	a5,a5,-40 # 800184c0 <hashtable+0xf8>
    800034f0:	94be                	add	s1,s1,a5
    800034f2:	8526                	mv	a0,s1
    800034f4:	ffffe097          	auipc	ra,0xffffe
    800034f8:	86c080e7          	jalr	-1940(ra) # 80000d60 <acquire>
  b->refcnt--;
    800034fc:	04892783          	lw	a5,72(s2)
    80003500:	37fd                	addiw	a5,a5,-1
    80003502:	0007871b          	sext.w	a4,a5
    80003506:	04f92423          	sw	a5,72(s2)
  if (b->refcnt == 0) {
    8000350a:	e719                	bnez	a4,80003518 <brelse+0x64>
    // no one is waiting for it.
    b->timestamp = ticks;
    8000350c:	00006797          	auipc	a5,0x6
    80003510:	b147a783          	lw	a5,-1260(a5) # 80009020 <ticks>
    80003514:	44f92c23          	sw	a5,1112(s2)
  }
  
  release(&hashtable.bucket_locks[idx]);
    80003518:	8526                	mv	a0,s1
    8000351a:	ffffe097          	auipc	ra,0xffffe
    8000351e:	916080e7          	jalr	-1770(ra) # 80000e30 <release>
}
    80003522:	60e2                	ld	ra,24(sp)
    80003524:	6442                	ld	s0,16(sp)
    80003526:	64a2                	ld	s1,8(sp)
    80003528:	6902                	ld	s2,0(sp)
    8000352a:	6105                	addi	sp,sp,32
    8000352c:	8082                	ret
    panic("brelse");
    8000352e:	00005517          	auipc	a0,0x5
    80003532:	07250513          	addi	a0,a0,114 # 800085a0 <syscalls+0xe8>
    80003536:	ffffd097          	auipc	ra,0xffffd
    8000353a:	01a080e7          	jalr	26(ra) # 80000550 <panic>

000000008000353e <bpin>:

void
bpin(struct buf *b) {
    8000353e:	1101                	addi	sp,sp,-32
    80003540:	ec06                	sd	ra,24(sp)
    80003542:	e822                	sd	s0,16(sp)
    80003544:	e426                	sd	s1,8(sp)
    80003546:	e04a                	sd	s2,0(sp)
    80003548:	1000                	addi	s0,sp,32
    8000354a:	892a                	mv	s2,a0
  return blockno % NBUCKET;
    8000354c:	4544                	lw	s1,12(a0)
  int idx = hash(b->dev, b->blockno);
  acquire(&hashtable.bucket_locks[idx]);
    8000354e:	47fd                	li	a5,31
    80003550:	02f4f4bb          	remuw	s1,s1,a5
    80003554:	0496                	slli	s1,s1,0x5
    80003556:	00015797          	auipc	a5,0x15
    8000355a:	f6a78793          	addi	a5,a5,-150 # 800184c0 <hashtable+0xf8>
    8000355e:	94be                	add	s1,s1,a5
    80003560:	8526                	mv	a0,s1
    80003562:	ffffd097          	auipc	ra,0xffffd
    80003566:	7fe080e7          	jalr	2046(ra) # 80000d60 <acquire>
  b->refcnt++;
    8000356a:	04892783          	lw	a5,72(s2)
    8000356e:	2785                	addiw	a5,a5,1
    80003570:	04f92423          	sw	a5,72(s2)
  release(&hashtable.bucket_locks[idx]);
    80003574:	8526                	mv	a0,s1
    80003576:	ffffe097          	auipc	ra,0xffffe
    8000357a:	8ba080e7          	jalr	-1862(ra) # 80000e30 <release>
}
    8000357e:	60e2                	ld	ra,24(sp)
    80003580:	6442                	ld	s0,16(sp)
    80003582:	64a2                	ld	s1,8(sp)
    80003584:	6902                	ld	s2,0(sp)
    80003586:	6105                	addi	sp,sp,32
    80003588:	8082                	ret

000000008000358a <bunpin>:

void
bunpin(struct buf *b) {
    8000358a:	1101                	addi	sp,sp,-32
    8000358c:	ec06                	sd	ra,24(sp)
    8000358e:	e822                	sd	s0,16(sp)
    80003590:	e426                	sd	s1,8(sp)
    80003592:	e04a                	sd	s2,0(sp)
    80003594:	1000                	addi	s0,sp,32
    80003596:	892a                	mv	s2,a0
  return blockno % NBUCKET;
    80003598:	4544                	lw	s1,12(a0)
  int idx = hash(b->dev, b->blockno);
  acquire(&hashtable.bucket_locks[idx]);
    8000359a:	47fd                	li	a5,31
    8000359c:	02f4f4bb          	remuw	s1,s1,a5
    800035a0:	0496                	slli	s1,s1,0x5
    800035a2:	00015797          	auipc	a5,0x15
    800035a6:	f1e78793          	addi	a5,a5,-226 # 800184c0 <hashtable+0xf8>
    800035aa:	94be                	add	s1,s1,a5
    800035ac:	8526                	mv	a0,s1
    800035ae:	ffffd097          	auipc	ra,0xffffd
    800035b2:	7b2080e7          	jalr	1970(ra) # 80000d60 <acquire>
  b->refcnt--;
    800035b6:	04892783          	lw	a5,72(s2)
    800035ba:	37fd                	addiw	a5,a5,-1
    800035bc:	04f92423          	sw	a5,72(s2)
  release(&hashtable.bucket_locks[idx]);
    800035c0:	8526                	mv	a0,s1
    800035c2:	ffffe097          	auipc	ra,0xffffe
    800035c6:	86e080e7          	jalr	-1938(ra) # 80000e30 <release>
}
    800035ca:	60e2                	ld	ra,24(sp)
    800035cc:	6442                	ld	s0,16(sp)
    800035ce:	64a2                	ld	s1,8(sp)
    800035d0:	6902                	ld	s2,0(sp)
    800035d2:	6105                	addi	sp,sp,32
    800035d4:	8082                	ret

00000000800035d6 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800035d6:	1101                	addi	sp,sp,-32
    800035d8:	ec06                	sd	ra,24(sp)
    800035da:	e822                	sd	s0,16(sp)
    800035dc:	e426                	sd	s1,8(sp)
    800035de:	e04a                	sd	s2,0(sp)
    800035e0:	1000                	addi	s0,sp,32
    800035e2:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800035e4:	00d5d59b          	srliw	a1,a1,0xd
    800035e8:	0001d797          	auipc	a5,0x1d
    800035ec:	6347a783          	lw	a5,1588(a5) # 80020c1c <sb+0x1c>
    800035f0:	9dbd                	addw	a1,a1,a5
    800035f2:	00000097          	auipc	ra,0x0
    800035f6:	c22080e7          	jalr	-990(ra) # 80003214 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800035fa:	0074f713          	andi	a4,s1,7
    800035fe:	4785                	li	a5,1
    80003600:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003604:	14ce                	slli	s1,s1,0x33
    80003606:	90d9                	srli	s1,s1,0x36
    80003608:	00950733          	add	a4,a0,s1
    8000360c:	05874703          	lbu	a4,88(a4)
    80003610:	00e7f6b3          	and	a3,a5,a4
    80003614:	c69d                	beqz	a3,80003642 <bfree+0x6c>
    80003616:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003618:	94aa                	add	s1,s1,a0
    8000361a:	fff7c793          	not	a5,a5
    8000361e:	8ff9                	and	a5,a5,a4
    80003620:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003624:	00001097          	auipc	ra,0x1
    80003628:	116080e7          	jalr	278(ra) # 8000473a <log_write>
  brelse(bp);
    8000362c:	854a                	mv	a0,s2
    8000362e:	00000097          	auipc	ra,0x0
    80003632:	e86080e7          	jalr	-378(ra) # 800034b4 <brelse>
}
    80003636:	60e2                	ld	ra,24(sp)
    80003638:	6442                	ld	s0,16(sp)
    8000363a:	64a2                	ld	s1,8(sp)
    8000363c:	6902                	ld	s2,0(sp)
    8000363e:	6105                	addi	sp,sp,32
    80003640:	8082                	ret
    panic("freeing free block");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f6650513          	addi	a0,a0,-154 # 800085a8 <syscalls+0xf0>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	f06080e7          	jalr	-250(ra) # 80000550 <panic>

0000000080003652 <balloc>:
{
    80003652:	711d                	addi	sp,sp,-96
    80003654:	ec86                	sd	ra,88(sp)
    80003656:	e8a2                	sd	s0,80(sp)
    80003658:	e4a6                	sd	s1,72(sp)
    8000365a:	e0ca                	sd	s2,64(sp)
    8000365c:	fc4e                	sd	s3,56(sp)
    8000365e:	f852                	sd	s4,48(sp)
    80003660:	f456                	sd	s5,40(sp)
    80003662:	f05a                	sd	s6,32(sp)
    80003664:	ec5e                	sd	s7,24(sp)
    80003666:	e862                	sd	s8,16(sp)
    80003668:	e466                	sd	s9,8(sp)
    8000366a:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    8000366c:	0001d797          	auipc	a5,0x1d
    80003670:	5987a783          	lw	a5,1432(a5) # 80020c04 <sb+0x4>
    80003674:	cbd1                	beqz	a5,80003708 <balloc+0xb6>
    80003676:	8baa                	mv	s7,a0
    80003678:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000367a:	0001db17          	auipc	s6,0x1d
    8000367e:	586b0b13          	addi	s6,s6,1414 # 80020c00 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003682:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003684:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003686:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003688:	6c89                	lui	s9,0x2
    8000368a:	a831                	j	800036a6 <balloc+0x54>
    brelse(bp);
    8000368c:	854a                	mv	a0,s2
    8000368e:	00000097          	auipc	ra,0x0
    80003692:	e26080e7          	jalr	-474(ra) # 800034b4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003696:	015c87bb          	addw	a5,s9,s5
    8000369a:	00078a9b          	sext.w	s5,a5
    8000369e:	004b2703          	lw	a4,4(s6)
    800036a2:	06eaf363          	bgeu	s5,a4,80003708 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800036a6:	41fad79b          	sraiw	a5,s5,0x1f
    800036aa:	0137d79b          	srliw	a5,a5,0x13
    800036ae:	015787bb          	addw	a5,a5,s5
    800036b2:	40d7d79b          	sraiw	a5,a5,0xd
    800036b6:	01cb2583          	lw	a1,28(s6)
    800036ba:	9dbd                	addw	a1,a1,a5
    800036bc:	855e                	mv	a0,s7
    800036be:	00000097          	auipc	ra,0x0
    800036c2:	b56080e7          	jalr	-1194(ra) # 80003214 <bread>
    800036c6:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036c8:	004b2503          	lw	a0,4(s6)
    800036cc:	000a849b          	sext.w	s1,s5
    800036d0:	8662                	mv	a2,s8
    800036d2:	faa4fde3          	bgeu	s1,a0,8000368c <balloc+0x3a>
      m = 1 << (bi % 8);
    800036d6:	41f6579b          	sraiw	a5,a2,0x1f
    800036da:	01d7d69b          	srliw	a3,a5,0x1d
    800036de:	00c6873b          	addw	a4,a3,a2
    800036e2:	00777793          	andi	a5,a4,7
    800036e6:	9f95                	subw	a5,a5,a3
    800036e8:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800036ec:	4037571b          	sraiw	a4,a4,0x3
    800036f0:	00e906b3          	add	a3,s2,a4
    800036f4:	0586c683          	lbu	a3,88(a3)
    800036f8:	00d7f5b3          	and	a1,a5,a3
    800036fc:	cd91                	beqz	a1,80003718 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036fe:	2605                	addiw	a2,a2,1
    80003700:	2485                	addiw	s1,s1,1
    80003702:	fd4618e3          	bne	a2,s4,800036d2 <balloc+0x80>
    80003706:	b759                	j	8000368c <balloc+0x3a>
  panic("balloc: out of blocks");
    80003708:	00005517          	auipc	a0,0x5
    8000370c:	eb850513          	addi	a0,a0,-328 # 800085c0 <syscalls+0x108>
    80003710:	ffffd097          	auipc	ra,0xffffd
    80003714:	e40080e7          	jalr	-448(ra) # 80000550 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003718:	974a                	add	a4,a4,s2
    8000371a:	8fd5                	or	a5,a5,a3
    8000371c:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003720:	854a                	mv	a0,s2
    80003722:	00001097          	auipc	ra,0x1
    80003726:	018080e7          	jalr	24(ra) # 8000473a <log_write>
        brelse(bp);
    8000372a:	854a                	mv	a0,s2
    8000372c:	00000097          	auipc	ra,0x0
    80003730:	d88080e7          	jalr	-632(ra) # 800034b4 <brelse>
  bp = bread(dev, bno);
    80003734:	85a6                	mv	a1,s1
    80003736:	855e                	mv	a0,s7
    80003738:	00000097          	auipc	ra,0x0
    8000373c:	adc080e7          	jalr	-1316(ra) # 80003214 <bread>
    80003740:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003742:	40000613          	li	a2,1024
    80003746:	4581                	li	a1,0
    80003748:	05850513          	addi	a0,a0,88
    8000374c:	ffffe097          	auipc	ra,0xffffe
    80003750:	9f4080e7          	jalr	-1548(ra) # 80001140 <memset>
  log_write(bp);
    80003754:	854a                	mv	a0,s2
    80003756:	00001097          	auipc	ra,0x1
    8000375a:	fe4080e7          	jalr	-28(ra) # 8000473a <log_write>
  brelse(bp);
    8000375e:	854a                	mv	a0,s2
    80003760:	00000097          	auipc	ra,0x0
    80003764:	d54080e7          	jalr	-684(ra) # 800034b4 <brelse>
}
    80003768:	8526                	mv	a0,s1
    8000376a:	60e6                	ld	ra,88(sp)
    8000376c:	6446                	ld	s0,80(sp)
    8000376e:	64a6                	ld	s1,72(sp)
    80003770:	6906                	ld	s2,64(sp)
    80003772:	79e2                	ld	s3,56(sp)
    80003774:	7a42                	ld	s4,48(sp)
    80003776:	7aa2                	ld	s5,40(sp)
    80003778:	7b02                	ld	s6,32(sp)
    8000377a:	6be2                	ld	s7,24(sp)
    8000377c:	6c42                	ld	s8,16(sp)
    8000377e:	6ca2                	ld	s9,8(sp)
    80003780:	6125                	addi	sp,sp,96
    80003782:	8082                	ret

0000000080003784 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003784:	7179                	addi	sp,sp,-48
    80003786:	f406                	sd	ra,40(sp)
    80003788:	f022                	sd	s0,32(sp)
    8000378a:	ec26                	sd	s1,24(sp)
    8000378c:	e84a                	sd	s2,16(sp)
    8000378e:	e44e                	sd	s3,8(sp)
    80003790:	e052                	sd	s4,0(sp)
    80003792:	1800                	addi	s0,sp,48
    80003794:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003796:	47ad                	li	a5,11
    80003798:	04b7fe63          	bgeu	a5,a1,800037f4 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    8000379c:	ff45849b          	addiw	s1,a1,-12
    800037a0:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800037a4:	0ff00793          	li	a5,255
    800037a8:	0ae7e363          	bltu	a5,a4,8000384e <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800037ac:	08852583          	lw	a1,136(a0)
    800037b0:	c5ad                	beqz	a1,8000381a <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800037b2:	00092503          	lw	a0,0(s2)
    800037b6:	00000097          	auipc	ra,0x0
    800037ba:	a5e080e7          	jalr	-1442(ra) # 80003214 <bread>
    800037be:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800037c0:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800037c4:	02049593          	slli	a1,s1,0x20
    800037c8:	9181                	srli	a1,a1,0x20
    800037ca:	058a                	slli	a1,a1,0x2
    800037cc:	00b784b3          	add	s1,a5,a1
    800037d0:	0004a983          	lw	s3,0(s1)
    800037d4:	04098d63          	beqz	s3,8000382e <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800037d8:	8552                	mv	a0,s4
    800037da:	00000097          	auipc	ra,0x0
    800037de:	cda080e7          	jalr	-806(ra) # 800034b4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800037e2:	854e                	mv	a0,s3
    800037e4:	70a2                	ld	ra,40(sp)
    800037e6:	7402                	ld	s0,32(sp)
    800037e8:	64e2                	ld	s1,24(sp)
    800037ea:	6942                	ld	s2,16(sp)
    800037ec:	69a2                	ld	s3,8(sp)
    800037ee:	6a02                	ld	s4,0(sp)
    800037f0:	6145                	addi	sp,sp,48
    800037f2:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    800037f4:	02059493          	slli	s1,a1,0x20
    800037f8:	9081                	srli	s1,s1,0x20
    800037fa:	048a                	slli	s1,s1,0x2
    800037fc:	94aa                	add	s1,s1,a0
    800037fe:	0584a983          	lw	s3,88(s1)
    80003802:	fe0990e3          	bnez	s3,800037e2 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003806:	4108                	lw	a0,0(a0)
    80003808:	00000097          	auipc	ra,0x0
    8000380c:	e4a080e7          	jalr	-438(ra) # 80003652 <balloc>
    80003810:	0005099b          	sext.w	s3,a0
    80003814:	0534ac23          	sw	s3,88(s1)
    80003818:	b7e9                	j	800037e2 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000381a:	4108                	lw	a0,0(a0)
    8000381c:	00000097          	auipc	ra,0x0
    80003820:	e36080e7          	jalr	-458(ra) # 80003652 <balloc>
    80003824:	0005059b          	sext.w	a1,a0
    80003828:	08b92423          	sw	a1,136(s2)
    8000382c:	b759                	j	800037b2 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    8000382e:	00092503          	lw	a0,0(s2)
    80003832:	00000097          	auipc	ra,0x0
    80003836:	e20080e7          	jalr	-480(ra) # 80003652 <balloc>
    8000383a:	0005099b          	sext.w	s3,a0
    8000383e:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003842:	8552                	mv	a0,s4
    80003844:	00001097          	auipc	ra,0x1
    80003848:	ef6080e7          	jalr	-266(ra) # 8000473a <log_write>
    8000384c:	b771                	j	800037d8 <bmap+0x54>
  panic("bmap: out of range");
    8000384e:	00005517          	auipc	a0,0x5
    80003852:	d8a50513          	addi	a0,a0,-630 # 800085d8 <syscalls+0x120>
    80003856:	ffffd097          	auipc	ra,0xffffd
    8000385a:	cfa080e7          	jalr	-774(ra) # 80000550 <panic>

000000008000385e <iget>:
{
    8000385e:	7179                	addi	sp,sp,-48
    80003860:	f406                	sd	ra,40(sp)
    80003862:	f022                	sd	s0,32(sp)
    80003864:	ec26                	sd	s1,24(sp)
    80003866:	e84a                	sd	s2,16(sp)
    80003868:	e44e                	sd	s3,8(sp)
    8000386a:	e052                	sd	s4,0(sp)
    8000386c:	1800                	addi	s0,sp,48
    8000386e:	89aa                	mv	s3,a0
    80003870:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003872:	0001d517          	auipc	a0,0x1d
    80003876:	3ae50513          	addi	a0,a0,942 # 80020c20 <icache>
    8000387a:	ffffd097          	auipc	ra,0xffffd
    8000387e:	4e6080e7          	jalr	1254(ra) # 80000d60 <acquire>
  empty = 0;
    80003882:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003884:	0001d497          	auipc	s1,0x1d
    80003888:	3bc48493          	addi	s1,s1,956 # 80020c40 <icache+0x20>
    8000388c:	0001f697          	auipc	a3,0x1f
    80003890:	fd468693          	addi	a3,a3,-44 # 80022860 <log>
    80003894:	a039                	j	800038a2 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003896:	02090b63          	beqz	s2,800038cc <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    8000389a:	09048493          	addi	s1,s1,144
    8000389e:	02d48a63          	beq	s1,a3,800038d2 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800038a2:	449c                	lw	a5,8(s1)
    800038a4:	fef059e3          	blez	a5,80003896 <iget+0x38>
    800038a8:	4098                	lw	a4,0(s1)
    800038aa:	ff3716e3          	bne	a4,s3,80003896 <iget+0x38>
    800038ae:	40d8                	lw	a4,4(s1)
    800038b0:	ff4713e3          	bne	a4,s4,80003896 <iget+0x38>
      ip->ref++;
    800038b4:	2785                	addiw	a5,a5,1
    800038b6:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    800038b8:	0001d517          	auipc	a0,0x1d
    800038bc:	36850513          	addi	a0,a0,872 # 80020c20 <icache>
    800038c0:	ffffd097          	auipc	ra,0xffffd
    800038c4:	570080e7          	jalr	1392(ra) # 80000e30 <release>
      return ip;
    800038c8:	8926                	mv	s2,s1
    800038ca:	a03d                	j	800038f8 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800038cc:	f7f9                	bnez	a5,8000389a <iget+0x3c>
    800038ce:	8926                	mv	s2,s1
    800038d0:	b7e9                	j	8000389a <iget+0x3c>
  if(empty == 0)
    800038d2:	02090c63          	beqz	s2,8000390a <iget+0xac>
  ip->dev = dev;
    800038d6:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800038da:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800038de:	4785                	li	a5,1
    800038e0:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800038e4:	04092423          	sw	zero,72(s2)
  release(&icache.lock);
    800038e8:	0001d517          	auipc	a0,0x1d
    800038ec:	33850513          	addi	a0,a0,824 # 80020c20 <icache>
    800038f0:	ffffd097          	auipc	ra,0xffffd
    800038f4:	540080e7          	jalr	1344(ra) # 80000e30 <release>
}
    800038f8:	854a                	mv	a0,s2
    800038fa:	70a2                	ld	ra,40(sp)
    800038fc:	7402                	ld	s0,32(sp)
    800038fe:	64e2                	ld	s1,24(sp)
    80003900:	6942                	ld	s2,16(sp)
    80003902:	69a2                	ld	s3,8(sp)
    80003904:	6a02                	ld	s4,0(sp)
    80003906:	6145                	addi	sp,sp,48
    80003908:	8082                	ret
    panic("iget: no inodes");
    8000390a:	00005517          	auipc	a0,0x5
    8000390e:	ce650513          	addi	a0,a0,-794 # 800085f0 <syscalls+0x138>
    80003912:	ffffd097          	auipc	ra,0xffffd
    80003916:	c3e080e7          	jalr	-962(ra) # 80000550 <panic>

000000008000391a <fsinit>:
fsinit(int dev) {
    8000391a:	7179                	addi	sp,sp,-48
    8000391c:	f406                	sd	ra,40(sp)
    8000391e:	f022                	sd	s0,32(sp)
    80003920:	ec26                	sd	s1,24(sp)
    80003922:	e84a                	sd	s2,16(sp)
    80003924:	e44e                	sd	s3,8(sp)
    80003926:	1800                	addi	s0,sp,48
    80003928:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000392a:	4585                	li	a1,1
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	8e8080e7          	jalr	-1816(ra) # 80003214 <bread>
    80003934:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003936:	0001d997          	auipc	s3,0x1d
    8000393a:	2ca98993          	addi	s3,s3,714 # 80020c00 <sb>
    8000393e:	02000613          	li	a2,32
    80003942:	05850593          	addi	a1,a0,88
    80003946:	854e                	mv	a0,s3
    80003948:	ffffe097          	auipc	ra,0xffffe
    8000394c:	858080e7          	jalr	-1960(ra) # 800011a0 <memmove>
  brelse(bp);
    80003950:	8526                	mv	a0,s1
    80003952:	00000097          	auipc	ra,0x0
    80003956:	b62080e7          	jalr	-1182(ra) # 800034b4 <brelse>
  if(sb.magic != FSMAGIC)
    8000395a:	0009a703          	lw	a4,0(s3)
    8000395e:	102037b7          	lui	a5,0x10203
    80003962:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003966:	02f71263          	bne	a4,a5,8000398a <fsinit+0x70>
  initlog(dev, &sb);
    8000396a:	0001d597          	auipc	a1,0x1d
    8000396e:	29658593          	addi	a1,a1,662 # 80020c00 <sb>
    80003972:	854a                	mv	a0,s2
    80003974:	00001097          	auipc	ra,0x1
    80003978:	b4a080e7          	jalr	-1206(ra) # 800044be <initlog>
}
    8000397c:	70a2                	ld	ra,40(sp)
    8000397e:	7402                	ld	s0,32(sp)
    80003980:	64e2                	ld	s1,24(sp)
    80003982:	6942                	ld	s2,16(sp)
    80003984:	69a2                	ld	s3,8(sp)
    80003986:	6145                	addi	sp,sp,48
    80003988:	8082                	ret
    panic("invalid file system");
    8000398a:	00005517          	auipc	a0,0x5
    8000398e:	c7650513          	addi	a0,a0,-906 # 80008600 <syscalls+0x148>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	bbe080e7          	jalr	-1090(ra) # 80000550 <panic>

000000008000399a <iinit>:
{
    8000399a:	7179                	addi	sp,sp,-48
    8000399c:	f406                	sd	ra,40(sp)
    8000399e:	f022                	sd	s0,32(sp)
    800039a0:	ec26                	sd	s1,24(sp)
    800039a2:	e84a                	sd	s2,16(sp)
    800039a4:	e44e                	sd	s3,8(sp)
    800039a6:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    800039a8:	00005597          	auipc	a1,0x5
    800039ac:	c7058593          	addi	a1,a1,-912 # 80008618 <syscalls+0x160>
    800039b0:	0001d517          	auipc	a0,0x1d
    800039b4:	27050513          	addi	a0,a0,624 # 80020c20 <icache>
    800039b8:	ffffd097          	auipc	ra,0xffffd
    800039bc:	524080e7          	jalr	1316(ra) # 80000edc <initlock>
  for(i = 0; i < NINODE; i++) {
    800039c0:	0001d497          	auipc	s1,0x1d
    800039c4:	29048493          	addi	s1,s1,656 # 80020c50 <icache+0x30>
    800039c8:	0001f997          	auipc	s3,0x1f
    800039cc:	ea898993          	addi	s3,s3,-344 # 80022870 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    800039d0:	00005917          	auipc	s2,0x5
    800039d4:	c5090913          	addi	s2,s2,-944 # 80008620 <syscalls+0x168>
    800039d8:	85ca                	mv	a1,s2
    800039da:	8526                	mv	a0,s1
    800039dc:	00001097          	auipc	ra,0x1
    800039e0:	e4c080e7          	jalr	-436(ra) # 80004828 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800039e4:	09048493          	addi	s1,s1,144
    800039e8:	ff3498e3          	bne	s1,s3,800039d8 <iinit+0x3e>
}
    800039ec:	70a2                	ld	ra,40(sp)
    800039ee:	7402                	ld	s0,32(sp)
    800039f0:	64e2                	ld	s1,24(sp)
    800039f2:	6942                	ld	s2,16(sp)
    800039f4:	69a2                	ld	s3,8(sp)
    800039f6:	6145                	addi	sp,sp,48
    800039f8:	8082                	ret

00000000800039fa <ialloc>:
{
    800039fa:	715d                	addi	sp,sp,-80
    800039fc:	e486                	sd	ra,72(sp)
    800039fe:	e0a2                	sd	s0,64(sp)
    80003a00:	fc26                	sd	s1,56(sp)
    80003a02:	f84a                	sd	s2,48(sp)
    80003a04:	f44e                	sd	s3,40(sp)
    80003a06:	f052                	sd	s4,32(sp)
    80003a08:	ec56                	sd	s5,24(sp)
    80003a0a:	e85a                	sd	s6,16(sp)
    80003a0c:	e45e                	sd	s7,8(sp)
    80003a0e:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a10:	0001d717          	auipc	a4,0x1d
    80003a14:	1fc72703          	lw	a4,508(a4) # 80020c0c <sb+0xc>
    80003a18:	4785                	li	a5,1
    80003a1a:	04e7fa63          	bgeu	a5,a4,80003a6e <ialloc+0x74>
    80003a1e:	8aaa                	mv	s5,a0
    80003a20:	8bae                	mv	s7,a1
    80003a22:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003a24:	0001da17          	auipc	s4,0x1d
    80003a28:	1dca0a13          	addi	s4,s4,476 # 80020c00 <sb>
    80003a2c:	00048b1b          	sext.w	s6,s1
    80003a30:	0044d593          	srli	a1,s1,0x4
    80003a34:	018a2783          	lw	a5,24(s4)
    80003a38:	9dbd                	addw	a1,a1,a5
    80003a3a:	8556                	mv	a0,s5
    80003a3c:	fffff097          	auipc	ra,0xfffff
    80003a40:	7d8080e7          	jalr	2008(ra) # 80003214 <bread>
    80003a44:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003a46:	05850993          	addi	s3,a0,88
    80003a4a:	00f4f793          	andi	a5,s1,15
    80003a4e:	079a                	slli	a5,a5,0x6
    80003a50:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003a52:	00099783          	lh	a5,0(s3)
    80003a56:	c785                	beqz	a5,80003a7e <ialloc+0x84>
    brelse(bp);
    80003a58:	00000097          	auipc	ra,0x0
    80003a5c:	a5c080e7          	jalr	-1444(ra) # 800034b4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003a60:	0485                	addi	s1,s1,1
    80003a62:	00ca2703          	lw	a4,12(s4)
    80003a66:	0004879b          	sext.w	a5,s1
    80003a6a:	fce7e1e3          	bltu	a5,a4,80003a2c <ialloc+0x32>
  panic("ialloc: no inodes");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	bba50513          	addi	a0,a0,-1094 # 80008628 <syscalls+0x170>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	ada080e7          	jalr	-1318(ra) # 80000550 <panic>
      memset(dip, 0, sizeof(*dip));
    80003a7e:	04000613          	li	a2,64
    80003a82:	4581                	li	a1,0
    80003a84:	854e                	mv	a0,s3
    80003a86:	ffffd097          	auipc	ra,0xffffd
    80003a8a:	6ba080e7          	jalr	1722(ra) # 80001140 <memset>
      dip->type = type;
    80003a8e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a92:	854a                	mv	a0,s2
    80003a94:	00001097          	auipc	ra,0x1
    80003a98:	ca6080e7          	jalr	-858(ra) # 8000473a <log_write>
      brelse(bp);
    80003a9c:	854a                	mv	a0,s2
    80003a9e:	00000097          	auipc	ra,0x0
    80003aa2:	a16080e7          	jalr	-1514(ra) # 800034b4 <brelse>
      return iget(dev, inum);
    80003aa6:	85da                	mv	a1,s6
    80003aa8:	8556                	mv	a0,s5
    80003aaa:	00000097          	auipc	ra,0x0
    80003aae:	db4080e7          	jalr	-588(ra) # 8000385e <iget>
}
    80003ab2:	60a6                	ld	ra,72(sp)
    80003ab4:	6406                	ld	s0,64(sp)
    80003ab6:	74e2                	ld	s1,56(sp)
    80003ab8:	7942                	ld	s2,48(sp)
    80003aba:	79a2                	ld	s3,40(sp)
    80003abc:	7a02                	ld	s4,32(sp)
    80003abe:	6ae2                	ld	s5,24(sp)
    80003ac0:	6b42                	ld	s6,16(sp)
    80003ac2:	6ba2                	ld	s7,8(sp)
    80003ac4:	6161                	addi	sp,sp,80
    80003ac6:	8082                	ret

0000000080003ac8 <iupdate>:
{
    80003ac8:	1101                	addi	sp,sp,-32
    80003aca:	ec06                	sd	ra,24(sp)
    80003acc:	e822                	sd	s0,16(sp)
    80003ace:	e426                	sd	s1,8(sp)
    80003ad0:	e04a                	sd	s2,0(sp)
    80003ad2:	1000                	addi	s0,sp,32
    80003ad4:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ad6:	415c                	lw	a5,4(a0)
    80003ad8:	0047d79b          	srliw	a5,a5,0x4
    80003adc:	0001d597          	auipc	a1,0x1d
    80003ae0:	13c5a583          	lw	a1,316(a1) # 80020c18 <sb+0x18>
    80003ae4:	9dbd                	addw	a1,a1,a5
    80003ae6:	4108                	lw	a0,0(a0)
    80003ae8:	fffff097          	auipc	ra,0xfffff
    80003aec:	72c080e7          	jalr	1836(ra) # 80003214 <bread>
    80003af0:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003af2:	05850793          	addi	a5,a0,88
    80003af6:	40c8                	lw	a0,4(s1)
    80003af8:	893d                	andi	a0,a0,15
    80003afa:	051a                	slli	a0,a0,0x6
    80003afc:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003afe:	04c49703          	lh	a4,76(s1)
    80003b02:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003b06:	04e49703          	lh	a4,78(s1)
    80003b0a:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003b0e:	05049703          	lh	a4,80(s1)
    80003b12:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003b16:	05249703          	lh	a4,82(s1)
    80003b1a:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003b1e:	48f8                	lw	a4,84(s1)
    80003b20:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003b22:	03400613          	li	a2,52
    80003b26:	05848593          	addi	a1,s1,88
    80003b2a:	0531                	addi	a0,a0,12
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	674080e7          	jalr	1652(ra) # 800011a0 <memmove>
  log_write(bp);
    80003b34:	854a                	mv	a0,s2
    80003b36:	00001097          	auipc	ra,0x1
    80003b3a:	c04080e7          	jalr	-1020(ra) # 8000473a <log_write>
  brelse(bp);
    80003b3e:	854a                	mv	a0,s2
    80003b40:	00000097          	auipc	ra,0x0
    80003b44:	974080e7          	jalr	-1676(ra) # 800034b4 <brelse>
}
    80003b48:	60e2                	ld	ra,24(sp)
    80003b4a:	6442                	ld	s0,16(sp)
    80003b4c:	64a2                	ld	s1,8(sp)
    80003b4e:	6902                	ld	s2,0(sp)
    80003b50:	6105                	addi	sp,sp,32
    80003b52:	8082                	ret

0000000080003b54 <idup>:
{
    80003b54:	1101                	addi	sp,sp,-32
    80003b56:	ec06                	sd	ra,24(sp)
    80003b58:	e822                	sd	s0,16(sp)
    80003b5a:	e426                	sd	s1,8(sp)
    80003b5c:	1000                	addi	s0,sp,32
    80003b5e:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003b60:	0001d517          	auipc	a0,0x1d
    80003b64:	0c050513          	addi	a0,a0,192 # 80020c20 <icache>
    80003b68:	ffffd097          	auipc	ra,0xffffd
    80003b6c:	1f8080e7          	jalr	504(ra) # 80000d60 <acquire>
  ip->ref++;
    80003b70:	449c                	lw	a5,8(s1)
    80003b72:	2785                	addiw	a5,a5,1
    80003b74:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003b76:	0001d517          	auipc	a0,0x1d
    80003b7a:	0aa50513          	addi	a0,a0,170 # 80020c20 <icache>
    80003b7e:	ffffd097          	auipc	ra,0xffffd
    80003b82:	2b2080e7          	jalr	690(ra) # 80000e30 <release>
}
    80003b86:	8526                	mv	a0,s1
    80003b88:	60e2                	ld	ra,24(sp)
    80003b8a:	6442                	ld	s0,16(sp)
    80003b8c:	64a2                	ld	s1,8(sp)
    80003b8e:	6105                	addi	sp,sp,32
    80003b90:	8082                	ret

0000000080003b92 <ilock>:
{
    80003b92:	1101                	addi	sp,sp,-32
    80003b94:	ec06                	sd	ra,24(sp)
    80003b96:	e822                	sd	s0,16(sp)
    80003b98:	e426                	sd	s1,8(sp)
    80003b9a:	e04a                	sd	s2,0(sp)
    80003b9c:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b9e:	c115                	beqz	a0,80003bc2 <ilock+0x30>
    80003ba0:	84aa                	mv	s1,a0
    80003ba2:	451c                	lw	a5,8(a0)
    80003ba4:	00f05f63          	blez	a5,80003bc2 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003ba8:	0541                	addi	a0,a0,16
    80003baa:	00001097          	auipc	ra,0x1
    80003bae:	cb8080e7          	jalr	-840(ra) # 80004862 <acquiresleep>
  if(ip->valid == 0){
    80003bb2:	44bc                	lw	a5,72(s1)
    80003bb4:	cf99                	beqz	a5,80003bd2 <ilock+0x40>
}
    80003bb6:	60e2                	ld	ra,24(sp)
    80003bb8:	6442                	ld	s0,16(sp)
    80003bba:	64a2                	ld	s1,8(sp)
    80003bbc:	6902                	ld	s2,0(sp)
    80003bbe:	6105                	addi	sp,sp,32
    80003bc0:	8082                	ret
    panic("ilock");
    80003bc2:	00005517          	auipc	a0,0x5
    80003bc6:	a7e50513          	addi	a0,a0,-1410 # 80008640 <syscalls+0x188>
    80003bca:	ffffd097          	auipc	ra,0xffffd
    80003bce:	986080e7          	jalr	-1658(ra) # 80000550 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003bd2:	40dc                	lw	a5,4(s1)
    80003bd4:	0047d79b          	srliw	a5,a5,0x4
    80003bd8:	0001d597          	auipc	a1,0x1d
    80003bdc:	0405a583          	lw	a1,64(a1) # 80020c18 <sb+0x18>
    80003be0:	9dbd                	addw	a1,a1,a5
    80003be2:	4088                	lw	a0,0(s1)
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	630080e7          	jalr	1584(ra) # 80003214 <bread>
    80003bec:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003bee:	05850593          	addi	a1,a0,88
    80003bf2:	40dc                	lw	a5,4(s1)
    80003bf4:	8bbd                	andi	a5,a5,15
    80003bf6:	079a                	slli	a5,a5,0x6
    80003bf8:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003bfa:	00059783          	lh	a5,0(a1)
    80003bfe:	04f49623          	sh	a5,76(s1)
    ip->major = dip->major;
    80003c02:	00259783          	lh	a5,2(a1)
    80003c06:	04f49723          	sh	a5,78(s1)
    ip->minor = dip->minor;
    80003c0a:	00459783          	lh	a5,4(a1)
    80003c0e:	04f49823          	sh	a5,80(s1)
    ip->nlink = dip->nlink;
    80003c12:	00659783          	lh	a5,6(a1)
    80003c16:	04f49923          	sh	a5,82(s1)
    ip->size = dip->size;
    80003c1a:	459c                	lw	a5,8(a1)
    80003c1c:	c8fc                	sw	a5,84(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003c1e:	03400613          	li	a2,52
    80003c22:	05b1                	addi	a1,a1,12
    80003c24:	05848513          	addi	a0,s1,88
    80003c28:	ffffd097          	auipc	ra,0xffffd
    80003c2c:	578080e7          	jalr	1400(ra) # 800011a0 <memmove>
    brelse(bp);
    80003c30:	854a                	mv	a0,s2
    80003c32:	00000097          	auipc	ra,0x0
    80003c36:	882080e7          	jalr	-1918(ra) # 800034b4 <brelse>
    ip->valid = 1;
    80003c3a:	4785                	li	a5,1
    80003c3c:	c4bc                	sw	a5,72(s1)
    if(ip->type == 0)
    80003c3e:	04c49783          	lh	a5,76(s1)
    80003c42:	fbb5                	bnez	a5,80003bb6 <ilock+0x24>
      panic("ilock: no type");
    80003c44:	00005517          	auipc	a0,0x5
    80003c48:	a0450513          	addi	a0,a0,-1532 # 80008648 <syscalls+0x190>
    80003c4c:	ffffd097          	auipc	ra,0xffffd
    80003c50:	904080e7          	jalr	-1788(ra) # 80000550 <panic>

0000000080003c54 <iunlock>:
{
    80003c54:	1101                	addi	sp,sp,-32
    80003c56:	ec06                	sd	ra,24(sp)
    80003c58:	e822                	sd	s0,16(sp)
    80003c5a:	e426                	sd	s1,8(sp)
    80003c5c:	e04a                	sd	s2,0(sp)
    80003c5e:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003c60:	c905                	beqz	a0,80003c90 <iunlock+0x3c>
    80003c62:	84aa                	mv	s1,a0
    80003c64:	01050913          	addi	s2,a0,16
    80003c68:	854a                	mv	a0,s2
    80003c6a:	00001097          	auipc	ra,0x1
    80003c6e:	c92080e7          	jalr	-878(ra) # 800048fc <holdingsleep>
    80003c72:	cd19                	beqz	a0,80003c90 <iunlock+0x3c>
    80003c74:	449c                	lw	a5,8(s1)
    80003c76:	00f05d63          	blez	a5,80003c90 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003c7a:	854a                	mv	a0,s2
    80003c7c:	00001097          	auipc	ra,0x1
    80003c80:	c3c080e7          	jalr	-964(ra) # 800048b8 <releasesleep>
}
    80003c84:	60e2                	ld	ra,24(sp)
    80003c86:	6442                	ld	s0,16(sp)
    80003c88:	64a2                	ld	s1,8(sp)
    80003c8a:	6902                	ld	s2,0(sp)
    80003c8c:	6105                	addi	sp,sp,32
    80003c8e:	8082                	ret
    panic("iunlock");
    80003c90:	00005517          	auipc	a0,0x5
    80003c94:	9c850513          	addi	a0,a0,-1592 # 80008658 <syscalls+0x1a0>
    80003c98:	ffffd097          	auipc	ra,0xffffd
    80003c9c:	8b8080e7          	jalr	-1864(ra) # 80000550 <panic>

0000000080003ca0 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ca0:	7179                	addi	sp,sp,-48
    80003ca2:	f406                	sd	ra,40(sp)
    80003ca4:	f022                	sd	s0,32(sp)
    80003ca6:	ec26                	sd	s1,24(sp)
    80003ca8:	e84a                	sd	s2,16(sp)
    80003caa:	e44e                	sd	s3,8(sp)
    80003cac:	e052                	sd	s4,0(sp)
    80003cae:	1800                	addi	s0,sp,48
    80003cb0:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003cb2:	05850493          	addi	s1,a0,88
    80003cb6:	08850913          	addi	s2,a0,136
    80003cba:	a021                	j	80003cc2 <itrunc+0x22>
    80003cbc:	0491                	addi	s1,s1,4
    80003cbe:	01248d63          	beq	s1,s2,80003cd8 <itrunc+0x38>
    if(ip->addrs[i]){
    80003cc2:	408c                	lw	a1,0(s1)
    80003cc4:	dde5                	beqz	a1,80003cbc <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003cc6:	0009a503          	lw	a0,0(s3)
    80003cca:	00000097          	auipc	ra,0x0
    80003cce:	90c080e7          	jalr	-1780(ra) # 800035d6 <bfree>
      ip->addrs[i] = 0;
    80003cd2:	0004a023          	sw	zero,0(s1)
    80003cd6:	b7dd                	j	80003cbc <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003cd8:	0889a583          	lw	a1,136(s3)
    80003cdc:	e185                	bnez	a1,80003cfc <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003cde:	0409aa23          	sw	zero,84(s3)
  iupdate(ip);
    80003ce2:	854e                	mv	a0,s3
    80003ce4:	00000097          	auipc	ra,0x0
    80003ce8:	de4080e7          	jalr	-540(ra) # 80003ac8 <iupdate>
}
    80003cec:	70a2                	ld	ra,40(sp)
    80003cee:	7402                	ld	s0,32(sp)
    80003cf0:	64e2                	ld	s1,24(sp)
    80003cf2:	6942                	ld	s2,16(sp)
    80003cf4:	69a2                	ld	s3,8(sp)
    80003cf6:	6a02                	ld	s4,0(sp)
    80003cf8:	6145                	addi	sp,sp,48
    80003cfa:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003cfc:	0009a503          	lw	a0,0(s3)
    80003d00:	fffff097          	auipc	ra,0xfffff
    80003d04:	514080e7          	jalr	1300(ra) # 80003214 <bread>
    80003d08:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003d0a:	05850493          	addi	s1,a0,88
    80003d0e:	45850913          	addi	s2,a0,1112
    80003d12:	a811                	j	80003d26 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003d14:	0009a503          	lw	a0,0(s3)
    80003d18:	00000097          	auipc	ra,0x0
    80003d1c:	8be080e7          	jalr	-1858(ra) # 800035d6 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003d20:	0491                	addi	s1,s1,4
    80003d22:	01248563          	beq	s1,s2,80003d2c <itrunc+0x8c>
      if(a[j])
    80003d26:	408c                	lw	a1,0(s1)
    80003d28:	dde5                	beqz	a1,80003d20 <itrunc+0x80>
    80003d2a:	b7ed                	j	80003d14 <itrunc+0x74>
    brelse(bp);
    80003d2c:	8552                	mv	a0,s4
    80003d2e:	fffff097          	auipc	ra,0xfffff
    80003d32:	786080e7          	jalr	1926(ra) # 800034b4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003d36:	0889a583          	lw	a1,136(s3)
    80003d3a:	0009a503          	lw	a0,0(s3)
    80003d3e:	00000097          	auipc	ra,0x0
    80003d42:	898080e7          	jalr	-1896(ra) # 800035d6 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003d46:	0809a423          	sw	zero,136(s3)
    80003d4a:	bf51                	j	80003cde <itrunc+0x3e>

0000000080003d4c <iput>:
{
    80003d4c:	1101                	addi	sp,sp,-32
    80003d4e:	ec06                	sd	ra,24(sp)
    80003d50:	e822                	sd	s0,16(sp)
    80003d52:	e426                	sd	s1,8(sp)
    80003d54:	e04a                	sd	s2,0(sp)
    80003d56:	1000                	addi	s0,sp,32
    80003d58:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003d5a:	0001d517          	auipc	a0,0x1d
    80003d5e:	ec650513          	addi	a0,a0,-314 # 80020c20 <icache>
    80003d62:	ffffd097          	auipc	ra,0xffffd
    80003d66:	ffe080e7          	jalr	-2(ra) # 80000d60 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d6a:	4498                	lw	a4,8(s1)
    80003d6c:	4785                	li	a5,1
    80003d6e:	02f70363          	beq	a4,a5,80003d94 <iput+0x48>
  ip->ref--;
    80003d72:	449c                	lw	a5,8(s1)
    80003d74:	37fd                	addiw	a5,a5,-1
    80003d76:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003d78:	0001d517          	auipc	a0,0x1d
    80003d7c:	ea850513          	addi	a0,a0,-344 # 80020c20 <icache>
    80003d80:	ffffd097          	auipc	ra,0xffffd
    80003d84:	0b0080e7          	jalr	176(ra) # 80000e30 <release>
}
    80003d88:	60e2                	ld	ra,24(sp)
    80003d8a:	6442                	ld	s0,16(sp)
    80003d8c:	64a2                	ld	s1,8(sp)
    80003d8e:	6902                	ld	s2,0(sp)
    80003d90:	6105                	addi	sp,sp,32
    80003d92:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003d94:	44bc                	lw	a5,72(s1)
    80003d96:	dff1                	beqz	a5,80003d72 <iput+0x26>
    80003d98:	05249783          	lh	a5,82(s1)
    80003d9c:	fbf9                	bnez	a5,80003d72 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d9e:	01048913          	addi	s2,s1,16
    80003da2:	854a                	mv	a0,s2
    80003da4:	00001097          	auipc	ra,0x1
    80003da8:	abe080e7          	jalr	-1346(ra) # 80004862 <acquiresleep>
    release(&icache.lock);
    80003dac:	0001d517          	auipc	a0,0x1d
    80003db0:	e7450513          	addi	a0,a0,-396 # 80020c20 <icache>
    80003db4:	ffffd097          	auipc	ra,0xffffd
    80003db8:	07c080e7          	jalr	124(ra) # 80000e30 <release>
    itrunc(ip);
    80003dbc:	8526                	mv	a0,s1
    80003dbe:	00000097          	auipc	ra,0x0
    80003dc2:	ee2080e7          	jalr	-286(ra) # 80003ca0 <itrunc>
    ip->type = 0;
    80003dc6:	04049623          	sh	zero,76(s1)
    iupdate(ip);
    80003dca:	8526                	mv	a0,s1
    80003dcc:	00000097          	auipc	ra,0x0
    80003dd0:	cfc080e7          	jalr	-772(ra) # 80003ac8 <iupdate>
    ip->valid = 0;
    80003dd4:	0404a423          	sw	zero,72(s1)
    releasesleep(&ip->lock);
    80003dd8:	854a                	mv	a0,s2
    80003dda:	00001097          	auipc	ra,0x1
    80003dde:	ade080e7          	jalr	-1314(ra) # 800048b8 <releasesleep>
    acquire(&icache.lock);
    80003de2:	0001d517          	auipc	a0,0x1d
    80003de6:	e3e50513          	addi	a0,a0,-450 # 80020c20 <icache>
    80003dea:	ffffd097          	auipc	ra,0xffffd
    80003dee:	f76080e7          	jalr	-138(ra) # 80000d60 <acquire>
    80003df2:	b741                	j	80003d72 <iput+0x26>

0000000080003df4 <iunlockput>:
{
    80003df4:	1101                	addi	sp,sp,-32
    80003df6:	ec06                	sd	ra,24(sp)
    80003df8:	e822                	sd	s0,16(sp)
    80003dfa:	e426                	sd	s1,8(sp)
    80003dfc:	1000                	addi	s0,sp,32
    80003dfe:	84aa                	mv	s1,a0
  iunlock(ip);
    80003e00:	00000097          	auipc	ra,0x0
    80003e04:	e54080e7          	jalr	-428(ra) # 80003c54 <iunlock>
  iput(ip);
    80003e08:	8526                	mv	a0,s1
    80003e0a:	00000097          	auipc	ra,0x0
    80003e0e:	f42080e7          	jalr	-190(ra) # 80003d4c <iput>
}
    80003e12:	60e2                	ld	ra,24(sp)
    80003e14:	6442                	ld	s0,16(sp)
    80003e16:	64a2                	ld	s1,8(sp)
    80003e18:	6105                	addi	sp,sp,32
    80003e1a:	8082                	ret

0000000080003e1c <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003e1c:	1141                	addi	sp,sp,-16
    80003e1e:	e422                	sd	s0,8(sp)
    80003e20:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003e22:	411c                	lw	a5,0(a0)
    80003e24:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003e26:	415c                	lw	a5,4(a0)
    80003e28:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003e2a:	04c51783          	lh	a5,76(a0)
    80003e2e:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003e32:	05251783          	lh	a5,82(a0)
    80003e36:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003e3a:	05456783          	lwu	a5,84(a0)
    80003e3e:	e99c                	sd	a5,16(a1)
}
    80003e40:	6422                	ld	s0,8(sp)
    80003e42:	0141                	addi	sp,sp,16
    80003e44:	8082                	ret

0000000080003e46 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003e46:	497c                	lw	a5,84(a0)
    80003e48:	0ed7e963          	bltu	a5,a3,80003f3a <readi+0xf4>
{
    80003e4c:	7159                	addi	sp,sp,-112
    80003e4e:	f486                	sd	ra,104(sp)
    80003e50:	f0a2                	sd	s0,96(sp)
    80003e52:	eca6                	sd	s1,88(sp)
    80003e54:	e8ca                	sd	s2,80(sp)
    80003e56:	e4ce                	sd	s3,72(sp)
    80003e58:	e0d2                	sd	s4,64(sp)
    80003e5a:	fc56                	sd	s5,56(sp)
    80003e5c:	f85a                	sd	s6,48(sp)
    80003e5e:	f45e                	sd	s7,40(sp)
    80003e60:	f062                	sd	s8,32(sp)
    80003e62:	ec66                	sd	s9,24(sp)
    80003e64:	e86a                	sd	s10,16(sp)
    80003e66:	e46e                	sd	s11,8(sp)
    80003e68:	1880                	addi	s0,sp,112
    80003e6a:	8baa                	mv	s7,a0
    80003e6c:	8c2e                	mv	s8,a1
    80003e6e:	8ab2                	mv	s5,a2
    80003e70:	84b6                	mv	s1,a3
    80003e72:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003e74:	9f35                	addw	a4,a4,a3
    return 0;
    80003e76:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003e78:	0ad76063          	bltu	a4,a3,80003f18 <readi+0xd2>
  if(off + n > ip->size)
    80003e7c:	00e7f463          	bgeu	a5,a4,80003e84 <readi+0x3e>
    n = ip->size - off;
    80003e80:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e84:	0a0b0963          	beqz	s6,80003f36 <readi+0xf0>
    80003e88:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e8a:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003e8e:	5cfd                	li	s9,-1
    80003e90:	a82d                	j	80003eca <readi+0x84>
    80003e92:	020a1d93          	slli	s11,s4,0x20
    80003e96:	020ddd93          	srli	s11,s11,0x20
    80003e9a:	05890613          	addi	a2,s2,88
    80003e9e:	86ee                	mv	a3,s11
    80003ea0:	963a                	add	a2,a2,a4
    80003ea2:	85d6                	mv	a1,s5
    80003ea4:	8562                	mv	a0,s8
    80003ea6:	fffff097          	auipc	ra,0xfffff
    80003eaa:	974080e7          	jalr	-1676(ra) # 8000281a <either_copyout>
    80003eae:	05950d63          	beq	a0,s9,80003f08 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003eb2:	854a                	mv	a0,s2
    80003eb4:	fffff097          	auipc	ra,0xfffff
    80003eb8:	600080e7          	jalr	1536(ra) # 800034b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003ebc:	013a09bb          	addw	s3,s4,s3
    80003ec0:	009a04bb          	addw	s1,s4,s1
    80003ec4:	9aee                	add	s5,s5,s11
    80003ec6:	0569f763          	bgeu	s3,s6,80003f14 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003eca:	000ba903          	lw	s2,0(s7)
    80003ece:	00a4d59b          	srliw	a1,s1,0xa
    80003ed2:	855e                	mv	a0,s7
    80003ed4:	00000097          	auipc	ra,0x0
    80003ed8:	8b0080e7          	jalr	-1872(ra) # 80003784 <bmap>
    80003edc:	0005059b          	sext.w	a1,a0
    80003ee0:	854a                	mv	a0,s2
    80003ee2:	fffff097          	auipc	ra,0xfffff
    80003ee6:	332080e7          	jalr	818(ra) # 80003214 <bread>
    80003eea:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003eec:	3ff4f713          	andi	a4,s1,1023
    80003ef0:	40ed07bb          	subw	a5,s10,a4
    80003ef4:	413b06bb          	subw	a3,s6,s3
    80003ef8:	8a3e                	mv	s4,a5
    80003efa:	2781                	sext.w	a5,a5
    80003efc:	0006861b          	sext.w	a2,a3
    80003f00:	f8f679e3          	bgeu	a2,a5,80003e92 <readi+0x4c>
    80003f04:	8a36                	mv	s4,a3
    80003f06:	b771                	j	80003e92 <readi+0x4c>
      brelse(bp);
    80003f08:	854a                	mv	a0,s2
    80003f0a:	fffff097          	auipc	ra,0xfffff
    80003f0e:	5aa080e7          	jalr	1450(ra) # 800034b4 <brelse>
      tot = -1;
    80003f12:	59fd                	li	s3,-1
  }
  return tot;
    80003f14:	0009851b          	sext.w	a0,s3
}
    80003f18:	70a6                	ld	ra,104(sp)
    80003f1a:	7406                	ld	s0,96(sp)
    80003f1c:	64e6                	ld	s1,88(sp)
    80003f1e:	6946                	ld	s2,80(sp)
    80003f20:	69a6                	ld	s3,72(sp)
    80003f22:	6a06                	ld	s4,64(sp)
    80003f24:	7ae2                	ld	s5,56(sp)
    80003f26:	7b42                	ld	s6,48(sp)
    80003f28:	7ba2                	ld	s7,40(sp)
    80003f2a:	7c02                	ld	s8,32(sp)
    80003f2c:	6ce2                	ld	s9,24(sp)
    80003f2e:	6d42                	ld	s10,16(sp)
    80003f30:	6da2                	ld	s11,8(sp)
    80003f32:	6165                	addi	sp,sp,112
    80003f34:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003f36:	89da                	mv	s3,s6
    80003f38:	bff1                	j	80003f14 <readi+0xce>
    return 0;
    80003f3a:	4501                	li	a0,0
}
    80003f3c:	8082                	ret

0000000080003f3e <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003f3e:	497c                	lw	a5,84(a0)
    80003f40:	10d7e763          	bltu	a5,a3,8000404e <writei+0x110>
{
    80003f44:	7159                	addi	sp,sp,-112
    80003f46:	f486                	sd	ra,104(sp)
    80003f48:	f0a2                	sd	s0,96(sp)
    80003f4a:	eca6                	sd	s1,88(sp)
    80003f4c:	e8ca                	sd	s2,80(sp)
    80003f4e:	e4ce                	sd	s3,72(sp)
    80003f50:	e0d2                	sd	s4,64(sp)
    80003f52:	fc56                	sd	s5,56(sp)
    80003f54:	f85a                	sd	s6,48(sp)
    80003f56:	f45e                	sd	s7,40(sp)
    80003f58:	f062                	sd	s8,32(sp)
    80003f5a:	ec66                	sd	s9,24(sp)
    80003f5c:	e86a                	sd	s10,16(sp)
    80003f5e:	e46e                	sd	s11,8(sp)
    80003f60:	1880                	addi	s0,sp,112
    80003f62:	8baa                	mv	s7,a0
    80003f64:	8c2e                	mv	s8,a1
    80003f66:	8ab2                	mv	s5,a2
    80003f68:	8936                	mv	s2,a3
    80003f6a:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003f6c:	00e687bb          	addw	a5,a3,a4
    80003f70:	0ed7e163          	bltu	a5,a3,80004052 <writei+0x114>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003f74:	00043737          	lui	a4,0x43
    80003f78:	0cf76f63          	bltu	a4,a5,80004056 <writei+0x118>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f7c:	0a0b0863          	beqz	s6,8000402c <writei+0xee>
    80003f80:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f82:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003f86:	5cfd                	li	s9,-1
    80003f88:	a091                	j	80003fcc <writei+0x8e>
    80003f8a:	02099d93          	slli	s11,s3,0x20
    80003f8e:	020ddd93          	srli	s11,s11,0x20
    80003f92:	05848513          	addi	a0,s1,88
    80003f96:	86ee                	mv	a3,s11
    80003f98:	8656                	mv	a2,s5
    80003f9a:	85e2                	mv	a1,s8
    80003f9c:	953a                	add	a0,a0,a4
    80003f9e:	fffff097          	auipc	ra,0xfffff
    80003fa2:	8d2080e7          	jalr	-1838(ra) # 80002870 <either_copyin>
    80003fa6:	07950263          	beq	a0,s9,8000400a <writei+0xcc>
      brelse(bp);
      n = -1;
      break;
    }
    log_write(bp);
    80003faa:	8526                	mv	a0,s1
    80003fac:	00000097          	auipc	ra,0x0
    80003fb0:	78e080e7          	jalr	1934(ra) # 8000473a <log_write>
    brelse(bp);
    80003fb4:	8526                	mv	a0,s1
    80003fb6:	fffff097          	auipc	ra,0xfffff
    80003fba:	4fe080e7          	jalr	1278(ra) # 800034b4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fbe:	01498a3b          	addw	s4,s3,s4
    80003fc2:	0129893b          	addw	s2,s3,s2
    80003fc6:	9aee                	add	s5,s5,s11
    80003fc8:	056a7763          	bgeu	s4,s6,80004016 <writei+0xd8>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003fcc:	000ba483          	lw	s1,0(s7)
    80003fd0:	00a9559b          	srliw	a1,s2,0xa
    80003fd4:	855e                	mv	a0,s7
    80003fd6:	fffff097          	auipc	ra,0xfffff
    80003fda:	7ae080e7          	jalr	1966(ra) # 80003784 <bmap>
    80003fde:	0005059b          	sext.w	a1,a0
    80003fe2:	8526                	mv	a0,s1
    80003fe4:	fffff097          	auipc	ra,0xfffff
    80003fe8:	230080e7          	jalr	560(ra) # 80003214 <bread>
    80003fec:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003fee:	3ff97713          	andi	a4,s2,1023
    80003ff2:	40ed07bb          	subw	a5,s10,a4
    80003ff6:	414b06bb          	subw	a3,s6,s4
    80003ffa:	89be                	mv	s3,a5
    80003ffc:	2781                	sext.w	a5,a5
    80003ffe:	0006861b          	sext.w	a2,a3
    80004002:	f8f674e3          	bgeu	a2,a5,80003f8a <writei+0x4c>
    80004006:	89b6                	mv	s3,a3
    80004008:	b749                	j	80003f8a <writei+0x4c>
      brelse(bp);
    8000400a:	8526                	mv	a0,s1
    8000400c:	fffff097          	auipc	ra,0xfffff
    80004010:	4a8080e7          	jalr	1192(ra) # 800034b4 <brelse>
      n = -1;
    80004014:	5b7d                	li	s6,-1
  }

  if(n > 0){
    if(off > ip->size)
    80004016:	054ba783          	lw	a5,84(s7)
    8000401a:	0127f463          	bgeu	a5,s2,80004022 <writei+0xe4>
      ip->size = off;
    8000401e:	052baa23          	sw	s2,84(s7)
    // write the i-node back to disk even if the size didn't change
    // because the loop above might have called bmap() and added a new
    // block to ip->addrs[].
    iupdate(ip);
    80004022:	855e                	mv	a0,s7
    80004024:	00000097          	auipc	ra,0x0
    80004028:	aa4080e7          	jalr	-1372(ra) # 80003ac8 <iupdate>
  }

  return n;
    8000402c:	000b051b          	sext.w	a0,s6
}
    80004030:	70a6                	ld	ra,104(sp)
    80004032:	7406                	ld	s0,96(sp)
    80004034:	64e6                	ld	s1,88(sp)
    80004036:	6946                	ld	s2,80(sp)
    80004038:	69a6                	ld	s3,72(sp)
    8000403a:	6a06                	ld	s4,64(sp)
    8000403c:	7ae2                	ld	s5,56(sp)
    8000403e:	7b42                	ld	s6,48(sp)
    80004040:	7ba2                	ld	s7,40(sp)
    80004042:	7c02                	ld	s8,32(sp)
    80004044:	6ce2                	ld	s9,24(sp)
    80004046:	6d42                	ld	s10,16(sp)
    80004048:	6da2                	ld	s11,8(sp)
    8000404a:	6165                	addi	sp,sp,112
    8000404c:	8082                	ret
    return -1;
    8000404e:	557d                	li	a0,-1
}
    80004050:	8082                	ret
    return -1;
    80004052:	557d                	li	a0,-1
    80004054:	bff1                	j	80004030 <writei+0xf2>
    return -1;
    80004056:	557d                	li	a0,-1
    80004058:	bfe1                	j	80004030 <writei+0xf2>

000000008000405a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    8000405a:	1141                	addi	sp,sp,-16
    8000405c:	e406                	sd	ra,8(sp)
    8000405e:	e022                	sd	s0,0(sp)
    80004060:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004062:	4639                	li	a2,14
    80004064:	ffffd097          	auipc	ra,0xffffd
    80004068:	1b8080e7          	jalr	440(ra) # 8000121c <strncmp>
}
    8000406c:	60a2                	ld	ra,8(sp)
    8000406e:	6402                	ld	s0,0(sp)
    80004070:	0141                	addi	sp,sp,16
    80004072:	8082                	ret

0000000080004074 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004074:	7139                	addi	sp,sp,-64
    80004076:	fc06                	sd	ra,56(sp)
    80004078:	f822                	sd	s0,48(sp)
    8000407a:	f426                	sd	s1,40(sp)
    8000407c:	f04a                	sd	s2,32(sp)
    8000407e:	ec4e                	sd	s3,24(sp)
    80004080:	e852                	sd	s4,16(sp)
    80004082:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004084:	04c51703          	lh	a4,76(a0)
    80004088:	4785                	li	a5,1
    8000408a:	00f71a63          	bne	a4,a5,8000409e <dirlookup+0x2a>
    8000408e:	892a                	mv	s2,a0
    80004090:	89ae                	mv	s3,a1
    80004092:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004094:	497c                	lw	a5,84(a0)
    80004096:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004098:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000409a:	e79d                	bnez	a5,800040c8 <dirlookup+0x54>
    8000409c:	a8a5                	j	80004114 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000409e:	00004517          	auipc	a0,0x4
    800040a2:	5c250513          	addi	a0,a0,1474 # 80008660 <syscalls+0x1a8>
    800040a6:	ffffc097          	auipc	ra,0xffffc
    800040aa:	4aa080e7          	jalr	1194(ra) # 80000550 <panic>
      panic("dirlookup read");
    800040ae:	00004517          	auipc	a0,0x4
    800040b2:	5ca50513          	addi	a0,a0,1482 # 80008678 <syscalls+0x1c0>
    800040b6:	ffffc097          	auipc	ra,0xffffc
    800040ba:	49a080e7          	jalr	1178(ra) # 80000550 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040be:	24c1                	addiw	s1,s1,16
    800040c0:	05492783          	lw	a5,84(s2)
    800040c4:	04f4f763          	bgeu	s1,a5,80004112 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c8:	4741                	li	a4,16
    800040ca:	86a6                	mv	a3,s1
    800040cc:	fc040613          	addi	a2,s0,-64
    800040d0:	4581                	li	a1,0
    800040d2:	854a                	mv	a0,s2
    800040d4:	00000097          	auipc	ra,0x0
    800040d8:	d72080e7          	jalr	-654(ra) # 80003e46 <readi>
    800040dc:	47c1                	li	a5,16
    800040de:	fcf518e3          	bne	a0,a5,800040ae <dirlookup+0x3a>
    if(de.inum == 0)
    800040e2:	fc045783          	lhu	a5,-64(s0)
    800040e6:	dfe1                	beqz	a5,800040be <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    800040e8:	fc240593          	addi	a1,s0,-62
    800040ec:	854e                	mv	a0,s3
    800040ee:	00000097          	auipc	ra,0x0
    800040f2:	f6c080e7          	jalr	-148(ra) # 8000405a <namecmp>
    800040f6:	f561                	bnez	a0,800040be <dirlookup+0x4a>
      if(poff)
    800040f8:	000a0463          	beqz	s4,80004100 <dirlookup+0x8c>
        *poff = off;
    800040fc:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004100:	fc045583          	lhu	a1,-64(s0)
    80004104:	00092503          	lw	a0,0(s2)
    80004108:	fffff097          	auipc	ra,0xfffff
    8000410c:	756080e7          	jalr	1878(ra) # 8000385e <iget>
    80004110:	a011                	j	80004114 <dirlookup+0xa0>
  return 0;
    80004112:	4501                	li	a0,0
}
    80004114:	70e2                	ld	ra,56(sp)
    80004116:	7442                	ld	s0,48(sp)
    80004118:	74a2                	ld	s1,40(sp)
    8000411a:	7902                	ld	s2,32(sp)
    8000411c:	69e2                	ld	s3,24(sp)
    8000411e:	6a42                	ld	s4,16(sp)
    80004120:	6121                	addi	sp,sp,64
    80004122:	8082                	ret

0000000080004124 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004124:	711d                	addi	sp,sp,-96
    80004126:	ec86                	sd	ra,88(sp)
    80004128:	e8a2                	sd	s0,80(sp)
    8000412a:	e4a6                	sd	s1,72(sp)
    8000412c:	e0ca                	sd	s2,64(sp)
    8000412e:	fc4e                	sd	s3,56(sp)
    80004130:	f852                	sd	s4,48(sp)
    80004132:	f456                	sd	s5,40(sp)
    80004134:	f05a                	sd	s6,32(sp)
    80004136:	ec5e                	sd	s7,24(sp)
    80004138:	e862                	sd	s8,16(sp)
    8000413a:	e466                	sd	s9,8(sp)
    8000413c:	1080                	addi	s0,sp,96
    8000413e:	84aa                	mv	s1,a0
    80004140:	8b2e                	mv	s6,a1
    80004142:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004144:	00054703          	lbu	a4,0(a0)
    80004148:	02f00793          	li	a5,47
    8000414c:	02f70363          	beq	a4,a5,80004172 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004150:	ffffe097          	auipc	ra,0xffffe
    80004154:	c58080e7          	jalr	-936(ra) # 80001da8 <myproc>
    80004158:	15853503          	ld	a0,344(a0)
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	9f8080e7          	jalr	-1544(ra) # 80003b54 <idup>
    80004164:	89aa                	mv	s3,a0
  while(*path == '/')
    80004166:	02f00913          	li	s2,47
  len = path - s;
    8000416a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000416c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000416e:	4c05                	li	s8,1
    80004170:	a865                	j	80004228 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004172:	4585                	li	a1,1
    80004174:	4505                	li	a0,1
    80004176:	fffff097          	auipc	ra,0xfffff
    8000417a:	6e8080e7          	jalr	1768(ra) # 8000385e <iget>
    8000417e:	89aa                	mv	s3,a0
    80004180:	b7dd                	j	80004166 <namex+0x42>
      iunlockput(ip);
    80004182:	854e                	mv	a0,s3
    80004184:	00000097          	auipc	ra,0x0
    80004188:	c70080e7          	jalr	-912(ra) # 80003df4 <iunlockput>
      return 0;
    8000418c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000418e:	854e                	mv	a0,s3
    80004190:	60e6                	ld	ra,88(sp)
    80004192:	6446                	ld	s0,80(sp)
    80004194:	64a6                	ld	s1,72(sp)
    80004196:	6906                	ld	s2,64(sp)
    80004198:	79e2                	ld	s3,56(sp)
    8000419a:	7a42                	ld	s4,48(sp)
    8000419c:	7aa2                	ld	s5,40(sp)
    8000419e:	7b02                	ld	s6,32(sp)
    800041a0:	6be2                	ld	s7,24(sp)
    800041a2:	6c42                	ld	s8,16(sp)
    800041a4:	6ca2                	ld	s9,8(sp)
    800041a6:	6125                	addi	sp,sp,96
    800041a8:	8082                	ret
      iunlock(ip);
    800041aa:	854e                	mv	a0,s3
    800041ac:	00000097          	auipc	ra,0x0
    800041b0:	aa8080e7          	jalr	-1368(ra) # 80003c54 <iunlock>
      return ip;
    800041b4:	bfe9                	j	8000418e <namex+0x6a>
      iunlockput(ip);
    800041b6:	854e                	mv	a0,s3
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	c3c080e7          	jalr	-964(ra) # 80003df4 <iunlockput>
      return 0;
    800041c0:	89d2                	mv	s3,s4
    800041c2:	b7f1                	j	8000418e <namex+0x6a>
  len = path - s;
    800041c4:	40b48633          	sub	a2,s1,a1
    800041c8:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800041cc:	094cd463          	bge	s9,s4,80004254 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800041d0:	4639                	li	a2,14
    800041d2:	8556                	mv	a0,s5
    800041d4:	ffffd097          	auipc	ra,0xffffd
    800041d8:	fcc080e7          	jalr	-52(ra) # 800011a0 <memmove>
  while(*path == '/')
    800041dc:	0004c783          	lbu	a5,0(s1)
    800041e0:	01279763          	bne	a5,s2,800041ee <namex+0xca>
    path++;
    800041e4:	0485                	addi	s1,s1,1
  while(*path == '/')
    800041e6:	0004c783          	lbu	a5,0(s1)
    800041ea:	ff278de3          	beq	a5,s2,800041e4 <namex+0xc0>
    ilock(ip);
    800041ee:	854e                	mv	a0,s3
    800041f0:	00000097          	auipc	ra,0x0
    800041f4:	9a2080e7          	jalr	-1630(ra) # 80003b92 <ilock>
    if(ip->type != T_DIR){
    800041f8:	04c99783          	lh	a5,76(s3)
    800041fc:	f98793e3          	bne	a5,s8,80004182 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004200:	000b0563          	beqz	s6,8000420a <namex+0xe6>
    80004204:	0004c783          	lbu	a5,0(s1)
    80004208:	d3cd                	beqz	a5,800041aa <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    8000420a:	865e                	mv	a2,s7
    8000420c:	85d6                	mv	a1,s5
    8000420e:	854e                	mv	a0,s3
    80004210:	00000097          	auipc	ra,0x0
    80004214:	e64080e7          	jalr	-412(ra) # 80004074 <dirlookup>
    80004218:	8a2a                	mv	s4,a0
    8000421a:	dd51                	beqz	a0,800041b6 <namex+0x92>
    iunlockput(ip);
    8000421c:	854e                	mv	a0,s3
    8000421e:	00000097          	auipc	ra,0x0
    80004222:	bd6080e7          	jalr	-1066(ra) # 80003df4 <iunlockput>
    ip = next;
    80004226:	89d2                	mv	s3,s4
  while(*path == '/')
    80004228:	0004c783          	lbu	a5,0(s1)
    8000422c:	05279763          	bne	a5,s2,8000427a <namex+0x156>
    path++;
    80004230:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004232:	0004c783          	lbu	a5,0(s1)
    80004236:	ff278de3          	beq	a5,s2,80004230 <namex+0x10c>
  if(*path == 0)
    8000423a:	c79d                	beqz	a5,80004268 <namex+0x144>
    path++;
    8000423c:	85a6                	mv	a1,s1
  len = path - s;
    8000423e:	8a5e                	mv	s4,s7
    80004240:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004242:	01278963          	beq	a5,s2,80004254 <namex+0x130>
    80004246:	dfbd                	beqz	a5,800041c4 <namex+0xa0>
    path++;
    80004248:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    8000424a:	0004c783          	lbu	a5,0(s1)
    8000424e:	ff279ce3          	bne	a5,s2,80004246 <namex+0x122>
    80004252:	bf8d                	j	800041c4 <namex+0xa0>
    memmove(name, s, len);
    80004254:	2601                	sext.w	a2,a2
    80004256:	8556                	mv	a0,s5
    80004258:	ffffd097          	auipc	ra,0xffffd
    8000425c:	f48080e7          	jalr	-184(ra) # 800011a0 <memmove>
    name[len] = 0;
    80004260:	9a56                	add	s4,s4,s5
    80004262:	000a0023          	sb	zero,0(s4)
    80004266:	bf9d                	j	800041dc <namex+0xb8>
  if(nameiparent){
    80004268:	f20b03e3          	beqz	s6,8000418e <namex+0x6a>
    iput(ip);
    8000426c:	854e                	mv	a0,s3
    8000426e:	00000097          	auipc	ra,0x0
    80004272:	ade080e7          	jalr	-1314(ra) # 80003d4c <iput>
    return 0;
    80004276:	4981                	li	s3,0
    80004278:	bf19                	j	8000418e <namex+0x6a>
  if(*path == 0)
    8000427a:	d7fd                	beqz	a5,80004268 <namex+0x144>
  while(*path != '/' && *path != 0)
    8000427c:	0004c783          	lbu	a5,0(s1)
    80004280:	85a6                	mv	a1,s1
    80004282:	b7d1                	j	80004246 <namex+0x122>

0000000080004284 <dirlink>:
{
    80004284:	7139                	addi	sp,sp,-64
    80004286:	fc06                	sd	ra,56(sp)
    80004288:	f822                	sd	s0,48(sp)
    8000428a:	f426                	sd	s1,40(sp)
    8000428c:	f04a                	sd	s2,32(sp)
    8000428e:	ec4e                	sd	s3,24(sp)
    80004290:	e852                	sd	s4,16(sp)
    80004292:	0080                	addi	s0,sp,64
    80004294:	892a                	mv	s2,a0
    80004296:	8a2e                	mv	s4,a1
    80004298:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    8000429a:	4601                	li	a2,0
    8000429c:	00000097          	auipc	ra,0x0
    800042a0:	dd8080e7          	jalr	-552(ra) # 80004074 <dirlookup>
    800042a4:	e93d                	bnez	a0,8000431a <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042a6:	05492483          	lw	s1,84(s2)
    800042aa:	c49d                	beqz	s1,800042d8 <dirlink+0x54>
    800042ac:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ae:	4741                	li	a4,16
    800042b0:	86a6                	mv	a3,s1
    800042b2:	fc040613          	addi	a2,s0,-64
    800042b6:	4581                	li	a1,0
    800042b8:	854a                	mv	a0,s2
    800042ba:	00000097          	auipc	ra,0x0
    800042be:	b8c080e7          	jalr	-1140(ra) # 80003e46 <readi>
    800042c2:	47c1                	li	a5,16
    800042c4:	06f51163          	bne	a0,a5,80004326 <dirlink+0xa2>
    if(de.inum == 0)
    800042c8:	fc045783          	lhu	a5,-64(s0)
    800042cc:	c791                	beqz	a5,800042d8 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800042ce:	24c1                	addiw	s1,s1,16
    800042d0:	05492783          	lw	a5,84(s2)
    800042d4:	fcf4ede3          	bltu	s1,a5,800042ae <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800042d8:	4639                	li	a2,14
    800042da:	85d2                	mv	a1,s4
    800042dc:	fc240513          	addi	a0,s0,-62
    800042e0:	ffffd097          	auipc	ra,0xffffd
    800042e4:	f78080e7          	jalr	-136(ra) # 80001258 <strncpy>
  de.inum = inum;
    800042e8:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800042ec:	4741                	li	a4,16
    800042ee:	86a6                	mv	a3,s1
    800042f0:	fc040613          	addi	a2,s0,-64
    800042f4:	4581                	li	a1,0
    800042f6:	854a                	mv	a0,s2
    800042f8:	00000097          	auipc	ra,0x0
    800042fc:	c46080e7          	jalr	-954(ra) # 80003f3e <writei>
    80004300:	872a                	mv	a4,a0
    80004302:	47c1                	li	a5,16
  return 0;
    80004304:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004306:	02f71863          	bne	a4,a5,80004336 <dirlink+0xb2>
}
    8000430a:	70e2                	ld	ra,56(sp)
    8000430c:	7442                	ld	s0,48(sp)
    8000430e:	74a2                	ld	s1,40(sp)
    80004310:	7902                	ld	s2,32(sp)
    80004312:	69e2                	ld	s3,24(sp)
    80004314:	6a42                	ld	s4,16(sp)
    80004316:	6121                	addi	sp,sp,64
    80004318:	8082                	ret
    iput(ip);
    8000431a:	00000097          	auipc	ra,0x0
    8000431e:	a32080e7          	jalr	-1486(ra) # 80003d4c <iput>
    return -1;
    80004322:	557d                	li	a0,-1
    80004324:	b7dd                	j	8000430a <dirlink+0x86>
      panic("dirlink read");
    80004326:	00004517          	auipc	a0,0x4
    8000432a:	36250513          	addi	a0,a0,866 # 80008688 <syscalls+0x1d0>
    8000432e:	ffffc097          	auipc	ra,0xffffc
    80004332:	222080e7          	jalr	546(ra) # 80000550 <panic>
    panic("dirlink");
    80004336:	00004517          	auipc	a0,0x4
    8000433a:	47250513          	addi	a0,a0,1138 # 800087a8 <syscalls+0x2f0>
    8000433e:	ffffc097          	auipc	ra,0xffffc
    80004342:	212080e7          	jalr	530(ra) # 80000550 <panic>

0000000080004346 <namei>:

struct inode*
namei(char *path)
{
    80004346:	1101                	addi	sp,sp,-32
    80004348:	ec06                	sd	ra,24(sp)
    8000434a:	e822                	sd	s0,16(sp)
    8000434c:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000434e:	fe040613          	addi	a2,s0,-32
    80004352:	4581                	li	a1,0
    80004354:	00000097          	auipc	ra,0x0
    80004358:	dd0080e7          	jalr	-560(ra) # 80004124 <namex>
}
    8000435c:	60e2                	ld	ra,24(sp)
    8000435e:	6442                	ld	s0,16(sp)
    80004360:	6105                	addi	sp,sp,32
    80004362:	8082                	ret

0000000080004364 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004364:	1141                	addi	sp,sp,-16
    80004366:	e406                	sd	ra,8(sp)
    80004368:	e022                	sd	s0,0(sp)
    8000436a:	0800                	addi	s0,sp,16
    8000436c:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000436e:	4585                	li	a1,1
    80004370:	00000097          	auipc	ra,0x0
    80004374:	db4080e7          	jalr	-588(ra) # 80004124 <namex>
}
    80004378:	60a2                	ld	ra,8(sp)
    8000437a:	6402                	ld	s0,0(sp)
    8000437c:	0141                	addi	sp,sp,16
    8000437e:	8082                	ret

0000000080004380 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004380:	1101                	addi	sp,sp,-32
    80004382:	ec06                	sd	ra,24(sp)
    80004384:	e822                	sd	s0,16(sp)
    80004386:	e426                	sd	s1,8(sp)
    80004388:	e04a                	sd	s2,0(sp)
    8000438a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    8000438c:	0001e917          	auipc	s2,0x1e
    80004390:	4d490913          	addi	s2,s2,1236 # 80022860 <log>
    80004394:	02092583          	lw	a1,32(s2)
    80004398:	03092503          	lw	a0,48(s2)
    8000439c:	fffff097          	auipc	ra,0xfffff
    800043a0:	e78080e7          	jalr	-392(ra) # 80003214 <bread>
    800043a4:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800043a6:	03492683          	lw	a3,52(s2)
    800043aa:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800043ac:	02d05763          	blez	a3,800043da <write_head+0x5a>
    800043b0:	0001e797          	auipc	a5,0x1e
    800043b4:	4e878793          	addi	a5,a5,1256 # 80022898 <log+0x38>
    800043b8:	05c50713          	addi	a4,a0,92
    800043bc:	36fd                	addiw	a3,a3,-1
    800043be:	1682                	slli	a3,a3,0x20
    800043c0:	9281                	srli	a3,a3,0x20
    800043c2:	068a                	slli	a3,a3,0x2
    800043c4:	0001e617          	auipc	a2,0x1e
    800043c8:	4d860613          	addi	a2,a2,1240 # 8002289c <log+0x3c>
    800043cc:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800043ce:	4390                	lw	a2,0(a5)
    800043d0:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800043d2:	0791                	addi	a5,a5,4
    800043d4:	0711                	addi	a4,a4,4
    800043d6:	fed79ce3          	bne	a5,a3,800043ce <write_head+0x4e>
  }
  bwrite(buf);
    800043da:	8526                	mv	a0,s1
    800043dc:	fffff097          	auipc	ra,0xfffff
    800043e0:	09a080e7          	jalr	154(ra) # 80003476 <bwrite>
  brelse(buf);
    800043e4:	8526                	mv	a0,s1
    800043e6:	fffff097          	auipc	ra,0xfffff
    800043ea:	0ce080e7          	jalr	206(ra) # 800034b4 <brelse>
}
    800043ee:	60e2                	ld	ra,24(sp)
    800043f0:	6442                	ld	s0,16(sp)
    800043f2:	64a2                	ld	s1,8(sp)
    800043f4:	6902                	ld	s2,0(sp)
    800043f6:	6105                	addi	sp,sp,32
    800043f8:	8082                	ret

00000000800043fa <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    800043fa:	0001e797          	auipc	a5,0x1e
    800043fe:	49a7a783          	lw	a5,1178(a5) # 80022894 <log+0x34>
    80004402:	0af05d63          	blez	a5,800044bc <install_trans+0xc2>
{
    80004406:	7139                	addi	sp,sp,-64
    80004408:	fc06                	sd	ra,56(sp)
    8000440a:	f822                	sd	s0,48(sp)
    8000440c:	f426                	sd	s1,40(sp)
    8000440e:	f04a                	sd	s2,32(sp)
    80004410:	ec4e                	sd	s3,24(sp)
    80004412:	e852                	sd	s4,16(sp)
    80004414:	e456                	sd	s5,8(sp)
    80004416:	e05a                	sd	s6,0(sp)
    80004418:	0080                	addi	s0,sp,64
    8000441a:	8b2a                	mv	s6,a0
    8000441c:	0001ea97          	auipc	s5,0x1e
    80004420:	47ca8a93          	addi	s5,s5,1148 # 80022898 <log+0x38>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004424:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004426:	0001e997          	auipc	s3,0x1e
    8000442a:	43a98993          	addi	s3,s3,1082 # 80022860 <log>
    8000442e:	a035                	j	8000445a <install_trans+0x60>
      bunpin(dbuf);
    80004430:	8526                	mv	a0,s1
    80004432:	fffff097          	auipc	ra,0xfffff
    80004436:	158080e7          	jalr	344(ra) # 8000358a <bunpin>
    brelse(lbuf);
    8000443a:	854a                	mv	a0,s2
    8000443c:	fffff097          	auipc	ra,0xfffff
    80004440:	078080e7          	jalr	120(ra) # 800034b4 <brelse>
    brelse(dbuf);
    80004444:	8526                	mv	a0,s1
    80004446:	fffff097          	auipc	ra,0xfffff
    8000444a:	06e080e7          	jalr	110(ra) # 800034b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000444e:	2a05                	addiw	s4,s4,1
    80004450:	0a91                	addi	s5,s5,4
    80004452:	0349a783          	lw	a5,52(s3)
    80004456:	04fa5963          	bge	s4,a5,800044a8 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000445a:	0209a583          	lw	a1,32(s3)
    8000445e:	014585bb          	addw	a1,a1,s4
    80004462:	2585                	addiw	a1,a1,1
    80004464:	0309a503          	lw	a0,48(s3)
    80004468:	fffff097          	auipc	ra,0xfffff
    8000446c:	dac080e7          	jalr	-596(ra) # 80003214 <bread>
    80004470:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004472:	000aa583          	lw	a1,0(s5)
    80004476:	0309a503          	lw	a0,48(s3)
    8000447a:	fffff097          	auipc	ra,0xfffff
    8000447e:	d9a080e7          	jalr	-614(ra) # 80003214 <bread>
    80004482:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004484:	40000613          	li	a2,1024
    80004488:	05890593          	addi	a1,s2,88
    8000448c:	05850513          	addi	a0,a0,88
    80004490:	ffffd097          	auipc	ra,0xffffd
    80004494:	d10080e7          	jalr	-752(ra) # 800011a0 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004498:	8526                	mv	a0,s1
    8000449a:	fffff097          	auipc	ra,0xfffff
    8000449e:	fdc080e7          	jalr	-36(ra) # 80003476 <bwrite>
    if(recovering == 0)
    800044a2:	f80b1ce3          	bnez	s6,8000443a <install_trans+0x40>
    800044a6:	b769                	j	80004430 <install_trans+0x36>
}
    800044a8:	70e2                	ld	ra,56(sp)
    800044aa:	7442                	ld	s0,48(sp)
    800044ac:	74a2                	ld	s1,40(sp)
    800044ae:	7902                	ld	s2,32(sp)
    800044b0:	69e2                	ld	s3,24(sp)
    800044b2:	6a42                	ld	s4,16(sp)
    800044b4:	6aa2                	ld	s5,8(sp)
    800044b6:	6b02                	ld	s6,0(sp)
    800044b8:	6121                	addi	sp,sp,64
    800044ba:	8082                	ret
    800044bc:	8082                	ret

00000000800044be <initlog>:
{
    800044be:	7179                	addi	sp,sp,-48
    800044c0:	f406                	sd	ra,40(sp)
    800044c2:	f022                	sd	s0,32(sp)
    800044c4:	ec26                	sd	s1,24(sp)
    800044c6:	e84a                	sd	s2,16(sp)
    800044c8:	e44e                	sd	s3,8(sp)
    800044ca:	1800                	addi	s0,sp,48
    800044cc:	892a                	mv	s2,a0
    800044ce:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800044d0:	0001e497          	auipc	s1,0x1e
    800044d4:	39048493          	addi	s1,s1,912 # 80022860 <log>
    800044d8:	00004597          	auipc	a1,0x4
    800044dc:	1c058593          	addi	a1,a1,448 # 80008698 <syscalls+0x1e0>
    800044e0:	8526                	mv	a0,s1
    800044e2:	ffffd097          	auipc	ra,0xffffd
    800044e6:	9fa080e7          	jalr	-1542(ra) # 80000edc <initlock>
  log.start = sb->logstart;
    800044ea:	0149a583          	lw	a1,20(s3)
    800044ee:	d08c                	sw	a1,32(s1)
  log.size = sb->nlog;
    800044f0:	0109a783          	lw	a5,16(s3)
    800044f4:	d0dc                	sw	a5,36(s1)
  log.dev = dev;
    800044f6:	0324a823          	sw	s2,48(s1)
  struct buf *buf = bread(log.dev, log.start);
    800044fa:	854a                	mv	a0,s2
    800044fc:	fffff097          	auipc	ra,0xfffff
    80004500:	d18080e7          	jalr	-744(ra) # 80003214 <bread>
  log.lh.n = lh->n;
    80004504:	4d3c                	lw	a5,88(a0)
    80004506:	d8dc                	sw	a5,52(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004508:	02f05563          	blez	a5,80004532 <initlog+0x74>
    8000450c:	05c50713          	addi	a4,a0,92
    80004510:	0001e697          	auipc	a3,0x1e
    80004514:	38868693          	addi	a3,a3,904 # 80022898 <log+0x38>
    80004518:	37fd                	addiw	a5,a5,-1
    8000451a:	1782                	slli	a5,a5,0x20
    8000451c:	9381                	srli	a5,a5,0x20
    8000451e:	078a                	slli	a5,a5,0x2
    80004520:	06050613          	addi	a2,a0,96
    80004524:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004526:	4310                	lw	a2,0(a4)
    80004528:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    8000452a:	0711                	addi	a4,a4,4
    8000452c:	0691                	addi	a3,a3,4
    8000452e:	fef71ce3          	bne	a4,a5,80004526 <initlog+0x68>
  brelse(buf);
    80004532:	fffff097          	auipc	ra,0xfffff
    80004536:	f82080e7          	jalr	-126(ra) # 800034b4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    8000453a:	4505                	li	a0,1
    8000453c:	00000097          	auipc	ra,0x0
    80004540:	ebe080e7          	jalr	-322(ra) # 800043fa <install_trans>
  log.lh.n = 0;
    80004544:	0001e797          	auipc	a5,0x1e
    80004548:	3407a823          	sw	zero,848(a5) # 80022894 <log+0x34>
  write_head(); // clear the log
    8000454c:	00000097          	auipc	ra,0x0
    80004550:	e34080e7          	jalr	-460(ra) # 80004380 <write_head>
}
    80004554:	70a2                	ld	ra,40(sp)
    80004556:	7402                	ld	s0,32(sp)
    80004558:	64e2                	ld	s1,24(sp)
    8000455a:	6942                	ld	s2,16(sp)
    8000455c:	69a2                	ld	s3,8(sp)
    8000455e:	6145                	addi	sp,sp,48
    80004560:	8082                	ret

0000000080004562 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004562:	1101                	addi	sp,sp,-32
    80004564:	ec06                	sd	ra,24(sp)
    80004566:	e822                	sd	s0,16(sp)
    80004568:	e426                	sd	s1,8(sp)
    8000456a:	e04a                	sd	s2,0(sp)
    8000456c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000456e:	0001e517          	auipc	a0,0x1e
    80004572:	2f250513          	addi	a0,a0,754 # 80022860 <log>
    80004576:	ffffc097          	auipc	ra,0xffffc
    8000457a:	7ea080e7          	jalr	2026(ra) # 80000d60 <acquire>
  while(1){
    if(log.committing){
    8000457e:	0001e497          	auipc	s1,0x1e
    80004582:	2e248493          	addi	s1,s1,738 # 80022860 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004586:	4979                	li	s2,30
    80004588:	a039                	j	80004596 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000458a:	85a6                	mv	a1,s1
    8000458c:	8526                	mv	a0,s1
    8000458e:	ffffe097          	auipc	ra,0xffffe
    80004592:	02a080e7          	jalr	42(ra) # 800025b8 <sleep>
    if(log.committing){
    80004596:	54dc                	lw	a5,44(s1)
    80004598:	fbed                	bnez	a5,8000458a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000459a:	549c                	lw	a5,40(s1)
    8000459c:	0017871b          	addiw	a4,a5,1
    800045a0:	0007069b          	sext.w	a3,a4
    800045a4:	0027179b          	slliw	a5,a4,0x2
    800045a8:	9fb9                	addw	a5,a5,a4
    800045aa:	0017979b          	slliw	a5,a5,0x1
    800045ae:	58d8                	lw	a4,52(s1)
    800045b0:	9fb9                	addw	a5,a5,a4
    800045b2:	00f95963          	bge	s2,a5,800045c4 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800045b6:	85a6                	mv	a1,s1
    800045b8:	8526                	mv	a0,s1
    800045ba:	ffffe097          	auipc	ra,0xffffe
    800045be:	ffe080e7          	jalr	-2(ra) # 800025b8 <sleep>
    800045c2:	bfd1                	j	80004596 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800045c4:	0001e517          	auipc	a0,0x1e
    800045c8:	29c50513          	addi	a0,a0,668 # 80022860 <log>
    800045cc:	d514                	sw	a3,40(a0)
      release(&log.lock);
    800045ce:	ffffd097          	auipc	ra,0xffffd
    800045d2:	862080e7          	jalr	-1950(ra) # 80000e30 <release>
      break;
    }
  }
}
    800045d6:	60e2                	ld	ra,24(sp)
    800045d8:	6442                	ld	s0,16(sp)
    800045da:	64a2                	ld	s1,8(sp)
    800045dc:	6902                	ld	s2,0(sp)
    800045de:	6105                	addi	sp,sp,32
    800045e0:	8082                	ret

00000000800045e2 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800045e2:	7139                	addi	sp,sp,-64
    800045e4:	fc06                	sd	ra,56(sp)
    800045e6:	f822                	sd	s0,48(sp)
    800045e8:	f426                	sd	s1,40(sp)
    800045ea:	f04a                	sd	s2,32(sp)
    800045ec:	ec4e                	sd	s3,24(sp)
    800045ee:	e852                	sd	s4,16(sp)
    800045f0:	e456                	sd	s5,8(sp)
    800045f2:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800045f4:	0001e497          	auipc	s1,0x1e
    800045f8:	26c48493          	addi	s1,s1,620 # 80022860 <log>
    800045fc:	8526                	mv	a0,s1
    800045fe:	ffffc097          	auipc	ra,0xffffc
    80004602:	762080e7          	jalr	1890(ra) # 80000d60 <acquire>
  log.outstanding -= 1;
    80004606:	549c                	lw	a5,40(s1)
    80004608:	37fd                	addiw	a5,a5,-1
    8000460a:	0007891b          	sext.w	s2,a5
    8000460e:	d49c                	sw	a5,40(s1)
  if(log.committing)
    80004610:	54dc                	lw	a5,44(s1)
    80004612:	efb9                	bnez	a5,80004670 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004614:	06091663          	bnez	s2,80004680 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004618:	0001e497          	auipc	s1,0x1e
    8000461c:	24848493          	addi	s1,s1,584 # 80022860 <log>
    80004620:	4785                	li	a5,1
    80004622:	d4dc                	sw	a5,44(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004624:	8526                	mv	a0,s1
    80004626:	ffffd097          	auipc	ra,0xffffd
    8000462a:	80a080e7          	jalr	-2038(ra) # 80000e30 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000462e:	58dc                	lw	a5,52(s1)
    80004630:	06f04763          	bgtz	a5,8000469e <end_op+0xbc>
    acquire(&log.lock);
    80004634:	0001e497          	auipc	s1,0x1e
    80004638:	22c48493          	addi	s1,s1,556 # 80022860 <log>
    8000463c:	8526                	mv	a0,s1
    8000463e:	ffffc097          	auipc	ra,0xffffc
    80004642:	722080e7          	jalr	1826(ra) # 80000d60 <acquire>
    log.committing = 0;
    80004646:	0204a623          	sw	zero,44(s1)
    wakeup(&log);
    8000464a:	8526                	mv	a0,s1
    8000464c:	ffffe097          	auipc	ra,0xffffe
    80004650:	0f2080e7          	jalr	242(ra) # 8000273e <wakeup>
    release(&log.lock);
    80004654:	8526                	mv	a0,s1
    80004656:	ffffc097          	auipc	ra,0xffffc
    8000465a:	7da080e7          	jalr	2010(ra) # 80000e30 <release>
}
    8000465e:	70e2                	ld	ra,56(sp)
    80004660:	7442                	ld	s0,48(sp)
    80004662:	74a2                	ld	s1,40(sp)
    80004664:	7902                	ld	s2,32(sp)
    80004666:	69e2                	ld	s3,24(sp)
    80004668:	6a42                	ld	s4,16(sp)
    8000466a:	6aa2                	ld	s5,8(sp)
    8000466c:	6121                	addi	sp,sp,64
    8000466e:	8082                	ret
    panic("log.committing");
    80004670:	00004517          	auipc	a0,0x4
    80004674:	03050513          	addi	a0,a0,48 # 800086a0 <syscalls+0x1e8>
    80004678:	ffffc097          	auipc	ra,0xffffc
    8000467c:	ed8080e7          	jalr	-296(ra) # 80000550 <panic>
    wakeup(&log);
    80004680:	0001e497          	auipc	s1,0x1e
    80004684:	1e048493          	addi	s1,s1,480 # 80022860 <log>
    80004688:	8526                	mv	a0,s1
    8000468a:	ffffe097          	auipc	ra,0xffffe
    8000468e:	0b4080e7          	jalr	180(ra) # 8000273e <wakeup>
  release(&log.lock);
    80004692:	8526                	mv	a0,s1
    80004694:	ffffc097          	auipc	ra,0xffffc
    80004698:	79c080e7          	jalr	1948(ra) # 80000e30 <release>
  if(do_commit){
    8000469c:	b7c9                	j	8000465e <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000469e:	0001ea97          	auipc	s5,0x1e
    800046a2:	1faa8a93          	addi	s5,s5,506 # 80022898 <log+0x38>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800046a6:	0001ea17          	auipc	s4,0x1e
    800046aa:	1baa0a13          	addi	s4,s4,442 # 80022860 <log>
    800046ae:	020a2583          	lw	a1,32(s4)
    800046b2:	012585bb          	addw	a1,a1,s2
    800046b6:	2585                	addiw	a1,a1,1
    800046b8:	030a2503          	lw	a0,48(s4)
    800046bc:	fffff097          	auipc	ra,0xfffff
    800046c0:	b58080e7          	jalr	-1192(ra) # 80003214 <bread>
    800046c4:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800046c6:	000aa583          	lw	a1,0(s5)
    800046ca:	030a2503          	lw	a0,48(s4)
    800046ce:	fffff097          	auipc	ra,0xfffff
    800046d2:	b46080e7          	jalr	-1210(ra) # 80003214 <bread>
    800046d6:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800046d8:	40000613          	li	a2,1024
    800046dc:	05850593          	addi	a1,a0,88
    800046e0:	05848513          	addi	a0,s1,88
    800046e4:	ffffd097          	auipc	ra,0xffffd
    800046e8:	abc080e7          	jalr	-1348(ra) # 800011a0 <memmove>
    bwrite(to);  // write the log
    800046ec:	8526                	mv	a0,s1
    800046ee:	fffff097          	auipc	ra,0xfffff
    800046f2:	d88080e7          	jalr	-632(ra) # 80003476 <bwrite>
    brelse(from);
    800046f6:	854e                	mv	a0,s3
    800046f8:	fffff097          	auipc	ra,0xfffff
    800046fc:	dbc080e7          	jalr	-580(ra) # 800034b4 <brelse>
    brelse(to);
    80004700:	8526                	mv	a0,s1
    80004702:	fffff097          	auipc	ra,0xfffff
    80004706:	db2080e7          	jalr	-590(ra) # 800034b4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000470a:	2905                	addiw	s2,s2,1
    8000470c:	0a91                	addi	s5,s5,4
    8000470e:	034a2783          	lw	a5,52(s4)
    80004712:	f8f94ee3          	blt	s2,a5,800046ae <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004716:	00000097          	auipc	ra,0x0
    8000471a:	c6a080e7          	jalr	-918(ra) # 80004380 <write_head>
    install_trans(0); // Now install writes to home locations
    8000471e:	4501                	li	a0,0
    80004720:	00000097          	auipc	ra,0x0
    80004724:	cda080e7          	jalr	-806(ra) # 800043fa <install_trans>
    log.lh.n = 0;
    80004728:	0001e797          	auipc	a5,0x1e
    8000472c:	1607a623          	sw	zero,364(a5) # 80022894 <log+0x34>
    write_head();    // Erase the transaction from the log
    80004730:	00000097          	auipc	ra,0x0
    80004734:	c50080e7          	jalr	-944(ra) # 80004380 <write_head>
    80004738:	bdf5                	j	80004634 <end_op+0x52>

000000008000473a <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    8000473a:	1101                	addi	sp,sp,-32
    8000473c:	ec06                	sd	ra,24(sp)
    8000473e:	e822                	sd	s0,16(sp)
    80004740:	e426                	sd	s1,8(sp)
    80004742:	e04a                	sd	s2,0(sp)
    80004744:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004746:	0001e717          	auipc	a4,0x1e
    8000474a:	14e72703          	lw	a4,334(a4) # 80022894 <log+0x34>
    8000474e:	47f5                	li	a5,29
    80004750:	08e7c063          	blt	a5,a4,800047d0 <log_write+0x96>
    80004754:	84aa                	mv	s1,a0
    80004756:	0001e797          	auipc	a5,0x1e
    8000475a:	12e7a783          	lw	a5,302(a5) # 80022884 <log+0x24>
    8000475e:	37fd                	addiw	a5,a5,-1
    80004760:	06f75863          	bge	a4,a5,800047d0 <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004764:	0001e797          	auipc	a5,0x1e
    80004768:	1247a783          	lw	a5,292(a5) # 80022888 <log+0x28>
    8000476c:	06f05a63          	blez	a5,800047e0 <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004770:	0001e917          	auipc	s2,0x1e
    80004774:	0f090913          	addi	s2,s2,240 # 80022860 <log>
    80004778:	854a                	mv	a0,s2
    8000477a:	ffffc097          	auipc	ra,0xffffc
    8000477e:	5e6080e7          	jalr	1510(ra) # 80000d60 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004782:	03492603          	lw	a2,52(s2)
    80004786:	06c05563          	blez	a2,800047f0 <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    8000478a:	44cc                	lw	a1,12(s1)
    8000478c:	0001e717          	auipc	a4,0x1e
    80004790:	10c70713          	addi	a4,a4,268 # 80022898 <log+0x38>
  for (i = 0; i < log.lh.n; i++) {
    80004794:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004796:	4314                	lw	a3,0(a4)
    80004798:	04b68d63          	beq	a3,a1,800047f2 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    8000479c:	2785                	addiw	a5,a5,1
    8000479e:	0711                	addi	a4,a4,4
    800047a0:	fec79be3          	bne	a5,a2,80004796 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    800047a4:	0631                	addi	a2,a2,12
    800047a6:	060a                	slli	a2,a2,0x2
    800047a8:	0001e797          	auipc	a5,0x1e
    800047ac:	0b878793          	addi	a5,a5,184 # 80022860 <log>
    800047b0:	963e                	add	a2,a2,a5
    800047b2:	44dc                	lw	a5,12(s1)
    800047b4:	c61c                	sw	a5,8(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800047b6:	8526                	mv	a0,s1
    800047b8:	fffff097          	auipc	ra,0xfffff
    800047bc:	d86080e7          	jalr	-634(ra) # 8000353e <bpin>
    log.lh.n++;
    800047c0:	0001e717          	auipc	a4,0x1e
    800047c4:	0a070713          	addi	a4,a4,160 # 80022860 <log>
    800047c8:	5b5c                	lw	a5,52(a4)
    800047ca:	2785                	addiw	a5,a5,1
    800047cc:	db5c                	sw	a5,52(a4)
    800047ce:	a83d                	j	8000480c <log_write+0xd2>
    panic("too big a transaction");
    800047d0:	00004517          	auipc	a0,0x4
    800047d4:	ee050513          	addi	a0,a0,-288 # 800086b0 <syscalls+0x1f8>
    800047d8:	ffffc097          	auipc	ra,0xffffc
    800047dc:	d78080e7          	jalr	-648(ra) # 80000550 <panic>
    panic("log_write outside of trans");
    800047e0:	00004517          	auipc	a0,0x4
    800047e4:	ee850513          	addi	a0,a0,-280 # 800086c8 <syscalls+0x210>
    800047e8:	ffffc097          	auipc	ra,0xffffc
    800047ec:	d68080e7          	jalr	-664(ra) # 80000550 <panic>
  for (i = 0; i < log.lh.n; i++) {
    800047f0:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    800047f2:	00c78713          	addi	a4,a5,12
    800047f6:	00271693          	slli	a3,a4,0x2
    800047fa:	0001e717          	auipc	a4,0x1e
    800047fe:	06670713          	addi	a4,a4,102 # 80022860 <log>
    80004802:	9736                	add	a4,a4,a3
    80004804:	44d4                	lw	a3,12(s1)
    80004806:	c714                	sw	a3,8(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004808:	faf607e3          	beq	a2,a5,800047b6 <log_write+0x7c>
  }
  release(&log.lock);
    8000480c:	0001e517          	auipc	a0,0x1e
    80004810:	05450513          	addi	a0,a0,84 # 80022860 <log>
    80004814:	ffffc097          	auipc	ra,0xffffc
    80004818:	61c080e7          	jalr	1564(ra) # 80000e30 <release>
}
    8000481c:	60e2                	ld	ra,24(sp)
    8000481e:	6442                	ld	s0,16(sp)
    80004820:	64a2                	ld	s1,8(sp)
    80004822:	6902                	ld	s2,0(sp)
    80004824:	6105                	addi	sp,sp,32
    80004826:	8082                	ret

0000000080004828 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004828:	1101                	addi	sp,sp,-32
    8000482a:	ec06                	sd	ra,24(sp)
    8000482c:	e822                	sd	s0,16(sp)
    8000482e:	e426                	sd	s1,8(sp)
    80004830:	e04a                	sd	s2,0(sp)
    80004832:	1000                	addi	s0,sp,32
    80004834:	84aa                	mv	s1,a0
    80004836:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004838:	00004597          	auipc	a1,0x4
    8000483c:	eb058593          	addi	a1,a1,-336 # 800086e8 <syscalls+0x230>
    80004840:	0521                	addi	a0,a0,8
    80004842:	ffffc097          	auipc	ra,0xffffc
    80004846:	69a080e7          	jalr	1690(ra) # 80000edc <initlock>
  lk->name = name;
    8000484a:	0324b423          	sd	s2,40(s1)
  lk->locked = 0;
    8000484e:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004852:	0204a823          	sw	zero,48(s1)
}
    80004856:	60e2                	ld	ra,24(sp)
    80004858:	6442                	ld	s0,16(sp)
    8000485a:	64a2                	ld	s1,8(sp)
    8000485c:	6902                	ld	s2,0(sp)
    8000485e:	6105                	addi	sp,sp,32
    80004860:	8082                	ret

0000000080004862 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004862:	1101                	addi	sp,sp,-32
    80004864:	ec06                	sd	ra,24(sp)
    80004866:	e822                	sd	s0,16(sp)
    80004868:	e426                	sd	s1,8(sp)
    8000486a:	e04a                	sd	s2,0(sp)
    8000486c:	1000                	addi	s0,sp,32
    8000486e:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004870:	00850913          	addi	s2,a0,8
    80004874:	854a                	mv	a0,s2
    80004876:	ffffc097          	auipc	ra,0xffffc
    8000487a:	4ea080e7          	jalr	1258(ra) # 80000d60 <acquire>
  while (lk->locked) {
    8000487e:	409c                	lw	a5,0(s1)
    80004880:	cb89                	beqz	a5,80004892 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004882:	85ca                	mv	a1,s2
    80004884:	8526                	mv	a0,s1
    80004886:	ffffe097          	auipc	ra,0xffffe
    8000488a:	d32080e7          	jalr	-718(ra) # 800025b8 <sleep>
  while (lk->locked) {
    8000488e:	409c                	lw	a5,0(s1)
    80004890:	fbed                	bnez	a5,80004882 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004892:	4785                	li	a5,1
    80004894:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004896:	ffffd097          	auipc	ra,0xffffd
    8000489a:	512080e7          	jalr	1298(ra) # 80001da8 <myproc>
    8000489e:	413c                	lw	a5,64(a0)
    800048a0:	d89c                	sw	a5,48(s1)
  release(&lk->lk);
    800048a2:	854a                	mv	a0,s2
    800048a4:	ffffc097          	auipc	ra,0xffffc
    800048a8:	58c080e7          	jalr	1420(ra) # 80000e30 <release>
}
    800048ac:	60e2                	ld	ra,24(sp)
    800048ae:	6442                	ld	s0,16(sp)
    800048b0:	64a2                	ld	s1,8(sp)
    800048b2:	6902                	ld	s2,0(sp)
    800048b4:	6105                	addi	sp,sp,32
    800048b6:	8082                	ret

00000000800048b8 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800048b8:	1101                	addi	sp,sp,-32
    800048ba:	ec06                	sd	ra,24(sp)
    800048bc:	e822                	sd	s0,16(sp)
    800048be:	e426                	sd	s1,8(sp)
    800048c0:	e04a                	sd	s2,0(sp)
    800048c2:	1000                	addi	s0,sp,32
    800048c4:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800048c6:	00850913          	addi	s2,a0,8
    800048ca:	854a                	mv	a0,s2
    800048cc:	ffffc097          	auipc	ra,0xffffc
    800048d0:	494080e7          	jalr	1172(ra) # 80000d60 <acquire>
  lk->locked = 0;
    800048d4:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800048d8:	0204a823          	sw	zero,48(s1)
  wakeup(lk);
    800048dc:	8526                	mv	a0,s1
    800048de:	ffffe097          	auipc	ra,0xffffe
    800048e2:	e60080e7          	jalr	-416(ra) # 8000273e <wakeup>
  release(&lk->lk);
    800048e6:	854a                	mv	a0,s2
    800048e8:	ffffc097          	auipc	ra,0xffffc
    800048ec:	548080e7          	jalr	1352(ra) # 80000e30 <release>
}
    800048f0:	60e2                	ld	ra,24(sp)
    800048f2:	6442                	ld	s0,16(sp)
    800048f4:	64a2                	ld	s1,8(sp)
    800048f6:	6902                	ld	s2,0(sp)
    800048f8:	6105                	addi	sp,sp,32
    800048fa:	8082                	ret

00000000800048fc <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800048fc:	7179                	addi	sp,sp,-48
    800048fe:	f406                	sd	ra,40(sp)
    80004900:	f022                	sd	s0,32(sp)
    80004902:	ec26                	sd	s1,24(sp)
    80004904:	e84a                	sd	s2,16(sp)
    80004906:	e44e                	sd	s3,8(sp)
    80004908:	1800                	addi	s0,sp,48
    8000490a:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000490c:	00850913          	addi	s2,a0,8
    80004910:	854a                	mv	a0,s2
    80004912:	ffffc097          	auipc	ra,0xffffc
    80004916:	44e080e7          	jalr	1102(ra) # 80000d60 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000491a:	409c                	lw	a5,0(s1)
    8000491c:	ef99                	bnez	a5,8000493a <holdingsleep+0x3e>
    8000491e:	4481                	li	s1,0
  release(&lk->lk);
    80004920:	854a                	mv	a0,s2
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	50e080e7          	jalr	1294(ra) # 80000e30 <release>
  return r;
}
    8000492a:	8526                	mv	a0,s1
    8000492c:	70a2                	ld	ra,40(sp)
    8000492e:	7402                	ld	s0,32(sp)
    80004930:	64e2                	ld	s1,24(sp)
    80004932:	6942                	ld	s2,16(sp)
    80004934:	69a2                	ld	s3,8(sp)
    80004936:	6145                	addi	sp,sp,48
    80004938:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000493a:	0304a983          	lw	s3,48(s1)
    8000493e:	ffffd097          	auipc	ra,0xffffd
    80004942:	46a080e7          	jalr	1130(ra) # 80001da8 <myproc>
    80004946:	4124                	lw	s1,64(a0)
    80004948:	413484b3          	sub	s1,s1,s3
    8000494c:	0014b493          	seqz	s1,s1
    80004950:	bfc1                	j	80004920 <holdingsleep+0x24>

0000000080004952 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004952:	1141                	addi	sp,sp,-16
    80004954:	e406                	sd	ra,8(sp)
    80004956:	e022                	sd	s0,0(sp)
    80004958:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    8000495a:	00004597          	auipc	a1,0x4
    8000495e:	d9e58593          	addi	a1,a1,-610 # 800086f8 <syscalls+0x240>
    80004962:	0001e517          	auipc	a0,0x1e
    80004966:	04e50513          	addi	a0,a0,78 # 800229b0 <ftable>
    8000496a:	ffffc097          	auipc	ra,0xffffc
    8000496e:	572080e7          	jalr	1394(ra) # 80000edc <initlock>
}
    80004972:	60a2                	ld	ra,8(sp)
    80004974:	6402                	ld	s0,0(sp)
    80004976:	0141                	addi	sp,sp,16
    80004978:	8082                	ret

000000008000497a <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000497a:	1101                	addi	sp,sp,-32
    8000497c:	ec06                	sd	ra,24(sp)
    8000497e:	e822                	sd	s0,16(sp)
    80004980:	e426                	sd	s1,8(sp)
    80004982:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004984:	0001e517          	auipc	a0,0x1e
    80004988:	02c50513          	addi	a0,a0,44 # 800229b0 <ftable>
    8000498c:	ffffc097          	auipc	ra,0xffffc
    80004990:	3d4080e7          	jalr	980(ra) # 80000d60 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004994:	0001e497          	auipc	s1,0x1e
    80004998:	03c48493          	addi	s1,s1,60 # 800229d0 <ftable+0x20>
    8000499c:	0001f717          	auipc	a4,0x1f
    800049a0:	fd470713          	addi	a4,a4,-44 # 80023970 <ftable+0xfc0>
    if(f->ref == 0){
    800049a4:	40dc                	lw	a5,4(s1)
    800049a6:	cf99                	beqz	a5,800049c4 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800049a8:	02848493          	addi	s1,s1,40
    800049ac:	fee49ce3          	bne	s1,a4,800049a4 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800049b0:	0001e517          	auipc	a0,0x1e
    800049b4:	00050513          	mv	a0,a0
    800049b8:	ffffc097          	auipc	ra,0xffffc
    800049bc:	478080e7          	jalr	1144(ra) # 80000e30 <release>
  return 0;
    800049c0:	4481                	li	s1,0
    800049c2:	a819                	j	800049d8 <filealloc+0x5e>
      f->ref = 1;
    800049c4:	4785                	li	a5,1
    800049c6:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800049c8:	0001e517          	auipc	a0,0x1e
    800049cc:	fe850513          	addi	a0,a0,-24 # 800229b0 <ftable>
    800049d0:	ffffc097          	auipc	ra,0xffffc
    800049d4:	460080e7          	jalr	1120(ra) # 80000e30 <release>
}
    800049d8:	8526                	mv	a0,s1
    800049da:	60e2                	ld	ra,24(sp)
    800049dc:	6442                	ld	s0,16(sp)
    800049de:	64a2                	ld	s1,8(sp)
    800049e0:	6105                	addi	sp,sp,32
    800049e2:	8082                	ret

00000000800049e4 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800049e4:	1101                	addi	sp,sp,-32
    800049e6:	ec06                	sd	ra,24(sp)
    800049e8:	e822                	sd	s0,16(sp)
    800049ea:	e426                	sd	s1,8(sp)
    800049ec:	1000                	addi	s0,sp,32
    800049ee:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800049f0:	0001e517          	auipc	a0,0x1e
    800049f4:	fc050513          	addi	a0,a0,-64 # 800229b0 <ftable>
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	368080e7          	jalr	872(ra) # 80000d60 <acquire>
  if(f->ref < 1)
    80004a00:	40dc                	lw	a5,4(s1)
    80004a02:	02f05263          	blez	a5,80004a26 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004a06:	2785                	addiw	a5,a5,1
    80004a08:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004a0a:	0001e517          	auipc	a0,0x1e
    80004a0e:	fa650513          	addi	a0,a0,-90 # 800229b0 <ftable>
    80004a12:	ffffc097          	auipc	ra,0xffffc
    80004a16:	41e080e7          	jalr	1054(ra) # 80000e30 <release>
  return f;
}
    80004a1a:	8526                	mv	a0,s1
    80004a1c:	60e2                	ld	ra,24(sp)
    80004a1e:	6442                	ld	s0,16(sp)
    80004a20:	64a2                	ld	s1,8(sp)
    80004a22:	6105                	addi	sp,sp,32
    80004a24:	8082                	ret
    panic("filedup");
    80004a26:	00004517          	auipc	a0,0x4
    80004a2a:	cda50513          	addi	a0,a0,-806 # 80008700 <syscalls+0x248>
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	b22080e7          	jalr	-1246(ra) # 80000550 <panic>

0000000080004a36 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004a36:	7139                	addi	sp,sp,-64
    80004a38:	fc06                	sd	ra,56(sp)
    80004a3a:	f822                	sd	s0,48(sp)
    80004a3c:	f426                	sd	s1,40(sp)
    80004a3e:	f04a                	sd	s2,32(sp)
    80004a40:	ec4e                	sd	s3,24(sp)
    80004a42:	e852                	sd	s4,16(sp)
    80004a44:	e456                	sd	s5,8(sp)
    80004a46:	0080                	addi	s0,sp,64
    80004a48:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004a4a:	0001e517          	auipc	a0,0x1e
    80004a4e:	f6650513          	addi	a0,a0,-154 # 800229b0 <ftable>
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	30e080e7          	jalr	782(ra) # 80000d60 <acquire>
  if(f->ref < 1)
    80004a5a:	40dc                	lw	a5,4(s1)
    80004a5c:	06f05163          	blez	a5,80004abe <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004a60:	37fd                	addiw	a5,a5,-1
    80004a62:	0007871b          	sext.w	a4,a5
    80004a66:	c0dc                	sw	a5,4(s1)
    80004a68:	06e04363          	bgtz	a4,80004ace <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004a6c:	0004a903          	lw	s2,0(s1)
    80004a70:	0094ca83          	lbu	s5,9(s1)
    80004a74:	0104ba03          	ld	s4,16(s1)
    80004a78:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004a7c:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004a80:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004a84:	0001e517          	auipc	a0,0x1e
    80004a88:	f2c50513          	addi	a0,a0,-212 # 800229b0 <ftable>
    80004a8c:	ffffc097          	auipc	ra,0xffffc
    80004a90:	3a4080e7          	jalr	932(ra) # 80000e30 <release>

  if(ff.type == FD_PIPE){
    80004a94:	4785                	li	a5,1
    80004a96:	04f90d63          	beq	s2,a5,80004af0 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004a9a:	3979                	addiw	s2,s2,-2
    80004a9c:	4785                	li	a5,1
    80004a9e:	0527e063          	bltu	a5,s2,80004ade <fileclose+0xa8>
    begin_op();
    80004aa2:	00000097          	auipc	ra,0x0
    80004aa6:	ac0080e7          	jalr	-1344(ra) # 80004562 <begin_op>
    iput(ff.ip);
    80004aaa:	854e                	mv	a0,s3
    80004aac:	fffff097          	auipc	ra,0xfffff
    80004ab0:	2a0080e7          	jalr	672(ra) # 80003d4c <iput>
    end_op();
    80004ab4:	00000097          	auipc	ra,0x0
    80004ab8:	b2e080e7          	jalr	-1234(ra) # 800045e2 <end_op>
    80004abc:	a00d                	j	80004ade <fileclose+0xa8>
    panic("fileclose");
    80004abe:	00004517          	auipc	a0,0x4
    80004ac2:	c4a50513          	addi	a0,a0,-950 # 80008708 <syscalls+0x250>
    80004ac6:	ffffc097          	auipc	ra,0xffffc
    80004aca:	a8a080e7          	jalr	-1398(ra) # 80000550 <panic>
    release(&ftable.lock);
    80004ace:	0001e517          	auipc	a0,0x1e
    80004ad2:	ee250513          	addi	a0,a0,-286 # 800229b0 <ftable>
    80004ad6:	ffffc097          	auipc	ra,0xffffc
    80004ada:	35a080e7          	jalr	858(ra) # 80000e30 <release>
  }
}
    80004ade:	70e2                	ld	ra,56(sp)
    80004ae0:	7442                	ld	s0,48(sp)
    80004ae2:	74a2                	ld	s1,40(sp)
    80004ae4:	7902                	ld	s2,32(sp)
    80004ae6:	69e2                	ld	s3,24(sp)
    80004ae8:	6a42                	ld	s4,16(sp)
    80004aea:	6aa2                	ld	s5,8(sp)
    80004aec:	6121                	addi	sp,sp,64
    80004aee:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004af0:	85d6                	mv	a1,s5
    80004af2:	8552                	mv	a0,s4
    80004af4:	00000097          	auipc	ra,0x0
    80004af8:	372080e7          	jalr	882(ra) # 80004e66 <pipeclose>
    80004afc:	b7cd                	j	80004ade <fileclose+0xa8>

0000000080004afe <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004afe:	715d                	addi	sp,sp,-80
    80004b00:	e486                	sd	ra,72(sp)
    80004b02:	e0a2                	sd	s0,64(sp)
    80004b04:	fc26                	sd	s1,56(sp)
    80004b06:	f84a                	sd	s2,48(sp)
    80004b08:	f44e                	sd	s3,40(sp)
    80004b0a:	0880                	addi	s0,sp,80
    80004b0c:	84aa                	mv	s1,a0
    80004b0e:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004b10:	ffffd097          	auipc	ra,0xffffd
    80004b14:	298080e7          	jalr	664(ra) # 80001da8 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004b18:	409c                	lw	a5,0(s1)
    80004b1a:	37f9                	addiw	a5,a5,-2
    80004b1c:	4705                	li	a4,1
    80004b1e:	04f76763          	bltu	a4,a5,80004b6c <filestat+0x6e>
    80004b22:	892a                	mv	s2,a0
    ilock(f->ip);
    80004b24:	6c88                	ld	a0,24(s1)
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	06c080e7          	jalr	108(ra) # 80003b92 <ilock>
    stati(f->ip, &st);
    80004b2e:	fb840593          	addi	a1,s0,-72
    80004b32:	6c88                	ld	a0,24(s1)
    80004b34:	fffff097          	auipc	ra,0xfffff
    80004b38:	2e8080e7          	jalr	744(ra) # 80003e1c <stati>
    iunlock(f->ip);
    80004b3c:	6c88                	ld	a0,24(s1)
    80004b3e:	fffff097          	auipc	ra,0xfffff
    80004b42:	116080e7          	jalr	278(ra) # 80003c54 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004b46:	46e1                	li	a3,24
    80004b48:	fb840613          	addi	a2,s0,-72
    80004b4c:	85ce                	mv	a1,s3
    80004b4e:	05893503          	ld	a0,88(s2)
    80004b52:	ffffd097          	auipc	ra,0xffffd
    80004b56:	f4a080e7          	jalr	-182(ra) # 80001a9c <copyout>
    80004b5a:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004b5e:	60a6                	ld	ra,72(sp)
    80004b60:	6406                	ld	s0,64(sp)
    80004b62:	74e2                	ld	s1,56(sp)
    80004b64:	7942                	ld	s2,48(sp)
    80004b66:	79a2                	ld	s3,40(sp)
    80004b68:	6161                	addi	sp,sp,80
    80004b6a:	8082                	ret
  return -1;
    80004b6c:	557d                	li	a0,-1
    80004b6e:	bfc5                	j	80004b5e <filestat+0x60>

0000000080004b70 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004b70:	7179                	addi	sp,sp,-48
    80004b72:	f406                	sd	ra,40(sp)
    80004b74:	f022                	sd	s0,32(sp)
    80004b76:	ec26                	sd	s1,24(sp)
    80004b78:	e84a                	sd	s2,16(sp)
    80004b7a:	e44e                	sd	s3,8(sp)
    80004b7c:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004b7e:	00854783          	lbu	a5,8(a0)
    80004b82:	c3d5                	beqz	a5,80004c26 <fileread+0xb6>
    80004b84:	84aa                	mv	s1,a0
    80004b86:	89ae                	mv	s3,a1
    80004b88:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004b8a:	411c                	lw	a5,0(a0)
    80004b8c:	4705                	li	a4,1
    80004b8e:	04e78963          	beq	a5,a4,80004be0 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004b92:	470d                	li	a4,3
    80004b94:	04e78d63          	beq	a5,a4,80004bee <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004b98:	4709                	li	a4,2
    80004b9a:	06e79e63          	bne	a5,a4,80004c16 <fileread+0xa6>
    ilock(f->ip);
    80004b9e:	6d08                	ld	a0,24(a0)
    80004ba0:	fffff097          	auipc	ra,0xfffff
    80004ba4:	ff2080e7          	jalr	-14(ra) # 80003b92 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004ba8:	874a                	mv	a4,s2
    80004baa:	5094                	lw	a3,32(s1)
    80004bac:	864e                	mv	a2,s3
    80004bae:	4585                	li	a1,1
    80004bb0:	6c88                	ld	a0,24(s1)
    80004bb2:	fffff097          	auipc	ra,0xfffff
    80004bb6:	294080e7          	jalr	660(ra) # 80003e46 <readi>
    80004bba:	892a                	mv	s2,a0
    80004bbc:	00a05563          	blez	a0,80004bc6 <fileread+0x56>
      f->off += r;
    80004bc0:	509c                	lw	a5,32(s1)
    80004bc2:	9fa9                	addw	a5,a5,a0
    80004bc4:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004bc6:	6c88                	ld	a0,24(s1)
    80004bc8:	fffff097          	auipc	ra,0xfffff
    80004bcc:	08c080e7          	jalr	140(ra) # 80003c54 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004bd0:	854a                	mv	a0,s2
    80004bd2:	70a2                	ld	ra,40(sp)
    80004bd4:	7402                	ld	s0,32(sp)
    80004bd6:	64e2                	ld	s1,24(sp)
    80004bd8:	6942                	ld	s2,16(sp)
    80004bda:	69a2                	ld	s3,8(sp)
    80004bdc:	6145                	addi	sp,sp,48
    80004bde:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004be0:	6908                	ld	a0,16(a0)
    80004be2:	00000097          	auipc	ra,0x0
    80004be6:	422080e7          	jalr	1058(ra) # 80005004 <piperead>
    80004bea:	892a                	mv	s2,a0
    80004bec:	b7d5                	j	80004bd0 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004bee:	02451783          	lh	a5,36(a0)
    80004bf2:	03079693          	slli	a3,a5,0x30
    80004bf6:	92c1                	srli	a3,a3,0x30
    80004bf8:	4725                	li	a4,9
    80004bfa:	02d76863          	bltu	a4,a3,80004c2a <fileread+0xba>
    80004bfe:	0792                	slli	a5,a5,0x4
    80004c00:	0001e717          	auipc	a4,0x1e
    80004c04:	d1070713          	addi	a4,a4,-752 # 80022910 <devsw>
    80004c08:	97ba                	add	a5,a5,a4
    80004c0a:	639c                	ld	a5,0(a5)
    80004c0c:	c38d                	beqz	a5,80004c2e <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004c0e:	4505                	li	a0,1
    80004c10:	9782                	jalr	a5
    80004c12:	892a                	mv	s2,a0
    80004c14:	bf75                	j	80004bd0 <fileread+0x60>
    panic("fileread");
    80004c16:	00004517          	auipc	a0,0x4
    80004c1a:	b0250513          	addi	a0,a0,-1278 # 80008718 <syscalls+0x260>
    80004c1e:	ffffc097          	auipc	ra,0xffffc
    80004c22:	932080e7          	jalr	-1742(ra) # 80000550 <panic>
    return -1;
    80004c26:	597d                	li	s2,-1
    80004c28:	b765                	j	80004bd0 <fileread+0x60>
      return -1;
    80004c2a:	597d                	li	s2,-1
    80004c2c:	b755                	j	80004bd0 <fileread+0x60>
    80004c2e:	597d                	li	s2,-1
    80004c30:	b745                	j	80004bd0 <fileread+0x60>

0000000080004c32 <filewrite>:
int
filewrite(struct file *f, uint64 addr, int n)
{
  int r, ret = 0;

  if(f->writable == 0)
    80004c32:	00954783          	lbu	a5,9(a0)
    80004c36:	14078563          	beqz	a5,80004d80 <filewrite+0x14e>
{
    80004c3a:	715d                	addi	sp,sp,-80
    80004c3c:	e486                	sd	ra,72(sp)
    80004c3e:	e0a2                	sd	s0,64(sp)
    80004c40:	fc26                	sd	s1,56(sp)
    80004c42:	f84a                	sd	s2,48(sp)
    80004c44:	f44e                	sd	s3,40(sp)
    80004c46:	f052                	sd	s4,32(sp)
    80004c48:	ec56                	sd	s5,24(sp)
    80004c4a:	e85a                	sd	s6,16(sp)
    80004c4c:	e45e                	sd	s7,8(sp)
    80004c4e:	e062                	sd	s8,0(sp)
    80004c50:	0880                	addi	s0,sp,80
    80004c52:	892a                	mv	s2,a0
    80004c54:	8aae                	mv	s5,a1
    80004c56:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004c58:	411c                	lw	a5,0(a0)
    80004c5a:	4705                	li	a4,1
    80004c5c:	02e78263          	beq	a5,a4,80004c80 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004c60:	470d                	li	a4,3
    80004c62:	02e78563          	beq	a5,a4,80004c8c <filewrite+0x5a>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004c66:	4709                	li	a4,2
    80004c68:	10e79463          	bne	a5,a4,80004d70 <filewrite+0x13e>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004c6c:	0ec05e63          	blez	a2,80004d68 <filewrite+0x136>
    int i = 0;
    80004c70:	4981                	li	s3,0
    80004c72:	6b05                	lui	s6,0x1
    80004c74:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004c78:	6b85                	lui	s7,0x1
    80004c7a:	c00b8b9b          	addiw	s7,s7,-1024
    80004c7e:	a851                	j	80004d12 <filewrite+0xe0>
    ret = pipewrite(f->pipe, addr, n);
    80004c80:	6908                	ld	a0,16(a0)
    80004c82:	00000097          	auipc	ra,0x0
    80004c86:	25e080e7          	jalr	606(ra) # 80004ee0 <pipewrite>
    80004c8a:	a85d                	j	80004d40 <filewrite+0x10e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004c8c:	02451783          	lh	a5,36(a0)
    80004c90:	03079693          	slli	a3,a5,0x30
    80004c94:	92c1                	srli	a3,a3,0x30
    80004c96:	4725                	li	a4,9
    80004c98:	0ed76663          	bltu	a4,a3,80004d84 <filewrite+0x152>
    80004c9c:	0792                	slli	a5,a5,0x4
    80004c9e:	0001e717          	auipc	a4,0x1e
    80004ca2:	c7270713          	addi	a4,a4,-910 # 80022910 <devsw>
    80004ca6:	97ba                	add	a5,a5,a4
    80004ca8:	679c                	ld	a5,8(a5)
    80004caa:	cff9                	beqz	a5,80004d88 <filewrite+0x156>
    ret = devsw[f->major].write(1, addr, n);
    80004cac:	4505                	li	a0,1
    80004cae:	9782                	jalr	a5
    80004cb0:	a841                	j	80004d40 <filewrite+0x10e>
    80004cb2:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004cb6:	00000097          	auipc	ra,0x0
    80004cba:	8ac080e7          	jalr	-1876(ra) # 80004562 <begin_op>
      ilock(f->ip);
    80004cbe:	01893503          	ld	a0,24(s2)
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	ed0080e7          	jalr	-304(ra) # 80003b92 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004cca:	8762                	mv	a4,s8
    80004ccc:	02092683          	lw	a3,32(s2)
    80004cd0:	01598633          	add	a2,s3,s5
    80004cd4:	4585                	li	a1,1
    80004cd6:	01893503          	ld	a0,24(s2)
    80004cda:	fffff097          	auipc	ra,0xfffff
    80004cde:	264080e7          	jalr	612(ra) # 80003f3e <writei>
    80004ce2:	84aa                	mv	s1,a0
    80004ce4:	02a05f63          	blez	a0,80004d22 <filewrite+0xf0>
        f->off += r;
    80004ce8:	02092783          	lw	a5,32(s2)
    80004cec:	9fa9                	addw	a5,a5,a0
    80004cee:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004cf2:	01893503          	ld	a0,24(s2)
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	f5e080e7          	jalr	-162(ra) # 80003c54 <iunlock>
      end_op();
    80004cfe:	00000097          	auipc	ra,0x0
    80004d02:	8e4080e7          	jalr	-1820(ra) # 800045e2 <end_op>

      if(r < 0)
        break;
      if(r != n1)
    80004d06:	049c1963          	bne	s8,s1,80004d58 <filewrite+0x126>
        panic("short filewrite");
      i += r;
    80004d0a:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004d0e:	0349d663          	bge	s3,s4,80004d3a <filewrite+0x108>
      int n1 = n - i;
    80004d12:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004d16:	84be                	mv	s1,a5
    80004d18:	2781                	sext.w	a5,a5
    80004d1a:	f8fb5ce3          	bge	s6,a5,80004cb2 <filewrite+0x80>
    80004d1e:	84de                	mv	s1,s7
    80004d20:	bf49                	j	80004cb2 <filewrite+0x80>
      iunlock(f->ip);
    80004d22:	01893503          	ld	a0,24(s2)
    80004d26:	fffff097          	auipc	ra,0xfffff
    80004d2a:	f2e080e7          	jalr	-210(ra) # 80003c54 <iunlock>
      end_op();
    80004d2e:	00000097          	auipc	ra,0x0
    80004d32:	8b4080e7          	jalr	-1868(ra) # 800045e2 <end_op>
      if(r < 0)
    80004d36:	fc04d8e3          	bgez	s1,80004d06 <filewrite+0xd4>
    }
    ret = (i == n ? n : -1);
    80004d3a:	8552                	mv	a0,s4
    80004d3c:	033a1863          	bne	s4,s3,80004d6c <filewrite+0x13a>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004d40:	60a6                	ld	ra,72(sp)
    80004d42:	6406                	ld	s0,64(sp)
    80004d44:	74e2                	ld	s1,56(sp)
    80004d46:	7942                	ld	s2,48(sp)
    80004d48:	79a2                	ld	s3,40(sp)
    80004d4a:	7a02                	ld	s4,32(sp)
    80004d4c:	6ae2                	ld	s5,24(sp)
    80004d4e:	6b42                	ld	s6,16(sp)
    80004d50:	6ba2                	ld	s7,8(sp)
    80004d52:	6c02                	ld	s8,0(sp)
    80004d54:	6161                	addi	sp,sp,80
    80004d56:	8082                	ret
        panic("short filewrite");
    80004d58:	00004517          	auipc	a0,0x4
    80004d5c:	9d050513          	addi	a0,a0,-1584 # 80008728 <syscalls+0x270>
    80004d60:	ffffb097          	auipc	ra,0xffffb
    80004d64:	7f0080e7          	jalr	2032(ra) # 80000550 <panic>
    int i = 0;
    80004d68:	4981                	li	s3,0
    80004d6a:	bfc1                	j	80004d3a <filewrite+0x108>
    ret = (i == n ? n : -1);
    80004d6c:	557d                	li	a0,-1
    80004d6e:	bfc9                	j	80004d40 <filewrite+0x10e>
    panic("filewrite");
    80004d70:	00004517          	auipc	a0,0x4
    80004d74:	9c850513          	addi	a0,a0,-1592 # 80008738 <syscalls+0x280>
    80004d78:	ffffb097          	auipc	ra,0xffffb
    80004d7c:	7d8080e7          	jalr	2008(ra) # 80000550 <panic>
    return -1;
    80004d80:	557d                	li	a0,-1
}
    80004d82:	8082                	ret
      return -1;
    80004d84:	557d                	li	a0,-1
    80004d86:	bf6d                	j	80004d40 <filewrite+0x10e>
    80004d88:	557d                	li	a0,-1
    80004d8a:	bf5d                	j	80004d40 <filewrite+0x10e>

0000000080004d8c <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d8c:	7179                	addi	sp,sp,-48
    80004d8e:	f406                	sd	ra,40(sp)
    80004d90:	f022                	sd	s0,32(sp)
    80004d92:	ec26                	sd	s1,24(sp)
    80004d94:	e84a                	sd	s2,16(sp)
    80004d96:	e44e                	sd	s3,8(sp)
    80004d98:	e052                	sd	s4,0(sp)
    80004d9a:	1800                	addi	s0,sp,48
    80004d9c:	84aa                	mv	s1,a0
    80004d9e:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004da0:	0005b023          	sd	zero,0(a1)
    80004da4:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004da8:	00000097          	auipc	ra,0x0
    80004dac:	bd2080e7          	jalr	-1070(ra) # 8000497a <filealloc>
    80004db0:	e088                	sd	a0,0(s1)
    80004db2:	c551                	beqz	a0,80004e3e <pipealloc+0xb2>
    80004db4:	00000097          	auipc	ra,0x0
    80004db8:	bc6080e7          	jalr	-1082(ra) # 8000497a <filealloc>
    80004dbc:	00aa3023          	sd	a0,0(s4)
    80004dc0:	c92d                	beqz	a0,80004e32 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004dc2:	ffffc097          	auipc	ra,0xffffc
    80004dc6:	db8080e7          	jalr	-584(ra) # 80000b7a <kalloc>
    80004dca:	892a                	mv	s2,a0
    80004dcc:	c125                	beqz	a0,80004e2c <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004dce:	4985                	li	s3,1
    80004dd0:	23352423          	sw	s3,552(a0)
  pi->writeopen = 1;
    80004dd4:	23352623          	sw	s3,556(a0)
  pi->nwrite = 0;
    80004dd8:	22052223          	sw	zero,548(a0)
  pi->nread = 0;
    80004ddc:	22052023          	sw	zero,544(a0)
  initlock(&pi->lock, "pipe");
    80004de0:	00004597          	auipc	a1,0x4
    80004de4:	96858593          	addi	a1,a1,-1688 # 80008748 <syscalls+0x290>
    80004de8:	ffffc097          	auipc	ra,0xffffc
    80004dec:	0f4080e7          	jalr	244(ra) # 80000edc <initlock>
  (*f0)->type = FD_PIPE;
    80004df0:	609c                	ld	a5,0(s1)
    80004df2:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004df6:	609c                	ld	a5,0(s1)
    80004df8:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dfc:	609c                	ld	a5,0(s1)
    80004dfe:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004e02:	609c                	ld	a5,0(s1)
    80004e04:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004e08:	000a3783          	ld	a5,0(s4)
    80004e0c:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004e10:	000a3783          	ld	a5,0(s4)
    80004e14:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004e18:	000a3783          	ld	a5,0(s4)
    80004e1c:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004e20:	000a3783          	ld	a5,0(s4)
    80004e24:	0127b823          	sd	s2,16(a5)
  return 0;
    80004e28:	4501                	li	a0,0
    80004e2a:	a025                	j	80004e52 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004e2c:	6088                	ld	a0,0(s1)
    80004e2e:	e501                	bnez	a0,80004e36 <pipealloc+0xaa>
    80004e30:	a039                	j	80004e3e <pipealloc+0xb2>
    80004e32:	6088                	ld	a0,0(s1)
    80004e34:	c51d                	beqz	a0,80004e62 <pipealloc+0xd6>
    fileclose(*f0);
    80004e36:	00000097          	auipc	ra,0x0
    80004e3a:	c00080e7          	jalr	-1024(ra) # 80004a36 <fileclose>
  if(*f1)
    80004e3e:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e42:	557d                	li	a0,-1
  if(*f1)
    80004e44:	c799                	beqz	a5,80004e52 <pipealloc+0xc6>
    fileclose(*f1);
    80004e46:	853e                	mv	a0,a5
    80004e48:	00000097          	auipc	ra,0x0
    80004e4c:	bee080e7          	jalr	-1042(ra) # 80004a36 <fileclose>
  return -1;
    80004e50:	557d                	li	a0,-1
}
    80004e52:	70a2                	ld	ra,40(sp)
    80004e54:	7402                	ld	s0,32(sp)
    80004e56:	64e2                	ld	s1,24(sp)
    80004e58:	6942                	ld	s2,16(sp)
    80004e5a:	69a2                	ld	s3,8(sp)
    80004e5c:	6a02                	ld	s4,0(sp)
    80004e5e:	6145                	addi	sp,sp,48
    80004e60:	8082                	ret
  return -1;
    80004e62:	557d                	li	a0,-1
    80004e64:	b7fd                	j	80004e52 <pipealloc+0xc6>

0000000080004e66 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e66:	1101                	addi	sp,sp,-32
    80004e68:	ec06                	sd	ra,24(sp)
    80004e6a:	e822                	sd	s0,16(sp)
    80004e6c:	e426                	sd	s1,8(sp)
    80004e6e:	e04a                	sd	s2,0(sp)
    80004e70:	1000                	addi	s0,sp,32
    80004e72:	84aa                	mv	s1,a0
    80004e74:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e76:	ffffc097          	auipc	ra,0xffffc
    80004e7a:	eea080e7          	jalr	-278(ra) # 80000d60 <acquire>
  if(writable){
    80004e7e:	04090263          	beqz	s2,80004ec2 <pipeclose+0x5c>
    pi->writeopen = 0;
    80004e82:	2204a623          	sw	zero,556(s1)
    wakeup(&pi->nread);
    80004e86:	22048513          	addi	a0,s1,544
    80004e8a:	ffffe097          	auipc	ra,0xffffe
    80004e8e:	8b4080e7          	jalr	-1868(ra) # 8000273e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e92:	2284b783          	ld	a5,552(s1)
    80004e96:	ef9d                	bnez	a5,80004ed4 <pipeclose+0x6e>
    release(&pi->lock);
    80004e98:	8526                	mv	a0,s1
    80004e9a:	ffffc097          	auipc	ra,0xffffc
    80004e9e:	f96080e7          	jalr	-106(ra) # 80000e30 <release>
#ifdef LAB_LOCK
    freelock(&pi->lock);
    80004ea2:	8526                	mv	a0,s1
    80004ea4:	ffffc097          	auipc	ra,0xffffc
    80004ea8:	fd4080e7          	jalr	-44(ra) # 80000e78 <freelock>
#endif    
    kfree((char*)pi);
    80004eac:	8526                	mv	a0,s1
    80004eae:	ffffc097          	auipc	ra,0xffffc
    80004eb2:	b7e080e7          	jalr	-1154(ra) # 80000a2c <kfree>
  } else
    release(&pi->lock);
}
    80004eb6:	60e2                	ld	ra,24(sp)
    80004eb8:	6442                	ld	s0,16(sp)
    80004eba:	64a2                	ld	s1,8(sp)
    80004ebc:	6902                	ld	s2,0(sp)
    80004ebe:	6105                	addi	sp,sp,32
    80004ec0:	8082                	ret
    pi->readopen = 0;
    80004ec2:	2204a423          	sw	zero,552(s1)
    wakeup(&pi->nwrite);
    80004ec6:	22448513          	addi	a0,s1,548
    80004eca:	ffffe097          	auipc	ra,0xffffe
    80004ece:	874080e7          	jalr	-1932(ra) # 8000273e <wakeup>
    80004ed2:	b7c1                	j	80004e92 <pipeclose+0x2c>
    release(&pi->lock);
    80004ed4:	8526                	mv	a0,s1
    80004ed6:	ffffc097          	auipc	ra,0xffffc
    80004eda:	f5a080e7          	jalr	-166(ra) # 80000e30 <release>
}
    80004ede:	bfe1                	j	80004eb6 <pipeclose+0x50>

0000000080004ee0 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004ee0:	7119                	addi	sp,sp,-128
    80004ee2:	fc86                	sd	ra,120(sp)
    80004ee4:	f8a2                	sd	s0,112(sp)
    80004ee6:	f4a6                	sd	s1,104(sp)
    80004ee8:	f0ca                	sd	s2,96(sp)
    80004eea:	ecce                	sd	s3,88(sp)
    80004eec:	e8d2                	sd	s4,80(sp)
    80004eee:	e4d6                	sd	s5,72(sp)
    80004ef0:	e0da                	sd	s6,64(sp)
    80004ef2:	fc5e                	sd	s7,56(sp)
    80004ef4:	f862                	sd	s8,48(sp)
    80004ef6:	f466                	sd	s9,40(sp)
    80004ef8:	f06a                	sd	s10,32(sp)
    80004efa:	ec6e                	sd	s11,24(sp)
    80004efc:	0100                	addi	s0,sp,128
    80004efe:	84aa                	mv	s1,a0
    80004f00:	8cae                	mv	s9,a1
    80004f02:	8b32                	mv	s6,a2
  int i;
  char ch;
  struct proc *pr = myproc();
    80004f04:	ffffd097          	auipc	ra,0xffffd
    80004f08:	ea4080e7          	jalr	-348(ra) # 80001da8 <myproc>
    80004f0c:	892a                	mv	s2,a0

  acquire(&pi->lock);
    80004f0e:	8526                	mv	a0,s1
    80004f10:	ffffc097          	auipc	ra,0xffffc
    80004f14:	e50080e7          	jalr	-432(ra) # 80000d60 <acquire>
  for(i = 0; i < n; i++){
    80004f18:	0d605963          	blez	s6,80004fea <pipewrite+0x10a>
    80004f1c:	89a6                	mv	s3,s1
    80004f1e:	3b7d                	addiw	s6,s6,-1
    80004f20:	1b02                	slli	s6,s6,0x20
    80004f22:	020b5b13          	srli	s6,s6,0x20
    80004f26:	4b81                	li	s7,0
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
      if(pi->readopen == 0 || pr->killed){
        release(&pi->lock);
        return -1;
      }
      wakeup(&pi->nread);
    80004f28:	22048a93          	addi	s5,s1,544
      sleep(&pi->nwrite, &pi->lock);
    80004f2c:	22448a13          	addi	s4,s1,548
    }
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f30:	5dfd                	li	s11,-1
    80004f32:	000b8d1b          	sext.w	s10,s7
    80004f36:	8c6a                	mv	s8,s10
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f38:	2204a783          	lw	a5,544(s1)
    80004f3c:	2244a703          	lw	a4,548(s1)
    80004f40:	2007879b          	addiw	a5,a5,512
    80004f44:	02f71b63          	bne	a4,a5,80004f7a <pipewrite+0x9a>
      if(pi->readopen == 0 || pr->killed){
    80004f48:	2284a783          	lw	a5,552(s1)
    80004f4c:	cbad                	beqz	a5,80004fbe <pipewrite+0xde>
    80004f4e:	03892783          	lw	a5,56(s2)
    80004f52:	e7b5                	bnez	a5,80004fbe <pipewrite+0xde>
      wakeup(&pi->nread);
    80004f54:	8556                	mv	a0,s5
    80004f56:	ffffd097          	auipc	ra,0xffffd
    80004f5a:	7e8080e7          	jalr	2024(ra) # 8000273e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f5e:	85ce                	mv	a1,s3
    80004f60:	8552                	mv	a0,s4
    80004f62:	ffffd097          	auipc	ra,0xffffd
    80004f66:	656080e7          	jalr	1622(ra) # 800025b8 <sleep>
    while(pi->nwrite == pi->nread + PIPESIZE){  //DOC: pipewrite-full
    80004f6a:	2204a783          	lw	a5,544(s1)
    80004f6e:	2244a703          	lw	a4,548(s1)
    80004f72:	2007879b          	addiw	a5,a5,512
    80004f76:	fcf709e3          	beq	a4,a5,80004f48 <pipewrite+0x68>
    if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f7a:	4685                	li	a3,1
    80004f7c:	019b8633          	add	a2,s7,s9
    80004f80:	f8f40593          	addi	a1,s0,-113
    80004f84:	05893503          	ld	a0,88(s2)
    80004f88:	ffffd097          	auipc	ra,0xffffd
    80004f8c:	ba0080e7          	jalr	-1120(ra) # 80001b28 <copyin>
    80004f90:	05b50e63          	beq	a0,s11,80004fec <pipewrite+0x10c>
      break;
    pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f94:	2244a783          	lw	a5,548(s1)
    80004f98:	0017871b          	addiw	a4,a5,1
    80004f9c:	22e4a223          	sw	a4,548(s1)
    80004fa0:	1ff7f793          	andi	a5,a5,511
    80004fa4:	97a6                	add	a5,a5,s1
    80004fa6:	f8f44703          	lbu	a4,-113(s0)
    80004faa:	02e78023          	sb	a4,32(a5)
  for(i = 0; i < n; i++){
    80004fae:	001d0c1b          	addiw	s8,s10,1
    80004fb2:	001b8793          	addi	a5,s7,1 # 1001 <_entry-0x7fffefff>
    80004fb6:	036b8b63          	beq	s7,s6,80004fec <pipewrite+0x10c>
    80004fba:	8bbe                	mv	s7,a5
    80004fbc:	bf9d                	j	80004f32 <pipewrite+0x52>
        release(&pi->lock);
    80004fbe:	8526                	mv	a0,s1
    80004fc0:	ffffc097          	auipc	ra,0xffffc
    80004fc4:	e70080e7          	jalr	-400(ra) # 80000e30 <release>
        return -1;
    80004fc8:	5c7d                	li	s8,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);
  return i;
}
    80004fca:	8562                	mv	a0,s8
    80004fcc:	70e6                	ld	ra,120(sp)
    80004fce:	7446                	ld	s0,112(sp)
    80004fd0:	74a6                	ld	s1,104(sp)
    80004fd2:	7906                	ld	s2,96(sp)
    80004fd4:	69e6                	ld	s3,88(sp)
    80004fd6:	6a46                	ld	s4,80(sp)
    80004fd8:	6aa6                	ld	s5,72(sp)
    80004fda:	6b06                	ld	s6,64(sp)
    80004fdc:	7be2                	ld	s7,56(sp)
    80004fde:	7c42                	ld	s8,48(sp)
    80004fe0:	7ca2                	ld	s9,40(sp)
    80004fe2:	7d02                	ld	s10,32(sp)
    80004fe4:	6de2                	ld	s11,24(sp)
    80004fe6:	6109                	addi	sp,sp,128
    80004fe8:	8082                	ret
  for(i = 0; i < n; i++){
    80004fea:	4c01                	li	s8,0
  wakeup(&pi->nread);
    80004fec:	22048513          	addi	a0,s1,544
    80004ff0:	ffffd097          	auipc	ra,0xffffd
    80004ff4:	74e080e7          	jalr	1870(ra) # 8000273e <wakeup>
  release(&pi->lock);
    80004ff8:	8526                	mv	a0,s1
    80004ffa:	ffffc097          	auipc	ra,0xffffc
    80004ffe:	e36080e7          	jalr	-458(ra) # 80000e30 <release>
  return i;
    80005002:	b7e1                	j	80004fca <pipewrite+0xea>

0000000080005004 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005004:	715d                	addi	sp,sp,-80
    80005006:	e486                	sd	ra,72(sp)
    80005008:	e0a2                	sd	s0,64(sp)
    8000500a:	fc26                	sd	s1,56(sp)
    8000500c:	f84a                	sd	s2,48(sp)
    8000500e:	f44e                	sd	s3,40(sp)
    80005010:	f052                	sd	s4,32(sp)
    80005012:	ec56                	sd	s5,24(sp)
    80005014:	e85a                	sd	s6,16(sp)
    80005016:	0880                	addi	s0,sp,80
    80005018:	84aa                	mv	s1,a0
    8000501a:	892e                	mv	s2,a1
    8000501c:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	d8a080e7          	jalr	-630(ra) # 80001da8 <myproc>
    80005026:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005028:	8b26                	mv	s6,s1
    8000502a:	8526                	mv	a0,s1
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	d34080e7          	jalr	-716(ra) # 80000d60 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005034:	2204a703          	lw	a4,544(s1)
    80005038:	2244a783          	lw	a5,548(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000503c:	22048993          	addi	s3,s1,544
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005040:	02f71463          	bne	a4,a5,80005068 <piperead+0x64>
    80005044:	22c4a783          	lw	a5,556(s1)
    80005048:	c385                	beqz	a5,80005068 <piperead+0x64>
    if(pr->killed){
    8000504a:	038a2783          	lw	a5,56(s4)
    8000504e:	ebc1                	bnez	a5,800050de <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005050:	85da                	mv	a1,s6
    80005052:	854e                	mv	a0,s3
    80005054:	ffffd097          	auipc	ra,0xffffd
    80005058:	564080e7          	jalr	1380(ra) # 800025b8 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    8000505c:	2204a703          	lw	a4,544(s1)
    80005060:	2244a783          	lw	a5,548(s1)
    80005064:	fef700e3          	beq	a4,a5,80005044 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005068:	09505263          	blez	s5,800050ec <piperead+0xe8>
    8000506c:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    8000506e:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005070:	2204a783          	lw	a5,544(s1)
    80005074:	2244a703          	lw	a4,548(s1)
    80005078:	02f70d63          	beq	a4,a5,800050b2 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000507c:	0017871b          	addiw	a4,a5,1
    80005080:	22e4a023          	sw	a4,544(s1)
    80005084:	1ff7f793          	andi	a5,a5,511
    80005088:	97a6                	add	a5,a5,s1
    8000508a:	0207c783          	lbu	a5,32(a5)
    8000508e:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005092:	4685                	li	a3,1
    80005094:	fbf40613          	addi	a2,s0,-65
    80005098:	85ca                	mv	a1,s2
    8000509a:	058a3503          	ld	a0,88(s4)
    8000509e:	ffffd097          	auipc	ra,0xffffd
    800050a2:	9fe080e7          	jalr	-1538(ra) # 80001a9c <copyout>
    800050a6:	01650663          	beq	a0,s6,800050b2 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050aa:	2985                	addiw	s3,s3,1
    800050ac:	0905                	addi	s2,s2,1
    800050ae:	fd3a91e3          	bne	s5,s3,80005070 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800050b2:	22448513          	addi	a0,s1,548
    800050b6:	ffffd097          	auipc	ra,0xffffd
    800050ba:	688080e7          	jalr	1672(ra) # 8000273e <wakeup>
  release(&pi->lock);
    800050be:	8526                	mv	a0,s1
    800050c0:	ffffc097          	auipc	ra,0xffffc
    800050c4:	d70080e7          	jalr	-656(ra) # 80000e30 <release>
  return i;
}
    800050c8:	854e                	mv	a0,s3
    800050ca:	60a6                	ld	ra,72(sp)
    800050cc:	6406                	ld	s0,64(sp)
    800050ce:	74e2                	ld	s1,56(sp)
    800050d0:	7942                	ld	s2,48(sp)
    800050d2:	79a2                	ld	s3,40(sp)
    800050d4:	7a02                	ld	s4,32(sp)
    800050d6:	6ae2                	ld	s5,24(sp)
    800050d8:	6b42                	ld	s6,16(sp)
    800050da:	6161                	addi	sp,sp,80
    800050dc:	8082                	ret
      release(&pi->lock);
    800050de:	8526                	mv	a0,s1
    800050e0:	ffffc097          	auipc	ra,0xffffc
    800050e4:	d50080e7          	jalr	-688(ra) # 80000e30 <release>
      return -1;
    800050e8:	59fd                	li	s3,-1
    800050ea:	bff9                	j	800050c8 <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800050ec:	4981                	li	s3,0
    800050ee:	b7d1                	j	800050b2 <piperead+0xae>

00000000800050f0 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800050f0:	df010113          	addi	sp,sp,-528
    800050f4:	20113423          	sd	ra,520(sp)
    800050f8:	20813023          	sd	s0,512(sp)
    800050fc:	ffa6                	sd	s1,504(sp)
    800050fe:	fbca                	sd	s2,496(sp)
    80005100:	f7ce                	sd	s3,488(sp)
    80005102:	f3d2                	sd	s4,480(sp)
    80005104:	efd6                	sd	s5,472(sp)
    80005106:	ebda                	sd	s6,464(sp)
    80005108:	e7de                	sd	s7,456(sp)
    8000510a:	e3e2                	sd	s8,448(sp)
    8000510c:	ff66                	sd	s9,440(sp)
    8000510e:	fb6a                	sd	s10,432(sp)
    80005110:	f76e                	sd	s11,424(sp)
    80005112:	0c00                	addi	s0,sp,528
    80005114:	84aa                	mv	s1,a0
    80005116:	dea43c23          	sd	a0,-520(s0)
    8000511a:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    8000511e:	ffffd097          	auipc	ra,0xffffd
    80005122:	c8a080e7          	jalr	-886(ra) # 80001da8 <myproc>
    80005126:	892a                	mv	s2,a0

  begin_op();
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	43a080e7          	jalr	1082(ra) # 80004562 <begin_op>

  if((ip = namei(path)) == 0){
    80005130:	8526                	mv	a0,s1
    80005132:	fffff097          	auipc	ra,0xfffff
    80005136:	214080e7          	jalr	532(ra) # 80004346 <namei>
    8000513a:	c92d                	beqz	a0,800051ac <exec+0xbc>
    8000513c:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	a54080e7          	jalr	-1452(ra) # 80003b92 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005146:	04000713          	li	a4,64
    8000514a:	4681                	li	a3,0
    8000514c:	e4840613          	addi	a2,s0,-440
    80005150:	4581                	li	a1,0
    80005152:	8526                	mv	a0,s1
    80005154:	fffff097          	auipc	ra,0xfffff
    80005158:	cf2080e7          	jalr	-782(ra) # 80003e46 <readi>
    8000515c:	04000793          	li	a5,64
    80005160:	00f51a63          	bne	a0,a5,80005174 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005164:	e4842703          	lw	a4,-440(s0)
    80005168:	464c47b7          	lui	a5,0x464c4
    8000516c:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005170:	04f70463          	beq	a4,a5,800051b8 <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005174:	8526                	mv	a0,s1
    80005176:	fffff097          	auipc	ra,0xfffff
    8000517a:	c7e080e7          	jalr	-898(ra) # 80003df4 <iunlockput>
    end_op();
    8000517e:	fffff097          	auipc	ra,0xfffff
    80005182:	464080e7          	jalr	1124(ra) # 800045e2 <end_op>
  }
  return -1;
    80005186:	557d                	li	a0,-1
}
    80005188:	20813083          	ld	ra,520(sp)
    8000518c:	20013403          	ld	s0,512(sp)
    80005190:	74fe                	ld	s1,504(sp)
    80005192:	795e                	ld	s2,496(sp)
    80005194:	79be                	ld	s3,488(sp)
    80005196:	7a1e                	ld	s4,480(sp)
    80005198:	6afe                	ld	s5,472(sp)
    8000519a:	6b5e                	ld	s6,464(sp)
    8000519c:	6bbe                	ld	s7,456(sp)
    8000519e:	6c1e                	ld	s8,448(sp)
    800051a0:	7cfa                	ld	s9,440(sp)
    800051a2:	7d5a                	ld	s10,432(sp)
    800051a4:	7dba                	ld	s11,424(sp)
    800051a6:	21010113          	addi	sp,sp,528
    800051aa:	8082                	ret
    end_op();
    800051ac:	fffff097          	auipc	ra,0xfffff
    800051b0:	436080e7          	jalr	1078(ra) # 800045e2 <end_op>
    return -1;
    800051b4:	557d                	li	a0,-1
    800051b6:	bfc9                	j	80005188 <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    800051b8:	854a                	mv	a0,s2
    800051ba:	ffffd097          	auipc	ra,0xffffd
    800051be:	cb2080e7          	jalr	-846(ra) # 80001e6c <proc_pagetable>
    800051c2:	8baa                	mv	s7,a0
    800051c4:	d945                	beqz	a0,80005174 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051c6:	e6842983          	lw	s3,-408(s0)
    800051ca:	e8045783          	lhu	a5,-384(s0)
    800051ce:	c7ad                	beqz	a5,80005238 <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800051d0:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800051d2:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800051d4:	6c85                	lui	s9,0x1
    800051d6:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800051da:	def43823          	sd	a5,-528(s0)
    800051de:	a42d                	j	80005408 <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800051e0:	00003517          	auipc	a0,0x3
    800051e4:	57050513          	addi	a0,a0,1392 # 80008750 <syscalls+0x298>
    800051e8:	ffffb097          	auipc	ra,0xffffb
    800051ec:	368080e7          	jalr	872(ra) # 80000550 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800051f0:	8756                	mv	a4,s5
    800051f2:	012d86bb          	addw	a3,s11,s2
    800051f6:	4581                	li	a1,0
    800051f8:	8526                	mv	a0,s1
    800051fa:	fffff097          	auipc	ra,0xfffff
    800051fe:	c4c080e7          	jalr	-948(ra) # 80003e46 <readi>
    80005202:	2501                	sext.w	a0,a0
    80005204:	1aaa9963          	bne	s5,a0,800053b6 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    80005208:	6785                	lui	a5,0x1
    8000520a:	0127893b          	addw	s2,a5,s2
    8000520e:	77fd                	lui	a5,0xfffff
    80005210:	01478a3b          	addw	s4,a5,s4
    80005214:	1f897163          	bgeu	s2,s8,800053f6 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    80005218:	02091593          	slli	a1,s2,0x20
    8000521c:	9181                	srli	a1,a1,0x20
    8000521e:	95ea                	add	a1,a1,s10
    80005220:	855e                	mv	a0,s7
    80005222:	ffffc097          	auipc	ra,0xffffc
    80005226:	2b8080e7          	jalr	696(ra) # 800014da <walkaddr>
    8000522a:	862a                	mv	a2,a0
    if(pa == 0)
    8000522c:	d955                	beqz	a0,800051e0 <exec+0xf0>
      n = PGSIZE;
    8000522e:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005230:	fd9a70e3          	bgeu	s4,s9,800051f0 <exec+0x100>
      n = sz - i;
    80005234:	8ad2                	mv	s5,s4
    80005236:	bf6d                	j	800051f0 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    80005238:	4901                	li	s2,0
  iunlockput(ip);
    8000523a:	8526                	mv	a0,s1
    8000523c:	fffff097          	auipc	ra,0xfffff
    80005240:	bb8080e7          	jalr	-1096(ra) # 80003df4 <iunlockput>
  end_op();
    80005244:	fffff097          	auipc	ra,0xfffff
    80005248:	39e080e7          	jalr	926(ra) # 800045e2 <end_op>
  p = myproc();
    8000524c:	ffffd097          	auipc	ra,0xffffd
    80005250:	b5c080e7          	jalr	-1188(ra) # 80001da8 <myproc>
    80005254:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    80005256:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    8000525a:	6785                	lui	a5,0x1
    8000525c:	17fd                	addi	a5,a5,-1
    8000525e:	993e                	add	s2,s2,a5
    80005260:	757d                	lui	a0,0xfffff
    80005262:	00a977b3          	and	a5,s2,a0
    80005266:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000526a:	6609                	lui	a2,0x2
    8000526c:	963e                	add	a2,a2,a5
    8000526e:	85be                	mv	a1,a5
    80005270:	855e                	mv	a0,s7
    80005272:	ffffc097          	auipc	ra,0xffffc
    80005276:	5da080e7          	jalr	1498(ra) # 8000184c <uvmalloc>
    8000527a:	8b2a                	mv	s6,a0
  ip = 0;
    8000527c:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000527e:	12050c63          	beqz	a0,800053b6 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005282:	75f9                	lui	a1,0xffffe
    80005284:	95aa                	add	a1,a1,a0
    80005286:	855e                	mv	a0,s7
    80005288:	ffffc097          	auipc	ra,0xffffc
    8000528c:	7e2080e7          	jalr	2018(ra) # 80001a6a <uvmclear>
  stackbase = sp - PGSIZE;
    80005290:	7c7d                	lui	s8,0xfffff
    80005292:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005294:	e0043783          	ld	a5,-512(s0)
    80005298:	6388                	ld	a0,0(a5)
    8000529a:	c535                	beqz	a0,80005306 <exec+0x216>
    8000529c:	e8840993          	addi	s3,s0,-376
    800052a0:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    800052a4:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800052a6:	ffffc097          	auipc	ra,0xffffc
    800052aa:	022080e7          	jalr	34(ra) # 800012c8 <strlen>
    800052ae:	2505                	addiw	a0,a0,1
    800052b0:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800052b4:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    800052b8:	13896363          	bltu	s2,s8,800053de <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800052bc:	e0043d83          	ld	s11,-512(s0)
    800052c0:	000dba03          	ld	s4,0(s11)
    800052c4:	8552                	mv	a0,s4
    800052c6:	ffffc097          	auipc	ra,0xffffc
    800052ca:	002080e7          	jalr	2(ra) # 800012c8 <strlen>
    800052ce:	0015069b          	addiw	a3,a0,1
    800052d2:	8652                	mv	a2,s4
    800052d4:	85ca                	mv	a1,s2
    800052d6:	855e                	mv	a0,s7
    800052d8:	ffffc097          	auipc	ra,0xffffc
    800052dc:	7c4080e7          	jalr	1988(ra) # 80001a9c <copyout>
    800052e0:	10054363          	bltz	a0,800053e6 <exec+0x2f6>
    ustack[argc] = sp;
    800052e4:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800052e8:	0485                	addi	s1,s1,1
    800052ea:	008d8793          	addi	a5,s11,8
    800052ee:	e0f43023          	sd	a5,-512(s0)
    800052f2:	008db503          	ld	a0,8(s11)
    800052f6:	c911                	beqz	a0,8000530a <exec+0x21a>
    if(argc >= MAXARG)
    800052f8:	09a1                	addi	s3,s3,8
    800052fa:	fb3c96e3          	bne	s9,s3,800052a6 <exec+0x1b6>
  sz = sz1;
    800052fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005302:	4481                	li	s1,0
    80005304:	a84d                	j	800053b6 <exec+0x2c6>
  sp = sz;
    80005306:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005308:	4481                	li	s1,0
  ustack[argc] = 0;
    8000530a:	00349793          	slli	a5,s1,0x3
    8000530e:	f9040713          	addi	a4,s0,-112
    80005312:	97ba                	add	a5,a5,a4
    80005314:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    80005318:	00148693          	addi	a3,s1,1
    8000531c:	068e                	slli	a3,a3,0x3
    8000531e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005322:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005326:	01897663          	bgeu	s2,s8,80005332 <exec+0x242>
  sz = sz1;
    8000532a:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000532e:	4481                	li	s1,0
    80005330:	a059                	j	800053b6 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005332:	e8840613          	addi	a2,s0,-376
    80005336:	85ca                	mv	a1,s2
    80005338:	855e                	mv	a0,s7
    8000533a:	ffffc097          	auipc	ra,0xffffc
    8000533e:	762080e7          	jalr	1890(ra) # 80001a9c <copyout>
    80005342:	0a054663          	bltz	a0,800053ee <exec+0x2fe>
  p->trapframe->a1 = sp;
    80005346:	060ab783          	ld	a5,96(s5)
    8000534a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000534e:	df843783          	ld	a5,-520(s0)
    80005352:	0007c703          	lbu	a4,0(a5)
    80005356:	cf11                	beqz	a4,80005372 <exec+0x282>
    80005358:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000535a:	02f00693          	li	a3,47
    8000535e:	a029                	j	80005368 <exec+0x278>
  for(last=s=path; *s; s++)
    80005360:	0785                	addi	a5,a5,1
    80005362:	fff7c703          	lbu	a4,-1(a5)
    80005366:	c711                	beqz	a4,80005372 <exec+0x282>
    if(*s == '/')
    80005368:	fed71ce3          	bne	a4,a3,80005360 <exec+0x270>
      last = s+1;
    8000536c:	def43c23          	sd	a5,-520(s0)
    80005370:	bfc5                	j	80005360 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005372:	4641                	li	a2,16
    80005374:	df843583          	ld	a1,-520(s0)
    80005378:	160a8513          	addi	a0,s5,352
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	f1a080e7          	jalr	-230(ra) # 80001296 <safestrcpy>
  oldpagetable = p->pagetable;
    80005384:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005388:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    8000538c:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005390:	060ab783          	ld	a5,96(s5)
    80005394:	e6043703          	ld	a4,-416(s0)
    80005398:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000539a:	060ab783          	ld	a5,96(s5)
    8000539e:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800053a2:	85ea                	mv	a1,s10
    800053a4:	ffffd097          	auipc	ra,0xffffd
    800053a8:	b64080e7          	jalr	-1180(ra) # 80001f08 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800053ac:	0004851b          	sext.w	a0,s1
    800053b0:	bbe1                	j	80005188 <exec+0x98>
    800053b2:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    800053b6:	e0843583          	ld	a1,-504(s0)
    800053ba:	855e                	mv	a0,s7
    800053bc:	ffffd097          	auipc	ra,0xffffd
    800053c0:	b4c080e7          	jalr	-1204(ra) # 80001f08 <proc_freepagetable>
  if(ip){
    800053c4:	da0498e3          	bnez	s1,80005174 <exec+0x84>
  return -1;
    800053c8:	557d                	li	a0,-1
    800053ca:	bb7d                	j	80005188 <exec+0x98>
    800053cc:	e1243423          	sd	s2,-504(s0)
    800053d0:	b7dd                	j	800053b6 <exec+0x2c6>
    800053d2:	e1243423          	sd	s2,-504(s0)
    800053d6:	b7c5                	j	800053b6 <exec+0x2c6>
    800053d8:	e1243423          	sd	s2,-504(s0)
    800053dc:	bfe9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053de:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053e2:	4481                	li	s1,0
    800053e4:	bfc9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053e6:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053ea:	4481                	li	s1,0
    800053ec:	b7e9                	j	800053b6 <exec+0x2c6>
  sz = sz1;
    800053ee:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800053f2:	4481                	li	s1,0
    800053f4:	b7c9                	j	800053b6 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053f6:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800053fa:	2b05                	addiw	s6,s6,1
    800053fc:	0389899b          	addiw	s3,s3,56
    80005400:	e8045783          	lhu	a5,-384(s0)
    80005404:	e2fb5be3          	bge	s6,a5,8000523a <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005408:	2981                	sext.w	s3,s3
    8000540a:	03800713          	li	a4,56
    8000540e:	86ce                	mv	a3,s3
    80005410:	e1040613          	addi	a2,s0,-496
    80005414:	4581                	li	a1,0
    80005416:	8526                	mv	a0,s1
    80005418:	fffff097          	auipc	ra,0xfffff
    8000541c:	a2e080e7          	jalr	-1490(ra) # 80003e46 <readi>
    80005420:	03800793          	li	a5,56
    80005424:	f8f517e3          	bne	a0,a5,800053b2 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    80005428:	e1042783          	lw	a5,-496(s0)
    8000542c:	4705                	li	a4,1
    8000542e:	fce796e3          	bne	a5,a4,800053fa <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005432:	e3843603          	ld	a2,-456(s0)
    80005436:	e3043783          	ld	a5,-464(s0)
    8000543a:	f8f669e3          	bltu	a2,a5,800053cc <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    8000543e:	e2043783          	ld	a5,-480(s0)
    80005442:	963e                	add	a2,a2,a5
    80005444:	f8f667e3          	bltu	a2,a5,800053d2 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005448:	85ca                	mv	a1,s2
    8000544a:	855e                	mv	a0,s7
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	400080e7          	jalr	1024(ra) # 8000184c <uvmalloc>
    80005454:	e0a43423          	sd	a0,-504(s0)
    80005458:	d141                	beqz	a0,800053d8 <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000545a:	e2043d03          	ld	s10,-480(s0)
    8000545e:	df043783          	ld	a5,-528(s0)
    80005462:	00fd77b3          	and	a5,s10,a5
    80005466:	fba1                	bnez	a5,800053b6 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005468:	e1842d83          	lw	s11,-488(s0)
    8000546c:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005470:	f80c03e3          	beqz	s8,800053f6 <exec+0x306>
    80005474:	8a62                	mv	s4,s8
    80005476:	4901                	li	s2,0
    80005478:	b345                	j	80005218 <exec+0x128>

000000008000547a <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000547a:	7179                	addi	sp,sp,-48
    8000547c:	f406                	sd	ra,40(sp)
    8000547e:	f022                	sd	s0,32(sp)
    80005480:	ec26                	sd	s1,24(sp)
    80005482:	e84a                	sd	s2,16(sp)
    80005484:	1800                	addi	s0,sp,48
    80005486:	892e                	mv	s2,a1
    80005488:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000548a:	fdc40593          	addi	a1,s0,-36
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	9d8080e7          	jalr	-1576(ra) # 80002e66 <argint>
    80005496:	04054063          	bltz	a0,800054d6 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000549a:	fdc42703          	lw	a4,-36(s0)
    8000549e:	47bd                	li	a5,15
    800054a0:	02e7ed63          	bltu	a5,a4,800054da <argfd+0x60>
    800054a4:	ffffd097          	auipc	ra,0xffffd
    800054a8:	904080e7          	jalr	-1788(ra) # 80001da8 <myproc>
    800054ac:	fdc42703          	lw	a4,-36(s0)
    800054b0:	01a70793          	addi	a5,a4,26
    800054b4:	078e                	slli	a5,a5,0x3
    800054b6:	953e                	add	a0,a0,a5
    800054b8:	651c                	ld	a5,8(a0)
    800054ba:	c395                	beqz	a5,800054de <argfd+0x64>
    return -1;
  if(pfd)
    800054bc:	00090463          	beqz	s2,800054c4 <argfd+0x4a>
    *pfd = fd;
    800054c0:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800054c4:	4501                	li	a0,0
  if(pf)
    800054c6:	c091                	beqz	s1,800054ca <argfd+0x50>
    *pf = f;
    800054c8:	e09c                	sd	a5,0(s1)
}
    800054ca:	70a2                	ld	ra,40(sp)
    800054cc:	7402                	ld	s0,32(sp)
    800054ce:	64e2                	ld	s1,24(sp)
    800054d0:	6942                	ld	s2,16(sp)
    800054d2:	6145                	addi	sp,sp,48
    800054d4:	8082                	ret
    return -1;
    800054d6:	557d                	li	a0,-1
    800054d8:	bfcd                	j	800054ca <argfd+0x50>
    return -1;
    800054da:	557d                	li	a0,-1
    800054dc:	b7fd                	j	800054ca <argfd+0x50>
    800054de:	557d                	li	a0,-1
    800054e0:	b7ed                	j	800054ca <argfd+0x50>

00000000800054e2 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800054e2:	1101                	addi	sp,sp,-32
    800054e4:	ec06                	sd	ra,24(sp)
    800054e6:	e822                	sd	s0,16(sp)
    800054e8:	e426                	sd	s1,8(sp)
    800054ea:	1000                	addi	s0,sp,32
    800054ec:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800054ee:	ffffd097          	auipc	ra,0xffffd
    800054f2:	8ba080e7          	jalr	-1862(ra) # 80001da8 <myproc>
    800054f6:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800054f8:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7ffd70b0>
    800054fc:	4501                	li	a0,0
    800054fe:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005500:	6398                	ld	a4,0(a5)
    80005502:	cb19                	beqz	a4,80005518 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005504:	2505                	addiw	a0,a0,1
    80005506:	07a1                	addi	a5,a5,8
    80005508:	fed51ce3          	bne	a0,a3,80005500 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000550c:	557d                	li	a0,-1
}
    8000550e:	60e2                	ld	ra,24(sp)
    80005510:	6442                	ld	s0,16(sp)
    80005512:	64a2                	ld	s1,8(sp)
    80005514:	6105                	addi	sp,sp,32
    80005516:	8082                	ret
      p->ofile[fd] = f;
    80005518:	01a50793          	addi	a5,a0,26
    8000551c:	078e                	slli	a5,a5,0x3
    8000551e:	963e                	add	a2,a2,a5
    80005520:	e604                	sd	s1,8(a2)
      return fd;
    80005522:	b7f5                	j	8000550e <fdalloc+0x2c>

0000000080005524 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005524:	715d                	addi	sp,sp,-80
    80005526:	e486                	sd	ra,72(sp)
    80005528:	e0a2                	sd	s0,64(sp)
    8000552a:	fc26                	sd	s1,56(sp)
    8000552c:	f84a                	sd	s2,48(sp)
    8000552e:	f44e                	sd	s3,40(sp)
    80005530:	f052                	sd	s4,32(sp)
    80005532:	ec56                	sd	s5,24(sp)
    80005534:	0880                	addi	s0,sp,80
    80005536:	89ae                	mv	s3,a1
    80005538:	8ab2                	mv	s5,a2
    8000553a:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000553c:	fb040593          	addi	a1,s0,-80
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	e24080e7          	jalr	-476(ra) # 80004364 <nameiparent>
    80005548:	892a                	mv	s2,a0
    8000554a:	12050f63          	beqz	a0,80005688 <create+0x164>
    return 0;

  ilock(dp);
    8000554e:	ffffe097          	auipc	ra,0xffffe
    80005552:	644080e7          	jalr	1604(ra) # 80003b92 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005556:	4601                	li	a2,0
    80005558:	fb040593          	addi	a1,s0,-80
    8000555c:	854a                	mv	a0,s2
    8000555e:	fffff097          	auipc	ra,0xfffff
    80005562:	b16080e7          	jalr	-1258(ra) # 80004074 <dirlookup>
    80005566:	84aa                	mv	s1,a0
    80005568:	c921                	beqz	a0,800055b8 <create+0x94>
    iunlockput(dp);
    8000556a:	854a                	mv	a0,s2
    8000556c:	fffff097          	auipc	ra,0xfffff
    80005570:	888080e7          	jalr	-1912(ra) # 80003df4 <iunlockput>
    ilock(ip);
    80005574:	8526                	mv	a0,s1
    80005576:	ffffe097          	auipc	ra,0xffffe
    8000557a:	61c080e7          	jalr	1564(ra) # 80003b92 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000557e:	2981                	sext.w	s3,s3
    80005580:	4789                	li	a5,2
    80005582:	02f99463          	bne	s3,a5,800055aa <create+0x86>
    80005586:	04c4d783          	lhu	a5,76(s1)
    8000558a:	37f9                	addiw	a5,a5,-2
    8000558c:	17c2                	slli	a5,a5,0x30
    8000558e:	93c1                	srli	a5,a5,0x30
    80005590:	4705                	li	a4,1
    80005592:	00f76c63          	bltu	a4,a5,800055aa <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005596:	8526                	mv	a0,s1
    80005598:	60a6                	ld	ra,72(sp)
    8000559a:	6406                	ld	s0,64(sp)
    8000559c:	74e2                	ld	s1,56(sp)
    8000559e:	7942                	ld	s2,48(sp)
    800055a0:	79a2                	ld	s3,40(sp)
    800055a2:	7a02                	ld	s4,32(sp)
    800055a4:	6ae2                	ld	s5,24(sp)
    800055a6:	6161                	addi	sp,sp,80
    800055a8:	8082                	ret
    iunlockput(ip);
    800055aa:	8526                	mv	a0,s1
    800055ac:	fffff097          	auipc	ra,0xfffff
    800055b0:	848080e7          	jalr	-1976(ra) # 80003df4 <iunlockput>
    return 0;
    800055b4:	4481                	li	s1,0
    800055b6:	b7c5                	j	80005596 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    800055b8:	85ce                	mv	a1,s3
    800055ba:	00092503          	lw	a0,0(s2)
    800055be:	ffffe097          	auipc	ra,0xffffe
    800055c2:	43c080e7          	jalr	1084(ra) # 800039fa <ialloc>
    800055c6:	84aa                	mv	s1,a0
    800055c8:	c529                	beqz	a0,80005612 <create+0xee>
  ilock(ip);
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	5c8080e7          	jalr	1480(ra) # 80003b92 <ilock>
  ip->major = major;
    800055d2:	05549723          	sh	s5,78(s1)
  ip->minor = minor;
    800055d6:	05449823          	sh	s4,80(s1)
  ip->nlink = 1;
    800055da:	4785                	li	a5,1
    800055dc:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800055e0:	8526                	mv	a0,s1
    800055e2:	ffffe097          	auipc	ra,0xffffe
    800055e6:	4e6080e7          	jalr	1254(ra) # 80003ac8 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800055ea:	2981                	sext.w	s3,s3
    800055ec:	4785                	li	a5,1
    800055ee:	02f98a63          	beq	s3,a5,80005622 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800055f2:	40d0                	lw	a2,4(s1)
    800055f4:	fb040593          	addi	a1,s0,-80
    800055f8:	854a                	mv	a0,s2
    800055fa:	fffff097          	auipc	ra,0xfffff
    800055fe:	c8a080e7          	jalr	-886(ra) # 80004284 <dirlink>
    80005602:	06054b63          	bltz	a0,80005678 <create+0x154>
  iunlockput(dp);
    80005606:	854a                	mv	a0,s2
    80005608:	ffffe097          	auipc	ra,0xffffe
    8000560c:	7ec080e7          	jalr	2028(ra) # 80003df4 <iunlockput>
  return ip;
    80005610:	b759                	j	80005596 <create+0x72>
    panic("create: ialloc");
    80005612:	00003517          	auipc	a0,0x3
    80005616:	15e50513          	addi	a0,a0,350 # 80008770 <syscalls+0x2b8>
    8000561a:	ffffb097          	auipc	ra,0xffffb
    8000561e:	f36080e7          	jalr	-202(ra) # 80000550 <panic>
    dp->nlink++;  // for ".."
    80005622:	05295783          	lhu	a5,82(s2)
    80005626:	2785                	addiw	a5,a5,1
    80005628:	04f91923          	sh	a5,82(s2)
    iupdate(dp);
    8000562c:	854a                	mv	a0,s2
    8000562e:	ffffe097          	auipc	ra,0xffffe
    80005632:	49a080e7          	jalr	1178(ra) # 80003ac8 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005636:	40d0                	lw	a2,4(s1)
    80005638:	00003597          	auipc	a1,0x3
    8000563c:	14858593          	addi	a1,a1,328 # 80008780 <syscalls+0x2c8>
    80005640:	8526                	mv	a0,s1
    80005642:	fffff097          	auipc	ra,0xfffff
    80005646:	c42080e7          	jalr	-958(ra) # 80004284 <dirlink>
    8000564a:	00054f63          	bltz	a0,80005668 <create+0x144>
    8000564e:	00492603          	lw	a2,4(s2)
    80005652:	00003597          	auipc	a1,0x3
    80005656:	13658593          	addi	a1,a1,310 # 80008788 <syscalls+0x2d0>
    8000565a:	8526                	mv	a0,s1
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	c28080e7          	jalr	-984(ra) # 80004284 <dirlink>
    80005664:	f80557e3          	bgez	a0,800055f2 <create+0xce>
      panic("create dots");
    80005668:	00003517          	auipc	a0,0x3
    8000566c:	12850513          	addi	a0,a0,296 # 80008790 <syscalls+0x2d8>
    80005670:	ffffb097          	auipc	ra,0xffffb
    80005674:	ee0080e7          	jalr	-288(ra) # 80000550 <panic>
    panic("create: dirlink");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	12850513          	addi	a0,a0,296 # 800087a0 <syscalls+0x2e8>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	ed0080e7          	jalr	-304(ra) # 80000550 <panic>
    return 0;
    80005688:	84aa                	mv	s1,a0
    8000568a:	b731                	j	80005596 <create+0x72>

000000008000568c <sys_dup>:
{
    8000568c:	7179                	addi	sp,sp,-48
    8000568e:	f406                	sd	ra,40(sp)
    80005690:	f022                	sd	s0,32(sp)
    80005692:	ec26                	sd	s1,24(sp)
    80005694:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005696:	fd840613          	addi	a2,s0,-40
    8000569a:	4581                	li	a1,0
    8000569c:	4501                	li	a0,0
    8000569e:	00000097          	auipc	ra,0x0
    800056a2:	ddc080e7          	jalr	-548(ra) # 8000547a <argfd>
    return -1;
    800056a6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800056a8:	02054363          	bltz	a0,800056ce <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    800056ac:	fd843503          	ld	a0,-40(s0)
    800056b0:	00000097          	auipc	ra,0x0
    800056b4:	e32080e7          	jalr	-462(ra) # 800054e2 <fdalloc>
    800056b8:	84aa                	mv	s1,a0
    return -1;
    800056ba:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800056bc:	00054963          	bltz	a0,800056ce <sys_dup+0x42>
  filedup(f);
    800056c0:	fd843503          	ld	a0,-40(s0)
    800056c4:	fffff097          	auipc	ra,0xfffff
    800056c8:	320080e7          	jalr	800(ra) # 800049e4 <filedup>
  return fd;
    800056cc:	87a6                	mv	a5,s1
}
    800056ce:	853e                	mv	a0,a5
    800056d0:	70a2                	ld	ra,40(sp)
    800056d2:	7402                	ld	s0,32(sp)
    800056d4:	64e2                	ld	s1,24(sp)
    800056d6:	6145                	addi	sp,sp,48
    800056d8:	8082                	ret

00000000800056da <sys_read>:
{
    800056da:	7179                	addi	sp,sp,-48
    800056dc:	f406                	sd	ra,40(sp)
    800056de:	f022                	sd	s0,32(sp)
    800056e0:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056e2:	fe840613          	addi	a2,s0,-24
    800056e6:	4581                	li	a1,0
    800056e8:	4501                	li	a0,0
    800056ea:	00000097          	auipc	ra,0x0
    800056ee:	d90080e7          	jalr	-624(ra) # 8000547a <argfd>
    return -1;
    800056f2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056f4:	04054163          	bltz	a0,80005736 <sys_read+0x5c>
    800056f8:	fe440593          	addi	a1,s0,-28
    800056fc:	4509                	li	a0,2
    800056fe:	ffffd097          	auipc	ra,0xffffd
    80005702:	768080e7          	jalr	1896(ra) # 80002e66 <argint>
    return -1;
    80005706:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005708:	02054763          	bltz	a0,80005736 <sys_read+0x5c>
    8000570c:	fd840593          	addi	a1,s0,-40
    80005710:	4505                	li	a0,1
    80005712:	ffffd097          	auipc	ra,0xffffd
    80005716:	776080e7          	jalr	1910(ra) # 80002e88 <argaddr>
    return -1;
    8000571a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000571c:	00054d63          	bltz	a0,80005736 <sys_read+0x5c>
  return fileread(f, p, n);
    80005720:	fe442603          	lw	a2,-28(s0)
    80005724:	fd843583          	ld	a1,-40(s0)
    80005728:	fe843503          	ld	a0,-24(s0)
    8000572c:	fffff097          	auipc	ra,0xfffff
    80005730:	444080e7          	jalr	1092(ra) # 80004b70 <fileread>
    80005734:	87aa                	mv	a5,a0
}
    80005736:	853e                	mv	a0,a5
    80005738:	70a2                	ld	ra,40(sp)
    8000573a:	7402                	ld	s0,32(sp)
    8000573c:	6145                	addi	sp,sp,48
    8000573e:	8082                	ret

0000000080005740 <sys_write>:
{
    80005740:	7179                	addi	sp,sp,-48
    80005742:	f406                	sd	ra,40(sp)
    80005744:	f022                	sd	s0,32(sp)
    80005746:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005748:	fe840613          	addi	a2,s0,-24
    8000574c:	4581                	li	a1,0
    8000574e:	4501                	li	a0,0
    80005750:	00000097          	auipc	ra,0x0
    80005754:	d2a080e7          	jalr	-726(ra) # 8000547a <argfd>
    return -1;
    80005758:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000575a:	04054163          	bltz	a0,8000579c <sys_write+0x5c>
    8000575e:	fe440593          	addi	a1,s0,-28
    80005762:	4509                	li	a0,2
    80005764:	ffffd097          	auipc	ra,0xffffd
    80005768:	702080e7          	jalr	1794(ra) # 80002e66 <argint>
    return -1;
    8000576c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000576e:	02054763          	bltz	a0,8000579c <sys_write+0x5c>
    80005772:	fd840593          	addi	a1,s0,-40
    80005776:	4505                	li	a0,1
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	710080e7          	jalr	1808(ra) # 80002e88 <argaddr>
    return -1;
    80005780:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005782:	00054d63          	bltz	a0,8000579c <sys_write+0x5c>
  return filewrite(f, p, n);
    80005786:	fe442603          	lw	a2,-28(s0)
    8000578a:	fd843583          	ld	a1,-40(s0)
    8000578e:	fe843503          	ld	a0,-24(s0)
    80005792:	fffff097          	auipc	ra,0xfffff
    80005796:	4a0080e7          	jalr	1184(ra) # 80004c32 <filewrite>
    8000579a:	87aa                	mv	a5,a0
}
    8000579c:	853e                	mv	a0,a5
    8000579e:	70a2                	ld	ra,40(sp)
    800057a0:	7402                	ld	s0,32(sp)
    800057a2:	6145                	addi	sp,sp,48
    800057a4:	8082                	ret

00000000800057a6 <sys_close>:
{
    800057a6:	1101                	addi	sp,sp,-32
    800057a8:	ec06                	sd	ra,24(sp)
    800057aa:	e822                	sd	s0,16(sp)
    800057ac:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800057ae:	fe040613          	addi	a2,s0,-32
    800057b2:	fec40593          	addi	a1,s0,-20
    800057b6:	4501                	li	a0,0
    800057b8:	00000097          	auipc	ra,0x0
    800057bc:	cc2080e7          	jalr	-830(ra) # 8000547a <argfd>
    return -1;
    800057c0:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800057c2:	02054463          	bltz	a0,800057ea <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800057c6:	ffffc097          	auipc	ra,0xffffc
    800057ca:	5e2080e7          	jalr	1506(ra) # 80001da8 <myproc>
    800057ce:	fec42783          	lw	a5,-20(s0)
    800057d2:	07e9                	addi	a5,a5,26
    800057d4:	078e                	slli	a5,a5,0x3
    800057d6:	97aa                	add	a5,a5,a0
    800057d8:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    800057dc:	fe043503          	ld	a0,-32(s0)
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	256080e7          	jalr	598(ra) # 80004a36 <fileclose>
  return 0;
    800057e8:	4781                	li	a5,0
}
    800057ea:	853e                	mv	a0,a5
    800057ec:	60e2                	ld	ra,24(sp)
    800057ee:	6442                	ld	s0,16(sp)
    800057f0:	6105                	addi	sp,sp,32
    800057f2:	8082                	ret

00000000800057f4 <sys_fstat>:
{
    800057f4:	1101                	addi	sp,sp,-32
    800057f6:	ec06                	sd	ra,24(sp)
    800057f8:	e822                	sd	s0,16(sp)
    800057fa:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057fc:	fe840613          	addi	a2,s0,-24
    80005800:	4581                	li	a1,0
    80005802:	4501                	li	a0,0
    80005804:	00000097          	auipc	ra,0x0
    80005808:	c76080e7          	jalr	-906(ra) # 8000547a <argfd>
    return -1;
    8000580c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000580e:	02054563          	bltz	a0,80005838 <sys_fstat+0x44>
    80005812:	fe040593          	addi	a1,s0,-32
    80005816:	4505                	li	a0,1
    80005818:	ffffd097          	auipc	ra,0xffffd
    8000581c:	670080e7          	jalr	1648(ra) # 80002e88 <argaddr>
    return -1;
    80005820:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005822:	00054b63          	bltz	a0,80005838 <sys_fstat+0x44>
  return filestat(f, st);
    80005826:	fe043583          	ld	a1,-32(s0)
    8000582a:	fe843503          	ld	a0,-24(s0)
    8000582e:	fffff097          	auipc	ra,0xfffff
    80005832:	2d0080e7          	jalr	720(ra) # 80004afe <filestat>
    80005836:	87aa                	mv	a5,a0
}
    80005838:	853e                	mv	a0,a5
    8000583a:	60e2                	ld	ra,24(sp)
    8000583c:	6442                	ld	s0,16(sp)
    8000583e:	6105                	addi	sp,sp,32
    80005840:	8082                	ret

0000000080005842 <sys_link>:
{
    80005842:	7169                	addi	sp,sp,-304
    80005844:	f606                	sd	ra,296(sp)
    80005846:	f222                	sd	s0,288(sp)
    80005848:	ee26                	sd	s1,280(sp)
    8000584a:	ea4a                	sd	s2,272(sp)
    8000584c:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000584e:	08000613          	li	a2,128
    80005852:	ed040593          	addi	a1,s0,-304
    80005856:	4501                	li	a0,0
    80005858:	ffffd097          	auipc	ra,0xffffd
    8000585c:	652080e7          	jalr	1618(ra) # 80002eaa <argstr>
    return -1;
    80005860:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005862:	10054e63          	bltz	a0,8000597e <sys_link+0x13c>
    80005866:	08000613          	li	a2,128
    8000586a:	f5040593          	addi	a1,s0,-176
    8000586e:	4505                	li	a0,1
    80005870:	ffffd097          	auipc	ra,0xffffd
    80005874:	63a080e7          	jalr	1594(ra) # 80002eaa <argstr>
    return -1;
    80005878:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000587a:	10054263          	bltz	a0,8000597e <sys_link+0x13c>
  begin_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	ce4080e7          	jalr	-796(ra) # 80004562 <begin_op>
  if((ip = namei(old)) == 0){
    80005886:	ed040513          	addi	a0,s0,-304
    8000588a:	fffff097          	auipc	ra,0xfffff
    8000588e:	abc080e7          	jalr	-1348(ra) # 80004346 <namei>
    80005892:	84aa                	mv	s1,a0
    80005894:	c551                	beqz	a0,80005920 <sys_link+0xde>
  ilock(ip);
    80005896:	ffffe097          	auipc	ra,0xffffe
    8000589a:	2fc080e7          	jalr	764(ra) # 80003b92 <ilock>
  if(ip->type == T_DIR){
    8000589e:	04c49703          	lh	a4,76(s1)
    800058a2:	4785                	li	a5,1
    800058a4:	08f70463          	beq	a4,a5,8000592c <sys_link+0xea>
  ip->nlink++;
    800058a8:	0524d783          	lhu	a5,82(s1)
    800058ac:	2785                	addiw	a5,a5,1
    800058ae:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    800058b2:	8526                	mv	a0,s1
    800058b4:	ffffe097          	auipc	ra,0xffffe
    800058b8:	214080e7          	jalr	532(ra) # 80003ac8 <iupdate>
  iunlock(ip);
    800058bc:	8526                	mv	a0,s1
    800058be:	ffffe097          	auipc	ra,0xffffe
    800058c2:	396080e7          	jalr	918(ra) # 80003c54 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800058c6:	fd040593          	addi	a1,s0,-48
    800058ca:	f5040513          	addi	a0,s0,-176
    800058ce:	fffff097          	auipc	ra,0xfffff
    800058d2:	a96080e7          	jalr	-1386(ra) # 80004364 <nameiparent>
    800058d6:	892a                	mv	s2,a0
    800058d8:	c935                	beqz	a0,8000594c <sys_link+0x10a>
  ilock(dp);
    800058da:	ffffe097          	auipc	ra,0xffffe
    800058de:	2b8080e7          	jalr	696(ra) # 80003b92 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800058e2:	00092703          	lw	a4,0(s2)
    800058e6:	409c                	lw	a5,0(s1)
    800058e8:	04f71d63          	bne	a4,a5,80005942 <sys_link+0x100>
    800058ec:	40d0                	lw	a2,4(s1)
    800058ee:	fd040593          	addi	a1,s0,-48
    800058f2:	854a                	mv	a0,s2
    800058f4:	fffff097          	auipc	ra,0xfffff
    800058f8:	990080e7          	jalr	-1648(ra) # 80004284 <dirlink>
    800058fc:	04054363          	bltz	a0,80005942 <sys_link+0x100>
  iunlockput(dp);
    80005900:	854a                	mv	a0,s2
    80005902:	ffffe097          	auipc	ra,0xffffe
    80005906:	4f2080e7          	jalr	1266(ra) # 80003df4 <iunlockput>
  iput(ip);
    8000590a:	8526                	mv	a0,s1
    8000590c:	ffffe097          	auipc	ra,0xffffe
    80005910:	440080e7          	jalr	1088(ra) # 80003d4c <iput>
  end_op();
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	cce080e7          	jalr	-818(ra) # 800045e2 <end_op>
  return 0;
    8000591c:	4781                	li	a5,0
    8000591e:	a085                	j	8000597e <sys_link+0x13c>
    end_op();
    80005920:	fffff097          	auipc	ra,0xfffff
    80005924:	cc2080e7          	jalr	-830(ra) # 800045e2 <end_op>
    return -1;
    80005928:	57fd                	li	a5,-1
    8000592a:	a891                	j	8000597e <sys_link+0x13c>
    iunlockput(ip);
    8000592c:	8526                	mv	a0,s1
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	4c6080e7          	jalr	1222(ra) # 80003df4 <iunlockput>
    end_op();
    80005936:	fffff097          	auipc	ra,0xfffff
    8000593a:	cac080e7          	jalr	-852(ra) # 800045e2 <end_op>
    return -1;
    8000593e:	57fd                	li	a5,-1
    80005940:	a83d                	j	8000597e <sys_link+0x13c>
    iunlockput(dp);
    80005942:	854a                	mv	a0,s2
    80005944:	ffffe097          	auipc	ra,0xffffe
    80005948:	4b0080e7          	jalr	1200(ra) # 80003df4 <iunlockput>
  ilock(ip);
    8000594c:	8526                	mv	a0,s1
    8000594e:	ffffe097          	auipc	ra,0xffffe
    80005952:	244080e7          	jalr	580(ra) # 80003b92 <ilock>
  ip->nlink--;
    80005956:	0524d783          	lhu	a5,82(s1)
    8000595a:	37fd                	addiw	a5,a5,-1
    8000595c:	04f49923          	sh	a5,82(s1)
  iupdate(ip);
    80005960:	8526                	mv	a0,s1
    80005962:	ffffe097          	auipc	ra,0xffffe
    80005966:	166080e7          	jalr	358(ra) # 80003ac8 <iupdate>
  iunlockput(ip);
    8000596a:	8526                	mv	a0,s1
    8000596c:	ffffe097          	auipc	ra,0xffffe
    80005970:	488080e7          	jalr	1160(ra) # 80003df4 <iunlockput>
  end_op();
    80005974:	fffff097          	auipc	ra,0xfffff
    80005978:	c6e080e7          	jalr	-914(ra) # 800045e2 <end_op>
  return -1;
    8000597c:	57fd                	li	a5,-1
}
    8000597e:	853e                	mv	a0,a5
    80005980:	70b2                	ld	ra,296(sp)
    80005982:	7412                	ld	s0,288(sp)
    80005984:	64f2                	ld	s1,280(sp)
    80005986:	6952                	ld	s2,272(sp)
    80005988:	6155                	addi	sp,sp,304
    8000598a:	8082                	ret

000000008000598c <sys_unlink>:
{
    8000598c:	7151                	addi	sp,sp,-240
    8000598e:	f586                	sd	ra,232(sp)
    80005990:	f1a2                	sd	s0,224(sp)
    80005992:	eda6                	sd	s1,216(sp)
    80005994:	e9ca                	sd	s2,208(sp)
    80005996:	e5ce                	sd	s3,200(sp)
    80005998:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000599a:	08000613          	li	a2,128
    8000599e:	f3040593          	addi	a1,s0,-208
    800059a2:	4501                	li	a0,0
    800059a4:	ffffd097          	auipc	ra,0xffffd
    800059a8:	506080e7          	jalr	1286(ra) # 80002eaa <argstr>
    800059ac:	18054163          	bltz	a0,80005b2e <sys_unlink+0x1a2>
  begin_op();
    800059b0:	fffff097          	auipc	ra,0xfffff
    800059b4:	bb2080e7          	jalr	-1102(ra) # 80004562 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800059b8:	fb040593          	addi	a1,s0,-80
    800059bc:	f3040513          	addi	a0,s0,-208
    800059c0:	fffff097          	auipc	ra,0xfffff
    800059c4:	9a4080e7          	jalr	-1628(ra) # 80004364 <nameiparent>
    800059c8:	84aa                	mv	s1,a0
    800059ca:	c979                	beqz	a0,80005aa0 <sys_unlink+0x114>
  ilock(dp);
    800059cc:	ffffe097          	auipc	ra,0xffffe
    800059d0:	1c6080e7          	jalr	454(ra) # 80003b92 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800059d4:	00003597          	auipc	a1,0x3
    800059d8:	dac58593          	addi	a1,a1,-596 # 80008780 <syscalls+0x2c8>
    800059dc:	fb040513          	addi	a0,s0,-80
    800059e0:	ffffe097          	auipc	ra,0xffffe
    800059e4:	67a080e7          	jalr	1658(ra) # 8000405a <namecmp>
    800059e8:	14050a63          	beqz	a0,80005b3c <sys_unlink+0x1b0>
    800059ec:	00003597          	auipc	a1,0x3
    800059f0:	d9c58593          	addi	a1,a1,-612 # 80008788 <syscalls+0x2d0>
    800059f4:	fb040513          	addi	a0,s0,-80
    800059f8:	ffffe097          	auipc	ra,0xffffe
    800059fc:	662080e7          	jalr	1634(ra) # 8000405a <namecmp>
    80005a00:	12050e63          	beqz	a0,80005b3c <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005a04:	f2c40613          	addi	a2,s0,-212
    80005a08:	fb040593          	addi	a1,s0,-80
    80005a0c:	8526                	mv	a0,s1
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	666080e7          	jalr	1638(ra) # 80004074 <dirlookup>
    80005a16:	892a                	mv	s2,a0
    80005a18:	12050263          	beqz	a0,80005b3c <sys_unlink+0x1b0>
  ilock(ip);
    80005a1c:	ffffe097          	auipc	ra,0xffffe
    80005a20:	176080e7          	jalr	374(ra) # 80003b92 <ilock>
  if(ip->nlink < 1)
    80005a24:	05291783          	lh	a5,82(s2)
    80005a28:	08f05263          	blez	a5,80005aac <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005a2c:	04c91703          	lh	a4,76(s2)
    80005a30:	4785                	li	a5,1
    80005a32:	08f70563          	beq	a4,a5,80005abc <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005a36:	4641                	li	a2,16
    80005a38:	4581                	li	a1,0
    80005a3a:	fc040513          	addi	a0,s0,-64
    80005a3e:	ffffb097          	auipc	ra,0xffffb
    80005a42:	702080e7          	jalr	1794(ra) # 80001140 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a46:	4741                	li	a4,16
    80005a48:	f2c42683          	lw	a3,-212(s0)
    80005a4c:	fc040613          	addi	a2,s0,-64
    80005a50:	4581                	li	a1,0
    80005a52:	8526                	mv	a0,s1
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	4ea080e7          	jalr	1258(ra) # 80003f3e <writei>
    80005a5c:	47c1                	li	a5,16
    80005a5e:	0af51563          	bne	a0,a5,80005b08 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005a62:	04c91703          	lh	a4,76(s2)
    80005a66:	4785                	li	a5,1
    80005a68:	0af70863          	beq	a4,a5,80005b18 <sys_unlink+0x18c>
  iunlockput(dp);
    80005a6c:	8526                	mv	a0,s1
    80005a6e:	ffffe097          	auipc	ra,0xffffe
    80005a72:	386080e7          	jalr	902(ra) # 80003df4 <iunlockput>
  ip->nlink--;
    80005a76:	05295783          	lhu	a5,82(s2)
    80005a7a:	37fd                	addiw	a5,a5,-1
    80005a7c:	04f91923          	sh	a5,82(s2)
  iupdate(ip);
    80005a80:	854a                	mv	a0,s2
    80005a82:	ffffe097          	auipc	ra,0xffffe
    80005a86:	046080e7          	jalr	70(ra) # 80003ac8 <iupdate>
  iunlockput(ip);
    80005a8a:	854a                	mv	a0,s2
    80005a8c:	ffffe097          	auipc	ra,0xffffe
    80005a90:	368080e7          	jalr	872(ra) # 80003df4 <iunlockput>
  end_op();
    80005a94:	fffff097          	auipc	ra,0xfffff
    80005a98:	b4e080e7          	jalr	-1202(ra) # 800045e2 <end_op>
  return 0;
    80005a9c:	4501                	li	a0,0
    80005a9e:	a84d                	j	80005b50 <sys_unlink+0x1c4>
    end_op();
    80005aa0:	fffff097          	auipc	ra,0xfffff
    80005aa4:	b42080e7          	jalr	-1214(ra) # 800045e2 <end_op>
    return -1;
    80005aa8:	557d                	li	a0,-1
    80005aaa:	a05d                	j	80005b50 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005aac:	00003517          	auipc	a0,0x3
    80005ab0:	d0450513          	addi	a0,a0,-764 # 800087b0 <syscalls+0x2f8>
    80005ab4:	ffffb097          	auipc	ra,0xffffb
    80005ab8:	a9c080e7          	jalr	-1380(ra) # 80000550 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005abc:	05492703          	lw	a4,84(s2)
    80005ac0:	02000793          	li	a5,32
    80005ac4:	f6e7f9e3          	bgeu	a5,a4,80005a36 <sys_unlink+0xaa>
    80005ac8:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005acc:	4741                	li	a4,16
    80005ace:	86ce                	mv	a3,s3
    80005ad0:	f1840613          	addi	a2,s0,-232
    80005ad4:	4581                	li	a1,0
    80005ad6:	854a                	mv	a0,s2
    80005ad8:	ffffe097          	auipc	ra,0xffffe
    80005adc:	36e080e7          	jalr	878(ra) # 80003e46 <readi>
    80005ae0:	47c1                	li	a5,16
    80005ae2:	00f51b63          	bne	a0,a5,80005af8 <sys_unlink+0x16c>
    if(de.inum != 0)
    80005ae6:	f1845783          	lhu	a5,-232(s0)
    80005aea:	e7a1                	bnez	a5,80005b32 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005aec:	29c1                	addiw	s3,s3,16
    80005aee:	05492783          	lw	a5,84(s2)
    80005af2:	fcf9ede3          	bltu	s3,a5,80005acc <sys_unlink+0x140>
    80005af6:	b781                	j	80005a36 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005af8:	00003517          	auipc	a0,0x3
    80005afc:	cd050513          	addi	a0,a0,-816 # 800087c8 <syscalls+0x310>
    80005b00:	ffffb097          	auipc	ra,0xffffb
    80005b04:	a50080e7          	jalr	-1456(ra) # 80000550 <panic>
    panic("unlink: writei");
    80005b08:	00003517          	auipc	a0,0x3
    80005b0c:	cd850513          	addi	a0,a0,-808 # 800087e0 <syscalls+0x328>
    80005b10:	ffffb097          	auipc	ra,0xffffb
    80005b14:	a40080e7          	jalr	-1472(ra) # 80000550 <panic>
    dp->nlink--;
    80005b18:	0524d783          	lhu	a5,82(s1)
    80005b1c:	37fd                	addiw	a5,a5,-1
    80005b1e:	04f49923          	sh	a5,82(s1)
    iupdate(dp);
    80005b22:	8526                	mv	a0,s1
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	fa4080e7          	jalr	-92(ra) # 80003ac8 <iupdate>
    80005b2c:	b781                	j	80005a6c <sys_unlink+0xe0>
    return -1;
    80005b2e:	557d                	li	a0,-1
    80005b30:	a005                	j	80005b50 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005b32:	854a                	mv	a0,s2
    80005b34:	ffffe097          	auipc	ra,0xffffe
    80005b38:	2c0080e7          	jalr	704(ra) # 80003df4 <iunlockput>
  iunlockput(dp);
    80005b3c:	8526                	mv	a0,s1
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	2b6080e7          	jalr	694(ra) # 80003df4 <iunlockput>
  end_op();
    80005b46:	fffff097          	auipc	ra,0xfffff
    80005b4a:	a9c080e7          	jalr	-1380(ra) # 800045e2 <end_op>
  return -1;
    80005b4e:	557d                	li	a0,-1
}
    80005b50:	70ae                	ld	ra,232(sp)
    80005b52:	740e                	ld	s0,224(sp)
    80005b54:	64ee                	ld	s1,216(sp)
    80005b56:	694e                	ld	s2,208(sp)
    80005b58:	69ae                	ld	s3,200(sp)
    80005b5a:	616d                	addi	sp,sp,240
    80005b5c:	8082                	ret

0000000080005b5e <sys_open>:

uint64
sys_open(void)
{
    80005b5e:	7131                	addi	sp,sp,-192
    80005b60:	fd06                	sd	ra,184(sp)
    80005b62:	f922                	sd	s0,176(sp)
    80005b64:	f526                	sd	s1,168(sp)
    80005b66:	f14a                	sd	s2,160(sp)
    80005b68:	ed4e                	sd	s3,152(sp)
    80005b6a:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b6c:	08000613          	li	a2,128
    80005b70:	f5040593          	addi	a1,s0,-176
    80005b74:	4501                	li	a0,0
    80005b76:	ffffd097          	auipc	ra,0xffffd
    80005b7a:	334080e7          	jalr	820(ra) # 80002eaa <argstr>
    return -1;
    80005b7e:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b80:	0c054163          	bltz	a0,80005c42 <sys_open+0xe4>
    80005b84:	f4c40593          	addi	a1,s0,-180
    80005b88:	4505                	li	a0,1
    80005b8a:	ffffd097          	auipc	ra,0xffffd
    80005b8e:	2dc080e7          	jalr	732(ra) # 80002e66 <argint>
    80005b92:	0a054863          	bltz	a0,80005c42 <sys_open+0xe4>

  begin_op();
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	9cc080e7          	jalr	-1588(ra) # 80004562 <begin_op>

  if(omode & O_CREATE){
    80005b9e:	f4c42783          	lw	a5,-180(s0)
    80005ba2:	2007f793          	andi	a5,a5,512
    80005ba6:	cbdd                	beqz	a5,80005c5c <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005ba8:	4681                	li	a3,0
    80005baa:	4601                	li	a2,0
    80005bac:	4589                	li	a1,2
    80005bae:	f5040513          	addi	a0,s0,-176
    80005bb2:	00000097          	auipc	ra,0x0
    80005bb6:	972080e7          	jalr	-1678(ra) # 80005524 <create>
    80005bba:	892a                	mv	s2,a0
    if(ip == 0){
    80005bbc:	c959                	beqz	a0,80005c52 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005bbe:	04c91703          	lh	a4,76(s2)
    80005bc2:	478d                	li	a5,3
    80005bc4:	00f71763          	bne	a4,a5,80005bd2 <sys_open+0x74>
    80005bc8:	04e95703          	lhu	a4,78(s2)
    80005bcc:	47a5                	li	a5,9
    80005bce:	0ce7ec63          	bltu	a5,a4,80005ca6 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005bd2:	fffff097          	auipc	ra,0xfffff
    80005bd6:	da8080e7          	jalr	-600(ra) # 8000497a <filealloc>
    80005bda:	89aa                	mv	s3,a0
    80005bdc:	10050263          	beqz	a0,80005ce0 <sys_open+0x182>
    80005be0:	00000097          	auipc	ra,0x0
    80005be4:	902080e7          	jalr	-1790(ra) # 800054e2 <fdalloc>
    80005be8:	84aa                	mv	s1,a0
    80005bea:	0e054663          	bltz	a0,80005cd6 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005bee:	04c91703          	lh	a4,76(s2)
    80005bf2:	478d                	li	a5,3
    80005bf4:	0cf70463          	beq	a4,a5,80005cbc <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005bf8:	4789                	li	a5,2
    80005bfa:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005bfe:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005c02:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005c06:	f4c42783          	lw	a5,-180(s0)
    80005c0a:	0017c713          	xori	a4,a5,1
    80005c0e:	8b05                	andi	a4,a4,1
    80005c10:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005c14:	0037f713          	andi	a4,a5,3
    80005c18:	00e03733          	snez	a4,a4
    80005c1c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005c20:	4007f793          	andi	a5,a5,1024
    80005c24:	c791                	beqz	a5,80005c30 <sys_open+0xd2>
    80005c26:	04c91703          	lh	a4,76(s2)
    80005c2a:	4789                	li	a5,2
    80005c2c:	08f70f63          	beq	a4,a5,80005cca <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005c30:	854a                	mv	a0,s2
    80005c32:	ffffe097          	auipc	ra,0xffffe
    80005c36:	022080e7          	jalr	34(ra) # 80003c54 <iunlock>
  end_op();
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	9a8080e7          	jalr	-1624(ra) # 800045e2 <end_op>

  return fd;
}
    80005c42:	8526                	mv	a0,s1
    80005c44:	70ea                	ld	ra,184(sp)
    80005c46:	744a                	ld	s0,176(sp)
    80005c48:	74aa                	ld	s1,168(sp)
    80005c4a:	790a                	ld	s2,160(sp)
    80005c4c:	69ea                	ld	s3,152(sp)
    80005c4e:	6129                	addi	sp,sp,192
    80005c50:	8082                	ret
      end_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	990080e7          	jalr	-1648(ra) # 800045e2 <end_op>
      return -1;
    80005c5a:	b7e5                	j	80005c42 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005c5c:	f5040513          	addi	a0,s0,-176
    80005c60:	ffffe097          	auipc	ra,0xffffe
    80005c64:	6e6080e7          	jalr	1766(ra) # 80004346 <namei>
    80005c68:	892a                	mv	s2,a0
    80005c6a:	c905                	beqz	a0,80005c9a <sys_open+0x13c>
    ilock(ip);
    80005c6c:	ffffe097          	auipc	ra,0xffffe
    80005c70:	f26080e7          	jalr	-218(ra) # 80003b92 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c74:	04c91703          	lh	a4,76(s2)
    80005c78:	4785                	li	a5,1
    80005c7a:	f4f712e3          	bne	a4,a5,80005bbe <sys_open+0x60>
    80005c7e:	f4c42783          	lw	a5,-180(s0)
    80005c82:	dba1                	beqz	a5,80005bd2 <sys_open+0x74>
      iunlockput(ip);
    80005c84:	854a                	mv	a0,s2
    80005c86:	ffffe097          	auipc	ra,0xffffe
    80005c8a:	16e080e7          	jalr	366(ra) # 80003df4 <iunlockput>
      end_op();
    80005c8e:	fffff097          	auipc	ra,0xfffff
    80005c92:	954080e7          	jalr	-1708(ra) # 800045e2 <end_op>
      return -1;
    80005c96:	54fd                	li	s1,-1
    80005c98:	b76d                	j	80005c42 <sys_open+0xe4>
      end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	948080e7          	jalr	-1720(ra) # 800045e2 <end_op>
      return -1;
    80005ca2:	54fd                	li	s1,-1
    80005ca4:	bf79                	j	80005c42 <sys_open+0xe4>
    iunlockput(ip);
    80005ca6:	854a                	mv	a0,s2
    80005ca8:	ffffe097          	auipc	ra,0xffffe
    80005cac:	14c080e7          	jalr	332(ra) # 80003df4 <iunlockput>
    end_op();
    80005cb0:	fffff097          	auipc	ra,0xfffff
    80005cb4:	932080e7          	jalr	-1742(ra) # 800045e2 <end_op>
    return -1;
    80005cb8:	54fd                	li	s1,-1
    80005cba:	b761                	j	80005c42 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005cbc:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005cc0:	04e91783          	lh	a5,78(s2)
    80005cc4:	02f99223          	sh	a5,36(s3)
    80005cc8:	bf2d                	j	80005c02 <sys_open+0xa4>
    itrunc(ip);
    80005cca:	854a                	mv	a0,s2
    80005ccc:	ffffe097          	auipc	ra,0xffffe
    80005cd0:	fd4080e7          	jalr	-44(ra) # 80003ca0 <itrunc>
    80005cd4:	bfb1                	j	80005c30 <sys_open+0xd2>
      fileclose(f);
    80005cd6:	854e                	mv	a0,s3
    80005cd8:	fffff097          	auipc	ra,0xfffff
    80005cdc:	d5e080e7          	jalr	-674(ra) # 80004a36 <fileclose>
    iunlockput(ip);
    80005ce0:	854a                	mv	a0,s2
    80005ce2:	ffffe097          	auipc	ra,0xffffe
    80005ce6:	112080e7          	jalr	274(ra) # 80003df4 <iunlockput>
    end_op();
    80005cea:	fffff097          	auipc	ra,0xfffff
    80005cee:	8f8080e7          	jalr	-1800(ra) # 800045e2 <end_op>
    return -1;
    80005cf2:	54fd                	li	s1,-1
    80005cf4:	b7b9                	j	80005c42 <sys_open+0xe4>

0000000080005cf6 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005cf6:	7175                	addi	sp,sp,-144
    80005cf8:	e506                	sd	ra,136(sp)
    80005cfa:	e122                	sd	s0,128(sp)
    80005cfc:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005cfe:	fffff097          	auipc	ra,0xfffff
    80005d02:	864080e7          	jalr	-1948(ra) # 80004562 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005d06:	08000613          	li	a2,128
    80005d0a:	f7040593          	addi	a1,s0,-144
    80005d0e:	4501                	li	a0,0
    80005d10:	ffffd097          	auipc	ra,0xffffd
    80005d14:	19a080e7          	jalr	410(ra) # 80002eaa <argstr>
    80005d18:	02054963          	bltz	a0,80005d4a <sys_mkdir+0x54>
    80005d1c:	4681                	li	a3,0
    80005d1e:	4601                	li	a2,0
    80005d20:	4585                	li	a1,1
    80005d22:	f7040513          	addi	a0,s0,-144
    80005d26:	fffff097          	auipc	ra,0xfffff
    80005d2a:	7fe080e7          	jalr	2046(ra) # 80005524 <create>
    80005d2e:	cd11                	beqz	a0,80005d4a <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d30:	ffffe097          	auipc	ra,0xffffe
    80005d34:	0c4080e7          	jalr	196(ra) # 80003df4 <iunlockput>
  end_op();
    80005d38:	fffff097          	auipc	ra,0xfffff
    80005d3c:	8aa080e7          	jalr	-1878(ra) # 800045e2 <end_op>
  return 0;
    80005d40:	4501                	li	a0,0
}
    80005d42:	60aa                	ld	ra,136(sp)
    80005d44:	640a                	ld	s0,128(sp)
    80005d46:	6149                	addi	sp,sp,144
    80005d48:	8082                	ret
    end_op();
    80005d4a:	fffff097          	auipc	ra,0xfffff
    80005d4e:	898080e7          	jalr	-1896(ra) # 800045e2 <end_op>
    return -1;
    80005d52:	557d                	li	a0,-1
    80005d54:	b7fd                	j	80005d42 <sys_mkdir+0x4c>

0000000080005d56 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005d56:	7135                	addi	sp,sp,-160
    80005d58:	ed06                	sd	ra,152(sp)
    80005d5a:	e922                	sd	s0,144(sp)
    80005d5c:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005d5e:	fffff097          	auipc	ra,0xfffff
    80005d62:	804080e7          	jalr	-2044(ra) # 80004562 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d66:	08000613          	li	a2,128
    80005d6a:	f7040593          	addi	a1,s0,-144
    80005d6e:	4501                	li	a0,0
    80005d70:	ffffd097          	auipc	ra,0xffffd
    80005d74:	13a080e7          	jalr	314(ra) # 80002eaa <argstr>
    80005d78:	04054a63          	bltz	a0,80005dcc <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d7c:	f6c40593          	addi	a1,s0,-148
    80005d80:	4505                	li	a0,1
    80005d82:	ffffd097          	auipc	ra,0xffffd
    80005d86:	0e4080e7          	jalr	228(ra) # 80002e66 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d8a:	04054163          	bltz	a0,80005dcc <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d8e:	f6840593          	addi	a1,s0,-152
    80005d92:	4509                	li	a0,2
    80005d94:	ffffd097          	auipc	ra,0xffffd
    80005d98:	0d2080e7          	jalr	210(ra) # 80002e66 <argint>
     argint(1, &major) < 0 ||
    80005d9c:	02054863          	bltz	a0,80005dcc <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005da0:	f6841683          	lh	a3,-152(s0)
    80005da4:	f6c41603          	lh	a2,-148(s0)
    80005da8:	458d                	li	a1,3
    80005daa:	f7040513          	addi	a0,s0,-144
    80005dae:	fffff097          	auipc	ra,0xfffff
    80005db2:	776080e7          	jalr	1910(ra) # 80005524 <create>
     argint(2, &minor) < 0 ||
    80005db6:	c919                	beqz	a0,80005dcc <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005db8:	ffffe097          	auipc	ra,0xffffe
    80005dbc:	03c080e7          	jalr	60(ra) # 80003df4 <iunlockput>
  end_op();
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	822080e7          	jalr	-2014(ra) # 800045e2 <end_op>
  return 0;
    80005dc8:	4501                	li	a0,0
    80005dca:	a031                	j	80005dd6 <sys_mknod+0x80>
    end_op();
    80005dcc:	fffff097          	auipc	ra,0xfffff
    80005dd0:	816080e7          	jalr	-2026(ra) # 800045e2 <end_op>
    return -1;
    80005dd4:	557d                	li	a0,-1
}
    80005dd6:	60ea                	ld	ra,152(sp)
    80005dd8:	644a                	ld	s0,144(sp)
    80005dda:	610d                	addi	sp,sp,160
    80005ddc:	8082                	ret

0000000080005dde <sys_chdir>:

uint64
sys_chdir(void)
{
    80005dde:	7135                	addi	sp,sp,-160
    80005de0:	ed06                	sd	ra,152(sp)
    80005de2:	e922                	sd	s0,144(sp)
    80005de4:	e526                	sd	s1,136(sp)
    80005de6:	e14a                	sd	s2,128(sp)
    80005de8:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005dea:	ffffc097          	auipc	ra,0xffffc
    80005dee:	fbe080e7          	jalr	-66(ra) # 80001da8 <myproc>
    80005df2:	892a                	mv	s2,a0
  
  begin_op();
    80005df4:	ffffe097          	auipc	ra,0xffffe
    80005df8:	76e080e7          	jalr	1902(ra) # 80004562 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005dfc:	08000613          	li	a2,128
    80005e00:	f6040593          	addi	a1,s0,-160
    80005e04:	4501                	li	a0,0
    80005e06:	ffffd097          	auipc	ra,0xffffd
    80005e0a:	0a4080e7          	jalr	164(ra) # 80002eaa <argstr>
    80005e0e:	04054b63          	bltz	a0,80005e64 <sys_chdir+0x86>
    80005e12:	f6040513          	addi	a0,s0,-160
    80005e16:	ffffe097          	auipc	ra,0xffffe
    80005e1a:	530080e7          	jalr	1328(ra) # 80004346 <namei>
    80005e1e:	84aa                	mv	s1,a0
    80005e20:	c131                	beqz	a0,80005e64 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005e22:	ffffe097          	auipc	ra,0xffffe
    80005e26:	d70080e7          	jalr	-656(ra) # 80003b92 <ilock>
  if(ip->type != T_DIR){
    80005e2a:	04c49703          	lh	a4,76(s1)
    80005e2e:	4785                	li	a5,1
    80005e30:	04f71063          	bne	a4,a5,80005e70 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005e34:	8526                	mv	a0,s1
    80005e36:	ffffe097          	auipc	ra,0xffffe
    80005e3a:	e1e080e7          	jalr	-482(ra) # 80003c54 <iunlock>
  iput(p->cwd);
    80005e3e:	15893503          	ld	a0,344(s2)
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	f0a080e7          	jalr	-246(ra) # 80003d4c <iput>
  end_op();
    80005e4a:	ffffe097          	auipc	ra,0xffffe
    80005e4e:	798080e7          	jalr	1944(ra) # 800045e2 <end_op>
  p->cwd = ip;
    80005e52:	14993c23          	sd	s1,344(s2)
  return 0;
    80005e56:	4501                	li	a0,0
}
    80005e58:	60ea                	ld	ra,152(sp)
    80005e5a:	644a                	ld	s0,144(sp)
    80005e5c:	64aa                	ld	s1,136(sp)
    80005e5e:	690a                	ld	s2,128(sp)
    80005e60:	610d                	addi	sp,sp,160
    80005e62:	8082                	ret
    end_op();
    80005e64:	ffffe097          	auipc	ra,0xffffe
    80005e68:	77e080e7          	jalr	1918(ra) # 800045e2 <end_op>
    return -1;
    80005e6c:	557d                	li	a0,-1
    80005e6e:	b7ed                	j	80005e58 <sys_chdir+0x7a>
    iunlockput(ip);
    80005e70:	8526                	mv	a0,s1
    80005e72:	ffffe097          	auipc	ra,0xffffe
    80005e76:	f82080e7          	jalr	-126(ra) # 80003df4 <iunlockput>
    end_op();
    80005e7a:	ffffe097          	auipc	ra,0xffffe
    80005e7e:	768080e7          	jalr	1896(ra) # 800045e2 <end_op>
    return -1;
    80005e82:	557d                	li	a0,-1
    80005e84:	bfd1                	j	80005e58 <sys_chdir+0x7a>

0000000080005e86 <sys_exec>:

uint64
sys_exec(void)
{
    80005e86:	7145                	addi	sp,sp,-464
    80005e88:	e786                	sd	ra,456(sp)
    80005e8a:	e3a2                	sd	s0,448(sp)
    80005e8c:	ff26                	sd	s1,440(sp)
    80005e8e:	fb4a                	sd	s2,432(sp)
    80005e90:	f74e                	sd	s3,424(sp)
    80005e92:	f352                	sd	s4,416(sp)
    80005e94:	ef56                	sd	s5,408(sp)
    80005e96:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e98:	08000613          	li	a2,128
    80005e9c:	f4040593          	addi	a1,s0,-192
    80005ea0:	4501                	li	a0,0
    80005ea2:	ffffd097          	auipc	ra,0xffffd
    80005ea6:	008080e7          	jalr	8(ra) # 80002eaa <argstr>
    return -1;
    80005eaa:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005eac:	0c054a63          	bltz	a0,80005f80 <sys_exec+0xfa>
    80005eb0:	e3840593          	addi	a1,s0,-456
    80005eb4:	4505                	li	a0,1
    80005eb6:	ffffd097          	auipc	ra,0xffffd
    80005eba:	fd2080e7          	jalr	-46(ra) # 80002e88 <argaddr>
    80005ebe:	0c054163          	bltz	a0,80005f80 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005ec2:	10000613          	li	a2,256
    80005ec6:	4581                	li	a1,0
    80005ec8:	e4040513          	addi	a0,s0,-448
    80005ecc:	ffffb097          	auipc	ra,0xffffb
    80005ed0:	274080e7          	jalr	628(ra) # 80001140 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005ed4:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005ed8:	89a6                	mv	s3,s1
    80005eda:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005edc:	02000a13          	li	s4,32
    80005ee0:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005ee4:	00391513          	slli	a0,s2,0x3
    80005ee8:	e3040593          	addi	a1,s0,-464
    80005eec:	e3843783          	ld	a5,-456(s0)
    80005ef0:	953e                	add	a0,a0,a5
    80005ef2:	ffffd097          	auipc	ra,0xffffd
    80005ef6:	eda080e7          	jalr	-294(ra) # 80002dcc <fetchaddr>
    80005efa:	02054a63          	bltz	a0,80005f2e <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005efe:	e3043783          	ld	a5,-464(s0)
    80005f02:	c3b9                	beqz	a5,80005f48 <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005f04:	ffffb097          	auipc	ra,0xffffb
    80005f08:	c76080e7          	jalr	-906(ra) # 80000b7a <kalloc>
    80005f0c:	85aa                	mv	a1,a0
    80005f0e:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005f12:	cd11                	beqz	a0,80005f2e <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005f14:	6605                	lui	a2,0x1
    80005f16:	e3043503          	ld	a0,-464(s0)
    80005f1a:	ffffd097          	auipc	ra,0xffffd
    80005f1e:	f04080e7          	jalr	-252(ra) # 80002e1e <fetchstr>
    80005f22:	00054663          	bltz	a0,80005f2e <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005f26:	0905                	addi	s2,s2,1
    80005f28:	09a1                	addi	s3,s3,8
    80005f2a:	fb491be3          	bne	s2,s4,80005ee0 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f2e:	10048913          	addi	s2,s1,256
    80005f32:	6088                	ld	a0,0(s1)
    80005f34:	c529                	beqz	a0,80005f7e <sys_exec+0xf8>
    kfree(argv[i]);
    80005f36:	ffffb097          	auipc	ra,0xffffb
    80005f3a:	af6080e7          	jalr	-1290(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f3e:	04a1                	addi	s1,s1,8
    80005f40:	ff2499e3          	bne	s1,s2,80005f32 <sys_exec+0xac>
  return -1;
    80005f44:	597d                	li	s2,-1
    80005f46:	a82d                	j	80005f80 <sys_exec+0xfa>
      argv[i] = 0;
    80005f48:	0a8e                	slli	s5,s5,0x3
    80005f4a:	fc040793          	addi	a5,s0,-64
    80005f4e:	9abe                	add	s5,s5,a5
    80005f50:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005f54:	e4040593          	addi	a1,s0,-448
    80005f58:	f4040513          	addi	a0,s0,-192
    80005f5c:	fffff097          	auipc	ra,0xfffff
    80005f60:	194080e7          	jalr	404(ra) # 800050f0 <exec>
    80005f64:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f66:	10048993          	addi	s3,s1,256
    80005f6a:	6088                	ld	a0,0(s1)
    80005f6c:	c911                	beqz	a0,80005f80 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f6e:	ffffb097          	auipc	ra,0xffffb
    80005f72:	abe080e7          	jalr	-1346(ra) # 80000a2c <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f76:	04a1                	addi	s1,s1,8
    80005f78:	ff3499e3          	bne	s1,s3,80005f6a <sys_exec+0xe4>
    80005f7c:	a011                	j	80005f80 <sys_exec+0xfa>
  return -1;
    80005f7e:	597d                	li	s2,-1
}
    80005f80:	854a                	mv	a0,s2
    80005f82:	60be                	ld	ra,456(sp)
    80005f84:	641e                	ld	s0,448(sp)
    80005f86:	74fa                	ld	s1,440(sp)
    80005f88:	795a                	ld	s2,432(sp)
    80005f8a:	79ba                	ld	s3,424(sp)
    80005f8c:	7a1a                	ld	s4,416(sp)
    80005f8e:	6afa                	ld	s5,408(sp)
    80005f90:	6179                	addi	sp,sp,464
    80005f92:	8082                	ret

0000000080005f94 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f94:	7139                	addi	sp,sp,-64
    80005f96:	fc06                	sd	ra,56(sp)
    80005f98:	f822                	sd	s0,48(sp)
    80005f9a:	f426                	sd	s1,40(sp)
    80005f9c:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f9e:	ffffc097          	auipc	ra,0xffffc
    80005fa2:	e0a080e7          	jalr	-502(ra) # 80001da8 <myproc>
    80005fa6:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005fa8:	fd840593          	addi	a1,s0,-40
    80005fac:	4501                	li	a0,0
    80005fae:	ffffd097          	auipc	ra,0xffffd
    80005fb2:	eda080e7          	jalr	-294(ra) # 80002e88 <argaddr>
    return -1;
    80005fb6:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005fb8:	0e054063          	bltz	a0,80006098 <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005fbc:	fc840593          	addi	a1,s0,-56
    80005fc0:	fd040513          	addi	a0,s0,-48
    80005fc4:	fffff097          	auipc	ra,0xfffff
    80005fc8:	dc8080e7          	jalr	-568(ra) # 80004d8c <pipealloc>
    return -1;
    80005fcc:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005fce:	0c054563          	bltz	a0,80006098 <sys_pipe+0x104>
  fd0 = -1;
    80005fd2:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005fd6:	fd043503          	ld	a0,-48(s0)
    80005fda:	fffff097          	auipc	ra,0xfffff
    80005fde:	508080e7          	jalr	1288(ra) # 800054e2 <fdalloc>
    80005fe2:	fca42223          	sw	a0,-60(s0)
    80005fe6:	08054c63          	bltz	a0,8000607e <sys_pipe+0xea>
    80005fea:	fc843503          	ld	a0,-56(s0)
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	4f4080e7          	jalr	1268(ra) # 800054e2 <fdalloc>
    80005ff6:	fca42023          	sw	a0,-64(s0)
    80005ffa:	06054863          	bltz	a0,8000606a <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005ffe:	4691                	li	a3,4
    80006000:	fc440613          	addi	a2,s0,-60
    80006004:	fd843583          	ld	a1,-40(s0)
    80006008:	6ca8                	ld	a0,88(s1)
    8000600a:	ffffc097          	auipc	ra,0xffffc
    8000600e:	a92080e7          	jalr	-1390(ra) # 80001a9c <copyout>
    80006012:	02054063          	bltz	a0,80006032 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006016:	4691                	li	a3,4
    80006018:	fc040613          	addi	a2,s0,-64
    8000601c:	fd843583          	ld	a1,-40(s0)
    80006020:	0591                	addi	a1,a1,4
    80006022:	6ca8                	ld	a0,88(s1)
    80006024:	ffffc097          	auipc	ra,0xffffc
    80006028:	a78080e7          	jalr	-1416(ra) # 80001a9c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    8000602c:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    8000602e:	06055563          	bgez	a0,80006098 <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006032:	fc442783          	lw	a5,-60(s0)
    80006036:	07e9                	addi	a5,a5,26
    80006038:	078e                	slli	a5,a5,0x3
    8000603a:	97a6                	add	a5,a5,s1
    8000603c:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006040:	fc042503          	lw	a0,-64(s0)
    80006044:	0569                	addi	a0,a0,26
    80006046:	050e                	slli	a0,a0,0x3
    80006048:	9526                	add	a0,a0,s1
    8000604a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000604e:	fd043503          	ld	a0,-48(s0)
    80006052:	fffff097          	auipc	ra,0xfffff
    80006056:	9e4080e7          	jalr	-1564(ra) # 80004a36 <fileclose>
    fileclose(wf);
    8000605a:	fc843503          	ld	a0,-56(s0)
    8000605e:	fffff097          	auipc	ra,0xfffff
    80006062:	9d8080e7          	jalr	-1576(ra) # 80004a36 <fileclose>
    return -1;
    80006066:	57fd                	li	a5,-1
    80006068:	a805                	j	80006098 <sys_pipe+0x104>
    if(fd0 >= 0)
    8000606a:	fc442783          	lw	a5,-60(s0)
    8000606e:	0007c863          	bltz	a5,8000607e <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006072:	01a78513          	addi	a0,a5,26
    80006076:	050e                	slli	a0,a0,0x3
    80006078:	9526                	add	a0,a0,s1
    8000607a:	00053423          	sd	zero,8(a0)
    fileclose(rf);
    8000607e:	fd043503          	ld	a0,-48(s0)
    80006082:	fffff097          	auipc	ra,0xfffff
    80006086:	9b4080e7          	jalr	-1612(ra) # 80004a36 <fileclose>
    fileclose(wf);
    8000608a:	fc843503          	ld	a0,-56(s0)
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	9a8080e7          	jalr	-1624(ra) # 80004a36 <fileclose>
    return -1;
    80006096:	57fd                	li	a5,-1
}
    80006098:	853e                	mv	a0,a5
    8000609a:	70e2                	ld	ra,56(sp)
    8000609c:	7442                	ld	s0,48(sp)
    8000609e:	74a2                	ld	s1,40(sp)
    800060a0:	6121                	addi	sp,sp,64
    800060a2:	8082                	ret
	...

00000000800060b0 <kernelvec>:
    800060b0:	7111                	addi	sp,sp,-256
    800060b2:	e006                	sd	ra,0(sp)
    800060b4:	e40a                	sd	sp,8(sp)
    800060b6:	e80e                	sd	gp,16(sp)
    800060b8:	ec12                	sd	tp,24(sp)
    800060ba:	f016                	sd	t0,32(sp)
    800060bc:	f41a                	sd	t1,40(sp)
    800060be:	f81e                	sd	t2,48(sp)
    800060c0:	fc22                	sd	s0,56(sp)
    800060c2:	e0a6                	sd	s1,64(sp)
    800060c4:	e4aa                	sd	a0,72(sp)
    800060c6:	e8ae                	sd	a1,80(sp)
    800060c8:	ecb2                	sd	a2,88(sp)
    800060ca:	f0b6                	sd	a3,96(sp)
    800060cc:	f4ba                	sd	a4,104(sp)
    800060ce:	f8be                	sd	a5,112(sp)
    800060d0:	fcc2                	sd	a6,120(sp)
    800060d2:	e146                	sd	a7,128(sp)
    800060d4:	e54a                	sd	s2,136(sp)
    800060d6:	e94e                	sd	s3,144(sp)
    800060d8:	ed52                	sd	s4,152(sp)
    800060da:	f156                	sd	s5,160(sp)
    800060dc:	f55a                	sd	s6,168(sp)
    800060de:	f95e                	sd	s7,176(sp)
    800060e0:	fd62                	sd	s8,184(sp)
    800060e2:	e1e6                	sd	s9,192(sp)
    800060e4:	e5ea                	sd	s10,200(sp)
    800060e6:	e9ee                	sd	s11,208(sp)
    800060e8:	edf2                	sd	t3,216(sp)
    800060ea:	f1f6                	sd	t4,224(sp)
    800060ec:	f5fa                	sd	t5,232(sp)
    800060ee:	f9fe                	sd	t6,240(sp)
    800060f0:	ba9fc0ef          	jal	ra,80002c98 <kerneltrap>
    800060f4:	6082                	ld	ra,0(sp)
    800060f6:	6122                	ld	sp,8(sp)
    800060f8:	61c2                	ld	gp,16(sp)
    800060fa:	7282                	ld	t0,32(sp)
    800060fc:	7322                	ld	t1,40(sp)
    800060fe:	73c2                	ld	t2,48(sp)
    80006100:	7462                	ld	s0,56(sp)
    80006102:	6486                	ld	s1,64(sp)
    80006104:	6526                	ld	a0,72(sp)
    80006106:	65c6                	ld	a1,80(sp)
    80006108:	6666                	ld	a2,88(sp)
    8000610a:	7686                	ld	a3,96(sp)
    8000610c:	7726                	ld	a4,104(sp)
    8000610e:	77c6                	ld	a5,112(sp)
    80006110:	7866                	ld	a6,120(sp)
    80006112:	688a                	ld	a7,128(sp)
    80006114:	692a                	ld	s2,136(sp)
    80006116:	69ca                	ld	s3,144(sp)
    80006118:	6a6a                	ld	s4,152(sp)
    8000611a:	7a8a                	ld	s5,160(sp)
    8000611c:	7b2a                	ld	s6,168(sp)
    8000611e:	7bca                	ld	s7,176(sp)
    80006120:	7c6a                	ld	s8,184(sp)
    80006122:	6c8e                	ld	s9,192(sp)
    80006124:	6d2e                	ld	s10,200(sp)
    80006126:	6dce                	ld	s11,208(sp)
    80006128:	6e6e                	ld	t3,216(sp)
    8000612a:	7e8e                	ld	t4,224(sp)
    8000612c:	7f2e                	ld	t5,232(sp)
    8000612e:	7fce                	ld	t6,240(sp)
    80006130:	6111                	addi	sp,sp,256
    80006132:	10200073          	sret
    80006136:	00000013          	nop
    8000613a:	00000013          	nop
    8000613e:	0001                	nop

0000000080006140 <timervec>:
    80006140:	34051573          	csrrw	a0,mscratch,a0
    80006144:	e10c                	sd	a1,0(a0)
    80006146:	e510                	sd	a2,8(a0)
    80006148:	e914                	sd	a3,16(a0)
    8000614a:	6d0c                	ld	a1,24(a0)
    8000614c:	7110                	ld	a2,32(a0)
    8000614e:	6194                	ld	a3,0(a1)
    80006150:	96b2                	add	a3,a3,a2
    80006152:	e194                	sd	a3,0(a1)
    80006154:	4589                	li	a1,2
    80006156:	14459073          	csrw	sip,a1
    8000615a:	6914                	ld	a3,16(a0)
    8000615c:	6510                	ld	a2,8(a0)
    8000615e:	610c                	ld	a1,0(a0)
    80006160:	34051573          	csrrw	a0,mscratch,a0
    80006164:	30200073          	mret
	...

000000008000616a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000616a:	1141                	addi	sp,sp,-16
    8000616c:	e422                	sd	s0,8(sp)
    8000616e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006170:	0c0007b7          	lui	a5,0xc000
    80006174:	4705                	li	a4,1
    80006176:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006178:	c3d8                	sw	a4,4(a5)
}
    8000617a:	6422                	ld	s0,8(sp)
    8000617c:	0141                	addi	sp,sp,16
    8000617e:	8082                	ret

0000000080006180 <plicinithart>:

void
plicinithart(void)
{
    80006180:	1141                	addi	sp,sp,-16
    80006182:	e406                	sd	ra,8(sp)
    80006184:	e022                	sd	s0,0(sp)
    80006186:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006188:	ffffc097          	auipc	ra,0xffffc
    8000618c:	bf4080e7          	jalr	-1036(ra) # 80001d7c <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006190:	0085171b          	slliw	a4,a0,0x8
    80006194:	0c0027b7          	lui	a5,0xc002
    80006198:	97ba                	add	a5,a5,a4
    8000619a:	40200713          	li	a4,1026
    8000619e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800061a2:	00d5151b          	slliw	a0,a0,0xd
    800061a6:	0c2017b7          	lui	a5,0xc201
    800061aa:	953e                	add	a0,a0,a5
    800061ac:	00052023          	sw	zero,0(a0)
}
    800061b0:	60a2                	ld	ra,8(sp)
    800061b2:	6402                	ld	s0,0(sp)
    800061b4:	0141                	addi	sp,sp,16
    800061b6:	8082                	ret

00000000800061b8 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    800061b8:	1141                	addi	sp,sp,-16
    800061ba:	e406                	sd	ra,8(sp)
    800061bc:	e022                	sd	s0,0(sp)
    800061be:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061c0:	ffffc097          	auipc	ra,0xffffc
    800061c4:	bbc080e7          	jalr	-1092(ra) # 80001d7c <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    800061c8:	00d5179b          	slliw	a5,a0,0xd
    800061cc:	0c201537          	lui	a0,0xc201
    800061d0:	953e                	add	a0,a0,a5
  return irq;
}
    800061d2:	4148                	lw	a0,4(a0)
    800061d4:	60a2                	ld	ra,8(sp)
    800061d6:	6402                	ld	s0,0(sp)
    800061d8:	0141                	addi	sp,sp,16
    800061da:	8082                	ret

00000000800061dc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800061dc:	1101                	addi	sp,sp,-32
    800061de:	ec06                	sd	ra,24(sp)
    800061e0:	e822                	sd	s0,16(sp)
    800061e2:	e426                	sd	s1,8(sp)
    800061e4:	1000                	addi	s0,sp,32
    800061e6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	b94080e7          	jalr	-1132(ra) # 80001d7c <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800061f0:	00d5151b          	slliw	a0,a0,0xd
    800061f4:	0c2017b7          	lui	a5,0xc201
    800061f8:	97aa                	add	a5,a5,a0
    800061fa:	c3c4                	sw	s1,4(a5)
}
    800061fc:	60e2                	ld	ra,24(sp)
    800061fe:	6442                	ld	s0,16(sp)
    80006200:	64a2                	ld	s1,8(sp)
    80006202:	6105                	addi	sp,sp,32
    80006204:	8082                	ret

0000000080006206 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006206:	1141                	addi	sp,sp,-16
    80006208:	e406                	sd	ra,8(sp)
    8000620a:	e022                	sd	s0,0(sp)
    8000620c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000620e:	479d                	li	a5,7
    80006210:	06a7c963          	blt	a5,a0,80006282 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006214:	0001e797          	auipc	a5,0x1e
    80006218:	dec78793          	addi	a5,a5,-532 # 80024000 <disk>
    8000621c:	00a78733          	add	a4,a5,a0
    80006220:	6789                	lui	a5,0x2
    80006222:	97ba                	add	a5,a5,a4
    80006224:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006228:	e7ad                	bnez	a5,80006292 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000622a:	00451793          	slli	a5,a0,0x4
    8000622e:	00020717          	auipc	a4,0x20
    80006232:	dd270713          	addi	a4,a4,-558 # 80026000 <disk+0x2000>
    80006236:	6314                	ld	a3,0(a4)
    80006238:	96be                	add	a3,a3,a5
    8000623a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000623e:	6314                	ld	a3,0(a4)
    80006240:	96be                	add	a3,a3,a5
    80006242:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006246:	6314                	ld	a3,0(a4)
    80006248:	96be                	add	a3,a3,a5
    8000624a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000624e:	6318                	ld	a4,0(a4)
    80006250:	97ba                	add	a5,a5,a4
    80006252:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006256:	0001e797          	auipc	a5,0x1e
    8000625a:	daa78793          	addi	a5,a5,-598 # 80024000 <disk>
    8000625e:	97aa                	add	a5,a5,a0
    80006260:	6509                	lui	a0,0x2
    80006262:	953e                	add	a0,a0,a5
    80006264:	4785                	li	a5,1
    80006266:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000626a:	00020517          	auipc	a0,0x20
    8000626e:	dae50513          	addi	a0,a0,-594 # 80026018 <disk+0x2018>
    80006272:	ffffc097          	auipc	ra,0xffffc
    80006276:	4cc080e7          	jalr	1228(ra) # 8000273e <wakeup>
}
    8000627a:	60a2                	ld	ra,8(sp)
    8000627c:	6402                	ld	s0,0(sp)
    8000627e:	0141                	addi	sp,sp,16
    80006280:	8082                	ret
    panic("free_desc 1");
    80006282:	00002517          	auipc	a0,0x2
    80006286:	56e50513          	addi	a0,a0,1390 # 800087f0 <syscalls+0x338>
    8000628a:	ffffa097          	auipc	ra,0xffffa
    8000628e:	2c6080e7          	jalr	710(ra) # 80000550 <panic>
    panic("free_desc 2");
    80006292:	00002517          	auipc	a0,0x2
    80006296:	56e50513          	addi	a0,a0,1390 # 80008800 <syscalls+0x348>
    8000629a:	ffffa097          	auipc	ra,0xffffa
    8000629e:	2b6080e7          	jalr	694(ra) # 80000550 <panic>

00000000800062a2 <virtio_disk_init>:
{
    800062a2:	1101                	addi	sp,sp,-32
    800062a4:	ec06                	sd	ra,24(sp)
    800062a6:	e822                	sd	s0,16(sp)
    800062a8:	e426                	sd	s1,8(sp)
    800062aa:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800062ac:	00002597          	auipc	a1,0x2
    800062b0:	56458593          	addi	a1,a1,1380 # 80008810 <syscalls+0x358>
    800062b4:	00020517          	auipc	a0,0x20
    800062b8:	e7450513          	addi	a0,a0,-396 # 80026128 <disk+0x2128>
    800062bc:	ffffb097          	auipc	ra,0xffffb
    800062c0:	c20080e7          	jalr	-992(ra) # 80000edc <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062c4:	100017b7          	lui	a5,0x10001
    800062c8:	4398                	lw	a4,0(a5)
    800062ca:	2701                	sext.w	a4,a4
    800062cc:	747277b7          	lui	a5,0x74727
    800062d0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800062d4:	0ef71163          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062d8:	100017b7          	lui	a5,0x10001
    800062dc:	43dc                	lw	a5,4(a5)
    800062de:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800062e0:	4705                	li	a4,1
    800062e2:	0ce79a63          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062e6:	100017b7          	lui	a5,0x10001
    800062ea:	479c                	lw	a5,8(a5)
    800062ec:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800062ee:	4709                	li	a4,2
    800062f0:	0ce79363          	bne	a5,a4,800063b6 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800062f4:	100017b7          	lui	a5,0x10001
    800062f8:	47d8                	lw	a4,12(a5)
    800062fa:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800062fc:	554d47b7          	lui	a5,0x554d4
    80006300:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006304:	0af71963          	bne	a4,a5,800063b6 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006308:	100017b7          	lui	a5,0x10001
    8000630c:	4705                	li	a4,1
    8000630e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006310:	470d                	li	a4,3
    80006312:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006314:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006316:	c7ffe737          	lui	a4,0xc7ffe
    8000631a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd6737>
    8000631e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006320:	2701                	sext.w	a4,a4
    80006322:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006324:	472d                	li	a4,11
    80006326:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006328:	473d                	li	a4,15
    8000632a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000632c:	6705                	lui	a4,0x1
    8000632e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006330:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006334:	5bdc                	lw	a5,52(a5)
    80006336:	2781                	sext.w	a5,a5
  if(max == 0)
    80006338:	c7d9                	beqz	a5,800063c6 <virtio_disk_init+0x124>
  if(max < NUM)
    8000633a:	471d                	li	a4,7
    8000633c:	08f77d63          	bgeu	a4,a5,800063d6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006340:	100014b7          	lui	s1,0x10001
    80006344:	47a1                	li	a5,8
    80006346:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006348:	6609                	lui	a2,0x2
    8000634a:	4581                	li	a1,0
    8000634c:	0001e517          	auipc	a0,0x1e
    80006350:	cb450513          	addi	a0,a0,-844 # 80024000 <disk>
    80006354:	ffffb097          	auipc	ra,0xffffb
    80006358:	dec080e7          	jalr	-532(ra) # 80001140 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000635c:	0001e717          	auipc	a4,0x1e
    80006360:	ca470713          	addi	a4,a4,-860 # 80024000 <disk>
    80006364:	00c75793          	srli	a5,a4,0xc
    80006368:	2781                	sext.w	a5,a5
    8000636a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000636c:	00020797          	auipc	a5,0x20
    80006370:	c9478793          	addi	a5,a5,-876 # 80026000 <disk+0x2000>
    80006374:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006376:	0001e717          	auipc	a4,0x1e
    8000637a:	d0a70713          	addi	a4,a4,-758 # 80024080 <disk+0x80>
    8000637e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006380:	0001f717          	auipc	a4,0x1f
    80006384:	c8070713          	addi	a4,a4,-896 # 80025000 <disk+0x1000>
    80006388:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000638a:	4705                	li	a4,1
    8000638c:	00e78c23          	sb	a4,24(a5)
    80006390:	00e78ca3          	sb	a4,25(a5)
    80006394:	00e78d23          	sb	a4,26(a5)
    80006398:	00e78da3          	sb	a4,27(a5)
    8000639c:	00e78e23          	sb	a4,28(a5)
    800063a0:	00e78ea3          	sb	a4,29(a5)
    800063a4:	00e78f23          	sb	a4,30(a5)
    800063a8:	00e78fa3          	sb	a4,31(a5)
}
    800063ac:	60e2                	ld	ra,24(sp)
    800063ae:	6442                	ld	s0,16(sp)
    800063b0:	64a2                	ld	s1,8(sp)
    800063b2:	6105                	addi	sp,sp,32
    800063b4:	8082                	ret
    panic("could not find virtio disk");
    800063b6:	00002517          	auipc	a0,0x2
    800063ba:	46a50513          	addi	a0,a0,1130 # 80008820 <syscalls+0x368>
    800063be:	ffffa097          	auipc	ra,0xffffa
    800063c2:	192080e7          	jalr	402(ra) # 80000550 <panic>
    panic("virtio disk has no queue 0");
    800063c6:	00002517          	auipc	a0,0x2
    800063ca:	47a50513          	addi	a0,a0,1146 # 80008840 <syscalls+0x388>
    800063ce:	ffffa097          	auipc	ra,0xffffa
    800063d2:	182080e7          	jalr	386(ra) # 80000550 <panic>
    panic("virtio disk max queue too short");
    800063d6:	00002517          	auipc	a0,0x2
    800063da:	48a50513          	addi	a0,a0,1162 # 80008860 <syscalls+0x3a8>
    800063de:	ffffa097          	auipc	ra,0xffffa
    800063e2:	172080e7          	jalr	370(ra) # 80000550 <panic>

00000000800063e6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063e6:	7159                	addi	sp,sp,-112
    800063e8:	f486                	sd	ra,104(sp)
    800063ea:	f0a2                	sd	s0,96(sp)
    800063ec:	eca6                	sd	s1,88(sp)
    800063ee:	e8ca                	sd	s2,80(sp)
    800063f0:	e4ce                	sd	s3,72(sp)
    800063f2:	e0d2                	sd	s4,64(sp)
    800063f4:	fc56                	sd	s5,56(sp)
    800063f6:	f85a                	sd	s6,48(sp)
    800063f8:	f45e                	sd	s7,40(sp)
    800063fa:	f062                	sd	s8,32(sp)
    800063fc:	ec66                	sd	s9,24(sp)
    800063fe:	e86a                	sd	s10,16(sp)
    80006400:	1880                	addi	s0,sp,112
    80006402:	892a                	mv	s2,a0
    80006404:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006406:	00c52c83          	lw	s9,12(a0)
    8000640a:	001c9c9b          	slliw	s9,s9,0x1
    8000640e:	1c82                	slli	s9,s9,0x20
    80006410:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006414:	00020517          	auipc	a0,0x20
    80006418:	d1450513          	addi	a0,a0,-748 # 80026128 <disk+0x2128>
    8000641c:	ffffb097          	auipc	ra,0xffffb
    80006420:	944080e7          	jalr	-1724(ra) # 80000d60 <acquire>
  for(int i = 0; i < 3; i++){
    80006424:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006426:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006428:	0001eb97          	auipc	s7,0x1e
    8000642c:	bd8b8b93          	addi	s7,s7,-1064 # 80024000 <disk>
    80006430:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006432:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006434:	8a4e                	mv	s4,s3
    80006436:	a051                	j	800064ba <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006438:	00fb86b3          	add	a3,s7,a5
    8000643c:	96da                	add	a3,a3,s6
    8000643e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006442:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006444:	0207c563          	bltz	a5,8000646e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006448:	2485                	addiw	s1,s1,1
    8000644a:	0711                	addi	a4,a4,4
    8000644c:	25548063          	beq	s1,s5,8000668c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006450:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006452:	00020697          	auipc	a3,0x20
    80006456:	bc668693          	addi	a3,a3,-1082 # 80026018 <disk+0x2018>
    8000645a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000645c:	0006c583          	lbu	a1,0(a3)
    80006460:	fde1                	bnez	a1,80006438 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006462:	2785                	addiw	a5,a5,1
    80006464:	0685                	addi	a3,a3,1
    80006466:	ff879be3          	bne	a5,s8,8000645c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000646a:	57fd                	li	a5,-1
    8000646c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000646e:	02905a63          	blez	s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006472:	f9042503          	lw	a0,-112(s0)
    80006476:	00000097          	auipc	ra,0x0
    8000647a:	d90080e7          	jalr	-624(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    8000647e:	4785                	li	a5,1
    80006480:	0297d163          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006484:	f9442503          	lw	a0,-108(s0)
    80006488:	00000097          	auipc	ra,0x0
    8000648c:	d7e080e7          	jalr	-642(ra) # 80006206 <free_desc>
      for(int j = 0; j < i; j++)
    80006490:	4789                	li	a5,2
    80006492:	0097d863          	bge	a5,s1,800064a2 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006496:	f9842503          	lw	a0,-104(s0)
    8000649a:	00000097          	auipc	ra,0x0
    8000649e:	d6c080e7          	jalr	-660(ra) # 80006206 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800064a2:	00020597          	auipc	a1,0x20
    800064a6:	c8658593          	addi	a1,a1,-890 # 80026128 <disk+0x2128>
    800064aa:	00020517          	auipc	a0,0x20
    800064ae:	b6e50513          	addi	a0,a0,-1170 # 80026018 <disk+0x2018>
    800064b2:	ffffc097          	auipc	ra,0xffffc
    800064b6:	106080e7          	jalr	262(ra) # 800025b8 <sleep>
  for(int i = 0; i < 3; i++){
    800064ba:	f9040713          	addi	a4,s0,-112
    800064be:	84ce                	mv	s1,s3
    800064c0:	bf41                	j	80006450 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    800064c2:	20058713          	addi	a4,a1,512
    800064c6:	00471693          	slli	a3,a4,0x4
    800064ca:	0001e717          	auipc	a4,0x1e
    800064ce:	b3670713          	addi	a4,a4,-1226 # 80024000 <disk>
    800064d2:	9736                	add	a4,a4,a3
    800064d4:	4685                	li	a3,1
    800064d6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064da:	20058713          	addi	a4,a1,512
    800064de:	00471693          	slli	a3,a4,0x4
    800064e2:	0001e717          	auipc	a4,0x1e
    800064e6:	b1e70713          	addi	a4,a4,-1250 # 80024000 <disk>
    800064ea:	9736                	add	a4,a4,a3
    800064ec:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800064f0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064f4:	7679                	lui	a2,0xffffe
    800064f6:	963e                	add	a2,a2,a5
    800064f8:	00020697          	auipc	a3,0x20
    800064fc:	b0868693          	addi	a3,a3,-1272 # 80026000 <disk+0x2000>
    80006500:	6298                	ld	a4,0(a3)
    80006502:	9732                	add	a4,a4,a2
    80006504:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006506:	6298                	ld	a4,0(a3)
    80006508:	9732                	add	a4,a4,a2
    8000650a:	4541                	li	a0,16
    8000650c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000650e:	6298                	ld	a4,0(a3)
    80006510:	9732                	add	a4,a4,a2
    80006512:	4505                	li	a0,1
    80006514:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006518:	f9442703          	lw	a4,-108(s0)
    8000651c:	6288                	ld	a0,0(a3)
    8000651e:	962a                	add	a2,a2,a0
    80006520:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd5fe6>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006524:	0712                	slli	a4,a4,0x4
    80006526:	6290                	ld	a2,0(a3)
    80006528:	963a                	add	a2,a2,a4
    8000652a:	05890513          	addi	a0,s2,88
    8000652e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006530:	6294                	ld	a3,0(a3)
    80006532:	96ba                	add	a3,a3,a4
    80006534:	40000613          	li	a2,1024
    80006538:	c690                	sw	a2,8(a3)
  if(write)
    8000653a:	140d0063          	beqz	s10,8000667a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000653e:	00020697          	auipc	a3,0x20
    80006542:	ac26b683          	ld	a3,-1342(a3) # 80026000 <disk+0x2000>
    80006546:	96ba                	add	a3,a3,a4
    80006548:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000654c:	0001e817          	auipc	a6,0x1e
    80006550:	ab480813          	addi	a6,a6,-1356 # 80024000 <disk>
    80006554:	00020517          	auipc	a0,0x20
    80006558:	aac50513          	addi	a0,a0,-1364 # 80026000 <disk+0x2000>
    8000655c:	6114                	ld	a3,0(a0)
    8000655e:	96ba                	add	a3,a3,a4
    80006560:	00c6d603          	lhu	a2,12(a3)
    80006564:	00166613          	ori	a2,a2,1
    80006568:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000656c:	f9842683          	lw	a3,-104(s0)
    80006570:	6110                	ld	a2,0(a0)
    80006572:	9732                	add	a4,a4,a2
    80006574:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006578:	20058613          	addi	a2,a1,512
    8000657c:	0612                	slli	a2,a2,0x4
    8000657e:	9642                	add	a2,a2,a6
    80006580:	577d                	li	a4,-1
    80006582:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006586:	00469713          	slli	a4,a3,0x4
    8000658a:	6114                	ld	a3,0(a0)
    8000658c:	96ba                	add	a3,a3,a4
    8000658e:	03078793          	addi	a5,a5,48
    80006592:	97c2                	add	a5,a5,a6
    80006594:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006596:	611c                	ld	a5,0(a0)
    80006598:	97ba                	add	a5,a5,a4
    8000659a:	4685                	li	a3,1
    8000659c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000659e:	611c                	ld	a5,0(a0)
    800065a0:	97ba                	add	a5,a5,a4
    800065a2:	4809                	li	a6,2
    800065a4:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    800065a8:	611c                	ld	a5,0(a0)
    800065aa:	973e                	add	a4,a4,a5
    800065ac:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800065b0:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    800065b4:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800065b8:	6518                	ld	a4,8(a0)
    800065ba:	00275783          	lhu	a5,2(a4)
    800065be:	8b9d                	andi	a5,a5,7
    800065c0:	0786                	slli	a5,a5,0x1
    800065c2:	97ba                	add	a5,a5,a4
    800065c4:	00b79223          	sh	a1,4(a5)
  __sync_synchronize();
    800065c8:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800065cc:	6518                	ld	a4,8(a0)
    800065ce:	00275783          	lhu	a5,2(a4)
    800065d2:	2785                	addiw	a5,a5,1
    800065d4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800065d8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800065dc:	100017b7          	lui	a5,0x10001
    800065e0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800065e4:	00492703          	lw	a4,4(s2)
    800065e8:	4785                	li	a5,1
    800065ea:	02f71163          	bne	a4,a5,8000660c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800065ee:	00020997          	auipc	s3,0x20
    800065f2:	b3a98993          	addi	s3,s3,-1222 # 80026128 <disk+0x2128>
  while(b->disk == 1) {
    800065f6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800065f8:	85ce                	mv	a1,s3
    800065fa:	854a                	mv	a0,s2
    800065fc:	ffffc097          	auipc	ra,0xffffc
    80006600:	fbc080e7          	jalr	-68(ra) # 800025b8 <sleep>
  while(b->disk == 1) {
    80006604:	00492783          	lw	a5,4(s2)
    80006608:	fe9788e3          	beq	a5,s1,800065f8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000660c:	f9042903          	lw	s2,-112(s0)
    80006610:	20090793          	addi	a5,s2,512
    80006614:	00479713          	slli	a4,a5,0x4
    80006618:	0001e797          	auipc	a5,0x1e
    8000661c:	9e878793          	addi	a5,a5,-1560 # 80024000 <disk>
    80006620:	97ba                	add	a5,a5,a4
    80006622:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006626:	00020997          	auipc	s3,0x20
    8000662a:	9da98993          	addi	s3,s3,-1574 # 80026000 <disk+0x2000>
    8000662e:	00491713          	slli	a4,s2,0x4
    80006632:	0009b783          	ld	a5,0(s3)
    80006636:	97ba                	add	a5,a5,a4
    80006638:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000663c:	854a                	mv	a0,s2
    8000663e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006642:	00000097          	auipc	ra,0x0
    80006646:	bc4080e7          	jalr	-1084(ra) # 80006206 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    8000664a:	8885                	andi	s1,s1,1
    8000664c:	f0ed                	bnez	s1,8000662e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    8000664e:	00020517          	auipc	a0,0x20
    80006652:	ada50513          	addi	a0,a0,-1318 # 80026128 <disk+0x2128>
    80006656:	ffffa097          	auipc	ra,0xffffa
    8000665a:	7da080e7          	jalr	2010(ra) # 80000e30 <release>
}
    8000665e:	70a6                	ld	ra,104(sp)
    80006660:	7406                	ld	s0,96(sp)
    80006662:	64e6                	ld	s1,88(sp)
    80006664:	6946                	ld	s2,80(sp)
    80006666:	69a6                	ld	s3,72(sp)
    80006668:	6a06                	ld	s4,64(sp)
    8000666a:	7ae2                	ld	s5,56(sp)
    8000666c:	7b42                	ld	s6,48(sp)
    8000666e:	7ba2                	ld	s7,40(sp)
    80006670:	7c02                	ld	s8,32(sp)
    80006672:	6ce2                	ld	s9,24(sp)
    80006674:	6d42                	ld	s10,16(sp)
    80006676:	6165                	addi	sp,sp,112
    80006678:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    8000667a:	00020697          	auipc	a3,0x20
    8000667e:	9866b683          	ld	a3,-1658(a3) # 80026000 <disk+0x2000>
    80006682:	96ba                	add	a3,a3,a4
    80006684:	4609                	li	a2,2
    80006686:	00c69623          	sh	a2,12(a3)
    8000668a:	b5c9                	j	8000654c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    8000668c:	f9042583          	lw	a1,-112(s0)
    80006690:	20058793          	addi	a5,a1,512
    80006694:	0792                	slli	a5,a5,0x4
    80006696:	0001e517          	auipc	a0,0x1e
    8000669a:	a1250513          	addi	a0,a0,-1518 # 800240a8 <disk+0xa8>
    8000669e:	953e                	add	a0,a0,a5
  if(write)
    800066a0:	e20d11e3          	bnez	s10,800064c2 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    800066a4:	20058713          	addi	a4,a1,512
    800066a8:	00471693          	slli	a3,a4,0x4
    800066ac:	0001e717          	auipc	a4,0x1e
    800066b0:	95470713          	addi	a4,a4,-1708 # 80024000 <disk>
    800066b4:	9736                	add	a4,a4,a3
    800066b6:	0a072423          	sw	zero,168(a4)
    800066ba:	b505                	j	800064da <virtio_disk_rw+0xf4>

00000000800066bc <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800066bc:	1101                	addi	sp,sp,-32
    800066be:	ec06                	sd	ra,24(sp)
    800066c0:	e822                	sd	s0,16(sp)
    800066c2:	e426                	sd	s1,8(sp)
    800066c4:	e04a                	sd	s2,0(sp)
    800066c6:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800066c8:	00020517          	auipc	a0,0x20
    800066cc:	a6050513          	addi	a0,a0,-1440 # 80026128 <disk+0x2128>
    800066d0:	ffffa097          	auipc	ra,0xffffa
    800066d4:	690080e7          	jalr	1680(ra) # 80000d60 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800066d8:	10001737          	lui	a4,0x10001
    800066dc:	533c                	lw	a5,96(a4)
    800066de:	8b8d                	andi	a5,a5,3
    800066e0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800066e2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800066e6:	00020797          	auipc	a5,0x20
    800066ea:	91a78793          	addi	a5,a5,-1766 # 80026000 <disk+0x2000>
    800066ee:	6b94                	ld	a3,16(a5)
    800066f0:	0207d703          	lhu	a4,32(a5)
    800066f4:	0026d783          	lhu	a5,2(a3)
    800066f8:	06f70163          	beq	a4,a5,8000675a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800066fc:	0001e917          	auipc	s2,0x1e
    80006700:	90490913          	addi	s2,s2,-1788 # 80024000 <disk>
    80006704:	00020497          	auipc	s1,0x20
    80006708:	8fc48493          	addi	s1,s1,-1796 # 80026000 <disk+0x2000>
    __sync_synchronize();
    8000670c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006710:	6898                	ld	a4,16(s1)
    80006712:	0204d783          	lhu	a5,32(s1)
    80006716:	8b9d                	andi	a5,a5,7
    80006718:	078e                	slli	a5,a5,0x3
    8000671a:	97ba                	add	a5,a5,a4
    8000671c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000671e:	20078713          	addi	a4,a5,512
    80006722:	0712                	slli	a4,a4,0x4
    80006724:	974a                	add	a4,a4,s2
    80006726:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000672a:	e731                	bnez	a4,80006776 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000672c:	20078793          	addi	a5,a5,512
    80006730:	0792                	slli	a5,a5,0x4
    80006732:	97ca                	add	a5,a5,s2
    80006734:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006736:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000673a:	ffffc097          	auipc	ra,0xffffc
    8000673e:	004080e7          	jalr	4(ra) # 8000273e <wakeup>

    disk.used_idx += 1;
    80006742:	0204d783          	lhu	a5,32(s1)
    80006746:	2785                	addiw	a5,a5,1
    80006748:	17c2                	slli	a5,a5,0x30
    8000674a:	93c1                	srli	a5,a5,0x30
    8000674c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006750:	6898                	ld	a4,16(s1)
    80006752:	00275703          	lhu	a4,2(a4)
    80006756:	faf71be3          	bne	a4,a5,8000670c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    8000675a:	00020517          	auipc	a0,0x20
    8000675e:	9ce50513          	addi	a0,a0,-1586 # 80026128 <disk+0x2128>
    80006762:	ffffa097          	auipc	ra,0xffffa
    80006766:	6ce080e7          	jalr	1742(ra) # 80000e30 <release>
}
    8000676a:	60e2                	ld	ra,24(sp)
    8000676c:	6442                	ld	s0,16(sp)
    8000676e:	64a2                	ld	s1,8(sp)
    80006770:	6902                	ld	s2,0(sp)
    80006772:	6105                	addi	sp,sp,32
    80006774:	8082                	ret
      panic("virtio_disk_intr status");
    80006776:	00002517          	auipc	a0,0x2
    8000677a:	10a50513          	addi	a0,a0,266 # 80008880 <syscalls+0x3c8>
    8000677e:	ffffa097          	auipc	ra,0xffffa
    80006782:	dd2080e7          	jalr	-558(ra) # 80000550 <panic>

0000000080006786 <statswrite>:
int statscopyin(char*, int);
int statslock(char*, int);
  
int
statswrite(int user_src, uint64 src, int n)
{
    80006786:	1141                	addi	sp,sp,-16
    80006788:	e422                	sd	s0,8(sp)
    8000678a:	0800                	addi	s0,sp,16
  return -1;
}
    8000678c:	557d                	li	a0,-1
    8000678e:	6422                	ld	s0,8(sp)
    80006790:	0141                	addi	sp,sp,16
    80006792:	8082                	ret

0000000080006794 <statsread>:

int
statsread(int user_dst, uint64 dst, int n)
{
    80006794:	7179                	addi	sp,sp,-48
    80006796:	f406                	sd	ra,40(sp)
    80006798:	f022                	sd	s0,32(sp)
    8000679a:	ec26                	sd	s1,24(sp)
    8000679c:	e84a                	sd	s2,16(sp)
    8000679e:	e44e                	sd	s3,8(sp)
    800067a0:	e052                	sd	s4,0(sp)
    800067a2:	1800                	addi	s0,sp,48
    800067a4:	892a                	mv	s2,a0
    800067a6:	89ae                	mv	s3,a1
    800067a8:	84b2                	mv	s1,a2
  int m;

  acquire(&stats.lock);
    800067aa:	00021517          	auipc	a0,0x21
    800067ae:	85650513          	addi	a0,a0,-1962 # 80027000 <stats>
    800067b2:	ffffa097          	auipc	ra,0xffffa
    800067b6:	5ae080e7          	jalr	1454(ra) # 80000d60 <acquire>

  if(stats.sz == 0) {
    800067ba:	00022797          	auipc	a5,0x22
    800067be:	8667a783          	lw	a5,-1946(a5) # 80028020 <stats+0x1020>
    800067c2:	cbb5                	beqz	a5,80006836 <statsread+0xa2>
#endif
#ifdef LAB_LOCK
    stats.sz = statslock(stats.buf, BUFSZ);
#endif
  }
  m = stats.sz - stats.off;
    800067c4:	00022797          	auipc	a5,0x22
    800067c8:	83c78793          	addi	a5,a5,-1988 # 80028000 <stats+0x1000>
    800067cc:	53d8                	lw	a4,36(a5)
    800067ce:	539c                	lw	a5,32(a5)
    800067d0:	9f99                	subw	a5,a5,a4
    800067d2:	0007869b          	sext.w	a3,a5

  if (m > 0) {
    800067d6:	06d05e63          	blez	a3,80006852 <statsread+0xbe>
    if(m > n)
    800067da:	8a3e                	mv	s4,a5
    800067dc:	00d4d363          	bge	s1,a3,800067e2 <statsread+0x4e>
    800067e0:	8a26                	mv	s4,s1
    800067e2:	000a049b          	sext.w	s1,s4
      m  = n;
    if(either_copyout(user_dst, dst, stats.buf+stats.off, m) != -1) {
    800067e6:	86a6                	mv	a3,s1
    800067e8:	00021617          	auipc	a2,0x21
    800067ec:	83860613          	addi	a2,a2,-1992 # 80027020 <stats+0x20>
    800067f0:	963a                	add	a2,a2,a4
    800067f2:	85ce                	mv	a1,s3
    800067f4:	854a                	mv	a0,s2
    800067f6:	ffffc097          	auipc	ra,0xffffc
    800067fa:	024080e7          	jalr	36(ra) # 8000281a <either_copyout>
    800067fe:	57fd                	li	a5,-1
    80006800:	00f50a63          	beq	a0,a5,80006814 <statsread+0x80>
      stats.off += m;
    80006804:	00021717          	auipc	a4,0x21
    80006808:	7fc70713          	addi	a4,a4,2044 # 80028000 <stats+0x1000>
    8000680c:	535c                	lw	a5,36(a4)
    8000680e:	014787bb          	addw	a5,a5,s4
    80006812:	d35c                	sw	a5,36(a4)
  } else {
    m = -1;
    stats.sz = 0;
    stats.off = 0;
  }
  release(&stats.lock);
    80006814:	00020517          	auipc	a0,0x20
    80006818:	7ec50513          	addi	a0,a0,2028 # 80027000 <stats>
    8000681c:	ffffa097          	auipc	ra,0xffffa
    80006820:	614080e7          	jalr	1556(ra) # 80000e30 <release>
  return m;
}
    80006824:	8526                	mv	a0,s1
    80006826:	70a2                	ld	ra,40(sp)
    80006828:	7402                	ld	s0,32(sp)
    8000682a:	64e2                	ld	s1,24(sp)
    8000682c:	6942                	ld	s2,16(sp)
    8000682e:	69a2                	ld	s3,8(sp)
    80006830:	6a02                	ld	s4,0(sp)
    80006832:	6145                	addi	sp,sp,48
    80006834:	8082                	ret
    stats.sz = statslock(stats.buf, BUFSZ);
    80006836:	6585                	lui	a1,0x1
    80006838:	00020517          	auipc	a0,0x20
    8000683c:	7e850513          	addi	a0,a0,2024 # 80027020 <stats+0x20>
    80006840:	ffffa097          	auipc	ra,0xffffa
    80006844:	74a080e7          	jalr	1866(ra) # 80000f8a <statslock>
    80006848:	00021797          	auipc	a5,0x21
    8000684c:	7ca7ac23          	sw	a0,2008(a5) # 80028020 <stats+0x1020>
    80006850:	bf95                	j	800067c4 <statsread+0x30>
    stats.sz = 0;
    80006852:	00021797          	auipc	a5,0x21
    80006856:	7ae78793          	addi	a5,a5,1966 # 80028000 <stats+0x1000>
    8000685a:	0207a023          	sw	zero,32(a5)
    stats.off = 0;
    8000685e:	0207a223          	sw	zero,36(a5)
    m = -1;
    80006862:	54fd                	li	s1,-1
    80006864:	bf45                	j	80006814 <statsread+0x80>

0000000080006866 <statsinit>:

void
statsinit(void)
{
    80006866:	1141                	addi	sp,sp,-16
    80006868:	e406                	sd	ra,8(sp)
    8000686a:	e022                	sd	s0,0(sp)
    8000686c:	0800                	addi	s0,sp,16
  initlock(&stats.lock, "stats");
    8000686e:	00002597          	auipc	a1,0x2
    80006872:	02a58593          	addi	a1,a1,42 # 80008898 <syscalls+0x3e0>
    80006876:	00020517          	auipc	a0,0x20
    8000687a:	78a50513          	addi	a0,a0,1930 # 80027000 <stats>
    8000687e:	ffffa097          	auipc	ra,0xffffa
    80006882:	65e080e7          	jalr	1630(ra) # 80000edc <initlock>

  devsw[STATS].read = statsread;
    80006886:	0001c797          	auipc	a5,0x1c
    8000688a:	08a78793          	addi	a5,a5,138 # 80022910 <devsw>
    8000688e:	00000717          	auipc	a4,0x0
    80006892:	f0670713          	addi	a4,a4,-250 # 80006794 <statsread>
    80006896:	f398                	sd	a4,32(a5)
  devsw[STATS].write = statswrite;
    80006898:	00000717          	auipc	a4,0x0
    8000689c:	eee70713          	addi	a4,a4,-274 # 80006786 <statswrite>
    800068a0:	f798                	sd	a4,40(a5)
}
    800068a2:	60a2                	ld	ra,8(sp)
    800068a4:	6402                	ld	s0,0(sp)
    800068a6:	0141                	addi	sp,sp,16
    800068a8:	8082                	ret

00000000800068aa <sprintint>:
  return 1;
}

static int
sprintint(char *s, int xx, int base, int sign)
{
    800068aa:	1101                	addi	sp,sp,-32
    800068ac:	ec22                	sd	s0,24(sp)
    800068ae:	1000                	addi	s0,sp,32
    800068b0:	882a                	mv	a6,a0
  char buf[16];
  int i, n;
  uint x;

  if(sign && (sign = xx < 0))
    800068b2:	c299                	beqz	a3,800068b8 <sprintint+0xe>
    800068b4:	0805c163          	bltz	a1,80006936 <sprintint+0x8c>
    x = -xx;
  else
    x = xx;
    800068b8:	2581                	sext.w	a1,a1
    800068ba:	4301                	li	t1,0

  i = 0;
    800068bc:	fe040713          	addi	a4,s0,-32
    800068c0:	4501                	li	a0,0
  do {
    buf[i++] = digits[x % base];
    800068c2:	2601                	sext.w	a2,a2
    800068c4:	00002697          	auipc	a3,0x2
    800068c8:	fdc68693          	addi	a3,a3,-36 # 800088a0 <digits>
    800068cc:	88aa                	mv	a7,a0
    800068ce:	2505                	addiw	a0,a0,1
    800068d0:	02c5f7bb          	remuw	a5,a1,a2
    800068d4:	1782                	slli	a5,a5,0x20
    800068d6:	9381                	srli	a5,a5,0x20
    800068d8:	97b6                	add	a5,a5,a3
    800068da:	0007c783          	lbu	a5,0(a5)
    800068de:	00f70023          	sb	a5,0(a4)
  } while((x /= base) != 0);
    800068e2:	0005879b          	sext.w	a5,a1
    800068e6:	02c5d5bb          	divuw	a1,a1,a2
    800068ea:	0705                	addi	a4,a4,1
    800068ec:	fec7f0e3          	bgeu	a5,a2,800068cc <sprintint+0x22>

  if(sign)
    800068f0:	00030b63          	beqz	t1,80006906 <sprintint+0x5c>
    buf[i++] = '-';
    800068f4:	ff040793          	addi	a5,s0,-16
    800068f8:	97aa                	add	a5,a5,a0
    800068fa:	02d00713          	li	a4,45
    800068fe:	fee78823          	sb	a4,-16(a5)
    80006902:	0028851b          	addiw	a0,a7,2

  n = 0;
  while(--i >= 0)
    80006906:	02a05c63          	blez	a0,8000693e <sprintint+0x94>
    8000690a:	fe040793          	addi	a5,s0,-32
    8000690e:	00a78733          	add	a4,a5,a0
    80006912:	87c2                	mv	a5,a6
    80006914:	0805                	addi	a6,a6,1
    80006916:	fff5061b          	addiw	a2,a0,-1
    8000691a:	1602                	slli	a2,a2,0x20
    8000691c:	9201                	srli	a2,a2,0x20
    8000691e:	9642                	add	a2,a2,a6
  *s = c;
    80006920:	fff74683          	lbu	a3,-1(a4)
    80006924:	00d78023          	sb	a3,0(a5)
  while(--i >= 0)
    80006928:	177d                	addi	a4,a4,-1
    8000692a:	0785                	addi	a5,a5,1
    8000692c:	fec79ae3          	bne	a5,a2,80006920 <sprintint+0x76>
    n += sputc(s+n, buf[i]);
  return n;
}
    80006930:	6462                	ld	s0,24(sp)
    80006932:	6105                	addi	sp,sp,32
    80006934:	8082                	ret
    x = -xx;
    80006936:	40b005bb          	negw	a1,a1
  if(sign && (sign = xx < 0))
    8000693a:	4305                	li	t1,1
    x = -xx;
    8000693c:	b741                	j	800068bc <sprintint+0x12>
  while(--i >= 0)
    8000693e:	4501                	li	a0,0
    80006940:	bfc5                	j	80006930 <sprintint+0x86>

0000000080006942 <snprintf>:

int
snprintf(char *buf, int sz, char *fmt, ...)
{
    80006942:	7171                	addi	sp,sp,-176
    80006944:	fc86                	sd	ra,120(sp)
    80006946:	f8a2                	sd	s0,112(sp)
    80006948:	f4a6                	sd	s1,104(sp)
    8000694a:	f0ca                	sd	s2,96(sp)
    8000694c:	ecce                	sd	s3,88(sp)
    8000694e:	e8d2                	sd	s4,80(sp)
    80006950:	e4d6                	sd	s5,72(sp)
    80006952:	e0da                	sd	s6,64(sp)
    80006954:	fc5e                	sd	s7,56(sp)
    80006956:	f862                	sd	s8,48(sp)
    80006958:	f466                	sd	s9,40(sp)
    8000695a:	f06a                	sd	s10,32(sp)
    8000695c:	ec6e                	sd	s11,24(sp)
    8000695e:	0100                	addi	s0,sp,128
    80006960:	e414                	sd	a3,8(s0)
    80006962:	e818                	sd	a4,16(s0)
    80006964:	ec1c                	sd	a5,24(s0)
    80006966:	03043023          	sd	a6,32(s0)
    8000696a:	03143423          	sd	a7,40(s0)
  va_list ap;
  int i, c;
  int off = 0;
  char *s;

  if (fmt == 0)
    8000696e:	ca0d                	beqz	a2,800069a0 <snprintf+0x5e>
    80006970:	8baa                	mv	s7,a0
    80006972:	89ae                	mv	s3,a1
    80006974:	8a32                	mv	s4,a2
    panic("null fmt");

  va_start(ap, fmt);
    80006976:	00840793          	addi	a5,s0,8
    8000697a:	f8f43423          	sd	a5,-120(s0)
  int off = 0;
    8000697e:	4481                	li	s1,0
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    80006980:	4901                	li	s2,0
    80006982:	02b05763          	blez	a1,800069b0 <snprintf+0x6e>
    if(c != '%'){
    80006986:	02500a93          	li	s5,37
      continue;
    }
    c = fmt[++i] & 0xff;
    if(c == 0)
      break;
    switch(c){
    8000698a:	07300b13          	li	s6,115
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
      break;
    case 's':
      if((s = va_arg(ap, char*)) == 0)
        s = "(null)";
      for(; *s && off < sz; s++)
    8000698e:	02800d93          	li	s11,40
  *s = c;
    80006992:	02500d13          	li	s10,37
    switch(c){
    80006996:	07800c93          	li	s9,120
    8000699a:	06400c13          	li	s8,100
    8000699e:	a01d                	j	800069c4 <snprintf+0x82>
    panic("null fmt");
    800069a0:	00001517          	auipc	a0,0x1
    800069a4:	68850513          	addi	a0,a0,1672 # 80008028 <etext+0x28>
    800069a8:	ffffa097          	auipc	ra,0xffffa
    800069ac:	ba8080e7          	jalr	-1112(ra) # 80000550 <panic>
  int off = 0;
    800069b0:	4481                	li	s1,0
    800069b2:	a86d                	j	80006a6c <snprintf+0x12a>
  *s = c;
    800069b4:	009b8733          	add	a4,s7,s1
    800069b8:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    800069bc:	2485                	addiw	s1,s1,1
  for(i = 0; off < sz && (c = fmt[i] & 0xff) != 0; i++){
    800069be:	2905                	addiw	s2,s2,1
    800069c0:	0b34d663          	bge	s1,s3,80006a6c <snprintf+0x12a>
    800069c4:	012a07b3          	add	a5,s4,s2
    800069c8:	0007c783          	lbu	a5,0(a5)
    800069cc:	0007871b          	sext.w	a4,a5
    800069d0:	cfd1                	beqz	a5,80006a6c <snprintf+0x12a>
    if(c != '%'){
    800069d2:	ff5711e3          	bne	a4,s5,800069b4 <snprintf+0x72>
    c = fmt[++i] & 0xff;
    800069d6:	2905                	addiw	s2,s2,1
    800069d8:	012a07b3          	add	a5,s4,s2
    800069dc:	0007c783          	lbu	a5,0(a5)
    if(c == 0)
    800069e0:	c7d1                	beqz	a5,80006a6c <snprintf+0x12a>
    switch(c){
    800069e2:	05678c63          	beq	a5,s6,80006a3a <snprintf+0xf8>
    800069e6:	02fb6763          	bltu	s6,a5,80006a14 <snprintf+0xd2>
    800069ea:	0b578763          	beq	a5,s5,80006a98 <snprintf+0x156>
    800069ee:	0b879b63          	bne	a5,s8,80006aa4 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 10, 1);
    800069f2:	f8843783          	ld	a5,-120(s0)
    800069f6:	00878713          	addi	a4,a5,8
    800069fa:	f8e43423          	sd	a4,-120(s0)
    800069fe:	4685                	li	a3,1
    80006a00:	4629                	li	a2,10
    80006a02:	438c                	lw	a1,0(a5)
    80006a04:	009b8533          	add	a0,s7,s1
    80006a08:	00000097          	auipc	ra,0x0
    80006a0c:	ea2080e7          	jalr	-350(ra) # 800068aa <sprintint>
    80006a10:	9ca9                	addw	s1,s1,a0
      break;
    80006a12:	b775                	j	800069be <snprintf+0x7c>
    switch(c){
    80006a14:	09979863          	bne	a5,s9,80006aa4 <snprintf+0x162>
      off += sprintint(buf+off, va_arg(ap, int), 16, 1);
    80006a18:	f8843783          	ld	a5,-120(s0)
    80006a1c:	00878713          	addi	a4,a5,8
    80006a20:	f8e43423          	sd	a4,-120(s0)
    80006a24:	4685                	li	a3,1
    80006a26:	4641                	li	a2,16
    80006a28:	438c                	lw	a1,0(a5)
    80006a2a:	009b8533          	add	a0,s7,s1
    80006a2e:	00000097          	auipc	ra,0x0
    80006a32:	e7c080e7          	jalr	-388(ra) # 800068aa <sprintint>
    80006a36:	9ca9                	addw	s1,s1,a0
      break;
    80006a38:	b759                	j	800069be <snprintf+0x7c>
      if((s = va_arg(ap, char*)) == 0)
    80006a3a:	f8843783          	ld	a5,-120(s0)
    80006a3e:	00878713          	addi	a4,a5,8
    80006a42:	f8e43423          	sd	a4,-120(s0)
    80006a46:	639c                	ld	a5,0(a5)
    80006a48:	c3b1                	beqz	a5,80006a8c <snprintf+0x14a>
      for(; *s && off < sz; s++)
    80006a4a:	0007c703          	lbu	a4,0(a5)
    80006a4e:	db25                	beqz	a4,800069be <snprintf+0x7c>
    80006a50:	0134de63          	bge	s1,s3,80006a6c <snprintf+0x12a>
    80006a54:	009b86b3          	add	a3,s7,s1
  *s = c;
    80006a58:	00e68023          	sb	a4,0(a3)
        off += sputc(buf+off, *s);
    80006a5c:	2485                	addiw	s1,s1,1
      for(; *s && off < sz; s++)
    80006a5e:	0785                	addi	a5,a5,1
    80006a60:	0007c703          	lbu	a4,0(a5)
    80006a64:	df29                	beqz	a4,800069be <snprintf+0x7c>
    80006a66:	0685                	addi	a3,a3,1
    80006a68:	fe9998e3          	bne	s3,s1,80006a58 <snprintf+0x116>
      off += sputc(buf+off, c);
      break;
    }
  }
  return off;
}
    80006a6c:	8526                	mv	a0,s1
    80006a6e:	70e6                	ld	ra,120(sp)
    80006a70:	7446                	ld	s0,112(sp)
    80006a72:	74a6                	ld	s1,104(sp)
    80006a74:	7906                	ld	s2,96(sp)
    80006a76:	69e6                	ld	s3,88(sp)
    80006a78:	6a46                	ld	s4,80(sp)
    80006a7a:	6aa6                	ld	s5,72(sp)
    80006a7c:	6b06                	ld	s6,64(sp)
    80006a7e:	7be2                	ld	s7,56(sp)
    80006a80:	7c42                	ld	s8,48(sp)
    80006a82:	7ca2                	ld	s9,40(sp)
    80006a84:	7d02                	ld	s10,32(sp)
    80006a86:	6de2                	ld	s11,24(sp)
    80006a88:	614d                	addi	sp,sp,176
    80006a8a:	8082                	ret
        s = "(null)";
    80006a8c:	00001797          	auipc	a5,0x1
    80006a90:	59478793          	addi	a5,a5,1428 # 80008020 <etext+0x20>
      for(; *s && off < sz; s++)
    80006a94:	876e                	mv	a4,s11
    80006a96:	bf6d                	j	80006a50 <snprintf+0x10e>
  *s = c;
    80006a98:	009b87b3          	add	a5,s7,s1
    80006a9c:	01a78023          	sb	s10,0(a5)
      off += sputc(buf+off, '%');
    80006aa0:	2485                	addiw	s1,s1,1
      break;
    80006aa2:	bf31                	j	800069be <snprintf+0x7c>
  *s = c;
    80006aa4:	009b8733          	add	a4,s7,s1
    80006aa8:	01a70023          	sb	s10,0(a4)
      off += sputc(buf+off, c);
    80006aac:	0014871b          	addiw	a4,s1,1
  *s = c;
    80006ab0:	975e                	add	a4,a4,s7
    80006ab2:	00f70023          	sb	a5,0(a4)
      off += sputc(buf+off, c);
    80006ab6:	2489                	addiw	s1,s1,2
      break;
    80006ab8:	b719                	j	800069be <snprintf+0x7c>
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
