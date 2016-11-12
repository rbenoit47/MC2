#!/bin/ksh
#
if [ ! $MODEL -o ! $MODEL_VERSION ] ;then
  echo "\n Model environment not set properly --- ABORT ---\n"
  exit 1
fi
#
. r.entry.dot
inrep=$MODEL_PATH/dfiles/$ARCH/bcmk
anal=$MODEL_PATH/dfiles/$ARCH/bcmk/20010920.120000
climato=$MODEL_PATH/dfiles/$ARCH/bcmk/clim_gef_400_mars96
geophy=$MODEL_PATH/dfiles/$ARCH/bcmk/geophy_400
_status=ABORT
#
eval `cclargs_lite $0 \
  -inrep   "$inrep"           "$inrep"    "[input directory]"\
  -anal    "$anal"            "$anal"     "[analysis]"\
  -climato "$climato"         "$climato"  "[climatology file]" \
  -geophy  "$geophy"          "$geophy"   "[genesis file ]" \
  -theoc   "0"                "1"         "[theoretical cases]"\
  -r       "0"                "1"         "[remove restart files]"\
  -debug   "0"                "1"         "[debug mode]"\
  -_status "ABORT"            "ABORT"     "[return status]"\
  ++ $*`
#
ici=`pwd`
#
export REPRUN=${REPRUN:-process}
export rep_from_which_model_is_launched=$ici
export CMC_LOGFILE=${CMC_LOGFILE:-${ici}/${REPRUN}/cmclog}
export F_ERRCNT=2000
#export F_SETBUF06=1
MAIN=main${MODEL}ntr_${ARCH}_${MODEL_VERSION}.Abs
#
mkdir ${REPRUN} 2> /dev/null
cd $REPRUN
if [ $? != 0 ] ; then
  echo "\n PROBLEM WITH DIRECTORY $REPRUN --ABORT--\n"
  exit 1   
fi
cd $ici
#
nml=${MODEL}_settings.nml
if [ ! -s $nml ] ; then
  echo "\n PROBLEM WITH FILE $nml --ABORT--\n"
  exit 1
else 
  /bin/rm -f $REPRUN/model_settings
  ln -s ${ici}/${nml} $REPRUN/model_settings
fi
#
if [ ! -s $REPRUN/00-00/restart ] ; then
  rstrt=0
else
  if [ $r -eq 0 -a $theoc -eq 0 ] ; then
    echo "\n RESTART MODE \n"
    rstrt=1
  fi
fi
if [ $rstrt -eq 0 ] ; then
  /bin/rm -rf $REPRUN/[0-9]* $REPRUN/bm* $REPRUN/geophy.bin $REPRUN/labfl.bin $CMC_LOGFILE
fi
#
if [ $theoc -eq 1 ] ; then
  exit 0
fi
#
lebin=${MODEL}ntr
lam=0
pstring=Pil_runstrt_S
if [ "${MODEL}" = "mc2" ] ; then
  lam=1
else
  grid=`grep -i Grd_typ_S $nml | sed "s-\(.*\)\(Grd_typ_S\)\( *= *'\)\(.*\)\( *'.*\)-\4-p" \
                               | grep -i l | wc -l`
  if [ $grid -gt 0 ] ; then
    lam=1
  fi
fi
#
if [ -x $MAIN ] ; then
  export F_PROGINF=""
  if [ $lam -lt 1 ] ; then
    echo "\n Ckecking analysis file: $anal for geophysical fields"
    r.filetype $anal
    if [ $? = 1 ] ; then
       /bin/rm -f ${anal}_2000tmp
       editfst2000 -s ${anal} -d ${anal}_2000tmp -i /dev/null
       /bin/mv ${anal}_2000tmp ${anal}
    fi
    geophy_2000.Abs -anal $anal
    /bin/rm -f $REPRUN/analysis ; ln -s $anal $REPRUN/analysis
  else	
    ladate=`grep -i $pstring $nml`
    if [ `echo $ladate | wc -w` -gt 0 ] ; then
      ladate=${ladate%%,*}
      ladate=`echo ${ladate##*=} | sed 's/"//g' | sed 's/\.//g'`
    else
      echo "\n LAM CONFIGURATION: $pstring must be specified in namelist &gement --- ABORT ---\n"
      exit
    fi
    fn='nul'
    for i in $inrep/* ; do
       if [ `r.fstliste -izfst $i -vdatev $ladate | grep UU | wc -l` -gt 0 ] ; then
         fn=$i
         break
       else
         if [ `r.fstliste -izfst $i -vdatev $ladate | grep UT1 | wc -l` -gt 0 ] ; then
         fn=$i
         break
         fi
       fi
    done
    if [ -s $fn ] ; then
      echo "\n Ckecking input file: $fn for geophysical fields"
      r.filetype $fn
      if [ $? = 1 ] ; then
        /bin/rm -f ${i}_2000tmp
        editfst2000 -s ${i} -d ${i}_2000tmp -i /dev/null
        /bin/mv ${i}_2000tmp ${i}
      fi 
      geophy_2000.Abs -anal $i
    else
      echo "\n NO DATA AVAILABLE IN $inrep \n FOR $ladate ------ ABORT -----\n"
      exit
    fi
    /bin/rm -f $REPRUN/liste_inputfiles_for_LAM $REPRUN/pilot ; ln -s $inrep $REPRUN/pilot
    ls -1 $inrep > $REPRUN/liste_inputfiles_for_LAM
  fi
  /bin/rm -f $REPRUN/climato ; ln -s $climato $REPRUN/climato
  /bin/rm -f $REPRUN/geophy  ; ln -s $geophy  $REPRUN/geophy
  cd $REPRUN ; ls -l ; cd $ici
  echo "Running $lebin ($MAIN):"
  if [ $debug -gt 0 -a $HOSTTYPE = IRIX5 ] ; then
    echo "dbx $MAIN (use command: run -$lebin to proceed)"
    dbx $MAIN
  else
#    export F_ERRCNT=2
    export F_PROGINF=detail
    echo "$MAIN -$lebin"
    $MAIN
  fi
  if [ $debug -eq 0 ] ; then
    cd $REPRUN
    /bin/rm -rf analysis climato pilot geophy model_settings
    cd $ici
  fi
  if test -s status.dot ; then
    . status.dot ; /bin/rm -f status.dot
  fi
else
  echo "\n Executable $MAIN not found \n"
fi
#
. r.return.dot
