SECTION "ENTRY", ROM0[$0150]
entry: ;jumps from cart header, initializes rom+ram and runs init
	cp $11
	jr nz, @ ;do not play the game on dmg
	ld a, $01
	ld [$2000], a
	ldh [$FF70], a ;init rom and ram banks
	jp init

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "MISC STUFF", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;random functions that dont fit in anywhere else
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

waitForVBlank: ;when called, other interrupts will simply get caught in the loop. only the vblank interrupt contains an extra pop, causing it to return to whoever called this function.
	halt
	jr waitForVBlank

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
bcopy: ;bc = number of bytes to copy, de = source, hl = dest
;copies a large chunk of data at once by unrolling the loop

	push de
	push hl
	xor a
	or c
	jr z, bcopy.skip ;skip the 1st loop if copying a multiple of 256 bytes
		rst $10 ;copy the first C bytes. now the remaining data can be copied in blocks
	.skip:
	
	xor a
	or b
	jr z, bcopy.done ;skip 2nd loop if there are no more bytes to copy
	
	.Bloop:
		ld c, $10
		.Cloop:
			REPT 16 ;copy 16 blocks of 16 bytes B times
				ld a, [de]
				inc de
				ldi [hl], a
			ENDR
			dec c
		jr nz, bcopy.Cloop
		dec b
	jr nz, bcopy.Bloop
	.done:
	pop hl
	pop de
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

MAIN: ;main driver code!
;the "actor heap" contains a linked list of "actors".
;each actor contains a pointer to its own function, an 8 bit variable, a pointer to the next actor, and 26 bytes of free memory to do whatever with.
;the main loop uses a global pointer to the head of the linked list to find and loop through each actor, running its function.
;at the end, it sets a flag marking the loop as done, advances the rng state, and goes to sleep.
;when the frame ends, the vblank interrupt will wake up and clear the flag.
;this way, if a different interrupt wakes MAIN up, the flag is still set and it immediately sleeps again.

;when an actor is run, register bc always points to itself.
;the actor can discard this value if it wants, but at the cost of not being able to locate its local variables anymore.
;hl is often used to access the rest of local memory. ld hl, N \ add hl, bc \ ld a, [hl] can be used to access the Nth byte.

	ldh a, [first_actor]
	ld c, a
	ldh a, [first_actor + 1]
	ld b, a ;get pointer to head of linked list
	
	.doNextActor:
		push bc ;bc = ptr to actor main
		ld e, c
		ld d, b
		ld a, [de]
		inc de
		ld l, a
		ld a, [de]
		inc de
		ld h, a ;put function into hl
		ld a, [de]
		ldh [rom_bank], a ;swap in actor bank
		ld [$2000], a
		rst $00 ;call the actor's function
		
		pop bc ;get pointer to the actor back in case it discarded it
		ld hl, ACTORSIZE - 2
		add hl, bc
		ldi a, [hl]
		ld c, a
		ldi a, [hl]
		ld b, a ;bc = pointer to next actor
		or c
	jr nz, MAIN.doNextActor ;the list ends when the pointer is zero
	
	ld a, $FF
	ldh [actors_done], a ;mark the loop as done
	call roll_rng
	call waitForVBlank
	jr MAIN

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
readJoystick: ;reads the current buttons being pressed and writes to hram for actors to read
;calculates which buttons are held from last frame as well as press + release edges

	ld a, $10 ;for some reason 0 means active? so this selects buttons rather than directions
	ldh [$FF00], a
	REPT 6
		ldh a, [$FF00] ;grab lo 4 bits of input (Str-Sel-B-A)
	ENDR
	and $0F
	ld c, a
	
	ld a, $20
	ldh [$FF00], a
	REPT 2
		ldh a, [$FF00] ;grab hi 4 bits of input (Dwn-Up-Lft-Rgt)
	ENDR
	and $0F
	swap a
	or c
	cpl ;also, buttons pressed are read as 0, so invert the logic to make 0 = unpressed, 1 = pressed
	ld c, a

	ldh a, [raw_input]
	ld b, a ;bc = last frame's input/this frame's input
	and c
	ldh [hold_input], a ;hold = b & c
	ld a, b
	cpl
	and c
	ldh [press_input], a ;press = c & !b
	ld a, c
	cpl
	and b
	ldh [release_input], a ;release = b & !c
	ld a, c
	ldh [raw_input], a ;raw = c
	ld a, $30
	ldh [$FF00], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

bcopyBanked: ;b = bank, c = size >> 4 (number of tiles), de = src, hl = dest
;copies c tiles from de to hl, using rom bank b.

	ldh a, [rom_bank]
	push af
	ld a, b
	ldh [rom_bank], a
	ld [$2000], a ;swap in bank "b"
	
	xor a
	sla c
	rla
	sla c
	rla
	sla c
	rla
	sla c
	rla
	ld b, a ;restore bc = size (c << 4 = size >> 4 << 4 = size)
	call bcopy ;do the copy
	
	pop af
	ldh [rom_bank], a
	ld [$2000], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

changeScene: ;a = scene ID to change to
;changes global scene variable and spawns appropriate actor
	
	ldh [scene], a
	
	add a
	add a
	ld de, manager_list
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	jp spawnActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

manager_list:
	NEWACTOR logoManager, $00
	NEWACTOR titleManager, $00
	NEWACTOR menuManager, $00
	NEWACTOR characterManager, $00
	NEWACTOR settingsManager, $00