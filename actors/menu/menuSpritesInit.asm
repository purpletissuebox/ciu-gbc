SECTION "MENU SPRITES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;sets up several global variables related to the sprite layer.
;copies strings to oam and initializes scanline interrupts.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuSpritesInit:
	ld e, c
	ld d, b
	jp removeActor