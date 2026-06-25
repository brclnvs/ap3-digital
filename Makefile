GHDL      = ghdl
STD       = --std=08
GHDL_LIBS = --PREFIX=/usr/lib/ghdl/mcode/vhdl
STOP_TIME = 50us
WORK_DIR  = work

RTL = rtl
TB  = rtl/testbench

# ------------------------------------------------------------------------------
# Fontes RTL comuns às duas alternativas (ordem de dependência)
# ------------------------------------------------------------------------------
COMMON_SRC = \
	$(RTL)/mse_pack.vhdl \
	$(RTL)/signed_subtractor.vhdl \
	$(RTL)/unsigned_register.vhdl \
	$(RTL)/mse_bc.vhdl

# Fontes específicas de cada alternativa + testbench correspondente
SRC_MULT = $(COMMON_SRC) \
	$(RTL)/square_mult.vhdl \
	$(RTL)/mse_bo_mult.vhdl \
	$(RTL)/mse_top_mult.vhdl \
	$(TB)/mse_tb_mult.vhdl

SRC_LUT = $(COMMON_SRC) \
	$(RTL)/square_lut.vhdl \
	$(RTL)/mse_bo_lut.vhdl \
	$(RTL)/mse_top_lut.vhdl \
	$(TB)/mse_tb_lut.vhdl

# ------------------------------------------------------------------------------
# Targets
# ------------------------------------------------------------------------------

.PHONY: all sim_mult sim_lut sim_all clean help

all: sim_all

sim_mult: mse_tb_mult.vcd
sim_lut:  mse_tb_lut.vcd
sim_all:  sim_mult sim_lut

# ------------------------------------------------------------------------------
# Regras de simulação
# ------------------------------------------------------------------------------

$(WORK_DIR):
	@mkdir -p $(WORK_DIR)

mse_tb_mult.vcd: $(SRC_MULT) | $(WORK_DIR)
	@echo ">>> [MULT] Analisando fontes..."
	@$(GHDL) -a $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) $(SRC_MULT)
	@echo ">>> [MULT] Elaborando mse_tb_mult..."
	@$(GHDL) -e $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) mse_tb_mult
	@echo ">>> [MULT] Simulando..."
	@$(GHDL) -r $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) mse_tb_mult \
		--vcd=$@ --stop-time=$(STOP_TIME)
	@echo ">>> [MULT] Pronto. VCD gerado: $@"

mse_tb_lut.vcd: $(SRC_LUT) | $(WORK_DIR)
	@echo ">>> [LUT] Analisando fontes..."
	@$(GHDL) -a $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) $(SRC_LUT)
	@echo ">>> [LUT] Elaborando mse_tb_lut..."
	@$(GHDL) -e $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) mse_tb_lut
	@echo ">>> [LUT] Simulando..."
	@$(GHDL) -r $(STD) $(GHDL_LIBS) --workdir=$(WORK_DIR) mse_tb_lut \
		--vcd=$@ --stop-time=$(STOP_TIME)
	@echo ">>> [LUT] Pronto. VCD gerado: $@"

# ------------------------------------------------------------------------------
# Limpeza
# ------------------------------------------------------------------------------

clean:
	@echo ">>> Removendo artefatos..."
	@rm -f *.vcd *.o *.cf mse_tb_mult mse_tb_lut
	@rm -rf $(WORK_DIR)
	@echo ">>> Pronto."

# ------------------------------------------------------------------------------
# Ajuda
# ------------------------------------------------------------------------------

help:
	@echo "Targets disponíveis:"
	@echo "  make sim_mult   — compila e simula alternativa MULTIPLICADOR"
	@echo "  make sim_lut    — compila e simula alternativa LOOKUP TABLE"
	@echo "  make sim_all    — roda as duas (padrão)"
	@echo "  make clean      — remove todos os artefatos gerados"
