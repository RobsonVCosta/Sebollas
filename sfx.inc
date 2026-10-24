; Short PSG effects. The original PSG ports and three-channel design are retained.
; B=channel (0..2), HL=tone period, C=duration in 50Hz ticks.
Psg_write:
    out (0A0h),a
    ld a,e
    out (0A1h),a
    ret
InitSound:
    ld a,7
    ld e,0B8h ; tones enabled, noise disabled; preserve keyboard I/O direction
    call Psg_write
    ld b,3
    ld a,8
.loop:
    push af
    push bc
    ld e,0
    call Psg_write
    pop bc
    pop af
    inc a
    djnz .loop
    ret
PlayEffect:
    push bc
    ld a,b
    add a,a
    push af
    ld e,l
    call Psg_write
    pop af
    inc a
    ld e,h
    call Psg_write
    pop bc
    push bc
    ld a,b
    add a,8
    ld e,12
    call Psg_write
    pop bc
    ld e,b
    ld d,0
    ld hl,_effectTime
    add hl,de
    ld (hl),c
    ret
UpdateSound:
    ld hl,_effectTime
    ld b,3
    ld c,8
.loop:
    ld a,(hl)
    or a
    jr z,.next
    dec (hl)
    jr nz,.next
    push bc
    push hl
    ld a,c
    ld e,0
    call Psg_write
    pop hl
    pop bc
.next:
    inc hl
    inc c
    djnz .loop
    ret
SoundStart:
    ld hl,424
    ld bc,0010h
    jp PlayEffect
SoundShot:
    ld hl,110
    ld bc,0004h
    jp PlayEffect
SoundCow:
    ld hl,700
    ld bc,0112h
    jp PlayEffect
SoundCrash:
    ld hl,1800
    ld bc,0219h
    jp PlayEffect
