$moduleRoot = Resolve-Path "$PSScriptRoot\.."

# Загружаем Public функции
Get-ChildItem "$moduleRoot\Public\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}

# Загружаем Private функции
Get-ChildItem "$moduleRoot\Private\*.ps1" -Recurse | ForEach-Object {
    . $_.FullName
}
