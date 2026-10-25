; Classic end-of-stage count: one cheese disappears as 100 points are added.
; The third stage is settled after the garapa boss, before the bus sequence.
CompleteStage:
    ld a,(_stage)
    cp 3
    jp z,BeginBoss
    jp BeginCheeseBonus

BeginCheeseBonus:
    ld a,7
    ld (_state),a
    call InitSound
    call StopMusic
    xor a
    ld (_hornPhase),a
    ld (_hornClock),a
    ld (_effectTime),a
    ld (_effectTime+1),a
    ld (_effectTime+2),a
    ld (_refueling),a
    ld (_cheese),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_caneActive),a
    ld (_bonusDone),a
    ld (_bonusSoundStep),a
    ld (_bonusBCD),a
    ld (_bonusBCD+1),a
    ld (_bonusBCD+2),a
    ld (_bonusBCD+3),a
    ld a,25
    ld (_bonusClock),a
    call HideSprites
    ld hl,NAMTBL
    ld bc,768
    ld a,32
    call FILVRM
    ld de,StageLabel
    ld bc,0308h
    call PutText
    ld a,(_stage)
    add a,'0'
    ld hl,NAMTBL+3*32+13
    call WRTVRM
    ld de,LevelDoneLabel
    ld bc,030Fh
    call PutText
    ld de,ScoreLabel
    ld bc,0707h
    call PutText
    ld de,CheeseLabel
    ld bc,0A07h
    call PutText
    ld de,BonusLabel
    ld bc,0D07h
    call PutText
    ld de,BonusRateLabel
    ld bc,1106h
    call PutText
    jp DrawBonusNumbers

CheeseBonusTick:
    ld a,(_bonusDone)
    or a
    jr z,.count
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    ld a,(_stage)
    cp 3
    jp z,BeginEnding
    jp AdvanceStage
.count:
    ld a,(_bonusClock)
    or a
    jr z,.convert
    dec a
    ld (_bonusClock),a
    ret
.convert:
    ld a,(_cheeseCount)
    or a
    jr z,.done
    sub 1
    daa
    ld (_cheeseCount),a
    call AddHundred
    ld hl,_bonusBCD
    ld de,HundredBCD
    call SUM_BCD_8D
    call DrawBonusNumbers
    call SoundBonusTick
    ld a,5
    ld (_bonusClock),a
    ret
.done:
    ld a,1
    ld (_bonusDone),a
    ld hl,75
    ld (_stageTimer),hl
    jp SoundBonusDone

DrawBonusNumbers:
    ld hl,_scoreBCD_8Digits
    ld de,_score
    call BcdToString
    ld de,_score
    ld bc,0710h
    call PutText
    ld hl,NAMTBL+10*32+18
    call DrawCheeseDigits
    ld hl,_bonusBCD
    ld de,_bonusText
    call BcdToString
    ld de,_bonusText
    ld bc,0D10h
    jp PutText

LevelDoneLabel: db "CONCLUIDA",0
BonusLabel: db "BONUS",0
BonusRateLabel: db "100 PONTOS POR QUEIJO",0
