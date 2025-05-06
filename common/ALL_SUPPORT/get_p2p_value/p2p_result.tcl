# This file help to run PERC PROBE P2P/CD if required
################################################################################
# Description: this proc help to get P2P results if required
# Arguments:
#    -probe               -input probe file required for p2p probe file
#    -gds|oasis|gdsii|oas  -layout file path for P2P run
#    -topcell              -specified topcell for P2P run
#    -lvs_file             -a required file for perc run
#    -resistance_file      -a required file for perc run
#
# Example: p2p_run -probe probe.text -layout my_layout.gds -topcell my_top
################################################################################

lappend auto_path "/home/apchen1/project/module_setup/calibre/module"
package require file_edit_func
package require gen_deck_header
package require data_func
package require debug_proc

# Setup Debug info for p2p
proc gen_debug_info {} {
    puts "Options incorrect, Error out!"
    puts "Please check with below options:"
    puts "-probe        > the probe file for p2p run, user should setup probe files by \"-probe <your_probe_file>\" "
    puts "-gds|-gdsii|-oas|-oasis  > the layout file for p2p run, user should setup layout files by \"-gds <your_layout_file>\" "
    puts "probe ref: /home/apchen1/project/module_setup/cad_functions/pv_tools/p2p/pin_pair.text"
    puts "Please Try:"
    puts "p2p_run \[-probe <your_probe_file>\] \[-gds <your_layout_file>\] {-lvs <your_lvs_file>} {-resistance_file <your_resistance_file>} {-precision 2000} "
    puts ""
    exit
}

# Setup probe file gen proc
# Probe file works for input probe provided by user, then ./p2p.probe is generated
proc gen_probe_file {probe_file {p2p_file "p2p.probe"}} {
    set probe_file_fh [open $probe_file r]
    set number 0
    set probepair [list]
    # Gen required PIN probe
    set p2p_file [open p2p.probe w+]
    # 1.2.1 probe file create and start
    puts $p2p_file "PROBE_POINTS"
    while {[gets $probe_file_fh lines] != -1} {
        if {[regexp {(.*)\\s+(.+)} $lines match P1 P2] && ![regexp {# $lines}]} {
            set number [expr $number + 1]
            puts $p2p_file "sources{$number} $P1"
            puts $p2p_file "sinks{$number} $P2"
            lappend probepair "sources{$number}"
            lappend probepair "sinks{$number}"
        }
    }
    array set array_prob $probepair
    puts $p2p_file "END PROBE_POINTS"
    puts $p2p_file "# Setup P2P rules"
    puts $p2p_file "PIN_PAIRS"
    foreach ele [array names array_prob] {
        puts $p2p_file "$ele $array_prob($ele) p2p rule_p2p -annotations probe $ele -comment \"start point $ele to end point $array_prob($ele) P2P \""
    }
    puts $p2p_file "END PIN_PAIRS"
    close $p2p_file
    close $probe_file_fh
}

################################################################################

# INI setup for P2P run
#set lvs_file [file normalize "./LDL_PROBE_PATH/lvs.rules"]
#set resistance_file [file normalize "./LDL_PROBE_PATH/resistance.rules"]
set lvs_file "/home/apchen1/project/module_setup/rule_deck/perc/main/modified/1.2b/1P15M_1X1Xb1Xe1Ya1Yb5Y2YyZZ/perc_n05.lvs"
#
set resistance_file ""
set lvs_file "/home/apchen1/project/module_setup/cad_functions/pv_tools/p2p/rules/N05/perc_n05_1P15M_1X1Xb1Xe1Ya1Yb5Y2YyZZ.top"
set tvf_func "/home/apchen1/project/module_setup/cad_functions/pv_tools/p2p/rules/tvf_functions.tcl"
set topcell ""

# opts may control define value
set opts [list "CD_P2P"]

################################################################################
# -1 Supply settings, blow list stand for all supplied options
set supply_options_list [list -probe -gds -gdsii -oasis -oas -topcell -lvs_file -resistance_file -precision]
# -2 required settings apply
set required_option [list -probe]
# -3 Default settings, blow list stand for all default options
array set default_options [list -lvs_file $lvs_file -resistance_file $resistance_file -topcell ""]
# All info in default_options map to user_options to initialize user_options
array set user_options [list -lvs_file $lvs_file -topcell ""]

# User settings
array set user_options $argv

# Reset lvs file || top cell if user specified
if {[info exist user_options(-lvs_file)]} {
    set lvs_file $user_options(-lvs_file)
}

if {[info exist user_options(-topcell)]} {
    set topcell $user_options(-topcell)
}

if {[info exist user_options(-precision)]} {
    set precision $user_options(-precision)
} else {
    set precision "NA"
}

# Get layout type and layout file
foreach ele [list -gds -gdsii -oas -oasis] {
    if {[info exist user_options($ele)]} {
        set layout_file [file normalize $user_options($ele)]
        if {$ele eq "-gds" || $ele eq "-gdsii"} {
            set layouttype "GDSII"
        } else {
            set layouttype "OASIS"
        }
    }
}
if {![info exist layouttype]} {
    puts "-gds|-gdsii|-oas|-oasis option is required"
    gen_debug_info
}

set user_options_list [array names user_options]
# Option settings debug
debug_proc::option_check $supply_options_list $required_option $user_options_list "gen_debug_info"

# Ini setup done, start main deck

# 1 Get input pin pairs
set probe_file [file normalize $user_options(-probe)]
puts "input probe is [file normalize $user_options(-probe)]"
gen_probe_file $probe_file "p2p.probe"

# 2 Gen P2P header
set svrf_fh [open [file normalize perc.svrf] w+]
gen_deck_header::write_input_data_to_file $svrf_fh $layout_file $topcell $layouttype "" "" "$precision"

puts $svrf_fh "PERC NETLIST LAYOUT"
puts $svrf_fh "PERC REPORT \"perc.rep\""
puts $svrf_fh "PERC SUMMARY REPORT \"perc.sum\""
puts $svrf_fh "DFM DATABASE \"dfmdb\" OVERWRITE REVISIONS \[DEVICES PINLOC\]"
puts $svrf_fh "PERC LDL PROBE PATH \"[file normalize "p2p.probe"]\""
puts $svrf_fh ""
foreach ele $opts {
    puts $svrf_fh "#DEFINE $ele"
}
puts $svrf_fh ""
puts $svrf_fh "DRC ICSTATION YES"
puts $svrf_fh ""
puts $svrf_fh "//INCLUDE RULES"
puts $svrf_fh "INCLUDE \"$lvs_file\""
if {[info exist user_options(-resistance_file)]} {
    puts $svrf_fh "INCLUDE \"$user_options(-resistance_file)\""
}
puts $svrf_fh "INCLUDE \"$tvf_func\""

# 3 Get include files

close $svrf_fh
################################################################################