SECTION "TITLESPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;fills oam with the correct letters for the title screen.
;loads tile ID, screen position, and palette.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

titleSpriteLoader:
	push bc
	swapInRam shadow_oam
	ld a, $2C ;x coordinate of first tile
	ld bc, $0005 ;increase in pointer value
	ld de, $0800 ;d = increase in x coordinate / e = y coordinate
	ld hl, shadow_oam + 1
	
	.locationLoop:
		ldd [hl], a ;save x coordinate
		ld [hl], e ;save y coordinate
		add hl, bc ;go to next oam entry
		add d ;increase x coordinate
		cp $84 ;loop until the other side of the screen is reached
	jr nz, titleSpriteLoader.locationLoop
	
	xor a ;start filling oam at entry 0
	ld de, titleSpriteLoader.message
	call loadString
	
	restoreBank "ram"
	pop de ;de = ptr to actor
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.message:
	db "Press Start\t"
