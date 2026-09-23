
---
title: Basic Baremetal STM32 Build and Flash  
date: 2026-09-23
draft: false
showToc: true 
tags:
  - Hardware
  - stm32
  - ARM
  - Linux
  - Arch 
---

I forgot how did I compile all of that in those two stm32 posts, lol. The post will be very brief since this one is just a quick guide for me, since I kinda panic when I realize that I can't quite recall what I have written myself...


## Full Pre-requisites 

```bash
sudo pacman -S arm-none-eabi-gcc gdb qemu-system-arm openocd stlink
```


## Compile ELF 

```bash 
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

## Convert to `.bin`

```bash
arm-none-eabi-objcopy -O binary build/blink.elf build/blink.bin
```

Since `st-flash` and QEMU expect raw binary. 


## Flash to Hardware

I use st-link and openocd. If you ask me why did I use both, I honestly don't remember. 

### st-flash

```bash
st-flash write build/blink.bin 0x8000000
```

To erase: 
```bash
st-flash erase
```

### openocd

```bash
openocd -f interface/stlink.cfg -f target/stm32f1x.cfg \
  -c "program build/blink.elf verify reset exit"
```

## Flash to QEMU 

```bash
qemu-system-arm -M netduinoplus2 -kernel build/blink.bin -S -s &
```

Wrong machine model, btw. It should not have been `netduinoplus2`, but something else, maybe it doesn't exist. 

## Regarding the Live-debug on Baremetal

While the blink was very successful. However, what I was originally want to do wasn't. For more information see [this post](https://flock137.github.io/posts/stm32_failed/). 

Until this day, I am still not sure why did it exactly failed, as the gdb keep disconnecting over and over again. It was speculated that the resource is too tight for an UART live debugging. Except for that, I wasn't able to investigate further, due to fatigue I suffer from at that time. 


