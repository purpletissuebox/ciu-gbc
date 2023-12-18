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
	ldh [scratch_byte], a
	swapInRam save_file
	ld a, [last_played_song]
	
	ld hl, SONGIDS
	add hl, bc
	ld de, sort_table
	dec a
	and $3F
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
		.noWrap:
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
		xor a
		srl e
		rra
		srl e
		rra
		add $40
		ldi [hl], a
		ld a, d
		adc e
		ldi [hl], a
		dec c
	jr nz, menuSpritesInit.calculateSrcs
	
	ldh a, [scratch_byte]
	ld c, a
	
	ld hl, TASKDEST
	add hl, bc
	ld a, LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, HIGH(sprite_tiles1)
	ldi [hl], a
	ld [hl], $13
	
	updateActorMain menuSpritesInit.loadGfx
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loadGfx:
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	cp $05
	jr nz, menuSpritesInit.submitNext
		updateActorMain menuSpritesInit.fixOAM
		ret
	.submitNext:
	ldh [scratch_byte], a
	add a
	add LOW(SONGIDS)
	add c
	ld e, a
	ld a, b
	adc $00
	ld d, a

	ld hl, TASKSRC
	add hl, bc
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ld d, a
	or $40
	ldi [hl], a
	ld a, BANK(song_names_vwf)
	bit 6, d
	jr z, menuSpritesInit.smallBank
		inc a
	.smallBank:
	ldi [hl], a
	
	call submitGraphicsTask
	
	ld hl, NUMTASKS
	add hl, bc
	ldh a, [scratch_byte]
	ld e, a
	ldd a, [hl]
	cp e
		ret z
	
	dec hl
	dec hl
	ld a, [hl]
	add $40
	ldi [hl], a
	ld a, [hl]
	adc $01
	ldi [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.fixOAM:
	push bc
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld bc, $1810
	ld d, $00
	
	.nextSong:
		ld e, $0A
		
		.nextLetter:
			ld a, b
			ldi [hl], a
			ld a, c
			ldi [hl], a
			add $08
			ld c, a
			ld a, d
			ldi [hl], a
			inc d
			inc d
			ld a, $08
			ldi [hl], a
			dec e
		jr nz, menuSpritesInit.nextLetter
		
		ld a, b
		add $20
		ld b, a
		rrca
		add $04
		ld c, a
		
		ld a, d
		cp $50
	jr nz, menuSpritesInit.nextSong
	
	ld a, $0A
	ld de, $0004
	ld hl, shadow_oam + $2B
	.paletteLoop:
		inc [hl]
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
	jr nz, menuSpritesInit.loop2
	
	ld a, HIGH(on_deck)
	ld [active_oam_buffer], a
	ld a, $04
	ld [menu_text_head], a

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