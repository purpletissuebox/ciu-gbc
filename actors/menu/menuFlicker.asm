SECTION "MENU FLICKER", ROMX

TIMER = $000F

menuFlicker:
	ldh a, [scene]
	sub GAMEPLAY
	jr c, menuFlicker.run
		ld e, c
		ld d, b
		jp removeActor
	
	.run:	
	ld hl, TIMER
	add hl, bc
	inc [hl]
	ld a, [hl]
	and $03
		ret nz
	
	ld a, [hl]
	and $04
	ld de, $0B98
	jr z, menuFlicker.yellow
		ld de, $7423
	.yellow:
	
	swapInRam shadow_palettes
	ld a, [fade_timer+1]
	sub $20
	ld hl, palette_backup + 8*4*2 + 1*4*2 + 3*2
	jr nz, menuFlicker.stillFading
		ld hl, shadow_palettes + 8*4*2 + 1*4*2 + 3*2
	.stillFading:
	
	ld a, e
	ldi [hl], a
	ld [hl], d
	restoreBank "ram"
	ret