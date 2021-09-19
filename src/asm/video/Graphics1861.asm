; *****************************************************************************************
; Copyright (c) 2020
; by Richard Dienstknecht
;
; Changes:
; Gaston Williams, February, 2021 - Updated to use Buffer pointer
; *****************************************************************************************

; =========================================================================================
; Interrupt and DMA service routine for the CDP1861 to display an effective resolution
; of 64 x 64 pixels, using a display buffer of 512 bytes.
;
; Note: Interrupt service routine should have exactly 29 instruction cycles before DMA 
;       and use only registers R0, R1 and R2.  Thus, the oddities in this routine.
; =========================================================================================

INT_Exit:                       LDXA
                                RET
DisplayInt:                     NOP               ; 3 instruction cycles for NOP
                                DEC  R2
                                SAV               ; Save X,P on stack
                                DEC  R2
                                STR  R2           ; Save D on stack

                                LOAD R0, O_VIDEO  ; 8 instruction cycles in MACRO
                                LDA  R0                                
                                PHI  R0
                                LDI  00H
                                PLO  R0           ; 27 instruction cycles at this point
                                    
INT_Loop:                       GLO  R0           ; 2 instruction cycles
                                                  ; ------ DMA here ------
                                SEX  R2
                                DEC  R0
                                PLO  R0
                                                  ; ------ DMA here ------
                                SEX  R2
                                BN1  INT_Loop
INT_Rest:                       GLO  R0
                                                  ; ------ DMA here ------
                                SEX  R2
                                DEC  R0
                                PLO  R0
                                                  ; ------ DMA here ------
                                B1   INT_Rest
                                BR   INT_Exit


;------------------------------------------------------------------------------------------


; =========================================================================================
; Parameters:
; RF            Value for filling
;
; Internal:
; R9            Pointer to buffer page value
; RA            Pointer to video buffer
; =========================================================================================

FillScreen:                     LOAD R9, O_VIDEO   ; prepare the pointer to the video buffer
                                LDN  R9

                                PHI  RA

                                LDI  00H
                                PLO  RA

FS_Loop:                        GHI  RF
                                STR  RA
                                INC  RA
                                GLO  RA
                                BNZ  FS_Loop

                                LOAD R9, O_VIDEO   ; prepare the pointer to the video buffer
                                LDN  R9
                                ADI  01H           ; second video display buffer page at start + 1 

                                STR  R2
                                GHI  RA
                                SD
                                BDF  FS_Loop

                                RETURN
;------------------------------------------------------------------------------------------


; =========================================================================================
; Parameters:
; RA.0          X coordinate of the sprite
; RA.1          Y coordinate of the sprite
; RF            Pointer to sprite
; RD            Size of the sprite in bytes
;
; Internal:
; R9            Pointer to buffer page
; RC            Pointer to video memory
; RB            Pointer to sprite bits
; =========================================================================================

DrawSprite:                     LOAD R9, O_VIDEO   ; prepare the pointer to the video buffer
                                LDN  R9

                                PHI  RC                 ; DisplayBuffer + Y * 8 + X / 8
                                GHI  RA                 ; result goes to RC

                                ANI  3FH                ; or 0 - 63

                                SHL                     ; after two shifts check 64x128 high bit in df
                                SHL                     ; df will always be zero for 64x64 and 64x32

                                SHL
                                PLO  RC
                                BNF  DSP_SkipLowInc
                                GHI  RC
                                ADI  01H
                                PHI  RC

DSP_SkipLowInc:                 GLO  RC
                                STR  R2
                                GLO  RA
                                ANI  3FH
                                SHR
                                SHR
                                SHR
                                ADD
                                PLO  RC
                                GLO  RA                 ; calculate the number of required shifts
                                ANI  07H                ; result to RA.1, replacing the Y coordinate
                                PHI  RA                 ; RA.0 will be used later to count the shifts

DSP_ByteLoop:                   GLO  RD                 ; exit if all bytes of the sprite have been drawn
                                BZ   DSP_Exit

                                LOAD R9, O_VIDEO        ; prepare the pointer to the video buffer
                                LDN  R9
                                ADI  01H                ; second video display buffer page at start + 1

                                STR  R2
                                GHI  RC
                                SD
                                BNF  DSP_Exit
                                LDN  RF                 ; load the next byte of the sprite into RB.0
                                PLO  RB
                                LDI  00H                ; set RB.1 to OOH
                                PHI  RB
                                DEC  RD                 ; decrement the sprite's byte counter
                                INC  RF                 ; increment the pointer to the sprite's bytes
                                GHI  RA                 ; prepare the shift counter
                                PLO  RA
DSP_ShiftLoop:                  GLO  RA                 ; exit the loop if all shifts have been performed
                                BZ   DSP_ShiftExit
                                DEC  RA                 ; decrement the shift counter
                                GLO  RB                 ; shift the values in RB
                                SHR
                                PLO  RB
                                GHI  RB
                                RSHR
                                PHI  RB
                                BR   DSP_ShiftLoop
DSP_ShiftExit:                  SEX  RC                 ; store the shifted bytes in the video buffer
                                GLO  RB
                                XOR
                                STR  RC
                                INC  RC
                                GHI  RB
                                XOR
                                STR  RC
                                SEX  R2
                                GLO  RC                 ; advance the video buffer pointer to the next line
                                ADI  07H
                                PLO  RC
                                GHI  RC
                                ADCI 00H
                                PHI  RC
                                BR   DSP_ByteLoop
DSP_Exit:                       RETURN

;------------------------------------------------------------------------------------------
