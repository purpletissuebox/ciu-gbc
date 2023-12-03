SECTION "MENU MAP", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;edits the tilemap to display new tiles just offscreen.
;reads from global variables to determine where the new tiles will load in, then reads scroll registers to find where to write their IDs to.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
FIRSTENTRY = $0004

menuMap:
.init:
;sets up some local variables to prepare for the copy later.
;need to calculate the starting tile ID and how many tiles to advance after the chunk is copied.
;we read from global memory to get a live update on which chunks are about to be overwritten.
	updateActorMain menuMap.main
	swapInRam menu_bkg_index
	
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]	
	and $80 ;check if we are scrolling up or down
	
	ld de, menuMap.chunk_differences_up
	jr z, menuMap.copy
		ld de, menuMap.chunk_differences_down ;and grab the appropriate table. these are the distances between chunks.
	
	.copy:
		inc hl ;skip the first byte of each entry and fill it in later
		ld a, [de] ;check for terminator
		inc de
			cp $FF
			jr z, menuMap.break
		ldi [hl], a
		ld a, [de]
		inc de
		ldi [hl], a ;copy the distance in the latter 2 bytes of each entry
	jr menuMap.copy
	.break:
	
	;there are 10 regions total. the first two are horizontal bands and have to be handled seperately.
	ld hl, FIRSTENTRY
	add hl, bc
	ld a, [menu_bkg_index] ;get which step the bands are on. assume band #2 is on the same step as #1
	ld e, a
	add a
	add e
	add a
	add a
	add e ;the horizontal bands' steps take up 13 tiles of vram.
	add $80 ;and the first tile of step 0 is 80. now a contains the first tile of whichever step we are actually on
	ldi [hl], a
	
	;the remaining regions are vertical stripes which are all the same size. we can handle them in a loop.
	inc hl
	inc hl
	ld c, l
	ld b, h ;bc points to the current entry
	ld de, menu_bkg_index + $0002 ;de points to the current step
	ld hl, menuMap.chunk_offsets ;hl points to the first tile in the step
	
	.loop:
		ld a, [de] ;get step number
		inc de
		add a
		add a
		add a ;vertical stripes use 8 tiles per step
		add [hl] ;add the starting tile ID, now a = first tile of this step
		inc hl
		
		ld [bc], a ;save the tile id to the current entry, then go to the next one
		inc bc
		inc bc
		inc bc
		add $04 ;the next entry comes 4 tiles later, because 2 regions share the same step.
		ld [bc], a
		inc bc
		inc bc
		inc bc
		
		ld a, e
		sub LOW(menu_bkg_index.end)
	jr nz, menuMap.loop
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	push bc
	swapInRam shadow_map
	
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get scroll fraction
	ld c, l
	ld b, h ;bc points to current entry
	
	and $80
	ld de, $8844;$9048
	jr nz, menuMap.down
		ld de, $E8F4;$E0F0 ;d/e = number of pixels below/right of the screen's top-left corner
	.down:
	
	;one row on the attr map is worth 32 tiles and tiles are worth 8 pixels, so calculate dest = 32*(ypos/8) + (xpos/8) = ypos*4 + xpos/8
	ld h, $00
	ldh a, [$FF42] ;get y scroll
	add $08 ;to get us to the center of the double tile (helps with timing problems where screen has already scrolled a few px)
	add d
	and $F0 ;add y offset from above section and round to the nearest double tile
	add a
	rl h
	add a
	rl h
	ld l, a ;hl = ypos*4
	
	ldh a, [$FF43]
	add $04
	add e
	and $F8
	rrca
	rrca
	rrca ;calculate xpos/8
	or l ;we shifted y left by 2 and x right by 3 so we have covered the entire *32 difference. thus these bits will never overlap and we can just OR them in instead of adding
	ld l, a
	
	ld de, shadow_map
	add hl, de ;hl points to destination tile. top left of first band.
	
	ld a, [bc] ;get tile ID
	inc bc
	ld e, $0D ;loop counter
	
	;the bands use the same tile IDs, just in different banks.
	.bands:
		set 5, l ;move to lower band
		ld [hl], a ;write
		res 5, l ;upper band
		ldi [hl], a ;write
		inc a ;next tile
		dec e
	jr nz, menuMap.bands
	
	;now copy in the stripes. for each entry in the actor's ram, we need to get the tile id, write it to 4 tiles moving downward each time, and then apply the travel distance to reach the next stripe.
	;bc points to the current entry (starts at distance), hl points to vram, de is a working register
	xor a
	.bigLoop:
		ldh [scratch_byte], a ;loop counter
		ld a, [bc]
		inc bc
		ld e, a
		ld a, [bc] ;read travel distance
		inc bc
		ld d, a 
		add hl, de ;travel to next stripe
		res 5, l
		res 2, h ;worst case scenario, we overflow in both x and y directions. luckily, stripes are aligned on a 2x2 grid, so round down on both bits to fix the overflow.
		
		ld de, $0020 ;de = distance to tile directly underneath current one
		ld a, [bc] ;get tile ID
		inc bc
		
		REPT 4
			ld [hl], a ;save tile ID
			inc a
			add hl, de ;go to below tile
			res 2, h ;wrap in y direction
		ENDR
		
		ldh a, [scratch_byte]
		inc a
		cp $08
	jr nz, menuMap.bigLoop
	
	restoreBank "ram"	
	pop bc
	
	ld hl, $000A
	add hl, bc
	ld [hl], $00 ;shadow map is updated now, so throw this away.
	ld de, menuMap.task
	call loadGraphicsTask
	updateActorMain menuMap.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.submit:
	call submitGraphicsTask
	ld hl, $000A
	add hl, bc
	ld a, [hl]
	and a
	jr z, menuMap.tryAgain
		ld e, c
		ld d, b
		call removeActor
	.tryAgain:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.chunk_differences_up:
	dw $0053, $030D, $0093, $028F, $0111, $0211, $018F, $0193
	db $FF
.chunk_differences_down:
	dw $0012, $030D, $0011, $028F, $008F, $0211, $010D, $0193
	db $FF
	
.chunk_offsets:
	db $20, $20, $58, $68
	
.task:
	GFXTASK shadow_map, bkg_map, $0000