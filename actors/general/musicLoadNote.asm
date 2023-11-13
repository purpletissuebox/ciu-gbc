loadNote: ;d = channel ID
;routine to load the next note from rom
;note struct contains 1 byte for pitch, volume, length, and inst ID
;notes can have effects of various sizes, hence a string of notes rather than an array
;alternatively, the first byte can represent a loop point instead, where the next note actually comes from the pointer in the other 3 bytes
	ldh a, [rom_bank]
	push af
	
	ld hl, note_streams
	ld a, d
	add a
	add a
	add l
	ld l, a ;hl = notestream[i]
	
	ldi a, [hl]
	ld c, a
	ldi a, [hl]
	ld b, a
	ldi a, [hl]
	ldh [rom_bank], a
	ld [$2000], a ;bc = ptr to note
	
	.return:
	ld a, [bc]
	inc bc
	bit 7, a
		jp nz, loopChannelRAM ;if top bit is set, bc actually points to a loop struct instead of real note
	
	call getPitchRAM ;convert midi key to raw wavelength, ae = wavelength
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
	inc bc
	ld e, a
	swap e
	and $0F ;get volume
	ldi [hl], a
	ld a, e
	and $0F ;get effect
		call nz, doFXRAM
	
	ld hl, chnl_timers + 1
	ld a, d
	add a
	add d
	add l
	ld l, a ;hl = chnl_timers[i]
	ld a, [bc] ;get length
	inc bc
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	ld [hl], a ;add length to timer
		
	call getInstrumentRAM ;convert index to ptr to instrument, es = instrument
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
	ld [hl], a ;zero out indices for instrument so each inst string starts at the beginning
	
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
	ld a, [bc] ;check its settings byte
	bit 3, a
		call nz, loadPCMRAM ;load pcm if needed
		
	restoreBank "rom"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
getPitch: ;a = midi key
;we use a lookup table for this due to the nonlinear relationship
;0 = C-2, 49 = C#-8, 6C = percussion pitch low, 7B = percussion pitch high
;we will also set the most significant bit of the frequency to signify a new note
	ld hl, frequency_tableRAM + 1
	add a
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ldd a, [hl]
	ld e, [hl]
	set 7, a ;return (8000 | wavelength) in ae
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

getInstrument: ;d = channel ID, [bc] = instrument index
;based on the channel and the instrument ID number, returns a pointer to that instrument.
	ld hl, inst_lists
	ld a, d
	add a
	add d
	add l
	ld l, a
	ldi a, [hl]
	ld h, [hl]
	ld l, a ;hl = start of this channel's instrument array
	
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
	ld e, a ;add and return ptr in es
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
loopChannel: ;a = (80 | loop flags), [bc] = loop mask, d = channel ID
;each loop flag that is provided is XORd with the current loop status.
;a mask is used so you can write to certain flags and read from others.
;the first time around, the flags will go high and we will loop
;the second time around, the XOR will cancel them out, flags go low and we continue
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
	
	ld a, [bc] ;now the entire flag byte is toggled but we might still have unwanted flags so mask them out
	inc bc
	and e
	jr nz, loopChannel.YesLoop
		inc bc ;if they remain unset, skip the "note" 
		inc bc
		jr loopChannel.NoLoop
		
	.YesLoop:
		dec hl ;otherwise, copy in new ptr (in rom it is big endian for easy copying)
		ld a, [bc]
		inc bc
		ldd [hl], a
		ld a, [bc]
		ldi [hl], a
		ld c, a
		ld b, [hl] ;resume processing notestream at the loop point
	
	.NoLoop:
	jp loadNoteRAM + (loadNote.return - loadNote) ;proceed to load the next note, regardless of it it was forwards or backwards

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
loadPCM: ;bc = ptr to instrument.settings
;initializes pcm-related variables based on a ptr to a pcm struct
;the struct contains a start time, followed by a ptr to the wave data.
	inc bc ;[bc] = ptr to pcm struct
	
	ld hl, pcm_timer
	xor a
	ldi [hl], a ;reset timer
	
	ld a, [bc]
	inc bc
	ldi [hl], a
	ld a, [bc]
	inc bc
	ldi [hl], a
	ld a, [bc]
	ldd [hl], a ;copy ptr to pcm struct to ram
	ldh [rom_bank], a
	ld [$2000], a
	
	ldd a, [hl]
	ld l, [hl] ;go back and follow that pointer to get
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
	ldh [$FF1D], a ;set up ch3 to play frequency 0706, C-5. we dont actually want to play any sound yet though so we will leave the upper byte untouched.
	
	ld l, $FF ;hl already points to hram so we get a fast hl = FFFF
	set 2, [hl] ;enable timer interrupt
	ret ;timer interrupt will set ch3 dac, wavelength hi, trigger, etc.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

doFX: ;a = effect ID, [hl] = channel wavelength lo, [bc] = effect data
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