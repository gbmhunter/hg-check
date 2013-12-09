:: Reports if there are any uncomitted changes in repos
@echo off
for /d %%d in (*) do (
	cd %%d
	:: By default, /F breaks up command output at spaces
	for /F %%G in ('hg id') do call :CheckId "%%G" "%%d"	
	:: echo %%d
	::for /F "delims=" %%G in ('hg outgoing -v') do call :CheckOutgoing "%%G" "%%d"	
	setlocal enabledelayedexpansion
	set CONCAT_STR=
	for /f "delims=" %%i in ('hg outgoing -v') do set "CONCAT_STR=!CONCAT_STR! %%i"
	::echo !CONCAT_STR!
	call :CheckOutgoing "!CONCAT_STR!" "%%d"
	cd ..
)
pause
GOTO :EOF

:CheckId
	rem Search for "+" substring withing each ID. If present, there are uncomitted changes.
	setlocal enableextensions enabledelayedexpansion
	set str1=%1	
	if not x%str1:+=%==x%str1% echo Uncomitted changes in %~2!
GOTO :EOF

:CheckOutgoing
	rem Search for "no changes found" substring within output of "hg outgoing -v". If present, there are unpushed changes.
	setlocal enableextensions enabledelayedexpansion
	set "str1=%1"
	::echo "Input=%~1"
	set "searchText=no changes found"
	set replaceText=
	set modified=!str1:%searchText%=%replaceText%!
	::echo Mod !modified!
	::echo Orig %str1% 
	if %modified% == %str1% echo Unpushed changes in %~2!
GOTO :EOF