SECTION "GRAPHICS TASK ROUTINES", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;some routines to work with "graphics tasks"
;gfx tasks are generic interfaces to the vblank handler to copy more data.
;they can work with tiles, maps, and attributes because they store a raw pointer.
;format: src | ram bank, rom bank, dest | vram bank, size - 1
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

loadGraphicsTask: ;bc = actor to load task into, de = ptr to task data
;loads a graphics task in rom to the actor's local memory so it can be modified.

	ld hl, $0004
	add hl, bc ;hl = actor.gfx_task
	REPT 6
		ld a, [de]
		inc de
		ldi [hl], a ;copy it
	ENDR
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

submitGraphicsTask: ;bc = submitting actor
;reads a "graphics task" from an actor's local memory and tries to add it to the global queue.
;the vblank handler can only handle 60 tiles worth of data per frame though, so some requests get rejected.
;to signify acceptance, the 10th byte of the actor is incremented.

	ld hl, $0004
	add hl, bc ;hl = actor.gfx task
	ldh a, [next_task]
	ld e, a
	ldh a, [next_task + 1]
	ld d, a ;de = next_task
	
	di ;graphics-related buffers are timing-sensitive
	REPT 6
		ldi a, [hl]
		ld [de], a
		inc de
	ENDR ;copy task into the queue, at the end of the loop de points to the next free slot
	
	inc a
	ld l, a
	ldh a, [num_tiles]
	add l ;a = total # of tiles requested this frame
	cp $61
		jr nc, submitGraphicsTask.tooMany ;vblank routine can only copy $60 tiles per frame
		
	ldh [num_tiles], a
	ld a, e
	ldh [next_task], a
	ld a, d
	ldh [next_task + 1], a ;confirm the task's entry by updating next_task pointer (on failure, the vblank handler won't loop enough times to read it)
	
	ld hl, vblank_jump + 1
	ld a, [hl]
	sub $18
	ldi [hl], a
	ld a, [hl]
	sbc $00
	ldi [hl], a ;vblank task handler is $18 bytes long, so we cause it to loop an extra time by decrementing it by that amt
	
	ld hl, $000A
	add hl, bc
	inc [hl] ;indicate success to the actor
	.tooMany:
	reti
	
GFXTASK: MACRO
	dw ((BANK(\1) & $07) | (\1)) ;source address + ram bank (lower bits are a don't care for rom copies)
	db BANK(\1)                  ;source's rom bank (don't care for ram copies)
IF _NARG > 2
	dw (\2 + \3) | BANK(\2)      ;destination region + address in vram with optional offset
ELSE
	dw (\2) | BANK (\2)
ENDC
IF _NARG > 3
	dw (\4) - 1
ELSE
	db ((\1.end - \1) >> 4) - 1  ;calculate size based on ".end" tag
ENDC
	db $FF                       ;padding
	db $FF                       ;padding
ENDM
