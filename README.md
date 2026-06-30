# Projeto Final - Cofre Digital Programável

**Disciplina:** Sistemas Digitais (SystemVerilog, Xcelium e Genus)
**Tema:** Projeto 3 - Cofre Digital Programável
**Equipe:** Caio Vinícius Pessoa Freires e Victor Guedes Alves Teixeira

---

## 1. Descrição

Sistema digital de um cofre eletrônico com senha programável, implementado em
SystemVerilog com arquitetura modular. O cofre permite cadastrar uma senha,
validar acesso, alterar a senha (com o cofre aberto) e se bloqueia
temporariamente após um número configurável de tentativas inválidas.

### Requisitos funcionais atendidos
- **Cadastro de senha** - estado `S_CADASTRO` grava a senha inicial.
- **Alteração de senha** - estado `S_ALTERA`, acessível apenas com o cofre aberto.
- **Validação de acesso** - `comparador` + estado `S_VALIDA`.
- **Bloqueio após tentativas inválidas** - `contador_tentativas` + `temporizador` + estado `S_BLOQUEIO`.

---

## 2. Estrutura de Arquivos

```
cofre/
├── README.md
├── cofre_fsm.png                  # diagrama de estados da FSM
│
├── rtl/                           # código RTL (SystemVerilog)
│   ├── cofre_pkg.sv               # tipos, estados e parâmetros
│   ├── registrador_senha.sv       # armazena a senha
│   ├── comparador.sv              # compara senha digitada x armazenada
│   ├── contador_tentativas.sv     # conta tentativas e sinaliza limite
│   ├── temporizador.sv            # temporiza o bloqueio
│   ├── cofre_controller.sv        # FSM principal (3 blocos)
│   └── cofre_top.sv               # top-level: interliga os módulos
│
├── tb/
│   └── tb_cofre_top.sv            # testbench RTL autochecking
│
├── sim/                           # scripts de simulação (Xcelium)
│   ├── run_xcelium.sh             # compila e simula o RTL
│   └── run_xcelium_posSint.sh     # simulação pós-síntese (netlist)
│
└── syn/                           # síntese (Genus)
    ├── syn_genus.tcl              # script TCL de síntese
    └── reports/                   # relatórios gerados (área, potência, timing)
```

---

## 3. Arquitetura (módulos)

| Módulo | Função |
|--------|--------|
| `cofre_pkg` | Define `estado_t`, `operacao_t` e parâmetros (tamanho da senha, MAX_TENT, T_BLOQUEIO). |
| `registrador_senha` | Guarda a senha cadastrada; grava nova ao receber `carregar`. |
| `comparador` | Combinacional: `senha_ok = (digitada == armazenada)`. |
| `contador_tentativas` | Conta erros; sinaliza `ultima_tent` e `estourou`. |
| `temporizador` | Conta `T_BLOQUEIO` ciclos e emite `fim`. |
| `cofre_controller` | FSM Moore de 3 blocos (estado, próximo estado, saídas). |
| `cofre_top` | Top-level que instancia e conecta tudo. |

A FSM usa o **modelo de três blocos** exigido:
- `always_ff` → registrador de estado (reset assíncrono).
- `always_comb` → lógica de próximo estado.
- `always_comb` → lógica de saídas.

---

## 4. Como Simular (RTL — Xcelium)

No servidor, dentro da pasta `sim/`:

```bash
cd sim
chmod +x run_xcelium.sh

# Modo batch (autochecking, imprime OK/FALHA):
./run_xcelium.sh

# Modo gráfico (abre o SimVision para capturar as ondas):
./run_xcelium.sh gui
```

O testbench é **autochecking**: ele imprime `[OK]`/`[FALHA]` para cada
verificação e um resumo final com a contagem de erros.

### Cenários cobertos pelo testbench
1. Cadastro da senha inicial.
2. Acesso válido (abre o cofre).
3. Fechamento do cofre.
4. Acesso inválido (não abre, incrementa contador).
5. Bloqueio após `MAX_TENT` tentativas.
6. Fim do bloqueio (volta a IDLE, zera contador).
7. Acesso válido após o bloqueio.
8. Alteração de senha e validação da nova senha.
9. Caso de borda: senha antiga não abre mais após alteração.

---

## 5. Como Sintetizar (Genus)

Antes de rodar, ajuste no `syn/syn_genus.tcl`:
- `LIB_DIR` e `LIB_NAME` → biblioteca da tecnologia fornecida pelo professor.
- `PERIODO` → período de clock alvo.

```bash
cd syn
genus -batch -files syn_genus.tcl
```

Saídas geradas:
- `cofre_top_netlist.v` → netlist sintetizado.
- `cofre_top.sdc` → restrições.
- `reports/` → área, potência, timing (caminho crítico e Fmax).

---

## 6. Simulação Pós-Síntese

Ajuste o caminho da biblioteca de simulação em `sim/run_xcelium_posSint.sh`
(`LIB_PATH`) e rode:

```bash
cd sim
./run_xcelium_posSint.sh
```

Roda o **mesmo testbench** sobre o netlist, comprovando equivalência RTL × pós-síntese.

---

## 7. Análises Obrigatórias (para o relatório)

Coletar dos relatórios do Genus (`syn/reports/`):

| Análise | Onde encontrar |
|---------|----------------|
| Área total | `area.rpt` / `gates.rpt` |
| Potência dinâmica e estática | `power.rpt` |
| Caminho crítico | `timing.rpt` |
| Clock máximo (Fmax) | `timing.rpt` (Fmax = 1 / (período − slack)) |
| Comparação RTL × Pós-Síntese | comparar resultados dos dois testbenches |

---

## 8. Divisão de Tarefas (2 pessoas)

| Pessoa | Responsabilidades |
|--------|-------------------|
| **Caio Vinícius** | `cofre_controller` (FSM), `cofre_top`, diagrama de estados, parte do testbench (cenários de acesso e bloqueio), síntese no Genus (`syn_genus.tcl`) e coleta de área/potência. |
| **Victor Guedes** | Módulos de apoio (`registrador_senha`, `comparador`, `contador_tentativas`, `temporizador`, `cofre_pkg`), parte do testbench (cadastro, alteração, casos de borda), scripts do Xcelium, simulação pós-síntese e análise de timing/Fmax. |

Ambos participam da escrita do **relatório técnico** e da revisão final.

---

## 9. Parâmetros Configuráveis (`cofre_pkg.sv`)

| Parâmetro | Valor padrão | Significado |
|-----------|--------------|-------------|
| `N_DIGITOS` | 4 | número de dígitos da senha |
| `W_DIGITO` | 4 | bits por dígito |
| `W_SENHA` | 16 | largura total da senha |
| `MAX_TENT` | 3 | tentativas antes de bloquear |
| `T_BLOQUEIO` | 20 | ciclos de bloqueio |
