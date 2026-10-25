# Full live-loop journey: steer to both stations, then into the destination.
# Cow damage is suppressed so this checks route/fuel independently of enemies.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set f [open resources/generated/road_centers0.bin rb]
fconfigure $f -translation binary
binary scan [read $f] cu* centers
close $f
set stops 0
set visited {}
set was_filling 0
set minimum_fuel 100
set finished false
proc drive_route {} {
    set state [debug read memory 0xC000]
    if {$state==11 && [debug read memory 0xC060]==0} {
        set ::finished true
        report_route
        return
    }
    if {$state!=1} {return}
    debug write memory 0xC007 100
    set fuel [debug read memory 0xC04E]
    if {$fuel<$::minimum_fuel} {set ::minimum_fuel $fuel}
    set filling [debug read memory 0xC050]
    if {$filling} {
        set station [expr {[debug read memory 0xC017]>80 ? 110 : 54}]
        dict set ::visited $station 1
        set ::stops [dict size $::visited]
    }
    set ::was_filling $filling
    if {![debug read memory 0xC061]} {keymatrixdown 8 128; return}
    set row [debug read memory 0xC017]
    set axle_row [expr {$row+17}]
    set target [expr {[lindex $::centers $axle_row]-8}]
    if {($axle_row<=117 && $axle_row>=108) || ($axle_row<=61 && $axle_row>=52)} {set target 168}
    set x [debug read memory 0xC004]
    keymatrixup 8 255
    if {$x<$target} {keymatrixdown 8 128}
    if {$x>$target} {keymatrixdown 8 16}
    if {$row==0} {
        keymatrixdown 8 32
        keymatrixup 8 144
        if {$x<120} {keymatrixdown 8 128}
        if {$x>120} {keymatrixdown 8 16}
    }
}
after time 6 {keymatrixdown 8 1}
after time 6.1 {keymatrixup 8 1; debug set_bp $::sym(MainLoop.tick) {} {drive_route}}
proc report_route {} {
    set state [debug read memory 0xC000]
    set hz [expr {[debug read memory 0xC003] ? 60 : 50}]
    set passed [expr {$::finished && $state==11 && $::stops==2 && $::minimum_fuel>0 && $::minimum_fuel<90}]
    set f [open "resources/generated/route-$hz.txt" w]
    puts $f "[expr {$passed ? {PASS} : {FAIL}}] fishing route: state=$state; refuel stops=$::stops; minimum fuel=$::minimum_fuel"
    close $f
    exit
}
after time 60 {report_route}
set power true
