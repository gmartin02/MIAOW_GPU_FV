// Purpose:
//   - choose one instruction instance using nondeterministic WFID + PC
//   - latch what the instruction is (raw instruction bits, opcode, FU)
//   - expose stage/location booleans for waveform inspection
//   - expose completion booleans for SALU / SIMD / SIMF / LSU paths

module cu_props #(
    parameter int WFID_W   = 6,
    parameter int PC_W     = 32,
    parameter int INSTR_W  = 32,
    parameter int OPCODE_W = 32,
    parameter int FU_W     = 2,
    parameter int SGPR_AW  = 9,
    parameter int VGPR_AW  = 10
) (
    input  logic                  clk,
    input  logic                  rst,

    // Decode/fetch-side identity
    input  logic                  wave2decode_instr_valid,
    input  logic [WFID_W-1:0]     wave2decode_wfid,
    input  logic [PC_W-1:0]       wave2decode_instr_pc,
    input  logic [INSTR_W-1:0]    wave2decode_instr,

    input  logic                  decode2issue_valid,
    input  logic [WFID_W-1:0]     decode2issue_wfid,
    input  logic [PC_W-1:0]       decode2issue_instr_pc,
    input  logic [OPCODE_W-1:0]   decode2issue_opcode,
    input  logic [FU_W-1:0]       decode2issue_fu,

    // Issue classification
    input  logic                  issue2salu_alu_select,
    input  logic                  issue2simd0_alu_select,
    input  logic                  issue2simd1_alu_select,
    input  logic                  issue2simd2_alu_select,
    input  logic                  issue2simd3_alu_select,
    input  logic                  issue2simf0_alu_select,
    input  logic                  issue2simf1_alu_select,
    input  logic                  issue2simf2_alu_select,
    input  logic                  issue2simf3_alu_select,
    input  logic                  issue2lsu_lsu_select,
    input  logic [WFID_W-1:0]     issue2alu_wfid,
    input  logic [WFID_W-1:0]     issue2lsu_wfid,

    // PC forwarded from issue to execution units — used to latch
    // track_issued_pc for retire-side precision matching.
    input  logic [PC_W-1:0]       issue2alu_instr_pc,
    input  logic [PC_W-1:0]       issue2lsu_instr_pc,

    // Completion / retire-ish markers
    input  logic                  salu2sgpr_instr_done,
    input  logic [WFID_W-1:0]     salu2sgpr_instr_done_wfid,
    input  logic [SGPR_AW-1:0]    salu2sgpr_dest_addr,
    input  logic [PC_W-1:0]       salu2tracemon_retire_pc,

    input  logic                  simd0_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simd0_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simd0_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simd0_2tracemon_retire_pc,
    input  logic                  simd1_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simd1_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simd1_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simd1_2tracemon_retire_pc,
    input  logic                  simd2_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simd2_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simd2_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simd2_2tracemon_retire_pc,
    input  logic                  simd3_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simd3_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simd3_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simd3_2tracemon_retire_pc,

    input  logic                  simf0_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simf0_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simf0_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simf0_2tracemon_retire_pc,
    input  logic                  simf1_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simf1_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simf1_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simf1_2tracemon_retire_pc,
    input  logic                  simf2_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simf2_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simf2_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simf2_2tracemon_retire_pc,
    input  logic                  simf3_2vgpr_instr_done,
    input  logic [WFID_W-1:0]     simf3_2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    simf3_2vgpr_dest_addr,
    input  logic [PC_W-1:0]       simf3_2tracemon_retire_pc,

    input  logic                  lsu2sgpr_instr_done,
    input  logic [WFID_W-1:0]     lsu2sgpr_instr_done_wfid,
    input  logic [SGPR_AW-1:0]    lsu2sgpr_dest_addr,
    input  logic                  lsu2vgpr_instr_done,
    input  logic [WFID_W-1:0]     lsu2vgpr_instr_done_wfid,
    input  logic [VGPR_AW-1:0]    lsu2vgpr_dest_addr,
    input  logic [PC_W-1:0]       lsu2tracemon_retire_pc,

    // SALU branch outcome signals
    input  logic                  salu2fetchwaveissue_branch_en,
    input  logic                  salu2fetchwaveissue_branch_taken,
    input  logic [WFID_W-1:0]     salu2fetchwaveissue_branch_wfid
);

    default clocking @(posedge clk); endclocking
    default disable iff (rst);
    
// ------------------------------------------------------------------------
    // Nondeterministic / oracle choice
    // ------------------------------------------------------------------------
    logic [WFID_W-1:0] ndc_wfid;
    logic [PC_W-1:0]   ndc_pc;

    ASM_NDC_WFID_STABLE: assume property ($stable(ndc_wfid));
    ASM_NDC_PC_STABLE:   assume property ($stable(ndc_pc));

    // ------------------------------------------------------------------------
    // Latched identity of the tracked instruction
    // ------------------------------------------------------------------------
    logic                 track_live;        // has the instruction been seen?
    logic                 track_decoded;     // reached decode->issue boundary
    logic                 track_completed;   // some matching completion seen

    logic [WFID_W-1:0]    track_wfid;
    logic [PC_W-1:0]      track_pc;
    logic [INSTR_W-1:0]   track_instr;
    logic [OPCODE_W-1:0]  track_opcode;
    logic [FU_W-1:0]      track_fu;
    
    // PC as seen at the issue->FU boundary; used for retire-side matching
    logic [PC_W-1:0]      track_issued_pc;

    // Destination address latched at completion
    logic                 track_has_sgpr_dest;
    logic                 track_has_vgpr_dest;
    logic [SGPR_AW-1:0]   track_sgpr_dest;
    logic [VGPR_AW-1:0]   track_vgpr_dest;

    // Path classification from issue
    logic                 track_issued_salu;
    logic                 track_issued_simd0;
    logic                 track_issued_simd1;
    logic                 track_issued_simd2;
    logic                 track_issued_simd3;
    logic                 track_issued_simf0;
    logic                 track_issued_simf1;
    logic                 track_issued_simf2;
    logic                 track_issued_simf3;
    logic                 track_issued_lsu;

    // ------------------------------------------------------------------------
    // Convenience predicates
    // ------------------------------------------------------------------------
    wire fetch_match = wave2decode_instr_valid &&
                       (wave2decode_wfid     == ndc_wfid) &&
                       (wave2decode_instr_pc == ndc_pc);

    wire decode_match = track_live && decode2issue_valid &&
                        (decode2issue_wfid     == track_wfid) &&
                        (decode2issue_instr_pc == track_pc);

    // ------------------------------------------------------------------------
    // Latch the tracked instruction on first matching fetch/decode observation
    // ------------------------------------------------------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            track_live         <= 1'b0;
            track_decoded      <= 1'b0;
            track_completed    <= 1'b0;

            track_wfid         <= '0;
            track_pc           <= '0;
            track_instr        <= '0;
            track_opcode       <= '0;
            track_fu           <= '0;

            track_has_sgpr_dest <= 1'b0;
            track_has_vgpr_dest <= 1'b0;
            track_sgpr_dest     <= '0;
            track_vgpr_dest     <= '0;

        end else begin
            // First sighting: latch identity at wave->decode boundary
            if (!track_live && fetch_match) begin
                track_live  <= 1'b1;
                track_wfid  <= wave2decode_wfid;
                track_pc    <= wave2decode_instr_pc;
                track_instr <= wave2decode_instr;
            end

            // Decode boundary: latch decoded operation identity
            if (track_live && !track_decoded && decode_match) begin
                track_decoded <= 1'b1;
                track_opcode  <= decode2issue_opcode;
                track_fu      <= decode2issue_fu;
            end

            // Completion capture.
            //
            // WFID match is required; retire PC match guards against other
            // instructions from the same wavefront completing concurrently.
            if (track_live && track_decoded && !track_completed) begin
                if (salu2sgpr_instr_done &&
                    (salu2sgpr_instr_done_wfid == track_wfid) &&
                    (salu2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_sgpr_dest <= 1'b1;
                    track_sgpr_dest     <= salu2sgpr_dest_addr;
 
                end else if (simd0_2vgpr_instr_done &&
                    (simd0_2vgpr_instr_done_wfid == track_wfid) &&
                    (simd0_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simd0_2vgpr_dest_addr;
 
                end else if (simd1_2vgpr_instr_done &&
                    (simd1_2vgpr_instr_done_wfid == track_wfid) &&
                    (simd1_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simd1_2vgpr_dest_addr;
 
                end else if (simd2_2vgpr_instr_done &&
                    (simd2_2vgpr_instr_done_wfid == track_wfid) &&
                    (simd2_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simd2_2vgpr_dest_addr;
 
                end else if (simd3_2vgpr_instr_done &&
                    (simd3_2vgpr_instr_done_wfid == track_wfid) &&
                    (simd3_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simd3_2vgpr_dest_addr;
 
                end else if (simf0_2vgpr_instr_done &&
                    (simf0_2vgpr_instr_done_wfid == track_wfid) &&
                    (simf0_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simf0_2vgpr_dest_addr;
 
                end else if (simf1_2vgpr_instr_done &&
                    (simf1_2vgpr_instr_done_wfid == track_wfid) &&
                    (simf1_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simf1_2vgpr_dest_addr;
 
                end else if (simf2_2vgpr_instr_done &&
                    (simf2_2vgpr_instr_done_wfid == track_wfid) &&
                    (simf2_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simf2_2vgpr_dest_addr;
 
                end else if (simf3_2vgpr_instr_done &&
                    (simf3_2vgpr_instr_done_wfid == track_wfid) &&
                    (simf3_2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= simf3_2vgpr_dest_addr;
 
                end else if (lsu2sgpr_instr_done &&
                    (lsu2sgpr_instr_done_wfid == track_wfid) &&
                    (lsu2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_sgpr_dest <= 1'b1;
                    track_sgpr_dest     <= lsu2sgpr_dest_addr;
 
                end else if (lsu2vgpr_instr_done &&
                    (lsu2vgpr_instr_done_wfid == track_wfid) &&
                    (lsu2tracemon_retire_pc   == track_issued_pc)) begin
                    track_completed     <= 1'b1;
                    track_has_vgpr_dest <= 1'b1;
                    track_vgpr_dest     <= lsu2vgpr_dest_addr;
                end else if (salu2fetchwaveissue_branch_en &&
                    (salu2fetchwaveissue_branch_wfid == track_wfid) &&
                    track_issued_salu) begin
                    track_completed  <= 1'b1;
                    // branches don't write a destination register so neither
                    // track_has_sgpr_dest nor track_has_vgpr_dest is set
                end
            end
        end
    end

     always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            track_issued_salu   <= 1'b0;
            track_issued_simd0  <= 1'b0;
            track_issued_simd1  <= 1'b0;
            track_issued_simd2  <= 1'b0;
            track_issued_simd3  <= 1'b0;
            track_issued_simf0  <= 1'b0;
            track_issued_simf1  <= 1'b0;
            track_issued_simf2  <= 1'b0;
            track_issued_simf3  <= 1'b0;
            track_issued_lsu    <= 1'b0;
            track_issued_pc     <= '0;
        end else if (track_decoded) begin
            if (!(track_issued_salu || track_issued_simd0 || track_issued_simd1 ||
                  track_issued_simd2 || track_issued_simd3 || track_issued_simf0 ||
                  track_issued_simf1 || track_issued_simf2 || track_issued_simf3 ||
                  track_issued_lsu)) begin
            	// Match on ndc_wfid directly — no track_live dependency.
                if (issue2salu_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_salu <= 1'b1;
                        track_issued_pc   <= issue2alu_instr_pc;
                end
                if (issue2simd0_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simd0 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simd1_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simd1 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simd2_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simd2 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simd3_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simd3 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simf0_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simf0 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simf1_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simf1 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simf2_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simf2 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2simf3_alu_select && 
                    (issue2alu_wfid == track_wfid) &&
                    (issue2alu_instr_pc == track_pc)) begin
                        track_issued_simf3 <= 1'b1;
                        track_issued_pc    <= issue2alu_instr_pc;
                end
                if (issue2lsu_lsu_select && 
                    (issue2lsu_wfid == track_wfid) &&
                    (issue2lsu_instr_pc == track_pc)) begin
                        track_issued_lsu <= 1'b1;
                        track_issued_pc  <= issue2lsu_instr_pc;
                end
	    end
        end
    end

    logic track_was_branch;
    logic track_branch_taken;

    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            track_was_branch   <= 1'b0;
            track_branch_taken <= 1'b0;
        end else if (track_issued_salu &&
                     salu2fetchwaveissue_branch_en &&
                     (salu2fetchwaveissue_branch_wfid == track_wfid) &&
                     !track_was_branch) begin
            track_was_branch   <= 1'b1;
            track_branch_taken <= salu2fetchwaveissue_branch_taken;
        end
    end
    
    // ------------------------------------------------------------------------
    // Location / stage observation wires for easy waveform browsing
    // ------------------------------------------------------------------------
    wire at_fetchdecode = fetch_match;

    wire at_decodeissue = track_live &&
                          decode2issue_valid &&
                          (decode2issue_wfid     == track_wfid) &&
                          (decode2issue_instr_pc == track_pc);

    wire at_issue_salu  = track_decoded && issue2salu_alu_select  &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simd0 = track_decoded && issue2simd0_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simd1 = track_decoded && issue2simd1_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simd2 = track_decoded && issue2simd2_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simd3 = track_decoded && issue2simd3_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simf0 = track_decoded && issue2simf0_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simf1 = track_decoded && issue2simf1_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simf2 = track_decoded && issue2simf2_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_simf3 = track_decoded && issue2simf3_alu_select &&
                          (issue2alu_wfid    == track_wfid) &&
                          (issue2alu_instr_pc == track_pc);

    wire at_issue_lsu   = track_decoded && issue2lsu_lsu_select   &&
                          (issue2lsu_wfid    == track_wfid) &&
                          (issue2lsu_instr_pc == track_pc);

    wire done_salu = salu2sgpr_instr_done &&
                      (salu2sgpr_instr_done_wfid == track_wfid) &&
                      (salu2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_salu;
 
    wire done_simd0 = simd0_2vgpr_instr_done &&
                      (simd0_2vgpr_instr_done_wfid == track_wfid) &&
                      (simd0_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simd0;
    wire done_simd1 = simd1_2vgpr_instr_done &&
                      (simd1_2vgpr_instr_done_wfid == track_wfid) &&
                      (simd1_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simd1;
    wire done_simd2 = simd2_2vgpr_instr_done &&
                      (simd2_2vgpr_instr_done_wfid == track_wfid) &&
                      (simd2_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simd2;
    wire done_simd3 = simd3_2vgpr_instr_done &&
                      (simd3_2vgpr_instr_done_wfid == track_wfid) &&
                      (simd3_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simd3;
 
    wire done_simf0 = simf0_2vgpr_instr_done &&
                      (simf0_2vgpr_instr_done_wfid == track_wfid) &&
                      (simf0_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simf0;
    wire done_simf1 = simf1_2vgpr_instr_done &&
                      (simf1_2vgpr_instr_done_wfid == track_wfid) &&
                      (simf1_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simf1;
    wire done_simf2 = simf2_2vgpr_instr_done &&
                      (simf2_2vgpr_instr_done_wfid == track_wfid) &&
                      (simf2_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simf2;
    wire done_simf3 = simf3_2vgpr_instr_done &&
                      (simf3_2vgpr_instr_done_wfid == track_wfid) &&
                      (simf3_2tracemon_retire_pc   == track_issued_pc) &&
                      track_issued_simf3;
 
    wire done_lsu_sgpr = lsu2sgpr_instr_done &&
                         (lsu2sgpr_instr_done_wfid == track_wfid) &&
                         (lsu2tracemon_retire_pc   == track_issued_pc) &&
                         track_issued_lsu;
    wire done_lsu_vgpr = lsu2vgpr_instr_done &&
                         (lsu2vgpr_instr_done_wfid == track_wfid) &&
                         (lsu2tracemon_retire_pc   == track_issued_pc) &&
                         track_issued_lsu;

    wire done_any = done_salu      ||
                    done_simd0     || done_simd1 || done_simd2 || done_simd3 ||
                    done_simf0     || done_simf1 || done_simf2 || done_simf3 ||
                    done_lsu_sgpr  || done_lsu_vgpr;

    wire at_salu_branch = track_issued_salu &&
                          salu2fetchwaveissue_branch_en &&
                          (salu2fetchwaveissue_branch_wfid == track_wfid);

    wire track_salu_branch_taken     = at_salu_branch &&  salu2fetchwaveissue_branch_taken;
    wire track_salu_branch_not_taken = at_salu_branch && !salu2fetchwaveissue_branch_taken;

    // ------------------------------------------------------------------------
    // Properties
    // ------------------------------------------------------------------------	
    ASM_TRACK_NOT_PRELIVE: assume property (
        $rose(!rst) |-> !track_live
    );

    AST_COMPLETED_STABLE: assert property (
        track_completed |=> track_completed
    );

    AST_LIVE_STABLE: assert property (
        track_live |=> track_live
    );

    AST_TRACK_DECODE_EVENTUALLY_ISSUES: assert property ($rose(track_decoded) |-> ##[1:20]
        (at_issue_salu  || at_issue_simd0 || at_issue_simd1 || at_issue_simd2 || at_issue_simd3 ||
         at_issue_simf0 || at_issue_simf1 || at_issue_simf2 || at_issue_simf3 || at_issue_lsu));

    AST_TRACK_SALU_EVENTUALLY_DONE: assert property ($rose(track_issued_salu) |-> ##[1:40] done_salu);

    AST_TRACK_LSU_EVENTUALLY_DONE: assert property ($rose(track_issued_lsu) |-> ##[1:80] (done_lsu_sgpr || done_lsu_vgpr));

    AST_TRACK_SIMD0_EVENTUALLY_DONE: assert property ($rose(track_issued_simd0) |-> ##[1:60] done_simd0);
    AST_TRACK_SIMF0_EVENTUALLY_DONE: assert property ($rose(track_issued_simf0) |-> ##[1:60] done_simf0);

    AST_NO_ISSUE_BEFORE_DECODE: assert property (
        (track_issued_salu || track_issued_simd0 || track_issued_simd1 || track_issued_simd2 || track_issued_simd3 ||
         track_issued_simf0 || track_issued_simf1 || track_issued_simf2 || track_issued_simf3 || track_issued_lsu)
        |->
        track_decoded
    );    

    AST_ISSUED_BEFORE_COMPLETED: assert property (
        $rose(track_completed) |-> 
        (track_issued_salu || track_issued_simd0 || track_issued_simd1 ||
         track_issued_simd2 || track_issued_simd3 || track_issued_simf0 ||
         track_issued_simf1 || track_issued_simf2 || track_issued_simf3 ||
         track_issued_lsu)
    );

    AST_TRACK_SOMEHOW_COMPLETES: assert property ($rose(track_live) |-> ##[1:100] track_completed);
 
    AST_TRACK_ID_STABLE: assert property ((track_live && $past(track_live)) |-> ($stable(track_wfid) && $stable(track_pc)));
 
    AST_TRACK_DECODED_ID_STABLE: assert property ((track_decoded && $past(track_decoded)) |-> ($stable(track_opcode) && $stable(track_fu)));
    
    AST_SALU_NOT_COMPLETED_AS_LSU: assert property (
        (at_issue_salu && !track_issued_lsu) |->
        not (##[1:40] (done_lsu_sgpr || done_lsu_vgpr))
    );

    AST_TRACK_HAS_AT_MOST_ONE_ISSUED_PATH: assert property (
        $onehot0({
            track_issued_salu,
            track_issued_simd0,
            track_issued_simd1,
            track_issued_simd2,
            track_issued_simd3,
            track_issued_simf0,
            track_issued_simf1,
            track_issued_simf2,
            track_issued_simf3,
            track_issued_lsu
        })
    );
    
    AST_TRACKED_SALU_COMPLETION_IS_SGPR_OR_BRANCH: assert property (
        (track_issued_salu && $rose(track_completed)) |->
        (track_has_sgpr_dest || track_was_branch)
    );

    // If issued to a vector FU, completion must write VGPR
    AST_TRACKED_VALU_COMPLETION_IS_VGPR: assert property (
        ((track_issued_simd0 || track_issued_simd1 ||
          track_issued_simd2 || track_issued_simd3 ||
          track_issued_simf0 || track_issued_simf1 ||
          track_issued_simf2 || track_issued_simf3) && $rose(track_completed)) |->
        track_has_vgpr_dest
    );

    AST_TRACKED_BRANCH_COMPLETION_HAS_NO_DEST: assert property (
        $rose(track_completed) && track_was_branch |->
        (!track_has_sgpr_dest && !track_has_vgpr_dest)
    );

    AST_BRANCH_ONLY_FROM_SALU_PATH: assert property (
        track_was_branch |-> track_issued_salu
    );

    COV_TRACK_SEEN: cover property (track_live);
    COV_TRACK_DECODED: cover property (track_decoded);
    COV_TRACK_COMPLETED: cover property (track_completed);
    

    // Confirm each individual issued flag is reachable
    COV_ISSUED_SALU:  cover property (track_issued_salu);
    COV_ISSUED_SIMD0: cover property (track_issued_simd0);
    COV_ISSUED_SIMF0: cover property (track_issued_simf0);
    COV_ISSUED_LSU:   cover property (track_issued_lsu);

    // Confirm dest latching at completion
    COV_HAS_SGPR_DEST: cover property (track_completed && track_has_sgpr_dest);
    COV_HAS_VGPR_DEST: cover property (track_completed && track_has_vgpr_dest);

    COV_TRACK_SALU: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_salu
        ##[1:20] done_salu
    );

    COV_TRACK_LSU: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_lsu
        ##[1:20] (done_lsu_sgpr || done_lsu_vgpr)
    );

    COV_TRACK_SIMD0: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_simd0
        ##[1:30] done_simd0
    );
 
    COV_TRACK_SIMF0: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_simf0
        ##[1:30] done_simf0
    );

    // Completion before fetch — should be UNREACHABLE
    COV_BAD_COMPLETE_BEFORE_LIVE: cover property (
        track_completed && !track_live
    );

    // Decoded before live — should be UNREACHABLE
    COV_BAD_DECODED_BEFORE_LIVE: cover property (
        track_decoded && !track_live
    );

    // Completed before decoded — should be UNREACHABLE
    // (every completion path requires track_wfid which is only valid after fetch,
    // and track_issued_pc which requires issue which comes after decode)
    COV_BAD_COMPLETE_BEFORE_DECODED: cover property (
        track_completed && !track_decoded
    );

    // Any done wire firing without the matching issued flag — should be UNREACHABLE
    // (these are the covers that caught your original bug)
    COV_BAD_SALU_DONE_NO_ISSUE:  cover property (done_salu  && !track_issued_salu);
    COV_BAD_LSU_DONE_NO_ISSUE:   cover property ((done_lsu_sgpr || done_lsu_vgpr) && !track_issued_lsu);
    COV_BAD_SIMD_DONE_NO_ISSUE:  cover property (
        (done_simd0 || done_simd1 || done_simd2 || done_simd3) &&
        !(track_issued_simd0 || track_issued_simd1 || track_issued_simd2 || track_issued_simd3)
    );
    COV_BAD_SIMF_DONE_NO_ISSUE:  cover property (
        (done_simf0 || done_simf1 || done_simf2 || done_simf3) &&
        !(track_issued_simf0 || track_issued_simf1 || track_issued_simf2 || track_issued_simf3)
    );

    // track_wfid changing after being set — should be UNREACHABLE
    COV_BAD_WFID_CHANGES: cover property (
        track_live && $past(track_live) && !$stable(track_wfid)
    );

    // track_pc changing after being set — should be UNREACHABLE
    COV_BAD_PC_CHANGES: cover property (
        track_live && $past(track_live) && !$stable(track_pc)
    );

    // track_opcode changing after decode — should be UNREACHABLE
    COV_BAD_OPCODE_CHANGES: cover property (
        track_decoded && $past(track_decoded) && !$stable(track_opcode)
    );

    // track_issued_salu going low after being set — should be UNREACHABLE
    // (all track_issued_* are write-once)
    COV_BAD_ISSUED_SALU_CLEARS: cover property (
        $fell(track_issued_salu) && !rst
    );
    COV_BAD_ISSUED_LSU_CLEARS: cover property (
        $fell(track_issued_lsu) && !rst
    );

    // Mutually exclusive FU paths — should be UNREACHABLE
    COV_BAD_SALU_AND_LSU: cover property (
        track_issued_salu && track_issued_lsu
    );

    COV_BAD_SIMD_AND_SIMF: cover property (
        (track_issued_simd0 || track_issued_simd1 ||
         track_issued_simd2 || track_issued_simd3) &&
        (track_issued_simf0 || track_issued_simf1 ||
         track_issued_simf2 || track_issued_simf3)
    );

    COV_TRACK_SALU_BRANCH_TAKEN: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_salu
        ##[1:20] track_salu_branch_taken
    );

    COV_TRACK_SALU_BRANCH_NOT_TAKEN: cover property (
        at_fetchdecode
        ##[1:10] at_decodeissue
        ##[1:10] at_issue_salu
        ##[1:20] track_salu_branch_not_taken
    );

endmodule


bind compute_unit cu_props #(
    .WFID_W  (6),
    .PC_W    (32),
    .INSTR_W (32),
    .OPCODE_W(32),
    .FU_W    (2),
    .SGPR_AW (9),
    .VGPR_AW (10)
) u_ndc (
    .clk(clk),
    .rst(rst),
 
    .wave2decode_instr_valid(wave2decode_instr_valid),
    .wave2decode_wfid(wave2decode_wfid),
    .wave2decode_instr_pc(wave2decode_instr_pc),
    .wave2decode_instr(wave2decode_instr),
 
    .decode2issue_valid(decode2issue_valid),
    .decode2issue_wfid(decode2issue_wfid),
    .decode2issue_instr_pc(decode2issue_instr_pc),
    .decode2issue_opcode(decode2issue_opcode),
    .decode2issue_fu(decode2issue_fu),
 
    .issue2salu_alu_select(issue2salu_alu_select),
    .issue2simd0_alu_select(issue2simd0_alu_select),
    .issue2simd1_alu_select(issue2simd1_alu_select),
    .issue2simd2_alu_select(issue2simd2_alu_select),
    .issue2simd3_alu_select(issue2simd3_alu_select),
    .issue2simf0_alu_select(issue2simf0_alu_select),
    .issue2simf1_alu_select(issue2simf1_alu_select),
    .issue2simf2_alu_select(issue2simf2_alu_select),
    .issue2simf3_alu_select(issue2simf3_alu_select),
    .issue2lsu_lsu_select(issue2lsu_lsu_select),
    .issue2alu_wfid(issue2alu_wfid),
    .issue2lsu_wfid(issue2lsu_wfid),
    .issue2alu_instr_pc(issue2alu_instr_pc),
    .issue2lsu_instr_pc(issue2lsu_instr_pc),
 
    .salu2sgpr_instr_done(salu2sgpr_instr_done),
    .salu2sgpr_instr_done_wfid(salu2sgpr_instr_done_wfid),
    .salu2sgpr_dest_addr(salu2sgpr_dest_addr),
    .salu2tracemon_retire_pc(salu2tracemon_retire_pc),
 
    .simd0_2vgpr_instr_done(simd0_2vgpr_instr_done),
    .simd0_2vgpr_instr_done_wfid(simd0_2vgpr_instr_done_wfid),
    .simd0_2vgpr_dest_addr(simd0_2vgpr_dest_addr),
    .simd0_2tracemon_retire_pc(simd0_2tracemon_retire_pc),
    .simd1_2vgpr_instr_done(simd1_2vgpr_instr_done),
    .simd1_2vgpr_instr_done_wfid(simd1_2vgpr_instr_done_wfid),
    .simd1_2vgpr_dest_addr(simd1_2vgpr_dest_addr),
    .simd1_2tracemon_retire_pc(simd1_2tracemon_retire_pc),
    .simd2_2vgpr_instr_done(simd2_2vgpr_instr_done),
    .simd2_2vgpr_instr_done_wfid(simd2_2vgpr_instr_done_wfid),
    .simd2_2vgpr_dest_addr(simd2_2vgpr_dest_addr),
    .simd2_2tracemon_retire_pc(simd2_2tracemon_retire_pc),
    .simd3_2vgpr_instr_done(simd3_2vgpr_instr_done),
    .simd3_2vgpr_instr_done_wfid(simd3_2vgpr_instr_done_wfid),
    .simd3_2vgpr_dest_addr(simd3_2vgpr_dest_addr),
    .simd3_2tracemon_retire_pc(simd3_2tracemon_retire_pc),
 
    .simf0_2vgpr_instr_done(simf0_2vgpr_instr_done),
    .simf0_2vgpr_instr_done_wfid(simf0_2vgpr_instr_done_wfid),
    .simf0_2vgpr_dest_addr(simf0_2vgpr_dest_addr),
    .simf0_2tracemon_retire_pc(simf0_2tracemon_retire_pc),
    .simf1_2vgpr_instr_done(simf1_2vgpr_instr_done),
    .simf1_2vgpr_instr_done_wfid(simf1_2vgpr_instr_done_wfid),
    .simf1_2vgpr_dest_addr(simf1_2vgpr_dest_addr),
    .simf1_2tracemon_retire_pc(simf1_2tracemon_retire_pc),
    .simf2_2vgpr_instr_done(simf2_2vgpr_instr_done),
    .simf2_2vgpr_instr_done_wfid(simf2_2vgpr_instr_done_wfid),
    .simf2_2vgpr_dest_addr(simf2_2vgpr_dest_addr),
    .simf2_2tracemon_retire_pc(simf2_2tracemon_retire_pc),
    .simf3_2vgpr_instr_done(simf3_2vgpr_instr_done),
    .simf3_2vgpr_instr_done_wfid(simf3_2vgpr_instr_done_wfid),
    .simf3_2vgpr_dest_addr(simf3_2vgpr_dest_addr),
    .simf3_2tracemon_retire_pc(simf3_2tracemon_retire_pc),
 
    .lsu2sgpr_instr_done(lsu2sgpr_instr_done),
    .lsu2sgpr_instr_done_wfid(lsu2sgpr_instr_done_wfid),
    .lsu2sgpr_dest_addr(lsu2sgpr_dest_addr),
    .lsu2vgpr_instr_done(lsu2vgpr_instr_done),
    .lsu2vgpr_instr_done_wfid(lsu2vgpr_instr_done_wfid),
    .lsu2vgpr_dest_addr(lsu2vgpr_dest_addr),
    .lsu2tracemon_retire_pc(lsu2tracemon_retire_pc),

    .salu2fetchwaveissue_branch_en(salu2fetchwaveissue_branch_en),
    .salu2fetchwaveissue_branch_taken(salu2fetchwaveissue_branch_taken),
    .salu2fetchwaveissue_branch_wfid(salu2fetchwaveissue_branch_wfid)
);
