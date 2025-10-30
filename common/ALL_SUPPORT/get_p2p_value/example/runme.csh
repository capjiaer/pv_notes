tclsh ../p2p_run.tcl -layout_file ./layout0.gds -resistance_file ./required_rules/rules.RO -lvs_file ./required_rules/perc_lvs_deck -probe_file ./pin_pair.txt -precision 1000 -include_files ./required_rules/rules.S
module load calibre/2024.1
bsub -Ip calibre -perc -hier -turbo -ldl perc.svrf | tee perc.log