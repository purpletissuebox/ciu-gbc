SECTION "TIMER HANDLER", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;runs on a timer interrupt to reload the wave of ch3. it does so at 8kHz, so it sounds like a continuous sound.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

playSample:
	push af
	push hl
	ldh a, [$FF70]
	push af
	ldh a, [rom_bank]
	push af ;back up registers + banks
	
	ld a, BANK(music_stuff)
	ldh [$FF70], a
	ld hl, the_sample_bank
	ldd a, [hl]
	ld [$2000], a
	ldd a, [hl]
	ld l, [hl]
	ld h, a ;get ptr to sample
	
	ld a, $BB
	ldh [$FF25], a
	xor a
	ldh [$FF1A], a ;disable ch3
	
WAVEPTR = $FF30
REPT 16
	ldi a, [hl]
	ldh [WAVEPTR], a ;copy to wave ram
WAVEPTR = WAVEPTR + 1
ENDR

	ld hl, the_sample_lo
	ld a, $10
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	add $80
	res 7, a
	set 6, a ;wrap while preserving carry
	ldi [hl], a
	ld a, $00
	adc [hl]
	ld [hl], a ;increment sample pointer
	
	ld a, $80
	ldh [$FF1A], a
	ld a, $FF
	ldh [$FF25], a
	ld a, $87
	ldh [$FF1E], a ;reenable ch3
	
	restoreBank "rom"
	restoreBank "ram"
	pop hl
	pop af
	reti