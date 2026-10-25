# Record the ROM's actual PSG output, isolated from music and road effects.
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
    soundlog start /tmp/sebollas-horn-msx.wav
    foreach {address value} {0xC000 3 0xC060 2 0xC063 255 0xC064 255 0xC059 0 0xC05A 0 0xC01C 0 0xC01D 0 0xC01E 0} {
        debug write memory $address $value
    }
    set cursor 0xCF00
    foreach name {InitSound StopMusic SoundHorn} {
        foreach byte [list 205 [expr {$::sym($name)&255}] [expr {$::sym($name)>>8}]] {
            debug write memory $cursor $byte; incr cursor
        }
    }
    foreach byte [list 251 195 [expr {$::sym(MainLoop)&255}] [expr {$::sym(MainLoop)>>8}]] {
        debug write memory $cursor $byte; incr cursor
    }
    reg SP 0xF380
    reg IFF 1
    reg PC 0xCF00
}
after time 7.1 {soundlog stop; exit}
set power true
