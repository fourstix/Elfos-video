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
#include  ops.inc
#include  bios.inc
#include  kernel.inc

; ************************************************************
; Define video code location in ROM or Memory
; ************************************************************                   
#include  location.inc

; ************************************************************
; Include the video definitions in the ROM
; ************************************************************                        
#if VideoCode == ROM
#include  video.inc                                          
#endif                                                      

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
binfo:              db      80H+9       ; Month, 80H offset means extended info
                    db      17          ; Day
                    dw      2021        ; Year

; Current build number
build:              dw      5

                    ; Must end with 0 (null)
                    db   'Copyright 2021 Gaston Williams',0
            
start:              LDA  RA                 ; move past any spaces
                    SMI  ' '
                    BZ   start
                    DEC  RA                 ; move back to non-space character
                    LDA  RA                 ; check for nonzero byte
                    BZ   check              ; jump if no arguments
                    SMI '-'                 ; check for argument
                    BNZ bad_arg
                    LDN RA                  ; check for correct argument
                    SMI 'i'
                    BZ  simple             ; set flag for return rather than warm boot
                    
bad_arg:            LOAD RF, usage          ; print bad arg message and end
                    CALL O_MSG
                    BR  exit

simple:             LOAD RF, r_type         ; point RF to return flag
                    LDI  0FFH               ; load flag for simple return
                    STR  RF                 ; set flag and continue

check:              CALL ValidateVideo      ; check if video is already loaded
                    GLO  RF                 ; RF.0 = zero, means already loaded
                    BZ   loaded                 
            
                    CALL AllocateVideoBuffers   ; allocate video buffers in himem
                    GLO  RF                     ; check the return flag
                    BNZ  no_mem                 ; non-zero means Elf/OS alloc failed
                     
                    CALL ValidateVideo      ; validate video drivers loaded okay
                    GLO RF                  ; RF.0 is zero, if valid
                    BNZ invalid             ; drivers failed to load for some reason
                                        
                    LOAD RF, descript       ; show video driver description 
                    CALL O_MSG
                    LOAD RF, k_version      ; show kernel version info
                    CALL O_MSG
                    LOAD RF, notice         ; show copyright notice
                    CALL O_MSG
                                        
loaded:             CALL VideoOn            ; turn video on
                    LOAD RF, started  
                    CALL O_MSG              
                    BR  exit                ; return to Elf/OS 

no_mem:             LOAD RF, not_alloc      ; show no memory available error
                    CALL O_MSG

invalid:            LOAD RF, failed         ; show driver failed to load error
                    CALL O_MSG 
                    
exit:               LOAD RF, r_type         ; check the return type flag
                    LDN  RF                 ; get the flag
                    BZ   safe               ; if flag zero, do safe return

                    RETURN                  ; simple return to Elf/OS
                    
safe:               LBR O_WRMBOOT           ; return to Elf/OS            
                    
r_type:             db   0                    
not_alloc:          db   'Elf/OS memory not allocated.',10,13,0                                
failed:             db   'Video drivers failed to load.',10,13,0
started:            db   'Video started.',10,13,0
descript:           db   'Elf/OS 1861 Pixie Video Drivers v4.01',10,13,0
k_version:          db   'For Elf/OS Kernel version 0.4.0 and higher.',10,13,0
notice:             db   'Copyright (c) 2021 by Gaston Williams',10,13,0
usage:              db   'Start video. Use vstart -i to load video drivers from init.rc',10,13,0

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
#if VideoCode == MEM
  ORG 02200H 
#include VideoMem.asm  
#endif


;------ define end of execution block
endrom: equ     $
