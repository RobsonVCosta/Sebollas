; Typing 1914 on the title reveals seven horizontal chapter shortcuts.
ClearTitleKeys:
    call CHSNS
    ret z
    call CHGET
    jr ClearTitleKeys

UpdateTitleInput:
    ld a,(_secretMenu)
    or a
    jp nz,UpdateSecretSelection
    call UpdateSecretCode
    ld a,(_secretMenu)
    or a
    ret nz
    jp UpdateTitleSelection

UpdateSecretCode:
    call CHSNS
    ret z
    call CHGET
AcceptSecretCharacter:
    ld b,a
    ld a,(_secretCodePos)
    ld e,a
    ld d,0
    ld hl,SecretCode
    add hl,de
    ld a,b
    cp (hl)
    jr z,.match
    cp '1'
    ld a,0
    jr nz,.save
    inc a ; allow a new sequence to start on a mismatched 1
.save:
    ld (_secretCodePos),a
    ret
.match:
    ld a,e
    inc a
    cp 4
    jr c,.save
    xor a
    ld (_secretCodePos),a
    ld (_secretChoice),a
    ld (_menuMoveHeld),a
    ld (_startArmed),a
    inc a
    ld (_secretMenu),a
    ld a,(_state)
    or a
    jr nz,.draw
    call DrawTitleMenu
.draw:
    jp DrawSecretMenu

UpdateSecretSelection:
    xor a
    call GTSTCK
    or a
    jr nz,.pressed
    ld (_menuMoveHeld),a
    ret
.pressed:
    ld b,a
    ld a,(_menuMoveHeld)
    or a
    ret nz
    ld a,b
    cp 3
    jr z,.right
    cp 7
    ret nz
    ld a,(_secretChoice)
    or a
    jr nz,.left
    ld a,7
.left:
    dec a
    jr .select
.right:
    ld a,(_secretChoice)
    inc a
    cp 7
    jr c,.select
    xor a
.select:
    ld (_secretChoice),a
    ld a,1
    ld (_menuMoveHeld),a
    jp DrawSecretMenu

DrawSecretMenu:
    ld hl,174*128+32
    ld b,20
.panelRow:
    push bc
    push hl
    ld bc,60
    xor a
    call FILVRM
    pop hl
    ld de,128
    add hl,de
    pop bc
    djnz .panelRow
    xor a
    ld (_secretDrawIndex),a
    ld hl,180*128+36 ; x=72, y=180 in SCREEN 5
    ld (_secretDrawDest),hl
.digit:
    ld a,(_secretDrawIndex)
    ld e,a
    ld d,0
    ld hl,SecretDigits
    add hl,de
    add hl,de
    add hl,de
    add hl,de
    add hl,de
    add hl,de
    add hl,de
    add hl,de
    push hl
    pop ix
    ld a,(_secretChoice)
    cp e
    ld a,15
    jr nz,.ink
    ld a,1 ; title palette's gold, against white unselected digits
.ink:
    ld (_secretInk),a
    ld de,(_secretDrawDest)
    ld b,8
.row:
    push bc
    push de
    ld d,(ix+0)
    inc ix
    ld hl,_screenBuffer
    ld a,(_secretInk)
    ld c,a
    ld b,4
.pair:
    xor a
    sla d
    jr nc,.high
    or c
.high:
    rlca
    rlca
    rlca
    rlca
    ld e,a
    xor a
    sla d
    jr nc,.low
    or c
.low:
    or e
    ld (hl),a
    inc hl
    djnz .pair
    pop de
    push de
    ld hl,_screenBuffer
    ld bc,4
    call LDIRVM
    pop hl
    ld de,128
    add hl,de
    ex de,hl
    pop bc
    djnz .row
    ld hl,(_secretDrawDest)
    ld de,8
    add hl,de
    ld (_secretDrawDest),hl
    ld hl,_secretDrawIndex
    inc (hl)
    ld a,(hl)
    cp 7
    jp c,.digit
    ret

LaunchSecretStage:
    ld a,(_secretChoice)
    or a
    jp z,ResetGame
    ; BeginStage supplies the same clean RAM, route and saved checkpoint as
    ; normal play, including five lives and a full fuel/hunger bar.
    push af
    call InitSound
    call StopMusic
    ld a,5
    ld (_lives),a
    xor a
    ld (_cheeseCount),a
    ld (_caneTotal),a
    ld (_caneHundred),a
    ld hl,_scoreBCD_8Digits
    ld b,4
.score:
    ld (hl),a
    inc hl
    djnz .score
    pop af
    push af
    cp 3
    ld a,1
    jr c,.stage
    pop af
    push af
    cp 3
    ld a,2
    jr z,.stage
    ld a,3
.stage:
    ld (_stage),a
    call BeginStage
    pop af
    cp 2
    jp z,BeginCaneChallenge
    cp 5
    jp z,BeginBoss
    cp 6
    jp z,BeginEndingArt
    ret

SecretCode: db "1914"
SecretDigits:
    db 018h,038h,018h,018h,018h,018h,03Ch,0
    db 03Ch,066h,006h,00Ch,018h,030h,07Eh,0
    db 03Ch,066h,006h,01Ch,006h,066h,03Ch,0
    db 00Ch,01Ch,03Ch,06Ch,07Eh,00Ch,00Ch,0
    db 07Eh,060h,07Ch,006h,006h,066h,03Ch,0
    db 01Ch,030h,060h,07Ch,066h,066h,03Ch,0
    db 07Eh,006h,00Ch,018h,030h,030h,030h,0
