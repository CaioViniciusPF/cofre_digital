//==============================================================================
// cofre_top.sv
// Top-level do Cofre Digital Programavel. Instancia e interconecta:
//   - registrador_senha
//   - comparador
//   - contador_tentativas
//   - temporizador
//   - cofre_controller (FSM)
//==============================================================================
import cofre_pkg::*;

module cofre_top (
  input  logic              clk,
  input  logic              rst,

  // Entradas de usuario
  input  logic [W_SENHA-1:0] senha_in,   // senha digitada / nova senha
  input  operacao_t         op,         // operacao solicitada
  input  logic              confirmar,  // pulso de confirmacao

  // Saidas
  output estado_t           estado,     // estado atual da FSM
  output logic              cofre_aberto,
  output logic              bloqueado,
  output logic              alarme,
  output logic [$clog2(MAX_TENT+1)-1:0] tentativas
);

  // Sinais internos
  logic [W_SENHA-1:0] senha_armazenada;
  logic               cadastrada;
  logic               senha_ok;
  logic               estourou;
  logic               ultima_tent;
  logic               fim_bloqueio;

  logic               carregar_senha;
  logic               inc_tentativa;
  logic               limpa_tentativa;
  logic               inicia_timer;

  // --------------------------------------------------------------------------
  // Registrador de senha
  // --------------------------------------------------------------------------
  registrador_senha u_reg (
    .clk         (clk),
    .rst         (rst),
    .carregar    (carregar_senha),
    .nova_senha  (senha_in),
    .senha_atual (senha_armazenada),
    .cadastrada  (cadastrada)
  );

  // --------------------------------------------------------------------------
  // Comparador
  // --------------------------------------------------------------------------
  comparador u_cmp (
    .senha_digitada   (senha_in),
    .senha_armazenada (senha_armazenada),
    .senha_ok         (senha_ok)
  );

  // --------------------------------------------------------------------------
  // Contador de tentativas
  // --------------------------------------------------------------------------
  contador_tentativas u_cnt (
    .clk         (clk),
    .rst         (rst),
    .incrementar (inc_tentativa),
    .limpar      (limpa_tentativa),
    .tentativas  (tentativas),
    .estourou    (estourou),
    .ultima_tent (ultima_tent)
  );

  // --------------------------------------------------------------------------
  // Temporizador de bloqueio
  // --------------------------------------------------------------------------
  temporizador u_timer (
    .clk     (clk),
    .rst     (rst),
    .iniciar (inicia_timer),
    .fim     (fim_bloqueio)
  );

  // --------------------------------------------------------------------------
  // Controlador (FSM)
  // --------------------------------------------------------------------------
  cofre_controller u_ctrl (
    .clk             (clk),
    .rst             (rst),
    .op              (op),
    .confirmar       (confirmar),
    .senha_ok        (senha_ok),
    .cadastrada      (cadastrada),
    .ultima_tent     (ultima_tent),
    .fim_bloqueio    (fim_bloqueio),
    .carregar_senha  (carregar_senha),
    .inc_tentativa   (inc_tentativa),
    .limpa_tentativa (limpa_tentativa),
    .inicia_timer    (inicia_timer),
    .estado_atual    (estado),
    .cofre_aberto    (cofre_aberto),
    .bloqueado       (bloqueado),
    .alarme          (alarme)
  );

endmodule : cofre_top
