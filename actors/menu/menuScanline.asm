SECTION "SCANLINE SAM", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;adjusts when the scanline interrupt fires as the screen scrolls.
;avoids text sprites getting cut off by waiting until they are rendered to display more.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

scanlineBuddy:
.init:
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	and $80
	rrca
	rrca
	rrca
	ldi [hl], a ;convert variable into an index, $00 for up and $10 for down
	
	swapInRam on_deck
	ld a, [on_deck.LYC_buffer]
	ld [hl], a ;save original scanline compare to local memory + 5
	restoreBank "ram"
	
	updateActorMain scanlineBuddy.main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	ld hl, SCROLLINDEX
	add hl, bc
	inc [hl] ;increment index before we read it
	ld a, [hl]
	and $0F ;that way this check will last 15 frames instead of 16
	jr nz, scanlineBuddy.continue
		ld e, c
		ld d, b
		jp removeActor
	
	.continue:
	ldi a, [hl] ;reobtain index, hl now points to the base LYC
	ld de, scanlineBuddy.scanline_adjustments
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to the offset
	
	swapInRam on_deck
	ld a, [de]
	add [hl]
	ld [on_deck.LYC_buffer], a ;apply offset and save it back
	restoreBank "ram"
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.scanline_adjustments:
	db $7F, $00, $08, $0D, $11, $14, $17, $19, $1B, $1C, $1D, $1E, $1F, $20, $20, $20 ;up
	db $7F, $00, $F8, $F3, $EF, $EC, $E9, $E7, $E5, $E4, $E3, $E2, $E1, $E0, $E0, $E0 ;down
