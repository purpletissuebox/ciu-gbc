SECTION "SCENE CHANGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;changes the game mode according to its variable. wrapper for "changeScene".
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

changeSceneActor:
	ld hl, VARIABLE
	add hl, bc
	ld e, [hl]
	jp changeScene