; *******************************************************************************************
; Tty1861 - Teletype Terminal video functions
; Copyright (c) 2020-2021 by Gaston Williams
;
; These functions implement basic terminal functions in 64x64 bit graphics.
;
; Notes:
;       1. AllocateVideoBuffers should be called first to set up the Video Buffers.
;       The ValidateVideo function can be used to verify video buffers are allocated.
;
;       2. VideoOn should be called to initialize the system variables, and the UpdateVideo
;       function should be used to display the video buffer after a change.
;
;       3. VideoOff should be used to turn the video off and clear the system variables.
;
;       4. The UnloadVideo can be used to return video buffer memory to the system.
;
;       5. Safe Video functions check save and restore registers.  Unsafe functions do not
;       preserve register values.
;
;       6. The  SaveVideoRegs and RestoreVideoRegs functions can be used to make unsafe 
;       video functions safe by saving affected registers in the video buffer before any 
;       calls to video routines, and then restoring them afterwards.
;
; Changes:
; Gaston Williams, Sept, 2020 - Original TTY video code
; Gaston Williams, Nov,  2020 - Added support for EOT to clear screen
; Gaston Williams, May,  2021 - Added support for video buffers in HiMem
; Gaston Williams, July, 2021 - Fixed issues with Save/Restore registers
; Gaston Williams, July, 2021 - Updated to use Elf/OS Alloc/Dealloc kernel routines
; *******************************************************************************************

; **************************************************************
; *** This block defines two special locations in the kernel ***
; **************************************************************                    
O_HIMEM:            EQU  0442H
O_VIDEO:            EQU  03D0H  

; =========================================================================================
; HandleControlChar - Process a control character and move the cursor on screen
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RC.0          ASCII code of the character (20 - 5F)
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character

; Internals:
; RC.1          Temporary values
; RF.0          Width of character
;
; Returns:
; RA.0          Updated X coordinate of the character
; RA.1          Updated Y coordinate of the character
; =========================================================================================
HandleControlChar:      GLO  RC                 ; get the character
                        SDI  0AH                ; check for newline
                        BZ   HCC_NewLine

                        GLO  RC                 ; get the character
                        SDI  0DH                ; check for carriage return
                        BZ   HCC_NewLine

                        GLO  RC                 ; get the character
                        SDI  0CH                ; check for form feed
                        BZ   HCC_FormFeed

                        GLO  RC                 ; get the character
                        SDI  04H                ; check for end of transmission
                        BZ   HCC_FormFeed

                        GLO  RC                 ; get the character
                        SDI  09H                ; check for tab
                        BZ   HCC_Tab

                        GLO  RC                 ; get the character
                        SDI  0BH                ; check for vertical tab
                        BZ   HCC_VTab

                        GLO  RC                 ; get the character
                        SDI  08H                ; check for backspace
                        BZ   HCC_Backspace

                        GLO  RC                 ; get the character
                        SDI  7FH                ; check for del
                        BZ   HCC_Del

                        GLO  RC                 ; get the character
                        SDI  18H                ; check for cancel the line
                        BZ   HCC_Cancel

                        GLO  RC                 ; get character
                        SDI  1FH                ; check for unit separator
                        BZ   HCC_Unit
                        
                        BR   HCC_Exit           ; ignore everything else

HCC_Unit:               CALL UnitSeparator      ; advance cursor 1 pixel column space
                        BR   HCC_Exit

HCC_Cancel:             CALL CancelLine         ; erase the current line
                        BR   HCC_Exit

HCC_Del:                CALL Rubout             ; del backs up and rubs out one column
                        BR   HCC_Exit

HCC_Backspace:          CALL Backspace          ; move cursor back and delete a character
                        BR   HCC_Exit

HCC_Tab:                CALL TabCursor          ; move to next tab stop
                        BR   HCC_Exit

HCC_VTab:               CALL DownCursor         ; move to next line, same x position
                        BR   HCC_Exit

HCC_FormFeed:           CALL ClearScreen        ; form feed clears the screen
                        BR   HCC_Exit

HCC_NewLine:            CALL NextLine           ; go to next line and end
                        BR   HCC_Exit

HCC_Exit:               RETURN
;------------------------------------------------------------------------------------------
; =========================================================================================
; PutChar - Write a character on the screen and advance the cursor
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RC.0          ASCII code of the character (20 - 5F)
;
; Internal:
; RC.1          Temporary values
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
; RF.0          Width of character from drawCharacter
; =========================================================================================

PutChar:                CALL CheckForNewLine    ; check for newline sequence  
                        CALL GetCursor

                        GLO  RA                 ; get the x location

                        BNZ  WC_SetChar         ; check for beginning of new line
                        CALL BlankLine          ; if at begining, blank the line

WC_SetChar:             GLO  RC                 ; check for DEL or any character
                        SMI  7FH                ; that is greater than 7FH
                        BGE   WC_Control

                        GLO  RC                 ; get the character
                        SMI  20H                ; check for any printable character
                        BGE  WC_Draw

WC_Control:             CALL HandleControlChar  ; everthing else is a control character
                        BR   WC_UpdateCursor    ; save cursor changes after control char

WC_Draw:                GLO  RA                 ; push RA with cursor location onto the stack
                        STXD
                        GHI  RA
                        STXD

                        CALL DrawCharacter      ; write the chracter

                        IRX
                        LDXA
                        PHI  RA                 ; restore RA with cursor location
                        LDX
                        PLO  RA

                        CALL RightCursor        ; advance cursor by character width + 1

WC_UpdateCursor:        CALL SetCursor

WC_Exit:                RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Initialize system variables for video Terminal
;
; Note: This function is called before any other video functions
;
; Internal:
; RD            Pointer to interrupt service routine
; RF.0          Value to set Video Flag false
;
; Return: 
; =========================================================================================

VideoOn:                LOAD R1, DisplayInt
                                                  
                        LDI  0FFH               ; set the video flag to true
                        PLO  RF
                        CALL SetVideoFlag

                        LDI  00H                ; set the video flag off
                        PLO  RF
                        CALL SetEchoFlag

                        CALL ClearScreen        ; set cursor to home                                              
                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Disable interrupts and reset system variables for TTY Terminal
;
; Note: This function cleans up pointers after video functions for other programs
;
; Internal:
; RF.0          Value to set Video Flag false
; =========================================================================================

VideoOff:               LDI  0FFH               ; Set value to clear display
                        STR  R2                 ; Store at x for output
                        OUT  1                  ; turn 1861 video off

                        DEC  R2                 ; The output instruction increments stack
                                                ; pointer, so back up the stack pointer to
                                                ; point to its previous location.
                                                
                        OUT  1                  ; Do it twice to guarantee it is always off
                        DEC  R2
                                                  
                        LDI  023H               ; Value for x=2; p=3
                        STR  R2                 ; Save for disable instruction
                        DIS                     ; Keep x=2; p=3 but disable interrupts
                        DEC  R2                 ; disable increments x
                        
                        LDI  00H                ; set the video flag to false
                        PLO  RF
                        CALL SetVideoFlag                        
                        
                        LOAD R1, 0000H          ; Clear Interrupt pointer                        
                             
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Create a pointer into a Video buffer at the location specified by Y location
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function used to manipulator pointer into video buffer
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internal:
; R9            Pointer to video buffer page
;
; Return:
; RF            Pointer to video buffer with Y Offset
; =========================================================================================

VideoOffsetY:           LOAD R9, O_VIDEO        ; prepare the pointer to the video buffer
                        LDN  R9
                        PHI  RF

                        GHI  RA                 ; get the y position into video buffer

                        ANI  3FH                ; or 0 - 63

                        SHL                     ; Convert Y value to position offset = (y * 8)
                        SHL                     ; check high bit of 64x128 count in df

                        SHL
                        PLO  RF
                        BNF  VY_SkipLowInc
                        GHI  RF
                        ADI  01H
                        PHI  RF

VY_SkipLowInc:          RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Add the X byte offset to a pointer into a Video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function used to manipulator pointer into video buffer
;
; Parameters:
; RF            Pointer to video buffer with Y Offset
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Return:
; RF            Pointer to video buffer at X,Y byte Offset
; RC.1          X Offset byte value
; RC.0          X Offset bit value
; =========================================================================================

VideoOffsetX:           GLO  RA         ; get the x bit position
                        ANI  07H        ; mask off all but lowest 3 bits
                        PLO  RC         ; save bit value in RC.0

                        GLO  RA         ; get the x byte position into video buffer
                        ANI  3FH        ; value 0 - 63
                        SHR             ; Convert x value to position offset = (x / 8)
                        SHR
                        SHR
                        PHI  RC         ; save byte value in RC.1


                        STXD            ; byte position offset in M(X)
                        IRX

                        GLO  RF         ; advance the pointer coordinate by byte offset
                        ADD             ; add the offset to pointer
                        PLO  RF         ; save lower byte

                        GHI  RF         ; update high byte if needed
                        ADCI 00H        ; Add carry into high byte and save
                        PHI  RF

                        RETURN
;------------------------------------------------------------------------------------------


; =========================================================================================
; Clear a line of text on the video console (6 rows of pixels at 8 bytes per row) along
; with the 2 rows of the next row of text.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internal:
; RF            Pointer to video buffer
; RD            Counter
; =========================================================================================

BlankLine:              CALL VideoOffsetY


                        LDI  00H        ; load byte counter
                        PHI  RD
                        PLO  RD

BL_Loop:                LDI  00H
                        STR  RF
                        INC  RF
                        INC  RD

                        GLO  RD

                        SDI  40H        ;do 64 times (6 rows of pixels x 8 bytes per row
                                        ; + 2 rows to overwrite existing text on line below.)
                        LBNZ BL_Loop

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Advance cursor to next tab stop: 08H, 10H, 18H, 20H, 28H, 30H, 38H, 00H (NextLine)
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

TabCursor:              GLO  RA                 ; get cursorX value
                        ADI  08H                ; advance 8 pixels, 2 avg char widths
                        ANI  78H                ; mask off lower 3 bits (truncate to 8)
                        PLO  RA                 ; set the x cursor to begining of line (zero)

                        SDI  38H                ; check to see if we went past last tab stop
                        BGE  TAB_Exit           ; If not, we are done

                        CALL NextLine           ; If we went over go to next line


TAB_Exit:               RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Move cursor back one position and delete the character
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Video should be off before calling this function.
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internals:
; RF.0          Width of average character to back up
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

Backspace:              LDI  04H                ; average character width = 4 pixels
                        PLO  RF                 ; RD.0 has width to back up
                        CALL LeftCursor         ; Move cursor back one character

                        CALL BlankCharacter     ; erase the previous character

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Move cursor back one pixel position and clear the column
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Video should be off before calling this function.
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internals:
; RF.0          Width of to back up
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

Rubout:                 LDI  01H                ; rubout one column of pixels
                        PLO  RF                 ; pixel width to back up
                        CALL LeftCursor         ; Move cursor back one character

                        CALL BlankCharacter     ; erase the previous pixel column

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Move cursor forward one pixel position
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internals:
; RF.0          Width of character (zero)
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================
UnitSeparator:          LDI  00H                ; put zero as character width
                        PLO  RF

                        CALL RightCursor        ; advance cursor 0+1 pixel column

                        RETURN
;------------------------------------------------------------------------------------------
                        
; =========================================================================================
; Clear line and position cursror at the begining of the current line.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Note: Video should be off before calling this function.
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

CancelLine:             LDI  00H                ; load zero and save as cursorX
                        PLO  RA                 ; set the x cursor to begining of line (zero)

                        CALL BlankLine          ; clear the line

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Create mask for blanking character bits in video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function used for removing character pixels
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
; RC.0          X Offset bit value
; RC.1          X Offset byte value
;
; Internals:
; RD.0          Counter for calculating Mask
;
; Returns:
; RD.1          Mask for video bit values X byte
; =========================================================================================
CreateMask:             LDI  00FFH              ; load bit mask
                        PHI  RD
                        GLO  RC                 ; put the X offset bit value in counter
                        PLO  RD

CM_Test:                BZ   CM_Done            ; keep going to counter exhausted
                        GHI  RD                 ; get the mask byte
                        SHR                     ; shift once for each bit offset
                        PHI  RD                 ; save mask value
                        DEC  RD                 ; decrement counter
                        GLO  RD                 ; test byte for zero
                        BR   CM_Test

CM_Done:                GHI  RD                 ; get mask value
                        XRI  00FFH              ; invert all the bits for ANDing
                        PHI  RD                 ; put bit mask back in RD.1


                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Advance cursor to beginning of the next line.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

NextLine:               LDI  00H                ; load zero and save as cursorX
                        PLO  RA                 ; set the x cursor to begining of line (zero)

                        GHI  RA                 ; advance y cursor to point to next line
                        ADI  06H                ; each line is 6 pixels high
                        PHI  RA                 ; update cursorY

                        SDI  3CH                ; check to see if we are past the end
                        BGE NL_Exit             ; DF = 1 means haven't gone past 60 y pixels

                        LDI  02H                ; go back to top line
                        PHI  RA                 ; update cursorY

NL_Exit:                RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; SetVideoFlag - Set the video flag to false or true
;
; Note: Internal function used to set or clear the video flag
;
; Parameters:
; RF.0          Value for flag, zero for false, non-zero for true
; Internal:
; RD            Pointer to video flag
; =========================================================================================
SetVideoFlag:           CALL GetVideoFlagPointer          
                        GLO  RF                 ; get the value for the flag
                        STR  RD                 ; store the flag
                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Advance cursor down to next line without changing x location
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Video should be off before calling this function.
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

DownCursor:             GHI  RA                 ; move y by 6 pixels
                        ADI  06H
                        PHI  RA                 ; save y

                        SDI  3CH                ; check y value to see if we went past 60
                        BGE  DC_Blank           ; if not, erase the next line

                        LDI  02H                ; if so, move back to first line at top of console
                        PHI  RA                 ; save y

DC_Blank:               CALL BlankLine          ; erase existing text


                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; ClearScreen - Blank the video screen and home the cursor.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Internal:
; RF.1          zero value to fill screen
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
; =========================================================================================

ClearScreen:            LDI  00H                ; clear screen
                        PHI  RF
                        CALL FillScreen

                        LDI  00H                ; set x location to left margin
                        PLO  RA

                        LDI  02H                ; set y location to top line
                        PHI  RA

                        CALL SetCursor          ; send cursor home

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; SetCursor - Save the Cursor value into memory
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internal:
; RD            Pointer to CursorY and CursorX
; =========================================================================================
SetCursor:              CALL GetCursorXY    ; get pointer to the x,y cursor location
                        GLO  RA             ; get character x location
                        STR  RD             ; save the x cursor value

                        INC RD              ; point to the y cursor location
                        GHI  RA             ; get character y location
                        STR  RD             ; save the y cursor value

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetCursor - Read the Cursor value from memory
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RD            Pointer to Cursor X,Y buffers
;
; Returns:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
; =========================================================================================
GetCursor:              Call GetCursorXY        ; get the location of x,y cursor
                        LDA  RD                 ; load the x cursor value
                        PLO  RA                 ; set character x location

                        LDN  RD                 ; load the y cursor value
                        PHI  RA                 ; set character y location

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetCursorXY - Get a pointer to the Cursor X, Y buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer CursorX and CursorY buffers
; =========================================================================================
GetCursorXY:            LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  05         ; Cursor xy is immediately after Character Pattern
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; WriteHexOutput - Write a value out to the hex display
;
; Safe - This function does not affect any video registers
;
; Parameters:
; RC.0          Value to be shown on the hex display
; =========================================================================================

WriteHexOutput:         GLO  RC         ; Get byte to display
                        STR  R2         ; Put byte on the stack

                        OUT  4          ; Show it. This increments stack pointer,
                        DEC  R2         ; so back up stack pointer to point to the end.

                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetVideoFlagPointer - Get a pointer to the Video Flag buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer Video Flag
; =========================================================================================
GetVideoFlagPointer:    LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  07         ; Flag buffer is immediately after Cursor xy 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Move cursor backwards a number of pixel widths
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RF.0          Width to back up cursor
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

LeftCursor:             GLO  RA                 ;
                        BZ   LC_PreviousLine    ; if begining of line, go back one line

                        STXD                    ; store x location it in M(X)
                        IRX

                        GLO  RF                 ; get the pixel width

                        SD                      ; move x back RD.0 pixels
                        PLO  RA                 ; save x
                        BGE  LC_Exit            ; if positive or zero, we are done

                        LDI  00H                ; don't back up before begining of line
                        PLO  RA
                        BR   LC_Exit

LC_PreviousLine:        GHI  RA
                        SMI  06H                ; back up one line
                        PHI  RA
                        BL   LC_Home            ; but don't go beyond home

                        LDI  40H                ; set M(X) to end of line
                        STXD                    ; store eol in M(X)
                        IRX

                        GLO  RF                 ; get the pixel width
                        SD                      ; back up from eol
                        PLO  RA
                        BR   LC_Exit

LC_Home:                LDI  02H                ; set y to first line
                        PHI  RA

                        LDI  00H                ; set x to beginning
                        PLO  RA

LC_Exit:                RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Move cursor forwards a number of pixel widths
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RF.0          Width to advance cursor
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
;
; Return:
; RA.0          Updated X coordinate
; RA.1          Updated Y coordinate
; =========================================================================================

RightCursor:            GLO  RF                 ; advance the x coordinate by the
                        STXD                    ; width of the character + 1
                        IRX                     ; store width in M(X)

                        GLO  RA
                        ADD
                        ADI  01H
                        PLO  RA

                        SDI  3CH                ; check x value to see if we went past 60
                        BGE  RC_Exit

                        LDI  00H                ; set x for beginning of next line and adjust y
                        PLO  RA

                        GHI  RA                 ; move y by 6 pixels
                        ADI  06H
                        PHI  RA

                        SDI  3CH                ; check y value to see if we went past 60
                        BGE  RC_Exit

                        LDI  02H                ; if so move back to first line at top of console
                        PHI  RA

RC_Exit:                RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Clear character pixels from the current cursor location
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character
; RA.1          Y coordinate of the character
;
; Internal:
; RF            Pointer to video buffer
; RD.1          Mask for video bit values X byte
; RD.0          Counter
; RC.0          X Offset bit value
; RC.1          X Offset byte value
; =========================================================================================

BlankCharacter:         CALL VideoOffsetY       ; set pointer to video at y location
                        CALL VideoOffsetX       ; set pointer to video at x,y location

                        GLO  RA                 ; check x location
                        BNZ  BCH_GetMask        ; if inside line, calculate masks

                        CALL BlankLine          ; if at the beginning, clear the line
                        BR   BCH_Done

BCH_GetMask:            CALL CreateMask         ; get the mask for video bits

                        LDI  00H                ; initialize counter
                        PLO  RD


BCH_Blank:              GHI  RD                 ; get mask and put at M(X)
                        STXD
                        IRX

                        LDN  RF                 ; load video byte
                        AND                     ; and with mask
                        STR  RF                 ; put it back in memory

                        GHI  RC                 ; get the byte offset value
                        SDI  07H                ; check for last byte
                        BZ   BCH_LastByte       ; don't blank next byte after last byte

                        LDI  00H                ; blank out next byte after byte 0 to 6
                        INC  RF                 ; set video pointer to next byte
                        STR  RF                 ; blank out any remaining pixels
                        DEC  RF                 ; set video ptr back to x byte

BCH_LastByte:           INC  RD                 ; increment counter
                        GLO  RD                 ; check if done 5 times
                        SDI  05H
                        BZ   BCH_Done

                        GLO  RF                 ; Adjust pointer to next line of character
                        ADI  08H                ; each line is 8 bytes
                        PLO  RF                 ; save low byte and adjust hi byte with carry

                        GHI  RF
                        ADCI 00H
                        PHI  RF                 ; video pointer now points to next line of character
                        BR   BCH_Blank          ; do next line

BCH_Done:               RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; WaitForInput - Wait for Input key press and release.  No data is read.
;
; Safe - This function does not affect any registers
; =========================================================================================

WaitForInput:           BN4  WaitForInput       ; Wait for Input press


WFI_Release:            B4   WFI_Release        ; Wait for Input release

                        RETURN                  ; return
;------------------------------------------------------------------------------------------

; =========================================================================================
; Print - Read characters from a string and write to video until a null is read.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RF    - pointer to String
; Internal:
; RC.0  - character value read from input
; =========================================================================================

Print:                  LDN  RF        ; get character, exit if 0 (null)
                        PLO  RC
                        BZ   W_Exit
                        INC  RF

                        PUSH RF        ; Save RF on stack

                        CALL PutChar   ; write character to video

                        POP RF         ; restore RF from stack
                        
                        BR Print       ; continue with next character until null                        

W_Exit:                 RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Println - Read characters from a string and write to video, then write a
;        new line character.
;
; Note: Unsafe - this function does not save and restore registers used
; 
; Parameters:
; RF    - pointer to String
;
; Internal:
; RC.0  - character value for newline
; =========================================================================================

Println:          CALL Print        ; Write string to video buffer
                  
                  LDI  0DH          ; Write <CR> after string
                  PLO  RC
                  
                  CALL PutChar      ; write newline character to video

                  RETURN
;------------------------------------------------------------------------------------------
                      
; =========================================================================================
; GetMarkerPointer - Get a pointer to the Video Marker string "Pixie"
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer Marker string
; =========================================================================================
GetMarkerPointer:       LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  20H        ; Marker string is after stack 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; ValidateVideo - Verify the Video Marker string matches "Pixie"
;
; Note: Safe - This function saves and restores registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RD            Pointer to Marker String
; RF            Pointer to valid marker
;
; Returns:      
; RF.0          Zero if valid, non-zero if not valid
; =========================================================================================
ValidateVideo:          CALL GetMarkerPointer   ; Load RD with location of string
                        LOAD RF, VideoMarker    ; Load expected value in RF
                        CALL f_strcmp           ; Compare strings RD to RF
                        PLO  RF                 ; Store result in RF.0                        
                        RETURN                  
;------------------------------------------------------------------------------------------

; =========================================================================================
; SetVideoMarker -  Set the Video Marker string "Pixie" at end of the video buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RD            Pointer to Marker String
; RF            Pointer to valid marker
;
; Returns: 
;     
; =========================================================================================
SetVideoMarker:         CALL GetMarkerPointer   ; Load RD with location of string
                        LOAD RF, VideoMarker    ; Load source value in RF
                        CALL f_strcpy           ; Copy string from RF to RD
                        RETURN                  
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetVideoFlag - Get the Video Flag from the buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RD            Pointer to Video Flag location
;
; Returns: 
; RF.0          Value of video flag
; =========================================================================================
                        
GetVideoFlag:           CALL GetVideoFlagPointer  ; set pointer to video flag
                        LDN  RD                   ; get video flag 
                        PLO  RF                      
                        RETURN                       
;------------------------------------------------------------------------------------------

; =========================================================================================
; SaveVideoRegs - Save all registers affected by video routines into the video buffer
;
; Note: Safe - This function can be used to save video registers before calling unsafe
;       video routines.
;
; Parameters:
; R9, RA, RB, RC, RD and RF are saved in the video buffer 
; Internal:
;  R8 is used as a stack pointer into the video buffer
; Returns:
;
; =========================================================================================
SaveVideoRegs:          PUSH R8          
                        LOAD R8, O_VIDEO  ; get Video Display Page address
                        LDN  R8           
                        ADI  02H          ; Video buffers 2 pages after display 
                        PHI  R8
                        LDI  1EH          ; point to top of stack
                        PLO  R8
                        SEX  R8           ; set x to video buffer stack pointer              
                        PUSH R9           ; Save video registers on stack
                        PUSH RA
                        PUSH RB
                        PUSH RC
                        PUSH RD
                        PUSH RF
                        SEX  R2           ; Set X back to program Stack
                        POP  R8           ; restore R8 to original values           
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; RetoreVideoRegs - Restore all registers affected by video routines from the video buffer
;
; Note: Safe - This function can be used to restore video registers before calling unsafe
;       video routines.
;
; Parameters:
;  
; Internal:
;  R8 is used as a stack pointer into the video buffer
; Returns:
; R9, RA, RB, RC, RD and RF with values retrieved from the video buffer stack
; =========================================================================================
RestoreVideoRegs:       PUSH R8           ; save R8 on program stack
                        LOAD R8, O_VIDEO  ; get Video Display Page
                        LDN  R8
                        ADI  02H          ; Video buffers 2 pages after display
                        PHI  R8
                        LDI  12H          ; point to bottom of stack
                        PLO  R8
                        SEX  R8           ; set x to video buffer stack pointer
                        POP  RF
                        POP  RD
                        POP  RC
                        POP  RB
                        POP  RA
                        POP  R9
                        SEX  R2           ; set x back to program stack pointer
                        POP  R8           ; restore R8
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; AllocateVideoBuffers - Set the Video Buffers and code into HiMem
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:
; R7.0          Allocation flags 44 for named, permanent block
; R7.1          Alignment, 255 (FF) for 256 page 
; RC            Requested Size to allocate                        
; RD            Pointer to target locations 
; RF            Pointer to Allocated memory block
; RF.0          Flag values to set in video buffer
;
; Returns: 
; RF.0          non-zero if Elf/OS failed to allocate memory block    
; =========================================================================================

AllocateVideoBuffers:   LOAD RD, 0465H        ; Point RD to lowmem location in kernel
                        LDI  60H              ; load lowmem with floor of $6000
                        STR  RD               ; Elf/OS will not allocate a block
                        INC  RD               ; of memory below this floor value
                        LDI  00H 
                        STR  RD
                        
                        LOAD RC, 0226H        ; load (512 + 38) bytes for block size
                        LOAD R7, 0FF44H       ; page aligned (FF) & named permanent (44) 
                        CALL O_ALLOC          ; Call Elf/OS allocation routine
                        
                        BNF  AVB_okay         ; DF = 1 means Elf/OS can't allocate block                                                                  
                        LDI  0FFH             ; load out of memory flag into RF.0
                        PLO  RF
                        RETURN                 
                                                
AVB_okay:               LOAD RD, O_VIDEO      ; save video buffer page in kernel
                        GHI  RF
                        STR  RD
                                              
                        LDI  00h
                        PLO  RF
                        CALL SetVideoFlag     ; Make sure video flag is false                        

                        LDI  00h
                        PLO  RF
                        CALL SetNewLineFlag   ; Make sure NewLine flag is false

                        LOAD  RF, 00H
                        CALL SetStrRefValue   ; Clear string reference
                        
                        CALL ClearStackArea   ; Clear out the stack and padding bytes
                        
                        CALL SetVideoMarker   ; Set the marker at end of buffers
                        
                        LDI  00H              ; clear RF.0 to indicate memory allocated
                        PLO  RF                                       
                        RETURN  
;------------------------------------------------------------------------------------------

; =========================================================================================
; UpdateVideo - Turn pixie video interrupts and DMA requests on, wait for an update 
;               and then turn them off.
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: This function is used to update video display
; 
; Internal:
; RF.0          Value to set Video Flag true
; =========================================================================================

UpdateVideo:            LDI  023H               ; value for x=2, p=3     
                        STR  R2                 ; Save for return instruction
                        RET                     ; Keep x=2; p=3 and enable interrupts
                        DEC  R2                 ; return increments x
                        
                        LOAD RF, 0CH            ; Load count into RF 

                        INP 1                   ; turn 1861 video on
                                                
VU_Wait_Start:          BN1  VU_Wait_Start      ; wait for video to start
          
VU_Wait_Frame:          B1   VU_Wait_Frame      ; wait for frame start

                ;----- Interrupt occurs here      

VU_New_EF1:             BN1  VU_New_EF1         ; wait for frame end
                                               
                        DEC  RF
                        GLO  RF
                        BNZ  VU_Wait_Frame      ; keep counting down                        
                  
                        
                        
                        SEX  R2                 ; Make sure X = R2
                        OUT  1                  ; turn 1861 video off
                                                ; The output instruction increments X
                        DEC  R2                 ; Set stack back to previous location
                                            
                        LDI  023H               ; Value for x=2; p=3
                        STR  R2                 ; Save for disable instruction
                        DIS                     ; Keep x=2; p=3 but disable interrupts
                        DEC  R2                 ; disable increments x
                                                                     
                        RETURN
;------------------------------------------------------------------------------------------                      

; =========================================================================================
; SetNewLineFlag - Set the newline flag 
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function used by the CheckForNewLine function
;
; Parameters:
; RC.0          Character Value to use to set new line flag:
;               F0H for <CR>, 0FH for <LF> and 00H for all other characters
; Internal:
; RD            Pointer to newline flag
; =========================================================================================
SetNewLineFlag:         CALL GetNewLinePointer          
                        GLO  RC                 ; get the character
                        SMI  0DH                ; Check for <CR>
                        BZ   SNLF_CR
                        GLO  RC
                        SMI  0AH                ; Check for <LF>
                        BZ   SNLF_LF    
                        LDI  00H                ; zero for all other characters
                        BR   SNLF_Save  
SNLF_CR:                LDI  0F0H               ; for <CR>, set to ignore <LF>
                        BR   SNLF_Save
SNLF_LF:                LDI  0FH                ; for <LF>, set to ignore <CR>
                        BR   SNLF_Save
SNLF_Save:              STR  RD                 ; store the flag                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; CheckForNewLine -  Check the newline flag and ignore the CR or LF if part of two 
;                 character new line sequence, CRLF or LFCR. 
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function called by PutChar function
;
; Parameters:
; RC.0          Character value to check
; RF.0          New Line flag
; Internal:
; RD            Pointer to NewLine flag
; =========================================================================================
CheckForNewLine:      CALL GetNewLineFlag
                      GLO  RF
                      BZ   CNL_Done
                      SHL                   ; Check for <CR> (MSB = 1)
                      BDF  CNL_CR           ; Otherwise <LF>
                      GLO  RC
                      SMI  0DH              ; check for <CR> after <LF>
                      BZ   CNL_Ignore
CNL_CR                GLO  RC             
                      SMI  0AH              ; check for <LF> after <CR>
                      BNZ  CNL_Done
CNL_Ignore:           LDI  00H              ; replace ignored char by Null             
                      PLO  RC  
CNL_Done:             CALL SetNewLineFlag   ; set flag based on next character                       
                      RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetNewLinePointer - Get a pointer to the NewLine buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer NewLine Flag
; =========================================================================================
GetNewLInePointer:      LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  08         ; NewLine buffer is immediately after video flag 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetNewLineFlag - Get the NewLine Flag from the buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RD            Pointer to Video Flag location
;
; Returns: 
; RF.0          Value of new line flag
; =========================================================================================
                        
GetNewLineFlag:         CALL GetNewlinePointer    ; set pointer to video flag
                        LDN  RD                ; get video flag 
                        PLO  RF
                      
                        RETURN                       
;------------------------------------------------------------------------------------------

; =========================================================================================
; EchoChar- Write character to serial out and display
;
; Safe - This function saves and restores registers
;
; Parameters:
; RF            Pointer to string               
; Internal:                        
; 
; Returns: 
; 
; =========================================================================================

EchoChar:           PLO  RE                 ; save D in RE.0
                    STXD                    ; Save D, DF, R9, RD and RF on stack 
                    SHRC                    ; put DF in hi bit 
                    STXD                    ; 
                    PUSH R9                 ;                     
                    PUSH RD                 ;
                    PUSH RC                 ; 
                    GLO  RE                 ; get d
                    PLO  RC                 ; set d in RC.0                  
                    
                    CALL SetCharValue       ; save the character in scratch area
                    
                    POP  RC                 ; restore consumed registers
                    POP  RD                 
                    POP  R9
                    IRX  
                    LDXA                    ; Get byte with df
                    SHL                     ; put hi bit into DF
                    LDX                     ; restore D
                    
                    CALL F_TYPE             ; call original character routine
                    
                    CALL SaveVideoRegs      ; save state after Bios call
                    CALL GetVideoFlag       ; check the video flag
                    GLO  RF                      
                    BZ   EC_Off             ; skip video update if off

                    CALL GetCharValue       ; get the RF value from video buffer
                    CALL PutChar            ; call display routine
                    CALL UpdateVideo
EC_Off:             CALL RestoreVideoRegs   ; restore state after Bios call

                    RETURN                  ; return to Elf/OS
;------------------------------------------------------------------------------------------

; =========================================================================================
; EchoMsg - Write string to serial out and display
;
; Safe - This function saves and restores registers
;
; Parameters:
; RF            Pointer to string               
; Internal:                        
; 
; Returns: 
; 
; =========================================================================================

EchoMsg:            STXD                    ; Save D, DF, R9 and RD on stack 
                    SHRC                    ; put DF in hi bit 
                    STXD                    ; 
                    PUSH R9                 ;                     
                    PUSH RD                 ; 
                    CALL SetStrRefValue     ; save the RF value in video buffer
                    POP  RD                 ; restore consumed registers
                    POP  R9
                    IRX  
                    LDXA                    ; Get df
                    SHL                     ; put hi bit into DF
                    LDX                     ; restore D
                    
                    CALL F_MSG              ; call original bios routine
                  
                    CALL SaveVideoRegs      ; save state after Bios call
                    CALL GetVideoFlag       ; check the video flag
                    GLO RF                      
                    BZ   EM_Off             ; skip video update if off
                    CALL GetStrRefValue     ; Get original string reference
                    CALL Print              ; call display routine
                    CALL UpdateVideo
EM_Off:             CALL RestoreVideoRegs   ; restore state after Bios call
                    RETURN                  ; return to Elf/OS
;------------------------------------------------------------------------------------------

; =========================================================================================
; EchoInMsg - Write inlined string to serial out and display
;
; Safe - This function saves and restores registers
;
; Parameters:
; R6            Pointer to string inline with original call           
; Internal:                        
; RF            Consumed by F_MSG routine
; Returns: 
; 
; =========================================================================================

EchoInMsg:          STXD                    ; Save D, DF, R9 and RD on stack 
                    SHRC                    ; put DF in hi bit 
                    STXD                    ; save df on stack
                    PUSH R9                 ;                     
                    PUSH RD                 ;                     
                    COPY R6, RF             ; R6 points to inlined string (before call)
                    CALL SetStrRefValue     ; save the RF value in video buffer
                    POP  RD                 ; restore consumed registers
                    POP  R9                    
                    IRX  
                    LDXA                    ; Get df from stack
                    SHL                     ; put hi bit into DF
                    LDX                     ; restore D from stack
                    
                    CALL F_MSG              ; call bios message routine
                                        
                    CALL SaveVideoRegs      ; save state after Bios call
                    CALL GetVideoFlag       ; check the video flag
                    GLO  RF                      
                    BZ   EIM_Off            ; skip video update if off                    
                    CALL GetStrRefValue     ; Get original RF reference
                    CALL Print              ; call display routine
                    CALL UpdateVideo
EIM_Off:            CALL RestoreVideoRegs   ; restore state after Bios call
EIM_Skip:           LDA  R6                 ; move R6 past inline string
                    BNZ  EIM_Skip           ; return to location after null
                    RETURN                  ; return to Elf/OS
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetEndMarker - Get a pointer to last non-null character in marker string
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer last non-null character in marker string
; =========================================================================================
GetEndMarker:           LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  24H        ; Last non-null character in string 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------
                        
; =========================================================================================
; UnloadVideo - Check to see if Video page can be unloaded
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:                        
; R9            Pointer to HiMem value
; RD            Pointer to video Marker
; Returns: 
; 
; =========================================================================================

UnloadVideo:            CALL ClearVideoMarker   ; Wipe out Marker value 

                        LOAD R9, O_VIDEO   ; prepare the pointer to the video buffer
                        LDN  R9
                        PHI  RF
                        LDI  00H
                        PLO  RF   
                        CALL O_DEALLOC
                        
                        RETURN        
;------------------------------------------------------------------------------------------

; =========================================================================================
; ClearVideoMarker -  Remove the Video Marker string "Pixie" at end of the buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RD            Pointer to end of Marker String
; RF            Pointer to valid marker
;
; Returns: 
;     
; =========================================================================================
ClearVideoMarker:       CALL GetEndMarker     ; Load RD last non-null character in Marker
                        LDI 00h               ; Overwrite with 0
                        SEX RD                ; and set X to RD
                        STXD
                        STXD
                        STXD
                        STXD
                        STXD
                        SEX R2                ; set X back to R2
                        RETURN                  
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetScratchPointer - Get a pointer to the scratch area in video buffers
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer to 2 byte scratch area
; =========================================================================================
GetScratchPointer:      LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  0AH        ; Scratch area is immediately after Echo flag 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------
                        
; =========================================================================================
; SetStrRefValue - Set the string reference value in the scratch area
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Note: Internal function used to save string reference for echo routines
;
; Parameters:
; RF            Original String reference
; Internal:
; RD            Pointer to scratch area
; =========================================================================================
SetStrRefValue:         CALL GetScratchPointer          
                        GHI  RF                 ; save the hi value of the pointer
                        STR  RD                 ; store the value
                        INC  RD
                        GLO  RF                 ; save the lo value of pointer
                        STR  RD
                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetStrRefValue - Get the string reference value from the scratch area
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Note: Internal function used to get original string reference for echo routines
;
; Parameters:
; 
; Internal:
; RD            Pointer to video flag
; Returns:
; RF            Original string reference value
; =========================================================================================
GetStrRefValue:         CALL GetScratchPointer
                        LDA  RD                 ; get the hi value of the string reference
                        PHI  RF                 ; save for return
                        LDN  RD                 ; get the lo value of the string reference
                        PLO  RF                 ; save for return
     
                        RETURN
;------------------------------------------------------------------------------------------
; =========================================================================================
; SetCharValue - Save a character value in the scratch buffer area
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function used to save the original character value for echo routines
;
; Parameters:
; RC.0          Character to save
; Internal:
; RD            Pointer to scratch area in video buffers
; =========================================================================================
SetCharValue:           CALL GetScratchPointer          
                        GLO  RC                 ; get the chraracter to save
                        STR  RD                 ; store in scratch area
                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetCharValue - Get the character value from the scratch area
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Note: Internal function used to get original character value for echo routines
;
; Parameters:
; 
; Internal:
; RD            Pointer to scratch area in video buffers
; Returns:
; RC.0          Original character value
; =========================================================================================
GetCharValue:           CALL GetScratchPointer
                        LDN  RD                 ; get the character value from scratch area
                        PLO  RC                 ; save for return
     
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetEchoPointer - Get a pointer to the Echo vectors in the video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer to Echo vector buffers
; =========================================================================================
GetEchoPointer:         LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  0CH        ; Echo vector buffers are after Echo Scratch area 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------
; =========================================================================================
; Draw32x64Image - Copy a 32x64 bit image into the video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RF            Pointer to 256 byte image data
;
; Internal:
; R9            Pointer to buffer page value
; RA            Pointer to video buffer
; RB            Counter for lines (32 lines)
; RC            Counter for bytes (8 bytes per line)
; RD            Pointer to duplicate line image data
; =========================================================================================

Draw32x64Image:     LOAD R9, O_VIDEO    ; prepare the pointer to the video buffer
                    LDN  R9
                    PHI  RA
                    LDI  00H
                    PLO  RA
                    COPY RF, RD         ; set up duplicate image data pointer
                    LOAD RB, 32         ; set up outside counter (32 lines)
                    LDI  0
                    PHI  RC             ; set up inner counter (8 bytes)
D32_rpt:            LDI  8
                    PLO  RC
D32_loop1:          LDA  RF             ; copy one line of 8 bytes
                    STR  RA
                    INC  RA
                    DEC  RC             ; check the byte count
                    GLO  RC
                    BNZ  D32_loop1
                    LDI  8
                    PLO  RC
D32_loop2:          LDA  RD             ; repeat line of 8 bytes 
                    STR  RA
                    INC  RA
                    DEC  RC             ; check the byte count
                    GLO  RC
                    BNZ  D32_loop2
                    DEC  RB             ; repeat 32 times to fill video buffer
                    GLO  RB
                    BNZ  D32_rpt
                    RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; Draw64x64Image - Copy a 64x64 bit image into the video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RF            Pointer to 512 byte image data
;
; Internal:
; R9            Pointer to buffer page value
; RA            Pointer to video buffer
; =========================================================================================

Draw64x64Image:            			LOAD R9, O_VIDEO   ; prepare the pointer to the video buffer
                                LDN  R9
                                PHI  RA
                                LDI  00H
                                PLO  RA

D64_Loop1:                      LDA  RF							; Load first page of display	
                                STR  RA
                                INC  RA
                                GLO  RA
                                BNZ  D64_Loop1

D64_Loop2:                      LDA  RF							; Load second page of display
                                STR  RA
                                INC  RA
                                GLO  RA
                                BNZ  D64_Loop2

                                RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; GetEchoFlagPointer - Get a pointer to the Echo vectors in the video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; R9            Pointer to video buffer page
;
; Returns:
; RD            Pointer to Echo vector buffers
; =========================================================================================
GetEchoFlagPointer:     LOAD R9, O_VIDEO
                        LDN  R9
                        ADI  02H        ; Video buffers 2 pages after display buffer start
                        PHI  RD
                        LDI  09H        ; Echo Flag is after the new line flag 
                        PLO  RD
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; SetEchoFlag - Set the echo flag to false or true
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
; Note: Internal function to set or clear the echo flag
;
; Parameters:
; RF.0          Value for flag, zero for false, non-zero for true
; Internal:
; RD            Pointer to video flag
; =========================================================================================
SetEchoFlag:            CALL GetEchoFlagPointer          
                        GLO  RF                 ; get the value for the flag
                        STR  RD                 ; store the flag
                        
                        RETURN
;------------------------------------------------------------------------------------------

; =========================================================================================
; IsEchoOn - Get the Echo Flag from the video buffers
;
; Note: Safe - This function saves and restores registers used by video routines
;
; Parameters:
;                
; Internal:
; R9            Pointer to video buffer page                        
; RD            Pointer to Echo Flag location
;
; Returns: 
; RF.0          Value of Echo flag (non-zero if true, zero if false)
; =========================================================================================
                        
IsEchoOn:               PUSH R9
                        PUSH RD
                        CALL GetEchoFlagPointer   ; set pointer to video flag
                        LDN  RD                   ; get video flag 
                        PLO  RF                   ; put echo flag in RF.0  
                        POP  RD
                        POP  R9                      
                        RETURN                       
;------------------------------------------------------------------------------------------

; =========================================================================================
; IsVideoReady - Check that the video is loaded and started.
;
; Note: Safe - This function saves and restores registers used by video routines
;
; Parameters:
;                
; Internal:                        
; RF     Video Valid and Video Started flag values
; RD     Pointer to Video Flag location
; R9     Pointer to video buffer page (GetVideoFlag)
;
; Returns: 
; RF.0          Ready value (0 if not ready; non-zero if ready)
; =========================================================================================
IsVideoReady:         PUSH R9
                      PUSH RD                      
                      CALL ValidateVideo
                      GLO  RF
                      BZ  IVR_loaded
                      LDI 00H               ; load false value in RF.0           
                      PLO RF
                      BR IVR_done           ; no need to check flag if not loaded
IVR_loaded:           CALL GetVideoFlag     ; sets RF true if started, false if not 
IVR_done:             POP RD                ; restore registers used to get video flag
                      POP R9
                      RETURN
;------------------------------------------------------------------------------------------

;=========================================================================================
; SaveVector - Save kernel vector into the video echo buffer location
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RD            Pointer Echo vector
; RF            Pointer to kernel vector
; Returns:
; 
; =========================================================================================
SaveVector:             INC   RF            ; point to address
                        LDA   RF            ; get hi address
                        STR   RD            ; put into vector
                        INC   RD            ; move to next address
                        LDN   RF            ; get lo address
                        STR   RD
                        INC   RD      
                        RETURN  
;------------------------------------------------------------------------------------------
  
;=========================================================================================
; RestoreVector - Save kernel vector into the video echo buffer location
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RD            Pointer Echo vector
; RF            Pointer to kernel vector location
; Returns:
; 
; =========================================================================================
RestoreVector:          INC   RF            ; point to address
                        LDA   RD            ; get original hi byte value from echo buffer
                        STR   RF            ; save hi byte in kernel
                        INC   RF            ; move to lo byte address
                        LDA   RD            ; get original lo byte value from echo buffer
                        STR   RF            ; save lo byte in kernel      
                        RETURN  
;------------------------------------------------------------------------------------------

;=========================================================================================
; MapVectors - Set kernel vectors to video echo routines
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RF            Pointer to kernel vector location
; Returns:
; 
; =========================================================================================
MapVectors:             LOAD RF, O_TYPE     ; point to kernel address
                        INC  RF             ; point to address
                        LDI  hi(EchoChar)
                        STR  RF             ; save hi byte in kernel
                        INC  RF             ; move to lo byte address
                        LDI  lo(EchoChar)   ; get original lo byte value from echo buffer
                        STR  RF             ; save lo byte in kernel
                        LOAD RF, O_MSG      ; point to kenel address
                        INC  RF             ; point to address
                        LDI  hi(EchoMsg)
                        STR  RF             ; save hi byte in kernel
                        INC  RF             ; move to lo byte address
                        LDI  lo(EchoMsg)    ; get original lo byte value from echo buffer
                        STR  RF             ; save lo byte in kernel      
                        LOAD RF, O_INMSG    ; point to kenel address
                        INC  RF             ; point to address
                        LDI  hi(EchoInMsg)
                        STR  RF             ; save hi byte in kernel
                        INC  RF             ; move to lo byte address
                        LDI  lo(EchoInMsg)  ; get original lo byte value from echo buffer
                        STR  RF             ; save lo byte in kernel      
                        RETURN  
;------------------------------------------------------------------------------------------
                       
;=========================================================================================
; EchoOn - Save kernel vectors to echo vectors and map to video functions
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RD            Pointer to Echo vectors;
; RF            Pointer to Kernel vector location
; RF.0          Echo flag value
; Returns:
; 
; =========================================================================================
EchoOn:                 CALL GetEchoPointer   ; Point RD to Echo buffers
                        LOAD RF, O_TYPE       ; Point RF to Kernel char fuction
                        CALL SaveVector       ; Save Kernel vector
                        LOAD RF, O_MSG        ; Point RF to Kernel msg function
                        CALL SaveVector       ; Save Kernel vector 
                        LOAD RF, O_INMSG      ; Point RF to Kernel inline msg function
                        CALL SaveVector       ; Save Kernel vector
                        LDI  0FFH 
                        PLO  RF               ; Set Echo flag on
                        CALL SetEchoFlag      
                        CALL MapVectors       ; Map vectors to new location
                        RETURN 
;------------------------------------------------------------------------------------------

;=========================================================================================
; EchoOff - Restore kernel vectors from the echo vector locations in video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;
; Internal:
; RD            Pointer to Echo vectors
; RF            Pointer to Kernel vector
; RF.0          Echo flag value
; Returns:
; 
; =========================================================================================
EchoOff:                CALL GetEchoPointer   ; Point RD to Echo buffers
                        LOAD RF, O_TYPE       ; Point RF to Kernel char fuction
                        CALL RestoreVector    ; Save Kernel vector
                        LOAD RF, O_MSG        ; Point RF to Kernel msg function
                        CALL RestoreVector    ; Save Kernel vector 
                        LOAD RF, O_INMSG      ; Point RF to Kernel inline msg function
                        CALL RestoreVector    ; Save Kernel vector
                        LDI  00H              ; Set the Echo flag false
                        PLO  RF
                        CALL SetEchoFlag
                        RETURN 
;------------------------------------------------------------------------------------------

; =========================================================================================
; DrawPixel - Set a pixel in the video buffer
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
; RA.0          X coordinate of the character, 0 to 63
; RA.1          Y coordinate of the character, 0 to 63
;
; Internal:
; RF            Pointer to video buffer at X,Y byte Offset
; RD.0          Bit mask
; RC.1          X Offset byte value
; RC.0          X Offset bit value
; R9            Pointer to video buffer page
; Return:
; RF            
; Internal:
; R9            Pointer to buffer page value
; =========================================================================================
DrawPixel:
                        CALL VideoOffsetY       ; set pointer to video at y location
                        CALL VideoOffsetX       ; set pointer to video at x,y location
                        LDI  80H                ; 0 offset is at left most bit
                        PLO  RD                 ; set mask with zero bit set
DP_Mask:                GLO  RC                 ; Get bit count  
                        BZ   DP_SetBit          ; Count is done
                        GLO  RD                 ; Get mask
                        SHR                     ; Shift bit over one position
                        PLO  RD                 ; store mask in RD.0
                        DEC  RC                 ; Count down
                        BR   DP_Mask            ; Check count and continue
DP_SetBit:              LDN  RF                 ; Get the current value in the buffer
                        STXD                    ; save it in memory
                        IRX         
                        GLO  RD                 ; Get the mask
                        OR                      ; Or the mask with memory
                        STR  RF                 ; Store it back in the video buffer
                        RETURN
;------------------------------------------------------------------------------------------
; =========================================================================================
; ClearEndBufffer - Zero out stack area and padding bytes before and after 
;
; Note: Unsafe - This function does *not* save and restore registers used by video routines
;
; Parameters:
;  
; Internal:
;  RD is used as a pointer into the video buffer
; Returns:
; 
; =========================================================================================
ClearStackArea:         CALL GetMarkerPointer     ; set RD to point to marker
                        DEC  RD                   ; point RD to just before marker
                        SEX  RD                   ; set X to data pointer
CSA_clear:              LDI  00H                  ; zero out data bytes 
                        STXD                      ; clear byte and back up
                        GLO  RD                   ; check count for end
                        SMI  11H                  ; check for one below padding byte
                        BNZ  CSA_clear            ; keep going until all bytes cleared
                        SEX  R2                   ; set x back to system stack  
                        RETURN
;------------------------------------------------------------------------------------------

; ******************************* VIDEO BUFFER MEMORY MAP *********************************

; =========================================================================================
; page:00 - page+1:FF : 512 byte display buffer 64 x 64 resolution,
;                       must start on page boundary
; =========================================================================================
; page+2:00-04 : 5 byte buffer for unpacked characters
; CharacterPattern       5 
; =========================================================================================
; page+2:05,06 : 2 Byte Cursor X, Cursor Y location for video console
; page+2:05 : CursorX                 1
; page+2:06 : CursorY                 1
; =========================================================================================
; page+2:07 : 1 Byte VideoFlag to indicate if 1861 Video is currently on or off
; =========================================================================================
; page+2:08 : 1 Byte NewLineFlag to indicate if CR or LF char should be skipped
; =========================================================================================
; page+2:09 : 1 Byte EchoFlag to indicate if echo function is on or off
; =========================================================================================
; page+2:0A,0B : 2 Byte scratch area for Echo routine string references and characters
; =========================================================================================
; page+2:0C,0D : Echo address vector for O_TYPE
; page+2:0E,0F : Echo address vector for O_MSG
; page+2:10,11 : Echo address vector for O_INMSG
; =========================================================================================
; page+2:12 : 1 Byte padding before register stack 
; =========================================================================================
; page+2:13-1E : Stack for Save/Restore Video Registers (R9, RA, RB, RC, RD and RF)  
; =========================================================================================
; page+2:1F : 1 Byte padding before marker 
; =========================================================================================
; page+2:20-25 : 6 Bytes for "Pixie",0 string to verify video buffers are loaded
; =========================================================================================


VideoMarker:            db "Pixie",0
