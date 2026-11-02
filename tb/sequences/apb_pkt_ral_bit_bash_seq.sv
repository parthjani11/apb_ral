//-----------------------------------------------------------------------------
// Class  : apb_pkt_ral_bit_bash_seq
// File   : tb/sequences/apb_pkt_ral_bit_bash_seq.sv
//-----------------------------------------------------------------------------

class apb_pkt_ral_bit_bash_seq extends apb_pkt_base_seq;
    `uvm_object_utils(apb_pkt_ral_bit_bash_seq)
  
    function new(string name = "apb_pkt_ral_bit_bash_seq");
      super.new(name);
    endfunction
  
    virtual task body();
      uvm_reg_bit_bash_seq bb_seq;
      uvm_reg_data_t       v, lk;
  
      // 1. Unlock CSR bank and verify
      `uvm_info("BIT_BASH", "Unlocking CSR bank before bit-bash", UVM_MEDIUM)
      ral_write(reg_block.lock, 32'hA5A5_C3C3);
      ral_read (reg_block.lock, v);
      if (v[0] !== 1'b0)
        `uvm_error("UNLOCK", $sformatf("bank still locked after key write (LOCK read 0x%08h)", v))
  
      // 2. Refresh live status registers so mirror matches DUT (SWITCH_STATUS.LOCKED is now 0)
      ral_read(reg_block.switch_status, v);  ral_read(reg_block.port_status, v);
      ral_read(reg_block.gen_status,    v);  ral_read(reg_block.stat_rx,     v);
      ral_read(reg_block.stat_tx,       v);  ral_read(reg_block.stat_drop,   v);
      ral_read(reg_block.irq_status,    v);  ral_read(reg_block.err_status,  v);
      ral_read(reg_block.err_count,     v);  ral_read(reg_block.err_info,    v);
  
      `uvm_info("BIT_BASH", "Running uvm_reg_bit_bash_seq on standard registers", UVM_MEDIUM)
  
      bb_seq = uvm_reg_bit_bash_seq::type_id::create("bb_seq");
      bb_seq.model = reg_block;
  
      // 3. Exclude registers with hardware side-effects / clamping / pulses / WO triggers:
      uvm_resource_db #(bit)::set({"REG::", reg_block.lock.get_full_name()},        "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.soft_reset.get_full_name()},  "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.gen_pkt_cfg.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.gen_ctrl.get_full_name()},    "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.switch_ctrl.get_full_name()}, "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.irq_force.get_full_name()},   "NO_REG_BIT_BASH_TEST", 1, this);
      uvm_resource_db #(bit)::set({"REG::", reg_block.err_inject.get_full_name()},  "NO_REG_BIT_BASH_TEST", 1, this);
  
      bb_seq.start(null, this);
  
      // 4. Prove the bank stayed unlocked during the run, then re-lock
      ral_read(reg_block.lock, lk);
      if (lk[0]) `uvm_error("BIT_BASH", "bank became locked during the run: results are vacuous")
      ral_write(reg_block.lock, 32'h0000_0000);
  
      `uvm_info("BIT_BASH", "=== Bit bash test COMPLETE ===", UVM_LOW)
    endtask
  
  endclass : apb_pkt_ral_bit_bash_seq