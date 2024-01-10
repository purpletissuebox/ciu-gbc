SECTION "SUBMENU LEADIN", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;handler for the "lead-in time" submenu.
;displays a menu with 4 digits that be changed
;reads and writes to the lead-in time in the save file.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTDIGIT = $0010
DIGITS = $0011

PUSHC
SETCHARMAP settingsChars

submenuLeadin:
.init:
	ld de, submenuLeadin.task
	call loadGraphicsTask ;the region of the map for the submenu will stay constant, so pre-load a task for it
	
	swapInRam save_file
	
	ld hl, leadin_time
	ldi a, [hl]
	ld h, [hl]
	ld l, a ;get hl = lead-in time from the save file
	call submenuLeadin.itoa14 ;de = 4 digits in bcd
	
	ld hl, CURRENTDIGIT
	add hl, bc
	xor a
	ldi [hl], a ;start with the first digit selected, now hl points to the digit array
	
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
	ldi [hl], a ;write bcd number to the digit array
	
	swapInRam shadow_wmap
	ld hl, shadow_wmap + 32*14 + 1
	ld de, submenuLeadin.confirm_msg
	rst $20
	ld hl, shadow_wmap + 32*16 + 1
	ld de, submenuLeadin.cancel_msg
	rst $20 ;write static messages to the left side of the menu
	
	ld hl, shadow_wmap + 32*15 + 17
	ld a, "m"
	ldi [hl], a
	ld [hl], "s" ;write static milliseconds tag to the right side
	
	call submenuLeadin.renderDigits ;write digits and arrows to window
	restoreBank "ram"
	restoreBank "ram"	
	updateActorMain submenuLeadin.main
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
	ldi a, [hl] ;a = digit to increment, hl points to digit array already
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl points to digit to increment
	
	ld a, [hl]
	inc a ;increment it
	cp $0A
	ld [hl], a ;if it didnt overflow, write it as-is
	jr nz, submenuLeadin.wrapUp
		ld [hl], $00 ;otherwise wrap to 0
	.wrapUp:
	jp submenuLeadin.renderDigits ;render the new numbers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.down:
	ld hl, CURRENTDIGIT
	add hl, bc
	ldi a, [hl] ;a = digit to decrement, hl points to the digit array already
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a ;hl points to digit to decrement
	
	ld a, [hl]
	sub $01 ;decrement it
	ld [hl], a ;if it didnt underflow, write it as-is
	jr nc, submenuLeadin.wrapDown
		ld [hl], $09 ;otherwise, wrap to 9
	.wrapDown:
	jp submenuLeadin.renderDigits ;render the new numbers

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.left:
	ld hl, CURRENTDIGIT
	add hl, bc
	ld a, [hl]
	inc a
	and $03
	ld [hl], a ;arrow now appears over the digit to the left mod 4
	jp submenuLeadin.renderDigits ;render it

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.right:
	ld hl, CURRENTDIGIT
	add hl, bc
	ld a, [hl]
	dec a
	and $03
	ld [hl], a ;arrow now appears over the digit to the right mod 4
	jp submenuLeadin.renderDigits

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.A:
.start:
	ld hl, DIGITS
	add hl, bc ;hl points to array of 4 digits from least to most significant
	ldi a, [hl]
	ld e, a
	ldi a, [hl]
	ld d, a
	ldi a, [hl]
	ld h, [hl]
	ld l, a ;the digits are now in hlde order
	
	call submenuLeadin.atoi14 ;convert to binary in de
	swapInRam save_file
	ld hl, leadin_time
	ld a, e
	ldi [hl], a
	ld [hl], d ;save to the save file
	restoreBank "ram"
	;now we have successfully saved the lead in time. we exit by falling through to the B case, since that will also exit.

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
	rst $20 ;blank out the window layer where the submenu appears
	restoreBank "ram"
	
	updateActorMain submenuLeadin.exit ;and exit
	jp submenuLeadin.exit

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.renderDigits:
	swapInRam shadow_wmap
	;first, display the digits
	ld hl, DIGITS
	add hl, bc ;hl points to digit array from least to most significant
	ld de, shadow_wmap + 32*15 + 15 ;de points to the rightmost digit
	
	ldi a, [hl]
	add "0"
	ld [de], a
	dec de
	ldi a, [hl]
	add "0"
	ld [de], a
	dec de
	ldi a, [hl]
	add "0"
	ld [de], a
	dec de
	ldi a, [hl]
	add "0"
	ld [de], a ;save digits from right to left (least to most significant)
	
	;next, blank out where the old arrow was	
	ld hl, CURRENTDIGIT
	add hl, bc
	ld d, [hl] ;d = the position where the arrows need to appear later
	
	ld a, " "
	ld hl, shadow_wmap + 32*16+12 ;bottom row
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld hl, shadow_wmap + 32*14+12 ;top row
	ldi [hl], a
	ldi [hl], a
	ldi [hl], a
	ld [hl], a ;hl points to the tile above the rightmost digit
	
	ld a, l
	sub d
	ld l, a
	ld a, h
	sbc $00
	ld h, a ;go backwards "d" tiles, so hl now points to the tile where the arrow should appear
	
	ld [hl], "v" ;save up arrow
	ld de, $0040
	add hl, de ;go down 2 rows
	ld [hl], "x" ;save down arrow
	
	restoreBank "ram"
	
	call submitGraphicsTask ;normally we would submit repeatedly until the task goes through, but the caller is probably expecting to get control back pretty soon.
	ld hl, TASKSDONE
	add hl, bc
	ld a, [hl] ;read if it went through or not
	ld [hl], $00 ;regardless of if it did, this actor will submit several more tasks in the future, but it checks to see if the tasks completed = 1. so keep writing a zero here to avoid messing up the check later.
	dec a ;check if number of tasks was 1
	ret z ;if it was, then go back to the caller immediately
	
	updateActorMain submenuLeadin.submit ;this way, lag frames are only inserted if necessary.
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.itoa14: ;converts 14 bit number in hl to 4 digit bcd in de
	xor a
	add hl, hl
	add hl, hl ;since the upper 2 digits are 0, go ahead and shift them out
	
	add hl, hl
	rla
	add hl, hl
	rla
	add hl, hl ;the next 3 bits range from 0-7, which are the same in base 10 and 16
	rla ;so we can just shift them into a with no issue
	
	ld d, $04
	.phase2:
		add hl, hl ;the next 4 bits range from 0-127, which fits in a + carry bit.
		adc a
		daa ;so daa with one register
		dec d
	jr nz, submenuLeadin.phase2
	
	rl d ;put carry in d
	ld e, a ;put least significant digits in e
	
	ld l, $07 ;now that 9 bits are shifted out, l is free to hold the loop counter
	.phase3:
		sla h ;the remaining 7 bits range from 0-9999, which need 2 registers (de)
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

.atoi14: ;hlde contains a string of 4 digits in base ten.
	ld a, d ;first, consolidate the tens and ones.
	add a
	add a
	add d
	add a
	add e
	ld e, a ;e = d*10 + e
	
	ld a, h ;consolidate the hundreds and thousands.
	add a
	add a
	add h
	add a
	add l
	ld d, a ;d = h*10 + l
	
	;finally, multiply d*100 + e to get h*1000+l*100+d*10+e, which is the number we want
	ld l, a
	ld h, $00
	
	add hl, hl ;2
	ld a, d
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a    ;3
	add hl, hl ;6
	add hl, hl ;12
	add hl, hl ;24
	ld a, d
	add l
	ld l, a
	ld a, h
	adc $00
	ld h, a    ;25
	add hl, hl ;50
	add hl, hl ;100
	
	ld d, $00
	add hl, de
	ld e, l
	ld d, h
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

.submit:
	call submitGraphicsTask ;attempt to load the task
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl] ;we will check if it went through by checking if num_tasks = 1. however, this means the next graphics task will be considered failed if num_tasks = 2
	ld [hl], $00 ;to fix this, write a zero here for later
	dec a ;check if the task went through
	ret nz ;try again if it didnt
	
	updateActorMain submenuLeadin.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.exit:
	call submitGraphicsTask
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl]
	ld [hl], $00 ;this works on the exact same mechanism as .submit above.
	dec a
	ret nz
	
	ld a, SETTINGS ;but this time, instead of returning to the main function, we exit the actor entirely.
	ldh [scene], a ;flag to the settings menu actor to start taking inputs again
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