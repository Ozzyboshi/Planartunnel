TEXTURE_SIZE EQU 16

SCREEN_RES_X equ 64
SCREEN_RES_Y equ 64

TEXTURE_WIDTH equ 16
TEXTURE_HEIGHT equ 16

RATIOX EQU 30
RATIOY EQU 4

;FONTCOLOR EQU $0FF0
FONTCOLOR EQU $0CDD

LSBANK_HEADER EQU 0
COLOR1VALUE EQU $A80

DEBUG MACRO
  clr.w                  $100
  move.w                 #$\1,d3
  ENDM

  include "AProcessing/libs/math/operations.s"
  include "AProcessing/libs/math/sin_256_word_q_8_8_autogen_macro.s"

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

BEAT_LIMIT    EQU  29
BEAT_TIMER:   dc.w 48
BEAT_COUNTER: dc.w 0
TUNNEL_MIN_VELOCITY EQU 0
TUNNEL_VELOCITY: dc.w TUNNEL_MIN_VELOCITY
COLORTABLEPTR:   dc.l COLORTABLE
COLORBEATACCELERATIONPTR: dc.l COLORBEATACCELERATION
OLD_VELOCITY: dc.w 0

TEXTURE_POINTER: dc.l TEXTURE_LIST
TEXTURE_LIST: dc.l CHECKERS
              dc.l X4
              dc.l LREV
              dc.l X3
              dc.l X2
              dc.l X
              dc.l SQUARE
              dc.l 0

COLORSTUNNEL:
    dc.w $0F,$00,$00,$00,$00,$00 ; from black to red
    dc.w $00,$00,$0F,$00,$00,$07 ; from green to dark blue
    dc.w $0F,$00,$0F,$07,$00,$07 ; yellow gradient

    dc.w $0F,$0F,$0F,$00,$0F,$00 ; start of transition colors
    dc.w $0F,$00,$0F,$0F,$0F,$00
    dc.w $0F,$0F,$0F,$0F,$0F,$00

    dc.w $0F,$0A,$0F,$08,$0F,$00

TRANSFORMATION_TABLE_Y:
  dcb.w SCREEN_RES_X*2*SCREEN_RES_Y*2,0

sinus:            dcb.w 1024,0
sinus_x:          dcb.w 128*4,0
sinus_y:          dcb.w 128*4,0

COLORTABLEPTRSTART:
COLORTABLE:       dcb.w 48,0
COLORTABLE2:      dcb.w 48,0
COLORTABLE3:      dcb.w 48,0
COLORTABLEPTREND:

COLORBEATACCELERATIONPTRSTART:
COLORBEATACCELERATION: dcb.w 8,0
COLORBEATACCELERATION2: dcb.w 8,0
COLORBEATACCELERATION3: dcb.w 8,0
COLORBEATACCELERATIONPTREND:

COLORBACKGROUNDACCELERATION: dcb.w 8,0

DEG2RADDIVPI2: dcb.b 92,0
RAG2DEVSOURCE:
    dc.w 0 ; 0 deg / 0.000000
    dc.w 2 ; 1 deg / 0.005556
    dc.w 3 ; 2 deg / 0.011111
    dc.w 3 ; 3 deg / 0.016667
    dc.w 3 ; 4 deg / 0.022222
    dc.w 3 ; 5 deg / 0.027778
    dc.w 3 ; 6 deg / 0.033333
    dc.w 2 ; 7 deg / 0.038889
    dc.w 3 ; 8 deg / 0.044444
    dc.w 3 ; 9 deg / 0.050000
    dc.w 3 ; 10 deg / 0.055556
    dc.w 3 ; 11 deg / 0.061111
    dc.w 3 ; 12 deg / 0.066667
    dc.w 2 ; 13 deg / 0.072222
    dc.w 3 ; 14 deg / 0.077778
    dc.w 3 ; 15 deg / 0.083333
    dc.w 3 ; 16 deg / 0.088889
    dc.w 3 ; 17 deg / 0.094444
    dc.w 3 ; 18 deg / 0.100000
    dc.w 3 ; 19 deg / 0.105556
    dc.w 2 ; 20 deg / 0.111111
    dc.w 3 ; 21 deg / 0.116667
    dc.w 3 ; 22 deg / 0.122222
    dc.w 3 ; 23 deg / 0.127778
    dc.w 3 ; 24 deg / 0.133333
    dc.w 3 ; 25 deg / 0.138889
    dc.w 2 ; 26 deg / 0.144444
    dc.w 3 ; 27 deg / 0.150000
    dc.w 3 ; 28 deg / 0.155556
    dc.w 3 ; 29 deg / 0.161111
    dc.w 3 ; 30 deg / 0.166667
    dc.w 3 ; 31 deg / 0.172222
    dc.w 3 ; 32 deg / 0.177778
    dc.w 2 ; 33 deg / 0.183333
    dc.w 3 ; 34 deg / 0.188889
    dc.w 3 ; 35 deg / 0.194444
    dc.w 3 ; 36 deg / 0.200000
    dc.w 3 ; 37 deg / 0.205556
    dc.w 3 ; 38 deg / 0.211111
    dc.w 2 ; 39 deg / 0.216667
    dc.w 3 ; 40 deg / 0.222222
    dc.w 3 ; 41 deg / 0.227778
    dc.w 3 ; 42 deg / 0.233333
    dc.w 3 ; 43 deg / 0.238889
    dc.w 3 ; 44 deg / 0.244444
    dc.w 3 ; 45 deg / 0.250000
    dc.w 2 ; 46 deg / 0.255556
    dc.w 3 ; 47 deg / 0.261111
    dc.w 3 ; 48 deg / 0.266667
    dc.w 3 ; 49 deg / 0.272222
    dc.w 3 ; 50 deg / 0.277778
    dc.w 3 ; 51 deg / 0.283333
    dc.w 2 ; 52 deg / 0.288889
    dc.w 3 ; 53 deg / 0.294444
    dc.w 3 ; 54 deg / 0.300000
    dc.w 3 ; 55 deg / 0.305556
    dc.w 3 ; 56 deg / 0.311111
    dc.w 3 ; 57 deg / 0.316667
    dc.w 2 ; 58 deg / 0.322222
    dc.w 3 ; 59 deg / 0.327778
    dc.w 3 ; 60 deg / 0.333333
    dc.w 3 ; 61 deg / 0.338889
    dc.w 3 ; 62 deg / 0.344444
    dc.w 3 ; 63 deg / 0.350000
    dc.w 3 ; 64 deg / 0.355556
    dc.w 2 ; 65 deg / 0.361111
    dc.w 3 ; 66 deg / 0.366667
    dc.w 3 ; 67 deg / 0.372222
    dc.w 3 ; 68 deg / 0.377778
    dc.w 3 ; 69 deg / 0.383333
    dc.w 3 ; 70 deg / 0.388889
    dc.w 2 ; 71 deg / 0.394444
    dc.w 3 ; 72 deg / 0.400000
    dc.w 3 ; 73 deg / 0.405556
    dc.w 3 ; 74 deg / 0.411111
    dc.w 3 ; 75 deg / 0.416667
    dc.w 3 ; 76 deg / 0.422222
    dc.w 3 ; 77 deg / 0.427778
    dc.w 2 ; 78 deg / 0.433333
    dc.w 3 ; 79 deg / 0.438889
    dc.w 3 ; 80 deg / 0.444444
    dc.w 3 ; 81 deg / 0.450000
    dc.w 3 ; 82 deg / 0.455556
    dc.w 3 ; 83 deg / 0.461111
    dc.w 2 ; 84 deg / 0.466667
    dc.w 3 ; 85 deg / 0.472222
    dc.w 3 ; 86 deg / 0.477778
    dc.w 3 ; 87 deg / 0.483333
    dc.w 3 ; 88 deg / 0.488889
    dc.w 3 ; 89 deg / 0.494444
    dc.w 2 ; 90 deg / 0.500000


  ;include           "deg2raddivpi2.i"
  include           "musicilario/LightSpeedPlayer_Micro.asm"
  include           "musicilario/LightSpeedPlayer_cia.asm"

Inizio:
  jsr               Save_all

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

  ; build the degrees to radians table
  lea               DEG2RADDIVPI2(PC),a0
  lea               92(a0),a1
  moveq             #90,d7
  moveq             #0,d1
looprag2:
  move.w            (a1)+,d0
  add.w             d1,d0
  move.b            d0,(a0)+
  move.w            d0,d1
  dbra              d7,looprag2

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
  move.l            d0,(a0)+
  ; Copperlist creation END

  ; Color 1 default value
  move.w            #COLOR1VALUE,COLOR1

  ; Build beat table
  ;move.w            #0,d0
  ;move.w            #$F00,d1
  ;move.w            #24,d7
  ;lea               COLORTABLE(PC),a0
  ;jsr               buildcolortable
  lea               COLORSTUNNEL,a0
  lea               COLORTABLE,a1
  moveq             #24-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

;  move.w            #7,d0
;  move.w            #$0F0,d1
;  move.w            #24,d7
;  lea               COLORTABLE2(PC),a0
;  jsr               buildcolortable
  ;lea               COLORSTUNNEL+12,a0
  lea               COLORTABLE2,a1
  adda.w            #12,a0
  moveq             #24-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

  ;move.w            #77,d0
  ;move.w            #$FF0,d1
  ;move.w            #24,d7
  ;lea               COLORTABLE3(PC),a0
  ;jsr               buildcolortable
  ;lea               COLORSTUNNEL+24,a0
  lea               COLORTABLE3,a1
  adda.w            #12,a0
  moveq             #24-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

  ; Build acceleration table (beatcolor)
  ;lea               COLORBEATACCELERATION(PC),a0
  ;move.w            #$F00,d0
  ;move.w            #$FFF,d1
  ;move.w            #7,d7
  ;jsr               buildcolortable
  lea               COLORBEATACCELERATION,a1
  adda.w            #12,a0
  moveq             #7-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

  ;               COLORBEATACCELERATION2(PC),a0
  ;move.w            #$0F0,d0
  ;move.w            #$FFF,d1
  ;move.w            #7,d7
  ;jsr               buildcolortable
  lea               COLORBEATACCELERATION2,a1
  adda.w            #12,a0
  moveq             #7-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

  ;lea               COLORBEATACCELERATION3(PC),a0
  ;move.w            #$FF0,d0
  ;move.w            #$FFF,d1
  ;move.w            #7,d7
  ;jsr               buildcolortable
  lea               COLORBEATACCELERATION3,a1
  adda.w            #12,a0
  moveq             #7-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

  lea               COLORBEATACCELERATION3,a1 ; do not remove this, will help shrinkler to save 4 bytes

  ; Build acceleration table (backgroundcolor)
  ;lea               COLORBACKGROUNDACCELERATION(PC),a0
  ;move.w            COLOR1VALUE,d0
  ;move.w            #$FFF,d1
  ;move.w            #7,d7
  ;jsr               buildcolortable
  lea               COLORBACKGROUNDACCELERATION,a1
  adda.w            #12,a0
  moveq             #7-1,d7
  jsr               BUILDCOLORTABLEMAP_SMALL

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

	; CREATE SIN table
  PROTON_SINUS

  lea 				      sinus,a0
  lea 				      sinus_x,a1
  lea 				      sinus_y,a2
  move.w 			      #1024/2-1,d7
partire:
  move.w 			      (a0),d0
  addq 				      #4,a0
  asr.w 			      #2,d0
  move.w 			      d0,d1
  asr.w             #1,d1
  asl.w             #8,d1

  bclr  				    #0,d0
  move.w 			      d0,(a1)+
  move.w 			      d1,(a2)+
  dbra 				      d7,partire

  jsr 				      _angleops_test9

  ; start logo print
  move.l SCREEN_PTR_OTHER_1,a3
  SETBITPLANE       1,a4
  lea               Logo,a5
  ; y cycle start
  move.w            #(SCREEN_RES_Y*1)-1,d7
tunnel_y_logo_prepare:
  move.l            (a5),(a4)+ ; Print logo on the left
  move.l            (a5),(a3)+ ; Print logo on the left
  adda.l            #32,a4
  adda.l            #32,a3
  move.l            (a5),(a4)+ ; Print logo on the right
  move.l            (a5)+,(a3)+ ; Print logo on the left
  dbra              d7,tunnel_y_logo_prepare

  ; START preparing bitplane 0, set 1010101010101010 in every byte where the tunnel will be drown
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

  ; Sprite 00 init
  MOVE.L            #MYSPRITE00,d5
  LEA               SpritePointers+8,a5
  POINTINCOPPERLIST

  ; Sprite 1 init
  MOVE.L            #MYSPRITE1,d5
  LEA               SpritePointers+16,a5
  POINTINCOPPERLIST

  ; Sprite 11 init
  MOVE.L            #MYSPRITE01,d5
  LEA               SpritePointers+24,a5
  POINTINCOPPERLIST

  jsr               GENERATE_TRANSFORMATION_TABLE_Y

  ; Generate transformation table for distance
  jsr               GENERATE_TRANSFORMATION_TABLE_X

  ; Set colors
  move.w            #$e06,$dff180
  move.w            #$0,$dff186

  ; set modulo

  ; Generate XOR texture (16px X 16px)
  ;jsr               XOR_TEXTURE

  ; generate X textures
  lea               X,a0
  moveq             #16-1,d7
  moveq             #3,d0
xloop:

  move.w            #$FF,16*2*2(a0)
  move.w            d7,16*3*2(a0)
  neg.w             d7
  move.w            d7,16*4*2(a0)
  neg.w             d7

  move.w            d0,16*2(a0)
  not.w             d0
  move.w            d0,(a0)+
  not.w             d0
  lsl.w             #1,d0
  dbra              d7,xloop

  lea               CHECKERS,a0
  lea               TEXTURE_DATA,a1 ;; byte next offset is TEXTURE_HEIGHT*TEXTURE_HEIGHT
  lea               TEXTURE_DATA_2,a4
  lea               TEXTURE_DATA_3,a3 ;;byte
  lea               TEXTURE_DATA_4,a2
  rept              16
  jsr               CONVERT2TEXTURE
  endr

  ; Write text
  lea               TXT,a0
  SETBITPLANE       0,a6
  ;add.l             #200*40,a6
  lea               200*40(a6),a6
  moveq             #0,d1
  lea               FONTS,a1
nextletter:
  moveq             #0,d0
  move.b            (a0),d0
  beq.s             txtend

  ; manage newline start
  cmp.b             #$FF,d0
  bne.s             validletter
  add.w             #1*8*40,d1
  SETBITPLANE       0,a6
  lea               200*40(a6),a6
  ;add.l             #200*40,a6
  add.w             d1,a6
  addq              #1,a0
  bra.s             nextletter
  ; manage newline end

validletter:
  subi.w            #$30,d0
  muls              #6,d0
  move.b            0(a1,d0.w),(a6)
  move.b            1(a1,d0.w),40(a6)
  move.b            2(a1,d0.w),80(a6)
  move.b            3(a1,d0.w),120(a6)
  move.b            4(a1,d0.w),160(a6)
  move.b            5(a1,d0.w),200(a6)
  addq              #1,a6
  addq              #1,a0

  bra.s             nextletter
txtend:

  ; Init LSP and start replay using easy CIA toolbox
mouse2:
  cmpi.b            #$ff,$dff006                                                   ; Are we at line 255?
  bne.s             mouse2
	lea		            LSPMusic,a0
	lea		            OZZYVIRGILHEADER,a1
	;lea LSPBank2,a1
  suba.l	          a2,a2			; suppose VBR=0 ( A500 )
	moveq	            #0,d0			; suppose PAL machine
	bsr		            LSP_MusicDriver_CIA_Start
	move.w	          #$e000,$dff09a

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
  lea               sinus_x(PC),a3
  move.w            0(a3,d7.w),d7
  ; SHIFTX END

  jsr               movespritex

  ; SHIFTY START
  lea               sinus_y(PC),a3
  move.l            d3,d0
  add.w             d0,d0
  andi.w            #%111111111,d0 ; Module of 512
  add.w             d0,d0
  move.w            0(a3,d0.w),d0
  jsr               movespritey
  add.w             d0,d7
  ; SHIFTY END

  ;moveq #0,d7 uncomment if you want the tunnel to be centered all the time

  lea               64+32*256+TRANSFORMATION_TABLE_DISTANCE,a3
  adda.w            d7,a3
  lea	              64+32*256+TRANSFORMATION_TABLE_Y(PC),a4
  adda.w            d7,a4

  ; multiply counter by 16
  move.w            d3,d5
  lsl.w             #4,d5

  move.w            d3,d0
  swap              d0 ; old velocity is on high part of d0
  move.w            TUNNEL_VELOCITY,d0
  lsr.w             #1,d0
  lsl.w             d0,d3
  move.w            #$F,d0 ; d0 must hold this value upon entering here

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

  swap              d0
  move.w            d0,d3 ; resume old counter

  ;move.l            EFFECT_FUNCTION,a5
  ;jsr               (a5)

  IFD COLORDEBUG
  move.w            #$000,$dff180
  ENDC

  move.l            COLORTABLEPTR,a5
  cmp.l             #COLORTABLEPTREND,a5
  bne.s             noresetcolorptr
  move.l            #COLORTABLEPTRSTART,COLORTABLEPTR
  move.l            COLORTABLEPTR,a5
noresetcolorptr:
  btst              #0,Lsp_Beat+1
  beq.s             colorcycle        ; if no beat we the beat color must return to the original state according to colortable

  ; IF WE ARE HERE IT MEANS WE HAVE A BEAT
  addq              #1,BEAT_COUNTER ; increase beat counter
  bclr              #0,Lsp_Beat+1   ; ack beat
  move.w            #48,BEAT_TIMER  ; reset beat timer to 48
  move.w            48(a5),COLOR2   ; set color to to the first color

  IF_1_LESS_EQ_2_W_U #22,BEAT_COUNTER,noaddvelocity,s ; check if we are managing the transition stage
  ; IF WE ARE HERE WE MUST MANAGE THE TRANSITION STAGE
  addq.w            #1,TUNNEL_VELOCITY  ; add velocity to the tunnel
  ; Set colors
  ; routine to change colors towards white
  move.w            BEAT_COUNTER,d5
  subi.w            #22,d5
  add.w             d5,d5
  move.l            COLORBEATACCELERATIONPTR,a5
  cmp.l             #COLORBEATACCELERATIONPTREND,a5
  bne.s             nocolorbeataccelerationreset
  move.l            #COLORBEATACCELERATIONPTRSTART,COLORBEATACCELERATIONPTR
  lea               COLORBEATACCELERATIONPTRSTART,a5
nocolorbeataccelerationreset:
  move.w            0(a5,d5),COLOR2
  lea               COLORBACKGROUNDACCELERATION(PC),a5
  move.w            0(a5,d5),COLOR1

noaddvelocity:
  bra.s             loadbitplanes

colorcycle:
  IF_1_GREATER_2_W_S #22,BEAT_COUNTER,loadbitplanes,s ; if beattimer <= 22
  move.w            BEAT_TIMER,d5
  subq              #2,d5
  beq.s             loadbitplanes
  move.w            0(a5,d5.w),COLOR2
  move.w            d5,BEAT_TIMER

  ; load bitplanes in copperlist
loadbitplanes:
  lea               BPLPTR2,a5
  move.l            SCREEN_PTR_1,d5
  POINTINCOPPERLIST

  ; if BEAT_COUNTER reaches 20 then do something
  cmpi.w            #BEAT_LIMIT,BEAT_COUNTER
  bne.w             nochangeeffect
  movem.l           d0-d7/a0-a6,-(sp)
  move.l            TEXTURE_POINTER,a0
  addq              #4,a0
  move.l            a0,TEXTURE_POINTER
  tst.l             (a0)
  bne.s             txtnoreset
  move.l            #TEXTURE_LIST,TEXTURE_POINTER
  move.l            TEXTURE_POINTER,a0
txtnoreset:
  move.l            (a0),a0
  ;lea               SQUARE,a0
  lea               TEXTURE_DATA,a1 ;; byte
  lea               TEXTURE_DATA_2,a4
  lea               TEXTURE_DATA_3,a3 ;;byte
  lea               TEXTURE_DATA_4,a2
  rept              16
  jsr               CONVERT2TEXTURE
  endr
  movem.l           (sp)+,d0-d7/a0-a6
  move.w            #1,BEAT_COUNTER
  move.w            #TUNNEL_MIN_VELOCITY,TUNNEL_VELOCITY ; reset tunnel velocity
  ; reset colors
  move.w            #COLOR1VALUE,COLOR1
  move.w            #$0,$dff186
  ; go to next beatcolortable
  addi.l            #96,COLORTABLEPTR
  addi.l            #16,COLORBEATACCELERATIONPTR

nochangeeffect

  ; increment the frame counter for animating
  addq              #1,d3
  add.w             TUNNEL_VELOCITY,d3

  ; exit if lmb is pressed
  btst              #6,$bfe001
  bne.w             mouse
exit_demo:
  bsr.w             LSP_MusicDriver_CIA_Stop
  jsr               Restore_all
  clr.l             d0
  rts

	data_c

	data
Logo:     incbin  "logo/rseV32x64x1.raw"
LSPMusic:	incbin	"musicilario/demo_klang_pt_5_2_4_micro.lsmusic"
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
  lea               MYSPRITE0,a3
  lea               MYSPRITE1,a4
   ; if d0 is odd we are moving the spaceship to an odd location, in this case we must set
  move.w            d7,d0
  lsr.w             #1,d0
  add.w             #$90-8,d0
  btst              #0,d0
  beq.s             .fspaceship2_no_odd_x
  bset              #0,3(a3)
  bset              #0,3+1*4+11*4+1*4(a3)
  bset              #0,3(a4)
  bset              #0,3+1*4+11*4+1*4(a4)
  bra.s             .fspaceship2_place_coords
.fspaceship2_no_odd_x:
  bclr              #0,3(a3)
  bclr              #0,3+1*4+11*4+1*4(a3)
  bclr              #0,3(a4)
  bclr              #0,3+1*4+11*4+1*4(a4)
.fspaceship2_place_coords:
  move.b            d0,1(a3)
  move.b            d0,1+1*4+11*4+1*4(a3)

  addq              #8,d0
  move.b            d0,1(a4)
  move.b            d0,1+1*4+11*4+1*4(a4)

  rts

movespritey:
  lea               MYSPRITE0,a3
  lea               MYSPRITE1,a4
  swap              d7
  move.w            d0,d7
  lsr.w             #7,d7

  add.w             #$80,d7

  move.b            d7,(a3)
  move.b            d7,1*4+11*4+1*4(a3)
  move.b            d7,(a4)
  move.b            d7,1*4+11*4+1*4(a4)

  add.w             #11,d7
  move.b            d7,2(a3)
  move.b            d7,2+1*4+11*4+1*4(a3)
  move.b            d7,2(a4)
  move.b            d7,2+1*4+11*4+1*4(a4)
  swap              d7

  rts

SQUARE:
  dc.w 0
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w %0111111111111110
  dc.w 0

X:
  dc.w 0 ; %0000000000000011
  dc.w 0 ; %0000000000000110
  dc.w 0 ; %0000000000001100
  dc.w 0 ; %0000000000011000
  dc.w 0 ; %0000000000110000
  dc.w 0 ; %0000000001100000
  dc.w 0 ; %0000000011000000
  dc.w 0 ; %0000000110000000
  dc.w 0 ; %0000001100000000
  dc.w 0 ; %0000011000000000
  dc.w 0 ; %0000110000000000
  dc.w 0 ; %0001100000000000
  dc.w 0 ; %0011000000000000
  dc.w 0 ; %0110000000000000
  dc.w 0 ; %1100000000000000
  dc.w 0 ; %1000000000000000

X2:
  dc.w 0 ; %1111111111111100
  dc.w 0 ; %1111111111111001
  dc.w 0 ; %1111111111110011
  dc.w 0 ; %1111111111100111
  dc.w 0 ; %1111111111001111
  dc.w 0 ; %1111111110011111
  dc.w 0 ; %1111111100111111
  dc.w 0 ; %1111111001111111
  dc.w 0 ; %1111110011111111
  dc.w 0 ; %1111100111111111
  dc.w 0 ; %1111001111111111
  dc.w 0 ; %1110011111111111
  dc.w 0 ; %1100111111111111
  dc.w 0 ; %1001111111111111
  dc.w 0 ; %0011111111111111
  dc.w 0 ; %0111111111111111

X3:
  dc.w 0 ; %1111111111111100
  dc.w 0 ; %1111111111111001
  dc.w 0 ; %1111111111110011
  dc.w 0 ; %1111111111100111
  dc.w 0 ; %1111111111001111
  dc.w 0 ; %1111111110011111
  dc.w 0 ; %1111111100111111
  dc.w 0 ; %1111111001111111
  dc.w 0 ; %1111110011111111
  dc.w 0 ; %1111100111111111
  dc.w 0 ; %1111001111111111
  dc.w 0 ; %1110011111111111
  dc.w 0 ; %1100111111111111
  dc.w 0 ; %1001111111111111
  dc.w 0 ; %0011111111111111
  dc.w 0 ; %0111111111111111

LREV:
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100
  dc.w 0 ;%1111111111111100

X4:
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0
  dc.w 0

CHECKERS:
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $FF00
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF
  dc.w $00FF

CONVERT2TEXTURE:
    moveq #16-1,d7
    move.w (a0)+,d0
convert2texturestartloop:
    moveq #0,d1
    lsl.w #1,d0
    smi d1
    lsr.w #4,d1
    move.b d1,(a1)+
    lsl.w #4,d1
    move.b d1,(a3)+
    lsl.w #4,d1
    move.w d1,(a2)+
    lsl.w #4,d1
    move.w d1,(a4)+
    dbra d7,convert2texturestartloop
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
  bpl.s             qsqrt1
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
  move.w            d5,d0
  subi.w            #SCREEN_RES_Y,d0

  ; compute X - width / 64.0
  move.w            d4,d1
  subi.w            #SCREEN_RES_X,d1

  ;we are ready to call atan2(y,x)/PI
  movem.l          d0/d1,-(sp)
  jsr               ATAN2_PI_128
  movem.l          (sp)+,d0/d1
  asr.w             #3,d3

  ;multiply by texture width and ratioY
  muls              #TEXTURE_WIDTH*RATIOY,d3

  asr.w             #2,d3

  move.w            d3,(a1)+

  addq              #1,d4
  dbra              d6,table_y_precalc_x

  addq              #1,d5
  dbra              d7,table_y_precalc_y
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

  include "AProcessing/libs/vectors/cordic.s"

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
ATAN2_128_QUADRANT: dcb.b 4096,0
Saveint:              dc.w 0
SaveDMA:              dc.w 0
SaveIRQ:              dc.l 0
Name:                 dc.b "graphics.library",0
  even

	include "AProcessing/libs/math/atan2_pi_128.s"
	include "AProcessing/libs/rasterizers/processing_bitplanes_fast.s"
  include "AProcessing/libs/precalc/precalc_col_table_small.s"
  include "AProcessing/libs/copperlistmacros.i"

;----------------------------------------------------------------

; **************************************************************************
; *				SUPER COPPERLIST			   *
; **************************************************************************

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

  dc.w $182
COLOR1: dc.w 0

  dc.w $184
COLOR2: dc.w 0

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

  dc.l 0
  dc.w $182,FONTCOLOR

  ; Copperlist end
  dc.w       $FFFF,$FFFE                                               ; End of copperlist

  include "musicilario/compact/exemusic.asm"

LSPBank:
OZZYVIRGILHEADER: dc.l 0
OZZYVIRGIL: dcb.b 32004,0
  dc.w 0,0
TXT:
  ;dc.b "FOLLOW[PHAZE[101",$FF,"THE[GREAT[RETROPROGRAMMING[COMMUNITY",$FF,"FOR[THE[C64[AND[THE[AMIGA",0
  dc.b "[[[RESISTANCE[PRESENTS[A[4K[ECS[INTRO",$FF,"[[CODE:OZZYBOSHI[MUSIC:IM76[DESIGN:Z3K",$FF,"GREETINGS[TO",$FF
  dc.b "[==>[PRINCE[PHAZE[101[AND",$FF,"[[[[[HIS[RETROPROGRAMMING[COMMUNITY",$FF
  dc.b "[==>[PELLICUS",$FF
  dc.b "[==>[ALL[AMIGA[USERS[AROUND[THE[WORLD",0
  even

FONTS:
  incbin fonts/fonts.raw
  dc.b 0,0,0,0,0,0
SPACESHIP:
  include "sprites/spaceship_back_left.s"
  include "sprites/spaceship_back_right.s"
  end