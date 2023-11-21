SECTION "TITLE_HUNTER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ends the title screen scene by "hunting down" other title screen actors and killing them.
;also spawns some new actors to facilitate loading in the new scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F
SINEACTOR = $0008

titleEnd:
.main:
	ld a, [press_input]
	and $08
	ret z ;wait for player to press start
	
	xor a
	ldh [music_on], a ;disable music
	updateActorMain titleEnd.wait
	
	xor a
	ld c, a ;c = actor table index
	.actorLoop:
		ld de, titleEnd.actor_table
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = actorTable[i]
		call spawnActor
		inc c ;i++
		ld a, c
		cp ((titleEnd.end - titleEnd.actor_table) >> 2)
	jr nz, titleEnd.actorLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wait:
	ld hl, TIMER
	add hl, bc
	inc [hl]
	ret nz ;wait for fadeout to finish
	
	ld e, c
	ld d, b
	call removeActor
	
	swapInRam save_string
	ld de, save_string
	ld hl, titleEnd.save_string
	ld c, $10
	rst $18
	
	ld a, MENU
	jr z, titleEnd.saveExists
		ld a, CHARACTER
	.saveExists:
	
	call changeScene
	restoreBank "ram"
	
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.sine_wave:
	NEWACTOR titleSineWave,$00
.main_menu:
	NEWACTOR menuManager,$00
.character_select:
	NEWACTOR characterManager,$00
.save_string:
	db "save file set up"
	
.actor_table:
	;NEWACTOR initSong,$01
	NEWACTOR setColors,$03
	NEWACTOR setColorsOBJ,$01
	.end
	
