function Test-ArchivePathConflicts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [Parameter(Mandatory)]
        [string]$SourceDirectory,

        [Parameter(Mandatory)]
        [string]$TargetDirectory
    )

    $archiveFull = Get-NormalizedFilePath -Path $ArchivePath
    $sourceFull = Get-NormalizedDirectoryPath -Path $SourceDirectory
    $targetFull = Get-NormalizedDirectoryPath -Path $TargetDirectory

    if ($archiveFull.Equals($targetFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "ArchivePath не должна совпадать с TargetDirectory"
    }

    if ($archiveFull.Equals($sourceFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "ArchivePath не должна совпадать с SourceDirectory"
    }

    if (Test-PathInsideDirectory -ChildPath $archiveFull -ParentDirectory $targetFull) {
        throw "ArchivePath не должна находиться внутри TargetDirectory"
    }

    if ((Test-Path $archiveFull) -and (Test-Path $archiveFull -PathType Container)) {
        throw "ArchivePath указывает на директорию, а не на файл архива: $archiveFull"
    }
}
