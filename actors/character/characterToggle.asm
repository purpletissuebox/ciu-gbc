SECTION "CHARACTER TOGGLE", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;moves character portraits towards and away from the center of the screen based on player input.
;reads joypad every frame, then spawns two actors to actually do the work of scrolling.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
CHOICE = $000A
SCROLLER = $000B
EXTRAVARIABLE = $000F

charToggle:
.wait: ;we need to wait until the initial scroll is done, which needs to wait for screen fade to complete, which the manager will trigger.
	swapInRam character
	ld a, [character] ;scroll actor will write to here when done
	and a
		jr z, charToggle.keepWaiting
	
	updateActorMain charToggle.setUpScroller
	ld de, charToggle.initLeft ;spawn an actor to select the left character
	call spawnActor
	
	.keepWaiting:
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.setUpScroller: ;copies the scroller actor into local memory, leaving the variable blank to fill in later.
	ld hl, SCROLLER
	add hl, bc
	ld de, charToggle.initLeft
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	updateActorMain charToggle.pollInput
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.pollInput:
	ldh a, [press_input]
	ld e, a
	and $01
		jr nz, charToggle.submit ;write choice to global memory if the user pressed A
	ld a, e
	and $30
	ret z ;check for L/R
	
	swap a ;XXLR XXXX -> XXXX XXLR
	rra ;shift bit for R into carry
	ld a, $01
	jr c, charToggle.right
		ld a, $00 ;a = 1 if R was pressed, else 0
	.right:
	
	ld hl, CHOICE
	add hl, bc
	cp [hl]
		ret z ;if we already have that side selected, do nothing
	
	ldi [hl], a ;else save new choice to local memory
	ld e, l
	ld d, h ;de now points to the scroller actor
	inc hl
	inc hl
	inc hl ;and hl points to its variable
	
	;construct variable for scroller (see below section). the timer will start at zero, so bits 0-4 are already done.
	swap a
	add a ;put character choice in bit 5. bit 6 is zero.
	ldi [hl], a
	xor $60 ;toggle direction and character for the second scroller
	ld [hl], a
	push de
	call spawnActor ;spawn scroller for selected character to go up
	
	pop de
	ld hl, EXTRAVARIABLE
	add hl, bc
	ldd a, [hl]
	ld [hl], a
	call spawnActor ;spawn scroller for deselected character to go down
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	swapInRam character
	ld hl, CHOICE
	add hl, bc
	ld a, [hl]
	inc a ;???
	ld [character], a ;save choice to global memory
	restoreBank "ram"
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.initLeft:
	NEWACTOR doCharScroll, $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "CHARACTER TOGGLE SCROLL", ROMX
doCharScroll: ;variable = -dct tttt: d = direction(0u1d), c = character(0s1r), t = time
	ld hl, VARIABLE
	add hl, bc
	inc [hl] ;increment timer. eventually this will overflow into character bit, but that will also cause the actor to despawn so it doesn't matter.
	ld a, [hl]
	ld e, a ;store variable in e for later
	and $1F
		jr z, doCharScroll.done ;exit when timer is done
	
	swapInRam shadow_scroll
	ld a, e ;get variable back
	ld d, $00
	sla e ;scroll entries are 2 bytes each, de = offset from start of table
	ld hl, doCharScroll.scrollTable
	add hl, de ;the lookup table is laid out in the same order as the variable (sorted by time, then character, then direction), so hl points to the current scroll entry.
	
	ld de, shadow_scroll ;decide whether or not to use bkg or window scroll based on character bit
	swap a
	and $02
	add e ;conveniently, selecting the character bit also gives the distance between bkg and window, so add it directly to the pointer
	ld e, a
	ldi a, [hl]
	ld [de], a
	inc de
	ld a, [hl]
	ld [de], a ;read from scroll entry and write to scroll registers.
	restoreBank "ram"
	ret
	
	.done:
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.scrollTable:
	INCBIN "../assets/code/toggleScroll.bin"
