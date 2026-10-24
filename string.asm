; Print: IX -> {x,y,ASCII string pointer}. Coordinates are tile units.
; Characters retain the original project bitmaps, now mapped to real ASCII.
Print:
    ld l,(ix+1)
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld c,(ix+0)
    ld b,0
    add hl,bc
    ld bc,NAMTBL
    add hl,bc
    ld e,(ix+2)
    ld d,(ix+3)
.loop:
    ld a,(de)
    or a
    ret z
    push hl
    push de
    call WRTVRM
    pop de
    pop hl
    inc de
    inc hl
    jr .loop

; PutText: DE -> string, B=row, C=column. Preserves IX.
PutText:
    ld a,c
    ld (_Print),a
    ld a,b
    ld (_Print+1),a
    ld (_Print+2),de
    push ix
    ld ix,_Print
    call Print
    pop ix
    ret

BcdToString:
    ld b,4
.loop:
    ld a,(hl)
    inc hl
    ld c,a
    rrca
    rrca
    rrca
    rrca
    and 15
    add a,'0'
    ld (de),a
    inc de
    ld a,c
    and 15
    add a,'0'
    ld (de),a
    inc de
    djnz .loop
    xor a
    ld (de),a
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



