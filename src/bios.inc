; *******************************************************************
; *** This software is copyright 2006 by Michael H Riley          ***
; *** You have permission to use, modify, copy, and distribute    ***
; *** this software so long as this copyright notice is retained. ***
; *** This software may not be used in commercial applications    ***
; *** without express written permission from the author.         ***
; *******************************************************************


; Define address for standard BIOS vectors
BIOS EQU 0ff00h


; Define address for extended BIOS vectors
EBIOS EQU 0f800h



; scall:      EQU  r4                    ; register for SCALL
; sret:       EQU  r5                    ; register for SRET

f_boot:     EQU  (BIOS+00h)            ; boot from ide device
f_type:     EQU  (BIOS+03h)            ; type 1 character to console
f_read:     EQU  (BIOS+06h)            ; read 1 character from console
f_msg:      EQU  (BIOS+09h)            ; type asciiz string to console
f_typex:    EQU  (BIOS+0ch)            ; depricated, just returns now
f_input:    EQU  (BIOS+0fh)            ; read asciiz from console
f_strcmp:   EQU  (BIOS+12h)            ; compare 2 strings
f_ltrim:    EQU  (BIOS+15h)            ; trim leading spaces
f_strcpy:   EQU  (BIOS+18h)            ; copy an asciiz string
f_memcpy:   EQU  (BIOS+1bh)            ; copy memory
f_wrtsec:   EQU  (BIOS+1eh)            ; write floppy sector (depricated)
f_rdsec:    EQU  (BIOS+21h)            ; read floppy sector (depricated)
f_seek0:    EQU  (BIOS+24h)            ; floppy seek to track 0 (depricated)
f_seek:     EQU  (BIOS+27h)            ; floopy track seek (depricated)
f_drive:    EQU  (BIOS+2ah)            ; select floppy drive (depricated)
f_setbd:    EQU  (BIOS+2dh)            ; set console baud rate
f_mul16:    EQU  (BIOS+30h)            ; 16-bit multiply
f_div16:    EQU  (BIOS+33h)            ; 16-bit division
f_idereset: EQU  (BIOS+36h)            ; reset ide device
f_idewrite: EQU  (BIOS+39h)            ; write ide sector
f_ideread:  EQU  (BIOS+3ch)            ; read ide sector
f_initcall: EQU  (BIOS+3fh)            ; initialize R4 and R5
f_bootide:  EQU  (BIOS+42h)            ; boot from ide device
f_hexin:    EQU  (BIOS+45h)            ; convert ascii number to hex
f_hexout2:  EQU  (BIOS+48h)            ; convert hex to 2-digit ascii
f_hexout4:  EQU  (BIOS+4bh)            ; convert hex to 4-digit ascii
f_tty:      EQU  (BIOS+4eh)            ; type character to console
f_mover:    EQU  (BIOS+51h)            ; program relocator
f_minimon:  EQU  (BIOS+54h)            ; mini monitor
f_freemem:  EQU  (BIOS+57h)            ; determine memory size
F_isnum:    EQU  (BIOS+5ah)            ; determine if D is numeric
f_atoi:     EQU  (BIOS+5dh)            ; convert ascii to integer
f_uintout:  EQU  (BIOS+60h)            ; convert unsigned integer to ascii
f_intout:   EQU  (BIOS+63h)            ; convert signed integer to ascii
f_inmsg:    EQU  (BIOS+66h)            ; type in-line message
f_inputl:   EQU  (BIOS+69h)            ; read limited line from console
f_brktest:  EQU  (BIOS+6ch)            ; check for serial break
f_findtkn:  EQU  (BIOS+6fh)            ; find token in a token table
f_isalpha:  EQU  (BIOS+72h)            ; determine if D is alphabetic
f_ishex:    EQU  (BIOS+75h)            ; determine if D is hexadecimal
f_isalnum:  EQU  (BIOS+78h)            ; determine if D is alpha or numeric
f_idnum:    EQU  (BIOS+7bh)            ; determine type of ascii number
f_isterm:   EQU  (BIOS+7eh)            ; determine if D is a termination char
f_getdev:   EQU  (BIOS+81h)            ; get supported devices

f_version:  EQU  (BIOS+0f9h)           ; 3 bytes holding bios version number

; "Extended" BIOS vectors

f_bread     EQU  (EBIOS+00h)        ; read from onboard serial port
f_btype     EQU  (EBIOS+03h)        ; write to onboard serial port
f_btest     EQU  (EBIOS+06h)        ; test onboard serial port
f_utype     EQU  (EBIOS+09h)        ; write to disk board UART
f_uread     EQU  (EBIOS+0ch)        ; read from disk board UART
f_utest     EQU  (EBIOS+0fh)        ; test disk board UART
f_usetbd    EQU  (EBIOS+12h)        ; set disk board UART baud rate and format
f_gettod    EQU  (EBIOS+15h)        ; read time of day clock
f_settod    EQU  (EBIOS+18h)        ; set time of day clock
f_rdnvr     EQU  (EBIOS+1bh)        ; read non volatile RAM
f_wrnvr     EQU  (EBIOS+1eh)        ; write non volatile RAM
f_idesize   EQU  (EBIOS+21h)        ; return size of attached IDE drive(s)
f_ideid     EQU  (EBIOS+24h)        ; return device data for IDE drive(s)
f_tmtoas    EQU  (EBIOS+2ah)        ; time to ASCII string
f_dttoas    EQU  (EBIOS+27h)        ; date to ASCII string
f_rtctest   EQU  (EBIOS+2dh)        ; test size and presence of RTC/NVR
f_astodt    EQU  (EBIOS+30h)        ; convert ASCII string to date
f_astotm    EQU  (EBIOS+33h)        ; convert ASCII string to time
