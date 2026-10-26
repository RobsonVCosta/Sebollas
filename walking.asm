; Walking prologue and garapa fight. Stages 0/1 have no horn or car.
LoadWalkingArt:
    ld a,(_stage)
    cp 2
    ret nc
    xor a
    ld (_walkFrame),a
    ld hl,TrioPatterns
    ld de,SPTPAT
    ld bc,256
    call LDIRVM
    ld hl,DonkeyPatterns
    ld de,SPTPAT+COW_PATTERN*8
    ld bc,512
    call LDIRVM
    ld a,(_stage)
    or a
    ret nz
    jp PlacePeacefulGarapa

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
    ret ; the peaceful boy is part of the scrolling map
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
    call EraseDonkeyShots
    call ResetDonkeyShots
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
    call ResetDonkeyShots
    ld a,12
    ld (_state),a
    ld hl,0 ; elapsed battle time; there is no time limit
    ld (_stageTimer),hl
    xor a
    ld (_caneTotal),a
    ld (_caneHundred),a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_bossFlash),a
    ld (_bossDefeat),a
    ld (_playerCane),a
    ld (_playerCaneTile),a
    ld (_playerCaneTile+1),a
    ld (_playerCaneClock),a
    ld (_bossDirection),a
    ld (_driveStarted),a
    ld (_garapaTileAddr),a
    ld (_garapaTileAddr+1),a
    ld (_caneTileAddr),a
    ld (_caneTileAddr+1),a
    ld a,12
    ld (_bossHP),a
    ld a,1
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
    xor a
    ld (_invulnerable),a
    call LoadBossArt
    call LoadGarapaTileArt
    call ClearArena
    call DrawArenaStation
    call DrawGarapaPhrase
    call DrawHUD
    call BuildBossSprites
    jp UploadSprites
CaneChallengeTick:
    call CheckDriveStart
    ld a,(_driveStarted)
    or a
    jr nz,.started
    call BuildBossSprites
    jp UploadSprites
.started:
    ld a,(_bossDefeat)
    or a
    jr z,.playing
    ld hl,_bossFlash
    dec (hl)
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
    call UpdatePlayerCane
    ld a,(_bossDefeat)
    or a
    jp nz,.render
    call CheckHits
    ld a,(_state)
    cp 12
    ret nz
    call UpdateFriendlyCane
    ld a,(_state)
    cp 12
    ret nz
    ld a,(_bossFlash)
    or a
    jr z,.moveBoss
    dec a
    ld (_bossFlash),a
.moveBoss:
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
    ld a,72
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
    call .remove
    ld a,(_invulnerable)
    or a
    ret nz
    jp LoseLife
.remove:
    xor a
    ld (_caneActive),a
    ld a,16
    ld (_throwClock),a
    ret

DrawCaneObjective:
    ld hl,NAMTBL+32+22
    ld bc,10
    ld a,32
    jp FILVRM

DrawGarapaPhrase:
    ld de,GarapaQuestion
    ld bc,0306h
    call PutText
    ld de,GarapaHPLabel
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
    push af
    ld a,b
    ld hl,NAMTBL+24
    call WRTVRM
    pop af
    add a,'0'
    ld hl,NAMTBL+25
    jp WRTVRM
GarapaHPLabel: db "GARAPA 00",0

; One upward cane at a time, with a short repeat delay while Space is held.
; Both projectile types use background tiles, keeping all 32 sprite slots
; available for the trio and three full-size donkeys.
UpdatePlayerCane:
    ld a,(_playerCaneClock)
    or a
    jr z,.active
    dec a
    ld (_playerCaneClock),a
.active:
    ld a,(_playerCane)
    or a
    jr nz,.move
    ld a,(_playerCaneClock)
    or a
    ret nz
    xor a
    call GTTRIG
    or a
    ret z
    ld a,1
    ld (_playerCane),a
    ld a,(_carX)
    add a,8
    ld (_playerCaneX),a
    ld a,(_carY)
    ld (_playerCaneY),a
    ld a,18
    ld (_playerCaneClock),a
    ret
.move:
    ld a,(_playerCaneY)
    sub 4
    ld (_playerCaneY),a
    cp 32
    jr c,.remove
    ; Match the visible 20px-wide boy inside his 32px tile canvas.
    ld b,a
    ld a,(_state)
    cp 12
    jr nz,.donkeys
    ld a,b
    cp 72
    jr nc,.donkeys
    ld a,(_bossX)
    ld b,a
    ld a,(_playerCaneX)
    sub b
    cp 24
    jr nc,.donkeys
    xor a
    ld (_playerCane),a
    ld a,10
    ld (_bossFlash),a
    call SoundCollect
    ld hl,_bossHP
    ld a,(hl)
    or a
    ret z
    dec (hl)
    jp nz,DrawHUD
    ld a,1
    ld (_bossDefeat),a
    ld a,75
    ld (_bossFlash),a
    xor a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    jp DrawHUD
.donkeys:
    ld ix,_cows
    call .hitDonkey
    ld ix,_cows+8
    call .hitDonkey
    ld ix,_cows+16
    jp .hitDonkey
.remove:
    xor a
    ld (_playerCane),a
    ret
.hitDonkey:
    ld a,(_playerCane)
    and (ix+0)
    ret z
    ld a,(_playerCaneX)
    sub (ix+1)
    add a,8
    cp 36
    ret nc
    ld a,(_playerCaneY)
    sub (ix+2)
    add a,12
    cp 40
    ret nc
    xor a
    ld (_playerCane),a
    inc (ix+5) ; hits taken, independent for each donkey
    ld a,(ix+5)
    cp 3
    jp c,SoundCow
    ld (ix+0),0
    ld (ix+4),100
    ld a,40
    ld (_spawnClock),a
    call AddHundred
    jp SoundCow

; A single crossing cow avoids overlapping two 32px cows with the wide trio.
; Bytes 6/7 mark a persistent chase; byte 5 counts the three required hits.
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
    ld a,(_cows)
    or a
    ret z
    jr .walking
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
    ld (ix+6),1
    ld (ix+7),1
    ld hl,(JIFFY)
    ld de,(_cowTimePtr)
    ld a,l
    ld (de),a
    inc de
    ld a,h
    ld (de),a
.chase:
.chaseMove:
    ld a,(_state)
    cp 12
    jr z,.chaseStep
    ld a,(_tick)
    and 1
    ret nz
.chaseStep:
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
    ret ; arena pursuit follows X, retaining its 32px lane
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
    ld a,(_state)
    cp 12
    jr z,.crossStep
    ld a,(_tick)
    and 1
    ret nz
.crossStep:
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

UpdateCaneHerd:
    ld a,1
    ld (_herdLevel),a
    xor a
    ld (_cows+8),a
    ld (_cows+16),a
    ld ix,_cows
    ld a,80
    ld hl,_cowChaseStart
.lane:
    ld (_cowTimePtr),hl
    ld (_cowLaneMin),a
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
    ld (ix+5),0
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

; The tile actors preserve the V9938's 32-sprite/eight-per-line limits with
; three full 32x32 donkeys. Their patterns are local to the cane arena.
LoadGarapaTileArt:
    ld de,186*8
    ld b,3
.patterns:
    push bc
    push de
    ld hl,GarapaTilePatterns
    ld bc,128
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .patterns
    ld de,02000h+186*8
    ld b,3
.colors:
    push bc
    push de
    ld hl,GarapaTileColors
    ld bc,128
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .colors
    ret

DrawFriendlyActors:
    call ErasePlayerCane
    ld hl,(_garapaTileAddr)
    ld a,h
    or l
    call nz,EraseGarapaTiles
    call EraseIncomingCane
    xor a
    ld (_garapaTileAddr),a
    ld (_garapaTileAddr+1),a
    ld a,(_bossFlash)
    and 2
    jr nz,.cane
    ld a,(_bossX)
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    ld hl,NAMTBL+5*32
    add hl,de
    ld (_garapaTileAddr),hl
    ex de,hl
    ld hl,GarapaTileMap
    ld b,4
.row:
    push bc
    push hl
    push de
    ld bc,4
    call LDIRVM
    pop hl
    ld de,32
    add hl,de
    ex de,hl
    pop hl
    ld bc,4
    add hl,bc
    pop bc
    djnz .row
.cane:
    xor a
    ld (_caneTileAddr),a
    ld (_caneTileAddr+1),a
    ld a,(_caneActive)
    or a
    jp z,DrawPlayerCane
    ld a,(_caneY)
    srl a
    srl a
    srl a
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,NAMTBL
    add hl,de
    ld a,(_caneX)
    add a,4
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    add hl,de
    ld (_caneTileAddr),hl
    push hl
    call RDVRM
    ld (_incomingUnder),a
    pop hl
    push hl
    ld a,248
    call CompositeCaneTile
    pop hl
    ld de,32
    add hl,de
    push hl
    call RDVRM
    ld (_incomingUnder+1),a
    pop hl
    ld a,249
    call CompositeCaneTile
    jp DrawPlayerCane

; Restore the exact background, including the fishing deck and other actors.
ErasePlayerCane:
    call EraseDonkeyShots
    ld hl,(_playerCaneTile)
    ld a,h
    or l
    ret z
    push hl
    ld a,(_playerCaneUnder)
    call WRTVRM
    pop hl
    ld de,32
    add hl,de
    ld a,(_playerCaneUnder+1)
    call WRTVRM
    xor a
    ld (_playerCaneTile),a
    ld (_playerCaneTile+1),a
    ret

DrawPlayerCane:
    call DrawPlayerCaneBody
    jp DrawDonkeyShots
DrawPlayerCaneBody:
    ld a,(_playerCane)
    or a
    ret z
    ld a,(_playerCaneY)
    and 248
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    ld de,NAMTBL
    add hl,de
    ld a,(_playerCaneX)
    add a,4
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    add hl,de
    ld (_playerCaneTile),hl
    push hl
    call RDVRM
    ld (_playerCaneUnder),a
    pop hl
    push hl
    ld a,246
    call CompositeCaneTile
    pop hl
    ld de,32
    add hl,de
    push hl
    call RDVRM
    ld (_playerCaneUnder+1),a
    pop hl
    ld a,247
    jp CompositeCaneTile

EraseGarapaTiles:
    ld b,4
.row:
    push bc
    push hl
    ld bc,4
    ld a,130
    call FILVRM
    pop hl
    ld de,32
    add hl,de
    pop bc
    djnz .row
    ret
EraseCaneTiles:
    push hl
    ld a,130
    call WRTVRM
    pop hl
    ld de,32
    add hl,de
    ld a,130
    jp WRTVRM
GarapaTileMap: db 186,187,188,189,190,191,192,193
    db 194,195,196,197,198,199,200,201

EraseIncomingCane:
    ld hl,(_caneTileAddr)
    ld a,h
    or l
    ret z
    push hl
    ld a,(_incomingUnder)
    call WRTVRM
    pop hl
    ld de,32
    add hl,de
    ld a,(_incomingUnder+1)
    call WRTVRM
    xor a
    ld (_caneTileAddr),a
    ld (_caneTileAddr+1),a
    ret

; Software transparency: preserve every background pixel outside the cane.
; Dynamic tiles avoid exceeding the MSX's eight hardware sprites per line.
; On multicolor rows the cane shares the foreground color; on solid rows
; it uses cream, retaining the exact original background color.
CompositeCaneTile:
    ld (_compositeTile),a
    ld (_compositeName),hl
    push hl
    call RDVRM
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    ex de,hl
    pop hl
    ld a,h
    sub 018h
    add a,a
    add a,a
    add a,a
    ld b,a
    add a,d
    ld d,a
    ld (_compositeSource),de
    ld a,(_compositeTile)
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,h
    add a,b
    ld h,a
    ld (_compositeDest),hl
    xor a
    ld (_compositeRow),a
.row:
    ld hl,(_compositeSource)
    call RDVRM
    ld (_compositePattern),a
    ld hl,(_compositeSource)
    ld de,02000h
    add hl,de
    call RDVRM
    ld c,a
    ld a,(_compositeTile)
    cp 250
    jr nc,.ball
    ld a,(_compositeRow)
    cp 5
    jr z,.unchanged ; joint in the stalk
    ld a,(_compositePattern)
    or a
    jr z,.solid
    cp 255
    jr nz,.mixed
    ld a,c
    rrca
    rrca
    rrca
    rrca
    ld c,a
.solid:
    ld a,c
    and 15
    or 0B0h
    ld c,a
    xor a
.mixed:
    or 018h
    ld (_compositePattern),a
    jr .unchanged
.ball:
    ld a,(_compositeRow)
    sub 2
    cp 4
    jr nc,.unchanged
    ld b,018h
    or a
    jr z,.ballMask
    cp 3
    jr z,.ballMask
    ld b,03Ch
.ballMask:
    ld a,(_compositePattern)
    cp 255
    jr nz,.ballColor
    ld a,c
    rrca
    rrca
    rrca
    rrca
    ld c,a
    xor a
.ballColor:
    or b
    ld (_compositePattern),a
    ld a,c
    and 15
    or 010h
    ld c,a
.unchanged:
    ld a,c
    ld hl,(_compositeDest)
    ld de,02000h
    add hl,de
    call WRTVRM
    ld hl,(_compositeDest)
    ld a,(_compositePattern)
    call WRTVRM
    ld hl,(_compositeSource)
    inc hl
    ld (_compositeSource),hl
    ld hl,(_compositeDest)
    inc hl
    ld (_compositeDest),hl
    ld hl,_compositeRow
    inc (hl)
    ld a,(hl)
    cp 8
    jp c,.row
    ld hl,(_compositeName)
    ld a,(_compositeTile)
    jp WRTVRM

; The persistent donkey may overlap the peaceful boy and the trio. Draw the
; boy in map tiles to keep all three visible without hardware sprite overflow.
PlacePeacefulGarapa:
    ld de,202*8
    ld b,3
.patterns:
    push bc
    push de
    ld hl,GarapaTilePatterns
    ld bc,128
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .patterns
    ld de,02000h+202*8
    ld b,3
.colors:
    push bc
    push de
    ld hl,GarapaTileColors
    ld bc,128
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .colors
    ld a,12
    call RoadCenter
    sub 8
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    ld hl,WorldMap+10*32
    add hl,de
    ld a,202
    ld b,4
.row:
    ld c,4
.col:
    ld (hl),a
    inc a
    inc hl
    dec c
    jr nz,.col
    ld de,28
    add hl,de
    djnz .row
    ret
