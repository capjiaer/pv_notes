set list1 "NET SPNET PIN LEFPIN FILL FILLOPC VIAFILL VIAFILLOPC VIA"
set list2 "PIN LEFPIN"
set outline_layer "62.21"


proc gen_layer_map {layer_name layer_number1 list1 layer_number2 list2} {


    set layer_info ""
    
    lassign [split $layer_number1 .] layer_number data_type1
    foreach ele $list1 {
        set info1 "$layer_name $ele $layer_number $data_type1"
        lappend layer_info $info1
    }

    lassign [split $layer_number2 .] layer_number data_type2
    foreach ele $list2 {
        set info2 "NAME $layer_name/$ele $layer_number $data_type2"
        lappend layer_info $info2
    }
    return $layer_info
}


set foundry_layer_list      "M1 M2 M3   F4  F5  D6  D7  D8  D9  D10 D11 D12 IA  IB  LB"
set foundry_layer_number    "15 17 19   177 178 171 196 596 598 688 695 700 136 137 69"

set my_file [open "layermap.txt" w]

foreach layer $foundry_layer_list number $foundry_layer_number {
    set my_list [gen_layer_map $layer $number.0 $list1 $number.20 $list2]
    foreach ele $my_list {
        puts $my_file $ele
    }
}
lassign [split $outline_layer .] layer_number data_type
puts $my_file "COMP ALL $layer_number $data_type"
close $my_file