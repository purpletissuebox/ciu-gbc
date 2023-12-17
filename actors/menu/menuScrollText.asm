SECTION "SCROLL TEXT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads scroll direction and moves the entire sprite layer up or down accordingly.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

scrollText:
.init:	
	ld de, scrollText.confirm
	call spawnActor
	
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
	call scrollText.adjustPos ;move 40 sprites in shadow oam
	
	swapInRam active_oam_buffer
	ld hl, active_oam_buffer
	ldi a, [hl]
	xor $01
	ld h, a
	ld e, $0A
	call scrollText.adjustPos ;move 10 sprites in the buffer
	
	restoreBank "ram"
	restoreBank "ram"

	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.scroll_amts:
	dw $7F7F, $0000, $0408, $0205, $0204, $0203, $0103, $0102, $0102, $0101, $0101, $0001, $0101, $0001, $0000, $0000 ;up
	dw $7F7F, $0000, $FCF8, $FEFB, $FEFC, $FEFD, $FFFD, $FFFE, $FFFE, $FFFF, $FFFF, $00FF, $FFFF, $00FF, $0000, $0000 ;down

.confirm:
	NEWACTOR swapBuffers, $FF

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

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SCANLINE BUFFER SWAP", ROMX

TIMER = $000F

swapBuffers:
.first:
	ldh a, [$FF44]
	cp $7C
		jr nc, swapBuffers.ready
	
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		or [hl]
	jr z, swapBuffers
	
		ld e, c
		ld d, b
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor
	
	.ready:
	updateActorMain swapBuffers.subsequent
	ld hl, TIMER
	add hl, bc
	ld [hl], $0F
	
	swapInRam active_oam_buffer
	ld de, active_oam_buffer
	ld a, [de]
	ld h, a
	xor $01
	ld [de], a
	ld d, a
	xor a
	ld e, a
	ld l, a
	
	push bc
	ld c, $28
	rst $10
	pop de
	
	ld a, [LYC_buffer]
	ldh [$FF45], a
	
	restoreBank "ram"
	ret

.subsequent:
	ldh a, [$FF44]
	cp $7C
		jr nc, swapBuffers.ready2
	
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		or [hl]
	jr z, swapBuffers.subsequent
	
		ld e, c
		ld d, b
		call spawnActor
		ld e, c
		ld d, b
		jp removeActor
	
	.ready2:
	ld hl, TIMER
	add hl, bc
	dec [hl]
	jr nz, swapBuffers.doTheSwap
		ld e, c
		ld d, b
		jp removeActor
	.doTheSwap:
	swapInRam active_oam_buffer
	ld a, [active_oam_buffer]
	xor $01
	ld [active_oam_buffer], a
	restoreBank "ram"
	ret