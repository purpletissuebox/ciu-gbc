SECTION "SCROLL TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads scroll direction and moves the entire sprite layer up or down accordingly.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

scrollText:
.init:
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get variable
	ld de, scrollText.lyc_worker
	call spawnActorV
	
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	and $80
	rrca
	rrca
	rrca
	ld [hl], a ;convert direction bit into a starting index for scrolling. $00 for up and $10 for down.
	updateActorMain scrollText.main
	
.main:
	ld hl, SCROLLINDEX
	add hl, bc
	inc [hl]
	ld a, [hl] ;increment index and grab it
	and $0F ;scroll ends after 15 frames regardless of starting index
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
	ld h, a ;hl points to current scroll entry
	
	ldi a, [hl]
	ld b, a
	ld c, [hl] ;b = y distance, c = x distance (because dw flips the bytes)
	
	swapInRam shadow_oam
	ld hl, shadow_oam
	ld e, $28
	call scrollText.adjustPos ;copy 40 sprites to shadow oam
	
	swapInRam on_deck
	ld a, [on_deck.active_buffer]
	and $FE
	ld h, a
	ld l, $00 ;ld hl, on_deck
	ld e, $28
	call scrollText.adjustPos ;copy 40 sprites to backup oam
	
	ld a, [on_deck.active_buffer]
	or $01
	ld h, a
	ld l, $00 ;ld hl, up_next
	ld e, $14
	call scrollText.adjustPos ;copy 20 sprites to backup oam #2
	
	restoreBank "ram"
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.scroll_amts:	
	dw $7F7F, $0000, $0102, $0103, $0102, $0202, $0102, $0103, $0102, $0102, $0103, $0102, $0202, $0102, $0103, $0102 ;up
	dw $7F7F, $0000, $FFFE, $FFFD, $FFFE, $FEFE, $FFFE, $FFFD, $FFFE, $FFFE, $FFFD, $FFFE, $FEFE, $FFFE, $FFFD, $FFFE ;down
	
.lyc_worker:
	NEWACTOR scanlineBuddy, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.adjustPos: ;hl points to oam, b = y axis adjustment, c = x axis adjustment, e = number of sprites to adjust
	ld a, [hl]
	add b
	ldi [hl], a ;add y position
	ld a, [hl]
	add c
	ldi [hl], a ;add x position
	inc hl
	inc hl ;point to next entry
	dec e
jr nz, scrollText.adjustPos
ret