; -------------------------------------------------------------------
;  Test if Load video drivers are laoded in the HiMem of the Elf/OS
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
; Starting point of the program and initialization of the CPU registers
;
; R0            Reserved as pointer to the DMA buffer
; R1            Reserved as interrupt vector
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

                    ORG     02000h    ; code starts here
            br     start              ; Jump past build info to code

; Build information
binfo:      db      80H+9             ; Month, 80H offset means extended info
            db      17                ; Day
            dw      2021              ; Year

; Current build number
build:      dw      5

            ; Must end with 0 (null)
            db      'Copyright 2021 Gaston Williams',0

start:      CALL O_INMSG
            db 'Video drivers are ',0

            CALL ValidateVideo      ; see if video is loaded
            GLO RF
            bz already            
        
            CALL O_INMSG
            db '*NOT* loaded.',10,13,0
            LBR O_WRMBOOT
          
already:    CALL O_INMSG
            db 'loaded.',10,13,0
            
            CALL O_INMSG
            db   'Video is ',0
            CALL IsVideoReady       ; check if video is on
            GLO  RF
            bz   v_off
            
            CALL O_INMSG
            db   'ON.',10,13,0
            br   v_page
            
v_off:      CALL O_INMSG
            db   'OFF.',10,13,0

v_page:     CALL O_INMSG 
            db   'Video Page: ',0
              
            LOAD RF, O_VIDEO
            LDN  RF
            PHI  RD
            LDI  00H 
            PLO  RD
            
            LOAD RF, buffer
            CALL f_hexout4
            
            LOAD RF, buffer
            CALL O_MSG
        
; Mirror is only available when video routines are in ROM    
#if VideoCode == ROM        
            CALL O_INMSG
            db   'Mirror is ',0
            CALL IsMirrorOn            ; check mirror status
            GLO  RF
            BZ   mirror_off            ; zero means mirror is off
            CALL O_INMSG
            db 'ON.',10,13,0
            BR exit
mirror_off: CALL O_INMSG
            db 'OFF.',10,13,0        
#endif
               
exit:       LBR O_WRMBOOT            ; return to Elf/OS

buffer:     db 0,0,0,0,10,13,0

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
#if VideoCode == MEM
  ORG 02200H 
#include VideoMem.asm  
#endif
                  
        ;------ define end of execution block
endrom: equ     $
