SECTION "MENU HUD INIT", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads tiles, attributes, and map for the hud on the menu scene.
;spawns child to load dynamic maps - the score and selected difficulty
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

menuHUDInit:
.getMap:
	updateActorMain menuHUDInit.getAttr
	swapInRam shadow_wmap
	
	ld hl, shadow_wmap
	ld de, hud_initial_map
	ld bc, (BANK(hud_initial_map) << 8) | ((hud_initial_map.end - hud_initial_map) >> 4)
	call bcopyBanked ;copy starting map to buffer in ram
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.getAttr:
	updateActorMain menuHUDInit.getScores
	swapInRam shadow_wattr
	
	ld hl, shadow_wattr
	ld de, hud_initial_attr
	ld bc, (BANK(hud_initial_attr) << 8) | ((hud_initial_attr.end - hud_initial_attr) >> 4)
	call bcopyBanked ;copy starting attributes to buffer in ram
	
	restoreBank "ram"
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.getScores: ;the hud actor already handles the initial tilemap, so spawn it instead of duplicating the work.
	swapInRam last_played_difficulty
	ld hl, last_played_difficulty
	ldd a, [hl] ;a = difficulty
	ld e, [hl] ;e = external song ID
	rrca
	rrca
	or e ;merge variable = ddxxxxxx
	ld de, menuHUDInit.hud_actor
	call spawnActorV
	restoreBank "ram"
	updateActorMain menuHUDInit.submit
	ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;	

.submit: ;loop for each task and submit it
	ld hl, NUMTASKS
	add hl, bc
	ld a, [hl] ;get number of successful graphics tasks
	cp ((menuHUDInit.end - menuHUDInit.hud_tasks) >> 3) ;if we hit the end, exit.
	jr nz, menuHUDInit.continue
		ld e, c
		ld d, b
		jp removeActor
	.continue:
	add a
	add a
	add a
	ld de, menuHUDInit.hud_tasks
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a
	call loadGraphicsTask ;submit the ith task in the list
	jp submitGraphicsTask
	
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.hud_actor:
	NEWACTOR menuHUD, $FF

.hud_tasks:
	GFXTASK hud_tiles0, $0000, menu_text0, $0000
	GFXTASK hud_tiles1, $0000, menu_text1, $0000
	GFXTASK shadow_wmap, $0000, win_map, $0000
	GFXTASK shadow_wattr, $0000, win_attr, $0000
	.end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "HUD GRAPHICS", ROMX

align 4
hud_tiles0:
	INCBIN "../assets/gfx/bkg/menu/hudTiles.bin",                     $0000, menu_text0.end-menu_text0
	.end
hud_tiles1:
	INCBIN "../assets/gfx/bkg/menu/hudTiles.bin", menu_text0.end-menu_text0, menu_text1.end-menu_text1
	.end
hud_initial_map:
	INCBIN "../assets/gfx/bkg/menu/hudMap.bin"
	.end
hud_initial_attr:
	INCBIN "../assets/gfx/bkg/menu/hudAttributes.bin"
	.end