@echo off
rem initiate the retry number
set retryNumber=0
set maxRetries=3

:RUN
%*
set LastErrorLevel=%ERRORLEVEL%
if %LastErrorLevel% == 0 goto :EOF
set /a retryNumber=%retryNumber%+1
if %reTryNumber% == %maxRetries% (goto FAILED)

:RETRY
set /a retryNumberDisp=%retryNumber%+1
@echo Command "%*" failed with exit code %LastErrorLevel%. Retrying %retryNumberDisp% of %maxRetries%
goto RUN

:FAILED
@echo Sorry, we tried running the command for %maxRetries% times and all attempts were unsuccessful!
exit /B %LastErrorLevel%
