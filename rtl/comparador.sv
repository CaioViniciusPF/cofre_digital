// comparador.sv
// Compara a senha digitada com a senha armazenada (combinacional).

import cofre_pkg::*;

module comparador (
  input  logic [W_SENHA-1:0] senha_digitada,
  input  logic [W_SENHA-1:0] senha_armazenada,
  output logic              senha_ok
);

  assign senha_ok = (senha_digitada == senha_armazenada);

endmodule : comparador
