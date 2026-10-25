# Complete campaign using keyboard input only: no lives/fuel/HP/position cheats.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
set f [open resources/generated/road_centers.bin rb]
fconfigure $f -translation binary
binary scan [read $f] cu* centers
close $f
set visited {}
set stops {}
set cow_counts [dict create 1 0 2 0 3 0]
set last_active {0 0}
set previous_stage 0
set previous_hp 12
set boss_hits 0
set bonus_stages {}
set bonus_previous {}
set bonus_converted 0
set bonus_errors 0
proc current_score {} {
    scan [binary encode hex [debug read_block memory 0xC008 4]] %d value
    return $value
}
set art_ticks [dict create 8 0 9 0]
set art_order {}
set road_errors 0
set saw_ending false
set finished false
set samples 0
set worst 0
set overflow 0
proc campaign_drive {} {
    keymatrixup 8 255
    keymatrixup 7 255
    set state [debug read memory 0xC000]
    if {$state==1 || $state==4 || $state==5} {
        incr ::samples
        set counts [lrepeat 192 0]
        for {set slot 0} {$slot<32} {incr slot} {
            set y [debug read VRAM [expr {0x1e00+$slot*4}]]
            if {$y==216} {break}
            incr y
            for {set line $y} {$line<$y+16 && $line<192} {incr line} {
                lset counts $line [expr {[lindex $counts $line]+1}]
            }
        }
        set peak [lindex [lsort -integer $counts] end]
        if {$peak>$::worst} {set ::worst $peak}
        if {$peak>8} {incr ::overflow}
    }
    if {$state==1} {
        set x [debug read memory 0xC004]
        set y [debug read memory 0xC005]
        set maprow [debug read memory 0xC017]
        for {set r [expr {$maprow+$y/8-2}]} {$r<=$maprow+($y+31)/8-2} {incr r} {
            for {set col [expr {$x/8}]} {$col<=($x+15)/8} {incr col} {
                if {[debug read memory [expr {$::sym(WorldMap)+$r*32+$col}]] ni {130 131 146 157}} {incr ::road_errors}
            }
        }
        set stage [debug read memory 0xC060]
        dict set ::visited $stage 1
        if {$stage!=$::previous_stage} {set ::last_active {0 0}; set ::previous_stage $stage}
        foreach idx {0 1} {
            set active [debug read memory [expr {0xC020+$idx*8}]]
            if {$active && ![lindex $::last_active $idx]} {dict incr ::cow_counts $stage}
            lset ::last_active $idx $active
        }
        if {![debug read memory 0xC061]} {keymatrixdown 8 128; return}
        set row [debug read memory 0xC017]
        set y [debug read memory 0xC005]
        set axle [expr {$row+(($y+8)/8)}]
        set target [lindex $::centers $axle]
        if {($axle<=117 && $axle>=108) || ($axle<=61 && $axle>=52)} {set target 168}
        if {$row==0} {set target 120; keymatrixdown 8 32}
        set x [debug read memory 0xC004]
        if {$x<$target} {keymatrixdown 8 128}
        if {$x>$target} {keymatrixdown 8 16}
        keymatrixdown 8 1
        if {[debug read memory 0xC050]} {
            set station [expr {$row>80 ? 110 : 54}]
            dict set ::stops "$stage-$station" 1
        }
    } elseif {$state==4} {
        set hp [debug read memory 0xC065]
        if {$hp<$::previous_hp} {incr ::boss_hits [expr {$::previous_hp-$hp}]}
        set ::previous_hp $hp
        set target [debug read memory 0xC066]
        if {[debug read memory 0xC069] && [debug read memory 0xC06B]>80} {
            if {[debug read memory 0xC06C]<=120} {set target 160} else {set target 80}
        }
        set x [debug read memory 0xC004]
        if {$x<$target} {keymatrixdown 8 128}
        if {$x>$target} {keymatrixdown 8 16}
        keymatrixdown 8 1
    } elseif {$state==7} {
        set stage [debug read memory 0xC060]
        set raw [debug read memory 0xC058]
        set remaining [expr {($raw>>4)*10+($raw&15)}]
        set score [current_score]
        if {![dict exists $::bonus_stages $stage]} {
            dict set ::bonus_stages $stage $remaining
        } else {
            lassign [dict get $::bonus_previous $stage] old_remaining old_score
            if {$remaining<$old_remaining} {
                set paid [expr {$old_remaining-$remaining}]
                incr ::bonus_converted $paid
                if {$score-$old_score!=$paid*100} {incr ::bonus_errors}
            }
        }
        dict set ::bonus_previous $stage [list $remaining $score]
    } elseif {$state==5} {
        set ::saw_ending true
        if {$::previous_hp>0} {incr ::boss_hits $::previous_hp; set ::previous_hp 0}
    } elseif {$state==8 || $state==9} {
        dict incr ::art_ticks $state
        if {[lsearch -exact $::art_order $state]<0} {lappend ::art_order $state}
    } elseif {$state==6} {
        if {[debug read_block VRAM [expr {0x1800+14*32+7}] 17] eq "By Robson Velloso"} {set ::finished true}
    }
}
after time 6 {keymatrixdown 8 1}
after time 6.1 {keymatrixup 8 1; debug set_bp $::sym(MainLoop.tick) {} {campaign_drive}}
after time 150 {
    set state [debug read memory 0xC000]
    set hz [expr {[debug read memory 0xC003] ? 60 : 50}]
    set ok [expr {$::finished && $state==6 && [dict size $::visited]==3 && [dict size $::stops]==6 && $::boss_hits==12 && $::saw_ending && $::overflow==0 && [dict size $::bonus_stages]==3 && $::bonus_converted>0 && $::bonus_errors==0 && $::road_errors==0 && $::art_order eq {8 9} && [dict get $::art_ticks 8]==250 && [dict get $::art_ticks 9]==250}]
    set f [open "resources/generated/campaign-$hz.txt" w]
    puts $f "[expr {$ok ? {PASS} : {FAIL}}] campaign: state=$state; stages=[dict size $::visited]; stations=[dict size $::stops]; boss hits=$::boss_hits; ending=$::saw_ending; road errors=$::road_errors; art ticks=$::art_ticks; cows=$::cow_counts; bonus stages=[dict size $::bonus_stages]; cheeses converted=$::bonus_converted; bonus errors=$::bonus_errors; max sprites=$::worst; overflow=$::overflow; lives=[debug read memory 0xC006]"
    close $f
    exit
}
set power true
