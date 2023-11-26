SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LOADER = $0004

menuSpritesInit:
.loadSprites:
	ld hl, LOADER
	add hl, bc
	ld e, l
	ld d, h
	ld a, LOW(menuLoadText.init)
	ldi [hl], a
	ld a, HIGH(menuLoadText.init)
	ldi [hl], a
	ld a, BANK(menuLoadText.init)
	ldi [hl], a
	
	swapInRam save_file
	ld a, [last_played_song]
	sub $02
	and $3F
	ld [hl], a
	call spawnActor
	
	restoreBank "ram"
	updateActorMain menuSpritesInit.doInterrupt
	ret

.doInterrupt:
	swapInRam on_deck
	ld a, $D1
	ld [on_deck.active_buffer], a
	
	ld hl, up_next + $0050
	ld de, $0004
	ld a, $14
	.loop:
		ld [hl], d
		add hl, de
		dec a
	jr nz, menuSpritesInit.loop
	
	restoreBank "ram"
	
	ld a, $18
	ldh [$FF45], a
	
	ld hl, $FF0F
	res 1, [hl]
	ld l, $FF
	set 1, [hl]
	
	ld e, c
	ld d, b
	jp removeActor