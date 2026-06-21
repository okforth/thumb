default: asm.tcl
	./asm.tcl
	hexdump -C out.bin
	gcc vm.c -o vm
	./vm
	hexdump -C out.bin

clean:
	rm vm out.bin
