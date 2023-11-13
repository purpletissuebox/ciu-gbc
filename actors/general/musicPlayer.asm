SECTION "MUSIC PLAYER ROM", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;music related functions that live in rom
;most of the actual music driver is loaded into ram during init because they need to access data in other rom banks.
;the only functions to stay behind are for intializing a song, advancing the timer, and calling the ram code.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

initSong: ;initializes music variables accoring to a song struct (see assets/music/songList.asm)
;the struct contains a pointer to a string of notes for each channel, a pointer to an instrument array for each channel, the tempo, and a starting waveform for ch3 (total 30 bytes). 
	updateActorMain runSong
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;a = index into song list
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
	ld d, a ;index into waveform table (for now use quick and dirty *16)
	
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
	rst $10 ;initialize each instrument to ID #0
	
	ld a, $01
	ldh [music_on], a
	
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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
runSong: ;main loop for music driver
	ldh a, [music_on]
	and a
	jr nz, runSong.run
		ld e, c
		ld d, b
		call removeActor
		jp killSong
	
	.run:
	swapInRam music_stuff
	
	ld d, $00 ;optimization - we need d = 0 as a loop counter later but can use it as a fast ld a, $00 now
	call tickTimer ;advance the current timestamp
	
	.loop: ;for each channel, load a new note if the wakeup time is less than the current time
		ld bc, chnl_timers
		ld a, d
		add a
		add d
		add c
		ld c, a ;bc = chnl_timers[i]
		
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
		
		call c, loadNoteRAM ;if global_timer[i] > chnl_timer[i], load a new note
		
		inc d
		bit 2, d
	jr z, runSong.loop
	
	call updateInstrumentsRAM ;write to a note status buffer based on how the instruments change vol, pitch, duty over time
	
	ld c, $10 ;io port for ch1 pitch
	ld hl, chnl_statuses
	
	.loop2: ;for each channel
		call note2SoundRegRAM ;convert buffer to raw sound register values
		bit 5, c
	jr z, runSong.loop2
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
tickTimer: ;remember d = 0 on entry
;increase the global timer by (tempo + $50)
	ld hl, beat_increase
	ldi a, [hl] ;hl now points to global timer
	
	add [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a ;add tempo
	
	ld hl, global_timer
	ld a, $50
	
	add [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ldi [hl], a ;add $50
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

killSong:
;turn off all sound registers
	ld hl, $FF10
	ld c, $13
	xor a
	rst $08
	ret

INCLUDE "../assets/music/songList.asm"

INCLUDE "../actors/general/musicPlayerRAM.asm"