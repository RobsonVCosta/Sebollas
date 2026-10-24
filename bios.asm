; -----------------------------------------
;  BIOS (endereços)
; -----------------------------------------

CHGMOD equ 005Fh ; muda modo de vídeo (A=modo)
INIGRP equ 0072h ; inicializa SCREEN 2
GICINI equ 006Bh ; inicializa o subsistema gráfico (equivale ao "GRP:")
FILVRM equ 0056h ; preenche VRAM
GTSTCK equ 00D5h ; A=0 (cursor keys) -> A = direção (0..8)
GTTRIG equ 00D8h ; A=0 (SPACE)       -> A != 0 quando pressionado
SNSMAT equ 0141h ;ler a linha da matriz do teclado e testar os bits.

WRTVRM equ 004Dh ; Escreve 1 byte na VRAM e HL é auto-incrementado. A = dado, HL = endereço de VRAM
LDIRVM equ 005Ch ;LDIRVM — copia um bloco RAM → VRAM
;Entrada: HL = origem (RAM), DE = destino (VRAM), BC = tamanho
;Efeito: copia BC bytes de (RAM[HL]) para (VRAM[DE]). (HL/DE avançam, BC zera)
;Use quando: precisa mandar vários bytes de uma vez (ex.: 4 atributos do sprite, 32 bytes do padrão 16×16, a Name Table inteira, etc.).
KEYSND equ 0F3DBh ;Keyboard beep a=0 off
; Endereços SCREEN 2
CHRTBL equ 0000h ; pattern generator (fundo)
NAMTBL equ 1800h ; Name Table (768 bytes: 32*24)
CLRTBL equ 2000h ;color table (fundo)
POSIT equ 00C6h ; H=linha (0..23), L=coluna (0..31)
CHPUT equ 00A2h ; imprime caractere em A

;(Video Display Processor)

WRTVDP equ 0047h ; escreve reg do VDP (A=valor, C=reg)
STATFL equ 0F3E7h ; espelho do S#0 mantido pela BIOS
; bit7: VBlank, bit6: 5º sprite, bit5: colisão

;Sprite --- VRAM (padrões da BIOS p/ SCREEN 2) ---
SAT equ 1B00h 	; Sprite Attribute Table (32*4 bytes)
SPTPAT equ 3800h ; Sprite Pattern Table (formas 8x8)


CALBAS equ 0156h ; chama uma instrução BASIC
RSLREG equ 0F663h ; onde a BIOS procura o número da instrução BASIC
HIMEM equ 0FC4Ah ; ponteiro de variáveis do BASIC


ERAFNK equ 00CCh ; apaga a barra  de funções
DSPFNK equ 00CFh ; mostra a barra de funções

;Timer
JIFFY equ 0xFC9E ;incrementado a cada VBlank (50 ou 60 Hz). 24 bits (3 bytes, LSB primeiro)


; --- Tabela de cores ---
TRANSPARENT equ 0
BLACK equ 1
GREEN equ 2
LIGHT_GREEN equ 3
BLUE equ 4
LIGHT_BLUE equ 5
DARK_RED equ 6
CYAN equ 7
RED equ 8
LIGHT_RED equ 9
YELLOW equ 10
LIGHT_YELLOW equ 11
DARK_GREEN equ 12
MAGENTA equ 13
GRAY equ 14
WHITE equ 15





