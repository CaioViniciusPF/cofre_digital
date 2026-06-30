// contador_tentativas.sv
// Conta tentativas invalidas. Emite 'estourou' quando atinge MAX_TENT.
// 'limpar' zera o contador (acesso valido ou fim do bloqueio).

import cofre_pkg::*;

module contador_tentativas (
  input  logic clk,
  input  logic rst,        // reset assincrono
  input  logic incrementar, // pulso: tentativa invalida
  input  logic limpar,      // pulso: zera contador
  output logic [$clog2(MAX_TENT+1)-1:0] tentativas,
  output logic estourou,    // 1 = atingiu MAX_TENT
  output logic ultima_tent  // 1 = a proxima tentativa invalida atinge o limite
);

  always_ff @(posedge clk or posedge rst) begin
    if (rst)
      tentativas <= '0;
    else if (limpar)
      tentativas <= '0;
    else if (incrementar && tentativas < MAX_TENT)
      tentativas <= tentativas + 1'b1;
  end

  assign estourou    = (tentativas >= MAX_TENT);
  // A tentativa atual eh a ultima permitida quando o contador esta
  // em MAX_TENT-1 (este erro fara o total atingir MAX_TENT).
  assign ultima_tent = (tentativas == MAX_TENT-1);

endmodule : contador_tentativas
