SECTION "SUBMENU BACKGROUND", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submenuBackground:
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor