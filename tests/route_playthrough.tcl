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
set stops 0
set visited {}
set was_filling 0
set minimum_fuel 100
set finished false
proc drive_route {} {
    set state [debug read memory 0xC000]
    if {$state==3} {set ::finished true; return}
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
    set row [debug read memory 0xC017]
    set axle_row [expr {$row+17}]
    set target 120
    if {($axle_row<=124 && $axle_row>=108) || ($axle_row<=68 && $axle_row>=52)} {set target 168}
    set x [debug read memory 0xC004]
    keymatrixup 8 255
    if {$x<$target} {keymatrixdown 8 128}
    if {$x>$target} {keymatrixdown 8 16}
    if {$row==0} {keymatrixdown 8 32}
}
after time 6 {keymatrixdown 8 1}
after time 6.1 {keymatrixup 8 1; debug set_bp $::sym(MainLoop.tick) {} {drive_route}}
after time 75 {
    set state [debug read memory 0xC000]
    set hz [expr {[debug read memory 0xC003] ? 60 : 50}]
    set passed [expr {$::finished && $state==3 && $::stops==2 && $::minimum_fuel>0 && $::minimum_fuel<70}]
    set f [open "resources/generated/route-$hz.txt" w]
    puts $f "[expr {$passed ? {PASS} : {FAIL}}] journey: state=$state; refuel stops=$::stops; minimum fuel=$::minimum_fuel; row=[debug read memory 0xC017]; x=[debug read memory 0xC004]; y=[debug read memory 0xC005]"
    close $f
    exit
}
set power true
