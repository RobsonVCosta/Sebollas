; Walking prologue and cane collection. Stages 0/1 have no horn or car.
LoadWalkingArt:
    ld a,(_stage)
    cp 2
    ret nc
    ld hl,TrioPatterns
    ld de,SPTPAT
    ld bc,256
    jp LDIRVM
DrawWalkingPlayer:
    ld a,(_carX)
    ld (_playerSprite+1),a
    ld a,(_carY)
    ld (_playerSprite+2),a
    ld ix,_playerSprite
    xor a
    jp DrawLargeSprite

GetCollectibleLabel:
    ld de,CheeseLabel
    ld a,(_stage)
    cp 1
    ret nz
    ld de,CaneLabel
    ret

RoadGarapaPosition:
    ld a,(_mapRow)
    cp 11
    ret nc
    ld b,a
    ld a,12
    sub b
    add a,a
    add a,a
    add a,a
    ld (_roadGarapaY),a
    ld a,12
    call RoadCenter
    sub 8
    ld (_bossX),a
    scf
    ret
DrawRoadGarapa:
    ld a,(_stage)
    or a
    ret nz
    ld a,(_state)
    cp 1
    jr z,.draw
    cp 11
    ret nz
.draw:
    call RoadGarapaPosition
    ret nc
    ld a,(_bossX)
    ld (_bossSprite+1),a
    ld a,(_roadGarapaY)
    ld (_bossSprite+2),a
    ld ix,_bossSprite
    ld a,BOSS_PATTERN/4
    jp DrawLargeSprite
CheckGarapaContact:
    call RoadGarapaPosition
    ret nc
    ld a,(_bossX)
    ld b,a
    ld a,(_carX)
    sub b
    add a,20
    cp 41
    ret nc
    ld a,(_roadGarapaY)
    ld b,a
    ld a,(_carY)
    sub b
    add a,20
    cp 41
    ret nc
    jp BeginGarapaMeeting
BeginGarapaMeeting:
    ld a,11
    ld (_state),a
    ld hl,100
    ld (_stageTimer),hl
    xor a
    ld (_driveStarted),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_caneActive),a
    ld (_bossFlash),a
    ld de,GarapaText
    ld bc,0308h
    call PutText
    call BuildSprites
    jp UploadSprites
MeetingTick:
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    ret nz
    ld a,(_stage)
    or a
    jp z,AdvanceStage
    jp BeginCheeseBonus

BeginCaneChallenge:
    ld a,12
    ld (_state),a
    ld hl,0 ; elapsed time controls herd growth; there is no time limit
    ld (_stageTimer),hl
    xor a
    ld (_caneTotal),a
    ld (_caneHundred),a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_bossFlash),a
    ld (_bossHP),a
    ld (_bossDirection),a
    ld a,1
    ld (_driveStarted),a
    ld (_herdLevel),a
    ld a,20
    ld (_throwClock),a
    ld (_spawnClock),a
    ld a,120
    ld (_bossX),a
    ld a,112
    ld (_carX),a
    ld a,136
    ld (_carY),a
    ld a,5
    ld (_lives),a
    xor a
    ld (_invulnerable),a
    call LoadBossArt
    call LoadSmallCowArt
    call ClearArena
    call DrawArenaStation
    ld de,GarapaQuestion
    ld bc,0306h
    call PutText
    call DrawHUD
    call BuildBossSprites
    jp UploadSprites
CaneChallengeTick:
    ld a,(_caneTotal)
    cp 100
    jr c,.playing
    ld hl,(_stageTimer)
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    jp z,BeginCheeseBonus
    call BuildBossSprites
    jp UploadSprites
.playing:
    call MovePlayer
    call UpdateBossFuel
    ld a,(_state)
    cp 12
    ret nz
    call UpdateWalkingCows
    call CheckHits
    ld a,(_state)
    cp 12
    ret nz
    call UpdateFriendlyCane
    ld a,(_caneTotal)
    cp 100
    jr nc,.render
    ld a,(_tick)
    and 3
    jr nz,.timer
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
    call DrawHUD
.timer:
    ld hl,(_stageTimer)
    ld a,h
    and l
    cp 255
    jr z,.render
    inc hl
    ld (_stageTimer),hl
.render:
    call BuildBossSprites
    jp UploadSprites

UpdateFriendlyCane:
    ld a,(_caneActive)
    or a
    jr nz,.fall
    ld hl,_throwClock
    dec (hl)
    ret nz
    ld a,1
    ld (_caneActive),a
    ld a,(_bossX)
    add a,8
    ld (_caneX),a
    ld a,64
    ld (_caneY),a
    ld a,(_carX)
    add a,8
    ld (_caneTarget),a
    ret
.fall:
    ld a,(_caneY)
    add a,2
    ld (_caneY),a
    cp 184
    jr nc,.remove
    ld a,(_carX)
    ld b,a
    ld a,(_caneX)
    sub b
    add a,8
    cp 40
    ret nc
    ld a,(_carY)
    ld b,a
    ld a,(_caneY)
    sub b
    add a,4
    cp 36
    ret nc
    ld a,(_caneTotal)
    cp 100
    jr nc,.remove
    inc a
    ld (_caneTotal),a
    cp 100
    jr nz,.count
    ld a,1
    ld (_caneHundred),a
    xor a
    ld (_cheeseCount),a
    ld hl,50
    ld (_stageTimer),hl
    jr .sound
.count:
    ld a,(_cheeseCount)
    add a,1
    daa
    ld (_cheeseCount),a
.sound:
    call SoundCollect
    call DrawCheeseHUD
.remove:
    xor a
    ld (_caneActive),a
    ld a,16
    ld (_throwClock),a
    ret

DrawCaneObjective:
    ld de,CaneGoalLabel
    ld bc,0113h
    call PutText
    ld a,(_caneTotal)
    cp 100
    jr c,.belowHundred
    ld a,'1'
    ld hl,NAMTBL+32+25
    jp WRTVRM
.belowHundred:
    ld b,'0'
.tens:
    cp 10
    jr c,.digits
    sub 10
    inc b
    jr .tens
.digits:
    push af
    ld a,b
    ld hl,NAMTBL+32+26
    call WRTVRM
    pop af
    add a,'0'
    ld hl,NAMTBL+32+27
    jp WRTVRM
CaneGoalLabel: db "CANAS 000/100",0

; A single crossing cow avoids overlapping two 32px cows with the wide trio.
; Bytes 6/7 mark a chase and its once-only trigger; BIOS time controls expiry.
UpdateWalkingCows:
    ld a,(_state)
    cp 12
    jp z,UpdateCaneHerd
    ld hl,_cowChaseStart
    ld (_cowTimePtr),hl
    xor a
    ld (_cowLaneMin),a
    ld a,160
    ld (_cowLaneMax),a
    ld a,(_stage)
    or a
    jr nz,.walking
    ld a,(_mapRow)
    cp 11
    jr nc,.walking
    xor a
    ld (_cows),a
    ret
.walking:
    ld a,(_driveStarted)
    or a
    ret z
    ld ix,_cows
    ld a,(ix+0)
    or a
    jp nz,.move
    ld hl,_spawnClock
    dec (hl)
    ret nz
    ld a,40
    ld (_spawnClock),a
    ld (ix+0),1
    ld (ix+4),0
    ld (ix+5),0
    ld (ix+6),0
    ld (ix+7),0
    ld a,(_nextDirection)
    ld (ix+3),a
    xor 1
    ld (_nextDirection),a
    ld a,(_state)
    cp 12
    jr nz,.road
    ld b,120
    ld (ix+2),80
    jr .side
.road:
    ld a,(_mapRow)
    add a,2
    call RoadCenter
    ld b,a
    ld (ix+2),16
.side:
    ld a,(ix+3)
    or a
    ld a,b
    jr nz,.rightSide
    sub 56
    jr .place
.rightSide:
    add a,40
.place:
    ld (ix+1),a
    ret
.move:
MoveWalkingCow:
    ld a,(ix+6)
    or a
    jr nz,.chase
    ld a,(ix+7)
    or a
    jp nz,.cross
    ld a,(_carX)
    sub (ix+1)
    add a,48
    cp 97
    jp nc,.cross
    ld a,(_carY)
    sub (ix+2)
    add a,48
    cp 97
    jp nc,.cross
    ld (ix+6),250
    ld (ix+7),1
    ld hl,(JIFFY)
    ld de,(_cowTimePtr)
    ld a,l
    ld (de),a
    inc de
    ld a,h
    ld (de),a
.chase:
    ld hl,(_cowTimePtr)
    ld e,(hl)
    inc hl
    ld d,(hl)
    ld hl,(JIFFY)
    or a
    sbc hl,de
    ld de,250
    ld a,(_is60Hz)
    or a
    jr z,.duration
    ld de,300
.duration:
    or a
    sbc hl,de
    jr c,.pursuing
    ld (ix+6),0
    jp .cross
.pursuing:
    dec (ix+6)
    jr nz,.chaseMove
    inc (ix+6) ; BIOS time owns expiry even if the game loop runs faster
.chaseMove:
    ld a,(_tick)
    and 1
    ret nz
    ld a,(_state)
    cp 12
    ld b,0
    jr nz,.targetX
    ld b,8
.targetX:
    ld a,(_carX)
    add a,b
    cp (ix+1)
    jr z,.y
    jr c,.chaseLeft
    inc (ix+1)
    jr .y
.chaseLeft:
    dec (ix+1)
.y:
    ld a,(_tick)
    and 3
    ret nz
    ld a,(_state)
    cp 12
    ld b,0
    jr nz,.targetY
    ld b,16
.targetY:
    ld a,(_carY)
    add a,b
    ld b,a
    ld a,(_cowLaneMin)
    cp b
    jr nc,.limitY
    ld a,(_cowLaneMax)
    cp b
    jr c,.limitY
    ld a,b
.limitY:
    cp (ix+2)
    ret z
    jr c,.chaseUp
    inc (ix+2)
    ret
.chaseUp:
    dec (ix+2)
    ret
.cross:
    ld a,(_tick)
    and 1
    ret nz
    ld a,(ix+3)
    or a
    ld a,(ix+1)
    jp nz,.crossLeft
    inc a
    cp 224
    jr nc,.exit
    jr .store
.crossLeft:
    dec a
    jr z,.exit
.store:
    ld (ix+1),a
    ret
.exit:
    ld (ix+0),0
    ld (ix+4),40
    ret

; Compact cows occupy separate vertical lanes, keeping the cane visible.
AppendWalkingCane:
    jp AppendSprite ; lane-separated arena cows leave room for the cane

LoadSmallCowArt:
    ld hl,SmallCowPatterns
    ld de,SPTPAT+DUST_PATTERN*8
    ld bc,128
    jp LDIRVM
DrawChallengeCows:
    ld ix,_cows
    call .cow
    ld ix,_cows+8
    call .cow
    ld ix,_cows+16
.cow:
    ld a,(ix+0)
    or a
    ret z
    ld d,(ix+2)
    ld e,(ix+1)
    ld a,(ix+3)
    add a,a
    add a,DUST_PATTERN/4
    call AppendSprite
    inc a
    jp AppendSprite

UpdateCaneHerd:
    ld a,1
    ld (_herdLevel),a
    ld hl,(_stageTimer)
    ld de,1000
    or a
    sbc hl,de
    jr c,.update
    ld a,2
    ld (_herdLevel),a
    or a
    sbc hl,de
    jr c,.update
    ld a,3
    ld (_herdLevel),a
.update:
    ld ix,_cows
    ld a,80
    ld hl,_cowChaseStart
    call .lane
    ld a,(_herdLevel)
    cp 2
    ret c
    ld ix,_cows+8
    ld a,112
    ld hl,_cowChaseStart2
    call .lane
    ld a,(_herdLevel)
    cp 3
    ret c
    ld ix,_cows+16
    ld a,144
    ld hl,_cowChaseStart3
.lane:
    ld (_cowTimePtr),hl
    ld (_cowLaneMin),a
    add a,16
    ld (_cowLaneMax),a
    ld a,(ix+0)
    or a
    jp nz,MoveWalkingCow
    ld a,(ix+4)
    or a
    jr z,.spawn
    dec (ix+4)
    ret
.spawn:
    ld (ix+0),1
    ld (ix+6),0
    ld (ix+7),0
    ld a,(_cowLaneMin)
    ld (ix+2),a
    ; Enter from the far side, never materialize on top of the trio/deck.
    ld a,(_carX)
    cp 136
    ld a,0
    jr nc,.direction
    inc a
.direction:
    ld (ix+3),a
    or a
    ld a,48
    jr z,.place
    ld a,224
.place:
    ld (ix+1),a
    ret

FishingTitle: db "INDO PESCAR",0
FishingSign: db "PESCA",0
HungerLabel: db "FOME",0
CaneLabel: db "CANAS   ",0
TimeLabel: db "T ",0
GarapaQuestion: db "Voc",243,"s tomam garapa?",0

BeginBarArrival:
    ld a,11
    ld (_state),a
    ld hl,100
    ld (_stageTimer),hl
    xor a
    ld (_driveStarted),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_cheese),a
    call DrawWorld
    ld de,BarArrivalText
    ld bc,0807h
    call PutText
    call BuildSprites
    jp UploadSprites
BarArrivalText: db "CHEGAMOS AO BAR!",0
