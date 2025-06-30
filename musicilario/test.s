TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_WIDTH equ 16
TEXTURE_HEIGHT equ 16

RATIOX EQU 30
RATIOY EQU 4

LSBANK_HEADER EQU $5d1860f6

DEBUG MACRO
  clr.w                  $100
  move.w                 #$\1,d3
  ENDM

; IF_1_LESS_EQ_2_W_U - Check if a data in unsigned word format is LESS of another value
; Input: 
;   - first parameter.w: number to check
;   - second paramter.w: number to check
;   - third parameter: label to jump if condition is false
;   - fourth parameter: size of the jump (s,w)
; Output:
;   - nothing
; Trashes:
;   Nothing
IF_1_LESS_EQ_2_W_U MACRO
    IFC '','\1'
    fail missing first operand!
    MEXIT
    ENDC
    IFC '','\2'
    fail missing second operand!
    MEXIT
    ENDC
    IFC '','\3'
    fail missing label to jump
    MEXIT
    ENDC
    IFNC 'w','\4'
    IFNC 's','\4'
    fail jump size unknown
    MEXIT
    ENDC
    ENDC
    cmp.w               \1,\2
    bcs.\4              \3
    ENDM

SETBITPLANE MACRO
                        IFD                         USE_DBLBUF
                        move.l                      SCREEN_PTR_\1,\2
                        ELSE
                        lea                         SCREEN_\1,\2
                        ENDC
                        ENDM

MEMCPY2 MACRO
	move.l #\3,d7
	subq   #1,d7
	lea \1,a0
	lea \2,a1
.1\@
	move.w (a0)+,(a1)
  neg.w (a1)+
	dbra d7,.1\@
	ENDM

PRINT_PIXELS MACRO
  ; start first pixel
  ; read transformation table (distance table)
  move.w            (a3)+,d2

  ; read transformation table (rotation table)
  move.w            (a4)+,d4

  ; add shift Y (add frame counter to what was read from the rotation table and perform a %16)
  add.w             d5,d4
  and.w             d7,d4 ; perform %256 module
  ;asl.w             #4,d4
  ;((15*16+10*16) mod 256 )

  ; add shift x (add frame counter to what was read from the distance table and perform a %16)
  ; frame counter is on the upper part of d7 to save access memory
  add.w             d3,d2
  and.w             d0,d2

  ; now d4 holds the correct offset of the table in the lower word
  add.w             d2,d4
  add.w             d4,d4
  move.w            0(a6,d4.w),d1 ; check if we have to print color 1 or color 2

  ; pixel 2 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  add.w             d4,d4
  or.w              0(a0,d4.w),d1

; pixel 3 start
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  or.b              0(a1,d4.w),d1

; start of pixel 4
  move.w            (a3)+,d2
  move.w            (a4)+,d4
  add.w             d5,d4
  and.w             d7,d4
  ;asl.w             #4,d4

  add.w             d3,d2
  and.w             d0,d2
  add.w             d2,d4
  or.b              0(a2,d4.w),d1

; copy 4 leds into bitplane

  move.w            d1,(a5)+
  ENDM

PROTON_SINUS MACRO
makesinus:      lea sinus+512(pc),a0
                move.l a0,a3
                lea 1026(a3),a1
                move.l a1,a2
                move.w #255,d0
.gen:           move.w d0,d1 
                move.w d0,d2
                add.w d1,d1 
                mulu d2,d2 
                lsr.w #8,d2 
                sub.w d2,d1 
                move.w d1,-(a3)
                move.w d1,(a0)+
                neg.w d1
                move.w d1,-(a1)
                move.w d1,(a2)+
                dbf d0,.gen
  ENDM


  ; Place addr in d0 and the copperlist pointer addr in a1 before calling
POINTINCOPPERLIST MACRO
  move.w              d5,6(a5)
  swap                d5
  move.w              d5,2(a5)
  ENDM
  jmp                 Inizio

MAXUWORD MACRO
                        cmp.w                       \2,\1
                        bcs.s                       .1\@
                        move.w                      \1,\2
.1\@
    ENDM

	SECTION             CiriCop,CODE_C
; Beatcounter
BEATCOUNTER: dc.w 48

ATAN2_128_QUADRANT: dcb.b 4096,0

ANGTABLE: 
    dc.w %0010110100000000 ; 45
    dc.w %0001101010010000 ; 26.565
    dc.w %0000111000001001 ; 14.036
    dc.w %0000011100100000 ; 7.125
    dc.w %0000001110010011 ; 3.576 
    dc.w %0000000111001010 ; 1.790
    dc.w %0000000011100101 ; 0.895
    dc.w %0000000001110010 ; 0.448
    dc.w 0

TRANSFORMATION_TABLE_Y:
  dcb.w SCREEN_RES_X*2*SCREEN_RES_Y*2,0

sinus:            dcb.w 1024,0
sinus_x:          dcb.w 128*4,0
sinus_y:          dcb.w 128*4,0

COLORTABLE: dcb.w 48,0


  include "../deg2raddivpi2.i"
  include "LightSpeedPlayer_Micro.asm"
  include "LightSpeedPlayer_cia.asm"

Inizio:
  jsr             Save_all

	lea               $dff000,a6
  move              #$7ff,$96(a6)                                                  ;Disable DMAs
  move              #%1000001110101111,$96(a6)                                     ;Master,Copper,Blitter,Bitplanes
  move              #$7fff,$9a(a6)                                                 ;Disable IRQs
  move              #$e000,$9a(a6)                                                 ;Master and lev6
					;NO COPPER-IRQ!
  moveq             #0,d0
  move              d0,$106(a6)                                                    ;Disable AGA/ECS-stuff
  move              d0,$1fc(a6)

  move.l            #COPPERLIST,$80(a6)                                            ; Copperlist point
  move.w            d0,$88(a6)                                                     ; Copperlist start

  move.w            d0,$1fc(a6)                                                    ; FMODE - NO AGA
  move.w            #$c00,$106(a6)                                                 ; BPLCON3 - NO AGA

  ; Copperlist creation START
  lea               SpritePointers,a0
  move.l            #$1200000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  ;lea               BPLPTR1,a0
  move.l            #$e00000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+
  add.l             #$20000,d0
  move.l            d0,(a0)+

  ;lea               COPLINES,a0
  moveq             #SCREEN_RES_Y-1,d7
  move.l            #$2BE3FFFE,d0
coploop:
  move.l            d0,(a0)+
  move.l            #$010AFFD8,(a0)+
  add.l             #1*33554432,d0
  move.l            d0,(a0)+
  move.l            #$010A0000,(a0)+
  add.l             #1*16777216,d0
  dbra              d7,coploop
  ; Copperlist creation END

  ; Start creating color table
  moveq             #24-1,d7
  moveq             #0,d0
  lea               COLORTABLE(PC),a0
colorloop:
  moveq             #0,d1
  moveq             #24,d2
  moveq             #0,d3
  move.w            #$F,d4

  ; MAP execution - start
  move.l            d0,d5
  sub.w             d3,d4 ; d4 = output_end - output_start
  sub.w             d1,d2 ; d2 = input_end - input_start
  sub.w             d1,d0 ; d0 = (input - input_start)
  muls              d0,d4
  divs              d2,d4
  add.w             d3,d4
  move.l            d5,d0
  ; Map execution - end

  move.w            d4,d1
  lsl.w             #8,d4
  or.w              d1,d4
  move.w            d4,(a0)+
  addq              #1,d0
  dbra              d7,colorloop
  ; Stop creating color table

  ; Call 'AK_Generate' with the following registers set:
  ; a0 = Sample Buffer Start Address
  ; a1 = 0 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
  ; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
  ; a3 = Rendering Progress Address (2 modes available... see below)
  lea               OZZYVIRGILHEADER,a0
  move.l            #LSBANK_HEADER,(a0)+
  lea               sinus_x(PC),a1
  lea               sinus_y(PC),a2
  jsr               AK_Generate

  ;lea               OZZYVIRGILHEADER,a0
  ;DEBUG 1111
  ;lea LSPBank2,a1
  ;move.w #8004-1,d7
  ;moveq #0,d0
;testloop:
;  cmp.b (a0)+,(a1)+
;  beq.s testok
;    DEBUG 1112
;testok:
 ;     addq #1,d0

  ;dbra d7,testloop
  ;DEBUG 1113

	; CREATE SIN table
  PROTON_SINUS

  lea 				sinus,a0
  lea 				sinus_x,a1
  lea 				sinus_y,a2
  move.w 			#1024/2-1,d7
partire:
  move.w 			(a0),d0
  addq 				#4,a0
  asr.w 			#2,d0
  move.w 			d0,d1
  asr.w             #1,d1
  asl.w             #8,d1

  bclr 				#0,d0
  move.w 			d0,(a1)+
  move.w 			d1,(a2)+
  dbra 				d7,partire

  jsr 				_angleops_test9

  ; START preparing bitplane 0, set FF in every byte where the tunnel will be drown
  SETBITPLANE       0,a6
  addq              #4,a6
  ; y cycle start
  move.w            #(SCREEN_RES_Y*3)-1,d7
tunnel_y_prepare:

; x cycle start
  moveq             #SCREEN_RES_X/4-1,d6
tunnel_x_prepare:
  ;move.w            #$FFFF,(a6)+
  move.w            #%1010101010101010,(a6)+
  ;move.w            #$FE7F,(a6)+
  dbra              d6,tunnel_x_prepare

  ; change scanline
  lea               8+40*0(a6),a6

  dbra              d7,tunnel_y_prepare
  ; END preparing bitplane 0, set FF in every byte where the tunnel will be drown

  ; Set bpl zero in copperlist
  lea               BPLPTR1,a5
  move.l            SCREEN_PTR_0,d5
  POINTINCOPPERLIST

  ; init sprites
  ; Sprite 0 init
  MOVE.L            #MYSPRITE0,d5
  LEA               SpritePointers,a5
  POINTINCOPPERLIST

  ; Sprite 1 init
  MOVE.L            #MYSPRITE00,d5
  LEA               SpritePointers+8,a5
  POINTINCOPPERLIST

  ; Sprite 1 init
  MOVE.L            #MYSPRITE1,d5
  LEA               SpritePointers+16,a5
  POINTINCOPPERLIST

  ; Sprite 2 init
  MOVE.L            #MYSPRITE01,d5
  LEA               SpritePointers+24,a5
  POINTINCOPPERLIST

  jsr             GENERATE_TRANSFORMATION_TABLE_Y

  ; Generate transformation table for distance
  jsr             GENERATE_TRANSFORMATION_TABLE_X

  ; Set colors
  move.w            #$F,$dff180
  move.w            #$888,$dff182
  ;move.w            #$00f,$dff184
  move.w            #$0,$dff186

  ; set modulo

  ; Generate XOR texture (16px X 16px)
  jsr               XOR_TEXTURE

  ; Write text
  lea TXT,a0
  SETBITPLANE       0,a6
  add.l #200*40,a6
  moveq #0,d1
  lea FONTS,a1
nextletter:
  moveq #0,d0
  move.b (a0),d0
  beq.s txtend

  ; manage newline start
  cmp.b #$FF,d0
  bne.s validletter
  add.w #1*8*40,d1
  SETBITPLANE       0,a6
  add.l #200*40,a6
  add.w d1,a6
  addq #1,a0
  bra.s nextletter
  ; manage newline end

validletter:
  subi.w #$30,d0
  muls #6,d0
  move.b 0(a1,d0.w),(a6)
  move.b 1(a1,d0.w),40(a6)
  move.b 2(a1,d0.w),80(a6)
  move.b 3(a1,d0.w),120(a6)
  move.b 4(a1,d0.w),160(a6)
  move.b 5(a1,d0.w),200(a6)
  addq #1,a6
  addq #1,a0

  bra.s nextletter
txtend:

	;code
		
			;move.w	#(1<<5)|(1<<6)|(1<<7)|(1<<8),$dff096

			;bsr		clearSprites

			move.w	#$0,$dff1fc
			;move.w	#$200,$dff100	; 0 bitplan
			;move.w	#$04f,$dff180
	
		; Init LSP and start replay using easy CIA toolbox
			lea		LSPMusic,a0
			lea		OZZYVIRGILHEADER,a1
			;lea LSPBank2,a1
      suba.l	a2,a2			; suppose VBR=0 ( A500 )
			moveq	#0,d0			; suppose PAL machine
			bsr		LSP_MusicDriver_CIA_Start

			move.w	#$e000,$dff09a

  moveq             #0,d3 ; reset current time variable
  move.l            #40*256*2*-1,d6

  lea               TEXTURE_DATA,a2
  lea               TEXTURE_DATA_2,a6
  lea               TEXTURE_DATA_3,a1
  lea               TEXTURE_DATA_4,a0
  
		
		

			; ******************************* START OF GAME LOOP ****************************
mouse:
  cmpi.b            #$ff,$dff006                                                   ; Are we at line 255?
  bne.s             mouse    

  ; Switch Bitplanes for double buffering
  neg.l             d6
  add.l             d6,SCREEN_PTR_1
  SETBITPLANE       1,a5
  addq              #4,a5

  ; *********************************** Start of tunnel rendering *********************************

  ; Add offset for navigating into the tunnel (ShiftX and ShiftY)
  ; I will use d3 (frame counter) to move from one place to another
  ; SHIFTX START
  move.l            d3,d7
  andi.w            #%111111111,d7 ; Module of 512
  add.w             d7,d7
  ;lea               SIN_TABLE(PC),a3
  lea               sinus_x(PC),a3
  move.w            0(a3,d7.w),d7
  ; SHIFTX END

  jsr movespritex

  ; SHIFTY START
  ;lea               SIN_TABLE2(PC),a3
  lea               sinus_y(PC),a3
  move.l            d3,d0
  add.w             d0,d0
  andi.w            #%111111111,d0 ; Module of 512
  add.w             d0,d0
  move.w            0(a3,d0.w),d0
  jsr movespritey
  add.w             d0,d7
  ; SHIFTY END

  lea               64+32*256+TRANSFORMATION_TABLE_DISTANCE,a3
  adda.w            d7,a3
  lea	              64+32*256+TRANSFORMATION_TABLE_Y(PC),a4
  adda.w            d7,a4

  moveq             #$F,d0

  ; multiply counter by 16
  move.w            d3,d5
  lsl.w             #4,d5

  ; y cycle start
  IFND TUNNEL_SCANLINES
  moveq             #SCREEN_RES_Y-1,d7
  ELSE
  moveq             #TUNNEL_SCANLINES-1,d7
  ENDC
  ori.l             #$FF0000,d7
tunnel_y:


  swap d7
  rept 16
  PRINT_PIXELS
  endr
  swap d7

  ; change scanline
  lea               64*2(a3),a3
  lea               64*2(a4),a4
  addq              #8,a5

  dbra              d7,tunnel_y
tunnelend:
  ;move.l            EFFECT_FUNCTION,a5
  ;jsr               (a5)

  IFD COLORDEBUG
  move.w            #$000,$dff180
  ENDC

  lea COLORTABLE(PC),a5
  ;btst #3,Lsp_Beat+1
  btst #4,d3
  beq.s colorcycle
  ;bclr #3,Lsp_Beat+1
  move.w #48,BEATCOUNTER
  move.w 48(a5),$DFF184
  bra.s loadbitplanes

colorcycle:
  move.w BEATCOUNTER,d5
  subq #2,d5
  move.w 0(a5,d5.w),$DFF184
  move.w d5,BEATCOUNTER

  ; load bitplanes in copperlist
loadbitplanes:
  lea               BPLPTR2,a5
  move.l            SCREEN_PTR_1,d5
  POINTINCOPPERLIST

  ; increment the frame counter for animating
  addq              #1,d3

  ; exit if lmb is pressed
  btst              #6,$bfe001
  bne.w             mouse
exit_demo:
  bsr.w             LSP_MusicDriver_CIA_Stop
  jsr             Restore_all
  clr.l             d0
  rts

;mainLoop:	bra.s	mainLoop

		
clearSprites:
			lea		$dff140,a0
			moveq	#8-1,d0			; 8 sprites to clear
			moveq	#0,d1
.clspr:		move.l	d1,(a0)+
			move.l	d1,(a0)+
			dbf		d0,.clspr
			rts

		data_c

;LSPBank2:	incbin	"compact/demo_klang2-3.lsbank"
;;			even

		data

LSPMusic:	incbin	"demo_klang_pt_5_micro.lsmusic"
			even

;---------------------------------------------------------------
Save_all:
  move.b            #$87,$bfd100                                                   ; stop drive
  move.l            $00000004,a6
  jsr               -132(a6)
  move.l            $6c,SaveIRQ
  move.w            $dff01c,Saveint
  or.w              #$c000,Saveint
  move.w            $dff002,SaveDMA
  or.w              #$8100,SaveDMA

  move.l	          4.w,a6		; ExecBase in A6
  JSR	              -$84(a6)	; FORBID - Disabilita il Multitasking
  JSR	              -$78(A6)	; DISABLE - Disabilita anche gli interrupt
				;	    del sistema operativo
  ; set new intena
  MOVE.L	          #$7FFF7FFF,$dff09A	; DISABILITA GLI INTERRUPTS & INTREQS

  rts

movespritex:
  lea                   MYSPRITE0,a3
  lea                   MYSPRITE1,a4
   ; if d0 is odd we are moving the spaceship to an odd location, in this case we must set
  move.w d7,d0
  lsr.w #1,d0
  add.w #$90-8,d0
  btst                 #0,d0
  beq.s                .fspaceship2_no_odd_x
  bset                 #0,3(a3)
  bset                 #0,3+1*4+11*4+1*4(a3)
  bset                 #0,3(a4)
  bset                 #0,3+1*4+11*4+1*4(a4)
  bra.s                .fspaceship2_place_coords
.fspaceship2_no_odd_x:
  bclr                 #0,3(a3)
  bclr                 #0,3+1*4+11*4+1*4(a3)
  bclr                 #0,3(a4)
  bclr                 #0,3+1*4+11*4+1*4(a4)
.fspaceship2_place_coords:
  move.b               d0,1(a3)
  move.b               d0,1+1*4+11*4+1*4(a3)

  addq #8,d0
  move.b               d0,1(a4)
  move.b               d0,1+1*4+11*4+1*4(a4)

  rts

movespritey:
  lea                   MYSPRITE0,a3
  lea                   MYSPRITE1,a4
  swap                  d7
  move.w                d0,d7
  lsr.w                 #7,d7

  add.w                 #$80,d7

  move.b               d7,(a3)
  move.b               d7,1*4+11*4+1*4(a3)
  move.b               d7,(a4)
  move.b               d7,1*4+11*4+1*4(a4)

  add.w #11,d7
  move.b               d7,2(a3)
  move.b               d7,2+1*4+11*4+1*4(a3)
  move.b               d7,2(a4)
  move.b               d7,2+1*4+11*4+1*4(a4)
  swap d7

  rts

; Routine to generate a XOR texture
XOR_TEXTURE:
  ;for(int y = 0; y < texHeight; y++)
  ;for(int x = 0; x < texWidth; x++)
  ;{
  ;  texture[y][x] = (x * 256 / texWidth) ^ (y * 256 / texHeight);
  ;}
  lea               TEXTURE_DATA(PC),a2
  lea               TEXTURE_DATA_2(PC),a3
  lea               TEXTURE_DATA_3(PC),a4
  lea               TEXTURE_DATA_4(PC),a5
  clr.w             d0
  clr.w             d1

  ; y cycle start   for(int y = 0; y < texHeight; y++)
  moveq             #TEXTURE_SIZE-1,d7
xor_texture_y:

; x cycle start
  moveq             #TEXTURE_SIZE-1,d6 ; for(int x = 0; x < texWidth; x++)
xor_texture_x:

  ; execute eor
  move.w            d0,d5
  eor.w             d1,d5

  ; if d7 > 127 color is 1
  IF_1_LESS_EQ_2_W_U #TEXTURE_SIZE/2,d5,.notgreater,s
  clr.b             (a4)+
  clr.b             (a2)+
  clr.w             (a3)+
  clr.w             (a5)+
  bra.s             .printpoint
.notgreater:
  move.b            #$F0,(a4)+
  move.b            #$0F,(a2)+
  move.w            #$F000,(a3)+
  move.w            #$0F00,(a5)+
.printpoint
  addq              #1,d0
  dbra              d6,xor_texture_x
  clr.w             d0
  addq              #1,d1
  dbra              d7,xor_texture_y
  rts


GENERATE_TRANSFORMATION_TABLE_X:
  lea               TRANSFORMATION_TABLE_DISTANCE(PC),a0

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys
  move.l            #0*64,d0
  move.l            #0,d1

  ; first cycle - for each Y
  moveq             #SCREEN_RES_Y*2-1,d7
table_precalc_y:

  ; second cycle - for each X
  moveq             #SCREEN_RES_X*2-1,d6
table_precalc_x:

  ; need to save d0 (x) and d1 (y) to preserve their value
  move.l            d0,d2
  move.l            d1,d3

  ;get the division number
  ;move.w            #64*SCREEN_RES_X,d4
  ;lsr.w             #1,d4 ; change here to set X position of the center

  sub.w             #64*64,d2
  muls.w            d2,d2
  lsr.l             #6,d2

  ;move.w            #64*SCREEN_RES_Y,d4
  ;lsr.w             #1,d4

  sub.w             #64*64,d3
  muls.w            d3,d3
  lsr.l             #6,d3

  add.l             d3,d2 ; it is important here to compute long because otherwise 
  lsr.l             #6,d2 ; the get strange bands in the middle of the tunner
  move.l            d2,d3 ; but anyway it could be an idea for an effect

  ;(x - width ) * (x - width ) + (y - height ) * (y - height )
    ; let's start with sqrt calculation

  ; start sqrt execution
  move.w            #-1,d5
qsqrt1:
  addq              #2,d5
  sub.w             d5,d3
  bpl               qsqrt1
  asr.w             #1,d5
  move.w            d5,d3
  ; end sqrt execution

 ; sanity check, distance could be zero, we dont want to divide by zero, m68k doesnt like it
  ; if distance is zero let's say distance is 1
  bne.s             distanceok
  moveq             #1,d3
distanceok:

  ; start executing the following C code: int inverse_distance = (int) (RATIOX * texHeight / distance);
  ; divide per texture height
  move.l            #64*RATIOX*TEXTURE_HEIGHT,d2
  divu              d3,d2

  ; get integer part
  lsr.w             #6,d2

  ;get the module
  ext.l             d2
  divu              #TEXTURE_HEIGHT,d2
  swap              d2

  ; write into transformation table
  move.w            d2,(a0)+

  addi.w            #1*64,d0
  dbra              d6,table_precalc_x

  add.w             #1*64,d1 ; increment y

  move.l            #0*64,d0
  dbra              d7,table_precalc_y

  rts

GENERATE_TRANSFORMATION_TABLE_Y:
  lea               TRANSFORMATION_TABLE_Y,a1

  ; height / 1 (64.0) into d3
  moveq             #SCREEN_RES_X,d3
  ;divu              #1,d3

  moveq             #SCREEN_RES_Y,d2
  ;divu              #1,d2

  ; cannot keep in d3 the value of x, saving in upper part of d2
  swap              d2
  move.w            d3,d2
  swap              d2

  ; init x (d0) and y (d1) , for convenience instead starting from 0, we start from -SCREEN_RES_X/2 and we end
  ; at SCREEN_RES/2, same for the Y axys

  ; first cycle - for each Y
  moveq             #0,d5 ; Y
  moveq             #SCREEN_RES_Y*2-1,d7
table_y_precalc_y:

  ; second cycle - for each X
  moveq             #0,d4 ; X
  moveq             #SCREEN_RES_X*2-1,d6
table_y_precalc_x:

  ;get atan_distance using Aprocessing
  ;double atan_distance = atan2(y - height / 64.0, x - width / 64.0)/M_PI;

  ; compute y - height / 64.0
  move.w           d5,d0
  subi.w            #SCREEN_RES_Y,d0

  ; compute X - width / 64.0
  move.w           d4,d1
  subi.w           #SCREEN_RES_X,d1

  ;we are ready to call atan2(y,x)/PI
  movem.l          d0/d1,-(sp)
  jsr              ATAN2_PI_128
  movem.l          (sp)+,d0/d1
  asr.w            #3,d3

  ;multiply by texture width and ratioY
  muls             #TEXTURE_WIDTH*RATIOY,d3

  asr.w            #2,d3

  move.w           d3,(a1)+

  addq             #1,d4
  dbra             d6,table_y_precalc_x

  addq             #1,d5
  dbra             d7,table_y_precalc_y
  rts


_angleops_test9:
  
  lea ATAN2_128_QUADRANT,a0
  moveq #64-1,d6 ; how many cycles for x?
  move.w #1,d0
test9loopx:  
  
  move.w #1,d1
  moveq #0,d5


  moveq #64-1,d7 ; how many cycles for y?
test9loop;

  movem.l d0/d1/d2/d4/d5/d6/d7/a0,-(sp)
  jsr CORDIC
  movem.l (sp)+,d0/d1/d2/d4/d5/d6/d7/a0
  lsr.w #8,d3
  cmp.b #$FF,d3
  bne.s noerrore
  moveq #0,d3
noerrore:

  MAXUWORD d5,d3

  addq #2,d1
  lea DEG2RADDIVPI2,a1
  move.b 0(a1,d3.w),(a0)+
  ;move.b d3,(a0)+
  move.b d3,d5 ; save it for later comparison
  dbra d7,test9loop

  addq #2,d0
  dbra d6,test9loopx
  rts

CORDIC:
    ; Load angle table into a0
    lea ANGTABLE,a0

    ; init Shiftcounter , register is d6
    moveq #0,d6

    ; init SumAngle , register is d3
    moveq #0,d3

cordicloop:
    ; check if Y is positive
    tst.w d1
    bmi cordicnegative

    ; ********************* Y is positive ***********************
    ; Xnew = X + Y >> Shiftcounter
    move.w d1,d5 ; first we have to shift Y , use scratch register d5
    asr.w d6,d5  ; Y is now shifted into d5
    add.w d0,d5  ; Now d5 holds Xnew

    ; Ynew = Y - X >> Shiftcounter
    move.w d0,d4 ; first we have to shift Y , use scratch register d4
    neg.w d4
    asr.w d6,d4  ; Y is now shifted into d5
    add.w d1,d4
    
    add.w (a0)+,d3 ; SumAngle += AngTable[i]

    bra cordicincreaseangle


cordicnegative:
    ; ********************* Y is NEGATIVE ***********************
    ; Xnew = X + Y >> Shiftcounter
    move.w d1,d5 ; first we have to shift Y , use scratch register d5
    asr.w d6,d5  ; Y is now shifted into d5
    neg d5
    add.w d0,d5  ; Now d5 holds Xnew

    ; Ynew = Y - X >> Shiftcounter
    move.w d0,d4 ; first we have to shift Y , use scratch register d4
    asr.w d6,d4  ; Y is now shifted into d5
    add.w d1,d4

    sub.w (a0)+,d3 ; SumAngle -= AngTable[i]

cordicincreaseangle:

    move.w d5,d0
    move.w d4,d1
    beq CORDINCEND
    tst.w (a0)
    beq CORDINCEND

    addq #1,d6 ; Increment shifting
    
    ; cycle over 
    bra cordicloop
CORDINCEND:
    rts

Restore_all:
  move.l            SaveIRQ,$6c
  move.w            #$7fff,$dff09a
  move.w            Saveint,$dff09a
  move.w            #$7fff,$dff096
  move.w            SaveDMA,$dff096
  move.l            $00000004,a6
  lea               Name,a1
  moveq             #0,d0
  jsr               -552(a6)
  move.l            d0,a0
  move.l            38(a0),$dff080
  clr.w             $dff088
  move.l            d0,a1
  jsr               -414(a6)
  jsr               -138(a6)
  rts

TEXTURE_DATA:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_2:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_3:
  dcb.b TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TEXTURE_DATA_4:
  dcb.w TEXTURE_HEIGHT*TEXTURE_HEIGHT,0
TRANSFORMATION_TABLE_DISTANCE:
  dcb.w SCREEN_RES_X*2*SCREEN_RES_Y*2,0
;---------------------------------------------------------------
Saveint:              dc.w 0
SaveDMA:              dc.w 0
SaveIRQ:              dc.l 0
Name:                 dc.b "graphics.library",0
  even

	include "../AProcessing/libs/rasterizers/processing_bitplanes_fast.s"
	  include "../AProcessing/libs/math/atan2_pi_128.s"

;----------------------------------------------------------------

; **************************************************************************
; *				SUPER COPPERLIST			   *
; **************************************************************************

; Single playfield mode
COPSET2BPL MACRO
  dc.w       $100
  dc.w       %0010001000000000
  ENDM

  SECTION    GRAPHIC,DATA_C

COPPERLIST:

; other stuff
  dc.w       $8e,$2c81                                                 ; DiwStrt	(registri con valori normali)
  dc.w       $90,$2cc1                                                 ; DiwStop
  dc.w       $92,$0038                                                 ; DdfStart
  dc.w       $94,$00d0                                                 ; DdfStop
  dc.w       $102,0

  dc.w       $104,$0064

  dc.w       $108,0                                                    ; Bpl1Mod
  dc.w       $10a,0

  COPSET2BPL

;dc.w    $1a0,$000    ; color transparency
  dc.w    $1a2,$213    ; color17
  dc.w    $1a4,$446    ; color18
  dc.w    $1a6,$ccd    ; color19
  dc.w    $1a8,$679    ; color20
  dc.w    $1aa,$235    ; color21
  dc.w    $1ac,$99b    ; color22
  dc.w    $1ae,$394    ; color23
  dc.w    $1b0,$cf7    ; color24

SpritePointers:
Sprite0pointers:
  dc.w 0,0,0,0

Sprite1pointers:
  dc.w 0,0,0,0

Sprite2pointers:
  ;dc.w       $128,$0000,$12a,$0000
  dc.w 0,0,0,0

Sprite3pointers:
  dc.w 0,0,0,0

Sprite4pointers:
  dc.w 0,0,0,0

Sprite5pointers:
  dc.w 0,0,0,0

Sprite6pointers;
  dc.w 0,0,0,0

Sprite7pointers:
  dc.w 0,0,0,0

; Bitplanes Pointers
BPLPTR1:
  dc.l 0,0
BPLPTR2:
  dc.l 0,0

COPLINES: dcb.l 4*64,0
  

  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  ;include exemusic.asm
  include "compact/exemusic.asm"

LSPBank:
OZZYVIRGILHEADER: dc.l 0
OZZYVIRGIL: dcb.b 32004,0
  dc.w 0
TXT:
  dc.b "FOLLOW[PHAZE[101",$FF,"THE[GREAT[RETROPROGRAMMING[COMMUNITY",$FF,"FOR[THE[C64[AND[THE[AMIGA",0
FONTS:
  incbin ../fonts/fonts.raw
  dc.b 0,0,0,0,0,0
SPACESHIP:
  include "../sprites/spaceship_back_left.s"
  include "../sprites/spaceship_back_right.s"
  end

