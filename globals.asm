ACTORSIZE EQUS "$0040"

SECTION "ACTOR_DATA_0", WRAM0[$C000]
TASKLIST:
	ds $30 ;holds 8 gfx tasks
ACTORHEAP:
	ds $FC0 ;holds 63 actors
	.end
;shadow_sprites:
	;ds $800 ;holds 128 tiles for sprite bank in vram
	;.end
	
SECTION "GAME_DATA_1", WRAMX[$D000], BANK[1]
UNION
save_file:
	ds $400
	.end
NEXTU
save_string:
	ds $10
save_scores:
	ds $300
last_played_song:
	ds $01
character:
	ds $01
note_speed:
	ds $01
color_scheme:
	ds $01
note_skin:
	ds $01
.padding:
	ds $EB
ENDU

score:
	ds $03
current_song:
	ds $01
game_mode:
	ds $01
	
sort_table:
	ds $40
	.end


SECTION "MUSIC_DATA_2", WRAMX[$D000], BANK[2]
music_stuff:
	note_streams:
		ds $10
		.end
	inst_lists:
		ds $0C
		.end
	music_enable:
		ds $01
	pcm_enable:
		ds $01
	tempo_change:
		ds $01
	.padding:
		ds $01


	beat_increase:
		ds $01
	global_timer:
		ds $03
	chnl_timers:
		ds $0C
	chnl_statuses:
		ds $10
	
	inst_timers:
		ds $10
	inst_ptrs:
		ds $0C
		.end
		
	pcm_timer:
		ds $01
	pcm_struct_ptr:
		ds $03
	old_wave:
		ds $10
		.end

music_code:
	loadNoteRAM:
		ds $8C
	getPitchRAM:
		ds $0F
	getInstrumentRAM:
		ds $1F
	loopChannelRAM:
		ds $27
	loadPCMRAM:
		ds $3B
	doFXRAM:
		ds $33
	
	updateInstrumentsRAM:
		ds $39
	updateDutyRAM:
		ds $34
	updateVolumeRAM:
		ds $54
	updatePitchRAM:
		ds $3F
	updatePCMRAM:
		ds $2C
	killPCMRAM:
		ds $1F
	note2SoundRegRAM:
		ds $30
		
	frequency_tableRAM:
		ds $0100

/*
ch1_ptr:
	ds $04
ch2_ptr:
	ds $04
ch3_ptr:
	ds $04
ch4_ptr:
	ds $04 ;ptr to the next note for each channel
;10
ch1_loop:
	ds $01
ch2_loop:
	ds $01
ch3_loop:
	ds $01
ch4_loop:
	ds $01 ;group of 8 loop flags (1 = section has played once already)
ch1_instTimer:
	ds $01
ch2_instTimer:
	ds $01
ch3_instTimer:
	ds $01
ch4_instTimer:
	ds $01 ;# of frames deep into each instrument data needs to be pulled from
tempo:
	ds $02 ;measured in frames/whole note
beat_increase:
	ds $02 ;how much the song timer needs to be incremented (beats/frame)
song_timer:
	ds $04 ;how many beats the song has been playing for in 24.8 format
;20
ch1_wakeUp:
	ds $04
ch2_wakeUp:
	ds $04
ch3_wakeUp:
	ds $04
ch4_wakeUp:
	ds $04 ;timestamp when the currently playing note will end
;30
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
inst_list:
	ds $04 ;ptr to instrument array for this song
;40
ch1_inst:
	ds $02
ch2_inst:
	ds $02
ch3_inst:
	ds $02
ch4_inst:
	ds $02
.padding:
	ds $08
;50
recent_note_1:
	ds $04
recent_note_2:
	ds $04
recent_note_3:
	ds $04
recent_note_4: ;4 byte struct containing pitch, instrument, envelope/vol, and length IDs
	ds $04
;60
old_wave:
	ds $10
;70
sample_map:
	ds $04
the_sample:
	ds $04
.padding:
	ds $88
;100
music_code1: ;code snippets that will be run from ram so that rom data can be looked up
	;ds decodeInstrument.end - decodeInstrument
	ds $BC
music_code1a:
	;ds updatePitch.end - updatePitch
	ds $42
music_code1b:
	;ds updateVolume.end - updateVolume
	ds $67
music_code1c:
	;ds updateDuty.end - updateDuty
	ds $58
music_code2:
	;ds loadNote.end - loadNote
	ds $CF
music_code3:
	;ds pitch2Freq.end - pitch2Freq
	ds $21
music_code4:
	;ds note2SoundReg.end - note2SoundReg
	ds $76
music_code5:
	;ds calculateLoopPoint.end - calculateLoopPoint
	ds $20
music_code7:
	;ds killPCM.end - killPCM
	ds $33*/

SECTION "DATA_3", WRAMX[$D000], BANK[3]

SECTION "DATA_4", WRAMX[$D000], BANK[4]

SECTION "SCRATCHGFX", WRAMX[$D000], BANK[5]
on_deck:
	ds $A0
	.end
up_next:
	ds $A0
	.end

SECTION "GFX_DATA_6", WRAMX[$D000], BANK[6]
UNION
shadow_tiles:
	ds $E00 ;backup tiles that can be manipulated out of vblank
	.end
NEXTU
animated_tiles:
	ds $40
	.end
ENDU

shadow_oam:
	ds $A0 ;backup satb table that can be manipulated out of vblank
	.end
shadow_palettes:
	ds $80 ;colors that will be copied to vram each frame
	.end
palette_backup:
	ds $80 ;holds original colors during screen effects so they can be restored
	.end
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
menu_bkg_index:
	ds $06
	.end
menu_oam_head:
	ds $01
menu_oam_index:
	ds $05
	.end

SECTION "BKG_DATA_7", WRAMX[$D000], BANK[7]
shadow_map:
	ds $400 ;backup bkg map that can be manipulated out of vblank
	.end
shadow_attr:
	ds $400 ;backup bkg attr that can be manipulated out of vblank
	.end
shadow_wmap:
	ds $400 ;backup win map that can be manipulated out of vblank
	.end
shadow_wattr:
	ds $400 ;backup win attr that can be manipulated out of vblank
	.end
	
SECTION "SAVEGAME", SRAM
save_string_S:
	ds $10
save_scores_S: ;24 bits * 64 songs * 4 difficulties
	ds $300
last_played_song_S:
	ds $01
character_S:
	ds $01
speed_S:
	ds $01
color_scheme_S:
	ds $01
note_skin_S:
	ds $01
	.end
	
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
	ds $01 ;DULRSSBA input struct for current input, press, hold, and release edges
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
scratch_byte:
	ds $01 ;faster than the stack
the_sample_lo:
	ds $01
the_sample_hi:
	ds $01
the_sample_bank:
	ds $01 ;ptr to audio sample used by timer interrupt
	
SECTION "SPRITETILES", VRAM[$8000], BANK[0]
sprite_tiles0:
	ds $800 ;sprite tiles that are copied from shadow_tiles every frame
	.end
	
SECTION "BKGTILES", VRAM[$8800], BANK[0]
UNION
bkg_tiles0:
	ds $1000 ;256 general purpose bkg tiles
	.end
NEXTU

menu_bands0:
	ds $0820
	.end
menu_text0:
	ds $01E0
	.end
menu_G_chunks:
	ds $0480
	.end
menu_P_chunks:
	ds $0180
	.end
ENDU
	
SECTION "BKGMAP", VRAM[$9800], BANK[0]
bkg_map:
	ds $400
	.end
	
SECTION "WINMAP", VRAM[$9C00], BANK[0]
win_map:
	ds $400
	.end

SECTION "SPRITETILES1", VRAM[$8000], BANK[1]
sprite_tiles1:
	ds $800 ;sprite tiles that are preserved between frames
	.end
	
SECTION "BKGTILES1", VRAM[$8800], BANK[1]
UNION
bkg_tiles1:
	ds $1000 ;256 general purpose bkg tiles
	.end
NEXTU
menu_bands1:
	ds $0820
	.end
menu_text1:
	ds $01E0
	.end
menu_O_chunks:
	ds $0380
	.end
menu_Y_chunks:
	ds $0280
	.end


ENDU

SECTION "BKGATTR", VRAM[$9800], BANK[1]
bkg_attr:
	ds $400
	.end
	
SECTION "WINATTR", VRAM[$9C00], BANK[1]
win_attr:
	ds $400
	.end