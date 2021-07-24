
; *****************************************************************************************
; SpriteDemo - video sprite functions based on a demo written by Richard Dienstknecht
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
                    dw  02000h          ; Program load address
                    dw  endrom-2000h    ; Program size
                    dw  02000h          ; Program execution address

                      ORG     02000h    ; code starts here
                    BR  start           ; Jump past build info to code

; Build information
binfo:              db  80H+7           ; Month, 80H offset means extended info
                    db  23              ; Day
                    dw  2021            ; Year

                    ; Current build number
build:              dw  4

                    ; Must end with 0 (null)
                    db  'Copyright 2021 Gaston Williams',0

; =========================================================================================
; Main
; =========================================================================================

start:							CALL IsVideoReady
                    GLO  RF                 ; RF.0 non-zero if video started
                    BNZ  loaded
                    LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT           ; return to Elf/OS
                        
loaded:             CALL ClearScreen        ; Clear the screen
                    CALL BigSprites				  ; Draw the sprites
										CALL UpdateVideo        ; show video updates
																																		 
										LBR O_WRMBOOT           ; return to Elf/OS
;------------------------------------------------------------------------------------------


; =========================================================================================
; Let's draw some big sprites!
; 
; Internal:
; R9 - Pointer to buffer page value
; RA.1 - X coordinate of the sprite (0-63)
; RA.0 - Y coordinate of the sprite (0-63)
; RB - Pointer to sprite bits
; RC - Pointer to video buffer memory
; RD.0 - Size of the sprite source in bytes
; RF - Pointer to sprite source
; =========================================================================================

BigSprites:			LDI  0008H		; The Klingon ship is actually made
								PLO  RA			  ; up of four sprites drawn next to
								LDI  0007H		; each other.
								PHI  RA
								
								LOAD RF, Klingon_0
								
								LDI  000FH
								PLO  RD
								CALL DrawSprite

								LDI  0010H
								PLO  RA
								LDI  0000H
								PHI  RA
								
								LOAD RF, Klingon_1
							
								LDI  000EH
								PLO  RD
								CALL DrawSprite

								LDI  0018H
								PLO  RA
								LDI  0003H
								PHI  RA
								
								LOAD RF, Klingon_2
								
								LDI  000BH
								PLO  RD
								CALL DrawSprite

								LDI  0020H
								PLO  RA
								LDI  000CH
								PHI  RA
								
								LOAD RF, Klingon_3
								
								LDI  000AH
								PLO  RD
								CALL DrawSprite

								LDI  0020H		; same with the Romulans
								PLO  RA
								LDI  0020H
								PHI  RA
								
								LOAD RF, Romulan_0
								
								LDI  000BH
								PLO  RD
								CALL DrawSprite

								LDI  0028H
								PLO  RA
								LDI  0025H
								PHI  RA
								
								LOAD RF, Romulan_1
								
								LDI  0008H
								PLO  RD
								CALL DrawSprite
								LDI  0030H
								PLO  RA
								LDI  0026H
								PHI  RA
								
								LOAD RF, Romulan_2
								
								LDI  0006H
								PLO  RD
								CALL DrawSprite

								LDI  0038H
								PLO  RA
								LDI  0020H
								PHI  RA
								
								LOAD RF, Romulan_3
								
								LDI  0008H
								PLO  RD
								CALL DrawSprite
								
								;--- draw the title on screen
								LOAD RF, SpriteTitle
								
								LDI  0DH
								PLO  RA     ; x value = 14
								LDI  32H
								PHI  RA     ; y value = 50
								
								CALL DrawString
								RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Graphics
; =========================================================================================

Klingon_0	db 0001H, 0003H, 0007H, 000FH, 000FH, 001FH, 0038H, 0070H	; offset 7
		db 00E0H, 00C0H, 00C0H, 00C0H, 0060H, 0060H, 0020H

Klingon_1	db 0006H, 0006H, 000FH, 007FH, 007FH, 007FH, 001FH, 00DFH	; offset 0
		db 00D9H, 00C9H, 00E6H, 00F0H, 00FFH, 001FH

Klingon_2	db 00E0H, 00E0H, 00E0H, 0080H, 00B8H, 00BCH, 003EH, 007FH	; offset 3
		db 00FFH, 00FFH, 0081H

Klingon_3	db 0080H, 00C0H, 00E0H, 0070H, 0030H, 0030H, 0030H, 0030H	; offset 12
		db 0060H, 0040H

;------------------------------------------------------------------------------------------

Romulan_0	db 0060H, 00F0H, 00F0H, 00F0H, 0060H, 0070H, 0038H, 001CH	; offset 0
		db 000FH, 0007H, 0003H

Romulan_1	db 0006H, 000FH, 007FH, 00FFH, 00FFH, 00F9H, 0039H, 000FH	; offset 5

Romulan_2	db 0001H, 00E3H, 00FFH, 00FEH, 00FCH, 00C0H			; offset 6

Romulan_3	db 0060H, 00F0H, 00F0H, 00F0H, 0060H, 00E0H, 00C0H, 0080H	; offset 0

;------------------------------------------------------------------------------------------

; =========================================================================================
; Strings
; =========================================================================================
failed:           db "Video is not started.",10,13,0
SpriteTitle:			db "Sprites!",0
;------------------------------------------------------------------------------------------

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
                  IF VideoCode == "MEM"
                      ORG 02200H 
                    INCLUDE "video/InitPicoElf.asm"
                  ENDIF

;----------------------------------------------------------------------------------------
; define end of execution block
endrom: EQU     $
