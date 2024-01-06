SECTION "VBLANK HANDLER", ROM0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;graphics handler that runs once per frame.
;performs oam dma, copies scroll registers, and loads colors from buffers
;also handles "graphics tasks" by jumping to some ram code which jumps back midway through the handler a la Duff's device
;graphics tasks contain src-dest-size so can handle maps, attr, and tiles.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VBLANK:
	push af
	ldh a, [actors_done] ;check if actors are done running. if they aren't, that means we need to insert a lag frame.
	and a
	jr nz, VBLANK.noLag
		pop af ;if we are lagging, do not do any graphics processing and return to the caller.
		reti
	.noLag:
	ldh a, [rom_bank]
	push af
	ldh a, [ram_bank]
	push af
	ldh a, [vram_bank]
	push af ;context save
	
	ld hl, TASKLIST
	ld c, $55 ;dma transfer port
	ld de, $0107 ;vram and wram banks
	jp vblank_jump
	REPT 8
		ldi a, [hl] ;dma src lo/wram bank
		ldh [$FF52], a
		and e
		ldh [$FF70], a
		ldi a, [hl] ;dma src hi
		ldh [$FF51], a
		ldi a, [hl] ;src rom bank
		ld [$2000], a
		ldi a, [hl] ;dma dest lo/vram bank
		ldh [$FF54], a
		and d
		ldh [$FF4F], a
		ldi a, [hl] ;dma dest hi
		ldh [$FF53], a
		ldi a, [hl] ;transfer length
		ldh [c], a
	ENDR
	.tasks_end:
	ld hl, vblank_jump + 1
	ld a, LOW(VBLANK.tasks_end)
	ldi [hl], a
	ld a, HIGH(VBLANK.tasks_end)
	ldi [hl], a ;return vblank jump to bottom of dl stack
	
	ld a, BANK(shadow_oam)
	ldh [$FF70], a
	ld a, HIGH(shadow_oam)
	call oam_routine
	
	xor a
	ldh [num_tiles], a ;free up gfx task space now that they are all done
	ldh [actors_done], a ;allow actors to run again
	ld hl, next_task
	ld a, LOW(TASKLIST)
	ldi [hl], a
	ld a, HIGH(TASKLIST) ;init task list ptr
	ldi [hl], a
	
	ei ;done with timing critical portion, the remaining stuff can be done in hblank
	
	ld hl, shadow_scroll
	ldi a, [hl]
	ldh [$FF42], a
	ldi a, [hl]
	ldh [$FF43], a
	ldi a, [hl]
	ldh [$FF4A], a
	ldi a, [hl]
	ldh [$FF4B], a

	ld a, BANK(shadow_palettes)
	ldh [$FF70], a
	ld de, $7F02
	ld hl, shadow_palettes
	ld c, $68 ;bkg pallete io port
	.selectPalette:
		ld b, $10 ;copy 16 blocks
		ld a, $80
		ldh [c], a ;start copy
		inc c
		.wait_hblank:
			ldh a, [$FF41]
			and e
		jr nz, VBLANK.wait_hblank
			REPT 4
				ldi a, [hl] ;copy 2 colors per hblank period
				ldh [c], a
			ENDR
			dec b
		jr nz, VBLANK.wait_hblank
		
		ld a, c
		inc c
		cp $69
	jr z, VBLANK.selectPalette ;repeat for sprite palletes
	
	pop af
	ldh [$FF4F], a
	pop af
	ldh [$FF70], a
	pop af
	ld [$2000], a ;restore banks
	pop af ;pop the original value of registers af from the stack.
	pop af ;pop the address of "wait for vblank" from the stack.
	ret ;this return will go to the caller of "wait for vblank".