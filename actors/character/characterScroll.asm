SECTION "CHARACTER SCROLL", ROMX

VARIABLE = $0003

characterScroller:
.stall:
	ld hl, VARIABLE
	add hl, bc
	dec [hl]
	ret nz

.init:
	swapInRam shadow_scroll
	ld hl, shadow_scroll
	ld a, $60
	ldi [hl], a
	ld a, $48
	ldi [hl], a
	ld a, $28
	ldi [hl], a
	ld [hl], $A7
	restoreBank "ram"
	ldh a, [$FF40]
	or $20
	ldh [$FF40], a
	updateActorMain characterScroller.main
	
.main:
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	cp $40
	jr z, characterScroller.exit
	
	ld de, characterScroller.scroll_table
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	swapInRam shadow_scroll
	ld hl, shadow_scroll+1
	ld a, [de]
	ldi [hl], a
	inc de
	inc hl
	ld a, [de]
	ldi [hl], a
	;;;;;;;;;;;;;;;;;;;;
	swapInRam shadow_oam
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	inc [hl]
	ld de, characterScroller.scroll_sprite_table
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	ld hl, shadow_oam
	ld bc, $0004
	
	.charY:
		ld a, [de]
		ld [hl], a
		add hl, bc
		ld a, l
		sub LOW(shadow_oam + $24) ;"character"
	jr nz, characterScroller.charY
	
	inc de
	.selY:
		ld a, [de]
		ld [hl], a
		add hl, bc
		ld a, l
		sub LOW(shadow_oam + $24 + $18) ;"select"
	jr nz, characterScroller.selY
	
	inc de
	inc hl
	ld bc, $0807
	ld a, [de]
	.sX:
		ldi [hl], a
		inc hl
		inc hl
		inc hl
		add b
		dec c
	jr nz, characterScroller.sX
	
	inc de
	ld c, $09
	ld a, [de]
	.rX:
		ldi [hl], a
		inc hl
		inc hl
		inc hl
		add b
		dec c
	jr nz, characterScroller.rX
	pop af
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	restoreBank "ram"
	ret
	
.exit:
	swapInRam character
	ld a, $01
	ld [character], a
	restoreBank "ram"
	ld de, characterScroller.flicker_actor
	call spawnActor
	ld e, c
	ld d, b
	call removeActor
	ret

.flicker_actor:
	NEWACTOR characterFlicker,$00

.scroll_table:
	INCBIN "../assets/code/charScrollTable.bin"

.scroll_sprite_table:
	INCBIN "../assets/code/charSpriteTable.bin"