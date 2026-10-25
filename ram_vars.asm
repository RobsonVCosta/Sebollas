; Sebollas: all mutable state is explicitly initialized in C000-C6FF.
_state          equ 0C000h ; 0 title, 1 road, 2 game over, 3 stage card, 4 boss, 5 ending, 6 credits, 7 bonus, 8/9 ending art, 10 stage intro
_tick           equ 0C001h
_framePhase     equ 0C002h
_is60Hz         equ 0C003h
_carX           equ 0C004h
_carY           equ 0C005h
_lives          equ 0C006h
_invulnerable   equ 0C007h
_scoreBCD_8Digits equ 0C008h
_score          equ 0C00Ch ; eight ASCII digits and terminator
_reserved15     equ 0C015h
_scrollClock    equ 0C016h
_mapRow         equ 0C017h
_spawnClock     equ 0C018h
_nextDirection  equ 0C019h
_startArmed     equ 0C01Ah
_menuDirty      equ 0C01Bh
_effectTime     equ 0C01Ch ; three channel countdowns
_cows           equ 0C020h ; two records: active,x,y,exitDirection,leaving (8 byte stride)
_reserved30     equ 0C030h ; third cow record in stage 3
_spriteCount    equ 0C040h
_satPtr         equ 0C041h
_colorPtr       equ 0C043h
_direction      equ 0C045h
_spriteBase     equ 0C046h
_drawX          equ 0C047h
_drawY          equ 0C048h
_copyCount      equ 0C049h
_Print          equ 0C04Ah ; x,y,string pointer
_fuel           equ 0C04Eh ; 0..100
_fuelClock      equ 0C04Fh ; one unit per 12 game ticks
_refueling      equ 0C050h ; freezes scrolling while tank fills
_terrainRow     equ 0C051h
_fuelAlertClock equ 0C052h
_cheese         equ 0C053h ; active
_cheeseX        equ 0C054h
_cheeseY        equ 0C055h
_cheesePhase    equ 0C056h
_cheeseClock    equ 0C057h
_cheeseCount    equ 0C058h ; packed BCD, 00..99
_hornPhase      equ 0C059h ; 0 idle, 1 short bi, 2 gap, 3 long biiii
_hornClock      equ 0C05Ah
_musicStep      equ 0C05Bh ; next note in the 32-event melody
_musicClock     equ 0C05Ch ; ticks remaining in this note
_musicPeriod    equ 0C05Dh ; current 16-bit PSG period, 0 = rest
_titleBlink     equ 0C05Fh
_stage          equ 0C060h
_driveStarted   equ 0C061h
_driveArmed     equ 0C062h
_stageTimer     equ 0C063h ; word
_bossHP         equ 0C065h
_bossX          equ 0C066h
_bossDirection  equ 0C067h
_throwClock     equ 0C068h
_caneActive     equ 0C069h
_caneX          equ 0C06Ah
_caneY          equ 0C06Bh
_caneTarget     equ 0C06Ch
_bossFlash      equ 0C06Dh
_endingPhase    equ 0C06Eh
_endingClock    equ 0C06Fh ; word
_busColumn      equ 0C071h
_runnerSmallX   equ 0C072h ; 255 waiting, 254 boarded, otherwise x
_runnerTallX    equ 0C073h
_runnerFatX     equ 0C074h
_creditNext     equ 0C075h ; word
_bonusBCD       equ 0C077h ; 4 packed BCD bytes, points converted this stage
_bonusText      equ 0C07Bh ; 8 ASCII digits and terminator
_bonusClock     equ 0C084h
_bonusDone      equ 0C085h
_bonusSoundStep equ 0C086h
_fuelAlertPitch equ 0C087h
_creditDest     equ 0C088h ; next VRAM cell; zero begins a new line
_creditClock    equ 0C08Ah
_roadMinX       equ 0C08Bh
_roadMaxX       equ 0C08Ch
_roadRow        equ 0C08Dh
_roadRows       equ 0C08Eh
_cowSerial      equ 0C08Fh
_bossDefeat     equ 0C090h ; 0 fight, 1 blinking, 2 escaping
_bossSprite     equ 0C091h ; x/y descriptor for the 32x32 reference sprite
_hornAge        equ 0C099h ; envelope/vibrato position within each horn note
_caneTotal      equ 0C09Ah ; collected canes during stage 1
_cowChaseStart  equ 0C09Bh ; BIOS-time origin of the five-second pursuit
_roadGarapaY    equ 0C09Dh
_caneHundred    equ 0C09Eh
_playerSprite   equ 0C0A0h
_budgetY        equ 0C0A8h
_budgetLines    equ 0C0A9h
WorldMap        equ 0D000h ; active route copied from ROM, safe below BIOS RAM
WorldMap1       equ WorldMap
WorldMap3       equ WorldMap
RoadCenters     equ 0E400h
RoadCenters1    equ RoadCenters
RoadCenters3    equ RoadCenters
RoadBounds      equ 0E4A0h
RoadBounds1     equ RoadBounds
RoadBounds3     equ RoadBounds
_herdLevel      equ 0C0ACh
_cowLaneMin     equ 0C0ADh
_cowLaneMax     equ 0C0AEh
_cowChaseStart2 equ 0C0B0h
_cowChaseStart3 equ 0C0B2h
_cowTimePtr     equ 0C0B4h
_satBuffer      equ 0C100h ; 128 bytes
_colorBuffer    equ 0C180h ; 512 bytes
_screenBuffer   equ 0C400h ; 768 bytes
RAM_END         equ 0C700h
