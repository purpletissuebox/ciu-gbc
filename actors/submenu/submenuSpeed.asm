SECTION "SUBMENU SPEED", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submenuSpeed:
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor