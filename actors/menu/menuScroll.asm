SECTION "MENU SCROLLER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;scrolls the screen either up or down by one "menu unit".
;if the variable is negative, scroll 2 tiles down and 1 tile right.
;if the variable is positive, scroll 2 tiles up and 1 tile left.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

menuScroller:
.init:
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl] ;get variable
	and $80
	rrca
	rrca
	rrca ;convert to either 0 if positive, 10 if negative. this will be the index into the scroll table later.
	ldi [hl], a
	ldh a, [$FF42]
	ldi [hl], a
	ldh a, [$FF43]
	ldi [hl], a ;write original scroll values to actor ram
	updateActorMain menuScroller.main
	
.main:
	ld hl, SCROLLINDEX
	add hl, bc
	inc [hl]
	ld a, [hl] ;get index into table of scroll offsets
	and $0F
	jr nz, menuScroller.doScroll ;if we have scrolled for the full 15 frames, exit.
		ld e, c
		ld d, b
		jp removeActor
		
	.doScroll:
	swapInRam shadow_scroll
	ldi a, [hl] ;get index again, hl now points to original scroll y
	add a
	ld de, menuScroller.scroll_offsets
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = scroll_offsets[i]
	
	ld bc, shadow_scroll
	ld a, [de]
	inc de
	add [hl]
	inc hl
	ld [bc], a ;shadow_scroll_y = original_y + scroll_offset[i]
	inc bc
	ld a, [de]
	add [hl]
	ld [bc], a ;same but for x direction
	restoreBank "ram"
	ret
	
.scroll_offsets:
	dw $7F7F, $0000, $FFFF, $FFFE, $FEFD, $FEFB, $FDFA, $FDF9, $FCF8, $FBF7, $FBF6, $FAF5, $FAF3, $F9F2, $F9F1, $F8F0 ;up
	dw $7F7F, $0000, $0101, $0102, $0203, $0205, $0306, $0307, $0408, $0509, $050A, $060B, $060D, $070E, $070F, $0810 ;down