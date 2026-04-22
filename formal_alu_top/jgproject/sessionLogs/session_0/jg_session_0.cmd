# ----------------------------------------
# Jasper Version Info
# tool      : Jasper 2023.09
# platform  : Linux 4.18.0-553.104.1.el8_10.x86_64
# version   : 2023.09 FCS 64 bits
# build date: 2023.09.27 19:40:18 UTC
# ----------------------------------------
# started   : 2026-04-17 14:02:12 EDT
# hostname  : net1580.(none)
# pid       : 325980
# arguments : '-label' 'session_0' '-console' '//127.0.0.1:40273' '-style' 'windows' '-data' 'AAABDniclY/RCgFBGIW/IbfyHIqklLQXbtyRUC5tYrfUtCuzUm54VG8yTr+2uHT+5pzTzOlMvwOSR4wRQ/Mu6jBnwZqZeMlWCjtGDBkzYIrnxIGMgiDuywfxVZpLM47ykz/zBvf6KInjG271/FFo1cE60tBpc1FToc5K3V43XXrs5TwlN1J7DeKzplS6st9TbbmxljfwYiVa' '-proj' '/home/net/ga100270/AMD/MIAOW_GPU/formal/jgproject/sessionLogs/session_0' '-init' '-hidden' '/home/net/ga100270/AMD/MIAOW_GPU/formal/jgproject/.tmp/.initCmds.tcl' 'run.tcl'
clear -all
analyze -sv12 -f filelist.f
elaborate -top alu
clock clk
reset rst
prove -all
