SECTION "SCROLL TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

scrollText:
.init:
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get variable
	and $80
	rrca
	rrca
	rrca
	ld [hl], a ;convert direction bit into a starting index for scrolling. $01 for up and $11 for down.
	updateActorMain scrollText.main
	
.main:
	ld hl, SCROLLINDEX
	add hl, bc
	inc [hl]
	ld a, [hl] ;increment index and grab it. because the actor spawns a frame late, we will actually start at index 2.
	and $0F
	jr nz, scrollText.doScroll
		ld e, c
		ld d, b
		jp removeActor
	
	.doScroll:
	ld a, [hl]
	ld hl, scrollText.scroll_amts
	add a
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ldi a, [hl]
	ld b, a
	ld c, [hl] ;b = y distance, c = x distance
	
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld e, $28
	call scrollText.adjustPos
	
	swapInRam on_deck
	ld hl, on_deck
	ld e, $28
	call scrollText.adjustPos
	
	ld hl, up_next
	ld e, $14
	call scrollText.adjustPos
	
	restoreBank "ram"
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.scroll_amts:	
	dw $7F7F, $0000, $0102, $0103, $0102, $0202, $0102, $0103, $0102, $0102, $0103, $0102, $0202, $0102, $0103, $0102 ;up
	dw $7F7F, $0000, $FFFE, $FFFD, $FFFE, $FEFE, $FFFE, $FFFD, $FFFE, $FFFE, $FFFD, $FFFE, $FEFE, $FFFE, $FFFD, $FFFE ;down

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.adjustPos: ;hl points to oam, b = y axis adjustment, c = x axis adjustment, e = number of sprites to adjust
	ld a, [hl]
	add b
	ldi [hl], a
	ld a, [hl]
	add c
	ldi [hl], a
	inc hl
	inc hl
	dec e
jr nz, scrollText.adjustPos
ret