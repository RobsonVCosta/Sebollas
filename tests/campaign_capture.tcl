# Fixed visual checkpoints, drawn by the ROM's own routines.
set throttle on
set maxframeskip 0
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
proc draw_checkpoint {routines} {
    set cursor 0xCEC0
    foreach name $routines {
        foreach byte [list 205 [expr {$::sym($name)&255}] [expr {$::sym($name)>>8}]] {
            debug write memory $cursor $byte; incr cursor
        }
    }
    set tail {195 240 207}
    if {$routines eq {ShowCredits}} {
        set tail [list 251 195 [expr {$::sym(MainLoop)&255}] [expr {$::sym(MainLoop)>>8}]]
    }
    foreach byte $tail {debug write memory $cursor $byte; incr cursor}
    foreach {addr val} {0xCFF0 118 0xCFF1 24 0xCFF2 253} {debug write memory $addr $val}
    reg SP 0xCE80
    reg PC 0xCEC0
}
after time 6 {
    debug write memory 0xC060 3
    debug write memory 0xC061 1
    draw_checkpoint {SetupGameVideo ApplyStagePalette BeginBoss}
}
after time 7 {
    foreach {addr val} {0xC065 8 0xC069 1 0xC06A 120 0xC06B 104} {debug write memory $addr $val}
    draw_checkpoint {DrawHUD BuildBossSprites UploadSprites}
}
after time 7.6 {screenshot -raw previews/garapa-openmsx-raw.png}
after time 8 {draw_checkpoint {BeginEnding}}
after time 9 {
    foreach {addr val} {0xC005 136 0xC06E 1 0xC071 25 0xC072 144 0xC073 160 0xC074 176 0xC001 8} {debug write memory $addr $val}
    draw_checkpoint {DrawBusRoad BuildEndingSprites UploadSprites}
}
after time 9.6 {screenshot -raw previews/onibus-openmsx-raw.png}
after time 10 {draw_checkpoint {ShowCredits}}
after time 18.6 {screenshot -raw previews/creditos-openmsx-raw.png}
after time 19 {
    foreach {addr val} {0xC060 1 0xC058 9 0xC008 0 0xC009 0 0xC00A 0x10 0xC00B 0} {debug write memory $addr $val}
    draw_checkpoint {SetupGameVideo ApplyStagePalette BeginCheeseBonus}
}
after time 19.6 {screenshot -raw previews/bonus-inicio-openmsx-raw.png}
after time 19.8 {reg IFF 1; reg SP 0xF380; reg PC $::sym(MainLoop)}
after time 20.7 {screenshot -raw previews/bonus-openmsx-raw.png}
after time 21 {exit}
set power true
