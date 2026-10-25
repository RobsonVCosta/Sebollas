; One transparent 16x16 sprite rolls toward the car, with two rotation frames.
; Replaces the visible sound waves, keeping the scanline limit at eight.
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
    ld a,(_cheeseClock)
    or a
    jr z,.spawn
    dec a
    ld (_cheeseClock),a
    ret
.spawn:
    ld a,(_mapRow)
    cp 20
    ret c
    add a,2
    call RoadCenter
    ld (_cheeseX),a
    ld a,32
    ld (_cheeseY),a
    ld a,1
    ld (_cheese),a
    xor a
    ld (_cheesePhase),a
    ret
.active:
    ; Collecting is independent of invulnerability and never takes a life.
    ld a,(_carX)
    ld b,a
    ld a,(_cheeseX)
    sub b
    add a,12
    cp 25
    jr nc,.roll
    ld a,(_carY)
    ld b,a
    ld a,(_cheeseY)
    sub b
    add a,12
    cp 41
    jr nc,.roll
    ld a,(_cheeseCount)
    cp 099h
    jr z,.counted
    add a,1
    daa
    ld (_cheeseCount),a
.counted:
    call SoundCollect
    jr .remove
.roll:
    ld a,(_tick)
    and 3
    ret nz
    ld a,(_cheeseY)
    add a,8
    cp 184
    jr nc,.remove
    ld (_cheeseY),a
    ; Follow the road's bends as the wheel rolls toward the player.
    sub 16
    srl a
    srl a
    srl a
    ld b,a
    ld a,(_mapRow)
    add a,b
    call RoadCenter
    ld (_cheeseX),a
    ld a,(_cheesePhase)
    xor 1
    ld (_cheesePhase),a
    ret
.remove:
    xor a
    ld (_cheese),a
    ld a,48
    ld (_cheeseClock),a
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
