#!/usr/bin/env tclsh

# ANSI escape sequences
set RED "\033\[31m"
set RESET "\033\[0m"

# assembler word map
set map {
	nop	0x00
	jump	0x01
	call	0x02
	exit	0x03
	if	0x04
	-if	0x05
	next	0x06
	lit	0x07
	@	0x08
	!	0x09
	c@	0x0a
	c!	0x0b
	a+	0x0c
	2*	0x0d
	2/	0x0e
	not	0x0f
	and	0x10
	xor	0x11
	or	0x12
	+	0x13
	-	0x14
	*	0x15
	/	0x16
	drop	0x17
	dup	0x18
	over	0x19
	swap	0x1a
	pop	0x1b
	push	0x1c
	a	0x1d
	a!	0x1e
	sys	0x1f
}

# read input file
set in [open "in.forth" r]
set words [read $in]
close $in

# write output binary file
set out [open "out.bin" wb]
fconfigure $out -translation binary -encoding binary

foreach word $words {
	if {[string is integer -strict $word]} {
		# fetch current position in file
		# calculate offset from 32-bit "cell" alignment
		set pos [tell $out]
		set pad [expr {(4 - ($pos % 4)) % 4}]

		# pad file and encode immediate value
		puts -nonewline $out [binary format "a$pad" ""]
		set bytes [binary format i $word]
		puts -nonewline $out $bytes
	} elseif {[dict exists $map $word]} {
		scan [dict get $map $word] %x value
		set byte [binary format c $value]
		puts -nonewline $out $byte
	} else {
		puts "${RED}Compiler error: >>>$word<<< not found!/${RESET}"
		exit
	}
}

close $out
