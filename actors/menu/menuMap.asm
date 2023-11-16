SECTION "MENU MAP", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuMap:
.init:
	updateActorMain menuMap.main
	swapInRam menu_bkg_index
	
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	and $80
	ld de, menuMap.chunk_differences_up
	jr z, menuMap.copy
		ld de, menuMap.chunk_differences_down
		
	.copy:
		inc hl
		ld a, [de]
		inc de
			cp $FF
			jr z, menuMap.break
		ldi [hl], a
		ld a, [de]
		inc de
		ldi [hl], a
	jr menuMap.copy
	
	.break:
	ld hl, $0004
	add hl, bc
	ld a, [menu_bkg_index]
	ld e, a
	add a
	add e
	add a
	add a
	add e
	add $80
	ldi [hl], a
	
	inc hl
	inc hl
	ld c, l
	ld b, h
	
	ld de, menu_bkg_index + $0002
	ld hl, menuMap.chunk_offsets
	
	.loop:
		ld a, [de]
		inc de
		add a
		add a
		add a
		add [hl]
		inc hl
		
		ld [bc], a
		inc bc
		inc bc
		inc bc
		add $04
		ld [bc], a
		inc bc
		inc bc
		inc bc
		
		ld a, e
		sub LOW(menu_bkg_index.end)
	jr nz, menuMap.loop
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.main:
	push bc
	swapInRam shadow_map
	
	ld hl, $0003
	add hl, bc
	ldi a, [hl]
	ld c, l
	ld b, h
	
	and $80
	ld de, $9048
	jr nz, menuMap.down
		ld de, $E0F0
		
	.down:
	ld h, $00
	ldh a, [$FF42]
	add $03
	add d
	and $F8
	add a
	rl h
	add a
	rl h
	ld l, a
	
	ldh a, [$FF43]
	add $03
	add e
	and $F8
	rrca
	rrca
	rrca
	or l
	ld l, a
	
	ld de, shadow_map
	add hl, de
	
	ld a, [bc]
	inc bc
	ld e, $0D
	
	.bands:
		set 5, l
		ld [hl], a
		res 5, l
		ldi [hl], a
		inc a
		dec e
	jr nz, menuMap.bands
	
	xor a
	
	.bigLoop:
		ldh [scratch_byte], a
		ld a, [bc]
		inc bc
		ld e, a
		ld a, [bc]
		inc bc
		ld d, a
		add hl, de
		res 5, l
		res 2, h
		
		ld de, $0020
		ld a, [bc]
		inc bc
		
		REPT 4
			ld [hl], a
			inc a
			add hl, de
			res 2, h
		ENDR
		
		ldh a, [scratch_byte]
		inc a
		cp $08
	jr nz, menuMap.bigLoop
	
	restoreBank "ram"	
	pop bc
	
	ld hl, $000A
	add hl, bc
	ld [hl], $00
	ld de, menuMap.task
	call loadGraphicsTask
	updateActorMain menuMap.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.submit:
	call submitGraphicsTask
	ld hl, $000A
	add hl, bc
	ld a, [hl]
	and a
	jr z, menuMap.tryAgain
		ld e, c
		ld d, b
		call removeActor
	.tryAgain:
	ret
	
.chunk_differences_up:
	dw $0053, $030D, $0093, $028F, $0111, $0211, $018F, $0193
	db $FF
.chunk_differences_down:
	dw $0012, $030D, $0011, $028F, $008F, $0211, $010D, $0193
	db $FF
	
.chunk_offsets:
	db $20, $20, $58, $68
	
.task:
	GFXTASK shadow_map, bkg_map, $0000