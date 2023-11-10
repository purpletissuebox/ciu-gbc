SECTION "FADE MUSIC", ROMX

VARIABLE = $0003
FADESPEED = $0004
TIMER = $0005
FADESTART = $0007
NEXTACTOR = $0008
MUSICPLAYER = $0009

fadeMusic:
.init:
	updateActorMain fadeMusic.wait
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	inc hl
		
	ld de, fadeMusic.fade_table
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld a, [de]
	inc de
	ldi [hl], a
	inc hl
	inc hl
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	inc de
	ldi [hl], a
		
	ld a, LOW(initSong)
	ldi [hl], a
	ld a, HIGH(initSong)
	ldi [hl], a
	ld a, BANK(initSong)
	ldi [hl], a
	ld a, [de]
	ld [hl], a
	
	xor a
	ldh [$FF24], a
	ret
	
.wait:
	ld hl, FADESTART
	add hl, bc
	ldd a, [hl]
	cp [hl]
	ret z
	
	updateActorMain fadeMusic.main
	
	ld hl, FADESPEED
	add hl, bc
	ld a, [hl]
	add a
	ret c
	
	ld hl, MUSICPLAYER
	add hl, bc
	ld e, l
	ld d, h
	jp spawnActor
	
.main:
	ld hl, TIMER
	add hl, bc
	ldi a, [hl]
	add a
	ld e, a
	sbc a
	ld d, a
	
	ld a, e
	add [hl]
	ldi [hl], a
	ld a, d
	adc [hl]
	ld [hl], a
	ld e, a
	swap a
	or e
	ldh [$FF24], a
	
	sub $77
	jr z, fadeMusic.doneUp
	inc e
	jr z, fadeMusic.doneDown
	ret
	
	.doneDown:
		xor a
		ldh [music_on], a
	.doneUp:
		ld hl, NEXTACTOR
		add hl, bc
		ld a, [hl]
		add a
		add a
		ld e, a
		ld d, $00
		ld hl, fadeMusic.actor_table
		add hl, de
		ldi a, [hl]
		ld d, [hl]
		call spawnActor
		
		ld e, c
		ld d, b
		jp removeActor

.fade_table:
	db $40, $20, $00, $00 ;speed, start, actor#, song#
	db $C0, $10, $00

.actor_table:
	dw dummy_actor
	db $01
	db $FF