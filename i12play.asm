		include ram_vars.asm ; declara símbolos de RAM
		include bios.asm
	
		
		OUTPUT i12play.rom ; sjasmplus: força nome de saída (opcional, se sua versão suportar)
		
		
		
		org 0x4000
		db 'A','B'              ; 0x00..0x01 = "AB" -> marca ROM
		dw START 		; +2..+3 = INIT (little-endian) -> chamada pelo BIOS
		dw 0x0000 		; +4..+5 = STATEMENT (0 se não usado)
		dw 0x0000 		; +6..+7 = DEVICE (0 se não usado)
		dw 0x0000 		; +8..+9 = TEXT (0 se não usado — cuidado se estiver em 8000h)
		db 0,0,0,0,0,0         ; +10..+15 = reservado (zeros)
		
		include sfx.inc
		include math.asm
		include "resources/screenMap.asm"
		include string.asm
		include "resources/bitmaps.asm"
		include sprites.spr
		include initRAM.asm
		include keyboard.asm
		include bitset.asm




		ld hl, 0xC090		
		add a,  0
		ld (hl), a



		
START:	
		call InitVarsAtRAM    
		call ResetPreviousKeys

		call Screen2
		
		;ld c, BLACK
		;ld b, WHITE
		;call SetColor

        call InitSound
		call InitTileBitmap
	

		
		ld  hl,_ascii
		ld  de,CHRTBL + 45*8 + 0000h
		ld  bc,8*40
		call LDIRVM
		

		ld  hl,_Ascii_Color
		ld  de,CLRTBL + 45*8 + 0000h
		ld  bc,8*40
		call LDIRVM



		
;------definição da forma do sprite --------
		ld bc, 32 		;sprite len
		ld de, SPTPAT 	; Sprite Pattern Table
		ld hl, _fuscaFront
		call LDIRVM 	; copia bloco RAM->VRAM: DE= patter table, HL= sprite Data, BC=len
        ;---posicionamento do Sprite-----
        ;ld bc, 4 ;sprite len
        ; ld de, SAT  ; Sprite Attribute Table (4 bytes)
        ; ld hl, _sprite_fuscaFront_attr
        ; call LDIRVM

		;------definição da forma do sprite --------
		ld bc, 32 		;sprite len
		ld de, SPTPAT + 4 * 8 	; Sprite Pattern Table
		ld hl, _fuscaBack
		call LDIRVM 	; copia bloco RAM->VRAM: DE= patter table, HL= sprite Data, BC=len
        ;---posicionamento do Sprite-----
        ;ld bc, 4 ;sprite len
        ; ld de, SAT  ; Sprite Attribute Table (4 bytes)
        ; ld hl, _sprite_fuscaFront_attr
        ; call LDIRVM	
		
		;------definição da forma do sprite --------
		ld bc, 32 		;sprite len
		ld de, SPTPAT + 8 * 8 ; Sprite Pattern Table (formas 8x8)
		ld hl, _sprite_2
		call LDIRVM 	; copia bloco RAM->VRAM: DE= patter table, HL= sprite Data, BC=len
        ;---posicionamento do Sprite-----
        ;ld bc, 4 ;sprite len
        ;ld de, SAT  + 1*4; Sprite Attribute Table (4 bytes)
        ;ld hl, _sprite_2_attr
        ;call LDIRVM

		;------definição da forma do sprite --------
		ld bc, 32 		;sprite len
		ld de, SPTPAT + 12 * 8 ; Sprite Pattern Table (formas 8x8)
		ld hl, _sprite_3
		call LDIRVM 	; copia bloco RAM->VRAM: DE= patter table, HL= sprite Data, BC=len
        ;---posicionamento do Sprite-----
   
		ei		
    	nop     ; permite que o EI surta efeito
main_loop:	
		halt ; espera VBlank (gera a IRQ do VDP)
		
		call ScanKeyboard

		;Teste de teclas
		ld hl, 0xC080
		ld a, (hl)
		ld hl, _teclas		
		ld e, a
		ld d, 0
		add hl, de
		ld a, (hl)
	    ;quebrando em nibble
		ld e, a      ; E = A = 0xEF
		and 0x0F     ; A = 0x0F
		ld e, a      ; E = 0x0F

		ld a, (hl)   ; recarrega
		srl a        ; desloca 4 bits p/ direita
		srl a
		srl a
		srl a        ; agora A = 0x0E
		ld d, a      ; D = 0x0E
		call GetKeyState	
		cp 1
		jr z, .down
		cp 2
		jr z, .release		
.back		
		call UpdateScore
   	
		call WaitInput 	; aguarda direção/space e despacha       
		call MoveTileBitmap
		call UpdateSound
		call UpdateAllSprites
        ;detecta colisão sprite
        ld   a,(STATFL)      ; lê a cópia salva pela BIOS
        bit  5,a             ; 1 = houve colisão de sprites neste frame
        jr   z, .noCollision
        ; ... fazer checagem fina em software ...

		ld a, (_sprite_4_attr + 4)
		xor a
		ld (_sprite_4_attr + 4), a	
.noCollision
		jr main_loop 	; continua para novas entradas
		
.down
	ld hl, 0xC080
	ld a, (hl)
	add a, a ; A = 2*A
	
	;soma oitava
	ld de,$C090
	ld h,d
    ld l,e          ; HL = DE
    add a,(hl)      ; A = A + (C090h) 

	ld b, 0
	call PlayNote
	jr .back

.release	
	ld hl, 0xC080
	ld a, (hl)
	inc a
	ld (hl), a
	ld a, 8 
	call FinishNote
	jr .back	
;====================FIM MAIN LOOP =============================

GetJIFFY:	
		di
		ld hl, (JIFFY) 	; lê 2 bytes menos significativos		
		ei
; agora: A:HL = contador de 24 bits
		ret    	
		
;========== updateSprite =====
;Atualiza posicionamento e cor do Sprite
;Atualiza a VRAM com o espleho em RAM
; A = índice (0..31)
; HL -> [Y, X, pattern, color]
UpdateSprite:	
		push af 		; vamos usar HL p/ calcular, então salvamos A e HL
		push hl
		
; DE = SAT + A*4
		ld l, a
		ld h, 0
		add hl, hl 		; *2
		add hl, hl 		; *4
		ld de, SAT
		add hl, de 		; HL = SAT + A*4
		ex de, hl 		; DE = destino VRAMf
		
		pop hl 			; HL = origem RAM (atributos)
		ld bc, 4
		call LDIRVM 	; copia 4 bytes RAM->VRAM
		
		pop af
		RET
		
Fire1:	
		ld a, (_sprite_2_attr + 4)
		or a
		jp nz, .doNothingFire1
		
;se já está atirando bullet2
		ld a, (_sprite_3_attr + 4)
		or a
		jp z, .goAheadMakeMyDay
;dá um "delay" entre o bullet
		ld a, (_sprite_3_attr + 5) ; delay para liberar bullet 2
		dec a
		ld (_sprite_3_attr + 5), a
		JP nz, .doNothingFire1
.goAheadMakeMyDay
;reposiciona o bullet para dentro do heroi
		ld a, (_sprite_fuscaFront_attr)
		;add a, 6
		ld (_sprite_2_attr), a
		ld a, (_sprite_fuscaFront_attr + 1)
		ld (_sprite_2_attr + 1), a
		
        ;ativa o fire
		ld a, (_sprite_2_attr + 4)
		ld a, 1
		ld (_sprite_2_attr + 4), a 				
	
		ld b, CHANNEL_A ; 
		call VerifyIsBusyChannel
		jp nz, .doNothingFire1

		
		ld de, _fire1
		call SetMusicData
		
		call StartMusic		

		ld hl, _scoreBCD_8Digits
		ld de, _somarBCD_8D
		call SUM_BCD_8D		
		ld hl, _scoreBCD_8Digits
		ld de, _score
		call BcdToString


.doNothingFire1
		ret
		
;Parametros: ix = _firing2    ; db Y,X,pattern,cor, state: 0 disable 1 enable
StopFire:		
		xor a
		ld (ix + 4), a 	;set status=0
		ld (ix + 5), DELAY_BULLETS ;set delay para liberar bullet 2
		ret
		
Fire2:	
;se já está atirando bullet2
		ld a, (_sprite_3_attr + 4)
		or a
		jp nz, .doNothingFire2
;se bullet1 ainda não está enable
		ld a, (_sprite_2_attr + 4)
		or a
		JP z, .doNothingFire2
;dá um "delay" entre o bullet
		ld a, (_sprite_2_attr + 5) ; delay para liberar bullet 2
		dec a
		ld (_sprite_2_attr + 5), a
		JP nz, .doNothingFire2
		
;se fire 1 ainda não está enable
		ld a, (_sprite_2_attr + 4)
		or a
		JP z, .doNothingFire2
		
;reposiciona o bullet para dentro do heroi
		ld a, (_sprite_fuscaFront_attr)
		;add a, 6
		ld (_sprite_3_attr), a
		  
		ld a, (_sprite_fuscaFront_attr + 1)
		
		ld (_sprite_3_attr + 1), a
;ativa o fire
		ld a, (_sprite_3_attr + 4)
		ld a, 1
		ld (_sprite_3_attr + 4), a
		
		ld b, CHANNEL_B ; 
		call VerifyIsBusyChannel
		jp nz, .doNothingFire2
		ld b, CHANNEL_B ; 
		ld de, _fire1

		call SetMusicData
		
		call StartMusic	
		
.doNothingFire2
		ret
		
;--------------  Updatefire ------------
;Parametros: ix = _sprite_2_attr    ; db Y,X,pattern,cor
Updatefire:	
		ld a, (ix)
		sub 5
		ld (ix), a
		jp c, .removeFire ; se underflow (era <5)
; caso contrário, segue o fluxo normal
		
		push ix
		pop hl
		ld a, (ix + 3) 	; sprite #3, por exemplo
		call UpdateSprite
		ret
.removeFire
		sub 3
		ld (ix), a
		push ix
		pop hl		
		ld (ix), 200	;set y para fora da tela
		ld a, (ix + 3) 	; sprite #3, por exemplo
		call UpdateSprite
		call StopFire
		ret
		
UpdateAllSprites:	
		ld hl, _sprite_fuscaFront_attr ; db Y,X,pattern,cor
		ld a, 0 ; sprite #3, por exemplo
		call UpdateSprite

		ld hl, _sprite_fuscaBack_attr ; db Y,X,pattern,cor
		ld a, 4 ; sprite #3, por exemplo
		call UpdateSprite

		ld hl, _sprite_4_attr ; db Y,X,pattern,cor		
		ld a, (_sprite_4_attr + 4) 
		or a 
		ld a, (_sprite_4_attr + 3) ; sprite #3, por exemplo
		call nz, UpdateSprite
		
		ld a, (_sprite_2_attr + 4)
		or a 			;Já que ld, a não altera flags
		ld ix, _sprite_2_attr
		call nz, Updatefire
		
		ld a, (_sprite_3_attr + 4)
		or a
		ld ix, _sprite_3_attr
		call nz, Updatefire
		ret
;==================== Background TileMap =============================
		
		
InitTileBitmap:	
;========================================
; --- escreve tile #1 no CHRTBL (#1*8) e suas cores no CLRTBL (#1*8) ---
; Banco 0 (linhas 0–7): +0x0000
		ld hl, _tile0_Bitmap
		ld de, CHRTBL + 0 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile0_Colors
		ld de, CLRTBL + 0 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
; Banco 1 (linhas 8–15): +0x0800
		ld hl, _tile0_Bitmap
		ld de, CHRTBL + 0 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile0_Colors
		ld de, CLRTBL + 0 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
; Banco 2 (linhas 16–23): +0x1000
		ld hl, _tile0_Bitmap
		ld de, CHRTBL + 0 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile0_Colors
		ld de, CLRTBL + 0 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
; --- escreve tile #1 no CHRTBL (#1*8) e suas cores no CLRTBL (#1*8) ---
; Banco 0 (linhas 0–7): +0x0000
		ld hl, _tile1_Bitmap
		ld de, CHRTBL + 1 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile1_Colors
		ld de, CLRTBL + 1 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
; Banco 1 (linhas 8–15): +0x0800
		ld hl, _tile1_Bitmap
		ld de, CHRTBL + 1 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile1_Colors
		ld de, CLRTBL + 1 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
; Banco 2 (linhas 16–23): +0x1000
		ld hl, _tile1_Bitmap
		ld de, CHRTBL + 1 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile1_Colors
		ld de, CLRTBL + 1 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
;========================================
; --- escreve tile #1 no CHRTBL (#1*8) e suas cores no CLRTBL (#1*8) ---
; Banco 0 (linhas 0–7): +0x0000
		ld hl, _tile2_Bitmap
		ld de, CHRTBL + 2 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile2_Colors
		ld de, CLRTBL + 2 * 8 + 0000h
		ld bc, 8
		call LDIRVM
		
; Banco 1 (linhas 8–15): +0x0800
		ld hl, _tile2_Bitmap
		ld de, CHRTBL + 2 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile2_Colors
		ld de, CLRTBL + 2 * 8 + 0800h
		ld bc, 8
		call LDIRVM
		
; Banco 2 (linhas 16–23): +0x1000
		ld hl, _tile2_Bitmap
		ld de, CHRTBL + 2 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
		ld hl, _tile2_Colors
		ld de, CLRTBL + 2 * 8 + 1000h
		ld bc, 8
		call LDIRVM
		
		
		ret
		
		
MoveTileBitmap:	
;Shift tilemap
		ld a, (_shiftTileCount)
		dec a
		ld (_shiftTileCount), a
		jp nz, .doNothing
;move tile
		ld a, COUNT_TILE
		ld (_shiftTileCount), a
		ld bc, (_shiftTile)
		
;Agora desenha ele deslocado
; BC := BC + 32
		ld hl, 32
		add hl, bc 		; HL = BC + 32
		ld b, h
		ld c, l
		
; if (BC >= 1280, BC >= 0x0500 em HEX) then BC = 0
		ld a, b
		cp 5
		jr c, .ok 		; B<3  => BC<=0x02FF
		xor a
		ld b, a
		ld c, a 		; BC = 0
.ok:	
		
		ld (_shiftTile), bc
		call UpdateScreenMap
.doNothing:	
		RET
		
;Espera receber o ld  hl, _screenMap     ; origem (RAM)
DrawTileBitmap:	
		ld de, NAMTBL 	; destino (VRAM)
		ld bc, 32 * 24 	; 768 bytes
		call LDIRVM 	; copia RAM -> VRAM
		ret
		
UpdateScreenMap:	
		ld bc, (_shiftTile) ;0..1024 == 40 linhas
		ld hl, _screenMap + 39 * 32
		or a 			;limpa carry visto que o sbc somaria com o carry
		sbc hl, bc
		call DrawTileBitmap
		ret

		
		
CheckCollisionWithScreenMap:					;(uma função pra bullet e outro para o heroi
		
;_shiftTile ;posição inicial do _screenMap
;_sprite_fuscaFront_attr: db 130, 100, 0, BLACK   ;y, x, nPtrn, Color
		
;screenX = _sprite_fuscaFront_attr.x/8;;
;if _screenMap[_shiftTile][screenX] != 0 { colidiuX}
;screenY = _sprite_fuscaFront_attr.y/8;
;if _screenMap[_shiftTile][screenY] != 0 { colidiuY}
;//adicionar os devidos offSets na verificação da colisão.
		ret
		
CheckCollisionWithEnemy:					;Enemy pode ser um tiro ou o próprio
;(uma função para o bullet e outro para o heroi
		
;_sprite_Enemy_attr: db 130, 100, 0, BLACK   ;y, x, nPtrn, Color
;_sprite_fuscaFront_attr: db 130, 100, 0, BLACK   ;y, x, nPtrn, Color
		
;if _sprite_Enemy_attr.x == _sprite_fuscaFront_attr.x { colidiuX}
;if _sprite_Enemy_attr.y == _sprite_fuscaFront_attr.y { colidiuY}
;//adicionar os devidos offSets na verificação da colisão.
		ret

		
	

DELAY_BULLETS equ 10
		
		
		
UpdateScore:		
	ld a, 23
	ld (_Print), a
	ld a, 1
	ld (_Print + 1), a
	ld hl, _score
	ld (_Print + 2), hl
	ld ix, _Print
	call Print
	ret
; -----------------------------------------
; WAIT_INPUT
; - espera até que haja uma direção (setas) ou SPACE
; - chama a rotina correspondente e retorna
; -----------------------------------------
WaitInput:	
		
		call Check_Space
; 1) direção das setas (cursor keys)
		xor a
		call GTSTCK 	; A = 0 (centro), 1(↑),2,3(→),4,5(↓),6,7(←),8
		cp 1 			; ↑
		jp z, HANDLE_UP
		cp 2 			; ↗
		jp z, HANDLE_UP_RIGHT
		cp 3 			; →
		jp z, HANDLE_RIGHT
		cp 4 			; ↘
		jp z, HANDLE_DOWN_RIGHT
		cp 5 			; ↓
		jp z, HANDLE_DOWN
		cp 6 			; ↙
		jp z, HANDLE_DOWN_LEFT
		cp 7 			; ←
		jp z, HANDLE_LEFT
		cp 8 			; ↖
		jp z, HANDLE_UP_LEFT
		ret
		
		
Check_Space:	
; 2) SPACE como “trigger 0”
		xor a 			; A=0 -> lê SPACE
		call GTTRIG 	; A != 0 se pressionado
		or a
		jr z, .return
		jp HANDLE_SPACE
.return
		ret
; -----------------------------------------
; Handlers de exemplo
; (aqui só troco a cor do fundo para demonstrar;
;  substitua pelo que você quiser fazer)
; -----------------------------------------
HANDLE_UP:	
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr), a  

		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr), a  
		ret
		
HANDLE_UP_RIGHT:	
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr), a
		
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr + 1), a

		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr), a
		
		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr + 1), a
		ret
HANDLE_RIGHT:	
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr + 1), a		

		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr + 1), a	

		ld a, (_sprite_4_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_4_attr + 1), a			

		ld hl, 0xC090
		ld a, (hl)
		add a,  18h
		ld (hl), a
		
.isBusy	
		ret


HANDLE_DOWN_RIGHT:	
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr + 1), a
		
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr), a

		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr + 1), a
		
		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr), a

		ret
HANDLE_DOWN:	
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr), a	


		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr), a	
		ret
		
HANDLE_DOWN_LEFT:	
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaFront_attr), a
		
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr + 1), a
		
		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		add a, (hl)
		ld (_sprite_fuscaBack_attr), a
		
		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr + 1), a


		ret
HANDLE_LEFT:	
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr + 1), a	

		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr + 1), a			

		ld a, (_sprite_4_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_4_attr + 1), a

		ld hl, 0xC090
		ld a, (hl)
		sub 18h
		ld (hl), a
.isBusy
		ret
		
HANDLE_UP_LEFT:	
		ld a, (_sprite_fuscaFront_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr + 1), a
		ld a, (_sprite_fuscaFront_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaFront_attr), a


		ld a, (_sprite_fuscaBack_attr + 1)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr + 1), a
		ld a, (_sprite_fuscaBack_attr)
		ld hl, _heroSpeed
		sub (hl)
		ld (_sprite_fuscaBack_attr), a
		ret
		
		
_heroSpeed:	db 1
HANDLE_SPACE:			
		call Fire1
		call Fire2
		
		ret
		
		
		
Screen2:	
;; ld  a,2
;;call CHGMOD
		call INIGRP
		call ClearScreen
;---- força exibir texto o screen 2. Naõ faz sentido mas funciona
;GICINI equ 006Bh
;call 006Bh
		
		call ERAFNK 	; desligar FKEY da barra inferior
		XOR A
		LD (KEYSND), A 	; desligar Beep do teclado
		call SetBorder
;set 16x16 sprites
		ld bc, 0e201h 	; write e2h in VDP register 01h (activate sprites, generate interrupts, set 16x16 sprites)
		call WRTVDP
		ret
		
ClearScreen:	
; 2) Zera os padrões (bitmap 8x8) -> todos os bits = 0
;    Pattern tables (3 bandas): 0000h..17FFh  (6 KB = 0x1800)
; limpa a Name Table
		ld hl, NAMTBL
		ld bc, 32 * 24
		xor a
		call FILVRM
		ret
		
; --- Sub-rotina: SetColor(c, b) ---
; c = cor 0..15, b = background 0..15
SetColor:	
		ld a, c
		rlca 			; duplica nibble: (A<<4)
		rlca
		rlca
		rlca
		or b 			; A = (cor<<4) | cor
		ld hl, CLRTBL 	; Color tables: 2000h..37FFh (3 bandas, 6KB)
		ld bc, 1800h
		call FILVRM
		ret
; ------------------------------------------
; BORDER
; Entrada: A = cor 0..15
; Muda apenas a cor da borda
; ------------------------------------------
SetBorder:	
		and 0Fh 		; garante faixa 0..15
		ld c, 7 		; registrador 7
		call WRTVDP
		ret
		
	
COUNT_TILE equ 30


