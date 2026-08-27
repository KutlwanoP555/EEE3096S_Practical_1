/*
 * dsp.s
 * EEE3096S 2026 - Practical 1B, Task 4
 * Cycle-counted ADC to DAC loop with a 45 degree phase delay
 *
 * Student 1 : <name>  <student number>
 * Student 2 : <name>  <student number>
 */

    .syntax unified
    .thumb
    .cpu    cortex-m0
    .fpu    softvfp

    .global DSP_Loop
    .type   DSP_Loop, %function

@ ---------------------------------------------------------------------------
@ Peripheral addresses
@ ---------------------------------------------------------------------------
    .equ ADC_DR,      0x40012440
    .equ DAC_DHR12R1, 0x40007408

    .section .text.DSP_Loop, "ax", %progbits

@ ===========================================================================
@ ENTRY POINT
@ ===========================================================================
DSP_Loop:
    @ Setup registers outside the timed loop
    LDR R0, =ADC_DR
    LDR R1, =DAC_DHR12R1

loop:
    @ --- SAMPLE AND OUTPUT ------------------------------------------------
    @ TODO 1: Read the current ADC conversion from the Data Register.
    LDR R2 , [R0]  @ Read ADC value into R2 
    @ TODO 2: Write the value straight out to the DAC Data Register.
    STR R2, [R1] @ Write ADC value to DAC
    @ --- DELAY SETUP ------------------------------------------------------
    @ TODO 3: Calculate the required cycle target for a 45-degree phase 
    @         delay on a 1 kHz sine wave running at an 8 MHz system clock.
    @         Load your inner loop counter and insert any NOP padding 
    @         needed to hit your exact target.
    @ Calculation:
    @   1 kHz period       = 1 / 1000 Hz = 1 ms
    @   45-degree delay    = 1 ms / 8 = 125 us
    @   8 MHz clock        = 8,000,000 cycles/s
    @   Delay target       = 125 us * 8 MHz = 1000 cycles
    @
    @ Let x be the delay-loop count. The cycle cost is:
    @   LDR + STR + MOVS + SUBS + BNE + B loop
    @   1 + 1 + 1 + x + 3(x - 1) + 1 + 3 = 4x + 4
    @
    @   4x + 4 = 1000
    @   x = 249 iterations
    MOVS R3, #249       @ Load the calculated delay-loop count

delay_loop:
    @ --- INNER LOOP -------------------------------------------------------
    @ TODO 4: Implement the counted delay loop.
    @         (Remember to use flag-updating arithmetic so your branch works).

    SUBS R3, R3, #1 @ Subtract 1 from R3 and update the flags
    BNE delay_loop  @ 3 cycles taken, 1 cycle on the final not-taken branch
    @ --- REPEAT -----------------------------------------------------------
    @ TODO 5: Branch back to the start of the main 'loop'.
    B loop @ back to the start of the main loop
    @ ----------------------------------------------------------------------
    @ NOTE: You must calculate your exact cycle budget, showing the cost 
    @ of every instruction and loop iteration, and document it in your report.
    @ ----------------------------------------------------------------------

    .size DSP_Loop, .-DSP_Loop