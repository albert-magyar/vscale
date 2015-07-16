VCS = vcs -full64

VCS_OPTS = -PP -notice -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -quiet \
	+define+DEBUG -debug_pp -noIncrComp \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-CC "-std=c++11" \

VCS_BASIC_TB = vscale_basic_tb.v

VCS_HEX_TB = vscale_hex_tb.v

VERILATOR = verilator

VERILATOR_OPTS = -Wall -Wno-WIDTH -Wno-UNUSED --cc

VERILATOR_CPP_TB = vscale_main.cpp

VERILATOR_TOP = vscale_verilator_top.v

SRCS = \
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
vscale_imm_gen.v

HDRS = \
vscale_ctrl_constants.vh \
rv32_opcodes.vh \
vscale_alu_ops.vh \
vscale_hasti_constants.vh \
vscale_csr_addr_map.vh

default: simv vscale-basic.vcd

simv: $(VCS_HEX_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_HEX_TB) $(SRCS)

vscale-basic.vcd: vscale-basic.vpd
	vpd2vcd $< $@

vscale-basic.vpd: simv-basic vscale_simple_test.bin
	./simv-basic

simv-basic: $(VCS_BASIC_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) -o $@ $(VCS_BASIC_TB) $(SRCS)

compile-verilator:
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SRCS) --exe $(VERILATOR_CPP_TB)
	cd obj_dir && make -f Vvscale_verilator_top.mk Vvscale_verilator_top

clean:
	rm -rf simv simv-basic obj_dir *.vcd *.vpd *.daidir

.PHONY: clean compile-verilator
