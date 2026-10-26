; At most three skipped sprite/HUD uploads between rendered gameplay ticks.
; JIFFY counts VBlanks, independently of the main loop's simulation counter.
UpdateFrameSkip:
    ld a,(JIFFY)
    ld c,a
    ld a,(_lastFrameJiffy)
    ld b,a
    ld a,c
    ld (_lastFrameJiffy),a
    sub b
    ld b,a
    ld a,(_state)
    ld c,a
    ld a,(_frameSkipState)
    cp c
    ld a,c
    ld (_frameSkipState),a
    jr nz,.draw ; scene changes always draw immediately
    cp 1
    jr z,.gameplay
    cp 4
    jr z,.gameplay
    cp 12
    jr nz,.draw
.gameplay:
    ld a,(_skipGraphics)
    cp 3
    jr nc,.draw ; the fourth consecutive gameplay tick must render
    ld c,2 ; PAL: two VBlanks mean a missed frame
    ld a,(_is60Hz)
    or a
    jr z,.compare
    ld a,(_framePhase)
    cp 1
    jr nz,.compare
    inc c ; NTSC's intentional sixth-frame omission is not an overrun
.compare:
    ld a,b
    cp c
    jr c,.draw
    ld a,(_skipGraphics)
    inc a
    ld (_skipGraphics),a
    ret
.draw:
    xor a
    ld (_skipGraphics),a
    ret

ResetFrameSkip:
    xor a
    ld (_skipGraphics),a
    ld (_hudDirty),a
    ld a,(JIFFY)
    ld (_lastFrameJiffy),a
    ld a,(_state)
    ld (_frameSkipState),a
    ret

; Preserve BC/DE/HL. A=1 only if this very scene is skipping its upload.
ShouldSkipGraphics:
    ld a,(_skipGraphics)
    or a
    ret z
    push hl
    ld a,(_state)
    ld hl,_frameSkipState
    cp (hl)
    pop hl
    ld a,0
    ret nz
    inc a
    ret
