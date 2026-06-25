//==============================================================================
// cofre_controller.sv
// FSM principal (Moore) do Cofre Digital. Modelo de tres blocos:
//   - always_ff  : registrador de estado
//   - always_comb: logica de proximo estado
//   - always_comb: logica de saidas
//==============================================================================
import cofre_pkg::*;

module cofre_controller (
  input  logic       clk,
  input  logic       rst,

  // Interface de usuario
  input  operacao_t  op,          // operacao solicitada
  input  logic       confirmar,   // pulso: confirma a senha digitada
  input  logic       senha_ok,    // do comparador
  input  logic       cadastrada,  // do registrador (ja existe senha?)
  input  logic       ultima_tent, // 1 = esta tentativa atinge o limite
  input  logic       fim_bloqueio,// do temporizador

  // Controle dos submodulos
  output logic       carregar_senha,  // grava nova senha
  output logic       inc_tentativa,   // incrementa contador
  output logic       limpa_tentativa, // zera contador
  output logic       inicia_timer,    // dispara temporizador

  // Saidas/estado
  output estado_t    estado_atual,
  output logic       cofre_aberto,    // 1 = destrancado
  output logic       bloqueado,       // 1 = em bloqueio
  output logic       alarme           // 1 = tentativa invalida sinalizada
);

  estado_t estado, prox_estado;

  // ---------------------------------------------------------------------------
  // Bloco 1: registrador de estado (sequencial)
  // ---------------------------------------------------------------------------
  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      estado <= S_RESET;
    else
      estado <= prox_estado;
  end

  // ---------------------------------------------------------------------------
  // Bloco 2: logica de proximo estado (combinacional)
  // ---------------------------------------------------------------------------
  always_comb begin
    prox_estado = estado; // default: mantem

    unique case (estado)
      S_RESET: begin
        // Apos reset, vai cadastrar a senha inicial
        prox_estado = S_CADASTRO;
      end

      S_CADASTRO: begin
        // Aguarda confirmacao do cadastro da senha
        if (confirmar)
          prox_estado = S_IDLE;
      end

      S_IDLE: begin
        // Cofre trancado. Aguarda operacao do usuario.
        if (op == OP_ABRIR && confirmar)
          prox_estado = S_VALIDA;
      end

      S_VALIDA: begin
        // Avalia a senha digitada
        if (senha_ok)
          prox_estado = S_ABERTO;
        else if (ultima_tent)
          prox_estado = S_BLOQUEIO;
        else
          prox_estado = S_IDLE; // tentativa errada, volta e aguarda
      end

      S_ABERTO: begin
        // Cofre aberto: pode fechar ou alterar a senha
        if (op == OP_FECHAR)
          prox_estado = S_IDLE;
        else if (op == OP_ALTERAR && confirmar)
          prox_estado = S_ALTERA;
      end

      S_ALTERA: begin
        // Grava a nova senha e volta para o estado aberto
        if (confirmar)
          prox_estado = S_ABERTO;
      end

      S_BLOQUEIO: begin
        // Permanece bloqueado ate o temporizador terminar
        if (fim_bloqueio)
          prox_estado = S_IDLE;
      end

      default: prox_estado = S_RESET;
    endcase
  end

  // ---------------------------------------------------------------------------
  // Bloco 3: logica de saidas (combinacional, Moore + acoes de transicao)
  // ---------------------------------------------------------------------------
  always_comb begin
    // Defaults
    carregar_senha  = 1'b0;
    inc_tentativa   = 1'b0;
    limpa_tentativa = 1'b0;
    inicia_timer    = 1'b0;
    cofre_aberto    = 1'b0;
    bloqueado       = 1'b0;
    alarme          = 1'b0;

    unique case (estado)
      S_CADASTRO: begin
        // Grava a senha inicial ao confirmar
        if (confirmar)
          carregar_senha = 1'b1;
      end

      S_VALIDA: begin
        if (senha_ok) begin
          limpa_tentativa = 1'b1; // acesso valido zera tentativas
        end
        else begin
          inc_tentativa = 1'b1;   // tentativa errada
          alarme        = 1'b1;
          if (ultima_tent)
            inicia_timer = 1'b1;  // dispara bloqueio
        end
      end

      S_ABERTO: begin
        cofre_aberto = 1'b1;
      end

      S_ALTERA: begin
        cofre_aberto = 1'b1; // continua aberto durante alteracao
        if (confirmar)
          carregar_senha = 1'b1; // grava a nova senha
      end

      S_BLOQUEIO: begin
        bloqueado = 1'b1;
        if (fim_bloqueio)
          limpa_tentativa = 1'b1; // ao sair do bloqueio, zera contador
      end

      default: ; // S_RESET, S_IDLE: saidas em default
    endcase
  end

  assign estado_atual = estado;

endmodule : cofre_controller
