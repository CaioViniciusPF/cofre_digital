# syn_genus.tcl
# Sintese logica do Cofre Digital no Cadence Genus
# Uso:
#   cd syn
#   genus -files syn_genus.tcl

# Diretório onde o script está sendo executado
set LOCAL_DIR [exec pwd]

# Como o script roda dentro de syn/, o projeto está um nível acima
set PROJ_DIR [file normalize "$LOCAL_DIR/.."]

# Caminhos do projeto
set RTL_PATH "$PROJ_DIR/rtl"
set LIB_PATH "$PROJ_DIR/library"

# Biblioteca de timing
set LIBRARY gscl45nm.lib

# Top-level
set DESIGN cofre_top

# Data/hora para criar pastas únicas
set DATE [clock format [clock seconds] -format "%b%d-%H-%M-%S"]

# Pastas de saída
set OUT_DIR "$PROJ_DIR/outputs/outputs_$DATE"
set REP_DIR "$PROJ_DIR/reports/reports_$DATE"

file mkdir $OUT_DIR
file mkdir $REP_DIR

puts "===================================="
puts "Rodando sintese do design: $DESIGN"
puts "Biblioteca: $LIB_PATH/$LIBRARY"
puts "===================================="

#==============================================================================
# 1. Leitura da biblioteca e dos arquivos RTL
#==============================================================================

read_lib "$LIB_PATH/$LIBRARY"

read_hdl -sv [list \
    "$RTL_PATH/cofre_pkg.sv" \
    "$RTL_PATH/registrador_senha.sv" \
    "$RTL_PATH/comparador.sv" \
    "$RTL_PATH/contador_tentativas.sv" \
    "$RTL_PATH/temporizador.sv" \
    "$RTL_PATH/cofre_controller.sv" \
    "$RTL_PATH/cofre_top.sv" \
]

#==============================================================================
# 2. Elaboracao
#==============================================================================

elaborate $DESIGN
current_design $DESIGN

check_design -unresolved

#==============================================================================
# 3. Constraints de timing
#==============================================================================

# Clock de 10 ns = 100 MHz
create_clock -name clk -period 10 [get_ports clk]

# Reset assíncrono fora da análise principal de timing
set_false_path -from [get_ports rst]

# Atrasos de entrada, removendo clock e reset
set_input_delay 1 -clock clk \
    [remove_from_collection [all_inputs] [get_ports {clk rst}]]

# Atraso requerido nas saídas
set_output_delay 1 -clock clk [all_outputs]

#==============================================================================
# 4. Sintese
#==============================================================================

syn_gen
syn_map
syn_opt

#==============================================================================
# 5. Relatorios
#==============================================================================

report area > "$REP_DIR/${DESIGN}_area.rpt"
report power > "$REP_DIR/${DESIGN}_power.rpt"
report gates > "$REP_DIR/${DESIGN}_gates.rpt"
report timing -max_paths 10 > "$REP_DIR/${DESIGN}_timing_10paths.rpt"

#==============================================================================
# 6. Arquivos de saida
#==============================================================================

write_hdl > "$OUT_DIR/${DESIGN}_netlist.v"
write_sdc > "$OUT_DIR/${DESIGN}.sdc"

puts "===================================="
puts "Sintese finalizada"
puts "Netlist: $OUT_DIR/${DESIGN}_netlist.v"
puts "Relatorios: $REP_DIR"
puts "===================================="

exit
