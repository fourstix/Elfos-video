; **************************************************************
; Safe Video Routines - these save/restore registers 
; **************************************************************                    
IsVideoReady:           EQU   0A545H
IsEchoOn:               EQU   0A475H
SaveVideoRegs:          EQU   0A218H
RestoreVideoRegs:       EQU   0A249H
; **************************************************************
; Unsafe Video Routines - these do *not* save/restore registers 
; **************************************************************                    
AllocateVideoBuffers:   EQU   0A1CCH
ValidateVideo:          EQU   0A1B1H
VideoOn:                EQU   09FF5H
VideoOff:               EQU   0A00BH
UnloadVideo:            EQU   0A3BFH
UpdateVideo:            EQU   0A280H  
ClearScreen:            EQU   0A0C9H
PutChar:                EQU   09FC7H
Print:                  EQU   0A185H
Println:                EQU   0A199H
EchoOn:                 EQU   0A4C7H
EchoOff:                EQU   0A4EFH
DrawString:             EQU   09ECCH
Draw32x64Image:         EQU   0A514H
Draw64x64Image:         EQU   0A3CFH
DrawSprite:             EQU   09E61H
DrawPixel:              EQU   0A566H
; **************************************************************
; This defines the video page value location in the kernel 
; **************************************************************                    
O_VIDEO:                EQU  03D0H  
