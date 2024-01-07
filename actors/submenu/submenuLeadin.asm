SECTION "SUBMENU LEADIN", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTDIGIT = $0004
DIGITS = $0005

PUSHC
SETCHARMAP settingsChars

submenuLeadin:
.init:
	ld de, submenuLeadin.task
	call loadGraphicsTask
	
	swapInRam save_file
	
	ld hl, leadin_tile
	ldi a, [hl]
	ld h, [hl]
	ld l, a
	
	call submenuLeadin.itoa14
	ld hl, CURRENTDIGIT
	add hl, bc
	xor a
	ldi [hl], a
	
	ld a, e
	and $0F
	ldi [hl], a
	ld a, e
	swap a
	and $0F
	ldi [hl], a
	ld a, d
	and $0F
	ldi [hl], a
	ld a, d
	swap a
	and $0F
	ldi [hl], a
	
	swapInRam shadow_wmap
	ld hl, shadow_wmap + 32*14 + 1
	ld de, submenuLeadin.confirm_msg
	rst $20
	ld hl, shadow_wmap + 32*16 + 1
	ld de, submenuLeadin.cancel_msg
	rst $20
	
	ld hl, shadow_wmap + 32*15 + 17
	ld a, "m"
	ldi [hl], a
	ld [hl], "s"
	
	call submenuLeadIn.renderDigits
	restoreBank "ram"
	restoreBank "ram"	
	updateActorMain submenuLeadIn.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ldh a, [press_input]
	bit 7, a
	jr z, submenuLeadin.checkUp
		jp submenuLeadin.down
	.checkUp:
	bit 6, a
	jr z, submenuLeadin.checkLeft
		jp submenuLeadin.up
	.checkLeft:
	bit 5, a
	jr z, submenuLeadin.checkRight
		jp submenuLeadin.left
	.checkRight:
	bit 4, a
	jr z, submenuLeadin.checkStart
		jp submenuLeadin.right
	.checkStart:
	bit 3, a
	jr z, submenuLeadin.checkB
		jp submenuLeadin.start
	.checkB:
	bit 1, a
	jr z, submenuLeadin.checkA
		jp submenuLeadin.B
	.checkA:
	bit 0, a
	ret z
		jp submenuLeadin.A
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.up:
	ld hl, CURRENTDIGIT
	add hl, bc
	ldi a, [hl]
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ld a, [hl]
	inc a
	cp $0A
	ld [hl], a
	jr nz, submenuLeadin.wrapUp
		ld [hl], $00
	.wrapUp:
	jp submenuLeadin.renderDigits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.down:
	ld hl, CURRENTDIGIT
	add hl, bc
	ldi a, [hl]
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ld a, [hl]
	sub $01
	ld [hl], a
	jr c, submenuLeadin.wrapUp
		ld [hl], $09
	.wrapUp:
	jp submenuLeadin.renderDigits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.left:
	ld hl, CURRENTDIGIT
	add hl, bc
	ld a, [hl]
	inc a
	and $03
	ld [hl], a
	jp submenuLeadin.renderDigits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.right:
	ld hl, CURRENTDIGIT
	add hl, bc
	ld a, [hl]
	dec a
	and $03
	ld [hl], a
	jp submenuLeadin.renderDigits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.A:
.start:
	ld hl, DIGITS
	add hl, bc
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	swap a
	or e
	ld e, a
	ldi a, [hl]
	ld d, [hl]
	swap d
	or d
	ld d, a
	
	call submenuLeadin.atoi14
	swapInRam save_file
	ld hl, leanin_tile
	ld a, e
	ldi [hl], a
	ld [hl], d
	restoreBank "ram"

.B:
	swapInRam shadow_wmap
	ld hl, shadow_wmap + 32*14 + 1
	ld de, submenuLeadin.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*15 + 1
	ld de, submenuLeadin.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*16 + 1
	ld de, submenuLeadin.blank_msg
	rst $20
	restoreBank "ram"
	
	updateActorMain submenuLeadin.exit
	jp submenuLeadin.exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderDigits:
	swapInRam shadow_wmap
	ld hl, DIGITS
	add hl, bc
	ld de, shadow_wmap + 32*15 + 12
	
	ldi a, [hl]
	add "0"
	ld [de], a
	inc [de]
	ldi a, [hl]
	add "0"
	ld [de], a
	inc [de]
	ldi a, [hl]
	add "0"
	ld [de], a
	inc [de]
	ldi a, [hl]
	add "0"
	ld [de], a
	
	ld hl, CURRENTDIGIT
	add hl, bc
	ld d, [hl]
	
	ld a, " "	
	ld hl, shadow_wmap + 32*16+12
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld hl, shadow_wmap + 32*14+12
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld [hl], a
	
	ld a, d
	sbc l
	ld l, a
	ld a, h
	sbc $00
	ld h, a
	
	ld [hl], "v"
	ld de, $0040
	add hl, de
	ld [hl], "x"
	
	restoreBank "ram"
	
	call submitGraphicsTask
	ld hl, TASKSDONE
	add hl, bc
	ld a, [hl]
	ld [hl], $00
	dec a
	ret z
	
	updateActorMain submenuLeadIn.submit
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.itoa14:
	add hl, hl
	add hl, hl ;2
	
	add hl, hl
	rla
	add hl, hl
	rla
	add hl, hl ;5
	rla
	
	ld d, $04
	.phase2:
		add hl, hl ;9
		adc a
		daa
		dec d
	jr nz, submenuLeadin.phase2
	
	rl d
	ld e, a
	
	ld l, $07
	.phase3:
		add hl, hl ;16
		ld a, e
		adc a
		daa
		ld e, a
		ld a, d
		adc a
		daa
		ld d, a
		dec l
	jr nz, submenuLeadin.phase3
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.atoi14:
	ld hl, $000E
	xor a
	.dec2binLoop:
		sra d
		rr e
		jr nc, submenuLeadin.shifted0
			rra
			rr h
			add $50
			jr submenuLeadin.reconvene
		.shifted0:
		rra
		rr h
		.reconvene:
		dec l
	jr nz, submenuLeadin.dec2binLoop
	rra
	rr h
	rra
	ld d, a
	rr h
	ld e, h
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

.submit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	ld [hl], $00
	dec a
	ret nz
	
	updateActorMain submenu.Leadin.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.exit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	ld [hl], $00
	dec a
	ret nz
	
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.task:
	GFXTASK shadow_wmap, $01C0, win_map, $01C0, $06
	
.confirm_msg:
	db "azconfirm\n"
.cancel_msg:
	db "bzcancel\n"
.blank_msg:
	db "                  \n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
POPC