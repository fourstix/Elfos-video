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
80  PRINT "Draw X axis and Y axis."
90  FOR I = 0 to 63
100 asm
          ; draw the x axis and y axis
          sep scall
          dw  SaveVideoRegs
          ldi v_I.0       ; draw x axis first 
          plo rf
          ldi v_I.1    
          phi rf          ; rf points to variable address
          inc rf
          inc rf          ; 32 bit integers since we using floating point
          inc rf          ; point to LSB (Least Significant Byte)
          ldn rf
          plo ra          ; set X to I value
          ldi 1FH
          phi ra          ; set Y to middle of screen
          sep scall       ; draw pixel for x axis
          dw  DrawPixel   
          ldi v_I.0       ; draw y axis on the left side
          plo rf
          ldi v_I.1    
          phi rf          ; rf points to variable address
          inc rf          ; 32 bit integers since we using floating point
          inc rf
          inc rf          ; point to LSB (Least Significant Byte)
          ldn rf
          phi ra          ; set Y to I byte value
          ldi 0H          ; set X to zero
          plo ra
          sep scall
          dw  DrawPixel   ; draw pixel for y axis
          sep scall
          dw  GetVideoRegs
    end
110 NEXT I
120 GOSUB 500   

130 PRINT "Calculate and plot sine wave."
140 FOR I = 0 to 63
145 REM 0.09817477 = 2 * Pi / 64 (to draw one cycle across 64 pixels)
150 J = 31 - CINT(31.0 * SIN(I*0.09817477))
155 REM Uncomment PRINT statement below to see data points
160 REM PRINT "Plot: ("; I; ", "; J; ")"
170 asm
          ; draw sine value on display
          sep scall
          dw  SaveVideoRegs          
          ldi v_I.0       ; get X byte value
          plo rf
          ldi v_I.1    
          phi rf          ; rf points to I 32-bit variable address
          inc rf
          inc rf
          inc rf
          ldn rf          ; point to Least Significant Byte
          plo ra          ; set X to I byte value
          ldi v_J.0       ; get Y byte value
          plo rf
          ldi v_J.1    
          phi rf          ; rf points to J 32-bit variable address
          inc rf
          inc rf
          inc rf          ; point to Least Significant Byte
          ldn rf       
          phi ra          ; set Y to J byte value
          sep scall
          dw  DrawPixel   ; set pixel for sine wave
          sep scall
          dw  GetVideoRegs
    end

180 GOSUB 500
190 NEXT I
200 PRINT "Done!"
210 GOTO 999

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
