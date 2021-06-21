#define BOOTS	   08000H
#define WARMB	   08003H
#define HELP	   09500H	
#define RAMPAGE	 07F00H	
#define BIOS 	   0FF00H
#define EBIOS 	 0F800H
#define PIXIE    01861H
#define XMODEM 	 0F000H
#define SEDIT    0D300H
#define FORTH    0A600H
#define EDTASM   0B500H
#define BASIC    0D600H
#define VISUAL   0C200H
#define XMODEM   0F000H	

; Pixie Video
SWITCHES .EQU	4	; toggle switches or HEX keypad (read only)
CDP1861	 .EQU	1	; CDP1861 pixie chip
#define PIXIE_ON	SEX SP\ DEC SP\ INP CDP1861\ INC SP
#define PIXIE_OFF	SEX SP\ OUT CDP1861\ DEC SP
