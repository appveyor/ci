Try
{ 
	## BUILD
	echo Build-Office-Config
	cmd /c "choco install office365proplus" 
	refreshenv
	echo download-writage
	Start-FileDownload 'http://www.writage.com/Writage-1.10.msi'
	echo install-writage
	cmd /c "msiexec /i Writage-1.10.msi /quiet"
}
Catch
{
	$Error.Clear()
	echo BUILD-Catch
}
finally
{
	echo BUILD-Operator
	refreshenv
}
