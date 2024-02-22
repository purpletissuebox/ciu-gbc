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
	NEWACTOR submenuNumber, $00 ;scroll speed
	NEWACTOR submenuSkin, $FF ;note skin
	NEWACTOR submenuRebind, $FF ;key bindings
	NEWACTOR submenuList, $00 ;sort method
	NEWACTOR submenuNumber, $01 ;input delay
	NEWACTOR submenuNumber, $02 ;lead-in time
	NEWACTOR submenuList, $01 ;background
	NEWACTOR submenuList, $02 ;color scheme
	NEWACTOR submenuNumber, $03 ;judgement