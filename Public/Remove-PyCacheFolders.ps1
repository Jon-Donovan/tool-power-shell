function Remove-PyCacheFolders {
    [CmdletBinding()]
    param (
        [string]$Path = "."
    )

    Get-ChildItem -Path $Path -Recurse -Directory -Filter "__pycache__" -ErrorAction SilentlyContinue |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

function Clear-PyCache {
    param (
        [string]$Path = "."
    )
    Remove-PyCacheFolders -Path $Path
}

# Set-Alias Clear-PyCache Remove-PyCacheFolders
Set-Alias Clear-PythonCache Remove-PyCacheFolders
