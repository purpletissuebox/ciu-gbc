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
	call spawnActorV
	
	restoreBank "ram"
	updateActorMain menuSpritesInit.doInterrupt
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loader_actor:
	NEWACTOR menuLoadText, $00