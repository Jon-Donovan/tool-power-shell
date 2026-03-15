Describe 'Test-ArchivePathConflicts' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Test-ArchivePathConflicts.ps1"
        . "$PSScriptRoot\TestSetup.ps1"
    }

    BeforeEach {
        Mock Get-NormalizedFilePath {
            param([string]$Path)
            $Path
        }

        Mock Get-NormalizedDirectoryPath {
            param([string]$Path)
            $Path
        }

        Mock Test-PathInsideDirectory { $false }
        Mock Test-Path { $false }
    }

    Context 'Успешные сценарии' {
        It 'Не бросает исключение если ArchivePath безопасен и TargetDirectory не задан' {
            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Archives\build.zip' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Not -Throw
        }

        It 'Не бросает исключение если ArchivePath безопасен и TargetDirectory задан' {
            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Archives\build.zip' `
                    -SourceDirectory 'C:\Repo\Src' `
                    -TargetDirectory 'C:\Build\Out'
            } | Should -Not -Throw
        }

        It 'Не бросает исключение если ArchivePath существует как файл' {
            Mock Test-Path {
                param($Path, $PathType)

                if ($Path -eq 'C:\Archives\build.zip' -and $null -eq $PathType) {
                    return $true
                }

                if ($Path -eq 'C:\Archives\build.zip' -and $PathType -eq 'Container') {
                    return $false
                }

                return $false
            }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Archives\build.zip' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Not -Throw
        }
    }

    Context 'Проверка TargetDirectory' {
        It 'Бросает исключение если ArchivePath совпадает с TargetDirectory' {
            Mock Get-NormalizedFilePath { 'C:\Build\Out' }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\Build\Out') { return 'C:\Build\Out' }
                if ($Path -eq 'C:\Repo\Src')  { return 'C:\Repo\Src' }
                return $Path
            }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Build\Out' `
                    -SourceDirectory 'C:\Repo\Src' `
                    -TargetDirectory 'C:\Build\Out'
            } | Should -Throw 'ArchivePath must not match TargetDirectory'
        }

        It 'Бросает исключение если ArchivePath совпадает с TargetDirectory без учёта регистра' {
            Mock Get-NormalizedFilePath { 'C:\BUILD\OUT' }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'c:\build\out') { return 'c:\build\out' }
                if ($Path -eq 'C:\Repo\Src')  { return 'C:\Repo\Src' }
                return $Path
            }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\BUILD\OUT' `
                    -SourceDirectory 'C:\Repo\Src' `
                    -TargetDirectory 'c:\build\out'
            } | Should -Throw 'ArchivePath must not match TargetDirectory'
        }

        It 'Бросает исключение если ArchivePath находится внутри TargetDirectory' {
            Mock Get-NormalizedFilePath { 'C:\Build\Out\build.zip' }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\Build\Out') { return 'C:\Build\Out' }
                if ($Path -eq 'C:\Repo\Src')  { return 'C:\Repo\Src' }
                return $Path
            }

            Mock Test-PathInsideDirectory -ParameterFilter {
                $ChildPath -eq 'C:\Build\Out\build.zip' -and $ParentDirectory -eq 'C:\Build\Out'
            } { $true }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Build\Out\build.zip' `
                    -SourceDirectory 'C:\Repo\Src' `
                    -TargetDirectory 'C:\Build\Out'
            } | Should -Throw 'ArchivePath must not be inside TargetDirectory'
        }

        It 'Не обрабатывает TargetDirectory если он null' {
            Test-ArchivePathConflicts `
                -ArchivePath 'C:\Archives\build.zip' `
                -SourceDirectory 'C:\Repo\Src' `
                -TargetDirectory $null

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\Repo\Src'
            }
        }

        It 'Не обрабатывает TargetDirectory если он пустой или из пробелов' {
            Test-ArchivePathConflicts `
                -ArchivePath 'C:\Archives\build.zip' `
                -SourceDirectory 'C:\Repo\Src' `
                -TargetDirectory '   '

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\Repo\Src'
            }
        }
    }

    Context 'Проверка SourceDirectory' {
        It 'Бросает исключение если ArchivePath совпадает с SourceDirectory' {
            Mock Get-NormalizedFilePath { 'C:\Repo\Src' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo\Src' }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Repo\Src' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'ArchivePath must not match SourceDirectory'
        }

        It 'Бросает исключение если ArchivePath совпадает с SourceDirectory без учёта регистра' {
            Mock Get-NormalizedFilePath { 'C:\REPO\SRC' }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)
                if ($Path -eq 'c:\repo\src') { return 'c:\repo\src' }
                return $Path
            }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\REPO\SRC' `
                    -SourceDirectory 'c:\repo\src'
            } | Should -Throw 'ArchivePath must not match SourceDirectory'
        }

        It 'Бросает исключение если ArchivePath находится внутри SourceDirectory' {
            Mock Get-NormalizedFilePath { 'C:\Repo\Src\artifacts\build.zip' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo\Src' }

            Mock Test-PathInsideDirectory -ParameterFilter {
                $ChildPath -eq 'C:\Repo\Src\artifacts\build.zip' -and $ParentDirectory -eq 'C:\Repo\Src'
            } { $true }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Repo\Src\artifacts\build.zip' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'ArchivePath must not be inside SourceDirectory'
        }
    }

    Context 'Проверка что ArchivePath не директория' {
        It 'Бросает исключение если ArchivePath указывает на директорию' {
            Mock Test-Path {
                param($Path, $PathType)

                if ($Path -eq 'C:\Archives\build.zip' -and $null -eq $PathType) {
                    return $true
                }

                if ($Path -eq 'C:\Archives\build.zip' -and $PathType -eq 'Container') {
                    return $true
                }

                return $false
            }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Archives\build.zip' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'ArchivePath points to a directory instead of an archive file*'
        }

        It 'Не бросает исключение если ArchivePath не существует' {
            Mock Test-Path { $false }

            {
                Test-ArchivePathConflicts `
                    -ArchivePath 'C:\Archives\missing.zip' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Not -Throw
        }
    }

    Context 'Взаимодействие с зависимостями' {
        It 'Вызывает Get-NormalizedFilePath для ArchivePath' {
            Test-ArchivePathConflicts `
                -ArchivePath '.\build.zip' `
                -SourceDirectory '.\src'

            Should -Invoke Get-NormalizedFilePath -Times 1 -Exactly -ParameterFilter {
                $Path -eq '.\build.zip'
            }
        }

        It 'Вызывает Get-NormalizedDirectoryPath для SourceDirectory' {
            Test-ArchivePathConflicts `
                -ArchivePath '.\build.zip' `
                -SourceDirectory '.\src'

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -Exactly -ParameterFilter {
                $Path -eq '.\src'
            }
        }

        It 'Вызывает Get-NormalizedDirectoryPath для TargetDirectory если он задан' {
            Test-ArchivePathConflicts `
                -ArchivePath '.\build.zip' `
                -SourceDirectory '.\src' `
                -TargetDirectory '.\out'

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -Exactly -ParameterFilter {
                $Path -eq '.\out'
            }
        }

        It 'Передаёт в проверку TargetDirectory нормализованные пути' {
            Mock Get-NormalizedFilePath {
                param([string]$Path)
                if ($Path -eq '.\build.zip') { return 'C:\Archives\build.zip' }
                return $Path
            }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)
                if ($Path -eq '.\out') { return 'C:\Build\Out' }
                if ($Path -eq '.\src') { return 'C:\Repo\Src' }
                return $Path
            }

            Test-ArchivePathConflicts `
                -ArchivePath '.\build.zip' `
                -SourceDirectory '.\src' `
                -TargetDirectory '.\out'

            Should -Invoke Test-PathInsideDirectory -Times 1 -ParameterFilter {
                $ChildPath -eq 'C:\Archives\build.zip' -and $ParentDirectory -eq 'C:\Build\Out'
            }
        }

        It 'Передаёт в проверку SourceDirectory нормализованные пути' {
            Mock Get-NormalizedFilePath {
                param([string]$Path)
                if ($Path -eq '.\build.zip') { return 'C:\Archives\build.zip' }
                return $Path
            }

            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)
                if ($Path -eq '.\src') { return 'C:\Repo\Src' }
                return $Path
            }

            Test-ArchivePathConflicts `
                -ArchivePath '.\build.zip' `
                -SourceDirectory '.\src'

            Should -Invoke Test-PathInsideDirectory -Times 1 -ParameterFilter {
                $ChildPath -eq 'C:\Archives\build.zip' -and $ParentDirectory -eq 'C:\Repo\Src'
            }
        }

        It 'Проверяет существование ArchivePath перед проверкой что это директория' {
            Mock Test-Path {
                param($Path, $PathType)
                $false
            }

            Test-ArchivePathConflicts `
                -ArchivePath 'C:\Archives\build.zip' `
                -SourceDirectory 'C:\Repo\Src'

            Should -Invoke Test-Path -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\Archives\build.zip' -and $null -eq $PathType
            }

            Should -Invoke Test-Path -Times 0 -ParameterFilter {
                $Path -eq 'C:\Archives\build.zip' -and $PathType -eq 'Container'
            }
        }
    }
}
