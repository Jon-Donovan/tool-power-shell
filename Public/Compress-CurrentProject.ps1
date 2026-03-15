function Compress-CurrentProject {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    param(
        [string]$SourceDirectory = (Get-Location).Path,
        [string]$ConfigFileName = '.compress.config.json'
    )

    $ErrorActionPreference = 'Stop'

    try {
        $SourceDirectory = (Resolve-Path $SourceDirectory).Path
        $ConfigPath = Join-Path $SourceDirectory $ConfigFileName

        if (-not (Test-Path $ConfigPath -PathType Leaf)) {
            throw "Config file not found: $ConfigPath"
        }

        $config = Get-Content -Path $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace($config.ArchivePath)) {
            throw "ArchivePath is not specified in config"
        }

        $archivePathTemplate = Resolve-Placeholders -Text $config.ArchivePath -PlaceHolders $config.PlaceHolders

        $ArchivePath = if ([System.IO.Path]::IsPathRooted($archivePathTemplate)) {
            $archivePathTemplate
        }
        else {
            Join-Path $SourceDirectory $archivePathTemplate
        }

        $SourceDirectory = Get-NormalizedDirectoryPath -Path $SourceDirectory
        $ArchivePath = Get-NormalizedFilePath -Path $ArchivePath
        $Exclude = @($config.Exclude)

        $archiveParent = Split-Path -Path $ArchivePath -Parent
        if ([string]::IsNullOrWhiteSpace($archiveParent)) {
            throw "Failed to determine archive parent directory"
        }

        $archiveParent = Get-NormalizedDirectoryPath -Path $archiveParent

        Test-ArchivePathConflicts `
            -ArchivePath $ArchivePath `
            -SourceDirectory $SourceDirectory

        if (-not (Test-Path $archiveParent -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($archiveParent, 'Create archive directory')) {
                New-Item -ItemType Directory -Path $archiveParent -Force | Out-Null
            }
        }

        if (Test-Path $ArchivePath -PathType Leaf) {
            if ($PSCmdlet.ShouldProcess($ArchivePath, 'Remove existing archive')) {
                Remove-Item -Path $ArchivePath -Force
            }
        }

        Add-Type -AssemblyName System.IO.Compression
        Add-Type -AssemblyName System.IO.Compression.FileSystem

        if ($PSCmdlet.ShouldProcess($ArchivePath, "Create ZIP archive from $SourceDirectory")) {
            $fileStream = [System.IO.File]::Open(
                $ArchivePath,
                [System.IO.FileMode]::Create,
                [System.IO.FileAccess]::ReadWrite,
                [System.IO.FileShare]::None
            )

            try {
                $zipArchive = [System.IO.Compression.ZipArchive]::new(
                    $fileStream,
                    [System.IO.Compression.ZipArchiveMode]::Create,
                    $false
                )

                try {
                    Get-ChildItem -Path $SourceDirectory -Recurse -Force -File | ForEach-Object {
                        $filePath = Get-NormalizedFilePath -Path $_.FullName
                        $relativePath = $filePath.Substring($SourceDirectory.Length).TrimStart('\')

                        if (Test-Excluded -RelativePath $relativePath -Patterns $Exclude) {
                            return
                        }

                        $entryPath = $relativePath -replace '\\', '/'

                        [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                            $zipArchive,
                            $filePath,
                            $entryPath,
                            [System.IO.Compression.CompressionLevel]::Optimal
                        ) | Out-Null
                    }
                }
                finally {
                    $zipArchive.Dispose()
                }
            }
            finally {
                $fileStream.Dispose()
            }
        }

        [pscustomobject]@{
            SourceDirectory = $SourceDirectory
            ConfigPath      = $ConfigPath
            ArchivePath     = $ArchivePath
            Exclude         = $Exclude
        }
    }
    catch {
        throw
    }
}
