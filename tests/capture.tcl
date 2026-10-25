# Visual smoke test: live title -> PLAY -> gameplay -> third collision -> gameover.
set renderer SDL
set throttle on
set maxframeskip 0
set sound_driver null
set save_settings_on_exit false
# Keep physical keyboard events from changing the scene during automation.
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set want_start false
set want_drive false
proc capture_input_guard {} {
    keymatrixup 8 255
    keymatrixup 7 255
    set state [debug read memory 0xC000]
    if {$state==1} {
        set ::want_start false
        if {$::want_drive} {keymatrixdown 8 32; set ::want_drive false}
        return
    }
    if {$state==0 && $::want_start} {
        debug write memory 0xC01A 1
        keymatrixdown 8 1
    } else {
        debug write memory 0xC01A 0
    }
}
debug set_bp $sym(MainLoop.tick) {} {capture_input_guard}
proc savebin {name data} {
    set f [open $name wb]
    fconfigure $f -translation binary
    puts -nonewline $f $data
    close $f
}
after time 7.62 {
    screenshot -raw previews/abertura-openmsx-raw.png
    savebin resources/generated/capture-title-vram.bin [debug read_block VRAM 0 27136]
    savebin resources/generated/capture-title-palette.bin [debug read_block {VDP palette} 0 32]
}
after time 8 {set ::want_start true}
after time 8.4 {set ::want_drive true}
after time 8.1 {keymatrixup 8 1}
after time 18 {
    screenshot -raw previews/gameplay-openmsx-raw.png
    savebin resources/generated/capture-vram.bin [debug read_block VRAM 0 16384]
    savebin resources/generated/capture-palette.bin [debug read_block {VDP palette} 0 32]
}
after time 18.1 {
    debug write memory 0xC006 1
    debug write memory 0xC007 0
    foreach {a v} [list 0xC020 1 0xC021 [debug read memory 0xC004] 0xC022 [debug read memory 0xC005] 0xC023 0 0xC024 0] {
        debug write memory $a $v
    }
}
after time 19 {
    screenshot -raw previews/gameover-openmsx-raw.png
    set f [open resources/generated/capture.txt w]
    puts $f "Final state: [debug read memory 0xC000] (expected 2 = GAME OVER)"
    close $f
    exit
}
set power true
