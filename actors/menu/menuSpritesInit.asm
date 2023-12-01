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
	
	ld hl, $FF40
	set 2, [hl] ;change sprites to 8x16 mode
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loader_actor:
	NEWACTOR menuLoadText, $00