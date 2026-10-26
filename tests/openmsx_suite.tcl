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
proc expect_glyph {x y code} {
    for {set row 0} {$row<8} {incr row} {
        set py [expr {$y+$row}]
        set addr [expr {($py/8)*256+$x*8+$py%8}]
        expect glyph_row_$row [debug read VRAM $addr] [rd [expr {$::sym(TilePatterns)+$code*8+$row}]]
    }
}
proc prepare {} {
    keymatrixup 8 255
    keymatrixup 7 255
    set f [open resources/generated/route2.bin rb]
    fconfigure $f -translation binary
    debug write_block memory 0xD000 [read $f]
    close $f
    debug write memory 0x7000 2
    debug write memory 0x7800 3
    foreach {a v} {0xC000 1 0xC004 120 0xC005 128 0xC006 5 0xC007 0 0xC015 0 0xC018 64 0xC017 138 0xC04E 100 0xC04F 0 0xC050 0 0xC052 0 0xC053 0 0xC054 0 0xC055 0 0xC056 0 0xC057 48 0xC058 0 0xC01C 0 0xC01D 0 0xC01E 0 0xC059 0 0xC05A 0 0xC05B 0 0xC05C 0 0xC05D 0 0xC05E 0 0xC060 2 0xC061 1 0xC062 1 0xC063 0 0xC064 0 0xC065 12 0xC066 120 0xC067 0 0xC068 24 0xC069 0 0xC06A 0 0xC06B 0 0xC06C 120 0xC06D 0 0xC077 0 0xC078 0 0xC079 0 0xC07A 0 0xC084 0 0xC085 0 0xC086 0 0xC087 0 0xC08F 0 0xC090 0 0xC099 0 0xC09A 0 0xC09E 0 0xC0AC 0 0xC0B6 0 0xC0B7 0 0xC0B8 0 0xC0B9 0 0xC0BA 0 0xC0BB 0 0xC0BC 0 0xC0BD 0 0xC0BE 0 0xC0BF 0 0xC0C0 0 0xC0C1 0 0xC0C2 0 0xC0C3 0 0xC0C4 0 0xC0C5 0 0xC0C6 0 0xC0C7 0 0xC0C8 0 0xC0C9 0 0xC0CA 0 0xC0CB 0 0xC0CC 0 0xC0CD 0 0xC0CE 0 0xC0CF 0 0xC0D0 0 0xC0D1 0 0xC0D2 0 0xC0D3 0 0xC0D4 0 0xC0D5 0 0xC0D6 0 0xC0D7 0} {wr $a $v}
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
case reset ResetGame {wr 0xC006 1} {
    expect state [rd 0xC000] 13
    expect lives [rd 0xC006] 5
    expect carX [rd 0xC004] 120
    expect carY [rd 0xC005] 128
    expect score [bcd] 00000000
}
foreach {name mask dx dy} {up 32 0 -1 upright 160 2 -1 right 128 2 0 downright 192 2 1 down 64 0 1 downleft 80 -2 1 left 16 -2 0 upleft 48 -2 -1} {
    case $name MovePlayer [list keymatrixdown 8 $mask] "expect x \[rd 0xC004\] [expr {120+$dx}]; expect y \[rd 0xC005\] [expr {128+$dy}]"
}
case clamp_top_right MovePlayer {wr 0xC004 208; wr 0xC005 32; keymatrixdown 8 160} {
    expect x [rd 0xC004] 128; expect y [rd 0xC005] 32
}
case clamp_bottom_left MovePlayer {wr 0xC004 32; wr 0xC005 160; keymatrixdown 8 80} {
    expect x [rd 0xC004] 80; expect y [rd 0xC005] 160
}
case horn_scares ScareCowsAhead {cow 100 80} {
    expect scared [rd 0xC024] 1
    expect points [bcd] 00000100
    expect lives [rd 0xC006] 5
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
    expect lives [rd 0xC006] 4; expect invulnerability [rd 0xC007] 100
}
case invulnerability CheckHits {cow 112 128; wr 0xC007 50} {
    expect lives [rd 0xC006] 5; expect invulnerability [rd 0xC007] 50
}
case third_hit_gameover CheckHits {
    cow 112 128; wr 0xC006 1
    debug write VRAM 0x18AC 130
} {
    expect state [rd 0xC000] 2; expect lives [rd 0xC006] 0
    expect world_preserved [debug read VRAM 0x18AC] 130
    expect centered_message [debug read_block VRAM [expr {0x1800+11*32+11}] 9] "GAME OVER"
    expect last_heart_off [debug read VRAM 0x181D] 141
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
    expect state [rd 0xC000] 13; expect lives [rd 0xC006] 5
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
    expect active [rd 0xC020] 1; expect x [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters1)+140}]]-8}]; expect y [rd 0xC022] 16
}
case spawn_left UpdateCows {wr 0xC018 1; wr 0xC019 1} {
    expect active [rd 0xC020] 1; expect x [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters1)+140}]]-8}]; expect dir [rd 0xC023] 1
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
foreach lives {0 1 2 3 4 5} {
    case hearts_$lives DrawHUD [list wr 0xC006 $lives] "
        for {set i 0} {\$i<5} {incr i} {
            expect heart_\$i \[debug read VRAM \[expr {0x181B+\$i}\]\] \[expr {\$i<$lives ? 140 : 141}\]
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
case filling_pauses_scroll UpdateScroll {wr 0xC050 1; wr 0xC016 7} {expect maprow [rd 0xC017] 138}
case route_does_not_wrap UpdateScroll {wr 0xC017 0; wr 0xC016 7} {expect maprow [rd 0xC017] 0}
case bridge_safe UpdateJourney {wr 0xC017 68} {expect lives [rd 0xC006] 5}
case river_collision UpdateJourney {wr 0xC060 2; wr 0xC017 68; wr 0xC004 72} {
    expect lives [rd 0xC006] 5; expect wall_x [rd 0xC004] 120
}
case narrow_road_wall UpdateJourney {wr 0xC060 2; wr 0xC017 110; wr 0xC004 32} {expect lives [rd 0xC006] 5; expect wall_x [rd 0xC004] 80}
case arrival UpdateJourney {wr 0xC017 0; wr 0xC005 80} {
    expect state [rd 0xC000] 11
    expect current_stage [rd 0xC060] 2
}
case destination_requires_driveway UpdateJourney {wr 0xC017 0} {expect state [rd 0xC000] 1}
foreach stone {232 233 234} {
    case arrival_on_stone_$stone UpdateJourney "wr 0xC017 0; wr 0xC005 80; wr [expr {0xD000+11*32+16}] $stone" {expect arrival [rd 0xC000] 11}
}
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
case continue_hidden_before_first_game ShowMenu {} {
    expect locked [rd 0xC0C0] 0
    for {set row 112} {$row<120} {incr row} {
        expect blank [debug read_block VRAM [expr {$row*128+76}] 36] [string repeat [binary format c $::sym(TITLE_PLAY_BACKGROUND)] 36]
    }
}
case continue_visible_after_playing ShowMenu {wr 0xC0C0 1} {
    expect play_selected [rd 0xC0C2] 0
    for {set row 0} {$row<8} {incr row} {
        expect text [debug read_block VRAM [expr {(112+$row)*128+79}] 33] [debug read_block memory [expr {$::sym(TitleContinueOn)+$row*36+3}] 33]
    }
}
case continue_select_down UpdateTitleSelection {wr 0x7000 4; wr 0x7800 5; wr 0xC0C0 1; keymatrixdown 8 64} {
    expect continue [rd 0xC0C2] 1; expect held [rd 0xC0C3] 1
}
case play_select_up UpdateTitleSelection {wr 0x7000 4; wr 0x7800 5; wr 0xC0C0 1; wr 0xC0C2 1; keymatrixdown 8 32} {expect play [rd 0xC0C2] 0}
case menu_held_direction_no_repeat UpdateTitleSelection {wr 0xC0C0 1; wr 0xC0C3 1; keymatrixdown 8 64} {expect still_play [rd 0xC0C2] 0}
case continue_locked_before_play UpdateTitleSelection {keymatrixdown 8 64} {expect play [rd 0xC0C2] 0}
case stage_saves_continue_checkpoint BeginStage {wr 0xC060 2; wr 0xC00A 18} {
    expect unlocked [rd 0xC0C0] 1; expect stage [rd 0xC0C1] 2
    expect score [binary encode hex [debug read_block memory 0xC0C4 4]] 00001200
}
case continue_retries_saved_stage MenuTick {
    wr 0xC000 0; wr 0xC01A 1; wr 0xC0C0 1; wr 0xC0C2 1; wr 0xC0C1 2
    wr 0xC0C6 18; wr 0xC006 0; wr 0xC058 9; keymatrixdown 7 128
} {
    expect card [rd 0xC000] 3; expect stage [rd 0xC060] 2; expect lives [rd 0xC006] 5
    expect score [bcd] 00001200; expect cheese_reset [rd 0xC058] 0
}
case play_still_starts_fresh MenuTick {
    wr 0xC000 0; wr 0xC01A 1; wr 0xC0C0 1; wr 0xC0C1 3; wr 0xC0C2 0
    wr 0xC00A 18; keymatrixdown 8 1
} {expect prologue [rd 0xC000] 13; expect stage [rd 0xC060] 0; expect score [bcd] 00000000}
case dark_brown_stone_mode SetupGameVideo {} {
    expect opaque_background_zero [expr {[debug read {VDP regs} 8]&32}] 32
    expect black_border [debug read {VDP regs} 7] 1
}
case title_to_game ResetGame {} {
    expect mode [rd 0xFCAF] 4
    expect height [expr {[debug read {VDP regs} 9]&128}] 0
    expect text_canvas [debug read_block VRAM 0 6144] [string repeat [binary format c 0] 6144]
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
case gauge_empty DrawFuel {wr 0xC04E 0} {expect needle [debug read VRAM 0x1827] 177}
case gauge_full DrawFuel {wr 0xC04E 100} {expect needle [debug read VRAM 0x1830] 176}
case gauge_half DrawFuel {wr 0xC04E 50} {expect needle [debug read VRAM 0x182C] 169}
case cheese_spawn ScrollRoadCheese {wr 0xC017 136} {
    expect active [rd 0xC053] 1; expect y [rd 0xC055] 16
    expect edge [rd 0xC054] [rd [expr {$::sym(RoadBounds)+136*2}]]
}
case cheese_collect UpdateCheese {wr 0xC053 1; wr 0xC054 120; wr 0xC055 120} {
    expect removed [rd 0xC053] 0; expect count [rd 0xC058] 1
    expect pending_bonus_not_score [bcd] 00000000; expect lives [rd 0xC006] 5
}
case cheese_stays_on_ground UpdateCheese {wr 0xC053 1; wr 0xC054 120; wr 0xC055 64; wr 0xC001 8} {
    expect y [rd 0xC055] 64; expect phase [rd 0xC056] 0; expect x [rd 0xC054] 120
}
case cheese_exits ScrollRoadCheese {wr 0xC053 1; wr 0xC054 40; wr 0xC055 176; wr 0xC001 8} {
    expect active [rd 0xC053] 0; expect lives [rd 0xC006] 5
}
case cheese_moves_with_scroll UpdateScroll {wr 0xC053 1; wr 0xC054 104; wr 0xC055 64; wr 0xC016 7} {
    expect y [rd 0xC055] 72; expect fixed_x [rd 0xC054] 104
}
case cheese_stops_at_station UpdateScroll {wr 0xC053 1; wr 0xC054 104; wr 0xC055 64; wr 0xC016 7; wr 0xC050 1} {expect y [rd 0xC055] 64}
case cheese_waits_between_scrolls UpdateScroll {wr 0xC053 1; wr 0xC055 64; wr 0xC016 0} {expect y [rd 0xC055] 64}
case cheese_uses_opposite_edge ScrollRoadCheese {wr 0xC017 104} {expect x [rd 0xC054] [rd [expr {$::sym(RoadBounds)+104*2+1}]]}
case no_cheese_respawn_without_scroll UpdateCheese {wr 0xC017 136; wr 0xC057 0} {expect absent [rd 0xC053] 0}
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
    expect phase [rd 0xC059] 3; expect clock [rd 0xC05A] 32
    expect long_a [rd 0xC01C] 32; expect long_b [rd 0xC01D] 32
    expect volume_a [debug read {PSG regs} 8] 10
    expect volume_b [debug read {PSG regs} 9] 8
}
case horn_long_finishes UpdateSound {
    wr 0xC059 3; wr 0xC05A 1; wr 0xC01C 1; wr 0xC01D 1
} {
    expect phase [rd 0xC059] 0
    expect backing_resumes [debug read {PSG regs} 8] 6
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
case spawn_matches_curve UpdateCows {wr 0xC060 2; wr 0xC017 70; wr 0xC018 1} {
    expect active [rd 0xC020] 1
    expect center [rd 0xC021] [expr {[debug read memory [expr {$::sym(RoadCenters)+72}]]-8}]
    expect waiting [rd 0xC024] 0
}
case music_starts UpdateMusic {} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 320
    expect backing [expr {[debug read {PSG regs} 0]+256*[debug read {PSG regs} 1]}] 508
    expect backing_volume [debug read {PSG regs} 8] 6
    expect music_volume [debug read {PSG regs} 10] 9
    expect next_note [rd 0xC05B] 1; expect duration [rd 0xC05C] 16
}
case music_advances UpdateMusic {wr 0xC05B 2; wr 0xC05C 1; wr 0xC05D 64; wr 0xC05E 1} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 285
    expect next_note [rd 0xC05B] 3; expect duration [rd 0xC05C] 4
}
case music_loops_with_rest UpdateMusic {wr 0xC05B [expr {$::sym(MUSIC_NOTE_COUNT)-1}]} {
    expect loop [rd 0xC05B] 0; expect rest_duration [rd 0xC05C] 3
    expect lead_silence [debug read {PSG regs} 10] 0; expect backing_silence [debug read {PSG regs} 8] 0
}
case battle_switch_resets_long_road_index UpdateMusic {wr 0xC000 4; wr 0xC05B 100; wr 0xC05C 8; wr 0xC0CC 252; wr 0xC0CD 1} {
    expect mode [rd 0xC0CB] 1; expect next [rd 0xC05B] 1
    expect battle [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 428
    expect backing_mute [debug read {PSG regs} 8] 0
}
case road_switch_restarts_excerpt UpdateMusic {wr 0xC0CB 1; wr 0xC05B 31; wr 0xC05C 6} {
    expect mode [rd 0xC0CB] 0; expect next [rd 0xC05B] 1
    expect lead [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 320
    expect backing_volume [debug read {PSG regs} 8] 6
}
case backing_yields_to_horn UpdateMusic {wr 0xC059 1; wr 0xC05C 8; wr 0xC0CC 252; wr 0xC0CD 1; debug write {PSG regs} 8 13; debug write {PSG regs} 0 75; debug write {PSG regs} 1 1} {
    expect horn_volume [debug read {PSG regs} 8] 13; expect horn_pitch [expr {[debug read {PSG regs} 0]+256*[debug read {PSG regs} 1]}] 331
}
case backing_yields_to_effect UpdateMusic {wr 0xC01C 3; wr 0xC05C 8; wr 0xC05D 64; wr 0xC05E 1; wr 0xC0CC 252; wr 0xC0CD 1; debug write {PSG regs} 8 12} {
    expect effect_volume [debug read {PSG regs} 8] 12; expect lead_volume [debug read {PSG regs} 10] 9
}
case backing_resumes_after_effect UpdateSound {wr 0xC01C 1; wr 0xC05C 8; wr 0xC05D 64; wr 0xC05E 1; wr 0xC0CC 252; wr 0xC0CD 1} {
    expect effect_done [rd 0xC01C] 0; expect backing_volume [debug read {PSG regs} 8] 6
    expect backing_pitch [expr {[debug read {PSG regs} 0]+256*[debug read {PSG regs} 1]}] 508
}
case stop_mutes_both_music_voices StopMusic {debug write {PSG regs} 8 6; debug write {PSG regs} 10 9; wr 0xC0CC 252; wr 0xC0CD 1} {
    expect backing_off [debug read {PSG regs} 8] 0; expect lead_off [debug read {PSG regs} 10] 0
    expect backing_cleared [rd 0xC0CC] 0
}
case music_resumes_after_effect UpdateSound {wr 0xC01E 1; wr 0xC05C 8; wr 0xC05D 214} {
    expect period [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 214
    expect music_volume [debug read {PSG regs} 10] 9; expect timer [rd 0xC05C] 7
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
case road_note_holds_until_its_release UpdateMusic {wr 0xC05C 3; wr 0xC05D 214} {
    expect sustained [debug read {PSG regs} 10] 9; expect timer [rd 0xC05C] 2
}
after realtime 10 {
    set f [open /tmp/sebollas-timeout.txt w]
    puts $f "index=$::index PC=[reg PC] SP=[reg SP] reports=$::reports"
    close $f
    exit
}
case horn_sequence_start SoundHorn {} {
    expect duration [rd 0xC01C] 6
    expect volume [debug read {PSG regs} 8] 10
    expect tone [expr {[debug read {PSG regs} 0]+256*[debug read {PSG regs} 1]}] 335
    expect metallic_tone [expr {[debug read {PSG regs} 2]+256*[debug read {PSG regs} 3]}] 36
    expect softer_metallic_layer [debug read {PSG regs} 9] 8
    expect dual_duration [rd 0xC01D] 6
    expect horn_phase [rd 0xC059] 1
    expect short_clock [rd 0xC05A] 6
}
case sound_finishes UpdateSound {wr 0xC01C 1} {
    expect duration [rd 0xC01C] 0
    expect backing_resumes [debug read {PSG regs} 8] 6
}
case invulnerability_expires MovePlayer {wr 0xC007 1} {expect timer [rd 0xC007] 0}
case waiting_does_not_scroll UpdateScroll {wr 0xC061 0; wr 0xC016 7} {expect map [rd 0xC017] 138}
case waiting_does_not_consume UpdateJourney {wr 0xC061 0; wr 0xC04F 5} {expect tank [rd 0xC04E] 100}
case waiting_has_no_cows UpdateCows {wr 0xC061 0; wr 0xC018 1} {expect active [rd 0xC020] 0}
case play_space_does_not_drive CheckDriveStart {wr 0xC061 0; wr 0xC062 0; keymatrixdown 8 1} {expect stopped [rd 0xC061] 0}
case idle_does_not_start CheckDriveStart {wr 0xC061 0; wr 0xC062 0} {expect stopped [rd 0xC061] 0}
case arrows_start_drive CheckDriveStart {wr 0xC061 0; keymatrixdown 8 128} {expect moving [rd 0xC061] 1}
case space_alone_keeps_waiting CheckDriveStart {wr 0xC061 0; wr 0xC062 1; keymatrixdown 8 1} {expect stopped [rd 0xC061] 0}
foreach stage {0 1 2 3} {
    case preserve_lives_stage_$stage BeginStage "wr 0xC060 $stage; wr 0xC006 2" {expect remaining [rd 0xC006] 2}
}
case preserve_lives_canearena BeginCaneChallenge {wr 0xC060 1; wr 0xC006 2} {expect remaining [rd 0xC006] 2}
case preserve_lives_cheeseboss BeginBoss {wr 0xC060 3; wr 0xC006 1} {expect remaining [rd 0xC006] 1}
case stage_two_follows_one AdvanceStage {wr 0xC060 1} {expect stage [rd 0xC060] 2; expect card [rd 0xC000] 3}
case stage_three_follows_two AdvanceStage {wr 0xC060 2} {expect stage [rd 0xC060] 3; expect card [rd 0xC000] 3}
case stage_card_shows_intro CampaignTick {wr 0xC000 3; wr 0xC060 2; wr 0xC063 1; wr 0xC064 0; wr 0xC00A 1} {
    expect illustration [rd 0xC000] 10; expect stage [rd 0xC060] 2
    expect timer [rd 0xC063] 250
    set f [open resources/generated/intro2.bin rb]; fconfigure $f -translation binary
    expect pixels [debug read_block VRAM 0 54272] [read $f]; close $f
    expect score_kept [bcd] 00000100
}
case intro_resumes_game StageIntroTick {wr 0xC000 10; wr 0xC060 2; wr 0xC063 1; wr 0xC064 0} {
    expect road [rd 0xC000] 1; expect video [rd 0xFCAF] 4
    expect waits_for_movement [rd 0xC061] 0; expect fuel [rd 0xC04E] 100
}
case car_route_cow_delay CowSpawnDelay {} {expect delay [reg A] 80}
case phase_two_cow_delay CowSpawnDelay {wr 0xC060 2} {expect delay [reg A] 80}
case phase_three_cow_delay CowSpawnDelay {wr 0xC060 3} {expect delay [reg A] 32}
case phase_three_opens_boss CompleteStage {wr 0xC060 3} {expect fight [rd 0xC000] 4; expect health [rd 0xC065] 12}
case boss_needs_many_honks BossTakeHit {wr 0xC000 4; wr 0xC005 136} {expect fight [rd 0xC000] 4; expect health [rd 0xC065] 11}
case long_horn_is_one_hit BossTick {wr 0xC000 4; wr 0xC005 136; wr 0xC059 3; wr 0xC05A 12; keymatrixdown 8 1} {expect health [rd 0xC065] 12}
case last_honk_wins BossTakeHit {wr 0xC000 4; wr 0xC005 136; wr 0xC065 1; wr 0xC060 3} {expect still_visible [rd 0xC000] 4; expect defeated [rd 0xC065] 0; expect blinking [rd 0xC090] 1; expect pause [rd 0xC06D] 75}
case garapa_throws_cane UpdateCane {wr 0xC000 4; wr 0xC068 0; wr 0xC066 132} {
    expect active [rd 0xC069] 1; expect x [rd 0xC06A] 132; expect y [rd 0xC06B] 64
}
case cane_takes_one_heart UpdateCane {wr 0xC000 4; wr 0xC005 136; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128} {
    expect lives [rd 0xC006] 4; expect protection [rd 0xC007] 100; expect consumed [rd 0xC069] 0
}
case cane_respects_protection UpdateCane {wr 0xC000 4; wr 0xC005 136; wr 0xC007 50; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128} {expect lives [rd 0xC006] 5}
case car_parks_for_ending EndingTick {wr 0xC000 5; wr 0xC06E 0; wr 0xC005 135; wr 0xC072 255; wr 0xC073 255; wr 0xC074 255} {expect parked_y [rd 0xC005] 136}
case small_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 19; wr 0xC070 0; wr 0xC071 20; wr 0xC072 255; wr 0xC073 255; wr 0xC074 255} {expect small [rd 0xC072] 96; expect tall_waits [rd 0xC073] 255}
case tall_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 44; wr 0xC070 0; wr 0xC071 20; wr 0xC072 254; wr 0xC073 255; wr 0xC074 255} {expect tall [rd 0xC073] 120}
case big_boy_exits EndingTick {wr 0xC000 5; wr 0xC06E 1; wr 0xC06F 69; wr 0xC070 0; wr 0xC071 20; wr 0xC072 254; wr 0xC073 254; wr 0xC074 255} {expect big [rd 0xC074] 144}
case bus_is_clipped DrawBusRoad {wr 0xC071 30} {
    expect destination [debug read VRAM [expr {0x1800+11*32+30}]] 78
    expect no_wrap [debug read VRAM [expr {0x1800+12*32}]] 157
}
case boys_board_the_bus EndingTick {wr 0xC000 5; wr 0xC06E 5; wr 0xC06F 200; wr 0xC070 0; wr 0xC071 33; wr 0xC072 254; wr 0xC073 254; wr 0xC074 254} {expect boarded [rd 0xC06E] 2; expect pause [rd 0xC063] 80}
case ending_reaches_first_art BeginEndingArt {} {
    set f [open resources/generated/ending1.bin rb]
    fconfigure $f -translation binary
    expect pixels [debug read_block VRAM 0 54272] [read $f]
    close $f
    expect image [rd 0xC000] 8
    expect timer [rd 0xC063] 250
    expect screen [rd 0xFCAF] 8
}
case first_art_holds EndingArtTick {wr 0xC000 8; wr 0xC063 2; wr 0xC064 0} {
    expect image [rd 0xC000] 8; expect timer [rd 0xC063] 1
}
case first_art_then_second_art EndingArtTick {wr 0xC000 8; wr 0xC063 1; wr 0xC064 0} {
    expect second_image [rd 0xC000] 9; expect timer [rd 0xC063] 250
    set f [open resources/generated/ending2.bin rb]; fconfigure $f -translation binary
    expect pixels [debug read_block VRAM 0 54272] [read $f]; close $f
}
case boys_wait_then_bus EndingTick {wr 0xC000 5; wr 0xC06E 3; wr 0xC063 1; wr 0xC064 0} {
    expect cinematic [rd 0xC000] 5; expect bus_phase [rd 0xC06E] 4
}
case second_art_holds EndingArtTick {wr 0xC000 9; wr 0xC063 2; wr 0xC064 0} {
    expect image [rd 0xC000] 9; expect timer [rd 0xC063] 1
}
case chase_to_credits EndingTick {wr 0xC000 5; wr 0xC06E 2; wr 0xC063 1; wr 0xC064 0} {
    expect screen [rd 0xFCAF] 4
    expect credits [rd 0xC000] 6
    expect blank_patterns [debug read_block VRAM 0 6144] [string repeat [binary format c 0] 6144]
    expect pointer [expr {[rd 0xC075]+256*[rd 0xC076]}] $::sym(CreditSequence)
}
case second_art_then_car EndingArtTick {wr 0xC000 9; wr 0xC063 1; wr 0xC064 0} {
    expect cinematic [rd 0xC000] 5; expect phase [rd 0xC06E] 0
    expect car [rd 0xC005] 120; expect waiting_boys [rd 0xC072] 255
    expect no_victory_text [expr {[debug read_block VRAM 0x1867 17] ne "VENCEMOS O QUEIJO!"}] 1
}
foreach state {8 9} {
    case music_during_image_$state UpdateMusic [list wr 0xC000 $state] {
        expect volume [debug read {PSG regs} 10] 9; expect note [rd 0xC05B] 1
    }
}
case cheese_pair_spawn UpdateCane {wr 0xC000 4; wr 0xC060 3; wr 0xC068 0} {
    expect first [rd 0xC069] 1; expect second [rd 0xC0BB] 1
    expect left [rd 0xC06A] 110; expect right [rd 0xC0BC] 130
    expect target1 [rd 0xC06C] 108; expect target2 [rd 0xC0BE] 132
}
case second_cheese_hits UpdateCane {wr 0xC000 4; wr 0xC060 3; wr 0xC0BB 1; wr 0xC0BC 120; wr 0xC0BD 120; wr 0xC001 1} {
    expect lives [rd 0xC006] 4; expect removed [rd 0xC0BB] 0
}
case cheese_pair_moves UpdateCane {wr 0xC000 4; wr 0xC060 3; wr 0xC069 1; wr 0xC06B 64; wr 0xC0BB 1; wr 0xC0BD 64} {
    expect first_y [rd 0xC06B] 67; expect second_y [rd 0xC0BD] 67
}
case cheese_pair_sprite_budget BuildBossSprites {wr 0xC000 4; wr 0xC060 3; wr 0xC069 1; wr 0xC06A 110; wr 0xC06B 64; wr 0xC0BB 1; wr 0xC0BC 130; wr 0xC0BD 64} {
    expect slots [rd 0xC040] 19
    set counts [lrepeat 192 0]
    for {set s 0} {$s<[rd 0xC040]} {incr s} {
        set y [expr {[rd [expr {0xC100+$s*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {lset counts $line [expr {[lindex $counts $line]+1}]}
    }
    expect max_per_line [lindex [lsort -integer $counts] end] 8
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
    expect label [debug read_block VRAM [expr {0x1800+32+22}] 8] "QUEIJOS "
    expect count [debug read_block VRAM [expr {0x1800+32+30}] 2] "12"
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
case bonus_then_next_stage CheeseBonusTick {wr 0xC060 1; wr 0xC000 7; wr 0xC085 1; wr 0xC063 1; wr 0xC064 0} {
    expect stage [rd 0xC060] 2; expect card [rd 0xC000] 3
}
case final_bonus_then_images CheeseBonusTick {wr 0xC000 7; wr 0xC060 3; wr 0xC085 1; wr 0xC063 1; wr 0xC064 0} {expect ending [rd 0xC000] 8}
case warning_alternates UpdateFuelAlert {wr 0xC04E 15; wr 0xC087 1} {
    expect other_note [debug read {PSG regs} 4] 128; expect loud [debug read {PSG regs} 10] 15
}
case warning_preserves_pitch_during_gap UpdateFuelAlert {wr 0xC04E 15; wr 0xC052 10; wr 0xC087 1} {expect pitch [rd 0xC087] 1}
case prologue_starts_blank BeginPrologue {} {
    expect story [rd 0xC000] 13; expect pending [rd 0xC0BF] 0
    expect blank [debug read_block VRAM 0 6144] [string repeat [binary format c 0] 6144]
}
case prologue_types_and_clacks RevealCreditLetter {
    wr 0xC000 13; wr 0xC088 0; wr 0xC089 0; wr 0xC08A 0
    wr 0xC075 [expr {$::sym(PrologueSequence)&255}]; wr 0xC076 [expr {$::sym(PrologueSequence)>>8}]
    debug write_block VRAM 0x18A6 [string repeat " " 19]
} {
    expect_glyph 6 40 69
    expect noise_mixer [debug read {PSG regs} 7] 177
    expect clack_volume [debug read {PSG regs} 8] 11; expect short [rd 0xC01C] 1
}
case prologue_clack_expires UpdateSound {wr 0xC000 13; wr 0xC01C 1; debug write {PSG regs} 7 177; debug write {PSG regs} 8 11} {
    expect silent [debug read {PSG regs} 8] 0; expect mixer [debug read {PSG regs} 7] 184
}
case prologue_completion_holds RevealCreditLetter {
    wr 0xC000 13; wr 0xC088 0; wr 0xC089 0; wr 0xC08A 0
    wr 0xC075 240; wr 0xC076 192; wr 0xC0F0 255
} {expect done [rd 0xC0BF] 1; expect five_seconds [rd 0xC063] 250}
case prologue_holds_readable PrologueTick {wr 0xC000 13; wr 0xC0BF 1; wr 0xC063 2; wr 0xC064 0} {
    expect story [rd 0xC000] 13; expect remaining [rd 0xC063] 1
}
case prologue_then_fishing_card PrologueTick {wr 0xC000 13; wr 0xC060 0; wr 0xC0BF 1; wr 0xC063 1; wr 0xC064 0} {
    expect card [rd 0xC000] 3; expect fishing [debug read_block VRAM 0x192A 11] "INDO PESCAR"
}
case credits_remain_silent RevealCreditLetter {
    wr 0xC000 6; wr 0xC088 0; wr 0xC089 0; wr 0xC08A 0
    wr 0xC075 [expr {$::sym(CreditSequence)&255}]; wr 0xC076 [expr {$::sym(CreditSequence)>>8}]
    debug write {PSG regs} 8 0
} {expect no_clack [rd 0xC01C] 0; expect volume [debug read {PSG regs} 8] 0}
case credit_first_character RevealCreditLetter {
    wr 0xC075 [expr {$::sym(CreditSequence)&255}]; wr 0xC076 [expr {$::sym(CreditSequence)>>8}]
    wr 0xC088 0; wr 0xC089 0; wr 0xC08A 0
    debug write_block VRAM 0x182C [string repeat " " 8]
} {
    expect_glyph 12 8 67
    expect delay [rd 0xC08A] 1
}
case prologue_second_line_adds_three_pixels RevealCreditLetter {
    wr 0xC000 13; wr 0xC075 240; wr 0xC076 192
    wr 0xC088 1; wr 0xC089 5; wr 0xC08A 0; wr 0xC0C8 1
    foreach {a v} {0xC0F0 0 0xC0F1 6 0xC0F2 2 0xC0F3 65 0xC0F4 0 0xC0F5 255} {wr $a $v}
} {expect y [rd 0xC0C9] 51; expect_glyph 2 51 65}
case text_crosses_vertical_bank RevealCreditLetter {
    wr 0xC075 240; wr 0xC076 192; wr 0xC088 0; wr 0xC089 0; wr 0xC08A 0; wr 0xC0C8 1
    foreach {a v} {0xC0F0 7 0xC0F1 5 0xC0F2 103 0xC0F3 0 0xC0F4 255} {wr $a $v}
} {expect y [rd 0xC0C9] 59; expect_glyph 5 59 103}
case credit_letter_gap RevealCreditLetter {wr 0xC08A 1; wr 0xC075 10; wr 0xC076 192} {
    expect pointer [rd 0xC075] 10; expect delay [rd 0xC08A] 0
}
case credit_new_line RevealCreditLetter {
    set addr [expr {$::sym(CreditLines)-1}]
    wr 0xC075 [expr {$addr&255}]; wr 0xC076 [expr {$addr>>8}]
    wr 0xC088 1; wr 0xC089 24; wr 0xC08A 0; wr 0xC0C8 1
    debug write_block VRAM 0x1885 [string repeat " " 24]
} {expect_glyph 5 35 69}
case boss_left_wall ClampCarToRoad {wr 0xC000 4; wr 0xC004 32} {expect x [rd 0xC004] 64; expect lives [rd 0xC006] 5}
case boss_right_wall ClampCarToRoad {wr 0xC000 4; wr 0xC004 250} {expect x [rd 0xC004] 240; expect lives [rd 0xC006] 5}
case no_start_prompt BeginStage {} {
    expect no_prompt [debug read_block VRAM [expr {0x1800+21*32+4}] 24] [debug read_block memory [expr {$::sym(WorldMap1)+(138+19)*32+4}] 24]
}
case stubborn_cow_ignores_horn ScareCowsAhead {cow 100 80; wr 0xC025 1} {
    expect parked [rd 0xC024] 0; expect score [bcd] 00000000
}
case third_cow_hears_horn ScareCowsAhead {
    foreach {a v} {0xC030 1 0xC031 100 0xC032 80 0xC034 0 0xC035 0} {wr $a $v}
} {expect leaving [rd 0xC034] 1}
case boss_blink_ends_in_escape BossDefeatTick {wr 0xC000 4; wr 0xC090 1; wr 0xC06D 1} {
    expect escaping [rd 0xC090] 2; expect still_boss [rd 0xC000] 4
}
case boss_runs_away BossDefeatTick {wr 0xC000 4; wr 0xC090 2; wr 0xC066 180} {expect x [rd 0xC066] 182}
case boss_leaves_before_bonus BossDefeatTick {wr 0xC000 4; wr 0xC090 2; wr 0xC066 238; wr 0xC060 3} {expect bonus [rd 0xC000] 7}
case boys_wait_outside EndingTick {wr 0xC000 5; wr 0xC06E 3; wr 0xC063 50; wr 0xC064 0; wr 0xC072 112; wr 0xC071 248} {
    expect boy [rd 0xC072] 112; expect bus_offscreen [rd 0xC071] 248; expect pause [rd 0xC063] 49
}
case bus_enters_from_left EndingTick {wr 0xC000 5; wr 0xC06E 4; wr 0xC071 255; wr 0xC001 0; wr 0xC072 112; wr 0xC073 120; wr 0xC074 112} {
    expect left [rd 0xC071] 0; expect waiting [rd 0xC072] 112
}
case boys_chase_passing_bus EndingTick {wr 0xC000 5; wr 0xC06E 4; wr 0xC071 18; wr 0xC001 1; wr 0xC072 112; wr 0xC073 120; wr 0xC074 112} {
    expect running [rd 0xC06E] 5; expect boy [rd 0xC072] 113
}
case phase_three_fourth_cow_stubborn UpdateCows {wr 0xC060 3; wr 0xC018 1; wr 0xC08F 3} {expect stubborn [rd 0xC025] 1}
case phase_three_three_cow_budget BuildSprites {
    cow 96 16
    foreach {a v} {0xC028 1 0xC029 96 0xC02A 64 0xC02B 0 0xC030 1 0xC031 96 0xC032 112 0xC033 0 0xC053 1 0xC054 120 0xC055 128} {wr $a $v}
} {
    expect slots [rd 0xC040] 32
    set counts [lrepeat 192 0]
    for {set slot 0} {$slot<32} {incr slot} {
        set y [expr {[rd [expr {0xC100+$slot*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {lset counts $line [expr {[lindex $counts $line]+1}]}
    }
    expect per_line [lindex [lsort -integer $counts] end] 8
}
case gameplay_has_no_stage_label DrawHUD {} {
    expect no_stage [debug read_block VRAM [expr {0x1800+17}] 6] "      "
}
case battle_music_starts UpdateMusic {wr 0xC000 4} {
    expect dramatic_tone [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 428
    expect quicker_notes [rd 0xC05C] 6
}
case bar_route_has_no_boss CompleteStage {wr 0xC060 2} {expect arrival [rd 0xC000] 11}
case fishing_meets_peaceful_garapa CompleteStage {wr 0xC060 0; wr 0xC017 0; wr 0xC005 96} {expect meeting [rd 0xC000] 11; expect no_projectile [rd 0xC069] 0}
case cheese_boss_uploads_shared_patterns LoadBossArt {wr 0xC060 3} {
    set f [open resources/generated/cheese_boss_patterns.bin rb]; fconfigure $f -translation binary
    expect boss_pixels [debug read_block VRAM [expr {0x3800+$::sym(BOSS_PATTERN)*8}] 256] [read $f]; close $f
    set f [open resources/generated/enemy_cheese_patterns.bin rb]; fconfigure $f -translation binary
    expect projectile_pixels [debug read_block VRAM [expr {0x3800+$::sym(CANE_PATTERN)*8}] 64] [read $f]; close $f
}
case garapa_restores_shared_patterns LoadBossArt {wr 0xC060 0} {
    set f [open resources/generated/sprites.bin rb]; fconfigure $f -translation binary
    seek $f [expr {$::sym(BOSS_PATTERN)*8}]
    expect restored [debug read_block VRAM [expr {0x3800+$::sym(BOSS_PATTERN)*8}] 320] [read $f 320]; close $f
}
case cheese_projectile_moves_faster UpdateCane {wr 0xC000 4; wr 0xC060 3; wr 0xC069 1; wr 0xC06B 64} {
    expect y [rd 0xC06B] 67
}
case cheese_fight_sprite_budget BuildBossSprites {wr 0xC000 4; wr 0xC060 3; wr 0xC005 80; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 64} {
    expect slots [rd 0xC040] 17
    set counts [lrepeat 192 0]
    for {set slot 0} {$slot<17} {incr slot} {
        set y [expr {[rd [expr {0xC100+$slot*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {lset counts $line [expr {[lindex $counts $line]+1}]}
    }
    expect per_line [lindex [lsort -integer $counts] end] 6
}
case battle_music_keeps_playing_during_horn UpdateMusic {wr 0xC000 4; wr 0xC059 1} {
    expect dramatic_tone [expr {[debug read {PSG regs} 4]+256*[debug read {PSG regs} 5]}] 428
    expect audible [debug read {PSG regs} 10] 9
}
case horn_reaches_full_volume ShapeHorn {wr 0xC059 3; wr 0xC05A 20; wr 0xC099 3} {
    expect main [debug read {PSG regs} 8] 13; expect metallic [debug read {PSG regs} 9] 11
    expect pitch [expr {[debug read {PSG regs} 0]+256*[debug read {PSG regs} 1]}] 331
}
case horn_tail_softens ShapeHorn {wr 0xC059 3; wr 0xC05A 1; wr 0xC099 31} {
    expect main [debug read {PSG regs} 8] 7; expect metallic [debug read {PSG regs} 9] 5
}
case horn_preserves_music_channel ShapeHorn {wr 0xC059 3; wr 0xC05A 20; wr 0xC099 6; debug write {PSG regs} 10 9; debug write {PSG regs} 4 170} {
    expect music_volume [debug read {PSG regs} 10] 9; expect music_pitch [debug read {PSG regs} 4] 170
}
case horn_preserves_refuel_channel ShapeHorn {
    wr 0xC050 1; wr 0xC059 3; wr 0xC05A 20; wr 0xC099 3; wr 0xC01D 3
    debug write {PSG regs} 2 120; debug write {PSG regs} 9 12
} {
    expect refuel_pitch [debug read {PSG regs} 2] 120
    expect refuel_volume [debug read {PSG regs} 9] 12
    expect refuel_timer [rd 0xC01D] 3
}
case horn_keeps_release_timers_in_sync ShapeHorn {wr 0xC059 3; wr 0xC05A 20; wr 0xC099 4; wr 0xC01C 0; wr 0xC01D 0} {
    expect timer_a [rd 0xC01C] 20; expect timer_b [rd 0xC01D] 20
}
case fuel_consumption_is_slower UpdateJourney {wr 0xC04F 5} {expect fuel [rd 0xC04E] 100; expect clock [rd 0xC04F] 6}
case boss_station_refills UpdateBossFuel {wr 0xC000 4; wr 0xC004 216; wr 0xC005 136; wr 0xC04E 20} {
    expect fuel [rd 0xC04E] 21; expect filling [rd 0xC050] 1
}
case boss_consumes_fuel UpdateBossFuel {wr 0xC000 4; wr 0xC04F 11; wr 0xC04E 20} {expect fuel [rd 0xC04E] 19}
case boss_empty_tank UpdateBossFuel {wr 0xC000 4; wr 0xC04F 11; wr 0xC04E 1} {expect gameover [rd 0xC000] 2}
case boss_station_keeps_combat_live BossTick {wr 0xC000 4; wr 0xC004 216; wr 0xC005 136; wr 0xC04E 20; wr 0xC001 0; wr 0xC066 120; wr 0xC067 0} {
    expect fuel [rd 0xC04E] 21; expect boss_moves [rd 0xC066] 122; expect fighting [rd 0xC000] 4
}
case boss_station_graphics DrawArenaStation {} {
    expect label [debug read_block VRAM [expr {0x1800+13*32+26}] 5] "POSTO"
    expect pump [debug read VRAM [expr {0x1800+14*32+28}]] 154
}
case final_stage_card ShowStageCard {wr 0xC060 3} {expect title [debug read_block VRAM [expr {0x1800+9*32+11}] 10] "FASE FINAL"}
case intro_waits_without_driving StageIntroTick {wr 0xC000 10; wr 0xC063 20; wr 0xC064 0; wr 0xC04E 42} {
    expect still_image [rd 0xC000] 10; expect fuel [rd 0xC04E] 42; expect timer [rd 0xC063] 19
}
case five_hearts_fill_hud DrawHUD {} {expect hearts [debug read_block VRAM 0x181B 5] [string repeat [format %c 140] 5]}
case fishing_has_no_horn SoundHorn {wr 0xC060 0} {expect quiet [rd 0xC059] 0}
case walking_has_no_horn UpdateHornInput {wr 0xC060 1; keymatrixdown 8 1} {expect quiet [rd 0xC059] 0}
case fishing_hud_is_hunger DrawFuel {wr 0xC060 0} {expect label [debug read_block VRAM 0x1821 4] "FOME"}
case no_cane_counter DrawCheeseHUD {wr 0xC060 1} {expect empty [debug read_block VRAM 0x1836 10] [string repeat " " 10]}
case walking_uploads_trio LoadWalkingArt {wr 0xC060 0} {
    set f [open resources/generated/trio_patterns.bin rb]; fconfigure $f -translation binary
    expect pixels [debug read_block VRAM 0x3800 256] [read $f]; close $f
    expect donkey_pixels [debug read_block VRAM 0x3900 512] [debug read_block memory $::sym(DonkeyPatterns) 512]
}
case walking_player_sprite BuildSprites {wr 0xC060 0} {expect group [rd 0xC040] 8}
case cow_crosses_walking_road UpdateWalkingCows {wr 0xC060 0; cow 70 70; wr 0xC004 200; wr 0xC001 0} {expect x [rd 0xC021] 71; expect no_chase [rd 0xC026] 0}
case nearby_cow_starts_five_second_chase UpdateWalkingCows {wr 0xC060 0; cow 112 112; wr 0xC004 112; wr 0xC001 0} {
    expect pursuing [rd 0xC026] 1; expect triggered [rd 0xC027] 1
}
case cow_chase_never_expires UpdateWalkingCows {
    wr 0xC060 0; cow 112 112; wr 0xC026 1; wr 0xC027 1
    set start [expr {([rd 0xFC9E]+256*[rd 0xFC9F]-([rd 0xC003] ? 300 : 250))&65535}]
    wr 0xC09B [expr {$start&255}]; wr 0xC09C [expr {$start>>8}]
} {expect pursuing [rd 0xC026] 1}
case cow_does_not_restart_chase UpdateWalkingCows {wr 0xC060 0; cow 112 112; wr 0xC026 0; wr 0xC027 1; wr 0xC001 0} {expect stopped [rd 0xC026] 0; expect crossing [rd 0xC021] 113}
case chasing_cow_tracks_screen UpdateScroll {wr 0xC060 0; cow 112 100; wr 0xC026 100; wr 0xC016 15} {expect y [rd 0xC022] 100}
case cane_challenge_has_boss CompleteStage {wr 0xC060 1} {
    expect challenge [rd 0xC000] 12; expect hp [rd 0xC065] 12
    expect question [debug read_block VRAM [expr {0x1800+3*32+6}] 19] "Voc[format %c 243]s tomam garapa?"
}
case enemy_cane_costs_life UpdateFriendlyCane {wr 0xC000 12; wr 0xC060 1; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 126; wr 0xC09A 0} {
    expect no_collection [rd 0xC058] 0; expect lives [rd 0xC006] 4; expect removed [rd 0xC069] 0
}
case walking_deck_graphics DrawArenaStation {wr 0xC060 1} {
    expect fishing [debug read_block VRAM [expr {0x1800+13*32+26}] 5] "PESCA"
    expect water [debug read VRAM [expr {0x1800+10*32+24}]] 145
    expect wood [debug read VRAM [expr {0x1800+14*32+24}]] 159
}
case peaceful_meeting_advances MeetingTick {wr 0xC000 11; wr 0xC060 0; wr 0xC063 1; wr 0xC064 0} {expect next [rd 0xC060] 1; expect card [rd 0xC000] 3}
case cane_challenge_ends_after_boss CaneChallengeTick {wr 0xC000 12; wr 0xC060 1; wr 0xC090 1; wr 0xC06D 1; wr 0xC065 0} {expect bonus [rd 0xC000] 7; expect defeated [rd 0xC065] 0}
case cane_uses_tiles_with_full_size_donkey BuildBossSprites {wr 0xC000 12; wr 0xC060 1; cow 112 100; wr 0xC004 112; wr 0xC005 128; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128} {expect slots [rd 0xC040] 16}
case cane_is_visible_with_scanline_space BuildBossSprites {wr 0xC000 12; wr 0xC060 1; cow 112 100; wr 0xC004 112; wr 0xC005 128; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 96} {expect slots [rd 0xC040] 16}
case bar_arrival_goes_to_bonus MeetingTick {wr 0xC000 11; wr 0xC060 2; wr 0xC063 1; wr 0xC064 0} {expect bonus [rd 0xC000] 7}
case fishing_starts_in_unnamed_house LoadStageMap {wr 0xC060 0} {
    expect house [rd [expr {0xD000+118*32+1}]] 148
    if {[debug read_block memory [expr {0xD000+117*32+1}] 4] eq "VAV[format %c 193]"} {error "unexpected Vava title"}
}
case final_stage_is_cheese_fight CompleteStage {wr 0xC060 3} {expect boss [rd 0xC000] 4; expect hp [rd 0xC065] 12}
case question_mark_is_uploaded LoadGraphics {} {
    set expected [debug read_block memory $::sym(QuestionMarkGlyph) 8]
    foreach bank {0 2048 4096} {expect glyph [debug read_block VRAM [expr {$bank+63*8}] 8] $expected}
}
case walking_can_descend_further MovePlayer {wr 0xC060 0; wr 0xC005 158; keymatrixdown 8 64} {expect y [rd 0xC005] 160}
case fishing_starts_on_shorter_route BeginStage {wr 0xC060 0} {
    expect shorter_start [rd 0xC017] 108; expect hunger [rd 0xC04E] 100
    expect home_visible [debug read VRAM 0x1981] 148
}
foreach station {42 86} {
    case fishing_deck_$station UpdateJourney "
        set f \[open resources/generated/route0.bin rb\]
        fconfigure \$f -translation binary
        debug write_block memory 0xD000 \[read \$f\]
        close \$f
        wr 0xC060 0; wr 0xC017 [expr {$station-17}]; wr 0xC004 168; wr 0xC04E 10
    " {expect fed [rd 0xC04E] 11; expect fishing [rd 0xC050] 1}
}
case walking_scroll_is_slower UpdateScroll {wr 0xC060 0; wr 0xC016 7} {expect row [rd 0xC017] 138; expect clock [rd 0xC016] 8}
case canes_begin_on_last_scroll UpdateScroll {wr 0xC060 1; wr 0xC017 1; wr 0xC016 15; wr 0xC004 64; wr 0xC005 160; wr 0xC006 2} {
    expect challenge [rd 0xC000] 12; expect road_finished [rd 0xC017] 0
    expect lives_carried [rd 0xC006] 2; expect goal [rd 0xC09A] 0
}
case canes_begin_at_road_end UpdateScroll {wr 0xC060 1; wr 0xC017 0; wr 0xC004 176; wr 0xC005 160} {expect challenge [rd 0xC000] 12}
case canes_wait_for_scroll_end UpdateJourney {wr 0xC060 1; wr 0xC017 3; wr 0xC004 112; wr 0xC005 80} {expect road [rd 0xC000] 1}
case canes_scroll_until_arrival UpdateScroll {wr 0xC060 1; wr 0xC017 2; wr 0xC016 15; wr 0xC005 160} {
    expect road [rd 0xC000] 1; expect row [rd 0xC017] 1
}
case fishing_still_needs_contact_at_end UpdateScroll {wr 0xC060 0; wr 0xC017 0; wr 0xC005 160} {expect peaceful_road [rd 0xC000] 1}
case second_walking_scroll_is_slower UpdateScroll {wr 0xC060 1; wr 0xC016 15} {expect row [rd 0xC017] 137}
case fishing_needs_contact CompleteStage {wr 0xC060 0; wr 0xC017 0; wr 0xC005 152} {expect playing [rd 0xC000] 1}
case garapa_enters_with_scroll RoadGarapaPosition {wr 0xC060 0; wr 0xC017 10} {expect top [rd 0xC09D] 16}
case garapa_follows_scroll RoadGarapaPosition {wr 0xC060 0; wr 0xC017 9} {expect y [rd 0xC09D] 24}
case garapa_waits_at_destination RoadGarapaPosition {wr 0xC060 0; wr 0xC017 0} {expect y [rd 0xC09D] 96}
case no_cane_timeout CaneChallengeTick {wr 0xC000 12; wr 0xC060 1; wr 0xC063 220; wr 0xC064 5; wr 0xC09A 29} {expect playing [rd 0xC000] 12; expect caught [rd 0xC09A] 29}
case enemy_cane_respects_invulnerability UpdateFriendlyCane {wr 0xC000 12; wr 0xC060 1; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 126; wr 0xC007 50} {expect lives [rd 0xC006] 5; expect removed [rd 0xC069] 0}
case enemy_cane_can_end_game UpdateFriendlyCane {wr 0xC000 12; wr 0xC060 1; wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 126; wr 0xC006 1} {expect gameover [rd 0xC000] 2; expect lives [rd 0xC006] 0}
case hundred_canes_bonus CheeseBonusTick {wr 0xC000 7; wr 0xC060 1; wr 0xC09E 1; wr 0xC058 0; wr 0xC084 0; wr 0xC085 0} {
    expect remaining [rd 0xC058] 153; expect hundred [rd 0xC09E] 0; expect score [bcd] 00000100
}
case herd_starts_with_one UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1} {expect level [rd 0xC0AC] 1; expect cow1 [rd 0xC020] 1; expect cow2 [rd 0xC028] 0}
case herd_adds_second_cow UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1; wr 0xC063 232; wr 0xC064 3} {expect level [rd 0xC0AC] 2; expect cow2 [rd 0xC028] 1}
case herd_adds_third_cow UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1; wr 0xC063 208; wr 0xC064 7} {expect level [rd 0xC0AC] 3; expect cow3 [rd 0xC030] 1}
case trio_heads_do_not_collide CheckHits {wr 0xC060 0; cow 112 100} {expect lives [rd 0xC006] 5}
case trio_lower_body_collides CheckHits {wr 0xC060 0; cow 112 136} {expect lives [rd 0xC006] 4}
case cheese_man_new_phrase BeginBoss {wr 0xC060 3} {expect phrase [debug read_block VRAM [expr {0x1800+3*32+5}] 23] "Experimentem meu queijo"}
case third_arena_cow_can_hit CheckHits {wr 0xC000 12; wr 0xC060 1; wr 0xC030 1; wr 0xC031 128; wr 0xC032 136} {expect lives [rd 0xC006] 4}
case new_herd_enters_far_side UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1; wr 0xC004 216; wr 0xC063 208; wr 0xC064 7} {expect x [rd 0xC031] 48; expect toward_right [rd 0xC033] 0}
case three_cows_preserve_sprite_budget BuildBossSprites {
    wr 0xC000 12; wr 0xC060 1; cow 112 96
    wr 0xC028 1; wr 0xC029 112; wr 0xC02A 128
    wr 0xC030 1; wr 0xC031 112; wr 0xC032 160
    wr 0xC069 1; wr 0xC06A 120; wr 0xC06B 128
} {
    expect slots [rd 0xC040] 32
    set counts [lrepeat 192 0]
    for {set slot 0} {$slot<32} {incr slot} {
        set y [expr {[rd [expr {0xC100+$slot*4}]]+1}]
        for {set line $y} {$line<$y+16 && $line<192} {incr line} {lset counts $line [expr {[lindex $counts $line]+1}]}
    }
    expect per_line [lindex [lsort -integer $counts] end] 8
}
case gauge_has_closed_ends DrawFuel {} {expect left [debug read VRAM 0x1826] 166; expect right [debug read VRAM 0x1831] 167}
case peaceful_meeting_has_no_caption BeginGarapaMeeting {wr 0xC060 0; wr 0xC017 0; debug write_block VRAM 0x1868 [string repeat " " 15]} {expect no_caption [debug read_block VRAM 0x1868 15] [string repeat " " 15]}
case garapa_phrase_never_alternates DrawGarapaPhrase {wr 0xC063 128} {expect phrase [debug read_block VRAM 0x1866 19] "Voc[format %c 243]s tomam garapa?"}
case cane_arena_is_wider MovePlayer {wr 0xC000 12; wr 0xC060 1; wr 0xC004 18; keymatrixdown 8 16} {expect x [rd 0xC004] 16}
case cane_arena_wide_right MovePlayer {wr 0xC000 12; wr 0xC060 1; wr 0xC004 222; keymatrixdown 8 128} {expect x [rd 0xC004] 224}
case throw_cane_with_space UpdatePlayerCane {wr 0xC000 12; wr 0xC060 1; keymatrixdown 8 1} {
    expect active [rd 0xC0CE] 1; expect x [rd 0xC0CF] 128; expect y [rd 0xC0D0] 128
    expect delay [rd 0xC0D3] 18; expect no_horn [rd 0xC059] 0
}
case no_throw_without_space UpdatePlayerCane {} {expect inactive [rd 0xC0CE] 0}
case throw_waits_for_movement CaneChallengeTick {wr 0xC000 12; wr 0xC060 1; wr 0xC061 0; keymatrixdown 8 1} {expect inactive [rd 0xC0CE] 0; expect stopped [rd 0xC061] 0}
case cane_throw_cooldown UpdatePlayerCane {wr 0xC0D3 10; keymatrixdown 8 1} {expect inactive [rd 0xC0CE] 0; expect delay [rd 0xC0D3] 9}
case player_cane_moves_up UpdatePlayerCane {wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 120} {expect y [rd 0xC0D0] 116}
case player_cane_exits UpdatePlayerCane {wr 0xC0CE 1; wr 0xC0CF 40; wr 0xC0D0 32} {expect inactive [rd 0xC0CE] 0}
case player_cane_hits_garapa UpdatePlayerCane {wr 0xC000 12; wr 0xC060 1; wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 72} {
    expect hp [rd 0xC065] 11; expect consumed [rd 0xC0CE] 0; expect flash [rd 0xC06D] 10
}
case player_cane_misses_garapa UpdatePlayerCane {wr 0xC0CE 1; wr 0xC0CF 160; wr 0xC0D0 72} {expect hp [rd 0xC065] 12; expect active [rd 0xC0CE] 1}
case final_cane_neutralizes_garapa UpdatePlayerCane {wr 0xC000 12; wr 0xC060 1; wr 0xC065 1; wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 72; cow 80 144; wr 0xC069 1} {
    expect hp [rd 0xC065] 0; expect defeated [rd 0xC090] 1; expect flash [rd 0xC06D] 75
    expect no_donkey [rd 0xC020] 0; expect no_incoming [rd 0xC069] 0
}
foreach base {0xC020 0xC028 0xC030} {
    case player_cane_kills_donkey_$base UpdatePlayerCane [list foreach {a v} [list 0xC0CE 1 0xC0CF 128 0xC0D0 124 $base 1 [expr {$base+1}] 120 [expr {$base+2}] 112 [expr {$base+5}] 2] {wr $a $v}] "expect dead \[rd $base\] 0; expect delay \[rd [expr {$base+4}]\] 100; expect consumed \[rd 0xC0CE\] 0; expect points \[bcd\] 00000100"
}
case player_cane_misses_donkey UpdatePlayerCane {cow 40 112; wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 124} {expect alive [rd 0xC020] 1; expect active [rd 0xC0CE] 1}
case cane_draw_preserves_sprite_budget BuildBossSprites {wr 0xC000 12; wr 0xC060 1; wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 120; cow 112 80; wr 0xC028 1; wr 0xC029 112; wr 0xC02A 112; wr 0xC030 1; wr 0xC031 112; wr 0xC032 144} {expect slots [rd 0xC040] 32; expect cane_tile [debug read VRAM 0x19F0] 246}
case cane_draw_saves_deck DrawPlayerCane {wr 0xC0CE 1; wr 0xC0CF 208; wr 0xC0D0 120; debug write VRAM 0x19FA 159; debug write VRAM 0x1A1A 157} {expect saved_top [rd 0xC0D4] 159; expect saved_bottom [rd 0xC0D5] 157}
case cane_erase_restores_deck ErasePlayerCane {wr 0xC0D1 250; wr 0xC0D2 25; wr 0xC0D4 159; wr 0xC0D5 157; debug write VRAM 0x19FA 184; debug write VRAM 0x1A1A 185} {expect top [debug read VRAM 0x19FA] 159; expect bottom [debug read VRAM 0x1A1A] 157; expect cleared [rd 0xC0D2] 0}
foreach hits {0 1} {
    case donkey_survives_hit_$hits UpdatePlayerCane [list foreach {a v} [list 0xC0CE 1 0xC0CF 128 0xC0D0 124 0xC020 1 0xC021 120 0xC022 112 0xC025 $hits] {wr $a $v}] "expect alive \[rd 0xC020\] 1; expect hits \[rd 0xC025\] [expr {$hits+1}]; expect points \[bcd\] 00000000; expect consumed \[rd 0xC0CE\] 0"
}
foreach stage {0 1} {
    case walking_road_throws_$stage UpdatePlayerCane "wr 0xC060 $stage; keymatrixdown 8 1" {expect active [rd 0xC0CE] 1; expect no_horn [rd 0xC059] 0}
}
case road_cane_does_not_hit_peaceful_boy UpdatePlayerCane {wr 0xC060 0; wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 72} {expect hp [rd 0xC065] 12}
case cane_transparent_over_solid_road DrawPlayerCane {
    wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 120
    debug write VRAM 0x19F0 130
    debug write VRAM [expr {2048+130*8}] 0
    debug write VRAM [expr {8192+2048+130*8}] 0xA6
} {
    expect pattern [debug read VRAM [expr {2048+246*8}]] 24
    expect original_background [debug read VRAM [expr {8192+2048+246*8}]] 182
}
case cane_preserves_patterned_background DrawPlayerCane {
    wr 0xC0CE 1; wr 0xC0CF 128; wr 0xC0D0 120
    debug write VRAM 0x19F0 130
    debug write VRAM [expr {2048+130*8}] 0x81
    debug write VRAM [expr {8192+2048+130*8}] 0xA6
} {
    expect pattern [debug read VRAM [expr {2048+246*8}]] 153
    expect exact_background_colors [debug read VRAM [expr {8192+2048+246*8}]] 166
}
case cane_challenge_waits CaneChallengeTick {wr 0xC000 12; wr 0xC060 1; wr 0xC061 0; wr 0xC04F 11} {expect hunger [rd 0xC04E] 100; expect elapsed [rd 0xC063] 0; expect dog [rd 0xC020] 0}
case cheese_boss_waits BossTick {wr 0xC000 4; wr 0xC060 3; wr 0xC061 0; wr 0xC04F 11} {expect gas [rd 0xC04E] 100; expect no_throw [rd 0xC069] 0}
case bonus_has_no_stage_number BeginCheeseBonus {wr 0xC060 1} {expect text [debug read_block VRAM 0x1869 14] "Fase conclu[format %c 245]da"}
case grandma_card ShowStageCard {wr 0xC060 2} {expect title [debug read_block VRAM 0x190C 7] "Vov[format %c 242]!!!"; expect empty_rows [debug read_block VRAM 0x1920 64] [string repeat " " 64]; expect no_instruction [debug read_block VRAM 0x1960 32] [string repeat " " 32]}
case walking_pose_stays_fixed BuildSprites {wr 0xC060 0; wr 0xC001 8; set ::fixed_pose [debug read_block VRAM 0x3800 256]} {expect pixels [debug read_block VRAM 0x3800 256] $::fixed_pose}
case cane_pose_stays_fixed BuildSprites {wr 0xC060 1; wr 0xC000 12; wr 0xC001 16; set ::fixed_pose [debug read_block VRAM 0x3800 256]} {expect pixels [debug read_block VRAM 0x3800 256] $::fixed_pose}
case arena_donkey_chases_every_tick UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1; wr 0xC001 1; cow 100 80} {expect x [rd 0xC021] 101; expect chase [rd 0xC027] 1}
case arena_donkey_crosses_every_tick UpdateCaneHerd {wr 0xC000 12; wr 0xC060 1; wr 0xC001 1; cow 100 80; wr 0xC027 1} {expect x [rd 0xC021] 101}
case fishing_donkey_keeps_original_speed UpdateWalkingCows {wr 0xC060 0; wr 0xC001 1; cow 70 70; wr 0xC004 200} {expect x [rd 0xC021] 70}
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
