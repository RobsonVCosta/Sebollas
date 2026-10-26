; Pellets originate at the rear and keep the direction aimed at the player.
UpdateDonkeyShots:
    ld a,(_stage)
    cp 2
    ret nc
    ld ix,_donkeyShots
    ld iy,_cows
    ld b,3
.loop:
    push bc
    call .shot
    ld de,8
    add ix,de
    add iy,de
    pop bc
    djnz .loop
    ret
.shot:
    ld a,(ix+0)
    or a
    jr nz,.move
    ld a,(iy+0)
    or a
    ret z
    ld a,(ix+4)
    or a
    jr z,.spawn
    dec (ix+4)
    ret
.spawn:
    ld a,100
    ld (ix+4),a
    ld a,(iy+3)
    ld (ix+3),a
    or a
    ld a,(iy+1)
    jr nz,.right
    sub 8
    ret c
    jr .place
.right:
    add a,32
    ret c
    cp 248
    ret nc
.place:
    ld (ix+1),a
    ld a,(iy+2)
    add a,16
    cp 184
    ret nc
    ld (ix+2),a
    ld (ix+0),1
    ld (ix+29),0
    ld a,(_carX)
    add a,12
    sub (ix+1)
    jr nc,.xPositive
    neg
    set 0,(ix+29)
.xPositive:
    ld (ix+24),a
    ld a,(_carY)
    add a,12
    sub (ix+2)
    jr nc,.yPositive
    neg
    set 1,(ix+29)
.yPositive:
    ld (ix+25),a
    cp (ix+24)
    jr nc,.denominator
    ld a,(ix+24)
.denominator:
    or a
    jr nz,.nonzero
    inc a
.nonzero:
    ld (ix+26),a
    srl a
    ld (ix+27),a
    ld (ix+28),a
    ret
.move:
    ; Two Bresenham steps per tick: constant aim, including steep diagonals.
    call .step
    ld a,(ix+0)
    or a
    ret z
    call .step
    ld a,(ix+0)
    or a
    ret z
    ld a,(ix+1)
    ld b,a
    ld a,(_carX)
    sub b
    add a,24
    cp 29
    ret nc
    ld a,(ix+2)
    ld b,a
    ld a,(_carY)
    sub b
    add a,28
    cp 29
    ret nc
    ld (ix+0),0
    ld a,(_invulnerable)
    or a
    ret nz
    ld a,(_state)
    cp 2
    ret z
    push ix
    push iy
    call LoseLife
    pop iy
    pop ix
    ret
.step:
    ld a,(ix+27)
    add a,(ix+24)
    jr c,.stepX
    cp (ix+26)
    jr c,.saveXError
.stepX:
    sub (ix+26)
    bit 0,(ix+29)
    jr nz,.leftStep
    inc (ix+1)
    jr .saveXError
.leftStep:
    dec (ix+1)
.saveXError:
    ld (ix+27),a
    ld a,(ix+28)
    add a,(ix+25)
    jr c,.stepY
    cp (ix+26)
    jr c,.saveYError
.stepY:
    sub (ix+26)
    bit 1,(ix+29)
    jr nz,.upStep
    inc (ix+2)
    jr .saveYError
.upStep:
    dec (ix+2)
.saveYError:
    ld (ix+28),a
    ld a,(ix+1)
    cp 248
    jr nc,.remove
    ld a,(ix+2)
    cp 16
    jr c,.remove
    cp 184
    ret c
.remove:
    ld (ix+0),0
    ret

ScrollDonkeyShots:
    ret ; aimed projectiles move in screen space, independently of the road

EraseDonkeyShots:
    ld ix,_donkeyShots+16
    ld b,3
.loop:
    push bc
    ld l,(ix+5)
    ld h,(ix+6)
    ld a,h
    or l
    jr z,.next
    ld a,(ix+7)
    push ix
    call WRTVRM
    pop ix
    ld (ix+5),0
    ld (ix+6),0
.next:
    ld de,-8
    add ix,de
    pop bc
    djnz .loop
    ret

DrawDonkeyShots:
    ld a,(_stage)
    cp 2
    ret nc
    ld a,(_state)
    cp 1
    jr z,.start
    cp 12
    ret nz
.start:
    ld ix,_donkeyShots
    ld b,3
    ld c,250
.loop:
    push bc
    ld a,(ix+0)
    or a
    jr z,.next
    ld a,(ix+2)
    cp 16
    jr c,.next
    cp 184
    jr nc,.next
    and 248
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    ld de,NAMTBL
    add hl,de
    ld a,(ix+1)
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    add hl,de
    ld (ix+5),l
    ld (ix+6),h
    push bc
    push hl
    push ix
    call RDVRM
    pop ix
    ld (ix+7),a
    pop hl
    pop bc
    ld a,c
    push ix
    call CompositeCaneTile
    pop ix
.next:
    ld de,8
    add ix,de
    pop bc
    inc c
    djnz .loop
    ret

ResetDonkeyShots:
    xor a
    ld hl,_donkeyShots
    ld de,_donkeyShots+1
    ld (hl),a
    ld bc,47
    ldir
    ret
