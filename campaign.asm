; Three-stage campaign, final garapa encounter, bus chase and credits.
CheckDriveStart:
    ld a,(_driveStarted)
    or a
    ret nz
    xor a
    call GTSTCK
    or a
    jr nz,.go
    xor a
    call GTTRIG
    or a
    jr z,.arm
    ld a,(_driveArmed)
    or a
    ret z
.go:
    ld a,1
    ld (_driveStarted),a
    jp DrawWorld
.arm:
    ld a,1
    ld (_driveArmed),a
    ret

ApplyStagePalette:
    ld hl,GamePalette
    ld a,(_stage)
    cp 2
    jr nz,.third
    ld hl,StagePalette1
    jr .upload
.third:
    cp 3
    jr nz,.upload
    ld hl,StagePalette2
.upload:
    push hl
    xor a
    ld c,16
    call WriteVDP
    pop hl
    di
    ld b,32
.loop:
    ld a,(hl)
    inc hl
    out (09Ah),a
    djnz .loop
    ei
    ret

CowSpawnDelay:
    ld a,(_stage)
    cp 3
    ld a,32
    ret z
    ld a,(_stage)
    cp 2
    ld a,80
    ret z
    ld a,128
    ret

AdvanceStage:
    ld a,(_stage)
    inc a
    ld (_stage),a
    ld a,3
    ld (_state),a
    ld hl,100
    ld (_stageTimer),hl
    call StopMusic
    call HideSprites
    ld hl,NAMTBL
    ld bc,768
    ld a,32
    call FILVRM
    ld de,StageLabel
    ld bc,090Ch
    call PutText
    ld a,(_stage)
    add a,'0'
    ld hl,NAMTBL+9*32+17
    call WRTVRM
    ld de,MoreCowsText
    ld a,(_stage)
    cp 3
    jr nz,.caption
    ld de,GarapaText
.caption:
    ld bc,0C06h
    jp PutText

CampaignTick:
    ld a,(_state)
    cp 3
    jr z,.stage
    cp 4
    jp z,BossTick
    cp 5
    jp z,EndingTick
    cp 7
    jp z,CheeseBonusTick
    cp 8
    jp nc,EndingArtTick
    cp 6
    jp z,CreditsTick
    jp MenuTick ; credits wait for a released and re-pressed start key
.stage:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    jp BeginStage

DrawStageHUD:
    ld hl,NAMTBL+17
    ld bc,6
    ld a,32
    call FILVRM
    ld a,(_state)
    cp 4
    jr z,.boss
    ld a,(_refueling)
    or a
    jr nz,.station
    ld de,StageLabel
    ld bc,0011h
    call PutText
    ld a,(_stage)
    add a,'0'
    ld hl,NAMTBL+22
    jp WRTVRM
.station:
    ld de,StationHUD
    ld bc,0011h
    jp PutText
.boss:
    ld de,BossHPLabel
    ld bc,0011h
    call PutText
    ld a,(_bossHP)
    ld b,'0'
.tens:
    cp 10
    jr c,.digits
    sub 10
    inc b
    jr .tens
.digits:
    add a,'0'
    push af
    ld a,b
    ld hl,NAMTBL+20
    call WRTVRM
    pop af
    ld hl,NAMTBL+21
    jp WRTVRM

; Rural intersection used by both the garapa fight and the final bus scene.
ClearArena:
    call HideSprites
    ld hl,NAMTBL
    ld bc,768
    ld a,128
    call FILVRM
    ld hl,NAMTBL+64+8
    ld b,22
.road:
    push bc
    push hl
    ld bc,16
    ld a,130
    call FILVRM
    pop hl
    ld de,32
    add hl,de
    pop bc
    djnz .road
    ld hl,NAMTBL
    ld bc,64
    ld a,32
    jp FILVRM

BeginBoss:
    ld a,4
    ld (_state),a
    ld a,12
    ld (_bossHP),a
    ld a,120
    ld (_bossX),a
    ld (_carX),a
    ld a,136
    ld (_carY),a
    ld a,3
    ld (_lives),a
    ld a,24
    ld (_throwClock),a
    xor a
    ld (_bossDirection),a
    ld (_bossDefeat),a
    ld (_bossFlash),a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_cheese),a
    ld (_refueling),a
    ld (_invulnerable),a
    ld (_hornPhase),a
    ld (_hornClock),a
    ld (_effectTime),a
    ld (_effectTime+1),a
    ld (_effectTime+2),a
    call InitSound
    call ClearArena
    ld de,GarapaText
    ld bc,0308h
    call PutText
    call DrawHUD
    call BuildBossSprites
    jp UploadSprites

BossTick:
    ld a,(_bossDefeat)
    or a
    jp nz,BossDefeatTick
    call MovePlayer
    call UpdateHornInput
    ld a,(_hornPhase)
    cp 1
    jr nz,.move
    ld a,(_hornClock)
    cp 6
    call z,BossTakeHit
    ld a,(_state)
    cp 4
    ret nz
.move:
    ld a,(_bossFlash)
    or a
    jr z,.step
    dec a
    ld (_bossFlash),a
.step:
    ld a,(_tick)
    and 3
    jr nz,.cane
    ld a,(_bossDirection)
    or a
    ld a,(_bossX)
    jr nz,.left
    add a,2
    cp 152
    jr c,.save
    ld a,1
    ld (_bossDirection),a
    ld a,152
    jr .save
.left:
    sub 2
    cp 89
    jr nc,.save
    xor a
    ld (_bossDirection),a
    ld a,88
.save:
    ld (_bossX),a
.cane:
    call UpdateCane
    ld a,(_state)
    cp 4
    ret nz
    ld a,(_tick)
    and 3
    call z,DrawHUD
    call BuildBossSprites
    jp UploadSprites

BossTakeHit:
    ld a,(_bossHP)
    or a
    ret z
    ld a,(_carX)
    ld b,a
    ld a,(_bossX)
    sub b
    add a,48
    cp 97
    ret nc
    ld a,(_carY)
    sub 40
    cp 128
    ret nc
    ld a,10
    ld (_bossFlash),a
    ld hl,_bossHP
    dec (hl)
    ret nz
    ld a,1
    ld (_bossDefeat),a
    xor a
    ld (_caneActive),a
    ld (_hornPhase),a
    ld (_hornClock),a
    ld a,75
    ld (_bossFlash),a
    ret

BossDefeatTick:
    ld a,(_bossDefeat)
    cp 2
    jr z,.run
    ld hl,_bossFlash
    dec (hl)
    jp nz,.draw
    ld a,2
    ld (_bossDefeat),a
    jp .draw
.run:
    ld a,(_bossX)
    add a,2
    cp 240
    jp nc,BeginCheeseBonus
    ld (_bossX),a
.draw:
    call BuildBossSprites
    jp UploadSprites

UpdateCane:
    ld a,(_caneActive)
    or a
    jr nz,.fly
    ld a,(_throwClock)
    or a
    jr z,.throw
    dec a
    ld (_throwClock),a
    ret
.throw:
    ld a,1
    ld (_caneActive),a
    ld a,(_bossX)
    ld (_caneX),a
    ld a,64
    ld (_caneY),a
    ld a,(_carX)
    ld (_caneTarget),a
    ret
.fly:
    ld a,(_caneY)
    add a,2
    cp 184
    jr nc,.remove
    ld (_caneY),a
    ld a,(_tick)
    and 3
    jr nz,.hit
    ld a,(_caneTarget)
    ld b,a
    ld a,(_caneX)
    cp b
    jr z,.hit
    jr c,.right
    sub 2
    jr .x
.right:
    add a,2
.x:
    ld (_caneX),a
.hit:
    ld a,(_invulnerable)
    or a
    ret nz
    ld a,(_caneX)
    ld b,a
    ld a,(_carX)
    sub b
    add a,10
    cp 24
    ret nc
    ld a,(_caneY)
    ld b,a
    ld a,(_carY)
    sub b
    add a,8
    cp 40
    ret nc
    call .remove
    jp LoseLife
.remove:
    xor a
    ld (_caneActive),a
    ld a,24
    ld (_throwClock),a
    ret

; A=first pattern / 4, D=top Y, E=X. Two layers in each 16px half.
DrawPerson:
    ld b,2
.half:
    push bc
    call AppendSprite
    inc a
    call AppendSprite
    inc a
    ld c,a
    ld a,d
    add a,16
    ld d,a
    ld a,c
    pop bc
    djnz .half
    ret

BuildBossSprites:
    call BuildSprites
    ld a,(_bossFlash)
    and 2
    jr nz,.cane
    ld d,40
    ld a,(_bossX)
    ld e,a
    ld a,BOSS_PATTERN/4
    call DrawPerson
.cane:
    ld a,(_caneActive)
    or a
    ret z
    ld a,(_caneX)
    ld e,a
    ld a,(_caneY)
    ld d,a
    ld a,(_tick)
    rrca
    rrca
    and 1
    add a,CANE_PATTERN/4
    jp AppendSprite

BeginEnding:
    ld a,5
    ld (_state),a
    xor a
    ld (_endingPhase),a
    ld (_endingClock),a
    ld (_endingClock+1),a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_cheese),a
    ld (_refueling),a
    ld (_driveStarted),a
    ld (_hornPhase),a
    ld (_hornClock),a
    ld (_effectTime),a
    ld (_effectTime+1),a
    ld (_effectTime+2),a
    ld (_invulnerable),a
    ld a,120
    ld (_carX),a
    ld (_carY),a
    ld a,248 ; starts fully outside the left edge
    ld (_busColumn),a
    ld a,255
    ld (_runnerSmallX),a
    ld (_runnerTallX),a
    ld (_runnerFatX),a
    call InitSound
    call ClearArena
    ld de,VictoryText
    ld bc,0307h
    call PutText
    ld de,BusDestination
    ld bc,0604h
    call PutText
    call DrawBusRoad
    call BuildEndingSprites
    jp UploadSprites

EndingTick:
    ld a,(_endingPhase)
    or a
    jp z,.park
    cp 2
    jp z,.hold
    cp 3
    jp z,.wait
    cp 4
    jp nc,.bus
    ld hl,(_endingClock)
    inc hl
    ld (_endingClock),hl
    ld a,l
    cp 20
    jr nz,.tall
    ld a,112
    ld (_runnerSmallX),a
.tall:
    ld a,l
    cp 45
    jr nz,.fat
    ld a,120
    ld (_runnerTallX),a
.fat:
    ld a,l
    cp 70
    jp nz,.draw
    ld a,112
    ld (_runnerFatX),a
    ld a,3
    ld (_endingPhase),a
    ld hl,100 ; let everyone stand outside the car for two seconds
    ld (_stageTimer),hl
    jp .draw
.wait:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    jp nz,.draw
    ld a,4
    ld (_endingPhase),a
    jp .draw
.bus:
    ld a,(_tick)
    and 3
    jr nz,.chase
    ld a,(_busColumn)
    cp 33
    jr z,.chase
    inc a
    ld (_busColumn),a
    call DrawBusRoad
.chase:
    ld a,(_endingPhase)
    cp 5
    jr z,.run
    ld a,(_busColumn)
    cp 18
    jp c,.draw
    cp 34
    jp nc,.draw ; negative columns before the bus enters
    ld a,5
    ld (_endingPhase),a
.run:
    ld hl,_runnerSmallX
    call AdvanceRunner
    ld hl,_runnerTallX
    call AdvanceRunner
    ld hl,_runnerFatX
    call AdvanceRunner
    ld a,(_runnerSmallX)
    cp 254
    jp nz,.draw
    ld a,(_runnerTallX)
    cp 254
    jp nz,.draw
    ld a,(_runnerFatX)
    cp 254
    jp nz,.draw
    ld a,2
    ld (_endingPhase),a
    ld hl,80
    ld (_stageTimer),hl
    ld de,CaughtBusText
    ld bc,0806h
    call PutText
.draw:
    call BuildEndingSprites
    jp UploadSprites
.park:
    ld a,(_carY)
    cp 136
    jr nc,.parked
    inc a
    ld (_carY),a
    jp .draw
.parked:
    ld a,1
    ld (_endingPhase),a
    jp .draw
.hold:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    jp z,BeginEndingArt
    jp .draw

AdvanceRunner:
    ld a,(hl)
    cp 254
    ret nc
    inc a
    cp 240
    jr nc,.board
    ld b,a
    ld a,(_busColumn)
    cp 30
    jr nc,.save
    add a,a
    add a,a
    add a,a
    sub 4
    cp b
    jr z,.board
    jr c,.board
.save:
    ld (hl),b
    ret
.board:
    ld (hl),254
    ret

DrawBusRoad:
    ld hl,NAMTBL+11*32
    ld bc,5*32
    ld a,157
    call FILVRM
    ld a,11
    ld (_drawY),a
    ld hl,BusTileMap
    ld b,4
.row:
    push bc
    ld a,(_busColumn)
    ld (_drawX),a
    ld b,8
.col:
    ld a,(_drawX)
    cp 32
    jr nc,.skip
    push bc
    push hl
    ld a,(_drawY)
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(_drawX)
    ld e,a
    ld d,0
    add hl,de
    ld de,NAMTBL
    add hl,de
    ex de,hl
    pop hl
    ld a,(hl)
    push hl
    ex de,hl
    call WRTVRM
    pop hl
    pop bc
.skip:
    inc hl
    ld a,(_drawX)
    inc a
    ld (_drawX),a
    djnz .col
    ld a,(_drawY)
    inc a
    ld (_drawY),a
    pop bc
    djnz .row
    ret

BuildEndingSprites:
    call BuildSprites
    ld a,(_runnerSmallX)
    cp 254
    jr nc,.tall
    ld e,a
    ld a,RUNNER_SMALL_PATTERN/4
    call .person
.tall:
    ld a,(_runnerTallX)
    cp 254
    jr nc,.fat
    ld e,a
    ld a,RUNNER_TALL_PATTERN/4
    call .person
.fat:
    ld a,(_runnerFatX)
    cp 254
    ret nc
    ld e,a
    ld a,RUNNER_FAT_PATTERN/4
.person:
    ld c,a
    ld a,(_endingPhase)
    cp 5
    ld a,0
    jr nz,.pose
    ld a,(_tick)
    rrca
    rrca
    rrca
    and 1
    add a,a
    add a,a
.pose:
    add a,c
    ld d,96
    jp DrawPerson

ShowCredits:
    call SetupGameVideo ; restore tiles, palette and banks after SCREEN 8
    ld a,6
    ld (_state),a
    xor a
    ld (_startArmed),a
    call HideSprites
    ld hl,NAMTBL
    ld bc,768
    ld a,32
    call FILVRM
    ld hl,CreditSequence
    ld (_creditNext),hl
    ld hl,0
    ld (_creditDest),hl
    xor a
    ld (_creditClock),a
    ret

CreditsTick:
    call RevealCreditLetter
    jp MenuTick

; A character every two game ticks, including the heading and signature.
RevealCreditLetter:
    ld a,(_creditClock)
    or a
    jr z,.ready
    dec a
    ld (_creditClock),a
    ret
.ready:
    ld hl,(_creditNext)
    ld de,(_creditDest)
    ld a,d
    or e
    jr nz,.letter
.line:
    ld a,(hl)
    cp 255
    ret z
    ld e,a
    ld d,0
    inc hl
    ex de,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld bc,NAMTBL
    add hl,bc
    ex de,hl
    ld a,(hl)
    inc hl
    add a,e
    ld e,a
    jr nc,.letter
    inc d
.letter:
    ld a,(hl)
    inc hl
    or a
    jr nz,.write
    jp .line
.write:
    ld (_creditNext),hl
    push de
    ex de,hl
    call WRTVRM
    pop hl
    inc hl
    ld (_creditDest),hl
    ld a,1
    ld (_creditClock),a
    ret

StageLabel: db "FASE ",0
MoreCowsText: db "MAIS VACAS NA ESTRADA",0
GarapaText: db "GAROTO DA GARAPA",0
BossHPLabel: db "HP ",0
StationHUD: db "POSTO",0
VictoryText: db "VENCEMOS A GARAPA!",0
BusDestination: db "ONIBUS PARA NOVA IGUA",244,"U",0
CaughtBusText: db "PEGAMOS O ONIBUS!",0
BusTileMap: db "N.IGUA",244,"U",208,209,210,211,212,213,214,215
    db 216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231
CreditSequence: db 1,12,"CREDITOS",0
    include "resources/generated/credits.inc"
