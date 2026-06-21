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

proc write_byte {fh pos value} {
	seek $fh $pos start ;# set position in file
	puts -nonewline $fh [binary format c $value]
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

# set pos [tell $out] ;# fetch current position in file
# puts -nonewline $out [binary format "a$pad" ""] ;# pad file and encode immediate value

set pos 0 ;# opcode position
set count 0 ;# dwords count

set stack {} ;# address stack
set fstack 0 ;# flag stack

proc push {_stack value} {
	upvar 1 $_stack stack
	lappend stack $value
}

proc pop {_stack} {
	upvar 1 $_stack stack
	if {[llength $stack] == 0} {
		return -code error "${::RED}Address stack underflow!${::RESET}"
	}
	set value [lindex $stack end]
	set stack [lrange $stack 0 end-1]
	return $value
}

set i 0
set total_words [llength $words]

while {$i < $total_words} {
	set word [lindex $words $i]
	# update position to skip literals/addresses filled
	if {[dword_offset $pos] == 0} {
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
	}
	# number literals
	if {[string is integer -strict $word]} {
		write_byte $out $pos [scan_opcode $map lit]
		incr pos
		set dpos [expr $pos + [dword_offset $pos]]
		set temp $count
		incr count
		while {$temp > 0} {
			incr dpos 4
			incr temp -1
		}
		write_dword $out $dpos $word
	# if conditionals
	} elseif {$word eq "if" || $word eq "-if"} {
		write_byte $out $pos [scan_opcode $map $word]
		incr pos
		set dpos [expr $pos + [dword_offset $pos]]
		set temp $count
		incr count
		while {$temp > 0} {
			incr dpos 4
			incr temp -1
		}
		push stack $dpos
	# then
	} elseif {$word eq "then"} {
		incr pos [dword_offset $pos]
		while {$count > 0} {
			incr pos 4
			incr count -1
		}
		set addr [pop stack]
		write_dword $out $addr $pos
	# remaining words
	} elseif {[dict exists $map $word]} {
		write_byte $out $pos [scan_opcode $map $word]
		incr pos
	} elseif {$word eq "align"} {
		incr pos [dword_offset $pos]
	} elseif {$word eq ",\""} {
		incr i
		set fill {}
		while {true} {
			set word [lindex $words $i]
			set last [string index $word end]
			if {$last eq "\""} {
				lappend fill [string range $word 0 end-1]
				set len [string length $fill]
				write_string $out $pos $fill
				incr pos $len
				break
			}
			lappend fill $word
			incr i
		}
	} elseif {$word eq ",'"} {
		incr i
		while {true} {
			set word [lindex $words $i]
			set last [string index $word end]
			if {$last eq "'"} {
				set word [string range $word 0 end-1]
				if {[string is integer -strict $word]} {
					write_byte $out $pos $word
					incr pos
					break
				} else {
					error "${RED}Compiler error: >>>$word<<< not a number!${RESET}"
				}
			}
			if {[string is integer -strict $word]} {
				write_byte $out $pos $word
				incr pos
			} else {
				error "${RED}Compiler error: >>>$word<<< not a number!${RESET}"
			}
			incr i
		}
	} elseif {$word eq "def"} {
		incr i
		set word [lindex $words $i]
		set last [string index $word end]
		set len [string length $word]
		incr pos [dword_offset [expr $pos + $len + 1]]
		write_string $out $pos $word
		incr pos $len
		write_byte $out $pos $len
		incr pos
		write_dword $out $pos [pop fstack]
		incr pos 4
		push fstack $pos
	} else {
		error "${RED}Compiler error: >>>$word<<< not found!/${RESET}"
	}
	incr i
}

close $out
