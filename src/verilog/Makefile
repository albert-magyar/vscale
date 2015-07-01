VCS = vcs -full64

VCS_OPTS = -PP -notice -line +lint=all,noVCDE +v2k -timescale=1ns/10ps -quiet \
	+define+DEBUG -debug_pp \
	+vc+list -CC "-I$(VCS_HOME)/include" \
	-CC "-std=c++11" \

SRCS = \
vscale_top_tb.v \
vscale_pc_mux.v \
vscale_ctrl.v \
vscale_regfile.v \
vscale_hasti_bridge.v \
vscale_src_a_mux.v \
vscale_alu.v \
vscale_src_b_mux.v \
vscale_core.v \
vscale_hasti_sram.v \
vscale_top.v \
vscale_hasti_wrapper.v \
vscale_csr_file.v \
vscale_imm_gen.v

HDRS = \
vscale_ctrl_constants.vh \
rv32_opcodes.vh \
vscale_alu_ops.vh \
vscale_hasti_constants.vh \
vscale_csr_addr_map.vh

simv: $(SRCS) $(HDRS)
	$(VCS) $(VCS_OPTS) $(SRCS)

clean:
	rm -f simv

.PHONY: clean