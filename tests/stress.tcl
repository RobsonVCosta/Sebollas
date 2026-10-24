# Long live-loop test: real keyboard input, shooting and all 192 scanlines.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set samples 0
set maximum 0
set bad 0
proc sample_frame {} {
    if {[debug read memory 0xC000]!=1} {return}
    incr ::samples
    # Keep the run alive while exercising real collision and invulnerability code.
    debug write memory 0xC006 3
    set counts [lrepeat 192 0]
    for {set s 0} {$s<32} {incr s} {
        set y [debug read VRAM [expr {0x1e00+$s*4}]]
        if {$y==216} {break}
        incr y
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {
            if {$line<0} {continue}
            lset counts $line [expr {[lindex $counts $line]+1}]
        }
    }
    set peak [lindex [lsort -integer $counts] end]
    if {$peak>$::maximum} {set ::maximum $peak}
    if {$peak>8} {incr ::bad}
    if {$::samples%32==0} {
        keymatrixup 8 254
        set masks {32 160 128 192 64 80 16 48 0}
        keymatrixdown 8 [expr {1|[lindex $masks [expr {($::samples/32)%9}]]}]
    }
}
after time 6 {keymatrixdown 8 1}
after time 6.1 {keymatrixup 8 1; debug set_bp $::sym(MainLoop) {} {sample_frame}}
after time 36 {
    set hz [expr {[debug read memory 0xC003] ? 60 : 50}]
    set f [open "resources/generated/stress-$hz.txt" w]
    puts $f "Samples=$::samples; maximum sprites/scanline=$::maximum; overflow frames=$::bad"
    close $f
    exit
}
set power true
