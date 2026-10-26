# Real keyboard entry, horizontal selection and launch from the title screen.
set throttle off
set sound_driver null
set save_settings_on_exit false
proc rd {address} {debug read memory $address}
set problems {}
after time 6 {keymatrixdown 0 2}
after time 6.12 {keymatrixup 0 255}
after time 6.24 {keymatrixdown 1 2}
after time 6.36 {keymatrixup 1 255}
after time 6.48 {keymatrixdown 0 2}
after time 6.60 {keymatrixup 0 255}
after time 6.72 {keymatrixdown 0 16}
after time 6.84 {keymatrixup 0 255}
after time 7 {
    if {[rd 0xC0EB]!=1 || [rd 0xC000]!=0} {lappend ::problems "1914 did not reveal the menu"}
    if {[debug read VRAM [expr {180*128+37}]]!=1} {lappend ::problems "selected digit not drawn"}
}
after time 7.1 {keymatrixdown 8 128}
after time 7.22 {keymatrixup 8 255}
after time 7.34 {keymatrixdown 8 128}
after time 7.46 {keymatrixup 8 255}
after time 7.6 {
    if {[rd 0xC0EC]!=2} {lappend ::problems "arrows did not select chapter 3"}
    keymatrixdown 7 128
}
after time 7.72 {keymatrixup 7 255}
after time 9 {
    if {[rd 0xC000]!=12 || [rd 0xC060]!=1 || [rd 0xC006]!=5} {lappend ::problems "Enter did not launch garapa battle"}
    set hz [expr {[rd 0xC003] ? 60 : 50}]
    set f [open resources/generated/secret-menu-$hz.txt w]
    if {[llength $::problems]} {puts $f "FAIL $::problems"} else {puts $f "PASS keyboard 1914, seven digits, horizontal arrows and Enter launch"}
    close $f
    exit
}
set power true
