; SEBOLLAS -- MSX2, SCREEN 4 game / SCREEN 5 title, 64 KiB ASCII16 cartridge.
    include ram_vars.asm
    include bios.asm
    include "resources/generated/assets.inc"
    include "resources/generated/title.inc"
    OUTPUT Sebollas.rom
    org 4000h
    db "AB"
    dw START,0,0,0
    db 0,0,0,0,0,0
START:
    di
    ld sp,0F380h
    ld a,(MSXVER)
    or a
    jr nz,.msx2
    ei
    ld hl,MSX2Message
.unsupported:
    ld a,(hl)
    or a
    jr z,.stop
    push hl
    call CHPUT
    pop hl
    inc hl
    jr .unsupported
.stop:
    halt
    jr .stop
.msx2:
    call MapCartridgePage2
    call InitVarsAtRAM
    ei
    ; Normalize both display standards to 50 game ticks per second.
    ld a,(RG9SAV)
    and 2
    xor 2
    ld (_is60Hz),a
    call SetupGameVideo
    call InitSound
    call ShowMenu
MainLoop:
    halt
    ld a,(_is60Hz)
    or a
    jr z,.tick
    ld a,(_framePhase)
    inc a
    cp 6
    jr c,.savePhase
    xor a
    ld (_framePhase),a
    jp MainLoop
.savePhase:
    ld (_framePhase),a
.tick:
    ld hl,_tick
    inc (hl)
    call UpdateSound
    ld a,(_state)
    cp 1
    jr z,.play
    cp 3
    jr c,.menu
    call CampaignTick
    jp MainLoop
.menu:
    call MenuTick
    jp MainLoop
.play:
    call CheckDriveStart
    ld a,(_driveStarted)
    or a
    jr nz,.driving
    call BuildSprites
    call UploadSprites
    jp MainLoop
.driving:
    call MovePlayer
    call UpdateJourney
    ld a,(_state)
    cp 1
    jp nz,MainLoop
    call UpdateHornInput
    call UpdateScroll
    call UpdateCheese
    call UpdateCows
    call CheckHits
    ld a,(_state)
    cp 1
    jp nz,MainLoop
    ld a,(_tick)
    and 3
    call z,DrawHUD
    call BuildSprites
    call UploadSprites
    jp MainLoop

MapCartridgePage2:
    ; The ASCII16 cartridge also maps 8000-BFFF. BIOS initially maps page 1;
    ; select the same primary/expanded slot for page 2 before reading the art.
    call RSLREG
    rrca
    rrca
    and 3
    ld c,a
    ld b,0
    ld hl,EXPTBL
    add hl,bc
    or (hl)
    ld e,a
    ld hl,SLTTBL
    add hl,bc
    ld a,(hl)
    and 0Ch
    or e
    ld h,080h
    jp ENASLT

SetupGameVideo:
    ld a,1
    ld (077FFh),a ; ASCII16: game data in 8000-BFFF
    ld a,4
    call CHGMOD
    call DISSCR
    call ERAFNK
    xor a
    ld (KEYSND),a
    ld a,(RG8SAV)
    and 0FDh
    ld c,8
    call WriteVDP
    ; Force 192 visible lines, preserving the BIOS 50/60Hz selection.
    ld a,(RG9SAV)
    and 07Fh
    ld c,9
    call WriteVDP
    ; 16x16 sprites, no magnification, display and VBlank IRQ enabled.
    ld a,0A2h
    ld c,1
    call WriteVDP
    ; Explicit SCREEN 4 layout: color=1C00, SAT=1E00, patterns=3800.
    ld a,03Fh
    ld c,5
    call WriteVDP
    xor a
    ld c,11
    call WriteVDP
    ld a,7
    ld c,6
    call WriteVDP
    xor a
    ld c,7
    call WriteVDP
    call LoadGraphics
    call HideSprites
    jp ENASCR

WriteVDP:
    ld b,a
    jp WRTVDP

LoadGraphics:
    ; Identical ASCII and scenery definitions in all three vertical banks.
    ld de,CHRTBL
    ld b,3
.patterns:
    push bc
    push de
    ld hl,TilePatterns
    ld bc,2048
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .patterns
    ld de,CLRTBL
    ld b,3
.colors:
    push bc
    push de
    ld hl,TileColors
    ld bc,2048
    call LDIRVM
    pop hl
    ld de,2048
    add hl,de
    ex de,hl
    pop bc
    djnz .colors
    ld hl,SpritePatterns
    ld de,SPTPAT
    ld bc,SPRITE_BYTES
    call LDIRVM
    ld a,0
    ld c,16
    call WriteVDP
    di
    ld hl,GamePalette
    ld b,32
.palette:
    ld a,(hl)
    out (09Ah),a
    inc hl
    djnz .palette
    ei
    ret

; Start keys are release-armed on every title/gameover transition.
ReadStart:
    xor a
    call GTTRIG
    or a
    jr nz,.pressed
    ld a,7
    call SNSMAT
    bit 7,a
    jr z,.pressed
    xor a
    ret
.pressed:
    ld a,1
    ret
MenuTick:
    call ReadStart
    or a
    jr nz,.pressed
    ld a,1
    ld (_startArmed),a
    jr .blink
.pressed:
    ld a,(_startArmed)
    or a
    jr z,.blink
    xor a
    ld (_startArmed),a
    ld a,(_state)
    cp 2
    jr nc,.title
    call SoundStart
    jp ResetGame
.title:
    xor a
    ld (_state),a
    jp ShowMenu
.blink:
    ld a,(_state)
    or a
    ret nz
    ld a,(_tick)
    and 15
    ret nz
    ld a,(_tick)
    and 16
    xor 16
    jp DrawTitlePlay

ShowMenu:
    call StopMusic
    xor a
    ld (_state),a
    ld (_startArmed),a
    jp ShowTitleArt

ShowGameOver:
    call StopMusic
    call DrawHUD
    call HideSprites
    ; Preserve the final world, with a centered three-row message panel.
    ld hl,NAMTBL+10*32+10
    ld b,3
.panel:
    push bc
    push hl
    ld bc,11
    ld a,32
    call FILVRM
    pop hl
    ld bc,32
    add hl,bc
    pop bc
    djnz .panel
    xor a
    ld (_startArmed),a
    ld de,GameOverText
    ld a,(_state)
    cp 3
    jr nz,.message
    ld de,ArrivalText
.message:
    ld bc,0B0Bh
    jp PutText

MovePlayer:
    xor a
    call GTSTCK
    ld (_direction),a
    cp 1
    jr z,.up
    cp 2
    jr z,.up
    cp 8
    jr nz,.downTest
.up:
    ld a,(_carY)
    cp 32
    jr z,.downTest
    dec a
    ld (_carY),a
.downTest:
    ld a,(_direction)
    cp 4
    jr z,.down
    cp 5
    jr z,.down
    cp 6
    jr nz,.leftTest
.down:
    ld a,(_carY)
    cp 144
    jr z,.leftTest
    inc a
    ld (_carY),a
.leftTest:
    ld a,(_direction)
    cp 6
    jr z,.left
    cp 7
    jr z,.left
    cp 8
    jr nz,.rightTest
.left:
    ld a,(_carX)
    cp 32
    jr z,.rightTest
    sub 2
    ld (_carX),a
.rightTest:
    ld a,(_direction)
    cp 2
    jr z,.right
    cp 3
    jr z,.right
    cp 4
    jr nz,.invulnerability
.right:
    ld a,(_carX)
    cp 208
    jr z,.invulnerability
    add a,2
    ld (_carX),a
.invulnerability:
    ld a,(_invulnerable)
    or a
    ret z
    dec a
    ld (_invulnerable),a
    ret

UpdateHornInput:
    xor a
    call GTTRIG
    or a
    jr z,.sounding
    call SoundHorn
.sounding:
    ld a,(_hornPhase)
    or a
    ret z
    cp 2 ; the pause between the two horn notes is silent
    ret z
    jp ScareCowsAhead

ScareCowsAhead:
    ld ix,_cows
    call .cow
    ld ix,_cows+8
.cow:
    ld a,(ix+0)
    or a
    ret z
    ld a,(ix+4)
    or a
    ret nz
    ; Sound reaches the road ahead immediately, including a bend in the lane.
    ld a,(_carX)
    sub (ix+1)
    add a,40
    cp 97
    ret nc
    ld a,(_carY)
    sub (ix+2)
    cp 128
    ret nc
    ld (ix+4),1
    call AddHundred
    jp SoundCow

UpdateScroll:
    ld a,(_driveStarted)
    or a
    ret z
    ld a,(_refueling)
    or a
    ret nz
    ld a,(_mapRow)
    or a
    ret z
    ld a,(_scrollClock)
    inc a
    and 7
    ld (_scrollClock),a
    ret nz
    ld a,(_mapRow)
    dec a
    ld (_mapRow),a
    ld ix,_cows
    call .moveCow
    ld ix,_cows+8
    call .moveCow
    jp DrawWorld
.moveCow:
    ld a,(ix+0)
    or a
    ret z
    ld a,(ix+2)
    add a,8
    ld (ix+2),a
    cp 161
    ret c
    ld (ix+0),0
    ret

UpdateCows:
    ld a,(_driveStarted)
    or a
    ret z
    ld ix,_cows
    call .walk
    ld ix,_cows+8
    call .walk
    ; Parked cows appear along the road, away from the destination courtyard.
    ld a,(_mapRow)
    cp 20
    ret c
    ; Cows enter at the top edge of the scrolling playfield, Y=16.
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld de,WorldMap
    add hl,de
    ld a,(hl)
    cp 145
    ret z
    ld a,(_spawnClock)
    dec a
    ld (_spawnClock),a
    ret nz
    call CowSpawnDelay
    ld (_spawnClock),a
    ld ix,_cows
    ld a,(ix+0)
    or a
    jr z,.spawnTest
    ld ix,_cows+8
    ld a,(ix+0)
    or a
    ret nz
.spawnTest:
    ; Check full cow rectangles, including a possible scroll-step boundary.
    ld a,(_cows)
    or a
    jr z,.other
    ld a,(_cows+2)
    cp 64
    ret c
.other:
    ld a,(_cows+8)
    or a
    jr z,.spawn
    ld a,(_cows+10)
    cp 64
    ret c
.spawn:
    ld (ix+0),1
    ld (ix+2),16
    ld (ix+4),0
    ld a,(_nextDirection)
    ld (ix+3),a
    xor 1
    ld (_nextDirection),a
    ; The 32px cow is centered on this part of the curved road.
    ld a,(_mapRow)
    add a,2 ; cow center at display Y=32, map row + 2
    push ix
    call RoadCenter
    pop ix
    sub 8 ; RoadCenter is the top-left of a 16px car, not a 32px cow
    ld (ix+1),a
    ret
.walk:
    ld a,(ix+0)
    or a
    ret z
    ; Parked cows stay at their world position until the driver honks.
    ld a,(ix+4)
    or a
    ret z
    ld b,2
    ld a,(ix+3)
    or a
    ld a,(ix+1)
    jr nz,.left
    add a,b
    cp 224
    jr nc,.exit
    jr .store
.left:
    sub b
    jr c,.exit
    or a
    jr z,.exit
.store:
    ld (ix+1),a
    ret
.exit:
    ld (ix+0),0
    ret

CheckHits:
    ld ix,_cows
    call .cow
    ld ix,_cows+8
    ; Do not process a second collision after game-over.
    ld a,(_state)
    cp 1
    ret nz
.cow:
    ld a,(ix+0)
    or a
    ret z
    ld a,(_invulnerable)
    or a
    ret nz
    ; Car reduced box 12x24, cow reduced box 24x24.
    ld a,(_carX)
    sub (ix+1)
    add a,10
    cp 36
    ret nc
    ld a,(_carY)
    sub (ix+2)
    add a,24
    cp 48
    ret nc
    jp LoseLife
AddTen:
    ld de,TenBCD
    jr AddScore
AddHundred:
    ld de,HundredBCD
AddScore:
    push ix
    ld hl,_scoreBCD_8Digits
    call SUM_BCD_8D
    pop ix
    ret

DrawHUD:
    ld hl,_scoreBCD_8Digits
    ld de,_score
    call BcdToString
    ld de,ScoreLabel
    ld bc,0001h
    call PutText
    ld de,_score
    ld bc,0007h
    call PutText
    ld hl,NAMTBL+25
    ld b,3
    ld a,(_lives)
    ld c,a
.hearts:
    ld a,c
    or a
    ld a,141 ; extinguished heart
    jr z,.heart
    dec c
    ld a,140 ; red heart
.heart:
    push bc
    push hl
    call WRTVRM
    pop hl
    pop bc
    inc hl
    inc hl
    djnz .hearts
    call DrawStageHUD
    call DrawCheeseHUD
    jp DrawFuel
DrawWorld:
    ; Keep two HUD rows fixed; copy only rows 2..23 from the finite route.
    ld a,(_mapRow)
    ld (_copyCount),a
    ld de,_screenBuffer+64
    ld b,22
.row:
    push bc
    push de
    ld a,(_copyCount)
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld bc,WorldMap
    add hl,bc
    pop de
    ld bc,32
    ldir
    ld a,(_copyCount)
    inc a
    ld (_copyCount),a
    pop bc
    djnz .row
    ld hl,_screenBuffer+64
    ld de,NAMTBL+64
    ld bc,704
    jp LDIRVM

; Each AppendSprite copies one four-byte attribute and its 16 color lines.
; D=y in display pixels (hardware stores y-1), E=x, A=pattern number / 4.
AppendSprite:
    push bc
    push de
    push hl
    push af
    ld hl,(_satPtr)
    ld a,d
    dec a
    ld (hl),a
    inc hl
    ld (hl),e
    inc hl
    pop af
    push af
    add a,a
    add a,a
    ld (hl),a
    inc hl
    ld (hl),0
    inc hl
    ld (_satPtr),hl
    pop af
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld bc,SpriteLineColors
    add hl,bc
    ld de,(_colorPtr)
    ld bc,16
    ldir
    ld (_colorPtr),de
    ld hl,_spriteCount
    inc (hl)
    pop hl
    pop de
    pop bc
    ret
HideSprites:
    ld hl,_satBuffer
    ld b,32
.loop:
    ld (hl),216
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    djnz .loop
    ld hl,_satBuffer
    ld de,SAT
    ld bc,128
    jp LDIRVM
BuildSprites:
    ; Clear all slots before rebuilding. Disabled slots use Y=216, never color 0.
    ld hl,_satBuffer
    ld b,32
.clear:
    ld (hl),216
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    ld (hl),0
    inc hl
    djnz .clear
    xor a
    ld (_spriteCount),a
    ld hl,_satBuffer
    ld (_satPtr),hl
    ld hl,_colorBuffer
    ld (_colorPtr),hl
    ld a,(_invulnerable)
    or a
    jr z,.car
    and 4
    jr nz,.dust
.car:
    ld a,(_carY)
    ld d,a
    ld a,(_carX)
    ld e,a
    ld a,CAR_PATTERN/4
    ld b,2
.half:
    push bc
    ld b,3
.layer:
    call AppendSprite
    inc a
    djnz .layer
    ld c,a
    ld a,d
    add a,16
    ld d,a
    ld a,c
    pop bc
    djnz .half
.dust:
    ld a,(_driveStarted)
    or a
    jr z,.cows
    ld a,(_carY)
    add a,32
    ld d,a
    ld a,(_carX)
    ld e,a
    ld a,(_tick)
    rrca
    rrca
    rrca
    and 3
    add a,DUST_PATTERN/4
    call AppendSprite
.cows:
    ld ix,_cows
    call DrawCow
    ld ix,_cows+8
    call DrawCow
    jp DrawCheese
DrawCow:
    ld a,(ix+0)
    or a
    ret z
    ; One fixed pose per direction, eight patterns per cow.
    ld a,(ix+3)
    add a,a
    add a,a
    add a,a
    add a,COW_PATTERN/4
    ld (_spriteBase),a
    ld a,(ix+2)
    ld (_drawY),a
    ld b,2
.row:
    push bc
    ld a,(ix+1)
    ld (_drawX),a
    ld b,2
.column:
    push bc
    ld a,(_drawY)
    ld d,a
    ld a,(_drawX)
    ld e,a
    ld a,(_spriteBase)
    call AppendSprite
    inc a
    call AppendSprite
    inc a
    ld (_spriteBase),a
    ld a,(_drawX)
    add a,16
    ld (_drawX),a
    pop bc
    djnz .column
    ld a,(_drawY)
    add a,16
    ld (_drawY),a
    pop bc
    djnz .row
    ret
UploadSprites:
    ld hl,_colorBuffer
    ld de,SPRCLR
    ld bc,512
    call LDIRVM
    ld hl,_satBuffer
    ld de,SAT
    ld bc,128
    jp LDIRVM

    include bonus.asm
    include campaign.asm
    include cheese.asm
    include route.asm
    include initRAM.asm
    include string.asm
    include math.asm
    include sfx.inc
    include music.asm
    include title.asm
TitleText: db "SEBOLLAS",0
SubtitleText: db "AVENTURA NA FAZENDA",0
PlayText: db "PLAY",0
BlankPlay: db "    ",0
GameOverText: db "GAME OVER",0
ArrivalText: db "CHEGAMOS!",0
CheeseLabel: db "QUEIJOS ",0
GaugeEmpty: db "E",0
GaugeFull: db "F",0
NeedleOffsets: db 0,1,2,2,3,4,5,6,6,7
FuelLabel: db "GAS",0
ScoreLabel: db "SCORE",0
MSX2Message: db "SEBOLLAS REQUER MSX2",13,10,0
TenBCD: db 0,0,0,010h
HundredBCD: db 0,0,1,0
CodeEnd:
    ASSERT CodeEnd < 8000h
TilePatterns: incbin "resources/generated/patterns.bin"
TileColors: incbin "resources/generated/colors.bin"
WorldMap: incbin "resources/generated/world.bin"
RoadCenters: incbin "resources/generated/road_centers.bin"
SpritePatterns: incbin "resources/generated/sprites.bin"
SpriteLineColors: incbin "resources/generated/sprite_colors.bin"
GamePalette: incbin "resources/generated/palette0.bin"
StagePalette1: incbin "resources/generated/palette1.bin"
StagePalette2: incbin "resources/generated/palette2.bin"
GameDataEnd:
    ASSERT GameDataEnd <= 0C000h
    defs 0C000h-$,0FFh
    ; Bank 2 is switched into 8000-BFFF only for the title screen.
    disp 8000h
TitlePalette: incbin "resources/generated/title_palette.bin"
TitlePlayOn: incbin "resources/generated/title_play.bin"
TitleBitmapRLE: incbin "resources/generated/title.rle"
TitleBankEnd:
    ASSERT TitleBankEnd <= 0C000h
    defs 0C000h-$,0FFh
    ent
    org 0
    defs 4000h,0FFh ; unused bank 3, power-of-two 64K cartridge
    ASSERT $ == 4000h
