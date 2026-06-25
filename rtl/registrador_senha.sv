//==============================================================================
// registrador_senha.sv
// Armazena a senha cadastrada. Permite escrita (cadastro/alteracao) e leitura.
//==============================================================================
import cofre_pkg::*;

module registrador_senha (
  input  logic              clk,
  input  logic              rst,        // reset assincrono
  input  logic              carregar,   // pulso: grava nova_senha
  input  logic [W_SENHA-1:0] nova_senha,
  output logic [W_SENHA-1:0] senha_atual,
  output logic              cadastrada  // 1 = ja existe senha gravada
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      senha_atual <= '0;
      cadastrada  <= 1'b0;
    end
    else if (carregar) begin
      senha_atual <= nova_senha;
      cadastrada  <= 1'b1;
    end
  end

endmodule : registrador_senha
