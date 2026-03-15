function Copy-ProjectItem {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string[]]$Exclude
    )

    $fullName = [System.IO.Path]::GetFullPath($Item.FullName)
    $relative = $fullName.Substring($SourceRoot.Length).TrimStart('\')
    $targetPath = Join-Path $TargetRoot $relative

    if (Test-Excluded -RelativePath $relative -Name $Item.Name -Patterns $Exclude) {
        return
    }

    if ($Item.PSIsContainer) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

        Get-ChildItem -Path $Item.FullName -Force | ForEach-Object {
            Copy-ProjectItem -Item $_ -SourceRoot $SourceRoot -TargetRoot $TargetRoot -Exclude $Exclude
        }
    }
    else {
        $parent = Split-Path -Path $targetPath -Parent
        if (-not (Test-Path $parent)) {
            New-Item -ItemType Directory -Path $parent -Force | Out-Null
        }

        Copy-Item -Path $Item.FullName -Destination $targetPath -Force
    }
}
