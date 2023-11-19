SECTION "TEXT FLICKER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;controls sprite colors for character select text
;flickers a palette between yellow and blue, then makes the blue color fade to white when a selection is made
;reads input each frame to determine which color palette to change and what colors to put there
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TIMER = $0004
OBJOFFSET = $004E

characterFlicker:
	ld hl, TIMER
	add hl, bc
	inc [hl] ;increment timer
	ldd a, [hl]
	and $04 ;flash text on for 4 frames, off for 4 frames
	rrca ;convert timer value into offset into color array
	ld de, characterFlicker.colors
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to color we want displayed
	
	swapInRam shadow_palettes
	
	ld a, [hl] ;get variable = which palette to write to
	add a
	add a
	add a ;palettes are 8 bytes in size
	ld hl, shadow_palettes + OBJOFFSET
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl points to destination palette
	
	
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a ;copy over desired color
	
	restoreBank "ram"
	
	ldh a, [press_input]
	ld e, a
	and $01 ;if A was pressed, change modes
		jr nz, characterFlicker.submit
	
	ld a, e
	and $30
		ret z ;if L/R were not pressed, dont bother checking for anything
	swap a
	rra ;rotate bottom bit (right) into carry flag
	ld a, $01
	jr c, characterFlicker.right
		ld a, $00 ;load a with 1 if right was pressed, 0 if left was pressed
	.right:
	
	ld hl, VARIABLE
	add hl, bc
	cp [hl]
		ret z ;if we are already flickering on that side, do nothing
	
	ld [hl], a
	ld de, characterFlicker.revert
	call spawnActor ;put both color palettes back to yellow and we will begin flicking the correct side next frame
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.submit:
	updateActorMain characterFlicker.shine
	ld hl, TIMER
	add hl, bc
	ld [hl], $00 ;some cleanup before we begin the next phase of color changes
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.shine:
	ld hl, TIMER
	add hl, bc
	inc [hl] ;increment timer
	ldd a, [hl]
	cp $40
		jr z, characterFlicker.end ;after 64 frames, the fade will be over so return
	
	add a
	ld de, characterFlicker.colors
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = pointer to upcoming color
	
	swapInRam shadow_palettes
	
	ld a, [hl] ;get variable
	add a
	add a
	add a
	ld hl, shadow_palettes + OBJOFFSET
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl points to destination color palette
		
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a ;copy it over
	
	restoreBank "ram"
	ret
	
	.end:
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
		
.revert:
	NEWACTOR setColorsOBJ, $82

.colors:
	dw $0B98, $7423
	
.shine_table:
	INCBIN "../assets/gfx/palettes/shineTable.bin"