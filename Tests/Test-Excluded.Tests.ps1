# Requires -Version 5.1
# Requires -Modules Pester

Set-StrictMode -Version Latest

Describe 'Test-Excluded' {
    BeforeAll {
        . "$PSScriptRoot\TestSetup.ps1"
    }

    Context 'Когда список Patterns пустой или не совпадает' {
        It 'Возвращает $false при пустом списке паттернов' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @() | Should -Be $false
        }

        It 'Возвращает $false, если ни Name, ни RelativePath не совпали' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('bin*', '*.log', 'obj\*') | Should -Be $false
        }
    }

    Context 'Когда совпадение идёт по Name' {
        It 'Возвращает $true, если Name совпадает с шаблоном' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('*.txt') | Should -Be $true
        }

        It 'Возвращает $true, если один из нескольких шаблонов совпал по Name' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('*.log', '*.txt', '*.json') | Should -Be $true
        }
    }

    Context 'Когда совпадение идёт по RelativePath' {
        It 'Возвращает $true, если RelativePath совпадает с шаблоном' {
            Test-Excluded -RelativePath 'src\app\file.txt' -Patterns @('\src\app\*') | Should -Be $true
        }

        It 'Нормализует / в \ и сравнивает корректно' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('\src\app\*') | Should -Be $true
        }

        It 'Возвращает $true, если путь совпал, даже когда Name не совпадает' {
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns @('\logs\*', '*.txt') | Should -Be $true
        }

        It 'Не совпадает если шаблон без wildcard' {
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns @('logs', '*.txt') | Should -Be $false
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns @('app', '*.txt') | Should -Be $false
        }

        It 'Совпадает при частичном совпадении пути' {
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns @('*logs*') | Should -Be $true
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns @('*app*') | Should -Be $true
        }

        It 'Совпадение по имени и пути работает корректно' {
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns '*.bin' | Should -Be $true
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns '\logs\*' | Should -Be $true
            Test-Excluded -RelativePath 'logs/app/file.bin' -Patterns '*.txt' | Should -Be $false
        }
    }

    Context 'Пограничные случаи' {
        It 'Возвращает $false, если Patterns = $null' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns $null | Should -Be $false
        }

        It 'Корректно работает с точным совпадением пути' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('\src\app\file.txt') | Should -Be $true
        }

        It 'Корректно работает с точным совпадением имени' {
            Test-Excluded -RelativePath 'src/app/file.txt' -Patterns @('*\file.txt') | Should -Be $true
        }
    }
}
