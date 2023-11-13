SECTION "TITLEMOVEMENT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;animates each sprite with a sine wave
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMERS = $0010

titleSineWave:
.init:
;creates an array of timers for each letter. the positions start offscreen, so earlier times make the letters fall later.
	ld hl, TIMERS
	add hl, bc ;hl = array of timers
	ld de, $060B ;d = space between times / e = array length
	ld a, $3F
	.setUp:
		ldi [hl], a ;initialize timer[i] = 0x3F - 6*i
		sub d
		dec e
	jr nz, titleSineWave.setUp
	
	updateActorMain titleSineWave.main
	ret

.main:
;for each letter, read and imcrement its timer, looping the last 40 frames of the animation.
;use the timer to index into a sine table and use that value to set the corresponding entry's y-position in oam.
	swapInRam shadow_oam
	
	ld hl, TIMERS
	add hl, bc
	ld e, l
	ld d, h ;de = timer array
	ld hl, shadow_oam ;hl = oam y position
	
	ld a, [de] ;the top of the loop demands a = [de], but for speed we want to read at the bottom, so pre-load for the first iteration
	
	.loop:
		inc a
		jr nz, titleSineWave.noOverflow
			ld a, $C0 ;loop lasts 40 frames
		.noOverflow:
		ld [de], a ;update timer
		inc de
		
		ld bc, titleSineWave.table
		add c
		ld c, a
		ld a, b
		adc $00
		ld b, a ;[bc] = sin(timer[i])
		
		ld a, [bc]
		ldi [hl], a ;save to y position of this oam entry
		ld bc, $0003
		add hl, bc ;hl = oam[i+1].yPos
		
		ld a, [de] ;a = index into sine table
		and a ;when we read past the end of the array, there will be a null terminator
	jr nz, titleSineWave.loop
	
	restoreBank "ram"
	ret
	
.cleanup:
;this function is (currently) invoked only when an external force changes this actor's main!
;should probably poll for start button press and use a timer to clean up instead...
;it zeros out the y-positions in oam.
	swapInRam shadow_oam
	
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
	
	restoreBank "ram"
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
