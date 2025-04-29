if {$argc != 2} {
    puts "Error, please try: calibredrv add_polygon.tcl <YOUR_LAYOUT> <POLYGON CMD>"
    puts "Example: bsub -Ip calibredrv add_polygon.tcl ./dpma_rx_top.CbFPIPMerge.merged.oas psub2.cal.0321_V2"
    puts "Gen layout with new polygon"
    exit
}
# Please modify your psub2.cal.0321_V2

set my_layout [lindex $argv 0]
set L [layout create $my_layout -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]

source [lindex $argv 1]

$L oasisout "post_[lindex $argv 0]"
