SECTION "TEXT FLICKER", ROMX

VARIABLE = $0003
TIMER = $0004
OBJOFFSET = $004E

characterFlicker:
	ld hl, TIMER
	add hl, bc
	inc [hl]
	ldd a, [hl]
	and a, $04
	rrca
	ld de, characterFlicker.colors
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	swapInRam shadow_palettes
	
	ld a, [hl]
	add a
	add a
	add a
	ld hl, shadow_palettes + OBJOFFSET
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	
	restoreBank "ram"
	
	ldh a, [press_input]
	ld e, a
	and $01
		jr nz, characterFlicker.submit
	
	ld a, e
	and $30
	ret z
	swap a
	rra
	ld a, $01
	jr c, characterFlicker.right
		ld a, $00
	.right:
	ld hl, VARIABLE
	add hl, bc
	cp [hl]
	ret z
	
	ld [hl], a
	ld de, characterFlicker.revert
	call spawnActor
	ret
	
.submit:
	updateActorMain characterFlicker.shine
	ld hl, TIMER
	add hl, bc
	ld [hl], $00

.shine:
	ld hl, TIMER
	add hl, bc
	inc [hl]
	ldd a, [hl]
	cp $40
	jr z, characterFlicker.end
	add a
	ld de, characterFlicker.colors
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	swapInRam shadow_palettes
	
	ld a, [hl]
	add a
	add a
	add a
	ld hl, shadow_palettes + OBJOFFSET
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
		
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	
	restoreBank "ram"
	ret
	
	.end:
		ld e, c
		ld d, b
		jp removeActor
		
.revert:
	NEWACTOR setColorsOBJ, $82

.colors:
	dw $0B98, $7423
	
.shine_table:
	INCBIN "../assets/gfx/palettes/shineTable.bin"