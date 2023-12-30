SECTION "SETTINGS MANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

settingsManager:
	ld a, SETTINGS
	ldh [scene], a
	
	ld de, settingsManager.actor_list
	.spawnLoop:
		call spawnActor
		ld a, e
		sub LOW(settingsManager.end)
	jr nz, settingsManager.spawnLoop
	
	ld e, c
	ld d, b
	jp removeActor
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.actor_list:
	NEWACTOR settingsScroll, $00
	NEWACTOR settingsGraphics, $FF
	NEWACTOR settingsInput, $FF
	.end