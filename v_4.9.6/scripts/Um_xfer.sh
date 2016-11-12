#!/bin/ksh
#
arguments=$*
exper_name=${1}
if [ -s ${HOME}/exper_configs/${exper_name}.generic/.config_file.dot.cfg ] ; then
  . r.get_config.dot -exper ${exper_name} -file .config_file.dot
fi
. r.entry.dot
#====> Obtaining the arguments:
eval `cclargs_lite $0 \
     -exp       "$exp"            ""         "[Experiment name]"     \
     -xfer      "$xfer"           ""         "[destination]"         \
     -xferl     "${xferl:-0}"     "0"        "[xfer model listing along with model output]"         \
     -job       "${job}"          ""         "[User defined jobname]" \
     -ppid      "${ppid}"         ""         "[Optional process ID of the caller]" \
     -endstepno "${endstepno:-0}" ""         "[endstep number]"      \
     -npe       "${npe:-1}"       "1"        "[number of subdomains]"\
     -status    "ED"              "ED"       "[job status]"          \
     -logext    ""                ""         "[ext for cmclog file ]"\
     -climat    "${climat:-0}"    "0"        "[climate mode flag]"   \
     -_listing  "$listing"        "$CRAYOUT" "[listing directory]"   \
     -diagnos   "$diagnos"        ""         "[Run script Climat_lancer_diag]" \
     -tailjob   "$tailjob"        ""         "[Tail job to be qsubbed]"  \
     -fularch   "$fularch"        ""         "[Name of restart archive]" \
     -lehost    "${lehost:-pollux}" ""       "[Name of intermediary host]"\
     -pilout    "${pilout:-0}"    "1"        "[Sauvegarder pour piloter LAM?]"\
     -continue  ""                ""         "[Continuation indicator for Climat_xfer]"\
  ++ $arguments`
#
if [ "$job" ] ; then
  lajob=${job}
else
  echo "-job must be specified -- ABORT -- \n"
  exit 3
fi
#
listing=${listing:-${HOME}/listings}
listing_ft=${listing}
if [ -d $listing/$lehost -o -L $listing/$lehost ] ; then
  listing_ft=$listing/$lehost
fi
#
PPID=$$
if [ "${ppid}" ] ; then 
  lajob=${lajob}_${ppid}
fi
#
if [ ! "${logext}" ] ; then logext=${endstepno} ; fi
#
if [ "${fularch}" ] ; then fularch=${archdir:-.}/${fularch} ; fi
#
if [ "${status}" != "ED" ] ; then
  tailjob=""
fi
if [ "${climat}" -gt 0 ] ; then
  if [ "${status}" != "ED" ] ; then
    diagnos="0"
    fularch=""
  elif [ -f "$CMC_LOGFILE" ] ; then
    mv $CMC_LOGFILE ${EXECDIR}/`basename ${CMC_LOGFILE}`${logext}
  fi
fi
#
if [ ! "$xfer" ] ; then
  echo "\n No file xfer requested\n"
  exit
fi
xfer_spe=`echo $xfer | sed 's/:/ /g'`
if [ `echo $xfer_spe | wc -w` -lt 2 ] ; then
  echo "\n Syntax error with argument -xfer of Um_xfer.sh"
  echo " Must be of the form target_machine:target_directory --ABORT-- \n"
  exit
fi
xfer=`echo $xfer_spe | sed 's/ /:/g'`
#
endstep=xxx
if [ "$endstepno" ] ; then
  if [ $endstepno -gt 0 ] ; then
    endstep=`echo ${endstepno} | sed 's/^0*//'`
  else
    endstep=0
  fi
fi
xfer_job=${lajob}_FT_$endstep
LISTING_FT_NM=${xfer_job}_$PPID
LISTM=""
if [ $xferl -gt 0 ] ; then
  LISTM=${LISTING}/${LISTING_NM}
fi
#
ici=${PWD}
nf2xfer=0
#
cd output 2> /dev/null
#
if [ $? -eq 0 ] ; then
  echo "################# content of directory output #################"
  ls -l
  laliste="" ; nbf=`ls -l | wc -l`
  if [ $nbf -gt 1 ] ; then
  for i in * ; do
    if [ ! -d $i ] ; then
      laliste=${laliste}" "${i}
      let nf2xfer=nf2xfer+1
    fi
  done
  fi
  echo "$nf2xfer to transfer: "${laliste}
  echo "###############################################################"
fi
#
if [ $nf2xfer -ge 1 ] ; then
  if [ ! -d last_step_${endstep} ]; then mkdir last_step_$endstep ; fi
  for filename in ${laliste} ; do
    mv ${filename} last_step_${endstep}
  done
  cd last_step_${endstep}
  #
  if [ ${climat} -gt 0 ]; then
    last_list=""
    listing_file=`ls ${LISTING}/${lajob##*/}*`
    for list in ${listing_file} ; do
      if [ -s ${list} ]; then
        last_list=${list}
      fi
    done
    if [ "${last_list}" -a "${status}" = "ED" ] ; then
      echo "\
      nrcp ${mach}:${LISTING}/${lajob##*/}* ${lehost}:${listing_ft} && \
      rsh ${mach} -n /bin/rm -f ${LISTING}/${lajob##*/}*" \
      > ${xfer_job}
    else
      touch ${xfer_job}
    fi
    #
    pivot_rept=WORKING_ON_last_step_${endstep}_files
    dest_mach=${xfer%%:*} ; dest_rept=${xfer##*:}/${exp}
    touch ${HOME}/.WORKING_ON/${exp}_${pivot_rept}
    echo "\
    . r.sm.dot ${MODEL} ${MODEL_VERSION} ; export EXECDIR=$EXECDIR ; \
    Climat_xfer ${exp} -s ${mach}:`true_path .` \
    -d ${xfer}/${exp} -npe ${npe} -diagnos ${diagnos} -fularch ${fularch} \
    -tailjob ${tailjob} -pilout ${pilout} -continue ${continue} \
    1> \${HOME}/listings/${lehost}/${xfer_job} 2>&1" >> ${xfer_job}
  else
    echo "\
    . r.sm.dot ${MODEL} ${MODEL_VERSION} ; \
    export EXECDIR=${EXECDIR} ; \
    Um_xfer ${exp} -s ${mach}:`pwd` -npe ${npe} -tailjob ${tailjob}" \
                   -listm ${LISTM} >> ${xfer_job}
  fi
  #
  echo "\n#########################################"
  echo "#####  XFER job launched on ${lehost}  #####\n"
  cat ${xfer_job}
  echo "\n#########################################"
else
  echo "\n No file to transfer from `pwd`/output \n"
fi
#
if [ -s ${xfer_job} ] ; then
  if [ ${delayed} -ge 1 ]; then
    echo "${xfer_job} moved to $HOME/delayed_jobs/${lehost}"
    /bin/mv ${xfer_job} ${HOME}/delayed_jobs/${lehost}/${xfer_job}.job
  else
    cputime=3600
    cmemory=500000
    echo ${ECHOARG} "\nCommande effectuee:"
    echo soumet ${xfer_job} -mach ${lehost} -t ${cputime} -cm ${cmemory} -listing ${listing} -jn ${xfer_job} -ppid ${PPID}
    echo
    soumet ${xfer_job} -mach ${lehost} -t ${cputime} -cm ${cmemory} -listing ${listing} -jn ${xfer_job} -ppid ${PPID}
  fi
fi
/bin/rm -f ${xfer_job}
_listing=${listing_ft}/${LISTING_FT_NM}
#
. r.return.dot

