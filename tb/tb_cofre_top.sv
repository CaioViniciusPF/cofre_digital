//==============================================================================
// tb_cofre_top.sv
// Testbench RTL autochecking do Cofre Digital Programavel.
// Verifica: cadastro, acesso valido, acesso invalido, bloqueio apos
// MAX_TENT tentativas, fim do bloqueio, alteracao de senha e casos de borda.
//==============================================================================
import cofre_pkg::*;

module tb_cofre_top;

  // Sinais
  logic              clk;
  logic              rst;
  logic [W_SENHA-1:0] senha_in;
  operacao_t         op;
  logic              confirmar;

  estado_t           estado;
  logic              cofre_aberto;
  logic              bloqueado;
  logic              alarme;
  logic [$clog2(MAX_TENT+1)-1:0] tentativas;

  // Contadores de verificacao
  int erros = 0;
  int checks = 0;

  // Senhas usadas no teste
  localparam logic [W_SENHA-1:0] SENHA1 = 16'h1234;
  localparam logic [W_SENHA-1:0] SENHA2 = 16'hABCD;
  localparam logic [W_SENHA-1:0] ERRADA = 16'h0000;

  // DUT
  cofre_top dut (
    .clk          (clk),
    .rst          (rst),
    .senha_in     (senha_in),
    .op           (op),
    .confirmar    (confirmar),
    .estado       (estado),
    .cofre_aberto (cofre_aberto),
    .bloqueado    (bloqueado),
    .alarme       (alarme),
    .tentativas   (tentativas)
  );

  // Clock 10ns
  initial clk = 0;
  always #5 clk = ~clk;

  // ---------------------------------------------------------------------------
  // Tarefas auxiliares
  // ---------------------------------------------------------------------------

  // Pulso de confirmacao por 1 ciclo
  task automatic pulso_confirmar();
    @(negedge clk);
    confirmar = 1'b1;
    @(negedge clk);
    confirmar = 1'b0;
  endtask

  // Verifica condicao e reporta
  task automatic check(input bit cond, input string msg);
    checks++;
    if (!cond) begin
      erros++;
      $error("[FALHA] %s | estado=%0d aberto=%0b bloq=%0b tent=%0d t=%0t",
             msg, estado, cofre_aberto, bloqueado, tentativas, $time);
    end
    else begin
      $display("[OK]    %s (t=%0t)", msg, $time);
    end
  endtask

  // Tenta abrir com determinada senha
  task automatic tentar_abrir(input logic [W_SENHA-1:0] s);
    @(negedge clk);
    senha_in = s;
    op       = OP_ABRIR;
    pulso_confirmar();
    op = OP_NENHUMA;
    @(negedge clk); // deixa a FSM avancar (S_VALIDA -> destino)
  endtask

  // ---------------------------------------------------------------------------
  // Sequencia principal de teste
  // ---------------------------------------------------------------------------
  initial begin
    // Inicializacao
    rst       = 1'b1;
    senha_in  = '0;
    op        = OP_NENHUMA;
    confirmar = 1'b0;
    repeat (2) @(negedge clk);
    rst = 1'b0;
    @(negedge clk);

    //------------------------------------------------------------------
    // 1) CADASTRO da senha inicial
    //------------------------------------------------------------------
    @(negedge clk);
    check(estado == S_CADASTRO, "Apos reset deve ir para CADASTRO");
    senha_in = SENHA1;
    pulso_confirmar();
    @(negedge clk);
    check(estado == S_IDLE, "Apos cadastro deve ir para IDLE");

    //------------------------------------------------------------------
    // 2) ACESSO VALIDO
    //------------------------------------------------------------------
    tentar_abrir(SENHA1);
    check(estado == S_ABERTO,  "Senha correta deve abrir o cofre");
    check(cofre_aberto == 1'b1,"cofre_aberto deve estar em 1");
    check(tentativas == 0,     "Acesso valido zera tentativas");

    // Fecha o cofre
    @(negedge clk);
    op = OP_FECHAR;
    @(negedge clk);
    op = OP_NENHUMA;
    @(negedge clk);
    check(estado == S_IDLE,     "Apos FECHAR deve voltar para IDLE");
    check(cofre_aberto == 1'b0, "Cofre deve estar fechado");

    //------------------------------------------------------------------
    // 3) ACESSO INVALIDO (1 tentativa) - nao deve abrir
    //------------------------------------------------------------------
    tentar_abrir(ERRADA);
    check(estado == S_IDLE,      "Senha errada nao abre (volta IDLE)");
    check(cofre_aberto == 1'b0,  "Cofre permanece fechado com senha errada");
    check(tentativas == 1,       "Contador deve marcar 1 tentativa");

    //------------------------------------------------------------------
    // 4) BLOQUEIO apos MAX_TENT tentativas invalidas
    //    Ja temos 1 erro; faltam (MAX_TENT-1) para estourar
    //------------------------------------------------------------------
    for (int i = 0; i < MAX_TENT-1; i++) begin
      tentar_abrir(ERRADA);
    end
    check(estado == S_BLOQUEIO, "Apos MAX_TENT erros deve BLOQUEAR");
    check(bloqueado == 1'b1,    "Sinal bloqueado deve estar em 1");

    //------------------------------------------------------------------
    // 5) FIM DO BLOQUEIO - apos T_BLOQUEIO ciclos volta para IDLE
    //------------------------------------------------------------------
    // Espera o temporizador terminar
    wait (estado == S_IDLE);
    check(estado == S_IDLE,     "Apos bloqueio deve voltar para IDLE");
    check(bloqueado == 1'b0,    "Sinal bloqueado deve voltar a 0");
    check(tentativas == 0,      "Fim do bloqueio zera tentativas");

    //------------------------------------------------------------------
    // 6) ACESSO VALIDO novamente apos bloqueio
    //------------------------------------------------------------------
    tentar_abrir(SENHA1);
    check(estado == S_ABERTO,   "Senha correta abre apos bloqueio");

    //------------------------------------------------------------------
    // 7) ALTERACAO de senha (cofre aberto)
    //------------------------------------------------------------------
    @(negedge clk);
    senha_in = SENHA2;
    op       = OP_ALTERAR;
    pulso_confirmar();   // entra em S_ALTERA
    op = OP_NENHUMA;
    senha_in = SENHA2;
    pulso_confirmar();   // confirma a nova senha -> grava
    @(negedge clk);
    check(estado == S_ABERTO,   "Apos alterar senha volta para ABERTO");

    // Fecha
    @(negedge clk);
    op = OP_FECHAR;
    @(negedge clk);
    op = OP_NENHUMA;
    @(negedge clk);

    //------------------------------------------------------------------
    // 8) Acesso com a NOVA senha deve funcionar
    //------------------------------------------------------------------
    tentar_abrir(SENHA2);
    check(estado == S_ABERTO,   "Nova senha deve abrir o cofre");

    // Fecha e testa que a senha antiga nao abre mais
    @(negedge clk); op = OP_FECHAR; @(negedge clk); op = OP_NENHUMA;
    @(negedge clk);
    tentar_abrir(SENHA1);
    check(cofre_aberto == 1'b0,  "Senha antiga NAO deve mais abrir");

    //------------------------------------------------------------------
    // Relatorio final
    //------------------------------------------------------------------
    @(negedge clk);
    $display("==================================================");
    $display("  RESUMO: %0d verificacoes, %0d erros", checks, erros);
    if (erros == 0)
      $display("  RESULTADO: TODOS OS TESTES PASSARAM");
    else
      $display("  RESULTADO: HOUVE FALHAS");
    $display("==================================================");
    $finish;
  end

  // Timeout de seguranca
  initial begin
    #100000;
    $error("TIMEOUT: simulacao nao terminou no tempo esperado");
    $finish;
  end

endmodule : tb_cofre_top
