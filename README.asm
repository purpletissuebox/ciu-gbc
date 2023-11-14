;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;BUILD INSTRUCTIONS
;shortcut for windows users:
;1. run the included build/build.bat. the rom will be made in build/ciu.gbc.
;2. debug files ciu.sym and ciuMap.txt can be removed for casual play.
;
;otherwise, to build it yourself:
;1. install rgbasm, rgblink, and rgbfix. tested using v0.5.1. (https://github.com/gbdev/rgbds/releases/tag/v0.5.1)
;2. navigate to <install directory>/build.
;3. assemble: rgbasm -p 0xFF -h -Weverything -o <object file> ../ciu.asm
;4. link: rgblink -p 0xFF -o <rom name> <object file>
;4b. optional flags -m <map file> and -n <symbol file> can be used to build debug information along with the rom.
;5. fix checksums: rgbfix -p 0xFF -f hg <rom name>
;6. the object file can now be removed.
;
;open the rom with your favorite game boy color device.
;thank you for reading
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;