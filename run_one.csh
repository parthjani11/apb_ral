#!/bin/csh -f
# usage: run_one.csh <uvm_test> <seq|none|all>      runs ./simv once and checks the log
if ($#argv < 2) then
  echo "usage: run_one.csh <uvm_test> <seq|none|all>"
  exit 2
endif
set test = $1
if (! -x simv) then
  echo "ERROR: ./simv not found - run:  csh -f run_vcs.csh compile"
  exit 1
endif
set seq  = $2
set log  = run_${test}_${seq}.log
set CM_OPTS = ( -cm line+cond+fsm+tgl+branch+assert+group )
set plus = ()
if ($?WAVES) set plus = ( +WAVES )
./simv +UVM_TESTNAME=$test +SEQ=$seq +UVM_VERBOSITY=UVM_MEDIUM $CM_OPTS -cm_name ${test}_${seq} $plus -l $log
csh -f check_log.csh $log

