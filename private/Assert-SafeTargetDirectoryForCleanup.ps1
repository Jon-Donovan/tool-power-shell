function Assert-SafeTargetDirectoryForCleanup {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$TargetDirectory,

        [Parameter(Mandatory)]
        [string]$SourceDirectory
    )

    if (-not (Test-Path $TargetDirectory -PathType Container)) {
        throw "TargetDirectory для очистки должна существовать и быть директорией: $TargetDirectory"
    }

    $targetFull = Get-NormalizedDirectoryPath -Path $TargetDirectory
    $sourceFull = Get-NormalizedDirectoryPath -Path $SourceDirectory

    $targetRoot = [System.IO.Path]::GetPathRoot($targetFull).TrimEnd('\')

    if ($targetFull.Equals($targetRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Очистка корня диска запрещена: $TargetDirectory"
    }

    if ($targetFull.Equals($sourceFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "Очистка TargetDirectory запрещена, если она совпадает с SourceDirectory"
    }

    if (Test-PathInsideDirectory -ChildPath $targetFull -ParentDirectory $sourceFull) {
        throw "Очистка TargetDirectory запрещена, если она находится внутри SourceDirectory"
    }
}
