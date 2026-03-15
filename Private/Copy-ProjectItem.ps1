function Copy-ProjectItem {
    param(
        [Parameter(Mandatory)]$Item,
        [Parameter(Mandatory)][string]$SourceRoot,
        [Parameter(Mandatory)][string]$TargetRoot,
        [Parameter(Mandatory)][string[]]$Exclude
    )

    $fullName = [System.IO.Path]::GetFullPath($Item.FullName)
    $sourceRootFull = [System.IO.Path]::GetFullPath($SourceRoot)

    $relative = $fullName.Substring($sourceRootFull.Length).TrimStart('\')

    if ([string]::IsNullOrEmpty($relative)) {
        $targetPath = $TargetRoot
    }
    else {
        $targetPath = Join-Path $TargetRoot $relative
    }

    $suff = ""
    if ($Item.PSIsContainer) {
        $suff = "/"
    }

    if (-not [string]::IsNullOrEmpty($relative) -and (Test-Excluded -RelativePath $relative$suff -Patterns $Exclude)) {
        return
    }

    if ($Item.PSIsContainer) {
        New-Item -ItemType Directory -Path $targetPath -Force | Out-Null

        Get-ChildItem -Path $Item.FullName -Force | ForEach-Object {
            Copy-ProjectItem -Item $_ -SourceRoot $sourceRootFull -TargetRoot $TargetRoot -Exclude $Exclude
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
