; SCREEN 5 matches the reference's native 256x212 canvas and avoids tile clashes.
ShowTitleArt:
    ld a,2
    ld (077FFh),a ; select the title bank
    ld a,5
    call CHGMOD
    call DISSCR
    ld a,(RG9SAV)
    or 080h
    ld c,9
    call WriteVDP
    ld a,(RG8SAV)
    or 2 ; hide sprites while displaying the bitmap
    ld c,8
    call WriteVDP
    xor a
    ld c,7 ; backdrop is palette entry 0, explicitly black
    call WriteVDP
    xor a
    ld c,14
    call WriteVDP
    xor a
    ld c,16
    call WriteVDP
    di
    ld hl,TitlePalette
    ld b,32
.palette:
    ld a,(hl)
    out (09Ah),a
    inc hl
    djnz .palette
    ; Decompress directly to VRAM while display/IRQ access is suspended.
    xor a
    out (099h),a
    ld a,040h
    out (099h),a
    ld hl,TitleBitmapRLE
.control:
    ld a,(hl)
    inc hl
    or a
    jr z,.done
    jp m,.repeat
    ld b,a
.literal:
    ld a,(hl)
    inc hl
    out (098h),a
    djnz .literal
    jr .control
.repeat:
    and 127
    add a,3
    ld b,a
    ld a,(hl)
    inc hl
.run:
    out (098h),a
    djnz .run
    jr .control
.done:
    ei
    jp ENASCR

; A=0 hides PLAY; nonzero shows it, without touching any of the surrounding art.
DrawTitlePlay:
    ld (_titleBlink),a
    ld hl,TitlePlayOn
    ld de,100*128+76
    ld b,8
.row:
    push bc
    push hl
    push de
    ld a,(_titleBlink)
    or a
    jr z,.off
    ld bc,20
    call LDIRVM
    jr .next
.off:
    ex de,hl
    ld bc,20
    ld a,TITLE_PLAY_BACKGROUND
    call FILVRM
.next:
    pop de
    pop hl
    ld bc,20
    add hl,bc
    push hl
    ld hl,128
    add hl,de
    ex de,hl
    pop hl
    pop bc
    djnz .row
    ret
