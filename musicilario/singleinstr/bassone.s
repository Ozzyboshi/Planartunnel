;
; LightSpeedPlayer usage example
; 

DEBUG MACRO
  clr.w                  $100
  move.w                 #$\1,d3
  ENDM
		code
		
			;move.w	#(1<<5)|(1<<6)|(1<<7)|(1<<8),$dff096

			bsr		clearSprites

			move.w	#$0,$dff1fc
			move.w	#$200,$dff100	; 0 bitplan
			move.w	#$04f,$dff180

				; Call 'AK_Generate' with the following registers set:
	; a0 = Sample Buffer Start Address
	; a1 = 0 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
	; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
	; a3 = Rendering Progress Address (2 modes available... see below)
	lea               OZZYVIRGILHEADER,a0
	move.l            #$e04f2bc9,(a0)+
	;lea               sinus_x(PC),a1
	;lea               sinus_y(PC),a1
	
	jsr               AK_Generate
	lea OZZYVIRGILHEADER,a0
	DEBUG 6543
	
mainLoop:	bra.s	mainLoop
	
clearSprites:
			lea		$dff140,a0
			moveq	#8-1,d0			; 8 sprites to clear
			moveq	#0,d1
.clspr:		move.l	d1,(a0)+
			move.l	d1,(a0)+
			dbf		d0,.clspr
			rts

		data_c
OZZYVIRGILHEADER: dc.l 0
LSPBank:	;incbin	"demo_klang_pt_8_cut.lsbank"
				dcb.b 6000,0
				dc.l 0,0,0,0
			even

		data

			even

  include bassone.asm
