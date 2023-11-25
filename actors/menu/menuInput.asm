SECTION "MENU INPUT READER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads user input every frame.
;when up or down is pressed, spawn off several child actors to do the graphics routines for the scrolling.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTSONG = $0003
QUEUEADJUSTPRE = $001C
TIMER = $001C
QUEUEADJUSTPOST = $001D

menuInput:
.init:
	swapInRam save_file
	updateActorMain menuInput.main
	ld hl, CURRENTSONG
	add hl, bc
	ld a, [last_played_song] ;get the song the user just played
	ldi [hl], a
	
	ld de, menuInput.low_priority_actors
	ld c, menuInput.end - menuInput.low_priority_actors
	rst $10 ;copy child actors into our local ram. we will write the intended variable for them later.
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	;swapInRam game_mode
	;ld a, [game_mode]
	;ld e, a
	;restoreBank "ram"
	;ld a, e
	;cp MENU
	;ret nz
	
	ldh a, [press_input]
	bit 6, a
	jr z, menuInput.checkDown
	;user pressed up, so we scroll towards lower-numbered regions
		xor a
		ld hl, QUEUEADJUSTPRE
		add hl, bc
		ldi [hl], a ;use the step array as-is
		dec a
		ld [hl], a ;then decrement each step
		
		ld hl, CURRENTSONG
		add hl, bc
		dec [hl] ;we now have the previous song selected
		ld a, [hl]
		dec a ;child actors need to load graphics offscreen for the song before that one
		and $3F
		jr menuInput.copyVariables
		
	.checkDown:
	bit 7, a
	ret z
	;user pressed down, so we scroll towards higher-numbered regions
		xor a
		ld hl, QUEUEADJUSTPOST
		add hl, bc
		ldd [hl], a ;step array is fine after we are done with it
		inc a
		ld [hl], a ;but needs to be incremented before use
		
		ld hl, CURRENTSONG
		add hl, bc
		inc [hl] ;we now have the next song selected
		ld a, [hl]
		add $08 ;child actors need to load graphics offscreen 8 songs down
		and $3F
		or $80 ;also flag it as downward movement
		
	.copyVariables:
	ld e, a ;e = desired variable for each child actor
	ld d, ((menuInput.end - menuInput.low_priority_actors) >> 2) ;d = loop variable
	
	.varLoop: ;conveniently, hl is pointing to the byte before the first actor. so after adding sizeof(actor) each loop we will point to each actor's variable.
		ld a, l
		add $04
		ld l, a
		ld a, h
		adc $00
		ld h, a
		ld [hl], e ;write new variable to each actor
		dec d
	jr nz, menuInput.varLoop
	
	ld a, c
	add (menuInput.high_priority_actors - menuInput.low_priority_actors) + 4 ;add distance from start of actor to the high priority actor list
	ld e, a
	ld a, b
	adc $00
	ld d, a ;de = ptr to first actor
	ld a, ((menuInput.end - menuInput.high_priority_actors) >> 2) ;a = number of actors to spawn
	.spawnLoopHi:
		ldh [scratch_byte], a
		call spawnActor ;de will automatically increment inside the call
		ldh a, [scratch_byte]
		dec a
	jr nz, menuInput.spawnLoopHi
	updateActorMain menuInput.doLowPrio
	
	swapInRam menu_bkg_index
	ld hl, QUEUEADJUSTPRE
	add hl, bc
	ld d, [hl] ;d = amount to adjust steps by
	ld e, $06 ;e = loop counter
	ld [hl], $04 ;this byte pulls double duty as the timer later, load it with 14 frames
	ld bc, menu_bkg_index
	ld hl, menuInput.moduli
	
	.preProcess: ;for each chunk
		ld a, [bc]
		add [hl]
		add d ;apply preprocess offset
		.mod:
			sub [hl] ;make sure it stays in the appropriate range
		jr nc, menuInput.mod
		add [hl]
		ld [bc], a ;save it back
		inc bc
		inc hl
		dec e
	jr nz, menuInput.preProcess
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.doLowPrio:
	ld hl, TIMER
	add hl, bc
	dec [hl]
	ret nz
	ld [hl], $0A
	
	ld a, c
	add $04 ;add distance from start of actor to the low priority actor list
	ld e, a
	ld a, b
	adc $00
	ld d, a ;de = ptr to first actor
	
	ld a, ((menuInput.high_priority_actors - menuInput.low_priority_actors) >> 2) ;a = number of actors to spawn
	.spawnLoopLo:
		ldh [scratch_byte], a
		call spawnActor ;de will automatically increment inside the call
		ldh a, [scratch_byte]
		dec a
	jr nz, menuInput.spawnLoopLo
	
	updateActorMain menuInput.wait
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.wait:
	ld hl, TIMER
	add hl, bc
	dec [hl] ;wait for timer to expire
	ret nz
	
	swapInRam menu_bkg_index
	inc hl
	ld d, [hl] ;get postprocess offset
	ld e, $06 ;loop counter
	
	updateActorMain menuInput.main
	ld bc, menu_bkg_index
	ld hl, menuInput.moduli ;set up pointers for post processing
	jp menuInput.preProcess ;the actual algorithm is exactly the same as preprocessing, so jump back to that function to reuse it

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.moduli:
	db $0A, $0A, $09, $07, $05, $03

.low_priority_actors:
	NEWACTOR fetchTiles, $FF
	NEWACTOR fetchAttributes, $FF
	NEWACTOR menuMap, $FF
.high_priority_actors:
	NEWACTOR menuScroller, $FF
	NEWACTOR menuLoadText, $FF
	.end