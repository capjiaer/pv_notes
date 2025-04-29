if {$argc < 2} {
    puts "Error, please try: calibredrv createref_cell.tcl <YOUR_LAYOUT> <SUB_LAYOUT1> <SUB_LSYOUT2>"
    puts "Example: bsub -Ip calibredrv createref_cell.tcl ./layout0.gds sub.gds"
    puts "Fast Merge sub.gds into layout0.gds"
    exit
}
# Step1: Create ref
set inputlayout [lindex $argv 0]
set L [layout create $inputlayout -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]
set ori_topcell [$L topcell]

set sub_list [lrange $argv 1 end]
foreach sub_layout $sub_list {
    set sub_topcell [layout peek $sub_layout -topcell]
    $L import layout $sub_layout FALSE rename -dt_expand -preservePaths -preserveTextAttributes -preserveProperties
    # Ref create for the next movement
    $L create ref $ori_topcell $sub_topcell 0 0 0 0 1
}
$L oasisout post_[file tail $inputlayout] $ori_topcell