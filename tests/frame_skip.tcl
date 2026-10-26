# Inject late-frame measurements into a live cheese fight. Verify actual VRAM
# writes, input, music and the three-skipped-frame limit across complete ticks.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set frames 0
set writes 0
set skipped 0
set rendered 0
set hud_deferred 0
set previous_skip 0
set previous_clock 0
set max_skip 0
proc rd {address} {debug read memory $address}
proc result {message} {
    set hz [expr {[rd 0xC003] ? 60 : 50}]
    set f [open resources/generated/frame-skip-$hz.txt w]
    puts $f $message
    close $f
    exit
}
proc before_tick {} {
    if {$::frames} {
        if {$::previous_skip} {
            if {$::writes!=0} {result "FAIL skipped frame wrote $::writes VRAM bytes"; return}
            incr ::skipped
            if {[rd 0xC0F4]} {incr ::hud_deferred}
        } else {
            if {$::writes<640} {result "FAIL rendered frame missed sprite upload"; return}
            incr ::rendered
            if {[rd 0xC0F4]} {result "FAIL deferred HUD not flushed"; return}
        }
    }
    if {$::frames==32} {
        if {[rd 0xC004]!=184 || !$::skipped || !$::rendered || !$::hud_deferred || $::max_skip!=3} {
            result "FAIL input or adaptive render coverage"; return
        }
        result "PASS $::rendered rendered/$::skipped skipped ticks; maximum three consecutive skips; VRAM omitted, HUD flushed, controls and music continued"
        return
    }
    # Model a missed physical frame, without changing simulation or sound RAM.
    debug write memory 0xC0F2 [expr {([rd 0xFC9E]-3)&255}]
    debug write memory 0xC04E 100
    debug write memory 0xC007 100
    set ::writes 0
}
proc after_sound {} {
    set skip [rd 0xC0F1]
    if {$skip>3 || ($skip && $skip!=$::previous_skip+1)} {result "FAIL skip streak exceeded limit or lost count"; return}
    if {$skip>$::max_skip} {set ::max_skip $skip}
    set expected [expr {$::previous_clock>1 ? $::previous_clock-1 : 6}]
    if {[rd 0xC05C]!=$expected} {result "FAIL music clock paused"; return}
    set ::previous_clock $expected
    set ::previous_skip $skip
    incr ::frames
}
after time 6 {
    set ::bootbp [debug set_bp $::sym(MainLoop.tick) {} {
        debug remove_bp $::bootbp
        debug write memory 0xC0EC 5
        set cursor 0xCF00
        foreach byte [list 205 [expr {$::sym(LaunchSecretStage)&255}] [expr {$::sym(LaunchSecretStage)>>8}] 195 240 207] {
            debug write memory $cursor $byte; incr cursor
        }
        set ::readybp [debug set_bp 0xCFF0 {} {
            debug remove_bp $::readybp
            debug write memory 0xC061 1
            debug write memory 0xC065 3
            keymatrixdown 8 128
            debug set_watchpoint write_io 0x98 {} {incr ::writes}
            debug set_bp $::sym(MainLoop.tick) {} {before_tick}
            debug set_bp [expr {$::sym(MainLoop.tick)+10}] {} {after_sound}
            reg SP 0xF380
            reg IFF 1
            reg PC $::sym(MainLoop)
            debug cont
        }]
        reg SP 0xCE80
        reg PC 0xCF00
        debug cont
    }]
}
after time 15 {result "FAIL timeout"}
set power true
