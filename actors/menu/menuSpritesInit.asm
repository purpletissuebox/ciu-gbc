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
	
	swapInRam on_deck
	ld a, $D1
	ld [on_deck.active_buffer], a
	
	restoreBank "ram"
	restoreBank "ram"
	
	updateActorMain menuSpritesInit.doInterrupt
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.doInterrupt:
	
	swapInRam up_next
	ld hl, up_next + $50
	ld de, $0004
	ld a, $14
	
	.spriteLoop1:
		ld [hl], d
		add hl, de
		dec a
	jr nz, menuSpritesInit.spriteLoop1
	
	ld hl, up_next_2 + $0050
	ld a, $14
	.spriteLoop2:
		ld [hl], d
		add hl, de
		dec a
	jr nz, menuSpritesInit.spriteLoop2
	
	restoreBank "ram"
	
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