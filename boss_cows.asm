; Road-sized 32x32 cows cross separate lanes in the cheese arena.
InitBossCows:
    ld a,30
    ld (_cows+4),a
    ld a,100
    ld (_cows+12),a
    ld a,112
    ld (_cows+2),a
    ld a,152
    ld (_cows+10),a
    xor a
    ld (_cows+3),a
    inc a
    ld (_cows+11),a
    ld hl,SpritePatterns+COW_PATTERN*8
    ld de,SPTPAT+COW_PATTERN*8
    ld bc,512
    jp LDIRVM

UpdateBossCows:
    ld a,(_tick)
    and 1
    ret nz
    ld ix,_cows
    call .cow
    ld ix,_cows+8
.cow:
    ld a,(ix+0)
    or a
    jr nz,.move
    ld a,(ix+4)
    or a
    jr z,.spawn
    dec (ix+4)
    ret
.spawn:
    ld (ix+0),1
    ld (ix+4),0
    ld (ix+5),0
    ld (ix+6),0
    ld a,(ix+3)
    or a
    ld a,0
    jr z,.save
    ld a,224
    jr .save
.move:
    ld b,1
    ld a,(ix+4)
    or a
    jr z,.direction
    inc b ; a honk sends the cow off faster
.direction:
    ld a,(ix+3)
    or a
    ld a,(ix+1)
    jr nz,.left
    add a,b
    cp 225
    jr nc,.exit
    jr .save
.left:
    sub b
    jr c,.exit
.save:
    ld (ix+1),a
    ret
.exit:
    ld (ix+0),0
    ld (ix+6),0
    ld (ix+4),100
    ret

DrawBossCows:
    ld a,(_stage)
    cp 3
    ret nz
    ld ix,_cows
    call DrawBossCow
    ld ix,_cows+8
DrawBossCow:
    ld (ix+6),0
    ld a,(ix+0)
    or a
    ret z
    ; Reserve eight slots and four layers on every covered scanline.
    ; Hidden cows cannot collide with the car.
    ld a,(_spriteCount)
    cp 25
    ret nc
    ld a,(ix+2)
    ld (_budgetY),a
    ld a,32
    ld (_budgetLines),a
.line:
    ld a,(_budgetY)
    ld d,a
    ld e,0
    ld a,(_spriteCount)
    or a
    jr z,.nextLine
    ld b,a
    ld hl,_satBuffer
.sprite:
    ld a,d
    sub (hl)
    dec a ; attributes store Y-1
    cp 16
    jr nc,.nextSprite
    inc e
    ld a,e
    cp 5
    ret nc
.nextSprite:
    inc hl
    inc hl
    inc hl
    inc hl
    djnz .sprite
.nextLine:
    ld hl,_budgetY
    inc (hl)
    ld hl,_budgetLines
    dec (hl)
    jr nz,.line
    ld (ix+6),1
    jp DrawCow
