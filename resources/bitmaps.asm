		
; --- tile #1: bitmap 8 bytes (cada byte = 8 pixels, bit1=acende cor FG) ---
_tile0_Bitmap:	
	db %01000000
	db %10100000
	db %01000100
	db %10010000
	db %01000010
	db %00010010
	db %01000000
	db %00000100
; --- cores por linha: (BG<<4 | FG). Ex.: BG=1 (azul escuro), FG=14 (amarelo) ---
_tile0_Colors:	
		db $3b,$3b,$3b,$3b,$3b,$3b,$3b,$3b
		
; --- tile #1: bitmap 8 bytes (cada byte = 8 pixels, bit1=acende cor FG) ---
_tile1_Bitmap:	
	db %10010001
	db %11001010
	db %01101100
	db %11100011
	db %00111101
	db %11010100
	db %01000110
	db %10001001
; --- cores por linha: (BG<<4 | FG). Ex.: BG=1 (azul escuro), FG=14 (amarelo) ---
_tile1_Colors:	
		db $ab,$ab,$ab,$eb,$e3,$e3,$ab,$ab
		
; --- tile #1: bitmap 8 bytes (cada byte = 8 pixels, bit1=acende cor FG) ---
_tile2_Bitmap:
    db %00010000
    db %00110000
    db %01111100
    db %11011110
    db %11011010
    db %11011011
    db %00010000
    db %00010000
; --- cores por linha: (BG<<4 | FG). Ex.: BG=1 (azul escuro), FG=14 (amarelo) ---
_tile2_Colors:
    db $db,$cb,$2b,$2b,$cb,$cb,$0b,$0b