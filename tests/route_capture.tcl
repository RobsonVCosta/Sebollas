# Capture stationary scenes using the real ROM's drawing routines and V9938.
set throttle on
set maxframeskip 0
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
proc scene {row x y fuel filling {arrived 0}} {
    foreach {addr val} [list 0xC000 1 0xC004 $x 0xC005 $y 0xC006 3 0xC007 0 0xC017 $row 0xC020 0 0xC028 0 0xC04E $fuel 0xC050 $filling 0xC053 0 0xC058 0 0xC060 1 0xC061 1] {
        debug write memory $addr $val
    }
    # A RAM trampoline calls ROM routines, then HALTs with BIOS IRQs enabled.
    set cursor 0xCFC0
    set routines {SetupGameVideo DrawWorld DrawHUD BuildSprites UploadSprites}
    if {$arrived} {
        debug write memory 0xC000 1
        lappend routines CompleteStage
    }
    foreach name $routines {
        foreach byte [list 205 [expr {$::sym($name)&255}] [expr {$::sym($name)>>8}]] {
            debug write memory $cursor $byte
            incr cursor
        }
    }
    foreach byte {195 240 207} {debug write memory $cursor $byte; incr cursor}
    foreach {addr val} {0xCFF0 118 0xCFF1 24 0xCFF2 253} {debug write memory $addr $val}
    reg SP 0xCF80
    reg PC 0xCFC0
}
after time 7 {scene 93 168 128 75 1}
after time 7.6 {screenshot -raw previews/posto-openmsx-raw.png}
after time 8 {
    scene 76 120 112 60 0
    foreach {addr val} {0xC053 1 0xC054 144 0xC055 96 0xC056 0} {debug write memory $addr $val}
}
after time 8.6 {screenshot -raw previews/ponte-openmsx-raw.png}
after time 9 {scene 0 120 80 40 0 1}
after time 9.6 {screenshot -raw previews/chegada-openmsx-raw.png}
after time 10 {
    scene 100 128 128 12 0
    foreach {addr val} {0xC020 1 0xC021 80 0xC022 48 0xC023 0 0xC053 1 0xC054 152 0xC055 80 0xC056 0 0xC058 3} {
        debug write memory $addr $val
    }
    debug write memory 0xC021 [expr {[debug read memory [expr {$::sym(RoadCenters)+106}]]-8}]
}
after time 10.6 {screenshot -raw previews/queijos-openmsx-raw.png}
after time 11 {exit}
set power true
