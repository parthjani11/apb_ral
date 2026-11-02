.RECIPEPREFIX := >
UVM_HOME ?= $(shell dirname $$(dirname $$(which vsim)))/verilog_src/uvm-1.2
TEST  ?= apb_pkt_seq_test
SEQ   ?= apb_pkt_basic_gen_seq
VERB  ?= UVM_MEDIUM
SEED  ?= 1
WAVES ?= 0
LOG    = $(TEST)_$(SEQ).log
ifeq ($(WAVES),1)
  PLUS += +WAVES
  ACC   = -voptargs=+acc
endif
SEQS := apb_pkt_ral_hw_reset_seq apb_pkt_unlock_seq apb_pkt_lock_seq apb_pkt_basic_gen_seq apb_pkt_drop_scenario_seq apb_pkt_irq_test_seq apb_pkt_err_inject_seq apb_pkt_lock_protection_seq apb_pkt_boundary_seq apb_pkt_continuous_mode_seq apb_pkt_stat_saturation_seq apb_pkt_reset_seq apb_pkt_ral_access_seq apb_pkt_ral_bit_bash_seq

.PHONY: compile run check questa selftest regress sweep vcs clean

compile:
> vlib work
> vlog -sv -timescale 1ns/1ps +incdir+$(UVM_HOME)/src -L mtiUvm -f filelist.f

run:
> vsim -c -coverage $(ACC) -L mtiUvm -sv_seed $(SEED) work.tb_top +UVM_TESTNAME=$(TEST) +SEQ=$(SEQ) +UVM_VERBOSITY=$(VERB) $(PLUS) -l $(LOG) -do "coverage save -onexit $(TEST)_$(SEQ).ucdb; run -all; quit -f"
> @$(MAKE) --no-print-directory check LOG=$(LOG)

# PASS only if no UVM_ERROR/UVM_FATAL and no assertion failure in the transcript
check:
> @if grep -qE "UVM_(ERROR|FATAL) +: +[1-9]|Assertion error" $(LOG); then echo "FAIL: $(LOG)"; exit 1; else echo "PASS: $(LOG)"; fi

questa: compile run

selftest: compile
> $(MAKE) --no-print-directory run TEST=apb_pkt_ral_selftest SEQ=none

regress: compile
> $(MAKE) --no-print-directory run TEST=apb_pkt_regress_test SEQ=all

# one simulation per sequence, then merge coverage (closure view)
sweep: compile
> for s in $(SEQS); do $(MAKE) --no-print-directory run SEQ=$$s || true; done
> vcover merge -out merged.ucdb apb_pkt_seq_test_*.ucdb
> vcover report -details -output merged_cov.txt merged.ucdb

vcs:
> vcs -full64 -sverilog -ntb_opts uvm-1.2 -cm assert+group -timescale=1ns/1ps -f filelist.f -o simv
> ./simv -cm assert+group +UVM_TESTNAME=$(TEST) +SEQ=$(SEQ) +UVM_VERBOSITY=$(VERB) -l $(LOG)

clean:
> rm -rf work transcript *.ucdb *.log *.wlf *.vcd simv simv.daidir csrc ucli.key vc_hdrs.h merged_cov.txt
