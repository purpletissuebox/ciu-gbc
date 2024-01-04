SECTION "SETTINGS SCROLL", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
SCROLLINDEX = $0004

settingsScroll:
.init:
	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	and $80
	rrca
	rrca
	ld [hl], a
	updateActorMain settingsScroll.main
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ld hl, SCROLLINDEX
	add hl, bc
	ld a, [hl]
	inc a
	ld [hl], a
	and $1F
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
	ld d, a
	
	swapInRam shadow_winloc
	ld a, [de]
	ld [shadow_winloc], a
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.scrollTable:
	;up
	db $FF, $80, $70, $64, $5A, $51, $49, $42, $3B, $35, $30, $2B, $26, $22, $1E, $1A, $17, $14, $11, $0E, $0C, $0A, $08, $07, $05, $04, $03, $02, $01, $01, $00, $00
	;down
	db $FF, $00, $10, $1C, $26, $2F, $37, $3E, $45, $4B, $50, $55, $5A, $5E, $62, $66, $69, $6C, $6F, $72, $74, $76, $78, $79, $7B, $7C, $7D, $7E, $7F, $7F, $80, $80