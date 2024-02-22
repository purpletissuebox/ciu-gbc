SECTION "SUBMENU LIST", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;handler for a submenu that lets the user select from predefained options.
;selects parameters (number of options, ptr to strings, etc) based on variable.
;saves ID number of selection to save file when confirmed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
TASKSUCCESS = $000A

NUMOPTIONS = $0010
STRINGBASE = $0011
DEST = $0012
CURRENTOPTION = $0014
CURRENTCURSOR = $0015
CURRENTBKG = $0016

PUSHC
SETCHARMAP settingsChars

submenuList:
	ld de, submenuList.task
	call loadGraphicsTask
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;get variable
	
	add a
	add a
	ld de, submenuList.target_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = ptr to target parameters
	
	ld hl, NUMOPTIONS
	add hl, bc
	
	push bc
	ld a, [de]
	inc de
	ldi [hl], a
	ld b, a
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	inc de
	ldi [hl], a ;copy parameters to local memory
	
	swapInRam save_file
	ld a, [de]
	ldd [hl], a
	ld d, a
	ldi a, [hl]
	ld e, a ;de = variable's destination
	inc hl ;hl = ptr to current option ID
	
	ld a, [de]
	ldi [hl], a ;save option to local memory
	ld c, a
	
	ld a, b
	sub $03 ;a = largest option that is allowed to be at the top
	cp c
	jr nc, submenuList.topOption
		ld e, a
		sub c
		cpl
		inc a
		ldi [hl], a
		ld [hl], e
		jr submenuList.cont
	.topOption:
		xor a
		ldi [hl], a
		ld [hl], c
	.cont:
	
	restoreBank "ram"
	pop bc
	updateActorMain submenuList.main
	jp submenuList.draw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ldh a, [press_input]
	bit 7, a
	jr z, submenuList.checkUp
		jp submenuList.down
	.checkUp:
	bit 6, a
	jr z, submenuList.checkLeft
		jp submenuList.up
	.checkLeft:
	bit 5, a
	jr z, submenuList.checkRight
		jp submenuList.left
	.checkRight:
	bit 4, a
	jr z, submenuList.checkStart
		jp submenuList.right
	.checkStart:
	bit 3, a
	jr z, submenuList.checkB
		jp submenuList.start
	.checkB:
	bit 1, a
	jr z, submenuList.checkA
		jp submenuList.B
	.checkA:
	bit 0, a
	ret z
		jp submenuList.A

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.up:
.left:
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	sub $01
	ret c
	
	ldi [hl], a
	ld a, [hl]
	sub $01
	ldi [hl], a
	jr nc, submenuList.goodCursorUp
		dec [hl]
		dec hl
		inc [hl]
	
	.goodCursorUp:
	jp submenuList.draw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

.down:
.right:
	ld hl, NUMOPTIONS
	add hl, bc
	ld e, [hl]
	
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	inc a
	cp e
	ret z
	
	ldi [hl], a
	ld a, [hl]
	inc a
	cp $03
	ldi [hl], a
	jr nz, submenuList.goodCursorDown
		inc [hl]
		dec hl
		dec [hl]
	
	.goodCursorDown:
	jp submenuList.draw

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.A:
.start:
	ld hl, CURRENTOPTION
	add hl, bc
	ldd a, [hl]
	ld e, a
	ldd a, [hl]
	ld l, [hl]
	ld h, a
	ld [hl], e

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.B:
	swapInRam shadow_wmap
	ld hl, shadow_wmap + 32*14 + 1
	ld de, submenuList.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*15 + 1
	ld de, submenuList.blank_msg
	rst $20
	ld hl, shadow_wmap + 32*16 + 1
	ld de, submenuList.blank_msg
	rst $20 ;blank out the window layer where the submenu appears
	restoreBank "ram"
	
	updateActorMain submenuList.exit ;and exit
	jp submenuList.exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.draw:
	swapInRam shadow_wmap
	ld hl, CURRENTBKG
	add hl, bc
	ld a, [hl] ;get offset from first string in the list
	
	ld hl, STRINGBASE
	add hl, bc
	add [hl] ;a = string ID for the topmost option on screen
	
	ld hl, submenuList.strings
	add a
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl = ptr to ptr to upcoming string to be printed
	
	ldi a, [hl]
	ld e, a
	ld d, [hl] ;de = ptr to string
	ld hl, shadow_wmap + 32*14 + 1; hl points to vram where string loads in
	
	push bc
	ld bc, $000E
	REPT 3
		rst strcpy ;copy upcoming string, now de points to the next string
		add hl, bc ;hl points to the next vram area
	ENDR
	pop bc
	
	ld hl, CURRENTCURSOR
	add hl, bc
	ld a, [hl] ;get cursor position
	swap a
	add a ;multiply by width of tilemap
	
	ld hl, shadow_wmap + 32*14 + 1
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl points to left side of the CURSORth string
	
	ld [hl], "["
	ld de, $0011
	add hl, de
	ld [hl], "]"
	
	restoreBank "ram"
	
	call submitGraphicsTask
	ld hl, TASKSUCCESS
	add hl, bc
	ld a, [hl] ;a = 1 if task success, else 0
	ld [hl], $00
	dec a
	ret z ;continue with actor operation if successfully submitted
	
	updateActorMain submenuList.submit
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask
	ld hl, TASKSUCCESS
	add hl, bc
	ld a, [hl]
	ld [hl], $00
	dec a
	ret z
	
	updateActorMain submenuList.main
	ret
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.exit:
	call submitGraphicsTask
	ld hl, TASKSUCCESS
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

.target_table:
	db $06 ;number of options
	db $00 ;string ID of first option
	dw sort_method ;variable to write back to
	
	db $05
	db $06
	dw background_selection
	
	db $07
	db $0B
	dw color_scheme

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

STRINGID = 0
.strings: ;pointer table to all the strings below.
REPT NUMOPTIONS
	dw submenuList.string_{02X:STRINGID}
STRINGID = STRINGID + 1
ENDR

.string_00: db "      genre       \n"
.string_01: db "   alphabetical   \n"
.string_02: db "    score asc     \n"
.string_03: db "    score desc    \n"
.string_04: db "   skill level    \n"
.string_05: db "      tempo       \n"

.string_06: db "      stage       \n"
.string_07: db "      tunnel      \n"
.string_08: db "     disabled     \n"
.string_09: db "      wires       \n"
.string_0A: db "    geometric     \n"

.string_0B: db "      blues       \n"
.string_0C: db "      greens      \n"
.string_0D: db "       reds       \n"
.string_0E: db "    monochrome    \n"
.string_0F: db "  high contrast   \n"
.string_10: db "    dark mode     \n"
.string_11: db "      pastel      \n"


.task:
	GFXTASK shadow_wmap, $01C0, win_map, $01C0, $06
.blank_msg:
	db "                  \n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPC