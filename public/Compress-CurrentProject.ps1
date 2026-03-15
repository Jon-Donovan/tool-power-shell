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
            throw "Файл конфигурации не найден: $ConfigPath"
        }

        $config = Get-Content $ConfigPath -Raw -Encoding UTF8 | ConvertFrom-Json

        if ([string]::IsNullOrWhiteSpace($config.TargetDirectory)) {
            throw "В конфиге не указан TargetDirectory"
        }

        if ([string]::IsNullOrWhiteSpace($config.ArchivePath)) {
            throw "В конфиге не указан ArchivePath"
        }

        $TargetDirectory = if ([System.IO.Path]::IsPathRooted($config.TargetDirectory)) {
            $config.TargetDirectory
        }
        else {
            Join-Path $SourceDirectory $config.TargetDirectory
        }

        $archivePathTemplate = Resolve-Placeholders -Text $config.ArchivePath -PlaceHolders $config.PlaceHolders

        $ArchivePath = if ([System.IO.Path]::IsPathRooted($archivePathTemplate)) {
            $archivePathTemplate
        }
        else {
            Join-Path $SourceDirectory $archivePathTemplate
        }

        $CleanTargetDirectory = [bool]$config.CleanTargetDirectory
        $Exclude = @($config.Exclude)

        $SourceDirectory = Get-NormalizedDirectoryPath -Path $SourceDirectory
        $TargetDirectory = Get-NormalizedDirectoryPath -Path $TargetDirectory
        $ArchivePath = Get-NormalizedFilePath -Path $ArchivePath

        if ($TargetDirectory.Equals($SourceDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "TargetDirectory не должна совпадать с SourceDirectory"
        }

        if (Test-PathInsideDirectory -ChildPath $TargetDirectory -ParentDirectory $SourceDirectory) {
            throw "TargetDirectory не должна находиться внутри SourceDirectory"
        }

        Test-ArchivePathConflicts `
            -ArchivePath $ArchivePath `
            -SourceDirectory $SourceDirectory `
            -TargetDirectory $TargetDirectory

        $archiveParent = Split-Path -Path $ArchivePath -Parent
        if ([string]::IsNullOrWhiteSpace($archiveParent)) {
            throw "Не удалось определить директорию для архива"
        }

        $archiveParent = Get-NormalizedDirectoryPath -Path $archiveParent

        if (-not (Test-Path $TargetDirectory -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($TargetDirectory, 'Создать целевую директорию')) {
                New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
            }
        }

        if (-not (Test-Path $archiveParent -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($archiveParent, 'Создать директорию для архива')) {
                New-Item -ItemType Directory -Path $archiveParent -Force | Out-Null
            }
        }

        if ($CleanTargetDirectory -and (Test-Path $TargetDirectory -PathType Container)) {
            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory $TargetDirectory `
                -SourceDirectory $SourceDirectory

            if ($PSCmdlet.ShouldProcess($TargetDirectory, 'Очистить целевую директорию')) {
                Get-ChildItem -Path $TargetDirectory -Force | Remove-Item -Recurse -Force
            }
        }

        Get-ChildItem -Path $SourceDirectory -Force | ForEach-Object {
            $relative = $_.Name

            if (Test-Excluded -RelativePath $relative -Name $_.Name -Patterns $Exclude) {
                return
            }

            Copy-ProjectItem `
                -Item $_ `
                -SourceRoot $SourceDirectory `
                -TargetRoot $TargetDirectory `
                -Exclude $Exclude
        }

        if (Test-Path $ArchivePath -PathType Leaf) {
            if ($PSCmdlet.ShouldProcess($ArchivePath, 'Удалить существующий архив')) {
                Remove-Item -Path $ArchivePath -Force
            }
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        if ($PSCmdlet.ShouldProcess($ArchivePath, "Создать ZIP-архив из $TargetDirectory")) {
            [System.IO.Compression.ZipFile]::CreateFromDirectory(
                $TargetDirectory,
                $ArchivePath,
                [System.IO.Compression.CompressionLevel]::Optimal,
                $false
            )
        }

        [pscustomobject]@{
            SourceDirectory      = $SourceDirectory
            ConfigPath           = $ConfigPath
            TargetDirectory      = $TargetDirectory
            ArchivePath          = $ArchivePath
            CleanTargetDirectory = $CleanTargetDirectory
            Exclude              = $Exclude
        }
    }
    catch {
        throw
    }
}