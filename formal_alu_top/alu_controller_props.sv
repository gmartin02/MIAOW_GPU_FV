module alu_controller_props (
    	// Inputs
    	input logic  	 clk,
    	input logic  	 rst,
    	input logic in_alu_select_flopped,
    	input logic in_alu_select,
    	input logic [11:0] in_source1_addr,
    	input logic [11:0] in_source2_addr,
    	input logic [11:0] in_source3_addr,
    	input logic [11:0] in_dest1_addr,
    	input logic [11:0] in_dest2_addr,
    	input logic [31:0] in_opcode,
    	input logic 	in_valu_done,

    	// Outputs
    	input logic  	out_alu_ready,
    	input logic 	out_vcc_wr_en,
    	input logic 	out_instr_done,
    	input logic 	out_vgpr_wr_en,
    	input logic [11:0] out_vgpr_dest_addr,
    	input logic 	 out_sgpr_wr_en,
    	input logic [11:0] out_sgpr_dest_addr,
    	input logic [31:0] out_alu_control,
    	input logic 	 out_alu_start,
    	input logic 	 out_src_buffer_wr_en,
    	input logic [3:0]  out_source1_mux_select,
    	input logic [3:0]  out_source2_mux_select,
    	input logic [3:0]  out_source3_mux_select,
    	input logic [9:0]  out_source1_src_constant,
    	input logic [9:0]  out_source2_src_constant,
    	input logic [9:0]  out_source3_src_constant,
   
    	input logic 	 out_vgpr_source1_rd_en,
    	input logic 	 out_vgpr_source2_rd_en,
    	input logic 	 out_vgpr_source3_rd_en,
    	input logic 	 out_sgpr_rd_en,
    	input logic 	 out_exec_rd_en,

    	// Internal signals    
    	input logic 	 dec_vcc_wr_en,
   	input logic 	 dec_vgpr_wr_en,
    	input logic 	 dec_sgpr_wr_en,
    	input logic 		 dec_vgpr_source1_rd_en,
    	input logic 		 dec_vgpr_source2_rd_en,
    	input logic 		 dec_vgpr_source3_rd_en,
    	input logic 	 dec_sgpr_rd_en,
    	input logic 	 dec_exec_rd_en,
    	input logic [3:0] 	 dec_out_source1_mux_select,
    	input logic [3:0] 	 dec_out_source2_mux_select,
    	input logic [3:0] 	 dec_out_source3_mux_select,

    	input logic 	 RD, 
    	input logic 	 EX, 
    	input logic 	 WB
);
	default clocking @(posedge clk); endclocking
    	default disable iff (rst);

 	localparam IDLE      = 3'b000;
   	localparam STATE_RD  = 3'b001;
   	localparam STATE_EX1 = 3'b010;
   	localparam STATE_EX2 = 3'b011;
   	localparam STATE_EX3 = 3'b100;
   	localparam STATE_EX4 = 3'b101;	

	//****************************************************************
	// Initial Basic Assertions and Covers to test connectivity
	//****************************************************************

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


	//****************************************************************
	// FSM properties
	//****************************************************************
	
	AST_fsm_valid_state: assert property    ((alu_controller.alu_fsm.current_state == IDLE)      ||
      						 (alu_controller.alu_fsm.current_state == STATE_RD)  ||
      						 (alu_controller.alu_fsm.current_state == STATE_EX1) ||
      						 (alu_controller.alu_fsm.current_state == STATE_EX2) ||
      						 (alu_controller.alu_fsm.current_state == STATE_EX3) ||
      						 (alu_controller.alu_fsm.current_state == STATE_EX4));
	
	COV_fsm_can_enter_RD: cover property (alu_controller.alu_fsm.current_state == STATE_RD);

	AST_read_no_select_goes_EX1: assert property ((alu_controller.alu_fsm.current_state == STATE_RD && !in_alu_select_flopped) |-> (alu_controller.alu_fsm.next_state == STATE_EX1));
	AST_alu_ready_only_idle: assert property (out_alu_ready |-> (alu_controller.alu_fsm.current_state == IDLE) || (alu_controller.alu_fsm.current_state == STATE_EX4 && in_valu_done));
	

	// Full 4-pass instruction lifecycle
   	COV_full_instruction_cycle: cover property (
         	(alu_controller.alu_fsm.current_state == IDLE && in_alu_select_flopped) ##[1:$]
         	(alu_controller.alu_fsm.current_state == STATE_EX1 && in_valu_done)     ##[1:$]
       		(alu_controller.alu_fsm.current_state == STATE_EX2 && in_valu_done)     ##[1:$]
       		(alu_controller.alu_fsm.current_state == STATE_EX3 && in_valu_done)     ##[1:$]
       		(alu_controller.alu_fsm.current_state == STATE_EX4 && in_valu_done)     ##[1:$]
       		(alu_controller.alu_fsm.current_state == IDLE)
     	);
 
   	// Back-to-back instructions
   	COV_back_to_back_dispatch: cover property (
        	out_instr_done ##[1:3] (alu_controller.alu_fsm.current_state == IDLE && in_alu_select_flopped)
      	);
 
   	COV_vgpr_writeback: cover property (WB && out_vgpr_wr_en && out_instr_done);
 
   	COV_VCC_wr_en: cover property (out_vcc_wr_en);
 
   	COV_sgpr_writeback: cover property (WB && out_sgpr_wr_en && out_instr_done);
 
   	COV_all_vgpr_sources: cover property (
         	out_vgpr_source1_rd_en && out_vgpr_source2_rd_en && out_vgpr_source3_rd_en
      	);
 
   	COV_read_SCC: cover property (out_source3_mux_select == 4'b1011);
 
	COV_src1_literal: cover property (out_source1_mux_select == 4'b0000);
 
  	COV_src1_sgpr: cover property (out_source1_mux_select == 4'b0011);
 
   	COV_read_vcc_lo: cover property (out_source1_mux_select == 4'b0100);
 
   	COV_read_exec_lo: cover property (out_source1_mux_select == 4'b0111);



endmodule

bind alu_controller alu_controller_props u_alu_controller_props (
    	// Inputs
    	.clk(clk),
    	.rst(rst),
    	.in_alu_select_flopped(in_alu_select_flopped),
    	.in_alu_select(in_alu_select),
    	.in_source1_addr(in_source1_addr),
    	.in_source2_addr(in_source2_addr),
    	.in_source3_addr(in_source3_addr),
    	.in_dest1_addr(in_dest1_addr),
    	.in_dest2_addr(in_dest2_addr),
    	.in_opcode(in_opcode),
    	.in_valu_done(in_valu_done),

    	// Outputs
    	.out_alu_ready(out_alu_ready),
    	.out_vcc_wr_en(out_vcc_wr_en),
    	.out_instr_done(out_instr_done),
    	.out_vgpr_wr_en(out_vgpr_wr_en),
    	.out_vgpr_dest_addr(out_vgpr_dest_addr),
    	.out_sgpr_wr_en(out_sgpr_wr_en),
    	.out_sgpr_dest_addr(out_sgpr_dest_addr),
    	.out_alu_control(out_alu_control),
    	.out_alu_start(out_alu_start),
    	.out_src_buffer_wr_en(out_src_buffer_wr_en),
    	.out_source1_mux_select(out_source1_mux_select),
    	.out_source2_mux_select(out_source2_mux_select),
    	.out_source3_mux_select(out_source3_mux_select),
    	.out_source1_src_constant(out_source1_src_constant),
    	.out_source2_src_constant(out_source2_src_constant),
    	.out_source3_src_constant(out_source3_src_constant),
   
    	.out_vgpr_source1_rd_en(out_vgpr_source1_rd_en),
    	.out_vgpr_source2_rd_en(out_vgpr_source2_rd_en),
    	.out_vgpr_source3_rd_en(out_vgpr_source3_rd_en),
    	.out_sgpr_rd_en(out_sgpr_rd_en),
    	.out_exec_rd_en(out_exec_rd_en),

    	// Internal signals    
    	.dec_vcc_wr_en(dec_vcc_wr_en),
   	.dec_vgpr_wr_en(dec_vgpr_wr_en),
    	.dec_sgpr_wr_en(dec_sgpr_wr_en),
    	.dec_vgpr_source1_rd_en(dec_vgpr_source1_rd_en),
    	.dec_vgpr_source2_rd_en(dec_vgpr_source2_rd_en),
    	.dec_vgpr_source3_rd_en(dec_vgpr_source3_rd_en),
    	.dec_sgpr_rd_en(dec_sgpr_rd_en),
    	.dec_exec_rd_en(dec_exec_rd_en),
    	.dec_out_source1_mux_select(dec_out_source1_mux_select),
    	.dec_out_source2_mux_select(dec_out_source2_mux_select),
    	.dec_out_source3_mux_select(dec_out_source3_mux_select),

    	.RD(RD), 
    	.EX(EX), 
    	.WB(WB)
);