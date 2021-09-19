; -------------------------------------------------------------------
; Elf/OS video functions located in ROM
; -------------------------------------------------------------------
; Based on software written by Michael H Riley
; Thanks to the author for making this code available.
; Original author copyright notice:
; *******************************************************************
; *** This software is copyright 2004 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************

; ******************************************************************************
; Original Code Copyright (c) 2020
; by Richard Dienstknecht
; Modified Code Copyright (c) 2021
; by Gaston Williams
;
; Changes:
; Gaston Williams, Feb,  2021 - Updated code for Pico/Elf
; Gaston Williams, Sept, 2021 - refactored files for Asm/02 assembler
; ******************************************************************************

.list
#include ops.inc
#include bios.inc
#include kernel.inc

********************************************************************************
; *** This defines the location in the kernel for video buffer page address. ***
; ******************************************************************************                    
O_VIDEO:            EQU  03D0H  

; ==============================================================================
; Reserved CPU registers
; R0            Pointer to the DMA buffer
; R1            Interrupt vector
; R2            Main stack pointer
; R3            Main program counter
; R4            Program counter for standard call procedure
; R5            Program counter for standard return procedure
; R6            Temporary values for standard call/return procedures
; RE.0          Used by Elf/OS to store accumulator in call procedures
; RE.1          Used by Elf/OS for baud rate
; ==============================================================================

    ORG 09D00H 
; ==============================================================================
; Support 64 x 64 resolution, No double-buffering
; ==============================================================================
#include Fonts.asm  
#include Graphics1861.asm
#include Text1861.asm                                                              
#include Tty1861.asm

;------ define end of execution block
endrom: equ     $
