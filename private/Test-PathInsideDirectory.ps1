function Test-PathInsideDirectory {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ChildPath,

        [Parameter(Mandatory)]
        [string]$ParentDirectory
    )

    $child = Get-NormalizedFilePath -Path $ChildPath
    $parent = Get-NormalizedDirectoryPath -Path $ParentDirectory

    $parentWithSeparator = $parent + '\'
    $childWithSeparator = $child.TrimEnd('\') + '\'

    return $childWithSeparator.StartsWith(
        $parentWithSeparator,
        [System.StringComparison]::OrdinalIgnoreCase
    )
}
