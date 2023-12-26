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

	and $3F
	ld d, a
	ld e, a
	xor a
	srl e
	rra
	srl e
	rra
	add $40
	ldi [hl], a
	ld a, d
	adc e
	ld d, a
	or $40
	ldi [hl], a
	
	ld a, BANK(song_names_vwf)
	bit 6, d
	jr z, menuLoadText.smallBank
		inc a
	.smallBank:
	ldi [hl], a
	
	swapInRam menu_text_head
	ld a, [menu_text_head]
	ld d, a
	ld e, a
	xor a
	srl e
	rra
	srl e
	rra
	add LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, d
	adc e
	add HIGH(sprite_tiles1)
	ldi [hl], a
	
	ld [hl], $13
	
	ldh a, [scratch_byte]
	cp $80
	jr nc, menuLoadText.down
	
	;up
	ld a, [menu_text_head]
	ld e, a
	sub $01
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
	ld d, a
	
	ld hl, shadow_oam
	ld bc, $F800 + STARTX
	
	.loopUp:
		call menuLoadText.loadSong
		
		ld a, d
		sub $64
		jr nz, menuLoadText.tileWrapUp
			ld d, a
		.tileWrapUp:
		ld a, b
		add $20
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a
		cp $40 + STARTX
	jr c, menuLoadText.loopUp
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a
	ld a, c
	cp $40 + STARTX
	jr z, menuLoadText.loopUp
	jr menuLoadText.cleanup
	
	.down:
	ld a, [menu_text_head]
	inc a
	cp $05
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
	ld d, a
	
	ld hl, shadow_oam
	ld bc, $1810 + STARTX
	
	.loopDown:
		call menuLoadText.loadSong
		
		ld a, d
		sub $64
		jr nz, menuLoadText.tileWrapDown
			ld d, a
		.tileWrapDown:
		ld a, b
		add $20
		ld b, a
		rrca
		add $04 + STARTX
		ld c, a
		cp $50 + STARTX
	jr c, menuLoadText.loopDown
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a
	ld a, c
	cp $50 + STARTX
	jr z, menuLoadText.loopDown
	
	.cleanup:
	restoreBank "ram"
	restoreBank "ram"
	pop bc
	updateActorMain menuLoadText.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
		ret nz
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.loadSong:
	ld e, $0A
	.nextSprite:
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
	jr nz, menuLoadText.nextSprite
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SONG NAME GRAPHICS", ROMX
;song_names_vwf:
	BIGFILE song_names_vwf, $8000, assets/gfx/sprites/songNames.bin