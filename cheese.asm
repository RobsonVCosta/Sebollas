; Transparent cheese placed at fixed locations along the road edges.
UpdateCheese:
    ld a,(_stage)
    cp 2
    ret c
    ld a,(_driveStarted)
    or a
    ret z
    ld a,(_cheese)
    or a
    jr nz,.active
    ret
.active:
    ; Collecting is independent of invulnerability and never takes a life.
    ld a,(_carX)
    ld b,a
    ld a,(_cheeseX)
    sub b
    add a,12
    cp 25
    ret nc
    ld a,(_carY)
    ld b,a
    ld a,(_cheeseY)
    sub b
    add a,12
    cp 41
    ret nc
    ld a,(_cheeseCount)
    cp 099h
    jr z,.counted
    add a,1
    daa
    ld (_cheeseCount),a
.counted:
    call SoundCollect
    jr .remove
.remove:
    xor a
    ld (_cheese),a
    ret

; Fixed world objects: only a real map scroll changes their screen Y.
; Alternate road edges every 32 rows; one sprite preserves the line budget.
ScrollRoadCheese:
    ld a,(_stage)
    cp 2
    ret c
    ld a,(_cheese)
    or a
    jr z,.spawn
    ld a,(_cheeseY)
    add a,8
    cp 184
    jr nc,.remove
    ld (_cheeseY),a
    ret
.remove:
    xor a
    ld (_cheese),a
.spawn:
    ld a,(_mapRow)
    cp 20
    ret c
    ld b,a
    and 31
    cp 8
    ret nz
    ld l,b
    ld h,0
    add hl,hl
    ld de,RoadBounds
    add hl,de
    ld a,b
    and 32
    jr z,.left
    inc hl
.left:
    ld a,(hl)
    ld (_cheeseX),a
    ld a,16
    ld (_cheeseY),a
    ld a,1
    ld (_cheese),a
    xor a
    ld (_cheesePhase),a
    ret

DrawCheese:
    ld a,(_cheese)
    or a
    ret z
    ld a,(_cheeseY)
    ld d,a
    ld a,(_cheeseX)
    ld e,a
    ld a,(_cheesePhase)
    add a,CHEESE_PATTERN/4
    jp AppendSprite

DrawCheeseHUD:
    ld a,(_stage)
    or a
    ret z
    cp 1
    jp z,DrawCaneObjective
    call GetCollectibleLabel
    ld bc,0116h
    call PutText
    ld hl,NAMTBL+32+30
DrawCheeseDigits:
    ld a,(_cheeseCount)
    ld c,a
    rrca
    rrca
    rrca
    rrca
    and 15
    add a,'0'
    push bc
    push hl
    call WRTVRM
    pop hl
    pop bc
    inc hl
    ld a,c
    and 15
    add a,'0'
    jp WRTVRM
