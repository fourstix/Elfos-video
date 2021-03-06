; *******************************************************************************************
; StringTest - Write strings to the display using the PrintString function
;
; Copyright (c) 2021 by Gaston Williams
;
; *******************************************************************************************
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
                    dw  02000h            ; Program load address
                    dw  endrom-2000h      ; Program size
                    dw  02000h            ; Program execution address

                        ORG     02000h    ; code starts here
                    br  start             ; Jump past build info to code

; Build information
binfo:              db  80H+9           ; Month, 80H offset means extended info
                    db  17              ; Day
                    dw  2021            ; Year

; Current build number
build:              dw  5

; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:              CALL IsVideoReady   ; RF.0 is non-zero if video ready
                    GLO  RF
                    BNZ  okay
                    LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT       ; return to Elf/OS
                    
okay:               CALL ClearScreen    ; update buffer with strings 
										CALL Lowercase
										CALL Uppercase
										CALL Numerals
                    
                    CALL UpdateVideo 		; update display
                    													
                    LBR O_WRMBOOT       ; return to Elf/OS
;-------------------------------------------------------------------------------


; ==============================================================================
; Lowercase - write the small alphabet letters to the screen
;
; Internals:
; RF - Pointer to String
; ==============================================================================

Lowercase:		LOAD RF, Alphabet			
        			CALL Print
        			RETURN
;-------------------------------------------------------------------------------			

; ==============================================================================
; Uppercase - write the Capital Alphabet letters to the screen
;
; Internals:
; RF - Pointer to String
; ==============================================================================

Uppercase:		LOAD RF, Capitals
        			CALL Print
        			RETURN
;-------------------------------------------------------------------------------

; ==============================================================================
; Numerals - write the numbers 0 through 9 to the screen
;
; Internals:
; RF - Pointer to String
; ==============================================================================

Numerals:		LOAD RF, Numbers			
      			CALL Println        ; end with newline
      			RETURN	
;-------------------------------------------------------------------------------

; ==============================================================================
; Strings for testing
; ==============================================================================

Alphabet:		db 'abcdefghijklmnopqrstuvwxyz',13,0
Capitals:		db 'ABCDEFGHIJKLMNOPQRSTUVWXYZ',10,0
Numbers:		db '0123456789',13,10,'!@#$%^&*()',13,10,'That',39,'s all, folks!',13,'Good-bye',0 

; ==============================================================================     
; Error messages     
; ============================================================================== 			
failed:     db 'Video is not started.',10,13,0      

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
#if VideoCode == MEM
  ORG 02200H 
#include VideoMem.asm  
#endif

; define end of execution block
endrom: EQU     $
