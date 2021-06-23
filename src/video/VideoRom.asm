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
                    CPU 1802

                    INCLUDE   bios.inc
                    INCLUDE   kernel.inc

                    INCLUDE   StdDefs.asm
                    INCLUDE   "bitfuncs.inc"                    

; =========================================================================================
; Reserved CPU registers
; R0            Pointer to the DMA buffer
; R1            Interrupt vector
; R2            Main stack pointer
; R3            Main program counter
; R4            Program counter for standard call procedure
; R5            Program counter for standard return procedure
; R6            Reserved for temporary values from standard call/return procedures
; RE.0          Used by Elf/OS to store accumulator in call procedures
; RE.1          Used by Elf/OS for baud rate
; =========================================================================================

                      ORG 09D00H 
                    INCLUDE "InitPicoElf.asm"

;------ define end of execution block
endrom: equ     $
