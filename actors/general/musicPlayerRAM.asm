SECTION "MUSIC PLAYER RAM", ROMX

loadNote:
INCLUDE "../actors/general/musicLoadNote.asm"

updateInstruments:
	ldh a, [rom_bank]
	push af
	
	ld d, $00
	.loop:
		ld hl, inst_ptrs
		ld a, d
		add a
		add d
		add l
		ld l, a
		
		ldi a, [hl]
		ld c, a
		ldi a, [hl]
		ld b, a
		ldi a, [hl]
		ldh [rom_bank], a
		ld [$2000], a
		ld a, [bc]
		ld e, a
		
		bit 0, e
		call nz, updateDutyRAM
		bit 1, e
		call nz, updateVolumeRAM
		bit 2, e
		call nz, updatePitchRAM
		bit 3, e
		call nz, updatePCMRAM
		
		inc d
		bit 2, d
	jr z, updateInstruments.loop
	
	restoreBank "rom"
	ret
	
updateDuty:
	ld hl, inst_timers
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment timer
	
	ld hl, $0001
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to inst string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index
	
	ldi a, [hl]
	cp $FF
		jr z, updateDuty.fixTimer
	ld e, a ;e = upcoming duty value
	ld hl, chnl_statuses
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e
	
	ld a, [bc]
	ld e, a ;restore e
	ret
	
.fixTimer:
	ld e, [hl]
	ld hl, inst_timers
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e
	jr updateDuty
	
updateVolume:
	ld hl, inst_timers + 1
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment timer
	
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to inst string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index
	
	ldi a, [hl]
	cp $FF
		jr z, updateVolume.fixTimer
	ld e, a ;e = upcoming volume
	ld hl, chnl_statuses + 1
	ld a, d
	add a
	add a
	add l
	ld l, a
	
	ld a, [hl]
	and $F0
	or e
	ld e, [hl]
	ld [hl], a
	sub e
		jr z, updateVolume.done
	or $F0
	ld e, a
	
	ld hl, $FF12
	ld a, d
	add a
	add a
	add d
	add l
	ld l, a
	
	.loop:
		ld a, $09
		ld [hl], a
		ld a, $11
		ld [hl], a
		ld a, $18
		ld [hl], a
		inc e
	jr nz, updateVolume.loop
	
	.done:
	ld a, [bc]
	ld e, a ;restore e
	ret
	
.fixTimer:
	ld e, [hl]
	ld hl, inst_timers + 1
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e
	jr updateVolume
	
updatePitch:
	ld hl, inst_timers + 2
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment timer
	
	ld hl, $0005
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to inst string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index
	
	ldi a, [hl]
	cp $80
		jr z, updatePitch.fixTimer
	ld e, a ;e = upcoming duty value
	ld hl, chnl_statuses + 2
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld a, e
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	rl e
	jr nc, updatePitch.signExtend
		dec a
	.signExtend:
	ld [hl], a
	
	ld a, [bc]
	ld e, a ;restore e
	ret
	
.fixTimer:
	ld e, [hl]
	ld hl, inst_timers + 2
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e
	jr updatePitch
	
updatePCM:
	ld hl, pcm_timer
	inc [hl]
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld c, a
	ldi a, [hl]
	ld b, a
	ld a, [hl]
	ldh [rom_bank], a
	ld [$2000], a
	
	ld l, c
	ld h, b
	ld bc, $0003 ;hl = pcm struct, e = current time, bc = offset to next sample
	
	.loop:
		ldi a, [hl]
		sub e
			jr z, updatePCM.loadNewSample
			ret nc
		add hl, bc
	jr updatePCM.loop
	
	.loadNewSample:
	ldi a, [hl]
	bit 7, a
		jp nz, killPCMRAM
		
	ldh [the_sample_hi], a
	ldi a, [hl]
	ldh [the_sample_lo], a
	ldi a, [hl]
	ldh [the_sample_bank], a
	ret
	
killPCM:
	ld hl, $FF30
	ld bc, old_wave
	ld e, $10
	xor a
	ldh [$FF1C], a
	ldh [$FF1A], a
	ld [pcm_enable], a
	
	.copy:
		ld a, [bc]
		inc bc
		ldi [hl], a
		dec e
	jr nz, killPCM.copy
	
	ld l, $FF
	res 2, [hl]
	
	ld a, $80
	ldh [$FF1A], a
	ret
	
note2SoundReg:
	inc c
	bit 3, c
	jr z, note2SoundReg.ch124
		ld a, [pcm_enable]
		and a
		jr z, note2SoundReg.ch124
			inc c
			inc c
			inc c
			inc c
			ld l, $1F
			ret
	
	.ch124:
	ldi a, [hl] ;duty
	ldh [c], a
	inc c
	
	ldi a, [hl]
	ld b, a
	ldi a, [hl]
	ld e, a
	ld d, [hl]
	ld a, d ;b = vol, de = wavelength
	and $7F
	ldi [hl], a
	
	bit 7, d
	jr z, note2SoundReg.skipVol
		ld a, b
		and $F0
		or $08
		ldh [c], a
	
	.skipVol:
	inc c
	ld a, e
	ldh [c], a
	inc c
	ld a, d
	ldh [c], a
	inc c
	ret
	
frequency_table:
	INCBIN "../assets/code/freqTable.bin"
	.end