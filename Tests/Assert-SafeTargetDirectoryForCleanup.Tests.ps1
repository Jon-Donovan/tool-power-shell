Describe 'Assert-SafeTargetDirectoryForCleanup' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Assert-SafeTargetDirectoryForCleanup.ps1"
        . "$PSScriptRoot\TestSetup.ps1"
    }

    BeforeEach {
        Mock Test-Path { $true }
        Mock Get-NormalizedDirectoryPath {
            param([string]$Path)
            $Path
        }
        Mock Test-PathInsideDirectory { $false }
    }

    Context 'Успешный сценарий' {
        It 'Не бросает исключение для безопасной директории' {
            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Build\Out' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Not -Throw
        }
    }

    Context 'Проверка существования и типа TargetDirectory' {
        It 'Бросает исключение если TargetDirectory не существует' {
            Mock Test-Path { $false }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Missing' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'TargetDirectory для очистки должна существовать и быть директорией*'
        }

        It 'Бросает исключение если TargetDirectory не директория' {
            Mock Test-Path { $false } -ParameterFilter {
                $Path -eq 'C:\Some\File.txt' -and $PathType -eq 'Container'
            }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Some\File.txt' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'TargetDirectory для очистки должна существовать и быть директорией*'
        }
    }

    Context 'Проверка корня диска' {
        It 'Бросает исключение если TargetDirectory это корень диска' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\') { return 'C:' }
                if ($Path -eq 'C:\Repo\Src') { return 'C:\Repo\Src' }

                return $Path
            }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'Очистка корня диска запрещена*'
        }

        It 'Бросает исключение без учёта регистра для корня диска' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'c:\') { return 'c:' }
                if ($Path -eq 'C:\Repo\Src') { return 'C:\Repo\Src' }

                return $Path
            }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'c:\' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'Очистка корня диска запрещена*'
        }
    }

    Context 'Проверка совпадения с SourceDirectory' {
        It 'Бросает исключение если TargetDirectory совпадает с SourceDirectory' {
            Mock Get-NormalizedDirectoryPath { 'C:\Repo\Src' }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Repo\Src' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'Очистка TargetDirectory запрещена, если она совпадает с SourceDirectory'
        }

        It 'Бросает исключение если TargetDirectory совпадает с SourceDirectory без учёта регистра' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\REPO\SRC') { return 'C:\REPO\SRC' }
                if ($Path -eq 'c:\repo\src') { return 'c:\repo\src' }

                return $Path
            }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\REPO\SRC' `
                    -SourceDirectory 'c:\repo\src'
            } | Should -Throw 'Очистка TargetDirectory запрещена, если она совпадает с SourceDirectory'
        }
    }

    Context 'Проверка вложенности в SourceDirectory' {
        It 'Бросает исключение если TargetDirectory находится внутри SourceDirectory' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\Repo\Src\Out') { return 'C:\Repo\Src\Out' }
                if ($Path -eq 'C:\Repo\Src') { return 'C:\Repo\Src' }

                return $Path
            }

            Mock Test-PathInsideDirectory { $true }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Repo\Src\Out' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Throw 'Очистка TargetDirectory запрещена, если она находится внутри SourceDirectory'
        }

        It 'Не бросает исключение если TargetDirectory не находится внутри SourceDirectory' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq 'C:\Build\Out') { return 'C:\Build\Out' }
                if ($Path -eq 'C:\Repo\Src') { return 'C:\Repo\Src' }

                return $Path
            }

            Mock Test-PathInsideDirectory { $false }

            {
                Assert-SafeTargetDirectoryForCleanup `
                    -TargetDirectory 'C:\Build\Out' `
                    -SourceDirectory 'C:\Repo\Src'
            } | Should -Not -Throw
        }
    }

    Context 'Взаимодействие с зависимостями' {
        It 'Вызывает Test-Path с PathType Container' {
            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory 'C:\Build\Out' `
                -SourceDirectory 'C:\Repo\Src'

            Should -Invoke Test-Path -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\Build\Out' -and $PathType -eq 'Container'
            }
        }

        It 'Вызывает Get-NormalizedDirectoryPath для TargetDirectory' {
            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory 'C:\Build\Out' `
                -SourceDirectory 'C:\Repo\Src'

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -ParameterFilter {
                $Path -eq 'C:\Build\Out'
            }
        }

        It 'Вызывает Get-NormalizedDirectoryPath для SourceDirectory' {
            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory 'C:\Build\Out' `
                -SourceDirectory 'C:\Repo\Src'

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -ParameterFilter {
                $Path -eq 'C:\Repo\Src'
            }
        }

        It 'Передаёт в Test-PathInsideDirectory нормализованные пути' {
            Mock Get-NormalizedDirectoryPath {
                param([string]$Path)

                if ($Path -eq '.\out') { return 'C:\Build\Out' }
                if ($Path -eq '.\src') { return 'C:\Repo\Src' }

                return $Path
            }

            Assert-SafeTargetDirectoryForCleanup `
                -TargetDirectory '.\out' `
                -SourceDirectory '.\src'

            Should -Invoke Test-PathInsideDirectory -Times 1 -Exactly -ParameterFilter {
                $ChildPath -eq 'C:\Build\Out' -and $ParentDirectory -eq 'C:\Repo\Src'
            }
        }
    }
}
