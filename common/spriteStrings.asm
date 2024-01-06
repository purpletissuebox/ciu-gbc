SECTION "SPRITE STRINGS", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;routines to work with strings in oam using the assembler's character map.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

clearSprites: ;e = number of sprites to clear
;moves e sprites in oam to y position 0, which is off the top of the screen. preserves tile IDs.

	swapInRam shadow_oam
	ld hl, shadow_oam
	xor a
	.loop:
		ldi [hl], a ;y position
		ldi [hl], a ;x position
		inc hl
		ldi [hl], a ;palette
		dec e
	jr nz, clearSprites.loop
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
loadString: ;de = ptr to string to load
;reads a string and copies each character as a tile ID into oam.

	push bc
	ld bc, $0004 ;save bc to use as fast loop counter
	ld hl, shadow_oam + 2 ;tile ID
	add l
	ld l, a
	swapInRam shadow_oam
	
	.loop:
		ld a, [de]
		cp "\t"
			jr z, loadString.break ;loop while we dont have a terminator character
		inc de
		ld [hl], a
		add hl, bc ;point to the next oam entry
	jr loadString.loop
	
	.break:
	restoreBank "ram"
	pop bc
	ret