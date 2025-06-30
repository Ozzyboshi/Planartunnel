MYSPRITE1
VSTART1	dc.b 0
HSTART1	dc.b 0
VSTOP1	dc.b 0,$00
	IFD USE_MIRRORED_SPRITES
	dc.w $0,$0 ; line 1
	dc.w $0,$0 ; line 2
	dc.w $0,$0 ; line 3
	dc.w $0,$0 ; line 4
	dc.w $0,$0 ; line 5
	dc.w $0,$0 ; line 6
	dc.w $0,$0 ; line 7
	dc.w $0,$0 ; line 8
	dc.w $0,$0 ; line 9
	dc.w $0,$0 ; line 10
	dc.w $0,$0 ; line 11
	ELSE
	dc.w $8000,$0000 ; line 1
	dc.w $4000,$8000 ; line 2
	dc.w $2000,$4004 ; line 3
	dc.w $3C00,$4000 ; line 4
	dc.w $28F9,$0C00 ; line 5
	dc.w $F603,$9588 ; line 6
	dc.w $6160,$2081 ; line 7
	dc.w $B500,$1400 ; line 8
	dc.w $F200,$0000 ; line 9
	dc.w $7C00,$0000 ; line 10
	dc.w $1800,$0000 ; line 11
	ENDC
	dc.w 0,0

MYSPRITE01
VSTART01	dc.b 0
HSTART01	dc.b 0
VSTOP01	dc.b	0,%10000000
	IFD USE_MIRRORED_SPRITES
	dc.w $0,$0 ; line 1
	dc.w $0,$0 ; line 2
	dc.w $0,$0 ; line 3
	dc.w $0,$0 ; line 4
	dc.w $0,$0 ; line 5
	dc.w $0,$0 ; line 6
	dc.w $0,$0 ; line 7
	dc.w $0,$0 ; line 8
	dc.w $0,$0 ; line 9
	dc.w $0,$0 ; line 10
	dc.w $0,$0 ; line 11
	ELSE
	dc.w $0000,$0000 ; line 1
	dc.w $0000,$0000 ; line 2
	dc.w $8000,$0000 ; line 3
	dc.w $A804,$0000 ; line 4
	dc.w $DBC5,$0000 ; line 5
	dc.w $7677,$0800 ; line 6
	dc.w $E204,$1C00 ; line 7
	dc.w $F604,$0800 ; line 8
	dc.w $6604,$8800 ; line 9
	dc.w $3C00,$4000 ; line 10
	dc.w $1800,$0000 ; line 11
	ENDC
	dc.w 0,0
