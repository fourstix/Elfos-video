; *******************************************************************************************
; Capture - Copy the display buffer to an image file
;
; Copyright (c) 2021 by Gaston Williams
; *******************************************************************************************
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
                        ORG     02000h-6        ; Header starts at 01ffah
                    dw  02000h                  ; Program load address
                    dw  endrom-2000h            ; Program size
                    dw  02000h                  ; Program execution address

                        ORG     02000h          ; code starts here
                    br  start                   ; Jump past build info to code

; Build information
binfo:              db  80H+5            ; April
                    db  11               ; Day
                    dw  2021             ; Year

                    ; Current build number
build:              dw  2

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0


start:              LDA	 RA		            ; ra -> command tail
                  	SMI	 ' '		          ; skip over spaces to find
                  	BZ	 start	          ; filename argument
                  	DEC	 RA
                  	GHI	 RA		            ; temp copy of argument address in rf
                  	PHI	 RF
                  	GLO	 RA
                  	PLO	 RF
findend:    	      LDA	 RF		            ; look for first non printable char
                  	SMI	 33	              ; (i.e. end of command tail)
                  	BDF	 findend
                  	DEC	 RF
                  	LDI	 0		            ; terminate command tail with NUL
                  	STR	 RF
                  	GHI	 RA		            ; ra -> start of filename argument
                  	PHI	 RF		            ; copy ra to rf
                  	GLO	 RA
                  	PLO	 RF
                  	LDN	 RF		            ; any argument?
                  	BNZ	 openfile		      ; if so, try opening it as a file
                    LOAD RF, usage
                  	CALL O_MSG		        ; otherwise display usage message
                  	RETURN  

openfile:           LOAD RD, fildes	      ; image file descriptor in RD
                    LDI  0
                    PHI  R7
                    LDI  3                ; flags, create if non-existant
                    PLO  R7
                    CALL O_OPEN           ; open file
                    BNF  filegood         ; jump if no error on open
                    
                    LOAD RF, errmsg
                    CALL O_MSG
                    RETURN                ; return to os

filegood:           CALL ValidateVideo    ; check if video is loaded                  
                    GLO  RF               ; RF.0 is zero if video loaded
                    BZ   loaded
                    LOAD RF, failed
                    CALL O_MSG
                    BR   close_exit

loaded:             LOAD R9, O_VIDEO      ; prepare the pointer to the video buffer
                    LDN  R9
                    PHI  RF
                    LDI  0
                    PLO  RF               ; video buffer address in RF
                    LOAD RD, fildes       ; RD points to file descriptor            
                    LOAD RC, 512          ; Put count into RC
                    CALL O_WRITE          ; write body
                    
close_exit:         LOAD RD, fildes       ; RD points to file descriptor 
                    CALL  O_CLOSE         ; close the file
                    RETURN                ; return to os
           
           


fildes:             db      0,0,0,0
                    dw      dta
                    db      0,0
                    db      0
                    db      0,0,0,0
                    dw      0,0
                    db      0,0,0,0
                    
            ;--- Message strings after video code
usage:              db      'Usage: capture imagefile',13,10,0
errmsg:             db      'File Error',10,13,0
failed:             db      "Video is not loaded.",13,10,0

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF

            ;------ define end of execution block
endrom:     equ     $

            ;------ data transfer area for fildes
dta:                ds      512
