; **************************************************************
; Safe Video Routines - these save/restore registers 
; **************************************************************                    
IsVideoReady:           EQU   0A475H
IsEchoOn:               EQU   0A45DH
SaveVideoRegs:          EQU   0A1D2H
RestoreVideoRegs:       EQU   0A203H
; **************************************************************
; Unsafe Video Routines - these do *not* save/restore registers 
; **************************************************************                    
AllocateVideoBuffers:   EQU   0A23AH
ValidateVideo:          EQU   0A1B1H
VideoOn:                EQU   09FF5H
VideoOff:               EQU   0A00BH
UnloadVideo:            EQU   0A3A8H
UpdateVideo:            EQU   0A280H  
ClearScreen:            EQU   0A0C9H
PutChar:                EQU   09FC7H
Print:                  EQU   0A185H
Println:                EQU   0A199H
EchoOn:                 EQU   0A4D0H
EchoOff:                EQU   0A4F8H
DrawString              EQU   09ECCH
Draw32x64Image:         EQU   0A400H
Draw64x64Image:         EQU   0A431H
DrawSprite:             EQU   09E61H
DrawPixel               EQU   0A51DH
; **************************************************************
; This defines the video page value location in the kernel 
; **************************************************************                    
O_VIDEO:                EQU  03D0H  
