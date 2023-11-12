SECTION "MUSIC PLAYER RAM", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;main music driver
;all of the music stuff runs out of here so we can switch rom banks mid execution
;the core mechanism works like this:
;each frame a timer is incremented. each channel keeps a running tally of when its next note is coming up so it can play them when the timer gets to that point.
;channels keep a pointer to their upcoming note, which contains an initial pitch, volume, and length which are copied into an intermediate "channel status" buffer. It also has an instrument ID.
;instruments contain pointers to long strings of pitch, volume, and duty cycle adjustments. they have their own timers and slowly read the strings once per frame, changing the buffer accordingly.
;at the end of each string is a terminator and an index of where to read from next frame, allowing for loops.
;the most significant bit of each note flags it as a special loop point instead. the remaining 7 bits are "loop channels" that can be nested to loop over sections multiple times.
;ch3 supports pcm playback. a special pcm string consists of a time to play a sample and a ptr to the sample data. this way notes can be separated logically while their wave data is separated physically.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMERDUTY = $0000
TIMERVOL = $0001
TIMERPITCH = $0002
TIMERPCM = $0003

INSTDUTY = $0001
INSTVOL = $0003
INSTPITCH = $0005
INSTPCM = $0001

STATUSDUTY = $0000
STATUSVOL = $0001
STATUSPITCH = $0002

;loadNote:
INCLUDE "../actors/general/musicLoadNote.asm"

updateInstruments:
;main driver for all of the instrument code
	ldh a, [rom_bank]
	push af
	
	ld d, $00 ;d = channel ID
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
		ld b, a ;bc = ptr to this channel's instrument
		ldi a, [hl]
		ldh [rom_bank], a
		ld [$2000], a
		ld a, [bc]
		ld e, a ;e = settings byte, we keep bc pointing to the instrument for simplicity
		
		bit 0, e ;each bit in the settings represents a different string to read from
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
	
updateDuty: ;bc = ptr to instrument, d = channel ID
;locates new duty value based on instrument and writes it to the current channel's status
	ld hl, inst_timers + TIMERDUTY
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment duty timer
	
	ld hl, INSTDUTY
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to duty string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index to find this frame's duty
	
	ldi a, [hl]
	cp $FF
		jr z, updateDuty.fixTimer ;if we hit a terminator, we need to adjust index for future frames
	ld e, a ;e = upcoming duty value
	ld hl, chnl_statuses + STATUSDUTY
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e ;save new duty in chnl_status
	
	ld a, [bc]
	ld e, a ;restore settings
	ret
	
.fixTimer:
	ld e, [hl] ;new index
	ld hl, inst_timers
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e ;save it over the old timer
	jr updateDuty
	
updateVolume: ;bc = ptr to instrument, d = channel ID
;locates new volume value based on instrument and writes to the current channel's io ports to set that volume
	ld hl, inst_timers + TIMERVOL
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment vol timer
	
	ld hl, INSTVOL
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to vol string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index to find this frame's vol
	
	ldi a, [hl]
	cp $FF
		jr z, updateVolume.fixTimer ;if we hit a terminator, we need to adjust for future frames
	ld e, a ;e = upcoming volume
	ld hl, chnl_statuses + STATUSVOL
	ld a, d
	add a
	add a
	add l
	ld l, a
	
	ld a, [hl] ;get old volume
	ld [hl], e ;save new volume
	sub e ;old vol - new vol = # of steps we have to take DOWN
		jr z, updateVolume.done
	or $F0 ;we are actually going to be taking steps UP. instead of calculating (10-(step%10)) and doing that many loops, we instead take ((step%10)-10) and count in reverse. we use OR to simultaneously do these operations.
	ld e, a
	
	ld hl, $FF12
	ld a, d
	add a
	add a
	add d
	add l
	ld l, a ;hl = volume io port for channel d
	
	.loop:
		ld a, $09
		ld [hl], a
		ld a, $11
		ld [hl], a
		ld a, $18
		ld [hl], a
		inc e
	jr nz, updateVolume.loop ;raise the volume one tick per loop
	
	.done:
	ld a, [bc]
	ld e, a ;restore e
	ret
	
.fixTimer:
	ld e, [hl] ;new index
	ld hl, inst_timers + 1
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e ;save it over the old timer
	jr updateVolume
	
updatePitch: ;bc = ptr to instrument, d = channel ID
;locates new pitch adjustment based on instrument and writes it to the current channel's status
	ld hl, inst_timers + TIMERPITCH
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld e, [hl] ;e = inst string index
	inc [hl] ;increment pitch timer
	
	ld hl, INSTPITCH
	add hl, bc
	ldi a, [hl]
	ld h, [hl] ;get ptr to pitch string
	add e
	ld l, a
	ld a, $00
	adc h
	ld h, a ;add index to find this frame's pitch
	
	ldi a, [hl]
	cp $80
		jr z, updatePitch.fixTimer
	ld e, a ;e = upcoming pitch change
	ld hl, chnl_statuses + STATUSPITCH
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld a, e
	add [hl] ;add pitch change to old pitch in chnl_status
	ldi [hl], a
	ld a, $00
	adc [hl]
	rl e ;check upper bit and adjust accordingly
	jr nc, updatePitch.signExtend
		dec a
	.signExtend:
	ld [hl], a
	
	ld a, [bc]
	ld e, a ;restore settings
	ret
	
.fixTimer:
	ld e, [hl] ;new index
	ld hl, inst_timers + 2
	ld a, d
	add a
	add a
	add l
	ld l, a
	ld [hl], e ;save it over the old timer
	jr updatePitch
	
updatePCM:
;scans through current pcm struct to find which sample should be playing and load it
	ld hl, pcm_timer
	inc [hl] ;increment before the load?
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
		ldi a, [hl] ;get time for the next sample to play
		sub e ;check if we've gotten that far yet
			jr z, updatePCM.loadNewSample ;if yes, load it
			ret nc ;if not, keep playing the current one
		add hl, bc
	jr updatePCM.loop
	
	.loadNewSample:
	ldi a, [hl]
	bit 7, a ;check for terminator
		jp nz, killPCMRAM
		
	ldh [the_sample_hi], a
	ldi a, [hl]
	ldh [the_sample_lo], a
	ldi a, [hl]
	ldh [the_sample_bank], a
	ret
	
killPCM:
;sets all the appropriate variables to resume regular wave channel behavior
	ld hl, $FF30
	ld bc, old_wave
	ld e, $10
	xor a
	ldh [$FF1C], a
	ldh [$FF1A], a
	ld [pcm_enable], a ;disable channel, unlock wave ram, and flag as no longer playing
	
	.copy:
		ld a, [bc]
		inc bc
		ldi [hl], a
		dec e
	jr nz, killPCM.copy ;copy old wave back in
	
	ld l, $FF
	res 2, [hl] ;disable timer interrupt
	
	ld a, $80
	ldh [$FF1A], a ;reenable ch3
	ret
	
note2SoundReg: ;c = io port corresponding to the current channel, hl = ptr to current channel status
	inc c
	bit 3, c
	jr z, note2SoundReg.ch124
		ld a, [pcm_enable]
		and a
		jr z, note2SoundReg.ch124
			inc c ;if we are playing channel 3 and pcm is active, the timer interrupt will handle playback. ignore this function.
			inc c
			inc c
			inc c
			ld l, $1F
			ret
	
	.ch124:
	ldi a, [hl] ;duty is already formatted how the io port wants it, so directly copy
	ldh [c], a
	inc c
	
	ldi a, [hl]
	ld b, a
	ldi a, [hl]
	ld e, a
	ld d, [hl]
	ld a, d ;b = vol, de = wavelength
	and $7F
	ldi [hl], a ;remove the retrigger bit from the wavelength for next frame
	
	bit 7, d
	jr z, note2SoundReg.skipVol
		swap b
		ld a, b ;if we need to retrigger, also add the corresponding bit in the volume io port
		or $08
		ldh [c], a
	
	.skipVol:
	inc c
	ld a, e
	ldh [c], a ;pitch is also pre-formatted
	inc c
	ld a, d
	ldh [c], a
	inc c
	ret
	
frequency_table:
	INCBIN "../assets/code/freqTable.bin"
	.end