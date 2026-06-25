#!/bin/bash
#==============================================================================
# run_xcelium_posSint.sh
# Simulacao POS-SINTESE: usa o netlist gerado pelo Genus + a biblioteca da
# tecnologia. Executa o MESMO testbench autochecking do RTL.
#
# Ajuste LIB_PATH para o caminho do .v de simulacao da sua biblioteca
# (ex.: a Nangate45 ou a biblioteca fornecida pelo professor).
#==============================================================================

LIB_PATH=/caminho/para/biblioteca/tecnologia.v   # <-- AJUSTAR

xrun -64bit -sv \
  -timescale 1ns/1ps \
  $LIB_PATH \
  ../syn/cofre_top_netlist.v \
  ../tb/tb_cofre_top.sv \
  -top tb_cofre_top \
  -access +rwc \
  +define+POS_SINTESE
