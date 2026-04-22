clear -all
analyze -sv12 -f filelist.f
analyze -sv12 cu_props.sv
elaborate -top compute_unit
clock clk
reset rst
prove -all