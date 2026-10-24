# Actual Z80 routine tests on C-BIOS MSX2. Run from the project root.
set throttle off
set sound_driver null
set save_settings_on_exit false
set fh [open resources/generated/sebollas.sym r]
foreach line [split [read $fh] \n] {
    if {[regexp {^([^:]+): EQU (0x[0-9A-Fa-f]+)} $line -> name addr]} {set sym($name) [expr {$addr}]}
}
close $fh
proc rd {a} {debug read memory $a}
proc wr {a v} {debug write memory $a $v}
proc expect {name actual expected} {
    if {$actual ne $expected} {error "$name: got <$actual>, expected <$expected>"}
}
proc prepare {} {
    keymatrixup 8 255
    keymatrixup 7 255
    foreach {a v} {0xC000 1 0xC004 120 0xC005 128 0xC006 3 0xC007 0 0xC015 0 0xC018 64 0xC017 138 0xC04E 100 0xC04F 0 0xC050 0} {wr $a $v}
    for {set a 0xC008} {$a<0xC00C} {incr a} {wr $a 0}
    for {set a 0xC020} {$a<0xC038} {incr a} {wr $a 0}
}
proc cow {x y {scared 0}} {
    foreach {a v} [list 0xC020 1 0xC021 $x 0xC022 $y 0xC023 0 0xC024 $scared] {wr $a $v}
}
proc bullet {x y} {wr 0xC030 1; wr 0xC031 $x; wr 0xC032 $y}
proc bcd {} {binary encode hex [debug read_block memory 0xC008 4]}
proc check_sat {} {
    expect slots [rd 0xC040] 25
    set counts [lrepeat 192 0]
    for {set s 0} {$s<25} {incr s} {
        set y [expr {[rd [expr {0xC100+$s*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {
            lset counts $line [expr {[lindex $counts $line]+1}]
        }
    }
    expect maximum_sprites [lindex [lsort -integer $counts] end] 8
    expect terminator [rd [expr {0xC100+25*4}]] 216
}
set cases {}
proc case {name routine setup check} {lappend ::cases [list $name $routine $setup $check]}
case reset ResetGame {} {
    expect state [rd 0xC000] 1
    expect lives [rd 0xC006] 3
    expect carX [rd 0xC004] 120
    expect carY [rd 0xC005] 128
    expect score [bcd] 00000000
}
foreach {name mask dx dy} {up 32 0 -1 upright 160 1 -1 right 128 1 0 downright 192 1 1 down 64 0 1 downleft 80 -1 1 left 16 -1 0 upleft 48 -1 -1} {
    case $name MovePlayer [list keymatrixdown 8 $mask] "expect x \[rd 0xC004\] [expr {120+$dx}]; expect y \[rd 0xC005\] [expr {128+$dy}]"
}
case clamp_top_right MovePlayer {wr 0xC004 176; wr 0xC005 32; keymatrixdown 8 160} {
    expect x [rd 0xC004] 176; expect y [rd 0xC005] 32
}
case clamp_bottom_left MovePlayer {wr 0xC004 64; wr 0xC005 144; keymatrixdown 8 80} {
    expect x [rd 0xC004] 64; expect y [rd 0xC005] 144
}
case shot_scares CheckHits {cow 100 80; bullet 104 88} {
    expect scared [rd 0xC024] 1
    expect consumed [rd 0xC030] 0
    expect points [bcd] 00000100
    expect lives [rd 0xC006] 3
}
case shot_scores_once CheckHits {cow 100 80 1; bullet 104 88; wr 0xC00A 1} {
    expect points [bcd] 00000100
}
case scare_speed UpdateCows {cow 100 80 1} {expect x [rd 0xC021] 102}
case walking_speed UpdateCows {cow 100 80} {expect x [rd 0xC021] 101}
case cow_crosses_right UpdateCows {cow 223 80} {
    expect active [rd 0xC020] 0; expect points [bcd] 00000010
}
case cow_crosses_left UpdateCows {cow 1 80; wr 0xC023 1} {
    expect active [rd 0xC020] 0; expect points [bcd] 00000010
}
case one_life_per_collision CheckHits {cow 112 128} {
    expect lives [rd 0xC006] 2; expect invulnerability [rd 0xC007] 100
}
case invulnerability CheckHits {cow 112 128; wr 0xC007 50} {
    expect lives [rd 0xC006] 3; expect invulnerability [rd 0xC007] 50
}
case third_hit_gameover CheckHits {
    cow 112 128; wr 0xC006 1
    debug write VRAM 0x18AC 130
} {
    expect state [rd 0xC000] 2; expect lives [rd 0xC006] 0
    expect world_preserved [debug read VRAM 0x18AC] 130
    expect centered_message [debug read_block VRAM [expr {0x1800+11*32+11}] 9] "GAME OVER"
    expect last_heart_off [debug read VRAM 0x1819] 141
    expect start_requires_release [rd 0xC01A] 0
}
case gameover_to_title MenuTick {wr 0xC000 2; wr 0xC01A 1; keymatrixdown 8 1} {
    expect state [rd 0xC000] 0; expect armed [rd 0xC01A] 0
}
case held_start_not_repeated MenuTick {wr 0xC000 0; wr 0xC01A 0; keymatrixdown 8 1} {
    expect state [rd 0xC000] 0
}
case released_start_arms MenuTick {wr 0xC000 0; wr 0xC01A 0} {expect armed [rd 0xC01A] 1}
case enter_starts MenuTick {wr 0xC000 0; wr 0xC01A 1; keymatrixdown 7 128} {
    expect state [rd 0xC000] 1; expect lives [rd 0xC006] 3
}
case space_fires UpdateBullets {keymatrixdown 8 1} {
    expect active [rd 0xC030] 1; expect y [rd 0xC032] 120
}
case bullets_cannot_overlap UpdateBullets {keymatrixdown 8 1; bullet 120 120} {
    expect second [rd 0xC034] 0
}
case second_bullet UpdateBullets {keymatrixdown 8 1; bullet 120 100} {
    expect second [rd 0xC034] 1
}
case bullet_moves UpdateBullets {bullet 120 80} {expect y [rd 0xC032] 76}
case bullet_exits UpdateBullets {bullet 120 16} {expect active [rd 0xC030] 0}
case bcd_carry AddTen {wr 0xC00A 9; wr 0xC00B 0x90} {expect score [bcd] 00001000}
case bcd_wrap AddTen {foreach a {0xC008 0xC009 0xC00A} {wr $a 0x99}; wr 0xC00B 0x90} {
    expect score [bcd] 00000000
}
case spawn_right UpdateCows {wr 0xC018 1; wr 0xC019 0} {
    expect active [rd 0xC020] 1; expect x [rd 0xC021] 0; expect y [rd 0xC022] 40
}
case spawn_left UpdateCows {wr 0xC018 1; wr 0xC019 1} {
    expect active [rd 0xC020] 1; expect x [rd 0xC021] 224; expect dir [rd 0xC023] 1
}
case spawn_spacing UpdateCows {cow 80 80; wr 0xC018 1} {expect second [rd 0xC028] 0}
case spawn_second UpdateCows {cow 80 104; wr 0xC018 1} {
    expect second [rd 0xC028] 1; expect separation [expr {[rd 0xC022]-[rd 0xC02A]}] 64
}
case sprite_budget BuildSprites {
    cow 96 128
    foreach {a v} {0xC028 1 0xC029 20 0xC02A 64 0xC02B 1 0xC02C 0} {wr $a $v}
    bullet 120 128; wr 0xC034 1; wr 0xC035 120; wr 0xC036 96
} {check_sat}
case fixed_hud UpdateScroll {
    wr 0xC016 15; wr 0xC017 80
    set ::oldhud [debug read_block VRAM 0x1800 64]
} {
    expect maprow [rd 0xC017] 79
    expect hud [debug read_block VRAM 0x1800 64] $::oldhud
}
foreach lives {0 1 2 3} {
    case hearts_$lives DrawHUD [list wr 0xC006 $lives] "
        for {set i 0} {\$i<3} {incr i} {
            expect heart_\$i \[debug read VRAM \[expr {0x1819+\$i*2}\]\] \[expr {\$i<$lives ? 140 : 141}\]
        }
    "
}
case gameover_no_play_blink MenuTick {
    wr 0xC000 2; wr 0xC001 16
    debug write VRAM 0x19CE 130
} {expect no_play [debug read VRAM 0x19CE] 130}
case cow_fixed_pose BuildSprites {cow 96 64; wr 0xC001 8} {
    expect cow_pattern [rd [expr {0xC100+7*4+2}]] $::sym(COW_PATTERN)
}
case fuel_consumption UpdateJourney {wr 0xC04F 11} {
    expect fuel [rd 0xC04E] 99; expect clock [rd 0xC04F] 0
}
case fuel_empty UpdateJourney {wr 0xC04E 1; wr 0xC04F 11} {expect state [rd 0xC000] 2}
foreach station {54 110} {
    case refuel_$station UpdateJourney "wr 0xC017 [expr {$station-17}]; wr 0xC004 168; wr 0xC04E 10" {
        expect fuel [rd 0xC04E] 11; expect filling [rd 0xC050] 1
    }
}
case no_refuel_on_road UpdateJourney {wr 0xC017 93; wr 0xC04E 10} {
    expect fuel [rd 0xC04E] 10; expect filling [rd 0xC050] 0
}
case refuel_recovers_empty UpdateJourney {wr 0xC017 93; wr 0xC004 168; wr 0xC04E 0} {
    expect fuel [rd 0xC04E] 1; expect state [rd 0xC000] 1
}
case tank_caps_at_100 UpdateJourney {wr 0xC017 93; wr 0xC004 168; wr 0xC04E 100} {
    expect fuel [rd 0xC04E] 100; expect filling [rd 0xC050] 0
}
case filling_pauses_scroll UpdateScroll {wr 0xC050 1; wr 0xC016 15} {expect maprow [rd 0xC017] 138}
case route_does_not_wrap UpdateScroll {wr 0xC017 0; wr 0xC016 15} {expect maprow [rd 0xC017] 0}
case bridge_safe UpdateJourney {wr 0xC017 68} {expect lives [rd 0xC006] 3}
case river_collision UpdateJourney {wr 0xC017 68; wr 0xC004 72} {
    expect lives [rd 0xC006] 2; expect rescue_x [rd 0xC004] 120
}
case narrow_road_collision UpdateJourney {wr 0xC017 110; wr 0xC004 64} {expect lives [rd 0xC006] 2}
case arrival UpdateJourney {wr 0xC017 0; wr 0xC005 80} {
    expect state [rd 0xC000] 3
    expect message [debug read_block VRAM [expr {0x1800+11*32+11}] 9] "CHEGAMOS!"
}
case destination_requires_driveway UpdateJourney {wr 0xC017 0} {expect state [rd 0xC000] 1}
case arrival_to_title MenuTick {wr 0xC000 3; wr 0xC01A 1; keymatrixdown 8 1} {expect state [rd 0xC000] 0}
case clean_title ShowMenu {} {
    expect below_play [debug read_block VRAM [expr {0x1800+15*32}] [expr {9*32}]] [string repeat " " [expr {9*32}]]
}
after realtime 10 {
    set f [open /tmp/sebollas-timeout.txt w]
    puts $f "index=$::index PC=[reg PC] SP=[reg SP] reports=$::reports"
    close $f
    exit
}
case sound_shot SoundShot {} {
    expect duration [rd 0xC01C] 4
    expect volume [debug read {PSG regs} 8] 12
    expect tone [debug read {PSG regs} 0] 110
}
case sound_finishes UpdateSound {wr 0xC01C 1} {
    expect duration [rd 0xC01C] 0
    expect volume [debug read {PSG regs} 8] 0
}
case invulnerability_expires MovePlayer {wr 0xC007 1} {expect timer [rd 0xC007] 0}
set index -1
set failures 0
set reports {}
proc next_case {} {
    if {$::index>=0} {
        set last [lindex $::cases $::index]
        if {[catch {uplevel #0 [lindex $last 3]} msg]} {
            incr ::failures
            lappend ::reports "FAIL [lindex $last 0]: $msg"
        } else {lappend ::reports "PASS [lindex $last 0]"}
    }
    incr ::index
    if {$::index>=[llength $::cases]} {
        lappend ::reports "[llength $::cases] Z80 cases; $::failures failures"
        set hz [expr {[rd 0xC003] ? 60 : 50}]
        set f [open "resources/generated/emulator-$hz.txt" w]
        puts $f [join $::reports \n]
        close $f
        exit
        return
    }
    prepare
    set current [lindex $::cases $::index]
    uplevel #0 [lindex $current 2]
    reg IFF 0
    reg SP 0xCFEE
    wr 0xCFEE 0xF0
    wr 0xCFEF 0xCF
    reg PC $::sym([lindex $current 1])
    debug cont
}
after time 6 {set ::before [rd 0xC001]}
after time 8 {
    set delta [expr {([rd 0xC001]-$::before)&255}]
    if {$delta<98 || $delta>102} {
        incr ::failures
        lappend ::reports "FAIL frequency normalization: $delta ticks / 2 seconds"
    } else {lappend ::reports "PASS frequency normalization: $delta ticks / 2 seconds"}
    debug set_bp 0xCFF0 {} {next_case}
    set ::startbp [debug set_bp $::sym(MainLoop.tick) {} {
        debug remove_bp $::startbp
        next_case
    }]
}

set power true
