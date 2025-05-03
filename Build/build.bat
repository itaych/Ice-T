..\..\atasm\atasm -mae -I..\src -I..\fonts -o..\bin\icet.xex ..\src\icet.asm -l..\bin\icet.lab -g..\bin\icet.lst
if errorlevel 1 pause
