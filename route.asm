; Fuel and terrain follow the same map tiles that are drawn on screen.
; Car contact point is the middle of its rear axle (x+8,y+24).
CarTerrain:
    ld a,(_carY)
    add a,8
    srl a
    srl a
    srl a
    ld b,a
    ld a,(_mapRow)
    add a,b
    ld (_terrainRow),a
    ld l,a
    ld h,0
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    add hl,hl
    ld a,(_carX)
    add a,8
    srl a
    srl a
    srl a
    ld e,a
    ld d,0
    add hl,de
    ld de,WorldMap
    add hl,de
    ld a,(hl)
    ret

UpdateJourney:
    xor a
    ld (_refueling),a
    call CarTerrain
    cp 157
    jr nz,.consume
    ld a,(_carX)
    cp 160
    jr c,.consume
    ; Only the two marked forecourts supply fuel.
    ld a,(_terrainRow)
    sub 52
    cp 10
    jr c,.station
    ld a,(_terrainRow)
    sub 108
    cp 10
    jr nc,.consume
.station:
    ld a,(_fuel)
    cp 100
    jr nc,.consume
    inc a
    ld (_fuel),a
    ld a,1
    ld (_refueling),a
    xor a
    ld (_fuelClock),a
    ret
.consume:
    ld a,(_fuelClock)
    inc a
    cp 12
    jr c,.saveClock
    xor a
    ld (_fuelClock),a
    ld hl,_fuel
    ld a,(hl)
    or a
    jr z,.empty
    dec (hl)
    jr z,.empty
    jr .terrain
.saveClock:
    ld (_fuelClock),a
.terrain:
    call CarTerrain
    cp 130
    jr z,.arrival
    cp 131
    jr z,.arrival
    cp 146
    jr z,.arrival
    cp 157
    jr z,.arrival
    ld a,(_invulnerable)
    or a
    ret nz
    ld a,120
    ld (_carX),a
    jp LoseLife
.arrival:
    ld a,(_mapRow)
    cp 4
    ret nc
    ld a,(_carY)
    cp 89
    ret nc
    ld a,(_carX)
    cp 104
    ret c
    cp 137
    ret nc
    ld a,3
    ld (_state),a
    jp ShowGameOver
.empty:
    ld a,2
    ld (_state),a
    jp ShowGameOver

LoseLife:
    ld a,100
    ld (_invulnerable),a
    call SoundCrash
    ld hl,_lives
    dec (hl)
    ret nz
    ld a,2
    ld (_state),a
    jp ShowGameOver

DrawFuel:
    ld de,FuelLabel
    ld bc,0101h
    call PutText
    ld hl,NAMTBL+32+5
    ld a,(_fuel)
    ld c,a
    ld b,10
.bar:
    ld a,c
    or a
    ld a,143
    jr z,.tile
    ld a,(_fuel)
    cp 21
    ld a,142
    jr nc,.filled
    ld a,144
.filled:
    ld d,a
    ld a,c
    sub 10
    jr nc,.remaining
    xor a
.remaining:
    ld c,a
    ld a,d
.tile:
    push bc
    push hl
    call WRTVRM
    pop hl
    pop bc
    inc hl
    djnz .bar
    ld de,RouteLabel
    ld bc,0111h
    call PutText
    ld a,(_refueling)
    or a
    ret z
    ld de,RefuelLabel
    ld bc,0111h
    jp PutText
