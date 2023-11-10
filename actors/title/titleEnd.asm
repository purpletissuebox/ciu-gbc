SECTION "TITLE_HUNTER", ROMX

TIMER = $000F
SINEACTOR = $0008

titleHunter:
.init:
	ld hl, SINEACTOR
	add hl, bc
	ldh a, [next_actor]
	ldi [hl], a
	ldh a, [next_actor+1]
	ldi [hl], a
	ld de, titleHunter.sine_wave
	call spawnActor
	updateActorMain titleHunter.main
ret
	
.main:
	ld a, [press_input]
	and $08
	ret z
	
	xor a
	ldh [music_on], a
	updateActorMain titleHunter.wait
	
	xor a ;a = actor table index
	.actorLoop:
		cp ((titleHunter.end - titleHunter.actor_table) >> 2)
		ret z
		ldh [scratch_byte], a
		ld de, titleHunter.actor_table
		add a
		add a
		add e
		ld e, a
		ld a, d
		adc $00
		ld d, a ;de = actorTable[i]
		call spawnActor
		ldh a, [scratch_byte]
		inc a ;i++
	jr titleHunter.actorLoop
	
.wait:
	ld hl, TIMER
	add hl, bc
	inc [hl]
	;ld a, $FE ;fadeout takes 53 frames + 80 to start
	;sub [hl]
	jr nz, titleHunter.notYet ;wait for fadeout to finish
		push bc
		ld hl, SINEACTOR
		add hl, bc
		ldi a, [hl]
		ld d, [hl]
		ld e, a
		call removeActor
		
		ld e, $0B
		call clearSprites
		
		pop de ;de = self
		call removeActor
		
		swapInRam save_string
		ld de, save_string
		ld hl, titleHunter.save_string
		ld c, $10
		rst $18
		
		ld de, titleHunter.main_menu
		jr z, titleHunter.saveExists
			ld de, titleHunter.character_select
		.saveExists:
		
		restoreBank "ram"
		call spawnActor
	.notYet:
	ret
	
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
	
