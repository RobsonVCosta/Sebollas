# Start at the cheese boss's completed escape, then let the actual main loop
# run the bonus, both illustrations, bus scene and credits without intervention.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set f [open resources/generated/going_home.bin rb]
fconfigure $f -translation binary
binary scan [read $f] cu* bytes
close $f
set event 0
set clock [lindex $bytes 6]
set music_ticks 0
set visited {}
proc rd {address} {debug read memory $address}
proc result {message} {
    set hz [expr {[rd 0xC003] ? 60 : 50}]
    set f [open resources/generated/going-home-sequence-$hz.txt w]
    puts $f $message
    close $f
    exit
}
proc observe_ending {} {
    set state [rd 0xC000]
    if {$state==4} {return}
    if {[lsearch -exact $::visited $state]<0} {lappend ::visited $state}
    if {$state==7 && [rd 0xC0CB]!=2 && !$::music_ticks} {return}
    if {[catch {
        if {[rd 0xC0CB]!=2} {error "ending mode lost in state $state"}
        if {[rd 0xC05C]!=$::clock} {error "score restarted or skipped in state $state"}
        foreach address {0xC0CC 0xC0E7 0xC05D} offset {0 2 4} {
            set index [expr {$::event*7+$offset}]
            set tone [expr {[lindex $::bytes $index]+256*[lindex $::bytes [expr {$index+1}]]}]
            if {[rd $address]+256*[rd [expr {$address+1}]]!=$tone} {error "wrong voice in state $state"}
        }
    } message]} {result "FAIL $message"; return}
    incr ::music_ticks
    incr ::clock -1
    if {$::clock==0} {
        set ::event [expr {($::event+1)%([llength $::bytes]/7)}]
        set ::clock [lindex $::bytes [expr {$::event*7+6}]]
    }
    if {$state==6 && [rd 0xC0CA]} {
        if {$::visited ne {7 8 9 5 6}} {result "FAIL states $::visited"; return}
        result "PASS victory -> bonus -> illustrations -> bus -> credits; $::music_ticks continuous music ticks"
    }
}
after time 6 {
    set ::bootbp [debug set_bp $::sym(MainLoop.tick) {} {
        debug remove_bp $::bootbp
        debug write memory 0xC060 3
        set cursor 0xCF00
        foreach name {SetupGameVideo BeginBoss} {
            foreach byte [list 205 [expr {$::sym($name)&255}] [expr {$::sym($name)>>8}]] {
                debug write memory $cursor $byte; incr cursor
            }
        }
        foreach byte {195 240 207} {debug write memory $cursor $byte; incr cursor}
        set ::readybp [debug set_bp 0xCFF0 {} {
            debug remove_bp $::readybp
            foreach {address value} {0xC061 1 0xC065 0 0xC090 2 0xC066 238 0xC058 2} {debug write memory $address $value}
            debug set_bp $::sym(MainLoop.tick) {} {observe_ending}
            reg IFF 1
            reg SP 0xF380
            reg PC $::sym(MainLoop)
            debug cont
        }]
        reg SP 0xCE80
        reg PC 0xCF00
        debug cont
    }]
}
after time 90 {result "FAIL ending timed out in state [rd 0xC000]"}
set power true
