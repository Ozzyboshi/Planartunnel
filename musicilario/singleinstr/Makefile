all:
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D TUNNEL_SCANLINES=64 -D USE_BPL_SECTION -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./chordbase.s  -o ./chordbase -I/usr/local/amiga/os-include && chmod 777 ./chordbase
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D TUNNEL_SCANLINES=64 -D USE_BPL_SECTION -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./bassone.s  -o ./bassone -I/usr/local/amiga/os-include && chmod 777 ./bassone
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D TUNNEL_SCANLINES=64 -D USE_BPL_SECTION -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./exp-pi.s  -o ./exp-pi -I/usr/local/amiga/os-include && chmod 777 ./exp-pi
