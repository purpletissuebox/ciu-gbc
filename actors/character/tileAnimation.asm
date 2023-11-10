SECTION "CHARACTER TILESTREAM", ROMX

VARIABLE = $0003
TIMER = $000E

tileAnimation:
.init:
	swapInRam shadow_scroll
	ld a, $50
	ld [shadow_scroll+1], a
	restoreBank "ram"
	ld de, tileAnimation.arrow_task
	call loadGraphicsTask
	updateActorMain tileAnimation.main

.main:
	ld hl, ACTORSIZE - 2
	add hl, bc
	ldd a, [hl]
	and a
	jr z, .lastActor
	
		ldh a, [next_actor+1]
		ldd [hl], a
		ldh a, [next_actor]
		ld [hl], a
		ld e, c
		ld d, b
		call spawnActor

		ld hl, ACTORSIZE - 4
		add hl, bc
		ldi a, [hl]
		ld h, [hl]
		ld l, a
		ld e, c
		ld d, b
		push bc
		ld c, LOW(ACTORSIZE - 2)
		rst $10
		
		pop de
		jp removeActor
		
	.lastActor:
	push bc
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	ld hl, TIMER
	add hl, bc
	add [hl]
	ldi [hl], a
	ld a, $00
	adc [hl]
	and $0F
	ld [hl], a
	
	ld b, a
	swapInRam shadow_scroll
	ld a, [shadow_scroll+1]
	add b
	and $0F
	ld e, $00
	rra
	rr e
	rra
	rr e
	ld d, a
	
	ld a, [shadow_scroll]
	cpl
	inc a
	add b
	and $0F
	add a
	ld c, a
	ld hl, arrow_tiles
	add hl, de
	add l
	ld l, a
	
	ld de, animated_tiles
	ld b, $10
	.loopUp:
		res 5, l
		ldi a, [hl]
		ld [de], a
		inc de
		ldi a, [hl]
		ld [de], a
		inc de
		dec b
	jr nz, tileAnimation.loopUp
	
	dec hl
	ld de, animated_tiles + $003F
	ld b, $10
	.loopDown:
		set 5, l
		ldd a, [hl]
		ld [de], a
		dec de
		ldd a, [hl]
		ld [de], a
		dec de
		dec b
	jr nz, tileAnimation.loopDown
	
	restoreBank "ram"
	pop bc
	call submitGraphicsTask
	ret
	
.arrow_task:
	GFXTASK animated_tiles, bkg_tiles0, $0000

align 6
arrow_tiles:
	INCBIN "../assets/gfx/bkg/character/arrowTiles.bin"
	.end
