SECTION "SETTINGS INPUT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;reads user input every frame and spawns child actors to handle them.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

CURRENTOPTION = $0004
CURRENTCURSOR = $0005
CURRENTBKG = $0006
NUMOPTIONS = $09
NUMVISIBLE = $06

settingsInput:
.init:
	swapInRam save_file
	
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [last_selected_option]
	ldi [hl], a ;get the most recently selected option and copy it to local memory. this will appear as the topmost option.
	
	cp NUMOPTIONS - NUMVISIBLE + 1 ;if the option is near the end of the list, we cant render it as the topmost one.
	jr c, settingsInput.topOption ;if the option is near the top, then we can.
		sub NUMOPTIONS - NUMVISIBLE ;calculate where the cursor will appear since it won't be the top
		ldi [hl], a 
		ld [hl], NUMOPTIONS - NUMVISIBLE ;put background at the lowest place possible
		jr settingsInput.loadBkg		
	.topOption:	
	ld [hl], $00 ;cursor is at the top
	inc hl
	ld [hl], a ;background is where the option said it would be
	
	.loadBkg:
	restoreBank "ram"
	ld hl, CURRENTCURSOR
	add hl, bc
	ld a, [hl]
	ld de, settingsInput.arrow_actor ;load cursor
	call spawnActorV
	
	ld hl, CURRENTBKG
	add hl, bc
	ld a, [hl]
	ld de, settingsInput.bkg_actor ;load menu options
	call spawnActorV
	
	updateActorMain settingsInput.main
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.main:
	ldh a, [scene]
	cp SETTINGS
	ret nz ;do not accept input when a submenu is active
	
	ldh a, [press_input]
	
	bit 7, a
	jr z, settingsInput.checkUp
		jp settingsInput.down
	.checkUp:
	bit 6, a
	jr z, settingsInput.checkLeft
		jp settingsInput.up
	.checkLeft:
	bit 5, a
	jr z, settingsInput.checkRight
		jp settingsInput.left
	.checkRight:
	bit 4, a
	jr z, settingsInput.checkStart
		jp settingsInput.right
	.checkStart:
	bit 3, a
	jr z, settingsInput.checkSelect
		jp settingsInput.start
	.checkSelect:
	bit 2, a
	jr z, settingsInput.checkB
		jp settingsInput.select
	.checkB:
	bit 1, a
	jr z, settingsInput.checkA
		jp settingsInput.B
	.checkA:
	bit 0, a
	ret z
		jp settingsInput.A
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.left:
.up:
	;scroll towards lower numbered options
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	sub $01 ;decrement current option
	ret c ;if we were already at the first option, do nothing
	
	ldi [hl], a ;save new option
	ld a, [hl]
	sub $01 ;decrement cursor position
		jr c, settingsInput.fixBkgUp ;if the cursor was already at the top, then move the entire background instead
	ld [hl], a ;save cursor position
	ld de, settingsInput.arrow_actor ;and render it
	jp spawnActorV
	
	.fixBkgUp:
	inc hl
	dec [hl] ;the background position is guaranteed to be in range after this, so blindly decrement and render.
	ld a, [hl]
	ld de, settingsInput.bkg_actor
	jp spawnActorV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.right:
.down:
	;scroll towards higher numbered regions
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	inc a ;increment current option
	cp NUMOPTIONS
	ret z ;if we are now out of bounds, do nothing
	
	ldi [hl], a ;save option
	ld a, [hl]
	inc a ;increment cursor position
	cp NUMVISIBLE
		jr z, settingsInput.fixBkgDown ;if the cursor is off the bottom of the screen, then move the background instead
	ld [hl], a ;save cursor position
	ld de, settingsInput.arrow_actor ;and render it
	jp spawnActorV
	
	.fixBkgDown:
	inc hl
	inc [hl] ;the background position is guaranteed to be in range after this, so blindly increment and render.
	ld a, [hl]
	ld de, settingsInput.bkg_actor
	jp spawnActorV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.start:
.A:
	;open the current option's submenu.
	ld a, SUBMENU
	ldh [scene], a ;block out future inputs
	ld hl, CURRENTOPTION
	ld a, [hl]
	ld de, settingsInput.submenu_actor ;spawn dispatcher using the current option as a variable
	jp spawnActorV

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.B:
.select:
	;close the menu and exit.
	ld a, MENU
	ldh [scene], a ;pass control back to the menu input actor
	
	ld de, settingsInput.wipe_actor ;scroll the menu away
	call spawnActor
	
	swapInRam save_file
	ld hl, CURRENTOPTION
	add hl, bc
	ld a, [hl]
	ld [last_selected_option], a ;write current option to save file before exiting
	restoreBank "ram"
	
	ld e, c
	ld d, b
	jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.wipe_actor:
	NEWACTOR settingsScroll, $80
.submenu_actor:
	NEWACTOR submenuDispatch, $FF
.arrow_actor:
	NEWACTOR settingsCursor, $FF
.bkg_actor:
	NEWACTOR settingsBkg, $FF