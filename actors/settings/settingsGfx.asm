SECTION "SETTINGS GFX", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;                <    ^ v > 
;abcdefghijklmnopqrstuvwxyz
;     x          x    xxx x

VARIABLE = $0003
NUMTASKS = $000A
LISTEND = $09
NUMVISIBLE = $06

PUSHC
SETCHARMAP settingsChars

settingsMenu:
	push bc
	swapInRam shadow_wmap
	
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	cp LISTEND - NUMVISIBLE + 1
	jr c, settingsMenu.printHeader
		ld a, LISTEND - NUMVISIBLE
	.printHeader:
	
	ld b, a	
	ld hl, shadow_wmap + 32*4 + 6
	ld de, settingsMenu.header
	and a
	jr nz, settingsMenu.headerPresent
		ld de, settingsMenu.blank
	.headerPresent:
	call settingsMenu.strcpy
	
	ld c, $00
	.printLoop:
		ld hl, settingsMenu.strings
		ld a, b
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a
		
		ldi a, [hl]
		ld e, a
		ld d, [hl]		
		
		ld hl, shadow_wmap + 32*5 + 4
		ld a, c
		swap a
		add a
		add l
		ld l, a
		ld a, h
		adc $00
		ld h, a
		
		call settingsMenu.strcpy
		inc b
		inc c
		ld a, c
		cp NUMVISIBLE
	jr c, settingsMenu.printLoop
	
	ld a, b
	ld hl, shadow_wmap + 32*11 + 6
	ld de, settingsMenu.footer
	cp LISTEND
	jr nz, settingsMenu.footerPresent
		ld de, settingsMenu.blank
	.footerPresent:
	call settingsMenu.strcpy
	
	restoreBank "ram"	
	pop bc
	ld de, settingsMenu.task
	call loadGraphicsTask
	updateActorMain settingsMenu.submit
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.submit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	dec a
	ret nz
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.strcpy:
	ld a, [de]
	inc de
		and a
		ret z
	ldi [hl], a
	jr settingsMenu.strcpy

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.task:
	GFXTASK shadow_wmap, $0080, win_map, $0080, $10

STRINGID = 0
.strings:
REPT LISTEND
	dw settingsMenu.string_{02u:STRINGID}
STRINGID = STRINGID + 1
ENDR

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.header:    db "v more v", $00
.footer:    db "x more x", $00
.blank:     db "        ", $00

.string_00: db "scroll speed", $00
.string_01: db "note skin   ", $00
.string_02: db "key bindings", $00
.string_03: db "sort method ", $00
.string_04: db "input delay ", $00
.string_05: db "lead in time", $00
.string_06: db "background  ", $00
.string_07: db "color scheme", $00
.string_08: db "judgement   ", $00

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "SETTINGS CURSOR", ROMX

settingsCursor:
	swapInRam shadow_wmap
	
	ld hl, shadow_wmap + 32*5 + 3
	ld de, $0020
	ld a, NUMVISIBLE
	.loop:
		ld [hl], " "
		add hl, de
		dec a
	jr nz, settingsCursor.loop
		
	ld hl, VARIABLE
	add hl, bc
	ld a, [hl]
	
	swap a
	add a
	ld hl, shadow_wmap + 32*5 + 3
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a
	ld [hl], "z"
	
	restoreBank "ram"
	
	ld de, settingsMenu.task
	call loadGraphicsTask
	updateActorMain settingsMenu.submit
	jp settingsMenu.submit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
POPC