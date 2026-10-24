
;-----------------------------------------
		
InitSound:	
; === Mixer: habilita  tom dos canais A, B, C (sem ruído) ===
; Bit = 0 habilita; 1 desabilita.
; R7 bits: 0/1/2 = tom A/B/C; 3/4/5 = ruído A/B/C
; 0b00111000 -> tom A, B e C ligados (bit0=0).
		ld a, 7 		; R7
		ld e, %00111000
		call Psg_write

		;Clear all _noteWaitList
		ld hl, _noteWaitList      ; destino
		ld de, _noteWaitList+1    ; destino seguinte
		ld (hl), 0             ; zera o primeiro byte
		ld bc, 17              ; quantidade de bytes restantes
		ldir                   ; copia 0 de HL para os 15 próximos endereços
		ret
		
		
; ============================
;Entrada:
; A = Channel Register 8, 9, 10 (R8, R9, R10 => A, B, C)
FinishNote:	
; === Silencia canal ===
		ld e, 0 		; volume 0
		call Psg_write
		ret



; ================================================
; Tabela de notas musicais para PSG AY-3-8910 (MSX)
; Cada entrada: db low, high
; Notas de C1 (32 Hz) até C8 (4186 Hz)
; ================================================

;-----------------------------------------
; Rotina de escrita no PSG
;  ENTRA: A = número do registrador (0..15)
;         E = valor a escrever
;-----------------------------------------
Psg_write:	
		push af
		push de
		push bc
		ld c, 0xA0
		out (c), a 		; seleciona registrador
		ld a, e
		inc c 			; C = 0xA1
		out (c), a 		; escreve valor
		pop bc
		pop de
		pop af
		ret

        
; ============================
; PlayNote
; Entrada:
;   A = índice da nota (EQU, ex: A4, D7...)
;   B = canal (0=A, 1=B, 2=C)
;   C = Tempo de execução   (T4, T2, T1, T1_2, T1_4, T1_8, T1_16)
; Usa:
;   HL, DE
; ============================
PlayNote:	
		push bc ;preserva o B =canal e C =tempo de execação
		
		; Verifica se a é (silêncio) REST equ 0xFE	
		cp REST         
		jr z, .isSilence

; --- Calcula endereço na tabela ---
		ld hl, NoteTable
		ld e, a
		ld d, 0
		add hl, de 		; HL = NoteTable + índice
		
; --- Calcula registradores PSG ---
		ld a, b
		add a, a 		; a = canal * 2 (R low)
		ld d, a 		; D = reg base

; --- Low byte ---
		ld a, (hl)
		ld e, a
		ld a, d 		; Rlow = canal*2
		call Psg_write
		
; --- High byte ---
		inc hl
		ld a, (hl)
		ld e, a
		ld a, d
		inc a 			; Rhigh = canal*2+1		
		call Psg_write

		; === Volume do canal  (0..15) ===		
		ld e, 14 		;  valor do volume (0-15)
		; Habilitar envelope no Canal A		
		;ld e, 0x10     ; bit 4 = 1 → usa envelope
	

		jp .notSilence
.isSilence		
		ld e, 0
.notSilence
		ld a, 8
		add a, b 		; R8, R9 ou R10
		call Psg_write
	
		; Já está tocoando vamos agendar o finishNote
		pop bc  ;fizemos pop para pegar o C =tempo de execação
		push bc ;Protege novamente pois iremos precisar do B = canal
		call CalcTime_finish ;hl, a é o time_finish	
		pop bc ;B =canal
		;AddToNoteWaitList----------------------
		;Será usado apenas para tocar musica
		;hl = time_finish
		;b = Channel
		call AddToNoteWaitList
		ret


; CalcTime_finish-----------------	
; Entrada: 	C =tempo de execução
; Saída: hl, a 
CalcTime_finish:		
		;lendo time_ini
		call GetJIFFY 	;hl time_ini
        
		push hl ;preserva tempo_ini
		;Calculando time_finish
		;time_finish = time_ini + Andamento*Tempo de execução
		;Multiplicando  Andamento*Tempo de execução
		ld a, c
		ld hl, _music_time
		ld b, (hl)
		call Mult8bx8b_16b ;resultado em hl
		;soma time_ini to hl (Andamento*Tempo de execução)
		push hl ; coloca resultado de Mult8bx8b_16b em de
		pop de		
		pop hl	;tempo_ini
      	add hl, de ;hl é o time_finish
		ret

;AddToNoteWaitList----------------------
;Será usado apenas para tocar musica
;hl = time_finish
;b = Channel
AddToNoteWaitList:	
		ld c, b
		ld b, 6 		; repete 6 vezes
		push hl
        ;multiplica c po b
		ld a, 0
.loopB	
		add a, c
		djnz .loopB 	; decrementa B e volta se ainda não chegou a 0
		ld c, a  ;c = 6xChannel
		
		ld e, c
		ld d, 0
		ld hl, _noteWaitList
		add hl, de ;hl é o address onde guardará o time_finish
		push hl
		pop ix 	;agora ix = _NoteWaitList + shift do canal		
		pop hl  ;hl = time_finish
		ld (ix), l
		ld (ix + 1), h		
		
		ret

; Entrada:
;   DE e HL carregados
; Saída:
;   Z → DE = HL
;   C → DE < HL
;   NC → DE >= HL

CompareDEHL:	
    ld a,d        ; compara MSB primeiro
    cp h
    jr nz,.diff   ; se forem diferentes, decide aqui
    ld a,e        ; senão, compara LSB
    cp l
.diff   
    ret

;
; Read _noteWaitList and compare to time_current
; if time_current > time_finish stop channel sound
; and fill 0000 at _noteWaitList channel
; and call nextNote
UpdateSound:	
	ld b, 3 
	ld c, 0 ;c = Channel
.loopBUpdateSound	;para cada canal
	push bc	
	call GetChannelAddress ;Agora hl = point of channel at _noteWaitList
	
	ld a, (hl)       ; pega byte baixo
    inc hl
    or (hl)          ; OR com byte alto   
	dec hl
    jr z, .next     ; se (HL) = 0000h, vai para .next
    				; caso contrário, continua aqui

	ld de, (hl) 	;de = time_finish
	
	call GetJIFFY 	;hl = time_current
	; if time_finish >= time_current
	call CompareDEHL	 
	jr nc, .next   	
	call TimeToFinish	
.next  
	pop bc
	inc c	
	djnz .loopBUpdateSound 
	ret


TimeToFinish:	
	push bc
	ld a, 8 
	add c
	call FinishNote	; A = Channel Register 8, 9, 10 (R8, R9, R10 => A, B, C)	
	
	
	;zera _noteWaitList para esse canal
	ld hl, 0x0000 	
	ld b, c ;b = Channel
	call AddToNoteWaitList 
	pop bc	
	call NextNote ; Verifica a existência de nova nota para tocar.
	ret

; NextNote------------------------
; Entrada:
; c = channel
; Verifica a existência de nova nota para tocar.
NextNote:

	call GetChannelAddress ;Agora hl = point of channel at _noteWaitList
	inc hl ;acessa o terceiro byte (music data address)
	inc hl
	ld a, (hl)       ; pega byte baixo
    inc hl
    or (hl)          ; OR com byte alto 
	dec hl  
    jr z, .done       ; se (HL) = 0000h, vai para .done	
	ld de, (hl)
	push de
	pop hl	
	
	ld   b, c 
    call NextNoteChannel
.done							
	ret 

;Entrada: 
;		c = Channel
;Saída:
; 	hl = point of channel at _noteWaitList
GetChannelAddress:
	ld hl, _noteWaitList   ; carrega endereço	
	ld e, c		 ; Multiplica E por 6. Resultado em E
	sla e        ; E = B × 2
    ld  d, e     ; guarda resultado ×2 em D
    sla e        ; E = B × 4
	ld a, e
    add d     ; A = (B×4) + (B×2) = B×6
    ld d, 0     ; DE = B x 6
	ld e, a
	add hl, de
	ret

;Entrada: 
;		b = Channel
;		de = musica data address to play
SetMusicData:
	push bc
	push de
	ld c, b
	call GetChannelAddress ;Agora hl = point of channel at _noteWaitList
	
	inc hl ;acessa o terceiro byte (callback address)
	inc hl	
	pop de
    ld (hl), e      ; byte baixo
    inc hl
    ld (hl), d      ; byte alto -> DE = endereço real da função
	pop bc
	ret

;Entrada : B = channel 
NextNoteChannel:
	ld ix, _noteWaitList
	push bc
	call MultiplayBx6	
	add ix, bc
	pop bc
	ld l, (ix+2)
	ld h, (ix+3) ;hl = music address
	;shift hl 
	ld e, (ix+4)
	ld d, (ix+5) ;de = shift note
	push de
	;shift hl 
	; SLA DE (16 bits) Mulplica shift note x2
	SLA e   ; desloca o byte menos significativo
	RL d    ; propaga o carry para o byte mais significativo
	add hl, de
	;incrementa o shtif note
	pop de
	inc de
	ld (ix+4), e
	ld (ix+5), d
	ld a, (hl) ; a = music note	
	cp FINISH 
    jr z, .finish	
	cp NEXT_MUSIC 
    jr z, .nextMusic	
	cp LOOP
	jr z, .loop	
	inc hl
	ld c, (hl) ; c =  Tempo de execução 
	call PlayNote	
	jr   .done    
.finish
	ld de, 0x00
	call SetMusicData ;stop propagation note
	call ResetShiftNote	
	jr  .done 
.nextMusic	
	ld de, 0x00
	push hl
	call SetMusicData ;stop propagation note
	call ResetShiftNote
	pop hl
	call NextMusic
	jr  .done
.loop:
	call ResetShiftNote	
	call StartMusic
.done  
	ret

;Chamado toda vez que uma música termina. Permite chamar refrão ou emendar em outra música
;Entrada : B = channel 
NextMusic:
		inc hl
		ld e, (hl) ; de =  NextMusic
		inc hl
		ld d, (hl)		
		call SetMusicData		
		call StartMusic	
		ret


;Entrada : B = channel 
StartMusic:
	call NextNoteChannel
	ret

;Entrada : B = channel 
;		   IX = _noteWaitList Shifted
ResetShiftNote:		
	;zera contador shift note
	ld de, 0x00
	ld (ix+4), e
	ld (ix+5), d
	ret

;Entrada: B = number
;Retorna: BC = B = 0, C = B x 6 
MultiplayBx6:	
	ld a, b      ; A = B
    rlca         ; A = B * 2
    ld l, a      ; guarda em L
    rlca         ; A = B * 4
    add a, l     ; A = B*4 + B*2 = B*6
	ld c, a
	ld b, 0	
	ret

;Entrada : B = channel 
VerifyIsBusyChannel:
    ld   ix, _noteWaitList   ; carrega endereço base
	call MultiplayBx6	
	add ix, bc
    ld   a, (ix)             ; pega byte 0
    or   (ix+1)              ; combina com byte 1
    or   (ix+2)              ; combina com byte 2
    or   (ix+3)              ; combina com byte 3
    ret                    ; Z=1 se todos forem zero



; ---------------------------------------------------
; Subrotina: SetNoisePeriod
; Parâmetro: A contém o valor desejado para o R6 (0..31)
; Efeito: configura o registrador 6 do AY-3-8910 com esse valor
; ---------------------------------------------------
SetNoisePeriod:
    ; Supondo porta 0xA0 = seletor de registrador
    ; e porta 0xA1 = escrita de dado
    ; (esse é esquema típico em MSX)  

    push af           ; salva A (se você quiser que A permaneça)  
    ld   a, 6         ; registrador 6 = Noise Period  
    out  (0xA0), a    ; seleciona registrador 6  

    pop  af           ; recupera valor desejado para A  
    out  (0xA1), a    ; escreve valor em R6  

    ret  


; MSX / AY-3-8910 (PSG)
; Portas típicas: 0xA0 (seleciona registrador), 0xA1 (dado)
;Entrada : DE = 12bits TEmPO de ENVElope [0-8190]
;			C = Tipo do envelope [0-15]	
; HOW TO USE
; Set o volume do canal para ;ld e, 0x10     ; bit 4 = 1 → usa envelope
; 
;ld de, 190
;ld c, %00001001 ;FADE_OUT
;ld c, %00001101 ;FADE_IN
;ld c, %00001110 ;WAVE 	
;ld c, %00001110 ;DENTE DE SERRA
;ld c, %00001111 ;ONE DENTE DE SERRA
;call SetEnvelope


SetEnvelope:
    ; R11 = fine (low 8 bits)
    ld   a, 11
    out  (0xA0), a
    ld   a, e          ; low 8 do período
    out  (0xA1), a

    ; R12 = coarse (high 4 bits)
    ld   a, 12
    out  (0xA0), a
    ld   a, d
    and  0x0F          ; só os 4 bits baixos contam
    out  (0xA1), a

    ; R13 = shape (baixa 4 bits)
    ld   a, 13
    out  (0xA0), a
    ld   a, c
    and  0x0F
    out  (0xA1), a
    ret

; ================================================
; Tabela de notas musicais para PSG AY-3-8910 (MSX)
; Cada entrada: db low,high  ; period 12 bits = (high << 8) | low
; Clock usado: 1.7897725 MHz (AY clock typical on MSX)
; Formula: period = clock / (16 * frequency)
; Notas de C1 (≈32.70 Hz) até B8 (≈7902.13 Hz)
; ================================================

NoteTable:
; --- Oitava 1 ---
	db 0x5C,0x0D	; C1 (32.703 Hz) -> period = 3420 (= 0xD5C)
	db 0x9B,0x0C	; C#1 (34.648 Hz) -> period = 3229 (= 0xC9D)
	db 0xE6,0x0B	; D1 (36.708 Hz) -> period = 3047 (= 0xBE7)
	db 0x3B,0x0B	; D#1 (38.891 Hz) -> period = 2876 (= 0xB3C)
	db 0x9A,0x0A	; E1 (41.203 Hz) -> period = 2715 (= 0xA9B)
	db 0x02,0x0A	; F1 (43.654 Hz) -> period = 2562 (= 0xA02)
	db 0x72,0x09	; F#1 (46.249 Hz) -> period = 2419 (= 0x973)
	db 0xEA,0x08	; G1 (48.999 Hz) -> period = 2283 (= 0x8EB)
	db 0x6A,0x08	; G#1 (51.913 Hz) -> period = 2155 (= 0x86B)
	db 0xF1,0x07	; A1 (55.000 Hz) -> period = 2034 (= 0x7F2)
	db 0x7F,0x07	; A#1 (58.270 Hz) -> period = 1920 (= 0x780)
	db 0x13,0x07	; B1 (61.735 Hz) -> period = 1812 (= 0x714)

; --- Oitava 2 ---
	db 0xAD,0x06	; C2 (65.406 Hz) -> period = 1710 (= 0x6AE)
	db 0x4D,0x06	; C#2 (69.296 Hz) -> period = 1614 (= 0x64E)
	db 0xF3,0x05	; D2 (73.416 Hz) -> period = 1678 (= 0x68E)
	db 0x9D,0x05	; D#2 (77.782 Hz) -> period = 1666 (= 0x682)
	db 0x4D,0x05	; E2 (82.407 Hz) -> period = 1654 (= 0x676)
	db 0x01,0x05	; F2 (87.307 Hz) -> period = 1642 (= 0x66A)
	db 0xB9,0x04	; F#2 (92.499 Hz) -> period = 1632 (= 0x660)
	db 0x75,0x04	; G2 (97.999 Hz) -> period = 1622 (= 0x656)
	db 0x34,0x04	; G#2 (103.826 Hz) -> period = 1613 (= 0x65D)
	db 0xF8,0x03	; A2 (110.000 Hz) -> period = 1605 (= 0x645)
	db 0xBF,0x03	; A#2 (116.541 Hz) -> period = 1598 (= 0x63E)
	db 0x89,0x03	; B2 (123.471 Hz) -> period = 1591 (= 0x637)

; --- Oitava 3 ---
	db 0x57,0x03	; C3 (130.813 Hz) -> period = 598 (= 0x256)
	db 0x27,0x03	; C#3 (138.591 Hz) -> period = 584 (= 0x248)
	db 0xF9,0x02	; D3 (146.832 Hz) -> period = 573 (= 0x23D)
	db 0xCE,0x02	; D#3 (155.563 Hz) -> period = 562 (= 0x232)
	db 0xA6,0x02	; E3 (164.814 Hz) -> period = 551 (= 0x227)
	db 0x80,0x02	; F3 (174.614 Hz) -> period = 541 (= 0x21D)
	db 0x5C,0x02	; F#3 (184.997 Hz) -> period = 533 (= 0x215)
	db 0x3A,0x02	; G3 (195.998 Hz) -> period = 525 (= 0x20D)
	db 0x19,0x02	; G#3 (207.652 Hz) -> period = 520 (= 0x208)
	db 0xFC,0x01	; A3 (220.000 Hz) -> period = 514 (= 0x202)
	db 0xDF,0x01	; A#3 (233.082 Hz) -> period = 507 (= 0x1FB)
	db 0xC4,0x01	; B3 (246.942 Hz) -> period = 501 (= 0x1F5)

; --- Oitava 4 ---
	db 0xAB,0x01	; C4 (261.626 Hz) -> period = 420 (= 0x1A4)
	db 0x93,0x01	; C#4 (277.183 Hz) -> period = 404 (= 0x194)
	db 0x7C,0x01	; D4 (293.665 Hz) -> period = 389 (= 0x185)
	db 0x67,0x01	; D#4 (311.127 Hz) -> period = 374 (= 0x176)
	db 0x53,0x01	; E4 (329.628 Hz) -> period = 364 (= 0x16C)
	db 0x40,0x01	; F4 (349.228 Hz) -> period = 352 (= 0x160)
	db 0x2E,0x01	; F#4 (369.994 Hz) -> period = 341 (= 0x155)
	db 0x1D,0x01	; G4 (391.995 Hz) -> period = 333 (= 0x14D)
	db 0x0D,0x01	; G#4 (415.305 Hz) -> period = 325 (= 0x145)
	db 0xFE,0x00	; A4 (440.000 Hz) -> period = 254 (= 0x0FE)
	db 0xEF,0x00	; A#4 (466.164 Hz) -> period = 246 (= 0x0F6)
	db 0xE2,0x00	; B4 (493.883 Hz) -> period = 239 (= 0x0EF)

; --- Oitava 5 ---
	db 0xD5,0x00	; C5 (523.251 Hz) -> period = 214 (= 0x0D6)
	db 0xC9,0x00	; C#5 (554.365 Hz) -> period = 203 (= 0x0CB)
	db 0xBE,0x00	; D5 (587.330 Hz) -> period = 193 (= 0x0C1)
	db 0xB3,0x00	; D#5 (622.254 Hz) -> period = 185 (= 0x0B9)
	db 0xA9,0x00	; E5 (659.255 Hz) -> period = 177 (= 0x0B1)
	db 0xA0,0x00	; F5 (698.456 Hz) -> period = 169 (= 0x0A9)
	db 0x97,0x00	; F#5 (739.989 Hz) -> period = 162 (= 0x0A2)
	db 0x8E,0x00	; G5 (783.991 Hz) -> period = 156 (= 0x09C)
	db 0x86,0x00	; G#5 (830.609 Hz) -> period = 150 (= 0x096)
	db 0x7F,0x00	; A5 (880.000 Hz) -> period = 146 (= 0x092)
	db 0x77,0x00	; A#5 (932.328 Hz) -> period = 142 (= 0x08E)
	db 0x71,0x00	; B5 (987.767 Hz) -> period = 139 (= 0x08B)

; --- Oitava 6 ---
	db 0x6A,0x00	; C6 (1046.502 Hz) -> period = 84 (= 0x054)
	db 0x64,0x00	; C#6 (1108.731 Hz) -> period = 80 (= 0x050)
	db 0x5F,0x00	; D6 (1174.659 Hz) -> period = 76 (= 0x04C)
	db 0x59,0x00	; D#6 (1244.508 Hz) -> period = 73 (= 0x049)
	db 0x54,0x00	; E6 (1318.510 Hz) -> period = 70 (= 0x046)
	db 0x50,0x00	; F6 (1396.913 Hz) -> period = 67 (= 0x043)
	db 0x4B,0x00	; F#6 (1479.978 Hz) -> period = 64 (= 0x040)
	db 0x47,0x00	; G6 (1567.982 Hz) -> period = 62 (= 0x03E)
	db 0x43,0x00	; G#6 (1661.219 Hz) -> period = 59 (= 0x03B)
	db 0x3F,0x00	; A6 (1760.000 Hz) -> period = 56 (= 0x038)
	db 0x3B,0x00	; A#6 (1864.655 Hz) -> period = 53 (= 0x035)
	db 0x38,0x00	; B6 (1975.533 Hz) -> period = 51 (= 0x033)

; --- Oitava 7 ---
	db 0x35,0x00	; C7 (2093.005 Hz) -> period = 36 (= 0x024)
	db 0x32,0x00	; C#7 (2217.461 Hz) -> period = 34 (= 0x022)
	db 0x2F,0x00	; D7 (2349.318 Hz) -> period = 33 (= 0x021)
	db 0x2C,0x00	; D#7 (2489.016 Hz) -> period = 32 (= 0x020)
	db 0x2A,0x00	; E7 (2637.020 Hz) -> period = 30 (= 0x01E)
	db 0x28,0x00	; F7 (2793.826 Hz) -> period = 28 (= 0x01C)
	db 0x25,0x00	; F#7 (2959.955 Hz) -> period = 27 (= 0x01B)
	db 0x23,0x00	; G7 (3135.964 Hz) -> period = 26 (= 0x01A)
	db 0x21,0x00	; G#7 (3322.438 Hz) -> period = 25 (= 0x019)
	db 0x1F,0x00	; A7 (3520.000 Hz) -> period = 24 (= 0x018)
	db 0x1D,0x00	; A#7 (3729.310 Hz) -> period = 23 (= 0x017)
	db 0x1C,0x00	; B7 (3951.066 Hz) -> period = 22 (= 0x016)

; --- Oitava 8 ---
	db 0x1A,0x00	; C8 (4186.009 Hz) -> period = 21 (= 0x015)
	
; ============================
; Definições de índice de notas
; Cada nota ocupa 2 bytes na NoteTable
; ============================
		
; --- Oitava 1 ---
C1   equ 00h
C1S  equ 02h
D1B  equ 02h
D1   equ 04h
D1S  equ 06h
E1B  equ 06h
E1   equ 08h
F1   equ 0Ah
F1S  equ 0Ch
G1B  equ 0Ch
G1   equ 0Eh
G1S  equ 10h
A1B  equ 10h
A1   equ 12h
A1S  equ 14h
B1B  equ 14h
B1   equ 16h

; --- Oitava 2 ---
C2   equ 18h
C2S  equ 1Ah
D2B  equ 1Ah
D2   equ 1Ch
D2S  equ 1Eh
E2B  equ 1Eh
E2   equ 20h
F2   equ 22h
F2S  equ 24h
G2B  equ 24h
G2   equ 26h
G2S  equ 28h
A2B  equ 28h
A2   equ 2Ah
A2S  equ 2Ch
B2B  equ 2Ch
B2   equ 2Eh

; --- Oitava 3 ---
C3   equ 30h
C3S  equ 32h
D3B  equ 32h
D3   equ 34h
D3S  equ 36h
E3B  equ 36h
E3   equ 38h
F3   equ 3Ah
F3S  equ 3Ch
G3B  equ 3Ch
G3   equ 3Eh
G3S  equ 40h
A3B  equ 40h
A3   equ 42h
A3S  equ 44h
B3B  equ 44h
B3   equ 46h

; --- Oitava 4 (central) ---
C4   equ 48h
C4S  equ 4Ah
D4B  equ 4Ah
D4   equ 4Ch
D4S  equ 4Eh
E4B  equ 4Eh
E4   equ 50h
F4   equ 52h
F4S  equ 54h
G4B  equ 54h
G4   equ 56h
G4S  equ 58h
A4B  equ 58h
A4   equ 5Ah
A4S  equ 5Ch
B4B  equ 5Ch
B4   equ 5Eh

; --- Oitava 5 ---
C5   equ 60h
C5S  equ 62h
D5B  equ 62h
D5   equ 64h
D5S  equ 66h
E5B  equ 66h
E5   equ 68h
F5   equ 6Ah
F5S  equ 6Ch
G5B  equ 6Ch
G5   equ 6Eh
G5S  equ 70h
A5B  equ 70h
A5   equ 72h
A5S  equ 74h
B5B  equ 74h
B5   equ 76h

; --- Oitava 6 ---
C6   equ 78h
C6S  equ 7Ah
D6B  equ 7Ah
D6   equ 7Ch
D6S  equ 7Eh
E6B  equ 7Eh
E6   equ 80h
F6   equ 82h
F6S  equ 84h
G6B  equ 84h
G6   equ 86h
G6S  equ 88h
A6B  equ 88h
A6   equ 8Ah
A6S  equ 8Ch
B6B  equ 8Ch
B6   equ 8Eh

; --- Oitava 7 ---
C7   equ 90h
C7S  equ 92h
D7B  equ 92h
D7   equ 94h
D7S  equ 96h
E7B  equ 96h
E7   equ 98h
F7   equ 9Ah
F7S  equ 9Ch
G7B  equ 9Ch
G7   equ 9Eh
G7S  equ 0A0h
A7B  equ 0A0h
A7   equ 0A2h
A7S  equ 0A4h
B7B  equ 0A4h
B7   equ 0A6h

; --- Oitava 8 ---
C8   equ 0A8h

NEXT_MUSIC equ 0xFC
LOOP equ 0xFD
REST equ 0xFE
FINISH equ 0xFF


; --- Times ---
T4     equ 20h    ; 32 decimal
T2     equ 10h    ; 16 decimal
T1     equ 08h    ; 8 decimal
T1_2   equ 04h    ; 4 decimal
T1_4   equ 02h    ; 2 decimal
T1_8   equ 01h    ; 1 decimal
T1_16  equ 00h    ; 0 decimal

;--- Andamento ---
;Fator em decisegundos (10 ds = 100 milliseconds)
LARGO EQU 6
ADAGIO EQU 5
ANDANTE EQU 4
MODERATO EQU 3
ALLEGRO EQU 2
PRESTO EQU 1
PRESTISSIMO EQU 0

CHANNEL_A equ 0
CHANNEL_B equ 1
CHANNEL_C equ 2

		
;--Musics

;fire, bird, tiro no escudo
_fire1:
	db A7, T1_16
	db F7, T1_16
	db A7, T1_4
	db FINISH

_derrapagem1:	
	db C6, T1_16
	db F5, T1_16
	db A5, T1_16
	db F5, T1_16
	db A5, T1_16
	db F5, T1_8	
	db A5, T1_16
	db FINISH


_music2:
	db C3, T1_2	
	db D3, T1_2
	db E3, T1_2
	db F3, T1
	db REST, T1_8
	db F3, T1_2
	db REST, T1_8
	db F3, T1_2
	db REST, T1_8
	db C3, T1_2	
	db D3, T1_2
	db C3, T1_2	
	db D3, T1_2
	db REST, T1_8
	db D3, T1_2
	db REST, T1_8
	db D3, T1_2
	db REST, T1_8
	db C3, T1_2	
	db G3, T1_2	
	db F3, T1_2
	db E3, T1_2
	db REST, T1_8
	db E3, T1_2
	db REST, T1_8
	db E3, T1_2
	db REST, T1_8
	db C3, T1_2	
	db D3, T1_2
	db E3, T1_2
	db F3, T1
	db REST, T1_8
	db F3, T1_2
	db F3, T1
	db REST, T1
	;db LOOP
	db NEXT_MUSIC 
	dw _derrapagem1
	
        
		; ===========================
; Missão Impossível (arranjo simplificado)
; 3 canais: A = melodia, B = baixo, C = acompanhamento
; ===========================


; Volumes por canal (opcional: você pode escrever direto nos registradores R8..R10)
; Ex.: para dar mais destaque ao canal A, podemos usar 14 (já usado no PlayNote).
; Se quiser reduzir, escreva com Psg_write antes de StartMusic.

; ---------------------------
; Melodia principal (Canal A)
; ---------------------------
_missao_melodia:
    ; Motivo: short-short-short - long (versão adaptada do tema 5/4)
    db E5,   T1_8
    db E5,   T1_8
    db E5,   T1_8
    db C5,   T1_4
    db E5,   T1_4
    db G5,   T1
    db REST, T1_8

    ; Repetição / variação
    db E5,   T1_8
    db E5,   T1_8
    db E5,   T1_8
    db C5,   T1_4
    db E5,   T1_4
    db B4,   T1
    db REST, T1_8

    ; Ponte
    db A5,   T1_4
    db G5,   T1_4
    db F5,   T1_2
    db REST, T1_8

    ; Final da frase - repete ou finaliza
    db E5,   T1_8
    db E5,   T1_8
    db E5,   T1_8
    db C5,   T1_4
    db E5,   T1_4
    db G5,   T1
    db FINISH

; ---------------------------
; Baixo rítmico (Canal B)
; ---------------------------
_missao_baixo:
    ; Simples ostinato para marcar o ritmo 5/4 (notas graves)
    db C3,   T1_2
    db REST, T1_8
    db C3,   T1_2
    db REST, T1_8
    db G2,   T1_2
    db REST, T1_8
    db C3,   T1_2
    db FINISH

; ---------------------------
; Acompanhamento (Canal C)
; ---------------------------
_missao_acomp:
    ; Acordes leves/contraponto com tempo mais longo
    db G4,   T1
    db REST, T1_8
    db G4,   T1_2
    db REST, T1_8
    db E4,   T1
    db REST, T1_8
    db F4,   T1_2
    db FINISH

; ---------------------------
; Rotina exemplo para iniciar a música nas 3 vozes
; (coloque isso onde você normalmente inicia músicas)
; ---------------------------
StartMissionImpossible:
    ; Canal A (melodia)
    ld b, CHANNEL_A
    ld de, _missao_melodia
    call SetMusicData
    ld b, CHANNEL_A
    call StartMusic

    ; Canal B (baixo)
    ld b, CHANNEL_B
    ld de, _missao_baixo
    call SetMusicData
    ld b, CHANNEL_B
    call StartMusic

    ; Canal C (acompanhamento)
    ld b, CHANNEL_C
    ld de, _missao_acomp
    call SetMusicData
    ld b, CHANNEL_C
    call StartMusic

    ret


