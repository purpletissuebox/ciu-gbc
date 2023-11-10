;loadNote: ;d = channel ID
	ldh a, [rom_bank]
	push af
	
	ld hl, note_streams
	ld a, d
	add a
	add a
	add l
	ld l, a
	
	ldi a, [hl]
	ld c, a
	ldi a, [hl]
	ld b, a
	ldi a, [hl]
	ldh [rom_bank], a
	ld [$2000], a ;bc = next note
	
	.return:
	ld a, [bc]
	inc bc
	bit 7, a
		jp nz, loopChannelRAM ;check if loop struct instead of real note
	
	call getPitchRAM ;ae = wavelength
	ld hl, chnl_statuses + 3 ;wavelength_hi
	ldh [scratch_byte], a
	ld a, d
	add a
	add a
	add l
	ld l, a
	ldh a, [scratch_byte]
	ldd [hl], a
	ld a, e
	ldd [hl], a ;save wavelength to channel status, hl now points to volume
	
	ld a, [bc]
	and $F0 ;get volume
	ld e, a
	swap e
	or e
	ld [hl], a
	ld a, [bc]
	inc bc
	and $0F ;get effect
		call nz, doFXRAM
	
	ld hl, chnl_timers + 1
	ld a, d
	add a
	add d
	add l
	ld l, a
	ld a, [bc]
	inc bc
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	ld [hl], a ;add length to timer
		
	call getInstrumentRAM ;es = instrument
	ld hl, inst_ptrs
	ld a, d
	add a
	add d
	add l
	ld l, a
	ldh a, [scratch_byte]
	ldi [hl], a
	ld a, e
	ldi [hl], a ;save instrument
	ld a, [hl]
	ldh [rom_bank], a
	ld [$2000], a
	
	ld hl, inst_timers
	ld a, d
	add a
	add a
	add l
	ld l, a
	xor a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld [hl], a ;this is the first frame for the inst
	
	ld hl, note_streams
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld a, c
	ldi [hl], a
	ld [hl], b ;update note pointer
	
	ldh a, [scratch_byte]
	ld c, a
	ld b, e ;retrieve instrument ptr
	ld a, [bc]
	bit 3, a
		call nz, loadPCMRAM
		
	restoreBank "rom"
	ret
	
getPitch:
	ld hl, frequency_tableRAM + 1
	add a
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ldd a, [hl]
	ld e, [hl]
	set 7, a
	ret
	
getInstrument:
	ld hl, inst_lists
	ld a, d
	add a
	add d
	add l
	ld l, a
	ldi a, [hl]
	ld h, [hl]
	ld l, a ;hl = start of instrument array
	
	ld a, [bc] ;instrument ID
	inc bc
	ld e, $00
	rla
	rl e
	rla
	rl e
	rla
	rl e ;ea = ID*sizeof(inst)
	
	add l
	ldh [scratch_byte], a
	ld a, e
	adc h
	ld e, a
	ret
	
loopChannel:
	and $7F ;a = loop flag(s) that should be checked
	ld e, a
	ld hl, note_streams + 3
	ld a, d
	add a
	add a
	add l
	ld l, a
	
	ld a, e
	xor [hl] ;toggle flags
	ldd [hl], a
	ld e, a ;e = new flags
	
	ld a, [bc]
	and e
	ld e, a ;e = relevant flags
	ld a, [bc]
	inc bc
	xor e
	jr z, loopChannel.YesLoop
		inc bc ;if they remain unset, skip the "note" 
		inc bc
		jr loopChannel.NoLoop
		
	.YesLoop:
		dec hl ;otherwise, copy in new ptr
		ld a, [bc]
		inc bc
		ldd [hl], a
		ld a, [bc]
		inc bc
		ldi [hl], a
		ld c, a
		ld b, [hl]
	
	.NoLoop:
	jp loadNoteRAM + (loadNote.return - loadNote)
	
loadPCM:
	ld hl, pcm_timer
	ld [hl], $00
	inc hl
	inc bc ;bc = ptr to pcm struct
	
	ld a, [bc]
	inc bc
	ldi [hl], a
	ld a, [bc]
	inc bc
	ldi [hl], a
	ld a, [bc]
	ldd [hl], a ;copy to pcm struct area
	
	ldh [rom_bank], a
	ld [$2000], a
	ldd a, [hl]
	ld l, [hl]
	ld h, a ;hl = first frame
	inc hl ;hl = first sample
	ldi a, [hl]
	ldh [the_sample_hi], a
	ldi a, [hl]
	ldh [the_sample_lo], a
	ldi a, [hl]
	ldh [the_sample_bank], a
	
	xor a
	ldh [$FF1A], a
	ld hl, $FF30
	ld bc, old_wave
	ld e, $10
	
	.loop:
		ldi a, [hl]
		ld [bc], a
		inc bc
		dec e
	jr nz, loadPCM.loop ;back up the old wave
	
	ld a, $06
	ldh [$FF1D], a
	ld l, $FF
	set 2, [hl] ;enable timer interrupt
	ret ;timer interrupt will set ch3 dac, wavelength hi, trigger, etc.
	
doFX: ;hl = channel wavelength lo
	.1: ;freq sweep
	dec a
	jr nz, doFX.2
		ld a, [bc]
		inc bc
		ldh [$FF10], a
		inc hl
		set 7, [hl]
		ret
	.2: ;new waveform
	dec a
	jr nz, doFX.3
		ldh [$FF1A], a
		ld e, $10
		ld hl, $FF30
		.loop:
			ld a, [bc]
			inc bc
			ldi [hl], a
			dec e
		jr nz, doFX.loop
		ld a, $80
		ldh [$FF1A], a
		ret
	.3: ;duty cycle
	dec a
	jr nz, doFX.4
		ld a, [bc]
		inc bc
		dec hl
		dec hl
		ld [hl], a		
	ret
	.4: ;tempo change
	dec a
	jr nz, doFX.5
		ld a, [bc]
		inc bc
		ld [tempo_change], a
	ret
	.5:
	ret