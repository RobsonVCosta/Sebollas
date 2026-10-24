InitVarsAtRAM:
    xor a
    ld hl,_state
    ld de,_state+1
    ld (hl),a
    ld bc,RAM_END-_state-1
    ldir
    ld a,1
    ld (_menuDirty),a
    ret

ResetGame:
    ld a,1
    ld (_state),a
    ld a,120
    ld (_carX),a
    ld a,128
    ld (_carY),a
    ld a,3
    ld (_lives),a
    xor a
    ld (_invulnerable),a
    ld (_fireWait),a
    ld (_scrollClock),a
    ld (_mapRow),a
    ld (_tick),a
    ld (_nextDirection),a
    ld (_fuelClock),a
    ld (_refueling),a
    ld a,138
    ld (_mapRow),a
    ld a,100
    ld (_fuel),a
    xor a
    ld hl,_cows
    ld de,_cows+1
    ld (hl),a
    ld bc,23
    ldir
    ld hl,_scoreBCD_8Digits
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    inc hl
    ld (hl),a
    ld a,1
    ld (_spawnClock),a
    ld hl,NAMTBL
    ld bc,64
    ld a,32
    call FILVRM
    call DrawWorld
    jp DrawHUD
