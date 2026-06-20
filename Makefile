default: asm.tcl
	./asm.tcl
	hexdump -C out.bin
	gcc vm.c -o vm
	./vm

clean:
	rm vm out.bin
