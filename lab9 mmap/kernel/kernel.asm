
kernel/kernel：     文件格式 elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
_entry:
	# set up a stack for C.
        # stack0 is declared in start.c,
        # with a 4096-byte stack per CPU.
        # sp = stack0 + (hartid * 4096)
        la sp, stack0
    80000000:	00009117          	auipc	sp,0x9
    80000004:	87013103          	ld	sp,-1936(sp) # 80008870 <_GLOBAL_OFFSET_TABLE_+0x8>
        li a0, 1024*4
    80000008:	6505                	lui	a0,0x1
	csrr a1, mhartid
    8000000a:	f14025f3          	csrr	a1,mhartid
        addi a1, a1, 1
    8000000e:	0585                	addi	a1,a1,1
        mul a0, a0, a1
    80000010:	02b50533          	mul	a0,a0,a1
        add sp, sp, a0
    80000014:	912a                	add	sp,sp,a0
	# jump to start() in start.c
        call start
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
spin:
        j spin
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000068:	4ac78793          	addi	a5,a5,1196 # 80006510 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffd87ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	f1478793          	addi	a5,a5,-236 # 80000fc2 <main>
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
  int i;

  for(i = 0; i < n; i++){
    80000106:	04c05663          	blez	a2,80000152 <consolewrite+0x5e>
    8000010a:	8a2a                	mv	s4,a0
    8000010c:	84ae                	mv	s1,a1
    8000010e:	89b2                	mv	s3,a2
    80000110:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000112:	5afd                	li	s5,-1
    80000114:	4685                	li	a3,1
    80000116:	8626                	mv	a2,s1
    80000118:	85d2                	mv	a1,s4
    8000011a:	fbf40513          	addi	a0,s0,-65
    8000011e:	00003097          	auipc	ra,0x3
    80000122:	cd2080e7          	jalr	-814(ra) # 80002df0 <either_copyin>
    80000126:	01550c63          	beq	a0,s5,8000013e <consolewrite+0x4a>
      break;
    uartputc(c);
    8000012a:	fbf44503          	lbu	a0,-65(s0)
    8000012e:	00000097          	auipc	ra,0x0
    80000132:	78e080e7          	jalr	1934(ra) # 800008bc <uartputc>
  for(i = 0; i < n; i++){
    80000136:	2905                	addiw	s2,s2,1
    80000138:	0485                	addi	s1,s1,1
    8000013a:	fd299de3          	bne	s3,s2,80000114 <consolewrite+0x20>
  }

  return i;
}
    8000013e:	854a                	mv	a0,s2
    80000140:	60a6                	ld	ra,72(sp)
    80000142:	6406                	ld	s0,64(sp)
    80000144:	74e2                	ld	s1,56(sp)
    80000146:	7942                	ld	s2,48(sp)
    80000148:	79a2                	ld	s3,40(sp)
    8000014a:	7a02                	ld	s4,32(sp)
    8000014c:	6ae2                	ld	s5,24(sp)
    8000014e:	6161                	addi	sp,sp,80
    80000150:	8082                	ret
  for(i = 0; i < n; i++){
    80000152:	4901                	li	s2,0
    80000154:	b7ed                	j	8000013e <consolewrite+0x4a>

0000000080000156 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000156:	7119                	addi	sp,sp,-128
    80000158:	fc86                	sd	ra,120(sp)
    8000015a:	f8a2                	sd	s0,112(sp)
    8000015c:	f4a6                	sd	s1,104(sp)
    8000015e:	f0ca                	sd	s2,96(sp)
    80000160:	ecce                	sd	s3,88(sp)
    80000162:	e8d2                	sd	s4,80(sp)
    80000164:	e4d6                	sd	s5,72(sp)
    80000166:	e0da                	sd	s6,64(sp)
    80000168:	fc5e                	sd	s7,56(sp)
    8000016a:	f862                	sd	s8,48(sp)
    8000016c:	f466                	sd	s9,40(sp)
    8000016e:	f06a                	sd	s10,32(sp)
    80000170:	ec6e                	sd	s11,24(sp)
    80000172:	0100                	addi	s0,sp,128
    80000174:	8b2a                	mv	s6,a0
    80000176:	8aae                	mv	s5,a1
    80000178:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    8000017a:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000017e:	00011517          	auipc	a0,0x11
    80000182:	00250513          	addi	a0,a0,2 # 80011180 <cons>
    80000186:	00001097          	auipc	ra,0x1
    8000018a:	b8e080e7          	jalr	-1138(ra) # 80000d14 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000018e:	00011497          	auipc	s1,0x11
    80000192:	ff248493          	addi	s1,s1,-14 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    80000196:	89a6                	mv	s3,s1
    80000198:	00011917          	auipc	s2,0x11
    8000019c:	08090913          	addi	s2,s2,128 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

    if(c == C('D')){  // end-of-file
    800001a0:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001a2:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001a4:	4da9                	li	s11,10
  while(n > 0){
    800001a6:	07405863          	blez	s4,80000216 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001aa:	0984a783          	lw	a5,152(s1)
    800001ae:	09c4a703          	lw	a4,156(s1)
    800001b2:	02f71463          	bne	a4,a5,800001da <consoleread+0x84>
      if(myproc()->killed){
    800001b6:	00002097          	auipc	ra,0x2
    800001ba:	020080e7          	jalr	32(ra) # 800021d6 <myproc>
    800001be:	591c                	lw	a5,48(a0)
    800001c0:	e7b5                	bnez	a5,8000022c <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001c2:	85ce                	mv	a1,s3
    800001c4:	854a                	mv	a0,s2
    800001c6:	00003097          	auipc	ra,0x3
    800001ca:	972080e7          	jalr	-1678(ra) # 80002b38 <sleep>
    while(cons.r == cons.w){
    800001ce:	0984a783          	lw	a5,152(s1)
    800001d2:	09c4a703          	lw	a4,156(s1)
    800001d6:	fef700e3          	beq	a4,a5,800001b6 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001da:	0017871b          	addiw	a4,a5,1
    800001de:	08e4ac23          	sw	a4,152(s1)
    800001e2:	07f7f713          	andi	a4,a5,127
    800001e6:	9726                	add	a4,a4,s1
    800001e8:	01874703          	lbu	a4,24(a4)
    800001ec:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001f0:	079c0663          	beq	s8,s9,8000025c <consoleread+0x106>
    cbuf = c;
    800001f4:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001f8:	4685                	li	a3,1
    800001fa:	f8f40613          	addi	a2,s0,-113
    800001fe:	85d6                	mv	a1,s5
    80000200:	855a                	mv	a0,s6
    80000202:	00003097          	auipc	ra,0x3
    80000206:	b98080e7          	jalr	-1128(ra) # 80002d9a <either_copyout>
    8000020a:	01a50663          	beq	a0,s10,80000216 <consoleread+0xc0>
    dst++;
    8000020e:	0a85                	addi	s5,s5,1
    --n;
    80000210:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000212:	f9bc1ae3          	bne	s8,s11,800001a6 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000216:	00011517          	auipc	a0,0x11
    8000021a:	f6a50513          	addi	a0,a0,-150 # 80011180 <cons>
    8000021e:	00001097          	auipc	ra,0x1
    80000222:	baa080e7          	jalr	-1110(ra) # 80000dc8 <release>

  return target - n;
    80000226:	414b853b          	subw	a0,s7,s4
    8000022a:	a811                	j	8000023e <consoleread+0xe8>
        release(&cons.lock);
    8000022c:	00011517          	auipc	a0,0x11
    80000230:	f5450513          	addi	a0,a0,-172 # 80011180 <cons>
    80000234:	00001097          	auipc	ra,0x1
    80000238:	b94080e7          	jalr	-1132(ra) # 80000dc8 <release>
        return -1;
    8000023c:	557d                	li	a0,-1
}
    8000023e:	70e6                	ld	ra,120(sp)
    80000240:	7446                	ld	s0,112(sp)
    80000242:	74a6                	ld	s1,104(sp)
    80000244:	7906                	ld	s2,96(sp)
    80000246:	69e6                	ld	s3,88(sp)
    80000248:	6a46                	ld	s4,80(sp)
    8000024a:	6aa6                	ld	s5,72(sp)
    8000024c:	6b06                	ld	s6,64(sp)
    8000024e:	7be2                	ld	s7,56(sp)
    80000250:	7c42                	ld	s8,48(sp)
    80000252:	7ca2                	ld	s9,40(sp)
    80000254:	7d02                	ld	s10,32(sp)
    80000256:	6de2                	ld	s11,24(sp)
    80000258:	6109                	addi	sp,sp,128
    8000025a:	8082                	ret
      if(n < target){
    8000025c:	000a071b          	sext.w	a4,s4
    80000260:	fb777be3          	bgeu	a4,s7,80000216 <consoleread+0xc0>
        cons.r--;
    80000264:	00011717          	auipc	a4,0x11
    80000268:	faf72a23          	sw	a5,-76(a4) # 80011218 <cons+0x98>
    8000026c:	b76d                	j	80000216 <consoleread+0xc0>

000000008000026e <consputc>:
{
    8000026e:	1141                	addi	sp,sp,-16
    80000270:	e406                	sd	ra,8(sp)
    80000272:	e022                	sd	s0,0(sp)
    80000274:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000276:	10000793          	li	a5,256
    8000027a:	00f50a63          	beq	a0,a5,8000028e <consputc+0x20>
    uartputc_sync(c);
    8000027e:	00000097          	auipc	ra,0x0
    80000282:	564080e7          	jalr	1380(ra) # 800007e2 <uartputc_sync>
}
    80000286:	60a2                	ld	ra,8(sp)
    80000288:	6402                	ld	s0,0(sp)
    8000028a:	0141                	addi	sp,sp,16
    8000028c:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000028e:	4521                	li	a0,8
    80000290:	00000097          	auipc	ra,0x0
    80000294:	552080e7          	jalr	1362(ra) # 800007e2 <uartputc_sync>
    80000298:	02000513          	li	a0,32
    8000029c:	00000097          	auipc	ra,0x0
    800002a0:	546080e7          	jalr	1350(ra) # 800007e2 <uartputc_sync>
    800002a4:	4521                	li	a0,8
    800002a6:	00000097          	auipc	ra,0x0
    800002aa:	53c080e7          	jalr	1340(ra) # 800007e2 <uartputc_sync>
    800002ae:	bfe1                	j	80000286 <consputc+0x18>

00000000800002b0 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002b0:	1101                	addi	sp,sp,-32
    800002b2:	ec06                	sd	ra,24(sp)
    800002b4:	e822                	sd	s0,16(sp)
    800002b6:	e426                	sd	s1,8(sp)
    800002b8:	e04a                	sd	s2,0(sp)
    800002ba:	1000                	addi	s0,sp,32
    800002bc:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002be:	00011517          	auipc	a0,0x11
    800002c2:	ec250513          	addi	a0,a0,-318 # 80011180 <cons>
    800002c6:	00001097          	auipc	ra,0x1
    800002ca:	a4e080e7          	jalr	-1458(ra) # 80000d14 <acquire>

  switch(c){
    800002ce:	47d5                	li	a5,21
    800002d0:	0af48663          	beq	s1,a5,8000037c <consoleintr+0xcc>
    800002d4:	0297ca63          	blt	a5,s1,80000308 <consoleintr+0x58>
    800002d8:	47a1                	li	a5,8
    800002da:	0ef48763          	beq	s1,a5,800003c8 <consoleintr+0x118>
    800002de:	47c1                	li	a5,16
    800002e0:	10f49a63          	bne	s1,a5,800003f4 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002e4:	00003097          	auipc	ra,0x3
    800002e8:	b62080e7          	jalr	-1182(ra) # 80002e46 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002ec:	00011517          	auipc	a0,0x11
    800002f0:	e9450513          	addi	a0,a0,-364 # 80011180 <cons>
    800002f4:	00001097          	auipc	ra,0x1
    800002f8:	ad4080e7          	jalr	-1324(ra) # 80000dc8 <release>
}
    800002fc:	60e2                	ld	ra,24(sp)
    800002fe:	6442                	ld	s0,16(sp)
    80000300:	64a2                	ld	s1,8(sp)
    80000302:	6902                	ld	s2,0(sp)
    80000304:	6105                	addi	sp,sp,32
    80000306:	8082                	ret
  switch(c){
    80000308:	07f00793          	li	a5,127
    8000030c:	0af48e63          	beq	s1,a5,800003c8 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000310:	00011717          	auipc	a4,0x11
    80000314:	e7070713          	addi	a4,a4,-400 # 80011180 <cons>
    80000318:	0a072783          	lw	a5,160(a4)
    8000031c:	09872703          	lw	a4,152(a4)
    80000320:	9f99                	subw	a5,a5,a4
    80000322:	07f00713          	li	a4,127
    80000326:	fcf763e3          	bltu	a4,a5,800002ec <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000032a:	47b5                	li	a5,13
    8000032c:	0cf48763          	beq	s1,a5,800003fa <consoleintr+0x14a>
      consputc(c);
    80000330:	8526                	mv	a0,s1
    80000332:	00000097          	auipc	ra,0x0
    80000336:	f3c080e7          	jalr	-196(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    8000033a:	00011797          	auipc	a5,0x11
    8000033e:	e4678793          	addi	a5,a5,-442 # 80011180 <cons>
    80000342:	0a07a703          	lw	a4,160(a5)
    80000346:	0017069b          	addiw	a3,a4,1
    8000034a:	0006861b          	sext.w	a2,a3
    8000034e:	0ad7a023          	sw	a3,160(a5)
    80000352:	07f77713          	andi	a4,a4,127
    80000356:	97ba                	add	a5,a5,a4
    80000358:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000035c:	47a9                	li	a5,10
    8000035e:	0cf48563          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000362:	4791                	li	a5,4
    80000364:	0cf48263          	beq	s1,a5,80000428 <consoleintr+0x178>
    80000368:	00011797          	auipc	a5,0x11
    8000036c:	eb07a783          	lw	a5,-336(a5) # 80011218 <cons+0x98>
    80000370:	0807879b          	addiw	a5,a5,128
    80000374:	f6f61ce3          	bne	a2,a5,800002ec <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000378:	863e                	mv	a2,a5
    8000037a:	a07d                	j	80000428 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000037c:	00011717          	auipc	a4,0x11
    80000380:	e0470713          	addi	a4,a4,-508 # 80011180 <cons>
    80000384:	0a072783          	lw	a5,160(a4)
    80000388:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000038c:	00011497          	auipc	s1,0x11
    80000390:	df448493          	addi	s1,s1,-524 # 80011180 <cons>
    while(cons.e != cons.w &&
    80000394:	4929                	li	s2,10
    80000396:	f4f70be3          	beq	a4,a5,800002ec <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	37fd                	addiw	a5,a5,-1
    8000039c:	07f7f713          	andi	a4,a5,127
    800003a0:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003a2:	01874703          	lbu	a4,24(a4)
    800003a6:	f52703e3          	beq	a4,s2,800002ec <consoleintr+0x3c>
      cons.e--;
    800003aa:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003ae:	10000513          	li	a0,256
    800003b2:	00000097          	auipc	ra,0x0
    800003b6:	ebc080e7          	jalr	-324(ra) # 8000026e <consputc>
    while(cons.e != cons.w &&
    800003ba:	0a04a783          	lw	a5,160(s1)
    800003be:	09c4a703          	lw	a4,156(s1)
    800003c2:	fcf71ce3          	bne	a4,a5,8000039a <consoleintr+0xea>
    800003c6:	b71d                	j	800002ec <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003c8:	00011717          	auipc	a4,0x11
    800003cc:	db870713          	addi	a4,a4,-584 # 80011180 <cons>
    800003d0:	0a072783          	lw	a5,160(a4)
    800003d4:	09c72703          	lw	a4,156(a4)
    800003d8:	f0f70ae3          	beq	a4,a5,800002ec <consoleintr+0x3c>
      cons.e--;
    800003dc:	37fd                	addiw	a5,a5,-1
    800003de:	00011717          	auipc	a4,0x11
    800003e2:	e4f72123          	sw	a5,-446(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003e6:	10000513          	li	a0,256
    800003ea:	00000097          	auipc	ra,0x0
    800003ee:	e84080e7          	jalr	-380(ra) # 8000026e <consputc>
    800003f2:	bded                	j	800002ec <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    800003f4:	ee048ce3          	beqz	s1,800002ec <consoleintr+0x3c>
    800003f8:	bf21                	j	80000310 <consoleintr+0x60>
      consputc(c);
    800003fa:	4529                	li	a0,10
    800003fc:	00000097          	auipc	ra,0x0
    80000400:	e72080e7          	jalr	-398(ra) # 8000026e <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000404:	00011797          	auipc	a5,0x11
    80000408:	d7c78793          	addi	a5,a5,-644 # 80011180 <cons>
    8000040c:	0a07a703          	lw	a4,160(a5)
    80000410:	0017069b          	addiw	a3,a4,1
    80000414:	0006861b          	sext.w	a2,a3
    80000418:	0ad7a023          	sw	a3,160(a5)
    8000041c:	07f77713          	andi	a4,a4,127
    80000420:	97ba                	add	a5,a5,a4
    80000422:	4729                	li	a4,10
    80000424:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000428:	00011797          	auipc	a5,0x11
    8000042c:	dec7aa23          	sw	a2,-524(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    80000430:	00011517          	auipc	a0,0x11
    80000434:	de850513          	addi	a0,a0,-536 # 80011218 <cons+0x98>
    80000438:	00003097          	auipc	ra,0x3
    8000043c:	886080e7          	jalr	-1914(ra) # 80002cbe <wakeup>
    80000440:	b575                	j	800002ec <consoleintr+0x3c>

0000000080000442 <consoleinit>:

void
consoleinit(void)
{
    80000442:	1141                	addi	sp,sp,-16
    80000444:	e406                	sd	ra,8(sp)
    80000446:	e022                	sd	s0,0(sp)
    80000448:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000044a:	00008597          	auipc	a1,0x8
    8000044e:	bc658593          	addi	a1,a1,-1082 # 80008010 <etext+0x10>
    80000452:	00011517          	auipc	a0,0x11
    80000456:	d2e50513          	addi	a0,a0,-722 # 80011180 <cons>
    8000045a:	00001097          	auipc	ra,0x1
    8000045e:	82a080e7          	jalr	-2006(ra) # 80000c84 <initlock>

  uartinit();
    80000462:	00000097          	auipc	ra,0x0
    80000466:	330080e7          	jalr	816(ra) # 80000792 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000046a:	00021797          	auipc	a5,0x21
    8000046e:	0b678793          	addi	a5,a5,182 # 80021520 <devsw>
    80000472:	00000717          	auipc	a4,0x0
    80000476:	ce470713          	addi	a4,a4,-796 # 80000156 <consoleread>
    8000047a:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000047c:	00000717          	auipc	a4,0x0
    80000480:	c7870713          	addi	a4,a4,-904 # 800000f4 <consolewrite>
    80000484:	ef98                	sd	a4,24(a5)
}
    80000486:	60a2                	ld	ra,8(sp)
    80000488:	6402                	ld	s0,0(sp)
    8000048a:	0141                	addi	sp,sp,16
    8000048c:	8082                	ret

000000008000048e <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000048e:	7179                	addi	sp,sp,-48
    80000490:	f406                	sd	ra,40(sp)
    80000492:	f022                	sd	s0,32(sp)
    80000494:	ec26                	sd	s1,24(sp)
    80000496:	e84a                	sd	s2,16(sp)
    80000498:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    8000049a:	c219                	beqz	a2,800004a0 <printint+0x12>
    8000049c:	08054663          	bltz	a0,80000528 <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004a0:	2501                	sext.w	a0,a0
    800004a2:	4881                	li	a7,0
    800004a4:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004a8:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004aa:	2581                	sext.w	a1,a1
    800004ac:	00008617          	auipc	a2,0x8
    800004b0:	b9460613          	addi	a2,a2,-1132 # 80008040 <digits>
    800004b4:	883a                	mv	a6,a4
    800004b6:	2705                	addiw	a4,a4,1
    800004b8:	02b577bb          	remuw	a5,a0,a1
    800004bc:	1782                	slli	a5,a5,0x20
    800004be:	9381                	srli	a5,a5,0x20
    800004c0:	97b2                	add	a5,a5,a2
    800004c2:	0007c783          	lbu	a5,0(a5)
    800004c6:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004ca:	0005079b          	sext.w	a5,a0
    800004ce:	02b5553b          	divuw	a0,a0,a1
    800004d2:	0685                	addi	a3,a3,1
    800004d4:	feb7f0e3          	bgeu	a5,a1,800004b4 <printint+0x26>

  if(sign)
    800004d8:	00088b63          	beqz	a7,800004ee <printint+0x60>
    buf[i++] = '-';
    800004dc:	fe040793          	addi	a5,s0,-32
    800004e0:	973e                	add	a4,a4,a5
    800004e2:	02d00793          	li	a5,45
    800004e6:	fef70823          	sb	a5,-16(a4)
    800004ea:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004ee:	02e05763          	blez	a4,8000051c <printint+0x8e>
    800004f2:	fd040793          	addi	a5,s0,-48
    800004f6:	00e784b3          	add	s1,a5,a4
    800004fa:	fff78913          	addi	s2,a5,-1
    800004fe:	993a                	add	s2,s2,a4
    80000500:	377d                	addiw	a4,a4,-1
    80000502:	1702                	slli	a4,a4,0x20
    80000504:	9301                	srli	a4,a4,0x20
    80000506:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000050a:	fff4c503          	lbu	a0,-1(s1)
    8000050e:	00000097          	auipc	ra,0x0
    80000512:	d60080e7          	jalr	-672(ra) # 8000026e <consputc>
  while(--i >= 0)
    80000516:	14fd                	addi	s1,s1,-1
    80000518:	ff2499e3          	bne	s1,s2,8000050a <printint+0x7c>
}
    8000051c:	70a2                	ld	ra,40(sp)
    8000051e:	7402                	ld	s0,32(sp)
    80000520:	64e2                	ld	s1,24(sp)
    80000522:	6942                	ld	s2,16(sp)
    80000524:	6145                	addi	sp,sp,48
    80000526:	8082                	ret
    x = -xx;
    80000528:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000052c:	4885                	li	a7,1
    x = -xx;
    8000052e:	bf9d                	j	800004a4 <printint+0x16>

0000000080000530 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000530:	1101                	addi	sp,sp,-32
    80000532:	ec06                	sd	ra,24(sp)
    80000534:	e822                	sd	s0,16(sp)
    80000536:	e426                	sd	s1,8(sp)
    80000538:	1000                	addi	s0,sp,32
    8000053a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000053c:	00011797          	auipc	a5,0x11
    80000540:	d007a223          	sw	zero,-764(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000544:	00008517          	auipc	a0,0x8
    80000548:	ad450513          	addi	a0,a0,-1324 # 80008018 <etext+0x18>
    8000054c:	00000097          	auipc	ra,0x0
    80000550:	02e080e7          	jalr	46(ra) # 8000057a <printf>
  printf(s);
    80000554:	8526                	mv	a0,s1
    80000556:	00000097          	auipc	ra,0x0
    8000055a:	024080e7          	jalr	36(ra) # 8000057a <printf>
  printf("\n");
    8000055e:	00008517          	auipc	a0,0x8
    80000562:	b8250513          	addi	a0,a0,-1150 # 800080e0 <digits+0xa0>
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	014080e7          	jalr	20(ra) # 8000057a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000056e:	4785                	li	a5,1
    80000570:	00009717          	auipc	a4,0x9
    80000574:	a8f72823          	sw	a5,-1392(a4) # 80009000 <panicked>
  for(;;)
    80000578:	a001                	j	80000578 <panic+0x48>

000000008000057a <printf>:
{
    8000057a:	7131                	addi	sp,sp,-192
    8000057c:	fc86                	sd	ra,120(sp)
    8000057e:	f8a2                	sd	s0,112(sp)
    80000580:	f4a6                	sd	s1,104(sp)
    80000582:	f0ca                	sd	s2,96(sp)
    80000584:	ecce                	sd	s3,88(sp)
    80000586:	e8d2                	sd	s4,80(sp)
    80000588:	e4d6                	sd	s5,72(sp)
    8000058a:	e0da                	sd	s6,64(sp)
    8000058c:	fc5e                	sd	s7,56(sp)
    8000058e:	f862                	sd	s8,48(sp)
    80000590:	f466                	sd	s9,40(sp)
    80000592:	f06a                	sd	s10,32(sp)
    80000594:	ec6e                	sd	s11,24(sp)
    80000596:	0100                	addi	s0,sp,128
    80000598:	8a2a                	mv	s4,a0
    8000059a:	e40c                	sd	a1,8(s0)
    8000059c:	e810                	sd	a2,16(s0)
    8000059e:	ec14                	sd	a3,24(s0)
    800005a0:	f018                	sd	a4,32(s0)
    800005a2:	f41c                	sd	a5,40(s0)
    800005a4:	03043823          	sd	a6,48(s0)
    800005a8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ac:	00011d97          	auipc	s11,0x11
    800005b0:	c94dad83          	lw	s11,-876(s11) # 80011240 <pr+0x18>
  if(locking)
    800005b4:	020d9b63          	bnez	s11,800005ea <printf+0x70>
  if (fmt == 0)
    800005b8:	040a0263          	beqz	s4,800005fc <printf+0x82>
  va_start(ap, fmt);
    800005bc:	00840793          	addi	a5,s0,8
    800005c0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005c4:	000a4503          	lbu	a0,0(s4)
    800005c8:	16050263          	beqz	a0,8000072c <printf+0x1b2>
    800005cc:	4481                	li	s1,0
    if(c != '%'){
    800005ce:	02500a93          	li	s5,37
    switch(c){
    800005d2:	07000b13          	li	s6,112
  consputc('x');
    800005d6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005d8:	00008b97          	auipc	s7,0x8
    800005dc:	a68b8b93          	addi	s7,s7,-1432 # 80008040 <digits>
    switch(c){
    800005e0:	07300c93          	li	s9,115
    800005e4:	06400c13          	li	s8,100
    800005e8:	a82d                	j	80000622 <printf+0xa8>
    acquire(&pr.lock);
    800005ea:	00011517          	auipc	a0,0x11
    800005ee:	c3e50513          	addi	a0,a0,-962 # 80011228 <pr>
    800005f2:	00000097          	auipc	ra,0x0
    800005f6:	722080e7          	jalr	1826(ra) # 80000d14 <acquire>
    800005fa:	bf7d                	j	800005b8 <printf+0x3e>
    panic("null fmt");
    800005fc:	00008517          	auipc	a0,0x8
    80000600:	a2c50513          	addi	a0,a0,-1492 # 80008028 <etext+0x28>
    80000604:	00000097          	auipc	ra,0x0
    80000608:	f2c080e7          	jalr	-212(ra) # 80000530 <panic>
      consputc(c);
    8000060c:	00000097          	auipc	ra,0x0
    80000610:	c62080e7          	jalr	-926(ra) # 8000026e <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000614:	2485                	addiw	s1,s1,1
    80000616:	009a07b3          	add	a5,s4,s1
    8000061a:	0007c503          	lbu	a0,0(a5)
    8000061e:	10050763          	beqz	a0,8000072c <printf+0x1b2>
    if(c != '%'){
    80000622:	ff5515e3          	bne	a0,s5,8000060c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000626:	2485                	addiw	s1,s1,1
    80000628:	009a07b3          	add	a5,s4,s1
    8000062c:	0007c783          	lbu	a5,0(a5)
    80000630:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000634:	cfe5                	beqz	a5,8000072c <printf+0x1b2>
    switch(c){
    80000636:	05678a63          	beq	a5,s6,8000068a <printf+0x110>
    8000063a:	02fb7663          	bgeu	s6,a5,80000666 <printf+0xec>
    8000063e:	09978963          	beq	a5,s9,800006d0 <printf+0x156>
    80000642:	07800713          	li	a4,120
    80000646:	0ce79863          	bne	a5,a4,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000064a:	f8843783          	ld	a5,-120(s0)
    8000064e:	00878713          	addi	a4,a5,8
    80000652:	f8e43423          	sd	a4,-120(s0)
    80000656:	4605                	li	a2,1
    80000658:	85ea                	mv	a1,s10
    8000065a:	4388                	lw	a0,0(a5)
    8000065c:	00000097          	auipc	ra,0x0
    80000660:	e32080e7          	jalr	-462(ra) # 8000048e <printint>
      break;
    80000664:	bf45                	j	80000614 <printf+0x9a>
    switch(c){
    80000666:	0b578263          	beq	a5,s5,8000070a <printf+0x190>
    8000066a:	0b879663          	bne	a5,s8,80000716 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000066e:	f8843783          	ld	a5,-120(s0)
    80000672:	00878713          	addi	a4,a5,8
    80000676:	f8e43423          	sd	a4,-120(s0)
    8000067a:	4605                	li	a2,1
    8000067c:	45a9                	li	a1,10
    8000067e:	4388                	lw	a0,0(a5)
    80000680:	00000097          	auipc	ra,0x0
    80000684:	e0e080e7          	jalr	-498(ra) # 8000048e <printint>
      break;
    80000688:	b771                	j	80000614 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000068a:	f8843783          	ld	a5,-120(s0)
    8000068e:	00878713          	addi	a4,a5,8
    80000692:	f8e43423          	sd	a4,-120(s0)
    80000696:	0007b983          	ld	s3,0(a5)
  consputc('0');
    8000069a:	03000513          	li	a0,48
    8000069e:	00000097          	auipc	ra,0x0
    800006a2:	bd0080e7          	jalr	-1072(ra) # 8000026e <consputc>
  consputc('x');
    800006a6:	07800513          	li	a0,120
    800006aa:	00000097          	auipc	ra,0x0
    800006ae:	bc4080e7          	jalr	-1084(ra) # 8000026e <consputc>
    800006b2:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006b4:	03c9d793          	srli	a5,s3,0x3c
    800006b8:	97de                	add	a5,a5,s7
    800006ba:	0007c503          	lbu	a0,0(a5)
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bb0080e7          	jalr	-1104(ra) # 8000026e <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006c6:	0992                	slli	s3,s3,0x4
    800006c8:	397d                	addiw	s2,s2,-1
    800006ca:	fe0915e3          	bnez	s2,800006b4 <printf+0x13a>
    800006ce:	b799                	j	80000614 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006d0:	f8843783          	ld	a5,-120(s0)
    800006d4:	00878713          	addi	a4,a5,8
    800006d8:	f8e43423          	sd	a4,-120(s0)
    800006dc:	0007b903          	ld	s2,0(a5)
    800006e0:	00090e63          	beqz	s2,800006fc <printf+0x182>
      for(; *s; s++)
    800006e4:	00094503          	lbu	a0,0(s2)
    800006e8:	d515                	beqz	a0,80000614 <printf+0x9a>
        consputc(*s);
    800006ea:	00000097          	auipc	ra,0x0
    800006ee:	b84080e7          	jalr	-1148(ra) # 8000026e <consputc>
      for(; *s; s++)
    800006f2:	0905                	addi	s2,s2,1
    800006f4:	00094503          	lbu	a0,0(s2)
    800006f8:	f96d                	bnez	a0,800006ea <printf+0x170>
    800006fa:	bf29                	j	80000614 <printf+0x9a>
        s = "(null)";
    800006fc:	00008917          	auipc	s2,0x8
    80000700:	92490913          	addi	s2,s2,-1756 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000704:	02800513          	li	a0,40
    80000708:	b7cd                	j	800006ea <printf+0x170>
      consputc('%');
    8000070a:	8556                	mv	a0,s5
    8000070c:	00000097          	auipc	ra,0x0
    80000710:	b62080e7          	jalr	-1182(ra) # 8000026e <consputc>
      break;
    80000714:	b701                	j	80000614 <printf+0x9a>
      consputc('%');
    80000716:	8556                	mv	a0,s5
    80000718:	00000097          	auipc	ra,0x0
    8000071c:	b56080e7          	jalr	-1194(ra) # 8000026e <consputc>
      consputc(c);
    80000720:	854a                	mv	a0,s2
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b4c080e7          	jalr	-1204(ra) # 8000026e <consputc>
      break;
    8000072a:	b5ed                	j	80000614 <printf+0x9a>
  if(locking)
    8000072c:	020d9163          	bnez	s11,8000074e <printf+0x1d4>
}
    80000730:	70e6                	ld	ra,120(sp)
    80000732:	7446                	ld	s0,112(sp)
    80000734:	74a6                	ld	s1,104(sp)
    80000736:	7906                	ld	s2,96(sp)
    80000738:	69e6                	ld	s3,88(sp)
    8000073a:	6a46                	ld	s4,80(sp)
    8000073c:	6aa6                	ld	s5,72(sp)
    8000073e:	6b06                	ld	s6,64(sp)
    80000740:	7be2                	ld	s7,56(sp)
    80000742:	7c42                	ld	s8,48(sp)
    80000744:	7ca2                	ld	s9,40(sp)
    80000746:	7d02                	ld	s10,32(sp)
    80000748:	6de2                	ld	s11,24(sp)
    8000074a:	6129                	addi	sp,sp,192
    8000074c:	8082                	ret
    release(&pr.lock);
    8000074e:	00011517          	auipc	a0,0x11
    80000752:	ada50513          	addi	a0,a0,-1318 # 80011228 <pr>
    80000756:	00000097          	auipc	ra,0x0
    8000075a:	672080e7          	jalr	1650(ra) # 80000dc8 <release>
}
    8000075e:	bfc9                	j	80000730 <printf+0x1b6>

0000000080000760 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000760:	1101                	addi	sp,sp,-32
    80000762:	ec06                	sd	ra,24(sp)
    80000764:	e822                	sd	s0,16(sp)
    80000766:	e426                	sd	s1,8(sp)
    80000768:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000076a:	00011497          	auipc	s1,0x11
    8000076e:	abe48493          	addi	s1,s1,-1346 # 80011228 <pr>
    80000772:	00008597          	auipc	a1,0x8
    80000776:	8c658593          	addi	a1,a1,-1850 # 80008038 <etext+0x38>
    8000077a:	8526                	mv	a0,s1
    8000077c:	00000097          	auipc	ra,0x0
    80000780:	508080e7          	jalr	1288(ra) # 80000c84 <initlock>
  pr.locking = 1;
    80000784:	4785                	li	a5,1
    80000786:	cc9c                	sw	a5,24(s1)
}
    80000788:	60e2                	ld	ra,24(sp)
    8000078a:	6442                	ld	s0,16(sp)
    8000078c:	64a2                	ld	s1,8(sp)
    8000078e:	6105                	addi	sp,sp,32
    80000790:	8082                	ret

0000000080000792 <uartinit>:

void uartstart();

void
uartinit(void)
{
    80000792:	1141                	addi	sp,sp,-16
    80000794:	e406                	sd	ra,8(sp)
    80000796:	e022                	sd	s0,0(sp)
    80000798:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    8000079a:	100007b7          	lui	a5,0x10000
    8000079e:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007a2:	f8000713          	li	a4,-128
    800007a6:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007aa:	470d                	li	a4,3
    800007ac:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007b0:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007b4:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007b8:	469d                	li	a3,7
    800007ba:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007be:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007c2:	00008597          	auipc	a1,0x8
    800007c6:	89658593          	addi	a1,a1,-1898 # 80008058 <digits+0x18>
    800007ca:	00011517          	auipc	a0,0x11
    800007ce:	a7e50513          	addi	a0,a0,-1410 # 80011248 <uart_tx_lock>
    800007d2:	00000097          	auipc	ra,0x0
    800007d6:	4b2080e7          	jalr	1202(ra) # 80000c84 <initlock>
}
    800007da:	60a2                	ld	ra,8(sp)
    800007dc:	6402                	ld	s0,0(sp)
    800007de:	0141                	addi	sp,sp,16
    800007e0:	8082                	ret

00000000800007e2 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007e2:	1101                	addi	sp,sp,-32
    800007e4:	ec06                	sd	ra,24(sp)
    800007e6:	e822                	sd	s0,16(sp)
    800007e8:	e426                	sd	s1,8(sp)
    800007ea:	1000                	addi	s0,sp,32
    800007ec:	84aa                	mv	s1,a0
  push_off();
    800007ee:	00000097          	auipc	ra,0x0
    800007f2:	4da080e7          	jalr	1242(ra) # 80000cc8 <push_off>

  if(panicked){
    800007f6:	00009797          	auipc	a5,0x9
    800007fa:	80a7a783          	lw	a5,-2038(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    800007fe:	10000737          	lui	a4,0x10000
  if(panicked){
    80000802:	c391                	beqz	a5,80000806 <uartputc_sync+0x24>
    for(;;)
    80000804:	a001                	j	80000804 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000806:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000080a:	0ff7f793          	andi	a5,a5,255
    8000080e:	0207f793          	andi	a5,a5,32
    80000812:	dbf5                	beqz	a5,80000806 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000814:	0ff4f793          	andi	a5,s1,255
    80000818:	10000737          	lui	a4,0x10000
    8000081c:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000820:	00000097          	auipc	ra,0x0
    80000824:	548080e7          	jalr	1352(ra) # 80000d68 <pop_off>
}
    80000828:	60e2                	ld	ra,24(sp)
    8000082a:	6442                	ld	s0,16(sp)
    8000082c:	64a2                	ld	s1,8(sp)
    8000082e:	6105                	addi	sp,sp,32
    80000830:	8082                	ret

0000000080000832 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000832:	00008717          	auipc	a4,0x8
    80000836:	7d673703          	ld	a4,2006(a4) # 80009008 <uart_tx_r>
    8000083a:	00008797          	auipc	a5,0x8
    8000083e:	7d67b783          	ld	a5,2006(a5) # 80009010 <uart_tx_w>
    80000842:	06e78c63          	beq	a5,a4,800008ba <uartstart+0x88>
{
    80000846:	7139                	addi	sp,sp,-64
    80000848:	fc06                	sd	ra,56(sp)
    8000084a:	f822                	sd	s0,48(sp)
    8000084c:	f426                	sd	s1,40(sp)
    8000084e:	f04a                	sd	s2,32(sp)
    80000850:	ec4e                	sd	s3,24(sp)
    80000852:	e852                	sd	s4,16(sp)
    80000854:	e456                	sd	s5,8(sp)
    80000856:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000858:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000085c:	00011a17          	auipc	s4,0x11
    80000860:	9eca0a13          	addi	s4,s4,-1556 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000864:	00008497          	auipc	s1,0x8
    80000868:	7a448493          	addi	s1,s1,1956 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000086c:	00008997          	auipc	s3,0x8
    80000870:	7a498993          	addi	s3,s3,1956 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000874:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000878:	0ff7f793          	andi	a5,a5,255
    8000087c:	0207f793          	andi	a5,a5,32
    80000880:	c785                	beqz	a5,800008a8 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000882:	01f77793          	andi	a5,a4,31
    80000886:	97d2                	add	a5,a5,s4
    80000888:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000088c:	0705                	addi	a4,a4,1
    8000088e:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000890:	8526                	mv	a0,s1
    80000892:	00002097          	auipc	ra,0x2
    80000896:	42c080e7          	jalr	1068(ra) # 80002cbe <wakeup>
    
    WriteReg(THR, c);
    8000089a:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    8000089e:	6098                	ld	a4,0(s1)
    800008a0:	0009b783          	ld	a5,0(s3)
    800008a4:	fce798e3          	bne	a5,a4,80000874 <uartstart+0x42>
  }
}
    800008a8:	70e2                	ld	ra,56(sp)
    800008aa:	7442                	ld	s0,48(sp)
    800008ac:	74a2                	ld	s1,40(sp)
    800008ae:	7902                	ld	s2,32(sp)
    800008b0:	69e2                	ld	s3,24(sp)
    800008b2:	6a42                	ld	s4,16(sp)
    800008b4:	6aa2                	ld	s5,8(sp)
    800008b6:	6121                	addi	sp,sp,64
    800008b8:	8082                	ret
    800008ba:	8082                	ret

00000000800008bc <uartputc>:
{
    800008bc:	7179                	addi	sp,sp,-48
    800008be:	f406                	sd	ra,40(sp)
    800008c0:	f022                	sd	s0,32(sp)
    800008c2:	ec26                	sd	s1,24(sp)
    800008c4:	e84a                	sd	s2,16(sp)
    800008c6:	e44e                	sd	s3,8(sp)
    800008c8:	e052                	sd	s4,0(sp)
    800008ca:	1800                	addi	s0,sp,48
    800008cc:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008ce:	00011517          	auipc	a0,0x11
    800008d2:	97a50513          	addi	a0,a0,-1670 # 80011248 <uart_tx_lock>
    800008d6:	00000097          	auipc	ra,0x0
    800008da:	43e080e7          	jalr	1086(ra) # 80000d14 <acquire>
  if(panicked){
    800008de:	00008797          	auipc	a5,0x8
    800008e2:	7227a783          	lw	a5,1826(a5) # 80009000 <panicked>
    800008e6:	c391                	beqz	a5,800008ea <uartputc+0x2e>
    for(;;)
    800008e8:	a001                	j	800008e8 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008797          	auipc	a5,0x8
    800008ee:	7267b783          	ld	a5,1830(a5) # 80009010 <uart_tx_w>
    800008f2:	00008717          	auipc	a4,0x8
    800008f6:	71673703          	ld	a4,1814(a4) # 80009008 <uart_tx_r>
    800008fa:	02070713          	addi	a4,a4,32
    800008fe:	02f71b63          	bne	a4,a5,80000934 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000902:	00011a17          	auipc	s4,0x11
    80000906:	946a0a13          	addi	s4,s4,-1722 # 80011248 <uart_tx_lock>
    8000090a:	00008497          	auipc	s1,0x8
    8000090e:	6fe48493          	addi	s1,s1,1790 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000912:	00008917          	auipc	s2,0x8
    80000916:	6fe90913          	addi	s2,s2,1790 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85d2                	mv	a1,s4
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	21a080e7          	jalr	538(ra) # 80002b38 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093783          	ld	a5,0(s2)
    8000092a:	6098                	ld	a4,0(s1)
    8000092c:	02070713          	addi	a4,a4,32
    80000930:	fef705e3          	beq	a4,a5,8000091a <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	91448493          	addi	s1,s1,-1772 # 80011248 <uart_tx_lock>
    8000093c:	01f7f713          	andi	a4,a5,31
    80000940:	9726                	add	a4,a4,s1
    80000942:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000946:	0785                	addi	a5,a5,1
    80000948:	00008717          	auipc	a4,0x8
    8000094c:	6cf73423          	sd	a5,1736(a4) # 80009010 <uart_tx_w>
      uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee2080e7          	jalr	-286(ra) # 80000832 <uartstart>
      release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	46e080e7          	jalr	1134(ra) # 80000dc8 <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret

0000000080000972 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000972:	1141                	addi	sp,sp,-16
    80000974:	e422                	sd	s0,8(sp)
    80000976:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000978:	100007b7          	lui	a5,0x10000
    8000097c:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000980:	8b85                	andi	a5,a5,1
    80000982:	cb91                	beqz	a5,80000996 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000984:	100007b7          	lui	a5,0x10000
    80000988:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000098c:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    80000990:	6422                	ld	s0,8(sp)
    80000992:	0141                	addi	sp,sp,16
    80000994:	8082                	ret
    return -1;
    80000996:	557d                	li	a0,-1
    80000998:	bfe5                	j	80000990 <uartgetc+0x1e>

000000008000099a <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    8000099a:	1101                	addi	sp,sp,-32
    8000099c:	ec06                	sd	ra,24(sp)
    8000099e:	e822                	sd	s0,16(sp)
    800009a0:	e426                	sd	s1,8(sp)
    800009a2:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a4:	54fd                	li	s1,-1
    int c = uartgetc();
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	fcc080e7          	jalr	-52(ra) # 80000972 <uartgetc>
    if(c == -1)
    800009ae:	00950763          	beq	a0,s1,800009bc <uartintr+0x22>
      break;
    consoleintr(c);
    800009b2:	00000097          	auipc	ra,0x0
    800009b6:	8fe080e7          	jalr	-1794(ra) # 800002b0 <consoleintr>
  while(1){
    800009ba:	b7f5                	j	800009a6 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009bc:	00011497          	auipc	s1,0x11
    800009c0:	88c48493          	addi	s1,s1,-1908 # 80011248 <uart_tx_lock>
    800009c4:	8526                	mv	a0,s1
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	34e080e7          	jalr	846(ra) # 80000d14 <acquire>
  uartstart();
    800009ce:	00000097          	auipc	ra,0x0
    800009d2:	e64080e7          	jalr	-412(ra) # 80000832 <uartstart>
  release(&uart_tx_lock);
    800009d6:	8526                	mv	a0,s1
    800009d8:	00000097          	auipc	ra,0x0
    800009dc:	3f0080e7          	jalr	1008(ra) # 80000dc8 <release>
}
    800009e0:	60e2                	ld	ra,24(sp)
    800009e2:	6442                	ld	s0,16(sp)
    800009e4:	64a2                	ld	s1,8(sp)
    800009e6:	6105                	addi	sp,sp,32
    800009e8:	8082                	ret

00000000800009ea <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009ea:	1101                	addi	sp,sp,-32
    800009ec:	ec06                	sd	ra,24(sp)
    800009ee:	e822                	sd	s0,16(sp)
    800009f0:	e426                	sd	s1,8(sp)
    800009f2:	e04a                	sd	s2,0(sp)
    800009f4:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f6:	03451793          	slli	a5,a0,0x34
    800009fa:	ebb9                	bnez	a5,80000a50 <kfree+0x66>
    800009fc:	84aa                	mv	s1,a0
    800009fe:	00025797          	auipc	a5,0x25
    80000a02:	60278793          	addi	a5,a5,1538 # 80026000 <end>
    80000a06:	04f56563          	bltu	a0,a5,80000a50 <kfree+0x66>
    80000a0a:	47c5                	li	a5,17
    80000a0c:	07ee                	slli	a5,a5,0x1b
    80000a0e:	04f57163          	bgeu	a0,a5,80000a50 <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a12:	6605                	lui	a2,0x1
    80000a14:	4585                	li	a1,1
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	3fa080e7          	jalr	1018(ra) # 80000e10 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1e:	00011917          	auipc	s2,0x11
    80000a22:	86290913          	addi	s2,s2,-1950 # 80011280 <kmem>
    80000a26:	854a                	mv	a0,s2
    80000a28:	00000097          	auipc	ra,0x0
    80000a2c:	2ec080e7          	jalr	748(ra) # 80000d14 <acquire>
  r->next = kmem.freelist;
    80000a30:	01893783          	ld	a5,24(s2)
    80000a34:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a36:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a3a:	854a                	mv	a0,s2
    80000a3c:	00000097          	auipc	ra,0x0
    80000a40:	38c080e7          	jalr	908(ra) # 80000dc8 <release>
}
    80000a44:	60e2                	ld	ra,24(sp)
    80000a46:	6442                	ld	s0,16(sp)
    80000a48:	64a2                	ld	s1,8(sp)
    80000a4a:	6902                	ld	s2,0(sp)
    80000a4c:	6105                	addi	sp,sp,32
    80000a4e:	8082                	ret
    panic("kfree");
    80000a50:	00007517          	auipc	a0,0x7
    80000a54:	61050513          	addi	a0,a0,1552 # 80008060 <digits+0x20>
    80000a58:	00000097          	auipc	ra,0x0
    80000a5c:	ad8080e7          	jalr	-1320(ra) # 80000530 <panic>

0000000080000a60 <freerange>:
{
    80000a60:	7179                	addi	sp,sp,-48
    80000a62:	f406                	sd	ra,40(sp)
    80000a64:	f022                	sd	s0,32(sp)
    80000a66:	ec26                	sd	s1,24(sp)
    80000a68:	e84a                	sd	s2,16(sp)
    80000a6a:	e44e                	sd	s3,8(sp)
    80000a6c:	e052                	sd	s4,0(sp)
    80000a6e:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a70:	6785                	lui	a5,0x1
    80000a72:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a76:	94aa                	add	s1,s1,a0
    80000a78:	757d                	lui	a0,0xfffff
    80000a7a:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3a>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5e080e7          	jalr	-162(ra) # 800009ea <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x28>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000aaa:	1101                	addi	sp,sp,-32
    80000aac:	ec06                	sd	ra,24(sp)
    80000aae:	e822                	sd	s0,16(sp)
    80000ab0:	e426                	sd	s1,8(sp)
    80000ab2:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000ab4:	00010497          	auipc	s1,0x10
    80000ab8:	7cc48493          	addi	s1,s1,1996 # 80011280 <kmem>
    80000abc:	8526                	mv	a0,s1
    80000abe:	00000097          	auipc	ra,0x0
    80000ac2:	256080e7          	jalr	598(ra) # 80000d14 <acquire>
  r = kmem.freelist;
    80000ac6:	6c84                	ld	s1,24(s1)
  if(r)
    80000ac8:	c885                	beqz	s1,80000af8 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000aca:	609c                	ld	a5,0(s1)
    80000acc:	00010517          	auipc	a0,0x10
    80000ad0:	7b450513          	addi	a0,a0,1972 # 80011280 <kmem>
    80000ad4:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	2f2080e7          	jalr	754(ra) # 80000dc8 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000ade:	6605                	lui	a2,0x1
    80000ae0:	4595                	li	a1,5
    80000ae2:	8526                	mv	a0,s1
    80000ae4:	00000097          	auipc	ra,0x0
    80000ae8:	32c080e7          	jalr	812(ra) # 80000e10 <memset>
  return (void*)r;
}
    80000aec:	8526                	mv	a0,s1
    80000aee:	60e2                	ld	ra,24(sp)
    80000af0:	6442                	ld	s0,16(sp)
    80000af2:	64a2                	ld	s1,8(sp)
    80000af4:	6105                	addi	sp,sp,32
    80000af6:	8082                	ret
  release(&kmem.lock);
    80000af8:	00010517          	auipc	a0,0x10
    80000afc:	78850513          	addi	a0,a0,1928 # 80011280 <kmem>
    80000b00:	00000097          	auipc	ra,0x0
    80000b04:	2c8080e7          	jalr	712(ra) # 80000dc8 <release>
  if(r)
    80000b08:	b7d5                	j	80000aec <kalloc+0x42>

0000000080000b0a <kvma_free>:
    kvma_free(p);
}

void
kvma_free(void *pa)
{
    80000b0a:	7179                	addi	sp,sp,-48
    80000b0c:	f406                	sd	ra,40(sp)
    80000b0e:	f022                	sd	s0,32(sp)
    80000b10:	ec26                	sd	s1,24(sp)
    80000b12:	e84a                	sd	s2,16(sp)
    80000b14:	e44e                	sd	s3,8(sp)
    80000b16:	1800                	addi	s0,sp,48
  if((char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b18:	00025797          	auipc	a5,0x25
    80000b1c:	4e878793          	addi	a5,a5,1256 # 80026000 <end>
    80000b20:	04f56c63          	bltu	a0,a5,80000b78 <kvma_free+0x6e>
    80000b24:	84aa                	mv	s1,a0
    80000b26:	47c5                	li	a5,17
    80000b28:	07ee                	slli	a5,a5,0x1b
    80000b2a:	04f57763          	bgeu	a0,a5,80000b78 <kvma_free+0x6e>
    panic("kvma_free");
  memset(pa, 0, sizeof(struct vma));
    80000b2e:	04000613          	li	a2,64
    80000b32:	4581                	li	a1,0
    80000b34:	00000097          	auipc	ra,0x0
    80000b38:	2dc080e7          	jalr	732(ra) # 80000e10 <memset>

  struct vma *p = (struct vma *)pa;
  acquire(&kvma.lock);
    80000b3c:	00010997          	auipc	s3,0x10
    80000b40:	74498993          	addi	s3,s3,1860 # 80011280 <kmem>
    80000b44:	00010917          	auipc	s2,0x10
    80000b48:	75c90913          	addi	s2,s2,1884 # 800112a0 <kvma>
    80000b4c:	854a                	mv	a0,s2
    80000b4e:	00000097          	auipc	ra,0x0
    80000b52:	1c6080e7          	jalr	454(ra) # 80000d14 <acquire>
  p->next = kvma.freelist;
    80000b56:	0389b783          	ld	a5,56(s3)
    80000b5a:	fc9c                	sd	a5,56(s1)
  kvma.freelist = p;
    80000b5c:	0299bc23          	sd	s1,56(s3)
  release(&kvma.lock);
    80000b60:	854a                	mv	a0,s2
    80000b62:	00000097          	auipc	ra,0x0
    80000b66:	266080e7          	jalr	614(ra) # 80000dc8 <release>
}
    80000b6a:	70a2                	ld	ra,40(sp)
    80000b6c:	7402                	ld	s0,32(sp)
    80000b6e:	64e2                	ld	s1,24(sp)
    80000b70:	6942                	ld	s2,16(sp)
    80000b72:	69a2                	ld	s3,8(sp)
    80000b74:	6145                	addi	sp,sp,48
    80000b76:	8082                	ret
    panic("kvma_free");
    80000b78:	00007517          	auipc	a0,0x7
    80000b7c:	4f050513          	addi	a0,a0,1264 # 80008068 <digits+0x28>
    80000b80:	00000097          	auipc	ra,0x0
    80000b84:	9b0080e7          	jalr	-1616(ra) # 80000530 <panic>

0000000080000b88 <free_vma_range>:
{
    80000b88:	1101                	addi	sp,sp,-32
    80000b8a:	ec06                	sd	ra,24(sp)
    80000b8c:	e822                	sd	s0,16(sp)
    80000b8e:	e426                	sd	s1,8(sp)
    80000b90:	e04a                	sd	s2,0(sp)
    80000b92:	1000                	addi	s0,sp,32
    80000b94:	892e                	mv	s2,a1
  p = (char *)PGROUNDUP((uint64)pa_start);
    80000b96:	6485                	lui	s1,0x1
    80000b98:	14fd                	addi	s1,s1,-1
    80000b9a:	94aa                	add	s1,s1,a0
    80000b9c:	757d                	lui	a0,0xfffff
    80000b9e:	8ce9                	and	s1,s1,a0
  for (; p + sizeof(struct vma) <= (char *)pa_end; p += sizeof(struct vma))
    80000ba0:	04048493          	addi	s1,s1,64 # 1040 <_entry-0x7fffefc0>
    80000ba4:	0095ec63          	bltu	a1,s1,80000bbc <free_vma_range+0x34>
    kvma_free(p);
    80000ba8:	fc048513          	addi	a0,s1,-64
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	f5e080e7          	jalr	-162(ra) # 80000b0a <kvma_free>
  for (; p + sizeof(struct vma) <= (char *)pa_end; p += sizeof(struct vma))
    80000bb4:	04048493          	addi	s1,s1,64
    80000bb8:	fe9978e3          	bgeu	s2,s1,80000ba8 <free_vma_range+0x20>
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6902                	ld	s2,0(sp)
    80000bc4:	6105                	addi	sp,sp,32
    80000bc6:	8082                	ret

0000000080000bc8 <kinit>:
{
    80000bc8:	1101                	addi	sp,sp,-32
    80000bca:	ec06                	sd	ra,24(sp)
    80000bcc:	e822                	sd	s0,16(sp)
    80000bce:	e426                	sd	s1,8(sp)
    80000bd0:	1000                	addi	s0,sp,32
  initlock(&kmem.lock, "kmem");
    80000bd2:	00010497          	auipc	s1,0x10
    80000bd6:	6ae48493          	addi	s1,s1,1710 # 80011280 <kmem>
    80000bda:	00007597          	auipc	a1,0x7
    80000bde:	49e58593          	addi	a1,a1,1182 # 80008078 <digits+0x38>
    80000be2:	8526                	mv	a0,s1
    80000be4:	00000097          	auipc	ra,0x0
    80000be8:	0a0080e7          	jalr	160(ra) # 80000c84 <initlock>
  initlock(&kvma.lock, "kvma");
    80000bec:	00007597          	auipc	a1,0x7
    80000bf0:	49458593          	addi	a1,a1,1172 # 80008080 <digits+0x40>
    80000bf4:	00010517          	auipc	a0,0x10
    80000bf8:	6ac50513          	addi	a0,a0,1708 # 800112a0 <kvma>
    80000bfc:	00000097          	auipc	ra,0x0
    80000c00:	088080e7          	jalr	136(ra) # 80000c84 <initlock>
  char *p = (char *)PGROUNDUP((uint64)end);
    80000c04:	00026517          	auipc	a0,0x26
    80000c08:	3fb50513          	addi	a0,a0,1019 # 80026fff <end+0xfff>
    80000c0c:	77fd                	lui	a5,0xfffff
    80000c0e:	8d7d                	and	a0,a0,a5
  kvma.freelist = 0;
    80000c10:	0204bc23          	sd	zero,56(s1)
  free_vma_range(p, p + PGSIZE);
    80000c14:	6485                	lui	s1,0x1
    80000c16:	94aa                	add	s1,s1,a0
    80000c18:	85a6                	mv	a1,s1
    80000c1a:	00000097          	auipc	ra,0x0
    80000c1e:	f6e080e7          	jalr	-146(ra) # 80000b88 <free_vma_range>
  freerange(p + PGSIZE, (void*)PHYSTOP);
    80000c22:	45c5                	li	a1,17
    80000c24:	05ee                	slli	a1,a1,0x1b
    80000c26:	8526                	mv	a0,s1
    80000c28:	00000097          	auipc	ra,0x0
    80000c2c:	e38080e7          	jalr	-456(ra) # 80000a60 <freerange>
}
    80000c30:	60e2                	ld	ra,24(sp)
    80000c32:	6442                	ld	s0,16(sp)
    80000c34:	64a2                	ld	s1,8(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret

0000000080000c3a <kvma_alloc>:


void *
kvma_alloc(void)
{
    80000c3a:	1101                	addi	sp,sp,-32
    80000c3c:	ec06                	sd	ra,24(sp)
    80000c3e:	e822                	sd	s0,16(sp)
    80000c40:	e426                	sd	s1,8(sp)
    80000c42:	1000                	addi	s0,sp,32
  struct vma *r;

  acquire(&kvma.lock);
    80000c44:	00010517          	auipc	a0,0x10
    80000c48:	65c50513          	addi	a0,a0,1628 # 800112a0 <kvma>
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	0c8080e7          	jalr	200(ra) # 80000d14 <acquire>
  r = kvma.freelist;
    80000c54:	00010497          	auipc	s1,0x10
    80000c58:	6644b483          	ld	s1,1636(s1) # 800112b8 <kvma+0x18>
  if (r)
    80000c5c:	c491                	beqz	s1,80000c68 <kvma_alloc+0x2e>
    kvma.freelist = r->next;
    80000c5e:	7c9c                	ld	a5,56(s1)
    80000c60:	00010717          	auipc	a4,0x10
    80000c64:	64f73c23          	sd	a5,1624(a4) # 800112b8 <kvma+0x18>
  release(&kvma.lock);
    80000c68:	00010517          	auipc	a0,0x10
    80000c6c:	63850513          	addi	a0,a0,1592 # 800112a0 <kvma>
    80000c70:	00000097          	auipc	ra,0x0
    80000c74:	158080e7          	jalr	344(ra) # 80000dc8 <release>

  return (void *)r;
    80000c78:	8526                	mv	a0,s1
    80000c7a:	60e2                	ld	ra,24(sp)
    80000c7c:	6442                	ld	s0,16(sp)
    80000c7e:	64a2                	ld	s1,8(sp)
    80000c80:	6105                	addi	sp,sp,32
    80000c82:	8082                	ret

0000000080000c84 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000c84:	1141                	addi	sp,sp,-16
    80000c86:	e422                	sd	s0,8(sp)
    80000c88:	0800                	addi	s0,sp,16
  lk->name = name;
    80000c8a:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000c8c:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000c90:	00053823          	sd	zero,16(a0)
}
    80000c94:	6422                	ld	s0,8(sp)
    80000c96:	0141                	addi	sp,sp,16
    80000c98:	8082                	ret

0000000080000c9a <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000c9a:	411c                	lw	a5,0(a0)
    80000c9c:	e399                	bnez	a5,80000ca2 <holding+0x8>
    80000c9e:	4501                	li	a0,0
  return r;
}
    80000ca0:	8082                	ret
{
    80000ca2:	1101                	addi	sp,sp,-32
    80000ca4:	ec06                	sd	ra,24(sp)
    80000ca6:	e822                	sd	s0,16(sp)
    80000ca8:	e426                	sd	s1,8(sp)
    80000caa:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000cac:	6904                	ld	s1,16(a0)
    80000cae:	00001097          	auipc	ra,0x1
    80000cb2:	50c080e7          	jalr	1292(ra) # 800021ba <mycpu>
    80000cb6:	40a48533          	sub	a0,s1,a0
    80000cba:	00153513          	seqz	a0,a0
}
    80000cbe:	60e2                	ld	ra,24(sp)
    80000cc0:	6442                	ld	s0,16(sp)
    80000cc2:	64a2                	ld	s1,8(sp)
    80000cc4:	6105                	addi	sp,sp,32
    80000cc6:	8082                	ret

0000000080000cc8 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000cc8:	1101                	addi	sp,sp,-32
    80000cca:	ec06                	sd	ra,24(sp)
    80000ccc:	e822                	sd	s0,16(sp)
    80000cce:	e426                	sd	s1,8(sp)
    80000cd0:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000cd2:	100024f3          	csrr	s1,sstatus
    80000cd6:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000cda:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000cdc:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ce0:	00001097          	auipc	ra,0x1
    80000ce4:	4da080e7          	jalr	1242(ra) # 800021ba <mycpu>
    80000ce8:	5d3c                	lw	a5,120(a0)
    80000cea:	cf89                	beqz	a5,80000d04 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000cec:	00001097          	auipc	ra,0x1
    80000cf0:	4ce080e7          	jalr	1230(ra) # 800021ba <mycpu>
    80000cf4:	5d3c                	lw	a5,120(a0)
    80000cf6:	2785                	addiw	a5,a5,1
    80000cf8:	dd3c                	sw	a5,120(a0)
}
    80000cfa:	60e2                	ld	ra,24(sp)
    80000cfc:	6442                	ld	s0,16(sp)
    80000cfe:	64a2                	ld	s1,8(sp)
    80000d00:	6105                	addi	sp,sp,32
    80000d02:	8082                	ret
    mycpu()->intena = old;
    80000d04:	00001097          	auipc	ra,0x1
    80000d08:	4b6080e7          	jalr	1206(ra) # 800021ba <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000d0c:	8085                	srli	s1,s1,0x1
    80000d0e:	8885                	andi	s1,s1,1
    80000d10:	dd64                	sw	s1,124(a0)
    80000d12:	bfe9                	j	80000cec <push_off+0x24>

0000000080000d14 <acquire>:
{
    80000d14:	1101                	addi	sp,sp,-32
    80000d16:	ec06                	sd	ra,24(sp)
    80000d18:	e822                	sd	s0,16(sp)
    80000d1a:	e426                	sd	s1,8(sp)
    80000d1c:	1000                	addi	s0,sp,32
    80000d1e:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	fa8080e7          	jalr	-88(ra) # 80000cc8 <push_off>
  if(holding(lk))
    80000d28:	8526                	mv	a0,s1
    80000d2a:	00000097          	auipc	ra,0x0
    80000d2e:	f70080e7          	jalr	-144(ra) # 80000c9a <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d32:	4705                	li	a4,1
  if(holding(lk))
    80000d34:	e115                	bnez	a0,80000d58 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000d36:	87ba                	mv	a5,a4
    80000d38:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000d3c:	2781                	sext.w	a5,a5
    80000d3e:	ffe5                	bnez	a5,80000d36 <acquire+0x22>
  __sync_synchronize();
    80000d40:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000d44:	00001097          	auipc	ra,0x1
    80000d48:	476080e7          	jalr	1142(ra) # 800021ba <mycpu>
    80000d4c:	e888                	sd	a0,16(s1)
}
    80000d4e:	60e2                	ld	ra,24(sp)
    80000d50:	6442                	ld	s0,16(sp)
    80000d52:	64a2                	ld	s1,8(sp)
    80000d54:	6105                	addi	sp,sp,32
    80000d56:	8082                	ret
    panic("acquire");
    80000d58:	00007517          	auipc	a0,0x7
    80000d5c:	33050513          	addi	a0,a0,816 # 80008088 <digits+0x48>
    80000d60:	fffff097          	auipc	ra,0xfffff
    80000d64:	7d0080e7          	jalr	2000(ra) # 80000530 <panic>

0000000080000d68 <pop_off>:

void
pop_off(void)
{
    80000d68:	1141                	addi	sp,sp,-16
    80000d6a:	e406                	sd	ra,8(sp)
    80000d6c:	e022                	sd	s0,0(sp)
    80000d6e:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000d70:	00001097          	auipc	ra,0x1
    80000d74:	44a080e7          	jalr	1098(ra) # 800021ba <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d78:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000d7c:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000d7e:	e78d                	bnez	a5,80000da8 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000d80:	5d3c                	lw	a5,120(a0)
    80000d82:	02f05b63          	blez	a5,80000db8 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000d86:	37fd                	addiw	a5,a5,-1
    80000d88:	0007871b          	sext.w	a4,a5
    80000d8c:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000d8e:	eb09                	bnez	a4,80000da0 <pop_off+0x38>
    80000d90:	5d7c                	lw	a5,124(a0)
    80000d92:	c799                	beqz	a5,80000da0 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000d94:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000d98:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000d9c:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000da0:	60a2                	ld	ra,8(sp)
    80000da2:	6402                	ld	s0,0(sp)
    80000da4:	0141                	addi	sp,sp,16
    80000da6:	8082                	ret
    panic("pop_off - interruptible");
    80000da8:	00007517          	auipc	a0,0x7
    80000dac:	2e850513          	addi	a0,a0,744 # 80008090 <digits+0x50>
    80000db0:	fffff097          	auipc	ra,0xfffff
    80000db4:	780080e7          	jalr	1920(ra) # 80000530 <panic>
    panic("pop_off");
    80000db8:	00007517          	auipc	a0,0x7
    80000dbc:	2f050513          	addi	a0,a0,752 # 800080a8 <digits+0x68>
    80000dc0:	fffff097          	auipc	ra,0xfffff
    80000dc4:	770080e7          	jalr	1904(ra) # 80000530 <panic>

0000000080000dc8 <release>:
{
    80000dc8:	1101                	addi	sp,sp,-32
    80000dca:	ec06                	sd	ra,24(sp)
    80000dcc:	e822                	sd	s0,16(sp)
    80000dce:	e426                	sd	s1,8(sp)
    80000dd0:	1000                	addi	s0,sp,32
    80000dd2:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000dd4:	00000097          	auipc	ra,0x0
    80000dd8:	ec6080e7          	jalr	-314(ra) # 80000c9a <holding>
    80000ddc:	c115                	beqz	a0,80000e00 <release+0x38>
  lk->cpu = 0;
    80000dde:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000de2:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000de6:	0f50000f          	fence	iorw,ow
    80000dea:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000dee:	00000097          	auipc	ra,0x0
    80000df2:	f7a080e7          	jalr	-134(ra) # 80000d68 <pop_off>
}
    80000df6:	60e2                	ld	ra,24(sp)
    80000df8:	6442                	ld	s0,16(sp)
    80000dfa:	64a2                	ld	s1,8(sp)
    80000dfc:	6105                	addi	sp,sp,32
    80000dfe:	8082                	ret
    panic("release");
    80000e00:	00007517          	auipc	a0,0x7
    80000e04:	2b050513          	addi	a0,a0,688 # 800080b0 <digits+0x70>
    80000e08:	fffff097          	auipc	ra,0xfffff
    80000e0c:	728080e7          	jalr	1832(ra) # 80000530 <panic>

0000000080000e10 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000e10:	1141                	addi	sp,sp,-16
    80000e12:	e422                	sd	s0,8(sp)
    80000e14:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000e16:	ce09                	beqz	a2,80000e30 <memset+0x20>
    80000e18:	87aa                	mv	a5,a0
    80000e1a:	fff6071b          	addiw	a4,a2,-1
    80000e1e:	1702                	slli	a4,a4,0x20
    80000e20:	9301                	srli	a4,a4,0x20
    80000e22:	0705                	addi	a4,a4,1
    80000e24:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000e26:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7ffd9000>
  for(i = 0; i < n; i++){
    80000e2a:	0785                	addi	a5,a5,1
    80000e2c:	fee79de3          	bne	a5,a4,80000e26 <memset+0x16>
  }
  return dst;
}
    80000e30:	6422                	ld	s0,8(sp)
    80000e32:	0141                	addi	sp,sp,16
    80000e34:	8082                	ret

0000000080000e36 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000e36:	1141                	addi	sp,sp,-16
    80000e38:	e422                	sd	s0,8(sp)
    80000e3a:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000e3c:	ca05                	beqz	a2,80000e6c <memcmp+0x36>
    80000e3e:	fff6069b          	addiw	a3,a2,-1
    80000e42:	1682                	slli	a3,a3,0x20
    80000e44:	9281                	srli	a3,a3,0x20
    80000e46:	0685                	addi	a3,a3,1
    80000e48:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000e4a:	00054783          	lbu	a5,0(a0)
    80000e4e:	0005c703          	lbu	a4,0(a1)
    80000e52:	00e79863          	bne	a5,a4,80000e62 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000e56:	0505                	addi	a0,a0,1
    80000e58:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000e5a:	fed518e3          	bne	a0,a3,80000e4a <memcmp+0x14>
  }

  return 0;
    80000e5e:	4501                	li	a0,0
    80000e60:	a019                	j	80000e66 <memcmp+0x30>
      return *s1 - *s2;
    80000e62:	40e7853b          	subw	a0,a5,a4
}
    80000e66:	6422                	ld	s0,8(sp)
    80000e68:	0141                	addi	sp,sp,16
    80000e6a:	8082                	ret
  return 0;
    80000e6c:	4501                	li	a0,0
    80000e6e:	bfe5                	j	80000e66 <memcmp+0x30>

0000000080000e70 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000e70:	1141                	addi	sp,sp,-16
    80000e72:	e422                	sd	s0,8(sp)
    80000e74:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000e76:	00a5f963          	bgeu	a1,a0,80000e88 <memmove+0x18>
    80000e7a:	02061713          	slli	a4,a2,0x20
    80000e7e:	9301                	srli	a4,a4,0x20
    80000e80:	00e587b3          	add	a5,a1,a4
    80000e84:	02f56563          	bltu	a0,a5,80000eae <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000e88:	fff6069b          	addiw	a3,a2,-1
    80000e8c:	ce11                	beqz	a2,80000ea8 <memmove+0x38>
    80000e8e:	1682                	slli	a3,a3,0x20
    80000e90:	9281                	srli	a3,a3,0x20
    80000e92:	0685                	addi	a3,a3,1
    80000e94:	96ae                	add	a3,a3,a1
    80000e96:	87aa                	mv	a5,a0
      *d++ = *s++;
    80000e98:	0585                	addi	a1,a1,1
    80000e9a:	0785                	addi	a5,a5,1
    80000e9c:	fff5c703          	lbu	a4,-1(a1)
    80000ea0:	fee78fa3          	sb	a4,-1(a5)
    while(n-- > 0)
    80000ea4:	fed59ae3          	bne	a1,a3,80000e98 <memmove+0x28>

  return dst;
}
    80000ea8:	6422                	ld	s0,8(sp)
    80000eaa:	0141                	addi	sp,sp,16
    80000eac:	8082                	ret
    d += n;
    80000eae:	972a                	add	a4,a4,a0
    while(n-- > 0)
    80000eb0:	fff6069b          	addiw	a3,a2,-1
    80000eb4:	da75                	beqz	a2,80000ea8 <memmove+0x38>
    80000eb6:	02069613          	slli	a2,a3,0x20
    80000eba:	9201                	srli	a2,a2,0x20
    80000ebc:	fff64613          	not	a2,a2
    80000ec0:	963e                	add	a2,a2,a5
      *--d = *--s;
    80000ec2:	17fd                	addi	a5,a5,-1
    80000ec4:	177d                	addi	a4,a4,-1
    80000ec6:	0007c683          	lbu	a3,0(a5)
    80000eca:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
    80000ece:	fec79ae3          	bne	a5,a2,80000ec2 <memmove+0x52>
    80000ed2:	bfd9                	j	80000ea8 <memmove+0x38>

0000000080000ed4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000ed4:	1141                	addi	sp,sp,-16
    80000ed6:	e406                	sd	ra,8(sp)
    80000ed8:	e022                	sd	s0,0(sp)
    80000eda:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000edc:	00000097          	auipc	ra,0x0
    80000ee0:	f94080e7          	jalr	-108(ra) # 80000e70 <memmove>
}
    80000ee4:	60a2                	ld	ra,8(sp)
    80000ee6:	6402                	ld	s0,0(sp)
    80000ee8:	0141                	addi	sp,sp,16
    80000eea:	8082                	ret

0000000080000eec <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000eec:	1141                	addi	sp,sp,-16
    80000eee:	e422                	sd	s0,8(sp)
    80000ef0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000ef2:	ce11                	beqz	a2,80000f0e <strncmp+0x22>
    80000ef4:	00054783          	lbu	a5,0(a0)
    80000ef8:	cf89                	beqz	a5,80000f12 <strncmp+0x26>
    80000efa:	0005c703          	lbu	a4,0(a1)
    80000efe:	00f71a63          	bne	a4,a5,80000f12 <strncmp+0x26>
    n--, p++, q++;
    80000f02:	367d                	addiw	a2,a2,-1
    80000f04:	0505                	addi	a0,a0,1
    80000f06:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000f08:	f675                	bnez	a2,80000ef4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000f0a:	4501                	li	a0,0
    80000f0c:	a809                	j	80000f1e <strncmp+0x32>
    80000f0e:	4501                	li	a0,0
    80000f10:	a039                	j	80000f1e <strncmp+0x32>
  if(n == 0)
    80000f12:	ca09                	beqz	a2,80000f24 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000f14:	00054503          	lbu	a0,0(a0)
    80000f18:	0005c783          	lbu	a5,0(a1)
    80000f1c:	9d1d                	subw	a0,a0,a5
}
    80000f1e:	6422                	ld	s0,8(sp)
    80000f20:	0141                	addi	sp,sp,16
    80000f22:	8082                	ret
    return 0;
    80000f24:	4501                	li	a0,0
    80000f26:	bfe5                	j	80000f1e <strncmp+0x32>

0000000080000f28 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000f28:	1141                	addi	sp,sp,-16
    80000f2a:	e422                	sd	s0,8(sp)
    80000f2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000f2e:	872a                	mv	a4,a0
    80000f30:	8832                	mv	a6,a2
    80000f32:	367d                	addiw	a2,a2,-1
    80000f34:	01005963          	blez	a6,80000f46 <strncpy+0x1e>
    80000f38:	0705                	addi	a4,a4,1
    80000f3a:	0005c783          	lbu	a5,0(a1)
    80000f3e:	fef70fa3          	sb	a5,-1(a4)
    80000f42:	0585                	addi	a1,a1,1
    80000f44:	f7f5                	bnez	a5,80000f30 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000f46:	00c05d63          	blez	a2,80000f60 <strncpy+0x38>
    80000f4a:	86ba                	mv	a3,a4
    *s++ = 0;
    80000f4c:	0685                	addi	a3,a3,1
    80000f4e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000f52:	fff6c793          	not	a5,a3
    80000f56:	9fb9                	addw	a5,a5,a4
    80000f58:	010787bb          	addw	a5,a5,a6
    80000f5c:	fef048e3          	bgtz	a5,80000f4c <strncpy+0x24>
  return os;
}
    80000f60:	6422                	ld	s0,8(sp)
    80000f62:	0141                	addi	sp,sp,16
    80000f64:	8082                	ret

0000000080000f66 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000f66:	1141                	addi	sp,sp,-16
    80000f68:	e422                	sd	s0,8(sp)
    80000f6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000f6c:	02c05363          	blez	a2,80000f92 <safestrcpy+0x2c>
    80000f70:	fff6069b          	addiw	a3,a2,-1
    80000f74:	1682                	slli	a3,a3,0x20
    80000f76:	9281                	srli	a3,a3,0x20
    80000f78:	96ae                	add	a3,a3,a1
    80000f7a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000f7c:	00d58963          	beq	a1,a3,80000f8e <safestrcpy+0x28>
    80000f80:	0585                	addi	a1,a1,1
    80000f82:	0785                	addi	a5,a5,1
    80000f84:	fff5c703          	lbu	a4,-1(a1)
    80000f88:	fee78fa3          	sb	a4,-1(a5)
    80000f8c:	fb65                	bnez	a4,80000f7c <safestrcpy+0x16>
    ;
  *s = 0;
    80000f8e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000f92:	6422                	ld	s0,8(sp)
    80000f94:	0141                	addi	sp,sp,16
    80000f96:	8082                	ret

0000000080000f98 <strlen>:

int
strlen(const char *s)
{
    80000f98:	1141                	addi	sp,sp,-16
    80000f9a:	e422                	sd	s0,8(sp)
    80000f9c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000f9e:	00054783          	lbu	a5,0(a0)
    80000fa2:	cf91                	beqz	a5,80000fbe <strlen+0x26>
    80000fa4:	0505                	addi	a0,a0,1
    80000fa6:	87aa                	mv	a5,a0
    80000fa8:	4685                	li	a3,1
    80000faa:	9e89                	subw	a3,a3,a0
    80000fac:	00f6853b          	addw	a0,a3,a5
    80000fb0:	0785                	addi	a5,a5,1
    80000fb2:	fff7c703          	lbu	a4,-1(a5)
    80000fb6:	fb7d                	bnez	a4,80000fac <strlen+0x14>
    ;
  return n;
}
    80000fb8:	6422                	ld	s0,8(sp)
    80000fba:	0141                	addi	sp,sp,16
    80000fbc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000fbe:	4501                	li	a0,0
    80000fc0:	bfe5                	j	80000fb8 <strlen+0x20>

0000000080000fc2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000fc2:	1141                	addi	sp,sp,-16
    80000fc4:	e406                	sd	ra,8(sp)
    80000fc6:	e022                	sd	s0,0(sp)
    80000fc8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000fca:	00001097          	auipc	ra,0x1
    80000fce:	1e0080e7          	jalr	480(ra) # 800021aa <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000fd2:	00008717          	auipc	a4,0x8
    80000fd6:	04670713          	addi	a4,a4,70 # 80009018 <started>
  if(cpuid() == 0){
    80000fda:	c139                	beqz	a0,80001020 <main+0x5e>
    while(started == 0)
    80000fdc:	431c                	lw	a5,0(a4)
    80000fde:	2781                	sext.w	a5,a5
    80000fe0:	dff5                	beqz	a5,80000fdc <main+0x1a>
      ;
    __sync_synchronize();
    80000fe2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000fe6:	00001097          	auipc	ra,0x1
    80000fea:	1c4080e7          	jalr	452(ra) # 800021aa <cpuid>
    80000fee:	85aa                	mv	a1,a0
    80000ff0:	00007517          	auipc	a0,0x7
    80000ff4:	0e050513          	addi	a0,a0,224 # 800080d0 <digits+0x90>
    80000ff8:	fffff097          	auipc	ra,0xfffff
    80000ffc:	582080e7          	jalr	1410(ra) # 8000057a <printf>
    kvminithart();    // turn on paging
    80001000:	00000097          	auipc	ra,0x0
    80001004:	0d8080e7          	jalr	216(ra) # 800010d8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80001008:	00002097          	auipc	ra,0x2
    8000100c:	f7e080e7          	jalr	-130(ra) # 80002f86 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001010:	00005097          	auipc	ra,0x5
    80001014:	540080e7          	jalr	1344(ra) # 80006550 <plicinithart>
  }

  scheduler();        
    80001018:	00001097          	auipc	ra,0x1
    8000101c:	7d6080e7          	jalr	2006(ra) # 800027ee <scheduler>
    consoleinit();
    80001020:	fffff097          	auipc	ra,0xfffff
    80001024:	422080e7          	jalr	1058(ra) # 80000442 <consoleinit>
    printfinit();
    80001028:	fffff097          	auipc	ra,0xfffff
    8000102c:	738080e7          	jalr	1848(ra) # 80000760 <printfinit>
    printf("\n");
    80001030:	00007517          	auipc	a0,0x7
    80001034:	0b050513          	addi	a0,a0,176 # 800080e0 <digits+0xa0>
    80001038:	fffff097          	auipc	ra,0xfffff
    8000103c:	542080e7          	jalr	1346(ra) # 8000057a <printf>
    printf("xv6 kernel is booting\n");
    80001040:	00007517          	auipc	a0,0x7
    80001044:	07850513          	addi	a0,a0,120 # 800080b8 <digits+0x78>
    80001048:	fffff097          	auipc	ra,0xfffff
    8000104c:	532080e7          	jalr	1330(ra) # 8000057a <printf>
    printf("\n");
    80001050:	00007517          	auipc	a0,0x7
    80001054:	09050513          	addi	a0,a0,144 # 800080e0 <digits+0xa0>
    80001058:	fffff097          	auipc	ra,0xfffff
    8000105c:	522080e7          	jalr	1314(ra) # 8000057a <printf>
    kinit();         // physical page allocator
    80001060:	00000097          	auipc	ra,0x0
    80001064:	b68080e7          	jalr	-1176(ra) # 80000bc8 <kinit>
    kvminit();       // create kernel page table
    80001068:	00000097          	auipc	ra,0x0
    8000106c:	310080e7          	jalr	784(ra) # 80001378 <kvminit>
    kvminithart();   // turn on paging
    80001070:	00000097          	auipc	ra,0x0
    80001074:	068080e7          	jalr	104(ra) # 800010d8 <kvminithart>
    procinit();      // process table
    80001078:	00001097          	auipc	ra,0x1
    8000107c:	09a080e7          	jalr	154(ra) # 80002112 <procinit>
    trapinit();      // trap vectors
    80001080:	00002097          	auipc	ra,0x2
    80001084:	ede080e7          	jalr	-290(ra) # 80002f5e <trapinit>
    trapinithart();  // install kernel trap vector
    80001088:	00002097          	auipc	ra,0x2
    8000108c:	efe080e7          	jalr	-258(ra) # 80002f86 <trapinithart>
    plicinit();      // set up interrupt controller
    80001090:	00005097          	auipc	ra,0x5
    80001094:	4aa080e7          	jalr	1194(ra) # 8000653a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80001098:	00005097          	auipc	ra,0x5
    8000109c:	4b8080e7          	jalr	1208(ra) # 80006550 <plicinithart>
    binit();         // buffer cache
    800010a0:	00002097          	auipc	ra,0x2
    800010a4:	68e080e7          	jalr	1678(ra) # 8000372e <binit>
    iinit();         // inode cache
    800010a8:	00003097          	auipc	ra,0x3
    800010ac:	d1e080e7          	jalr	-738(ra) # 80003dc6 <iinit>
    fileinit();      // file table
    800010b0:	00004097          	auipc	ra,0x4
    800010b4:	cd0080e7          	jalr	-816(ra) # 80004d80 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800010b8:	00005097          	auipc	ra,0x5
    800010bc:	5ba080e7          	jalr	1466(ra) # 80006672 <virtio_disk_init>
    userinit();      // first user process
    800010c0:	00001097          	auipc	ra,0x1
    800010c4:	3e4080e7          	jalr	996(ra) # 800024a4 <userinit>
    __sync_synchronize();
    800010c8:	0ff0000f          	fence
    started = 1;
    800010cc:	4785                	li	a5,1
    800010ce:	00008717          	auipc	a4,0x8
    800010d2:	f4f72523          	sw	a5,-182(a4) # 80009018 <started>
    800010d6:	b789                	j	80001018 <main+0x56>

00000000800010d8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    800010d8:	1141                	addi	sp,sp,-16
    800010da:	e422                	sd	s0,8(sp)
    800010dc:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    800010de:	00008797          	auipc	a5,0x8
    800010e2:	f427b783          	ld	a5,-190(a5) # 80009020 <kernel_pagetable>
    800010e6:	83b1                	srli	a5,a5,0xc
    800010e8:	577d                	li	a4,-1
    800010ea:	177e                	slli	a4,a4,0x3f
    800010ec:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    800010ee:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    800010f2:	12000073          	sfence.vma
  sfence_vma();
}
    800010f6:	6422                	ld	s0,8(sp)
    800010f8:	0141                	addi	sp,sp,16
    800010fa:	8082                	ret

00000000800010fc <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    800010fc:	7139                	addi	sp,sp,-64
    800010fe:	fc06                	sd	ra,56(sp)
    80001100:	f822                	sd	s0,48(sp)
    80001102:	f426                	sd	s1,40(sp)
    80001104:	f04a                	sd	s2,32(sp)
    80001106:	ec4e                	sd	s3,24(sp)
    80001108:	e852                	sd	s4,16(sp)
    8000110a:	e456                	sd	s5,8(sp)
    8000110c:	e05a                	sd	s6,0(sp)
    8000110e:	0080                	addi	s0,sp,64
    80001110:	84aa                	mv	s1,a0
    80001112:	89ae                	mv	s3,a1
    80001114:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80001116:	57fd                	li	a5,-1
    80001118:	83e9                	srli	a5,a5,0x1a
    8000111a:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    8000111c:	4b31                	li	s6,12
  if(va >= MAXVA)
    8000111e:	04b7f263          	bgeu	a5,a1,80001162 <walk+0x66>
    panic("walk");
    80001122:	00007517          	auipc	a0,0x7
    80001126:	fc650513          	addi	a0,a0,-58 # 800080e8 <digits+0xa8>
    8000112a:	fffff097          	auipc	ra,0xfffff
    8000112e:	406080e7          	jalr	1030(ra) # 80000530 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001132:	060a8663          	beqz	s5,8000119e <walk+0xa2>
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	974080e7          	jalr	-1676(ra) # 80000aaa <kalloc>
    8000113e:	84aa                	mv	s1,a0
    80001140:	c529                	beqz	a0,8000118a <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001142:	6605                	lui	a2,0x1
    80001144:	4581                	li	a1,0
    80001146:	00000097          	auipc	ra,0x0
    8000114a:	cca080e7          	jalr	-822(ra) # 80000e10 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    8000114e:	00c4d793          	srli	a5,s1,0xc
    80001152:	07aa                	slli	a5,a5,0xa
    80001154:	0017e793          	ori	a5,a5,1
    80001158:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    8000115c:	3a5d                	addiw	s4,s4,-9
    8000115e:	036a0063          	beq	s4,s6,8000117e <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001162:	0149d933          	srl	s2,s3,s4
    80001166:	1ff97913          	andi	s2,s2,511
    8000116a:	090e                	slli	s2,s2,0x3
    8000116c:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    8000116e:	00093483          	ld	s1,0(s2)
    80001172:	0014f793          	andi	a5,s1,1
    80001176:	dfd5                	beqz	a5,80001132 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001178:	80a9                	srli	s1,s1,0xa
    8000117a:	04b2                	slli	s1,s1,0xc
    8000117c:	b7c5                	j	8000115c <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    8000117e:	00c9d513          	srli	a0,s3,0xc
    80001182:	1ff57513          	andi	a0,a0,511
    80001186:	050e                	slli	a0,a0,0x3
    80001188:	9526                	add	a0,a0,s1
}
    8000118a:	70e2                	ld	ra,56(sp)
    8000118c:	7442                	ld	s0,48(sp)
    8000118e:	74a2                	ld	s1,40(sp)
    80001190:	7902                	ld	s2,32(sp)
    80001192:	69e2                	ld	s3,24(sp)
    80001194:	6a42                	ld	s4,16(sp)
    80001196:	6aa2                	ld	s5,8(sp)
    80001198:	6b02                	ld	s6,0(sp)
    8000119a:	6121                	addi	sp,sp,64
    8000119c:	8082                	ret
        return 0;
    8000119e:	4501                	li	a0,0
    800011a0:	b7ed                	j	8000118a <walk+0x8e>

00000000800011a2 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800011a2:	57fd                	li	a5,-1
    800011a4:	83e9                	srli	a5,a5,0x1a
    800011a6:	00b7f463          	bgeu	a5,a1,800011ae <walkaddr+0xc>
    return 0;
    800011aa:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800011ac:	8082                	ret
{
    800011ae:	1141                	addi	sp,sp,-16
    800011b0:	e406                	sd	ra,8(sp)
    800011b2:	e022                	sd	s0,0(sp)
    800011b4:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800011b6:	4601                	li	a2,0
    800011b8:	00000097          	auipc	ra,0x0
    800011bc:	f44080e7          	jalr	-188(ra) # 800010fc <walk>
  if(pte == 0)
    800011c0:	c105                	beqz	a0,800011e0 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800011c2:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800011c4:	0117f693          	andi	a3,a5,17
    800011c8:	4745                	li	a4,17
    return 0;
    800011ca:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800011cc:	00e68663          	beq	a3,a4,800011d8 <walkaddr+0x36>
}
    800011d0:	60a2                	ld	ra,8(sp)
    800011d2:	6402                	ld	s0,0(sp)
    800011d4:	0141                	addi	sp,sp,16
    800011d6:	8082                	ret
  pa = PTE2PA(*pte);
    800011d8:	00a7d513          	srli	a0,a5,0xa
    800011dc:	0532                	slli	a0,a0,0xc
  return pa;
    800011de:	bfcd                	j	800011d0 <walkaddr+0x2e>
    return 0;
    800011e0:	4501                	li	a0,0
    800011e2:	b7fd                	j	800011d0 <walkaddr+0x2e>

00000000800011e4 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800011e4:	715d                	addi	sp,sp,-80
    800011e6:	e486                	sd	ra,72(sp)
    800011e8:	e0a2                	sd	s0,64(sp)
    800011ea:	fc26                	sd	s1,56(sp)
    800011ec:	f84a                	sd	s2,48(sp)
    800011ee:	f44e                	sd	s3,40(sp)
    800011f0:	f052                	sd	s4,32(sp)
    800011f2:	ec56                	sd	s5,24(sp)
    800011f4:	e85a                	sd	s6,16(sp)
    800011f6:	e45e                	sd	s7,8(sp)
    800011f8:	0880                	addi	s0,sp,80
    800011fa:	8aaa                	mv	s5,a0
    800011fc:	8b3a                	mv	s6,a4
  uint64 a, last;
  pte_t *pte;

  a = PGROUNDDOWN(va);
    800011fe:	777d                	lui	a4,0xfffff
    80001200:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    80001204:	167d                	addi	a2,a2,-1
    80001206:	00b609b3          	add	s3,a2,a1
    8000120a:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    8000120e:	893e                	mv	s2,a5
    80001210:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    80001214:	6b85                	lui	s7,0x1
    80001216:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    8000121a:	4605                	li	a2,1
    8000121c:	85ca                	mv	a1,s2
    8000121e:	8556                	mv	a0,s5
    80001220:	00000097          	auipc	ra,0x0
    80001224:	edc080e7          	jalr	-292(ra) # 800010fc <walk>
    80001228:	c51d                	beqz	a0,80001256 <mappages+0x72>
    if(*pte & PTE_V)
    8000122a:	611c                	ld	a5,0(a0)
    8000122c:	8b85                	andi	a5,a5,1
    8000122e:	ef81                	bnez	a5,80001246 <mappages+0x62>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001230:	80b1                	srli	s1,s1,0xc
    80001232:	04aa                	slli	s1,s1,0xa
    80001234:	0164e4b3          	or	s1,s1,s6
    80001238:	0014e493          	ori	s1,s1,1
    8000123c:	e104                	sd	s1,0(a0)
    if(a == last)
    8000123e:	03390863          	beq	s2,s3,8000126e <mappages+0x8a>
    a += PGSIZE;
    80001242:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001244:	bfc9                	j	80001216 <mappages+0x32>
      panic("remap");
    80001246:	00007517          	auipc	a0,0x7
    8000124a:	eaa50513          	addi	a0,a0,-342 # 800080f0 <digits+0xb0>
    8000124e:	fffff097          	auipc	ra,0xfffff
    80001252:	2e2080e7          	jalr	738(ra) # 80000530 <panic>
      return -1;
    80001256:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001258:	60a6                	ld	ra,72(sp)
    8000125a:	6406                	ld	s0,64(sp)
    8000125c:	74e2                	ld	s1,56(sp)
    8000125e:	7942                	ld	s2,48(sp)
    80001260:	79a2                	ld	s3,40(sp)
    80001262:	7a02                	ld	s4,32(sp)
    80001264:	6ae2                	ld	s5,24(sp)
    80001266:	6b42                	ld	s6,16(sp)
    80001268:	6ba2                	ld	s7,8(sp)
    8000126a:	6161                	addi	sp,sp,80
    8000126c:	8082                	ret
  return 0;
    8000126e:	4501                	li	a0,0
    80001270:	b7e5                	j	80001258 <mappages+0x74>

0000000080001272 <kvmmap>:
{
    80001272:	1141                	addi	sp,sp,-16
    80001274:	e406                	sd	ra,8(sp)
    80001276:	e022                	sd	s0,0(sp)
    80001278:	0800                	addi	s0,sp,16
    8000127a:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    8000127c:	86b2                	mv	a3,a2
    8000127e:	863e                	mv	a2,a5
    80001280:	00000097          	auipc	ra,0x0
    80001284:	f64080e7          	jalr	-156(ra) # 800011e4 <mappages>
    80001288:	e509                	bnez	a0,80001292 <kvmmap+0x20>
}
    8000128a:	60a2                	ld	ra,8(sp)
    8000128c:	6402                	ld	s0,0(sp)
    8000128e:	0141                	addi	sp,sp,16
    80001290:	8082                	ret
    panic("kvmmap");
    80001292:	00007517          	auipc	a0,0x7
    80001296:	e6650513          	addi	a0,a0,-410 # 800080f8 <digits+0xb8>
    8000129a:	fffff097          	auipc	ra,0xfffff
    8000129e:	296080e7          	jalr	662(ra) # 80000530 <panic>

00000000800012a2 <kvmmake>:
{
    800012a2:	1101                	addi	sp,sp,-32
    800012a4:	ec06                	sd	ra,24(sp)
    800012a6:	e822                	sd	s0,16(sp)
    800012a8:	e426                	sd	s1,8(sp)
    800012aa:	e04a                	sd	s2,0(sp)
    800012ac:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800012ae:	fffff097          	auipc	ra,0xfffff
    800012b2:	7fc080e7          	jalr	2044(ra) # 80000aaa <kalloc>
    800012b6:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800012b8:	6605                	lui	a2,0x1
    800012ba:	4581                	li	a1,0
    800012bc:	00000097          	auipc	ra,0x0
    800012c0:	b54080e7          	jalr	-1196(ra) # 80000e10 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800012c4:	4719                	li	a4,6
    800012c6:	6685                	lui	a3,0x1
    800012c8:	10000637          	lui	a2,0x10000
    800012cc:	100005b7          	lui	a1,0x10000
    800012d0:	8526                	mv	a0,s1
    800012d2:	00000097          	auipc	ra,0x0
    800012d6:	fa0080e7          	jalr	-96(ra) # 80001272 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800012da:	4719                	li	a4,6
    800012dc:	6685                	lui	a3,0x1
    800012de:	10001637          	lui	a2,0x10001
    800012e2:	100015b7          	lui	a1,0x10001
    800012e6:	8526                	mv	a0,s1
    800012e8:	00000097          	auipc	ra,0x0
    800012ec:	f8a080e7          	jalr	-118(ra) # 80001272 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800012f0:	4719                	li	a4,6
    800012f2:	004006b7          	lui	a3,0x400
    800012f6:	0c000637          	lui	a2,0xc000
    800012fa:	0c0005b7          	lui	a1,0xc000
    800012fe:	8526                	mv	a0,s1
    80001300:	00000097          	auipc	ra,0x0
    80001304:	f72080e7          	jalr	-142(ra) # 80001272 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001308:	00007917          	auipc	s2,0x7
    8000130c:	cf890913          	addi	s2,s2,-776 # 80008000 <etext>
    80001310:	4729                	li	a4,10
    80001312:	80007697          	auipc	a3,0x80007
    80001316:	cee68693          	addi	a3,a3,-786 # 8000 <_entry-0x7fff8000>
    8000131a:	4605                	li	a2,1
    8000131c:	067e                	slli	a2,a2,0x1f
    8000131e:	85b2                	mv	a1,a2
    80001320:	8526                	mv	a0,s1
    80001322:	00000097          	auipc	ra,0x0
    80001326:	f50080e7          	jalr	-176(ra) # 80001272 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    8000132a:	4719                	li	a4,6
    8000132c:	46c5                	li	a3,17
    8000132e:	06ee                	slli	a3,a3,0x1b
    80001330:	412686b3          	sub	a3,a3,s2
    80001334:	864a                	mv	a2,s2
    80001336:	85ca                	mv	a1,s2
    80001338:	8526                	mv	a0,s1
    8000133a:	00000097          	auipc	ra,0x0
    8000133e:	f38080e7          	jalr	-200(ra) # 80001272 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001342:	4729                	li	a4,10
    80001344:	6685                	lui	a3,0x1
    80001346:	00006617          	auipc	a2,0x6
    8000134a:	cba60613          	addi	a2,a2,-838 # 80007000 <_trampoline>
    8000134e:	040005b7          	lui	a1,0x4000
    80001352:	15fd                	addi	a1,a1,-1
    80001354:	05b2                	slli	a1,a1,0xc
    80001356:	8526                	mv	a0,s1
    80001358:	00000097          	auipc	ra,0x0
    8000135c:	f1a080e7          	jalr	-230(ra) # 80001272 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001360:	8526                	mv	a0,s1
    80001362:	00001097          	auipc	ra,0x1
    80001366:	d1a080e7          	jalr	-742(ra) # 8000207c <proc_mapstacks>
}
    8000136a:	8526                	mv	a0,s1
    8000136c:	60e2                	ld	ra,24(sp)
    8000136e:	6442                	ld	s0,16(sp)
    80001370:	64a2                	ld	s1,8(sp)
    80001372:	6902                	ld	s2,0(sp)
    80001374:	6105                	addi	sp,sp,32
    80001376:	8082                	ret

0000000080001378 <kvminit>:
{
    80001378:	1141                	addi	sp,sp,-16
    8000137a:	e406                	sd	ra,8(sp)
    8000137c:	e022                	sd	s0,0(sp)
    8000137e:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001380:	00000097          	auipc	ra,0x0
    80001384:	f22080e7          	jalr	-222(ra) # 800012a2 <kvmmake>
    80001388:	00008797          	auipc	a5,0x8
    8000138c:	c8a7bc23          	sd	a0,-872(a5) # 80009020 <kernel_pagetable>
}
    80001390:	60a2                	ld	ra,8(sp)
    80001392:	6402                	ld	s0,0(sp)
    80001394:	0141                	addi	sp,sp,16
    80001396:	8082                	ret

0000000080001398 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001398:	715d                	addi	sp,sp,-80
    8000139a:	e486                	sd	ra,72(sp)
    8000139c:	e0a2                	sd	s0,64(sp)
    8000139e:	fc26                	sd	s1,56(sp)
    800013a0:	f84a                	sd	s2,48(sp)
    800013a2:	f44e                	sd	s3,40(sp)
    800013a4:	f052                	sd	s4,32(sp)
    800013a6:	ec56                	sd	s5,24(sp)
    800013a8:	e85a                	sd	s6,16(sp)
    800013aa:	e45e                	sd	s7,8(sp)
    800013ac:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800013ae:	03459793          	slli	a5,a1,0x34
    800013b2:	e795                	bnez	a5,800013de <uvmunmap+0x46>
    800013b4:	8a2a                	mv	s4,a0
    800013b6:	892e                	mv	s2,a1
    800013b8:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013ba:	0632                	slli	a2,a2,0xc
    800013bc:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if(PTE_FLAGS(*pte) == PTE_V) 
    800013c0:	4b05                	li	s6,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800013c2:	6b85                	lui	s7,0x1
    800013c4:	0735e163          	bltu	a1,s3,80001426 <uvmunmap+0x8e>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800013c8:	60a6                	ld	ra,72(sp)
    800013ca:	6406                	ld	s0,64(sp)
    800013cc:	74e2                	ld	s1,56(sp)
    800013ce:	7942                	ld	s2,48(sp)
    800013d0:	79a2                	ld	s3,40(sp)
    800013d2:	7a02                	ld	s4,32(sp)
    800013d4:	6ae2                	ld	s5,24(sp)
    800013d6:	6b42                	ld	s6,16(sp)
    800013d8:	6ba2                	ld	s7,8(sp)
    800013da:	6161                	addi	sp,sp,80
    800013dc:	8082                	ret
    panic("uvmunmap: not aligned");
    800013de:	00007517          	auipc	a0,0x7
    800013e2:	d2250513          	addi	a0,a0,-734 # 80008100 <digits+0xc0>
    800013e6:	fffff097          	auipc	ra,0xfffff
    800013ea:	14a080e7          	jalr	330(ra) # 80000530 <panic>
      panic("uvmunmap: walk");
    800013ee:	00007517          	auipc	a0,0x7
    800013f2:	d2a50513          	addi	a0,a0,-726 # 80008118 <digits+0xd8>
    800013f6:	fffff097          	auipc	ra,0xfffff
    800013fa:	13a080e7          	jalr	314(ra) # 80000530 <panic>
      panic("uvmunmap: not a leaf"); // pte=0x87f73ff0
    800013fe:	00007517          	auipc	a0,0x7
    80001402:	d2a50513          	addi	a0,a0,-726 # 80008128 <digits+0xe8>
    80001406:	fffff097          	auipc	ra,0xfffff
    8000140a:	12a080e7          	jalr	298(ra) # 80000530 <panic>
      uint64 pa = PTE2PA(*pte);
    8000140e:	83a9                	srli	a5,a5,0xa
      kfree((void*)pa);
    80001410:	00c79513          	slli	a0,a5,0xc
    80001414:	fffff097          	auipc	ra,0xfffff
    80001418:	5d6080e7          	jalr	1494(ra) # 800009ea <kfree>
    *pte = 0;
    8000141c:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001420:	995e                	add	s2,s2,s7
    80001422:	fb3973e3          	bgeu	s2,s3,800013c8 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    80001426:	4601                	li	a2,0
    80001428:	85ca                	mv	a1,s2
    8000142a:	8552                	mv	a0,s4
    8000142c:	00000097          	auipc	ra,0x0
    80001430:	cd0080e7          	jalr	-816(ra) # 800010fc <walk>
    80001434:	84aa                	mv	s1,a0
    80001436:	dd45                	beqz	a0,800013ee <uvmunmap+0x56>
    if(PTE_FLAGS(*pte) == PTE_V) 
    80001438:	611c                	ld	a5,0(a0)
    8000143a:	3ff7f713          	andi	a4,a5,1023
    8000143e:	fd6700e3          	beq	a4,s6,800013fe <uvmunmap+0x66>
    if(do_free && (*pte & PTE_V)){
    80001442:	fc0a8de3          	beqz	s5,8000141c <uvmunmap+0x84>
    80001446:	0017f713          	andi	a4,a5,1
    8000144a:	db69                	beqz	a4,8000141c <uvmunmap+0x84>
    8000144c:	b7c9                	j	8000140e <uvmunmap+0x76>

000000008000144e <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    8000144e:	1101                	addi	sp,sp,-32
    80001450:	ec06                	sd	ra,24(sp)
    80001452:	e822                	sd	s0,16(sp)
    80001454:	e426                	sd	s1,8(sp)
    80001456:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001458:	fffff097          	auipc	ra,0xfffff
    8000145c:	652080e7          	jalr	1618(ra) # 80000aaa <kalloc>
    80001460:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001462:	c519                	beqz	a0,80001470 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001464:	6605                	lui	a2,0x1
    80001466:	4581                	li	a1,0
    80001468:	00000097          	auipc	ra,0x0
    8000146c:	9a8080e7          	jalr	-1624(ra) # 80000e10 <memset>
  return pagetable;
}
    80001470:	8526                	mv	a0,s1
    80001472:	60e2                	ld	ra,24(sp)
    80001474:	6442                	ld	s0,16(sp)
    80001476:	64a2                	ld	s1,8(sp)
    80001478:	6105                	addi	sp,sp,32
    8000147a:	8082                	ret

000000008000147c <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    8000147c:	7179                	addi	sp,sp,-48
    8000147e:	f406                	sd	ra,40(sp)
    80001480:	f022                	sd	s0,32(sp)
    80001482:	ec26                	sd	s1,24(sp)
    80001484:	e84a                	sd	s2,16(sp)
    80001486:	e44e                	sd	s3,8(sp)
    80001488:	e052                	sd	s4,0(sp)
    8000148a:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    8000148c:	6785                	lui	a5,0x1
    8000148e:	04f67863          	bgeu	a2,a5,800014de <uvminit+0x62>
    80001492:	8a2a                	mv	s4,a0
    80001494:	89ae                	mv	s3,a1
    80001496:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    80001498:	fffff097          	auipc	ra,0xfffff
    8000149c:	612080e7          	jalr	1554(ra) # 80000aaa <kalloc>
    800014a0:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800014a2:	6605                	lui	a2,0x1
    800014a4:	4581                	li	a1,0
    800014a6:	00000097          	auipc	ra,0x0
    800014aa:	96a080e7          	jalr	-1686(ra) # 80000e10 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800014ae:	4779                	li	a4,30
    800014b0:	86ca                	mv	a3,s2
    800014b2:	6605                	lui	a2,0x1
    800014b4:	4581                	li	a1,0
    800014b6:	8552                	mv	a0,s4
    800014b8:	00000097          	auipc	ra,0x0
    800014bc:	d2c080e7          	jalr	-724(ra) # 800011e4 <mappages>
  memmove(mem, src, sz);
    800014c0:	8626                	mv	a2,s1
    800014c2:	85ce                	mv	a1,s3
    800014c4:	854a                	mv	a0,s2
    800014c6:	00000097          	auipc	ra,0x0
    800014ca:	9aa080e7          	jalr	-1622(ra) # 80000e70 <memmove>
}
    800014ce:	70a2                	ld	ra,40(sp)
    800014d0:	7402                	ld	s0,32(sp)
    800014d2:	64e2                	ld	s1,24(sp)
    800014d4:	6942                	ld	s2,16(sp)
    800014d6:	69a2                	ld	s3,8(sp)
    800014d8:	6a02                	ld	s4,0(sp)
    800014da:	6145                	addi	sp,sp,48
    800014dc:	8082                	ret
    panic("inituvm: more than a page");
    800014de:	00007517          	auipc	a0,0x7
    800014e2:	c6250513          	addi	a0,a0,-926 # 80008140 <digits+0x100>
    800014e6:	fffff097          	auipc	ra,0xfffff
    800014ea:	04a080e7          	jalr	74(ra) # 80000530 <panic>

00000000800014ee <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800014ee:	1101                	addi	sp,sp,-32
    800014f0:	ec06                	sd	ra,24(sp)
    800014f2:	e822                	sd	s0,16(sp)
    800014f4:	e426                	sd	s1,8(sp)
    800014f6:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800014f8:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800014fa:	00b67d63          	bgeu	a2,a1,80001514 <uvmdealloc+0x26>
    800014fe:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001500:	6785                	lui	a5,0x1
    80001502:	17fd                	addi	a5,a5,-1
    80001504:	00f60733          	add	a4,a2,a5
    80001508:	767d                	lui	a2,0xfffff
    8000150a:	8f71                	and	a4,a4,a2
    8000150c:	97ae                	add	a5,a5,a1
    8000150e:	8ff1                	and	a5,a5,a2
    80001510:	00f76863          	bltu	a4,a5,80001520 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001514:	8526                	mv	a0,s1
    80001516:	60e2                	ld	ra,24(sp)
    80001518:	6442                	ld	s0,16(sp)
    8000151a:	64a2                	ld	s1,8(sp)
    8000151c:	6105                	addi	sp,sp,32
    8000151e:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001520:	8f99                	sub	a5,a5,a4
    80001522:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001524:	4685                	li	a3,1
    80001526:	0007861b          	sext.w	a2,a5
    8000152a:	85ba                	mv	a1,a4
    8000152c:	00000097          	auipc	ra,0x0
    80001530:	e6c080e7          	jalr	-404(ra) # 80001398 <uvmunmap>
    80001534:	b7c5                	j	80001514 <uvmdealloc+0x26>

0000000080001536 <uvmalloc>:
  if(newsz < oldsz)
    80001536:	0ab66163          	bltu	a2,a1,800015d8 <uvmalloc+0xa2>
{
    8000153a:	7139                	addi	sp,sp,-64
    8000153c:	fc06                	sd	ra,56(sp)
    8000153e:	f822                	sd	s0,48(sp)
    80001540:	f426                	sd	s1,40(sp)
    80001542:	f04a                	sd	s2,32(sp)
    80001544:	ec4e                	sd	s3,24(sp)
    80001546:	e852                	sd	s4,16(sp)
    80001548:	e456                	sd	s5,8(sp)
    8000154a:	0080                	addi	s0,sp,64
    8000154c:	8aaa                	mv	s5,a0
    8000154e:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001550:	6985                	lui	s3,0x1
    80001552:	19fd                	addi	s3,s3,-1
    80001554:	95ce                	add	a1,a1,s3
    80001556:	79fd                	lui	s3,0xfffff
    80001558:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000155c:	08c9f063          	bgeu	s3,a2,800015dc <uvmalloc+0xa6>
    80001560:	894e                	mv	s2,s3
    mem = kalloc();
    80001562:	fffff097          	auipc	ra,0xfffff
    80001566:	548080e7          	jalr	1352(ra) # 80000aaa <kalloc>
    8000156a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000156c:	c51d                	beqz	a0,8000159a <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    8000156e:	6605                	lui	a2,0x1
    80001570:	4581                	li	a1,0
    80001572:	00000097          	auipc	ra,0x0
    80001576:	89e080e7          	jalr	-1890(ra) # 80000e10 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    8000157a:	4779                	li	a4,30
    8000157c:	86a6                	mv	a3,s1
    8000157e:	6605                	lui	a2,0x1
    80001580:	85ca                	mv	a1,s2
    80001582:	8556                	mv	a0,s5
    80001584:	00000097          	auipc	ra,0x0
    80001588:	c60080e7          	jalr	-928(ra) # 800011e4 <mappages>
    8000158c:	e905                	bnez	a0,800015bc <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000158e:	6785                	lui	a5,0x1
    80001590:	993e                	add	s2,s2,a5
    80001592:	fd4968e3          	bltu	s2,s4,80001562 <uvmalloc+0x2c>
  return newsz;
    80001596:	8552                	mv	a0,s4
    80001598:	a809                	j	800015aa <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    8000159a:	864e                	mv	a2,s3
    8000159c:	85ca                	mv	a1,s2
    8000159e:	8556                	mv	a0,s5
    800015a0:	00000097          	auipc	ra,0x0
    800015a4:	f4e080e7          	jalr	-178(ra) # 800014ee <uvmdealloc>
      return 0;
    800015a8:	4501                	li	a0,0
}
    800015aa:	70e2                	ld	ra,56(sp)
    800015ac:	7442                	ld	s0,48(sp)
    800015ae:	74a2                	ld	s1,40(sp)
    800015b0:	7902                	ld	s2,32(sp)
    800015b2:	69e2                	ld	s3,24(sp)
    800015b4:	6a42                	ld	s4,16(sp)
    800015b6:	6aa2                	ld	s5,8(sp)
    800015b8:	6121                	addi	sp,sp,64
    800015ba:	8082                	ret
      kfree(mem);
    800015bc:	8526                	mv	a0,s1
    800015be:	fffff097          	auipc	ra,0xfffff
    800015c2:	42c080e7          	jalr	1068(ra) # 800009ea <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800015c6:	864e                	mv	a2,s3
    800015c8:	85ca                	mv	a1,s2
    800015ca:	8556                	mv	a0,s5
    800015cc:	00000097          	auipc	ra,0x0
    800015d0:	f22080e7          	jalr	-222(ra) # 800014ee <uvmdealloc>
      return 0;
    800015d4:	4501                	li	a0,0
    800015d6:	bfd1                	j	800015aa <uvmalloc+0x74>
    return oldsz;
    800015d8:	852e                	mv	a0,a1
}
    800015da:	8082                	ret
  return newsz;
    800015dc:	8532                	mv	a0,a2
    800015de:	b7f1                	j	800015aa <uvmalloc+0x74>

00000000800015e0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800015e0:	7179                	addi	sp,sp,-48
    800015e2:	f406                	sd	ra,40(sp)
    800015e4:	f022                	sd	s0,32(sp)
    800015e6:	ec26                	sd	s1,24(sp)
    800015e8:	e84a                	sd	s2,16(sp)
    800015ea:	e44e                	sd	s3,8(sp)
    800015ec:	e052                	sd	s4,0(sp)
    800015ee:	1800                	addi	s0,sp,48
    800015f0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800015f2:	84aa                	mv	s1,a0
    800015f4:	6905                	lui	s2,0x1
    800015f6:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800015f8:	4985                	li	s3,1
    800015fa:	a821                	j	80001612 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800015fc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800015fe:	0532                	slli	a0,a0,0xc
    80001600:	00000097          	auipc	ra,0x0
    80001604:	fe0080e7          	jalr	-32(ra) # 800015e0 <freewalk>
      pagetable[i] = 0;
    80001608:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000160c:	04a1                	addi	s1,s1,8
    8000160e:	03248163          	beq	s1,s2,80001630 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001612:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001614:	00f57793          	andi	a5,a0,15
    80001618:	ff3782e3          	beq	a5,s3,800015fc <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000161c:	8905                	andi	a0,a0,1
    8000161e:	d57d                	beqz	a0,8000160c <freewalk+0x2c>
      panic("freewalk: leaf");
    80001620:	00007517          	auipc	a0,0x7
    80001624:	b4050513          	addi	a0,a0,-1216 # 80008160 <digits+0x120>
    80001628:	fffff097          	auipc	ra,0xfffff
    8000162c:	f08080e7          	jalr	-248(ra) # 80000530 <panic>
    }
  }
  kfree((void*)pagetable);
    80001630:	8552                	mv	a0,s4
    80001632:	fffff097          	auipc	ra,0xfffff
    80001636:	3b8080e7          	jalr	952(ra) # 800009ea <kfree>
}
    8000163a:	70a2                	ld	ra,40(sp)
    8000163c:	7402                	ld	s0,32(sp)
    8000163e:	64e2                	ld	s1,24(sp)
    80001640:	6942                	ld	s2,16(sp)
    80001642:	69a2                	ld	s3,8(sp)
    80001644:	6a02                	ld	s4,0(sp)
    80001646:	6145                	addi	sp,sp,48
    80001648:	8082                	ret

000000008000164a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000164a:	1101                	addi	sp,sp,-32
    8000164c:	ec06                	sd	ra,24(sp)
    8000164e:	e822                	sd	s0,16(sp)
    80001650:	e426                	sd	s1,8(sp)
    80001652:	1000                	addi	s0,sp,32
    80001654:	84aa                	mv	s1,a0
  if(sz > 0)
    80001656:	e999                	bnez	a1,8000166c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001658:	8526                	mv	a0,s1
    8000165a:	00000097          	auipc	ra,0x0
    8000165e:	f86080e7          	jalr	-122(ra) # 800015e0 <freewalk>
}
    80001662:	60e2                	ld	ra,24(sp)
    80001664:	6442                	ld	s0,16(sp)
    80001666:	64a2                	ld	s1,8(sp)
    80001668:	6105                	addi	sp,sp,32
    8000166a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000166c:	6605                	lui	a2,0x1
    8000166e:	167d                	addi	a2,a2,-1
    80001670:	962e                	add	a2,a2,a1
    80001672:	4685                	li	a3,1
    80001674:	8231                	srli	a2,a2,0xc
    80001676:	4581                	li	a1,0
    80001678:	00000097          	auipc	ra,0x0
    8000167c:	d20080e7          	jalr	-736(ra) # 80001398 <uvmunmap>
    80001680:	bfe1                	j	80001658 <uvmfree+0xe>

0000000080001682 <uvmcopy>:
// physical memory.
// returns 0 on success, -1 on failure.
// frees any allocated pages on failure.
int
uvmcopy(pagetable_t old, pagetable_t new, uint64 start, uint64 sz)
{
    80001682:	715d                	addi	sp,sp,-80
    80001684:	e486                	sd	ra,72(sp)
    80001686:	e0a2                	sd	s0,64(sp)
    80001688:	fc26                	sd	s1,56(sp)
    8000168a:	f84a                	sd	s2,48(sp)
    8000168c:	f44e                	sd	s3,40(sp)
    8000168e:	f052                	sd	s4,32(sp)
    80001690:	ec56                	sd	s5,24(sp)
    80001692:	e85a                	sd	s6,16(sp)
    80001694:	e45e                	sd	s7,8(sp)
    80001696:	e062                	sd	s8,0(sp)
    80001698:	0880                	addi	s0,sp,80
  pte_t *pte, *npte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = start; i < start + sz; i += PGSIZE){
    8000169a:	00d60a33          	add	s4,a2,a3
    8000169e:	0d467563          	bgeu	a2,s4,80001768 <uvmcopy+0xe6>
    800016a2:	8baa                	mv	s7,a0
    800016a4:	8aae                	mv	s5,a1
    800016a6:	8b32                	mv	s6,a2
    800016a8:	8932                	mv	s2,a2
    800016aa:	a889                	j	800016fc <uvmcopy+0x7a>
    if((pte = walk(old, i, 0)) == 0)
      panic("uvmcopy: pte should exist");
    800016ac:	00007517          	auipc	a0,0x7
    800016b0:	ac450513          	addi	a0,a0,-1340 # 80008170 <digits+0x130>
    800016b4:	fffff097          	auipc	ra,0xfffff
    800016b8:	e7c080e7          	jalr	-388(ra) # 80000530 <panic>
      npte = walk(new, i, 1);
      *npte = *pte;
    }
    else
    {
      pa = PTE2PA(*pte);
    800016bc:	00a75593          	srli	a1,a4,0xa
    800016c0:	00c59c13          	slli	s8,a1,0xc
      flags = PTE_FLAGS(*pte);
    800016c4:	3ff77493          	andi	s1,a4,1023
      if((mem = kalloc()) == 0)
    800016c8:	fffff097          	auipc	ra,0xfffff
    800016cc:	3e2080e7          	jalr	994(ra) # 80000aaa <kalloc>
    800016d0:	89aa                	mv	s3,a0
    800016d2:	c12d                	beqz	a0,80001734 <uvmcopy+0xb2>
        goto err;
      memmove(mem, (char*)pa, PGSIZE);
    800016d4:	6605                	lui	a2,0x1
    800016d6:	85e2                	mv	a1,s8
    800016d8:	fffff097          	auipc	ra,0xfffff
    800016dc:	798080e7          	jalr	1944(ra) # 80000e70 <memmove>
      if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800016e0:	8726                	mv	a4,s1
    800016e2:	86ce                	mv	a3,s3
    800016e4:	6605                	lui	a2,0x1
    800016e6:	85ca                	mv	a1,s2
    800016e8:	8556                	mv	a0,s5
    800016ea:	00000097          	auipc	ra,0x0
    800016ee:	afa080e7          	jalr	-1286(ra) # 800011e4 <mappages>
    800016f2:	ed05                	bnez	a0,8000172a <uvmcopy+0xa8>
  for(i = start; i < start + sz; i += PGSIZE){
    800016f4:	6785                	lui	a5,0x1
    800016f6:	993e                	add	s2,s2,a5
    800016f8:	07497663          	bgeu	s2,s4,80001764 <uvmcopy+0xe2>
    if((pte = walk(old, i, 0)) == 0)
    800016fc:	4601                	li	a2,0
    800016fe:	85ca                	mv	a1,s2
    80001700:	855e                	mv	a0,s7
    80001702:	00000097          	auipc	ra,0x0
    80001706:	9fa080e7          	jalr	-1542(ra) # 800010fc <walk>
    8000170a:	84aa                	mv	s1,a0
    8000170c:	d145                	beqz	a0,800016ac <uvmcopy+0x2a>
    if((*pte & PTE_V) == 0)
    8000170e:	6118                	ld	a4,0(a0)
    80001710:	00177793          	andi	a5,a4,1
    80001714:	f7c5                	bnez	a5,800016bc <uvmcopy+0x3a>
      npte = walk(new, i, 1);
    80001716:	4605                	li	a2,1
    80001718:	85ca                	mv	a1,s2
    8000171a:	8556                	mv	a0,s5
    8000171c:	00000097          	auipc	ra,0x0
    80001720:	9e0080e7          	jalr	-1568(ra) # 800010fc <walk>
      *npte = *pte;
    80001724:	609c                	ld	a5,0(s1)
    80001726:	e11c                	sd	a5,0(a0)
    80001728:	b7f1                	j	800016f4 <uvmcopy+0x72>
        kfree(mem);
    8000172a:	854e                	mv	a0,s3
    8000172c:	fffff097          	auipc	ra,0xfffff
    80001730:	2be080e7          	jalr	702(ra) # 800009ea <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, start, (i - start) / PGSIZE, 1);
    80001734:	41690933          	sub	s2,s2,s6
    80001738:	4685                	li	a3,1
    8000173a:	00c95613          	srli	a2,s2,0xc
    8000173e:	85da                	mv	a1,s6
    80001740:	8556                	mv	a0,s5
    80001742:	00000097          	auipc	ra,0x0
    80001746:	c56080e7          	jalr	-938(ra) # 80001398 <uvmunmap>
  return -1;
    8000174a:	557d                	li	a0,-1
}
    8000174c:	60a6                	ld	ra,72(sp)
    8000174e:	6406                	ld	s0,64(sp)
    80001750:	74e2                	ld	s1,56(sp)
    80001752:	7942                	ld	s2,48(sp)
    80001754:	79a2                	ld	s3,40(sp)
    80001756:	7a02                	ld	s4,32(sp)
    80001758:	6ae2                	ld	s5,24(sp)
    8000175a:	6b42                	ld	s6,16(sp)
    8000175c:	6ba2                	ld	s7,8(sp)
    8000175e:	6c02                	ld	s8,0(sp)
    80001760:	6161                	addi	sp,sp,80
    80001762:	8082                	ret
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	b7dd                	j	8000174c <uvmcopy+0xca>
    80001768:	4501                	li	a0,0
    8000176a:	b7cd                	j	8000174c <uvmcopy+0xca>

000000008000176c <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000176c:	1141                	addi	sp,sp,-16
    8000176e:	e406                	sd	ra,8(sp)
    80001770:	e022                	sd	s0,0(sp)
    80001772:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001774:	4601                	li	a2,0
    80001776:	00000097          	auipc	ra,0x0
    8000177a:	986080e7          	jalr	-1658(ra) # 800010fc <walk>
  if(pte == 0)
    8000177e:	c901                	beqz	a0,8000178e <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001780:	611c                	ld	a5,0(a0)
    80001782:	9bbd                	andi	a5,a5,-17
    80001784:	e11c                	sd	a5,0(a0)
}
    80001786:	60a2                	ld	ra,8(sp)
    80001788:	6402                	ld	s0,0(sp)
    8000178a:	0141                	addi	sp,sp,16
    8000178c:	8082                	ret
    panic("uvmclear");
    8000178e:	00007517          	auipc	a0,0x7
    80001792:	a0250513          	addi	a0,a0,-1534 # 80008190 <digits+0x150>
    80001796:	fffff097          	auipc	ra,0xfffff
    8000179a:	d9a080e7          	jalr	-614(ra) # 80000530 <panic>

000000008000179e <sys_mmap>:
  }
}

uint64
sys_mmap()
{
    8000179e:	7119                	addi	sp,sp,-128
    800017a0:	fc86                	sd	ra,120(sp)
    800017a2:	f8a2                	sd	s0,112(sp)
    800017a4:	f4a6                	sd	s1,104(sp)
    800017a6:	f0ca                	sd	s2,96(sp)
    800017a8:	ecce                	sd	s3,88(sp)
    800017aa:	e8d2                	sd	s4,80(sp)
    800017ac:	e4d6                	sd	s5,72(sp)
    800017ae:	e0da                	sd	s6,64(sp)
    800017b0:	fc5e                	sd	s7,56(sp)
    800017b2:	f862                	sd	s8,48(sp)
    800017b4:	f466                	sd	s9,40(sp)
    800017b6:	f06a                	sd	s10,32(sp)
    800017b8:	0100                	addi	s0,sp,128
  uint64 addr;
  int length, prot, flags, fd, offset;
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    800017ba:	f9840593          	addi	a1,s0,-104
    800017be:	4501                	li	a0,0
    800017c0:	00002097          	auipc	ra,0x2
    800017c4:	cae080e7          	jalr	-850(ra) # 8000346e <argaddr>
    return -1;
    800017c8:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    800017ca:	08054463          	bltz	a0,80001852 <sys_mmap+0xb4>
    800017ce:	f9440593          	addi	a1,s0,-108
    800017d2:	4505                	li	a0,1
    800017d4:	00002097          	auipc	ra,0x2
    800017d8:	c78080e7          	jalr	-904(ra) # 8000344c <argint>
    return -1;
    800017dc:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    800017de:	06054a63          	bltz	a0,80001852 <sys_mmap+0xb4>
    800017e2:	f9040593          	addi	a1,s0,-112
    800017e6:	4509                	li	a0,2
    800017e8:	00002097          	auipc	ra,0x2
    800017ec:	c64080e7          	jalr	-924(ra) # 8000344c <argint>
    return -1;
    800017f0:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    800017f2:	06054063          	bltz	a0,80001852 <sys_mmap+0xb4>
    800017f6:	f8c40593          	addi	a1,s0,-116
    800017fa:	450d                	li	a0,3
    800017fc:	00002097          	auipc	ra,0x2
    80001800:	c50080e7          	jalr	-944(ra) # 8000344c <argint>
    return -1;
    80001804:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    80001806:	04054663          	bltz	a0,80001852 <sys_mmap+0xb4>
    8000180a:	f8840593          	addi	a1,s0,-120
    8000180e:	4511                	li	a0,4
    80001810:	00002097          	auipc	ra,0x2
    80001814:	c3c080e7          	jalr	-964(ra) # 8000344c <argint>
    return -1;
    80001818:	57fd                	li	a5,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0 || argint(2, &prot) < 0 || argint(3, &flags) < 0 || argint(4, &fd) < 0 || argint(5, &offset) < 0)
    8000181a:	02054c63          	bltz	a0,80001852 <sys_mmap+0xb4>
    8000181e:	f8440593          	addi	a1,s0,-124
    80001822:	4515                	li	a0,5
    80001824:	00002097          	auipc	ra,0x2
    80001828:	c28080e7          	jalr	-984(ra) # 8000344c <argint>
    8000182c:	26054363          	bltz	a0,80001a92 <sys_mmap+0x2f4>
  if (addr != 0 || offset != 0 || (prot & PTE_X))
    80001830:	f9843703          	ld	a4,-104(s0)
    return -1;
    80001834:	57fd                	li	a5,-1
  if (addr != 0 || offset != 0 || (prot & PTE_X))
    80001836:	ef11                	bnez	a4,80001852 <sys_mmap+0xb4>
    80001838:	f9042703          	lw	a4,-112(s0)
    8000183c:	8b21                	andi	a4,a4,8
    8000183e:	f8442783          	lw	a5,-124(s0)
    80001842:	8f5d                	or	a4,a4,a5
    return -1;
    80001844:	57fd                	li	a5,-1
  if (addr != 0 || offset != 0 || (prot & PTE_X))
    80001846:	e711                	bnez	a4,80001852 <sys_mmap+0xb4>
  // length should be page aligned
  if (PGROUNDDOWN(length) != length)
    80001848:	f9442703          	lw	a4,-108(s0)
    8000184c:	03471693          	slli	a3,a4,0x34
    80001850:	c285                	beqz	a3,80001870 <sys_mmap+0xd2>
    prev->next = new_vma;

  filedup(fp);

  return new_vma->start;
}
    80001852:	853e                	mv	a0,a5
    80001854:	70e6                	ld	ra,120(sp)
    80001856:	7446                	ld	s0,112(sp)
    80001858:	74a6                	ld	s1,104(sp)
    8000185a:	7906                	ld	s2,96(sp)
    8000185c:	69e6                	ld	s3,88(sp)
    8000185e:	6a46                	ld	s4,80(sp)
    80001860:	6aa6                	ld	s5,72(sp)
    80001862:	6b06                	ld	s6,64(sp)
    80001864:	7be2                	ld	s7,56(sp)
    80001866:	7c42                	ld	s8,48(sp)
    80001868:	7ca2                	ld	s9,40(sp)
    8000186a:	7d02                	ld	s10,32(sp)
    8000186c:	6109                	addi	sp,sp,128
    8000186e:	8082                	ret
  struct file *fp = myproc()->ofile[fd];
    80001870:	00001097          	auipc	ra,0x1
    80001874:	966080e7          	jalr	-1690(ra) # 800021d6 <myproc>
    80001878:	f8842783          	lw	a5,-120(s0)
    8000187c:	07e9                	addi	a5,a5,26
    8000187e:	078e                	slli	a5,a5,0x3
    80001880:	97aa                	add	a5,a5,a0
    80001882:	0007bc03          	ld	s8,0(a5) # 1000 <_entry-0x7ffff000>
  if (!fp->readable && (prot & PROT_READ))
    80001886:	008c4783          	lbu	a5,8(s8)
    8000188a:	ef81                	bnez	a5,800018a2 <sys_mmap+0x104>
    8000188c:	f9042703          	lw	a4,-112(s0)
    80001890:	00177693          	andi	a3,a4,1
    return -1;
    80001894:	57fd                	li	a5,-1
  if (!fp->readable && (prot & PROT_READ))
    80001896:	fed5                	bnez	a3,80001852 <sys_mmap+0xb4>
  if (!fp->writable && (prot & PROT_WRITE) && flags == MAP_SHARED)
    80001898:	009c4783          	lbu	a5,9(s8)
  int pte_flags = PTE_U;
    8000189c:	4a41                	li	s4,16
  if (!fp->writable && (prot & PROT_WRITE) && flags == MAP_SHARED)
    8000189e:	eb9d                	bnez	a5,800018d4 <sys_mmap+0x136>
    800018a0:	a021                	j	800018a8 <sys_mmap+0x10a>
    800018a2:	009c4783          	lbu	a5,9(s8)
    800018a6:	e38d                	bnez	a5,800018c8 <sys_mmap+0x12a>
    800018a8:	f9042783          	lw	a5,-112(s0)
    800018ac:	0027f713          	andi	a4,a5,2
    800018b0:	1e070563          	beqz	a4,80001a9a <sys_mmap+0x2fc>
    800018b4:	f8c42683          	lw	a3,-116(s0)
    800018b8:	4705                	li	a4,1
    800018ba:	1ce68e63          	beq	a3,a4,80001a96 <sys_mmap+0x2f8>
  if (prot & PROT_READ)
    800018be:	8b85                	andi	a5,a5,1
  int pte_flags = PTE_U;
    800018c0:	4a41                	li	s4,16
  if (prot & PROT_READ)
    800018c2:	cb99                	beqz	a5,800018d8 <sys_mmap+0x13a>
    pte_flags |= PTE_R;
    800018c4:	4a49                	li	s4,18
    800018c6:	a809                	j	800018d8 <sys_mmap+0x13a>
  if (prot & PROT_READ)
    800018c8:	f9042703          	lw	a4,-112(s0)
    800018cc:	00177793          	andi	a5,a4,1
    800018d0:	cfbd                	beqz	a5,8000194e <sys_mmap+0x1b0>
    pte_flags |= PTE_R;
    800018d2:	4a49                	li	s4,18
  if (prot & PROT_WRITE)
    800018d4:	8b09                	andi	a4,a4,2
    800018d6:	c319                	beqz	a4,800018dc <sys_mmap+0x13e>
    pte_flags |= PTE_W;
    800018d8:	004a6a13          	ori	s4,s4,4
  struct vma *p = myproc()->vma, *new_vma = kvma_alloc(), *prev = 0;
    800018dc:	00001097          	auipc	ra,0x1
    800018e0:	8fa080e7          	jalr	-1798(ra) # 800021d6 <myproc>
    800018e4:	16853903          	ld	s2,360(a0)
    800018e8:	fffff097          	auipc	ra,0xfffff
    800018ec:	352080e7          	jalr	850(ra) # 80000c3a <kvma_alloc>
    800018f0:	8aaa                	mv	s5,a0
  new_vma->length = length;  
    800018f2:	f9442783          	lw	a5,-108(s0)
    800018f6:	f11c                	sd	a5,32(a0)
  new_vma->offset = offset;
    800018f8:	f8442783          	lw	a5,-124(s0)
    800018fc:	f51c                	sd	a5,40(a0)
  new_vma->prot = prot;
    800018fe:	f9042783          	lw	a5,-112(s0)
    80001902:	c91c                	sw	a5,16(a0)
  new_vma->flags = flags;
    80001904:	f8c42783          	lw	a5,-116(s0)
    80001908:	d91c                	sw	a5,48(a0)
  new_vma->file = fp;
    8000190a:	01853c23          	sd	s8,24(a0)
  new_vma->next = 0;
    8000190e:	02053c23          	sd	zero,56(a0)
  pagetable_t pagetable = myproc()->pagetable;
    80001912:	00001097          	auipc	ra,0x1
    80001916:	8c4080e7          	jalr	-1852(ra) # 800021d6 <myproc>
    8000191a:	05053b03          	ld	s6,80(a0)
  if (p == 0)
    8000191e:	02090a63          	beqz	s2,80001952 <sys_mmap+0x1b4>
    lower = p->end;
    80001922:	00893783          	ld	a5,8(s2) # 1008 <_entry-0x7fffeff8>
    if (upper - lower >= length)
    80001926:	f9442583          	lw	a1,-108(s0)
    8000192a:	020004b7          	lui	s1,0x2000
    8000192e:	14fd                	addi	s1,s1,-1
    80001930:	04b6                	slli	s1,s1,0xd
    80001932:	4b81                	li	s7,0
    80001934:	40f487b3          	sub	a5,s1,a5
    80001938:	02b7f663          	bgeu	a5,a1,80001964 <sys_mmap+0x1c6>
    upper = p->start;
    8000193c:	00093483          	ld	s1,0(s2)
    if (p->next == 0)
    80001940:	03893703          	ld	a4,56(s2)
    80001944:	cf59                	beqz	a4,800019e2 <sys_mmap+0x244>
      lower = p->next->end;
    80001946:	671c                	ld	a5,8(a4)
    80001948:	8bca                	mv	s7,s2
    8000194a:	893a                	mv	s2,a4
    8000194c:	b7e5                	j	80001934 <sys_mmap+0x196>
  int pte_flags = PTE_U;
    8000194e:	4a41                	li	s4,16
    80001950:	b751                	j	800018d4 <sys_mmap+0x136>
    lower = upper - length;
    80001952:	f9442583          	lw	a1,-108(s0)
    80001956:	020004b7          	lui	s1,0x2000
    8000195a:	14fd                	addi	s1,s1,-1
    8000195c:	04b6                	slli	s1,s1,0xd
    8000195e:	40b485b3          	sub	a1,s1,a1
  for (; p != 0; p = p->next)
    80001962:	a051                	j	800019e6 <sys_mmap+0x248>
      for (uint64 va = upper - PGSIZE; va >= upper - length; va -= PGSIZE)
    80001964:	7cfd                	lui	s9,0xfffff
    80001966:	9ca6                	add	s9,s9,s1
    80001968:	40b485b3          	sub	a1,s1,a1
    8000196c:	02bce563          	bltu	s9,a1,80001996 <sys_mmap+0x1f8>
    80001970:	89e6                	mv	s3,s9
    80001972:	7d7d                	lui	s10,0xfffff
        pte_t *pte = walk(pagetable, va, 1);
    80001974:	4605                	li	a2,1
    80001976:	85ce                	mv	a1,s3
    80001978:	855a                	mv	a0,s6
    8000197a:	fffff097          	auipc	ra,0xfffff
    8000197e:	782080e7          	jalr	1922(ra) # 800010fc <walk>
        if (pte)
    80001982:	cd05                	beqz	a0,800019ba <sys_mmap+0x21c>
          *pte = PA2PTE(0) | pte_flags;  // allocate a fake 0 address
    80001984:	01453023          	sd	s4,0(a0)
      for (uint64 va = upper - PGSIZE; va >= upper - length; va -= PGSIZE)
    80001988:	99ea                	add	s3,s3,s10
    8000198a:	f9442583          	lw	a1,-108(s0)
    8000198e:	40b485b3          	sub	a1,s1,a1
    80001992:	feb9f1e3          	bgeu	s3,a1,80001974 <sys_mmap+0x1d6>
      new_vma->start = upper - length;
    80001996:	00bab023          	sd	a1,0(s5)
      new_vma->end = upper;
    8000199a:	009ab423          	sd	s1,8(s5)
      new_vma->next = p;
    8000199e:	032abc23          	sd	s2,56(s5)
      if (prev == 0)
    800019a2:	020b8963          	beqz	s7,800019d4 <sys_mmap+0x236>
        prev->next = new_vma;
    800019a6:	035bbc23          	sd	s5,56(s7) # 1038 <_entry-0x7fffefc8>
      filedup(fp);
    800019aa:	8562                	mv	a0,s8
    800019ac:	00003097          	auipc	ra,0x3
    800019b0:	466080e7          	jalr	1126(ra) # 80004e12 <filedup>
      return new_vma->start;
    800019b4:	000ab783          	ld	a5,0(s5)
    800019b8:	bd69                	j	80001852 <sys_mmap+0xb4>
          uvmunmap(pagetable, va + PGSIZE, (upper - PGSIZE - va) / PGSIZE, 0);
    800019ba:	413c8633          	sub	a2,s9,s3
    800019be:	4681                	li	a3,0
    800019c0:	8231                	srli	a2,a2,0xc
    800019c2:	6585                	lui	a1,0x1
    800019c4:	95ce                	add	a1,a1,s3
    800019c6:	855a                	mv	a0,s6
    800019c8:	00000097          	auipc	ra,0x0
    800019cc:	9d0080e7          	jalr	-1584(ra) # 80001398 <uvmunmap>
          return -1;
    800019d0:	57fd                	li	a5,-1
    800019d2:	b541                	j	80001852 <sys_mmap+0xb4>
        myproc()->vma = new_vma;
    800019d4:	00001097          	auipc	ra,0x1
    800019d8:	802080e7          	jalr	-2046(ra) # 800021d6 <myproc>
    800019dc:	17553423          	sd	s5,360(a0)
    800019e0:	b7e9                	j	800019aa <sys_mmap+0x20c>
      lower = upper - length;
    800019e2:	40b485b3          	sub	a1,s1,a1
  pte_t *pte = walk(pagetable, lower, 0);
    800019e6:	4601                	li	a2,0
    800019e8:	855a                	mv	a0,s6
    800019ea:	fffff097          	auipc	ra,0xfffff
    800019ee:	712080e7          	jalr	1810(ra) # 800010fc <walk>
  if (*pte != 0)
    800019f2:	6118                	ld	a4,0(a0)
    return -1;
    800019f4:	57fd                	li	a5,-1
  if (*pte != 0)
    800019f6:	e4071ee3          	bnez	a4,80001852 <sys_mmap+0xb4>
  for (uint64 va = upper - PGSIZE; va >= upper - length; va -= PGSIZE)
    800019fa:	7d7d                	lui	s10,0xfffff
    800019fc:	9d26                	add	s10,s10,s1
    800019fe:	f9442783          	lw	a5,-108(s0)
    80001a02:	40f487b3          	sub	a5,s1,a5
    80001a06:	04fd6063          	bltu	s10,a5,80001a46 <sys_mmap+0x2a8>
    80001a0a:	89ea                	mv	s3,s10
      printf("va=%p, pte=%p\n", va, *pte);
    80001a0c:	00006c97          	auipc	s9,0x6
    80001a10:	794c8c93          	addi	s9,s9,1940 # 800081a0 <digits+0x160>
  for (uint64 va = upper - PGSIZE; va >= upper - length; va -= PGSIZE)
    80001a14:	7bfd                	lui	s7,0xfffff
    pte_t *pte = walk(pagetable, va, 1);
    80001a16:	4605                	li	a2,1
    80001a18:	85ce                	mv	a1,s3
    80001a1a:	855a                	mv	a0,s6
    80001a1c:	fffff097          	auipc	ra,0xfffff
    80001a20:	6e0080e7          	jalr	1760(ra) # 800010fc <walk>
    if (pte)
    80001a24:	c139                	beqz	a0,80001a6a <sys_mmap+0x2cc>
      *pte = PA2PTE(0) | pte_flags;  // allocate a fake 0 address
    80001a26:	01453023          	sd	s4,0(a0)
      printf("va=%p, pte=%p\n", va, *pte);
    80001a2a:	8652                	mv	a2,s4
    80001a2c:	85ce                	mv	a1,s3
    80001a2e:	8566                	mv	a0,s9
    80001a30:	fffff097          	auipc	ra,0xfffff
    80001a34:	b4a080e7          	jalr	-1206(ra) # 8000057a <printf>
  for (uint64 va = upper - PGSIZE; va >= upper - length; va -= PGSIZE)
    80001a38:	99de                	add	s3,s3,s7
    80001a3a:	f9442783          	lw	a5,-108(s0)
    80001a3e:	40f487b3          	sub	a5,s1,a5
    80001a42:	fcf9fae3          	bgeu	s3,a5,80001a16 <sys_mmap+0x278>
  new_vma->start = upper - length;
    80001a46:	00fab023          	sd	a5,0(s5)
  new_vma->end = upper;
    80001a4a:	009ab423          	sd	s1,8(s5)
  new_vma->next = 0;
    80001a4e:	020abc23          	sd	zero,56(s5)
  if (prev == 0)
    80001a52:	02090963          	beqz	s2,80001a84 <sys_mmap+0x2e6>
    prev->next = new_vma;
    80001a56:	03593c23          	sd	s5,56(s2)
  filedup(fp);
    80001a5a:	8562                	mv	a0,s8
    80001a5c:	00003097          	auipc	ra,0x3
    80001a60:	3b6080e7          	jalr	950(ra) # 80004e12 <filedup>
  return new_vma->start;
    80001a64:	000ab783          	ld	a5,0(s5)
    80001a68:	b3ed                	j	80001852 <sys_mmap+0xb4>
      uvmunmap(pagetable, va + PGSIZE, (upper - PGSIZE - va) / PGSIZE, 0);
    80001a6a:	413d0633          	sub	a2,s10,s3
    80001a6e:	4681                	li	a3,0
    80001a70:	8231                	srli	a2,a2,0xc
    80001a72:	6585                	lui	a1,0x1
    80001a74:	95ce                	add	a1,a1,s3
    80001a76:	855a                	mv	a0,s6
    80001a78:	00000097          	auipc	ra,0x0
    80001a7c:	920080e7          	jalr	-1760(ra) # 80001398 <uvmunmap>
      return -1;
    80001a80:	57fd                	li	a5,-1
    80001a82:	bbc1                	j	80001852 <sys_mmap+0xb4>
    myproc()->vma = new_vma;
    80001a84:	00000097          	auipc	ra,0x0
    80001a88:	752080e7          	jalr	1874(ra) # 800021d6 <myproc>
    80001a8c:	17553423          	sd	s5,360(a0)
    80001a90:	b7e9                	j	80001a5a <sys_mmap+0x2bc>
    return -1;
    80001a92:	57fd                	li	a5,-1
    80001a94:	bb7d                	j	80001852 <sys_mmap+0xb4>
    return -1;
    80001a96:	57fd                	li	a5,-1
    80001a98:	bb6d                	j	80001852 <sys_mmap+0xb4>
  if (prot & PROT_READ)
    80001a9a:	8b85                	andi	a5,a5,1
  int pte_flags = PTE_U;
    80001a9c:	4a41                	li	s4,16
  if (prot & PROT_READ)
    80001a9e:	e2078fe3          	beqz	a5,800018dc <sys_mmap+0x13e>
    pte_flags |= PTE_R;
    80001aa2:	4a49                	li	s4,18
    80001aa4:	bd25                	j	800018dc <sys_mmap+0x13e>

0000000080001aa6 <pagefault_handler>:
pagefault_handler(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  char *pa;

  if(va >= MAXVA)
    80001aa6:	57fd                	li	a5,-1
    80001aa8:	83e9                	srli	a5,a5,0x1a
    80001aaa:	0cb7ee63          	bltu	a5,a1,80001b86 <pagefault_handler+0xe0>
{
    80001aae:	7179                	addi	sp,sp,-48
    80001ab0:	f406                	sd	ra,40(sp)
    80001ab2:	f022                	sd	s0,32(sp)
    80001ab4:	ec26                	sd	s1,24(sp)
    80001ab6:	e84a                	sd	s2,16(sp)
    80001ab8:	e44e                	sd	s3,8(sp)
    80001aba:	e052                	sd	s4,0(sp)
    80001abc:	1800                	addi	s0,sp,48
    80001abe:	892e                	mv	s2,a1
    return -1;
  if ((pte = walk(pagetable, va, 0)) == 0)
    80001ac0:	4601                	li	a2,0
    80001ac2:	fffff097          	auipc	ra,0xfffff
    80001ac6:	63a080e7          	jalr	1594(ra) # 800010fc <walk>
    80001aca:	89aa                	mv	s3,a0
    80001acc:	cd5d                	beqz	a0,80001b8a <pagefault_handler+0xe4>
    // invalid address
    return -1;
  if ((*pte & PTE_U) == 0)
    80001ace:	611c                	ld	a5,0(a0)
    80001ad0:	8bc1                	andi	a5,a5,16
    80001ad2:	cfd5                	beqz	a5,80001b8e <pagefault_handler+0xe8>
    return -1;
  
  // find vma
  struct vma *p;
  for (p = myproc()->vma; p != 0; p = p->next)
    80001ad4:	00000097          	auipc	ra,0x0
    80001ad8:	702080e7          	jalr	1794(ra) # 800021d6 <myproc>
    80001adc:	16853483          	ld	s1,360(a0)
    80001ae0:	e899                	bnez	s1,80001af6 <pagefault_handler+0x50>
    if (va >= p->start && va < p->end)
      break;
  if (p == 0)
    panic("cannot find vma");
    80001ae2:	00006517          	auipc	a0,0x6
    80001ae6:	6ce50513          	addi	a0,a0,1742 # 800081b0 <digits+0x170>
    80001aea:	fffff097          	auipc	ra,0xfffff
    80001aee:	a46080e7          	jalr	-1466(ra) # 80000530 <panic>
  for (p = myproc()->vma; p != 0; p = p->next)
    80001af2:	7c84                	ld	s1,56(s1)
    80001af4:	d4fd                	beqz	s1,80001ae2 <pagefault_handler+0x3c>
    if (va >= p->start && va < p->end)
    80001af6:	609c                	ld	a5,0(s1)
    80001af8:	fef96de3          	bltu	s2,a5,80001af2 <pagefault_handler+0x4c>
    80001afc:	649c                	ld	a5,8(s1)
    80001afe:	fef97ae3          	bgeu	s2,a5,80001af2 <pagefault_handler+0x4c>
  
  // alloc a page
  pa = kalloc();
    80001b02:	fffff097          	auipc	ra,0xfffff
    80001b06:	fa8080e7          	jalr	-88(ra) # 80000aaa <kalloc>
    80001b0a:	8a2a                	mv	s4,a0
  if (pa == 0)
    80001b0c:	c159                	beqz	a0,80001b92 <pagefault_handler+0xec>
    return -1;
  memset(pa, 0, PGSIZE);
    80001b0e:	6605                	lui	a2,0x1
    80001b10:	4581                	li	a1,0
    80001b12:	8552                	mv	a0,s4
    80001b14:	fffff097          	auipc	ra,0xfffff
    80001b18:	2fc080e7          	jalr	764(ra) # 80000e10 <memset>
  *pte = PA2PTE(pa) | PTE_FLAGS(*pte) | PTE_V;
    80001b1c:	00ca5793          	srli	a5,s4,0xc
    80001b20:	07aa                	slli	a5,a5,0xa
    80001b22:	0009b703          	ld	a4,0(s3) # fffffffffffff000 <end+0xffffffff7ffd9000>
    80001b26:	3ff77713          	andi	a4,a4,1023
    80001b2a:	8fd9                	or	a5,a5,a4
    80001b2c:	0017e793          	ori	a5,a5,1
    80001b30:	00f9b023          	sd	a5,0(s3)

  // write to the page
  va = PGROUNDDOWN(va);
  struct file *fp = p->file;
    80001b34:	0184b983          	ld	s3,24(s1) # 2000018 <_entry-0x7dffffe8>
  ilock(fp->ip);
    80001b38:	0189b503          	ld	a0,24(s3)
    80001b3c:	00002097          	auipc	ra,0x2
    80001b40:	482080e7          	jalr	1154(ra) # 80003fbe <ilock>
  va = PGROUNDDOWN(va);
    80001b44:	76fd                	lui	a3,0xfffff
    80001b46:	00d97933          	and	s2,s2,a3
  readi(fp->ip, 0, (uint64)pa, va - p->start + p->offset, PGSIZE);
    80001b4a:	7494                	ld	a3,40(s1)
    80001b4c:	00d9093b          	addw	s2,s2,a3
    80001b50:	6094                	ld	a3,0(s1)
    80001b52:	6705                	lui	a4,0x1
    80001b54:	40d906bb          	subw	a3,s2,a3
    80001b58:	8652                	mv	a2,s4
    80001b5a:	4581                	li	a1,0
    80001b5c:	0189b503          	ld	a0,24(s3)
    80001b60:	00002097          	auipc	ra,0x2
    80001b64:	712080e7          	jalr	1810(ra) # 80004272 <readi>
  iunlock(fp->ip);
    80001b68:	0189b503          	ld	a0,24(s3)
    80001b6c:	00002097          	auipc	ra,0x2
    80001b70:	514080e7          	jalr	1300(ra) # 80004080 <iunlock>

  return 0;
    80001b74:	4501                	li	a0,0
}
    80001b76:	70a2                	ld	ra,40(sp)
    80001b78:	7402                	ld	s0,32(sp)
    80001b7a:	64e2                	ld	s1,24(sp)
    80001b7c:	6942                	ld	s2,16(sp)
    80001b7e:	69a2                	ld	s3,8(sp)
    80001b80:	6a02                	ld	s4,0(sp)
    80001b82:	6145                	addi	sp,sp,48
    80001b84:	8082                	ret
    return -1;
    80001b86:	557d                	li	a0,-1
}
    80001b88:	8082                	ret
    return -1;
    80001b8a:	557d                	li	a0,-1
    80001b8c:	b7ed                	j	80001b76 <pagefault_handler+0xd0>
    return -1;
    80001b8e:	557d                	li	a0,-1
    80001b90:	b7dd                	j	80001b76 <pagefault_handler+0xd0>
    return -1;
    80001b92:	557d                	li	a0,-1
    80001b94:	b7cd                	j	80001b76 <pagefault_handler+0xd0>

0000000080001b96 <copyout>:
  while(len > 0){
    80001b96:	ced9                	beqz	a3,80001c34 <copyout+0x9e>
{
    80001b98:	715d                	addi	sp,sp,-80
    80001b9a:	e486                	sd	ra,72(sp)
    80001b9c:	e0a2                	sd	s0,64(sp)
    80001b9e:	fc26                	sd	s1,56(sp)
    80001ba0:	f84a                	sd	s2,48(sp)
    80001ba2:	f44e                	sd	s3,40(sp)
    80001ba4:	f052                	sd	s4,32(sp)
    80001ba6:	ec56                	sd	s5,24(sp)
    80001ba8:	e85a                	sd	s6,16(sp)
    80001baa:	e45e                	sd	s7,8(sp)
    80001bac:	e062                	sd	s8,0(sp)
    80001bae:	0880                	addi	s0,sp,80
    80001bb0:	8b2a                	mv	s6,a0
    80001bb2:	892e                	mv	s2,a1
    80001bb4:	8ab2                	mv	s5,a2
    80001bb6:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(dstva);
    80001bb8:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (dstva - va0);
    80001bba:	6b85                	lui	s7,0x1
    80001bbc:	a805                	j	80001bec <copyout+0x56>
    80001bbe:	412984b3          	sub	s1,s3,s2
    80001bc2:	94de                	add	s1,s1,s7
    if(n > len)
    80001bc4:	009a7363          	bgeu	s4,s1,80001bca <copyout+0x34>
    80001bc8:	84d2                	mv	s1,s4
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001bca:	41390933          	sub	s2,s2,s3
    80001bce:	0004861b          	sext.w	a2,s1
    80001bd2:	85d6                	mv	a1,s5
    80001bd4:	954a                	add	a0,a0,s2
    80001bd6:	fffff097          	auipc	ra,0xfffff
    80001bda:	29a080e7          	jalr	666(ra) # 80000e70 <memmove>
    len -= n;
    80001bde:	409a0a33          	sub	s4,s4,s1
    src += n;
    80001be2:	9aa6                	add	s5,s5,s1
    dstva = va0 + PGSIZE;
    80001be4:	01798933          	add	s2,s3,s7
  while(len > 0){
    80001be8:	020a0963          	beqz	s4,80001c1a <copyout+0x84>
    va0 = PGROUNDDOWN(dstva);
    80001bec:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001bf0:	85ce                	mv	a1,s3
    80001bf2:	855a                	mv	a0,s6
    80001bf4:	fffff097          	auipc	ra,0xfffff
    80001bf8:	5ae080e7          	jalr	1454(ra) # 800011a2 <walkaddr>
    if(pa0 == 0)
    80001bfc:	f169                	bnez	a0,80001bbe <copyout+0x28>
      if (pagefault_handler(pagetable, va0) != 0)
    80001bfe:	85ce                	mv	a1,s3
    80001c00:	855a                	mv	a0,s6
    80001c02:	00000097          	auipc	ra,0x0
    80001c06:	ea4080e7          	jalr	-348(ra) # 80001aa6 <pagefault_handler>
    80001c0a:	e51d                	bnez	a0,80001c38 <copyout+0xa2>
      pa0 = walkaddr(pagetable, va0);
    80001c0c:	85ce                	mv	a1,s3
    80001c0e:	855a                	mv	a0,s6
    80001c10:	fffff097          	auipc	ra,0xfffff
    80001c14:	592080e7          	jalr	1426(ra) # 800011a2 <walkaddr>
    80001c18:	b75d                	j	80001bbe <copyout+0x28>
  return 0;
    80001c1a:	4501                	li	a0,0
}
    80001c1c:	60a6                	ld	ra,72(sp)
    80001c1e:	6406                	ld	s0,64(sp)
    80001c20:	74e2                	ld	s1,56(sp)
    80001c22:	7942                	ld	s2,48(sp)
    80001c24:	79a2                	ld	s3,40(sp)
    80001c26:	7a02                	ld	s4,32(sp)
    80001c28:	6ae2                	ld	s5,24(sp)
    80001c2a:	6b42                	ld	s6,16(sp)
    80001c2c:	6ba2                	ld	s7,8(sp)
    80001c2e:	6c02                	ld	s8,0(sp)
    80001c30:	6161                	addi	sp,sp,80
    80001c32:	8082                	ret
  return 0;
    80001c34:	4501                	li	a0,0
}
    80001c36:	8082                	ret
        return -1;
    80001c38:	557d                	li	a0,-1
    80001c3a:	b7cd                	j	80001c1c <copyout+0x86>

0000000080001c3c <copyin>:
  while(len > 0){
    80001c3c:	ced9                	beqz	a3,80001cda <copyin+0x9e>
{
    80001c3e:	715d                	addi	sp,sp,-80
    80001c40:	e486                	sd	ra,72(sp)
    80001c42:	e0a2                	sd	s0,64(sp)
    80001c44:	fc26                	sd	s1,56(sp)
    80001c46:	f84a                	sd	s2,48(sp)
    80001c48:	f44e                	sd	s3,40(sp)
    80001c4a:	f052                	sd	s4,32(sp)
    80001c4c:	ec56                	sd	s5,24(sp)
    80001c4e:	e85a                	sd	s6,16(sp)
    80001c50:	e45e                	sd	s7,8(sp)
    80001c52:	e062                	sd	s8,0(sp)
    80001c54:	0880                	addi	s0,sp,80
    80001c56:	8b2a                	mv	s6,a0
    80001c58:	8aae                	mv	s5,a1
    80001c5a:	8932                	mv	s2,a2
    80001c5c:	8a36                	mv	s4,a3
    va0 = PGROUNDDOWN(srcva);
    80001c5e:	7c7d                	lui	s8,0xfffff
    n = PGSIZE - (srcva - va0);
    80001c60:	6b85                	lui	s7,0x1
    80001c62:	a805                	j	80001c92 <copyin+0x56>
    80001c64:	412984b3          	sub	s1,s3,s2
    80001c68:	94de                	add	s1,s1,s7
    if(n > len)
    80001c6a:	009a7363          	bgeu	s4,s1,80001c70 <copyin+0x34>
    80001c6e:	84d2                	mv	s1,s4
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001c70:	413905b3          	sub	a1,s2,s3
    80001c74:	0004861b          	sext.w	a2,s1
    80001c78:	95aa                	add	a1,a1,a0
    80001c7a:	8556                	mv	a0,s5
    80001c7c:	fffff097          	auipc	ra,0xfffff
    80001c80:	1f4080e7          	jalr	500(ra) # 80000e70 <memmove>
    len -= n;
    80001c84:	409a0a33          	sub	s4,s4,s1
    dst += n;
    80001c88:	9aa6                	add	s5,s5,s1
    srcva = va0 + PGSIZE;
    80001c8a:	01798933          	add	s2,s3,s7
  while(len > 0){
    80001c8e:	020a0963          	beqz	s4,80001cc0 <copyin+0x84>
    va0 = PGROUNDDOWN(srcva);
    80001c92:	018979b3          	and	s3,s2,s8
    pa0 = walkaddr(pagetable, va0);
    80001c96:	85ce                	mv	a1,s3
    80001c98:	855a                	mv	a0,s6
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	508080e7          	jalr	1288(ra) # 800011a2 <walkaddr>
    if(pa0 == 0)
    80001ca2:	f169                	bnez	a0,80001c64 <copyin+0x28>
      if (pagefault_handler(pagetable, va0) != 0)
    80001ca4:	85ce                	mv	a1,s3
    80001ca6:	855a                	mv	a0,s6
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	dfe080e7          	jalr	-514(ra) # 80001aa6 <pagefault_handler>
    80001cb0:	e51d                	bnez	a0,80001cde <copyin+0xa2>
      pa0 = walkaddr(pagetable, va0);
    80001cb2:	85ce                	mv	a1,s3
    80001cb4:	855a                	mv	a0,s6
    80001cb6:	fffff097          	auipc	ra,0xfffff
    80001cba:	4ec080e7          	jalr	1260(ra) # 800011a2 <walkaddr>
    80001cbe:	b75d                	j	80001c64 <copyin+0x28>
  return 0;
    80001cc0:	4501                	li	a0,0
}
    80001cc2:	60a6                	ld	ra,72(sp)
    80001cc4:	6406                	ld	s0,64(sp)
    80001cc6:	74e2                	ld	s1,56(sp)
    80001cc8:	7942                	ld	s2,48(sp)
    80001cca:	79a2                	ld	s3,40(sp)
    80001ccc:	7a02                	ld	s4,32(sp)
    80001cce:	6ae2                	ld	s5,24(sp)
    80001cd0:	6b42                	ld	s6,16(sp)
    80001cd2:	6ba2                	ld	s7,8(sp)
    80001cd4:	6c02                	ld	s8,0(sp)
    80001cd6:	6161                	addi	sp,sp,80
    80001cd8:	8082                	ret
  return 0;
    80001cda:	4501                	li	a0,0
}
    80001cdc:	8082                	ret
        return -1;
    80001cde:	557d                	li	a0,-1
    80001ce0:	b7cd                	j	80001cc2 <copyin+0x86>

0000000080001ce2 <copyinstr>:
  while(got_null == 0 && max > 0){
    80001ce2:	c2f1                	beqz	a3,80001da6 <copyinstr+0xc4>
{
    80001ce4:	715d                	addi	sp,sp,-80
    80001ce6:	e486                	sd	ra,72(sp)
    80001ce8:	e0a2                	sd	s0,64(sp)
    80001cea:	fc26                	sd	s1,56(sp)
    80001cec:	f84a                	sd	s2,48(sp)
    80001cee:	f44e                	sd	s3,40(sp)
    80001cf0:	f052                	sd	s4,32(sp)
    80001cf2:	ec56                	sd	s5,24(sp)
    80001cf4:	e85a                	sd	s6,16(sp)
    80001cf6:	e45e                	sd	s7,8(sp)
    80001cf8:	0880                	addi	s0,sp,80
    80001cfa:	89aa                	mv	s3,a0
    80001cfc:	8b2e                	mv	s6,a1
    80001cfe:	8bb2                	mv	s7,a2
    80001d00:	8ab6                	mv	s5,a3
    va0 = PGROUNDDOWN(srcva);
    80001d02:	7a7d                	lui	s4,0xfffff
    n = PGSIZE - (srcva - va0);
    80001d04:	6905                	lui	s2,0x1
    80001d06:	a0a9                	j	80001d50 <copyinstr+0x6e>
      if (pagefault_handler(pagetable, va0) != 0)
    80001d08:	85a6                	mv	a1,s1
    80001d0a:	854e                	mv	a0,s3
    80001d0c:	00000097          	auipc	ra,0x0
    80001d10:	d9a080e7          	jalr	-614(ra) # 80001aa6 <pagefault_handler>
    80001d14:	e559                	bnez	a0,80001da2 <copyinstr+0xc0>
      pa0 = walkaddr(pagetable, va0);
    80001d16:	85a6                	mv	a1,s1
    80001d18:	854e                	mv	a0,s3
    80001d1a:	fffff097          	auipc	ra,0xfffff
    80001d1e:	488080e7          	jalr	1160(ra) # 800011a2 <walkaddr>
    80001d22:	a081                	j	80001d62 <copyinstr+0x80>
        *dst = '\0';
    80001d24:	00078023          	sb	zero,0(a5)
    80001d28:	4785                	li	a5,1
  if(got_null){
    80001d2a:	0017b793          	seqz	a5,a5
    80001d2e:	40f00533          	neg	a0,a5
}
    80001d32:	60a6                	ld	ra,72(sp)
    80001d34:	6406                	ld	s0,64(sp)
    80001d36:	74e2                	ld	s1,56(sp)
    80001d38:	7942                	ld	s2,48(sp)
    80001d3a:	79a2                	ld	s3,40(sp)
    80001d3c:	7a02                	ld	s4,32(sp)
    80001d3e:	6ae2                	ld	s5,24(sp)
    80001d40:	6b42                	ld	s6,16(sp)
    80001d42:	6ba2                	ld	s7,8(sp)
    80001d44:	6161                	addi	sp,sp,80
    80001d46:	8082                	ret
    srcva = va0 + PGSIZE;
    80001d48:	01248bb3          	add	s7,s1,s2
  while(got_null == 0 && max > 0){
    80001d4c:	040a8963          	beqz	s5,80001d9e <copyinstr+0xbc>
    va0 = PGROUNDDOWN(srcva);
    80001d50:	014bf4b3          	and	s1,s7,s4
    pa0 = walkaddr(pagetable, va0);
    80001d54:	85a6                	mv	a1,s1
    80001d56:	854e                	mv	a0,s3
    80001d58:	fffff097          	auipc	ra,0xfffff
    80001d5c:	44a080e7          	jalr	1098(ra) # 800011a2 <walkaddr>
    if(pa0 == 0)
    80001d60:	d545                	beqz	a0,80001d08 <copyinstr+0x26>
    n = PGSIZE - (srcva - va0);
    80001d62:	41748633          	sub	a2,s1,s7
    80001d66:	964a                	add	a2,a2,s2
    if(n > max)
    80001d68:	00caf363          	bgeu	s5,a2,80001d6e <copyinstr+0x8c>
    80001d6c:	8656                	mv	a2,s5
    char *p = (char *) (pa0 + (srcva - va0));
    80001d6e:	409b8bb3          	sub	s7,s7,s1
    80001d72:	9baa                	add	s7,s7,a0
    while(n > 0){
    80001d74:	da71                	beqz	a2,80001d48 <copyinstr+0x66>
    80001d76:	965a                	add	a2,a2,s6
    80001d78:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001d7a:	416b8833          	sub	a6,s7,s6
    80001d7e:	1afd                	addi	s5,s5,-1
    80001d80:	9b56                	add	s6,s6,s5
    80001d82:	00f80733          	add	a4,a6,a5
    80001d86:	00074703          	lbu	a4,0(a4) # 1000 <_entry-0x7ffff000>
    80001d8a:	df49                	beqz	a4,80001d24 <copyinstr+0x42>
        *dst = *p;
    80001d8c:	00e78023          	sb	a4,0(a5)
      --max;
    80001d90:	40fb0ab3          	sub	s5,s6,a5
      dst++;
    80001d94:	0785                	addi	a5,a5,1
    while(n > 0){
    80001d96:	fec796e3          	bne	a5,a2,80001d82 <copyinstr+0xa0>
      dst++;
    80001d9a:	8b32                	mv	s6,a2
    80001d9c:	b775                	j	80001d48 <copyinstr+0x66>
    80001d9e:	4781                	li	a5,0
    80001da0:	b769                	j	80001d2a <copyinstr+0x48>
        return -1;
    80001da2:	557d                	li	a0,-1
    80001da4:	b779                	j	80001d32 <copyinstr+0x50>
  int got_null = 0;
    80001da6:	4781                	li	a5,0
  if(got_null){
    80001da8:	0017b793          	seqz	a5,a5
    80001dac:	40f00533          	neg	a0,a5
}
    80001db0:	8082                	ret

0000000080001db2 <writeback>:

void
writeback(struct vma* vma, uint64 addr, uint64 n)
{
    80001db2:	711d                	addi	sp,sp,-96
    80001db4:	ec86                	sd	ra,88(sp)
    80001db6:	e8a2                	sd	s0,80(sp)
    80001db8:	e4a6                	sd	s1,72(sp)
    80001dba:	e0ca                	sd	s2,64(sp)
    80001dbc:	fc4e                	sd	s3,56(sp)
    80001dbe:	f852                	sd	s4,48(sp)
    80001dc0:	f456                	sd	s5,40(sp)
    80001dc2:	f05a                	sd	s6,32(sp)
    80001dc4:	ec5e                	sd	s7,24(sp)
    80001dc6:	e862                	sd	s8,16(sp)
    80001dc8:	e466                	sd	s9,8(sp)
    80001dca:	1080                	addi	s0,sp,96
    80001dcc:	89aa                	mv	s3,a0
    80001dce:	84ae                	mv	s1,a1
    80001dd0:	8a32                	mv	s4,a2
  // we can only write a maximum of 3 * BSIZE once at a time, and PGSIZE = 4 * BSIZE
  printf("writeback: addr=%p, length=%d\n", addr, n);
    80001dd2:	00006517          	auipc	a0,0x6
    80001dd6:	3ee50513          	addi	a0,a0,1006 # 800081c0 <digits+0x180>
    80001dda:	ffffe097          	auipc	ra,0xffffe
    80001dde:	7a0080e7          	jalr	1952(ra) # 8000057a <printf>
  pte_t *pte;
  uint64 va;
  struct file *fp = vma->file;
    80001de2:	0189b903          	ld	s2,24(s3)
  pagetable_t pagetable = myproc()->pagetable;
    80001de6:	00000097          	auipc	ra,0x0
    80001dea:	3f0080e7          	jalr	1008(ra) # 800021d6 <myproc>
    80001dee:	05053b03          	ld	s6,80(a0)

  for (va = addr; va < addr + n; va += PGSIZE)
    80001df2:	9a26                	add	s4,s4,s1
    80001df4:	0d44f563          	bgeu	s1,s4,80001ebe <writeback+0x10c>
    if (*pte & PTE_D)
    {
      // need to write back entire page
      begin_op();
      ilock(fp->ip);
      writei(fp->ip, 1, va, vma->offset + va - vma->start, PGSIZE / 2);
    80001df8:	6a85                	lui	s5,0x1
    80001dfa:	800a8b93          	addi	s7,s5,-2048 # 800 <_entry-0x7ffff800>
      iunlock(fp->ip);
      end_op();
      begin_op();
      ilock(fp->ip);
      writei(fp->ip, 1, va + PGSIZE / 2, vma->offset + va + PGSIZE / 2 - vma->start, PGSIZE / 2);
    80001dfe:	6c05                	lui	s8,0x1
    80001e00:	800c0c1b          	addiw	s8,s8,-2048
    80001e04:	a04d                	j	80001ea6 <writeback+0xf4>
      begin_op();
    80001e06:	00003097          	auipc	ra,0x3
    80001e0a:	b8a080e7          	jalr	-1142(ra) # 80004990 <begin_op>
      ilock(fp->ip);
    80001e0e:	01893503          	ld	a0,24(s2) # 1018 <_entry-0x7fffefe8>
    80001e12:	00002097          	auipc	ra,0x2
    80001e16:	1ac080e7          	jalr	428(ra) # 80003fbe <ilock>
      writei(fp->ip, 1, va, vma->offset + va - vma->start, PGSIZE / 2);
    80001e1a:	00048c9b          	sext.w	s9,s1
    80001e1e:	0289b683          	ld	a3,40(s3)
    80001e22:	0009b783          	ld	a5,0(s3)
    80001e26:	9e9d                	subw	a3,a3,a5
    80001e28:	875e                	mv	a4,s7
    80001e2a:	9ea5                	addw	a3,a3,s1
    80001e2c:	8626                	mv	a2,s1
    80001e2e:	4585                	li	a1,1
    80001e30:	01893503          	ld	a0,24(s2)
    80001e34:	00002097          	auipc	ra,0x2
    80001e38:	536080e7          	jalr	1334(ra) # 8000436a <writei>
      iunlock(fp->ip);
    80001e3c:	01893503          	ld	a0,24(s2)
    80001e40:	00002097          	auipc	ra,0x2
    80001e44:	240080e7          	jalr	576(ra) # 80004080 <iunlock>
      end_op();
    80001e48:	00003097          	auipc	ra,0x3
    80001e4c:	bc8080e7          	jalr	-1080(ra) # 80004a10 <end_op>
      begin_op();
    80001e50:	00003097          	auipc	ra,0x3
    80001e54:	b40080e7          	jalr	-1216(ra) # 80004990 <begin_op>
      ilock(fp->ip);
    80001e58:	01893503          	ld	a0,24(s2)
    80001e5c:	00002097          	auipc	ra,0x2
    80001e60:	162080e7          	jalr	354(ra) # 80003fbe <ilock>
      writei(fp->ip, 1, va + PGSIZE / 2, vma->offset + va + PGSIZE / 2 - vma->start, PGSIZE / 2);
    80001e64:	0289b783          	ld	a5,40(s3)
    80001e68:	018787bb          	addw	a5,a5,s8
    80001e6c:	0009b683          	ld	a3,0(s3)
    80001e70:	40d786bb          	subw	a3,a5,a3
    80001e74:	875e                	mv	a4,s7
    80001e76:	019686bb          	addw	a3,a3,s9
    80001e7a:	01748633          	add	a2,s1,s7
    80001e7e:	4585                	li	a1,1
    80001e80:	01893503          	ld	a0,24(s2)
    80001e84:	00002097          	auipc	ra,0x2
    80001e88:	4e6080e7          	jalr	1254(ra) # 8000436a <writei>
      iunlock(fp->ip);
    80001e8c:	01893503          	ld	a0,24(s2)
    80001e90:	00002097          	auipc	ra,0x2
    80001e94:	1f0080e7          	jalr	496(ra) # 80004080 <iunlock>
      end_op();
    80001e98:	00003097          	auipc	ra,0x3
    80001e9c:	b78080e7          	jalr	-1160(ra) # 80004a10 <end_op>
  for (va = addr; va < addr + n; va += PGSIZE)
    80001ea0:	94d6                	add	s1,s1,s5
    80001ea2:	0144fe63          	bgeu	s1,s4,80001ebe <writeback+0x10c>
    pte = walk(pagetable, va, 0);
    80001ea6:	4601                	li	a2,0
    80001ea8:	85a6                	mv	a1,s1
    80001eaa:	855a                	mv	a0,s6
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	250080e7          	jalr	592(ra) # 800010fc <walk>
    if (*pte & PTE_D)
    80001eb4:	611c                	ld	a5,0(a0)
    80001eb6:	0807f793          	andi	a5,a5,128
    80001eba:	d3fd                	beqz	a5,80001ea0 <writeback+0xee>
    80001ebc:	b7a9                	j	80001e06 <writeback+0x54>
    }
  }
    80001ebe:	60e6                	ld	ra,88(sp)
    80001ec0:	6446                	ld	s0,80(sp)
    80001ec2:	64a6                	ld	s1,72(sp)
    80001ec4:	6906                	ld	s2,64(sp)
    80001ec6:	79e2                	ld	s3,56(sp)
    80001ec8:	7a42                	ld	s4,48(sp)
    80001eca:	7aa2                	ld	s5,40(sp)
    80001ecc:	7b02                	ld	s6,32(sp)
    80001ece:	6be2                	ld	s7,24(sp)
    80001ed0:	6c42                	ld	s8,16(sp)
    80001ed2:	6ca2                	ld	s9,8(sp)
    80001ed4:	6125                	addi	sp,sp,96
    80001ed6:	8082                	ret

0000000080001ed8 <sys_munmap>:
{
    80001ed8:	7139                	addi	sp,sp,-64
    80001eda:	fc06                	sd	ra,56(sp)
    80001edc:	f822                	sd	s0,48(sp)
    80001ede:	f426                	sd	s1,40(sp)
    80001ee0:	f04a                	sd	s2,32(sp)
    80001ee2:	ec4e                	sd	s3,24(sp)
    80001ee4:	0080                	addi	s0,sp,64
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80001ee6:	fc840593          	addi	a1,s0,-56
    80001eea:	4501                	li	a0,0
    80001eec:	00001097          	auipc	ra,0x1
    80001ef0:	582080e7          	jalr	1410(ra) # 8000346e <argaddr>
    return -1;
    80001ef4:	597d                	li	s2,-1
  if (argaddr(0, &addr) < 0 || argint(1, &length) < 0)
    80001ef6:	02054563          	bltz	a0,80001f20 <sys_munmap+0x48>
    80001efa:	fc440593          	addi	a1,s0,-60
    80001efe:	4505                	li	a0,1
    80001f00:	00001097          	auipc	ra,0x1
    80001f04:	54c080e7          	jalr	1356(ra) # 8000344c <argint>
    80001f08:	12054463          	bltz	a0,80002030 <sys_munmap+0x158>
  if (PGROUNDDOWN(addr) != addr || PGROUNDDOWN(length) != length)
    80001f0c:	fc843783          	ld	a5,-56(s0)
    80001f10:	03479713          	slli	a4,a5,0x34
    80001f14:	e711                	bnez	a4,80001f20 <sys_munmap+0x48>
    80001f16:	fc442783          	lw	a5,-60(s0)
    80001f1a:	03479713          	slli	a4,a5,0x34
    80001f1e:	cb09                	beqz	a4,80001f30 <sys_munmap+0x58>
}
    80001f20:	854a                	mv	a0,s2
    80001f22:	70e2                	ld	ra,56(sp)
    80001f24:	7442                	ld	s0,48(sp)
    80001f26:	74a2                	ld	s1,40(sp)
    80001f28:	7902                	ld	s2,32(sp)
    80001f2a:	69e2                	ld	s3,24(sp)
    80001f2c:	6121                	addi	sp,sp,64
    80001f2e:	8082                	ret
  struct vma *vma = myproc()->vma, *prev = 0;
    80001f30:	00000097          	auipc	ra,0x0
    80001f34:	2a6080e7          	jalr	678(ra) # 800021d6 <myproc>
    80001f38:	16853483          	ld	s1,360(a0)
  for (; vma != 0; vma = vma->next)
    80001f3c:	cce5                	beqz	s1,80002034 <sys_munmap+0x15c>
    if (addr >= vma->start && addr < vma->end)
    80001f3e:	fc843583          	ld	a1,-56(s0)
  struct vma *vma = myproc()->vma, *prev = 0;
    80001f42:	4981                	li	s3,0
    80001f44:	a029                	j	80001f4e <sys_munmap+0x76>
  for (; vma != 0; vma = vma->next)
    80001f46:	7c9c                	ld	a5,56(s1)
    80001f48:	89a6                	mv	s3,s1
    80001f4a:	cfb5                	beqz	a5,80001fc6 <sys_munmap+0xee>
    80001f4c:	84be                	mv	s1,a5
    if (addr >= vma->start && addr < vma->end)
    80001f4e:	609c                	ld	a5,0(s1)
    80001f50:	fef5ebe3          	bltu	a1,a5,80001f46 <sys_munmap+0x6e>
    80001f54:	6498                	ld	a4,8(s1)
    80001f56:	fee5f8e3          	bgeu	a1,a4,80001f46 <sys_munmap+0x6e>
  if (addr != vma->start && addr + length != vma->end)
    80001f5a:	00b78863          	beq	a5,a1,80001f6a <sys_munmap+0x92>
    80001f5e:	fc442783          	lw	a5,-60(s0)
    80001f62:	97ae                	add	a5,a5,a1
    return -1;
    80001f64:	597d                	li	s2,-1
  if (addr != vma->start && addr + length != vma->end)
    80001f66:	faf71de3          	bne	a4,a5,80001f20 <sys_munmap+0x48>
  if ((vma->prot & PROT_WRITE) && vma->flags == MAP_SHARED)
    80001f6a:	489c                	lw	a5,16(s1)
    80001f6c:	8b89                	andi	a5,a5,2
    80001f6e:	c789                	beqz	a5,80001f78 <sys_munmap+0xa0>
    80001f70:	5898                	lw	a4,48(s1)
    80001f72:	4785                	li	a5,1
    80001f74:	04f70b63          	beq	a4,a5,80001fca <sys_munmap+0xf2>
  uvmunmap(myproc()->pagetable, addr, length / PGSIZE, 1);
    80001f78:	00000097          	auipc	ra,0x0
    80001f7c:	25e080e7          	jalr	606(ra) # 800021d6 <myproc>
    80001f80:	fc442783          	lw	a5,-60(s0)
    80001f84:	41f7d61b          	sraiw	a2,a5,0x1f
    80001f88:	0146561b          	srliw	a2,a2,0x14
    80001f8c:	9e3d                	addw	a2,a2,a5
    80001f8e:	4685                	li	a3,1
    80001f90:	40c6561b          	sraiw	a2,a2,0xc
    80001f94:	fc843583          	ld	a1,-56(s0)
    80001f98:	6928                	ld	a0,80(a0)
    80001f9a:	fffff097          	auipc	ra,0xfffff
    80001f9e:	3fe080e7          	jalr	1022(ra) # 80001398 <uvmunmap>
  if (addr == vma->start)
    80001fa2:	fc843783          	ld	a5,-56(s0)
    80001fa6:	6098                	ld	a4,0(s1)
    80001fa8:	02f70963          	beq	a4,a5,80001fda <sys_munmap+0x102>
  else if (addr + length == vma->end)
    80001fac:	fc442703          	lw	a4,-60(s0)
    80001fb0:	00e78633          	add	a2,a5,a4
    80001fb4:	6494                	ld	a3,8(s1)
    80001fb6:	02d60f63          	beq	a2,a3,80001ff4 <sys_munmap+0x11c>
  if (vma->length == 0)
    80001fba:	0204b903          	ld	s2,32(s1)
    80001fbe:	04090163          	beqz	s2,80002000 <sys_munmap+0x128>
  return 0;
    80001fc2:	4901                	li	s2,0
    80001fc4:	bfb1                	j	80001f20 <sys_munmap+0x48>
    return -1;
    80001fc6:	597d                	li	s2,-1
    80001fc8:	bfa1                	j	80001f20 <sys_munmap+0x48>
    writeback(vma, addr, length);
    80001fca:	fc442603          	lw	a2,-60(s0)
    80001fce:	8526                	mv	a0,s1
    80001fd0:	00000097          	auipc	ra,0x0
    80001fd4:	de2080e7          	jalr	-542(ra) # 80001db2 <writeback>
    80001fd8:	b745                	j	80001f78 <sys_munmap+0xa0>
    vma->start = addr + length;
    80001fda:	fc442703          	lw	a4,-60(s0)
    80001fde:	97ba                	add	a5,a5,a4
    80001fe0:	e09c                	sd	a5,0(s1)
    vma->offset += length;
    80001fe2:	fc442683          	lw	a3,-60(s0)
    80001fe6:	7498                	ld	a4,40(s1)
    80001fe8:	9736                	add	a4,a4,a3
    80001fea:	f498                	sd	a4,40(s1)
    vma->length -= length;
    80001fec:	709c                	ld	a5,32(s1)
    80001fee:	8f95                	sub	a5,a5,a3
    80001ff0:	f09c                	sd	a5,32(s1)
    80001ff2:	b7e1                	j	80001fba <sys_munmap+0xe2>
    vma->end = addr;
    80001ff4:	e49c                	sd	a5,8(s1)
    vma->length -= length;
    80001ff6:	709c                	ld	a5,32(s1)
    80001ff8:	40e78733          	sub	a4,a5,a4
    80001ffc:	f098                	sd	a4,32(s1)
    80001ffe:	bf75                	j	80001fba <sys_munmap+0xe2>
    fileclose(vma->file);
    80002000:	6c88                	ld	a0,24(s1)
    80002002:	00003097          	auipc	ra,0x3
    80002006:	e62080e7          	jalr	-414(ra) # 80004e64 <fileclose>
    if (prev == 0)
    8000200a:	00098b63          	beqz	s3,80002020 <sys_munmap+0x148>
      prev->next = vma->next;
    8000200e:	7c9c                	ld	a5,56(s1)
    80002010:	02f9bc23          	sd	a5,56(s3)
    kvma_free(vma);
    80002014:	8526                	mv	a0,s1
    80002016:	fffff097          	auipc	ra,0xfffff
    8000201a:	af4080e7          	jalr	-1292(ra) # 80000b0a <kvma_free>
    8000201e:	b709                	j	80001f20 <sys_munmap+0x48>
      myproc()->vma = vma->next;
    80002020:	00000097          	auipc	ra,0x0
    80002024:	1b6080e7          	jalr	438(ra) # 800021d6 <myproc>
    80002028:	7c9c                	ld	a5,56(s1)
    8000202a:	16f53423          	sd	a5,360(a0)
    8000202e:	b7dd                	j	80002014 <sys_munmap+0x13c>
    return -1;
    80002030:	597d                	li	s2,-1
    80002032:	b5fd                	j	80001f20 <sys_munmap+0x48>
    return -1;
    80002034:	597d                	li	s2,-1
    80002036:	b5ed                	j	80001f20 <sys_munmap+0x48>

0000000080002038 <wakeup1>:

// Wake up p if it is sleeping in wait(); used by exit().
// Caller must hold p->lock.
static void
wakeup1(struct proc *p)
{
    80002038:	1101                	addi	sp,sp,-32
    8000203a:	ec06                	sd	ra,24(sp)
    8000203c:	e822                	sd	s0,16(sp)
    8000203e:	e426                	sd	s1,8(sp)
    80002040:	1000                	addi	s0,sp,32
    80002042:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002044:	fffff097          	auipc	ra,0xfffff
    80002048:	c56080e7          	jalr	-938(ra) # 80000c9a <holding>
    8000204c:	c909                	beqz	a0,8000205e <wakeup1+0x26>
    panic("wakeup1");
  if(p->chan == p && p->state == SLEEPING) {
    8000204e:	749c                	ld	a5,40(s1)
    80002050:	00978f63          	beq	a5,s1,8000206e <wakeup1+0x36>
    p->state = RUNNABLE;
  }
}
    80002054:	60e2                	ld	ra,24(sp)
    80002056:	6442                	ld	s0,16(sp)
    80002058:	64a2                	ld	s1,8(sp)
    8000205a:	6105                	addi	sp,sp,32
    8000205c:	8082                	ret
    panic("wakeup1");
    8000205e:	00006517          	auipc	a0,0x6
    80002062:	18250513          	addi	a0,a0,386 # 800081e0 <digits+0x1a0>
    80002066:	ffffe097          	auipc	ra,0xffffe
    8000206a:	4ca080e7          	jalr	1226(ra) # 80000530 <panic>
  if(p->chan == p && p->state == SLEEPING) {
    8000206e:	4c98                	lw	a4,24(s1)
    80002070:	4785                	li	a5,1
    80002072:	fef711e3          	bne	a4,a5,80002054 <wakeup1+0x1c>
    p->state = RUNNABLE;
    80002076:	4789                	li	a5,2
    80002078:	cc9c                	sw	a5,24(s1)
}
    8000207a:	bfe9                	j	80002054 <wakeup1+0x1c>

000000008000207c <proc_mapstacks>:
proc_mapstacks(pagetable_t kpgtbl) {
    8000207c:	7139                	addi	sp,sp,-64
    8000207e:	fc06                	sd	ra,56(sp)
    80002080:	f822                	sd	s0,48(sp)
    80002082:	f426                	sd	s1,40(sp)
    80002084:	f04a                	sd	s2,32(sp)
    80002086:	ec4e                	sd	s3,24(sp)
    80002088:	e852                	sd	s4,16(sp)
    8000208a:	e456                	sd	s5,8(sp)
    8000208c:	e05a                	sd	s6,0(sp)
    8000208e:	0080                	addi	s0,sp,64
    80002090:	89aa                	mv	s3,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002092:	0000f497          	auipc	s1,0xf
    80002096:	64648493          	addi	s1,s1,1606 # 800116d8 <proc>
    uint64 va = KSTACK((int) (p - proc));
    8000209a:	8b26                	mv	s6,s1
    8000209c:	00006a97          	auipc	s5,0x6
    800020a0:	f64a8a93          	addi	s5,s5,-156 # 80008000 <etext>
    800020a4:	04000937          	lui	s2,0x4000
    800020a8:	197d                	addi	s2,s2,-1
    800020aa:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800020ac:	00015a17          	auipc	s4,0x15
    800020b0:	22ca0a13          	addi	s4,s4,556 # 800172d8 <tickslock>
    char *pa = kalloc();
    800020b4:	fffff097          	auipc	ra,0xfffff
    800020b8:	9f6080e7          	jalr	-1546(ra) # 80000aaa <kalloc>
    800020bc:	862a                	mv	a2,a0
    if(pa == 0)
    800020be:	c131                	beqz	a0,80002102 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800020c0:	416485b3          	sub	a1,s1,s6
    800020c4:	8591                	srai	a1,a1,0x4
    800020c6:	000ab783          	ld	a5,0(s5)
    800020ca:	02f585b3          	mul	a1,a1,a5
    800020ce:	2585                	addiw	a1,a1,1
    800020d0:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800020d4:	4719                	li	a4,6
    800020d6:	6685                	lui	a3,0x1
    800020d8:	40b905b3          	sub	a1,s2,a1
    800020dc:	854e                	mv	a0,s3
    800020de:	fffff097          	auipc	ra,0xfffff
    800020e2:	194080e7          	jalr	404(ra) # 80001272 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800020e6:	17048493          	addi	s1,s1,368
    800020ea:	fd4495e3          	bne	s1,s4,800020b4 <proc_mapstacks+0x38>
}
    800020ee:	70e2                	ld	ra,56(sp)
    800020f0:	7442                	ld	s0,48(sp)
    800020f2:	74a2                	ld	s1,40(sp)
    800020f4:	7902                	ld	s2,32(sp)
    800020f6:	69e2                	ld	s3,24(sp)
    800020f8:	6a42                	ld	s4,16(sp)
    800020fa:	6aa2                	ld	s5,8(sp)
    800020fc:	6b02                	ld	s6,0(sp)
    800020fe:	6121                	addi	sp,sp,64
    80002100:	8082                	ret
      panic("kalloc");
    80002102:	00006517          	auipc	a0,0x6
    80002106:	0e650513          	addi	a0,a0,230 # 800081e8 <digits+0x1a8>
    8000210a:	ffffe097          	auipc	ra,0xffffe
    8000210e:	426080e7          	jalr	1062(ra) # 80000530 <panic>

0000000080002112 <procinit>:
{
    80002112:	7139                	addi	sp,sp,-64
    80002114:	fc06                	sd	ra,56(sp)
    80002116:	f822                	sd	s0,48(sp)
    80002118:	f426                	sd	s1,40(sp)
    8000211a:	f04a                	sd	s2,32(sp)
    8000211c:	ec4e                	sd	s3,24(sp)
    8000211e:	e852                	sd	s4,16(sp)
    80002120:	e456                	sd	s5,8(sp)
    80002122:	e05a                	sd	s6,0(sp)
    80002124:	0080                	addi	s0,sp,64
  initlock(&pid_lock, "nextpid");
    80002126:	00006597          	auipc	a1,0x6
    8000212a:	0ca58593          	addi	a1,a1,202 # 800081f0 <digits+0x1b0>
    8000212e:	0000f517          	auipc	a0,0xf
    80002132:	19250513          	addi	a0,a0,402 # 800112c0 <pid_lock>
    80002136:	fffff097          	auipc	ra,0xfffff
    8000213a:	b4e080e7          	jalr	-1202(ra) # 80000c84 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000213e:	0000f497          	auipc	s1,0xf
    80002142:	59a48493          	addi	s1,s1,1434 # 800116d8 <proc>
      initlock(&p->lock, "proc");
    80002146:	00006b17          	auipc	s6,0x6
    8000214a:	0b2b0b13          	addi	s6,s6,178 # 800081f8 <digits+0x1b8>
      p->kstack = KSTACK((int) (p - proc));
    8000214e:	8aa6                	mv	s5,s1
    80002150:	00006a17          	auipc	s4,0x6
    80002154:	eb0a0a13          	addi	s4,s4,-336 # 80008000 <etext>
    80002158:	04000937          	lui	s2,0x4000
    8000215c:	197d                	addi	s2,s2,-1
    8000215e:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80002160:	00015997          	auipc	s3,0x15
    80002164:	17898993          	addi	s3,s3,376 # 800172d8 <tickslock>
      initlock(&p->lock, "proc");
    80002168:	85da                	mv	a1,s6
    8000216a:	8526                	mv	a0,s1
    8000216c:	fffff097          	auipc	ra,0xfffff
    80002170:	b18080e7          	jalr	-1256(ra) # 80000c84 <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80002174:	415487b3          	sub	a5,s1,s5
    80002178:	8791                	srai	a5,a5,0x4
    8000217a:	000a3703          	ld	a4,0(s4)
    8000217e:	02e787b3          	mul	a5,a5,a4
    80002182:	2785                	addiw	a5,a5,1
    80002184:	00d7979b          	slliw	a5,a5,0xd
    80002188:	40f907b3          	sub	a5,s2,a5
    8000218c:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    8000218e:	17048493          	addi	s1,s1,368
    80002192:	fd349be3          	bne	s1,s3,80002168 <procinit+0x56>
}
    80002196:	70e2                	ld	ra,56(sp)
    80002198:	7442                	ld	s0,48(sp)
    8000219a:	74a2                	ld	s1,40(sp)
    8000219c:	7902                	ld	s2,32(sp)
    8000219e:	69e2                	ld	s3,24(sp)
    800021a0:	6a42                	ld	s4,16(sp)
    800021a2:	6aa2                	ld	s5,8(sp)
    800021a4:	6b02                	ld	s6,0(sp)
    800021a6:	6121                	addi	sp,sp,64
    800021a8:	8082                	ret

00000000800021aa <cpuid>:
{
    800021aa:	1141                	addi	sp,sp,-16
    800021ac:	e422                	sd	s0,8(sp)
    800021ae:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800021b0:	8512                	mv	a0,tp
}
    800021b2:	2501                	sext.w	a0,a0
    800021b4:	6422                	ld	s0,8(sp)
    800021b6:	0141                	addi	sp,sp,16
    800021b8:	8082                	ret

00000000800021ba <mycpu>:
mycpu(void) {
    800021ba:	1141                	addi	sp,sp,-16
    800021bc:	e422                	sd	s0,8(sp)
    800021be:	0800                	addi	s0,sp,16
    800021c0:	8792                	mv	a5,tp
  struct cpu *c = &cpus[id];
    800021c2:	2781                	sext.w	a5,a5
    800021c4:	079e                	slli	a5,a5,0x7
}
    800021c6:	0000f517          	auipc	a0,0xf
    800021ca:	11250513          	addi	a0,a0,274 # 800112d8 <cpus>
    800021ce:	953e                	add	a0,a0,a5
    800021d0:	6422                	ld	s0,8(sp)
    800021d2:	0141                	addi	sp,sp,16
    800021d4:	8082                	ret

00000000800021d6 <myproc>:
myproc(void) {
    800021d6:	1101                	addi	sp,sp,-32
    800021d8:	ec06                	sd	ra,24(sp)
    800021da:	e822                	sd	s0,16(sp)
    800021dc:	e426                	sd	s1,8(sp)
    800021de:	1000                	addi	s0,sp,32
  push_off();
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	ae8080e7          	jalr	-1304(ra) # 80000cc8 <push_off>
    800021e8:	8792                	mv	a5,tp
  struct proc *p = c->proc;
    800021ea:	2781                	sext.w	a5,a5
    800021ec:	079e                	slli	a5,a5,0x7
    800021ee:	0000f717          	auipc	a4,0xf
    800021f2:	0d270713          	addi	a4,a4,210 # 800112c0 <pid_lock>
    800021f6:	97ba                	add	a5,a5,a4
    800021f8:	6f84                	ld	s1,24(a5)
  pop_off();
    800021fa:	fffff097          	auipc	ra,0xfffff
    800021fe:	b6e080e7          	jalr	-1170(ra) # 80000d68 <pop_off>
}
    80002202:	8526                	mv	a0,s1
    80002204:	60e2                	ld	ra,24(sp)
    80002206:	6442                	ld	s0,16(sp)
    80002208:	64a2                	ld	s1,8(sp)
    8000220a:	6105                	addi	sp,sp,32
    8000220c:	8082                	ret

000000008000220e <forkret>:
{
    8000220e:	1141                	addi	sp,sp,-16
    80002210:	e406                	sd	ra,8(sp)
    80002212:	e022                	sd	s0,0(sp)
    80002214:	0800                	addi	s0,sp,16
  release(&myproc()->lock);
    80002216:	00000097          	auipc	ra,0x0
    8000221a:	fc0080e7          	jalr	-64(ra) # 800021d6 <myproc>
    8000221e:	fffff097          	auipc	ra,0xfffff
    80002222:	baa080e7          	jalr	-1110(ra) # 80000dc8 <release>
  if (first) {
    80002226:	00006797          	auipc	a5,0x6
    8000222a:	5fa7a783          	lw	a5,1530(a5) # 80008820 <first.1702>
    8000222e:	eb89                	bnez	a5,80002240 <forkret+0x32>
  usertrapret();
    80002230:	00001097          	auipc	ra,0x1
    80002234:	d6e080e7          	jalr	-658(ra) # 80002f9e <usertrapret>
}
    80002238:	60a2                	ld	ra,8(sp)
    8000223a:	6402                	ld	s0,0(sp)
    8000223c:	0141                	addi	sp,sp,16
    8000223e:	8082                	ret
    first = 0;
    80002240:	00006797          	auipc	a5,0x6
    80002244:	5e07a023          	sw	zero,1504(a5) # 80008820 <first.1702>
    fsinit(ROOTDEV);
    80002248:	4505                	li	a0,1
    8000224a:	00002097          	auipc	ra,0x2
    8000224e:	afc080e7          	jalr	-1284(ra) # 80003d46 <fsinit>
    80002252:	bff9                	j	80002230 <forkret+0x22>

0000000080002254 <allocpid>:
allocpid() {
    80002254:	1101                	addi	sp,sp,-32
    80002256:	ec06                	sd	ra,24(sp)
    80002258:	e822                	sd	s0,16(sp)
    8000225a:	e426                	sd	s1,8(sp)
    8000225c:	e04a                	sd	s2,0(sp)
    8000225e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80002260:	0000f917          	auipc	s2,0xf
    80002264:	06090913          	addi	s2,s2,96 # 800112c0 <pid_lock>
    80002268:	854a                	mv	a0,s2
    8000226a:	fffff097          	auipc	ra,0xfffff
    8000226e:	aaa080e7          	jalr	-1366(ra) # 80000d14 <acquire>
  pid = nextpid;
    80002272:	00006797          	auipc	a5,0x6
    80002276:	5b278793          	addi	a5,a5,1458 # 80008824 <nextpid>
    8000227a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    8000227c:	0014871b          	addiw	a4,s1,1
    80002280:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80002282:	854a                	mv	a0,s2
    80002284:	fffff097          	auipc	ra,0xfffff
    80002288:	b44080e7          	jalr	-1212(ra) # 80000dc8 <release>
}
    8000228c:	8526                	mv	a0,s1
    8000228e:	60e2                	ld	ra,24(sp)
    80002290:	6442                	ld	s0,16(sp)
    80002292:	64a2                	ld	s1,8(sp)
    80002294:	6902                	ld	s2,0(sp)
    80002296:	6105                	addi	sp,sp,32
    80002298:	8082                	ret

000000008000229a <proc_pagetable>:
{
    8000229a:	1101                	addi	sp,sp,-32
    8000229c:	ec06                	sd	ra,24(sp)
    8000229e:	e822                	sd	s0,16(sp)
    800022a0:	e426                	sd	s1,8(sp)
    800022a2:	e04a                	sd	s2,0(sp)
    800022a4:	1000                	addi	s0,sp,32
    800022a6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    800022a8:	fffff097          	auipc	ra,0xfffff
    800022ac:	1a6080e7          	jalr	422(ra) # 8000144e <uvmcreate>
    800022b0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800022b2:	c121                	beqz	a0,800022f2 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    800022b4:	4729                	li	a4,10
    800022b6:	00005697          	auipc	a3,0x5
    800022ba:	d4a68693          	addi	a3,a3,-694 # 80007000 <_trampoline>
    800022be:	6605                	lui	a2,0x1
    800022c0:	040005b7          	lui	a1,0x4000
    800022c4:	15fd                	addi	a1,a1,-1
    800022c6:	05b2                	slli	a1,a1,0xc
    800022c8:	fffff097          	auipc	ra,0xfffff
    800022cc:	f1c080e7          	jalr	-228(ra) # 800011e4 <mappages>
    800022d0:	02054863          	bltz	a0,80002300 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    800022d4:	4719                	li	a4,6
    800022d6:	05893683          	ld	a3,88(s2)
    800022da:	6605                	lui	a2,0x1
    800022dc:	020005b7          	lui	a1,0x2000
    800022e0:	15fd                	addi	a1,a1,-1
    800022e2:	05b6                	slli	a1,a1,0xd
    800022e4:	8526                	mv	a0,s1
    800022e6:	fffff097          	auipc	ra,0xfffff
    800022ea:	efe080e7          	jalr	-258(ra) # 800011e4 <mappages>
    800022ee:	02054163          	bltz	a0,80002310 <proc_pagetable+0x76>
}
    800022f2:	8526                	mv	a0,s1
    800022f4:	60e2                	ld	ra,24(sp)
    800022f6:	6442                	ld	s0,16(sp)
    800022f8:	64a2                	ld	s1,8(sp)
    800022fa:	6902                	ld	s2,0(sp)
    800022fc:	6105                	addi	sp,sp,32
    800022fe:	8082                	ret
    uvmfree(pagetable, 0);
    80002300:	4581                	li	a1,0
    80002302:	8526                	mv	a0,s1
    80002304:	fffff097          	auipc	ra,0xfffff
    80002308:	346080e7          	jalr	838(ra) # 8000164a <uvmfree>
    return 0;
    8000230c:	4481                	li	s1,0
    8000230e:	b7d5                	j	800022f2 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002310:	4681                	li	a3,0
    80002312:	4605                	li	a2,1
    80002314:	040005b7          	lui	a1,0x4000
    80002318:	15fd                	addi	a1,a1,-1
    8000231a:	05b2                	slli	a1,a1,0xc
    8000231c:	8526                	mv	a0,s1
    8000231e:	fffff097          	auipc	ra,0xfffff
    80002322:	07a080e7          	jalr	122(ra) # 80001398 <uvmunmap>
    uvmfree(pagetable, 0);
    80002326:	4581                	li	a1,0
    80002328:	8526                	mv	a0,s1
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	320080e7          	jalr	800(ra) # 8000164a <uvmfree>
    return 0;
    80002332:	4481                	li	s1,0
    80002334:	bf7d                	j	800022f2 <proc_pagetable+0x58>

0000000080002336 <proc_freepagetable>:
{
    80002336:	1101                	addi	sp,sp,-32
    80002338:	ec06                	sd	ra,24(sp)
    8000233a:	e822                	sd	s0,16(sp)
    8000233c:	e426                	sd	s1,8(sp)
    8000233e:	e04a                	sd	s2,0(sp)
    80002340:	1000                	addi	s0,sp,32
    80002342:	84aa                	mv	s1,a0
    80002344:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80002346:	4681                	li	a3,0
    80002348:	4605                	li	a2,1
    8000234a:	040005b7          	lui	a1,0x4000
    8000234e:	15fd                	addi	a1,a1,-1
    80002350:	05b2                	slli	a1,a1,0xc
    80002352:	fffff097          	auipc	ra,0xfffff
    80002356:	046080e7          	jalr	70(ra) # 80001398 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    8000235a:	4681                	li	a3,0
    8000235c:	4605                	li	a2,1
    8000235e:	020005b7          	lui	a1,0x2000
    80002362:	15fd                	addi	a1,a1,-1
    80002364:	05b6                	slli	a1,a1,0xd
    80002366:	8526                	mv	a0,s1
    80002368:	fffff097          	auipc	ra,0xfffff
    8000236c:	030080e7          	jalr	48(ra) # 80001398 <uvmunmap>
  uvmfree(pagetable, sz);
    80002370:	85ca                	mv	a1,s2
    80002372:	8526                	mv	a0,s1
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	2d6080e7          	jalr	726(ra) # 8000164a <uvmfree>
}
    8000237c:	60e2                	ld	ra,24(sp)
    8000237e:	6442                	ld	s0,16(sp)
    80002380:	64a2                	ld	s1,8(sp)
    80002382:	6902                	ld	s2,0(sp)
    80002384:	6105                	addi	sp,sp,32
    80002386:	8082                	ret

0000000080002388 <freeproc>:
{
    80002388:	1101                	addi	sp,sp,-32
    8000238a:	ec06                	sd	ra,24(sp)
    8000238c:	e822                	sd	s0,16(sp)
    8000238e:	e426                	sd	s1,8(sp)
    80002390:	1000                	addi	s0,sp,32
    80002392:	84aa                	mv	s1,a0
  if(p->trapframe)
    80002394:	6d28                	ld	a0,88(a0)
    80002396:	c509                	beqz	a0,800023a0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80002398:	ffffe097          	auipc	ra,0xffffe
    8000239c:	652080e7          	jalr	1618(ra) # 800009ea <kfree>
  p->trapframe = 0;
    800023a0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    800023a4:	68a8                	ld	a0,80(s1)
    800023a6:	c511                	beqz	a0,800023b2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    800023a8:	64ac                	ld	a1,72(s1)
    800023aa:	00000097          	auipc	ra,0x0
    800023ae:	f8c080e7          	jalr	-116(ra) # 80002336 <proc_freepagetable>
  p->pagetable = 0;
    800023b2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    800023b6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    800023ba:	0204ac23          	sw	zero,56(s1)
  p->parent = 0;
    800023be:	0204b023          	sd	zero,32(s1)
  p->name[0] = 0;
    800023c2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    800023c6:	0204b423          	sd	zero,40(s1)
  p->killed = 0;
    800023ca:	0204a823          	sw	zero,48(s1)
  p->xstate = 0;
    800023ce:	0204aa23          	sw	zero,52(s1)
  p->state = UNUSED;
    800023d2:	0004ac23          	sw	zero,24(s1)
}
    800023d6:	60e2                	ld	ra,24(sp)
    800023d8:	6442                	ld	s0,16(sp)
    800023da:	64a2                	ld	s1,8(sp)
    800023dc:	6105                	addi	sp,sp,32
    800023de:	8082                	ret

00000000800023e0 <allocproc>:
{
    800023e0:	1101                	addi	sp,sp,-32
    800023e2:	ec06                	sd	ra,24(sp)
    800023e4:	e822                	sd	s0,16(sp)
    800023e6:	e426                	sd	s1,8(sp)
    800023e8:	e04a                	sd	s2,0(sp)
    800023ea:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    800023ec:	0000f497          	auipc	s1,0xf
    800023f0:	2ec48493          	addi	s1,s1,748 # 800116d8 <proc>
    800023f4:	00015917          	auipc	s2,0x15
    800023f8:	ee490913          	addi	s2,s2,-284 # 800172d8 <tickslock>
    acquire(&p->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	916080e7          	jalr	-1770(ra) # 80000d14 <acquire>
    if(p->state == UNUSED) {
    80002406:	4c9c                	lw	a5,24(s1)
    80002408:	cf81                	beqz	a5,80002420 <allocproc+0x40>
      release(&p->lock);
    8000240a:	8526                	mv	a0,s1
    8000240c:	fffff097          	auipc	ra,0xfffff
    80002410:	9bc080e7          	jalr	-1604(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002414:	17048493          	addi	s1,s1,368
    80002418:	ff2492e3          	bne	s1,s2,800023fc <allocproc+0x1c>
  return 0;
    8000241c:	4481                	li	s1,0
    8000241e:	a889                	j	80002470 <allocproc+0x90>
  p->pid = allocpid();
    80002420:	00000097          	auipc	ra,0x0
    80002424:	e34080e7          	jalr	-460(ra) # 80002254 <allocpid>
    80002428:	dc88                	sw	a0,56(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    8000242a:	ffffe097          	auipc	ra,0xffffe
    8000242e:	680080e7          	jalr	1664(ra) # 80000aaa <kalloc>
    80002432:	892a                	mv	s2,a0
    80002434:	eca8                	sd	a0,88(s1)
    80002436:	c521                	beqz	a0,8000247e <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80002438:	8526                	mv	a0,s1
    8000243a:	00000097          	auipc	ra,0x0
    8000243e:	e60080e7          	jalr	-416(ra) # 8000229a <proc_pagetable>
    80002442:	892a                	mv	s2,a0
    80002444:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80002446:	c139                	beqz	a0,8000248c <allocproc+0xac>
  memset(&p->context, 0, sizeof(p->context));
    80002448:	07000613          	li	a2,112
    8000244c:	4581                	li	a1,0
    8000244e:	06048513          	addi	a0,s1,96
    80002452:	fffff097          	auipc	ra,0xfffff
    80002456:	9be080e7          	jalr	-1602(ra) # 80000e10 <memset>
  p->context.ra = (uint64)forkret;
    8000245a:	00000797          	auipc	a5,0x0
    8000245e:	db478793          	addi	a5,a5,-588 # 8000220e <forkret>
    80002462:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80002464:	60bc                	ld	a5,64(s1)
    80002466:	6705                	lui	a4,0x1
    80002468:	97ba                	add	a5,a5,a4
    8000246a:	f4bc                	sd	a5,104(s1)
  p->vma = 0;
    8000246c:	1604b423          	sd	zero,360(s1)
}
    80002470:	8526                	mv	a0,s1
    80002472:	60e2                	ld	ra,24(sp)
    80002474:	6442                	ld	s0,16(sp)
    80002476:	64a2                	ld	s1,8(sp)
    80002478:	6902                	ld	s2,0(sp)
    8000247a:	6105                	addi	sp,sp,32
    8000247c:	8082                	ret
    release(&p->lock);
    8000247e:	8526                	mv	a0,s1
    80002480:	fffff097          	auipc	ra,0xfffff
    80002484:	948080e7          	jalr	-1720(ra) # 80000dc8 <release>
    return 0;
    80002488:	84ca                	mv	s1,s2
    8000248a:	b7dd                	j	80002470 <allocproc+0x90>
    freeproc(p);
    8000248c:	8526                	mv	a0,s1
    8000248e:	00000097          	auipc	ra,0x0
    80002492:	efa080e7          	jalr	-262(ra) # 80002388 <freeproc>
    release(&p->lock);
    80002496:	8526                	mv	a0,s1
    80002498:	fffff097          	auipc	ra,0xfffff
    8000249c:	930080e7          	jalr	-1744(ra) # 80000dc8 <release>
    return 0;
    800024a0:	84ca                	mv	s1,s2
    800024a2:	b7f9                	j	80002470 <allocproc+0x90>

00000000800024a4 <userinit>:
{
    800024a4:	1101                	addi	sp,sp,-32
    800024a6:	ec06                	sd	ra,24(sp)
    800024a8:	e822                	sd	s0,16(sp)
    800024aa:	e426                	sd	s1,8(sp)
    800024ac:	1000                	addi	s0,sp,32
  p = allocproc();
    800024ae:	00000097          	auipc	ra,0x0
    800024b2:	f32080e7          	jalr	-206(ra) # 800023e0 <allocproc>
    800024b6:	84aa                	mv	s1,a0
  initproc = p;
    800024b8:	00007797          	auipc	a5,0x7
    800024bc:	b6a7b823          	sd	a0,-1168(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    800024c0:	03400613          	li	a2,52
    800024c4:	00006597          	auipc	a1,0x6
    800024c8:	36c58593          	addi	a1,a1,876 # 80008830 <initcode>
    800024cc:	6928                	ld	a0,80(a0)
    800024ce:	fffff097          	auipc	ra,0xfffff
    800024d2:	fae080e7          	jalr	-82(ra) # 8000147c <uvminit>
  p->sz = PGSIZE;
    800024d6:	6785                	lui	a5,0x1
    800024d8:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    800024da:	6cb8                	ld	a4,88(s1)
    800024dc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    800024e0:	6cb8                	ld	a4,88(s1)
    800024e2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800024e4:	4641                	li	a2,16
    800024e6:	00006597          	auipc	a1,0x6
    800024ea:	d1a58593          	addi	a1,a1,-742 # 80008200 <digits+0x1c0>
    800024ee:	15848513          	addi	a0,s1,344
    800024f2:	fffff097          	auipc	ra,0xfffff
    800024f6:	a74080e7          	jalr	-1420(ra) # 80000f66 <safestrcpy>
  p->cwd = namei("/");
    800024fa:	00006517          	auipc	a0,0x6
    800024fe:	d1650513          	addi	a0,a0,-746 # 80008210 <digits+0x1d0>
    80002502:	00002097          	auipc	ra,0x2
    80002506:	272080e7          	jalr	626(ra) # 80004774 <namei>
    8000250a:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    8000250e:	4789                	li	a5,2
    80002510:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80002512:	8526                	mv	a0,s1
    80002514:	fffff097          	auipc	ra,0xfffff
    80002518:	8b4080e7          	jalr	-1868(ra) # 80000dc8 <release>
}
    8000251c:	60e2                	ld	ra,24(sp)
    8000251e:	6442                	ld	s0,16(sp)
    80002520:	64a2                	ld	s1,8(sp)
    80002522:	6105                	addi	sp,sp,32
    80002524:	8082                	ret

0000000080002526 <growproc>:
{
    80002526:	1101                	addi	sp,sp,-32
    80002528:	ec06                	sd	ra,24(sp)
    8000252a:	e822                	sd	s0,16(sp)
    8000252c:	e426                	sd	s1,8(sp)
    8000252e:	e04a                	sd	s2,0(sp)
    80002530:	1000                	addi	s0,sp,32
    80002532:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002534:	00000097          	auipc	ra,0x0
    80002538:	ca2080e7          	jalr	-862(ra) # 800021d6 <myproc>
    8000253c:	892a                	mv	s2,a0
  sz = p->sz;
    8000253e:	652c                	ld	a1,72(a0)
    80002540:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80002544:	00904f63          	bgtz	s1,80002562 <growproc+0x3c>
  } else if(n < 0){
    80002548:	0204cc63          	bltz	s1,80002580 <growproc+0x5a>
  p->sz = sz;
    8000254c:	1602                	slli	a2,a2,0x20
    8000254e:	9201                	srli	a2,a2,0x20
    80002550:	04c93423          	sd	a2,72(s2)
  return 0;
    80002554:	4501                	li	a0,0
}
    80002556:	60e2                	ld	ra,24(sp)
    80002558:	6442                	ld	s0,16(sp)
    8000255a:	64a2                	ld	s1,8(sp)
    8000255c:	6902                	ld	s2,0(sp)
    8000255e:	6105                	addi	sp,sp,32
    80002560:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80002562:	9e25                	addw	a2,a2,s1
    80002564:	1602                	slli	a2,a2,0x20
    80002566:	9201                	srli	a2,a2,0x20
    80002568:	1582                	slli	a1,a1,0x20
    8000256a:	9181                	srli	a1,a1,0x20
    8000256c:	6928                	ld	a0,80(a0)
    8000256e:	fffff097          	auipc	ra,0xfffff
    80002572:	fc8080e7          	jalr	-56(ra) # 80001536 <uvmalloc>
    80002576:	0005061b          	sext.w	a2,a0
    8000257a:	fa69                	bnez	a2,8000254c <growproc+0x26>
      return -1;
    8000257c:	557d                	li	a0,-1
    8000257e:	bfe1                	j	80002556 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80002580:	9e25                	addw	a2,a2,s1
    80002582:	1602                	slli	a2,a2,0x20
    80002584:	9201                	srli	a2,a2,0x20
    80002586:	1582                	slli	a1,a1,0x20
    80002588:	9181                	srli	a1,a1,0x20
    8000258a:	6928                	ld	a0,80(a0)
    8000258c:	fffff097          	auipc	ra,0xfffff
    80002590:	f62080e7          	jalr	-158(ra) # 800014ee <uvmdealloc>
    80002594:	0005061b          	sext.w	a2,a0
    80002598:	bf55                	j	8000254c <growproc+0x26>

000000008000259a <fork>:
{
    8000259a:	7139                	addi	sp,sp,-64
    8000259c:	fc06                	sd	ra,56(sp)
    8000259e:	f822                	sd	s0,48(sp)
    800025a0:	f426                	sd	s1,40(sp)
    800025a2:	f04a                	sd	s2,32(sp)
    800025a4:	ec4e                	sd	s3,24(sp)
    800025a6:	e852                	sd	s4,16(sp)
    800025a8:	e456                	sd	s5,8(sp)
    800025aa:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    800025ac:	00000097          	auipc	ra,0x0
    800025b0:	c2a080e7          	jalr	-982(ra) # 800021d6 <myproc>
    800025b4:	89aa                	mv	s3,a0
  if((np = allocproc()) == 0){
    800025b6:	00000097          	auipc	ra,0x0
    800025ba:	e2a080e7          	jalr	-470(ra) # 800023e0 <allocproc>
    800025be:	1c050363          	beqz	a0,80002784 <fork+0x1ea>
    800025c2:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, 0, p->sz) < 0){
    800025c4:	0489b683          	ld	a3,72(s3)
    800025c8:	4601                	li	a2,0
    800025ca:	692c                	ld	a1,80(a0)
    800025cc:	0509b503          	ld	a0,80(s3)
    800025d0:	fffff097          	auipc	ra,0xfffff
    800025d4:	0b2080e7          	jalr	178(ra) # 80001682 <uvmcopy>
    800025d8:	0a054a63          	bltz	a0,8000268c <fork+0xf2>
  np->sz = p->sz;
    800025dc:	0489b783          	ld	a5,72(s3)
    800025e0:	04fa3423          	sd	a5,72(s4)
  struct vma *vma = p->vma, *nvma;
    800025e4:	1689b903          	ld	s2,360(s3)
  if (vma == 0)
    800025e8:	0a090e63          	beqz	s2,800026a4 <fork+0x10a>
    nvma = kvma_alloc();
    800025ec:	ffffe097          	auipc	ra,0xffffe
    800025f0:	64e080e7          	jalr	1614(ra) # 80000c3a <kvma_alloc>
    800025f4:	84aa                	mv	s1,a0
    memmove(nvma, vma, sizeof(struct vma));
    800025f6:	04000613          	li	a2,64
    800025fa:	85ca                	mv	a1,s2
    800025fc:	fffff097          	auipc	ra,0xfffff
    80002600:	874080e7          	jalr	-1932(ra) # 80000e70 <memmove>
    nvma->next = 0;
    80002604:	0204bc23          	sd	zero,56(s1)
    np->vma = nvma;
    80002608:	169a3423          	sd	s1,360(s4)
    filedup(nvma->file);
    8000260c:	6c88                	ld	a0,24(s1)
    8000260e:	00003097          	auipc	ra,0x3
    80002612:	804080e7          	jalr	-2044(ra) # 80004e12 <filedup>
    if(uvmcopy(p->pagetable, np->pagetable, vma->start, vma->length) < 0)
    80002616:	02093683          	ld	a3,32(s2)
    8000261a:	00093603          	ld	a2,0(s2)
    8000261e:	050a3583          	ld	a1,80(s4)
    80002622:	0509b503          	ld	a0,80(s3)
    80002626:	fffff097          	auipc	ra,0xfffff
    8000262a:	05c080e7          	jalr	92(ra) # 80001682 <uvmcopy>
    8000262e:	0a054f63          	bltz	a0,800026ec <fork+0x152>
    for (vma = vma->next; vma != 0; vma = vma->next)
    80002632:	03893903          	ld	s2,56(s2)
    80002636:	06090963          	beqz	s2,800026a8 <fork+0x10e>
      nvma->next = kvma_alloc();
    8000263a:	8aa6                	mv	s5,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	5fe080e7          	jalr	1534(ra) # 80000c3a <kvma_alloc>
    80002644:	84aa                	mv	s1,a0
    80002646:	02aabc23          	sd	a0,56(s5)
      memmove(nvma, vma, sizeof(struct vma));
    8000264a:	04000613          	li	a2,64
    8000264e:	85ca                	mv	a1,s2
    80002650:	fffff097          	auipc	ra,0xfffff
    80002654:	820080e7          	jalr	-2016(ra) # 80000e70 <memmove>
      nvma->next = 0;
    80002658:	0204bc23          	sd	zero,56(s1)
      filedup(nvma->file);
    8000265c:	6c88                	ld	a0,24(s1)
    8000265e:	00002097          	auipc	ra,0x2
    80002662:	7b4080e7          	jalr	1972(ra) # 80004e12 <filedup>
      if(uvmcopy(p->pagetable, np->pagetable, vma->start, vma->length) < 0)
    80002666:	02093683          	ld	a3,32(s2)
    8000266a:	00093603          	ld	a2,0(s2)
    8000266e:	050a3583          	ld	a1,80(s4)
    80002672:	0509b503          	ld	a0,80(s3)
    80002676:	fffff097          	auipc	ra,0xfffff
    8000267a:	00c080e7          	jalr	12(ra) # 80001682 <uvmcopy>
    8000267e:	08054363          	bltz	a0,80002704 <fork+0x16a>
    for (vma = vma->next; vma != 0; vma = vma->next)
    80002682:	03893903          	ld	s2,56(s2)
    80002686:	fa091ae3          	bnez	s2,8000263a <fork+0xa0>
    8000268a:	a839                	j	800026a8 <fork+0x10e>
    freeproc(np);
    8000268c:	8552                	mv	a0,s4
    8000268e:	00000097          	auipc	ra,0x0
    80002692:	cfa080e7          	jalr	-774(ra) # 80002388 <freeproc>
    release(&np->lock);
    80002696:	8552                	mv	a0,s4
    80002698:	ffffe097          	auipc	ra,0xffffe
    8000269c:	730080e7          	jalr	1840(ra) # 80000dc8 <release>
    return -1;
    800026a0:	54fd                	li	s1,-1
    800026a2:	a0f9                	j	80002770 <fork+0x1d6>
    np->vma = 0;
    800026a4:	160a3423          	sd	zero,360(s4)
  np->parent = p;
    800026a8:	033a3023          	sd	s3,32(s4)
  *(np->trapframe) = *(p->trapframe);
    800026ac:	0589b683          	ld	a3,88(s3)
    800026b0:	87b6                	mv	a5,a3
    800026b2:	058a3703          	ld	a4,88(s4)
    800026b6:	12068693          	addi	a3,a3,288
    800026ba:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800026be:	6788                	ld	a0,8(a5)
    800026c0:	6b8c                	ld	a1,16(a5)
    800026c2:	6f90                	ld	a2,24(a5)
    800026c4:	01073023          	sd	a6,0(a4)
    800026c8:	e708                	sd	a0,8(a4)
    800026ca:	eb0c                	sd	a1,16(a4)
    800026cc:	ef10                	sd	a2,24(a4)
    800026ce:	02078793          	addi	a5,a5,32
    800026d2:	02070713          	addi	a4,a4,32
    800026d6:	fed792e3          	bne	a5,a3,800026ba <fork+0x120>
  np->trapframe->a0 = 0;
    800026da:	058a3783          	ld	a5,88(s4)
    800026de:	0607b823          	sd	zero,112(a5)
    800026e2:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    800026e6:	15000913          	li	s2,336
    800026ea:	a099                	j	80002730 <fork+0x196>
      freeproc(np);
    800026ec:	8552                	mv	a0,s4
    800026ee:	00000097          	auipc	ra,0x0
    800026f2:	c9a080e7          	jalr	-870(ra) # 80002388 <freeproc>
      release(&np->lock);
    800026f6:	8552                	mv	a0,s4
    800026f8:	ffffe097          	auipc	ra,0xffffe
    800026fc:	6d0080e7          	jalr	1744(ra) # 80000dc8 <release>
      return -1;
    80002700:	54fd                	li	s1,-1
    80002702:	a0bd                	j	80002770 <fork+0x1d6>
        freeproc(np);
    80002704:	8552                	mv	a0,s4
    80002706:	00000097          	auipc	ra,0x0
    8000270a:	c82080e7          	jalr	-894(ra) # 80002388 <freeproc>
        release(&np->lock);
    8000270e:	8552                	mv	a0,s4
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	6b8080e7          	jalr	1720(ra) # 80000dc8 <release>
        return -1;
    80002718:	54fd                	li	s1,-1
    8000271a:	a899                	j	80002770 <fork+0x1d6>
      np->ofile[i] = filedup(p->ofile[i]);
    8000271c:	00002097          	auipc	ra,0x2
    80002720:	6f6080e7          	jalr	1782(ra) # 80004e12 <filedup>
    80002724:	009a07b3          	add	a5,s4,s1
    80002728:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    8000272a:	04a1                	addi	s1,s1,8
    8000272c:	01248763          	beq	s1,s2,8000273a <fork+0x1a0>
    if(p->ofile[i])
    80002730:	009987b3          	add	a5,s3,s1
    80002734:	6388                	ld	a0,0(a5)
    80002736:	f17d                	bnez	a0,8000271c <fork+0x182>
    80002738:	bfcd                	j	8000272a <fork+0x190>
  np->cwd = idup(p->cwd);
    8000273a:	1509b503          	ld	a0,336(s3)
    8000273e:	00002097          	auipc	ra,0x2
    80002742:	842080e7          	jalr	-1982(ra) # 80003f80 <idup>
    80002746:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    8000274a:	4641                	li	a2,16
    8000274c:	15898593          	addi	a1,s3,344
    80002750:	158a0513          	addi	a0,s4,344
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	812080e7          	jalr	-2030(ra) # 80000f66 <safestrcpy>
  pid = np->pid;
    8000275c:	038a2483          	lw	s1,56(s4)
  np->state = RUNNABLE;
    80002760:	4789                	li	a5,2
    80002762:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80002766:	8552                	mv	a0,s4
    80002768:	ffffe097          	auipc	ra,0xffffe
    8000276c:	660080e7          	jalr	1632(ra) # 80000dc8 <release>
}
    80002770:	8526                	mv	a0,s1
    80002772:	70e2                	ld	ra,56(sp)
    80002774:	7442                	ld	s0,48(sp)
    80002776:	74a2                	ld	s1,40(sp)
    80002778:	7902                	ld	s2,32(sp)
    8000277a:	69e2                	ld	s3,24(sp)
    8000277c:	6a42                	ld	s4,16(sp)
    8000277e:	6aa2                	ld	s5,8(sp)
    80002780:	6121                	addi	sp,sp,64
    80002782:	8082                	ret
    return -1;
    80002784:	54fd                	li	s1,-1
    80002786:	b7ed                	j	80002770 <fork+0x1d6>

0000000080002788 <reparent>:
{
    80002788:	7179                	addi	sp,sp,-48
    8000278a:	f406                	sd	ra,40(sp)
    8000278c:	f022                	sd	s0,32(sp)
    8000278e:	ec26                	sd	s1,24(sp)
    80002790:	e84a                	sd	s2,16(sp)
    80002792:	e44e                	sd	s3,8(sp)
    80002794:	e052                	sd	s4,0(sp)
    80002796:	1800                	addi	s0,sp,48
    80002798:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000279a:	0000f497          	auipc	s1,0xf
    8000279e:	f3e48493          	addi	s1,s1,-194 # 800116d8 <proc>
      pp->parent = initproc;
    800027a2:	00007a17          	auipc	s4,0x7
    800027a6:	886a0a13          	addi	s4,s4,-1914 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800027aa:	00015997          	auipc	s3,0x15
    800027ae:	b2e98993          	addi	s3,s3,-1234 # 800172d8 <tickslock>
    800027b2:	a029                	j	800027bc <reparent+0x34>
    800027b4:	17048493          	addi	s1,s1,368
    800027b8:	03348363          	beq	s1,s3,800027de <reparent+0x56>
    if(pp->parent == p){
    800027bc:	709c                	ld	a5,32(s1)
    800027be:	ff279be3          	bne	a5,s2,800027b4 <reparent+0x2c>
      acquire(&pp->lock);
    800027c2:	8526                	mv	a0,s1
    800027c4:	ffffe097          	auipc	ra,0xffffe
    800027c8:	550080e7          	jalr	1360(ra) # 80000d14 <acquire>
      pp->parent = initproc;
    800027cc:	000a3783          	ld	a5,0(s4)
    800027d0:	f09c                	sd	a5,32(s1)
      release(&pp->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	5f4080e7          	jalr	1524(ra) # 80000dc8 <release>
    800027dc:	bfe1                	j	800027b4 <reparent+0x2c>
}
    800027de:	70a2                	ld	ra,40(sp)
    800027e0:	7402                	ld	s0,32(sp)
    800027e2:	64e2                	ld	s1,24(sp)
    800027e4:	6942                	ld	s2,16(sp)
    800027e6:	69a2                	ld	s3,8(sp)
    800027e8:	6a02                	ld	s4,0(sp)
    800027ea:	6145                	addi	sp,sp,48
    800027ec:	8082                	ret

00000000800027ee <scheduler>:
{
    800027ee:	711d                	addi	sp,sp,-96
    800027f0:	ec86                	sd	ra,88(sp)
    800027f2:	e8a2                	sd	s0,80(sp)
    800027f4:	e4a6                	sd	s1,72(sp)
    800027f6:	e0ca                	sd	s2,64(sp)
    800027f8:	fc4e                	sd	s3,56(sp)
    800027fa:	f852                	sd	s4,48(sp)
    800027fc:	f456                	sd	s5,40(sp)
    800027fe:	f05a                	sd	s6,32(sp)
    80002800:	ec5e                	sd	s7,24(sp)
    80002802:	e862                	sd	s8,16(sp)
    80002804:	e466                	sd	s9,8(sp)
    80002806:	1080                	addi	s0,sp,96
    80002808:	8792                	mv	a5,tp
  int id = r_tp();
    8000280a:	2781                	sext.w	a5,a5
  c->proc = 0;
    8000280c:	00779c13          	slli	s8,a5,0x7
    80002810:	0000f717          	auipc	a4,0xf
    80002814:	ab070713          	addi	a4,a4,-1360 # 800112c0 <pid_lock>
    80002818:	9762                	add	a4,a4,s8
    8000281a:	00073c23          	sd	zero,24(a4)
        swtch(&c->context, &p->context);
    8000281e:	0000f717          	auipc	a4,0xf
    80002822:	ac270713          	addi	a4,a4,-1342 # 800112e0 <cpus+0x8>
    80002826:	9c3a                	add	s8,s8,a4
      if(p->state == RUNNABLE) {
    80002828:	4a89                	li	s5,2
        c->proc = p;
    8000282a:	079e                	slli	a5,a5,0x7
    8000282c:	0000fb17          	auipc	s6,0xf
    80002830:	a94b0b13          	addi	s6,s6,-1388 # 800112c0 <pid_lock>
    80002834:	9b3e                	add	s6,s6,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002836:	00015a17          	auipc	s4,0x15
    8000283a:	aa2a0a13          	addi	s4,s4,-1374 # 800172d8 <tickslock>
    int nproc = 0;
    8000283e:	4c81                	li	s9,0
    80002840:	a8a1                	j	80002898 <scheduler+0xaa>
        p->state = RUNNING;
    80002842:	0174ac23          	sw	s7,24(s1)
        c->proc = p;
    80002846:	009b3c23          	sd	s1,24(s6)
        swtch(&c->context, &p->context);
    8000284a:	06048593          	addi	a1,s1,96
    8000284e:	8562                	mv	a0,s8
    80002850:	00000097          	auipc	ra,0x0
    80002854:	6a4080e7          	jalr	1700(ra) # 80002ef4 <swtch>
        c->proc = 0;
    80002858:	000b3c23          	sd	zero,24(s6)
      release(&p->lock);
    8000285c:	8526                	mv	a0,s1
    8000285e:	ffffe097          	auipc	ra,0xffffe
    80002862:	56a080e7          	jalr	1386(ra) # 80000dc8 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80002866:	17048493          	addi	s1,s1,368
    8000286a:	01448d63          	beq	s1,s4,80002884 <scheduler+0x96>
      acquire(&p->lock);
    8000286e:	8526                	mv	a0,s1
    80002870:	ffffe097          	auipc	ra,0xffffe
    80002874:	4a4080e7          	jalr	1188(ra) # 80000d14 <acquire>
      if(p->state != UNUSED) {
    80002878:	4c9c                	lw	a5,24(s1)
    8000287a:	d3ed                	beqz	a5,8000285c <scheduler+0x6e>
        nproc++;
    8000287c:	2985                	addiw	s3,s3,1
      if(p->state == RUNNABLE) {
    8000287e:	fd579fe3          	bne	a5,s5,8000285c <scheduler+0x6e>
    80002882:	b7c1                	j	80002842 <scheduler+0x54>
    if(nproc <= 2) {   // only init and sh exist
    80002884:	013aca63          	blt	s5,s3,80002898 <scheduler+0xaa>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002888:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000288c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002890:	10079073          	csrw	sstatus,a5
      asm volatile("wfi");
    80002894:	10500073          	wfi
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002898:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000289c:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a0:	10079073          	csrw	sstatus,a5
    int nproc = 0;
    800028a4:	89e6                	mv	s3,s9
    for(p = proc; p < &proc[NPROC]; p++) {
    800028a6:	0000f497          	auipc	s1,0xf
    800028aa:	e3248493          	addi	s1,s1,-462 # 800116d8 <proc>
        p->state = RUNNING;
    800028ae:	4b8d                	li	s7,3
    800028b0:	bf7d                	j	8000286e <scheduler+0x80>

00000000800028b2 <sched>:
{
    800028b2:	7179                	addi	sp,sp,-48
    800028b4:	f406                	sd	ra,40(sp)
    800028b6:	f022                	sd	s0,32(sp)
    800028b8:	ec26                	sd	s1,24(sp)
    800028ba:	e84a                	sd	s2,16(sp)
    800028bc:	e44e                	sd	s3,8(sp)
    800028be:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800028c0:	00000097          	auipc	ra,0x0
    800028c4:	916080e7          	jalr	-1770(ra) # 800021d6 <myproc>
    800028c8:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800028ca:	ffffe097          	auipc	ra,0xffffe
    800028ce:	3d0080e7          	jalr	976(ra) # 80000c9a <holding>
    800028d2:	c93d                	beqz	a0,80002948 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800028d4:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800028d6:	2781                	sext.w	a5,a5
    800028d8:	079e                	slli	a5,a5,0x7
    800028da:	0000f717          	auipc	a4,0xf
    800028de:	9e670713          	addi	a4,a4,-1562 # 800112c0 <pid_lock>
    800028e2:	97ba                	add	a5,a5,a4
    800028e4:	0907a703          	lw	a4,144(a5)
    800028e8:	4785                	li	a5,1
    800028ea:	06f71763          	bne	a4,a5,80002958 <sched+0xa6>
  if(p->state == RUNNING)
    800028ee:	4c98                	lw	a4,24(s1)
    800028f0:	478d                	li	a5,3
    800028f2:	06f70b63          	beq	a4,a5,80002968 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028f6:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800028fa:	8b89                	andi	a5,a5,2
  if(intr_get())
    800028fc:	efb5                	bnez	a5,80002978 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800028fe:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002900:	0000f917          	auipc	s2,0xf
    80002904:	9c090913          	addi	s2,s2,-1600 # 800112c0 <pid_lock>
    80002908:	2781                	sext.w	a5,a5
    8000290a:	079e                	slli	a5,a5,0x7
    8000290c:	97ca                	add	a5,a5,s2
    8000290e:	0947a983          	lw	s3,148(a5)
    80002912:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002914:	2781                	sext.w	a5,a5
    80002916:	079e                	slli	a5,a5,0x7
    80002918:	0000f597          	auipc	a1,0xf
    8000291c:	9c858593          	addi	a1,a1,-1592 # 800112e0 <cpus+0x8>
    80002920:	95be                	add	a1,a1,a5
    80002922:	06048513          	addi	a0,s1,96
    80002926:	00000097          	auipc	ra,0x0
    8000292a:	5ce080e7          	jalr	1486(ra) # 80002ef4 <swtch>
    8000292e:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002930:	2781                	sext.w	a5,a5
    80002932:	079e                	slli	a5,a5,0x7
    80002934:	97ca                	add	a5,a5,s2
    80002936:	0937aa23          	sw	s3,148(a5)
}
    8000293a:	70a2                	ld	ra,40(sp)
    8000293c:	7402                	ld	s0,32(sp)
    8000293e:	64e2                	ld	s1,24(sp)
    80002940:	6942                	ld	s2,16(sp)
    80002942:	69a2                	ld	s3,8(sp)
    80002944:	6145                	addi	sp,sp,48
    80002946:	8082                	ret
    panic("sched p->lock");
    80002948:	00006517          	auipc	a0,0x6
    8000294c:	8d050513          	addi	a0,a0,-1840 # 80008218 <digits+0x1d8>
    80002950:	ffffe097          	auipc	ra,0xffffe
    80002954:	be0080e7          	jalr	-1056(ra) # 80000530 <panic>
    panic("sched locks");
    80002958:	00006517          	auipc	a0,0x6
    8000295c:	8d050513          	addi	a0,a0,-1840 # 80008228 <digits+0x1e8>
    80002960:	ffffe097          	auipc	ra,0xffffe
    80002964:	bd0080e7          	jalr	-1072(ra) # 80000530 <panic>
    panic("sched running");
    80002968:	00006517          	auipc	a0,0x6
    8000296c:	8d050513          	addi	a0,a0,-1840 # 80008238 <digits+0x1f8>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	bc0080e7          	jalr	-1088(ra) # 80000530 <panic>
    panic("sched interruptible");
    80002978:	00006517          	auipc	a0,0x6
    8000297c:	8d050513          	addi	a0,a0,-1840 # 80008248 <digits+0x208>
    80002980:	ffffe097          	auipc	ra,0xffffe
    80002984:	bb0080e7          	jalr	-1104(ra) # 80000530 <panic>

0000000080002988 <exit>:
{
    80002988:	7139                	addi	sp,sp,-64
    8000298a:	fc06                	sd	ra,56(sp)
    8000298c:	f822                	sd	s0,48(sp)
    8000298e:	f426                	sd	s1,40(sp)
    80002990:	f04a                	sd	s2,32(sp)
    80002992:	ec4e                	sd	s3,24(sp)
    80002994:	e852                	sd	s4,16(sp)
    80002996:	e456                	sd	s5,8(sp)
    80002998:	0080                	addi	s0,sp,64
    8000299a:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    8000299c:	00000097          	auipc	ra,0x0
    800029a0:	83a080e7          	jalr	-1990(ra) # 800021d6 <myproc>
  if(p == initproc)
    800029a4:	00006797          	auipc	a5,0x6
    800029a8:	6847b783          	ld	a5,1668(a5) # 80009028 <initproc>
    800029ac:	00a78c63          	beq	a5,a0,800029c4 <exit+0x3c>
    800029b0:	89aa                	mv	s3,a0
  struct vma *vma = myproc()->vma, *next;
    800029b2:	00000097          	auipc	ra,0x0
    800029b6:	824080e7          	jalr	-2012(ra) # 800021d6 <myproc>
    800029ba:	16853483          	ld	s1,360(a0)
  while (vma != 0)
    800029be:	c4ad                	beqz	s1,80002a28 <exit+0xa0>
    if ((vma->prot & PROT_WRITE) && vma->flags == MAP_SHARED)
    800029c0:	4a85                	li	s5,1
    800029c2:	a0a9                	j	80002a0c <exit+0x84>
    panic("init exiting");
    800029c4:	00006517          	auipc	a0,0x6
    800029c8:	89c50513          	addi	a0,a0,-1892 # 80008260 <digits+0x220>
    800029cc:	ffffe097          	auipc	ra,0xffffe
    800029d0:	b64080e7          	jalr	-1180(ra) # 80000530 <panic>
    uvmunmap(myproc()->pagetable, vma->start, vma->length / PGSIZE, 1);
    800029d4:	00000097          	auipc	ra,0x0
    800029d8:	802080e7          	jalr	-2046(ra) # 800021d6 <myproc>
    800029dc:	7090                	ld	a2,32(s1)
    800029de:	86d6                	mv	a3,s5
    800029e0:	8231                	srli	a2,a2,0xc
    800029e2:	608c                	ld	a1,0(s1)
    800029e4:	6928                	ld	a0,80(a0)
    800029e6:	fffff097          	auipc	ra,0xfffff
    800029ea:	9b2080e7          	jalr	-1614(ra) # 80001398 <uvmunmap>
    fileclose(vma->file);
    800029ee:	6c88                	ld	a0,24(s1)
    800029f0:	00002097          	auipc	ra,0x2
    800029f4:	474080e7          	jalr	1140(ra) # 80004e64 <fileclose>
    next = vma->next;
    800029f8:	0384b903          	ld	s2,56(s1)
    kvma_free(vma);
    800029fc:	8526                	mv	a0,s1
    800029fe:	ffffe097          	auipc	ra,0xffffe
    80002a02:	10c080e7          	jalr	268(ra) # 80000b0a <kvma_free>
  while (vma != 0)
    80002a06:	02090163          	beqz	s2,80002a28 <exit+0xa0>
    vma = next;
    80002a0a:	84ca                	mv	s1,s2
    if ((vma->prot & PROT_WRITE) && vma->flags == MAP_SHARED)
    80002a0c:	489c                	lw	a5,16(s1)
    80002a0e:	8b89                	andi	a5,a5,2
    80002a10:	d3f1                	beqz	a5,800029d4 <exit+0x4c>
    80002a12:	589c                	lw	a5,48(s1)
    80002a14:	fd5790e3          	bne	a5,s5,800029d4 <exit+0x4c>
      writeback(vma, vma->start, vma->length);
    80002a18:	7090                	ld	a2,32(s1)
    80002a1a:	608c                	ld	a1,0(s1)
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	fffff097          	auipc	ra,0xfffff
    80002a22:	394080e7          	jalr	916(ra) # 80001db2 <writeback>
    80002a26:	b77d                	j	800029d4 <exit+0x4c>
  for(int fd = 0; fd < NOFILE; fd++){
    80002a28:	0d098493          	addi	s1,s3,208
    80002a2c:	15098913          	addi	s2,s3,336
    80002a30:	a811                	j	80002a44 <exit+0xbc>
      fileclose(f);
    80002a32:	00002097          	auipc	ra,0x2
    80002a36:	432080e7          	jalr	1074(ra) # 80004e64 <fileclose>
      p->ofile[fd] = 0;
    80002a3a:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002a3e:	04a1                	addi	s1,s1,8
    80002a40:	01248563          	beq	s1,s2,80002a4a <exit+0xc2>
    if(p->ofile[fd]){
    80002a44:	6088                	ld	a0,0(s1)
    80002a46:	f575                	bnez	a0,80002a32 <exit+0xaa>
    80002a48:	bfdd                	j	80002a3e <exit+0xb6>
  begin_op();
    80002a4a:	00002097          	auipc	ra,0x2
    80002a4e:	f46080e7          	jalr	-186(ra) # 80004990 <begin_op>
  iput(p->cwd);
    80002a52:	1509b503          	ld	a0,336(s3)
    80002a56:	00001097          	auipc	ra,0x1
    80002a5a:	722080e7          	jalr	1826(ra) # 80004178 <iput>
  end_op();
    80002a5e:	00002097          	auipc	ra,0x2
    80002a62:	fb2080e7          	jalr	-78(ra) # 80004a10 <end_op>
  p->cwd = 0;
    80002a66:	1409b823          	sd	zero,336(s3)
  acquire(&initproc->lock);
    80002a6a:	00006497          	auipc	s1,0x6
    80002a6e:	5be48493          	addi	s1,s1,1470 # 80009028 <initproc>
    80002a72:	6088                	ld	a0,0(s1)
    80002a74:	ffffe097          	auipc	ra,0xffffe
    80002a78:	2a0080e7          	jalr	672(ra) # 80000d14 <acquire>
  wakeup1(initproc);
    80002a7c:	6088                	ld	a0,0(s1)
    80002a7e:	fffff097          	auipc	ra,0xfffff
    80002a82:	5ba080e7          	jalr	1466(ra) # 80002038 <wakeup1>
  release(&initproc->lock);
    80002a86:	6088                	ld	a0,0(s1)
    80002a88:	ffffe097          	auipc	ra,0xffffe
    80002a8c:	340080e7          	jalr	832(ra) # 80000dc8 <release>
  acquire(&p->lock);
    80002a90:	854e                	mv	a0,s3
    80002a92:	ffffe097          	auipc	ra,0xffffe
    80002a96:	282080e7          	jalr	642(ra) # 80000d14 <acquire>
  struct proc *original_parent = p->parent;
    80002a9a:	0209b483          	ld	s1,32(s3)
  release(&p->lock);
    80002a9e:	854e                	mv	a0,s3
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	328080e7          	jalr	808(ra) # 80000dc8 <release>
  acquire(&original_parent->lock);
    80002aa8:	8526                	mv	a0,s1
    80002aaa:	ffffe097          	auipc	ra,0xffffe
    80002aae:	26a080e7          	jalr	618(ra) # 80000d14 <acquire>
  acquire(&p->lock);
    80002ab2:	854e                	mv	a0,s3
    80002ab4:	ffffe097          	auipc	ra,0xffffe
    80002ab8:	260080e7          	jalr	608(ra) # 80000d14 <acquire>
  reparent(p);
    80002abc:	854e                	mv	a0,s3
    80002abe:	00000097          	auipc	ra,0x0
    80002ac2:	cca080e7          	jalr	-822(ra) # 80002788 <reparent>
  wakeup1(original_parent);
    80002ac6:	8526                	mv	a0,s1
    80002ac8:	fffff097          	auipc	ra,0xfffff
    80002acc:	570080e7          	jalr	1392(ra) # 80002038 <wakeup1>
  p->xstate = status;
    80002ad0:	0349aa23          	sw	s4,52(s3)
  p->state = ZOMBIE;
    80002ad4:	4791                	li	a5,4
    80002ad6:	00f9ac23          	sw	a5,24(s3)
  release(&original_parent->lock);
    80002ada:	8526                	mv	a0,s1
    80002adc:	ffffe097          	auipc	ra,0xffffe
    80002ae0:	2ec080e7          	jalr	748(ra) # 80000dc8 <release>
  sched();
    80002ae4:	00000097          	auipc	ra,0x0
    80002ae8:	dce080e7          	jalr	-562(ra) # 800028b2 <sched>
  panic("zombie exit");
    80002aec:	00005517          	auipc	a0,0x5
    80002af0:	78450513          	addi	a0,a0,1924 # 80008270 <digits+0x230>
    80002af4:	ffffe097          	auipc	ra,0xffffe
    80002af8:	a3c080e7          	jalr	-1476(ra) # 80000530 <panic>

0000000080002afc <yield>:
{
    80002afc:	1101                	addi	sp,sp,-32
    80002afe:	ec06                	sd	ra,24(sp)
    80002b00:	e822                	sd	s0,16(sp)
    80002b02:	e426                	sd	s1,8(sp)
    80002b04:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002b06:	fffff097          	auipc	ra,0xfffff
    80002b0a:	6d0080e7          	jalr	1744(ra) # 800021d6 <myproc>
    80002b0e:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	204080e7          	jalr	516(ra) # 80000d14 <acquire>
  p->state = RUNNABLE;
    80002b18:	4789                	li	a5,2
    80002b1a:	cc9c                	sw	a5,24(s1)
  sched();
    80002b1c:	00000097          	auipc	ra,0x0
    80002b20:	d96080e7          	jalr	-618(ra) # 800028b2 <sched>
  release(&p->lock);
    80002b24:	8526                	mv	a0,s1
    80002b26:	ffffe097          	auipc	ra,0xffffe
    80002b2a:	2a2080e7          	jalr	674(ra) # 80000dc8 <release>
}
    80002b2e:	60e2                	ld	ra,24(sp)
    80002b30:	6442                	ld	s0,16(sp)
    80002b32:	64a2                	ld	s1,8(sp)
    80002b34:	6105                	addi	sp,sp,32
    80002b36:	8082                	ret

0000000080002b38 <sleep>:
{
    80002b38:	7179                	addi	sp,sp,-48
    80002b3a:	f406                	sd	ra,40(sp)
    80002b3c:	f022                	sd	s0,32(sp)
    80002b3e:	ec26                	sd	s1,24(sp)
    80002b40:	e84a                	sd	s2,16(sp)
    80002b42:	e44e                	sd	s3,8(sp)
    80002b44:	1800                	addi	s0,sp,48
    80002b46:	89aa                	mv	s3,a0
    80002b48:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002b4a:	fffff097          	auipc	ra,0xfffff
    80002b4e:	68c080e7          	jalr	1676(ra) # 800021d6 <myproc>
    80002b52:	84aa                	mv	s1,a0
  if(lk != &p->lock){  //DOC: sleeplock0
    80002b54:	05250663          	beq	a0,s2,80002ba0 <sleep+0x68>
    acquire(&p->lock);  //DOC: sleeplock1
    80002b58:	ffffe097          	auipc	ra,0xffffe
    80002b5c:	1bc080e7          	jalr	444(ra) # 80000d14 <acquire>
    release(lk);
    80002b60:	854a                	mv	a0,s2
    80002b62:	ffffe097          	auipc	ra,0xffffe
    80002b66:	266080e7          	jalr	614(ra) # 80000dc8 <release>
  p->chan = chan;
    80002b6a:	0334b423          	sd	s3,40(s1)
  p->state = SLEEPING;
    80002b6e:	4785                	li	a5,1
    80002b70:	cc9c                	sw	a5,24(s1)
  sched();
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	d40080e7          	jalr	-704(ra) # 800028b2 <sched>
  p->chan = 0;
    80002b7a:	0204b423          	sd	zero,40(s1)
    release(&p->lock);
    80002b7e:	8526                	mv	a0,s1
    80002b80:	ffffe097          	auipc	ra,0xffffe
    80002b84:	248080e7          	jalr	584(ra) # 80000dc8 <release>
    acquire(lk);
    80002b88:	854a                	mv	a0,s2
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	18a080e7          	jalr	394(ra) # 80000d14 <acquire>
}
    80002b92:	70a2                	ld	ra,40(sp)
    80002b94:	7402                	ld	s0,32(sp)
    80002b96:	64e2                	ld	s1,24(sp)
    80002b98:	6942                	ld	s2,16(sp)
    80002b9a:	69a2                	ld	s3,8(sp)
    80002b9c:	6145                	addi	sp,sp,48
    80002b9e:	8082                	ret
  p->chan = chan;
    80002ba0:	03353423          	sd	s3,40(a0)
  p->state = SLEEPING;
    80002ba4:	4785                	li	a5,1
    80002ba6:	cd1c                	sw	a5,24(a0)
  sched();
    80002ba8:	00000097          	auipc	ra,0x0
    80002bac:	d0a080e7          	jalr	-758(ra) # 800028b2 <sched>
  p->chan = 0;
    80002bb0:	0204b423          	sd	zero,40(s1)
  if(lk != &p->lock){
    80002bb4:	bff9                	j	80002b92 <sleep+0x5a>

0000000080002bb6 <wait>:
{
    80002bb6:	715d                	addi	sp,sp,-80
    80002bb8:	e486                	sd	ra,72(sp)
    80002bba:	e0a2                	sd	s0,64(sp)
    80002bbc:	fc26                	sd	s1,56(sp)
    80002bbe:	f84a                	sd	s2,48(sp)
    80002bc0:	f44e                	sd	s3,40(sp)
    80002bc2:	f052                	sd	s4,32(sp)
    80002bc4:	ec56                	sd	s5,24(sp)
    80002bc6:	e85a                	sd	s6,16(sp)
    80002bc8:	e45e                	sd	s7,8(sp)
    80002bca:	e062                	sd	s8,0(sp)
    80002bcc:	0880                	addi	s0,sp,80
    80002bce:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002bd0:	fffff097          	auipc	ra,0xfffff
    80002bd4:	606080e7          	jalr	1542(ra) # 800021d6 <myproc>
    80002bd8:	892a                	mv	s2,a0
  acquire(&p->lock);
    80002bda:	8c2a                	mv	s8,a0
    80002bdc:	ffffe097          	auipc	ra,0xffffe
    80002be0:	138080e7          	jalr	312(ra) # 80000d14 <acquire>
    havekids = 0;
    80002be4:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    80002be6:	4a11                	li	s4,4
    for(np = proc; np < &proc[NPROC]; np++){
    80002be8:	00014997          	auipc	s3,0x14
    80002bec:	6f098993          	addi	s3,s3,1776 # 800172d8 <tickslock>
        havekids = 1;
    80002bf0:	4a85                	li	s5,1
    havekids = 0;
    80002bf2:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002bf4:	0000f497          	auipc	s1,0xf
    80002bf8:	ae448493          	addi	s1,s1,-1308 # 800116d8 <proc>
    80002bfc:	a08d                	j	80002c5e <wait+0xa8>
          pid = np->pid;
    80002bfe:	0384a983          	lw	s3,56(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c02:	000b0e63          	beqz	s6,80002c1e <wait+0x68>
    80002c06:	4691                	li	a3,4
    80002c08:	03448613          	addi	a2,s1,52
    80002c0c:	85da                	mv	a1,s6
    80002c0e:	05093503          	ld	a0,80(s2)
    80002c12:	fffff097          	auipc	ra,0xfffff
    80002c16:	f84080e7          	jalr	-124(ra) # 80001b96 <copyout>
    80002c1a:	02054263          	bltz	a0,80002c3e <wait+0x88>
          freeproc(np);
    80002c1e:	8526                	mv	a0,s1
    80002c20:	fffff097          	auipc	ra,0xfffff
    80002c24:	768080e7          	jalr	1896(ra) # 80002388 <freeproc>
          release(&np->lock);
    80002c28:	8526                	mv	a0,s1
    80002c2a:	ffffe097          	auipc	ra,0xffffe
    80002c2e:	19e080e7          	jalr	414(ra) # 80000dc8 <release>
          release(&p->lock);
    80002c32:	854a                	mv	a0,s2
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	194080e7          	jalr	404(ra) # 80000dc8 <release>
          return pid;
    80002c3c:	a8a9                	j	80002c96 <wait+0xe0>
            release(&np->lock);
    80002c3e:	8526                	mv	a0,s1
    80002c40:	ffffe097          	auipc	ra,0xffffe
    80002c44:	188080e7          	jalr	392(ra) # 80000dc8 <release>
            release(&p->lock);
    80002c48:	854a                	mv	a0,s2
    80002c4a:	ffffe097          	auipc	ra,0xffffe
    80002c4e:	17e080e7          	jalr	382(ra) # 80000dc8 <release>
            return -1;
    80002c52:	59fd                	li	s3,-1
    80002c54:	a089                	j	80002c96 <wait+0xe0>
    for(np = proc; np < &proc[NPROC]; np++){
    80002c56:	17048493          	addi	s1,s1,368
    80002c5a:	03348463          	beq	s1,s3,80002c82 <wait+0xcc>
      if(np->parent == p){
    80002c5e:	709c                	ld	a5,32(s1)
    80002c60:	ff279be3          	bne	a5,s2,80002c56 <wait+0xa0>
        acquire(&np->lock);
    80002c64:	8526                	mv	a0,s1
    80002c66:	ffffe097          	auipc	ra,0xffffe
    80002c6a:	0ae080e7          	jalr	174(ra) # 80000d14 <acquire>
        if(np->state == ZOMBIE){
    80002c6e:	4c9c                	lw	a5,24(s1)
    80002c70:	f94787e3          	beq	a5,s4,80002bfe <wait+0x48>
        release(&np->lock);
    80002c74:	8526                	mv	a0,s1
    80002c76:	ffffe097          	auipc	ra,0xffffe
    80002c7a:	152080e7          	jalr	338(ra) # 80000dc8 <release>
        havekids = 1;
    80002c7e:	8756                	mv	a4,s5
    80002c80:	bfd9                	j	80002c56 <wait+0xa0>
    if(!havekids || p->killed){
    80002c82:	c701                	beqz	a4,80002c8a <wait+0xd4>
    80002c84:	03092783          	lw	a5,48(s2)
    80002c88:	c785                	beqz	a5,80002cb0 <wait+0xfa>
      release(&p->lock);
    80002c8a:	854a                	mv	a0,s2
    80002c8c:	ffffe097          	auipc	ra,0xffffe
    80002c90:	13c080e7          	jalr	316(ra) # 80000dc8 <release>
      return -1;
    80002c94:	59fd                	li	s3,-1
}
    80002c96:	854e                	mv	a0,s3
    80002c98:	60a6                	ld	ra,72(sp)
    80002c9a:	6406                	ld	s0,64(sp)
    80002c9c:	74e2                	ld	s1,56(sp)
    80002c9e:	7942                	ld	s2,48(sp)
    80002ca0:	79a2                	ld	s3,40(sp)
    80002ca2:	7a02                	ld	s4,32(sp)
    80002ca4:	6ae2                	ld	s5,24(sp)
    80002ca6:	6b42                	ld	s6,16(sp)
    80002ca8:	6ba2                	ld	s7,8(sp)
    80002caa:	6c02                	ld	s8,0(sp)
    80002cac:	6161                	addi	sp,sp,80
    80002cae:	8082                	ret
    sleep(p, &p->lock);  //DOC: wait-sleep
    80002cb0:	85e2                	mv	a1,s8
    80002cb2:	854a                	mv	a0,s2
    80002cb4:	00000097          	auipc	ra,0x0
    80002cb8:	e84080e7          	jalr	-380(ra) # 80002b38 <sleep>
    havekids = 0;
    80002cbc:	bf1d                	j	80002bf2 <wait+0x3c>

0000000080002cbe <wakeup>:
{
    80002cbe:	7139                	addi	sp,sp,-64
    80002cc0:	fc06                	sd	ra,56(sp)
    80002cc2:	f822                	sd	s0,48(sp)
    80002cc4:	f426                	sd	s1,40(sp)
    80002cc6:	f04a                	sd	s2,32(sp)
    80002cc8:	ec4e                	sd	s3,24(sp)
    80002cca:	e852                	sd	s4,16(sp)
    80002ccc:	e456                	sd	s5,8(sp)
    80002cce:	0080                	addi	s0,sp,64
    80002cd0:	8a2a                	mv	s4,a0
  for(p = proc; p < &proc[NPROC]; p++) {
    80002cd2:	0000f497          	auipc	s1,0xf
    80002cd6:	a0648493          	addi	s1,s1,-1530 # 800116d8 <proc>
    if(p->state == SLEEPING && p->chan == chan) {
    80002cda:	4985                	li	s3,1
      p->state = RUNNABLE;
    80002cdc:	4a89                	li	s5,2
  for(p = proc; p < &proc[NPROC]; p++) {
    80002cde:	00014917          	auipc	s2,0x14
    80002ce2:	5fa90913          	addi	s2,s2,1530 # 800172d8 <tickslock>
    80002ce6:	a821                	j	80002cfe <wakeup+0x40>
      p->state = RUNNABLE;
    80002ce8:	0154ac23          	sw	s5,24(s1)
    release(&p->lock);
    80002cec:	8526                	mv	a0,s1
    80002cee:	ffffe097          	auipc	ra,0xffffe
    80002cf2:	0da080e7          	jalr	218(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002cf6:	17048493          	addi	s1,s1,368
    80002cfa:	01248e63          	beq	s1,s2,80002d16 <wakeup+0x58>
    acquire(&p->lock);
    80002cfe:	8526                	mv	a0,s1
    80002d00:	ffffe097          	auipc	ra,0xffffe
    80002d04:	014080e7          	jalr	20(ra) # 80000d14 <acquire>
    if(p->state == SLEEPING && p->chan == chan) {
    80002d08:	4c9c                	lw	a5,24(s1)
    80002d0a:	ff3791e3          	bne	a5,s3,80002cec <wakeup+0x2e>
    80002d0e:	749c                	ld	a5,40(s1)
    80002d10:	fd479ee3          	bne	a5,s4,80002cec <wakeup+0x2e>
    80002d14:	bfd1                	j	80002ce8 <wakeup+0x2a>
}
    80002d16:	70e2                	ld	ra,56(sp)
    80002d18:	7442                	ld	s0,48(sp)
    80002d1a:	74a2                	ld	s1,40(sp)
    80002d1c:	7902                	ld	s2,32(sp)
    80002d1e:	69e2                	ld	s3,24(sp)
    80002d20:	6a42                	ld	s4,16(sp)
    80002d22:	6aa2                	ld	s5,8(sp)
    80002d24:	6121                	addi	sp,sp,64
    80002d26:	8082                	ret

0000000080002d28 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002d28:	7179                	addi	sp,sp,-48
    80002d2a:	f406                	sd	ra,40(sp)
    80002d2c:	f022                	sd	s0,32(sp)
    80002d2e:	ec26                	sd	s1,24(sp)
    80002d30:	e84a                	sd	s2,16(sp)
    80002d32:	e44e                	sd	s3,8(sp)
    80002d34:	1800                	addi	s0,sp,48
    80002d36:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002d38:	0000f497          	auipc	s1,0xf
    80002d3c:	9a048493          	addi	s1,s1,-1632 # 800116d8 <proc>
    80002d40:	00014997          	auipc	s3,0x14
    80002d44:	59898993          	addi	s3,s3,1432 # 800172d8 <tickslock>
    acquire(&p->lock);
    80002d48:	8526                	mv	a0,s1
    80002d4a:	ffffe097          	auipc	ra,0xffffe
    80002d4e:	fca080e7          	jalr	-54(ra) # 80000d14 <acquire>
    if(p->pid == pid){
    80002d52:	5c9c                	lw	a5,56(s1)
    80002d54:	01278d63          	beq	a5,s2,80002d6e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002d58:	8526                	mv	a0,s1
    80002d5a:	ffffe097          	auipc	ra,0xffffe
    80002d5e:	06e080e7          	jalr	110(ra) # 80000dc8 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80002d62:	17048493          	addi	s1,s1,368
    80002d66:	ff3491e3          	bne	s1,s3,80002d48 <kill+0x20>
  }
  return -1;
    80002d6a:	557d                	li	a0,-1
    80002d6c:	a829                	j	80002d86 <kill+0x5e>
      p->killed = 1;
    80002d6e:	4785                	li	a5,1
    80002d70:	d89c                	sw	a5,48(s1)
      if(p->state == SLEEPING){
    80002d72:	4c98                	lw	a4,24(s1)
    80002d74:	4785                	li	a5,1
    80002d76:	00f70f63          	beq	a4,a5,80002d94 <kill+0x6c>
      release(&p->lock);
    80002d7a:	8526                	mv	a0,s1
    80002d7c:	ffffe097          	auipc	ra,0xffffe
    80002d80:	04c080e7          	jalr	76(ra) # 80000dc8 <release>
      return 0;
    80002d84:	4501                	li	a0,0
}
    80002d86:	70a2                	ld	ra,40(sp)
    80002d88:	7402                	ld	s0,32(sp)
    80002d8a:	64e2                	ld	s1,24(sp)
    80002d8c:	6942                	ld	s2,16(sp)
    80002d8e:	69a2                	ld	s3,8(sp)
    80002d90:	6145                	addi	sp,sp,48
    80002d92:	8082                	ret
        p->state = RUNNABLE;
    80002d94:	4789                	li	a5,2
    80002d96:	cc9c                	sw	a5,24(s1)
    80002d98:	b7cd                	j	80002d7a <kill+0x52>

0000000080002d9a <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002d9a:	7179                	addi	sp,sp,-48
    80002d9c:	f406                	sd	ra,40(sp)
    80002d9e:	f022                	sd	s0,32(sp)
    80002da0:	ec26                	sd	s1,24(sp)
    80002da2:	e84a                	sd	s2,16(sp)
    80002da4:	e44e                	sd	s3,8(sp)
    80002da6:	e052                	sd	s4,0(sp)
    80002da8:	1800                	addi	s0,sp,48
    80002daa:	84aa                	mv	s1,a0
    80002dac:	892e                	mv	s2,a1
    80002dae:	89b2                	mv	s3,a2
    80002db0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002db2:	fffff097          	auipc	ra,0xfffff
    80002db6:	424080e7          	jalr	1060(ra) # 800021d6 <myproc>
  if(user_dst){
    80002dba:	c08d                	beqz	s1,80002ddc <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    80002dbc:	86d2                	mv	a3,s4
    80002dbe:	864e                	mv	a2,s3
    80002dc0:	85ca                	mv	a1,s2
    80002dc2:	6928                	ld	a0,80(a0)
    80002dc4:	fffff097          	auipc	ra,0xfffff
    80002dc8:	dd2080e7          	jalr	-558(ra) # 80001b96 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002dcc:	70a2                	ld	ra,40(sp)
    80002dce:	7402                	ld	s0,32(sp)
    80002dd0:	64e2                	ld	s1,24(sp)
    80002dd2:	6942                	ld	s2,16(sp)
    80002dd4:	69a2                	ld	s3,8(sp)
    80002dd6:	6a02                	ld	s4,0(sp)
    80002dd8:	6145                	addi	sp,sp,48
    80002dda:	8082                	ret
    memmove((char *)dst, src, len);
    80002ddc:	000a061b          	sext.w	a2,s4
    80002de0:	85ce                	mv	a1,s3
    80002de2:	854a                	mv	a0,s2
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	08c080e7          	jalr	140(ra) # 80000e70 <memmove>
    return 0;
    80002dec:	8526                	mv	a0,s1
    80002dee:	bff9                	j	80002dcc <either_copyout+0x32>

0000000080002df0 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002df0:	7179                	addi	sp,sp,-48
    80002df2:	f406                	sd	ra,40(sp)
    80002df4:	f022                	sd	s0,32(sp)
    80002df6:	ec26                	sd	s1,24(sp)
    80002df8:	e84a                	sd	s2,16(sp)
    80002dfa:	e44e                	sd	s3,8(sp)
    80002dfc:	e052                	sd	s4,0(sp)
    80002dfe:	1800                	addi	s0,sp,48
    80002e00:	892a                	mv	s2,a0
    80002e02:	84ae                	mv	s1,a1
    80002e04:	89b2                	mv	s3,a2
    80002e06:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002e08:	fffff097          	auipc	ra,0xfffff
    80002e0c:	3ce080e7          	jalr	974(ra) # 800021d6 <myproc>
  if(user_src){
    80002e10:	c08d                	beqz	s1,80002e32 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002e12:	86d2                	mv	a3,s4
    80002e14:	864e                	mv	a2,s3
    80002e16:	85ca                	mv	a1,s2
    80002e18:	6928                	ld	a0,80(a0)
    80002e1a:	fffff097          	auipc	ra,0xfffff
    80002e1e:	e22080e7          	jalr	-478(ra) # 80001c3c <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002e22:	70a2                	ld	ra,40(sp)
    80002e24:	7402                	ld	s0,32(sp)
    80002e26:	64e2                	ld	s1,24(sp)
    80002e28:	6942                	ld	s2,16(sp)
    80002e2a:	69a2                	ld	s3,8(sp)
    80002e2c:	6a02                	ld	s4,0(sp)
    80002e2e:	6145                	addi	sp,sp,48
    80002e30:	8082                	ret
    memmove(dst, (char*)src, len);
    80002e32:	000a061b          	sext.w	a2,s4
    80002e36:	85ce                	mv	a1,s3
    80002e38:	854a                	mv	a0,s2
    80002e3a:	ffffe097          	auipc	ra,0xffffe
    80002e3e:	036080e7          	jalr	54(ra) # 80000e70 <memmove>
    return 0;
    80002e42:	8526                	mv	a0,s1
    80002e44:	bff9                	j	80002e22 <either_copyin+0x32>

0000000080002e46 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002e46:	715d                	addi	sp,sp,-80
    80002e48:	e486                	sd	ra,72(sp)
    80002e4a:	e0a2                	sd	s0,64(sp)
    80002e4c:	fc26                	sd	s1,56(sp)
    80002e4e:	f84a                	sd	s2,48(sp)
    80002e50:	f44e                	sd	s3,40(sp)
    80002e52:	f052                	sd	s4,32(sp)
    80002e54:	ec56                	sd	s5,24(sp)
    80002e56:	e85a                	sd	s6,16(sp)
    80002e58:	e45e                	sd	s7,8(sp)
    80002e5a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002e5c:	00005517          	auipc	a0,0x5
    80002e60:	28450513          	addi	a0,a0,644 # 800080e0 <digits+0xa0>
    80002e64:	ffffd097          	auipc	ra,0xffffd
    80002e68:	716080e7          	jalr	1814(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002e6c:	0000f497          	auipc	s1,0xf
    80002e70:	9c448493          	addi	s1,s1,-1596 # 80011830 <proc+0x158>
    80002e74:	00014917          	auipc	s2,0x14
    80002e78:	5bc90913          	addi	s2,s2,1468 # 80017430 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e7c:	4b11                	li	s6,4
      state = states[p->state];
    else
      state = "???";
    80002e7e:	00005997          	auipc	s3,0x5
    80002e82:	40298993          	addi	s3,s3,1026 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002e86:	00005a97          	auipc	s5,0x5
    80002e8a:	402a8a93          	addi	s5,s5,1026 # 80008288 <digits+0x248>
    printf("\n");
    80002e8e:	00005a17          	auipc	s4,0x5
    80002e92:	252a0a13          	addi	s4,s4,594 # 800080e0 <digits+0xa0>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002e96:	00005b97          	auipc	s7,0x5
    80002e9a:	42ab8b93          	addi	s7,s7,1066 # 800082c0 <states.1742>
    80002e9e:	a00d                	j	80002ec0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002ea0:	ee06a583          	lw	a1,-288(a3)
    80002ea4:	8556                	mv	a0,s5
    80002ea6:	ffffd097          	auipc	ra,0xffffd
    80002eaa:	6d4080e7          	jalr	1748(ra) # 8000057a <printf>
    printf("\n");
    80002eae:	8552                	mv	a0,s4
    80002eb0:	ffffd097          	auipc	ra,0xffffd
    80002eb4:	6ca080e7          	jalr	1738(ra) # 8000057a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002eb8:	17048493          	addi	s1,s1,368
    80002ebc:	03248163          	beq	s1,s2,80002ede <procdump+0x98>
    if(p->state == UNUSED)
    80002ec0:	86a6                	mv	a3,s1
    80002ec2:	ec04a783          	lw	a5,-320(s1)
    80002ec6:	dbed                	beqz	a5,80002eb8 <procdump+0x72>
      state = "???";
    80002ec8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002eca:	fcfb6be3          	bltu	s6,a5,80002ea0 <procdump+0x5a>
    80002ece:	1782                	slli	a5,a5,0x20
    80002ed0:	9381                	srli	a5,a5,0x20
    80002ed2:	078e                	slli	a5,a5,0x3
    80002ed4:	97de                	add	a5,a5,s7
    80002ed6:	6390                	ld	a2,0(a5)
    80002ed8:	f661                	bnez	a2,80002ea0 <procdump+0x5a>
      state = "???";
    80002eda:	864e                	mv	a2,s3
    80002edc:	b7d1                	j	80002ea0 <procdump+0x5a>
  }
}
    80002ede:	60a6                	ld	ra,72(sp)
    80002ee0:	6406                	ld	s0,64(sp)
    80002ee2:	74e2                	ld	s1,56(sp)
    80002ee4:	7942                	ld	s2,48(sp)
    80002ee6:	79a2                	ld	s3,40(sp)
    80002ee8:	7a02                	ld	s4,32(sp)
    80002eea:	6ae2                	ld	s5,24(sp)
    80002eec:	6b42                	ld	s6,16(sp)
    80002eee:	6ba2                	ld	s7,8(sp)
    80002ef0:	6161                	addi	sp,sp,80
    80002ef2:	8082                	ret

0000000080002ef4 <swtch>:
# Save current registers in old. Load from new.	


.globl swtch
swtch:
        sd ra, 0(a0)
    80002ef4:	00153023          	sd	ra,0(a0)
        sd sp, 8(a0)
    80002ef8:	00253423          	sd	sp,8(a0)
        sd s0, 16(a0)
    80002efc:	e900                	sd	s0,16(a0)
        sd s1, 24(a0)
    80002efe:	ed04                	sd	s1,24(a0)
        sd s2, 32(a0)
    80002f00:	03253023          	sd	s2,32(a0)
        sd s3, 40(a0)
    80002f04:	03353423          	sd	s3,40(a0)
        sd s4, 48(a0)
    80002f08:	03453823          	sd	s4,48(a0)
        sd s5, 56(a0)
    80002f0c:	03553c23          	sd	s5,56(a0)
        sd s6, 64(a0)
    80002f10:	05653023          	sd	s6,64(a0)
        sd s7, 72(a0)
    80002f14:	05753423          	sd	s7,72(a0)
        sd s8, 80(a0)
    80002f18:	05853823          	sd	s8,80(a0)
        sd s9, 88(a0)
    80002f1c:	05953c23          	sd	s9,88(a0)
        sd s10, 96(a0)
    80002f20:	07a53023          	sd	s10,96(a0)
        sd s11, 104(a0)
    80002f24:	07b53423          	sd	s11,104(a0)

        ld ra, 0(a1)
    80002f28:	0005b083          	ld	ra,0(a1)
        ld sp, 8(a1)
    80002f2c:	0085b103          	ld	sp,8(a1)
        ld s0, 16(a1)
    80002f30:	6980                	ld	s0,16(a1)
        ld s1, 24(a1)
    80002f32:	6d84                	ld	s1,24(a1)
        ld s2, 32(a1)
    80002f34:	0205b903          	ld	s2,32(a1)
        ld s3, 40(a1)
    80002f38:	0285b983          	ld	s3,40(a1)
        ld s4, 48(a1)
    80002f3c:	0305ba03          	ld	s4,48(a1)
        ld s5, 56(a1)
    80002f40:	0385ba83          	ld	s5,56(a1)
        ld s6, 64(a1)
    80002f44:	0405bb03          	ld	s6,64(a1)
        ld s7, 72(a1)
    80002f48:	0485bb83          	ld	s7,72(a1)
        ld s8, 80(a1)
    80002f4c:	0505bc03          	ld	s8,80(a1)
        ld s9, 88(a1)
    80002f50:	0585bc83          	ld	s9,88(a1)
        ld s10, 96(a1)
    80002f54:	0605bd03          	ld	s10,96(a1)
        ld s11, 104(a1)
    80002f58:	0685bd83          	ld	s11,104(a1)
        
        ret
    80002f5c:	8082                	ret

0000000080002f5e <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002f5e:	1141                	addi	sp,sp,-16
    80002f60:	e406                	sd	ra,8(sp)
    80002f62:	e022                	sd	s0,0(sp)
    80002f64:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002f66:	00005597          	auipc	a1,0x5
    80002f6a:	38258593          	addi	a1,a1,898 # 800082e8 <states.1742+0x28>
    80002f6e:	00014517          	auipc	a0,0x14
    80002f72:	36a50513          	addi	a0,a0,874 # 800172d8 <tickslock>
    80002f76:	ffffe097          	auipc	ra,0xffffe
    80002f7a:	d0e080e7          	jalr	-754(ra) # 80000c84 <initlock>
}
    80002f7e:	60a2                	ld	ra,8(sp)
    80002f80:	6402                	ld	s0,0(sp)
    80002f82:	0141                	addi	sp,sp,16
    80002f84:	8082                	ret

0000000080002f86 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002f86:	1141                	addi	sp,sp,-16
    80002f88:	e422                	sd	s0,8(sp)
    80002f8a:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002f8c:	00003797          	auipc	a5,0x3
    80002f90:	4f478793          	addi	a5,a5,1268 # 80006480 <kernelvec>
    80002f94:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002f98:	6422                	ld	s0,8(sp)
    80002f9a:	0141                	addi	sp,sp,16
    80002f9c:	8082                	ret

0000000080002f9e <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002f9e:	1141                	addi	sp,sp,-16
    80002fa0:	e406                	sd	ra,8(sp)
    80002fa2:	e022                	sd	s0,0(sp)
    80002fa4:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002fa6:	fffff097          	auipc	ra,0xfffff
    80002faa:	230080e7          	jalr	560(ra) # 800021d6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002fae:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002fb2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002fb4:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    80002fb8:	00004617          	auipc	a2,0x4
    80002fbc:	04860613          	addi	a2,a2,72 # 80007000 <_trampoline>
    80002fc0:	00004697          	auipc	a3,0x4
    80002fc4:	04068693          	addi	a3,a3,64 # 80007000 <_trampoline>
    80002fc8:	8e91                	sub	a3,a3,a2
    80002fca:	040007b7          	lui	a5,0x4000
    80002fce:	17fd                	addi	a5,a5,-1
    80002fd0:	07b2                	slli	a5,a5,0xc
    80002fd2:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002fd4:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002fd8:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002fda:	180026f3          	csrr	a3,satp
    80002fde:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002fe0:	6d38                	ld	a4,88(a0)
    80002fe2:	6134                	ld	a3,64(a0)
    80002fe4:	6585                	lui	a1,0x1
    80002fe6:	96ae                	add	a3,a3,a1
    80002fe8:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002fea:	6d38                	ld	a4,88(a0)
    80002fec:	00000697          	auipc	a3,0x0
    80002ff0:	13868693          	addi	a3,a3,312 # 80003124 <usertrap>
    80002ff4:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    80002ff6:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002ff8:	8692                	mv	a3,tp
    80002ffa:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ffc:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80003000:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80003004:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003008:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    8000300c:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    8000300e:	6f18                	ld	a4,24(a4)
    80003010:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80003014:	692c                	ld	a1,80(a0)
    80003016:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80003018:	00004717          	auipc	a4,0x4
    8000301c:	07870713          	addi	a4,a4,120 # 80007090 <userret>
    80003020:	8f11                	sub	a4,a4,a2
    80003022:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80003024:	577d                	li	a4,-1
    80003026:	177e                	slli	a4,a4,0x3f
    80003028:	8dd9                	or	a1,a1,a4
    8000302a:	02000537          	lui	a0,0x2000
    8000302e:	157d                	addi	a0,a0,-1
    80003030:	0536                	slli	a0,a0,0xd
    80003032:	9782                	jalr	a5
}
    80003034:	60a2                	ld	ra,8(sp)
    80003036:	6402                	ld	s0,0(sp)
    80003038:	0141                	addi	sp,sp,16
    8000303a:	8082                	ret

000000008000303c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000303c:	1101                	addi	sp,sp,-32
    8000303e:	ec06                	sd	ra,24(sp)
    80003040:	e822                	sd	s0,16(sp)
    80003042:	e426                	sd	s1,8(sp)
    80003044:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80003046:	00014497          	auipc	s1,0x14
    8000304a:	29248493          	addi	s1,s1,658 # 800172d8 <tickslock>
    8000304e:	8526                	mv	a0,s1
    80003050:	ffffe097          	auipc	ra,0xffffe
    80003054:	cc4080e7          	jalr	-828(ra) # 80000d14 <acquire>
  ticks++;
    80003058:	00006517          	auipc	a0,0x6
    8000305c:	fd850513          	addi	a0,a0,-40 # 80009030 <ticks>
    80003060:	411c                	lw	a5,0(a0)
    80003062:	2785                	addiw	a5,a5,1
    80003064:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80003066:	00000097          	auipc	ra,0x0
    8000306a:	c58080e7          	jalr	-936(ra) # 80002cbe <wakeup>
  release(&tickslock);
    8000306e:	8526                	mv	a0,s1
    80003070:	ffffe097          	auipc	ra,0xffffe
    80003074:	d58080e7          	jalr	-680(ra) # 80000dc8 <release>
}
    80003078:	60e2                	ld	ra,24(sp)
    8000307a:	6442                	ld	s0,16(sp)
    8000307c:	64a2                	ld	s1,8(sp)
    8000307e:	6105                	addi	sp,sp,32
    80003080:	8082                	ret

0000000080003082 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    80003082:	1101                	addi	sp,sp,-32
    80003084:	ec06                	sd	ra,24(sp)
    80003086:	e822                	sd	s0,16(sp)
    80003088:	e426                	sd	s1,8(sp)
    8000308a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000308c:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    80003090:	00074d63          	bltz	a4,800030aa <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80003094:	57fd                	li	a5,-1
    80003096:	17fe                	slli	a5,a5,0x3f
    80003098:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    8000309a:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    8000309c:	06f70363          	beq	a4,a5,80003102 <devintr+0x80>
  }
}
    800030a0:	60e2                	ld	ra,24(sp)
    800030a2:	6442                	ld	s0,16(sp)
    800030a4:	64a2                	ld	s1,8(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret
     (scause & 0xff) == 9){
    800030aa:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    800030ae:	46a5                	li	a3,9
    800030b0:	fed792e3          	bne	a5,a3,80003094 <devintr+0x12>
    int irq = plic_claim();
    800030b4:	00003097          	auipc	ra,0x3
    800030b8:	4d4080e7          	jalr	1236(ra) # 80006588 <plic_claim>
    800030bc:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800030be:	47a9                	li	a5,10
    800030c0:	02f50763          	beq	a0,a5,800030ee <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800030c4:	4785                	li	a5,1
    800030c6:	02f50963          	beq	a0,a5,800030f8 <devintr+0x76>
    return 1;
    800030ca:	4505                	li	a0,1
    } else if(irq){
    800030cc:	d8f1                	beqz	s1,800030a0 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800030ce:	85a6                	mv	a1,s1
    800030d0:	00005517          	auipc	a0,0x5
    800030d4:	22050513          	addi	a0,a0,544 # 800082f0 <states.1742+0x30>
    800030d8:	ffffd097          	auipc	ra,0xffffd
    800030dc:	4a2080e7          	jalr	1186(ra) # 8000057a <printf>
      plic_complete(irq);
    800030e0:	8526                	mv	a0,s1
    800030e2:	00003097          	auipc	ra,0x3
    800030e6:	4ca080e7          	jalr	1226(ra) # 800065ac <plic_complete>
    return 1;
    800030ea:	4505                	li	a0,1
    800030ec:	bf55                	j	800030a0 <devintr+0x1e>
      uartintr();
    800030ee:	ffffe097          	auipc	ra,0xffffe
    800030f2:	8ac080e7          	jalr	-1876(ra) # 8000099a <uartintr>
    800030f6:	b7ed                	j	800030e0 <devintr+0x5e>
      virtio_disk_intr();
    800030f8:	00004097          	auipc	ra,0x4
    800030fc:	994080e7          	jalr	-1644(ra) # 80006a8c <virtio_disk_intr>
    80003100:	b7c5                	j	800030e0 <devintr+0x5e>
    if(cpuid() == 0){
    80003102:	fffff097          	auipc	ra,0xfffff
    80003106:	0a8080e7          	jalr	168(ra) # 800021aa <cpuid>
    8000310a:	c901                	beqz	a0,8000311a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000310c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003110:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80003112:	14479073          	csrw	sip,a5
    return 2;
    80003116:	4509                	li	a0,2
    80003118:	b761                	j	800030a0 <devintr+0x1e>
      clockintr();
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	f22080e7          	jalr	-222(ra) # 8000303c <clockintr>
    80003122:	b7ed                	j	8000310c <devintr+0x8a>

0000000080003124 <usertrap>:
{
    80003124:	7179                	addi	sp,sp,-48
    80003126:	f406                	sd	ra,40(sp)
    80003128:	f022                	sd	s0,32(sp)
    8000312a:	ec26                	sd	s1,24(sp)
    8000312c:	e84a                	sd	s2,16(sp)
    8000312e:	e44e                	sd	s3,8(sp)
    80003130:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003132:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80003136:	1007f793          	andi	a5,a5,256
    8000313a:	e3b5                	bnez	a5,8000319e <usertrap+0x7a>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000313c:	00003797          	auipc	a5,0x3
    80003140:	34478793          	addi	a5,a5,836 # 80006480 <kernelvec>
    80003144:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80003148:	fffff097          	auipc	ra,0xfffff
    8000314c:	08e080e7          	jalr	142(ra) # 800021d6 <myproc>
    80003150:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80003152:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003154:	14102773          	csrr	a4,sepc
    80003158:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000315a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    8000315e:	47a1                	li	a5,8
    80003160:	04f71d63          	bne	a4,a5,800031ba <usertrap+0x96>
    if(p->killed)
    80003164:	591c                	lw	a5,48(a0)
    80003166:	e7a1                	bnez	a5,800031ae <usertrap+0x8a>
    p->trapframe->epc += 4;
    80003168:	6cb8                	ld	a4,88(s1)
    8000316a:	6f1c                	ld	a5,24(a4)
    8000316c:	0791                	addi	a5,a5,4
    8000316e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003170:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003174:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003178:	10079073          	csrw	sstatus,a5
    syscall();
    8000317c:	00000097          	auipc	ra,0x0
    80003180:	344080e7          	jalr	836(ra) # 800034c0 <syscall>
  if(p->killed)
    80003184:	589c                	lw	a5,48(s1)
    80003186:	eff1                	bnez	a5,80003262 <usertrap+0x13e>
  usertrapret();
    80003188:	00000097          	auipc	ra,0x0
    8000318c:	e16080e7          	jalr	-490(ra) # 80002f9e <usertrapret>
}
    80003190:	70a2                	ld	ra,40(sp)
    80003192:	7402                	ld	s0,32(sp)
    80003194:	64e2                	ld	s1,24(sp)
    80003196:	6942                	ld	s2,16(sp)
    80003198:	69a2                	ld	s3,8(sp)
    8000319a:	6145                	addi	sp,sp,48
    8000319c:	8082                	ret
    panic("usertrap: not from user mode");
    8000319e:	00005517          	auipc	a0,0x5
    800031a2:	17250513          	addi	a0,a0,370 # 80008310 <states.1742+0x50>
    800031a6:	ffffd097          	auipc	ra,0xffffd
    800031aa:	38a080e7          	jalr	906(ra) # 80000530 <panic>
      exit(-1);
    800031ae:	557d                	li	a0,-1
    800031b0:	fffff097          	auipc	ra,0xfffff
    800031b4:	7d8080e7          	jalr	2008(ra) # 80002988 <exit>
    800031b8:	bf45                	j	80003168 <usertrap+0x44>
  } else if((which_dev = devintr()) != 0){
    800031ba:	00000097          	auipc	ra,0x0
    800031be:	ec8080e7          	jalr	-312(ra) # 80003082 <devintr>
    800031c2:	892a                	mv	s2,a0
    800031c4:	ed41                	bnez	a0,8000325c <usertrap+0x138>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031c6:	14202773          	csrr	a4,scause
  } else if (r_scause() == 13 || r_scause() == 15){
    800031ca:	47b5                	li	a5,13
    800031cc:	00f70763          	beq	a4,a5,800031da <usertrap+0xb6>
    800031d0:	14202773          	csrr	a4,scause
    800031d4:	47bd                	li	a5,15
    800031d6:	04f71963          	bne	a4,a5,80003228 <usertrap+0x104>
  asm volatile("csrr %0, stval" : "=r" (x) );
    800031da:	143029f3          	csrr	s3,stval
    if (pagefault_handler(myproc()->pagetable, va) != 0) 
    800031de:	fffff097          	auipc	ra,0xfffff
    800031e2:	ff8080e7          	jalr	-8(ra) # 800021d6 <myproc>
    800031e6:	85ce                	mv	a1,s3
    800031e8:	6928                	ld	a0,80(a0)
    800031ea:	fffff097          	auipc	ra,0xfffff
    800031ee:	8bc080e7          	jalr	-1860(ra) # 80001aa6 <pagefault_handler>
    800031f2:	d949                	beqz	a0,80003184 <usertrap+0x60>
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031f4:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    800031f8:	5c90                	lw	a2,56(s1)
    800031fa:	00005517          	auipc	a0,0x5
    800031fe:	13650513          	addi	a0,a0,310 # 80008330 <states.1742+0x70>
    80003202:	ffffd097          	auipc	ra,0xffffd
    80003206:	378080e7          	jalr	888(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000320a:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000320e:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003212:	00005517          	auipc	a0,0x5
    80003216:	14e50513          	addi	a0,a0,334 # 80008360 <states.1742+0xa0>
    8000321a:	ffffd097          	auipc	ra,0xffffd
    8000321e:	360080e7          	jalr	864(ra) # 8000057a <printf>
      p->killed = 1;
    80003222:	4785                	li	a5,1
    80003224:	d89c                	sw	a5,48(s1)
    80003226:	a83d                	j	80003264 <usertrap+0x140>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003228:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    8000322c:	5c90                	lw	a2,56(s1)
    8000322e:	00005517          	auipc	a0,0x5
    80003232:	10250513          	addi	a0,a0,258 # 80008330 <states.1742+0x70>
    80003236:	ffffd097          	auipc	ra,0xffffd
    8000323a:	344080e7          	jalr	836(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000323e:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003242:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003246:	00005517          	auipc	a0,0x5
    8000324a:	11a50513          	addi	a0,a0,282 # 80008360 <states.1742+0xa0>
    8000324e:	ffffd097          	auipc	ra,0xffffd
    80003252:	32c080e7          	jalr	812(ra) # 8000057a <printf>
    p->killed = 1;
    80003256:	4785                	li	a5,1
    80003258:	d89c                	sw	a5,48(s1)
    8000325a:	a029                	j	80003264 <usertrap+0x140>
  if(p->killed)
    8000325c:	589c                	lw	a5,48(s1)
    8000325e:	cb81                	beqz	a5,8000326e <usertrap+0x14a>
    80003260:	a011                	j	80003264 <usertrap+0x140>
    80003262:	4901                	li	s2,0
    exit(-1);
    80003264:	557d                	li	a0,-1
    80003266:	fffff097          	auipc	ra,0xfffff
    8000326a:	722080e7          	jalr	1826(ra) # 80002988 <exit>
  if(which_dev == 2)
    8000326e:	4789                	li	a5,2
    80003270:	f0f91ce3          	bne	s2,a5,80003188 <usertrap+0x64>
    yield();
    80003274:	00000097          	auipc	ra,0x0
    80003278:	888080e7          	jalr	-1912(ra) # 80002afc <yield>
    8000327c:	b731                	j	80003188 <usertrap+0x64>

000000008000327e <kerneltrap>:
{
    8000327e:	7179                	addi	sp,sp,-48
    80003280:	f406                	sd	ra,40(sp)
    80003282:	f022                	sd	s0,32(sp)
    80003284:	ec26                	sd	s1,24(sp)
    80003286:	e84a                	sd	s2,16(sp)
    80003288:	e44e                	sd	s3,8(sp)
    8000328a:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000328c:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003290:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003294:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80003298:	1004f793          	andi	a5,s1,256
    8000329c:	cb85                	beqz	a5,800032cc <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000329e:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800032a2:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800032a4:	ef85                	bnez	a5,800032dc <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800032a6:	00000097          	auipc	ra,0x0
    800032aa:	ddc080e7          	jalr	-548(ra) # 80003082 <devintr>
    800032ae:	cd1d                	beqz	a0,800032ec <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800032b0:	4789                	li	a5,2
    800032b2:	06f50a63          	beq	a0,a5,80003326 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800032b6:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800032ba:	10049073          	csrw	sstatus,s1
}
    800032be:	70a2                	ld	ra,40(sp)
    800032c0:	7402                	ld	s0,32(sp)
    800032c2:	64e2                	ld	s1,24(sp)
    800032c4:	6942                	ld	s2,16(sp)
    800032c6:	69a2                	ld	s3,8(sp)
    800032c8:	6145                	addi	sp,sp,48
    800032ca:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800032cc:	00005517          	auipc	a0,0x5
    800032d0:	0b450513          	addi	a0,a0,180 # 80008380 <states.1742+0xc0>
    800032d4:	ffffd097          	auipc	ra,0xffffd
    800032d8:	25c080e7          	jalr	604(ra) # 80000530 <panic>
    panic("kerneltrap: interrupts enabled");
    800032dc:	00005517          	auipc	a0,0x5
    800032e0:	0cc50513          	addi	a0,a0,204 # 800083a8 <states.1742+0xe8>
    800032e4:	ffffd097          	auipc	ra,0xffffd
    800032e8:	24c080e7          	jalr	588(ra) # 80000530 <panic>
    printf("scause %p\n", scause);
    800032ec:	85ce                	mv	a1,s3
    800032ee:	00005517          	auipc	a0,0x5
    800032f2:	0da50513          	addi	a0,a0,218 # 800083c8 <states.1742+0x108>
    800032f6:	ffffd097          	auipc	ra,0xffffd
    800032fa:	284080e7          	jalr	644(ra) # 8000057a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800032fe:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003302:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80003306:	00005517          	auipc	a0,0x5
    8000330a:	0d250513          	addi	a0,a0,210 # 800083d8 <states.1742+0x118>
    8000330e:	ffffd097          	auipc	ra,0xffffd
    80003312:	26c080e7          	jalr	620(ra) # 8000057a <printf>
    panic("kerneltrap");
    80003316:	00005517          	auipc	a0,0x5
    8000331a:	0da50513          	addi	a0,a0,218 # 800083f0 <states.1742+0x130>
    8000331e:	ffffd097          	auipc	ra,0xffffd
    80003322:	212080e7          	jalr	530(ra) # 80000530 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80003326:	fffff097          	auipc	ra,0xfffff
    8000332a:	eb0080e7          	jalr	-336(ra) # 800021d6 <myproc>
    8000332e:	d541                	beqz	a0,800032b6 <kerneltrap+0x38>
    80003330:	fffff097          	auipc	ra,0xfffff
    80003334:	ea6080e7          	jalr	-346(ra) # 800021d6 <myproc>
    80003338:	4d18                	lw	a4,24(a0)
    8000333a:	478d                	li	a5,3
    8000333c:	f6f71de3          	bne	a4,a5,800032b6 <kerneltrap+0x38>
    yield();
    80003340:	fffff097          	auipc	ra,0xfffff
    80003344:	7bc080e7          	jalr	1980(ra) # 80002afc <yield>
    80003348:	b7bd                	j	800032b6 <kerneltrap+0x38>

000000008000334a <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000334a:	1101                	addi	sp,sp,-32
    8000334c:	ec06                	sd	ra,24(sp)
    8000334e:	e822                	sd	s0,16(sp)
    80003350:	e426                	sd	s1,8(sp)
    80003352:	1000                	addi	s0,sp,32
    80003354:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80003356:	fffff097          	auipc	ra,0xfffff
    8000335a:	e80080e7          	jalr	-384(ra) # 800021d6 <myproc>
  switch (n) {
    8000335e:	4795                	li	a5,5
    80003360:	0497e163          	bltu	a5,s1,800033a2 <argraw+0x58>
    80003364:	048a                	slli	s1,s1,0x2
    80003366:	00005717          	auipc	a4,0x5
    8000336a:	0c270713          	addi	a4,a4,194 # 80008428 <states.1742+0x168>
    8000336e:	94ba                	add	s1,s1,a4
    80003370:	409c                	lw	a5,0(s1)
    80003372:	97ba                	add	a5,a5,a4
    80003374:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80003376:	6d3c                	ld	a5,88(a0)
    80003378:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000337a:	60e2                	ld	ra,24(sp)
    8000337c:	6442                	ld	s0,16(sp)
    8000337e:	64a2                	ld	s1,8(sp)
    80003380:	6105                	addi	sp,sp,32
    80003382:	8082                	ret
    return p->trapframe->a1;
    80003384:	6d3c                	ld	a5,88(a0)
    80003386:	7fa8                	ld	a0,120(a5)
    80003388:	bfcd                	j	8000337a <argraw+0x30>
    return p->trapframe->a2;
    8000338a:	6d3c                	ld	a5,88(a0)
    8000338c:	63c8                	ld	a0,128(a5)
    8000338e:	b7f5                	j	8000337a <argraw+0x30>
    return p->trapframe->a3;
    80003390:	6d3c                	ld	a5,88(a0)
    80003392:	67c8                	ld	a0,136(a5)
    80003394:	b7dd                	j	8000337a <argraw+0x30>
    return p->trapframe->a4;
    80003396:	6d3c                	ld	a5,88(a0)
    80003398:	6bc8                	ld	a0,144(a5)
    8000339a:	b7c5                	j	8000337a <argraw+0x30>
    return p->trapframe->a5;
    8000339c:	6d3c                	ld	a5,88(a0)
    8000339e:	6fc8                	ld	a0,152(a5)
    800033a0:	bfe9                	j	8000337a <argraw+0x30>
  panic("argraw");
    800033a2:	00005517          	auipc	a0,0x5
    800033a6:	05e50513          	addi	a0,a0,94 # 80008400 <states.1742+0x140>
    800033aa:	ffffd097          	auipc	ra,0xffffd
    800033ae:	186080e7          	jalr	390(ra) # 80000530 <panic>

00000000800033b2 <fetchaddr>:
{
    800033b2:	1101                	addi	sp,sp,-32
    800033b4:	ec06                	sd	ra,24(sp)
    800033b6:	e822                	sd	s0,16(sp)
    800033b8:	e426                	sd	s1,8(sp)
    800033ba:	e04a                	sd	s2,0(sp)
    800033bc:	1000                	addi	s0,sp,32
    800033be:	84aa                	mv	s1,a0
    800033c0:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800033c2:	fffff097          	auipc	ra,0xfffff
    800033c6:	e14080e7          	jalr	-492(ra) # 800021d6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    800033ca:	653c                	ld	a5,72(a0)
    800033cc:	02f4f863          	bgeu	s1,a5,800033fc <fetchaddr+0x4a>
    800033d0:	00848713          	addi	a4,s1,8
    800033d4:	02e7e663          	bltu	a5,a4,80003400 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800033d8:	46a1                	li	a3,8
    800033da:	8626                	mv	a2,s1
    800033dc:	85ca                	mv	a1,s2
    800033de:	6928                	ld	a0,80(a0)
    800033e0:	fffff097          	auipc	ra,0xfffff
    800033e4:	85c080e7          	jalr	-1956(ra) # 80001c3c <copyin>
    800033e8:	00a03533          	snez	a0,a0
    800033ec:	40a00533          	neg	a0,a0
}
    800033f0:	60e2                	ld	ra,24(sp)
    800033f2:	6442                	ld	s0,16(sp)
    800033f4:	64a2                	ld	s1,8(sp)
    800033f6:	6902                	ld	s2,0(sp)
    800033f8:	6105                	addi	sp,sp,32
    800033fa:	8082                	ret
    return -1;
    800033fc:	557d                	li	a0,-1
    800033fe:	bfcd                	j	800033f0 <fetchaddr+0x3e>
    80003400:	557d                	li	a0,-1
    80003402:	b7fd                	j	800033f0 <fetchaddr+0x3e>

0000000080003404 <fetchstr>:
{
    80003404:	7179                	addi	sp,sp,-48
    80003406:	f406                	sd	ra,40(sp)
    80003408:	f022                	sd	s0,32(sp)
    8000340a:	ec26                	sd	s1,24(sp)
    8000340c:	e84a                	sd	s2,16(sp)
    8000340e:	e44e                	sd	s3,8(sp)
    80003410:	1800                	addi	s0,sp,48
    80003412:	892a                	mv	s2,a0
    80003414:	84ae                	mv	s1,a1
    80003416:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80003418:	fffff097          	auipc	ra,0xfffff
    8000341c:	dbe080e7          	jalr	-578(ra) # 800021d6 <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80003420:	86ce                	mv	a3,s3
    80003422:	864a                	mv	a2,s2
    80003424:	85a6                	mv	a1,s1
    80003426:	6928                	ld	a0,80(a0)
    80003428:	fffff097          	auipc	ra,0xfffff
    8000342c:	8ba080e7          	jalr	-1862(ra) # 80001ce2 <copyinstr>
  if(err < 0)
    80003430:	00054763          	bltz	a0,8000343e <fetchstr+0x3a>
  return strlen(buf);
    80003434:	8526                	mv	a0,s1
    80003436:	ffffe097          	auipc	ra,0xffffe
    8000343a:	b62080e7          	jalr	-1182(ra) # 80000f98 <strlen>
}
    8000343e:	70a2                	ld	ra,40(sp)
    80003440:	7402                	ld	s0,32(sp)
    80003442:	64e2                	ld	s1,24(sp)
    80003444:	6942                	ld	s2,16(sp)
    80003446:	69a2                	ld	s3,8(sp)
    80003448:	6145                	addi	sp,sp,48
    8000344a:	8082                	ret

000000008000344c <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    8000344c:	1101                	addi	sp,sp,-32
    8000344e:	ec06                	sd	ra,24(sp)
    80003450:	e822                	sd	s0,16(sp)
    80003452:	e426                	sd	s1,8(sp)
    80003454:	1000                	addi	s0,sp,32
    80003456:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003458:	00000097          	auipc	ra,0x0
    8000345c:	ef2080e7          	jalr	-270(ra) # 8000334a <argraw>
    80003460:	c088                	sw	a0,0(s1)
  return 0;
}
    80003462:	4501                	li	a0,0
    80003464:	60e2                	ld	ra,24(sp)
    80003466:	6442                	ld	s0,16(sp)
    80003468:	64a2                	ld	s1,8(sp)
    8000346a:	6105                	addi	sp,sp,32
    8000346c:	8082                	ret

000000008000346e <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    8000346e:	1101                	addi	sp,sp,-32
    80003470:	ec06                	sd	ra,24(sp)
    80003472:	e822                	sd	s0,16(sp)
    80003474:	e426                	sd	s1,8(sp)
    80003476:	1000                	addi	s0,sp,32
    80003478:	84ae                	mv	s1,a1
  *ip = argraw(n);
    8000347a:	00000097          	auipc	ra,0x0
    8000347e:	ed0080e7          	jalr	-304(ra) # 8000334a <argraw>
    80003482:	e088                	sd	a0,0(s1)
  return 0;
}
    80003484:	4501                	li	a0,0
    80003486:	60e2                	ld	ra,24(sp)
    80003488:	6442                	ld	s0,16(sp)
    8000348a:	64a2                	ld	s1,8(sp)
    8000348c:	6105                	addi	sp,sp,32
    8000348e:	8082                	ret

0000000080003490 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003490:	1101                	addi	sp,sp,-32
    80003492:	ec06                	sd	ra,24(sp)
    80003494:	e822                	sd	s0,16(sp)
    80003496:	e426                	sd	s1,8(sp)
    80003498:	e04a                	sd	s2,0(sp)
    8000349a:	1000                	addi	s0,sp,32
    8000349c:	84ae                	mv	s1,a1
    8000349e:	8932                	mv	s2,a2
  *ip = argraw(n);
    800034a0:	00000097          	auipc	ra,0x0
    800034a4:	eaa080e7          	jalr	-342(ra) # 8000334a <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    800034a8:	864a                	mv	a2,s2
    800034aa:	85a6                	mv	a1,s1
    800034ac:	00000097          	auipc	ra,0x0
    800034b0:	f58080e7          	jalr	-168(ra) # 80003404 <fetchstr>
}
    800034b4:	60e2                	ld	ra,24(sp)
    800034b6:	6442                	ld	s0,16(sp)
    800034b8:	64a2                	ld	s1,8(sp)
    800034ba:	6902                	ld	s2,0(sp)
    800034bc:	6105                	addi	sp,sp,32
    800034be:	8082                	ret

00000000800034c0 <syscall>:
[SYS_munmap]  sys_munmap
};

void
syscall(void)
{
    800034c0:	1101                	addi	sp,sp,-32
    800034c2:	ec06                	sd	ra,24(sp)
    800034c4:	e822                	sd	s0,16(sp)
    800034c6:	e426                	sd	s1,8(sp)
    800034c8:	e04a                	sd	s2,0(sp)
    800034ca:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800034cc:	fffff097          	auipc	ra,0xfffff
    800034d0:	d0a080e7          	jalr	-758(ra) # 800021d6 <myproc>
    800034d4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800034d6:	05853903          	ld	s2,88(a0)
    800034da:	0a893783          	ld	a5,168(s2)
    800034de:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800034e2:	37fd                	addiw	a5,a5,-1
    800034e4:	4759                	li	a4,22
    800034e6:	00f76f63          	bltu	a4,a5,80003504 <syscall+0x44>
    800034ea:	00369713          	slli	a4,a3,0x3
    800034ee:	00005797          	auipc	a5,0x5
    800034f2:	f5278793          	addi	a5,a5,-174 # 80008440 <syscalls>
    800034f6:	97ba                	add	a5,a5,a4
    800034f8:	639c                	ld	a5,0(a5)
    800034fa:	c789                	beqz	a5,80003504 <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    800034fc:	9782                	jalr	a5
    800034fe:	06a93823          	sd	a0,112(s2)
    80003502:	a839                	j	80003520 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003504:	15848613          	addi	a2,s1,344
    80003508:	5c8c                	lw	a1,56(s1)
    8000350a:	00005517          	auipc	a0,0x5
    8000350e:	efe50513          	addi	a0,a0,-258 # 80008408 <states.1742+0x148>
    80003512:	ffffd097          	auipc	ra,0xffffd
    80003516:	068080e7          	jalr	104(ra) # 8000057a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    8000351a:	6cbc                	ld	a5,88(s1)
    8000351c:	577d                	li	a4,-1
    8000351e:	fbb8                	sd	a4,112(a5)
  }
}
    80003520:	60e2                	ld	ra,24(sp)
    80003522:	6442                	ld	s0,16(sp)
    80003524:	64a2                	ld	s1,8(sp)
    80003526:	6902                	ld	s2,0(sp)
    80003528:	6105                	addi	sp,sp,32
    8000352a:	8082                	ret

000000008000352c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    8000352c:	1101                	addi	sp,sp,-32
    8000352e:	ec06                	sd	ra,24(sp)
    80003530:	e822                	sd	s0,16(sp)
    80003532:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80003534:	fec40593          	addi	a1,s0,-20
    80003538:	4501                	li	a0,0
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	f12080e7          	jalr	-238(ra) # 8000344c <argint>
    return -1;
    80003542:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003544:	00054963          	bltz	a0,80003556 <sys_exit+0x2a>
  exit(n);
    80003548:	fec42503          	lw	a0,-20(s0)
    8000354c:	fffff097          	auipc	ra,0xfffff
    80003550:	43c080e7          	jalr	1084(ra) # 80002988 <exit>
  return 0;  // not reached
    80003554:	4781                	li	a5,0
}
    80003556:	853e                	mv	a0,a5
    80003558:	60e2                	ld	ra,24(sp)
    8000355a:	6442                	ld	s0,16(sp)
    8000355c:	6105                	addi	sp,sp,32
    8000355e:	8082                	ret

0000000080003560 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003560:	1141                	addi	sp,sp,-16
    80003562:	e406                	sd	ra,8(sp)
    80003564:	e022                	sd	s0,0(sp)
    80003566:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003568:	fffff097          	auipc	ra,0xfffff
    8000356c:	c6e080e7          	jalr	-914(ra) # 800021d6 <myproc>
}
    80003570:	5d08                	lw	a0,56(a0)
    80003572:	60a2                	ld	ra,8(sp)
    80003574:	6402                	ld	s0,0(sp)
    80003576:	0141                	addi	sp,sp,16
    80003578:	8082                	ret

000000008000357a <sys_fork>:

uint64
sys_fork(void)
{
    8000357a:	1141                	addi	sp,sp,-16
    8000357c:	e406                	sd	ra,8(sp)
    8000357e:	e022                	sd	s0,0(sp)
    80003580:	0800                	addi	s0,sp,16
  return fork();
    80003582:	fffff097          	auipc	ra,0xfffff
    80003586:	018080e7          	jalr	24(ra) # 8000259a <fork>
}
    8000358a:	60a2                	ld	ra,8(sp)
    8000358c:	6402                	ld	s0,0(sp)
    8000358e:	0141                	addi	sp,sp,16
    80003590:	8082                	ret

0000000080003592 <sys_wait>:

uint64
sys_wait(void)
{
    80003592:	1101                	addi	sp,sp,-32
    80003594:	ec06                	sd	ra,24(sp)
    80003596:	e822                	sd	s0,16(sp)
    80003598:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    8000359a:	fe840593          	addi	a1,s0,-24
    8000359e:	4501                	li	a0,0
    800035a0:	00000097          	auipc	ra,0x0
    800035a4:	ece080e7          	jalr	-306(ra) # 8000346e <argaddr>
    800035a8:	87aa                	mv	a5,a0
    return -1;
    800035aa:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    800035ac:	0007c863          	bltz	a5,800035bc <sys_wait+0x2a>
  return wait(p);
    800035b0:	fe843503          	ld	a0,-24(s0)
    800035b4:	fffff097          	auipc	ra,0xfffff
    800035b8:	602080e7          	jalr	1538(ra) # 80002bb6 <wait>
}
    800035bc:	60e2                	ld	ra,24(sp)
    800035be:	6442                	ld	s0,16(sp)
    800035c0:	6105                	addi	sp,sp,32
    800035c2:	8082                	ret

00000000800035c4 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    800035c4:	7179                	addi	sp,sp,-48
    800035c6:	f406                	sd	ra,40(sp)
    800035c8:	f022                	sd	s0,32(sp)
    800035ca:	ec26                	sd	s1,24(sp)
    800035cc:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    800035ce:	fdc40593          	addi	a1,s0,-36
    800035d2:	4501                	li	a0,0
    800035d4:	00000097          	auipc	ra,0x0
    800035d8:	e78080e7          	jalr	-392(ra) # 8000344c <argint>
    800035dc:	87aa                	mv	a5,a0
    return -1;
    800035de:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    800035e0:	0207c063          	bltz	a5,80003600 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    800035e4:	fffff097          	auipc	ra,0xfffff
    800035e8:	bf2080e7          	jalr	-1038(ra) # 800021d6 <myproc>
    800035ec:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    800035ee:	fdc42503          	lw	a0,-36(s0)
    800035f2:	fffff097          	auipc	ra,0xfffff
    800035f6:	f34080e7          	jalr	-204(ra) # 80002526 <growproc>
    800035fa:	00054863          	bltz	a0,8000360a <sys_sbrk+0x46>
    return -1;
  return addr;
    800035fe:	8526                	mv	a0,s1
}
    80003600:	70a2                	ld	ra,40(sp)
    80003602:	7402                	ld	s0,32(sp)
    80003604:	64e2                	ld	s1,24(sp)
    80003606:	6145                	addi	sp,sp,48
    80003608:	8082                	ret
    return -1;
    8000360a:	557d                	li	a0,-1
    8000360c:	bfd5                	j	80003600 <sys_sbrk+0x3c>

000000008000360e <sys_sleep>:

uint64
sys_sleep(void)
{
    8000360e:	7139                	addi	sp,sp,-64
    80003610:	fc06                	sd	ra,56(sp)
    80003612:	f822                	sd	s0,48(sp)
    80003614:	f426                	sd	s1,40(sp)
    80003616:	f04a                	sd	s2,32(sp)
    80003618:	ec4e                	sd	s3,24(sp)
    8000361a:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    8000361c:	fcc40593          	addi	a1,s0,-52
    80003620:	4501                	li	a0,0
    80003622:	00000097          	auipc	ra,0x0
    80003626:	e2a080e7          	jalr	-470(ra) # 8000344c <argint>
    return -1;
    8000362a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    8000362c:	06054563          	bltz	a0,80003696 <sys_sleep+0x88>
  acquire(&tickslock);
    80003630:	00014517          	auipc	a0,0x14
    80003634:	ca850513          	addi	a0,a0,-856 # 800172d8 <tickslock>
    80003638:	ffffd097          	auipc	ra,0xffffd
    8000363c:	6dc080e7          	jalr	1756(ra) # 80000d14 <acquire>
  ticks0 = ticks;
    80003640:	00006917          	auipc	s2,0x6
    80003644:	9f092903          	lw	s2,-1552(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003648:	fcc42783          	lw	a5,-52(s0)
    8000364c:	cf85                	beqz	a5,80003684 <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    8000364e:	00014997          	auipc	s3,0x14
    80003652:	c8a98993          	addi	s3,s3,-886 # 800172d8 <tickslock>
    80003656:	00006497          	auipc	s1,0x6
    8000365a:	9da48493          	addi	s1,s1,-1574 # 80009030 <ticks>
    if(myproc()->killed){
    8000365e:	fffff097          	auipc	ra,0xfffff
    80003662:	b78080e7          	jalr	-1160(ra) # 800021d6 <myproc>
    80003666:	591c                	lw	a5,48(a0)
    80003668:	ef9d                	bnez	a5,800036a6 <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    8000366a:	85ce                	mv	a1,s3
    8000366c:	8526                	mv	a0,s1
    8000366e:	fffff097          	auipc	ra,0xfffff
    80003672:	4ca080e7          	jalr	1226(ra) # 80002b38 <sleep>
  while(ticks - ticks0 < n){
    80003676:	409c                	lw	a5,0(s1)
    80003678:	412787bb          	subw	a5,a5,s2
    8000367c:	fcc42703          	lw	a4,-52(s0)
    80003680:	fce7efe3          	bltu	a5,a4,8000365e <sys_sleep+0x50>
  }
  release(&tickslock);
    80003684:	00014517          	auipc	a0,0x14
    80003688:	c5450513          	addi	a0,a0,-940 # 800172d8 <tickslock>
    8000368c:	ffffd097          	auipc	ra,0xffffd
    80003690:	73c080e7          	jalr	1852(ra) # 80000dc8 <release>
  return 0;
    80003694:	4781                	li	a5,0
}
    80003696:	853e                	mv	a0,a5
    80003698:	70e2                	ld	ra,56(sp)
    8000369a:	7442                	ld	s0,48(sp)
    8000369c:	74a2                	ld	s1,40(sp)
    8000369e:	7902                	ld	s2,32(sp)
    800036a0:	69e2                	ld	s3,24(sp)
    800036a2:	6121                	addi	sp,sp,64
    800036a4:	8082                	ret
      release(&tickslock);
    800036a6:	00014517          	auipc	a0,0x14
    800036aa:	c3250513          	addi	a0,a0,-974 # 800172d8 <tickslock>
    800036ae:	ffffd097          	auipc	ra,0xffffd
    800036b2:	71a080e7          	jalr	1818(ra) # 80000dc8 <release>
      return -1;
    800036b6:	57fd                	li	a5,-1
    800036b8:	bff9                	j	80003696 <sys_sleep+0x88>

00000000800036ba <sys_kill>:

uint64
sys_kill(void)
{
    800036ba:	1101                	addi	sp,sp,-32
    800036bc:	ec06                	sd	ra,24(sp)
    800036be:	e822                	sd	s0,16(sp)
    800036c0:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800036c2:	fec40593          	addi	a1,s0,-20
    800036c6:	4501                	li	a0,0
    800036c8:	00000097          	auipc	ra,0x0
    800036cc:	d84080e7          	jalr	-636(ra) # 8000344c <argint>
    800036d0:	87aa                	mv	a5,a0
    return -1;
    800036d2:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800036d4:	0007c863          	bltz	a5,800036e4 <sys_kill+0x2a>
  return kill(pid);
    800036d8:	fec42503          	lw	a0,-20(s0)
    800036dc:	fffff097          	auipc	ra,0xfffff
    800036e0:	64c080e7          	jalr	1612(ra) # 80002d28 <kill>
}
    800036e4:	60e2                	ld	ra,24(sp)
    800036e6:	6442                	ld	s0,16(sp)
    800036e8:	6105                	addi	sp,sp,32
    800036ea:	8082                	ret

00000000800036ec <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800036ec:	1101                	addi	sp,sp,-32
    800036ee:	ec06                	sd	ra,24(sp)
    800036f0:	e822                	sd	s0,16(sp)
    800036f2:	e426                	sd	s1,8(sp)
    800036f4:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800036f6:	00014517          	auipc	a0,0x14
    800036fa:	be250513          	addi	a0,a0,-1054 # 800172d8 <tickslock>
    800036fe:	ffffd097          	auipc	ra,0xffffd
    80003702:	616080e7          	jalr	1558(ra) # 80000d14 <acquire>
  xticks = ticks;
    80003706:	00006497          	auipc	s1,0x6
    8000370a:	92a4a483          	lw	s1,-1750(s1) # 80009030 <ticks>
  release(&tickslock);
    8000370e:	00014517          	auipc	a0,0x14
    80003712:	bca50513          	addi	a0,a0,-1078 # 800172d8 <tickslock>
    80003716:	ffffd097          	auipc	ra,0xffffd
    8000371a:	6b2080e7          	jalr	1714(ra) # 80000dc8 <release>
  return xticks;
}
    8000371e:	02049513          	slli	a0,s1,0x20
    80003722:	9101                	srli	a0,a0,0x20
    80003724:	60e2                	ld	ra,24(sp)
    80003726:	6442                	ld	s0,16(sp)
    80003728:	64a2                	ld	s1,8(sp)
    8000372a:	6105                	addi	sp,sp,32
    8000372c:	8082                	ret

000000008000372e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000372e:	7179                	addi	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	e052                	sd	s4,0(sp)
    8000373c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000373e:	00005597          	auipc	a1,0x5
    80003742:	dc258593          	addi	a1,a1,-574 # 80008500 <syscalls+0xc0>
    80003746:	00014517          	auipc	a0,0x14
    8000374a:	baa50513          	addi	a0,a0,-1110 # 800172f0 <bcache>
    8000374e:	ffffd097          	auipc	ra,0xffffd
    80003752:	536080e7          	jalr	1334(ra) # 80000c84 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003756:	0001c797          	auipc	a5,0x1c
    8000375a:	b9a78793          	addi	a5,a5,-1126 # 8001f2f0 <bcache+0x8000>
    8000375e:	0001c717          	auipc	a4,0x1c
    80003762:	dfa70713          	addi	a4,a4,-518 # 8001f558 <bcache+0x8268>
    80003766:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000376a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000376e:	00014497          	auipc	s1,0x14
    80003772:	b9a48493          	addi	s1,s1,-1126 # 80017308 <bcache+0x18>
    b->next = bcache.head.next;
    80003776:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003778:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000377a:	00005a17          	auipc	s4,0x5
    8000377e:	d8ea0a13          	addi	s4,s4,-626 # 80008508 <syscalls+0xc8>
    b->next = bcache.head.next;
    80003782:	2b893783          	ld	a5,696(s2)
    80003786:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003788:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    8000378c:	85d2                	mv	a1,s4
    8000378e:	01048513          	addi	a0,s1,16
    80003792:	00001097          	auipc	ra,0x1
    80003796:	4c4080e7          	jalr	1220(ra) # 80004c56 <initsleeplock>
    bcache.head.next->prev = b;
    8000379a:	2b893783          	ld	a5,696(s2)
    8000379e:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800037a0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800037a4:	45848493          	addi	s1,s1,1112
    800037a8:	fd349de3          	bne	s1,s3,80003782 <binit+0x54>
  }
}
    800037ac:	70a2                	ld	ra,40(sp)
    800037ae:	7402                	ld	s0,32(sp)
    800037b0:	64e2                	ld	s1,24(sp)
    800037b2:	6942                	ld	s2,16(sp)
    800037b4:	69a2                	ld	s3,8(sp)
    800037b6:	6a02                	ld	s4,0(sp)
    800037b8:	6145                	addi	sp,sp,48
    800037ba:	8082                	ret

00000000800037bc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800037bc:	7179                	addi	sp,sp,-48
    800037be:	f406                	sd	ra,40(sp)
    800037c0:	f022                	sd	s0,32(sp)
    800037c2:	ec26                	sd	s1,24(sp)
    800037c4:	e84a                	sd	s2,16(sp)
    800037c6:	e44e                	sd	s3,8(sp)
    800037c8:	1800                	addi	s0,sp,48
    800037ca:	89aa                	mv	s3,a0
    800037cc:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800037ce:	00014517          	auipc	a0,0x14
    800037d2:	b2250513          	addi	a0,a0,-1246 # 800172f0 <bcache>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	53e080e7          	jalr	1342(ra) # 80000d14 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800037de:	0001c497          	auipc	s1,0x1c
    800037e2:	dca4b483          	ld	s1,-566(s1) # 8001f5a8 <bcache+0x82b8>
    800037e6:	0001c797          	auipc	a5,0x1c
    800037ea:	d7278793          	addi	a5,a5,-654 # 8001f558 <bcache+0x8268>
    800037ee:	02f48f63          	beq	s1,a5,8000382c <bread+0x70>
    800037f2:	873e                	mv	a4,a5
    800037f4:	a021                	j	800037fc <bread+0x40>
    800037f6:	68a4                	ld	s1,80(s1)
    800037f8:	02e48a63          	beq	s1,a4,8000382c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800037fc:	449c                	lw	a5,8(s1)
    800037fe:	ff379ce3          	bne	a5,s3,800037f6 <bread+0x3a>
    80003802:	44dc                	lw	a5,12(s1)
    80003804:	ff2799e3          	bne	a5,s2,800037f6 <bread+0x3a>
      b->refcnt++;
    80003808:	40bc                	lw	a5,64(s1)
    8000380a:	2785                	addiw	a5,a5,1
    8000380c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000380e:	00014517          	auipc	a0,0x14
    80003812:	ae250513          	addi	a0,a0,-1310 # 800172f0 <bcache>
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	5b2080e7          	jalr	1458(ra) # 80000dc8 <release>
      acquiresleep(&b->lock);
    8000381e:	01048513          	addi	a0,s1,16
    80003822:	00001097          	auipc	ra,0x1
    80003826:	46e080e7          	jalr	1134(ra) # 80004c90 <acquiresleep>
      return b;
    8000382a:	a8b9                	j	80003888 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000382c:	0001c497          	auipc	s1,0x1c
    80003830:	d744b483          	ld	s1,-652(s1) # 8001f5a0 <bcache+0x82b0>
    80003834:	0001c797          	auipc	a5,0x1c
    80003838:	d2478793          	addi	a5,a5,-732 # 8001f558 <bcache+0x8268>
    8000383c:	00f48863          	beq	s1,a5,8000384c <bread+0x90>
    80003840:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003842:	40bc                	lw	a5,64(s1)
    80003844:	cf81                	beqz	a5,8000385c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003846:	64a4                	ld	s1,72(s1)
    80003848:	fee49de3          	bne	s1,a4,80003842 <bread+0x86>
  panic("bget: no buffers");
    8000384c:	00005517          	auipc	a0,0x5
    80003850:	cc450513          	addi	a0,a0,-828 # 80008510 <syscalls+0xd0>
    80003854:	ffffd097          	auipc	ra,0xffffd
    80003858:	cdc080e7          	jalr	-804(ra) # 80000530 <panic>
      b->dev = dev;
    8000385c:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003860:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003864:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003868:	4785                	li	a5,1
    8000386a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000386c:	00014517          	auipc	a0,0x14
    80003870:	a8450513          	addi	a0,a0,-1404 # 800172f0 <bcache>
    80003874:	ffffd097          	auipc	ra,0xffffd
    80003878:	554080e7          	jalr	1364(ra) # 80000dc8 <release>
      acquiresleep(&b->lock);
    8000387c:	01048513          	addi	a0,s1,16
    80003880:	00001097          	auipc	ra,0x1
    80003884:	410080e7          	jalr	1040(ra) # 80004c90 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003888:	409c                	lw	a5,0(s1)
    8000388a:	cb89                	beqz	a5,8000389c <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    8000388c:	8526                	mv	a0,s1
    8000388e:	70a2                	ld	ra,40(sp)
    80003890:	7402                	ld	s0,32(sp)
    80003892:	64e2                	ld	s1,24(sp)
    80003894:	6942                	ld	s2,16(sp)
    80003896:	69a2                	ld	s3,8(sp)
    80003898:	6145                	addi	sp,sp,48
    8000389a:	8082                	ret
    virtio_disk_rw(b, 0);
    8000389c:	4581                	li	a1,0
    8000389e:	8526                	mv	a0,s1
    800038a0:	00003097          	auipc	ra,0x3
    800038a4:	f16080e7          	jalr	-234(ra) # 800067b6 <virtio_disk_rw>
    b->valid = 1;
    800038a8:	4785                	li	a5,1
    800038aa:	c09c                	sw	a5,0(s1)
  return b;
    800038ac:	b7c5                	j	8000388c <bread+0xd0>

00000000800038ae <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800038ae:	1101                	addi	sp,sp,-32
    800038b0:	ec06                	sd	ra,24(sp)
    800038b2:	e822                	sd	s0,16(sp)
    800038b4:	e426                	sd	s1,8(sp)
    800038b6:	1000                	addi	s0,sp,32
    800038b8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038ba:	0541                	addi	a0,a0,16
    800038bc:	00001097          	auipc	ra,0x1
    800038c0:	46e080e7          	jalr	1134(ra) # 80004d2a <holdingsleep>
    800038c4:	cd01                	beqz	a0,800038dc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800038c6:	4585                	li	a1,1
    800038c8:	8526                	mv	a0,s1
    800038ca:	00003097          	auipc	ra,0x3
    800038ce:	eec080e7          	jalr	-276(ra) # 800067b6 <virtio_disk_rw>
}
    800038d2:	60e2                	ld	ra,24(sp)
    800038d4:	6442                	ld	s0,16(sp)
    800038d6:	64a2                	ld	s1,8(sp)
    800038d8:	6105                	addi	sp,sp,32
    800038da:	8082                	ret
    panic("bwrite");
    800038dc:	00005517          	auipc	a0,0x5
    800038e0:	c4c50513          	addi	a0,a0,-948 # 80008528 <syscalls+0xe8>
    800038e4:	ffffd097          	auipc	ra,0xffffd
    800038e8:	c4c080e7          	jalr	-948(ra) # 80000530 <panic>

00000000800038ec <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800038ec:	1101                	addi	sp,sp,-32
    800038ee:	ec06                	sd	ra,24(sp)
    800038f0:	e822                	sd	s0,16(sp)
    800038f2:	e426                	sd	s1,8(sp)
    800038f4:	e04a                	sd	s2,0(sp)
    800038f6:	1000                	addi	s0,sp,32
    800038f8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800038fa:	01050913          	addi	s2,a0,16
    800038fe:	854a                	mv	a0,s2
    80003900:	00001097          	auipc	ra,0x1
    80003904:	42a080e7          	jalr	1066(ra) # 80004d2a <holdingsleep>
    80003908:	c92d                	beqz	a0,8000397a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000390a:	854a                	mv	a0,s2
    8000390c:	00001097          	auipc	ra,0x1
    80003910:	3da080e7          	jalr	986(ra) # 80004ce6 <releasesleep>

  acquire(&bcache.lock);
    80003914:	00014517          	auipc	a0,0x14
    80003918:	9dc50513          	addi	a0,a0,-1572 # 800172f0 <bcache>
    8000391c:	ffffd097          	auipc	ra,0xffffd
    80003920:	3f8080e7          	jalr	1016(ra) # 80000d14 <acquire>
  b->refcnt--;
    80003924:	40bc                	lw	a5,64(s1)
    80003926:	37fd                	addiw	a5,a5,-1
    80003928:	0007871b          	sext.w	a4,a5
    8000392c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000392e:	eb05                	bnez	a4,8000395e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003930:	68bc                	ld	a5,80(s1)
    80003932:	64b8                	ld	a4,72(s1)
    80003934:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003936:	64bc                	ld	a5,72(s1)
    80003938:	68b8                	ld	a4,80(s1)
    8000393a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000393c:	0001c797          	auipc	a5,0x1c
    80003940:	9b478793          	addi	a5,a5,-1612 # 8001f2f0 <bcache+0x8000>
    80003944:	2b87b703          	ld	a4,696(a5)
    80003948:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000394a:	0001c717          	auipc	a4,0x1c
    8000394e:	c0e70713          	addi	a4,a4,-1010 # 8001f558 <bcache+0x8268>
    80003952:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003954:	2b87b703          	ld	a4,696(a5)
    80003958:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000395a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000395e:	00014517          	auipc	a0,0x14
    80003962:	99250513          	addi	a0,a0,-1646 # 800172f0 <bcache>
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	462080e7          	jalr	1122(ra) # 80000dc8 <release>
}
    8000396e:	60e2                	ld	ra,24(sp)
    80003970:	6442                	ld	s0,16(sp)
    80003972:	64a2                	ld	s1,8(sp)
    80003974:	6902                	ld	s2,0(sp)
    80003976:	6105                	addi	sp,sp,32
    80003978:	8082                	ret
    panic("brelse");
    8000397a:	00005517          	auipc	a0,0x5
    8000397e:	bb650513          	addi	a0,a0,-1098 # 80008530 <syscalls+0xf0>
    80003982:	ffffd097          	auipc	ra,0xffffd
    80003986:	bae080e7          	jalr	-1106(ra) # 80000530 <panic>

000000008000398a <bpin>:

void
bpin(struct buf *b) {
    8000398a:	1101                	addi	sp,sp,-32
    8000398c:	ec06                	sd	ra,24(sp)
    8000398e:	e822                	sd	s0,16(sp)
    80003990:	e426                	sd	s1,8(sp)
    80003992:	1000                	addi	s0,sp,32
    80003994:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003996:	00014517          	auipc	a0,0x14
    8000399a:	95a50513          	addi	a0,a0,-1702 # 800172f0 <bcache>
    8000399e:	ffffd097          	auipc	ra,0xffffd
    800039a2:	376080e7          	jalr	886(ra) # 80000d14 <acquire>
  b->refcnt++;
    800039a6:	40bc                	lw	a5,64(s1)
    800039a8:	2785                	addiw	a5,a5,1
    800039aa:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039ac:	00014517          	auipc	a0,0x14
    800039b0:	94450513          	addi	a0,a0,-1724 # 800172f0 <bcache>
    800039b4:	ffffd097          	auipc	ra,0xffffd
    800039b8:	414080e7          	jalr	1044(ra) # 80000dc8 <release>
}
    800039bc:	60e2                	ld	ra,24(sp)
    800039be:	6442                	ld	s0,16(sp)
    800039c0:	64a2                	ld	s1,8(sp)
    800039c2:	6105                	addi	sp,sp,32
    800039c4:	8082                	ret

00000000800039c6 <bunpin>:

void
bunpin(struct buf *b) {
    800039c6:	1101                	addi	sp,sp,-32
    800039c8:	ec06                	sd	ra,24(sp)
    800039ca:	e822                	sd	s0,16(sp)
    800039cc:	e426                	sd	s1,8(sp)
    800039ce:	1000                	addi	s0,sp,32
    800039d0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800039d2:	00014517          	auipc	a0,0x14
    800039d6:	91e50513          	addi	a0,a0,-1762 # 800172f0 <bcache>
    800039da:	ffffd097          	auipc	ra,0xffffd
    800039de:	33a080e7          	jalr	826(ra) # 80000d14 <acquire>
  b->refcnt--;
    800039e2:	40bc                	lw	a5,64(s1)
    800039e4:	37fd                	addiw	a5,a5,-1
    800039e6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800039e8:	00014517          	auipc	a0,0x14
    800039ec:	90850513          	addi	a0,a0,-1784 # 800172f0 <bcache>
    800039f0:	ffffd097          	auipc	ra,0xffffd
    800039f4:	3d8080e7          	jalr	984(ra) # 80000dc8 <release>
}
    800039f8:	60e2                	ld	ra,24(sp)
    800039fa:	6442                	ld	s0,16(sp)
    800039fc:	64a2                	ld	s1,8(sp)
    800039fe:	6105                	addi	sp,sp,32
    80003a00:	8082                	ret

0000000080003a02 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003a02:	1101                	addi	sp,sp,-32
    80003a04:	ec06                	sd	ra,24(sp)
    80003a06:	e822                	sd	s0,16(sp)
    80003a08:	e426                	sd	s1,8(sp)
    80003a0a:	e04a                	sd	s2,0(sp)
    80003a0c:	1000                	addi	s0,sp,32
    80003a0e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003a10:	00d5d59b          	srliw	a1,a1,0xd
    80003a14:	0001c797          	auipc	a5,0x1c
    80003a18:	fb87a783          	lw	a5,-72(a5) # 8001f9cc <sb+0x1c>
    80003a1c:	9dbd                	addw	a1,a1,a5
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	d9e080e7          	jalr	-610(ra) # 800037bc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003a26:	0074f713          	andi	a4,s1,7
    80003a2a:	4785                	li	a5,1
    80003a2c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003a30:	14ce                	slli	s1,s1,0x33
    80003a32:	90d9                	srli	s1,s1,0x36
    80003a34:	00950733          	add	a4,a0,s1
    80003a38:	05874703          	lbu	a4,88(a4)
    80003a3c:	00e7f6b3          	and	a3,a5,a4
    80003a40:	c69d                	beqz	a3,80003a6e <bfree+0x6c>
    80003a42:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003a44:	94aa                	add	s1,s1,a0
    80003a46:	fff7c793          	not	a5,a5
    80003a4a:	8ff9                	and	a5,a5,a4
    80003a4c:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003a50:	00001097          	auipc	ra,0x1
    80003a54:	118080e7          	jalr	280(ra) # 80004b68 <log_write>
  brelse(bp);
    80003a58:	854a                	mv	a0,s2
    80003a5a:	00000097          	auipc	ra,0x0
    80003a5e:	e92080e7          	jalr	-366(ra) # 800038ec <brelse>
}
    80003a62:	60e2                	ld	ra,24(sp)
    80003a64:	6442                	ld	s0,16(sp)
    80003a66:	64a2                	ld	s1,8(sp)
    80003a68:	6902                	ld	s2,0(sp)
    80003a6a:	6105                	addi	sp,sp,32
    80003a6c:	8082                	ret
    panic("freeing free block");
    80003a6e:	00005517          	auipc	a0,0x5
    80003a72:	aca50513          	addi	a0,a0,-1334 # 80008538 <syscalls+0xf8>
    80003a76:	ffffd097          	auipc	ra,0xffffd
    80003a7a:	aba080e7          	jalr	-1350(ra) # 80000530 <panic>

0000000080003a7e <balloc>:
{
    80003a7e:	711d                	addi	sp,sp,-96
    80003a80:	ec86                	sd	ra,88(sp)
    80003a82:	e8a2                	sd	s0,80(sp)
    80003a84:	e4a6                	sd	s1,72(sp)
    80003a86:	e0ca                	sd	s2,64(sp)
    80003a88:	fc4e                	sd	s3,56(sp)
    80003a8a:	f852                	sd	s4,48(sp)
    80003a8c:	f456                	sd	s5,40(sp)
    80003a8e:	f05a                	sd	s6,32(sp)
    80003a90:	ec5e                	sd	s7,24(sp)
    80003a92:	e862                	sd	s8,16(sp)
    80003a94:	e466                	sd	s9,8(sp)
    80003a96:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003a98:	0001c797          	auipc	a5,0x1c
    80003a9c:	f1c7a783          	lw	a5,-228(a5) # 8001f9b4 <sb+0x4>
    80003aa0:	cbd1                	beqz	a5,80003b34 <balloc+0xb6>
    80003aa2:	8baa                	mv	s7,a0
    80003aa4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003aa6:	0001cb17          	auipc	s6,0x1c
    80003aaa:	f0ab0b13          	addi	s6,s6,-246 # 8001f9b0 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003aae:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003ab0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ab2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003ab4:	6c89                	lui	s9,0x2
    80003ab6:	a831                	j	80003ad2 <balloc+0x54>
    brelse(bp);
    80003ab8:	854a                	mv	a0,s2
    80003aba:	00000097          	auipc	ra,0x0
    80003abe:	e32080e7          	jalr	-462(ra) # 800038ec <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003ac2:	015c87bb          	addw	a5,s9,s5
    80003ac6:	00078a9b          	sext.w	s5,a5
    80003aca:	004b2703          	lw	a4,4(s6)
    80003ace:	06eaf363          	bgeu	s5,a4,80003b34 <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    80003ad2:	41fad79b          	sraiw	a5,s5,0x1f
    80003ad6:	0137d79b          	srliw	a5,a5,0x13
    80003ada:	015787bb          	addw	a5,a5,s5
    80003ade:	40d7d79b          	sraiw	a5,a5,0xd
    80003ae2:	01cb2583          	lw	a1,28(s6)
    80003ae6:	9dbd                	addw	a1,a1,a5
    80003ae8:	855e                	mv	a0,s7
    80003aea:	00000097          	auipc	ra,0x0
    80003aee:	cd2080e7          	jalr	-814(ra) # 800037bc <bread>
    80003af2:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003af4:	004b2503          	lw	a0,4(s6)
    80003af8:	000a849b          	sext.w	s1,s5
    80003afc:	8662                	mv	a2,s8
    80003afe:	faa4fde3          	bgeu	s1,a0,80003ab8 <balloc+0x3a>
      m = 1 << (bi % 8);
    80003b02:	41f6579b          	sraiw	a5,a2,0x1f
    80003b06:	01d7d69b          	srliw	a3,a5,0x1d
    80003b0a:	00c6873b          	addw	a4,a3,a2
    80003b0e:	00777793          	andi	a5,a4,7
    80003b12:	9f95                	subw	a5,a5,a3
    80003b14:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003b18:	4037571b          	sraiw	a4,a4,0x3
    80003b1c:	00e906b3          	add	a3,s2,a4
    80003b20:	0586c683          	lbu	a3,88(a3)
    80003b24:	00d7f5b3          	and	a1,a5,a3
    80003b28:	cd91                	beqz	a1,80003b44 <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003b2a:	2605                	addiw	a2,a2,1
    80003b2c:	2485                	addiw	s1,s1,1
    80003b2e:	fd4618e3          	bne	a2,s4,80003afe <balloc+0x80>
    80003b32:	b759                	j	80003ab8 <balloc+0x3a>
  panic("balloc: out of blocks");
    80003b34:	00005517          	auipc	a0,0x5
    80003b38:	a1c50513          	addi	a0,a0,-1508 # 80008550 <syscalls+0x110>
    80003b3c:	ffffd097          	auipc	ra,0xffffd
    80003b40:	9f4080e7          	jalr	-1548(ra) # 80000530 <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003b44:	974a                	add	a4,a4,s2
    80003b46:	8fd5                	or	a5,a5,a3
    80003b48:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003b4c:	854a                	mv	a0,s2
    80003b4e:	00001097          	auipc	ra,0x1
    80003b52:	01a080e7          	jalr	26(ra) # 80004b68 <log_write>
        brelse(bp);
    80003b56:	854a                	mv	a0,s2
    80003b58:	00000097          	auipc	ra,0x0
    80003b5c:	d94080e7          	jalr	-620(ra) # 800038ec <brelse>
  bp = bread(dev, bno);
    80003b60:	85a6                	mv	a1,s1
    80003b62:	855e                	mv	a0,s7
    80003b64:	00000097          	auipc	ra,0x0
    80003b68:	c58080e7          	jalr	-936(ra) # 800037bc <bread>
    80003b6c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003b6e:	40000613          	li	a2,1024
    80003b72:	4581                	li	a1,0
    80003b74:	05850513          	addi	a0,a0,88
    80003b78:	ffffd097          	auipc	ra,0xffffd
    80003b7c:	298080e7          	jalr	664(ra) # 80000e10 <memset>
  log_write(bp);
    80003b80:	854a                	mv	a0,s2
    80003b82:	00001097          	auipc	ra,0x1
    80003b86:	fe6080e7          	jalr	-26(ra) # 80004b68 <log_write>
  brelse(bp);
    80003b8a:	854a                	mv	a0,s2
    80003b8c:	00000097          	auipc	ra,0x0
    80003b90:	d60080e7          	jalr	-672(ra) # 800038ec <brelse>
}
    80003b94:	8526                	mv	a0,s1
    80003b96:	60e6                	ld	ra,88(sp)
    80003b98:	6446                	ld	s0,80(sp)
    80003b9a:	64a6                	ld	s1,72(sp)
    80003b9c:	6906                	ld	s2,64(sp)
    80003b9e:	79e2                	ld	s3,56(sp)
    80003ba0:	7a42                	ld	s4,48(sp)
    80003ba2:	7aa2                	ld	s5,40(sp)
    80003ba4:	7b02                	ld	s6,32(sp)
    80003ba6:	6be2                	ld	s7,24(sp)
    80003ba8:	6c42                	ld	s8,16(sp)
    80003baa:	6ca2                	ld	s9,8(sp)
    80003bac:	6125                	addi	sp,sp,96
    80003bae:	8082                	ret

0000000080003bb0 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003bb0:	7179                	addi	sp,sp,-48
    80003bb2:	f406                	sd	ra,40(sp)
    80003bb4:	f022                	sd	s0,32(sp)
    80003bb6:	ec26                	sd	s1,24(sp)
    80003bb8:	e84a                	sd	s2,16(sp)
    80003bba:	e44e                	sd	s3,8(sp)
    80003bbc:	e052                	sd	s4,0(sp)
    80003bbe:	1800                	addi	s0,sp,48
    80003bc0:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003bc2:	47ad                	li	a5,11
    80003bc4:	04b7fe63          	bgeu	a5,a1,80003c20 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    80003bc8:	ff45849b          	addiw	s1,a1,-12
    80003bcc:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003bd0:	0ff00793          	li	a5,255
    80003bd4:	0ae7e363          	bltu	a5,a4,80003c7a <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    80003bd8:	08052583          	lw	a1,128(a0)
    80003bdc:	c5ad                	beqz	a1,80003c46 <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    80003bde:	00092503          	lw	a0,0(s2)
    80003be2:	00000097          	auipc	ra,0x0
    80003be6:	bda080e7          	jalr	-1062(ra) # 800037bc <bread>
    80003bea:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003bec:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003bf0:	02049593          	slli	a1,s1,0x20
    80003bf4:	9181                	srli	a1,a1,0x20
    80003bf6:	058a                	slli	a1,a1,0x2
    80003bf8:	00b784b3          	add	s1,a5,a1
    80003bfc:	0004a983          	lw	s3,0(s1)
    80003c00:	04098d63          	beqz	s3,80003c5a <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    80003c04:	8552                	mv	a0,s4
    80003c06:	00000097          	auipc	ra,0x0
    80003c0a:	ce6080e7          	jalr	-794(ra) # 800038ec <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003c0e:	854e                	mv	a0,s3
    80003c10:	70a2                	ld	ra,40(sp)
    80003c12:	7402                	ld	s0,32(sp)
    80003c14:	64e2                	ld	s1,24(sp)
    80003c16:	6942                	ld	s2,16(sp)
    80003c18:	69a2                	ld	s3,8(sp)
    80003c1a:	6a02                	ld	s4,0(sp)
    80003c1c:	6145                	addi	sp,sp,48
    80003c1e:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003c20:	02059493          	slli	s1,a1,0x20
    80003c24:	9081                	srli	s1,s1,0x20
    80003c26:	048a                	slli	s1,s1,0x2
    80003c28:	94aa                	add	s1,s1,a0
    80003c2a:	0504a983          	lw	s3,80(s1)
    80003c2e:	fe0990e3          	bnez	s3,80003c0e <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    80003c32:	4108                	lw	a0,0(a0)
    80003c34:	00000097          	auipc	ra,0x0
    80003c38:	e4a080e7          	jalr	-438(ra) # 80003a7e <balloc>
    80003c3c:	0005099b          	sext.w	s3,a0
    80003c40:	0534a823          	sw	s3,80(s1)
    80003c44:	b7e9                	j	80003c0e <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    80003c46:	4108                	lw	a0,0(a0)
    80003c48:	00000097          	auipc	ra,0x0
    80003c4c:	e36080e7          	jalr	-458(ra) # 80003a7e <balloc>
    80003c50:	0005059b          	sext.w	a1,a0
    80003c54:	08b92023          	sw	a1,128(s2)
    80003c58:	b759                	j	80003bde <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003c5a:	00092503          	lw	a0,0(s2)
    80003c5e:	00000097          	auipc	ra,0x0
    80003c62:	e20080e7          	jalr	-480(ra) # 80003a7e <balloc>
    80003c66:	0005099b          	sext.w	s3,a0
    80003c6a:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003c6e:	8552                	mv	a0,s4
    80003c70:	00001097          	auipc	ra,0x1
    80003c74:	ef8080e7          	jalr	-264(ra) # 80004b68 <log_write>
    80003c78:	b771                	j	80003c04 <bmap+0x54>
  panic("bmap: out of range");
    80003c7a:	00005517          	auipc	a0,0x5
    80003c7e:	8ee50513          	addi	a0,a0,-1810 # 80008568 <syscalls+0x128>
    80003c82:	ffffd097          	auipc	ra,0xffffd
    80003c86:	8ae080e7          	jalr	-1874(ra) # 80000530 <panic>

0000000080003c8a <iget>:
{
    80003c8a:	7179                	addi	sp,sp,-48
    80003c8c:	f406                	sd	ra,40(sp)
    80003c8e:	f022                	sd	s0,32(sp)
    80003c90:	ec26                	sd	s1,24(sp)
    80003c92:	e84a                	sd	s2,16(sp)
    80003c94:	e44e                	sd	s3,8(sp)
    80003c96:	e052                	sd	s4,0(sp)
    80003c98:	1800                	addi	s0,sp,48
    80003c9a:	89aa                	mv	s3,a0
    80003c9c:	8a2e                	mv	s4,a1
  acquire(&icache.lock);
    80003c9e:	0001c517          	auipc	a0,0x1c
    80003ca2:	d3250513          	addi	a0,a0,-718 # 8001f9d0 <icache>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	06e080e7          	jalr	110(ra) # 80000d14 <acquire>
  empty = 0;
    80003cae:	4901                	li	s2,0
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003cb0:	0001c497          	auipc	s1,0x1c
    80003cb4:	d3848493          	addi	s1,s1,-712 # 8001f9e8 <icache+0x18>
    80003cb8:	0001d697          	auipc	a3,0x1d
    80003cbc:	7c068693          	addi	a3,a3,1984 # 80021478 <log>
    80003cc0:	a039                	j	80003cce <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cc2:	02090b63          	beqz	s2,80003cf8 <iget+0x6e>
  for(ip = &icache.inode[0]; ip < &icache.inode[NINODE]; ip++){
    80003cc6:	08848493          	addi	s1,s1,136
    80003cca:	02d48a63          	beq	s1,a3,80003cfe <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80003cce:	449c                	lw	a5,8(s1)
    80003cd0:	fef059e3          	blez	a5,80003cc2 <iget+0x38>
    80003cd4:	4098                	lw	a4,0(s1)
    80003cd6:	ff3716e3          	bne	a4,s3,80003cc2 <iget+0x38>
    80003cda:	40d8                	lw	a4,4(s1)
    80003cdc:	ff4713e3          	bne	a4,s4,80003cc2 <iget+0x38>
      ip->ref++;
    80003ce0:	2785                	addiw	a5,a5,1
    80003ce2:	c49c                	sw	a5,8(s1)
      release(&icache.lock);
    80003ce4:	0001c517          	auipc	a0,0x1c
    80003ce8:	cec50513          	addi	a0,a0,-788 # 8001f9d0 <icache>
    80003cec:	ffffd097          	auipc	ra,0xffffd
    80003cf0:	0dc080e7          	jalr	220(ra) # 80000dc8 <release>
      return ip;
    80003cf4:	8926                	mv	s2,s1
    80003cf6:	a03d                	j	80003d24 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003cf8:	f7f9                	bnez	a5,80003cc6 <iget+0x3c>
    80003cfa:	8926                	mv	s2,s1
    80003cfc:	b7e9                	j	80003cc6 <iget+0x3c>
  if(empty == 0)
    80003cfe:	02090c63          	beqz	s2,80003d36 <iget+0xac>
  ip->dev = dev;
    80003d02:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003d06:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003d0a:	4785                	li	a5,1
    80003d0c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003d10:	04092023          	sw	zero,64(s2)
  release(&icache.lock);
    80003d14:	0001c517          	auipc	a0,0x1c
    80003d18:	cbc50513          	addi	a0,a0,-836 # 8001f9d0 <icache>
    80003d1c:	ffffd097          	auipc	ra,0xffffd
    80003d20:	0ac080e7          	jalr	172(ra) # 80000dc8 <release>
}
    80003d24:	854a                	mv	a0,s2
    80003d26:	70a2                	ld	ra,40(sp)
    80003d28:	7402                	ld	s0,32(sp)
    80003d2a:	64e2                	ld	s1,24(sp)
    80003d2c:	6942                	ld	s2,16(sp)
    80003d2e:	69a2                	ld	s3,8(sp)
    80003d30:	6a02                	ld	s4,0(sp)
    80003d32:	6145                	addi	sp,sp,48
    80003d34:	8082                	ret
    panic("iget: no inodes");
    80003d36:	00005517          	auipc	a0,0x5
    80003d3a:	84a50513          	addi	a0,a0,-1974 # 80008580 <syscalls+0x140>
    80003d3e:	ffffc097          	auipc	ra,0xffffc
    80003d42:	7f2080e7          	jalr	2034(ra) # 80000530 <panic>

0000000080003d46 <fsinit>:
fsinit(int dev) {
    80003d46:	7179                	addi	sp,sp,-48
    80003d48:	f406                	sd	ra,40(sp)
    80003d4a:	f022                	sd	s0,32(sp)
    80003d4c:	ec26                	sd	s1,24(sp)
    80003d4e:	e84a                	sd	s2,16(sp)
    80003d50:	e44e                	sd	s3,8(sp)
    80003d52:	1800                	addi	s0,sp,48
    80003d54:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003d56:	4585                	li	a1,1
    80003d58:	00000097          	auipc	ra,0x0
    80003d5c:	a64080e7          	jalr	-1436(ra) # 800037bc <bread>
    80003d60:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003d62:	0001c997          	auipc	s3,0x1c
    80003d66:	c4e98993          	addi	s3,s3,-946 # 8001f9b0 <sb>
    80003d6a:	02000613          	li	a2,32
    80003d6e:	05850593          	addi	a1,a0,88
    80003d72:	854e                	mv	a0,s3
    80003d74:	ffffd097          	auipc	ra,0xffffd
    80003d78:	0fc080e7          	jalr	252(ra) # 80000e70 <memmove>
  brelse(bp);
    80003d7c:	8526                	mv	a0,s1
    80003d7e:	00000097          	auipc	ra,0x0
    80003d82:	b6e080e7          	jalr	-1170(ra) # 800038ec <brelse>
  if(sb.magic != FSMAGIC)
    80003d86:	0009a703          	lw	a4,0(s3)
    80003d8a:	102037b7          	lui	a5,0x10203
    80003d8e:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80003d92:	02f71263          	bne	a4,a5,80003db6 <fsinit+0x70>
  initlog(dev, &sb);
    80003d96:	0001c597          	auipc	a1,0x1c
    80003d9a:	c1a58593          	addi	a1,a1,-998 # 8001f9b0 <sb>
    80003d9e:	854a                	mv	a0,s2
    80003da0:	00001097          	auipc	ra,0x1
    80003da4:	b4c080e7          	jalr	-1204(ra) # 800048ec <initlog>
}
    80003da8:	70a2                	ld	ra,40(sp)
    80003daa:	7402                	ld	s0,32(sp)
    80003dac:	64e2                	ld	s1,24(sp)
    80003dae:	6942                	ld	s2,16(sp)
    80003db0:	69a2                	ld	s3,8(sp)
    80003db2:	6145                	addi	sp,sp,48
    80003db4:	8082                	ret
    panic("invalid file system");
    80003db6:	00004517          	auipc	a0,0x4
    80003dba:	7da50513          	addi	a0,a0,2010 # 80008590 <syscalls+0x150>
    80003dbe:	ffffc097          	auipc	ra,0xffffc
    80003dc2:	772080e7          	jalr	1906(ra) # 80000530 <panic>

0000000080003dc6 <iinit>:
{
    80003dc6:	7179                	addi	sp,sp,-48
    80003dc8:	f406                	sd	ra,40(sp)
    80003dca:	f022                	sd	s0,32(sp)
    80003dcc:	ec26                	sd	s1,24(sp)
    80003dce:	e84a                	sd	s2,16(sp)
    80003dd0:	e44e                	sd	s3,8(sp)
    80003dd2:	1800                	addi	s0,sp,48
  initlock(&icache.lock, "icache");
    80003dd4:	00004597          	auipc	a1,0x4
    80003dd8:	7d458593          	addi	a1,a1,2004 # 800085a8 <syscalls+0x168>
    80003ddc:	0001c517          	auipc	a0,0x1c
    80003de0:	bf450513          	addi	a0,a0,-1036 # 8001f9d0 <icache>
    80003de4:	ffffd097          	auipc	ra,0xffffd
    80003de8:	ea0080e7          	jalr	-352(ra) # 80000c84 <initlock>
  for(i = 0; i < NINODE; i++) {
    80003dec:	0001c497          	auipc	s1,0x1c
    80003df0:	c0c48493          	addi	s1,s1,-1012 # 8001f9f8 <icache+0x28>
    80003df4:	0001d997          	auipc	s3,0x1d
    80003df8:	69498993          	addi	s3,s3,1684 # 80021488 <log+0x10>
    initsleeplock(&icache.inode[i].lock, "inode");
    80003dfc:	00004917          	auipc	s2,0x4
    80003e00:	7b490913          	addi	s2,s2,1972 # 800085b0 <syscalls+0x170>
    80003e04:	85ca                	mv	a1,s2
    80003e06:	8526                	mv	a0,s1
    80003e08:	00001097          	auipc	ra,0x1
    80003e0c:	e4e080e7          	jalr	-434(ra) # 80004c56 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003e10:	08848493          	addi	s1,s1,136
    80003e14:	ff3498e3          	bne	s1,s3,80003e04 <iinit+0x3e>
}
    80003e18:	70a2                	ld	ra,40(sp)
    80003e1a:	7402                	ld	s0,32(sp)
    80003e1c:	64e2                	ld	s1,24(sp)
    80003e1e:	6942                	ld	s2,16(sp)
    80003e20:	69a2                	ld	s3,8(sp)
    80003e22:	6145                	addi	sp,sp,48
    80003e24:	8082                	ret

0000000080003e26 <ialloc>:
{
    80003e26:	715d                	addi	sp,sp,-80
    80003e28:	e486                	sd	ra,72(sp)
    80003e2a:	e0a2                	sd	s0,64(sp)
    80003e2c:	fc26                	sd	s1,56(sp)
    80003e2e:	f84a                	sd	s2,48(sp)
    80003e30:	f44e                	sd	s3,40(sp)
    80003e32:	f052                	sd	s4,32(sp)
    80003e34:	ec56                	sd	s5,24(sp)
    80003e36:	e85a                	sd	s6,16(sp)
    80003e38:	e45e                	sd	s7,8(sp)
    80003e3a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e3c:	0001c717          	auipc	a4,0x1c
    80003e40:	b8072703          	lw	a4,-1152(a4) # 8001f9bc <sb+0xc>
    80003e44:	4785                	li	a5,1
    80003e46:	04e7fa63          	bgeu	a5,a4,80003e9a <ialloc+0x74>
    80003e4a:	8aaa                	mv	s5,a0
    80003e4c:	8bae                	mv	s7,a1
    80003e4e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003e50:	0001ca17          	auipc	s4,0x1c
    80003e54:	b60a0a13          	addi	s4,s4,-1184 # 8001f9b0 <sb>
    80003e58:	00048b1b          	sext.w	s6,s1
    80003e5c:	0044d593          	srli	a1,s1,0x4
    80003e60:	018a2783          	lw	a5,24(s4)
    80003e64:	9dbd                	addw	a1,a1,a5
    80003e66:	8556                	mv	a0,s5
    80003e68:	00000097          	auipc	ra,0x0
    80003e6c:	954080e7          	jalr	-1708(ra) # 800037bc <bread>
    80003e70:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    80003e72:	05850993          	addi	s3,a0,88
    80003e76:	00f4f793          	andi	a5,s1,15
    80003e7a:	079a                	slli	a5,a5,0x6
    80003e7c:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003e7e:	00099783          	lh	a5,0(s3)
    80003e82:	c785                	beqz	a5,80003eaa <ialloc+0x84>
    brelse(bp);
    80003e84:	00000097          	auipc	ra,0x0
    80003e88:	a68080e7          	jalr	-1432(ra) # 800038ec <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003e8c:	0485                	addi	s1,s1,1
    80003e8e:	00ca2703          	lw	a4,12(s4)
    80003e92:	0004879b          	sext.w	a5,s1
    80003e96:	fce7e1e3          	bltu	a5,a4,80003e58 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003e9a:	00004517          	auipc	a0,0x4
    80003e9e:	71e50513          	addi	a0,a0,1822 # 800085b8 <syscalls+0x178>
    80003ea2:	ffffc097          	auipc	ra,0xffffc
    80003ea6:	68e080e7          	jalr	1678(ra) # 80000530 <panic>
      memset(dip, 0, sizeof(*dip));
    80003eaa:	04000613          	li	a2,64
    80003eae:	4581                	li	a1,0
    80003eb0:	854e                	mv	a0,s3
    80003eb2:	ffffd097          	auipc	ra,0xffffd
    80003eb6:	f5e080e7          	jalr	-162(ra) # 80000e10 <memset>
      dip->type = type;
    80003eba:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003ebe:	854a                	mv	a0,s2
    80003ec0:	00001097          	auipc	ra,0x1
    80003ec4:	ca8080e7          	jalr	-856(ra) # 80004b68 <log_write>
      brelse(bp);
    80003ec8:	854a                	mv	a0,s2
    80003eca:	00000097          	auipc	ra,0x0
    80003ece:	a22080e7          	jalr	-1502(ra) # 800038ec <brelse>
      return iget(dev, inum);
    80003ed2:	85da                	mv	a1,s6
    80003ed4:	8556                	mv	a0,s5
    80003ed6:	00000097          	auipc	ra,0x0
    80003eda:	db4080e7          	jalr	-588(ra) # 80003c8a <iget>
}
    80003ede:	60a6                	ld	ra,72(sp)
    80003ee0:	6406                	ld	s0,64(sp)
    80003ee2:	74e2                	ld	s1,56(sp)
    80003ee4:	7942                	ld	s2,48(sp)
    80003ee6:	79a2                	ld	s3,40(sp)
    80003ee8:	7a02                	ld	s4,32(sp)
    80003eea:	6ae2                	ld	s5,24(sp)
    80003eec:	6b42                	ld	s6,16(sp)
    80003eee:	6ba2                	ld	s7,8(sp)
    80003ef0:	6161                	addi	sp,sp,80
    80003ef2:	8082                	ret

0000000080003ef4 <iupdate>:
{
    80003ef4:	1101                	addi	sp,sp,-32
    80003ef6:	ec06                	sd	ra,24(sp)
    80003ef8:	e822                	sd	s0,16(sp)
    80003efa:	e426                	sd	s1,8(sp)
    80003efc:	e04a                	sd	s2,0(sp)
    80003efe:	1000                	addi	s0,sp,32
    80003f00:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003f02:	415c                	lw	a5,4(a0)
    80003f04:	0047d79b          	srliw	a5,a5,0x4
    80003f08:	0001c597          	auipc	a1,0x1c
    80003f0c:	ac05a583          	lw	a1,-1344(a1) # 8001f9c8 <sb+0x18>
    80003f10:	9dbd                	addw	a1,a1,a5
    80003f12:	4108                	lw	a0,0(a0)
    80003f14:	00000097          	auipc	ra,0x0
    80003f18:	8a8080e7          	jalr	-1880(ra) # 800037bc <bread>
    80003f1c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003f1e:	05850793          	addi	a5,a0,88
    80003f22:	40c8                	lw	a0,4(s1)
    80003f24:	893d                	andi	a0,a0,15
    80003f26:	051a                	slli	a0,a0,0x6
    80003f28:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003f2a:	04449703          	lh	a4,68(s1)
    80003f2e:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    80003f32:	04649703          	lh	a4,70(s1)
    80003f36:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003f3a:	04849703          	lh	a4,72(s1)
    80003f3e:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    80003f42:	04a49703          	lh	a4,74(s1)
    80003f46:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003f4a:	44f8                	lw	a4,76(s1)
    80003f4c:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003f4e:	03400613          	li	a2,52
    80003f52:	05048593          	addi	a1,s1,80
    80003f56:	0531                	addi	a0,a0,12
    80003f58:	ffffd097          	auipc	ra,0xffffd
    80003f5c:	f18080e7          	jalr	-232(ra) # 80000e70 <memmove>
  log_write(bp);
    80003f60:	854a                	mv	a0,s2
    80003f62:	00001097          	auipc	ra,0x1
    80003f66:	c06080e7          	jalr	-1018(ra) # 80004b68 <log_write>
  brelse(bp);
    80003f6a:	854a                	mv	a0,s2
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	980080e7          	jalr	-1664(ra) # 800038ec <brelse>
}
    80003f74:	60e2                	ld	ra,24(sp)
    80003f76:	6442                	ld	s0,16(sp)
    80003f78:	64a2                	ld	s1,8(sp)
    80003f7a:	6902                	ld	s2,0(sp)
    80003f7c:	6105                	addi	sp,sp,32
    80003f7e:	8082                	ret

0000000080003f80 <idup>:
{
    80003f80:	1101                	addi	sp,sp,-32
    80003f82:	ec06                	sd	ra,24(sp)
    80003f84:	e822                	sd	s0,16(sp)
    80003f86:	e426                	sd	s1,8(sp)
    80003f88:	1000                	addi	s0,sp,32
    80003f8a:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80003f8c:	0001c517          	auipc	a0,0x1c
    80003f90:	a4450513          	addi	a0,a0,-1468 # 8001f9d0 <icache>
    80003f94:	ffffd097          	auipc	ra,0xffffd
    80003f98:	d80080e7          	jalr	-640(ra) # 80000d14 <acquire>
  ip->ref++;
    80003f9c:	449c                	lw	a5,8(s1)
    80003f9e:	2785                	addiw	a5,a5,1
    80003fa0:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    80003fa2:	0001c517          	auipc	a0,0x1c
    80003fa6:	a2e50513          	addi	a0,a0,-1490 # 8001f9d0 <icache>
    80003faa:	ffffd097          	auipc	ra,0xffffd
    80003fae:	e1e080e7          	jalr	-482(ra) # 80000dc8 <release>
}
    80003fb2:	8526                	mv	a0,s1
    80003fb4:	60e2                	ld	ra,24(sp)
    80003fb6:	6442                	ld	s0,16(sp)
    80003fb8:	64a2                	ld	s1,8(sp)
    80003fba:	6105                	addi	sp,sp,32
    80003fbc:	8082                	ret

0000000080003fbe <ilock>:
{
    80003fbe:	1101                	addi	sp,sp,-32
    80003fc0:	ec06                	sd	ra,24(sp)
    80003fc2:	e822                	sd	s0,16(sp)
    80003fc4:	e426                	sd	s1,8(sp)
    80003fc6:	e04a                	sd	s2,0(sp)
    80003fc8:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003fca:	c115                	beqz	a0,80003fee <ilock+0x30>
    80003fcc:	84aa                	mv	s1,a0
    80003fce:	451c                	lw	a5,8(a0)
    80003fd0:	00f05f63          	blez	a5,80003fee <ilock+0x30>
  acquiresleep(&ip->lock);
    80003fd4:	0541                	addi	a0,a0,16
    80003fd6:	00001097          	auipc	ra,0x1
    80003fda:	cba080e7          	jalr	-838(ra) # 80004c90 <acquiresleep>
  if(ip->valid == 0){
    80003fde:	40bc                	lw	a5,64(s1)
    80003fe0:	cf99                	beqz	a5,80003ffe <ilock+0x40>
}
    80003fe2:	60e2                	ld	ra,24(sp)
    80003fe4:	6442                	ld	s0,16(sp)
    80003fe6:	64a2                	ld	s1,8(sp)
    80003fe8:	6902                	ld	s2,0(sp)
    80003fea:	6105                	addi	sp,sp,32
    80003fec:	8082                	ret
    panic("ilock");
    80003fee:	00004517          	auipc	a0,0x4
    80003ff2:	5e250513          	addi	a0,a0,1506 # 800085d0 <syscalls+0x190>
    80003ff6:	ffffc097          	auipc	ra,0xffffc
    80003ffa:	53a080e7          	jalr	1338(ra) # 80000530 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003ffe:	40dc                	lw	a5,4(s1)
    80004000:	0047d79b          	srliw	a5,a5,0x4
    80004004:	0001c597          	auipc	a1,0x1c
    80004008:	9c45a583          	lw	a1,-1596(a1) # 8001f9c8 <sb+0x18>
    8000400c:	9dbd                	addw	a1,a1,a5
    8000400e:	4088                	lw	a0,0(s1)
    80004010:	fffff097          	auipc	ra,0xfffff
    80004014:	7ac080e7          	jalr	1964(ra) # 800037bc <bread>
    80004018:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000401a:	05850593          	addi	a1,a0,88
    8000401e:	40dc                	lw	a5,4(s1)
    80004020:	8bbd                	andi	a5,a5,15
    80004022:	079a                	slli	a5,a5,0x6
    80004024:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004026:	00059783          	lh	a5,0(a1)
    8000402a:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    8000402e:	00259783          	lh	a5,2(a1)
    80004032:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80004036:	00459783          	lh	a5,4(a1)
    8000403a:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    8000403e:	00659783          	lh	a5,6(a1)
    80004042:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80004046:	459c                	lw	a5,8(a1)
    80004048:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000404a:	03400613          	li	a2,52
    8000404e:	05b1                	addi	a1,a1,12
    80004050:	05048513          	addi	a0,s1,80
    80004054:	ffffd097          	auipc	ra,0xffffd
    80004058:	e1c080e7          	jalr	-484(ra) # 80000e70 <memmove>
    brelse(bp);
    8000405c:	854a                	mv	a0,s2
    8000405e:	00000097          	auipc	ra,0x0
    80004062:	88e080e7          	jalr	-1906(ra) # 800038ec <brelse>
    ip->valid = 1;
    80004066:	4785                	li	a5,1
    80004068:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000406a:	04449783          	lh	a5,68(s1)
    8000406e:	fbb5                	bnez	a5,80003fe2 <ilock+0x24>
      panic("ilock: no type");
    80004070:	00004517          	auipc	a0,0x4
    80004074:	56850513          	addi	a0,a0,1384 # 800085d8 <syscalls+0x198>
    80004078:	ffffc097          	auipc	ra,0xffffc
    8000407c:	4b8080e7          	jalr	1208(ra) # 80000530 <panic>

0000000080004080 <iunlock>:
{
    80004080:	1101                	addi	sp,sp,-32
    80004082:	ec06                	sd	ra,24(sp)
    80004084:	e822                	sd	s0,16(sp)
    80004086:	e426                	sd	s1,8(sp)
    80004088:	e04a                	sd	s2,0(sp)
    8000408a:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000408c:	c905                	beqz	a0,800040bc <iunlock+0x3c>
    8000408e:	84aa                	mv	s1,a0
    80004090:	01050913          	addi	s2,a0,16
    80004094:	854a                	mv	a0,s2
    80004096:	00001097          	auipc	ra,0x1
    8000409a:	c94080e7          	jalr	-876(ra) # 80004d2a <holdingsleep>
    8000409e:	cd19                	beqz	a0,800040bc <iunlock+0x3c>
    800040a0:	449c                	lw	a5,8(s1)
    800040a2:	00f05d63          	blez	a5,800040bc <iunlock+0x3c>
  releasesleep(&ip->lock);
    800040a6:	854a                	mv	a0,s2
    800040a8:	00001097          	auipc	ra,0x1
    800040ac:	c3e080e7          	jalr	-962(ra) # 80004ce6 <releasesleep>
}
    800040b0:	60e2                	ld	ra,24(sp)
    800040b2:	6442                	ld	s0,16(sp)
    800040b4:	64a2                	ld	s1,8(sp)
    800040b6:	6902                	ld	s2,0(sp)
    800040b8:	6105                	addi	sp,sp,32
    800040ba:	8082                	ret
    panic("iunlock");
    800040bc:	00004517          	auipc	a0,0x4
    800040c0:	52c50513          	addi	a0,a0,1324 # 800085e8 <syscalls+0x1a8>
    800040c4:	ffffc097          	auipc	ra,0xffffc
    800040c8:	46c080e7          	jalr	1132(ra) # 80000530 <panic>

00000000800040cc <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800040cc:	7179                	addi	sp,sp,-48
    800040ce:	f406                	sd	ra,40(sp)
    800040d0:	f022                	sd	s0,32(sp)
    800040d2:	ec26                	sd	s1,24(sp)
    800040d4:	e84a                	sd	s2,16(sp)
    800040d6:	e44e                	sd	s3,8(sp)
    800040d8:	e052                	sd	s4,0(sp)
    800040da:	1800                	addi	s0,sp,48
    800040dc:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800040de:	05050493          	addi	s1,a0,80
    800040e2:	08050913          	addi	s2,a0,128
    800040e6:	a021                	j	800040ee <itrunc+0x22>
    800040e8:	0491                	addi	s1,s1,4
    800040ea:	01248d63          	beq	s1,s2,80004104 <itrunc+0x38>
    if(ip->addrs[i]){
    800040ee:	408c                	lw	a1,0(s1)
    800040f0:	dde5                	beqz	a1,800040e8 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800040f2:	0009a503          	lw	a0,0(s3)
    800040f6:	00000097          	auipc	ra,0x0
    800040fa:	90c080e7          	jalr	-1780(ra) # 80003a02 <bfree>
      ip->addrs[i] = 0;
    800040fe:	0004a023          	sw	zero,0(s1)
    80004102:	b7dd                	j	800040e8 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004104:	0809a583          	lw	a1,128(s3)
    80004108:	e185                	bnez	a1,80004128 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000410a:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    8000410e:	854e                	mv	a0,s3
    80004110:	00000097          	auipc	ra,0x0
    80004114:	de4080e7          	jalr	-540(ra) # 80003ef4 <iupdate>
}
    80004118:	70a2                	ld	ra,40(sp)
    8000411a:	7402                	ld	s0,32(sp)
    8000411c:	64e2                	ld	s1,24(sp)
    8000411e:	6942                	ld	s2,16(sp)
    80004120:	69a2                	ld	s3,8(sp)
    80004122:	6a02                	ld	s4,0(sp)
    80004124:	6145                	addi	sp,sp,48
    80004126:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80004128:	0009a503          	lw	a0,0(s3)
    8000412c:	fffff097          	auipc	ra,0xfffff
    80004130:	690080e7          	jalr	1680(ra) # 800037bc <bread>
    80004134:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80004136:	05850493          	addi	s1,a0,88
    8000413a:	45850913          	addi	s2,a0,1112
    8000413e:	a811                	j	80004152 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80004140:	0009a503          	lw	a0,0(s3)
    80004144:	00000097          	auipc	ra,0x0
    80004148:	8be080e7          	jalr	-1858(ra) # 80003a02 <bfree>
    for(j = 0; j < NINDIRECT; j++){
    8000414c:	0491                	addi	s1,s1,4
    8000414e:	01248563          	beq	s1,s2,80004158 <itrunc+0x8c>
      if(a[j])
    80004152:	408c                	lw	a1,0(s1)
    80004154:	dde5                	beqz	a1,8000414c <itrunc+0x80>
    80004156:	b7ed                	j	80004140 <itrunc+0x74>
    brelse(bp);
    80004158:	8552                	mv	a0,s4
    8000415a:	fffff097          	auipc	ra,0xfffff
    8000415e:	792080e7          	jalr	1938(ra) # 800038ec <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80004162:	0809a583          	lw	a1,128(s3)
    80004166:	0009a503          	lw	a0,0(s3)
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	898080e7          	jalr	-1896(ra) # 80003a02 <bfree>
    ip->addrs[NDIRECT] = 0;
    80004172:	0809a023          	sw	zero,128(s3)
    80004176:	bf51                	j	8000410a <itrunc+0x3e>

0000000080004178 <iput>:
{
    80004178:	1101                	addi	sp,sp,-32
    8000417a:	ec06                	sd	ra,24(sp)
    8000417c:	e822                	sd	s0,16(sp)
    8000417e:	e426                	sd	s1,8(sp)
    80004180:	e04a                	sd	s2,0(sp)
    80004182:	1000                	addi	s0,sp,32
    80004184:	84aa                	mv	s1,a0
  acquire(&icache.lock);
    80004186:	0001c517          	auipc	a0,0x1c
    8000418a:	84a50513          	addi	a0,a0,-1974 # 8001f9d0 <icache>
    8000418e:	ffffd097          	auipc	ra,0xffffd
    80004192:	b86080e7          	jalr	-1146(ra) # 80000d14 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004196:	4498                	lw	a4,8(s1)
    80004198:	4785                	li	a5,1
    8000419a:	02f70363          	beq	a4,a5,800041c0 <iput+0x48>
  ip->ref--;
    8000419e:	449c                	lw	a5,8(s1)
    800041a0:	37fd                	addiw	a5,a5,-1
    800041a2:	c49c                	sw	a5,8(s1)
  release(&icache.lock);
    800041a4:	0001c517          	auipc	a0,0x1c
    800041a8:	82c50513          	addi	a0,a0,-2004 # 8001f9d0 <icache>
    800041ac:	ffffd097          	auipc	ra,0xffffd
    800041b0:	c1c080e7          	jalr	-996(ra) # 80000dc8 <release>
}
    800041b4:	60e2                	ld	ra,24(sp)
    800041b6:	6442                	ld	s0,16(sp)
    800041b8:	64a2                	ld	s1,8(sp)
    800041ba:	6902                	ld	s2,0(sp)
    800041bc:	6105                	addi	sp,sp,32
    800041be:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    800041c0:	40bc                	lw	a5,64(s1)
    800041c2:	dff1                	beqz	a5,8000419e <iput+0x26>
    800041c4:	04a49783          	lh	a5,74(s1)
    800041c8:	fbf9                	bnez	a5,8000419e <iput+0x26>
    acquiresleep(&ip->lock);
    800041ca:	01048913          	addi	s2,s1,16
    800041ce:	854a                	mv	a0,s2
    800041d0:	00001097          	auipc	ra,0x1
    800041d4:	ac0080e7          	jalr	-1344(ra) # 80004c90 <acquiresleep>
    release(&icache.lock);
    800041d8:	0001b517          	auipc	a0,0x1b
    800041dc:	7f850513          	addi	a0,a0,2040 # 8001f9d0 <icache>
    800041e0:	ffffd097          	auipc	ra,0xffffd
    800041e4:	be8080e7          	jalr	-1048(ra) # 80000dc8 <release>
    itrunc(ip);
    800041e8:	8526                	mv	a0,s1
    800041ea:	00000097          	auipc	ra,0x0
    800041ee:	ee2080e7          	jalr	-286(ra) # 800040cc <itrunc>
    ip->type = 0;
    800041f2:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800041f6:	8526                	mv	a0,s1
    800041f8:	00000097          	auipc	ra,0x0
    800041fc:	cfc080e7          	jalr	-772(ra) # 80003ef4 <iupdate>
    ip->valid = 0;
    80004200:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004204:	854a                	mv	a0,s2
    80004206:	00001097          	auipc	ra,0x1
    8000420a:	ae0080e7          	jalr	-1312(ra) # 80004ce6 <releasesleep>
    acquire(&icache.lock);
    8000420e:	0001b517          	auipc	a0,0x1b
    80004212:	7c250513          	addi	a0,a0,1986 # 8001f9d0 <icache>
    80004216:	ffffd097          	auipc	ra,0xffffd
    8000421a:	afe080e7          	jalr	-1282(ra) # 80000d14 <acquire>
    8000421e:	b741                	j	8000419e <iput+0x26>

0000000080004220 <iunlockput>:
{
    80004220:	1101                	addi	sp,sp,-32
    80004222:	ec06                	sd	ra,24(sp)
    80004224:	e822                	sd	s0,16(sp)
    80004226:	e426                	sd	s1,8(sp)
    80004228:	1000                	addi	s0,sp,32
    8000422a:	84aa                	mv	s1,a0
  iunlock(ip);
    8000422c:	00000097          	auipc	ra,0x0
    80004230:	e54080e7          	jalr	-428(ra) # 80004080 <iunlock>
  iput(ip);
    80004234:	8526                	mv	a0,s1
    80004236:	00000097          	auipc	ra,0x0
    8000423a:	f42080e7          	jalr	-190(ra) # 80004178 <iput>
}
    8000423e:	60e2                	ld	ra,24(sp)
    80004240:	6442                	ld	s0,16(sp)
    80004242:	64a2                	ld	s1,8(sp)
    80004244:	6105                	addi	sp,sp,32
    80004246:	8082                	ret

0000000080004248 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80004248:	1141                	addi	sp,sp,-16
    8000424a:	e422                	sd	s0,8(sp)
    8000424c:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    8000424e:	411c                	lw	a5,0(a0)
    80004250:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80004252:	415c                	lw	a5,4(a0)
    80004254:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80004256:	04451783          	lh	a5,68(a0)
    8000425a:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    8000425e:	04a51783          	lh	a5,74(a0)
    80004262:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80004266:	04c56783          	lwu	a5,76(a0)
    8000426a:	e99c                	sd	a5,16(a1)
}
    8000426c:	6422                	ld	s0,8(sp)
    8000426e:	0141                	addi	sp,sp,16
    80004270:	8082                	ret

0000000080004272 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80004272:	457c                	lw	a5,76(a0)
    80004274:	0ed7e963          	bltu	a5,a3,80004366 <readi+0xf4>
{
    80004278:	7159                	addi	sp,sp,-112
    8000427a:	f486                	sd	ra,104(sp)
    8000427c:	f0a2                	sd	s0,96(sp)
    8000427e:	eca6                	sd	s1,88(sp)
    80004280:	e8ca                	sd	s2,80(sp)
    80004282:	e4ce                	sd	s3,72(sp)
    80004284:	e0d2                	sd	s4,64(sp)
    80004286:	fc56                	sd	s5,56(sp)
    80004288:	f85a                	sd	s6,48(sp)
    8000428a:	f45e                	sd	s7,40(sp)
    8000428c:	f062                	sd	s8,32(sp)
    8000428e:	ec66                	sd	s9,24(sp)
    80004290:	e86a                	sd	s10,16(sp)
    80004292:	e46e                	sd	s11,8(sp)
    80004294:	1880                	addi	s0,sp,112
    80004296:	8baa                	mv	s7,a0
    80004298:	8c2e                	mv	s8,a1
    8000429a:	8ab2                	mv	s5,a2
    8000429c:	84b6                	mv	s1,a3
    8000429e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    800042a0:	9f35                	addw	a4,a4,a3
    return 0;
    800042a2:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    800042a4:	0ad76063          	bltu	a4,a3,80004344 <readi+0xd2>
  if(off + n > ip->size)
    800042a8:	00e7f463          	bgeu	a5,a4,800042b0 <readi+0x3e>
    n = ip->size - off;
    800042ac:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042b0:	0a0b0963          	beqz	s6,80004362 <readi+0xf0>
    800042b4:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800042b6:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    800042ba:	5cfd                	li	s9,-1
    800042bc:	a82d                	j	800042f6 <readi+0x84>
    800042be:	020a1d93          	slli	s11,s4,0x20
    800042c2:	020ddd93          	srli	s11,s11,0x20
    800042c6:	05890613          	addi	a2,s2,88
    800042ca:	86ee                	mv	a3,s11
    800042cc:	963a                	add	a2,a2,a4
    800042ce:	85d6                	mv	a1,s5
    800042d0:	8562                	mv	a0,s8
    800042d2:	fffff097          	auipc	ra,0xfffff
    800042d6:	ac8080e7          	jalr	-1336(ra) # 80002d9a <either_copyout>
    800042da:	05950d63          	beq	a0,s9,80004334 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    800042de:	854a                	mv	a0,s2
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	60c080e7          	jalr	1548(ra) # 800038ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800042e8:	013a09bb          	addw	s3,s4,s3
    800042ec:	009a04bb          	addw	s1,s4,s1
    800042f0:	9aee                	add	s5,s5,s11
    800042f2:	0569f763          	bgeu	s3,s6,80004340 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800042f6:	000ba903          	lw	s2,0(s7)
    800042fa:	00a4d59b          	srliw	a1,s1,0xa
    800042fe:	855e                	mv	a0,s7
    80004300:	00000097          	auipc	ra,0x0
    80004304:	8b0080e7          	jalr	-1872(ra) # 80003bb0 <bmap>
    80004308:	0005059b          	sext.w	a1,a0
    8000430c:	854a                	mv	a0,s2
    8000430e:	fffff097          	auipc	ra,0xfffff
    80004312:	4ae080e7          	jalr	1198(ra) # 800037bc <bread>
    80004316:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004318:	3ff4f713          	andi	a4,s1,1023
    8000431c:	40ed07bb          	subw	a5,s10,a4
    80004320:	413b06bb          	subw	a3,s6,s3
    80004324:	8a3e                	mv	s4,a5
    80004326:	2781                	sext.w	a5,a5
    80004328:	0006861b          	sext.w	a2,a3
    8000432c:	f8f679e3          	bgeu	a2,a5,800042be <readi+0x4c>
    80004330:	8a36                	mv	s4,a3
    80004332:	b771                	j	800042be <readi+0x4c>
      brelse(bp);
    80004334:	854a                	mv	a0,s2
    80004336:	fffff097          	auipc	ra,0xfffff
    8000433a:	5b6080e7          	jalr	1462(ra) # 800038ec <brelse>
      tot = -1;
    8000433e:	59fd                	li	s3,-1
  }
  return tot;
    80004340:	0009851b          	sext.w	a0,s3
}
    80004344:	70a6                	ld	ra,104(sp)
    80004346:	7406                	ld	s0,96(sp)
    80004348:	64e6                	ld	s1,88(sp)
    8000434a:	6946                	ld	s2,80(sp)
    8000434c:	69a6                	ld	s3,72(sp)
    8000434e:	6a06                	ld	s4,64(sp)
    80004350:	7ae2                	ld	s5,56(sp)
    80004352:	7b42                	ld	s6,48(sp)
    80004354:	7ba2                	ld	s7,40(sp)
    80004356:	7c02                	ld	s8,32(sp)
    80004358:	6ce2                	ld	s9,24(sp)
    8000435a:	6d42                	ld	s10,16(sp)
    8000435c:	6da2                	ld	s11,8(sp)
    8000435e:	6165                	addi	sp,sp,112
    80004360:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004362:	89da                	mv	s3,s6
    80004364:	bff1                	j	80004340 <readi+0xce>
    return 0;
    80004366:	4501                	li	a0,0
}
    80004368:	8082                	ret

000000008000436a <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    8000436a:	457c                	lw	a5,76(a0)
    8000436c:	10d7e863          	bltu	a5,a3,8000447c <writei+0x112>
{
    80004370:	7159                	addi	sp,sp,-112
    80004372:	f486                	sd	ra,104(sp)
    80004374:	f0a2                	sd	s0,96(sp)
    80004376:	eca6                	sd	s1,88(sp)
    80004378:	e8ca                	sd	s2,80(sp)
    8000437a:	e4ce                	sd	s3,72(sp)
    8000437c:	e0d2                	sd	s4,64(sp)
    8000437e:	fc56                	sd	s5,56(sp)
    80004380:	f85a                	sd	s6,48(sp)
    80004382:	f45e                	sd	s7,40(sp)
    80004384:	f062                	sd	s8,32(sp)
    80004386:	ec66                	sd	s9,24(sp)
    80004388:	e86a                	sd	s10,16(sp)
    8000438a:	e46e                	sd	s11,8(sp)
    8000438c:	1880                	addi	s0,sp,112
    8000438e:	8b2a                	mv	s6,a0
    80004390:	8c2e                	mv	s8,a1
    80004392:	8ab2                	mv	s5,a2
    80004394:	8936                	mv	s2,a3
    80004396:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80004398:	00e687bb          	addw	a5,a3,a4
    8000439c:	0ed7e263          	bltu	a5,a3,80004480 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    800043a0:	00043737          	lui	a4,0x43
    800043a4:	0ef76063          	bltu	a4,a5,80004484 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043a8:	0c0b8863          	beqz	s7,80004478 <writei+0x10e>
    800043ac:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    800043ae:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    800043b2:	5cfd                	li	s9,-1
    800043b4:	a091                	j	800043f8 <writei+0x8e>
    800043b6:	02099d93          	slli	s11,s3,0x20
    800043ba:	020ddd93          	srli	s11,s11,0x20
    800043be:	05848513          	addi	a0,s1,88
    800043c2:	86ee                	mv	a3,s11
    800043c4:	8656                	mv	a2,s5
    800043c6:	85e2                	mv	a1,s8
    800043c8:	953a                	add	a0,a0,a4
    800043ca:	fffff097          	auipc	ra,0xfffff
    800043ce:	a26080e7          	jalr	-1498(ra) # 80002df0 <either_copyin>
    800043d2:	07950263          	beq	a0,s9,80004436 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    800043d6:	8526                	mv	a0,s1
    800043d8:	00000097          	auipc	ra,0x0
    800043dc:	790080e7          	jalr	1936(ra) # 80004b68 <log_write>
    brelse(bp);
    800043e0:	8526                	mv	a0,s1
    800043e2:	fffff097          	auipc	ra,0xfffff
    800043e6:	50a080e7          	jalr	1290(ra) # 800038ec <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800043ea:	01498a3b          	addw	s4,s3,s4
    800043ee:	0129893b          	addw	s2,s3,s2
    800043f2:	9aee                	add	s5,s5,s11
    800043f4:	057a7663          	bgeu	s4,s7,80004440 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    800043f8:	000b2483          	lw	s1,0(s6)
    800043fc:	00a9559b          	srliw	a1,s2,0xa
    80004400:	855a                	mv	a0,s6
    80004402:	fffff097          	auipc	ra,0xfffff
    80004406:	7ae080e7          	jalr	1966(ra) # 80003bb0 <bmap>
    8000440a:	0005059b          	sext.w	a1,a0
    8000440e:	8526                	mv	a0,s1
    80004410:	fffff097          	auipc	ra,0xfffff
    80004414:	3ac080e7          	jalr	940(ra) # 800037bc <bread>
    80004418:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000441a:	3ff97713          	andi	a4,s2,1023
    8000441e:	40ed07bb          	subw	a5,s10,a4
    80004422:	414b86bb          	subw	a3,s7,s4
    80004426:	89be                	mv	s3,a5
    80004428:	2781                	sext.w	a5,a5
    8000442a:	0006861b          	sext.w	a2,a3
    8000442e:	f8f674e3          	bgeu	a2,a5,800043b6 <writei+0x4c>
    80004432:	89b6                	mv	s3,a3
    80004434:	b749                	j	800043b6 <writei+0x4c>
      brelse(bp);
    80004436:	8526                	mv	a0,s1
    80004438:	fffff097          	auipc	ra,0xfffff
    8000443c:	4b4080e7          	jalr	1204(ra) # 800038ec <brelse>
  }

  if(off > ip->size)
    80004440:	04cb2783          	lw	a5,76(s6)
    80004444:	0127f463          	bgeu	a5,s2,8000444c <writei+0xe2>
    ip->size = off;
    80004448:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    8000444c:	855a                	mv	a0,s6
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	aa6080e7          	jalr	-1370(ra) # 80003ef4 <iupdate>

  return tot;
    80004456:	000a051b          	sext.w	a0,s4
}
    8000445a:	70a6                	ld	ra,104(sp)
    8000445c:	7406                	ld	s0,96(sp)
    8000445e:	64e6                	ld	s1,88(sp)
    80004460:	6946                	ld	s2,80(sp)
    80004462:	69a6                	ld	s3,72(sp)
    80004464:	6a06                	ld	s4,64(sp)
    80004466:	7ae2                	ld	s5,56(sp)
    80004468:	7b42                	ld	s6,48(sp)
    8000446a:	7ba2                	ld	s7,40(sp)
    8000446c:	7c02                	ld	s8,32(sp)
    8000446e:	6ce2                	ld	s9,24(sp)
    80004470:	6d42                	ld	s10,16(sp)
    80004472:	6da2                	ld	s11,8(sp)
    80004474:	6165                	addi	sp,sp,112
    80004476:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004478:	8a5e                	mv	s4,s7
    8000447a:	bfc9                	j	8000444c <writei+0xe2>
    return -1;
    8000447c:	557d                	li	a0,-1
}
    8000447e:	8082                	ret
    return -1;
    80004480:	557d                	li	a0,-1
    80004482:	bfe1                	j	8000445a <writei+0xf0>
    return -1;
    80004484:	557d                	li	a0,-1
    80004486:	bfd1                	j	8000445a <writei+0xf0>

0000000080004488 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004488:	1141                	addi	sp,sp,-16
    8000448a:	e406                	sd	ra,8(sp)
    8000448c:	e022                	sd	s0,0(sp)
    8000448e:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004490:	4639                	li	a2,14
    80004492:	ffffd097          	auipc	ra,0xffffd
    80004496:	a5a080e7          	jalr	-1446(ra) # 80000eec <strncmp>
}
    8000449a:	60a2                	ld	ra,8(sp)
    8000449c:	6402                	ld	s0,0(sp)
    8000449e:	0141                	addi	sp,sp,16
    800044a0:	8082                	ret

00000000800044a2 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    800044a2:	7139                	addi	sp,sp,-64
    800044a4:	fc06                	sd	ra,56(sp)
    800044a6:	f822                	sd	s0,48(sp)
    800044a8:	f426                	sd	s1,40(sp)
    800044aa:	f04a                	sd	s2,32(sp)
    800044ac:	ec4e                	sd	s3,24(sp)
    800044ae:	e852                	sd	s4,16(sp)
    800044b0:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    800044b2:	04451703          	lh	a4,68(a0)
    800044b6:	4785                	li	a5,1
    800044b8:	00f71a63          	bne	a4,a5,800044cc <dirlookup+0x2a>
    800044bc:	892a                	mv	s2,a0
    800044be:	89ae                	mv	s3,a1
    800044c0:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c2:	457c                	lw	a5,76(a0)
    800044c4:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    800044c6:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044c8:	e79d                	bnez	a5,800044f6 <dirlookup+0x54>
    800044ca:	a8a5                	j	80004542 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    800044cc:	00004517          	auipc	a0,0x4
    800044d0:	12450513          	addi	a0,a0,292 # 800085f0 <syscalls+0x1b0>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	05c080e7          	jalr	92(ra) # 80000530 <panic>
      panic("dirlookup read");
    800044dc:	00004517          	auipc	a0,0x4
    800044e0:	12c50513          	addi	a0,a0,300 # 80008608 <syscalls+0x1c8>
    800044e4:	ffffc097          	auipc	ra,0xffffc
    800044e8:	04c080e7          	jalr	76(ra) # 80000530 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800044ec:	24c1                	addiw	s1,s1,16
    800044ee:	04c92783          	lw	a5,76(s2)
    800044f2:	04f4f763          	bgeu	s1,a5,80004540 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800044f6:	4741                	li	a4,16
    800044f8:	86a6                	mv	a3,s1
    800044fa:	fc040613          	addi	a2,s0,-64
    800044fe:	4581                	li	a1,0
    80004500:	854a                	mv	a0,s2
    80004502:	00000097          	auipc	ra,0x0
    80004506:	d70080e7          	jalr	-656(ra) # 80004272 <readi>
    8000450a:	47c1                	li	a5,16
    8000450c:	fcf518e3          	bne	a0,a5,800044dc <dirlookup+0x3a>
    if(de.inum == 0)
    80004510:	fc045783          	lhu	a5,-64(s0)
    80004514:	dfe1                	beqz	a5,800044ec <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004516:	fc240593          	addi	a1,s0,-62
    8000451a:	854e                	mv	a0,s3
    8000451c:	00000097          	auipc	ra,0x0
    80004520:	f6c080e7          	jalr	-148(ra) # 80004488 <namecmp>
    80004524:	f561                	bnez	a0,800044ec <dirlookup+0x4a>
      if(poff)
    80004526:	000a0463          	beqz	s4,8000452e <dirlookup+0x8c>
        *poff = off;
    8000452a:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    8000452e:	fc045583          	lhu	a1,-64(s0)
    80004532:	00092503          	lw	a0,0(s2)
    80004536:	fffff097          	auipc	ra,0xfffff
    8000453a:	754080e7          	jalr	1876(ra) # 80003c8a <iget>
    8000453e:	a011                	j	80004542 <dirlookup+0xa0>
  return 0;
    80004540:	4501                	li	a0,0
}
    80004542:	70e2                	ld	ra,56(sp)
    80004544:	7442                	ld	s0,48(sp)
    80004546:	74a2                	ld	s1,40(sp)
    80004548:	7902                	ld	s2,32(sp)
    8000454a:	69e2                	ld	s3,24(sp)
    8000454c:	6a42                	ld	s4,16(sp)
    8000454e:	6121                	addi	sp,sp,64
    80004550:	8082                	ret

0000000080004552 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004552:	711d                	addi	sp,sp,-96
    80004554:	ec86                	sd	ra,88(sp)
    80004556:	e8a2                	sd	s0,80(sp)
    80004558:	e4a6                	sd	s1,72(sp)
    8000455a:	e0ca                	sd	s2,64(sp)
    8000455c:	fc4e                	sd	s3,56(sp)
    8000455e:	f852                	sd	s4,48(sp)
    80004560:	f456                	sd	s5,40(sp)
    80004562:	f05a                	sd	s6,32(sp)
    80004564:	ec5e                	sd	s7,24(sp)
    80004566:	e862                	sd	s8,16(sp)
    80004568:	e466                	sd	s9,8(sp)
    8000456a:	1080                	addi	s0,sp,96
    8000456c:	84aa                	mv	s1,a0
    8000456e:	8b2e                	mv	s6,a1
    80004570:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004572:	00054703          	lbu	a4,0(a0)
    80004576:	02f00793          	li	a5,47
    8000457a:	02f70363          	beq	a4,a5,800045a0 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    8000457e:	ffffe097          	auipc	ra,0xffffe
    80004582:	c58080e7          	jalr	-936(ra) # 800021d6 <myproc>
    80004586:	15053503          	ld	a0,336(a0)
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	9f6080e7          	jalr	-1546(ra) # 80003f80 <idup>
    80004592:	89aa                	mv	s3,a0
  while(*path == '/')
    80004594:	02f00913          	li	s2,47
  len = path - s;
    80004598:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000459a:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000459c:	4c05                	li	s8,1
    8000459e:	a865                	j	80004656 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    800045a0:	4585                	li	a1,1
    800045a2:	4505                	li	a0,1
    800045a4:	fffff097          	auipc	ra,0xfffff
    800045a8:	6e6080e7          	jalr	1766(ra) # 80003c8a <iget>
    800045ac:	89aa                	mv	s3,a0
    800045ae:	b7dd                	j	80004594 <namex+0x42>
      iunlockput(ip);
    800045b0:	854e                	mv	a0,s3
    800045b2:	00000097          	auipc	ra,0x0
    800045b6:	c6e080e7          	jalr	-914(ra) # 80004220 <iunlockput>
      return 0;
    800045ba:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800045bc:	854e                	mv	a0,s3
    800045be:	60e6                	ld	ra,88(sp)
    800045c0:	6446                	ld	s0,80(sp)
    800045c2:	64a6                	ld	s1,72(sp)
    800045c4:	6906                	ld	s2,64(sp)
    800045c6:	79e2                	ld	s3,56(sp)
    800045c8:	7a42                	ld	s4,48(sp)
    800045ca:	7aa2                	ld	s5,40(sp)
    800045cc:	7b02                	ld	s6,32(sp)
    800045ce:	6be2                	ld	s7,24(sp)
    800045d0:	6c42                	ld	s8,16(sp)
    800045d2:	6ca2                	ld	s9,8(sp)
    800045d4:	6125                	addi	sp,sp,96
    800045d6:	8082                	ret
      iunlock(ip);
    800045d8:	854e                	mv	a0,s3
    800045da:	00000097          	auipc	ra,0x0
    800045de:	aa6080e7          	jalr	-1370(ra) # 80004080 <iunlock>
      return ip;
    800045e2:	bfe9                	j	800045bc <namex+0x6a>
      iunlockput(ip);
    800045e4:	854e                	mv	a0,s3
    800045e6:	00000097          	auipc	ra,0x0
    800045ea:	c3a080e7          	jalr	-966(ra) # 80004220 <iunlockput>
      return 0;
    800045ee:	89d2                	mv	s3,s4
    800045f0:	b7f1                	j	800045bc <namex+0x6a>
  len = path - s;
    800045f2:	40b48633          	sub	a2,s1,a1
    800045f6:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    800045fa:	094cd463          	bge	s9,s4,80004682 <namex+0x130>
    memmove(name, s, DIRSIZ);
    800045fe:	4639                	li	a2,14
    80004600:	8556                	mv	a0,s5
    80004602:	ffffd097          	auipc	ra,0xffffd
    80004606:	86e080e7          	jalr	-1938(ra) # 80000e70 <memmove>
  while(*path == '/')
    8000460a:	0004c783          	lbu	a5,0(s1)
    8000460e:	01279763          	bne	a5,s2,8000461c <namex+0xca>
    path++;
    80004612:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004614:	0004c783          	lbu	a5,0(s1)
    80004618:	ff278de3          	beq	a5,s2,80004612 <namex+0xc0>
    ilock(ip);
    8000461c:	854e                	mv	a0,s3
    8000461e:	00000097          	auipc	ra,0x0
    80004622:	9a0080e7          	jalr	-1632(ra) # 80003fbe <ilock>
    if(ip->type != T_DIR){
    80004626:	04499783          	lh	a5,68(s3)
    8000462a:	f98793e3          	bne	a5,s8,800045b0 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    8000462e:	000b0563          	beqz	s6,80004638 <namex+0xe6>
    80004632:	0004c783          	lbu	a5,0(s1)
    80004636:	d3cd                	beqz	a5,800045d8 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004638:	865e                	mv	a2,s7
    8000463a:	85d6                	mv	a1,s5
    8000463c:	854e                	mv	a0,s3
    8000463e:	00000097          	auipc	ra,0x0
    80004642:	e64080e7          	jalr	-412(ra) # 800044a2 <dirlookup>
    80004646:	8a2a                	mv	s4,a0
    80004648:	dd51                	beqz	a0,800045e4 <namex+0x92>
    iunlockput(ip);
    8000464a:	854e                	mv	a0,s3
    8000464c:	00000097          	auipc	ra,0x0
    80004650:	bd4080e7          	jalr	-1068(ra) # 80004220 <iunlockput>
    ip = next;
    80004654:	89d2                	mv	s3,s4
  while(*path == '/')
    80004656:	0004c783          	lbu	a5,0(s1)
    8000465a:	05279763          	bne	a5,s2,800046a8 <namex+0x156>
    path++;
    8000465e:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004660:	0004c783          	lbu	a5,0(s1)
    80004664:	ff278de3          	beq	a5,s2,8000465e <namex+0x10c>
  if(*path == 0)
    80004668:	c79d                	beqz	a5,80004696 <namex+0x144>
    path++;
    8000466a:	85a6                	mv	a1,s1
  len = path - s;
    8000466c:	8a5e                	mv	s4,s7
    8000466e:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004670:	01278963          	beq	a5,s2,80004682 <namex+0x130>
    80004674:	dfbd                	beqz	a5,800045f2 <namex+0xa0>
    path++;
    80004676:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004678:	0004c783          	lbu	a5,0(s1)
    8000467c:	ff279ce3          	bne	a5,s2,80004674 <namex+0x122>
    80004680:	bf8d                	j	800045f2 <namex+0xa0>
    memmove(name, s, len);
    80004682:	2601                	sext.w	a2,a2
    80004684:	8556                	mv	a0,s5
    80004686:	ffffc097          	auipc	ra,0xffffc
    8000468a:	7ea080e7          	jalr	2026(ra) # 80000e70 <memmove>
    name[len] = 0;
    8000468e:	9a56                	add	s4,s4,s5
    80004690:	000a0023          	sb	zero,0(s4)
    80004694:	bf9d                	j	8000460a <namex+0xb8>
  if(nameiparent){
    80004696:	f20b03e3          	beqz	s6,800045bc <namex+0x6a>
    iput(ip);
    8000469a:	854e                	mv	a0,s3
    8000469c:	00000097          	auipc	ra,0x0
    800046a0:	adc080e7          	jalr	-1316(ra) # 80004178 <iput>
    return 0;
    800046a4:	4981                	li	s3,0
    800046a6:	bf19                	j	800045bc <namex+0x6a>
  if(*path == 0)
    800046a8:	d7fd                	beqz	a5,80004696 <namex+0x144>
  while(*path != '/' && *path != 0)
    800046aa:	0004c783          	lbu	a5,0(s1)
    800046ae:	85a6                	mv	a1,s1
    800046b0:	b7d1                	j	80004674 <namex+0x122>

00000000800046b2 <dirlink>:
{
    800046b2:	7139                	addi	sp,sp,-64
    800046b4:	fc06                	sd	ra,56(sp)
    800046b6:	f822                	sd	s0,48(sp)
    800046b8:	f426                	sd	s1,40(sp)
    800046ba:	f04a                	sd	s2,32(sp)
    800046bc:	ec4e                	sd	s3,24(sp)
    800046be:	e852                	sd	s4,16(sp)
    800046c0:	0080                	addi	s0,sp,64
    800046c2:	892a                	mv	s2,a0
    800046c4:	8a2e                	mv	s4,a1
    800046c6:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800046c8:	4601                	li	a2,0
    800046ca:	00000097          	auipc	ra,0x0
    800046ce:	dd8080e7          	jalr	-552(ra) # 800044a2 <dirlookup>
    800046d2:	e93d                	bnez	a0,80004748 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046d4:	04c92483          	lw	s1,76(s2)
    800046d8:	c49d                	beqz	s1,80004706 <dirlink+0x54>
    800046da:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800046dc:	4741                	li	a4,16
    800046de:	86a6                	mv	a3,s1
    800046e0:	fc040613          	addi	a2,s0,-64
    800046e4:	4581                	li	a1,0
    800046e6:	854a                	mv	a0,s2
    800046e8:	00000097          	auipc	ra,0x0
    800046ec:	b8a080e7          	jalr	-1142(ra) # 80004272 <readi>
    800046f0:	47c1                	li	a5,16
    800046f2:	06f51163          	bne	a0,a5,80004754 <dirlink+0xa2>
    if(de.inum == 0)
    800046f6:	fc045783          	lhu	a5,-64(s0)
    800046fa:	c791                	beqz	a5,80004706 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800046fc:	24c1                	addiw	s1,s1,16
    800046fe:	04c92783          	lw	a5,76(s2)
    80004702:	fcf4ede3          	bltu	s1,a5,800046dc <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004706:	4639                	li	a2,14
    80004708:	85d2                	mv	a1,s4
    8000470a:	fc240513          	addi	a0,s0,-62
    8000470e:	ffffd097          	auipc	ra,0xffffd
    80004712:	81a080e7          	jalr	-2022(ra) # 80000f28 <strncpy>
  de.inum = inum;
    80004716:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000471a:	4741                	li	a4,16
    8000471c:	86a6                	mv	a3,s1
    8000471e:	fc040613          	addi	a2,s0,-64
    80004722:	4581                	li	a1,0
    80004724:	854a                	mv	a0,s2
    80004726:	00000097          	auipc	ra,0x0
    8000472a:	c44080e7          	jalr	-956(ra) # 8000436a <writei>
    8000472e:	872a                	mv	a4,a0
    80004730:	47c1                	li	a5,16
  return 0;
    80004732:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004734:	02f71863          	bne	a4,a5,80004764 <dirlink+0xb2>
}
    80004738:	70e2                	ld	ra,56(sp)
    8000473a:	7442                	ld	s0,48(sp)
    8000473c:	74a2                	ld	s1,40(sp)
    8000473e:	7902                	ld	s2,32(sp)
    80004740:	69e2                	ld	s3,24(sp)
    80004742:	6a42                	ld	s4,16(sp)
    80004744:	6121                	addi	sp,sp,64
    80004746:	8082                	ret
    iput(ip);
    80004748:	00000097          	auipc	ra,0x0
    8000474c:	a30080e7          	jalr	-1488(ra) # 80004178 <iput>
    return -1;
    80004750:	557d                	li	a0,-1
    80004752:	b7dd                	j	80004738 <dirlink+0x86>
      panic("dirlink read");
    80004754:	00004517          	auipc	a0,0x4
    80004758:	ec450513          	addi	a0,a0,-316 # 80008618 <syscalls+0x1d8>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	dd4080e7          	jalr	-556(ra) # 80000530 <panic>
    panic("dirlink");
    80004764:	00004517          	auipc	a0,0x4
    80004768:	fc450513          	addi	a0,a0,-60 # 80008728 <syscalls+0x2e8>
    8000476c:	ffffc097          	auipc	ra,0xffffc
    80004770:	dc4080e7          	jalr	-572(ra) # 80000530 <panic>

0000000080004774 <namei>:

struct inode*
namei(char *path)
{
    80004774:	1101                	addi	sp,sp,-32
    80004776:	ec06                	sd	ra,24(sp)
    80004778:	e822                	sd	s0,16(sp)
    8000477a:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    8000477c:	fe040613          	addi	a2,s0,-32
    80004780:	4581                	li	a1,0
    80004782:	00000097          	auipc	ra,0x0
    80004786:	dd0080e7          	jalr	-560(ra) # 80004552 <namex>
}
    8000478a:	60e2                	ld	ra,24(sp)
    8000478c:	6442                	ld	s0,16(sp)
    8000478e:	6105                	addi	sp,sp,32
    80004790:	8082                	ret

0000000080004792 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004792:	1141                	addi	sp,sp,-16
    80004794:	e406                	sd	ra,8(sp)
    80004796:	e022                	sd	s0,0(sp)
    80004798:	0800                	addi	s0,sp,16
    8000479a:	862e                	mv	a2,a1
  return namex(path, 1, name);
    8000479c:	4585                	li	a1,1
    8000479e:	00000097          	auipc	ra,0x0
    800047a2:	db4080e7          	jalr	-588(ra) # 80004552 <namex>
}
    800047a6:	60a2                	ld	ra,8(sp)
    800047a8:	6402                	ld	s0,0(sp)
    800047aa:	0141                	addi	sp,sp,16
    800047ac:	8082                	ret

00000000800047ae <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800047ae:	1101                	addi	sp,sp,-32
    800047b0:	ec06                	sd	ra,24(sp)
    800047b2:	e822                	sd	s0,16(sp)
    800047b4:	e426                	sd	s1,8(sp)
    800047b6:	e04a                	sd	s2,0(sp)
    800047b8:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800047ba:	0001d917          	auipc	s2,0x1d
    800047be:	cbe90913          	addi	s2,s2,-834 # 80021478 <log>
    800047c2:	01892583          	lw	a1,24(s2)
    800047c6:	02892503          	lw	a0,40(s2)
    800047ca:	fffff097          	auipc	ra,0xfffff
    800047ce:	ff2080e7          	jalr	-14(ra) # 800037bc <bread>
    800047d2:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800047d4:	02c92683          	lw	a3,44(s2)
    800047d8:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800047da:	02d05763          	blez	a3,80004808 <write_head+0x5a>
    800047de:	0001d797          	auipc	a5,0x1d
    800047e2:	cca78793          	addi	a5,a5,-822 # 800214a8 <log+0x30>
    800047e6:	05c50713          	addi	a4,a0,92
    800047ea:	36fd                	addiw	a3,a3,-1
    800047ec:	1682                	slli	a3,a3,0x20
    800047ee:	9281                	srli	a3,a3,0x20
    800047f0:	068a                	slli	a3,a3,0x2
    800047f2:	0001d617          	auipc	a2,0x1d
    800047f6:	cba60613          	addi	a2,a2,-838 # 800214ac <log+0x34>
    800047fa:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800047fc:	4390                	lw	a2,0(a5)
    800047fe:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004800:	0791                	addi	a5,a5,4
    80004802:	0711                	addi	a4,a4,4
    80004804:	fed79ce3          	bne	a5,a3,800047fc <write_head+0x4e>
  }
  bwrite(buf);
    80004808:	8526                	mv	a0,s1
    8000480a:	fffff097          	auipc	ra,0xfffff
    8000480e:	0a4080e7          	jalr	164(ra) # 800038ae <bwrite>
  brelse(buf);
    80004812:	8526                	mv	a0,s1
    80004814:	fffff097          	auipc	ra,0xfffff
    80004818:	0d8080e7          	jalr	216(ra) # 800038ec <brelse>
}
    8000481c:	60e2                	ld	ra,24(sp)
    8000481e:	6442                	ld	s0,16(sp)
    80004820:	64a2                	ld	s1,8(sp)
    80004822:	6902                	ld	s2,0(sp)
    80004824:	6105                	addi	sp,sp,32
    80004826:	8082                	ret

0000000080004828 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004828:	0001d797          	auipc	a5,0x1d
    8000482c:	c7c7a783          	lw	a5,-900(a5) # 800214a4 <log+0x2c>
    80004830:	0af05d63          	blez	a5,800048ea <install_trans+0xc2>
{
    80004834:	7139                	addi	sp,sp,-64
    80004836:	fc06                	sd	ra,56(sp)
    80004838:	f822                	sd	s0,48(sp)
    8000483a:	f426                	sd	s1,40(sp)
    8000483c:	f04a                	sd	s2,32(sp)
    8000483e:	ec4e                	sd	s3,24(sp)
    80004840:	e852                	sd	s4,16(sp)
    80004842:	e456                	sd	s5,8(sp)
    80004844:	e05a                	sd	s6,0(sp)
    80004846:	0080                	addi	s0,sp,64
    80004848:	8b2a                	mv	s6,a0
    8000484a:	0001da97          	auipc	s5,0x1d
    8000484e:	c5ea8a93          	addi	s5,s5,-930 # 800214a8 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004852:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004854:	0001d997          	auipc	s3,0x1d
    80004858:	c2498993          	addi	s3,s3,-988 # 80021478 <log>
    8000485c:	a035                	j	80004888 <install_trans+0x60>
      bunpin(dbuf);
    8000485e:	8526                	mv	a0,s1
    80004860:	fffff097          	auipc	ra,0xfffff
    80004864:	166080e7          	jalr	358(ra) # 800039c6 <bunpin>
    brelse(lbuf);
    80004868:	854a                	mv	a0,s2
    8000486a:	fffff097          	auipc	ra,0xfffff
    8000486e:	082080e7          	jalr	130(ra) # 800038ec <brelse>
    brelse(dbuf);
    80004872:	8526                	mv	a0,s1
    80004874:	fffff097          	auipc	ra,0xfffff
    80004878:	078080e7          	jalr	120(ra) # 800038ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000487c:	2a05                	addiw	s4,s4,1
    8000487e:	0a91                	addi	s5,s5,4
    80004880:	02c9a783          	lw	a5,44(s3)
    80004884:	04fa5963          	bge	s4,a5,800048d6 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004888:	0189a583          	lw	a1,24(s3)
    8000488c:	014585bb          	addw	a1,a1,s4
    80004890:	2585                	addiw	a1,a1,1
    80004892:	0289a503          	lw	a0,40(s3)
    80004896:	fffff097          	auipc	ra,0xfffff
    8000489a:	f26080e7          	jalr	-218(ra) # 800037bc <bread>
    8000489e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800048a0:	000aa583          	lw	a1,0(s5)
    800048a4:	0289a503          	lw	a0,40(s3)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	f14080e7          	jalr	-236(ra) # 800037bc <bread>
    800048b0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800048b2:	40000613          	li	a2,1024
    800048b6:	05890593          	addi	a1,s2,88
    800048ba:	05850513          	addi	a0,a0,88
    800048be:	ffffc097          	auipc	ra,0xffffc
    800048c2:	5b2080e7          	jalr	1458(ra) # 80000e70 <memmove>
    bwrite(dbuf);  // write dst to disk
    800048c6:	8526                	mv	a0,s1
    800048c8:	fffff097          	auipc	ra,0xfffff
    800048cc:	fe6080e7          	jalr	-26(ra) # 800038ae <bwrite>
    if(recovering == 0)
    800048d0:	f80b1ce3          	bnez	s6,80004868 <install_trans+0x40>
    800048d4:	b769                	j	8000485e <install_trans+0x36>
}
    800048d6:	70e2                	ld	ra,56(sp)
    800048d8:	7442                	ld	s0,48(sp)
    800048da:	74a2                	ld	s1,40(sp)
    800048dc:	7902                	ld	s2,32(sp)
    800048de:	69e2                	ld	s3,24(sp)
    800048e0:	6a42                	ld	s4,16(sp)
    800048e2:	6aa2                	ld	s5,8(sp)
    800048e4:	6b02                	ld	s6,0(sp)
    800048e6:	6121                	addi	sp,sp,64
    800048e8:	8082                	ret
    800048ea:	8082                	ret

00000000800048ec <initlog>:
{
    800048ec:	7179                	addi	sp,sp,-48
    800048ee:	f406                	sd	ra,40(sp)
    800048f0:	f022                	sd	s0,32(sp)
    800048f2:	ec26                	sd	s1,24(sp)
    800048f4:	e84a                	sd	s2,16(sp)
    800048f6:	e44e                	sd	s3,8(sp)
    800048f8:	1800                	addi	s0,sp,48
    800048fa:	892a                	mv	s2,a0
    800048fc:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800048fe:	0001d497          	auipc	s1,0x1d
    80004902:	b7a48493          	addi	s1,s1,-1158 # 80021478 <log>
    80004906:	00004597          	auipc	a1,0x4
    8000490a:	d2258593          	addi	a1,a1,-734 # 80008628 <syscalls+0x1e8>
    8000490e:	8526                	mv	a0,s1
    80004910:	ffffc097          	auipc	ra,0xffffc
    80004914:	374080e7          	jalr	884(ra) # 80000c84 <initlock>
  log.start = sb->logstart;
    80004918:	0149a583          	lw	a1,20(s3)
    8000491c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000491e:	0109a783          	lw	a5,16(s3)
    80004922:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004924:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004928:	854a                	mv	a0,s2
    8000492a:	fffff097          	auipc	ra,0xfffff
    8000492e:	e92080e7          	jalr	-366(ra) # 800037bc <bread>
  log.lh.n = lh->n;
    80004932:	4d3c                	lw	a5,88(a0)
    80004934:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004936:	02f05563          	blez	a5,80004960 <initlog+0x74>
    8000493a:	05c50713          	addi	a4,a0,92
    8000493e:	0001d697          	auipc	a3,0x1d
    80004942:	b6a68693          	addi	a3,a3,-1174 # 800214a8 <log+0x30>
    80004946:	37fd                	addiw	a5,a5,-1
    80004948:	1782                	slli	a5,a5,0x20
    8000494a:	9381                	srli	a5,a5,0x20
    8000494c:	078a                	slli	a5,a5,0x2
    8000494e:	06050613          	addi	a2,a0,96
    80004952:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004954:	4310                	lw	a2,0(a4)
    80004956:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004958:	0711                	addi	a4,a4,4
    8000495a:	0691                	addi	a3,a3,4
    8000495c:	fef71ce3          	bne	a4,a5,80004954 <initlog+0x68>
  brelse(buf);
    80004960:	fffff097          	auipc	ra,0xfffff
    80004964:	f8c080e7          	jalr	-116(ra) # 800038ec <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004968:	4505                	li	a0,1
    8000496a:	00000097          	auipc	ra,0x0
    8000496e:	ebe080e7          	jalr	-322(ra) # 80004828 <install_trans>
  log.lh.n = 0;
    80004972:	0001d797          	auipc	a5,0x1d
    80004976:	b207a923          	sw	zero,-1230(a5) # 800214a4 <log+0x2c>
  write_head(); // clear the log
    8000497a:	00000097          	auipc	ra,0x0
    8000497e:	e34080e7          	jalr	-460(ra) # 800047ae <write_head>
}
    80004982:	70a2                	ld	ra,40(sp)
    80004984:	7402                	ld	s0,32(sp)
    80004986:	64e2                	ld	s1,24(sp)
    80004988:	6942                	ld	s2,16(sp)
    8000498a:	69a2                	ld	s3,8(sp)
    8000498c:	6145                	addi	sp,sp,48
    8000498e:	8082                	ret

0000000080004990 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004990:	1101                	addi	sp,sp,-32
    80004992:	ec06                	sd	ra,24(sp)
    80004994:	e822                	sd	s0,16(sp)
    80004996:	e426                	sd	s1,8(sp)
    80004998:	e04a                	sd	s2,0(sp)
    8000499a:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000499c:	0001d517          	auipc	a0,0x1d
    800049a0:	adc50513          	addi	a0,a0,-1316 # 80021478 <log>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	370080e7          	jalr	880(ra) # 80000d14 <acquire>
  while(1){
    if(log.committing){
    800049ac:	0001d497          	auipc	s1,0x1d
    800049b0:	acc48493          	addi	s1,s1,-1332 # 80021478 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049b4:	4979                	li	s2,30
    800049b6:	a039                	j	800049c4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800049b8:	85a6                	mv	a1,s1
    800049ba:	8526                	mv	a0,s1
    800049bc:	ffffe097          	auipc	ra,0xffffe
    800049c0:	17c080e7          	jalr	380(ra) # 80002b38 <sleep>
    if(log.committing){
    800049c4:	50dc                	lw	a5,36(s1)
    800049c6:	fbed                	bnez	a5,800049b8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800049c8:	509c                	lw	a5,32(s1)
    800049ca:	0017871b          	addiw	a4,a5,1
    800049ce:	0007069b          	sext.w	a3,a4
    800049d2:	0027179b          	slliw	a5,a4,0x2
    800049d6:	9fb9                	addw	a5,a5,a4
    800049d8:	0017979b          	slliw	a5,a5,0x1
    800049dc:	54d8                	lw	a4,44(s1)
    800049de:	9fb9                	addw	a5,a5,a4
    800049e0:	00f95963          	bge	s2,a5,800049f2 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800049e4:	85a6                	mv	a1,s1
    800049e6:	8526                	mv	a0,s1
    800049e8:	ffffe097          	auipc	ra,0xffffe
    800049ec:	150080e7          	jalr	336(ra) # 80002b38 <sleep>
    800049f0:	bfd1                	j	800049c4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800049f2:	0001d517          	auipc	a0,0x1d
    800049f6:	a8650513          	addi	a0,a0,-1402 # 80021478 <log>
    800049fa:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800049fc:	ffffc097          	auipc	ra,0xffffc
    80004a00:	3cc080e7          	jalr	972(ra) # 80000dc8 <release>
      break;
    }
  }
}
    80004a04:	60e2                	ld	ra,24(sp)
    80004a06:	6442                	ld	s0,16(sp)
    80004a08:	64a2                	ld	s1,8(sp)
    80004a0a:	6902                	ld	s2,0(sp)
    80004a0c:	6105                	addi	sp,sp,32
    80004a0e:	8082                	ret

0000000080004a10 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004a10:	7139                	addi	sp,sp,-64
    80004a12:	fc06                	sd	ra,56(sp)
    80004a14:	f822                	sd	s0,48(sp)
    80004a16:	f426                	sd	s1,40(sp)
    80004a18:	f04a                	sd	s2,32(sp)
    80004a1a:	ec4e                	sd	s3,24(sp)
    80004a1c:	e852                	sd	s4,16(sp)
    80004a1e:	e456                	sd	s5,8(sp)
    80004a20:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004a22:	0001d497          	auipc	s1,0x1d
    80004a26:	a5648493          	addi	s1,s1,-1450 # 80021478 <log>
    80004a2a:	8526                	mv	a0,s1
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	2e8080e7          	jalr	744(ra) # 80000d14 <acquire>
  log.outstanding -= 1;
    80004a34:	509c                	lw	a5,32(s1)
    80004a36:	37fd                	addiw	a5,a5,-1
    80004a38:	0007891b          	sext.w	s2,a5
    80004a3c:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004a3e:	50dc                	lw	a5,36(s1)
    80004a40:	efb9                	bnez	a5,80004a9e <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004a42:	06091663          	bnez	s2,80004aae <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004a46:	0001d497          	auipc	s1,0x1d
    80004a4a:	a3248493          	addi	s1,s1,-1486 # 80021478 <log>
    80004a4e:	4785                	li	a5,1
    80004a50:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004a52:	8526                	mv	a0,s1
    80004a54:	ffffc097          	auipc	ra,0xffffc
    80004a58:	374080e7          	jalr	884(ra) # 80000dc8 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004a5c:	54dc                	lw	a5,44(s1)
    80004a5e:	06f04763          	bgtz	a5,80004acc <end_op+0xbc>
    acquire(&log.lock);
    80004a62:	0001d497          	auipc	s1,0x1d
    80004a66:	a1648493          	addi	s1,s1,-1514 # 80021478 <log>
    80004a6a:	8526                	mv	a0,s1
    80004a6c:	ffffc097          	auipc	ra,0xffffc
    80004a70:	2a8080e7          	jalr	680(ra) # 80000d14 <acquire>
    log.committing = 0;
    80004a74:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004a78:	8526                	mv	a0,s1
    80004a7a:	ffffe097          	auipc	ra,0xffffe
    80004a7e:	244080e7          	jalr	580(ra) # 80002cbe <wakeup>
    release(&log.lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	344080e7          	jalr	836(ra) # 80000dc8 <release>
}
    80004a8c:	70e2                	ld	ra,56(sp)
    80004a8e:	7442                	ld	s0,48(sp)
    80004a90:	74a2                	ld	s1,40(sp)
    80004a92:	7902                	ld	s2,32(sp)
    80004a94:	69e2                	ld	s3,24(sp)
    80004a96:	6a42                	ld	s4,16(sp)
    80004a98:	6aa2                	ld	s5,8(sp)
    80004a9a:	6121                	addi	sp,sp,64
    80004a9c:	8082                	ret
    panic("log.committing");
    80004a9e:	00004517          	auipc	a0,0x4
    80004aa2:	b9250513          	addi	a0,a0,-1134 # 80008630 <syscalls+0x1f0>
    80004aa6:	ffffc097          	auipc	ra,0xffffc
    80004aaa:	a8a080e7          	jalr	-1398(ra) # 80000530 <panic>
    wakeup(&log);
    80004aae:	0001d497          	auipc	s1,0x1d
    80004ab2:	9ca48493          	addi	s1,s1,-1590 # 80021478 <log>
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffe097          	auipc	ra,0xffffe
    80004abc:	206080e7          	jalr	518(ra) # 80002cbe <wakeup>
  release(&log.lock);
    80004ac0:	8526                	mv	a0,s1
    80004ac2:	ffffc097          	auipc	ra,0xffffc
    80004ac6:	306080e7          	jalr	774(ra) # 80000dc8 <release>
  if(do_commit){
    80004aca:	b7c9                	j	80004a8c <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004acc:	0001da97          	auipc	s5,0x1d
    80004ad0:	9dca8a93          	addi	s5,s5,-1572 # 800214a8 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004ad4:	0001da17          	auipc	s4,0x1d
    80004ad8:	9a4a0a13          	addi	s4,s4,-1628 # 80021478 <log>
    80004adc:	018a2583          	lw	a1,24(s4)
    80004ae0:	012585bb          	addw	a1,a1,s2
    80004ae4:	2585                	addiw	a1,a1,1
    80004ae6:	028a2503          	lw	a0,40(s4)
    80004aea:	fffff097          	auipc	ra,0xfffff
    80004aee:	cd2080e7          	jalr	-814(ra) # 800037bc <bread>
    80004af2:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004af4:	000aa583          	lw	a1,0(s5)
    80004af8:	028a2503          	lw	a0,40(s4)
    80004afc:	fffff097          	auipc	ra,0xfffff
    80004b00:	cc0080e7          	jalr	-832(ra) # 800037bc <bread>
    80004b04:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004b06:	40000613          	li	a2,1024
    80004b0a:	05850593          	addi	a1,a0,88
    80004b0e:	05848513          	addi	a0,s1,88
    80004b12:	ffffc097          	auipc	ra,0xffffc
    80004b16:	35e080e7          	jalr	862(ra) # 80000e70 <memmove>
    bwrite(to);  // write the log
    80004b1a:	8526                	mv	a0,s1
    80004b1c:	fffff097          	auipc	ra,0xfffff
    80004b20:	d92080e7          	jalr	-622(ra) # 800038ae <bwrite>
    brelse(from);
    80004b24:	854e                	mv	a0,s3
    80004b26:	fffff097          	auipc	ra,0xfffff
    80004b2a:	dc6080e7          	jalr	-570(ra) # 800038ec <brelse>
    brelse(to);
    80004b2e:	8526                	mv	a0,s1
    80004b30:	fffff097          	auipc	ra,0xfffff
    80004b34:	dbc080e7          	jalr	-580(ra) # 800038ec <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b38:	2905                	addiw	s2,s2,1
    80004b3a:	0a91                	addi	s5,s5,4
    80004b3c:	02ca2783          	lw	a5,44(s4)
    80004b40:	f8f94ee3          	blt	s2,a5,80004adc <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004b44:	00000097          	auipc	ra,0x0
    80004b48:	c6a080e7          	jalr	-918(ra) # 800047ae <write_head>
    install_trans(0); // Now install writes to home locations
    80004b4c:	4501                	li	a0,0
    80004b4e:	00000097          	auipc	ra,0x0
    80004b52:	cda080e7          	jalr	-806(ra) # 80004828 <install_trans>
    log.lh.n = 0;
    80004b56:	0001d797          	auipc	a5,0x1d
    80004b5a:	9407a723          	sw	zero,-1714(a5) # 800214a4 <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004b5e:	00000097          	auipc	ra,0x0
    80004b62:	c50080e7          	jalr	-944(ra) # 800047ae <write_head>
    80004b66:	bdf5                	j	80004a62 <end_op+0x52>

0000000080004b68 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004b68:	1101                	addi	sp,sp,-32
    80004b6a:	ec06                	sd	ra,24(sp)
    80004b6c:	e822                	sd	s0,16(sp)
    80004b6e:	e426                	sd	s1,8(sp)
    80004b70:	e04a                	sd	s2,0(sp)
    80004b72:	1000                	addi	s0,sp,32
  int i;

  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004b74:	0001d717          	auipc	a4,0x1d
    80004b78:	93072703          	lw	a4,-1744(a4) # 800214a4 <log+0x2c>
    80004b7c:	47f5                	li	a5,29
    80004b7e:	08e7c063          	blt	a5,a4,80004bfe <log_write+0x96>
    80004b82:	84aa                	mv	s1,a0
    80004b84:	0001d797          	auipc	a5,0x1d
    80004b88:	9107a783          	lw	a5,-1776(a5) # 80021494 <log+0x1c>
    80004b8c:	37fd                	addiw	a5,a5,-1
    80004b8e:	06f75863          	bge	a4,a5,80004bfe <log_write+0x96>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004b92:	0001d797          	auipc	a5,0x1d
    80004b96:	9067a783          	lw	a5,-1786(a5) # 80021498 <log+0x20>
    80004b9a:	06f05a63          	blez	a5,80004c0e <log_write+0xa6>
    panic("log_write outside of trans");

  acquire(&log.lock);
    80004b9e:	0001d917          	auipc	s2,0x1d
    80004ba2:	8da90913          	addi	s2,s2,-1830 # 80021478 <log>
    80004ba6:	854a                	mv	a0,s2
    80004ba8:	ffffc097          	auipc	ra,0xffffc
    80004bac:	16c080e7          	jalr	364(ra) # 80000d14 <acquire>
  for (i = 0; i < log.lh.n; i++) {
    80004bb0:	02c92603          	lw	a2,44(s2)
    80004bb4:	06c05563          	blez	a2,80004c1e <log_write+0xb6>
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bb8:	44cc                	lw	a1,12(s1)
    80004bba:	0001d717          	auipc	a4,0x1d
    80004bbe:	8ee70713          	addi	a4,a4,-1810 # 800214a8 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004bc2:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorbtion
    80004bc4:	4314                	lw	a3,0(a4)
    80004bc6:	04b68d63          	beq	a3,a1,80004c20 <log_write+0xb8>
  for (i = 0; i < log.lh.n; i++) {
    80004bca:	2785                	addiw	a5,a5,1
    80004bcc:	0711                	addi	a4,a4,4
    80004bce:	fec79be3          	bne	a5,a2,80004bc4 <log_write+0x5c>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004bd2:	0621                	addi	a2,a2,8
    80004bd4:	060a                	slli	a2,a2,0x2
    80004bd6:	0001d797          	auipc	a5,0x1d
    80004bda:	8a278793          	addi	a5,a5,-1886 # 80021478 <log>
    80004bde:	963e                	add	a2,a2,a5
    80004be0:	44dc                	lw	a5,12(s1)
    80004be2:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004be4:	8526                	mv	a0,s1
    80004be6:	fffff097          	auipc	ra,0xfffff
    80004bea:	da4080e7          	jalr	-604(ra) # 8000398a <bpin>
    log.lh.n++;
    80004bee:	0001d717          	auipc	a4,0x1d
    80004bf2:	88a70713          	addi	a4,a4,-1910 # 80021478 <log>
    80004bf6:	575c                	lw	a5,44(a4)
    80004bf8:	2785                	addiw	a5,a5,1
    80004bfa:	d75c                	sw	a5,44(a4)
    80004bfc:	a83d                	j	80004c3a <log_write+0xd2>
    panic("too big a transaction");
    80004bfe:	00004517          	auipc	a0,0x4
    80004c02:	a4250513          	addi	a0,a0,-1470 # 80008640 <syscalls+0x200>
    80004c06:	ffffc097          	auipc	ra,0xffffc
    80004c0a:	92a080e7          	jalr	-1750(ra) # 80000530 <panic>
    panic("log_write outside of trans");
    80004c0e:	00004517          	auipc	a0,0x4
    80004c12:	a4a50513          	addi	a0,a0,-1462 # 80008658 <syscalls+0x218>
    80004c16:	ffffc097          	auipc	ra,0xffffc
    80004c1a:	91a080e7          	jalr	-1766(ra) # 80000530 <panic>
  for (i = 0; i < log.lh.n; i++) {
    80004c1e:	4781                	li	a5,0
  log.lh.block[i] = b->blockno;
    80004c20:	00878713          	addi	a4,a5,8
    80004c24:	00271693          	slli	a3,a4,0x2
    80004c28:	0001d717          	auipc	a4,0x1d
    80004c2c:	85070713          	addi	a4,a4,-1968 # 80021478 <log>
    80004c30:	9736                	add	a4,a4,a3
    80004c32:	44d4                	lw	a3,12(s1)
    80004c34:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004c36:	faf607e3          	beq	a2,a5,80004be4 <log_write+0x7c>
  }
  release(&log.lock);
    80004c3a:	0001d517          	auipc	a0,0x1d
    80004c3e:	83e50513          	addi	a0,a0,-1986 # 80021478 <log>
    80004c42:	ffffc097          	auipc	ra,0xffffc
    80004c46:	186080e7          	jalr	390(ra) # 80000dc8 <release>
}
    80004c4a:	60e2                	ld	ra,24(sp)
    80004c4c:	6442                	ld	s0,16(sp)
    80004c4e:	64a2                	ld	s1,8(sp)
    80004c50:	6902                	ld	s2,0(sp)
    80004c52:	6105                	addi	sp,sp,32
    80004c54:	8082                	ret

0000000080004c56 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004c56:	1101                	addi	sp,sp,-32
    80004c58:	ec06                	sd	ra,24(sp)
    80004c5a:	e822                	sd	s0,16(sp)
    80004c5c:	e426                	sd	s1,8(sp)
    80004c5e:	e04a                	sd	s2,0(sp)
    80004c60:	1000                	addi	s0,sp,32
    80004c62:	84aa                	mv	s1,a0
    80004c64:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004c66:	00004597          	auipc	a1,0x4
    80004c6a:	a1258593          	addi	a1,a1,-1518 # 80008678 <syscalls+0x238>
    80004c6e:	0521                	addi	a0,a0,8
    80004c70:	ffffc097          	auipc	ra,0xffffc
    80004c74:	014080e7          	jalr	20(ra) # 80000c84 <initlock>
  lk->name = name;
    80004c78:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004c7c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004c80:	0204a423          	sw	zero,40(s1)
}
    80004c84:	60e2                	ld	ra,24(sp)
    80004c86:	6442                	ld	s0,16(sp)
    80004c88:	64a2                	ld	s1,8(sp)
    80004c8a:	6902                	ld	s2,0(sp)
    80004c8c:	6105                	addi	sp,sp,32
    80004c8e:	8082                	ret

0000000080004c90 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004c90:	1101                	addi	sp,sp,-32
    80004c92:	ec06                	sd	ra,24(sp)
    80004c94:	e822                	sd	s0,16(sp)
    80004c96:	e426                	sd	s1,8(sp)
    80004c98:	e04a                	sd	s2,0(sp)
    80004c9a:	1000                	addi	s0,sp,32
    80004c9c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004c9e:	00850913          	addi	s2,a0,8
    80004ca2:	854a                	mv	a0,s2
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	070080e7          	jalr	112(ra) # 80000d14 <acquire>
  while (lk->locked) {
    80004cac:	409c                	lw	a5,0(s1)
    80004cae:	cb89                	beqz	a5,80004cc0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004cb0:	85ca                	mv	a1,s2
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffe097          	auipc	ra,0xffffe
    80004cb8:	e84080e7          	jalr	-380(ra) # 80002b38 <sleep>
  while (lk->locked) {
    80004cbc:	409c                	lw	a5,0(s1)
    80004cbe:	fbed                	bnez	a5,80004cb0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004cc0:	4785                	li	a5,1
    80004cc2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004cc4:	ffffd097          	auipc	ra,0xffffd
    80004cc8:	512080e7          	jalr	1298(ra) # 800021d6 <myproc>
    80004ccc:	5d1c                	lw	a5,56(a0)
    80004cce:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004cd0:	854a                	mv	a0,s2
    80004cd2:	ffffc097          	auipc	ra,0xffffc
    80004cd6:	0f6080e7          	jalr	246(ra) # 80000dc8 <release>
}
    80004cda:	60e2                	ld	ra,24(sp)
    80004cdc:	6442                	ld	s0,16(sp)
    80004cde:	64a2                	ld	s1,8(sp)
    80004ce0:	6902                	ld	s2,0(sp)
    80004ce2:	6105                	addi	sp,sp,32
    80004ce4:	8082                	ret

0000000080004ce6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004ce6:	1101                	addi	sp,sp,-32
    80004ce8:	ec06                	sd	ra,24(sp)
    80004cea:	e822                	sd	s0,16(sp)
    80004cec:	e426                	sd	s1,8(sp)
    80004cee:	e04a                	sd	s2,0(sp)
    80004cf0:	1000                	addi	s0,sp,32
    80004cf2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004cf4:	00850913          	addi	s2,a0,8
    80004cf8:	854a                	mv	a0,s2
    80004cfa:	ffffc097          	auipc	ra,0xffffc
    80004cfe:	01a080e7          	jalr	26(ra) # 80000d14 <acquire>
  lk->locked = 0;
    80004d02:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004d06:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80004d0a:	8526                	mv	a0,s1
    80004d0c:	ffffe097          	auipc	ra,0xffffe
    80004d10:	fb2080e7          	jalr	-78(ra) # 80002cbe <wakeup>
  release(&lk->lk);
    80004d14:	854a                	mv	a0,s2
    80004d16:	ffffc097          	auipc	ra,0xffffc
    80004d1a:	0b2080e7          	jalr	178(ra) # 80000dc8 <release>
}
    80004d1e:	60e2                	ld	ra,24(sp)
    80004d20:	6442                	ld	s0,16(sp)
    80004d22:	64a2                	ld	s1,8(sp)
    80004d24:	6902                	ld	s2,0(sp)
    80004d26:	6105                	addi	sp,sp,32
    80004d28:	8082                	ret

0000000080004d2a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80004d2a:	7179                	addi	sp,sp,-48
    80004d2c:	f406                	sd	ra,40(sp)
    80004d2e:	f022                	sd	s0,32(sp)
    80004d30:	ec26                	sd	s1,24(sp)
    80004d32:	e84a                	sd	s2,16(sp)
    80004d34:	e44e                	sd	s3,8(sp)
    80004d36:	1800                	addi	s0,sp,48
    80004d38:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80004d3a:	00850913          	addi	s2,a0,8
    80004d3e:	854a                	mv	a0,s2
    80004d40:	ffffc097          	auipc	ra,0xffffc
    80004d44:	fd4080e7          	jalr	-44(ra) # 80000d14 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d48:	409c                	lw	a5,0(s1)
    80004d4a:	ef99                	bnez	a5,80004d68 <holdingsleep+0x3e>
    80004d4c:	4481                	li	s1,0
  release(&lk->lk);
    80004d4e:	854a                	mv	a0,s2
    80004d50:	ffffc097          	auipc	ra,0xffffc
    80004d54:	078080e7          	jalr	120(ra) # 80000dc8 <release>
  return r;
}
    80004d58:	8526                	mv	a0,s1
    80004d5a:	70a2                	ld	ra,40(sp)
    80004d5c:	7402                	ld	s0,32(sp)
    80004d5e:	64e2                	ld	s1,24(sp)
    80004d60:	6942                	ld	s2,16(sp)
    80004d62:	69a2                	ld	s3,8(sp)
    80004d64:	6145                	addi	sp,sp,48
    80004d66:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004d68:	0284a983          	lw	s3,40(s1)
    80004d6c:	ffffd097          	auipc	ra,0xffffd
    80004d70:	46a080e7          	jalr	1130(ra) # 800021d6 <myproc>
    80004d74:	5d04                	lw	s1,56(a0)
    80004d76:	413484b3          	sub	s1,s1,s3
    80004d7a:	0014b493          	seqz	s1,s1
    80004d7e:	bfc1                	j	80004d4e <holdingsleep+0x24>

0000000080004d80 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004d80:	1141                	addi	sp,sp,-16
    80004d82:	e406                	sd	ra,8(sp)
    80004d84:	e022                	sd	s0,0(sp)
    80004d86:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004d88:	00004597          	auipc	a1,0x4
    80004d8c:	90058593          	addi	a1,a1,-1792 # 80008688 <syscalls+0x248>
    80004d90:	0001d517          	auipc	a0,0x1d
    80004d94:	83050513          	addi	a0,a0,-2000 # 800215c0 <ftable>
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	eec080e7          	jalr	-276(ra) # 80000c84 <initlock>
}
    80004da0:	60a2                	ld	ra,8(sp)
    80004da2:	6402                	ld	s0,0(sp)
    80004da4:	0141                	addi	sp,sp,16
    80004da6:	8082                	ret

0000000080004da8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004da8:	1101                	addi	sp,sp,-32
    80004daa:	ec06                	sd	ra,24(sp)
    80004dac:	e822                	sd	s0,16(sp)
    80004dae:	e426                	sd	s1,8(sp)
    80004db0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004db2:	0001d517          	auipc	a0,0x1d
    80004db6:	80e50513          	addi	a0,a0,-2034 # 800215c0 <ftable>
    80004dba:	ffffc097          	auipc	ra,0xffffc
    80004dbe:	f5a080e7          	jalr	-166(ra) # 80000d14 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dc2:	0001d497          	auipc	s1,0x1d
    80004dc6:	81648493          	addi	s1,s1,-2026 # 800215d8 <ftable+0x18>
    80004dca:	0001d717          	auipc	a4,0x1d
    80004dce:	7ae70713          	addi	a4,a4,1966 # 80022578 <ftable+0xfb8>
    if(f->ref == 0){
    80004dd2:	40dc                	lw	a5,4(s1)
    80004dd4:	cf99                	beqz	a5,80004df2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004dd6:	02848493          	addi	s1,s1,40
    80004dda:	fee49ce3          	bne	s1,a4,80004dd2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004dde:	0001c517          	auipc	a0,0x1c
    80004de2:	7e250513          	addi	a0,a0,2018 # 800215c0 <ftable>
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	fe2080e7          	jalr	-30(ra) # 80000dc8 <release>
  return 0;
    80004dee:	4481                	li	s1,0
    80004df0:	a819                	j	80004e06 <filealloc+0x5e>
      f->ref = 1;
    80004df2:	4785                	li	a5,1
    80004df4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80004df6:	0001c517          	auipc	a0,0x1c
    80004dfa:	7ca50513          	addi	a0,a0,1994 # 800215c0 <ftable>
    80004dfe:	ffffc097          	auipc	ra,0xffffc
    80004e02:	fca080e7          	jalr	-54(ra) # 80000dc8 <release>
}
    80004e06:	8526                	mv	a0,s1
    80004e08:	60e2                	ld	ra,24(sp)
    80004e0a:	6442                	ld	s0,16(sp)
    80004e0c:	64a2                	ld	s1,8(sp)
    80004e0e:	6105                	addi	sp,sp,32
    80004e10:	8082                	ret

0000000080004e12 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004e12:	1101                	addi	sp,sp,-32
    80004e14:	ec06                	sd	ra,24(sp)
    80004e16:	e822                	sd	s0,16(sp)
    80004e18:	e426                	sd	s1,8(sp)
    80004e1a:	1000                	addi	s0,sp,32
    80004e1c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004e1e:	0001c517          	auipc	a0,0x1c
    80004e22:	7a250513          	addi	a0,a0,1954 # 800215c0 <ftable>
    80004e26:	ffffc097          	auipc	ra,0xffffc
    80004e2a:	eee080e7          	jalr	-274(ra) # 80000d14 <acquire>
  if(f->ref < 1)
    80004e2e:	40dc                	lw	a5,4(s1)
    80004e30:	02f05263          	blez	a5,80004e54 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004e34:	2785                	addiw	a5,a5,1
    80004e36:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004e38:	0001c517          	auipc	a0,0x1c
    80004e3c:	78850513          	addi	a0,a0,1928 # 800215c0 <ftable>
    80004e40:	ffffc097          	auipc	ra,0xffffc
    80004e44:	f88080e7          	jalr	-120(ra) # 80000dc8 <release>
  return f;
}
    80004e48:	8526                	mv	a0,s1
    80004e4a:	60e2                	ld	ra,24(sp)
    80004e4c:	6442                	ld	s0,16(sp)
    80004e4e:	64a2                	ld	s1,8(sp)
    80004e50:	6105                	addi	sp,sp,32
    80004e52:	8082                	ret
    panic("filedup");
    80004e54:	00004517          	auipc	a0,0x4
    80004e58:	83c50513          	addi	a0,a0,-1988 # 80008690 <syscalls+0x250>
    80004e5c:	ffffb097          	auipc	ra,0xffffb
    80004e60:	6d4080e7          	jalr	1748(ra) # 80000530 <panic>

0000000080004e64 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004e64:	7139                	addi	sp,sp,-64
    80004e66:	fc06                	sd	ra,56(sp)
    80004e68:	f822                	sd	s0,48(sp)
    80004e6a:	f426                	sd	s1,40(sp)
    80004e6c:	f04a                	sd	s2,32(sp)
    80004e6e:	ec4e                	sd	s3,24(sp)
    80004e70:	e852                	sd	s4,16(sp)
    80004e72:	e456                	sd	s5,8(sp)
    80004e74:	0080                	addi	s0,sp,64
    80004e76:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004e78:	0001c517          	auipc	a0,0x1c
    80004e7c:	74850513          	addi	a0,a0,1864 # 800215c0 <ftable>
    80004e80:	ffffc097          	auipc	ra,0xffffc
    80004e84:	e94080e7          	jalr	-364(ra) # 80000d14 <acquire>
  if(f->ref < 1)
    80004e88:	40dc                	lw	a5,4(s1)
    80004e8a:	06f05163          	blez	a5,80004eec <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    80004e8e:	37fd                	addiw	a5,a5,-1
    80004e90:	0007871b          	sext.w	a4,a5
    80004e94:	c0dc                	sw	a5,4(s1)
    80004e96:	06e04363          	bgtz	a4,80004efc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80004e9a:	0004a903          	lw	s2,0(s1)
    80004e9e:	0094ca83          	lbu	s5,9(s1)
    80004ea2:	0104ba03          	ld	s4,16(s1)
    80004ea6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80004eaa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80004eae:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004eb2:	0001c517          	auipc	a0,0x1c
    80004eb6:	70e50513          	addi	a0,a0,1806 # 800215c0 <ftable>
    80004eba:	ffffc097          	auipc	ra,0xffffc
    80004ebe:	f0e080e7          	jalr	-242(ra) # 80000dc8 <release>

  if(ff.type == FD_PIPE){
    80004ec2:	4785                	li	a5,1
    80004ec4:	04f90d63          	beq	s2,a5,80004f1e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004ec8:	3979                	addiw	s2,s2,-2
    80004eca:	4785                	li	a5,1
    80004ecc:	0527e063          	bltu	a5,s2,80004f0c <fileclose+0xa8>
    begin_op();
    80004ed0:	00000097          	auipc	ra,0x0
    80004ed4:	ac0080e7          	jalr	-1344(ra) # 80004990 <begin_op>
    iput(ff.ip);
    80004ed8:	854e                	mv	a0,s3
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	29e080e7          	jalr	670(ra) # 80004178 <iput>
    end_op();
    80004ee2:	00000097          	auipc	ra,0x0
    80004ee6:	b2e080e7          	jalr	-1234(ra) # 80004a10 <end_op>
    80004eea:	a00d                	j	80004f0c <fileclose+0xa8>
    panic("fileclose");
    80004eec:	00003517          	auipc	a0,0x3
    80004ef0:	7ac50513          	addi	a0,a0,1964 # 80008698 <syscalls+0x258>
    80004ef4:	ffffb097          	auipc	ra,0xffffb
    80004ef8:	63c080e7          	jalr	1596(ra) # 80000530 <panic>
    release(&ftable.lock);
    80004efc:	0001c517          	auipc	a0,0x1c
    80004f00:	6c450513          	addi	a0,a0,1732 # 800215c0 <ftable>
    80004f04:	ffffc097          	auipc	ra,0xffffc
    80004f08:	ec4080e7          	jalr	-316(ra) # 80000dc8 <release>
  }
}
    80004f0c:	70e2                	ld	ra,56(sp)
    80004f0e:	7442                	ld	s0,48(sp)
    80004f10:	74a2                	ld	s1,40(sp)
    80004f12:	7902                	ld	s2,32(sp)
    80004f14:	69e2                	ld	s3,24(sp)
    80004f16:	6a42                	ld	s4,16(sp)
    80004f18:	6aa2                	ld	s5,8(sp)
    80004f1a:	6121                	addi	sp,sp,64
    80004f1c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004f1e:	85d6                	mv	a1,s5
    80004f20:	8552                	mv	a0,s4
    80004f22:	00000097          	auipc	ra,0x0
    80004f26:	34c080e7          	jalr	844(ra) # 8000526e <pipeclose>
    80004f2a:	b7cd                	j	80004f0c <fileclose+0xa8>

0000000080004f2c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004f2c:	715d                	addi	sp,sp,-80
    80004f2e:	e486                	sd	ra,72(sp)
    80004f30:	e0a2                	sd	s0,64(sp)
    80004f32:	fc26                	sd	s1,56(sp)
    80004f34:	f84a                	sd	s2,48(sp)
    80004f36:	f44e                	sd	s3,40(sp)
    80004f38:	0880                	addi	s0,sp,80
    80004f3a:	84aa                	mv	s1,a0
    80004f3c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004f3e:	ffffd097          	auipc	ra,0xffffd
    80004f42:	298080e7          	jalr	664(ra) # 800021d6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004f46:	409c                	lw	a5,0(s1)
    80004f48:	37f9                	addiw	a5,a5,-2
    80004f4a:	4705                	li	a4,1
    80004f4c:	04f76763          	bltu	a4,a5,80004f9a <filestat+0x6e>
    80004f50:	892a                	mv	s2,a0
    ilock(f->ip);
    80004f52:	6c88                	ld	a0,24(s1)
    80004f54:	fffff097          	auipc	ra,0xfffff
    80004f58:	06a080e7          	jalr	106(ra) # 80003fbe <ilock>
    stati(f->ip, &st);
    80004f5c:	fb840593          	addi	a1,s0,-72
    80004f60:	6c88                	ld	a0,24(s1)
    80004f62:	fffff097          	auipc	ra,0xfffff
    80004f66:	2e6080e7          	jalr	742(ra) # 80004248 <stati>
    iunlock(f->ip);
    80004f6a:	6c88                	ld	a0,24(s1)
    80004f6c:	fffff097          	auipc	ra,0xfffff
    80004f70:	114080e7          	jalr	276(ra) # 80004080 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004f74:	46e1                	li	a3,24
    80004f76:	fb840613          	addi	a2,s0,-72
    80004f7a:	85ce                	mv	a1,s3
    80004f7c:	05093503          	ld	a0,80(s2)
    80004f80:	ffffd097          	auipc	ra,0xffffd
    80004f84:	c16080e7          	jalr	-1002(ra) # 80001b96 <copyout>
    80004f88:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004f8c:	60a6                	ld	ra,72(sp)
    80004f8e:	6406                	ld	s0,64(sp)
    80004f90:	74e2                	ld	s1,56(sp)
    80004f92:	7942                	ld	s2,48(sp)
    80004f94:	79a2                	ld	s3,40(sp)
    80004f96:	6161                	addi	sp,sp,80
    80004f98:	8082                	ret
  return -1;
    80004f9a:	557d                	li	a0,-1
    80004f9c:	bfc5                	j	80004f8c <filestat+0x60>

0000000080004f9e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004f9e:	7179                	addi	sp,sp,-48
    80004fa0:	f406                	sd	ra,40(sp)
    80004fa2:	f022                	sd	s0,32(sp)
    80004fa4:	ec26                	sd	s1,24(sp)
    80004fa6:	e84a                	sd	s2,16(sp)
    80004fa8:	e44e                	sd	s3,8(sp)
    80004faa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004fac:	00854783          	lbu	a5,8(a0)
    80004fb0:	c3d5                	beqz	a5,80005054 <fileread+0xb6>
    80004fb2:	84aa                	mv	s1,a0
    80004fb4:	89ae                	mv	s3,a1
    80004fb6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004fb8:	411c                	lw	a5,0(a0)
    80004fba:	4705                	li	a4,1
    80004fbc:	04e78963          	beq	a5,a4,8000500e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004fc0:	470d                	li	a4,3
    80004fc2:	04e78d63          	beq	a5,a4,8000501c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004fc6:	4709                	li	a4,2
    80004fc8:	06e79e63          	bne	a5,a4,80005044 <fileread+0xa6>
    ilock(f->ip);
    80004fcc:	6d08                	ld	a0,24(a0)
    80004fce:	fffff097          	auipc	ra,0xfffff
    80004fd2:	ff0080e7          	jalr	-16(ra) # 80003fbe <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004fd6:	874a                	mv	a4,s2
    80004fd8:	5094                	lw	a3,32(s1)
    80004fda:	864e                	mv	a2,s3
    80004fdc:	4585                	li	a1,1
    80004fde:	6c88                	ld	a0,24(s1)
    80004fe0:	fffff097          	auipc	ra,0xfffff
    80004fe4:	292080e7          	jalr	658(ra) # 80004272 <readi>
    80004fe8:	892a                	mv	s2,a0
    80004fea:	00a05563          	blez	a0,80004ff4 <fileread+0x56>
      f->off += r;
    80004fee:	509c                	lw	a5,32(s1)
    80004ff0:	9fa9                	addw	a5,a5,a0
    80004ff2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004ff4:	6c88                	ld	a0,24(s1)
    80004ff6:	fffff097          	auipc	ra,0xfffff
    80004ffa:	08a080e7          	jalr	138(ra) # 80004080 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004ffe:	854a                	mv	a0,s2
    80005000:	70a2                	ld	ra,40(sp)
    80005002:	7402                	ld	s0,32(sp)
    80005004:	64e2                	ld	s1,24(sp)
    80005006:	6942                	ld	s2,16(sp)
    80005008:	69a2                	ld	s3,8(sp)
    8000500a:	6145                	addi	sp,sp,48
    8000500c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000500e:	6908                	ld	a0,16(a0)
    80005010:	00000097          	auipc	ra,0x0
    80005014:	3c8080e7          	jalr	968(ra) # 800053d8 <piperead>
    80005018:	892a                	mv	s2,a0
    8000501a:	b7d5                	j	80004ffe <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000501c:	02451783          	lh	a5,36(a0)
    80005020:	03079693          	slli	a3,a5,0x30
    80005024:	92c1                	srli	a3,a3,0x30
    80005026:	4725                	li	a4,9
    80005028:	02d76863          	bltu	a4,a3,80005058 <fileread+0xba>
    8000502c:	0792                	slli	a5,a5,0x4
    8000502e:	0001c717          	auipc	a4,0x1c
    80005032:	4f270713          	addi	a4,a4,1266 # 80021520 <devsw>
    80005036:	97ba                	add	a5,a5,a4
    80005038:	639c                	ld	a5,0(a5)
    8000503a:	c38d                	beqz	a5,8000505c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000503c:	4505                	li	a0,1
    8000503e:	9782                	jalr	a5
    80005040:	892a                	mv	s2,a0
    80005042:	bf75                	j	80004ffe <fileread+0x60>
    panic("fileread");
    80005044:	00003517          	auipc	a0,0x3
    80005048:	66450513          	addi	a0,a0,1636 # 800086a8 <syscalls+0x268>
    8000504c:	ffffb097          	auipc	ra,0xffffb
    80005050:	4e4080e7          	jalr	1252(ra) # 80000530 <panic>
    return -1;
    80005054:	597d                	li	s2,-1
    80005056:	b765                	j	80004ffe <fileread+0x60>
      return -1;
    80005058:	597d                	li	s2,-1
    8000505a:	b755                	j	80004ffe <fileread+0x60>
    8000505c:	597d                	li	s2,-1
    8000505e:	b745                	j	80004ffe <fileread+0x60>

0000000080005060 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80005060:	715d                	addi	sp,sp,-80
    80005062:	e486                	sd	ra,72(sp)
    80005064:	e0a2                	sd	s0,64(sp)
    80005066:	fc26                	sd	s1,56(sp)
    80005068:	f84a                	sd	s2,48(sp)
    8000506a:	f44e                	sd	s3,40(sp)
    8000506c:	f052                	sd	s4,32(sp)
    8000506e:	ec56                	sd	s5,24(sp)
    80005070:	e85a                	sd	s6,16(sp)
    80005072:	e45e                	sd	s7,8(sp)
    80005074:	e062                	sd	s8,0(sp)
    80005076:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80005078:	00954783          	lbu	a5,9(a0)
    8000507c:	10078663          	beqz	a5,80005188 <filewrite+0x128>
    80005080:	892a                	mv	s2,a0
    80005082:	8aae                	mv	s5,a1
    80005084:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80005086:	411c                	lw	a5,0(a0)
    80005088:	4705                	li	a4,1
    8000508a:	02e78263          	beq	a5,a4,800050ae <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000508e:	470d                	li	a4,3
    80005090:	02e78663          	beq	a5,a4,800050bc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80005094:	4709                	li	a4,2
    80005096:	0ee79163          	bne	a5,a4,80005178 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000509a:	0ac05d63          	blez	a2,80005154 <filewrite+0xf4>
    int i = 0;
    8000509e:	4981                	li	s3,0
    800050a0:	6b05                	lui	s6,0x1
    800050a2:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    800050a6:	6b85                	lui	s7,0x1
    800050a8:	c00b8b9b          	addiw	s7,s7,-1024
    800050ac:	a861                	j	80005144 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800050ae:	6908                	ld	a0,16(a0)
    800050b0:	00000097          	auipc	ra,0x0
    800050b4:	22e080e7          	jalr	558(ra) # 800052de <pipewrite>
    800050b8:	8a2a                	mv	s4,a0
    800050ba:	a045                	j	8000515a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800050bc:	02451783          	lh	a5,36(a0)
    800050c0:	03079693          	slli	a3,a5,0x30
    800050c4:	92c1                	srli	a3,a3,0x30
    800050c6:	4725                	li	a4,9
    800050c8:	0cd76263          	bltu	a4,a3,8000518c <filewrite+0x12c>
    800050cc:	0792                	slli	a5,a5,0x4
    800050ce:	0001c717          	auipc	a4,0x1c
    800050d2:	45270713          	addi	a4,a4,1106 # 80021520 <devsw>
    800050d6:	97ba                	add	a5,a5,a4
    800050d8:	679c                	ld	a5,8(a5)
    800050da:	cbdd                	beqz	a5,80005190 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800050dc:	4505                	li	a0,1
    800050de:	9782                	jalr	a5
    800050e0:	8a2a                	mv	s4,a0
    800050e2:	a8a5                	j	8000515a <filewrite+0xfa>
    800050e4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800050e8:	00000097          	auipc	ra,0x0
    800050ec:	8a8080e7          	jalr	-1880(ra) # 80004990 <begin_op>
      ilock(f->ip);
    800050f0:	01893503          	ld	a0,24(s2)
    800050f4:	fffff097          	auipc	ra,0xfffff
    800050f8:	eca080e7          	jalr	-310(ra) # 80003fbe <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800050fc:	8762                	mv	a4,s8
    800050fe:	02092683          	lw	a3,32(s2)
    80005102:	01598633          	add	a2,s3,s5
    80005106:	4585                	li	a1,1
    80005108:	01893503          	ld	a0,24(s2)
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	25e080e7          	jalr	606(ra) # 8000436a <writei>
    80005114:	84aa                	mv	s1,a0
    80005116:	00a05763          	blez	a0,80005124 <filewrite+0xc4>
        f->off += r;
    8000511a:	02092783          	lw	a5,32(s2)
    8000511e:	9fa9                	addw	a5,a5,a0
    80005120:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80005124:	01893503          	ld	a0,24(s2)
    80005128:	fffff097          	auipc	ra,0xfffff
    8000512c:	f58080e7          	jalr	-168(ra) # 80004080 <iunlock>
      end_op();
    80005130:	00000097          	auipc	ra,0x0
    80005134:	8e0080e7          	jalr	-1824(ra) # 80004a10 <end_op>

      if(r != n1){
    80005138:	009c1f63          	bne	s8,s1,80005156 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    8000513c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80005140:	0149db63          	bge	s3,s4,80005156 <filewrite+0xf6>
      int n1 = n - i;
    80005144:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80005148:	84be                	mv	s1,a5
    8000514a:	2781                	sext.w	a5,a5
    8000514c:	f8fb5ce3          	bge	s6,a5,800050e4 <filewrite+0x84>
    80005150:	84de                	mv	s1,s7
    80005152:	bf49                	j	800050e4 <filewrite+0x84>
    int i = 0;
    80005154:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80005156:	013a1f63          	bne	s4,s3,80005174 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000515a:	8552                	mv	a0,s4
    8000515c:	60a6                	ld	ra,72(sp)
    8000515e:	6406                	ld	s0,64(sp)
    80005160:	74e2                	ld	s1,56(sp)
    80005162:	7942                	ld	s2,48(sp)
    80005164:	79a2                	ld	s3,40(sp)
    80005166:	7a02                	ld	s4,32(sp)
    80005168:	6ae2                	ld	s5,24(sp)
    8000516a:	6b42                	ld	s6,16(sp)
    8000516c:	6ba2                	ld	s7,8(sp)
    8000516e:	6c02                	ld	s8,0(sp)
    80005170:	6161                	addi	sp,sp,80
    80005172:	8082                	ret
    ret = (i == n ? n : -1);
    80005174:	5a7d                	li	s4,-1
    80005176:	b7d5                	j	8000515a <filewrite+0xfa>
    panic("filewrite");
    80005178:	00003517          	auipc	a0,0x3
    8000517c:	54050513          	addi	a0,a0,1344 # 800086b8 <syscalls+0x278>
    80005180:	ffffb097          	auipc	ra,0xffffb
    80005184:	3b0080e7          	jalr	944(ra) # 80000530 <panic>
    return -1;
    80005188:	5a7d                	li	s4,-1
    8000518a:	bfc1                	j	8000515a <filewrite+0xfa>
      return -1;
    8000518c:	5a7d                	li	s4,-1
    8000518e:	b7f1                	j	8000515a <filewrite+0xfa>
    80005190:	5a7d                	li	s4,-1
    80005192:	b7e1                	j	8000515a <filewrite+0xfa>

0000000080005194 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80005194:	7179                	addi	sp,sp,-48
    80005196:	f406                	sd	ra,40(sp)
    80005198:	f022                	sd	s0,32(sp)
    8000519a:	ec26                	sd	s1,24(sp)
    8000519c:	e84a                	sd	s2,16(sp)
    8000519e:	e44e                	sd	s3,8(sp)
    800051a0:	e052                	sd	s4,0(sp)
    800051a2:	1800                	addi	s0,sp,48
    800051a4:	84aa                	mv	s1,a0
    800051a6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    800051a8:	0005b023          	sd	zero,0(a1)
    800051ac:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    800051b0:	00000097          	auipc	ra,0x0
    800051b4:	bf8080e7          	jalr	-1032(ra) # 80004da8 <filealloc>
    800051b8:	e088                	sd	a0,0(s1)
    800051ba:	c551                	beqz	a0,80005246 <pipealloc+0xb2>
    800051bc:	00000097          	auipc	ra,0x0
    800051c0:	bec080e7          	jalr	-1044(ra) # 80004da8 <filealloc>
    800051c4:	00aa3023          	sd	a0,0(s4)
    800051c8:	c92d                	beqz	a0,8000523a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    800051ca:	ffffc097          	auipc	ra,0xffffc
    800051ce:	8e0080e7          	jalr	-1824(ra) # 80000aaa <kalloc>
    800051d2:	892a                	mv	s2,a0
    800051d4:	c125                	beqz	a0,80005234 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    800051d6:	4985                	li	s3,1
    800051d8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    800051dc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    800051e0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    800051e4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    800051e8:	00003597          	auipc	a1,0x3
    800051ec:	4e058593          	addi	a1,a1,1248 # 800086c8 <syscalls+0x288>
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	a94080e7          	jalr	-1388(ra) # 80000c84 <initlock>
  (*f0)->type = FD_PIPE;
    800051f8:	609c                	ld	a5,0(s1)
    800051fa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800051fe:	609c                	ld	a5,0(s1)
    80005200:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80005204:	609c                	ld	a5,0(s1)
    80005206:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    8000520a:	609c                	ld	a5,0(s1)
    8000520c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005210:	000a3783          	ld	a5,0(s4)
    80005214:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005218:	000a3783          	ld	a5,0(s4)
    8000521c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005220:	000a3783          	ld	a5,0(s4)
    80005224:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005228:	000a3783          	ld	a5,0(s4)
    8000522c:	0127b823          	sd	s2,16(a5)
  return 0;
    80005230:	4501                	li	a0,0
    80005232:	a025                	j	8000525a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80005234:	6088                	ld	a0,0(s1)
    80005236:	e501                	bnez	a0,8000523e <pipealloc+0xaa>
    80005238:	a039                	j	80005246 <pipealloc+0xb2>
    8000523a:	6088                	ld	a0,0(s1)
    8000523c:	c51d                	beqz	a0,8000526a <pipealloc+0xd6>
    fileclose(*f0);
    8000523e:	00000097          	auipc	ra,0x0
    80005242:	c26080e7          	jalr	-986(ra) # 80004e64 <fileclose>
  if(*f1)
    80005246:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    8000524a:	557d                	li	a0,-1
  if(*f1)
    8000524c:	c799                	beqz	a5,8000525a <pipealloc+0xc6>
    fileclose(*f1);
    8000524e:	853e                	mv	a0,a5
    80005250:	00000097          	auipc	ra,0x0
    80005254:	c14080e7          	jalr	-1004(ra) # 80004e64 <fileclose>
  return -1;
    80005258:	557d                	li	a0,-1
}
    8000525a:	70a2                	ld	ra,40(sp)
    8000525c:	7402                	ld	s0,32(sp)
    8000525e:	64e2                	ld	s1,24(sp)
    80005260:	6942                	ld	s2,16(sp)
    80005262:	69a2                	ld	s3,8(sp)
    80005264:	6a02                	ld	s4,0(sp)
    80005266:	6145                	addi	sp,sp,48
    80005268:	8082                	ret
  return -1;
    8000526a:	557d                	li	a0,-1
    8000526c:	b7fd                	j	8000525a <pipealloc+0xc6>

000000008000526e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    8000526e:	1101                	addi	sp,sp,-32
    80005270:	ec06                	sd	ra,24(sp)
    80005272:	e822                	sd	s0,16(sp)
    80005274:	e426                	sd	s1,8(sp)
    80005276:	e04a                	sd	s2,0(sp)
    80005278:	1000                	addi	s0,sp,32
    8000527a:	84aa                	mv	s1,a0
    8000527c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    8000527e:	ffffc097          	auipc	ra,0xffffc
    80005282:	a96080e7          	jalr	-1386(ra) # 80000d14 <acquire>
  if(writable){
    80005286:	02090d63          	beqz	s2,800052c0 <pipeclose+0x52>
    pi->writeopen = 0;
    8000528a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    8000528e:	21848513          	addi	a0,s1,536
    80005292:	ffffe097          	auipc	ra,0xffffe
    80005296:	a2c080e7          	jalr	-1492(ra) # 80002cbe <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    8000529a:	2204b783          	ld	a5,544(s1)
    8000529e:	eb95                	bnez	a5,800052d2 <pipeclose+0x64>
    release(&pi->lock);
    800052a0:	8526                	mv	a0,s1
    800052a2:	ffffc097          	auipc	ra,0xffffc
    800052a6:	b26080e7          	jalr	-1242(ra) # 80000dc8 <release>
    kfree((char*)pi);
    800052aa:	8526                	mv	a0,s1
    800052ac:	ffffb097          	auipc	ra,0xffffb
    800052b0:	73e080e7          	jalr	1854(ra) # 800009ea <kfree>
  } else
    release(&pi->lock);
}
    800052b4:	60e2                	ld	ra,24(sp)
    800052b6:	6442                	ld	s0,16(sp)
    800052b8:	64a2                	ld	s1,8(sp)
    800052ba:	6902                	ld	s2,0(sp)
    800052bc:	6105                	addi	sp,sp,32
    800052be:	8082                	ret
    pi->readopen = 0;
    800052c0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    800052c4:	21c48513          	addi	a0,s1,540
    800052c8:	ffffe097          	auipc	ra,0xffffe
    800052cc:	9f6080e7          	jalr	-1546(ra) # 80002cbe <wakeup>
    800052d0:	b7e9                	j	8000529a <pipeclose+0x2c>
    release(&pi->lock);
    800052d2:	8526                	mv	a0,s1
    800052d4:	ffffc097          	auipc	ra,0xffffc
    800052d8:	af4080e7          	jalr	-1292(ra) # 80000dc8 <release>
}
    800052dc:	bfe1                	j	800052b4 <pipeclose+0x46>

00000000800052de <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    800052de:	7159                	addi	sp,sp,-112
    800052e0:	f486                	sd	ra,104(sp)
    800052e2:	f0a2                	sd	s0,96(sp)
    800052e4:	eca6                	sd	s1,88(sp)
    800052e6:	e8ca                	sd	s2,80(sp)
    800052e8:	e4ce                	sd	s3,72(sp)
    800052ea:	e0d2                	sd	s4,64(sp)
    800052ec:	fc56                	sd	s5,56(sp)
    800052ee:	f85a                	sd	s6,48(sp)
    800052f0:	f45e                	sd	s7,40(sp)
    800052f2:	f062                	sd	s8,32(sp)
    800052f4:	ec66                	sd	s9,24(sp)
    800052f6:	1880                	addi	s0,sp,112
    800052f8:	84aa                	mv	s1,a0
    800052fa:	8aae                	mv	s5,a1
    800052fc:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    800052fe:	ffffd097          	auipc	ra,0xffffd
    80005302:	ed8080e7          	jalr	-296(ra) # 800021d6 <myproc>
    80005306:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005308:	8526                	mv	a0,s1
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	a0a080e7          	jalr	-1526(ra) # 80000d14 <acquire>
  while(i < n){
    80005312:	0d405163          	blez	s4,800053d4 <pipewrite+0xf6>
    80005316:	8ba6                	mv	s7,s1
  int i = 0;
    80005318:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000531a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000531c:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005320:	21c48c13          	addi	s8,s1,540
    80005324:	a08d                	j	80005386 <pipewrite+0xa8>
      release(&pi->lock);
    80005326:	8526                	mv	a0,s1
    80005328:	ffffc097          	auipc	ra,0xffffc
    8000532c:	aa0080e7          	jalr	-1376(ra) # 80000dc8 <release>
      return -1;
    80005330:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005332:	854a                	mv	a0,s2
    80005334:	70a6                	ld	ra,104(sp)
    80005336:	7406                	ld	s0,96(sp)
    80005338:	64e6                	ld	s1,88(sp)
    8000533a:	6946                	ld	s2,80(sp)
    8000533c:	69a6                	ld	s3,72(sp)
    8000533e:	6a06                	ld	s4,64(sp)
    80005340:	7ae2                	ld	s5,56(sp)
    80005342:	7b42                	ld	s6,48(sp)
    80005344:	7ba2                	ld	s7,40(sp)
    80005346:	7c02                	ld	s8,32(sp)
    80005348:	6ce2                	ld	s9,24(sp)
    8000534a:	6165                	addi	sp,sp,112
    8000534c:	8082                	ret
      wakeup(&pi->nread);
    8000534e:	8566                	mv	a0,s9
    80005350:	ffffe097          	auipc	ra,0xffffe
    80005354:	96e080e7          	jalr	-1682(ra) # 80002cbe <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80005358:	85de                	mv	a1,s7
    8000535a:	8562                	mv	a0,s8
    8000535c:	ffffd097          	auipc	ra,0xffffd
    80005360:	7dc080e7          	jalr	2012(ra) # 80002b38 <sleep>
    80005364:	a839                	j	80005382 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005366:	21c4a783          	lw	a5,540(s1)
    8000536a:	0017871b          	addiw	a4,a5,1
    8000536e:	20e4ae23          	sw	a4,540(s1)
    80005372:	1ff7f793          	andi	a5,a5,511
    80005376:	97a6                	add	a5,a5,s1
    80005378:	f9f44703          	lbu	a4,-97(s0)
    8000537c:	00e78c23          	sb	a4,24(a5)
      i++;
    80005380:	2905                	addiw	s2,s2,1
  while(i < n){
    80005382:	03495d63          	bge	s2,s4,800053bc <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80005386:	2204a783          	lw	a5,544(s1)
    8000538a:	dfd1                	beqz	a5,80005326 <pipewrite+0x48>
    8000538c:	0309a783          	lw	a5,48(s3)
    80005390:	fbd9                	bnez	a5,80005326 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80005392:	2184a783          	lw	a5,536(s1)
    80005396:	21c4a703          	lw	a4,540(s1)
    8000539a:	2007879b          	addiw	a5,a5,512
    8000539e:	faf708e3          	beq	a4,a5,8000534e <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800053a2:	4685                	li	a3,1
    800053a4:	01590633          	add	a2,s2,s5
    800053a8:	f9f40593          	addi	a1,s0,-97
    800053ac:	0509b503          	ld	a0,80(s3)
    800053b0:	ffffd097          	auipc	ra,0xffffd
    800053b4:	88c080e7          	jalr	-1908(ra) # 80001c3c <copyin>
    800053b8:	fb6517e3          	bne	a0,s6,80005366 <pipewrite+0x88>
  wakeup(&pi->nread);
    800053bc:	21848513          	addi	a0,s1,536
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	8fe080e7          	jalr	-1794(ra) # 80002cbe <wakeup>
  release(&pi->lock);
    800053c8:	8526                	mv	a0,s1
    800053ca:	ffffc097          	auipc	ra,0xffffc
    800053ce:	9fe080e7          	jalr	-1538(ra) # 80000dc8 <release>
  return i;
    800053d2:	b785                	j	80005332 <pipewrite+0x54>
  int i = 0;
    800053d4:	4901                	li	s2,0
    800053d6:	b7dd                	j	800053bc <pipewrite+0xde>

00000000800053d8 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    800053d8:	715d                	addi	sp,sp,-80
    800053da:	e486                	sd	ra,72(sp)
    800053dc:	e0a2                	sd	s0,64(sp)
    800053de:	fc26                	sd	s1,56(sp)
    800053e0:	f84a                	sd	s2,48(sp)
    800053e2:	f44e                	sd	s3,40(sp)
    800053e4:	f052                	sd	s4,32(sp)
    800053e6:	ec56                	sd	s5,24(sp)
    800053e8:	e85a                	sd	s6,16(sp)
    800053ea:	0880                	addi	s0,sp,80
    800053ec:	84aa                	mv	s1,a0
    800053ee:	892e                	mv	s2,a1
    800053f0:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    800053f2:	ffffd097          	auipc	ra,0xffffd
    800053f6:	de4080e7          	jalr	-540(ra) # 800021d6 <myproc>
    800053fa:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    800053fc:	8b26                	mv	s6,s1
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffc097          	auipc	ra,0xffffc
    80005404:	914080e7          	jalr	-1772(ra) # 80000d14 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005408:	2184a703          	lw	a4,536(s1)
    8000540c:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005410:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005414:	02f71463          	bne	a4,a5,8000543c <piperead+0x64>
    80005418:	2244a783          	lw	a5,548(s1)
    8000541c:	c385                	beqz	a5,8000543c <piperead+0x64>
    if(pr->killed){
    8000541e:	030a2783          	lw	a5,48(s4)
    80005422:	ebc1                	bnez	a5,800054b2 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005424:	85da                	mv	a1,s6
    80005426:	854e                	mv	a0,s3
    80005428:	ffffd097          	auipc	ra,0xffffd
    8000542c:	710080e7          	jalr	1808(ra) # 80002b38 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005430:	2184a703          	lw	a4,536(s1)
    80005434:	21c4a783          	lw	a5,540(s1)
    80005438:	fef700e3          	beq	a4,a5,80005418 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000543c:	09505263          	blez	s5,800054c0 <piperead+0xe8>
    80005440:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005442:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005444:	2184a783          	lw	a5,536(s1)
    80005448:	21c4a703          	lw	a4,540(s1)
    8000544c:	02f70d63          	beq	a4,a5,80005486 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005450:	0017871b          	addiw	a4,a5,1
    80005454:	20e4ac23          	sw	a4,536(s1)
    80005458:	1ff7f793          	andi	a5,a5,511
    8000545c:	97a6                	add	a5,a5,s1
    8000545e:	0187c783          	lbu	a5,24(a5)
    80005462:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005466:	4685                	li	a3,1
    80005468:	fbf40613          	addi	a2,s0,-65
    8000546c:	85ca                	mv	a1,s2
    8000546e:	050a3503          	ld	a0,80(s4)
    80005472:	ffffc097          	auipc	ra,0xffffc
    80005476:	724080e7          	jalr	1828(ra) # 80001b96 <copyout>
    8000547a:	01650663          	beq	a0,s6,80005486 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000547e:	2985                	addiw	s3,s3,1
    80005480:	0905                	addi	s2,s2,1
    80005482:	fd3a91e3          	bne	s5,s3,80005444 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005486:	21c48513          	addi	a0,s1,540
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	834080e7          	jalr	-1996(ra) # 80002cbe <wakeup>
  release(&pi->lock);
    80005492:	8526                	mv	a0,s1
    80005494:	ffffc097          	auipc	ra,0xffffc
    80005498:	934080e7          	jalr	-1740(ra) # 80000dc8 <release>
  return i;
}
    8000549c:	854e                	mv	a0,s3
    8000549e:	60a6                	ld	ra,72(sp)
    800054a0:	6406                	ld	s0,64(sp)
    800054a2:	74e2                	ld	s1,56(sp)
    800054a4:	7942                	ld	s2,48(sp)
    800054a6:	79a2                	ld	s3,40(sp)
    800054a8:	7a02                	ld	s4,32(sp)
    800054aa:	6ae2                	ld	s5,24(sp)
    800054ac:	6b42                	ld	s6,16(sp)
    800054ae:	6161                	addi	sp,sp,80
    800054b0:	8082                	ret
      release(&pi->lock);
    800054b2:	8526                	mv	a0,s1
    800054b4:	ffffc097          	auipc	ra,0xffffc
    800054b8:	914080e7          	jalr	-1772(ra) # 80000dc8 <release>
      return -1;
    800054bc:	59fd                	li	s3,-1
    800054be:	bff9                	j	8000549c <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800054c0:	4981                	li	s3,0
    800054c2:	b7d1                	j	80005486 <piperead+0xae>

00000000800054c4 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    800054c4:	df010113          	addi	sp,sp,-528
    800054c8:	20113423          	sd	ra,520(sp)
    800054cc:	20813023          	sd	s0,512(sp)
    800054d0:	ffa6                	sd	s1,504(sp)
    800054d2:	fbca                	sd	s2,496(sp)
    800054d4:	f7ce                	sd	s3,488(sp)
    800054d6:	f3d2                	sd	s4,480(sp)
    800054d8:	efd6                	sd	s5,472(sp)
    800054da:	ebda                	sd	s6,464(sp)
    800054dc:	e7de                	sd	s7,456(sp)
    800054de:	e3e2                	sd	s8,448(sp)
    800054e0:	ff66                	sd	s9,440(sp)
    800054e2:	fb6a                	sd	s10,432(sp)
    800054e4:	f76e                	sd	s11,424(sp)
    800054e6:	0c00                	addi	s0,sp,528
    800054e8:	84aa                	mv	s1,a0
    800054ea:	dea43c23          	sd	a0,-520(s0)
    800054ee:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800054f2:	ffffd097          	auipc	ra,0xffffd
    800054f6:	ce4080e7          	jalr	-796(ra) # 800021d6 <myproc>
    800054fa:	892a                	mv	s2,a0

  begin_op();
    800054fc:	fffff097          	auipc	ra,0xfffff
    80005500:	494080e7          	jalr	1172(ra) # 80004990 <begin_op>

  if((ip = namei(path)) == 0){
    80005504:	8526                	mv	a0,s1
    80005506:	fffff097          	auipc	ra,0xfffff
    8000550a:	26e080e7          	jalr	622(ra) # 80004774 <namei>
    8000550e:	c92d                	beqz	a0,80005580 <exec+0xbc>
    80005510:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005512:	fffff097          	auipc	ra,0xfffff
    80005516:	aac080e7          	jalr	-1364(ra) # 80003fbe <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000551a:	04000713          	li	a4,64
    8000551e:	4681                	li	a3,0
    80005520:	e4840613          	addi	a2,s0,-440
    80005524:	4581                	li	a1,0
    80005526:	8526                	mv	a0,s1
    80005528:	fffff097          	auipc	ra,0xfffff
    8000552c:	d4a080e7          	jalr	-694(ra) # 80004272 <readi>
    80005530:	04000793          	li	a5,64
    80005534:	00f51a63          	bne	a0,a5,80005548 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    80005538:	e4842703          	lw	a4,-440(s0)
    8000553c:	464c47b7          	lui	a5,0x464c4
    80005540:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005544:	04f70463          	beq	a4,a5,8000558c <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005548:	8526                	mv	a0,s1
    8000554a:	fffff097          	auipc	ra,0xfffff
    8000554e:	cd6080e7          	jalr	-810(ra) # 80004220 <iunlockput>
    end_op();
    80005552:	fffff097          	auipc	ra,0xfffff
    80005556:	4be080e7          	jalr	1214(ra) # 80004a10 <end_op>
  }
  return -1;
    8000555a:	557d                	li	a0,-1
}
    8000555c:	20813083          	ld	ra,520(sp)
    80005560:	20013403          	ld	s0,512(sp)
    80005564:	74fe                	ld	s1,504(sp)
    80005566:	795e                	ld	s2,496(sp)
    80005568:	79be                	ld	s3,488(sp)
    8000556a:	7a1e                	ld	s4,480(sp)
    8000556c:	6afe                	ld	s5,472(sp)
    8000556e:	6b5e                	ld	s6,464(sp)
    80005570:	6bbe                	ld	s7,456(sp)
    80005572:	6c1e                	ld	s8,448(sp)
    80005574:	7cfa                	ld	s9,440(sp)
    80005576:	7d5a                	ld	s10,432(sp)
    80005578:	7dba                	ld	s11,424(sp)
    8000557a:	21010113          	addi	sp,sp,528
    8000557e:	8082                	ret
    end_op();
    80005580:	fffff097          	auipc	ra,0xfffff
    80005584:	490080e7          	jalr	1168(ra) # 80004a10 <end_op>
    return -1;
    80005588:	557d                	li	a0,-1
    8000558a:	bfc9                	j	8000555c <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000558c:	854a                	mv	a0,s2
    8000558e:	ffffd097          	auipc	ra,0xffffd
    80005592:	d0c080e7          	jalr	-756(ra) # 8000229a <proc_pagetable>
    80005596:	8baa                	mv	s7,a0
    80005598:	d945                	beqz	a0,80005548 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000559a:	e6842983          	lw	s3,-408(s0)
    8000559e:	e8045783          	lhu	a5,-384(s0)
    800055a2:	c7ad                	beqz	a5,8000560c <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    800055a4:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800055a6:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    800055a8:	6c85                	lui	s9,0x1
    800055aa:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    800055ae:	def43823          	sd	a5,-528(s0)
    800055b2:	a42d                	j	800057dc <exec+0x318>
    panic("loadseg: va must be page aligned");

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    800055b4:	00003517          	auipc	a0,0x3
    800055b8:	11c50513          	addi	a0,a0,284 # 800086d0 <syscalls+0x290>
    800055bc:	ffffb097          	auipc	ra,0xffffb
    800055c0:	f74080e7          	jalr	-140(ra) # 80000530 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    800055c4:	8756                	mv	a4,s5
    800055c6:	012d86bb          	addw	a3,s11,s2
    800055ca:	4581                	li	a1,0
    800055cc:	8526                	mv	a0,s1
    800055ce:	fffff097          	auipc	ra,0xfffff
    800055d2:	ca4080e7          	jalr	-860(ra) # 80004272 <readi>
    800055d6:	2501                	sext.w	a0,a0
    800055d8:	1aaa9963          	bne	s5,a0,8000578a <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    800055dc:	6785                	lui	a5,0x1
    800055de:	0127893b          	addw	s2,a5,s2
    800055e2:	77fd                	lui	a5,0xfffff
    800055e4:	01478a3b          	addw	s4,a5,s4
    800055e8:	1f897163          	bgeu	s2,s8,800057ca <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800055ec:	02091593          	slli	a1,s2,0x20
    800055f0:	9181                	srli	a1,a1,0x20
    800055f2:	95ea                	add	a1,a1,s10
    800055f4:	855e                	mv	a0,s7
    800055f6:	ffffc097          	auipc	ra,0xffffc
    800055fa:	bac080e7          	jalr	-1108(ra) # 800011a2 <walkaddr>
    800055fe:	862a                	mv	a2,a0
    if(pa == 0)
    80005600:	d955                	beqz	a0,800055b4 <exec+0xf0>
      n = PGSIZE;
    80005602:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005604:	fd9a70e3          	bgeu	s4,s9,800055c4 <exec+0x100>
      n = sz - i;
    80005608:	8ad2                	mv	s5,s4
    8000560a:	bf6d                	j	800055c4 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG+1], stackbase;
    8000560c:	4901                	li	s2,0
  iunlockput(ip);
    8000560e:	8526                	mv	a0,s1
    80005610:	fffff097          	auipc	ra,0xfffff
    80005614:	c10080e7          	jalr	-1008(ra) # 80004220 <iunlockput>
  end_op();
    80005618:	fffff097          	auipc	ra,0xfffff
    8000561c:	3f8080e7          	jalr	1016(ra) # 80004a10 <end_op>
  p = myproc();
    80005620:	ffffd097          	auipc	ra,0xffffd
    80005624:	bb6080e7          	jalr	-1098(ra) # 800021d6 <myproc>
    80005628:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    8000562a:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    8000562e:	6785                	lui	a5,0x1
    80005630:	17fd                	addi	a5,a5,-1
    80005632:	993e                	add	s2,s2,a5
    80005634:	757d                	lui	a0,0xfffff
    80005636:	00a977b3          	and	a5,s2,a0
    8000563a:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    8000563e:	6609                	lui	a2,0x2
    80005640:	963e                	add	a2,a2,a5
    80005642:	85be                	mv	a1,a5
    80005644:	855e                	mv	a0,s7
    80005646:	ffffc097          	auipc	ra,0xffffc
    8000564a:	ef0080e7          	jalr	-272(ra) # 80001536 <uvmalloc>
    8000564e:	8b2a                	mv	s6,a0
  ip = 0;
    80005650:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005652:	12050c63          	beqz	a0,8000578a <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005656:	75f9                	lui	a1,0xffffe
    80005658:	95aa                	add	a1,a1,a0
    8000565a:	855e                	mv	a0,s7
    8000565c:	ffffc097          	auipc	ra,0xffffc
    80005660:	110080e7          	jalr	272(ra) # 8000176c <uvmclear>
  stackbase = sp - PGSIZE;
    80005664:	7c7d                	lui	s8,0xfffff
    80005666:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005668:	e0043783          	ld	a5,-512(s0)
    8000566c:	6388                	ld	a0,0(a5)
    8000566e:	c535                	beqz	a0,800056da <exec+0x216>
    80005670:	e8840993          	addi	s3,s0,-376
    80005674:	f8840c93          	addi	s9,s0,-120
  sp = sz;
    80005678:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    8000567a:	ffffc097          	auipc	ra,0xffffc
    8000567e:	91e080e7          	jalr	-1762(ra) # 80000f98 <strlen>
    80005682:	2505                	addiw	a0,a0,1
    80005684:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005688:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000568c:	13896363          	bltu	s2,s8,800057b2 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005690:	e0043d83          	ld	s11,-512(s0)
    80005694:	000dba03          	ld	s4,0(s11)
    80005698:	8552                	mv	a0,s4
    8000569a:	ffffc097          	auipc	ra,0xffffc
    8000569e:	8fe080e7          	jalr	-1794(ra) # 80000f98 <strlen>
    800056a2:	0015069b          	addiw	a3,a0,1
    800056a6:	8652                	mv	a2,s4
    800056a8:	85ca                	mv	a1,s2
    800056aa:	855e                	mv	a0,s7
    800056ac:	ffffc097          	auipc	ra,0xffffc
    800056b0:	4ea080e7          	jalr	1258(ra) # 80001b96 <copyout>
    800056b4:	10054363          	bltz	a0,800057ba <exec+0x2f6>
    ustack[argc] = sp;
    800056b8:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    800056bc:	0485                	addi	s1,s1,1
    800056be:	008d8793          	addi	a5,s11,8
    800056c2:	e0f43023          	sd	a5,-512(s0)
    800056c6:	008db503          	ld	a0,8(s11)
    800056ca:	c911                	beqz	a0,800056de <exec+0x21a>
    if(argc >= MAXARG)
    800056cc:	09a1                	addi	s3,s3,8
    800056ce:	fb3c96e3          	bne	s9,s3,8000567a <exec+0x1b6>
  sz = sz1;
    800056d2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800056d6:	4481                	li	s1,0
    800056d8:	a84d                	j	8000578a <exec+0x2c6>
  sp = sz;
    800056da:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    800056dc:	4481                	li	s1,0
  ustack[argc] = 0;
    800056de:	00349793          	slli	a5,s1,0x3
    800056e2:	f9040713          	addi	a4,s0,-112
    800056e6:	97ba                	add	a5,a5,a4
    800056e8:	ee07bc23          	sd	zero,-264(a5) # ef8 <_entry-0x7ffff108>
  sp -= (argc+1) * sizeof(uint64);
    800056ec:	00148693          	addi	a3,s1,1
    800056f0:	068e                	slli	a3,a3,0x3
    800056f2:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800056f6:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800056fa:	01897663          	bgeu	s2,s8,80005706 <exec+0x242>
  sz = sz1;
    800056fe:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005702:	4481                	li	s1,0
    80005704:	a059                	j	8000578a <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005706:	e8840613          	addi	a2,s0,-376
    8000570a:	85ca                	mv	a1,s2
    8000570c:	855e                	mv	a0,s7
    8000570e:	ffffc097          	auipc	ra,0xffffc
    80005712:	488080e7          	jalr	1160(ra) # 80001b96 <copyout>
    80005716:	0a054663          	bltz	a0,800057c2 <exec+0x2fe>
  p->trapframe->a1 = sp;
    8000571a:	058ab783          	ld	a5,88(s5)
    8000571e:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005722:	df843783          	ld	a5,-520(s0)
    80005726:	0007c703          	lbu	a4,0(a5)
    8000572a:	cf11                	beqz	a4,80005746 <exec+0x282>
    8000572c:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000572e:	02f00693          	li	a3,47
    80005732:	a029                	j	8000573c <exec+0x278>
  for(last=s=path; *s; s++)
    80005734:	0785                	addi	a5,a5,1
    80005736:	fff7c703          	lbu	a4,-1(a5)
    8000573a:	c711                	beqz	a4,80005746 <exec+0x282>
    if(*s == '/')
    8000573c:	fed71ce3          	bne	a4,a3,80005734 <exec+0x270>
      last = s+1;
    80005740:	def43c23          	sd	a5,-520(s0)
    80005744:	bfc5                	j	80005734 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005746:	4641                	li	a2,16
    80005748:	df843583          	ld	a1,-520(s0)
    8000574c:	158a8513          	addi	a0,s5,344
    80005750:	ffffc097          	auipc	ra,0xffffc
    80005754:	816080e7          	jalr	-2026(ra) # 80000f66 <safestrcpy>
  oldpagetable = p->pagetable;
    80005758:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000575c:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    80005760:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005764:	058ab783          	ld	a5,88(s5)
    80005768:	e6043703          	ld	a4,-416(s0)
    8000576c:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000576e:	058ab783          	ld	a5,88(s5)
    80005772:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005776:	85ea                	mv	a1,s10
    80005778:	ffffd097          	auipc	ra,0xffffd
    8000577c:	bbe080e7          	jalr	-1090(ra) # 80002336 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005780:	0004851b          	sext.w	a0,s1
    80005784:	bbe1                	j	8000555c <exec+0x98>
    80005786:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    8000578a:	e0843583          	ld	a1,-504(s0)
    8000578e:	855e                	mv	a0,s7
    80005790:	ffffd097          	auipc	ra,0xffffd
    80005794:	ba6080e7          	jalr	-1114(ra) # 80002336 <proc_freepagetable>
  if(ip){
    80005798:	da0498e3          	bnez	s1,80005548 <exec+0x84>
  return -1;
    8000579c:	557d                	li	a0,-1
    8000579e:	bb7d                	j	8000555c <exec+0x98>
    800057a0:	e1243423          	sd	s2,-504(s0)
    800057a4:	b7dd                	j	8000578a <exec+0x2c6>
    800057a6:	e1243423          	sd	s2,-504(s0)
    800057aa:	b7c5                	j	8000578a <exec+0x2c6>
    800057ac:	e1243423          	sd	s2,-504(s0)
    800057b0:	bfe9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057b2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057b6:	4481                	li	s1,0
    800057b8:	bfc9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057ba:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057be:	4481                	li	s1,0
    800057c0:	b7e9                	j	8000578a <exec+0x2c6>
  sz = sz1;
    800057c2:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800057c6:	4481                	li	s1,0
    800057c8:	b7c9                	j	8000578a <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800057ca:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800057ce:	2b05                	addiw	s6,s6,1
    800057d0:	0389899b          	addiw	s3,s3,56
    800057d4:	e8045783          	lhu	a5,-384(s0)
    800057d8:	e2fb5be3          	bge	s6,a5,8000560e <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    800057dc:	2981                	sext.w	s3,s3
    800057de:	03800713          	li	a4,56
    800057e2:	86ce                	mv	a3,s3
    800057e4:	e1040613          	addi	a2,s0,-496
    800057e8:	4581                	li	a1,0
    800057ea:	8526                	mv	a0,s1
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	a86080e7          	jalr	-1402(ra) # 80004272 <readi>
    800057f4:	03800793          	li	a5,56
    800057f8:	f8f517e3          	bne	a0,a5,80005786 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800057fc:	e1042783          	lw	a5,-496(s0)
    80005800:	4705                	li	a4,1
    80005802:	fce796e3          	bne	a5,a4,800057ce <exec+0x30a>
    if(ph.memsz < ph.filesz)
    80005806:	e3843603          	ld	a2,-456(s0)
    8000580a:	e3043783          	ld	a5,-464(s0)
    8000580e:	f8f669e3          	bltu	a2,a5,800057a0 <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005812:	e2043783          	ld	a5,-480(s0)
    80005816:	963e                	add	a2,a2,a5
    80005818:	f8f667e3          	bltu	a2,a5,800057a6 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    8000581c:	85ca                	mv	a1,s2
    8000581e:	855e                	mv	a0,s7
    80005820:	ffffc097          	auipc	ra,0xffffc
    80005824:	d16080e7          	jalr	-746(ra) # 80001536 <uvmalloc>
    80005828:	e0a43423          	sd	a0,-504(s0)
    8000582c:	d141                	beqz	a0,800057ac <exec+0x2e8>
    if(ph.vaddr % PGSIZE != 0)
    8000582e:	e2043d03          	ld	s10,-480(s0)
    80005832:	df043783          	ld	a5,-528(s0)
    80005836:	00fd77b3          	and	a5,s10,a5
    8000583a:	fba1                	bnez	a5,8000578a <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    8000583c:	e1842d83          	lw	s11,-488(s0)
    80005840:	e3042c03          	lw	s8,-464(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005844:	f80c03e3          	beqz	s8,800057ca <exec+0x306>
    80005848:	8a62                	mv	s4,s8
    8000584a:	4901                	li	s2,0
    8000584c:	b345                	j	800055ec <exec+0x128>

000000008000584e <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000584e:	7179                	addi	sp,sp,-48
    80005850:	f406                	sd	ra,40(sp)
    80005852:	f022                	sd	s0,32(sp)
    80005854:	ec26                	sd	s1,24(sp)
    80005856:	e84a                	sd	s2,16(sp)
    80005858:	1800                	addi	s0,sp,48
    8000585a:	892e                	mv	s2,a1
    8000585c:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000585e:	fdc40593          	addi	a1,s0,-36
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	bea080e7          	jalr	-1046(ra) # 8000344c <argint>
    8000586a:	04054063          	bltz	a0,800058aa <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000586e:	fdc42703          	lw	a4,-36(s0)
    80005872:	47bd                	li	a5,15
    80005874:	02e7ed63          	bltu	a5,a4,800058ae <argfd+0x60>
    80005878:	ffffd097          	auipc	ra,0xffffd
    8000587c:	95e080e7          	jalr	-1698(ra) # 800021d6 <myproc>
    80005880:	fdc42703          	lw	a4,-36(s0)
    80005884:	01a70793          	addi	a5,a4,26
    80005888:	078e                	slli	a5,a5,0x3
    8000588a:	953e                	add	a0,a0,a5
    8000588c:	611c                	ld	a5,0(a0)
    8000588e:	c395                	beqz	a5,800058b2 <argfd+0x64>
    return -1;
  if(pfd)
    80005890:	00090463          	beqz	s2,80005898 <argfd+0x4a>
    *pfd = fd;
    80005894:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005898:	4501                	li	a0,0
  if(pf)
    8000589a:	c091                	beqz	s1,8000589e <argfd+0x50>
    *pf = f;
    8000589c:	e09c                	sd	a5,0(s1)
}
    8000589e:	70a2                	ld	ra,40(sp)
    800058a0:	7402                	ld	s0,32(sp)
    800058a2:	64e2                	ld	s1,24(sp)
    800058a4:	6942                	ld	s2,16(sp)
    800058a6:	6145                	addi	sp,sp,48
    800058a8:	8082                	ret
    return -1;
    800058aa:	557d                	li	a0,-1
    800058ac:	bfcd                	j	8000589e <argfd+0x50>
    return -1;
    800058ae:	557d                	li	a0,-1
    800058b0:	b7fd                	j	8000589e <argfd+0x50>
    800058b2:	557d                	li	a0,-1
    800058b4:	b7ed                	j	8000589e <argfd+0x50>

00000000800058b6 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800058b6:	1101                	addi	sp,sp,-32
    800058b8:	ec06                	sd	ra,24(sp)
    800058ba:	e822                	sd	s0,16(sp)
    800058bc:	e426                	sd	s1,8(sp)
    800058be:	1000                	addi	s0,sp,32
    800058c0:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800058c2:	ffffd097          	auipc	ra,0xffffd
    800058c6:	914080e7          	jalr	-1772(ra) # 800021d6 <myproc>
    800058ca:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800058cc:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7ffd90d0>
    800058d0:	4501                	li	a0,0
    800058d2:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800058d4:	6398                	ld	a4,0(a5)
    800058d6:	cb19                	beqz	a4,800058ec <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800058d8:	2505                	addiw	a0,a0,1
    800058da:	07a1                	addi	a5,a5,8
    800058dc:	fed51ce3          	bne	a0,a3,800058d4 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800058e0:	557d                	li	a0,-1
}
    800058e2:	60e2                	ld	ra,24(sp)
    800058e4:	6442                	ld	s0,16(sp)
    800058e6:	64a2                	ld	s1,8(sp)
    800058e8:	6105                	addi	sp,sp,32
    800058ea:	8082                	ret
      p->ofile[fd] = f;
    800058ec:	01a50793          	addi	a5,a0,26
    800058f0:	078e                	slli	a5,a5,0x3
    800058f2:	963e                	add	a2,a2,a5
    800058f4:	e204                	sd	s1,0(a2)
      return fd;
    800058f6:	b7f5                	j	800058e2 <fdalloc+0x2c>

00000000800058f8 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800058f8:	715d                	addi	sp,sp,-80
    800058fa:	e486                	sd	ra,72(sp)
    800058fc:	e0a2                	sd	s0,64(sp)
    800058fe:	fc26                	sd	s1,56(sp)
    80005900:	f84a                	sd	s2,48(sp)
    80005902:	f44e                	sd	s3,40(sp)
    80005904:	f052                	sd	s4,32(sp)
    80005906:	ec56                	sd	s5,24(sp)
    80005908:	0880                	addi	s0,sp,80
    8000590a:	89ae                	mv	s3,a1
    8000590c:	8ab2                	mv	s5,a2
    8000590e:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005910:	fb040593          	addi	a1,s0,-80
    80005914:	fffff097          	auipc	ra,0xfffff
    80005918:	e7e080e7          	jalr	-386(ra) # 80004792 <nameiparent>
    8000591c:	892a                	mv	s2,a0
    8000591e:	12050f63          	beqz	a0,80005a5c <create+0x164>
    return 0;

  ilock(dp);
    80005922:	ffffe097          	auipc	ra,0xffffe
    80005926:	69c080e7          	jalr	1692(ra) # 80003fbe <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000592a:	4601                	li	a2,0
    8000592c:	fb040593          	addi	a1,s0,-80
    80005930:	854a                	mv	a0,s2
    80005932:	fffff097          	auipc	ra,0xfffff
    80005936:	b70080e7          	jalr	-1168(ra) # 800044a2 <dirlookup>
    8000593a:	84aa                	mv	s1,a0
    8000593c:	c921                	beqz	a0,8000598c <create+0x94>
    iunlockput(dp);
    8000593e:	854a                	mv	a0,s2
    80005940:	fffff097          	auipc	ra,0xfffff
    80005944:	8e0080e7          	jalr	-1824(ra) # 80004220 <iunlockput>
    ilock(ip);
    80005948:	8526                	mv	a0,s1
    8000594a:	ffffe097          	auipc	ra,0xffffe
    8000594e:	674080e7          	jalr	1652(ra) # 80003fbe <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005952:	2981                	sext.w	s3,s3
    80005954:	4789                	li	a5,2
    80005956:	02f99463          	bne	s3,a5,8000597e <create+0x86>
    8000595a:	0444d783          	lhu	a5,68(s1)
    8000595e:	37f9                	addiw	a5,a5,-2
    80005960:	17c2                	slli	a5,a5,0x30
    80005962:	93c1                	srli	a5,a5,0x30
    80005964:	4705                	li	a4,1
    80005966:	00f76c63          	bltu	a4,a5,8000597e <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    8000596a:	8526                	mv	a0,s1
    8000596c:	60a6                	ld	ra,72(sp)
    8000596e:	6406                	ld	s0,64(sp)
    80005970:	74e2                	ld	s1,56(sp)
    80005972:	7942                	ld	s2,48(sp)
    80005974:	79a2                	ld	s3,40(sp)
    80005976:	7a02                	ld	s4,32(sp)
    80005978:	6ae2                	ld	s5,24(sp)
    8000597a:	6161                	addi	sp,sp,80
    8000597c:	8082                	ret
    iunlockput(ip);
    8000597e:	8526                	mv	a0,s1
    80005980:	fffff097          	auipc	ra,0xfffff
    80005984:	8a0080e7          	jalr	-1888(ra) # 80004220 <iunlockput>
    return 0;
    80005988:	4481                	li	s1,0
    8000598a:	b7c5                	j	8000596a <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000598c:	85ce                	mv	a1,s3
    8000598e:	00092503          	lw	a0,0(s2)
    80005992:	ffffe097          	auipc	ra,0xffffe
    80005996:	494080e7          	jalr	1172(ra) # 80003e26 <ialloc>
    8000599a:	84aa                	mv	s1,a0
    8000599c:	c529                	beqz	a0,800059e6 <create+0xee>
  ilock(ip);
    8000599e:	ffffe097          	auipc	ra,0xffffe
    800059a2:	620080e7          	jalr	1568(ra) # 80003fbe <ilock>
  ip->major = major;
    800059a6:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    800059aa:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    800059ae:	4785                	li	a5,1
    800059b0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	53e080e7          	jalr	1342(ra) # 80003ef4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800059be:	2981                	sext.w	s3,s3
    800059c0:	4785                	li	a5,1
    800059c2:	02f98a63          	beq	s3,a5,800059f6 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    800059c6:	40d0                	lw	a2,4(s1)
    800059c8:	fb040593          	addi	a1,s0,-80
    800059cc:	854a                	mv	a0,s2
    800059ce:	fffff097          	auipc	ra,0xfffff
    800059d2:	ce4080e7          	jalr	-796(ra) # 800046b2 <dirlink>
    800059d6:	06054b63          	bltz	a0,80005a4c <create+0x154>
  iunlockput(dp);
    800059da:	854a                	mv	a0,s2
    800059dc:	fffff097          	auipc	ra,0xfffff
    800059e0:	844080e7          	jalr	-1980(ra) # 80004220 <iunlockput>
  return ip;
    800059e4:	b759                	j	8000596a <create+0x72>
    panic("create: ialloc");
    800059e6:	00003517          	auipc	a0,0x3
    800059ea:	d0a50513          	addi	a0,a0,-758 # 800086f0 <syscalls+0x2b0>
    800059ee:	ffffb097          	auipc	ra,0xffffb
    800059f2:	b42080e7          	jalr	-1214(ra) # 80000530 <panic>
    dp->nlink++;  // for ".."
    800059f6:	04a95783          	lhu	a5,74(s2)
    800059fa:	2785                	addiw	a5,a5,1
    800059fc:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    80005a00:	854a                	mv	a0,s2
    80005a02:	ffffe097          	auipc	ra,0xffffe
    80005a06:	4f2080e7          	jalr	1266(ra) # 80003ef4 <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005a0a:	40d0                	lw	a2,4(s1)
    80005a0c:	00003597          	auipc	a1,0x3
    80005a10:	cf458593          	addi	a1,a1,-780 # 80008700 <syscalls+0x2c0>
    80005a14:	8526                	mv	a0,s1
    80005a16:	fffff097          	auipc	ra,0xfffff
    80005a1a:	c9c080e7          	jalr	-868(ra) # 800046b2 <dirlink>
    80005a1e:	00054f63          	bltz	a0,80005a3c <create+0x144>
    80005a22:	00492603          	lw	a2,4(s2)
    80005a26:	00003597          	auipc	a1,0x3
    80005a2a:	ce258593          	addi	a1,a1,-798 # 80008708 <syscalls+0x2c8>
    80005a2e:	8526                	mv	a0,s1
    80005a30:	fffff097          	auipc	ra,0xfffff
    80005a34:	c82080e7          	jalr	-894(ra) # 800046b2 <dirlink>
    80005a38:	f80557e3          	bgez	a0,800059c6 <create+0xce>
      panic("create dots");
    80005a3c:	00003517          	auipc	a0,0x3
    80005a40:	cd450513          	addi	a0,a0,-812 # 80008710 <syscalls+0x2d0>
    80005a44:	ffffb097          	auipc	ra,0xffffb
    80005a48:	aec080e7          	jalr	-1300(ra) # 80000530 <panic>
    panic("create: dirlink");
    80005a4c:	00003517          	auipc	a0,0x3
    80005a50:	cd450513          	addi	a0,a0,-812 # 80008720 <syscalls+0x2e0>
    80005a54:	ffffb097          	auipc	ra,0xffffb
    80005a58:	adc080e7          	jalr	-1316(ra) # 80000530 <panic>
    return 0;
    80005a5c:	84aa                	mv	s1,a0
    80005a5e:	b731                	j	8000596a <create+0x72>

0000000080005a60 <sys_dup>:
{
    80005a60:	7179                	addi	sp,sp,-48
    80005a62:	f406                	sd	ra,40(sp)
    80005a64:	f022                	sd	s0,32(sp)
    80005a66:	ec26                	sd	s1,24(sp)
    80005a68:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005a6a:	fd840613          	addi	a2,s0,-40
    80005a6e:	4581                	li	a1,0
    80005a70:	4501                	li	a0,0
    80005a72:	00000097          	auipc	ra,0x0
    80005a76:	ddc080e7          	jalr	-548(ra) # 8000584e <argfd>
    return -1;
    80005a7a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005a7c:	02054363          	bltz	a0,80005aa2 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005a80:	fd843503          	ld	a0,-40(s0)
    80005a84:	00000097          	auipc	ra,0x0
    80005a88:	e32080e7          	jalr	-462(ra) # 800058b6 <fdalloc>
    80005a8c:	84aa                	mv	s1,a0
    return -1;
    80005a8e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005a90:	00054963          	bltz	a0,80005aa2 <sys_dup+0x42>
  filedup(f);
    80005a94:	fd843503          	ld	a0,-40(s0)
    80005a98:	fffff097          	auipc	ra,0xfffff
    80005a9c:	37a080e7          	jalr	890(ra) # 80004e12 <filedup>
  return fd;
    80005aa0:	87a6                	mv	a5,s1
}
    80005aa2:	853e                	mv	a0,a5
    80005aa4:	70a2                	ld	ra,40(sp)
    80005aa6:	7402                	ld	s0,32(sp)
    80005aa8:	64e2                	ld	s1,24(sp)
    80005aaa:	6145                	addi	sp,sp,48
    80005aac:	8082                	ret

0000000080005aae <sys_read>:
{
    80005aae:	7179                	addi	sp,sp,-48
    80005ab0:	f406                	sd	ra,40(sp)
    80005ab2:	f022                	sd	s0,32(sp)
    80005ab4:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ab6:	fe840613          	addi	a2,s0,-24
    80005aba:	4581                	li	a1,0
    80005abc:	4501                	li	a0,0
    80005abe:	00000097          	auipc	ra,0x0
    80005ac2:	d90080e7          	jalr	-624(ra) # 8000584e <argfd>
    return -1;
    80005ac6:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005ac8:	04054163          	bltz	a0,80005b0a <sys_read+0x5c>
    80005acc:	fe440593          	addi	a1,s0,-28
    80005ad0:	4509                	li	a0,2
    80005ad2:	ffffe097          	auipc	ra,0xffffe
    80005ad6:	97a080e7          	jalr	-1670(ra) # 8000344c <argint>
    return -1;
    80005ada:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005adc:	02054763          	bltz	a0,80005b0a <sys_read+0x5c>
    80005ae0:	fd840593          	addi	a1,s0,-40
    80005ae4:	4505                	li	a0,1
    80005ae6:	ffffe097          	auipc	ra,0xffffe
    80005aea:	988080e7          	jalr	-1656(ra) # 8000346e <argaddr>
    return -1;
    80005aee:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005af0:	00054d63          	bltz	a0,80005b0a <sys_read+0x5c>
  return fileread(f, p, n);
    80005af4:	fe442603          	lw	a2,-28(s0)
    80005af8:	fd843583          	ld	a1,-40(s0)
    80005afc:	fe843503          	ld	a0,-24(s0)
    80005b00:	fffff097          	auipc	ra,0xfffff
    80005b04:	49e080e7          	jalr	1182(ra) # 80004f9e <fileread>
    80005b08:	87aa                	mv	a5,a0
}
    80005b0a:	853e                	mv	a0,a5
    80005b0c:	70a2                	ld	ra,40(sp)
    80005b0e:	7402                	ld	s0,32(sp)
    80005b10:	6145                	addi	sp,sp,48
    80005b12:	8082                	ret

0000000080005b14 <sys_write>:
{
    80005b14:	7179                	addi	sp,sp,-48
    80005b16:	f406                	sd	ra,40(sp)
    80005b18:	f022                	sd	s0,32(sp)
    80005b1a:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b1c:	fe840613          	addi	a2,s0,-24
    80005b20:	4581                	li	a1,0
    80005b22:	4501                	li	a0,0
    80005b24:	00000097          	auipc	ra,0x0
    80005b28:	d2a080e7          	jalr	-726(ra) # 8000584e <argfd>
    return -1;
    80005b2c:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b2e:	04054163          	bltz	a0,80005b70 <sys_write+0x5c>
    80005b32:	fe440593          	addi	a1,s0,-28
    80005b36:	4509                	li	a0,2
    80005b38:	ffffe097          	auipc	ra,0xffffe
    80005b3c:	914080e7          	jalr	-1772(ra) # 8000344c <argint>
    return -1;
    80005b40:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b42:	02054763          	bltz	a0,80005b70 <sys_write+0x5c>
    80005b46:	fd840593          	addi	a1,s0,-40
    80005b4a:	4505                	li	a0,1
    80005b4c:	ffffe097          	auipc	ra,0xffffe
    80005b50:	922080e7          	jalr	-1758(ra) # 8000346e <argaddr>
    return -1;
    80005b54:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005b56:	00054d63          	bltz	a0,80005b70 <sys_write+0x5c>
  return filewrite(f, p, n);
    80005b5a:	fe442603          	lw	a2,-28(s0)
    80005b5e:	fd843583          	ld	a1,-40(s0)
    80005b62:	fe843503          	ld	a0,-24(s0)
    80005b66:	fffff097          	auipc	ra,0xfffff
    80005b6a:	4fa080e7          	jalr	1274(ra) # 80005060 <filewrite>
    80005b6e:	87aa                	mv	a5,a0
}
    80005b70:	853e                	mv	a0,a5
    80005b72:	70a2                	ld	ra,40(sp)
    80005b74:	7402                	ld	s0,32(sp)
    80005b76:	6145                	addi	sp,sp,48
    80005b78:	8082                	ret

0000000080005b7a <sys_close>:
{
    80005b7a:	1101                	addi	sp,sp,-32
    80005b7c:	ec06                	sd	ra,24(sp)
    80005b7e:	e822                	sd	s0,16(sp)
    80005b80:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005b82:	fe040613          	addi	a2,s0,-32
    80005b86:	fec40593          	addi	a1,s0,-20
    80005b8a:	4501                	li	a0,0
    80005b8c:	00000097          	auipc	ra,0x0
    80005b90:	cc2080e7          	jalr	-830(ra) # 8000584e <argfd>
    return -1;
    80005b94:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005b96:	02054463          	bltz	a0,80005bbe <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005b9a:	ffffc097          	auipc	ra,0xffffc
    80005b9e:	63c080e7          	jalr	1596(ra) # 800021d6 <myproc>
    80005ba2:	fec42783          	lw	a5,-20(s0)
    80005ba6:	07e9                	addi	a5,a5,26
    80005ba8:	078e                	slli	a5,a5,0x3
    80005baa:	97aa                	add	a5,a5,a0
    80005bac:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    80005bb0:	fe043503          	ld	a0,-32(s0)
    80005bb4:	fffff097          	auipc	ra,0xfffff
    80005bb8:	2b0080e7          	jalr	688(ra) # 80004e64 <fileclose>
  return 0;
    80005bbc:	4781                	li	a5,0
}
    80005bbe:	853e                	mv	a0,a5
    80005bc0:	60e2                	ld	ra,24(sp)
    80005bc2:	6442                	ld	s0,16(sp)
    80005bc4:	6105                	addi	sp,sp,32
    80005bc6:	8082                	ret

0000000080005bc8 <sys_fstat>:
{
    80005bc8:	1101                	addi	sp,sp,-32
    80005bca:	ec06                	sd	ra,24(sp)
    80005bcc:	e822                	sd	s0,16(sp)
    80005bce:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bd0:	fe840613          	addi	a2,s0,-24
    80005bd4:	4581                	li	a1,0
    80005bd6:	4501                	li	a0,0
    80005bd8:	00000097          	auipc	ra,0x0
    80005bdc:	c76080e7          	jalr	-906(ra) # 8000584e <argfd>
    return -1;
    80005be0:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005be2:	02054563          	bltz	a0,80005c0c <sys_fstat+0x44>
    80005be6:	fe040593          	addi	a1,s0,-32
    80005bea:	4505                	li	a0,1
    80005bec:	ffffe097          	auipc	ra,0xffffe
    80005bf0:	882080e7          	jalr	-1918(ra) # 8000346e <argaddr>
    return -1;
    80005bf4:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    80005bf6:	00054b63          	bltz	a0,80005c0c <sys_fstat+0x44>
  return filestat(f, st);
    80005bfa:	fe043583          	ld	a1,-32(s0)
    80005bfe:	fe843503          	ld	a0,-24(s0)
    80005c02:	fffff097          	auipc	ra,0xfffff
    80005c06:	32a080e7          	jalr	810(ra) # 80004f2c <filestat>
    80005c0a:	87aa                	mv	a5,a0
}
    80005c0c:	853e                	mv	a0,a5
    80005c0e:	60e2                	ld	ra,24(sp)
    80005c10:	6442                	ld	s0,16(sp)
    80005c12:	6105                	addi	sp,sp,32
    80005c14:	8082                	ret

0000000080005c16 <sys_link>:
{
    80005c16:	7169                	addi	sp,sp,-304
    80005c18:	f606                	sd	ra,296(sp)
    80005c1a:	f222                	sd	s0,288(sp)
    80005c1c:	ee26                	sd	s1,280(sp)
    80005c1e:	ea4a                	sd	s2,272(sp)
    80005c20:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c22:	08000613          	li	a2,128
    80005c26:	ed040593          	addi	a1,s0,-304
    80005c2a:	4501                	li	a0,0
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	864080e7          	jalr	-1948(ra) # 80003490 <argstr>
    return -1;
    80005c34:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c36:	10054e63          	bltz	a0,80005d52 <sys_link+0x13c>
    80005c3a:	08000613          	li	a2,128
    80005c3e:	f5040593          	addi	a1,s0,-176
    80005c42:	4505                	li	a0,1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	84c080e7          	jalr	-1972(ra) # 80003490 <argstr>
    return -1;
    80005c4c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005c4e:	10054263          	bltz	a0,80005d52 <sys_link+0x13c>
  begin_op();
    80005c52:	fffff097          	auipc	ra,0xfffff
    80005c56:	d3e080e7          	jalr	-706(ra) # 80004990 <begin_op>
  if((ip = namei(old)) == 0){
    80005c5a:	ed040513          	addi	a0,s0,-304
    80005c5e:	fffff097          	auipc	ra,0xfffff
    80005c62:	b16080e7          	jalr	-1258(ra) # 80004774 <namei>
    80005c66:	84aa                	mv	s1,a0
    80005c68:	c551                	beqz	a0,80005cf4 <sys_link+0xde>
  ilock(ip);
    80005c6a:	ffffe097          	auipc	ra,0xffffe
    80005c6e:	354080e7          	jalr	852(ra) # 80003fbe <ilock>
  if(ip->type == T_DIR){
    80005c72:	04449703          	lh	a4,68(s1)
    80005c76:	4785                	li	a5,1
    80005c78:	08f70463          	beq	a4,a5,80005d00 <sys_link+0xea>
  ip->nlink++;
    80005c7c:	04a4d783          	lhu	a5,74(s1)
    80005c80:	2785                	addiw	a5,a5,1
    80005c82:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005c86:	8526                	mv	a0,s1
    80005c88:	ffffe097          	auipc	ra,0xffffe
    80005c8c:	26c080e7          	jalr	620(ra) # 80003ef4 <iupdate>
  iunlock(ip);
    80005c90:	8526                	mv	a0,s1
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	3ee080e7          	jalr	1006(ra) # 80004080 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005c9a:	fd040593          	addi	a1,s0,-48
    80005c9e:	f5040513          	addi	a0,s0,-176
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	af0080e7          	jalr	-1296(ra) # 80004792 <nameiparent>
    80005caa:	892a                	mv	s2,a0
    80005cac:	c935                	beqz	a0,80005d20 <sys_link+0x10a>
  ilock(dp);
    80005cae:	ffffe097          	auipc	ra,0xffffe
    80005cb2:	310080e7          	jalr	784(ra) # 80003fbe <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005cb6:	00092703          	lw	a4,0(s2)
    80005cba:	409c                	lw	a5,0(s1)
    80005cbc:	04f71d63          	bne	a4,a5,80005d16 <sys_link+0x100>
    80005cc0:	40d0                	lw	a2,4(s1)
    80005cc2:	fd040593          	addi	a1,s0,-48
    80005cc6:	854a                	mv	a0,s2
    80005cc8:	fffff097          	auipc	ra,0xfffff
    80005ccc:	9ea080e7          	jalr	-1558(ra) # 800046b2 <dirlink>
    80005cd0:	04054363          	bltz	a0,80005d16 <sys_link+0x100>
  iunlockput(dp);
    80005cd4:	854a                	mv	a0,s2
    80005cd6:	ffffe097          	auipc	ra,0xffffe
    80005cda:	54a080e7          	jalr	1354(ra) # 80004220 <iunlockput>
  iput(ip);
    80005cde:	8526                	mv	a0,s1
    80005ce0:	ffffe097          	auipc	ra,0xffffe
    80005ce4:	498080e7          	jalr	1176(ra) # 80004178 <iput>
  end_op();
    80005ce8:	fffff097          	auipc	ra,0xfffff
    80005cec:	d28080e7          	jalr	-728(ra) # 80004a10 <end_op>
  return 0;
    80005cf0:	4781                	li	a5,0
    80005cf2:	a085                	j	80005d52 <sys_link+0x13c>
    end_op();
    80005cf4:	fffff097          	auipc	ra,0xfffff
    80005cf8:	d1c080e7          	jalr	-740(ra) # 80004a10 <end_op>
    return -1;
    80005cfc:	57fd                	li	a5,-1
    80005cfe:	a891                	j	80005d52 <sys_link+0x13c>
    iunlockput(ip);
    80005d00:	8526                	mv	a0,s1
    80005d02:	ffffe097          	auipc	ra,0xffffe
    80005d06:	51e080e7          	jalr	1310(ra) # 80004220 <iunlockput>
    end_op();
    80005d0a:	fffff097          	auipc	ra,0xfffff
    80005d0e:	d06080e7          	jalr	-762(ra) # 80004a10 <end_op>
    return -1;
    80005d12:	57fd                	li	a5,-1
    80005d14:	a83d                	j	80005d52 <sys_link+0x13c>
    iunlockput(dp);
    80005d16:	854a                	mv	a0,s2
    80005d18:	ffffe097          	auipc	ra,0xffffe
    80005d1c:	508080e7          	jalr	1288(ra) # 80004220 <iunlockput>
  ilock(ip);
    80005d20:	8526                	mv	a0,s1
    80005d22:	ffffe097          	auipc	ra,0xffffe
    80005d26:	29c080e7          	jalr	668(ra) # 80003fbe <ilock>
  ip->nlink--;
    80005d2a:	04a4d783          	lhu	a5,74(s1)
    80005d2e:	37fd                	addiw	a5,a5,-1
    80005d30:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005d34:	8526                	mv	a0,s1
    80005d36:	ffffe097          	auipc	ra,0xffffe
    80005d3a:	1be080e7          	jalr	446(ra) # 80003ef4 <iupdate>
  iunlockput(ip);
    80005d3e:	8526                	mv	a0,s1
    80005d40:	ffffe097          	auipc	ra,0xffffe
    80005d44:	4e0080e7          	jalr	1248(ra) # 80004220 <iunlockput>
  end_op();
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	cc8080e7          	jalr	-824(ra) # 80004a10 <end_op>
  return -1;
    80005d50:	57fd                	li	a5,-1
}
    80005d52:	853e                	mv	a0,a5
    80005d54:	70b2                	ld	ra,296(sp)
    80005d56:	7412                	ld	s0,288(sp)
    80005d58:	64f2                	ld	s1,280(sp)
    80005d5a:	6952                	ld	s2,272(sp)
    80005d5c:	6155                	addi	sp,sp,304
    80005d5e:	8082                	ret

0000000080005d60 <sys_unlink>:
{
    80005d60:	7151                	addi	sp,sp,-240
    80005d62:	f586                	sd	ra,232(sp)
    80005d64:	f1a2                	sd	s0,224(sp)
    80005d66:	eda6                	sd	s1,216(sp)
    80005d68:	e9ca                	sd	s2,208(sp)
    80005d6a:	e5ce                	sd	s3,200(sp)
    80005d6c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005d6e:	08000613          	li	a2,128
    80005d72:	f3040593          	addi	a1,s0,-208
    80005d76:	4501                	li	a0,0
    80005d78:	ffffd097          	auipc	ra,0xffffd
    80005d7c:	718080e7          	jalr	1816(ra) # 80003490 <argstr>
    80005d80:	18054163          	bltz	a0,80005f02 <sys_unlink+0x1a2>
  begin_op();
    80005d84:	fffff097          	auipc	ra,0xfffff
    80005d88:	c0c080e7          	jalr	-1012(ra) # 80004990 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005d8c:	fb040593          	addi	a1,s0,-80
    80005d90:	f3040513          	addi	a0,s0,-208
    80005d94:	fffff097          	auipc	ra,0xfffff
    80005d98:	9fe080e7          	jalr	-1538(ra) # 80004792 <nameiparent>
    80005d9c:	84aa                	mv	s1,a0
    80005d9e:	c979                	beqz	a0,80005e74 <sys_unlink+0x114>
  ilock(dp);
    80005da0:	ffffe097          	auipc	ra,0xffffe
    80005da4:	21e080e7          	jalr	542(ra) # 80003fbe <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005da8:	00003597          	auipc	a1,0x3
    80005dac:	95858593          	addi	a1,a1,-1704 # 80008700 <syscalls+0x2c0>
    80005db0:	fb040513          	addi	a0,s0,-80
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	6d4080e7          	jalr	1748(ra) # 80004488 <namecmp>
    80005dbc:	14050a63          	beqz	a0,80005f10 <sys_unlink+0x1b0>
    80005dc0:	00003597          	auipc	a1,0x3
    80005dc4:	94858593          	addi	a1,a1,-1720 # 80008708 <syscalls+0x2c8>
    80005dc8:	fb040513          	addi	a0,s0,-80
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	6bc080e7          	jalr	1724(ra) # 80004488 <namecmp>
    80005dd4:	12050e63          	beqz	a0,80005f10 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005dd8:	f2c40613          	addi	a2,s0,-212
    80005ddc:	fb040593          	addi	a1,s0,-80
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	6c0080e7          	jalr	1728(ra) # 800044a2 <dirlookup>
    80005dea:	892a                	mv	s2,a0
    80005dec:	12050263          	beqz	a0,80005f10 <sys_unlink+0x1b0>
  ilock(ip);
    80005df0:	ffffe097          	auipc	ra,0xffffe
    80005df4:	1ce080e7          	jalr	462(ra) # 80003fbe <ilock>
  if(ip->nlink < 1)
    80005df8:	04a91783          	lh	a5,74(s2)
    80005dfc:	08f05263          	blez	a5,80005e80 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005e00:	04491703          	lh	a4,68(s2)
    80005e04:	4785                	li	a5,1
    80005e06:	08f70563          	beq	a4,a5,80005e90 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005e0a:	4641                	li	a2,16
    80005e0c:	4581                	li	a1,0
    80005e0e:	fc040513          	addi	a0,s0,-64
    80005e12:	ffffb097          	auipc	ra,0xffffb
    80005e16:	ffe080e7          	jalr	-2(ra) # 80000e10 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005e1a:	4741                	li	a4,16
    80005e1c:	f2c42683          	lw	a3,-212(s0)
    80005e20:	fc040613          	addi	a2,s0,-64
    80005e24:	4581                	li	a1,0
    80005e26:	8526                	mv	a0,s1
    80005e28:	ffffe097          	auipc	ra,0xffffe
    80005e2c:	542080e7          	jalr	1346(ra) # 8000436a <writei>
    80005e30:	47c1                	li	a5,16
    80005e32:	0af51563          	bne	a0,a5,80005edc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005e36:	04491703          	lh	a4,68(s2)
    80005e3a:	4785                	li	a5,1
    80005e3c:	0af70863          	beq	a4,a5,80005eec <sys_unlink+0x18c>
  iunlockput(dp);
    80005e40:	8526                	mv	a0,s1
    80005e42:	ffffe097          	auipc	ra,0xffffe
    80005e46:	3de080e7          	jalr	990(ra) # 80004220 <iunlockput>
  ip->nlink--;
    80005e4a:	04a95783          	lhu	a5,74(s2)
    80005e4e:	37fd                	addiw	a5,a5,-1
    80005e50:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005e54:	854a                	mv	a0,s2
    80005e56:	ffffe097          	auipc	ra,0xffffe
    80005e5a:	09e080e7          	jalr	158(ra) # 80003ef4 <iupdate>
  iunlockput(ip);
    80005e5e:	854a                	mv	a0,s2
    80005e60:	ffffe097          	auipc	ra,0xffffe
    80005e64:	3c0080e7          	jalr	960(ra) # 80004220 <iunlockput>
  end_op();
    80005e68:	fffff097          	auipc	ra,0xfffff
    80005e6c:	ba8080e7          	jalr	-1112(ra) # 80004a10 <end_op>
  return 0;
    80005e70:	4501                	li	a0,0
    80005e72:	a84d                	j	80005f24 <sys_unlink+0x1c4>
    end_op();
    80005e74:	fffff097          	auipc	ra,0xfffff
    80005e78:	b9c080e7          	jalr	-1124(ra) # 80004a10 <end_op>
    return -1;
    80005e7c:	557d                	li	a0,-1
    80005e7e:	a05d                	j	80005f24 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005e80:	00003517          	auipc	a0,0x3
    80005e84:	8b050513          	addi	a0,a0,-1872 # 80008730 <syscalls+0x2f0>
    80005e88:	ffffa097          	auipc	ra,0xffffa
    80005e8c:	6a8080e7          	jalr	1704(ra) # 80000530 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005e90:	04c92703          	lw	a4,76(s2)
    80005e94:	02000793          	li	a5,32
    80005e98:	f6e7f9e3          	bgeu	a5,a4,80005e0a <sys_unlink+0xaa>
    80005e9c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005ea0:	4741                	li	a4,16
    80005ea2:	86ce                	mv	a3,s3
    80005ea4:	f1840613          	addi	a2,s0,-232
    80005ea8:	4581                	li	a1,0
    80005eaa:	854a                	mv	a0,s2
    80005eac:	ffffe097          	auipc	ra,0xffffe
    80005eb0:	3c6080e7          	jalr	966(ra) # 80004272 <readi>
    80005eb4:	47c1                	li	a5,16
    80005eb6:	00f51b63          	bne	a0,a5,80005ecc <sys_unlink+0x16c>
    if(de.inum != 0)
    80005eba:	f1845783          	lhu	a5,-232(s0)
    80005ebe:	e7a1                	bnez	a5,80005f06 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005ec0:	29c1                	addiw	s3,s3,16
    80005ec2:	04c92783          	lw	a5,76(s2)
    80005ec6:	fcf9ede3          	bltu	s3,a5,80005ea0 <sys_unlink+0x140>
    80005eca:	b781                	j	80005e0a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005ecc:	00003517          	auipc	a0,0x3
    80005ed0:	87c50513          	addi	a0,a0,-1924 # 80008748 <syscalls+0x308>
    80005ed4:	ffffa097          	auipc	ra,0xffffa
    80005ed8:	65c080e7          	jalr	1628(ra) # 80000530 <panic>
    panic("unlink: writei");
    80005edc:	00003517          	auipc	a0,0x3
    80005ee0:	88450513          	addi	a0,a0,-1916 # 80008760 <syscalls+0x320>
    80005ee4:	ffffa097          	auipc	ra,0xffffa
    80005ee8:	64c080e7          	jalr	1612(ra) # 80000530 <panic>
    dp->nlink--;
    80005eec:	04a4d783          	lhu	a5,74(s1)
    80005ef0:	37fd                	addiw	a5,a5,-1
    80005ef2:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ef6:	8526                	mv	a0,s1
    80005ef8:	ffffe097          	auipc	ra,0xffffe
    80005efc:	ffc080e7          	jalr	-4(ra) # 80003ef4 <iupdate>
    80005f00:	b781                	j	80005e40 <sys_unlink+0xe0>
    return -1;
    80005f02:	557d                	li	a0,-1
    80005f04:	a005                	j	80005f24 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005f06:	854a                	mv	a0,s2
    80005f08:	ffffe097          	auipc	ra,0xffffe
    80005f0c:	318080e7          	jalr	792(ra) # 80004220 <iunlockput>
  iunlockput(dp);
    80005f10:	8526                	mv	a0,s1
    80005f12:	ffffe097          	auipc	ra,0xffffe
    80005f16:	30e080e7          	jalr	782(ra) # 80004220 <iunlockput>
  end_op();
    80005f1a:	fffff097          	auipc	ra,0xfffff
    80005f1e:	af6080e7          	jalr	-1290(ra) # 80004a10 <end_op>
  return -1;
    80005f22:	557d                	li	a0,-1
}
    80005f24:	70ae                	ld	ra,232(sp)
    80005f26:	740e                	ld	s0,224(sp)
    80005f28:	64ee                	ld	s1,216(sp)
    80005f2a:	694e                	ld	s2,208(sp)
    80005f2c:	69ae                	ld	s3,200(sp)
    80005f2e:	616d                	addi	sp,sp,240
    80005f30:	8082                	ret

0000000080005f32 <sys_open>:

uint64
sys_open(void)
{
    80005f32:	7131                	addi	sp,sp,-192
    80005f34:	fd06                	sd	ra,184(sp)
    80005f36:	f922                	sd	s0,176(sp)
    80005f38:	f526                	sd	s1,168(sp)
    80005f3a:	f14a                	sd	s2,160(sp)
    80005f3c:	ed4e                	sd	s3,152(sp)
    80005f3e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f40:	08000613          	li	a2,128
    80005f44:	f5040593          	addi	a1,s0,-176
    80005f48:	4501                	li	a0,0
    80005f4a:	ffffd097          	auipc	ra,0xffffd
    80005f4e:	546080e7          	jalr	1350(ra) # 80003490 <argstr>
    return -1;
    80005f52:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005f54:	0c054163          	bltz	a0,80006016 <sys_open+0xe4>
    80005f58:	f4c40593          	addi	a1,s0,-180
    80005f5c:	4505                	li	a0,1
    80005f5e:	ffffd097          	auipc	ra,0xffffd
    80005f62:	4ee080e7          	jalr	1262(ra) # 8000344c <argint>
    80005f66:	0a054863          	bltz	a0,80006016 <sys_open+0xe4>

  begin_op();
    80005f6a:	fffff097          	auipc	ra,0xfffff
    80005f6e:	a26080e7          	jalr	-1498(ra) # 80004990 <begin_op>

  if(omode & O_CREATE){
    80005f72:	f4c42783          	lw	a5,-180(s0)
    80005f76:	2007f793          	andi	a5,a5,512
    80005f7a:	cbdd                	beqz	a5,80006030 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005f7c:	4681                	li	a3,0
    80005f7e:	4601                	li	a2,0
    80005f80:	4589                	li	a1,2
    80005f82:	f5040513          	addi	a0,s0,-176
    80005f86:	00000097          	auipc	ra,0x0
    80005f8a:	972080e7          	jalr	-1678(ra) # 800058f8 <create>
    80005f8e:	892a                	mv	s2,a0
    if(ip == 0){
    80005f90:	c959                	beqz	a0,80006026 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005f92:	04491703          	lh	a4,68(s2)
    80005f96:	478d                	li	a5,3
    80005f98:	00f71763          	bne	a4,a5,80005fa6 <sys_open+0x74>
    80005f9c:	04695703          	lhu	a4,70(s2)
    80005fa0:	47a5                	li	a5,9
    80005fa2:	0ce7ec63          	bltu	a5,a4,8000607a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	e02080e7          	jalr	-510(ra) # 80004da8 <filealloc>
    80005fae:	89aa                	mv	s3,a0
    80005fb0:	10050263          	beqz	a0,800060b4 <sys_open+0x182>
    80005fb4:	00000097          	auipc	ra,0x0
    80005fb8:	902080e7          	jalr	-1790(ra) # 800058b6 <fdalloc>
    80005fbc:	84aa                	mv	s1,a0
    80005fbe:	0e054663          	bltz	a0,800060aa <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005fc2:	04491703          	lh	a4,68(s2)
    80005fc6:	478d                	li	a5,3
    80005fc8:	0cf70463          	beq	a4,a5,80006090 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005fcc:	4789                	li	a5,2
    80005fce:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005fd2:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005fd6:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005fda:	f4c42783          	lw	a5,-180(s0)
    80005fde:	0017c713          	xori	a4,a5,1
    80005fe2:	8b05                	andi	a4,a4,1
    80005fe4:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005fe8:	0037f713          	andi	a4,a5,3
    80005fec:	00e03733          	snez	a4,a4
    80005ff0:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005ff4:	4007f793          	andi	a5,a5,1024
    80005ff8:	c791                	beqz	a5,80006004 <sys_open+0xd2>
    80005ffa:	04491703          	lh	a4,68(s2)
    80005ffe:	4789                	li	a5,2
    80006000:	08f70f63          	beq	a4,a5,8000609e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006004:	854a                	mv	a0,s2
    80006006:	ffffe097          	auipc	ra,0xffffe
    8000600a:	07a080e7          	jalr	122(ra) # 80004080 <iunlock>
  end_op();
    8000600e:	fffff097          	auipc	ra,0xfffff
    80006012:	a02080e7          	jalr	-1534(ra) # 80004a10 <end_op>

  return fd;
}
    80006016:	8526                	mv	a0,s1
    80006018:	70ea                	ld	ra,184(sp)
    8000601a:	744a                	ld	s0,176(sp)
    8000601c:	74aa                	ld	s1,168(sp)
    8000601e:	790a                	ld	s2,160(sp)
    80006020:	69ea                	ld	s3,152(sp)
    80006022:	6129                	addi	sp,sp,192
    80006024:	8082                	ret
      end_op();
    80006026:	fffff097          	auipc	ra,0xfffff
    8000602a:	9ea080e7          	jalr	-1558(ra) # 80004a10 <end_op>
      return -1;
    8000602e:	b7e5                	j	80006016 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80006030:	f5040513          	addi	a0,s0,-176
    80006034:	ffffe097          	auipc	ra,0xffffe
    80006038:	740080e7          	jalr	1856(ra) # 80004774 <namei>
    8000603c:	892a                	mv	s2,a0
    8000603e:	c905                	beqz	a0,8000606e <sys_open+0x13c>
    ilock(ip);
    80006040:	ffffe097          	auipc	ra,0xffffe
    80006044:	f7e080e7          	jalr	-130(ra) # 80003fbe <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006048:	04491703          	lh	a4,68(s2)
    8000604c:	4785                	li	a5,1
    8000604e:	f4f712e3          	bne	a4,a5,80005f92 <sys_open+0x60>
    80006052:	f4c42783          	lw	a5,-180(s0)
    80006056:	dba1                	beqz	a5,80005fa6 <sys_open+0x74>
      iunlockput(ip);
    80006058:	854a                	mv	a0,s2
    8000605a:	ffffe097          	auipc	ra,0xffffe
    8000605e:	1c6080e7          	jalr	454(ra) # 80004220 <iunlockput>
      end_op();
    80006062:	fffff097          	auipc	ra,0xfffff
    80006066:	9ae080e7          	jalr	-1618(ra) # 80004a10 <end_op>
      return -1;
    8000606a:	54fd                	li	s1,-1
    8000606c:	b76d                	j	80006016 <sys_open+0xe4>
      end_op();
    8000606e:	fffff097          	auipc	ra,0xfffff
    80006072:	9a2080e7          	jalr	-1630(ra) # 80004a10 <end_op>
      return -1;
    80006076:	54fd                	li	s1,-1
    80006078:	bf79                	j	80006016 <sys_open+0xe4>
    iunlockput(ip);
    8000607a:	854a                	mv	a0,s2
    8000607c:	ffffe097          	auipc	ra,0xffffe
    80006080:	1a4080e7          	jalr	420(ra) # 80004220 <iunlockput>
    end_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	98c080e7          	jalr	-1652(ra) # 80004a10 <end_op>
    return -1;
    8000608c:	54fd                	li	s1,-1
    8000608e:	b761                	j	80006016 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006090:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006094:	04691783          	lh	a5,70(s2)
    80006098:	02f99223          	sh	a5,36(s3)
    8000609c:	bf2d                	j	80005fd6 <sys_open+0xa4>
    itrunc(ip);
    8000609e:	854a                	mv	a0,s2
    800060a0:	ffffe097          	auipc	ra,0xffffe
    800060a4:	02c080e7          	jalr	44(ra) # 800040cc <itrunc>
    800060a8:	bfb1                	j	80006004 <sys_open+0xd2>
      fileclose(f);
    800060aa:	854e                	mv	a0,s3
    800060ac:	fffff097          	auipc	ra,0xfffff
    800060b0:	db8080e7          	jalr	-584(ra) # 80004e64 <fileclose>
    iunlockput(ip);
    800060b4:	854a                	mv	a0,s2
    800060b6:	ffffe097          	auipc	ra,0xffffe
    800060ba:	16a080e7          	jalr	362(ra) # 80004220 <iunlockput>
    end_op();
    800060be:	fffff097          	auipc	ra,0xfffff
    800060c2:	952080e7          	jalr	-1710(ra) # 80004a10 <end_op>
    return -1;
    800060c6:	54fd                	li	s1,-1
    800060c8:	b7b9                	j	80006016 <sys_open+0xe4>

00000000800060ca <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800060ca:	7175                	addi	sp,sp,-144
    800060cc:	e506                	sd	ra,136(sp)
    800060ce:	e122                	sd	s0,128(sp)
    800060d0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800060d2:	fffff097          	auipc	ra,0xfffff
    800060d6:	8be080e7          	jalr	-1858(ra) # 80004990 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800060da:	08000613          	li	a2,128
    800060de:	f7040593          	addi	a1,s0,-144
    800060e2:	4501                	li	a0,0
    800060e4:	ffffd097          	auipc	ra,0xffffd
    800060e8:	3ac080e7          	jalr	940(ra) # 80003490 <argstr>
    800060ec:	02054963          	bltz	a0,8000611e <sys_mkdir+0x54>
    800060f0:	4681                	li	a3,0
    800060f2:	4601                	li	a2,0
    800060f4:	4585                	li	a1,1
    800060f6:	f7040513          	addi	a0,s0,-144
    800060fa:	fffff097          	auipc	ra,0xfffff
    800060fe:	7fe080e7          	jalr	2046(ra) # 800058f8 <create>
    80006102:	cd11                	beqz	a0,8000611e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006104:	ffffe097          	auipc	ra,0xffffe
    80006108:	11c080e7          	jalr	284(ra) # 80004220 <iunlockput>
  end_op();
    8000610c:	fffff097          	auipc	ra,0xfffff
    80006110:	904080e7          	jalr	-1788(ra) # 80004a10 <end_op>
  return 0;
    80006114:	4501                	li	a0,0
}
    80006116:	60aa                	ld	ra,136(sp)
    80006118:	640a                	ld	s0,128(sp)
    8000611a:	6149                	addi	sp,sp,144
    8000611c:	8082                	ret
    end_op();
    8000611e:	fffff097          	auipc	ra,0xfffff
    80006122:	8f2080e7          	jalr	-1806(ra) # 80004a10 <end_op>
    return -1;
    80006126:	557d                	li	a0,-1
    80006128:	b7fd                	j	80006116 <sys_mkdir+0x4c>

000000008000612a <sys_mknod>:

uint64
sys_mknod(void)
{
    8000612a:	7135                	addi	sp,sp,-160
    8000612c:	ed06                	sd	ra,152(sp)
    8000612e:	e922                	sd	s0,144(sp)
    80006130:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80006132:	fffff097          	auipc	ra,0xfffff
    80006136:	85e080e7          	jalr	-1954(ra) # 80004990 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000613a:	08000613          	li	a2,128
    8000613e:	f7040593          	addi	a1,s0,-144
    80006142:	4501                	li	a0,0
    80006144:	ffffd097          	auipc	ra,0xffffd
    80006148:	34c080e7          	jalr	844(ra) # 80003490 <argstr>
    8000614c:	04054a63          	bltz	a0,800061a0 <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80006150:	f6c40593          	addi	a1,s0,-148
    80006154:	4505                	li	a0,1
    80006156:	ffffd097          	auipc	ra,0xffffd
    8000615a:	2f6080e7          	jalr	758(ra) # 8000344c <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000615e:	04054163          	bltz	a0,800061a0 <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80006162:	f6840593          	addi	a1,s0,-152
    80006166:	4509                	li	a0,2
    80006168:	ffffd097          	auipc	ra,0xffffd
    8000616c:	2e4080e7          	jalr	740(ra) # 8000344c <argint>
     argint(1, &major) < 0 ||
    80006170:	02054863          	bltz	a0,800061a0 <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006174:	f6841683          	lh	a3,-152(s0)
    80006178:	f6c41603          	lh	a2,-148(s0)
    8000617c:	458d                	li	a1,3
    8000617e:	f7040513          	addi	a0,s0,-144
    80006182:	fffff097          	auipc	ra,0xfffff
    80006186:	776080e7          	jalr	1910(ra) # 800058f8 <create>
     argint(2, &minor) < 0 ||
    8000618a:	c919                	beqz	a0,800061a0 <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000618c:	ffffe097          	auipc	ra,0xffffe
    80006190:	094080e7          	jalr	148(ra) # 80004220 <iunlockput>
  end_op();
    80006194:	fffff097          	auipc	ra,0xfffff
    80006198:	87c080e7          	jalr	-1924(ra) # 80004a10 <end_op>
  return 0;
    8000619c:	4501                	li	a0,0
    8000619e:	a031                	j	800061aa <sys_mknod+0x80>
    end_op();
    800061a0:	fffff097          	auipc	ra,0xfffff
    800061a4:	870080e7          	jalr	-1936(ra) # 80004a10 <end_op>
    return -1;
    800061a8:	557d                	li	a0,-1
}
    800061aa:	60ea                	ld	ra,152(sp)
    800061ac:	644a                	ld	s0,144(sp)
    800061ae:	610d                	addi	sp,sp,160
    800061b0:	8082                	ret

00000000800061b2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800061b2:	7135                	addi	sp,sp,-160
    800061b4:	ed06                	sd	ra,152(sp)
    800061b6:	e922                	sd	s0,144(sp)
    800061b8:	e526                	sd	s1,136(sp)
    800061ba:	e14a                	sd	s2,128(sp)
    800061bc:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800061be:	ffffc097          	auipc	ra,0xffffc
    800061c2:	018080e7          	jalr	24(ra) # 800021d6 <myproc>
    800061c6:	892a                	mv	s2,a0
  
  begin_op();
    800061c8:	ffffe097          	auipc	ra,0xffffe
    800061cc:	7c8080e7          	jalr	1992(ra) # 80004990 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800061d0:	08000613          	li	a2,128
    800061d4:	f6040593          	addi	a1,s0,-160
    800061d8:	4501                	li	a0,0
    800061da:	ffffd097          	auipc	ra,0xffffd
    800061de:	2b6080e7          	jalr	694(ra) # 80003490 <argstr>
    800061e2:	04054b63          	bltz	a0,80006238 <sys_chdir+0x86>
    800061e6:	f6040513          	addi	a0,s0,-160
    800061ea:	ffffe097          	auipc	ra,0xffffe
    800061ee:	58a080e7          	jalr	1418(ra) # 80004774 <namei>
    800061f2:	84aa                	mv	s1,a0
    800061f4:	c131                	beqz	a0,80006238 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800061f6:	ffffe097          	auipc	ra,0xffffe
    800061fa:	dc8080e7          	jalr	-568(ra) # 80003fbe <ilock>
  if(ip->type != T_DIR){
    800061fe:	04449703          	lh	a4,68(s1)
    80006202:	4785                	li	a5,1
    80006204:	04f71063          	bne	a4,a5,80006244 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006208:	8526                	mv	a0,s1
    8000620a:	ffffe097          	auipc	ra,0xffffe
    8000620e:	e76080e7          	jalr	-394(ra) # 80004080 <iunlock>
  iput(p->cwd);
    80006212:	15093503          	ld	a0,336(s2)
    80006216:	ffffe097          	auipc	ra,0xffffe
    8000621a:	f62080e7          	jalr	-158(ra) # 80004178 <iput>
  end_op();
    8000621e:	ffffe097          	auipc	ra,0xffffe
    80006222:	7f2080e7          	jalr	2034(ra) # 80004a10 <end_op>
  p->cwd = ip;
    80006226:	14993823          	sd	s1,336(s2)
  return 0;
    8000622a:	4501                	li	a0,0
}
    8000622c:	60ea                	ld	ra,152(sp)
    8000622e:	644a                	ld	s0,144(sp)
    80006230:	64aa                	ld	s1,136(sp)
    80006232:	690a                	ld	s2,128(sp)
    80006234:	610d                	addi	sp,sp,160
    80006236:	8082                	ret
    end_op();
    80006238:	ffffe097          	auipc	ra,0xffffe
    8000623c:	7d8080e7          	jalr	2008(ra) # 80004a10 <end_op>
    return -1;
    80006240:	557d                	li	a0,-1
    80006242:	b7ed                	j	8000622c <sys_chdir+0x7a>
    iunlockput(ip);
    80006244:	8526                	mv	a0,s1
    80006246:	ffffe097          	auipc	ra,0xffffe
    8000624a:	fda080e7          	jalr	-38(ra) # 80004220 <iunlockput>
    end_op();
    8000624e:	ffffe097          	auipc	ra,0xffffe
    80006252:	7c2080e7          	jalr	1986(ra) # 80004a10 <end_op>
    return -1;
    80006256:	557d                	li	a0,-1
    80006258:	bfd1                	j	8000622c <sys_chdir+0x7a>

000000008000625a <sys_exec>:

uint64
sys_exec(void)
{
    8000625a:	7145                	addi	sp,sp,-464
    8000625c:	e786                	sd	ra,456(sp)
    8000625e:	e3a2                	sd	s0,448(sp)
    80006260:	ff26                	sd	s1,440(sp)
    80006262:	fb4a                	sd	s2,432(sp)
    80006264:	f74e                	sd	s3,424(sp)
    80006266:	f352                	sd	s4,416(sp)
    80006268:	ef56                	sd	s5,408(sp)
    8000626a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    8000626c:	08000613          	li	a2,128
    80006270:	f4040593          	addi	a1,s0,-192
    80006274:	4501                	li	a0,0
    80006276:	ffffd097          	auipc	ra,0xffffd
    8000627a:	21a080e7          	jalr	538(ra) # 80003490 <argstr>
    return -1;
    8000627e:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80006280:	0c054a63          	bltz	a0,80006354 <sys_exec+0xfa>
    80006284:	e3840593          	addi	a1,s0,-456
    80006288:	4505                	li	a0,1
    8000628a:	ffffd097          	auipc	ra,0xffffd
    8000628e:	1e4080e7          	jalr	484(ra) # 8000346e <argaddr>
    80006292:	0c054163          	bltz	a0,80006354 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80006296:	10000613          	li	a2,256
    8000629a:	4581                	li	a1,0
    8000629c:	e4040513          	addi	a0,s0,-448
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	b70080e7          	jalr	-1168(ra) # 80000e10 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    800062a8:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    800062ac:	89a6                	mv	s3,s1
    800062ae:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    800062b0:	02000a13          	li	s4,32
    800062b4:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    800062b8:	00391513          	slli	a0,s2,0x3
    800062bc:	e3040593          	addi	a1,s0,-464
    800062c0:	e3843783          	ld	a5,-456(s0)
    800062c4:	953e                	add	a0,a0,a5
    800062c6:	ffffd097          	auipc	ra,0xffffd
    800062ca:	0ec080e7          	jalr	236(ra) # 800033b2 <fetchaddr>
    800062ce:	02054a63          	bltz	a0,80006302 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    800062d2:	e3043783          	ld	a5,-464(s0)
    800062d6:	c3b9                	beqz	a5,8000631c <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    800062d8:	ffffa097          	auipc	ra,0xffffa
    800062dc:	7d2080e7          	jalr	2002(ra) # 80000aaa <kalloc>
    800062e0:	85aa                	mv	a1,a0
    800062e2:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    800062e6:	cd11                	beqz	a0,80006302 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    800062e8:	6605                	lui	a2,0x1
    800062ea:	e3043503          	ld	a0,-464(s0)
    800062ee:	ffffd097          	auipc	ra,0xffffd
    800062f2:	116080e7          	jalr	278(ra) # 80003404 <fetchstr>
    800062f6:	00054663          	bltz	a0,80006302 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    800062fa:	0905                	addi	s2,s2,1
    800062fc:	09a1                	addi	s3,s3,8
    800062fe:	fb491be3          	bne	s2,s4,800062b4 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006302:	10048913          	addi	s2,s1,256
    80006306:	6088                	ld	a0,0(s1)
    80006308:	c529                	beqz	a0,80006352 <sys_exec+0xf8>
    kfree(argv[i]);
    8000630a:	ffffa097          	auipc	ra,0xffffa
    8000630e:	6e0080e7          	jalr	1760(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006312:	04a1                	addi	s1,s1,8
    80006314:	ff2499e3          	bne	s1,s2,80006306 <sys_exec+0xac>
  return -1;
    80006318:	597d                	li	s2,-1
    8000631a:	a82d                	j	80006354 <sys_exec+0xfa>
      argv[i] = 0;
    8000631c:	0a8e                	slli	s5,s5,0x3
    8000631e:	fc040793          	addi	a5,s0,-64
    80006322:	9abe                	add	s5,s5,a5
    80006324:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80006328:	e4040593          	addi	a1,s0,-448
    8000632c:	f4040513          	addi	a0,s0,-192
    80006330:	fffff097          	auipc	ra,0xfffff
    80006334:	194080e7          	jalr	404(ra) # 800054c4 <exec>
    80006338:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000633a:	10048993          	addi	s3,s1,256
    8000633e:	6088                	ld	a0,0(s1)
    80006340:	c911                	beqz	a0,80006354 <sys_exec+0xfa>
    kfree(argv[i]);
    80006342:	ffffa097          	auipc	ra,0xffffa
    80006346:	6a8080e7          	jalr	1704(ra) # 800009ea <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    8000634a:	04a1                	addi	s1,s1,8
    8000634c:	ff3499e3          	bne	s1,s3,8000633e <sys_exec+0xe4>
    80006350:	a011                	j	80006354 <sys_exec+0xfa>
  return -1;
    80006352:	597d                	li	s2,-1
}
    80006354:	854a                	mv	a0,s2
    80006356:	60be                	ld	ra,456(sp)
    80006358:	641e                	ld	s0,448(sp)
    8000635a:	74fa                	ld	s1,440(sp)
    8000635c:	795a                	ld	s2,432(sp)
    8000635e:	79ba                	ld	s3,424(sp)
    80006360:	7a1a                	ld	s4,416(sp)
    80006362:	6afa                	ld	s5,408(sp)
    80006364:	6179                	addi	sp,sp,464
    80006366:	8082                	ret

0000000080006368 <sys_pipe>:

uint64
sys_pipe(void)
{
    80006368:	7139                	addi	sp,sp,-64
    8000636a:	fc06                	sd	ra,56(sp)
    8000636c:	f822                	sd	s0,48(sp)
    8000636e:	f426                	sd	s1,40(sp)
    80006370:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006372:	ffffc097          	auipc	ra,0xffffc
    80006376:	e64080e7          	jalr	-412(ra) # 800021d6 <myproc>
    8000637a:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    8000637c:	fd840593          	addi	a1,s0,-40
    80006380:	4501                	li	a0,0
    80006382:	ffffd097          	auipc	ra,0xffffd
    80006386:	0ec080e7          	jalr	236(ra) # 8000346e <argaddr>
    return -1;
    8000638a:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    8000638c:	0e054063          	bltz	a0,8000646c <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80006390:	fc840593          	addi	a1,s0,-56
    80006394:	fd040513          	addi	a0,s0,-48
    80006398:	fffff097          	auipc	ra,0xfffff
    8000639c:	dfc080e7          	jalr	-516(ra) # 80005194 <pipealloc>
    return -1;
    800063a0:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    800063a2:	0c054563          	bltz	a0,8000646c <sys_pipe+0x104>
  fd0 = -1;
    800063a6:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    800063aa:	fd043503          	ld	a0,-48(s0)
    800063ae:	fffff097          	auipc	ra,0xfffff
    800063b2:	508080e7          	jalr	1288(ra) # 800058b6 <fdalloc>
    800063b6:	fca42223          	sw	a0,-60(s0)
    800063ba:	08054c63          	bltz	a0,80006452 <sys_pipe+0xea>
    800063be:	fc843503          	ld	a0,-56(s0)
    800063c2:	fffff097          	auipc	ra,0xfffff
    800063c6:	4f4080e7          	jalr	1268(ra) # 800058b6 <fdalloc>
    800063ca:	fca42023          	sw	a0,-64(s0)
    800063ce:	06054863          	bltz	a0,8000643e <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    800063d2:	4691                	li	a3,4
    800063d4:	fc440613          	addi	a2,s0,-60
    800063d8:	fd843583          	ld	a1,-40(s0)
    800063dc:	68a8                	ld	a0,80(s1)
    800063de:	ffffb097          	auipc	ra,0xffffb
    800063e2:	7b8080e7          	jalr	1976(ra) # 80001b96 <copyout>
    800063e6:	02054063          	bltz	a0,80006406 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    800063ea:	4691                	li	a3,4
    800063ec:	fc040613          	addi	a2,s0,-64
    800063f0:	fd843583          	ld	a1,-40(s0)
    800063f4:	0591                	addi	a1,a1,4
    800063f6:	68a8                	ld	a0,80(s1)
    800063f8:	ffffb097          	auipc	ra,0xffffb
    800063fc:	79e080e7          	jalr	1950(ra) # 80001b96 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006400:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006402:	06055563          	bgez	a0,8000646c <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80006406:	fc442783          	lw	a5,-60(s0)
    8000640a:	07e9                	addi	a5,a5,26
    8000640c:	078e                	slli	a5,a5,0x3
    8000640e:	97a6                	add	a5,a5,s1
    80006410:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006414:	fc042503          	lw	a0,-64(s0)
    80006418:	0569                	addi	a0,a0,26
    8000641a:	050e                	slli	a0,a0,0x3
    8000641c:	9526                	add	a0,a0,s1
    8000641e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006422:	fd043503          	ld	a0,-48(s0)
    80006426:	fffff097          	auipc	ra,0xfffff
    8000642a:	a3e080e7          	jalr	-1474(ra) # 80004e64 <fileclose>
    fileclose(wf);
    8000642e:	fc843503          	ld	a0,-56(s0)
    80006432:	fffff097          	auipc	ra,0xfffff
    80006436:	a32080e7          	jalr	-1486(ra) # 80004e64 <fileclose>
    return -1;
    8000643a:	57fd                	li	a5,-1
    8000643c:	a805                	j	8000646c <sys_pipe+0x104>
    if(fd0 >= 0)
    8000643e:	fc442783          	lw	a5,-60(s0)
    80006442:	0007c863          	bltz	a5,80006452 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006446:	01a78513          	addi	a0,a5,26
    8000644a:	050e                	slli	a0,a0,0x3
    8000644c:	9526                	add	a0,a0,s1
    8000644e:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006452:	fd043503          	ld	a0,-48(s0)
    80006456:	fffff097          	auipc	ra,0xfffff
    8000645a:	a0e080e7          	jalr	-1522(ra) # 80004e64 <fileclose>
    fileclose(wf);
    8000645e:	fc843503          	ld	a0,-56(s0)
    80006462:	fffff097          	auipc	ra,0xfffff
    80006466:	a02080e7          	jalr	-1534(ra) # 80004e64 <fileclose>
    return -1;
    8000646a:	57fd                	li	a5,-1
}
    8000646c:	853e                	mv	a0,a5
    8000646e:	70e2                	ld	ra,56(sp)
    80006470:	7442                	ld	s0,48(sp)
    80006472:	74a2                	ld	s1,40(sp)
    80006474:	6121                	addi	sp,sp,64
    80006476:	8082                	ret
	...

0000000080006480 <kernelvec>:
.globl kerneltrap
.globl kernelvec
.align 4
kernelvec:
        // make room to save registers.
        addi sp, sp, -256
    80006480:	7111                	addi	sp,sp,-256

        // save the registers.
        sd ra, 0(sp)
    80006482:	e006                	sd	ra,0(sp)
        sd sp, 8(sp)
    80006484:	e40a                	sd	sp,8(sp)
        sd gp, 16(sp)
    80006486:	e80e                	sd	gp,16(sp)
        sd tp, 24(sp)
    80006488:	ec12                	sd	tp,24(sp)
        sd t0, 32(sp)
    8000648a:	f016                	sd	t0,32(sp)
        sd t1, 40(sp)
    8000648c:	f41a                	sd	t1,40(sp)
        sd t2, 48(sp)
    8000648e:	f81e                	sd	t2,48(sp)
        sd s0, 56(sp)
    80006490:	fc22                	sd	s0,56(sp)
        sd s1, 64(sp)
    80006492:	e0a6                	sd	s1,64(sp)
        sd a0, 72(sp)
    80006494:	e4aa                	sd	a0,72(sp)
        sd a1, 80(sp)
    80006496:	e8ae                	sd	a1,80(sp)
        sd a2, 88(sp)
    80006498:	ecb2                	sd	a2,88(sp)
        sd a3, 96(sp)
    8000649a:	f0b6                	sd	a3,96(sp)
        sd a4, 104(sp)
    8000649c:	f4ba                	sd	a4,104(sp)
        sd a5, 112(sp)
    8000649e:	f8be                	sd	a5,112(sp)
        sd a6, 120(sp)
    800064a0:	fcc2                	sd	a6,120(sp)
        sd a7, 128(sp)
    800064a2:	e146                	sd	a7,128(sp)
        sd s2, 136(sp)
    800064a4:	e54a                	sd	s2,136(sp)
        sd s3, 144(sp)
    800064a6:	e94e                	sd	s3,144(sp)
        sd s4, 152(sp)
    800064a8:	ed52                	sd	s4,152(sp)
        sd s5, 160(sp)
    800064aa:	f156                	sd	s5,160(sp)
        sd s6, 168(sp)
    800064ac:	f55a                	sd	s6,168(sp)
        sd s7, 176(sp)
    800064ae:	f95e                	sd	s7,176(sp)
        sd s8, 184(sp)
    800064b0:	fd62                	sd	s8,184(sp)
        sd s9, 192(sp)
    800064b2:	e1e6                	sd	s9,192(sp)
        sd s10, 200(sp)
    800064b4:	e5ea                	sd	s10,200(sp)
        sd s11, 208(sp)
    800064b6:	e9ee                	sd	s11,208(sp)
        sd t3, 216(sp)
    800064b8:	edf2                	sd	t3,216(sp)
        sd t4, 224(sp)
    800064ba:	f1f6                	sd	t4,224(sp)
        sd t5, 232(sp)
    800064bc:	f5fa                	sd	t5,232(sp)
        sd t6, 240(sp)
    800064be:	f9fe                	sd	t6,240(sp)

	// call the C trap handler in trap.c
        call kerneltrap
    800064c0:	dbffc0ef          	jal	ra,8000327e <kerneltrap>

        // restore registers.
        ld ra, 0(sp)
    800064c4:	6082                	ld	ra,0(sp)
        ld sp, 8(sp)
    800064c6:	6122                	ld	sp,8(sp)
        ld gp, 16(sp)
    800064c8:	61c2                	ld	gp,16(sp)
        // not this, in case we moved CPUs: ld tp, 24(sp)
        ld t0, 32(sp)
    800064ca:	7282                	ld	t0,32(sp)
        ld t1, 40(sp)
    800064cc:	7322                	ld	t1,40(sp)
        ld t2, 48(sp)
    800064ce:	73c2                	ld	t2,48(sp)
        ld s0, 56(sp)
    800064d0:	7462                	ld	s0,56(sp)
        ld s1, 64(sp)
    800064d2:	6486                	ld	s1,64(sp)
        ld a0, 72(sp)
    800064d4:	6526                	ld	a0,72(sp)
        ld a1, 80(sp)
    800064d6:	65c6                	ld	a1,80(sp)
        ld a2, 88(sp)
    800064d8:	6666                	ld	a2,88(sp)
        ld a3, 96(sp)
    800064da:	7686                	ld	a3,96(sp)
        ld a4, 104(sp)
    800064dc:	7726                	ld	a4,104(sp)
        ld a5, 112(sp)
    800064de:	77c6                	ld	a5,112(sp)
        ld a6, 120(sp)
    800064e0:	7866                	ld	a6,120(sp)
        ld a7, 128(sp)
    800064e2:	688a                	ld	a7,128(sp)
        ld s2, 136(sp)
    800064e4:	692a                	ld	s2,136(sp)
        ld s3, 144(sp)
    800064e6:	69ca                	ld	s3,144(sp)
        ld s4, 152(sp)
    800064e8:	6a6a                	ld	s4,152(sp)
        ld s5, 160(sp)
    800064ea:	7a8a                	ld	s5,160(sp)
        ld s6, 168(sp)
    800064ec:	7b2a                	ld	s6,168(sp)
        ld s7, 176(sp)
    800064ee:	7bca                	ld	s7,176(sp)
        ld s8, 184(sp)
    800064f0:	7c6a                	ld	s8,184(sp)
        ld s9, 192(sp)
    800064f2:	6c8e                	ld	s9,192(sp)
        ld s10, 200(sp)
    800064f4:	6d2e                	ld	s10,200(sp)
        ld s11, 208(sp)
    800064f6:	6dce                	ld	s11,208(sp)
        ld t3, 216(sp)
    800064f8:	6e6e                	ld	t3,216(sp)
        ld t4, 224(sp)
    800064fa:	7e8e                	ld	t4,224(sp)
        ld t5, 232(sp)
    800064fc:	7f2e                	ld	t5,232(sp)
        ld t6, 240(sp)
    800064fe:	7fce                	ld	t6,240(sp)

        addi sp, sp, 256
    80006500:	6111                	addi	sp,sp,256

        // return to whatever we were doing in the kernel.
        sret
    80006502:	10200073          	sret
    80006506:	00000013          	nop
    8000650a:	00000013          	nop
    8000650e:	0001                	nop

0000000080006510 <timervec>:
        # start.c has set up the memory that mscratch points to:
        # scratch[0,8,16] : register save area.
        # scratch[24] : address of CLINT's MTIMECMP register.
        # scratch[32] : desired interval between interrupts.
        
        csrrw a0, mscratch, a0
    80006510:	34051573          	csrrw	a0,mscratch,a0
        sd a1, 0(a0)
    80006514:	e10c                	sd	a1,0(a0)
        sd a2, 8(a0)
    80006516:	e510                	sd	a2,8(a0)
        sd a3, 16(a0)
    80006518:	e914                	sd	a3,16(a0)

        # schedule the next timer interrupt
        # by adding interval to mtimecmp.
        ld a1, 24(a0) # CLINT_MTIMECMP(hart)
    8000651a:	6d0c                	ld	a1,24(a0)
        ld a2, 32(a0) # interval
    8000651c:	7110                	ld	a2,32(a0)
        ld a3, 0(a1)
    8000651e:	6194                	ld	a3,0(a1)
        add a3, a3, a2
    80006520:	96b2                	add	a3,a3,a2
        sd a3, 0(a1)
    80006522:	e194                	sd	a3,0(a1)

        # raise a supervisor software interrupt.
	li a1, 2
    80006524:	4589                	li	a1,2
        csrw sip, a1
    80006526:	14459073          	csrw	sip,a1

        ld a3, 16(a0)
    8000652a:	6914                	ld	a3,16(a0)
        ld a2, 8(a0)
    8000652c:	6510                	ld	a2,8(a0)
        ld a1, 0(a0)
    8000652e:	610c                	ld	a1,0(a0)
        csrrw a0, mscratch, a0
    80006530:	34051573          	csrrw	a0,mscratch,a0

        mret
    80006534:	30200073          	mret
	...

000000008000653a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    8000653a:	1141                	addi	sp,sp,-16
    8000653c:	e422                	sd	s0,8(sp)
    8000653e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006540:	0c0007b7          	lui	a5,0xc000
    80006544:	4705                	li	a4,1
    80006546:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006548:	c3d8                	sw	a4,4(a5)
}
    8000654a:	6422                	ld	s0,8(sp)
    8000654c:	0141                	addi	sp,sp,16
    8000654e:	8082                	ret

0000000080006550 <plicinithart>:

void
plicinithart(void)
{
    80006550:	1141                	addi	sp,sp,-16
    80006552:	e406                	sd	ra,8(sp)
    80006554:	e022                	sd	s0,0(sp)
    80006556:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006558:	ffffc097          	auipc	ra,0xffffc
    8000655c:	c52080e7          	jalr	-942(ra) # 800021aa <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006560:	0085171b          	slliw	a4,a0,0x8
    80006564:	0c0027b7          	lui	a5,0xc002
    80006568:	97ba                	add	a5,a5,a4
    8000656a:	40200713          	li	a4,1026
    8000656e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006572:	00d5151b          	slliw	a0,a0,0xd
    80006576:	0c2017b7          	lui	a5,0xc201
    8000657a:	953e                	add	a0,a0,a5
    8000657c:	00052023          	sw	zero,0(a0)
}
    80006580:	60a2                	ld	ra,8(sp)
    80006582:	6402                	ld	s0,0(sp)
    80006584:	0141                	addi	sp,sp,16
    80006586:	8082                	ret

0000000080006588 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006588:	1141                	addi	sp,sp,-16
    8000658a:	e406                	sd	ra,8(sp)
    8000658c:	e022                	sd	s0,0(sp)
    8000658e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006590:	ffffc097          	auipc	ra,0xffffc
    80006594:	c1a080e7          	jalr	-998(ra) # 800021aa <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006598:	00d5179b          	slliw	a5,a0,0xd
    8000659c:	0c201537          	lui	a0,0xc201
    800065a0:	953e                	add	a0,a0,a5
  return irq;
}
    800065a2:	4148                	lw	a0,4(a0)
    800065a4:	60a2                	ld	ra,8(sp)
    800065a6:	6402                	ld	s0,0(sp)
    800065a8:	0141                	addi	sp,sp,16
    800065aa:	8082                	ret

00000000800065ac <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    800065ac:	1101                	addi	sp,sp,-32
    800065ae:	ec06                	sd	ra,24(sp)
    800065b0:	e822                	sd	s0,16(sp)
    800065b2:	e426                	sd	s1,8(sp)
    800065b4:	1000                	addi	s0,sp,32
    800065b6:	84aa                	mv	s1,a0
  int hart = cpuid();
    800065b8:	ffffc097          	auipc	ra,0xffffc
    800065bc:	bf2080e7          	jalr	-1038(ra) # 800021aa <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    800065c0:	00d5151b          	slliw	a0,a0,0xd
    800065c4:	0c2017b7          	lui	a5,0xc201
    800065c8:	97aa                	add	a5,a5,a0
    800065ca:	c3c4                	sw	s1,4(a5)
}
    800065cc:	60e2                	ld	ra,24(sp)
    800065ce:	6442                	ld	s0,16(sp)
    800065d0:	64a2                	ld	s1,8(sp)
    800065d2:	6105                	addi	sp,sp,32
    800065d4:	8082                	ret

00000000800065d6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    800065d6:	1141                	addi	sp,sp,-16
    800065d8:	e406                	sd	ra,8(sp)
    800065da:	e022                	sd	s0,0(sp)
    800065dc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    800065de:	479d                	li	a5,7
    800065e0:	06a7c963          	blt	a5,a0,80006652 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    800065e4:	0001d797          	auipc	a5,0x1d
    800065e8:	a1c78793          	addi	a5,a5,-1508 # 80023000 <disk>
    800065ec:	00a78733          	add	a4,a5,a0
    800065f0:	6789                	lui	a5,0x2
    800065f2:	97ba                	add	a5,a5,a4
    800065f4:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    800065f8:	e7ad                	bnez	a5,80006662 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    800065fa:	00451793          	slli	a5,a0,0x4
    800065fe:	0001f717          	auipc	a4,0x1f
    80006602:	a0270713          	addi	a4,a4,-1534 # 80025000 <disk+0x2000>
    80006606:	6314                	ld	a3,0(a4)
    80006608:	96be                	add	a3,a3,a5
    8000660a:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    8000660e:	6314                	ld	a3,0(a4)
    80006610:	96be                	add	a3,a3,a5
    80006612:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    80006616:	6314                	ld	a3,0(a4)
    80006618:	96be                	add	a3,a3,a5
    8000661a:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    8000661e:	6318                	ld	a4,0(a4)
    80006620:	97ba                	add	a5,a5,a4
    80006622:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    80006626:	0001d797          	auipc	a5,0x1d
    8000662a:	9da78793          	addi	a5,a5,-1574 # 80023000 <disk>
    8000662e:	97aa                	add	a5,a5,a0
    80006630:	6509                	lui	a0,0x2
    80006632:	953e                	add	a0,a0,a5
    80006634:	4785                	li	a5,1
    80006636:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    8000663a:	0001f517          	auipc	a0,0x1f
    8000663e:	9de50513          	addi	a0,a0,-1570 # 80025018 <disk+0x2018>
    80006642:	ffffc097          	auipc	ra,0xffffc
    80006646:	67c080e7          	jalr	1660(ra) # 80002cbe <wakeup>
}
    8000664a:	60a2                	ld	ra,8(sp)
    8000664c:	6402                	ld	s0,0(sp)
    8000664e:	0141                	addi	sp,sp,16
    80006650:	8082                	ret
    panic("free_desc 1");
    80006652:	00002517          	auipc	a0,0x2
    80006656:	11e50513          	addi	a0,a0,286 # 80008770 <syscalls+0x330>
    8000665a:	ffffa097          	auipc	ra,0xffffa
    8000665e:	ed6080e7          	jalr	-298(ra) # 80000530 <panic>
    panic("free_desc 2");
    80006662:	00002517          	auipc	a0,0x2
    80006666:	11e50513          	addi	a0,a0,286 # 80008780 <syscalls+0x340>
    8000666a:	ffffa097          	auipc	ra,0xffffa
    8000666e:	ec6080e7          	jalr	-314(ra) # 80000530 <panic>

0000000080006672 <virtio_disk_init>:
{
    80006672:	1101                	addi	sp,sp,-32
    80006674:	ec06                	sd	ra,24(sp)
    80006676:	e822                	sd	s0,16(sp)
    80006678:	e426                	sd	s1,8(sp)
    8000667a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000667c:	00002597          	auipc	a1,0x2
    80006680:	11458593          	addi	a1,a1,276 # 80008790 <syscalls+0x350>
    80006684:	0001f517          	auipc	a0,0x1f
    80006688:	aa450513          	addi	a0,a0,-1372 # 80025128 <disk+0x2128>
    8000668c:	ffffa097          	auipc	ra,0xffffa
    80006690:	5f8080e7          	jalr	1528(ra) # 80000c84 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006694:	100017b7          	lui	a5,0x10001
    80006698:	4398                	lw	a4,0(a5)
    8000669a:	2701                	sext.w	a4,a4
    8000669c:	747277b7          	lui	a5,0x74727
    800066a0:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    800066a4:	0ef71163          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066a8:	100017b7          	lui	a5,0x10001
    800066ac:	43dc                	lw	a5,4(a5)
    800066ae:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800066b0:	4705                	li	a4,1
    800066b2:	0ce79a63          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066b6:	100017b7          	lui	a5,0x10001
    800066ba:	479c                	lw	a5,8(a5)
    800066bc:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    800066be:	4709                	li	a4,2
    800066c0:	0ce79363          	bne	a5,a4,80006786 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800066c4:	100017b7          	lui	a5,0x10001
    800066c8:	47d8                	lw	a4,12(a5)
    800066ca:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800066cc:	554d47b7          	lui	a5,0x554d4
    800066d0:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800066d4:	0af71963          	bne	a4,a5,80006786 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    800066d8:	100017b7          	lui	a5,0x10001
    800066dc:	4705                	li	a4,1
    800066de:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066e0:	470d                	li	a4,3
    800066e2:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800066e4:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    800066e6:	c7ffe737          	lui	a4,0xc7ffe
    800066ea:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47fd875f>
    800066ee:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800066f0:	2701                	sext.w	a4,a4
    800066f2:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f4:	472d                	li	a4,11
    800066f6:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800066f8:	473d                	li	a4,15
    800066fa:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    800066fc:	6705                	lui	a4,0x1
    800066fe:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006700:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006704:	5bdc                	lw	a5,52(a5)
    80006706:	2781                	sext.w	a5,a5
  if(max == 0)
    80006708:	c7d9                	beqz	a5,80006796 <virtio_disk_init+0x124>
  if(max < NUM)
    8000670a:	471d                	li	a4,7
    8000670c:	08f77d63          	bgeu	a4,a5,800067a6 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006710:	100014b7          	lui	s1,0x10001
    80006714:	47a1                	li	a5,8
    80006716:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    80006718:	6609                	lui	a2,0x2
    8000671a:	4581                	li	a1,0
    8000671c:	0001d517          	auipc	a0,0x1d
    80006720:	8e450513          	addi	a0,a0,-1820 # 80023000 <disk>
    80006724:	ffffa097          	auipc	ra,0xffffa
    80006728:	6ec080e7          	jalr	1772(ra) # 80000e10 <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    8000672c:	0001d717          	auipc	a4,0x1d
    80006730:	8d470713          	addi	a4,a4,-1836 # 80023000 <disk>
    80006734:	00c75793          	srli	a5,a4,0xc
    80006738:	2781                	sext.w	a5,a5
    8000673a:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    8000673c:	0001f797          	auipc	a5,0x1f
    80006740:	8c478793          	addi	a5,a5,-1852 # 80025000 <disk+0x2000>
    80006744:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    80006746:	0001d717          	auipc	a4,0x1d
    8000674a:	93a70713          	addi	a4,a4,-1734 # 80023080 <disk+0x80>
    8000674e:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    80006750:	0001e717          	auipc	a4,0x1e
    80006754:	8b070713          	addi	a4,a4,-1872 # 80024000 <disk+0x1000>
    80006758:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    8000675a:	4705                	li	a4,1
    8000675c:	00e78c23          	sb	a4,24(a5)
    80006760:	00e78ca3          	sb	a4,25(a5)
    80006764:	00e78d23          	sb	a4,26(a5)
    80006768:	00e78da3          	sb	a4,27(a5)
    8000676c:	00e78e23          	sb	a4,28(a5)
    80006770:	00e78ea3          	sb	a4,29(a5)
    80006774:	00e78f23          	sb	a4,30(a5)
    80006778:	00e78fa3          	sb	a4,31(a5)
}
    8000677c:	60e2                	ld	ra,24(sp)
    8000677e:	6442                	ld	s0,16(sp)
    80006780:	64a2                	ld	s1,8(sp)
    80006782:	6105                	addi	sp,sp,32
    80006784:	8082                	ret
    panic("could not find virtio disk");
    80006786:	00002517          	auipc	a0,0x2
    8000678a:	01a50513          	addi	a0,a0,26 # 800087a0 <syscalls+0x360>
    8000678e:	ffffa097          	auipc	ra,0xffffa
    80006792:	da2080e7          	jalr	-606(ra) # 80000530 <panic>
    panic("virtio disk has no queue 0");
    80006796:	00002517          	auipc	a0,0x2
    8000679a:	02a50513          	addi	a0,a0,42 # 800087c0 <syscalls+0x380>
    8000679e:	ffffa097          	auipc	ra,0xffffa
    800067a2:	d92080e7          	jalr	-622(ra) # 80000530 <panic>
    panic("virtio disk max queue too short");
    800067a6:	00002517          	auipc	a0,0x2
    800067aa:	03a50513          	addi	a0,a0,58 # 800087e0 <syscalls+0x3a0>
    800067ae:	ffffa097          	auipc	ra,0xffffa
    800067b2:	d82080e7          	jalr	-638(ra) # 80000530 <panic>

00000000800067b6 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800067b6:	7159                	addi	sp,sp,-112
    800067b8:	f486                	sd	ra,104(sp)
    800067ba:	f0a2                	sd	s0,96(sp)
    800067bc:	eca6                	sd	s1,88(sp)
    800067be:	e8ca                	sd	s2,80(sp)
    800067c0:	e4ce                	sd	s3,72(sp)
    800067c2:	e0d2                	sd	s4,64(sp)
    800067c4:	fc56                	sd	s5,56(sp)
    800067c6:	f85a                	sd	s6,48(sp)
    800067c8:	f45e                	sd	s7,40(sp)
    800067ca:	f062                	sd	s8,32(sp)
    800067cc:	ec66                	sd	s9,24(sp)
    800067ce:	e86a                	sd	s10,16(sp)
    800067d0:	1880                	addi	s0,sp,112
    800067d2:	892a                	mv	s2,a0
    800067d4:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800067d6:	00c52c83          	lw	s9,12(a0)
    800067da:	001c9c9b          	slliw	s9,s9,0x1
    800067de:	1c82                	slli	s9,s9,0x20
    800067e0:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    800067e4:	0001f517          	auipc	a0,0x1f
    800067e8:	94450513          	addi	a0,a0,-1724 # 80025128 <disk+0x2128>
    800067ec:	ffffa097          	auipc	ra,0xffffa
    800067f0:	528080e7          	jalr	1320(ra) # 80000d14 <acquire>
  for(int i = 0; i < 3; i++){
    800067f4:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    800067f6:	4c21                	li	s8,8
      disk.free[i] = 0;
    800067f8:	0001db97          	auipc	s7,0x1d
    800067fc:	808b8b93          	addi	s7,s7,-2040 # 80023000 <disk>
    80006800:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006802:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006804:	8a4e                	mv	s4,s3
    80006806:	a051                	j	8000688a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006808:	00fb86b3          	add	a3,s7,a5
    8000680c:	96da                	add	a3,a3,s6
    8000680e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006812:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006814:	0207c563          	bltz	a5,8000683e <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    80006818:	2485                	addiw	s1,s1,1
    8000681a:	0711                	addi	a4,a4,4
    8000681c:	25548063          	beq	s1,s5,80006a5c <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    80006820:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006822:	0001e697          	auipc	a3,0x1e
    80006826:	7f668693          	addi	a3,a3,2038 # 80025018 <disk+0x2018>
    8000682a:	87d2                	mv	a5,s4
    if(disk.free[i]){
    8000682c:	0006c583          	lbu	a1,0(a3)
    80006830:	fde1                	bnez	a1,80006808 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    80006832:	2785                	addiw	a5,a5,1
    80006834:	0685                	addi	a3,a3,1
    80006836:	ff879be3          	bne	a5,s8,8000682c <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    8000683a:	57fd                	li	a5,-1
    8000683c:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    8000683e:	02905a63          	blez	s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006842:	f9042503          	lw	a0,-112(s0)
    80006846:	00000097          	auipc	ra,0x0
    8000684a:	d90080e7          	jalr	-624(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    8000684e:	4785                	li	a5,1
    80006850:	0297d163          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006854:	f9442503          	lw	a0,-108(s0)
    80006858:	00000097          	auipc	ra,0x0
    8000685c:	d7e080e7          	jalr	-642(ra) # 800065d6 <free_desc>
      for(int j = 0; j < i; j++)
    80006860:	4789                	li	a5,2
    80006862:	0097d863          	bge	a5,s1,80006872 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    80006866:	f9842503          	lw	a0,-104(s0)
    8000686a:	00000097          	auipc	ra,0x0
    8000686e:	d6c080e7          	jalr	-660(ra) # 800065d6 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006872:	0001f597          	auipc	a1,0x1f
    80006876:	8b658593          	addi	a1,a1,-1866 # 80025128 <disk+0x2128>
    8000687a:	0001e517          	auipc	a0,0x1e
    8000687e:	79e50513          	addi	a0,a0,1950 # 80025018 <disk+0x2018>
    80006882:	ffffc097          	auipc	ra,0xffffc
    80006886:	2b6080e7          	jalr	694(ra) # 80002b38 <sleep>
  for(int i = 0; i < 3; i++){
    8000688a:	f9040713          	addi	a4,s0,-112
    8000688e:	84ce                	mv	s1,s3
    80006890:	bf41                	j	80006820 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006892:	20058713          	addi	a4,a1,512
    80006896:	00471693          	slli	a3,a4,0x4
    8000689a:	0001c717          	auipc	a4,0x1c
    8000689e:	76670713          	addi	a4,a4,1894 # 80023000 <disk>
    800068a2:	9736                	add	a4,a4,a3
    800068a4:	4685                	li	a3,1
    800068a6:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800068aa:	20058713          	addi	a4,a1,512
    800068ae:	00471693          	slli	a3,a4,0x4
    800068b2:	0001c717          	auipc	a4,0x1c
    800068b6:	74e70713          	addi	a4,a4,1870 # 80023000 <disk>
    800068ba:	9736                	add	a4,a4,a3
    800068bc:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    800068c0:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800068c4:	7679                	lui	a2,0xffffe
    800068c6:	963e                	add	a2,a2,a5
    800068c8:	0001e697          	auipc	a3,0x1e
    800068cc:	73868693          	addi	a3,a3,1848 # 80025000 <disk+0x2000>
    800068d0:	6298                	ld	a4,0(a3)
    800068d2:	9732                	add	a4,a4,a2
    800068d4:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800068d6:	6298                	ld	a4,0(a3)
    800068d8:	9732                	add	a4,a4,a2
    800068da:	4541                	li	a0,16
    800068dc:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800068de:	6298                	ld	a4,0(a3)
    800068e0:	9732                	add	a4,a4,a2
    800068e2:	4505                	li	a0,1
    800068e4:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    800068e8:	f9442703          	lw	a4,-108(s0)
    800068ec:	6288                	ld	a0,0(a3)
    800068ee:	962a                	add	a2,a2,a0
    800068f0:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7ffd800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    800068f4:	0712                	slli	a4,a4,0x4
    800068f6:	6290                	ld	a2,0(a3)
    800068f8:	963a                	add	a2,a2,a4
    800068fa:	05890513          	addi	a0,s2,88
    800068fe:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006900:	6294                	ld	a3,0(a3)
    80006902:	96ba                	add	a3,a3,a4
    80006904:	40000613          	li	a2,1024
    80006908:	c690                	sw	a2,8(a3)
  if(write)
    8000690a:	140d0063          	beqz	s10,80006a4a <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000690e:	0001e697          	auipc	a3,0x1e
    80006912:	6f26b683          	ld	a3,1778(a3) # 80025000 <disk+0x2000>
    80006916:	96ba                	add	a3,a3,a4
    80006918:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    8000691c:	0001c817          	auipc	a6,0x1c
    80006920:	6e480813          	addi	a6,a6,1764 # 80023000 <disk>
    80006924:	0001e517          	auipc	a0,0x1e
    80006928:	6dc50513          	addi	a0,a0,1756 # 80025000 <disk+0x2000>
    8000692c:	6114                	ld	a3,0(a0)
    8000692e:	96ba                	add	a3,a3,a4
    80006930:	00c6d603          	lhu	a2,12(a3)
    80006934:	00166613          	ori	a2,a2,1
    80006938:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    8000693c:	f9842683          	lw	a3,-104(s0)
    80006940:	6110                	ld	a2,0(a0)
    80006942:	9732                	add	a4,a4,a2
    80006944:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006948:	20058613          	addi	a2,a1,512
    8000694c:	0612                	slli	a2,a2,0x4
    8000694e:	9642                	add	a2,a2,a6
    80006950:	577d                	li	a4,-1
    80006952:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006956:	00469713          	slli	a4,a3,0x4
    8000695a:	6114                	ld	a3,0(a0)
    8000695c:	96ba                	add	a3,a3,a4
    8000695e:	03078793          	addi	a5,a5,48
    80006962:	97c2                	add	a5,a5,a6
    80006964:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    80006966:	611c                	ld	a5,0(a0)
    80006968:	97ba                	add	a5,a5,a4
    8000696a:	4685                	li	a3,1
    8000696c:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    8000696e:	611c                	ld	a5,0(a0)
    80006970:	97ba                	add	a5,a5,a4
    80006972:	4809                	li	a6,2
    80006974:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006978:	611c                	ld	a5,0(a0)
    8000697a:	973e                	add	a4,a4,a5
    8000697c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006980:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006984:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006988:	6518                	ld	a4,8(a0)
    8000698a:	00275783          	lhu	a5,2(a4)
    8000698e:	8b9d                	andi	a5,a5,7
    80006990:	0786                	slli	a5,a5,0x1
    80006992:	97ba                	add	a5,a5,a4
    80006994:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006998:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000699c:	6518                	ld	a4,8(a0)
    8000699e:	00275783          	lhu	a5,2(a4)
    800069a2:	2785                	addiw	a5,a5,1
    800069a4:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800069a8:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800069ac:	100017b7          	lui	a5,0x10001
    800069b0:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800069b4:	00492703          	lw	a4,4(s2)
    800069b8:	4785                	li	a5,1
    800069ba:	02f71163          	bne	a4,a5,800069dc <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    800069be:	0001e997          	auipc	s3,0x1e
    800069c2:	76a98993          	addi	s3,s3,1898 # 80025128 <disk+0x2128>
  while(b->disk == 1) {
    800069c6:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    800069c8:	85ce                	mv	a1,s3
    800069ca:	854a                	mv	a0,s2
    800069cc:	ffffc097          	auipc	ra,0xffffc
    800069d0:	16c080e7          	jalr	364(ra) # 80002b38 <sleep>
  while(b->disk == 1) {
    800069d4:	00492783          	lw	a5,4(s2)
    800069d8:	fe9788e3          	beq	a5,s1,800069c8 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    800069dc:	f9042903          	lw	s2,-112(s0)
    800069e0:	20090793          	addi	a5,s2,512
    800069e4:	00479713          	slli	a4,a5,0x4
    800069e8:	0001c797          	auipc	a5,0x1c
    800069ec:	61878793          	addi	a5,a5,1560 # 80023000 <disk>
    800069f0:	97ba                	add	a5,a5,a4
    800069f2:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    800069f6:	0001e997          	auipc	s3,0x1e
    800069fa:	60a98993          	addi	s3,s3,1546 # 80025000 <disk+0x2000>
    800069fe:	00491713          	slli	a4,s2,0x4
    80006a02:	0009b783          	ld	a5,0(s3)
    80006a06:	97ba                	add	a5,a5,a4
    80006a08:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006a0c:	854a                	mv	a0,s2
    80006a0e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006a12:	00000097          	auipc	ra,0x0
    80006a16:	bc4080e7          	jalr	-1084(ra) # 800065d6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006a1a:	8885                	andi	s1,s1,1
    80006a1c:	f0ed                	bnez	s1,800069fe <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006a1e:	0001e517          	auipc	a0,0x1e
    80006a22:	70a50513          	addi	a0,a0,1802 # 80025128 <disk+0x2128>
    80006a26:	ffffa097          	auipc	ra,0xffffa
    80006a2a:	3a2080e7          	jalr	930(ra) # 80000dc8 <release>
}
    80006a2e:	70a6                	ld	ra,104(sp)
    80006a30:	7406                	ld	s0,96(sp)
    80006a32:	64e6                	ld	s1,88(sp)
    80006a34:	6946                	ld	s2,80(sp)
    80006a36:	69a6                	ld	s3,72(sp)
    80006a38:	6a06                	ld	s4,64(sp)
    80006a3a:	7ae2                	ld	s5,56(sp)
    80006a3c:	7b42                	ld	s6,48(sp)
    80006a3e:	7ba2                	ld	s7,40(sp)
    80006a40:	7c02                	ld	s8,32(sp)
    80006a42:	6ce2                	ld	s9,24(sp)
    80006a44:	6d42                	ld	s10,16(sp)
    80006a46:	6165                	addi	sp,sp,112
    80006a48:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006a4a:	0001e697          	auipc	a3,0x1e
    80006a4e:	5b66b683          	ld	a3,1462(a3) # 80025000 <disk+0x2000>
    80006a52:	96ba                	add	a3,a3,a4
    80006a54:	4609                	li	a2,2
    80006a56:	00c69623          	sh	a2,12(a3)
    80006a5a:	b5c9                	j	8000691c <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006a5c:	f9042583          	lw	a1,-112(s0)
    80006a60:	20058793          	addi	a5,a1,512
    80006a64:	0792                	slli	a5,a5,0x4
    80006a66:	0001c517          	auipc	a0,0x1c
    80006a6a:	64250513          	addi	a0,a0,1602 # 800230a8 <disk+0xa8>
    80006a6e:	953e                	add	a0,a0,a5
  if(write)
    80006a70:	e20d11e3          	bnez	s10,80006892 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006a74:	20058713          	addi	a4,a1,512
    80006a78:	00471693          	slli	a3,a4,0x4
    80006a7c:	0001c717          	auipc	a4,0x1c
    80006a80:	58470713          	addi	a4,a4,1412 # 80023000 <disk>
    80006a84:	9736                	add	a4,a4,a3
    80006a86:	0a072423          	sw	zero,168(a4)
    80006a8a:	b505                	j	800068aa <virtio_disk_rw+0xf4>

0000000080006a8c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006a8c:	1101                	addi	sp,sp,-32
    80006a8e:	ec06                	sd	ra,24(sp)
    80006a90:	e822                	sd	s0,16(sp)
    80006a92:	e426                	sd	s1,8(sp)
    80006a94:	e04a                	sd	s2,0(sp)
    80006a96:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006a98:	0001e517          	auipc	a0,0x1e
    80006a9c:	69050513          	addi	a0,a0,1680 # 80025128 <disk+0x2128>
    80006aa0:	ffffa097          	auipc	ra,0xffffa
    80006aa4:	274080e7          	jalr	628(ra) # 80000d14 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006aa8:	10001737          	lui	a4,0x10001
    80006aac:	533c                	lw	a5,96(a4)
    80006aae:	8b8d                	andi	a5,a5,3
    80006ab0:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006ab2:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006ab6:	0001e797          	auipc	a5,0x1e
    80006aba:	54a78793          	addi	a5,a5,1354 # 80025000 <disk+0x2000>
    80006abe:	6b94                	ld	a3,16(a5)
    80006ac0:	0207d703          	lhu	a4,32(a5)
    80006ac4:	0026d783          	lhu	a5,2(a3)
    80006ac8:	06f70163          	beq	a4,a5,80006b2a <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006acc:	0001c917          	auipc	s2,0x1c
    80006ad0:	53490913          	addi	s2,s2,1332 # 80023000 <disk>
    80006ad4:	0001e497          	auipc	s1,0x1e
    80006ad8:	52c48493          	addi	s1,s1,1324 # 80025000 <disk+0x2000>
    __sync_synchronize();
    80006adc:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006ae0:	6898                	ld	a4,16(s1)
    80006ae2:	0204d783          	lhu	a5,32(s1)
    80006ae6:	8b9d                	andi	a5,a5,7
    80006ae8:	078e                	slli	a5,a5,0x3
    80006aea:	97ba                	add	a5,a5,a4
    80006aec:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006aee:	20078713          	addi	a4,a5,512
    80006af2:	0712                	slli	a4,a4,0x4
    80006af4:	974a                	add	a4,a4,s2
    80006af6:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    80006afa:	e731                	bnez	a4,80006b46 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006afc:	20078793          	addi	a5,a5,512
    80006b00:	0792                	slli	a5,a5,0x4
    80006b02:	97ca                	add	a5,a5,s2
    80006b04:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006b06:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006b0a:	ffffc097          	auipc	ra,0xffffc
    80006b0e:	1b4080e7          	jalr	436(ra) # 80002cbe <wakeup>

    disk.used_idx += 1;
    80006b12:	0204d783          	lhu	a5,32(s1)
    80006b16:	2785                	addiw	a5,a5,1
    80006b18:	17c2                	slli	a5,a5,0x30
    80006b1a:	93c1                	srli	a5,a5,0x30
    80006b1c:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006b20:	6898                	ld	a4,16(s1)
    80006b22:	00275703          	lhu	a4,2(a4)
    80006b26:	faf71be3          	bne	a4,a5,80006adc <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    80006b2a:	0001e517          	auipc	a0,0x1e
    80006b2e:	5fe50513          	addi	a0,a0,1534 # 80025128 <disk+0x2128>
    80006b32:	ffffa097          	auipc	ra,0xffffa
    80006b36:	296080e7          	jalr	662(ra) # 80000dc8 <release>
}
    80006b3a:	60e2                	ld	ra,24(sp)
    80006b3c:	6442                	ld	s0,16(sp)
    80006b3e:	64a2                	ld	s1,8(sp)
    80006b40:	6902                	ld	s2,0(sp)
    80006b42:	6105                	addi	sp,sp,32
    80006b44:	8082                	ret
      panic("virtio_disk_intr status");
    80006b46:	00002517          	auipc	a0,0x2
    80006b4a:	cba50513          	addi	a0,a0,-838 # 80008800 <syscalls+0x3c0>
    80006b4e:	ffffa097          	auipc	ra,0xffffa
    80006b52:	9e2080e7          	jalr	-1566(ra) # 80000530 <panic>
	...

0000000080007000 <_trampoline>:
        # mapped into user space, at TRAPFRAME.
        #
        
	# swap a0 and sscratch
        # so that a0 is TRAPFRAME
        csrrw a0, sscratch, a0
    80007000:	14051573          	csrrw	a0,sscratch,a0

        # save the user registers in TRAPFRAME
        sd ra, 40(a0)
    80007004:	02153423          	sd	ra,40(a0)
        sd sp, 48(a0)
    80007008:	02253823          	sd	sp,48(a0)
        sd gp, 56(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
        sd tp, 64(a0)
    80007010:	04453023          	sd	tp,64(a0)
        sd t0, 72(a0)
    80007014:	04553423          	sd	t0,72(a0)
        sd t1, 80(a0)
    80007018:	04653823          	sd	t1,80(a0)
        sd t2, 88(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
        sd s0, 96(a0)
    80007020:	f120                	sd	s0,96(a0)
        sd s1, 104(a0)
    80007022:	f524                	sd	s1,104(a0)
        sd a1, 120(a0)
    80007024:	fd2c                	sd	a1,120(a0)
        sd a2, 128(a0)
    80007026:	e150                	sd	a2,128(a0)
        sd a3, 136(a0)
    80007028:	e554                	sd	a3,136(a0)
        sd a4, 144(a0)
    8000702a:	e958                	sd	a4,144(a0)
        sd a5, 152(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
        sd a6, 160(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
        sd a7, 168(a0)
    80007032:	0b153423          	sd	a7,168(a0)
        sd s2, 176(a0)
    80007036:	0b253823          	sd	s2,176(a0)
        sd s3, 184(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
        sd s4, 192(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
        sd s5, 200(a0)
    80007042:	0d553423          	sd	s5,200(a0)
        sd s6, 208(a0)
    80007046:	0d653823          	sd	s6,208(a0)
        sd s7, 216(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
        sd s8, 224(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
        sd s9, 232(a0)
    80007052:	0f953423          	sd	s9,232(a0)
        sd s10, 240(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
        sd s11, 248(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
        sd t3, 256(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
        sd t4, 264(a0)
    80007062:	11d53423          	sd	t4,264(a0)
        sd t5, 272(a0)
    80007066:	11e53823          	sd	t5,272(a0)
        sd t6, 280(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)

	# save the user a0 in p->trapframe->a0
        csrr t0, sscratch
    8000706e:	140022f3          	csrr	t0,sscratch
        sd t0, 112(a0)
    80007072:	06553823          	sd	t0,112(a0)

        # restore kernel stack pointer from p->trapframe->kernel_sp
        ld sp, 8(a0)
    80007076:	00853103          	ld	sp,8(a0)

        # make tp hold the current hartid, from p->trapframe->kernel_hartid
        ld tp, 32(a0)
    8000707a:	02053203          	ld	tp,32(a0)

        # load the address of usertrap(), p->trapframe->kernel_trap
        ld t0, 16(a0)
    8000707e:	01053283          	ld	t0,16(a0)

        # restore kernel page table from p->trapframe->kernel_satp
        ld t1, 0(a0)
    80007082:	00053303          	ld	t1,0(a0)
        csrw satp, t1
    80007086:	18031073          	csrw	satp,t1
        sfence.vma zero, zero
    8000708a:	12000073          	sfence.vma

        # a0 is no longer valid, since the kernel page
        # table does not specially map p->tf.

        # jump to usertrap(), which does not return
        jr t0
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
        # usertrapret() calls here.
        # a0: TRAPFRAME, in user page table.
        # a1: user page table, for satp.

        # switch to the user page table.
        csrw satp, a1
    80007090:	18059073          	csrw	satp,a1
        sfence.vma zero, zero
    80007094:	12000073          	sfence.vma

        # put the saved user a0 in sscratch, so we
        # can swap it with our a0 (TRAPFRAME) in the last step.
        ld t0, 112(a0)
    80007098:	07053283          	ld	t0,112(a0)
        csrw sscratch, t0
    8000709c:	14029073          	csrw	sscratch,t0

        # restore all but a0 from TRAPFRAME
        ld ra, 40(a0)
    800070a0:	02853083          	ld	ra,40(a0)
        ld sp, 48(a0)
    800070a4:	03053103          	ld	sp,48(a0)
        ld gp, 56(a0)
    800070a8:	03853183          	ld	gp,56(a0)
        ld tp, 64(a0)
    800070ac:	04053203          	ld	tp,64(a0)
        ld t0, 72(a0)
    800070b0:	04853283          	ld	t0,72(a0)
        ld t1, 80(a0)
    800070b4:	05053303          	ld	t1,80(a0)
        ld t2, 88(a0)
    800070b8:	05853383          	ld	t2,88(a0)
        ld s0, 96(a0)
    800070bc:	7120                	ld	s0,96(a0)
        ld s1, 104(a0)
    800070be:	7524                	ld	s1,104(a0)
        ld a1, 120(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
        ld a2, 128(a0)
    800070c2:	6150                	ld	a2,128(a0)
        ld a3, 136(a0)
    800070c4:	6554                	ld	a3,136(a0)
        ld a4, 144(a0)
    800070c6:	6958                	ld	a4,144(a0)
        ld a5, 152(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
        ld a6, 160(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
        ld a7, 168(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
        ld s2, 176(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
        ld s3, 184(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
        ld s4, 192(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
        ld s5, 200(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
        ld s6, 208(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
        ld s7, 216(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
        ld s8, 224(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
        ld s9, 232(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
        ld s10, 240(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
        ld s11, 248(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
        ld t3, 256(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
        ld t4, 264(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
        ld t5, 272(a0)
    80007102:	11053f03          	ld	t5,272(a0)
        ld t6, 280(a0)
    80007106:	11853f83          	ld	t6,280(a0)

	# restore user a0, and save TRAPFRAME in sscratch
        csrrw a0, sscratch, a0
    8000710a:	14051573          	csrrw	a0,sscratch,a0
        
        # return to user mode and user pc.
        # usertrapret() set up sstatus and sepc.
        sret
    8000710e:	10200073          	sret
	...
