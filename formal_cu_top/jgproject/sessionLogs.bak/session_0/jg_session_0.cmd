# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.09
# platform  : Linux 4.18.0-553.104.1.el8_10.x86_64
# version   : 2023.09 FCS 64 bits
# build date: 2023.09.27 19:40:18 UTC
# ----------------------------------------
# started   : 2026-04-22 18:19:48 EDT
# hostname  : net1580.(none)
# pid       : 3971001
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:43509' '-style' 'windows' '-data' 'AAABDniclY/RCgFBGIW/IbfyHIqklLQXbtyRUC5tYrfUtCuzUm54VG8yTr+2uHT+5pzTzOlMvwOSR4wRQ/Mu6jBnwZqZeMlWCjtGDBkzYIrnxIGMgiDuywfxVZpLM47ykz/zBvf6KInjG271/FFo1cE60tBpc1FToc5K3V43XXrs5TwlN1J7DeKzplS6st9TbbmxljfwYiVa' '-proj' '/home/net/ga100270/AMD/MIAOW_GPU/formal_cu_top/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/net/ga100270/AMD/MIAOW_GPU/formal_cu_top/jgproject/.tmp/.initCmds.tcl' 'run.tcl'
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
