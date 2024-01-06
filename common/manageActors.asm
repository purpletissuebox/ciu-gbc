SECTION "MANAGE ACTORS", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;various functions for creating actors, destorying actors, and changing actor variables.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawnActor: ;de = ptr to new actor struct
;"spawning" an actor simply means appending it to the actor heap linked list.
;the next available slot is already recorded in a global pointer, so the place it spawns in is pre-calculated.
;we will still need to recalculate it though, since a following call to spawnActor will need it.

	push bc
	;step 1 - find end of linked list
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a ;bc = start of linked list
	
	.searchLoop:
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		or [hl] ;traverse linked list until current_actor.next is null
			jr z, spawnActor.foundEnd
			
		ldd a, [hl]
		ld b, a
		ld c, [hl]
	jr spawnActor.searchLoop
	
	;step 2 - append our actor
	.foundEnd:
		ldh a, [next_actor+1]
		ldd [hl], a
		ld b, a
		ldh a, [next_actor]
		ld [hl], a
		ld l, a
		ld h, b ;current_actor.next AND hl = future home of our new actor
		
		ld c, $04
		rst $10 ;copy our actor into the spot
		xor a
		ld c, ACTORSIZE - 4
		rst $08 ;and zero out its memory

	ld bc, ACTORSIZE - 1
	ld hl, ACTORHEAP + 1
	
	
	;step 3 - update the global pointer to the next free slot
	.findEmpty:
		add hl, bc
		ldi a, [hl]
		or [hl]
	jr nz, spawnActor.findEmpty ;search through memory sequentially (NOT like a linked list) to find an unused slot
	
	dec hl
	ld a, l
	ldh [next_actor], a
	ld a, h
	ldh [next_actor+1], a ;write to global variable
	
	pop bc
	ret ;"returns" de = ptr to byte following actor struct

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

removeActor: ;de = actor that will be killed
;killing an actor is as simple as finding the previous actor and making it point to the actor after ours.

	push bc
	
	;step 1 - find which actor points to ours
	ldh a, [first_actor]
	ld l, a
	ldh a, [first_actor + 1]
	ld h, a
	ld bc, ACTORSIZE - 2 ;hl = ptr to first actor
	
	.search:
		add hl, bc
		ldi a, [hl]
		sub e
	jr nz, removeActor.wrongActor
		ld a, [hl]
		sub d ;traverse linked list until current_actor.next == our actor
			jr z, removeActor.targetFound	
	.wrongActor:
		ldd a, [hl]
		ld l, [hl]
		ld h, a
	jr removeActor.search
	
	;step 2 - make previous actor "skip over" ours, removing us from the chain
	.targetFound:
	ld c, l
	ld b, h ;bc = prev.next
	ld hl, ACTORSIZE - 1
	add hl, de ;hl = us.next
	
	ldd a, [hl]
	ld [bc], a
	dec bc
	ld a, [hl]
	ld [bc], a ;copy our next actor into the previous actor's
	
	xor a
	ld [de], a
	inc de
	ld [de], a ;mark our actor as empty
	
	pop bc
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

spawnActorV: ;de = ptr to actor struct, a = variable
;alternative to spawnActor. this version has a variable passed in via a register instead of in memory.
;this makes it easier to change the variable, but more difficult to get pointers to the actor after it spawns.
;as a result, de will no longer point to the next actor on return. see spawnActor for more details.
	push bc
	ld b, a ;store variable in b to access HRAM later
	ld c, $03
	
	ldh a, [next_actor]
	ld l, a
	ldh a, [next_actor+1]
	ld h, a
	rst $10 ;copy actor's function into the next free slot
	ld a, b
	ldd [hl], a ;save variable at the end
	dec hl
	dec hl
	ld e, l
	ld d, h ;save ptr to actor for later
	
	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor+1]
	ld b, a ;bc points to current actor
	
	.loop:
		ld hl, ACTORSIZE -2
		add hl, bc
		ldi a, [hl]
		or [hl] ;check current_actor.next
		jr z, spawnActorV.foundEnd ;if zero, we need to append our actor
		
		ldd a, [hl]
		ld b, a
		ld c, [hl] ;else update current_actor = current_actor.next and keep looking
	jr spawnActorV.loop
	
	.foundEnd:
		ld a, d
		ldd [hl], a
		ld [hl], e ;append
		
		ld hl, $0004
		add hl, de
		xor a
		ld c, ACTORSIZE - 4
		rst $08 ;zero out remaining memory

	ld bc, ACTORSIZE - 1
	ld hl, ACTORHEAP + 1
	
	.findEmpty:
		add hl, bc ;hl points to the ith actor
		ldi a, [hl]
		or [hl] ;check if empty
	jr nz, spawnActorV.findEmpty
	
	dec hl ;if empty, this is our next free slot to use
	ld a, l
	ldh [next_actor], a
	ld a, h
	ldh [next_actor+1], a ;mark it as such and return
	
	pop bc
	ret