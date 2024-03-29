SECTION "TITLETILES", ROMX

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;loads and submits graphics tasks for the title screen scene
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

TASKSDONE = $000A

loadTitleTiles:
	ld hl, TASKSDONE
	add hl, bc
	ld de, loadTitleTiles.gfx_tasks
	ld a, [hl] ;get number of tasks successfully completed
	cp ((loadTitleTiles.end - loadTitleTiles.gfx_tasks) >> 3) ;check if we did them all
	jr z, loadTitleTiles.done
	
	add a
	add a
	add a
	add e
	ld e, a
	ld a, d
	adc $00
	ld d, a ;de = next remaining incomplete graphics task
	
	call loadGraphicsTask
	jp submitGraphicsTask ;try and complete it

	.done:
		ld e, c
		ld d, b
		jp removeActor

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	
.gfx_tasks:
	GFXTASK titleTiles1, $0000, bkg_tiles0, $0000
	GFXTASK titleTiles2, $0000, bkg_tiles0, $0400
	GFXTASK titleTiles3, $0000, bkg_tiles0, $0800
	GFXTASK titleTiles4, $0000, bkg_tiles0, $0C00
	GFXTASK titleTiles5, $0000, bkg_tiles1, $0800
	GFXTASK titleMap, $0000, bkg_map, $0000
	GFXTASK titleAttr, $0000, bkg_attr, $0000
	.end

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

SECTION "TITLE SCREEN TILES", ROMX
align 4
titleTiles1:
	INCBIN "../assets/gfx/bkg/title/titleTiles.bin", $0000, $0400
	.end
	
titleTiles2:
	INCBIN "../assets/gfx/bkg/title/titleTiles.bin", $0400, $0400
	.end
	
titleTiles3:
	INCBIN "../assets/gfx/bkg/title/titleTiles.bin", $0800, $0400
	.end
	
titleTiles4:
	INCBIN "../assets/gfx/bkg/title/titleTiles.bin", $0C00, $0400
	.end
	
titleTiles5:
	INCBIN "../assets/gfx/bkg/title/titleTiles.bin", $1000, $0440
	.end
	
titleMap:
	INCBIN "../assets/gfx/bkg/title/titleMap.bin"
	.end
	
titleAttr:
	INCBIN "../assets/gfx/bkg/title/titleAttr.bin"
	.end
