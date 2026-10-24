; -------------------------------------------------------
; MSX Z80 – Leitura de teclado com transições (press/hold/release)
; -------------------------------------------------------
;Uso
;   call ScanKeyboard          ; lê _currentKeys (12 linhas)
            ; --- EXEMPLO: verifica ESPAÇO (ex.: linha/bit a ajustar)
            ; D = linha, E = bit (0..7). Substitua pelos da tecla desejada.
;            ld   d, 6                  ; EXEMPLO: linha 6
;            ld   e, 0                  ; EXEMPLO: bit 0
;            call GetKeyState_DE        ; retorna em A: 0=up,1=just-press,2=held,3=just-release
            ; aqui você pode usar A (comparar, pular, etc.)

;            jp   MainLoop


; -------------------------------------------------------
; Buffers (12 linhas da matriz)
; _currentKeys é sobrescrito a cada varredura; _previousKeys guarda a anterior
; -------------------------------------------------------
;_currentKeys:    ds 12
;_previousKeys:   ds 12


ResetPreviousKeys:
            ; Inicializa buffers: prev = 0xFF (tudo solto)
            ld   hl, _previousKeys
            ld   b, 12
.init_prev: ld   (hl), 0xFF
            inc  hl
            djnz .init_prev
            ret


         

; -------------------------------------------------------
; ScanKeyboard
; Lê as 12 linhas (0..11) via SNSMAT -> _currentKeys[]
; e ao final copia _currentKeys para _previousKeys (para a próxima iteração).
; -------------------------------------------------------
ScanKeyboard:
            ;;debug
             ld de, 0xC070
             ;;
            ld   hl, _currentKeys
            ld   c, 0                  ; linha = 0..11
.read_row:  ld   a, c
            call SNSMAT                ; A = bitmap (0=pressionado)
            ld   (hl), a               ; guarda _currentKeys[linha]
            
            ;;debug
            push hl
           
            cpl 
            ld   (de), a
            inc de
            pop hl            
            ;;

            inc  hl
            inc  c
            ld   a, c
            cp   12
            jr   nz, .read_row

            ;;debug
            ;;force key press
            ; ld   hl, _currentKeys
            ; ld a, 0xBF
            ; ld (hl), a
            ret

SavePreviousKeys:            
            ; copia _currentKeys -> _previousKeys (12 bytes)
            ld   hl, _currentKeys
            ld   de, _previousKeys
            ld   bc, 12
            ldir
            ret

; -------------------------------------------------------
; GetKeyState
; ENTRADA: D = linha (0..11), E = bit (0..7)
; SAIDA:   A = estado da tecla:
;        0 = solta (idle)
;        1 = acabou de pressionar (onkeydown)
;        2 = mantida pressionada (onkeypress)
;        3 = acabou de soltar (onkeyup)
; Usa:    HL, A, B temporários
; -------------------------------------------------------
GetKeyState:           
            call ShiftLeft ;Entrada: E -> quanta shift Left a ser feita
                            ;Saída:   B é o resultado. Ex. E = 2, saída B = %00000100
.mask_ready:
            ; cur = _currentKeys[linha], prev = _previousKeys[linha]
            push de
            ld   a, d ;D é a linha
            ld   l, a
            ld   h, 0
            ld   de, _currentKeys
            add  hl, de
            ld   a, (hl)               ; A = cur_row_bits
            ld   c, a                  ; C = currentKey
            pop de
            ld   a, d
            ld   l, a
            ld   h, 0
            ld   de, _previousKeys
            add  hl, de
            ld   a, (hl)               ; A = prev_row_bits
            ld   h, a                  ; H = previousKey

            ;Verifica se current_is_down
            ld   a, c          ; A = currentKey
            cpl               ; A = NOT A. Invert bits já que SNSMAT carrega invertido. 0xFF = nenhuma tecla pressionada
            and  b             ; B = key que está sendo vefificada
            cp b ;Se A AND B == B, flag Z é ativada
            jr   z, .current_is_down     ; Z=1 se A AND B == B. O bit ativado em B está ativado em A
            ld   a, 0   ; current_is_not_down = 0         
            jr .verify_previous
.current_is_down:
            ld   a, 1     ; current_is_down = 1
.verify_previous
            ld   c, a    ; preserva resultado current_is_down em C

            ld   a, h    ; H = previousKey
            cpl          ; A = NOT A. Invert bits já que SNSMAT carrega invertido. 0xFF = nenhuma tecla pressionada
            and  b      ; Z=1 se A AND B == B. O bit a
            cp b ;Se A AND B == B, flag Z é ativada
            jr   z, .previous_is_down
            ld   a, 0    ; previous_is_not_down = 0 
            jr .conclusion
.previous_is_down:
            ld a, 1  ;; previous_is_down = 1
.conclusion
            ;c = current. 0 = idle, 1 = down
            ;a = previous.  0 = idle, 1 = down
            ;if C == 0 and A == 0 -> idle
            ;if C == 1 and A == 0 -> onkeydown (user presses a key)
            ;if C == 1 and A == 1 -> onkeypress (user is pressing a key)
            ;if C == 0 and A == 1 -> onkeyup (user releases a key)
            rr   c  ;C é deslocado (shift right) para o carry.
            rla     ;Faz shift Left de A e soma com o carry
            ; agora A = 0..3
            cp   0
            jr   z,.idle
            cp   1
            jr   z,.onkeyup
            cp   2
            jr   z,.onkeydown
            ; se chegou aqui, é 3
            jr   .onkeypress         

.idle:           
            jr   .done

.onkeydown:
           call SavePreviousKeys
           jr .done

.onkeypress:          
           jr .done
.onkeyup:
           call SavePreviousKeys
           jr .done

.done:
    ret



; IsKeyDown: lê apenas a tecla pedida
; ENtrada: DE, D = linha; E = Bit
; Saída: A=1 se pressionado, senão A=0
;Uso
;   ld  d, 1         ; linha
;    ld  e, 1          ; bit
;    call IsKeyDown ; A=1 se espaço pressionado, senão A=0
;    cp 1
;    jp z, .teclaPressionada

IsKeyDown:
    ld   a, d
    call SNSMAT          ; A = bits da linha (0 = down)
    ld   c, a            ; guarda linha lida em C

    ; gera máscara = 1 << E
    ld   a, e
    ld   b, 1
.mk: cp   0
    jr   z, .mask_ok
    sla  b
    dec  a
    jr   .mk
.mask_ok:

    ld   a, c            ; bits atuais da linha
    and  b               ; testa bit da tecla
    ld   a, 0            ; assume solta
    ret  nz              ; se bit=1 => solta (retorna 0)
    ld   a, 1            ; se bit=0 => pressionada
    ret


_0 equ 0x00
_1 equ 0x01
_2 equ 0x02
_3 equ 0x03
_4 equ 0x04
_5 equ 0x05
_6 equ 0x06
_7 equ 0x07   

_8 equ 0x10
_9 equ 0x11 ;CONFUNDE COM O Ç QUE TAMBÉM ACENDE ESSES BITS
;_CEDILHA equ 0x11 AND 0X60
_MINUS equ 0x12       
_EQUAL equ 0x13
_CONTRA_BARR equ 0x14
_COLCHETE_OPEN equ 0x15
_COLCHETE_CLOSE equ 0x16
_PONTE_VIRGULA equ 0x17

_ASPAS equ 0x20
_COMMA equ 0x22
_PERIOD equ 0x23
_DIVISAO equ 0x24
_CONTROL_RIGHT equ 0x25
_A equ 0x26
_B equ 0x27

_C equ 0x30
_D equ 0x31
_E equ 0x32
_F equ 0x33
_G equ 0x34
_H equ 0x35
_I equ 0x36
_J equ 0x37

_K equ 0x40
_L equ 0x41
_M equ 0x42
_N equ 0x43
_O equ 0x44
_P equ 0x45
_Q equ 0x46
_R equ 0x47

_S equ 0x50
_T equ 0x51
_U equ 0x52
_V equ 0x53
_W equ 0x54
_X equ 0x55
_Y equ 0x56
_Z equ 0x57

_SHIFT equ 0x60
_CONTROL_LEFT equ 0x61
_ALT_LEFT equ 0x62
_CAPSLOCK equ 0x63
_F1 equ 0x65
_F2 equ 0x66
_F3 equ 0x67

_F4 equ 0x70
_F5 equ 0x71
_ESC equ 0x72
_TAB equ 0x73
_F8 equ 0x74
_BACKSPACE equ 0x75
_F7 equ 0x76
_ENTER equ 0x77

_SPACE equ 0x80
_HOME equ 0x81
_INSERT equ 0x82
_DELETE equ 0x83
_CURSOR_LEFT equ 0x84
_CURSOR_UP equ 0x85
_CURSOR_DOWN equ 0x86
_CURSOR_RIGHT equ 0x87

_NUMPAD_MULTIPLY equ 0x90
_NUMPAD_PLUS equ 0x91
_NUMPAD_DIVISAO equ 0x92
_NUMPAD_0 equ 0x93
_NUMPAD_1 equ 0x94
_NUMPAD_2 equ 0x95
_NUMPAD_3 equ 0x96
_NUMPAD_4 equ 0x97

_NUMPAD_5 equ 0xA0
_NUMPAD_6 equ 0xA1
_NUMPAD_7 equ 0xA2
_NUMPAD_8 equ 0xA3

_NUMPAD_9 equ 0xA4
_NUMPAD_MINUS equ 0xA5
_NUMPAD_COMMA equ 0xA7




_teclas db _0,_1,_2,_3,_4,_5,_6,_7,_8,_9
 db _MINUS,_EQUAL,_CONTRA_BARR,_COLCHETE_OPEN,_COLCHETE_CLOSE
 db _PONTE_VIRGULA,   _ASPAS,_COMMA,_PERIOD,_DIVISAO
 db _CONTROL_RIGHT,_A,_B, _C,_D,_E,_F,_G,_H,_I,_J,_K,_L,_M,_N,_O
 db _P,_Q,_R,  _S,_T,_U,_V,_W,_X,_Y,_Z
 db _SHIFT,_CONTROL_LEFT,_ALT_LEFT,_CAPSLOCK
 db _F1,_F2,_F3,   _F4,_F5,_ESC,_TAB,_F8,_BACKSPACE,_F7
 db _ENTER,   _SPACE,_HOME,_INSERT,_DELETE,_CURSOR_LEFT
 db _CURSOR_UP,_CURSOR_DOWN,_CURSOR_RIGHT
 db _NUMPAD_MULTIPLY,_NUMPAD_PLUS,_NUMPAD_DIVISAO
 db _NUMPAD_0,_NUMPAD_1,_NUMPAD_2,_NUMPAD_3,_NUMPAD_4 
  db _NUMPAD_5,_NUMPAD_6,_NUMPAD_7,_NUMPAD_8,_NUMPAD_9
  db _NUMPAD_MINUS,_NUMPAD_COMMA