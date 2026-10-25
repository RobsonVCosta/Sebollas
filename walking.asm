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
    ld a,120
    ld (_bossX),a
    call LoadBossArt
    call ClearArena
    ld de,GarapaText
    ld bc,0308h
    call PutText
    call BuildBossSprites
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
    ld hl,1500 ; 30 seconds to catch as many canes as possible
    ld (_stageTimer),hl
    xor a
    ld (_caneTotal),a
    ld (_caneActive),a
    ld (_cows),a
    ld (_cows+8),a
    ld (_cows+16),a
    ld (_bossFlash),a
    ld (_bossHP),a
    ld (_bossDirection),a
    ld a,1
    ld (_driveStarted),a
    ld a,20
    ld (_throwClock),a
    ld (_spawnClock),a
    ld a,120
    ld (_bossX),a
    ld a,112
    ld (_carX),a
    ld a,136
    ld (_carY),a
    call LoadBossArt
    call ClearArena
    call DrawArenaStation
    ld de,GarapaQuestion
    ld bc,0306h
    call PutText
    call DrawHUD
    call BuildBossSprites
    jp UploadSprites
CaneChallengeTick:
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
    dec hl
    ld (_stageTimer),hl
    ld a,h
    or l
    jp z,BeginCheeseBonus
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
    add a,12
    cp 48
    ret nc
    ld a,(_carY)
    ld b,a
    ld a,(_caneY)
    sub b
    add a,12
    cp 44
    ret nc
    ld a,(_cheeseCount)
    cp 099h
    jr z,.sound
    add a,1
    daa
    ld (_cheeseCount),a
    ld hl,_caneTotal
    inc (hl)
.sound:
    call SoundCollect
    call DrawCheeseHUD
.remove:
    xor a
    ld (_caneActive),a
    ld a,16
    ld (_throwClock),a
    ret

DrawCaneTimer:
    ld de,TimeLabel
    ld bc,0011h
    call PutText
    ld hl,(_stageTimer)
    ld bc,50
    xor a
.seconds:
    or a
    sbc hl,bc
    jr c,.decimal
    inc a
    jr .seconds
.decimal:
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
    ld hl,NAMTBL+20
    call WRTVRM
    pop af
    add a,'0'
    ld hl,NAMTBL+21
    jp WRTVRM

; A single crossing cow avoids overlapping two 32px cows with the wide trio.
; Per-record bytes 6/7 are the 250-tick chase and the once-only trigger.
UpdateWalkingCows:
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
    ld a,(ix+6)
    or a
    jr nz,.chase
    ld a,(ix+7)
    or a
    jr nz,.cross
    ld a,(_carX)
    sub (ix+1)
    add a,48
    cp 97
    jr nc,.cross
    ld a,(_carY)
    sub (ix+2)
    add a,48
    cp 97
    jr nc,.cross
    ld (ix+6),250
    ld (ix+7),1
    ld hl,(JIFFY)
    ld (_cowChaseStart),hl
.chase:
    ld hl,(JIFFY)
    ld de,(_cowChaseStart)
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
    ld a,(_carX)
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
    ld a,(_carY)
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
    jr nz,.crossLeft
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
    ret

; A cane is temporarily occluded when the existing foreground fills all eight
; hardware slots on a scanline. Pickup logic remains independent of rendering.
AppendWalkingCane:
    push af
    push bc
    push de
    ld a,(_cows)
    or a
    jr z,.visible
    ; Intersection of the cane's 16 rows and the cow's 32 rows.
    ld a,(_cows+2)
    ld b,a
    ld a,d
    cp b
    jr nc,.start
    ld a,b
.start:
    ld b,a
    ld a,(_cows+2)
    add a,32
    ld c,a
    ld a,d
    add a,16
    cp c
    jr c,.end
    ld a,c
.end:
    ld c,a
    ld a,b
    cp c
    jr nc,.visible
    ; Eight existing entries means the cow overlaps either 32px actor here.
    ld a,(_carY)
    cp c
    jr nc,.boss
    add a,32
    cp b
    jr c,.boss
    jr z,.boss
    jr .hidden
.boss:
    ld a,c
    cp 41
    jr c,.visible
    ld a,b
    cp 72
    jr nc,.visible
.hidden:
    pop de
    pop bc
    pop af
    ret
.visible:
    pop de
    pop bc
    pop af
    jp AppendSprite

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
