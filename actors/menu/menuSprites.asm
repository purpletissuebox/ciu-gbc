SECTION "MENU OBJ WRAPPER"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;spawns child actors to load new sprites on the menu scene.
;is passed a song ID in, which it will calculate a scroll fraction to pass to its children.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

menuSprites:
	ld e, c
	ld d, b
	call removeActor

	ld hl, VARIABLE
	add hl, bc
	ldi a, [hl]
	cp $80
		jr c, .menuSprites.up
	
	;song ID refers to the song below us. need the song above us instead.
	sub $02
	and $3F
	or $80
	jr menuSprites.summon
	
	.up:
	;song ID refers to the song above us. need the song off the top of the screen instead.
	dec a
	and $3F
	
	.summon:
	ld c, a
	ld de, menuSprites.load_oam_actor
	call spawnActorV
	
	ld a, c
	ld de, menuSprites.scroll_actor
	jp spawnActorV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.load_oam_actor:
	NEWACTOR menuLoadText, $FF

.scroll_actor:
	NEWACTOR scrollText, $FF