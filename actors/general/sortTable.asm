SECTION "SORT TABLE", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads save file to determine sort method to use, then writes to the global sort table.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

handleSort:
	push bc
	swapInRam save_file
	or a ;clear carry for multiply
	ld a, [sort_method]
	ld e, $00
	rra
	rr e
	rra
	rr e
	ld d, a ;de = index * 64
	ld hl, handleSort.table
	add hl, de ;hl = ptr to desired sort table
	
	ld de, sort_table
	ld c, $40
	.loop:
		ldi a, [hl]
		ld [de], a ;copy to global sort table
		inc de
		dec c
	jr nz, handleSort.loop
	
	restoreBank "ram"
	pop bc
	updateActorMain handleSort.flicker
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.flicker:
	ld hl, $000F
	add hl, bc
	inc [hl]
	ld a, [hl]
	and $03
		ret nz
	
	ld a, [hl]
	and $04
	ld de, $0B98
	jr z, handleSort.yellow
		ld de, $7423
	.yellow:
	swapInRam shadow_palettes
	ld hl, shadow_palettes + 8*4*2 + 1*4*2 + 3*2
	ld a, e
	ldi [hl], a
	ld [hl], d
	restoreBank "ram"
	ret

.table:
	INCBIN "../assets/code/sortMethods.bin"
	;0 = ID order
	;1 = genre
	;2 = score