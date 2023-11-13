;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;
;BUILD INSTRUCTIONS
;shortcut for windows users:
;1. open the included build/build.bat.
;2. replace the builddir variable with the path to the build/ folder on your machine.
;3. run build.bat. the rom will be made in build/ciu.gbc.
;4. debug files ciu.sym and ciuMap.txt can be removed for casual play.
;
;otherwise, to build it yourself:
;1. install rgbasm, rgblink, and rgbfix. tested using v0.5.1. (https://github.com/gbdev/rgbds/releases/tag/v0.5.1)
;2. navigate to <install directory>/build.
;3. assemble: rgbasm -p 0xFF -h -Weverything -o <object file> ../ciu.asm
;4. link: rgblink -p 0xFF -o <rom name> <object file>
;5. fix checksums: rgbfix -p 0xFF -f hg <rom name>
;6. the object file can now be removed.
;
;open the rom with your favorite game boy color device.
;thank you for reading
;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;