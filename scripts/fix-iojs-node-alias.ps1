function FixNodeExe($iojsPath) {
    if(-not (Test-Path $iojsPath)) {
        return
    }

    Remove-Item "$iojsPath\node.exe" -Force

    '@IF EXIST "%~dp0\iojs.exe" ( 
       "%~dp0\iojs.exe" %* 
    ) ELSE ( 
       iojs %* 
    )' | Out-File "$iojsPath\node.cmd" -Encoding ascii
}


FixNodeExe "${env:ProgramFiles(x86)}\iojs"
FixNodeExe "${env:ProgramFiles}\iojs"