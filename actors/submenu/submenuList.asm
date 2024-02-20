SECTION "SUBMENU LIST", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;handler for a submenu that lets the user select from predefained options.
;selects parameters (number of options, ptr to strings, etc) based on variable.
;saves ID number of selection to save file when confirmed.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003

NUMOPTIONS = $0010
DEST = $0011
STRINGPTR = $0013
CURRENTOPTION = $0015
CURRENTBKG = $0016
CURRENTCURSOR = $0017

PUSHC
SETCHARMAP settingsChars

submenuList:
	ld de, submenuList.task
	call loadGraphicsTask
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	
	add a
	add a
	ld de, submenuList.target_table
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld hl, NUMOPTIONS
	add hl, bc
	
	REPT 3
		ld a, [de]
		inc de
		ldi [hl], a
	ENDR
	
	ld a, [de]
	add a
	ld de, submenuList.string_ptr_ptrs
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	
	ld a, [de]
	inc de
	ldi [hl], a
	ld a, [de]
	ldi [hl], a
	
	





	ld a, SETTINGS
	ldh [scene], a
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.targetTable:

.string_ptr_ptrs:

.string_ptrs:

.string_00_00:
.string_00_01:
.string_00_02:
.string_00_03:
.string_00_04:


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPC