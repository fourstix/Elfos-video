; -------------------------------------------------------------------
; Turn pixie video off
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
                                           
; ************************************************************
; Define video code location as "ROM" or "MEM"
; ************************************************************                   
VideoCode EQU "ROM"

; ************************************************************
; Include the video definitions in the ROM
; ************************************************************                        
           IF VideoCode == "ROM"
             INCLUDE     video.inc                                          
           ENDIF                                                      

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

; ************************************************************
; This block generates the Execution header
; It occurs 6 bytes before the program start.
; ************************************************************
                        ORG     02000h-6  ; Header starts at 01ffah
                    dw  02000h            ; Program load address
                    dw  endrom-2000h      ; Program size
                    dw  02000h            ; Program execution address

                        ORG     02000h    ; code starts here
                    br  start             ; Jump past build info to code

; Build information
binfo:              db  80H+7             ; Month, 80H offset means extended info
                    db  23                ; Day
                    dw  2021              ; Year

; Current build number
build:              dw  4

; Must end with 0 (null)
                    db      'Copyright 2021 Gaston Williams',0
                  
start:              LDA  RA                 ; move past any spaces
                    SMI  ' '
                    BZ   start
                    DEC  RA                 ; move back to non-space character
                    LDA  RA                 ; check for nonzero byte
                    BZ   check              ; jump if no arguments
                    SMI '-'                 ; check for argument
                    BNZ bad_arg
                    LDN RA                  ; check for correct argument
                    SMI 'u'
                    BZ   unload
                    BR   bad_arg            ; anything else is a bad argument  

check:              CALL ValidateVideo      ; RF.0 nonzero if drivers loaded
                    GLO  RF
                    BNZ  fail               ; fail if drivers are not loaded
                    
                    CALL VideoOff           ; stop the video
                    BR   done
                                   
bad_arg:            LOAD RF, usage          ; print bad arg message and end
                    CALL O_MSG
                    LBR O_WRMBOOT
                    
unload:             CALL ValidateVideo      ; check for video first
                    GLO  RF
                    BNZ  fail               ; fail if drivers are not loaded
                    CALL IsEchoOn           ; see if echo is on
                    GLO  RF
                    BZ   continue
                    CALL EchoOff            ; turn off echo if needed
continue:           CALL VideoOff           ; always stop the video  
                    CALL UnloadVIdeo        ; unload the video drivers
                    GLO  RF
                    BZ   cleared            ; if successful print message
                    LOAD RF, cannot         ; otherwise, print unload error
                    CALL O_MSG
                    BR   done   
                                     
cleared:            LOAD RF, removed
                    CALL O_MSG 
                    LBR O_WRMBOOT       
                                            ; continue on to print stop message
done:               LOAD RF, stopped
                    CALL O_MSG
                    LBR O_WRMBOOT                  ; return to Elf/OS 
                      
fail:               LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT                  ; return to Elf/OS
                                   

failed:             db   "Video drivers are not loaded.",10,13,0
stopped:            db   "Video stopped.",10,13,0
usage:              db   "Stops video. Use vstop -u to unload video drivers.",10,13,0   
cannot:             db   "Cannot unload video drivers.",10,13,0
removed:            db   "Video drivers unloaded.",10,13,0
            
; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF
            
;------ define end of execution block
endrom: equ     $
