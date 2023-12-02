SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuSpritesInit:
.loadSprites:
	swapInRam save_file
	ld a, [last_played_song]
	sub $02
	and $3F
	ld de, menuSpritesInit.loader_actor
	call spawnActorV ;load the starting tiles
	restoreBank "ram"
	
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
	restoreBank "ram"
	
	ld hl, $FF40
	set 2, [hl] ;change sprites to 8x16 mode
	ld l, $45
	ld [hl], $5A ;set LYC register
	ld l, $0F
	res 1, [hl] ;stop the scanline interrupt from running immediately if it was already queued
	ld l, $FF
	set 1, [hl] ;enable future scanline interrupts
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loader_actor:
	NEWACTOR menuLoadText, $00