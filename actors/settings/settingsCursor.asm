SECTION "SETTINGS CURSOR", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;moves the cursor on the settings screen up and down
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

VARIABLE = $0003
NUMTASKS = $000A
NUMVISIBLE = $06

PUSHC
SETCHARMAP settingsChars

settingsCursor:
	swapInRam shadow_wmap
	
	ld hl, shadow_wmap + 32*5 + 3 ;hl points just left of the topmost option
	ld de, $0020 ;de = distance between rows
	ld a, NUMVISIBLE ;a = loop counter
	.loop:
		ld [hl], " " ;blank out all the rows to erase previous cursor position
		add hl, de
		dec a
	jr nz, settingsCursor.loop
		
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;a = number of rows below the first option to place the cursor
	
	swap a
	add a ;a = number of rows * 32 = number of tiles to advance
	ld hl, shadow_wmap + 32*5 + 3 ;hl points to the first row's cursor position
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	ld [hl], "z" ;save new cursor at that row
	
	restoreBank "ram"
	
	ld de, settingsCursor.task
	call loadGraphicsTask
	updateActorMain settingsCursor.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask ;attempt to submit the task
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
	ret nz ;if it failed, try again next frame
	
	ld e, c
	ld d, b
	jp removeActor ;otherwise we are done

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.task:
	GFXTASK shadow_wmap, $0080, win_map, $0080, $10

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
POPC