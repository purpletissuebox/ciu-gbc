SECTION "MUSIC PLAYER ROM", ROMX
initSong:
	updateActorMain runSong
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	ld de, song_list
	ld l, $00
	rra
	rr l
	rra
	rr l
	rra
	rr l
	ld h, a
	add hl, de
	ld e, l
	ld d, h ;de = ptr to song struct
	
	swapInRam music_stuff
	
	ld hl, note_streams
	ld c, note_streams.end - note_streams
	rst $10 ;copy note streams
	
	push de
	ld c, inst_lists.end - inst_lists
	rst $10 ;copy instrument lists
	
	xor a
	ld c, old_wave.end - music_enable
	rst $08 ;clear other variables
	
	ld a, [de]
	inc de
	ld [beat_increase], a ;tempo
	
	ld a, [de]
	swap a
	ld de, initSong.waveforms
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	xor a
	ldh [$FF1A], a
	ld c, $10
	ld hl, $FF30
	rst $10 ;copy waveform to ch3 ram
	ld a, $80
	ldh [$FF1A], a
	
	ld hl, inst_ptrs
	pop de
	ld c, inst_ptrs.end - inst_ptrs
	rst $10
	
	restoreBank "ram"
	ret
	
.waveforms:
	db $00,$11,$22,$33,$44,$55,$66,$77,$88,$99,$AA,$BB,$CC,$DD,$EE,$FF ;0 - sawtooth
	db $01,$23,$45,$67,$89,$AB,$CD,$EF,$FE,$DC,$BA,$98,$76,$54,$32,$10 ;1 - triangle
	db $89,$AC,$DE,$EF,$FF,$EE,$DC,$A9,$76,$53,$21,$10,$00,$11,$23,$56 ;2 - sine
	db $00,$00,$00,$00,$00,$00,$00,$00,$FF,$FF,$FF,$FF,$FF,$FF,$FF,$FF ;3 - square
	db $48,$48,$B5,$9B,$BB,$95,$B8,$48,$48,$49,$4A,$75,$45,$7A,$49,$48 ;4 - synth1
	db $11,$24,$7D,$85,$67,$BE,$ED,$A7,$6D,$95,$45,$75,$A0,$94,$64,$32 ;5 - buzzy lead
	db $03,$69,$CF,$CA,$85,$31,$36,$8A,$75,$8A,$DB,$97,$53,$68,$AC,$84 ;6 - synth2
	db $A8,$42,$24,$8A,$AC,$CA,$87,$8B,$DE,$DA,$65,$57,$99,$83,$10,$13 ;7 - sagaia wave
	
runSong:
	swapInRam music_stuff
	
	ld d, $00
	call tickTimer
	
	.loop: ;for each channel, load a new note if the wakeup time is less than the current time
		ld bc, chnl_timers
		ld a, d
		add a
		add d
		add c
		ld c, a
		
		ld hl, global_timer
		ld a, [bc]
		inc bc
		sub [hl]
		inc hl
		ld a, [bc]
		inc bc
		sbc [hl]
		inc hl
		ld a, [bc]
		sbc [hl]
		
		call c, loadNoteRAM
		
		inc d
		bit 2, d
	jr z, runSong.loop
	
	call updateInstrumentsRAM
	
	ld c, $10
	ld hl, chnl_statuses
	
	.loop2:
		call note2SoundRegRAM
		bit 5, c
	jr z, runSong.loop2
	restoreBank "ram"
	ret
		
tickTimer: ;d = 0
	ld hl, beat_increase
	ldi a, [hl]
	
	add [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	
	ld hl, global_timer
	ld a, $50
	
	add [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	ret

INCLUDE "../assets/music/songList.asm"

INCLUDE "../actors/general/musicPlayerRAM.asm"