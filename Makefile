asm: asmblr.tcl
	./asmblr.tcl
	hexdump -C out.bin

vm: vm.c
	gcc vm.c -o vm
	./vm
