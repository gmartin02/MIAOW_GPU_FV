clear -all
analyze -sv12 -f filelist.f
elaborate -top alu
clock clk
reset rst
prove -all