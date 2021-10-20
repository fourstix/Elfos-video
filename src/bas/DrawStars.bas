.list
10  asm
             ; define labels for video routines in ROM                       
#include video_bas.inc
    end        
20  R = 0
30  PRINT "Checking video status."
40  asm
          ldi v_R.1     ; point rd to R variable
          phi rd
          ldi v_R.0
          plo rd
          sep  scall    ; check if video is okay  
          dw   IsVideoOkay
          glo  rf       ; RF.0 is non-zero if okay
          str  rd       ; set hi-byte of R with flag 
    end
50  IF R = 0 THEN GOTO 900

60  PRINT "Clear the display."
70  asm
          sep scall
          dw  SaveVideoRegs
          sep scall
          dw  ClearScreen
          sep scall
          dw  GetVideoRegs
    end       
    
80  FOR I=1 to 100    
90  X = RND(64)
100 Y = RND(64)
110 asm
          ; draw random dot on display
          sep scall
          dw  SaveVideoRegs          
          ldi v_X.0       ; get X byte value
          plo rf
          ldi v_X.1    
          phi rf          ; rf points to X 16-bit variable address
          inc rf
          ldn rf          ; point to Least Significant Byte
          plo ra          ; set X to byte value
          ldi v_Y.0       ; get Y byte value
          plo rf
          ldi v_Y.1    
          phi rf          ; rf points to Y 16-bit variable address
          inc rf          ; point to Least Significant Byte
          ldn rf       
          phi ra          ; set Y to byte value
          sep scall
          dw  DrawPixel   ; set pixel on display
          sep scall
          dw  GetVideoRegs
    end
120 GOSUB 500
130 NEXT I
140 PRINT "Done!"
150 GOTO 999

500 asm   
          ; subroutine to update display
          sep scall
          dw  SaveVideoRegs
          sep scall
          dw  UpdateVideo
          sep scall
          dw  GetVideoRegs
          sep sret
    end

900 PRINT "Video is off."
999 END
