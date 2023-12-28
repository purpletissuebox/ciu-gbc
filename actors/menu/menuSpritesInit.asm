SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TASKSRC = $0004
TASKDEST = $0007
NUMTASKS = $000A
SONGIDS = $0010

menuSpritesInit:
.loadSprites:
	ld a, c
	ldh [scratch_byte], a ;c is used as a loop counter, this is faster than a push-pop
	swapInRam save_file
	ld a, [last_played_song]
	
	ld hl, SONGIDS
	add hl, bc
	ld de, sort_table
	dec a ;the first song on screen is the song before the selection
	and $3F
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to internal song ID at the top of the screen
	
	ld c, $05
	.getIDs:
		ld a, [de]
		inc de
		ldi [hl], a ;copy 5 internal song IDs to actor memory
		inc hl
		ld a, e
		sub LOW(sort_table.end)
		jr nz, menuSpritesInit.noWrap
			ld de, sort_table
		.noWrap:
		dec c
	jr nz, menuSpritesInit.getIDs
	
	ldh a, [scratch_byte]
	ld c, a ;get pointer to actor memory back
	ld hl, SONGIDS
	add hl, bc ;hl points to list of internal IDs
	
	ld c, $05
	.calculateSrcs: ;for each song
		ld d, [hl]
		ld e, d
		xor a
		srl e
		rra
		srl e
		rra ;multiply by $140
		add $40
		ldi [hl], a ;calculate offset into graphics data and save it over the internal IDs
		ld a, d
		adc e
		ldi [hl], a
		dec c
	jr nz, menuSpritesInit.calculateSrcs
	
	ldh a, [scratch_byte]
	ld c, a
	
	ld hl, TASKDEST ;the source for the graphics task will change based on the above, but some parts will stay static
	add hl, bc
	ld a, LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, HIGH(sprite_tiles1) ;initialize destination address
	ldi [hl], a
	ld [hl], $13 ;initialize number of tiles = 20 per song
	
	updateActorMain menuSpritesInit.loadGfx
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loadGfx:
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	cp $05 ;keep submitting tasks until all 5 songs are loaded
	jr nz, menuSpritesInit.submitNext
		updateActorMain menuSpritesInit.fixOAM
		ret
	.submitNext:
	ldh [scratch_byte], a ;scratch = current song index 0-4
	add a
	add LOW(SONGIDS)
	add c
	ld e, a
	ld a, b
	adc $00
	ld d, a ;de points to offset into tile data

	ld hl, TASKSRC
	add hl, bc
	ld a, [de]
	inc de
	ldi [hl], a ;save low byte of source address
	ld a, [de]
	ld d, a ;save backup of high byte
	or $40
	ldi [hl], a ;the actual address has this bit set
	ld a, BANK(song_names_vwf)
	bit 6, d ;use backup to check which bank it is in
	jr z, menuSpritesInit.smallBank
		inc a
	.smallBank:
	ldi [hl], a ;save bank
	
	call submitGraphicsTask
	
	ld hl, NUMTASKS
	add hl, bc
	ldh a, [scratch_byte]
	ld e, a
	ldd a, [hl]
	cp e ;check if our task matches the upcoming task for next frame
		ret z ;if they match, the task failed, so do not update the destination pointer.
	
	dec hl
	dec hl
	ld a, [hl]
	add $40
	ldi [hl], a
	ld a, [hl]
	adc $01 ;increment destination pointer by one song worth, $0140
	ldi [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.fixOAM:
	push bc
	swapInRam shadow_oam
	ld hl, shadow_oam ;hl = pointer to current sprite
	ld bc, $1810 ;b/c = y/x position
	ld d, $00 ;d will track tile IDs, it starts at zero
	
	.nextSong:
		ld e, $0A ;e = loop counter
		
		.nextLetter:
			ld a, b
			ldi [hl], a ;save y coordinate
			ld a, c
			ldi [hl], a ;save x coordinate and increment
			add $08
			ld c, a
			ld a, d
			ldi [hl], a ;save tile ID and increment
			inc d
			inc d
			ld a, $08
			ldi [hl], a ;specify tiles reside in bank 1
			dec e
		jr nz, menuSpritesInit.nextLetter
		
		ld a, b
		add $20
		ld b, a ;increment y position for next song
		rrca
		add $04
		ld c, a ;calculate x position based on y position and slope of 1/2
		
		ld a, d
		cp $50 ;after copying 4 songs, the tile ID will be 80
	jr nz, menuSpritesInit.nextSong
	
	ld a, $0A ;number of sprites in one song
	ld de, $0004 ;distance between sprites
	ld hl, shadow_oam + $2B ;pointer to the second song (our selection)
	.paletteLoop:
		inc [hl] ;update these tiles to use another palette
		add hl, de
		dec a
	jr nz, menuSpritesInit.paletteLoop
	
	restoreBank "ram"
	pop bc
	updateActorMain menuSpritesInit.cleanup
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.cleanup:	
	swapInRam on_deck
	ld e, $28
	ld hl, on_deck
	xor a
	.loop:
		ldi [hl], a ;y position
		ldi [hl], a ;x position
		ldi [hl], a ;tile ID
		ldi [hl], a ;palette
		dec e
	jr nz, menuSpritesInit.loop
	
	ld e, $28
	ld hl, on_deck_2
	.loop2:
		ldi [hl], a ;y position
		ldi [hl], a ;x position
		ldi [hl], a ;tile ID
		ldi [hl], a ;palette
		dec e
	jr nz, menuSpritesInit.loop2 ;clear alternate OAM to prevent artifacts
	
	ld a, HIGH(on_deck)
	ld [active_oam_buffer], a
	ld a, $04
	ld [menu_text_head], a ;initialize which tiles need to be replaced and which buffer is active

	ld hl, $FF40
	set 2, [hl] ;change sprites to 8x16 mode
	ld l, $45
	ld a, $7A
	ld [hl], a ;set LYC register
	ld [LYC_buffer], a ;and its buffer
	ld l, $0F
	res 1, [hl] ;stop the scanline interrupt from running immediately if it was already queued
	ld l, $FF
	set 1, [hl] ;enable future scanline interrupts
	
	restoreBank "ram"
	ld e, c
	ld d, b
	jp removeActor