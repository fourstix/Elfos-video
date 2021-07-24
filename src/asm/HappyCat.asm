; *******************************************************************************************
; Snoopy - Draw a happy cat image on the screen 
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

								ORG     02000h-6    ; Header starts at 01ffah
							dw      2000h
							dw      endrom-2000h
							dw      2000h

								ORG     02000h      ; code starts here
							br  start             ; Jump past build info to code

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

binfo:				db	80h+7		; May
							db	23 			; Day
							dw	2021		; Year

build:				dw	4		; build
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
                        
loaded:             LOAD RF, happycat
										CALL Draw32x64Image
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
; Data for HappyCat graphic image
; ***************************************
happycat: 
  db	01DH,000H,000H,000H,000H,000H,000H,000H
  db	001H,040H,000H,000H,000H,000H,080H,000H
  db	015H,050H,000H,000H,000H,000H,080H,000H
  db	010H,07CH,000H,000H,000H,000H,080H,000H
  db	015H,02BH,000H,000H,000H,000H,080H,000H
  db	014H,01BH,0F8H,000H,000H,000H,080H,000H
  db	012H,055H,05EH,000H,000H,000H,080H,000H
  db	012H,015H,0ABH,0E0H,000H,000H,080H,000H
  db	011H,055H,055H,07FH,020H,000H,000H,000H
  db	01AH,0A5H,055H,050H,030H,071H,0C8H,080H
  db	009H,054H,0A2H,082H,080H,08AH,028H,080H
  db	01AH,0AAH,098H,008H,050H,082H,02CH,080H
  db	015H,055H,045H,045H,000H,083H,0EAH,080H
  db	014H,034H,0A4H,020H,020H,082H,029H,080H
  db	02BH,015H,052H,08AH,040H,08AH,028H,080H
  db	06DH,02AH,0A8H,080H,040H,072H,028H,080H
  db	05AH,05AH,094H,021H,080H,000H,000H,000H
  db	06BH,0DEH,0C3H,000H,040H,089H,0C7H,000H
  db	0BBH,06BH,008H,0ABH,080H,08AH,028H,080H
  db	0D5H,0DBH,044H,009H,0C0H,08AH,028H,000H
  db	0BBH,075H,0D2H,0AAH,080H,0FBH,0E7H,000H
  db	0CDH,0C5H,07AH,0AAH,0C0H,08AH,020H,080H
  db	055H,0A3H,0AAH,097H,040H,08AH,028H,080H
  db	0CAH,0EDH,0AAH,0A5H,060H,08AH,027H,000H
  db	092H,08EH,0AAH,0ABH,0A0H,000H,000H,000H
  db	040H,005H,055H,055H,0B0H,0FAH,00FH,09CH
  db	02AH,085H,02AH,0A5H,050H,082H,008H,022H
  db	028H,061H,050H,0B6H,0B0H,082H,008H,002H
  db	015H,058H,00AH,095H,058H,0E2H,00EH,004H
  db	005H,041H,048H,056H,0A8H,082H,008H,008H
  db	004H,0AAH,002H,0A9H,058H,082H,008H,000H
  db	004H,0AAH,0A0H,0ACH,028H,0FBH,0E8H,008H


; define end of execution block
endrom	equ	$		
