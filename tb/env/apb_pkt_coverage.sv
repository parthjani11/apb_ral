//-----------------------------------------------------------------------------
// apb_pkt_coverage : Simple APB Input Functional Coverage
// Checks:
//   1. Which of the 25 DUT registers (0x0000 to 0x0060) were accessed
//   2. Direction of input access (Read vs. Write)
//   3. Input address validity (Valid aligned vs. Unaligned / Out-of-Range)
//-----------------------------------------------------------------------------

class apb_pkt_coverage extends uvm_subscriber #(apb_seq_item);
    `uvm_component_utils(apb_pkt_coverage)
  
    // Kept so apb_pkt_env.sv connect_phase (m_cov.m_ral = m_ral; m_cov.st = m_state;)
    // compiles without needing any changes to apb_pkt_env.sv
    apb_pkt_reg_block m_ral;
    apb_pkt_state     st;
  
    bit [15:0] addr;
    bit        rw;
    bit        valid_reg_acc;
  
    covergroup cg_apb_input;
      option.per_instance = 1;
      option.name         = "cg_apb_input";
  
      // 1. Which registers were accessed (sampled on valid aligned accesses)
      cp_reg_addr: coverpoint addr iff (valid_reg_acc) {
        bins device_id     = {16'h0000};
        bins version       = {16'h0004};
        bins switch_status = {16'h0008};
        bins port_status   = {16'h000C};
        bins gen_status    = {16'h0010};
        bins stat_rx       = {16'h0014};
        bins stat_tx       = {16'h0018};
        bins stat_drop     = {16'h001C};
        bins switch_ctrl   = {16'h0020};
        bins port_enable   = {16'h0024};
        bins fwd_enable    = {16'h0028};
        bins gen_ctrl      = {16'h002C};
        bins gen_pkt_cfg   = {16'h0030};
        bins gen_interval  = {16'h0034};
        bins gen_count     = {16'h0038};
        bins irq_status    = {16'h003C};
        bins irq_enable    = {16'h0040};
        bins irq_force     = {16'h0044};
        bins err_status    = {16'h0048};
        bins err_enable    = {16'h004C};
        bins err_inject    = {16'h0050};
        bins err_count     = {16'h0054};
        bins err_info      = {16'h0058};
        bins lock          = {16'h005C};
        bins soft_reset    = {16'h0060};
      }
  
      // 2. Input transfer direction (Read = 0, Write = 1)
      cp_rw: coverpoint rw {
        bins read  = {1'b0};
        bins write = {1'b1};
      }
    endgroup
  
    function new(string name = "apb_pkt_coverage", uvm_component parent);
      super.new(name, parent);
      cg_apb_input = new();
    endfunction
  
    virtual function void write(apb_seq_item t);
      addr          = t.addr;
      rw            = t.rw;
      valid_reg_acc = (t.addr[1:0] == 2'b00) && (t.addr <= 16'h0060);
      cg_apb_input.sample();
    endfunction
  
    virtual function void report_phase(uvm_phase phase);
      `uvm_info("COV", $sformatf("Total Input Coverage: %0.1f%%  (Registers Accessed: %0.1f%%, R/W: %0.1f%%)",
                cg_apb_input.get_inst_coverage(),
                cg_apb_input.cp_reg_addr.get_inst_coverage(),
                cg_apb_input.cp_rw.get_inst_coverage()), UVM_LOW)
    endfunction
  
  endclass : apb_pkt_coverage