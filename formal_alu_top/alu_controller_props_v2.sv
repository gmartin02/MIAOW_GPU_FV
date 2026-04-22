// =============================================================================
// alu_controller_assertions.sv
//
// Behavioral SVA for formal verification of the alu_controller within
// the MIAOW GPU ALU (AMD Southern Islands ISA).
//
// VERIFICATION STRATEGY:
//   These assertions are bound at the `alu` module level, NOT the
//   `alu_controller` level. This is critical because:
//
//   - `in_valu_done` (aka `valu_done`) is driven by the `valu` submodule
//     inside `alu`. If we verify at the `alu_controller` level, formal
//     treats it as a free input and we need fragile assumes. At the `alu`
//     level, it is driven by real RTL — formal cannot inject bogus values.
//
//   - `in_alu_select_flopped` (aka `cnt_alu_select`) is driven by
//     `PS_flops_issue_alu`, which is just a registered version of
//     `issue_alu_select`. Again, real RTL constrains it.
//
//   The only truly free inputs are those coming from outside `alu`:
//   `issue_alu_select`, `issue_opcode`, source/dest addresses, etc.
//   These only need a single protocol assume (dispatch respects ready).
// =============================================================================

module alu_controller_assertions
  (
   input logic        clk,
   input logic        rst,

   // External interface (from outside the alu module)
   input logic        issue_alu_select,
   input logic        issue_alu_ready,

   // Internal alu_controller signals (accessed via hierarchy)
   input logic        in_alu_select_flopped,
   input logic        in_alu_select,
   input logic [11:0] in_source1_addr,
   input logic [11:0] in_source2_addr,
   input logic [11:0] in_source3_addr,
   input logic [11:0] in_dest1_addr,
   input logic [11:0] in_dest2_addr,
   input logic [31:0] in_opcode,
   input logic        in_valu_done,

   input logic        out_alu_ready,
   input logic        out_vcc_wr_en,
   input logic        out_instr_done,
   input logic        out_vgpr_wr_en,
   input logic [11:0] out_vgpr_dest_addr,
   input logic        out_sgpr_wr_en,
   input logic [11:0] out_sgpr_dest_addr,
   input logic [31:0] out_alu_control,
   input logic        out_alu_start,
   input logic        out_src_buffer_wr_en,
   input logic [3:0]  out_source1_mux_select,
   input logic [3:0]  out_source2_mux_select,
   input logic [3:0]  out_source3_mux_select,
   input logic [9:0]  out_source1_src_constant,
   input logic [9:0]  out_source2_src_constant,
   input logic [9:0]  out_source3_src_constant,
   input logic        out_vgpr_source1_rd_en,
   input logic        out_vgpr_source2_rd_en,
   input logic        out_vgpr_source3_rd_en,
   input logic        out_sgpr_rd_en,
   input logic        out_exec_rd_en,

   input logic        RD,
   input logic        EX,
   input logic        WB,
   input logic [2:0]  fsm_current_state
   );

   localparam IDLE      = 3'b000;
   localparam STATE_RD  = 3'b001;
   localparam STATE_EX1 = 3'b010;
   localparam STATE_EX2 = 3'b011;
   localparam STATE_EX3 = 3'b100;
   localparam STATE_EX4 = 3'b101;

   default clocking cb @(posedge clk); endclocking
   default disable iff (rst);

   // =========================================================================
   //  ENVIRONMENT CONSTRAINT
   //
   //  Only one assume is needed: the external issuer respects the
   //  ready/valid handshake. This constrains `issue_alu_select` (the
   //  only truly free dispatch signal from outside the alu module).
   //
   //  We constrain issue_alu_ready (not out_alu_ready) because
   //  issue_alu_ready = alu_ready & queue_ready — it is the actual
   //  signal the issuer sees.
   //
   //  No assumes are needed for in_valu_done or in_alu_select_flopped
   //  because they are driven by real RTL inside the alu module.
   // =========================================================================

   ASM_issuer_respects_ready:
      assume property (
         issue_alu_select |-> issue_alu_ready
      );

   // =========================================================================
   //  HANDSHAKE & PROTOCOL
   // =========================================================================

   // The ALU must not claim ready while an instruction is in flight
   AST_not_ready_during_execution:
      assert property (
         (fsm_current_state != IDLE) && (fsm_current_state != STATE_EX4 || !in_valu_done)
         |-> !out_alu_ready
      );

   // Every dispatch must eventually produce a completion
   AST_dispatch_guarantees_completion:
      assert property (
         (fsm_current_state == IDLE && in_alu_select_flopped)
         |-> s_eventually out_instr_done
      );

   // Once the ALU goes busy, it must eventually become ready again
   AST_no_permanent_stall:
      assert property (
         $fell(out_alu_ready) |-> s_eventually out_alu_ready
      );

   // instr_done is a single-cycle pulse
   AST_instr_done_is_pulse:
      assert property (
         out_instr_done |=> !out_instr_done
      );

   // =========================================================================
   //  NO SIDE EFFECTS WHEN IDLE
   // =========================================================================

   // No writeback activity when no instruction is completing
   AST_no_spurious_writeback:
      assert property (
         !WB |-> (!out_vcc_wr_en && !out_vgpr_wr_en &&
                  !out_sgpr_wr_en && !out_instr_done)
      );

   // No opcode forwarded to the ALU datapath when not executing
   AST_no_opcode_leak_when_idle:
      assert property (
         !EX |-> (out_alu_control == 32'd0)
      );

   // No source buffer writes when not in the read stage
   AST_no_spurious_source_capture:
      assert property (
         (fsm_current_state == IDLE && !in_alu_select_flopped)
         |-> !out_src_buffer_wr_en
      );

   // =========================================================================
   //  READ ENABLE SAFETY
   // =========================================================================

   // If source1 is a VGPR source, source1 VGPR read must be enabled
   AST_source1_vgpr_read:
      assert property (
         in_alu_select && (in_source1_addr[11:10] == 2'b10)
         |-> out_vgpr_source1_rd_en
      );


   // If source2 is a VGPR source, source2 VGPR read must be enabled
   AST_source2_vgpr_read:
      assert property (
         in_alu_select && (in_source2_addr[11:10] == 2'b10)
         |-> out_vgpr_source2_rd_en
      );

   // If source3 is a VGPR source, source3 VGPR read must be enabled
   AST_source3_vgpr_read:
      assert property (
         in_alu_select && (in_source3_addr[11:10] == 2'b10)
         |-> out_vgpr_source3_rd_en
      );

   // Read enables are gated by alu_select
   AST_no_read_when_not_selected:
      assert property (
         !in_alu_select |-> !out_vgpr_source1_rd_en &&
                            !out_vgpr_source2_rd_en &&
                            !out_vgpr_source3_rd_en &&
                            !out_sgpr_rd_en &&
                            !out_exec_rd_en
      );

   // A non-VGPR source must never trigger a VGPR read port
   AST_no_false_vgpr_read_src1:
      assert property (
         in_alu_select && (in_source1_addr[11:10] != 2'b10)
         |-> !out_vgpr_source1_rd_en
      );

   AST_no_false_vgpr_read_src2:
      assert property (
         in_alu_select && (in_source2_addr[11:10] != 2'b10)
         |-> !out_vgpr_source2_rd_en
      );

   AST_no_false_vgpr_read_src3:
      assert property (
         in_alu_select && (in_source3_addr[11:10] != 2'b10)
         |-> !out_vgpr_source3_rd_en
      );

   // =========================================================================
   //  DESTINATION INTEGRITY
   // =========================================================================

   // A VGPR destination address must land on the VGPR dest port
   AST_vgpr_dest_has_vgpr_addr:
      assert property (
         (in_dest1_addr[11:10] == 2'b10 || in_dest2_addr[11:10] == 2'b10)
         |-> (out_vgpr_dest_addr[11:10] == 2'b10)
      );

   // An SGPR/special destination address must land on the SGPR dest port
   AST_sgpr_dest_has_sgpr_addr:
      assert property (
         (in_dest1_addr[11:10] == 2'b11 || in_dest2_addr[11:10] == 2'b11)
         |-> (out_sgpr_dest_addr[11:10] == 2'b11 ||
              out_sgpr_dest_addr[11:9] == 3'b110)
      );

   // No destination address is fabricated — must match an input
   AST_vgpr_dest_not_fabricated:
      assert property (
         (in_dest1_addr[11:10] == 2'b10 || in_dest1_addr[11:10] == 2'b11 ||
          in_dest2_addr[11:10] == 2'b10 || in_dest2_addr[11:10] == 2'b11)
         |-> (out_vgpr_dest_addr == in_dest1_addr ||
              out_vgpr_dest_addr == in_dest2_addr)
      );

   AST_sgpr_dest_not_fabricated:
      assert property (
         (in_dest1_addr[11:10] == 2'b10 || in_dest1_addr[11:10] == 2'b11 ||
          in_dest2_addr[11:10] == 2'b10 || in_dest2_addr[11:10] == 2'b11)
         |-> (out_sgpr_dest_addr == in_dest1_addr ||
              out_sgpr_dest_addr == in_dest2_addr)
      );

   // =========================================================================
   //  PIPELINE ORDERING
   // =========================================================================

   // RD and WB must never overlap
   AST_rd_wb_mutually_exclusive:
      assert property (!(RD && WB));

   // RD and EX must not overlap
   AST_rd_ex_no_overlap:
      assert property (RD |-> !EX);

   // alu_start should only fire when the datapath is executing
   AST_start_only_during_execution:
      assert property (out_alu_start |-> EX);

   // A writeback must be preceded by execution
   AST_wb_preceded_by_ex:
      assert property (WB |-> $past(EX));

   // Completion can only come from the final execution stage
   AST_completion_only_from_ex4:
      assert property (
         WB |-> (fsm_current_state == STATE_EX4)
      );

   // Execution states must progress in order — no skipping
   AST_ex1_to_ex2_no_skip:
      assert property (
         (fsm_current_state == STATE_EX1 && in_valu_done)
         |=> (fsm_current_state == STATE_EX2)
      );

   AST_ex2_to_ex3_no_skip:
      assert property (
         (fsm_current_state == STATE_EX2 && in_valu_done)
         |=> (fsm_current_state == STATE_EX3)
      );

   AST_ex3_to_ex4_no_skip:
      assert property (
         (fsm_current_state == STATE_EX3 && in_valu_done)
         |=> (fsm_current_state == STATE_EX4)
      );

   // The FSM must not regress to an earlier execution state
   AST_no_backward_transition:
      assert property (
         (fsm_current_state == STATE_EX2) |=> (fsm_current_state != STATE_EX1)
      );

   // =========================================================================
   //  DATA INTEGRITY
   // =========================================================================

   // When executing, the datapath must receive the actual opcode
   AST_opcode_forwarded_during_ex:
      assert property (
         EX |-> (out_alu_control == in_opcode)
      );

   // Source mux selects must be stable during execution
   AST_src1_mux_stable_during_ex:
      assert property (
         (EX && $past(EX)) |-> (out_source1_mux_select == $past(out_source1_mux_select))
      );

   AST_src2_mux_stable_during_ex:
      assert property (
         (EX && $past(EX)) |-> (out_source2_mux_select == $past(out_source2_mux_select))
      );

   AST_src3_mux_stable_during_ex:
      assert property (
         (EX && $past(EX)) |-> (out_source3_mux_select == $past(out_source3_mux_select))
      );

   // =========================================================================
   //  COVER PROPERTIES
   // =========================================================================

   // Full 4-pass instruction lifecycle
   COV_full_instruction_cycle:
      cover property (
         (fsm_current_state == IDLE && in_alu_select_flopped) ##[1:$]
         (fsm_current_state == STATE_EX1 && in_valu_done)     ##[1:$]
         (fsm_current_state == STATE_EX2 && in_valu_done)     ##[1:$]
         (fsm_current_state == STATE_EX3 && in_valu_done)     ##[1:$]
         (fsm_current_state == STATE_EX4 && in_valu_done)     ##[1:$]
         (fsm_current_state == IDLE)
      );

   // Back-to-back instructions
   COV_back_to_back_dispatch:
      cover property (
         out_instr_done ##[1:3] (fsm_current_state == IDLE && in_alu_select_flopped)
      );

   COV_vgpr_writeback:
      cover property (WB && out_vgpr_wr_en && out_instr_done);

   COV_VCC_wr_en:
      cover property (out_vcc_wr_en);

   COV_sgpr_writeback:
      cover property (WB && out_sgpr_wr_en && out_instr_done);

   COV_all_vgpr_sources:
      cover property (
         out_vgpr_source1_rd_en && out_vgpr_source2_rd_en && out_vgpr_source3_rd_en
      );

   COV_read_SCC:
      cover property (out_source3_mux_select == 4'b1011);

   COV_src1_literal:
      cover property (out_source1_mux_select == 4'b0000);

   COV_src1_sgpr:
      cover property (out_source1_mux_select == 4'b0011);

   COV_read_vcc_lo:
      cover property (out_source1_mux_select == 4'b0100);

   COV_read_exec_lo:
      cover property (out_source1_mux_select == 4'b0111);

endmodule

bind alu alu_controller_assertions u_assertions (
      .clk                    (clk),
      .rst                    (rst),
      // External interface
      .issue_alu_select       (issue_alu_select),
      .issue_alu_ready        (issue_alu_ready),
      // Internal signals via hierarchy
      .in_alu_select_flopped  (alu_controller.in_alu_select_flopped),
      .in_alu_select          (alu_controller.in_alu_select),
      .in_source1_addr        (alu_controller.in_source1_addr),
      .in_source2_addr        (alu_controller.in_source2_addr),
      .in_source3_addr        (alu_controller.in_source3_addr),
      .in_dest1_addr          (alu_controller.in_dest1_addr),
      .in_dest2_addr          (alu_controller.in_dest2_addr),
      .in_opcode              (alu_controller.in_opcode),
      .in_valu_done           (valu_done),
      .out_alu_ready          (alu_ready),
      .out_vcc_wr_en          (alu_controller.out_vcc_wr_en),
      .out_instr_done         (alu_controller.out_instr_done),
      .out_vgpr_wr_en         (alu_controller.out_vgpr_wr_en),
      .out_vgpr_dest_addr     (alu_controller.out_vgpr_dest_addr),
      .out_sgpr_wr_en         (alu_controller.out_sgpr_wr_en),
      .out_sgpr_dest_addr     (alu_controller.out_sgpr_dest_addr),
      .out_alu_control        (alu_controller.out_alu_control),
      .out_alu_start          (alu_controller.out_alu_start),
      .out_src_buffer_wr_en   (alu_controller.out_src_buffer_wr_en),
      .out_source1_mux_select (alu_controller.out_source1_mux_select),
      .out_source2_mux_select (alu_controller.out_source2_mux_select),
      .out_source3_mux_select (alu_controller.out_source3_mux_select),
      .out_source1_src_constant(alu_controller.out_source1_src_constant),
      .out_source2_src_constant(alu_controller.out_source2_src_constant),
      .out_source3_src_constant(alu_controller.out_source3_src_constant),
      .out_vgpr_source1_rd_en (vgpr_source1_rd_en),
      .out_vgpr_source2_rd_en (vgpr_source2_rd_en),      .out_vgpr_source3_rd_en (vgpr_source3_rd_en),
      .out_sgpr_rd_en         (sgpr_rd_en),
      .out_exec_rd_en         (exec_rd_en),
      .RD                     (alu_controller.alu_fsm.RD),
      .EX                     (alu_controller.alu_fsm.EX),
      .WB                     (alu_controller.alu_fsm.WB),
      .fsm_current_state      (alu_controller.alu_fsm.current_state)
   );