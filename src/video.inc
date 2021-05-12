ValidateVideo:          EQU   0A4B1H
AllocateVideoBuffers:   EQU   0A4CCH
VideoOn:                EQU   0A2F5H
VideoOff:               EQU   0A30BH
UnloadVideo:            EQU   0A6A5H
IsVideoReady:           EQU   0A5C0H
UpdateVideo:            EQU   0A558H  
ClearScreen:            EQU   0A3C9H
PutChar:                EQU   0A2C7H
Println:                EQU   0A499H
Print:                  EQU   0A485H
GetEchoFlag:            EQU   0A75BH
EchoOn:                 EQU   0A79BH
EchoOff:                EQU   0A7C3H
DrawString              EQU   0A1CCH
Draw32x64Image:         EQU   0A7E8H
Draw64x64Image:         EQU   0A6B5H
DrawSprite:             EQU   0A161H
; **************************************************************
; This defines the video page value location in the kernel 
; **************************************************************                    
O_VIDEO:                EQU  03D0H  
