jump

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

: i pop pop dup push swap push ;

: emit ( char -- ) 0 sys ;
: neg ( n -- n+1 ) not 1 + ;

: = ( a b -- f )
  - -1 swap if not then
;

: digit ( n -- ) 10 / dup if digit else drop then '0' + 0 sys ;
: space ( -- ) 32 emit ;
: . ( n -- ) dup -if neg '-' emit then digit space ;

: cr ( -- ) 10 0 sys ;

: end -1 sys ;

then

19 . 12 .
'*' emit space
'.' emit space
19 12 * drop . cr

-1 sys
