 #
 exp=${1}
 HOST=${2}
 nextname=${3}
 nextstep=${4}
 LAUNCH_COMMAND=${5}
 listing=${6}
 # 
 # Mode CLIMAT: On lance le prochain interval
 # Ce code est concu pour etre appelle en mode
 # "inline" par la scrip Um_launch de GEM/DM
 #
 # Verifier d'abord les conditions d'exeption
 #
 arreter=`rsh ${HOST} -n "if [ -f ${REPCFG}/arreter_prochain_cycle ] ; then echo oui ; else echo non ; fi" `
 #
 if [ "$arreter" = "oui" ] ; then
  #
  echo "Le lanceur a recu un signal arreter_prochain_cycle."
  #
  cat >relance_tmp <<FIN_relance
    #!/bin/ksh
    #
    echo "\nRedemarrage de ${exp%_*}\n"
    . r.sm.dot ${MODEL} ${MODEL_VERSION}
    rm -f ${REPCFG}/arreter_prochain_cycle
    ${LAUNCH_COMMAND} ${REPCFG} -exp ${nextname} \
    -continue ${exp} -step_total ${nextstep} -stepout ${_endstep}
FIN_relance
  #
  chmod a+x relance_tmp
  nrcp relance_tmp ${HOST}:${REPCFG}/relancer_prochain_cycle
  rm -f relance_tmp
  #
 else
  #
  echo "\n#####################################"
  echo "# Launching next climatic interval  #"
  echo "# named: ${nextname} "
  echo "# ==> Will run up to step ${nextstep} "
  echo "#####################################\n"
  #
  cd ${EXECDIR}
  touch BUSY_WITH_RELAUNCH
  #
  cat >  continue_with_next_job <<end_of_continue_job
    . r.sm.dot ${MODEL} ${MODEL_VERSION} ; cd ${REPCFG}
    ${LAUNCH_COMMAND} . -exp ${nextname} -continue ${exp} \
             -step_total ${nextstep} -stepout ${_endstep}
end_of_continue_job
  #
  soumet continue_with_next_job -mach ${HOST} -cm 25000 -t 200 \
        -jn autolaunch_${nextname} -listing ${listing}
  #
  echo "\n#####################################"
  echo "# continue_with_next_job is as follows:"
  echo "\n#####################################"
  cat continue_with_next_job
  echo "\n#####################################"
  rm -f continue_with_next_job
  #
 fi
