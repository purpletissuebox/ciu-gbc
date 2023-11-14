@echo off

SET builddir=%0\..\

SET options1=-p 0xFF -h -Weverything             -o ciu.o    ..\ciu.asm
SET options2=-p 0xFF -m ciuMap.txt    -n ciu.sym -o ciu.gbc   .\ciu.o
SET options3=-p 0xFF -f hg                          ciu.gbc

pushd .
cd %builddir%

.\rgbasm.exe  %options1%
.\rgblink.exe %options2%
.\rgbfix.exe  %options3%

DEL .\ciu.o

popd
pause