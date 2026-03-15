function Copy-CurrentProject {
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

        if ([string]::IsNullOrWhiteSpace($config.TargetDirectory)) {
            throw "TargetDirectory is not specified in config"
        }

        $TargetDirectory = if ([System.IO.Path]::IsPathRooted($config.TargetDirectory)) {
            $config.TargetDirectory
        }
        else {
            Join-Path $SourceDirectory $config.TargetDirectory
        }

        $CleanTargetDirectory = [bool]$config.CleanTargetDirectory
        $Exclude = @($config.Exclude)

        $SourceDirectory = Get-NormalizedDirectoryPath -Path $SourceDirectory
        $TargetDirectory = Get-NormalizedDirectoryPath -Path $TargetDirectory

        if ($TargetDirectory.Equals($SourceDirectory, [System.StringComparison]::OrdinalIgnoreCase)) {
            throw "TargetDirectory must not match SourceDirectory"
        }

        if (Test-PathInsideDirectory -ChildPath $TargetDirectory -ParentDirectory $SourceDirectory) {
            throw "TargetDirectory must not be inside SourceDirectory"
        }

        if (-not (Test-Path $TargetDirectory -PathType Container)) {
            if ($PSCmdlet.ShouldProcess($TargetDirectory, 'Create target directory')) {
                New-Item -ItemType Directory -Path $TargetDirectory -Force | Out-Null
            }
        }

        if ($CleanTargetDirectory -and (Test-Path $TargetDirectory -PathType Container)) {
            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory $TargetDirectory `
                -SourceDirectory $SourceDirectory

            if ($PSCmdlet.ShouldProcess($TargetDirectory, 'Clean target directory')) {
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

        [pscustomobject]@{
            SourceDirectory      = $SourceDirectory
            ConfigPath           = $ConfigPath
            TargetDirectory      = $TargetDirectory
            CleanTargetDirectory = $CleanTargetDirectory
            Exclude              = $Exclude
        }
    }
    catch {
        throw
    }
}
