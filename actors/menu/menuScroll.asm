SECTION "MENU SCROLLER", ROMX

menuScroller:
.init:
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	and $80
	rrca
	rrca
	rrca
	ldi [hl], a
	ldh a, [$FF42]
	ldi [hl], a
	ldh a, [$FF43]
	ldi [hl], a
	updateActorMain menuScroller.main
	
.main:
	ld hl, $0004
	add hl, bc
	inc [hl]
	ld a, [hl]
	and $0F
	jr nz, menuScroller.doScroll
		ld e, c
		ld d, b
		jp removeActor
		
	.doScroll:
	swapInRam shadow_scroll
	ldi a, [hl]
	add a
	ld de, menuScroller.offsets
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld bc, shadow_scroll
	ld a, [de]
	inc de
	add [hl]
	inc hl
	ld [bc], a
	inc bc
	ld a, [de]
	add [hl]
	ld [bc], a
	restoreBank "ram"
	ret
	
.offsets:
	dw $7F7F, $0000, $FFFF, $FFFE, $FEFD, $FEFB, $FDFA, $FDF9, $FCF8, $FBF7, $FBF6, $FAF5, $FAF3, $F9F2, $F9F1, $F8F0
	dw $7F7F, $0000, $0101, $0102, $0203, $0205, $0306, $0307, $0408, $0509, $050A, $060B, $060D, $070E, $070F, $0810