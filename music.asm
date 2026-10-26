; Original, light country-style chiptune, on PSG channel C at volume 9/15.
; Foreground effects own their channels; the tune pauses for the horn/refilling
; and resumes its current note once channel C is free again.
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
    ret nz ; never replace a crash or the low-fuel alert
    ld a,(_state)
    cp 4
    jr z,.musicClock ; battle theme keeps channel C while the horn uses A/B
    ld a,(_hornPhase)
    or a
    jr nz,.duck
    ld a,(_refueling)
    or a
    jr nz,.duck
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
    add hl,hl
    add hl,de
    ld de,MusicNotes
    ld a,(_state)
    cp 4
    jr z,.battle
    cp 12
    jr nz,.score
.battle:
    ld de,BattleMusicNotes
.score:
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
    ld (_musicStep),a
.play:
    ld hl,(_musicPeriod)
    ld a,h
    or l
    jr z,.duck ; a zero period in the score is a rest
    ld a,4
    ld e,l
    call Psg_write
    ld a,5
    ld e,h
    call Psg_write
    ld a,(_musicClock)
    cp 3
    jr c,.duck ; small gaps articulate each note
    ld a,10
    ld e,9
    jp Psg_write
.duck:
    ld a,10
    ld e,0
    jp Psg_write

StopMusic:
    xor a
    ld (_musicStep),a
    ld (_musicClock),a
    ld (_musicPeriod),a
    ld (_musicPeriod+1),a
    ld a,(_effectTime+2)
    or a
    ret nz
    ld a,10
    ld e,0
    jp Psg_write

; AY tone periods; timing uses the game's normalized 50Hz clock.
; 32 events, looping in C major, with short notes and a relaxed final cadence.
MusicNotes:
    dw 170 ; E5
    db 12
    dw 214 ; C5
    db 6
    dw 285 ; G4
    db 6
    dw 214 ; C5
    db 12
    dw 170 ; E5
    db 12
    dw 143 ; G5
    db 18
    dw 170 ; E5
    db 6
    dw 190 ; D5
    db 12
    dw 214 ; C5
    db 18
    dw 0
    db 6
    dw 285 ; G4
    db 12
    dw 170 ; E5
    db 12
    dw 190 ; D5
    db 6
    dw 214 ; C5
    db 6
    dw 190 ; D5
    db 12
    dw 170 ; E5
    db 12
    dw 160 ; F5
    db 12
    dw 127 ; A5
    db 6
    dw 160 ; F5
    db 6
    dw 170 ; E5
    db 12
    dw 190 ; D5
    db 12
    dw 143 ; G5
    db 18
    dw 170 ; E5
    db 6
    dw 190 ; D5
    db 12
    dw 214 ; C5
    db 12
    dw 285 ; G4
    db 12
    dw 214 ; C5
    db 12
    dw 170 ; E5
    db 12
    dw 190 ; D5
    db 12
    dw 226 ; B4
    db 12
    dw 214 ; C5
    db 24
    dw 0
    db 12

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
