SECTION "SUBMENU DISPATCH", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;chooses a handler according to its variable to load a submenu.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

submenuDispatch:
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get which submenu we are on
	add a
	add a ;a = submenu*sizeof(actor)
	
	ld de, submenuDispatch.actor_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to the handler of choice
	call spawnActor ;spawn it
	
	ld e, c
	ld d, b
	jp removeActor ;done!

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