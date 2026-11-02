# apb_pkt_switch UVM RAL testbench: final state, run and debug guide

References: IEEE 1800.2 / UVM-1.2 register layer (uvm_reg_block, uvm_reg_map, uvm_reg_adapter, uvm_reg_predictor, uvm_reg_cbs).

## 1. File map
| Area | File | Role |
|---|---|---|
| Top | tb/top/tb_top.sv | 100 MHz clock, reset, apb_if, DUT, config_db, `+WAVES` dump |
| Agent | tb/apb_agent/* | driver samples PRDATA/PSLVERR at the completing edge; monitor publishes one item per transfer |
| RAL | tb/ral/apb_pkt_reg_field_defs.sv | all 25 registers (spec-exact layout, reserved bits as RO fields) |
| RAL | tb/ral/apb_pkt_reg_block.sv | `default_map` (base 0, 4 B, LE), create/configure/build/add_reg macro, backdoor paths for 6 RW regs |
| RAL | tb/ral/apb_pkt_ral_adapter.sv | reg2bus / bus2reg, shared by the map and the predictor |
| Env | tb/env/apb_pkt_env.sv | builds and connects; mirror reset at start_of_simulation |
| Env | tb/env/apb_pkt_reg_cbs.sv | lock gate, pulse fields, LENGTH clamp, LOCK key, SOFT_RESET |
| Env | tb/env/apb_pkt_scoreboard.sv | response, mirror compare, status, run accounting, sticky bits |
| Env | tb/env/apb_pkt_coverage.sv | 12 covergroups |
| Env | tb/env/apb_pkt_state.sv | shared lock/accounting/sticky state |
| Seq | tb/sequences/* | 14 sequences, layout from RAL fields (`fval`, `pack_fld`) |
| Tests | tb/tests/apb_pkt_tests.sv | `apb_pkt_seq_test` (+SEQ=), `apb_pkt_regress_test`, `apb_pkt_ral_selftest` |
| SVA | tb/sva/apb_pkt_sva.sv | 42 assertions, 33 covers, bound into apb_pkt_switch and pkt_switch |
| Sim | sim/filelist.f, sim/Makefile | Questa and VCS flows |

Monitor subscriber order is fixed: scoreboard, coverage, then predictor (both observers need pre-transfer state).

## 2. Run order (from sim/)
1. `make selftest`: callbacks proven without DUT traffic. Expect `12 checks, 0 errors -> ALL PASSED`.
2. `make questa SEQ=apb_pkt_ral_hw_reset_seq`, then `apb_pkt_unlock_seq`, `apb_pkt_lock_seq`, `apb_pkt_basic_gen_seq`.
3. Remaining sequences one at a time: `make run SEQ=<name>`.
4. `make regress`: the whole list in one simulation, soft reset between sequences.
5. `make sweep`: one simulation per sequence, merged coverage in merged.ucdb and merged_cov.txt.
Options: `WAVES=1` (VCD plus +acc), `SEED=n`, `VERB=UVM_HIGH`, `make clean`. Each run prints PASS or FAIL from the transcript.

## 3. Error ID -> where to look
| ID or name | Meaning | First suspect |
|---|---|---|
| NOVIF, NO_RAL, SEQ | wiring, missing handle, unknown +SEQ name | tb_top config_db path, test run_seq |
| APB_DRV | PREADY never seen | driver, DUT pready |
| a_apb_* assertions | master protocol broken | apb_driver |
| PSLVERR, RDATA_ERR | response rules (spec 3.5) | DUT address decode or driver sampling |
| WO_READ | write-only register did not read 0 | DUT read mux |
| RD_MIRROR | read differs from mirror | RAL layout, callbacks, or a real DUT bug |
| STATUS | SWITCH/PORT/GEN status inconsistent | DUT status logic or RAL field positions |
| RUN_ACCT | RX/TX/DROP differ from the model | DUT counters, or sequence config (interval vs length) |
| STICKY | IRQ/ERR bit lost without a clear | DUT sticky logic |
| SELFTEST | callback rule broken | apb_pkt_reg_cbs |
| a_lk_ign_*, a_wr_*, a_irq_w1c, a_srst_restores | spec rule broken in the DUT | RTL |
Expected, harmless: a UVM warning "Individual field access not available" when a sequence calls field.write()/read().

## 4. Status
Verified: whole tree compiles and elaborates with slang against UVM-core sources and the RTL from the spec PDF (0 errors); register layout, resets and 25 offsets checked by script against the spec and RTL constants; UVM behaviours relied on were read from the UVM source.
Not verified: nothing has been simulated, so no run results or coverage numbers exist yet.

## 5. Known limits
- Run accounting models the first counted START after a stat-clear/reset; continuous and multi-START runs are skipped.
- IRQ_FORCE / ERR_INJECT side effects on IRQ/ERR status are checked by SVA and sequences, not by the scoreboard.
- Driver leaves one idle cycle between transfers and does not abort on reset mid-transfer.
- Bit-bash may flag GEN_PKT_CFG.LENGTH (0 is stored as 1); if so, skip that register for bit-bash.
