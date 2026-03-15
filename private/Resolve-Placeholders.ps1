function Resolve-Placeholders {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $false)]
        [object[]]$PlaceHolders
    )

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return $Text
    }

    if ($null -eq $PlaceHolders -or $PlaceHolders.Count -eq 0) {
        return $Text
    }

    $result = $Text
    $now = Get-Date

    $SourceDirectory = $null

    if (Get-Variable -Name SourceDirectory -Scope Script -ErrorAction SilentlyContinue) {
        $SourceDirectory = (Get-Variable -Name SourceDirectory -Scope Script).Value
    } elseif (Get-Variable -Name SourceDirectory -Scope 1 -ErrorAction SilentlyContinue) {
        $SourceDirectory = (Get-Variable -Name SourceDirectory -Scope 1).Value
    } elseif (Get-Variable -Name SourceDirectory -ErrorAction SilentlyContinue) {
        $SourceDirectory = (Get-Variable -Name SourceDirectory).Value
    }

    foreach ($placeHolder in $PlaceHolders) {
        if ($null -eq $placeHolder) {
            continue
        }

        $name = [string]$placeHolder.name
        $type = [string]$placeHolder.type
        $args = $placeHolder.arg

        if ([string]::IsNullOrWhiteSpace($name)) {
            throw "У плейсхолдера отсутствует name"
        }

        if ([string]::IsNullOrWhiteSpace($type)) {
            throw "У плейсхолдера '$name' отсутствует type"
        }

        $value = switch ($type.ToLowerInvariant()) {
            "date" {
                $format = if ($args -and $args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    [string]$args[0]
                } else {
                    "yyyy-MM-dd"
                }

                $now.ToString($format)
            }

            "time" {
                $format = if ($args -and $args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    [string]$args[0]
                } else {
                    "HH-mm-ss"
                }

                $now.ToString($format)
            }

            "datetime" {
                $format = if ($args -and $args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    [string]$args[0]
                } else {
                    "yyyy-MM-dd_HH-mm-ss"
                }

                $now.ToString($format)
            }

            "timestamp" {
                $format = if ($args -and $args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    [string]$args[0]
                } else {
                    "yyyyMMddHHmmss"
                }

                $now.ToString($format)
            }

            "projectname" {
                if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
                    throw "Для плейсхолдера '$name' с type 'projectname' не определён SourceDirectory"
                }

                Split-Path $SourceDirectory -Leaf
            }

            "guid" {
                $format = if ($args -and $args.Count -gt 0 -and -not [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    [string]$args[0]
                } else {
                    "N"
                }

                [guid]::NewGuid().ToString($format)
            }

            "env" {
                if ($null -eq $args -or $args.Count -eq 0 -or [string]::IsNullOrWhiteSpace([string]$args[0])) {
                    throw "Для плейсхолдера '$name' с type 'env' нужно указать имя переменной окружения в arg[0]"
                }

                $environmentVariableName = [string]$args[0]
                $environmentVariableValue = [Environment]::GetEnvironmentVariable($environmentVariableName)

                if ($null -eq $environmentVariableValue) {
                    throw "Переменная окружения '$environmentVariableName' для плейсхолдера '$name' не найдена"
                }

                $environmentVariableValue
            }

            "username" {
                $env:USERNAME
            }

            "machine" {
                $env:COMPUTERNAME
            }

            "git-branch" {
                if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
                    throw "Для плейсхолдера '$name' с type 'git-branch' не определён SourceDirectory"
                }

                $gitBranch = & git -C $SourceDirectory rev-parse --abbrev-ref HEAD 2>$null

                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitBranch)) {
                    throw "Не удалось определить git branch для плейсхолдера '$name'"
                }

                $gitBranch.Trim()
            }

            "git-commit-short" {
                if ([string]::IsNullOrWhiteSpace($SourceDirectory)) {
                    throw "Для плейсхолдера '$name' с type 'git-commit-short' не определён SourceDirectory"
                }

                $gitCommitShort = & git -C $SourceDirectory rev-parse --short HEAD 2>$null

                if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($gitCommitShort)) {
                    throw "Не удалось определить git commit для плейсхолдера '$name'"
                }

                $gitCommitShort.Trim()
            }

            default {
                throw "Неизвестный type у плейсхолдера '$name': '$type'"
            }
        }

        $value = Normalize-PathSegment -Value ([string]$value)

        $pattern = [regex]::Escape("{${name}}")
        $result = [regex]::Replace($result, $pattern, [System.Text.RegularExpressions.MatchEvaluator]{ param($m) $value })
    }

    return $result
}