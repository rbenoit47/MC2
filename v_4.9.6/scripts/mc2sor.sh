#!/bin/ksh
#
eval `cclargs_lite $0 \
       -g       "0"    "1"         "[output for cascade]"\
       -sp      "0"    "1"         "[save raw prog files]"\
  ++ $*`
#
mkdir output 2>/dev/null
#
set -x 
flagsor=99
if test -x ./runsor.sh ; then
  SOR=./runsor.sh
else
  SOR=$mc2/scripts/runsor.sh
fi
$SOR
flagsor=$?
#
if test $flagsor -eq 0 ; then
  /bin/mv process/prog/* output
  ls -lL output
fi
#
flagsorgl=99
if test $g -eq 1 ; then
#=====> RELAUNCHING sormc2 for output in GL levels
#
   mv mc2_settings.nml mc2_settings_bk
   sed 's/\( *gnpself *= *\)\([0-9]\)/\11/p' mc2_settings_bk > mc2_settings.nml
   $SOR
   flagsorgl=$?
   /bin/mv mc2_settings_bk mc2_settings.nml
   if test $flagsorgl -eq 0 ; then
      /bin/mv process/prog/* output
      ls -lL output
   fi
else
   flagsorgl=0
fi
#
if test $sp -eq 1 ; then
  /bin/mv process/zmc2.prog* output
  /bin/mv process/zmc2.phys* output
else
  /bin/rm -f process/zmc2.prog* process/zmc2.phys*
fi
