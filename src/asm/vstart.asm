; -------------------------------------------------------------------
; Turn pixie video on
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
                            ORG     02000h-6        ; Header starts at 01ffah
                    dw      02000h          ; Program load address
                    dw      endrom-2000h    ; Program size
                    dw      02000h          ; Program execution address

                            ORG     02000h          ; code starts here
                    br     start            ; Jump past build info to code

; Build information
binfo:              db      80H+7           ; Month, 80H offset means extended info
                    db      11              ; Day
                    dw      2021            ; Year

; Current build number
build:              dw      3

                    ; Must end with 0 (null)
                    db      'Copyright 2021 Gaston Williams',0
            
start:              CALL ValidateVideo          ; check if video is already loaded
                    GLO  RF
                    BNZ  allocate
                    BR   loaded 
            
allocate:           CALL AllocateVideoBuffers   ; allocate video buffers in himem
            
                    CALL ValidateVideo          ; validate video drivers loaded okay
                    GLO RF
                    BZ verbose
                    LOAD RF, failed
                    CALL O_MSG 
                    NOP
                    LBR O_WRMBOOT 
                    
verbose:            LOAD RF, descript           ; show description and copyright
                    CALL O_MSG
                    LOAD RF, notice  
                    CALL O_MSG
                                        
loaded:             CALL VideoOn                ; turn video on
                    LOAD RF, started  
                    CALL O_MSG              
                    LBR O_WRMBOOT               ; return to Elf/OS 
                    
                                
failed:             db   "Video drivers failed to load.",10,13,0
started:            db   "Video started.",10,13,0
descript:           db   "Elf/OS 1861 Pixie Video Drivers v3.01",10,13,0
notice:             db   "Copyright (c) 2021 by Gaston Williams",10,13,0
; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF

;------ define end of execution block
endrom: equ     $
