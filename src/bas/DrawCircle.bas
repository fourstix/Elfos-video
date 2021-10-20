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
          sep  scall    ; check if video is ok 
          dw   IsVideoOkay
          glo  rf       ; RF.0 is non-zero if ok
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

80  FOR I=0 to 63 step 2
85  REM 0.09817477 = 2 * Pi / 64
90  Y=SIN(I*0.09817477)*31.0+31.0
95  REM scale X by half, because of rectangular 128x64 GLCD display
100 X=COS(I*0.09817477)*16.0+31.0
145 REM Uncomment PRINT statement below to see  points
150 REM PRINT "Plot: ("; X; ", "; Y; ")"
160 asm
          ; draw circular value on display
          sep scall
          dw  SaveVideoRegs       
          ldi v_X.0       ; get X byte value
          plo rf
          ldi v_X.1    
          phi rf          ; rf points to X 32-bit variable address
          inc rf
          inc rf
          inc rf
          ldn rf          ; point to Least Significant Byte
          plo ra          ; set X byte value for drawpixel
          ldi v_Y.0       ; get Y byte value
          plo rf
          ldi v_Y.1    
          phi rf          ; rf points to Y 32-bit variable address
          inc rf
          inc rf
          inc rf          ; point to Least Significant Byte
          ldn rf       
          phi ra          ; set Y byte value for drawpixel
          sep scall
          dw  DrawPixel   ; set pixel for circle
          sep scall
          dw  GetVideoRegs
    end

170 GOSUB 500
180 NEXT I
190 PRINT "Done!"
200 GOTO 999

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
