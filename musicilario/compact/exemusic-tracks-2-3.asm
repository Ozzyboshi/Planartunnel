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
AK_FINE_PROGRESS_LEN	equ 13000
AK_SMP_LEN				equ 13000
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
; Instrument 1 - chordbase
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
				; v2 = osc_saw(0, 2100, 128)
				add.w	#2100,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1

				; v3 = osc_saw(1, 2090, 128)
				add.w	#2090,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d2

				; v2 = add(v3, v2)
				add.w	d2,d1
				bvc.s	.AddNoClamp_1_3
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.AddNoClamp_1_3

				; v1 = osc_pulse(3, 1047, 59, 32)
				add.w	#1047,AK_OpInstance+4(a5)
				cmp.w	#((32-63)<<9),AK_OpInstance+4(a5)
				slt		d0
				ext.w	d0
				eor.w	#$7fff,d0
				muls	#59,d0
				asr.l	#7,d0

				; v1 = add(v2, v1)
				add.w	d1,d0
				bvc.s	.AddNoClamp_1_5
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_1_5

				; v2 = envd(6, 2, 52, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#8388352,d5
				cmp.l	#872415232,d5
				bgt.s   .EnvDNoSustain_1_6
				move.l	#872415232,d5
.EnvDNoSustain_1_6
				move.l	d5,AK_EnvDValue+0(a5)

				; v3 = envd(7, 16, 0, 128)
				move.l	AK_EnvDValue+4(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#253952,d5
				bgt.s   .EnvDNoSustain_1_7
				moveq	#0,d5
.EnvDNoSustain_1_7
				move.l	d5,AK_EnvDValue+4(a5)

				; v2 = mul(v3, v2)
				muls	d2,d1
				add.l	d1,d1
				swap	d1

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
; Instrument 2 - discokick-ed
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst2Loop
				; v2 = osc_pulse(0, 226, 128, 32)
				add.w	#226,AK_OpInstance+0(a5)
				cmp.w	#((32-63)<<9),AK_OpInstance+0(a5)
				slt		d1
				ext.w	d1
				eor.w	#$7fff,d1

				; v3 = osc_noise(128)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d2

				; v2 = add(v3, v2)
				add.w	d2,d1
				bvc.s	.AddNoClamp_2_3
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.AddNoClamp_2_3

				; v3 = envd(3, 4, 0, 15)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#2796032,d5
				bgt.s   .EnvDNoSustain_2_4
				moveq	#0,d5
.EnvDNoSustain_2_4
				move.l	d5,AK_EnvDValue+0(a5)
				muls	#15,d2
				asr.l	#7,d2

				; v3 = mul(v3, v2)
				muls	d1,d2
				add.l	d2,d2
				swap	d2

				; v1 = envd(6, 5, 0, 128)
				move.l	AK_EnvDValue+4(a5),d5
				move.l	d5,d0
				swap	d0
				sub.l	#2097152,d5
				bgt.s   .EnvDNoSustain_2_6
				moveq	#0,d5
.EnvDNoSustain_2_6
				move.l	d5,AK_EnvDValue+4(a5)

				; v1 = mul(v1, 523)
				muls	#523,d0
				add.l	d0,d0
				swap	d0

				; v1 = osc_tri(8, v1, 128)
				add.w	d0,AK_OpInstance+2(a5)
				move.w	AK_OpInstance+2(a5),d0
				bge.s	.TriNoInvert_2_8
				not.w	d0
.TriNoInvert_2_8
				sub.w	#16384,d0
				add.w	d0,d0

				; v2 = envd(9, 5, 0, 128)
				move.l	AK_EnvDValue+8(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#2097152,d5
				bgt.s   .EnvDNoSustain_2_9
				moveq	#0,d5
.EnvDNoSustain_2_9
				move.l	d5,AK_EnvDValue+8(a5)

				; v1 = mul(v2, v1)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				; v1 = add(v3, v1)
				add.w	d2,d0
				bvc.s	.AddNoClamp_2_11
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_2_11

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+4(a5),d7
				blt		.Inst2Loop

;----------------------------------------------------------------------------
; Instrument 3 - hihat
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst3Loop
				; v1 = osc_noise(128)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d0

				; v2 = enva(1, 4, 0, 128)
				move.l	AK_OpInstance+0(a5),d5
				move.l	d5,d1
				swap	d1
				add.l	#2796032,d5
				bvc.s   .EnvANoMax_3_2
				move.l	#32767<<16,d5
.EnvANoMax_3_2
				move.l	d5,AK_OpInstance+0(a5)

				; v3 = envd(2, 4, 22, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#2796032,d5
				cmp.l	#369098752,d5
				bgt.s   .EnvDNoSustain_3_3
				move.l	#369098752,d5
.EnvDNoSustain_3_3
				move.l	d5,AK_EnvDValue+0(a5)

				; v4 = envd(3, 6, 0, 128)
				move.l	AK_EnvDValue+4(a5),d5
				move.l	d5,d3
				swap	d3
				sub.l	#1677568,d5
				bgt.s   .EnvDNoSustain_3_4
				moveq	#0,d5
.EnvDNoSustain_3_4
				move.l	d5,AK_EnvDValue+4(a5)

				; v3 = mul(v4, v3)
				muls	d3,d2
				add.l	d2,d2
				swap	d2

				; v2 = mul(v3, v2)
				muls	d2,d1
				add.l	d1,d1
				swap	d1

				; v1 = mul(v2, v1)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				; v2 = sv_flt_n(8, v1, 81, 6, 3)
				move.w	AK_OpInstance+AK_BPF+4(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	#81,d5
				move.w	AK_OpInstance+AK_LPF+4(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_3_8
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_3_8
				move.w	d4,AK_OpInstance+AK_LPF+4(a5)
				muls	#6,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_3_8
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_3_8
.NoClampMaxHPF_3_8
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_3_8
				move.w	#-32768,d5
.NoClampMinHPF_3_8
				move.w	d5,AK_OpInstance+AK_HPF+4(a5)
				asr.w	#7,d5
				muls	#81,d5
				add.w	AK_OpInstance+AK_BPF+4(a5),d5
				bvc.s	.NoClampBPF_3_8
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_3_8
				move.w	d5,AK_OpInstance+AK_BPF+4(a5)
				move.w	AK_OpInstance+AK_HPF+4(a5),d1
				add.w	d1,d1
				bvc.s	.NoClampMode3_3_8
				spl		d1
				ext.w	d1
				eor.w	#$7fff,d1
.NoClampMode3_3_8

				; v3 = envd(10, 2, 0, 128)
				move.l	AK_EnvDValue+8(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#8388352,d5
				bgt.s   .EnvDNoSustain_3_9
				moveq	#0,d5
.EnvDNoSustain_3_9
				move.l	d5,AK_EnvDValue+8(a5)

				; v2 = mul(v3, v2)
				muls	d2,d1
				add.l	d1,d1
				swap	d1

				; v1 = add(v2, v1)
				add.w	d1,d0
				bvc.s	.AddNoClamp_3_11
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_3_11

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+8(a5),d7
				blt		.Inst3Loop

;----------------------------------------------------------------------------
; Instrument 4 - snare
;----------------------------------------------------------------------------

				moveq	#0,d0
				bsr		AK_ResetVars
				moveq	#0,d7
				ifne	AK_USE_PROGRESS
					ifeq	AK_FINE_PROGRESS
						addq.b	#1,(a3)
					endif
				endif
.Inst4Loop
				; v2 = osc_tri(0, 3216, 128)
				add.w	#3216,AK_OpInstance+0(a5)
				move.w	AK_OpInstance+0(a5),d1
				bge.s	.TriNoInvert_4_1
				not.w	d1
.TriNoInvert_4_1
				sub.w	#16384,d1
				add.w	d1,d1

				; v3 = ctrl(v2)
				move.w	d1,d2
				moveq	#9,d4
				asr.w	d4,d2
				add.w	#64,d2

				; v1 = osc_pulse(2, 1047, 54, v3)
				add.w	#1047,AK_OpInstance+2(a5)
				move.w	d2,d4
				and.w	#255,d4
				sub.w	#63,d4
				asl.w	#8,d4
				add.w	d4,d4
				cmp.w	AK_OpInstance+2(a5),d4
				slt		d0
				ext.w	d0
				eor.w	#$7fff,d0
				muls	#54,d0
				asr.l	#7,d0

				; v2 = envd(3, 2, 0, 128)
				move.l	AK_EnvDValue+0(a5),d5
				move.l	d5,d1
				swap	d1
				sub.l	#8388352,d5
				bgt.s   .EnvDNoSustain_4_4
				moveq	#0,d5
.EnvDNoSustain_4_4
				move.l	d5,AK_EnvDValue+0(a5)

				; v1 = mul(v2, v1)
				muls	d1,d0
				add.l	d0,d0
				swap	d0

				; v3 = envd(5, 8, 0, 41)
				move.l	AK_EnvDValue+4(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#931840,d5
				bgt.s   .EnvDNoSustain_4_6
				moveq	#0,d5
.EnvDNoSustain_4_6
				move.l	d5,AK_EnvDValue+4(a5)
				muls	#41,d2
				asr.l	#7,d2

				; v3 = mul(v3, 4274)
				muls	#4274,d2
				add.l	d2,d2
				swap	d2

				; v4 = osc_tri(7, v3, 128)
				add.w	d2,AK_OpInstance+4(a5)
				move.w	AK_OpInstance+4(a5),d3
				bge.s	.TriNoInvert_4_8
				not.w	d3
.TriNoInvert_4_8
				sub.w	#16384,d3
				add.w	d3,d3

				; v3 = envd(8, 4, 0, 128)
				move.l	AK_EnvDValue+8(a5),d5
				move.l	d5,d2
				swap	d2
				sub.l	#2796032,d5
				bgt.s   .EnvDNoSustain_4_9
				moveq	#0,d5
.EnvDNoSustain_4_9
				move.l	d5,AK_EnvDValue+8(a5)

				; v3 = mul(v4, v3)
				muls	d3,d2
				add.l	d2,d2
				swap	d2

				; v1 = add(v3, v1)
				add.w	d2,d0
				bvc.s	.AddNoClamp_4_11
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_4_11

				; v2 = osc_noise(17)
				move.l	AK_NoiseSeeds+0(a5),d4
				move.l	AK_NoiseSeeds+4(a5),d5
				eor.l	d5,d4
				move.l	d4,AK_NoiseSeeds+0(a5)
				add.l	d5,AK_NoiseSeeds+8(a5)
				add.l	d4,AK_NoiseSeeds+4(a5)
				move.w	AK_NoiseSeeds+10(a5),d1
				muls	#17,d1
				asr.l	#7,d1

				; v1 = add(v2, v1)
				add.w	d1,d0
				bvc.s	.AddNoClamp_4_13
				spl		d0
				ext.w	d0
				eor.w	#$7fff,d0
.AddNoClamp_4_13

				; v2 = ctrl(v3)
				move.w	d2,d1
				moveq	#9,d4
				asr.w	d4,d1
				add.w	#64,d1

				; v1 = sv_flt_n(14, v1, v2, 81, 0)
				move.w	AK_OpInstance+AK_BPF+6(a5),d5
				asr.w	#7,d5
				move.w	d5,d6
				muls	d1,d5
				move.w	AK_OpInstance+AK_LPF+6(a5),d4
				add.w	d5,d4
				bvc.s	.NoClampLPF_4_15
				spl		d4
				ext.w	d4
				eor.w	#$7fff,d4
.NoClampLPF_4_15
				move.w	d4,AK_OpInstance+AK_LPF+6(a5)
				muls	#81,d6
				move.w	d0,d5
				ext.l	d5
				ext.l	d4
				sub.l	d4,d5
				sub.l	d6,d5
				cmp.l	#32767,d5
				ble.s	.NoClampMaxHPF_4_15
				move.w	#32767,d5
				bra.s	.NoClampMinHPF_4_15
.NoClampMaxHPF_4_15
				cmp.l	#-32768,d5
				bge.s	.NoClampMinHPF_4_15
				move.w	#-32768,d5
.NoClampMinHPF_4_15
				move.w	d5,AK_OpInstance+AK_HPF+6(a5)
				asr.w	#7,d5
				muls	d1,d5
				add.w	AK_OpInstance+AK_BPF+6(a5),d5
				bvc.s	.NoClampBPF_4_15
				spl		d5
				ext.w	d5
				eor.w	#$7fff,d5
.NoClampBPF_4_15
				move.w	d5,AK_OpInstance+AK_BPF+6(a5)
				move.w	AK_OpInstance+AK_LPF+6(a5),d0

				asr.w	#8,d0
				move.b	d0,(a0)+
				ifne	AK_USE_PROGRESS
					ifne	AK_FINE_PROGRESS
						addq.l	#1,(a3)
					endif
				endif
				addq.l	#1,d7
				cmp.l	AK_SmpLen+12(a5),d7
				blt		.Inst4Loop


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
				move.l  #32767<<16,d6
				move.l	d6,(a6)+
				move.l	d6,(a6)+
				move.l	d6,(a6)+
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
AK_NoiseSeeds	rs.l	3
AK_SmpAddr		rs.l	31
AK_ExtSmpAddr	rs.l	8
AK_OpInstance	rs.w    6
AK_EnvDValue	rs.l	3
AK_VarSize		rs.w	0

AK_Vars:
				dc.l	$00001f40		; Instrument 1 Length 
				dc.l	$000007d0		; Instrument 2 Length 
				dc.l	$000003e8		; Instrument 3 Length 
				dc.l	$000007d0		; Instrument 4 Length 
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
				dc.l	$67452301		; AK_NoiseSeed1
				dc.l	$efcdab89		; AK_NoiseSeed2
				dc.l	$00000000		; AK_NoiseSeed3
				ds.b	AK_VarSize-AK_SmpAddr

;----------------------------------------------------------------------------
