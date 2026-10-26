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
    call InitSound
    ld a,5
    ld (_lives),a
    call SetupGameVideoHidden
    xor a
    ld (_cheeseCount),a
    ld (_caneTotal),a
    ld (_caneHundred),a
    ld (_continueAvailable),a
    ld hl,_scoreBCD_8Digits
    ld b,4
.score:
    ld (hl),a
    inc hl
    djnz .score
    xor a
    ld (_stage),a
    jp BeginPrologue

; Continue restarts the current stage with its original score and five lives.
ContinueGame:
    call SetupGameVideo
    ld a,(_continueStage)
    ld (_stage),a
    ld a,5
    ld (_lives),a
    ld hl,_continueScore
    ld de,_scoreBCD_8Digits
    ld bc,4
    ldir
    xor a
    ld (_cheeseCount),a
    ld (_caneTotal),a
    ld (_caneHundred),a
    jp ShowStageCard

BeginStage:
    call ResetDonkeyShots
    ld a,1
    ld (_continueAvailable),a
    ld a,(_stage)
    ld (_continueStage),a
    ld hl,_scoreBCD_8Digits
    ld de,_continueScore
    ld bc,4
    ldir
    call SetupGameVideo
    call LoadStageMap
    call LoadWalkingArt
    call InitSound
    xor a
    ld (_invulnerable),a
    ld (_scrollClock),a
    ld (_tick),a
    ld (_nextDirection),a
    ld (_fuelClock),a
    ld (_refueling),a
    ld (_fuelAlertClock),a
    ld (_fuelAlertPitch),a
    ld (_hornPhase),a
    ld (_hornClock),a
    ld (_musicStep),a
    ld (_musicClock),a
    ld (_musicPeriod),a
    ld (_musicPeriod+1),a
    ld (_cheese),a
    ld (_playerCane),a
    ld (_playerCaneClock),a
    ld (_playerCaneTile),a
    ld (_playerCaneTile+1),a
    ld (_driveStarted),a
    ld (_driveArmed),a
    ld (_caneActive),a
    ld (_secondCheese),a
    ld (_thirdCheese),a
    ld (_cowSerial),a
    ld (_effectTime),a
    ld (_effectTime+1),a
    ld (_effectTime+2),a
    ld hl,_cows
    ld de,_cows+1
    ld (hl),a
    ld bc,23
    ldir
    ld a,1
    ld (_state),a
    ld (_spawnClock),a
    ld a,120
    ld (_carX),a
    ld a,(_stage)
    cp 2
    jr nc,.position
    ld a,112
    ld (_carX),a
.position:
    ld a,128
    ld (_carY),a
    ld a,48
    ld (_cheeseClock),a
    ld a,(_stage)
    or a
    ld a,138
    jr nz,.startRow
    ld a,FISHING_START_ROW
.startRow:
    ld (_mapRow),a
    ld a,100
    ld (_fuel),a
.video:
    call ApplyStagePalette
    ld hl,NAMTBL
    ld bc,64
    ld a,32
    call FILVRM
    call DrawWorld
    call DrawHUD
.sprites:
    call BuildSprites
    jp UploadSprites
