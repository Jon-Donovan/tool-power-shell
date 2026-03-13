function Pack-CurrentDir {
    param(
        [Parameter(Mandatory=$true)][string]$TargetDirectory,
        [Parameter(Mandatory=$true)][string]$ArchivePath
    )

    $source = (Get-Location).Path

    Get-ChildItem -Force | Copy-Item -Destination $TargetDirectory -Recurse -Force

    Push-Location $TargetDirectory
    Get-ChildItem -Recurse -Directory -Filter '__pycache__' | Remove-Item -Recurse -Force
    Pop-Location

    Compress-Archive -Path "$TargetDirectory\*" -DestinationPath $ArchivePath -Force
}