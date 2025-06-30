;----------------------------------------------------------------------------
;
; Generated with Aklang2Asm V1.1, by Dan/Lemon. 2021-2022.
;
; Based on Alcatraz Amigaklang rendering core. (c) Jochen 'Virgill' Feldkötter 2020.
;
; What's new in V1.1?
; - Instance offsets fixed in ADSR operator
; - Incorrect shift direction fixed in OnePoleFilter operator
; - Loop Generator now correctly interleaved with instrument generation
; - Fine progress includes loop generation, and new AK_FINE_PROGRESS_LEN added
; - Reverb large buffer instance offsets were wrong, causing potential buffer overrun
;
; Call 'AK_Generate' with the following registers set:
; a0 = Sample Buffer Start Address
; a1 = 0 Bytes Temporary Work Buffer Address (can be freed after sample rendering complete)
; a2 = External Samples Address (need not be in chip memory, and can be freed after sample rendering complete)
; a3 = Rendering Progress Address (2 modes available... see below)
;
; AK_FINE_PROGRESS equ 0 = rendering progress as a byte (current instrument number)
; AK_FINE_PROGRESS equ 1 = rendering progress as a long (current sample byte)
;
;----------------------------------------------------------------------------

AK_USE_PROGRESS			equ 1
AK_FINE_PROGRESS		equ 1
AK_FINE_PROGRESS_LEN	equ 18000
AK_SMP_LEN				equ 18000
AK_EXT_SMP_LEN			equ 0

AK_Generate:

				lea		AK_Vars(pc),a5

				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						move.b	#-1,(a3)
					else
						move.l	#0,(a3)
					endif
				endif

				; Create sample & external sample base addresses
				lea		AK_SmpLen(a5),a6
				lea		AK_SmpAddr(a5),a4
				move.l	a0,d0
				moveq	#31-1,d7
.SmpAdrLoop		move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.SmpAdrLoop
				move.l	a2,d0
				moveq	#8-1,d7
.ExtSmpAdrLoop	move.l	d0,(a4)+
				add.l	(a6)+,d0
				dbra	d7,.ExtSmpAdrLoop

;----------------------------------------------------------------------------
; Instrument 1 - exp-pi
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst1Loop
				; v1 = osc_tri(0, 6, 128)
				add.w	#6,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d0
				bge.s	.TriNoInvert_1_1
				not.w	d0
.TriNoInvert_1_1
				sub.w	#16384,d0
				add.w	d0,d0

				; v1 = ctrl(v1)
				moveq	#9,d4
				asr.w	d4,d0
				add.w	#64,d0

				; v1 = osc_pulse(2, 4186, 9, v1)
				add.w	#4186,AK_OpInstance+2(a5)
				move.w	d0,d4
				and.w	#255,d4
				sub.w	#63,d4
				asl.w	#8,d4
				add.w	d4,d4
				cmp.w	AK_OpInstance+2(a5),d4
				slt		d0
				ext.w	d0
				eor.w	#$7fff,d0
				muls	#9,d0
				asr.l	#7,d0

				; v2 = osc_saw(3, 2093, 30)
				add.w	#2093,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d1
				muls	#30,d1
				asr.l	#7,d1

				; v1 = add(v2, v1)
				add.w	d1,d0
				bvc.s	.AddNoClamp_1_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_1_5

				; v2 = sh(5, v1, 64)
				sub.w	#1,AK_OpInstance+6(a5)
				bge.s	.SHNoStore_1_6
				move.w	d0,AK_OpInstance+8(a5)
				move.w	#1024,AK_OpInstance+6(a5)
.SHNoStore_1_6
				move.w	AK_OpInstance+8(a5),d1

				; v2 = ctrl(v2)
				moveq	#9,d4
				asr.w	d4,d1
				add.w	#64,d1

				; v1 = sv_flt_n(7, v1, v2, 88, 1)
				move.w	AK_OpInstance+AK_BPF+10(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+10(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_1_8
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_1_8
				move.w	d4,AK_OpInstance+AK_LPF+10(a5)
				muls	#88,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_1_8
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_1_8
.NoClampMaxHPF_1_8
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_1_8
				move.w	#-32768,d5
.NoClampMinHPF_1_8
				move.w	d5,AK_OpInstance+AK_HPF+10(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+10(a5),d5
				bvc.s	.NoClampBPF_1_8
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_1_8
				move.w	d5,AK_OpInstance+AK_BPF+10(a5)
				move.w	AK_OpInstance+AK_HPF+10(a5),d0

				; v2 = adsr(8, 8183, 442, 3407872, 5709, 3407872, 8388352)
				move.l	AK_OpInstance+16(a5),d1
				move.w	AK_OpInstance+20(a5),d4
				beq.s	.ADSR_A_1_9
				subq.w	#1,d4
				beq.s	.ADSR_D_1_9
				subq.w	#1,d4
				beq.s	.ADSR_S_1_9
.ADSR_R_1_9
				sub.l	#3407872,d1
				bge.s	.ADSR_End_1_9
				moveq	#0,d1
				bra.s	.ADSR_End_1_9
.ADSR_A_1_9
				add.l	#8183,d1
				cmp.l	#8388352,d1
				blt.s	.ADSR_End_1_9
				move.l	#8388352,d1
				move.w	#1,AK_OpInstance+20(a5)
				bra.s	.ADSR_End_1_9
.ADSR_D_1_9
				sub.l	#442,d1
				cmp.l	#3407872,d1
				bgt.s	.ADSR_End_1_9
				move.l	#3407872,d1
				move.l	#5709,AK_OpInstance+22(a5)
				move.w	#2,AK_OpInstance+20(a5)
				bra.s	.ADSR_End_1_9
.ADSR_S_1_9
				subq.l	#1,AK_OpInstance+22(a5)
				bge.s	.ADSR_End_1_9
				move.w	#3,AK_OpInstance+20(a5)
.ADSR_End_1_9
				move.l	d1,AK_OpInstance+16(a5)
				asr.l	#8,d1

				; v1 = mul(v2, v1)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+0(a5),d7
				blt		.Inst1Loop


;----------------------------------------------------------------------------

				; Clear first 2 bytes of each sample
				lea		AK_SmpAddr(a5),a6
				moveq	#0,d0
				moveq	#31-1,d7
.SmpClrLoop		move.l	(a6)+,a4
				move.b	d0,(a4)+
				move.b	d0,(a4)+
				dbra	d7,.SmpClrLoop

				rts

;----------------------------------------------------------------------------

AK_ResetVars:
				moveq   #0,d1
				moveq   #0,d2
				moveq   #0,d3
				moveq   #0,d0
				lea		AK_OpInstance(a5),a6
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				move.l	d0,(a6)+
				rts

;----------------------------------------------------------------------------

				rsreset
AK_LPF			rs.w	1
AK_HPF			rs.w	1
AK_BPF			rs.w	1
				rsreset
AK_CHORD1		rs.l	1
AK_CHORD2		rs.l	1
AK_CHORD3		rs.l	1
				rsreset
AK_SmpLen		rs.l	31
AK_ExtSmpLen	rs.l	8
AK_SmpAddr		rs.l	31
AK_ExtSmpAddr	rs.l	8
AK_OpInstance	rs.w    14
AK_EnvDValue	rs.l	0
AK_VarSize		rs.w	0

AK_Vars:
				dc.l	$00004650		; Instrument 1 Length 
				dc.l	$00000000		; Instrument 2 Length 
				dc.l	$00000000		; Instrument 3 Length 
				dc.l	$00000000		; Instrument 4 Length 
				dc.l	$00000000		; Instrument 5 Length 
				dc.l	$00000000		; Instrument 6 Length 
				dc.l	$00000000		; Instrument 7 Length 
				dc.l	$00000000		; Instrument 8 Length 
				dc.l	$00000000		; Instrument 9 Length 
				dc.l	$00000000		; Instrument 10 Length 
				dc.l	$00000000		; Instrument 11 Length 
				dc.l	$00000000		; Instrument 12 Length 
				dc.l	$00000000		; Instrument 13 Length 
				dc.l	$00000000		; Instrument 14 Length 
				dc.l	$00000000		; Instrument 15 Length 
				dc.l	$00000000		; Instrument 16 Length 
				dc.l	$00000000		; Instrument 17 Length 
				dc.l	$00000000		; Instrument 18 Length 
				dc.l	$00000000		; Instrument 19 Length 
				dc.l	$00000000		; Instrument 20 Length 
				dc.l	$00000000		; Instrument 21 Length 
				dc.l	$00000000		; Instrument 22 Length 
				dc.l	$00000000		; Instrument 23 Length 
				dc.l	$00000000		; Instrument 24 Length 
				dc.l	$00000000		; Instrument 25 Length 
				dc.l	$00000000		; Instrument 26 Length 
				dc.l	$00000000		; Instrument 27 Length 
				dc.l	$00000000		; Instrument 28 Length 
				dc.l	$00000000		; Instrument 29 Length 
				dc.l	$00000000		; Instrument 30 Length 
				dc.l	$00000000		; Instrument 31 Length 
				dc.l	$00000000		; External Sample 1 Length 
				dc.l	$00000000		; External Sample 2 Length 
				dc.l	$00000000		; External Sample 3 Length 
				dc.l	$00000000		; External Sample 4 Length 
				dc.l	$00000000		; External Sample 5 Length 
				dc.l	$00000000		; External Sample 6 Length 
				dc.l	$00000000		; External Sample 7 Length 
				dc.l	$00000000		; External Sample 8 Length 
				ds.b	AK_VarSize-AK_SmpAddr

;----------------------------------------------------------------------------
