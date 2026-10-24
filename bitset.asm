            ; Faz shift left E vezes (1 << bit)
            ;Entrada: E -> quanta shift Left a ser feita
            ;Saída:   B é o resultado. Ex. E = 2, saída B = %00000100
ShiftLeft:           
            ld   a, e
            ld   b, 1
.shl:       cp   0
            jr   z, .done
            sla  b
            dec  a
            jr   .shl
.done
            ret