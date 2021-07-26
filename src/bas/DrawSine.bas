
10  asm
             ; define labels for video routines in ROM
isready:     equ 0A475H
saveregs:    equ 0A1D2H
restoreregs: equ 0A203H
println:     equ 0A199H
update:      equ 0A280H  
clear:       equ 0A0C9H
drawpixel:   equ 0A51DH  
    end     
20  R = 0
30  PRINT "Checking video status."
40  asm
          ldi [R].1     ; point rd to R variable
          phi rd
          ldi [R].0
          plo rd
          sep  scall    ; check if video is ready  
          dw   isready
          glo  rf       ; RF.0 is non-zero if ready
          str  rd       ; set hi-byte of R with flag 
    end
50  IF R = 0 THEN GOTO 900

60  PRINT "Clear the display."
70  asm
          sep scall
          dw  saveregs
          sep scall
          dw  clear
          sep scall
          dw  restoreregs
    end        

80  PRINT "Draw X axis and Y axis."
90  FOR I = 0 to 63
100 asm
          ; draw the x axis and y axis
          sep scall
          dw  saveregs
          ldi [I].0       ; draw x axis first 
          plo rf
          ldi [I].1    
          phi rf          ; rf points to variable address
          inc rf
          inc rf          ; 32 bit integers since we using floating point
          inc rf          ; point to LSB (Least Significant Byte)
          ldn rf
          plo ra          ; set X to I value
          ldi 1FH
          phi ra          ; set Y to middle of screen
          sep scall       ; draw pixel for x axis
          dw  drawpixel   
          ldi [I].0       ; draw y axis on the left side
          plo rf
          ldi [I].1    
          phi rf          ; rf points to variable address
          inc rf          ; 32 bit integers since we using floating point
          inc rf
          inc rf          ; point to LSB (Least Significant Byte)
          ldn rf
          phi ra          ; set Y to I byte value
          ldi 0H          ; set X to zero
          plo ra
          sep scall
          dw  drawpixel   ; draw pixel for y axis
          sep scall
          dw  restoreregs
    end
100 NEXT I
110 GOSUB 500   

120 PRINT "Calculate and plot sine wave."
130 FOR I = 0 to 63
135 REM 0.09817477 = 2 * Pi / 64 (to draw one cycle across 64 pixels)
140 J = 31 - CINT(31.0 * SIN(I*0.09817477))
145 REM Uncomment PRINT statement below to see data points
150 REM PRINT "Plot: ("; I; ", "; J; ")"
160 asm
          ; draw sine value on display
          sep scall
          dw  saveregs          
          ldi [I].0       ; get X byte value
          plo rf
          ldi [I].1    
          phi rf          ; rf points to I 32-bit variable address
          inc rf
          inc rf
          inc rf
          ldn rf          ; point to Least Significant Byte
          plo ra          ; set X to I byte value
          ldi [J].0       ; get Y byte value
          plo rf
          ldi [J].1    
          phi rf          ; rf points to J 32-bit variable address
          inc rf
          inc rf
          inc rf          ; point to Least Significant Byte
          ldn rf       
          phi ra          ; set Y to J byte value
          sep scall
          dw  drawpixel   ; set pixel for sine wave
          sep scall
          dw  restoreregs
    end

170 GOSUB 500
180 NEXT I
190 PRINT "Done!"
200 GOTO 999

500 asm   
          ; subroutine to update display
          sep scall
          dw  saveregs
          sep scall
          dw  update
          sep scall
          dw  restoreregs
          sep sret
    end

900 PRINT "Video is off."
999 END
