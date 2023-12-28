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
	
	ld a, [active_oam_buffer]
	xor $01
	ld h, a
	ld l, LOW(on_deck)
	ld e, $0A
	call scrollText.adjustPos ;move 10 sprites in the buffer
	
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.scroll_amts:
	dw $7F7F, $0000, $0408, $0205, $0204, $0203, $0103, $0102, $0102, $0101, $0101, $0001, $0101, $0001, $0000, $0000 ;up
	dw $7F7F, $0000, $FCF8, $FEFB, $FEFC, $FEFD, $FFFD, $FFFE, $FFFE, $FFFF, $FFFF, $00FF, $FFFF, $00FF, $0000, $0000 ;down

.confirm:
	NEWACTOR swapBuffers, $00

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

TIMER = $0003

swapBuffers:
	ldh a, [$FF44]
	cp $7C
		jr nc, swapBuffers.ready ;wait until the on deck sprites have been rendered before switching. this way the graphics within one frame are consistent.
	
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		or [hl]
	jr z, swapBuffers ;check if other actors are waiting to run. if not, keep waiting for the scanline interrupt.
	
		ld e, c ;if so, respawn to give them a chance to run
		ld d, b
		call spawnActor
		.exit:
		ld e, c
		ld d, b
		jp removeActor
	
	.ready:
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc a ;increment timer, actor exits after $0F frames
	ld [hl], a
	and $0F
	jr z, swapBuffers.exit
	
	swapInRam active_oam_buffer
	ld de, active_oam_buffer
	ld a, [de]
	ld h, a ;hl points to active buffer
	xor $01
	ld [de], a ;toggle which one is active for next frame
	ld d, a ;de points to inactive buffer
	xor a
	ld e, a
	ld l, a
	
	ld c, $28
	rst $10 ;copy inactive to active to make sure other actors are doing work on an up-to-date copy
	
	ld a, [LYC_buffer] ;set LYC for next frame
	ldh [$FF45], a
	
	restoreBank "ram"
	ret