SECTION "SETTINGS SCROLL", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;smoothly pulls the settings menu on or off the screen.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

settingsScroll:
.init:
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	and $80 ;use the topmost bit as a direction indicator - 0 = up and 1 = down
	rrca
	rrca ;convert to a starting index, 0 for up and 32 for down
	ld [hl], a
	updateActorMain settingsScroll.main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ld hl, SCROLLINDEX
	add hl, bc
	ld a, [hl]
	inc a
	ld [hl], a ;increment timer
	and $1F ;after 31 frames, exit
	jr nz, settingsScroll.doScroll
		ld e, c
		ld d, b
		jp removeActor
	.doScroll:
	
	ld a, [hl]
	ld de, settingsScroll.scrollTable
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to the current frame's scroll amount
	
	swapInRam shadow_winloc
	ld a, [de]
	ld [shadow_winloc], a ;save it to the global scroll
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.scrollTable:
	;up
	db $FF, $80, $70, $64, $5A, $51, $49, $42, $3B, $35, $30, $2B, $26, $22, $1E, $1A, $17, $14, $11, $0E, $0C, $0A, $08, $07, $05, $04, $03, $02, $01, $01, $00, $00
	;down
	db $FF, $00, $10, $1C, $26, $2F, $37, $3E, $45, $4B, $50, $55, $5A, $5E, $62, $66, $69, $6C, $6F, $72, $74, $76, $78, $79, $7B, $7C, $7D, $7E, $7F, $7F, $80, $80