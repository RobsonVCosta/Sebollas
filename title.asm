; SCREEN 5 matches the reference's native 256x212 canvas and avoids tile clashes.
ShowTitleArt:
    ld a,4
    ld (07000h),a ; select the two 8 KiB title banks
    inc a
    ld (07800h),a
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
    call ENASCR
    jp DrawTitleMenu

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

; Keep both actions readable; only the selected action has a cursor and blinks.
DrawTitleMenu:
    ld a,1
    call DrawTitlePlay
    ld a,(_continueAvailable)
    or a
    ret z
    call DrawTitleContinue
    ld de,112*128+76
    ld a,(_titleSelection)
    or a
    jr z,ClearTitleCursor
    ld de,100*128+76
ClearTitleCursor:
    ld b,8
.row:
    push bc
    push de
    ex de,hl
    ld bc,3
    ld a,TITLE_PLAY_BACKGROUND
    call FILVRM
    pop hl
    ld de,128
    add hl,de
    ex de,hl
    pop bc
    djnz .row
    ret

DrawTitleContinue:
    ld (_titleBlink),a
    ld hl,TitleContinueOn
    ld de,112*128+76
    ld b,8
.row:
    push bc
    push hl
    push de
    ld a,(_titleBlink)
    or a
    jr z,.off
    ld bc,36
    call LDIRVM
    jr .next
.off:
    ex de,hl
    ld bc,36
    ld a,TITLE_PLAY_BACKGROUND
    call FILVRM
.next:
    pop de
    pop hl
    ld bc,36
    add hl,bc
    push hl
    ld hl,128
    add hl,de
    ex de,hl
    pop hl
    pop bc
    djnz .row
    ret

; Direction presses select a row once, until the stick/arrows are released.
UpdateTitleSelection:
    ld a,(_continueAvailable)
    or a
    ret z
    xor a
    call GTSTCK
    or a
    jr nz,.direction
    ld (_menuMoveHeld),a
    ret
.direction:
    ld b,a
    ld a,(_menuMoveHeld)
    or a
    ret nz
    ld a,b
    cp 4
    jr c,.upOrSide
    cp 7
    jr c,.down
    cp 7
    ret z
.up:
    xor a
    jr .select
.upOrSide:
    cp 3
    ret z
    jr .up
.down:
    ld a,1
.select:
    ld (_titleSelection),a
    ld a,1
    ld (_menuMoveHeld),a
    jp DrawTitleMenu
