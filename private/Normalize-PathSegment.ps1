function Normalize-PathSegment {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Value
    )

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return $Value
    }

    $invalidFileNameChars = [System.IO.Path]::GetInvalidFileNameChars()
    $normalizedValue = $Value

    foreach ($invalidChar in $invalidFileNameChars) {
        $normalizedValue = $normalizedValue.Replace([string]$invalidChar, "-")
    }

    $normalizedValue = $normalizedValue.Trim()

    while ($normalizedValue.Contains("--")) {
        $normalizedValue = $normalizedValue.Replace("--", "-")
    }

    $normalizedValue = $normalizedValue.Trim('-', '.')

    return $normalizedValue
}