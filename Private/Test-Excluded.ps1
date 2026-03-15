function Test-Excluded {
    [CmdletBinding()]
    param(
        [string]$RelativePath,
        [string[]]$Patterns
    )

    if (-not $Patterns) {
        Write-Debug "Patterns пустой — возвращаем false"
        return $false
    }

    $normalized = $RelativePath -replace '/', '\'
    # добавляем ведущий .\ если его нет
    $normalized = $normalized -replace '^[\\]+', ''
    $normalized = "\$normalized"

    foreach ($pattern in $Patterns) {

        if ($normalized -like $pattern) {
            Write-Verbose "Совпадение по пути: $normalized  [$pattern]"
            return $true
        }
    }

    Write-Verbose "Совпадений нет $normalized"
    return $false
}
