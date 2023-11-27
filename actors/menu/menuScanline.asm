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
	ld [hl], a
	
	updateActorMain scanlineBuddy.main

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	ld hl, SCROLLINDEX
	add hl, bc
	inc [hl]
	ld a, [hl]
	and $0F
	jr nz, scanlineBuddy.continue
		ld e, c
		ld d, b
		jp removeActor
	
	.continue:
	ld e, [hl]
	ld hl, scanlineBuddy.scanline_adjustments
	ld d, $00
	add hl, de
	
	di
	ldh a, [$FF45]
	add [hl]
	ldh [$FF45], a
	reti
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.scanline_adjustments:
	db $7F, $00, $02, $03, $02, $02, $02, $03, $02, $02, $03, $02, $02, $02, $03, $02
	db $7F, $00, $FE, $FD, $FE, $FE, $FE, $FD, $FE, $FE, $FD, $FE, $FE, $FE, $FD, $FE
