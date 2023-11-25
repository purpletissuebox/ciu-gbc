SECTION "CHARACTER ENTRY", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;slides character portraits and text inwards from offscreen
;initalizes scroll registers and global variables for the toggle actor to take over later.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

characterEntry:
.stall:
	ld hl, VARIABLE
	add hl, bc
	dec [hl] ;wait for timer to expire
	ret nz
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.init:
	swapInRam shadow_scroll
	ld hl, shadow_scroll
	ld a, $60
	ldi [hl], a
	ld a, $48
	ldi [hl], a
	ld a, $28
	ldi [hl], a
	ld [hl], $A7 ;initalize scroll y registers. these will stay constant over the actor's lifespan.
	restoreBank "ram"
	ldh a, [$FF40]
	or $20
	ldh [$FF40], a ;enable window
	updateActorMain characterEntry.main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get variable = index into scroll table. we will be reading from it again later, so don't increment yet.
	cp $40 ;the timer is now counting back up
		jr z, characterEntry.exit
	
	ld de, characterEntry.scroll_table
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to scroll table entry. these are two bytes, one for bkg x and one for win x.
	
	swapInRam shadow_scroll
	ld hl, shadow_scroll+1
	ld a, [de]
	ldi [hl], a
	inc de
	inc hl
	ld a, [de]
	ldi [hl], a ;copy to scroll x registers
	
	;now we have to move the sprite layer.
	swapInRam shadow_oam
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get index into the scroll table again
	inc [hl]
	ld de, characterEntry.scroll_sprite_table
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to scroll table entry. these are four bytes: y coordinate for "CHARACTER" text, y coordinate for "SELECT" text, x coordinate for left side, x coordinate for right side.
	ld hl, shadow_oam
	ld bc, $0004 ;distance between oam entries
	
	;y coordinate is easy. just copy to each letter in the string.
	.charY:
		ld a, [de]
		ld [hl], a
		add hl, bc
		ld a, l
		sub LOW(shadow_oam + $24) ;"character" * (4 bytes/letter)
	jr nz, characterEntry.charY
	
	inc de
	.selY:
		ld a, [de]
		ld [hl], a
		add hl, bc
		ld a, l
		sub LOW(shadow_oam + $24 + $18) ;"select" * (4 bytes/letter)
	jr nz, characterEntry.selY
	
	;x coordinate is harder, we have to move to the right as we traverse the string.
	inc de
	inc hl
	ld bc, $0807 ;c = number of letters, b = distance between them
	ld a, [de] ;a is the starting scroll amt, it will accumulate as we move rightwards
	.sX:
		ldi [hl], a
		inc hl
		inc hl
		inc hl
		add b
		dec c
	jr nz, characterEntry.sX
	
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
	jr nz, characterEntry.rX
	
	restoreBank "ram"
	restoreBank "ram" ;???
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.exit:
	swapInRam character
	ld a, $01
	ld [character], a ;flag entrance as complete
	restoreBank "ram"
	ld de, characterEntry.flicker_actor ;get text colors going
	call spawnActor
	ld e, c
	ld d, b
	jp removeActor ;done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.flicker_actor:
	NEWACTOR characterFlicker,$00

.scroll_table:
	INCBIN "../assets/code/charScrollTable.bin"

.scroll_sprite_table:
	INCBIN "../assets/code/charSpriteTable.bin"