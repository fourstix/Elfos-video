; *******************************************************************************************
; Echo - Write strings from Elf/OS message functions to video display and serial output
;
; Copyright (c) 2021 by Gaston Williams
;
; *******************************************************************************************
                      CPU 1802

                      INCLUDE   bios.inc
                      INCLUDE   kernel.inc

                      INCLUDE   StdDefs.asm
                      INCLUDE   "bitfuncs.inc"

; ************************************************************
; Echo is only supported when the video code located is in ROM
; ************************************************************                   
                    INCLUDE     video.inc                                          
                                                 
                      
; =========================================================================================
; Starting point of the program and initialization of the CPU registers
; R0            Reserved as pointer to the DMA buffer
; R1            Reserved as interrupt vector
; R2            Main stack pointer
; R3            Main program counter
; R4            Program counter for standard call procedure
; R5            Program counter for standard return procedure
; R6            Reserved for temporary values from standard call/return procedures
; RE.0          Used by Elf/OS to store accumulator in call procedures
; RE.1          Used by Elf/OS for baud rate
; =========================================================================================

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
                      ORG     02000h-6  ; Header starts at 01ffah
                    dw  02000h          ; Program load address
                    dw  endrom-2000h    ; Program size
                    dw  02000h          ; Program execution address

                      ORG     02000h    ; code starts here
                    BR  start           ; Jump past build info to code

; Build information
binfo:              db  80H+7           ; Month, 80H offset means extended info
                    db  9               ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  3

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:              CALL ValidateVideo      ; check if video is loaded
                    GLO  RF                 ; zero if video loaded
                    BZ   loaded
                    LOAD RF, failed
                    CALL O_MSG
                    LBR  O_WRMBOOT          ; return to Elf/OS
                        
loaded:             CALL IsEchoOn           ; check echo status
                    GLO  RF
                    BZ   turn_on            ; zero means echo is off
                    CALL EchoOff            ; turn echo off
                    LOAD RF, echo_off
                    CALL O_MSG
                    LBR  O_WRMBOOT          ; return to Elf/OS
                    
turn_on:            CALL EchoOn             ; turn echo on                    
                    LOAD RF, echo_on
                    CALL O_MSG
                    LBR  O_WRMBOOT          ; return to Elf/OS
                    
failed:             db "Video is not started.",10,13,0
echo_on:            db "Echo is on.",10,13,0 
echo_off:           db "Echo is off.",10,13,0                        
                      
;----------------------------------------------------------------------------------------
; define end of execution block
endrom: EQU     $
