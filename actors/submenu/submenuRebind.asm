SECTION "SUBMENU BINDINGS", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submenuRebind:
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor