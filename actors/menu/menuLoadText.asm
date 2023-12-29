SECTION "LOAD TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads text strings into oam based on scroll fraction.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
STARTX = $00

menuLoadText:
	push bc
	swapInRam sort_table
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;variable = external ID for the new song to render
	ldh [scratch_byte], a

	;calculate source address for the new tiles - each song takes up 20 tiles = $140 bytes and start at address $4040
	and $3F
	ld d, a ;d0 = ID * $100
	ld e, a
	xor a
	srl e
	rra
	srl e
	rra ;ea = ID * $40
	add $40 ;add ea + d0 + $0040 = ($40 + 0 + a) + (d + e + carry)
	ldi [hl], a
	ld a, d
	adc e
	ld d, a ;save high result back to register to use in bank calculation
	or $40 ;wrap address to $4000-$7FFF range
	ldi [hl], a
	
	ld a, BANK(song_names_vwf)
	bit 6, d ;if address is larger than $4000, we must use the next bank
	jr z, menuLoadText.smallBank
		inc a
	.smallBank:
	ldi [hl], a
	
	;next, calculate destination address
	swapInRam menu_text_head
	ld a, [menu_text_head]
	ld d, a
	ld e, a
	xor a
	srl e
	rra
	srl e
	rra ;multiply the slot it will load in at by $140
	add LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, d
	adc e
	add HIGH(sprite_tiles1)
	ldi [hl], a
	
	ld [hl], $13 ;copy 20 tiles always
	
	ldh a, [scratch_byte]
	cp $80 ;retrieve variable and get direction bit
	jr nc, menuLoadText.down
	
	;up
	ld a, [menu_text_head]
	ld e, a
	sub $01 ;decrement which slot will receive the next bit of text
	jr nc, menuLoadText.goodIndexUp
		ld a, $04
	.goodIndexUp:
	ld [menu_text_head], a
	ld a, e
	add a
	add a
	add e
	add a
	add a
	ld d, a ;calculate tile ID of the topmost song on the screen, which is the old head * 20.
	
	ld hl, shadow_oam
	ld bc, $F800 + STARTX ;initialize ptr to oam and y/x coordinates in hl, b/c
	
	.loopUp: ;for each song
		call menuLoadText.loadSong ;write 20 sprites in to oam
		
		ld a, d ;the subroutine increments our tile ID but it still might spill out of range
		sub $64
		jr nz, menuLoadText.tileWrapUp
			ld d, a ;if so, reload it with 0
		.tileWrapUp:
		
		ld a, b
		add $20 ;increment the y coordinate
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a ;reset x coordinate to y/2. this is a holdover from when songs were made up of a variable number of sprites, but a nice speedup nonetheless.
		cp $40 + STARTX
	jr c, menuLoadText.loopUp ;no registers remain for a dedicated loop counter, but song #4 will always overflow here.
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a ;to write song #5, point hl to the inactive buffer
	ld a, c
	cp $40 + STARTX
	jr z, menuLoadText.loopUp ;go back to copy song #5. it will bump the x coordinate one more time and we can go through.
		ld hl, shadow_oam + $53
	jr menuLoadText.cleanup ;finish doing actor work.
	
	.down:
	ld a, [menu_text_head]
	inc a
	cp $05 ;increment which slot will receive the next bit of text
	jr c, menuLoadText.goodIndexDown
		xor a
	.goodIndexDown:
	ld [menu_text_head], a
	ld e, a
	add a
	add a
	add e
	add a
	add a
	ld d, a ;calculate tile ID of the topmost song on the screen, which is the new head * 20.
	
	ld hl, shadow_oam
	ld bc, $1810 + STARTX ;initialize ptr to oam and y/x coordinate in hl, b/c
	
	.loopDown: ;for each song
		call menuLoadText.loadSong ;write 20 sprites in to oam
		
		ld a, d ;the subroutine increments our tile ID but it still might spill out of range
		sub $64
		jr nz, menuLoadText.tileWrapDown
			ld d, a ;if so, reload it with 0
		.tileWrapDown:
		ld a, b
		add $20 ;increment the y coordinate
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a ;reset x coordinate to y/2. this is a holdover from when songs were made up of a variable number of sprites, but a nice speedup nonetheless.
		cp $50 + STARTX
	jr c, menuLoadText.loopDown ;no registers remain for a dedicated loop counter, but song #4 will always overflow here.
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a ;to write song #5, point hl to the inactive buffer
	ld a, c
	cp $50 + STARTX
	jr z, menuLoadText.loopDown ;go back to copy song #5. it will bump the x coordinate one more time and we can go through.
		ld hl, shadow_oam + $2B	
	
	.cleanup:
	ld de, $0004
	ld a, $0A
	.paletteLoop:
		inc [hl]
		add hl, de
		dec a
	jr nz, menuLoadText.paletteLoop
	
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	updateActorMain menuLoadText.submit ;the task was loaded above, now actually try to submit it.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl] ;retry until the task goes through.
	dec a
		ret nz
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loadSong: ;hl points to next oam entry to be filled, bc contains y/x coordinate, d contains tile ID
	ld e, $0A ;e used as loop counter
	.nextSprite:
		ld a, b
		ldi [hl], a ;save y coordinate
		ld a, c
		ldi [hl], a ;save x coordinate
		add $08 ;and increment by 8 pixels
		ld c, a
		ld a, d
		ldi [hl], a ;save tile ID
		inc d
		inc d ;increment to the next sprite, which is 2 tiles in 8x16 mode.
		ld a, $08
		ldi [hl], a ;save attribute bit to use bank 1
		dec e
	jr nz, menuLoadText.nextSprite
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SONG NAME GRAPHICS", ROMX
;song_names_vwf:
	BIGFILE song_names_vwf, $8000, assets/gfx/sprites/songNames.bin