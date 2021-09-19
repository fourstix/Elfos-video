; *******************************************************************************************
; PixelDemo - Draw lines on the screen using DrawPixel function
;
; Copyright (c) 2021 by Gaston Williams
; Based on a program written by Wayne Hortensius, 2021
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

binfo:				db	80h+9		; Month
							db	17 			; Day
							dw	2021		; Year

build:				dw	5	      ; build
							db	'Copyright 2021 Gaston Williams',0

; ==============================================================================
; Main
; ==============================================================================

start:              CALL IsVideoReady
                    GLO  RF                 ; RF.0 non-zero if video started
                    BNZ  loaded
                    LOAD RF, failed
                    CALL O_MSG
                    LBR O_WRMBOOT           ; return to Elf/OS
                        
loaded:             LOAD RB, 00H            ; set up counter in RB

                    CALL ClearScreen        ; clear all pixels before drawing
                      
drawframe:          GLO  RB                 ; get count
                    SDI  03FH               ; compare with end 
                    BNF  innerbox           ; draw inner box after frame complete
                    
                    PLO  RA                 ; put difference in Y
                    GLO  RB                 ; diagonal line is (i, 63-i)
                    PHI  RA                 ; put count in X
                    CALL DrawPixel          ; set pixel for first diagonal line
                    
                    GLO  RB                 ; second diagonal line is (i, i)
                    PLO  RA                 ; put count in X
                    PHI  RA                 ; put same value in Y
                    CALL DrawPixel          ; set pixel for second diagonal line
                    
                    GLO  RB                 ; left border (0, i)
                    PHI  RA                 ; put count in y
                    LDI  00H                ; 0 is the far left 
                    PLO  RA                 ; put left border value in X
                    CALL DrawPixel          ; set pixels for left border line
                    
                    GLO  RB                 ; right border (3F, i)
                    PHI  RA                 ; put count in y
                    LDI  03FH               ; 63 is the far right 
                    PLO  RA                 ; put right border value in X
                    CALL DrawPixel          ; set pixels for right border line
                    
                    GLO  RB                 ; top border (i,0)
                    PLO  RA                 ; put count in X
                    LDI  00H                ; 0 is the top 
                    PHI  RA                 ; put top border value in X                    
                    CALL DrawPixel          ; set pixels for top border line
                    
                    GLO  RB                 ; bottom border (i, 3F)
                    PLO  RA                 ; put count in y
                    LDI  03FH               ; 63 is the bottom 
                    PHI  RA                 ; put bottom border value in X
                    CALL DrawPixel          ; set pixels for bottom border line
                     
                    INC  RB                 ; bump counter
                    BR   drawframe          ; continue to draw frame              
                    
innerbox:           LOAD RB, 010H           ; draw a box inside the frame

drawbox:            GLO  RB                 ; get count
                    SDI  030H               ; compare with end                    
                    BNF  update             ; finished draw pixels, update display
                    
                    GLO  RB                 ; draw top of box (i, 10H)
                    PLO  RA                 ; put count in X
                    LDI  010H               ; put box top value in Y
                    PHI  RA
                    CALL DrawPixel          ; set pixels for box top
                    
                    GLO  RB                 ; draw bottom of box (i, 30H)
                    PLO  RA                 ; put count in X
                    LDI  030H               ; put box bottom value in Y
                    PHI  RA
                    CALL DrawPixel          ; set pixels for box bottom
                    
                    GLO  RB                 ; draw left side of box (10H, i)
                    PHI  RA                 ; put count in Y
                    LDI  010H               ; put box left side value in X
                    PLO  RA
                    CALL DrawPixel          ; set pixels for box left side
                    
                    GLO  RB                 ; draw right side of box (30H, i)
                    PHI  RA                 ; put count in Y
                    LDI  030H               ; put box right side value in X
                    PLO  RA     
                    CALL DrawPixel          ; set pixels for box right side
                    
                    INC  RB                 ; bump counter
                    BR   drawbox            ; continue drawing until box is done              
                    
update:             CALL UpdateVideo        ; show pattern on display
                                      																	                                              
                    LBR O_WRMBOOT           ; return to Elf/OS

;----------------------------------------------------------------------------------------
   
failed:   db 'Video is not started.',13,10,0       

; ************************************************************
; Assemble video routines in memory
; ************************************************************                        
#if VideoCode == MEM
  ORG 02200H 
#include VideoMem.asm  
#endif

; define end of execution block
endrom:	equ	$		
