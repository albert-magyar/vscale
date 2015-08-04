include Makefrag

V_SRC_DIR = src/main/verilog

V_TEST_DIR = src/test/verilog

CXX_TEST_DIR = src/test/cxx

SIM_DIR = sim

MEM_DIR = src/test/inputs

OUT_DIR = output

VERILATOR = verilator

VERILATOR_OPTS = -Wall -Wno-WIDTH -Wno-UNUSED --cc \
	+incdir+$(V_SRC_DIR) \
	--Mdir $(SIM_DIR) \
	-Wno-fatal

VERILATOR_MAKE_OPTS = OPT_FAST="-O3"

VCS = vcs -full64

VCS_OPTS = -PP -notice -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -quiet \
	+define+DEBUG -debug_pp \
	+incdir+$(V_SRC_DIR) -Mdirectory=$(SIM_DIR)/csrc \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-CC "-std=c++11" \

SIMV_OPTS = -k $(OUT_DIR)/ucli.key +max-cycles=1000000 -q

VCS_BASIC_TB = $(V_TEST_DIR)/vscale_basic_tb.v

VCS_HEX_TB = $(V_TEST_DIR)/vscale_hex_tb.v

VERILATOR_CPP_TB = $(CXX_TEST_DIR)/vscale_benchmark.cpp

VERILATOR_TOP = $(V_TEST_DIR)/vscale_benchmark_top.v

VERILATOR_ZSCALE_CPP_TB = $(CXX_TEST_DIR)/zscale_benchmark.cpp

VERILATOR_ZSCALE_TOP = $(V_TEST_DIR)/zscale_benchmark_top.v

SRCS = $(addprefix $(V_SRC_DIR)/, \
vscale_top.v \
vscale_PC_mux.v \
vscale_ctrl.v \
vscale_regfile.v \
vscale_hasti_bridge.v \
vscale_src_a_mux.v \
vscale_alu.v \
vscale_src_b_mux.v \
vscale_core.v \
vscale_hasti_sram.v \
vscale_hasti_wrapper.v \
vscale_csr_file.v \
vscale_imm_gen.v \
)

HDRS = $(addprefix $(V_SRC_DIR)/, \
vscale_ctrl_constants.vh \
rv32_opcodes.vh \
vscale_alu_ops.vh \
vscale_hasti_constants.vh \
vscale_csr_addr_map.vh \
)

TEST_VPD_FILES = $(addprefix $(OUT_DIR)/,$(addsuffix .vpd,$(RV32_TESTS)))

vcs-sim: $(SIM_DIR)/simv $(SIM_DIR)/simv-basic

run-asm-tests: $(TEST_VPD_FILES)

verilator-sim: $(SIM_DIR)/Vvscale_benchmark_top $(SIM_DIR)/Vvscale_benchmark_top

$(OUT_DIR)/%.vpd: $(MEM_DIR)/%.hex $(SIM_DIR)/simv
	$(SIM_DIR)/simv $(SIMV_OPTS) +max_cycles=$(MAX_CYCLES) +loadmem=$< +vpdfile=$@ && [ $$PIPESTATUS -eq 0 ]

$(SIM_DIR)/simv: $(VCS_HEX_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_HEX_TB) $(SRCS)

$(OUT_DIR)/vscale-basic.vpd: $(SIM_DIR)/simv-basic $(MEM_DIR)/vscale_simple_test.bin
	$(SIM_DIR)/simv-basic $(SIMV_OPTS) +loadmem=$(MEM_DIR)/vscale_simple_test.bin +vpdfile=$@

$(SIM_DIR)/simv-basic: $(VCS_BASIC_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_BASIC_TB) $(SRCS)

$(SIM_DIR)/Vvscale_benchmark_top: $(VERILATOR_TOP) $(SRCS) $(HDRS) $(VERILATOR_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SRCS) --exe ../$(VERILATOR_CPP_TB)
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vvscale_benchmark_top.mk Vvscale_benchmark_top__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vvscale_benchmark_top.mk Vvscale_benchmark_top

$(SIM_DIR)/Vzscale_benchmark_top: $(VERILATOR_ZSCALE_TOP) $(SRCS) $(HDRS) $(VERILATOR_ZSCALE_CPP_TB)
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_ZSCALE_TOP) \
	$(V_TEST_DIR)/zscale_top.v \
	$(V_TEST_DIR)/ZscaleTop.ZscaleConfig.v \
	$(SRCS) --exe ../$(VERILATOR_ZSCALE_CPP_TB) \
	--top-module zscale_benchmark_top \
	-DSYNTHESIS
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vzscale_benchmark_top.mk Vzscale_benchmark_top__ALL.a
	cd sim; make $(VERILATOR_MAKE_OPTS) -f Vzscale_benchmark_top.mk Vzscale_benchmark_top

clean:
	rm -rf $(SIM_DIR)/*

.PHONY: clean run-asm-tests
