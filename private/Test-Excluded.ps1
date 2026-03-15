function Test-Excluded {
    [CmdletBinding()]
    param(
        [string]$RelativePath,
        [string]$Name,
        [string[]]$Patterns
    )

    $normalized = $RelativePath -replace '/', '\'

    foreach ($pattern in $Patterns) {
        if (
            $Name -like $pattern -or
            $normalized -like $pattern
        ) {
            return $true
        }
    }

    return $false
}
