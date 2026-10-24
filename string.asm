; -------------------------------------------------------
; PRINT
; Entrada:  L = linha (0..23), C = coluna (0..31), DE -> string (0-terminada)
; Efeito : Escreve na Name Table com WRTVRM (sem usar instruções ilegais)
; Usa    : HL (VRAM)
; -------------------------------------------------------
Print:	
		push ix
		ld l, (ix + 1) 	; x
		ld c, (ix) 		; y
		ld e, (ix + 2) 	; L = low(ptr)
		ld d, (ix + 3) 	; H = high(ptr)  => HL = &msg
; Calcula HL = NAMTBL + (linha*32) + coluna
		ld h, 0
		add hl, hl 		; *2
		add hl, hl 		; *4
		add hl, hl 		; *8
		add hl, hl 		; *16
		add hl, hl 		; *32
		ld b, 0
		add hl, bc 		; HL = linha*32 + coluna
		ld bc, NAMTBL
		add hl, bc 		; HL = endereço VRAM destino
		
.p_loop:	
		ld a, (de)
		or a
		jr z, .p_done
		call WRTVRM
		inc de
		inc hl
		jr .p_loop
.p_done:	
		pop ix
		
		
		
		
;===========================================================
; BIN8_TO_BINSTRING
; Converte o conteúdo de A em uma string ASCII "00000000"
; Entrada:
;   A  = valor a converter (8 bits)
;   HL = endereço onde salvar a string (8 bytes)
; Saída:
;   (HL..HL+7) = '0' ou '1' (sem terminador 0)
; Usa: A,B,C,D,E,H,L,F
;===========================================================
		
BinaryToSting:	
		ld b, 8 		; vamos gerar 8 caracteres
.loop:	
		rlca 			; rota A à esquerda, bit7 -> Carry
		ld c, '0'
		jr nc, .store
		ld c, '1'
.store:	
		ld (hl), c
		inc hl
		djnz .loop
		ret
		
bin_string:	db "--------",0     ; espaço para a string "00010011"
		
; ------------------------------------------------------
; BCD8_TO_STRING
; Converte 4 bytes BCD "packed" (8 dígitos) em 8 ASCII '0'..'9'
; Entrada:
;   HL = &_scoreBCD_8Digits   ; 4 bytes: [HH|LL]*4  (ex.: 0x99,0x12,0x30,0x45)
;   DE = &_scoreString        ; 8 bytes de destino
; Saída:
;   _scoreString = "99123045" no exemplo
; Regs afetados: A, B, C, HL, DE, F
; ------------------------------------------------------
		
BcdToString:	
		ld b, 4 		; 4 bytes => 8 dígitos
.conv_loop:	
		ld a, (hl) 		; lê um byte packed (duas casas decimais)
		inc hl
		ld c, a
		
; --- nibble alto (dígito 1)
		ld a, c
		srl a
		srl a
		srl a
		srl a 			; A = (C >> 4)
		add a, '0'
		ld (de), a
		inc de
		
; --- nibble baixo (dígito 2)
		ld a, c
		and 0x0F 		; A = C & 0x0F
		add a, '0'
		ld (de), a
		inc de
		
		djnz .conv_loop
		ret


_ascii: DB $00,$00,$00,$00,$00,$00,$00,$00 ;Space
		DB $3C,$42,$99,$A1,$A1,$99,$42,$3C ;copyright
        DB $00,$00,$00,$00,$7E,$00,$00,$00 ;-
		DB $00,$1C,$22,$63,$63,$63,$22,$1C ;0
        DB $00,$18,$38,$18,$18,$18,$18,$7E ;1
        DB $00,$3E,$63,$03,$0E,$3C,$70,$7F ;2
        DB $00,$3E,$63,$03,$0E,$03,$63,$3E ;3
        DB $00,$0E,$1E,$36,$66,$66,$7F,$06 ;4
        DB $00,$7F,$60,$7E,$63,$03,$63,$3E ;5
        DB $00,$3E,$63,$60,$7E,$63,$63,$3E ;6
        DB $00,$7F,$63,$06,$0C,$18,$18,$18 ;7
        DB $00,$3E,$63,$63,$3E,$63,$63,$3E ;8
        DB $00,$3E,$63,$63,$3F,$03,$63,$3E ;9        
        DB $00,$1C,$36,$63,$63,$7F,$63,$63 ;A
        DB $00,$7E,$63,$63,$7E,$63,$63,$7E ;B
        DB $00,$3E,$63,$60,$60,$60,$63,$3E ;C
        DB $00,$7C,$66,$63,$63,$63,$66,$7C ;D
        DB $00,$7F,$60,$60,$7E,$60,$60,$7F ;E
        DB $00,$7E,$60,$7C,$60,$60,$60,$60 ;F
        DB $00,$3E,$63,$60,$67,$63,$63,$3F ;G
        DB $00,$63,$63,$63,$7F,$63,$63,$63 ;H
        DB $00,$3C,$18,$18,$18,$18,$18,$3C ;I
        DB $00,$1F,$06,$06,$06,$06,$66,$3C ;J
        DB $00,$63,$66,$6C,$78,$7C,$6E,$67 ;K
        DB $00,$60,$60,$60,$60,$60,$60,$7F ;L
        DB $00,$63,$77,$7F,$7F,$6B,$63,$63 ;M
        DB $00,$63,$73,$7B,$7F,$6F,$67,$63 ;N
        DB $00,$3E,$63,$63,$63,$63,$63,$3E ;O
        DB $00,$7E,$63,$63,$63,$7E,$60,$60 ;P
        DB $00,$3E,$63,$63,$63,$6B,$66,$3B ;Q 
        DB $00,$7E,$63,$63,$62,$7C,$66,$63 ;R     
        DB $00,$3E,$63,$60,$3E,$03,$63,$3E ;S     
        DB $00,$7E,$18,$18,$18,$18,$18,$18 ;T
        DB $00,$63,$63,$63,$63,$63,$63,$3E ;U
        DB $00,$63,$63,$63,$63,$36,$1C,$08 ;V
        DB $00,$63,$63,$6B,$6B,$7F,$77,$22 ;w
        DB $00,$63,$76,$3C,$1C,$1E,$37,$63 ;X
        DB $00,$66,$66,$7E,$3C,$18,$18,$18 ;Y
        DB $00,$7F,$07,$0E,$1C,$38,$70,$7F ;Z 


; --- cores por linha: (BG<<4 | FG). Ex.: BG=1 (azul escuro), FG=14 (amarelo) ---
_Ascii_Color: defs 400, $f0 


		