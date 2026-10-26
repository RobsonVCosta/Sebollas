# Play every event through the real Z80 player, checking the three PSG channels
# on every tick, the 16-bit ROM pointer, bank restoration and permanent silence after the last note.
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
set events {}
for {set i 0} {$i<[llength $bytes]} {incr i 7} {
    lappend events [list \
        [expr {[lindex $bytes $i]+256*[lindex $bytes [expr {$i+1}]]}] \
        [expr {[lindex $bytes [expr {$i+2}]]+256*[lindex $bytes [expr {$i+3}]]}] \
        [expr {[lindex $bytes [expr {$i+4}]]+256*[lindex $bytes [expr {$i+5}]]}] \
        [lindex $bytes [expr {$i+6}]]]
}
set event 0
set clock [lindex [lindex $events 0] 3]
set ticks 0
proc rd {address} {debug read memory $address}
proc finish {message} {
    set hz [expr {[rd 0xC003] ? 60 : 50}]
    set f [open resources/generated/going-home-$hz.txt w]
    puts $f $message
    close $f
    exit
}
proc run_tick {} {
    reg IFF 0
    reg SP 0xCFEE
    debug write memory 0xCFEE 0xF0
    debug write memory 0xCFEF 0xCF
    reg PC $::sym(UpdateSound)
    debug cont
}
proc check_tick {} {
    if {$::event==[llength $::events]} {
        foreach register {8 9 10} {
            if {[debug read {PSG regs} $register]!=0} {finish "FAIL song restarted after its end"; return}
        }
        if {[rd 0xC0E5]+256*[rd 0xC0E6]!=$::sym(GoingHomeNotesEnd)} {finish "FAIL end pointer lost"; return}
        incr ::silent_ticks
        if {$::silent_ticks==300} {finish "PASS $::ticks music ticks, three PSG voices, permanent end and 300 silent ticks"; return}
        run_tick
        return
    }
    if {[catch {
        set expected [lindex $::events $::event]
        foreach channel {0 1 2} volume {10 6 9} {
            set tone [lindex $expected $channel]
            set actual [debug read {PSG regs} [expr {8+$channel}]]
            if {$actual!=($tone ? $volume : 0)} {error "channel $channel volume $actual"}
            if {$tone} {
                set actual [expr {[debug read {PSG regs} [expr {2*$channel}]]+256*[debug read {PSG regs} [expr {2*$channel+1}]]}]
                if {$actual!=$tone} {error "channel $channel tone $actual != $tone"}
            }
        }
        if {[rd 0xC05C]!=$::clock} {error "clock [rd 0xC05C] != $::clock"}
        set next [expr {$::sym(GoingHomeNotes)+($::event+1)*7}]
        if {[rd 0xC0E5]+256*[rd 0xC0E6]!=$next} {error "event pointer"}
        if {[debug read_block memory 0xA000 16] ne $::game_bank} {error "game bank not restored"}
    } message]} {finish "FAIL tick $::ticks event $::event: $message"; return}
    incr ::ticks
    incr ::clock -1
    if {$::clock==0} {
        incr ::event
        if {$::event<[llength $::events]} {set ::clock [lindex [lindex $::events $::event] 3]}
    }
    run_tick
}
set silent_ticks 0
after time 6 {
    # Enter while the CPU is executing, rather than while MainLoop is halted.
    set ::bootbp [debug set_bp $::sym(MainLoop.tick) {} {
    debug remove_bp $::bootbp
    foreach {address value} {0xC000 6 0xC060 3 0xC0CB 0 0xC05C 0 0xC01C 0 0xC01D 0 0xC01E 0 0xC059 0 0xC05A 0} {
        debug write memory $address $value
    }
    debug write memory 0x7800 3
    set ::game_bank [debug read_block memory 0xA000 16]
    debug write {PSG regs} 7 0xB8
    debug set_bp 0xCFF0 {} {check_tick}
    run_tick
    }]
}
set power true
