Describe 'Get-NormalizedDirectoryPath' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Get-NormalizedDirectoryPath.ps1"
        . "$PSScriptRoot\TestSetup.ps1"
    }

    Context 'Успешные сценарии' {
        It 'Возвращает абсолютный путь для относительной директории' {
            $inputPath = '.\test-dir'
            $expected = [System.IO.Path]::GetFullPath($inputPath).TrimEnd('\')

            $result = Get-NormalizedDirectoryPath -Path $inputPath

            $result | Should -Be $expected
        }

        It 'Возвращает нормализованный абсолютный путь' {
            $inputPath = [System.IO.Path]::Combine((Get-Location).Path, 'folder', '..', 'dir')
            $expected = [System.IO.Path]::GetFullPath($inputPath).TrimEnd('\')

            $result = Get-NormalizedDirectoryPath -Path $inputPath

            $result | Should -Be $expected
        }

        It 'Схлопывает сегменты dot и dotdot' {
            $inputPath = '.\folder\..\dir'
            $expected = [System.IO.Path]::GetFullPath($inputPath).TrimEnd('\')

            $result = Get-NormalizedDirectoryPath -Path $inputPath

            $result | Should -Be $expected
        }

        It 'Убирает завершающий обратный слеш' {
            $base = Join-Path (Get-Location).Path 'test-dir'
            $inputPath = $base + '\'

            $result = Get-NormalizedDirectoryPath -Path $inputPath

            $result | Should -Be ([System.IO.Path]::GetFullPath($base).TrimEnd('\'))
            $result.EndsWith('\') | Should -BeFalse
        }

        It 'Не меняет путь без завершающего обратного слеша' {
            $inputPath = Join-Path (Get-Location).Path 'test-dir'
            $expected = [System.IO.Path]::GetFullPath($inputPath).TrimEnd('\')

            $result = Get-NormalizedDirectoryPath -Path $inputPath

            $result | Should -Be $expected
        }
    }

    Context 'Ошибочные сценарии' {
        It 'Бросает ошибку биндинга при пустой строке' {
            {
                Get-NormalizedDirectoryPath -Path ''
            } | Should -Throw
        }

        It 'Бросает ошибку биндинга при null' {
            {
                Get-NormalizedDirectoryPath -Path $null
            } | Should -Throw
        }
    }

    Context 'Граничные случаи' {
        It 'Корректно обрабатывает корень диска' {
            $root = [System.IO.Path]::GetPathRoot((Get-Location).Path)

            $result = Get-NormalizedDirectoryPath -Path $root

            $result | Should -Be $root.TrimEnd('\')
        }
    }
}
