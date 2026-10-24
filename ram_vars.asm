; Sebollas: all mutable state is explicitly initialized in C000-C6FF.
_state          equ 0C000h ; 0 title, 1 playing, 2 game over
_tick           equ 0C001h
_framePhase     equ 0C002h
_is60Hz         equ 0C003h
_carX           equ 0C004h
_carY           equ 0C005h
_lives          equ 0C006h
_invulnerable   equ 0C007h
_scoreBCD_8Digits equ 0C008h
_score          equ 0C00Ch ; eight ASCII digits and terminator
_fireWait       equ 0C015h
_scrollClock    equ 0C016h
_mapRow         equ 0C017h
_spawnClock     equ 0C018h
_nextDirection  equ 0C019h
_startArmed     equ 0C01Ah
_menuDirty      equ 0C01Bh
_effectTime     equ 0C01Ch ; three channel countdowns
_cows           equ 0C020h ; two records: active,x,y,direction,scared (8 byte stride)
_bullets        equ 0C030h ; two records: active,x,y (4 byte stride)
_spriteCount    equ 0C040h
_satPtr         equ 0C041h
_colorPtr       equ 0C043h
_direction      equ 0C045h
_spriteBase     equ 0C046h
_drawX          equ 0C047h
_drawY          equ 0C048h
_copyCount      equ 0C049h
_Print          equ 0C04Ah ; x,y,string pointer
_satBuffer      equ 0C100h ; 128 bytes
_colorBuffer    equ 0C180h ; 512 bytes
_screenBuffer   equ 0C400h ; 768 bytes
RAM_END         equ 0C700h
