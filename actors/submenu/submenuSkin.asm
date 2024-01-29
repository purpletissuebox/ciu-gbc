SECTION "SUBMENU SKIN", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TASKSRC = $0004
OPTION = $0010
CURSOR = $0011
BACKGROUND = $0012
SCANLINEBUF = $0013
NUMOPTIONS = $08
NUMVISIBLE = $03

PUSHC
SETCHARMAP settingsChars

submenuSkin:
.init:
	swapInRam save_file
	ld a, [note_skin]
	ld hl, OPTION
	add hl, bc
	ldi [hl], a
	
	cp NUMOPTIONS - NUMVISIBLE ;if the option is near the end of the list, we cant render it as the topmost one.
	jr c, submenuSkin.topOption ;if the option is near the top, then we can.
		sub NUMOPTIONS - NUMVISIBLE ;calculate where the cursor will appear since it won't be the top
		ldi [hl], a 
		ld [hl], NUMOPTIONS - NUMVISIBLE ;put background at the lowest place possible
		jr submenuSkin.continue		
	.topOption:	
	ld [hl], $00 ;cursor is at the top
	inc hl
	ld [hl], a ;background is where the option said it would be
	
	.continue:
	restoreBank "ram"
	
	swapInRam shadow_wmap
	ld a, "f"
	ld hl, shadow_wmap + 32*14 + 1
	ld de, $001D
	REPT 3
		ldi [hl], a
		ldi [hl], a
		ldi [hl], a
		add hl, de
	ENDR
	restoreBank "ram"
	
	call submenuSkin.initOAM	
	jp submenuSkin.renderEverything
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ldh a, [press_input]
	bit 7, a
	jr z, submenuSkin.checkUp
		jp submenuSkin.down
	.checkUp:
	bit 6, a
	jr z, submenuSkin.checkLeft
		jp submenuSkin.up
	.checkLeft:
	bit 5, a
	jr z, submenuSkin.checkRight
		jp submenuSkin.left
	.checkRight:
	bit 4, a
	jr z, submenuSkin.checkStart
		jp submenuSkin.right
	.checkStart:
	bit 3, a
	jr z, submenuSkin.checkB
		jp submenuSkin.start
	.checkB:
	bit 1, a
	jr z, submenuSkin.checkA
		jp submenuSkin.B
	.checkA:
	bit 0, a
	ret z
		jp submenuSkin.A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.up:
.left:
	ld hl, OPTION
	add hl, bc
	ld a, [hl]
	sub $01
		ret c
	
	ldi [hl], a
	ld a, [hl]
	sub $01
		jr c, submenuSkin.fixBkgUp
	ldi [hl], a
	jp submenuSkin.renderEverything
	
	.fixBkgUp:
	inc hl
	dec [hl]
	jp submenuSkin.renderEverything

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.down:
.right:
	ld hl, OPTION
	add hl, bc
	ld a, [hl]
	inc a
	cp NUMOPTIONS
		ret z
	
	ldi [hl], a
	ld a, [hl]
	inc a
	cp NUMVISIBLE
		jr z, submenuSkin.fixBkgDown
	ldi [hl], a
	jp submenuSkin.renderEverything
	
	.fixBkgDown:
	inc hl
	inc [hl]
	jp submenuSkin.renderEverything

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.A:
.start:
	swapInRam save_file
	ld hl, OPTION
	add hl, bc
	ld a, [hl]
	ld [note_skin], a
	restoreBank "ram"
	
.B:
	swapInRam shadow_wmap
	ld hl, shadow_wmap + 32*14 + 1
	ld de, submenuSkin.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*15 + 1
	ld de, submenuSkin.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*16 + 1
	ld de, submenuSkin.blank_msg
	rst $20 ;blank out the window layer where the submenu appears
	restoreBank "ram"
	
	call submenuSkin.restoreOAM
	updateActorMain submenuSkin.exit
	jp submenuSkin.exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderCursor:
	swapInRam shadow_wmap
	
	ld hl, shadow_wmap + 32*14 + 4
	ld d, $00
	ld a, NUMVISIBLE
	.blankLoop:
		ld [hl], " "
		ld e, $0E
		add hl, de
		ld [hl], " "
		ld e, $12
		add hl, de
		dec a
	jr nz, submenuSkin.blankLoop
	
	ld hl, CURSOR
	add hl, bc
	ld a, [hl]
	swap a
	add a
	ld hl, shadow_wmap + 32*14 + 4
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	
	ld [hl], "["
	ld e, $0E
	add hl, de
	ld [hl], "]"
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderBkg:
	push bc
	swapInRam shadow_wmap
	
	ld hl, BACKGROUND
	add hl, bc
	ld b, [hl]
	ld c, $00
	
	.bkgLoop:
		ld hl, submenuSkin.skin_names
		ld a, b
		add a
		add l
		ld l, a
		ld a, h
		ld a, h
		adc $00
		ld h, a
		
		ldi a, [hl]
		ld d, [hl]
		ld e, a
		
		ld hl, shadow_wmap + 32*14 + 5
		ld a, c
		swap a
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a
		
		rst $20
		inc b
		inc c
		ld a, c
		cp NUMVISIBLE
	jr nz, submenuSkin.bkgLoop
	
	restoreBank "ram"
	pop bc
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderArrow:
	ld hl, OPTION
	add hl, bc
	ld a, [hl]
	ld d, $00
	swap a
	add a
	rl d
	add a
	rl d
	
	ld hl, TASKSRC
	add hl, bc
	add LOW(submenuSkin.previewGfx)
	ldi [hl], a
	ld a, d
	adc HIGH(submenuSkin.previewGfx)
	ldi [hl], a
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderEverything:
	call submenuSkin.renderCursor
	call submenuSkin.renderBkg
	
	ld de, submenuSkin.bkg_task
	call loadGraphicsTask
	call submitGraphicsTask
	
	ld de, submenuSkin.tile_task
	call loadGraphicsTask
	call submenuSkin.renderArrow
	call submitGraphicsTask
	
	ld hl, NUMTASKS
	add hl, bc
	ld e, [hl]
	ld [hl], $00
	
	updateActorMain submenuSkin.main
	ld a, e
	cp $02
	jr z, submenuSkin.success
		updateActorMain submenuSkin.renderEverything
	.success:
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.exit:
	ld de, submenuSkin.bkg_task
	call loadGraphicsTask
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
	ret nz
	
	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.initOAM:
	swapInRam on_deck
	push bc
	
	ld a, [active_oam_buffer]
	ld d, a
	ld h, a
	ld e, $00
	ld l, $98
	
	ld c, $08
	rst $10
	
	ld l, c
	ld de, submenuSkin.sprite_entries
	ld c, $08
	rst $10
	
	ldh a, [$FF45]
	ld hl, SCANLINEBUF
	add hl, bc
	ld [hl], a
	ld a, $70
	ldh [$FF45], a
	
	pop bc
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.restoreOAM:
	swapInRam on_deck
	push bc
	
	ld a, [active_oam_buffer]
	ld d, a
	ld h, a
	ld e, $98
	ld l, $00
	
	ld c, $08
	rst $10
	
	ld l, $98
	xor a
	ld c, $08
	rst $08
	
	ld hl, SCANLINEBUF
	add hl, bc
	ld a, [hl]
	ldh [$FF45], a
	
	pop bc
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.bkg_task:
	GFXTASK shadow_wmap, $01C0, win_map, $01C0, $06
.tile_task:
	GFXTASK submenuSkin.previewGfx, $0000, sprite_tiles1, $07C0, $04

.sprite_entries:
	db $84, $14, $7C, $0A
	db $84, $1C, $7E, $0A
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STRINGID = 0
.skin_names: ;pointer table to all the strings below.
REPT NUMOPTIONS
	dw submenuSkin.string_{02u:STRINGID}
STRINGID = STRINGID + 1
ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.blank_msg: db "                  \n"

.string_00: db "standard     \n"
.string_01: db "wide         \n"
.string_02: db "tapered      \n"
.string_03: db "outlined     \n"
.string_04: db "ddr          \n"
.string_05: db "simple       \n"
.string_06: db "hollow       \n"
.string_07: db "soccer ball  \n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

align 4
.previewGfx:
	INCBIN "../assets/gfx/sprites/notePreview.bin"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPC