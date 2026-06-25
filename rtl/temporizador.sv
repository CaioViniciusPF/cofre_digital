//==============================================================================
// temporizador.sv
// Conta T_BLOQUEIO ciclos quando 'iniciar' é ativado. Emite 'fim' ao terminar.
//==============================================================================
import cofre_pkg::*;

module temporizador (
  input  logic clk,
  input  logic rst,     // reset assincrono
  input  logic iniciar, // pulso: comeca a contagem
  output logic fim      // 1 = contagem concluida
);

  localparam int W_CNT = $clog2(T_BLOQUEIO+1);
  logic [W_CNT-1:0] cnt;
  logic             ativo;

  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      cnt   <= '0;
      ativo <= 1'b0;
    end
    else if (iniciar) begin
      cnt   <= '0;
      ativo <= 1'b1;
    end
    else if (ativo) begin
      if (cnt == T_BLOQUEIO-1) begin
        ativo <= 1'b0;
        cnt   <= '0;
      end
      else begin
        cnt <= cnt + 1'b1;
      end
    end
  end

  // 'fim' pulsa quando o ultimo ciclo da contagem é atingido
  assign fim = ativo && (cnt == T_BLOQUEIO-1);

endmodule : temporizador
