// cofre_pkg.sv
// Pacote com tipos e parametros compartilhados do Cofre Digital Programavel
package cofre_pkg;

  // Largura da senha (numero de digitos)
  parameter int N_DIGITOS  = 4;
  // Largura de cada digito
  parameter int W_DIGITO   = 4;
  // Largura total da senha
  parameter int W_SENHA    = N_DIGITOS * W_DIGITO; // 16 bits

  // Numero maximo de tentativas invalidas antes do bloqueio
  parameter int MAX_TENT   = 3;
  // Ciclos de clock que o cofre permanece bloqueado
  parameter int T_BLOQUEIO = 20;

  // Estados da FSM principal (Moore)
  typedef enum logic [2:0] {
    S_RESET    = 3'd0, // estado inicial apos reset
    S_CADASTRO = 3'd1, // cadastro da senha inicial
    S_IDLE     = 3'd2, // cofre trancado, aguardando operacao
    S_VALIDA   = 3'd3, // validacao da senha digitada
    S_ABERTO   = 3'd4, // cofre destrancado
    S_ALTERA   = 3'd5, // alteracao de senha (exige cofre aberto)
    S_BLOQUEIO = 3'd6  // bloqueio temporario apos exceder tentativas
  } estado_t;

  // Operacoes solicitadas pelo usuario (entrada op[1:0])
  typedef enum logic [1:0] {
    OP_NENHUMA = 2'b00,
    OP_ABRIR   = 2'b01, // validar senha e abrir
    OP_ALTERAR = 2'b10, // alterar senha (cofre deve estar aberto)
    OP_FECHAR  = 2'b11  // fechar o cofre
  } operacao_t;

endpackage : cofre_pkg
