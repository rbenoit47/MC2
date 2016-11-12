#!/bin/ksh
#
if [ ! $MODEL -o ! $MODEL_VERSION ] ;then
  echo "\n Model environment not set properly --- ABORT ---\n"
  exit 1
fi
arguments=$*
#
ici=`pwd`
#
. r.entry.dot
exper_name=${1}
if [ -s ${HOME}/exper_configs/${exper_name}.generic/.config_file.dot.cfg ] ; then
  set -x
  . r.get_config.dot -exper ${exper_name} -file .config_file.dot
  set +x
fi
anal=${anal:-${MODEL_PATH}/dfiles/$ARCH/bcmk/1996071900_000}
climato=${climato:-${MODEL_PATH}/dfiles/$ARCH/bcmk/clim_gef_400_mars96}
geophy=${geophy:-${MODEL_PATH}/dfiles/$ARCH/bcmk/geophy_400}
inrep=${inrep:-${MODEL_PATH}/dfiles/$ARCH/bcmk}
execdir=${execdir:-${ici}}
debug=${debug:-0}
climat=${climat:-0}
_status=ABORT
#
eval `cclargs_lite $0 \
     -inrep   "$inrep"      "$inrep"      "[input directory (LAM)]"   \
     -anal    "$anal"       "$anal"       "[input analysis]"          \
     -climato "$climato"    "$climato"    "[input climato]"           \
     -geophy  "$geophy"     "$geophy"     "[geophysical fields]"      \
     -anclim  "$anclim"     "$anclim"     "[analyzed climate]"        \
     -outrep  "$outrep"     ""            "[output directory]"        \
     -runent  "${runent:-0}" "1"          "[run entry program]"       \
     -runmod  "${runmod:-0}" "1"          "[run main  program]"       \
     -debug   "$debug"      "1"           "[Debug mode flag]"         \
     -climat  "$climat"     "1"           "[climate mode flag]"       \
     -_status "ABORT"       "ABORT"       "[return status]"           \
     -_endstep ""           ""            "[last time step performed]"\
     -_npe     "1"          "1"           "[number of subdomains]"    \
  ++ $arguments`
#
#=====> SET UP
echo "\n ****** Um_maindriver begins ******\n"
export WA_CONFIG='1024 4 4 0'
export EXECDIR=${EXECDIR:-${execdir}}
export REPRUN=process
RM=/bin/rm
MV=/bin/mv
#
#=====> LAUNCHING entry program
#
_status=ED
if [ $runent -gt 0 ] ; then
  if [ -s boot ] ; then
    $RM -rf $REPRUN
  fi
  . r.call.dot Um_runent.sh -inrep $inrep -anal $anal -climato $climato -geophy $geophy -debug $debug
fi
#
#=====> LAUNCHING main program
#
if [ "$_status" = "ED" ] ; then
  if [ $runmod -gt 0 ] ; then
  . r.call.dot Um_runmod.sh -climato $climato -anclim $anclim -outrep $outrep -debug $debug -climat $climat
    if [ "$_status" = "ABORT" ] ; then
       echo "\n Um_runmod.sh ended abnormally -- EXIT ---\n"
    fi
  fi
else
  _status=ABORT
  echo "\n Um_runent.sh ended abnormally -- EXIT ---\n"
fi
#
if [ "$_status" = "ED" -a $debug -eq 0 -a $climat -eq 0 ] ; then
  if [ $runmod -gt 0 ] ; then
    $RM -rf $REPRUN/geophy.bin $REPRUN/labfl.bin $REPRUN/bm*
  fi
fi
#
if [ "$_status" = "ABORT" ] ; then
   if [ $debug -eq 0 -a $climat -eq 0 ] ; then
     $RM -f ${REPRUN} 2> /dev/null
   fi
fi
#
echo "\n ****** Um_maindriver ends ********\n"
. r.return.dot


