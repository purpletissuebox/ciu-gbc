@echo off

SET options1=-p 0xFF -h -Weverything -o ciu.o ..\ciu.asm
SET options2=-m ciuMap.txt -n ciu.sym -p 0xFF -o ciu.gbc ciu.o
SET options3=-fhg -p 0xFF ciu.gbc

rgbasm %options1%
rgblink %options2%
rgbfix %options3%

DEL ciu.o

pause