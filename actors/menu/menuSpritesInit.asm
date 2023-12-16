SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SONGIDS = $0010

menuSpritesInit:
.loadSprites:
	ld a, c
	ldh [scratch_byte], a
	swapInRam save_file
	ld a, [last_played_song]
	ld l, a
	swapInRam sort_table
	ld a, l
	
	ld hl, SONGIDS
	add hl, bc
	ld de, sort_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld c, $05
	.getIDs:
		ld a, [de]
		inc de
		ldi [hl], a
		inc hl
		ld a, e
		sub LOW(sort_table.end)
		jr nz, menuSpritesInit.noWrap
			ld de, sort_table
		.noWrap
		ld a, l
		dec c
	jr nz, menuSpritesInit.getIDs
	
	ldh a, [scratch_byte]
	ld c, a
	ld hl, SONGIDS
	add hl, bc
	ld c, $05
	.calculateSrcs:
		ld d, [hl]
		ld e, d
		ld a, d
		srl e
		rra
		srl e
		rra
		add $40
		ldi [hl], a
		ld a, d
		adc e
		ldi [hl], a
		ld a, l
		dec c
	jr nz, menuSpritesInit.calculateSrcs
	
	ldh a, [scratch_byte]
	ld c, a
	updateActorMain menuSpritesInit.loadGfx
	restoreBank "ram"
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loadGfx:
	ret
	
	swapInRam on_deck
	ld e, $28
	ld hl, on_deck
	xor a
	.loop:
		ldi [hl], a ;y position
		ldi [hl], a ;x position
		inc hl
		ldi [hl], a ;palette
		dec e
	jr nz, menuSpritesInit.loop
	
	ld e, $28
	ld hl, on_deck_2
	xor a
	.loop2:
		ldi [hl], a ;y position
		ldi [hl], a ;x position
		inc hl
		ldi [hl], a ;palette
		dec e
	jr nz, menuSpritesInit.loop2
	
	ld a, $D0
	ld [on_deck.active_buffer], a

	ld hl, $FF40
	set 2, [hl] ;change sprites to 8x16 mode
	ld l, $45
	ld a, $7A
	ld [hl], a ;set LYC register
	ld [on_deck.LYC_buffer], a ;and its buffer
	ld l, $0F
	res 1, [hl] ;stop the scanline interrupt from running immediately if it was already queued
	ld l, $FF
	set 1, [hl] ;enable future scanline interrupts
	
	restoreBank "ram"	
	restoreBank "ram"
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loader_actor:
	NEWACTOR menuLoadText, $00