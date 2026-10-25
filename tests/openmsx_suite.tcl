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
    foreach {a v} {0xC000 1 0xC004 120 0xC005 128 0xC006 3 0xC007 0 0xC015 0 0xC018 64 0xC017 138 0xC04E 100 0xC04F 0 0xC050 0 0xC052 0 0xC053 0 0xC054 0 0xC055 0 0xC056 0 0xC057 48 0xC058 0 0xC01C 0 0xC01D 0 0xC01E 0 0xC059 0 0xC05A 0 0xC05B 0 0xC05C 0 0xC05D 0 0xC05E 0 0xC060 1 0xC061 1 0xC062 1 0xC063 0 0xC064 0 0xC065 12 0xC066 120 0xC067 0 0xC068 24 0xC069 0 0xC06A 0 0xC06B 0 0xC06C 120 0xC06D 0 0xC077 0 0xC078 0 0xC079 0 0xC07A 0 0xC084 0 0xC085 0 0xC086 0 0xC087 0} {wr $a $v}
    for {set a 0xC008} {$a<0xC00C} {incr a} {wr $a 0}
    for {set a 0xC020} {$a<0xC038} {incr a} {wr $a 0}
}
proc cow {x y {scared 0}} {
    foreach {a v} [list 0xC020 1 0xC021 $x 0xC022 $y 0xC023 0 0xC024 $scared] {wr $a $v}
}
proc bcd {} {binary encode hex [debug read_block memory 0xC008 4]}
proc check_sat {} {
    expect slots [rd 0xC040] 24
    set counts [lrepeat 192 0]
    for {set s 0} {$s<24} {incr s} {
        set y [expr {[rd [expr {0xC100+$s*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {
            lset counts $line [expr {[lindex $counts $line]+1}]
        }
    }
    expect maximum_sprites [lindex [lsort -integer $counts] end] 8
    expect terminator [rd [expr {0xC100+24*4}]] 216
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
foreach {name mask dx dy} {up 32 0 -1 upright 160 2 -1 right 128 2 0 downright 192 2 1 down 64 0 1 downleft 80 -2 1 left 16 -2 0 upleft 48 -2 -1} {
    case $name MovePlayer [list keymatrixdown 8 $mask] "expect x \[rd 0xC004\] [expr {120+$dx}]; expect y \[rd 0xC005\] [expr {128+$dy}]"
}
case clamp_top_right MovePlayer {wr 0xC004 208; wr 0xC005 32; keymatrixdown 8 160} {
    expect x [rd 0xC004] 208; expect y [rd 0xC005] 32
}
case clamp_bottom_left MovePlayer {wr 0xC004 32; wr 0xC005 144; keymatrixdown 8 80} {
    expect x [rd 0xC004] 32; expect y [rd 0xC005] 144
}
case horn_scares ScareCowsAhead {cow 100 80} {
    expect scared [rd 0xC024] 1
    expect points [bcd] 00000100
    expect lives [rd 0xC006] 3
}
case horn_scores_once ScareCowsAhead {cow 100 80 1; wr 0xC00A 1} {
    expect points [bcd] 00000100
}
case scare_speed UpdateCows {cow 100 80 1} {expect x [rd 0xC021] 102}
case parked_cow_stays UpdateCows {cow 100 80} {expect x [rd 0xC021] 100}
case cow_leaves_right UpdateCows {cow 223 80 1} {
    expect active [rd 0xC020] 0; expect points [bcd] 00000000
}
case cow_leaves_left UpdateCows {cow 1 80 1; wr 0xC023 1} {
    expect active [rd 0xC020] 0; expect points [bcd] 00000000
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
case space_honks UpdateHornInput {keymatrixdown 8 1; cow 112 80} {
    expect horn_phase [rd 0xC059] 1; expect leaving [rd 0xC024] 1
}
case no_horn_cow_waits UpdateHornInput {cow 112 80} {expect leaving [rd 0xC024] 0}
case horn_reaches_both UpdateHornInput {
    keymatrixdown 8 1; cow 112 80
    foreach {a v} {0xC028 1 0xC029 112 0xC02A 16 0xC02B 1 0xC02C 0} {wr $a $v}
} {
    expect first [rd 0xC024] 1; expect second [rd 0xC02C] 1
    expect points [bcd] 00000200
}
case horn_spares_cows_behind ScareCowsAhead {cow 112 144} {expect leaving [rd 0xC024] 0}
case horn_out_of_range ScareCowsAhead {cow 100 0} {expect leaving [rd 0xC024] 0}
case bcd_carry AddTen {wr 0xC00A 9; wr 0xC00B 0x90} {expect score [bcd] 00001000}
case bcd_wrap AddTen {foreach a {0xC008 0xC009 0xC00A} {wr $a 0x99}; wr 0xC00B 0x90} {
    expect score [bcd] 00000000
}
case spawn_right UpdateCows {wr 0xC018 1; wr 0xC019 0} {
    expect active [rd 0xC020] 1; expect x [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters)+140}]]-8}]; expect y [rd 0xC022] 16
}
case spawn_left UpdateCows {wr 0xC018 1; wr 0xC019 1} {
    expect active [rd 0xC020] 1; expect x [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters)+140}]]-8}]; expect dir [rd 0xC023] 1
}
case spawn_spacing UpdateCows {cow 80 60; wr 0xC018 1} {expect second [rd 0xC028] 0}
case spawn_second UpdateCows {cow 80 104; wr 0xC018 1} {
    expect second [rd 0xC028] 1; expect separation [expr {[rd 0xC022]-[rd 0xC02A]}] 88
}
case sprite_budget BuildSprites {
    cow 96 128
    foreach {a v} {0xC028 1 0xC029 20 0xC02A 64 0xC02B 1 0xC02C 0} {wr $a $v}
    wr 0xC053 1; wr 0xC054 120; wr 0xC055 128
} {check_sat}
case fixed_hud UpdateScroll {
    wr 0xC016 7; wr 0xC017 80
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
case fuel_consumption UpdateJourney {wr 0xC04F 5} {
    expect fuel [rd 0xC04E] 99; expect clock [rd 0xC04F] 0
}
case fuel_empty UpdateJourney {wr 0xC04E 1; wr 0xC04F 5} {expect state [rd 0xC000] 2}
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
case filling_pauses_scroll UpdateScroll {wr 0xC050 1; wr 0xC016 7} {expect maprow [rd 0xC017] 138}
case route_does_not_wrap UpdateScroll {wr 0xC017 0; wr 0xC016 7} {expect maprow [rd 0xC017] 0}
case bridge_safe UpdateJourney {wr 0xC017 68} {expect lives [rd 0xC006] 3}
case river_collision UpdateJourney {wr 0xC017 68; wr 0xC004 72} {
    expect lives [rd 0xC006] 2; expect rescue_x [rd 0xC004] [debug read memory [expr {$::sym(RoadCenters)+85}]]
}
case narrow_road_collision UpdateJourney {wr 0xC017 110; wr 0xC004 32} {expect lives [rd 0xC006] 2}
case arrival UpdateJourney {wr 0xC017 0; wr 0xC005 80} {
    expect state [rd 0xC000] 7
    expect current_stage [rd 0xC060] 1
    expect card [debug read_block VRAM [expr {0x1800+3*32+8}] 5] "FASE "
}
case destination_requires_driveway UpdateJourney {wr 0xC017 0} {expect state [rd 0xC000] 1}
case arrival_to_title MenuTick {wr 0xC000 3; wr 0xC01A 1; keymatrixdown 8 1} {expect state [rd 0xC000] 0}
case title_art_loaded ShowMenu {} {
    expect black_backdrop [debug read {VDP regs} 7] 0
    expect mode [rd 0xFCAF] 5
    expect height [expr {[debug read {VDP regs} 9]&128}] 128
    for {set row 0} {$row<8} {incr row} {
        expect play_row [debug read_block VRAM [expr {100*128+76+$row*128}] 20] [debug read_block memory [expr {$::sym(TitlePlayOn)+$row*20}] 20]
    }
}
case title_play_hidden DrawTitlePlay {reg A 0} {
    expect clear_play [debug read_block VRAM [expr {100*128+76}] 20] [string repeat [format %c $::sym(TITLE_PLAY_BACKGROUND)] 20]
}
case title_play_shown DrawTitlePlay {reg A 1} {
    expect play [debug read_block VRAM [expr {100*128+76}] 20] [debug read_block memory $::sym(TitlePlayOn) 20]
}
case title_to_game ResetGame {} {
    expect mode [rd 0xFCAF] 4
    expect height [expr {[debug read {VDP regs} 9]&128}] 0
    expect font_bank [debug read_block VRAM 0 2048] [debug read_block memory $::sym(TilePatterns) 2048]
}
case low_fuel_alert UpdateFuelAlert {wr 0xC04E 20} {
    expect duration [rd 0xC01E] 6; expect interval [rd 0xC052] 25
    expect tone [debug read {PSG regs} 4] 96
    expect loud [debug read {PSG regs} 10] 15
}
case critical_fuel_faster UpdateFuelAlert {wr 0xC04E 10} {expect interval [rd 0xC052] 12}
case fuel_alert_cooldown UpdateFuelAlert {wr 0xC04E 10; wr 0xC052 10} {
    expect interval [rd 0xC052] 9; expect silent [rd 0xC01E] 0
}
case fuel_alert_stops_on_refill UpdateFuelAlert {wr 0xC04E 50; wr 0xC052 10} {expect interval [rd 0xC052] 0}
case no_alert_while_filling UpdateFuelAlert {wr 0xC04E 10; wr 0xC050 1} {expect silent [rd 0xC01E] 0}
case crash_precedes_fuel_alert UpdateFuelAlert {wr 0xC04E 10; wr 0xC01E 20} {expect crash [rd 0xC01E] 20}
case gauge_empty DrawFuel {wr 0xC04E 0} {expect needle [debug read VRAM 0x1826] 177}
case gauge_full DrawFuel {wr 0xC04E 100} {expect needle [debug read VRAM 0x182F] 176}
case gauge_half DrawFuel {wr 0xC04E 50} {expect needle [debug read VRAM 0x182B] 169}
case cheese_spawn UpdateCheese {wr 0xC057 0} {
    expect active [rd 0xC053] 1; expect y [rd 0xC055] 32
    expect center [rd 0xC054] [debug read memory [expr {$::sym(RoadCenters)+140}]]
}
case cheese_collect UpdateCheese {wr 0xC053 1; wr 0xC054 120; wr 0xC055 120} {
    expect removed [rd 0xC053] 0; expect count [rd 0xC058] 1
    expect pending_bonus_not_score [bcd] 00000000; expect lives [rd 0xC006] 3
}
case cheese_roll UpdateCheese {wr 0xC053 1; wr 0xC054 120; wr 0xC055 64; wr 0xC001 8} {
    expect y [rd 0xC055] 72; expect phase [rd 0xC056] 1
}
case cheese_exits UpdateCheese {wr 0xC053 1; wr 0xC054 40; wr 0xC055 176; wr 0xC001 8} {
    expect active [rd 0xC053] 0; expect lives [rd 0xC006] 3
}
case cheese_count_bcd UpdateCheese {wr 0xC053 1; wr 0xC054 120; wr 0xC055 120; wr 0xC058 9} {expect count [rd 0xC058] 16}
case cheese_sprite BuildSprites {wr 0xC053 1; wr 0xC054 120; wr 0xC055 64} {
    expect slots [rd 0xC040] 8
    expect pattern [rd [expr {0xC100+7*4+2}]] $::sym(CHEESE_PATTERN)
    expect y [rd [expr {0xC100+7*4}]] 63
    expect x [rd [expr {0xC100+7*4+1}]] 120
}
case horn_short_to_gap UpdateSound {
    wr 0xC059 1; wr 0xC05A 1; wr 0xC01C 1; wr 0xC01D 1
} {
    expect phase [rd 0xC059] 2; expect clock [rd 0xC05A] 4
    expect silent_a [debug read {PSG regs} 8] 0
    expect silent_b [debug read {PSG regs} 9] 0
}
case horn_gap_to_long UpdateSound {wr 0xC059 2; wr 0xC05A 1} {
    expect phase [rd 0xC059] 3; expect clock [rd 0xC05A] 24
    expect long_a [rd 0xC01C] 24; expect long_b [rd 0xC01D] 24
    expect volume_a [debug read {PSG regs} 8] 12
    expect volume_b [debug read {PSG regs} 9] 12
}
case horn_long_finishes UpdateSound {
    wr 0xC059 3; wr 0xC05A 1; wr 0xC01C 1; wr 0xC01D 1
} {
    expect phase [rd 0xC059] 0
    expect silent_a [debug read {PSG regs} 8] 0
    expect silent_b [debug read {PSG regs} 9] 0
}
case horn_does_not_restart SoundHorn {wr 0xC059 3; wr 0xC05A 12} {
    expect phase [rd 0xC059] 3; expect clock [rd 0xC05A] 12
}
case refuel_tone_low SoundRefuel {wr 0xC04E 50} {
    expect period [expr {[debug read {PSG regs} 2]+256*[debug read {PSG regs} 3]}] 600
    expect duration [rd 0xC01D] 3
}
case refuel_tone_high SoundRefuel {wr 0xC04E 90} {
    expect period [expr {[debug read {PSG regs} 2]+256*[debug read {PSG regs} 3]}] 360
}
case filling_plays_sound UpdateJourney {wr 0xC017 93; wr 0xC004 168; wr 0xC04E 10; wr 0xC001 0} {
    expect fuel [rd 0xC04E] 11
    expect duration [rd 0xC01D] 3
}
case no_horn_visual BuildSprites {wr 0xC059 1; wr 0xC05A 6} {
    expect only_car_and_dust [rd 0xC040] 7
}
case parked_cow_tracks_scenery UpdateScroll {cow 112 64; wr 0xC016 7} {
    expect x [rd 0xC021] 112; expect y [rd 0xC022] 72
    expect waiting [rd 0xC024] 0
}
case horn_spares_side_cow ScareCowsAhead {cow 208 80} {expect waiting [rd 0xC024] 0}
case horn_silent_gap UpdateHornInput {cow 112 80; wr 0xC059 2; wr 0xC05A 2} {expect waiting [rd 0xC024] 0}
case scared_cow_goes_left UpdateCows {cow 100 80 1; wr 0xC023 1} {expect x [rd 0xC021] 98}
case spawn_matches_curve UpdateCows {wr 0xC017 70; wr 0xC018 1} {
    expect active [rd 0xC020] 1
    expect center [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters)+72}]]-8}]
    expect waiting [rd 0xC024] 0
}
case music_starts UpdateMusic {} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 170
    expect quiet_volume [debug read {PSG regs} 10] 5
    expect next_note [rd 0xC05B] 1; expect duration [rd 0xC05C] 12
}
case music_advances UpdateMusic {wr 0xC05B 1; wr 0xC05C 1; wr 0xC05D 170} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 214
    expect next_note [rd 0xC05B] 2; expect duration [rd 0xC05C] 6
}
case music_loops_with_rest UpdateMusic {wr 0xC05B 31} {
    expect loop [rd 0xC05B] 0; expect rest_duration [rd 0xC05C] 12
    expect silence [debug read {PSG regs} 10] 0
}
case music_resumes_after_effect UpdateSound {wr 0xC01E 1; wr 0xC05C 8; wr 0xC05D 214} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 214
    expect music_volume [debug read {PSG regs} 10] 5; expect timer [rd 0xC05C] 7
}
case music_preserves_foreground UpdateMusic {
    wr 0xC01E 10; wr 0xC05C 8; wr 0xC05D 214
    debug write {PSG regs} 4 37; debug write {PSG regs} 10 12
} {
    expect effect_period [debug read {PSG regs} 4] 37
    expect effect_volume [debug read {PSG regs} 10] 12
    expect paused [rd 0xC05C] 8
}
case music_yields_to_horn UpdateMusic {wr 0xC059 1; wr 0xC05C 8; wr 0xC05D 214} {
    expect silence [debug read {PSG regs} 10] 0; expect paused [rd 0xC05C] 8
}
case music_yields_to_refuel UpdateMusic {wr 0xC050 1; wr 0xC05C 8; wr 0xC05D 214} {
    expect silence [debug read {PSG regs} 10] 0; expect paused [rd 0xC05C] 8
}
case music_stops_at_gameover UpdateMusic {wr 0xC000 2; wr 0xC05B 5; wr 0xC05C 8; wr 0xC05D 214} {
    expect silence [debug read {PSG regs} 10] 0
    expect rewind [rd 0xC05B] 0; expect stopped [rd 0xC05C] 0
}
case music_note_gap UpdateMusic {wr 0xC05C 3; wr 0xC05D 214} {
    expect silence [debug read {PSG regs} 10] 0; expect timer [rd 0xC05C] 2
}
after realtime 10 {
    set f [open /tmp/sebollas-timeout.txt w]
    puts $f "index=$::index PC=[reg PC] SP=[reg SP] reports=$::reports"
    close $f
    exit
}
case horn_sequence_start SoundHorn {} {
    expect duration [rd 0xC01C] 6
    expect volume [debug read {PSG regs} 8] 12
    expect tone [debug read {PSG regs} 0] 180
    expect second_tone [debug read {PSG regs} 2] 142
    expect dual_duration [rd 0xC01D] 6
    expect horn_phase [rd 0xC059] 1
    expect short_clock [rd 0xC05A] 6
}
case sound_finishes UpdateSound {wr 0xC01C 1} {
    expect duration [rd 0xC01C] 0
    expect volume [debug read {PSG regs} 8] 0
}
case invulnerability_expires MovePlayer {wr 0xC007 1} {expect timer [rd 0xC007] 0}
case waiting_does_not_scroll UpdateScroll {wr 0xC061 0; wr 0xC016 7} {expect map [rd 0xC017] 138}
case waiting_does_not_consume UpdateJourney {wr 0xC061 0; wr 0xC04F 5} {expect tank [rd 0xC04E] 100}
case waiting_has_no_cows UpdateCows {wr 0xC061 0; wr 0xC018 1} {expect active [rd 0xC020] 0}
case play_space_does_not_drive CheckDriveStart {wr 0xC061 0; wr 0xC062 0; keymatrixdown 8 1} {expect stopped [rd 0xC061] 0}
case release_arms_drive CheckDriveStart {wr 0xC061 0; wr 0xC062 0} {expect ready [rd 0xC062] 1; expect stopped [rd 0xC061] 0}
case arrows_start_drive CheckDriveStart {wr 0xC061 0; keymatrixdown 8 128} {expect moving [rd 0xC061] 1}
case space_starts_drive CheckDriveStart {wr 0xC061 0; wr 0xC062 1; keymatrixdown 8 1} {expect moving [rd 0xC061] 1}
case stage_two_follows_one AdvanceStage {} {expect stage [rd 0xC060] 2; expect card [rd 0xC000] 3}
case stage_three_follows_two AdvanceStage {wr 0xC060 2} {expect stage [rd 0xC060] 3; expect card [rd 0xC000] 3}
case stage_card_resumes CampaignTick {wr 0xC000 3; wr 0xC060 2; wr 0xC063 1; wr 0xC064 0; wr 0xC00A 1} {
    expect road [rd 0xC000] 1; expect stage [rd 0xC060] 2
    expect next_stage_drives [rd 0xC061] 1; expect fuel [rd 0xC04E] 100
    expect score_kept [bcd] 00000100
}
case phase_one_cow_delay CowSpawnDelay {} {expect delay [reg A] 128}
case phase_two_cow_delay CowSpawnDelay {wr 0xC060 2} {expect delay [reg A] 80}
case phase_three_cow_delay CowSpawnDelay {wr 0xC060 3} {expect delay [reg A] 48}
case phase_three_opens_boss CompleteStage {wr 0xC060 3} {expect fight [rd 0xC000] 4; expect health [rd 0xC065] 12}
case boss_needs_many_honks BossTakeHit {wr 0xC000 4; wr 0xC005 136} {expect fight [rd 0xC000] 4; expect health [rd 0xC065] 11}
case long_horn_is_one_hit BossTick {wr 0xC000 4; wr 0xC005 136; wr 0xC059 3; wr 0xC05A 12; keymatrixdown 8 1} {expect health [rd 0xC065] 12}
case last_honk_wins BossTakeHit {wr 0xC000 4; wr 0xC005 136; wr 0xC065 1; wr 0xC060 3} {expect bonus_first [rd 0xC000] 7; expect defeated [rd 0xC065] 0}
case garapa_throws_cane UpdateCane {wr 0xC000 4; wr 0xC068 0; wr 0xC066 132} {
    expect active [rd 0xC069] 1; expect x [rd 0xC06A] 132; expect y [rd 0xC06B] 64
}
case cane_takes_one_heart UpdateCane {wr 0xC000 4; wr 0xC005 136; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128} {
    expect lives [rd 0xC006] 2; expect protection [rd 0xC007] 100; expect consumed [rd 0xC069] 0
}
case cane_respects_protection UpdateCane {wr 0xC000 4; wr 0xC005 136; wr 0xC007 50; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128} {expect lives [rd 0xC006] 3}
case car_parks_for_ending EndingTick {wr 0xC000 5; wr 0xC06E 0; wr 0xC005 135; wr 0xC072 255; wr 0xC073 255; wr 0xC074 255} {expect parked_y [rd 0xC005] 136}
case small_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 19; wr 0xC070 0; wr 0xC071 20; wr 0xC072 255; wr 0xC073 255; wr 0xC074 255} {expect small [rd 0xC072] 113; expect tall_waits [rd 0xC073] 255}
case tall_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 44; wr 0xC070 0; wr 0xC071 20; wr 0xC072 254; wr 0xC073 255; wr 0xC074 255} {expect tall [rd 0xC073] 121}
case big_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 69; wr 0xC070 0; wr 0xC071 20; wr 0xC072 254; wr 0xC073 254; wr 0xC074 255} {expect big [rd 0xC074] 113}
case bus_is_clipped DrawBusRoad {wr 0xC071 30} {
    expect destination [debug read VRAM [expr {0x1800+11*32+30}]] 78
    expect no_wrap [debug read VRAM [expr {0x1800+12*32}]] 157
}
case boys_board_the_bus EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 200; wr 0xC070 0; wr 0xC071 33; wr 0xC072 254; wr 0xC073 254; wr 0xC074 254} {expect boarded [rd 0xC06E] 2; expect pause [rd 0xC063] 80}
case ending_reaches_credits EndingTick {wr 0xC000 5; wr 0xC06E 2; wr 0xC063 1; wr 0xC064 0} {
    expect credits [rd 0xC000] 6
    expect names [debug read_block VRAM [expr {0x1800+5*32+4}] 24] "Argon, Gordinho (Leto) e"
    expect author [debug read_block VRAM [expr {0x1800+14*32+7}] 17] "By Robson Velloso"
}
case ending_sprite_budget BuildEndingSprites {wr 0xC000 5; wr 0xC061 0; wr 0xC005 136; wr 0xC072 120; wr 0xC073 140; wr 0xC074 160} {
    expect slots [rd 0xC040] 18
    set counts [lrepeat 192 0]
    for {set s 0} {$s<18} {incr s} {
        set y [expr {[rd [expr {0xC100+$s*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {lset counts $line [expr {[lindex $counts $line]+1}]}
    }
    expect maximum [lindex [lsort -integer $counts] end] 6
}
case cow_scroll_exact_step UpdateScroll {cow 112 16; wr 0xC016 7} {
    expect top_moves_with_map [rd 0xC022] 24; expect map [rd 0xC017] 137
}
case cow_waits_between_scroll_steps UpdateScroll {cow 112 16; wr 0xC016 2} {expect y [rd 0xC022] 16}
case cow_pauses_at_station UpdateScroll {cow 112 16; wr 0xC016 7; wr 0xC050 1} {expect y [rd 0xC022] 16}
case cheese_header DrawHUD {wr 0xC058 0x12; wr 0xC050 1} {
    expect label [debug read_block VRAM [expr {0x1800+32+18}] 8] "QUEIJOS "
    expect count [debug read_block VRAM [expr {0x1800+32+26}] 2] "12"
}
case bonus_begins_without_awarding BeginCheeseBonus {wr 0xC058 3} {
    expect state [rd 0xC000] 7; expect waiting_cheeses [rd 0xC058] 3; expect score [bcd] 00000000
}
case bonus_converts_one CheeseBonusTick {wr 0xC000 7; wr 0xC058 3} {
    expect remaining [rd 0xC058] 2; expect score [bcd] 00000100
    expect bonus [binary encode hex [debug read_block memory 0xC077 4]] 00000100
    expect tick_sound [rd 0xC01C] 4
}
case bonus_waits_between_ticks CheeseBonusTick {wr 0xC000 7; wr 0xC058 3; wr 0xC084 2} {
    expect remaining [rd 0xC058] 3; expect score [bcd] 00000000
}
case bonus_bcd_countdown CheeseBonusTick {wr 0xC000 7; wr 0xC058 0x10} {expect nine [rd 0xC058] 9}
case bonus_handles_score_carry CheeseBonusTick {wr 0xC000 7; wr 0xC058 1; wr 0xC00A 0x99} {expect score [bcd] 00010000}
case empty_bonus_finishes_once CheeseBonusTick {wr 0xC000 7; wr 0xC058 0} {
    expect done [rd 0xC085] 1; expect hold [rd 0xC063] 75; expect score [bcd] 00000000
}
case bonus_then_next_stage CheeseBonusTick {wr 0xC000 7; wr 0xC085 1; wr 0xC063 1; wr 0xC064 0} {
    expect stage [rd 0xC060] 2; expect card [rd 0xC000] 3
}
case final_bonus_then_bus CheeseBonusTick {wr 0xC000 7; wr 0xC060 3; wr 0xC085 1; wr 0xC063 1; wr 0xC064 0} {expect ending [rd 0xC000] 5}
case warning_alternates UpdateFuelAlert {wr 0xC04E 15; wr 0xC087 1} {
    expect other_note [debug read {PSG regs} 4] 128; expect loud [debug read {PSG regs} 10] 15
}
case warning_preserves_pitch_during_gap UpdateFuelAlert {wr 0xC04E 15; wr 0xC052 10; wr 0xC087 1} {expect pitch [rd 0xC087] 1}
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
