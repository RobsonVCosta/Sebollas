;-------------------------------------------
; ram_vars.asm
; Variáveis que residem em RAM
;-------------------------------------------
		
_shiftTileCount = 0C000h ; endereço absoluto em RAM
_shiftTile = _shiftTileCount + 1


;andamento
_music_time = _shiftTile + 2

;_NoteWaitList----------------------
;18 bytes, 6 bytes for each channel A, B, C
;Channel A
;2 bytes for time_finish
;2 bytes for music address
;2 bytes for music player position
;Channel B
;2 bytes for time_finish 
;2 bytes for  music address
;2 bytes for music player position
;Channel C
;2 bytes for time_finish 
;2 bytes for  music address
;2 bytes for music player position
_noteWaitList = _music_time + 1



_sprite_fuscaFront_attr = _noteWaitList + 18
_sprite_fuscaBack_attr = _sprite_fuscaFront_attr + 6
_sprite_2_attr = _sprite_fuscaBack_attr + 6
_sprite_3_attr = _sprite_2_attr + 6
_sprite_4_attr = _sprite_3_attr + 6

_score = _sprite_4_attr + 6	

_scoreBCD_8Digits = _score + 9
_somarBCD_8D = _scoreBCD_8Digits + 4 

		
;_sprite_1_attr: db 130, 100, 0, BLACK, 0   ;y, x, nPtrn, Color	, status: (0 enable, 1 disable)
;_sprite_2_attr: db 130, 100, 4, WHITE, 0, DELAY_BULLETS ;y, x, nPtrn, Color, status: (0 enable, 1 disable) , delay entre o proximo bullet
;_sprite_3_attr: db 130, 100, 4, RED, 0, DELAY_BULLETS

_currentKeys = _somarBCD_8D + 4
_previousKeys = _currentKeys + 12

_Print = _previousKeys + 12
;_Print:	ds 4 			; [db x][db y][dw msg]
; db 1         ; x
;db 1         ; y
; dw msg       ; ponteiro (little-endian: low, high)



