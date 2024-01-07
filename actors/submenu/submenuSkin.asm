SECTION "SUBMENU SKIN", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submenuSkin:
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor