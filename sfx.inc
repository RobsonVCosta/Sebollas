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
    ld a,(_stage)
    cp 2
    ret c
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
    ; Reference recording: ~338 Hz body and a quieter metallic band near 3 kHz.
    push bc
    ld b,0
    ld hl,335
    call PlayEffect
    pop bc
    ld a,(_refueling)
    or a
    jr nz,.envelope
    ld b,1
    ld hl,36
    call PlayEffect
.envelope:
    xor a
    ld (_hornAge),a
    jp ShapeHorn
UpdateHorn:
    ld a,(_hornPhase)
    or a
    ret z
    ld hl,_hornClock
    dec (hl)
    jr z,.transition
    ld a,(_hornPhase)
    cp 2
    ret z
    jp ShapeHorn
.transition:
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
    ld a,32
    ld (_hornClock),a
    ld c,32
    jp HornTones

; Subtle pitch movement and a soft attack/release avoid a flat electronic beep.
; A/B are the horn; C remains available for music and priority alerts.
ShapeHorn:
    ld a,(_hornClock)
    ld (_effectTime),a
    ld a,(_hornAge)
    and 15
    add a,a
    ld e,a
    ld d,0
    ld hl,HornPitchPeriods
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    xor a
    call Psg_write
    ld e,d
    ld a,1
    call Psg_write
    ld a,(_hornClock)
    cp 4
    jr nc,.attack
    ld e,a
    ld d,0
    ld hl,HornReleaseVolumes
    add hl,de
    ld e,(hl)
    jr .volume
.attack:
    ld a,(_hornAge)
    ld e,10
    or a
    jr z,.volume
    ld e,12
    cp 1
    jr z,.volume
    ld e,13
.volume:
    ld a,8
    call Psg_write
    ld c,e
    ld a,(_refueling)
    or a
    jr nz,.age ; channel B belongs to the refueling pulses while at a station
    ld a,(_hornClock)
    ld (_effectTime+1),a
    ld a,2
    ld e,36
    call Psg_write
    ld a,3
    ld e,0
    call Psg_write
    ld a,c
    sub 2 ; quieter high tone, matching the recording's metallic resonance
    ld e,a
    ld a,9
    call Psg_write
.age:
    ld hl,_hornAge
    inc (hl)
    ret
HornPitchPeriods:
    dw 335,333,332,331,330,329,329,330,331,332,333,333,332,331,330,330
HornReleaseVolumes:
    db 0,7,9,11

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
    jr z,.playing
    cp 4
    jr z,.playing
    cp 12
    ret nz
.playing:
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
