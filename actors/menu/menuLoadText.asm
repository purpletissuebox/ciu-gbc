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
	ld a, [hl] ;variable = external ID for the new song to render
	ldh [scratch_byte], a
	
	ld hl, TASKSRC
	add hl, bc
	cp $80
	dec a
	jr c, menuLoadText.up
		add $03
	.up:
	and $3F
	
	ld d, a
	ld e, a
	srl e
	rra
	srl e
	rra
	add $40
	ldi [hl], a
	ld a, d
	adc e
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
	ld a, e
	srl e
	rra
	srl e
	rra
	and $C0
	add LOW(sprite_tiles1) | BANK(sprite_tiles1)
	ldi [hl], a
	ld a, d
	adc e
	add HIGH(sprite_tiles1)
	ldi [hl], a
	ld [hl], $13
	
	ldh a, [scratch_byte]
	cp $80
	ld a, [menu_text_head]
	jr nc, menuLoadText.down
	
	;up
	ld bc, $F800
	sub $01
	jr nc, menuLoadText.goodIndexUp
		ld a, $04
	.goodIndexUp:
	ld [menu_text_head], a
	ldh [scratch_byte], a
	ld hl, shadow_oam
	
	.loopUp:
		ldh a, [scratch_byte]
		inc a
		cp $05
		jr c, menuLoadText.proceedUp
			xor a
		.proceedUp:
		ldh [scratch_byte], a
		ld e, a
		add a
		add a
		swap e
		add e
		ld d, a
		call menuLoadText.loadSong

		ld a, b
		add $20
		ld b, a
		rrca
		add $04
		ld c, a
		cp $48
	jr c, menuLoadText.loopUp
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a
	ld a, c
	cp $48
	jr z, menuLoadText.loopUp
	jr menuLoadText.cleanup		
	
	.down:
	ld e, a
	ld bc, $1810
	inc a
	cp $05
	jr c, menuLoadText.goodIndexDown
		xor a
	.goodIndexDown:
	ld [menu_text_head], a
	ld a, e
	ldh [scratch_byte], a
	ld hl, shadow_oam
	
	.loopDown:
		ldh a, [scratch_byte]
		sub $01
		jr nc, menuLoadText.proceedDown
			ld a, $05
		.proceedDown:
		ldh [scratch_byte], a
		ld e, a
		add a
		add a
		swap e
		add e
		ld d, a
		call menuLoadText.loadSong
		
		ld a, b
		add $20
		ld b, a
		rrca
		add $04
		ld c, a
		cp $58
	jr c, menuLoadText.loopDown
	
	ld l, $00
	ld a, [active_oam_buffer]
	xor $01
	ld h, a
	ld a, c
	cp $58
	jr z, menuLoadText.loopDown
	
	.cleanup:
	restoreBank "ram"
	restoreBank "ram"
	pop de
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