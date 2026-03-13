function New-ZipFromCurrentDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$TargetDirectory,

        [Parameter(Mandatory = $true)]
        [string]$ArchivePath,

        [string]$SourceDirectory = (Get-Location).Path,

        [switch]$CleanTargetDirectory
    )

    $ErrorActionPreference = 'Stop'

    try {
        $SourceDirectory = (Resolve-Path $SourceDirectory).Path

        if (-not (Test-Path $TargetDirectory)) {
            New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
        }

        $TargetDirectory = (Resolve-Path $TargetDirectory).Path

        $archiveParent = Split-Path -Path $ArchivePath -Parent
        if ([string]::IsNullOrWhiteSpace($archiveParent)) {
            throw "Нужно указать полный путь к архиву, например C:\temp\result.zip"
        }

        if (-not (Test-Path $archiveParent)) {
            New-Item -ItemType Directory -Path $archiveParent -Force | Out-Null
        }

        # Защита от рекурсивного копирования
        if ($TargetDirectory.StartsWith($SourceDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "TargetDirectory не должна находиться внутри SourceDirectory."
        }

        # При необходимости очистить целевую папку перед копированием
        if ($CleanTargetDirectory -and (Test-Path $TargetDirectory)) {
            Get-ChildItem -Path $TargetDirectory -Force | Remove-Item -Recurse -Force
        }

        # Копируем содержимое текущей директории, включая скрытые файлы
        Get-ChildItem -Path $SourceDirectory -Force | ForEach-Object {
            Copy-Item -Path $_.FullName -Destination $TargetDirectory -Recurse -Force
        }

        # Выполняем команду в целевой директории
        Push-Location $TargetDirectory
        try {
            Get-ChildItem -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force
        }
        finally {
            Pop-Location
        }

        # Если архив уже существует — удаляем
        if (Test-Path $ArchivePath) {
            Remove-Item -Path $ArchivePath -Force
        }

        # Создаём zip-архив
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $TargetDirectory,
            $ArchivePath,
            [System.IO.Compression.CompressionLevel]::Optimal,
            $false
        )

        Write-Host "Готово:"
        Write-Host "  Скопировано в: $TargetDirectory"
        Write-Host "  Архив создан:  $ArchivePath"
    }
    catch {
        Write-Error $_
    }
}