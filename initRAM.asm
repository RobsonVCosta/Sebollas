


; copia HL->DE
		
;=== init vars ======
;variaveis temporárias na ROM que vão para a RAM em InitVarsAtRAM



_init_sprite_fuscaFront_attr: db 130, 100, 0, BLACK, 0   ;y, x, nPtrn, Color	, status: (0 enable, 1 disable)
_init_sprite_fuscaBack_attr: db 146, 100, 4, BLACK, 0   ;y,
_init_sprite_2_attr: db 120, 100, 8, BLACK, 0, DELAY_BULLETS ;y, x, nPtrn, Color, status: (0 enable, 1 disable) , delay entre o proximo bullet
_init_sprite_3_attr: db 120, 100, 8, BLACK, 0, DELAY_BULLETS
_init_sprite_4_attr: db 13, 100, 12, RED, 1


_init_score: db 0, 0, 0, 0, 0, 0
_init_somarBCD_8D db 0x00,0x00,0x00,0x10
_init_scoreBCD_8Digits db 0x00,0x00,0x00,0x00
; copiar valor inicial da ROM para RAM
InitVarsAtRAM:
        ;Tiled Map
		ld hl, COUNT_TILE ; HL aponta para o byte na ROM
		ld de, _shiftTileCount ; DE aponta para a variável em RAM
		ld bc, 1 		; tamanho em bytes
		ldir
        ld hl, 00h ; HL aponta para o byte na ROM
		ld de, _shiftTile ; DE aponta para a variável em RAM
		ld bc, 2 		; tamanho em bytes
		ldir
        
		;Andamento da música		 
		ld hl, ADAGIO ; HL aponta para o byte na ROM
		ld de, _music_time ; DE aponta para a variável em RAM
		ld bc, 1 		; tamanho em bytes

        ;Sprites          
        ld hl, _init_sprite_fuscaFront_attr   ; fonte: dados na ROM
        ld de, _sprite_fuscaFront_attr        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir  
        ld hl, _init_sprite_fuscaBack_attr   ; fonte: dados na ROM
        ld de, _sprite_fuscaBack_attr        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir  
        ld hl, _init_sprite_2_attr   ; fonte: dados na ROM
        ld de, _sprite_2_attr        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir   
        ld hl, _init_sprite_3_attr   ; fonte: dados na ROM
        ld de, _sprite_3_attr        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir     
		ld hl, _init_sprite_4_attr   ; fonte: dados na ROM
        ld de, _sprite_4_attr        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir 

		ld hl, _init_score   ; fonte: dados na ROM
        ld de, _score        ; destino: RAM
        ld bc, 6                     ; quantidade de bytes
        ldir 
        ld hl, _init_somarBCD_8D   ; fonte: dados na ROM
        ld de, _somarBCD_8D        ; destino: RAM
        ld bc, 4                     ; quantidade de bytes
        ldir 
        ld hl, _init_scoreBCD_8Digits   ; fonte: dados na ROM
        ld de, _scoreBCD_8Digits        ; destino: RAM
        ld bc, 4                     ; quantidade de bytes
        ldir 

        ret

