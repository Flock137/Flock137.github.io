---
title: Understanding ARM dissassembly 
date: 2026-03-12
draft: false
showToc: true 
tags:
  - Assembly
  - Hardware
  - Linux
  - stm32
  - ARM
---

## Introduction

When you compile C code for an ARM microcontroller, the compiler translates your high-level code into machine instructions. Reverse engineering tools like Binary Ninja, Ghidra, radare2, etc. can decompile those instructions back into pseudo-C code. This guide shows you how to read that decompiled output and understand what's happening at the hardware level.


## The Example: STM32 LED Blink

We'll use a simple LED blink program for an STM32F103xx (ARM Cortex-M3) microcontroller, that I have published in another repo: https://github.com/Flock137/stm32_blinky_baremetal

### Original C Code (main.c)

```c
#define STM32F103xB
#include "stm32f1xx.h"

void delay(volatile uint32_t count) {
    while(count--);
}

int main(void) {
    // Enable GPIOC clock
    RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;

    // Configure PC13 as output
    GPIOC->CRH = (GPIOC->CRH & ~0xFF000000) | 0x33000000;

    while(1) {
        GPIOC->ODR ^= (1 << 13);  // Toggle
        delay(2000000);
    }
}
```

### Binary Ninja Decompiled Output

```c
08000000    void delay(uint32_t volatile count) __pure
08000000    {
08000000        uint32_t var_c = count;
08000012        uint32_t i;
08000012
08000012        do
08000012        {
0800000a            i = var_c;
0800000e            var_c = i - 1;
08000012        } while (i);
08000000    }

08000020    void main() __noreturn
08000020    {
08000020        *(uint32_t*)0x40021018 |= 0x10;
0800003e        *(uint32_t*)0x40011004 = (
0800003e            *(uint32_t*)0x40011004 & 0xffffff)
0800003e            | 0x33000000;
0800003e
0800004a        while (true)
0800004a            *(uint32_t*)0x4001100c ^= 0x2000;
08000020    }

// Literal pool (constants stored in flash)
08000058  int32_t data_8000058 = 0x40021000  // RCC base
0800005c  int32_t data_800005c = 0x40011000  // GPIOC base
08000060  int32_t data_8000060 = 0x1e8480    // 2000000 decimal
```


## Understanding C Operators


### 1. Post-Decrement (`--`)

```c
while(count--);
```

**How it works:**
- Evaluates the current value
- Then decrements by 1
- Continues while value is non-zero

**Detailed example:**
```c
count = 3;
while(count--);

// What happens:
// Check: count is 3 (true) → then decrement to 2
// Check: count is 2 (true) → then decrement to 1
// Check: count is 1 (true) → then decrement to 0
// Check: count is 0 (false) → exit loop
```

**Comparison with pre-decrement:**
```c
int a = 5;
int b = a--;  // b = 5, a = 4 (post-decrement: use then decrement)

int x = 5;
int y = --x;  // y = 4, x = 4 (pre-decrement: decrement then use)
```

### 2. Bitwise OR Assignment (`|=`)

```c
RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
// Equivalent to:
RCC->APB2ENR = RCC->APB2ENR | RCC_APB2ENR_IOPCEN;
```

**Purpose:** Set specific bits to 1 without affecting other bits

**Example:**
```
Original value:  0000 0101  (0x05)
OR with:         0001 0000  (0x10)
                 ---------
Result:          0001 0101  (0x15)
                     ^
                     Bit 4 is now set, others unchanged
```

**But why?**
In embedded systems, you often need to enable a feature by setting a specific bit in a control register. Other bits control different features, so you can't just write a new value - you must preserve the existing bits.

### 3. Bitwise AND with NOT (`& ~`)

```c
GPIOC->CRH & ~0xFF000000
```

**Purpose:** Clear specific bits (set them to 0)

**Step by step:**
```
0xFF000000 =      1111 1111 0000 0000 0000 0000 0000 0000
~0xFF000000 =     0000 0000 1111 1111 1111 1111 1111 1111
                                        (all bits flipped)

Original CRH:     1010 1011 0101 0101 1100 1100 1010 1010
AND ~0xFF000000:  0000 0000 1111 1111 1111 1111 1111 1111
                  -----------------------------------------
Result:           0000 0000 0101 0101 1100 1100 1010 1010
                  ^^^^^^^^^
                  Top 8 bits cleared
```


### 4. XOR (`^=`)

```c
GPIOC->ODR ^= (1 << 13);
```

**Purpose:** Toggle bits (0→1, 1→0)

**Example:**
```
First toggle:
ODR:           0000 0000 0000 0000 0000 0000 0000 0000
XOR (1 << 13): 0000 0000 0000 0000 0010 0000 0000 0000
               -----------------------------------------
Result:        0000 0000 0000 0000 0010 0000 0000 0000 (bit 13 = 1)

Second toggle:
ODR:           0000 0000 0000 0000 0010 0000 0000 0000
XOR (1 << 13): 0000 0000 0000 0000 0010 0000 0000 0000
               -----------------------------------------
Result:        0000 0000 0000 0000 0000 0000 0000 0000 (bit 13 = 0)
```

**XOR table:**
```
0 ^ 0 = 0
0 ^ 1 = 1
1 ^ 0 = 1
1 ^ 1 = 0 
```

### 5. Left Shift (`<<`)

```c
(1 << 13)
```

**Purpose:** Create a bitmask by shifting bits to the left

**Example:**
```
1 << 0  = 0000 0000 0000 0001  (0x0001)
1 << 1  = 0000 0000 0000 0010  (0x0002)
1 << 2  = 0000 0000 0000 0100  (0x0004)
1 << 13 = 0010 0000 0000 0000  (0x2000)
```

**Reasoning:**
Instead of memorizing that bit 13 = 0x2000, you just write `(1 << 13)` which is self-documenting.

### 6. The Arrow Operator (`->`)

```c
GPIOC->ODR
```

**What it means:**
```c
ptr->member
// Exactly equivalent to:
(*ptr).member
```

**How it works in embedded code:**

```c
// The peripheral struct definition
typedef struct {
    uint32_t CRL;   // offset 0x00
    uint32_t CRH;   // offset 0x04
    uint32_t IDR;   // offset 0x08
    uint32_t ODR;   // offset 0x0C
} GPIO_TypeDef;

// The pointer definition (from stm32f1xx.h)
#define GPIOC ((GPIO_TypeDef *) 0x40011000)
```

**What happens when you write `GPIOC->ODR`:**

1. `GPIOC` is a pointer to address `0x40011000`
2. `->` dereferences it and accesses the struct
3. `ODR` is at offset `0x0C` in the struct
4. Final address: `0x40011000 + 0x0C = 0x4001100C`

**Visual representation:**
```
Memory Address    Register    Offset
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0x40011000   →   CRL         +0x00
0x40011004   →   CRH         +0x04
0x40011008   →   IDR         +0x08
0x4001100C   →   ODR         +0x0C  ← GPIOC->ODR points here
```


## Memory-Mapped I/O: The Bridge

In ARM microcontrollers, **hardware peripherals are controlled by reading/writing to specific memory addresses**. These aren't RAM locations - they're special addresses that connect directly to hardware.

### Example: The RCC Peripheral

**Human-readable C code:**
```c
RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
```

**How the macro expands:**

```c
// Step 1: Expand the macros
#define RCC ((RCC_TypeDef *) 0x40021000)
#define RCC_APB2ENR_IOPCEN 0x10

// Step 2: Expand RCC
((RCC_TypeDef *) 0x40021000)->APB2ENR |= 0x10;

// Step 3: Calculate address
// RCC base = 0x40021000
// APB2ENR offset = 0x18 (from struct definition)
// Final address = 0x40021018

// Step 4: What the CPU actually sees
*(uint32_t*)0x40021018 |= 0x10;
```


### Memory Map Overview

```
Address Range        Purpose
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
0x08000000-0x0801FFFF   Flash (128KB) - Your program code
0x20000000-0x20004FFF   SRAM (20KB) - Variables, stack
0x40000000-0x40023FFF   Peripherals - Hardware control

Peripherals:
0x40021000             RCC (Reset and Clock Control)
0x40011000             GPIOC (GPIO Port C)
```

### How the Compiler Translates

```c
// What you write:
RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;

// What the compiler generates (pseudo-code):
1. Load address 0x40021018 into register
2. Read current value from that address
3. OR it with 0x10
4. Write the result back to 0x40021018

// What the disassembler shows you:
*(uint32_t*)0x40021018 |= 0x10;
```


## Reading the Disassembly

### Understanding the Address Column

```
08000000    void delay(uint32_t volatile count) __pure
08000000    {
0800000a        i = var_c;
0800000e        var_c = i - 1;
08000012    } while (i);
```

**The left column are memory addresses:**
- `0x08000000` - Flash memory address where this function starts
- `0x0800000a` - Address of the instruction that copies var_c to i
- `0x0800000e` - Address of the decrement instruction
- `0x08000012` - Address of the loop check instruction


### The Literal Pool

```c
08000058  int32_t data_8000058 = 0x40021000  // RCC base
0800005c  int32_t data_800005c = 0x40011000  // GPIOC base
08000060  int32_t data_8000060 = 0x1e8480    // 2000000 decimal
```

**What is this?**
ARM processors can't load large 32-bit constants directly into registers. Instead, the compiler stores them in Flash and loads them from there.

**Example:**
```c
delay(2000000);

// The CPU needs to load 2000000 (0x1E8480) into a register
// It can't do this in one instruction, so:
// 1. Compiler stores 0x1E8480 at address 0x08000060
// 2. At runtime, CPU loads from 0x08000060 into register
// 3. Then calls delay() with that value
```

### Type Casts

```c
*(uint32_t*)0x40021018
```

**Breaking it down:**
- `0x40021018` - A raw memory address
- `(uint32_t*)` - Cast it to a pointer to 32-bit unsigned integer
- `*` - Dereference (access the value at that address)

**Why the cast is needed:**
In C, you can't dereference a raw number. This tells the compiler "treat this number as a pointer to a 32-bit value."



## Step-by-Step Comparison

### Enabling the Clock

**C Code (main.c:10):**
```c
RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
```

**Disassembly (line 33):**
```c
*(uint32_t*)0x40021018 |= 0x10;
```

**Matching process:**

1. **Find RCC base address:**
   ```c
   #define RCC ((RCC_TypeDef *) 0x40021000)
   ```
   Look at the literal pool: `data_8000058 = 0x40021000` 

2. **Find APB2ENR offset:**
   ```c
   typedef struct {
       uint32_t CR;      // offset 0x00
       uint32_t CFGR;    // offset 0x04
       uint32_t CIR;     // offset 0x08
       uint32_t APB2RSTR;// offset 0x0C
       uint32_t APB1RSTR;// offset 0x10
       uint32_t AHBENR;  // offset 0x14
       uint32_t APB2ENR; // offset 0x18 
   } RCC_TypeDef;
   ```

3. **Calculate final address:**
   ```
   0x40021000 (RCC base)
   + 0x18 (APB2ENR offset)
   = 0x40021018 
   ```

4. **Find the bit value:**
   ```c
   #define RCC_APB2ENR_IOPCEN 0x10
   ```
   This is bit 4 (2^4 = 16 = 0x10) 

### Example 2: Configuring the GPIO Pin

**C Code (main.c:13):**
```c
GPIOC->CRH = (GPIOC->CRH & ~0xFF000000) | 0x33000000;
```

**Disassembly (lines 34-36):**
```c
*(uint32_t*)0x40011004 = (
    *(uint32_t*)0x40011004 & 0xffffff)
    | 0x33000000;
```

**Matching process:**

1. **Find GPIOC base:**
   ```
   Literal pool: data_800005c = 0x40011000 
   ```

2. **Find CRH offset:**
   ```c
   typedef struct {
       uint32_t CRL;  // offset 0x00
       uint32_t CRH;  // offset 0x04 
   } GPIO_TypeDef;
   ```

3. **Calculate address:**
   ```
   0x40011000 + 0x04 = 0x40011004
   ```

4. **Compare the operations:**
   ```c
   // Source:
   (GPIOC->CRH & ~0xFF000000) | 0x33000000

   // Disassembly:
   (*(uint32_t*)0x40011004 & 0xffffff) | 0x33000000

   // Note: ~0xFF000000 = 0x00FFFFFF
   //       0xffffff = 0x00FFFFFF
   ```

Note that the compiler has optimized the `~0xFF000000` by computing the NOT operation at compile time.

### Example 3: Toggling the LED

**C Code (main.c:16):**
```c
GPIOC->ODR ^= (1 << 13);
```

**Disassembly (line 39):**
```c
*(uint32_t*)0x4001100c ^= 0x2000;
```

**Matching process:**

1. **Find ODR offset:**
   ```c
   typedef struct {
       uint32_t CRL;  // offset 0x00
       uint32_t CRH;  // offset 0x04
       uint32_t IDR;  // offset 0x08
       uint32_t ODR;  // offset 0x0C 
   } GPIO_TypeDef;
   ```

2. **Calculate address:**
   ```
   0x40011000 + 0x0C = 0x4001100C 
   ```

3. **Calculate the bit value:**
   ```
   1 << 13 = 1 shifted left 13 positions
          = 0x2000 
   ```

**Binary verification:**
```
1       = 0000 0000 0000 0001
1 << 13 = 0010 0000 0000 0000
        = 0x2000 
```

### Example 4: The Delay Function

**C Code (main.c:4-6):**
```c
void delay(volatile uint32_t count) {
    while(count--);
}
```

**Disassembly (lines 16-27):**
```c
void delay(uint32_t volatile count) __pure
{
    uint32_t var_c = count;
    uint32_t i;

    do {
        i = var_c;
        var_c = i - 1;
    } while (i);
}
```

You can see that the compiler has transformed the loop structure:

```c
// Original:
while(count--)

// Becomes:
do {
    i = count;
    count = i - 1;
} while (i);
```

This is because ARM processors can check conditions very efficiently at the end of a loop. This is a common compiler optimization, so they are technically the same thing.



## Key Patterns to Recognize

### Pattern 1: Read-Modify-Write

**Purpose:** Change specific bits without affecting others

**Template:**
```c
register = (register & mask) | value;
```

**Example:**
```c
GPIOC->CRH = (GPIOC->CRH & ~0xFF000000) | 0x33000000;
```

**What it does:**
1. Read current value
2. Clear bits you want to change (AND with mask)
3. Set new bits (OR with value)
4. Write back

**Why not just write the value directly?**
Because other bits in the register might control other pins or features. It is required to preserve them.

### Pattern 2: Bit Set (OR)

**Purpose:** Enable a feature by setting a bit to 1

**Template:**
```c
register |= (1 << bit_number);
```

**Example:**
```c
RCC->APB2ENR |= RCC_APB2ENR_IOPCEN;
// Same as:
RCC->APB2ENR |= (1 << 4);
```

**Why use OR?**
It only sets bits to 1, never clears them. Other enabled features stay enabled.

### Pattern 3: Bit Clear (`AND` `NOT`)

**Purpose:** Disable a feature by setting a bit to 0

**Template:**
```c
register &= ~(1 << bit_number);
```

**Example:**
```c
GPIOC->ODR &= ~(1 << 13);  // Turn off LED
```

**Why?**
The `NOT` inverts the bit mask, `AND` clears only those bits.

### Pattern 4: Bit Toggle (XOR)

**Purpose:** Flip a bit (0 -> 1 or 1 -> 0)

**Template:**
```c
register ^= (1 << bit_number);
```

**Example:**
```c
GPIOC->ODR ^= (1 << 13);  // Toggle LED
```

**Why XOR?**
It automatically flips the bit state without needing to know the current state.

### Pattern 5: Bit Check (AND)

**Purpose:** Test if a specific bit is set

**Template:**
```c
if (register & (1 << bit_number)) {
    // Bit is set
}
```

**Example:**
```c
if (GPIOC->IDR & (1 << 13)) {
    // Pin 13 is high
}
```

### Summary Table

| Operation | Operator | Purpose | Example |
|-----------|----------|---------|---------|
| Set bit | `\|=` | Turn on a feature | `reg \|= (1 << 4)` |
| Clear bit | `&= ~` | Turn off a feature | `reg &= ~(1 << 4)` |
| Toggle bit | `^=` | Flip a bit | `reg ^= (1 << 4)` |
| Check bit | `&` | Test if bit is set | `if (reg & (1 << 4))` |
| Read-Modify-Write | `& ~` then `\|` | Change some bits | `reg = (reg & ~mask) \| val` |


## Practical Tips

### 1. Use a Reference Manual 
It's highly recommended that you use them, since searching or using AI tool might not help that much. 
For example, with STM32F103xx Black Pill, it has 3 related manuals/references. You can view them here: https://github.com/Flock137/STM32_manual

### 2. Calculate Addresses Manually

When you see an address in disassembly, work backwards:

```
Address: 0x4001100C

Step 1: What's the base?
0x40011000 → That's GPIOC

Step 2: What's the offset?
0x4001100C - 0x40011000 = 0x0C

Step 3: What register is at 0x0C?
typedef struct {
    uint32_t CRL;  // +0x00
    uint32_t CRH;  // +0x04
    uint32_t IDR;  // +0x08
    uint32_t ODR;  // +0x0C  \\Here!
} GPIO_TypeDef;

Answer: GPIOC->ODR
```

### 3. Convert Between Number Formats

**Hex to Binary:**
```
0x2000 = ?

Break into nibbles (4 bits each):
2    0    0    0
0010 0000 0000 0000

So 0x2000 = bit 13 is set (as in 13th position starting from the right)
```

**Quick hex-to-binary chart:**
```
Hex  Binary
0    0000
1    0001
2    0010
3    0011
4    0100
5    0101
6    0110
7    0111
8    1000
9    1001
A    1010
B    1011
C    1100
D    1101
E    1110
F    1111
```

### 4. Recognize Magic Numbers

**Common values in STM32:**

| Value | Meaning |
|-------|---------|
| 0x10 | Bit 4 set |
| 0x2000 | Bit 13 set (1 << 13) |
| 0x33 | GPIO output 50MHz, push-pull |
| 0x44 | GPIO input, floating |
| 0x88 | GPIO input, pull-up/down |
| 0xFF000000 | Top 8 bits mask |
| 0x00FFFFFF | Bottom 24 bits mask |

### 5. Look for Patterns in the Literal Pool

```c
08000058  int32_t data_8000058 = 0x40021000  // RCC
0800005c  int32_t data_800005c = 0x40011000  // GPIOC
08000060  int32_t data_8000060 = 0x1e8480    // delay count
```

**How to use this:**
- Addresses starting with 0x4002xxxx → APB2 peripherals (RCC, AFIO)
- Addresses starting with 0x4001xxxx → APB1/APB2 GPIO ports
- Large hex numbers that aren't addresses → often delay counts or data

### 6. Notes on Compiler Optimizations

**The compiler may:**
- Change loop types (while → do-while)
- Pre-calculate constants (~0xFF000000 → 0x00FFFFFF)
- Reorder operations for efficiency
- Inline small functions
- Remove unused code

**But it will never:**
- Change the final hardware behavior
- Skip volatile accesses
- Reorder memory operations incorrectly

### 7. Trace Data Flow

Follow a value through the code:

```c
// Source:
delay(2000000);

// Literal pool shows:
data_8000060 = 0x1e8480  // 2000000 in hex

// Assembly would:
1. Load 0x1e8480 from address 0x08000060
2. Store in register (e.g., r0)
3. Call delay function
4. delay() decrements until 0
```


## Common Pitfalls

### Pitfall 1: Forgetting the Pointer Cast

```c
// Wrong:
*0x40021018 |= 0x10;  // Error: can't dereference an integer

// Right:
*(uint32_t*)0x40021018 |= 0x10;
```

### Pitfall 2: Wrong Bit Calculations

```c
// You see:
reg ^= 0x2000

// Don't assume it's bit 8 (0x2000 = 8192)
// Calculate properly:
0x2000 = 0010 0000 0000 0000 = bit 13
```

### Pitfall 3: Endian type Confusion

ARM Cortex-M is **little-endian**, but for bit operations on 32-bit registers, you usually don't need to worry about this. It matters more for multi-bytes data structures.

### Pitfall 4: Volatile Keyword

```c
volatile uint32_t count;
```

**Meaning:**
- Tells compiler "this value might change unexpectedly"
- Prevents optimization that might skip reading the variable
- Essential for hardware registers and interrupt-shared variables

**In disassembly:**
You'll see actual memory reads/writes even if they seem redundant.


## Quick Reference Card

### Operator Cheat Sheet
```c
|=     Set bits      reg |= 0x10
&= ~   Clear bits    reg &= ~0x10
^=     Toggle bits   reg ^= 0x10
&      Test bits     if (reg & 0x10)
<<     Shift left    1 << 13 = 0x2000
>>     Shift right   0x2000 >> 13 = 1
```

### Common STM32 Addresses
```
0x40021000  RCC (clocks)
0x40010800  GPIOA
0x40010C00  GPIOB
0x40011000  GPIOC
0x08000000  Flash start
0x20000000  SRAM start
```

---

*Last updated: 2026-03-12*
*For corrections or additions, please make pull request*
