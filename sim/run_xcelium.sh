#!/bin/bash

# run_xcelium.sh
# Compilacao e simulacao RTL do Cofre Digital no Xcelium.
# Uso:  ./run_xcelium.sh          (modo batch, autochecking)
#       ./run_xcelium.sh gui      (abre o SimVision)


MODO=$1
GUI_FLAG=""

if [ "$MODO" == "gui" ]; then
  GUI_FLAG="+gui"
fi

xrun -64bit -sv \
  -timescale 1ns/1ps \
  ../rtl/cofre_pkg.sv \
  ../rtl/registrador_senha.sv \
  ../rtl/comparador.sv \
  ../rtl/contador_tentativas.sv \
  ../rtl/temporizador.sv \
  ../rtl/cofre_controller.sv \
  ../rtl/cofre_top.sv \
  ../tb/tb_cofre_top.sv \
  -top tb_cofre_top \
  -access +rwc \
  $GUI_FLAG
