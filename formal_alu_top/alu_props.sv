module alu_props (
    input logic         clk,
    input logic         rst,

    // Inputs
    input logic         issue_alu_select,
    input logic         exec_rd_scc_value,
    input logic         rfa_queue_entry_serviced,

    input logic [5:0]   issue_wfid,

    input logic [11:0]  issue_source_reg1,
    input logic [11:0]  issue_source_reg2,
    input logic [11:0]  issue_source_reg3,
    input logic [11:0]  issue_dest_reg1,
    input logic [11:0]  issue_dest_reg2,

    input logic [15:0]  issue_imm_value0,

    input logic [31:0]  issue_imm_value1,
    input logic [31:0]  issue_opcode,
    input logic [31:0]  sgpr_rd_data,
    input logic [31:0]  exec_rd_m0_value,
    input logic [31:0]  issue_instr_pc,

    input logic [63:0]  exec_rd_exec_value,
    input logic [63:0]  exec_rd_vcc_value,

    input logic [2047:0] vgpr_source1_data,
    input logic [2047:0] vgpr_source2_data,
    input logic [2047:0] vgpr_source3_data,

    // Outputs
    input logic          vgpr_source1_rd_en,
    input logic          vgpr_source2_rd_en,
    input logic          vgpr_source3_rd_en,
    input logic          vgpr_wr_en,
    input logic          exec_rd_en,
    input logic          exec_wr_vcc_en,
    input logic          sgpr_rd_en,
    input logic          sgpr_wr_en,
    input logic          issue_alu_ready,
    input logic          vgpr_instr_done,
    input logic          rfa_queue_entry_valid,

    input logic [5:0]    exec_rd_wfid,
    input logic [5:0]    exec_wr_vcc_wfid,
    input logic [5:0]    vgpr_instr_done_wfid,

    input logic [8:0]    sgpr_rd_addr,
    input logic [8:0]    sgpr_wr_addr,

    input logic [9:0]    vgpr_source1_addr,
    input logic [9:0]    vgpr_source2_addr,
    input logic [9:0]    vgpr_source3_addr,
    input logic [9:0]    vgpr_dest_addr,

    input logic [31:0]   tracemon_retire_pc,

    input logic [63:0]   vgpr_wr_mask,
    input logic [63:0]   exec_wr_vcc_value,
    input logic [63:0]   sgpr_wr_data,
    input logic [63:0]   sgpr_wr_mask,

    input logic [2047:0] vgpr_dest_data,

    // Internal signals
    input logic [11:0]   rd_source1_addr,
    input logic [11:0]   rd_source2_addr,
    input logic [11:0]   rd_source3_addr,

    input logic          cnt_alu_select,
    input logic [31:0]   cnt_opcode,
    input logic [11:0]   rd_dest1_addr,
    input logic [11:0]   rd_dest2_addr,
    input logic [5:0]    ex_wfid,
    input logic [31:0]   ex_instr_pc,
    input logic [15:0]   imm_value_0,
    input logic [31:0]   imm_value_1,

    input logic [3:0]    source1_mux_select,
    input logic [3:0]    source2_mux_select,
    input logic [3:0]    source3_mux_select,
    input logic          src_buffer_wr_en,
    input logic [31:0]   alu_control,
    input logic          alu_start,
    input logic [11:0]   ex_vgpr_dest_addr,
    input logic [11:0]   ex_sgpr_dest_addr,
    input logic          ex_vgpr_wr_en,
    input logic          ex_sgpr_wr_en,
    input logic          ex_instr_done,
    input logic          ex_vcc_wr_en,
    input logic          alu_ready,
    input logic [9:0]    source1_src_constant,
    input logic [9:0]    source2_src_constant,
    input logic [9:0]    source3_src_constant,

    input logic [2047:0] source1_data,
    input logic [2047:0] source2_data,
    input logic [2047:0] source3_data,

    input logic [511:0]  alu_source1_data,
    input logic [511:0]  alu_source2_data,
    input logic [511:0]  alu_source3_data,
    input logic [15:0]   alu_source_vcc_value,
    input logic [15:0]   alu_source_exec_value,

    input logic [511:0]  alu_vgpr_dest_data,
    input logic [15:0]   alu_sgpr_dest_data,
    input logic [15:0]   alu_dest_vcc_value,
    input logic [15:0]   alu_dest_exec_value,
    input logic          valu_done,

    input logic [2047:0] queue_vgpr_dest_data,
    input logic [63:0]   queue_sgpr_dest_data,
    input logic [63:0]   queue_vgpr_wr_mask,
    input logic [63:0]   queue_exec_wr_vcc_value,

    input logic          queue_vgpr_wr_en,
    input logic          queue_sgpr_wr_en,
    input logic [9:0]    queue_vgpr_dest_addr,
    input logic [8:0]    queue_sgpr_dest_addr,
    input logic [5:0]    queue_vgpr_instr_done_wfid,
    input logic [31:0]   queue_tracemon_retire_pc,
    input logic          queue_vgpr_instr_done,
    input logic          queue_exec_wr_vcc_en,

    input logic          queue_ready,
    input logic          queue_empty,

    input logic [31:0]   sgpr_rd_data_i,
    input logic [31:0]   exec_rd_m0_value_i,
    input logic [63:0]   exec_rd_exec_value_i,
    input logic [63:0]   exec_rd_vcc_value_i,
    input logic          exec_rd_scc_value_i,
    input logic [2047:0] vgpr_source1_data_i,
    input logic [2047:0] vgpr_source2_data_i,
    input logic [2047:0] vgpr_source3_data_i
);

    default clocking cb @(posedge clk); endclocking
    default disable iff (rst);

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
  function automatic bit is_v_add_i32(input logic [31:0] opcode);
  return ({opcode[31:24], opcode[11:0]} ==
          {`ALU_VOP2_FORMAT, 12'h025});
endfunction
    // When vgpr writeback is asserted, done should also be asserted in same phase
    AST_vgpr_write_means_done: assert property (vgpr_wr_en |-> vgpr_instr_done);

    // Issue -> ALU start
    COV_issue_to_alu_start: cover property (issue_alu_select ##[1:10] alu_start);

    // Issue -> VALU done
    COV_issue_to_valu_done: cover property (issue_alu_select ##[1:30] valu_done);

    // Issue -> queue stage done
    COV_issue_to_queue_done: cover property (issue_alu_select ##[1:40] queue_vgpr_instr_done);

    // Issue -> final instruction done
    COV_issue_to_instr_done: cover property (issue_alu_select ##[1:60] vgpr_instr_done);

    // Full visible end-to-end path
    COV_issue_alu_done_retire: cover property (
        issue_alu_select 
        ##[1:10] alu_start 
        ##[1:20] valu_done  
        ##[1:10] queue_vgpr_instr_done 
        ##[1:20] vgpr_instr_done
    );

    // VOP1 -> VGPR write
    COV_vop1_vgpr_write:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd2)
            ##[0:10] (vgpr_source1_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && vgpr_wr_en)
        );

    COV_vop1_vgpr_write2:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd2)
            ##[0:10] (vgpr_source1_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && vgpr_wr_en && (vgpr_instr_done_wfid == issue_wfid))
        );

    COV_vop1_vgpr_write3:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd2)
            ##[0:10] (vgpr_source1_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && sgpr_wr_en && (vgpr_instr_done_wfid == issue_wfid))
        );

    // VOP2 -> VGPR write
    COV_vop2_vgpr_write:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd4)
            ##[0:10] (vgpr_source1_rd_en || vgpr_source2_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && vgpr_wr_en)
        );

    // VOP3a -> VGPR write
    COV_vop3a_vgpr_write:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd16)
            ##[0:10] (vgpr_source1_rd_en || vgpr_source2_rd_en || vgpr_source3_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && vgpr_wr_en)
        );

    // VOP3b -> VGPR write path exercised
    COV_vop3b_vgpr_write:
        cover property (
            issue_alu_select
            && (cnt_opcode[31:24] == 8'd8)
            ##[0:10] (vgpr_source1_rd_en || vgpr_source2_rd_en || vgpr_source3_rd_en || sgpr_rd_en || exec_rd_en)
            ##[1:10] alu_start
            ##[1:20] valu_done
            ##[1:20] (vgpr_instr_done && vgpr_wr_en)
        );

endmodule

bind alu alu_props u_alu_props (
    .clk(clk),
    .rst(rst),

    .issue_alu_select(issue_alu_select),
    .exec_rd_scc_value(exec_rd_scc_value),
    .rfa_queue_entry_serviced(rfa_queue_entry_serviced),
    .issue_wfid(issue_wfid),
    .issue_source_reg1(issue_source_reg1),
    .issue_source_reg2(issue_source_reg2),
    .issue_source_reg3(issue_source_reg3),
    .issue_dest_reg1(issue_dest_reg1),
    .issue_dest_reg2(issue_dest_reg2),
    .issue_imm_value0(issue_imm_value0),
    .issue_imm_value1(issue_imm_value1),
    .issue_opcode(issue_opcode),
    .sgpr_rd_data(sgpr_rd_data),
    .exec_rd_m0_value(exec_rd_m0_value),
    .issue_instr_pc(issue_instr_pc),
    .exec_rd_exec_value(exec_rd_exec_value),
    .exec_rd_vcc_value(exec_rd_vcc_value),
    .vgpr_source1_data(vgpr_source1_data),
    .vgpr_source2_data(vgpr_source2_data),
    .vgpr_source3_data(vgpr_source3_data),

    .vgpr_source1_rd_en(vgpr_source1_rd_en),
    .vgpr_source2_rd_en(vgpr_source2_rd_en),
    .vgpr_source3_rd_en(vgpr_source3_rd_en),
    .vgpr_wr_en(vgpr_wr_en),
    .exec_rd_en(exec_rd_en),
    .exec_wr_vcc_en(exec_wr_vcc_en),
    .sgpr_rd_en(sgpr_rd_en),
    .sgpr_wr_en(sgpr_wr_en),
    .issue_alu_ready(issue_alu_ready),
    .vgpr_instr_done(vgpr_instr_done),
    .rfa_queue_entry_valid(rfa_queue_entry_valid),
    .exec_rd_wfid(exec_rd_wfid),
    .exec_wr_vcc_wfid(exec_wr_vcc_wfid),
    .vgpr_instr_done_wfid(vgpr_instr_done_wfid),
    .sgpr_rd_addr(sgpr_rd_addr),
    .sgpr_wr_addr(sgpr_wr_addr),
    .vgpr_source1_addr(vgpr_source1_addr),
    .vgpr_source2_addr(vgpr_source2_addr),
    .vgpr_source3_addr(vgpr_source3_addr),
    .vgpr_dest_addr(vgpr_dest_addr),
    .tracemon_retire_pc(tracemon_retire_pc),
    .vgpr_wr_mask(vgpr_wr_mask),
    .exec_wr_vcc_value(exec_wr_vcc_value),
    .sgpr_wr_data(sgpr_wr_data),
    .sgpr_wr_mask(sgpr_wr_mask),
    .vgpr_dest_data(vgpr_dest_data),

    .rd_source1_addr(rd_source1_addr),
    .rd_source2_addr(rd_source2_addr),
    .rd_source3_addr(rd_source3_addr),

    .cnt_alu_select(cnt_alu_select),
    .cnt_opcode(cnt_opcode),
    .rd_dest1_addr(rd_dest1_addr),
    .rd_dest2_addr(rd_dest2_addr),
    .ex_wfid(ex_wfid),
    .ex_instr_pc(ex_instr_pc),
    .imm_value_0(imm_value_0),
    .imm_value_1(imm_value_1),

    .source1_mux_select(source1_mux_select),
    .source2_mux_select(source2_mux_select),
    .source3_mux_select(source3_mux_select),
    .src_buffer_wr_en(src_buffer_wr_en),
    .alu_control(alu_control),
    .alu_start(alu_start),
    .ex_vgpr_dest_addr(ex_vgpr_dest_addr),
    .ex_sgpr_dest_addr(ex_sgpr_dest_addr),
    .ex_vgpr_wr_en(ex_vgpr_wr_en),
    .ex_sgpr_wr_en(ex_sgpr_wr_en),
    .ex_instr_done(ex_instr_done),
    .ex_vcc_wr_en(ex_vcc_wr_en),
    .alu_ready(alu_ready),
    .source1_src_constant(source1_src_constant),
    .source2_src_constant(source2_src_constant),
    .source3_src_constant(source3_src_constant),

    .source1_data(source1_data),
    .source2_data(source2_data),
    .source3_data(source3_data),

    .alu_source1_data(alu_source1_data),
    .alu_source2_data(alu_source2_data),
    .alu_source3_data(alu_source3_data),
    .alu_source_vcc_value(alu_source_vcc_value),
    .alu_source_exec_value(alu_source_exec_value),

    .alu_vgpr_dest_data(alu_vgpr_dest_data),
    .alu_sgpr_dest_data(alu_sgpr_dest_data),
    .alu_dest_vcc_value(alu_dest_vcc_value),
    .alu_dest_exec_value(alu_dest_exec_value),
    .valu_done(valu_done),

    .queue_vgpr_dest_data(queue_vgpr_dest_data),
    .queue_sgpr_dest_data(queue_sgpr_dest_data),
    .queue_vgpr_wr_mask(queue_vgpr_wr_mask),
    .queue_exec_wr_vcc_value(queue_exec_wr_vcc_value),

    .queue_vgpr_wr_en(queue_vgpr_wr_en),
    .queue_sgpr_wr_en(queue_sgpr_wr_en),
    .queue_vgpr_dest_addr(queue_vgpr_dest_addr),
    .queue_sgpr_dest_addr(queue_sgpr_dest_addr),
    .queue_vgpr_instr_done_wfid(queue_vgpr_instr_done_wfid),
    .queue_tracemon_retire_pc(queue_tracemon_retire_pc),
    .queue_vgpr_instr_done(queue_vgpr_instr_done),
    .queue_exec_wr_vcc_en(queue_exec_wr_vcc_en),

    .queue_ready(queue_ready),
    .queue_empty(queue_empty),

    .sgpr_rd_data_i(sgpr_rd_data_i),
    .exec_rd_m0_value_i(exec_rd_m0_value_i),
    .exec_rd_exec_value_i(exec_rd_exec_value_i),
    .exec_rd_vcc_value_i(exec_rd_vcc_value_i),
    .exec_rd_scc_value_i(exec_rd_scc_value_i),
    .vgpr_source1_data_i(vgpr_source1_data_i),
    .vgpr_source2_data_i(vgpr_source2_data_i),
    .vgpr_source3_data_i(vgpr_source3_data_i)
);