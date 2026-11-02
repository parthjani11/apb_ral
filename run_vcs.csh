#!/bin/csh -f
#------------------------------------------------------------------------------
# apb_pkt_switch : VCS run script (csh)
#   csh -f run_vcs.csh directed        plain SV directed test + bound SVA (no UVM)
#   csh -f run_vcs.csh compile         compile the UVM testbench -> ./simv
#   csh -f run_vcs.csh selftest        UVM RAL callback self-test (no DUT traffic)
#   csh -f run_vcs.csh seq <name>      one UVM sequence (default apb_pkt_basic_gen_seq)
#   csh -f run_vcs.csh regress         all sequences in one simulation
#   csh -f run_vcs.csh sweep           one simulation per sequence + consolidated log + coverage report
#   csh -f run_vcs.csh report          urg coverage report from simv.vdb
#   csh -f run_vcs.csh clean           remove build artifacts and run logs
# Optional: setenv WAVES 1 (VCD dump) ; setenv UVM_NTB uvm (sites using UVM-1.1d)
#------------------------------------------------------------------------------
if (-e setup.csh) source setup.csh

set mode = help
if ($#argv >= 1) set mode = $1
set seq = apb_pkt_basic_gen_seq
if ($#argv >= 2) set seq = $2

if ($mode == directed || $mode == compile) then
  sh -c "command -v vcs" >& /dev/null
  if ($status != 0) then
    echo "ERROR: 'vcs' not found in PATH."
    echo "       Put your site's Synopsys setup line in setup.csh, e.g.  source /fetools/<your_path>"
    echo "       (or run that setup line in this shell first), then run this script again."
    exit 1
  endif
endif

set VCS_OPTS = ( -sverilog -full64 +v2k -debug_access+all -timescale=1ns/1ps )
set uvm_ver = uvm-1.2
if ($?UVM_NTB) then
  set uvm_ver = $UVM_NTB
endif
set UVM_OPTS = ( -ntb_opts $uvm_ver -top tb_top )
set CM_OPTS  = ( -cm line+cond+fsm+tgl+branch+assert )
set plus = ()
if ($?WAVES) set plus = ( +WAVES )
set SEQS = ( apb_pkt_ral_hw_reset_seq apb_pkt_unlock_seq apb_pkt_lock_seq apb_pkt_basic_gen_seq \
             apb_pkt_drop_scenario_seq apb_pkt_irq_test_seq apb_pkt_err_inject_seq \
             apb_pkt_lock_protection_seq apb_pkt_boundary_seq apb_pkt_continuous_mode_seq \
             apb_pkt_stat_saturation_seq apb_pkt_reset_seq apb_pkt_ral_access_seq apb_pkt_ral_bit_bash_seq )

switch ($mode)

case directed:
  vcs $VCS_OPTS -R -top tb_directed -l directed.log design.sv tb/sva/apb_pkt_sva.sv tb_directed.sv $plus
  csh -f check_log.csh directed.log directed
  breaksw

case compile:
  vcs $VCS_OPTS $UVM_OPTS $CM_OPTS -f filelist_uvm.f -l compile.log -o simv
  breaksw

case selftest:
  if (! -e simv) csh -f run_vcs.csh compile
  csh -f run_one.csh apb_pkt_ral_selftest none
  breaksw

case seq:
  if (! -e simv) csh -f run_vcs.csh compile
  csh -f run_one.csh apb_pkt_seq_test $seq
  breaksw

case regress:
  if (! -e simv) csh -f run_vcs.csh compile
  csh -f run_one.csh apb_pkt_regress_test all
  breaksw

case sweep:
  if (! -e simv) csh -f run_vcs.csh compile
  set sweep_log = "sweep_master.log"
  rm -f $sweep_log
  echo "========================================================" | tee -a $sweep_log
  echo " Starting Sweep Regression across 14 Sequences"           | tee -a $sweep_log
  echo " Master Log: $sweep_log"                                  | tee -a $sweep_log
  echo "========================================================" | tee -a $sweep_log

  foreach s ($SEQS)
    echo "========================================================" | tee -a $sweep_log
    echo ">>> Running sequence: $s ..."                            | tee -a $sweep_log
    echo "========================================================" | tee -a $sweep_log
    csh -f run_one.csh apb_pkt_seq_test $s |& tee -a $sweep_log
    echo "" | tee -a $sweep_log
  end

  echo "========================================================" | tee -a $sweep_log
  echo ">>> Merging Coverage with URG..."                         | tee -a $sweep_log
  echo "========================================================" | tee -a $sweep_log
  urg -dir simv.vdb -report urgReport |& tee -a $sweep_log
  echo "coverage report: urgReport/dashboard.html" | tee -a $sweep_log
  breaksw

case report:
  urg -dir simv.vdb -report urgReport
  echo "coverage report: urgReport/dashboard.html"
  breaksw

case clean:
  rm -rf simv simv.daidir csrc simv.vdb urgReport ucli.key vc_hdrs.h DVEfiles *.vcd *.vpd
  rm -f compile.log directed.log tr_db.log urg.log run_*.log
  breaksw

default:
  sed -n '2,14p' run_vcs.csh
  breaksw

endsw
