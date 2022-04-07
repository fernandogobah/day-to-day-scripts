@REM #!/bin/bash
@REM # Author: Fernando Lima
@REM # E-mail: fernandogobah@gmail.com
@REM # Last Update: 2022-04-07
@REM # Desc: Script for deletes files in folder

SET NAME_FOLDER=W:\Folder1\Folder2


FOR /F "tokens=*" %%G IN ('DIR /B /AD /S %NAME_FOLDER%') DO RMDIR /S /Q "%%G"

DEL "%NAME_FOLDER%\*.*" /s /q