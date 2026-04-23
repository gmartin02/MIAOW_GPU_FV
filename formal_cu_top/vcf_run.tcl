set_blackbox -designs {vgpr sgpr}
set_blackbox -cells {
  simd0.alu.valu
  simd0.alu.src_shift_reg
  simd0.alu.dest_shift_reg
  simd0.alu.src1_mux
  simd0.alu.src2_mux
  simd0.alu.src3_mux

  simd1.alu.valu
  simd1.alu.src_shift_reg
  simd1.alu.dest_shift_reg
  simd1.alu.src1_mux
  simd1.alu.src2_mux
  simd1.alu.src3_mux

  simd2.alu.valu
  simd2.alu.src_shift_reg
  simd2.alu.dest_shift_reg
  simd2.alu.src1_mux
  simd2.alu.src2_mux
  simd2.alu.src3_mux

  simd3.alu.valu
  simd3.alu.src_shift_reg
  simd3.alu.dest_shift_reg
  simd3.alu.src1_mux
  simd3.alu.src2_mux
  simd3.alu.src3_mux

  simf0.alu.valu
  simf0.alu.src_shift_reg
  simf0.alu.dest_shift_reg
  simf0.alu.src1_mux
  simf0.alu.src2_mux
  simf0.alu.src3_mux

  simf1.alu.valu
  simf1.alu.src_shift_reg
  simf1.alu.dest_shift_reg
  simf1.alu.src1_mux
  simf1.alu.src2_mux
  simf1.alu.src3_mux

  simf2.alu.valu
  simf2.alu.src_shift_reg
  simf2.alu.dest_shift_reg
  simf2.alu.src1_mux
  simf2.alu.src2_mux
  simf2.alu.src3_mux

  simf3.alu.valu
  simf3.alu.src_shift_reg
  simf3.alu.dest_shift_reg
  simf3.alu.src1_mux
  simf3.alu.src2_mux
  simf3.alu.src3_mux
}

analyze -format sverilog -vcs "-f filelist.f"
analyze -format sverilog -vcs "cu_props.sv"

elaborate compute_unit -sva

create_clock clk -period 10
create_reset rst -sense high

report_fv -list

check_fv