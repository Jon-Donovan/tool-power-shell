Describe 'Test-PathInsideDirectory' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Test-PathInsideDirectory.ps1"
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
    }

    Context 'Успешные сценарии' {
        It 'Возвращает true если файл находится внутри директории' {
            Mock Get-NormalizedFilePath { 'C:\Repo\Sub\File.txt' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeTrue
        }

        It 'Возвращает true если путь совпадает с директорией' {
            Mock Get-NormalizedFilePath { 'C:\Repo' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeTrue
        }

        It 'Возвращает true без учёта регистра' {
            Mock Get-NormalizedFilePath { 'c:\repo\sub\file.txt' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeTrue
        }

        It 'Корректно работает если child уже оканчивается обратным слешем' {
            Mock Get-NormalizedFilePath { 'C:\Repo\Sub\' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeTrue
        }

        It 'Корректно работает если parent уже оканчивается обратным слешем' {
            Mock Get-NormalizedFilePath { 'C:\Repo\Sub\File.txt' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeTrue
        }
    }

    Context 'Неуспешные сценарии' {
        It 'Возвращает false если файл находится вне директории' {
            Mock Get-NormalizedFilePath { 'C:\Other\File.txt' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeFalse
        }

        It 'Возвращает false для похожего префикса но другой директории' {
            Mock Get-NormalizedFilePath { 'C:\Repository\File.txt' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeFalse
        }

        It 'Возвращает false если child короче parent и не совпадает с ним' {
            Mock Get-NormalizedFilePath { 'C:\Rep' }
            Mock Get-NormalizedDirectoryPath { 'C:\Repo' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'ignored-child' `
                -ParentDirectory 'ignored-parent'

            $result | Should -BeFalse
        }
    }

    Context 'Взаимодействие с зависимостями' {
        It 'Вызывает Get-NormalizedFilePath один раз с ChildPath' {
            Test-PathInsideDirectory `
                -ChildPath 'C:\A\File.txt' `
                -ParentDirectory 'C:\A'

            Should -Invoke Get-NormalizedFilePath -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\A\File.txt'
            }
        }

        It 'Вызывает Get-NormalizedDirectoryPath один раз с ParentDirectory' {
            Test-PathInsideDirectory `
                -ChildPath 'C:\A\File.txt' `
                -ParentDirectory 'C:\A'

            Should -Invoke Get-NormalizedDirectoryPath -Times 1 -Exactly -ParameterFilter {
                $Path -eq 'C:\A'
            }
        }

        It 'Использует нормализованные значения а не исходные аргументы' {
            Mock Get-NormalizedFilePath { 'D:\Normalized\File.txt' }
            Mock Get-NormalizedDirectoryPath { 'D:\Normalized' }

            $result = Test-PathInsideDirectory `
                -ChildPath 'C:\Raw\File.txt' `
                -ParentDirectory 'C:\Raw'

            $result | Should -BeTrue
        }
    }
}
