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
	m*	0x15
	/mod	0x16
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
set out [open "out.bin" w+b]
fconfigure $out -translation binary ;#-encoding binary

# pad output file to 64MiB
set target_size [expr 64 * 1024 * 1024]
seek $out [expr $target_size - 1] start
puts -nonewline $out "\x00"

proc write_byte {fh pos value} {
	seek $fh $pos start ;# set position in file
	puts -nonewline $fh [binary format cu $value]
}

proc write_dword {fh pos value} {
	seek $fh $pos start ;# set position in file
	puts -nonewline $fh [binary format i $value]
}

proc write_string {fh pos str} {
	seek $fh $pos start
	puts -nonewline $fh $str
}

proc dword_offset {pos} {
	return [expr {(4 - ($pos % 4)) % 4}]
}

proc scan_opcode {map word} {
	scan [dict get $map $word] %x value
	return $value
}

proc read_byte {fh pos} {
	seek $fh $pos start ;# set position in file
	binary scan [read $fh 1] cu byte
	return $byte
}

# set pos [tell $out] ;# fetch current position in file
# puts -nonewline $out [binary format "a$pad" ""] ;# pad file and encode immediate value

proc push {stack value} {
	upvar 1 $stack this_stack
	lappend this_stack $value
}

proc pop {stack} {
	upvar 1 $stack this_stack
	if {[llength $this_stack] == 0} {
		return -code error "${::RED}Address stack underflow!${::RESET}"
	}
	set value [lindex $this_stack end]
	set this_stack [lrange $this_stack 0 end-1]
	return $value
}

set pos 0 ;# opcode position
set count 0 ;# dwords count

set addr_stack {} ;# address stack
set dict_stack 0 ;# dictionary stack

set dict_list {} ;# defined terms

set word_index 0
set word_count [llength $words]

while {$word_index < $word_count} {
	# update position to skip literals/addresses filled
	if {[dword_offset $pos] == 0} {
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
	}

	# current word being read
	set word [lindex $words $word_index]
	incr word_index

	# comments
	if {$word eq "("} {
		while {$word_index < $word_count} {
			set word [lindex $words $word_index]
			incr word_index
			if {$word eq ")"} {
				break
			}
		}
		continue
	}

	# ascii literals
	if {[regexp {^'(.){1}'$} $word -> char]} {
		scan $char %c word ;# convert to a number literal
	}

	# number literals: decimal, hexadecimal, etc.
	if {[string is entier -strict $word]} {
		write_byte $out $pos [scan_opcode $map "lit"]
		incr pos
		set dpos [expr $pos + [dword_offset $pos]]
		set skip $count
		incr count
		while {$skip > 0} {
			incr dpos 4
			incr skip -1
		}
		write_dword $out $dpos $word
		continue
	}

	if {$word eq "if" || $word eq "-if" || $word eq "jump"} {
		write_byte $out $pos [scan_opcode $map $word]
		incr pos
		set dpos [expr $pos + [dword_offset $pos]]
		set skip $count
		incr count
		while {$skip > 0} {
			incr dpos 4
			incr skip -1
		}
		push addr_stack $dpos
		continue
	}

	if {$word eq "else"} {
		write_byte $out $pos [scan_opcode $map jump]
		incr pos
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
		set addr [pop addr_stack] ;# retrieve 'if' address from stack
		push addr_stack $pos ;# store 'else' address to stack
		incr pos 4
		write_dword $out $addr [expr $pos - $addr] ;# write to 'if' address
		continue
	}

	if {$word eq "then"} {
		# skip past any compiled code
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
		set addr [pop addr_stack]
		write_dword $out $addr [expr $pos - $addr]
		continue
	} 

	if {$word eq "for"} {
		# store T into R as loop count
		write_byte $out $pos [scan_opcode $map "push"]
		incr pos
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
		push addr_stack $pos
		continue
	}

	if {$word eq "next"} {
		write_byte $out $pos [scan_opcode $map "next"]
		incr pos
		set dpos [expr $pos + [dword_offset $pos]]
		set skip $count
		incr count
		while {$skip > 0} {
			incr dpos 4
			incr skip -1
		}
		set addr [pop addr_stack]
		write_dword $out $dpos [expr $addr - $dpos]
		continue
	}

	# dictionary entry
	if {$word eq ":"} {
		# skip past any compiled code 
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}

		# compile word, len, link
		set word [lindex $words $word_index]
		incr word_index
		set len [string length $word]
		incr pos [dword_offset [expr $len + 3]]
		write_string $out $pos $word		;# name
		incr pos $len
		write_byte $out $pos $len		;# name length
		incr pos 3				;# skip payload length and flags
		write_dword $out $pos [pop dict_stack]	;# link
		incr pos 4
		push dict_stack $pos

		lappend dict_list $word $pos
		continue
	}

	# compile ';' as exit
	if {$word eq ";"} {
		# skip ahead of literals and addresses
		while {$count > 0} {
			incr pos [dword_offset $pos]
			incr pos 4
			incr count -1
		}

		# fetch latest defined word
		set word [lindex [dict keys $dict_list] end]
		set addr [dict get $dict_list $word]	;# addr of payload content
		set len [expr $pos - $addr]		;# length of payload
		incr addr -6				;# addr of payload length
		write_byte $out $addr $len

		# compile exit from word
		write_byte $out $pos [scan_opcode $map exit]
		incr pos
		continue
	}

	# set flag of lastest defined word as inlined
	if {$word eq "inline"} {
		set word [lindex [dict keys $dict_list] end]
		set addr [dict get $dict_list $word]
		incr addr -5 ;# position of flags
		set byte [read_byte $out $addr]
		set byte [expr {$byte ^ 0x40}] ;# flip 7th bit
		write_byte $out $addr $byte
		continue
	}

	# compile when matching opcode
	if {[dict exists $map $word]} {
		write_byte $out $pos [scan_opcode $map $word]
		incr pos
		continue
	}

	# compile defined word
	if {[dict exists $dict_list $word]} {
		set addr [dict get $dict_list $word]
		set flags [read_byte $out [expr {$addr - 5}]]
		set len   [read_byte $out [expr {$addr - 6}]]
		set flag [expr {$flags & 0x40}] ;# filter for inline flag

		# compiled as inlined word
		if {$flag != 0} {
			# 1 byte words
			if {$len == 1} {
				write_byte $out $pos [read_byte $out $addr]
				incr pos
				continue
			}

			# n bytes words: skip any immediates, addresses
			incr pos [dword_offset $pos]
			while {$count > 0} {
				incr pos 4
				incr count -1
			}

			while {$len} {
				set byte [read_byte $out $addr]
				# ignore exit/return for inlined words
				if {$byte == [scan_opcode $map exit]} {
					set byte [scan_opcode $map nop]
				}
				write_byte $out $pos $byte
				incr addr
				incr pos
				incr len -1
			}
			continue
		}

		# compile as call to word
		write_byte $out $pos [scan_opcode $map call]
		incr pos
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
		write_dword $out $pos [expr $addr - $pos]
		incr pos 4
		continue
	}

	error "${RED}Compiler error: >>>$word<<< not found!/${RESET}"
	break
}

close $out
