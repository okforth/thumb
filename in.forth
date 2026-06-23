jump

( -- DICTIONARY -- )

: drop drop ;
: dup dup ;
: swap swap ;
: over over ;
: tuck swap over ;
: ?dup dup if dup then ;
: nip push drop pop ;
: rot push swap pop swap ;
: nrot swap push swap pop ;
: 2drop drop drop ;
: 2dup over over ;

: = ( a b -- f )
  - -1 swap if not then
;

: digit ( n -- )
  10 /
  dup if digit else drop then
  '0' + 0 sys
;

then

100 digit 10 0 sys


-1 sys
