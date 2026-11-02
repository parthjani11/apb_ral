#!/bin/csh -f
# usage: check_log.csh <log> [directed]     PASS/FAIL from a simulation log
if ($#argv < 1) then
  echo "usage: check_log.csh <log> [directed]"
  exit 2
endif
set log = $1
if (! -e $log) then
  echo "FAIL : $log was not created - the simulation never ran (check the tool setup / messages above)"
  exit 1
endif
if (-z $log) then
  echo "FAIL : $log is empty"
  exit 1
endif
set nuvm = `grep -cE "UVM_(ERROR|FATAL) +: +[1-9]" $log`
set nsva = `grep -ciE "failed at|Offending" $log`
set pass = 1
if ($nuvm > 0 || $nsva > 0) set pass = 0
if ($#argv >= 2) then
  if ($2 == "directed") then
    set ntest = `grep -c "TEST PASSED" $log`
    if ($ntest == 0) set pass = 0
  endif
endif
if ($pass) then
  echo "PASS : $log"
  exit 0
else
  echo "FAIL : $log   (UVM errors: $nuvm, assertion failures: $nsva)"
  exit 1
endif

