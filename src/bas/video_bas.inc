; **************************************************************
; Safe Video Routines - these save/restore registers 
; **************************************************************                    
IsVideoOkay:            EQU   0A478H
IsMirrorOn:             EQU   0A460H
SaveVideoRegs:          EQU   0A1D2H
GetVideoRegs:           EQU   0A203H
; **************************************************************
; Unsafe Video Routines - these do *not* save/restore registers 
; **************************************************************                    
AllocateVideoBuffers:   EQU   0A23AH
ValidateVideo:          EQU   0A1B1H
VideoOn:                EQU   09FF5H
VideoOff:               EQU   0A00BH
UnloadVideo:            EQU   0A3ABH
UpdateVideo:            EQU   0A283H  
ClearScreen:            EQU   0A0C9H
PutChar:                EQU   09FC7H
Print:                  EQU   0A185H
Println:                EQU   0A199H
MirrorOn:               EQU   0A4D3H
MirrorOff:              EQU   0A4FBH
DrawString:             EQU   09ECCH
Draw32x64Image:         EQU   0A403H
Draw64x64Image:         EQU   0A434H
DrawSprite:             EQU   09E61H
DrawPixel:              EQU   0A520H
; **************************************************************
; This defines the video page value location in the kernel 
; **************************************************************                    
O_VIDEO:                EQU  03D0H  
