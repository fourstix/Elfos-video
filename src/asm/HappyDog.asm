; *******************************************************************************************
; HappyDog - Draw a 512 byte image on the screen 
;
; Copyright (c) 2021 by Gaston Williams
; Based on a program written by Wayne Hortensius, 2021
; *******************************************************************************************
                        CPU 1802

                        INCLUDE   bios.inc
                        INCLUDE   kernel.inc

                        INCLUDE   StdDefs.asm
                        INCLUDE   "bitfuncs.inc"
                        
; ************************************************************
; Define video code location as "ROM" or "MEM"
; ************************************************************                   
VideoCode EQU "MEM"

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
; This block generates the Execution header for a stand-alone
; program. It begins 6 bytes before the program start.
; ************************************************************

								ORG     02000h-6      ; Header starts at 01ffah
							dw      2000h
							dw      endrom-2000h
							dw      2000h

								ORG     02000h        ; code starts here
							br  start               ; Jump past build info to code

; **************************************************
; *** Build information:                         ***
; ***    build date                              ***
; ***    build number                            ***
; ***    information text string                 ***
; **************************************************
; Build date format:
; 80h+month, day, four digit year
; **************************************************
; 80h month offset indicates extended
; build information, with build number and text.
; **************************************************

binfo:				db	80h+7		; Month
							db	23 			; Day
							dw	2021		; Year

build:				dw	4	      ; build
							db	'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:              CALL IsVideoReady
                    GLO  RF                 ; RF.0 non-zero if video started
                    BNZ  loaded
                    LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT           ; return to Elf/OS
                        
loaded:             LOAD RF, doggie
										CALL Draw64x64Image
										CALL UpdateVideo        ; update display              
                                      																	                                              
                    LBR O_WRMBOOT           ; return to Elf/OS

;----------------------------------------------------------------------------------------
   
failed:   db "Video is not started.",13,10,0       

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF


; ***************************************
; Data for 64x64 graphic image
; ***************************************
doggie: 
	db	080h,000h,000h,000h,000h,080h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,000h,000h,000h
	db	000h,000h,000h,000h,000h,001h,0ffh,0ffh
	db	000h,000h,000h,000h,000h,002h,000h,001h
	db	000h,000h,020h,000h,030h,002h,000h,002h
	db	000h,000h,000h,000h,078h,001h,0ffh,0feh
	db	000h,000h,000h,07fh,087h,0f8h,020h,000h
	db	000h,000h,000h,040h,030h,008h,020h,000h
	db	000h,000h,000h,07fh,087h,0f0h,020h,000h
	db	000h,000h,000h,000h,07ah,020h,020h,000h
	db	000h,040h,000h,000h,031h,010h,020h,020h
	db	000h,000h,000h,000h,000h,0c8h,020h,000h
	db	000h,000h,000h,000h,001h,03fh,0f8h,000h
	db	000h,000h,000h,000h,002h,000h,008h,000h
	db	000h,000h,000h,080h,006h,0fch,008h,000h
	db	000h,003h,080h,000h,002h,001h,0f8h,000h
	db	00Ch,007h,0c0h,000h,001h,00eh,000h,000h
	db	01Eh,00fh,0e0h,000h,000h,0f0h,000h,000h
	db	03Fh,0bfh,0f0h,000h,000h,000h,000h,000h
	db	037h,0ffh,0f8h,000h,000h,000h,000h,000h
	db	067h,0ffh,0e8h,002h,000h,000h,000h,000h
	db	067h,0ffh,0f8h,000h,000h,000h,000h,000h
	db	043h,0bfh,0f8h,000h,000h,004h,000h,000h
	db	0c3h,0bfh,0f0h,000h,000h,000h,000h,000h
	db	083h,0ffh,0e0h,000h,000h,000h,000h,000h
	db	083h,0ffh,0c0h,000h,000h,000h,000h,000h
	db	081h,0e0h,000h,000h,000h,000h,000h,000h
	db	081h,0c0h,000h,000h,000h,000h,000h,002h
	db	081h,0c0h,000h,000h,000h,000h,000h,000h
	db	081h,0c0h,000h,000h,000h,000h,000h,000h
	db	081h,0c0h,000h,000h,000h,000h,000h,000h
	db	0c1h,0e0h,000h,000h,000h,000h,000h,000h
	db	0c1h,0feh,000h,000h,000h,000h,000h,000h
	db	061h,0feh,000h,000h,000h,000h,000h,000h
	db	063h,0feh,000h,000h,000h,000h,000h,000h
	db	03fh,0fch,000h,000h,000h,000h,000h,000h
	db	03fh,0f8h,000h,000h,000h,000h,000h,000h
	db	003h,0f0h,030h,000h,000h,000h,000h,000h
	db	003h,0f0h,070h,0eeh,0e3h,0bbh,0abh,0b8h
	db	000h,0f8h,0f0h,0a8h,0a2h,02ah,03ah,0a0h
	db	000h,0fdh,0e0h,0e8h,0e2h,02bh,0bbh,0a0h
	db	000h,07fh,0c0h,0c8h,0a2h,028h,0aah,0a0h
	db	000h,07fh,080h,0aeh,0a3h,0bbh,0aah,0b8h
	db	000h,06fh,000h,000h,000h,000h,000h,000h
	db	000h,06fh,000h,000h,000h,000h,000h,000h
	db	000h,077h,080h,01dh,0d5h,0d5h,0ddh,0c0h
	db	000h,077h,080h,011h,05dh,054h,091h,040h
	db	000h,05bh,0c0h,011h,05dh,0d4h,099h,0c0h
	db	000h,05bh,0c0h,011h,055h,014h,091h,080h
	db	000h,06dh,0c0h,01dh,0d5h,01ch,09dh,040h
	db	000h,06dh,0c0h,000h,000h,000h,000h,000h
	db	000h,06dh,0c0h,000h,000h,000h,000h,000h
	db	000h,06dh,0c0h,000h,000h,000h,000h,000h
	db	000h,033h,080h,000h,000h,000h,000h,000h
	db	0ffh,03fh,03fh,0ffh,0ffh,0ffh,0ffh,0ffh
	db	000h,01fh,000h,000h,000h,000h,000h,000h
	db	000h,00eh,000h,000h,000h,000h,000h,000h
	db	000h,00eh,000h,000h,000h,000h,000h,000h
	db	000h,00eh,000h,000h,000h,000h,000h,000h
	db	000h,01fh,080h,000h,000h,000h,000h,000h
	db	000h,03fh,0c0h,000h,000h,000h,000h,000h
	db	000h,03fh,0c0h,000h,000h,000h,000h,000h


; define end of execution block
endrom	equ	$		
