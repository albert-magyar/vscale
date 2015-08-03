V_SRC_DIR = src/main/verilog

V_TEST_DIR = src/test/verilog

CXX_TEST_DIR = src/main/cxx

SIM_DIR = sim

MEM_DIR = src/test/inputs

OUT_DIR = output

VERILATOR = verilator

VERILATOR_OPTS = -Wall -Wno-WIDTH -Wno-UNUSED --cc

VCS = vcs -full64

VCS_OPTS = -PP -notice -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -quiet \
	+define+DEBUG -debug_pp -noIncrComp \
	+incdir+$(V_SRC_DIR) -Mdirectory=$(SIM_DIR)/csrc \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-CC "-std=c++11" \

SIMV_OPTS = -k $(OUT_DIR)/ucli.key

VCS_BASIC_TB = $(V_TEST_DIR)/vscale_basic_tb.v

VCS_HEX_TB = $(V_TEST_DIR)/vscale_hex_tb.v

VERILATOR_CPP_TB = $(CXX_TEST_DIR)/vscale_main.cpp

VERILATOR_TOP = $(V_TEST_DIR)/vscale_verilator_top.v

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

default: $(SIM_DIR)/simv $(SIM_DIR)/simv-basic

$(SIM_DIR)/simv: $(VCS_HEX_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_HEX_TB) $(SRCS)

$(OUT_DIR)/vscale-basic.vpd: $(SIM_DIR)/simv-basic $(MEM_DIR)/vscale_simple_test.bin
	$(SIM_DIR)/simv-basic $(SIMV_OPTS) +loadmem=$(MEM_DIR)/vscale_simple_test.bin +vpdfile=$@

$(SIM_DIR)/simv-basic: $(VCS_BASIC_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_BASIC_TB) $(SRCS)

compile-verilator:
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SRCS) --exe $(VERILATOR_CPP_TB)
	cd obj_dir && make -f Vvscale_verilator_top.mk Vvscale_verilator_top

clean:
	rm -rf $(SIM_DIR)/*

.PHONY: clean compile-verilator
