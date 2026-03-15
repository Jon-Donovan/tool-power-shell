function Test-ArchivePathConflicts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ArchivePath,

        [Parameter(Mandatory)]
        [string]$SourceDirectory,

        [string]$TargetDirectory
    )

    $archiveFull = Get-NormalizedFilePath -Path $ArchivePath
    $sourceFull = Get-NormalizedDirectoryPath -Path $SourceDirectory

    if (-not [string]::IsNullOrWhiteSpace($TargetDirectory)) {
        $targetFull = Get-NormalizedDirectoryPath -Path $TargetDirectory

        if ($archiveFull.Equals($targetFull, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "ArchivePath must not match TargetDirectory"
        }

        if (Test-PathInsideDirectory -ChildPath $archiveFull -ParentDirectory $targetFull) {
            throw "ArchivePath must not be inside TargetDirectory"
        }
    }

    if ($archiveFull.Equals($sourceFull, [System.StringComparison]::OrdinalIgnoreCase)) {
        throw "ArchivePath must not match SourceDirectory"
    }

    if (Test-PathInsideDirectory -ChildPath $archiveFull -ParentDirectory $sourceFull) {
        throw "ArchivePath must not be inside SourceDirectory"
    }

    if ((Test-Path $archiveFull) -and (Test-Path $archiveFull -PathType Container)) {
        throw "ArchivePath points to a directory instead of an archive file: $archiveFull"
    }
}
