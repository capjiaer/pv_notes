## remote.temp
LAUNCH CLUSTER WAIT 60 COUNT <<:TOTAL_CPU:>> MINCOUNT <<:MIN_CPU:>>
REMOTE COMMAND bsub ARGUMENTS [<<:QUEUE_INFO:>> -J CalRemote[1-<<:CLUSTER_NUM:>>] -n <<:CLUSTER_CPU:>> <<:WORK_DIR:>>/launch_remote.sh]
//REMOTE COMMAND bsub ARGUMENTS [<<:QUEUE_INFO:>> -J CalRemote[1-<<:CLUSTER_NUM:>>] -n <<:CLUSTER_CPU:>> -R "select[hname!='%H']" <<:WORK_DIR:>>/launch_remote.sh]
// REMOTE COMMAND launch_locals.sh ARGUMENTS [32]

## launch_remote.sh
#!/bin/sh -f
############################################################
# File Name: launch_remote.sh
# Author: anping.chen
# Email: anping.chen@joinsilicon.com
# Created Time: Mon 15 Jul 2024 03:49:44 PM CST
############################################################
for host in $LSB_HOSTS
do
    rcalibre "/tmp" 0 -mtflex $CALIBRE_REMOTE_CONNECTION -64 -f &
done
wait

## launch_locals.sh
############################################################
# File Name: launch_locals.sh
# Author: anping.chen
# Email: anping.chen@joinsilicon.com
# Created Time: Mon 15 Jul 2024 03:51:07 PM CST
############################################################

c=0
while [$c -lt $1] ; do
    recalibre /tmp 0 -mtflex $CALIBRE_REMOTE_CONNECTION -64
    c=$((c + 1))
done

#####################################################################
# set execopt(lsf_remote_str) "-hyper remote -remotedata -recoveroff -remotefile $pv_calibre($flowtype,lsf_remote_file)"
