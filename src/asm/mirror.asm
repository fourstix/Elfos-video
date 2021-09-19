; *******************************************************************************
; Mirror - Write strings from Elf/OS message functions to video display and to 
;          serial output.  Toggles function on and off.
;
; Copyright (c) 2021 by Gaston Williams
;
; ******************************************************************************
#include  ops.inc
#include  bios.inc
#include  kernel.inc

; ************************************************************
; Mirror is only supported when the video code located is in ROM
; ************************************************************                   
#include  video.inc                                       
                                                 
                      
; ==============================================================================
; Starting point of the program and initialization of the CPU registers
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
binfo:              db  80H+9           ; Month, 80H offset means extended info
                    db  17               ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  5

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
                        
loaded:             CALL IsMirrorOn         ; check mirror status
                    GLO  RF
                    BZ   turn_on            ; zero means mirror is off
                    CALL MirrorOff          ; turn mirror off
                    LOAD RF, mirror_off
                    CALL O_MSG
                    LBR  O_WRMBOOT          ; return to Elf/OS
                    
turn_on:            CALL MirrorOn           ; turn mirror on                    
                    LOAD RF, mirror_on
                    CALL O_MSG
                    LBR  O_WRMBOOT          ; return to Elf/OS
                    
failed:             db 'Video is not started.',10,13,0
mirror_on:          db 'Mirror is on.',10,13,0 
mirror_off:         db 'Mirror is off.',10,13,0                        
                      
;----------------------------------------------------------------------------------------
; define end of execution block
endrom: EQU     $
