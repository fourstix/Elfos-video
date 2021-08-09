; *******************************************************************************************
; CharSet - Write printable characters to the display using the PutChar function
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
; Starting point of the program and initialization of the CPU registers
;
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
                        ORG     02000h-6    ; Header starts at 01ffah
                    dw  02000h              ; Program load address
                    dw  endrom-2000h        ; Program size
                    dw  02000h              ; Program execution address

                        ORG     02000h      ; code starts here
                    br  start               ; Jump past build info to code

; Build information
binfo:              db  80H+8           ; Month, 80H offset means extended info
                    db  8               ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  4

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:              CALL IsVideoReady      ; RF.0 is non-zero if ready
                    GLO  RF
                    BNZ  loaded
                    LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT         ; return to Elf/OS
                        
loaded:             CALL ClearScreen

                    CALL printChars       ; print ascii chars 32-126	
                        							
                    CALL UpdateVideo      ; update display              
                                      																	                                              
                    LBR O_WRMBOOT         ; return to Elf/OS
       
;----------------------------------------------------------------------------------------
   
; =========================================================================================
; PrintChars - write the printable ascii letters to the screen
;
; Internals:
; R9 - Counter for characters
; RC.0 - Character to write to screen
; =========================================================================================

PrintChars:         LOAD R9, 0020H          ; Start with the space char (32)
next_char:          GLO  R9     
                    PLO  RC
                    PUSH R9                 ; Save counter to stack
			              CALL PutChar            ; print it to display buffer
                    POP  R9                 ; Restore counter from stack
                    INC  R9
                    GLO  R9
                    SDI  007FH              ; quit when we reach DEL (127)
                    BNZ  next_char          ; otherwise keep printing              

			              RETURN
;------------------------------------------------------------------------------------------			

failed:   db "Video is not started.",13,10,0

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF
                           
; define end of execution block
endrom:   EQU     $
