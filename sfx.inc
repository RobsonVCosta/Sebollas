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
    call UpdateHorn
    call UpdateFuelAlert
    jp UpdateMusic
SoundStart:
    ld hl,424
    ld bc,0010h
    jp PlayEffect
SoundHorn:
    ; Do not restart an in-progress "bi, biiii" when space is held down.
    ld a,(_hornPhase)
    or a
    ret nz
    ld a,1
    ld (_hornPhase),a
    ld a,6
    ld (_hornClock),a
    ld c,6
    jp HornTones
HornTones:
    ; Short/long lengths share the two beating tones of the same horn.
    push bc
    ld b,0
    ld hl,180
    call PlayEffect
    pop bc
    ld b,1
    ld hl,142
    jp PlayEffect
UpdateHorn:
    ld a,(_hornPhase)
    or a
    ret z
    ld hl,_hornClock
    dec (hl)
    ret nz
    ld a,(_hornPhase)
    cp 1
    jr z,.gap
    cp 2
    jr z,.long
    xor a
    ld (_hornPhase),a
    ret
.gap:
    ld a,2
    ld (_hornPhase),a
    ld a,4
    ld (_hornClock),a
    ret
.long:
    ld a,3
    ld (_hornPhase),a
    ld a,24
    ld (_hornClock),a
    ld c,24
    jp HornTones
SoundRefuel:
    ; Rising, separated pulses while fuel enters the tank (River Raid style).
    ld a,(_fuel)
    ld e,a
    ld d,0
    ld l,e
    ld h,d
    add hl,hl
    add hl,de
    add hl,hl
    ex de,hl
    ld hl,900
    or a
    sbc hl,de
    ld bc,0103h
    jp PlayEffect
SoundCollect:
    ld a,(_hornPhase)
    or a
    ret nz
    ld a,(_refueling)
    or a
    ret nz
    ld hl,212
    ld bc,0106h
    jp PlayEffect
SoundCow:
    ld a,(_hornPhase)
    or a
    ret nz
    ld a,(_refueling)
    or a
    ret nz
    ld hl,700
    ld bc,0112h
    jp PlayEffect
SoundCrash:
    ld hl,1800
    ld bc,0219h
    jp PlayEffect

UpdateFuelAlert:
    ld a,(_state)
    cp 1
    ret nz
    ld a,(_driveStarted)
    or a
    ret z
    ld a,(_refueling)
    or a
    jr nz,.reset
    ld a,(_fuel)
    cp 21
    jr nc,.reset
    or a
    ret z
    ld a,(_fuelAlertClock)
    or a
    jr z,.beep
    dec a
    ld (_fuelAlertClock),a
    ret
.beep:
    ; Crash effects have priority over the low-fuel warning on channel C.
    ld a,(_effectTime+2)
    or a
    ret nz
    ld a,(_fuel)
    cp 11
    ld a,25
    jr nc,.clock
    ld a,12
.clock:
    ld (_fuelAlertClock),a
    ld a,(_fuelAlertPitch)
    xor 1
    ld (_fuelAlertPitch),a
    ld hl,128
    or a
    jr z,.tone
    ld hl,96
.tone:
    ld bc,0206h
    call PlayEffect
    ld a,10
    ld e,15
    jp Psg_write
.reset:
    xor a
    ld (_fuelAlertClock),a
    ld (_fuelAlertPitch),a
    ret

SoundBonusTick:
    ld a,(_bonusSoundStep)
    xor 1
    ld (_bonusSoundStep),a
    ld hl,159
    or a
    jr z,.tone
    ld hl,127
.tone:
    ld bc,0004h
    jp PlayEffect
SoundBonusDone:
    ld hl,214
    ld bc,000Ah
    call PlayEffect
    ld hl,170
    ld bc,010Ah
    jp PlayEffect
