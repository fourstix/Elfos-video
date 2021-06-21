ValidateVideo:          EQU   0A1B1H
AllocateVideoBuffers:   EQU   0A1CCH
VideoOn:                EQU   09FF5H
VideoOff:               EQU   0A00BH
UnloadVideo:            EQU   0A3A5H
IsVideoReady:           EQU   0A2C0H
UpdateVideo:            EQU   0A258H  
ClearScreen:            EQU   0A0C9H
PutChar:                EQU   09FC7H
Println:                EQU   0A199H
Print:                  EQU   0A185H
GetEchoFlag:            EQU   0A45BH
EchoOn:                 EQU   0A49BH
EchoOff:                EQU   0A4C3H
DrawString              EQU   09ECCH
Draw32x64Image:         EQU   0A4E8H
Draw64x64Image:         EQU   0A3B5H
DrawSprite:             EQU   09E61H
; **************************************************************
; This defines the video page value location in the kernel 
; **************************************************************                    
O_VIDEO:                EQU  03D0H  
