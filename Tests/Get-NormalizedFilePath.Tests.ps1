Describe 'Get-NormalizedFilePath' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Get-NormalizedFilePath.ps1"
        . "$PSScriptRoot\TestSetup.ps1"
    }

    Context 'Успешные сценарии' {
        It 'Возвращает абсолютный путь для относительного пути' {
            $relativePath = '.\test-file.txt'
            $expected = [System.IO.Path]::GetFullPath($relativePath)

            $result = Get-NormalizedFilePath -Path $relativePath

            $result | Should -Be $expected
        }

        It 'Возвращает нормализованный абсолютный путь для абсолютного пути' {
            $inputPath = [System.IO.Path]::Combine((Get-Location).Path, 'folder', '..', 'file.txt')
            $expected = [System.IO.Path]::GetFullPath($inputPath)

            $result = Get-NormalizedFilePath -Path $inputPath

            $result | Should -Be $expected
        }

        It 'Схлопывает сегменты dot и dotdot' {
            $inputPath = '.\folder\..\file.txt'
            $expected = [System.IO.Path]::GetFullPath($inputPath)

            $result = Get-NormalizedFilePath -Path $inputPath

            $result | Should -Be $expected
        }
    }

    Context 'Ошибочные сценарии' {
        It 'Бросает ошибку биндинга при пустой строке' {
            {
                Get-NormalizedFilePath -Path ''
            } | Should -Throw
        }

        It 'Бросает ошибку при null' {
            {
                Get-NormalizedFilePath -Path $null
            } | Should -Throw
        }
    }
}
