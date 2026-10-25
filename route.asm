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
    call GetWorldMap
    add hl,de
    ld a,(hl)
    ret

UpdateJourney:
    ld a,(_driveStarted)
    or a
    ret z
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
    ld a,(_tick)
    and 3
    call z,SoundRefuel
    ret
.consume:
    ld a,(_fuelClock)
    inc a
    cp 6
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
    call ClampCarToRoad
    call CarTerrain
    cp 130
    jr z,.arrival
    cp 131
    jr z,.arrival
    cp 146
    jr z,.arrival
    cp 157
    jr z,.arrival
    ret
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
    jp CompleteStage
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

RoadCenter:
    ld e,a
    ld d,0
    call GetRoadCenters
    add hl,de
    ld a,(hl)
    ret

DrawFuel:
    ld de,FuelLabel
    ld bc,0101h
    call PutText
    ld de,GaugeEmpty
    ld bc,0105h
    call PutText
    ld de,GaugeFull
    ld bc,0110h
    call PutText
    ld hl,NAMTBL+32+6
    ld bc,10
    ld a,168
    call FILVRM
    ld a,(_fuel)
    cp 100
    jr c,.divide
    ld a,99
.divide:
    ld b,0
.tens:
    cp 10
    jr c,.offset
    sub 10
    inc b
    jr .tens
.offset:
    ld e,a
    ld d,0
    ld hl,NeedleOffsets
    add hl,de
    ld c,(hl)
    ld a,(_fuel)
    cp 21
    ld a,169
    jr nc,.needle
    ld a,177
.needle:
    add a,c
    push af
    ld e,b
    ld d,0
    ld hl,NAMTBL+32+6
    add hl,de
    pop af
    call WRTVRM
    ret

; Intersect the drivable span of every tile row covered by the 16x32 car.
; Driveways and station forecourts remain accessible; bridge rails are walls.
ClampCarToRoad:
    ld a,(_state)
    cp 4
    jp z,.arena
    cp 1
    ret nz
    xor a
    ld (_roadMinX),a
    ld a,240
    ld (_roadMaxX),a
    ld a,(_carY)
    and 7
    add a,31
    srl a
    srl a
    srl a
    inc a
    ld (_roadRows),a
    ld a,(_carY)
    srl a
    srl a
    srl a
    sub 2
    ld b,a
    ld a,(_mapRow)
    add a,b
    ld (_roadRow),a
.row:
    ld a,(_roadRow)
    ld l,a
    ld h,0
    add hl,hl
    push hl
    call GetRoadBounds
    pop de
    add hl,de
    ld d,(hl)
    inc hl
    ld e,(hl)
    ld a,(_roadMinX)
    cp d
    jr nc,.max
    ld a,d
    ld (_roadMinX),a
.max:
    ld b,e
    ld a,(_roadMaxX)
    cp b
    jr c,.advance
    ld a,b
    ld (_roadMaxX),a
.advance:
    ld hl,_roadRow
    inc (hl)
    ld hl,_roadRows
    dec (hl)
    jr nz,.row
    jr .clamp
.arena:
    ld a,64
    ld (_roadMinX),a
    ld a,176
    ld (_roadMaxX),a
.clamp:
    ld a,(_roadMinX)
    ld b,a
    ld a,(_carX)
    cp b
    jr nc,.upper
    ld a,b
.upper:
    ld b,a
    ld a,(_roadMaxX)
    cp b
    jr c,.save
    ld a,b
.save:
    ld (_carX),a
    ret

; Stage-specific maps share the same houses, stations and finite route length.
GetWorldMap:
    ld de,WorldMap1
    ld a,(_stage)
    cp 1
    ret z
    ld de,WorldMap3
    cp 3
    ret z
    ld de,WorldMap
    ret
GetRoadCenters:
    ld hl,RoadCenters1
    ld a,(_stage)
    cp 1
    ret z
    ld hl,RoadCenters3
    cp 3
    ret z
    ld hl,RoadCenters
    ret
GetRoadBounds:
    ld hl,RoadBounds1
    ld a,(_stage)
    cp 1
    ret z
    ld hl,RoadBounds3
    cp 3
    ret z
    ld hl,RoadBounds
    ret
