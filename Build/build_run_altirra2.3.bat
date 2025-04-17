
atasm -mae -I..\src -I..\fonts -o..\bin\icet.xex ..\src\icet.asm -l..\bin\icet.lab
if errorlevel 1 pause
start C:\Users\Itay\Desktop\Altirra-2.30\Altirra64.exe ..\bin\icet.xex