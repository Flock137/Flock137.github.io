---
title: Rough TivaC code example write-up  
date: 2026-11-09
draft: false
showToc: true 
tags:
  - Hardware
  - TivaC
  - ARM 
---


## Description 
Detect the rising edge of pressing button SW1 by using interrupts and then change the status of LEDs in the order below:

```txt
ON RED -> OFF RED -> ON BLUE -> OFF BLUE -> ON GREEN -> OFF GREEN -> ON ALL LEDS -> OFF ALL LEDS -> ON RED (a loop)
```

- Must use interrupts 

## Write-up

- include libraries 
- define switch, individual leds pins and toggle all leds' pins 
- Initiate global variable number of steps that would count button cases
- main 
    - Enable clocks and peripherals 
    - Configure led pins as output, initial state OFF 
    - Configure switch 1 (PF4) as input with pull-up 
    - Enable interrupts
    - "Use" rising edge for switch 1 
    - Enable global interrupts 
    - "while true, keep doing the task"
- `void GPIOPortFIntHandler(void)` 
    - Clear flag to avoid re-triggering 
    - Debounce set up 
    - switch case between led states as mentioned in descriptions
    - Use modulo math to "loop" the number of steps 

## Source code

```c
#include <stdint.h>
#include <stdbool.h>
#include "inc/tm4c123gh6pm.h"
#include "inc/hw_memmap.h"
#include "inc/hw_types.h"
#include "inc/hw_gpio.h"
#include "driverlib/sysctl.h"
#include "driverlib/interrupt.h"
#include "driverlib/gpio.h"

#define BUTTON_SW1   GPIO_PIN_4          // PF4 - SW1 (active low, pull-up)
#define LED_RED      GPIO_PIN_1          // PF1
#define LED_BLUE     GPIO_PIN_2          // PF2
#define LED_GREEN    GPIO_PIN_3          // PF3
#define LED_ALL      (LED_RED | LED_BLUE | LED_GREEN)

// State counter: 0..7, advanced on each rising edge (button release)
// init step number as global variable 
static volatile uint8_t step = 0;

void GPIOPortFIntHandler(void);

int main(void)
{
    // --- System clock: 16 MHz xtal -> 400 MHz PLL -> /10 = 40 MHz ---
    SysCtlClockSet(SYSCTL_SYSDIV_5 | SYSCTL_USE_PLL |
                   SYSCTL_XTAL_16MHZ | SYSCTL_OSC_MAIN);
    SysCtlPeripheralEnable(SYSCTL_PERIPH_GPIOF);

    // --- Configure LEDs (PF1, PF2, PF3) as outputs, start OFF ---
    GPIOPinTypeGPIOOutput(GPIO_PORTF_BASE, LED_ALL);
    GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, 0x00);

    // --- Configure SW1 (PF4) as input with pull-up ---
    GPIOPinTypeGPIOInput(GPIO_PORTF_BASE, BUTTON_SW1);
    GPIOPadConfigSet(GPIO_PORTF_BASE, BUTTON_SW1,
                     GPIO_STRENGTH_2MA, GPIO_PIN_TYPE_STD_WPU);

    // --- Interrupt setup ---
    IntEnable(INT_GPIOF);
    GPIOIntRegister(GPIO_PORTF_BASE, GPIOPortFIntHandler);

    // RISING edge = button RELEASE
    GPIOIntTypeSet(GPIO_PORTF_BASE, BUTTON_SW1, GPIO_RISING_EDGE);

    IntPrioritySet(INT_GPIOF, 7);
    GPIOIntEnable(GPIO_PORTF_BASE, GPIO_INT_PIN_4);

    // --- Global interrupts ---
    IntMasterEnable();

    while(1)
    {
        // Idle - all work happens in the ISR
    }
}

// --- ISR: fires on RISING edge of PF4 (button release) ---
void GPIOPortFIntHandler(void)
{
    // Clear the flag FIRST to avoid re-triggering
    GPIOIntClear(GPIO_PORTF_BASE, GPIO_INT_PIN_4);

    // Simple debounce (~a few ms at 40 MHz)
    SysCtlDelay(500000);

    // Advance the sequence
    switch(step)
    {
        case 0:  // ON RED
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, LED_RED);
            break;

        case 1:  // OFF RED
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, 0x00);
            break;

        case 2:  // ON BLUE
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, LED_BLUE);
            break;

        case 3:  // OFF BLUE
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, 0x00);
            break;

        case 4:  // ON GREEN
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, LED_GREEN);
            break;

        case 5:  // OFF GREEN
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, 0x00);
            break;

        case 6:  // ON ALL LEDS
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, LED_ALL);
            break;

        case 7:  // OFF ALL LEDS
            GPIOPinWrite(GPIO_PORTF_BASE, LED_ALL, 0x00);
            break;
    }

    // Next rising edge advances to next state (wraps 7 -> 0)
    step = (step + 1) % 8;
}

```





























