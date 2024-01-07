SECTION "SETTINGS BKG", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;moves the cursor and the menu options in the settings scene.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;an "x" below a letter denotes it being unused. they will be used to store ui elements instead, which appear above them.
;                <    ^ v > 
;abcdefghijklmnopqrstuvwxyz
;     x          x    xxx x

VARIABLE = $0003
NUMTASKS = $000A
NUMOPTIONS = $09
NUMVISIBLE = $06

PUSHC
SETCHARMAP settingsChars

settingsBkg:
	push bc
	swapInRam shadow_wmap
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl] ;variable contains the topmost option
	ld b, a	;store it in b for later
	
	;first, render the headeh
	ld hl, shadow_wmap + 32*4 + 6 ;hl points to where the header string goes
	ld de, settingsBkg.header
	and a
	jr nz, settingsBkg.headerPresent ;if we are not already at the top of the menu, print a message saying there are more options above.
		ld de, settingsBkg.blank ;otherwise there are no more options and we print nothing.
	.headerPresent:
	rst $20
	
	;then render the options in order
	ld c, $00 ;b = current string ID, c = number of strings we have rendered so far
	.printLoop:
		ld hl, settingsBkg.strings
		ld a, b
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl points to a pointer to the next option's string
		
		ldi a, [hl]
		ld e, a
		ld d, [hl] ;de points to the string
		
		ld hl, shadow_wmap + 32*5 + 4 ;hl points to the left column of the menu
		ld a, c ;c = the number of rows down we need to travel
		swap a
		add a ;a = c*32, which is the number of tiles to go down that many rows
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a ;hl points to the background where we are loading the string
		
		rst $20
		inc b ;increment string ID
		inc c ;increment which row it will go on
		ld a, c
		cp NUMVISIBLE ;when we have done all the visible options, exit
	jr c, settingsBkg.printLoop
	
	;render the footer
	ld a, b
	ld hl, shadow_wmap + 32*11 + 6 ;hl points to where the footer will appear
	ld de, settingsBkg.footer
	cp NUMOPTIONS
	jr nz, settingsBkg.footerPresent ;if we are not on the last option, print a message saying there are more options below.
		ld de, settingsBkg.blank ;otherwise there are no more options and we print nothing.
	.footerPresent:
	rst $20
	
	restoreBank "ram"	
	pop bc
	ld de, settingsBkg.task ;copy the new text into vram
	call loadGraphicsTask
	updateActorMain settingsBkg.submit
	
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

STRINGID = 0
.strings: ;pointer table to all the strings below.
REPT NUMOPTIONS
	dw settingsBkg.string_{02u:STRINGID}
STRINGID = STRINGID + 1
ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.header:    db "v more v\n"
.footer:    db "x more x\n"
.blank:     db "        \n"

.string_00: db "scroll speed\n"
.string_01: db "note skin   \n"
.string_02: db "key bindings\n"
.string_03: db "sort method \n"
.string_04: db "input delay \n"
.string_05: db "lead in time\n"
.string_06: db "background  \n"
.string_07: db "color scheme\n"
.string_08: db "judgement   \n"

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

POPC