function Get-Path
{
    ([Environment]::GetEnvironmentVariable("path", "machine")).Split(";") | Sort-Object
}

function Add-Path([string]$item)
{
    $item = (Get-SanitizedPath $item)
    $pathItemsArray = ([Environment]::GetEnvironmentVariable("path", "machine")).Split(";")
    $pathItems = New-Object System.Collections.ArrayList($null)
    $pathItems.AddRange($pathItemsArray)

    # add folder
    $index = -1
    for($i = 0; $i -lt $pathItems.Count; $i++) {
        if((Get-SanitizedPath $pathItems[$i]) -eq $item) {
            $index = $i;
            break
        }
    }

    if($index -eq -1) {
        # item not found - add it
        $pathItems.Add($item) | Out-null

        # update PATH variable
        $updatedPath = $pathItems -join ';'
        [Environment]::SetEnvironmentVariable("path", $updatedPath, "machine")        
    }
}

function Remove-Path([string]$item)
{
    $item = (Get-SanitizedPath $item)
    $pathItemsArray = ([Environment]::GetEnvironmentVariable("path", "machine")).Split(";")
    $pathItems = New-Object System.Collections.ArrayList($null)
    $pathItems.AddRange($pathItemsArray)

    $index = -1
    for($i = 0; $i -lt $pathItems.Count; $i++) {
        if((Get-SanitizedPath $pathItems[$i]) -eq $item) {
            $index = $i;
            break
        }
    }

    if($index -ne -1) {
        # remove folder
        $pathItems.RemoveAt($index) | Out-null

        # update PATH variable
        $updatedPath = $pathItems -join ';'
        [Environment]::SetEnvironmentVariable("path", $updatedPath, "machine")        
    }
}

function Get-SanitizedPath([string]$path) {
    return $path.Replace('/', '\').Trim('\')
}

function Add-SessionPath([string]$path) {

    $sanitizedPath = Get-SanitizedPath $path

    foreach($item in $env:path.Split(";")) {
        if($sanitizedPath -eq (Get-SanitizedPath $item)) {
            return # already added
        }
    }

    $env:path = "$sanitizedPath;$env:path"
}

# export module members
Export-ModuleMember -Function Get-Path, Add-Path, Remove-Path, Add-SessionPath
