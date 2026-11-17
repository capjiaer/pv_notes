#!/usr/bin/tcsh -f
set in_lef = $1
set out_gds = $2

#set tlef = "/techlib/smic/28HKCPlus1p8v/incoming/tf_tm/scc28n_1p8m_6ma_6ic_2tmc_alpa1.lef"
#set map = "/techlib/smic/28HKCPlus1p8v/incoming/tf_tm/lefStreamin.map"
#set map = "/techlib/smic/28HKCPlus1p8v/incoming/tf_tm/tech.map"
#bi2 fdi2gds -64 -system LEFDEF -lef $tlef /projects/wasp/exchange/IP_to_SOC/analog/20240902/S28_EFUSE_PSW/lef/S28_EFUSE_PSW.lef -precision 1000 -layermap $map  -outfile S28_EFUSE_PSW.gds


set tlef = "/projects/pelican03/work/xiaxiaojun/LIBRARY/DesignKit/PNR/tf_innovus/LN14LPU_INNOVUS_A01-V1.0.3.0/11M_3Mx_4Cx_2Kx_2Gx_LB/8p25TR/ln14lpu_tech_11M_3Mx_4Cx_2Kx_2Gx_LB.small.die.lef"
#set map = "/projects/pelican03/work/xiaxiaojun/LIBRARY/DesignKit/PNR/tf_innovus/LN14LPU_INNOVUS_A01-V1.0.3.0/11M_3Mx_4Cx_2Kx_2Gx_LB/tech.map"
set map = "/projects/pelican03/work/songlincai/COMMON/hack_data/map"

bsub -n 1 -q pelican03 -Is fdi2gds -64 -system LEFDEF -lef $tlef $in_lef -precision 1000 -annotatePins TEXT -layermap $map  -outfile $out_gds
