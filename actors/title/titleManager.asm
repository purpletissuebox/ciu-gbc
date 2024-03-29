SECTION "TITLEMANAGER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;orchestrates the spawning of all the actors related to the title screen state of the game.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TIMER = $000F

titleManager: ;spawn one actor every 56 frames
	ld hl, TIMER
	add hl, bc
	ld a, [hl]
	inc a
	cp $56 ;wait for timer
	ld [hl], a
		ret nz
	
	xor a
	ld [hl], a ;reset timer
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;variable = next actor to spawn
	inc [hl]
	cp ((titleManager.end - titleManager.actorTable) >> 2) ;end of table
	jr z, titleManager.done
	add a
	add a
	ld de, titleManager.actorTable
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = actorTable[i]
	call spawnActor
	.notDone:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.done:
	ld e, c
	ld d, b
	jp removeActor

.actorTable:
	NEWACTOR loadTitleTiles, $FF
	NEWACTOR setColors, $82
	NEWACTOR setColorsOBJ, $80
	NEWACTOR titleSpriteLoader, $FF
	NEWACTOR titleSineWave, $FF
	NEWACTOR titleEnd, $FF
	.end
