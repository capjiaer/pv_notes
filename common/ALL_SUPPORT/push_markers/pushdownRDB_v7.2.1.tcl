# USAGE: calibredrv pushdownRDB.tcl -rdbIn <rdb > -origDB < orig GDS/OASIS file > -UBMlayer <layer number> -cellFile < cell list in a txt file > \
#				    -rdbout < output rdb file > -OASout <output OASIS file > [-debug < 1/0> ] [-boundaryLayer < layer number > ] \
#                  [-promote < 1/0 > ] [-blockRDB 1|0]
#
#
# Version: 1.0
# Version: 1.1 Added debugging switches and change invoke options
# version: 2.0 rewrite the code so it is much orginazed and has a lot more description
# version: 3.0 add a special promote switch to promote results from the lower level blocks to target cell level
# version: 4.0 modify the algorighm so it does not require to create all those intermediate files...
# version: 5.0 Use DRC optionation for boolean operation.
# version: 5.1 fix performance issue
# version: 6.0 this new version of script to pushdownRDB.tcl for UBM flow. Major changes are: take input layer as the input, convert the output results to OASIS file.
# version: 6.1 fix a bug that it will always error out unless user provides a OASIS output file name
# version: 6.2 fix a logic error that might cause an emtpy result.
# Date: 2017/12/06
# Author: Saunder Peng

# Author: James Paris
# version 6.3 Added -fixPolygons to convert_RDB_file procedure to address non-orientable objects in DRC.
# version 6.4 Added support for RDB output per block; -blockRDB
#             Replaced TrimCell check with regsub check to permit short cellnames   
# version 6.5 Renamed temporary output files and basic cleanup.
# version 6.6 Added DBU2UU procedure & SIZE down boundaryLayer by 1 dbu to avoid merging abutting shapes in Calibre DRC.
# version 6.7 Fixed BlockRDB output when -rdbout is specified with "./". 
# version 6.8 Enable boundary layer only import to DESIGNrev when boundary layer is specified on command line.
# version 6.9 Fixed issue with boundary layer only import.
#             Print block result counts to transcript when -blockRDB is set
#             Added -hyper for runtime improvement.
# version 7.0 Fixed issue with boundaryLayer name in "TrimCell" when boundaryLayer is specified with datatype 0.
#             Changed output filenames to all be sequencially numbered "1_<filename> to 6_<filename>
# version 7.1 Added -ctoFile read option for RDB import to generate a CTO file containing checktext.
# version 7.2 Fixed the outputCellRDB when the layout contained no cells for blockRDB output.
#
# Notes: "-promote" this hidden switch will give user an option to choose either to promote the lower level results to toplevel before running pushdown command this option is on by default, because this part will also help user to cut the results between two cells.
#        "-boundaryLayer" allows user to choose its own cell boundary layer instead of using the calculated bbox value to define the cell outline
# 			, this option should be used if your cell contains non-rectangular cells			
#
#

proc showHelp  { } {
	puts "USAGE : calibredrv pushdownRDB.tcl \{ -rdbIn <rdb > | -UBMlayer < layer # > \} -origDB < orig GDS/OASIS file > -cellFile < cell list in a txt file > \{ -rdbout  < output rdb file > | -OASout <output OASIS file > \} \[-blockRDB 0/1\] \[-boundaryLayer < layer # > \]    "
}

proc ctk_cvtDBU2UU { value precision } {
    foreach coord $value {
        lappend coordList [expr {double($coord) / $precision}]
    }
    return $coordList
}
proc reduceDBsize { origDB newOAS cellFile debug tmpLayer boundaryLayer tmpTopcell forPushDownOAS } { 

# The purpose of this proc is to reduce the amount of data the downstream flow needs to process
# Then at the end of this proc, it will only write out only the cells that in the cell list that user specificed with a polygon that covers the extent of the cell
#

# load the input database	
	if { $boundaryLayer != "" } {
        foreach { bl_num bl_dt } [split $boundaryLayer .] {break}
        if { $bl_dt == "" } { set bl_dt 0 }
        if {$debug == 1 } { puts "boundaryLayer:$boundaryLayer\nbl_num:$bl_num\nbl_dt:$bl_dt\n"}
        set L [ layout create $origDB -dt_expand -preservePaths -ignoreTexts -noReport -map $bl_num $bl_dt $boundaryLayer -only ]
        if {$debug == 1} { puts "DRAWN BOUNDARY MODE: layers = [$L layernames]\nPushdown target defined as layer: $boundaryLayer"}
    } else {
        set L [ layout create $origDB -dt_expand -preservePaths -ignoreTexts -noReport ]
        if {$debug == 1} { puts "CELL BOUNDARY MODE: layers = [$L layernames]\nPushdown target defined by cell extent."}
    }

# load the cellFile 
	set f_read [ open $cellFile r ]
	set f_data [ read $f_read ] 
	set cellList [ split $f_data "\n" ]

# use the following layer as tmp layer ( when we export the database, this layer will be the only layer got exported )
	set tmp_layer $tmpLayer 
	set empty_layer 0.4321
	
	$L create layer $empty_layer

# start to process each cell inside the cell list

	foreach cell $cellList {
	
		set TrimCell [string trimright $cell ]
		
		if { $debug } {
		
			puts "debug_reduceDB >>start processing cell $cell"
			puts "TrimCell = $TrimCell"
		}
		
		# make sure it is a actual cell name, not a space...

		if { [regsub {\s+} $TrimCell ""] ne "" } {
        
			# create a temp layer
			$L create layer $tmp_layer 
			
			
			# if the cell exists, find the extent of the cell using $L bbox command
			if { [ $L exists cell $TrimCell ] && $boundaryLayer == "" } { 
				set bbox [ $L bbox $TrimCell ]
				if { $debug } { 
					puts "debug_reduceDB >> creating polygon in cell $TrimCell " 
				}
				# make the bbox one dbu inside
				set new_bbox_value "[expr [lindex $bbox 0 ] + 1 ] [expr [lindex $bbox 1 ] + 1 ] [expr [lindex $bbox 2 ] - 1 ] [expr [lindex $bbox 3 ] - 1 ] "
				
				# then create a polygon that covers the extent of the cell
				
				eval $L create polygon $TrimCell $tmp_layer $new_bbox_value 

			} elseif {[ $L exists cell $TrimCell ] && $boundaryLayer != ""  } {
				# if boundary layer is defined
			
				set layerInCell [$L layers -cell $TrimCell]
                if {0} { puts "\nlayerInCell: $layerInCell\n"}
                
                # DESIGNrev doesn't keep datatype 0 in layer names. If input was 108.0, then it needs to be changed
                # to just 108 for the boundary generation inside the cell.
                if {0} { puts "\nboundaryLayer: $boundaryLayer" }
                foreach { bl_num bl_dt } [split $boundaryLayer .] {break}
                if { $bl_dt == 0 } { set boundaryLayer $bl_num }
                if {0} { puts "\nboundaryLayer: $boundaryLayer" }


				if  { [ lsearch $layerInCell $boundaryLayer ] != "-1" } {
					if { $debug } {
					
						puts "debug_reduceDB >> cell $TrimCell contains boundary Layer use $boundaryLayer to create bbox for for reduced database "
						puts "layers in cell $TrimCell = $layerInCell boundary layer = $boundaryLayer"
					}	
					# following command is to COPY the boundary layer to the tmp layer. Since COPY does not support cell specific option, use OR instead
                    # Undersize boundary layer by 1dbu to avoid merging abutted drawn boundaries.
                    set dummyLayer [$L create layer 1122.3344]
                    $L SIZE $boundaryLayer $dummyLayer BY [ctk_cvtDBU2UU -1 [$L precision]]
                    #$L oasisout FOO.oas
					# It OR with an empty layer to force the boundary layer to empty layer
					$L OR $empty_layer $dummyLayer $tmp_layer -cell $TrimCell
						
				
				} else {
				# this part is probably not needed, Saunder to verify
				
					set bbox [ $L bbox $TrimCell ]
					
					if { $debug } { 
						puts "debug_reduceDB >> creating polygon in cell $TrimCell " 
					}
					# make the bbox one dbu inside
					set new_bbox_value "[expr [lindex $bbox 0 ] + 1 ] [expr [lindex $bbox 1 ] + 1 ] [expr [lindex $bbox 2 ] - 1 ] [expr [lindex $bbox 3 ] - 1 ] "
				
					# then create a polygon that covers the extent of the cell
				
					eval $L create polygon $TrimCell $tmp_layer $new_bbox_value 
				
				}
			} else {
				puts "Warning >> cell $TrimCell does not exist in the orginal layout $origDB"
				
			}
		}
	}
	
	set topcell [$L topcell]

	set cmd "$L oasisout $forPushDownOAS  -noReport -map $tmp_layer -noEmptyCells noRefs"
	eval $cmd

	# remove this... this is not needed, Saunder to clean this part.
	set cmd "$L oasisout $newOAS -noReport -map $tmp_layer -noEmptyCells noRefs"
	eval $cmd
		
	
	
	if { $debug } {
		$L oasisout 3_reduceDB.[pid].oas  -noReport -map $tmp_layer -noEmptyCells noRefs
	}

}

proc checkPrecision { rdbIn reducedOAS convertedOAS rdbout debug } {

	# this part of the code is to check whether the precision of the input database is the same as the rdb
	# if those two files have same precision, then this script will rename the file from $reducedOAS to $convertedOAS
	# otherwise, it will create a new oasis file with the precision that is the same as the rdb 
  	# The asumption is: if input database precision is not the same as the rdb precision, we assume rdb has higher precision.
	
    if {$debug==1} { puts "CTO FILE: ${rdbout}.cto" }
    # Read original RDB and create a CTO file.
	set rdbHandle [ layout create $rdbIn -noReport -ctoFile ${rdbout}.cto ]
	set rdbPrecision [$rdbHandle precision ]
	set dbPrecision [layout peek $reducedOAS -precision ]
	
	if {$dbPrecision == $rdbPrecision } {
			
		if { $debug} {
			puts "debug_precision >> nothing needs to be modified, layout precision = rdb precision = $dbPrecision"
		}

		# if nothing need to change ( layout database precision is the same as rdb precision), then we rename the input database file
	
		file rename -force $reducedOAS $convertedOAS
			
	} else {

		# if database precision isnt the same between the input database & rdb file some process is required.
		set tmpFile "tmp.[pid].oas"
		
		if { $debug} {
			puts "debug_precision >> rdb file has precision of $rdbPrecision original database has precision file of $dbPrecision"
			puts "debug_precision >> Because precision is different between input rdb & input layout database. This script needs to create a tmp OAS file just so this script to work, the tmp OASIS file is: $convertedOAS "
		}
			
			#following is to create a tmp file just so it will have the same precision as input rdb... ( tmp file will be an empty design that has no polygons in it ...)

			
			# layer 1.1 is guarantee to be unused layer because rdb layers will only be integer.
			$rdbHandle create layer 1.1 
			$rdbHandle oasisout $tmpFile -noReport -map 1.1 
			
			# This is always assume rdb will have higher precision than the orig layout database
			# filemerge by defaul will always choose the input database that has higher preision for the precision in output file

			layout filemerge -in $tmpFile -in $reducedOAS -out $convertedOAS
						
			if { $debug} {
				puts "debug_precision >> this shuold create a $convertedOAS, so the $convertedOAS shuold be the same as the rdb file, this $convertedOAS file will be used in the downstream flow"
			}

			# delete the $tmpFile.... ( only used in the layout filemerge step)
			file delete $tmpFile
			
			if {$debug} {
				puts "debug_precision >> delele the tmp file $tmpFile which was used to create $convertedOAS "
			}
	}
}

# the propose for the following proc are the following:

# 1. convert the rdb file into OASIS format
# 2. convert the edge pair results to 4dbu wide polygon if the env var is set


proc convert_RDB_file { rdbIn OASout } {

	set tmp_oas 4_rdb2oas.[pid].oas
	
	set rdbhandle [layout create $rdbIn -noReport ]

	
	if { [info exists ::env(MGC_CWB_CONVERT_ZWPATH_TO_POLYGON) ] } {
	
		$rdbhandle oasisout $tmp_oas  -fixPolygons
		# load the database in so the 0 width path can be converted to 4dbu wide polygon
		set L [ layout create $tmp_oas -dt_expand ]
		
		# export converted OASIS file
		$L oasisout $OASout
		
	} else {
		
		puts "Warning: edge pair results will be dropped in this conversion, set MGC_CWB_CONVERT_ZWPATH_TO_POLYGON env var in the terminal = 1 to avoid this" 
		
		# since env var is not set, 0 width path ( from edge pair results will be dropped )
		$rdbhandle oasisout $OASout

	}

}


proc create_DRC_rule { input ruleFileName DRC_rdbout boundaryLayer debug }  {

# purpose for this proc is to create a DRC rule file to promote the lower level results to top level results
# if a violation is acorss both cells, it will try to break itself into two separate error shapes, with each one of those only inside the cell. 
#
# input for this DRC run: OASIS file ( OASIS file that contains all the error shapes & the cells boundary of each target cell)
# output for this DRC run: flat RDB file
# 


	puts "Entering creating DRC rule proc"

	set L [ layout create $input -dt_expand -preserveProperties -noReport ]	
	set topcell [$L topcell ]
	set layers [ $L layers ]
	set format [$L format]
	set precision [$L precision]
	
	puts " boundaryLayer =$boundaryLayer"
	set bLayerNumber  [lindex [split $boundaryLayer "."] 0 ]
	set bLayerDatatype [lindex [split $boundaryLayer "."] 1 ]
	set mapped_layer_number 9999
	
	
	set f_write [ open $ruleFileName w+]
	
	puts $f_write "LAYOUT PATH \"$input\" "
	puts $f_write "LAYOUT PRIMARY $topcell "
	puts $f_write "LAYOUT SYSTEM $format"
	puts $f_write "PRECISION $precision"
	puts $f_write "DRC MAXIMUM RESULTS ALL"
puts $f_write "DRC RESULTS DATABASE $DRC_rdbout"
	puts $f_write "LAYER MAP $bLayerNumber DATATYPE $bLayerDatatype $mapped_layer_number"
	
	puts $f_write "Layer BOUNDARY_LAYER $mapped_layer_number "

	
	foreach layer $layers {
	
		if { $layer != $boundaryLayer } {
			
				if {$debug } {
					puts "start processing layer $layer"
				}
						
				set layername [$L layernames $layer]
				puts $f_write "Layer \"$layername\" $layer "
	
				if {$debug } {
					puts "start generate check for check $layername"
				}
				
				puts $f_write "\"$layername\" { AND \"$layername\" BOUNDARY_LAYER   NOT \"$layername\" BOUNDARY_LAYER } "
		        lappend all_layernames $layername		
								
			}
	
	}

	close $f_write	
}
	
proc cutResults_new { rdbIn convertedOAS cellFile rdbout tmpLayer debug blockRDB promote layerBump tmpTopcell forPushDownOAS OASout UBMlayer origDB } { 

	# this proc has three main functions:
	# if promote option is set ( it is on by default), the first step is to promote the lower level results to top level. 
	# if promote option is set ( it is on by default), the second step is for when a result is across two blocks, then it will try to cut one results into two different segements
	# after process the rdb file, it will run the pushmarker command to push toplevel results to cells that specificed by user


	if {$debug } {
		puts "debug_cut_results: entering cutResult function"
		puts "debug_cut_results: input arguments are rdbIn: $rdbIn convertedOAS: $convertedOAS cellFile: $cellFile rdbout: $rdbout tmpLayer: $tmpLayer OASout: $OASout"
	}

# define all the tmp variable to be used
	
	set tmp_oas 4_rdb2oas.[pid].oas
	set tmp3_oas 5_tmp.[pid].oas
	set tmp4_oas 6_tmp.[pid].oas
	
	set new_layerList ""
	set DRC_rule_name "drc.rules"
	set DRC_rdbout "drc.rdb"

# if user choose to output the results in OASIS file, that means user does not define a output rdb file name, in this case we will choose one tmp file name for user.
	if { $OASout != "" } {
		set rdbout tmp.rdb.[pid].rdb 
	} 
	
	
	if { $UBMlayer != "" } { 
		# this part is for users that defined the shapes they want to pushed down in UMB layer #
		layout filemerge -in $origDB -include_layer $UBMlayer -out $tmp_oas

	} else {
		# this is for users that have shapes defined in the rdb files.
	
		convert_RDB_file $rdbIn $tmp_oas
		# call the convert_RDB utility to convert the input rdb file to OASIS format	
	}


	set topcell [ layout peek $tmp_oas -topcell]
	
	set Ltmp [ layout create ]
	$Ltmp create cell $topcell
	$Ltmp create cell $tmpTopcell
	$Ltmp create ref $topcell $tmpTopcell 0 0 0 0 1
	$Ltmp oasisout $tmp3_oas


	# the following two filemerge script is to: combine the error file with the cell outline file
	layout filemerge -in $convertedOAS -in $tmp_oas -out $tmp4_oas

	if {$debug } {
		puts "loading the combined file that contains the rdb file and reduced design input file"
		puts "this $tmp4_oas file is going to be used in DRC check"
	}


	# if user choose to promote all the violations in input rdb to toplevel
	if { $promote == 1 } { 
		
		puts "Starting running DRC to promote results to toplevel and try to cut the violation based on the cell outline"	
		create_DRC_rule $tmp4_oas $DRC_rule_name $DRC_rdbout  $tmpLayer  $debug 
		
		# run DRC after the DRC rule file is written in previous proc.
		exec $::env(MGC_HOME)/bin/calibre -drc -hier -turbo -hyper $DRC_rule_name
		puts "DRC finished, running DRV pushmarker command to push to cell level"

	} else {

		# if user choose not to promote, this script uses the input rdb to run pushmarker command 
		set DRC_rdbout $rdbIn

	}
	# load the reduced OASIS ( database that only contains the cell outline) to run the pushmarker command
	#JMP - looks like this should use convertedOAS and not forPushDownOAS
    #set L2 [ layout create $forPushDownOAS -dt_expand -noReport ]
	set L2 [ layout create $convertedOAS -dt_expand -noReport ]
	set L2_topcell [ $L2 topcell ]

	    set pushmarkers_cmd " $L2 pushmarkers $DRC_rdbout -out $rdbout -cell $L2_topcell -map * [split $tmpLayer . ] " 
        #puts $pushmarkers_cmd
	    eval $pushmarkers_cmd

	# convert the RDB result to OAS file that specified by customer:

	if { $OASout != "" } { 

    # Need to enable top-level only RDB output when blockRDB is enabled.
        if {$blockRDB == 1 } { 
         #1. Write out OASIS depth 0
         #2. Import OASIS depth 0 from #1 (includes empty references)
         #3. Export Hierarchical RDB (drops empty references)
        } else {
        # When blockRDB is not set, output as normal.
    		set Lrdb_convert [ layout create $rdbout -noReport -preserveProperties]
	    	$Lrdb_convert oasisout $OASout
        }
	}
	
	if { $debug == 0 } {
	
		puts "Deleting the tmp files created in cutResult proc"
        file delete -force $tmp_oas
		file delete -force $tmp3_oas 
		file delete -force $tmp4_oas 
		file delete -force $forPushDownOAS
		file delete -force $DRC_rdbout 
        file delete -force $DRC_rule_name
		if { $OASout != "" } { 
			file delete -force $rdbout	
		}
	}

    # Run Block RDB output if -blockRDB is set to 1
    if {$debug} { puts "BLOCKRDB: $blockRDB" }
    if { $blockRDB == 0 } { 
        puts "Results output in single file."
    } elseif { $blockRDB == 1 } {
        puts "Block results output individually."
        outputCellRDB $rdbout $debug
        
    }
}

proc createCellRDBFilename { cellname pushrdb } {
    # Split by "/"
    set tokens [split $pushrdb "/"]
    if {0} { puts $tokens }

    # Prepend cellname to last token
    set newRDBFilename [lreplace $tokens end end "${cellname}_[lindex $tokens end]"]
    return [join $newRDBFilename /]
}

proc reportBlockStatistics { lHandle block } {
    puts "BLOCK SUMMARY $block:"
    foreach bLayer [$lHandle layers -cell $block] {
       foreach {bLayerNum bLayerDT} [split $bLayer .] {break}
        set bLayerName [$lHandle layernames $bLayer]

        set bLayerCount [$lHandle iterator count poly $block $bLayer -depth 0 0]
        puts "   $bLayerName : $bLayerCount"
    }
}

proc outputCellRDB { pushedRDB debug } {
    set pRDBHandle [ layout create $pushedRDB -noReport -preserveProperties]
    set pLayers [$pRDBHandle layers]
    set pTopcell [$pRDBHandle topcell]
    set pCells [lsort [ $pRDBHandle cells]]

    if {$debug} {
        puts "pRDBHandle: $pRDBHandle"
        puts "pLayers: $pLayers"
        puts "pTopcell: $pTopcell"
        puts "pCells: $pCells"
    }

    # pCells includes the topcell. If the list is greater than one, there are other cells
    # if not, then no cells were in the output.
    if { [llength $pCells] > 1  } {
        foreach cellOutput $pCells {
            if { [string match $cellOutput $pTopcell] != 1 } { lappend cellOutputList $cellOutput }
        }
        puts "\nWriting block RDB output:"

        foreach cOutput $cellOutputList {
            set cellRDBFilename [createCellRDBFilename $cOutput $pushedRDB]
            set cmd "$pRDBHandle rdbout $cellRDBFilename -cell $cOutput -layers $pLayers"
            if {0} { puts $cmd }
            eval $cmd
            # Report block summary count of results per check
            reportBlockStatistics $pRDBHandle $cOutput
   
            # Output OASIS for debug when set to 1.
            if {0} { 
                set cmd2 "$pRDBHandle oasisout ${cellRDBFilename}.oasis  $cOutput"
                puts $cmd2
                eval $cmd2
            }
        }
        # JMP: Added to output only the top level RDB data. 
        set top_cmd "$pRDBHandle oasisout top_tmp.oas -depth 0 -cBlocks -strictMode -clipsNone -maxPolygonVertices 8191 -maxPathVertices 1024"
        ;#puts "top_cmd: $top_cmd"
        eval $top_cmd
        set L_toponly [layout create top_tmp.oas]
        set top_cmd2 "$L_toponly rdbout ${pTopcell}_pushed.rdb -cell $pTopcell -layers $pLayers -hier"
        ;#puts "top_cmd2: $top_cmd2"
        eval $top_cmd2
		file delete -force top_tmp.oas ;# from blockRDB top-level RDB output proc

    } else {
        puts "No blocks found in $pushedRDB."
    }

}


set totalTime [ time { 


    set rdbIn ""
    set origDB ""
    set outputDir  ""
    set cellFile   ""
    set UBMlayer ""
    set OASout ""
    set debug "0"
    set promote "1"	
	# default for promote is "1" so it will CUT the shapes and also promote the results from lower level cells to topcell
    set blockRDB "0"	
    set boundaryLayer ""
    set rdbout ""

	# set up initial values for the tmp file names that is going to be used in the script..

	set reducedOAS "reduced.[pid].oas"
	set convertedOAS "2_converted.[pid].oas"
	set tmpLayer 2099.331
	set layerBump 1000
	set tmpTopcell "tmptop.[pid]"
	set forPushDownOAS "1_forPushDown.[pid].oas"	
	
    ######################################################
    # Set up initial vars from Arguments
    ######################################################
    for {set i 0} {$i < $argc} {incr i} {
        set arg [lindex $argv $i]
        switch -exact -- $arg {
            "-rdbIn" {
                            set rdbIn [lindex $argv [expr {$i+1}]]
                            incr i
                        }
            "-origDB" {
                            set origDB [lindex $argv [expr {$i+1}]]
                            incr i
                            }

	      "-cellFile" {
                            set cellFile [lindex $argv [expr {$i+1}]]
                            incr i
                        }
	      
	      "-rdbout" {
                            set rdbout [lindex $argv [expr {$i+1}]]
                            incr i
                        }
		
	      "-OASout" {
                            set OASout [lindex $argv [expr {$i+1}]]
                            incr i
                        }
		

	      "-UBMlayer" {
                            set UBMlayer [lindex $argv [expr {$i+1}]]
                            incr i
                        }
		
	      "-debug" {
                            set debug [lindex $argv [expr {$i+1}]]
                            incr i
                        }

	      "-promote" {
                            set promote [lindex $argv [expr {$i+1}]]
                            incr i
                        }
	      
	      "-blockRDB" {
                            set blockRDB [lindex $argv [expr {$i+1}]]
                            incr i
                        }

	      "-boundaryLayer" {
                            set boundaryLayer [lindex $argv [expr {$i+1}]]
                            incr i
                        }

             default {
			showHelp
			puts "unknown option [lindex $argv $i ]"
			exit

                }
            }
    }

    if { $debug } {
		puts "debug >> input arguments: rdb = $rdbIn origDB == $origDB , cellFile = $cellFile, rdbout = $rdbout boundaryLayer = $boundaryLayer"
    }
    if { $origDB == "" || $cellFile =="" } {
	
	showHelp
	exit 	
    } elseif {  $OASout == "" && $rdbout =="" } {

	showHelp
	exit 	

    } elseif { $rdbIn == "" && $UBMlayer ==""  } {

	showHelp
	exit 	

    }

	# first step, reduce the database size, it shuold reduce the database that downstream flow needs to process to improve the runtime
	if { [ catch { 	reduceDBsize $origDB $reducedOAS $cellFile $debug $tmpLayer $boundaryLayer $tmpTopcell $forPushDownOAS }  msg ] } {
		puts  "Error while creating a reduced database to improve runtime, please contact your Mentor AE/TME for support"
		puts  "Error message = $msg"
		exit
	} else {
		puts "Done creating reduced database"
	}
	

	# second step: check whether the input database has the same precision as the rdb file, if not, create a OASIS file that has the same precision as the rdb file
	# The assumption is: if there are differences between those two files' precision, rdb is the one has higher precision.
	#
	
	if { [ catch { checkPrecision $rdbIn $reducedOAS $convertedOAS $rdbout $debug } msg ] } {
		puts  "Error while changing precision for OASIS file so it matches the precision for rdb file, please contact your Mentor AE/TME for support"
		puts  "Error message = $msg"
		exit
	} else {
		puts "Done changing precision to OASIS file"
	}
		
	# third step: has three main functions:
	# if promote option is set ( it is on by default), the first step is to promote the lower level results to top level. 
	# if promote option is set ( it is on by default), the second step is for when a result is across two blocks, then it will try to cut one results into two different segements
	# after process the rdb file, it will run the pushmarker command to push toplevel results to cells that specificed by user

	if { [ catch {  cutResults_new $rdbIn $convertedOAS $cellFile $rdbout $tmpLayer $debug $blockRDB $promote $layerBump $tmpTopcell $forPushDownOAS $OASout $UBMlayer $origDB }  msg ] } {
		puts  "Something went wrong with this script, please contact your Mentor AE/TME for support"
		puts  "Error message = $msg"
		exit
	} else {
		puts "\n============================================ \n"
		#puts "Finished.. \nNew RDB is: $rdbout  \n" 
		puts "Finished.. \nCheck RDB ouput *.rdb \n"
	}

	if { $debug == 0 } {
	
		puts "Deleting the tmp files "
		file delete -force $reducedOAS
		file delete -force $convertedOAS
	}

}

 ]   

set us [lindex $totalTime 0]
set sec [expr {$us/1000000.0}]
set timeString "[format "%.2f seconds\n" $sec]"

set minutes 0
set hours   0

if { $sec > 60 } {
    set minutes [expr int($sec / 60)]
    set seconds [expr {$sec - ($minutes * 60)} ]
    set timeString  "${minutes}m ${seconds}s"
}
if { $minutes > 60 } {
    set hours   [expr int($minutes / 60)]
    set minutes [expr {$minutes - ($hours * 60)} ]
    set timeString  "${hours}h ${minutes}m ${seconds}s"
}

puts "\nTotal time: $timeString"
