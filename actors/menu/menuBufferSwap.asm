SECTION "SWAP BUFFERS", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;swaps buffers
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuSwapBuffers:
.init:
	ldh a, [$FF44]
	cp $7C
		jr nc, menuSwapBuffers.begin
	
	ld hl, ACTORSIZE - 2
	add hl, bc
	ldi a, [hl]
	or [hl]
		jr z, menuSwapBuffers.init
	
	ld e, c
	ld d, b
	call spawnActor
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.begin:
	swapInRam on_deck
	ld a, [on_deck.active_buffer]
	xor $02
	ld [on_deck.active_buffer], a
	restoreBank "ram"
	
	ld hl, $0003
	add hl, bc
	ld a, [hl]
	and $80
	rrca
	rrca
	add $1A
	ldh [$FF45], a
	ld e, c
	ld d, b
	jp removeActor