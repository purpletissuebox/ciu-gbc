SECTION "MENU HUD", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads tiles, attributes, and map for the hud on the menu scene.
;spawns child to load dynamic maps - the score and selected difficulty
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuHUDInit:
	swapInRam last_played_song
	ld e, c
	ld d, b
	restoreBank "ram"
	jp removeActor