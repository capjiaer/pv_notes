if {$argc < 3} {
    puts "Error, please try: calibredrv fast_merge.tcl <YOUR_LAYOUT> <MERGED_LAYOUT> <SUB_LAYOUT1> <SUB_LSYOUT2>"
    puts "Example: bsub -Ip calibredrv fast_merge.tcl ./layout0.gds merged_out.gds sub1.gds sub2.gds .."
    puts "Fast Merge sub1.gds sub2.gds ... into layout0.gds"
    exit
}
# Step1: Get top cell info
set inputlayout [lindex $argv 0]
set outputlayout [lindex $argv 1]
set L [layout create $inputlayout -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
set ori_topcell [$L topcell]

set sub_list [lrange $argv 2 end]
foreach sub_layout $sub_list {
    # Get top cell name for each sub_layout, import them and creat ref
    set sub_topcell [layout peek $sub_layout -topcell]
    $L import layout $sub_layout FALSE rename -dt_expand -preservePaths -preserveTextAttributes -preserveProperties
    # Ref create for the next movement
    $L create ref $ori_topcell $sub_topcell 0 0 0 0 1
}
$L oasisout $outputlayout $ori_topcell
