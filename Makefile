default: asm.tcl
	./asm.tcl
	hexdump -C out.bin
	gcc vm.c -o machine
	./machine
	hexdump -C out.bin

clean:
	rm machine out.bin
