if {$argc > 3} {
    puts "Error, please try: calibredrv rename_cell.tcl <YOUR_LAYOUT> <CELL_NAME1> <CELL_NAME2>"
    puts "Example: bsub -Ip calibredrv rename_cell.tcl ./layout0.gds new_top"
    puts "CEll rename if requried"
    exit
}
# Step1: Create ref
set inputlayout [lindex $argv 0]
set L [layout create $inputlayout -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
set top_name [$L topcell]
$L flatten cell $top_name
set target_cellname STAR_1_JS_extra_dummyFill

$L cellname $top_name $target_cellname
$L oasisout [file rootname [file tail $inputlayout]].oas $target_cellname