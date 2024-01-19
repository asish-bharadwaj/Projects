
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
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
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	02e78793          	addi	a5,a5,46 # 80006090 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc07f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	502080e7          	jalr	1282(ra) # 8000262c <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	2ae080e7          	jalr	686(ra) # 80002476 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	fec080e7          	jalr	-20(ra) # 800021c2 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	3c4080e7          	jalr	964(ra) # 800025d6 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	390080e7          	jalr	912(ra) # 80002682 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	de0080e7          	jalr	-544(ra) # 80002226 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	17078793          	addi	a5,a5,368 # 800215e8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	992080e7          	jalr	-1646(ra) # 80002226 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	8a4080e7          	jalr	-1884(ra) # 800021c2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00022797          	auipc	a5,0x22
    80000a00:	d8478793          	addi	a5,a5,-636 # 80022780 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00022517          	auipc	a0,0x22
    80000ad2:	cb250513          	addi	a0,a0,-846 # 80022780 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdc881>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	ae4080e7          	jalr	-1308(ra) # 800029a2 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	20a080e7          	jalr	522(ra) # 800060d0 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	00e080e7          	jalr	14(ra) # 80001edc <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	a44080e7          	jalr	-1468(ra) # 8000297a <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	a64080e7          	jalr	-1436(ra) # 800029a2 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	174080e7          	jalr	372(ra) # 800060ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	182080e7          	jalr	386(ra) # 800060d0 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	2f8080e7          	jalr	760(ra) # 8000324e <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	998080e7          	jalr	-1640(ra) # 800038f6 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	93e080e7          	jalr	-1730(ra) # 800048a4 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	26a080e7          	jalr	618(ra) # 800061d8 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d48080e7          	jalr	-696(ra) # 80001cbe <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdc877>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdc880>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00016a17          	auipc	s4,0x16
    8000186a:	b3aa0a13          	addi	s4,s4,-1222 # 800173a0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    800018a0:	19048493          	addi	s1,s1,400
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00016997          	auipc	s3,0x16
    80001936:	a6e98993          	addi	s3,s3,-1426 # 800173a0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	19048493          	addi	s1,s1,400
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first)
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e647a783          	lw	a5,-412(a5) # 80008860 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	fb4080e7          	jalr	-76(ra) # 800029ba <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e407a523          	sw	zero,-438(a5) # 80008860 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	e56080e7          	jalr	-426(ra) # 80003876 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e1c78793          	addi	a5,a5,-484 # 80008864 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	05893683          	ld	a3,88(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001b6a:	6d28                	ld	a0,88(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0404bc23          	sd	zero,88(s1)
  if (p->pagetable)
    80001b7a:	68a8                	ld	a0,80(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	64ac                	ld	a1,72(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001b8c:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001b98:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3de48493          	addi	s1,s1,990 # 80010fa0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	7d690913          	addi	s2,s2,2006 # 800173a0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001bea:	19048493          	addi	s1,s1,400
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a071                	j	80001c80 <allocproc+0xca>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	eca8                	sd	a0,88(s1)
    80001c10:	cd3d                	beqz	a0,80001c8e <allocproc+0xd8>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c20:	c159                	beqz	a0,80001ca6 <allocproc+0xf0>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06048513          	addi	a0,s1,96
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	60bc                	ld	a5,64(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c46:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c4a:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c4e:	00007797          	auipc	a5,0x7
    80001c52:	cb27a783          	lw	a5,-846(a5) # 80008900 <ticks>
    80001c56:	16f4a623          	sw	a5,364(s1)
  p->RBI = 25;
    80001c5a:	47e5                	li	a5,25
    80001c5c:	16f4ae23          	sw	a5,380(s1)
  p->sp = 50;
    80001c60:	03200793          	li	a5,50
    80001c64:	16f4aa23          	sw	a5,372(s1)
  p->Rtime = 0;
    80001c68:	1804a223          	sw	zero,388(s1)
  p->wtime = 0;
    80001c6c:	1804a023          	sw	zero,384(s1)
  p->state = 0;
    80001c70:	0004ac23          	sw	zero,24(s1)
  p->sched = 0;
    80001c74:	1804a623          	sw	zero,396(s1)
  p->dp = 75;
    80001c78:	04b00793          	li	a5,75
    80001c7c:	16f4ac23          	sw	a5,376(s1)
}
    80001c80:	8526                	mv	a0,s1
    80001c82:	60e2                	ld	ra,24(sp)
    80001c84:	6442                	ld	s0,16(sp)
    80001c86:	64a2                	ld	s1,8(sp)
    80001c88:	6902                	ld	s2,0(sp)
    80001c8a:	6105                	addi	sp,sp,32
    80001c8c:	8082                	ret
    freeproc(p);
    80001c8e:	8526                	mv	a0,s1
    80001c90:	00000097          	auipc	ra,0x0
    80001c94:	ece080e7          	jalr	-306(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c98:	8526                	mv	a0,s1
    80001c9a:	fffff097          	auipc	ra,0xfffff
    80001c9e:	ff0080e7          	jalr	-16(ra) # 80000c8a <release>
    return 0;
    80001ca2:	84ca                	mv	s1,s2
    80001ca4:	bff1                	j	80001c80 <allocproc+0xca>
    freeproc(p);
    80001ca6:	8526                	mv	a0,s1
    80001ca8:	00000097          	auipc	ra,0x0
    80001cac:	eb6080e7          	jalr	-330(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cb0:	8526                	mv	a0,s1
    80001cb2:	fffff097          	auipc	ra,0xfffff
    80001cb6:	fd8080e7          	jalr	-40(ra) # 80000c8a <release>
    return 0;
    80001cba:	84ca                	mv	s1,s2
    80001cbc:	b7d1                	j	80001c80 <allocproc+0xca>

0000000080001cbe <userinit>:
{
    80001cbe:	1101                	addi	sp,sp,-32
    80001cc0:	ec06                	sd	ra,24(sp)
    80001cc2:	e822                	sd	s0,16(sp)
    80001cc4:	e426                	sd	s1,8(sp)
    80001cc6:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cc8:	00000097          	auipc	ra,0x0
    80001ccc:	eee080e7          	jalr	-274(ra) # 80001bb6 <allocproc>
    80001cd0:	84aa                	mv	s1,a0
  initproc = p;
    80001cd2:	00007797          	auipc	a5,0x7
    80001cd6:	c2a7b323          	sd	a0,-986(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cda:	03400613          	li	a2,52
    80001cde:	00007597          	auipc	a1,0x7
    80001ce2:	b9258593          	addi	a1,a1,-1134 # 80008870 <initcode>
    80001ce6:	6928                	ld	a0,80(a0)
    80001ce8:	fffff097          	auipc	ra,0xfffff
    80001cec:	66e080e7          	jalr	1646(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cf0:	6785                	lui	a5,0x1
    80001cf2:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001cf4:	6cb8                	ld	a4,88(s1)
    80001cf6:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001cfa:	6cb8                	ld	a4,88(s1)
    80001cfc:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cfe:	4641                	li	a2,16
    80001d00:	00006597          	auipc	a1,0x6
    80001d04:	50058593          	addi	a1,a1,1280 # 80008200 <digits+0x1c0>
    80001d08:	15848513          	addi	a0,s1,344
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	110080e7          	jalr	272(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d14:	00006517          	auipc	a0,0x6
    80001d18:	4fc50513          	addi	a0,a0,1276 # 80008210 <digits+0x1d0>
    80001d1c:	00002097          	auipc	ra,0x2
    80001d20:	584080e7          	jalr	1412(ra) # 800042a0 <namei>
    80001d24:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d28:	478d                	li	a5,3
    80001d2a:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	fffff097          	auipc	ra,0xfffff
    80001d32:	f5c080e7          	jalr	-164(ra) # 80000c8a <release>
}
    80001d36:	60e2                	ld	ra,24(sp)
    80001d38:	6442                	ld	s0,16(sp)
    80001d3a:	64a2                	ld	s1,8(sp)
    80001d3c:	6105                	addi	sp,sp,32
    80001d3e:	8082                	ret

0000000080001d40 <growproc>:
{
    80001d40:	1101                	addi	sp,sp,-32
    80001d42:	ec06                	sd	ra,24(sp)
    80001d44:	e822                	sd	s0,16(sp)
    80001d46:	e426                	sd	s1,8(sp)
    80001d48:	e04a                	sd	s2,0(sp)
    80001d4a:	1000                	addi	s0,sp,32
    80001d4c:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d4e:	00000097          	auipc	ra,0x0
    80001d52:	c5e080e7          	jalr	-930(ra) # 800019ac <myproc>
    80001d56:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d58:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d5a:	01204c63          	bgtz	s2,80001d72 <growproc+0x32>
  else if (n < 0)
    80001d5e:	02094663          	bltz	s2,80001d8a <growproc+0x4a>
  p->sz = sz;
    80001d62:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d64:	4501                	li	a0,0
}
    80001d66:	60e2                	ld	ra,24(sp)
    80001d68:	6442                	ld	s0,16(sp)
    80001d6a:	64a2                	ld	s1,8(sp)
    80001d6c:	6902                	ld	s2,0(sp)
    80001d6e:	6105                	addi	sp,sp,32
    80001d70:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d72:	4691                	li	a3,4
    80001d74:	00b90633          	add	a2,s2,a1
    80001d78:	6928                	ld	a0,80(a0)
    80001d7a:	fffff097          	auipc	ra,0xfffff
    80001d7e:	696080e7          	jalr	1686(ra) # 80001410 <uvmalloc>
    80001d82:	85aa                	mv	a1,a0
    80001d84:	fd79                	bnez	a0,80001d62 <growproc+0x22>
      return -1;
    80001d86:	557d                	li	a0,-1
    80001d88:	bff9                	j	80001d66 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d8a:	00b90633          	add	a2,s2,a1
    80001d8e:	6928                	ld	a0,80(a0)
    80001d90:	fffff097          	auipc	ra,0xfffff
    80001d94:	638080e7          	jalr	1592(ra) # 800013c8 <uvmdealloc>
    80001d98:	85aa                	mv	a1,a0
    80001d9a:	b7e1                	j	80001d62 <growproc+0x22>

0000000080001d9c <fork>:
{
    80001d9c:	7139                	addi	sp,sp,-64
    80001d9e:	fc06                	sd	ra,56(sp)
    80001da0:	f822                	sd	s0,48(sp)
    80001da2:	f426                	sd	s1,40(sp)
    80001da4:	f04a                	sd	s2,32(sp)
    80001da6:	ec4e                	sd	s3,24(sp)
    80001da8:	e852                	sd	s4,16(sp)
    80001daa:	e456                	sd	s5,8(sp)
    80001dac:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dae:	00000097          	auipc	ra,0x0
    80001db2:	bfe080e7          	jalr	-1026(ra) # 800019ac <myproc>
    80001db6:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	dfe080e7          	jalr	-514(ra) # 80001bb6 <allocproc>
    80001dc0:	10050c63          	beqz	a0,80001ed8 <fork+0x13c>
    80001dc4:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dc6:	048ab603          	ld	a2,72(s5)
    80001dca:	692c                	ld	a1,80(a0)
    80001dcc:	050ab503          	ld	a0,80(s5)
    80001dd0:	fffff097          	auipc	ra,0xfffff
    80001dd4:	798080e7          	jalr	1944(ra) # 80001568 <uvmcopy>
    80001dd8:	04054863          	bltz	a0,80001e28 <fork+0x8c>
  np->sz = p->sz;
    80001ddc:	048ab783          	ld	a5,72(s5)
    80001de0:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001de4:	058ab683          	ld	a3,88(s5)
    80001de8:	87b6                	mv	a5,a3
    80001dea:	058a3703          	ld	a4,88(s4)
    80001dee:	12068693          	addi	a3,a3,288
    80001df2:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001df6:	6788                	ld	a0,8(a5)
    80001df8:	6b8c                	ld	a1,16(a5)
    80001dfa:	6f90                	ld	a2,24(a5)
    80001dfc:	01073023          	sd	a6,0(a4)
    80001e00:	e708                	sd	a0,8(a4)
    80001e02:	eb0c                	sd	a1,16(a4)
    80001e04:	ef10                	sd	a2,24(a4)
    80001e06:	02078793          	addi	a5,a5,32
    80001e0a:	02070713          	addi	a4,a4,32
    80001e0e:	fed792e3          	bne	a5,a3,80001df2 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e12:	058a3783          	ld	a5,88(s4)
    80001e16:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e1a:	0d0a8493          	addi	s1,s5,208
    80001e1e:	0d0a0913          	addi	s2,s4,208
    80001e22:	150a8993          	addi	s3,s5,336
    80001e26:	a00d                	j	80001e48 <fork+0xac>
    freeproc(np);
    80001e28:	8552                	mv	a0,s4
    80001e2a:	00000097          	auipc	ra,0x0
    80001e2e:	d34080e7          	jalr	-716(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e32:	8552                	mv	a0,s4
    80001e34:	fffff097          	auipc	ra,0xfffff
    80001e38:	e56080e7          	jalr	-426(ra) # 80000c8a <release>
    return -1;
    80001e3c:	597d                	li	s2,-1
    80001e3e:	a059                	j	80001ec4 <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e40:	04a1                	addi	s1,s1,8
    80001e42:	0921                	addi	s2,s2,8
    80001e44:	01348b63          	beq	s1,s3,80001e5a <fork+0xbe>
    if (p->ofile[i])
    80001e48:	6088                	ld	a0,0(s1)
    80001e4a:	d97d                	beqz	a0,80001e40 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e4c:	00003097          	auipc	ra,0x3
    80001e50:	aea080e7          	jalr	-1302(ra) # 80004936 <filedup>
    80001e54:	00a93023          	sd	a0,0(s2)
    80001e58:	b7e5                	j	80001e40 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e5a:	150ab503          	ld	a0,336(s5)
    80001e5e:	00002097          	auipc	ra,0x2
    80001e62:	c58080e7          	jalr	-936(ra) # 80003ab6 <idup>
    80001e66:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e6a:	4641                	li	a2,16
    80001e6c:	158a8593          	addi	a1,s5,344
    80001e70:	158a0513          	addi	a0,s4,344
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	fa8080e7          	jalr	-88(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e7c:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e80:	8552                	mv	a0,s4
    80001e82:	fffff097          	auipc	ra,0xfffff
    80001e86:	e08080e7          	jalr	-504(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e8a:	0000f497          	auipc	s1,0xf
    80001e8e:	cfe48493          	addi	s1,s1,-770 # 80010b88 <wait_lock>
    80001e92:	8526                	mv	a0,s1
    80001e94:	fffff097          	auipc	ra,0xfffff
    80001e98:	d42080e7          	jalr	-702(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e9c:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ea0:	8526                	mv	a0,s1
    80001ea2:	fffff097          	auipc	ra,0xfffff
    80001ea6:	de8080e7          	jalr	-536(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001eaa:	8552                	mv	a0,s4
    80001eac:	fffff097          	auipc	ra,0xfffff
    80001eb0:	d2a080e7          	jalr	-726(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001eb4:	478d                	li	a5,3
    80001eb6:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001eba:	8552                	mv	a0,s4
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	dce080e7          	jalr	-562(ra) # 80000c8a <release>
}
    80001ec4:	854a                	mv	a0,s2
    80001ec6:	70e2                	ld	ra,56(sp)
    80001ec8:	7442                	ld	s0,48(sp)
    80001eca:	74a2                	ld	s1,40(sp)
    80001ecc:	7902                	ld	s2,32(sp)
    80001ece:	69e2                	ld	s3,24(sp)
    80001ed0:	6a42                	ld	s4,16(sp)
    80001ed2:	6aa2                	ld	s5,8(sp)
    80001ed4:	6121                	addi	sp,sp,64
    80001ed6:	8082                	ret
    return -1;
    80001ed8:	597d                	li	s2,-1
    80001eda:	b7ed                	j	80001ec4 <fork+0x128>

0000000080001edc <scheduler>:
{
    80001edc:	7175                	addi	sp,sp,-144
    80001ede:	e506                	sd	ra,136(sp)
    80001ee0:	e122                	sd	s0,128(sp)
    80001ee2:	fca6                	sd	s1,120(sp)
    80001ee4:	f8ca                	sd	s2,112(sp)
    80001ee6:	f4ce                	sd	s3,104(sp)
    80001ee8:	f0d2                	sd	s4,96(sp)
    80001eea:	ecd6                	sd	s5,88(sp)
    80001eec:	e8da                	sd	s6,80(sp)
    80001eee:	e4de                	sd	s7,72(sp)
    80001ef0:	e0e2                	sd	s8,64(sp)
    80001ef2:	fc66                	sd	s9,56(sp)
    80001ef4:	f86a                	sd	s10,48(sp)
    80001ef6:	f46e                	sd	s11,40(sp)
    80001ef8:	0900                	addi	s0,sp,144
  printf("pbs\n");
    80001efa:	00006517          	auipc	a0,0x6
    80001efe:	31e50513          	addi	a0,a0,798 # 80008218 <digits+0x1d8>
    80001f02:	ffffe097          	auipc	ra,0xffffe
    80001f06:	688080e7          	jalr	1672(ra) # 8000058a <printf>
    80001f0a:	8792                	mv	a5,tp
  int id = r_tp();
    80001f0c:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f0e:	00779693          	slli	a3,a5,0x7
    80001f12:	0000f717          	auipc	a4,0xf
    80001f16:	c5e70713          	addi	a4,a4,-930 # 80010b70 <pid_lock>
    80001f1a:	9736                	add	a4,a4,a3
    80001f1c:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f20:	0000f717          	auipc	a4,0xf
    80001f24:	c8870713          	addi	a4,a4,-888 # 80010ba8 <cpus+0x8>
    80001f28:	9736                	add	a4,a4,a3
    80001f2a:	f6e43c23          	sd	a4,-136(s0)
    uint min_dp = 101, min_sched = 100000000, min_ctime = 1000000000;
    80001f2e:	3b9ad737          	lui	a4,0x3b9ad
    80001f32:	a0070713          	addi	a4,a4,-1536 # 3b9aca00 <_entry-0x44653600>
    80001f36:	f8e43423          	sd	a4,-120(s0)
    80001f3a:	05f5e737          	lui	a4,0x5f5e
    80001f3e:	10070713          	addi	a4,a4,256 # 5f5e100 <_entry-0x7a0a1f00>
    80001f42:	f8e43023          	sd	a4,-128(s0)
      else if(dp == min_dp && p->state == RUNNABLE){
    80001f46:	4a0d                	li	s4,3
    for(p = proc; p < &proc[NPROC]; p++){
    80001f48:	00015997          	auipc	s3,0x15
    80001f4c:	45898993          	addi	s3,s3,1112 # 800173a0 <tickslock>
        c->proc = p;
    80001f50:	0000fd97          	auipc	s11,0xf
    80001f54:	c20d8d93          	addi	s11,s11,-992 # 80010b70 <pid_lock>
    80001f58:	9db6                	add	s11,s11,a3
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f5a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f5e:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f62:	10079073          	csrw	sstatus,a5
    uint min_dp = 101, min_sched = 100000000, min_ctime = 1000000000;
    80001f66:	f8843d03          	ld	s10,-120(s0)
    80001f6a:	f8043c83          	ld	s9,-128(s0)
    80001f6e:	06500913          	li	s2,101
    for(p = proc; p < &proc[NPROC]; p++){
    80001f72:	0000f497          	auipc	s1,0xf
    80001f76:	02e48493          	addi	s1,s1,46 # 80010fa0 <proc>
        rbi = 0;
    80001f7a:	4b01                	li	s6,0
        rbi = (((3*p->Rtime - p->stime - p->wtime)*50) / (p->Rtime + p->wtime + p->stime + 1));
    80001f7c:	03200c13          	li	s8,50
    80001f80:	06400a93          	li	s5,100
    80001f84:	06400b93          	li	s7,100
    80001f88:	a839                	j	80001fa6 <scheduler+0xca>
      else if(dp == min_dp && p->state == RUNNABLE){
    80001f8a:	01271563          	bne	a4,s2,80001f94 <scheduler+0xb8>
    80001f8e:	4c9c                	lw	a5,24(s1)
    80001f90:	09478263          	beq	a5,s4,80002014 <scheduler+0x138>
      release(&p->lock);
    80001f94:	8526                	mv	a0,s1
    80001f96:	fffff097          	auipc	ra,0xfffff
    80001f9a:	cf4080e7          	jalr	-780(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++){
    80001f9e:	19048493          	addi	s1,s1,400
    80001fa2:	09348d63          	beq	s1,s3,8000203c <scheduler+0x160>
      acquire(&p->lock);
    80001fa6:	8526                	mv	a0,s1
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	c2e080e7          	jalr	-978(ra) # 80000bd6 <acquire>
      if(3 * p->Rtime < p->stime + p->wtime){
    80001fb0:	1844a703          	lw	a4,388(s1)
    80001fb4:	0017179b          	slliw	a5,a4,0x1
    80001fb8:	9fb9                	addw	a5,a5,a4
    80001fba:	0007851b          	sext.w	a0,a5
    80001fbe:	1884a583          	lw	a1,392(s1)
    80001fc2:	1804a603          	lw	a2,384(s1)
    80001fc6:	00c5883b          	addw	a6,a1,a2
        rbi = 0;
    80001fca:	86da                	mv	a3,s6
      if(3 * p->Rtime < p->stime + p->wtime){
    80001fcc:	01056b63          	bltu	a0,a6,80001fe2 <scheduler+0x106>
        rbi = (((3*p->Rtime - p->stime - p->wtime)*50) / (p->Rtime + p->wtime + p->stime + 1));
    80001fd0:	9f8d                	subw	a5,a5,a1
    80001fd2:	9f91                	subw	a5,a5,a2
    80001fd4:	038787bb          	mulw	a5,a5,s8
    80001fd8:	9f2d                	addw	a4,a4,a1
    80001fda:	2705                	addiw	a4,a4,1
    80001fdc:	9f31                	addw	a4,a4,a2
    80001fde:	02e7d6bb          	divuw	a3,a5,a4
      p->RBI = rbi;
    80001fe2:	16d4ae23          	sw	a3,380(s1)
      dp = p->sp + p->RBI;
    80001fe6:	1744a783          	lw	a5,372(s1)
    80001fea:	9fb5                	addw	a5,a5,a3
    80001fec:	0007871b          	sext.w	a4,a5
    80001ff0:	00eaf363          	bgeu	s5,a4,80001ff6 <scheduler+0x11a>
    80001ff4:	87de                	mv	a5,s7
    80001ff6:	0007871b          	sext.w	a4,a5
      p->dp = dp;
    80001ffa:	16f4ac23          	sw	a5,376(s1)
      if(dp < min_dp && p->state == RUNNABLE){
    80001ffe:	f92776e3          	bgeu	a4,s2,80001f8a <scheduler+0xae>
    80002002:	4c9c                	lw	a5,24(s1)
    80002004:	f94798e3          	bne	a5,s4,80001f94 <scheduler+0xb8>
        min_ctime = p->ctime;
    80002008:	16c4ad03          	lw	s10,364(s1)
        min_sched = p->sched;
    8000200c:	18c4ac83          	lw	s9,396(s1)
        min_dp = dp;
    80002010:	893a                	mv	s2,a4
        min_sched = p->sched;
    80002012:	b749                	j	80001f94 <scheduler+0xb8>
        if(p->sched < min_sched){
    80002014:	18c4a783          	lw	a5,396(s1)
    80002018:	0197f663          	bgeu	a5,s9,80002024 <scheduler+0x148>
          min_ctime = p->ctime;
    8000201c:	16c4ad03          	lw	s10,364(s1)
          min_sched = p->sched;
    80002020:	8cbe                	mv	s9,a5
    80002022:	bf8d                	j	80001f94 <scheduler+0xb8>
        else if(p->sched == min_sched){
    80002024:	f79798e3          	bne	a5,s9,80001f94 <scheduler+0xb8>
          if(p->ctime < min_ctime){
    80002028:	16c4a783          	lw	a5,364(s1)
    8000202c:	873e                	mv	a4,a5
    8000202e:	2781                	sext.w	a5,a5
    80002030:	00fd7363          	bgeu	s10,a5,80002036 <scheduler+0x15a>
    80002034:	876a                	mv	a4,s10
    80002036:	00070d1b          	sext.w	s10,a4
    8000203a:	bfa9                	j	80001f94 <scheduler+0xb8>
    for(p = proc; p < &proc[NPROC]; p++){
    8000203c:	0000f497          	auipc	s1,0xf
    80002040:	f6448493          	addi	s1,s1,-156 # 80010fa0 <proc>
        p->state = RUNNING;
    80002044:	4b91                	li	s7,4
        p->sched++;
    80002046:	001c8b1b          	addiw	s6,s9,1
    8000204a:	a811                	j	8000205e <scheduler+0x182>
      release(&p->lock);
    8000204c:	8526                	mv	a0,s1
    8000204e:	fffff097          	auipc	ra,0xfffff
    80002052:	c3c080e7          	jalr	-964(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++){
    80002056:	19048493          	addi	s1,s1,400
    8000205a:	f13480e3          	beq	s1,s3,80001f5a <scheduler+0x7e>
      acquire(&p->lock);
    8000205e:	8526                	mv	a0,s1
    80002060:	fffff097          	auipc	ra,0xfffff
    80002064:	b76080e7          	jalr	-1162(ra) # 80000bd6 <acquire>
      if((p->state == RUNNABLE) && (p->dp == min_dp) && (p->sched == min_sched) && (p->ctime == min_ctime)){
    80002068:	4c9c                	lw	a5,24(s1)
    8000206a:	ff4791e3          	bne	a5,s4,8000204c <scheduler+0x170>
    8000206e:	1784a783          	lw	a5,376(s1)
    80002072:	fd279de3          	bne	a5,s2,8000204c <scheduler+0x170>
    80002076:	18c4a783          	lw	a5,396(s1)
    8000207a:	fd9799e3          	bne	a5,s9,8000204c <scheduler+0x170>
    8000207e:	16c4a783          	lw	a5,364(s1)
    80002082:	fda795e3          	bne	a5,s10,8000204c <scheduler+0x170>
        p->state = RUNNING;
    80002086:	0174ac23          	sw	s7,24(s1)
        p->sched++;
    8000208a:	1964a623          	sw	s6,396(s1)
        p->Rtime = 0;
    8000208e:	1804a223          	sw	zero,388(s1)
        p->stime = 0;
    80002092:	1804a423          	sw	zero,392(s1)
        c->proc = p;
    80002096:	029db823          	sd	s1,48(s11)
        swtch(&c->context, &p->context);
    8000209a:	06048593          	addi	a1,s1,96
    8000209e:	f7843503          	ld	a0,-136(s0)
    800020a2:	00001097          	auipc	ra,0x1
    800020a6:	86e080e7          	jalr	-1938(ra) # 80002910 <swtch>
        c->proc = 0;
    800020aa:	020db823          	sd	zero,48(s11)
    800020ae:	bf79                	j	8000204c <scheduler+0x170>

00000000800020b0 <sched>:
{
    800020b0:	7179                	addi	sp,sp,-48
    800020b2:	f406                	sd	ra,40(sp)
    800020b4:	f022                	sd	s0,32(sp)
    800020b6:	ec26                	sd	s1,24(sp)
    800020b8:	e84a                	sd	s2,16(sp)
    800020ba:	e44e                	sd	s3,8(sp)
    800020bc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800020be:	00000097          	auipc	ra,0x0
    800020c2:	8ee080e7          	jalr	-1810(ra) # 800019ac <myproc>
    800020c6:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	a94080e7          	jalr	-1388(ra) # 80000b5c <holding>
    800020d0:	c93d                	beqz	a0,80002146 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020d2:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    800020d4:	2781                	sext.w	a5,a5
    800020d6:	079e                	slli	a5,a5,0x7
    800020d8:	0000f717          	auipc	a4,0xf
    800020dc:	a9870713          	addi	a4,a4,-1384 # 80010b70 <pid_lock>
    800020e0:	97ba                	add	a5,a5,a4
    800020e2:	0a87a703          	lw	a4,168(a5)
    800020e6:	4785                	li	a5,1
    800020e8:	06f71763          	bne	a4,a5,80002156 <sched+0xa6>
  if (p->state == RUNNING)
    800020ec:	4c98                	lw	a4,24(s1)
    800020ee:	4791                	li	a5,4
    800020f0:	06f70b63          	beq	a4,a5,80002166 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020f4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020f8:	8b89                	andi	a5,a5,2
  if (intr_get())
    800020fa:	efb5                	bnez	a5,80002176 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020fc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020fe:	0000f917          	auipc	s2,0xf
    80002102:	a7290913          	addi	s2,s2,-1422 # 80010b70 <pid_lock>
    80002106:	2781                	sext.w	a5,a5
    80002108:	079e                	slli	a5,a5,0x7
    8000210a:	97ca                	add	a5,a5,s2
    8000210c:	0ac7a983          	lw	s3,172(a5)
    80002110:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002112:	2781                	sext.w	a5,a5
    80002114:	079e                	slli	a5,a5,0x7
    80002116:	0000f597          	auipc	a1,0xf
    8000211a:	a9258593          	addi	a1,a1,-1390 # 80010ba8 <cpus+0x8>
    8000211e:	95be                	add	a1,a1,a5
    80002120:	06048513          	addi	a0,s1,96
    80002124:	00000097          	auipc	ra,0x0
    80002128:	7ec080e7          	jalr	2028(ra) # 80002910 <swtch>
    8000212c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000212e:	2781                	sext.w	a5,a5
    80002130:	079e                	slli	a5,a5,0x7
    80002132:	993e                	add	s2,s2,a5
    80002134:	0b392623          	sw	s3,172(s2)
}
    80002138:	70a2                	ld	ra,40(sp)
    8000213a:	7402                	ld	s0,32(sp)
    8000213c:	64e2                	ld	s1,24(sp)
    8000213e:	6942                	ld	s2,16(sp)
    80002140:	69a2                	ld	s3,8(sp)
    80002142:	6145                	addi	sp,sp,48
    80002144:	8082                	ret
    panic("sched p->lock");
    80002146:	00006517          	auipc	a0,0x6
    8000214a:	0da50513          	addi	a0,a0,218 # 80008220 <digits+0x1e0>
    8000214e:	ffffe097          	auipc	ra,0xffffe
    80002152:	3f2080e7          	jalr	1010(ra) # 80000540 <panic>
    panic("sched locks");
    80002156:	00006517          	auipc	a0,0x6
    8000215a:	0da50513          	addi	a0,a0,218 # 80008230 <digits+0x1f0>
    8000215e:	ffffe097          	auipc	ra,0xffffe
    80002162:	3e2080e7          	jalr	994(ra) # 80000540 <panic>
    panic("sched running");
    80002166:	00006517          	auipc	a0,0x6
    8000216a:	0da50513          	addi	a0,a0,218 # 80008240 <digits+0x200>
    8000216e:	ffffe097          	auipc	ra,0xffffe
    80002172:	3d2080e7          	jalr	978(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002176:	00006517          	auipc	a0,0x6
    8000217a:	0da50513          	addi	a0,a0,218 # 80008250 <digits+0x210>
    8000217e:	ffffe097          	auipc	ra,0xffffe
    80002182:	3c2080e7          	jalr	962(ra) # 80000540 <panic>

0000000080002186 <yield>:
{
    80002186:	1101                	addi	sp,sp,-32
    80002188:	ec06                	sd	ra,24(sp)
    8000218a:	e822                	sd	s0,16(sp)
    8000218c:	e426                	sd	s1,8(sp)
    8000218e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002190:	00000097          	auipc	ra,0x0
    80002194:	81c080e7          	jalr	-2020(ra) # 800019ac <myproc>
    80002198:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	a3c080e7          	jalr	-1476(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    800021a2:	478d                	li	a5,3
    800021a4:	cc9c                	sw	a5,24(s1)
  sched();
    800021a6:	00000097          	auipc	ra,0x0
    800021aa:	f0a080e7          	jalr	-246(ra) # 800020b0 <sched>
  release(&p->lock);
    800021ae:	8526                	mv	a0,s1
    800021b0:	fffff097          	auipc	ra,0xfffff
    800021b4:	ada080e7          	jalr	-1318(ra) # 80000c8a <release>
}
    800021b8:	60e2                	ld	ra,24(sp)
    800021ba:	6442                	ld	s0,16(sp)
    800021bc:	64a2                	ld	s1,8(sp)
    800021be:	6105                	addi	sp,sp,32
    800021c0:	8082                	ret

00000000800021c2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    800021c2:	7179                	addi	sp,sp,-48
    800021c4:	f406                	sd	ra,40(sp)
    800021c6:	f022                	sd	s0,32(sp)
    800021c8:	ec26                	sd	s1,24(sp)
    800021ca:	e84a                	sd	s2,16(sp)
    800021cc:	e44e                	sd	s3,8(sp)
    800021ce:	1800                	addi	s0,sp,48
    800021d0:	89aa                	mv	s3,a0
    800021d2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800021d4:	fffff097          	auipc	ra,0xfffff
    800021d8:	7d8080e7          	jalr	2008(ra) # 800019ac <myproc>
    800021dc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    800021de:	fffff097          	auipc	ra,0xfffff
    800021e2:	9f8080e7          	jalr	-1544(ra) # 80000bd6 <acquire>
  release(lk);
    800021e6:	854a                	mv	a0,s2
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	aa2080e7          	jalr	-1374(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021f0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021f4:	4789                	li	a5,2
    800021f6:	cc9c                	sw	a5,24(s1)

  sched();
    800021f8:	00000097          	auipc	ra,0x0
    800021fc:	eb8080e7          	jalr	-328(ra) # 800020b0 <sched>

  // Tidy up.
  p->chan = 0;
    80002200:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002204:	8526                	mv	a0,s1
    80002206:	fffff097          	auipc	ra,0xfffff
    8000220a:	a84080e7          	jalr	-1404(ra) # 80000c8a <release>
  acquire(lk);
    8000220e:	854a                	mv	a0,s2
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	9c6080e7          	jalr	-1594(ra) # 80000bd6 <acquire>
}
    80002218:	70a2                	ld	ra,40(sp)
    8000221a:	7402                	ld	s0,32(sp)
    8000221c:	64e2                	ld	s1,24(sp)
    8000221e:	6942                	ld	s2,16(sp)
    80002220:	69a2                	ld	s3,8(sp)
    80002222:	6145                	addi	sp,sp,48
    80002224:	8082                	ret

0000000080002226 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002226:	7139                	addi	sp,sp,-64
    80002228:	fc06                	sd	ra,56(sp)
    8000222a:	f822                	sd	s0,48(sp)
    8000222c:	f426                	sd	s1,40(sp)
    8000222e:	f04a                	sd	s2,32(sp)
    80002230:	ec4e                	sd	s3,24(sp)
    80002232:	e852                	sd	s4,16(sp)
    80002234:	e456                	sd	s5,8(sp)
    80002236:	0080                	addi	s0,sp,64
    80002238:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    8000223a:	0000f497          	auipc	s1,0xf
    8000223e:	d6648493          	addi	s1,s1,-666 # 80010fa0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002242:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002244:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002246:	00015917          	auipc	s2,0x15
    8000224a:	15a90913          	addi	s2,s2,346 # 800173a0 <tickslock>
    8000224e:	a811                	j	80002262 <wakeup+0x3c>
      }
      release(&p->lock);
    80002250:	8526                	mv	a0,s1
    80002252:	fffff097          	auipc	ra,0xfffff
    80002256:	a38080e7          	jalr	-1480(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000225a:	19048493          	addi	s1,s1,400
    8000225e:	03248663          	beq	s1,s2,8000228a <wakeup+0x64>
    if (p != myproc())
    80002262:	fffff097          	auipc	ra,0xfffff
    80002266:	74a080e7          	jalr	1866(ra) # 800019ac <myproc>
    8000226a:	fea488e3          	beq	s1,a0,8000225a <wakeup+0x34>
      acquire(&p->lock);
    8000226e:	8526                	mv	a0,s1
    80002270:	fffff097          	auipc	ra,0xfffff
    80002274:	966080e7          	jalr	-1690(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002278:	4c9c                	lw	a5,24(s1)
    8000227a:	fd379be3          	bne	a5,s3,80002250 <wakeup+0x2a>
    8000227e:	709c                	ld	a5,32(s1)
    80002280:	fd4798e3          	bne	a5,s4,80002250 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002284:	0154ac23          	sw	s5,24(s1)
    80002288:	b7e1                	j	80002250 <wakeup+0x2a>
    }
  }
}
    8000228a:	70e2                	ld	ra,56(sp)
    8000228c:	7442                	ld	s0,48(sp)
    8000228e:	74a2                	ld	s1,40(sp)
    80002290:	7902                	ld	s2,32(sp)
    80002292:	69e2                	ld	s3,24(sp)
    80002294:	6a42                	ld	s4,16(sp)
    80002296:	6aa2                	ld	s5,8(sp)
    80002298:	6121                	addi	sp,sp,64
    8000229a:	8082                	ret

000000008000229c <reparent>:
{
    8000229c:	7179                	addi	sp,sp,-48
    8000229e:	f406                	sd	ra,40(sp)
    800022a0:	f022                	sd	s0,32(sp)
    800022a2:	ec26                	sd	s1,24(sp)
    800022a4:	e84a                	sd	s2,16(sp)
    800022a6:	e44e                	sd	s3,8(sp)
    800022a8:	e052                	sd	s4,0(sp)
    800022aa:	1800                	addi	s0,sp,48
    800022ac:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022ae:	0000f497          	auipc	s1,0xf
    800022b2:	cf248493          	addi	s1,s1,-782 # 80010fa0 <proc>
      pp->parent = initproc;
    800022b6:	00006a17          	auipc	s4,0x6
    800022ba:	642a0a13          	addi	s4,s4,1602 # 800088f8 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    800022be:	00015997          	auipc	s3,0x15
    800022c2:	0e298993          	addi	s3,s3,226 # 800173a0 <tickslock>
    800022c6:	a029                	j	800022d0 <reparent+0x34>
    800022c8:	19048493          	addi	s1,s1,400
    800022cc:	01348d63          	beq	s1,s3,800022e6 <reparent+0x4a>
    if (pp->parent == p)
    800022d0:	7c9c                	ld	a5,56(s1)
    800022d2:	ff279be3          	bne	a5,s2,800022c8 <reparent+0x2c>
      pp->parent = initproc;
    800022d6:	000a3503          	ld	a0,0(s4)
    800022da:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800022dc:	00000097          	auipc	ra,0x0
    800022e0:	f4a080e7          	jalr	-182(ra) # 80002226 <wakeup>
    800022e4:	b7d5                	j	800022c8 <reparent+0x2c>
}
    800022e6:	70a2                	ld	ra,40(sp)
    800022e8:	7402                	ld	s0,32(sp)
    800022ea:	64e2                	ld	s1,24(sp)
    800022ec:	6942                	ld	s2,16(sp)
    800022ee:	69a2                	ld	s3,8(sp)
    800022f0:	6a02                	ld	s4,0(sp)
    800022f2:	6145                	addi	sp,sp,48
    800022f4:	8082                	ret

00000000800022f6 <exit>:
{
    800022f6:	7179                	addi	sp,sp,-48
    800022f8:	f406                	sd	ra,40(sp)
    800022fa:	f022                	sd	s0,32(sp)
    800022fc:	ec26                	sd	s1,24(sp)
    800022fe:	e84a                	sd	s2,16(sp)
    80002300:	e44e                	sd	s3,8(sp)
    80002302:	e052                	sd	s4,0(sp)
    80002304:	1800                	addi	s0,sp,48
    80002306:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	6a4080e7          	jalr	1700(ra) # 800019ac <myproc>
    80002310:	89aa                	mv	s3,a0
  if (p == initproc)
    80002312:	00006797          	auipc	a5,0x6
    80002316:	5e67b783          	ld	a5,1510(a5) # 800088f8 <initproc>
    8000231a:	0d050493          	addi	s1,a0,208
    8000231e:	15050913          	addi	s2,a0,336
    80002322:	02a79363          	bne	a5,a0,80002348 <exit+0x52>
    panic("init exiting");
    80002326:	00006517          	auipc	a0,0x6
    8000232a:	f4250513          	addi	a0,a0,-190 # 80008268 <digits+0x228>
    8000232e:	ffffe097          	auipc	ra,0xffffe
    80002332:	212080e7          	jalr	530(ra) # 80000540 <panic>
      fileclose(f);
    80002336:	00002097          	auipc	ra,0x2
    8000233a:	652080e7          	jalr	1618(ra) # 80004988 <fileclose>
      p->ofile[fd] = 0;
    8000233e:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002342:	04a1                	addi	s1,s1,8
    80002344:	01248563          	beq	s1,s2,8000234e <exit+0x58>
    if (p->ofile[fd])
    80002348:	6088                	ld	a0,0(s1)
    8000234a:	f575                	bnez	a0,80002336 <exit+0x40>
    8000234c:	bfdd                	j	80002342 <exit+0x4c>
  begin_op();
    8000234e:	00002097          	auipc	ra,0x2
    80002352:	172080e7          	jalr	370(ra) # 800044c0 <begin_op>
  iput(p->cwd);
    80002356:	1509b503          	ld	a0,336(s3)
    8000235a:	00002097          	auipc	ra,0x2
    8000235e:	954080e7          	jalr	-1708(ra) # 80003cae <iput>
  end_op();
    80002362:	00002097          	auipc	ra,0x2
    80002366:	1dc080e7          	jalr	476(ra) # 8000453e <end_op>
  p->cwd = 0;
    8000236a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000236e:	0000f497          	auipc	s1,0xf
    80002372:	81a48493          	addi	s1,s1,-2022 # 80010b88 <wait_lock>
    80002376:	8526                	mv	a0,s1
    80002378:	fffff097          	auipc	ra,0xfffff
    8000237c:	85e080e7          	jalr	-1954(ra) # 80000bd6 <acquire>
  reparent(p);
    80002380:	854e                	mv	a0,s3
    80002382:	00000097          	auipc	ra,0x0
    80002386:	f1a080e7          	jalr	-230(ra) # 8000229c <reparent>
  wakeup(p->parent);
    8000238a:	0389b503          	ld	a0,56(s3)
    8000238e:	00000097          	auipc	ra,0x0
    80002392:	e98080e7          	jalr	-360(ra) # 80002226 <wakeup>
  acquire(&p->lock);
    80002396:	854e                	mv	a0,s3
    80002398:	fffff097          	auipc	ra,0xfffff
    8000239c:	83e080e7          	jalr	-1986(ra) # 80000bd6 <acquire>
  p->xstate = status;
    800023a0:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800023a4:	4795                	li	a5,5
    800023a6:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    800023aa:	00006797          	auipc	a5,0x6
    800023ae:	5567a783          	lw	a5,1366(a5) # 80008900 <ticks>
    800023b2:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    800023b6:	8526                	mv	a0,s1
    800023b8:	fffff097          	auipc	ra,0xfffff
    800023bc:	8d2080e7          	jalr	-1838(ra) # 80000c8a <release>
  sched();
    800023c0:	00000097          	auipc	ra,0x0
    800023c4:	cf0080e7          	jalr	-784(ra) # 800020b0 <sched>
  panic("zombie exit");
    800023c8:	00006517          	auipc	a0,0x6
    800023cc:	eb050513          	addi	a0,a0,-336 # 80008278 <digits+0x238>
    800023d0:	ffffe097          	auipc	ra,0xffffe
    800023d4:	170080e7          	jalr	368(ra) # 80000540 <panic>

00000000800023d8 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    800023d8:	7179                	addi	sp,sp,-48
    800023da:	f406                	sd	ra,40(sp)
    800023dc:	f022                	sd	s0,32(sp)
    800023de:	ec26                	sd	s1,24(sp)
    800023e0:	e84a                	sd	s2,16(sp)
    800023e2:	e44e                	sd	s3,8(sp)
    800023e4:	1800                	addi	s0,sp,48
    800023e6:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800023e8:	0000f497          	auipc	s1,0xf
    800023ec:	bb848493          	addi	s1,s1,-1096 # 80010fa0 <proc>
    800023f0:	00015997          	auipc	s3,0x15
    800023f4:	fb098993          	addi	s3,s3,-80 # 800173a0 <tickslock>
  {
    acquire(&p->lock);
    800023f8:	8526                	mv	a0,s1
    800023fa:	ffffe097          	auipc	ra,0xffffe
    800023fe:	7dc080e7          	jalr	2012(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002402:	589c                	lw	a5,48(s1)
    80002404:	01278d63          	beq	a5,s2,8000241e <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002408:	8526                	mv	a0,s1
    8000240a:	fffff097          	auipc	ra,0xfffff
    8000240e:	880080e7          	jalr	-1920(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002412:	19048493          	addi	s1,s1,400
    80002416:	ff3491e3          	bne	s1,s3,800023f8 <kill+0x20>
  }
  return -1;
    8000241a:	557d                	li	a0,-1
    8000241c:	a829                	j	80002436 <kill+0x5e>
      p->killed = 1;
    8000241e:	4785                	li	a5,1
    80002420:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002422:	4c98                	lw	a4,24(s1)
    80002424:	4789                	li	a5,2
    80002426:	00f70f63          	beq	a4,a5,80002444 <kill+0x6c>
      release(&p->lock);
    8000242a:	8526                	mv	a0,s1
    8000242c:	fffff097          	auipc	ra,0xfffff
    80002430:	85e080e7          	jalr	-1954(ra) # 80000c8a <release>
      return 0;
    80002434:	4501                	li	a0,0
}
    80002436:	70a2                	ld	ra,40(sp)
    80002438:	7402                	ld	s0,32(sp)
    8000243a:	64e2                	ld	s1,24(sp)
    8000243c:	6942                	ld	s2,16(sp)
    8000243e:	69a2                	ld	s3,8(sp)
    80002440:	6145                	addi	sp,sp,48
    80002442:	8082                	ret
        p->state = RUNNABLE;
    80002444:	478d                	li	a5,3
    80002446:	cc9c                	sw	a5,24(s1)
    80002448:	b7cd                	j	8000242a <kill+0x52>

000000008000244a <setkilled>:

void setkilled(struct proc *p)
{
    8000244a:	1101                	addi	sp,sp,-32
    8000244c:	ec06                	sd	ra,24(sp)
    8000244e:	e822                	sd	s0,16(sp)
    80002450:	e426                	sd	s1,8(sp)
    80002452:	1000                	addi	s0,sp,32
    80002454:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002456:	ffffe097          	auipc	ra,0xffffe
    8000245a:	780080e7          	jalr	1920(ra) # 80000bd6 <acquire>
  p->killed = 1;
    8000245e:	4785                	li	a5,1
    80002460:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002462:	8526                	mv	a0,s1
    80002464:	fffff097          	auipc	ra,0xfffff
    80002468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
}
    8000246c:	60e2                	ld	ra,24(sp)
    8000246e:	6442                	ld	s0,16(sp)
    80002470:	64a2                	ld	s1,8(sp)
    80002472:	6105                	addi	sp,sp,32
    80002474:	8082                	ret

0000000080002476 <killed>:

int killed(struct proc *p)
{
    80002476:	1101                	addi	sp,sp,-32
    80002478:	ec06                	sd	ra,24(sp)
    8000247a:	e822                	sd	s0,16(sp)
    8000247c:	e426                	sd	s1,8(sp)
    8000247e:	e04a                	sd	s2,0(sp)
    80002480:	1000                	addi	s0,sp,32
    80002482:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002484:	ffffe097          	auipc	ra,0xffffe
    80002488:	752080e7          	jalr	1874(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000248c:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002490:	8526                	mv	a0,s1
    80002492:	ffffe097          	auipc	ra,0xffffe
    80002496:	7f8080e7          	jalr	2040(ra) # 80000c8a <release>
  return k;
}
    8000249a:	854a                	mv	a0,s2
    8000249c:	60e2                	ld	ra,24(sp)
    8000249e:	6442                	ld	s0,16(sp)
    800024a0:	64a2                	ld	s1,8(sp)
    800024a2:	6902                	ld	s2,0(sp)
    800024a4:	6105                	addi	sp,sp,32
    800024a6:	8082                	ret

00000000800024a8 <wait>:
{
    800024a8:	715d                	addi	sp,sp,-80
    800024aa:	e486                	sd	ra,72(sp)
    800024ac:	e0a2                	sd	s0,64(sp)
    800024ae:	fc26                	sd	s1,56(sp)
    800024b0:	f84a                	sd	s2,48(sp)
    800024b2:	f44e                	sd	s3,40(sp)
    800024b4:	f052                	sd	s4,32(sp)
    800024b6:	ec56                	sd	s5,24(sp)
    800024b8:	e85a                	sd	s6,16(sp)
    800024ba:	e45e                	sd	s7,8(sp)
    800024bc:	e062                	sd	s8,0(sp)
    800024be:	0880                	addi	s0,sp,80
    800024c0:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	4ea080e7          	jalr	1258(ra) # 800019ac <myproc>
    800024ca:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800024cc:	0000e517          	auipc	a0,0xe
    800024d0:	6bc50513          	addi	a0,a0,1724 # 80010b88 <wait_lock>
    800024d4:	ffffe097          	auipc	ra,0xffffe
    800024d8:	702080e7          	jalr	1794(ra) # 80000bd6 <acquire>
    havekids = 0;
    800024dc:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    800024de:	4a15                	li	s4,5
        havekids = 1;
    800024e0:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024e2:	00015997          	auipc	s3,0x15
    800024e6:	ebe98993          	addi	s3,s3,-322 # 800173a0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    800024ea:	0000ec17          	auipc	s8,0xe
    800024ee:	69ec0c13          	addi	s8,s8,1694 # 80010b88 <wait_lock>
    havekids = 0;
    800024f2:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800024f4:	0000f497          	auipc	s1,0xf
    800024f8:	aac48493          	addi	s1,s1,-1364 # 80010fa0 <proc>
    800024fc:	a0bd                	j	8000256a <wait+0xc2>
          pid = pp->pid;
    800024fe:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002502:	000b0e63          	beqz	s6,8000251e <wait+0x76>
    80002506:	4691                	li	a3,4
    80002508:	02c48613          	addi	a2,s1,44
    8000250c:	85da                	mv	a1,s6
    8000250e:	05093503          	ld	a0,80(s2)
    80002512:	fffff097          	auipc	ra,0xfffff
    80002516:	15a080e7          	jalr	346(ra) # 8000166c <copyout>
    8000251a:	02054563          	bltz	a0,80002544 <wait+0x9c>
          freeproc(pp);
    8000251e:	8526                	mv	a0,s1
    80002520:	fffff097          	auipc	ra,0xfffff
    80002524:	63e080e7          	jalr	1598(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002528:	8526                	mv	a0,s1
    8000252a:	ffffe097          	auipc	ra,0xffffe
    8000252e:	760080e7          	jalr	1888(ra) # 80000c8a <release>
          release(&wait_lock);
    80002532:	0000e517          	auipc	a0,0xe
    80002536:	65650513          	addi	a0,a0,1622 # 80010b88 <wait_lock>
    8000253a:	ffffe097          	auipc	ra,0xffffe
    8000253e:	750080e7          	jalr	1872(ra) # 80000c8a <release>
          return pid;
    80002542:	a0b5                	j	800025ae <wait+0x106>
            release(&pp->lock);
    80002544:	8526                	mv	a0,s1
    80002546:	ffffe097          	auipc	ra,0xffffe
    8000254a:	744080e7          	jalr	1860(ra) # 80000c8a <release>
            release(&wait_lock);
    8000254e:	0000e517          	auipc	a0,0xe
    80002552:	63a50513          	addi	a0,a0,1594 # 80010b88 <wait_lock>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
            return -1;
    8000255e:	59fd                	li	s3,-1
    80002560:	a0b9                	j	800025ae <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002562:	19048493          	addi	s1,s1,400
    80002566:	03348463          	beq	s1,s3,8000258e <wait+0xe6>
      if (pp->parent == p)
    8000256a:	7c9c                	ld	a5,56(s1)
    8000256c:	ff279be3          	bne	a5,s2,80002562 <wait+0xba>
        acquire(&pp->lock);
    80002570:	8526                	mv	a0,s1
    80002572:	ffffe097          	auipc	ra,0xffffe
    80002576:	664080e7          	jalr	1636(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000257a:	4c9c                	lw	a5,24(s1)
    8000257c:	f94781e3          	beq	a5,s4,800024fe <wait+0x56>
        release(&pp->lock);
    80002580:	8526                	mv	a0,s1
    80002582:	ffffe097          	auipc	ra,0xffffe
    80002586:	708080e7          	jalr	1800(ra) # 80000c8a <release>
        havekids = 1;
    8000258a:	8756                	mv	a4,s5
    8000258c:	bfd9                	j	80002562 <wait+0xba>
    if (!havekids || killed(p))
    8000258e:	c719                	beqz	a4,8000259c <wait+0xf4>
    80002590:	854a                	mv	a0,s2
    80002592:	00000097          	auipc	ra,0x0
    80002596:	ee4080e7          	jalr	-284(ra) # 80002476 <killed>
    8000259a:	c51d                	beqz	a0,800025c8 <wait+0x120>
      release(&wait_lock);
    8000259c:	0000e517          	auipc	a0,0xe
    800025a0:	5ec50513          	addi	a0,a0,1516 # 80010b88 <wait_lock>
    800025a4:	ffffe097          	auipc	ra,0xffffe
    800025a8:	6e6080e7          	jalr	1766(ra) # 80000c8a <release>
      return -1;
    800025ac:	59fd                	li	s3,-1
}
    800025ae:	854e                	mv	a0,s3
    800025b0:	60a6                	ld	ra,72(sp)
    800025b2:	6406                	ld	s0,64(sp)
    800025b4:	74e2                	ld	s1,56(sp)
    800025b6:	7942                	ld	s2,48(sp)
    800025b8:	79a2                	ld	s3,40(sp)
    800025ba:	7a02                	ld	s4,32(sp)
    800025bc:	6ae2                	ld	s5,24(sp)
    800025be:	6b42                	ld	s6,16(sp)
    800025c0:	6ba2                	ld	s7,8(sp)
    800025c2:	6c02                	ld	s8,0(sp)
    800025c4:	6161                	addi	sp,sp,80
    800025c6:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    800025c8:	85e2                	mv	a1,s8
    800025ca:	854a                	mv	a0,s2
    800025cc:	00000097          	auipc	ra,0x0
    800025d0:	bf6080e7          	jalr	-1034(ra) # 800021c2 <sleep>
    havekids = 0;
    800025d4:	bf39                	j	800024f2 <wait+0x4a>

00000000800025d6 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800025d6:	7179                	addi	sp,sp,-48
    800025d8:	f406                	sd	ra,40(sp)
    800025da:	f022                	sd	s0,32(sp)
    800025dc:	ec26                	sd	s1,24(sp)
    800025de:	e84a                	sd	s2,16(sp)
    800025e0:	e44e                	sd	s3,8(sp)
    800025e2:	e052                	sd	s4,0(sp)
    800025e4:	1800                	addi	s0,sp,48
    800025e6:	84aa                	mv	s1,a0
    800025e8:	892e                	mv	s2,a1
    800025ea:	89b2                	mv	s3,a2
    800025ec:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025ee:	fffff097          	auipc	ra,0xfffff
    800025f2:	3be080e7          	jalr	958(ra) # 800019ac <myproc>
  if (user_dst)
    800025f6:	c08d                	beqz	s1,80002618 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800025f8:	86d2                	mv	a3,s4
    800025fa:	864e                	mv	a2,s3
    800025fc:	85ca                	mv	a1,s2
    800025fe:	6928                	ld	a0,80(a0)
    80002600:	fffff097          	auipc	ra,0xfffff
    80002604:	06c080e7          	jalr	108(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002608:	70a2                	ld	ra,40(sp)
    8000260a:	7402                	ld	s0,32(sp)
    8000260c:	64e2                	ld	s1,24(sp)
    8000260e:	6942                	ld	s2,16(sp)
    80002610:	69a2                	ld	s3,8(sp)
    80002612:	6a02                	ld	s4,0(sp)
    80002614:	6145                	addi	sp,sp,48
    80002616:	8082                	ret
    memmove((char *)dst, src, len);
    80002618:	000a061b          	sext.w	a2,s4
    8000261c:	85ce                	mv	a1,s3
    8000261e:	854a                	mv	a0,s2
    80002620:	ffffe097          	auipc	ra,0xffffe
    80002624:	70e080e7          	jalr	1806(ra) # 80000d2e <memmove>
    return 0;
    80002628:	8526                	mv	a0,s1
    8000262a:	bff9                	j	80002608 <either_copyout+0x32>

000000008000262c <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    8000262c:	7179                	addi	sp,sp,-48
    8000262e:	f406                	sd	ra,40(sp)
    80002630:	f022                	sd	s0,32(sp)
    80002632:	ec26                	sd	s1,24(sp)
    80002634:	e84a                	sd	s2,16(sp)
    80002636:	e44e                	sd	s3,8(sp)
    80002638:	e052                	sd	s4,0(sp)
    8000263a:	1800                	addi	s0,sp,48
    8000263c:	892a                	mv	s2,a0
    8000263e:	84ae                	mv	s1,a1
    80002640:	89b2                	mv	s3,a2
    80002642:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002644:	fffff097          	auipc	ra,0xfffff
    80002648:	368080e7          	jalr	872(ra) # 800019ac <myproc>
  if (user_src)
    8000264c:	c08d                	beqz	s1,8000266e <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    8000264e:	86d2                	mv	a3,s4
    80002650:	864e                	mv	a2,s3
    80002652:	85ca                	mv	a1,s2
    80002654:	6928                	ld	a0,80(a0)
    80002656:	fffff097          	auipc	ra,0xfffff
    8000265a:	0a2080e7          	jalr	162(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    8000265e:	70a2                	ld	ra,40(sp)
    80002660:	7402                	ld	s0,32(sp)
    80002662:	64e2                	ld	s1,24(sp)
    80002664:	6942                	ld	s2,16(sp)
    80002666:	69a2                	ld	s3,8(sp)
    80002668:	6a02                	ld	s4,0(sp)
    8000266a:	6145                	addi	sp,sp,48
    8000266c:	8082                	ret
    memmove(dst, (char *)src, len);
    8000266e:	000a061b          	sext.w	a2,s4
    80002672:	85ce                	mv	a1,s3
    80002674:	854a                	mv	a0,s2
    80002676:	ffffe097          	auipc	ra,0xffffe
    8000267a:	6b8080e7          	jalr	1720(ra) # 80000d2e <memmove>
    return 0;
    8000267e:	8526                	mv	a0,s1
    80002680:	bff9                	j	8000265e <either_copyin+0x32>

0000000080002682 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002682:	715d                	addi	sp,sp,-80
    80002684:	e486                	sd	ra,72(sp)
    80002686:	e0a2                	sd	s0,64(sp)
    80002688:	fc26                	sd	s1,56(sp)
    8000268a:	f84a                	sd	s2,48(sp)
    8000268c:	f44e                	sd	s3,40(sp)
    8000268e:	f052                	sd	s4,32(sp)
    80002690:	ec56                	sd	s5,24(sp)
    80002692:	e85a                	sd	s6,16(sp)
    80002694:	e45e                	sd	s7,8(sp)
    80002696:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    80002698:	00006517          	auipc	a0,0x6
    8000269c:	a3050513          	addi	a0,a0,-1488 # 800080c8 <digits+0x88>
    800026a0:	ffffe097          	auipc	ra,0xffffe
    800026a4:	eea080e7          	jalr	-278(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026a8:	0000f497          	auipc	s1,0xf
    800026ac:	a5048493          	addi	s1,s1,-1456 # 800110f8 <proc+0x158>
    800026b0:	00015917          	auipc	s2,0x15
    800026b4:	e4890913          	addi	s2,s2,-440 # 800174f8 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b8:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    800026ba:	00006997          	auipc	s3,0x6
    800026be:	bce98993          	addi	s3,s3,-1074 # 80008288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    800026c2:	00006a97          	auipc	s5,0x6
    800026c6:	bcea8a93          	addi	s5,s5,-1074 # 80008290 <digits+0x250>
    printf("\n");
    800026ca:	00006a17          	auipc	s4,0x6
    800026ce:	9fea0a13          	addi	s4,s4,-1538 # 800080c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026d2:	00006b97          	auipc	s7,0x6
    800026d6:	bfeb8b93          	addi	s7,s7,-1026 # 800082d0 <states.0>
    800026da:	a00d                	j	800026fc <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800026dc:	ed86a583          	lw	a1,-296(a3)
    800026e0:	8556                	mv	a0,s5
    800026e2:	ffffe097          	auipc	ra,0xffffe
    800026e6:	ea8080e7          	jalr	-344(ra) # 8000058a <printf>
    printf("\n");
    800026ea:	8552                	mv	a0,s4
    800026ec:	ffffe097          	auipc	ra,0xffffe
    800026f0:	e9e080e7          	jalr	-354(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800026f4:	19048493          	addi	s1,s1,400
    800026f8:	03248263          	beq	s1,s2,8000271c <procdump+0x9a>
    if (p->state == UNUSED)
    800026fc:	86a6                	mv	a3,s1
    800026fe:	ec04a783          	lw	a5,-320(s1)
    80002702:	dbed                	beqz	a5,800026f4 <procdump+0x72>
      state = "???";
    80002704:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002706:	fcfb6be3          	bltu	s6,a5,800026dc <procdump+0x5a>
    8000270a:	02079713          	slli	a4,a5,0x20
    8000270e:	01d75793          	srli	a5,a4,0x1d
    80002712:	97de                	add	a5,a5,s7
    80002714:	6390                	ld	a2,0(a5)
    80002716:	f279                	bnez	a2,800026dc <procdump+0x5a>
      state = "???";
    80002718:	864e                	mv	a2,s3
    8000271a:	b7c9                	j	800026dc <procdump+0x5a>
  }
}
    8000271c:	60a6                	ld	ra,72(sp)
    8000271e:	6406                	ld	s0,64(sp)
    80002720:	74e2                	ld	s1,56(sp)
    80002722:	7942                	ld	s2,48(sp)
    80002724:	79a2                	ld	s3,40(sp)
    80002726:	7a02                	ld	s4,32(sp)
    80002728:	6ae2                	ld	s5,24(sp)
    8000272a:	6b42                	ld	s6,16(sp)
    8000272c:	6ba2                	ld	s7,8(sp)
    8000272e:	6161                	addi	sp,sp,80
    80002730:	8082                	ret

0000000080002732 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002732:	711d                	addi	sp,sp,-96
    80002734:	ec86                	sd	ra,88(sp)
    80002736:	e8a2                	sd	s0,80(sp)
    80002738:	e4a6                	sd	s1,72(sp)
    8000273a:	e0ca                	sd	s2,64(sp)
    8000273c:	fc4e                	sd	s3,56(sp)
    8000273e:	f852                	sd	s4,48(sp)
    80002740:	f456                	sd	s5,40(sp)
    80002742:	f05a                	sd	s6,32(sp)
    80002744:	ec5e                	sd	s7,24(sp)
    80002746:	e862                	sd	s8,16(sp)
    80002748:	e466                	sd	s9,8(sp)
    8000274a:	e06a                	sd	s10,0(sp)
    8000274c:	1080                	addi	s0,sp,96
    8000274e:	8b2a                	mv	s6,a0
    80002750:	8bae                	mv	s7,a1
    80002752:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002754:	fffff097          	auipc	ra,0xfffff
    80002758:	258080e7          	jalr	600(ra) # 800019ac <myproc>
    8000275c:	892a                	mv	s2,a0

  acquire(&wait_lock);
    8000275e:	0000e517          	auipc	a0,0xe
    80002762:	42a50513          	addi	a0,a0,1066 # 80010b88 <wait_lock>
    80002766:	ffffe097          	auipc	ra,0xffffe
    8000276a:	470080e7          	jalr	1136(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    8000276e:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002770:	4a15                	li	s4,5
        havekids = 1;
    80002772:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80002774:	00015997          	auipc	s3,0x15
    80002778:	c2c98993          	addi	s3,s3,-980 # 800173a0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000277c:	0000ed17          	auipc	s10,0xe
    80002780:	40cd0d13          	addi	s10,s10,1036 # 80010b88 <wait_lock>
    havekids = 0;
    80002784:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002786:	0000f497          	auipc	s1,0xf
    8000278a:	81a48493          	addi	s1,s1,-2022 # 80010fa0 <proc>
    8000278e:	a059                	j	80002814 <waitx+0xe2>
          pid = np->pid;
    80002790:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002794:	1684a783          	lw	a5,360(s1)
    80002798:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    8000279c:	16c4a703          	lw	a4,364(s1)
    800027a0:	9f3d                	addw	a4,a4,a5
    800027a2:	1704a783          	lw	a5,368(s1)
    800027a6:	9f99                	subw	a5,a5,a4
    800027a8:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800027ac:	000b0e63          	beqz	s6,800027c8 <waitx+0x96>
    800027b0:	4691                	li	a3,4
    800027b2:	02c48613          	addi	a2,s1,44
    800027b6:	85da                	mv	a1,s6
    800027b8:	05093503          	ld	a0,80(s2)
    800027bc:	fffff097          	auipc	ra,0xfffff
    800027c0:	eb0080e7          	jalr	-336(ra) # 8000166c <copyout>
    800027c4:	02054563          	bltz	a0,800027ee <waitx+0xbc>
          freeproc(np);
    800027c8:	8526                	mv	a0,s1
    800027ca:	fffff097          	auipc	ra,0xfffff
    800027ce:	394080e7          	jalr	916(ra) # 80001b5e <freeproc>
          release(&np->lock);
    800027d2:	8526                	mv	a0,s1
    800027d4:	ffffe097          	auipc	ra,0xffffe
    800027d8:	4b6080e7          	jalr	1206(ra) # 80000c8a <release>
          release(&wait_lock);
    800027dc:	0000e517          	auipc	a0,0xe
    800027e0:	3ac50513          	addi	a0,a0,940 # 80010b88 <wait_lock>
    800027e4:	ffffe097          	auipc	ra,0xffffe
    800027e8:	4a6080e7          	jalr	1190(ra) # 80000c8a <release>
          return pid;
    800027ec:	a09d                	j	80002852 <waitx+0x120>
            release(&np->lock);
    800027ee:	8526                	mv	a0,s1
    800027f0:	ffffe097          	auipc	ra,0xffffe
    800027f4:	49a080e7          	jalr	1178(ra) # 80000c8a <release>
            release(&wait_lock);
    800027f8:	0000e517          	auipc	a0,0xe
    800027fc:	39050513          	addi	a0,a0,912 # 80010b88 <wait_lock>
    80002800:	ffffe097          	auipc	ra,0xffffe
    80002804:	48a080e7          	jalr	1162(ra) # 80000c8a <release>
            return -1;
    80002808:	59fd                	li	s3,-1
    8000280a:	a0a1                	j	80002852 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    8000280c:	19048493          	addi	s1,s1,400
    80002810:	03348463          	beq	s1,s3,80002838 <waitx+0x106>
      if (np->parent == p)
    80002814:	7c9c                	ld	a5,56(s1)
    80002816:	ff279be3          	bne	a5,s2,8000280c <waitx+0xda>
        acquire(&np->lock);
    8000281a:	8526                	mv	a0,s1
    8000281c:	ffffe097          	auipc	ra,0xffffe
    80002820:	3ba080e7          	jalr	954(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    80002824:	4c9c                	lw	a5,24(s1)
    80002826:	f74785e3          	beq	a5,s4,80002790 <waitx+0x5e>
        release(&np->lock);
    8000282a:	8526                	mv	a0,s1
    8000282c:	ffffe097          	auipc	ra,0xffffe
    80002830:	45e080e7          	jalr	1118(ra) # 80000c8a <release>
        havekids = 1;
    80002834:	8756                	mv	a4,s5
    80002836:	bfd9                	j	8000280c <waitx+0xda>
    if (!havekids || p->killed)
    80002838:	c701                	beqz	a4,80002840 <waitx+0x10e>
    8000283a:	02892783          	lw	a5,40(s2)
    8000283e:	cb8d                	beqz	a5,80002870 <waitx+0x13e>
      release(&wait_lock);
    80002840:	0000e517          	auipc	a0,0xe
    80002844:	34850513          	addi	a0,a0,840 # 80010b88 <wait_lock>
    80002848:	ffffe097          	auipc	ra,0xffffe
    8000284c:	442080e7          	jalr	1090(ra) # 80000c8a <release>
      return -1;
    80002850:	59fd                	li	s3,-1
  }
}
    80002852:	854e                	mv	a0,s3
    80002854:	60e6                	ld	ra,88(sp)
    80002856:	6446                	ld	s0,80(sp)
    80002858:	64a6                	ld	s1,72(sp)
    8000285a:	6906                	ld	s2,64(sp)
    8000285c:	79e2                	ld	s3,56(sp)
    8000285e:	7a42                	ld	s4,48(sp)
    80002860:	7aa2                	ld	s5,40(sp)
    80002862:	7b02                	ld	s6,32(sp)
    80002864:	6be2                	ld	s7,24(sp)
    80002866:	6c42                	ld	s8,16(sp)
    80002868:	6ca2                	ld	s9,8(sp)
    8000286a:	6d02                	ld	s10,0(sp)
    8000286c:	6125                	addi	sp,sp,96
    8000286e:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002870:	85ea                	mv	a1,s10
    80002872:	854a                	mv	a0,s2
    80002874:	00000097          	auipc	ra,0x0
    80002878:	94e080e7          	jalr	-1714(ra) # 800021c2 <sleep>
    havekids = 0;
    8000287c:	b721                	j	80002784 <waitx+0x52>

000000008000287e <update_time>:

void update_time()
{
    8000287e:	7139                	addi	sp,sp,-64
    80002880:	fc06                	sd	ra,56(sp)
    80002882:	f822                	sd	s0,48(sp)
    80002884:	f426                	sd	s1,40(sp)
    80002886:	f04a                	sd	s2,32(sp)
    80002888:	ec4e                	sd	s3,24(sp)
    8000288a:	e852                	sd	s4,16(sp)
    8000288c:	e456                	sd	s5,8(sp)
    8000288e:	0080                	addi	s0,sp,64
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002890:	0000e497          	auipc	s1,0xe
    80002894:	71048493          	addi	s1,s1,1808 # 80010fa0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002898:	4991                	li	s3,4
    {
      p->rtime++;
      p->Rtime++;
    }
    else if(p->state == RUNNABLE){
    8000289a:	4a0d                	li	s4,3
      p->wtime++;
    }
    else if(p->state == SLEEPING){
    8000289c:	4a89                	li	s5,2
  for (p = proc; p < &proc[NPROC]; p++)
    8000289e:	00015917          	auipc	s2,0x15
    800028a2:	b0290913          	addi	s2,s2,-1278 # 800173a0 <tickslock>
    800028a6:	a025                	j	800028ce <update_time+0x50>
      p->rtime++;
    800028a8:	1684a783          	lw	a5,360(s1)
    800028ac:	2785                	addiw	a5,a5,1
    800028ae:	16f4a423          	sw	a5,360(s1)
      p->Rtime++;
    800028b2:	1844a783          	lw	a5,388(s1)
    800028b6:	2785                	addiw	a5,a5,1
    800028b8:	18f4a223          	sw	a5,388(s1)
      p->stime++;
    }
    release(&p->lock);
    800028bc:	8526                	mv	a0,s1
    800028be:	ffffe097          	auipc	ra,0xffffe
    800028c2:	3cc080e7          	jalr	972(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028c6:	19048493          	addi	s1,s1,400
    800028ca:	03248a63          	beq	s1,s2,800028fe <update_time+0x80>
    acquire(&p->lock);
    800028ce:	8526                	mv	a0,s1
    800028d0:	ffffe097          	auipc	ra,0xffffe
    800028d4:	306080e7          	jalr	774(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    800028d8:	4c9c                	lw	a5,24(s1)
    800028da:	fd3787e3          	beq	a5,s3,800028a8 <update_time+0x2a>
    else if(p->state == RUNNABLE){
    800028de:	01478a63          	beq	a5,s4,800028f2 <update_time+0x74>
    else if(p->state == SLEEPING){
    800028e2:	fd579de3          	bne	a5,s5,800028bc <update_time+0x3e>
      p->stime++;
    800028e6:	1884a783          	lw	a5,392(s1)
    800028ea:	2785                	addiw	a5,a5,1
    800028ec:	18f4a423          	sw	a5,392(s1)
    800028f0:	b7f1                	j	800028bc <update_time+0x3e>
      p->wtime++;
    800028f2:	1804a783          	lw	a5,384(s1)
    800028f6:	2785                	addiw	a5,a5,1
    800028f8:	18f4a023          	sw	a5,384(s1)
    800028fc:	b7c1                	j	800028bc <update_time+0x3e>
  }
    800028fe:	70e2                	ld	ra,56(sp)
    80002900:	7442                	ld	s0,48(sp)
    80002902:	74a2                	ld	s1,40(sp)
    80002904:	7902                	ld	s2,32(sp)
    80002906:	69e2                	ld	s3,24(sp)
    80002908:	6a42                	ld	s4,16(sp)
    8000290a:	6aa2                	ld	s5,8(sp)
    8000290c:	6121                	addi	sp,sp,64
    8000290e:	8082                	ret

0000000080002910 <swtch>:
    80002910:	00153023          	sd	ra,0(a0)
    80002914:	00253423          	sd	sp,8(a0)
    80002918:	e900                	sd	s0,16(a0)
    8000291a:	ed04                	sd	s1,24(a0)
    8000291c:	03253023          	sd	s2,32(a0)
    80002920:	03353423          	sd	s3,40(a0)
    80002924:	03453823          	sd	s4,48(a0)
    80002928:	03553c23          	sd	s5,56(a0)
    8000292c:	05653023          	sd	s6,64(a0)
    80002930:	05753423          	sd	s7,72(a0)
    80002934:	05853823          	sd	s8,80(a0)
    80002938:	05953c23          	sd	s9,88(a0)
    8000293c:	07a53023          	sd	s10,96(a0)
    80002940:	07b53423          	sd	s11,104(a0)
    80002944:	0005b083          	ld	ra,0(a1)
    80002948:	0085b103          	ld	sp,8(a1)
    8000294c:	6980                	ld	s0,16(a1)
    8000294e:	6d84                	ld	s1,24(a1)
    80002950:	0205b903          	ld	s2,32(a1)
    80002954:	0285b983          	ld	s3,40(a1)
    80002958:	0305ba03          	ld	s4,48(a1)
    8000295c:	0385ba83          	ld	s5,56(a1)
    80002960:	0405bb03          	ld	s6,64(a1)
    80002964:	0485bb83          	ld	s7,72(a1)
    80002968:	0505bc03          	ld	s8,80(a1)
    8000296c:	0585bc83          	ld	s9,88(a1)
    80002970:	0605bd03          	ld	s10,96(a1)
    80002974:	0685bd83          	ld	s11,104(a1)
    80002978:	8082                	ret

000000008000297a <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    8000297a:	1141                	addi	sp,sp,-16
    8000297c:	e406                	sd	ra,8(sp)
    8000297e:	e022                	sd	s0,0(sp)
    80002980:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002982:	00006597          	auipc	a1,0x6
    80002986:	97e58593          	addi	a1,a1,-1666 # 80008300 <states.0+0x30>
    8000298a:	00015517          	auipc	a0,0x15
    8000298e:	a1650513          	addi	a0,a0,-1514 # 800173a0 <tickslock>
    80002992:	ffffe097          	auipc	ra,0xffffe
    80002996:	1b4080e7          	jalr	436(ra) # 80000b46 <initlock>
}
    8000299a:	60a2                	ld	ra,8(sp)
    8000299c:	6402                	ld	s0,0(sp)
    8000299e:	0141                	addi	sp,sp,16
    800029a0:	8082                	ret

00000000800029a2 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    800029a2:	1141                	addi	sp,sp,-16
    800029a4:	e422                	sd	s0,8(sp)
    800029a6:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029a8:	00003797          	auipc	a5,0x3
    800029ac:	65878793          	addi	a5,a5,1624 # 80006000 <kernelvec>
    800029b0:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800029b4:	6422                	ld	s0,8(sp)
    800029b6:	0141                	addi	sp,sp,16
    800029b8:	8082                	ret

00000000800029ba <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    800029ba:	1141                	addi	sp,sp,-16
    800029bc:	e406                	sd	ra,8(sp)
    800029be:	e022                	sd	s0,0(sp)
    800029c0:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800029c2:	fffff097          	auipc	ra,0xfffff
    800029c6:	fea080e7          	jalr	-22(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029ca:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800029ce:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800029d4:	00004697          	auipc	a3,0x4
    800029d8:	62c68693          	addi	a3,a3,1580 # 80007000 <_trampoline>
    800029dc:	00004717          	auipc	a4,0x4
    800029e0:	62470713          	addi	a4,a4,1572 # 80007000 <_trampoline>
    800029e4:	8f15                	sub	a4,a4,a3
    800029e6:	040007b7          	lui	a5,0x4000
    800029ea:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800029ec:	07b2                	slli	a5,a5,0xc
    800029ee:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800029f0:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800029f4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800029f6:	18002673          	csrr	a2,satp
    800029fa:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800029fc:	6d30                	ld	a2,88(a0)
    800029fe:	6138                	ld	a4,64(a0)
    80002a00:	6585                	lui	a1,0x1
    80002a02:	972e                	add	a4,a4,a1
    80002a04:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002a06:	6d38                	ld	a4,88(a0)
    80002a08:	00000617          	auipc	a2,0x0
    80002a0c:	13e60613          	addi	a2,a2,318 # 80002b46 <usertrap>
    80002a10:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002a12:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002a14:	8612                	mv	a2,tp
    80002a16:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a18:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002a1c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002a20:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a24:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002a28:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002a2a:	6f18                	ld	a4,24(a4)
    80002a2c:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002a30:	6928                	ld	a0,80(a0)
    80002a32:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002a34:	00004717          	auipc	a4,0x4
    80002a38:	66870713          	addi	a4,a4,1640 # 8000709c <userret>
    80002a3c:	8f15                	sub	a4,a4,a3
    80002a3e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002a40:	577d                	li	a4,-1
    80002a42:	177e                	slli	a4,a4,0x3f
    80002a44:	8d59                	or	a0,a0,a4
    80002a46:	9782                	jalr	a5
}
    80002a48:	60a2                	ld	ra,8(sp)
    80002a4a:	6402                	ld	s0,0(sp)
    80002a4c:	0141                	addi	sp,sp,16
    80002a4e:	8082                	ret

0000000080002a50 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002a50:	1101                	addi	sp,sp,-32
    80002a52:	ec06                	sd	ra,24(sp)
    80002a54:	e822                	sd	s0,16(sp)
    80002a56:	e426                	sd	s1,8(sp)
    80002a58:	e04a                	sd	s2,0(sp)
    80002a5a:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002a5c:	00015917          	auipc	s2,0x15
    80002a60:	94490913          	addi	s2,s2,-1724 # 800173a0 <tickslock>
    80002a64:	854a                	mv	a0,s2
    80002a66:	ffffe097          	auipc	ra,0xffffe
    80002a6a:	170080e7          	jalr	368(ra) # 80000bd6 <acquire>
  ticks++;
    80002a6e:	00006497          	auipc	s1,0x6
    80002a72:	e9248493          	addi	s1,s1,-366 # 80008900 <ticks>
    80002a76:	409c                	lw	a5,0(s1)
    80002a78:	2785                	addiw	a5,a5,1
    80002a7a:	c09c                	sw	a5,0(s1)
  update_time();
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	e02080e7          	jalr	-510(ra) # 8000287e <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80002a84:	8526                	mv	a0,s1
    80002a86:	fffff097          	auipc	ra,0xfffff
    80002a8a:	7a0080e7          	jalr	1952(ra) # 80002226 <wakeup>
  release(&tickslock);
    80002a8e:	854a                	mv	a0,s2
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	1fa080e7          	jalr	506(ra) # 80000c8a <release>
}
    80002a98:	60e2                	ld	ra,24(sp)
    80002a9a:	6442                	ld	s0,16(sp)
    80002a9c:	64a2                	ld	s1,8(sp)
    80002a9e:	6902                	ld	s2,0(sp)
    80002aa0:	6105                	addi	sp,sp,32
    80002aa2:	8082                	ret

0000000080002aa4 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002aa4:	1101                	addi	sp,sp,-32
    80002aa6:	ec06                	sd	ra,24(sp)
    80002aa8:	e822                	sd	s0,16(sp)
    80002aaa:	e426                	sd	s1,8(sp)
    80002aac:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002aae:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002ab2:	00074d63          	bltz	a4,80002acc <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002ab6:	57fd                	li	a5,-1
    80002ab8:	17fe                	slli	a5,a5,0x3f
    80002aba:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002abc:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002abe:	06f70363          	beq	a4,a5,80002b24 <devintr+0x80>
  }
}
    80002ac2:	60e2                	ld	ra,24(sp)
    80002ac4:	6442                	ld	s0,16(sp)
    80002ac6:	64a2                	ld	s1,8(sp)
    80002ac8:	6105                	addi	sp,sp,32
    80002aca:	8082                	ret
      (scause & 0xff) == 9)
    80002acc:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80002ad0:	46a5                	li	a3,9
    80002ad2:	fed792e3          	bne	a5,a3,80002ab6 <devintr+0x12>
    int irq = plic_claim();
    80002ad6:	00003097          	auipc	ra,0x3
    80002ada:	632080e7          	jalr	1586(ra) # 80006108 <plic_claim>
    80002ade:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002ae0:	47a9                	li	a5,10
    80002ae2:	02f50763          	beq	a0,a5,80002b10 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002ae6:	4785                	li	a5,1
    80002ae8:	02f50963          	beq	a0,a5,80002b1a <devintr+0x76>
    return 1;
    80002aec:	4505                	li	a0,1
    else if (irq)
    80002aee:	d8f1                	beqz	s1,80002ac2 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002af0:	85a6                	mv	a1,s1
    80002af2:	00006517          	auipc	a0,0x6
    80002af6:	81650513          	addi	a0,a0,-2026 # 80008308 <states.0+0x38>
    80002afa:	ffffe097          	auipc	ra,0xffffe
    80002afe:	a90080e7          	jalr	-1392(ra) # 8000058a <printf>
      plic_complete(irq);
    80002b02:	8526                	mv	a0,s1
    80002b04:	00003097          	auipc	ra,0x3
    80002b08:	628080e7          	jalr	1576(ra) # 8000612c <plic_complete>
    return 1;
    80002b0c:	4505                	li	a0,1
    80002b0e:	bf55                	j	80002ac2 <devintr+0x1e>
      uartintr();
    80002b10:	ffffe097          	auipc	ra,0xffffe
    80002b14:	e88080e7          	jalr	-376(ra) # 80000998 <uartintr>
    80002b18:	b7ed                	j	80002b02 <devintr+0x5e>
      virtio_disk_intr();
    80002b1a:	00004097          	auipc	ra,0x4
    80002b1e:	ada080e7          	jalr	-1318(ra) # 800065f4 <virtio_disk_intr>
    80002b22:	b7c5                	j	80002b02 <devintr+0x5e>
    if (cpuid() == 0)
    80002b24:	fffff097          	auipc	ra,0xfffff
    80002b28:	e5c080e7          	jalr	-420(ra) # 80001980 <cpuid>
    80002b2c:	c901                	beqz	a0,80002b3c <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002b2e:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002b32:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002b34:	14479073          	csrw	sip,a5
    return 2;
    80002b38:	4509                	li	a0,2
    80002b3a:	b761                	j	80002ac2 <devintr+0x1e>
      clockintr();
    80002b3c:	00000097          	auipc	ra,0x0
    80002b40:	f14080e7          	jalr	-236(ra) # 80002a50 <clockintr>
    80002b44:	b7ed                	j	80002b2e <devintr+0x8a>

0000000080002b46 <usertrap>:
{
    80002b46:	1101                	addi	sp,sp,-32
    80002b48:	ec06                	sd	ra,24(sp)
    80002b4a:	e822                	sd	s0,16(sp)
    80002b4c:	e426                	sd	s1,8(sp)
    80002b4e:	e04a                	sd	s2,0(sp)
    80002b50:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b52:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80002b56:	1007f793          	andi	a5,a5,256
    80002b5a:	e3b1                	bnez	a5,80002b9e <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002b5c:	00003797          	auipc	a5,0x3
    80002b60:	4a478793          	addi	a5,a5,1188 # 80006000 <kernelvec>
    80002b64:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002b68:	fffff097          	auipc	ra,0xfffff
    80002b6c:	e44080e7          	jalr	-444(ra) # 800019ac <myproc>
    80002b70:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002b72:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b74:	14102773          	csrr	a4,sepc
    80002b78:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b7a:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80002b7e:	47a1                	li	a5,8
    80002b80:	02f70763          	beq	a4,a5,80002bae <usertrap+0x68>
  else if ((which_dev = devintr()) != 0)
    80002b84:	00000097          	auipc	ra,0x0
    80002b88:	f20080e7          	jalr	-224(ra) # 80002aa4 <devintr>
    80002b8c:	892a                	mv	s2,a0
    80002b8e:	c151                	beqz	a0,80002c12 <usertrap+0xcc>
  if (killed(p))
    80002b90:	8526                	mv	a0,s1
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	8e4080e7          	jalr	-1820(ra) # 80002476 <killed>
    80002b9a:	c929                	beqz	a0,80002bec <usertrap+0xa6>
    80002b9c:	a099                	j	80002be2 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002b9e:	00005517          	auipc	a0,0x5
    80002ba2:	78a50513          	addi	a0,a0,1930 # 80008328 <states.0+0x58>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	99a080e7          	jalr	-1638(ra) # 80000540 <panic>
    if (killed(p))
    80002bae:	00000097          	auipc	ra,0x0
    80002bb2:	8c8080e7          	jalr	-1848(ra) # 80002476 <killed>
    80002bb6:	e921                	bnez	a0,80002c06 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002bb8:	6cb8                	ld	a4,88(s1)
    80002bba:	6f1c                	ld	a5,24(a4)
    80002bbc:	0791                	addi	a5,a5,4
    80002bbe:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002bc0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002bc4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002bc8:	10079073          	csrw	sstatus,a5
    syscall();
    80002bcc:	00000097          	auipc	ra,0x0
    80002bd0:	2d4080e7          	jalr	724(ra) # 80002ea0 <syscall>
  if (killed(p))
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	00000097          	auipc	ra,0x0
    80002bda:	8a0080e7          	jalr	-1888(ra) # 80002476 <killed>
    80002bde:	c911                	beqz	a0,80002bf2 <usertrap+0xac>
    80002be0:	4901                	li	s2,0
    exit(-1);
    80002be2:	557d                	li	a0,-1
    80002be4:	fffff097          	auipc	ra,0xfffff
    80002be8:	712080e7          	jalr	1810(ra) # 800022f6 <exit>
  if (which_dev == 2)
    80002bec:	4789                	li	a5,2
    80002bee:	04f90f63          	beq	s2,a5,80002c4c <usertrap+0x106>
  usertrapret();
    80002bf2:	00000097          	auipc	ra,0x0
    80002bf6:	dc8080e7          	jalr	-568(ra) # 800029ba <usertrapret>
}
    80002bfa:	60e2                	ld	ra,24(sp)
    80002bfc:	6442                	ld	s0,16(sp)
    80002bfe:	64a2                	ld	s1,8(sp)
    80002c00:	6902                	ld	s2,0(sp)
    80002c02:	6105                	addi	sp,sp,32
    80002c04:	8082                	ret
      exit(-1);
    80002c06:	557d                	li	a0,-1
    80002c08:	fffff097          	auipc	ra,0xfffff
    80002c0c:	6ee080e7          	jalr	1774(ra) # 800022f6 <exit>
    80002c10:	b765                	j	80002bb8 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c12:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c16:	5890                	lw	a2,48(s1)
    80002c18:	00005517          	auipc	a0,0x5
    80002c1c:	73050513          	addi	a0,a0,1840 # 80008348 <states.0+0x78>
    80002c20:	ffffe097          	auipc	ra,0xffffe
    80002c24:	96a080e7          	jalr	-1686(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c28:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c2c:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c30:	00005517          	auipc	a0,0x5
    80002c34:	74850513          	addi	a0,a0,1864 # 80008378 <states.0+0xa8>
    80002c38:	ffffe097          	auipc	ra,0xffffe
    80002c3c:	952080e7          	jalr	-1710(ra) # 8000058a <printf>
    setkilled(p);
    80002c40:	8526                	mv	a0,s1
    80002c42:	00000097          	auipc	ra,0x0
    80002c46:	808080e7          	jalr	-2040(ra) # 8000244a <setkilled>
    80002c4a:	b769                	j	80002bd4 <usertrap+0x8e>
    yield();
    80002c4c:	fffff097          	auipc	ra,0xfffff
    80002c50:	53a080e7          	jalr	1338(ra) # 80002186 <yield>
    80002c54:	bf79                	j	80002bf2 <usertrap+0xac>

0000000080002c56 <kerneltrap>:
{
    80002c56:	7179                	addi	sp,sp,-48
    80002c58:	f406                	sd	ra,40(sp)
    80002c5a:	f022                	sd	s0,32(sp)
    80002c5c:	ec26                	sd	s1,24(sp)
    80002c5e:	e84a                	sd	s2,16(sp)
    80002c60:	e44e                	sd	s3,8(sp)
    80002c62:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c64:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c68:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c6c:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    80002c70:	1004f793          	andi	a5,s1,256
    80002c74:	cb85                	beqz	a5,80002ca4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c76:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c7a:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    80002c7c:	ef85                	bnez	a5,80002cb4 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    80002c7e:	00000097          	auipc	ra,0x0
    80002c82:	e26080e7          	jalr	-474(ra) # 80002aa4 <devintr>
    80002c86:	cd1d                	beqz	a0,80002cc4 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c88:	4789                	li	a5,2
    80002c8a:	06f50a63          	beq	a0,a5,80002cfe <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c8e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002c92:	10049073          	csrw	sstatus,s1
}
    80002c96:	70a2                	ld	ra,40(sp)
    80002c98:	7402                	ld	s0,32(sp)
    80002c9a:	64e2                	ld	s1,24(sp)
    80002c9c:	6942                	ld	s2,16(sp)
    80002c9e:	69a2                	ld	s3,8(sp)
    80002ca0:	6145                	addi	sp,sp,48
    80002ca2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002ca4:	00005517          	auipc	a0,0x5
    80002ca8:	6f450513          	addi	a0,a0,1780 # 80008398 <states.0+0xc8>
    80002cac:	ffffe097          	auipc	ra,0xffffe
    80002cb0:	894080e7          	jalr	-1900(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	70c50513          	addi	a0,a0,1804 # 800083c0 <states.0+0xf0>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	884080e7          	jalr	-1916(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002cc4:	85ce                	mv	a1,s3
    80002cc6:	00005517          	auipc	a0,0x5
    80002cca:	71a50513          	addi	a0,a0,1818 # 800083e0 <states.0+0x110>
    80002cce:	ffffe097          	auipc	ra,0xffffe
    80002cd2:	8bc080e7          	jalr	-1860(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002cd6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cda:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cde:	00005517          	auipc	a0,0x5
    80002ce2:	71250513          	addi	a0,a0,1810 # 800083f0 <states.0+0x120>
    80002ce6:	ffffe097          	auipc	ra,0xffffe
    80002cea:	8a4080e7          	jalr	-1884(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	71a50513          	addi	a0,a0,1818 # 80008408 <states.0+0x138>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	84a080e7          	jalr	-1974(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002cfe:	fffff097          	auipc	ra,0xfffff
    80002d02:	cae080e7          	jalr	-850(ra) # 800019ac <myproc>
    80002d06:	d541                	beqz	a0,80002c8e <kerneltrap+0x38>
    80002d08:	fffff097          	auipc	ra,0xfffff
    80002d0c:	ca4080e7          	jalr	-860(ra) # 800019ac <myproc>
    80002d10:	4d18                	lw	a4,24(a0)
    80002d12:	4791                	li	a5,4
    80002d14:	f6f71de3          	bne	a4,a5,80002c8e <kerneltrap+0x38>
    yield();
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	46e080e7          	jalr	1134(ra) # 80002186 <yield>
    80002d20:	b7bd                	j	80002c8e <kerneltrap+0x38>

0000000080002d22 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d22:	1101                	addi	sp,sp,-32
    80002d24:	ec06                	sd	ra,24(sp)
    80002d26:	e822                	sd	s0,16(sp)
    80002d28:	e426                	sd	s1,8(sp)
    80002d2a:	1000                	addi	s0,sp,32
    80002d2c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d2e:	fffff097          	auipc	ra,0xfffff
    80002d32:	c7e080e7          	jalr	-898(ra) # 800019ac <myproc>
  switch (n) {
    80002d36:	4795                	li	a5,5
    80002d38:	0497e163          	bltu	a5,s1,80002d7a <argraw+0x58>
    80002d3c:	048a                	slli	s1,s1,0x2
    80002d3e:	00005717          	auipc	a4,0x5
    80002d42:	70270713          	addi	a4,a4,1794 # 80008440 <states.0+0x170>
    80002d46:	94ba                	add	s1,s1,a4
    80002d48:	409c                	lw	a5,0(s1)
    80002d4a:	97ba                	add	a5,a5,a4
    80002d4c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d4e:	6d3c                	ld	a5,88(a0)
    80002d50:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d52:	60e2                	ld	ra,24(sp)
    80002d54:	6442                	ld	s0,16(sp)
    80002d56:	64a2                	ld	s1,8(sp)
    80002d58:	6105                	addi	sp,sp,32
    80002d5a:	8082                	ret
    return p->trapframe->a1;
    80002d5c:	6d3c                	ld	a5,88(a0)
    80002d5e:	7fa8                	ld	a0,120(a5)
    80002d60:	bfcd                	j	80002d52 <argraw+0x30>
    return p->trapframe->a2;
    80002d62:	6d3c                	ld	a5,88(a0)
    80002d64:	63c8                	ld	a0,128(a5)
    80002d66:	b7f5                	j	80002d52 <argraw+0x30>
    return p->trapframe->a3;
    80002d68:	6d3c                	ld	a5,88(a0)
    80002d6a:	67c8                	ld	a0,136(a5)
    80002d6c:	b7dd                	j	80002d52 <argraw+0x30>
    return p->trapframe->a4;
    80002d6e:	6d3c                	ld	a5,88(a0)
    80002d70:	6bc8                	ld	a0,144(a5)
    80002d72:	b7c5                	j	80002d52 <argraw+0x30>
    return p->trapframe->a5;
    80002d74:	6d3c                	ld	a5,88(a0)
    80002d76:	6fc8                	ld	a0,152(a5)
    80002d78:	bfe9                	j	80002d52 <argraw+0x30>
  panic("argraw");
    80002d7a:	00005517          	auipc	a0,0x5
    80002d7e:	69e50513          	addi	a0,a0,1694 # 80008418 <states.0+0x148>
    80002d82:	ffffd097          	auipc	ra,0xffffd
    80002d86:	7be080e7          	jalr	1982(ra) # 80000540 <panic>

0000000080002d8a <fetchaddr>:
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	e04a                	sd	s2,0(sp)
    80002d94:	1000                	addi	s0,sp,32
    80002d96:	84aa                	mv	s1,a0
    80002d98:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002d9a:	fffff097          	auipc	ra,0xfffff
    80002d9e:	c12080e7          	jalr	-1006(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002da2:	653c                	ld	a5,72(a0)
    80002da4:	02f4f863          	bgeu	s1,a5,80002dd4 <fetchaddr+0x4a>
    80002da8:	00848713          	addi	a4,s1,8
    80002dac:	02e7e663          	bltu	a5,a4,80002dd8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002db0:	46a1                	li	a3,8
    80002db2:	8626                	mv	a2,s1
    80002db4:	85ca                	mv	a1,s2
    80002db6:	6928                	ld	a0,80(a0)
    80002db8:	fffff097          	auipc	ra,0xfffff
    80002dbc:	940080e7          	jalr	-1728(ra) # 800016f8 <copyin>
    80002dc0:	00a03533          	snez	a0,a0
    80002dc4:	40a00533          	neg	a0,a0
}
    80002dc8:	60e2                	ld	ra,24(sp)
    80002dca:	6442                	ld	s0,16(sp)
    80002dcc:	64a2                	ld	s1,8(sp)
    80002dce:	6902                	ld	s2,0(sp)
    80002dd0:	6105                	addi	sp,sp,32
    80002dd2:	8082                	ret
    return -1;
    80002dd4:	557d                	li	a0,-1
    80002dd6:	bfcd                	j	80002dc8 <fetchaddr+0x3e>
    80002dd8:	557d                	li	a0,-1
    80002dda:	b7fd                	j	80002dc8 <fetchaddr+0x3e>

0000000080002ddc <fetchstr>:
{
    80002ddc:	7179                	addi	sp,sp,-48
    80002dde:	f406                	sd	ra,40(sp)
    80002de0:	f022                	sd	s0,32(sp)
    80002de2:	ec26                	sd	s1,24(sp)
    80002de4:	e84a                	sd	s2,16(sp)
    80002de6:	e44e                	sd	s3,8(sp)
    80002de8:	1800                	addi	s0,sp,48
    80002dea:	892a                	mv	s2,a0
    80002dec:	84ae                	mv	s1,a1
    80002dee:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002df0:	fffff097          	auipc	ra,0xfffff
    80002df4:	bbc080e7          	jalr	-1092(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002df8:	86ce                	mv	a3,s3
    80002dfa:	864a                	mv	a2,s2
    80002dfc:	85a6                	mv	a1,s1
    80002dfe:	6928                	ld	a0,80(a0)
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	986080e7          	jalr	-1658(ra) # 80001786 <copyinstr>
    80002e08:	00054e63          	bltz	a0,80002e24 <fetchstr+0x48>
  return strlen(buf);
    80002e0c:	8526                	mv	a0,s1
    80002e0e:	ffffe097          	auipc	ra,0xffffe
    80002e12:	040080e7          	jalr	64(ra) # 80000e4e <strlen>
}
    80002e16:	70a2                	ld	ra,40(sp)
    80002e18:	7402                	ld	s0,32(sp)
    80002e1a:	64e2                	ld	s1,24(sp)
    80002e1c:	6942                	ld	s2,16(sp)
    80002e1e:	69a2                	ld	s3,8(sp)
    80002e20:	6145                	addi	sp,sp,48
    80002e22:	8082                	ret
    return -1;
    80002e24:	557d                	li	a0,-1
    80002e26:	bfc5                	j	80002e16 <fetchstr+0x3a>

0000000080002e28 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002e28:	1101                	addi	sp,sp,-32
    80002e2a:	ec06                	sd	ra,24(sp)
    80002e2c:	e822                	sd	s0,16(sp)
    80002e2e:	e426                	sd	s1,8(sp)
    80002e30:	1000                	addi	s0,sp,32
    80002e32:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e34:	00000097          	auipc	ra,0x0
    80002e38:	eee080e7          	jalr	-274(ra) # 80002d22 <argraw>
    80002e3c:	c088                	sw	a0,0(s1)
}
    80002e3e:	60e2                	ld	ra,24(sp)
    80002e40:	6442                	ld	s0,16(sp)
    80002e42:	64a2                	ld	s1,8(sp)
    80002e44:	6105                	addi	sp,sp,32
    80002e46:	8082                	ret

0000000080002e48 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002e48:	1101                	addi	sp,sp,-32
    80002e4a:	ec06                	sd	ra,24(sp)
    80002e4c:	e822                	sd	s0,16(sp)
    80002e4e:	e426                	sd	s1,8(sp)
    80002e50:	1000                	addi	s0,sp,32
    80002e52:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e54:	00000097          	auipc	ra,0x0
    80002e58:	ece080e7          	jalr	-306(ra) # 80002d22 <argraw>
    80002e5c:	e088                	sd	a0,0(s1)
}
    80002e5e:	60e2                	ld	ra,24(sp)
    80002e60:	6442                	ld	s0,16(sp)
    80002e62:	64a2                	ld	s1,8(sp)
    80002e64:	6105                	addi	sp,sp,32
    80002e66:	8082                	ret

0000000080002e68 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e68:	7179                	addi	sp,sp,-48
    80002e6a:	f406                	sd	ra,40(sp)
    80002e6c:	f022                	sd	s0,32(sp)
    80002e6e:	ec26                	sd	s1,24(sp)
    80002e70:	e84a                	sd	s2,16(sp)
    80002e72:	1800                	addi	s0,sp,48
    80002e74:	84ae                	mv	s1,a1
    80002e76:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002e78:	fd840593          	addi	a1,s0,-40
    80002e7c:	00000097          	auipc	ra,0x0
    80002e80:	fcc080e7          	jalr	-52(ra) # 80002e48 <argaddr>
  return fetchstr(addr, buf, max);
    80002e84:	864a                	mv	a2,s2
    80002e86:	85a6                	mv	a1,s1
    80002e88:	fd843503          	ld	a0,-40(s0)
    80002e8c:	00000097          	auipc	ra,0x0
    80002e90:	f50080e7          	jalr	-176(ra) # 80002ddc <fetchstr>
}
    80002e94:	70a2                	ld	ra,40(sp)
    80002e96:	7402                	ld	s0,32(sp)
    80002e98:	64e2                	ld	s1,24(sp)
    80002e9a:	6942                	ld	s2,16(sp)
    80002e9c:	6145                	addi	sp,sp,48
    80002e9e:	8082                	ret

0000000080002ea0 <syscall>:
[SYS_setpriority] sys_setpriority
};

void
syscall(void)
{
    80002ea0:	1101                	addi	sp,sp,-32
    80002ea2:	ec06                	sd	ra,24(sp)
    80002ea4:	e822                	sd	s0,16(sp)
    80002ea6:	e426                	sd	s1,8(sp)
    80002ea8:	e04a                	sd	s2,0(sp)
    80002eaa:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002eac:	fffff097          	auipc	ra,0xfffff
    80002eb0:	b00080e7          	jalr	-1280(ra) # 800019ac <myproc>
    80002eb4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002eb6:	05853903          	ld	s2,88(a0)
    80002eba:	0a893783          	ld	a5,168(s2)
    80002ebe:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002ec2:	37fd                	addiw	a5,a5,-1
    80002ec4:	475d                	li	a4,23
    80002ec6:	00f76f63          	bltu	a4,a5,80002ee4 <syscall+0x44>
    80002eca:	00369713          	slli	a4,a3,0x3
    80002ece:	00005797          	auipc	a5,0x5
    80002ed2:	58a78793          	addi	a5,a5,1418 # 80008458 <syscalls>
    80002ed6:	97ba                	add	a5,a5,a4
    80002ed8:	639c                	ld	a5,0(a5)
    80002eda:	c789                	beqz	a5,80002ee4 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002edc:	9782                	jalr	a5
    80002ede:	06a93823          	sd	a0,112(s2)
    80002ee2:	a839                	j	80002f00 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002ee4:	15848613          	addi	a2,s1,344
    80002ee8:	588c                	lw	a1,48(s1)
    80002eea:	00005517          	auipc	a0,0x5
    80002eee:	53650513          	addi	a0,a0,1334 # 80008420 <states.0+0x150>
    80002ef2:	ffffd097          	auipc	ra,0xffffd
    80002ef6:	698080e7          	jalr	1688(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002efa:	6cbc                	ld	a5,88(s1)
    80002efc:	577d                	li	a4,-1
    80002efe:	fbb8                	sd	a4,112(a5)
  }
}
    80002f00:	60e2                	ld	ra,24(sp)
    80002f02:	6442                	ld	s0,16(sp)
    80002f04:	64a2                	ld	s1,8(sp)
    80002f06:	6902                	ld	s2,0(sp)
    80002f08:	6105                	addi	sp,sp,32
    80002f0a:	8082                	ret

0000000080002f0c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f0c:	1101                	addi	sp,sp,-32
    80002f0e:	ec06                	sd	ra,24(sp)
    80002f10:	e822                	sd	s0,16(sp)
    80002f12:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002f14:	fec40593          	addi	a1,s0,-20
    80002f18:	4501                	li	a0,0
    80002f1a:	00000097          	auipc	ra,0x0
    80002f1e:	f0e080e7          	jalr	-242(ra) # 80002e28 <argint>
  exit(n);
    80002f22:	fec42503          	lw	a0,-20(s0)
    80002f26:	fffff097          	auipc	ra,0xfffff
    80002f2a:	3d0080e7          	jalr	976(ra) # 800022f6 <exit>
  return 0; // not reached
}
    80002f2e:	4501                	li	a0,0
    80002f30:	60e2                	ld	ra,24(sp)
    80002f32:	6442                	ld	s0,16(sp)
    80002f34:	6105                	addi	sp,sp,32
    80002f36:	8082                	ret

0000000080002f38 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f38:	1141                	addi	sp,sp,-16
    80002f3a:	e406                	sd	ra,8(sp)
    80002f3c:	e022                	sd	s0,0(sp)
    80002f3e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f40:	fffff097          	auipc	ra,0xfffff
    80002f44:	a6c080e7          	jalr	-1428(ra) # 800019ac <myproc>
}
    80002f48:	5908                	lw	a0,48(a0)
    80002f4a:	60a2                	ld	ra,8(sp)
    80002f4c:	6402                	ld	s0,0(sp)
    80002f4e:	0141                	addi	sp,sp,16
    80002f50:	8082                	ret

0000000080002f52 <sys_fork>:

uint64
sys_fork(void)
{
    80002f52:	1141                	addi	sp,sp,-16
    80002f54:	e406                	sd	ra,8(sp)
    80002f56:	e022                	sd	s0,0(sp)
    80002f58:	0800                	addi	s0,sp,16
  return fork();
    80002f5a:	fffff097          	auipc	ra,0xfffff
    80002f5e:	e42080e7          	jalr	-446(ra) # 80001d9c <fork>
}
    80002f62:	60a2                	ld	ra,8(sp)
    80002f64:	6402                	ld	s0,0(sp)
    80002f66:	0141                	addi	sp,sp,16
    80002f68:	8082                	ret

0000000080002f6a <sys_wait>:

uint64
sys_wait(void)
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002f72:	fe840593          	addi	a1,s0,-24
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	ed0080e7          	jalr	-304(ra) # 80002e48 <argaddr>
  return wait(p);
    80002f80:	fe843503          	ld	a0,-24(s0)
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	524080e7          	jalr	1316(ra) # 800024a8 <wait>
}
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002f94:	7179                	addi	sp,sp,-48
    80002f96:	f406                	sd	ra,40(sp)
    80002f98:	f022                	sd	s0,32(sp)
    80002f9a:	ec26                	sd	s1,24(sp)
    80002f9c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002f9e:	fdc40593          	addi	a1,s0,-36
    80002fa2:	4501                	li	a0,0
    80002fa4:	00000097          	auipc	ra,0x0
    80002fa8:	e84080e7          	jalr	-380(ra) # 80002e28 <argint>
  addr = myproc()->sz;
    80002fac:	fffff097          	auipc	ra,0xfffff
    80002fb0:	a00080e7          	jalr	-1536(ra) # 800019ac <myproc>
    80002fb4:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80002fb6:	fdc42503          	lw	a0,-36(s0)
    80002fba:	fffff097          	auipc	ra,0xfffff
    80002fbe:	d86080e7          	jalr	-634(ra) # 80001d40 <growproc>
    80002fc2:	00054863          	bltz	a0,80002fd2 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002fc6:	8526                	mv	a0,s1
    80002fc8:	70a2                	ld	ra,40(sp)
    80002fca:	7402                	ld	s0,32(sp)
    80002fcc:	64e2                	ld	s1,24(sp)
    80002fce:	6145                	addi	sp,sp,48
    80002fd0:	8082                	ret
    return -1;
    80002fd2:	54fd                	li	s1,-1
    80002fd4:	bfcd                	j	80002fc6 <sys_sbrk+0x32>

0000000080002fd6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002fd6:	7139                	addi	sp,sp,-64
    80002fd8:	fc06                	sd	ra,56(sp)
    80002fda:	f822                	sd	s0,48(sp)
    80002fdc:	f426                	sd	s1,40(sp)
    80002fde:	f04a                	sd	s2,32(sp)
    80002fe0:	ec4e                	sd	s3,24(sp)
    80002fe2:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002fe4:	fcc40593          	addi	a1,s0,-52
    80002fe8:	4501                	li	a0,0
    80002fea:	00000097          	auipc	ra,0x0
    80002fee:	e3e080e7          	jalr	-450(ra) # 80002e28 <argint>
  acquire(&tickslock);
    80002ff2:	00014517          	auipc	a0,0x14
    80002ff6:	3ae50513          	addi	a0,a0,942 # 800173a0 <tickslock>
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	bdc080e7          	jalr	-1060(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003002:	00006917          	auipc	s2,0x6
    80003006:	8fe92903          	lw	s2,-1794(s2) # 80008900 <ticks>
  while (ticks - ticks0 < n)
    8000300a:	fcc42783          	lw	a5,-52(s0)
    8000300e:	cf9d                	beqz	a5,8000304c <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003010:	00014997          	auipc	s3,0x14
    80003014:	39098993          	addi	s3,s3,912 # 800173a0 <tickslock>
    80003018:	00006497          	auipc	s1,0x6
    8000301c:	8e848493          	addi	s1,s1,-1816 # 80008900 <ticks>
    if (killed(myproc()))
    80003020:	fffff097          	auipc	ra,0xfffff
    80003024:	98c080e7          	jalr	-1652(ra) # 800019ac <myproc>
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	44e080e7          	jalr	1102(ra) # 80002476 <killed>
    80003030:	ed15                	bnez	a0,8000306c <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003032:	85ce                	mv	a1,s3
    80003034:	8526                	mv	a0,s1
    80003036:	fffff097          	auipc	ra,0xfffff
    8000303a:	18c080e7          	jalr	396(ra) # 800021c2 <sleep>
  while (ticks - ticks0 < n)
    8000303e:	409c                	lw	a5,0(s1)
    80003040:	412787bb          	subw	a5,a5,s2
    80003044:	fcc42703          	lw	a4,-52(s0)
    80003048:	fce7ece3          	bltu	a5,a4,80003020 <sys_sleep+0x4a>
  }
  release(&tickslock);
    8000304c:	00014517          	auipc	a0,0x14
    80003050:	35450513          	addi	a0,a0,852 # 800173a0 <tickslock>
    80003054:	ffffe097          	auipc	ra,0xffffe
    80003058:	c36080e7          	jalr	-970(ra) # 80000c8a <release>
  return 0;
    8000305c:	4501                	li	a0,0
}
    8000305e:	70e2                	ld	ra,56(sp)
    80003060:	7442                	ld	s0,48(sp)
    80003062:	74a2                	ld	s1,40(sp)
    80003064:	7902                	ld	s2,32(sp)
    80003066:	69e2                	ld	s3,24(sp)
    80003068:	6121                	addi	sp,sp,64
    8000306a:	8082                	ret
      release(&tickslock);
    8000306c:	00014517          	auipc	a0,0x14
    80003070:	33450513          	addi	a0,a0,820 # 800173a0 <tickslock>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	c16080e7          	jalr	-1002(ra) # 80000c8a <release>
      return -1;
    8000307c:	557d                	li	a0,-1
    8000307e:	b7c5                	j	8000305e <sys_sleep+0x88>

0000000080003080 <sys_kill>:

uint64
sys_kill(void)
{
    80003080:	1101                	addi	sp,sp,-32
    80003082:	ec06                	sd	ra,24(sp)
    80003084:	e822                	sd	s0,16(sp)
    80003086:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003088:	fec40593          	addi	a1,s0,-20
    8000308c:	4501                	li	a0,0
    8000308e:	00000097          	auipc	ra,0x0
    80003092:	d9a080e7          	jalr	-614(ra) # 80002e28 <argint>
  return kill(pid);
    80003096:	fec42503          	lw	a0,-20(s0)
    8000309a:	fffff097          	auipc	ra,0xfffff
    8000309e:	33e080e7          	jalr	830(ra) # 800023d8 <kill>
}
    800030a2:	60e2                	ld	ra,24(sp)
    800030a4:	6442                	ld	s0,16(sp)
    800030a6:	6105                	addi	sp,sp,32
    800030a8:	8082                	ret

00000000800030aa <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030aa:	1101                	addi	sp,sp,-32
    800030ac:	ec06                	sd	ra,24(sp)
    800030ae:	e822                	sd	s0,16(sp)
    800030b0:	e426                	sd	s1,8(sp)
    800030b2:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030b4:	00014517          	auipc	a0,0x14
    800030b8:	2ec50513          	addi	a0,a0,748 # 800173a0 <tickslock>
    800030bc:	ffffe097          	auipc	ra,0xffffe
    800030c0:	b1a080e7          	jalr	-1254(ra) # 80000bd6 <acquire>
  xticks = ticks;
    800030c4:	00006497          	auipc	s1,0x6
    800030c8:	83c4a483          	lw	s1,-1988(s1) # 80008900 <ticks>
  release(&tickslock);
    800030cc:	00014517          	auipc	a0,0x14
    800030d0:	2d450513          	addi	a0,a0,724 # 800173a0 <tickslock>
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	bb6080e7          	jalr	-1098(ra) # 80000c8a <release>
  return xticks;
}
    800030dc:	02049513          	slli	a0,s1,0x20
    800030e0:	9101                	srli	a0,a0,0x20
    800030e2:	60e2                	ld	ra,24(sp)
    800030e4:	6442                	ld	s0,16(sp)
    800030e6:	64a2                	ld	s1,8(sp)
    800030e8:	6105                	addi	sp,sp,32
    800030ea:	8082                	ret

00000000800030ec <sys_waitx>:

uint64
sys_waitx(void)
{
    800030ec:	7139                	addi	sp,sp,-64
    800030ee:	fc06                	sd	ra,56(sp)
    800030f0:	f822                	sd	s0,48(sp)
    800030f2:	f426                	sd	s1,40(sp)
    800030f4:	f04a                	sd	s2,32(sp)
    800030f6:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800030f8:	fd840593          	addi	a1,s0,-40
    800030fc:	4501                	li	a0,0
    800030fe:	00000097          	auipc	ra,0x0
    80003102:	d4a080e7          	jalr	-694(ra) # 80002e48 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003106:	fd040593          	addi	a1,s0,-48
    8000310a:	4505                	li	a0,1
    8000310c:	00000097          	auipc	ra,0x0
    80003110:	d3c080e7          	jalr	-708(ra) # 80002e48 <argaddr>
  argaddr(2, &addr2);
    80003114:	fc840593          	addi	a1,s0,-56
    80003118:	4509                	li	a0,2
    8000311a:	00000097          	auipc	ra,0x0
    8000311e:	d2e080e7          	jalr	-722(ra) # 80002e48 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003122:	fc040613          	addi	a2,s0,-64
    80003126:	fc440593          	addi	a1,s0,-60
    8000312a:	fd843503          	ld	a0,-40(s0)
    8000312e:	fffff097          	auipc	ra,0xfffff
    80003132:	604080e7          	jalr	1540(ra) # 80002732 <waitx>
    80003136:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003138:	fffff097          	auipc	ra,0xfffff
    8000313c:	874080e7          	jalr	-1932(ra) # 800019ac <myproc>
    80003140:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003142:	4691                	li	a3,4
    80003144:	fc440613          	addi	a2,s0,-60
    80003148:	fd043583          	ld	a1,-48(s0)
    8000314c:	6928                	ld	a0,80(a0)
    8000314e:	ffffe097          	auipc	ra,0xffffe
    80003152:	51e080e7          	jalr	1310(ra) # 8000166c <copyout>
    return -1;
    80003156:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003158:	00054f63          	bltz	a0,80003176 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    8000315c:	4691                	li	a3,4
    8000315e:	fc040613          	addi	a2,s0,-64
    80003162:	fc843583          	ld	a1,-56(s0)
    80003166:	68a8                	ld	a0,80(s1)
    80003168:	ffffe097          	auipc	ra,0xffffe
    8000316c:	504080e7          	jalr	1284(ra) # 8000166c <copyout>
    80003170:	00054a63          	bltz	a0,80003184 <sys_waitx+0x98>
    return -1;
  return ret;
    80003174:	87ca                	mv	a5,s2
}
    80003176:	853e                	mv	a0,a5
    80003178:	70e2                	ld	ra,56(sp)
    8000317a:	7442                	ld	s0,48(sp)
    8000317c:	74a2                	ld	s1,40(sp)
    8000317e:	7902                	ld	s2,32(sp)
    80003180:	6121                	addi	sp,sp,64
    80003182:	8082                	ret
    return -1;
    80003184:	57fd                	li	a5,-1
    80003186:	bfc5                	j	80003176 <sys_waitx+0x8a>

0000000080003188 <sys_setpriority>:

uint64
sys_setpriority(void){
    80003188:	1101                	addi	sp,sp,-32
    8000318a:	ec06                	sd	ra,24(sp)
    8000318c:	e822                	sd	s0,16(sp)
    8000318e:	1000                	addi	s0,sp,32
  int pid, new_priority;
  argint(0, &pid);
    80003190:	fec40593          	addi	a1,s0,-20
    80003194:	4501                	li	a0,0
    80003196:	00000097          	auipc	ra,0x0
    8000319a:	c92080e7          	jalr	-878(ra) # 80002e28 <argint>
  argint(1, &new_priority);
    8000319e:	fe840593          	addi	a1,s0,-24
    800031a2:	4505                	li	a0,1
    800031a4:	00000097          	auipc	ra,0x0
    800031a8:	c84080e7          	jalr	-892(ra) # 80002e28 <argint>
  if(pid < 0 || new_priority < 0)
    800031ac:	fec42683          	lw	a3,-20(s0)
    800031b0:	0806cb63          	bltz	a3,80003246 <sys_setpriority+0xbe>
    800031b4:	fe842583          	lw	a1,-24(s0)
    800031b8:	0805c963          	bltz	a1,8000324a <sys_setpriority+0xc2>
    return -1;
  struct proc* req = proc;
  for(struct proc* p = proc; p < &proc[NPROC]; p++){
    800031bc:	0000e797          	auipc	a5,0xe
    800031c0:	de478793          	addi	a5,a5,-540 # 80010fa0 <proc>
    800031c4:	00014617          	auipc	a2,0x14
    800031c8:	1dc60613          	addi	a2,a2,476 # 800173a0 <tickslock>
    if(pid == p->pid){
    800031cc:	5b98                	lw	a4,48(a5)
    800031ce:	00d70a63          	beq	a4,a3,800031e2 <sys_setpriority+0x5a>
  for(struct proc* p = proc; p < &proc[NPROC]; p++){
    800031d2:	19078793          	addi	a5,a5,400
    800031d6:	fec79be3          	bne	a5,a2,800031cc <sys_setpriority+0x44>
  struct proc* req = proc;
    800031da:	0000e797          	auipc	a5,0xe
    800031de:	dc678793          	addi	a5,a5,-570 # 80010fa0 <proc>
      req = p;
      break;
    }
  }
  int prev_sp = req->sp;
    800031e2:	1747a503          	lw	a0,372(a5)
  int rbi = (((3*req->Rtime - req->stime - req->wtime)*50)/(req->Rtime + req->wtime + req->stime + 1));
    800031e6:	1847a683          	lw	a3,388(a5)
    800031ea:	1887a803          	lw	a6,392(a5)
    800031ee:	1807a603          	lw	a2,384(a5)
    800031f2:	0016971b          	slliw	a4,a3,0x1
    800031f6:	9f35                	addw	a4,a4,a3
    800031f8:	4107073b          	subw	a4,a4,a6
    800031fc:	9f11                	subw	a4,a4,a2
    800031fe:	03200893          	li	a7,50
    80003202:	0317073b          	mulw	a4,a4,a7
    80003206:	010686bb          	addw	a3,a3,a6
    8000320a:	2685                	addiw	a3,a3,1
    8000320c:	9eb1                	addw	a3,a3,a2
    8000320e:	02d7573b          	divuw	a4,a4,a3
  if(rbi < 0)
    rbi = 0;
  int new_dp = rbi + new_priority;
    80003212:	0007069b          	sext.w	a3,a4
    80003216:	fff6c693          	not	a3,a3
    8000321a:	96fd                	srai	a3,a3,0x3f
    8000321c:	8f75                	and	a4,a4,a3
    8000321e:	9f2d                	addw	a4,a4,a1
  if(new_dp > 100)
    new_dp = 100;
  req->dp = new_dp;
    80003220:	0007061b          	sext.w	a2,a4
    80003224:	06400693          	li	a3,100
    80003228:	00c6d463          	bge	a3,a2,80003230 <sys_setpriority+0xa8>
    8000322c:	06400713          	li	a4,100
    80003230:	16e7ac23          	sw	a4,376(a5)
  req->sp = new_priority;
    80003234:	16b7aa23          	sw	a1,372(a5)
  req->RBI = 25;
    80003238:	4765                	li	a4,25
    8000323a:	16e7ae23          	sw	a4,380(a5)
  if(new_dp < req->dp){
    yield();
  }

  return prev_sp;
    8000323e:	60e2                	ld	ra,24(sp)
    80003240:	6442                	ld	s0,16(sp)
    80003242:	6105                	addi	sp,sp,32
    80003244:	8082                	ret
    return -1;
    80003246:	557d                	li	a0,-1
    80003248:	bfdd                	j	8000323e <sys_setpriority+0xb6>
    8000324a:	557d                	li	a0,-1
    8000324c:	bfcd                	j	8000323e <sys_setpriority+0xb6>

000000008000324e <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000324e:	7179                	addi	sp,sp,-48
    80003250:	f406                	sd	ra,40(sp)
    80003252:	f022                	sd	s0,32(sp)
    80003254:	ec26                	sd	s1,24(sp)
    80003256:	e84a                	sd	s2,16(sp)
    80003258:	e44e                	sd	s3,8(sp)
    8000325a:	e052                	sd	s4,0(sp)
    8000325c:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000325e:	00005597          	auipc	a1,0x5
    80003262:	2c258593          	addi	a1,a1,706 # 80008520 <syscalls+0xc8>
    80003266:	00014517          	auipc	a0,0x14
    8000326a:	15250513          	addi	a0,a0,338 # 800173b8 <bcache>
    8000326e:	ffffe097          	auipc	ra,0xffffe
    80003272:	8d8080e7          	jalr	-1832(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003276:	0001c797          	auipc	a5,0x1c
    8000327a:	14278793          	addi	a5,a5,322 # 8001f3b8 <bcache+0x8000>
    8000327e:	0001c717          	auipc	a4,0x1c
    80003282:	3a270713          	addi	a4,a4,930 # 8001f620 <bcache+0x8268>
    80003286:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    8000328a:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000328e:	00014497          	auipc	s1,0x14
    80003292:	14248493          	addi	s1,s1,322 # 800173d0 <bcache+0x18>
    b->next = bcache.head.next;
    80003296:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003298:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    8000329a:	00005a17          	auipc	s4,0x5
    8000329e:	28ea0a13          	addi	s4,s4,654 # 80008528 <syscalls+0xd0>
    b->next = bcache.head.next;
    800032a2:	2b893783          	ld	a5,696(s2)
    800032a6:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    800032a8:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    800032ac:	85d2                	mv	a1,s4
    800032ae:	01048513          	addi	a0,s1,16
    800032b2:	00001097          	auipc	ra,0x1
    800032b6:	4c8080e7          	jalr	1224(ra) # 8000477a <initsleeplock>
    bcache.head.next->prev = b;
    800032ba:	2b893783          	ld	a5,696(s2)
    800032be:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    800032c0:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800032c4:	45848493          	addi	s1,s1,1112
    800032c8:	fd349de3          	bne	s1,s3,800032a2 <binit+0x54>
  }
}
    800032cc:	70a2                	ld	ra,40(sp)
    800032ce:	7402                	ld	s0,32(sp)
    800032d0:	64e2                	ld	s1,24(sp)
    800032d2:	6942                	ld	s2,16(sp)
    800032d4:	69a2                	ld	s3,8(sp)
    800032d6:	6a02                	ld	s4,0(sp)
    800032d8:	6145                	addi	sp,sp,48
    800032da:	8082                	ret

00000000800032dc <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800032dc:	7179                	addi	sp,sp,-48
    800032de:	f406                	sd	ra,40(sp)
    800032e0:	f022                	sd	s0,32(sp)
    800032e2:	ec26                	sd	s1,24(sp)
    800032e4:	e84a                	sd	s2,16(sp)
    800032e6:	e44e                	sd	s3,8(sp)
    800032e8:	1800                	addi	s0,sp,48
    800032ea:	892a                	mv	s2,a0
    800032ec:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800032ee:	00014517          	auipc	a0,0x14
    800032f2:	0ca50513          	addi	a0,a0,202 # 800173b8 <bcache>
    800032f6:	ffffe097          	auipc	ra,0xffffe
    800032fa:	8e0080e7          	jalr	-1824(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800032fe:	0001c497          	auipc	s1,0x1c
    80003302:	3724b483          	ld	s1,882(s1) # 8001f670 <bcache+0x82b8>
    80003306:	0001c797          	auipc	a5,0x1c
    8000330a:	31a78793          	addi	a5,a5,794 # 8001f620 <bcache+0x8268>
    8000330e:	02f48f63          	beq	s1,a5,8000334c <bread+0x70>
    80003312:	873e                	mv	a4,a5
    80003314:	a021                	j	8000331c <bread+0x40>
    80003316:	68a4                	ld	s1,80(s1)
    80003318:	02e48a63          	beq	s1,a4,8000334c <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    8000331c:	449c                	lw	a5,8(s1)
    8000331e:	ff279ce3          	bne	a5,s2,80003316 <bread+0x3a>
    80003322:	44dc                	lw	a5,12(s1)
    80003324:	ff3799e3          	bne	a5,s3,80003316 <bread+0x3a>
      b->refcnt++;
    80003328:	40bc                	lw	a5,64(s1)
    8000332a:	2785                	addiw	a5,a5,1
    8000332c:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000332e:	00014517          	auipc	a0,0x14
    80003332:	08a50513          	addi	a0,a0,138 # 800173b8 <bcache>
    80003336:	ffffe097          	auipc	ra,0xffffe
    8000333a:	954080e7          	jalr	-1708(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000333e:	01048513          	addi	a0,s1,16
    80003342:	00001097          	auipc	ra,0x1
    80003346:	472080e7          	jalr	1138(ra) # 800047b4 <acquiresleep>
      return b;
    8000334a:	a8b9                	j	800033a8 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000334c:	0001c497          	auipc	s1,0x1c
    80003350:	31c4b483          	ld	s1,796(s1) # 8001f668 <bcache+0x82b0>
    80003354:	0001c797          	auipc	a5,0x1c
    80003358:	2cc78793          	addi	a5,a5,716 # 8001f620 <bcache+0x8268>
    8000335c:	00f48863          	beq	s1,a5,8000336c <bread+0x90>
    80003360:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003362:	40bc                	lw	a5,64(s1)
    80003364:	cf81                	beqz	a5,8000337c <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003366:	64a4                	ld	s1,72(s1)
    80003368:	fee49de3          	bne	s1,a4,80003362 <bread+0x86>
  panic("bget: no buffers");
    8000336c:	00005517          	auipc	a0,0x5
    80003370:	1c450513          	addi	a0,a0,452 # 80008530 <syscalls+0xd8>
    80003374:	ffffd097          	auipc	ra,0xffffd
    80003378:	1cc080e7          	jalr	460(ra) # 80000540 <panic>
      b->dev = dev;
    8000337c:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003380:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003384:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003388:	4785                	li	a5,1
    8000338a:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000338c:	00014517          	auipc	a0,0x14
    80003390:	02c50513          	addi	a0,a0,44 # 800173b8 <bcache>
    80003394:	ffffe097          	auipc	ra,0xffffe
    80003398:	8f6080e7          	jalr	-1802(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000339c:	01048513          	addi	a0,s1,16
    800033a0:	00001097          	auipc	ra,0x1
    800033a4:	414080e7          	jalr	1044(ra) # 800047b4 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    800033a8:	409c                	lw	a5,0(s1)
    800033aa:	cb89                	beqz	a5,800033bc <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    800033ac:	8526                	mv	a0,s1
    800033ae:	70a2                	ld	ra,40(sp)
    800033b0:	7402                	ld	s0,32(sp)
    800033b2:	64e2                	ld	s1,24(sp)
    800033b4:	6942                	ld	s2,16(sp)
    800033b6:	69a2                	ld	s3,8(sp)
    800033b8:	6145                	addi	sp,sp,48
    800033ba:	8082                	ret
    virtio_disk_rw(b, 0);
    800033bc:	4581                	li	a1,0
    800033be:	8526                	mv	a0,s1
    800033c0:	00003097          	auipc	ra,0x3
    800033c4:	002080e7          	jalr	2(ra) # 800063c2 <virtio_disk_rw>
    b->valid = 1;
    800033c8:	4785                	li	a5,1
    800033ca:	c09c                	sw	a5,0(s1)
  return b;
    800033cc:	b7c5                	j	800033ac <bread+0xd0>

00000000800033ce <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800033ce:	1101                	addi	sp,sp,-32
    800033d0:	ec06                	sd	ra,24(sp)
    800033d2:	e822                	sd	s0,16(sp)
    800033d4:	e426                	sd	s1,8(sp)
    800033d6:	1000                	addi	s0,sp,32
    800033d8:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800033da:	0541                	addi	a0,a0,16
    800033dc:	00001097          	auipc	ra,0x1
    800033e0:	472080e7          	jalr	1138(ra) # 8000484e <holdingsleep>
    800033e4:	cd01                	beqz	a0,800033fc <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800033e6:	4585                	li	a1,1
    800033e8:	8526                	mv	a0,s1
    800033ea:	00003097          	auipc	ra,0x3
    800033ee:	fd8080e7          	jalr	-40(ra) # 800063c2 <virtio_disk_rw>
}
    800033f2:	60e2                	ld	ra,24(sp)
    800033f4:	6442                	ld	s0,16(sp)
    800033f6:	64a2                	ld	s1,8(sp)
    800033f8:	6105                	addi	sp,sp,32
    800033fa:	8082                	ret
    panic("bwrite");
    800033fc:	00005517          	auipc	a0,0x5
    80003400:	14c50513          	addi	a0,a0,332 # 80008548 <syscalls+0xf0>
    80003404:	ffffd097          	auipc	ra,0xffffd
    80003408:	13c080e7          	jalr	316(ra) # 80000540 <panic>

000000008000340c <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    8000340c:	1101                	addi	sp,sp,-32
    8000340e:	ec06                	sd	ra,24(sp)
    80003410:	e822                	sd	s0,16(sp)
    80003412:	e426                	sd	s1,8(sp)
    80003414:	e04a                	sd	s2,0(sp)
    80003416:	1000                	addi	s0,sp,32
    80003418:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    8000341a:	01050913          	addi	s2,a0,16
    8000341e:	854a                	mv	a0,s2
    80003420:	00001097          	auipc	ra,0x1
    80003424:	42e080e7          	jalr	1070(ra) # 8000484e <holdingsleep>
    80003428:	c92d                	beqz	a0,8000349a <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    8000342a:	854a                	mv	a0,s2
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	3de080e7          	jalr	990(ra) # 8000480a <releasesleep>

  acquire(&bcache.lock);
    80003434:	00014517          	auipc	a0,0x14
    80003438:	f8450513          	addi	a0,a0,-124 # 800173b8 <bcache>
    8000343c:	ffffd097          	auipc	ra,0xffffd
    80003440:	79a080e7          	jalr	1946(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003444:	40bc                	lw	a5,64(s1)
    80003446:	37fd                	addiw	a5,a5,-1
    80003448:	0007871b          	sext.w	a4,a5
    8000344c:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000344e:	eb05                	bnez	a4,8000347e <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003450:	68bc                	ld	a5,80(s1)
    80003452:	64b8                	ld	a4,72(s1)
    80003454:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003456:	64bc                	ld	a5,72(s1)
    80003458:	68b8                	ld	a4,80(s1)
    8000345a:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    8000345c:	0001c797          	auipc	a5,0x1c
    80003460:	f5c78793          	addi	a5,a5,-164 # 8001f3b8 <bcache+0x8000>
    80003464:	2b87b703          	ld	a4,696(a5)
    80003468:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    8000346a:	0001c717          	auipc	a4,0x1c
    8000346e:	1b670713          	addi	a4,a4,438 # 8001f620 <bcache+0x8268>
    80003472:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003474:	2b87b703          	ld	a4,696(a5)
    80003478:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    8000347a:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000347e:	00014517          	auipc	a0,0x14
    80003482:	f3a50513          	addi	a0,a0,-198 # 800173b8 <bcache>
    80003486:	ffffe097          	auipc	ra,0xffffe
    8000348a:	804080e7          	jalr	-2044(ra) # 80000c8a <release>
}
    8000348e:	60e2                	ld	ra,24(sp)
    80003490:	6442                	ld	s0,16(sp)
    80003492:	64a2                	ld	s1,8(sp)
    80003494:	6902                	ld	s2,0(sp)
    80003496:	6105                	addi	sp,sp,32
    80003498:	8082                	ret
    panic("brelse");
    8000349a:	00005517          	auipc	a0,0x5
    8000349e:	0b650513          	addi	a0,a0,182 # 80008550 <syscalls+0xf8>
    800034a2:	ffffd097          	auipc	ra,0xffffd
    800034a6:	09e080e7          	jalr	158(ra) # 80000540 <panic>

00000000800034aa <bpin>:

void
bpin(struct buf *b) {
    800034aa:	1101                	addi	sp,sp,-32
    800034ac:	ec06                	sd	ra,24(sp)
    800034ae:	e822                	sd	s0,16(sp)
    800034b0:	e426                	sd	s1,8(sp)
    800034b2:	1000                	addi	s0,sp,32
    800034b4:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034b6:	00014517          	auipc	a0,0x14
    800034ba:	f0250513          	addi	a0,a0,-254 # 800173b8 <bcache>
    800034be:	ffffd097          	auipc	ra,0xffffd
    800034c2:	718080e7          	jalr	1816(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800034c6:	40bc                	lw	a5,64(s1)
    800034c8:	2785                	addiw	a5,a5,1
    800034ca:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800034cc:	00014517          	auipc	a0,0x14
    800034d0:	eec50513          	addi	a0,a0,-276 # 800173b8 <bcache>
    800034d4:	ffffd097          	auipc	ra,0xffffd
    800034d8:	7b6080e7          	jalr	1974(ra) # 80000c8a <release>
}
    800034dc:	60e2                	ld	ra,24(sp)
    800034de:	6442                	ld	s0,16(sp)
    800034e0:	64a2                	ld	s1,8(sp)
    800034e2:	6105                	addi	sp,sp,32
    800034e4:	8082                	ret

00000000800034e6 <bunpin>:

void
bunpin(struct buf *b) {
    800034e6:	1101                	addi	sp,sp,-32
    800034e8:	ec06                	sd	ra,24(sp)
    800034ea:	e822                	sd	s0,16(sp)
    800034ec:	e426                	sd	s1,8(sp)
    800034ee:	1000                	addi	s0,sp,32
    800034f0:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800034f2:	00014517          	auipc	a0,0x14
    800034f6:	ec650513          	addi	a0,a0,-314 # 800173b8 <bcache>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	6dc080e7          	jalr	1756(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003502:	40bc                	lw	a5,64(s1)
    80003504:	37fd                	addiw	a5,a5,-1
    80003506:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003508:	00014517          	auipc	a0,0x14
    8000350c:	eb050513          	addi	a0,a0,-336 # 800173b8 <bcache>
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	77a080e7          	jalr	1914(ra) # 80000c8a <release>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6105                	addi	sp,sp,32
    80003520:	8082                	ret

0000000080003522 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003522:	1101                	addi	sp,sp,-32
    80003524:	ec06                	sd	ra,24(sp)
    80003526:	e822                	sd	s0,16(sp)
    80003528:	e426                	sd	s1,8(sp)
    8000352a:	e04a                	sd	s2,0(sp)
    8000352c:	1000                	addi	s0,sp,32
    8000352e:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003530:	00d5d59b          	srliw	a1,a1,0xd
    80003534:	0001c797          	auipc	a5,0x1c
    80003538:	5607a783          	lw	a5,1376(a5) # 8001fa94 <sb+0x1c>
    8000353c:	9dbd                	addw	a1,a1,a5
    8000353e:	00000097          	auipc	ra,0x0
    80003542:	d9e080e7          	jalr	-610(ra) # 800032dc <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003546:	0074f713          	andi	a4,s1,7
    8000354a:	4785                	li	a5,1
    8000354c:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003550:	14ce                	slli	s1,s1,0x33
    80003552:	90d9                	srli	s1,s1,0x36
    80003554:	00950733          	add	a4,a0,s1
    80003558:	05874703          	lbu	a4,88(a4)
    8000355c:	00e7f6b3          	and	a3,a5,a4
    80003560:	c69d                	beqz	a3,8000358e <bfree+0x6c>
    80003562:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003564:	94aa                	add	s1,s1,a0
    80003566:	fff7c793          	not	a5,a5
    8000356a:	8f7d                	and	a4,a4,a5
    8000356c:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    80003570:	00001097          	auipc	ra,0x1
    80003574:	126080e7          	jalr	294(ra) # 80004696 <log_write>
  brelse(bp);
    80003578:	854a                	mv	a0,s2
    8000357a:	00000097          	auipc	ra,0x0
    8000357e:	e92080e7          	jalr	-366(ra) # 8000340c <brelse>
}
    80003582:	60e2                	ld	ra,24(sp)
    80003584:	6442                	ld	s0,16(sp)
    80003586:	64a2                	ld	s1,8(sp)
    80003588:	6902                	ld	s2,0(sp)
    8000358a:	6105                	addi	sp,sp,32
    8000358c:	8082                	ret
    panic("freeing free block");
    8000358e:	00005517          	auipc	a0,0x5
    80003592:	fca50513          	addi	a0,a0,-54 # 80008558 <syscalls+0x100>
    80003596:	ffffd097          	auipc	ra,0xffffd
    8000359a:	faa080e7          	jalr	-86(ra) # 80000540 <panic>

000000008000359e <balloc>:
{
    8000359e:	711d                	addi	sp,sp,-96
    800035a0:	ec86                	sd	ra,88(sp)
    800035a2:	e8a2                	sd	s0,80(sp)
    800035a4:	e4a6                	sd	s1,72(sp)
    800035a6:	e0ca                	sd	s2,64(sp)
    800035a8:	fc4e                	sd	s3,56(sp)
    800035aa:	f852                	sd	s4,48(sp)
    800035ac:	f456                	sd	s5,40(sp)
    800035ae:	f05a                	sd	s6,32(sp)
    800035b0:	ec5e                	sd	s7,24(sp)
    800035b2:	e862                	sd	s8,16(sp)
    800035b4:	e466                	sd	s9,8(sp)
    800035b6:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800035b8:	0001c797          	auipc	a5,0x1c
    800035bc:	4c47a783          	lw	a5,1220(a5) # 8001fa7c <sb+0x4>
    800035c0:	cff5                	beqz	a5,800036bc <balloc+0x11e>
    800035c2:	8baa                	mv	s7,a0
    800035c4:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800035c6:	0001cb17          	auipc	s6,0x1c
    800035ca:	4b2b0b13          	addi	s6,s6,1202 # 8001fa78 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035ce:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800035d0:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800035d2:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800035d4:	6c89                	lui	s9,0x2
    800035d6:	a061                	j	8000365e <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800035d8:	97ca                	add	a5,a5,s2
    800035da:	8e55                	or	a2,a2,a3
    800035dc:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800035e0:	854a                	mv	a0,s2
    800035e2:	00001097          	auipc	ra,0x1
    800035e6:	0b4080e7          	jalr	180(ra) # 80004696 <log_write>
        brelse(bp);
    800035ea:	854a                	mv	a0,s2
    800035ec:	00000097          	auipc	ra,0x0
    800035f0:	e20080e7          	jalr	-480(ra) # 8000340c <brelse>
  bp = bread(dev, bno);
    800035f4:	85a6                	mv	a1,s1
    800035f6:	855e                	mv	a0,s7
    800035f8:	00000097          	auipc	ra,0x0
    800035fc:	ce4080e7          	jalr	-796(ra) # 800032dc <bread>
    80003600:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003602:	40000613          	li	a2,1024
    80003606:	4581                	li	a1,0
    80003608:	05850513          	addi	a0,a0,88
    8000360c:	ffffd097          	auipc	ra,0xffffd
    80003610:	6c6080e7          	jalr	1734(ra) # 80000cd2 <memset>
  log_write(bp);
    80003614:	854a                	mv	a0,s2
    80003616:	00001097          	auipc	ra,0x1
    8000361a:	080080e7          	jalr	128(ra) # 80004696 <log_write>
  brelse(bp);
    8000361e:	854a                	mv	a0,s2
    80003620:	00000097          	auipc	ra,0x0
    80003624:	dec080e7          	jalr	-532(ra) # 8000340c <brelse>
}
    80003628:	8526                	mv	a0,s1
    8000362a:	60e6                	ld	ra,88(sp)
    8000362c:	6446                	ld	s0,80(sp)
    8000362e:	64a6                	ld	s1,72(sp)
    80003630:	6906                	ld	s2,64(sp)
    80003632:	79e2                	ld	s3,56(sp)
    80003634:	7a42                	ld	s4,48(sp)
    80003636:	7aa2                	ld	s5,40(sp)
    80003638:	7b02                	ld	s6,32(sp)
    8000363a:	6be2                	ld	s7,24(sp)
    8000363c:	6c42                	ld	s8,16(sp)
    8000363e:	6ca2                	ld	s9,8(sp)
    80003640:	6125                	addi	sp,sp,96
    80003642:	8082                	ret
    brelse(bp);
    80003644:	854a                	mv	a0,s2
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	dc6080e7          	jalr	-570(ra) # 8000340c <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000364e:	015c87bb          	addw	a5,s9,s5
    80003652:	00078a9b          	sext.w	s5,a5
    80003656:	004b2703          	lw	a4,4(s6)
    8000365a:	06eaf163          	bgeu	s5,a4,800036bc <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000365e:	41fad79b          	sraiw	a5,s5,0x1f
    80003662:	0137d79b          	srliw	a5,a5,0x13
    80003666:	015787bb          	addw	a5,a5,s5
    8000366a:	40d7d79b          	sraiw	a5,a5,0xd
    8000366e:	01cb2583          	lw	a1,28(s6)
    80003672:	9dbd                	addw	a1,a1,a5
    80003674:	855e                	mv	a0,s7
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	c66080e7          	jalr	-922(ra) # 800032dc <bread>
    8000367e:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003680:	004b2503          	lw	a0,4(s6)
    80003684:	000a849b          	sext.w	s1,s5
    80003688:	8762                	mv	a4,s8
    8000368a:	faa4fde3          	bgeu	s1,a0,80003644 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000368e:	00777693          	andi	a3,a4,7
    80003692:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003696:	41f7579b          	sraiw	a5,a4,0x1f
    8000369a:	01d7d79b          	srliw	a5,a5,0x1d
    8000369e:	9fb9                	addw	a5,a5,a4
    800036a0:	4037d79b          	sraiw	a5,a5,0x3
    800036a4:	00f90633          	add	a2,s2,a5
    800036a8:	05864603          	lbu	a2,88(a2)
    800036ac:	00c6f5b3          	and	a1,a3,a2
    800036b0:	d585                	beqz	a1,800035d8 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800036b2:	2705                	addiw	a4,a4,1
    800036b4:	2485                	addiw	s1,s1,1
    800036b6:	fd471ae3          	bne	a4,s4,8000368a <balloc+0xec>
    800036ba:	b769                	j	80003644 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800036bc:	00005517          	auipc	a0,0x5
    800036c0:	eb450513          	addi	a0,a0,-332 # 80008570 <syscalls+0x118>
    800036c4:	ffffd097          	auipc	ra,0xffffd
    800036c8:	ec6080e7          	jalr	-314(ra) # 8000058a <printf>
  return 0;
    800036cc:	4481                	li	s1,0
    800036ce:	bfa9                	j	80003628 <balloc+0x8a>

00000000800036d0 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800036d0:	7179                	addi	sp,sp,-48
    800036d2:	f406                	sd	ra,40(sp)
    800036d4:	f022                	sd	s0,32(sp)
    800036d6:	ec26                	sd	s1,24(sp)
    800036d8:	e84a                	sd	s2,16(sp)
    800036da:	e44e                	sd	s3,8(sp)
    800036dc:	e052                	sd	s4,0(sp)
    800036de:	1800                	addi	s0,sp,48
    800036e0:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800036e2:	47ad                	li	a5,11
    800036e4:	02b7e863          	bltu	a5,a1,80003714 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800036e8:	02059793          	slli	a5,a1,0x20
    800036ec:	01e7d593          	srli	a1,a5,0x1e
    800036f0:	00b504b3          	add	s1,a0,a1
    800036f4:	0504a903          	lw	s2,80(s1)
    800036f8:	06091e63          	bnez	s2,80003774 <bmap+0xa4>
      addr = balloc(ip->dev);
    800036fc:	4108                	lw	a0,0(a0)
    800036fe:	00000097          	auipc	ra,0x0
    80003702:	ea0080e7          	jalr	-352(ra) # 8000359e <balloc>
    80003706:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000370a:	06090563          	beqz	s2,80003774 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000370e:	0524a823          	sw	s2,80(s1)
    80003712:	a08d                	j	80003774 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003714:	ff45849b          	addiw	s1,a1,-12
    80003718:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000371c:	0ff00793          	li	a5,255
    80003720:	08e7e563          	bltu	a5,a4,800037aa <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003724:	08052903          	lw	s2,128(a0)
    80003728:	00091d63          	bnez	s2,80003742 <bmap+0x72>
      addr = balloc(ip->dev);
    8000372c:	4108                	lw	a0,0(a0)
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	e70080e7          	jalr	-400(ra) # 8000359e <balloc>
    80003736:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000373a:	02090d63          	beqz	s2,80003774 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000373e:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003742:	85ca                	mv	a1,s2
    80003744:	0009a503          	lw	a0,0(s3)
    80003748:	00000097          	auipc	ra,0x0
    8000374c:	b94080e7          	jalr	-1132(ra) # 800032dc <bread>
    80003750:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003752:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003756:	02049713          	slli	a4,s1,0x20
    8000375a:	01e75593          	srli	a1,a4,0x1e
    8000375e:	00b784b3          	add	s1,a5,a1
    80003762:	0004a903          	lw	s2,0(s1)
    80003766:	02090063          	beqz	s2,80003786 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    8000376a:	8552                	mv	a0,s4
    8000376c:	00000097          	auipc	ra,0x0
    80003770:	ca0080e7          	jalr	-864(ra) # 8000340c <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003774:	854a                	mv	a0,s2
    80003776:	70a2                	ld	ra,40(sp)
    80003778:	7402                	ld	s0,32(sp)
    8000377a:	64e2                	ld	s1,24(sp)
    8000377c:	6942                	ld	s2,16(sp)
    8000377e:	69a2                	ld	s3,8(sp)
    80003780:	6a02                	ld	s4,0(sp)
    80003782:	6145                	addi	sp,sp,48
    80003784:	8082                	ret
      addr = balloc(ip->dev);
    80003786:	0009a503          	lw	a0,0(s3)
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	e14080e7          	jalr	-492(ra) # 8000359e <balloc>
    80003792:	0005091b          	sext.w	s2,a0
      if(addr){
    80003796:	fc090ae3          	beqz	s2,8000376a <bmap+0x9a>
        a[bn] = addr;
    8000379a:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000379e:	8552                	mv	a0,s4
    800037a0:	00001097          	auipc	ra,0x1
    800037a4:	ef6080e7          	jalr	-266(ra) # 80004696 <log_write>
    800037a8:	b7c9                	j	8000376a <bmap+0x9a>
  panic("bmap: out of range");
    800037aa:	00005517          	auipc	a0,0x5
    800037ae:	dde50513          	addi	a0,a0,-546 # 80008588 <syscalls+0x130>
    800037b2:	ffffd097          	auipc	ra,0xffffd
    800037b6:	d8e080e7          	jalr	-626(ra) # 80000540 <panic>

00000000800037ba <iget>:
{
    800037ba:	7179                	addi	sp,sp,-48
    800037bc:	f406                	sd	ra,40(sp)
    800037be:	f022                	sd	s0,32(sp)
    800037c0:	ec26                	sd	s1,24(sp)
    800037c2:	e84a                	sd	s2,16(sp)
    800037c4:	e44e                	sd	s3,8(sp)
    800037c6:	e052                	sd	s4,0(sp)
    800037c8:	1800                	addi	s0,sp,48
    800037ca:	89aa                	mv	s3,a0
    800037cc:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800037ce:	0001c517          	auipc	a0,0x1c
    800037d2:	2ca50513          	addi	a0,a0,714 # 8001fa98 <itable>
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	400080e7          	jalr	1024(ra) # 80000bd6 <acquire>
  empty = 0;
    800037de:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037e0:	0001c497          	auipc	s1,0x1c
    800037e4:	2d048493          	addi	s1,s1,720 # 8001fab0 <itable+0x18>
    800037e8:	0001e697          	auipc	a3,0x1e
    800037ec:	d5868693          	addi	a3,a3,-680 # 80021540 <log>
    800037f0:	a039                	j	800037fe <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800037f2:	02090b63          	beqz	s2,80003828 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800037f6:	08848493          	addi	s1,s1,136
    800037fa:	02d48a63          	beq	s1,a3,8000382e <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800037fe:	449c                	lw	a5,8(s1)
    80003800:	fef059e3          	blez	a5,800037f2 <iget+0x38>
    80003804:	4098                	lw	a4,0(s1)
    80003806:	ff3716e3          	bne	a4,s3,800037f2 <iget+0x38>
    8000380a:	40d8                	lw	a4,4(s1)
    8000380c:	ff4713e3          	bne	a4,s4,800037f2 <iget+0x38>
      ip->ref++;
    80003810:	2785                	addiw	a5,a5,1
    80003812:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80003814:	0001c517          	auipc	a0,0x1c
    80003818:	28450513          	addi	a0,a0,644 # 8001fa98 <itable>
    8000381c:	ffffd097          	auipc	ra,0xffffd
    80003820:	46e080e7          	jalr	1134(ra) # 80000c8a <release>
      return ip;
    80003824:	8926                	mv	s2,s1
    80003826:	a03d                	j	80003854 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003828:	f7f9                	bnez	a5,800037f6 <iget+0x3c>
    8000382a:	8926                	mv	s2,s1
    8000382c:	b7e9                	j	800037f6 <iget+0x3c>
  if(empty == 0)
    8000382e:	02090c63          	beqz	s2,80003866 <iget+0xac>
  ip->dev = dev;
    80003832:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003836:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000383a:	4785                	li	a5,1
    8000383c:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80003840:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003844:	0001c517          	auipc	a0,0x1c
    80003848:	25450513          	addi	a0,a0,596 # 8001fa98 <itable>
    8000384c:	ffffd097          	auipc	ra,0xffffd
    80003850:	43e080e7          	jalr	1086(ra) # 80000c8a <release>
}
    80003854:	854a                	mv	a0,s2
    80003856:	70a2                	ld	ra,40(sp)
    80003858:	7402                	ld	s0,32(sp)
    8000385a:	64e2                	ld	s1,24(sp)
    8000385c:	6942                	ld	s2,16(sp)
    8000385e:	69a2                	ld	s3,8(sp)
    80003860:	6a02                	ld	s4,0(sp)
    80003862:	6145                	addi	sp,sp,48
    80003864:	8082                	ret
    panic("iget: no inodes");
    80003866:	00005517          	auipc	a0,0x5
    8000386a:	d3a50513          	addi	a0,a0,-710 # 800085a0 <syscalls+0x148>
    8000386e:	ffffd097          	auipc	ra,0xffffd
    80003872:	cd2080e7          	jalr	-814(ra) # 80000540 <panic>

0000000080003876 <fsinit>:
fsinit(int dev) {
    80003876:	7179                	addi	sp,sp,-48
    80003878:	f406                	sd	ra,40(sp)
    8000387a:	f022                	sd	s0,32(sp)
    8000387c:	ec26                	sd	s1,24(sp)
    8000387e:	e84a                	sd	s2,16(sp)
    80003880:	e44e                	sd	s3,8(sp)
    80003882:	1800                	addi	s0,sp,48
    80003884:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003886:	4585                	li	a1,1
    80003888:	00000097          	auipc	ra,0x0
    8000388c:	a54080e7          	jalr	-1452(ra) # 800032dc <bread>
    80003890:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    80003892:	0001c997          	auipc	s3,0x1c
    80003896:	1e698993          	addi	s3,s3,486 # 8001fa78 <sb>
    8000389a:	02000613          	li	a2,32
    8000389e:	05850593          	addi	a1,a0,88
    800038a2:	854e                	mv	a0,s3
    800038a4:	ffffd097          	auipc	ra,0xffffd
    800038a8:	48a080e7          	jalr	1162(ra) # 80000d2e <memmove>
  brelse(bp);
    800038ac:	8526                	mv	a0,s1
    800038ae:	00000097          	auipc	ra,0x0
    800038b2:	b5e080e7          	jalr	-1186(ra) # 8000340c <brelse>
  if(sb.magic != FSMAGIC)
    800038b6:	0009a703          	lw	a4,0(s3)
    800038ba:	102037b7          	lui	a5,0x10203
    800038be:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    800038c2:	02f71263          	bne	a4,a5,800038e6 <fsinit+0x70>
  initlog(dev, &sb);
    800038c6:	0001c597          	auipc	a1,0x1c
    800038ca:	1b258593          	addi	a1,a1,434 # 8001fa78 <sb>
    800038ce:	854a                	mv	a0,s2
    800038d0:	00001097          	auipc	ra,0x1
    800038d4:	b4a080e7          	jalr	-1206(ra) # 8000441a <initlog>
}
    800038d8:	70a2                	ld	ra,40(sp)
    800038da:	7402                	ld	s0,32(sp)
    800038dc:	64e2                	ld	s1,24(sp)
    800038de:	6942                	ld	s2,16(sp)
    800038e0:	69a2                	ld	s3,8(sp)
    800038e2:	6145                	addi	sp,sp,48
    800038e4:	8082                	ret
    panic("invalid file system");
    800038e6:	00005517          	auipc	a0,0x5
    800038ea:	cca50513          	addi	a0,a0,-822 # 800085b0 <syscalls+0x158>
    800038ee:	ffffd097          	auipc	ra,0xffffd
    800038f2:	c52080e7          	jalr	-942(ra) # 80000540 <panic>

00000000800038f6 <iinit>:
{
    800038f6:	7179                	addi	sp,sp,-48
    800038f8:	f406                	sd	ra,40(sp)
    800038fa:	f022                	sd	s0,32(sp)
    800038fc:	ec26                	sd	s1,24(sp)
    800038fe:	e84a                	sd	s2,16(sp)
    80003900:	e44e                	sd	s3,8(sp)
    80003902:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003904:	00005597          	auipc	a1,0x5
    80003908:	cc458593          	addi	a1,a1,-828 # 800085c8 <syscalls+0x170>
    8000390c:	0001c517          	auipc	a0,0x1c
    80003910:	18c50513          	addi	a0,a0,396 # 8001fa98 <itable>
    80003914:	ffffd097          	auipc	ra,0xffffd
    80003918:	232080e7          	jalr	562(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000391c:	0001c497          	auipc	s1,0x1c
    80003920:	1a448493          	addi	s1,s1,420 # 8001fac0 <itable+0x28>
    80003924:	0001e997          	auipc	s3,0x1e
    80003928:	c2c98993          	addi	s3,s3,-980 # 80021550 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000392c:	00005917          	auipc	s2,0x5
    80003930:	ca490913          	addi	s2,s2,-860 # 800085d0 <syscalls+0x178>
    80003934:	85ca                	mv	a1,s2
    80003936:	8526                	mv	a0,s1
    80003938:	00001097          	auipc	ra,0x1
    8000393c:	e42080e7          	jalr	-446(ra) # 8000477a <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80003940:	08848493          	addi	s1,s1,136
    80003944:	ff3498e3          	bne	s1,s3,80003934 <iinit+0x3e>
}
    80003948:	70a2                	ld	ra,40(sp)
    8000394a:	7402                	ld	s0,32(sp)
    8000394c:	64e2                	ld	s1,24(sp)
    8000394e:	6942                	ld	s2,16(sp)
    80003950:	69a2                	ld	s3,8(sp)
    80003952:	6145                	addi	sp,sp,48
    80003954:	8082                	ret

0000000080003956 <ialloc>:
{
    80003956:	715d                	addi	sp,sp,-80
    80003958:	e486                	sd	ra,72(sp)
    8000395a:	e0a2                	sd	s0,64(sp)
    8000395c:	fc26                	sd	s1,56(sp)
    8000395e:	f84a                	sd	s2,48(sp)
    80003960:	f44e                	sd	s3,40(sp)
    80003962:	f052                	sd	s4,32(sp)
    80003964:	ec56                	sd	s5,24(sp)
    80003966:	e85a                	sd	s6,16(sp)
    80003968:	e45e                	sd	s7,8(sp)
    8000396a:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    8000396c:	0001c717          	auipc	a4,0x1c
    80003970:	11872703          	lw	a4,280(a4) # 8001fa84 <sb+0xc>
    80003974:	4785                	li	a5,1
    80003976:	04e7fa63          	bgeu	a5,a4,800039ca <ialloc+0x74>
    8000397a:	8aaa                	mv	s5,a0
    8000397c:	8bae                	mv	s7,a1
    8000397e:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003980:	0001ca17          	auipc	s4,0x1c
    80003984:	0f8a0a13          	addi	s4,s4,248 # 8001fa78 <sb>
    80003988:	00048b1b          	sext.w	s6,s1
    8000398c:	0044d593          	srli	a1,s1,0x4
    80003990:	018a2783          	lw	a5,24(s4)
    80003994:	9dbd                	addw	a1,a1,a5
    80003996:	8556                	mv	a0,s5
    80003998:	00000097          	auipc	ra,0x0
    8000399c:	944080e7          	jalr	-1724(ra) # 800032dc <bread>
    800039a0:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800039a2:	05850993          	addi	s3,a0,88
    800039a6:	00f4f793          	andi	a5,s1,15
    800039aa:	079a                	slli	a5,a5,0x6
    800039ac:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800039ae:	00099783          	lh	a5,0(s3)
    800039b2:	c3a1                	beqz	a5,800039f2 <ialloc+0x9c>
    brelse(bp);
    800039b4:	00000097          	auipc	ra,0x0
    800039b8:	a58080e7          	jalr	-1448(ra) # 8000340c <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800039bc:	0485                	addi	s1,s1,1
    800039be:	00ca2703          	lw	a4,12(s4)
    800039c2:	0004879b          	sext.w	a5,s1
    800039c6:	fce7e1e3          	bltu	a5,a4,80003988 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800039ca:	00005517          	auipc	a0,0x5
    800039ce:	c0e50513          	addi	a0,a0,-1010 # 800085d8 <syscalls+0x180>
    800039d2:	ffffd097          	auipc	ra,0xffffd
    800039d6:	bb8080e7          	jalr	-1096(ra) # 8000058a <printf>
  return 0;
    800039da:	4501                	li	a0,0
}
    800039dc:	60a6                	ld	ra,72(sp)
    800039de:	6406                	ld	s0,64(sp)
    800039e0:	74e2                	ld	s1,56(sp)
    800039e2:	7942                	ld	s2,48(sp)
    800039e4:	79a2                	ld	s3,40(sp)
    800039e6:	7a02                	ld	s4,32(sp)
    800039e8:	6ae2                	ld	s5,24(sp)
    800039ea:	6b42                	ld	s6,16(sp)
    800039ec:	6ba2                	ld	s7,8(sp)
    800039ee:	6161                	addi	sp,sp,80
    800039f0:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800039f2:	04000613          	li	a2,64
    800039f6:	4581                	li	a1,0
    800039f8:	854e                	mv	a0,s3
    800039fa:	ffffd097          	auipc	ra,0xffffd
    800039fe:	2d8080e7          	jalr	728(ra) # 80000cd2 <memset>
      dip->type = type;
    80003a02:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003a06:	854a                	mv	a0,s2
    80003a08:	00001097          	auipc	ra,0x1
    80003a0c:	c8e080e7          	jalr	-882(ra) # 80004696 <log_write>
      brelse(bp);
    80003a10:	854a                	mv	a0,s2
    80003a12:	00000097          	auipc	ra,0x0
    80003a16:	9fa080e7          	jalr	-1542(ra) # 8000340c <brelse>
      return iget(dev, inum);
    80003a1a:	85da                	mv	a1,s6
    80003a1c:	8556                	mv	a0,s5
    80003a1e:	00000097          	auipc	ra,0x0
    80003a22:	d9c080e7          	jalr	-612(ra) # 800037ba <iget>
    80003a26:	bf5d                	j	800039dc <ialloc+0x86>

0000000080003a28 <iupdate>:
{
    80003a28:	1101                	addi	sp,sp,-32
    80003a2a:	ec06                	sd	ra,24(sp)
    80003a2c:	e822                	sd	s0,16(sp)
    80003a2e:	e426                	sd	s1,8(sp)
    80003a30:	e04a                	sd	s2,0(sp)
    80003a32:	1000                	addi	s0,sp,32
    80003a34:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003a36:	415c                	lw	a5,4(a0)
    80003a38:	0047d79b          	srliw	a5,a5,0x4
    80003a3c:	0001c597          	auipc	a1,0x1c
    80003a40:	0545a583          	lw	a1,84(a1) # 8001fa90 <sb+0x18>
    80003a44:	9dbd                	addw	a1,a1,a5
    80003a46:	4108                	lw	a0,0(a0)
    80003a48:	00000097          	auipc	ra,0x0
    80003a4c:	894080e7          	jalr	-1900(ra) # 800032dc <bread>
    80003a50:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a52:	05850793          	addi	a5,a0,88
    80003a56:	40d8                	lw	a4,4(s1)
    80003a58:	8b3d                	andi	a4,a4,15
    80003a5a:	071a                	slli	a4,a4,0x6
    80003a5c:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    80003a5e:	04449703          	lh	a4,68(s1)
    80003a62:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003a66:	04649703          	lh	a4,70(s1)
    80003a6a:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    80003a6e:	04849703          	lh	a4,72(s1)
    80003a72:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003a76:	04a49703          	lh	a4,74(s1)
    80003a7a:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    80003a7e:	44f8                	lw	a4,76(s1)
    80003a80:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003a82:	03400613          	li	a2,52
    80003a86:	05048593          	addi	a1,s1,80
    80003a8a:	00c78513          	addi	a0,a5,12
    80003a8e:	ffffd097          	auipc	ra,0xffffd
    80003a92:	2a0080e7          	jalr	672(ra) # 80000d2e <memmove>
  log_write(bp);
    80003a96:	854a                	mv	a0,s2
    80003a98:	00001097          	auipc	ra,0x1
    80003a9c:	bfe080e7          	jalr	-1026(ra) # 80004696 <log_write>
  brelse(bp);
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	00000097          	auipc	ra,0x0
    80003aa6:	96a080e7          	jalr	-1686(ra) # 8000340c <brelse>
}
    80003aaa:	60e2                	ld	ra,24(sp)
    80003aac:	6442                	ld	s0,16(sp)
    80003aae:	64a2                	ld	s1,8(sp)
    80003ab0:	6902                	ld	s2,0(sp)
    80003ab2:	6105                	addi	sp,sp,32
    80003ab4:	8082                	ret

0000000080003ab6 <idup>:
{
    80003ab6:	1101                	addi	sp,sp,-32
    80003ab8:	ec06                	sd	ra,24(sp)
    80003aba:	e822                	sd	s0,16(sp)
    80003abc:	e426                	sd	s1,8(sp)
    80003abe:	1000                	addi	s0,sp,32
    80003ac0:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003ac2:	0001c517          	auipc	a0,0x1c
    80003ac6:	fd650513          	addi	a0,a0,-42 # 8001fa98 <itable>
    80003aca:	ffffd097          	auipc	ra,0xffffd
    80003ace:	10c080e7          	jalr	268(ra) # 80000bd6 <acquire>
  ip->ref++;
    80003ad2:	449c                	lw	a5,8(s1)
    80003ad4:	2785                	addiw	a5,a5,1
    80003ad6:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ad8:	0001c517          	auipc	a0,0x1c
    80003adc:	fc050513          	addi	a0,a0,-64 # 8001fa98 <itable>
    80003ae0:	ffffd097          	auipc	ra,0xffffd
    80003ae4:	1aa080e7          	jalr	426(ra) # 80000c8a <release>
}
    80003ae8:	8526                	mv	a0,s1
    80003aea:	60e2                	ld	ra,24(sp)
    80003aec:	6442                	ld	s0,16(sp)
    80003aee:	64a2                	ld	s1,8(sp)
    80003af0:	6105                	addi	sp,sp,32
    80003af2:	8082                	ret

0000000080003af4 <ilock>:
{
    80003af4:	1101                	addi	sp,sp,-32
    80003af6:	ec06                	sd	ra,24(sp)
    80003af8:	e822                	sd	s0,16(sp)
    80003afa:	e426                	sd	s1,8(sp)
    80003afc:	e04a                	sd	s2,0(sp)
    80003afe:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80003b00:	c115                	beqz	a0,80003b24 <ilock+0x30>
    80003b02:	84aa                	mv	s1,a0
    80003b04:	451c                	lw	a5,8(a0)
    80003b06:	00f05f63          	blez	a5,80003b24 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003b0a:	0541                	addi	a0,a0,16
    80003b0c:	00001097          	auipc	ra,0x1
    80003b10:	ca8080e7          	jalr	-856(ra) # 800047b4 <acquiresleep>
  if(ip->valid == 0){
    80003b14:	40bc                	lw	a5,64(s1)
    80003b16:	cf99                	beqz	a5,80003b34 <ilock+0x40>
}
    80003b18:	60e2                	ld	ra,24(sp)
    80003b1a:	6442                	ld	s0,16(sp)
    80003b1c:	64a2                	ld	s1,8(sp)
    80003b1e:	6902                	ld	s2,0(sp)
    80003b20:	6105                	addi	sp,sp,32
    80003b22:	8082                	ret
    panic("ilock");
    80003b24:	00005517          	auipc	a0,0x5
    80003b28:	acc50513          	addi	a0,a0,-1332 # 800085f0 <syscalls+0x198>
    80003b2c:	ffffd097          	auipc	ra,0xffffd
    80003b30:	a14080e7          	jalr	-1516(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003b34:	40dc                	lw	a5,4(s1)
    80003b36:	0047d79b          	srliw	a5,a5,0x4
    80003b3a:	0001c597          	auipc	a1,0x1c
    80003b3e:	f565a583          	lw	a1,-170(a1) # 8001fa90 <sb+0x18>
    80003b42:	9dbd                	addw	a1,a1,a5
    80003b44:	4088                	lw	a0,0(s1)
    80003b46:	fffff097          	auipc	ra,0xfffff
    80003b4a:	796080e7          	jalr	1942(ra) # 800032dc <bread>
    80003b4e:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003b50:	05850593          	addi	a1,a0,88
    80003b54:	40dc                	lw	a5,4(s1)
    80003b56:	8bbd                	andi	a5,a5,15
    80003b58:	079a                	slli	a5,a5,0x6
    80003b5a:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003b5c:	00059783          	lh	a5,0(a1)
    80003b60:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003b64:	00259783          	lh	a5,2(a1)
    80003b68:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003b6c:	00459783          	lh	a5,4(a1)
    80003b70:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003b74:	00659783          	lh	a5,6(a1)
    80003b78:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003b7c:	459c                	lw	a5,8(a1)
    80003b7e:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003b80:	03400613          	li	a2,52
    80003b84:	05b1                	addi	a1,a1,12
    80003b86:	05048513          	addi	a0,s1,80
    80003b8a:	ffffd097          	auipc	ra,0xffffd
    80003b8e:	1a4080e7          	jalr	420(ra) # 80000d2e <memmove>
    brelse(bp);
    80003b92:	854a                	mv	a0,s2
    80003b94:	00000097          	auipc	ra,0x0
    80003b98:	878080e7          	jalr	-1928(ra) # 8000340c <brelse>
    ip->valid = 1;
    80003b9c:	4785                	li	a5,1
    80003b9e:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003ba0:	04449783          	lh	a5,68(s1)
    80003ba4:	fbb5                	bnez	a5,80003b18 <ilock+0x24>
      panic("ilock: no type");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	a5250513          	addi	a0,a0,-1454 # 800085f8 <syscalls+0x1a0>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	992080e7          	jalr	-1646(ra) # 80000540 <panic>

0000000080003bb6 <iunlock>:
{
    80003bb6:	1101                	addi	sp,sp,-32
    80003bb8:	ec06                	sd	ra,24(sp)
    80003bba:	e822                	sd	s0,16(sp)
    80003bbc:	e426                	sd	s1,8(sp)
    80003bbe:	e04a                	sd	s2,0(sp)
    80003bc0:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003bc2:	c905                	beqz	a0,80003bf2 <iunlock+0x3c>
    80003bc4:	84aa                	mv	s1,a0
    80003bc6:	01050913          	addi	s2,a0,16
    80003bca:	854a                	mv	a0,s2
    80003bcc:	00001097          	auipc	ra,0x1
    80003bd0:	c82080e7          	jalr	-894(ra) # 8000484e <holdingsleep>
    80003bd4:	cd19                	beqz	a0,80003bf2 <iunlock+0x3c>
    80003bd6:	449c                	lw	a5,8(s1)
    80003bd8:	00f05d63          	blez	a5,80003bf2 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003bdc:	854a                	mv	a0,s2
    80003bde:	00001097          	auipc	ra,0x1
    80003be2:	c2c080e7          	jalr	-980(ra) # 8000480a <releasesleep>
}
    80003be6:	60e2                	ld	ra,24(sp)
    80003be8:	6442                	ld	s0,16(sp)
    80003bea:	64a2                	ld	s1,8(sp)
    80003bec:	6902                	ld	s2,0(sp)
    80003bee:	6105                	addi	sp,sp,32
    80003bf0:	8082                	ret
    panic("iunlock");
    80003bf2:	00005517          	auipc	a0,0x5
    80003bf6:	a1650513          	addi	a0,a0,-1514 # 80008608 <syscalls+0x1b0>
    80003bfa:	ffffd097          	auipc	ra,0xffffd
    80003bfe:	946080e7          	jalr	-1722(ra) # 80000540 <panic>

0000000080003c02 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003c02:	7179                	addi	sp,sp,-48
    80003c04:	f406                	sd	ra,40(sp)
    80003c06:	f022                	sd	s0,32(sp)
    80003c08:	ec26                	sd	s1,24(sp)
    80003c0a:	e84a                	sd	s2,16(sp)
    80003c0c:	e44e                	sd	s3,8(sp)
    80003c0e:	e052                	sd	s4,0(sp)
    80003c10:	1800                	addi	s0,sp,48
    80003c12:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003c14:	05050493          	addi	s1,a0,80
    80003c18:	08050913          	addi	s2,a0,128
    80003c1c:	a021                	j	80003c24 <itrunc+0x22>
    80003c1e:	0491                	addi	s1,s1,4
    80003c20:	01248d63          	beq	s1,s2,80003c3a <itrunc+0x38>
    if(ip->addrs[i]){
    80003c24:	408c                	lw	a1,0(s1)
    80003c26:	dde5                	beqz	a1,80003c1e <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003c28:	0009a503          	lw	a0,0(s3)
    80003c2c:	00000097          	auipc	ra,0x0
    80003c30:	8f6080e7          	jalr	-1802(ra) # 80003522 <bfree>
      ip->addrs[i] = 0;
    80003c34:	0004a023          	sw	zero,0(s1)
    80003c38:	b7dd                	j	80003c1e <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003c3a:	0809a583          	lw	a1,128(s3)
    80003c3e:	e185                	bnez	a1,80003c5e <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003c40:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003c44:	854e                	mv	a0,s3
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	de2080e7          	jalr	-542(ra) # 80003a28 <iupdate>
}
    80003c4e:	70a2                	ld	ra,40(sp)
    80003c50:	7402                	ld	s0,32(sp)
    80003c52:	64e2                	ld	s1,24(sp)
    80003c54:	6942                	ld	s2,16(sp)
    80003c56:	69a2                	ld	s3,8(sp)
    80003c58:	6a02                	ld	s4,0(sp)
    80003c5a:	6145                	addi	sp,sp,48
    80003c5c:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003c5e:	0009a503          	lw	a0,0(s3)
    80003c62:	fffff097          	auipc	ra,0xfffff
    80003c66:	67a080e7          	jalr	1658(ra) # 800032dc <bread>
    80003c6a:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003c6c:	05850493          	addi	s1,a0,88
    80003c70:	45850913          	addi	s2,a0,1112
    80003c74:	a021                	j	80003c7c <itrunc+0x7a>
    80003c76:	0491                	addi	s1,s1,4
    80003c78:	01248b63          	beq	s1,s2,80003c8e <itrunc+0x8c>
      if(a[j])
    80003c7c:	408c                	lw	a1,0(s1)
    80003c7e:	dde5                	beqz	a1,80003c76 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003c80:	0009a503          	lw	a0,0(s3)
    80003c84:	00000097          	auipc	ra,0x0
    80003c88:	89e080e7          	jalr	-1890(ra) # 80003522 <bfree>
    80003c8c:	b7ed                	j	80003c76 <itrunc+0x74>
    brelse(bp);
    80003c8e:	8552                	mv	a0,s4
    80003c90:	fffff097          	auipc	ra,0xfffff
    80003c94:	77c080e7          	jalr	1916(ra) # 8000340c <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003c98:	0809a583          	lw	a1,128(s3)
    80003c9c:	0009a503          	lw	a0,0(s3)
    80003ca0:	00000097          	auipc	ra,0x0
    80003ca4:	882080e7          	jalr	-1918(ra) # 80003522 <bfree>
    ip->addrs[NDIRECT] = 0;
    80003ca8:	0809a023          	sw	zero,128(s3)
    80003cac:	bf51                	j	80003c40 <itrunc+0x3e>

0000000080003cae <iput>:
{
    80003cae:	1101                	addi	sp,sp,-32
    80003cb0:	ec06                	sd	ra,24(sp)
    80003cb2:	e822                	sd	s0,16(sp)
    80003cb4:	e426                	sd	s1,8(sp)
    80003cb6:	e04a                	sd	s2,0(sp)
    80003cb8:	1000                	addi	s0,sp,32
    80003cba:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003cbc:	0001c517          	auipc	a0,0x1c
    80003cc0:	ddc50513          	addi	a0,a0,-548 # 8001fa98 <itable>
    80003cc4:	ffffd097          	auipc	ra,0xffffd
    80003cc8:	f12080e7          	jalr	-238(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ccc:	4498                	lw	a4,8(s1)
    80003cce:	4785                	li	a5,1
    80003cd0:	02f70363          	beq	a4,a5,80003cf6 <iput+0x48>
  ip->ref--;
    80003cd4:	449c                	lw	a5,8(s1)
    80003cd6:	37fd                	addiw	a5,a5,-1
    80003cd8:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003cda:	0001c517          	auipc	a0,0x1c
    80003cde:	dbe50513          	addi	a0,a0,-578 # 8001fa98 <itable>
    80003ce2:	ffffd097          	auipc	ra,0xffffd
    80003ce6:	fa8080e7          	jalr	-88(ra) # 80000c8a <release>
}
    80003cea:	60e2                	ld	ra,24(sp)
    80003cec:	6442                	ld	s0,16(sp)
    80003cee:	64a2                	ld	s1,8(sp)
    80003cf0:	6902                	ld	s2,0(sp)
    80003cf2:	6105                	addi	sp,sp,32
    80003cf4:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003cf6:	40bc                	lw	a5,64(s1)
    80003cf8:	dff1                	beqz	a5,80003cd4 <iput+0x26>
    80003cfa:	04a49783          	lh	a5,74(s1)
    80003cfe:	fbf9                	bnez	a5,80003cd4 <iput+0x26>
    acquiresleep(&ip->lock);
    80003d00:	01048913          	addi	s2,s1,16
    80003d04:	854a                	mv	a0,s2
    80003d06:	00001097          	auipc	ra,0x1
    80003d0a:	aae080e7          	jalr	-1362(ra) # 800047b4 <acquiresleep>
    release(&itable.lock);
    80003d0e:	0001c517          	auipc	a0,0x1c
    80003d12:	d8a50513          	addi	a0,a0,-630 # 8001fa98 <itable>
    80003d16:	ffffd097          	auipc	ra,0xffffd
    80003d1a:	f74080e7          	jalr	-140(ra) # 80000c8a <release>
    itrunc(ip);
    80003d1e:	8526                	mv	a0,s1
    80003d20:	00000097          	auipc	ra,0x0
    80003d24:	ee2080e7          	jalr	-286(ra) # 80003c02 <itrunc>
    ip->type = 0;
    80003d28:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003d2c:	8526                	mv	a0,s1
    80003d2e:	00000097          	auipc	ra,0x0
    80003d32:	cfa080e7          	jalr	-774(ra) # 80003a28 <iupdate>
    ip->valid = 0;
    80003d36:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003d3a:	854a                	mv	a0,s2
    80003d3c:	00001097          	auipc	ra,0x1
    80003d40:	ace080e7          	jalr	-1330(ra) # 8000480a <releasesleep>
    acquire(&itable.lock);
    80003d44:	0001c517          	auipc	a0,0x1c
    80003d48:	d5450513          	addi	a0,a0,-684 # 8001fa98 <itable>
    80003d4c:	ffffd097          	auipc	ra,0xffffd
    80003d50:	e8a080e7          	jalr	-374(ra) # 80000bd6 <acquire>
    80003d54:	b741                	j	80003cd4 <iput+0x26>

0000000080003d56 <iunlockput>:
{
    80003d56:	1101                	addi	sp,sp,-32
    80003d58:	ec06                	sd	ra,24(sp)
    80003d5a:	e822                	sd	s0,16(sp)
    80003d5c:	e426                	sd	s1,8(sp)
    80003d5e:	1000                	addi	s0,sp,32
    80003d60:	84aa                	mv	s1,a0
  iunlock(ip);
    80003d62:	00000097          	auipc	ra,0x0
    80003d66:	e54080e7          	jalr	-428(ra) # 80003bb6 <iunlock>
  iput(ip);
    80003d6a:	8526                	mv	a0,s1
    80003d6c:	00000097          	auipc	ra,0x0
    80003d70:	f42080e7          	jalr	-190(ra) # 80003cae <iput>
}
    80003d74:	60e2                	ld	ra,24(sp)
    80003d76:	6442                	ld	s0,16(sp)
    80003d78:	64a2                	ld	s1,8(sp)
    80003d7a:	6105                	addi	sp,sp,32
    80003d7c:	8082                	ret

0000000080003d7e <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003d7e:	1141                	addi	sp,sp,-16
    80003d80:	e422                	sd	s0,8(sp)
    80003d82:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003d84:	411c                	lw	a5,0(a0)
    80003d86:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003d88:	415c                	lw	a5,4(a0)
    80003d8a:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003d8c:	04451783          	lh	a5,68(a0)
    80003d90:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003d94:	04a51783          	lh	a5,74(a0)
    80003d98:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003d9c:	04c56783          	lwu	a5,76(a0)
    80003da0:	e99c                	sd	a5,16(a1)
}
    80003da2:	6422                	ld	s0,8(sp)
    80003da4:	0141                	addi	sp,sp,16
    80003da6:	8082                	ret

0000000080003da8 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003da8:	457c                	lw	a5,76(a0)
    80003daa:	0ed7e963          	bltu	a5,a3,80003e9c <readi+0xf4>
{
    80003dae:	7159                	addi	sp,sp,-112
    80003db0:	f486                	sd	ra,104(sp)
    80003db2:	f0a2                	sd	s0,96(sp)
    80003db4:	eca6                	sd	s1,88(sp)
    80003db6:	e8ca                	sd	s2,80(sp)
    80003db8:	e4ce                	sd	s3,72(sp)
    80003dba:	e0d2                	sd	s4,64(sp)
    80003dbc:	fc56                	sd	s5,56(sp)
    80003dbe:	f85a                	sd	s6,48(sp)
    80003dc0:	f45e                	sd	s7,40(sp)
    80003dc2:	f062                	sd	s8,32(sp)
    80003dc4:	ec66                	sd	s9,24(sp)
    80003dc6:	e86a                	sd	s10,16(sp)
    80003dc8:	e46e                	sd	s11,8(sp)
    80003dca:	1880                	addi	s0,sp,112
    80003dcc:	8b2a                	mv	s6,a0
    80003dce:	8bae                	mv	s7,a1
    80003dd0:	8a32                	mv	s4,a2
    80003dd2:	84b6                	mv	s1,a3
    80003dd4:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003dd6:	9f35                	addw	a4,a4,a3
    return 0;
    80003dd8:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003dda:	0ad76063          	bltu	a4,a3,80003e7a <readi+0xd2>
  if(off + n > ip->size)
    80003dde:	00e7f463          	bgeu	a5,a4,80003de6 <readi+0x3e>
    n = ip->size - off;
    80003de2:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003de6:	0a0a8963          	beqz	s5,80003e98 <readi+0xf0>
    80003dea:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003dec:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003df0:	5c7d                	li	s8,-1
    80003df2:	a82d                	j	80003e2c <readi+0x84>
    80003df4:	020d1d93          	slli	s11,s10,0x20
    80003df8:	020ddd93          	srli	s11,s11,0x20
    80003dfc:	05890613          	addi	a2,s2,88
    80003e00:	86ee                	mv	a3,s11
    80003e02:	963a                	add	a2,a2,a4
    80003e04:	85d2                	mv	a1,s4
    80003e06:	855e                	mv	a0,s7
    80003e08:	ffffe097          	auipc	ra,0xffffe
    80003e0c:	7ce080e7          	jalr	1998(ra) # 800025d6 <either_copyout>
    80003e10:	05850d63          	beq	a0,s8,80003e6a <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003e14:	854a                	mv	a0,s2
    80003e16:	fffff097          	auipc	ra,0xfffff
    80003e1a:	5f6080e7          	jalr	1526(ra) # 8000340c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e1e:	013d09bb          	addw	s3,s10,s3
    80003e22:	009d04bb          	addw	s1,s10,s1
    80003e26:	9a6e                	add	s4,s4,s11
    80003e28:	0559f763          	bgeu	s3,s5,80003e76 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003e2c:	00a4d59b          	srliw	a1,s1,0xa
    80003e30:	855a                	mv	a0,s6
    80003e32:	00000097          	auipc	ra,0x0
    80003e36:	89e080e7          	jalr	-1890(ra) # 800036d0 <bmap>
    80003e3a:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003e3e:	cd85                	beqz	a1,80003e76 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003e40:	000b2503          	lw	a0,0(s6)
    80003e44:	fffff097          	auipc	ra,0xfffff
    80003e48:	498080e7          	jalr	1176(ra) # 800032dc <bread>
    80003e4c:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e4e:	3ff4f713          	andi	a4,s1,1023
    80003e52:	40ec87bb          	subw	a5,s9,a4
    80003e56:	413a86bb          	subw	a3,s5,s3
    80003e5a:	8d3e                	mv	s10,a5
    80003e5c:	2781                	sext.w	a5,a5
    80003e5e:	0006861b          	sext.w	a2,a3
    80003e62:	f8f679e3          	bgeu	a2,a5,80003df4 <readi+0x4c>
    80003e66:	8d36                	mv	s10,a3
    80003e68:	b771                	j	80003df4 <readi+0x4c>
      brelse(bp);
    80003e6a:	854a                	mv	a0,s2
    80003e6c:	fffff097          	auipc	ra,0xfffff
    80003e70:	5a0080e7          	jalr	1440(ra) # 8000340c <brelse>
      tot = -1;
    80003e74:	59fd                	li	s3,-1
  }
  return tot;
    80003e76:	0009851b          	sext.w	a0,s3
}
    80003e7a:	70a6                	ld	ra,104(sp)
    80003e7c:	7406                	ld	s0,96(sp)
    80003e7e:	64e6                	ld	s1,88(sp)
    80003e80:	6946                	ld	s2,80(sp)
    80003e82:	69a6                	ld	s3,72(sp)
    80003e84:	6a06                	ld	s4,64(sp)
    80003e86:	7ae2                	ld	s5,56(sp)
    80003e88:	7b42                	ld	s6,48(sp)
    80003e8a:	7ba2                	ld	s7,40(sp)
    80003e8c:	7c02                	ld	s8,32(sp)
    80003e8e:	6ce2                	ld	s9,24(sp)
    80003e90:	6d42                	ld	s10,16(sp)
    80003e92:	6da2                	ld	s11,8(sp)
    80003e94:	6165                	addi	sp,sp,112
    80003e96:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003e98:	89d6                	mv	s3,s5
    80003e9a:	bff1                	j	80003e76 <readi+0xce>
    return 0;
    80003e9c:	4501                	li	a0,0
}
    80003e9e:	8082                	ret

0000000080003ea0 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003ea0:	457c                	lw	a5,76(a0)
    80003ea2:	10d7e863          	bltu	a5,a3,80003fb2 <writei+0x112>
{
    80003ea6:	7159                	addi	sp,sp,-112
    80003ea8:	f486                	sd	ra,104(sp)
    80003eaa:	f0a2                	sd	s0,96(sp)
    80003eac:	eca6                	sd	s1,88(sp)
    80003eae:	e8ca                	sd	s2,80(sp)
    80003eb0:	e4ce                	sd	s3,72(sp)
    80003eb2:	e0d2                	sd	s4,64(sp)
    80003eb4:	fc56                	sd	s5,56(sp)
    80003eb6:	f85a                	sd	s6,48(sp)
    80003eb8:	f45e                	sd	s7,40(sp)
    80003eba:	f062                	sd	s8,32(sp)
    80003ebc:	ec66                	sd	s9,24(sp)
    80003ebe:	e86a                	sd	s10,16(sp)
    80003ec0:	e46e                	sd	s11,8(sp)
    80003ec2:	1880                	addi	s0,sp,112
    80003ec4:	8aaa                	mv	s5,a0
    80003ec6:	8bae                	mv	s7,a1
    80003ec8:	8a32                	mv	s4,a2
    80003eca:	8936                	mv	s2,a3
    80003ecc:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003ece:	00e687bb          	addw	a5,a3,a4
    80003ed2:	0ed7e263          	bltu	a5,a3,80003fb6 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003ed6:	00043737          	lui	a4,0x43
    80003eda:	0ef76063          	bltu	a4,a5,80003fba <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003ede:	0c0b0863          	beqz	s6,80003fae <writei+0x10e>
    80003ee2:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ee4:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003ee8:	5c7d                	li	s8,-1
    80003eea:	a091                	j	80003f2e <writei+0x8e>
    80003eec:	020d1d93          	slli	s11,s10,0x20
    80003ef0:	020ddd93          	srli	s11,s11,0x20
    80003ef4:	05848513          	addi	a0,s1,88
    80003ef8:	86ee                	mv	a3,s11
    80003efa:	8652                	mv	a2,s4
    80003efc:	85de                	mv	a1,s7
    80003efe:	953a                	add	a0,a0,a4
    80003f00:	ffffe097          	auipc	ra,0xffffe
    80003f04:	72c080e7          	jalr	1836(ra) # 8000262c <either_copyin>
    80003f08:	07850263          	beq	a0,s8,80003f6c <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003f0c:	8526                	mv	a0,s1
    80003f0e:	00000097          	auipc	ra,0x0
    80003f12:	788080e7          	jalr	1928(ra) # 80004696 <log_write>
    brelse(bp);
    80003f16:	8526                	mv	a0,s1
    80003f18:	fffff097          	auipc	ra,0xfffff
    80003f1c:	4f4080e7          	jalr	1268(ra) # 8000340c <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003f20:	013d09bb          	addw	s3,s10,s3
    80003f24:	012d093b          	addw	s2,s10,s2
    80003f28:	9a6e                	add	s4,s4,s11
    80003f2a:	0569f663          	bgeu	s3,s6,80003f76 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003f2e:	00a9559b          	srliw	a1,s2,0xa
    80003f32:	8556                	mv	a0,s5
    80003f34:	fffff097          	auipc	ra,0xfffff
    80003f38:	79c080e7          	jalr	1948(ra) # 800036d0 <bmap>
    80003f3c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003f40:	c99d                	beqz	a1,80003f76 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003f42:	000aa503          	lw	a0,0(s5)
    80003f46:	fffff097          	auipc	ra,0xfffff
    80003f4a:	396080e7          	jalr	918(ra) # 800032dc <bread>
    80003f4e:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003f50:	3ff97713          	andi	a4,s2,1023
    80003f54:	40ec87bb          	subw	a5,s9,a4
    80003f58:	413b06bb          	subw	a3,s6,s3
    80003f5c:	8d3e                	mv	s10,a5
    80003f5e:	2781                	sext.w	a5,a5
    80003f60:	0006861b          	sext.w	a2,a3
    80003f64:	f8f674e3          	bgeu	a2,a5,80003eec <writei+0x4c>
    80003f68:	8d36                	mv	s10,a3
    80003f6a:	b749                	j	80003eec <writei+0x4c>
      brelse(bp);
    80003f6c:	8526                	mv	a0,s1
    80003f6e:	fffff097          	auipc	ra,0xfffff
    80003f72:	49e080e7          	jalr	1182(ra) # 8000340c <brelse>
  }

  if(off > ip->size)
    80003f76:	04caa783          	lw	a5,76(s5)
    80003f7a:	0127f463          	bgeu	a5,s2,80003f82 <writei+0xe2>
    ip->size = off;
    80003f7e:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003f82:	8556                	mv	a0,s5
    80003f84:	00000097          	auipc	ra,0x0
    80003f88:	aa4080e7          	jalr	-1372(ra) # 80003a28 <iupdate>

  return tot;
    80003f8c:	0009851b          	sext.w	a0,s3
}
    80003f90:	70a6                	ld	ra,104(sp)
    80003f92:	7406                	ld	s0,96(sp)
    80003f94:	64e6                	ld	s1,88(sp)
    80003f96:	6946                	ld	s2,80(sp)
    80003f98:	69a6                	ld	s3,72(sp)
    80003f9a:	6a06                	ld	s4,64(sp)
    80003f9c:	7ae2                	ld	s5,56(sp)
    80003f9e:	7b42                	ld	s6,48(sp)
    80003fa0:	7ba2                	ld	s7,40(sp)
    80003fa2:	7c02                	ld	s8,32(sp)
    80003fa4:	6ce2                	ld	s9,24(sp)
    80003fa6:	6d42                	ld	s10,16(sp)
    80003fa8:	6da2                	ld	s11,8(sp)
    80003faa:	6165                	addi	sp,sp,112
    80003fac:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003fae:	89da                	mv	s3,s6
    80003fb0:	bfc9                	j	80003f82 <writei+0xe2>
    return -1;
    80003fb2:	557d                	li	a0,-1
}
    80003fb4:	8082                	ret
    return -1;
    80003fb6:	557d                	li	a0,-1
    80003fb8:	bfe1                	j	80003f90 <writei+0xf0>
    return -1;
    80003fba:	557d                	li	a0,-1
    80003fbc:	bfd1                	j	80003f90 <writei+0xf0>

0000000080003fbe <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003fbe:	1141                	addi	sp,sp,-16
    80003fc0:	e406                	sd	ra,8(sp)
    80003fc2:	e022                	sd	s0,0(sp)
    80003fc4:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003fc6:	4639                	li	a2,14
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	dda080e7          	jalr	-550(ra) # 80000da2 <strncmp>
}
    80003fd0:	60a2                	ld	ra,8(sp)
    80003fd2:	6402                	ld	s0,0(sp)
    80003fd4:	0141                	addi	sp,sp,16
    80003fd6:	8082                	ret

0000000080003fd8 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003fd8:	7139                	addi	sp,sp,-64
    80003fda:	fc06                	sd	ra,56(sp)
    80003fdc:	f822                	sd	s0,48(sp)
    80003fde:	f426                	sd	s1,40(sp)
    80003fe0:	f04a                	sd	s2,32(sp)
    80003fe2:	ec4e                	sd	s3,24(sp)
    80003fe4:	e852                	sd	s4,16(sp)
    80003fe6:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003fe8:	04451703          	lh	a4,68(a0)
    80003fec:	4785                	li	a5,1
    80003fee:	00f71a63          	bne	a4,a5,80004002 <dirlookup+0x2a>
    80003ff2:	892a                	mv	s2,a0
    80003ff4:	89ae                	mv	s3,a1
    80003ff6:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ff8:	457c                	lw	a5,76(a0)
    80003ffa:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003ffc:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ffe:	e79d                	bnez	a5,8000402c <dirlookup+0x54>
    80004000:	a8a5                	j	80004078 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004002:	00004517          	auipc	a0,0x4
    80004006:	60e50513          	addi	a0,a0,1550 # 80008610 <syscalls+0x1b8>
    8000400a:	ffffc097          	auipc	ra,0xffffc
    8000400e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004012:	00004517          	auipc	a0,0x4
    80004016:	61650513          	addi	a0,a0,1558 # 80008628 <syscalls+0x1d0>
    8000401a:	ffffc097          	auipc	ra,0xffffc
    8000401e:	526080e7          	jalr	1318(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004022:	24c1                	addiw	s1,s1,16
    80004024:	04c92783          	lw	a5,76(s2)
    80004028:	04f4f763          	bgeu	s1,a5,80004076 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000402c:	4741                	li	a4,16
    8000402e:	86a6                	mv	a3,s1
    80004030:	fc040613          	addi	a2,s0,-64
    80004034:	4581                	li	a1,0
    80004036:	854a                	mv	a0,s2
    80004038:	00000097          	auipc	ra,0x0
    8000403c:	d70080e7          	jalr	-656(ra) # 80003da8 <readi>
    80004040:	47c1                	li	a5,16
    80004042:	fcf518e3          	bne	a0,a5,80004012 <dirlookup+0x3a>
    if(de.inum == 0)
    80004046:	fc045783          	lhu	a5,-64(s0)
    8000404a:	dfe1                	beqz	a5,80004022 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    8000404c:	fc240593          	addi	a1,s0,-62
    80004050:	854e                	mv	a0,s3
    80004052:	00000097          	auipc	ra,0x0
    80004056:	f6c080e7          	jalr	-148(ra) # 80003fbe <namecmp>
    8000405a:	f561                	bnez	a0,80004022 <dirlookup+0x4a>
      if(poff)
    8000405c:	000a0463          	beqz	s4,80004064 <dirlookup+0x8c>
        *poff = off;
    80004060:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004064:	fc045583          	lhu	a1,-64(s0)
    80004068:	00092503          	lw	a0,0(s2)
    8000406c:	fffff097          	auipc	ra,0xfffff
    80004070:	74e080e7          	jalr	1870(ra) # 800037ba <iget>
    80004074:	a011                	j	80004078 <dirlookup+0xa0>
  return 0;
    80004076:	4501                	li	a0,0
}
    80004078:	70e2                	ld	ra,56(sp)
    8000407a:	7442                	ld	s0,48(sp)
    8000407c:	74a2                	ld	s1,40(sp)
    8000407e:	7902                	ld	s2,32(sp)
    80004080:	69e2                	ld	s3,24(sp)
    80004082:	6a42                	ld	s4,16(sp)
    80004084:	6121                	addi	sp,sp,64
    80004086:	8082                	ret

0000000080004088 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004088:	711d                	addi	sp,sp,-96
    8000408a:	ec86                	sd	ra,88(sp)
    8000408c:	e8a2                	sd	s0,80(sp)
    8000408e:	e4a6                	sd	s1,72(sp)
    80004090:	e0ca                	sd	s2,64(sp)
    80004092:	fc4e                	sd	s3,56(sp)
    80004094:	f852                	sd	s4,48(sp)
    80004096:	f456                	sd	s5,40(sp)
    80004098:	f05a                	sd	s6,32(sp)
    8000409a:	ec5e                	sd	s7,24(sp)
    8000409c:	e862                	sd	s8,16(sp)
    8000409e:	e466                	sd	s9,8(sp)
    800040a0:	e06a                	sd	s10,0(sp)
    800040a2:	1080                	addi	s0,sp,96
    800040a4:	84aa                	mv	s1,a0
    800040a6:	8b2e                	mv	s6,a1
    800040a8:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800040aa:	00054703          	lbu	a4,0(a0)
    800040ae:	02f00793          	li	a5,47
    800040b2:	02f70363          	beq	a4,a5,800040d8 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800040b6:	ffffe097          	auipc	ra,0xffffe
    800040ba:	8f6080e7          	jalr	-1802(ra) # 800019ac <myproc>
    800040be:	15053503          	ld	a0,336(a0)
    800040c2:	00000097          	auipc	ra,0x0
    800040c6:	9f4080e7          	jalr	-1548(ra) # 80003ab6 <idup>
    800040ca:	8a2a                	mv	s4,a0
  while(*path == '/')
    800040cc:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    800040d0:	4cb5                	li	s9,13
  len = path - s;
    800040d2:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    800040d4:	4c05                	li	s8,1
    800040d6:	a87d                	j	80004194 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    800040d8:	4585                	li	a1,1
    800040da:	4505                	li	a0,1
    800040dc:	fffff097          	auipc	ra,0xfffff
    800040e0:	6de080e7          	jalr	1758(ra) # 800037ba <iget>
    800040e4:	8a2a                	mv	s4,a0
    800040e6:	b7dd                	j	800040cc <namex+0x44>
      iunlockput(ip);
    800040e8:	8552                	mv	a0,s4
    800040ea:	00000097          	auipc	ra,0x0
    800040ee:	c6c080e7          	jalr	-916(ra) # 80003d56 <iunlockput>
      return 0;
    800040f2:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    800040f4:	8552                	mv	a0,s4
    800040f6:	60e6                	ld	ra,88(sp)
    800040f8:	6446                	ld	s0,80(sp)
    800040fa:	64a6                	ld	s1,72(sp)
    800040fc:	6906                	ld	s2,64(sp)
    800040fe:	79e2                	ld	s3,56(sp)
    80004100:	7a42                	ld	s4,48(sp)
    80004102:	7aa2                	ld	s5,40(sp)
    80004104:	7b02                	ld	s6,32(sp)
    80004106:	6be2                	ld	s7,24(sp)
    80004108:	6c42                	ld	s8,16(sp)
    8000410a:	6ca2                	ld	s9,8(sp)
    8000410c:	6d02                	ld	s10,0(sp)
    8000410e:	6125                	addi	sp,sp,96
    80004110:	8082                	ret
      iunlock(ip);
    80004112:	8552                	mv	a0,s4
    80004114:	00000097          	auipc	ra,0x0
    80004118:	aa2080e7          	jalr	-1374(ra) # 80003bb6 <iunlock>
      return ip;
    8000411c:	bfe1                	j	800040f4 <namex+0x6c>
      iunlockput(ip);
    8000411e:	8552                	mv	a0,s4
    80004120:	00000097          	auipc	ra,0x0
    80004124:	c36080e7          	jalr	-970(ra) # 80003d56 <iunlockput>
      return 0;
    80004128:	8a4e                	mv	s4,s3
    8000412a:	b7e9                	j	800040f4 <namex+0x6c>
  len = path - s;
    8000412c:	40998633          	sub	a2,s3,s1
    80004130:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004134:	09acd863          	bge	s9,s10,800041c4 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004138:	4639                	li	a2,14
    8000413a:	85a6                	mv	a1,s1
    8000413c:	8556                	mv	a0,s5
    8000413e:	ffffd097          	auipc	ra,0xffffd
    80004142:	bf0080e7          	jalr	-1040(ra) # 80000d2e <memmove>
    80004146:	84ce                	mv	s1,s3
  while(*path == '/')
    80004148:	0004c783          	lbu	a5,0(s1)
    8000414c:	01279763          	bne	a5,s2,8000415a <namex+0xd2>
    path++;
    80004150:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004152:	0004c783          	lbu	a5,0(s1)
    80004156:	ff278de3          	beq	a5,s2,80004150 <namex+0xc8>
    ilock(ip);
    8000415a:	8552                	mv	a0,s4
    8000415c:	00000097          	auipc	ra,0x0
    80004160:	998080e7          	jalr	-1640(ra) # 80003af4 <ilock>
    if(ip->type != T_DIR){
    80004164:	044a1783          	lh	a5,68(s4)
    80004168:	f98790e3          	bne	a5,s8,800040e8 <namex+0x60>
    if(nameiparent && *path == '\0'){
    8000416c:	000b0563          	beqz	s6,80004176 <namex+0xee>
    80004170:	0004c783          	lbu	a5,0(s1)
    80004174:	dfd9                	beqz	a5,80004112 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004176:	865e                	mv	a2,s7
    80004178:	85d6                	mv	a1,s5
    8000417a:	8552                	mv	a0,s4
    8000417c:	00000097          	auipc	ra,0x0
    80004180:	e5c080e7          	jalr	-420(ra) # 80003fd8 <dirlookup>
    80004184:	89aa                	mv	s3,a0
    80004186:	dd41                	beqz	a0,8000411e <namex+0x96>
    iunlockput(ip);
    80004188:	8552                	mv	a0,s4
    8000418a:	00000097          	auipc	ra,0x0
    8000418e:	bcc080e7          	jalr	-1076(ra) # 80003d56 <iunlockput>
    ip = next;
    80004192:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004194:	0004c783          	lbu	a5,0(s1)
    80004198:	01279763          	bne	a5,s2,800041a6 <namex+0x11e>
    path++;
    8000419c:	0485                	addi	s1,s1,1
  while(*path == '/')
    8000419e:	0004c783          	lbu	a5,0(s1)
    800041a2:	ff278de3          	beq	a5,s2,8000419c <namex+0x114>
  if(*path == 0)
    800041a6:	cb9d                	beqz	a5,800041dc <namex+0x154>
  while(*path != '/' && *path != 0)
    800041a8:	0004c783          	lbu	a5,0(s1)
    800041ac:	89a6                	mv	s3,s1
  len = path - s;
    800041ae:	8d5e                	mv	s10,s7
    800041b0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800041b2:	01278963          	beq	a5,s2,800041c4 <namex+0x13c>
    800041b6:	dbbd                	beqz	a5,8000412c <namex+0xa4>
    path++;
    800041b8:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    800041ba:	0009c783          	lbu	a5,0(s3)
    800041be:	ff279ce3          	bne	a5,s2,800041b6 <namex+0x12e>
    800041c2:	b7ad                	j	8000412c <namex+0xa4>
    memmove(name, s, len);
    800041c4:	2601                	sext.w	a2,a2
    800041c6:	85a6                	mv	a1,s1
    800041c8:	8556                	mv	a0,s5
    800041ca:	ffffd097          	auipc	ra,0xffffd
    800041ce:	b64080e7          	jalr	-1180(ra) # 80000d2e <memmove>
    name[len] = 0;
    800041d2:	9d56                	add	s10,s10,s5
    800041d4:	000d0023          	sb	zero,0(s10)
    800041d8:	84ce                	mv	s1,s3
    800041da:	b7bd                	j	80004148 <namex+0xc0>
  if(nameiparent){
    800041dc:	f00b0ce3          	beqz	s6,800040f4 <namex+0x6c>
    iput(ip);
    800041e0:	8552                	mv	a0,s4
    800041e2:	00000097          	auipc	ra,0x0
    800041e6:	acc080e7          	jalr	-1332(ra) # 80003cae <iput>
    return 0;
    800041ea:	4a01                	li	s4,0
    800041ec:	b721                	j	800040f4 <namex+0x6c>

00000000800041ee <dirlink>:
{
    800041ee:	7139                	addi	sp,sp,-64
    800041f0:	fc06                	sd	ra,56(sp)
    800041f2:	f822                	sd	s0,48(sp)
    800041f4:	f426                	sd	s1,40(sp)
    800041f6:	f04a                	sd	s2,32(sp)
    800041f8:	ec4e                	sd	s3,24(sp)
    800041fa:	e852                	sd	s4,16(sp)
    800041fc:	0080                	addi	s0,sp,64
    800041fe:	892a                	mv	s2,a0
    80004200:	8a2e                	mv	s4,a1
    80004202:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004204:	4601                	li	a2,0
    80004206:	00000097          	auipc	ra,0x0
    8000420a:	dd2080e7          	jalr	-558(ra) # 80003fd8 <dirlookup>
    8000420e:	e93d                	bnez	a0,80004284 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004210:	04c92483          	lw	s1,76(s2)
    80004214:	c49d                	beqz	s1,80004242 <dirlink+0x54>
    80004216:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004218:	4741                	li	a4,16
    8000421a:	86a6                	mv	a3,s1
    8000421c:	fc040613          	addi	a2,s0,-64
    80004220:	4581                	li	a1,0
    80004222:	854a                	mv	a0,s2
    80004224:	00000097          	auipc	ra,0x0
    80004228:	b84080e7          	jalr	-1148(ra) # 80003da8 <readi>
    8000422c:	47c1                	li	a5,16
    8000422e:	06f51163          	bne	a0,a5,80004290 <dirlink+0xa2>
    if(de.inum == 0)
    80004232:	fc045783          	lhu	a5,-64(s0)
    80004236:	c791                	beqz	a5,80004242 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004238:	24c1                	addiw	s1,s1,16
    8000423a:	04c92783          	lw	a5,76(s2)
    8000423e:	fcf4ede3          	bltu	s1,a5,80004218 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004242:	4639                	li	a2,14
    80004244:	85d2                	mv	a1,s4
    80004246:	fc240513          	addi	a0,s0,-62
    8000424a:	ffffd097          	auipc	ra,0xffffd
    8000424e:	b94080e7          	jalr	-1132(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004252:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004256:	4741                	li	a4,16
    80004258:	86a6                	mv	a3,s1
    8000425a:	fc040613          	addi	a2,s0,-64
    8000425e:	4581                	li	a1,0
    80004260:	854a                	mv	a0,s2
    80004262:	00000097          	auipc	ra,0x0
    80004266:	c3e080e7          	jalr	-962(ra) # 80003ea0 <writei>
    8000426a:	1541                	addi	a0,a0,-16
    8000426c:	00a03533          	snez	a0,a0
    80004270:	40a00533          	neg	a0,a0
}
    80004274:	70e2                	ld	ra,56(sp)
    80004276:	7442                	ld	s0,48(sp)
    80004278:	74a2                	ld	s1,40(sp)
    8000427a:	7902                	ld	s2,32(sp)
    8000427c:	69e2                	ld	s3,24(sp)
    8000427e:	6a42                	ld	s4,16(sp)
    80004280:	6121                	addi	sp,sp,64
    80004282:	8082                	ret
    iput(ip);
    80004284:	00000097          	auipc	ra,0x0
    80004288:	a2a080e7          	jalr	-1494(ra) # 80003cae <iput>
    return -1;
    8000428c:	557d                	li	a0,-1
    8000428e:	b7dd                	j	80004274 <dirlink+0x86>
      panic("dirlink read");
    80004290:	00004517          	auipc	a0,0x4
    80004294:	3a850513          	addi	a0,a0,936 # 80008638 <syscalls+0x1e0>
    80004298:	ffffc097          	auipc	ra,0xffffc
    8000429c:	2a8080e7          	jalr	680(ra) # 80000540 <panic>

00000000800042a0 <namei>:

struct inode*
namei(char *path)
{
    800042a0:	1101                	addi	sp,sp,-32
    800042a2:	ec06                	sd	ra,24(sp)
    800042a4:	e822                	sd	s0,16(sp)
    800042a6:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    800042a8:	fe040613          	addi	a2,s0,-32
    800042ac:	4581                	li	a1,0
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	dda080e7          	jalr	-550(ra) # 80004088 <namex>
}
    800042b6:	60e2                	ld	ra,24(sp)
    800042b8:	6442                	ld	s0,16(sp)
    800042ba:	6105                	addi	sp,sp,32
    800042bc:	8082                	ret

00000000800042be <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    800042be:	1141                	addi	sp,sp,-16
    800042c0:	e406                	sd	ra,8(sp)
    800042c2:	e022                	sd	s0,0(sp)
    800042c4:	0800                	addi	s0,sp,16
    800042c6:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800042c8:	4585                	li	a1,1
    800042ca:	00000097          	auipc	ra,0x0
    800042ce:	dbe080e7          	jalr	-578(ra) # 80004088 <namex>
}
    800042d2:	60a2                	ld	ra,8(sp)
    800042d4:	6402                	ld	s0,0(sp)
    800042d6:	0141                	addi	sp,sp,16
    800042d8:	8082                	ret

00000000800042da <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800042da:	1101                	addi	sp,sp,-32
    800042dc:	ec06                	sd	ra,24(sp)
    800042de:	e822                	sd	s0,16(sp)
    800042e0:	e426                	sd	s1,8(sp)
    800042e2:	e04a                	sd	s2,0(sp)
    800042e4:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800042e6:	0001d917          	auipc	s2,0x1d
    800042ea:	25a90913          	addi	s2,s2,602 # 80021540 <log>
    800042ee:	01892583          	lw	a1,24(s2)
    800042f2:	02892503          	lw	a0,40(s2)
    800042f6:	fffff097          	auipc	ra,0xfffff
    800042fa:	fe6080e7          	jalr	-26(ra) # 800032dc <bread>
    800042fe:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004300:	02c92683          	lw	a3,44(s2)
    80004304:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004306:	02d05863          	blez	a3,80004336 <write_head+0x5c>
    8000430a:	0001d797          	auipc	a5,0x1d
    8000430e:	26678793          	addi	a5,a5,614 # 80021570 <log+0x30>
    80004312:	05c50713          	addi	a4,a0,92
    80004316:	36fd                	addiw	a3,a3,-1
    80004318:	02069613          	slli	a2,a3,0x20
    8000431c:	01e65693          	srli	a3,a2,0x1e
    80004320:	0001d617          	auipc	a2,0x1d
    80004324:	25460613          	addi	a2,a2,596 # 80021574 <log+0x34>
    80004328:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    8000432a:	4390                	lw	a2,0(a5)
    8000432c:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000432e:	0791                	addi	a5,a5,4
    80004330:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004332:	fed79ce3          	bne	a5,a3,8000432a <write_head+0x50>
  }
  bwrite(buf);
    80004336:	8526                	mv	a0,s1
    80004338:	fffff097          	auipc	ra,0xfffff
    8000433c:	096080e7          	jalr	150(ra) # 800033ce <bwrite>
  brelse(buf);
    80004340:	8526                	mv	a0,s1
    80004342:	fffff097          	auipc	ra,0xfffff
    80004346:	0ca080e7          	jalr	202(ra) # 8000340c <brelse>
}
    8000434a:	60e2                	ld	ra,24(sp)
    8000434c:	6442                	ld	s0,16(sp)
    8000434e:	64a2                	ld	s1,8(sp)
    80004350:	6902                	ld	s2,0(sp)
    80004352:	6105                	addi	sp,sp,32
    80004354:	8082                	ret

0000000080004356 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004356:	0001d797          	auipc	a5,0x1d
    8000435a:	2167a783          	lw	a5,534(a5) # 8002156c <log+0x2c>
    8000435e:	0af05d63          	blez	a5,80004418 <install_trans+0xc2>
{
    80004362:	7139                	addi	sp,sp,-64
    80004364:	fc06                	sd	ra,56(sp)
    80004366:	f822                	sd	s0,48(sp)
    80004368:	f426                	sd	s1,40(sp)
    8000436a:	f04a                	sd	s2,32(sp)
    8000436c:	ec4e                	sd	s3,24(sp)
    8000436e:	e852                	sd	s4,16(sp)
    80004370:	e456                	sd	s5,8(sp)
    80004372:	e05a                	sd	s6,0(sp)
    80004374:	0080                	addi	s0,sp,64
    80004376:	8b2a                	mv	s6,a0
    80004378:	0001da97          	auipc	s5,0x1d
    8000437c:	1f8a8a93          	addi	s5,s5,504 # 80021570 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004380:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004382:	0001d997          	auipc	s3,0x1d
    80004386:	1be98993          	addi	s3,s3,446 # 80021540 <log>
    8000438a:	a00d                	j	800043ac <install_trans+0x56>
    brelse(lbuf);
    8000438c:	854a                	mv	a0,s2
    8000438e:	fffff097          	auipc	ra,0xfffff
    80004392:	07e080e7          	jalr	126(ra) # 8000340c <brelse>
    brelse(dbuf);
    80004396:	8526                	mv	a0,s1
    80004398:	fffff097          	auipc	ra,0xfffff
    8000439c:	074080e7          	jalr	116(ra) # 8000340c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800043a0:	2a05                	addiw	s4,s4,1
    800043a2:	0a91                	addi	s5,s5,4
    800043a4:	02c9a783          	lw	a5,44(s3)
    800043a8:	04fa5e63          	bge	s4,a5,80004404 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    800043ac:	0189a583          	lw	a1,24(s3)
    800043b0:	014585bb          	addw	a1,a1,s4
    800043b4:	2585                	addiw	a1,a1,1
    800043b6:	0289a503          	lw	a0,40(s3)
    800043ba:	fffff097          	auipc	ra,0xfffff
    800043be:	f22080e7          	jalr	-222(ra) # 800032dc <bread>
    800043c2:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800043c4:	000aa583          	lw	a1,0(s5)
    800043c8:	0289a503          	lw	a0,40(s3)
    800043cc:	fffff097          	auipc	ra,0xfffff
    800043d0:	f10080e7          	jalr	-240(ra) # 800032dc <bread>
    800043d4:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800043d6:	40000613          	li	a2,1024
    800043da:	05890593          	addi	a1,s2,88
    800043de:	05850513          	addi	a0,a0,88
    800043e2:	ffffd097          	auipc	ra,0xffffd
    800043e6:	94c080e7          	jalr	-1716(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800043ea:	8526                	mv	a0,s1
    800043ec:	fffff097          	auipc	ra,0xfffff
    800043f0:	fe2080e7          	jalr	-30(ra) # 800033ce <bwrite>
    if(recovering == 0)
    800043f4:	f80b1ce3          	bnez	s6,8000438c <install_trans+0x36>
      bunpin(dbuf);
    800043f8:	8526                	mv	a0,s1
    800043fa:	fffff097          	auipc	ra,0xfffff
    800043fe:	0ec080e7          	jalr	236(ra) # 800034e6 <bunpin>
    80004402:	b769                	j	8000438c <install_trans+0x36>
}
    80004404:	70e2                	ld	ra,56(sp)
    80004406:	7442                	ld	s0,48(sp)
    80004408:	74a2                	ld	s1,40(sp)
    8000440a:	7902                	ld	s2,32(sp)
    8000440c:	69e2                	ld	s3,24(sp)
    8000440e:	6a42                	ld	s4,16(sp)
    80004410:	6aa2                	ld	s5,8(sp)
    80004412:	6b02                	ld	s6,0(sp)
    80004414:	6121                	addi	sp,sp,64
    80004416:	8082                	ret
    80004418:	8082                	ret

000000008000441a <initlog>:
{
    8000441a:	7179                	addi	sp,sp,-48
    8000441c:	f406                	sd	ra,40(sp)
    8000441e:	f022                	sd	s0,32(sp)
    80004420:	ec26                	sd	s1,24(sp)
    80004422:	e84a                	sd	s2,16(sp)
    80004424:	e44e                	sd	s3,8(sp)
    80004426:	1800                	addi	s0,sp,48
    80004428:	892a                	mv	s2,a0
    8000442a:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    8000442c:	0001d497          	auipc	s1,0x1d
    80004430:	11448493          	addi	s1,s1,276 # 80021540 <log>
    80004434:	00004597          	auipc	a1,0x4
    80004438:	21458593          	addi	a1,a1,532 # 80008648 <syscalls+0x1f0>
    8000443c:	8526                	mv	a0,s1
    8000443e:	ffffc097          	auipc	ra,0xffffc
    80004442:	708080e7          	jalr	1800(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004446:	0149a583          	lw	a1,20(s3)
    8000444a:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    8000444c:	0109a783          	lw	a5,16(s3)
    80004450:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004452:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004456:	854a                	mv	a0,s2
    80004458:	fffff097          	auipc	ra,0xfffff
    8000445c:	e84080e7          	jalr	-380(ra) # 800032dc <bread>
  log.lh.n = lh->n;
    80004460:	4d34                	lw	a3,88(a0)
    80004462:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004464:	02d05663          	blez	a3,80004490 <initlog+0x76>
    80004468:	05c50793          	addi	a5,a0,92
    8000446c:	0001d717          	auipc	a4,0x1d
    80004470:	10470713          	addi	a4,a4,260 # 80021570 <log+0x30>
    80004474:	36fd                	addiw	a3,a3,-1
    80004476:	02069613          	slli	a2,a3,0x20
    8000447a:	01e65693          	srli	a3,a2,0x1e
    8000447e:	06050613          	addi	a2,a0,96
    80004482:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004484:	4390                	lw	a2,0(a5)
    80004486:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004488:	0791                	addi	a5,a5,4
    8000448a:	0711                	addi	a4,a4,4
    8000448c:	fed79ce3          	bne	a5,a3,80004484 <initlog+0x6a>
  brelse(buf);
    80004490:	fffff097          	auipc	ra,0xfffff
    80004494:	f7c080e7          	jalr	-132(ra) # 8000340c <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004498:	4505                	li	a0,1
    8000449a:	00000097          	auipc	ra,0x0
    8000449e:	ebc080e7          	jalr	-324(ra) # 80004356 <install_trans>
  log.lh.n = 0;
    800044a2:	0001d797          	auipc	a5,0x1d
    800044a6:	0c07a523          	sw	zero,202(a5) # 8002156c <log+0x2c>
  write_head(); // clear the log
    800044aa:	00000097          	auipc	ra,0x0
    800044ae:	e30080e7          	jalr	-464(ra) # 800042da <write_head>
}
    800044b2:	70a2                	ld	ra,40(sp)
    800044b4:	7402                	ld	s0,32(sp)
    800044b6:	64e2                	ld	s1,24(sp)
    800044b8:	6942                	ld	s2,16(sp)
    800044ba:	69a2                	ld	s3,8(sp)
    800044bc:	6145                	addi	sp,sp,48
    800044be:	8082                	ret

00000000800044c0 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    800044c0:	1101                	addi	sp,sp,-32
    800044c2:	ec06                	sd	ra,24(sp)
    800044c4:	e822                	sd	s0,16(sp)
    800044c6:	e426                	sd	s1,8(sp)
    800044c8:	e04a                	sd	s2,0(sp)
    800044ca:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800044cc:	0001d517          	auipc	a0,0x1d
    800044d0:	07450513          	addi	a0,a0,116 # 80021540 <log>
    800044d4:	ffffc097          	auipc	ra,0xffffc
    800044d8:	702080e7          	jalr	1794(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800044dc:	0001d497          	auipc	s1,0x1d
    800044e0:	06448493          	addi	s1,s1,100 # 80021540 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044e4:	4979                	li	s2,30
    800044e6:	a039                	j	800044f4 <begin_op+0x34>
      sleep(&log, &log.lock);
    800044e8:	85a6                	mv	a1,s1
    800044ea:	8526                	mv	a0,s1
    800044ec:	ffffe097          	auipc	ra,0xffffe
    800044f0:	cd6080e7          	jalr	-810(ra) # 800021c2 <sleep>
    if(log.committing){
    800044f4:	50dc                	lw	a5,36(s1)
    800044f6:	fbed                	bnez	a5,800044e8 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800044f8:	5098                	lw	a4,32(s1)
    800044fa:	2705                	addiw	a4,a4,1
    800044fc:	0007069b          	sext.w	a3,a4
    80004500:	0027179b          	slliw	a5,a4,0x2
    80004504:	9fb9                	addw	a5,a5,a4
    80004506:	0017979b          	slliw	a5,a5,0x1
    8000450a:	54d8                	lw	a4,44(s1)
    8000450c:	9fb9                	addw	a5,a5,a4
    8000450e:	00f95963          	bge	s2,a5,80004520 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004512:	85a6                	mv	a1,s1
    80004514:	8526                	mv	a0,s1
    80004516:	ffffe097          	auipc	ra,0xffffe
    8000451a:	cac080e7          	jalr	-852(ra) # 800021c2 <sleep>
    8000451e:	bfd9                	j	800044f4 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004520:	0001d517          	auipc	a0,0x1d
    80004524:	02050513          	addi	a0,a0,32 # 80021540 <log>
    80004528:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000452a:	ffffc097          	auipc	ra,0xffffc
    8000452e:	760080e7          	jalr	1888(ra) # 80000c8a <release>
      break;
    }
  }
}
    80004532:	60e2                	ld	ra,24(sp)
    80004534:	6442                	ld	s0,16(sp)
    80004536:	64a2                	ld	s1,8(sp)
    80004538:	6902                	ld	s2,0(sp)
    8000453a:	6105                	addi	sp,sp,32
    8000453c:	8082                	ret

000000008000453e <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000453e:	7139                	addi	sp,sp,-64
    80004540:	fc06                	sd	ra,56(sp)
    80004542:	f822                	sd	s0,48(sp)
    80004544:	f426                	sd	s1,40(sp)
    80004546:	f04a                	sd	s2,32(sp)
    80004548:	ec4e                	sd	s3,24(sp)
    8000454a:	e852                	sd	s4,16(sp)
    8000454c:	e456                	sd	s5,8(sp)
    8000454e:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004550:	0001d497          	auipc	s1,0x1d
    80004554:	ff048493          	addi	s1,s1,-16 # 80021540 <log>
    80004558:	8526                	mv	a0,s1
    8000455a:	ffffc097          	auipc	ra,0xffffc
    8000455e:	67c080e7          	jalr	1660(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    80004562:	509c                	lw	a5,32(s1)
    80004564:	37fd                	addiw	a5,a5,-1
    80004566:	0007891b          	sext.w	s2,a5
    8000456a:	d09c                	sw	a5,32(s1)
  if(log.committing)
    8000456c:	50dc                	lw	a5,36(s1)
    8000456e:	e7b9                	bnez	a5,800045bc <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004570:	04091e63          	bnez	s2,800045cc <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004574:	0001d497          	auipc	s1,0x1d
    80004578:	fcc48493          	addi	s1,s1,-52 # 80021540 <log>
    8000457c:	4785                	li	a5,1
    8000457e:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004580:	8526                	mv	a0,s1
    80004582:	ffffc097          	auipc	ra,0xffffc
    80004586:	708080e7          	jalr	1800(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    8000458a:	54dc                	lw	a5,44(s1)
    8000458c:	06f04763          	bgtz	a5,800045fa <end_op+0xbc>
    acquire(&log.lock);
    80004590:	0001d497          	auipc	s1,0x1d
    80004594:	fb048493          	addi	s1,s1,-80 # 80021540 <log>
    80004598:	8526                	mv	a0,s1
    8000459a:	ffffc097          	auipc	ra,0xffffc
    8000459e:	63c080e7          	jalr	1596(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800045a2:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800045a6:	8526                	mv	a0,s1
    800045a8:	ffffe097          	auipc	ra,0xffffe
    800045ac:	c7e080e7          	jalr	-898(ra) # 80002226 <wakeup>
    release(&log.lock);
    800045b0:	8526                	mv	a0,s1
    800045b2:	ffffc097          	auipc	ra,0xffffc
    800045b6:	6d8080e7          	jalr	1752(ra) # 80000c8a <release>
}
    800045ba:	a03d                	j	800045e8 <end_op+0xaa>
    panic("log.committing");
    800045bc:	00004517          	auipc	a0,0x4
    800045c0:	09450513          	addi	a0,a0,148 # 80008650 <syscalls+0x1f8>
    800045c4:	ffffc097          	auipc	ra,0xffffc
    800045c8:	f7c080e7          	jalr	-132(ra) # 80000540 <panic>
    wakeup(&log);
    800045cc:	0001d497          	auipc	s1,0x1d
    800045d0:	f7448493          	addi	s1,s1,-140 # 80021540 <log>
    800045d4:	8526                	mv	a0,s1
    800045d6:	ffffe097          	auipc	ra,0xffffe
    800045da:	c50080e7          	jalr	-944(ra) # 80002226 <wakeup>
  release(&log.lock);
    800045de:	8526                	mv	a0,s1
    800045e0:	ffffc097          	auipc	ra,0xffffc
    800045e4:	6aa080e7          	jalr	1706(ra) # 80000c8a <release>
}
    800045e8:	70e2                	ld	ra,56(sp)
    800045ea:	7442                	ld	s0,48(sp)
    800045ec:	74a2                	ld	s1,40(sp)
    800045ee:	7902                	ld	s2,32(sp)
    800045f0:	69e2                	ld	s3,24(sp)
    800045f2:	6a42                	ld	s4,16(sp)
    800045f4:	6aa2                	ld	s5,8(sp)
    800045f6:	6121                	addi	sp,sp,64
    800045f8:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800045fa:	0001da97          	auipc	s5,0x1d
    800045fe:	f76a8a93          	addi	s5,s5,-138 # 80021570 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004602:	0001da17          	auipc	s4,0x1d
    80004606:	f3ea0a13          	addi	s4,s4,-194 # 80021540 <log>
    8000460a:	018a2583          	lw	a1,24(s4)
    8000460e:	012585bb          	addw	a1,a1,s2
    80004612:	2585                	addiw	a1,a1,1
    80004614:	028a2503          	lw	a0,40(s4)
    80004618:	fffff097          	auipc	ra,0xfffff
    8000461c:	cc4080e7          	jalr	-828(ra) # 800032dc <bread>
    80004620:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004622:	000aa583          	lw	a1,0(s5)
    80004626:	028a2503          	lw	a0,40(s4)
    8000462a:	fffff097          	auipc	ra,0xfffff
    8000462e:	cb2080e7          	jalr	-846(ra) # 800032dc <bread>
    80004632:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004634:	40000613          	li	a2,1024
    80004638:	05850593          	addi	a1,a0,88
    8000463c:	05848513          	addi	a0,s1,88
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	6ee080e7          	jalr	1774(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004648:	8526                	mv	a0,s1
    8000464a:	fffff097          	auipc	ra,0xfffff
    8000464e:	d84080e7          	jalr	-636(ra) # 800033ce <bwrite>
    brelse(from);
    80004652:	854e                	mv	a0,s3
    80004654:	fffff097          	auipc	ra,0xfffff
    80004658:	db8080e7          	jalr	-584(ra) # 8000340c <brelse>
    brelse(to);
    8000465c:	8526                	mv	a0,s1
    8000465e:	fffff097          	auipc	ra,0xfffff
    80004662:	dae080e7          	jalr	-594(ra) # 8000340c <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004666:	2905                	addiw	s2,s2,1
    80004668:	0a91                	addi	s5,s5,4
    8000466a:	02ca2783          	lw	a5,44(s4)
    8000466e:	f8f94ee3          	blt	s2,a5,8000460a <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004672:	00000097          	auipc	ra,0x0
    80004676:	c68080e7          	jalr	-920(ra) # 800042da <write_head>
    install_trans(0); // Now install writes to home locations
    8000467a:	4501                	li	a0,0
    8000467c:	00000097          	auipc	ra,0x0
    80004680:	cda080e7          	jalr	-806(ra) # 80004356 <install_trans>
    log.lh.n = 0;
    80004684:	0001d797          	auipc	a5,0x1d
    80004688:	ee07a423          	sw	zero,-280(a5) # 8002156c <log+0x2c>
    write_head();    // Erase the transaction from the log
    8000468c:	00000097          	auipc	ra,0x0
    80004690:	c4e080e7          	jalr	-946(ra) # 800042da <write_head>
    80004694:	bdf5                	j	80004590 <end_op+0x52>

0000000080004696 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004696:	1101                	addi	sp,sp,-32
    80004698:	ec06                	sd	ra,24(sp)
    8000469a:	e822                	sd	s0,16(sp)
    8000469c:	e426                	sd	s1,8(sp)
    8000469e:	e04a                	sd	s2,0(sp)
    800046a0:	1000                	addi	s0,sp,32
    800046a2:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800046a4:	0001d917          	auipc	s2,0x1d
    800046a8:	e9c90913          	addi	s2,s2,-356 # 80021540 <log>
    800046ac:	854a                	mv	a0,s2
    800046ae:	ffffc097          	auipc	ra,0xffffc
    800046b2:	528080e7          	jalr	1320(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800046b6:	02c92603          	lw	a2,44(s2)
    800046ba:	47f5                	li	a5,29
    800046bc:	06c7c563          	blt	a5,a2,80004726 <log_write+0x90>
    800046c0:	0001d797          	auipc	a5,0x1d
    800046c4:	e9c7a783          	lw	a5,-356(a5) # 8002155c <log+0x1c>
    800046c8:	37fd                	addiw	a5,a5,-1
    800046ca:	04f65e63          	bge	a2,a5,80004726 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800046ce:	0001d797          	auipc	a5,0x1d
    800046d2:	e927a783          	lw	a5,-366(a5) # 80021560 <log+0x20>
    800046d6:	06f05063          	blez	a5,80004736 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800046da:	4781                	li	a5,0
    800046dc:	06c05563          	blez	a2,80004746 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046e0:	44cc                	lw	a1,12(s1)
    800046e2:	0001d717          	auipc	a4,0x1d
    800046e6:	e8e70713          	addi	a4,a4,-370 # 80021570 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800046ea:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800046ec:	4314                	lw	a3,0(a4)
    800046ee:	04b68c63          	beq	a3,a1,80004746 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800046f2:	2785                	addiw	a5,a5,1
    800046f4:	0711                	addi	a4,a4,4
    800046f6:	fef61be3          	bne	a2,a5,800046ec <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800046fa:	0621                	addi	a2,a2,8
    800046fc:	060a                	slli	a2,a2,0x2
    800046fe:	0001d797          	auipc	a5,0x1d
    80004702:	e4278793          	addi	a5,a5,-446 # 80021540 <log>
    80004706:	97b2                	add	a5,a5,a2
    80004708:	44d8                	lw	a4,12(s1)
    8000470a:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000470c:	8526                	mv	a0,s1
    8000470e:	fffff097          	auipc	ra,0xfffff
    80004712:	d9c080e7          	jalr	-612(ra) # 800034aa <bpin>
    log.lh.n++;
    80004716:	0001d717          	auipc	a4,0x1d
    8000471a:	e2a70713          	addi	a4,a4,-470 # 80021540 <log>
    8000471e:	575c                	lw	a5,44(a4)
    80004720:	2785                	addiw	a5,a5,1
    80004722:	d75c                	sw	a5,44(a4)
    80004724:	a82d                	j	8000475e <log_write+0xc8>
    panic("too big a transaction");
    80004726:	00004517          	auipc	a0,0x4
    8000472a:	f3a50513          	addi	a0,a0,-198 # 80008660 <syscalls+0x208>
    8000472e:	ffffc097          	auipc	ra,0xffffc
    80004732:	e12080e7          	jalr	-494(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004736:	00004517          	auipc	a0,0x4
    8000473a:	f4250513          	addi	a0,a0,-190 # 80008678 <syscalls+0x220>
    8000473e:	ffffc097          	auipc	ra,0xffffc
    80004742:	e02080e7          	jalr	-510(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004746:	00878693          	addi	a3,a5,8
    8000474a:	068a                	slli	a3,a3,0x2
    8000474c:	0001d717          	auipc	a4,0x1d
    80004750:	df470713          	addi	a4,a4,-524 # 80021540 <log>
    80004754:	9736                	add	a4,a4,a3
    80004756:	44d4                	lw	a3,12(s1)
    80004758:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000475a:	faf609e3          	beq	a2,a5,8000470c <log_write+0x76>
  }
  release(&log.lock);
    8000475e:	0001d517          	auipc	a0,0x1d
    80004762:	de250513          	addi	a0,a0,-542 # 80021540 <log>
    80004766:	ffffc097          	auipc	ra,0xffffc
    8000476a:	524080e7          	jalr	1316(ra) # 80000c8a <release>
}
    8000476e:	60e2                	ld	ra,24(sp)
    80004770:	6442                	ld	s0,16(sp)
    80004772:	64a2                	ld	s1,8(sp)
    80004774:	6902                	ld	s2,0(sp)
    80004776:	6105                	addi	sp,sp,32
    80004778:	8082                	ret

000000008000477a <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    8000477a:	1101                	addi	sp,sp,-32
    8000477c:	ec06                	sd	ra,24(sp)
    8000477e:	e822                	sd	s0,16(sp)
    80004780:	e426                	sd	s1,8(sp)
    80004782:	e04a                	sd	s2,0(sp)
    80004784:	1000                	addi	s0,sp,32
    80004786:	84aa                	mv	s1,a0
    80004788:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    8000478a:	00004597          	auipc	a1,0x4
    8000478e:	f0e58593          	addi	a1,a1,-242 # 80008698 <syscalls+0x240>
    80004792:	0521                	addi	a0,a0,8
    80004794:	ffffc097          	auipc	ra,0xffffc
    80004798:	3b2080e7          	jalr	946(ra) # 80000b46 <initlock>
  lk->name = name;
    8000479c:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800047a0:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800047a4:	0204a423          	sw	zero,40(s1)
}
    800047a8:	60e2                	ld	ra,24(sp)
    800047aa:	6442                	ld	s0,16(sp)
    800047ac:	64a2                	ld	s1,8(sp)
    800047ae:	6902                	ld	s2,0(sp)
    800047b0:	6105                	addi	sp,sp,32
    800047b2:	8082                	ret

00000000800047b4 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800047b4:	1101                	addi	sp,sp,-32
    800047b6:	ec06                	sd	ra,24(sp)
    800047b8:	e822                	sd	s0,16(sp)
    800047ba:	e426                	sd	s1,8(sp)
    800047bc:	e04a                	sd	s2,0(sp)
    800047be:	1000                	addi	s0,sp,32
    800047c0:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800047c2:	00850913          	addi	s2,a0,8
    800047c6:	854a                	mv	a0,s2
    800047c8:	ffffc097          	auipc	ra,0xffffc
    800047cc:	40e080e7          	jalr	1038(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800047d0:	409c                	lw	a5,0(s1)
    800047d2:	cb89                	beqz	a5,800047e4 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800047d4:	85ca                	mv	a1,s2
    800047d6:	8526                	mv	a0,s1
    800047d8:	ffffe097          	auipc	ra,0xffffe
    800047dc:	9ea080e7          	jalr	-1558(ra) # 800021c2 <sleep>
  while (lk->locked) {
    800047e0:	409c                	lw	a5,0(s1)
    800047e2:	fbed                	bnez	a5,800047d4 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800047e4:	4785                	li	a5,1
    800047e6:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800047e8:	ffffd097          	auipc	ra,0xffffd
    800047ec:	1c4080e7          	jalr	452(ra) # 800019ac <myproc>
    800047f0:	591c                	lw	a5,48(a0)
    800047f2:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800047f4:	854a                	mv	a0,s2
    800047f6:	ffffc097          	auipc	ra,0xffffc
    800047fa:	494080e7          	jalr	1172(ra) # 80000c8a <release>
}
    800047fe:	60e2                	ld	ra,24(sp)
    80004800:	6442                	ld	s0,16(sp)
    80004802:	64a2                	ld	s1,8(sp)
    80004804:	6902                	ld	s2,0(sp)
    80004806:	6105                	addi	sp,sp,32
    80004808:	8082                	ret

000000008000480a <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000480a:	1101                	addi	sp,sp,-32
    8000480c:	ec06                	sd	ra,24(sp)
    8000480e:	e822                	sd	s0,16(sp)
    80004810:	e426                	sd	s1,8(sp)
    80004812:	e04a                	sd	s2,0(sp)
    80004814:	1000                	addi	s0,sp,32
    80004816:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004818:	00850913          	addi	s2,a0,8
    8000481c:	854a                	mv	a0,s2
    8000481e:	ffffc097          	auipc	ra,0xffffc
    80004822:	3b8080e7          	jalr	952(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004826:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000482a:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000482e:	8526                	mv	a0,s1
    80004830:	ffffe097          	auipc	ra,0xffffe
    80004834:	9f6080e7          	jalr	-1546(ra) # 80002226 <wakeup>
  release(&lk->lk);
    80004838:	854a                	mv	a0,s2
    8000483a:	ffffc097          	auipc	ra,0xffffc
    8000483e:	450080e7          	jalr	1104(ra) # 80000c8a <release>
}
    80004842:	60e2                	ld	ra,24(sp)
    80004844:	6442                	ld	s0,16(sp)
    80004846:	64a2                	ld	s1,8(sp)
    80004848:	6902                	ld	s2,0(sp)
    8000484a:	6105                	addi	sp,sp,32
    8000484c:	8082                	ret

000000008000484e <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000484e:	7179                	addi	sp,sp,-48
    80004850:	f406                	sd	ra,40(sp)
    80004852:	f022                	sd	s0,32(sp)
    80004854:	ec26                	sd	s1,24(sp)
    80004856:	e84a                	sd	s2,16(sp)
    80004858:	e44e                	sd	s3,8(sp)
    8000485a:	1800                	addi	s0,sp,48
    8000485c:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000485e:	00850913          	addi	s2,a0,8
    80004862:	854a                	mv	a0,s2
    80004864:	ffffc097          	auipc	ra,0xffffc
    80004868:	372080e7          	jalr	882(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    8000486c:	409c                	lw	a5,0(s1)
    8000486e:	ef99                	bnez	a5,8000488c <holdingsleep+0x3e>
    80004870:	4481                	li	s1,0
  release(&lk->lk);
    80004872:	854a                	mv	a0,s2
    80004874:	ffffc097          	auipc	ra,0xffffc
    80004878:	416080e7          	jalr	1046(ra) # 80000c8a <release>
  return r;
}
    8000487c:	8526                	mv	a0,s1
    8000487e:	70a2                	ld	ra,40(sp)
    80004880:	7402                	ld	s0,32(sp)
    80004882:	64e2                	ld	s1,24(sp)
    80004884:	6942                	ld	s2,16(sp)
    80004886:	69a2                	ld	s3,8(sp)
    80004888:	6145                	addi	sp,sp,48
    8000488a:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    8000488c:	0284a983          	lw	s3,40(s1)
    80004890:	ffffd097          	auipc	ra,0xffffd
    80004894:	11c080e7          	jalr	284(ra) # 800019ac <myproc>
    80004898:	5904                	lw	s1,48(a0)
    8000489a:	413484b3          	sub	s1,s1,s3
    8000489e:	0014b493          	seqz	s1,s1
    800048a2:	bfc1                	j	80004872 <holdingsleep+0x24>

00000000800048a4 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800048a4:	1141                	addi	sp,sp,-16
    800048a6:	e406                	sd	ra,8(sp)
    800048a8:	e022                	sd	s0,0(sp)
    800048aa:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800048ac:	00004597          	auipc	a1,0x4
    800048b0:	dfc58593          	addi	a1,a1,-516 # 800086a8 <syscalls+0x250>
    800048b4:	0001d517          	auipc	a0,0x1d
    800048b8:	dd450513          	addi	a0,a0,-556 # 80021688 <ftable>
    800048bc:	ffffc097          	auipc	ra,0xffffc
    800048c0:	28a080e7          	jalr	650(ra) # 80000b46 <initlock>
}
    800048c4:	60a2                	ld	ra,8(sp)
    800048c6:	6402                	ld	s0,0(sp)
    800048c8:	0141                	addi	sp,sp,16
    800048ca:	8082                	ret

00000000800048cc <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800048cc:	1101                	addi	sp,sp,-32
    800048ce:	ec06                	sd	ra,24(sp)
    800048d0:	e822                	sd	s0,16(sp)
    800048d2:	e426                	sd	s1,8(sp)
    800048d4:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800048d6:	0001d517          	auipc	a0,0x1d
    800048da:	db250513          	addi	a0,a0,-590 # 80021688 <ftable>
    800048de:	ffffc097          	auipc	ra,0xffffc
    800048e2:	2f8080e7          	jalr	760(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048e6:	0001d497          	auipc	s1,0x1d
    800048ea:	dba48493          	addi	s1,s1,-582 # 800216a0 <ftable+0x18>
    800048ee:	0001e717          	auipc	a4,0x1e
    800048f2:	d5270713          	addi	a4,a4,-686 # 80022640 <disk>
    if(f->ref == 0){
    800048f6:	40dc                	lw	a5,4(s1)
    800048f8:	cf99                	beqz	a5,80004916 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800048fa:	02848493          	addi	s1,s1,40
    800048fe:	fee49ce3          	bne	s1,a4,800048f6 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80004902:	0001d517          	auipc	a0,0x1d
    80004906:	d8650513          	addi	a0,a0,-634 # 80021688 <ftable>
    8000490a:	ffffc097          	auipc	ra,0xffffc
    8000490e:	380080e7          	jalr	896(ra) # 80000c8a <release>
  return 0;
    80004912:	4481                	li	s1,0
    80004914:	a819                	j	8000492a <filealloc+0x5e>
      f->ref = 1;
    80004916:	4785                	li	a5,1
    80004918:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000491a:	0001d517          	auipc	a0,0x1d
    8000491e:	d6e50513          	addi	a0,a0,-658 # 80021688 <ftable>
    80004922:	ffffc097          	auipc	ra,0xffffc
    80004926:	368080e7          	jalr	872(ra) # 80000c8a <release>
}
    8000492a:	8526                	mv	a0,s1
    8000492c:	60e2                	ld	ra,24(sp)
    8000492e:	6442                	ld	s0,16(sp)
    80004930:	64a2                	ld	s1,8(sp)
    80004932:	6105                	addi	sp,sp,32
    80004934:	8082                	ret

0000000080004936 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004936:	1101                	addi	sp,sp,-32
    80004938:	ec06                	sd	ra,24(sp)
    8000493a:	e822                	sd	s0,16(sp)
    8000493c:	e426                	sd	s1,8(sp)
    8000493e:	1000                	addi	s0,sp,32
    80004940:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80004942:	0001d517          	auipc	a0,0x1d
    80004946:	d4650513          	addi	a0,a0,-698 # 80021688 <ftable>
    8000494a:	ffffc097          	auipc	ra,0xffffc
    8000494e:	28c080e7          	jalr	652(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004952:	40dc                	lw	a5,4(s1)
    80004954:	02f05263          	blez	a5,80004978 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004958:	2785                	addiw	a5,a5,1
    8000495a:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000495c:	0001d517          	auipc	a0,0x1d
    80004960:	d2c50513          	addi	a0,a0,-724 # 80021688 <ftable>
    80004964:	ffffc097          	auipc	ra,0xffffc
    80004968:	326080e7          	jalr	806(ra) # 80000c8a <release>
  return f;
}
    8000496c:	8526                	mv	a0,s1
    8000496e:	60e2                	ld	ra,24(sp)
    80004970:	6442                	ld	s0,16(sp)
    80004972:	64a2                	ld	s1,8(sp)
    80004974:	6105                	addi	sp,sp,32
    80004976:	8082                	ret
    panic("filedup");
    80004978:	00004517          	auipc	a0,0x4
    8000497c:	d3850513          	addi	a0,a0,-712 # 800086b0 <syscalls+0x258>
    80004980:	ffffc097          	auipc	ra,0xffffc
    80004984:	bc0080e7          	jalr	-1088(ra) # 80000540 <panic>

0000000080004988 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004988:	7139                	addi	sp,sp,-64
    8000498a:	fc06                	sd	ra,56(sp)
    8000498c:	f822                	sd	s0,48(sp)
    8000498e:	f426                	sd	s1,40(sp)
    80004990:	f04a                	sd	s2,32(sp)
    80004992:	ec4e                	sd	s3,24(sp)
    80004994:	e852                	sd	s4,16(sp)
    80004996:	e456                	sd	s5,8(sp)
    80004998:	0080                	addi	s0,sp,64
    8000499a:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    8000499c:	0001d517          	auipc	a0,0x1d
    800049a0:	cec50513          	addi	a0,a0,-788 # 80021688 <ftable>
    800049a4:	ffffc097          	auipc	ra,0xffffc
    800049a8:	232080e7          	jalr	562(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800049ac:	40dc                	lw	a5,4(s1)
    800049ae:	06f05163          	blez	a5,80004a10 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800049b2:	37fd                	addiw	a5,a5,-1
    800049b4:	0007871b          	sext.w	a4,a5
    800049b8:	c0dc                	sw	a5,4(s1)
    800049ba:	06e04363          	bgtz	a4,80004a20 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800049be:	0004a903          	lw	s2,0(s1)
    800049c2:	0094ca83          	lbu	s5,9(s1)
    800049c6:	0104ba03          	ld	s4,16(s1)
    800049ca:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800049ce:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800049d2:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800049d6:	0001d517          	auipc	a0,0x1d
    800049da:	cb250513          	addi	a0,a0,-846 # 80021688 <ftable>
    800049de:	ffffc097          	auipc	ra,0xffffc
    800049e2:	2ac080e7          	jalr	684(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800049e6:	4785                	li	a5,1
    800049e8:	04f90d63          	beq	s2,a5,80004a42 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800049ec:	3979                	addiw	s2,s2,-2
    800049ee:	4785                	li	a5,1
    800049f0:	0527e063          	bltu	a5,s2,80004a30 <fileclose+0xa8>
    begin_op();
    800049f4:	00000097          	auipc	ra,0x0
    800049f8:	acc080e7          	jalr	-1332(ra) # 800044c0 <begin_op>
    iput(ff.ip);
    800049fc:	854e                	mv	a0,s3
    800049fe:	fffff097          	auipc	ra,0xfffff
    80004a02:	2b0080e7          	jalr	688(ra) # 80003cae <iput>
    end_op();
    80004a06:	00000097          	auipc	ra,0x0
    80004a0a:	b38080e7          	jalr	-1224(ra) # 8000453e <end_op>
    80004a0e:	a00d                	j	80004a30 <fileclose+0xa8>
    panic("fileclose");
    80004a10:	00004517          	auipc	a0,0x4
    80004a14:	ca850513          	addi	a0,a0,-856 # 800086b8 <syscalls+0x260>
    80004a18:	ffffc097          	auipc	ra,0xffffc
    80004a1c:	b28080e7          	jalr	-1240(ra) # 80000540 <panic>
    release(&ftable.lock);
    80004a20:	0001d517          	auipc	a0,0x1d
    80004a24:	c6850513          	addi	a0,a0,-920 # 80021688 <ftable>
    80004a28:	ffffc097          	auipc	ra,0xffffc
    80004a2c:	262080e7          	jalr	610(ra) # 80000c8a <release>
  }
}
    80004a30:	70e2                	ld	ra,56(sp)
    80004a32:	7442                	ld	s0,48(sp)
    80004a34:	74a2                	ld	s1,40(sp)
    80004a36:	7902                	ld	s2,32(sp)
    80004a38:	69e2                	ld	s3,24(sp)
    80004a3a:	6a42                	ld	s4,16(sp)
    80004a3c:	6aa2                	ld	s5,8(sp)
    80004a3e:	6121                	addi	sp,sp,64
    80004a40:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80004a42:	85d6                	mv	a1,s5
    80004a44:	8552                	mv	a0,s4
    80004a46:	00000097          	auipc	ra,0x0
    80004a4a:	34c080e7          	jalr	844(ra) # 80004d92 <pipeclose>
    80004a4e:	b7cd                	j	80004a30 <fileclose+0xa8>

0000000080004a50 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80004a50:	715d                	addi	sp,sp,-80
    80004a52:	e486                	sd	ra,72(sp)
    80004a54:	e0a2                	sd	s0,64(sp)
    80004a56:	fc26                	sd	s1,56(sp)
    80004a58:	f84a                	sd	s2,48(sp)
    80004a5a:	f44e                	sd	s3,40(sp)
    80004a5c:	0880                	addi	s0,sp,80
    80004a5e:	84aa                	mv	s1,a0
    80004a60:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80004a62:	ffffd097          	auipc	ra,0xffffd
    80004a66:	f4a080e7          	jalr	-182(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004a6a:	409c                	lw	a5,0(s1)
    80004a6c:	37f9                	addiw	a5,a5,-2
    80004a6e:	4705                	li	a4,1
    80004a70:	04f76763          	bltu	a4,a5,80004abe <filestat+0x6e>
    80004a74:	892a                	mv	s2,a0
    ilock(f->ip);
    80004a76:	6c88                	ld	a0,24(s1)
    80004a78:	fffff097          	auipc	ra,0xfffff
    80004a7c:	07c080e7          	jalr	124(ra) # 80003af4 <ilock>
    stati(f->ip, &st);
    80004a80:	fb840593          	addi	a1,s0,-72
    80004a84:	6c88                	ld	a0,24(s1)
    80004a86:	fffff097          	auipc	ra,0xfffff
    80004a8a:	2f8080e7          	jalr	760(ra) # 80003d7e <stati>
    iunlock(f->ip);
    80004a8e:	6c88                	ld	a0,24(s1)
    80004a90:	fffff097          	auipc	ra,0xfffff
    80004a94:	126080e7          	jalr	294(ra) # 80003bb6 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004a98:	46e1                	li	a3,24
    80004a9a:	fb840613          	addi	a2,s0,-72
    80004a9e:	85ce                	mv	a1,s3
    80004aa0:	05093503          	ld	a0,80(s2)
    80004aa4:	ffffd097          	auipc	ra,0xffffd
    80004aa8:	bc8080e7          	jalr	-1080(ra) # 8000166c <copyout>
    80004aac:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    80004ab0:	60a6                	ld	ra,72(sp)
    80004ab2:	6406                	ld	s0,64(sp)
    80004ab4:	74e2                	ld	s1,56(sp)
    80004ab6:	7942                	ld	s2,48(sp)
    80004ab8:	79a2                	ld	s3,40(sp)
    80004aba:	6161                	addi	sp,sp,80
    80004abc:	8082                	ret
  return -1;
    80004abe:	557d                	li	a0,-1
    80004ac0:	bfc5                	j	80004ab0 <filestat+0x60>

0000000080004ac2 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80004ac2:	7179                	addi	sp,sp,-48
    80004ac4:	f406                	sd	ra,40(sp)
    80004ac6:	f022                	sd	s0,32(sp)
    80004ac8:	ec26                	sd	s1,24(sp)
    80004aca:	e84a                	sd	s2,16(sp)
    80004acc:	e44e                	sd	s3,8(sp)
    80004ace:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80004ad0:	00854783          	lbu	a5,8(a0)
    80004ad4:	c3d5                	beqz	a5,80004b78 <fileread+0xb6>
    80004ad6:	84aa                	mv	s1,a0
    80004ad8:	89ae                	mv	s3,a1
    80004ada:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004adc:	411c                	lw	a5,0(a0)
    80004ade:	4705                	li	a4,1
    80004ae0:	04e78963          	beq	a5,a4,80004b32 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004ae4:	470d                	li	a4,3
    80004ae6:	04e78d63          	beq	a5,a4,80004b40 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004aea:	4709                	li	a4,2
    80004aec:	06e79e63          	bne	a5,a4,80004b68 <fileread+0xa6>
    ilock(f->ip);
    80004af0:	6d08                	ld	a0,24(a0)
    80004af2:	fffff097          	auipc	ra,0xfffff
    80004af6:	002080e7          	jalr	2(ra) # 80003af4 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004afa:	874a                	mv	a4,s2
    80004afc:	5094                	lw	a3,32(s1)
    80004afe:	864e                	mv	a2,s3
    80004b00:	4585                	li	a1,1
    80004b02:	6c88                	ld	a0,24(s1)
    80004b04:	fffff097          	auipc	ra,0xfffff
    80004b08:	2a4080e7          	jalr	676(ra) # 80003da8 <readi>
    80004b0c:	892a                	mv	s2,a0
    80004b0e:	00a05563          	blez	a0,80004b18 <fileread+0x56>
      f->off += r;
    80004b12:	509c                	lw	a5,32(s1)
    80004b14:	9fa9                	addw	a5,a5,a0
    80004b16:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    80004b18:	6c88                	ld	a0,24(s1)
    80004b1a:	fffff097          	auipc	ra,0xfffff
    80004b1e:	09c080e7          	jalr	156(ra) # 80003bb6 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80004b22:	854a                	mv	a0,s2
    80004b24:	70a2                	ld	ra,40(sp)
    80004b26:	7402                	ld	s0,32(sp)
    80004b28:	64e2                	ld	s1,24(sp)
    80004b2a:	6942                	ld	s2,16(sp)
    80004b2c:	69a2                	ld	s3,8(sp)
    80004b2e:	6145                	addi	sp,sp,48
    80004b30:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80004b32:	6908                	ld	a0,16(a0)
    80004b34:	00000097          	auipc	ra,0x0
    80004b38:	3c6080e7          	jalr	966(ra) # 80004efa <piperead>
    80004b3c:	892a                	mv	s2,a0
    80004b3e:	b7d5                	j	80004b22 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80004b40:	02451783          	lh	a5,36(a0)
    80004b44:	03079693          	slli	a3,a5,0x30
    80004b48:	92c1                	srli	a3,a3,0x30
    80004b4a:	4725                	li	a4,9
    80004b4c:	02d76863          	bltu	a4,a3,80004b7c <fileread+0xba>
    80004b50:	0792                	slli	a5,a5,0x4
    80004b52:	0001d717          	auipc	a4,0x1d
    80004b56:	a9670713          	addi	a4,a4,-1386 # 800215e8 <devsw>
    80004b5a:	97ba                	add	a5,a5,a4
    80004b5c:	639c                	ld	a5,0(a5)
    80004b5e:	c38d                	beqz	a5,80004b80 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004b60:	4505                	li	a0,1
    80004b62:	9782                	jalr	a5
    80004b64:	892a                	mv	s2,a0
    80004b66:	bf75                	j	80004b22 <fileread+0x60>
    panic("fileread");
    80004b68:	00004517          	auipc	a0,0x4
    80004b6c:	b6050513          	addi	a0,a0,-1184 # 800086c8 <syscalls+0x270>
    80004b70:	ffffc097          	auipc	ra,0xffffc
    80004b74:	9d0080e7          	jalr	-1584(ra) # 80000540 <panic>
    return -1;
    80004b78:	597d                	li	s2,-1
    80004b7a:	b765                	j	80004b22 <fileread+0x60>
      return -1;
    80004b7c:	597d                	li	s2,-1
    80004b7e:	b755                	j	80004b22 <fileread+0x60>
    80004b80:	597d                	li	s2,-1
    80004b82:	b745                	j	80004b22 <fileread+0x60>

0000000080004b84 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004b84:	715d                	addi	sp,sp,-80
    80004b86:	e486                	sd	ra,72(sp)
    80004b88:	e0a2                	sd	s0,64(sp)
    80004b8a:	fc26                	sd	s1,56(sp)
    80004b8c:	f84a                	sd	s2,48(sp)
    80004b8e:	f44e                	sd	s3,40(sp)
    80004b90:	f052                	sd	s4,32(sp)
    80004b92:	ec56                	sd	s5,24(sp)
    80004b94:	e85a                	sd	s6,16(sp)
    80004b96:	e45e                	sd	s7,8(sp)
    80004b98:	e062                	sd	s8,0(sp)
    80004b9a:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004b9c:	00954783          	lbu	a5,9(a0)
    80004ba0:	10078663          	beqz	a5,80004cac <filewrite+0x128>
    80004ba4:	892a                	mv	s2,a0
    80004ba6:	8b2e                	mv	s6,a1
    80004ba8:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004baa:	411c                	lw	a5,0(a0)
    80004bac:	4705                	li	a4,1
    80004bae:	02e78263          	beq	a5,a4,80004bd2 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004bb2:	470d                	li	a4,3
    80004bb4:	02e78663          	beq	a5,a4,80004be0 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004bb8:	4709                	li	a4,2
    80004bba:	0ee79163          	bne	a5,a4,80004c9c <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004bbe:	0ac05d63          	blez	a2,80004c78 <filewrite+0xf4>
    int i = 0;
    80004bc2:	4981                	li	s3,0
    80004bc4:	6b85                	lui	s7,0x1
    80004bc6:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004bca:	6c05                	lui	s8,0x1
    80004bcc:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80004bd0:	a861                	j	80004c68 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004bd2:	6908                	ld	a0,16(a0)
    80004bd4:	00000097          	auipc	ra,0x0
    80004bd8:	22e080e7          	jalr	558(ra) # 80004e02 <pipewrite>
    80004bdc:	8a2a                	mv	s4,a0
    80004bde:	a045                	j	80004c7e <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004be0:	02451783          	lh	a5,36(a0)
    80004be4:	03079693          	slli	a3,a5,0x30
    80004be8:	92c1                	srli	a3,a3,0x30
    80004bea:	4725                	li	a4,9
    80004bec:	0cd76263          	bltu	a4,a3,80004cb0 <filewrite+0x12c>
    80004bf0:	0792                	slli	a5,a5,0x4
    80004bf2:	0001d717          	auipc	a4,0x1d
    80004bf6:	9f670713          	addi	a4,a4,-1546 # 800215e8 <devsw>
    80004bfa:	97ba                	add	a5,a5,a4
    80004bfc:	679c                	ld	a5,8(a5)
    80004bfe:	cbdd                	beqz	a5,80004cb4 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004c00:	4505                	li	a0,1
    80004c02:	9782                	jalr	a5
    80004c04:	8a2a                	mv	s4,a0
    80004c06:	a8a5                	j	80004c7e <filewrite+0xfa>
    80004c08:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004c0c:	00000097          	auipc	ra,0x0
    80004c10:	8b4080e7          	jalr	-1868(ra) # 800044c0 <begin_op>
      ilock(f->ip);
    80004c14:	01893503          	ld	a0,24(s2)
    80004c18:	fffff097          	auipc	ra,0xfffff
    80004c1c:	edc080e7          	jalr	-292(ra) # 80003af4 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004c20:	8756                	mv	a4,s5
    80004c22:	02092683          	lw	a3,32(s2)
    80004c26:	01698633          	add	a2,s3,s6
    80004c2a:	4585                	li	a1,1
    80004c2c:	01893503          	ld	a0,24(s2)
    80004c30:	fffff097          	auipc	ra,0xfffff
    80004c34:	270080e7          	jalr	624(ra) # 80003ea0 <writei>
    80004c38:	84aa                	mv	s1,a0
    80004c3a:	00a05763          	blez	a0,80004c48 <filewrite+0xc4>
        f->off += r;
    80004c3e:	02092783          	lw	a5,32(s2)
    80004c42:	9fa9                	addw	a5,a5,a0
    80004c44:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004c48:	01893503          	ld	a0,24(s2)
    80004c4c:	fffff097          	auipc	ra,0xfffff
    80004c50:	f6a080e7          	jalr	-150(ra) # 80003bb6 <iunlock>
      end_op();
    80004c54:	00000097          	auipc	ra,0x0
    80004c58:	8ea080e7          	jalr	-1814(ra) # 8000453e <end_op>

      if(r != n1){
    80004c5c:	009a9f63          	bne	s5,s1,80004c7a <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004c60:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004c64:	0149db63          	bge	s3,s4,80004c7a <filewrite+0xf6>
      int n1 = n - i;
    80004c68:	413a04bb          	subw	s1,s4,s3
    80004c6c:	0004879b          	sext.w	a5,s1
    80004c70:	f8fbdce3          	bge	s7,a5,80004c08 <filewrite+0x84>
    80004c74:	84e2                	mv	s1,s8
    80004c76:	bf49                	j	80004c08 <filewrite+0x84>
    int i = 0;
    80004c78:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004c7a:	013a1f63          	bne	s4,s3,80004c98 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004c7e:	8552                	mv	a0,s4
    80004c80:	60a6                	ld	ra,72(sp)
    80004c82:	6406                	ld	s0,64(sp)
    80004c84:	74e2                	ld	s1,56(sp)
    80004c86:	7942                	ld	s2,48(sp)
    80004c88:	79a2                	ld	s3,40(sp)
    80004c8a:	7a02                	ld	s4,32(sp)
    80004c8c:	6ae2                	ld	s5,24(sp)
    80004c8e:	6b42                	ld	s6,16(sp)
    80004c90:	6ba2                	ld	s7,8(sp)
    80004c92:	6c02                	ld	s8,0(sp)
    80004c94:	6161                	addi	sp,sp,80
    80004c96:	8082                	ret
    ret = (i == n ? n : -1);
    80004c98:	5a7d                	li	s4,-1
    80004c9a:	b7d5                	j	80004c7e <filewrite+0xfa>
    panic("filewrite");
    80004c9c:	00004517          	auipc	a0,0x4
    80004ca0:	a3c50513          	addi	a0,a0,-1476 # 800086d8 <syscalls+0x280>
    80004ca4:	ffffc097          	auipc	ra,0xffffc
    80004ca8:	89c080e7          	jalr	-1892(ra) # 80000540 <panic>
    return -1;
    80004cac:	5a7d                	li	s4,-1
    80004cae:	bfc1                	j	80004c7e <filewrite+0xfa>
      return -1;
    80004cb0:	5a7d                	li	s4,-1
    80004cb2:	b7f1                	j	80004c7e <filewrite+0xfa>
    80004cb4:	5a7d                	li	s4,-1
    80004cb6:	b7e1                	j	80004c7e <filewrite+0xfa>

0000000080004cb8 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004cb8:	7179                	addi	sp,sp,-48
    80004cba:	f406                	sd	ra,40(sp)
    80004cbc:	f022                	sd	s0,32(sp)
    80004cbe:	ec26                	sd	s1,24(sp)
    80004cc0:	e84a                	sd	s2,16(sp)
    80004cc2:	e44e                	sd	s3,8(sp)
    80004cc4:	e052                	sd	s4,0(sp)
    80004cc6:	1800                	addi	s0,sp,48
    80004cc8:	84aa                	mv	s1,a0
    80004cca:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004ccc:	0005b023          	sd	zero,0(a1)
    80004cd0:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004cd4:	00000097          	auipc	ra,0x0
    80004cd8:	bf8080e7          	jalr	-1032(ra) # 800048cc <filealloc>
    80004cdc:	e088                	sd	a0,0(s1)
    80004cde:	c551                	beqz	a0,80004d6a <pipealloc+0xb2>
    80004ce0:	00000097          	auipc	ra,0x0
    80004ce4:	bec080e7          	jalr	-1044(ra) # 800048cc <filealloc>
    80004ce8:	00aa3023          	sd	a0,0(s4)
    80004cec:	c92d                	beqz	a0,80004d5e <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004cee:	ffffc097          	auipc	ra,0xffffc
    80004cf2:	df8080e7          	jalr	-520(ra) # 80000ae6 <kalloc>
    80004cf6:	892a                	mv	s2,a0
    80004cf8:	c125                	beqz	a0,80004d58 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004cfa:	4985                	li	s3,1
    80004cfc:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d00:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d04:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004d08:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004d0c:	00004597          	auipc	a1,0x4
    80004d10:	9dc58593          	addi	a1,a1,-1572 # 800086e8 <syscalls+0x290>
    80004d14:	ffffc097          	auipc	ra,0xffffc
    80004d18:	e32080e7          	jalr	-462(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004d1c:	609c                	ld	a5,0(s1)
    80004d1e:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004d22:	609c                	ld	a5,0(s1)
    80004d24:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004d28:	609c                	ld	a5,0(s1)
    80004d2a:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004d2e:	609c                	ld	a5,0(s1)
    80004d30:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004d34:	000a3783          	ld	a5,0(s4)
    80004d38:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004d3c:	000a3783          	ld	a5,0(s4)
    80004d40:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004d44:	000a3783          	ld	a5,0(s4)
    80004d48:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004d4c:	000a3783          	ld	a5,0(s4)
    80004d50:	0127b823          	sd	s2,16(a5)
  return 0;
    80004d54:	4501                	li	a0,0
    80004d56:	a025                	j	80004d7e <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004d58:	6088                	ld	a0,0(s1)
    80004d5a:	e501                	bnez	a0,80004d62 <pipealloc+0xaa>
    80004d5c:	a039                	j	80004d6a <pipealloc+0xb2>
    80004d5e:	6088                	ld	a0,0(s1)
    80004d60:	c51d                	beqz	a0,80004d8e <pipealloc+0xd6>
    fileclose(*f0);
    80004d62:	00000097          	auipc	ra,0x0
    80004d66:	c26080e7          	jalr	-986(ra) # 80004988 <fileclose>
  if(*f1)
    80004d6a:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004d6e:	557d                	li	a0,-1
  if(*f1)
    80004d70:	c799                	beqz	a5,80004d7e <pipealloc+0xc6>
    fileclose(*f1);
    80004d72:	853e                	mv	a0,a5
    80004d74:	00000097          	auipc	ra,0x0
    80004d78:	c14080e7          	jalr	-1004(ra) # 80004988 <fileclose>
  return -1;
    80004d7c:	557d                	li	a0,-1
}
    80004d7e:	70a2                	ld	ra,40(sp)
    80004d80:	7402                	ld	s0,32(sp)
    80004d82:	64e2                	ld	s1,24(sp)
    80004d84:	6942                	ld	s2,16(sp)
    80004d86:	69a2                	ld	s3,8(sp)
    80004d88:	6a02                	ld	s4,0(sp)
    80004d8a:	6145                	addi	sp,sp,48
    80004d8c:	8082                	ret
  return -1;
    80004d8e:	557d                	li	a0,-1
    80004d90:	b7fd                	j	80004d7e <pipealloc+0xc6>

0000000080004d92 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004d92:	1101                	addi	sp,sp,-32
    80004d94:	ec06                	sd	ra,24(sp)
    80004d96:	e822                	sd	s0,16(sp)
    80004d98:	e426                	sd	s1,8(sp)
    80004d9a:	e04a                	sd	s2,0(sp)
    80004d9c:	1000                	addi	s0,sp,32
    80004d9e:	84aa                	mv	s1,a0
    80004da0:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004da2:	ffffc097          	auipc	ra,0xffffc
    80004da6:	e34080e7          	jalr	-460(ra) # 80000bd6 <acquire>
  if(writable){
    80004daa:	02090d63          	beqz	s2,80004de4 <pipeclose+0x52>
    pi->writeopen = 0;
    80004dae:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004db2:	21848513          	addi	a0,s1,536
    80004db6:	ffffd097          	auipc	ra,0xffffd
    80004dba:	470080e7          	jalr	1136(ra) # 80002226 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004dbe:	2204b783          	ld	a5,544(s1)
    80004dc2:	eb95                	bnez	a5,80004df6 <pipeclose+0x64>
    release(&pi->lock);
    80004dc4:	8526                	mv	a0,s1
    80004dc6:	ffffc097          	auipc	ra,0xffffc
    80004dca:	ec4080e7          	jalr	-316(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004dce:	8526                	mv	a0,s1
    80004dd0:	ffffc097          	auipc	ra,0xffffc
    80004dd4:	c18080e7          	jalr	-1000(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004dd8:	60e2                	ld	ra,24(sp)
    80004dda:	6442                	ld	s0,16(sp)
    80004ddc:	64a2                	ld	s1,8(sp)
    80004dde:	6902                	ld	s2,0(sp)
    80004de0:	6105                	addi	sp,sp,32
    80004de2:	8082                	ret
    pi->readopen = 0;
    80004de4:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004de8:	21c48513          	addi	a0,s1,540
    80004dec:	ffffd097          	auipc	ra,0xffffd
    80004df0:	43a080e7          	jalr	1082(ra) # 80002226 <wakeup>
    80004df4:	b7e9                	j	80004dbe <pipeclose+0x2c>
    release(&pi->lock);
    80004df6:	8526                	mv	a0,s1
    80004df8:	ffffc097          	auipc	ra,0xffffc
    80004dfc:	e92080e7          	jalr	-366(ra) # 80000c8a <release>
}
    80004e00:	bfe1                	j	80004dd8 <pipeclose+0x46>

0000000080004e02 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e02:	711d                	addi	sp,sp,-96
    80004e04:	ec86                	sd	ra,88(sp)
    80004e06:	e8a2                	sd	s0,80(sp)
    80004e08:	e4a6                	sd	s1,72(sp)
    80004e0a:	e0ca                	sd	s2,64(sp)
    80004e0c:	fc4e                	sd	s3,56(sp)
    80004e0e:	f852                	sd	s4,48(sp)
    80004e10:	f456                	sd	s5,40(sp)
    80004e12:	f05a                	sd	s6,32(sp)
    80004e14:	ec5e                	sd	s7,24(sp)
    80004e16:	e862                	sd	s8,16(sp)
    80004e18:	1080                	addi	s0,sp,96
    80004e1a:	84aa                	mv	s1,a0
    80004e1c:	8aae                	mv	s5,a1
    80004e1e:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004e20:	ffffd097          	auipc	ra,0xffffd
    80004e24:	b8c080e7          	jalr	-1140(ra) # 800019ac <myproc>
    80004e28:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004e2a:	8526                	mv	a0,s1
    80004e2c:	ffffc097          	auipc	ra,0xffffc
    80004e30:	daa080e7          	jalr	-598(ra) # 80000bd6 <acquire>
  while(i < n){
    80004e34:	0b405663          	blez	s4,80004ee0 <pipewrite+0xde>
  int i = 0;
    80004e38:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004e3a:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004e3c:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004e40:	21c48b93          	addi	s7,s1,540
    80004e44:	a089                	j	80004e86 <pipewrite+0x84>
      release(&pi->lock);
    80004e46:	8526                	mv	a0,s1
    80004e48:	ffffc097          	auipc	ra,0xffffc
    80004e4c:	e42080e7          	jalr	-446(ra) # 80000c8a <release>
      return -1;
    80004e50:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004e52:	854a                	mv	a0,s2
    80004e54:	60e6                	ld	ra,88(sp)
    80004e56:	6446                	ld	s0,80(sp)
    80004e58:	64a6                	ld	s1,72(sp)
    80004e5a:	6906                	ld	s2,64(sp)
    80004e5c:	79e2                	ld	s3,56(sp)
    80004e5e:	7a42                	ld	s4,48(sp)
    80004e60:	7aa2                	ld	s5,40(sp)
    80004e62:	7b02                	ld	s6,32(sp)
    80004e64:	6be2                	ld	s7,24(sp)
    80004e66:	6c42                	ld	s8,16(sp)
    80004e68:	6125                	addi	sp,sp,96
    80004e6a:	8082                	ret
      wakeup(&pi->nread);
    80004e6c:	8562                	mv	a0,s8
    80004e6e:	ffffd097          	auipc	ra,0xffffd
    80004e72:	3b8080e7          	jalr	952(ra) # 80002226 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004e76:	85a6                	mv	a1,s1
    80004e78:	855e                	mv	a0,s7
    80004e7a:	ffffd097          	auipc	ra,0xffffd
    80004e7e:	348080e7          	jalr	840(ra) # 800021c2 <sleep>
  while(i < n){
    80004e82:	07495063          	bge	s2,s4,80004ee2 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004e86:	2204a783          	lw	a5,544(s1)
    80004e8a:	dfd5                	beqz	a5,80004e46 <pipewrite+0x44>
    80004e8c:	854e                	mv	a0,s3
    80004e8e:	ffffd097          	auipc	ra,0xffffd
    80004e92:	5e8080e7          	jalr	1512(ra) # 80002476 <killed>
    80004e96:	f945                	bnez	a0,80004e46 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004e98:	2184a783          	lw	a5,536(s1)
    80004e9c:	21c4a703          	lw	a4,540(s1)
    80004ea0:	2007879b          	addiw	a5,a5,512
    80004ea4:	fcf704e3          	beq	a4,a5,80004e6c <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ea8:	4685                	li	a3,1
    80004eaa:	01590633          	add	a2,s2,s5
    80004eae:	faf40593          	addi	a1,s0,-81
    80004eb2:	0509b503          	ld	a0,80(s3)
    80004eb6:	ffffd097          	auipc	ra,0xffffd
    80004eba:	842080e7          	jalr	-1982(ra) # 800016f8 <copyin>
    80004ebe:	03650263          	beq	a0,s6,80004ee2 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004ec2:	21c4a783          	lw	a5,540(s1)
    80004ec6:	0017871b          	addiw	a4,a5,1
    80004eca:	20e4ae23          	sw	a4,540(s1)
    80004ece:	1ff7f793          	andi	a5,a5,511
    80004ed2:	97a6                	add	a5,a5,s1
    80004ed4:	faf44703          	lbu	a4,-81(s0)
    80004ed8:	00e78c23          	sb	a4,24(a5)
      i++;
    80004edc:	2905                	addiw	s2,s2,1
    80004ede:	b755                	j	80004e82 <pipewrite+0x80>
  int i = 0;
    80004ee0:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004ee2:	21848513          	addi	a0,s1,536
    80004ee6:	ffffd097          	auipc	ra,0xffffd
    80004eea:	340080e7          	jalr	832(ra) # 80002226 <wakeup>
  release(&pi->lock);
    80004eee:	8526                	mv	a0,s1
    80004ef0:	ffffc097          	auipc	ra,0xffffc
    80004ef4:	d9a080e7          	jalr	-614(ra) # 80000c8a <release>
  return i;
    80004ef8:	bfa9                	j	80004e52 <pipewrite+0x50>

0000000080004efa <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004efa:	715d                	addi	sp,sp,-80
    80004efc:	e486                	sd	ra,72(sp)
    80004efe:	e0a2                	sd	s0,64(sp)
    80004f00:	fc26                	sd	s1,56(sp)
    80004f02:	f84a                	sd	s2,48(sp)
    80004f04:	f44e                	sd	s3,40(sp)
    80004f06:	f052                	sd	s4,32(sp)
    80004f08:	ec56                	sd	s5,24(sp)
    80004f0a:	e85a                	sd	s6,16(sp)
    80004f0c:	0880                	addi	s0,sp,80
    80004f0e:	84aa                	mv	s1,a0
    80004f10:	892e                	mv	s2,a1
    80004f12:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004f14:	ffffd097          	auipc	ra,0xffffd
    80004f18:	a98080e7          	jalr	-1384(ra) # 800019ac <myproc>
    80004f1c:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004f1e:	8526                	mv	a0,s1
    80004f20:	ffffc097          	auipc	ra,0xffffc
    80004f24:	cb6080e7          	jalr	-842(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f28:	2184a703          	lw	a4,536(s1)
    80004f2c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f30:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f34:	02f71763          	bne	a4,a5,80004f62 <piperead+0x68>
    80004f38:	2244a783          	lw	a5,548(s1)
    80004f3c:	c39d                	beqz	a5,80004f62 <piperead+0x68>
    if(killed(pr)){
    80004f3e:	8552                	mv	a0,s4
    80004f40:	ffffd097          	auipc	ra,0xffffd
    80004f44:	536080e7          	jalr	1334(ra) # 80002476 <killed>
    80004f48:	e949                	bnez	a0,80004fda <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004f4a:	85a6                	mv	a1,s1
    80004f4c:	854e                	mv	a0,s3
    80004f4e:	ffffd097          	auipc	ra,0xffffd
    80004f52:	274080e7          	jalr	628(ra) # 800021c2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004f56:	2184a703          	lw	a4,536(s1)
    80004f5a:	21c4a783          	lw	a5,540(s1)
    80004f5e:	fcf70de3          	beq	a4,a5,80004f38 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f62:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f64:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004f66:	05505463          	blez	s5,80004fae <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004f6a:	2184a783          	lw	a5,536(s1)
    80004f6e:	21c4a703          	lw	a4,540(s1)
    80004f72:	02f70e63          	beq	a4,a5,80004fae <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004f76:	0017871b          	addiw	a4,a5,1
    80004f7a:	20e4ac23          	sw	a4,536(s1)
    80004f7e:	1ff7f793          	andi	a5,a5,511
    80004f82:	97a6                	add	a5,a5,s1
    80004f84:	0187c783          	lbu	a5,24(a5)
    80004f88:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004f8c:	4685                	li	a3,1
    80004f8e:	fbf40613          	addi	a2,s0,-65
    80004f92:	85ca                	mv	a1,s2
    80004f94:	050a3503          	ld	a0,80(s4)
    80004f98:	ffffc097          	auipc	ra,0xffffc
    80004f9c:	6d4080e7          	jalr	1748(ra) # 8000166c <copyout>
    80004fa0:	01650763          	beq	a0,s6,80004fae <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004fa4:	2985                	addiw	s3,s3,1
    80004fa6:	0905                	addi	s2,s2,1
    80004fa8:	fd3a91e3          	bne	s5,s3,80004f6a <piperead+0x70>
    80004fac:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004fae:	21c48513          	addi	a0,s1,540
    80004fb2:	ffffd097          	auipc	ra,0xffffd
    80004fb6:	274080e7          	jalr	628(ra) # 80002226 <wakeup>
  release(&pi->lock);
    80004fba:	8526                	mv	a0,s1
    80004fbc:	ffffc097          	auipc	ra,0xffffc
    80004fc0:	cce080e7          	jalr	-818(ra) # 80000c8a <release>
  return i;
}
    80004fc4:	854e                	mv	a0,s3
    80004fc6:	60a6                	ld	ra,72(sp)
    80004fc8:	6406                	ld	s0,64(sp)
    80004fca:	74e2                	ld	s1,56(sp)
    80004fcc:	7942                	ld	s2,48(sp)
    80004fce:	79a2                	ld	s3,40(sp)
    80004fd0:	7a02                	ld	s4,32(sp)
    80004fd2:	6ae2                	ld	s5,24(sp)
    80004fd4:	6b42                	ld	s6,16(sp)
    80004fd6:	6161                	addi	sp,sp,80
    80004fd8:	8082                	ret
      release(&pi->lock);
    80004fda:	8526                	mv	a0,s1
    80004fdc:	ffffc097          	auipc	ra,0xffffc
    80004fe0:	cae080e7          	jalr	-850(ra) # 80000c8a <release>
      return -1;
    80004fe4:	59fd                	li	s3,-1
    80004fe6:	bff9                	j	80004fc4 <piperead+0xca>

0000000080004fe8 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004fe8:	1141                	addi	sp,sp,-16
    80004fea:	e422                	sd	s0,8(sp)
    80004fec:	0800                	addi	s0,sp,16
    80004fee:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004ff0:	8905                	andi	a0,a0,1
    80004ff2:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004ff4:	8b89                	andi	a5,a5,2
    80004ff6:	c399                	beqz	a5,80004ffc <flags2perm+0x14>
      perm |= PTE_W;
    80004ff8:	00456513          	ori	a0,a0,4
    return perm;
}
    80004ffc:	6422                	ld	s0,8(sp)
    80004ffe:	0141                	addi	sp,sp,16
    80005000:	8082                	ret

0000000080005002 <exec>:

int
exec(char *path, char **argv)
{
    80005002:	de010113          	addi	sp,sp,-544
    80005006:	20113c23          	sd	ra,536(sp)
    8000500a:	20813823          	sd	s0,528(sp)
    8000500e:	20913423          	sd	s1,520(sp)
    80005012:	21213023          	sd	s2,512(sp)
    80005016:	ffce                	sd	s3,504(sp)
    80005018:	fbd2                	sd	s4,496(sp)
    8000501a:	f7d6                	sd	s5,488(sp)
    8000501c:	f3da                	sd	s6,480(sp)
    8000501e:	efde                	sd	s7,472(sp)
    80005020:	ebe2                	sd	s8,464(sp)
    80005022:	e7e6                	sd	s9,456(sp)
    80005024:	e3ea                	sd	s10,448(sp)
    80005026:	ff6e                	sd	s11,440(sp)
    80005028:	1400                	addi	s0,sp,544
    8000502a:	892a                	mv	s2,a0
    8000502c:	dea43423          	sd	a0,-536(s0)
    80005030:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005034:	ffffd097          	auipc	ra,0xffffd
    80005038:	978080e7          	jalr	-1672(ra) # 800019ac <myproc>
    8000503c:	84aa                	mv	s1,a0

  begin_op();
    8000503e:	fffff097          	auipc	ra,0xfffff
    80005042:	482080e7          	jalr	1154(ra) # 800044c0 <begin_op>

  if((ip = namei(path)) == 0){
    80005046:	854a                	mv	a0,s2
    80005048:	fffff097          	auipc	ra,0xfffff
    8000504c:	258080e7          	jalr	600(ra) # 800042a0 <namei>
    80005050:	c93d                	beqz	a0,800050c6 <exec+0xc4>
    80005052:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005054:	fffff097          	auipc	ra,0xfffff
    80005058:	aa0080e7          	jalr	-1376(ra) # 80003af4 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000505c:	04000713          	li	a4,64
    80005060:	4681                	li	a3,0
    80005062:	e5040613          	addi	a2,s0,-432
    80005066:	4581                	li	a1,0
    80005068:	8556                	mv	a0,s5
    8000506a:	fffff097          	auipc	ra,0xfffff
    8000506e:	d3e080e7          	jalr	-706(ra) # 80003da8 <readi>
    80005072:	04000793          	li	a5,64
    80005076:	00f51a63          	bne	a0,a5,8000508a <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    8000507a:	e5042703          	lw	a4,-432(s0)
    8000507e:	464c47b7          	lui	a5,0x464c4
    80005082:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005086:	04f70663          	beq	a4,a5,800050d2 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    8000508a:	8556                	mv	a0,s5
    8000508c:	fffff097          	auipc	ra,0xfffff
    80005090:	cca080e7          	jalr	-822(ra) # 80003d56 <iunlockput>
    end_op();
    80005094:	fffff097          	auipc	ra,0xfffff
    80005098:	4aa080e7          	jalr	1194(ra) # 8000453e <end_op>
  }
  return -1;
    8000509c:	557d                	li	a0,-1
}
    8000509e:	21813083          	ld	ra,536(sp)
    800050a2:	21013403          	ld	s0,528(sp)
    800050a6:	20813483          	ld	s1,520(sp)
    800050aa:	20013903          	ld	s2,512(sp)
    800050ae:	79fe                	ld	s3,504(sp)
    800050b0:	7a5e                	ld	s4,496(sp)
    800050b2:	7abe                	ld	s5,488(sp)
    800050b4:	7b1e                	ld	s6,480(sp)
    800050b6:	6bfe                	ld	s7,472(sp)
    800050b8:	6c5e                	ld	s8,464(sp)
    800050ba:	6cbe                	ld	s9,456(sp)
    800050bc:	6d1e                	ld	s10,448(sp)
    800050be:	7dfa                	ld	s11,440(sp)
    800050c0:	22010113          	addi	sp,sp,544
    800050c4:	8082                	ret
    end_op();
    800050c6:	fffff097          	auipc	ra,0xfffff
    800050ca:	478080e7          	jalr	1144(ra) # 8000453e <end_op>
    return -1;
    800050ce:	557d                	li	a0,-1
    800050d0:	b7f9                	j	8000509e <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    800050d2:	8526                	mv	a0,s1
    800050d4:	ffffd097          	auipc	ra,0xffffd
    800050d8:	99c080e7          	jalr	-1636(ra) # 80001a70 <proc_pagetable>
    800050dc:	8b2a                	mv	s6,a0
    800050de:	d555                	beqz	a0,8000508a <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050e0:	e7042783          	lw	a5,-400(s0)
    800050e4:	e8845703          	lhu	a4,-376(s0)
    800050e8:	c735                	beqz	a4,80005154 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800050ea:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050ec:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    800050f0:	6a05                	lui	s4,0x1
    800050f2:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    800050f6:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    800050fa:	6d85                	lui	s11,0x1
    800050fc:	7d7d                	lui	s10,0xfffff
    800050fe:	ac3d                	j	8000533c <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005100:	00003517          	auipc	a0,0x3
    80005104:	5f050513          	addi	a0,a0,1520 # 800086f0 <syscalls+0x298>
    80005108:	ffffb097          	auipc	ra,0xffffb
    8000510c:	438080e7          	jalr	1080(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005110:	874a                	mv	a4,s2
    80005112:	009c86bb          	addw	a3,s9,s1
    80005116:	4581                	li	a1,0
    80005118:	8556                	mv	a0,s5
    8000511a:	fffff097          	auipc	ra,0xfffff
    8000511e:	c8e080e7          	jalr	-882(ra) # 80003da8 <readi>
    80005122:	2501                	sext.w	a0,a0
    80005124:	1aa91963          	bne	s2,a0,800052d6 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005128:	009d84bb          	addw	s1,s11,s1
    8000512c:	013d09bb          	addw	s3,s10,s3
    80005130:	1f74f663          	bgeu	s1,s7,8000531c <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005134:	02049593          	slli	a1,s1,0x20
    80005138:	9181                	srli	a1,a1,0x20
    8000513a:	95e2                	add	a1,a1,s8
    8000513c:	855a                	mv	a0,s6
    8000513e:	ffffc097          	auipc	ra,0xffffc
    80005142:	f1e080e7          	jalr	-226(ra) # 8000105c <walkaddr>
    80005146:	862a                	mv	a2,a0
    if(pa == 0)
    80005148:	dd45                	beqz	a0,80005100 <exec+0xfe>
      n = PGSIZE;
    8000514a:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    8000514c:	fd49f2e3          	bgeu	s3,s4,80005110 <exec+0x10e>
      n = sz - i;
    80005150:	894e                	mv	s2,s3
    80005152:	bf7d                	j	80005110 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005154:	4901                	li	s2,0
  iunlockput(ip);
    80005156:	8556                	mv	a0,s5
    80005158:	fffff097          	auipc	ra,0xfffff
    8000515c:	bfe080e7          	jalr	-1026(ra) # 80003d56 <iunlockput>
  end_op();
    80005160:	fffff097          	auipc	ra,0xfffff
    80005164:	3de080e7          	jalr	990(ra) # 8000453e <end_op>
  p = myproc();
    80005168:	ffffd097          	auipc	ra,0xffffd
    8000516c:	844080e7          	jalr	-1980(ra) # 800019ac <myproc>
    80005170:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005172:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005176:	6785                	lui	a5,0x1
    80005178:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000517a:	97ca                	add	a5,a5,s2
    8000517c:	777d                	lui	a4,0xfffff
    8000517e:	8ff9                	and	a5,a5,a4
    80005180:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005184:	4691                	li	a3,4
    80005186:	6609                	lui	a2,0x2
    80005188:	963e                	add	a2,a2,a5
    8000518a:	85be                	mv	a1,a5
    8000518c:	855a                	mv	a0,s6
    8000518e:	ffffc097          	auipc	ra,0xffffc
    80005192:	282080e7          	jalr	642(ra) # 80001410 <uvmalloc>
    80005196:	8c2a                	mv	s8,a0
  ip = 0;
    80005198:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    8000519a:	12050e63          	beqz	a0,800052d6 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    8000519e:	75f9                	lui	a1,0xffffe
    800051a0:	95aa                	add	a1,a1,a0
    800051a2:	855a                	mv	a0,s6
    800051a4:	ffffc097          	auipc	ra,0xffffc
    800051a8:	496080e7          	jalr	1174(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    800051ac:	7afd                	lui	s5,0xfffff
    800051ae:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    800051b0:	df043783          	ld	a5,-528(s0)
    800051b4:	6388                	ld	a0,0(a5)
    800051b6:	c925                	beqz	a0,80005226 <exec+0x224>
    800051b8:	e9040993          	addi	s3,s0,-368
    800051bc:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800051c0:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    800051c2:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    800051c4:	ffffc097          	auipc	ra,0xffffc
    800051c8:	c8a080e7          	jalr	-886(ra) # 80000e4e <strlen>
    800051cc:	0015079b          	addiw	a5,a0,1
    800051d0:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    800051d4:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    800051d8:	13596663          	bltu	s2,s5,80005304 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    800051dc:	df043d83          	ld	s11,-528(s0)
    800051e0:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    800051e4:	8552                	mv	a0,s4
    800051e6:	ffffc097          	auipc	ra,0xffffc
    800051ea:	c68080e7          	jalr	-920(ra) # 80000e4e <strlen>
    800051ee:	0015069b          	addiw	a3,a0,1
    800051f2:	8652                	mv	a2,s4
    800051f4:	85ca                	mv	a1,s2
    800051f6:	855a                	mv	a0,s6
    800051f8:	ffffc097          	auipc	ra,0xffffc
    800051fc:	474080e7          	jalr	1140(ra) # 8000166c <copyout>
    80005200:	10054663          	bltz	a0,8000530c <exec+0x30a>
    ustack[argc] = sp;
    80005204:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005208:	0485                	addi	s1,s1,1
    8000520a:	008d8793          	addi	a5,s11,8
    8000520e:	def43823          	sd	a5,-528(s0)
    80005212:	008db503          	ld	a0,8(s11)
    80005216:	c911                	beqz	a0,8000522a <exec+0x228>
    if(argc >= MAXARG)
    80005218:	09a1                	addi	s3,s3,8
    8000521a:	fb3c95e3          	bne	s9,s3,800051c4 <exec+0x1c2>
  sz = sz1;
    8000521e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005222:	4a81                	li	s5,0
    80005224:	a84d                	j	800052d6 <exec+0x2d4>
  sp = sz;
    80005226:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005228:	4481                	li	s1,0
  ustack[argc] = 0;
    8000522a:	00349793          	slli	a5,s1,0x3
    8000522e:	f9078793          	addi	a5,a5,-112
    80005232:	97a2                	add	a5,a5,s0
    80005234:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005238:	00148693          	addi	a3,s1,1
    8000523c:	068e                	slli	a3,a3,0x3
    8000523e:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005242:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005246:	01597663          	bgeu	s2,s5,80005252 <exec+0x250>
  sz = sz1;
    8000524a:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000524e:	4a81                	li	s5,0
    80005250:	a059                	j	800052d6 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005252:	e9040613          	addi	a2,s0,-368
    80005256:	85ca                	mv	a1,s2
    80005258:	855a                	mv	a0,s6
    8000525a:	ffffc097          	auipc	ra,0xffffc
    8000525e:	412080e7          	jalr	1042(ra) # 8000166c <copyout>
    80005262:	0a054963          	bltz	a0,80005314 <exec+0x312>
  p->trapframe->a1 = sp;
    80005266:	058bb783          	ld	a5,88(s7)
    8000526a:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000526e:	de843783          	ld	a5,-536(s0)
    80005272:	0007c703          	lbu	a4,0(a5)
    80005276:	cf11                	beqz	a4,80005292 <exec+0x290>
    80005278:	0785                	addi	a5,a5,1
    if(*s == '/')
    8000527a:	02f00693          	li	a3,47
    8000527e:	a039                	j	8000528c <exec+0x28a>
      last = s+1;
    80005280:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005284:	0785                	addi	a5,a5,1
    80005286:	fff7c703          	lbu	a4,-1(a5)
    8000528a:	c701                	beqz	a4,80005292 <exec+0x290>
    if(*s == '/')
    8000528c:	fed71ce3          	bne	a4,a3,80005284 <exec+0x282>
    80005290:	bfc5                	j	80005280 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005292:	4641                	li	a2,16
    80005294:	de843583          	ld	a1,-536(s0)
    80005298:	158b8513          	addi	a0,s7,344
    8000529c:	ffffc097          	auipc	ra,0xffffc
    800052a0:	b80080e7          	jalr	-1152(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    800052a4:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    800052a8:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    800052ac:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    800052b0:	058bb783          	ld	a5,88(s7)
    800052b4:	e6843703          	ld	a4,-408(s0)
    800052b8:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    800052ba:	058bb783          	ld	a5,88(s7)
    800052be:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    800052c2:	85ea                	mv	a1,s10
    800052c4:	ffffd097          	auipc	ra,0xffffd
    800052c8:	848080e7          	jalr	-1976(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800052cc:	0004851b          	sext.w	a0,s1
    800052d0:	b3f9                	j	8000509e <exec+0x9c>
    800052d2:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800052d6:	df843583          	ld	a1,-520(s0)
    800052da:	855a                	mv	a0,s6
    800052dc:	ffffd097          	auipc	ra,0xffffd
    800052e0:	830080e7          	jalr	-2000(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800052e4:	da0a93e3          	bnez	s5,8000508a <exec+0x88>
  return -1;
    800052e8:	557d                	li	a0,-1
    800052ea:	bb55                	j	8000509e <exec+0x9c>
    800052ec:	df243c23          	sd	s2,-520(s0)
    800052f0:	b7dd                	j	800052d6 <exec+0x2d4>
    800052f2:	df243c23          	sd	s2,-520(s0)
    800052f6:	b7c5                	j	800052d6 <exec+0x2d4>
    800052f8:	df243c23          	sd	s2,-520(s0)
    800052fc:	bfe9                	j	800052d6 <exec+0x2d4>
    800052fe:	df243c23          	sd	s2,-520(s0)
    80005302:	bfd1                	j	800052d6 <exec+0x2d4>
  sz = sz1;
    80005304:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005308:	4a81                	li	s5,0
    8000530a:	b7f1                	j	800052d6 <exec+0x2d4>
  sz = sz1;
    8000530c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005310:	4a81                	li	s5,0
    80005312:	b7d1                	j	800052d6 <exec+0x2d4>
  sz = sz1;
    80005314:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005318:	4a81                	li	s5,0
    8000531a:	bf75                	j	800052d6 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    8000531c:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005320:	e0843783          	ld	a5,-504(s0)
    80005324:	0017869b          	addiw	a3,a5,1
    80005328:	e0d43423          	sd	a3,-504(s0)
    8000532c:	e0043783          	ld	a5,-512(s0)
    80005330:	0387879b          	addiw	a5,a5,56
    80005334:	e8845703          	lhu	a4,-376(s0)
    80005338:	e0e6dfe3          	bge	a3,a4,80005156 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000533c:	2781                	sext.w	a5,a5
    8000533e:	e0f43023          	sd	a5,-512(s0)
    80005342:	03800713          	li	a4,56
    80005346:	86be                	mv	a3,a5
    80005348:	e1840613          	addi	a2,s0,-488
    8000534c:	4581                	li	a1,0
    8000534e:	8556                	mv	a0,s5
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	a58080e7          	jalr	-1448(ra) # 80003da8 <readi>
    80005358:	03800793          	li	a5,56
    8000535c:	f6f51be3          	bne	a0,a5,800052d2 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005360:	e1842783          	lw	a5,-488(s0)
    80005364:	4705                	li	a4,1
    80005366:	fae79de3          	bne	a5,a4,80005320 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    8000536a:	e4043483          	ld	s1,-448(s0)
    8000536e:	e3843783          	ld	a5,-456(s0)
    80005372:	f6f4ede3          	bltu	s1,a5,800052ec <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005376:	e2843783          	ld	a5,-472(s0)
    8000537a:	94be                	add	s1,s1,a5
    8000537c:	f6f4ebe3          	bltu	s1,a5,800052f2 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005380:	de043703          	ld	a4,-544(s0)
    80005384:	8ff9                	and	a5,a5,a4
    80005386:	fbad                	bnez	a5,800052f8 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005388:	e1c42503          	lw	a0,-484(s0)
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	c5c080e7          	jalr	-932(ra) # 80004fe8 <flags2perm>
    80005394:	86aa                	mv	a3,a0
    80005396:	8626                	mv	a2,s1
    80005398:	85ca                	mv	a1,s2
    8000539a:	855a                	mv	a0,s6
    8000539c:	ffffc097          	auipc	ra,0xffffc
    800053a0:	074080e7          	jalr	116(ra) # 80001410 <uvmalloc>
    800053a4:	dea43c23          	sd	a0,-520(s0)
    800053a8:	d939                	beqz	a0,800052fe <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053aa:	e2843c03          	ld	s8,-472(s0)
    800053ae:	e2042c83          	lw	s9,-480(s0)
    800053b2:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    800053b6:	f60b83e3          	beqz	s7,8000531c <exec+0x31a>
    800053ba:	89de                	mv	s3,s7
    800053bc:	4481                	li	s1,0
    800053be:	bb9d                	j	80005134 <exec+0x132>

00000000800053c0 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    800053c0:	7179                	addi	sp,sp,-48
    800053c2:	f406                	sd	ra,40(sp)
    800053c4:	f022                	sd	s0,32(sp)
    800053c6:	ec26                	sd	s1,24(sp)
    800053c8:	e84a                	sd	s2,16(sp)
    800053ca:	1800                	addi	s0,sp,48
    800053cc:	892e                	mv	s2,a1
    800053ce:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    800053d0:	fdc40593          	addi	a1,s0,-36
    800053d4:	ffffe097          	auipc	ra,0xffffe
    800053d8:	a54080e7          	jalr	-1452(ra) # 80002e28 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    800053dc:	fdc42703          	lw	a4,-36(s0)
    800053e0:	47bd                	li	a5,15
    800053e2:	02e7eb63          	bltu	a5,a4,80005418 <argfd+0x58>
    800053e6:	ffffc097          	auipc	ra,0xffffc
    800053ea:	5c6080e7          	jalr	1478(ra) # 800019ac <myproc>
    800053ee:	fdc42703          	lw	a4,-36(s0)
    800053f2:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdc89a>
    800053f6:	078e                	slli	a5,a5,0x3
    800053f8:	953e                	add	a0,a0,a5
    800053fa:	611c                	ld	a5,0(a0)
    800053fc:	c385                	beqz	a5,8000541c <argfd+0x5c>
    return -1;
  if(pfd)
    800053fe:	00090463          	beqz	s2,80005406 <argfd+0x46>
    *pfd = fd;
    80005402:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005406:	4501                	li	a0,0
  if(pf)
    80005408:	c091                	beqz	s1,8000540c <argfd+0x4c>
    *pf = f;
    8000540a:	e09c                	sd	a5,0(s1)
}
    8000540c:	70a2                	ld	ra,40(sp)
    8000540e:	7402                	ld	s0,32(sp)
    80005410:	64e2                	ld	s1,24(sp)
    80005412:	6942                	ld	s2,16(sp)
    80005414:	6145                	addi	sp,sp,48
    80005416:	8082                	ret
    return -1;
    80005418:	557d                	li	a0,-1
    8000541a:	bfcd                	j	8000540c <argfd+0x4c>
    8000541c:	557d                	li	a0,-1
    8000541e:	b7fd                	j	8000540c <argfd+0x4c>

0000000080005420 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005420:	1101                	addi	sp,sp,-32
    80005422:	ec06                	sd	ra,24(sp)
    80005424:	e822                	sd	s0,16(sp)
    80005426:	e426                	sd	s1,8(sp)
    80005428:	1000                	addi	s0,sp,32
    8000542a:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    8000542c:	ffffc097          	auipc	ra,0xffffc
    80005430:	580080e7          	jalr	1408(ra) # 800019ac <myproc>
    80005434:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005436:	0d050793          	addi	a5,a0,208
    8000543a:	4501                	li	a0,0
    8000543c:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    8000543e:	6398                	ld	a4,0(a5)
    80005440:	cb19                	beqz	a4,80005456 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005442:	2505                	addiw	a0,a0,1
    80005444:	07a1                	addi	a5,a5,8
    80005446:	fed51ce3          	bne	a0,a3,8000543e <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000544a:	557d                	li	a0,-1
}
    8000544c:	60e2                	ld	ra,24(sp)
    8000544e:	6442                	ld	s0,16(sp)
    80005450:	64a2                	ld	s1,8(sp)
    80005452:	6105                	addi	sp,sp,32
    80005454:	8082                	ret
      p->ofile[fd] = f;
    80005456:	01a50793          	addi	a5,a0,26
    8000545a:	078e                	slli	a5,a5,0x3
    8000545c:	963e                	add	a2,a2,a5
    8000545e:	e204                	sd	s1,0(a2)
      return fd;
    80005460:	b7f5                	j	8000544c <fdalloc+0x2c>

0000000080005462 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005462:	715d                	addi	sp,sp,-80
    80005464:	e486                	sd	ra,72(sp)
    80005466:	e0a2                	sd	s0,64(sp)
    80005468:	fc26                	sd	s1,56(sp)
    8000546a:	f84a                	sd	s2,48(sp)
    8000546c:	f44e                	sd	s3,40(sp)
    8000546e:	f052                	sd	s4,32(sp)
    80005470:	ec56                	sd	s5,24(sp)
    80005472:	e85a                	sd	s6,16(sp)
    80005474:	0880                	addi	s0,sp,80
    80005476:	8b2e                	mv	s6,a1
    80005478:	89b2                	mv	s3,a2
    8000547a:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    8000547c:	fb040593          	addi	a1,s0,-80
    80005480:	fffff097          	auipc	ra,0xfffff
    80005484:	e3e080e7          	jalr	-450(ra) # 800042be <nameiparent>
    80005488:	84aa                	mv	s1,a0
    8000548a:	14050f63          	beqz	a0,800055e8 <create+0x186>
    return 0;

  ilock(dp);
    8000548e:	ffffe097          	auipc	ra,0xffffe
    80005492:	666080e7          	jalr	1638(ra) # 80003af4 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005496:	4601                	li	a2,0
    80005498:	fb040593          	addi	a1,s0,-80
    8000549c:	8526                	mv	a0,s1
    8000549e:	fffff097          	auipc	ra,0xfffff
    800054a2:	b3a080e7          	jalr	-1222(ra) # 80003fd8 <dirlookup>
    800054a6:	8aaa                	mv	s5,a0
    800054a8:	c931                	beqz	a0,800054fc <create+0x9a>
    iunlockput(dp);
    800054aa:	8526                	mv	a0,s1
    800054ac:	fffff097          	auipc	ra,0xfffff
    800054b0:	8aa080e7          	jalr	-1878(ra) # 80003d56 <iunlockput>
    ilock(ip);
    800054b4:	8556                	mv	a0,s5
    800054b6:	ffffe097          	auipc	ra,0xffffe
    800054ba:	63e080e7          	jalr	1598(ra) # 80003af4 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    800054be:	000b059b          	sext.w	a1,s6
    800054c2:	4789                	li	a5,2
    800054c4:	02f59563          	bne	a1,a5,800054ee <create+0x8c>
    800054c8:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdc8c4>
    800054cc:	37f9                	addiw	a5,a5,-2
    800054ce:	17c2                	slli	a5,a5,0x30
    800054d0:	93c1                	srli	a5,a5,0x30
    800054d2:	4705                	li	a4,1
    800054d4:	00f76d63          	bltu	a4,a5,800054ee <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    800054d8:	8556                	mv	a0,s5
    800054da:	60a6                	ld	ra,72(sp)
    800054dc:	6406                	ld	s0,64(sp)
    800054de:	74e2                	ld	s1,56(sp)
    800054e0:	7942                	ld	s2,48(sp)
    800054e2:	79a2                	ld	s3,40(sp)
    800054e4:	7a02                	ld	s4,32(sp)
    800054e6:	6ae2                	ld	s5,24(sp)
    800054e8:	6b42                	ld	s6,16(sp)
    800054ea:	6161                	addi	sp,sp,80
    800054ec:	8082                	ret
    iunlockput(ip);
    800054ee:	8556                	mv	a0,s5
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	866080e7          	jalr	-1946(ra) # 80003d56 <iunlockput>
    return 0;
    800054f8:	4a81                	li	s5,0
    800054fa:	bff9                	j	800054d8 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800054fc:	85da                	mv	a1,s6
    800054fe:	4088                	lw	a0,0(s1)
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	456080e7          	jalr	1110(ra) # 80003956 <ialloc>
    80005508:	8a2a                	mv	s4,a0
    8000550a:	c539                	beqz	a0,80005558 <create+0xf6>
  ilock(ip);
    8000550c:	ffffe097          	auipc	ra,0xffffe
    80005510:	5e8080e7          	jalr	1512(ra) # 80003af4 <ilock>
  ip->major = major;
    80005514:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005518:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000551c:	4905                	li	s2,1
    8000551e:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80005522:	8552                	mv	a0,s4
    80005524:	ffffe097          	auipc	ra,0xffffe
    80005528:	504080e7          	jalr	1284(ra) # 80003a28 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000552c:	000b059b          	sext.w	a1,s6
    80005530:	03258b63          	beq	a1,s2,80005566 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80005534:	004a2603          	lw	a2,4(s4)
    80005538:	fb040593          	addi	a1,s0,-80
    8000553c:	8526                	mv	a0,s1
    8000553e:	fffff097          	auipc	ra,0xfffff
    80005542:	cb0080e7          	jalr	-848(ra) # 800041ee <dirlink>
    80005546:	06054f63          	bltz	a0,800055c4 <create+0x162>
  iunlockput(dp);
    8000554a:	8526                	mv	a0,s1
    8000554c:	fffff097          	auipc	ra,0xfffff
    80005550:	80a080e7          	jalr	-2038(ra) # 80003d56 <iunlockput>
  return ip;
    80005554:	8ad2                	mv	s5,s4
    80005556:	b749                	j	800054d8 <create+0x76>
    iunlockput(dp);
    80005558:	8526                	mv	a0,s1
    8000555a:	ffffe097          	auipc	ra,0xffffe
    8000555e:	7fc080e7          	jalr	2044(ra) # 80003d56 <iunlockput>
    return 0;
    80005562:	8ad2                	mv	s5,s4
    80005564:	bf95                	j	800054d8 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005566:	004a2603          	lw	a2,4(s4)
    8000556a:	00003597          	auipc	a1,0x3
    8000556e:	1a658593          	addi	a1,a1,422 # 80008710 <syscalls+0x2b8>
    80005572:	8552                	mv	a0,s4
    80005574:	fffff097          	auipc	ra,0xfffff
    80005578:	c7a080e7          	jalr	-902(ra) # 800041ee <dirlink>
    8000557c:	04054463          	bltz	a0,800055c4 <create+0x162>
    80005580:	40d0                	lw	a2,4(s1)
    80005582:	00003597          	auipc	a1,0x3
    80005586:	19658593          	addi	a1,a1,406 # 80008718 <syscalls+0x2c0>
    8000558a:	8552                	mv	a0,s4
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	c62080e7          	jalr	-926(ra) # 800041ee <dirlink>
    80005594:	02054863          	bltz	a0,800055c4 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005598:	004a2603          	lw	a2,4(s4)
    8000559c:	fb040593          	addi	a1,s0,-80
    800055a0:	8526                	mv	a0,s1
    800055a2:	fffff097          	auipc	ra,0xfffff
    800055a6:	c4c080e7          	jalr	-948(ra) # 800041ee <dirlink>
    800055aa:	00054d63          	bltz	a0,800055c4 <create+0x162>
    dp->nlink++;  // for ".."
    800055ae:	04a4d783          	lhu	a5,74(s1)
    800055b2:	2785                	addiw	a5,a5,1
    800055b4:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800055b8:	8526                	mv	a0,s1
    800055ba:	ffffe097          	auipc	ra,0xffffe
    800055be:	46e080e7          	jalr	1134(ra) # 80003a28 <iupdate>
    800055c2:	b761                	j	8000554a <create+0xe8>
  ip->nlink = 0;
    800055c4:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    800055c8:	8552                	mv	a0,s4
    800055ca:	ffffe097          	auipc	ra,0xffffe
    800055ce:	45e080e7          	jalr	1118(ra) # 80003a28 <iupdate>
  iunlockput(ip);
    800055d2:	8552                	mv	a0,s4
    800055d4:	ffffe097          	auipc	ra,0xffffe
    800055d8:	782080e7          	jalr	1922(ra) # 80003d56 <iunlockput>
  iunlockput(dp);
    800055dc:	8526                	mv	a0,s1
    800055de:	ffffe097          	auipc	ra,0xffffe
    800055e2:	778080e7          	jalr	1912(ra) # 80003d56 <iunlockput>
  return 0;
    800055e6:	bdcd                	j	800054d8 <create+0x76>
    return 0;
    800055e8:	8aaa                	mv	s5,a0
    800055ea:	b5fd                	j	800054d8 <create+0x76>

00000000800055ec <sys_dup>:
{
    800055ec:	7179                	addi	sp,sp,-48
    800055ee:	f406                	sd	ra,40(sp)
    800055f0:	f022                	sd	s0,32(sp)
    800055f2:	ec26                	sd	s1,24(sp)
    800055f4:	e84a                	sd	s2,16(sp)
    800055f6:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800055f8:	fd840613          	addi	a2,s0,-40
    800055fc:	4581                	li	a1,0
    800055fe:	4501                	li	a0,0
    80005600:	00000097          	auipc	ra,0x0
    80005604:	dc0080e7          	jalr	-576(ra) # 800053c0 <argfd>
    return -1;
    80005608:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000560a:	02054363          	bltz	a0,80005630 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000560e:	fd843903          	ld	s2,-40(s0)
    80005612:	854a                	mv	a0,s2
    80005614:	00000097          	auipc	ra,0x0
    80005618:	e0c080e7          	jalr	-500(ra) # 80005420 <fdalloc>
    8000561c:	84aa                	mv	s1,a0
    return -1;
    8000561e:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005620:	00054863          	bltz	a0,80005630 <sys_dup+0x44>
  filedup(f);
    80005624:	854a                	mv	a0,s2
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	310080e7          	jalr	784(ra) # 80004936 <filedup>
  return fd;
    8000562e:	87a6                	mv	a5,s1
}
    80005630:	853e                	mv	a0,a5
    80005632:	70a2                	ld	ra,40(sp)
    80005634:	7402                	ld	s0,32(sp)
    80005636:	64e2                	ld	s1,24(sp)
    80005638:	6942                	ld	s2,16(sp)
    8000563a:	6145                	addi	sp,sp,48
    8000563c:	8082                	ret

000000008000563e <sys_getreadcount>:
{
    8000563e:	1141                	addi	sp,sp,-16
    80005640:	e422                	sd	s0,8(sp)
    80005642:	0800                	addi	s0,sp,16
}
    80005644:	00003517          	auipc	a0,0x3
    80005648:	2c052503          	lw	a0,704(a0) # 80008904 <readCount>
    8000564c:	6422                	ld	s0,8(sp)
    8000564e:	0141                	addi	sp,sp,16
    80005650:	8082                	ret

0000000080005652 <sys_read>:
{
    80005652:	7179                	addi	sp,sp,-48
    80005654:	f406                	sd	ra,40(sp)
    80005656:	f022                	sd	s0,32(sp)
    80005658:	1800                	addi	s0,sp,48
  readCount++;
    8000565a:	00003717          	auipc	a4,0x3
    8000565e:	2aa70713          	addi	a4,a4,682 # 80008904 <readCount>
    80005662:	431c                	lw	a5,0(a4)
    80005664:	2785                	addiw	a5,a5,1
    80005666:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80005668:	fd840593          	addi	a1,s0,-40
    8000566c:	4505                	li	a0,1
    8000566e:	ffffd097          	auipc	ra,0xffffd
    80005672:	7da080e7          	jalr	2010(ra) # 80002e48 <argaddr>
  argint(2, &n);
    80005676:	fe440593          	addi	a1,s0,-28
    8000567a:	4509                	li	a0,2
    8000567c:	ffffd097          	auipc	ra,0xffffd
    80005680:	7ac080e7          	jalr	1964(ra) # 80002e28 <argint>
  if(argfd(0, 0, &f) < 0)
    80005684:	fe840613          	addi	a2,s0,-24
    80005688:	4581                	li	a1,0
    8000568a:	4501                	li	a0,0
    8000568c:	00000097          	auipc	ra,0x0
    80005690:	d34080e7          	jalr	-716(ra) # 800053c0 <argfd>
    80005694:	87aa                	mv	a5,a0
    return -1;
    80005696:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005698:	0007cc63          	bltz	a5,800056b0 <sys_read+0x5e>
  return fileread(f, p, n);
    8000569c:	fe442603          	lw	a2,-28(s0)
    800056a0:	fd843583          	ld	a1,-40(s0)
    800056a4:	fe843503          	ld	a0,-24(s0)
    800056a8:	fffff097          	auipc	ra,0xfffff
    800056ac:	41a080e7          	jalr	1050(ra) # 80004ac2 <fileread>
}
    800056b0:	70a2                	ld	ra,40(sp)
    800056b2:	7402                	ld	s0,32(sp)
    800056b4:	6145                	addi	sp,sp,48
    800056b6:	8082                	ret

00000000800056b8 <sys_write>:
{
    800056b8:	7179                	addi	sp,sp,-48
    800056ba:	f406                	sd	ra,40(sp)
    800056bc:	f022                	sd	s0,32(sp)
    800056be:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800056c0:	fd840593          	addi	a1,s0,-40
    800056c4:	4505                	li	a0,1
    800056c6:	ffffd097          	auipc	ra,0xffffd
    800056ca:	782080e7          	jalr	1922(ra) # 80002e48 <argaddr>
  argint(2, &n);
    800056ce:	fe440593          	addi	a1,s0,-28
    800056d2:	4509                	li	a0,2
    800056d4:	ffffd097          	auipc	ra,0xffffd
    800056d8:	754080e7          	jalr	1876(ra) # 80002e28 <argint>
  if(argfd(0, 0, &f) < 0)
    800056dc:	fe840613          	addi	a2,s0,-24
    800056e0:	4581                	li	a1,0
    800056e2:	4501                	li	a0,0
    800056e4:	00000097          	auipc	ra,0x0
    800056e8:	cdc080e7          	jalr	-804(ra) # 800053c0 <argfd>
    800056ec:	87aa                	mv	a5,a0
    return -1;
    800056ee:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800056f0:	0007cc63          	bltz	a5,80005708 <sys_write+0x50>
  return filewrite(f, p, n);
    800056f4:	fe442603          	lw	a2,-28(s0)
    800056f8:	fd843583          	ld	a1,-40(s0)
    800056fc:	fe843503          	ld	a0,-24(s0)
    80005700:	fffff097          	auipc	ra,0xfffff
    80005704:	484080e7          	jalr	1156(ra) # 80004b84 <filewrite>
}
    80005708:	70a2                	ld	ra,40(sp)
    8000570a:	7402                	ld	s0,32(sp)
    8000570c:	6145                	addi	sp,sp,48
    8000570e:	8082                	ret

0000000080005710 <sys_close>:
{
    80005710:	1101                	addi	sp,sp,-32
    80005712:	ec06                	sd	ra,24(sp)
    80005714:	e822                	sd	s0,16(sp)
    80005716:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005718:	fe040613          	addi	a2,s0,-32
    8000571c:	fec40593          	addi	a1,s0,-20
    80005720:	4501                	li	a0,0
    80005722:	00000097          	auipc	ra,0x0
    80005726:	c9e080e7          	jalr	-866(ra) # 800053c0 <argfd>
    return -1;
    8000572a:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000572c:	02054463          	bltz	a0,80005754 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005730:	ffffc097          	auipc	ra,0xffffc
    80005734:	27c080e7          	jalr	636(ra) # 800019ac <myproc>
    80005738:	fec42783          	lw	a5,-20(s0)
    8000573c:	07e9                	addi	a5,a5,26
    8000573e:	078e                	slli	a5,a5,0x3
    80005740:	953e                	add	a0,a0,a5
    80005742:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80005746:	fe043503          	ld	a0,-32(s0)
    8000574a:	fffff097          	auipc	ra,0xfffff
    8000574e:	23e080e7          	jalr	574(ra) # 80004988 <fileclose>
  return 0;
    80005752:	4781                	li	a5,0
}
    80005754:	853e                	mv	a0,a5
    80005756:	60e2                	ld	ra,24(sp)
    80005758:	6442                	ld	s0,16(sp)
    8000575a:	6105                	addi	sp,sp,32
    8000575c:	8082                	ret

000000008000575e <sys_fstat>:
{
    8000575e:	1101                	addi	sp,sp,-32
    80005760:	ec06                	sd	ra,24(sp)
    80005762:	e822                	sd	s0,16(sp)
    80005764:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005766:	fe040593          	addi	a1,s0,-32
    8000576a:	4505                	li	a0,1
    8000576c:	ffffd097          	auipc	ra,0xffffd
    80005770:	6dc080e7          	jalr	1756(ra) # 80002e48 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005774:	fe840613          	addi	a2,s0,-24
    80005778:	4581                	li	a1,0
    8000577a:	4501                	li	a0,0
    8000577c:	00000097          	auipc	ra,0x0
    80005780:	c44080e7          	jalr	-956(ra) # 800053c0 <argfd>
    80005784:	87aa                	mv	a5,a0
    return -1;
    80005786:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005788:	0007ca63          	bltz	a5,8000579c <sys_fstat+0x3e>
  return filestat(f, st);
    8000578c:	fe043583          	ld	a1,-32(s0)
    80005790:	fe843503          	ld	a0,-24(s0)
    80005794:	fffff097          	auipc	ra,0xfffff
    80005798:	2bc080e7          	jalr	700(ra) # 80004a50 <filestat>
}
    8000579c:	60e2                	ld	ra,24(sp)
    8000579e:	6442                	ld	s0,16(sp)
    800057a0:	6105                	addi	sp,sp,32
    800057a2:	8082                	ret

00000000800057a4 <sys_link>:
{
    800057a4:	7169                	addi	sp,sp,-304
    800057a6:	f606                	sd	ra,296(sp)
    800057a8:	f222                	sd	s0,288(sp)
    800057aa:	ee26                	sd	s1,280(sp)
    800057ac:	ea4a                	sd	s2,272(sp)
    800057ae:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057b0:	08000613          	li	a2,128
    800057b4:	ed040593          	addi	a1,s0,-304
    800057b8:	4501                	li	a0,0
    800057ba:	ffffd097          	auipc	ra,0xffffd
    800057be:	6ae080e7          	jalr	1710(ra) # 80002e68 <argstr>
    return -1;
    800057c2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057c4:	10054e63          	bltz	a0,800058e0 <sys_link+0x13c>
    800057c8:	08000613          	li	a2,128
    800057cc:	f5040593          	addi	a1,s0,-176
    800057d0:	4505                	li	a0,1
    800057d2:	ffffd097          	auipc	ra,0xffffd
    800057d6:	696080e7          	jalr	1686(ra) # 80002e68 <argstr>
    return -1;
    800057da:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057dc:	10054263          	bltz	a0,800058e0 <sys_link+0x13c>
  begin_op();
    800057e0:	fffff097          	auipc	ra,0xfffff
    800057e4:	ce0080e7          	jalr	-800(ra) # 800044c0 <begin_op>
  if((ip = namei(old)) == 0){
    800057e8:	ed040513          	addi	a0,s0,-304
    800057ec:	fffff097          	auipc	ra,0xfffff
    800057f0:	ab4080e7          	jalr	-1356(ra) # 800042a0 <namei>
    800057f4:	84aa                	mv	s1,a0
    800057f6:	c551                	beqz	a0,80005882 <sys_link+0xde>
  ilock(ip);
    800057f8:	ffffe097          	auipc	ra,0xffffe
    800057fc:	2fc080e7          	jalr	764(ra) # 80003af4 <ilock>
  if(ip->type == T_DIR){
    80005800:	04449703          	lh	a4,68(s1)
    80005804:	4785                	li	a5,1
    80005806:	08f70463          	beq	a4,a5,8000588e <sys_link+0xea>
  ip->nlink++;
    8000580a:	04a4d783          	lhu	a5,74(s1)
    8000580e:	2785                	addiw	a5,a5,1
    80005810:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005814:	8526                	mv	a0,s1
    80005816:	ffffe097          	auipc	ra,0xffffe
    8000581a:	212080e7          	jalr	530(ra) # 80003a28 <iupdate>
  iunlock(ip);
    8000581e:	8526                	mv	a0,s1
    80005820:	ffffe097          	auipc	ra,0xffffe
    80005824:	396080e7          	jalr	918(ra) # 80003bb6 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005828:	fd040593          	addi	a1,s0,-48
    8000582c:	f5040513          	addi	a0,s0,-176
    80005830:	fffff097          	auipc	ra,0xfffff
    80005834:	a8e080e7          	jalr	-1394(ra) # 800042be <nameiparent>
    80005838:	892a                	mv	s2,a0
    8000583a:	c935                	beqz	a0,800058ae <sys_link+0x10a>
  ilock(dp);
    8000583c:	ffffe097          	auipc	ra,0xffffe
    80005840:	2b8080e7          	jalr	696(ra) # 80003af4 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005844:	00092703          	lw	a4,0(s2)
    80005848:	409c                	lw	a5,0(s1)
    8000584a:	04f71d63          	bne	a4,a5,800058a4 <sys_link+0x100>
    8000584e:	40d0                	lw	a2,4(s1)
    80005850:	fd040593          	addi	a1,s0,-48
    80005854:	854a                	mv	a0,s2
    80005856:	fffff097          	auipc	ra,0xfffff
    8000585a:	998080e7          	jalr	-1640(ra) # 800041ee <dirlink>
    8000585e:	04054363          	bltz	a0,800058a4 <sys_link+0x100>
  iunlockput(dp);
    80005862:	854a                	mv	a0,s2
    80005864:	ffffe097          	auipc	ra,0xffffe
    80005868:	4f2080e7          	jalr	1266(ra) # 80003d56 <iunlockput>
  iput(ip);
    8000586c:	8526                	mv	a0,s1
    8000586e:	ffffe097          	auipc	ra,0xffffe
    80005872:	440080e7          	jalr	1088(ra) # 80003cae <iput>
  end_op();
    80005876:	fffff097          	auipc	ra,0xfffff
    8000587a:	cc8080e7          	jalr	-824(ra) # 8000453e <end_op>
  return 0;
    8000587e:	4781                	li	a5,0
    80005880:	a085                	j	800058e0 <sys_link+0x13c>
    end_op();
    80005882:	fffff097          	auipc	ra,0xfffff
    80005886:	cbc080e7          	jalr	-836(ra) # 8000453e <end_op>
    return -1;
    8000588a:	57fd                	li	a5,-1
    8000588c:	a891                	j	800058e0 <sys_link+0x13c>
    iunlockput(ip);
    8000588e:	8526                	mv	a0,s1
    80005890:	ffffe097          	auipc	ra,0xffffe
    80005894:	4c6080e7          	jalr	1222(ra) # 80003d56 <iunlockput>
    end_op();
    80005898:	fffff097          	auipc	ra,0xfffff
    8000589c:	ca6080e7          	jalr	-858(ra) # 8000453e <end_op>
    return -1;
    800058a0:	57fd                	li	a5,-1
    800058a2:	a83d                	j	800058e0 <sys_link+0x13c>
    iunlockput(dp);
    800058a4:	854a                	mv	a0,s2
    800058a6:	ffffe097          	auipc	ra,0xffffe
    800058aa:	4b0080e7          	jalr	1200(ra) # 80003d56 <iunlockput>
  ilock(ip);
    800058ae:	8526                	mv	a0,s1
    800058b0:	ffffe097          	auipc	ra,0xffffe
    800058b4:	244080e7          	jalr	580(ra) # 80003af4 <ilock>
  ip->nlink--;
    800058b8:	04a4d783          	lhu	a5,74(s1)
    800058bc:	37fd                	addiw	a5,a5,-1
    800058be:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058c2:	8526                	mv	a0,s1
    800058c4:	ffffe097          	auipc	ra,0xffffe
    800058c8:	164080e7          	jalr	356(ra) # 80003a28 <iupdate>
  iunlockput(ip);
    800058cc:	8526                	mv	a0,s1
    800058ce:	ffffe097          	auipc	ra,0xffffe
    800058d2:	488080e7          	jalr	1160(ra) # 80003d56 <iunlockput>
  end_op();
    800058d6:	fffff097          	auipc	ra,0xfffff
    800058da:	c68080e7          	jalr	-920(ra) # 8000453e <end_op>
  return -1;
    800058de:	57fd                	li	a5,-1
}
    800058e0:	853e                	mv	a0,a5
    800058e2:	70b2                	ld	ra,296(sp)
    800058e4:	7412                	ld	s0,288(sp)
    800058e6:	64f2                	ld	s1,280(sp)
    800058e8:	6952                	ld	s2,272(sp)
    800058ea:	6155                	addi	sp,sp,304
    800058ec:	8082                	ret

00000000800058ee <sys_unlink>:
{
    800058ee:	7151                	addi	sp,sp,-240
    800058f0:	f586                	sd	ra,232(sp)
    800058f2:	f1a2                	sd	s0,224(sp)
    800058f4:	eda6                	sd	s1,216(sp)
    800058f6:	e9ca                	sd	s2,208(sp)
    800058f8:	e5ce                	sd	s3,200(sp)
    800058fa:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800058fc:	08000613          	li	a2,128
    80005900:	f3040593          	addi	a1,s0,-208
    80005904:	4501                	li	a0,0
    80005906:	ffffd097          	auipc	ra,0xffffd
    8000590a:	562080e7          	jalr	1378(ra) # 80002e68 <argstr>
    8000590e:	18054163          	bltz	a0,80005a90 <sys_unlink+0x1a2>
  begin_op();
    80005912:	fffff097          	auipc	ra,0xfffff
    80005916:	bae080e7          	jalr	-1106(ra) # 800044c0 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000591a:	fb040593          	addi	a1,s0,-80
    8000591e:	f3040513          	addi	a0,s0,-208
    80005922:	fffff097          	auipc	ra,0xfffff
    80005926:	99c080e7          	jalr	-1636(ra) # 800042be <nameiparent>
    8000592a:	84aa                	mv	s1,a0
    8000592c:	c979                	beqz	a0,80005a02 <sys_unlink+0x114>
  ilock(dp);
    8000592e:	ffffe097          	auipc	ra,0xffffe
    80005932:	1c6080e7          	jalr	454(ra) # 80003af4 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005936:	00003597          	auipc	a1,0x3
    8000593a:	dda58593          	addi	a1,a1,-550 # 80008710 <syscalls+0x2b8>
    8000593e:	fb040513          	addi	a0,s0,-80
    80005942:	ffffe097          	auipc	ra,0xffffe
    80005946:	67c080e7          	jalr	1660(ra) # 80003fbe <namecmp>
    8000594a:	14050a63          	beqz	a0,80005a9e <sys_unlink+0x1b0>
    8000594e:	00003597          	auipc	a1,0x3
    80005952:	dca58593          	addi	a1,a1,-566 # 80008718 <syscalls+0x2c0>
    80005956:	fb040513          	addi	a0,s0,-80
    8000595a:	ffffe097          	auipc	ra,0xffffe
    8000595e:	664080e7          	jalr	1636(ra) # 80003fbe <namecmp>
    80005962:	12050e63          	beqz	a0,80005a9e <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005966:	f2c40613          	addi	a2,s0,-212
    8000596a:	fb040593          	addi	a1,s0,-80
    8000596e:	8526                	mv	a0,s1
    80005970:	ffffe097          	auipc	ra,0xffffe
    80005974:	668080e7          	jalr	1640(ra) # 80003fd8 <dirlookup>
    80005978:	892a                	mv	s2,a0
    8000597a:	12050263          	beqz	a0,80005a9e <sys_unlink+0x1b0>
  ilock(ip);
    8000597e:	ffffe097          	auipc	ra,0xffffe
    80005982:	176080e7          	jalr	374(ra) # 80003af4 <ilock>
  if(ip->nlink < 1)
    80005986:	04a91783          	lh	a5,74(s2)
    8000598a:	08f05263          	blez	a5,80005a0e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    8000598e:	04491703          	lh	a4,68(s2)
    80005992:	4785                	li	a5,1
    80005994:	08f70563          	beq	a4,a5,80005a1e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005998:	4641                	li	a2,16
    8000599a:	4581                	li	a1,0
    8000599c:	fc040513          	addi	a0,s0,-64
    800059a0:	ffffb097          	auipc	ra,0xffffb
    800059a4:	332080e7          	jalr	818(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059a8:	4741                	li	a4,16
    800059aa:	f2c42683          	lw	a3,-212(s0)
    800059ae:	fc040613          	addi	a2,s0,-64
    800059b2:	4581                	li	a1,0
    800059b4:	8526                	mv	a0,s1
    800059b6:	ffffe097          	auipc	ra,0xffffe
    800059ba:	4ea080e7          	jalr	1258(ra) # 80003ea0 <writei>
    800059be:	47c1                	li	a5,16
    800059c0:	0af51563          	bne	a0,a5,80005a6a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059c4:	04491703          	lh	a4,68(s2)
    800059c8:	4785                	li	a5,1
    800059ca:	0af70863          	beq	a4,a5,80005a7a <sys_unlink+0x18c>
  iunlockput(dp);
    800059ce:	8526                	mv	a0,s1
    800059d0:	ffffe097          	auipc	ra,0xffffe
    800059d4:	386080e7          	jalr	902(ra) # 80003d56 <iunlockput>
  ip->nlink--;
    800059d8:	04a95783          	lhu	a5,74(s2)
    800059dc:	37fd                	addiw	a5,a5,-1
    800059de:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800059e2:	854a                	mv	a0,s2
    800059e4:	ffffe097          	auipc	ra,0xffffe
    800059e8:	044080e7          	jalr	68(ra) # 80003a28 <iupdate>
  iunlockput(ip);
    800059ec:	854a                	mv	a0,s2
    800059ee:	ffffe097          	auipc	ra,0xffffe
    800059f2:	368080e7          	jalr	872(ra) # 80003d56 <iunlockput>
  end_op();
    800059f6:	fffff097          	auipc	ra,0xfffff
    800059fa:	b48080e7          	jalr	-1208(ra) # 8000453e <end_op>
  return 0;
    800059fe:	4501                	li	a0,0
    80005a00:	a84d                	j	80005ab2 <sys_unlink+0x1c4>
    end_op();
    80005a02:	fffff097          	auipc	ra,0xfffff
    80005a06:	b3c080e7          	jalr	-1220(ra) # 8000453e <end_op>
    return -1;
    80005a0a:	557d                	li	a0,-1
    80005a0c:	a05d                	j	80005ab2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a0e:	00003517          	auipc	a0,0x3
    80005a12:	d1250513          	addi	a0,a0,-750 # 80008720 <syscalls+0x2c8>
    80005a16:	ffffb097          	auipc	ra,0xffffb
    80005a1a:	b2a080e7          	jalr	-1238(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a1e:	04c92703          	lw	a4,76(s2)
    80005a22:	02000793          	li	a5,32
    80005a26:	f6e7f9e3          	bgeu	a5,a4,80005998 <sys_unlink+0xaa>
    80005a2a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a2e:	4741                	li	a4,16
    80005a30:	86ce                	mv	a3,s3
    80005a32:	f1840613          	addi	a2,s0,-232
    80005a36:	4581                	li	a1,0
    80005a38:	854a                	mv	a0,s2
    80005a3a:	ffffe097          	auipc	ra,0xffffe
    80005a3e:	36e080e7          	jalr	878(ra) # 80003da8 <readi>
    80005a42:	47c1                	li	a5,16
    80005a44:	00f51b63          	bne	a0,a5,80005a5a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a48:	f1845783          	lhu	a5,-232(s0)
    80005a4c:	e7a1                	bnez	a5,80005a94 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4e:	29c1                	addiw	s3,s3,16
    80005a50:	04c92783          	lw	a5,76(s2)
    80005a54:	fcf9ede3          	bltu	s3,a5,80005a2e <sys_unlink+0x140>
    80005a58:	b781                	j	80005998 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a5a:	00003517          	auipc	a0,0x3
    80005a5e:	cde50513          	addi	a0,a0,-802 # 80008738 <syscalls+0x2e0>
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	ade080e7          	jalr	-1314(ra) # 80000540 <panic>
    panic("unlink: writei");
    80005a6a:	00003517          	auipc	a0,0x3
    80005a6e:	ce650513          	addi	a0,a0,-794 # 80008750 <syscalls+0x2f8>
    80005a72:	ffffb097          	auipc	ra,0xffffb
    80005a76:	ace080e7          	jalr	-1330(ra) # 80000540 <panic>
    dp->nlink--;
    80005a7a:	04a4d783          	lhu	a5,74(s1)
    80005a7e:	37fd                	addiw	a5,a5,-1
    80005a80:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005a84:	8526                	mv	a0,s1
    80005a86:	ffffe097          	auipc	ra,0xffffe
    80005a8a:	fa2080e7          	jalr	-94(ra) # 80003a28 <iupdate>
    80005a8e:	b781                	j	800059ce <sys_unlink+0xe0>
    return -1;
    80005a90:	557d                	li	a0,-1
    80005a92:	a005                	j	80005ab2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005a94:	854a                	mv	a0,s2
    80005a96:	ffffe097          	auipc	ra,0xffffe
    80005a9a:	2c0080e7          	jalr	704(ra) # 80003d56 <iunlockput>
  iunlockput(dp);
    80005a9e:	8526                	mv	a0,s1
    80005aa0:	ffffe097          	auipc	ra,0xffffe
    80005aa4:	2b6080e7          	jalr	694(ra) # 80003d56 <iunlockput>
  end_op();
    80005aa8:	fffff097          	auipc	ra,0xfffff
    80005aac:	a96080e7          	jalr	-1386(ra) # 8000453e <end_op>
  return -1;
    80005ab0:	557d                	li	a0,-1
}
    80005ab2:	70ae                	ld	ra,232(sp)
    80005ab4:	740e                	ld	s0,224(sp)
    80005ab6:	64ee                	ld	s1,216(sp)
    80005ab8:	694e                	ld	s2,208(sp)
    80005aba:	69ae                	ld	s3,200(sp)
    80005abc:	616d                	addi	sp,sp,240
    80005abe:	8082                	ret

0000000080005ac0 <sys_open>:

uint64
sys_open(void)
{
    80005ac0:	7131                	addi	sp,sp,-192
    80005ac2:	fd06                	sd	ra,184(sp)
    80005ac4:	f922                	sd	s0,176(sp)
    80005ac6:	f526                	sd	s1,168(sp)
    80005ac8:	f14a                	sd	s2,160(sp)
    80005aca:	ed4e                	sd	s3,152(sp)
    80005acc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005ace:	f4c40593          	addi	a1,s0,-180
    80005ad2:	4505                	li	a0,1
    80005ad4:	ffffd097          	auipc	ra,0xffffd
    80005ad8:	354080e7          	jalr	852(ra) # 80002e28 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005adc:	08000613          	li	a2,128
    80005ae0:	f5040593          	addi	a1,s0,-176
    80005ae4:	4501                	li	a0,0
    80005ae6:	ffffd097          	auipc	ra,0xffffd
    80005aea:	382080e7          	jalr	898(ra) # 80002e68 <argstr>
    80005aee:	87aa                	mv	a5,a0
    return -1;
    80005af0:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005af2:	0a07c963          	bltz	a5,80005ba4 <sys_open+0xe4>

  begin_op();
    80005af6:	fffff097          	auipc	ra,0xfffff
    80005afa:	9ca080e7          	jalr	-1590(ra) # 800044c0 <begin_op>

  if(omode & O_CREATE){
    80005afe:	f4c42783          	lw	a5,-180(s0)
    80005b02:	2007f793          	andi	a5,a5,512
    80005b06:	cfc5                	beqz	a5,80005bbe <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b08:	4681                	li	a3,0
    80005b0a:	4601                	li	a2,0
    80005b0c:	4589                	li	a1,2
    80005b0e:	f5040513          	addi	a0,s0,-176
    80005b12:	00000097          	auipc	ra,0x0
    80005b16:	950080e7          	jalr	-1712(ra) # 80005462 <create>
    80005b1a:	84aa                	mv	s1,a0
    if(ip == 0){
    80005b1c:	c959                	beqz	a0,80005bb2 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b1e:	04449703          	lh	a4,68(s1)
    80005b22:	478d                	li	a5,3
    80005b24:	00f71763          	bne	a4,a5,80005b32 <sys_open+0x72>
    80005b28:	0464d703          	lhu	a4,70(s1)
    80005b2c:	47a5                	li	a5,9
    80005b2e:	0ce7ed63          	bltu	a5,a4,80005c08 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b32:	fffff097          	auipc	ra,0xfffff
    80005b36:	d9a080e7          	jalr	-614(ra) # 800048cc <filealloc>
    80005b3a:	89aa                	mv	s3,a0
    80005b3c:	10050363          	beqz	a0,80005c42 <sys_open+0x182>
    80005b40:	00000097          	auipc	ra,0x0
    80005b44:	8e0080e7          	jalr	-1824(ra) # 80005420 <fdalloc>
    80005b48:	892a                	mv	s2,a0
    80005b4a:	0e054763          	bltz	a0,80005c38 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b4e:	04449703          	lh	a4,68(s1)
    80005b52:	478d                	li	a5,3
    80005b54:	0cf70563          	beq	a4,a5,80005c1e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b58:	4789                	li	a5,2
    80005b5a:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b5e:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b62:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b66:	f4c42783          	lw	a5,-180(s0)
    80005b6a:	0017c713          	xori	a4,a5,1
    80005b6e:	8b05                	andi	a4,a4,1
    80005b70:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005b74:	0037f713          	andi	a4,a5,3
    80005b78:	00e03733          	snez	a4,a4
    80005b7c:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005b80:	4007f793          	andi	a5,a5,1024
    80005b84:	c791                	beqz	a5,80005b90 <sys_open+0xd0>
    80005b86:	04449703          	lh	a4,68(s1)
    80005b8a:	4789                	li	a5,2
    80005b8c:	0af70063          	beq	a4,a5,80005c2c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005b90:	8526                	mv	a0,s1
    80005b92:	ffffe097          	auipc	ra,0xffffe
    80005b96:	024080e7          	jalr	36(ra) # 80003bb6 <iunlock>
  end_op();
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	9a4080e7          	jalr	-1628(ra) # 8000453e <end_op>

  return fd;
    80005ba2:	854a                	mv	a0,s2
}
    80005ba4:	70ea                	ld	ra,184(sp)
    80005ba6:	744a                	ld	s0,176(sp)
    80005ba8:	74aa                	ld	s1,168(sp)
    80005baa:	790a                	ld	s2,160(sp)
    80005bac:	69ea                	ld	s3,152(sp)
    80005bae:	6129                	addi	sp,sp,192
    80005bb0:	8082                	ret
      end_op();
    80005bb2:	fffff097          	auipc	ra,0xfffff
    80005bb6:	98c080e7          	jalr	-1652(ra) # 8000453e <end_op>
      return -1;
    80005bba:	557d                	li	a0,-1
    80005bbc:	b7e5                	j	80005ba4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bbe:	f5040513          	addi	a0,s0,-176
    80005bc2:	ffffe097          	auipc	ra,0xffffe
    80005bc6:	6de080e7          	jalr	1758(ra) # 800042a0 <namei>
    80005bca:	84aa                	mv	s1,a0
    80005bcc:	c905                	beqz	a0,80005bfc <sys_open+0x13c>
    ilock(ip);
    80005bce:	ffffe097          	auipc	ra,0xffffe
    80005bd2:	f26080e7          	jalr	-218(ra) # 80003af4 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005bd6:	04449703          	lh	a4,68(s1)
    80005bda:	4785                	li	a5,1
    80005bdc:	f4f711e3          	bne	a4,a5,80005b1e <sys_open+0x5e>
    80005be0:	f4c42783          	lw	a5,-180(s0)
    80005be4:	d7b9                	beqz	a5,80005b32 <sys_open+0x72>
      iunlockput(ip);
    80005be6:	8526                	mv	a0,s1
    80005be8:	ffffe097          	auipc	ra,0xffffe
    80005bec:	16e080e7          	jalr	366(ra) # 80003d56 <iunlockput>
      end_op();
    80005bf0:	fffff097          	auipc	ra,0xfffff
    80005bf4:	94e080e7          	jalr	-1714(ra) # 8000453e <end_op>
      return -1;
    80005bf8:	557d                	li	a0,-1
    80005bfa:	b76d                	j	80005ba4 <sys_open+0xe4>
      end_op();
    80005bfc:	fffff097          	auipc	ra,0xfffff
    80005c00:	942080e7          	jalr	-1726(ra) # 8000453e <end_op>
      return -1;
    80005c04:	557d                	li	a0,-1
    80005c06:	bf79                	j	80005ba4 <sys_open+0xe4>
    iunlockput(ip);
    80005c08:	8526                	mv	a0,s1
    80005c0a:	ffffe097          	auipc	ra,0xffffe
    80005c0e:	14c080e7          	jalr	332(ra) # 80003d56 <iunlockput>
    end_op();
    80005c12:	fffff097          	auipc	ra,0xfffff
    80005c16:	92c080e7          	jalr	-1748(ra) # 8000453e <end_op>
    return -1;
    80005c1a:	557d                	li	a0,-1
    80005c1c:	b761                	j	80005ba4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c1e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c22:	04649783          	lh	a5,70(s1)
    80005c26:	02f99223          	sh	a5,36(s3)
    80005c2a:	bf25                	j	80005b62 <sys_open+0xa2>
    itrunc(ip);
    80005c2c:	8526                	mv	a0,s1
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	fd4080e7          	jalr	-44(ra) # 80003c02 <itrunc>
    80005c36:	bfa9                	j	80005b90 <sys_open+0xd0>
      fileclose(f);
    80005c38:	854e                	mv	a0,s3
    80005c3a:	fffff097          	auipc	ra,0xfffff
    80005c3e:	d4e080e7          	jalr	-690(ra) # 80004988 <fileclose>
    iunlockput(ip);
    80005c42:	8526                	mv	a0,s1
    80005c44:	ffffe097          	auipc	ra,0xffffe
    80005c48:	112080e7          	jalr	274(ra) # 80003d56 <iunlockput>
    end_op();
    80005c4c:	fffff097          	auipc	ra,0xfffff
    80005c50:	8f2080e7          	jalr	-1806(ra) # 8000453e <end_op>
    return -1;
    80005c54:	557d                	li	a0,-1
    80005c56:	b7b9                	j	80005ba4 <sys_open+0xe4>

0000000080005c58 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c58:	7175                	addi	sp,sp,-144
    80005c5a:	e506                	sd	ra,136(sp)
    80005c5c:	e122                	sd	s0,128(sp)
    80005c5e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c60:	fffff097          	auipc	ra,0xfffff
    80005c64:	860080e7          	jalr	-1952(ra) # 800044c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c68:	08000613          	li	a2,128
    80005c6c:	f7040593          	addi	a1,s0,-144
    80005c70:	4501                	li	a0,0
    80005c72:	ffffd097          	auipc	ra,0xffffd
    80005c76:	1f6080e7          	jalr	502(ra) # 80002e68 <argstr>
    80005c7a:	02054963          	bltz	a0,80005cac <sys_mkdir+0x54>
    80005c7e:	4681                	li	a3,0
    80005c80:	4601                	li	a2,0
    80005c82:	4585                	li	a1,1
    80005c84:	f7040513          	addi	a0,s0,-144
    80005c88:	fffff097          	auipc	ra,0xfffff
    80005c8c:	7da080e7          	jalr	2010(ra) # 80005462 <create>
    80005c90:	cd11                	beqz	a0,80005cac <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005c92:	ffffe097          	auipc	ra,0xffffe
    80005c96:	0c4080e7          	jalr	196(ra) # 80003d56 <iunlockput>
  end_op();
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	8a4080e7          	jalr	-1884(ra) # 8000453e <end_op>
  return 0;
    80005ca2:	4501                	li	a0,0
}
    80005ca4:	60aa                	ld	ra,136(sp)
    80005ca6:	640a                	ld	s0,128(sp)
    80005ca8:	6149                	addi	sp,sp,144
    80005caa:	8082                	ret
    end_op();
    80005cac:	fffff097          	auipc	ra,0xfffff
    80005cb0:	892080e7          	jalr	-1902(ra) # 8000453e <end_op>
    return -1;
    80005cb4:	557d                	li	a0,-1
    80005cb6:	b7fd                	j	80005ca4 <sys_mkdir+0x4c>

0000000080005cb8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005cb8:	7135                	addi	sp,sp,-160
    80005cba:	ed06                	sd	ra,152(sp)
    80005cbc:	e922                	sd	s0,144(sp)
    80005cbe:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cc0:	fffff097          	auipc	ra,0xfffff
    80005cc4:	800080e7          	jalr	-2048(ra) # 800044c0 <begin_op>
  argint(1, &major);
    80005cc8:	f6c40593          	addi	a1,s0,-148
    80005ccc:	4505                	li	a0,1
    80005cce:	ffffd097          	auipc	ra,0xffffd
    80005cd2:	15a080e7          	jalr	346(ra) # 80002e28 <argint>
  argint(2, &minor);
    80005cd6:	f6840593          	addi	a1,s0,-152
    80005cda:	4509                	li	a0,2
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	14c080e7          	jalr	332(ra) # 80002e28 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ce4:	08000613          	li	a2,128
    80005ce8:	f7040593          	addi	a1,s0,-144
    80005cec:	4501                	li	a0,0
    80005cee:	ffffd097          	auipc	ra,0xffffd
    80005cf2:	17a080e7          	jalr	378(ra) # 80002e68 <argstr>
    80005cf6:	02054b63          	bltz	a0,80005d2c <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005cfa:	f6841683          	lh	a3,-152(s0)
    80005cfe:	f6c41603          	lh	a2,-148(s0)
    80005d02:	458d                	li	a1,3
    80005d04:	f7040513          	addi	a0,s0,-144
    80005d08:	fffff097          	auipc	ra,0xfffff
    80005d0c:	75a080e7          	jalr	1882(ra) # 80005462 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d10:	cd11                	beqz	a0,80005d2c <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d12:	ffffe097          	auipc	ra,0xffffe
    80005d16:	044080e7          	jalr	68(ra) # 80003d56 <iunlockput>
  end_op();
    80005d1a:	fffff097          	auipc	ra,0xfffff
    80005d1e:	824080e7          	jalr	-2012(ra) # 8000453e <end_op>
  return 0;
    80005d22:	4501                	li	a0,0
}
    80005d24:	60ea                	ld	ra,152(sp)
    80005d26:	644a                	ld	s0,144(sp)
    80005d28:	610d                	addi	sp,sp,160
    80005d2a:	8082                	ret
    end_op();
    80005d2c:	fffff097          	auipc	ra,0xfffff
    80005d30:	812080e7          	jalr	-2030(ra) # 8000453e <end_op>
    return -1;
    80005d34:	557d                	li	a0,-1
    80005d36:	b7fd                	j	80005d24 <sys_mknod+0x6c>

0000000080005d38 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d38:	7135                	addi	sp,sp,-160
    80005d3a:	ed06                	sd	ra,152(sp)
    80005d3c:	e922                	sd	s0,144(sp)
    80005d3e:	e526                	sd	s1,136(sp)
    80005d40:	e14a                	sd	s2,128(sp)
    80005d42:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d44:	ffffc097          	auipc	ra,0xffffc
    80005d48:	c68080e7          	jalr	-920(ra) # 800019ac <myproc>
    80005d4c:	892a                	mv	s2,a0
  
  begin_op();
    80005d4e:	ffffe097          	auipc	ra,0xffffe
    80005d52:	772080e7          	jalr	1906(ra) # 800044c0 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d56:	08000613          	li	a2,128
    80005d5a:	f6040593          	addi	a1,s0,-160
    80005d5e:	4501                	li	a0,0
    80005d60:	ffffd097          	auipc	ra,0xffffd
    80005d64:	108080e7          	jalr	264(ra) # 80002e68 <argstr>
    80005d68:	04054b63          	bltz	a0,80005dbe <sys_chdir+0x86>
    80005d6c:	f6040513          	addi	a0,s0,-160
    80005d70:	ffffe097          	auipc	ra,0xffffe
    80005d74:	530080e7          	jalr	1328(ra) # 800042a0 <namei>
    80005d78:	84aa                	mv	s1,a0
    80005d7a:	c131                	beqz	a0,80005dbe <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005d7c:	ffffe097          	auipc	ra,0xffffe
    80005d80:	d78080e7          	jalr	-648(ra) # 80003af4 <ilock>
  if(ip->type != T_DIR){
    80005d84:	04449703          	lh	a4,68(s1)
    80005d88:	4785                	li	a5,1
    80005d8a:	04f71063          	bne	a4,a5,80005dca <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005d8e:	8526                	mv	a0,s1
    80005d90:	ffffe097          	auipc	ra,0xffffe
    80005d94:	e26080e7          	jalr	-474(ra) # 80003bb6 <iunlock>
  iput(p->cwd);
    80005d98:	15093503          	ld	a0,336(s2)
    80005d9c:	ffffe097          	auipc	ra,0xffffe
    80005da0:	f12080e7          	jalr	-238(ra) # 80003cae <iput>
  end_op();
    80005da4:	ffffe097          	auipc	ra,0xffffe
    80005da8:	79a080e7          	jalr	1946(ra) # 8000453e <end_op>
  p->cwd = ip;
    80005dac:	14993823          	sd	s1,336(s2)
  return 0;
    80005db0:	4501                	li	a0,0
}
    80005db2:	60ea                	ld	ra,152(sp)
    80005db4:	644a                	ld	s0,144(sp)
    80005db6:	64aa                	ld	s1,136(sp)
    80005db8:	690a                	ld	s2,128(sp)
    80005dba:	610d                	addi	sp,sp,160
    80005dbc:	8082                	ret
    end_op();
    80005dbe:	ffffe097          	auipc	ra,0xffffe
    80005dc2:	780080e7          	jalr	1920(ra) # 8000453e <end_op>
    return -1;
    80005dc6:	557d                	li	a0,-1
    80005dc8:	b7ed                	j	80005db2 <sys_chdir+0x7a>
    iunlockput(ip);
    80005dca:	8526                	mv	a0,s1
    80005dcc:	ffffe097          	auipc	ra,0xffffe
    80005dd0:	f8a080e7          	jalr	-118(ra) # 80003d56 <iunlockput>
    end_op();
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	76a080e7          	jalr	1898(ra) # 8000453e <end_op>
    return -1;
    80005ddc:	557d                	li	a0,-1
    80005dde:	bfd1                	j	80005db2 <sys_chdir+0x7a>

0000000080005de0 <sys_exec>:

uint64
sys_exec(void)
{
    80005de0:	7145                	addi	sp,sp,-464
    80005de2:	e786                	sd	ra,456(sp)
    80005de4:	e3a2                	sd	s0,448(sp)
    80005de6:	ff26                	sd	s1,440(sp)
    80005de8:	fb4a                	sd	s2,432(sp)
    80005dea:	f74e                	sd	s3,424(sp)
    80005dec:	f352                	sd	s4,416(sp)
    80005dee:	ef56                	sd	s5,408(sp)
    80005df0:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005df2:	e3840593          	addi	a1,s0,-456
    80005df6:	4505                	li	a0,1
    80005df8:	ffffd097          	auipc	ra,0xffffd
    80005dfc:	050080e7          	jalr	80(ra) # 80002e48 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005e00:	08000613          	li	a2,128
    80005e04:	f4040593          	addi	a1,s0,-192
    80005e08:	4501                	li	a0,0
    80005e0a:	ffffd097          	auipc	ra,0xffffd
    80005e0e:	05e080e7          	jalr	94(ra) # 80002e68 <argstr>
    80005e12:	87aa                	mv	a5,a0
    return -1;
    80005e14:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005e16:	0c07c363          	bltz	a5,80005edc <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005e1a:	10000613          	li	a2,256
    80005e1e:	4581                	li	a1,0
    80005e20:	e4040513          	addi	a0,s0,-448
    80005e24:	ffffb097          	auipc	ra,0xffffb
    80005e28:	eae080e7          	jalr	-338(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e2c:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e30:	89a6                	mv	s3,s1
    80005e32:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e34:	02000a13          	li	s4,32
    80005e38:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e3c:	00391513          	slli	a0,s2,0x3
    80005e40:	e3040593          	addi	a1,s0,-464
    80005e44:	e3843783          	ld	a5,-456(s0)
    80005e48:	953e                	add	a0,a0,a5
    80005e4a:	ffffd097          	auipc	ra,0xffffd
    80005e4e:	f40080e7          	jalr	-192(ra) # 80002d8a <fetchaddr>
    80005e52:	02054a63          	bltz	a0,80005e86 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005e56:	e3043783          	ld	a5,-464(s0)
    80005e5a:	c3b9                	beqz	a5,80005ea0 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e5c:	ffffb097          	auipc	ra,0xffffb
    80005e60:	c8a080e7          	jalr	-886(ra) # 80000ae6 <kalloc>
    80005e64:	85aa                	mv	a1,a0
    80005e66:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005e6a:	cd11                	beqz	a0,80005e86 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005e6c:	6605                	lui	a2,0x1
    80005e6e:	e3043503          	ld	a0,-464(s0)
    80005e72:	ffffd097          	auipc	ra,0xffffd
    80005e76:	f6a080e7          	jalr	-150(ra) # 80002ddc <fetchstr>
    80005e7a:	00054663          	bltz	a0,80005e86 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005e7e:	0905                	addi	s2,s2,1
    80005e80:	09a1                	addi	s3,s3,8
    80005e82:	fb491be3          	bne	s2,s4,80005e38 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e86:	f4040913          	addi	s2,s0,-192
    80005e8a:	6088                	ld	a0,0(s1)
    80005e8c:	c539                	beqz	a0,80005eda <sys_exec+0xfa>
    kfree(argv[i]);
    80005e8e:	ffffb097          	auipc	ra,0xffffb
    80005e92:	b5a080e7          	jalr	-1190(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005e96:	04a1                	addi	s1,s1,8
    80005e98:	ff2499e3          	bne	s1,s2,80005e8a <sys_exec+0xaa>
  return -1;
    80005e9c:	557d                	li	a0,-1
    80005e9e:	a83d                	j	80005edc <sys_exec+0xfc>
      argv[i] = 0;
    80005ea0:	0a8e                	slli	s5,s5,0x3
    80005ea2:	fc0a8793          	addi	a5,s5,-64
    80005ea6:	00878ab3          	add	s5,a5,s0
    80005eaa:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005eae:	e4040593          	addi	a1,s0,-448
    80005eb2:	f4040513          	addi	a0,s0,-192
    80005eb6:	fffff097          	auipc	ra,0xfffff
    80005eba:	14c080e7          	jalr	332(ra) # 80005002 <exec>
    80005ebe:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec0:	f4040993          	addi	s3,s0,-192
    80005ec4:	6088                	ld	a0,0(s1)
    80005ec6:	c901                	beqz	a0,80005ed6 <sys_exec+0xf6>
    kfree(argv[i]);
    80005ec8:	ffffb097          	auipc	ra,0xffffb
    80005ecc:	b20080e7          	jalr	-1248(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed0:	04a1                	addi	s1,s1,8
    80005ed2:	ff3499e3          	bne	s1,s3,80005ec4 <sys_exec+0xe4>
  return ret;
    80005ed6:	854a                	mv	a0,s2
    80005ed8:	a011                	j	80005edc <sys_exec+0xfc>
  return -1;
    80005eda:	557d                	li	a0,-1
}
    80005edc:	60be                	ld	ra,456(sp)
    80005ede:	641e                	ld	s0,448(sp)
    80005ee0:	74fa                	ld	s1,440(sp)
    80005ee2:	795a                	ld	s2,432(sp)
    80005ee4:	79ba                	ld	s3,424(sp)
    80005ee6:	7a1a                	ld	s4,416(sp)
    80005ee8:	6afa                	ld	s5,408(sp)
    80005eea:	6179                	addi	sp,sp,464
    80005eec:	8082                	ret

0000000080005eee <sys_pipe>:

uint64
sys_pipe(void)
{
    80005eee:	7139                	addi	sp,sp,-64
    80005ef0:	fc06                	sd	ra,56(sp)
    80005ef2:	f822                	sd	s0,48(sp)
    80005ef4:	f426                	sd	s1,40(sp)
    80005ef6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005ef8:	ffffc097          	auipc	ra,0xffffc
    80005efc:	ab4080e7          	jalr	-1356(ra) # 800019ac <myproc>
    80005f00:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005f02:	fd840593          	addi	a1,s0,-40
    80005f06:	4501                	li	a0,0
    80005f08:	ffffd097          	auipc	ra,0xffffd
    80005f0c:	f40080e7          	jalr	-192(ra) # 80002e48 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005f10:	fc840593          	addi	a1,s0,-56
    80005f14:	fd040513          	addi	a0,s0,-48
    80005f18:	fffff097          	auipc	ra,0xfffff
    80005f1c:	da0080e7          	jalr	-608(ra) # 80004cb8 <pipealloc>
    return -1;
    80005f20:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f22:	0c054463          	bltz	a0,80005fea <sys_pipe+0xfc>
  fd0 = -1;
    80005f26:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f2a:	fd043503          	ld	a0,-48(s0)
    80005f2e:	fffff097          	auipc	ra,0xfffff
    80005f32:	4f2080e7          	jalr	1266(ra) # 80005420 <fdalloc>
    80005f36:	fca42223          	sw	a0,-60(s0)
    80005f3a:	08054b63          	bltz	a0,80005fd0 <sys_pipe+0xe2>
    80005f3e:	fc843503          	ld	a0,-56(s0)
    80005f42:	fffff097          	auipc	ra,0xfffff
    80005f46:	4de080e7          	jalr	1246(ra) # 80005420 <fdalloc>
    80005f4a:	fca42023          	sw	a0,-64(s0)
    80005f4e:	06054863          	bltz	a0,80005fbe <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f52:	4691                	li	a3,4
    80005f54:	fc440613          	addi	a2,s0,-60
    80005f58:	fd843583          	ld	a1,-40(s0)
    80005f5c:	68a8                	ld	a0,80(s1)
    80005f5e:	ffffb097          	auipc	ra,0xffffb
    80005f62:	70e080e7          	jalr	1806(ra) # 8000166c <copyout>
    80005f66:	02054063          	bltz	a0,80005f86 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005f6a:	4691                	li	a3,4
    80005f6c:	fc040613          	addi	a2,s0,-64
    80005f70:	fd843583          	ld	a1,-40(s0)
    80005f74:	0591                	addi	a1,a1,4
    80005f76:	68a8                	ld	a0,80(s1)
    80005f78:	ffffb097          	auipc	ra,0xffffb
    80005f7c:	6f4080e7          	jalr	1780(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005f80:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f82:	06055463          	bgez	a0,80005fea <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005f86:	fc442783          	lw	a5,-60(s0)
    80005f8a:	07e9                	addi	a5,a5,26
    80005f8c:	078e                	slli	a5,a5,0x3
    80005f8e:	97a6                	add	a5,a5,s1
    80005f90:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005f94:	fc042783          	lw	a5,-64(s0)
    80005f98:	07e9                	addi	a5,a5,26
    80005f9a:	078e                	slli	a5,a5,0x3
    80005f9c:	94be                	add	s1,s1,a5
    80005f9e:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005fa2:	fd043503          	ld	a0,-48(s0)
    80005fa6:	fffff097          	auipc	ra,0xfffff
    80005faa:	9e2080e7          	jalr	-1566(ra) # 80004988 <fileclose>
    fileclose(wf);
    80005fae:	fc843503          	ld	a0,-56(s0)
    80005fb2:	fffff097          	auipc	ra,0xfffff
    80005fb6:	9d6080e7          	jalr	-1578(ra) # 80004988 <fileclose>
    return -1;
    80005fba:	57fd                	li	a5,-1
    80005fbc:	a03d                	j	80005fea <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005fbe:	fc442783          	lw	a5,-60(s0)
    80005fc2:	0007c763          	bltz	a5,80005fd0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005fc6:	07e9                	addi	a5,a5,26
    80005fc8:	078e                	slli	a5,a5,0x3
    80005fca:	97a6                	add	a5,a5,s1
    80005fcc:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005fd0:	fd043503          	ld	a0,-48(s0)
    80005fd4:	fffff097          	auipc	ra,0xfffff
    80005fd8:	9b4080e7          	jalr	-1612(ra) # 80004988 <fileclose>
    fileclose(wf);
    80005fdc:	fc843503          	ld	a0,-56(s0)
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	9a8080e7          	jalr	-1624(ra) # 80004988 <fileclose>
    return -1;
    80005fe8:	57fd                	li	a5,-1
}
    80005fea:	853e                	mv	a0,a5
    80005fec:	70e2                	ld	ra,56(sp)
    80005fee:	7442                	ld	s0,48(sp)
    80005ff0:	74a2                	ld	s1,40(sp)
    80005ff2:	6121                	addi	sp,sp,64
    80005ff4:	8082                	ret
	...

0000000080006000 <kernelvec>:
    80006000:	7111                	addi	sp,sp,-256
    80006002:	e006                	sd	ra,0(sp)
    80006004:	e40a                	sd	sp,8(sp)
    80006006:	e80e                	sd	gp,16(sp)
    80006008:	ec12                	sd	tp,24(sp)
    8000600a:	f016                	sd	t0,32(sp)
    8000600c:	f41a                	sd	t1,40(sp)
    8000600e:	f81e                	sd	t2,48(sp)
    80006010:	fc22                	sd	s0,56(sp)
    80006012:	e0a6                	sd	s1,64(sp)
    80006014:	e4aa                	sd	a0,72(sp)
    80006016:	e8ae                	sd	a1,80(sp)
    80006018:	ecb2                	sd	a2,88(sp)
    8000601a:	f0b6                	sd	a3,96(sp)
    8000601c:	f4ba                	sd	a4,104(sp)
    8000601e:	f8be                	sd	a5,112(sp)
    80006020:	fcc2                	sd	a6,120(sp)
    80006022:	e146                	sd	a7,128(sp)
    80006024:	e54a                	sd	s2,136(sp)
    80006026:	e94e                	sd	s3,144(sp)
    80006028:	ed52                	sd	s4,152(sp)
    8000602a:	f156                	sd	s5,160(sp)
    8000602c:	f55a                	sd	s6,168(sp)
    8000602e:	f95e                	sd	s7,176(sp)
    80006030:	fd62                	sd	s8,184(sp)
    80006032:	e1e6                	sd	s9,192(sp)
    80006034:	e5ea                	sd	s10,200(sp)
    80006036:	e9ee                	sd	s11,208(sp)
    80006038:	edf2                	sd	t3,216(sp)
    8000603a:	f1f6                	sd	t4,224(sp)
    8000603c:	f5fa                	sd	t5,232(sp)
    8000603e:	f9fe                	sd	t6,240(sp)
    80006040:	c17fc0ef          	jal	ra,80002c56 <kerneltrap>
    80006044:	6082                	ld	ra,0(sp)
    80006046:	6122                	ld	sp,8(sp)
    80006048:	61c2                	ld	gp,16(sp)
    8000604a:	7282                	ld	t0,32(sp)
    8000604c:	7322                	ld	t1,40(sp)
    8000604e:	73c2                	ld	t2,48(sp)
    80006050:	7462                	ld	s0,56(sp)
    80006052:	6486                	ld	s1,64(sp)
    80006054:	6526                	ld	a0,72(sp)
    80006056:	65c6                	ld	a1,80(sp)
    80006058:	6666                	ld	a2,88(sp)
    8000605a:	7686                	ld	a3,96(sp)
    8000605c:	7726                	ld	a4,104(sp)
    8000605e:	77c6                	ld	a5,112(sp)
    80006060:	7866                	ld	a6,120(sp)
    80006062:	688a                	ld	a7,128(sp)
    80006064:	692a                	ld	s2,136(sp)
    80006066:	69ca                	ld	s3,144(sp)
    80006068:	6a6a                	ld	s4,152(sp)
    8000606a:	7a8a                	ld	s5,160(sp)
    8000606c:	7b2a                	ld	s6,168(sp)
    8000606e:	7bca                	ld	s7,176(sp)
    80006070:	7c6a                	ld	s8,184(sp)
    80006072:	6c8e                	ld	s9,192(sp)
    80006074:	6d2e                	ld	s10,200(sp)
    80006076:	6dce                	ld	s11,208(sp)
    80006078:	6e6e                	ld	t3,216(sp)
    8000607a:	7e8e                	ld	t4,224(sp)
    8000607c:	7f2e                	ld	t5,232(sp)
    8000607e:	7fce                	ld	t6,240(sp)
    80006080:	6111                	addi	sp,sp,256
    80006082:	10200073          	sret
    80006086:	00000013          	nop
    8000608a:	00000013          	nop
    8000608e:	0001                	nop

0000000080006090 <timervec>:
    80006090:	34051573          	csrrw	a0,mscratch,a0
    80006094:	e10c                	sd	a1,0(a0)
    80006096:	e510                	sd	a2,8(a0)
    80006098:	e914                	sd	a3,16(a0)
    8000609a:	6d0c                	ld	a1,24(a0)
    8000609c:	7110                	ld	a2,32(a0)
    8000609e:	6194                	ld	a3,0(a1)
    800060a0:	96b2                	add	a3,a3,a2
    800060a2:	e194                	sd	a3,0(a1)
    800060a4:	4589                	li	a1,2
    800060a6:	14459073          	csrw	sip,a1
    800060aa:	6914                	ld	a3,16(a0)
    800060ac:	6510                	ld	a2,8(a0)
    800060ae:	610c                	ld	a1,0(a0)
    800060b0:	34051573          	csrrw	a0,mscratch,a0
    800060b4:	30200073          	mret
	...

00000000800060ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800060ba:	1141                	addi	sp,sp,-16
    800060bc:	e422                	sd	s0,8(sp)
    800060be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800060c0:	0c0007b7          	lui	a5,0xc000
    800060c4:	4705                	li	a4,1
    800060c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800060c8:	c3d8                	sw	a4,4(a5)
}
    800060ca:	6422                	ld	s0,8(sp)
    800060cc:	0141                	addi	sp,sp,16
    800060ce:	8082                	ret

00000000800060d0 <plicinithart>:

void
plicinithart(void)
{
    800060d0:	1141                	addi	sp,sp,-16
    800060d2:	e406                	sd	ra,8(sp)
    800060d4:	e022                	sd	s0,0(sp)
    800060d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800060d8:	ffffc097          	auipc	ra,0xffffc
    800060dc:	8a8080e7          	jalr	-1880(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800060e0:	0085171b          	slliw	a4,a0,0x8
    800060e4:	0c0027b7          	lui	a5,0xc002
    800060e8:	97ba                	add	a5,a5,a4
    800060ea:	40200713          	li	a4,1026
    800060ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800060f2:	00d5151b          	slliw	a0,a0,0xd
    800060f6:	0c2017b7          	lui	a5,0xc201
    800060fa:	97aa                	add	a5,a5,a0
    800060fc:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006100:	60a2                	ld	ra,8(sp)
    80006102:	6402                	ld	s0,0(sp)
    80006104:	0141                	addi	sp,sp,16
    80006106:	8082                	ret

0000000080006108 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006108:	1141                	addi	sp,sp,-16
    8000610a:	e406                	sd	ra,8(sp)
    8000610c:	e022                	sd	s0,0(sp)
    8000610e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006110:	ffffc097          	auipc	ra,0xffffc
    80006114:	870080e7          	jalr	-1936(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006118:	00d5151b          	slliw	a0,a0,0xd
    8000611c:	0c2017b7          	lui	a5,0xc201
    80006120:	97aa                	add	a5,a5,a0
  return irq;
}
    80006122:	43c8                	lw	a0,4(a5)
    80006124:	60a2                	ld	ra,8(sp)
    80006126:	6402                	ld	s0,0(sp)
    80006128:	0141                	addi	sp,sp,16
    8000612a:	8082                	ret

000000008000612c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000612c:	1101                	addi	sp,sp,-32
    8000612e:	ec06                	sd	ra,24(sp)
    80006130:	e822                	sd	s0,16(sp)
    80006132:	e426                	sd	s1,8(sp)
    80006134:	1000                	addi	s0,sp,32
    80006136:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006138:	ffffc097          	auipc	ra,0xffffc
    8000613c:	848080e7          	jalr	-1976(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006140:	00d5151b          	slliw	a0,a0,0xd
    80006144:	0c2017b7          	lui	a5,0xc201
    80006148:	97aa                	add	a5,a5,a0
    8000614a:	c3c4                	sw	s1,4(a5)
}
    8000614c:	60e2                	ld	ra,24(sp)
    8000614e:	6442                	ld	s0,16(sp)
    80006150:	64a2                	ld	s1,8(sp)
    80006152:	6105                	addi	sp,sp,32
    80006154:	8082                	ret

0000000080006156 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006156:	1141                	addi	sp,sp,-16
    80006158:	e406                	sd	ra,8(sp)
    8000615a:	e022                	sd	s0,0(sp)
    8000615c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000615e:	479d                	li	a5,7
    80006160:	04a7cc63          	blt	a5,a0,800061b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006164:	0001c797          	auipc	a5,0x1c
    80006168:	4dc78793          	addi	a5,a5,1244 # 80022640 <disk>
    8000616c:	97aa                	add	a5,a5,a0
    8000616e:	0187c783          	lbu	a5,24(a5)
    80006172:	ebb9                	bnez	a5,800061c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006174:	00451693          	slli	a3,a0,0x4
    80006178:	0001c797          	auipc	a5,0x1c
    8000617c:	4c878793          	addi	a5,a5,1224 # 80022640 <disk>
    80006180:	6398                	ld	a4,0(a5)
    80006182:	9736                	add	a4,a4,a3
    80006184:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006188:	6398                	ld	a4,0(a5)
    8000618a:	9736                	add	a4,a4,a3
    8000618c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006190:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006194:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006198:	97aa                	add	a5,a5,a0
    8000619a:	4705                	li	a4,1
    8000619c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    800061a0:	0001c517          	auipc	a0,0x1c
    800061a4:	4b850513          	addi	a0,a0,1208 # 80022658 <disk+0x18>
    800061a8:	ffffc097          	auipc	ra,0xffffc
    800061ac:	07e080e7          	jalr	126(ra) # 80002226 <wakeup>
}
    800061b0:	60a2                	ld	ra,8(sp)
    800061b2:	6402                	ld	s0,0(sp)
    800061b4:	0141                	addi	sp,sp,16
    800061b6:	8082                	ret
    panic("free_desc 1");
    800061b8:	00002517          	auipc	a0,0x2
    800061bc:	5a850513          	addi	a0,a0,1448 # 80008760 <syscalls+0x308>
    800061c0:	ffffa097          	auipc	ra,0xffffa
    800061c4:	380080e7          	jalr	896(ra) # 80000540 <panic>
    panic("free_desc 2");
    800061c8:	00002517          	auipc	a0,0x2
    800061cc:	5a850513          	addi	a0,a0,1448 # 80008770 <syscalls+0x318>
    800061d0:	ffffa097          	auipc	ra,0xffffa
    800061d4:	370080e7          	jalr	880(ra) # 80000540 <panic>

00000000800061d8 <virtio_disk_init>:
{
    800061d8:	1101                	addi	sp,sp,-32
    800061da:	ec06                	sd	ra,24(sp)
    800061dc:	e822                	sd	s0,16(sp)
    800061de:	e426                	sd	s1,8(sp)
    800061e0:	e04a                	sd	s2,0(sp)
    800061e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800061e4:	00002597          	auipc	a1,0x2
    800061e8:	59c58593          	addi	a1,a1,1436 # 80008780 <syscalls+0x328>
    800061ec:	0001c517          	auipc	a0,0x1c
    800061f0:	57c50513          	addi	a0,a0,1404 # 80022768 <disk+0x128>
    800061f4:	ffffb097          	auipc	ra,0xffffb
    800061f8:	952080e7          	jalr	-1710(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800061fc:	100017b7          	lui	a5,0x10001
    80006200:	4398                	lw	a4,0(a5)
    80006202:	2701                	sext.w	a4,a4
    80006204:	747277b7          	lui	a5,0x74727
    80006208:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000620c:	14f71b63          	bne	a4,a5,80006362 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006210:	100017b7          	lui	a5,0x10001
    80006214:	43dc                	lw	a5,4(a5)
    80006216:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006218:	4709                	li	a4,2
    8000621a:	14e79463          	bne	a5,a4,80006362 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000621e:	100017b7          	lui	a5,0x10001
    80006222:	479c                	lw	a5,8(a5)
    80006224:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006226:	12e79e63          	bne	a5,a4,80006362 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    8000622a:	100017b7          	lui	a5,0x10001
    8000622e:	47d8                	lw	a4,12(a5)
    80006230:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006232:	554d47b7          	lui	a5,0x554d4
    80006236:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    8000623a:	12f71463          	bne	a4,a5,80006362 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    8000623e:	100017b7          	lui	a5,0x10001
    80006242:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006246:	4705                	li	a4,1
    80006248:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000624a:	470d                	li	a4,3
    8000624c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    8000624e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006250:	c7ffe6b7          	lui	a3,0xc7ffe
    80006254:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdbfdf>
    80006258:	8f75                	and	a4,a4,a3
    8000625a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    8000625c:	472d                	li	a4,11
    8000625e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006260:	5bbc                	lw	a5,112(a5)
    80006262:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006266:	8ba1                	andi	a5,a5,8
    80006268:	10078563          	beqz	a5,80006372 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    8000626c:	100017b7          	lui	a5,0x10001
    80006270:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006274:	43fc                	lw	a5,68(a5)
    80006276:	2781                	sext.w	a5,a5
    80006278:	10079563          	bnez	a5,80006382 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000627c:	100017b7          	lui	a5,0x10001
    80006280:	5bdc                	lw	a5,52(a5)
    80006282:	2781                	sext.w	a5,a5
  if(max == 0)
    80006284:	10078763          	beqz	a5,80006392 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006288:	471d                	li	a4,7
    8000628a:	10f77c63          	bgeu	a4,a5,800063a2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000628e:	ffffb097          	auipc	ra,0xffffb
    80006292:	858080e7          	jalr	-1960(ra) # 80000ae6 <kalloc>
    80006296:	0001c497          	auipc	s1,0x1c
    8000629a:	3aa48493          	addi	s1,s1,938 # 80022640 <disk>
    8000629e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    800062a0:	ffffb097          	auipc	ra,0xffffb
    800062a4:	846080e7          	jalr	-1978(ra) # 80000ae6 <kalloc>
    800062a8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    800062aa:	ffffb097          	auipc	ra,0xffffb
    800062ae:	83c080e7          	jalr	-1988(ra) # 80000ae6 <kalloc>
    800062b2:	87aa                	mv	a5,a0
    800062b4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    800062b6:	6088                	ld	a0,0(s1)
    800062b8:	cd6d                	beqz	a0,800063b2 <virtio_disk_init+0x1da>
    800062ba:	0001c717          	auipc	a4,0x1c
    800062be:	38e73703          	ld	a4,910(a4) # 80022648 <disk+0x8>
    800062c2:	cb65                	beqz	a4,800063b2 <virtio_disk_init+0x1da>
    800062c4:	c7fd                	beqz	a5,800063b2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    800062c6:	6605                	lui	a2,0x1
    800062c8:	4581                	li	a1,0
    800062ca:	ffffb097          	auipc	ra,0xffffb
    800062ce:	a08080e7          	jalr	-1528(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    800062d2:	0001c497          	auipc	s1,0x1c
    800062d6:	36e48493          	addi	s1,s1,878 # 80022640 <disk>
    800062da:	6605                	lui	a2,0x1
    800062dc:	4581                	li	a1,0
    800062de:	6488                	ld	a0,8(s1)
    800062e0:	ffffb097          	auipc	ra,0xffffb
    800062e4:	9f2080e7          	jalr	-1550(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    800062e8:	6605                	lui	a2,0x1
    800062ea:	4581                	li	a1,0
    800062ec:	6888                	ld	a0,16(s1)
    800062ee:	ffffb097          	auipc	ra,0xffffb
    800062f2:	9e4080e7          	jalr	-1564(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800062f6:	100017b7          	lui	a5,0x10001
    800062fa:	4721                	li	a4,8
    800062fc:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    800062fe:	4098                	lw	a4,0(s1)
    80006300:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006304:	40d8                	lw	a4,4(s1)
    80006306:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000630a:	6498                	ld	a4,8(s1)
    8000630c:	0007069b          	sext.w	a3,a4
    80006310:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006314:	9701                	srai	a4,a4,0x20
    80006316:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    8000631a:	6898                	ld	a4,16(s1)
    8000631c:	0007069b          	sext.w	a3,a4
    80006320:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006324:	9701                	srai	a4,a4,0x20
    80006326:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    8000632a:	4705                	li	a4,1
    8000632c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    8000632e:	00e48c23          	sb	a4,24(s1)
    80006332:	00e48ca3          	sb	a4,25(s1)
    80006336:	00e48d23          	sb	a4,26(s1)
    8000633a:	00e48da3          	sb	a4,27(s1)
    8000633e:	00e48e23          	sb	a4,28(s1)
    80006342:	00e48ea3          	sb	a4,29(s1)
    80006346:	00e48f23          	sb	a4,30(s1)
    8000634a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    8000634e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006352:	0727a823          	sw	s2,112(a5)
}
    80006356:	60e2                	ld	ra,24(sp)
    80006358:	6442                	ld	s0,16(sp)
    8000635a:	64a2                	ld	s1,8(sp)
    8000635c:	6902                	ld	s2,0(sp)
    8000635e:	6105                	addi	sp,sp,32
    80006360:	8082                	ret
    panic("could not find virtio disk");
    80006362:	00002517          	auipc	a0,0x2
    80006366:	42e50513          	addi	a0,a0,1070 # 80008790 <syscalls+0x338>
    8000636a:	ffffa097          	auipc	ra,0xffffa
    8000636e:	1d6080e7          	jalr	470(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006372:	00002517          	auipc	a0,0x2
    80006376:	43e50513          	addi	a0,a0,1086 # 800087b0 <syscalls+0x358>
    8000637a:	ffffa097          	auipc	ra,0xffffa
    8000637e:	1c6080e7          	jalr	454(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006382:	00002517          	auipc	a0,0x2
    80006386:	44e50513          	addi	a0,a0,1102 # 800087d0 <syscalls+0x378>
    8000638a:	ffffa097          	auipc	ra,0xffffa
    8000638e:	1b6080e7          	jalr	438(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006392:	00002517          	auipc	a0,0x2
    80006396:	45e50513          	addi	a0,a0,1118 # 800087f0 <syscalls+0x398>
    8000639a:	ffffa097          	auipc	ra,0xffffa
    8000639e:	1a6080e7          	jalr	422(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    800063a2:	00002517          	auipc	a0,0x2
    800063a6:	46e50513          	addi	a0,a0,1134 # 80008810 <syscalls+0x3b8>
    800063aa:	ffffa097          	auipc	ra,0xffffa
    800063ae:	196080e7          	jalr	406(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    800063b2:	00002517          	auipc	a0,0x2
    800063b6:	47e50513          	addi	a0,a0,1150 # 80008830 <syscalls+0x3d8>
    800063ba:	ffffa097          	auipc	ra,0xffffa
    800063be:	186080e7          	jalr	390(ra) # 80000540 <panic>

00000000800063c2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    800063c2:	7119                	addi	sp,sp,-128
    800063c4:	fc86                	sd	ra,120(sp)
    800063c6:	f8a2                	sd	s0,112(sp)
    800063c8:	f4a6                	sd	s1,104(sp)
    800063ca:	f0ca                	sd	s2,96(sp)
    800063cc:	ecce                	sd	s3,88(sp)
    800063ce:	e8d2                	sd	s4,80(sp)
    800063d0:	e4d6                	sd	s5,72(sp)
    800063d2:	e0da                	sd	s6,64(sp)
    800063d4:	fc5e                	sd	s7,56(sp)
    800063d6:	f862                	sd	s8,48(sp)
    800063d8:	f466                	sd	s9,40(sp)
    800063da:	f06a                	sd	s10,32(sp)
    800063dc:	ec6e                	sd	s11,24(sp)
    800063de:	0100                	addi	s0,sp,128
    800063e0:	8aaa                	mv	s5,a0
    800063e2:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    800063e4:	00c52d03          	lw	s10,12(a0)
    800063e8:	001d1d1b          	slliw	s10,s10,0x1
    800063ec:	1d02                	slli	s10,s10,0x20
    800063ee:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    800063f2:	0001c517          	auipc	a0,0x1c
    800063f6:	37650513          	addi	a0,a0,886 # 80022768 <disk+0x128>
    800063fa:	ffffa097          	auipc	ra,0xffffa
    800063fe:	7dc080e7          	jalr	2012(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006402:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006404:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006406:	0001cb97          	auipc	s7,0x1c
    8000640a:	23ab8b93          	addi	s7,s7,570 # 80022640 <disk>
  for(int i = 0; i < 3; i++){
    8000640e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006410:	0001cc97          	auipc	s9,0x1c
    80006414:	358c8c93          	addi	s9,s9,856 # 80022768 <disk+0x128>
    80006418:	a08d                	j	8000647a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000641a:	00fb8733          	add	a4,s7,a5
    8000641e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006422:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006424:	0207c563          	bltz	a5,8000644e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006428:	2905                	addiw	s2,s2,1
    8000642a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000642c:	05690c63          	beq	s2,s6,80006484 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006430:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006432:	0001c717          	auipc	a4,0x1c
    80006436:	20e70713          	addi	a4,a4,526 # 80022640 <disk>
    8000643a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000643c:	01874683          	lbu	a3,24(a4)
    80006440:	fee9                	bnez	a3,8000641a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006442:	2785                	addiw	a5,a5,1
    80006444:	0705                	addi	a4,a4,1
    80006446:	fe979be3          	bne	a5,s1,8000643c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    8000644a:	57fd                	li	a5,-1
    8000644c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    8000644e:	01205d63          	blez	s2,80006468 <virtio_disk_rw+0xa6>
    80006452:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006454:	000a2503          	lw	a0,0(s4)
    80006458:	00000097          	auipc	ra,0x0
    8000645c:	cfe080e7          	jalr	-770(ra) # 80006156 <free_desc>
      for(int j = 0; j < i; j++)
    80006460:	2d85                	addiw	s11,s11,1
    80006462:	0a11                	addi	s4,s4,4
    80006464:	ff2d98e3          	bne	s11,s2,80006454 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006468:	85e6                	mv	a1,s9
    8000646a:	0001c517          	auipc	a0,0x1c
    8000646e:	1ee50513          	addi	a0,a0,494 # 80022658 <disk+0x18>
    80006472:	ffffc097          	auipc	ra,0xffffc
    80006476:	d50080e7          	jalr	-688(ra) # 800021c2 <sleep>
  for(int i = 0; i < 3; i++){
    8000647a:	f8040a13          	addi	s4,s0,-128
{
    8000647e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006480:	894e                	mv	s2,s3
    80006482:	b77d                	j	80006430 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006484:	f8042503          	lw	a0,-128(s0)
    80006488:	00a50713          	addi	a4,a0,10
    8000648c:	0712                	slli	a4,a4,0x4

  if(write)
    8000648e:	0001c797          	auipc	a5,0x1c
    80006492:	1b278793          	addi	a5,a5,434 # 80022640 <disk>
    80006496:	00e786b3          	add	a3,a5,a4
    8000649a:	01803633          	snez	a2,s8
    8000649e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    800064a0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    800064a4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    800064a8:	f6070613          	addi	a2,a4,-160
    800064ac:	6394                	ld	a3,0(a5)
    800064ae:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800064b0:	00870593          	addi	a1,a4,8
    800064b4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    800064b6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    800064b8:	0007b803          	ld	a6,0(a5)
    800064bc:	9642                	add	a2,a2,a6
    800064be:	46c1                	li	a3,16
    800064c0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    800064c2:	4585                	li	a1,1
    800064c4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    800064c8:	f8442683          	lw	a3,-124(s0)
    800064cc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    800064d0:	0692                	slli	a3,a3,0x4
    800064d2:	9836                	add	a6,a6,a3
    800064d4:	058a8613          	addi	a2,s5,88
    800064d8:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    800064dc:	0007b803          	ld	a6,0(a5)
    800064e0:	96c2                	add	a3,a3,a6
    800064e2:	40000613          	li	a2,1024
    800064e6:	c690                	sw	a2,8(a3)
  if(write)
    800064e8:	001c3613          	seqz	a2,s8
    800064ec:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800064f0:	00166613          	ori	a2,a2,1
    800064f4:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800064f8:	f8842603          	lw	a2,-120(s0)
    800064fc:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006500:	00250693          	addi	a3,a0,2
    80006504:	0692                	slli	a3,a3,0x4
    80006506:	96be                	add	a3,a3,a5
    80006508:	58fd                	li	a7,-1
    8000650a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000650e:	0612                	slli	a2,a2,0x4
    80006510:	9832                	add	a6,a6,a2
    80006512:	f9070713          	addi	a4,a4,-112
    80006516:	973e                	add	a4,a4,a5
    80006518:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000651c:	6398                	ld	a4,0(a5)
    8000651e:	9732                	add	a4,a4,a2
    80006520:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006522:	4609                	li	a2,2
    80006524:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006528:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000652c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006530:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006534:	6794                	ld	a3,8(a5)
    80006536:	0026d703          	lhu	a4,2(a3)
    8000653a:	8b1d                	andi	a4,a4,7
    8000653c:	0706                	slli	a4,a4,0x1
    8000653e:	96ba                	add	a3,a3,a4
    80006540:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80006544:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006548:	6798                	ld	a4,8(a5)
    8000654a:	00275783          	lhu	a5,2(a4)
    8000654e:	2785                	addiw	a5,a5,1
    80006550:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006554:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006558:	100017b7          	lui	a5,0x10001
    8000655c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006560:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80006564:	0001c917          	auipc	s2,0x1c
    80006568:	20490913          	addi	s2,s2,516 # 80022768 <disk+0x128>
  while(b->disk == 1) {
    8000656c:	4485                	li	s1,1
    8000656e:	00b79c63          	bne	a5,a1,80006586 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006572:	85ca                	mv	a1,s2
    80006574:	8556                	mv	a0,s5
    80006576:	ffffc097          	auipc	ra,0xffffc
    8000657a:	c4c080e7          	jalr	-948(ra) # 800021c2 <sleep>
  while(b->disk == 1) {
    8000657e:	004aa783          	lw	a5,4(s5)
    80006582:	fe9788e3          	beq	a5,s1,80006572 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006586:	f8042903          	lw	s2,-128(s0)
    8000658a:	00290713          	addi	a4,s2,2
    8000658e:	0712                	slli	a4,a4,0x4
    80006590:	0001c797          	auipc	a5,0x1c
    80006594:	0b078793          	addi	a5,a5,176 # 80022640 <disk>
    80006598:	97ba                	add	a5,a5,a4
    8000659a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000659e:	0001c997          	auipc	s3,0x1c
    800065a2:	0a298993          	addi	s3,s3,162 # 80022640 <disk>
    800065a6:	00491713          	slli	a4,s2,0x4
    800065aa:	0009b783          	ld	a5,0(s3)
    800065ae:	97ba                	add	a5,a5,a4
    800065b0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800065b4:	854a                	mv	a0,s2
    800065b6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800065ba:	00000097          	auipc	ra,0x0
    800065be:	b9c080e7          	jalr	-1124(ra) # 80006156 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800065c2:	8885                	andi	s1,s1,1
    800065c4:	f0ed                	bnez	s1,800065a6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800065c6:	0001c517          	auipc	a0,0x1c
    800065ca:	1a250513          	addi	a0,a0,418 # 80022768 <disk+0x128>
    800065ce:	ffffa097          	auipc	ra,0xffffa
    800065d2:	6bc080e7          	jalr	1724(ra) # 80000c8a <release>
}
    800065d6:	70e6                	ld	ra,120(sp)
    800065d8:	7446                	ld	s0,112(sp)
    800065da:	74a6                	ld	s1,104(sp)
    800065dc:	7906                	ld	s2,96(sp)
    800065de:	69e6                	ld	s3,88(sp)
    800065e0:	6a46                	ld	s4,80(sp)
    800065e2:	6aa6                	ld	s5,72(sp)
    800065e4:	6b06                	ld	s6,64(sp)
    800065e6:	7be2                	ld	s7,56(sp)
    800065e8:	7c42                	ld	s8,48(sp)
    800065ea:	7ca2                	ld	s9,40(sp)
    800065ec:	7d02                	ld	s10,32(sp)
    800065ee:	6de2                	ld	s11,24(sp)
    800065f0:	6109                	addi	sp,sp,128
    800065f2:	8082                	ret

00000000800065f4 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    800065f4:	1101                	addi	sp,sp,-32
    800065f6:	ec06                	sd	ra,24(sp)
    800065f8:	e822                	sd	s0,16(sp)
    800065fa:	e426                	sd	s1,8(sp)
    800065fc:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    800065fe:	0001c497          	auipc	s1,0x1c
    80006602:	04248493          	addi	s1,s1,66 # 80022640 <disk>
    80006606:	0001c517          	auipc	a0,0x1c
    8000660a:	16250513          	addi	a0,a0,354 # 80022768 <disk+0x128>
    8000660e:	ffffa097          	auipc	ra,0xffffa
    80006612:	5c8080e7          	jalr	1480(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006616:	10001737          	lui	a4,0x10001
    8000661a:	533c                	lw	a5,96(a4)
    8000661c:	8b8d                	andi	a5,a5,3
    8000661e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006620:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006624:	689c                	ld	a5,16(s1)
    80006626:	0204d703          	lhu	a4,32(s1)
    8000662a:	0027d783          	lhu	a5,2(a5)
    8000662e:	04f70863          	beq	a4,a5,8000667e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006632:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006636:	6898                	ld	a4,16(s1)
    80006638:	0204d783          	lhu	a5,32(s1)
    8000663c:	8b9d                	andi	a5,a5,7
    8000663e:	078e                	slli	a5,a5,0x3
    80006640:	97ba                	add	a5,a5,a4
    80006642:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006644:	00278713          	addi	a4,a5,2
    80006648:	0712                	slli	a4,a4,0x4
    8000664a:	9726                	add	a4,a4,s1
    8000664c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006650:	e721                	bnez	a4,80006698 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006652:	0789                	addi	a5,a5,2
    80006654:	0792                	slli	a5,a5,0x4
    80006656:	97a6                	add	a5,a5,s1
    80006658:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000665a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000665e:	ffffc097          	auipc	ra,0xffffc
    80006662:	bc8080e7          	jalr	-1080(ra) # 80002226 <wakeup>

    disk.used_idx += 1;
    80006666:	0204d783          	lhu	a5,32(s1)
    8000666a:	2785                	addiw	a5,a5,1
    8000666c:	17c2                	slli	a5,a5,0x30
    8000666e:	93c1                	srli	a5,a5,0x30
    80006670:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006674:	6898                	ld	a4,16(s1)
    80006676:	00275703          	lhu	a4,2(a4)
    8000667a:	faf71ce3          	bne	a4,a5,80006632 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000667e:	0001c517          	auipc	a0,0x1c
    80006682:	0ea50513          	addi	a0,a0,234 # 80022768 <disk+0x128>
    80006686:	ffffa097          	auipc	ra,0xffffa
    8000668a:	604080e7          	jalr	1540(ra) # 80000c8a <release>
}
    8000668e:	60e2                	ld	ra,24(sp)
    80006690:	6442                	ld	s0,16(sp)
    80006692:	64a2                	ld	s1,8(sp)
    80006694:	6105                	addi	sp,sp,32
    80006696:	8082                	ret
      panic("virtio_disk_intr status");
    80006698:	00002517          	auipc	a0,0x2
    8000669c:	1b050513          	addi	a0,a0,432 # 80008848 <syscalls+0x3f0>
    800066a0:	ffffa097          	auipc	ra,0xffffa
    800066a4:	ea0080e7          	jalr	-352(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
