# P1: bsub your xterm into a main machine
bsub -q pdk_pv -m epyc-node01 xterm -e "source run_3ddrc.csh"

# P2: details for run_3ddrc.csh

set workdir = path/to/workdir
cd $workdir
setenv MGC_CWB_TMP_DIR $workdir

setenv CALIBRE_HOME /lab/eda/calibre/aok_cal_2025.4_18.11

calibre -64 -hier -turbo -turbo_litho -nowaite -remotefile mtflex.config -hyper -drc <your_svrf_file> |& tee -i calibre_drc.log


# P3: details for mtflex.config

mtflex.config:
HYPER LICENSE ALL SMTFACTOR 1
remote host epyc-node02 128 MGC_HOME /lab/eda/calibre/aok_cal_2025.4_18.11 RSH /usr/bin/ssh DRC /tmp
remote host epyc-node01 128 MGC_HOME /lab/eda/calibre/aok_cal_2025.4_18.11 RSH /usr/bin/ssh DRC /tmp
...
