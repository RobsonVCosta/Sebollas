# Record the actual ROM's two-voice PSG arrangement, with no gameplay effects.
set throttle off
set renderer none
set save_settings_on_exit false
set frequency 44100
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
after time 6 {
    foreach {address value} {0xC000 1 0xC059 0 0xC05A 0 0xC050 0 0xC01C 0 0xC01D 0 0xC01E 0} {
        debug write memory $address $value
    }
    set cursor 0xCF00
    foreach name {InitSound StopMusic} {
        foreach byte [list 205 [expr {$::sym($name)&255}] [expr {$::sym($name)>>8}]] {
            debug write memory $cursor $byte; incr cursor
        }
    }
    set loop $cursor
    foreach byte [list 118 205 [expr {$::sym(UpdateSound)&255}] [expr {$::sym(UpdateSound)>>8}] 195 [expr {$loop&255}] [expr {$loop>>8}]] {
        debug write memory $cursor $byte; incr cursor
    }
    reg SP 0xF380
    reg IFF 1
    reg PC 0xCF00
    soundlog start /tmp/sebollas-sultans-msx.wav
}
after time 29.5 {soundlog stop; exit}
set power true
