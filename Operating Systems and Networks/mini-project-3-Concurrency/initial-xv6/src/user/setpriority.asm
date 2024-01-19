
user/_setpriority:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user.h"
#include "kernel/fcntl.h"

int main(int argc, char** argv){
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	e04a                	sd	s2,0(sp)
   a:	1000                	addi	s0,sp,32
    if(argc < 3 || argc > 3){
   c:	478d                	li	a5,3
   e:	00f50f63          	beq	a0,a5,2c <main+0x2c>
        printf("Incorrect input format. Expected format -  setpriority pid priority\n");
  12:	00001517          	auipc	a0,0x1
  16:	81e50513          	addi	a0,a0,-2018 # 830 <malloc+0xf4>
  1a:	00000097          	auipc	ra,0x0
  1e:	66a080e7          	jalr	1642(ra) # 684 <printf>
        exit(1);
  22:	4505                	li	a0,1
  24:	00000097          	auipc	ra,0x0
  28:	2ce080e7          	jalr	718(ra) # 2f2 <exit>
  2c:	84ae                	mv	s1,a1
    }
    int pid = atoi(argv[1]);
  2e:	6588                	ld	a0,8(a1)
  30:	00000097          	auipc	ra,0x0
  34:	1c8080e7          	jalr	456(ra) # 1f8 <atoi>
  38:	892a                	mv	s2,a0
    int priority = atoi(argv[2]);
  3a:	6888                	ld	a0,16(s1)
  3c:	00000097          	auipc	ra,0x0
  40:	1bc080e7          	jalr	444(ra) # 1f8 <atoi>
  44:	85aa                	mv	a1,a0
    printf("%d\n",  setpriority(pid, priority));
  46:	854a                	mv	a0,s2
  48:	00000097          	auipc	ra,0x0
  4c:	35a080e7          	jalr	858(ra) # 3a2 <setpriority>
  50:	85aa                	mv	a1,a0
  52:	00001517          	auipc	a0,0x1
  56:	82650513          	addi	a0,a0,-2010 # 878 <malloc+0x13c>
  5a:	00000097          	auipc	ra,0x0
  5e:	62a080e7          	jalr	1578(ra) # 684 <printf>
    exit(0);
  62:	4501                	li	a0,0
  64:	00000097          	auipc	ra,0x0
  68:	28e080e7          	jalr	654(ra) # 2f2 <exit>

000000000000006c <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  6c:	1141                	addi	sp,sp,-16
  6e:	e406                	sd	ra,8(sp)
  70:	e022                	sd	s0,0(sp)
  72:	0800                	addi	s0,sp,16
  extern int main();
  main();
  74:	00000097          	auipc	ra,0x0
  78:	f8c080e7          	jalr	-116(ra) # 0 <main>
  exit(0);
  7c:	4501                	li	a0,0
  7e:	00000097          	auipc	ra,0x0
  82:	274080e7          	jalr	628(ra) # 2f2 <exit>

0000000000000086 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  86:	1141                	addi	sp,sp,-16
  88:	e422                	sd	s0,8(sp)
  8a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  8c:	87aa                	mv	a5,a0
  8e:	0585                	addi	a1,a1,1
  90:	0785                	addi	a5,a5,1
  92:	fff5c703          	lbu	a4,-1(a1)
  96:	fee78fa3          	sb	a4,-1(a5)
  9a:	fb75                	bnez	a4,8e <strcpy+0x8>
    ;
  return os;
}
  9c:	6422                	ld	s0,8(sp)
  9e:	0141                	addi	sp,sp,16
  a0:	8082                	ret

00000000000000a2 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  a2:	1141                	addi	sp,sp,-16
  a4:	e422                	sd	s0,8(sp)
  a6:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  a8:	00054783          	lbu	a5,0(a0)
  ac:	cb91                	beqz	a5,c0 <strcmp+0x1e>
  ae:	0005c703          	lbu	a4,0(a1)
  b2:	00f71763          	bne	a4,a5,c0 <strcmp+0x1e>
    p++, q++;
  b6:	0505                	addi	a0,a0,1
  b8:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  ba:	00054783          	lbu	a5,0(a0)
  be:	fbe5                	bnez	a5,ae <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  c0:	0005c503          	lbu	a0,0(a1)
}
  c4:	40a7853b          	subw	a0,a5,a0
  c8:	6422                	ld	s0,8(sp)
  ca:	0141                	addi	sp,sp,16
  cc:	8082                	ret

00000000000000ce <strlen>:

uint
strlen(const char *s)
{
  ce:	1141                	addi	sp,sp,-16
  d0:	e422                	sd	s0,8(sp)
  d2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  d4:	00054783          	lbu	a5,0(a0)
  d8:	cf91                	beqz	a5,f4 <strlen+0x26>
  da:	0505                	addi	a0,a0,1
  dc:	87aa                	mv	a5,a0
  de:	4685                	li	a3,1
  e0:	9e89                	subw	a3,a3,a0
  e2:	00f6853b          	addw	a0,a3,a5
  e6:	0785                	addi	a5,a5,1
  e8:	fff7c703          	lbu	a4,-1(a5)
  ec:	fb7d                	bnez	a4,e2 <strlen+0x14>
    ;
  return n;
}
  ee:	6422                	ld	s0,8(sp)
  f0:	0141                	addi	sp,sp,16
  f2:	8082                	ret
  for(n = 0; s[n]; n++)
  f4:	4501                	li	a0,0
  f6:	bfe5                	j	ee <strlen+0x20>

00000000000000f8 <memset>:

void*
memset(void *dst, int c, uint n)
{
  f8:	1141                	addi	sp,sp,-16
  fa:	e422                	sd	s0,8(sp)
  fc:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  fe:	ca19                	beqz	a2,114 <memset+0x1c>
 100:	87aa                	mv	a5,a0
 102:	1602                	slli	a2,a2,0x20
 104:	9201                	srli	a2,a2,0x20
 106:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 10a:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 10e:	0785                	addi	a5,a5,1
 110:	fee79de3          	bne	a5,a4,10a <memset+0x12>
  }
  return dst;
}
 114:	6422                	ld	s0,8(sp)
 116:	0141                	addi	sp,sp,16
 118:	8082                	ret

000000000000011a <strchr>:

char*
strchr(const char *s, char c)
{
 11a:	1141                	addi	sp,sp,-16
 11c:	e422                	sd	s0,8(sp)
 11e:	0800                	addi	s0,sp,16
  for(; *s; s++)
 120:	00054783          	lbu	a5,0(a0)
 124:	cb99                	beqz	a5,13a <strchr+0x20>
    if(*s == c)
 126:	00f58763          	beq	a1,a5,134 <strchr+0x1a>
  for(; *s; s++)
 12a:	0505                	addi	a0,a0,1
 12c:	00054783          	lbu	a5,0(a0)
 130:	fbfd                	bnez	a5,126 <strchr+0xc>
      return (char*)s;
  return 0;
 132:	4501                	li	a0,0
}
 134:	6422                	ld	s0,8(sp)
 136:	0141                	addi	sp,sp,16
 138:	8082                	ret
  return 0;
 13a:	4501                	li	a0,0
 13c:	bfe5                	j	134 <strchr+0x1a>

000000000000013e <gets>:

char*
gets(char *buf, int max)
{
 13e:	711d                	addi	sp,sp,-96
 140:	ec86                	sd	ra,88(sp)
 142:	e8a2                	sd	s0,80(sp)
 144:	e4a6                	sd	s1,72(sp)
 146:	e0ca                	sd	s2,64(sp)
 148:	fc4e                	sd	s3,56(sp)
 14a:	f852                	sd	s4,48(sp)
 14c:	f456                	sd	s5,40(sp)
 14e:	f05a                	sd	s6,32(sp)
 150:	ec5e                	sd	s7,24(sp)
 152:	1080                	addi	s0,sp,96
 154:	8baa                	mv	s7,a0
 156:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 158:	892a                	mv	s2,a0
 15a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 15c:	4aa9                	li	s5,10
 15e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 160:	89a6                	mv	s3,s1
 162:	2485                	addiw	s1,s1,1
 164:	0344d863          	bge	s1,s4,194 <gets+0x56>
    cc = read(0, &c, 1);
 168:	4605                	li	a2,1
 16a:	faf40593          	addi	a1,s0,-81
 16e:	4501                	li	a0,0
 170:	00000097          	auipc	ra,0x0
 174:	19a080e7          	jalr	410(ra) # 30a <read>
    if(cc < 1)
 178:	00a05e63          	blez	a0,194 <gets+0x56>
    buf[i++] = c;
 17c:	faf44783          	lbu	a5,-81(s0)
 180:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 184:	01578763          	beq	a5,s5,192 <gets+0x54>
 188:	0905                	addi	s2,s2,1
 18a:	fd679be3          	bne	a5,s6,160 <gets+0x22>
  for(i=0; i+1 < max; ){
 18e:	89a6                	mv	s3,s1
 190:	a011                	j	194 <gets+0x56>
 192:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 194:	99de                	add	s3,s3,s7
 196:	00098023          	sb	zero,0(s3)
  return buf;
}
 19a:	855e                	mv	a0,s7
 19c:	60e6                	ld	ra,88(sp)
 19e:	6446                	ld	s0,80(sp)
 1a0:	64a6                	ld	s1,72(sp)
 1a2:	6906                	ld	s2,64(sp)
 1a4:	79e2                	ld	s3,56(sp)
 1a6:	7a42                	ld	s4,48(sp)
 1a8:	7aa2                	ld	s5,40(sp)
 1aa:	7b02                	ld	s6,32(sp)
 1ac:	6be2                	ld	s7,24(sp)
 1ae:	6125                	addi	sp,sp,96
 1b0:	8082                	ret

00000000000001b2 <stat>:

int
stat(const char *n, struct stat *st)
{
 1b2:	1101                	addi	sp,sp,-32
 1b4:	ec06                	sd	ra,24(sp)
 1b6:	e822                	sd	s0,16(sp)
 1b8:	e426                	sd	s1,8(sp)
 1ba:	e04a                	sd	s2,0(sp)
 1bc:	1000                	addi	s0,sp,32
 1be:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1c0:	4581                	li	a1,0
 1c2:	00000097          	auipc	ra,0x0
 1c6:	170080e7          	jalr	368(ra) # 332 <open>
  if(fd < 0)
 1ca:	02054563          	bltz	a0,1f4 <stat+0x42>
 1ce:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1d0:	85ca                	mv	a1,s2
 1d2:	00000097          	auipc	ra,0x0
 1d6:	178080e7          	jalr	376(ra) # 34a <fstat>
 1da:	892a                	mv	s2,a0
  close(fd);
 1dc:	8526                	mv	a0,s1
 1de:	00000097          	auipc	ra,0x0
 1e2:	13c080e7          	jalr	316(ra) # 31a <close>
  return r;
}
 1e6:	854a                	mv	a0,s2
 1e8:	60e2                	ld	ra,24(sp)
 1ea:	6442                	ld	s0,16(sp)
 1ec:	64a2                	ld	s1,8(sp)
 1ee:	6902                	ld	s2,0(sp)
 1f0:	6105                	addi	sp,sp,32
 1f2:	8082                	ret
    return -1;
 1f4:	597d                	li	s2,-1
 1f6:	bfc5                	j	1e6 <stat+0x34>

00000000000001f8 <atoi>:

int
atoi(const char *s)
{
 1f8:	1141                	addi	sp,sp,-16
 1fa:	e422                	sd	s0,8(sp)
 1fc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1fe:	00054683          	lbu	a3,0(a0)
 202:	fd06879b          	addiw	a5,a3,-48
 206:	0ff7f793          	zext.b	a5,a5
 20a:	4625                	li	a2,9
 20c:	02f66863          	bltu	a2,a5,23c <atoi+0x44>
 210:	872a                	mv	a4,a0
  n = 0;
 212:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 214:	0705                	addi	a4,a4,1
 216:	0025179b          	slliw	a5,a0,0x2
 21a:	9fa9                	addw	a5,a5,a0
 21c:	0017979b          	slliw	a5,a5,0x1
 220:	9fb5                	addw	a5,a5,a3
 222:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 226:	00074683          	lbu	a3,0(a4)
 22a:	fd06879b          	addiw	a5,a3,-48
 22e:	0ff7f793          	zext.b	a5,a5
 232:	fef671e3          	bgeu	a2,a5,214 <atoi+0x1c>
  return n;
}
 236:	6422                	ld	s0,8(sp)
 238:	0141                	addi	sp,sp,16
 23a:	8082                	ret
  n = 0;
 23c:	4501                	li	a0,0
 23e:	bfe5                	j	236 <atoi+0x3e>

0000000000000240 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 240:	1141                	addi	sp,sp,-16
 242:	e422                	sd	s0,8(sp)
 244:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 246:	02b57463          	bgeu	a0,a1,26e <memmove+0x2e>
    while(n-- > 0)
 24a:	00c05f63          	blez	a2,268 <memmove+0x28>
 24e:	1602                	slli	a2,a2,0x20
 250:	9201                	srli	a2,a2,0x20
 252:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 256:	872a                	mv	a4,a0
      *dst++ = *src++;
 258:	0585                	addi	a1,a1,1
 25a:	0705                	addi	a4,a4,1
 25c:	fff5c683          	lbu	a3,-1(a1)
 260:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 264:	fee79ae3          	bne	a5,a4,258 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 268:	6422                	ld	s0,8(sp)
 26a:	0141                	addi	sp,sp,16
 26c:	8082                	ret
    dst += n;
 26e:	00c50733          	add	a4,a0,a2
    src += n;
 272:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 274:	fec05ae3          	blez	a2,268 <memmove+0x28>
 278:	fff6079b          	addiw	a5,a2,-1
 27c:	1782                	slli	a5,a5,0x20
 27e:	9381                	srli	a5,a5,0x20
 280:	fff7c793          	not	a5,a5
 284:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 286:	15fd                	addi	a1,a1,-1
 288:	177d                	addi	a4,a4,-1
 28a:	0005c683          	lbu	a3,0(a1)
 28e:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 292:	fee79ae3          	bne	a5,a4,286 <memmove+0x46>
 296:	bfc9                	j	268 <memmove+0x28>

0000000000000298 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 298:	1141                	addi	sp,sp,-16
 29a:	e422                	sd	s0,8(sp)
 29c:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 29e:	ca05                	beqz	a2,2ce <memcmp+0x36>
 2a0:	fff6069b          	addiw	a3,a2,-1
 2a4:	1682                	slli	a3,a3,0x20
 2a6:	9281                	srli	a3,a3,0x20
 2a8:	0685                	addi	a3,a3,1
 2aa:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ac:	00054783          	lbu	a5,0(a0)
 2b0:	0005c703          	lbu	a4,0(a1)
 2b4:	00e79863          	bne	a5,a4,2c4 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2b8:	0505                	addi	a0,a0,1
    p2++;
 2ba:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2bc:	fed518e3          	bne	a0,a3,2ac <memcmp+0x14>
  }
  return 0;
 2c0:	4501                	li	a0,0
 2c2:	a019                	j	2c8 <memcmp+0x30>
      return *p1 - *p2;
 2c4:	40e7853b          	subw	a0,a5,a4
}
 2c8:	6422                	ld	s0,8(sp)
 2ca:	0141                	addi	sp,sp,16
 2cc:	8082                	ret
  return 0;
 2ce:	4501                	li	a0,0
 2d0:	bfe5                	j	2c8 <memcmp+0x30>

00000000000002d2 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2d2:	1141                	addi	sp,sp,-16
 2d4:	e406                	sd	ra,8(sp)
 2d6:	e022                	sd	s0,0(sp)
 2d8:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2da:	00000097          	auipc	ra,0x0
 2de:	f66080e7          	jalr	-154(ra) # 240 <memmove>
}
 2e2:	60a2                	ld	ra,8(sp)
 2e4:	6402                	ld	s0,0(sp)
 2e6:	0141                	addi	sp,sp,16
 2e8:	8082                	ret

00000000000002ea <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2ea:	4885                	li	a7,1
 ecall
 2ec:	00000073          	ecall
 ret
 2f0:	8082                	ret

00000000000002f2 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2f2:	4889                	li	a7,2
 ecall
 2f4:	00000073          	ecall
 ret
 2f8:	8082                	ret

00000000000002fa <wait>:
.global wait
wait:
 li a7, SYS_wait
 2fa:	488d                	li	a7,3
 ecall
 2fc:	00000073          	ecall
 ret
 300:	8082                	ret

0000000000000302 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 302:	4891                	li	a7,4
 ecall
 304:	00000073          	ecall
 ret
 308:	8082                	ret

000000000000030a <read>:
.global read
read:
 li a7, SYS_read
 30a:	4895                	li	a7,5
 ecall
 30c:	00000073          	ecall
 ret
 310:	8082                	ret

0000000000000312 <write>:
.global write
write:
 li a7, SYS_write
 312:	48c1                	li	a7,16
 ecall
 314:	00000073          	ecall
 ret
 318:	8082                	ret

000000000000031a <close>:
.global close
close:
 li a7, SYS_close
 31a:	48d5                	li	a7,21
 ecall
 31c:	00000073          	ecall
 ret
 320:	8082                	ret

0000000000000322 <kill>:
.global kill
kill:
 li a7, SYS_kill
 322:	4899                	li	a7,6
 ecall
 324:	00000073          	ecall
 ret
 328:	8082                	ret

000000000000032a <exec>:
.global exec
exec:
 li a7, SYS_exec
 32a:	489d                	li	a7,7
 ecall
 32c:	00000073          	ecall
 ret
 330:	8082                	ret

0000000000000332 <open>:
.global open
open:
 li a7, SYS_open
 332:	48bd                	li	a7,15
 ecall
 334:	00000073          	ecall
 ret
 338:	8082                	ret

000000000000033a <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 33a:	48c5                	li	a7,17
 ecall
 33c:	00000073          	ecall
 ret
 340:	8082                	ret

0000000000000342 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 342:	48c9                	li	a7,18
 ecall
 344:	00000073          	ecall
 ret
 348:	8082                	ret

000000000000034a <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 34a:	48a1                	li	a7,8
 ecall
 34c:	00000073          	ecall
 ret
 350:	8082                	ret

0000000000000352 <link>:
.global link
link:
 li a7, SYS_link
 352:	48cd                	li	a7,19
 ecall
 354:	00000073          	ecall
 ret
 358:	8082                	ret

000000000000035a <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 35a:	48d1                	li	a7,20
 ecall
 35c:	00000073          	ecall
 ret
 360:	8082                	ret

0000000000000362 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 362:	48a5                	li	a7,9
 ecall
 364:	00000073          	ecall
 ret
 368:	8082                	ret

000000000000036a <dup>:
.global dup
dup:
 li a7, SYS_dup
 36a:	48a9                	li	a7,10
 ecall
 36c:	00000073          	ecall
 ret
 370:	8082                	ret

0000000000000372 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 372:	48ad                	li	a7,11
 ecall
 374:	00000073          	ecall
 ret
 378:	8082                	ret

000000000000037a <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 37a:	48b1                	li	a7,12
 ecall
 37c:	00000073          	ecall
 ret
 380:	8082                	ret

0000000000000382 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 382:	48b5                	li	a7,13
 ecall
 384:	00000073          	ecall
 ret
 388:	8082                	ret

000000000000038a <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 38a:	48b9                	li	a7,14
 ecall
 38c:	00000073          	ecall
 ret
 390:	8082                	ret

0000000000000392 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 392:	48d9                	li	a7,22
 ecall
 394:	00000073          	ecall
 ret
 398:	8082                	ret

000000000000039a <getreadcount>:
.global getreadcount
getreadcount:
 li a7, SYS_getreadcount
 39a:	48dd                	li	a7,23
 ecall
 39c:	00000073          	ecall
 ret
 3a0:	8082                	ret

00000000000003a2 <setpriority>:
.global setpriority
setpriority:
 li a7, SYS_setpriority
 3a2:	48e1                	li	a7,24
 ecall
 3a4:	00000073          	ecall
 ret
 3a8:	8082                	ret

00000000000003aa <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3aa:	1101                	addi	sp,sp,-32
 3ac:	ec06                	sd	ra,24(sp)
 3ae:	e822                	sd	s0,16(sp)
 3b0:	1000                	addi	s0,sp,32
 3b2:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3b6:	4605                	li	a2,1
 3b8:	fef40593          	addi	a1,s0,-17
 3bc:	00000097          	auipc	ra,0x0
 3c0:	f56080e7          	jalr	-170(ra) # 312 <write>
}
 3c4:	60e2                	ld	ra,24(sp)
 3c6:	6442                	ld	s0,16(sp)
 3c8:	6105                	addi	sp,sp,32
 3ca:	8082                	ret

00000000000003cc <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3cc:	7139                	addi	sp,sp,-64
 3ce:	fc06                	sd	ra,56(sp)
 3d0:	f822                	sd	s0,48(sp)
 3d2:	f426                	sd	s1,40(sp)
 3d4:	f04a                	sd	s2,32(sp)
 3d6:	ec4e                	sd	s3,24(sp)
 3d8:	0080                	addi	s0,sp,64
 3da:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3dc:	c299                	beqz	a3,3e2 <printint+0x16>
 3de:	0805c963          	bltz	a1,470 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3e2:	2581                	sext.w	a1,a1
  neg = 0;
 3e4:	4881                	li	a7,0
 3e6:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3ea:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3ec:	2601                	sext.w	a2,a2
 3ee:	00000517          	auipc	a0,0x0
 3f2:	4f250513          	addi	a0,a0,1266 # 8e0 <digits>
 3f6:	883a                	mv	a6,a4
 3f8:	2705                	addiw	a4,a4,1
 3fa:	02c5f7bb          	remuw	a5,a1,a2
 3fe:	1782                	slli	a5,a5,0x20
 400:	9381                	srli	a5,a5,0x20
 402:	97aa                	add	a5,a5,a0
 404:	0007c783          	lbu	a5,0(a5)
 408:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 40c:	0005879b          	sext.w	a5,a1
 410:	02c5d5bb          	divuw	a1,a1,a2
 414:	0685                	addi	a3,a3,1
 416:	fec7f0e3          	bgeu	a5,a2,3f6 <printint+0x2a>
  if(neg)
 41a:	00088c63          	beqz	a7,432 <printint+0x66>
    buf[i++] = '-';
 41e:	fd070793          	addi	a5,a4,-48
 422:	00878733          	add	a4,a5,s0
 426:	02d00793          	li	a5,45
 42a:	fef70823          	sb	a5,-16(a4)
 42e:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 432:	02e05863          	blez	a4,462 <printint+0x96>
 436:	fc040793          	addi	a5,s0,-64
 43a:	00e78933          	add	s2,a5,a4
 43e:	fff78993          	addi	s3,a5,-1
 442:	99ba                	add	s3,s3,a4
 444:	377d                	addiw	a4,a4,-1
 446:	1702                	slli	a4,a4,0x20
 448:	9301                	srli	a4,a4,0x20
 44a:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 44e:	fff94583          	lbu	a1,-1(s2)
 452:	8526                	mv	a0,s1
 454:	00000097          	auipc	ra,0x0
 458:	f56080e7          	jalr	-170(ra) # 3aa <putc>
  while(--i >= 0)
 45c:	197d                	addi	s2,s2,-1
 45e:	ff3918e3          	bne	s2,s3,44e <printint+0x82>
}
 462:	70e2                	ld	ra,56(sp)
 464:	7442                	ld	s0,48(sp)
 466:	74a2                	ld	s1,40(sp)
 468:	7902                	ld	s2,32(sp)
 46a:	69e2                	ld	s3,24(sp)
 46c:	6121                	addi	sp,sp,64
 46e:	8082                	ret
    x = -xx;
 470:	40b005bb          	negw	a1,a1
    neg = 1;
 474:	4885                	li	a7,1
    x = -xx;
 476:	bf85                	j	3e6 <printint+0x1a>

0000000000000478 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 478:	7119                	addi	sp,sp,-128
 47a:	fc86                	sd	ra,120(sp)
 47c:	f8a2                	sd	s0,112(sp)
 47e:	f4a6                	sd	s1,104(sp)
 480:	f0ca                	sd	s2,96(sp)
 482:	ecce                	sd	s3,88(sp)
 484:	e8d2                	sd	s4,80(sp)
 486:	e4d6                	sd	s5,72(sp)
 488:	e0da                	sd	s6,64(sp)
 48a:	fc5e                	sd	s7,56(sp)
 48c:	f862                	sd	s8,48(sp)
 48e:	f466                	sd	s9,40(sp)
 490:	f06a                	sd	s10,32(sp)
 492:	ec6e                	sd	s11,24(sp)
 494:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 496:	0005c903          	lbu	s2,0(a1)
 49a:	18090f63          	beqz	s2,638 <vprintf+0x1c0>
 49e:	8aaa                	mv	s5,a0
 4a0:	8b32                	mv	s6,a2
 4a2:	00158493          	addi	s1,a1,1
  state = 0;
 4a6:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4a8:	02500a13          	li	s4,37
 4ac:	4c55                	li	s8,21
 4ae:	00000c97          	auipc	s9,0x0
 4b2:	3dac8c93          	addi	s9,s9,986 # 888 <malloc+0x14c>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4b6:	02800d93          	li	s11,40
  putc(fd, 'x');
 4ba:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4bc:	00000b97          	auipc	s7,0x0
 4c0:	424b8b93          	addi	s7,s7,1060 # 8e0 <digits>
 4c4:	a839                	j	4e2 <vprintf+0x6a>
        putc(fd, c);
 4c6:	85ca                	mv	a1,s2
 4c8:	8556                	mv	a0,s5
 4ca:	00000097          	auipc	ra,0x0
 4ce:	ee0080e7          	jalr	-288(ra) # 3aa <putc>
 4d2:	a019                	j	4d8 <vprintf+0x60>
    } else if(state == '%'){
 4d4:	01498d63          	beq	s3,s4,4ee <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4d8:	0485                	addi	s1,s1,1
 4da:	fff4c903          	lbu	s2,-1(s1)
 4de:	14090d63          	beqz	s2,638 <vprintf+0x1c0>
    if(state == 0){
 4e2:	fe0999e3          	bnez	s3,4d4 <vprintf+0x5c>
      if(c == '%'){
 4e6:	ff4910e3          	bne	s2,s4,4c6 <vprintf+0x4e>
        state = '%';
 4ea:	89d2                	mv	s3,s4
 4ec:	b7f5                	j	4d8 <vprintf+0x60>
      if(c == 'd'){
 4ee:	11490c63          	beq	s2,s4,606 <vprintf+0x18e>
 4f2:	f9d9079b          	addiw	a5,s2,-99
 4f6:	0ff7f793          	zext.b	a5,a5
 4fa:	10fc6e63          	bltu	s8,a5,616 <vprintf+0x19e>
 4fe:	f9d9079b          	addiw	a5,s2,-99
 502:	0ff7f713          	zext.b	a4,a5
 506:	10ec6863          	bltu	s8,a4,616 <vprintf+0x19e>
 50a:	00271793          	slli	a5,a4,0x2
 50e:	97e6                	add	a5,a5,s9
 510:	439c                	lw	a5,0(a5)
 512:	97e6                	add	a5,a5,s9
 514:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 516:	008b0913          	addi	s2,s6,8
 51a:	4685                	li	a3,1
 51c:	4629                	li	a2,10
 51e:	000b2583          	lw	a1,0(s6)
 522:	8556                	mv	a0,s5
 524:	00000097          	auipc	ra,0x0
 528:	ea8080e7          	jalr	-344(ra) # 3cc <printint>
 52c:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 52e:	4981                	li	s3,0
 530:	b765                	j	4d8 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 532:	008b0913          	addi	s2,s6,8
 536:	4681                	li	a3,0
 538:	4629                	li	a2,10
 53a:	000b2583          	lw	a1,0(s6)
 53e:	8556                	mv	a0,s5
 540:	00000097          	auipc	ra,0x0
 544:	e8c080e7          	jalr	-372(ra) # 3cc <printint>
 548:	8b4a                	mv	s6,s2
      state = 0;
 54a:	4981                	li	s3,0
 54c:	b771                	j	4d8 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 54e:	008b0913          	addi	s2,s6,8
 552:	4681                	li	a3,0
 554:	866a                	mv	a2,s10
 556:	000b2583          	lw	a1,0(s6)
 55a:	8556                	mv	a0,s5
 55c:	00000097          	auipc	ra,0x0
 560:	e70080e7          	jalr	-400(ra) # 3cc <printint>
 564:	8b4a                	mv	s6,s2
      state = 0;
 566:	4981                	li	s3,0
 568:	bf85                	j	4d8 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 56a:	008b0793          	addi	a5,s6,8
 56e:	f8f43423          	sd	a5,-120(s0)
 572:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 576:	03000593          	li	a1,48
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e2e080e7          	jalr	-466(ra) # 3aa <putc>
  putc(fd, 'x');
 584:	07800593          	li	a1,120
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e20080e7          	jalr	-480(ra) # 3aa <putc>
 592:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 594:	03c9d793          	srli	a5,s3,0x3c
 598:	97de                	add	a5,a5,s7
 59a:	0007c583          	lbu	a1,0(a5)
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e0a080e7          	jalr	-502(ra) # 3aa <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a8:	0992                	slli	s3,s3,0x4
 5aa:	397d                	addiw	s2,s2,-1
 5ac:	fe0914e3          	bnez	s2,594 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5b0:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5b4:	4981                	li	s3,0
 5b6:	b70d                	j	4d8 <vprintf+0x60>
        s = va_arg(ap, char*);
 5b8:	008b0913          	addi	s2,s6,8
 5bc:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5c0:	02098163          	beqz	s3,5e2 <vprintf+0x16a>
        while(*s != 0){
 5c4:	0009c583          	lbu	a1,0(s3)
 5c8:	c5ad                	beqz	a1,632 <vprintf+0x1ba>
          putc(fd, *s);
 5ca:	8556                	mv	a0,s5
 5cc:	00000097          	auipc	ra,0x0
 5d0:	dde080e7          	jalr	-546(ra) # 3aa <putc>
          s++;
 5d4:	0985                	addi	s3,s3,1
        while(*s != 0){
 5d6:	0009c583          	lbu	a1,0(s3)
 5da:	f9e5                	bnez	a1,5ca <vprintf+0x152>
        s = va_arg(ap, char*);
 5dc:	8b4a                	mv	s6,s2
      state = 0;
 5de:	4981                	li	s3,0
 5e0:	bde5                	j	4d8 <vprintf+0x60>
          s = "(null)";
 5e2:	00000997          	auipc	s3,0x0
 5e6:	29e98993          	addi	s3,s3,670 # 880 <malloc+0x144>
        while(*s != 0){
 5ea:	85ee                	mv	a1,s11
 5ec:	bff9                	j	5ca <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 5ee:	008b0913          	addi	s2,s6,8
 5f2:	000b4583          	lbu	a1,0(s6)
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	db2080e7          	jalr	-590(ra) # 3aa <putc>
 600:	8b4a                	mv	s6,s2
      state = 0;
 602:	4981                	li	s3,0
 604:	bdd1                	j	4d8 <vprintf+0x60>
        putc(fd, c);
 606:	85d2                	mv	a1,s4
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	da0080e7          	jalr	-608(ra) # 3aa <putc>
      state = 0;
 612:	4981                	li	s3,0
 614:	b5d1                	j	4d8 <vprintf+0x60>
        putc(fd, '%');
 616:	85d2                	mv	a1,s4
 618:	8556                	mv	a0,s5
 61a:	00000097          	auipc	ra,0x0
 61e:	d90080e7          	jalr	-624(ra) # 3aa <putc>
        putc(fd, c);
 622:	85ca                	mv	a1,s2
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	d84080e7          	jalr	-636(ra) # 3aa <putc>
      state = 0;
 62e:	4981                	li	s3,0
 630:	b565                	j	4d8 <vprintf+0x60>
        s = va_arg(ap, char*);
 632:	8b4a                	mv	s6,s2
      state = 0;
 634:	4981                	li	s3,0
 636:	b54d                	j	4d8 <vprintf+0x60>
    }
  }
}
 638:	70e6                	ld	ra,120(sp)
 63a:	7446                	ld	s0,112(sp)
 63c:	74a6                	ld	s1,104(sp)
 63e:	7906                	ld	s2,96(sp)
 640:	69e6                	ld	s3,88(sp)
 642:	6a46                	ld	s4,80(sp)
 644:	6aa6                	ld	s5,72(sp)
 646:	6b06                	ld	s6,64(sp)
 648:	7be2                	ld	s7,56(sp)
 64a:	7c42                	ld	s8,48(sp)
 64c:	7ca2                	ld	s9,40(sp)
 64e:	7d02                	ld	s10,32(sp)
 650:	6de2                	ld	s11,24(sp)
 652:	6109                	addi	sp,sp,128
 654:	8082                	ret

0000000000000656 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 656:	715d                	addi	sp,sp,-80
 658:	ec06                	sd	ra,24(sp)
 65a:	e822                	sd	s0,16(sp)
 65c:	1000                	addi	s0,sp,32
 65e:	e010                	sd	a2,0(s0)
 660:	e414                	sd	a3,8(s0)
 662:	e818                	sd	a4,16(s0)
 664:	ec1c                	sd	a5,24(s0)
 666:	03043023          	sd	a6,32(s0)
 66a:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 66e:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 672:	8622                	mv	a2,s0
 674:	00000097          	auipc	ra,0x0
 678:	e04080e7          	jalr	-508(ra) # 478 <vprintf>
}
 67c:	60e2                	ld	ra,24(sp)
 67e:	6442                	ld	s0,16(sp)
 680:	6161                	addi	sp,sp,80
 682:	8082                	ret

0000000000000684 <printf>:

void
printf(const char *fmt, ...)
{
 684:	711d                	addi	sp,sp,-96
 686:	ec06                	sd	ra,24(sp)
 688:	e822                	sd	s0,16(sp)
 68a:	1000                	addi	s0,sp,32
 68c:	e40c                	sd	a1,8(s0)
 68e:	e810                	sd	a2,16(s0)
 690:	ec14                	sd	a3,24(s0)
 692:	f018                	sd	a4,32(s0)
 694:	f41c                	sd	a5,40(s0)
 696:	03043823          	sd	a6,48(s0)
 69a:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 69e:	00840613          	addi	a2,s0,8
 6a2:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6a6:	85aa                	mv	a1,a0
 6a8:	4505                	li	a0,1
 6aa:	00000097          	auipc	ra,0x0
 6ae:	dce080e7          	jalr	-562(ra) # 478 <vprintf>
}
 6b2:	60e2                	ld	ra,24(sp)
 6b4:	6442                	ld	s0,16(sp)
 6b6:	6125                	addi	sp,sp,96
 6b8:	8082                	ret

00000000000006ba <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6ba:	1141                	addi	sp,sp,-16
 6bc:	e422                	sd	s0,8(sp)
 6be:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6c0:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6c4:	00001797          	auipc	a5,0x1
 6c8:	93c7b783          	ld	a5,-1732(a5) # 1000 <freep>
 6cc:	a02d                	j	6f6 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6ce:	4618                	lw	a4,8(a2)
 6d0:	9f2d                	addw	a4,a4,a1
 6d2:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6d6:	6398                	ld	a4,0(a5)
 6d8:	6310                	ld	a2,0(a4)
 6da:	a83d                	j	718 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6dc:	ff852703          	lw	a4,-8(a0)
 6e0:	9f31                	addw	a4,a4,a2
 6e2:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6e4:	ff053683          	ld	a3,-16(a0)
 6e8:	a091                	j	72c <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ea:	6398                	ld	a4,0(a5)
 6ec:	00e7e463          	bltu	a5,a4,6f4 <free+0x3a>
 6f0:	00e6ea63          	bltu	a3,a4,704 <free+0x4a>
{
 6f4:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f6:	fed7fae3          	bgeu	a5,a3,6ea <free+0x30>
 6fa:	6398                	ld	a4,0(a5)
 6fc:	00e6e463          	bltu	a3,a4,704 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 700:	fee7eae3          	bltu	a5,a4,6f4 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 704:	ff852583          	lw	a1,-8(a0)
 708:	6390                	ld	a2,0(a5)
 70a:	02059813          	slli	a6,a1,0x20
 70e:	01c85713          	srli	a4,a6,0x1c
 712:	9736                	add	a4,a4,a3
 714:	fae60de3          	beq	a2,a4,6ce <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 718:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 71c:	4790                	lw	a2,8(a5)
 71e:	02061593          	slli	a1,a2,0x20
 722:	01c5d713          	srli	a4,a1,0x1c
 726:	973e                	add	a4,a4,a5
 728:	fae68ae3          	beq	a3,a4,6dc <free+0x22>
    p->s.ptr = bp->s.ptr;
 72c:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 72e:	00001717          	auipc	a4,0x1
 732:	8cf73923          	sd	a5,-1838(a4) # 1000 <freep>
}
 736:	6422                	ld	s0,8(sp)
 738:	0141                	addi	sp,sp,16
 73a:	8082                	ret

000000000000073c <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 73c:	7139                	addi	sp,sp,-64
 73e:	fc06                	sd	ra,56(sp)
 740:	f822                	sd	s0,48(sp)
 742:	f426                	sd	s1,40(sp)
 744:	f04a                	sd	s2,32(sp)
 746:	ec4e                	sd	s3,24(sp)
 748:	e852                	sd	s4,16(sp)
 74a:	e456                	sd	s5,8(sp)
 74c:	e05a                	sd	s6,0(sp)
 74e:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 750:	02051493          	slli	s1,a0,0x20
 754:	9081                	srli	s1,s1,0x20
 756:	04bd                	addi	s1,s1,15
 758:	8091                	srli	s1,s1,0x4
 75a:	0014899b          	addiw	s3,s1,1
 75e:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 760:	00001517          	auipc	a0,0x1
 764:	8a053503          	ld	a0,-1888(a0) # 1000 <freep>
 768:	c515                	beqz	a0,794 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 76a:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 76c:	4798                	lw	a4,8(a5)
 76e:	02977f63          	bgeu	a4,s1,7ac <malloc+0x70>
 772:	8a4e                	mv	s4,s3
 774:	0009871b          	sext.w	a4,s3
 778:	6685                	lui	a3,0x1
 77a:	00d77363          	bgeu	a4,a3,780 <malloc+0x44>
 77e:	6a05                	lui	s4,0x1
 780:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 784:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 788:	00001917          	auipc	s2,0x1
 78c:	87890913          	addi	s2,s2,-1928 # 1000 <freep>
  if(p == (char*)-1)
 790:	5afd                	li	s5,-1
 792:	a895                	j	806 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 794:	00001797          	auipc	a5,0x1
 798:	87c78793          	addi	a5,a5,-1924 # 1010 <base>
 79c:	00001717          	auipc	a4,0x1
 7a0:	86f73223          	sd	a5,-1948(a4) # 1000 <freep>
 7a4:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7a6:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7aa:	b7e1                	j	772 <malloc+0x36>
      if(p->s.size == nunits)
 7ac:	02e48c63          	beq	s1,a4,7e4 <malloc+0xa8>
        p->s.size -= nunits;
 7b0:	4137073b          	subw	a4,a4,s3
 7b4:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7b6:	02071693          	slli	a3,a4,0x20
 7ba:	01c6d713          	srli	a4,a3,0x1c
 7be:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7c0:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7c4:	00001717          	auipc	a4,0x1
 7c8:	82a73e23          	sd	a0,-1988(a4) # 1000 <freep>
      return (void*)(p + 1);
 7cc:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7d0:	70e2                	ld	ra,56(sp)
 7d2:	7442                	ld	s0,48(sp)
 7d4:	74a2                	ld	s1,40(sp)
 7d6:	7902                	ld	s2,32(sp)
 7d8:	69e2                	ld	s3,24(sp)
 7da:	6a42                	ld	s4,16(sp)
 7dc:	6aa2                	ld	s5,8(sp)
 7de:	6b02                	ld	s6,0(sp)
 7e0:	6121                	addi	sp,sp,64
 7e2:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7e4:	6398                	ld	a4,0(a5)
 7e6:	e118                	sd	a4,0(a0)
 7e8:	bff1                	j	7c4 <malloc+0x88>
  hp->s.size = nu;
 7ea:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7ee:	0541                	addi	a0,a0,16
 7f0:	00000097          	auipc	ra,0x0
 7f4:	eca080e7          	jalr	-310(ra) # 6ba <free>
  return freep;
 7f8:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7fc:	d971                	beqz	a0,7d0 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7fe:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 800:	4798                	lw	a4,8(a5)
 802:	fa9775e3          	bgeu	a4,s1,7ac <malloc+0x70>
    if(p == freep)
 806:	00093703          	ld	a4,0(s2)
 80a:	853e                	mv	a0,a5
 80c:	fef719e3          	bne	a4,a5,7fe <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 810:	8552                	mv	a0,s4
 812:	00000097          	auipc	ra,0x0
 816:	b68080e7          	jalr	-1176(ra) # 37a <sbrk>
  if(p == (char*)-1)
 81a:	fd5518e3          	bne	a0,s5,7ea <malloc+0xae>
        return 0;
 81e:	4501                	li	a0,0
 820:	bf45                	j	7d0 <malloc+0x94>
