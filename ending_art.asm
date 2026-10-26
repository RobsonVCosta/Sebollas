; Timed, unskippable illustrations before the car arrival and bus chase.
; The main loop supplies 50 ticks per second in both PAL and NTSC.
BeginEndingArt:
    ld a,8
    ld (_state),a
    ; Illustration 1 starts at physical ROM bank 8 (offset 10000h).
    ld a,8
    call ShowEndingArt
    ld hl,250
    ld (_stageTimer),hl
    ret

EndingArtTick:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    ld a,(_state)
    cp 9
    jp z,BeginEnding
    jp BeginSecondEndingArt

BeginSecondEndingArt:
    ld a,9
    ld (_state),a
    ; Illustration 2 starts at physical ROM bank 16 (offset 20000h).
    ld a,16
    call ShowEndingArt
    ld hl,250
    ld (_stageTimer),hl
    ret

; A = first ASCII8 bank. SCREEN 8 has one GRB332 byte per pixel.
; Only the 8000-9FFF window changes; all code/music remain in the fixed bank.
ShowEndingArt:
    push af
    ld a,8
    call CHGMOD
    call DISSCR
    ld a,(RG9SAV)
    or 080h
    ld c,9
    call WriteVDP
    ld a,(RG8SAV)
    or 2
    ld c,8
    call WriteVDP
    xor a
    ld c,7
    call WriteVDP
    xor a
    ld c,14
    call WriteVDP
    pop af
    ld e,a
    di
    xor a
    out (099h),a
    ld a,040h
    out (099h),a
    ld d,6 ; six complete 8 KiB banks, then the final 20 rows
.bank:
    ld a,e
    ld (07000h),a
    inc e
    ld hl,08000h
    ld bc,02000h
    call .copy
    dec d
    jr nz,.bank
    ld a,e
    ld (07000h),a
    ld hl,08000h
    ld bc,01400h
    call .copy
    ei
    jp ENASCR
.copy:
    ld a,(hl)
    inc hl
    out (098h),a
    dec bc
    ld a,b
    or c
    jr nz,.copy
    ret

; Stage illustrations use the same native 256-color loader as the ending.
BeginStageIntro:
    ld a,10
    ld (_state),a
    ld a,(_stage)
    or a
    jr nz,.standard
    ld a,56
    jr .load
.standard:
    dec a
    add a,a
    add a,a
    add a,a
    add a,24
.load:
    call ShowEndingArt
    ld hl,250
    ld (_stageTimer),hl
    ret
StageIntroTick:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    jp BeginStage
