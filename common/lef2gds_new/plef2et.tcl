#!/usr/bin/tclsh
#
# Usage: PlLef2Et.tcl <lef> <topcell> <out>
#
# 从 LEF 文件中提取每个 MACRO 的 PIN text，生成 ET (embed text) 文件。
# 由 PlLef2Et.pl 改写而来。

set mymap(M1)  {15 20}
set mymap(M2)  {17 20}
set mymap(M3)  {19 20}
set mymap(C4)  {41 20}
set mymap(C5)  {141 20}
set mymap(C6)  {142 20}
set mymap(C7)  {143 20}
set mymap(K1)  {181 20}
set mymap(K2)  {182 20}
set mymap(G1)  {161 20}
set mymap(G2)  {162 20}
set mymap(LB)  {69 20}


if {[llength $argv] != 3} {
    puts stderr "Usage: $argv0 <lef> <topcell> <out>"
    exit 1
}
lassign $argv lef topcell out

# 读入 LEF，行首去空白
set fh [open $lef r]
set lines {}
while {[gets $fh raw] >= 0} {
    lappend lines [string trimleft $raw]
}
close $fh

# 找出每个 MACRO 行号 与 每个 OBS 行号，paste 配对
set macro_lines {}
set obs_lines {}
for {set i 0} {$i < [llength $lines]} {incr i} {
    set ln [lindex $lines $i]
    if {[regexp {^MACRO } $ln]} {
        lappend macro_lines $i
    } elseif {[regexp {^OBS\b} $ln]} {
        lappend obs_lines $i
    }
}

# 原 perl 用 paste，假设 macro 与 obs 一一对应
set pairs {}
for {set i 0} {$i < [llength $macro_lines]} {incr i} {
    lappend pairs [list [lindex $macro_lines $i] [lindex $obs_lines $i]]
}

set out_fh [open $out w]


foreach pair $pairs {
    lassign $pair star end
    if {![string is integer -strict $star]} continue
    if {![string is integer -strict $end]} continue

    set PinName ""
    set Layer   ""

    for {set i $star} {$i <= $end} {incr i} {
        set ln [lindex $lines $i]
        if {[regexp {^PIN\s+(\S+)} $ln -> name]} {
            set PinName $name
        }
        if {[regexp {^LAYER\s+(\S+)} $ln -> name]} {
            set Layer $name
        }
        if {[regexp {^(?:RECT|POLYGON)\s+(\S+)\s+(\S+)} $ln -> p_x p_y]} {
            # 原 perl 判断: $Layer !~ /^VIA /i
            # 注意: $Layer 来自 "LAYER xxx" 的 split，不包含 "VIA " 前缀，
            # 除非层名本身以 VIA 开头。这里保留原行为。
            if {![regexp -nocase {^VIA } $Layer]} {
                if {[info exists mymap($Layer)]} {
                    set gds [lindex $mymap($Layer) 0]
                    set dt  [lindex $mymap($Layer) 1]
                    puts $out_fh "LAYOUT TEXT \"$PinName\" $p_x $p_y $gds $dt $topcell"
                } else {
                    puts stderr "Warn: layer '$Layer' not in mymap (pin=$PinName)"
                }
            } else {
                puts "Infos: $PinName $p_x $p_y$Layer"
            }
        }
    }
}

close $out_fh
puts "Done: $out"
