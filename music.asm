; Two-voice PSG reduction of the user-supplied Sultans of Swing excerpt.
; C carries the melody. A supplies backing only while no foreground effect owns it.
UpdateMusic:
    ld a,(_state)
    cp 5
    jp z,UpdateEndingMusic
    cp 6
    jp z,UpdateEndingMusic
    cp 8
    jp z,UpdateEndingMusic
    cp 9
    jp z,UpdateEndingMusic
    cp 7
    jr nz,.normalState
    ld a,(_stage)
    cp 3
    jp z,UpdateEndingMusic
    jp StopMusic
.normalState:
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
    cp 2
    call z,StopMusic
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
    ld e,9
    jp Psg_write
.mute:
    ld a,8
    ld e,0
    jp Psg_write

StopMusic:
    ld a,(_musicMode)
    cp 2
    jr nz,.reset
    ld a,(_effectTime+1)
    or a
    jr nz,.reset
    ld a,9
    ld e,0
    call Psg_write
.reset:
    xor a
    ld (_endingMusicNext),a
    ld (_endingMusicNext+1),a
    ld (_musicHarmonyPeriod),a
    ld (_musicHarmonyPeriod+1),a
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

; Continuous three-voice ending: final bonus, illustrations, bus and credits.
; Effects borrow only their own channel; the score clock never pauses for them.
UpdateEndingMusic:
    ld a,(_musicMode)
    cp 2
    jr z,.clock
    ld a,2
    ld (_musicMode),a
    xor a
    ld (_musicClock),a
    ld hl,GoingHomeNotes
    ld (_endingMusicNext),hl
.clock:
    ld a,(_musicClock)
    or a
    jr z,.next
    dec a
    ld (_musicClock),a
    jr nz,.play
.next:
    ld hl,(_endingMusicNext)
    ld de,GoingHomeNotesEnd
    ld a,h
    cp d
    jr nz,.load
    ld a,l
    cp e
    jr z,.finished
.load:
    ; Only A000-BFFF changes. Illustration copies own 8000-9FFF, and all
    ; executable code remains in 4000-7FFF. Restore the game-data bank.
    ld a,6
    ld (07800h),a
    ld hl,(_endingMusicNext)
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld (_musicBackingPeriod),de
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld (_musicHarmonyPeriod),de
    ld e,(hl)
    inc hl
    ld d,(hl)
    inc hl
    ld (_musicPeriod),de
    ld a,(hl)
    inc hl
    ld (_musicClock),a
.save:
    ld (_endingMusicNext),hl
    ld a,3
    ld (07800h),a
    jr .play
.finished:
    ; Latch ending mode and the end pointer so the song cannot restart.
    ld hl,0
    ld (_musicBackingPeriod),hl
    ld (_musicHarmonyPeriod),hl
    ld (_musicPeriod),hl
.play:
    ld a,(_effectTime)
    or a
    jr nz,.harmony
    ld hl,(_musicBackingPeriod)
    ld bc,000Ah ; A: bass, volume 10
    call PlayEndingVoice
.harmony:
    ld a,(_effectTime+1)
    or a
    jr nz,.lead
    ld hl,(_musicHarmonyPeriod)
    ld bc,0106h ; B: inner part, volume 6
    call PlayEndingVoice
.lead:
    ld a,(_effectTime+2)
    or a
    ret nz
    ld hl,(_musicPeriod)
    ld bc,0209h ; C: melody, volume 9
    jp PlayEndingVoice

PlayEndingVoice:
    ld a,h
    or l
    jr z,.mute
    ld a,b
    add a,a
    ld e,l
    call Psg_write
    ld a,b
    add a,a
    inc a
    ld e,h
    call Psg_write
    ld e,c
    jr .volume
.mute:
    ld e,0
.volume:
    ld a,b
    add a,8
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
