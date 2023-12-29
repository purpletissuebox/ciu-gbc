SECTION "MENU INPUT READER", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads user input every frame.
;when up or down is pressed, spawn off several child actors to do the graphics routines for the scrolling.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTSONG = $0003
CURRENTDIFF = $0004
TIMER = $000F

menuInput:
.init:
	swapInRam save_file
	updateActorMain menuInput.main
	ld hl, CURRENTSONG
	add hl, bc
	ld a, [last_played_song] ;get the song the user just played
	ldi [hl], a
	ld a, [last_played_difficulty]
	ld [hl], a
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	ldh a, [scene]
	cp MENU
	ret nz
	
	ldh a, [press_input]
	bit 6, a
	jr z, menuInput.checkDown
		jp menuInput.up
		
	.checkDown:
	bit 7, a
	jr z, menuInput.checkLeft
		jp menuInput.down
	.checkLeft:
	bit 5, a
	jr z, menuInput.checkRight
		jp menuInput.left
	.checkRight:
	bit 4, a
	jr z, menuInput.checkSelect
		jp menuInput.right
	.checkSelect:
	bit 2, a
	jr z, menuInput.checkB
		jp menuInput.select
	.checkB:
	bit 1, a
	jr z, menuInput.checkA
		jp menuInput.B
	.checkA:
	bit 0, a
	ret z
		jp menuInput.A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.up:
	;scroll towards lower-numbered songs
	ld hl, CURRENTSONG
	add hl, bc
	dec [hl] ;we now have the previous song selected
	ldi a, [hl]
	and $3F
	ldh [scratch_byte], a
	
	rlca
	rlca
	or [hl]
	rrca
	rrca
	ld de, menuInput.hud_actor
	call spawnActorV
	
	ldh a, [scratch_byte]
	ld de, menuInput.bkg_actor
	call spawnActorV
	
	ldh a, [scratch_byte]
	ld de, menuInput.sprite_actor
	call spawnActorV
	
	updateActorMain menuInput.wait
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.down:
	;scroll towards higher-numbered songs
	ld hl, CURRENTSONG
	add hl, bc
	inc [hl] ;next song selected
	ldi a, [hl]
	and $3F
	or $80
	ldh [scratch_byte], a
	
	rlca
	dec a
	rlca
	or [hl]
	rrca
	rrca
	ld de, menuInput.hud_actor
	call spawnActorV
	
	ldh a, [scratch_byte]
	ld de, menuInput.bkg_actor
	call spawnActorV
	
	ldh a, [scratch_byte]
	ld de, menuInput.sprite_actor
	call spawnActorV
	
	updateActorMain menuInput.wait
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.left:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.right:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.select:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.B:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.A:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.wait:
	ld hl, TIMER
	add hl, bc
	ld [hl], $0F
	updateActorMain menuInput.wait2

.wait2:
	ld hl, TIMER
	add hl, bc
	dec [hl] ;wait for timer to expire
		ret nz
	
	updateActorMain menuInput.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.bkg_actor:
	NEWACTOR menuBkg, $FF

.sprite_actor:
	NEWACTOR menuSprites, $FF

.hud_actor:
	NEWACTOR menuHUD, $FF