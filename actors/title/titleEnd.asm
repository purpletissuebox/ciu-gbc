SECTION "TITLE_HUNTER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ends the title screen scene by "hunting down" other title screen actors and killing them.
;also spawns some new actors to facilitate loading in the new scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F
SINEACTOR = $0008

titleHunter:
.init:
	ld hl, SINEACTOR
	add hl, bc
	ldh a, [next_actor]
	ldi [hl], a
	ldh a, [next_actor+1]
	ldi [hl], a ;before spawning the sine wave, record where it will load in
	ld de, titleHunter.sine_wave
	call spawnActor
	
	updateActorMain titleHunter.main
ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ld a, [press_input]
	and $08
	ret z ;wait for player to press start
	
	xor a
	ldh [music_on], a ;disable music
	updateActorMain titleHunter.wait
	
	xor a
	ld c, a ;c = actor table index
	.actorLoop:
		ld de, titleHunter.actor_table
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
		cp ((titleHunter.end - titleHunter.actor_table) >> 2)
	jr nz, titleHunter.actorLoop
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wait:
	ld hl, TIMER
	add hl, bc
	inc [hl]
	ret nz ;wait for fadeout to finish
	
	push bc
	ld hl, SINEACTOR
	add hl, bc
	ldi a, [hl]
	ld d, [hl]
	ld e, a
	call removeActor
	
	ld e, $0B
	call clearSprites ;remove press start text
	
	pop de ;de = self
	call removeActor
	
	swapInRam save_string
	ld de, save_string
	ld hl, titleHunter.save_string
	ld c, $10
	rst $18
	
	ld a, MENU
	jr z, titleHunter.saveExists
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
	
