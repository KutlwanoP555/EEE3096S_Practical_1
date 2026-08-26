/*
 * lcd.s
 * EEE3096S 2026 - Practical 1B, Task 5
 * 4-bit bit-banged HD44780 driver, and the level shifter timing fault
 *
 * Student 1 : <name>  <MNKSTE007>
 * Student 2 : <name>  <MKGKAR020>
 */

    .syntax unified
    .thumb
    .cpu    cortex-m0
    .fpu    softvfp

    .global LCD_Run
    .type   LCD_Run, %function

@ ---------------------------------------------------------------------------
@ Register addresses. BSRR is at offset 0x18 from each port base.
@ ---------------------------------------------------------------------------
    .equ GPIOA_BSRR, 0x48000018
    .equ GPIOB_BSRR, 0x48000418
    .equ GPIOC_BSRR, 0x48000818

@ ---------------------------------------------------------------------------
@ PIN MAP
@   PC15  Enable (E)     -> PC15_S on the 5 V side
@   PC14  Register Select (RS)
@   PB8   D4      PB9   D5      PA12  D6      PA15  D7
@   R/W is tied to ground. The LCD is write only. 
@ ---------------------------------------------------------------------------

    .section .text.LCD_Run, "ax", %progbits

@ ===========================================================================
@ ENTRY POINT
@ ===========================================================================
LCD_Run:
    PUSH {LR}

    @ TODO 1: Wait for the LCD power rail to settle (consult datasheet).
    BL  LCD_DelayLong @ Wait 10 ms for power rail to settle
    BL  LCD_DelayLong @ Wait 10 ms for power rail to settle
    BL  LCD_DelayLong @ Wait 10 ms for power rail to settle
    @ Might another delay be needed here? - safe is > 40ms
    BL  LCD_DelayLong @ Wait 10 ms for power rail to settle


    @ TODO 2: Call the 4-bit initialization sequence.
    BL LCD_Init # 
    @ TODO 3: Write the character 'A' (0x41) to the display.
    BL LCD_WriteData #0x41
hang:
    B    hang

    .size LCD_Run, .-LCD_Run

@ ===========================================================================
@ LCD_Init
@ Puts the controller into 4-bit mode and readies the display.
@ ===========================================================================
    .type LCD_Init, %function
LCD_Init:
    PUSH {LR}

    @ TODO 4: Send the 4-bit initialization sequence.
    @ Reference the HD44780 datasheet flowchart. 
    @ Send commands with RS low using LCD_WriteCmd.
    MOVS R0, #0x33 @ startup: send 0x3 nibble twice
    BL   LCD_WriteCmd
    BL   LCD_DelayLong @ wait > 4.1 ms

    MOVS R0, #0x32 @ startup: final handover to 4-bit mode
    BL   LCD_WriteCmd
    BL   LCD_DelayShort 
    BL  LCD_DelayShort @ wait > 100 us

    MOVS R0, #0x28 @ function set: 4-bit, 2-line, 5x8
    BL   LCD_WriteCmd
    MOVS R0, #0x0C @ display on, cursor off, blink off
    BL   LCD_WriteCmd
    MOVS R0, #0x06 @ entry mode: increment, no shift
    BL   LCD_WriteCmd
    MOVS R0, #0x01 @ clear display
    BL   LCD_WriteCmd
    BL   LCD_DelayLong @ clear/home needs long execution time


    POP {PC}

@ ===========================================================================
@ LCD_WriteCmd   R0 = command byte, RS low
@ LCD_WriteData  R0 = data byte,    RS high
@ Both send the high nibble first, then the low nibble.
@ ===========================================================================
    .type LCD_WriteCmd, %function
LCD_WriteCmd:
    PUSH {R0, LR}
    @ TODO 5: Drive RS (PC14) LOW, then fall through to the shared sender
    LDR  R1, =GPIOC_BSRR
    MOVS R2, #1
    LSLS R2, R2, #30     @ BSRR reset bit for PC14 (14 + 16)
    STR  R2, [R1]
    B    LCD_Send8

    .type LCD_WriteData, %function
LCD_WriteData:
    PUSH {R0, LR}
    @ TODO 6: Drive RS (PC14) HIGH, then fall through.
    LDR  R1, =GPIOC_BSRR
    MOVS R2, #1
    LSLS R2, R2, #14     @ BSRR set bit for PC14
    STR  R2, [R1]
    B    LCD_Send8


LCD_Send8:
    @ TODO 7: Send the upper nibble of R0, pulse Enable,
    @         then the lower nibble of R0, pulse Enable again.
    PUSH {R1, R2}

    MOV  R1, R0
    LSRS R0, R0, #4
    BL   LCD_SendNibble
    BL   LCD_Pulse

    MOV  R0, R1
    MOVS R2, #0x0F
    ANDS R0, R2
    BL   LCD_SendNibble
    BL   LCD_Pulse

    POP  {R1, R2}
    POP  {R0, PC}

@ ===========================================================================
@ LCD_SendNibble   R0 bits 3:0 -> the four data lines
@ ===========================================================================
    .type LCD_SendNibble, %function
LCD_SendNibble:
    PUSH {R1, R2, R3, LR}

    @ TODO 8: Map the four bits of R0 onto the four data pins (across 3 ports).
    @   R0 bit 0 -> PB8   (D4)
    @   R0 bit 1 -> PB9   (D5)
    @   R0 bit 2 -> PA12  (D6)
    @   R0 bit 3 -> PA15  (D7)
    MOV  R1, R0, LSL #4 @ Move D4 to PB8
    MOV  R2, R0, LSL #3 @ Move D5 to PB9
    MOV  R3, R0, LSL #8 @ Move D6 to PA12
    ORR  R3, R3, R0, LSL #12 @ Move D7 to PA15
    LDR  R2, =GPIOA_BSRR
    STR  R3, [R2] @ Write to GPIOA_BSRR
    LDR  R2, =GPIOB_BSRR
    STR  R2, [R2] @ Write to GPIOB_BSRR

    POP {R1, R2, R3, PC}

@ ===========================================================================
@ LCD_Pulse
@ ===========================================================================
    .type LCD_Pulse, %function
LCD_Pulse:
    PUSH {R0, R1, R2, LR}

    LDR  R0, =GPIOC_BSRR

    @ TODO 9: Set PC15 HIGH.
    MOVS R2, #1
    LSLS R2, R2, #15     @ BSRR set bit for PC15
    STR  R2, [R0]
    @ -----------------------------------------------------------------
    @ TODO 10: THE TIMING FIX
    @ Implement a calculated pad delay here to overcome the RC time 
    @ constant of the level shifter and meet the HD44780 hold time requirements.
    @ Show your cycle arithmetic in the comments.
    @ -----------------------------------------------------------------

    @ TODO 11: Set PC15 LOW.
    MOVS R2, #1
    LSLS R2, R2, #31     @ BSRR reset bit for PC15
    STR  R2, [R0]

    @ TODO 12: Hold Enable low long enough to meet the LCD cycle time.
    BL LCD_DelayShort @ wait > 55 us   
    POP {R0, R1, R2, PC}

@ ===========================================================================
@ Delay helpers
@ ===========================================================================
    .type LCD_DelayLong, %function

LCD_DelayLong:
    @ TODO 13: Implement a millisecond-scale delay. Show cycle arithmetic.
    LDR  R0, =80000 @ Approximate cycles per millisecond at 8 MHz 10 ms delay
delay_loop_long:
    SUBS R0, R0, #1
    BNE delay_loop_long
    BX   LR

    .type LCD_DelayShort, %function
LCD_DelayShort:
    @ TODO 14: Implement a microsecond-scale delay. Show cycle arithmetic.
    LDR  R0, =440 @ Approximate cycles per microsecond at 8 MHz 10 us delay
delay_loop_short:
    SUBS R0, R0, #1
    BNE delay_loop_short
    BX   LR