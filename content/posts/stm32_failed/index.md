---
title: Failed attempt on performing Hardware Forensics (STM32)
date: 2026-02-07
draft: false
showToc: true 
tags:
  - Forensics
  - Hardware
  - Debug
  - Linux
---

## Introduction  

I chose to start my hardware hacking journey with an attempt to live debugging a piece of hardware. As I am waiting for the necessary parts I need to arrive, I did some emulations of the STM32, so I might have the binary ready to flash the binary into the hardware by the times the parts arrive.

As weird as it is to write about a failed attempt on a blog post, this is written to at least temporary record what I did, for potential future references. The code for this attempt would not be released, as I definitely do not want to embarrase myself.

## Prerequisites 

For this, you need these packages: `arm-none-eabi-gcc`, `gdb` (or `gdb-multiarch`, it might depend on which distro you use) and `qemu-system-arm`

Installation command on all Arch and Arch-based systems: 

```
sudo pacman -S arm-none-eabi-gcc gdb qemu-system-arm 
```

For other distros, please search for your equivalent command and packages, as sometimes, it varies. 


## File structure 

```
❯ tree
.
├── build
│   ├── blink.bin
│   ├── blink.elf
│   └── blink.map
├── inc
│   └── stm32f103c8t6.h
├── src
│   ├── main.c
│   └── vectors.c
└── stm32f103c8t6.ld

```

.bin is created later, after successfully compiling the .elf file by typing the command: 

```
❯ arm-none-eabi-objcopy -O binary build/blink.elf build/blink.bin
```

## Executed steps 
Write `main.c`, header (`.h`) linker (`.ld`) and vector table (`vector.c`) and put into its respective places, which was mentionned above. Then you will start to compile the binary (`.elf`):


```
arm-none-eabi-gcc \
  -mcpu=cortex-m3 \
  -mthumb \
  -mfloat-abi=soft \
  -nostdlib \
  -ffreestanding \
  -Isrc -Iinc \
  -T stm32f103c8t6.ld \
  -Wl,-Map=build/blink.map \
  -Wl,--gc-sections \
  -Wl,--print-memory-usage \
  src/vectors.c src/main.c \
  -o build/blink.elf
```


Output: 
```
/usr/lib/gcc/arm-none-eabi/14.2.0/../../../../arm-none-eabi/bin/ld: warning: build/blink.elf has a LOAD segment with RWX permissions
Memory region         Used Size  Region Size  %age Used
           FLASH:         132 B        64 KB      0.20%
             RAM:          1 KB        20 KB      5.00%
```


Then make the `.bin` file, you make this to flash the task into the hardware itself:

```
❯ arm-none-eabi-objcopy -O binary build/blink.elf build/blink.bin
```

Output: 

```
qemu-system-arm -M netduinoplus2 -kernel build/blink.bin -S -s &
echo "QEMU started. PID: $!"
[1] 40761
QEMU started. PID: 40761
```


After obtaining the .bin file for flashing, do this: 

```
cd ~/stm32_forensics/blink

# Terminal 1: Launch QEMU (stops CPU, waits for debugger)
qemu-system-arm -M netduinoplus2 -kernel build/blink.bin -S -s &
echo "QEMU started. PID: $!"
```


Right after that, this might appear:
```
✦ ❯ VNC server running on ::1:5900
```

Now we can start debugging session within gdb. 


## GDB
In a separated terminal:

```
cd ~/stm32_forensics/blink
gdb build/blink.elf
```


```
# Inside GDB:
(gdb) target remote localhost:1234
(gdb) load  # Load your program
(gdb) break main
(gdb) continue  
```


## Errors encountered and Issues

```
src/main.c:2:1: note: 'uint32_t' is defined in header '<stdint.h>'; this is probably fixable by adding '#include <stdint.h>'
    1 | #include "stm32f103c8t6.h"
  +++ |+#include <stdint.h>
    2 | 
```



```
src/main.c:24:5: error: implicit declaration of function 'main' [-Wimplicit-function-declaration]
   24 |     main();
      |     ^~~~
```

It means that the `main()` is being called before your definition of main itself.


### Program continuing forever inside gdb
If it's blank after you `continue`, it means that something went wrong, Ctrl+C and inspect:

```
^C
Program received signal SIGINT, Interrupt.
0x08000014 in Default_Handler ()
(gdb) bt
#0  0x08000014 in Default_Handler ()
(gdb) info reg
r0             0x0                 0
r1             0x0                 0
r2             0x0                 0
r3             0x0                 0
r4             0x0                 0
r5             0x0                 0
r6             0x0                 0
r7             0x20004ffc          536891388
r8             0x0                 0
r9             0x0                 0
r10            0x0                 0
r11            0x0                 0
r12            0x0                 0
sp             0x20004ffc          0x20004ffc
lr             0xffffffff          -1
pc             0x8000014           0x8000014 <Default_Handler+4>
xpsr           0x41000000          1090519040
fpscr          0x0                 0
msp            0x20004ffc          536891388
psp            0x0                 0
primask        0x0                 0
control        0x0                 0
basepri        0x0                 0
faultmask      0x0                 0

```

1. **PC = `0x08000014`** → This is the **HardFault Handler** (4th vector, 0x14 bytes from flash start)

2. **LR = `0xFFFFFFFF`** → Link Register shows **exception return**

3. **SP = `0x20004FFC`** → Stack pointer is near top of RAM (20KB RAM ends at 0x20005000)



```
✦ ❯ arm-none-eabi-objdump -s -j .isr_vector build/blink.elf

build/blink.elf:     file format elf32-littlearm

Contents of section .isr_vector:
 8000000 00500020 45000008 11000008 11000008  .P. E...........

```
Registers seems to be pointing to the wrong addresses. 


```
✦ ❯ arm-none-eabi-objdump -d build/blink.elf --start-address=0x08000000 --stop-address=0x08000080

build/blink.elf:     file format elf32-littlearm


Disassembly of section .text:

08000010 <Default_Handler>:
 8000010:	b480      	push	{r7}
 8000012:	af00      	add	r7, sp, #0
 8000014:	e7fe      	b.n	8000014 <Default_Handler+0x4>
	...

08000018 <crude_delay>:
 8000018:	b480      	push	{r7}
 800001a:	b083      	sub	sp, #12
 800001c:	af00      	add	r7, sp, #0
 800001e:	2300      	movs	r3, #0
 8000020:	607b      	str	r3, [r7, #4]
 8000022:	e002      	b.n	800002a <crude_delay+0x12>
 8000024:	687b      	ldr	r3, [r7, #4]
 8000026:	3301      	adds	r3, #1
 8000028:	607b      	str	r3, [r7, #4]
 800002a:	687b      	ldr	r3, [r7, #4]
 800002c:	4a04      	ldr	r2, [pc, #16]	@ (8000040 <crude_delay+0x28>)
 800002e:	4293      	cmp	r3, r2
 8000030:	ddf8      	ble.n	8000024 <crude_delay+0xc>
 8000032:	bf00      	nop
 8000034:	bf00      	nop
 8000036:	370c      	adds	r7, #12
 8000038:	46bd      	mov	sp, r7
 800003a:	bc80      	pop	{r7}
 800003c:	4770      	bx	lr
 800003e:	bf00      	nop
 8000040:	000f423f 	.word	0x000f423f

08000044 <main>:
 8000044:	b580      	push	{r7, lr}
 8000046:	af00      	add	r7, sp, #0
 8000048:	4b0b      	ldr	r3, [pc, #44]	@ (8000078 <main+0x34>)
 800004a:	681b      	ldr	r3, [r3, #0]
 800004c:	4a0a      	ldr	r2, [pc, #40]	@ (8000078 <main+0x34>)
 800004e:	f043 0310 	orr.w	r3, r3, #16
 8000052:	6013      	str	r3, [r2, #0]
 8000054:	4b09      	ldr	r3, [pc, #36]	@ (800007c <main+0x38>)
 8000056:	681b      	ldr	r3, [r3, #0]
 8000058:	f423 0370 	bic.w	r3, r3, #15728640	@ 0xf00000
 800005c:	4a07      	ldr	r2, [pc, #28]	@ (800007c <main+0x38>)
 800005e:	f443 1340 	orr.w	r3, r3, #3145728	@ 0x300000
 8000062:	6013      	str	r3, [r2, #0]
 8000064:	4b06      	ldr	r3, [pc, #24]	@ (8000080 <main+0x3c>)
 8000066:	681b      	ldr	r3, [r3, #0]
 8000068:	4a05      	ldr	r2, [pc, #20]	@ (8000080 <main+0x3c>)
 800006a:	f483 5300 	eor.w	r3, r3, #8192	@ 0x2000
 800006e:	6013      	str	r3, [r2, #0]
 8000070:	f7ff ffd2 	bl	8000018 <crude_delay>
 8000074:	e7f6      	b.n	8000064 <main+0x20>
 8000076:	bf00      	nop
 8000078:	40021018 	.word	0x40021018
 800007c:	40011004 	.word	0x40011004
```
This is one of the processes disasembly.



## Logs 
This was made on a similar but simplified version of the blinker.


```
~/Projects/simple_stm32 
✦ ❯ arm-none-eabi-objdump -s -j .isr_vector build/blink.elf

build/blink.elf:     file format elf32-littlearm

Contents of section .isr_vector:
 8000000 00500020 45000008 11000008 11000008  .P. E...........

~/Projects/simple_stm32 
✦ ❯ arm-none-eabi-nm build/blink.elf | grep -E "(vectors|_start|Default_Handler|main)"
08000010 T Default_Handler
0800004e T main
08000044 T _start
08000000 R vectors

~/Projects/simple_stm32 
✦ ❯ arm-none-eabi-objdump -d build/blink.elf --start-address=0x08000000 --stop-address=0x08000030

build/blink.elf:     file format elf32-littlearm


Disassembly of section .text:

08000010 <Default_Handler>:
 8000010:	b480      	push	{r7}
 8000012:	af00      	add	r7, sp, #0
 8000014:	e7fe      	b.n	8000014 <Default_Handler+0x4>
	...

08000018 <crude_delay>:
 8000018:	b480      	push	{r7}
 800001a:	b083      	sub	sp, #12
 800001c:	af00      	add	r7, sp, #0
 800001e:	2300      	movs	r3, #0
 8000020:	607b      	str	r3, [r7, #4]
 8000022:	e002      	b.n	800002a <crude_delay+0x12>
 8000024:	687b      	ldr	r3, [r7, #4]
 8000026:	3301      	adds	r3, #1
 8000028:	607b      	str	r3, [r7, #4]
 800002a:	687b      	ldr	r3, [r7, #4]
 800002c:	4a04      	ldr	r2, [pc, #16]	@ (8000040 <crude_delay+0x28>)
 800002e:	4293      	cmp	r3, r2
```

The processes is rather normal to my eyes, and as I start the program in gdb, it stuck at `Default_Handler()` again, and I found out that both process seemed to have never reached `main()`.

## Conclusion

*And the journey continue...* 
