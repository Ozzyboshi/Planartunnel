all:
		vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D USE_BPL_SECTION -D TUNNEL_SCANLINES=64 -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./test.s  -o ./test -I/usr/local/amiga/os-include && chmod 777 ./test
		vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D USE_BPL_SECTION -D TUNNEL_SCANLINES=64 -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./testnudo.s  -o ./testnudo -I/usr/local/amiga/os-include && chmod 777 ./testnudo

