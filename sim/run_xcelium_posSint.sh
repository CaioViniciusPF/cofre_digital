#!/bin/bash

# run_xcelium_posSint.sh
# Simulacao POS-SINTESE do Cofre Digital
# Usa a netlist gerada pelo Genus + biblioteca Verilog da tecnologia


echo "========================================"
echo "Simulacao POS-SINTESE com Xcelium"
echo "========================================"

# Biblioteca Verilog da tecnologia
LIB_PATH="../library/gscl45nm.v"

# Pega automaticamente a netlist mais recente gerada pelo Genus
NETLIST=$(ls -t ../outputs/outputs_*/cofre_top_netlist.v 2>/dev/null | head -n 1)

if [ ! -f "$LIB_PATH" ]; then
    echo "ERRO: biblioteca nao encontrada em: $LIB_PATH"
    exit 1
fi

if [ -z "$NETLIST" ]; then
    echo "ERRO: netlist pos-sintese nao encontrada."
    echo "Verifique se existe:"
    echo "../outputs/outputs_*/cofre_top_netlist.v"
    exit 1
fi

echo "Biblioteca: $LIB_PATH"
echo "Netlist:    $NETLIST"
echo "Testbench:  ../tb/tb_cofre_top.sv"
echo "========================================"

xrun -64bit -sv \
  -timescale 1ns/1ps \
  "$LIB_PATH" \
  "$NETLIST" \
  ../tb/tb_cofre_top.sv \
  -top tb_cofre_top \
  -access +rwc \
  +define+POS_SINTESE

echo "========================================"
echo "Fim da simulacao POS-SINTESE"
echo "========================================"
