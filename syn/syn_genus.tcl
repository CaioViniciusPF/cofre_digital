#==============================================================================
# syn_genus.tcl
# Script de sintese logica do Cofre Digital no Cadence Genus.
#
# Uso:  genus -batch -files syn_genus.tcl
#
# AJUSTES OBRIGATORIOS antes de rodar:
#   - LIB_DIR  : caminho da biblioteca .lib da tecnologia
#   - LIB_NAME : nome do arquivo .lib
#   - PERIODO  : periodo de clock alvo (em ns)
#==============================================================================

#--- 1. Configuracao da biblioteca -------------------------------------------
set LIB_DIR  "/caminho/para/biblioteca"     ;# <-- AJUSTAR
set LIB_NAME "tecnologia_typical.lib"        ;# <-- AJUSTAR

set_db init_lib_search_path $LIB_DIR
set_db library $LIB_NAME

#--- 2. Leitura do RTL --------------------------------------------------------
set RTL_DIR "../rtl"

read_hdl -sv [list \
  $RTL_DIR/cofre_pkg.sv \
  $RTL_DIR/registrador_senha.sv \
  $RTL_DIR/comparador.sv \
  $RTL_DIR/contador_tentativas.sv \
  $RTL_DIR/temporizador.sv \
  $RTL_DIR/cofre_controller.sv \
  $RTL_DIR/cofre_top.sv \
]

#--- 3. Elaboracao ------------------------------------------------------------
elaborate cofre_top
check_design -unresolved

#--- 4. Restricoes de timing --------------------------------------------------
set PERIODO 10.0   ;# <-- AJUSTAR (periodo de clock em ns; 10ns = 100 MHz)

create_clock -name clk -period $PERIODO [get_ports clk]
set_clock_uncertainty [expr 0.05 * $PERIODO] [get_clocks clk]

# Reset tratado como entrada assincrona (nao constrange pelo clock)
set_false_path -from [get_ports rst]

# Margens de I/O (40% do periodo como exemplo)
set_input_delay  [expr 0.4 * $PERIODO] -clock clk [all_inputs]
set_output_delay [expr 0.4 * $PERIODO] -clock clk [all_outputs]

#--- 5. Sintese ---------------------------------------------------------------
set_db syn_generic_effort medium
set_db syn_map_effort     medium
set_db syn_opt_effort     medium

syn_generic
syn_map
syn_opt

#--- 6. Relatorios (analises obrigatorias) ------------------------------------
report_area    > reports/area.rpt
report_power   > reports/power.rpt
report_timing  > reports/timing.rpt
report_timing -unconstrained > reports/timing_unconstrained.rpt

# Resumo de gates e Fmax
report_gates   > reports/gates.rpt

#--- 7. Escrita do netlist e SDC ----------------------------------------------
write_hdl > cofre_top_netlist.v
write_sdc > cofre_top.sdc

puts "================================================="
puts " Sintese concluida."
puts " Netlist: cofre_top_netlist.v"
puts " Relatorios em: reports/"
puts "================================================="

exit
