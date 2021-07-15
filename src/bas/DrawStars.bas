
10  asm
             ; define labels for video routines in ROM
isready:     equ 0A545H
saveregs:    equ 0A218H
restoreregs: equ 0A249H
println:     equ 0A199H 
update:      equ 0A280H
clear:       equ 0A0C9H
drawpixel:   equ 0A566H 
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
    
80  FOR I=1 to 100    
90  X = RND(64)
100 Y = RND(64)
110 asm
          ; draw random dot on display
          sep scall
          dw  saveregs          
          ldi [X].0       ; get X byte value
          plo rf
          ldi [X].1    
          phi rf          ; rf points to X 16-bit variable address
          inc rf
          ldn rf          ; point to Least Significant Byte
          plo ra          ; set X to byte value
          ldi [Y].0       ; get Y byte value
          plo rf
          ldi [Y].1    
          phi rf          ; rf points to Y 16-bit variable address
          inc rf          ; point to Least Significant Byte
          ldn rf       
          phi ra          ; set Y to byte value
          sep scall
          dw  drawpixel   ; set pixel on display
          sep scall
          dw  restoreregs
    end
120 GOSUB 500
130 NEXT I
140 PRINT "Done!"
150 GOTO 999

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
