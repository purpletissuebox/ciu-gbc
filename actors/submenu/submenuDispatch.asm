SECTION "SUBMENU DISPATCH", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

submenuDispatch:
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	add a
	
	ld de, submenuDispatch.actor_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	call spawnActor
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.actor_table:
	NEWACTOR submenuSpeed, $FF
	NEWACTOR submenuSkin, $FF
	NEWACTOR submenuRebind, $FF
	NEWACTOR submenuSort, $FF
	NEWACTOR submenuDelay, $FF
	NEWACTOR submenuLeadin, $FF
	NEWACTOR submenuBackground, $FF
	NEWACTOR submenuColors, $FF
	NEWACTOR submenuJudgement, $FF