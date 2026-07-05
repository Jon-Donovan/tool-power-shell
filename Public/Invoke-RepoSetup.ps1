function Invoke-RepoSetup {
    [CmdletBinding()]
    param(
        [string]$ConfigPath = (Join-Path (Split-Path $PSScriptRoot -Parent) "config.json")
    )

    if (-not (Test-Path $ConfigPath)) {
        throw "Конфиг не найден: $ConfigPath"
    }

    $config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    $scriptPath = $config.InvokeRepoSetup.SetupRepoScriptPath

    if (-not $scriptPath) {
        throw "В конфиге не задан SetupRepoScriptPath"
    }

    if (-not (Test-Path $scriptPath)) {
        throw "Файл не найден: $scriptPath"
    }

    & python $scriptPath

    if ($LASTEXITCODE -ne 0) {
        throw "Скрипт завершился с кодом $LASTEXITCODE"
    }
}
