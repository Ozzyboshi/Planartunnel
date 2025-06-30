all:
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D TUNNEL_SCANLINES=64 -D USE_BPL_SECTION -D USE_DBLBUF -DMATRIX_STACK_SIZE=0  ./tunnel.s  -o ./tunnel -I/usr/local/amiga/os-include && chmod 777 ./tunnel
	vasmm68k_mot -kick1hunks -devpac -Fhunkexe -quiet -esc  -m68000 -D TUNNEL_SCANLINES=38 -D USE_DBLBUF -DMATRIX_STACK_SIZE=0 -D COLORDEBUG  ./tunnel.s  -o ./tunneldebug -I/usr/local/amiga/os-include && chmod 777 ./tunneldebug

	./comprimi.sh

adf:
	exe2adf-linux64bit -i tunnelcompresso -l tunnel_$(date +'%F_%T') -a ./adf/tunnel_$(date +'%F_%T').adf
	exe2adf-linux64bit -i musicilario/test -l tunnel_$(date +'%F_%T') -a ./adf/tunneltest_$(date +'%F_%T').adf
	exe2adf-linux64bit -i musicilario/testcompresso -l tunnel_$(date +'%F_%T') -a ./adf/tunneltestcompresso_$(date +'%F_%T').adf
