@echo off
rem initiate the retry number
set errorCode=1
set retryNumber=0
set maxRetries=3

:RESTORE
nuget restore %*

rem problem?
IF ERRORLEVEL %errorCode% GOTO :RETRY

rem everything is fine!
GOTO :EXIT

:RETRY
@echo Oops, nuget restore exited with code %errorCode% - let us try again!
set /a retryNumber=%retryNumber%+1
IF %reTryNumber% LSS %maxRetries% (GOTO :RESTORE)
IF %retryNumber% EQU %maxRetries% (GOTO :ERR)

:ERR
@echo Sorry, we tried restoring nuget packages for %maxRetries% times and all attempts were unsuccessful!
EXIT /B 1

:EXIT
