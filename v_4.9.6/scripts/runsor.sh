#!/bin/ksh
#
icirunsor=`pwd`
REPRUN=process
repout=${icirunsor}/$REPRUN/prog
bin="mainmc2${ARCH}_${MODEL_VERSION}.Abs"
#
eval `cclargs $0 \
  -prog   ""        ""        "[which prog]"\
  -dyn    "1"       "0"       "[dynamics post-processing]"\
  -phy    "1"       "0"       "[physicss post-processing]"\
  -outmc2 "$repout" "$repout" "[output directory]"\
  ++ $*`
#
nml=mc2_settings.nml
if test ! -s $nml ; then
  echo "\n PROBLEM WITH FILE $nml --ABORT--\n"
  exit
else 
  /bin/rm -f $REPRUN/model_settings
  ln -s ${icirunsor}/${nml} $REPRUN/model_settings
fi
#
phyf=""
dynf=""
cd ${icirunsor}/$REPRUN
if test "$prog" = "" -o "$prog" = " " ; then
  if test $phy -gt 0 ; then
    phyf=`ls zmc2.prog_p_* 2> /dev/null | sed 's-zmc2\.prog_p_--'`
  fi
  if test $dyn -gt 0 ; then
    dynf=`ls zmc2.prog_d_* 2> /dev/null | sed 's-zmc2\.prog_d_--'`
  fi
else
  for i in $prog ; do
    if test $phy -gt 0 ; then
      phyf=${phyf}" "`ls zmc2.prog_p_$i 2> /dev/null | sed 's-zmc2\.prog_p_--'`
    fi
    if test $dyn -gt 0 ; then
      dynf=${dynf}" "`ls zmc2.prog_d_$i 2> /dev/null | sed 's-zmc2\.prog_d_--'`
    fi
  done
fi
#
if [ "$phyf" = "" -o "$phyf" = " " ] ; then
  if [ "$dynf" = "" -o "$dynf" = " " ] ; then
    echo "\nNO OUTPUT TO PROCESS --- EXIT\n" ; exit 0
  fi
fi
#
pself=0
if test `grep gnpself ${icirunsor}/mc2_settings.nml 2> /dev/null | wc -l` -gt 0 ; then
  pself=`grep gnpself ${icirunsor}/mc2_settings.nml | awk '{print $NF}'`
fi
#
runit ()
{
  repsor=$TMPDIR/runsor_$1$2
  mkdir $repsor 2> /dev/null
  cd $repsor 2> /dev/null
  flagok=$?
  if test $flagok != 0 ; then
    echo '\nWORKING DIRECTORY FOR SORMC2 NOT AVAILABLE --- ABORT\n'
    exit 5
  fi
  cd $3
  outfile=`grep fileout mc2_settings.nml | awk '{print $NF}' | sed 's/"//g'`
  if test "$outfile" = "" ; then
    echo '\nSOR_CFGS NAMELIST VARIABLE "FILEOUT" NOT AVAILABLE --- ABORT\n'
    exit 5
  fi
  outfile=\"${outfile}_$1$2\"
  cd $repsor
  export rep_from_which_model_is_launched=`pwd`
  if test -x ${icirunsor}/$bin ; then
    mkdir $REPRUN 2> /dev/null
    cat $3/mc2_settings.nml | sed "s-\( *fileout *= *\)\(.*\)-\1${outfile}-p" \
                                                   > process/model_settings
    if test "$exten" = ".d" -o "$exten" = ".g" ; then
      ln -s ${icirunsor}/$REPRUN/zmc2.prog_d_$1 $REPRUN/zmc2.progd 2> /dev/null
    fi
    if test "$exten" = ".p" ; then
      ln -s ${icirunsor}/$REPRUN/zmc2.prog_p_$1 $REPRUN/zmc2.progp 2> /dev/null
    fi
    ls -lL $REPRUN
    mkdir $outmc2 2> /dev/null ; ln -s $outmc2 $REPRUN/prog
    ${icirunsor}/$bin -sormc2
  else
    echo "\n$bin NOT FOUND --- ABORT\n" ; 5
  fi
  cd $icirunsor
  /bin/rm -rf $repsor
}
#
for i in $dynf ; do
  exten="."
  if test $pself -eq 0 ; then
    exten=${exten}"d"
  else
    exten=${exten}"g"
  fi
  echo runit $i $exten $icirunsor
  runit $i $exten $icirunsor
done
#
exten=".p"
if test $pself -eq 0 ; then
  for i in $phyf ; do
    echo runit $i $exten $icirunsor
    runit $i $exten $icirunsor
  done
fi
/bin/rm -f $REPRUN/model_settings
exit 0
#










