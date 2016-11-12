#!/bin/ksh
#
if [ ! $MODEL -o ! $MODEL_VERSION ] ;then
  echo "\n Model environment not set properly --- ABORT ---\n"
  exit 1
fi
arguments=$*
#
. r.entry.dot
_status=ABORT
#
eval `cclargs_lite $0 \
  -outcfg   "outcfg.out"   ""          "[file name for output controller (gem only)]"\
  -outrep   ""             ""          "[output directory]"                          \
  -debug    "0"            "1"         "[debug mode]"                                \
  -no_mpi   "0"            "1"         "[Do NOT use r.mpirun]"                       \
  -climat   "0"            "1"         "[climate mode flag]"                         \
  -climato  "$climato"     "$climato"  "[climato  (gem climate-mode only)]"          \
  -anclim   "$anclim"      "$anclim"   "[analyzed climate (gem climate-mode only)]"  \
  -_status  "ABORT"        "ABORT"     "[return status]"                             \
  -_endstep ""             ""          "[last time step performed]"                  \
  -_npe     "1"            "1"         "[number of subdomains]"                      \
  ++ $arguments`
#
ici=`pwd`
#
export REPRUN=${REPRUN:-process}
export CMC_LOGFILE=${CMC_LOGFILE:-${ici}/${REPRUN}/cmclog}
export rep_from_which_model_is_launched=$ici
export EXECDIR=${EXECDIR:-${ici}}
export F_ERRCNT=100
#export F_SETBUF06=1
MAIN=main${MODEL}dm_${ARCH}_${MODEL_VERSION}.Abs
#
nml=${MODEL}_settings.nml
if [ ! -s $nml ] ; then
  echo "\n PROBLEM WITH FILE $nml --ABORT--\n"
  exit
else 
  ln -sf ${ici}/${nml} $REPRUN/model_settings
fi
#
if [ -s $outcfg ] ; then
  ln -sf ${ici}/$outcfg $REPRUN/output_settings
elif [ -s outcfg.out ] ; then
  ln -sf ${ici}/outcfg.out $REPRUN/output_settings
fi
#
if [ ${climato} ] ; then
  if [ ! -s $REPRUN/imclima ] ; then
    ln -sf $climato $REPRUN/imclima ; ls -l $REPRUN/imclima
  fi
fi
if [ ${anclim} ] ; then
  if [ ! -s $REPRUN/imanclima ] ; then
    ln -sf $anclim $REPRUN/imanclima ; ls -l $REPRUN/imanclima
  fi
fi
#
printenv > .resetenv
npx=`grep -i npex $nml | sed "s-\(.*\)\(npex *= *[0-9]*\)\(.*\)-\2-p"`
npy=`grep -i npey $nml | sed "s-\(.*\)\(npey *= *[0-9]*\)\(.*\)-\2-p"`
npx=${npx##*=}
npy=${npy##*=}
let _npe=npx*npy
#
mkdir $REPRUN 2> /dev/null
cd $REPRUN
if [ $? != 0 ] ; then
  echo "\n PROBLEM WITH DIRECTORY $REPRUN --ABORT--\n"
  exit  
else
  if [ ! -s 00-00/restart ] ; then
    /bin/rm -rf [0-9]*
    cntx=0
    while [ $cntx -lt $npx ] ; do
    cnty=0
    while [ $cnty -lt $npy ] ; do
       let s1=100+$cntx
       let s2=100+$cnty
       s1=`echo $s1 | sed 's/^1//'`
       s2=`echo $s2 | sed 's/^1//'`
       mkdir ${s1}-${s2}
       let cnty=cnty+1
    done 
    let cntx=cntx+1
    done
  else
    echo "\n RESTART MODE \n"
  fi
fi
#
cd $ici
if [ -s constantes ] ; then
  ln -sf `pwd`/constantes ${REPRUN}/00-00/constantes
fi
if [ -s ozoclim    ] ; then
  ln -sf `pwd`/ozoclim ${REPRUN}/00-00/ozoclim
fi
if [ -s ozoclim_32 ] ; then
  ln -sf `pwd`/ozoclim_32 ${REPRUN}/00-00/ozoclim_32
fi
if [ -s irtab5_std ] ; then
  ln -sf `pwd`/irtab5_std  ${REPRUN}/00-00/irtab5_std
fi
if [ -s irtab5_32  ] ; then
  ln -sf `pwd`/irtab5_32  ${REPRUN}/00-00/irtab5_32
fi
#
echo localhost $_npe > ${REPRUN}/mpi_nodes.cfg
#
if [ ${outrep} ] ; then
  outrep2=' '
  if test $climat -gt 0 ; then outrep2=/`basename $ici` ; fi
  if [ "$outrep" != "output" ] ; then
    ln -sf ${outrep}${outrep2} output
    if [ ! -d ${outrep}${outrep2} ]; then mkdir -p ${outrep}${outrep2} ; fi
  fi
else
  outrep=output
  mkdir $outrep 2>/dev/null
fi
mkdir ${outrep}/casc 2>/dev/null
if [ ! -s $REPRUN/00-00/restart ] ; then
  /bin/rm -f ${outrep}/casc/* 2> /dev/null
fi
/bin/rm -f ${outrep}/* 2> /dev/null
lebin=${MODEL}dm
#
if [ -s $MAIN ] ; then
  echo "Running $lebin ($MAIN) on $_npe ($npx x $npy) PEs:"
  if [ $debug -gt 0 ] ; then
    if [ $_npe = 1 -a $HOSTTYPE = IRIX5 ]; then
      echo "dbx $MAIN (use command: run -$lebin to proceed)"
      dbx $MAIN
    else
      echo "debug mode implies npe=1 and HOSTTYPE=IRIX5"
      exit
    fi
  else
#    export F_ERRCNT=2
    export MPIPROGINF=ALL_DETAIL
    if [ $no_mpi -eq 0 ] ; then
      echo "r.mpirun -pgm $MAIN -npex $npx -npey $npy"
      echo OMP_NUM_THREADS=$OMP_NUM_THREADS
      r.mpirun -pgm $MAIN -npex $npx -npey $npy
      /bin/rm -f mpi_nodes.cfg
    else
      if [ $_npe -gt 1 ] ; then
        echo "NPEX and NPEY must both be equal to 1 when NOT using mpirun --- ABORT ---"
        exit
      else
        echo "$MAIN"
        $MAIN
      fi
    fi
  fi
  /bin/rm -rf $REPRUN/model_settings
  /bin/rm -rf $REPRUN/imclima $REPRUN/imanclima
  if [ -s status.dot ] ; then
    . status.dot ; /bin/rm -f status.dot
  fi
else
  echo "\n $MAIN not available\n"
fi
#
if [ "$_status" = "ED" ] ; then
   mv $REPRUN/time_series.bin $EXECDIR/output 2> /dev/null
   if [ $climat -gt 0 ] ; then
     cp $REPRUN/[0-9]*/zonaux_* $EXECDIR/output 2> /dev/null
   elif [ $debug -eq 0 ]; then
     mv $REPRUN/[0-9]*/zonaux_* $EXECDIR/output 2> /dev/null
     for i in ${REPRUN}/[0-9]* ; do
       if [ -d $i ] ; then
         /bin/mv $i/*hpm* ${REPRUN} 2> /dev/null
         /bin/rm -rf $i
       fi
     done
   fi
fi   
#
. r.return.dot




