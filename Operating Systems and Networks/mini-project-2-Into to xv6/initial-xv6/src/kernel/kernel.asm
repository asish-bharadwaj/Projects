
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	0000a117          	auipc	sp,0xa
    80000004:	8e013103          	ld	sp,-1824(sp) # 800098e0 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000050:	0000a717          	auipc	a4,0xa
    80000054:	8f070713          	addi	a4,a4,-1808 # 80009940 <timer_scratch>
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
    80000062:	00007797          	auipc	a5,0x7
    80000066:	b5e78793          	addi	a5,a5,-1186 # 80006bc0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffda23f>
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
    8000012a:	00003097          	auipc	ra,0x3
    8000012e:	fb6080e7          	jalr	-74(ra) # 800030e0 <either_copyin>
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
    8000018a:	00012517          	auipc	a0,0x12
    8000018e:	8f650513          	addi	a0,a0,-1802 # 80011a80 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00012497          	auipc	s1,0x12
    8000019e:	8e648493          	addi	s1,s1,-1818 # 80011a80 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00012917          	auipc	s2,0x12
    800001a6:	97690913          	addi	s2,s2,-1674 # 80011b18 <cons+0x98>
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
    800001c8:	00003097          	auipc	ra,0x3
    800001cc:	d62080e7          	jalr	-670(ra) # 80002f2a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00003097          	auipc	ra,0x3
    800001da:	aa0080e7          	jalr	-1376(ra) # 80002c76 <sleep>
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
    80000212:	00003097          	auipc	ra,0x3
    80000216:	e78080e7          	jalr	-392(ra) # 8000308a <either_copyout>
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
    80000226:	00012517          	auipc	a0,0x12
    8000022a:	85a50513          	addi	a0,a0,-1958 # 80011a80 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00012517          	auipc	a0,0x12
    80000240:	84450513          	addi	a0,a0,-1980 # 80011a80 <cons>
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
    80000272:	00012717          	auipc	a4,0x12
    80000276:	8af72323          	sw	a5,-1882(a4) # 80011b18 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	7b450513          	addi	a0,a0,1972 # 80011a80 <cons>
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
    800002f2:	00003097          	auipc	ra,0x3
    800002f6:	e44080e7          	jalr	-444(ra) # 80003136 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	78650513          	addi	a0,a0,1926 # 80011a80 <cons>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	76270713          	addi	a4,a4,1890 # 80011a80 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	73878793          	addi	a5,a5,1848 # 80011a80 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	7a27a783          	lw	a5,1954(a5) # 80011b18 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	6f670713          	addi	a4,a4,1782 # 80011a80 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	6e648493          	addi	s1,s1,1766 # 80011a80 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	6aa70713          	addi	a4,a4,1706 # 80011a80 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	72f72a23          	sw	a5,1844(a4) # 80011b20 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	66e78793          	addi	a5,a5,1646 # 80011a80 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	6ec7a323          	sw	a2,1766(a5) # 80011b1c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	6da50513          	addi	a0,a0,1754 # 80011b18 <cons+0x98>
    80000446:	00003097          	auipc	ra,0x3
    8000044a:	894080e7          	jalr	-1900(ra) # 80002cda <wakeup>
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
    80000458:	00009597          	auipc	a1,0x9
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80009010 <etext+0x10>
    80000460:	00011517          	auipc	a0,0x11
    80000464:	62050513          	addi	a0,a0,1568 # 80011a80 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00023797          	auipc	a5,0x23
    8000047c:	fb078793          	addi	a5,a5,-80 # 80023428 <devsw>
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
    800004ba:	00009617          	auipc	a2,0x9
    800004be:	b8660613          	addi	a2,a2,-1146 # 80009040 <digits>
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
    8000054c:	00011797          	auipc	a5,0x11
    80000550:	5e07aa23          	sw	zero,1524(a5) # 80011b40 <pr+0x18>
  printf("panic: ");
    80000554:	00009517          	auipc	a0,0x9
    80000558:	ac450513          	addi	a0,a0,-1340 # 80009018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00009517          	auipc	a0,0x9
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800090c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00009717          	auipc	a4,0x9
    80000584:	38f72023          	sw	a5,896(a4) # 80009900 <panicked>
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
    800005bc:	00011d97          	auipc	s11,0x11
    800005c0:	584dad83          	lw	s11,1412(s11) # 80011b40 <pr+0x18>
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
    800005e8:	00009b17          	auipc	s6,0x9
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80009040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00011517          	auipc	a0,0x11
    800005fe:	52e50513          	addi	a0,a0,1326 # 80011b28 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00009517          	auipc	a0,0x9
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80009028 <etext+0x28>
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
    80000706:	00009497          	auipc	s1,0x9
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80009020 <etext+0x20>
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
    80000758:	00011517          	auipc	a0,0x11
    8000075c:	3d050513          	addi	a0,a0,976 # 80011b28 <pr>
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
    80000774:	00011497          	auipc	s1,0x11
    80000778:	3b448493          	addi	s1,s1,948 # 80011b28 <pr>
    8000077c:	00009597          	auipc	a1,0x9
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80009038 <etext+0x38>
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
    800007cc:	00009597          	auipc	a1,0x9
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80009058 <digits+0x18>
    800007d4:	00011517          	auipc	a0,0x11
    800007d8:	37450513          	addi	a0,a0,884 # 80011b48 <uart_tx_lock>
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
    80000800:	00009797          	auipc	a5,0x9
    80000804:	1007a783          	lw	a5,256(a5) # 80009900 <panicked>
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
    80000838:	00009797          	auipc	a5,0x9
    8000083c:	0d07b783          	ld	a5,208(a5) # 80009908 <uart_tx_r>
    80000840:	00009717          	auipc	a4,0x9
    80000844:	0d073703          	ld	a4,208(a4) # 80009910 <uart_tx_w>
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
    80000862:	00011a17          	auipc	s4,0x11
    80000866:	2e6a0a13          	addi	s4,s4,742 # 80011b48 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00009497          	auipc	s1,0x9
    8000086e:	09e48493          	addi	s1,s1,158 # 80009908 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00009997          	auipc	s3,0x9
    80000876:	09e98993          	addi	s3,s3,158 # 80009910 <uart_tx_w>
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
    80000898:	446080e7          	jalr	1094(ra) # 80002cda <wakeup>
    
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
    800008d0:	00011517          	auipc	a0,0x11
    800008d4:	27850513          	addi	a0,a0,632 # 80011b48 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00009797          	auipc	a5,0x9
    800008e4:	0207a783          	lw	a5,32(a5) # 80009900 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00009717          	auipc	a4,0x9
    800008ee:	02673703          	ld	a4,38(a4) # 80009910 <uart_tx_w>
    800008f2:	00009797          	auipc	a5,0x9
    800008f6:	0167b783          	ld	a5,22(a5) # 80009908 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00011997          	auipc	s3,0x11
    80000902:	24a98993          	addi	s3,s3,586 # 80011b48 <uart_tx_lock>
    80000906:	00009497          	auipc	s1,0x9
    8000090a:	00248493          	addi	s1,s1,2 # 80009908 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00009917          	auipc	s2,0x9
    80000912:	00290913          	addi	s2,s2,2 # 80009910 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	358080e7          	jalr	856(ra) # 80002c76 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00011497          	auipc	s1,0x11
    80000938:	21448493          	addi	s1,s1,532 # 80011b48 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00009797          	auipc	a5,0x9
    8000094c:	fce7b423          	sd	a4,-56(a5) # 80009910 <uart_tx_w>
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
    800009ba:	00011497          	auipc	s1,0x11
    800009be:	18e48493          	addi	s1,s1,398 # 80011b48 <uart_tx_lock>
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
    800009fc:	00024797          	auipc	a5,0x24
    80000a00:	bc478793          	addi	a5,a5,-1084 # 800245c0 <end>
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
    80000a1c:	00011917          	auipc	s2,0x11
    80000a20:	16490913          	addi	s2,s2,356 # 80011b80 <kmem>
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
    80000a4e:	00008517          	auipc	a0,0x8
    80000a52:	61250513          	addi	a0,a0,1554 # 80009060 <digits+0x20>
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
    80000ab2:	00008597          	auipc	a1,0x8
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80009068 <digits+0x28>
    80000aba:	00011517          	auipc	a0,0x11
    80000abe:	0c650513          	addi	a0,a0,198 # 80011b80 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00024517          	auipc	a0,0x24
    80000ad2:	af250513          	addi	a0,a0,-1294 # 800245c0 <end>
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
    80000af0:	00011497          	auipc	s1,0x11
    80000af4:	09048493          	addi	s1,s1,144 # 80011b80 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00011517          	auipc	a0,0x11
    80000b0c:	07850513          	addi	a0,a0,120 # 80011b80 <kmem>
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
    80000b34:	00011517          	auipc	a0,0x11
    80000b38:	04c50513          	addi	a0,a0,76 # 80011b80 <kmem>
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
    80000c1a:	00008517          	auipc	a0,0x8
    80000c1e:	45650513          	addi	a0,a0,1110 # 80009070 <digits+0x30>
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
    80000c6a:	00008517          	auipc	a0,0x8
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80009078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00008517          	auipc	a0,0x8
    80000c7e:	41650513          	addi	a0,a0,1046 # 80009090 <digits+0x50>
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
    80000cc2:	00008517          	auipc	a0,0x8
    80000cc6:	3d650513          	addi	a0,a0,982 # 80009098 <digits+0x58>
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
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdaa41>
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
    80000e88:	00009717          	auipc	a4,0x9
    80000e8c:	a9070713          	addi	a4,a4,-1392 # 80009918 <started>
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
    80000ea6:	00008517          	auipc	a0,0x8
    80000eaa:	21250513          	addi	a0,a0,530 # 800090b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	564080e7          	jalr	1380(ra) # 80003422 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00006097          	auipc	ra,0x6
    80000eca:	d3a080e7          	jalr	-710(ra) # 80006c00 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	036080e7          	jalr	54(ra) # 80001f04 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00008517          	auipc	a0,0x8
    80000eea:	1e250513          	addi	a0,a0,482 # 800090c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00008517          	auipc	a0,0x8
    80000efa:	1aa50513          	addi	a0,a0,426 # 800090a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00008517          	auipc	a0,0x8
    80000f0a:	1c250513          	addi	a0,a0,450 # 800090c8 <digits+0x88>
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
    80000f3a:	4c4080e7          	jalr	1220(ra) # 800033fa <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	4e4080e7          	jalr	1252(ra) # 80003422 <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00006097          	auipc	ra,0x6
    80000f4a:	ca4080e7          	jalr	-860(ra) # 80006bea <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00006097          	auipc	ra,0x6
    80000f52:	cb2080e7          	jalr	-846(ra) # 80006c00 <plicinithart>
    binit();         // buffer cache
    80000f56:	00003097          	auipc	ra,0x3
    80000f5a:	e3a080e7          	jalr	-454(ra) # 80003d90 <binit>
    iinit();         // inode table
    80000f5e:	00003097          	auipc	ra,0x3
    80000f62:	4da080e7          	jalr	1242(ra) # 80004438 <iinit>
    fileinit();      // file table
    80000f66:	00004097          	auipc	ra,0x4
    80000f6a:	480080e7          	jalr	1152(ra) # 800053e6 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00006097          	auipc	ra,0x6
    80000f72:	d9a080e7          	jalr	-614(ra) # 80006d08 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d70080e7          	jalr	-656(ra) # 80001ce6 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00009717          	auipc	a4,0x9
    80000f88:	98f72a23          	sw	a5,-1644(a4) # 80009918 <started>
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
    80000f98:	00009797          	auipc	a5,0x9
    80000f9c:	9887b783          	ld	a5,-1656(a5) # 80009920 <kernel_pagetable>
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
    80000fdc:	00008517          	auipc	a0,0x8
    80000fe0:	0f450513          	addi	a0,a0,244 # 800090d0 <digits+0x90>
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
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdaa37>
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
    80001102:	00008517          	auipc	a0,0x8
    80001106:	fd650513          	addi	a0,a0,-42 # 800090d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00008517          	auipc	a0,0x8
    80001116:	fd650513          	addi	a0,a0,-42 # 800090e8 <digits+0xa8>
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
    8000115e:	00008517          	auipc	a0,0x8
    80001162:	f9a50513          	addi	a0,a0,-102 # 800090f8 <digits+0xb8>
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
    800011d4:	00008917          	auipc	s2,0x8
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80009000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80008697          	auipc	a3,0x80008
    800011e2:	e2268693          	addi	a3,a3,-478 # 9000 <_entry-0x7fff7000>
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
    80001212:	00007617          	auipc	a2,0x7
    80001216:	dee60613          	addi	a2,a2,-530 # 80008000 <_trampoline>
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
    80001254:	00008797          	auipc	a5,0x8
    80001258:	6ca7b623          	sd	a0,1740(a5) # 80009920 <kernel_pagetable>
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
    800012aa:	00008517          	auipc	a0,0x8
    800012ae:	e5650513          	addi	a0,a0,-426 # 80009100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00008517          	auipc	a0,0x8
    800012be:	e5e50513          	addi	a0,a0,-418 # 80009118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00008517          	auipc	a0,0x8
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80009128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00008517          	auipc	a0,0x8
    800012de:	e6650513          	addi	a0,a0,-410 # 80009140 <digits+0x100>
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
    800013b8:	00008517          	auipc	a0,0x8
    800013bc:	da050513          	addi	a0,a0,-608 # 80009158 <digits+0x118>
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
    80001504:	00008517          	auipc	a0,0x8
    80001508:	c7450513          	addi	a0,a0,-908 # 80009178 <digits+0x138>
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
    800015e2:	00008517          	auipc	a0,0x8
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80009188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00008517          	auipc	a0,0x8
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800091a8 <digits+0x168>
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
    8000165c:	00008517          	auipc	a0,0x8
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800091c8 <digits+0x188>
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
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdaa40>
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
    8000184c:	00011497          	auipc	s1,0x11
    80001850:	f9448493          	addi	s1,s1,-108 # 800127e0 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00007a97          	auipc	s5,0x7
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80009000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001866:	00018a17          	auipc	s4,0x18
    8000186a:	97aa0a13          	addi	s4,s4,-1670 # 800191e0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if (pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	858d                	srai	a1,a1,0x3
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
    800018a0:	1a848493          	addi	s1,s1,424
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
    800018bc:	00008517          	auipc	a0,0x8
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800091d8 <digits+0x198>
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
    800018e0:	00008597          	auipc	a1,0x8
    800018e4:	90058593          	addi	a1,a1,-1792 # 800091e0 <digits+0x1a0>
    800018e8:	00010517          	auipc	a0,0x10
    800018ec:	2b850513          	addi	a0,a0,696 # 80011ba0 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00008597          	auipc	a1,0x8
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800091e8 <digits+0x1a8>
    80001900:	00010517          	auipc	a0,0x10
    80001904:	2b850513          	addi	a0,a0,696 # 80011bb8 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001910:	00011497          	auipc	s1,0x11
    80001914:	ed048493          	addi	s1,s1,-304 # 800127e0 <proc>
  {
    initlock(&p->lock, "proc");
    80001918:	00008b17          	auipc	s6,0x8
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800091f8 <digits+0x1b8>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00007a17          	auipc	s4,0x7
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80009000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001932:	00018997          	auipc	s3,0x18
    80001936:	8ae98993          	addi	s3,s3,-1874 # 800191e0 <tickslock>
    initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
    p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	878d                	srai	a5,a5,0x3
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e0bc                	sd	a5,64(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001964:	1a848493          	addi	s1,s1,424
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
    8000199c:	00010517          	auipc	a0,0x10
    800019a0:	23450513          	addi	a0,a0,564 # 80011bd0 <cpus>
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
    800019c4:	00010717          	auipc	a4,0x10
    800019c8:	1dc70713          	addi	a4,a4,476 # 80011ba0 <pid_lock>
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
    800019fc:	00008797          	auipc	a5,0x8
    80001a00:	e947a783          	lw	a5,-364(a5) # 80009890 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00002097          	auipc	ra,0x2
    80001a0a:	a34080e7          	jalr	-1484(ra) # 8000343a <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00008797          	auipc	a5,0x8
    80001a1a:	e607ad23          	sw	zero,-390(a5) # 80009890 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00003097          	auipc	ra,0x3
    80001a24:	998080e7          	jalr	-1640(ra) # 800043b8 <fsinit>
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
    80001a36:	00010917          	auipc	s2,0x10
    80001a3a:	16a90913          	addi	s2,s2,362 # 80011ba0 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00008797          	auipc	a5,0x8
    80001a4c:	e4c78793          	addi	a5,a5,-436 # 80009894 <nextpid>
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
    80001a8c:	00006697          	auipc	a3,0x6
    80001a90:	57468693          	addi	a3,a3,1396 # 80008000 <_trampoline>
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
  p->rtime = -1;
    80001bac:	57fd                	li	a5,-1
    80001bae:	16f4a423          	sw	a5,360(s1)
  p->ctime = -1;
    80001bb2:	16f4a623          	sw	a5,364(s1)
  p->etime = -1;
    80001bb6:	16f4a823          	sw	a5,368(s1)
  p->handler = -1;
    80001bba:	16f4bc23          	sd	a5,376(s1)
  p->interval_ticks = -1;
    80001bbe:	18f4a023          	sw	a5,384(s1)
}
    80001bc2:	60e2                	ld	ra,24(sp)
    80001bc4:	6442                	ld	s0,16(sp)
    80001bc6:	64a2                	ld	s1,8(sp)
    80001bc8:	6105                	addi	sp,sp,32
    80001bca:	8082                	ret

0000000080001bcc <allocproc>:
{
    80001bcc:	1101                	addi	sp,sp,-32
    80001bce:	ec06                	sd	ra,24(sp)
    80001bd0:	e822                	sd	s0,16(sp)
    80001bd2:	e426                	sd	s1,8(sp)
    80001bd4:	e04a                	sd	s2,0(sp)
    80001bd6:	1000                	addi	s0,sp,32
  for (p = proc; p < &proc[NPROC]; p++)
    80001bd8:	00011497          	auipc	s1,0x11
    80001bdc:	c0848493          	addi	s1,s1,-1016 # 800127e0 <proc>
    80001be0:	00017917          	auipc	s2,0x17
    80001be4:	60090913          	addi	s2,s2,1536 # 800191e0 <tickslock>
    acquire(&p->lock);
    80001be8:	8526                	mv	a0,s1
    80001bea:	fffff097          	auipc	ra,0xfffff
    80001bee:	fec080e7          	jalr	-20(ra) # 80000bd6 <acquire>
    if (p->state == UNUSED)
    80001bf2:	4c9c                	lw	a5,24(s1)
    80001bf4:	cf81                	beqz	a5,80001c0c <allocproc+0x40>
      release(&p->lock);
    80001bf6:	8526                	mv	a0,s1
    80001bf8:	fffff097          	auipc	ra,0xfffff
    80001bfc:	092080e7          	jalr	146(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c00:	1a848493          	addi	s1,s1,424
    80001c04:	ff2492e3          	bne	s1,s2,80001be8 <allocproc+0x1c>
  return 0;
    80001c08:	4481                	li	s1,0
    80001c0a:	a879                	j	80001ca8 <allocproc+0xdc>
  p->pid = allocpid();
    80001c0c:	00000097          	auipc	ra,0x0
    80001c10:	e1e080e7          	jalr	-482(ra) # 80001a2a <allocpid>
    80001c14:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c16:	4785                	li	a5,1
    80001c18:	cc9c                	sw	a5,24(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    80001c1a:	fffff097          	auipc	ra,0xfffff
    80001c1e:	ecc080e7          	jalr	-308(ra) # 80000ae6 <kalloc>
    80001c22:	892a                	mv	s2,a0
    80001c24:	eca8                	sd	a0,88(s1)
    80001c26:	c941                	beqz	a0,80001cb6 <allocproc+0xea>
  p->pagetable = proc_pagetable(p);
    80001c28:	8526                	mv	a0,s1
    80001c2a:	00000097          	auipc	ra,0x0
    80001c2e:	e46080e7          	jalr	-442(ra) # 80001a70 <proc_pagetable>
    80001c32:	892a                	mv	s2,a0
    80001c34:	e8a8                	sd	a0,80(s1)
  if (p->pagetable == 0)
    80001c36:	cd41                	beqz	a0,80001cce <allocproc+0x102>
  memset(&p->context, 0, sizeof(p->context));
    80001c38:	07000613          	li	a2,112
    80001c3c:	4581                	li	a1,0
    80001c3e:	06048513          	addi	a0,s1,96
    80001c42:	fffff097          	auipc	ra,0xfffff
    80001c46:	090080e7          	jalr	144(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c4a:	00000797          	auipc	a5,0x0
    80001c4e:	d9a78793          	addi	a5,a5,-614 # 800019e4 <forkret>
    80001c52:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c54:	60bc                	ld	a5,64(s1)
    80001c56:	6705                	lui	a4,0x1
    80001c58:	97ba                	add	a5,a5,a4
    80001c5a:	f4bc                	sd	a5,104(s1)
  p->rtime = 0;
    80001c5c:	1604a423          	sw	zero,360(s1)
  p->etime = 0;
    80001c60:	1604a823          	sw	zero,368(s1)
  p->ctime = ticks;
    80001c64:	00008797          	auipc	a5,0x8
    80001c68:	ccc7a783          	lw	a5,-820(a5) # 80009930 <ticks>
    80001c6c:	16f4a623          	sw	a5,364(s1)
  p->alarm_on = 1;
    80001c70:	4785                	li	a5,1
    80001c72:	18f4a823          	sw	a5,400(s1)
  p->atime = 0;
    80001c76:	1804aa23          	sw	zero,404(s1)
  p->priority = 0;
    80001c7a:	1804ac23          	sw	zero,408(s1)
  p->clk_int = 0;
    80001c7e:	1804ae23          	sw	zero,412(s1)
  p->vol_exit = 0;
    80001c82:	1a04a223          	sw	zero,420(s1)
  PQ[0][pq[0]++] = p;
    80001c86:	00010717          	auipc	a4,0x10
    80001c8a:	f1a70713          	addi	a4,a4,-230 # 80011ba0 <pid_lock>
    80001c8e:	43072783          	lw	a5,1072(a4)
    80001c92:	0017869b          	addiw	a3,a5,1
    80001c96:	42d72823          	sw	a3,1072(a4)
    80001c9a:	078e                	slli	a5,a5,0x3
    80001c9c:	00010717          	auipc	a4,0x10
    80001ca0:	34470713          	addi	a4,a4,836 # 80011fe0 <PQ>
    80001ca4:	97ba                	add	a5,a5,a4
    80001ca6:	e384                	sd	s1,0(a5)
}
    80001ca8:	8526                	mv	a0,s1
    80001caa:	60e2                	ld	ra,24(sp)
    80001cac:	6442                	ld	s0,16(sp)
    80001cae:	64a2                	ld	s1,8(sp)
    80001cb0:	6902                	ld	s2,0(sp)
    80001cb2:	6105                	addi	sp,sp,32
    80001cb4:	8082                	ret
    freeproc(p);
    80001cb6:	8526                	mv	a0,s1
    80001cb8:	00000097          	auipc	ra,0x0
    80001cbc:	ea6080e7          	jalr	-346(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cc0:	8526                	mv	a0,s1
    80001cc2:	fffff097          	auipc	ra,0xfffff
    80001cc6:	fc8080e7          	jalr	-56(ra) # 80000c8a <release>
    return 0;
    80001cca:	84ca                	mv	s1,s2
    80001ccc:	bff1                	j	80001ca8 <allocproc+0xdc>
    freeproc(p);
    80001cce:	8526                	mv	a0,s1
    80001cd0:	00000097          	auipc	ra,0x0
    80001cd4:	e8e080e7          	jalr	-370(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001cd8:	8526                	mv	a0,s1
    80001cda:	fffff097          	auipc	ra,0xfffff
    80001cde:	fb0080e7          	jalr	-80(ra) # 80000c8a <release>
    return 0;
    80001ce2:	84ca                	mv	s1,s2
    80001ce4:	b7d1                	j	80001ca8 <allocproc+0xdc>

0000000080001ce6 <userinit>:
{
    80001ce6:	1101                	addi	sp,sp,-32
    80001ce8:	ec06                	sd	ra,24(sp)
    80001cea:	e822                	sd	s0,16(sp)
    80001cec:	e426                	sd	s1,8(sp)
    80001cee:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cf0:	00000097          	auipc	ra,0x0
    80001cf4:	edc080e7          	jalr	-292(ra) # 80001bcc <allocproc>
    80001cf8:	84aa                	mv	s1,a0
  initproc = p;
    80001cfa:	00008797          	auipc	a5,0x8
    80001cfe:	c2a7b723          	sd	a0,-978(a5) # 80009928 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001d02:	03400613          	li	a2,52
    80001d06:	00008597          	auipc	a1,0x8
    80001d0a:	b9a58593          	addi	a1,a1,-1126 # 800098a0 <initcode>
    80001d0e:	6928                	ld	a0,80(a0)
    80001d10:	fffff097          	auipc	ra,0xfffff
    80001d14:	646080e7          	jalr	1606(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001d18:	6785                	lui	a5,0x1
    80001d1a:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;     // user program counter
    80001d1c:	6cb8                	ld	a4,88(s1)
    80001d1e:	00073c23          	sd	zero,24(a4)
  p->trapframe->sp = PGSIZE; // user stack pointer
    80001d22:	6cb8                	ld	a4,88(s1)
    80001d24:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d26:	4641                	li	a2,16
    80001d28:	00007597          	auipc	a1,0x7
    80001d2c:	4d858593          	addi	a1,a1,1240 # 80009200 <digits+0x1c0>
    80001d30:	15848513          	addi	a0,s1,344
    80001d34:	fffff097          	auipc	ra,0xfffff
    80001d38:	0e8080e7          	jalr	232(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001d3c:	00007517          	auipc	a0,0x7
    80001d40:	4d450513          	addi	a0,a0,1236 # 80009210 <digits+0x1d0>
    80001d44:	00003097          	auipc	ra,0x3
    80001d48:	09e080e7          	jalr	158(ra) # 80004de2 <namei>
    80001d4c:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d50:	478d                	li	a5,3
    80001d52:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d54:	8526                	mv	a0,s1
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	f34080e7          	jalr	-204(ra) # 80000c8a <release>
}
    80001d5e:	60e2                	ld	ra,24(sp)
    80001d60:	6442                	ld	s0,16(sp)
    80001d62:	64a2                	ld	s1,8(sp)
    80001d64:	6105                	addi	sp,sp,32
    80001d66:	8082                	ret

0000000080001d68 <growproc>:
{
    80001d68:	1101                	addi	sp,sp,-32
    80001d6a:	ec06                	sd	ra,24(sp)
    80001d6c:	e822                	sd	s0,16(sp)
    80001d6e:	e426                	sd	s1,8(sp)
    80001d70:	e04a                	sd	s2,0(sp)
    80001d72:	1000                	addi	s0,sp,32
    80001d74:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d76:	00000097          	auipc	ra,0x0
    80001d7a:	c36080e7          	jalr	-970(ra) # 800019ac <myproc>
    80001d7e:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d80:	652c                	ld	a1,72(a0)
  if (n > 0)
    80001d82:	01204c63          	bgtz	s2,80001d9a <growproc+0x32>
  else if (n < 0)
    80001d86:	02094663          	bltz	s2,80001db2 <growproc+0x4a>
  p->sz = sz;
    80001d8a:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d8c:	4501                	li	a0,0
}
    80001d8e:	60e2                	ld	ra,24(sp)
    80001d90:	6442                	ld	s0,16(sp)
    80001d92:	64a2                	ld	s1,8(sp)
    80001d94:	6902                	ld	s2,0(sp)
    80001d96:	6105                	addi	sp,sp,32
    80001d98:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80001d9a:	4691                	li	a3,4
    80001d9c:	00b90633          	add	a2,s2,a1
    80001da0:	6928                	ld	a0,80(a0)
    80001da2:	fffff097          	auipc	ra,0xfffff
    80001da6:	66e080e7          	jalr	1646(ra) # 80001410 <uvmalloc>
    80001daa:	85aa                	mv	a1,a0
    80001dac:	fd79                	bnez	a0,80001d8a <growproc+0x22>
      return -1;
    80001dae:	557d                	li	a0,-1
    80001db0:	bff9                	j	80001d8e <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001db2:	00b90633          	add	a2,s2,a1
    80001db6:	6928                	ld	a0,80(a0)
    80001db8:	fffff097          	auipc	ra,0xfffff
    80001dbc:	610080e7          	jalr	1552(ra) # 800013c8 <uvmdealloc>
    80001dc0:	85aa                	mv	a1,a0
    80001dc2:	b7e1                	j	80001d8a <growproc+0x22>

0000000080001dc4 <fork>:
{
    80001dc4:	7139                	addi	sp,sp,-64
    80001dc6:	fc06                	sd	ra,56(sp)
    80001dc8:	f822                	sd	s0,48(sp)
    80001dca:	f426                	sd	s1,40(sp)
    80001dcc:	f04a                	sd	s2,32(sp)
    80001dce:	ec4e                	sd	s3,24(sp)
    80001dd0:	e852                	sd	s4,16(sp)
    80001dd2:	e456                	sd	s5,8(sp)
    80001dd4:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dd6:	00000097          	auipc	ra,0x0
    80001dda:	bd6080e7          	jalr	-1066(ra) # 800019ac <myproc>
    80001dde:	8aaa                	mv	s5,a0
  if ((np = allocproc()) == 0)
    80001de0:	00000097          	auipc	ra,0x0
    80001de4:	dec080e7          	jalr	-532(ra) # 80001bcc <allocproc>
    80001de8:	10050c63          	beqz	a0,80001f00 <fork+0x13c>
    80001dec:	8a2a                	mv	s4,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80001dee:	048ab603          	ld	a2,72(s5)
    80001df2:	692c                	ld	a1,80(a0)
    80001df4:	050ab503          	ld	a0,80(s5)
    80001df8:	fffff097          	auipc	ra,0xfffff
    80001dfc:	770080e7          	jalr	1904(ra) # 80001568 <uvmcopy>
    80001e00:	04054863          	bltz	a0,80001e50 <fork+0x8c>
  np->sz = p->sz;
    80001e04:	048ab783          	ld	a5,72(s5)
    80001e08:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001e0c:	058ab683          	ld	a3,88(s5)
    80001e10:	87b6                	mv	a5,a3
    80001e12:	058a3703          	ld	a4,88(s4)
    80001e16:	12068693          	addi	a3,a3,288
    80001e1a:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e1e:	6788                	ld	a0,8(a5)
    80001e20:	6b8c                	ld	a1,16(a5)
    80001e22:	6f90                	ld	a2,24(a5)
    80001e24:	01073023          	sd	a6,0(a4)
    80001e28:	e708                	sd	a0,8(a4)
    80001e2a:	eb0c                	sd	a1,16(a4)
    80001e2c:	ef10                	sd	a2,24(a4)
    80001e2e:	02078793          	addi	a5,a5,32
    80001e32:	02070713          	addi	a4,a4,32
    80001e36:	fed792e3          	bne	a5,a3,80001e1a <fork+0x56>
  np->trapframe->a0 = 0;
    80001e3a:	058a3783          	ld	a5,88(s4)
    80001e3e:	0607b823          	sd	zero,112(a5)
  for (i = 0; i < NOFILE; i++)
    80001e42:	0d0a8493          	addi	s1,s5,208
    80001e46:	0d0a0913          	addi	s2,s4,208
    80001e4a:	150a8993          	addi	s3,s5,336
    80001e4e:	a00d                	j	80001e70 <fork+0xac>
    freeproc(np);
    80001e50:	8552                	mv	a0,s4
    80001e52:	00000097          	auipc	ra,0x0
    80001e56:	d0c080e7          	jalr	-756(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e5a:	8552                	mv	a0,s4
    80001e5c:	fffff097          	auipc	ra,0xfffff
    80001e60:	e2e080e7          	jalr	-466(ra) # 80000c8a <release>
    return -1;
    80001e64:	597d                	li	s2,-1
    80001e66:	a059                	j	80001eec <fork+0x128>
  for (i = 0; i < NOFILE; i++)
    80001e68:	04a1                	addi	s1,s1,8
    80001e6a:	0921                	addi	s2,s2,8
    80001e6c:	01348b63          	beq	s1,s3,80001e82 <fork+0xbe>
    if (p->ofile[i])
    80001e70:	6088                	ld	a0,0(s1)
    80001e72:	d97d                	beqz	a0,80001e68 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e74:	00003097          	auipc	ra,0x3
    80001e78:	604080e7          	jalr	1540(ra) # 80005478 <filedup>
    80001e7c:	00a93023          	sd	a0,0(s2)
    80001e80:	b7e5                	j	80001e68 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e82:	150ab503          	ld	a0,336(s5)
    80001e86:	00002097          	auipc	ra,0x2
    80001e8a:	772080e7          	jalr	1906(ra) # 800045f8 <idup>
    80001e8e:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e92:	4641                	li	a2,16
    80001e94:	158a8593          	addi	a1,s5,344
    80001e98:	158a0513          	addi	a0,s4,344
    80001e9c:	fffff097          	auipc	ra,0xfffff
    80001ea0:	f80080e7          	jalr	-128(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001ea4:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001ea8:	8552                	mv	a0,s4
    80001eaa:	fffff097          	auipc	ra,0xfffff
    80001eae:	de0080e7          	jalr	-544(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001eb2:	00010497          	auipc	s1,0x10
    80001eb6:	d0648493          	addi	s1,s1,-762 # 80011bb8 <wait_lock>
    80001eba:	8526                	mv	a0,s1
    80001ebc:	fffff097          	auipc	ra,0xfffff
    80001ec0:	d1a080e7          	jalr	-742(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001ec4:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001ec8:	8526                	mv	a0,s1
    80001eca:	fffff097          	auipc	ra,0xfffff
    80001ece:	dc0080e7          	jalr	-576(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001ed2:	8552                	mv	a0,s4
    80001ed4:	fffff097          	auipc	ra,0xfffff
    80001ed8:	d02080e7          	jalr	-766(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001edc:	478d                	li	a5,3
    80001ede:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ee2:	8552                	mv	a0,s4
    80001ee4:	fffff097          	auipc	ra,0xfffff
    80001ee8:	da6080e7          	jalr	-602(ra) # 80000c8a <release>
}
    80001eec:	854a                	mv	a0,s2
    80001eee:	70e2                	ld	ra,56(sp)
    80001ef0:	7442                	ld	s0,48(sp)
    80001ef2:	74a2                	ld	s1,40(sp)
    80001ef4:	7902                	ld	s2,32(sp)
    80001ef6:	69e2                	ld	s3,24(sp)
    80001ef8:	6a42                	ld	s4,16(sp)
    80001efa:	6aa2                	ld	s5,8(sp)
    80001efc:	6121                	addi	sp,sp,64
    80001efe:	8082                	ret
    return -1;
    80001f00:	597d                	li	s2,-1
    80001f02:	b7ed                	j	80001eec <fork+0x128>

0000000080001f04 <scheduler>:
{
    80001f04:	7135                	addi	sp,sp,-160
    80001f06:	ed06                	sd	ra,152(sp)
    80001f08:	e922                	sd	s0,144(sp)
    80001f0a:	e526                	sd	s1,136(sp)
    80001f0c:	e14a                	sd	s2,128(sp)
    80001f0e:	fcce                	sd	s3,120(sp)
    80001f10:	f8d2                	sd	s4,112(sp)
    80001f12:	f4d6                	sd	s5,104(sp)
    80001f14:	f0da                	sd	s6,96(sp)
    80001f16:	ecde                	sd	s7,88(sp)
    80001f18:	e8e2                	sd	s8,80(sp)
    80001f1a:	e4e6                	sd	s9,72(sp)
    80001f1c:	e0ea                	sd	s10,64(sp)
    80001f1e:	fc6e                	sd	s11,56(sp)
    80001f20:	1100                	addi	s0,sp,160
  printf("MLFQ\n");
    80001f22:	00007517          	auipc	a0,0x7
    80001f26:	2f650513          	addi	a0,a0,758 # 80009218 <digits+0x1d8>
    80001f2a:	ffffe097          	auipc	ra,0xffffe
    80001f2e:	660080e7          	jalr	1632(ra) # 8000058a <printf>
    80001f32:	8792                	mv	a5,tp
  int id = r_tp();
    80001f34:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f36:	00779d13          	slli	s10,a5,0x7
    80001f3a:	00010717          	auipc	a4,0x10
    80001f3e:	c6670713          	addi	a4,a4,-922 # 80011ba0 <pid_lock>
    80001f42:	976a                	add	a4,a4,s10
    80001f44:	02073823          	sd	zero,48(a4)
          swtch(&c->context, &p->context);
    80001f48:	00010717          	auipc	a4,0x10
    80001f4c:	c9070713          	addi	a4,a4,-880 # 80011bd8 <cpus+0x8>
    80001f50:	9d3a                	add	s10,s10,a4
    if(pq[0]){
    80001f52:	00010a17          	auipc	s4,0x10
    80001f56:	c4ea0a13          	addi	s4,s4,-946 # 80011ba0 <pid_lock>
            PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    80001f5a:	00010a97          	auipc	s5,0x10
    80001f5e:	086a8a93          	addi	s5,s5,134 # 80011fe0 <PQ>
          c->proc = p;
    80001f62:	079e                	slli	a5,a5,0x7
    80001f64:	00fa0cb3          	add	s9,s4,a5
    80001f68:	aafd                	j	80002166 <scheduler+0x262>
            p->clk_int++;
    80001f6a:	19c92783          	lw	a5,412(s2)
    80001f6e:	2785                	addiw	a5,a5,1
    80001f70:	18f92e23          	sw	a5,412(s2)
            for(int j = 0; j < NPROC; j++){
    80001f74:	00011497          	auipc	s1,0x11
    80001f78:	86c48493          	addi	s1,s1,-1940 # 800127e0 <proc>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    80001f7c:	4c0d                	li	s8,3
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    80001f7e:	03200d93          	li	s11,50
    80001f82:	a825                	j	80001fba <scheduler+0xb6>
                  proc[j].vol_exit = 0;
    80001f84:	1a04a223          	sw	zero,420(s1)
                  PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    80001f88:	1984a783          	lw	a5,408(s1)
    80001f8c:	00279713          	slli	a4,a5,0x2
    80001f90:	9752                	add	a4,a4,s4
    80001f92:	43072683          	lw	a3,1072(a4)
    80001f96:	0016861b          	addiw	a2,a3,1
    80001f9a:	42c72823          	sw	a2,1072(a4)
    80001f9e:	079a                	slli	a5,a5,0x6
    80001fa0:	97b6                	add	a5,a5,a3
    80001fa2:	078e                	slli	a5,a5,0x3
    80001fa4:	97d6                	add	a5,a5,s5
    80001fa6:	e384                	sd	s1,0(a5)
                release(&proc[j].lock);
    80001fa8:	854e                	mv	a0,s3
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	ce0080e7          	jalr	-800(ra) # 80000c8a <release>
            for(int j = 0; j < NPROC; j++){
    80001fb2:	1a848493          	addi	s1,s1,424
    80001fb6:	11648e63          	beq	s1,s6,800020d2 <scheduler+0x1ce>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    80001fba:	89a6                	mv	s3,s1
    80001fbc:	5898                	lw	a4,48(s1)
    80001fbe:	03092783          	lw	a5,48(s2)
    80001fc2:	fef708e3          	beq	a4,a5,80001fb2 <scheduler+0xae>
    80001fc6:	4c9c                	lw	a5,24(s1)
    80001fc8:	ff8795e3          	bne	a5,s8,80001fb2 <scheduler+0xae>
                acquire(&proc[j].lock);
    80001fcc:	8526                	mv	a0,s1
    80001fce:	fffff097          	auipc	ra,0xfffff
    80001fd2:	c08080e7          	jalr	-1016(ra) # 80000bd6 <acquire>
                if(proc[j].vol_exit == 1){
    80001fd6:	1a44a783          	lw	a5,420(s1)
    80001fda:	fb7785e3          	beq	a5,s7,80001f84 <scheduler+0x80>
                  proc[j].wait_time++;
    80001fde:	1a04a783          	lw	a5,416(s1)
    80001fe2:	2785                	addiw	a5,a5,1
    80001fe4:	0007871b          	sext.w	a4,a5
    80001fe8:	1af4a023          	sw	a5,416(s1)
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    80001fec:	faeddee3          	bge	s11,a4,80001fa8 <scheduler+0xa4>
    80001ff0:	1984a503          	lw	a0,408(s1)
    80001ff4:	faa05ae3          	blez	a0,80001fa8 <scheduler+0xa4>
                    proc[j].wait_time = 0;
    80001ff8:	1a04a023          	sw	zero,416(s1)
                    proc[j].clk_int = 0;
    80001ffc:	1804ae23          	sw	zero,412(s1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002000:	00251793          	slli	a5,a0,0x2
    80002004:	97d2                	add	a5,a5,s4
    80002006:	4307a803          	lw	a6,1072(a5)
    8000200a:	03005e63          	blez	a6,80002046 <scheduler+0x142>
    8000200e:	00951793          	slli	a5,a0,0x9
    80002012:	97d6                	add	a5,a5,s5
    80002014:	0008089b          	sext.w	a7,a6
    80002018:	875e                	mv	a4,s7
                    int flag = 0;
    8000201a:	4601                	li	a2,0
    8000201c:	a831                	j	80002038 <scheduler+0x134>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    8000201e:	0007069b          	sext.w	a3,a4
    80002022:	865e                	mv	a2,s7
    80002024:	0106d463          	bge	a3,a6,8000202c <scheduler+0x128>
                        PQ[proc[j].priority][k] = PQ[proc[j].priority][k+1];
    80002028:	6594                	ld	a3,8(a1)
    8000202a:	e194                	sd	a3,0(a1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    8000202c:	07a1                	addi	a5,a5,8
    8000202e:	0017069b          	addiw	a3,a4,1
    80002032:	01170a63          	beq	a4,a7,80002046 <scheduler+0x142>
    80002036:	8736                	mv	a4,a3
                      if(PQ[proc[j].priority][k] == &proc[j])
    80002038:	85be                	mv	a1,a5
    8000203a:	6394                	ld	a3,0(a5)
    8000203c:	ff3681e3          	beq	a3,s3,8000201e <scheduler+0x11a>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002040:	ff7616e3          	bne	a2,s7,8000202c <scheduler+0x128>
    80002044:	bfe9                	j	8000201e <scheduler+0x11a>
                    pq[proc[j].priority]--;
    80002046:	00251793          	slli	a5,a0,0x2
    8000204a:	97d2                	add	a5,a5,s4
    8000204c:	387d                	addiw	a6,a6,-1
    8000204e:	4307a823          	sw	a6,1072(a5)
                    proc[j].priority--;
    80002052:	357d                	addiw	a0,a0,-1
    80002054:	0005079b          	sext.w	a5,a0
    80002058:	18a9ac23          	sw	a0,408(s3)
                    PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    8000205c:	00279713          	slli	a4,a5,0x2
    80002060:	9752                	add	a4,a4,s4
    80002062:	43072683          	lw	a3,1072(a4)
    80002066:	0016861b          	addiw	a2,a3,1
    8000206a:	42c72823          	sw	a2,1072(a4)
    8000206e:	079a                	slli	a5,a5,0x6
    80002070:	97b6                	add	a5,a5,a3
    80002072:	078e                	slli	a5,a5,0x3
    80002074:	97d6                	add	a5,a5,s5
    80002076:	0137b023          	sd	s3,0(a5)
    8000207a:	b73d                	j	80001fa8 <scheduler+0xa4>
              if(flag == 1 && k+1 < pq[p->priority])
    8000207c:	0005879b          	sext.w	a5,a1
    80002080:	855e                	mv	a0,s7
    80002082:	00c7dc63          	bge	a5,a2,8000209a <scheduler+0x196>
                PQ[p->priority][k] = PQ[p->priority][k+1];
    80002086:	071a                	slli	a4,a4,0x6
    80002088:	97ba                	add	a5,a5,a4
    8000208a:	078e                	slli	a5,a5,0x3
    8000208c:	97d6                	add	a5,a5,s5
    8000208e:	6390                	ld	a2,0(a5)
    80002090:	00d707b3          	add	a5,a4,a3
    80002094:	078e                	slli	a5,a5,0x3
    80002096:	97d6                	add	a5,a5,s5
    80002098:	e390                	sd	a2,0(a5)
            for(int k = 0; k < pq[p->priority]; k++){
    8000209a:	2685                	addiw	a3,a3,1
    8000209c:	19892703          	lw	a4,408(s2)
    800020a0:	00271793          	slli	a5,a4,0x2
    800020a4:	97d2                	add	a5,a5,s4
    800020a6:	4307a603          	lw	a2,1072(a5)
    800020aa:	0585                	addi	a1,a1,1
    800020ac:	00c6dd63          	bge	a3,a2,800020c6 <scheduler+0x1c2>
              if(PQ[p->priority][k] == p){
    800020b0:	00671793          	slli	a5,a4,0x6
    800020b4:	97b6                	add	a5,a5,a3
    800020b6:	078e                	slli	a5,a5,0x3
    800020b8:	97d6                	add	a5,a5,s5
    800020ba:	639c                	ld	a5,0(a5)
    800020bc:	fd2780e3          	beq	a5,s2,8000207c <scheduler+0x178>
              if(flag == 1 && k+1 < pq[p->priority])
    800020c0:	fd751de3          	bne	a0,s7,8000209a <scheduler+0x196>
    800020c4:	bf65                	j	8000207c <scheduler+0x178>
            pq[p->priority]--;
    800020c6:	00271793          	slli	a5,a4,0x2
    800020ca:	97d2                	add	a5,a5,s4
    800020cc:	367d                	addiw	a2,a2,-1 # fff <_entry-0x7ffff001>
    800020ce:	42c7a823          	sw	a2,1072(a5)
        while(p->state == RUNNABLE && p->clk_int < 1){
    800020d2:	01892703          	lw	a4,24(s2)
    800020d6:	478d                	li	a5,3
    800020d8:	04f71e63          	bne	a4,a5,80002134 <scheduler+0x230>
    800020dc:	19c92783          	lw	a5,412(s2)
    800020e0:	04f04a63          	bgtz	a5,80002134 <scheduler+0x230>
          p->state = RUNNING;
    800020e4:	4791                	li	a5,4
    800020e6:	00f92c23          	sw	a5,24(s2)
          p->wait_time = 0;
    800020ea:	1a092023          	sw	zero,416(s2)
          c->proc = p;
    800020ee:	032cb823          	sd	s2,48(s9)
          swtch(&c->context, &p->context);
    800020f2:	06090593          	addi	a1,s2,96
    800020f6:	856a                	mv	a0,s10
    800020f8:	00001097          	auipc	ra,0x1
    800020fc:	298080e7          	jalr	664(ra) # 80003390 <swtch>
          c->proc = 0;
    80002100:	020cb823          	sd	zero,48(s9)
          if(p->state == RUNNABLE){
    80002104:	01892703          	lw	a4,24(s2)
    80002108:	478d                	li	a5,3
    8000210a:	e6f700e3          	beq	a4,a5,80001f6a <scheduler+0x66>
            p->vol_exit = 1;
    8000210e:	1b792223          	sw	s7,420(s2)
            p->wait_time = 0;
    80002112:	1a092023          	sw	zero,416(s2)
            p->clk_int = 0;
    80002116:	18092e23          	sw	zero,412(s2)
            for(int k = 0; k < pq[p->priority]; k++){
    8000211a:	19892703          	lw	a4,408(s2)
    8000211e:	00271793          	slli	a5,a4,0x2
    80002122:	97d2                	add	a5,a5,s4
    80002124:	4307a603          	lw	a2,1072(a5)
    80002128:	f8c05fe3          	blez	a2,800020c6 <scheduler+0x1c2>
    8000212c:	4585                	li	a1,1
    8000212e:	4681                	li	a3,0
            int flag = 0;
    80002130:	4501                	li	a0,0
    80002132:	bfbd                	j	800020b0 <scheduler+0x1ac>
        if(p->clk_int == 1){
    80002134:	19c92803          	lw	a6,412(s2)
    80002138:	4785                	li	a5,1
    8000213a:	06f80f63          	beq	a6,a5,800021b8 <scheduler+0x2b4>
        release(&p->lock);
    8000213e:	854a                	mv	a0,s2
    80002140:	fffff097          	auipc	ra,0xfffff
    80002144:	b4a080e7          	jalr	-1206(ra) # 80000c8a <release>
      for(int i = 0; i < pq[0]; i++){
    80002148:	f8043783          	ld	a5,-128(s0)
    8000214c:	0017871b          	addiw	a4,a5,1
    80002150:	f8e43023          	sd	a4,-128(s0)
    80002154:	f8843783          	ld	a5,-120(s0)
    80002158:	07a1                	addi	a5,a5,8
    8000215a:	f8f43423          	sd	a5,-120(s0)
    8000215e:	430a2783          	lw	a5,1072(s4)
    80002162:	02f74b63          	blt	a4,a5,80002198 <scheduler+0x294>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002166:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000216a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000216e:	10079073          	csrw	sstatus,a5
    if(pq[0]){
    80002172:	430a2783          	lw	a5,1072(s4)
    80002176:	f6f43423          	sd	a5,-152(s0)
    8000217a:	c3ed                	beqz	a5,8000225c <scheduler+0x358>
      for(int i = 0; i < pq[0]; i++){
    8000217c:	fef055e3          	blez	a5,80002166 <scheduler+0x262>
    80002180:	00010797          	auipc	a5,0x10
    80002184:	e6078793          	addi	a5,a5,-416 # 80011fe0 <PQ>
    80002188:	f8f43423          	sd	a5,-120(s0)
    8000218c:	f8043023          	sd	zero,-128(s0)
    80002190:	00017b17          	auipc	s6,0x17
    80002194:	050b0b13          	addi	s6,s6,80 # 800191e0 <tickslock>
        p = PQ[0][i];
    80002198:	f8843783          	ld	a5,-120(s0)
    8000219c:	0007b903          	ld	s2,0(a5)
        acquire(&p->lock);
    800021a0:	854a                	mv	a0,s2
    800021a2:	fffff097          	auipc	ra,0xfffff
    800021a6:	a34080e7          	jalr	-1484(ra) # 80000bd6 <acquire>
        while(p->state == RUNNABLE && p->clk_int < 1){
    800021aa:	01892703          	lw	a4,24(s2)
    800021ae:	478d                	li	a5,3
            p->vol_exit = 1;
    800021b0:	4b85                	li	s7,1
        while(p->state == RUNNABLE && p->clk_int < 1){
    800021b2:	f2f705e3          	beq	a4,a5,800020dc <scheduler+0x1d8>
    800021b6:	bfbd                	j	80002134 <scheduler+0x230>
          p->clk_int = 0;
    800021b8:	18092e23          	sw	zero,412(s2)
          p->wait_time = 0;
    800021bc:	1a092023          	sw	zero,416(s2)
          for(int k = 0; k < pq[p->priority]; k++){
    800021c0:	19892783          	lw	a5,408(s2)
    800021c4:	00279713          	slli	a4,a5,0x2
    800021c8:	9752                	add	a4,a4,s4
    800021ca:	43072683          	lw	a3,1072(a4)
    800021ce:	04d05b63          	blez	a3,80002224 <scheduler+0x320>
    800021d2:	4505                	li	a0,1
    800021d4:	4601                	li	a2,0
          int flag = 0;
    800021d6:	4581                	li	a1,0
            if(flag == 1 && k+1 < pq[p->priority])
    800021d8:	4885                	li	a7,1
    800021da:	a815                	j	8000220e <scheduler+0x30a>
    800021dc:	0005071b          	sext.w	a4,a0
    800021e0:	85c2                	mv	a1,a6
    800021e2:	00d75b63          	bge	a4,a3,800021f8 <scheduler+0x2f4>
              PQ[p->priority][k] = PQ[p->priority][k+1];
    800021e6:	079a                	slli	a5,a5,0x6
    800021e8:	973e                	add	a4,a4,a5
    800021ea:	070e                	slli	a4,a4,0x3
    800021ec:	9756                	add	a4,a4,s5
    800021ee:	6318                	ld	a4,0(a4)
    800021f0:	97b2                	add	a5,a5,a2
    800021f2:	078e                	slli	a5,a5,0x3
    800021f4:	97d6                	add	a5,a5,s5
    800021f6:	e398                	sd	a4,0(a5)
          for(int k = 0; k < pq[p->priority]; k++){
    800021f8:	2605                	addiw	a2,a2,1
    800021fa:	19892783          	lw	a5,408(s2)
    800021fe:	00279713          	slli	a4,a5,0x2
    80002202:	9752                	add	a4,a4,s4
    80002204:	43072683          	lw	a3,1072(a4)
    80002208:	0505                	addi	a0,a0,1
    8000220a:	00d65d63          	bge	a2,a3,80002224 <scheduler+0x320>
            if(PQ[p->priority][k] == p)
    8000220e:	00679713          	slli	a4,a5,0x6
    80002212:	9732                	add	a4,a4,a2
    80002214:	070e                	slli	a4,a4,0x3
    80002216:	9756                	add	a4,a4,s5
    80002218:	6318                	ld	a4,0(a4)
    8000221a:	fd2701e3          	beq	a4,s2,800021dc <scheduler+0x2d8>
            if(flag == 1 && k+1 < pq[p->priority])
    8000221e:	fd159de3          	bne	a1,a7,800021f8 <scheduler+0x2f4>
    80002222:	bf6d                	j	800021dc <scheduler+0x2d8>
          pq[p->priority]--;
    80002224:	00279713          	slli	a4,a5,0x2
    80002228:	9752                	add	a4,a4,s4
    8000222a:	36fd                	addiw	a3,a3,-1
    8000222c:	42d72823          	sw	a3,1072(a4)
          p->priority++;
    80002230:	2785                	addiw	a5,a5,1
    80002232:	0007871b          	sext.w	a4,a5
    80002236:	18f92c23          	sw	a5,408(s2)
          PQ[p->priority][pq[p->priority]++] = p;
    8000223a:	00271793          	slli	a5,a4,0x2
    8000223e:	97d2                	add	a5,a5,s4
    80002240:	4307a683          	lw	a3,1072(a5)
    80002244:	0016861b          	addiw	a2,a3,1
    80002248:	42c7a823          	sw	a2,1072(a5)
    8000224c:	00671793          	slli	a5,a4,0x6
    80002250:	97b6                	add	a5,a5,a3
    80002252:	078e                	slli	a5,a5,0x3
    80002254:	97d6                	add	a5,a5,s5
    80002256:	0127b023          	sd	s2,0(a5)
    8000225a:	b5d5                	j	8000213e <scheduler+0x23a>
    else if(pq[1]){
    8000225c:	434a2783          	lw	a5,1076(s4)
    80002260:	f6f43823          	sd	a5,-144(s0)
    80002264:	eb8d                	bnez	a5,80002296 <scheduler+0x392>
    else if(pq[2]){
    80002266:	438a2783          	lw	a5,1080(s4)
    8000226a:	f6f43c23          	sd	a5,-136(s0)
    8000226e:	30079f63          	bnez	a5,8000258c <scheduler+0x688>
    else if(pq[3]){
    80002272:	43ca2783          	lw	a5,1084(s4)
    80002276:	080783e3          	beqz	a5,80002afc <scheduler+0xbf8>
      for(int i = 0; i < pq[3] && pq[0] == 0 && pq[1] == 0 && pq[2] == 0; i++){
    8000227a:	eef056e3          	blez	a5,80002166 <scheduler+0x262>
    8000227e:	00010797          	auipc	a5,0x10
    80002282:	36278793          	addi	a5,a5,866 # 800125e0 <PQ+0x600>
    80002286:	f8f43023          	sd	a5,-128(s0)
    8000228a:	00017b17          	auipc	s6,0x17
    8000228e:	f56b0b13          	addi	s6,s6,-170 # 800191e0 <tickslock>
    80002292:	03d0006f          	j	80002ace <scheduler+0xbca>
      for(int i = 0; i < pq[1] && pq[0] == 0; i++){
    80002296:	ecf058e3          	blez	a5,80002166 <scheduler+0x262>
    8000229a:	00010797          	auipc	a5,0x10
    8000229e:	f4678793          	addi	a5,a5,-186 # 800121e0 <PQ+0x200>
    800022a2:	f8f43023          	sd	a5,-128(s0)
    800022a6:	f6843783          	ld	a5,-152(s0)
    800022aa:	f6f43c23          	sd	a5,-136(s0)
    800022ae:	00017b17          	auipc	s6,0x17
    800022b2:	f32b0b13          	addi	s6,s6,-206 # 800191e0 <tickslock>
    800022b6:	ac01                	j	800024c6 <scheduler+0x5c2>
            p->clk_int++;
    800022b8:	19c92783          	lw	a5,412(s2)
    800022bc:	2785                	addiw	a5,a5,1
    800022be:	18f92e23          	sw	a5,412(s2)
            for(int j = 0; j < NPROC; j++){
    800022c2:	00010497          	auipc	s1,0x10
    800022c6:	51e48493          	addi	s1,s1,1310 # 800127e0 <proc>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    800022ca:	4c0d                	li	s8,3
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    800022cc:	03200d93          	li	s11,50
                    int flag = 0;
    800022d0:	f9343423          	sd	s3,-120(s0)
    800022d4:	a825                	j	8000230c <scheduler+0x408>
                  proc[j].vol_exit = 0;
    800022d6:	1a04a223          	sw	zero,420(s1)
                  PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    800022da:	1984a783          	lw	a5,408(s1)
    800022de:	00279713          	slli	a4,a5,0x2
    800022e2:	9752                	add	a4,a4,s4
    800022e4:	43072683          	lw	a3,1072(a4)
    800022e8:	0016861b          	addiw	a2,a3,1
    800022ec:	42c72823          	sw	a2,1072(a4)
    800022f0:	079a                	slli	a5,a5,0x6
    800022f2:	97b6                	add	a5,a5,a3
    800022f4:	078e                	slli	a5,a5,0x3
    800022f6:	97d6                	add	a5,a5,s5
    800022f8:	e384                	sd	s1,0(a5)
                release(&proc[j].lock);
    800022fa:	854e                	mv	a0,s3
    800022fc:	fffff097          	auipc	ra,0xfffff
    80002300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
            for(int j = 0; j < NPROC; j++){
    80002304:	1a848493          	addi	s1,s1,424
    80002308:	109b0d63          	beq	s6,s1,80002422 <scheduler+0x51e>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    8000230c:	89a6                	mv	s3,s1
    8000230e:	5898                	lw	a4,48(s1)
    80002310:	03092783          	lw	a5,48(s2)
    80002314:	fef708e3          	beq	a4,a5,80002304 <scheduler+0x400>
    80002318:	4c9c                	lw	a5,24(s1)
    8000231a:	ff8795e3          	bne	a5,s8,80002304 <scheduler+0x400>
                acquire(&proc[j].lock); 
    8000231e:	8526                	mv	a0,s1
    80002320:	fffff097          	auipc	ra,0xfffff
    80002324:	8b6080e7          	jalr	-1866(ra) # 80000bd6 <acquire>
                if(proc[j].vol_exit == 1){
    80002328:	1a44a783          	lw	a5,420(s1)
    8000232c:	fb7785e3          	beq	a5,s7,800022d6 <scheduler+0x3d2>
                  proc[j].wait_time++;
    80002330:	1a04a783          	lw	a5,416(s1)
    80002334:	2785                	addiw	a5,a5,1
    80002336:	0007871b          	sext.w	a4,a5
    8000233a:	1af4a023          	sw	a5,416(s1)
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    8000233e:	faeddee3          	bge	s11,a4,800022fa <scheduler+0x3f6>
    80002342:	1984a583          	lw	a1,408(s1)
    80002346:	fab05ae3          	blez	a1,800022fa <scheduler+0x3f6>
                    proc[j].wait_time = 0;
    8000234a:	1a04a023          	sw	zero,416(s1)
                    proc[j].clk_int = 0;
    8000234e:	1804ae23          	sw	zero,412(s1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002352:	00259793          	slli	a5,a1,0x2
    80002356:	97d2                	add	a5,a5,s4
    80002358:	4307a803          	lw	a6,1072(a5)
    8000235c:	03005f63          	blez	a6,8000239a <scheduler+0x496>
    80002360:	00959793          	slli	a5,a1,0x9
    80002364:	97d6                	add	a5,a5,s5
    80002366:	0008089b          	sext.w	a7,a6
                    int flag = 0;
    8000236a:	f8843603          	ld	a2,-120(s0)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    8000236e:	875e                	mv	a4,s7
    80002370:	a831                	j	8000238c <scheduler+0x488>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002372:	0007069b          	sext.w	a3,a4
    80002376:	865e                	mv	a2,s7
    80002378:	0106d463          	bge	a3,a6,80002380 <scheduler+0x47c>
                        PQ[proc[j].priority][k] = PQ[proc[j].priority][k+1];
    8000237c:	6514                	ld	a3,8(a0)
    8000237e:	e114                	sd	a3,0(a0)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002380:	07a1                	addi	a5,a5,8
    80002382:	0017069b          	addiw	a3,a4,1
    80002386:	00e88a63          	beq	a7,a4,8000239a <scheduler+0x496>
    8000238a:	8736                	mv	a4,a3
                      if(PQ[proc[j].priority][k] == &proc[j])
    8000238c:	853e                	mv	a0,a5
    8000238e:	6394                	ld	a3,0(a5)
    80002390:	ff3681e3          	beq	a3,s3,80002372 <scheduler+0x46e>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002394:	ff7616e3          	bne	a2,s7,80002380 <scheduler+0x47c>
    80002398:	bfe9                	j	80002372 <scheduler+0x46e>
                    pq[proc[j].priority]--;
    8000239a:	00259793          	slli	a5,a1,0x2
    8000239e:	97d2                	add	a5,a5,s4
    800023a0:	387d                	addiw	a6,a6,-1
    800023a2:	4307a823          	sw	a6,1072(a5)
                    proc[j].priority--;
    800023a6:	35fd                	addiw	a1,a1,-1
    800023a8:	0005879b          	sext.w	a5,a1
    800023ac:	18b9ac23          	sw	a1,408(s3)
                    PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    800023b0:	00279713          	slli	a4,a5,0x2
    800023b4:	9752                	add	a4,a4,s4
    800023b6:	43072683          	lw	a3,1072(a4)
    800023ba:	0016861b          	addiw	a2,a3,1
    800023be:	42c72823          	sw	a2,1072(a4)
    800023c2:	079a                	slli	a5,a5,0x6
    800023c4:	97b6                	add	a5,a5,a3
    800023c6:	078e                	slli	a5,a5,0x3
    800023c8:	97d6                	add	a5,a5,s5
    800023ca:	0137b023          	sd	s3,0(a5)
    800023ce:	b735                	j	800022fa <scheduler+0x3f6>
              if(flag == 1 && k+1 < pq[p->priority])
    800023d0:	0005879b          	sext.w	a5,a1
    800023d4:	89de                	mv	s3,s7
    800023d6:	00c7db63          	bge	a5,a2,800023ec <scheduler+0x4e8>
                PQ[p->priority][k] = PQ[p->priority][k+1];
    800023da:	071a                	slli	a4,a4,0x6
    800023dc:	97ba                	add	a5,a5,a4
    800023de:	078e                	slli	a5,a5,0x3
    800023e0:	97d6                	add	a5,a5,s5
    800023e2:	639c                	ld	a5,0(a5)
    800023e4:	9736                	add	a4,a4,a3
    800023e6:	070e                	slli	a4,a4,0x3
    800023e8:	9756                	add	a4,a4,s5
    800023ea:	e31c                	sd	a5,0(a4)
            for(int k = 0; k < pq[p->priority]; k++){
    800023ec:	2685                	addiw	a3,a3,1
    800023ee:	19892703          	lw	a4,408(s2)
    800023f2:	00271793          	slli	a5,a4,0x2
    800023f6:	97d2                	add	a5,a5,s4
    800023f8:	4307a603          	lw	a2,1072(a5)
    800023fc:	0585                	addi	a1,a1,1
    800023fe:	00c6dd63          	bge	a3,a2,80002418 <scheduler+0x514>
              if(PQ[p->priority][k] == p)
    80002402:	00671793          	slli	a5,a4,0x6
    80002406:	97b6                	add	a5,a5,a3
    80002408:	078e                	slli	a5,a5,0x3
    8000240a:	97d6                	add	a5,a5,s5
    8000240c:	639c                	ld	a5,0(a5)
    8000240e:	fd2781e3          	beq	a5,s2,800023d0 <scheduler+0x4cc>
              if(flag == 1 && k+1 < pq[p->priority])
    80002412:	fd799de3          	bne	s3,s7,800023ec <scheduler+0x4e8>
    80002416:	bf6d                	j	800023d0 <scheduler+0x4cc>
            pq[p->priority]--;
    80002418:	070a                	slli	a4,a4,0x2
    8000241a:	9752                	add	a4,a4,s4
    8000241c:	367d                	addiw	a2,a2,-1
    8000241e:	42c72823          	sw	a2,1072(a4)
        while(p->state == RUNNABLE && p->clk_int < 3 && pq[0] == 0){
    80002422:	01892703          	lw	a4,24(s2)
    80002426:	478d                	li	a5,3
    80002428:	06f71263          	bne	a4,a5,8000248c <scheduler+0x588>
    8000242c:	19c92703          	lw	a4,412(s2)
    80002430:	4789                	li	a5,2
    80002432:	04e7cd63          	blt	a5,a4,8000248c <scheduler+0x588>
    80002436:	430a2983          	lw	s3,1072(s4)
    8000243a:	04099e63          	bnez	s3,80002496 <scheduler+0x592>
          p->state = RUNNING;
    8000243e:	4791                	li	a5,4
    80002440:	00f92c23          	sw	a5,24(s2)
          c->proc = p;
    80002444:	032cb823          	sd	s2,48(s9)
          p->wait_time = 0;
    80002448:	1a092023          	sw	zero,416(s2)
          swtch(&c->context, &p->context);
    8000244c:	06090593          	addi	a1,s2,96
    80002450:	856a                	mv	a0,s10
    80002452:	00001097          	auipc	ra,0x1
    80002456:	f3e080e7          	jalr	-194(ra) # 80003390 <swtch>
          c->proc = 0;
    8000245a:	020cb823          	sd	zero,48(s9)
          if(p->state == RUNNABLE){
    8000245e:	01892703          	lw	a4,24(s2)
    80002462:	478d                	li	a5,3
    80002464:	e4f70ae3          	beq	a4,a5,800022b8 <scheduler+0x3b4>
            p->vol_exit = 1;
    80002468:	1b792223          	sw	s7,420(s2)
            p->wait_time = 0;
    8000246c:	1a092023          	sw	zero,416(s2)
            p->clk_int = 0;
    80002470:	18092e23          	sw	zero,412(s2)
            for(int k = 0; k < pq[p->priority]; k++){
    80002474:	19892703          	lw	a4,408(s2)
    80002478:	00271793          	slli	a5,a4,0x2
    8000247c:	97d2                	add	a5,a5,s4
    8000247e:	4307a603          	lw	a2,1072(a5)
    80002482:	f8c05be3          	blez	a2,80002418 <scheduler+0x514>
    80002486:	86ce                	mv	a3,s3
    80002488:	4585                	li	a1,1
    8000248a:	bfa5                	j	80002402 <scheduler+0x4fe>
        if(p->clk_int == 3){
    8000248c:	19c92703          	lw	a4,412(s2)
    80002490:	478d                	li	a5,3
    80002492:	04f70a63          	beq	a4,a5,800024e6 <scheduler+0x5e2>
        release(&p->lock);
    80002496:	854a                	mv	a0,s2
    80002498:	ffffe097          	auipc	ra,0xffffe
    8000249c:	7f2080e7          	jalr	2034(ra) # 80000c8a <release>
        if(pq[0])
    800024a0:	430a2783          	lw	a5,1072(s4)
    800024a4:	cc0791e3          	bnez	a5,80002166 <scheduler+0x262>
      for(int i = 0; i < pq[1] && pq[0] == 0; i++){
    800024a8:	f7843783          	ld	a5,-136(s0)
    800024ac:	2785                	addiw	a5,a5,1
    800024ae:	873e                	mv	a4,a5
    800024b0:	f6f43c23          	sd	a5,-136(s0)
    800024b4:	434a2783          	lw	a5,1076(s4)
    800024b8:	caf757e3          	bge	a4,a5,80002166 <scheduler+0x262>
    800024bc:	f8043783          	ld	a5,-128(s0)
    800024c0:	07a1                	addi	a5,a5,8
    800024c2:	f8f43023          	sd	a5,-128(s0)
        p = PQ[1][i];
    800024c6:	f8043783          	ld	a5,-128(s0)
    800024ca:	0007b903          	ld	s2,0(a5)
        acquire(&p->lock);
    800024ce:	854a                	mv	a0,s2
    800024d0:	ffffe097          	auipc	ra,0xffffe
    800024d4:	706080e7          	jalr	1798(ra) # 80000bd6 <acquire>
        while(p->state == RUNNABLE && p->clk_int < 3 && pq[0] == 0){
    800024d8:	01892703          	lw	a4,24(s2)
    800024dc:	478d                	li	a5,3
            p->vol_exit = 1;
    800024de:	4b85                	li	s7,1
        while(p->state == RUNNABLE && p->clk_int < 3 && pq[0] == 0){
    800024e0:	f4f706e3          	beq	a4,a5,8000242c <scheduler+0x528>
    800024e4:	b765                	j	8000248c <scheduler+0x588>
          p->wait_time = 0;
    800024e6:	1a092023          	sw	zero,416(s2)
          p->clk_int = 0;
    800024ea:	18092e23          	sw	zero,412(s2)
          for(int k = 0; k < pq[p->priority]; k++){
    800024ee:	19892703          	lw	a4,408(s2)
    800024f2:	00271793          	slli	a5,a4,0x2
    800024f6:	97d2                	add	a5,a5,s4
    800024f8:	4307a683          	lw	a3,1072(a5)
    800024fc:	04d05d63          	blez	a3,80002556 <scheduler+0x652>
    80002500:	f6843603          	ld	a2,-152(s0)
    80002504:	85b2                	mv	a1,a2
    80002506:	4505                	li	a0,1
    80002508:	4805                	li	a6,1
    8000250a:	a81d                	j	80002540 <scheduler+0x63c>
            if(flag == 1 && k+1 < pq[p->priority])
    8000250c:	0005079b          	sext.w	a5,a0
    80002510:	8642                	mv	a2,a6
    80002512:	00d7dc63          	bge	a5,a3,8000252a <scheduler+0x626>
              PQ[p->priority][k] = PQ[p->priority][k+1];
    80002516:	071a                	slli	a4,a4,0x6
    80002518:	97ba                	add	a5,a5,a4
    8000251a:	078e                	slli	a5,a5,0x3
    8000251c:	97d6                	add	a5,a5,s5
    8000251e:	6394                	ld	a3,0(a5)
    80002520:	00b707b3          	add	a5,a4,a1
    80002524:	078e                	slli	a5,a5,0x3
    80002526:	97d6                	add	a5,a5,s5
    80002528:	e394                	sd	a3,0(a5)
          for(int k = 0; k < pq[p->priority]; k++){
    8000252a:	2585                	addiw	a1,a1,1
    8000252c:	19892703          	lw	a4,408(s2)
    80002530:	00271793          	slli	a5,a4,0x2
    80002534:	97d2                	add	a5,a5,s4
    80002536:	4307a683          	lw	a3,1072(a5)
    8000253a:	0505                	addi	a0,a0,1
    8000253c:	00d5dd63          	bge	a1,a3,80002556 <scheduler+0x652>
            if(PQ[p->priority][k] == p)
    80002540:	00671793          	slli	a5,a4,0x6
    80002544:	97ae                	add	a5,a5,a1
    80002546:	078e                	slli	a5,a5,0x3
    80002548:	97d6                	add	a5,a5,s5
    8000254a:	639c                	ld	a5,0(a5)
    8000254c:	fd2780e3          	beq	a5,s2,8000250c <scheduler+0x608>
            if(flag == 1 && k+1 < pq[p->priority])
    80002550:	fd061de3          	bne	a2,a6,8000252a <scheduler+0x626>
    80002554:	bf65                	j	8000250c <scheduler+0x608>
          pq[p->priority]--;
    80002556:	00271793          	slli	a5,a4,0x2
    8000255a:	97d2                	add	a5,a5,s4
    8000255c:	36fd                	addiw	a3,a3,-1
    8000255e:	42d7a823          	sw	a3,1072(a5)
          p->priority++;
    80002562:	2705                	addiw	a4,a4,1
    80002564:	0007079b          	sext.w	a5,a4
    80002568:	18e92c23          	sw	a4,408(s2)
          PQ[p->priority][pq[p->priority]++] = p;
    8000256c:	00279713          	slli	a4,a5,0x2
    80002570:	9752                	add	a4,a4,s4
    80002572:	43072683          	lw	a3,1072(a4)
    80002576:	0016861b          	addiw	a2,a3,1
    8000257a:	42c72823          	sw	a2,1072(a4)
    8000257e:	079a                	slli	a5,a5,0x6
    80002580:	97b6                	add	a5,a5,a3
    80002582:	078e                	slli	a5,a5,0x3
    80002584:	97d6                	add	a5,a5,s5
    80002586:	0127b023          	sd	s2,0(a5)
    8000258a:	b731                	j	80002496 <scheduler+0x592>
      for(int i = 0; i < pq[2] && pq[0] == 0 && pq[1] == 0; i++){
    8000258c:	bcf05de3          	blez	a5,80002166 <scheduler+0x262>
    80002590:	00010797          	auipc	a5,0x10
    80002594:	e5078793          	addi	a5,a5,-432 # 800123e0 <PQ+0x400>
    80002598:	f6f43c23          	sd	a5,-136(s0)
    8000259c:	00017b17          	auipc	s6,0x17
    800025a0:	c44b0b13          	addi	s6,s6,-956 # 800191e0 <tickslock>
    800025a4:	a405                	j	800027c4 <scheduler+0x8c0>
            p->clk_int++;
    800025a6:	19c92783          	lw	a5,412(s2)
    800025aa:	2785                	addiw	a5,a5,1
    800025ac:	18f92e23          	sw	a5,412(s2)
            for(int j = 0; j < NPROC; j++){
    800025b0:	00010497          	auipc	s1,0x10
    800025b4:	23048493          	addi	s1,s1,560 # 800127e0 <proc>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    800025b8:	4c0d                	li	s8,3
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    800025ba:	03200d93          	li	s11,50
                    int flag = 0;
    800025be:	f9343423          	sd	s3,-120(s0)
    800025c2:	a825                	j	800025fa <scheduler+0x6f6>
                  proc[j].vol_exit = 0;
    800025c4:	1a04a223          	sw	zero,420(s1)
                  PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    800025c8:	1984a783          	lw	a5,408(s1)
    800025cc:	00279713          	slli	a4,a5,0x2
    800025d0:	9752                	add	a4,a4,s4
    800025d2:	43072683          	lw	a3,1072(a4)
    800025d6:	0016861b          	addiw	a2,a3,1
    800025da:	42c72823          	sw	a2,1072(a4)
    800025de:	079a                	slli	a5,a5,0x6
    800025e0:	97b6                	add	a5,a5,a3
    800025e2:	078e                	slli	a5,a5,0x3
    800025e4:	97d6                	add	a5,a5,s5
    800025e6:	e384                	sd	s1,0(a5)
                release(&proc[j].lock); 
    800025e8:	854e                	mv	a0,s3
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	6a0080e7          	jalr	1696(ra) # 80000c8a <release>
            for(int j = 0; j < NPROC; j++){
    800025f2:	1a848493          	addi	s1,s1,424
    800025f6:	11648e63          	beq	s1,s6,80002712 <scheduler+0x80e>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    800025fa:	89a6                	mv	s3,s1
    800025fc:	5898                	lw	a4,48(s1)
    800025fe:	03092783          	lw	a5,48(s2)
    80002602:	fef708e3          	beq	a4,a5,800025f2 <scheduler+0x6ee>
    80002606:	4c9c                	lw	a5,24(s1)
    80002608:	ff8795e3          	bne	a5,s8,800025f2 <scheduler+0x6ee>
                acquire(&proc[j].lock);
    8000260c:	8526                	mv	a0,s1
    8000260e:	ffffe097          	auipc	ra,0xffffe
    80002612:	5c8080e7          	jalr	1480(ra) # 80000bd6 <acquire>
                if(proc[j].vol_exit == 1){
    80002616:	1a44a783          	lw	a5,420(s1)
    8000261a:	fb7785e3          	beq	a5,s7,800025c4 <scheduler+0x6c0>
                  proc[j].wait_time++;
    8000261e:	1a04a783          	lw	a5,416(s1)
    80002622:	2785                	addiw	a5,a5,1
    80002624:	0007871b          	sext.w	a4,a5
    80002628:	1af4a023          	sw	a5,416(s1)
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    8000262c:	faeddee3          	bge	s11,a4,800025e8 <scheduler+0x6e4>
    80002630:	1984a583          	lw	a1,408(s1)
    80002634:	fab05ae3          	blez	a1,800025e8 <scheduler+0x6e4>
                    proc[j].wait_time = 0;
    80002638:	1a04a023          	sw	zero,416(s1)
                    proc[j].clk_int = 0;
    8000263c:	1804ae23          	sw	zero,412(s1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002640:	00259793          	slli	a5,a1,0x2
    80002644:	97d2                	add	a5,a5,s4
    80002646:	4307a803          	lw	a6,1072(a5)
    8000264a:	03005f63          	blez	a6,80002688 <scheduler+0x784>
    8000264e:	00959793          	slli	a5,a1,0x9
    80002652:	97d6                	add	a5,a5,s5
    80002654:	0008089b          	sext.w	a7,a6
                    int flag = 0;
    80002658:	f8843603          	ld	a2,-120(s0)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    8000265c:	875e                	mv	a4,s7
    8000265e:	a831                	j	8000267a <scheduler+0x776>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002660:	0007069b          	sext.w	a3,a4
    80002664:	865e                	mv	a2,s7
    80002666:	0106d463          	bge	a3,a6,8000266e <scheduler+0x76a>
                        PQ[proc[j].priority][k] = PQ[proc[j].priority][k+1];
    8000266a:	6514                	ld	a3,8(a0)
    8000266c:	e114                	sd	a3,0(a0)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    8000266e:	07a1                	addi	a5,a5,8
    80002670:	0017069b          	addiw	a3,a4,1
    80002674:	01170a63          	beq	a4,a7,80002688 <scheduler+0x784>
    80002678:	8736                	mv	a4,a3
                      if(PQ[proc[j].priority][k] == &proc[j])
    8000267a:	853e                	mv	a0,a5
    8000267c:	6394                	ld	a3,0(a5)
    8000267e:	ff3681e3          	beq	a3,s3,80002660 <scheduler+0x75c>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002682:	ff7616e3          	bne	a2,s7,8000266e <scheduler+0x76a>
    80002686:	bfe9                	j	80002660 <scheduler+0x75c>
                    pq[proc[j].priority]--;
    80002688:	00259793          	slli	a5,a1,0x2
    8000268c:	97d2                	add	a5,a5,s4
    8000268e:	387d                	addiw	a6,a6,-1
    80002690:	4307a823          	sw	a6,1072(a5)
                    proc[j].priority--;
    80002694:	35fd                	addiw	a1,a1,-1
    80002696:	0005879b          	sext.w	a5,a1
    8000269a:	18b9ac23          	sw	a1,408(s3)
                    PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    8000269e:	00279713          	slli	a4,a5,0x2
    800026a2:	9752                	add	a4,a4,s4
    800026a4:	43072683          	lw	a3,1072(a4)
    800026a8:	0016861b          	addiw	a2,a3,1
    800026ac:	42c72823          	sw	a2,1072(a4)
    800026b0:	079a                	slli	a5,a5,0x6
    800026b2:	97b6                	add	a5,a5,a3
    800026b4:	078e                	slli	a5,a5,0x3
    800026b6:	97d6                	add	a5,a5,s5
    800026b8:	0137b023          	sd	s3,0(a5)
    800026bc:	b735                	j	800025e8 <scheduler+0x6e4>
              if(flag == 1 && k+1 < pq[p->priority])
    800026be:	0005879b          	sext.w	a5,a1
    800026c2:	89de                	mv	s3,s7
    800026c4:	00c7dc63          	bge	a5,a2,800026dc <scheduler+0x7d8>
                PQ[p->priority][k] = PQ[p->priority][k+1];
    800026c8:	071a                	slli	a4,a4,0x6
    800026ca:	97ba                	add	a5,a5,a4
    800026cc:	078e                	slli	a5,a5,0x3
    800026ce:	97d6                	add	a5,a5,s5
    800026d0:	6390                	ld	a2,0(a5)
    800026d2:	9736                	add	a4,a4,a3
    800026d4:	00371793          	slli	a5,a4,0x3
    800026d8:	97d6                	add	a5,a5,s5
    800026da:	e390                	sd	a2,0(a5)
            for(int k = 0; k < pq[p->priority]; k++){
    800026dc:	2685                	addiw	a3,a3,1
    800026de:	19892703          	lw	a4,408(s2)
    800026e2:	00271793          	slli	a5,a4,0x2
    800026e6:	97d2                	add	a5,a5,s4
    800026e8:	4307a603          	lw	a2,1072(a5)
    800026ec:	0585                	addi	a1,a1,1
    800026ee:	00c6dd63          	bge	a3,a2,80002708 <scheduler+0x804>
              if(PQ[p->priority][k] == p)
    800026f2:	00671793          	slli	a5,a4,0x6
    800026f6:	97b6                	add	a5,a5,a3
    800026f8:	078e                	slli	a5,a5,0x3
    800026fa:	97d6                	add	a5,a5,s5
    800026fc:	639c                	ld	a5,0(a5)
    800026fe:	fd2780e3          	beq	a5,s2,800026be <scheduler+0x7ba>
              if(flag == 1 && k+1 < pq[p->priority])
    80002702:	fd799de3          	bne	s3,s7,800026dc <scheduler+0x7d8>
    80002706:	bf65                	j	800026be <scheduler+0x7ba>
            pq[p->priority]--;
    80002708:	070a                	slli	a4,a4,0x2
    8000270a:	9752                	add	a4,a4,s4
    8000270c:	367d                	addiw	a2,a2,-1
    8000270e:	42c72823          	sw	a2,1072(a4)
        while(p->state == RUNNABLE && p->clk_int < 9 && pq[1] == 0 && pq[0] == 0){
    80002712:	01892703          	lw	a4,24(s2)
    80002716:	478d                	li	a5,3
    80002718:	06f71663          	bne	a4,a5,80002784 <scheduler+0x880>
    8000271c:	19c92703          	lw	a4,412(s2)
    80002720:	47a1                	li	a5,8
    80002722:	06e7c163          	blt	a5,a4,80002784 <scheduler+0x880>
    80002726:	434a2983          	lw	s3,1076(s4)
    8000272a:	430a2783          	lw	a5,1072(s4)
    8000272e:	00f9e9b3          	or	s3,s3,a5
    80002732:	04099e63          	bnez	s3,8000278e <scheduler+0x88a>
          p->state = RUNNING;
    80002736:	4791                	li	a5,4
    80002738:	00f92c23          	sw	a5,24(s2)
          c->proc = p;
    8000273c:	032cb823          	sd	s2,48(s9)
          p->wait_time = 0;
    80002740:	1a092023          	sw	zero,416(s2)
          swtch(&c->context, &p->context);
    80002744:	06090593          	addi	a1,s2,96
    80002748:	856a                	mv	a0,s10
    8000274a:	00001097          	auipc	ra,0x1
    8000274e:	c46080e7          	jalr	-954(ra) # 80003390 <swtch>
          c->proc = 0;
    80002752:	020cb823          	sd	zero,48(s9)
          if(p->state == RUNNABLE){
    80002756:	01892703          	lw	a4,24(s2)
    8000275a:	478d                	li	a5,3
    8000275c:	e4f705e3          	beq	a4,a5,800025a6 <scheduler+0x6a2>
            p->vol_exit = 1;
    80002760:	1b792223          	sw	s7,420(s2)
            p->wait_time = 0;
    80002764:	1a092023          	sw	zero,416(s2)
            p->clk_int = 0;
    80002768:	18092e23          	sw	zero,412(s2)
            for(int k = 0; k < pq[p->priority]; k++){
    8000276c:	19892703          	lw	a4,408(s2)
    80002770:	00271793          	slli	a5,a4,0x2
    80002774:	97d2                	add	a5,a5,s4
    80002776:	4307a603          	lw	a2,1072(a5)
    8000277a:	f8c057e3          	blez	a2,80002708 <scheduler+0x804>
    8000277e:	86ce                	mv	a3,s3
    80002780:	4585                	li	a1,1
    80002782:	bf85                	j	800026f2 <scheduler+0x7ee>
        if(p->clk_int == 9){
    80002784:	19c92703          	lw	a4,412(s2)
    80002788:	47a5                	li	a5,9
    8000278a:	06f70363          	beq	a4,a5,800027f0 <scheduler+0x8ec>
        release(&p->lock);
    8000278e:	854a                	mv	a0,s2
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	4fa080e7          	jalr	1274(ra) # 80000c8a <release>
        if(pq[0] || pq[1]){
    80002798:	430a2783          	lw	a5,1072(s4)
    8000279c:	434a2703          	lw	a4,1076(s4)
    800027a0:	8fd9                	or	a5,a5,a4
    800027a2:	9c0792e3          	bnez	a5,80002166 <scheduler+0x262>
      for(int i = 0; i < pq[2] && pq[0] == 0 && pq[1] == 0; i++){
    800027a6:	f7043783          	ld	a5,-144(s0)
    800027aa:	2785                	addiw	a5,a5,1
    800027ac:	873e                	mv	a4,a5
    800027ae:	f6f43823          	sd	a5,-144(s0)
    800027b2:	438a2783          	lw	a5,1080(s4)
    800027b6:	9af758e3          	bge	a4,a5,80002166 <scheduler+0x262>
    800027ba:	f7843783          	ld	a5,-136(s0)
    800027be:	07a1                	addi	a5,a5,8
    800027c0:	f6f43c23          	sd	a5,-136(s0)
    800027c4:	434a2783          	lw	a5,1076(s4)
    800027c8:	f8f43023          	sd	a5,-128(s0)
    800027cc:	98079de3          	bnez	a5,80002166 <scheduler+0x262>
        p = PQ[2][i];
    800027d0:	f7843783          	ld	a5,-136(s0)
    800027d4:	0007b903          	ld	s2,0(a5)
        acquire(&p->lock);
    800027d8:	854a                	mv	a0,s2
    800027da:	ffffe097          	auipc	ra,0xffffe
    800027de:	3fc080e7          	jalr	1020(ra) # 80000bd6 <acquire>
        while(p->state == RUNNABLE && p->clk_int < 9 && pq[1] == 0 && pq[0] == 0){
    800027e2:	01892703          	lw	a4,24(s2)
    800027e6:	478d                	li	a5,3
            p->vol_exit = 1;
    800027e8:	4b85                	li	s7,1
        while(p->state == RUNNABLE && p->clk_int < 9 && pq[1] == 0 && pq[0] == 0){
    800027ea:	f2f709e3          	beq	a4,a5,8000271c <scheduler+0x818>
    800027ee:	bf59                	j	80002784 <scheduler+0x880>
          p->wait_time = 0;
    800027f0:	1a092023          	sw	zero,416(s2)
          p->clk_int = 0;
    800027f4:	18092e23          	sw	zero,412(s2)
          for(int k = 0; k < pq[p->priority]; k++){
    800027f8:	19892703          	lw	a4,408(s2)
    800027fc:	00271793          	slli	a5,a4,0x2
    80002800:	97d2                	add	a5,a5,s4
    80002802:	4307a603          	lw	a2,1072(a5)
    80002806:	04c05f63          	blez	a2,80002864 <scheduler+0x960>
    8000280a:	f8043683          	ld	a3,-128(s0)
    8000280e:	4585                	li	a1,1
    80002810:	4505                	li	a0,1
    80002812:	a825                	j	8000284a <scheduler+0x946>
            if(flag == 1 && k+1 < pq[p->priority])
    80002814:	0005879b          	sext.w	a5,a1
    80002818:	f8a43023          	sd	a0,-128(s0)
    8000281c:	00c7dc63          	bge	a5,a2,80002834 <scheduler+0x930>
              PQ[p->priority][k] = PQ[p->priority][k+1];
    80002820:	071a                	slli	a4,a4,0x6
    80002822:	97ba                	add	a5,a5,a4
    80002824:	078e                	slli	a5,a5,0x3
    80002826:	97d6                	add	a5,a5,s5
    80002828:	6390                	ld	a2,0(a5)
    8000282a:	00d707b3          	add	a5,a4,a3
    8000282e:	078e                	slli	a5,a5,0x3
    80002830:	97d6                	add	a5,a5,s5
    80002832:	e390                	sd	a2,0(a5)
          for(int k = 0; k < pq[p->priority]; k++){
    80002834:	2685                	addiw	a3,a3,1
    80002836:	19892703          	lw	a4,408(s2)
    8000283a:	00271793          	slli	a5,a4,0x2
    8000283e:	97d2                	add	a5,a5,s4
    80002840:	4307a603          	lw	a2,1072(a5)
    80002844:	0585                	addi	a1,a1,1
    80002846:	00c6df63          	bge	a3,a2,80002864 <scheduler+0x960>
            if(PQ[p->priority][k] == p)
    8000284a:	00671793          	slli	a5,a4,0x6
    8000284e:	97b6                	add	a5,a5,a3
    80002850:	078e                	slli	a5,a5,0x3
    80002852:	97d6                	add	a5,a5,s5
    80002854:	639c                	ld	a5,0(a5)
    80002856:	fb278fe3          	beq	a5,s2,80002814 <scheduler+0x910>
            if(flag == 1 && k+1 < pq[p->priority])
    8000285a:	f8043783          	ld	a5,-128(s0)
    8000285e:	fca79be3          	bne	a5,a0,80002834 <scheduler+0x930>
    80002862:	bf4d                	j	80002814 <scheduler+0x910>
          pq[p->priority]--;
    80002864:	00271793          	slli	a5,a4,0x2
    80002868:	97d2                	add	a5,a5,s4
    8000286a:	367d                	addiw	a2,a2,-1
    8000286c:	42c7a823          	sw	a2,1072(a5)
          p->priority++;
    80002870:	2705                	addiw	a4,a4,1
    80002872:	0007079b          	sext.w	a5,a4
    80002876:	18e92c23          	sw	a4,408(s2)
          PQ[p->priority][pq[p->priority]++] = p;
    8000287a:	00279713          	slli	a4,a5,0x2
    8000287e:	9752                	add	a4,a4,s4
    80002880:	43072683          	lw	a3,1072(a4)
    80002884:	0016861b          	addiw	a2,a3,1
    80002888:	42c72823          	sw	a2,1072(a4)
    8000288c:	079a                	slli	a5,a5,0x6
    8000288e:	97b6                	add	a5,a5,a3
    80002890:	078e                	slli	a5,a5,0x3
    80002892:	97d6                	add	a5,a5,s5
    80002894:	0127b023          	sd	s2,0(a5)
    80002898:	bddd                	j	8000278e <scheduler+0x88a>
            p->clk_int++;
    8000289a:	19c92783          	lw	a5,412(s2)
    8000289e:	2785                	addiw	a5,a5,1
    800028a0:	18f92e23          	sw	a5,412(s2)
            for(int j = 0; j < NPROC; j++){
    800028a4:	00010497          	auipc	s1,0x10
    800028a8:	f3c48493          	addi	s1,s1,-196 # 800127e0 <proc>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    800028ac:	4c0d                	li	s8,3
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    800028ae:	03200d93          	li	s11,50
                    int flag = 0;
    800028b2:	f9343423          	sd	s3,-120(s0)
    800028b6:	a825                	j	800028ee <scheduler+0x9ea>
                  proc[j].vol_exit = 0;
    800028b8:	1a04a223          	sw	zero,420(s1)
                  PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    800028bc:	1984a783          	lw	a5,408(s1)
    800028c0:	00279713          	slli	a4,a5,0x2
    800028c4:	9752                	add	a4,a4,s4
    800028c6:	43072683          	lw	a3,1072(a4)
    800028ca:	0016861b          	addiw	a2,a3,1
    800028ce:	42c72823          	sw	a2,1072(a4)
    800028d2:	079a                	slli	a5,a5,0x6
    800028d4:	97b6                	add	a5,a5,a3
    800028d6:	078e                	slli	a5,a5,0x3
    800028d8:	97d6                	add	a5,a5,s5
    800028da:	e384                	sd	s1,0(a5)
                release(&proc[j].lock);
    800028dc:	854e                	mv	a0,s3
    800028de:	ffffe097          	auipc	ra,0xffffe
    800028e2:	3ac080e7          	jalr	940(ra) # 80000c8a <release>
            for(int j = 0; j < NPROC; j++){
    800028e6:	1a848493          	addi	s1,s1,424
    800028ea:	11648e63          	beq	s1,s6,80002a06 <scheduler+0xb02>
              if(proc[j].pid != p->pid && proc[j].state == RUNNABLE){
    800028ee:	89a6                	mv	s3,s1
    800028f0:	5898                	lw	a4,48(s1)
    800028f2:	03092783          	lw	a5,48(s2)
    800028f6:	fef708e3          	beq	a4,a5,800028e6 <scheduler+0x9e2>
    800028fa:	4c9c                	lw	a5,24(s1)
    800028fc:	ff8795e3          	bne	a5,s8,800028e6 <scheduler+0x9e2>
                acquire(&proc[j].lock);
    80002900:	8526                	mv	a0,s1
    80002902:	ffffe097          	auipc	ra,0xffffe
    80002906:	2d4080e7          	jalr	724(ra) # 80000bd6 <acquire>
                if(proc[j].vol_exit == 1){
    8000290a:	1a44a783          	lw	a5,420(s1)
    8000290e:	fb7785e3          	beq	a5,s7,800028b8 <scheduler+0x9b4>
                  proc[j].wait_time++;
    80002912:	1a04a783          	lw	a5,416(s1)
    80002916:	2785                	addiw	a5,a5,1
    80002918:	0007871b          	sext.w	a4,a5
    8000291c:	1af4a023          	sw	a5,416(s1)
                  if(proc[j].wait_time > 50 && proc[j].priority >= 1){
    80002920:	faeddee3          	bge	s11,a4,800028dc <scheduler+0x9d8>
    80002924:	1984a503          	lw	a0,408(s1)
    80002928:	faa05ae3          	blez	a0,800028dc <scheduler+0x9d8>
                    proc[j].wait_time = 0;
    8000292c:	1a04a023          	sw	zero,416(s1)
                    proc[j].clk_int = 0;
    80002930:	1804ae23          	sw	zero,412(s1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002934:	00251793          	slli	a5,a0,0x2
    80002938:	97d2                	add	a5,a5,s4
    8000293a:	4307a803          	lw	a6,1072(a5)
    8000293e:	03005f63          	blez	a6,8000297c <scheduler+0xa78>
    80002942:	00951793          	slli	a5,a0,0x9
    80002946:	97d6                	add	a5,a5,s5
    80002948:	0008089b          	sext.w	a7,a6
                    int flag = 0;
    8000294c:	f8843603          	ld	a2,-120(s0)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002950:	875e                	mv	a4,s7
    80002952:	a831                	j	8000296e <scheduler+0xa6a>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002954:	0007069b          	sext.w	a3,a4
    80002958:	865e                	mv	a2,s7
    8000295a:	0106d463          	bge	a3,a6,80002962 <scheduler+0xa5e>
                        PQ[proc[j].priority][k] = PQ[proc[j].priority][k+1];
    8000295e:	6594                	ld	a3,8(a1)
    80002960:	e194                	sd	a3,0(a1)
                    for(int k = 0; k < pq[proc[j].priority]; k++){
    80002962:	07a1                	addi	a5,a5,8
    80002964:	0017069b          	addiw	a3,a4,1
    80002968:	01170a63          	beq	a4,a7,8000297c <scheduler+0xa78>
    8000296c:	8736                	mv	a4,a3
                      if(PQ[proc[j].priority][k] == &proc[j])
    8000296e:	85be                	mv	a1,a5
    80002970:	6394                	ld	a3,0(a5)
    80002972:	ff3681e3          	beq	a3,s3,80002954 <scheduler+0xa50>
                      if(flag == 1 && k+1 < pq[proc[j].priority])
    80002976:	ff7616e3          	bne	a2,s7,80002962 <scheduler+0xa5e>
    8000297a:	bfe9                	j	80002954 <scheduler+0xa50>
                    pq[proc[j].priority]--;
    8000297c:	00251793          	slli	a5,a0,0x2
    80002980:	97d2                	add	a5,a5,s4
    80002982:	387d                	addiw	a6,a6,-1
    80002984:	4307a823          	sw	a6,1072(a5)
                     proc[j].priority--;
    80002988:	357d                	addiw	a0,a0,-1
    8000298a:	0005079b          	sext.w	a5,a0
    8000298e:	18a9ac23          	sw	a0,408(s3)
                    PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    80002992:	00279713          	slli	a4,a5,0x2
    80002996:	9752                	add	a4,a4,s4
    80002998:	43072683          	lw	a3,1072(a4)
    8000299c:	0016861b          	addiw	a2,a3,1
    800029a0:	42c72823          	sw	a2,1072(a4)
    800029a4:	079a                	slli	a5,a5,0x6
    800029a6:	97b6                	add	a5,a5,a3
    800029a8:	078e                	slli	a5,a5,0x3
    800029aa:	97d6                	add	a5,a5,s5
    800029ac:	0137b023          	sd	s3,0(a5)
    800029b0:	b735                	j	800028dc <scheduler+0x9d8>
              if(flag == 1 && k+1 < pq[p->priority])
    800029b2:	0005879b          	sext.w	a5,a1
    800029b6:	89de                	mv	s3,s7
    800029b8:	00c7dc63          	bge	a5,a2,800029d0 <scheduler+0xacc>
                PQ[p->priority][k] = PQ[p->priority][k+1];
    800029bc:	071a                	slli	a4,a4,0x6
    800029be:	97ba                	add	a5,a5,a4
    800029c0:	078e                	slli	a5,a5,0x3
    800029c2:	97d6                	add	a5,a5,s5
    800029c4:	6390                	ld	a2,0(a5)
    800029c6:	9736                	add	a4,a4,a3
    800029c8:	00371793          	slli	a5,a4,0x3
    800029cc:	97d6                	add	a5,a5,s5
    800029ce:	e390                	sd	a2,0(a5)
            for(int k = 0; k < pq[p->priority]; k++){
    800029d0:	2685                	addiw	a3,a3,1
    800029d2:	19892703          	lw	a4,408(s2)
    800029d6:	00271793          	slli	a5,a4,0x2
    800029da:	97d2                	add	a5,a5,s4
    800029dc:	4307a603          	lw	a2,1072(a5)
    800029e0:	0585                	addi	a1,a1,1
    800029e2:	00c6dd63          	bge	a3,a2,800029fc <scheduler+0xaf8>
              if(PQ[p->priority][k] == p)
    800029e6:	00671793          	slli	a5,a4,0x6
    800029ea:	97b6                	add	a5,a5,a3
    800029ec:	078e                	slli	a5,a5,0x3
    800029ee:	97d6                	add	a5,a5,s5
    800029f0:	639c                	ld	a5,0(a5)
    800029f2:	fd2780e3          	beq	a5,s2,800029b2 <scheduler+0xaae>
              if(flag == 1 && k+1 < pq[p->priority])
    800029f6:	fd799de3          	bne	s3,s7,800029d0 <scheduler+0xacc>
    800029fa:	bf65                	j	800029b2 <scheduler+0xaae>
            pq[p->priority]--;
    800029fc:	070a                	slli	a4,a4,0x2
    800029fe:	9752                	add	a4,a4,s4
    80002a00:	367d                	addiw	a2,a2,-1
    80002a02:	42c72823          	sw	a2,1072(a4)
        while(p->state == RUNNABLE && p->clk_int < 15 && pq[0] == 0 && pq[1] == 0 && pq[2] == 0){
    80002a06:	01892703          	lw	a4,24(s2)
    80002a0a:	478d                	li	a5,3
    80002a0c:	06f71a63          	bne	a4,a5,80002a80 <scheduler+0xb7c>
    80002a10:	19c92703          	lw	a4,412(s2)
    80002a14:	47b9                	li	a5,14
    80002a16:	06e7c563          	blt	a5,a4,80002a80 <scheduler+0xb7c>
    80002a1a:	430a2983          	lw	s3,1072(s4)
    80002a1e:	434a2783          	lw	a5,1076(s4)
    80002a22:	00f9e9b3          	or	s3,s3,a5
    80002a26:	438a2783          	lw	a5,1080(s4)
    80002a2a:	00f9e9b3          	or	s3,s3,a5
    80002a2e:	06099263          	bnez	s3,80002a92 <scheduler+0xb8e>
          p->state = RUNNING;
    80002a32:	4791                	li	a5,4
    80002a34:	00f92c23          	sw	a5,24(s2)
          c->proc = p;
    80002a38:	032cb823          	sd	s2,48(s9)
          p->wait_time = 0;
    80002a3c:	1a092023          	sw	zero,416(s2)
          swtch(&c->context, &p->context);
    80002a40:	06090593          	addi	a1,s2,96
    80002a44:	856a                	mv	a0,s10
    80002a46:	00001097          	auipc	ra,0x1
    80002a4a:	94a080e7          	jalr	-1718(ra) # 80003390 <swtch>
          c->proc = 0;
    80002a4e:	020cb823          	sd	zero,48(s9)
          if(p->state == RUNNABLE){
    80002a52:	01892703          	lw	a4,24(s2)
    80002a56:	478d                	li	a5,3
    80002a58:	e4f701e3          	beq	a4,a5,8000289a <scheduler+0x996>
            p->vol_exit = 1;
    80002a5c:	1b792223          	sw	s7,420(s2)
            p->wait_time = 0;
    80002a60:	1a092023          	sw	zero,416(s2)
            p->clk_int = 0;
    80002a64:	18092e23          	sw	zero,412(s2)
            for(int k = 0; k < pq[p->priority]; k++){
    80002a68:	19892703          	lw	a4,408(s2)
    80002a6c:	00271793          	slli	a5,a4,0x2
    80002a70:	97d2                	add	a5,a5,s4
    80002a72:	4307a603          	lw	a2,1072(a5)
    80002a76:	f8c053e3          	blez	a2,800029fc <scheduler+0xaf8>
    80002a7a:	86ce                	mv	a3,s3
    80002a7c:	4585                	li	a1,1
    80002a7e:	b7a5                	j	800029e6 <scheduler+0xae2>
        if(p->clk_int == 15){
    80002a80:	19c92703          	lw	a4,412(s2)
    80002a84:	47bd                	li	a5,15
    80002a86:	00f71663          	bne	a4,a5,80002a92 <scheduler+0xb8e>
          p->wait_time = 0;
    80002a8a:	1a092023          	sw	zero,416(s2)
          p->clk_int = 0;
    80002a8e:	18092e23          	sw	zero,412(s2)
        release(&p->lock);
    80002a92:	854a                	mv	a0,s2
    80002a94:	ffffe097          	auipc	ra,0xffffe
    80002a98:	1f6080e7          	jalr	502(ra) # 80000c8a <release>
        if(pq[0] || pq[1] || pq[2])
    80002a9c:	430a2783          	lw	a5,1072(s4)
    80002aa0:	434a2703          	lw	a4,1076(s4)
    80002aa4:	8fd9                	or	a5,a5,a4
    80002aa6:	438a2703          	lw	a4,1080(s4)
    80002aaa:	8fd9                	or	a5,a5,a4
    80002aac:	ea079d63          	bnez	a5,80002166 <scheduler+0x262>
      for(int i = 0; i < pq[3] && pq[0] == 0 && pq[1] == 0 && pq[2] == 0; i++){
    80002ab0:	f7843783          	ld	a5,-136(s0)
    80002ab4:	2785                	addiw	a5,a5,1
    80002ab6:	873e                	mv	a4,a5
    80002ab8:	f6f43c23          	sd	a5,-136(s0)
    80002abc:	43ca2783          	lw	a5,1084(s4)
    80002ac0:	eaf75363          	bge	a4,a5,80002166 <scheduler+0x262>
    80002ac4:	f8043783          	ld	a5,-128(s0)
    80002ac8:	07a1                	addi	a5,a5,8
    80002aca:	f8f43023          	sd	a5,-128(s0)
    80002ace:	434a2783          	lw	a5,1076(s4)
    80002ad2:	438a2703          	lw	a4,1080(s4)
    80002ad6:	8fd9                	or	a5,a5,a4
    80002ad8:	e8079763          	bnez	a5,80002166 <scheduler+0x262>
        p = PQ[3][i];
    80002adc:	f8043783          	ld	a5,-128(s0)
    80002ae0:	0007b903          	ld	s2,0(a5)
        acquire(&p->lock);
    80002ae4:	854a                	mv	a0,s2
    80002ae6:	ffffe097          	auipc	ra,0xffffe
    80002aea:	0f0080e7          	jalr	240(ra) # 80000bd6 <acquire>
        while(p->state == RUNNABLE && p->clk_int < 15 && pq[0] == 0 && pq[1] == 0 && pq[2] == 0){
    80002aee:	01892703          	lw	a4,24(s2)
    80002af2:	478d                	li	a5,3
            p->vol_exit = 1;
    80002af4:	4b85                	li	s7,1
        while(p->state == RUNNABLE && p->clk_int < 15 && pq[0] == 0 && pq[1] == 0 && pq[2] == 0){
    80002af6:	f0f70de3          	beq	a4,a5,80002a10 <scheduler+0xb0c>
    80002afa:	b759                	j	80002a80 <scheduler+0xb7c>
    80002afc:	00010497          	auipc	s1,0x10
    80002b00:	ce448493          	addi	s1,s1,-796 # 800127e0 <proc>
    80002b04:	00016b17          	auipc	s6,0x16
    80002b08:	6dcb0b13          	addi	s6,s6,1756 # 800191e0 <tickslock>
        if(proc[j].state == RUNNABLE){
    80002b0c:	498d                	li	s3,3
          if(proc[j].vol_exit == 1){
    80002b0e:	4b85                	li	s7,1
    80002b10:	a811                	j	80002b24 <scheduler+0xc20>
        release(&proc[j].lock);
    80002b12:	854a                	mv	a0,s2
    80002b14:	ffffe097          	auipc	ra,0xffffe
    80002b18:	176080e7          	jalr	374(ra) # 80000c8a <release>
      for(int j = 0; j < NPROC; j++){
    80002b1c:	1a848493          	addi	s1,s1,424
    80002b20:	e5648363          	beq	s1,s6,80002166 <scheduler+0x262>
        acquire(&proc[j].lock);
    80002b24:	8926                	mv	s2,s1
    80002b26:	8526                	mv	a0,s1
    80002b28:	ffffe097          	auipc	ra,0xffffe
    80002b2c:	0ae080e7          	jalr	174(ra) # 80000bd6 <acquire>
        if(proc[j].state == RUNNABLE){
    80002b30:	4c9c                	lw	a5,24(s1)
    80002b32:	ff3790e3          	bne	a5,s3,80002b12 <scheduler+0xc0e>
          if(proc[j].vol_exit == 1){
    80002b36:	1a44a783          	lw	a5,420(s1)
    80002b3a:	fd779ce3          	bne	a5,s7,80002b12 <scheduler+0xc0e>
            proc[j].vol_exit = 0;
    80002b3e:	1a04a223          	sw	zero,420(s1)
            PQ[proc[j].priority][pq[proc[j].priority]++] = &proc[j];
    80002b42:	1984a783          	lw	a5,408(s1)
    80002b46:	00279713          	slli	a4,a5,0x2
    80002b4a:	9752                	add	a4,a4,s4
    80002b4c:	43072683          	lw	a3,1072(a4)
    80002b50:	0016861b          	addiw	a2,a3,1
    80002b54:	42c72823          	sw	a2,1072(a4)
    80002b58:	079a                	slli	a5,a5,0x6
    80002b5a:	97b6                	add	a5,a5,a3
    80002b5c:	078e                	slli	a5,a5,0x3
    80002b5e:	97d6                	add	a5,a5,s5
    80002b60:	e384                	sd	s1,0(a5)
    80002b62:	bf45                	j	80002b12 <scheduler+0xc0e>

0000000080002b64 <sched>:
{
    80002b64:	7179                	addi	sp,sp,-48
    80002b66:	f406                	sd	ra,40(sp)
    80002b68:	f022                	sd	s0,32(sp)
    80002b6a:	ec26                	sd	s1,24(sp)
    80002b6c:	e84a                	sd	s2,16(sp)
    80002b6e:	e44e                	sd	s3,8(sp)
    80002b70:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002b72:	fffff097          	auipc	ra,0xfffff
    80002b76:	e3a080e7          	jalr	-454(ra) # 800019ac <myproc>
    80002b7a:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    80002b7c:	ffffe097          	auipc	ra,0xffffe
    80002b80:	fe0080e7          	jalr	-32(ra) # 80000b5c <holding>
    80002b84:	c93d                	beqz	a0,80002bfa <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002b86:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002b88:	2781                	sext.w	a5,a5
    80002b8a:	079e                	slli	a5,a5,0x7
    80002b8c:	0000f717          	auipc	a4,0xf
    80002b90:	01470713          	addi	a4,a4,20 # 80011ba0 <pid_lock>
    80002b94:	97ba                	add	a5,a5,a4
    80002b96:	0a87a703          	lw	a4,168(a5)
    80002b9a:	4785                	li	a5,1
    80002b9c:	06f71763          	bne	a4,a5,80002c0a <sched+0xa6>
  if (p->state == RUNNING)
    80002ba0:	4c98                	lw	a4,24(s1)
    80002ba2:	4791                	li	a5,4
    80002ba4:	06f70b63          	beq	a4,a5,80002c1a <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ba8:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002bac:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002bae:	efb5                	bnez	a5,80002c2a <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002bb0:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002bb2:	0000f917          	auipc	s2,0xf
    80002bb6:	fee90913          	addi	s2,s2,-18 # 80011ba0 <pid_lock>
    80002bba:	2781                	sext.w	a5,a5
    80002bbc:	079e                	slli	a5,a5,0x7
    80002bbe:	97ca                	add	a5,a5,s2
    80002bc0:	0ac7a983          	lw	s3,172(a5)
    80002bc4:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002bc6:	2781                	sext.w	a5,a5
    80002bc8:	079e                	slli	a5,a5,0x7
    80002bca:	0000f597          	auipc	a1,0xf
    80002bce:	00e58593          	addi	a1,a1,14 # 80011bd8 <cpus+0x8>
    80002bd2:	95be                	add	a1,a1,a5
    80002bd4:	06048513          	addi	a0,s1,96
    80002bd8:	00000097          	auipc	ra,0x0
    80002bdc:	7b8080e7          	jalr	1976(ra) # 80003390 <swtch>
    80002be0:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    80002be2:	2781                	sext.w	a5,a5
    80002be4:	079e                	slli	a5,a5,0x7
    80002be6:	993e                	add	s2,s2,a5
    80002be8:	0b392623          	sw	s3,172(s2)
}
    80002bec:	70a2                	ld	ra,40(sp)
    80002bee:	7402                	ld	s0,32(sp)
    80002bf0:	64e2                	ld	s1,24(sp)
    80002bf2:	6942                	ld	s2,16(sp)
    80002bf4:	69a2                	ld	s3,8(sp)
    80002bf6:	6145                	addi	sp,sp,48
    80002bf8:	8082                	ret
    panic("sched p->lock");
    80002bfa:	00006517          	auipc	a0,0x6
    80002bfe:	62650513          	addi	a0,a0,1574 # 80009220 <digits+0x1e0>
    80002c02:	ffffe097          	auipc	ra,0xffffe
    80002c06:	93e080e7          	jalr	-1730(ra) # 80000540 <panic>
    panic("sched locks");
    80002c0a:	00006517          	auipc	a0,0x6
    80002c0e:	62650513          	addi	a0,a0,1574 # 80009230 <digits+0x1f0>
    80002c12:	ffffe097          	auipc	ra,0xffffe
    80002c16:	92e080e7          	jalr	-1746(ra) # 80000540 <panic>
    panic("sched running");
    80002c1a:	00006517          	auipc	a0,0x6
    80002c1e:	62650513          	addi	a0,a0,1574 # 80009240 <digits+0x200>
    80002c22:	ffffe097          	auipc	ra,0xffffe
    80002c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002c2a:	00006517          	auipc	a0,0x6
    80002c2e:	62650513          	addi	a0,a0,1574 # 80009250 <digits+0x210>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	90e080e7          	jalr	-1778(ra) # 80000540 <panic>

0000000080002c3a <yield>:
{
    80002c3a:	1101                	addi	sp,sp,-32
    80002c3c:	ec06                	sd	ra,24(sp)
    80002c3e:	e822                	sd	s0,16(sp)
    80002c40:	e426                	sd	s1,8(sp)
    80002c42:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002c44:	fffff097          	auipc	ra,0xfffff
    80002c48:	d68080e7          	jalr	-664(ra) # 800019ac <myproc>
    80002c4c:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002c4e:	ffffe097          	auipc	ra,0xffffe
    80002c52:	f88080e7          	jalr	-120(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002c56:	478d                	li	a5,3
    80002c58:	cc9c                	sw	a5,24(s1)
  sched();
    80002c5a:	00000097          	auipc	ra,0x0
    80002c5e:	f0a080e7          	jalr	-246(ra) # 80002b64 <sched>
  release(&p->lock);
    80002c62:	8526                	mv	a0,s1
    80002c64:	ffffe097          	auipc	ra,0xffffe
    80002c68:	026080e7          	jalr	38(ra) # 80000c8a <release>
}
    80002c6c:	60e2                	ld	ra,24(sp)
    80002c6e:	6442                	ld	s0,16(sp)
    80002c70:	64a2                	ld	s1,8(sp)
    80002c72:	6105                	addi	sp,sp,32
    80002c74:	8082                	ret

0000000080002c76 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    80002c76:	7179                	addi	sp,sp,-48
    80002c78:	f406                	sd	ra,40(sp)
    80002c7a:	f022                	sd	s0,32(sp)
    80002c7c:	ec26                	sd	s1,24(sp)
    80002c7e:	e84a                	sd	s2,16(sp)
    80002c80:	e44e                	sd	s3,8(sp)
    80002c82:	1800                	addi	s0,sp,48
    80002c84:	89aa                	mv	s3,a0
    80002c86:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c88:	fffff097          	auipc	ra,0xfffff
    80002c8c:	d24080e7          	jalr	-732(ra) # 800019ac <myproc>
    80002c90:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    80002c92:	ffffe097          	auipc	ra,0xffffe
    80002c96:	f44080e7          	jalr	-188(ra) # 80000bd6 <acquire>
  release(lk);
    80002c9a:	854a                	mv	a0,s2
    80002c9c:	ffffe097          	auipc	ra,0xffffe
    80002ca0:	fee080e7          	jalr	-18(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    80002ca4:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002ca8:	4789                	li	a5,2
    80002caa:	cc9c                	sw	a5,24(s1)

  sched();
    80002cac:	00000097          	auipc	ra,0x0
    80002cb0:	eb8080e7          	jalr	-328(ra) # 80002b64 <sched>

  // Tidy up.
  p->chan = 0;
    80002cb4:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002cb8:	8526                	mv	a0,s1
    80002cba:	ffffe097          	auipc	ra,0xffffe
    80002cbe:	fd0080e7          	jalr	-48(ra) # 80000c8a <release>
  acquire(lk);
    80002cc2:	854a                	mv	a0,s2
    80002cc4:	ffffe097          	auipc	ra,0xffffe
    80002cc8:	f12080e7          	jalr	-238(ra) # 80000bd6 <acquire>
}
    80002ccc:	70a2                	ld	ra,40(sp)
    80002cce:	7402                	ld	s0,32(sp)
    80002cd0:	64e2                	ld	s1,24(sp)
    80002cd2:	6942                	ld	s2,16(sp)
    80002cd4:	69a2                	ld	s3,8(sp)
    80002cd6:	6145                	addi	sp,sp,48
    80002cd8:	8082                	ret

0000000080002cda <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    80002cda:	7139                	addi	sp,sp,-64
    80002cdc:	fc06                	sd	ra,56(sp)
    80002cde:	f822                	sd	s0,48(sp)
    80002ce0:	f426                	sd	s1,40(sp)
    80002ce2:	f04a                	sd	s2,32(sp)
    80002ce4:	ec4e                	sd	s3,24(sp)
    80002ce6:	e852                	sd	s4,16(sp)
    80002ce8:	e456                	sd	s5,8(sp)
    80002cea:	0080                	addi	s0,sp,64
    80002cec:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002cee:	00010497          	auipc	s1,0x10
    80002cf2:	af248493          	addi	s1,s1,-1294 # 800127e0 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    80002cf6:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    80002cf8:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002cfa:	00016917          	auipc	s2,0x16
    80002cfe:	4e690913          	addi	s2,s2,1254 # 800191e0 <tickslock>
    80002d02:	a811                	j	80002d16 <wakeup+0x3c>
      }
      release(&p->lock);
    80002d04:	8526                	mv	a0,s1
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	f84080e7          	jalr	-124(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002d0e:	1a848493          	addi	s1,s1,424
    80002d12:	03248663          	beq	s1,s2,80002d3e <wakeup+0x64>
    if (p != myproc())
    80002d16:	fffff097          	auipc	ra,0xfffff
    80002d1a:	c96080e7          	jalr	-874(ra) # 800019ac <myproc>
    80002d1e:	fea488e3          	beq	s1,a0,80002d0e <wakeup+0x34>
      acquire(&p->lock);
    80002d22:	8526                	mv	a0,s1
    80002d24:	ffffe097          	auipc	ra,0xffffe
    80002d28:	eb2080e7          	jalr	-334(ra) # 80000bd6 <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002d2c:	4c9c                	lw	a5,24(s1)
    80002d2e:	fd379be3          	bne	a5,s3,80002d04 <wakeup+0x2a>
    80002d32:	709c                	ld	a5,32(s1)
    80002d34:	fd4798e3          	bne	a5,s4,80002d04 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002d38:	0154ac23          	sw	s5,24(s1)
    80002d3c:	b7e1                	j	80002d04 <wakeup+0x2a>
    }
  }
}
    80002d3e:	70e2                	ld	ra,56(sp)
    80002d40:	7442                	ld	s0,48(sp)
    80002d42:	74a2                	ld	s1,40(sp)
    80002d44:	7902                	ld	s2,32(sp)
    80002d46:	69e2                	ld	s3,24(sp)
    80002d48:	6a42                	ld	s4,16(sp)
    80002d4a:	6aa2                	ld	s5,8(sp)
    80002d4c:	6121                	addi	sp,sp,64
    80002d4e:	8082                	ret

0000000080002d50 <reparent>:
{
    80002d50:	7179                	addi	sp,sp,-48
    80002d52:	f406                	sd	ra,40(sp)
    80002d54:	f022                	sd	s0,32(sp)
    80002d56:	ec26                	sd	s1,24(sp)
    80002d58:	e84a                	sd	s2,16(sp)
    80002d5a:	e44e                	sd	s3,8(sp)
    80002d5c:	e052                	sd	s4,0(sp)
    80002d5e:	1800                	addi	s0,sp,48
    80002d60:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002d62:	00010497          	auipc	s1,0x10
    80002d66:	a7e48493          	addi	s1,s1,-1410 # 800127e0 <proc>
      pp->parent = initproc;
    80002d6a:	00007a17          	auipc	s4,0x7
    80002d6e:	bbea0a13          	addi	s4,s4,-1090 # 80009928 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    80002d72:	00016997          	auipc	s3,0x16
    80002d76:	46e98993          	addi	s3,s3,1134 # 800191e0 <tickslock>
    80002d7a:	a029                	j	80002d84 <reparent+0x34>
    80002d7c:	1a848493          	addi	s1,s1,424
    80002d80:	01348d63          	beq	s1,s3,80002d9a <reparent+0x4a>
    if (pp->parent == p)
    80002d84:	7c9c                	ld	a5,56(s1)
    80002d86:	ff279be3          	bne	a5,s2,80002d7c <reparent+0x2c>
      pp->parent = initproc;
    80002d8a:	000a3503          	ld	a0,0(s4)
    80002d8e:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002d90:	00000097          	auipc	ra,0x0
    80002d94:	f4a080e7          	jalr	-182(ra) # 80002cda <wakeup>
    80002d98:	b7d5                	j	80002d7c <reparent+0x2c>
}
    80002d9a:	70a2                	ld	ra,40(sp)
    80002d9c:	7402                	ld	s0,32(sp)
    80002d9e:	64e2                	ld	s1,24(sp)
    80002da0:	6942                	ld	s2,16(sp)
    80002da2:	69a2                	ld	s3,8(sp)
    80002da4:	6a02                	ld	s4,0(sp)
    80002da6:	6145                	addi	sp,sp,48
    80002da8:	8082                	ret

0000000080002daa <exit>:
{
    80002daa:	7179                	addi	sp,sp,-48
    80002dac:	f406                	sd	ra,40(sp)
    80002dae:	f022                	sd	s0,32(sp)
    80002db0:	ec26                	sd	s1,24(sp)
    80002db2:	e84a                	sd	s2,16(sp)
    80002db4:	e44e                	sd	s3,8(sp)
    80002db6:	e052                	sd	s4,0(sp)
    80002db8:	1800                	addi	s0,sp,48
    80002dba:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002dbc:	fffff097          	auipc	ra,0xfffff
    80002dc0:	bf0080e7          	jalr	-1040(ra) # 800019ac <myproc>
    80002dc4:	89aa                	mv	s3,a0
  if (p == initproc)
    80002dc6:	00007797          	auipc	a5,0x7
    80002dca:	b627b783          	ld	a5,-1182(a5) # 80009928 <initproc>
    80002dce:	0d050493          	addi	s1,a0,208
    80002dd2:	15050913          	addi	s2,a0,336
    80002dd6:	02a79363          	bne	a5,a0,80002dfc <exit+0x52>
    panic("init exiting");
    80002dda:	00006517          	auipc	a0,0x6
    80002dde:	48e50513          	addi	a0,a0,1166 # 80009268 <digits+0x228>
    80002de2:	ffffd097          	auipc	ra,0xffffd
    80002de6:	75e080e7          	jalr	1886(ra) # 80000540 <panic>
      fileclose(f);
    80002dea:	00002097          	auipc	ra,0x2
    80002dee:	6e0080e7          	jalr	1760(ra) # 800054ca <fileclose>
      p->ofile[fd] = 0;
    80002df2:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    80002df6:	04a1                	addi	s1,s1,8
    80002df8:	01248563          	beq	s1,s2,80002e02 <exit+0x58>
    if (p->ofile[fd])
    80002dfc:	6088                	ld	a0,0(s1)
    80002dfe:	f575                	bnez	a0,80002dea <exit+0x40>
    80002e00:	bfdd                	j	80002df6 <exit+0x4c>
  begin_op();
    80002e02:	00002097          	auipc	ra,0x2
    80002e06:	200080e7          	jalr	512(ra) # 80005002 <begin_op>
  iput(p->cwd);
    80002e0a:	1509b503          	ld	a0,336(s3)
    80002e0e:	00002097          	auipc	ra,0x2
    80002e12:	9e2080e7          	jalr	-1566(ra) # 800047f0 <iput>
  end_op();
    80002e16:	00002097          	auipc	ra,0x2
    80002e1a:	26a080e7          	jalr	618(ra) # 80005080 <end_op>
  p->cwd = 0;
    80002e1e:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    80002e22:	0000f497          	auipc	s1,0xf
    80002e26:	d9648493          	addi	s1,s1,-618 # 80011bb8 <wait_lock>
    80002e2a:	8526                	mv	a0,s1
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	daa080e7          	jalr	-598(ra) # 80000bd6 <acquire>
  reparent(p);
    80002e34:	854e                	mv	a0,s3
    80002e36:	00000097          	auipc	ra,0x0
    80002e3a:	f1a080e7          	jalr	-230(ra) # 80002d50 <reparent>
  wakeup(p->parent);
    80002e3e:	0389b503          	ld	a0,56(s3)
    80002e42:	00000097          	auipc	ra,0x0
    80002e46:	e98080e7          	jalr	-360(ra) # 80002cda <wakeup>
  acquire(&p->lock);
    80002e4a:	854e                	mv	a0,s3
    80002e4c:	ffffe097          	auipc	ra,0xffffe
    80002e50:	d8a080e7          	jalr	-630(ra) # 80000bd6 <acquire>
  p->xstate = status;
    80002e54:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002e58:	4795                	li	a5,5
    80002e5a:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002e5e:	00007797          	auipc	a5,0x7
    80002e62:	ad27a783          	lw	a5,-1326(a5) # 80009930 <ticks>
    80002e66:	16f9a823          	sw	a5,368(s3)
  release(&wait_lock);
    80002e6a:	8526                	mv	a0,s1
    80002e6c:	ffffe097          	auipc	ra,0xffffe
    80002e70:	e1e080e7          	jalr	-482(ra) # 80000c8a <release>
  sched();
    80002e74:	00000097          	auipc	ra,0x0
    80002e78:	cf0080e7          	jalr	-784(ra) # 80002b64 <sched>
  panic("zombie exit");
    80002e7c:	00006517          	auipc	a0,0x6
    80002e80:	3fc50513          	addi	a0,a0,1020 # 80009278 <digits+0x238>
    80002e84:	ffffd097          	auipc	ra,0xffffd
    80002e88:	6bc080e7          	jalr	1724(ra) # 80000540 <panic>

0000000080002e8c <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002e8c:	7179                	addi	sp,sp,-48
    80002e8e:	f406                	sd	ra,40(sp)
    80002e90:	f022                	sd	s0,32(sp)
    80002e92:	ec26                	sd	s1,24(sp)
    80002e94:	e84a                	sd	s2,16(sp)
    80002e96:	e44e                	sd	s3,8(sp)
    80002e98:	1800                	addi	s0,sp,48
    80002e9a:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002e9c:	00010497          	auipc	s1,0x10
    80002ea0:	94448493          	addi	s1,s1,-1724 # 800127e0 <proc>
    80002ea4:	00016997          	auipc	s3,0x16
    80002ea8:	33c98993          	addi	s3,s3,828 # 800191e0 <tickslock>
  {
    acquire(&p->lock);
    80002eac:	8526                	mv	a0,s1
    80002eae:	ffffe097          	auipc	ra,0xffffe
    80002eb2:	d28080e7          	jalr	-728(ra) # 80000bd6 <acquire>
    if (p->pid == pid)
    80002eb6:	589c                	lw	a5,48(s1)
    80002eb8:	01278d63          	beq	a5,s2,80002ed2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002ebc:	8526                	mv	a0,s1
    80002ebe:	ffffe097          	auipc	ra,0xffffe
    80002ec2:	dcc080e7          	jalr	-564(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002ec6:	1a848493          	addi	s1,s1,424
    80002eca:	ff3491e3          	bne	s1,s3,80002eac <kill+0x20>
  }
  return -1;
    80002ece:	557d                	li	a0,-1
    80002ed0:	a829                	j	80002eea <kill+0x5e>
      p->killed = 1;
    80002ed2:	4785                	li	a5,1
    80002ed4:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    80002ed6:	4c98                	lw	a4,24(s1)
    80002ed8:	4789                	li	a5,2
    80002eda:	00f70f63          	beq	a4,a5,80002ef8 <kill+0x6c>
      release(&p->lock);
    80002ede:	8526                	mv	a0,s1
    80002ee0:	ffffe097          	auipc	ra,0xffffe
    80002ee4:	daa080e7          	jalr	-598(ra) # 80000c8a <release>
      return 0;
    80002ee8:	4501                	li	a0,0
}
    80002eea:	70a2                	ld	ra,40(sp)
    80002eec:	7402                	ld	s0,32(sp)
    80002eee:	64e2                	ld	s1,24(sp)
    80002ef0:	6942                	ld	s2,16(sp)
    80002ef2:	69a2                	ld	s3,8(sp)
    80002ef4:	6145                	addi	sp,sp,48
    80002ef6:	8082                	ret
        p->state = RUNNABLE;
    80002ef8:	478d                	li	a5,3
    80002efa:	cc9c                	sw	a5,24(s1)
    80002efc:	b7cd                	j	80002ede <kill+0x52>

0000000080002efe <setkilled>:

void setkilled(struct proc *p)
{
    80002efe:	1101                	addi	sp,sp,-32
    80002f00:	ec06                	sd	ra,24(sp)
    80002f02:	e822                	sd	s0,16(sp)
    80002f04:	e426                	sd	s1,8(sp)
    80002f06:	1000                	addi	s0,sp,32
    80002f08:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002f0a:	ffffe097          	auipc	ra,0xffffe
    80002f0e:	ccc080e7          	jalr	-820(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002f12:	4785                	li	a5,1
    80002f14:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002f16:	8526                	mv	a0,s1
    80002f18:	ffffe097          	auipc	ra,0xffffe
    80002f1c:	d72080e7          	jalr	-654(ra) # 80000c8a <release>
}
    80002f20:	60e2                	ld	ra,24(sp)
    80002f22:	6442                	ld	s0,16(sp)
    80002f24:	64a2                	ld	s1,8(sp)
    80002f26:	6105                	addi	sp,sp,32
    80002f28:	8082                	ret

0000000080002f2a <killed>:

int killed(struct proc *p)
{
    80002f2a:	1101                	addi	sp,sp,-32
    80002f2c:	ec06                	sd	ra,24(sp)
    80002f2e:	e822                	sd	s0,16(sp)
    80002f30:	e426                	sd	s1,8(sp)
    80002f32:	e04a                	sd	s2,0(sp)
    80002f34:	1000                	addi	s0,sp,32
    80002f36:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002f38:	ffffe097          	auipc	ra,0xffffe
    80002f3c:	c9e080e7          	jalr	-866(ra) # 80000bd6 <acquire>
  k = p->killed;
    80002f40:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002f44:	8526                	mv	a0,s1
    80002f46:	ffffe097          	auipc	ra,0xffffe
    80002f4a:	d44080e7          	jalr	-700(ra) # 80000c8a <release>
  return k;
}
    80002f4e:	854a                	mv	a0,s2
    80002f50:	60e2                	ld	ra,24(sp)
    80002f52:	6442                	ld	s0,16(sp)
    80002f54:	64a2                	ld	s1,8(sp)
    80002f56:	6902                	ld	s2,0(sp)
    80002f58:	6105                	addi	sp,sp,32
    80002f5a:	8082                	ret

0000000080002f5c <wait>:
{
    80002f5c:	715d                	addi	sp,sp,-80
    80002f5e:	e486                	sd	ra,72(sp)
    80002f60:	e0a2                	sd	s0,64(sp)
    80002f62:	fc26                	sd	s1,56(sp)
    80002f64:	f84a                	sd	s2,48(sp)
    80002f66:	f44e                	sd	s3,40(sp)
    80002f68:	f052                	sd	s4,32(sp)
    80002f6a:	ec56                	sd	s5,24(sp)
    80002f6c:	e85a                	sd	s6,16(sp)
    80002f6e:	e45e                	sd	s7,8(sp)
    80002f70:	e062                	sd	s8,0(sp)
    80002f72:	0880                	addi	s0,sp,80
    80002f74:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002f76:	fffff097          	auipc	ra,0xfffff
    80002f7a:	a36080e7          	jalr	-1482(ra) # 800019ac <myproc>
    80002f7e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002f80:	0000f517          	auipc	a0,0xf
    80002f84:	c3850513          	addi	a0,a0,-968 # 80011bb8 <wait_lock>
    80002f88:	ffffe097          	auipc	ra,0xffffe
    80002f8c:	c4e080e7          	jalr	-946(ra) # 80000bd6 <acquire>
    havekids = 0;
    80002f90:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    80002f92:	4a15                	li	s4,5
        havekids = 1;
    80002f94:	4a85                	li	s5,1
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002f96:	00016997          	auipc	s3,0x16
    80002f9a:	24a98993          	addi	s3,s3,586 # 800191e0 <tickslock>
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002f9e:	0000fc17          	auipc	s8,0xf
    80002fa2:	c1ac0c13          	addi	s8,s8,-998 # 80011bb8 <wait_lock>
    havekids = 0;
    80002fa6:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002fa8:	00010497          	auipc	s1,0x10
    80002fac:	83848493          	addi	s1,s1,-1992 # 800127e0 <proc>
    80002fb0:	a0bd                	j	8000301e <wait+0xc2>
          pid = pp->pid;
    80002fb2:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    80002fb6:	000b0e63          	beqz	s6,80002fd2 <wait+0x76>
    80002fba:	4691                	li	a3,4
    80002fbc:	02c48613          	addi	a2,s1,44
    80002fc0:	85da                	mv	a1,s6
    80002fc2:	05093503          	ld	a0,80(s2)
    80002fc6:	ffffe097          	auipc	ra,0xffffe
    80002fca:	6a6080e7          	jalr	1702(ra) # 8000166c <copyout>
    80002fce:	02054563          	bltz	a0,80002ff8 <wait+0x9c>
          freeproc(pp);
    80002fd2:	8526                	mv	a0,s1
    80002fd4:	fffff097          	auipc	ra,0xfffff
    80002fd8:	b8a080e7          	jalr	-1142(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    80002fdc:	8526                	mv	a0,s1
    80002fde:	ffffe097          	auipc	ra,0xffffe
    80002fe2:	cac080e7          	jalr	-852(ra) # 80000c8a <release>
          release(&wait_lock);
    80002fe6:	0000f517          	auipc	a0,0xf
    80002fea:	bd250513          	addi	a0,a0,-1070 # 80011bb8 <wait_lock>
    80002fee:	ffffe097          	auipc	ra,0xffffe
    80002ff2:	c9c080e7          	jalr	-868(ra) # 80000c8a <release>
          return pid;
    80002ff6:	a0b5                	j	80003062 <wait+0x106>
            release(&pp->lock);
    80002ff8:	8526                	mv	a0,s1
    80002ffa:	ffffe097          	auipc	ra,0xffffe
    80002ffe:	c90080e7          	jalr	-880(ra) # 80000c8a <release>
            release(&wait_lock);
    80003002:	0000f517          	auipc	a0,0xf
    80003006:	bb650513          	addi	a0,a0,-1098 # 80011bb8 <wait_lock>
    8000300a:	ffffe097          	auipc	ra,0xffffe
    8000300e:	c80080e7          	jalr	-896(ra) # 80000c8a <release>
            return -1;
    80003012:	59fd                	li	s3,-1
    80003014:	a0b9                	j	80003062 <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80003016:	1a848493          	addi	s1,s1,424
    8000301a:	03348463          	beq	s1,s3,80003042 <wait+0xe6>
      if (pp->parent == p)
    8000301e:	7c9c                	ld	a5,56(s1)
    80003020:	ff279be3          	bne	a5,s2,80003016 <wait+0xba>
        acquire(&pp->lock);
    80003024:	8526                	mv	a0,s1
    80003026:	ffffe097          	auipc	ra,0xffffe
    8000302a:	bb0080e7          	jalr	-1104(ra) # 80000bd6 <acquire>
        if (pp->state == ZOMBIE)
    8000302e:	4c9c                	lw	a5,24(s1)
    80003030:	f94781e3          	beq	a5,s4,80002fb2 <wait+0x56>
        release(&pp->lock);
    80003034:	8526                	mv	a0,s1
    80003036:	ffffe097          	auipc	ra,0xffffe
    8000303a:	c54080e7          	jalr	-940(ra) # 80000c8a <release>
        havekids = 1;
    8000303e:	8756                	mv	a4,s5
    80003040:	bfd9                	j	80003016 <wait+0xba>
    if (!havekids || killed(p))
    80003042:	c719                	beqz	a4,80003050 <wait+0xf4>
    80003044:	854a                	mv	a0,s2
    80003046:	00000097          	auipc	ra,0x0
    8000304a:	ee4080e7          	jalr	-284(ra) # 80002f2a <killed>
    8000304e:	c51d                	beqz	a0,8000307c <wait+0x120>
      release(&wait_lock);
    80003050:	0000f517          	auipc	a0,0xf
    80003054:	b6850513          	addi	a0,a0,-1176 # 80011bb8 <wait_lock>
    80003058:	ffffe097          	auipc	ra,0xffffe
    8000305c:	c32080e7          	jalr	-974(ra) # 80000c8a <release>
      return -1;
    80003060:	59fd                	li	s3,-1
}
    80003062:	854e                	mv	a0,s3
    80003064:	60a6                	ld	ra,72(sp)
    80003066:	6406                	ld	s0,64(sp)
    80003068:	74e2                	ld	s1,56(sp)
    8000306a:	7942                	ld	s2,48(sp)
    8000306c:	79a2                	ld	s3,40(sp)
    8000306e:	7a02                	ld	s4,32(sp)
    80003070:	6ae2                	ld	s5,24(sp)
    80003072:	6b42                	ld	s6,16(sp)
    80003074:	6ba2                	ld	s7,8(sp)
    80003076:	6c02                	ld	s8,0(sp)
    80003078:	6161                	addi	sp,sp,80
    8000307a:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    8000307c:	85e2                	mv	a1,s8
    8000307e:	854a                	mv	a0,s2
    80003080:	00000097          	auipc	ra,0x0
    80003084:	bf6080e7          	jalr	-1034(ra) # 80002c76 <sleep>
    havekids = 0;
    80003088:	bf39                	j	80002fa6 <wait+0x4a>

000000008000308a <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    8000308a:	7179                	addi	sp,sp,-48
    8000308c:	f406                	sd	ra,40(sp)
    8000308e:	f022                	sd	s0,32(sp)
    80003090:	ec26                	sd	s1,24(sp)
    80003092:	e84a                	sd	s2,16(sp)
    80003094:	e44e                	sd	s3,8(sp)
    80003096:	e052                	sd	s4,0(sp)
    80003098:	1800                	addi	s0,sp,48
    8000309a:	84aa                	mv	s1,a0
    8000309c:	892e                	mv	s2,a1
    8000309e:	89b2                	mv	s3,a2
    800030a0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030a2:	fffff097          	auipc	ra,0xfffff
    800030a6:	90a080e7          	jalr	-1782(ra) # 800019ac <myproc>
  if (user_dst)
    800030aa:	c08d                	beqz	s1,800030cc <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    800030ac:	86d2                	mv	a3,s4
    800030ae:	864e                	mv	a2,s3
    800030b0:	85ca                	mv	a1,s2
    800030b2:	6928                	ld	a0,80(a0)
    800030b4:	ffffe097          	auipc	ra,0xffffe
    800030b8:	5b8080e7          	jalr	1464(ra) # 8000166c <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800030bc:	70a2                	ld	ra,40(sp)
    800030be:	7402                	ld	s0,32(sp)
    800030c0:	64e2                	ld	s1,24(sp)
    800030c2:	6942                	ld	s2,16(sp)
    800030c4:	69a2                	ld	s3,8(sp)
    800030c6:	6a02                	ld	s4,0(sp)
    800030c8:	6145                	addi	sp,sp,48
    800030ca:	8082                	ret
    memmove((char *)dst, src, len);
    800030cc:	000a061b          	sext.w	a2,s4
    800030d0:	85ce                	mv	a1,s3
    800030d2:	854a                	mv	a0,s2
    800030d4:	ffffe097          	auipc	ra,0xffffe
    800030d8:	c5a080e7          	jalr	-934(ra) # 80000d2e <memmove>
    return 0;
    800030dc:	8526                	mv	a0,s1
    800030de:	bff9                	j	800030bc <either_copyout+0x32>

00000000800030e0 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800030e0:	7179                	addi	sp,sp,-48
    800030e2:	f406                	sd	ra,40(sp)
    800030e4:	f022                	sd	s0,32(sp)
    800030e6:	ec26                	sd	s1,24(sp)
    800030e8:	e84a                	sd	s2,16(sp)
    800030ea:	e44e                	sd	s3,8(sp)
    800030ec:	e052                	sd	s4,0(sp)
    800030ee:	1800                	addi	s0,sp,48
    800030f0:	892a                	mv	s2,a0
    800030f2:	84ae                	mv	s1,a1
    800030f4:	89b2                	mv	s3,a2
    800030f6:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800030f8:	fffff097          	auipc	ra,0xfffff
    800030fc:	8b4080e7          	jalr	-1868(ra) # 800019ac <myproc>
  if (user_src)
    80003100:	c08d                	beqz	s1,80003122 <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80003102:	86d2                	mv	a3,s4
    80003104:	864e                	mv	a2,s3
    80003106:	85ca                	mv	a1,s2
    80003108:	6928                	ld	a0,80(a0)
    8000310a:	ffffe097          	auipc	ra,0xffffe
    8000310e:	5ee080e7          	jalr	1518(ra) # 800016f8 <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80003112:	70a2                	ld	ra,40(sp)
    80003114:	7402                	ld	s0,32(sp)
    80003116:	64e2                	ld	s1,24(sp)
    80003118:	6942                	ld	s2,16(sp)
    8000311a:	69a2                	ld	s3,8(sp)
    8000311c:	6a02                	ld	s4,0(sp)
    8000311e:	6145                	addi	sp,sp,48
    80003120:	8082                	ret
    memmove(dst, (char *)src, len);
    80003122:	000a061b          	sext.w	a2,s4
    80003126:	85ce                	mv	a1,s3
    80003128:	854a                	mv	a0,s2
    8000312a:	ffffe097          	auipc	ra,0xffffe
    8000312e:	c04080e7          	jalr	-1020(ra) # 80000d2e <memmove>
    return 0;
    80003132:	8526                	mv	a0,s1
    80003134:	bff9                	j	80003112 <either_copyin+0x32>

0000000080003136 <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80003136:	715d                	addi	sp,sp,-80
    80003138:	e486                	sd	ra,72(sp)
    8000313a:	e0a2                	sd	s0,64(sp)
    8000313c:	fc26                	sd	s1,56(sp)
    8000313e:	f84a                	sd	s2,48(sp)
    80003140:	f44e                	sd	s3,40(sp)
    80003142:	f052                	sd	s4,32(sp)
    80003144:	ec56                	sd	s5,24(sp)
    80003146:	e85a                	sd	s6,16(sp)
    80003148:	e45e                	sd	s7,8(sp)
    8000314a:	0880                	addi	s0,sp,80
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  struct proc *p;
  char *state;

  printf("\n");
    8000314c:	00006517          	auipc	a0,0x6
    80003150:	f7c50513          	addi	a0,a0,-132 # 800090c8 <digits+0x88>
    80003154:	ffffd097          	auipc	ra,0xffffd
    80003158:	436080e7          	jalr	1078(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    8000315c:	0000f497          	auipc	s1,0xf
    80003160:	7dc48493          	addi	s1,s1,2012 # 80012938 <proc+0x158>
    80003164:	00016917          	auipc	s2,0x16
    80003168:	1d490913          	addi	s2,s2,468 # 80019338 <bcache+0x140>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000316c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000316e:	00006997          	auipc	s3,0x6
    80003172:	11a98993          	addi	s3,s3,282 # 80009288 <digits+0x248>
    printf("%d %s %s", p->pid, state, p->name);
    80003176:	00006a97          	auipc	s5,0x6
    8000317a:	11aa8a93          	addi	s5,s5,282 # 80009290 <digits+0x250>
    printf("\n");
    8000317e:	00006a17          	auipc	s4,0x6
    80003182:	f4aa0a13          	addi	s4,s4,-182 # 800090c8 <digits+0x88>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80003186:	00006b97          	auipc	s7,0x6
    8000318a:	14ab8b93          	addi	s7,s7,330 # 800092d0 <states.0>
    8000318e:	a00d                	j	800031b0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80003190:	ed86a583          	lw	a1,-296(a3)
    80003194:	8556                	mv	a0,s5
    80003196:	ffffd097          	auipc	ra,0xffffd
    8000319a:	3f4080e7          	jalr	1012(ra) # 8000058a <printf>
    printf("\n");
    8000319e:	8552                	mv	a0,s4
    800031a0:	ffffd097          	auipc	ra,0xffffd
    800031a4:	3ea080e7          	jalr	1002(ra) # 8000058a <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    800031a8:	1a848493          	addi	s1,s1,424
    800031ac:	03248263          	beq	s1,s2,800031d0 <procdump+0x9a>
    if (p->state == UNUSED)
    800031b0:	86a6                	mv	a3,s1
    800031b2:	ec04a783          	lw	a5,-320(s1)
    800031b6:	dbed                	beqz	a5,800031a8 <procdump+0x72>
      state = "???";
    800031b8:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800031ba:	fcfb6be3          	bltu	s6,a5,80003190 <procdump+0x5a>
    800031be:	02079713          	slli	a4,a5,0x20
    800031c2:	01d75793          	srli	a5,a4,0x1d
    800031c6:	97de                	add	a5,a5,s7
    800031c8:	6390                	ld	a2,0(a5)
    800031ca:	f279                	bnez	a2,80003190 <procdump+0x5a>
      state = "???";
    800031cc:	864e                	mv	a2,s3
    800031ce:	b7c9                	j	80003190 <procdump+0x5a>
  }
}
    800031d0:	60a6                	ld	ra,72(sp)
    800031d2:	6406                	ld	s0,64(sp)
    800031d4:	74e2                	ld	s1,56(sp)
    800031d6:	7942                	ld	s2,48(sp)
    800031d8:	79a2                	ld	s3,40(sp)
    800031da:	7a02                	ld	s4,32(sp)
    800031dc:	6ae2                	ld	s5,24(sp)
    800031de:	6b42                	ld	s6,16(sp)
    800031e0:	6ba2                	ld	s7,8(sp)
    800031e2:	6161                	addi	sp,sp,80
    800031e4:	8082                	ret

00000000800031e6 <waitx>:

// waitx
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    800031e6:	711d                	addi	sp,sp,-96
    800031e8:	ec86                	sd	ra,88(sp)
    800031ea:	e8a2                	sd	s0,80(sp)
    800031ec:	e4a6                	sd	s1,72(sp)
    800031ee:	e0ca                	sd	s2,64(sp)
    800031f0:	fc4e                	sd	s3,56(sp)
    800031f2:	f852                	sd	s4,48(sp)
    800031f4:	f456                	sd	s5,40(sp)
    800031f6:	f05a                	sd	s6,32(sp)
    800031f8:	ec5e                	sd	s7,24(sp)
    800031fa:	e862                	sd	s8,16(sp)
    800031fc:	e466                	sd	s9,8(sp)
    800031fe:	e06a                	sd	s10,0(sp)
    80003200:	1080                	addi	s0,sp,96
    80003202:	8b2a                	mv	s6,a0
    80003204:	8bae                	mv	s7,a1
    80003206:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80003208:	ffffe097          	auipc	ra,0xffffe
    8000320c:	7a4080e7          	jalr	1956(ra) # 800019ac <myproc>
    80003210:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80003212:	0000f517          	auipc	a0,0xf
    80003216:	9a650513          	addi	a0,a0,-1626 # 80011bb8 <wait_lock>
    8000321a:	ffffe097          	auipc	ra,0xffffe
    8000321e:	9bc080e7          	jalr	-1604(ra) # 80000bd6 <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80003222:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80003224:	4a15                	li	s4,5
        havekids = 1;
    80003226:	4a85                	li	s5,1
    for (np = proc; np < &proc[NPROC]; np++)
    80003228:	00016997          	auipc	s3,0x16
    8000322c:	fb898993          	addi	s3,s3,-72 # 800191e0 <tickslock>
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80003230:	0000fd17          	auipc	s10,0xf
    80003234:	988d0d13          	addi	s10,s10,-1656 # 80011bb8 <wait_lock>
    havekids = 0;
    80003238:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    8000323a:	0000f497          	auipc	s1,0xf
    8000323e:	5a648493          	addi	s1,s1,1446 # 800127e0 <proc>
    80003242:	a059                	j	800032c8 <waitx+0xe2>
          pid = np->pid;
    80003244:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80003248:	1684a783          	lw	a5,360(s1)
    8000324c:	00fc2023          	sw	a5,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80003250:	16c4a703          	lw	a4,364(s1)
    80003254:	9f3d                	addw	a4,a4,a5
    80003256:	1704a783          	lw	a5,368(s1)
    8000325a:	9f99                	subw	a5,a5,a4
    8000325c:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80003260:	000b0e63          	beqz	s6,8000327c <waitx+0x96>
    80003264:	4691                	li	a3,4
    80003266:	02c48613          	addi	a2,s1,44
    8000326a:	85da                	mv	a1,s6
    8000326c:	05093503          	ld	a0,80(s2)
    80003270:	ffffe097          	auipc	ra,0xffffe
    80003274:	3fc080e7          	jalr	1020(ra) # 8000166c <copyout>
    80003278:	02054563          	bltz	a0,800032a2 <waitx+0xbc>
          freeproc(np);
    8000327c:	8526                	mv	a0,s1
    8000327e:	fffff097          	auipc	ra,0xfffff
    80003282:	8e0080e7          	jalr	-1824(ra) # 80001b5e <freeproc>
          release(&np->lock);
    80003286:	8526                	mv	a0,s1
    80003288:	ffffe097          	auipc	ra,0xffffe
    8000328c:	a02080e7          	jalr	-1534(ra) # 80000c8a <release>
          release(&wait_lock);
    80003290:	0000f517          	auipc	a0,0xf
    80003294:	92850513          	addi	a0,a0,-1752 # 80011bb8 <wait_lock>
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	9f2080e7          	jalr	-1550(ra) # 80000c8a <release>
          return pid;
    800032a0:	a09d                	j	80003306 <waitx+0x120>
            release(&np->lock);
    800032a2:	8526                	mv	a0,s1
    800032a4:	ffffe097          	auipc	ra,0xffffe
    800032a8:	9e6080e7          	jalr	-1562(ra) # 80000c8a <release>
            release(&wait_lock);
    800032ac:	0000f517          	auipc	a0,0xf
    800032b0:	90c50513          	addi	a0,a0,-1780 # 80011bb8 <wait_lock>
    800032b4:	ffffe097          	auipc	ra,0xffffe
    800032b8:	9d6080e7          	jalr	-1578(ra) # 80000c8a <release>
            return -1;
    800032bc:	59fd                	li	s3,-1
    800032be:	a0a1                	j	80003306 <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    800032c0:	1a848493          	addi	s1,s1,424
    800032c4:	03348463          	beq	s1,s3,800032ec <waitx+0x106>
      if (np->parent == p)
    800032c8:	7c9c                	ld	a5,56(s1)
    800032ca:	ff279be3          	bne	a5,s2,800032c0 <waitx+0xda>
        acquire(&np->lock);
    800032ce:	8526                	mv	a0,s1
    800032d0:	ffffe097          	auipc	ra,0xffffe
    800032d4:	906080e7          	jalr	-1786(ra) # 80000bd6 <acquire>
        if (np->state == ZOMBIE)
    800032d8:	4c9c                	lw	a5,24(s1)
    800032da:	f74785e3          	beq	a5,s4,80003244 <waitx+0x5e>
        release(&np->lock);
    800032de:	8526                	mv	a0,s1
    800032e0:	ffffe097          	auipc	ra,0xffffe
    800032e4:	9aa080e7          	jalr	-1622(ra) # 80000c8a <release>
        havekids = 1;
    800032e8:	8756                	mv	a4,s5
    800032ea:	bfd9                	j	800032c0 <waitx+0xda>
    if (!havekids || p->killed)
    800032ec:	c701                	beqz	a4,800032f4 <waitx+0x10e>
    800032ee:	02892783          	lw	a5,40(s2)
    800032f2:	cb8d                	beqz	a5,80003324 <waitx+0x13e>
      release(&wait_lock);
    800032f4:	0000f517          	auipc	a0,0xf
    800032f8:	8c450513          	addi	a0,a0,-1852 # 80011bb8 <wait_lock>
    800032fc:	ffffe097          	auipc	ra,0xffffe
    80003300:	98e080e7          	jalr	-1650(ra) # 80000c8a <release>
      return -1;
    80003304:	59fd                	li	s3,-1
  }
}
    80003306:	854e                	mv	a0,s3
    80003308:	60e6                	ld	ra,88(sp)
    8000330a:	6446                	ld	s0,80(sp)
    8000330c:	64a6                	ld	s1,72(sp)
    8000330e:	6906                	ld	s2,64(sp)
    80003310:	79e2                	ld	s3,56(sp)
    80003312:	7a42                	ld	s4,48(sp)
    80003314:	7aa2                	ld	s5,40(sp)
    80003316:	7b02                	ld	s6,32(sp)
    80003318:	6be2                	ld	s7,24(sp)
    8000331a:	6c42                	ld	s8,16(sp)
    8000331c:	6ca2                	ld	s9,8(sp)
    8000331e:	6d02                	ld	s10,0(sp)
    80003320:	6125                	addi	sp,sp,96
    80003322:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80003324:	85ea                	mv	a1,s10
    80003326:	854a                	mv	a0,s2
    80003328:	00000097          	auipc	ra,0x0
    8000332c:	94e080e7          	jalr	-1714(ra) # 80002c76 <sleep>
    havekids = 0;
    80003330:	b721                	j	80003238 <waitx+0x52>

0000000080003332 <update_time>:

void update_time()
{
    80003332:	7179                	addi	sp,sp,-48
    80003334:	f406                	sd	ra,40(sp)
    80003336:	f022                	sd	s0,32(sp)
    80003338:	ec26                	sd	s1,24(sp)
    8000333a:	e84a                	sd	s2,16(sp)
    8000333c:	e44e                	sd	s3,8(sp)
    8000333e:	1800                	addi	s0,sp,48
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80003340:	0000f497          	auipc	s1,0xf
    80003344:	4a048493          	addi	s1,s1,1184 # 800127e0 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80003348:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    8000334a:	00016917          	auipc	s2,0x16
    8000334e:	e9690913          	addi	s2,s2,-362 # 800191e0 <tickslock>
    80003352:	a811                	j	80003366 <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80003354:	8526                	mv	a0,s1
    80003356:	ffffe097          	auipc	ra,0xffffe
    8000335a:	934080e7          	jalr	-1740(ra) # 80000c8a <release>
  for (p = proc; p < &proc[NPROC]; p++)
    8000335e:	1a848493          	addi	s1,s1,424
    80003362:	03248063          	beq	s1,s2,80003382 <update_time+0x50>
    acquire(&p->lock);
    80003366:	8526                	mv	a0,s1
    80003368:	ffffe097          	auipc	ra,0xffffe
    8000336c:	86e080e7          	jalr	-1938(ra) # 80000bd6 <acquire>
    if (p->state == RUNNING)
    80003370:	4c9c                	lw	a5,24(s1)
    80003372:	ff3791e3          	bne	a5,s3,80003354 <update_time+0x22>
      p->rtime++;
    80003376:	1684a783          	lw	a5,360(s1)
    8000337a:	2785                	addiw	a5,a5,1
    8000337c:	16f4a423          	sw	a5,360(s1)
    80003380:	bfd1                	j	80003354 <update_time+0x22>
  }
    80003382:	70a2                	ld	ra,40(sp)
    80003384:	7402                	ld	s0,32(sp)
    80003386:	64e2                	ld	s1,24(sp)
    80003388:	6942                	ld	s2,16(sp)
    8000338a:	69a2                	ld	s3,8(sp)
    8000338c:	6145                	addi	sp,sp,48
    8000338e:	8082                	ret

0000000080003390 <swtch>:
    80003390:	00153023          	sd	ra,0(a0)
    80003394:	00253423          	sd	sp,8(a0)
    80003398:	e900                	sd	s0,16(a0)
    8000339a:	ed04                	sd	s1,24(a0)
    8000339c:	03253023          	sd	s2,32(a0)
    800033a0:	03353423          	sd	s3,40(a0)
    800033a4:	03453823          	sd	s4,48(a0)
    800033a8:	03553c23          	sd	s5,56(a0)
    800033ac:	05653023          	sd	s6,64(a0)
    800033b0:	05753423          	sd	s7,72(a0)
    800033b4:	05853823          	sd	s8,80(a0)
    800033b8:	05953c23          	sd	s9,88(a0)
    800033bc:	07a53023          	sd	s10,96(a0)
    800033c0:	07b53423          	sd	s11,104(a0)
    800033c4:	0005b083          	ld	ra,0(a1)
    800033c8:	0085b103          	ld	sp,8(a1)
    800033cc:	6980                	ld	s0,16(a1)
    800033ce:	6d84                	ld	s1,24(a1)
    800033d0:	0205b903          	ld	s2,32(a1)
    800033d4:	0285b983          	ld	s3,40(a1)
    800033d8:	0305ba03          	ld	s4,48(a1)
    800033dc:	0385ba83          	ld	s5,56(a1)
    800033e0:	0405bb03          	ld	s6,64(a1)
    800033e4:	0485bb83          	ld	s7,72(a1)
    800033e8:	0505bc03          	ld	s8,80(a1)
    800033ec:	0585bc83          	ld	s9,88(a1)
    800033f0:	0605bd03          	ld	s10,96(a1)
    800033f4:	0685bd83          	ld	s11,104(a1)
    800033f8:	8082                	ret

00000000800033fa <trapinit>:
void kernelvec();

extern int devintr();

void trapinit(void)
{
    800033fa:	1141                	addi	sp,sp,-16
    800033fc:	e406                	sd	ra,8(sp)
    800033fe:	e022                	sd	s0,0(sp)
    80003400:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80003402:	00006597          	auipc	a1,0x6
    80003406:	efe58593          	addi	a1,a1,-258 # 80009300 <states.0+0x30>
    8000340a:	00016517          	auipc	a0,0x16
    8000340e:	dd650513          	addi	a0,a0,-554 # 800191e0 <tickslock>
    80003412:	ffffd097          	auipc	ra,0xffffd
    80003416:	734080e7          	jalr	1844(ra) # 80000b46 <initlock>
}
    8000341a:	60a2                	ld	ra,8(sp)
    8000341c:	6402                	ld	s0,0(sp)
    8000341e:	0141                	addi	sp,sp,16
    80003420:	8082                	ret

0000000080003422 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void trapinithart(void)
{
    80003422:	1141                	addi	sp,sp,-16
    80003424:	e422                	sd	s0,8(sp)
    80003426:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003428:	00003797          	auipc	a5,0x3
    8000342c:	70878793          	addi	a5,a5,1800 # 80006b30 <kernelvec>
    80003430:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80003434:	6422                	ld	s0,8(sp)
    80003436:	0141                	addi	sp,sp,16
    80003438:	8082                	ret

000000008000343a <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    8000343a:	1141                	addi	sp,sp,-16
    8000343c:	e406                	sd	ra,8(sp)
    8000343e:	e022                	sd	s0,0(sp)
    80003440:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80003442:	ffffe097          	auipc	ra,0xffffe
    80003446:	56a080e7          	jalr	1386(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000344a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000344e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003450:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80003454:	00005697          	auipc	a3,0x5
    80003458:	bac68693          	addi	a3,a3,-1108 # 80008000 <_trampoline>
    8000345c:	00005717          	auipc	a4,0x5
    80003460:	ba470713          	addi	a4,a4,-1116 # 80008000 <_trampoline>
    80003464:	8f15                	sub	a4,a4,a3
    80003466:	040007b7          	lui	a5,0x4000
    8000346a:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    8000346c:	07b2                	slli	a5,a5,0xc
    8000346e:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80003470:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80003474:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80003476:	18002673          	csrr	a2,satp
    8000347a:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    8000347c:	6d30                	ld	a2,88(a0)
    8000347e:	6138                	ld	a4,64(a0)
    80003480:	6585                	lui	a1,0x1
    80003482:	972e                	add	a4,a4,a1
    80003484:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80003486:	6d38                	ld	a4,88(a0)
    80003488:	00000617          	auipc	a2,0x0
    8000348c:	13e60613          	addi	a2,a2,318 # 800035c6 <usertrap>
    80003490:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80003492:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80003494:	8612                	mv	a2,tp
    80003496:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003498:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    8000349c:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800034a0:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800034a4:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800034a8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800034aa:	6f18                	ld	a4,24(a4)
    800034ac:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    800034b0:	6928                	ld	a0,80(a0)
    800034b2:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    800034b4:	00005717          	auipc	a4,0x5
    800034b8:	be870713          	addi	a4,a4,-1048 # 8000809c <userret>
    800034bc:	8f15                	sub	a4,a4,a3
    800034be:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    800034c0:	577d                	li	a4,-1
    800034c2:	177e                	slli	a4,a4,0x3f
    800034c4:	8d59                	or	a0,a0,a4
    800034c6:	9782                	jalr	a5
}
    800034c8:	60a2                	ld	ra,8(sp)
    800034ca:	6402                	ld	s0,0(sp)
    800034cc:	0141                	addi	sp,sp,16
    800034ce:	8082                	ret

00000000800034d0 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    800034d0:	1101                	addi	sp,sp,-32
    800034d2:	ec06                	sd	ra,24(sp)
    800034d4:	e822                	sd	s0,16(sp)
    800034d6:	e426                	sd	s1,8(sp)
    800034d8:	e04a                	sd	s2,0(sp)
    800034da:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800034dc:	00016917          	auipc	s2,0x16
    800034e0:	d0490913          	addi	s2,s2,-764 # 800191e0 <tickslock>
    800034e4:	854a                	mv	a0,s2
    800034e6:	ffffd097          	auipc	ra,0xffffd
    800034ea:	6f0080e7          	jalr	1776(ra) # 80000bd6 <acquire>
  ticks++;
    800034ee:	00006497          	auipc	s1,0x6
    800034f2:	44248493          	addi	s1,s1,1090 # 80009930 <ticks>
    800034f6:	409c                	lw	a5,0(s1)
    800034f8:	2785                	addiw	a5,a5,1
    800034fa:	c09c                	sw	a5,0(s1)
  update_time();
    800034fc:	00000097          	auipc	ra,0x0
    80003500:	e36080e7          	jalr	-458(ra) # 80003332 <update_time>
  //   // {
  //   //   p->wtime++;
  //   // }
  //   release(&p->lock);
  // }
  wakeup(&ticks);
    80003504:	8526                	mv	a0,s1
    80003506:	fffff097          	auipc	ra,0xfffff
    8000350a:	7d4080e7          	jalr	2004(ra) # 80002cda <wakeup>
  release(&tickslock);
    8000350e:	854a                	mv	a0,s2
    80003510:	ffffd097          	auipc	ra,0xffffd
    80003514:	77a080e7          	jalr	1914(ra) # 80000c8a <release>
}
    80003518:	60e2                	ld	ra,24(sp)
    8000351a:	6442                	ld	s0,16(sp)
    8000351c:	64a2                	ld	s1,8(sp)
    8000351e:	6902                	ld	s2,0(sp)
    80003520:	6105                	addi	sp,sp,32
    80003522:	8082                	ret

0000000080003524 <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80003524:	1101                	addi	sp,sp,-32
    80003526:	ec06                	sd	ra,24(sp)
    80003528:	e822                	sd	s0,16(sp)
    8000352a:	e426                	sd	s1,8(sp)
    8000352c:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    8000352e:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80003532:	00074d63          	bltz	a4,8000354c <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80003536:	57fd                	li	a5,-1
    80003538:	17fe                	slli	a5,a5,0x3f
    8000353a:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    8000353c:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    8000353e:	06f70363          	beq	a4,a5,800035a4 <devintr+0x80>
  }
}
    80003542:	60e2                	ld	ra,24(sp)
    80003544:	6442                	ld	s0,16(sp)
    80003546:	64a2                	ld	s1,8(sp)
    80003548:	6105                	addi	sp,sp,32
    8000354a:	8082                	ret
      (scause & 0xff) == 9)
    8000354c:	0ff77793          	zext.b	a5,a4
  if ((scause & 0x8000000000000000L) &&
    80003550:	46a5                	li	a3,9
    80003552:	fed792e3          	bne	a5,a3,80003536 <devintr+0x12>
    int irq = plic_claim();
    80003556:	00003097          	auipc	ra,0x3
    8000355a:	6e2080e7          	jalr	1762(ra) # 80006c38 <plic_claim>
    8000355e:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80003560:	47a9                	li	a5,10
    80003562:	02f50763          	beq	a0,a5,80003590 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80003566:	4785                	li	a5,1
    80003568:	02f50963          	beq	a0,a5,8000359a <devintr+0x76>
    return 1;
    8000356c:	4505                	li	a0,1
    else if (irq)
    8000356e:	d8f1                	beqz	s1,80003542 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80003570:	85a6                	mv	a1,s1
    80003572:	00006517          	auipc	a0,0x6
    80003576:	d9650513          	addi	a0,a0,-618 # 80009308 <states.0+0x38>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	010080e7          	jalr	16(ra) # 8000058a <printf>
      plic_complete(irq);
    80003582:	8526                	mv	a0,s1
    80003584:	00003097          	auipc	ra,0x3
    80003588:	6d8080e7          	jalr	1752(ra) # 80006c5c <plic_complete>
    return 1;
    8000358c:	4505                	li	a0,1
    8000358e:	bf55                	j	80003542 <devintr+0x1e>
      uartintr();
    80003590:	ffffd097          	auipc	ra,0xffffd
    80003594:	408080e7          	jalr	1032(ra) # 80000998 <uartintr>
    80003598:	b7ed                	j	80003582 <devintr+0x5e>
      virtio_disk_intr();
    8000359a:	00004097          	auipc	ra,0x4
    8000359e:	b8a080e7          	jalr	-1142(ra) # 80007124 <virtio_disk_intr>
    800035a2:	b7c5                	j	80003582 <devintr+0x5e>
    if (cpuid() == 0)
    800035a4:	ffffe097          	auipc	ra,0xffffe
    800035a8:	3dc080e7          	jalr	988(ra) # 80001980 <cpuid>
    800035ac:	c901                	beqz	a0,800035bc <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800035ae:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800035b2:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800035b4:	14479073          	csrw	sip,a5
    return 2;
    800035b8:	4509                	li	a0,2
    800035ba:	b761                	j	80003542 <devintr+0x1e>
      clockintr();
    800035bc:	00000097          	auipc	ra,0x0
    800035c0:	f14080e7          	jalr	-236(ra) # 800034d0 <clockintr>
    800035c4:	b7ed                	j	800035ae <devintr+0x8a>

00000000800035c6 <usertrap>:
{
    800035c6:	7179                	addi	sp,sp,-48
    800035c8:	f406                	sd	ra,40(sp)
    800035ca:	f022                	sd	s0,32(sp)
    800035cc:	ec26                	sd	s1,24(sp)
    800035ce:	e84a                	sd	s2,16(sp)
    800035d0:	e44e                	sd	s3,8(sp)
    800035d2:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800035d4:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    800035d8:	1007f793          	andi	a5,a5,256
    800035dc:	e3ad                	bnez	a5,8000363e <usertrap+0x78>
  asm volatile("csrw stvec, %0" : : "r" (x));
    800035de:	00003797          	auipc	a5,0x3
    800035e2:	55278793          	addi	a5,a5,1362 # 80006b30 <kernelvec>
    800035e6:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800035ea:	ffffe097          	auipc	ra,0xffffe
    800035ee:	3c2080e7          	jalr	962(ra) # 800019ac <myproc>
    800035f2:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800035f4:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800035f6:	14102773          	csrr	a4,sepc
    800035fa:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800035fc:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003600:	47a1                	li	a5,8
    80003602:	04f70663          	beq	a4,a5,8000364e <usertrap+0x88>
  else if ((which_dev = devintr()) != 0)
    80003606:	00000097          	auipc	ra,0x0
    8000360a:	f1e080e7          	jalr	-226(ra) # 80003524 <devintr>
    8000360e:	892a                	mv	s2,a0
    80003610:	10050063          	beqz	a0,80003710 <usertrap+0x14a>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003614:	4789                	li	a5,2
    80003616:	06f50763          	beq	a0,a5,80003684 <usertrap+0xbe>
  if (killed(p))
    8000361a:	8526                	mv	a0,s1
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	90e080e7          	jalr	-1778(ra) # 80002f2a <killed>
    80003624:	12051363          	bnez	a0,8000374a <usertrap+0x184>
  usertrapret();
    80003628:	00000097          	auipc	ra,0x0
    8000362c:	e12080e7          	jalr	-494(ra) # 8000343a <usertrapret>
}
    80003630:	70a2                	ld	ra,40(sp)
    80003632:	7402                	ld	s0,32(sp)
    80003634:	64e2                	ld	s1,24(sp)
    80003636:	6942                	ld	s2,16(sp)
    80003638:	69a2                	ld	s3,8(sp)
    8000363a:	6145                	addi	sp,sp,48
    8000363c:	8082                	ret
    panic("usertrap: not from user mode");
    8000363e:	00006517          	auipc	a0,0x6
    80003642:	cea50513          	addi	a0,a0,-790 # 80009328 <states.0+0x58>
    80003646:	ffffd097          	auipc	ra,0xffffd
    8000364a:	efa080e7          	jalr	-262(ra) # 80000540 <panic>
    if (killed(p))
    8000364e:	00000097          	auipc	ra,0x0
    80003652:	8dc080e7          	jalr	-1828(ra) # 80002f2a <killed>
    80003656:	e10d                	bnez	a0,80003678 <usertrap+0xb2>
    p->trapframe->epc += 4;
    80003658:	6cb8                	ld	a4,88(s1)
    8000365a:	6f1c                	ld	a5,24(a4)
    8000365c:	0791                	addi	a5,a5,4
    8000365e:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003660:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80003664:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80003668:	10079073          	csrw	sstatus,a5
    syscall();
    8000366c:	00000097          	auipc	ra,0x0
    80003670:	360080e7          	jalr	864(ra) # 800039cc <syscall>
  int which_dev = 0;
    80003674:	4901                	li	s2,0
    80003676:	b755                	j	8000361a <usertrap+0x54>
      exit(-1);
    80003678:	557d                	li	a0,-1
    8000367a:	fffff097          	auipc	ra,0xfffff
    8000367e:	730080e7          	jalr	1840(ra) # 80002daa <exit>
    80003682:	bfd9                	j	80003658 <usertrap+0x92>
    if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    80003684:	ffffe097          	auipc	ra,0xffffe
    80003688:	328080e7          	jalr	808(ra) # 800019ac <myproc>
    8000368c:	c909                	beqz	a0,8000369e <usertrap+0xd8>
    8000368e:	ffffe097          	auipc	ra,0xffffe
    80003692:	31e080e7          	jalr	798(ra) # 800019ac <myproc>
    80003696:	4d18                	lw	a4,24(a0)
    80003698:	4791                	li	a5,4
    8000369a:	00f70e63          	beq	a4,a5,800036b6 <usertrap+0xf0>
  if (killed(p))
    8000369e:	8526                	mv	a0,s1
    800036a0:	00000097          	auipc	ra,0x0
    800036a4:	88a080e7          	jalr	-1910(ra) # 80002f2a <killed>
    800036a8:	c94d                	beqz	a0,8000375a <usertrap+0x194>
    exit(-1);
    800036aa:	557d                	li	a0,-1
    800036ac:	fffff097          	auipc	ra,0xfffff
    800036b0:	6fe080e7          	jalr	1790(ra) # 80002daa <exit>
  if(which_dev == 2){
    800036b4:	a05d                	j	8000375a <usertrap+0x194>
      if(myproc()->alarm_on == 0){
    800036b6:	ffffe097          	auipc	ra,0xffffe
    800036ba:	2f6080e7          	jalr	758(ra) # 800019ac <myproc>
    800036be:	19052783          	lw	a5,400(a0)
    800036c2:	fff1                	bnez	a5,8000369e <usertrap+0xd8>
        struct proc* pr = myproc();
    800036c4:	ffffe097          	auipc	ra,0xffffe
    800036c8:	2e8080e7          	jalr	744(ra) # 800019ac <myproc>
    800036cc:	892a                	mv	s2,a0
        if((pr->rtime - pr->atime)%pr->interval_ticks == 0){
    800036ce:	16852783          	lw	a5,360(a0)
    800036d2:	19452703          	lw	a4,404(a0)
    800036d6:	9f99                	subw	a5,a5,a4
    800036d8:	18052703          	lw	a4,384(a0)
    800036dc:	02e7f7bb          	remuw	a5,a5,a4
    800036e0:	ffdd                	bnez	a5,8000369e <usertrap+0xd8>
          pr->alarm_on = 1;
    800036e2:	4785                	li	a5,1
    800036e4:	18f52823          	sw	a5,400(a0)
          struct trapframe* tf = kalloc();
    800036e8:	ffffd097          	auipc	ra,0xffffd
    800036ec:	3fe080e7          	jalr	1022(ra) # 80000ae6 <kalloc>
    800036f0:	89aa                	mv	s3,a0
          memmove(tf, pr->trapframe, PGSIZE);
    800036f2:	6605                	lui	a2,0x1
    800036f4:	05893583          	ld	a1,88(s2)
    800036f8:	ffffd097          	auipc	ra,0xffffd
    800036fc:	636080e7          	jalr	1590(ra) # 80000d2e <memmove>
          pr->cached_alarm_tf = tf;
    80003700:	19393423          	sd	s3,392(s2)
          pr->trapframe->epc = pr->handler;
    80003704:	05893783          	ld	a5,88(s2)
    80003708:	17893703          	ld	a4,376(s2)
    8000370c:	ef98                	sd	a4,24(a5)
    8000370e:	bf41                	j	8000369e <usertrap+0xd8>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003710:	142025f3          	csrr	a1,scause
      printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003714:	5890                	lw	a2,48(s1)
    80003716:	00006517          	auipc	a0,0x6
    8000371a:	c3250513          	addi	a0,a0,-974 # 80009348 <states.0+0x78>
    8000371e:	ffffd097          	auipc	ra,0xffffd
    80003722:	e6c080e7          	jalr	-404(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003726:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000372a:	14302673          	csrr	a2,stval
      printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000372e:	00006517          	auipc	a0,0x6
    80003732:	c4a50513          	addi	a0,a0,-950 # 80009378 <states.0+0xa8>
    80003736:	ffffd097          	auipc	ra,0xffffd
    8000373a:	e54080e7          	jalr	-428(ra) # 8000058a <printf>
      setkilled(p);
    8000373e:	8526                	mv	a0,s1
    80003740:	fffff097          	auipc	ra,0xfffff
    80003744:	7be080e7          	jalr	1982(ra) # 80002efe <setkilled>
    80003748:	bdc9                	j	8000361a <usertrap+0x54>
    exit(-1);
    8000374a:	557d                	li	a0,-1
    8000374c:	fffff097          	auipc	ra,0xfffff
    80003750:	65e080e7          	jalr	1630(ra) # 80002daa <exit>
  if(which_dev == 2){
    80003754:	4789                	li	a5,2
    80003756:	ecf919e3          	bne	s2,a5,80003628 <usertrap+0x62>
    printf("pid: %d ticks: %d queue: %d\n", p->pid, ticks, p->priority);
    8000375a:	1984a683          	lw	a3,408(s1)
    8000375e:	00006617          	auipc	a2,0x6
    80003762:	1d262603          	lw	a2,466(a2) # 80009930 <ticks>
    80003766:	588c                	lw	a1,48(s1)
    80003768:	00006517          	auipc	a0,0x6
    8000376c:	c3050513          	addi	a0,a0,-976 # 80009398 <states.0+0xc8>
    80003770:	ffffd097          	auipc	ra,0xffffd
    80003774:	e1a080e7          	jalr	-486(ra) # 8000058a <printf>
    yield();
    80003778:	fffff097          	auipc	ra,0xfffff
    8000377c:	4c2080e7          	jalr	1218(ra) # 80002c3a <yield>
    80003780:	b565                	j	80003628 <usertrap+0x62>

0000000080003782 <kerneltrap>:
{ 
    80003782:	7179                	addi	sp,sp,-48
    80003784:	f406                	sd	ra,40(sp)
    80003786:	f022                	sd	s0,32(sp)
    80003788:	ec26                	sd	s1,24(sp)
    8000378a:	e84a                	sd	s2,16(sp)
    8000378c:	e44e                	sd	s3,8(sp)
    8000378e:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003790:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003794:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003798:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    8000379c:	1004f793          	andi	a5,s1,256
    800037a0:	cb85                	beqz	a5,800037d0 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800037a2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800037a6:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800037a8:	ef85                	bnez	a5,800037e0 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800037aa:	00000097          	auipc	ra,0x0
    800037ae:	d7a080e7          	jalr	-646(ra) # 80003524 <devintr>
    800037b2:	cd1d                	beqz	a0,800037f0 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    800037b4:	4789                	li	a5,2
    800037b6:	06f50a63          	beq	a0,a5,8000382a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800037ba:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800037be:	10049073          	csrw	sstatus,s1
}
    800037c2:	70a2                	ld	ra,40(sp)
    800037c4:	7402                	ld	s0,32(sp)
    800037c6:	64e2                	ld	s1,24(sp)
    800037c8:	6942                	ld	s2,16(sp)
    800037ca:	69a2                	ld	s3,8(sp)
    800037cc:	6145                	addi	sp,sp,48
    800037ce:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800037d0:	00006517          	auipc	a0,0x6
    800037d4:	be850513          	addi	a0,a0,-1048 # 800093b8 <states.0+0xe8>
    800037d8:	ffffd097          	auipc	ra,0xffffd
    800037dc:	d68080e7          	jalr	-664(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800037e0:	00006517          	auipc	a0,0x6
    800037e4:	c0050513          	addi	a0,a0,-1024 # 800093e0 <states.0+0x110>
    800037e8:	ffffd097          	auipc	ra,0xffffd
    800037ec:	d58080e7          	jalr	-680(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    800037f0:	85ce                	mv	a1,s3
    800037f2:	00006517          	auipc	a0,0x6
    800037f6:	c0e50513          	addi	a0,a0,-1010 # 80009400 <states.0+0x130>
    800037fa:	ffffd097          	auipc	ra,0xffffd
    800037fe:	d90080e7          	jalr	-624(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003802:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003806:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000380a:	00006517          	auipc	a0,0x6
    8000380e:	c0650513          	addi	a0,a0,-1018 # 80009410 <states.0+0x140>
    80003812:	ffffd097          	auipc	ra,0xffffd
    80003816:	d78080e7          	jalr	-648(ra) # 8000058a <printf>
    panic("kerneltrap");
    8000381a:	00006517          	auipc	a0,0x6
    8000381e:	c0e50513          	addi	a0,a0,-1010 # 80009428 <states.0+0x158>
    80003822:	ffffd097          	auipc	ra,0xffffd
    80003826:	d1e080e7          	jalr	-738(ra) # 80000540 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING){
    8000382a:	ffffe097          	auipc	ra,0xffffe
    8000382e:	182080e7          	jalr	386(ra) # 800019ac <myproc>
    80003832:	d541                	beqz	a0,800037ba <kerneltrap+0x38>
    80003834:	ffffe097          	auipc	ra,0xffffe
    80003838:	178080e7          	jalr	376(ra) # 800019ac <myproc>
    8000383c:	4d18                	lw	a4,24(a0)
    8000383e:	4791                	li	a5,4
    80003840:	f6f71de3          	bne	a4,a5,800037ba <kerneltrap+0x38>
      yield();
    80003844:	fffff097          	auipc	ra,0xfffff
    80003848:	3f6080e7          	jalr	1014(ra) # 80002c3a <yield>
    8000384c:	b7bd                	j	800037ba <kerneltrap+0x38>

000000008000384e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000384e:	1101                	addi	sp,sp,-32
    80003850:	ec06                	sd	ra,24(sp)
    80003852:	e822                	sd	s0,16(sp)
    80003854:	e426                	sd	s1,8(sp)
    80003856:	1000                	addi	s0,sp,32
    80003858:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000385a:	ffffe097          	auipc	ra,0xffffe
    8000385e:	152080e7          	jalr	338(ra) # 800019ac <myproc>
  switch (n) {
    80003862:	4795                	li	a5,5
    80003864:	0497e163          	bltu	a5,s1,800038a6 <argraw+0x58>
    80003868:	048a                	slli	s1,s1,0x2
    8000386a:	00006717          	auipc	a4,0x6
    8000386e:	bf670713          	addi	a4,a4,-1034 # 80009460 <states.0+0x190>
    80003872:	94ba                	add	s1,s1,a4
    80003874:	409c                	lw	a5,0(s1)
    80003876:	97ba                	add	a5,a5,a4
    80003878:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    8000387a:	6d3c                	ld	a5,88(a0)
    8000387c:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    8000387e:	60e2                	ld	ra,24(sp)
    80003880:	6442                	ld	s0,16(sp)
    80003882:	64a2                	ld	s1,8(sp)
    80003884:	6105                	addi	sp,sp,32
    80003886:	8082                	ret
    return p->trapframe->a1;
    80003888:	6d3c                	ld	a5,88(a0)
    8000388a:	7fa8                	ld	a0,120(a5)
    8000388c:	bfcd                	j	8000387e <argraw+0x30>
    return p->trapframe->a2;
    8000388e:	6d3c                	ld	a5,88(a0)
    80003890:	63c8                	ld	a0,128(a5)
    80003892:	b7f5                	j	8000387e <argraw+0x30>
    return p->trapframe->a3;
    80003894:	6d3c                	ld	a5,88(a0)
    80003896:	67c8                	ld	a0,136(a5)
    80003898:	b7dd                	j	8000387e <argraw+0x30>
    return p->trapframe->a4;
    8000389a:	6d3c                	ld	a5,88(a0)
    8000389c:	6bc8                	ld	a0,144(a5)
    8000389e:	b7c5                	j	8000387e <argraw+0x30>
    return p->trapframe->a5;
    800038a0:	6d3c                	ld	a5,88(a0)
    800038a2:	6fc8                	ld	a0,152(a5)
    800038a4:	bfe9                	j	8000387e <argraw+0x30>
  panic("argraw");
    800038a6:	00006517          	auipc	a0,0x6
    800038aa:	b9250513          	addi	a0,a0,-1134 # 80009438 <states.0+0x168>
    800038ae:	ffffd097          	auipc	ra,0xffffd
    800038b2:	c92080e7          	jalr	-878(ra) # 80000540 <panic>

00000000800038b6 <fetchaddr>:
{
    800038b6:	1101                	addi	sp,sp,-32
    800038b8:	ec06                	sd	ra,24(sp)
    800038ba:	e822                	sd	s0,16(sp)
    800038bc:	e426                	sd	s1,8(sp)
    800038be:	e04a                	sd	s2,0(sp)
    800038c0:	1000                	addi	s0,sp,32
    800038c2:	84aa                	mv	s1,a0
    800038c4:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800038c6:	ffffe097          	auipc	ra,0xffffe
    800038ca:	0e6080e7          	jalr	230(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    800038ce:	653c                	ld	a5,72(a0)
    800038d0:	02f4f863          	bgeu	s1,a5,80003900 <fetchaddr+0x4a>
    800038d4:	00848713          	addi	a4,s1,8
    800038d8:	02e7e663          	bltu	a5,a4,80003904 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    800038dc:	46a1                	li	a3,8
    800038de:	8626                	mv	a2,s1
    800038e0:	85ca                	mv	a1,s2
    800038e2:	6928                	ld	a0,80(a0)
    800038e4:	ffffe097          	auipc	ra,0xffffe
    800038e8:	e14080e7          	jalr	-492(ra) # 800016f8 <copyin>
    800038ec:	00a03533          	snez	a0,a0
    800038f0:	40a00533          	neg	a0,a0
}
    800038f4:	60e2                	ld	ra,24(sp)
    800038f6:	6442                	ld	s0,16(sp)
    800038f8:	64a2                	ld	s1,8(sp)
    800038fa:	6902                	ld	s2,0(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret
    return -1;
    80003900:	557d                	li	a0,-1
    80003902:	bfcd                	j	800038f4 <fetchaddr+0x3e>
    80003904:	557d                	li	a0,-1
    80003906:	b7fd                	j	800038f4 <fetchaddr+0x3e>

0000000080003908 <fetchstr>:
{
    80003908:	7179                	addi	sp,sp,-48
    8000390a:	f406                	sd	ra,40(sp)
    8000390c:	f022                	sd	s0,32(sp)
    8000390e:	ec26                	sd	s1,24(sp)
    80003910:	e84a                	sd	s2,16(sp)
    80003912:	e44e                	sd	s3,8(sp)
    80003914:	1800                	addi	s0,sp,48
    80003916:	892a                	mv	s2,a0
    80003918:	84ae                	mv	s1,a1
    8000391a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000391c:	ffffe097          	auipc	ra,0xffffe
    80003920:	090080e7          	jalr	144(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003924:	86ce                	mv	a3,s3
    80003926:	864a                	mv	a2,s2
    80003928:	85a6                	mv	a1,s1
    8000392a:	6928                	ld	a0,80(a0)
    8000392c:	ffffe097          	auipc	ra,0xffffe
    80003930:	e5a080e7          	jalr	-422(ra) # 80001786 <copyinstr>
    80003934:	00054e63          	bltz	a0,80003950 <fetchstr+0x48>
  return strlen(buf);
    80003938:	8526                	mv	a0,s1
    8000393a:	ffffd097          	auipc	ra,0xffffd
    8000393e:	514080e7          	jalr	1300(ra) # 80000e4e <strlen>
}
    80003942:	70a2                	ld	ra,40(sp)
    80003944:	7402                	ld	s0,32(sp)
    80003946:	64e2                	ld	s1,24(sp)
    80003948:	6942                	ld	s2,16(sp)
    8000394a:	69a2                	ld	s3,8(sp)
    8000394c:	6145                	addi	sp,sp,48
    8000394e:	8082                	ret
    return -1;
    80003950:	557d                	li	a0,-1
    80003952:	bfc5                	j	80003942 <fetchstr+0x3a>

0000000080003954 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003954:	1101                	addi	sp,sp,-32
    80003956:	ec06                	sd	ra,24(sp)
    80003958:	e822                	sd	s0,16(sp)
    8000395a:	e426                	sd	s1,8(sp)
    8000395c:	1000                	addi	s0,sp,32
    8000395e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003960:	00000097          	auipc	ra,0x0
    80003964:	eee080e7          	jalr	-274(ra) # 8000384e <argraw>
    80003968:	c088                	sw	a0,0(s1)
}
    8000396a:	60e2                	ld	ra,24(sp)
    8000396c:	6442                	ld	s0,16(sp)
    8000396e:	64a2                	ld	s1,8(sp)
    80003970:	6105                	addi	sp,sp,32
    80003972:	8082                	ret

0000000080003974 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80003974:	1101                	addi	sp,sp,-32
    80003976:	ec06                	sd	ra,24(sp)
    80003978:	e822                	sd	s0,16(sp)
    8000397a:	e426                	sd	s1,8(sp)
    8000397c:	1000                	addi	s0,sp,32
    8000397e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80003980:	00000097          	auipc	ra,0x0
    80003984:	ece080e7          	jalr	-306(ra) # 8000384e <argraw>
    80003988:	e088                	sd	a0,0(s1)
}
    8000398a:	60e2                	ld	ra,24(sp)
    8000398c:	6442                	ld	s0,16(sp)
    8000398e:	64a2                	ld	s1,8(sp)
    80003990:	6105                	addi	sp,sp,32
    80003992:	8082                	ret

0000000080003994 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80003994:	7179                	addi	sp,sp,-48
    80003996:	f406                	sd	ra,40(sp)
    80003998:	f022                	sd	s0,32(sp)
    8000399a:	ec26                	sd	s1,24(sp)
    8000399c:	e84a                	sd	s2,16(sp)
    8000399e:	1800                	addi	s0,sp,48
    800039a0:	84ae                	mv	s1,a1
    800039a2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800039a4:	fd840593          	addi	a1,s0,-40
    800039a8:	00000097          	auipc	ra,0x0
    800039ac:	fcc080e7          	jalr	-52(ra) # 80003974 <argaddr>
  return fetchstr(addr, buf, max);
    800039b0:	864a                	mv	a2,s2
    800039b2:	85a6                	mv	a1,s1
    800039b4:	fd843503          	ld	a0,-40(s0)
    800039b8:	00000097          	auipc	ra,0x0
    800039bc:	f50080e7          	jalr	-176(ra) # 80003908 <fetchstr>
}
    800039c0:	70a2                	ld	ra,40(sp)
    800039c2:	7402                	ld	s0,32(sp)
    800039c4:	64e2                	ld	s1,24(sp)
    800039c6:	6942                	ld	s2,16(sp)
    800039c8:	6145                	addi	sp,sp,48
    800039ca:	8082                	ret

00000000800039cc <syscall>:
[SYS_sigreturn]   sys_sigreturn,
};

void
syscall(void)
{
    800039cc:	1101                	addi	sp,sp,-32
    800039ce:	ec06                	sd	ra,24(sp)
    800039d0:	e822                	sd	s0,16(sp)
    800039d2:	e426                	sd	s1,8(sp)
    800039d4:	e04a                	sd	s2,0(sp)
    800039d6:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    800039d8:	ffffe097          	auipc	ra,0xffffe
    800039dc:	fd4080e7          	jalr	-44(ra) # 800019ac <myproc>
    800039e0:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    800039e2:	05853903          	ld	s2,88(a0)
    800039e6:	0a893783          	ld	a5,168(s2)
    800039ea:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    800039ee:	37fd                	addiw	a5,a5,-1
    800039f0:	4761                	li	a4,24
    800039f2:	00f76f63          	bltu	a4,a5,80003a10 <syscall+0x44>
    800039f6:	00369713          	slli	a4,a3,0x3
    800039fa:	00006797          	auipc	a5,0x6
    800039fe:	a7e78793          	addi	a5,a5,-1410 # 80009478 <syscalls>
    80003a02:	97ba                	add	a5,a5,a4
    80003a04:	639c                	ld	a5,0(a5)
    80003a06:	c789                	beqz	a5,80003a10 <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80003a08:	9782                	jalr	a5
    80003a0a:	06a93823          	sd	a0,112(s2)
    80003a0e:	a839                	j	80003a2c <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80003a10:	15848613          	addi	a2,s1,344
    80003a14:	588c                	lw	a1,48(s1)
    80003a16:	00006517          	auipc	a0,0x6
    80003a1a:	a2a50513          	addi	a0,a0,-1494 # 80009440 <states.0+0x170>
    80003a1e:	ffffd097          	auipc	ra,0xffffd
    80003a22:	b6c080e7          	jalr	-1172(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80003a26:	6cbc                	ld	a5,88(s1)
    80003a28:	577d                	li	a4,-1
    80003a2a:	fbb8                	sd	a4,112(a5)
  }
}
    80003a2c:	60e2                	ld	ra,24(sp)
    80003a2e:	6442                	ld	s0,16(sp)
    80003a30:	64a2                	ld	s1,8(sp)
    80003a32:	6902                	ld	s2,0(sp)
    80003a34:	6105                	addi	sp,sp,32
    80003a36:	8082                	ret

0000000080003a38 <sys_exit>:
#include "proc.h"
#include "file.h"

uint64
sys_exit(void)
{
    80003a38:	1101                	addi	sp,sp,-32
    80003a3a:	ec06                	sd	ra,24(sp)
    80003a3c:	e822                	sd	s0,16(sp)
    80003a3e:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80003a40:	fec40593          	addi	a1,s0,-20
    80003a44:	4501                	li	a0,0
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	f0e080e7          	jalr	-242(ra) # 80003954 <argint>
  exit(n);
    80003a4e:	fec42503          	lw	a0,-20(s0)
    80003a52:	fffff097          	auipc	ra,0xfffff
    80003a56:	358080e7          	jalr	856(ra) # 80002daa <exit>
  return 0; // not reached
}
    80003a5a:	4501                	li	a0,0
    80003a5c:	60e2                	ld	ra,24(sp)
    80003a5e:	6442                	ld	s0,16(sp)
    80003a60:	6105                	addi	sp,sp,32
    80003a62:	8082                	ret

0000000080003a64 <sys_getpid>:

uint64
sys_getpid(void)
{
    80003a64:	1141                	addi	sp,sp,-16
    80003a66:	e406                	sd	ra,8(sp)
    80003a68:	e022                	sd	s0,0(sp)
    80003a6a:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003a6c:	ffffe097          	auipc	ra,0xffffe
    80003a70:	f40080e7          	jalr	-192(ra) # 800019ac <myproc>
}
    80003a74:	5908                	lw	a0,48(a0)
    80003a76:	60a2                	ld	ra,8(sp)
    80003a78:	6402                	ld	s0,0(sp)
    80003a7a:	0141                	addi	sp,sp,16
    80003a7c:	8082                	ret

0000000080003a7e <sys_fork>:

uint64
sys_fork(void)
{
    80003a7e:	1141                	addi	sp,sp,-16
    80003a80:	e406                	sd	ra,8(sp)
    80003a82:	e022                	sd	s0,0(sp)
    80003a84:	0800                	addi	s0,sp,16
  return fork();
    80003a86:	ffffe097          	auipc	ra,0xffffe
    80003a8a:	33e080e7          	jalr	830(ra) # 80001dc4 <fork>
}
    80003a8e:	60a2                	ld	ra,8(sp)
    80003a90:	6402                	ld	s0,0(sp)
    80003a92:	0141                	addi	sp,sp,16
    80003a94:	8082                	ret

0000000080003a96 <sys_wait>:

uint64
sys_wait(void)
{
    80003a96:	1101                	addi	sp,sp,-32
    80003a98:	ec06                	sd	ra,24(sp)
    80003a9a:	e822                	sd	s0,16(sp)
    80003a9c:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003a9e:	fe840593          	addi	a1,s0,-24
    80003aa2:	4501                	li	a0,0
    80003aa4:	00000097          	auipc	ra,0x0
    80003aa8:	ed0080e7          	jalr	-304(ra) # 80003974 <argaddr>
  return wait(p);
    80003aac:	fe843503          	ld	a0,-24(s0)
    80003ab0:	fffff097          	auipc	ra,0xfffff
    80003ab4:	4ac080e7          	jalr	1196(ra) # 80002f5c <wait>
}
    80003ab8:	60e2                	ld	ra,24(sp)
    80003aba:	6442                	ld	s0,16(sp)
    80003abc:	6105                	addi	sp,sp,32
    80003abe:	8082                	ret

0000000080003ac0 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80003ac0:	7179                	addi	sp,sp,-48
    80003ac2:	f406                	sd	ra,40(sp)
    80003ac4:	f022                	sd	s0,32(sp)
    80003ac6:	ec26                	sd	s1,24(sp)
    80003ac8:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003aca:	fdc40593          	addi	a1,s0,-36
    80003ace:	4501                	li	a0,0
    80003ad0:	00000097          	auipc	ra,0x0
    80003ad4:	e84080e7          	jalr	-380(ra) # 80003954 <argint>
  addr = myproc()->sz;
    80003ad8:	ffffe097          	auipc	ra,0xffffe
    80003adc:	ed4080e7          	jalr	-300(ra) # 800019ac <myproc>
    80003ae0:	6524                	ld	s1,72(a0)
  if (growproc(n) < 0)
    80003ae2:	fdc42503          	lw	a0,-36(s0)
    80003ae6:	ffffe097          	auipc	ra,0xffffe
    80003aea:	282080e7          	jalr	642(ra) # 80001d68 <growproc>
    80003aee:	00054863          	bltz	a0,80003afe <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80003af2:	8526                	mv	a0,s1
    80003af4:	70a2                	ld	ra,40(sp)
    80003af6:	7402                	ld	s0,32(sp)
    80003af8:	64e2                	ld	s1,24(sp)
    80003afa:	6145                	addi	sp,sp,48
    80003afc:	8082                	ret
    return -1;
    80003afe:	54fd                	li	s1,-1
    80003b00:	bfcd                	j	80003af2 <sys_sbrk+0x32>

0000000080003b02 <sys_sleep>:

uint64
sys_sleep(void)
{
    80003b02:	7139                	addi	sp,sp,-64
    80003b04:	fc06                	sd	ra,56(sp)
    80003b06:	f822                	sd	s0,48(sp)
    80003b08:	f426                	sd	s1,40(sp)
    80003b0a:	f04a                	sd	s2,32(sp)
    80003b0c:	ec4e                	sd	s3,24(sp)
    80003b0e:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80003b10:	fcc40593          	addi	a1,s0,-52
    80003b14:	4501                	li	a0,0
    80003b16:	00000097          	auipc	ra,0x0
    80003b1a:	e3e080e7          	jalr	-450(ra) # 80003954 <argint>
  acquire(&tickslock);
    80003b1e:	00015517          	auipc	a0,0x15
    80003b22:	6c250513          	addi	a0,a0,1730 # 800191e0 <tickslock>
    80003b26:	ffffd097          	auipc	ra,0xffffd
    80003b2a:	0b0080e7          	jalr	176(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80003b2e:	00006917          	auipc	s2,0x6
    80003b32:	e0292903          	lw	s2,-510(s2) # 80009930 <ticks>
  while (ticks - ticks0 < n)
    80003b36:	fcc42783          	lw	a5,-52(s0)
    80003b3a:	cf9d                	beqz	a5,80003b78 <sys_sleep+0x76>
    if (killed(myproc()))
    {
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003b3c:	00015997          	auipc	s3,0x15
    80003b40:	6a498993          	addi	s3,s3,1700 # 800191e0 <tickslock>
    80003b44:	00006497          	auipc	s1,0x6
    80003b48:	dec48493          	addi	s1,s1,-532 # 80009930 <ticks>
    if (killed(myproc()))
    80003b4c:	ffffe097          	auipc	ra,0xffffe
    80003b50:	e60080e7          	jalr	-416(ra) # 800019ac <myproc>
    80003b54:	fffff097          	auipc	ra,0xfffff
    80003b58:	3d6080e7          	jalr	982(ra) # 80002f2a <killed>
    80003b5c:	ed15                	bnez	a0,80003b98 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003b5e:	85ce                	mv	a1,s3
    80003b60:	8526                	mv	a0,s1
    80003b62:	fffff097          	auipc	ra,0xfffff
    80003b66:	114080e7          	jalr	276(ra) # 80002c76 <sleep>
  while (ticks - ticks0 < n)
    80003b6a:	409c                	lw	a5,0(s1)
    80003b6c:	412787bb          	subw	a5,a5,s2
    80003b70:	fcc42703          	lw	a4,-52(s0)
    80003b74:	fce7ece3          	bltu	a5,a4,80003b4c <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003b78:	00015517          	auipc	a0,0x15
    80003b7c:	66850513          	addi	a0,a0,1640 # 800191e0 <tickslock>
    80003b80:	ffffd097          	auipc	ra,0xffffd
    80003b84:	10a080e7          	jalr	266(ra) # 80000c8a <release>
  return 0;
    80003b88:	4501                	li	a0,0
}
    80003b8a:	70e2                	ld	ra,56(sp)
    80003b8c:	7442                	ld	s0,48(sp)
    80003b8e:	74a2                	ld	s1,40(sp)
    80003b90:	7902                	ld	s2,32(sp)
    80003b92:	69e2                	ld	s3,24(sp)
    80003b94:	6121                	addi	sp,sp,64
    80003b96:	8082                	ret
      release(&tickslock);
    80003b98:	00015517          	auipc	a0,0x15
    80003b9c:	64850513          	addi	a0,a0,1608 # 800191e0 <tickslock>
    80003ba0:	ffffd097          	auipc	ra,0xffffd
    80003ba4:	0ea080e7          	jalr	234(ra) # 80000c8a <release>
      return -1;
    80003ba8:	557d                	li	a0,-1
    80003baa:	b7c5                	j	80003b8a <sys_sleep+0x88>

0000000080003bac <sys_kill>:

uint64
sys_kill(void)
{
    80003bac:	1101                	addi	sp,sp,-32
    80003bae:	ec06                	sd	ra,24(sp)
    80003bb0:	e822                	sd	s0,16(sp)
    80003bb2:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80003bb4:	fec40593          	addi	a1,s0,-20
    80003bb8:	4501                	li	a0,0
    80003bba:	00000097          	auipc	ra,0x0
    80003bbe:	d9a080e7          	jalr	-614(ra) # 80003954 <argint>
  return kill(pid);
    80003bc2:	fec42503          	lw	a0,-20(s0)
    80003bc6:	fffff097          	auipc	ra,0xfffff
    80003bca:	2c6080e7          	jalr	710(ra) # 80002e8c <kill>
}
    80003bce:	60e2                	ld	ra,24(sp)
    80003bd0:	6442                	ld	s0,16(sp)
    80003bd2:	6105                	addi	sp,sp,32
    80003bd4:	8082                	ret

0000000080003bd6 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003bd6:	1101                	addi	sp,sp,-32
    80003bd8:	ec06                	sd	ra,24(sp)
    80003bda:	e822                	sd	s0,16(sp)
    80003bdc:	e426                	sd	s1,8(sp)
    80003bde:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80003be0:	00015517          	auipc	a0,0x15
    80003be4:	60050513          	addi	a0,a0,1536 # 800191e0 <tickslock>
    80003be8:	ffffd097          	auipc	ra,0xffffd
    80003bec:	fee080e7          	jalr	-18(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80003bf0:	00006497          	auipc	s1,0x6
    80003bf4:	d404a483          	lw	s1,-704(s1) # 80009930 <ticks>
  release(&tickslock);
    80003bf8:	00015517          	auipc	a0,0x15
    80003bfc:	5e850513          	addi	a0,a0,1512 # 800191e0 <tickslock>
    80003c00:	ffffd097          	auipc	ra,0xffffd
    80003c04:	08a080e7          	jalr	138(ra) # 80000c8a <release>
  return xticks;
}
    80003c08:	02049513          	slli	a0,s1,0x20
    80003c0c:	9101                	srli	a0,a0,0x20
    80003c0e:	60e2                	ld	ra,24(sp)
    80003c10:	6442                	ld	s0,16(sp)
    80003c12:	64a2                	ld	s1,8(sp)
    80003c14:	6105                	addi	sp,sp,32
    80003c16:	8082                	ret

0000000080003c18 <sys_waitx>:

uint64
sys_waitx(void)
{
    80003c18:	7139                	addi	sp,sp,-64
    80003c1a:	fc06                	sd	ra,56(sp)
    80003c1c:	f822                	sd	s0,48(sp)
    80003c1e:	f426                	sd	s1,40(sp)
    80003c20:	f04a                	sd	s2,32(sp)
    80003c22:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    80003c24:	fd840593          	addi	a1,s0,-40
    80003c28:	4501                	li	a0,0
    80003c2a:	00000097          	auipc	ra,0x0
    80003c2e:	d4a080e7          	jalr	-694(ra) # 80003974 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    80003c32:	fd040593          	addi	a1,s0,-48
    80003c36:	4505                	li	a0,1
    80003c38:	00000097          	auipc	ra,0x0
    80003c3c:	d3c080e7          	jalr	-708(ra) # 80003974 <argaddr>
  argaddr(2, &addr2);
    80003c40:	fc840593          	addi	a1,s0,-56
    80003c44:	4509                	li	a0,2
    80003c46:	00000097          	auipc	ra,0x0
    80003c4a:	d2e080e7          	jalr	-722(ra) # 80003974 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    80003c4e:	fc040613          	addi	a2,s0,-64
    80003c52:	fc440593          	addi	a1,s0,-60
    80003c56:	fd843503          	ld	a0,-40(s0)
    80003c5a:	fffff097          	auipc	ra,0xfffff
    80003c5e:	58c080e7          	jalr	1420(ra) # 800031e6 <waitx>
    80003c62:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80003c64:	ffffe097          	auipc	ra,0xffffe
    80003c68:	d48080e7          	jalr	-696(ra) # 800019ac <myproc>
    80003c6c:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003c6e:	4691                	li	a3,4
    80003c70:	fc440613          	addi	a2,s0,-60
    80003c74:	fd043583          	ld	a1,-48(s0)
    80003c78:	6928                	ld	a0,80(a0)
    80003c7a:	ffffe097          	auipc	ra,0xffffe
    80003c7e:	9f2080e7          	jalr	-1550(ra) # 8000166c <copyout>
    return -1;
    80003c82:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1, (char *)&wtime, sizeof(int)) < 0)
    80003c84:	00054f63          	bltz	a0,80003ca2 <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2, (char *)&rtime, sizeof(int)) < 0)
    80003c88:	4691                	li	a3,4
    80003c8a:	fc040613          	addi	a2,s0,-64
    80003c8e:	fc843583          	ld	a1,-56(s0)
    80003c92:	68a8                	ld	a0,80(s1)
    80003c94:	ffffe097          	auipc	ra,0xffffe
    80003c98:	9d8080e7          	jalr	-1576(ra) # 8000166c <copyout>
    80003c9c:	00054a63          	bltz	a0,80003cb0 <sys_waitx+0x98>
    return -1;
  return ret;
    80003ca0:	87ca                	mv	a5,s2
}
    80003ca2:	853e                	mv	a0,a5
    80003ca4:	70e2                	ld	ra,56(sp)
    80003ca6:	7442                	ld	s0,48(sp)
    80003ca8:	74a2                	ld	s1,40(sp)
    80003caa:	7902                	ld	s2,32(sp)
    80003cac:	6121                	addi	sp,sp,64
    80003cae:	8082                	ret
    return -1;
    80003cb0:	57fd                	li	a5,-1
    80003cb2:	bfc5                	j	80003ca2 <sys_waitx+0x8a>

0000000080003cb4 <sys_getreadcount>:

uint64
sys_getreadcount(void){
    80003cb4:	1141                	addi	sp,sp,-16
    80003cb6:	e422                	sd	s0,8(sp)
    80003cb8:	0800                	addi	s0,sp,16
  return readcount;
}
    80003cba:	00006517          	auipc	a0,0x6
    80003cbe:	c7a52503          	lw	a0,-902(a0) # 80009934 <readcount>
    80003cc2:	6422                	ld	s0,8(sp)
    80003cc4:	0141                	addi	sp,sp,16
    80003cc6:	8082                	ret

0000000080003cc8 <sys_sigalarm>:

uint64
sys_sigalarm(void){
    80003cc8:	7179                	addi	sp,sp,-48
    80003cca:	f406                	sd	ra,40(sp)
    80003ccc:	f022                	sd	s0,32(sp)
    80003cce:	ec26                	sd	s1,24(sp)
    80003cd0:	1800                	addi	s0,sp,48
  int interval;
  uint64 handler;
  argint(0, &interval);
    80003cd2:	fdc40593          	addi	a1,s0,-36
    80003cd6:	4501                	li	a0,0
    80003cd8:	00000097          	auipc	ra,0x0
    80003cdc:	c7c080e7          	jalr	-900(ra) # 80003954 <argint>
  argaddr(1, &handler);
    80003ce0:	fd040593          	addi	a1,s0,-48
    80003ce4:	4505                	li	a0,1
    80003ce6:	00000097          	auipc	ra,0x0
    80003cea:	c8e080e7          	jalr	-882(ra) # 80003974 <argaddr>
  if(interval < 0 || handler < 0)
    80003cee:	fdc42783          	lw	a5,-36(s0)
    return -1;
    80003cf2:	557d                	li	a0,-1
  if(interval < 0 || handler < 0)
    80003cf4:	0407c663          	bltz	a5,80003d40 <sys_sigalarm+0x78>
  myproc()->interval_ticks = interval;
    80003cf8:	ffffe097          	auipc	ra,0xffffe
    80003cfc:	cb4080e7          	jalr	-844(ra) # 800019ac <myproc>
    80003d00:	fdc42783          	lw	a5,-36(s0)
    80003d04:	18f52023          	sw	a5,384(a0)
  myproc()->handler = handler;
    80003d08:	ffffe097          	auipc	ra,0xffffe
    80003d0c:	ca4080e7          	jalr	-860(ra) # 800019ac <myproc>
    80003d10:	fd043783          	ld	a5,-48(s0)
    80003d14:	16f53c23          	sd	a5,376(a0)
  myproc()->alarm_on = 0;
    80003d18:	ffffe097          	auipc	ra,0xffffe
    80003d1c:	c94080e7          	jalr	-876(ra) # 800019ac <myproc>
    80003d20:	18052823          	sw	zero,400(a0)
  myproc()->atime = myproc()->rtime;
    80003d24:	ffffe097          	auipc	ra,0xffffe
    80003d28:	c88080e7          	jalr	-888(ra) # 800019ac <myproc>
    80003d2c:	84aa                	mv	s1,a0
    80003d2e:	ffffe097          	auipc	ra,0xffffe
    80003d32:	c7e080e7          	jalr	-898(ra) # 800019ac <myproc>
    80003d36:	1684a783          	lw	a5,360(s1)
    80003d3a:	18f52a23          	sw	a5,404(a0)

  return 0;
    80003d3e:	4501                	li	a0,0
}
    80003d40:	70a2                	ld	ra,40(sp)
    80003d42:	7402                	ld	s0,32(sp)
    80003d44:	64e2                	ld	s1,24(sp)
    80003d46:	6145                	addi	sp,sp,48
    80003d48:	8082                	ret

0000000080003d4a <sys_sigreturn>:

uint64
sys_sigreturn(void){
    80003d4a:	1101                	addi	sp,sp,-32
    80003d4c:	ec06                	sd	ra,24(sp)
    80003d4e:	e822                	sd	s0,16(sp)
    80003d50:	e426                	sd	s1,8(sp)
    80003d52:	1000                	addi	s0,sp,32
  struct proc* pr = myproc();
    80003d54:	ffffe097          	auipc	ra,0xffffe
    80003d58:	c58080e7          	jalr	-936(ra) # 800019ac <myproc>
    80003d5c:	84aa                	mv	s1,a0
  memmove(pr->trapframe, pr->cached_alarm_tf, PGSIZE);
    80003d5e:	6605                	lui	a2,0x1
    80003d60:	18853583          	ld	a1,392(a0)
    80003d64:	6d28                	ld	a0,88(a0)
    80003d66:	ffffd097          	auipc	ra,0xffffd
    80003d6a:	fc8080e7          	jalr	-56(ra) # 80000d2e <memmove>

  kfree(pr->cached_alarm_tf);
    80003d6e:	1884b503          	ld	a0,392(s1)
    80003d72:	ffffd097          	auipc	ra,0xffffd
    80003d76:	c76080e7          	jalr	-906(ra) # 800009e8 <kfree>
  pr->cached_alarm_tf = 0;
    80003d7a:	1804b423          	sd	zero,392(s1)
  pr->alarm_on = 0;
    80003d7e:	1804a823          	sw	zero,400(s1)

  return pr->trapframe->a0;
    80003d82:	6cbc                	ld	a5,88(s1)
    80003d84:	7ba8                	ld	a0,112(a5)
    80003d86:	60e2                	ld	ra,24(sp)
    80003d88:	6442                	ld	s0,16(sp)
    80003d8a:	64a2                	ld	s1,8(sp)
    80003d8c:	6105                	addi	sp,sp,32
    80003d8e:	8082                	ret

0000000080003d90 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003d90:	7179                	addi	sp,sp,-48
    80003d92:	f406                	sd	ra,40(sp)
    80003d94:	f022                	sd	s0,32(sp)
    80003d96:	ec26                	sd	s1,24(sp)
    80003d98:	e84a                	sd	s2,16(sp)
    80003d9a:	e44e                	sd	s3,8(sp)
    80003d9c:	e052                	sd	s4,0(sp)
    80003d9e:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003da0:	00005597          	auipc	a1,0x5
    80003da4:	7a858593          	addi	a1,a1,1960 # 80009548 <syscalls+0xd0>
    80003da8:	00015517          	auipc	a0,0x15
    80003dac:	45050513          	addi	a0,a0,1104 # 800191f8 <bcache>
    80003db0:	ffffd097          	auipc	ra,0xffffd
    80003db4:	d96080e7          	jalr	-618(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003db8:	0001d797          	auipc	a5,0x1d
    80003dbc:	44078793          	addi	a5,a5,1088 # 800211f8 <bcache+0x8000>
    80003dc0:	0001d717          	auipc	a4,0x1d
    80003dc4:	6a070713          	addi	a4,a4,1696 # 80021460 <bcache+0x8268>
    80003dc8:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003dcc:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003dd0:	00015497          	auipc	s1,0x15
    80003dd4:	44048493          	addi	s1,s1,1088 # 80019210 <bcache+0x18>
    b->next = bcache.head.next;
    80003dd8:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003dda:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ddc:	00005a17          	auipc	s4,0x5
    80003de0:	774a0a13          	addi	s4,s4,1908 # 80009550 <syscalls+0xd8>
    b->next = bcache.head.next;
    80003de4:	2b893783          	ld	a5,696(s2)
    80003de8:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003dea:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003dee:	85d2                	mv	a1,s4
    80003df0:	01048513          	addi	a0,s1,16
    80003df4:	00001097          	auipc	ra,0x1
    80003df8:	4c8080e7          	jalr	1224(ra) # 800052bc <initsleeplock>
    bcache.head.next->prev = b;
    80003dfc:	2b893783          	ld	a5,696(s2)
    80003e00:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003e02:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003e06:	45848493          	addi	s1,s1,1112
    80003e0a:	fd349de3          	bne	s1,s3,80003de4 <binit+0x54>
  }
}
    80003e0e:	70a2                	ld	ra,40(sp)
    80003e10:	7402                	ld	s0,32(sp)
    80003e12:	64e2                	ld	s1,24(sp)
    80003e14:	6942                	ld	s2,16(sp)
    80003e16:	69a2                	ld	s3,8(sp)
    80003e18:	6a02                	ld	s4,0(sp)
    80003e1a:	6145                	addi	sp,sp,48
    80003e1c:	8082                	ret

0000000080003e1e <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003e1e:	7179                	addi	sp,sp,-48
    80003e20:	f406                	sd	ra,40(sp)
    80003e22:	f022                	sd	s0,32(sp)
    80003e24:	ec26                	sd	s1,24(sp)
    80003e26:	e84a                	sd	s2,16(sp)
    80003e28:	e44e                	sd	s3,8(sp)
    80003e2a:	1800                	addi	s0,sp,48
    80003e2c:	892a                	mv	s2,a0
    80003e2e:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80003e30:	00015517          	auipc	a0,0x15
    80003e34:	3c850513          	addi	a0,a0,968 # 800191f8 <bcache>
    80003e38:	ffffd097          	auipc	ra,0xffffd
    80003e3c:	d9e080e7          	jalr	-610(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003e40:	0001d497          	auipc	s1,0x1d
    80003e44:	6704b483          	ld	s1,1648(s1) # 800214b0 <bcache+0x82b8>
    80003e48:	0001d797          	auipc	a5,0x1d
    80003e4c:	61878793          	addi	a5,a5,1560 # 80021460 <bcache+0x8268>
    80003e50:	02f48f63          	beq	s1,a5,80003e8e <bread+0x70>
    80003e54:	873e                	mv	a4,a5
    80003e56:	a021                	j	80003e5e <bread+0x40>
    80003e58:	68a4                	ld	s1,80(s1)
    80003e5a:	02e48a63          	beq	s1,a4,80003e8e <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003e5e:	449c                	lw	a5,8(s1)
    80003e60:	ff279ce3          	bne	a5,s2,80003e58 <bread+0x3a>
    80003e64:	44dc                	lw	a5,12(s1)
    80003e66:	ff3799e3          	bne	a5,s3,80003e58 <bread+0x3a>
      b->refcnt++;
    80003e6a:	40bc                	lw	a5,64(s1)
    80003e6c:	2785                	addiw	a5,a5,1
    80003e6e:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003e70:	00015517          	auipc	a0,0x15
    80003e74:	38850513          	addi	a0,a0,904 # 800191f8 <bcache>
    80003e78:	ffffd097          	auipc	ra,0xffffd
    80003e7c:	e12080e7          	jalr	-494(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003e80:	01048513          	addi	a0,s1,16
    80003e84:	00001097          	auipc	ra,0x1
    80003e88:	472080e7          	jalr	1138(ra) # 800052f6 <acquiresleep>
      return b;
    80003e8c:	a8b9                	j	80003eea <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003e8e:	0001d497          	auipc	s1,0x1d
    80003e92:	61a4b483          	ld	s1,1562(s1) # 800214a8 <bcache+0x82b0>
    80003e96:	0001d797          	auipc	a5,0x1d
    80003e9a:	5ca78793          	addi	a5,a5,1482 # 80021460 <bcache+0x8268>
    80003e9e:	00f48863          	beq	s1,a5,80003eae <bread+0x90>
    80003ea2:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003ea4:	40bc                	lw	a5,64(s1)
    80003ea6:	cf81                	beqz	a5,80003ebe <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ea8:	64a4                	ld	s1,72(s1)
    80003eaa:	fee49de3          	bne	s1,a4,80003ea4 <bread+0x86>
  panic("bget: no buffers");
    80003eae:	00005517          	auipc	a0,0x5
    80003eb2:	6aa50513          	addi	a0,a0,1706 # 80009558 <syscalls+0xe0>
    80003eb6:	ffffc097          	auipc	ra,0xffffc
    80003eba:	68a080e7          	jalr	1674(ra) # 80000540 <panic>
      b->dev = dev;
    80003ebe:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    80003ec2:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003ec6:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003eca:	4785                	li	a5,1
    80003ecc:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003ece:	00015517          	auipc	a0,0x15
    80003ed2:	32a50513          	addi	a0,a0,810 # 800191f8 <bcache>
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003ede:	01048513          	addi	a0,s1,16
    80003ee2:	00001097          	auipc	ra,0x1
    80003ee6:	414080e7          	jalr	1044(ra) # 800052f6 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003eea:	409c                	lw	a5,0(s1)
    80003eec:	cb89                	beqz	a5,80003efe <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003eee:	8526                	mv	a0,s1
    80003ef0:	70a2                	ld	ra,40(sp)
    80003ef2:	7402                	ld	s0,32(sp)
    80003ef4:	64e2                	ld	s1,24(sp)
    80003ef6:	6942                	ld	s2,16(sp)
    80003ef8:	69a2                	ld	s3,8(sp)
    80003efa:	6145                	addi	sp,sp,48
    80003efc:	8082                	ret
    virtio_disk_rw(b, 0);
    80003efe:	4581                	li	a1,0
    80003f00:	8526                	mv	a0,s1
    80003f02:	00003097          	auipc	ra,0x3
    80003f06:	ff0080e7          	jalr	-16(ra) # 80006ef2 <virtio_disk_rw>
    b->valid = 1;
    80003f0a:	4785                	li	a5,1
    80003f0c:	c09c                	sw	a5,0(s1)
  return b;
    80003f0e:	b7c5                	j	80003eee <bread+0xd0>

0000000080003f10 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003f10:	1101                	addi	sp,sp,-32
    80003f12:	ec06                	sd	ra,24(sp)
    80003f14:	e822                	sd	s0,16(sp)
    80003f16:	e426                	sd	s1,8(sp)
    80003f18:	1000                	addi	s0,sp,32
    80003f1a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003f1c:	0541                	addi	a0,a0,16
    80003f1e:	00001097          	auipc	ra,0x1
    80003f22:	472080e7          	jalr	1138(ra) # 80005390 <holdingsleep>
    80003f26:	cd01                	beqz	a0,80003f3e <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003f28:	4585                	li	a1,1
    80003f2a:	8526                	mv	a0,s1
    80003f2c:	00003097          	auipc	ra,0x3
    80003f30:	fc6080e7          	jalr	-58(ra) # 80006ef2 <virtio_disk_rw>
}
    80003f34:	60e2                	ld	ra,24(sp)
    80003f36:	6442                	ld	s0,16(sp)
    80003f38:	64a2                	ld	s1,8(sp)
    80003f3a:	6105                	addi	sp,sp,32
    80003f3c:	8082                	ret
    panic("bwrite");
    80003f3e:	00005517          	auipc	a0,0x5
    80003f42:	63250513          	addi	a0,a0,1586 # 80009570 <syscalls+0xf8>
    80003f46:	ffffc097          	auipc	ra,0xffffc
    80003f4a:	5fa080e7          	jalr	1530(ra) # 80000540 <panic>

0000000080003f4e <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003f4e:	1101                	addi	sp,sp,-32
    80003f50:	ec06                	sd	ra,24(sp)
    80003f52:	e822                	sd	s0,16(sp)
    80003f54:	e426                	sd	s1,8(sp)
    80003f56:	e04a                	sd	s2,0(sp)
    80003f58:	1000                	addi	s0,sp,32
    80003f5a:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003f5c:	01050913          	addi	s2,a0,16
    80003f60:	854a                	mv	a0,s2
    80003f62:	00001097          	auipc	ra,0x1
    80003f66:	42e080e7          	jalr	1070(ra) # 80005390 <holdingsleep>
    80003f6a:	c92d                	beqz	a0,80003fdc <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003f6c:	854a                	mv	a0,s2
    80003f6e:	00001097          	auipc	ra,0x1
    80003f72:	3de080e7          	jalr	990(ra) # 8000534c <releasesleep>

  acquire(&bcache.lock);
    80003f76:	00015517          	auipc	a0,0x15
    80003f7a:	28250513          	addi	a0,a0,642 # 800191f8 <bcache>
    80003f7e:	ffffd097          	auipc	ra,0xffffd
    80003f82:	c58080e7          	jalr	-936(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003f86:	40bc                	lw	a5,64(s1)
    80003f88:	37fd                	addiw	a5,a5,-1
    80003f8a:	0007871b          	sext.w	a4,a5
    80003f8e:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003f90:	eb05                	bnez	a4,80003fc0 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003f92:	68bc                	ld	a5,80(s1)
    80003f94:	64b8                	ld	a4,72(s1)
    80003f96:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003f98:	64bc                	ld	a5,72(s1)
    80003f9a:	68b8                	ld	a4,80(s1)
    80003f9c:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003f9e:	0001d797          	auipc	a5,0x1d
    80003fa2:	25a78793          	addi	a5,a5,602 # 800211f8 <bcache+0x8000>
    80003fa6:	2b87b703          	ld	a4,696(a5)
    80003faa:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003fac:	0001d717          	auipc	a4,0x1d
    80003fb0:	4b470713          	addi	a4,a4,1204 # 80021460 <bcache+0x8268>
    80003fb4:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003fb6:	2b87b703          	ld	a4,696(a5)
    80003fba:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003fbc:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003fc0:	00015517          	auipc	a0,0x15
    80003fc4:	23850513          	addi	a0,a0,568 # 800191f8 <bcache>
    80003fc8:	ffffd097          	auipc	ra,0xffffd
    80003fcc:	cc2080e7          	jalr	-830(ra) # 80000c8a <release>
}
    80003fd0:	60e2                	ld	ra,24(sp)
    80003fd2:	6442                	ld	s0,16(sp)
    80003fd4:	64a2                	ld	s1,8(sp)
    80003fd6:	6902                	ld	s2,0(sp)
    80003fd8:	6105                	addi	sp,sp,32
    80003fda:	8082                	ret
    panic("brelse");
    80003fdc:	00005517          	auipc	a0,0x5
    80003fe0:	59c50513          	addi	a0,a0,1436 # 80009578 <syscalls+0x100>
    80003fe4:	ffffc097          	auipc	ra,0xffffc
    80003fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>

0000000080003fec <bpin>:

void
bpin(struct buf *b) {
    80003fec:	1101                	addi	sp,sp,-32
    80003fee:	ec06                	sd	ra,24(sp)
    80003ff0:	e822                	sd	s0,16(sp)
    80003ff2:	e426                	sd	s1,8(sp)
    80003ff4:	1000                	addi	s0,sp,32
    80003ff6:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003ff8:	00015517          	auipc	a0,0x15
    80003ffc:	20050513          	addi	a0,a0,512 # 800191f8 <bcache>
    80004000:	ffffd097          	auipc	ra,0xffffd
    80004004:	bd6080e7          	jalr	-1066(ra) # 80000bd6 <acquire>
  b->refcnt++;
    80004008:	40bc                	lw	a5,64(s1)
    8000400a:	2785                	addiw	a5,a5,1
    8000400c:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000400e:	00015517          	auipc	a0,0x15
    80004012:	1ea50513          	addi	a0,a0,490 # 800191f8 <bcache>
    80004016:	ffffd097          	auipc	ra,0xffffd
    8000401a:	c74080e7          	jalr	-908(ra) # 80000c8a <release>
}
    8000401e:	60e2                	ld	ra,24(sp)
    80004020:	6442                	ld	s0,16(sp)
    80004022:	64a2                	ld	s1,8(sp)
    80004024:	6105                	addi	sp,sp,32
    80004026:	8082                	ret

0000000080004028 <bunpin>:

void
bunpin(struct buf *b) {
    80004028:	1101                	addi	sp,sp,-32
    8000402a:	ec06                	sd	ra,24(sp)
    8000402c:	e822                	sd	s0,16(sp)
    8000402e:	e426                	sd	s1,8(sp)
    80004030:	1000                	addi	s0,sp,32
    80004032:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80004034:	00015517          	auipc	a0,0x15
    80004038:	1c450513          	addi	a0,a0,452 # 800191f8 <bcache>
    8000403c:	ffffd097          	auipc	ra,0xffffd
    80004040:	b9a080e7          	jalr	-1126(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80004044:	40bc                	lw	a5,64(s1)
    80004046:	37fd                	addiw	a5,a5,-1
    80004048:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    8000404a:	00015517          	auipc	a0,0x15
    8000404e:	1ae50513          	addi	a0,a0,430 # 800191f8 <bcache>
    80004052:	ffffd097          	auipc	ra,0xffffd
    80004056:	c38080e7          	jalr	-968(ra) # 80000c8a <release>
}
    8000405a:	60e2                	ld	ra,24(sp)
    8000405c:	6442                	ld	s0,16(sp)
    8000405e:	64a2                	ld	s1,8(sp)
    80004060:	6105                	addi	sp,sp,32
    80004062:	8082                	ret

0000000080004064 <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80004064:	1101                	addi	sp,sp,-32
    80004066:	ec06                	sd	ra,24(sp)
    80004068:	e822                	sd	s0,16(sp)
    8000406a:	e426                	sd	s1,8(sp)
    8000406c:	e04a                	sd	s2,0(sp)
    8000406e:	1000                	addi	s0,sp,32
    80004070:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80004072:	00d5d59b          	srliw	a1,a1,0xd
    80004076:	0001e797          	auipc	a5,0x1e
    8000407a:	85e7a783          	lw	a5,-1954(a5) # 800218d4 <sb+0x1c>
    8000407e:	9dbd                	addw	a1,a1,a5
    80004080:	00000097          	auipc	ra,0x0
    80004084:	d9e080e7          	jalr	-610(ra) # 80003e1e <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80004088:	0074f713          	andi	a4,s1,7
    8000408c:	4785                	li	a5,1
    8000408e:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80004092:	14ce                	slli	s1,s1,0x33
    80004094:	90d9                	srli	s1,s1,0x36
    80004096:	00950733          	add	a4,a0,s1
    8000409a:	05874703          	lbu	a4,88(a4)
    8000409e:	00e7f6b3          	and	a3,a5,a4
    800040a2:	c69d                	beqz	a3,800040d0 <bfree+0x6c>
    800040a4:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800040a6:	94aa                	add	s1,s1,a0
    800040a8:	fff7c793          	not	a5,a5
    800040ac:	8f7d                	and	a4,a4,a5
    800040ae:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800040b2:	00001097          	auipc	ra,0x1
    800040b6:	126080e7          	jalr	294(ra) # 800051d8 <log_write>
  brelse(bp);
    800040ba:	854a                	mv	a0,s2
    800040bc:	00000097          	auipc	ra,0x0
    800040c0:	e92080e7          	jalr	-366(ra) # 80003f4e <brelse>
}
    800040c4:	60e2                	ld	ra,24(sp)
    800040c6:	6442                	ld	s0,16(sp)
    800040c8:	64a2                	ld	s1,8(sp)
    800040ca:	6902                	ld	s2,0(sp)
    800040cc:	6105                	addi	sp,sp,32
    800040ce:	8082                	ret
    panic("freeing free block");
    800040d0:	00005517          	auipc	a0,0x5
    800040d4:	4b050513          	addi	a0,a0,1200 # 80009580 <syscalls+0x108>
    800040d8:	ffffc097          	auipc	ra,0xffffc
    800040dc:	468080e7          	jalr	1128(ra) # 80000540 <panic>

00000000800040e0 <balloc>:
{
    800040e0:	711d                	addi	sp,sp,-96
    800040e2:	ec86                	sd	ra,88(sp)
    800040e4:	e8a2                	sd	s0,80(sp)
    800040e6:	e4a6                	sd	s1,72(sp)
    800040e8:	e0ca                	sd	s2,64(sp)
    800040ea:	fc4e                	sd	s3,56(sp)
    800040ec:	f852                	sd	s4,48(sp)
    800040ee:	f456                	sd	s5,40(sp)
    800040f0:	f05a                	sd	s6,32(sp)
    800040f2:	ec5e                	sd	s7,24(sp)
    800040f4:	e862                	sd	s8,16(sp)
    800040f6:	e466                	sd	s9,8(sp)
    800040f8:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    800040fa:	0001d797          	auipc	a5,0x1d
    800040fe:	7c27a783          	lw	a5,1986(a5) # 800218bc <sb+0x4>
    80004102:	cff5                	beqz	a5,800041fe <balloc+0x11e>
    80004104:	8baa                	mv	s7,a0
    80004106:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80004108:	0001db17          	auipc	s6,0x1d
    8000410c:	7b0b0b13          	addi	s6,s6,1968 # 800218b8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004110:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80004112:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80004114:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80004116:	6c89                	lui	s9,0x2
    80004118:	a061                	j	800041a0 <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000411a:	97ca                	add	a5,a5,s2
    8000411c:	8e55                	or	a2,a2,a3
    8000411e:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    80004122:	854a                	mv	a0,s2
    80004124:	00001097          	auipc	ra,0x1
    80004128:	0b4080e7          	jalr	180(ra) # 800051d8 <log_write>
        brelse(bp);
    8000412c:	854a                	mv	a0,s2
    8000412e:	00000097          	auipc	ra,0x0
    80004132:	e20080e7          	jalr	-480(ra) # 80003f4e <brelse>
  bp = bread(dev, bno);
    80004136:	85a6                	mv	a1,s1
    80004138:	855e                	mv	a0,s7
    8000413a:	00000097          	auipc	ra,0x0
    8000413e:	ce4080e7          	jalr	-796(ra) # 80003e1e <bread>
    80004142:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80004144:	40000613          	li	a2,1024
    80004148:	4581                	li	a1,0
    8000414a:	05850513          	addi	a0,a0,88
    8000414e:	ffffd097          	auipc	ra,0xffffd
    80004152:	b84080e7          	jalr	-1148(ra) # 80000cd2 <memset>
  log_write(bp);
    80004156:	854a                	mv	a0,s2
    80004158:	00001097          	auipc	ra,0x1
    8000415c:	080080e7          	jalr	128(ra) # 800051d8 <log_write>
  brelse(bp);
    80004160:	854a                	mv	a0,s2
    80004162:	00000097          	auipc	ra,0x0
    80004166:	dec080e7          	jalr	-532(ra) # 80003f4e <brelse>
}
    8000416a:	8526                	mv	a0,s1
    8000416c:	60e6                	ld	ra,88(sp)
    8000416e:	6446                	ld	s0,80(sp)
    80004170:	64a6                	ld	s1,72(sp)
    80004172:	6906                	ld	s2,64(sp)
    80004174:	79e2                	ld	s3,56(sp)
    80004176:	7a42                	ld	s4,48(sp)
    80004178:	7aa2                	ld	s5,40(sp)
    8000417a:	7b02                	ld	s6,32(sp)
    8000417c:	6be2                	ld	s7,24(sp)
    8000417e:	6c42                	ld	s8,16(sp)
    80004180:	6ca2                	ld	s9,8(sp)
    80004182:	6125                	addi	sp,sp,96
    80004184:	8082                	ret
    brelse(bp);
    80004186:	854a                	mv	a0,s2
    80004188:	00000097          	auipc	ra,0x0
    8000418c:	dc6080e7          	jalr	-570(ra) # 80003f4e <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80004190:	015c87bb          	addw	a5,s9,s5
    80004194:	00078a9b          	sext.w	s5,a5
    80004198:	004b2703          	lw	a4,4(s6)
    8000419c:	06eaf163          	bgeu	s5,a4,800041fe <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800041a0:	41fad79b          	sraiw	a5,s5,0x1f
    800041a4:	0137d79b          	srliw	a5,a5,0x13
    800041a8:	015787bb          	addw	a5,a5,s5
    800041ac:	40d7d79b          	sraiw	a5,a5,0xd
    800041b0:	01cb2583          	lw	a1,28(s6)
    800041b4:	9dbd                	addw	a1,a1,a5
    800041b6:	855e                	mv	a0,s7
    800041b8:	00000097          	auipc	ra,0x0
    800041bc:	c66080e7          	jalr	-922(ra) # 80003e1e <bread>
    800041c0:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800041c2:	004b2503          	lw	a0,4(s6)
    800041c6:	000a849b          	sext.w	s1,s5
    800041ca:	8762                	mv	a4,s8
    800041cc:	faa4fde3          	bgeu	s1,a0,80004186 <balloc+0xa6>
      m = 1 << (bi % 8);
    800041d0:	00777693          	andi	a3,a4,7
    800041d4:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    800041d8:	41f7579b          	sraiw	a5,a4,0x1f
    800041dc:	01d7d79b          	srliw	a5,a5,0x1d
    800041e0:	9fb9                	addw	a5,a5,a4
    800041e2:	4037d79b          	sraiw	a5,a5,0x3
    800041e6:	00f90633          	add	a2,s2,a5
    800041ea:	05864603          	lbu	a2,88(a2) # 1058 <_entry-0x7fffefa8>
    800041ee:	00c6f5b3          	and	a1,a3,a2
    800041f2:	d585                	beqz	a1,8000411a <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800041f4:	2705                	addiw	a4,a4,1
    800041f6:	2485                	addiw	s1,s1,1
    800041f8:	fd471ae3          	bne	a4,s4,800041cc <balloc+0xec>
    800041fc:	b769                	j	80004186 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    800041fe:	00005517          	auipc	a0,0x5
    80004202:	39a50513          	addi	a0,a0,922 # 80009598 <syscalls+0x120>
    80004206:	ffffc097          	auipc	ra,0xffffc
    8000420a:	384080e7          	jalr	900(ra) # 8000058a <printf>
  return 0;
    8000420e:	4481                	li	s1,0
    80004210:	bfa9                	j	8000416a <balloc+0x8a>

0000000080004212 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80004212:	7179                	addi	sp,sp,-48
    80004214:	f406                	sd	ra,40(sp)
    80004216:	f022                	sd	s0,32(sp)
    80004218:	ec26                	sd	s1,24(sp)
    8000421a:	e84a                	sd	s2,16(sp)
    8000421c:	e44e                	sd	s3,8(sp)
    8000421e:	e052                	sd	s4,0(sp)
    80004220:	1800                	addi	s0,sp,48
    80004222:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80004224:	47ad                	li	a5,11
    80004226:	02b7e863          	bltu	a5,a1,80004256 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    8000422a:	02059793          	slli	a5,a1,0x20
    8000422e:	01e7d593          	srli	a1,a5,0x1e
    80004232:	00b504b3          	add	s1,a0,a1
    80004236:	0504a903          	lw	s2,80(s1)
    8000423a:	06091e63          	bnez	s2,800042b6 <bmap+0xa4>
      addr = balloc(ip->dev);
    8000423e:	4108                	lw	a0,0(a0)
    80004240:	00000097          	auipc	ra,0x0
    80004244:	ea0080e7          	jalr	-352(ra) # 800040e0 <balloc>
    80004248:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000424c:	06090563          	beqz	s2,800042b6 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    80004250:	0524a823          	sw	s2,80(s1)
    80004254:	a08d                	j	800042b6 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    80004256:	ff45849b          	addiw	s1,a1,-12
    8000425a:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    8000425e:	0ff00793          	li	a5,255
    80004262:	08e7e563          	bltu	a5,a4,800042ec <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80004266:	08052903          	lw	s2,128(a0)
    8000426a:	00091d63          	bnez	s2,80004284 <bmap+0x72>
      addr = balloc(ip->dev);
    8000426e:	4108                	lw	a0,0(a0)
    80004270:	00000097          	auipc	ra,0x0
    80004274:	e70080e7          	jalr	-400(ra) # 800040e0 <balloc>
    80004278:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    8000427c:	02090d63          	beqz	s2,800042b6 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80004280:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80004284:	85ca                	mv	a1,s2
    80004286:	0009a503          	lw	a0,0(s3)
    8000428a:	00000097          	auipc	ra,0x0
    8000428e:	b94080e7          	jalr	-1132(ra) # 80003e1e <bread>
    80004292:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80004294:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80004298:	02049713          	slli	a4,s1,0x20
    8000429c:	01e75593          	srli	a1,a4,0x1e
    800042a0:	00b784b3          	add	s1,a5,a1
    800042a4:	0004a903          	lw	s2,0(s1)
    800042a8:	02090063          	beqz	s2,800042c8 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800042ac:	8552                	mv	a0,s4
    800042ae:	00000097          	auipc	ra,0x0
    800042b2:	ca0080e7          	jalr	-864(ra) # 80003f4e <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800042b6:	854a                	mv	a0,s2
    800042b8:	70a2                	ld	ra,40(sp)
    800042ba:	7402                	ld	s0,32(sp)
    800042bc:	64e2                	ld	s1,24(sp)
    800042be:	6942                	ld	s2,16(sp)
    800042c0:	69a2                	ld	s3,8(sp)
    800042c2:	6a02                	ld	s4,0(sp)
    800042c4:	6145                	addi	sp,sp,48
    800042c6:	8082                	ret
      addr = balloc(ip->dev);
    800042c8:	0009a503          	lw	a0,0(s3)
    800042cc:	00000097          	auipc	ra,0x0
    800042d0:	e14080e7          	jalr	-492(ra) # 800040e0 <balloc>
    800042d4:	0005091b          	sext.w	s2,a0
      if(addr){
    800042d8:	fc090ae3          	beqz	s2,800042ac <bmap+0x9a>
        a[bn] = addr;
    800042dc:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    800042e0:	8552                	mv	a0,s4
    800042e2:	00001097          	auipc	ra,0x1
    800042e6:	ef6080e7          	jalr	-266(ra) # 800051d8 <log_write>
    800042ea:	b7c9                	j	800042ac <bmap+0x9a>
  panic("bmap: out of range");
    800042ec:	00005517          	auipc	a0,0x5
    800042f0:	2c450513          	addi	a0,a0,708 # 800095b0 <syscalls+0x138>
    800042f4:	ffffc097          	auipc	ra,0xffffc
    800042f8:	24c080e7          	jalr	588(ra) # 80000540 <panic>

00000000800042fc <iget>:
{
    800042fc:	7179                	addi	sp,sp,-48
    800042fe:	f406                	sd	ra,40(sp)
    80004300:	f022                	sd	s0,32(sp)
    80004302:	ec26                	sd	s1,24(sp)
    80004304:	e84a                	sd	s2,16(sp)
    80004306:	e44e                	sd	s3,8(sp)
    80004308:	e052                	sd	s4,0(sp)
    8000430a:	1800                	addi	s0,sp,48
    8000430c:	89aa                	mv	s3,a0
    8000430e:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80004310:	0001d517          	auipc	a0,0x1d
    80004314:	5c850513          	addi	a0,a0,1480 # 800218d8 <itable>
    80004318:	ffffd097          	auipc	ra,0xffffd
    8000431c:	8be080e7          	jalr	-1858(ra) # 80000bd6 <acquire>
  empty = 0;
    80004320:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004322:	0001d497          	auipc	s1,0x1d
    80004326:	5ce48493          	addi	s1,s1,1486 # 800218f0 <itable+0x18>
    8000432a:	0001f697          	auipc	a3,0x1f
    8000432e:	05668693          	addi	a3,a3,86 # 80023380 <log>
    80004332:	a039                	j	80004340 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004334:	02090b63          	beqz	s2,8000436a <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004338:	08848493          	addi	s1,s1,136
    8000433c:	02d48a63          	beq	s1,a3,80004370 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    80004340:	449c                	lw	a5,8(s1)
    80004342:	fef059e3          	blez	a5,80004334 <iget+0x38>
    80004346:	4098                	lw	a4,0(s1)
    80004348:	ff3716e3          	bne	a4,s3,80004334 <iget+0x38>
    8000434c:	40d8                	lw	a4,4(s1)
    8000434e:	ff4713e3          	bne	a4,s4,80004334 <iget+0x38>
      ip->ref++;
    80004352:	2785                	addiw	a5,a5,1
    80004354:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004356:	0001d517          	auipc	a0,0x1d
    8000435a:	58250513          	addi	a0,a0,1410 # 800218d8 <itable>
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
      return ip;
    80004366:	8926                	mv	s2,s1
    80004368:	a03d                	j	80004396 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000436a:	f7f9                	bnez	a5,80004338 <iget+0x3c>
    8000436c:	8926                	mv	s2,s1
    8000436e:	b7e9                	j	80004338 <iget+0x3c>
  if(empty == 0)
    80004370:	02090c63          	beqz	s2,800043a8 <iget+0xac>
  ip->dev = dev;
    80004374:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004378:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    8000437c:	4785                	li	a5,1
    8000437e:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    80004382:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004386:	0001d517          	auipc	a0,0x1d
    8000438a:	55250513          	addi	a0,a0,1362 # 800218d8 <itable>
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	8fc080e7          	jalr	-1796(ra) # 80000c8a <release>
}
    80004396:	854a                	mv	a0,s2
    80004398:	70a2                	ld	ra,40(sp)
    8000439a:	7402                	ld	s0,32(sp)
    8000439c:	64e2                	ld	s1,24(sp)
    8000439e:	6942                	ld	s2,16(sp)
    800043a0:	69a2                	ld	s3,8(sp)
    800043a2:	6a02                	ld	s4,0(sp)
    800043a4:	6145                	addi	sp,sp,48
    800043a6:	8082                	ret
    panic("iget: no inodes");
    800043a8:	00005517          	auipc	a0,0x5
    800043ac:	22050513          	addi	a0,a0,544 # 800095c8 <syscalls+0x150>
    800043b0:	ffffc097          	auipc	ra,0xffffc
    800043b4:	190080e7          	jalr	400(ra) # 80000540 <panic>

00000000800043b8 <fsinit>:
fsinit(int dev) {
    800043b8:	7179                	addi	sp,sp,-48
    800043ba:	f406                	sd	ra,40(sp)
    800043bc:	f022                	sd	s0,32(sp)
    800043be:	ec26                	sd	s1,24(sp)
    800043c0:	e84a                	sd	s2,16(sp)
    800043c2:	e44e                	sd	s3,8(sp)
    800043c4:	1800                	addi	s0,sp,48
    800043c6:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800043c8:	4585                	li	a1,1
    800043ca:	00000097          	auipc	ra,0x0
    800043ce:	a54080e7          	jalr	-1452(ra) # 80003e1e <bread>
    800043d2:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800043d4:	0001d997          	auipc	s3,0x1d
    800043d8:	4e498993          	addi	s3,s3,1252 # 800218b8 <sb>
    800043dc:	02000613          	li	a2,32
    800043e0:	05850593          	addi	a1,a0,88
    800043e4:	854e                	mv	a0,s3
    800043e6:	ffffd097          	auipc	ra,0xffffd
    800043ea:	948080e7          	jalr	-1720(ra) # 80000d2e <memmove>
  brelse(bp);
    800043ee:	8526                	mv	a0,s1
    800043f0:	00000097          	auipc	ra,0x0
    800043f4:	b5e080e7          	jalr	-1186(ra) # 80003f4e <brelse>
  if(sb.magic != FSMAGIC)
    800043f8:	0009a703          	lw	a4,0(s3)
    800043fc:	102037b7          	lui	a5,0x10203
    80004400:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004404:	02f71263          	bne	a4,a5,80004428 <fsinit+0x70>
  initlog(dev, &sb);
    80004408:	0001d597          	auipc	a1,0x1d
    8000440c:	4b058593          	addi	a1,a1,1200 # 800218b8 <sb>
    80004410:	854a                	mv	a0,s2
    80004412:	00001097          	auipc	ra,0x1
    80004416:	b4a080e7          	jalr	-1206(ra) # 80004f5c <initlog>
}
    8000441a:	70a2                	ld	ra,40(sp)
    8000441c:	7402                	ld	s0,32(sp)
    8000441e:	64e2                	ld	s1,24(sp)
    80004420:	6942                	ld	s2,16(sp)
    80004422:	69a2                	ld	s3,8(sp)
    80004424:	6145                	addi	sp,sp,48
    80004426:	8082                	ret
    panic("invalid file system");
    80004428:	00005517          	auipc	a0,0x5
    8000442c:	1b050513          	addi	a0,a0,432 # 800095d8 <syscalls+0x160>
    80004430:	ffffc097          	auipc	ra,0xffffc
    80004434:	110080e7          	jalr	272(ra) # 80000540 <panic>

0000000080004438 <iinit>:
{
    80004438:	7179                	addi	sp,sp,-48
    8000443a:	f406                	sd	ra,40(sp)
    8000443c:	f022                	sd	s0,32(sp)
    8000443e:	ec26                	sd	s1,24(sp)
    80004440:	e84a                	sd	s2,16(sp)
    80004442:	e44e                	sd	s3,8(sp)
    80004444:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004446:	00005597          	auipc	a1,0x5
    8000444a:	1aa58593          	addi	a1,a1,426 # 800095f0 <syscalls+0x178>
    8000444e:	0001d517          	auipc	a0,0x1d
    80004452:	48a50513          	addi	a0,a0,1162 # 800218d8 <itable>
    80004456:	ffffc097          	auipc	ra,0xffffc
    8000445a:	6f0080e7          	jalr	1776(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    8000445e:	0001d497          	auipc	s1,0x1d
    80004462:	4a248493          	addi	s1,s1,1186 # 80021900 <itable+0x28>
    80004466:	0001f997          	auipc	s3,0x1f
    8000446a:	f2a98993          	addi	s3,s3,-214 # 80023390 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000446e:	00005917          	auipc	s2,0x5
    80004472:	18a90913          	addi	s2,s2,394 # 800095f8 <syscalls+0x180>
    80004476:	85ca                	mv	a1,s2
    80004478:	8526                	mv	a0,s1
    8000447a:	00001097          	auipc	ra,0x1
    8000447e:	e42080e7          	jalr	-446(ra) # 800052bc <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    80004482:	08848493          	addi	s1,s1,136
    80004486:	ff3498e3          	bne	s1,s3,80004476 <iinit+0x3e>
}
    8000448a:	70a2                	ld	ra,40(sp)
    8000448c:	7402                	ld	s0,32(sp)
    8000448e:	64e2                	ld	s1,24(sp)
    80004490:	6942                	ld	s2,16(sp)
    80004492:	69a2                	ld	s3,8(sp)
    80004494:	6145                	addi	sp,sp,48
    80004496:	8082                	ret

0000000080004498 <ialloc>:
{
    80004498:	715d                	addi	sp,sp,-80
    8000449a:	e486                	sd	ra,72(sp)
    8000449c:	e0a2                	sd	s0,64(sp)
    8000449e:	fc26                	sd	s1,56(sp)
    800044a0:	f84a                	sd	s2,48(sp)
    800044a2:	f44e                	sd	s3,40(sp)
    800044a4:	f052                	sd	s4,32(sp)
    800044a6:	ec56                	sd	s5,24(sp)
    800044a8:	e85a                	sd	s6,16(sp)
    800044aa:	e45e                	sd	s7,8(sp)
    800044ac:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800044ae:	0001d717          	auipc	a4,0x1d
    800044b2:	41672703          	lw	a4,1046(a4) # 800218c4 <sb+0xc>
    800044b6:	4785                	li	a5,1
    800044b8:	04e7fa63          	bgeu	a5,a4,8000450c <ialloc+0x74>
    800044bc:	8aaa                	mv	s5,a0
    800044be:	8bae                	mv	s7,a1
    800044c0:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800044c2:	0001da17          	auipc	s4,0x1d
    800044c6:	3f6a0a13          	addi	s4,s4,1014 # 800218b8 <sb>
    800044ca:	00048b1b          	sext.w	s6,s1
    800044ce:	0044d593          	srli	a1,s1,0x4
    800044d2:	018a2783          	lw	a5,24(s4)
    800044d6:	9dbd                	addw	a1,a1,a5
    800044d8:	8556                	mv	a0,s5
    800044da:	00000097          	auipc	ra,0x0
    800044de:	944080e7          	jalr	-1724(ra) # 80003e1e <bread>
    800044e2:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800044e4:	05850993          	addi	s3,a0,88
    800044e8:	00f4f793          	andi	a5,s1,15
    800044ec:	079a                	slli	a5,a5,0x6
    800044ee:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800044f0:	00099783          	lh	a5,0(s3)
    800044f4:	c3a1                	beqz	a5,80004534 <ialloc+0x9c>
    brelse(bp);
    800044f6:	00000097          	auipc	ra,0x0
    800044fa:	a58080e7          	jalr	-1448(ra) # 80003f4e <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800044fe:	0485                	addi	s1,s1,1
    80004500:	00ca2703          	lw	a4,12(s4)
    80004504:	0004879b          	sext.w	a5,s1
    80004508:	fce7e1e3          	bltu	a5,a4,800044ca <ialloc+0x32>
  printf("ialloc: no inodes\n");
    8000450c:	00005517          	auipc	a0,0x5
    80004510:	0f450513          	addi	a0,a0,244 # 80009600 <syscalls+0x188>
    80004514:	ffffc097          	auipc	ra,0xffffc
    80004518:	076080e7          	jalr	118(ra) # 8000058a <printf>
  return 0;
    8000451c:	4501                	li	a0,0
}
    8000451e:	60a6                	ld	ra,72(sp)
    80004520:	6406                	ld	s0,64(sp)
    80004522:	74e2                	ld	s1,56(sp)
    80004524:	7942                	ld	s2,48(sp)
    80004526:	79a2                	ld	s3,40(sp)
    80004528:	7a02                	ld	s4,32(sp)
    8000452a:	6ae2                	ld	s5,24(sp)
    8000452c:	6b42                	ld	s6,16(sp)
    8000452e:	6ba2                	ld	s7,8(sp)
    80004530:	6161                	addi	sp,sp,80
    80004532:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004534:	04000613          	li	a2,64
    80004538:	4581                	li	a1,0
    8000453a:	854e                	mv	a0,s3
    8000453c:	ffffc097          	auipc	ra,0xffffc
    80004540:	796080e7          	jalr	1942(ra) # 80000cd2 <memset>
      dip->type = type;
    80004544:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004548:	854a                	mv	a0,s2
    8000454a:	00001097          	auipc	ra,0x1
    8000454e:	c8e080e7          	jalr	-882(ra) # 800051d8 <log_write>
      brelse(bp);
    80004552:	854a                	mv	a0,s2
    80004554:	00000097          	auipc	ra,0x0
    80004558:	9fa080e7          	jalr	-1542(ra) # 80003f4e <brelse>
      return iget(dev, inum);
    8000455c:	85da                	mv	a1,s6
    8000455e:	8556                	mv	a0,s5
    80004560:	00000097          	auipc	ra,0x0
    80004564:	d9c080e7          	jalr	-612(ra) # 800042fc <iget>
    80004568:	bf5d                	j	8000451e <ialloc+0x86>

000000008000456a <iupdate>:
{
    8000456a:	1101                	addi	sp,sp,-32
    8000456c:	ec06                	sd	ra,24(sp)
    8000456e:	e822                	sd	s0,16(sp)
    80004570:	e426                	sd	s1,8(sp)
    80004572:	e04a                	sd	s2,0(sp)
    80004574:	1000                	addi	s0,sp,32
    80004576:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004578:	415c                	lw	a5,4(a0)
    8000457a:	0047d79b          	srliw	a5,a5,0x4
    8000457e:	0001d597          	auipc	a1,0x1d
    80004582:	3525a583          	lw	a1,850(a1) # 800218d0 <sb+0x18>
    80004586:	9dbd                	addw	a1,a1,a5
    80004588:	4108                	lw	a0,0(a0)
    8000458a:	00000097          	auipc	ra,0x0
    8000458e:	894080e7          	jalr	-1900(ra) # 80003e1e <bread>
    80004592:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004594:	05850793          	addi	a5,a0,88
    80004598:	40d8                	lw	a4,4(s1)
    8000459a:	8b3d                	andi	a4,a4,15
    8000459c:	071a                	slli	a4,a4,0x6
    8000459e:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800045a0:	04449703          	lh	a4,68(s1)
    800045a4:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800045a8:	04649703          	lh	a4,70(s1)
    800045ac:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800045b0:	04849703          	lh	a4,72(s1)
    800045b4:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    800045b8:	04a49703          	lh	a4,74(s1)
    800045bc:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    800045c0:	44f8                	lw	a4,76(s1)
    800045c2:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800045c4:	03400613          	li	a2,52
    800045c8:	05048593          	addi	a1,s1,80
    800045cc:	00c78513          	addi	a0,a5,12
    800045d0:	ffffc097          	auipc	ra,0xffffc
    800045d4:	75e080e7          	jalr	1886(ra) # 80000d2e <memmove>
  log_write(bp);
    800045d8:	854a                	mv	a0,s2
    800045da:	00001097          	auipc	ra,0x1
    800045de:	bfe080e7          	jalr	-1026(ra) # 800051d8 <log_write>
  brelse(bp);
    800045e2:	854a                	mv	a0,s2
    800045e4:	00000097          	auipc	ra,0x0
    800045e8:	96a080e7          	jalr	-1686(ra) # 80003f4e <brelse>
}
    800045ec:	60e2                	ld	ra,24(sp)
    800045ee:	6442                	ld	s0,16(sp)
    800045f0:	64a2                	ld	s1,8(sp)
    800045f2:	6902                	ld	s2,0(sp)
    800045f4:	6105                	addi	sp,sp,32
    800045f6:	8082                	ret

00000000800045f8 <idup>:
{
    800045f8:	1101                	addi	sp,sp,-32
    800045fa:	ec06                	sd	ra,24(sp)
    800045fc:	e822                	sd	s0,16(sp)
    800045fe:	e426                	sd	s1,8(sp)
    80004600:	1000                	addi	s0,sp,32
    80004602:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80004604:	0001d517          	auipc	a0,0x1d
    80004608:	2d450513          	addi	a0,a0,724 # 800218d8 <itable>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	5ca080e7          	jalr	1482(ra) # 80000bd6 <acquire>
  ip->ref++;
    80004614:	449c                	lw	a5,8(s1)
    80004616:	2785                	addiw	a5,a5,1
    80004618:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000461a:	0001d517          	auipc	a0,0x1d
    8000461e:	2be50513          	addi	a0,a0,702 # 800218d8 <itable>
    80004622:	ffffc097          	auipc	ra,0xffffc
    80004626:	668080e7          	jalr	1640(ra) # 80000c8a <release>
}
    8000462a:	8526                	mv	a0,s1
    8000462c:	60e2                	ld	ra,24(sp)
    8000462e:	6442                	ld	s0,16(sp)
    80004630:	64a2                	ld	s1,8(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <ilock>:
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	e426                	sd	s1,8(sp)
    8000463e:	e04a                	sd	s2,0(sp)
    80004640:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    80004642:	c115                	beqz	a0,80004666 <ilock+0x30>
    80004644:	84aa                	mv	s1,a0
    80004646:	451c                	lw	a5,8(a0)
    80004648:	00f05f63          	blez	a5,80004666 <ilock+0x30>
  acquiresleep(&ip->lock);
    8000464c:	0541                	addi	a0,a0,16
    8000464e:	00001097          	auipc	ra,0x1
    80004652:	ca8080e7          	jalr	-856(ra) # 800052f6 <acquiresleep>
  if(ip->valid == 0){
    80004656:	40bc                	lw	a5,64(s1)
    80004658:	cf99                	beqz	a5,80004676 <ilock+0x40>
}
    8000465a:	60e2                	ld	ra,24(sp)
    8000465c:	6442                	ld	s0,16(sp)
    8000465e:	64a2                	ld	s1,8(sp)
    80004660:	6902                	ld	s2,0(sp)
    80004662:	6105                	addi	sp,sp,32
    80004664:	8082                	ret
    panic("ilock");
    80004666:	00005517          	auipc	a0,0x5
    8000466a:	fb250513          	addi	a0,a0,-78 # 80009618 <syscalls+0x1a0>
    8000466e:	ffffc097          	auipc	ra,0xffffc
    80004672:	ed2080e7          	jalr	-302(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004676:	40dc                	lw	a5,4(s1)
    80004678:	0047d79b          	srliw	a5,a5,0x4
    8000467c:	0001d597          	auipc	a1,0x1d
    80004680:	2545a583          	lw	a1,596(a1) # 800218d0 <sb+0x18>
    80004684:	9dbd                	addw	a1,a1,a5
    80004686:	4088                	lw	a0,0(s1)
    80004688:	fffff097          	auipc	ra,0xfffff
    8000468c:	796080e7          	jalr	1942(ra) # 80003e1e <bread>
    80004690:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004692:	05850593          	addi	a1,a0,88
    80004696:	40dc                	lw	a5,4(s1)
    80004698:	8bbd                	andi	a5,a5,15
    8000469a:	079a                	slli	a5,a5,0x6
    8000469c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    8000469e:	00059783          	lh	a5,0(a1)
    800046a2:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800046a6:	00259783          	lh	a5,2(a1)
    800046aa:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800046ae:	00459783          	lh	a5,4(a1)
    800046b2:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800046b6:	00659783          	lh	a5,6(a1)
    800046ba:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800046be:	459c                	lw	a5,8(a1)
    800046c0:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800046c2:	03400613          	li	a2,52
    800046c6:	05b1                	addi	a1,a1,12
    800046c8:	05048513          	addi	a0,s1,80
    800046cc:	ffffc097          	auipc	ra,0xffffc
    800046d0:	662080e7          	jalr	1634(ra) # 80000d2e <memmove>
    brelse(bp);
    800046d4:	854a                	mv	a0,s2
    800046d6:	00000097          	auipc	ra,0x0
    800046da:	878080e7          	jalr	-1928(ra) # 80003f4e <brelse>
    ip->valid = 1;
    800046de:	4785                	li	a5,1
    800046e0:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800046e2:	04449783          	lh	a5,68(s1)
    800046e6:	fbb5                	bnez	a5,8000465a <ilock+0x24>
      panic("ilock: no type");
    800046e8:	00005517          	auipc	a0,0x5
    800046ec:	f3850513          	addi	a0,a0,-200 # 80009620 <syscalls+0x1a8>
    800046f0:	ffffc097          	auipc	ra,0xffffc
    800046f4:	e50080e7          	jalr	-432(ra) # 80000540 <panic>

00000000800046f8 <iunlock>:
{
    800046f8:	1101                	addi	sp,sp,-32
    800046fa:	ec06                	sd	ra,24(sp)
    800046fc:	e822                	sd	s0,16(sp)
    800046fe:	e426                	sd	s1,8(sp)
    80004700:	e04a                	sd	s2,0(sp)
    80004702:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80004704:	c905                	beqz	a0,80004734 <iunlock+0x3c>
    80004706:	84aa                	mv	s1,a0
    80004708:	01050913          	addi	s2,a0,16
    8000470c:	854a                	mv	a0,s2
    8000470e:	00001097          	auipc	ra,0x1
    80004712:	c82080e7          	jalr	-894(ra) # 80005390 <holdingsleep>
    80004716:	cd19                	beqz	a0,80004734 <iunlock+0x3c>
    80004718:	449c                	lw	a5,8(s1)
    8000471a:	00f05d63          	blez	a5,80004734 <iunlock+0x3c>
  releasesleep(&ip->lock);
    8000471e:	854a                	mv	a0,s2
    80004720:	00001097          	auipc	ra,0x1
    80004724:	c2c080e7          	jalr	-980(ra) # 8000534c <releasesleep>
}
    80004728:	60e2                	ld	ra,24(sp)
    8000472a:	6442                	ld	s0,16(sp)
    8000472c:	64a2                	ld	s1,8(sp)
    8000472e:	6902                	ld	s2,0(sp)
    80004730:	6105                	addi	sp,sp,32
    80004732:	8082                	ret
    panic("iunlock");
    80004734:	00005517          	auipc	a0,0x5
    80004738:	efc50513          	addi	a0,a0,-260 # 80009630 <syscalls+0x1b8>
    8000473c:	ffffc097          	auipc	ra,0xffffc
    80004740:	e04080e7          	jalr	-508(ra) # 80000540 <panic>

0000000080004744 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80004744:	7179                	addi	sp,sp,-48
    80004746:	f406                	sd	ra,40(sp)
    80004748:	f022                	sd	s0,32(sp)
    8000474a:	ec26                	sd	s1,24(sp)
    8000474c:	e84a                	sd	s2,16(sp)
    8000474e:	e44e                	sd	s3,8(sp)
    80004750:	e052                	sd	s4,0(sp)
    80004752:	1800                	addi	s0,sp,48
    80004754:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004756:	05050493          	addi	s1,a0,80
    8000475a:	08050913          	addi	s2,a0,128
    8000475e:	a021                	j	80004766 <itrunc+0x22>
    80004760:	0491                	addi	s1,s1,4
    80004762:	01248d63          	beq	s1,s2,8000477c <itrunc+0x38>
    if(ip->addrs[i]){
    80004766:	408c                	lw	a1,0(s1)
    80004768:	dde5                	beqz	a1,80004760 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    8000476a:	0009a503          	lw	a0,0(s3)
    8000476e:	00000097          	auipc	ra,0x0
    80004772:	8f6080e7          	jalr	-1802(ra) # 80004064 <bfree>
      ip->addrs[i] = 0;
    80004776:	0004a023          	sw	zero,0(s1)
    8000477a:	b7dd                	j	80004760 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    8000477c:	0809a583          	lw	a1,128(s3)
    80004780:	e185                	bnez	a1,800047a0 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80004782:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004786:	854e                	mv	a0,s3
    80004788:	00000097          	auipc	ra,0x0
    8000478c:	de2080e7          	jalr	-542(ra) # 8000456a <iupdate>
}
    80004790:	70a2                	ld	ra,40(sp)
    80004792:	7402                	ld	s0,32(sp)
    80004794:	64e2                	ld	s1,24(sp)
    80004796:	6942                	ld	s2,16(sp)
    80004798:	69a2                	ld	s3,8(sp)
    8000479a:	6a02                	ld	s4,0(sp)
    8000479c:	6145                	addi	sp,sp,48
    8000479e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800047a0:	0009a503          	lw	a0,0(s3)
    800047a4:	fffff097          	auipc	ra,0xfffff
    800047a8:	67a080e7          	jalr	1658(ra) # 80003e1e <bread>
    800047ac:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800047ae:	05850493          	addi	s1,a0,88
    800047b2:	45850913          	addi	s2,a0,1112
    800047b6:	a021                	j	800047be <itrunc+0x7a>
    800047b8:	0491                	addi	s1,s1,4
    800047ba:	01248b63          	beq	s1,s2,800047d0 <itrunc+0x8c>
      if(a[j])
    800047be:	408c                	lw	a1,0(s1)
    800047c0:	dde5                	beqz	a1,800047b8 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    800047c2:	0009a503          	lw	a0,0(s3)
    800047c6:	00000097          	auipc	ra,0x0
    800047ca:	89e080e7          	jalr	-1890(ra) # 80004064 <bfree>
    800047ce:	b7ed                	j	800047b8 <itrunc+0x74>
    brelse(bp);
    800047d0:	8552                	mv	a0,s4
    800047d2:	fffff097          	auipc	ra,0xfffff
    800047d6:	77c080e7          	jalr	1916(ra) # 80003f4e <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800047da:	0809a583          	lw	a1,128(s3)
    800047de:	0009a503          	lw	a0,0(s3)
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	882080e7          	jalr	-1918(ra) # 80004064 <bfree>
    ip->addrs[NDIRECT] = 0;
    800047ea:	0809a023          	sw	zero,128(s3)
    800047ee:	bf51                	j	80004782 <itrunc+0x3e>

00000000800047f0 <iput>:
{
    800047f0:	1101                	addi	sp,sp,-32
    800047f2:	ec06                	sd	ra,24(sp)
    800047f4:	e822                	sd	s0,16(sp)
    800047f6:	e426                	sd	s1,8(sp)
    800047f8:	e04a                	sd	s2,0(sp)
    800047fa:	1000                	addi	s0,sp,32
    800047fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800047fe:	0001d517          	auipc	a0,0x1d
    80004802:	0da50513          	addi	a0,a0,218 # 800218d8 <itable>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	3d0080e7          	jalr	976(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    8000480e:	4498                	lw	a4,8(s1)
    80004810:	4785                	li	a5,1
    80004812:	02f70363          	beq	a4,a5,80004838 <iput+0x48>
  ip->ref--;
    80004816:	449c                	lw	a5,8(s1)
    80004818:	37fd                	addiw	a5,a5,-1
    8000481a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000481c:	0001d517          	auipc	a0,0x1d
    80004820:	0bc50513          	addi	a0,a0,188 # 800218d8 <itable>
    80004824:	ffffc097          	auipc	ra,0xffffc
    80004828:	466080e7          	jalr	1126(ra) # 80000c8a <release>
}
    8000482c:	60e2                	ld	ra,24(sp)
    8000482e:	6442                	ld	s0,16(sp)
    80004830:	64a2                	ld	s1,8(sp)
    80004832:	6902                	ld	s2,0(sp)
    80004834:	6105                	addi	sp,sp,32
    80004836:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004838:	40bc                	lw	a5,64(s1)
    8000483a:	dff1                	beqz	a5,80004816 <iput+0x26>
    8000483c:	04a49783          	lh	a5,74(s1)
    80004840:	fbf9                	bnez	a5,80004816 <iput+0x26>
    acquiresleep(&ip->lock);
    80004842:	01048913          	addi	s2,s1,16
    80004846:	854a                	mv	a0,s2
    80004848:	00001097          	auipc	ra,0x1
    8000484c:	aae080e7          	jalr	-1362(ra) # 800052f6 <acquiresleep>
    release(&itable.lock);
    80004850:	0001d517          	auipc	a0,0x1d
    80004854:	08850513          	addi	a0,a0,136 # 800218d8 <itable>
    80004858:	ffffc097          	auipc	ra,0xffffc
    8000485c:	432080e7          	jalr	1074(ra) # 80000c8a <release>
    itrunc(ip);
    80004860:	8526                	mv	a0,s1
    80004862:	00000097          	auipc	ra,0x0
    80004866:	ee2080e7          	jalr	-286(ra) # 80004744 <itrunc>
    ip->type = 0;
    8000486a:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    8000486e:	8526                	mv	a0,s1
    80004870:	00000097          	auipc	ra,0x0
    80004874:	cfa080e7          	jalr	-774(ra) # 8000456a <iupdate>
    ip->valid = 0;
    80004878:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    8000487c:	854a                	mv	a0,s2
    8000487e:	00001097          	auipc	ra,0x1
    80004882:	ace080e7          	jalr	-1330(ra) # 8000534c <releasesleep>
    acquire(&itable.lock);
    80004886:	0001d517          	auipc	a0,0x1d
    8000488a:	05250513          	addi	a0,a0,82 # 800218d8 <itable>
    8000488e:	ffffc097          	auipc	ra,0xffffc
    80004892:	348080e7          	jalr	840(ra) # 80000bd6 <acquire>
    80004896:	b741                	j	80004816 <iput+0x26>

0000000080004898 <iunlockput>:
{
    80004898:	1101                	addi	sp,sp,-32
    8000489a:	ec06                	sd	ra,24(sp)
    8000489c:	e822                	sd	s0,16(sp)
    8000489e:	e426                	sd	s1,8(sp)
    800048a0:	1000                	addi	s0,sp,32
    800048a2:	84aa                	mv	s1,a0
  iunlock(ip);
    800048a4:	00000097          	auipc	ra,0x0
    800048a8:	e54080e7          	jalr	-428(ra) # 800046f8 <iunlock>
  iput(ip);
    800048ac:	8526                	mv	a0,s1
    800048ae:	00000097          	auipc	ra,0x0
    800048b2:	f42080e7          	jalr	-190(ra) # 800047f0 <iput>
}
    800048b6:	60e2                	ld	ra,24(sp)
    800048b8:	6442                	ld	s0,16(sp)
    800048ba:	64a2                	ld	s1,8(sp)
    800048bc:	6105                	addi	sp,sp,32
    800048be:	8082                	ret

00000000800048c0 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800048c0:	1141                	addi	sp,sp,-16
    800048c2:	e422                	sd	s0,8(sp)
    800048c4:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800048c6:	411c                	lw	a5,0(a0)
    800048c8:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800048ca:	415c                	lw	a5,4(a0)
    800048cc:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800048ce:	04451783          	lh	a5,68(a0)
    800048d2:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800048d6:	04a51783          	lh	a5,74(a0)
    800048da:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800048de:	04c56783          	lwu	a5,76(a0)
    800048e2:	e99c                	sd	a5,16(a1)
}
    800048e4:	6422                	ld	s0,8(sp)
    800048e6:	0141                	addi	sp,sp,16
    800048e8:	8082                	ret

00000000800048ea <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800048ea:	457c                	lw	a5,76(a0)
    800048ec:	0ed7e963          	bltu	a5,a3,800049de <readi+0xf4>
{
    800048f0:	7159                	addi	sp,sp,-112
    800048f2:	f486                	sd	ra,104(sp)
    800048f4:	f0a2                	sd	s0,96(sp)
    800048f6:	eca6                	sd	s1,88(sp)
    800048f8:	e8ca                	sd	s2,80(sp)
    800048fa:	e4ce                	sd	s3,72(sp)
    800048fc:	e0d2                	sd	s4,64(sp)
    800048fe:	fc56                	sd	s5,56(sp)
    80004900:	f85a                	sd	s6,48(sp)
    80004902:	f45e                	sd	s7,40(sp)
    80004904:	f062                	sd	s8,32(sp)
    80004906:	ec66                	sd	s9,24(sp)
    80004908:	e86a                	sd	s10,16(sp)
    8000490a:	e46e                	sd	s11,8(sp)
    8000490c:	1880                	addi	s0,sp,112
    8000490e:	8b2a                	mv	s6,a0
    80004910:	8bae                	mv	s7,a1
    80004912:	8a32                	mv	s4,a2
    80004914:	84b6                	mv	s1,a3
    80004916:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004918:	9f35                	addw	a4,a4,a3
    return 0;
    8000491a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    8000491c:	0ad76063          	bltu	a4,a3,800049bc <readi+0xd2>
  if(off + n > ip->size)
    80004920:	00e7f463          	bgeu	a5,a4,80004928 <readi+0x3e>
    n = ip->size - off;
    80004924:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004928:	0a0a8963          	beqz	s5,800049da <readi+0xf0>
    8000492c:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    8000492e:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80004932:	5c7d                	li	s8,-1
    80004934:	a82d                	j	8000496e <readi+0x84>
    80004936:	020d1d93          	slli	s11,s10,0x20
    8000493a:	020ddd93          	srli	s11,s11,0x20
    8000493e:	05890613          	addi	a2,s2,88
    80004942:	86ee                	mv	a3,s11
    80004944:	963a                	add	a2,a2,a4
    80004946:	85d2                	mv	a1,s4
    80004948:	855e                	mv	a0,s7
    8000494a:	ffffe097          	auipc	ra,0xffffe
    8000494e:	740080e7          	jalr	1856(ra) # 8000308a <either_copyout>
    80004952:	05850d63          	beq	a0,s8,800049ac <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004956:	854a                	mv	a0,s2
    80004958:	fffff097          	auipc	ra,0xfffff
    8000495c:	5f6080e7          	jalr	1526(ra) # 80003f4e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004960:	013d09bb          	addw	s3,s10,s3
    80004964:	009d04bb          	addw	s1,s10,s1
    80004968:	9a6e                	add	s4,s4,s11
    8000496a:	0559f763          	bgeu	s3,s5,800049b8 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    8000496e:	00a4d59b          	srliw	a1,s1,0xa
    80004972:	855a                	mv	a0,s6
    80004974:	00000097          	auipc	ra,0x0
    80004978:	89e080e7          	jalr	-1890(ra) # 80004212 <bmap>
    8000497c:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004980:	cd85                	beqz	a1,800049b8 <readi+0xce>
    bp = bread(ip->dev, addr);
    80004982:	000b2503          	lw	a0,0(s6)
    80004986:	fffff097          	auipc	ra,0xfffff
    8000498a:	498080e7          	jalr	1176(ra) # 80003e1e <bread>
    8000498e:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004990:	3ff4f713          	andi	a4,s1,1023
    80004994:	40ec87bb          	subw	a5,s9,a4
    80004998:	413a86bb          	subw	a3,s5,s3
    8000499c:	8d3e                	mv	s10,a5
    8000499e:	2781                	sext.w	a5,a5
    800049a0:	0006861b          	sext.w	a2,a3
    800049a4:	f8f679e3          	bgeu	a2,a5,80004936 <readi+0x4c>
    800049a8:	8d36                	mv	s10,a3
    800049aa:	b771                	j	80004936 <readi+0x4c>
      brelse(bp);
    800049ac:	854a                	mv	a0,s2
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	5a0080e7          	jalr	1440(ra) # 80003f4e <brelse>
      tot = -1;
    800049b6:	59fd                	li	s3,-1
  }
  return tot;
    800049b8:	0009851b          	sext.w	a0,s3
}
    800049bc:	70a6                	ld	ra,104(sp)
    800049be:	7406                	ld	s0,96(sp)
    800049c0:	64e6                	ld	s1,88(sp)
    800049c2:	6946                	ld	s2,80(sp)
    800049c4:	69a6                	ld	s3,72(sp)
    800049c6:	6a06                	ld	s4,64(sp)
    800049c8:	7ae2                	ld	s5,56(sp)
    800049ca:	7b42                	ld	s6,48(sp)
    800049cc:	7ba2                	ld	s7,40(sp)
    800049ce:	7c02                	ld	s8,32(sp)
    800049d0:	6ce2                	ld	s9,24(sp)
    800049d2:	6d42                	ld	s10,16(sp)
    800049d4:	6da2                	ld	s11,8(sp)
    800049d6:	6165                	addi	sp,sp,112
    800049d8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800049da:	89d6                	mv	s3,s5
    800049dc:	bff1                	j	800049b8 <readi+0xce>
    return 0;
    800049de:	4501                	li	a0,0
}
    800049e0:	8082                	ret

00000000800049e2 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800049e2:	457c                	lw	a5,76(a0)
    800049e4:	10d7e863          	bltu	a5,a3,80004af4 <writei+0x112>
{
    800049e8:	7159                	addi	sp,sp,-112
    800049ea:	f486                	sd	ra,104(sp)
    800049ec:	f0a2                	sd	s0,96(sp)
    800049ee:	eca6                	sd	s1,88(sp)
    800049f0:	e8ca                	sd	s2,80(sp)
    800049f2:	e4ce                	sd	s3,72(sp)
    800049f4:	e0d2                	sd	s4,64(sp)
    800049f6:	fc56                	sd	s5,56(sp)
    800049f8:	f85a                	sd	s6,48(sp)
    800049fa:	f45e                	sd	s7,40(sp)
    800049fc:	f062                	sd	s8,32(sp)
    800049fe:	ec66                	sd	s9,24(sp)
    80004a00:	e86a                	sd	s10,16(sp)
    80004a02:	e46e                	sd	s11,8(sp)
    80004a04:	1880                	addi	s0,sp,112
    80004a06:	8aaa                	mv	s5,a0
    80004a08:	8bae                	mv	s7,a1
    80004a0a:	8a32                	mv	s4,a2
    80004a0c:	8936                	mv	s2,a3
    80004a0e:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80004a10:	00e687bb          	addw	a5,a3,a4
    80004a14:	0ed7e263          	bltu	a5,a3,80004af8 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004a18:	00043737          	lui	a4,0x43
    80004a1c:	0ef76063          	bltu	a4,a5,80004afc <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004a20:	0c0b0863          	beqz	s6,80004af0 <writei+0x10e>
    80004a24:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a26:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004a2a:	5c7d                	li	s8,-1
    80004a2c:	a091                	j	80004a70 <writei+0x8e>
    80004a2e:	020d1d93          	slli	s11,s10,0x20
    80004a32:	020ddd93          	srli	s11,s11,0x20
    80004a36:	05848513          	addi	a0,s1,88
    80004a3a:	86ee                	mv	a3,s11
    80004a3c:	8652                	mv	a2,s4
    80004a3e:	85de                	mv	a1,s7
    80004a40:	953a                	add	a0,a0,a4
    80004a42:	ffffe097          	auipc	ra,0xffffe
    80004a46:	69e080e7          	jalr	1694(ra) # 800030e0 <either_copyin>
    80004a4a:	07850263          	beq	a0,s8,80004aae <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004a4e:	8526                	mv	a0,s1
    80004a50:	00000097          	auipc	ra,0x0
    80004a54:	788080e7          	jalr	1928(ra) # 800051d8 <log_write>
    brelse(bp);
    80004a58:	8526                	mv	a0,s1
    80004a5a:	fffff097          	auipc	ra,0xfffff
    80004a5e:	4f4080e7          	jalr	1268(ra) # 80003f4e <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004a62:	013d09bb          	addw	s3,s10,s3
    80004a66:	012d093b          	addw	s2,s10,s2
    80004a6a:	9a6e                	add	s4,s4,s11
    80004a6c:	0569f663          	bgeu	s3,s6,80004ab8 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80004a70:	00a9559b          	srliw	a1,s2,0xa
    80004a74:	8556                	mv	a0,s5
    80004a76:	fffff097          	auipc	ra,0xfffff
    80004a7a:	79c080e7          	jalr	1948(ra) # 80004212 <bmap>
    80004a7e:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80004a82:	c99d                	beqz	a1,80004ab8 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80004a84:	000aa503          	lw	a0,0(s5)
    80004a88:	fffff097          	auipc	ra,0xfffff
    80004a8c:	396080e7          	jalr	918(ra) # 80003e1e <bread>
    80004a90:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80004a92:	3ff97713          	andi	a4,s2,1023
    80004a96:	40ec87bb          	subw	a5,s9,a4
    80004a9a:	413b06bb          	subw	a3,s6,s3
    80004a9e:	8d3e                	mv	s10,a5
    80004aa0:	2781                	sext.w	a5,a5
    80004aa2:	0006861b          	sext.w	a2,a3
    80004aa6:	f8f674e3          	bgeu	a2,a5,80004a2e <writei+0x4c>
    80004aaa:	8d36                	mv	s10,a3
    80004aac:	b749                	j	80004a2e <writei+0x4c>
      brelse(bp);
    80004aae:	8526                	mv	a0,s1
    80004ab0:	fffff097          	auipc	ra,0xfffff
    80004ab4:	49e080e7          	jalr	1182(ra) # 80003f4e <brelse>
  }

  if(off > ip->size)
    80004ab8:	04caa783          	lw	a5,76(s5)
    80004abc:	0127f463          	bgeu	a5,s2,80004ac4 <writei+0xe2>
    ip->size = off;
    80004ac0:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80004ac4:	8556                	mv	a0,s5
    80004ac6:	00000097          	auipc	ra,0x0
    80004aca:	aa4080e7          	jalr	-1372(ra) # 8000456a <iupdate>

  return tot;
    80004ace:	0009851b          	sext.w	a0,s3
}
    80004ad2:	70a6                	ld	ra,104(sp)
    80004ad4:	7406                	ld	s0,96(sp)
    80004ad6:	64e6                	ld	s1,88(sp)
    80004ad8:	6946                	ld	s2,80(sp)
    80004ada:	69a6                	ld	s3,72(sp)
    80004adc:	6a06                	ld	s4,64(sp)
    80004ade:	7ae2                	ld	s5,56(sp)
    80004ae0:	7b42                	ld	s6,48(sp)
    80004ae2:	7ba2                	ld	s7,40(sp)
    80004ae4:	7c02                	ld	s8,32(sp)
    80004ae6:	6ce2                	ld	s9,24(sp)
    80004ae8:	6d42                	ld	s10,16(sp)
    80004aea:	6da2                	ld	s11,8(sp)
    80004aec:	6165                	addi	sp,sp,112
    80004aee:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80004af0:	89da                	mv	s3,s6
    80004af2:	bfc9                	j	80004ac4 <writei+0xe2>
    return -1;
    80004af4:	557d                	li	a0,-1
}
    80004af6:	8082                	ret
    return -1;
    80004af8:	557d                	li	a0,-1
    80004afa:	bfe1                	j	80004ad2 <writei+0xf0>
    return -1;
    80004afc:	557d                	li	a0,-1
    80004afe:	bfd1                	j	80004ad2 <writei+0xf0>

0000000080004b00 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80004b00:	1141                	addi	sp,sp,-16
    80004b02:	e406                	sd	ra,8(sp)
    80004b04:	e022                	sd	s0,0(sp)
    80004b06:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004b08:	4639                	li	a2,14
    80004b0a:	ffffc097          	auipc	ra,0xffffc
    80004b0e:	298080e7          	jalr	664(ra) # 80000da2 <strncmp>
}
    80004b12:	60a2                	ld	ra,8(sp)
    80004b14:	6402                	ld	s0,0(sp)
    80004b16:	0141                	addi	sp,sp,16
    80004b18:	8082                	ret

0000000080004b1a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004b1a:	7139                	addi	sp,sp,-64
    80004b1c:	fc06                	sd	ra,56(sp)
    80004b1e:	f822                	sd	s0,48(sp)
    80004b20:	f426                	sd	s1,40(sp)
    80004b22:	f04a                	sd	s2,32(sp)
    80004b24:	ec4e                	sd	s3,24(sp)
    80004b26:	e852                	sd	s4,16(sp)
    80004b28:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004b2a:	04451703          	lh	a4,68(a0)
    80004b2e:	4785                	li	a5,1
    80004b30:	00f71a63          	bne	a4,a5,80004b44 <dirlookup+0x2a>
    80004b34:	892a                	mv	s2,a0
    80004b36:	89ae                	mv	s3,a1
    80004b38:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b3a:	457c                	lw	a5,76(a0)
    80004b3c:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004b3e:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b40:	e79d                	bnez	a5,80004b6e <dirlookup+0x54>
    80004b42:	a8a5                	j	80004bba <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80004b44:	00005517          	auipc	a0,0x5
    80004b48:	af450513          	addi	a0,a0,-1292 # 80009638 <syscalls+0x1c0>
    80004b4c:	ffffc097          	auipc	ra,0xffffc
    80004b50:	9f4080e7          	jalr	-1548(ra) # 80000540 <panic>
      panic("dirlookup read");
    80004b54:	00005517          	auipc	a0,0x5
    80004b58:	afc50513          	addi	a0,a0,-1284 # 80009650 <syscalls+0x1d8>
    80004b5c:	ffffc097          	auipc	ra,0xffffc
    80004b60:	9e4080e7          	jalr	-1564(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004b64:	24c1                	addiw	s1,s1,16
    80004b66:	04c92783          	lw	a5,76(s2)
    80004b6a:	04f4f763          	bgeu	s1,a5,80004bb8 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004b6e:	4741                	li	a4,16
    80004b70:	86a6                	mv	a3,s1
    80004b72:	fc040613          	addi	a2,s0,-64
    80004b76:	4581                	li	a1,0
    80004b78:	854a                	mv	a0,s2
    80004b7a:	00000097          	auipc	ra,0x0
    80004b7e:	d70080e7          	jalr	-656(ra) # 800048ea <readi>
    80004b82:	47c1                	li	a5,16
    80004b84:	fcf518e3          	bne	a0,a5,80004b54 <dirlookup+0x3a>
    if(de.inum == 0)
    80004b88:	fc045783          	lhu	a5,-64(s0)
    80004b8c:	dfe1                	beqz	a5,80004b64 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004b8e:	fc240593          	addi	a1,s0,-62
    80004b92:	854e                	mv	a0,s3
    80004b94:	00000097          	auipc	ra,0x0
    80004b98:	f6c080e7          	jalr	-148(ra) # 80004b00 <namecmp>
    80004b9c:	f561                	bnez	a0,80004b64 <dirlookup+0x4a>
      if(poff)
    80004b9e:	000a0463          	beqz	s4,80004ba6 <dirlookup+0x8c>
        *poff = off;
    80004ba2:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80004ba6:	fc045583          	lhu	a1,-64(s0)
    80004baa:	00092503          	lw	a0,0(s2)
    80004bae:	fffff097          	auipc	ra,0xfffff
    80004bb2:	74e080e7          	jalr	1870(ra) # 800042fc <iget>
    80004bb6:	a011                	j	80004bba <dirlookup+0xa0>
  return 0;
    80004bb8:	4501                	li	a0,0
}
    80004bba:	70e2                	ld	ra,56(sp)
    80004bbc:	7442                	ld	s0,48(sp)
    80004bbe:	74a2                	ld	s1,40(sp)
    80004bc0:	7902                	ld	s2,32(sp)
    80004bc2:	69e2                	ld	s3,24(sp)
    80004bc4:	6a42                	ld	s4,16(sp)
    80004bc6:	6121                	addi	sp,sp,64
    80004bc8:	8082                	ret

0000000080004bca <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80004bca:	711d                	addi	sp,sp,-96
    80004bcc:	ec86                	sd	ra,88(sp)
    80004bce:	e8a2                	sd	s0,80(sp)
    80004bd0:	e4a6                	sd	s1,72(sp)
    80004bd2:	e0ca                	sd	s2,64(sp)
    80004bd4:	fc4e                	sd	s3,56(sp)
    80004bd6:	f852                	sd	s4,48(sp)
    80004bd8:	f456                	sd	s5,40(sp)
    80004bda:	f05a                	sd	s6,32(sp)
    80004bdc:	ec5e                	sd	s7,24(sp)
    80004bde:	e862                	sd	s8,16(sp)
    80004be0:	e466                	sd	s9,8(sp)
    80004be2:	e06a                	sd	s10,0(sp)
    80004be4:	1080                	addi	s0,sp,96
    80004be6:	84aa                	mv	s1,a0
    80004be8:	8b2e                	mv	s6,a1
    80004bea:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80004bec:	00054703          	lbu	a4,0(a0)
    80004bf0:	02f00793          	li	a5,47
    80004bf4:	02f70363          	beq	a4,a5,80004c1a <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80004bf8:	ffffd097          	auipc	ra,0xffffd
    80004bfc:	db4080e7          	jalr	-588(ra) # 800019ac <myproc>
    80004c00:	15053503          	ld	a0,336(a0)
    80004c04:	00000097          	auipc	ra,0x0
    80004c08:	9f4080e7          	jalr	-1548(ra) # 800045f8 <idup>
    80004c0c:	8a2a                	mv	s4,a0
  while(*path == '/')
    80004c0e:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80004c12:	4cb5                	li	s9,13
  len = path - s;
    80004c14:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80004c16:	4c05                	li	s8,1
    80004c18:	a87d                	j	80004cd6 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80004c1a:	4585                	li	a1,1
    80004c1c:	4505                	li	a0,1
    80004c1e:	fffff097          	auipc	ra,0xfffff
    80004c22:	6de080e7          	jalr	1758(ra) # 800042fc <iget>
    80004c26:	8a2a                	mv	s4,a0
    80004c28:	b7dd                	j	80004c0e <namex+0x44>
      iunlockput(ip);
    80004c2a:	8552                	mv	a0,s4
    80004c2c:	00000097          	auipc	ra,0x0
    80004c30:	c6c080e7          	jalr	-916(ra) # 80004898 <iunlockput>
      return 0;
    80004c34:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80004c36:	8552                	mv	a0,s4
    80004c38:	60e6                	ld	ra,88(sp)
    80004c3a:	6446                	ld	s0,80(sp)
    80004c3c:	64a6                	ld	s1,72(sp)
    80004c3e:	6906                	ld	s2,64(sp)
    80004c40:	79e2                	ld	s3,56(sp)
    80004c42:	7a42                	ld	s4,48(sp)
    80004c44:	7aa2                	ld	s5,40(sp)
    80004c46:	7b02                	ld	s6,32(sp)
    80004c48:	6be2                	ld	s7,24(sp)
    80004c4a:	6c42                	ld	s8,16(sp)
    80004c4c:	6ca2                	ld	s9,8(sp)
    80004c4e:	6d02                	ld	s10,0(sp)
    80004c50:	6125                	addi	sp,sp,96
    80004c52:	8082                	ret
      iunlock(ip);
    80004c54:	8552                	mv	a0,s4
    80004c56:	00000097          	auipc	ra,0x0
    80004c5a:	aa2080e7          	jalr	-1374(ra) # 800046f8 <iunlock>
      return ip;
    80004c5e:	bfe1                	j	80004c36 <namex+0x6c>
      iunlockput(ip);
    80004c60:	8552                	mv	a0,s4
    80004c62:	00000097          	auipc	ra,0x0
    80004c66:	c36080e7          	jalr	-970(ra) # 80004898 <iunlockput>
      return 0;
    80004c6a:	8a4e                	mv	s4,s3
    80004c6c:	b7e9                	j	80004c36 <namex+0x6c>
  len = path - s;
    80004c6e:	40998633          	sub	a2,s3,s1
    80004c72:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80004c76:	09acd863          	bge	s9,s10,80004d06 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80004c7a:	4639                	li	a2,14
    80004c7c:	85a6                	mv	a1,s1
    80004c7e:	8556                	mv	a0,s5
    80004c80:	ffffc097          	auipc	ra,0xffffc
    80004c84:	0ae080e7          	jalr	174(ra) # 80000d2e <memmove>
    80004c88:	84ce                	mv	s1,s3
  while(*path == '/')
    80004c8a:	0004c783          	lbu	a5,0(s1)
    80004c8e:	01279763          	bne	a5,s2,80004c9c <namex+0xd2>
    path++;
    80004c92:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004c94:	0004c783          	lbu	a5,0(s1)
    80004c98:	ff278de3          	beq	a5,s2,80004c92 <namex+0xc8>
    ilock(ip);
    80004c9c:	8552                	mv	a0,s4
    80004c9e:	00000097          	auipc	ra,0x0
    80004ca2:	998080e7          	jalr	-1640(ra) # 80004636 <ilock>
    if(ip->type != T_DIR){
    80004ca6:	044a1783          	lh	a5,68(s4)
    80004caa:	f98790e3          	bne	a5,s8,80004c2a <namex+0x60>
    if(nameiparent && *path == '\0'){
    80004cae:	000b0563          	beqz	s6,80004cb8 <namex+0xee>
    80004cb2:	0004c783          	lbu	a5,0(s1)
    80004cb6:	dfd9                	beqz	a5,80004c54 <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004cb8:	865e                	mv	a2,s7
    80004cba:	85d6                	mv	a1,s5
    80004cbc:	8552                	mv	a0,s4
    80004cbe:	00000097          	auipc	ra,0x0
    80004cc2:	e5c080e7          	jalr	-420(ra) # 80004b1a <dirlookup>
    80004cc6:	89aa                	mv	s3,a0
    80004cc8:	dd41                	beqz	a0,80004c60 <namex+0x96>
    iunlockput(ip);
    80004cca:	8552                	mv	a0,s4
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	bcc080e7          	jalr	-1076(ra) # 80004898 <iunlockput>
    ip = next;
    80004cd4:	8a4e                	mv	s4,s3
  while(*path == '/')
    80004cd6:	0004c783          	lbu	a5,0(s1)
    80004cda:	01279763          	bne	a5,s2,80004ce8 <namex+0x11e>
    path++;
    80004cde:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004ce0:	0004c783          	lbu	a5,0(s1)
    80004ce4:	ff278de3          	beq	a5,s2,80004cde <namex+0x114>
  if(*path == 0)
    80004ce8:	cb9d                	beqz	a5,80004d1e <namex+0x154>
  while(*path != '/' && *path != 0)
    80004cea:	0004c783          	lbu	a5,0(s1)
    80004cee:	89a6                	mv	s3,s1
  len = path - s;
    80004cf0:	8d5e                	mv	s10,s7
    80004cf2:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004cf4:	01278963          	beq	a5,s2,80004d06 <namex+0x13c>
    80004cf8:	dbbd                	beqz	a5,80004c6e <namex+0xa4>
    path++;
    80004cfa:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80004cfc:	0009c783          	lbu	a5,0(s3)
    80004d00:	ff279ce3          	bne	a5,s2,80004cf8 <namex+0x12e>
    80004d04:	b7ad                	j	80004c6e <namex+0xa4>
    memmove(name, s, len);
    80004d06:	2601                	sext.w	a2,a2
    80004d08:	85a6                	mv	a1,s1
    80004d0a:	8556                	mv	a0,s5
    80004d0c:	ffffc097          	auipc	ra,0xffffc
    80004d10:	022080e7          	jalr	34(ra) # 80000d2e <memmove>
    name[len] = 0;
    80004d14:	9d56                	add	s10,s10,s5
    80004d16:	000d0023          	sb	zero,0(s10)
    80004d1a:	84ce                	mv	s1,s3
    80004d1c:	b7bd                	j	80004c8a <namex+0xc0>
  if(nameiparent){
    80004d1e:	f00b0ce3          	beqz	s6,80004c36 <namex+0x6c>
    iput(ip);
    80004d22:	8552                	mv	a0,s4
    80004d24:	00000097          	auipc	ra,0x0
    80004d28:	acc080e7          	jalr	-1332(ra) # 800047f0 <iput>
    return 0;
    80004d2c:	4a01                	li	s4,0
    80004d2e:	b721                	j	80004c36 <namex+0x6c>

0000000080004d30 <dirlink>:
{
    80004d30:	7139                	addi	sp,sp,-64
    80004d32:	fc06                	sd	ra,56(sp)
    80004d34:	f822                	sd	s0,48(sp)
    80004d36:	f426                	sd	s1,40(sp)
    80004d38:	f04a                	sd	s2,32(sp)
    80004d3a:	ec4e                	sd	s3,24(sp)
    80004d3c:	e852                	sd	s4,16(sp)
    80004d3e:	0080                	addi	s0,sp,64
    80004d40:	892a                	mv	s2,a0
    80004d42:	8a2e                	mv	s4,a1
    80004d44:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004d46:	4601                	li	a2,0
    80004d48:	00000097          	auipc	ra,0x0
    80004d4c:	dd2080e7          	jalr	-558(ra) # 80004b1a <dirlookup>
    80004d50:	e93d                	bnez	a0,80004dc6 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004d52:	04c92483          	lw	s1,76(s2)
    80004d56:	c49d                	beqz	s1,80004d84 <dirlink+0x54>
    80004d58:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d5a:	4741                	li	a4,16
    80004d5c:	86a6                	mv	a3,s1
    80004d5e:	fc040613          	addi	a2,s0,-64
    80004d62:	4581                	li	a1,0
    80004d64:	854a                	mv	a0,s2
    80004d66:	00000097          	auipc	ra,0x0
    80004d6a:	b84080e7          	jalr	-1148(ra) # 800048ea <readi>
    80004d6e:	47c1                	li	a5,16
    80004d70:	06f51163          	bne	a0,a5,80004dd2 <dirlink+0xa2>
    if(de.inum == 0)
    80004d74:	fc045783          	lhu	a5,-64(s0)
    80004d78:	c791                	beqz	a5,80004d84 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004d7a:	24c1                	addiw	s1,s1,16
    80004d7c:	04c92783          	lw	a5,76(s2)
    80004d80:	fcf4ede3          	bltu	s1,a5,80004d5a <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004d84:	4639                	li	a2,14
    80004d86:	85d2                	mv	a1,s4
    80004d88:	fc240513          	addi	a0,s0,-62
    80004d8c:	ffffc097          	auipc	ra,0xffffc
    80004d90:	052080e7          	jalr	82(ra) # 80000dde <strncpy>
  de.inum = inum;
    80004d94:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004d98:	4741                	li	a4,16
    80004d9a:	86a6                	mv	a3,s1
    80004d9c:	fc040613          	addi	a2,s0,-64
    80004da0:	4581                	li	a1,0
    80004da2:	854a                	mv	a0,s2
    80004da4:	00000097          	auipc	ra,0x0
    80004da8:	c3e080e7          	jalr	-962(ra) # 800049e2 <writei>
    80004dac:	1541                	addi	a0,a0,-16
    80004dae:	00a03533          	snez	a0,a0
    80004db2:	40a00533          	neg	a0,a0
}
    80004db6:	70e2                	ld	ra,56(sp)
    80004db8:	7442                	ld	s0,48(sp)
    80004dba:	74a2                	ld	s1,40(sp)
    80004dbc:	7902                	ld	s2,32(sp)
    80004dbe:	69e2                	ld	s3,24(sp)
    80004dc0:	6a42                	ld	s4,16(sp)
    80004dc2:	6121                	addi	sp,sp,64
    80004dc4:	8082                	ret
    iput(ip);
    80004dc6:	00000097          	auipc	ra,0x0
    80004dca:	a2a080e7          	jalr	-1494(ra) # 800047f0 <iput>
    return -1;
    80004dce:	557d                	li	a0,-1
    80004dd0:	b7dd                	j	80004db6 <dirlink+0x86>
      panic("dirlink read");
    80004dd2:	00005517          	auipc	a0,0x5
    80004dd6:	88e50513          	addi	a0,a0,-1906 # 80009660 <syscalls+0x1e8>
    80004dda:	ffffb097          	auipc	ra,0xffffb
    80004dde:	766080e7          	jalr	1894(ra) # 80000540 <panic>

0000000080004de2 <namei>:

struct inode*
namei(char *path)
{
    80004de2:	1101                	addi	sp,sp,-32
    80004de4:	ec06                	sd	ra,24(sp)
    80004de6:	e822                	sd	s0,16(sp)
    80004de8:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004dea:	fe040613          	addi	a2,s0,-32
    80004dee:	4581                	li	a1,0
    80004df0:	00000097          	auipc	ra,0x0
    80004df4:	dda080e7          	jalr	-550(ra) # 80004bca <namex>
}
    80004df8:	60e2                	ld	ra,24(sp)
    80004dfa:	6442                	ld	s0,16(sp)
    80004dfc:	6105                	addi	sp,sp,32
    80004dfe:	8082                	ret

0000000080004e00 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004e00:	1141                	addi	sp,sp,-16
    80004e02:	e406                	sd	ra,8(sp)
    80004e04:	e022                	sd	s0,0(sp)
    80004e06:	0800                	addi	s0,sp,16
    80004e08:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004e0a:	4585                	li	a1,1
    80004e0c:	00000097          	auipc	ra,0x0
    80004e10:	dbe080e7          	jalr	-578(ra) # 80004bca <namex>
}
    80004e14:	60a2                	ld	ra,8(sp)
    80004e16:	6402                	ld	s0,0(sp)
    80004e18:	0141                	addi	sp,sp,16
    80004e1a:	8082                	ret

0000000080004e1c <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004e1c:	1101                	addi	sp,sp,-32
    80004e1e:	ec06                	sd	ra,24(sp)
    80004e20:	e822                	sd	s0,16(sp)
    80004e22:	e426                	sd	s1,8(sp)
    80004e24:	e04a                	sd	s2,0(sp)
    80004e26:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004e28:	0001e917          	auipc	s2,0x1e
    80004e2c:	55890913          	addi	s2,s2,1368 # 80023380 <log>
    80004e30:	01892583          	lw	a1,24(s2)
    80004e34:	02892503          	lw	a0,40(s2)
    80004e38:	fffff097          	auipc	ra,0xfffff
    80004e3c:	fe6080e7          	jalr	-26(ra) # 80003e1e <bread>
    80004e40:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004e42:	02c92683          	lw	a3,44(s2)
    80004e46:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004e48:	02d05863          	blez	a3,80004e78 <write_head+0x5c>
    80004e4c:	0001e797          	auipc	a5,0x1e
    80004e50:	56478793          	addi	a5,a5,1380 # 800233b0 <log+0x30>
    80004e54:	05c50713          	addi	a4,a0,92
    80004e58:	36fd                	addiw	a3,a3,-1
    80004e5a:	02069613          	slli	a2,a3,0x20
    80004e5e:	01e65693          	srli	a3,a2,0x1e
    80004e62:	0001e617          	auipc	a2,0x1e
    80004e66:	55260613          	addi	a2,a2,1362 # 800233b4 <log+0x34>
    80004e6a:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004e6c:	4390                	lw	a2,0(a5)
    80004e6e:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004e70:	0791                	addi	a5,a5,4
    80004e72:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80004e74:	fed79ce3          	bne	a5,a3,80004e6c <write_head+0x50>
  }
  bwrite(buf);
    80004e78:	8526                	mv	a0,s1
    80004e7a:	fffff097          	auipc	ra,0xfffff
    80004e7e:	096080e7          	jalr	150(ra) # 80003f10 <bwrite>
  brelse(buf);
    80004e82:	8526                	mv	a0,s1
    80004e84:	fffff097          	auipc	ra,0xfffff
    80004e88:	0ca080e7          	jalr	202(ra) # 80003f4e <brelse>
}
    80004e8c:	60e2                	ld	ra,24(sp)
    80004e8e:	6442                	ld	s0,16(sp)
    80004e90:	64a2                	ld	s1,8(sp)
    80004e92:	6902                	ld	s2,0(sp)
    80004e94:	6105                	addi	sp,sp,32
    80004e96:	8082                	ret

0000000080004e98 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e98:	0001e797          	auipc	a5,0x1e
    80004e9c:	5147a783          	lw	a5,1300(a5) # 800233ac <log+0x2c>
    80004ea0:	0af05d63          	blez	a5,80004f5a <install_trans+0xc2>
{
    80004ea4:	7139                	addi	sp,sp,-64
    80004ea6:	fc06                	sd	ra,56(sp)
    80004ea8:	f822                	sd	s0,48(sp)
    80004eaa:	f426                	sd	s1,40(sp)
    80004eac:	f04a                	sd	s2,32(sp)
    80004eae:	ec4e                	sd	s3,24(sp)
    80004eb0:	e852                	sd	s4,16(sp)
    80004eb2:	e456                	sd	s5,8(sp)
    80004eb4:	e05a                	sd	s6,0(sp)
    80004eb6:	0080                	addi	s0,sp,64
    80004eb8:	8b2a                	mv	s6,a0
    80004eba:	0001ea97          	auipc	s5,0x1e
    80004ebe:	4f6a8a93          	addi	s5,s5,1270 # 800233b0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ec2:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004ec4:	0001e997          	auipc	s3,0x1e
    80004ec8:	4bc98993          	addi	s3,s3,1212 # 80023380 <log>
    80004ecc:	a00d                	j	80004eee <install_trans+0x56>
    brelse(lbuf);
    80004ece:	854a                	mv	a0,s2
    80004ed0:	fffff097          	auipc	ra,0xfffff
    80004ed4:	07e080e7          	jalr	126(ra) # 80003f4e <brelse>
    brelse(dbuf);
    80004ed8:	8526                	mv	a0,s1
    80004eda:	fffff097          	auipc	ra,0xfffff
    80004ede:	074080e7          	jalr	116(ra) # 80003f4e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004ee2:	2a05                	addiw	s4,s4,1
    80004ee4:	0a91                	addi	s5,s5,4
    80004ee6:	02c9a783          	lw	a5,44(s3)
    80004eea:	04fa5e63          	bge	s4,a5,80004f46 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004eee:	0189a583          	lw	a1,24(s3)
    80004ef2:	014585bb          	addw	a1,a1,s4
    80004ef6:	2585                	addiw	a1,a1,1
    80004ef8:	0289a503          	lw	a0,40(s3)
    80004efc:	fffff097          	auipc	ra,0xfffff
    80004f00:	f22080e7          	jalr	-222(ra) # 80003e1e <bread>
    80004f04:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004f06:	000aa583          	lw	a1,0(s5)
    80004f0a:	0289a503          	lw	a0,40(s3)
    80004f0e:	fffff097          	auipc	ra,0xfffff
    80004f12:	f10080e7          	jalr	-240(ra) # 80003e1e <bread>
    80004f16:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004f18:	40000613          	li	a2,1024
    80004f1c:	05890593          	addi	a1,s2,88
    80004f20:	05850513          	addi	a0,a0,88
    80004f24:	ffffc097          	auipc	ra,0xffffc
    80004f28:	e0a080e7          	jalr	-502(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    80004f2c:	8526                	mv	a0,s1
    80004f2e:	fffff097          	auipc	ra,0xfffff
    80004f32:	fe2080e7          	jalr	-30(ra) # 80003f10 <bwrite>
    if(recovering == 0)
    80004f36:	f80b1ce3          	bnez	s6,80004ece <install_trans+0x36>
      bunpin(dbuf);
    80004f3a:	8526                	mv	a0,s1
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	0ec080e7          	jalr	236(ra) # 80004028 <bunpin>
    80004f44:	b769                	j	80004ece <install_trans+0x36>
}
    80004f46:	70e2                	ld	ra,56(sp)
    80004f48:	7442                	ld	s0,48(sp)
    80004f4a:	74a2                	ld	s1,40(sp)
    80004f4c:	7902                	ld	s2,32(sp)
    80004f4e:	69e2                	ld	s3,24(sp)
    80004f50:	6a42                	ld	s4,16(sp)
    80004f52:	6aa2                	ld	s5,8(sp)
    80004f54:	6b02                	ld	s6,0(sp)
    80004f56:	6121                	addi	sp,sp,64
    80004f58:	8082                	ret
    80004f5a:	8082                	ret

0000000080004f5c <initlog>:
{
    80004f5c:	7179                	addi	sp,sp,-48
    80004f5e:	f406                	sd	ra,40(sp)
    80004f60:	f022                	sd	s0,32(sp)
    80004f62:	ec26                	sd	s1,24(sp)
    80004f64:	e84a                	sd	s2,16(sp)
    80004f66:	e44e                	sd	s3,8(sp)
    80004f68:	1800                	addi	s0,sp,48
    80004f6a:	892a                	mv	s2,a0
    80004f6c:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004f6e:	0001e497          	auipc	s1,0x1e
    80004f72:	41248493          	addi	s1,s1,1042 # 80023380 <log>
    80004f76:	00004597          	auipc	a1,0x4
    80004f7a:	6fa58593          	addi	a1,a1,1786 # 80009670 <syscalls+0x1f8>
    80004f7e:	8526                	mv	a0,s1
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	bc6080e7          	jalr	-1082(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004f88:	0149a583          	lw	a1,20(s3)
    80004f8c:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004f8e:	0109a783          	lw	a5,16(s3)
    80004f92:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004f94:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004f98:	854a                	mv	a0,s2
    80004f9a:	fffff097          	auipc	ra,0xfffff
    80004f9e:	e84080e7          	jalr	-380(ra) # 80003e1e <bread>
  log.lh.n = lh->n;
    80004fa2:	4d34                	lw	a3,88(a0)
    80004fa4:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004fa6:	02d05663          	blez	a3,80004fd2 <initlog+0x76>
    80004faa:	05c50793          	addi	a5,a0,92
    80004fae:	0001e717          	auipc	a4,0x1e
    80004fb2:	40270713          	addi	a4,a4,1026 # 800233b0 <log+0x30>
    80004fb6:	36fd                	addiw	a3,a3,-1
    80004fb8:	02069613          	slli	a2,a3,0x20
    80004fbc:	01e65693          	srli	a3,a2,0x1e
    80004fc0:	06050613          	addi	a2,a0,96
    80004fc4:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004fc6:	4390                	lw	a2,0(a5)
    80004fc8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004fca:	0791                	addi	a5,a5,4
    80004fcc:	0711                	addi	a4,a4,4
    80004fce:	fed79ce3          	bne	a5,a3,80004fc6 <initlog+0x6a>
  brelse(buf);
    80004fd2:	fffff097          	auipc	ra,0xfffff
    80004fd6:	f7c080e7          	jalr	-132(ra) # 80003f4e <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004fda:	4505                	li	a0,1
    80004fdc:	00000097          	auipc	ra,0x0
    80004fe0:	ebc080e7          	jalr	-324(ra) # 80004e98 <install_trans>
  log.lh.n = 0;
    80004fe4:	0001e797          	auipc	a5,0x1e
    80004fe8:	3c07a423          	sw	zero,968(a5) # 800233ac <log+0x2c>
  write_head(); // clear the log
    80004fec:	00000097          	auipc	ra,0x0
    80004ff0:	e30080e7          	jalr	-464(ra) # 80004e1c <write_head>
}
    80004ff4:	70a2                	ld	ra,40(sp)
    80004ff6:	7402                	ld	s0,32(sp)
    80004ff8:	64e2                	ld	s1,24(sp)
    80004ffa:	6942                	ld	s2,16(sp)
    80004ffc:	69a2                	ld	s3,8(sp)
    80004ffe:	6145                	addi	sp,sp,48
    80005000:	8082                	ret

0000000080005002 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80005002:	1101                	addi	sp,sp,-32
    80005004:	ec06                	sd	ra,24(sp)
    80005006:	e822                	sd	s0,16(sp)
    80005008:	e426                	sd	s1,8(sp)
    8000500a:	e04a                	sd	s2,0(sp)
    8000500c:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    8000500e:	0001e517          	auipc	a0,0x1e
    80005012:	37250513          	addi	a0,a0,882 # 80023380 <log>
    80005016:	ffffc097          	auipc	ra,0xffffc
    8000501a:	bc0080e7          	jalr	-1088(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    8000501e:	0001e497          	auipc	s1,0x1e
    80005022:	36248493          	addi	s1,s1,866 # 80023380 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80005026:	4979                	li	s2,30
    80005028:	a039                	j	80005036 <begin_op+0x34>
      sleep(&log, &log.lock);
    8000502a:	85a6                	mv	a1,s1
    8000502c:	8526                	mv	a0,s1
    8000502e:	ffffe097          	auipc	ra,0xffffe
    80005032:	c48080e7          	jalr	-952(ra) # 80002c76 <sleep>
    if(log.committing){
    80005036:	50dc                	lw	a5,36(s1)
    80005038:	fbed                	bnez	a5,8000502a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000503a:	5098                	lw	a4,32(s1)
    8000503c:	2705                	addiw	a4,a4,1
    8000503e:	0007069b          	sext.w	a3,a4
    80005042:	0027179b          	slliw	a5,a4,0x2
    80005046:	9fb9                	addw	a5,a5,a4
    80005048:	0017979b          	slliw	a5,a5,0x1
    8000504c:	54d8                	lw	a4,44(s1)
    8000504e:	9fb9                	addw	a5,a5,a4
    80005050:	00f95963          	bge	s2,a5,80005062 <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80005054:	85a6                	mv	a1,s1
    80005056:	8526                	mv	a0,s1
    80005058:	ffffe097          	auipc	ra,0xffffe
    8000505c:	c1e080e7          	jalr	-994(ra) # 80002c76 <sleep>
    80005060:	bfd9                	j	80005036 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80005062:	0001e517          	auipc	a0,0x1e
    80005066:	31e50513          	addi	a0,a0,798 # 80023380 <log>
    8000506a:	d114                	sw	a3,32(a0)
      release(&log.lock);
    8000506c:	ffffc097          	auipc	ra,0xffffc
    80005070:	c1e080e7          	jalr	-994(ra) # 80000c8a <release>
      break;
    }
  }
}
    80005074:	60e2                	ld	ra,24(sp)
    80005076:	6442                	ld	s0,16(sp)
    80005078:	64a2                	ld	s1,8(sp)
    8000507a:	6902                	ld	s2,0(sp)
    8000507c:	6105                	addi	sp,sp,32
    8000507e:	8082                	ret

0000000080005080 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80005080:	7139                	addi	sp,sp,-64
    80005082:	fc06                	sd	ra,56(sp)
    80005084:	f822                	sd	s0,48(sp)
    80005086:	f426                	sd	s1,40(sp)
    80005088:	f04a                	sd	s2,32(sp)
    8000508a:	ec4e                	sd	s3,24(sp)
    8000508c:	e852                	sd	s4,16(sp)
    8000508e:	e456                	sd	s5,8(sp)
    80005090:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80005092:	0001e497          	auipc	s1,0x1e
    80005096:	2ee48493          	addi	s1,s1,750 # 80023380 <log>
    8000509a:	8526                	mv	a0,s1
    8000509c:	ffffc097          	auipc	ra,0xffffc
    800050a0:	b3a080e7          	jalr	-1222(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    800050a4:	509c                	lw	a5,32(s1)
    800050a6:	37fd                	addiw	a5,a5,-1
    800050a8:	0007891b          	sext.w	s2,a5
    800050ac:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800050ae:	50dc                	lw	a5,36(s1)
    800050b0:	e7b9                	bnez	a5,800050fe <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800050b2:	04091e63          	bnez	s2,8000510e <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    800050b6:	0001e497          	auipc	s1,0x1e
    800050ba:	2ca48493          	addi	s1,s1,714 # 80023380 <log>
    800050be:	4785                	li	a5,1
    800050c0:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    800050c2:	8526                	mv	a0,s1
    800050c4:	ffffc097          	auipc	ra,0xffffc
    800050c8:	bc6080e7          	jalr	-1082(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    800050cc:	54dc                	lw	a5,44(s1)
    800050ce:	06f04763          	bgtz	a5,8000513c <end_op+0xbc>
    acquire(&log.lock);
    800050d2:	0001e497          	auipc	s1,0x1e
    800050d6:	2ae48493          	addi	s1,s1,686 # 80023380 <log>
    800050da:	8526                	mv	a0,s1
    800050dc:	ffffc097          	auipc	ra,0xffffc
    800050e0:	afa080e7          	jalr	-1286(ra) # 80000bd6 <acquire>
    log.committing = 0;
    800050e4:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    800050e8:	8526                	mv	a0,s1
    800050ea:	ffffe097          	auipc	ra,0xffffe
    800050ee:	bf0080e7          	jalr	-1040(ra) # 80002cda <wakeup>
    release(&log.lock);
    800050f2:	8526                	mv	a0,s1
    800050f4:	ffffc097          	auipc	ra,0xffffc
    800050f8:	b96080e7          	jalr	-1130(ra) # 80000c8a <release>
}
    800050fc:	a03d                	j	8000512a <end_op+0xaa>
    panic("log.committing");
    800050fe:	00004517          	auipc	a0,0x4
    80005102:	57a50513          	addi	a0,a0,1402 # 80009678 <syscalls+0x200>
    80005106:	ffffb097          	auipc	ra,0xffffb
    8000510a:	43a080e7          	jalr	1082(ra) # 80000540 <panic>
    wakeup(&log);
    8000510e:	0001e497          	auipc	s1,0x1e
    80005112:	27248493          	addi	s1,s1,626 # 80023380 <log>
    80005116:	8526                	mv	a0,s1
    80005118:	ffffe097          	auipc	ra,0xffffe
    8000511c:	bc2080e7          	jalr	-1086(ra) # 80002cda <wakeup>
  release(&log.lock);
    80005120:	8526                	mv	a0,s1
    80005122:	ffffc097          	auipc	ra,0xffffc
    80005126:	b68080e7          	jalr	-1176(ra) # 80000c8a <release>
}
    8000512a:	70e2                	ld	ra,56(sp)
    8000512c:	7442                	ld	s0,48(sp)
    8000512e:	74a2                	ld	s1,40(sp)
    80005130:	7902                	ld	s2,32(sp)
    80005132:	69e2                	ld	s3,24(sp)
    80005134:	6a42                	ld	s4,16(sp)
    80005136:	6aa2                	ld	s5,8(sp)
    80005138:	6121                	addi	sp,sp,64
    8000513a:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    8000513c:	0001ea97          	auipc	s5,0x1e
    80005140:	274a8a93          	addi	s5,s5,628 # 800233b0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80005144:	0001ea17          	auipc	s4,0x1e
    80005148:	23ca0a13          	addi	s4,s4,572 # 80023380 <log>
    8000514c:	018a2583          	lw	a1,24(s4)
    80005150:	012585bb          	addw	a1,a1,s2
    80005154:	2585                	addiw	a1,a1,1
    80005156:	028a2503          	lw	a0,40(s4)
    8000515a:	fffff097          	auipc	ra,0xfffff
    8000515e:	cc4080e7          	jalr	-828(ra) # 80003e1e <bread>
    80005162:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80005164:	000aa583          	lw	a1,0(s5)
    80005168:	028a2503          	lw	a0,40(s4)
    8000516c:	fffff097          	auipc	ra,0xfffff
    80005170:	cb2080e7          	jalr	-846(ra) # 80003e1e <bread>
    80005174:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80005176:	40000613          	li	a2,1024
    8000517a:	05850593          	addi	a1,a0,88
    8000517e:	05848513          	addi	a0,s1,88
    80005182:	ffffc097          	auipc	ra,0xffffc
    80005186:	bac080e7          	jalr	-1108(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	d84080e7          	jalr	-636(ra) # 80003f10 <bwrite>
    brelse(from);
    80005194:	854e                	mv	a0,s3
    80005196:	fffff097          	auipc	ra,0xfffff
    8000519a:	db8080e7          	jalr	-584(ra) # 80003f4e <brelse>
    brelse(to);
    8000519e:	8526                	mv	a0,s1
    800051a0:	fffff097          	auipc	ra,0xfffff
    800051a4:	dae080e7          	jalr	-594(ra) # 80003f4e <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800051a8:	2905                	addiw	s2,s2,1
    800051aa:	0a91                	addi	s5,s5,4
    800051ac:	02ca2783          	lw	a5,44(s4)
    800051b0:	f8f94ee3          	blt	s2,a5,8000514c <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800051b4:	00000097          	auipc	ra,0x0
    800051b8:	c68080e7          	jalr	-920(ra) # 80004e1c <write_head>
    install_trans(0); // Now install writes to home locations
    800051bc:	4501                	li	a0,0
    800051be:	00000097          	auipc	ra,0x0
    800051c2:	cda080e7          	jalr	-806(ra) # 80004e98 <install_trans>
    log.lh.n = 0;
    800051c6:	0001e797          	auipc	a5,0x1e
    800051ca:	1e07a323          	sw	zero,486(a5) # 800233ac <log+0x2c>
    write_head();    // Erase the transaction from the log
    800051ce:	00000097          	auipc	ra,0x0
    800051d2:	c4e080e7          	jalr	-946(ra) # 80004e1c <write_head>
    800051d6:	bdf5                	j	800050d2 <end_op+0x52>

00000000800051d8 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    800051d8:	1101                	addi	sp,sp,-32
    800051da:	ec06                	sd	ra,24(sp)
    800051dc:	e822                	sd	s0,16(sp)
    800051de:	e426                	sd	s1,8(sp)
    800051e0:	e04a                	sd	s2,0(sp)
    800051e2:	1000                	addi	s0,sp,32
    800051e4:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    800051e6:	0001e917          	auipc	s2,0x1e
    800051ea:	19a90913          	addi	s2,s2,410 # 80023380 <log>
    800051ee:	854a                	mv	a0,s2
    800051f0:	ffffc097          	auipc	ra,0xffffc
    800051f4:	9e6080e7          	jalr	-1562(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    800051f8:	02c92603          	lw	a2,44(s2)
    800051fc:	47f5                	li	a5,29
    800051fe:	06c7c563          	blt	a5,a2,80005268 <log_write+0x90>
    80005202:	0001e797          	auipc	a5,0x1e
    80005206:	19a7a783          	lw	a5,410(a5) # 8002339c <log+0x1c>
    8000520a:	37fd                	addiw	a5,a5,-1
    8000520c:	04f65e63          	bge	a2,a5,80005268 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80005210:	0001e797          	auipc	a5,0x1e
    80005214:	1907a783          	lw	a5,400(a5) # 800233a0 <log+0x20>
    80005218:	06f05063          	blez	a5,80005278 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    8000521c:	4781                	li	a5,0
    8000521e:	06c05563          	blez	a2,80005288 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80005222:	44cc                	lw	a1,12(s1)
    80005224:	0001e717          	auipc	a4,0x1e
    80005228:	18c70713          	addi	a4,a4,396 # 800233b0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    8000522c:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000522e:	4314                	lw	a3,0(a4)
    80005230:	04b68c63          	beq	a3,a1,80005288 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80005234:	2785                	addiw	a5,a5,1
    80005236:	0711                	addi	a4,a4,4
    80005238:	fef61be3          	bne	a2,a5,8000522e <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    8000523c:	0621                	addi	a2,a2,8
    8000523e:	060a                	slli	a2,a2,0x2
    80005240:	0001e797          	auipc	a5,0x1e
    80005244:	14078793          	addi	a5,a5,320 # 80023380 <log>
    80005248:	97b2                	add	a5,a5,a2
    8000524a:	44d8                	lw	a4,12(s1)
    8000524c:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    8000524e:	8526                	mv	a0,s1
    80005250:	fffff097          	auipc	ra,0xfffff
    80005254:	d9c080e7          	jalr	-612(ra) # 80003fec <bpin>
    log.lh.n++;
    80005258:	0001e717          	auipc	a4,0x1e
    8000525c:	12870713          	addi	a4,a4,296 # 80023380 <log>
    80005260:	575c                	lw	a5,44(a4)
    80005262:	2785                	addiw	a5,a5,1
    80005264:	d75c                	sw	a5,44(a4)
    80005266:	a82d                	j	800052a0 <log_write+0xc8>
    panic("too big a transaction");
    80005268:	00004517          	auipc	a0,0x4
    8000526c:	42050513          	addi	a0,a0,1056 # 80009688 <syscalls+0x210>
    80005270:	ffffb097          	auipc	ra,0xffffb
    80005274:	2d0080e7          	jalr	720(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80005278:	00004517          	auipc	a0,0x4
    8000527c:	42850513          	addi	a0,a0,1064 # 800096a0 <syscalls+0x228>
    80005280:	ffffb097          	auipc	ra,0xffffb
    80005284:	2c0080e7          	jalr	704(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80005288:	00878693          	addi	a3,a5,8
    8000528c:	068a                	slli	a3,a3,0x2
    8000528e:	0001e717          	auipc	a4,0x1e
    80005292:	0f270713          	addi	a4,a4,242 # 80023380 <log>
    80005296:	9736                	add	a4,a4,a3
    80005298:	44d4                	lw	a3,12(s1)
    8000529a:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    8000529c:	faf609e3          	beq	a2,a5,8000524e <log_write+0x76>
  }
  release(&log.lock);
    800052a0:	0001e517          	auipc	a0,0x1e
    800052a4:	0e050513          	addi	a0,a0,224 # 80023380 <log>
    800052a8:	ffffc097          	auipc	ra,0xffffc
    800052ac:	9e2080e7          	jalr	-1566(ra) # 80000c8a <release>
}
    800052b0:	60e2                	ld	ra,24(sp)
    800052b2:	6442                	ld	s0,16(sp)
    800052b4:	64a2                	ld	s1,8(sp)
    800052b6:	6902                	ld	s2,0(sp)
    800052b8:	6105                	addi	sp,sp,32
    800052ba:	8082                	ret

00000000800052bc <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    800052bc:	1101                	addi	sp,sp,-32
    800052be:	ec06                	sd	ra,24(sp)
    800052c0:	e822                	sd	s0,16(sp)
    800052c2:	e426                	sd	s1,8(sp)
    800052c4:	e04a                	sd	s2,0(sp)
    800052c6:	1000                	addi	s0,sp,32
    800052c8:	84aa                	mv	s1,a0
    800052ca:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    800052cc:	00004597          	auipc	a1,0x4
    800052d0:	3f458593          	addi	a1,a1,1012 # 800096c0 <syscalls+0x248>
    800052d4:	0521                	addi	a0,a0,8
    800052d6:	ffffc097          	auipc	ra,0xffffc
    800052da:	870080e7          	jalr	-1936(ra) # 80000b46 <initlock>
  lk->name = name;
    800052de:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    800052e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800052e6:	0204a423          	sw	zero,40(s1)
}
    800052ea:	60e2                	ld	ra,24(sp)
    800052ec:	6442                	ld	s0,16(sp)
    800052ee:	64a2                	ld	s1,8(sp)
    800052f0:	6902                	ld	s2,0(sp)
    800052f2:	6105                	addi	sp,sp,32
    800052f4:	8082                	ret

00000000800052f6 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    800052f6:	1101                	addi	sp,sp,-32
    800052f8:	ec06                	sd	ra,24(sp)
    800052fa:	e822                	sd	s0,16(sp)
    800052fc:	e426                	sd	s1,8(sp)
    800052fe:	e04a                	sd	s2,0(sp)
    80005300:	1000                	addi	s0,sp,32
    80005302:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80005304:	00850913          	addi	s2,a0,8
    80005308:	854a                	mv	a0,s2
    8000530a:	ffffc097          	auipc	ra,0xffffc
    8000530e:	8cc080e7          	jalr	-1844(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    80005312:	409c                	lw	a5,0(s1)
    80005314:	cb89                	beqz	a5,80005326 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80005316:	85ca                	mv	a1,s2
    80005318:	8526                	mv	a0,s1
    8000531a:	ffffe097          	auipc	ra,0xffffe
    8000531e:	95c080e7          	jalr	-1700(ra) # 80002c76 <sleep>
  while (lk->locked) {
    80005322:	409c                	lw	a5,0(s1)
    80005324:	fbed                	bnez	a5,80005316 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80005326:	4785                	li	a5,1
    80005328:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000532a:	ffffc097          	auipc	ra,0xffffc
    8000532e:	682080e7          	jalr	1666(ra) # 800019ac <myproc>
    80005332:	591c                	lw	a5,48(a0)
    80005334:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80005336:	854a                	mv	a0,s2
    80005338:	ffffc097          	auipc	ra,0xffffc
    8000533c:	952080e7          	jalr	-1710(ra) # 80000c8a <release>
}
    80005340:	60e2                	ld	ra,24(sp)
    80005342:	6442                	ld	s0,16(sp)
    80005344:	64a2                	ld	s1,8(sp)
    80005346:	6902                	ld	s2,0(sp)
    80005348:	6105                	addi	sp,sp,32
    8000534a:	8082                	ret

000000008000534c <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    8000534c:	1101                	addi	sp,sp,-32
    8000534e:	ec06                	sd	ra,24(sp)
    80005350:	e822                	sd	s0,16(sp)
    80005352:	e426                	sd	s1,8(sp)
    80005354:	e04a                	sd	s2,0(sp)
    80005356:	1000                	addi	s0,sp,32
    80005358:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000535a:	00850913          	addi	s2,a0,8
    8000535e:	854a                	mv	a0,s2
    80005360:	ffffc097          	auipc	ra,0xffffc
    80005364:	876080e7          	jalr	-1930(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80005368:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    8000536c:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005370:	8526                	mv	a0,s1
    80005372:	ffffe097          	auipc	ra,0xffffe
    80005376:	968080e7          	jalr	-1688(ra) # 80002cda <wakeup>
  release(&lk->lk);
    8000537a:	854a                	mv	a0,s2
    8000537c:	ffffc097          	auipc	ra,0xffffc
    80005380:	90e080e7          	jalr	-1778(ra) # 80000c8a <release>
}
    80005384:	60e2                	ld	ra,24(sp)
    80005386:	6442                	ld	s0,16(sp)
    80005388:	64a2                	ld	s1,8(sp)
    8000538a:	6902                	ld	s2,0(sp)
    8000538c:	6105                	addi	sp,sp,32
    8000538e:	8082                	ret

0000000080005390 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005390:	7179                	addi	sp,sp,-48
    80005392:	f406                	sd	ra,40(sp)
    80005394:	f022                	sd	s0,32(sp)
    80005396:	ec26                	sd	s1,24(sp)
    80005398:	e84a                	sd	s2,16(sp)
    8000539a:	e44e                	sd	s3,8(sp)
    8000539c:	1800                	addi	s0,sp,48
    8000539e:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800053a0:	00850913          	addi	s2,a0,8
    800053a4:	854a                	mv	a0,s2
    800053a6:	ffffc097          	auipc	ra,0xffffc
    800053aa:	830080e7          	jalr	-2000(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800053ae:	409c                	lw	a5,0(s1)
    800053b0:	ef99                	bnez	a5,800053ce <holdingsleep+0x3e>
    800053b2:	4481                	li	s1,0
  release(&lk->lk);
    800053b4:	854a                	mv	a0,s2
    800053b6:	ffffc097          	auipc	ra,0xffffc
    800053ba:	8d4080e7          	jalr	-1836(ra) # 80000c8a <release>
  return r;
}
    800053be:	8526                	mv	a0,s1
    800053c0:	70a2                	ld	ra,40(sp)
    800053c2:	7402                	ld	s0,32(sp)
    800053c4:	64e2                	ld	s1,24(sp)
    800053c6:	6942                	ld	s2,16(sp)
    800053c8:	69a2                	ld	s3,8(sp)
    800053ca:	6145                	addi	sp,sp,48
    800053cc:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800053ce:	0284a983          	lw	s3,40(s1)
    800053d2:	ffffc097          	auipc	ra,0xffffc
    800053d6:	5da080e7          	jalr	1498(ra) # 800019ac <myproc>
    800053da:	5904                	lw	s1,48(a0)
    800053dc:	413484b3          	sub	s1,s1,s3
    800053e0:	0014b493          	seqz	s1,s1
    800053e4:	bfc1                	j	800053b4 <holdingsleep+0x24>

00000000800053e6 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800053e6:	1141                	addi	sp,sp,-16
    800053e8:	e406                	sd	ra,8(sp)
    800053ea:	e022                	sd	s0,0(sp)
    800053ec:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800053ee:	00004597          	auipc	a1,0x4
    800053f2:	2e258593          	addi	a1,a1,738 # 800096d0 <syscalls+0x258>
    800053f6:	0001e517          	auipc	a0,0x1e
    800053fa:	0d250513          	addi	a0,a0,210 # 800234c8 <ftable>
    800053fe:	ffffb097          	auipc	ra,0xffffb
    80005402:	748080e7          	jalr	1864(ra) # 80000b46 <initlock>
}
    80005406:	60a2                	ld	ra,8(sp)
    80005408:	6402                	ld	s0,0(sp)
    8000540a:	0141                	addi	sp,sp,16
    8000540c:	8082                	ret

000000008000540e <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    8000540e:	1101                	addi	sp,sp,-32
    80005410:	ec06                	sd	ra,24(sp)
    80005412:	e822                	sd	s0,16(sp)
    80005414:	e426                	sd	s1,8(sp)
    80005416:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80005418:	0001e517          	auipc	a0,0x1e
    8000541c:	0b050513          	addi	a0,a0,176 # 800234c8 <ftable>
    80005420:	ffffb097          	auipc	ra,0xffffb
    80005424:	7b6080e7          	jalr	1974(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005428:	0001e497          	auipc	s1,0x1e
    8000542c:	0b848493          	addi	s1,s1,184 # 800234e0 <ftable+0x18>
    80005430:	0001f717          	auipc	a4,0x1f
    80005434:	05070713          	addi	a4,a4,80 # 80024480 <disk>
    if(f->ref == 0){
    80005438:	40dc                	lw	a5,4(s1)
    8000543a:	cf99                	beqz	a5,80005458 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000543c:	02848493          	addi	s1,s1,40
    80005440:	fee49ce3          	bne	s1,a4,80005438 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005444:	0001e517          	auipc	a0,0x1e
    80005448:	08450513          	addi	a0,a0,132 # 800234c8 <ftable>
    8000544c:	ffffc097          	auipc	ra,0xffffc
    80005450:	83e080e7          	jalr	-1986(ra) # 80000c8a <release>
  return 0;
    80005454:	4481                	li	s1,0
    80005456:	a819                	j	8000546c <filealloc+0x5e>
      f->ref = 1;
    80005458:	4785                	li	a5,1
    8000545a:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    8000545c:	0001e517          	auipc	a0,0x1e
    80005460:	06c50513          	addi	a0,a0,108 # 800234c8 <ftable>
    80005464:	ffffc097          	auipc	ra,0xffffc
    80005468:	826080e7          	jalr	-2010(ra) # 80000c8a <release>
}
    8000546c:	8526                	mv	a0,s1
    8000546e:	60e2                	ld	ra,24(sp)
    80005470:	6442                	ld	s0,16(sp)
    80005472:	64a2                	ld	s1,8(sp)
    80005474:	6105                	addi	sp,sp,32
    80005476:	8082                	ret

0000000080005478 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80005478:	1101                	addi	sp,sp,-32
    8000547a:	ec06                	sd	ra,24(sp)
    8000547c:	e822                	sd	s0,16(sp)
    8000547e:	e426                	sd	s1,8(sp)
    80005480:	1000                	addi	s0,sp,32
    80005482:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005484:	0001e517          	auipc	a0,0x1e
    80005488:	04450513          	addi	a0,a0,68 # 800234c8 <ftable>
    8000548c:	ffffb097          	auipc	ra,0xffffb
    80005490:	74a080e7          	jalr	1866(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80005494:	40dc                	lw	a5,4(s1)
    80005496:	02f05263          	blez	a5,800054ba <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000549a:	2785                	addiw	a5,a5,1
    8000549c:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    8000549e:	0001e517          	auipc	a0,0x1e
    800054a2:	02a50513          	addi	a0,a0,42 # 800234c8 <ftable>
    800054a6:	ffffb097          	auipc	ra,0xffffb
    800054aa:	7e4080e7          	jalr	2020(ra) # 80000c8a <release>
  return f;
}
    800054ae:	8526                	mv	a0,s1
    800054b0:	60e2                	ld	ra,24(sp)
    800054b2:	6442                	ld	s0,16(sp)
    800054b4:	64a2                	ld	s1,8(sp)
    800054b6:	6105                	addi	sp,sp,32
    800054b8:	8082                	ret
    panic("filedup");
    800054ba:	00004517          	auipc	a0,0x4
    800054be:	21e50513          	addi	a0,a0,542 # 800096d8 <syscalls+0x260>
    800054c2:	ffffb097          	auipc	ra,0xffffb
    800054c6:	07e080e7          	jalr	126(ra) # 80000540 <panic>

00000000800054ca <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800054ca:	7139                	addi	sp,sp,-64
    800054cc:	fc06                	sd	ra,56(sp)
    800054ce:	f822                	sd	s0,48(sp)
    800054d0:	f426                	sd	s1,40(sp)
    800054d2:	f04a                	sd	s2,32(sp)
    800054d4:	ec4e                	sd	s3,24(sp)
    800054d6:	e852                	sd	s4,16(sp)
    800054d8:	e456                	sd	s5,8(sp)
    800054da:	0080                	addi	s0,sp,64
    800054dc:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800054de:	0001e517          	auipc	a0,0x1e
    800054e2:	fea50513          	addi	a0,a0,-22 # 800234c8 <ftable>
    800054e6:	ffffb097          	auipc	ra,0xffffb
    800054ea:	6f0080e7          	jalr	1776(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    800054ee:	40dc                	lw	a5,4(s1)
    800054f0:	06f05163          	blez	a5,80005552 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800054f4:	37fd                	addiw	a5,a5,-1
    800054f6:	0007871b          	sext.w	a4,a5
    800054fa:	c0dc                	sw	a5,4(s1)
    800054fc:	06e04363          	bgtz	a4,80005562 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    80005500:	0004a903          	lw	s2,0(s1)
    80005504:	0094ca83          	lbu	s5,9(s1)
    80005508:	0104ba03          	ld	s4,16(s1)
    8000550c:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005510:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005514:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80005518:	0001e517          	auipc	a0,0x1e
    8000551c:	fb050513          	addi	a0,a0,-80 # 800234c8 <ftable>
    80005520:	ffffb097          	auipc	ra,0xffffb
    80005524:	76a080e7          	jalr	1898(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    80005528:	4785                	li	a5,1
    8000552a:	04f90d63          	beq	s2,a5,80005584 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    8000552e:	3979                	addiw	s2,s2,-2
    80005530:	4785                	li	a5,1
    80005532:	0527e063          	bltu	a5,s2,80005572 <fileclose+0xa8>
    begin_op();
    80005536:	00000097          	auipc	ra,0x0
    8000553a:	acc080e7          	jalr	-1332(ra) # 80005002 <begin_op>
    iput(ff.ip);
    8000553e:	854e                	mv	a0,s3
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	2b0080e7          	jalr	688(ra) # 800047f0 <iput>
    end_op();
    80005548:	00000097          	auipc	ra,0x0
    8000554c:	b38080e7          	jalr	-1224(ra) # 80005080 <end_op>
    80005550:	a00d                	j	80005572 <fileclose+0xa8>
    panic("fileclose");
    80005552:	00004517          	auipc	a0,0x4
    80005556:	18e50513          	addi	a0,a0,398 # 800096e0 <syscalls+0x268>
    8000555a:	ffffb097          	auipc	ra,0xffffb
    8000555e:	fe6080e7          	jalr	-26(ra) # 80000540 <panic>
    release(&ftable.lock);
    80005562:	0001e517          	auipc	a0,0x1e
    80005566:	f6650513          	addi	a0,a0,-154 # 800234c8 <ftable>
    8000556a:	ffffb097          	auipc	ra,0xffffb
    8000556e:	720080e7          	jalr	1824(ra) # 80000c8a <release>
  }
}
    80005572:	70e2                	ld	ra,56(sp)
    80005574:	7442                	ld	s0,48(sp)
    80005576:	74a2                	ld	s1,40(sp)
    80005578:	7902                	ld	s2,32(sp)
    8000557a:	69e2                	ld	s3,24(sp)
    8000557c:	6a42                	ld	s4,16(sp)
    8000557e:	6aa2                	ld	s5,8(sp)
    80005580:	6121                	addi	sp,sp,64
    80005582:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005584:	85d6                	mv	a1,s5
    80005586:	8552                	mv	a0,s4
    80005588:	00000097          	auipc	ra,0x0
    8000558c:	34c080e7          	jalr	844(ra) # 800058d4 <pipeclose>
    80005590:	b7cd                	j	80005572 <fileclose+0xa8>

0000000080005592 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005592:	715d                	addi	sp,sp,-80
    80005594:	e486                	sd	ra,72(sp)
    80005596:	e0a2                	sd	s0,64(sp)
    80005598:	fc26                	sd	s1,56(sp)
    8000559a:	f84a                	sd	s2,48(sp)
    8000559c:	f44e                	sd	s3,40(sp)
    8000559e:	0880                	addi	s0,sp,80
    800055a0:	84aa                	mv	s1,a0
    800055a2:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800055a4:	ffffc097          	auipc	ra,0xffffc
    800055a8:	408080e7          	jalr	1032(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800055ac:	409c                	lw	a5,0(s1)
    800055ae:	37f9                	addiw	a5,a5,-2
    800055b0:	4705                	li	a4,1
    800055b2:	04f76763          	bltu	a4,a5,80005600 <filestat+0x6e>
    800055b6:	892a                	mv	s2,a0
    ilock(f->ip);
    800055b8:	6c88                	ld	a0,24(s1)
    800055ba:	fffff097          	auipc	ra,0xfffff
    800055be:	07c080e7          	jalr	124(ra) # 80004636 <ilock>
    stati(f->ip, &st);
    800055c2:	fb840593          	addi	a1,s0,-72
    800055c6:	6c88                	ld	a0,24(s1)
    800055c8:	fffff097          	auipc	ra,0xfffff
    800055cc:	2f8080e7          	jalr	760(ra) # 800048c0 <stati>
    iunlock(f->ip);
    800055d0:	6c88                	ld	a0,24(s1)
    800055d2:	fffff097          	auipc	ra,0xfffff
    800055d6:	126080e7          	jalr	294(ra) # 800046f8 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800055da:	46e1                	li	a3,24
    800055dc:	fb840613          	addi	a2,s0,-72
    800055e0:	85ce                	mv	a1,s3
    800055e2:	05093503          	ld	a0,80(s2)
    800055e6:	ffffc097          	auipc	ra,0xffffc
    800055ea:	086080e7          	jalr	134(ra) # 8000166c <copyout>
    800055ee:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800055f2:	60a6                	ld	ra,72(sp)
    800055f4:	6406                	ld	s0,64(sp)
    800055f6:	74e2                	ld	s1,56(sp)
    800055f8:	7942                	ld	s2,48(sp)
    800055fa:	79a2                	ld	s3,40(sp)
    800055fc:	6161                	addi	sp,sp,80
    800055fe:	8082                	ret
  return -1;
    80005600:	557d                	li	a0,-1
    80005602:	bfc5                	j	800055f2 <filestat+0x60>

0000000080005604 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    80005604:	7179                	addi	sp,sp,-48
    80005606:	f406                	sd	ra,40(sp)
    80005608:	f022                	sd	s0,32(sp)
    8000560a:	ec26                	sd	s1,24(sp)
    8000560c:	e84a                	sd	s2,16(sp)
    8000560e:	e44e                	sd	s3,8(sp)
    80005610:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005612:	00854783          	lbu	a5,8(a0)
    80005616:	c3d5                	beqz	a5,800056ba <fileread+0xb6>
    80005618:	84aa                	mv	s1,a0
    8000561a:	89ae                	mv	s3,a1
    8000561c:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    8000561e:	411c                	lw	a5,0(a0)
    80005620:	4705                	li	a4,1
    80005622:	04e78963          	beq	a5,a4,80005674 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80005626:	470d                	li	a4,3
    80005628:	04e78d63          	beq	a5,a4,80005682 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    8000562c:	4709                	li	a4,2
    8000562e:	06e79e63          	bne	a5,a4,800056aa <fileread+0xa6>
    ilock(f->ip);
    80005632:	6d08                	ld	a0,24(a0)
    80005634:	fffff097          	auipc	ra,0xfffff
    80005638:	002080e7          	jalr	2(ra) # 80004636 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    8000563c:	874a                	mv	a4,s2
    8000563e:	5094                	lw	a3,32(s1)
    80005640:	864e                	mv	a2,s3
    80005642:	4585                	li	a1,1
    80005644:	6c88                	ld	a0,24(s1)
    80005646:	fffff097          	auipc	ra,0xfffff
    8000564a:	2a4080e7          	jalr	676(ra) # 800048ea <readi>
    8000564e:	892a                	mv	s2,a0
    80005650:	00a05563          	blez	a0,8000565a <fileread+0x56>
      f->off += r;
    80005654:	509c                	lw	a5,32(s1)
    80005656:	9fa9                	addw	a5,a5,a0
    80005658:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000565a:	6c88                	ld	a0,24(s1)
    8000565c:	fffff097          	auipc	ra,0xfffff
    80005660:	09c080e7          	jalr	156(ra) # 800046f8 <iunlock>
  } else {
    panic("fileread");
  }
  return r;
}
    80005664:	854a                	mv	a0,s2
    80005666:	70a2                	ld	ra,40(sp)
    80005668:	7402                	ld	s0,32(sp)
    8000566a:	64e2                	ld	s1,24(sp)
    8000566c:	6942                	ld	s2,16(sp)
    8000566e:	69a2                	ld	s3,8(sp)
    80005670:	6145                	addi	sp,sp,48
    80005672:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005674:	6908                	ld	a0,16(a0)
    80005676:	00000097          	auipc	ra,0x0
    8000567a:	3c6080e7          	jalr	966(ra) # 80005a3c <piperead>
    8000567e:	892a                	mv	s2,a0
    80005680:	b7d5                	j	80005664 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005682:	02451783          	lh	a5,36(a0)
    80005686:	03079693          	slli	a3,a5,0x30
    8000568a:	92c1                	srli	a3,a3,0x30
    8000568c:	4725                	li	a4,9
    8000568e:	02d76863          	bltu	a4,a3,800056be <fileread+0xba>
    80005692:	0792                	slli	a5,a5,0x4
    80005694:	0001e717          	auipc	a4,0x1e
    80005698:	d9470713          	addi	a4,a4,-620 # 80023428 <devsw>
    8000569c:	97ba                	add	a5,a5,a4
    8000569e:	639c                	ld	a5,0(a5)
    800056a0:	c38d                	beqz	a5,800056c2 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800056a2:	4505                	li	a0,1
    800056a4:	9782                	jalr	a5
    800056a6:	892a                	mv	s2,a0
    800056a8:	bf75                	j	80005664 <fileread+0x60>
    panic("fileread");
    800056aa:	00004517          	auipc	a0,0x4
    800056ae:	04650513          	addi	a0,a0,70 # 800096f0 <syscalls+0x278>
    800056b2:	ffffb097          	auipc	ra,0xffffb
    800056b6:	e8e080e7          	jalr	-370(ra) # 80000540 <panic>
    return -1;
    800056ba:	597d                	li	s2,-1
    800056bc:	b765                	j	80005664 <fileread+0x60>
      return -1;
    800056be:	597d                	li	s2,-1
    800056c0:	b755                	j	80005664 <fileread+0x60>
    800056c2:	597d                	li	s2,-1
    800056c4:	b745                	j	80005664 <fileread+0x60>

00000000800056c6 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800056c6:	715d                	addi	sp,sp,-80
    800056c8:	e486                	sd	ra,72(sp)
    800056ca:	e0a2                	sd	s0,64(sp)
    800056cc:	fc26                	sd	s1,56(sp)
    800056ce:	f84a                	sd	s2,48(sp)
    800056d0:	f44e                	sd	s3,40(sp)
    800056d2:	f052                	sd	s4,32(sp)
    800056d4:	ec56                	sd	s5,24(sp)
    800056d6:	e85a                	sd	s6,16(sp)
    800056d8:	e45e                	sd	s7,8(sp)
    800056da:	e062                	sd	s8,0(sp)
    800056dc:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800056de:	00954783          	lbu	a5,9(a0)
    800056e2:	10078663          	beqz	a5,800057ee <filewrite+0x128>
    800056e6:	892a                	mv	s2,a0
    800056e8:	8b2e                	mv	s6,a1
    800056ea:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800056ec:	411c                	lw	a5,0(a0)
    800056ee:	4705                	li	a4,1
    800056f0:	02e78263          	beq	a5,a4,80005714 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800056f4:	470d                	li	a4,3
    800056f6:	02e78663          	beq	a5,a4,80005722 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800056fa:	4709                	li	a4,2
    800056fc:	0ee79163          	bne	a5,a4,800057de <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80005700:	0ac05d63          	blez	a2,800057ba <filewrite+0xf4>
    int i = 0;
    80005704:	4981                	li	s3,0
    80005706:	6b85                	lui	s7,0x1
    80005708:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    8000570c:	6c05                	lui	s8,0x1
    8000570e:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    80005712:	a861                	j	800057aa <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005714:	6908                	ld	a0,16(a0)
    80005716:	00000097          	auipc	ra,0x0
    8000571a:	22e080e7          	jalr	558(ra) # 80005944 <pipewrite>
    8000571e:	8a2a                	mv	s4,a0
    80005720:	a045                	j	800057c0 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005722:	02451783          	lh	a5,36(a0)
    80005726:	03079693          	slli	a3,a5,0x30
    8000572a:	92c1                	srli	a3,a3,0x30
    8000572c:	4725                	li	a4,9
    8000572e:	0cd76263          	bltu	a4,a3,800057f2 <filewrite+0x12c>
    80005732:	0792                	slli	a5,a5,0x4
    80005734:	0001e717          	auipc	a4,0x1e
    80005738:	cf470713          	addi	a4,a4,-780 # 80023428 <devsw>
    8000573c:	97ba                	add	a5,a5,a4
    8000573e:	679c                	ld	a5,8(a5)
    80005740:	cbdd                	beqz	a5,800057f6 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005742:	4505                	li	a0,1
    80005744:	9782                	jalr	a5
    80005746:	8a2a                	mv	s4,a0
    80005748:	a8a5                	j	800057c0 <filewrite+0xfa>
    8000574a:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    8000574e:	00000097          	auipc	ra,0x0
    80005752:	8b4080e7          	jalr	-1868(ra) # 80005002 <begin_op>
      ilock(f->ip);
    80005756:	01893503          	ld	a0,24(s2)
    8000575a:	fffff097          	auipc	ra,0xfffff
    8000575e:	edc080e7          	jalr	-292(ra) # 80004636 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005762:	8756                	mv	a4,s5
    80005764:	02092683          	lw	a3,32(s2)
    80005768:	01698633          	add	a2,s3,s6
    8000576c:	4585                	li	a1,1
    8000576e:	01893503          	ld	a0,24(s2)
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	270080e7          	jalr	624(ra) # 800049e2 <writei>
    8000577a:	84aa                	mv	s1,a0
    8000577c:	00a05763          	blez	a0,8000578a <filewrite+0xc4>
        f->off += r;
    80005780:	02092783          	lw	a5,32(s2)
    80005784:	9fa9                	addw	a5,a5,a0
    80005786:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000578a:	01893503          	ld	a0,24(s2)
    8000578e:	fffff097          	auipc	ra,0xfffff
    80005792:	f6a080e7          	jalr	-150(ra) # 800046f8 <iunlock>
      end_op();
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	8ea080e7          	jalr	-1814(ra) # 80005080 <end_op>

      if(r != n1){
    8000579e:	009a9f63          	bne	s5,s1,800057bc <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800057a2:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800057a6:	0149db63          	bge	s3,s4,800057bc <filewrite+0xf6>
      int n1 = n - i;
    800057aa:	413a04bb          	subw	s1,s4,s3
    800057ae:	0004879b          	sext.w	a5,s1
    800057b2:	f8fbdce3          	bge	s7,a5,8000574a <filewrite+0x84>
    800057b6:	84e2                	mv	s1,s8
    800057b8:	bf49                	j	8000574a <filewrite+0x84>
    int i = 0;
    800057ba:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800057bc:	013a1f63          	bne	s4,s3,800057da <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800057c0:	8552                	mv	a0,s4
    800057c2:	60a6                	ld	ra,72(sp)
    800057c4:	6406                	ld	s0,64(sp)
    800057c6:	74e2                	ld	s1,56(sp)
    800057c8:	7942                	ld	s2,48(sp)
    800057ca:	79a2                	ld	s3,40(sp)
    800057cc:	7a02                	ld	s4,32(sp)
    800057ce:	6ae2                	ld	s5,24(sp)
    800057d0:	6b42                	ld	s6,16(sp)
    800057d2:	6ba2                	ld	s7,8(sp)
    800057d4:	6c02                	ld	s8,0(sp)
    800057d6:	6161                	addi	sp,sp,80
    800057d8:	8082                	ret
    ret = (i == n ? n : -1);
    800057da:	5a7d                	li	s4,-1
    800057dc:	b7d5                	j	800057c0 <filewrite+0xfa>
    panic("filewrite");
    800057de:	00004517          	auipc	a0,0x4
    800057e2:	f2250513          	addi	a0,a0,-222 # 80009700 <syscalls+0x288>
    800057e6:	ffffb097          	auipc	ra,0xffffb
    800057ea:	d5a080e7          	jalr	-678(ra) # 80000540 <panic>
    return -1;
    800057ee:	5a7d                	li	s4,-1
    800057f0:	bfc1                	j	800057c0 <filewrite+0xfa>
      return -1;
    800057f2:	5a7d                	li	s4,-1
    800057f4:	b7f1                	j	800057c0 <filewrite+0xfa>
    800057f6:	5a7d                	li	s4,-1
    800057f8:	b7e1                	j	800057c0 <filewrite+0xfa>

00000000800057fa <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800057fa:	7179                	addi	sp,sp,-48
    800057fc:	f406                	sd	ra,40(sp)
    800057fe:	f022                	sd	s0,32(sp)
    80005800:	ec26                	sd	s1,24(sp)
    80005802:	e84a                	sd	s2,16(sp)
    80005804:	e44e                	sd	s3,8(sp)
    80005806:	e052                	sd	s4,0(sp)
    80005808:	1800                	addi	s0,sp,48
    8000580a:	84aa                	mv	s1,a0
    8000580c:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    8000580e:	0005b023          	sd	zero,0(a1)
    80005812:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80005816:	00000097          	auipc	ra,0x0
    8000581a:	bf8080e7          	jalr	-1032(ra) # 8000540e <filealloc>
    8000581e:	e088                	sd	a0,0(s1)
    80005820:	c551                	beqz	a0,800058ac <pipealloc+0xb2>
    80005822:	00000097          	auipc	ra,0x0
    80005826:	bec080e7          	jalr	-1044(ra) # 8000540e <filealloc>
    8000582a:	00aa3023          	sd	a0,0(s4)
    8000582e:	c92d                	beqz	a0,800058a0 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005830:	ffffb097          	auipc	ra,0xffffb
    80005834:	2b6080e7          	jalr	694(ra) # 80000ae6 <kalloc>
    80005838:	892a                	mv	s2,a0
    8000583a:	c125                	beqz	a0,8000589a <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    8000583c:	4985                	li	s3,1
    8000583e:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005842:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80005846:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000584a:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    8000584e:	00004597          	auipc	a1,0x4
    80005852:	ec258593          	addi	a1,a1,-318 # 80009710 <syscalls+0x298>
    80005856:	ffffb097          	auipc	ra,0xffffb
    8000585a:	2f0080e7          	jalr	752(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    8000585e:	609c                	ld	a5,0(s1)
    80005860:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005864:	609c                	ld	a5,0(s1)
    80005866:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000586a:	609c                	ld	a5,0(s1)
    8000586c:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005870:	609c                	ld	a5,0(s1)
    80005872:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80005876:	000a3783          	ld	a5,0(s4)
    8000587a:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    8000587e:	000a3783          	ld	a5,0(s4)
    80005882:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80005886:	000a3783          	ld	a5,0(s4)
    8000588a:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    8000588e:	000a3783          	ld	a5,0(s4)
    80005892:	0127b823          	sd	s2,16(a5)
  return 0;
    80005896:	4501                	li	a0,0
    80005898:	a025                	j	800058c0 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000589a:	6088                	ld	a0,0(s1)
    8000589c:	e501                	bnez	a0,800058a4 <pipealloc+0xaa>
    8000589e:	a039                	j	800058ac <pipealloc+0xb2>
    800058a0:	6088                	ld	a0,0(s1)
    800058a2:	c51d                	beqz	a0,800058d0 <pipealloc+0xd6>
    fileclose(*f0);
    800058a4:	00000097          	auipc	ra,0x0
    800058a8:	c26080e7          	jalr	-986(ra) # 800054ca <fileclose>
  if(*f1)
    800058ac:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800058b0:	557d                	li	a0,-1
  if(*f1)
    800058b2:	c799                	beqz	a5,800058c0 <pipealloc+0xc6>
    fileclose(*f1);
    800058b4:	853e                	mv	a0,a5
    800058b6:	00000097          	auipc	ra,0x0
    800058ba:	c14080e7          	jalr	-1004(ra) # 800054ca <fileclose>
  return -1;
    800058be:	557d                	li	a0,-1
}
    800058c0:	70a2                	ld	ra,40(sp)
    800058c2:	7402                	ld	s0,32(sp)
    800058c4:	64e2                	ld	s1,24(sp)
    800058c6:	6942                	ld	s2,16(sp)
    800058c8:	69a2                	ld	s3,8(sp)
    800058ca:	6a02                	ld	s4,0(sp)
    800058cc:	6145                	addi	sp,sp,48
    800058ce:	8082                	ret
  return -1;
    800058d0:	557d                	li	a0,-1
    800058d2:	b7fd                	j	800058c0 <pipealloc+0xc6>

00000000800058d4 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800058d4:	1101                	addi	sp,sp,-32
    800058d6:	ec06                	sd	ra,24(sp)
    800058d8:	e822                	sd	s0,16(sp)
    800058da:	e426                	sd	s1,8(sp)
    800058dc:	e04a                	sd	s2,0(sp)
    800058de:	1000                	addi	s0,sp,32
    800058e0:	84aa                	mv	s1,a0
    800058e2:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800058e4:	ffffb097          	auipc	ra,0xffffb
    800058e8:	2f2080e7          	jalr	754(ra) # 80000bd6 <acquire>
  if(writable){
    800058ec:	02090d63          	beqz	s2,80005926 <pipeclose+0x52>
    pi->writeopen = 0;
    800058f0:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800058f4:	21848513          	addi	a0,s1,536
    800058f8:	ffffd097          	auipc	ra,0xffffd
    800058fc:	3e2080e7          	jalr	994(ra) # 80002cda <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80005900:	2204b783          	ld	a5,544(s1)
    80005904:	eb95                	bnez	a5,80005938 <pipeclose+0x64>
    release(&pi->lock);
    80005906:	8526                	mv	a0,s1
    80005908:	ffffb097          	auipc	ra,0xffffb
    8000590c:	382080e7          	jalr	898(ra) # 80000c8a <release>
    kfree((char*)pi);
    80005910:	8526                	mv	a0,s1
    80005912:	ffffb097          	auipc	ra,0xffffb
    80005916:	0d6080e7          	jalr	214(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    8000591a:	60e2                	ld	ra,24(sp)
    8000591c:	6442                	ld	s0,16(sp)
    8000591e:	64a2                	ld	s1,8(sp)
    80005920:	6902                	ld	s2,0(sp)
    80005922:	6105                	addi	sp,sp,32
    80005924:	8082                	ret
    pi->readopen = 0;
    80005926:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000592a:	21c48513          	addi	a0,s1,540
    8000592e:	ffffd097          	auipc	ra,0xffffd
    80005932:	3ac080e7          	jalr	940(ra) # 80002cda <wakeup>
    80005936:	b7e9                	j	80005900 <pipeclose+0x2c>
    release(&pi->lock);
    80005938:	8526                	mv	a0,s1
    8000593a:	ffffb097          	auipc	ra,0xffffb
    8000593e:	350080e7          	jalr	848(ra) # 80000c8a <release>
}
    80005942:	bfe1                	j	8000591a <pipeclose+0x46>

0000000080005944 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005944:	711d                	addi	sp,sp,-96
    80005946:	ec86                	sd	ra,88(sp)
    80005948:	e8a2                	sd	s0,80(sp)
    8000594a:	e4a6                	sd	s1,72(sp)
    8000594c:	e0ca                	sd	s2,64(sp)
    8000594e:	fc4e                	sd	s3,56(sp)
    80005950:	f852                	sd	s4,48(sp)
    80005952:	f456                	sd	s5,40(sp)
    80005954:	f05a                	sd	s6,32(sp)
    80005956:	ec5e                	sd	s7,24(sp)
    80005958:	e862                	sd	s8,16(sp)
    8000595a:	1080                	addi	s0,sp,96
    8000595c:	84aa                	mv	s1,a0
    8000595e:	8aae                	mv	s5,a1
    80005960:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005962:	ffffc097          	auipc	ra,0xffffc
    80005966:	04a080e7          	jalr	74(ra) # 800019ac <myproc>
    8000596a:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    8000596c:	8526                	mv	a0,s1
    8000596e:	ffffb097          	auipc	ra,0xffffb
    80005972:	268080e7          	jalr	616(ra) # 80000bd6 <acquire>
  while(i < n){
    80005976:	0b405663          	blez	s4,80005a22 <pipewrite+0xde>
  int i = 0;
    8000597a:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    8000597c:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    8000597e:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80005982:	21c48b93          	addi	s7,s1,540
    80005986:	a089                	j	800059c8 <pipewrite+0x84>
      release(&pi->lock);
    80005988:	8526                	mv	a0,s1
    8000598a:	ffffb097          	auipc	ra,0xffffb
    8000598e:	300080e7          	jalr	768(ra) # 80000c8a <release>
      return -1;
    80005992:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80005994:	854a                	mv	a0,s2
    80005996:	60e6                	ld	ra,88(sp)
    80005998:	6446                	ld	s0,80(sp)
    8000599a:	64a6                	ld	s1,72(sp)
    8000599c:	6906                	ld	s2,64(sp)
    8000599e:	79e2                	ld	s3,56(sp)
    800059a0:	7a42                	ld	s4,48(sp)
    800059a2:	7aa2                	ld	s5,40(sp)
    800059a4:	7b02                	ld	s6,32(sp)
    800059a6:	6be2                	ld	s7,24(sp)
    800059a8:	6c42                	ld	s8,16(sp)
    800059aa:	6125                	addi	sp,sp,96
    800059ac:	8082                	ret
      wakeup(&pi->nread);
    800059ae:	8562                	mv	a0,s8
    800059b0:	ffffd097          	auipc	ra,0xffffd
    800059b4:	32a080e7          	jalr	810(ra) # 80002cda <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800059b8:	85a6                	mv	a1,s1
    800059ba:	855e                	mv	a0,s7
    800059bc:	ffffd097          	auipc	ra,0xffffd
    800059c0:	2ba080e7          	jalr	698(ra) # 80002c76 <sleep>
  while(i < n){
    800059c4:	07495063          	bge	s2,s4,80005a24 <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    800059c8:	2204a783          	lw	a5,544(s1)
    800059cc:	dfd5                	beqz	a5,80005988 <pipewrite+0x44>
    800059ce:	854e                	mv	a0,s3
    800059d0:	ffffd097          	auipc	ra,0xffffd
    800059d4:	55a080e7          	jalr	1370(ra) # 80002f2a <killed>
    800059d8:	f945                	bnez	a0,80005988 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800059da:	2184a783          	lw	a5,536(s1)
    800059de:	21c4a703          	lw	a4,540(s1)
    800059e2:	2007879b          	addiw	a5,a5,512
    800059e6:	fcf704e3          	beq	a4,a5,800059ae <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    800059ea:	4685                	li	a3,1
    800059ec:	01590633          	add	a2,s2,s5
    800059f0:	faf40593          	addi	a1,s0,-81
    800059f4:	0509b503          	ld	a0,80(s3)
    800059f8:	ffffc097          	auipc	ra,0xffffc
    800059fc:	d00080e7          	jalr	-768(ra) # 800016f8 <copyin>
    80005a00:	03650263          	beq	a0,s6,80005a24 <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80005a04:	21c4a783          	lw	a5,540(s1)
    80005a08:	0017871b          	addiw	a4,a5,1
    80005a0c:	20e4ae23          	sw	a4,540(s1)
    80005a10:	1ff7f793          	andi	a5,a5,511
    80005a14:	97a6                	add	a5,a5,s1
    80005a16:	faf44703          	lbu	a4,-81(s0)
    80005a1a:	00e78c23          	sb	a4,24(a5)
      i++;
    80005a1e:	2905                	addiw	s2,s2,1
    80005a20:	b755                	j	800059c4 <pipewrite+0x80>
  int i = 0;
    80005a22:	4901                	li	s2,0
  wakeup(&pi->nread);
    80005a24:	21848513          	addi	a0,s1,536
    80005a28:	ffffd097          	auipc	ra,0xffffd
    80005a2c:	2b2080e7          	jalr	690(ra) # 80002cda <wakeup>
  release(&pi->lock);
    80005a30:	8526                	mv	a0,s1
    80005a32:	ffffb097          	auipc	ra,0xffffb
    80005a36:	258080e7          	jalr	600(ra) # 80000c8a <release>
  return i;
    80005a3a:	bfa9                	j	80005994 <pipewrite+0x50>

0000000080005a3c <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005a3c:	715d                	addi	sp,sp,-80
    80005a3e:	e486                	sd	ra,72(sp)
    80005a40:	e0a2                	sd	s0,64(sp)
    80005a42:	fc26                	sd	s1,56(sp)
    80005a44:	f84a                	sd	s2,48(sp)
    80005a46:	f44e                	sd	s3,40(sp)
    80005a48:	f052                	sd	s4,32(sp)
    80005a4a:	ec56                	sd	s5,24(sp)
    80005a4c:	e85a                	sd	s6,16(sp)
    80005a4e:	0880                	addi	s0,sp,80
    80005a50:	84aa                	mv	s1,a0
    80005a52:	892e                	mv	s2,a1
    80005a54:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005a56:	ffffc097          	auipc	ra,0xffffc
    80005a5a:	f56080e7          	jalr	-170(ra) # 800019ac <myproc>
    80005a5e:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80005a60:	8526                	mv	a0,s1
    80005a62:	ffffb097          	auipc	ra,0xffffb
    80005a66:	174080e7          	jalr	372(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005a6a:	2184a703          	lw	a4,536(s1)
    80005a6e:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005a72:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005a76:	02f71763          	bne	a4,a5,80005aa4 <piperead+0x68>
    80005a7a:	2244a783          	lw	a5,548(s1)
    80005a7e:	c39d                	beqz	a5,80005aa4 <piperead+0x68>
    if(killed(pr)){
    80005a80:	8552                	mv	a0,s4
    80005a82:	ffffd097          	auipc	ra,0xffffd
    80005a86:	4a8080e7          	jalr	1192(ra) # 80002f2a <killed>
    80005a8a:	e949                	bnez	a0,80005b1c <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005a8c:	85a6                	mv	a1,s1
    80005a8e:	854e                	mv	a0,s3
    80005a90:	ffffd097          	auipc	ra,0xffffd
    80005a94:	1e6080e7          	jalr	486(ra) # 80002c76 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005a98:	2184a703          	lw	a4,536(s1)
    80005a9c:	21c4a783          	lw	a5,540(s1)
    80005aa0:	fcf70de3          	beq	a4,a5,80005a7a <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005aa4:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005aa6:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005aa8:	05505463          	blez	s5,80005af0 <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80005aac:	2184a783          	lw	a5,536(s1)
    80005ab0:	21c4a703          	lw	a4,540(s1)
    80005ab4:	02f70e63          	beq	a4,a5,80005af0 <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80005ab8:	0017871b          	addiw	a4,a5,1
    80005abc:	20e4ac23          	sw	a4,536(s1)
    80005ac0:	1ff7f793          	andi	a5,a5,511
    80005ac4:	97a6                	add	a5,a5,s1
    80005ac6:	0187c783          	lbu	a5,24(a5)
    80005aca:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005ace:	4685                	li	a3,1
    80005ad0:	fbf40613          	addi	a2,s0,-65
    80005ad4:	85ca                	mv	a1,s2
    80005ad6:	050a3503          	ld	a0,80(s4)
    80005ada:	ffffc097          	auipc	ra,0xffffc
    80005ade:	b92080e7          	jalr	-1134(ra) # 8000166c <copyout>
    80005ae2:	01650763          	beq	a0,s6,80005af0 <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005ae6:	2985                	addiw	s3,s3,1
    80005ae8:	0905                	addi	s2,s2,1
    80005aea:	fd3a91e3          	bne	s5,s3,80005aac <piperead+0x70>
    80005aee:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005af0:	21c48513          	addi	a0,s1,540
    80005af4:	ffffd097          	auipc	ra,0xffffd
    80005af8:	1e6080e7          	jalr	486(ra) # 80002cda <wakeup>
  release(&pi->lock);
    80005afc:	8526                	mv	a0,s1
    80005afe:	ffffb097          	auipc	ra,0xffffb
    80005b02:	18c080e7          	jalr	396(ra) # 80000c8a <release>
  return i;
}
    80005b06:	854e                	mv	a0,s3
    80005b08:	60a6                	ld	ra,72(sp)
    80005b0a:	6406                	ld	s0,64(sp)
    80005b0c:	74e2                	ld	s1,56(sp)
    80005b0e:	7942                	ld	s2,48(sp)
    80005b10:	79a2                	ld	s3,40(sp)
    80005b12:	7a02                	ld	s4,32(sp)
    80005b14:	6ae2                	ld	s5,24(sp)
    80005b16:	6b42                	ld	s6,16(sp)
    80005b18:	6161                	addi	sp,sp,80
    80005b1a:	8082                	ret
      release(&pi->lock);
    80005b1c:	8526                	mv	a0,s1
    80005b1e:	ffffb097          	auipc	ra,0xffffb
    80005b22:	16c080e7          	jalr	364(ra) # 80000c8a <release>
      return -1;
    80005b26:	59fd                	li	s3,-1
    80005b28:	bff9                	j	80005b06 <piperead+0xca>

0000000080005b2a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80005b2a:	1141                	addi	sp,sp,-16
    80005b2c:	e422                	sd	s0,8(sp)
    80005b2e:	0800                	addi	s0,sp,16
    80005b30:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005b32:	8905                	andi	a0,a0,1
    80005b34:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80005b36:	8b89                	andi	a5,a5,2
    80005b38:	c399                	beqz	a5,80005b3e <flags2perm+0x14>
      perm |= PTE_W;
    80005b3a:	00456513          	ori	a0,a0,4
    return perm;
}
    80005b3e:	6422                	ld	s0,8(sp)
    80005b40:	0141                	addi	sp,sp,16
    80005b42:	8082                	ret

0000000080005b44 <exec>:

int
exec(char *path, char **argv)
{
    80005b44:	de010113          	addi	sp,sp,-544
    80005b48:	20113c23          	sd	ra,536(sp)
    80005b4c:	20813823          	sd	s0,528(sp)
    80005b50:	20913423          	sd	s1,520(sp)
    80005b54:	21213023          	sd	s2,512(sp)
    80005b58:	ffce                	sd	s3,504(sp)
    80005b5a:	fbd2                	sd	s4,496(sp)
    80005b5c:	f7d6                	sd	s5,488(sp)
    80005b5e:	f3da                	sd	s6,480(sp)
    80005b60:	efde                	sd	s7,472(sp)
    80005b62:	ebe2                	sd	s8,464(sp)
    80005b64:	e7e6                	sd	s9,456(sp)
    80005b66:	e3ea                	sd	s10,448(sp)
    80005b68:	ff6e                	sd	s11,440(sp)
    80005b6a:	1400                	addi	s0,sp,544
    80005b6c:	892a                	mv	s2,a0
    80005b6e:	dea43423          	sd	a0,-536(s0)
    80005b72:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005b76:	ffffc097          	auipc	ra,0xffffc
    80005b7a:	e36080e7          	jalr	-458(ra) # 800019ac <myproc>
    80005b7e:	84aa                	mv	s1,a0

  begin_op();
    80005b80:	fffff097          	auipc	ra,0xfffff
    80005b84:	482080e7          	jalr	1154(ra) # 80005002 <begin_op>

  if((ip = namei(path)) == 0){
    80005b88:	854a                	mv	a0,s2
    80005b8a:	fffff097          	auipc	ra,0xfffff
    80005b8e:	258080e7          	jalr	600(ra) # 80004de2 <namei>
    80005b92:	c93d                	beqz	a0,80005c08 <exec+0xc4>
    80005b94:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005b96:	fffff097          	auipc	ra,0xfffff
    80005b9a:	aa0080e7          	jalr	-1376(ra) # 80004636 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80005b9e:	04000713          	li	a4,64
    80005ba2:	4681                	li	a3,0
    80005ba4:	e5040613          	addi	a2,s0,-432
    80005ba8:	4581                	li	a1,0
    80005baa:	8556                	mv	a0,s5
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	d3e080e7          	jalr	-706(ra) # 800048ea <readi>
    80005bb4:	04000793          	li	a5,64
    80005bb8:	00f51a63          	bne	a0,a5,80005bcc <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80005bbc:	e5042703          	lw	a4,-432(s0)
    80005bc0:	464c47b7          	lui	a5,0x464c4
    80005bc4:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005bc8:	04f70663          	beq	a4,a5,80005c14 <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005bcc:	8556                	mv	a0,s5
    80005bce:	fffff097          	auipc	ra,0xfffff
    80005bd2:	cca080e7          	jalr	-822(ra) # 80004898 <iunlockput>
    end_op();
    80005bd6:	fffff097          	auipc	ra,0xfffff
    80005bda:	4aa080e7          	jalr	1194(ra) # 80005080 <end_op>
  }
  return -1;
    80005bde:	557d                	li	a0,-1
}
    80005be0:	21813083          	ld	ra,536(sp)
    80005be4:	21013403          	ld	s0,528(sp)
    80005be8:	20813483          	ld	s1,520(sp)
    80005bec:	20013903          	ld	s2,512(sp)
    80005bf0:	79fe                	ld	s3,504(sp)
    80005bf2:	7a5e                	ld	s4,496(sp)
    80005bf4:	7abe                	ld	s5,488(sp)
    80005bf6:	7b1e                	ld	s6,480(sp)
    80005bf8:	6bfe                	ld	s7,472(sp)
    80005bfa:	6c5e                	ld	s8,464(sp)
    80005bfc:	6cbe                	ld	s9,456(sp)
    80005bfe:	6d1e                	ld	s10,448(sp)
    80005c00:	7dfa                	ld	s11,440(sp)
    80005c02:	22010113          	addi	sp,sp,544
    80005c06:	8082                	ret
    end_op();
    80005c08:	fffff097          	auipc	ra,0xfffff
    80005c0c:	478080e7          	jalr	1144(ra) # 80005080 <end_op>
    return -1;
    80005c10:	557d                	li	a0,-1
    80005c12:	b7f9                	j	80005be0 <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80005c14:	8526                	mv	a0,s1
    80005c16:	ffffc097          	auipc	ra,0xffffc
    80005c1a:	e5a080e7          	jalr	-422(ra) # 80001a70 <proc_pagetable>
    80005c1e:	8b2a                	mv	s6,a0
    80005c20:	d555                	beqz	a0,80005bcc <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005c22:	e7042783          	lw	a5,-400(s0)
    80005c26:	e8845703          	lhu	a4,-376(s0)
    80005c2a:	c735                	beqz	a4,80005c96 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005c2c:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005c2e:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80005c32:	6a05                	lui	s4,0x1
    80005c34:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80005c38:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80005c3c:	6d85                	lui	s11,0x1
    80005c3e:	7d7d                	lui	s10,0xfffff
    80005c40:	ac3d                	j	80005e7e <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005c42:	00004517          	auipc	a0,0x4
    80005c46:	ad650513          	addi	a0,a0,-1322 # 80009718 <syscalls+0x2a0>
    80005c4a:	ffffb097          	auipc	ra,0xffffb
    80005c4e:	8f6080e7          	jalr	-1802(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005c52:	874a                	mv	a4,s2
    80005c54:	009c86bb          	addw	a3,s9,s1
    80005c58:	4581                	li	a1,0
    80005c5a:	8556                	mv	a0,s5
    80005c5c:	fffff097          	auipc	ra,0xfffff
    80005c60:	c8e080e7          	jalr	-882(ra) # 800048ea <readi>
    80005c64:	2501                	sext.w	a0,a0
    80005c66:	1aa91963          	bne	s2,a0,80005e18 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80005c6a:	009d84bb          	addw	s1,s11,s1
    80005c6e:	013d09bb          	addw	s3,s10,s3
    80005c72:	1f74f663          	bgeu	s1,s7,80005e5e <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80005c76:	02049593          	slli	a1,s1,0x20
    80005c7a:	9181                	srli	a1,a1,0x20
    80005c7c:	95e2                	add	a1,a1,s8
    80005c7e:	855a                	mv	a0,s6
    80005c80:	ffffb097          	auipc	ra,0xffffb
    80005c84:	3dc080e7          	jalr	988(ra) # 8000105c <walkaddr>
    80005c88:	862a                	mv	a2,a0
    if(pa == 0)
    80005c8a:	dd45                	beqz	a0,80005c42 <exec+0xfe>
      n = PGSIZE;
    80005c8c:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80005c8e:	fd49f2e3          	bgeu	s3,s4,80005c52 <exec+0x10e>
      n = sz - i;
    80005c92:	894e                	mv	s2,s3
    80005c94:	bf7d                	j	80005c52 <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005c96:	4901                	li	s2,0
  iunlockput(ip);
    80005c98:	8556                	mv	a0,s5
    80005c9a:	fffff097          	auipc	ra,0xfffff
    80005c9e:	bfe080e7          	jalr	-1026(ra) # 80004898 <iunlockput>
  end_op();
    80005ca2:	fffff097          	auipc	ra,0xfffff
    80005ca6:	3de080e7          	jalr	990(ra) # 80005080 <end_op>
  p = myproc();
    80005caa:	ffffc097          	auipc	ra,0xffffc
    80005cae:	d02080e7          	jalr	-766(ra) # 800019ac <myproc>
    80005cb2:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80005cb4:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80005cb8:	6785                	lui	a5,0x1
    80005cba:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80005cbc:	97ca                	add	a5,a5,s2
    80005cbe:	777d                	lui	a4,0xfffff
    80005cc0:	8ff9                	and	a5,a5,a4
    80005cc2:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005cc6:	4691                	li	a3,4
    80005cc8:	6609                	lui	a2,0x2
    80005cca:	963e                	add	a2,a2,a5
    80005ccc:	85be                	mv	a1,a5
    80005cce:	855a                	mv	a0,s6
    80005cd0:	ffffb097          	auipc	ra,0xffffb
    80005cd4:	740080e7          	jalr	1856(ra) # 80001410 <uvmalloc>
    80005cd8:	8c2a                	mv	s8,a0
  ip = 0;
    80005cda:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80005cdc:	12050e63          	beqz	a0,80005e18 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005ce0:	75f9                	lui	a1,0xffffe
    80005ce2:	95aa                	add	a1,a1,a0
    80005ce4:	855a                	mv	a0,s6
    80005ce6:	ffffc097          	auipc	ra,0xffffc
    80005cea:	954080e7          	jalr	-1708(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80005cee:	7afd                	lui	s5,0xfffff
    80005cf0:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80005cf2:	df043783          	ld	a5,-528(s0)
    80005cf6:	6388                	ld	a0,0(a5)
    80005cf8:	c925                	beqz	a0,80005d68 <exec+0x224>
    80005cfa:	e9040993          	addi	s3,s0,-368
    80005cfe:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005d02:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005d04:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80005d06:	ffffb097          	auipc	ra,0xffffb
    80005d0a:	148080e7          	jalr	328(ra) # 80000e4e <strlen>
    80005d0e:	0015079b          	addiw	a5,a0,1
    80005d12:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005d16:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80005d1a:	13596663          	bltu	s2,s5,80005e46 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005d1e:	df043d83          	ld	s11,-528(s0)
    80005d22:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80005d26:	8552                	mv	a0,s4
    80005d28:	ffffb097          	auipc	ra,0xffffb
    80005d2c:	126080e7          	jalr	294(ra) # 80000e4e <strlen>
    80005d30:	0015069b          	addiw	a3,a0,1
    80005d34:	8652                	mv	a2,s4
    80005d36:	85ca                	mv	a1,s2
    80005d38:	855a                	mv	a0,s6
    80005d3a:	ffffc097          	auipc	ra,0xffffc
    80005d3e:	932080e7          	jalr	-1742(ra) # 8000166c <copyout>
    80005d42:	10054663          	bltz	a0,80005e4e <exec+0x30a>
    ustack[argc] = sp;
    80005d46:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005d4a:	0485                	addi	s1,s1,1
    80005d4c:	008d8793          	addi	a5,s11,8
    80005d50:	def43823          	sd	a5,-528(s0)
    80005d54:	008db503          	ld	a0,8(s11)
    80005d58:	c911                	beqz	a0,80005d6c <exec+0x228>
    if(argc >= MAXARG)
    80005d5a:	09a1                	addi	s3,s3,8
    80005d5c:	fb3c95e3          	bne	s9,s3,80005d06 <exec+0x1c2>
  sz = sz1;
    80005d60:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005d64:	4a81                	li	s5,0
    80005d66:	a84d                	j	80005e18 <exec+0x2d4>
  sp = sz;
    80005d68:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005d6a:	4481                	li	s1,0
  ustack[argc] = 0;
    80005d6c:	00349793          	slli	a5,s1,0x3
    80005d70:	f9078793          	addi	a5,a5,-112
    80005d74:	97a2                	add	a5,a5,s0
    80005d76:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005d7a:	00148693          	addi	a3,s1,1
    80005d7e:	068e                	slli	a3,a3,0x3
    80005d80:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005d84:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005d88:	01597663          	bgeu	s2,s5,80005d94 <exec+0x250>
  sz = sz1;
    80005d8c:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005d90:	4a81                	li	s5,0
    80005d92:	a059                	j	80005e18 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005d94:	e9040613          	addi	a2,s0,-368
    80005d98:	85ca                	mv	a1,s2
    80005d9a:	855a                	mv	a0,s6
    80005d9c:	ffffc097          	auipc	ra,0xffffc
    80005da0:	8d0080e7          	jalr	-1840(ra) # 8000166c <copyout>
    80005da4:	0a054963          	bltz	a0,80005e56 <exec+0x312>
  p->trapframe->a1 = sp;
    80005da8:	058bb783          	ld	a5,88(s7)
    80005dac:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005db0:	de843783          	ld	a5,-536(s0)
    80005db4:	0007c703          	lbu	a4,0(a5)
    80005db8:	cf11                	beqz	a4,80005dd4 <exec+0x290>
    80005dba:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005dbc:	02f00693          	li	a3,47
    80005dc0:	a039                	j	80005dce <exec+0x28a>
      last = s+1;
    80005dc2:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005dc6:	0785                	addi	a5,a5,1
    80005dc8:	fff7c703          	lbu	a4,-1(a5)
    80005dcc:	c701                	beqz	a4,80005dd4 <exec+0x290>
    if(*s == '/')
    80005dce:	fed71ce3          	bne	a4,a3,80005dc6 <exec+0x282>
    80005dd2:	bfc5                	j	80005dc2 <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80005dd4:	4641                	li	a2,16
    80005dd6:	de843583          	ld	a1,-536(s0)
    80005dda:	158b8513          	addi	a0,s7,344
    80005dde:	ffffb097          	auipc	ra,0xffffb
    80005de2:	03e080e7          	jalr	62(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005de6:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80005dea:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80005dee:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005df2:	058bb783          	ld	a5,88(s7)
    80005df6:	e6843703          	ld	a4,-408(s0)
    80005dfa:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005dfc:	058bb783          	ld	a5,88(s7)
    80005e00:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005e04:	85ea                	mv	a1,s10
    80005e06:	ffffc097          	auipc	ra,0xffffc
    80005e0a:	d06080e7          	jalr	-762(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005e0e:	0004851b          	sext.w	a0,s1
    80005e12:	b3f9                	j	80005be0 <exec+0x9c>
    80005e14:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80005e18:	df843583          	ld	a1,-520(s0)
    80005e1c:	855a                	mv	a0,s6
    80005e1e:	ffffc097          	auipc	ra,0xffffc
    80005e22:	cee080e7          	jalr	-786(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    80005e26:	da0a93e3          	bnez	s5,80005bcc <exec+0x88>
  return -1;
    80005e2a:	557d                	li	a0,-1
    80005e2c:	bb55                	j	80005be0 <exec+0x9c>
    80005e2e:	df243c23          	sd	s2,-520(s0)
    80005e32:	b7dd                	j	80005e18 <exec+0x2d4>
    80005e34:	df243c23          	sd	s2,-520(s0)
    80005e38:	b7c5                	j	80005e18 <exec+0x2d4>
    80005e3a:	df243c23          	sd	s2,-520(s0)
    80005e3e:	bfe9                	j	80005e18 <exec+0x2d4>
    80005e40:	df243c23          	sd	s2,-520(s0)
    80005e44:	bfd1                	j	80005e18 <exec+0x2d4>
  sz = sz1;
    80005e46:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005e4a:	4a81                	li	s5,0
    80005e4c:	b7f1                	j	80005e18 <exec+0x2d4>
  sz = sz1;
    80005e4e:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005e52:	4a81                	li	s5,0
    80005e54:	b7d1                	j	80005e18 <exec+0x2d4>
  sz = sz1;
    80005e56:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80005e5a:	4a81                	li	s5,0
    80005e5c:	bf75                	j	80005e18 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005e5e:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005e62:	e0843783          	ld	a5,-504(s0)
    80005e66:	0017869b          	addiw	a3,a5,1
    80005e6a:	e0d43423          	sd	a3,-504(s0)
    80005e6e:	e0043783          	ld	a5,-512(s0)
    80005e72:	0387879b          	addiw	a5,a5,56
    80005e76:	e8845703          	lhu	a4,-376(s0)
    80005e7a:	e0e6dfe3          	bge	a3,a4,80005c98 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005e7e:	2781                	sext.w	a5,a5
    80005e80:	e0f43023          	sd	a5,-512(s0)
    80005e84:	03800713          	li	a4,56
    80005e88:	86be                	mv	a3,a5
    80005e8a:	e1840613          	addi	a2,s0,-488
    80005e8e:	4581                	li	a1,0
    80005e90:	8556                	mv	a0,s5
    80005e92:	fffff097          	auipc	ra,0xfffff
    80005e96:	a58080e7          	jalr	-1448(ra) # 800048ea <readi>
    80005e9a:	03800793          	li	a5,56
    80005e9e:	f6f51be3          	bne	a0,a5,80005e14 <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80005ea2:	e1842783          	lw	a5,-488(s0)
    80005ea6:	4705                	li	a4,1
    80005ea8:	fae79de3          	bne	a5,a4,80005e62 <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005eac:	e4043483          	ld	s1,-448(s0)
    80005eb0:	e3843783          	ld	a5,-456(s0)
    80005eb4:	f6f4ede3          	bltu	s1,a5,80005e2e <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005eb8:	e2843783          	ld	a5,-472(s0)
    80005ebc:	94be                	add	s1,s1,a5
    80005ebe:	f6f4ebe3          	bltu	s1,a5,80005e34 <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    80005ec2:	de043703          	ld	a4,-544(s0)
    80005ec6:	8ff9                	and	a5,a5,a4
    80005ec8:	fbad                	bnez	a5,80005e3a <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005eca:	e1c42503          	lw	a0,-484(s0)
    80005ece:	00000097          	auipc	ra,0x0
    80005ed2:	c5c080e7          	jalr	-932(ra) # 80005b2a <flags2perm>
    80005ed6:	86aa                	mv	a3,a0
    80005ed8:	8626                	mv	a2,s1
    80005eda:	85ca                	mv	a1,s2
    80005edc:	855a                	mv	a0,s6
    80005ede:	ffffb097          	auipc	ra,0xffffb
    80005ee2:	532080e7          	jalr	1330(ra) # 80001410 <uvmalloc>
    80005ee6:	dea43c23          	sd	a0,-520(s0)
    80005eea:	d939                	beqz	a0,80005e40 <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005eec:	e2843c03          	ld	s8,-472(s0)
    80005ef0:	e2042c83          	lw	s9,-480(s0)
    80005ef4:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005ef8:	f60b83e3          	beqz	s7,80005e5e <exec+0x31a>
    80005efc:	89de                	mv	s3,s7
    80005efe:	4481                	li	s1,0
    80005f00:	bb9d                	j	80005c76 <exec+0x132>

0000000080005f02 <argfd>:
int readcount = 0;
// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005f02:	7179                	addi	sp,sp,-48
    80005f04:	f406                	sd	ra,40(sp)
    80005f06:	f022                	sd	s0,32(sp)
    80005f08:	ec26                	sd	s1,24(sp)
    80005f0a:	e84a                	sd	s2,16(sp)
    80005f0c:	1800                	addi	s0,sp,48
    80005f0e:	892e                	mv	s2,a1
    80005f10:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005f12:	fdc40593          	addi	a1,s0,-36
    80005f16:	ffffe097          	auipc	ra,0xffffe
    80005f1a:	a3e080e7          	jalr	-1474(ra) # 80003954 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005f1e:	fdc42703          	lw	a4,-36(s0)
    80005f22:	47bd                	li	a5,15
    80005f24:	02e7eb63          	bltu	a5,a4,80005f5a <argfd+0x58>
    80005f28:	ffffc097          	auipc	ra,0xffffc
    80005f2c:	a84080e7          	jalr	-1404(ra) # 800019ac <myproc>
    80005f30:	fdc42703          	lw	a4,-36(s0)
    80005f34:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdaa5a>
    80005f38:	078e                	slli	a5,a5,0x3
    80005f3a:	953e                	add	a0,a0,a5
    80005f3c:	611c                	ld	a5,0(a0)
    80005f3e:	c385                	beqz	a5,80005f5e <argfd+0x5c>
    return -1;
  if(pfd)
    80005f40:	00090463          	beqz	s2,80005f48 <argfd+0x46>
    *pfd = fd;
    80005f44:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005f48:	4501                	li	a0,0
  if(pf)
    80005f4a:	c091                	beqz	s1,80005f4e <argfd+0x4c>
    *pf = f;
    80005f4c:	e09c                	sd	a5,0(s1)
}
    80005f4e:	70a2                	ld	ra,40(sp)
    80005f50:	7402                	ld	s0,32(sp)
    80005f52:	64e2                	ld	s1,24(sp)
    80005f54:	6942                	ld	s2,16(sp)
    80005f56:	6145                	addi	sp,sp,48
    80005f58:	8082                	ret
    return -1;
    80005f5a:	557d                	li	a0,-1
    80005f5c:	bfcd                	j	80005f4e <argfd+0x4c>
    80005f5e:	557d                	li	a0,-1
    80005f60:	b7fd                	j	80005f4e <argfd+0x4c>

0000000080005f62 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005f62:	1101                	addi	sp,sp,-32
    80005f64:	ec06                	sd	ra,24(sp)
    80005f66:	e822                	sd	s0,16(sp)
    80005f68:	e426                	sd	s1,8(sp)
    80005f6a:	1000                	addi	s0,sp,32
    80005f6c:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005f6e:	ffffc097          	auipc	ra,0xffffc
    80005f72:	a3e080e7          	jalr	-1474(ra) # 800019ac <myproc>
    80005f76:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005f78:	0d050793          	addi	a5,a0,208
    80005f7c:	4501                	li	a0,0
    80005f7e:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005f80:	6398                	ld	a4,0(a5)
    80005f82:	cb19                	beqz	a4,80005f98 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005f84:	2505                	addiw	a0,a0,1
    80005f86:	07a1                	addi	a5,a5,8
    80005f88:	fed51ce3          	bne	a0,a3,80005f80 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005f8c:	557d                	li	a0,-1
}
    80005f8e:	60e2                	ld	ra,24(sp)
    80005f90:	6442                	ld	s0,16(sp)
    80005f92:	64a2                	ld	s1,8(sp)
    80005f94:	6105                	addi	sp,sp,32
    80005f96:	8082                	ret
      p->ofile[fd] = f;
    80005f98:	01a50793          	addi	a5,a0,26
    80005f9c:	078e                	slli	a5,a5,0x3
    80005f9e:	963e                	add	a2,a2,a5
    80005fa0:	e204                	sd	s1,0(a2)
      return fd;
    80005fa2:	b7f5                	j	80005f8e <fdalloc+0x2c>

0000000080005fa4 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005fa4:	715d                	addi	sp,sp,-80
    80005fa6:	e486                	sd	ra,72(sp)
    80005fa8:	e0a2                	sd	s0,64(sp)
    80005faa:	fc26                	sd	s1,56(sp)
    80005fac:	f84a                	sd	s2,48(sp)
    80005fae:	f44e                	sd	s3,40(sp)
    80005fb0:	f052                	sd	s4,32(sp)
    80005fb2:	ec56                	sd	s5,24(sp)
    80005fb4:	e85a                	sd	s6,16(sp)
    80005fb6:	0880                	addi	s0,sp,80
    80005fb8:	8b2e                	mv	s6,a1
    80005fba:	89b2                	mv	s3,a2
    80005fbc:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005fbe:	fb040593          	addi	a1,s0,-80
    80005fc2:	fffff097          	auipc	ra,0xfffff
    80005fc6:	e3e080e7          	jalr	-450(ra) # 80004e00 <nameiparent>
    80005fca:	84aa                	mv	s1,a0
    80005fcc:	14050f63          	beqz	a0,8000612a <create+0x186>
    return 0;

  ilock(dp);
    80005fd0:	ffffe097          	auipc	ra,0xffffe
    80005fd4:	666080e7          	jalr	1638(ra) # 80004636 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005fd8:	4601                	li	a2,0
    80005fda:	fb040593          	addi	a1,s0,-80
    80005fde:	8526                	mv	a0,s1
    80005fe0:	fffff097          	auipc	ra,0xfffff
    80005fe4:	b3a080e7          	jalr	-1222(ra) # 80004b1a <dirlookup>
    80005fe8:	8aaa                	mv	s5,a0
    80005fea:	c931                	beqz	a0,8000603e <create+0x9a>
    iunlockput(dp);
    80005fec:	8526                	mv	a0,s1
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	8aa080e7          	jalr	-1878(ra) # 80004898 <iunlockput>
    ilock(ip);
    80005ff6:	8556                	mv	a0,s5
    80005ff8:	ffffe097          	auipc	ra,0xffffe
    80005ffc:	63e080e7          	jalr	1598(ra) # 80004636 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80006000:	000b059b          	sext.w	a1,s6
    80006004:	4789                	li	a5,2
    80006006:	02f59563          	bne	a1,a5,80006030 <create+0x8c>
    8000600a:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdaa84>
    8000600e:	37f9                	addiw	a5,a5,-2
    80006010:	17c2                	slli	a5,a5,0x30
    80006012:	93c1                	srli	a5,a5,0x30
    80006014:	4705                	li	a4,1
    80006016:	00f76d63          	bltu	a4,a5,80006030 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000601a:	8556                	mv	a0,s5
    8000601c:	60a6                	ld	ra,72(sp)
    8000601e:	6406                	ld	s0,64(sp)
    80006020:	74e2                	ld	s1,56(sp)
    80006022:	7942                	ld	s2,48(sp)
    80006024:	79a2                	ld	s3,40(sp)
    80006026:	7a02                	ld	s4,32(sp)
    80006028:	6ae2                	ld	s5,24(sp)
    8000602a:	6b42                	ld	s6,16(sp)
    8000602c:	6161                	addi	sp,sp,80
    8000602e:	8082                	ret
    iunlockput(ip);
    80006030:	8556                	mv	a0,s5
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	866080e7          	jalr	-1946(ra) # 80004898 <iunlockput>
    return 0;
    8000603a:	4a81                	li	s5,0
    8000603c:	bff9                	j	8000601a <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    8000603e:	85da                	mv	a1,s6
    80006040:	4088                	lw	a0,0(s1)
    80006042:	ffffe097          	auipc	ra,0xffffe
    80006046:	456080e7          	jalr	1110(ra) # 80004498 <ialloc>
    8000604a:	8a2a                	mv	s4,a0
    8000604c:	c539                	beqz	a0,8000609a <create+0xf6>
  ilock(ip);
    8000604e:	ffffe097          	auipc	ra,0xffffe
    80006052:	5e8080e7          	jalr	1512(ra) # 80004636 <ilock>
  ip->major = major;
    80006056:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    8000605a:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    8000605e:	4905                	li	s2,1
    80006060:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    80006064:	8552                	mv	a0,s4
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	504080e7          	jalr	1284(ra) # 8000456a <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000606e:	000b059b          	sext.w	a1,s6
    80006072:	03258b63          	beq	a1,s2,800060a8 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    80006076:	004a2603          	lw	a2,4(s4)
    8000607a:	fb040593          	addi	a1,s0,-80
    8000607e:	8526                	mv	a0,s1
    80006080:	fffff097          	auipc	ra,0xfffff
    80006084:	cb0080e7          	jalr	-848(ra) # 80004d30 <dirlink>
    80006088:	06054f63          	bltz	a0,80006106 <create+0x162>
  iunlockput(dp);
    8000608c:	8526                	mv	a0,s1
    8000608e:	fffff097          	auipc	ra,0xfffff
    80006092:	80a080e7          	jalr	-2038(ra) # 80004898 <iunlockput>
  return ip;
    80006096:	8ad2                	mv	s5,s4
    80006098:	b749                	j	8000601a <create+0x76>
    iunlockput(dp);
    8000609a:	8526                	mv	a0,s1
    8000609c:	ffffe097          	auipc	ra,0xffffe
    800060a0:	7fc080e7          	jalr	2044(ra) # 80004898 <iunlockput>
    return 0;
    800060a4:	8ad2                	mv	s5,s4
    800060a6:	bf95                	j	8000601a <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800060a8:	004a2603          	lw	a2,4(s4)
    800060ac:	00003597          	auipc	a1,0x3
    800060b0:	68c58593          	addi	a1,a1,1676 # 80009738 <syscalls+0x2c0>
    800060b4:	8552                	mv	a0,s4
    800060b6:	fffff097          	auipc	ra,0xfffff
    800060ba:	c7a080e7          	jalr	-902(ra) # 80004d30 <dirlink>
    800060be:	04054463          	bltz	a0,80006106 <create+0x162>
    800060c2:	40d0                	lw	a2,4(s1)
    800060c4:	00003597          	auipc	a1,0x3
    800060c8:	67c58593          	addi	a1,a1,1660 # 80009740 <syscalls+0x2c8>
    800060cc:	8552                	mv	a0,s4
    800060ce:	fffff097          	auipc	ra,0xfffff
    800060d2:	c62080e7          	jalr	-926(ra) # 80004d30 <dirlink>
    800060d6:	02054863          	bltz	a0,80006106 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    800060da:	004a2603          	lw	a2,4(s4)
    800060de:	fb040593          	addi	a1,s0,-80
    800060e2:	8526                	mv	a0,s1
    800060e4:	fffff097          	auipc	ra,0xfffff
    800060e8:	c4c080e7          	jalr	-948(ra) # 80004d30 <dirlink>
    800060ec:	00054d63          	bltz	a0,80006106 <create+0x162>
    dp->nlink++;  // for ".."
    800060f0:	04a4d783          	lhu	a5,74(s1)
    800060f4:	2785                	addiw	a5,a5,1
    800060f6:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800060fa:	8526                	mv	a0,s1
    800060fc:	ffffe097          	auipc	ra,0xffffe
    80006100:	46e080e7          	jalr	1134(ra) # 8000456a <iupdate>
    80006104:	b761                	j	8000608c <create+0xe8>
  ip->nlink = 0;
    80006106:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000610a:	8552                	mv	a0,s4
    8000610c:	ffffe097          	auipc	ra,0xffffe
    80006110:	45e080e7          	jalr	1118(ra) # 8000456a <iupdate>
  iunlockput(ip);
    80006114:	8552                	mv	a0,s4
    80006116:	ffffe097          	auipc	ra,0xffffe
    8000611a:	782080e7          	jalr	1922(ra) # 80004898 <iunlockput>
  iunlockput(dp);
    8000611e:	8526                	mv	a0,s1
    80006120:	ffffe097          	auipc	ra,0xffffe
    80006124:	778080e7          	jalr	1912(ra) # 80004898 <iunlockput>
  return 0;
    80006128:	bdcd                	j	8000601a <create+0x76>
    return 0;
    8000612a:	8aaa                	mv	s5,a0
    8000612c:	b5fd                	j	8000601a <create+0x76>

000000008000612e <sys_dup>:
{
    8000612e:	7179                	addi	sp,sp,-48
    80006130:	f406                	sd	ra,40(sp)
    80006132:	f022                	sd	s0,32(sp)
    80006134:	ec26                	sd	s1,24(sp)
    80006136:	e84a                	sd	s2,16(sp)
    80006138:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    8000613a:	fd840613          	addi	a2,s0,-40
    8000613e:	4581                	li	a1,0
    80006140:	4501                	li	a0,0
    80006142:	00000097          	auipc	ra,0x0
    80006146:	dc0080e7          	jalr	-576(ra) # 80005f02 <argfd>
    return -1;
    8000614a:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000614c:	02054363          	bltz	a0,80006172 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    80006150:	fd843903          	ld	s2,-40(s0)
    80006154:	854a                	mv	a0,s2
    80006156:	00000097          	auipc	ra,0x0
    8000615a:	e0c080e7          	jalr	-500(ra) # 80005f62 <fdalloc>
    8000615e:	84aa                	mv	s1,a0
    return -1;
    80006160:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80006162:	00054863          	bltz	a0,80006172 <sys_dup+0x44>
  filedup(f);
    80006166:	854a                	mv	a0,s2
    80006168:	fffff097          	auipc	ra,0xfffff
    8000616c:	310080e7          	jalr	784(ra) # 80005478 <filedup>
  return fd;
    80006170:	87a6                	mv	a5,s1
}
    80006172:	853e                	mv	a0,a5
    80006174:	70a2                	ld	ra,40(sp)
    80006176:	7402                	ld	s0,32(sp)
    80006178:	64e2                	ld	s1,24(sp)
    8000617a:	6942                	ld	s2,16(sp)
    8000617c:	6145                	addi	sp,sp,48
    8000617e:	8082                	ret

0000000080006180 <sys_read>:
{
    80006180:	7179                	addi	sp,sp,-48
    80006182:	f406                	sd	ra,40(sp)
    80006184:	f022                	sd	s0,32(sp)
    80006186:	1800                	addi	s0,sp,48
  readcount++;
    80006188:	00003717          	auipc	a4,0x3
    8000618c:	7ac70713          	addi	a4,a4,1964 # 80009934 <readcount>
    80006190:	431c                	lw	a5,0(a4)
    80006192:	2785                	addiw	a5,a5,1
    80006194:	c31c                	sw	a5,0(a4)
  argaddr(1, &p);
    80006196:	fd840593          	addi	a1,s0,-40
    8000619a:	4505                	li	a0,1
    8000619c:	ffffd097          	auipc	ra,0xffffd
    800061a0:	7d8080e7          	jalr	2008(ra) # 80003974 <argaddr>
  argint(2, &n);
    800061a4:	fe440593          	addi	a1,s0,-28
    800061a8:	4509                	li	a0,2
    800061aa:	ffffd097          	auipc	ra,0xffffd
    800061ae:	7aa080e7          	jalr	1962(ra) # 80003954 <argint>
  if(argfd(0, 0, &f) < 0)
    800061b2:	fe840613          	addi	a2,s0,-24
    800061b6:	4581                	li	a1,0
    800061b8:	4501                	li	a0,0
    800061ba:	00000097          	auipc	ra,0x0
    800061be:	d48080e7          	jalr	-696(ra) # 80005f02 <argfd>
    800061c2:	87aa                	mv	a5,a0
    return -1;
    800061c4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800061c6:	0007cc63          	bltz	a5,800061de <sys_read+0x5e>
  return fileread(f, p, n);
    800061ca:	fe442603          	lw	a2,-28(s0)
    800061ce:	fd843583          	ld	a1,-40(s0)
    800061d2:	fe843503          	ld	a0,-24(s0)
    800061d6:	fffff097          	auipc	ra,0xfffff
    800061da:	42e080e7          	jalr	1070(ra) # 80005604 <fileread>
}
    800061de:	70a2                	ld	ra,40(sp)
    800061e0:	7402                	ld	s0,32(sp)
    800061e2:	6145                	addi	sp,sp,48
    800061e4:	8082                	ret

00000000800061e6 <sys_write>:
{
    800061e6:	7179                	addi	sp,sp,-48
    800061e8:	f406                	sd	ra,40(sp)
    800061ea:	f022                	sd	s0,32(sp)
    800061ec:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800061ee:	fd840593          	addi	a1,s0,-40
    800061f2:	4505                	li	a0,1
    800061f4:	ffffd097          	auipc	ra,0xffffd
    800061f8:	780080e7          	jalr	1920(ra) # 80003974 <argaddr>
  argint(2, &n);
    800061fc:	fe440593          	addi	a1,s0,-28
    80006200:	4509                	li	a0,2
    80006202:	ffffd097          	auipc	ra,0xffffd
    80006206:	752080e7          	jalr	1874(ra) # 80003954 <argint>
  if(argfd(0, 0, &f) < 0)
    8000620a:	fe840613          	addi	a2,s0,-24
    8000620e:	4581                	li	a1,0
    80006210:	4501                	li	a0,0
    80006212:	00000097          	auipc	ra,0x0
    80006216:	cf0080e7          	jalr	-784(ra) # 80005f02 <argfd>
    8000621a:	87aa                	mv	a5,a0
    return -1;
    8000621c:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000621e:	0007cc63          	bltz	a5,80006236 <sys_write+0x50>
  return filewrite(f, p, n);
    80006222:	fe442603          	lw	a2,-28(s0)
    80006226:	fd843583          	ld	a1,-40(s0)
    8000622a:	fe843503          	ld	a0,-24(s0)
    8000622e:	fffff097          	auipc	ra,0xfffff
    80006232:	498080e7          	jalr	1176(ra) # 800056c6 <filewrite>
}
    80006236:	70a2                	ld	ra,40(sp)
    80006238:	7402                	ld	s0,32(sp)
    8000623a:	6145                	addi	sp,sp,48
    8000623c:	8082                	ret

000000008000623e <sys_close>:
{
    8000623e:	1101                	addi	sp,sp,-32
    80006240:	ec06                	sd	ra,24(sp)
    80006242:	e822                	sd	s0,16(sp)
    80006244:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80006246:	fe040613          	addi	a2,s0,-32
    8000624a:	fec40593          	addi	a1,s0,-20
    8000624e:	4501                	li	a0,0
    80006250:	00000097          	auipc	ra,0x0
    80006254:	cb2080e7          	jalr	-846(ra) # 80005f02 <argfd>
    return -1;
    80006258:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    8000625a:	02054463          	bltz	a0,80006282 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000625e:	ffffb097          	auipc	ra,0xffffb
    80006262:	74e080e7          	jalr	1870(ra) # 800019ac <myproc>
    80006266:	fec42783          	lw	a5,-20(s0)
    8000626a:	07e9                	addi	a5,a5,26
    8000626c:	078e                	slli	a5,a5,0x3
    8000626e:	953e                	add	a0,a0,a5
    80006270:	00053023          	sd	zero,0(a0)
  fileclose(f);
    80006274:	fe043503          	ld	a0,-32(s0)
    80006278:	fffff097          	auipc	ra,0xfffff
    8000627c:	252080e7          	jalr	594(ra) # 800054ca <fileclose>
  return 0;
    80006280:	4781                	li	a5,0
}
    80006282:	853e                	mv	a0,a5
    80006284:	60e2                	ld	ra,24(sp)
    80006286:	6442                	ld	s0,16(sp)
    80006288:	6105                	addi	sp,sp,32
    8000628a:	8082                	ret

000000008000628c <sys_fstat>:
{
    8000628c:	1101                	addi	sp,sp,-32
    8000628e:	ec06                	sd	ra,24(sp)
    80006290:	e822                	sd	s0,16(sp)
    80006292:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80006294:	fe040593          	addi	a1,s0,-32
    80006298:	4505                	li	a0,1
    8000629a:	ffffd097          	auipc	ra,0xffffd
    8000629e:	6da080e7          	jalr	1754(ra) # 80003974 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800062a2:	fe840613          	addi	a2,s0,-24
    800062a6:	4581                	li	a1,0
    800062a8:	4501                	li	a0,0
    800062aa:	00000097          	auipc	ra,0x0
    800062ae:	c58080e7          	jalr	-936(ra) # 80005f02 <argfd>
    800062b2:	87aa                	mv	a5,a0
    return -1;
    800062b4:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800062b6:	0007ca63          	bltz	a5,800062ca <sys_fstat+0x3e>
  return filestat(f, st);
    800062ba:	fe043583          	ld	a1,-32(s0)
    800062be:	fe843503          	ld	a0,-24(s0)
    800062c2:	fffff097          	auipc	ra,0xfffff
    800062c6:	2d0080e7          	jalr	720(ra) # 80005592 <filestat>
}
    800062ca:	60e2                	ld	ra,24(sp)
    800062cc:	6442                	ld	s0,16(sp)
    800062ce:	6105                	addi	sp,sp,32
    800062d0:	8082                	ret

00000000800062d2 <sys_link>:
{
    800062d2:	7169                	addi	sp,sp,-304
    800062d4:	f606                	sd	ra,296(sp)
    800062d6:	f222                	sd	s0,288(sp)
    800062d8:	ee26                	sd	s1,280(sp)
    800062da:	ea4a                	sd	s2,272(sp)
    800062dc:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800062de:	08000613          	li	a2,128
    800062e2:	ed040593          	addi	a1,s0,-304
    800062e6:	4501                	li	a0,0
    800062e8:	ffffd097          	auipc	ra,0xffffd
    800062ec:	6ac080e7          	jalr	1708(ra) # 80003994 <argstr>
    return -1;
    800062f0:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800062f2:	10054e63          	bltz	a0,8000640e <sys_link+0x13c>
    800062f6:	08000613          	li	a2,128
    800062fa:	f5040593          	addi	a1,s0,-176
    800062fe:	4505                	li	a0,1
    80006300:	ffffd097          	auipc	ra,0xffffd
    80006304:	694080e7          	jalr	1684(ra) # 80003994 <argstr>
    return -1;
    80006308:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000630a:	10054263          	bltz	a0,8000640e <sys_link+0x13c>
  begin_op();
    8000630e:	fffff097          	auipc	ra,0xfffff
    80006312:	cf4080e7          	jalr	-780(ra) # 80005002 <begin_op>
  if((ip = namei(old)) == 0){
    80006316:	ed040513          	addi	a0,s0,-304
    8000631a:	fffff097          	auipc	ra,0xfffff
    8000631e:	ac8080e7          	jalr	-1336(ra) # 80004de2 <namei>
    80006322:	84aa                	mv	s1,a0
    80006324:	c551                	beqz	a0,800063b0 <sys_link+0xde>
  ilock(ip);
    80006326:	ffffe097          	auipc	ra,0xffffe
    8000632a:	310080e7          	jalr	784(ra) # 80004636 <ilock>
  if(ip->type == T_DIR){
    8000632e:	04449703          	lh	a4,68(s1)
    80006332:	4785                	li	a5,1
    80006334:	08f70463          	beq	a4,a5,800063bc <sys_link+0xea>
  ip->nlink++;
    80006338:	04a4d783          	lhu	a5,74(s1)
    8000633c:	2785                	addiw	a5,a5,1
    8000633e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006342:	8526                	mv	a0,s1
    80006344:	ffffe097          	auipc	ra,0xffffe
    80006348:	226080e7          	jalr	550(ra) # 8000456a <iupdate>
  iunlock(ip);
    8000634c:	8526                	mv	a0,s1
    8000634e:	ffffe097          	auipc	ra,0xffffe
    80006352:	3aa080e7          	jalr	938(ra) # 800046f8 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80006356:	fd040593          	addi	a1,s0,-48
    8000635a:	f5040513          	addi	a0,s0,-176
    8000635e:	fffff097          	auipc	ra,0xfffff
    80006362:	aa2080e7          	jalr	-1374(ra) # 80004e00 <nameiparent>
    80006366:	892a                	mv	s2,a0
    80006368:	c935                	beqz	a0,800063dc <sys_link+0x10a>
  ilock(dp);
    8000636a:	ffffe097          	auipc	ra,0xffffe
    8000636e:	2cc080e7          	jalr	716(ra) # 80004636 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006372:	00092703          	lw	a4,0(s2)
    80006376:	409c                	lw	a5,0(s1)
    80006378:	04f71d63          	bne	a4,a5,800063d2 <sys_link+0x100>
    8000637c:	40d0                	lw	a2,4(s1)
    8000637e:	fd040593          	addi	a1,s0,-48
    80006382:	854a                	mv	a0,s2
    80006384:	fffff097          	auipc	ra,0xfffff
    80006388:	9ac080e7          	jalr	-1620(ra) # 80004d30 <dirlink>
    8000638c:	04054363          	bltz	a0,800063d2 <sys_link+0x100>
  iunlockput(dp);
    80006390:	854a                	mv	a0,s2
    80006392:	ffffe097          	auipc	ra,0xffffe
    80006396:	506080e7          	jalr	1286(ra) # 80004898 <iunlockput>
  iput(ip);
    8000639a:	8526                	mv	a0,s1
    8000639c:	ffffe097          	auipc	ra,0xffffe
    800063a0:	454080e7          	jalr	1108(ra) # 800047f0 <iput>
  end_op();
    800063a4:	fffff097          	auipc	ra,0xfffff
    800063a8:	cdc080e7          	jalr	-804(ra) # 80005080 <end_op>
  return 0;
    800063ac:	4781                	li	a5,0
    800063ae:	a085                	j	8000640e <sys_link+0x13c>
    end_op();
    800063b0:	fffff097          	auipc	ra,0xfffff
    800063b4:	cd0080e7          	jalr	-816(ra) # 80005080 <end_op>
    return -1;
    800063b8:	57fd                	li	a5,-1
    800063ba:	a891                	j	8000640e <sys_link+0x13c>
    iunlockput(ip);
    800063bc:	8526                	mv	a0,s1
    800063be:	ffffe097          	auipc	ra,0xffffe
    800063c2:	4da080e7          	jalr	1242(ra) # 80004898 <iunlockput>
    end_op();
    800063c6:	fffff097          	auipc	ra,0xfffff
    800063ca:	cba080e7          	jalr	-838(ra) # 80005080 <end_op>
    return -1;
    800063ce:	57fd                	li	a5,-1
    800063d0:	a83d                	j	8000640e <sys_link+0x13c>
    iunlockput(dp);
    800063d2:	854a                	mv	a0,s2
    800063d4:	ffffe097          	auipc	ra,0xffffe
    800063d8:	4c4080e7          	jalr	1220(ra) # 80004898 <iunlockput>
  ilock(ip);
    800063dc:	8526                	mv	a0,s1
    800063de:	ffffe097          	auipc	ra,0xffffe
    800063e2:	258080e7          	jalr	600(ra) # 80004636 <ilock>
  ip->nlink--;
    800063e6:	04a4d783          	lhu	a5,74(s1)
    800063ea:	37fd                	addiw	a5,a5,-1
    800063ec:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800063f0:	8526                	mv	a0,s1
    800063f2:	ffffe097          	auipc	ra,0xffffe
    800063f6:	178080e7          	jalr	376(ra) # 8000456a <iupdate>
  iunlockput(ip);
    800063fa:	8526                	mv	a0,s1
    800063fc:	ffffe097          	auipc	ra,0xffffe
    80006400:	49c080e7          	jalr	1180(ra) # 80004898 <iunlockput>
  end_op();
    80006404:	fffff097          	auipc	ra,0xfffff
    80006408:	c7c080e7          	jalr	-900(ra) # 80005080 <end_op>
  return -1;
    8000640c:	57fd                	li	a5,-1
}
    8000640e:	853e                	mv	a0,a5
    80006410:	70b2                	ld	ra,296(sp)
    80006412:	7412                	ld	s0,288(sp)
    80006414:	64f2                	ld	s1,280(sp)
    80006416:	6952                	ld	s2,272(sp)
    80006418:	6155                	addi	sp,sp,304
    8000641a:	8082                	ret

000000008000641c <sys_unlink>:
{
    8000641c:	7151                	addi	sp,sp,-240
    8000641e:	f586                	sd	ra,232(sp)
    80006420:	f1a2                	sd	s0,224(sp)
    80006422:	eda6                	sd	s1,216(sp)
    80006424:	e9ca                	sd	s2,208(sp)
    80006426:	e5ce                	sd	s3,200(sp)
    80006428:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000642a:	08000613          	li	a2,128
    8000642e:	f3040593          	addi	a1,s0,-208
    80006432:	4501                	li	a0,0
    80006434:	ffffd097          	auipc	ra,0xffffd
    80006438:	560080e7          	jalr	1376(ra) # 80003994 <argstr>
    8000643c:	18054163          	bltz	a0,800065be <sys_unlink+0x1a2>
  begin_op();
    80006440:	fffff097          	auipc	ra,0xfffff
    80006444:	bc2080e7          	jalr	-1086(ra) # 80005002 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80006448:	fb040593          	addi	a1,s0,-80
    8000644c:	f3040513          	addi	a0,s0,-208
    80006450:	fffff097          	auipc	ra,0xfffff
    80006454:	9b0080e7          	jalr	-1616(ra) # 80004e00 <nameiparent>
    80006458:	84aa                	mv	s1,a0
    8000645a:	c979                	beqz	a0,80006530 <sys_unlink+0x114>
  ilock(dp);
    8000645c:	ffffe097          	auipc	ra,0xffffe
    80006460:	1da080e7          	jalr	474(ra) # 80004636 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006464:	00003597          	auipc	a1,0x3
    80006468:	2d458593          	addi	a1,a1,724 # 80009738 <syscalls+0x2c0>
    8000646c:	fb040513          	addi	a0,s0,-80
    80006470:	ffffe097          	auipc	ra,0xffffe
    80006474:	690080e7          	jalr	1680(ra) # 80004b00 <namecmp>
    80006478:	14050a63          	beqz	a0,800065cc <sys_unlink+0x1b0>
    8000647c:	00003597          	auipc	a1,0x3
    80006480:	2c458593          	addi	a1,a1,708 # 80009740 <syscalls+0x2c8>
    80006484:	fb040513          	addi	a0,s0,-80
    80006488:	ffffe097          	auipc	ra,0xffffe
    8000648c:	678080e7          	jalr	1656(ra) # 80004b00 <namecmp>
    80006490:	12050e63          	beqz	a0,800065cc <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006494:	f2c40613          	addi	a2,s0,-212
    80006498:	fb040593          	addi	a1,s0,-80
    8000649c:	8526                	mv	a0,s1
    8000649e:	ffffe097          	auipc	ra,0xffffe
    800064a2:	67c080e7          	jalr	1660(ra) # 80004b1a <dirlookup>
    800064a6:	892a                	mv	s2,a0
    800064a8:	12050263          	beqz	a0,800065cc <sys_unlink+0x1b0>
  ilock(ip);
    800064ac:	ffffe097          	auipc	ra,0xffffe
    800064b0:	18a080e7          	jalr	394(ra) # 80004636 <ilock>
  if(ip->nlink < 1)
    800064b4:	04a91783          	lh	a5,74(s2)
    800064b8:	08f05263          	blez	a5,8000653c <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800064bc:	04491703          	lh	a4,68(s2)
    800064c0:	4785                	li	a5,1
    800064c2:	08f70563          	beq	a4,a5,8000654c <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800064c6:	4641                	li	a2,16
    800064c8:	4581                	li	a1,0
    800064ca:	fc040513          	addi	a0,s0,-64
    800064ce:	ffffb097          	auipc	ra,0xffffb
    800064d2:	804080e7          	jalr	-2044(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800064d6:	4741                	li	a4,16
    800064d8:	f2c42683          	lw	a3,-212(s0)
    800064dc:	fc040613          	addi	a2,s0,-64
    800064e0:	4581                	li	a1,0
    800064e2:	8526                	mv	a0,s1
    800064e4:	ffffe097          	auipc	ra,0xffffe
    800064e8:	4fe080e7          	jalr	1278(ra) # 800049e2 <writei>
    800064ec:	47c1                	li	a5,16
    800064ee:	0af51563          	bne	a0,a5,80006598 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800064f2:	04491703          	lh	a4,68(s2)
    800064f6:	4785                	li	a5,1
    800064f8:	0af70863          	beq	a4,a5,800065a8 <sys_unlink+0x18c>
  iunlockput(dp);
    800064fc:	8526                	mv	a0,s1
    800064fe:	ffffe097          	auipc	ra,0xffffe
    80006502:	39a080e7          	jalr	922(ra) # 80004898 <iunlockput>
  ip->nlink--;
    80006506:	04a95783          	lhu	a5,74(s2)
    8000650a:	37fd                	addiw	a5,a5,-1
    8000650c:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80006510:	854a                	mv	a0,s2
    80006512:	ffffe097          	auipc	ra,0xffffe
    80006516:	058080e7          	jalr	88(ra) # 8000456a <iupdate>
  iunlockput(ip);
    8000651a:	854a                	mv	a0,s2
    8000651c:	ffffe097          	auipc	ra,0xffffe
    80006520:	37c080e7          	jalr	892(ra) # 80004898 <iunlockput>
  end_op();
    80006524:	fffff097          	auipc	ra,0xfffff
    80006528:	b5c080e7          	jalr	-1188(ra) # 80005080 <end_op>
  return 0;
    8000652c:	4501                	li	a0,0
    8000652e:	a84d                	j	800065e0 <sys_unlink+0x1c4>
    end_op();
    80006530:	fffff097          	auipc	ra,0xfffff
    80006534:	b50080e7          	jalr	-1200(ra) # 80005080 <end_op>
    return -1;
    80006538:	557d                	li	a0,-1
    8000653a:	a05d                	j	800065e0 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    8000653c:	00003517          	auipc	a0,0x3
    80006540:	20c50513          	addi	a0,a0,524 # 80009748 <syscalls+0x2d0>
    80006544:	ffffa097          	auipc	ra,0xffffa
    80006548:	ffc080e7          	jalr	-4(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000654c:	04c92703          	lw	a4,76(s2)
    80006550:	02000793          	li	a5,32
    80006554:	f6e7f9e3          	bgeu	a5,a4,800064c6 <sys_unlink+0xaa>
    80006558:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000655c:	4741                	li	a4,16
    8000655e:	86ce                	mv	a3,s3
    80006560:	f1840613          	addi	a2,s0,-232
    80006564:	4581                	li	a1,0
    80006566:	854a                	mv	a0,s2
    80006568:	ffffe097          	auipc	ra,0xffffe
    8000656c:	382080e7          	jalr	898(ra) # 800048ea <readi>
    80006570:	47c1                	li	a5,16
    80006572:	00f51b63          	bne	a0,a5,80006588 <sys_unlink+0x16c>
    if(de.inum != 0)
    80006576:	f1845783          	lhu	a5,-232(s0)
    8000657a:	e7a1                	bnez	a5,800065c2 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    8000657c:	29c1                	addiw	s3,s3,16
    8000657e:	04c92783          	lw	a5,76(s2)
    80006582:	fcf9ede3          	bltu	s3,a5,8000655c <sys_unlink+0x140>
    80006586:	b781                	j	800064c6 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80006588:	00003517          	auipc	a0,0x3
    8000658c:	1d850513          	addi	a0,a0,472 # 80009760 <syscalls+0x2e8>
    80006590:	ffffa097          	auipc	ra,0xffffa
    80006594:	fb0080e7          	jalr	-80(ra) # 80000540 <panic>
    panic("unlink: writei");
    80006598:	00003517          	auipc	a0,0x3
    8000659c:	1e050513          	addi	a0,a0,480 # 80009778 <syscalls+0x300>
    800065a0:	ffffa097          	auipc	ra,0xffffa
    800065a4:	fa0080e7          	jalr	-96(ra) # 80000540 <panic>
    dp->nlink--;
    800065a8:	04a4d783          	lhu	a5,74(s1)
    800065ac:	37fd                	addiw	a5,a5,-1
    800065ae:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800065b2:	8526                	mv	a0,s1
    800065b4:	ffffe097          	auipc	ra,0xffffe
    800065b8:	fb6080e7          	jalr	-74(ra) # 8000456a <iupdate>
    800065bc:	b781                	j	800064fc <sys_unlink+0xe0>
    return -1;
    800065be:	557d                	li	a0,-1
    800065c0:	a005                	j	800065e0 <sys_unlink+0x1c4>
    iunlockput(ip);
    800065c2:	854a                	mv	a0,s2
    800065c4:	ffffe097          	auipc	ra,0xffffe
    800065c8:	2d4080e7          	jalr	724(ra) # 80004898 <iunlockput>
  iunlockput(dp);
    800065cc:	8526                	mv	a0,s1
    800065ce:	ffffe097          	auipc	ra,0xffffe
    800065d2:	2ca080e7          	jalr	714(ra) # 80004898 <iunlockput>
  end_op();
    800065d6:	fffff097          	auipc	ra,0xfffff
    800065da:	aaa080e7          	jalr	-1366(ra) # 80005080 <end_op>
  return -1;
    800065de:	557d                	li	a0,-1
}
    800065e0:	70ae                	ld	ra,232(sp)
    800065e2:	740e                	ld	s0,224(sp)
    800065e4:	64ee                	ld	s1,216(sp)
    800065e6:	694e                	ld	s2,208(sp)
    800065e8:	69ae                	ld	s3,200(sp)
    800065ea:	616d                	addi	sp,sp,240
    800065ec:	8082                	ret

00000000800065ee <sys_open>:

uint64
sys_open(void)
{
    800065ee:	7131                	addi	sp,sp,-192
    800065f0:	fd06                	sd	ra,184(sp)
    800065f2:	f922                	sd	s0,176(sp)
    800065f4:	f526                	sd	s1,168(sp)
    800065f6:	f14a                	sd	s2,160(sp)
    800065f8:	ed4e                	sd	s3,152(sp)
    800065fa:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800065fc:	f4c40593          	addi	a1,s0,-180
    80006600:	4505                	li	a0,1
    80006602:	ffffd097          	auipc	ra,0xffffd
    80006606:	352080e7          	jalr	850(ra) # 80003954 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000660a:	08000613          	li	a2,128
    8000660e:	f5040593          	addi	a1,s0,-176
    80006612:	4501                	li	a0,0
    80006614:	ffffd097          	auipc	ra,0xffffd
    80006618:	380080e7          	jalr	896(ra) # 80003994 <argstr>
    8000661c:	87aa                	mv	a5,a0
    return -1;
    8000661e:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80006620:	0a07c963          	bltz	a5,800066d2 <sys_open+0xe4>

  begin_op();
    80006624:	fffff097          	auipc	ra,0xfffff
    80006628:	9de080e7          	jalr	-1570(ra) # 80005002 <begin_op>

  if(omode & O_CREATE){
    8000662c:	f4c42783          	lw	a5,-180(s0)
    80006630:	2007f793          	andi	a5,a5,512
    80006634:	cfc5                	beqz	a5,800066ec <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80006636:	4681                	li	a3,0
    80006638:	4601                	li	a2,0
    8000663a:	4589                	li	a1,2
    8000663c:	f5040513          	addi	a0,s0,-176
    80006640:	00000097          	auipc	ra,0x0
    80006644:	964080e7          	jalr	-1692(ra) # 80005fa4 <create>
    80006648:	84aa                	mv	s1,a0
    if(ip == 0){
    8000664a:	c959                	beqz	a0,800066e0 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    8000664c:	04449703          	lh	a4,68(s1)
    80006650:	478d                	li	a5,3
    80006652:	00f71763          	bne	a4,a5,80006660 <sys_open+0x72>
    80006656:	0464d703          	lhu	a4,70(s1)
    8000665a:	47a5                	li	a5,9
    8000665c:	0ce7ed63          	bltu	a5,a4,80006736 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006660:	fffff097          	auipc	ra,0xfffff
    80006664:	dae080e7          	jalr	-594(ra) # 8000540e <filealloc>
    80006668:	89aa                	mv	s3,a0
    8000666a:	10050363          	beqz	a0,80006770 <sys_open+0x182>
    8000666e:	00000097          	auipc	ra,0x0
    80006672:	8f4080e7          	jalr	-1804(ra) # 80005f62 <fdalloc>
    80006676:	892a                	mv	s2,a0
    80006678:	0e054763          	bltz	a0,80006766 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    8000667c:	04449703          	lh	a4,68(s1)
    80006680:	478d                	li	a5,3
    80006682:	0cf70563          	beq	a4,a5,8000674c <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80006686:	4789                	li	a5,2
    80006688:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    8000668c:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006690:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006694:	f4c42783          	lw	a5,-180(s0)
    80006698:	0017c713          	xori	a4,a5,1
    8000669c:	8b05                	andi	a4,a4,1
    8000669e:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800066a2:	0037f713          	andi	a4,a5,3
    800066a6:	00e03733          	snez	a4,a4
    800066aa:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800066ae:	4007f793          	andi	a5,a5,1024
    800066b2:	c791                	beqz	a5,800066be <sys_open+0xd0>
    800066b4:	04449703          	lh	a4,68(s1)
    800066b8:	4789                	li	a5,2
    800066ba:	0af70063          	beq	a4,a5,8000675a <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800066be:	8526                	mv	a0,s1
    800066c0:	ffffe097          	auipc	ra,0xffffe
    800066c4:	038080e7          	jalr	56(ra) # 800046f8 <iunlock>
  end_op();
    800066c8:	fffff097          	auipc	ra,0xfffff
    800066cc:	9b8080e7          	jalr	-1608(ra) # 80005080 <end_op>

  return fd;
    800066d0:	854a                	mv	a0,s2
}
    800066d2:	70ea                	ld	ra,184(sp)
    800066d4:	744a                	ld	s0,176(sp)
    800066d6:	74aa                	ld	s1,168(sp)
    800066d8:	790a                	ld	s2,160(sp)
    800066da:	69ea                	ld	s3,152(sp)
    800066dc:	6129                	addi	sp,sp,192
    800066de:	8082                	ret
      end_op();
    800066e0:	fffff097          	auipc	ra,0xfffff
    800066e4:	9a0080e7          	jalr	-1632(ra) # 80005080 <end_op>
      return -1;
    800066e8:	557d                	li	a0,-1
    800066ea:	b7e5                	j	800066d2 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800066ec:	f5040513          	addi	a0,s0,-176
    800066f0:	ffffe097          	auipc	ra,0xffffe
    800066f4:	6f2080e7          	jalr	1778(ra) # 80004de2 <namei>
    800066f8:	84aa                	mv	s1,a0
    800066fa:	c905                	beqz	a0,8000672a <sys_open+0x13c>
    ilock(ip);
    800066fc:	ffffe097          	auipc	ra,0xffffe
    80006700:	f3a080e7          	jalr	-198(ra) # 80004636 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80006704:	04449703          	lh	a4,68(s1)
    80006708:	4785                	li	a5,1
    8000670a:	f4f711e3          	bne	a4,a5,8000664c <sys_open+0x5e>
    8000670e:	f4c42783          	lw	a5,-180(s0)
    80006712:	d7b9                	beqz	a5,80006660 <sys_open+0x72>
      iunlockput(ip);
    80006714:	8526                	mv	a0,s1
    80006716:	ffffe097          	auipc	ra,0xffffe
    8000671a:	182080e7          	jalr	386(ra) # 80004898 <iunlockput>
      end_op();
    8000671e:	fffff097          	auipc	ra,0xfffff
    80006722:	962080e7          	jalr	-1694(ra) # 80005080 <end_op>
      return -1;
    80006726:	557d                	li	a0,-1
    80006728:	b76d                	j	800066d2 <sys_open+0xe4>
      end_op();
    8000672a:	fffff097          	auipc	ra,0xfffff
    8000672e:	956080e7          	jalr	-1706(ra) # 80005080 <end_op>
      return -1;
    80006732:	557d                	li	a0,-1
    80006734:	bf79                	j	800066d2 <sys_open+0xe4>
    iunlockput(ip);
    80006736:	8526                	mv	a0,s1
    80006738:	ffffe097          	auipc	ra,0xffffe
    8000673c:	160080e7          	jalr	352(ra) # 80004898 <iunlockput>
    end_op();
    80006740:	fffff097          	auipc	ra,0xfffff
    80006744:	940080e7          	jalr	-1728(ra) # 80005080 <end_op>
    return -1;
    80006748:	557d                	li	a0,-1
    8000674a:	b761                	j	800066d2 <sys_open+0xe4>
    f->type = FD_DEVICE;
    8000674c:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006750:	04649783          	lh	a5,70(s1)
    80006754:	02f99223          	sh	a5,36(s3)
    80006758:	bf25                	j	80006690 <sys_open+0xa2>
    itrunc(ip);
    8000675a:	8526                	mv	a0,s1
    8000675c:	ffffe097          	auipc	ra,0xffffe
    80006760:	fe8080e7          	jalr	-24(ra) # 80004744 <itrunc>
    80006764:	bfa9                	j	800066be <sys_open+0xd0>
      fileclose(f);
    80006766:	854e                	mv	a0,s3
    80006768:	fffff097          	auipc	ra,0xfffff
    8000676c:	d62080e7          	jalr	-670(ra) # 800054ca <fileclose>
    iunlockput(ip);
    80006770:	8526                	mv	a0,s1
    80006772:	ffffe097          	auipc	ra,0xffffe
    80006776:	126080e7          	jalr	294(ra) # 80004898 <iunlockput>
    end_op();
    8000677a:	fffff097          	auipc	ra,0xfffff
    8000677e:	906080e7          	jalr	-1786(ra) # 80005080 <end_op>
    return -1;
    80006782:	557d                	li	a0,-1
    80006784:	b7b9                	j	800066d2 <sys_open+0xe4>

0000000080006786 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80006786:	7175                	addi	sp,sp,-144
    80006788:	e506                	sd	ra,136(sp)
    8000678a:	e122                	sd	s0,128(sp)
    8000678c:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    8000678e:	fffff097          	auipc	ra,0xfffff
    80006792:	874080e7          	jalr	-1932(ra) # 80005002 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80006796:	08000613          	li	a2,128
    8000679a:	f7040593          	addi	a1,s0,-144
    8000679e:	4501                	li	a0,0
    800067a0:	ffffd097          	auipc	ra,0xffffd
    800067a4:	1f4080e7          	jalr	500(ra) # 80003994 <argstr>
    800067a8:	02054963          	bltz	a0,800067da <sys_mkdir+0x54>
    800067ac:	4681                	li	a3,0
    800067ae:	4601                	li	a2,0
    800067b0:	4585                	li	a1,1
    800067b2:	f7040513          	addi	a0,s0,-144
    800067b6:	fffff097          	auipc	ra,0xfffff
    800067ba:	7ee080e7          	jalr	2030(ra) # 80005fa4 <create>
    800067be:	cd11                	beqz	a0,800067da <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800067c0:	ffffe097          	auipc	ra,0xffffe
    800067c4:	0d8080e7          	jalr	216(ra) # 80004898 <iunlockput>
  end_op();
    800067c8:	fffff097          	auipc	ra,0xfffff
    800067cc:	8b8080e7          	jalr	-1864(ra) # 80005080 <end_op>
  return 0;
    800067d0:	4501                	li	a0,0
}
    800067d2:	60aa                	ld	ra,136(sp)
    800067d4:	640a                	ld	s0,128(sp)
    800067d6:	6149                	addi	sp,sp,144
    800067d8:	8082                	ret
    end_op();
    800067da:	fffff097          	auipc	ra,0xfffff
    800067de:	8a6080e7          	jalr	-1882(ra) # 80005080 <end_op>
    return -1;
    800067e2:	557d                	li	a0,-1
    800067e4:	b7fd                	j	800067d2 <sys_mkdir+0x4c>

00000000800067e6 <sys_mknod>:

uint64
sys_mknod(void)
{
    800067e6:	7135                	addi	sp,sp,-160
    800067e8:	ed06                	sd	ra,152(sp)
    800067ea:	e922                	sd	s0,144(sp)
    800067ec:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800067ee:	fffff097          	auipc	ra,0xfffff
    800067f2:	814080e7          	jalr	-2028(ra) # 80005002 <begin_op>
  argint(1, &major);
    800067f6:	f6c40593          	addi	a1,s0,-148
    800067fa:	4505                	li	a0,1
    800067fc:	ffffd097          	auipc	ra,0xffffd
    80006800:	158080e7          	jalr	344(ra) # 80003954 <argint>
  argint(2, &minor);
    80006804:	f6840593          	addi	a1,s0,-152
    80006808:	4509                	li	a0,2
    8000680a:	ffffd097          	auipc	ra,0xffffd
    8000680e:	14a080e7          	jalr	330(ra) # 80003954 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006812:	08000613          	li	a2,128
    80006816:	f7040593          	addi	a1,s0,-144
    8000681a:	4501                	li	a0,0
    8000681c:	ffffd097          	auipc	ra,0xffffd
    80006820:	178080e7          	jalr	376(ra) # 80003994 <argstr>
    80006824:	02054b63          	bltz	a0,8000685a <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80006828:	f6841683          	lh	a3,-152(s0)
    8000682c:	f6c41603          	lh	a2,-148(s0)
    80006830:	458d                	li	a1,3
    80006832:	f7040513          	addi	a0,s0,-144
    80006836:	fffff097          	auipc	ra,0xfffff
    8000683a:	76e080e7          	jalr	1902(ra) # 80005fa4 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000683e:	cd11                	beqz	a0,8000685a <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006840:	ffffe097          	auipc	ra,0xffffe
    80006844:	058080e7          	jalr	88(ra) # 80004898 <iunlockput>
  end_op();
    80006848:	fffff097          	auipc	ra,0xfffff
    8000684c:	838080e7          	jalr	-1992(ra) # 80005080 <end_op>
  return 0;
    80006850:	4501                	li	a0,0
}
    80006852:	60ea                	ld	ra,152(sp)
    80006854:	644a                	ld	s0,144(sp)
    80006856:	610d                	addi	sp,sp,160
    80006858:	8082                	ret
    end_op();
    8000685a:	fffff097          	auipc	ra,0xfffff
    8000685e:	826080e7          	jalr	-2010(ra) # 80005080 <end_op>
    return -1;
    80006862:	557d                	li	a0,-1
    80006864:	b7fd                	j	80006852 <sys_mknod+0x6c>

0000000080006866 <sys_chdir>:

uint64
sys_chdir(void)
{
    80006866:	7135                	addi	sp,sp,-160
    80006868:	ed06                	sd	ra,152(sp)
    8000686a:	e922                	sd	s0,144(sp)
    8000686c:	e526                	sd	s1,136(sp)
    8000686e:	e14a                	sd	s2,128(sp)
    80006870:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006872:	ffffb097          	auipc	ra,0xffffb
    80006876:	13a080e7          	jalr	314(ra) # 800019ac <myproc>
    8000687a:	892a                	mv	s2,a0
  
  begin_op();
    8000687c:	ffffe097          	auipc	ra,0xffffe
    80006880:	786080e7          	jalr	1926(ra) # 80005002 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006884:	08000613          	li	a2,128
    80006888:	f6040593          	addi	a1,s0,-160
    8000688c:	4501                	li	a0,0
    8000688e:	ffffd097          	auipc	ra,0xffffd
    80006892:	106080e7          	jalr	262(ra) # 80003994 <argstr>
    80006896:	04054b63          	bltz	a0,800068ec <sys_chdir+0x86>
    8000689a:	f6040513          	addi	a0,s0,-160
    8000689e:	ffffe097          	auipc	ra,0xffffe
    800068a2:	544080e7          	jalr	1348(ra) # 80004de2 <namei>
    800068a6:	84aa                	mv	s1,a0
    800068a8:	c131                	beqz	a0,800068ec <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800068aa:	ffffe097          	auipc	ra,0xffffe
    800068ae:	d8c080e7          	jalr	-628(ra) # 80004636 <ilock>
  if(ip->type != T_DIR){
    800068b2:	04449703          	lh	a4,68(s1)
    800068b6:	4785                	li	a5,1
    800068b8:	04f71063          	bne	a4,a5,800068f8 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800068bc:	8526                	mv	a0,s1
    800068be:	ffffe097          	auipc	ra,0xffffe
    800068c2:	e3a080e7          	jalr	-454(ra) # 800046f8 <iunlock>
  iput(p->cwd);
    800068c6:	15093503          	ld	a0,336(s2)
    800068ca:	ffffe097          	auipc	ra,0xffffe
    800068ce:	f26080e7          	jalr	-218(ra) # 800047f0 <iput>
  end_op();
    800068d2:	ffffe097          	auipc	ra,0xffffe
    800068d6:	7ae080e7          	jalr	1966(ra) # 80005080 <end_op>
  p->cwd = ip;
    800068da:	14993823          	sd	s1,336(s2)
  return 0;
    800068de:	4501                	li	a0,0
}
    800068e0:	60ea                	ld	ra,152(sp)
    800068e2:	644a                	ld	s0,144(sp)
    800068e4:	64aa                	ld	s1,136(sp)
    800068e6:	690a                	ld	s2,128(sp)
    800068e8:	610d                	addi	sp,sp,160
    800068ea:	8082                	ret
    end_op();
    800068ec:	ffffe097          	auipc	ra,0xffffe
    800068f0:	794080e7          	jalr	1940(ra) # 80005080 <end_op>
    return -1;
    800068f4:	557d                	li	a0,-1
    800068f6:	b7ed                	j	800068e0 <sys_chdir+0x7a>
    iunlockput(ip);
    800068f8:	8526                	mv	a0,s1
    800068fa:	ffffe097          	auipc	ra,0xffffe
    800068fe:	f9e080e7          	jalr	-98(ra) # 80004898 <iunlockput>
    end_op();
    80006902:	ffffe097          	auipc	ra,0xffffe
    80006906:	77e080e7          	jalr	1918(ra) # 80005080 <end_op>
    return -1;
    8000690a:	557d                	li	a0,-1
    8000690c:	bfd1                	j	800068e0 <sys_chdir+0x7a>

000000008000690e <sys_exec>:

uint64
sys_exec(void)
{
    8000690e:	7145                	addi	sp,sp,-464
    80006910:	e786                	sd	ra,456(sp)
    80006912:	e3a2                	sd	s0,448(sp)
    80006914:	ff26                	sd	s1,440(sp)
    80006916:	fb4a                	sd	s2,432(sp)
    80006918:	f74e                	sd	s3,424(sp)
    8000691a:	f352                	sd	s4,416(sp)
    8000691c:	ef56                	sd	s5,408(sp)
    8000691e:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80006920:	e3840593          	addi	a1,s0,-456
    80006924:	4505                	li	a0,1
    80006926:	ffffd097          	auipc	ra,0xffffd
    8000692a:	04e080e7          	jalr	78(ra) # 80003974 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    8000692e:	08000613          	li	a2,128
    80006932:	f4040593          	addi	a1,s0,-192
    80006936:	4501                	li	a0,0
    80006938:	ffffd097          	auipc	ra,0xffffd
    8000693c:	05c080e7          	jalr	92(ra) # 80003994 <argstr>
    80006940:	87aa                	mv	a5,a0
    return -1;
    80006942:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006944:	0c07c363          	bltz	a5,80006a0a <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80006948:	10000613          	li	a2,256
    8000694c:	4581                	li	a1,0
    8000694e:	e4040513          	addi	a0,s0,-448
    80006952:	ffffa097          	auipc	ra,0xffffa
    80006956:	380080e7          	jalr	896(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000695a:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    8000695e:	89a6                	mv	s3,s1
    80006960:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006962:	02000a13          	li	s4,32
    80006966:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000696a:	00391513          	slli	a0,s2,0x3
    8000696e:	e3040593          	addi	a1,s0,-464
    80006972:	e3843783          	ld	a5,-456(s0)
    80006976:	953e                	add	a0,a0,a5
    80006978:	ffffd097          	auipc	ra,0xffffd
    8000697c:	f3e080e7          	jalr	-194(ra) # 800038b6 <fetchaddr>
    80006980:	02054a63          	bltz	a0,800069b4 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006984:	e3043783          	ld	a5,-464(s0)
    80006988:	c3b9                	beqz	a5,800069ce <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000698a:	ffffa097          	auipc	ra,0xffffa
    8000698e:	15c080e7          	jalr	348(ra) # 80000ae6 <kalloc>
    80006992:	85aa                	mv	a1,a0
    80006994:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80006998:	cd11                	beqz	a0,800069b4 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000699a:	6605                	lui	a2,0x1
    8000699c:	e3043503          	ld	a0,-464(s0)
    800069a0:	ffffd097          	auipc	ra,0xffffd
    800069a4:	f68080e7          	jalr	-152(ra) # 80003908 <fetchstr>
    800069a8:	00054663          	bltz	a0,800069b4 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    800069ac:	0905                	addi	s2,s2,1
    800069ae:	09a1                	addi	s3,s3,8
    800069b0:	fb491be3          	bne	s2,s4,80006966 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069b4:	f4040913          	addi	s2,s0,-192
    800069b8:	6088                	ld	a0,0(s1)
    800069ba:	c539                	beqz	a0,80006a08 <sys_exec+0xfa>
    kfree(argv[i]);
    800069bc:	ffffa097          	auipc	ra,0xffffa
    800069c0:	02c080e7          	jalr	44(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069c4:	04a1                	addi	s1,s1,8
    800069c6:	ff2499e3          	bne	s1,s2,800069b8 <sys_exec+0xaa>
  return -1;
    800069ca:	557d                	li	a0,-1
    800069cc:	a83d                	j	80006a0a <sys_exec+0xfc>
      argv[i] = 0;
    800069ce:	0a8e                	slli	s5,s5,0x3
    800069d0:	fc0a8793          	addi	a5,s5,-64
    800069d4:	00878ab3          	add	s5,a5,s0
    800069d8:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800069dc:	e4040593          	addi	a1,s0,-448
    800069e0:	f4040513          	addi	a0,s0,-192
    800069e4:	fffff097          	auipc	ra,0xfffff
    800069e8:	160080e7          	jalr	352(ra) # 80005b44 <exec>
    800069ec:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069ee:	f4040993          	addi	s3,s0,-192
    800069f2:	6088                	ld	a0,0(s1)
    800069f4:	c901                	beqz	a0,80006a04 <sys_exec+0xf6>
    kfree(argv[i]);
    800069f6:	ffffa097          	auipc	ra,0xffffa
    800069fa:	ff2080e7          	jalr	-14(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800069fe:	04a1                	addi	s1,s1,8
    80006a00:	ff3499e3          	bne	s1,s3,800069f2 <sys_exec+0xe4>
  return ret;
    80006a04:	854a                	mv	a0,s2
    80006a06:	a011                	j	80006a0a <sys_exec+0xfc>
  return -1;
    80006a08:	557d                	li	a0,-1
}
    80006a0a:	60be                	ld	ra,456(sp)
    80006a0c:	641e                	ld	s0,448(sp)
    80006a0e:	74fa                	ld	s1,440(sp)
    80006a10:	795a                	ld	s2,432(sp)
    80006a12:	79ba                	ld	s3,424(sp)
    80006a14:	7a1a                	ld	s4,416(sp)
    80006a16:	6afa                	ld	s5,408(sp)
    80006a18:	6179                	addi	sp,sp,464
    80006a1a:	8082                	ret

0000000080006a1c <sys_pipe>:

uint64
sys_pipe(void)
{
    80006a1c:	7139                	addi	sp,sp,-64
    80006a1e:	fc06                	sd	ra,56(sp)
    80006a20:	f822                	sd	s0,48(sp)
    80006a22:	f426                	sd	s1,40(sp)
    80006a24:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80006a26:	ffffb097          	auipc	ra,0xffffb
    80006a2a:	f86080e7          	jalr	-122(ra) # 800019ac <myproc>
    80006a2e:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006a30:	fd840593          	addi	a1,s0,-40
    80006a34:	4501                	li	a0,0
    80006a36:	ffffd097          	auipc	ra,0xffffd
    80006a3a:	f3e080e7          	jalr	-194(ra) # 80003974 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006a3e:	fc840593          	addi	a1,s0,-56
    80006a42:	fd040513          	addi	a0,s0,-48
    80006a46:	fffff097          	auipc	ra,0xfffff
    80006a4a:	db4080e7          	jalr	-588(ra) # 800057fa <pipealloc>
    return -1;
    80006a4e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006a50:	0c054463          	bltz	a0,80006b18 <sys_pipe+0xfc>
  fd0 = -1;
    80006a54:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80006a58:	fd043503          	ld	a0,-48(s0)
    80006a5c:	fffff097          	auipc	ra,0xfffff
    80006a60:	506080e7          	jalr	1286(ra) # 80005f62 <fdalloc>
    80006a64:	fca42223          	sw	a0,-60(s0)
    80006a68:	08054b63          	bltz	a0,80006afe <sys_pipe+0xe2>
    80006a6c:	fc843503          	ld	a0,-56(s0)
    80006a70:	fffff097          	auipc	ra,0xfffff
    80006a74:	4f2080e7          	jalr	1266(ra) # 80005f62 <fdalloc>
    80006a78:	fca42023          	sw	a0,-64(s0)
    80006a7c:	06054863          	bltz	a0,80006aec <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006a80:	4691                	li	a3,4
    80006a82:	fc440613          	addi	a2,s0,-60
    80006a86:	fd843583          	ld	a1,-40(s0)
    80006a8a:	68a8                	ld	a0,80(s1)
    80006a8c:	ffffb097          	auipc	ra,0xffffb
    80006a90:	be0080e7          	jalr	-1056(ra) # 8000166c <copyout>
    80006a94:	02054063          	bltz	a0,80006ab4 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80006a98:	4691                	li	a3,4
    80006a9a:	fc040613          	addi	a2,s0,-64
    80006a9e:	fd843583          	ld	a1,-40(s0)
    80006aa2:	0591                	addi	a1,a1,4
    80006aa4:	68a8                	ld	a0,80(s1)
    80006aa6:	ffffb097          	auipc	ra,0xffffb
    80006aaa:	bc6080e7          	jalr	-1082(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006aae:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006ab0:	06055463          	bgez	a0,80006b18 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006ab4:	fc442783          	lw	a5,-60(s0)
    80006ab8:	07e9                	addi	a5,a5,26
    80006aba:	078e                	slli	a5,a5,0x3
    80006abc:	97a6                	add	a5,a5,s1
    80006abe:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80006ac2:	fc042783          	lw	a5,-64(s0)
    80006ac6:	07e9                	addi	a5,a5,26
    80006ac8:	078e                	slli	a5,a5,0x3
    80006aca:	94be                	add	s1,s1,a5
    80006acc:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80006ad0:	fd043503          	ld	a0,-48(s0)
    80006ad4:	fffff097          	auipc	ra,0xfffff
    80006ad8:	9f6080e7          	jalr	-1546(ra) # 800054ca <fileclose>
    fileclose(wf);
    80006adc:	fc843503          	ld	a0,-56(s0)
    80006ae0:	fffff097          	auipc	ra,0xfffff
    80006ae4:	9ea080e7          	jalr	-1558(ra) # 800054ca <fileclose>
    return -1;
    80006ae8:	57fd                	li	a5,-1
    80006aea:	a03d                	j	80006b18 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80006aec:	fc442783          	lw	a5,-60(s0)
    80006af0:	0007c763          	bltz	a5,80006afe <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80006af4:	07e9                	addi	a5,a5,26
    80006af6:	078e                	slli	a5,a5,0x3
    80006af8:	97a6                	add	a5,a5,s1
    80006afa:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80006afe:	fd043503          	ld	a0,-48(s0)
    80006b02:	fffff097          	auipc	ra,0xfffff
    80006b06:	9c8080e7          	jalr	-1592(ra) # 800054ca <fileclose>
    fileclose(wf);
    80006b0a:	fc843503          	ld	a0,-56(s0)
    80006b0e:	fffff097          	auipc	ra,0xfffff
    80006b12:	9bc080e7          	jalr	-1604(ra) # 800054ca <fileclose>
    return -1;
    80006b16:	57fd                	li	a5,-1
}
    80006b18:	853e                	mv	a0,a5
    80006b1a:	70e2                	ld	ra,56(sp)
    80006b1c:	7442                	ld	s0,48(sp)
    80006b1e:	74a2                	ld	s1,40(sp)
    80006b20:	6121                	addi	sp,sp,64
    80006b22:	8082                	ret
	...

0000000080006b30 <kernelvec>:
    80006b30:	7111                	addi	sp,sp,-256
    80006b32:	e006                	sd	ra,0(sp)
    80006b34:	e40a                	sd	sp,8(sp)
    80006b36:	e80e                	sd	gp,16(sp)
    80006b38:	ec12                	sd	tp,24(sp)
    80006b3a:	f016                	sd	t0,32(sp)
    80006b3c:	f41a                	sd	t1,40(sp)
    80006b3e:	f81e                	sd	t2,48(sp)
    80006b40:	fc22                	sd	s0,56(sp)
    80006b42:	e0a6                	sd	s1,64(sp)
    80006b44:	e4aa                	sd	a0,72(sp)
    80006b46:	e8ae                	sd	a1,80(sp)
    80006b48:	ecb2                	sd	a2,88(sp)
    80006b4a:	f0b6                	sd	a3,96(sp)
    80006b4c:	f4ba                	sd	a4,104(sp)
    80006b4e:	f8be                	sd	a5,112(sp)
    80006b50:	fcc2                	sd	a6,120(sp)
    80006b52:	e146                	sd	a7,128(sp)
    80006b54:	e54a                	sd	s2,136(sp)
    80006b56:	e94e                	sd	s3,144(sp)
    80006b58:	ed52                	sd	s4,152(sp)
    80006b5a:	f156                	sd	s5,160(sp)
    80006b5c:	f55a                	sd	s6,168(sp)
    80006b5e:	f95e                	sd	s7,176(sp)
    80006b60:	fd62                	sd	s8,184(sp)
    80006b62:	e1e6                	sd	s9,192(sp)
    80006b64:	e5ea                	sd	s10,200(sp)
    80006b66:	e9ee                	sd	s11,208(sp)
    80006b68:	edf2                	sd	t3,216(sp)
    80006b6a:	f1f6                	sd	t4,224(sp)
    80006b6c:	f5fa                	sd	t5,232(sp)
    80006b6e:	f9fe                	sd	t6,240(sp)
    80006b70:	c13fc0ef          	jal	ra,80003782 <kerneltrap>
    80006b74:	6082                	ld	ra,0(sp)
    80006b76:	6122                	ld	sp,8(sp)
    80006b78:	61c2                	ld	gp,16(sp)
    80006b7a:	7282                	ld	t0,32(sp)
    80006b7c:	7322                	ld	t1,40(sp)
    80006b7e:	73c2                	ld	t2,48(sp)
    80006b80:	7462                	ld	s0,56(sp)
    80006b82:	6486                	ld	s1,64(sp)
    80006b84:	6526                	ld	a0,72(sp)
    80006b86:	65c6                	ld	a1,80(sp)
    80006b88:	6666                	ld	a2,88(sp)
    80006b8a:	7686                	ld	a3,96(sp)
    80006b8c:	7726                	ld	a4,104(sp)
    80006b8e:	77c6                	ld	a5,112(sp)
    80006b90:	7866                	ld	a6,120(sp)
    80006b92:	688a                	ld	a7,128(sp)
    80006b94:	692a                	ld	s2,136(sp)
    80006b96:	69ca                	ld	s3,144(sp)
    80006b98:	6a6a                	ld	s4,152(sp)
    80006b9a:	7a8a                	ld	s5,160(sp)
    80006b9c:	7b2a                	ld	s6,168(sp)
    80006b9e:	7bca                	ld	s7,176(sp)
    80006ba0:	7c6a                	ld	s8,184(sp)
    80006ba2:	6c8e                	ld	s9,192(sp)
    80006ba4:	6d2e                	ld	s10,200(sp)
    80006ba6:	6dce                	ld	s11,208(sp)
    80006ba8:	6e6e                	ld	t3,216(sp)
    80006baa:	7e8e                	ld	t4,224(sp)
    80006bac:	7f2e                	ld	t5,232(sp)
    80006bae:	7fce                	ld	t6,240(sp)
    80006bb0:	6111                	addi	sp,sp,256
    80006bb2:	10200073          	sret
    80006bb6:	00000013          	nop
    80006bba:	00000013          	nop
    80006bbe:	0001                	nop

0000000080006bc0 <timervec>:
    80006bc0:	34051573          	csrrw	a0,mscratch,a0
    80006bc4:	e10c                	sd	a1,0(a0)
    80006bc6:	e510                	sd	a2,8(a0)
    80006bc8:	e914                	sd	a3,16(a0)
    80006bca:	6d0c                	ld	a1,24(a0)
    80006bcc:	7110                	ld	a2,32(a0)
    80006bce:	6194                	ld	a3,0(a1)
    80006bd0:	96b2                	add	a3,a3,a2
    80006bd2:	e194                	sd	a3,0(a1)
    80006bd4:	4589                	li	a1,2
    80006bd6:	14459073          	csrw	sip,a1
    80006bda:	6914                	ld	a3,16(a0)
    80006bdc:	6510                	ld	a2,8(a0)
    80006bde:	610c                	ld	a1,0(a0)
    80006be0:	34051573          	csrrw	a0,mscratch,a0
    80006be4:	30200073          	mret
	...

0000000080006bea <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80006bea:	1141                	addi	sp,sp,-16
    80006bec:	e422                	sd	s0,8(sp)
    80006bee:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80006bf0:	0c0007b7          	lui	a5,0xc000
    80006bf4:	4705                	li	a4,1
    80006bf6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80006bf8:	c3d8                	sw	a4,4(a5)
}
    80006bfa:	6422                	ld	s0,8(sp)
    80006bfc:	0141                	addi	sp,sp,16
    80006bfe:	8082                	ret

0000000080006c00 <plicinithart>:

void
plicinithart(void)
{
    80006c00:	1141                	addi	sp,sp,-16
    80006c02:	e406                	sd	ra,8(sp)
    80006c04:	e022                	sd	s0,0(sp)
    80006c06:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006c08:	ffffb097          	auipc	ra,0xffffb
    80006c0c:	d78080e7          	jalr	-648(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80006c10:	0085171b          	slliw	a4,a0,0x8
    80006c14:	0c0027b7          	lui	a5,0xc002
    80006c18:	97ba                	add	a5,a5,a4
    80006c1a:	40200713          	li	a4,1026
    80006c1e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006c22:	00d5151b          	slliw	a0,a0,0xd
    80006c26:	0c2017b7          	lui	a5,0xc201
    80006c2a:	97aa                	add	a5,a5,a0
    80006c2c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80006c30:	60a2                	ld	ra,8(sp)
    80006c32:	6402                	ld	s0,0(sp)
    80006c34:	0141                	addi	sp,sp,16
    80006c36:	8082                	ret

0000000080006c38 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006c38:	1141                	addi	sp,sp,-16
    80006c3a:	e406                	sd	ra,8(sp)
    80006c3c:	e022                	sd	s0,0(sp)
    80006c3e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006c40:	ffffb097          	auipc	ra,0xffffb
    80006c44:	d40080e7          	jalr	-704(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006c48:	00d5151b          	slliw	a0,a0,0xd
    80006c4c:	0c2017b7          	lui	a5,0xc201
    80006c50:	97aa                	add	a5,a5,a0
  return irq;
}
    80006c52:	43c8                	lw	a0,4(a5)
    80006c54:	60a2                	ld	ra,8(sp)
    80006c56:	6402                	ld	s0,0(sp)
    80006c58:	0141                	addi	sp,sp,16
    80006c5a:	8082                	ret

0000000080006c5c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80006c5c:	1101                	addi	sp,sp,-32
    80006c5e:	ec06                	sd	ra,24(sp)
    80006c60:	e822                	sd	s0,16(sp)
    80006c62:	e426                	sd	s1,8(sp)
    80006c64:	1000                	addi	s0,sp,32
    80006c66:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006c68:	ffffb097          	auipc	ra,0xffffb
    80006c6c:	d18080e7          	jalr	-744(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006c70:	00d5151b          	slliw	a0,a0,0xd
    80006c74:	0c2017b7          	lui	a5,0xc201
    80006c78:	97aa                	add	a5,a5,a0
    80006c7a:	c3c4                	sw	s1,4(a5)
}
    80006c7c:	60e2                	ld	ra,24(sp)
    80006c7e:	6442                	ld	s0,16(sp)
    80006c80:	64a2                	ld	s1,8(sp)
    80006c82:	6105                	addi	sp,sp,32
    80006c84:	8082                	ret

0000000080006c86 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006c86:	1141                	addi	sp,sp,-16
    80006c88:	e406                	sd	ra,8(sp)
    80006c8a:	e022                	sd	s0,0(sp)
    80006c8c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80006c8e:	479d                	li	a5,7
    80006c90:	04a7cc63          	blt	a5,a0,80006ce8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006c94:	0001d797          	auipc	a5,0x1d
    80006c98:	7ec78793          	addi	a5,a5,2028 # 80024480 <disk>
    80006c9c:	97aa                	add	a5,a5,a0
    80006c9e:	0187c783          	lbu	a5,24(a5)
    80006ca2:	ebb9                	bnez	a5,80006cf8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006ca4:	00451693          	slli	a3,a0,0x4
    80006ca8:	0001d797          	auipc	a5,0x1d
    80006cac:	7d878793          	addi	a5,a5,2008 # 80024480 <disk>
    80006cb0:	6398                	ld	a4,0(a5)
    80006cb2:	9736                	add	a4,a4,a3
    80006cb4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006cb8:	6398                	ld	a4,0(a5)
    80006cba:	9736                	add	a4,a4,a3
    80006cbc:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006cc0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006cc4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006cc8:	97aa                	add	a5,a5,a0
    80006cca:	4705                	li	a4,1
    80006ccc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006cd0:	0001d517          	auipc	a0,0x1d
    80006cd4:	7c850513          	addi	a0,a0,1992 # 80024498 <disk+0x18>
    80006cd8:	ffffc097          	auipc	ra,0xffffc
    80006cdc:	002080e7          	jalr	2(ra) # 80002cda <wakeup>
}
    80006ce0:	60a2                	ld	ra,8(sp)
    80006ce2:	6402                	ld	s0,0(sp)
    80006ce4:	0141                	addi	sp,sp,16
    80006ce6:	8082                	ret
    panic("free_desc 1");
    80006ce8:	00003517          	auipc	a0,0x3
    80006cec:	aa050513          	addi	a0,a0,-1376 # 80009788 <syscalls+0x310>
    80006cf0:	ffffa097          	auipc	ra,0xffffa
    80006cf4:	850080e7          	jalr	-1968(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006cf8:	00003517          	auipc	a0,0x3
    80006cfc:	aa050513          	addi	a0,a0,-1376 # 80009798 <syscalls+0x320>
    80006d00:	ffffa097          	auipc	ra,0xffffa
    80006d04:	840080e7          	jalr	-1984(ra) # 80000540 <panic>

0000000080006d08 <virtio_disk_init>:
{
    80006d08:	1101                	addi	sp,sp,-32
    80006d0a:	ec06                	sd	ra,24(sp)
    80006d0c:	e822                	sd	s0,16(sp)
    80006d0e:	e426                	sd	s1,8(sp)
    80006d10:	e04a                	sd	s2,0(sp)
    80006d12:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006d14:	00003597          	auipc	a1,0x3
    80006d18:	a9458593          	addi	a1,a1,-1388 # 800097a8 <syscalls+0x330>
    80006d1c:	0001e517          	auipc	a0,0x1e
    80006d20:	88c50513          	addi	a0,a0,-1908 # 800245a8 <disk+0x128>
    80006d24:	ffffa097          	auipc	ra,0xffffa
    80006d28:	e22080e7          	jalr	-478(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006d2c:	100017b7          	lui	a5,0x10001
    80006d30:	4398                	lw	a4,0(a5)
    80006d32:	2701                	sext.w	a4,a4
    80006d34:	747277b7          	lui	a5,0x74727
    80006d38:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006d3c:	14f71b63          	bne	a4,a5,80006e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006d40:	100017b7          	lui	a5,0x10001
    80006d44:	43dc                	lw	a5,4(a5)
    80006d46:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006d48:	4709                	li	a4,2
    80006d4a:	14e79463          	bne	a5,a4,80006e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006d4e:	100017b7          	lui	a5,0x10001
    80006d52:	479c                	lw	a5,8(a5)
    80006d54:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006d56:	12e79e63          	bne	a5,a4,80006e92 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006d5a:	100017b7          	lui	a5,0x10001
    80006d5e:	47d8                	lw	a4,12(a5)
    80006d60:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006d62:	554d47b7          	lui	a5,0x554d4
    80006d66:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006d6a:	12f71463          	bne	a4,a5,80006e92 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d6e:	100017b7          	lui	a5,0x10001
    80006d72:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d76:	4705                	li	a4,1
    80006d78:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d7a:	470d                	li	a4,3
    80006d7c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006d7e:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006d80:	c7ffe6b7          	lui	a3,0xc7ffe
    80006d84:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fda19f>
    80006d88:	8f75                	and	a4,a4,a3
    80006d8a:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006d8c:	472d                	li	a4,11
    80006d8e:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006d90:	5bbc                	lw	a5,112(a5)
    80006d92:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006d96:	8ba1                	andi	a5,a5,8
    80006d98:	10078563          	beqz	a5,80006ea2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006d9c:	100017b7          	lui	a5,0x10001
    80006da0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006da4:	43fc                	lw	a5,68(a5)
    80006da6:	2781                	sext.w	a5,a5
    80006da8:	10079563          	bnez	a5,80006eb2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006dac:	100017b7          	lui	a5,0x10001
    80006db0:	5bdc                	lw	a5,52(a5)
    80006db2:	2781                	sext.w	a5,a5
  if(max == 0)
    80006db4:	10078763          	beqz	a5,80006ec2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006db8:	471d                	li	a4,7
    80006dba:	10f77c63          	bgeu	a4,a5,80006ed2 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80006dbe:	ffffa097          	auipc	ra,0xffffa
    80006dc2:	d28080e7          	jalr	-728(ra) # 80000ae6 <kalloc>
    80006dc6:	0001d497          	auipc	s1,0x1d
    80006dca:	6ba48493          	addi	s1,s1,1722 # 80024480 <disk>
    80006dce:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006dd0:	ffffa097          	auipc	ra,0xffffa
    80006dd4:	d16080e7          	jalr	-746(ra) # 80000ae6 <kalloc>
    80006dd8:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006dda:	ffffa097          	auipc	ra,0xffffa
    80006dde:	d0c080e7          	jalr	-756(ra) # 80000ae6 <kalloc>
    80006de2:	87aa                	mv	a5,a0
    80006de4:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006de6:	6088                	ld	a0,0(s1)
    80006de8:	cd6d                	beqz	a0,80006ee2 <virtio_disk_init+0x1da>
    80006dea:	0001d717          	auipc	a4,0x1d
    80006dee:	69e73703          	ld	a4,1694(a4) # 80024488 <disk+0x8>
    80006df2:	cb65                	beqz	a4,80006ee2 <virtio_disk_init+0x1da>
    80006df4:	c7fd                	beqz	a5,80006ee2 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006df6:	6605                	lui	a2,0x1
    80006df8:	4581                	li	a1,0
    80006dfa:	ffffa097          	auipc	ra,0xffffa
    80006dfe:	ed8080e7          	jalr	-296(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006e02:	0001d497          	auipc	s1,0x1d
    80006e06:	67e48493          	addi	s1,s1,1662 # 80024480 <disk>
    80006e0a:	6605                	lui	a2,0x1
    80006e0c:	4581                	li	a1,0
    80006e0e:	6488                	ld	a0,8(s1)
    80006e10:	ffffa097          	auipc	ra,0xffffa
    80006e14:	ec2080e7          	jalr	-318(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006e18:	6605                	lui	a2,0x1
    80006e1a:	4581                	li	a1,0
    80006e1c:	6888                	ld	a0,16(s1)
    80006e1e:	ffffa097          	auipc	ra,0xffffa
    80006e22:	eb4080e7          	jalr	-332(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006e26:	100017b7          	lui	a5,0x10001
    80006e2a:	4721                	li	a4,8
    80006e2c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006e2e:	4098                	lw	a4,0(s1)
    80006e30:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006e34:	40d8                	lw	a4,4(s1)
    80006e36:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006e3a:	6498                	ld	a4,8(s1)
    80006e3c:	0007069b          	sext.w	a3,a4
    80006e40:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006e44:	9701                	srai	a4,a4,0x20
    80006e46:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006e4a:	6898                	ld	a4,16(s1)
    80006e4c:	0007069b          	sext.w	a3,a4
    80006e50:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006e54:	9701                	srai	a4,a4,0x20
    80006e56:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006e5a:	4705                	li	a4,1
    80006e5c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80006e5e:	00e48c23          	sb	a4,24(s1)
    80006e62:	00e48ca3          	sb	a4,25(s1)
    80006e66:	00e48d23          	sb	a4,26(s1)
    80006e6a:	00e48da3          	sb	a4,27(s1)
    80006e6e:	00e48e23          	sb	a4,28(s1)
    80006e72:	00e48ea3          	sb	a4,29(s1)
    80006e76:	00e48f23          	sb	a4,30(s1)
    80006e7a:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006e7e:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006e82:	0727a823          	sw	s2,112(a5)
}
    80006e86:	60e2                	ld	ra,24(sp)
    80006e88:	6442                	ld	s0,16(sp)
    80006e8a:	64a2                	ld	s1,8(sp)
    80006e8c:	6902                	ld	s2,0(sp)
    80006e8e:	6105                	addi	sp,sp,32
    80006e90:	8082                	ret
    panic("could not find virtio disk");
    80006e92:	00003517          	auipc	a0,0x3
    80006e96:	92650513          	addi	a0,a0,-1754 # 800097b8 <syscalls+0x340>
    80006e9a:	ffff9097          	auipc	ra,0xffff9
    80006e9e:	6a6080e7          	jalr	1702(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006ea2:	00003517          	auipc	a0,0x3
    80006ea6:	93650513          	addi	a0,a0,-1738 # 800097d8 <syscalls+0x360>
    80006eaa:	ffff9097          	auipc	ra,0xffff9
    80006eae:	696080e7          	jalr	1686(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006eb2:	00003517          	auipc	a0,0x3
    80006eb6:	94650513          	addi	a0,a0,-1722 # 800097f8 <syscalls+0x380>
    80006eba:	ffff9097          	auipc	ra,0xffff9
    80006ebe:	686080e7          	jalr	1670(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006ec2:	00003517          	auipc	a0,0x3
    80006ec6:	95650513          	addi	a0,a0,-1706 # 80009818 <syscalls+0x3a0>
    80006eca:	ffff9097          	auipc	ra,0xffff9
    80006ece:	676080e7          	jalr	1654(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006ed2:	00003517          	auipc	a0,0x3
    80006ed6:	96650513          	addi	a0,a0,-1690 # 80009838 <syscalls+0x3c0>
    80006eda:	ffff9097          	auipc	ra,0xffff9
    80006ede:	666080e7          	jalr	1638(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006ee2:	00003517          	auipc	a0,0x3
    80006ee6:	97650513          	addi	a0,a0,-1674 # 80009858 <syscalls+0x3e0>
    80006eea:	ffff9097          	auipc	ra,0xffff9
    80006eee:	656080e7          	jalr	1622(ra) # 80000540 <panic>

0000000080006ef2 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006ef2:	7119                	addi	sp,sp,-128
    80006ef4:	fc86                	sd	ra,120(sp)
    80006ef6:	f8a2                	sd	s0,112(sp)
    80006ef8:	f4a6                	sd	s1,104(sp)
    80006efa:	f0ca                	sd	s2,96(sp)
    80006efc:	ecce                	sd	s3,88(sp)
    80006efe:	e8d2                	sd	s4,80(sp)
    80006f00:	e4d6                	sd	s5,72(sp)
    80006f02:	e0da                	sd	s6,64(sp)
    80006f04:	fc5e                	sd	s7,56(sp)
    80006f06:	f862                	sd	s8,48(sp)
    80006f08:	f466                	sd	s9,40(sp)
    80006f0a:	f06a                	sd	s10,32(sp)
    80006f0c:	ec6e                	sd	s11,24(sp)
    80006f0e:	0100                	addi	s0,sp,128
    80006f10:	8aaa                	mv	s5,a0
    80006f12:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006f14:	00c52d03          	lw	s10,12(a0)
    80006f18:	001d1d1b          	slliw	s10,s10,0x1
    80006f1c:	1d02                	slli	s10,s10,0x20
    80006f1e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006f22:	0001d517          	auipc	a0,0x1d
    80006f26:	68650513          	addi	a0,a0,1670 # 800245a8 <disk+0x128>
    80006f2a:	ffffa097          	auipc	ra,0xffffa
    80006f2e:	cac080e7          	jalr	-852(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006f32:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006f34:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006f36:	0001db97          	auipc	s7,0x1d
    80006f3a:	54ab8b93          	addi	s7,s7,1354 # 80024480 <disk>
  for(int i = 0; i < 3; i++){
    80006f3e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006f40:	0001dc97          	auipc	s9,0x1d
    80006f44:	668c8c93          	addi	s9,s9,1640 # 800245a8 <disk+0x128>
    80006f48:	a08d                	j	80006faa <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    80006f4a:	00fb8733          	add	a4,s7,a5
    80006f4e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006f52:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006f54:	0207c563          	bltz	a5,80006f7e <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006f58:	2905                	addiw	s2,s2,1
    80006f5a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    80006f5c:	05690c63          	beq	s2,s6,80006fb4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006f60:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006f62:	0001d717          	auipc	a4,0x1d
    80006f66:	51e70713          	addi	a4,a4,1310 # 80024480 <disk>
    80006f6a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    80006f6c:	01874683          	lbu	a3,24(a4)
    80006f70:	fee9                	bnez	a3,80006f4a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006f72:	2785                	addiw	a5,a5,1
    80006f74:	0705                	addi	a4,a4,1
    80006f76:	fe979be3          	bne	a5,s1,80006f6c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006f7a:	57fd                	li	a5,-1
    80006f7c:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    80006f7e:	01205d63          	blez	s2,80006f98 <virtio_disk_rw+0xa6>
    80006f82:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    80006f84:	000a2503          	lw	a0,0(s4)
    80006f88:	00000097          	auipc	ra,0x0
    80006f8c:	cfe080e7          	jalr	-770(ra) # 80006c86 <free_desc>
      for(int j = 0; j < i; j++)
    80006f90:	2d85                	addiw	s11,s11,1
    80006f92:	0a11                	addi	s4,s4,4
    80006f94:	ff2d98e3          	bne	s11,s2,80006f84 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006f98:	85e6                	mv	a1,s9
    80006f9a:	0001d517          	auipc	a0,0x1d
    80006f9e:	4fe50513          	addi	a0,a0,1278 # 80024498 <disk+0x18>
    80006fa2:	ffffc097          	auipc	ra,0xffffc
    80006fa6:	cd4080e7          	jalr	-812(ra) # 80002c76 <sleep>
  for(int i = 0; i < 3; i++){
    80006faa:	f8040a13          	addi	s4,s0,-128
{
    80006fae:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006fb0:	894e                	mv	s2,s3
    80006fb2:	b77d                	j	80006f60 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fb4:	f8042503          	lw	a0,-128(s0)
    80006fb8:	00a50713          	addi	a4,a0,10
    80006fbc:	0712                	slli	a4,a4,0x4

  if(write)
    80006fbe:	0001d797          	auipc	a5,0x1d
    80006fc2:	4c278793          	addi	a5,a5,1218 # 80024480 <disk>
    80006fc6:	00e786b3          	add	a3,a5,a4
    80006fca:	01803633          	snez	a2,s8
    80006fce:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006fd0:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006fd4:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fd8:	f6070613          	addi	a2,a4,-160
    80006fdc:	6394                	ld	a3,0(a5)
    80006fde:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006fe0:	00870593          	addi	a1,a4,8
    80006fe4:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006fe6:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006fe8:	0007b803          	ld	a6,0(a5)
    80006fec:	9642                	add	a2,a2,a6
    80006fee:	46c1                	li	a3,16
    80006ff0:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006ff2:	4585                	li	a1,1
    80006ff4:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006ff8:	f8442683          	lw	a3,-124(s0)
    80006ffc:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80007000:	0692                	slli	a3,a3,0x4
    80007002:	9836                	add	a6,a6,a3
    80007004:	058a8613          	addi	a2,s5,88
    80007008:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000700c:	0007b803          	ld	a6,0(a5)
    80007010:	96c2                	add	a3,a3,a6
    80007012:	40000613          	li	a2,1024
    80007016:	c690                	sw	a2,8(a3)
  if(write)
    80007018:	001c3613          	seqz	a2,s8
    8000701c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80007020:	00166613          	ori	a2,a2,1
    80007024:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80007028:	f8842603          	lw	a2,-120(s0)
    8000702c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80007030:	00250693          	addi	a3,a0,2
    80007034:	0692                	slli	a3,a3,0x4
    80007036:	96be                	add	a3,a3,a5
    80007038:	58fd                	li	a7,-1
    8000703a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000703e:	0612                	slli	a2,a2,0x4
    80007040:	9832                	add	a6,a6,a2
    80007042:	f9070713          	addi	a4,a4,-112
    80007046:	973e                	add	a4,a4,a5
    80007048:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000704c:	6398                	ld	a4,0(a5)
    8000704e:	9732                	add	a4,a4,a2
    80007050:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80007052:	4609                	li	a2,2
    80007054:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80007058:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000705c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80007060:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80007064:	6794                	ld	a3,8(a5)
    80007066:	0026d703          	lhu	a4,2(a3)
    8000706a:	8b1d                	andi	a4,a4,7
    8000706c:	0706                	slli	a4,a4,0x1
    8000706e:	96ba                	add	a3,a3,a4
    80007070:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    80007074:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80007078:	6798                	ld	a4,8(a5)
    8000707a:	00275783          	lhu	a5,2(a4)
    8000707e:	2785                	addiw	a5,a5,1
    80007080:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80007084:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80007088:	100017b7          	lui	a5,0x10001
    8000708c:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80007090:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    80007094:	0001d917          	auipc	s2,0x1d
    80007098:	51490913          	addi	s2,s2,1300 # 800245a8 <disk+0x128>
  while(b->disk == 1) {
    8000709c:	4485                	li	s1,1
    8000709e:	00b79c63          	bne	a5,a1,800070b6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800070a2:	85ca                	mv	a1,s2
    800070a4:	8556                	mv	a0,s5
    800070a6:	ffffc097          	auipc	ra,0xffffc
    800070aa:	bd0080e7          	jalr	-1072(ra) # 80002c76 <sleep>
  while(b->disk == 1) {
    800070ae:	004aa783          	lw	a5,4(s5)
    800070b2:	fe9788e3          	beq	a5,s1,800070a2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800070b6:	f8042903          	lw	s2,-128(s0)
    800070ba:	00290713          	addi	a4,s2,2
    800070be:	0712                	slli	a4,a4,0x4
    800070c0:	0001d797          	auipc	a5,0x1d
    800070c4:	3c078793          	addi	a5,a5,960 # 80024480 <disk>
    800070c8:	97ba                	add	a5,a5,a4
    800070ca:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800070ce:	0001d997          	auipc	s3,0x1d
    800070d2:	3b298993          	addi	s3,s3,946 # 80024480 <disk>
    800070d6:	00491713          	slli	a4,s2,0x4
    800070da:	0009b783          	ld	a5,0(s3)
    800070de:	97ba                	add	a5,a5,a4
    800070e0:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    800070e4:	854a                	mv	a0,s2
    800070e6:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800070ea:	00000097          	auipc	ra,0x0
    800070ee:	b9c080e7          	jalr	-1124(ra) # 80006c86 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800070f2:	8885                	andi	s1,s1,1
    800070f4:	f0ed                	bnez	s1,800070d6 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800070f6:	0001d517          	auipc	a0,0x1d
    800070fa:	4b250513          	addi	a0,a0,1202 # 800245a8 <disk+0x128>
    800070fe:	ffffa097          	auipc	ra,0xffffa
    80007102:	b8c080e7          	jalr	-1140(ra) # 80000c8a <release>
}
    80007106:	70e6                	ld	ra,120(sp)
    80007108:	7446                	ld	s0,112(sp)
    8000710a:	74a6                	ld	s1,104(sp)
    8000710c:	7906                	ld	s2,96(sp)
    8000710e:	69e6                	ld	s3,88(sp)
    80007110:	6a46                	ld	s4,80(sp)
    80007112:	6aa6                	ld	s5,72(sp)
    80007114:	6b06                	ld	s6,64(sp)
    80007116:	7be2                	ld	s7,56(sp)
    80007118:	7c42                	ld	s8,48(sp)
    8000711a:	7ca2                	ld	s9,40(sp)
    8000711c:	7d02                	ld	s10,32(sp)
    8000711e:	6de2                	ld	s11,24(sp)
    80007120:	6109                	addi	sp,sp,128
    80007122:	8082                	ret

0000000080007124 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80007124:	1101                	addi	sp,sp,-32
    80007126:	ec06                	sd	ra,24(sp)
    80007128:	e822                	sd	s0,16(sp)
    8000712a:	e426                	sd	s1,8(sp)
    8000712c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000712e:	0001d497          	auipc	s1,0x1d
    80007132:	35248493          	addi	s1,s1,850 # 80024480 <disk>
    80007136:	0001d517          	auipc	a0,0x1d
    8000713a:	47250513          	addi	a0,a0,1138 # 800245a8 <disk+0x128>
    8000713e:	ffffa097          	auipc	ra,0xffffa
    80007142:	a98080e7          	jalr	-1384(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80007146:	10001737          	lui	a4,0x10001
    8000714a:	533c                	lw	a5,96(a4)
    8000714c:	8b8d                	andi	a5,a5,3
    8000714e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80007150:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80007154:	689c                	ld	a5,16(s1)
    80007156:	0204d703          	lhu	a4,32(s1)
    8000715a:	0027d783          	lhu	a5,2(a5)
    8000715e:	04f70863          	beq	a4,a5,800071ae <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80007162:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80007166:	6898                	ld	a4,16(s1)
    80007168:	0204d783          	lhu	a5,32(s1)
    8000716c:	8b9d                	andi	a5,a5,7
    8000716e:	078e                	slli	a5,a5,0x3
    80007170:	97ba                	add	a5,a5,a4
    80007172:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80007174:	00278713          	addi	a4,a5,2
    80007178:	0712                	slli	a4,a4,0x4
    8000717a:	9726                	add	a4,a4,s1
    8000717c:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80007180:	e721                	bnez	a4,800071c8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80007182:	0789                	addi	a5,a5,2
    80007184:	0792                	slli	a5,a5,0x4
    80007186:	97a6                	add	a5,a5,s1
    80007188:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    8000718a:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000718e:	ffffc097          	auipc	ra,0xffffc
    80007192:	b4c080e7          	jalr	-1204(ra) # 80002cda <wakeup>

    disk.used_idx += 1;
    80007196:	0204d783          	lhu	a5,32(s1)
    8000719a:	2785                	addiw	a5,a5,1
    8000719c:	17c2                	slli	a5,a5,0x30
    8000719e:	93c1                	srli	a5,a5,0x30
    800071a0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800071a4:	6898                	ld	a4,16(s1)
    800071a6:	00275703          	lhu	a4,2(a4)
    800071aa:	faf71ce3          	bne	a4,a5,80007162 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800071ae:	0001d517          	auipc	a0,0x1d
    800071b2:	3fa50513          	addi	a0,a0,1018 # 800245a8 <disk+0x128>
    800071b6:	ffffa097          	auipc	ra,0xffffa
    800071ba:	ad4080e7          	jalr	-1324(ra) # 80000c8a <release>
}
    800071be:	60e2                	ld	ra,24(sp)
    800071c0:	6442                	ld	s0,16(sp)
    800071c2:	64a2                	ld	s1,8(sp)
    800071c4:	6105                	addi	sp,sp,32
    800071c6:	8082                	ret
      panic("virtio_disk_intr status");
    800071c8:	00002517          	auipc	a0,0x2
    800071cc:	6a850513          	addi	a0,a0,1704 # 80009870 <syscalls+0x3f8>
    800071d0:	ffff9097          	auipc	ra,0xffff9
    800071d4:	370080e7          	jalr	880(ra) # 80000540 <panic>
	...

0000000080008000 <_trampoline>:
    80008000:	14051073          	csrw	sscratch,a0
    80008004:	02000537          	lui	a0,0x2000
    80008008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000800a:	0536                	slli	a0,a0,0xd
    8000800c:	02153423          	sd	ra,40(a0)
    80008010:	02253823          	sd	sp,48(a0)
    80008014:	02353c23          	sd	gp,56(a0)
    80008018:	04453023          	sd	tp,64(a0)
    8000801c:	04553423          	sd	t0,72(a0)
    80008020:	04653823          	sd	t1,80(a0)
    80008024:	04753c23          	sd	t2,88(a0)
    80008028:	f120                	sd	s0,96(a0)
    8000802a:	f524                	sd	s1,104(a0)
    8000802c:	fd2c                	sd	a1,120(a0)
    8000802e:	e150                	sd	a2,128(a0)
    80008030:	e554                	sd	a3,136(a0)
    80008032:	e958                	sd	a4,144(a0)
    80008034:	ed5c                	sd	a5,152(a0)
    80008036:	0b053023          	sd	a6,160(a0)
    8000803a:	0b153423          	sd	a7,168(a0)
    8000803e:	0b253823          	sd	s2,176(a0)
    80008042:	0b353c23          	sd	s3,184(a0)
    80008046:	0d453023          	sd	s4,192(a0)
    8000804a:	0d553423          	sd	s5,200(a0)
    8000804e:	0d653823          	sd	s6,208(a0)
    80008052:	0d753c23          	sd	s7,216(a0)
    80008056:	0f853023          	sd	s8,224(a0)
    8000805a:	0f953423          	sd	s9,232(a0)
    8000805e:	0fa53823          	sd	s10,240(a0)
    80008062:	0fb53c23          	sd	s11,248(a0)
    80008066:	11c53023          	sd	t3,256(a0)
    8000806a:	11d53423          	sd	t4,264(a0)
    8000806e:	11e53823          	sd	t5,272(a0)
    80008072:	11f53c23          	sd	t6,280(a0)
    80008076:	140022f3          	csrr	t0,sscratch
    8000807a:	06553823          	sd	t0,112(a0)
    8000807e:	00853103          	ld	sp,8(a0)
    80008082:	02053203          	ld	tp,32(a0)
    80008086:	01053283          	ld	t0,16(a0)
    8000808a:	00053303          	ld	t1,0(a0)
    8000808e:	12000073          	sfence.vma
    80008092:	18031073          	csrw	satp,t1
    80008096:	12000073          	sfence.vma
    8000809a:	8282                	jr	t0

000000008000809c <userret>:
    8000809c:	12000073          	sfence.vma
    800080a0:	18051073          	csrw	satp,a0
    800080a4:	12000073          	sfence.vma
    800080a8:	02000537          	lui	a0,0x2000
    800080ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800080ae:	0536                	slli	a0,a0,0xd
    800080b0:	02853083          	ld	ra,40(a0)
    800080b4:	03053103          	ld	sp,48(a0)
    800080b8:	03853183          	ld	gp,56(a0)
    800080bc:	04053203          	ld	tp,64(a0)
    800080c0:	04853283          	ld	t0,72(a0)
    800080c4:	05053303          	ld	t1,80(a0)
    800080c8:	05853383          	ld	t2,88(a0)
    800080cc:	7120                	ld	s0,96(a0)
    800080ce:	7524                	ld	s1,104(a0)
    800080d0:	7d2c                	ld	a1,120(a0)
    800080d2:	6150                	ld	a2,128(a0)
    800080d4:	6554                	ld	a3,136(a0)
    800080d6:	6958                	ld	a4,144(a0)
    800080d8:	6d5c                	ld	a5,152(a0)
    800080da:	0a053803          	ld	a6,160(a0)
    800080de:	0a853883          	ld	a7,168(a0)
    800080e2:	0b053903          	ld	s2,176(a0)
    800080e6:	0b853983          	ld	s3,184(a0)
    800080ea:	0c053a03          	ld	s4,192(a0)
    800080ee:	0c853a83          	ld	s5,200(a0)
    800080f2:	0d053b03          	ld	s6,208(a0)
    800080f6:	0d853b83          	ld	s7,216(a0)
    800080fa:	0e053c03          	ld	s8,224(a0)
    800080fe:	0e853c83          	ld	s9,232(a0)
    80008102:	0f053d03          	ld	s10,240(a0)
    80008106:	0f853d83          	ld	s11,248(a0)
    8000810a:	10053e03          	ld	t3,256(a0)
    8000810e:	10853e83          	ld	t4,264(a0)
    80008112:	11053f03          	ld	t5,272(a0)
    80008116:	11853f83          	ld	t6,280(a0)
    8000811a:	7928                	ld	a0,112(a0)
    8000811c:	10200073          	sret
	...
