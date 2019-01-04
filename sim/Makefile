TBENCHSRC	= ece564_project_tb_top.v
SRCDIR		= ../src
SVERILOGSRC	= $(wildcard ./*.sv)
VERILOGTOP	= tb_top

# Mentor Graphics QuestaSim/ModelSim
sim:	
	vlib work
	vlog $(SRCDIR)/MyDesign.v
	vlog $(SRCDIR)/read_in_message.v
	vlog $(SRCDIR)/controller.v
	vlog $(SRCDIR)/w_generator.v
	vlog $(SRCDIR)/compute_hash.v
	vlog -sv $(SRCDIR)/sram.v
	vlog -sv $(TBENCHSRC)
	vopt $(VERILOGTOP) -o $(VERILOGTOP)_opt
	vsim $(VERILOGTOP)_opt -c -do "run -all" 

gui:
	vlib work
	vlog $(SRCDIR)/MyDesign.v
	vlog $(SRCDIR)/read_in_message.v
	vlog $(SRCDIR)/controller.v
	vlog $(SRCDIR)/w_generator.v
	vlog $(SRCDIR)/compute_hash.v
	vlog -sv $(SRCDIR)/sram.v
	vlog -sv $(TBENCHSRC)
	vsim -novopt $(VERILOGTOP)

clean:
	-rm -rf work
	-rm -rf mti_lib
	-rm -f ram.bin
	-rm -f *.elf
	-rm -f *.o
	-rm -f transcript
	-rm -f vsim.wlf


