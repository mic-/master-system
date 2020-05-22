; Cross Platform Music Player
; SMS/GG version
; /Mic, 2008
;
; The player code/data requires 3-5kB of ROM depending on which effects that are used.


; Define the starting address of XPMP's RAM chunk (about 200 consecutive bytes are used).
.IFNDEF XPMP_RAM_START
.DEFINE XPMP_RAM_START $D000
.ENDIF

.DEFINE XPMP_ENABLE_CHANNEL_A
.DEFINE XPMP_ENABLE_CHANNEL_B
.DEFINE XPMP_ENABLE_CHANNEL_C
.DEFINE XPMP_ENABLE_CHANNEL_D
.IFDEF XPMP_ENABLE_FM
.DEFINE XPMP_ENABLE_CHANNEL_E
.DEFINE XPMP_ENABLE_CHANNEL_F
.DEFINE XPMP_ENABLE_CHANNEL_G
.DEFINE XPMP_ENABLE_CHANNEL_H
.DEFINE XPMP_ENABLE_CHANNEL_I
.DEFINE XPMP_ENABLE_CHANNEL_J
.ENDIF

.EQU CMD_NOTE   $00
.EQU CMD_REST	$0C
.EQU CMD_OCTAVE $10
.EQU CMD_DUTY   $20
.EQU CMD_VOL2   $30
.EQU CMD_OCTUP  $40
.EQU CMD_OCTDN  $50
.EQU CMD_ARPOFF $90
.EQU CMD_JSR	$96
.EQU CMD_RTS	$97
.EQU CMD_CBOFF  $E0
.EQU CMD_CBONCE $E1
.EQU CMD_CBEVNT $E2
.EQU CMD_CBEVVC $E3
.EQU CMD_CBEVVM $E4
.EQU CMD_CBEVOC $E5
.EQU CMD_DETUNE $ED
.EQU CMD_VOLSET $F0
.EQU CMD_VOLMAC $F1
.EQU CMD_DUTMAC $F2
.EQU CMD_PORMAC $F3
.EQU CMD_PANMAC $F4
.EQU CMD_VIBMAC $F5
.EQU CMD_SWPMAC $F6
.EQU CMD_VSLMAC $F7
.EQU CMD_ARPMAC $F8
.EQU CMD_JMP    $F9
.EQU CMD_DJNZ   $FA
.EQU CMD_LOPCNT $FB
.EQU CMD_APMAC2 $FC
.EQU CMD_END    $FF

.EQU EFFECT_DISABLED 0


.STRUCT xpmp_channel_t
dataPtr		dw
dataPos		dw
delay		dw
delayHi		db	; Note delays are 24 bit unsigned fixed point in 16.8 format
note		db
noteOffs	db
octave		db
duty		db
freq		dw
volume		db
volOffs		db
volOffsLatch	db
freqOffs	dw
freqOffsLatch	dw
detune		dw 
vMac		db
vMacPtr		dw
vMacPos		db
enMac		db
enMacPtr	dw
enMacPos	db
en2Mac		db
en2MacPtr	dw
en2MacPos	db
epMac		db
epMacPtr	dw
epMacPos	db
csMac		db
csMacPtr	dw
csMacPos	db
mpMac		db
mpMacPtr	dw
mpMacDelay	db
loop1		db
loop2		db
loopPtr		dw
returnAddr	dw
oldPos		dw
cbEvnote	dw
.ENDST


.STRUCT xpmp_fm_channel_t
dataPtr		dw
dataPos		dw
delay		dw
delayHi		db	; Note delays are 24 bit unsigned fixed point in 16.8 format
note		db
noteOffs	db
octave		db
duty		db
freq		dw
volume		db
volOffs		db
volOffsLatch	db
freqOffs	dw
freqOffsLatch	dw
detune		dw 
vMac		db
vMacPtr		dw
vMacPos		db
enMac		db
enMacPtr	dw
enMacPos	db
en2Mac		db
en2MacPtr	dw
en2MacPos	db
epMac		db
epMacPtr	dw
epMacPos	db
csMac		db
csMacPtr	dw
csMacPos	db
mpMac		db
mpMacPtr	dw
mpMacDelay	db
loop1		db
loop2		db
loopPtr		dw
returnAddr	dw
oldPos		dw
algo		db
cbEvnote	dw
.ENDST


.IFDEF XPMP_ENABLE_FM
.ENUM XPMP_RAM_START
xpmp_channel0	INSTANCEOF xpmp_channel_t
xpmp_channel1 	INSTANCEOF xpmp_channel_t
xpmp_channel2 	INSTANCEOF xpmp_channel_t
xpmp_channel3 	INSTANCEOF xpmp_channel_t
xpmp_channel4 	INSTANCEOF xpmp_fm_channel_t
xpmp_channel5 	INSTANCEOF xpmp_fm_channel_t
xpmp_channel6 	INSTANCEOF xpmp_fm_channel_t
xpmp_channel7 	INSTANCEOF xpmp_fm_channel_t
xpmp_channel8 	INSTANCEOF xpmp_fm_channel_t
xpmp_channel9 	INSTANCEOF xpmp_fm_channel_t
xpmp_freqChange	db
xpmp_volChange 	db
xpmp_lastNote	db
xpmp_pan	db
xpmp_tempw	dw
.ENDE
.ELSE
.ENUM XPMP_RAM_START
xpmp_channel0	INSTANCEOF xpmp_channel_t
xpmp_channel1 	INSTANCEOF xpmp_channel_t
xpmp_channel2 	INSTANCEOF xpmp_channel_t
xpmp_channel3 	INSTANCEOF xpmp_channel_t
xpmp_freqChange	db
xpmp_volChange 	db
xpmp_lastNote	db
xpmp_pan	db
xpmp_tempw	dw
.ENDE
.ENDIF

; Compare HL with an immediate 16-bit number and jump if less (unsigned)
.MACRO JL_IMM16
	push	hl
	ld	de,\1
	and	a
	sbc	hl,de
	pop	hl
	jp	c,\2
.ENDM


; Compare HL with an immediate 16-bit number and jump if greater or equal (unsigned)
.MACRO JGE_IMM16
	push	hl
	ld	de,\1
	and	a
	sbc	hl,de
	pop	hl
	jp	nc,\2
.ENDM



; Initialize the music player
; HL = pointer to song table, A = song number
xpmp_init:
	ld	b,0
	dec	a
	ld	c,a
	sla	c
	add	hl,bc
	
	; Initialize all the player variables to zero
	ld 	bc,XPMP_RAM_START
	ld 	a,0
	ld 	d,xpmp_tempw+2-XPMP_RAM_START
	xpmp_init_zero:
		ld 	(bc),a
		inc 	bc
		dec 	d
		jr 	nz,xpmp_init_zero
	
	; Initialize channel data pointers
	.IFDEF XPMP_ENABLE_CHANNEL_A
	ld	a,(hl)
	ld	(xpmp_channel0.dataPtr),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_A
	ld	a,(hl)
	ld	(xpmp_channel0.dataPtr+1),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_B
	ld	a,(hl)
	ld	(xpmp_channel1.dataPtr),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_B
	ld	a,(hl)
	ld	(xpmp_channel1.dataPtr+1),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_C
	ld	a,(hl)
	ld	(xpmp_channel2.dataPtr),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_C
	ld	a,(hl)
	ld	(xpmp_channel2.dataPtr+1),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_D
	ld	a,(hl)
	ld	(xpmp_channel3.dataPtr),a
	.ENDIF
	inc	hl
	.IFDEF XPMP_ENABLE_CHANNEL_D
	ld	a,(hl)
	ld	(xpmp_channel3.dataPtr+1),a
	.ENDIF
	
	.IFDEF XPMP_ENABLE_CHANNEL_A
	ld	hl,xpmp_channel0.loop1-1
	ld	(xpmp_channel0.loopPtr),hl
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_B
	ld	hl,xpmp_channel1.loop1-1
	ld	(xpmp_channel1.loopPtr),hl
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_C
	ld	hl,xpmp_channel2.loop1-1
	ld	(xpmp_channel2.loopPtr),hl
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_D
	ld	hl,xpmp_channel3.loop1-1
	ld	(xpmp_channel3.loopPtr),hl
	.ENDIF
	
	; Initialize the delays for all channels to 1
	ld 	a,1
	.IFDEF XPMP_ENABLE_CHANNEL_A
	ld	(xpmp_channel0.delay+1),a
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_B
	ld	(xpmp_channel1.delay+1),a
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_C
	ld	(xpmp_channel2.delay+1),a
	.ENDIF
	.IFDEF XPMP_ENABLE_CHANNEL_D
	ld	(xpmp_channel3.delay+1),a
	.ENDIF
	
	; Generate white noise by default
	ld	a,4
	.IFDEF XPMP_ENABLE_CHANNEL_D
	ld	(xpmp_channel3.duty),a
	.ENDIF
	
	ld	a,$FF
	ld	(xpmp_pan),a
	
	ret


.macro XPMP_COMMANDS

; Note / rest
xpmp_\1_cmd_00:
	ld	hl,(xpmp_tempw)
xpmp_\1_cmd_00_2:
	ld	a,(xpmp_channel\1.note)
	ld	(xpmp_lastNote),a
	ld	a,c
	and	$0F
	ld	(xpmp_channel\1.note),a
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	inc	de
	ld	(xpmp_channel\1.dataPos),de
	inc	hl
	ld	a,(hl)
	bit	7,a
	jr	z,xpmp_\1_cmd_00_short_note
		inc	de
		ld	(xpmp_channel\1.dataPos),de
		inc	hl
		res	7,a
		ld	d,a
		srl	d
		rrc	a
		and	$80
		ld	e,(hl)
		or	e
		ld	e,a
		inc	hl
		ld	a,(xpmp_channel\1.delay)	
		add	a,(hl)
		ld	(xpmp_channel\1.delay),a	; Fractional part
		ld	hl,0 
		adc	hl,de
		ld	(xpmp_channel\1.delay+1),hl	; Whole part
		jp 	xpmp_\1_cmd_00_got_delay
	xpmp_\1_cmd_00_short_note:
	ld	d,0
	ld	e,a
	inc	hl
	ld	a,(xpmp_channel\1.delay)	
	add	a,(hl)
	ld	(xpmp_channel\1.delay),a	; Fractional part
	ld	hl,0 
	adc	hl,de
	ret	z
	ld	(xpmp_channel\1.delay+1),hl	; Whole part
	xpmp_\1_cmd_00_got_delay:
	ld	a,2
	ld	(xpmp_freqChange),a
	;xpmp_\1_cmd_00_zero_delay:
	ld	a,(xpmp_channel\1.note)
	cp	CMD_REST	
	ret	z				; If this was a rest command we can return now
	.IFNDEF XPMP_VMAC_NOT_USED
	ld	a,(xpmp_channel\1.vMac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_v_mac		; Reset effects as needed..
	.ENDIF
	.IF \1 < 3
	.IFNDEF XPMP_ENMAC_NOT_USED
	ld	a,(xpmp_channel\1.enMac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_en_mac
	.ENDIF
	.IFNDEF XPMP_EN2MAC_NOT_USED
	ld	a,(xpmp_channel\1.en2Mac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_en2_mac
	.ENDIF
	.IF \1 < 3
	.IF \1 != 1
	.IFNDEF XPMP_MPMAC_NOT_USED
	ld	a,(xpmp_channel\1.mpMac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_mp_mac
	.ENDIF
	.ENDIF
	.IFNDEF XPMP_EPMAC_NOT_USED
	ld	a,(xpmp_channel\1.epMac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_ep_mac
	.ENDIF
	.ENDIF
	.IFDEF XPMP_GAME_GEAR
	ld	a,(xpmp_channel\1.csMac)
	cp	EFFECT_DISABLED
	call	nz,xpmp_\1_reset_cs_mac
	.ENDIF
	.ENDIF
	ld	hl,(xpmp_channel\1.cbEvnote)
	ld	a,h
	or	l
	ret	z
	jp	(hl)				; If a callback has been set for EVERY-NOTE we call it now

; Set octave
xpmp_\1_cmd_10:
	;ld	hl,(xpmp_tempw)
	ld	a,c 
	and	$0F
	sub	2				; Minimum octave is 2
	ld	b,a
	add	a,a
	add	a,a
	sla	b
	sla	b
	sla	b
	add	a,b				; A = (C & $0F) * 12
	ld	(xpmp_channel\1.octave),a
	ret
	
xpmp_\1_cmd_20:
	.IF \1 == 3
	ld	hl,(xpmp_tempw)
	ld	a,c
	and	1
	xor	1
	add	a,a
	add	a,a
	ld	(xpmp_channel\1.duty),a
	.ENDIF
	ret

; Set volume (short)
xpmp_\1_cmd_30:
	;ld	hl,(xpmp_tempw)
	ld	a,c
	and	$0F
	ld	(xpmp_channel\1.volume),a
	ld	a,1
	ld	(xpmp_volChange),a		; Volume has changed
	ld	a,EFFECT_DISABLED
	ld	(xpmp_channel\1.vMac),a		; Volume set overrides volume macros
	ret

; Octave up + note	
xpmp_\1_cmd_40:
	ld	hl,(xpmp_tempw)
	ld	a,(xpmp_channel\1.octave)
	add	a,12
	ld	(xpmp_channel\1.octave),a
	jp	xpmp_\1_cmd_00_2

; Octave down + note
xpmp_\1_cmd_50:
	ld	hl,(xpmp_tempw)
	ld	a,(xpmp_channel\1.octave)
	sub	12
	ld	(xpmp_channel\1.octave),a
	jp	xpmp_\1_cmd_00_2

xpmp_\1_cmd_60:
	;ld	hl,(xpmp_tempw)
;	ret
xpmp_\1_cmd_70:
	;ld	hl,(xpmp_tempw)
;	ret
xpmp_\1_cmd_80:
	;ld	hl,(xpmp_tempw)
	ret

; Turn off arpeggio macro
xpmp_\1_cmd_90:
	ld	a,c
	cp	CMD_JSR
	jr	z,xpmp_\1_cmd_90_jsr
	cp	CMD_RTS
	jr	z,xpmp_\1_cmd_90_rts

	.IF \1 < 3
	ld	hl,(xpmp_tempw)
	ld	a,0
	ld	(xpmp_channel\1.enMac),a
	ld	(xpmp_channel\1.en2Mac),a
	ld	(xpmp_channel\1.noteOffs),a
	.ENDIF
	ret

	xpmp_\1_cmd_90_jsr:
	.IF \1 < 3
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.oldPos),de
	ld	de,(xpmp_channel\1.dataPtr)
	ld	(xpmp_channel\1.returnAddr),de
	ld	hl,(xpmp_tempw)
	inc	hl
	ld	a,(hl)
	ld	de,xpmp_pattern_tbl
	ld	h,0
	add	a,a
	ld	l,a
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ld	(xpmp_channel\1.dataPtr),de
	ld	a,$FF
	ld	(xpmp_channel\1.dataPos),a
	ld	(xpmp_channel\1.dataPos+1),a
	.ENDIF
	ret
	
	xpmp_\1_cmd_90_rts:
	.IF \1 < 3
	ld	de,(xpmp_channel\1.returnAddr)
	ld	(xpmp_channel\1.dataPtr),de
	ld	de,(xpmp_channel\1.oldPos)
	ld	(xpmp_channel\1.dataPos),de
	.ENDIF
	ret
	
xpmp_\1_cmd_A0:
	;ld	hl,(xpmp_tempw)
;	ret
xpmp_\1_cmd_B0:
	;ld	hl,(xpmp_tempw)
;	ret
xpmp_\1_cmd_C0:
	;ld	hl,(xpmp_tempw)
;	ret
xpmp_\1_cmd_D0:
	;ld	hl,(xpmp_tempw)
	ret

; Callback
xpmp_\1_cmd_E0:
	ld	hl,(xpmp_tempw)
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de
	ld	a,c
	;cp	CMD_CBOFF
	;jr	z,xpmp_\1_cmd_E0_cboff
	;cp	CMD_CBONCE
	;jr	z,xpmp_\1_cmd_E0_cbonce
	;cp	CMD_CBEVNT
	;jr	z,xpmp_\1_cmd_E0_cbevnt
	.IF \1 < 3
	cp	CMD_DETUNE
	jr	z,xpmp_\1_cmd_E0_detune
	.ENDIF
	ret

	.IF \1 > 3
	xpmp_\1_cmd_E0_cboff:
	ld	a,0
	ld	(xpmp_channel\1.cbEvnote),a
	ld	(xpmp_channel\1.cbEvnote+1),a
	ret
	
	xpmp_\1_cmd_E0_cbonce:
	inc	hl
	ld	a,(hl)
	ld	de,xpmp_callback_tbl
	ld	h,0
	add	a,a
	ld	l,a
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	jp	(hl)
	
	; Every note
	xpmp_\1_cmd_E0_cbevnt:
	inc	hl
	ld	a,(hl)
	ld	de,xpmp_callback_tbl
	ld	h,0
	add	a,a
	ld	l,a
	add	hl,de
	ld	a,(hl)
	ld	(xpmp_channel\1.cbEvnote),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.cbEvnote+1),a
	ret
	.ENDIF
	
	.IF \1 < 3
	xpmp_\1_cmd_E0_detune:
	inc	hl
	ld	e,(hl)
	ld	d,0
	bit	7,e
	jr	z,xpmp_\1_cmd_E0_detune_pos
	ld	d,$FF
	xpmp_\1_cmd_E0_detune_pos:
	ld	(xpmp_channel\1.detune),de
	ret
	.ENDIF
	
xpmp_\1_cmd_F0:
	ld	hl,(xpmp_tempw)
	; Initialize volume macro	
	ld	a,c

	.IFNDEF XPMP_VMAC_NOT_USED
	cp	CMD_VOLMAC
	.IF \1 < 3
	jr	nz,xpmp_\1_cmd_F0_check_VIBMAC
	.ELSE
	jr	nz,xpmp_\1_cmd_F0_check_JMP
	.ENDIF
	inc	hl
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	a,(hl)
	ld	(xpmp_channel\1.vMac),a
	ld	(xpmp_channel\1.dataPos),de
	xpmp_\1_reset_v_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_v_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)	
	ld	(xpmp_channel\1.vMacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.vMacPtr+1),a
	ld	hl,(xpmp_channel\1.vMacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.volume),a
	ld	a,1
	ld	(xpmp_volChange),a	
	ld	a,1
	ld	(xpmp_channel\1.vMacPos),a
	ret
	.ENDIF
	
	.IF \1 < 3
	xpmp_\1_cmd_F0_check_VIBMAC:
	.IFNDEF XPMP_MPMAC_NOT_USED
	.IF \1 != 1
	; Initialize vibrato macro
	cp	CMD_VIBMAC
	jr	nz,xpmp_\1_cmd_F0_check_SWPMAC
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de	
	inc	hl
	ld	a,(hl)
	cp	EFFECT_DISABLED
	jr	z,xpmp_\1_cmd_F0_disable_VIBMAC
	ld	(xpmp_channel\1.mpMac),a
	xpmp_\1_reset_mp_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_MP_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)
	ld	(xpmp_channel\1.mpMacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.mpMacPtr+1),a
	ld	hl,(xpmp_channel\1.mpMacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.mpMacDelay),a
	inc	hl
	ld	(xpmp_channel\1.mpMacPtr),hl
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.freqOffsLatch),a
	ld	a,0
	ld	(xpmp_channel\1.freqOffsLatch+1),a
	ld	(xpmp_channel\1.freqOffs),a
	ld	(xpmp_channel\1.freqOffs+1),a
	ret
	xpmp_\1_cmd_F0_disable_VIBMAC:
	ld	(xpmp_channel\1.mpMac),a
	ld	(xpmp_channel\1.freqOffs),a
	ld	(xpmp_channel\1.freqOffs+1),a
	ret
	.ENDIF
	.ENDIF
	
	; Initialize sweep macro
	xpmp_\1_cmd_F0_check_SWPMAC:
	.IFNDEF XPMP_EPMAC_NOT_USED
	cp	CMD_SWPMAC
	jr	nz,xpmp_\1_cmd_F0_check_JMP
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de	
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.epMac),a
	cp	EFFECT_DISABLED
	jr	z,xpmp_\1_cmd_F0_disable_SWPMAC	
	xpmp_\1_reset_ep_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_EP_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)	
	ld	(xpmp_channel\1.epMacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.epMacPtr+1),a
	ld	hl,(xpmp_channel\1.epMacPtr)
	ld	a,1
	ld	(xpmp_channel\1.epMacPos),a
	dec	a
	ld	(xpmp_channel\1.freqOffs+1),a
	ld	a,(hl)
	ld	(xpmp_channel\1.freqOffs),a
	bit	7,a
	ret	z
	ld	a,$FF
	ld	(xpmp_channel\1.freqOffs+1),a
	ret
	xpmp_\1_cmd_F0_disable_SWPMAC:
	ld	(xpmp_channel\1.epMac),a
	ld	(xpmp_channel\1.freqOffs),a
	ld	(xpmp_channel\1.freqOffs+1),a
	ret
	.ENDIF
	.ENDIF
	
	; Jump
	xpmp_\1_cmd_F0_check_JMP:
	cp	CMD_JMP
	jr	nz,xpmp_\1_cmd_F0_check_LOPCNT
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	dec	de				; dataPos will be increased after the return, so we decrease it here
	ld	(xpmp_channel\1.dataPos),de
	ret

	; Set loop count
	xpmp_\1_cmd_F0_check_LOPCNT:
	cp	CMD_LOPCNT
	jr	nz,xpmp_\1_cmd_F0_check_DJNZ
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de	
	inc	hl
	ld	a,(hl)
	ld	hl,(xpmp_channel\1.loopPtr)
	inc	hl
	ld	(hl),a
	ld	(xpmp_channel\1.loopPtr),hl
	ret

	; Decrease and jump if not zero
	xpmp_\1_cmd_F0_check_DJNZ:
	cp	CMD_DJNZ
	jr	nz,xpmp_\1_cmd_F0_check_APMAC2
	ld	hl,(xpmp_channel\1.loopPtr)
	dec	(hl)
	jr	z,xpmp_\1_cmd_F0_DJNZ_Z		; Check if the counter has reached zero
	ld	hl,(xpmp_tempw)
	inc	hl
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	dec	de				; dataPos will be increased after the return, so we decrease it here
	ld	(xpmp_channel\1.dataPos),de
	ret
	xpmp_\1_cmd_F0_DJNZ_Z:
	dec	hl
	ld	(xpmp_channel\1.loopPtr),hl
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	inc	de
	ld	(xpmp_channel\1.dataPos),de	
	ret
	
	; Initialize non-cumulative arpeggio macro
	xpmp_\1_cmd_F0_check_APMAC2:
	.IF \1 < 3
	.IFNDEF XPMP_EN2MAC_NOT_USED
	cp	CMD_APMAC2
	jr	nz,xpmp_\1_cmd_F0_check_ARPMAC
	inc	hl
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	a,(hl)
	ld	(xpmp_channel\1.en2Mac),a
	ld	(xpmp_channel\1.dataPos),de
	xpmp_\1_reset_en2_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_EN_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)	
	ld	(xpmp_channel\1.en2MacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.en2MacPtr+1),a
	ld	hl,(xpmp_channel\1.en2MacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.noteOffs),a
	ld	a,1
	ld	(xpmp_channel\1.en2MacPos),a
	dec	a
	ld	(xpmp_channel\1.enMac),a
	ret
	.ENDIF
	.ENDIF
	
	; Initialize non-cumulative arpeggio macro
	xpmp_\1_cmd_F0_check_ARPMAC:
	.IF \1 < 3
	.IFNDEF XPMP_ENMAC_NOT_USED
	cp	CMD_ARPMAC
	jr	nz,xpmp_\1_cmd_F0_check_PANMAC
	inc	hl
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	a,(hl)
	ld	(xpmp_channel\1.enMac),a
	ld	(xpmp_channel\1.dataPos),de
	xpmp_\1_reset_en_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_EN_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)	
	ld	(xpmp_channel\1.enMacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.enMacPtr+1),a
	ld	hl,(xpmp_channel\1.enMacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.noteOffs),a
	ld	a,1
	ld	(xpmp_channel\1.enMacPos),a
	dec	a
	ld	(xpmp_channel\1.en2Mac),a
	ret
	.ENDIF
	.ENDIF
	
	xpmp_\1_cmd_F0_check_PANMAC:
	.IF \1 > 3
	cp	CMD_PANMAC
	jr	nz,xpmp_\1_cmd_F0_check_END
	inc	hl
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de
	ld	a,(hl)
	ld	(xpmp_channel\1.csMac),a
	cp	EFFECT_DISABLED
	jr	z,xpmp_\1_cs_off
	xpmp_\1_reset_cs_mac:
	dec	a
	add	a,a
	ld	hl,xpmp_CS_mac_tbl
	ld	d,0
	ld	e,a
	add	hl,de
	ld	a,(hl)	
	ld	(xpmp_channel\1.csMacPtr),a
	inc	hl
	ld	a,(hl)
	ld	(xpmp_channel\1.csMacPtr+1),a
	ld	hl,(xpmp_channel\1.csMacPtr)
	ld	a,1
	ld	(xpmp_channel\1.csMacPos),a
	ld	a,(hl)
	xpmp_\1_write_pan:
	bit	7,a
	jr	z,xpmp_\1_reset_cs_pos
	ld	a,(xpmp_pan)
	res	\1,a
	set	4+\1,a
	ld	(xpmp_pan),a
	.IFDEF	XPMP_GAME_GEAR
	out	($06),a
	.ENDIF
	ret
	xpmp_\1_reset_cs_pos:
	cp	0
	jr	nz,xpmp_\1_reset_cs_right
	xpmp_\1_cs_off:
	ld	a,(xpmp_pan)
	or	$11<<\1
	ld	(xpmp_pan),a
	.IFDEF	XPMP_GAME_GEAR
	out	($06),a
	.ENDIF
	ret
	xpmp_\1_reset_cs_right:
	ld	a,(xpmp_pan)
	res	4+\1,a
	set	\1,a
	ld	(xpmp_pan),a
	.IFDEF	XPMP_GAME_GEAR
	out	($06),a
	.ENDIF
	.ENDIF
	ret
	
	xpmp_\1_cmd_F0_check_END:
	cp	CMD_END
	jr	nz,xpmp_\1_cmd_F0_not_found
	ld	a,CMD_END
	ld	(xpmp_channel\1.note),a		; Playback of this channel should end
	ld	a,2
	ld	(xpmp_freqChange),a		; The command-reading loop should exit	
	ret

	xpmp_\1_cmd_F0_not_found:
	ld	de,(xpmp_channel\1.dataPos)
	inc	de
	ld	(xpmp_channel\1.dataPos),de	
	
	ret
.endm	


xpmp_call_hl:
	jp (hl)
	


.MACRO XPMP_UPDATE_FUNC 

xpmp_\1_update:
	ld	a,0
	ld	(xpmp_freqChange),a
	ld	(xpmp_volChange),a
	
	ld	a,(xpmp_channel\1.note)
	cp	CMD_END
	ret	z				; Playback has ended for this channel - all processing should be skipped
	
	ld 	hl,(xpmp_channel\1.delay+1)	; Decrement the whole part of the delay and check if it has reached zero
	dec	hl
	ld	a,h
	or	l
	jp 	nz,xpmp_\1_update_effects	
	
	; Loop here until a note/rest or END command is read (signaled by xpmp_freqChange == 2)
	xpmp_\1_update_read_cmd:
	ld	hl,(xpmp_channel\1.dataPtr)
	ld 	de,(xpmp_channel\1.dataPos)
	add 	hl,de
	ld 	c,(hl)
	ld	(xpmp_tempw),hl			; Store HL for later use
	ld	a,c
	srl	a
	srl	a
	srl	a
	res	0,a				; A = (C>>3)&~1 = (C>>4)<<1
	ld	l,a
	ld	h,0
	ld	de,xpmp_\1_jump_tbl	
	add	hl,de
	ld	e,(hl)				; HL = jump_tbl + (command >> 4)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	call	xpmp_call_hl

	ld	hl,(xpmp_channel\1.dataPos)
	inc	hl
	ld	(xpmp_channel\1.dataPos),hl

	ld	a,(xpmp_freqChange)
	cp	2
	jr	z,xpmp_update_\1_freq_change
	jp 	xpmp_\1_update_read_cmd
	
	xpmp_update_\1_freq_change:	
	ld	a,(xpmp_channel\1.note)
	cp	CMD_REST
	jp	z,xpmp_\1_rest
	cp	CMD_END
	jp	z,xpmp_\1_rest
	ld	b,a
	ld	a,(xpmp_channel\1.noteOffs)
	add	a,b
	.IF \1 < 3
	ld	b,a
	ld	a,(xpmp_channel\1.octave)
	add	a,b
	ld	hl,xpmp_freq_tbl
	ld	d,0
	add	a,a
	ld	e,a
	add	hl,de
	ld	e,(hl)
	inc	hl
	ld	d,(hl)
	ex	de,hl
	ld	de,(xpmp_channel\1.freqOffs)
	and	a
	sbc	hl,de
	ld	de,(xpmp_channel\1.detune)
	and	a
	sbc	hl,de
	JL_IMM16 $03EF,xpmp_updqte_\1_lb_ok
	ld	hl,(xpmp_freq_tbl+18)
	jp	xpmp_update_\1_freq_ok
	xpmp_updqte_\1_lb_ok:
	JGE_IMM16 $001C,xpmp_update_\1_freq_ok
	ld	hl,$001C
	xpmp_update_\1_freq_ok:
	ld	a,l
	and	$0F
	or	\1<<5|$80
	out	($7F),a
	ld	a,h
	sla	l		
	rla			
	sla	l
	rla	
	sla	l
	rla	
	sla	l
	rla	
	out	($7F),a
	.ELSE
	and	3
	ld	b,a
	ld	a,(xpmp_channel3.duty)
	or	b
	or	$E0
	out	($7F),a
	xor	$E0
	out	($7F),a
	.ENDIF
	ld	a,(xpmp_lastNote)
	cp	CMD_REST
	jr	nz,xpmp_\1_update_set_vol2
	jp	xpmp_\1_update_set_vol3

	xpmp_\1_update_set_vol:
	ld	a,(xpmp_channel\1.note)
	cp	CMD_REST
	jr	z,xpmp_\1_rest
	xpmp_\1_update_set_vol2:
	; Update the volume if it has changed
	ld	a,(xpmp_volChange)
	cp	0
	ret	z
	xpmp_\1_update_set_vol3:
	ld	a,(xpmp_channel\1.volume)
	xor	$9F|(\1<<5)
	out	($7F),a
	res	7,a
	out	($7F),a
	xpmp_update_\1_no_vol_change:
	ret
	
	; Mute the channel
	xpmp_\1_rest:
	ld	a,$9F|(\1<<5)
	out	($7F),a
	res	7,a
	out	($7F),a
	ret

	xpmp_\1_update_effects:
	ld 	(xpmp_channel\1.delay+1),hl

	.IFNDEF XPMP_VMAC_NOT_USED
	; Volume macro
	ld 	a,(xpmp_channel\1.vMac)
	cp 	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_v_done 
	xpmp_update_\1_v:
	ld 	hl,(xpmp_channel\1.vMacPtr)
	ld	a,1
	ld	(xpmp_volChange),a
	ld 	d,0
	ld 	a,(xpmp_channel\1.vMacPos)
	ld 	e,a
	add 	hl,de				; Add macro position to pointer
	ld 	a,(hl)
	cp 	128				; If we read a value of 128 we should loop
	jr 	z,xpmp_update_\1_v_loop
	ld	(xpmp_channel\1.volume),a 	; Set a new volume
	inc	de				; Increase the position
	ld	a,e
	ld	(xpmp_channel\1.vMacPos),a
	jp	xpmp_update_\1_v_done
	xpmp_update_\1_v_loop:
	ld	a,(xpmp_channel\1.vMac)		; Which volume macro are we using?
	dec	a
	ld	e,a
	sla	e				; Each pointer is two bytes
	ld	bc,xpmp_v_mac_loop_tbl
	ld	hl,xpmp_channel\1.vMacPtr
	ex	de,hl
	add	hl,bc 				; HL = xpmp_vMac_loop_tbl + (vMac - 1)*2
	ld	a,(hl)				; Read low byte of pointer
	ld	(de),a				; Store in xpmp_\1_vMac_ptr
	inc 	de	
	inc	hl
	ld	a,(hl)				; Read high byte of pointer
	ld	(de),a
	ld	a,1
	ld	(xpmp_channel\1.vMacPos),a
	ld	hl,(xpmp_channel\1.vMacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.volume),a
	xpmp_update_\1_v_done:
	.ENDIF
	
	.IF \1 < 3
	.IFNDEF XPMP_ENMAC_NOT_USED
	; Cumulative arpeggio
	ld 	a,(xpmp_channel\1.enMac)
	cp	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_EN_done
	xpmp_update_\1_EN:
	ld	a,1
	ld	(xpmp_freqChange),a		; Frequency has changed, but we haven't read a new note/rest yet
	ld	hl,(xpmp_channel\1.enMacPtr)
	ld 	d,0
	ld 	a,(xpmp_channel\1.enMacPos)
	ld 	e,a
	add 	hl,de				; Add macro position to pointer
	ld 	a,(hl)
	cp 	128				; If we read a value of 128 we should loop
	jr 	z,xpmp_update_\1_EN_loop
	ld	b,a
	ld	a,(xpmp_channel\1.noteOffs)
	add	a,b
	ld	(xpmp_channel\1.noteOffs),a	; Number of semitones to offset the current note by
	inc	de				; Increase the position
	ld	a,e				
	ld	(xpmp_channel\1.enMacPos),a
	jp	xpmp_update_\1_EN_done		
	xpmp_update_\1_EN_loop:
	ld	a,(xpmp_channel\1.enMac)	; Which arpeggio macro are we using?
	dec	a
	add	a,a				; Each pointer is two bytes
	ld	e,a
	ld	hl,xpmp_channel\1.enMacPtr
	ld	bc,xpmp_EN_mac_loop_tbl
	ex	de,hl
	add	hl,bc				; HL = xpmp_EN_mac_loop_tbl + (enMac - 1)*2
	ld	a,(hl)				; Read low byte of pointer
	ld	(de),a
	inc 	de
	inc	hl
	ld	a,(hl)				; Read high byte of pointer
	ld	(de),a
	ld	a,1
	ld	(xpmp_channel\1.enMacPos),a	; Reset position
	ld	hl,(xpmp_channel\1.enMacPtr)
	ld	b,(hl)
	ld	a,(xpmp_channel\1.noteOffs)
	add	a,b
	ld	(xpmp_channel\1.noteOffs),a	; Reset note offset
	xpmp_update_\1_EN_done:
	.ENDIF
	
	.IFNDEF XPMP_EN2MAC_NOT_USED
	; Non-cumulative arpeggio
	ld 	a,(xpmp_channel\1.en2Mac)
	cp	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_EN2_done
	xpmp_update_\1_EN2:
	ld	a,1
	ld	(xpmp_freqChange),a		; Frequency has changed, but we haven't read a new note/rest yet
	ld	hl,(xpmp_channel\1.en2MacPtr)
	ld 	d,0
	ld 	a,(xpmp_channel\1.en2MacPos)
	ld 	e,a
	add 	hl,de				; Add macro position to pointer
	ld 	a,(hl)
	cp 	128				; If we read a value of 128 we should loop
	jr 	z,xpmp_update_\1_EN2_loop
	ld	(xpmp_channel\1.noteOffs),a	; Number of semitones to offset the current note by
	inc	de				; Increase the position
	ld	a,e				
	ld	(xpmp_channel\1.en2MacPos),a
	jp	xpmp_update_\1_EN2_done		
	xpmp_update_\1_EN2_loop:
	ld	a,(xpmp_channel\1.en2Mac)	; Which arpeggio macro are we using?
	dec	a
	add	a,a				; Each pointer is two bytes
	ld	e,a
	ld	hl,xpmp_channel\1.en2MacPtr
	ld	bc,xpmp_EN_mac_loop_tbl
	ex	de,hl
	add	hl,bc				; HL = xpmp_EN_mac_loop_tbl + (en2Mac - 1)*2
	ld	a,(hl)				; Read low byte of pointer
	ld	(de),a
	inc 	de
	inc	hl
	ld	a,(hl)				; Read high byte of pointer
	ld	(de),a
	ld	a,1
	ld	(xpmp_channel\1.en2MacPos),a	; Reset position
	ld	hl,(xpmp_channel\1.en2MacPtr)
	ld	a,(hl)
	ld	(xpmp_channel\1.noteOffs),a	; Reset note offset
	xpmp_update_\1_EN2_done:
	.ENDIF
	
	.IF \1 < 3
	.IFNDEF XPMP_EPMAC_NOT_USED
	; Sweep macro
	ld 	a,(xpmp_channel\1.epMac)
	cp	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_EP_done
	xpmp_update_\1_EP:
	ld	a,1
	ld	(xpmp_freqChange),a		; Frequency has changed, but we haven't read a new note/rest yet
	ld	hl,(xpmp_channel\1.epMacPtr)
	ld 	d,0
	ld 	a,(xpmp_channel\1.epMacPos)
	ld 	e,a
	add 	hl,de				; Add macro position to pointer
	ld 	a,(hl)
	cp 	128				; If we read a value of 128 we should loop
	jr 	z,xpmp_update_\1_EP_loop
	ld	b,a
	inc	de				; Increase the position
	ld	a,e				
	ld	(xpmp_channel\1.epMacPos),a
	ld	e,b
	ld	d,0
	bit	7,b
	jr	z,xpmp_update_\1_pos_freq
	ld	d,$FF
	xpmp_update_\1_pos_freq:
	ld	hl,(xpmp_channel\1.freqOffs)
	add	hl,de
	ld	(xpmp_channel\1.freqOffs),hl
	jp	xpmp_update_\1_EP_done		
	xpmp_update_\1_EP_loop:
	ld	a,(xpmp_channel\1.epMac)	; Which sweep macro are we using?
	dec	a
	add	a,a				; Each pointer is two bytes
	ld	e,a
	ld	hl,xpmp_channel\1.epMacPtr
	ld	bc,xpmp_EP_mac_loop_tbl
	ex	de,hl
	add	hl,bc				; HL = xpmp_EP_mac_loop_tbl + (epMac - 1)*2
	ld	a,(hl)				; Read low byte of pointer
	ld	(de),a
	inc 	de
	inc	hl
	ld	a,(hl)				; Read high byte of pointer
	ld	(de),a
	ld	a,1
	ld	(xpmp_channel\1.epMacPos),a	; Reset position
	ld	hl,(xpmp_channel\1.epMacPtr)
	ld	e,(hl)
	ld	d,0
	bit	7,e
	jr	z,xpmp_update_\1_pos_freq_2
	ld	d,$FF
	xpmp_update_\1_pos_freq_2:
	ld	hl,(xpmp_channel\1.freqOffs)
	add	hl,de
	ld	(xpmp_channel\1.freqOffs),hl
	xpmp_update_\1_EP_done:
	.ENDIF
	
	.IF \1 != 1
	.IFNDEF XPMP_MPMAC_NOT_USED
	; Vibrato
	ld 	a,(xpmp_channel\1.mpMac)
	cp	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_MP_done
	ld	a,(xpmp_channel\1.mpMacDelay)
	dec	a
	jr 	nz,xpmp_update_\1_MP_done2
	xpmp_update_\1_MP:
	ld	a,1
	ld	(xpmp_freqChange),a		; Volume has changed
	ld	hl,(xpmp_channel\1.mpMacPtr)
	ld	de,(xpmp_channel\1.freqOffsLatch) ; Load the volume offset from the latch, then negate the latch
	ld	(xpmp_channel\1.freqOffs),de
	and	a				; Clear carry
	ld 	a,(hl)				; Reload the vibrato delay
	ld	hl,0
	sbc	hl,de
	ld	(xpmp_channel\1.freqOffsLatch),hl
	xpmp_update_\1_MP_done2:
	ld	(xpmp_channel\1.mpMacDelay),a
	xpmp_update_\1_MP_done:
	.ENDIF
	.ENDIF
	.ENDIF

	.IFDEF XPMP_GAME_GEAR
	; Channel separation (pan) macro
	ld 	a,(xpmp_channel\1.csMac)
	cp	EFFECT_DISABLED
	jr 	z,xpmp_update_\1_CS_done
	xpmp_update_\1_CS:
	ld	hl,(xpmp_channel\1.csMacPtr)
	ld 	d,0
	ld 	a,(xpmp_channel\1.csMacPos)
	ld 	e,a
	add 	hl,de				; Add macro position to pointer
	ld 	a,(hl)
	cp 	128				; If we read a value of 128 we should loop
	jr 	z,xpmp_update_\1_CS_loop
	ld	b,a

	inc	de				; Increase the position
	ld	a,e				
	ld	(xpmp_channel\1.csMacPos),a
	jp	xpmp_update_\1_CS_do_write		
	xpmp_update_\1_CS_loop:
	ld	a,(xpmp_channel\1.csMac)	; Which pan macro are we using?
	dec	a
	add	a,a				; Each pointer is two bytes
	ld	e,a
	ld	hl,xpmp_channel\1.csMacPtr
	ld	bc,xpmp_CS_mac_loop_tbl
	ex	de,hl
	add	hl,bc				; HL = xpmp_CS_mac_loop_tbl + (csMac - 1)*2
	ld	a,(hl)				; Read low byte of pointer
	ld	(de),a
	inc 	de
	inc	hl
	ld	a,(hl)				; Read high byte of pointer
	ld	(de),a
	ld	a,1
	ld	(xpmp_channel\1.csMacPos),a	; Reset position
	ld	hl,(xpmp_channel\1.csMacPtr)
	ld	b,(hl)
	xpmp_update_\1_CS_do_write:
	ld	a,b
	call	xpmp_\1_write_pan
	xpmp_update_\1_CS_done:
	.ENDIF
	.ENDIF
	
	ld	a,(xpmp_freqChange)
	cp	0
	jp	nz,xpmp_update_\1_freq_change
	jp	xpmp_\1_update_set_vol
	
 .ENDM


.IFDEF XPMP_ENABLE_FM
.ENDIF


.IFDEF XPMP_ENABLE_CHANNEL_A
 XPMP_COMMANDS 0
 XPMP_UPDATE_FUNC 0
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_B
 XPMP_COMMANDS 1
 XPMP_UPDATE_FUNC 1
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_C
 XPMP_COMMANDS 2
 XPMP_UPDATE_FUNC 2
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_D
 XPMP_COMMANDS 3
 XPMP_UPDATE_FUNC 3
.ENDIF


xpmp_update:
.IFDEF XPMP_ENABLE_CHANNEL_A
	call xpmp_0_update
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_B
	call xpmp_1_update
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_C
	call xpmp_2_update
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_D
	call xpmp_3_update
.ENDIF
ret
	

.MACRO XPMP_JUMP_TABLE
xpmp_\1_jump_tbl:
.dw xpmp_\1_cmd_00
.dw xpmp_\1_cmd_10
.dw xpmp_\1_cmd_20
.dw xpmp_\1_cmd_30
.dw xpmp_\1_cmd_40
.dw xpmp_\1_cmd_50
.dw xpmp_\1_cmd_60
.dw xpmp_\1_cmd_70
.dw xpmp_\1_cmd_80
.dw xpmp_\1_cmd_90
.dw xpmp_\1_cmd_A0
.dw xpmp_\1_cmd_B0
.dw xpmp_\1_cmd_C0
.dw xpmp_\1_cmd_D0
.dw xpmp_\1_cmd_E0
.dw xpmp_\1_cmd_F0
.ENDM


.IFDEF XPMP_ENABLE_CHANNEL_A
 XPMP_JUMP_TABLE 0
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_B
 XPMP_JUMP_TABLE 1
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_C
 XPMP_JUMP_TABLE 2
.ENDIF
.IFDEF XPMP_ENABLE_CHANNEL_D
 XPMP_JUMP_TABLE 3
.ENDIF

xpmp_freq_tbl:
.IFDEF XPMP_50_HZ
.IFDEF XPMP_TUNE_SMS
.dw $02A9,$0249,$01EF,$019A,$0149,$00FD,$00B5,$0072,$0032,$03F6,$03BD,$0387
.dw $0354,$0324,$02F7,$02CD,$02A4,$027E,$025A,$0239,$0219,$01FB,$01DE,$01C3
.dw $01AA,$0192,$017B,$0166,$0152,$013F,$012D,$011C,$010C,$00FD,$00EF,$00E1
.dw $00D5,$00C9,$00BD,$00B3,$00A9,$009F,$0096,$008E,$0086,$007E,$0077,$0070
.dw $006A,$0064,$005E,$0059,$0054,$004F,$004B,$0047,$0043,$003F,$003B,$0038
.dw $0035,$0032,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F,$001D,$001C
.ELSE
.dw $029E,$023F,$01E5,$0191,$0141,$00F5,$00AE,$006B,$002B,$03EF,$03B7,$0381
.dw $034F,$031F,$02F2,$02C8,$02A0,$027A,$0257,$0235,$0215,$01F7,$01DB,$01C0
.dw $01A7,$018F,$0179,$0164,$0150,$013D,$012B,$011A,$010A,$00FB,$00ED,$00E0
.dw $00D3,$00C7,$00BC,$00B2,$00A8,$009E,$0095,$008D,$0085,$007D,$0076,$0070
.dw $0069,$0063,$005E,$0059,$0054,$004F,$004A,$0046,$0042,$003E,$003B,$0038
.dw $0034,$0031,$002F,$002C,$002A,$0027,$0025,$0023,$0021,$001F,$001D,$001C
.ENDIF
.ELSE
.IFDEF XPMP_TUNE_SMS
.dw $02B9,$0258,$01FD,$01A7,$0156,$0109,$00C0,$007C,$003C,$03FF,$03C5,$038F
.dw $035C,$032C,$02FE,$02D3,$02AB,$0284,$0260,$023E,$021E,$01FF,$01E2,$01C7
.dw $01AE,$0196,$017F,$0169,$0155,$0142,$0130,$011F,$010F,$00FF,$00F1,$00E3
.dw $00D7,$00CB,$00BF,$00B4,$00AA,$00A1,$0098,$008F,$0087,$007F,$0078,$0071
.dw $006B,$0065,$005F,$005A,$0055,$0050,$004C,$0047,$0043,$003F,$003C,$0038
.dw $0035,$0032,$002F,$002D,$002A,$0028,$0026,$0023,$0021,$001F,$001E,$001C
.ELSE
.dw $02AE,$024E,$01F3,$019E,$014D,$0101,$00B9,$0075,$0035,$03F8,$03BF,$0389
.dw $0357,$0327,$02F9,$02CF,$02A6,$0280,$025C,$023A,$021A,$01FC,$01DF,$01C4
.dw $01AB,$0193,$017C,$0167,$0153,$0140,$012E,$011D,$010D,$00FE,$00EF,$00E2
.dw $00D5,$00C9,$00BE,$00B3,$00A9,$00A0,$0097,$008E,$0086,$007F,$0077,$0071
.dw $006A,$0064,$005F,$0059,$0054,$0050,$004B,$0047,$0043,$003F,$003B,$0038
.dw $0035,$0032,$002F,$002C,$002A,$0028,$0025,$0023,$0021,$001F,$001D,$001C
.ENDIF
.ENDIF

			


	