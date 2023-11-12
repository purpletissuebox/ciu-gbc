cnote EQUS "0"
c#note EQUS "1"
dnote EQUS "2"
d#note EQUS "3"
enote EQUS "4"
fnote EQUS "5"
f#note EQUS "6"
gnote EQUS "7"
g#note EQUS "8"
anote EQUS "9"
a#note EQUS "10"
bnote EQUS "11"

quadwhole EQUS "$FF\ndb $75, $00, $00, $01"
doublewhole EQUS "$80"
wholenote EQUS "$40"
halfnote EQUS "$20"
quarternote EQUS "$10"
eighthnote EQUS "$08"
sixteenthnote EQUS "$04"
thirtysecondnote EQUS "$02"
sixtyfourthnote EQUS "$01"

note: MACRO ;\1 = note name, \2 = octave, \3 = volume, \4 = inst ID, \5 = length
	db (\1) + 12*((\2) - 2)
	db (\3) ;<< 4
	db (\5)
	db (\4)
ENDM

loop_point: MACRO
	db $80 | (1 << (\1))
	db 1 << (\1)
	db HIGH(.m_\2_\3)
	db LOW(.m_\2_\3)
ENDM
	
infinite_loop: MACRO
	db $81, $01
	db HIGH(.m_\1_\2)
	db LOW(.m_\1_\2)
	db $81, $01
	db HIGH(.m_\1_\2)
	db LOW(.m_\1_\2)
ENDM

instrument: MACRO ;\1-\3 = inst string IDs, \1 = pcm 
	IF (_NARG == 1)
		db $08
		dw \1
		db BANK(\1)
		db $FF, $FF, $FF, $FF
	ELSE
SETTINGS = 0
		REPT 3
			IF (\1) >= 0
SETTINGS = SETTINGS | 8
			ENDC
			
SETTINGS = SETTINGS >> 1
			shift 1
		ENDR
		
		shift -3		
		db SETTINGS
		
		IF(\1 >= 0)
			dw .duty_string_\1
		ELSE
			dw $FFFF
		ENDC
		
		IF(\2 >= 0)
			dw .vol_string_\2
		ELSE
			dw $FFFF
		ENDC
		
		IF(\3 >= 0)
			dw .pitch_string_\3
		ELSE
			dw $FFFF
		ENDC
		
		db $FF
	ENDC
ENDM

song: MACRO

PUSHS
	INCLUDE "../assets/music/songs/\1Song.asm"
	INCLUDE "../assets/music/insts/\1Insts.asm"
POPS

CHANNELID = 1
	REPT 4
		dw \1_notestream_ch{u:CHANNELID}
		db BANK(\1_notestream_ch{u:CHANNELID})
		db $00
CHANNELID = CHANNELID + 1
	ENDR

CHANNELID = 1
	REPT 4
		dw \1_inst_list_ch{u:CHANNELID}
		db BANK(\1_inst_list_ch{u:CHANNELID})
CHANNELID = CHANNELID + 1
	ENDR

	bpm \2
	db \3
	dw $FFFF
ENDM

bpm: MACRO
	db (ROUND(MUL((\1 << 16), 1.142920922))) >> 16 - 80

ENDM

pcm_struct: MACRO
	db $00
	TIME = 0
	REPT _NARG/2
		dw (\1)
		BANK(\1)
		TIME = TIME + \2
		db TIME
		shift
		shift
	ENDR
	db $FF
ENDM

song_list:
	song crabby, 164, 1
	.end