SECTION "SUBMENU DELAY", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submenuDelay:
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor