SECTION "ACTOR_DATA_0", WRAM0[$C000]
TASKLIST:
	ds $30 ;holds 8 gfx tasks
ACTORHEAP:
	ds $400 ;holds 16 actors
shadow_sprites:
	ds $800 ;holds 128 tiles for sprite bank in vram
	.end
	
SECTION "DATA_1", WRAMX[$D000], BANK[1]
ZEROPAGE:
	ds $100

SECTION "MUSIC_DATA_2", WRAMX[$D000], BANK[2]
ch1_ptr:
	ds $04
ch2_ptr:
	ds $04
ch3_ptr:
	ds $04
ch4_ptr:
	ds $04 ;ptr to the next note for each channel
	
inst_list:
	ds $04 ;ptr to instrument array for this song
ch1_instTimer:
	ds $01
ch2_instTimer:
	ds $01
ch3_instTimer:
	ds $01
ch4_instTimer:
	ds $01 ;# of frames deep into each instrument data needs to be pulled from
tempo:
	ds $02 ;measured in frames/half note
beat_increase:
	ds $02 ;how much the song timer needs to be incremented (beats/frame)
song_timer:
	ds $04 ;how many beats the song has been playing for in 24.8 format
	
ch1_wakeUp:
	ds $04
ch2_wakeUp:
	ds $04
ch3_wakeUp:
	ds $04
ch4_wakeUp:
	ds $04 ;timestamp when the currently playing note will end

ch1_loop:
	ds $01
ch2_loop:
	ds $01
ch3_loop:
	ds $01
ch4_loop:
	ds $01 ;group of 8 loop flags (1 = section has played once already)
ch1_pitch:
	ds $02
ch2_pitch:
	ds $02
ch3_pitch:
	ds $02
ch4_pitch:
	ds $02 ;16 bit number representing how far up or down the note should be pitched
ch1_duty:
	ds $01
ch2_duty:
	ds $01
ch3_duty:
	ds $01
ch4_duty:
	ds $01 ;duty cycle used for each channel
	
recent_note_1:
	ds $04
recent_note_2:
	ds $04
recent_note_3:
	ds $04
recent_note_4: ;4 byte struct containing pitch, instrument, envelope/vol, and length IDs
	ds $04
	
oldWave:
	ds $10
sampleMap:
	ds $04
theSample:
	ds $04
.padding:
	ds $18

music_code1:
	ds $180
music_code1a:
	ds $100
music_code1b:
	ds $100
music_code1c:
	ds $100
music_code1d:
	ds $100
music_code2:
	ds $100
music_code3:
	ds $100
music_code4: ;code snippets that will be run from ram so that rom data can be looked up
	ds $100
music_code5:
	ds $100
music_code6:
	ds $100
music_code7:
	ds $100

SECTION "DATA_3", WRAMX[$D000], BANK[3]

SECTION "DATA_4", WRAMX[$D000], BANK[4]

SECTION "DATA_5", WRAMX[$D000], BANK[5]

SECTION "GFX_DATA_6", WRAMX[$D000], BANK[6]
shadow_tiles:
	ds $E00 ;backup tiles that can be manipulated out of vblank
shadow_oam:
	ds $A0 ;backup satb table that can be manipulated out of vblank
shadow_palettes:
	ds $80 ;colors that will be copied to vram each frame
palette_backup:
	ds $80 ;holds original colors during screen effects so they can be restored
fade_timer:
	ds $02 ;screen brightness in 8.8 format: 1F.00 = full color, 00.FF = completely black
temp_rgb:
	ds $03 ;temporary storage for red, blue, and green color components
	.end
obj_fade_timer:
	ds $02 ;same but for sprites
obj_temp_rgb:
	ds $03 ;same but for sprites
	.end
shadow_scroll:
	ds $02 ;bkg scroll y,x
shadow_winloc:
	ds $02 ;win scroll y,x

SECTION "BKG_DATA_7", WRAMX[$D000], BANK[7]
shadow_map:
	ds $400 ;backup bkg map that can be manipulated out of vblank
shadow_attr:
	ds $400 ;backup bkg attr that can be manipulated out of vblank
shadow_wmap:
	ds $400 ;backup win map that can be manipulated out of vblank
shadow_wattr:
	ds $400 ;backup win attr that can be manipulated out of vblank

SECTION "HRAM", HRAM
rom_bank:
	ds $01
ram_bank:
	ds $01
vram_bank:
	ds $01 ;currently swapped in rom, wram, and vram banks
music_on:
	ds $01 ;music player will despawn when zero
num_tiles:
	ds $01
num_palettes:
	ds $01 ;occupied pallete and tile slots
first_actor:
	ds $02
next_actor:
	ds $02 ;ptrs to the first actor in the linked list and the next free location
next_task:
	ds $02 ;ptr to the next free slot in the gfx task list
raw_input:
	ds $01
press_input:
	ds $01
hold_input:
	ds $01
release_input:
	ds $01 ;UDLRSSBA input struct for current input, press, hold, and release edges
;16
vblank_jump:
	ds $03 ;3 byte instruction JP VBLANK.taskStart
oam_routine:
	ds $0A ;small routine to copy shadow oam to the real oam
rng_seed:
	ds $02 ;xorshift
actors_done:
	ds $01 ;byte is nonzero if interrupts should yield to vblank
;32
	
SECTION "SPRITETILES", VRAM[$8000], BANK[0]
sprite_tiles:
	ds $800 ;sprite tiles that are copied from shadow_tiles every frame
	
SECTION "BKGTILES", VRAM[$8800], BANK[0]
bkg_tiles:
	ds $1000 ;256 general purpose bkg tiles
	
SECTION "BKGMAP", VRAM[$9800], BANK[0]
bkg_map:
	ds $400
	
SECTION "WINMAP", VRAM[$9C00], BANK[0]
win_map:
	ds $400

SECTION "SPRITETILES1", VRAM[$8000], BANK[1]
sprite_tiles1:
	ds $800 ;sprite tiles that are preserved between frames
	
SECTION "BKGTILES1", VRAM[$8800], BANK[1]
bkg_tiles1:
	ds $1000 ;256 general purpose bkg tiles

SECTION "BKGATTR", VRAM[$9800], BANK[1]
bkg_attr:
	ds $400
	
SECTION "WINATTR", VRAM[$9C00], BANK[1]
win_attr:
	ds $400