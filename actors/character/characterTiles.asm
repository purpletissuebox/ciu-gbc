SECTION "CHARACTER TILES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads graphics for the character select scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

NUMTASKS = $000A

characterTiles:
	ld hl, NUMTASKS
	add hl, bc
	ld de, characterTiles.gfx_tasks
	ld a, [hl] ;use number of successfully completed tasks as an index into the task array
	cp ((characterTiles.end - characterTiles.gfx_tasks) >> 3)
		jr z, characterTiles.done ;if we completed them all, terminate
	add a
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de points to the next task to request
	call loadGraphicsTask
	jp submitGraphicsTask
	
	.done:
	ld e, c
	ld d, b
	call removeActor
	
	xor a
	ld de, characterTiles.character_text
	jp loadString ;load tile IDs into OAM. the sprite actor will handle moving them around.
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.gfx_tasks:
	GFXTASK character_tiles1, bkg_tiles0, $0800
	GFXTASK character_tiles2, bkg_tiles0, $0C00
	GFXTASK character_tiles3, bkg_tiles1, $0800
	GFXTASK character_tiles4, bkg_tiles1, $0C00
	GFXTASK character_map1, bkg_map
	GFXTASK character_attr1, bkg_attr
	GFXTASK character_map2, win_map
	GFXTASK character_attr2, win_attr
	.end
	
.character_text:
	db "CHARACTERSELECTSHANTAEROTTYTOPS\t"
	
SECTION "CHARACTER BACKGROUND", ROMX
align 4
	character_tiles1:
		INCBIN "../assets/gfx/bkg/character/sTiles.bin", $0000, $0400
		.end
	character_tiles2:
		INCBIN "../assets/gfx/bkg/character/sTiles.bin", $0400, $0400
		.end
	character_tiles3:
		INCBIN "../assets/gfx/bkg/character/rTiles.bin", $0000, $0400
		.end
	character_tiles4:
		INCBIN "../assets/gfx/bkg/character/rTiles.bin", $0400, $0350
		.end
		
	character_map1:
		INCBIN "../assets/gfx/bkg/character/sMap.bin"
		.end
	character_attr1:
		INCBIN "../assets/gfx/bkg/character/sAttr.bin"
		.end
	character_map2:
		INCBIN "../assets/gfx/bkg/character/rMap.bin"
		.end
	character_attr2:
		INCBIN "../assets/gfx/bkg/character/rAttr.bin"
		.end