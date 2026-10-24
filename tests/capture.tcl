# Visual smoke test: live title -> PLAY -> gameplay -> third collision -> gameover.
set renderer SDL
set throttle on
set maxframeskip 0
set sound_driver null
set save_settings_on_exit false
proc savebin {name data} {
    set f [open $name wb]
    fconfigure $f -translation binary
    puts -nonewline $f $data
    close $f
}
after time 7.3 {screenshot -raw previews/abertura-openmsx-raw.png}
after time 8 {keymatrixdown 8 1}
after time 8.1 {keymatrixup 8 1}
after time 10 {
    screenshot -raw previews/gameplay-openmsx-raw.png
    savebin resources/generated/capture-vram.bin [debug read_block VRAM 0 16384]
    savebin resources/generated/capture-palette.bin [debug read_block {VDP palette} 0 32]
}
after time 10.1 {
    debug write memory 0xC006 1
    debug write memory 0xC007 0
    foreach {a v} [list 0xC020 1 0xC021 [debug read memory 0xC004] 0xC022 [debug read memory 0xC005] 0xC023 0 0xC024 0] {
        debug write memory $a $v
    }
}
after time 11 {
    screenshot -raw previews/gameover-openmsx-raw.png
    set f [open resources/generated/capture.txt w]
    puts $f "Final state: [debug read memory 0xC000] (expected 2 = GAME OVER)"
    close $f
    exit
}
set power true
