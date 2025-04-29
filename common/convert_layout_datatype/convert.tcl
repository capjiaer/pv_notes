# This function help to switch gds layout into oasis
if {$argc < 1} {
    puts "Try bsub -Ip calibredrv convert.tcl <<input_gds>> <<output_oasis>>"
    exit
}

set inputlayout [lindex $argv 0]

if {$argc == 1} {
    set outlayout [file tail $inputlayout]
    set outlayout [string map {.gds .oas} $outlayout]
} else {
    set outlayout [lindex $argv 1]
}

set L [layout create $inputlayout -dt_expand -preservePaths -preserveTextAttributes -preserveProperties]

$L oasisout $outlayout
puts "$outlayout Generated"