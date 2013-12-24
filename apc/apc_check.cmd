@echo off
set item=%~1
for /f "tokens=3" %%i in ('type c:\apcupsd\etc\apcupsd\apcupsd.status ^| find.exe /i "%item%"') do (
	set line=%%i
	goto out
)
:out
echo %line%
