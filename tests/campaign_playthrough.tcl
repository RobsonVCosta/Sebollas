# Full four-stage campaign: keyboard only; no health, position, fuel or HP cheats.
set throttle off
set sound_driver null
set save_settings_on_exit false
set f [open resources/generated/sebollas.sym r]
foreach line [split [read $f] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $f
proc ::tcl::mathfunc::min {a b} {expr {$a<$b ? $a : $b}}
proc ::tcl::mathfunc::max {a b} {expr {$a>$b ? $a : $b}}
proc rd {addr} {debug read memory $addr}
proc score {} {scan [binary encode hex [debug read_block memory 0xC008 4]] %d value; return $value}
proc steer {target goal} {
    set x [rd 0xC004]; set y [rd 0xC005]
    if {$x<$target} {keymatrixdown 8 128}
    if {$x>$target} {keymatrixdown 8 16}
    if {$y<$goal} {keymatrixdown 8 64}
    if {$y>$goal} {keymatrixdown 8 32}
}
proc avoid_walking_cow {target goal} {
    if {![rd 0xC020]} {return [list $target $goal]}
    set x [rd 0xC004]; set y [rd 0xC005]
    set cx [rd 0xC021]; set cy [rd 0xC022]
    if {abs($cx-$x)<72 && abs($cy-$y)<80} {
        set left [rd 0xC08B]; set right [rd 0xC08C]
        if {$cx<$x} {set target $right} else {set target $left}
        if {$cy<$y} {set goal 160} else {set goal 32}
        if {$y>=136 && $cy<$y && $y-$cy<32} {set goal 32}
        if {$y<=40 && $cy>$y && $cy-$y<32} {set goal 160}
        if {[rd 0xC000]==12 && $goal<80} {set goal 80}
    }
    return [list $target $goal]
}
set herd {}; set visited {}; set stops {}; set intros [dict create 0 0 1 0 2 0 3 0]
set meetings {}; set bonus {}; set bonus_previous {}; set converted 0; set bonus_errors 0
set boss_stations {}; set previous_hp 12; set boss_hits 0; set challenge_ticks 0
set art_ticks [dict create 8 0 9 0]; set ending_phases {}; set finished false
set road_errors 0; set worst 0; set overflow 0; set samples 0
proc campaign_drive {} {
    keymatrixup 8 255; keymatrixup 7 255
    set state [rd 0xC000]; set stage [rd 0xC060]
    if {$state in {1 4 5 11 12}} {
        incr ::samples
        set counts [lrepeat 192 0]
        for {set slot 0} {$slot<32} {incr slot} {
            set y [debug read VRAM [expr {0x1e00+$slot*4}]]
            if {$y==216} {break}
            incr y
            for {set line $y} {$line<$y+16 && $line<192} {incr line} {
                if {$line>=0} {lset counts $line [expr {[lindex $counts $line]+1}]}
            }
        }
        set peak [lindex [lsort -integer $counts] end]
        if {$peak>$::worst} {set ::worst $peak}
        if {$peak>8} {incr ::overflow}
    }
    if {$state==10} {dict incr ::intros $stage; return}
    if {$state==11} {dict incr ::meetings $stage; return}
    if {$state==1} {
        dict set ::visited $stage 1
        set x [rd 0xC004]; set y [rd 0xC005]; set row [rd 0xC017]
        set width [expr {$stage<2 ? 32 : 16}]
        for {set r [expr {$row+$y/8-2}]} {$r<=$row+($y+31)/8-2} {incr r} {
            for {set col [expr {$x/8}]} {$col<=($x+$width-1)/8} {incr col} {
                if {[rd [expr {0xD000+$r*32+$col}]] ni {130 131 146 157 159}} {incr ::road_errors}
            }
        }
        if {![rd 0xC061]} {keymatrixdown 8 128; return}
        set axle [expr {$row+(($y+8)/8)}]
        set target [rd [expr {0xE400+$axle}]]
        if {$stage<2} {incr target -8}
        set goal 128
        if {($axle<=117 && $axle>=108) || ($axle<=61 && $axle>=52)} {set target 168}
        if {[rd 0xC050]} {dict set ::stops "$stage-[expr {$row>80 ? 110 : 54}]" 1}
        if {$stage<2} {
            lassign [avoid_walking_cow $target $goal] target goal
        } else {
            foreach idx {0 1 2} {
                set base [expr {0xC020+$idx*8}]
                set distance [expr {$y-[rd [expr {$base+2}]]}]
                set cowx [rd [expr {$base+1}]]
                if {[rd $base] && [rd [expr {$base+5}]] && $distance>=-24 && $distance<=96 && $target>$cowx-11 && $target<$cowx+26} {set target [rd 0xC08C]}
            }
            keymatrixdown 8 1
        }
        if {$stage<2 && (($axle<=117 && $axle>=108) || ($axle<=61 && $axle>=52))} {
            set target 168; set goal 128
        }
        if {$row==0} {set target 120; set goal [expr {$stage==0 ? 96 : 80}]}
        steer $target $goal
    } elseif {$state==12} {
        incr ::challenge_ticks
        if {![rd 0xC061]} {keymatrixdown 8 64; return}
        set target [expr {[rd 0xC06A]-8}]; set goal 160
        if {![rd 0xC069]} {set target [rd 0xC066]}
        dict set ::herd [rd 0xC0AC] 1
        if {![dict exists $::boss_stations 1] || [rd 0xC04E]<30 || [rd 0xC050]} {
            set target 216; set goal 136
            if {[rd 0xC050] && [rd 0xC04E]>=95} {dict set ::boss_stations 1 1}
        }
        steer $target 160
    } elseif {$state==4} {
        if {![rd 0xC061]} {keymatrixdown 8 128; return}
        set hp [rd 0xC065]
        if {$hp<$::previous_hp} {incr ::boss_hits [expr {$::previous_hp-$hp}]}
        set ::previous_hp $hp
        set target [rd 0xC066]
        if {[rd 0xC069] && [rd 0xC06B]>=64} {
            if {[rd 0xC06C]<=120} {set target 160} else {set target 80}
        }
        if {![dict exists $::boss_stations 3]} {
            set target 216
            if {[rd 0xC050] && [rd 0xC04E]>=95} {dict set ::boss_stations 3 1}
        }
        steer $target 136
        keymatrixdown 8 1
    } elseif {$state==7} {
        set raw [rd 0xC058]; set remaining [expr {($raw>>4)*10+($raw&15)}]; set value [score]; if {[rd 0xC09E]} {set remaining 100}
        if {![dict exists $::bonus $stage]} {dict set ::bonus $stage $remaining} else {
            lassign [dict get $::bonus_previous $stage] old_remaining old_score
            if {$remaining<$old_remaining} {
                set paid [expr {$old_remaining-$remaining}]; incr ::converted $paid
                if {$value-$old_score!=$paid*100} {incr ::bonus_errors}
            }
        }
        dict set ::bonus_previous $stage [list $remaining $value]
    } elseif {$state==5} {dict incr ::ending_phases [rd 0xC06E]
    } elseif {$state==8 || $state==9} {dict incr ::art_ticks $state
    } elseif {$state==6 && [debug read_block VRAM [expr {0x1800+14*32+7}] 17] eq "By Robson Velloso"} {set ::finished true}
}
after time 6 {keymatrixdown 8 1}
after time 6.1 {keymatrixup 8 1; debug set_bp $::sym(MainLoop.tick) {} {campaign_drive}}
after time 1200 {
    set state [rd 0xC000]; set hz [expr {[rd 0xC003] ? 60 : 50}]
    set intro_ok true
    foreach stage {0 1 2 3} {if {[dict get $::intros $stage]!=250} {set intro_ok false}}
    set ok [expr {$::finished && $state==6 && [dict size $::visited]==4 && $::boss_hits==12 && $::challenge_ticks>0 && [rd 0xC09A]==30 && [dict size $::herd]>=2 && [dict exists $::meetings 0] && [dict exists $::meetings 2] && $intro_ok && $::road_errors==0 && $::overflow==0 && [dict size $::bonus]==3 && $::converted>0 && $::bonus_errors==0 && [dict get $::art_ticks 8]==250 && [dict get $::art_ticks 9]==250}]
    set f [open "resources/generated/campaign-$hz.txt" w]
    puts $f "[expr {$ok ? {PASS} : {FAIL}}] campaign: state=$state; stages=[dict size $::visited]; stops=[dict size $::stops]; final boss hits=$::boss_hits; cane ticks=$::challenge_ticks; canes caught=[rd 0xC09A]; herd=$::herd; meetings=$::meetings; intro ticks=$::intros; arena refills=$::boss_stations; road errors=$::road_errors; bonus stages=[dict size $::bonus]; converted=$::converted; bonus errors=$::bonus_errors; max sprites=$::worst; overflow=$::overflow; lives=[rd 0xC006]"
    close $f; exit
}
set power true
