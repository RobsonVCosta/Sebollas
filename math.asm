		
; =========================
; Mul8x8to16
; Entrada:
;   B = multiplicador
;   C = multiplicando
; Saída:
;   E:C = resultado 16 bits
; Temporários:
;   A
; =========================
;será usado para converter o tempo da nota levando em conta o andamento
Mul8x8to16:	
		push hl
		push af
		ld e, 0 		; Inicializa resultado LSB
		ld d, 0 		; Inicializa resultado MSB
		
		ld a, b 		; A = multiplicador
		ld h, 8 		; contador de 8 bits
		
.mulLoop:	
; verifica bit 0 de A (multiplicador)
		bit 0, a
		jr z, .skipAdd
		
; adiciona C ao resultado E:C
		push af
		ld a, e
		add a, c
		ld e, a
		jr nc, .notInc
		inc d
.notInc:	
		pop af
		
.skipAdd:	
; shift multiplicador e multiplicando para próximo bit
		rra 			; shift right A (multiplicador)
		sla c 			; shift left C
		rl d 			; shift carry de C para D
		
		dec h
		ld a, h
		or a
		jr nz, .mulLoop
		pop af
		pop hl
		ret

;---------------------------------------------------
; MUL8 (otimizada)
; Entrada: A = multiplicando (8 bits), B = multiplicador (8 bits)
; Saída:   HL = A * B (16 bits)
; Observação: destrói A,B,C,D,E,H,L
;---------------------------------------------------
Mult8bx8b_16b:
    ld   e, a        ; E = multiplicando (low)
    ld   d, 0        ; D = 0  (DE = multiplicando como 16-bit)
    ld   c, b        ; C = multiplicador (cópia)
    xor  a           ; A = 0 (opcional, limpa flags)
    ld   h, 0
    ld   l, 0        ; HL = 0 (acumulador)

    ld   b, 8        ; contador para DJNZ (8 iterações)
.mul_loop:
    srl  c           ; shift right logical C -> carry = antigo bit0
    jr   nc, .noadd  ; se bit0 = 0, pula a adição
    add  hl, de      ; HL += DE  (DE é multiplicando deslocado)
.noadd:
    sla  e           ; shift left E (low byte), carry = antigo bit7 de E
    rl   d           ; rotaciona D via carry (insere E7 em D0)
    djnz .mul_loop

    ret
		
; ==================================================
; ADD24_16
; Soma um valor de 24 bits (HL:A) com 16 bits (DE).
;----
; Entrada:
;    H = byte mais significativo (MSB)
;    L = byte intermediário
;    A = byte menos significativo (LSB)
;    DE = valor de 16 bits a adicionar
;
; Saída:
;    H,L,A = resultado da soma de 24 bits
;
; Registradores modificados: A, F
; ==================================================
		
Add24bPlus16b_24b:	
; 1) soma LSB (A + E)
		add a, e 		; A = A + E
		ld c, a 		; salva novo LSB em C
		ld a, l 		; prepara soma no próximo byte
		adc a, d 		; soma L + D + carry
		ld l, a 		; atualiza L
		ld a, h
		adc a, 0 		; soma carry no MSB
		ld h, a
		ld a, c 		; restaura LSB final em A
		RET


		; ------------------------------------------------------------
; SOMA_BCD_PACKED8_FIXED
; Soma dois números BCD "packed" de 4 bytes (8 dígitos).
; Entrada:
;   HL = &_scoreBCD_8Digits   ; 4 bytes (MSB em [HL], LSB em [HL+3])
;   DE = &_somarBCD_8Digits   ; 4 bytes (MSB em [DE], LSB em [DE+3])
; Saída:
;   _scoreBCD_8Digits = _scoreBCD_8Digits + _somarBCD_8Digits (BCD válido)
; Regs afetados: A, B, C, HL, DE, F
; ------------------------------------------------------------
SUM_BCD_8D:	
; posiciona HL e DE no byte de UNIDADES (offset +3)
		inc hl
		inc hl
		inc hl 			; HL = &_score + 3
		inc de
		inc de
		inc de 			; DE = &_somar + 3
		
		xor a 			; zera A e CARRY (C=0)
		ld b, 4 		; 4 bytes (8 dígitos), soma da direita p/ esquerda
		
.sum_loop:	
		ld c, (hl) 		; C = byte BCD do score
		ld a, (de) 		; A = byte BCD do incremento
		adc a, c 		; A = incremento + score + carry
		daa 			; ajusta p/ BCD
		ld (hl), a 		; grava de volta no score
		
		dec hl
		dec de
		djnz .sum_loop
		
; se Carry ficou set depois do MSB, é overflow de 8 dígitos -> ignorado
		ret