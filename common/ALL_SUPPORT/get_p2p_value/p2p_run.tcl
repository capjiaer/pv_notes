#!/usr/bin/env tclsh

# ###############################################################
#  This file helps to run PERC PROBE P2P/CD if required
# ###############################################################
# Description: this proc helps to get P2P results if required
# Arguments:
#   -probe             - input probe file required for p2p probe file
#   -gds|oasis|gdsii|oas - layout file path for P2P run
#   -topcell           - specified topcell for P2P run
#   -lvs_file          - a required file for perc run
#   -resistance_file   - a required file for perc run
#   -precision         - optional dbu precision



# Auto load required packages for base run
set dir [file dirname [info script]]/resource
foreach file [glob [file join $dir *.tcl]] {
    source $file
}

# Default tvf_function is below
set tvf_func_file "$dir/functions.tvf"

# 1) Supply settings
# Settle resistance_file, lvs_file, layout_file, probe_file, topcell precision for PERC run
set supply_options_list [list -resistance_file -lvs_file -layout_file -probe_file -topcell -precision]
array set user_options $argv

set error_flag 0

# Settle resistance_file
if {[info exist user_options(-resistance_file)]} {
    set resistance_file $user_options(-resistance_file)
    puts "Get resistance_file   [file normalize $user_options(-resistance_file)]"
} else {puts "ERROR: -resistance_file opt is reuqried!! please settle"; set error_flag 1}

# Settle lvs_file
if {[info exist user_options(-lvs_file)]} {
    set lvs_file $user_options(-lvs_file)
    puts "Get lvs_file          [file normalize $user_options(-lvs_file)]"
} else {puts "ERROR: -lvs_file opt is reuqried!! please settle"; set error_flag 1}


# Settle layout_file
if {[info exist user_options(-layout_file)]} {
    set layout_file $user_options(-layout_file)
    puts "Get layout_file       [file normalize $user_options(-layout_file)]"
    set extension [file extension $layout_file]
    if {$extension eq ".gds"} {
        set LAYOUT_SYSTEM "GDSII"
    } elseif {$extension eq ".oas"} {
        set LAYOUT_SYSTEM "OASIS"
    } else {
        set LAYOUT_SYSTEM "GDSII"
        puts "Can not recognize the LAYOUT TYPE, set it as default GDSII, Please check with your layout_file in case un-expected input"
    }
} else {puts "ERROR: -layout_file opt is reuqried!! please settle"; set error_flag 1}

# Settle probe_file
if {[info exist user_options(-probe_file)]} {
    set probe_file $user_options(-probe_file)
    puts "Get probe_file        [file normalize $user_options(-probe_file)]"
} else {puts "ERROR: -probe_file opt is reuqried!! please settle"; set error_flag 1}

# Settle topcell 
set topcell "*"
if {[info exist user_options(-topcell)]} {
    set topcell $user_options(-topcell)
    puts "Get topcell $user_options(-topcell)"
}

# Settle precision
if {[info exist user_options(-precision)]} {
    set precision $user_options(-precision)
    puts "Get precision $user_options(-precision)"
} else {
    set precision "1000"
    puts "Set precision 1000 as default, please set it by \"-precision <YOUR_PRECISION>\" if your precision is not 1000!!!"
}

# Settle include file
set include_files ""
set include_info ""
if {[info exist user_options(-include_files)]} {
    set include_files $user_options(-include_files)
    puts "Get other include file $user_options(-include_files)"
}
foreach ele $include_files {
    append include_info "include $ele \n"
}

if {$error_flag} {
    puts "ERROR SUMMARY FOR P2P RUN, please check with your OPITONS!"
    exit
}
# Settle resistance_file, lvs_file, layout_file, probe_file, topcell precision for PERC run Done

dict set mapdict LAYOUT_PATH [file normalize $layout_file]
dict set mapdict LAYOUT_PRIMARY $topcell
dict set mapdict LAYOUT_SYSTEM $LAYOUT_SYSTEM
dict set mapdict PRECISION $precision

dict set mapdict LVS_FILE [file normalize $lvs_file]
dict set mapdict R0_FILE [file normalize $resistance_file]
dict set mapdict TVF_FILE [file normalize $tvf_func_file]

dict set mapdict INCLUDE_INFO $include_info

# Gen probe file base on user input probe
gen_probe_file [file normalize $probe_file] "p2p.probe"
set final_probe_file [file normalize "p2p.probe"]
dict set mapdict LDL_PROBE_PATH $final_probe_file


set temp_file $dir/perc.svrf_temp
set target_file [pwd]/perc.svrf
file_temp::write_file $temp_file $target_file $mapdict -permissions rwxr-xr-x

exit


