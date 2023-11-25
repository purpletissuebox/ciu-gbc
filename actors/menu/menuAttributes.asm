;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads the current scroll position and calulates an offset into a big array of attributes for the main menu.
;each "row" in the attribute binary represents a 2 tile wide band.
;tiles in the upper part of the band are stored forward, while the lower part is stored backwards. there is some slight padding between bands.
;the pointer to the shadow attrs will snake around as attributes are copied in.
;finally, once shadow attr is updated, submit it as a graphics task.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

fetchAttributes:
	push bc
	swapInRam shadow_attr
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get scroll fraction
	
	;get x/y offsets based on scroll direction
	ld bc, $E0B0  ;if scrolling up, the band starts 32 pixels above and 80 pixels left of current scroll window
	bit 7, a
	jr z, fetchAttributes.up
		ld bc, $9008 ;if scrolling down, the band starts 32 pixels below the bottom left corner. this is 112 pixels below and 8 pixels right of the top left corner.
	.up:
	
	and $3F ;remove direction bit
	ld l, $00
	rra
	rr l
	rra
	rr l
	ld h, a ;multiply by 64. one band is 2 rows * 32 tiles per row
	ld de, menu_attr
	add hl, de
	ld e, l
	ld d, h ;source pointer to first row of band
	
	;one row on the attr map is worth 32 tiles and tiles are worth 8 pixels, so calculate dest = 32*(ypos/8) + (xpos/8) = ypos*4 + xpos/8
	ld h, $00
	ldh a, [$FF42] ;get y scroll
	add $08 ;to get us to the center of the double tile (helps with timing problems where screen has already scrolled a few px)
	add b
	and $F0 ;add y offset from above section and round to the nearest double tile
	rla
	rl h
	rla
	rl h
	ld l, a ;hl = ypos*4
	
	ldh a, [$FF43]
	add $04
	add c
	and $F8
	rrca
	rrca
	rrca ;calculate xpos/8
	or l ;we shifted y left by 2 and x right by 3 so we have covered the entire *32 difference. thus these bits will never overlap and we can just OR them in instead of adding
	ld l, a

	ld bc, shadow_attr
	add hl, bc ;destination pointer to first row of band
	
	ld c, $1D ;number of tiles to copy
	.evenRow:
		ld a, [de]
		inc de
		res 5, l ;as we move left to right, hl will overflow in bit 5 when we go down to the next (odd) row. since bit 5 is always 0 for even rows, clearing it will move us back up a row.
		ldi [hl], a
		dec c
	jr nz, fetchAttributes.evenRow
	
	ld c, $1D
	dec hl ;the previous ldi [hl], a put us one tile too far so back up
	
	.oddRow:
		ld a, [de]
		inc de
		set 5, l ;if we copy left to right this time, bit 5 will already be set and the overflow will propagate up to bit 6. this is very cpu intensive to detect.
		ldd [hl], a ;but if we copy right to left, bit 5 can just be blindly set to get the same wrapping behavior.
		dec c
		jr nz, fetchAttributes.oddRow
		
	restoreBank "ram"
	pop bc
	
	ld de, menuTilesInit.attr
	call loadGraphicsTask
	updateActorMain fetchAttributes.submit ;just in case other actors clog up the queue, attempt to resubmit until our new map goes through

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	and a
	jr nz, fetchAttributes.done
		jp submitGraphicsTask
	
	.done:
		ld e, c
		ld d, b
		jp removeActor