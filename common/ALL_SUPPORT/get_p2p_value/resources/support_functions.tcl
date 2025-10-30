proc gen_debug_info {} {
    puts "Options incorrect, Error out"
    puts "Please check with below options:"
    puts "-probe           > the probe file for p2p run, user should setup probe files by \"-probe <your_probe_file>\""
    puts "-gds|-gdsii|-oas|-oasis  > the layout file for p2p run, user should setup layout files by \"-gds <your_layout_file>\""
    puts "probe ref: ./examples/pin_pair.txt"
    puts "Please Try:"
    puts "calibre -tcl scripts/p2p_run.tcl \\"
    puts "  -probe <your_probe_file> \\"
    puts "  -gds <your_layout_file> {-lvs <your_lvs_file>} {-resistance_file <your_resistance_file>} {-precision 2000}"
    puts ""
    exit 1
}

# ---------------------------------------------------------------
# Generate p2p.probe from user provided probe file
proc gen_probe_file {probe_file {p2p_file "p2p.probe"}} {
    set probe_file_fh [open $probe_file r]
    set number 0
    set probepair [list]

    set p2p_fh [open $p2p_file w+]
    puts $p2p_fh "PROBE_POINTS"
    while {[gets $probe_file_fh lines] != -1} {
        if {[regexp "(.*),\\s*(.*),\\s*(.*)\\s*" $lines match P1 P2 P3] && ![regexp ^# $lines]} {
            set number [expr {$number + 1}]
            puts $p2p_fh "source${number} $P1"
            puts $p2p_fh "sink${number} $P2"
            if {[expr {[string first "P2P" $P3] != -1}]} {
                lappend probepair_p2p "source${number}"
                lappend probepair_p2p "sink${number}"
            }

            if {[expr {[string first "CD" $P3] != -1}]} {
                lappend probepair_cd "source${number}"
                lappend probepair_cd "sink${number}"
            }

        }
    }
    puts $p2p_fh "END PROBE_POINTS"
    array set array_prob_p2p $probepair_p2p
    array set array_prob_cd $probepair_cd
    puts $p2p_fh "# Setup P2P and CD rules"
    puts $p2p_fh "PIN_PAIRS"
    foreach ele [array names array_prob_p2p] {
        puts $p2p_fh "$ele $array_prob_p2p($ele) p2p rule_p2p -annotations probe $ele -comment \"start point $ele to end point $array_prob_p2p($ele) P2P\""
    }
    foreach ele [array names array_prob_cd] {
        puts $p2p_fh "$ele $array_prob_cd($ele) cd rule_cd -annotations probe $ele -comment \"start point $ele to end point $array_prob_cd($ele) CD\""
    }
    puts $p2p_fh "END PIN_PAIRS"
    close $p2p_fh
    close $probe_file_fh
}

# Register the package
package provide file_temp 1.0
# This package help to gen tempfile, do file key world replacement
# Create namespace
namespace eval ::file_temp {
	namespace export write_file 
}

#############################################################################################################################
# Description: this proc help to translate a template into a outputfile with different keyword for the further csh usage
# Arguments: 
#		temp_file		-input temp_file to be processed
#		out_file		-output file to be written after processing temp_file
#		mapdict			-keyword mapping dictionary for substituting keywords
#		-opendelimiter	-open delimiter string, default is "<<"
#		-closedelimiter	-close delimiter string, default is ">>"
#		-delundef		-if delete the undefined keyword (1) or preserve (0)
#
# Example: file_temp::write_file temp_file output.text $mapdict -delundef 1
#############################################################################################################################

proc ::file_temp::write_file {temp_file out_file mapdict args} {
	array set optargs [list -opendelimiter "<<:" -closedelimiter ":>>" -permissions "rw-r--r--" -delundef 0]        
	array set optargs $args
	set infile [open $temp_file "r"]
	set outfile [open $out_file "w"]
	while {[gets $infile line] >= 0} {
		if {[regexp "${optargs(-opendelimiter)}\\S+${optargs(-closedelimiter)}" $line]} {
			set rol $line
			set printline ""        
			# loop over this line untill process all keyword 
			while {$rol ne ""} {
				if {[regexp "^(.*?)${optargs(-opendelimiter)}(\\S+?)${optargs(-closedelimiter)}(.*)$" $rol -> sol match_var rol]} {
					append printline $sol
                    #update function here in 20250103
                    if {[string first "|" $match_var] != -1} {
                        set result [split $match_var "|"]
                        set match_var [lindex $result 0]
                        #update function here in 20250106, support $var_name to recognize var_name, not just var_name
                        set default_value [lindex $result 1]
                    }
                    # if get key, then replace, if not, then try default key, if no default key, then remain the basic
                    # it can be:
                    #1: pre_info+ <<:required_key|default_value:>> +post_info ->pre_info+ required_value +post_info
                    #2: pre_info+ <<:required_key|default_value:>> +post_info ->pre_info+ default_value +post_info (required_key not exist)
                    #3: pre_info+ <<:required_key:>> +post_info         ->pre_info+ required_value +post_info
                    #4: pre_info+ <<:required_key:>> +post_info         ->pre_info+ <<:required_key:>> +post_info (required_key not exist)
					if {[dict exists $mapdict $match_var]} {
						append printline [dict get $mapdict $match_var]        
					} elseif {[info exists default_value]} {
						append printline "$default_value"
                    } elseif {$optargs(-delundef) == 0} {
						# preserve undefined keyword if required
						append printline "${optargs(-opendelimiter)}${match_var}${optargs(-closedelimiter)}"
					}
                    if {[info exists default_value]} {
                        unset default_value
                    }
				} else {
					append printline $rol
					set rol ""
				}
			}
			# replace finished        
			puts $outfile $printline
		} else {
			# copy the line without keyword
			puts $outfile $line
		}
	}
	close $infile
	close $outfile
	file attributes $out_file -permission $optargs(-permissions)
}

