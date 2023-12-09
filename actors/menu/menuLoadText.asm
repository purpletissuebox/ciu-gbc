SECTION "LOAD TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads text strings into oam based on scroll fraction.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TASKSRCLOW = $0004
TASKDESTLOW = $0007
SONGLIST = $000B
STARTX = $00

menuLoadText:
	push bc
	swapInRam sort_table
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;variable = external ID for the first song to render
	ldh [scratch_byte], a
	
	ld hl, SONGLIST
	add hl, bc
	ld b, a ;retrieve variable
	ld c, $05 ;c = loop counter
	
	ld de, sort_table
	and $3F
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = pointer to internal song ID
	
	.copyLoop:
		ld a, [de]
		inc de
		ldi [hl], a ;copy 5 internal IDs to local memory
		ld a, e
		cp LOW(sort_table.end)
		jr nz, menuLoadText.noWrap
			ld de, sort_table
		.noWrap:
		dec c
	jr nz, menuLoadText.copyLoop
	
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld a, b ;retrieve variable
	and $80
	
	ld bc, $F800 + STARTX ;if scrolling up, first song title is above the screen.
	jr z, menuLoadText.up
		ld bc, $1800 + STARTX + $10 ;if scrolling down, move 4 tiles down, 2 tiles over.
	.up:
	
	call menuLoadText.loadSongNames ;copy sprites to shadow oam
	
	ldh a, [scratch_byte]
	and $80
	ld hl, shadow_oam + $0053
	jr nz, menuLoadText.down
		ld hl, shadow_oam + $002B
	.down:
	
	ld de, $0004
	ld bc, $0A09 ;de = distance between sprites, b = loop counter, c = palette to write
	
	.paletteLoop:
		ld [hl], c
		add hl, de
		dec b
	jr nz, menuLoadText.paletteLoop ;replace the soon-to-be-selected song's palette.
	
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	
	;next we just need the actual tile data for each sprite. the source address will change randomly, but dest address will change sequentially, so we can initialize it now.
	ld hl, TASKDESTLOW
	add hl, bc
	ld a, LOW((sprite_tiles1 - $0140) | BANK(sprite_tiles1))
	ldi [hl], a
	ld a, HIGH((sprite_tiles1 - $0140) | BANK(sprite_tiles1))
	ldi [hl], a
	ld [hl], $13 ;20 tiles
	
	.gfxLoop:
		ld hl, NUMTASKS ;we will use the number of completed tasks as a loop counter. the background actors are staggered so they shouldnt clog up the gfx task buffer
		add hl, bc
		ldi a, [hl] ;hl now points to song list
		cp $05
			jr z, menuLoadText.break
		
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl = pointer to song ID
		
		ld a, [hl] ;calculate src address = ((ID*320)%$4000) + $4040
		ld d, a
		ld e, $00
		rra
		rr e
		rra
		rr e
		and $3F
		add d
		ld d, a ;de = distance from start of gfx data
		
		ld hl, TASKSRCLOW
		add hl, bc
		ld a, e
		add $40
		ldi [hl], a
		ld a, d
		adc $00
		ld d, a
		or $40
		ldi [hl], a
		ld a, BANK(song_names_vwf)
		bit 6, d
		jr z, menuLoadText.smallBank
			inc a
		.smallBank:
		ldi [hl], a ;hl now points to destination
		
		ld a, [hl]
		add $40
		ldi [hl], a
		ld a, [hl]
		adc $01
		ldi [hl], a
		
		call submitGraphicsTask
	jr menuLoadText.gfxLoop
	.break:
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.loadSongNames: ;hl = pointer to oam, b = y coordinate, c = x coordinate
;each sprite will just use the next available tile. this means we can avoid actually reading the string and instead just increment by fixed amounts.
	ld d, $00 ;d will accumulate how many tiles we have used
	.nextSong:
		ld e, $0A ;e counts how many sprites are left for the current string
		.loop:
			ld a, b
			ldi [hl], a ;y coord
			ld a, c
			ldi [hl], a ;x coord
			add $08
			ld c, a
			ld a, d
			ldi [hl], a ;tile ID
			add $02
			ld d, a
			ld [hl], $08 ;sprite attr, they will go in bank 1
			inc hl
			
			dec e
		jr nz, menuLoadText.loop
		
		ld a, b
		add $20
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a ;increment vertical position and reset horizontal position
		
		ld a, d
		cp $50 ;if we reach all 40 sprites, then we are done
	jr nz, menuLoadText.nextSong
	
	swapInRam on_deck
	
	ld hl, on_deck.active_buffer
	ldi a, [hl]
	xor $01
	ld h, a
	ld e, $0A
	
	.loop2:
		ld a, b
		ldi [hl], a
		ld a, c
		ldi [hl], a
		add $08
		ld c, a
		ld a, d
		ldi [hl], a
		add $02
		ld d, a
		ld [hl], $08
		inc hl
		
		dec e
	jr nz, menuLoadText.loop2
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SONG NAME GRAPHICS", ROMX
;song_names_vwf:
	BIGFILE song_names_vwf, $5000, assets/gfx/sprites/songNames.bin