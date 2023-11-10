fetchAttributes:
	push bc
	swapInRam shadow_attr
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	ld bc, $E0B0
	bit 7, a
	jr z, fetchAttributes.up
		ld bc, $9008
	.up:
	and $3F
	ld l, $00
	rra
	rr l
	rra
	rr l
	ld h, a
	ld de, menu_attr
	add hl, de
	ld e, l
	ld d, h ;src
	
	ld h, $00
	ldh a, [$FF42]
	add $03
	add b
	and $F8
	rla
	rl h
	rla
	rl h
	ld l, a
	
	ldh a, [$FF43]
	add $03
	add c
	and $F8
	rrca
	rrca
	rrca
	or l
	ld l, a

	ld bc, shadow_attr
	add hl, bc ;dest
	
	ld c, $1D
	.evenRow:
		ld a, [de]
		inc de
		res 5, l
		ldi [hl], a
		dec c
	jr nz, fetchAttributes.evenRow
	
	ld c, $1D
	dec hl
	
	.oddRow:
		ld a, [de]
		inc de
		set 5, l
		ldd [hl], a
		dec c
		jr nz, fetchAttributes.oddRow
		
	restoreBank "ram"
	pop bc
	
	ld de, menuTilesInit.attr
	call loadGraphicsTask
	updateActorMain fetchAttributes.submit

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
		call removeActor
	ret