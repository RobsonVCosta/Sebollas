; Three-stage campaign, final garapa encounter, bus chase and credits.
CheckDriveStart:
    ld a,(_driveStarted)
    or a
    ret nz
    xor a
    call GTSTCK
    or a
    ret z
    ld a,1
    ld (_driveStarted),a
    ld a,(_state)
    cp 1
    jp z,DrawWorld
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
UploadPalette:
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
ShowStageCard:
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
    ld a,(_stage)
    or a
    jr nz,.notFishing
    ld de,FishingTitle
    ld bc,090Ah
    jp PutText
.notFishing:
    cp 3
    jr nz,.numbered
    ld de,FinalStageText
    ld bc,090Bh
    call PutText
    ld de,FinalStageSubtitle
    ld bc,0B07h
    jp PutText
.numbered:
    cp 2
    jr nz,.stageNumber
    ld de,GrandmaTitle
    ld bc,080Ch
    jp PutText
.stageNumber:
    ld de,GarapaStageTitle
    ld bc,090Ch
    jp PutText
GarapaStageTitle: db "Garapa??",0

CampaignTick:
    ld a,(_state)
    cp 13
    jp z,PrologueTick
    cp 3
    jr z,.stage
    cp 4
    jp z,BossTick
    cp 5
    jp z,EndingTick
    cp 7
    jp z,CheeseBonusTick
    cp 11
    jp z,MeetingTick
    cp 12
    jp z,CaneChallengeTick
    cp 10
    jp z,StageIntroTick
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
    jp BeginStageIntro

DrawStageHUD:
    ld hl,NAMTBL+17
    ld bc,6
    ld a,32
    call FILVRM
    ld a,(_state)
    cp 12
    jp z,DrawGarapaPhrase
    cp 4
    jr z,.boss
    ld a,(_refueling)
    or a
    jr nz,.station
    ret
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
    ld a,(_state)
    cp 12
    jr nz,.roadSize
    pop hl
    push hl
    ld a,l
    sub 6
    ld l,a
    jr nc,.wide
    dec h
.wide:
    ld bc,28
.roadSize:
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
    ld a,24
    ld (_throwClock),a
    xor a
    ld (_bossDirection),a
    ld (_bossDefeat),a
    ld (_bossFlash),a
    ld (_caneActive),a
    ld (_secondCheese),a
    ld (_thirdCheese),a
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
    ld (_driveStarted),a
    call InitSound
    xor a
    ld (_musicStep),a
    ld (_musicClock),a
    call LoadBossArt
    call ClearArena
    call DrawArenaStation
    ld de,GarapaText
    ld a,(_stage)
    cp 3
    jr nz,.name
    ld de,CheeseManPhrase
.name:
    ld bc,0308h
    ld a,(_stage)
    cp 3
    jr nz,.caption
    ld bc,0305h
.caption:
    call PutText
    call DrawHUD
    call BuildBossSprites
    jp UploadSprites

BossTick:
    call CheckDriveStart
    ld a,(_driveStarted)
    or a
    ret z
    ld a,(_bossDefeat)
    or a
    jp nz,BossDefeatTick
    call MovePlayer
    call UpdateBossFuel
    ld a,(_state)
    cp 4
    ret nz
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
    ld b,2
    ld c,a
    ld a,(_stage)
    cp 3
    jr nz,.rightSpeed
    inc b
.rightSpeed:
    ld a,c
    add a,b
    cp 152
    jr c,.save
    ld a,1
    ld (_bossDirection),a
    ld a,152
    jr .save
.left:
    ld b,2
    ld c,a
    ld a,(_stage)
    cp 3
    jr nz,.leftSpeed
    inc b
.leftSpeed:
    ld a,c
    sub b
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
    ld (_secondCheese),a
    ld (_thirdCheese),a
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
    ld b,a
    ld a,(_secondCheese)
    or b
    ld b,a
    ld a,(_thirdCheese)
    or b
    jr nz,.advance
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
    ld a,(_stage)
    cp 3
    ret nz
    ld a,1
    ld (_secondCheese),a
    ld a,(_bossX)
    sub 10
    ld (_caneX),a
    add a,20
    ld (_secondCheese+1),a
    ld a,64
    ld (_secondCheese+2),a
    ld a,(_carX)
    sub 12
    ld (_caneTarget),a
    add a,24
    ld (_secondCheese+3),a
    ld a,(_bossHP)
    cp 4
    ret nc
    or a
    ret z
    ld a,1
    ld (_thirdCheese),a
    ld a,(_bossX)
    ld (_thirdCheese+1),a
    sub 16
    ld (_caneX),a
    add a,32
    ld (_secondCheese+1),a
    ; All three launch together. The center one leads by 16 pixels so the
    ; V9938 never has to draw six cheese layers on the same line as the car.
    ld a,80
    ld (_thirdCheese+2),a
    ld a,(_carX)
    ld (_thirdCheese+3),a
    sub 24
    ld (_caneTarget),a
    add a,48
    ld (_secondCheese+3),a
    ret
.advance:
    ld ix,_caneActive
    call MoveBossProjectile
    ld a,(_state)
    cp 4
    ret nz
    ld ix,_secondCheese
    call MoveBossProjectile
    ld a,(_state)
    cp 4
    ret nz
    ld ix,_thirdCheese
MoveBossProjectile:
    ld a,(ix+0)
    or a
    ret z
.fly:
    ld a,(_stage)
    cp 3
    ld b,2
    jr nz,.speed
    inc b
.speed:
    ld a,(ix+2)
    add a,b
    cp 184
    jr nc,.remove
    ld (ix+2),a
    ld a,(_tick)
    and 3
    jr nz,.hit
    ld a,(ix+3)
    ld b,a
    ld a,(ix+1)
    cp b
    jr z,.hit
    jr c,.right
    sub 2
    jr .x
.right:
    add a,2
.x:
    ld (ix+1),a
.hit:
    ld a,(_invulnerable)
    or a
    ret nz
    ld a,(ix+1)
    ld b,a
    ld a,(_carX)
    sub b
    add a,10
    cp 24
    ret nc
    ld a,(ix+2)
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
    ld (ix+0),a
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
    ld a,(_state)
    cp 12
    jp z,DrawFriendlyActors
    ld a,(_bossFlash)
    and 2
    jr nz,.cane
    ld a,(_bossX)
    ld (_bossSprite+1),a
    ld a,40
    ld (_bossSprite+2),a
    ld ix,_bossSprite
    ld a,BOSS_PATTERN/4
    call DrawLargeSprite
.cane:
    ld ix,_caneActive
    call DrawBossProjectile
    ld ix,_secondCheese
    call DrawBossProjectile
    ld ix,_thirdCheese
DrawBossProjectile:
    ld a,(ix+0)
    or a
    ret z
    ld e,(ix+1)
    ld d,(ix+2)
    ld a,CANE_PATTERN/4
    call AppendSprite
    inc a
    jp AppendSprite

BeginEnding:
    call SetupGameVideo
    ld a,5
    ld (_state),a
    xor a
    ld (_endingPhase),a
    ld (_endingClock),a
    ld (_endingClock+1),a
    ld (_caneActive),a
    ld (_secondCheese),a
    ld (_thirdCheese),a
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
    call ApplyStagePalette ; restore road/runner colors after the cheese boss
    call ClearArena
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
    ld a,96
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
    ld a,144
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
    jp z,ShowCredits
    jp .draw

AdvanceRunner:
    ld a,(hl)
    cp 254
    ret nc
    inc a
    cp 240
    jr nc,.board
    ld (hl),a
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

 ; Story prologue uses the same letter renderer and font as the credits.
BeginPrologue:
    ld a,13
    ld (_state),a
    call InitSound
    call StopMusic
    xor a
    ld (_introDone),a
    ld (_hornPhase),a
    ld (_effectTime),a
    ld (_effectTime+1),a
    ld (_effectTime+2),a
    call InitSpacedText
    ld hl,PrologueSequence
    ld (_creditNext),hl
    ret

PrologueTick:
    ld a,(_introDone)
    or a
    jp z,RevealCreditLetter
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    call SetupGameVideo ; restore the standard font after the pixel text screen
    jp ShowStageCard

ShowCredits:
    call SetupGameVideo ; restore tiles, palette and banks after SCREEN 8
    ld a,6
    ld (_state),a
    xor a
    ld (_startArmed),a
    call InitSpacedText
    ld hl,CreditSequence
    ld (_creditNext),hl
    ret

; Unique tiles per screen cell let text start at any pixel Y in SCREEN 4.
; Glyphs retain their original 8px height, with 11px between adjacent baselines.
InitSpacedText:
    call DISSCR
    call HideSprites
    ld hl,CHRTBL
    ld bc,6144
    xor a
    call FILVRM
    ld hl,CLRTBL
    ld bc,6144
    ld a,0F1h
    call FILVRM
    ld hl,_screenBuffer
    ld b,3
.bank:
    push bc
    xor a
.tile:
    ld (hl),a
    inc hl
    inc a
    jr nz,.tile
    pop bc
    djnz .bank
    ld hl,_screenBuffer
    ld de,NAMTBL
    ld bc,768
    call LDIRVM
    xor a
    ld (_textLine),a
    ld (_textY),a
    ld (_textDone),a
    ld (_creditClock),a
    ld (_creditDest),a
    ld (_creditDest+1),a
    jp ENASCR

CreditsTick:
    call RevealCreditLetter
    jp MenuTick

; A character every two game ticks, including the heading and signature.
RevealCreditLetter:
    ld a,(_textDone)
    or a
    ret nz
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
    jr nz,.row
    ld a,1
    ld (_textDone),a
    ld (_creditNext),hl
    ld a,(_state)
    cp 13
    ret nz
    ld a,1
    ld (_introDone),a
    ld hl,250 ; five seconds to read the complete introduction
    ld (_stageTimer),hl
    ret
.row:
    add a,a
    add a,a
    add a,a
    ld b,a
    ld a,(_textLine)
    ld c,a
    add a,a
    add a,c
    add a,b
    ld (_textY),a
    ld a,(_textLine)
    inc a
    ld (_textLine),a
    inc hl
    ld c,(hl)
    inc hl
    push hl
    ld a,(_textY)
    call TextPatternAddress
    ex de,hl
    pop hl
.letter:
    ld a,(hl)
    inc hl
    or a
    jr nz,.write
    jp .line
.write:
    ld (_creditNext),hl
    push de
    call DrawSpacedLetter
    pop hl
    ld de,8
    add hl,de
    ld (_creditDest),hl
    ld a,1
    ld (_creditClock),a
    ld a,(_state)
    cp 13
    jp z,SoundTypewriter
    ret

; A=pixel Y, C=tile column. Return the first pattern byte in HL.
TextPatternAddress:
    ld l,a
    and 7
    ld e,a
    ld d,0
    ld a,l
    and 0F8h
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,de
    ld a,c
    add a,a
    add a,a
    add a,a
    ld e,a
    ld d,0
    add hl,de
    ret

; A=character, DE=first VRAM pattern byte. Split across tile rows as needed.
DrawSpacedLetter:
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    ld bc,TilePatterns
    add hl,bc
    ld a,(_textY)
    and 7
    ld c,a
    ld b,8
.row:
    ld a,(hl)
    inc hl
    push hl
    push bc
    push de
    ex de,hl
    call WRTVRM
    pop de
    pop bc
    pop hl
    inc de
    inc c
    ld a,c
    and 7
    jr nz,.next
    ld a,e
    add a,248
    ld e,a
    jr nc,.next
    inc d
.next:
    djnz .row
    ret

PrologueSequence:
    include "resources/generated/prologue.inc"

StageLabel: db "FASE ",0
FinalStageText: db "FASE FINAL",0
FinalStageSubtitle: db "O homem do queijo",0
GrandmaTitle: db "Vov",242,"!!!",0
MoreCowsText: db "MAIS VACAS NA ESTRADA",0
GarapaText: db "GAROTO DA GARAPA",0
CheeseManText: db "HOMEM DO QUEIJO",0
CheeseManPhrase: db "Experimentem meu queijo",0
BossHPLabel: db "HP ",0
StationHUD: db "POSTO",0
BusDestination: db "ONIBUS PARA NOVA IGUA",244,"U",0
BusTileMap: db "N.IGUA",244,"U",208,209,210,211,212,213,214,215
    db 216,217,218,219,220,221,222,223,224,225,226,227,228,229,230,231
CreditSequence: db 1,12,"CREDITOS",0
    include "resources/generated/credits.inc"

; Swap only the shared boss/projectile patterns; road sprites stay intact.
LoadBossArt:
    ld hl,SpritePatterns+BOSS_PATTERN*8
    ld a,(_stage)
    cp 3
    jr nz,.copy
    ld hl,CheeseBossPatterns
.copy:
    ld de,SPTPAT+BOSS_PATTERN*8
    ld bc,320
    call LDIRVM
    ld a,(_stage)
    cp 3
    ret nz
    ld hl,CheeseFightPalette
    jp UploadPalette

DrawArenaStation:
    ld a,(_stage)
    cp 2
    jr nc,.floorStart
    ld hl,NAMTBL+10*32+24
    ld b,4
.pond:
    push bc
    push hl
    ld bc,8
    ld a,145
    call FILVRM
    pop hl
    ld de,32
    add hl,de
    pop bc
    djnz .pond
.floorStart:
    ld hl,NAMTBL+14*32+24
    ld b,10
.floor:
    push bc
    push hl
    ld bc,8
    ld a,(_stage)
    cp 2
    ld a,157
    jr nc,.floorTile
    ld a,159
.floorTile:
    call FILVRM
    pop hl
    ld de,32
    add hl,de
    pop bc
    djnz .floor
    ld de,StationHUD
    ld a,(_stage)
    cp 2
    jr nc,.stationSign
    ld de,FishingSign
.stationSign:
    ld bc,0D1Ah
    call PutText
    ld a,(_stage)
    cp 2
    ret c
    ld hl,NAMTBL+14*32+28
    ld a,154
    call WRTVRM
    ld hl,NAMTBL+14*32+29
    ld a,156
    call WRTVRM
    ld hl,NAMTBL+15*32+28
    ld a,155
    call WRTVRM
    ld hl,NAMTBL+15*32+29
    ld a,156
    jp WRTVRM
