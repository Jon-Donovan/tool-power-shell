Describe 'Normalize-PathSegment' {
    BeforeAll {
        # Подключи файл с функцией
        # . "$PSScriptRoot\..\Private\Normalize-PathSegment.ps1"
        . "$PSScriptRoot\TestSetup.ps1"
    }

    Context 'Базовое поведение' {
        It 'Возвращает строку без изменений если она уже валидна' {
            $result = Normalize-PathSegment -Value 'My_File-Name.2026'

            $result | Should -Be 'My_File-Name.2026'
        }

        It 'Возвращает строку из пробелов как есть' {
            $result = Normalize-PathSegment -Value '   '

            $result | Should -Be '   '
        }

        It 'Бросает ошибку биндинга для пустой строки' {
            {
                Normalize-PathSegment -Value ''
            } | Should -Throw
        }

        It 'Бросает ошибку биндинга для null' {
            {
                Normalize-PathSegment -Value $null
            } | Should -Throw
        }
    }

    Context 'Замена недопустимых символов' {
        It 'Заменяет недопустимые символы имени файла на дефис' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = 'A' + ($invalidChars[0]) + 'B'
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be 'A-B'
        }

        It 'Заменяет несколько недопустимых символов подряд и схлопывает дефисы' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = 'A' + ($invalidChars[0]) + ($invalidChars[0]) + 'B'
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be 'A-B'
        }

        It 'Корректно обрабатывает смесь недопустимых символов и пробелов' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = '  A' + ($invalidChars[0]) + '  B  '
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be 'A-  B'
        }
    }

    Context 'Схлопывание дефисов' {
        It 'Схлопывает двойные дефисы в один' {
            $result = Normalize-PathSegment -Value 'A--B'

            $result | Should -Be 'A-B'
        }

        It 'Схлопывает много подряд идущих дефисов в один' {
            $result = Normalize-PathSegment -Value 'A-----B'

            $result | Should -Be 'A-B'
        }

        It 'Схлопывает дефисы появившиеся после замены недопустимых символов' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = 'A-' + ($invalidChars[0]) + '-B'
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be 'A-B'
        }
    }

    Context 'Обрезка по краям' {
        It 'Убирает пробелы по краям' {
            $result = Normalize-PathSegment -Value '  abc  '

            $result | Should -Be 'abc'
        }

        It 'Убирает дефисы по краям' {
            $result = Normalize-PathSegment -Value '--abc--'

            $result | Should -Be 'abc'
        }

        It 'Убирает точки по краям' {
            $result = Normalize-PathSegment -Value '..abc..'

            $result | Should -Be 'abc'
        }

        It 'Убирает и точки и дефисы по краям' {
            $result = Normalize-PathSegment -Value '.-abc-.'

            $result | Should -Be 'abc'
        }

        It 'Не удаляет точки внутри строки' {
            $result = Normalize-PathSegment -Value 'ab.cd.ef'

            $result | Should -Be 'ab.cd.ef'
        }

        It 'Не удаляет одиночный дефис внутри строки' {
            $result = Normalize-PathSegment -Value 'ab-cd'

            $result | Should -Be 'ab-cd'
        }
    }

    Context 'Граничные случаи' {
        It 'Может вернуть пустую строку если после нормализации ничего не осталось' {
            $result = Normalize-PathSegment -Value '---...---'

            $result | Should -Be ''
        }

        It 'Возвращает пустую строку если строка состоит только из недопустимых символов' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = -join ($invalidChars | Select-Object -First 3)
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be ''
        }

        It 'Корректно нормализует сложную строку' {
            $invalidChars = [System.IO.Path]::GetInvalidFileNameChars() |
                Where-Object { $_ -notin @([char]0) }

            $sample = '  ..Report' + $invalidChars[0] + $invalidChars[0] + '2026..  '
            $result = Normalize-PathSegment -Value $sample

            $result | Should -Be 'Report-2026'
        }
    }
}
