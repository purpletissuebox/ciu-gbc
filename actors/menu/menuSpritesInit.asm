SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuSpritesInit:
.loadSprites:
	swapInRam save_file
	ld a, [last_played_song]
	dec a
	and $3F
	or $80
	ld de, menuSpritesInit.loader_actor
	call spawnActorV ;load the starting tiles
	
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