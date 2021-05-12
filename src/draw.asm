; *******************************************************************************************
; Draw - Draw an image file on the display
;
; Copyright (c) 2021 by Gaston Williams
;
; Based on the Pix program written by Wayne Hortensius  2021
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
                        ORG     02000h-6  ; Header starts at 01ffah
                    dw  02000h            ; Program load address
                    dw  endrom-2000h      ; Program size
                    dw  02000h            ; Program execution address

                        ORG     02000h    ; code starts here
                    br  start             ; Jump past build info to code

; Build information
binfo:              db  80H+5           ; May
                    db  11              ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  2

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0


start:              LDA	RA		; ra -> command tail
                  	SMI	' '		; skip over spaces to find
                  	BZ	start	; filename argument
                  	DEC	RA
                  	GHI	RA		; temp copy of argument address in rf
                  	PHI	RF
                  	GLO	RA
                  	PLO	RF
find_end:           LDA	RF		; look for first non printable char
                  	SMI	33	  ; (i.e. end of command tail)
                  	BDF	find_end
                  	DEC	RF
                  	LDI	0		  ; terminate command tail with NUL
                  	STR	RF
                  	GHI	RA		; ra -> start of filename argument
                  	PHI	RF		; copy ra to rf
                  	GLO	RA
                  	PLO	RF
                  	LDN	RF		         ; any argument?
                  	BNZ  	check_video  ; yep, try opening it as a file
                    LOAD  RF,usage
                  	CALL	O_MSG		     ; otherwise display usage message
                  	RETURN

                    ; Check video then see if we can open the file 
check_video:        PUSH RF                 ; save RF on stack
                    CALL IsVideoReady
                    GLO  RF                 ; RF.0 non-zero if video started
                    BNZ  open_img
                    POP  RF                 ; restore stack location
                    LOAD RF, failed
                    CALL O_MSG
                    RETURN

open_img:           POP  RF              ; retore RF
                    LOAD RD,fildes	     ; image file descriptor
                    LDI	 0		           ; (no create, no truncate, no append) flags
                    PLO	 R7
                    PHI  R7
                    CALL O_OPEN		      ; attempt to open file
                    BNF  opened	        ; DF=0, file was opened
                    LOAD RF, not_found
                    CALL O_MSG
                    RETURN	            ; return to Elf/OS
                    
opened:         	  LOAD RC,512         ; read up to 512 bytes 
                    LOAD RF,buff1
                    LOAD RD,fildes
                    CALL O_READ		      ; read the image file
                    BDF  read_err 	    ; DF=1, read error
                    GLO	 RC		          ; check file size read
                    BNZ  size_err
                    GHI  RC
                    SMI  1              ; 32x64 size is 100H (256 bytes)
                    BZ   loaded32
                    SMI  1              ; 64x64 size is 200H (512 bytes)
                    BZ   loaded64 
                    BNZ  size_err       ; Anything else isn't supported
                    
                                            
loaded32:           LOAD RF,buff1
                    CALL Draw32x64Image
                    BR   update
loaded64:           LOAD RF,buff1
                    CALL Draw64x64Image                    
update:             CALL UpdateVideo        ; update display
                    
close_exit:         LOAD  RD,fildes
                    CALL	O_CLOSE		        ; close the image file
                    RETURN      	          ; return to Elf/OS

                    
size_err:         	LOAD  RF,bad_size
                    CALL	O_MSG                	
                    BR	 close_exit
                    
read_err:         	LOAD RF,bad_read
                    CALL O_MSG                  	
                  	BR	 close_exit
                    
fildes:             db	0,0,0,0
                    dw	dta
                    db	0,0
                    db	0
                    db	0,0,0,0
                    dw	0,0
                    db	0,0,0,0
                     
        ;--- Message strings after video code
usage:              db	'Usage: draw imagefile',13,10,0
not_found:          db	'File not found',13,10,0
bad_size:           db	'Incorrect image file size',13,10,0
bad_read:           db	'Error reading image file',13,10,0
failed:             db  'Video is not started.',13,10,0

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF

        ;------ define end of execution block
endrom: equ     $

;--- file data transfer buffer
dta:	           ds	512
;--- image data buffer
buff1:	         ds	512
