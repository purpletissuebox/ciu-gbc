SECTION "TITLEMOVEMENT", ROMX

TIMERS = $0010

titleSineWave:
.init:
	ld hl, TIMERS
	add hl, bc ;hl = array of timers
	ld de, $060B ;d = space between times / e = array length
	ld a, $3F
	.setUp:
		ldi[hl], a ;initialize timer[i] = 0x3F - 6*i
		sub d
		dec e
	jr nz, titleSineWave.setUp
	
	updateActorMain titleSineWave.main
	ret

.main:
	ldh a, [ram_bank]
	push af
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ldh [ram_bank], a
	
	ld hl, TIMERS
	add hl, bc
	ld e, l
	ld d, h ;de = timer array
	ld hl, shadow_oam ;hl = oam[i].yPos
	.loop:
		ld bc, titleSineWave.table
		ld a, [de] ;a = index into sine table
		inc a
		jr nz, titleSineWave.noOverflow
			ld a, $C0 ;loop last 40 frames
		.noOverflow:
		ld [de], a ;update timer
		inc de
		add c
		ld c, a
		ld a, b
		adc $00
		ld b, a ;bc = sin(timer[i])
		ld a, [bc]
		ldi [hl], a ;save to y position of this oam entry
		inc hl
		inc hl
		inc hl ;hl = oam[i+1].yPos
		ld a, e
		and $0F
		sub $0B ;array is aligned to 16 bytes so we can check index via (i = de & 000F)
	jr nz, titleSineWave.loop
	pop af
	ldh [$FF70], a
	ldh [ram_bank], a
	ret
	
.cleanup:
	ldh a, [ram_bank]
	push af
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ldh [ram_bank], a
	
	ld e, c
	ld d, b
	ld a, $0B
	ld bc, $0004
	ld hl, shadow_oam
	.clearOAM:
		ld [hl], b
		add hl, bc
		dec a
	jr nz, titleSineWave.clearOAM
	call removeActor
	
	pop af
	ldh [$FF70], a
	ldh [ram_bank], a
	ret
	
	
.table:
angle = 0.0
height = 0.0
SPEED = 1.0
	REPT 192 - (DIV(128.0,SPEED) >> 16) ;above screen
		db $00
	ENDR
	REPT (DIV(128.0,SPEED) >> 16) ;linearly ramp up
		db height >> 16
height = height + SPEED
	ENDR
	REPT 64
		db (MUL(4.995, SIN(angle)) + 128.0) >> 16 ;sine wave
angle = angle + 1024.0
	ENDR
