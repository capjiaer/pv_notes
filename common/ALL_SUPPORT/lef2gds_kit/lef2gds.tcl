#!/usr/bin/tclsh

proc main {argv} {
    # 默认参数
    set tlef ""
    set lef ""

    # 解析命令行参数
    for {set i 0} {$i < [llength $argv]} {incr i} {
        set arg [lindex $argv $i]
        switch -- $arg {
            "-tlef" {
                set tlef [lindex $argv [incr i]]
            }
            "-lef" {
                set lef [lindex $argv [incr i]]
            }
            default {
                puts stderr "Unknown option: $arg"
                exit 1
            }
        }
    }


    # 检查必要参数
    if {$tlef eq "" || $lef eq ""} {
        puts stderr "Usage: my_csh -tlef <tlef_file> -lef <lef_file>"
        exit 1
    }

    # 提取 lef 文件名（不带路径和后缀）
    set lef_basename [file rootname [file tail $lef]]
    set outfile "${lef_basename}.gds"

    # Step1: 生成 layermap.txt
    set map_file "./layermap.txt"
    set gen_layermap_dir [file dirname [info script]]
    exec tclsh $gen_layermap_dir/gen_layermap.tcl



    # Step2: 运行 fdi2gds
    set cmd_output [exec bsub -Ip fdi2gds -system LEFDEF -map $map_file -annotatePins TEXT -lef $tlef $lef -outfile $outfile 2>@1]
    # 提取关键行
    foreach line [split $cmd_output "\n"] {
        if {[string match "*OUTPUT:*" $line] || [string match "*LAYOUT FILE SIZE:*" $line]} {
            puts $line
        }
    }
    puts "GDS file generated: $outfile"
}

main $argv