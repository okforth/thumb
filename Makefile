run: asm.tcl vm.c
	./asm.tcl
	gcc vm.c -o machine
	./machine

debug: run
	hexdump -C out.bin

clean:
	rm machine out.bin
