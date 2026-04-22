clear -all
analyze -sv12 -f filelist.f
analyze -sv12 cu_props.sv
elaborate -top compute_unit \
	-bbox_m {vgpr sgpr} \
	-bbox_i {
    	simd0.alu.valu \
    	simd0.alu.src_shift_reg \
    	simd0.alu.dest_shift_reg \
    	simd0.alu.src1_mux \
    	simd0.alu.src2_mux \
    	simd0.alu.src3_mux \
    	simd1.alu.valu \
    	simd1.alu.src_shift_reg \
    	simd1.alu.dest_shift_reg \
    	simd1.alu.src1_mux \
    	simd1.alu.src2_mux \
    	simd1.alu.src3_mux \
    	simd2.alu.valu \
    	simd2.alu.src_shift_reg \
    	simd2.alu.dest_shift_reg \
    	simd2.alu.src1_mux \
    	simd2.alu.src2_mux \
    	simd2.alu.src3_mux \
    	simd3.alu.valu \
    	simd3.alu.src_shift_reg \
    	simd3.alu.dest_shift_reg \
    	simd3.alu.src1_mux \
    	simd3.alu.src2_mux \
    	simd3.alu.src3_mux \
    	simf0.alu.valu \
    	simf0.alu.src_shift_reg \
    	simf0.alu.dest_shift_reg \
   	simf0.alu.src1_mux \
    	simf0.alu.src2_mux \
    	simf0.alu.src3_mux \
    	simf1.alu.valu \
    	simf1.alu.src_shift_reg \
    	simf1.alu.dest_shift_reg \
    	simf1.alu.src1_mux \
    	simf1.alu.src2_mux \
    	simf1.alu.src3_mux \
    	simf2.alu.valu \
    	simf2.alu.src_shift_reg \
    	simf2.alu.dest_shift_reg \
    	simf2.alu.src1_mux \
   	 simf2.alu.src2_mux \
    	simf2.alu.src3_mux \
    	simf3.alu.valu \
    	simf3.alu.src_shift_reg \
    	simf3.alu.dest_shift_reg \
    	simf3.alu.src1_mux \
    	simf3.alu.src2_mux \
    	simf3.alu.src3_mux \
  	}
clock clk
reset rst
prove -all