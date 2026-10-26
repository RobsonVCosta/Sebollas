; Two-voice PSG reduction of the user-supplied Sultans of Swing excerpt.
; C carries the melody. A supplies backing only while no foreground effect owns it.
UpdateMusic:
    ld a,(_state)
    cp 8
    jr z,.active
    cp 9
    jr z,.active
    cp 11
    jr z,.active
    cp 12
    jr z,.active
    cp 1
    jr z,.active
    cp 4
    jp c,StopMusic
    cp 7
    jp nc,StopMusic
.active:
    ld a,(_effectTime+2)
    or a
    ret nz ; crash and low-fuel warning own channel C
    ld b,0
    ld a,(_state)
    cp 4
    jr z,.battleMode
    cp 12
    jr nz,.mode
.battleMode:
    inc b
.mode:
    ld a,(_musicMode)
    cp b
    jr z,.sameMode
    ld a,b
    ld (_musicMode),a
    xor a
    ld (_musicStep),a
    ld (_musicClock),a
    ld (_musicBackingPeriod),a
    ld (_musicBackingPeriod+1),a
.sameMode:
    ld a,(_state)
    cp 4
    jr z,.musicClock
    ld a,(_hornPhase)
    or a
    jp nz,.duck
    ld a,(_refueling)
    or a
    jp nz,.duck
.musicClock:
    ld a,(_musicClock)
    or a
    jr z,.nextNote
    dec a
    ld (_musicClock),a
    jr nz,.play
.nextNote:
    ld a,(_musicStep)
    ld e,a
    ld d,0
    ld l,e
    ld h,d
    ld a,(_musicMode)
    or a
    jr nz,.battleNote
    ; Normal events: melody period, backing period, duration (five bytes).
    add hl,hl
    add hl,hl
    add hl,de
    ld de,MusicNotes
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld (_musicPeriod),de
    inc hl
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld (_musicBackingPeriod),de
    inc hl
    ld a,(hl)
    ld (_musicClock),a
    ld a,(_musicStep)
    inc a
    cp MUSIC_NOTE_COUNT
    jr c,.saveStep
    xor a
    jr .saveStep
.battleNote:
    add hl,hl
    add hl,de
    ld de,BattleMusicNotes
    add hl,de
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld (_musicPeriod),de
    inc hl
    ld a,(hl)
    ld (_musicClock),a
    ld a,(_musicStep)
    inc a
    and 31
.saveStep:
    ld (_musicStep),a
.play:
    ld hl,(_musicPeriod)
    ld a,h
    or l
    jr z,.duck
    ld a,4
    ld e,l
    call Psg_write
    ld a,5
    ld e,h
    call Psg_write
    ld a,(_musicMode)
    or a
    jr z,.volume
    ld a,(_musicClock)
    cp 3
    jr c,.duck ; battle theme keeps its original articulated arpeggios
.volume:
    ld a,10
    ld e,9
    call Psg_write
    jp UpdateMusicBacking
.duck:
    ld a,10
    ld e,0
    call Psg_write
    jp UpdateMusicBacking

UpdateMusicBacking:
    ld a,(_hornPhase)
    or a
    ret nz
    ld a,(_effectTime)
    or a
    ret nz ; never replace the horn, bonus or typewriter on A
    ld a,(_musicMode)
    or a
    jr nz,.mute
    ld a,(_refueling)
    or a
    jr nz,.mute
    ld hl,(_musicBackingPeriod)
    ld a,h
    or l
    jr z,.mute
    xor a
    ld e,l
    call Psg_write
    ld a,1
    ld e,h
    call Psg_write
    ld a,8
    ld e,6
    jp Psg_write
.mute:
    ld a,8
    ld e,0
    jp Psg_write

StopMusic:
    xor a
    ld (_musicStep),a
    ld (_musicClock),a
    ld (_musicPeriod),a
    ld (_musicPeriod+1),a
    ld (_musicBackingPeriod),a
    ld (_musicBackingPeriod+1),a
    ld (_musicMode),a
    ld a,(_hornPhase)
    or a
    jr nz,.lead
    ld a,(_effectTime)
    or a
    jr nz,.lead
    ld a,8
    ld e,0
    call Psg_write
.lead:
    ld a,(_effectTime+2)
    or a
    ret nz
    ld a,10
    ld e,0
    jp Psg_write

    include "resources/generated/sultans.inc"

; Fast C-minor arpeggios replace the road melody during enemy encounters.
BattleMusicNotes:
    dw 428
    db 6
    dw 214
    db 6
    dw 360
    db 6
    dw 180
    db 6
    dw 428
    db 6
    dw 214
    db 6
    dw 285
    db 6
    dw 143
    db 6
    dw 428
    db 6
    dw 214
    db 6
    dw 320
    db 6
    dw 160
    db 6
    dw 428
    db 6
    dw 214
    db 6
    dw 285
    db 6
    dw 143
    db 6
    dw 453
    db 6
    dw 226
    db 6
    dw 360
    db 6
    dw 180
    db 6
    dw 453
    db 6
    dw 226
    db 6
    dw 285
    db 6
    dw 143
    db 6
    dw 480
    db 6
    dw 240
    db 6
    dw 380
    db 6
    dw 190
    db 6
    dw 428
    db 6
    dw 214
    db 6
    dw 360
    db 6
    dw 180
    db 6
