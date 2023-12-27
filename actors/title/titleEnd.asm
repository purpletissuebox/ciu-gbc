SECTION "TITLE_HUNTER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;ends the title screen scene by "hunting down" other title screen actors and killing them.
;also spawns some new actors to facilitate loading in the new scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TIMER = $000F

titleEnd:
.main:
	ld a, [press_input]
	and $08
	ret z ;wait for player to press start
	push bc
	
	xor a
	ldh [music_on], a ;disable music
	
	ld de, titleEnd.remove_sprites
	call spawnActor ;fade sprite layer
	
	swapInRam save_string
	ld de, save_string
	ld hl, titleEnd.save_string
	ld c, $10
	rst $18 ;check if save file contains a special string
	
	ld b, $03 ;if it does, progress to the menu scene
	jr z, titleEnd.saveExists
		;inc b ;else character scene
	.saveExists:
	
	restoreBank "ram"
	ld a, b	
	ld de, titleEnd.remove_bkg
	call spawnActorV
	
	pop de
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.save_string:
	db "save file set up"
	
.remove_sprites:
	NEWACTOR setColorsOBJ,$01

.remove_bkg:
	NEWACTOR setColors,$FF
	
