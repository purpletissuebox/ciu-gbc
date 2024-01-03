SECTION "MENU FLICKER", ROMX

TIMER = $000F

menuFlicker:
	ldh a, [scene]
	sub GAMEPLAY
	jr c, menuFlicker.run
		ld e, c
		ld d, b
		jp removeActor ;quit running when a song is selected
	
	.run:	
	ld hl, TIMER
	add hl, bc
	inc [hl] ;increment timer every frame
	ld a, [hl]
	and $07 ;on frame multiples of 8, toggle the color
		ret nz
	
	ld a, [hl]
	and $08 ;change between yellow and blue based on the next bit up
	ld de, $0B9F ;de = color value to write
	jr z, menuFlicker.yellow
		ld de, $7423
	.yellow:
	
	swapInRam shadow_palettes ;if we write directly to the palette buffer, it will be full instensity while the rest of the screen fades in or out. so check if fades are in progress.
	ld a, [fade_timer+1]
	sub $20
	ld hl, palette_backup + 8*4*2 + 1*4*2 + 3*2 ;8 bkg palettes + 1 oam palette + 3 colors
	jr nz, menuFlicker.stillFading
		ld hl, shadow_palettes + 8*4*2 + 1*4*2 + 3*2 ;if the screen is not fading, write directly to the palette buffer
	.stillFading:
	
	ld a, e
	ldi [hl], a
	ld [hl], d ;save the appropriate color to the appropriate buffer
	restoreBank "ram"
	ret