apb_pkt_switch : design + testbench for Synopsys VCS (csh)
==========================================================
QUICK START  (copy / paste)
   unzip apb_pkt_final.zip -d apb_pkt        # or copy the files into any work directory
   cd apb_pkt
   csh                                       # only if you are not already in csh
   vi setup.csh                              # put your site's Synopsys setup line, then:
   source setup.csh
   csh -f run_vcs.csh directed               # design + directed test + bound SVA  -> expect: PASS : directed.log

EXACT vcs COMMAND behind "directed"  (same style as your design.v example):
   vcs -sverilog -R -full64 +v2k -debug_access+all -timescale=1ns/1ps -top tb_directed -l fell.log design.sv tb/sva/apb_pkt_sva.sv tb_directed.sv
   -> the end of fell.log shows:  TEST PASSED (87 checks)

UVM TESTBENCH
   csh -f run_vcs.csh compile                       builds ./simv   (compile.log)
   csh -f run_vcs.csh selftest                      expect: 12 checks, 0 errors -> ALL PASSED
   csh -f run_vcs.csh seq apb_pkt_ral_hw_reset_seq  then apb_pkt_basic_gen_seq and the other sequences
   csh -f run_vcs.csh regress                       all sequences in one simulation
   csh -f run_vcs.csh sweep                         one run per sequence + coverage (urgReport/dashboard.html)
   csh -f run_vcs.csh clean                         remove build output
   Options:  setenv WAVES 1   (VCD dump)      setenv UVM_NTB uvm   (if your site uses UVM-1.1d instead of uvm-1.2)
   Every run prints PASS or FAIL; UVM_ERROR/UVM_FATAL or an assertion failure in the log means FAIL.

FILES
   design.sv          whole design in one file          rtl/   the same four sources separately (from the spec PDF)
   tb_directed.sv     plain SV self-checking test        tb/    UVM testbench + bound SVA (tb/sva)
   run_vcs.csh        main driver (run_one.csh and check_log.csh are helpers; no chmod needed)
   filelist_uvm.f     VCS file list for the UVM testbench
   sim/               optional Questa Makefile flow      docs/  architecture notes and error-ID guide

VERIFICATION STATUS
   Simulated (open-source Verilator): design.sv + tb_directed.sv -> 87/87 checks pass; the 42 bound assertions -> 0 failures,
      32 of 33 covers hit (only c_rx_sat needs the 65535-packet UVM sequence).
   Script flow dry-run with a csh-compatible shell and stub tools: all modes work.
   Compile-checked only (slang + UVM sources): the full UVM testbench.
   NOT run: Synopsys VCS itself, and the UVM testbench in any simulator. If a first VCS compile prints tool-specific
   warnings or a run fails, send compile.log / the first failing log.
