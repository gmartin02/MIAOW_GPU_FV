
module deadlock_assertions_alu_bind
  #(parameter MODULE = `MODULE_SIMD)
  (
   input logic        clk,
   input logic        rst,
   input logic        alu_ready,
   input logic        valu_done,
   input logic        issue_alu_ready,
   input logic        queue_ready,
   input logic [31:0] alu_control,
   input logic [15:0] alu_source_exec_value
   );

  function automatic bit simd_opcode_supported(input logic [31:0] opcode);
    begin
      casez ({opcode[31:24], opcode[11:0]})
        {`ALU_VOP1_FORMAT, 12'h001},
        {`ALU_VOP2_FORMAT, 12'h025},
        {`ALU_VOP2_FORMAT, 12'h026},
        {`ALU_VOP2_FORMAT, 12'h01B},
        {`ALU_VOP3A_FORMAT, 12'h11B},
        {`ALU_VOP2_FORMAT, 12'h01C},
        {`ALU_VOP2_FORMAT, 12'h01A},
        {`ALU_VOP2_FORMAT, 12'h016},
        {`ALU_VOP2_FORMAT, 12'h018},
        {`ALU_VOP2_FORMAT, 12'h014},
        {`ALU_VOP2_FORMAT, 12'h012},
        {`ALU_VOP3A_FORMAT, 12'h114},
        {`ALU_VOP2_FORMAT, 12'h013},
        {`ALU_VOP2_FORMAT, 12'h113},
        {`ALU_VOP2_FORMAT, 12'h000},
        {`ALU_VOPC_FORMAT, 12'h080},
        {`ALU_VOPC_FORMAT, 12'h081},
        {`ALU_VOPC_FORMAT, 12'h082},
        {`ALU_VOPC_FORMAT, 12'h083},
        {`ALU_VOPC_FORMAT, 12'h084},
        {`ALU_VOPC_FORMAT, 12'h085},
        {`ALU_VOPC_FORMAT, 12'h086},
        {`ALU_VOPC_FORMAT, 12'h087},
        {`ALU_VOPC_FORMAT, 12'h0C0},
        {`ALU_VOPC_FORMAT, 12'h0C1},
        {`ALU_VOPC_FORMAT, 12'h0C2},
        {`ALU_VOPC_FORMAT, 12'h0C3},
        {`ALU_VOPC_FORMAT, 12'h0C4},
        {`ALU_VOPC_FORMAT, 12'h0C5},
        {`ALU_VOPC_FORMAT, 12'h0C6},
        {`ALU_VOPC_FORMAT, 12'h0C7},
        {`ALU_VOP3A_FORMAT, 12'h080},
        {`ALU_VOP3A_FORMAT, 12'h081},
        {`ALU_VOP3A_FORMAT, 12'h082},
        {`ALU_VOP3A_FORMAT, 12'h083},
        {`ALU_VOP3A_FORMAT, 12'h084},
        {`ALU_VOP3A_FORMAT, 12'h085},
        {`ALU_VOP3A_FORMAT, 12'h086},
        {`ALU_VOP3A_FORMAT, 12'h087},
        {`ALU_VOP3A_FORMAT, 12'h0C0},
        {`ALU_VOP3A_FORMAT, 12'h0C1},
        {`ALU_VOP3A_FORMAT, 12'h0C2},
        {`ALU_VOP3A_FORMAT, 12'h0C3},
        {`ALU_VOP3A_FORMAT, 12'h0C4},
        {`ALU_VOP3A_FORMAT, 12'h0C5},
        {`ALU_VOP3A_FORMAT, 12'h0C6},
        {`ALU_VOP3A_FORMAT, 12'h0C7},
        {`ALU_VOP3A_FORMAT, 12'h16A},
        {`ALU_VOP2_FORMAT, 12'h009},
        {`ALU_VOP3A_FORMAT, 12'h109},
        {`ALU_VOP3A_FORMAT, 12'h16B},
        {`ALU_VOP3A_FORMAT, 12'h169},
        {`ALU_VOP3A_FORMAT, 12'h148},
        {`ALU_VOP3A_FORMAT, 12'h149},
        {`ALU_VOP3A_FORMAT, 12'h14A},
        {`ALU_VOP2_FORMAT, 12'h028},
        {`ALU_VOP2_FORMAT, 12'h027}: simd_opcode_supported = 1'b1;
        default: simd_opcode_supported = 1'b0;
      endcase
    end
  endfunction

  // ==========================================================
  // DEADLOCK #1: SIMD unsupported-opcode execution stall
  // ==========================================================

  //**********************************************************************************
  // Gabe's interpretation:
  // If the SIMD ALU is given an unsupported instruction while there is active work, 
  // it is not allowed to stall forever. It must eventually terminate that operation somehow by asserting valu_done.
  //**********************************************************************************
  
  cover property (@(posedge clk) disable iff (rst)
  ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     queue_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     !simd_opcode_supported(alu_control)) ##1
  ((alu.valu.alu_done | ~alu_source_exec_value) != '1)[*100]);

  // Liveness property that SHOULD fail if an unsupported SIMD opcode can
  // reach execution with any active EXEC lane.
  property p_no_unsupported_simd_exec_stall;
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     queue_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     !simd_opcode_supported(alu_control))
    |-> s_eventually valu_done;
  endproperty
  assert property (p_no_unsupported_simd_exec_stall)
    else $error("DEADLOCK_ALU#1: Unsupported SIMD opcode entered EX and never raised valu_done");

  property p_no_supported_simd_exec_stall;
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     queue_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     simd_opcode_supported(alu_control))
    |-> s_eventually valu_done;
  endproperty
  assert property (p_no_supported_simd_exec_stall)
    else $error("DEADLOCK_ALU#1: Supported SIMD opcode entered EX and never raised valu_done");

  // Positive characterization of the bug: once the unsupported opcode is
  // resident in EX, the ALU should remain not-ready on the following cycle.
  property p_unsupported_simd_forces_backpressure;
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     queue_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     !simd_opcode_supported(alu_control))
    |=> !issue_alu_ready;
  endproperty
  assert property (p_unsupported_simd_forces_backpressure)
    else $error("DEADLOCK_ALU#1: Expected issue_alu_ready to stay low during unsupported SIMD execution");

  // Sanity check: supported SIMD operations should finish within a bounded
  // window. This helps distinguish the unsupported-opcode deadlock from a bad
  // proof setup.
  property p_supported_simd_opcode_completes;
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     simd_opcode_supported(alu_control))
    |-> ##[1:12] valu_done;
  endproperty
  assert property (p_supported_simd_opcode_completes)
    else $error("DEADLOCK_ALU#1_SANITY: Supported SIMD opcode did not complete within 12 cycles");

  // Cover: witness the deadlock signature directly.
  cover property (
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     queue_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     !simd_opcode_supported(alu_control))
    ##1 (!valu_done && !issue_alu_ready)[*8]
  );

  // Cover: witness the healthy contrast case for supported instructions.
  cover property (
    @(posedge clk) disable iff (rst)
    ((MODULE == `MODULE_SIMD) &&
     !alu_ready &&
     (|alu_control) &&
     (|alu_source_exec_value) &&
     simd_opcode_supported(alu_control))
    ##[1:12] valu_done ##1 alu_ready
  );

endmodule

// ============================================================
// Optional lane-local witness on simd_alu
// ============================================================

module deadlock_assertions_simd_lane_bind
  (
   input logic        clk,
   input logic        rst,
   input logic        alu_source_exec_value,
   input logic [31:0] alu_control,
   input logic        alu_done
   );

  function automatic bit simd_opcode_supported(input logic [31:0] opcode);
    begin
      casez ({opcode[31:24], opcode[11:0]})
        {`ALU_VOP1_FORMAT, 12'h001},
        {`ALU_VOP2_FORMAT, 12'h025},
        {`ALU_VOP2_FORMAT, 12'h026},
        {`ALU_VOP2_FORMAT, 12'h01B},
        {`ALU_VOP3A_FORMAT, 12'h11B},
        {`ALU_VOP2_FORMAT, 12'h01C},
        {`ALU_VOP2_FORMAT, 12'h01A},
        {`ALU_VOP2_FORMAT, 12'h016},
        {`ALU_VOP2_FORMAT, 12'h018},
        {`ALU_VOP2_FORMAT, 12'h014},
        {`ALU_VOP2_FORMAT, 12'h012},
        {`ALU_VOP3A_FORMAT, 12'h114},
        {`ALU_VOP2_FORMAT, 12'h013},
        {`ALU_VOP2_FORMAT, 12'h113},
        {`ALU_VOP2_FORMAT, 12'h000},
        {`ALU_VOPC_FORMAT, 12'h080},
        {`ALU_VOPC_FORMAT, 12'h081},
        {`ALU_VOPC_FORMAT, 12'h082},
        {`ALU_VOPC_FORMAT, 12'h083},
        {`ALU_VOPC_FORMAT, 12'h084},
        {`ALU_VOPC_FORMAT, 12'h085},
        {`ALU_VOPC_FORMAT, 12'h086},
        {`ALU_VOPC_FORMAT, 12'h087},
        {`ALU_VOPC_FORMAT, 12'h0C0},
        {`ALU_VOPC_FORMAT, 12'h0C1},
        {`ALU_VOPC_FORMAT, 12'h0C2},
        {`ALU_VOPC_FORMAT, 12'h0C3},
        {`ALU_VOPC_FORMAT, 12'h0C4},
        {`ALU_VOPC_FORMAT, 12'h0C5},
        {`ALU_VOPC_FORMAT, 12'h0C6},
        {`ALU_VOPC_FORMAT, 12'h0C7},
        {`ALU_VOP3A_FORMAT, 12'h080},
        {`ALU_VOP3A_FORMAT, 12'h081},
        {`ALU_VOP3A_FORMAT, 12'h082},
        {`ALU_VOP3A_FORMAT, 12'h083},
        {`ALU_VOP3A_FORMAT, 12'h084},
        {`ALU_VOP3A_FORMAT, 12'h085},
        {`ALU_VOP3A_FORMAT, 12'h086},
        {`ALU_VOP3A_FORMAT, 12'h087},
        {`ALU_VOP3A_FORMAT, 12'h0C0},
        {`ALU_VOP3A_FORMAT, 12'h0C1},
        {`ALU_VOP3A_FORMAT, 12'h0C2},
        {`ALU_VOP3A_FORMAT, 12'h0C3},
        {`ALU_VOP3A_FORMAT, 12'h0C4},
        {`ALU_VOP3A_FORMAT, 12'h0C5},
        {`ALU_VOP3A_FORMAT, 12'h0C6},
        {`ALU_VOP3A_FORMAT, 12'h0C7},
        {`ALU_VOP3A_FORMAT, 12'h16A},
        {`ALU_VOP2_FORMAT, 12'h009},
        {`ALU_VOP3A_FORMAT, 12'h109},
        {`ALU_VOP3A_FORMAT, 12'h16B},
        {`ALU_VOP3A_FORMAT, 12'h169},
        {`ALU_VOP3A_FORMAT, 12'h148},
        {`ALU_VOP3A_FORMAT, 12'h149},
        {`ALU_VOP3A_FORMAT, 12'h14A},
        {`ALU_VOP2_FORMAT, 12'h028},
        {`ALU_VOP2_FORMAT, 12'h027}: simd_opcode_supported = 1'b1;
        default: simd_opcode_supported = 1'b0;
      endcase
    end
  endfunction

  // If an active lane sees an unsupported opcode, it should currently sit in
  // the failing default path with alu_done low. This is a witness property.
  property p_lane_hits_default_done_zero;
    @(posedge clk) disable iff (rst)
    (alu_source_exec_value && (|alu_control) && !simd_opcode_supported(alu_control))
    |-> !alu_done;
  endproperty
  assert property (p_lane_hits_default_done_zero)
    else $error("DEADLOCK_ALU#1_LANE: Unsupported active SIMD lane was not observed with alu_done=0");

  cover property (
    @(posedge clk) disable iff (rst)
    (alu_source_exec_value && (|alu_control) && !simd_opcode_supported(alu_control))
    ##1 !alu_done[*4]
  );

endmodule

// ============================================================
// Bind statements
// ============================================================

bind alu deadlock_assertions_alu_bind #(.MODULE(MODULE)) deadlock_assertions_alu_bind_i (
  .clk(clk),
  .rst(rst),
  .alu_ready(alu_ready),
  .valu_done(valu_done),
  .issue_alu_ready(issue_alu_ready),
  .queue_ready(queue_ready),
  .alu_control(alu_control),
  .alu_source_exec_value(alu_source_exec_value)
);

bind simd_alu deadlock_assertions_simd_lane_bind deadlock_assertions_simd_lane_bind_i (
  .clk(clk),
  .rst(rst),
  .alu_source_exec_value(alu_source_exec_value),
  .alu_control(alu_control),
  .alu_done(alu_done)
);
