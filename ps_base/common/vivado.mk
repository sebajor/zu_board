###################################################################
# 
# Xilinx Vivado FPGA Makefile
# 
# Copyright (c) 2016 Alex Forencich
# 
###################################################################
# 
# Parameters:
# FPGA_TOP - Top module name
# FPGA_FAMILY - FPGA family (e.g. VirtexUltrascale)
# FPGA_DEVICE - FPGA device (e.g. xcvu095-ffva2104-2-e)
# SYN_FILES - space-separated list of source files
# INC_FILES - space-separated list of include files
# XDC_FILES - space-separated list of timing constraint files
# XCI_FILES - space-separated list of IP XCI files
# 
# Example:
# 
# FPGA_TOP = fpga
# FPGA_FAMILY = VirtexUltrascale
# FPGA_DEVICE = xcvu095-ffva2104-2-e
# SYN_FILES = rtl/fpga.v
# XDC_FILES = fpga.xdc
# XCI_FILES = ip/pcspma.xci
# include ../common/vivado.mk
# 
###################################################################

# phony targets
.PHONY: clean fpga

# prevent make from deleting intermediate files and reports
.PRECIOUS: %.xpr %.bit %.mcs %.prm
.SECONDARY:

CONFIG ?= config.mk
-include ../$(CONFIG)

SYN_FILES_REL = $(patsubst %, ../%, $(SYN_FILES))
INC_FILES_REL = $(patsubst %, ../%, $(INC_FILES))
XCI_FILES_REL = $(patsubst %, ../%, $(XCI_FILES))
IP_TCL_FILES_REL = $(patsubst %, ../%, $(IP_TCL_FILES))

ifdef XDC_FILES
  XDC_FILES_REL = $(patsubst %, ../%, $(XDC_FILES))
else
  XDC_FILES_REL = $(FPGA_TOP).xdc
endif


FPGA_TOP ?= fpga
PROJECT ?= $(FPGA_TOP)
BOARD_PATH ?= /Xilinx/Vivado/2022.1/data/boards

###################################################################
# Main Targets
#
# all: build everything
# clean: remove output files and project files
###################################################################

all: fpga

fpga: $(PROJECT).bit

tmpclean:
	-rm -rf *.log *.jou *.cache *.hbs *.hw *.ip_user_files *.runs *.xpr *.html *.xml *.sim *.srcs *.str .Xil defines.v
	-rm -rf create_project.tcl run_synth.tcl run_impl.tcl generate_bit.tcl

clean: tmpclean
	-rm -rf *.bit program.tcl generate_mcs.tcl *.mcs *.prm flash.tcl

distclean: clean
	-rm -rf rev

###################################################################
# Target implementations
###################################################################

# Vivado project file
$(PROJECT).xpr: Makefile $(XCI_FILES_REL)
	rm -rf defines.v
	touch defines.v
	for x in $(DEFS); do echo '`define' $$x >> defines.v; done
	echo "set_param board.repoPaths [list $(BOARD_PATH)]" > create_project.tcl
	echo "create_project -force -part $(FPGA_PART) $(PROJECT)" >> create_project.tcl
	echo "set_property board_part avnet.com:zuboard_1cg:part0:1.0 [current_project]" >> create_project.tcl
	echo "add_files -fileset sources_1 defines.v" >> create_project.tcl
	for x in $(SYN_FILES_REL); do echo "add_files -fileset sources_1 $$x" >> create_project.tcl; done
	for x in $(XDC_FILES_REL); do echo "add_files -fileset constrs_1 $$x" >> create_project.tcl; done
	for x in $(XCI_FILES_REL); do echo "import_ip $$x" >> create_project.tcl; done
	for x in $(IP_TCL_FILES_REL); do echo "source $$x" >> create_project.tcl; done
	#echo "reset_property board_connections [current_project]" >> create_project.tcl
	echo "exit" >> create_project.tcl
	vivado -nojournal -nolog -mode batch -source create_project.tcl

# synthesis run
$(PROJECT).runs/synth_1/$(PROJECT).dcp: $(PROJECT).xpr $(SYN_FILES_REL) $(INC_FILES_REL) $(XDC_FILES_REL)
	echo "open_project $(PROJECT).xpr" > run_synth.tcl
	echo "reset_run synth_1" >> run_synth.tcl
	echo "launch_runs synth_1" >> run_synth.tcl
	echo "wait_on_run synth_1" >> run_synth.tcl
	echo "exit" >> run_synth.tcl
	vivado -nojournal -nolog -mode batch -source run_synth.tcl

# implementation run
$(PROJECT).runs/impl_1/$(PROJECT)_routed.dcp: $(PROJECT).runs/synth_1/$(PROJECT).dcp
	echo "open_project $(PROJECT).xpr" > run_impl.tcl
	echo "reset_run impl_1" >> run_impl.tcl
	echo "launch_runs impl_1" >> run_impl.tcl
	echo "wait_on_run impl_1" >> run_impl.tcl
	echo "exit" >> run_impl.tcl
	vivado -nojournal -nolog -mode batch -source run_impl.tcl

# bit file
$(PROJECT).bit: $(PROJECT).runs/impl_1/$(PROJECT)_routed.dcp
	echo "open_project $(PROJECT).xpr" > generate_bit.tcl
	echo "open_run impl_1" >> generate_bit.tcl
	echo "set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]" >> generate_bit.tcl
	echo "write_bitstream $(PROJECT).bit" >> generate_bit.tcl
	#to run the line we need to set some parameters, (this could be a dirty trick, dont know...)
	echo "set_property platform.board_id zub1gc [current_project]" >> generate_bit.tcl
	echo "set_property platform.name zub1gc [current_project]" >> generate_bit.tcl
	echo "set_property platform.default_output_type "sd_card" [current_project]" >> generate_bit.tcl
	echo "set_property platform.design_intent.embedded "true" [current_project]" >> generate_bit.tcl
	echo "set_property platform.design_intent.server_managed "false" [current_project]" >> generate_bit.tcl
	echo "set_property platform.design_intent.external_host "false" [current_project]" >> generate_bit.tcl
	echo "set_property platform.design_intent.datacenter "false" [current_project]" >> generate_bit.tcl
	#also it needs the bit file in the run/impl folder >:(
	echo "exec cp $(PROJECT).bit $(PROJECT).runs/impl_1/system_wrapper.bit" >> generate_bit.tcl
	echo "write_hw_platform -fixed -include_bit -force -file $(PROJECT).xsa" >> generate_bit.tcl
	echo "exit" >> generate_bit.tcl
	vivado -nojournal -nolog -mode batch -source generate_bit.tcl
	mkdir -p rev
	EXT=bit; COUNT=100; \
	while [ -e rev/$(PROJECT)_rev$$COUNT.bit ]; \
	do COUNT=$$((COUNT+1)); done; \
	cp -pv $(PROJECT).bit rev/$(PROJECT)_rev$$COUNT.bit; \
	if [ -e $(PROJECT).runs/impl_1/$(PROJECT).ltx ]; then cp -pv $(PROJECT).runs/impl_1/$(PROJECT).ltx rev/$(PROJECT)_rev$$COUNT.ltx; fi
	##copy the hwh
	cp $(PROJECT).gen/sources_1/bd/system/hw_handoff/system.hwh rev/system.hwh
