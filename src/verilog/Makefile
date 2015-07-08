VCS = vcs -full64

VCS_OPTS = -PP -notice -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -quiet \
	+define+DEBUG -debug_pp \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-CC "-std=c++11" \

VCS_TB = vscale_top_tb.v

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

vscale.vcd: vscale.vpd
	vpd2vcd $< $@

vscale.vpd: simv vscale_simple_test.bin
	./simv

simv: $(VCS_TB) $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) $(VCS_TB) $(SRCS)

compile-verilator:
	$(VERILATOR) $(VERILATOR_OPTS) $(VERILATOR_TOP) $(SRCS) --exe $(VERILATOR_CPP_TB)
	cd obj_dir && make -f Vvscale_verilator_top.mk Vvscale_verilator_top

clean:
	rm -rf simv obj_dir

.PHONY: clean compile-verilator
