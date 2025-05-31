
rd /s/q atrdisk
rd /s/q release
del release
del release.7z

mkdir release
mkdir atrdisk

atasm -mae -I..\src -I..\fonts -o..\bin\icet.xex ..\src\icet.asm -l..\bin\icet.lab
if errorlevel 1 goto error
atasm -mae -I..\Col80 ..\Col80\col80.asm -oatrdisk\col80.com
if errorlevel 1 goto error

copy ..\bin\icet.xex atrdisk\icet.com
copy ..\RHandlers\*.* atrdisk
copy ..\Doc\readme.txt atrdisk
copy ..\Doc\icet.txt atrdisk
copy ..\Doc\vt102.txt atrdisk
copy mydos\*.* atrdisk

copy ..\bin\icet.xex release
copy ..\Doc\quickstart.txt release
copy ..\Doc\icet.txt release
copy ..\Doc\vt102.txt release

rem TEMP
rem atasm -mae -I..\Col80 ..\Col80\col80.asm -oatrdisk\col80.com -lcol80.lab
rem ren atrdisk\col80.com col80.ar0
rem ren atrdisk\icet.txt i
rem copy g atrdisk\
rem copy icet.dat atrdisk\
rem END TEMP

dir2atr -m -b MyDos4534 1040 release\icet.atr atrdisk
if errorlevel 1 goto error

rd /s/q atrdisk

cd release
"%programfiles%\7-Zip\7z" a ..\release.zip *.*
cd ..
if errorlevel 1 goto error

goto end
:error
pause
:end

rd /s/q release
