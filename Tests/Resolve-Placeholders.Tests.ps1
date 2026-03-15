# Requires -Version 5.1
# Requires -Modules Pester

Set-StrictMode -Version Latest

Describe 'Resolve-Placeholders' {
    BeforeAll {
        # Подключите файл с вашей функцией
        . "$PSScriptRoot\TestSetup.ps1"

#         # Заглушка зависимости, если в боевом коде она не импортируется отдельно
#         function Normalize-PathSegment {
#             param(
#                 [Parameter(Mandatory)]
#                 [string]$Value
#             )
#             return $Value
#         }
    }

    BeforeEach {
        # Чистим возможные следы прошлых тестов
        Remove-Variable -Name SourceDirectory -Scope Script -ErrorAction SilentlyContinue
        Remove-Variable -Name SourceDirectory -Scope Global -ErrorAction SilentlyContinue
        Remove-Item Env:TEST_PLACEHOLDER_VAR -ErrorAction SilentlyContinue
        Remove-Item Function:\git -ErrorAction SilentlyContinue

        # Фиксируем дату
        Mock Get-Date {
            [datetime]'2026-03-16T14:05:06'
        }

        # По умолчанию Normalize-PathSegment ничего не меняет
        Mock Normalize-PathSegment {
            param([string]$Value)
            $Value
        }
    }

    Context 'Базовое поведение' {
        It 'Возвращает исходный текст если Text пустая строка' {
            $result = Resolve-Placeholders -Text '' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be ''
        }

        It 'Возвращает исходный текст если Text состоит из пробелов' {
            $result = Resolve-Placeholders -Text '   ' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be '   '
        }

        It 'Возвращает исходный текст если PlaceHolders = $null' {
            $result = Resolve-Placeholders -Text 'abc' -PlaceHolders $null
            $result | Should -Be 'abc'
        }

        It 'Возвращает исходный текст если PlaceHolders пустой массив' {
            $result = Resolve-Placeholders -Text 'abc' -PlaceHolders @()
            $result | Should -Be 'abc'
        }

        It 'Пропускает null-элементы в массиве плейсхолдеров' {
            $result = Resolve-Placeholders -Text 'X{d}Y' -PlaceHolders @(
                $null,
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be 'X2026-03-16Y'
        }
    }

    Context 'Валидация name и type' {
        It 'Бросает исключение если отсутствует name' {
            {
                Resolve-Placeholders -Text '{x}' -PlaceHolders @(
                    [pscustomobject]@{ name = ''; type = 'date'; arg = @() }
                )
            } | Should -Throw "*отсутствует name*"
        }

        It 'Бросает исключение если отсутствует type' {
            {
                Resolve-Placeholders -Text '{x}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'x'; type = ''; arg = @() }
                )
            } | Should -Throw "*отсутствует type*"
        }
    }

    Context 'Тип date' {
        It 'Подставляет date в формате по умолчанию' {
            $result = Resolve-Placeholders -Text 'build-{d}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be 'build-2026-03-16'
        }

        It 'Подставляет date в пользовательском формате' {
            $result = Resolve-Placeholders -Text 'build-{d}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @('dd.MM.yyyy') }
            )

            $result | Should -Be 'build-16.03.2026'
        }
    }

    Context 'Тип time' {
        It 'Подставляет time в формате по умолчанию' {
            $result = Resolve-Placeholders -Text 'build-{t}' -PlaceHolders @(
                [pscustomobject]@{ name = 't'; type = 'time'; arg = @() }
            )

            $result | Should -Be 'build-14-05-06'
        }

        It 'Подставляет time в пользовательском формате' {
            $result = Resolve-Placeholders -Text 'build-{t}' -PlaceHolders @(
                [pscustomobject]@{ name = 't'; type = 'time'; arg = @('HH:mm') }
            )

            $result | Should -Be 'build-14:05'
        }
    }

    Context 'Тип datetime' {
        It 'Подставляет datetime в формате по умолчанию' {
            $result = Resolve-Placeholders -Text 'build-{dt}' -PlaceHolders @(
                [pscustomobject]@{ name = 'dt'; type = 'datetime'; arg = @() }
            )

            $result | Should -Be 'build-2026-03-16_14-05-06'
        }

        It 'Подставляет datetime в пользовательском формате' {
            $result = Resolve-Placeholders -Text 'build-{dt}' -PlaceHolders @(
                [pscustomobject]@{ name = 'dt'; type = 'datetime'; arg = @('yyyyMMdd-HHmm') }
            )

            $result | Should -Be 'build-20260316-1405'
        }
    }

    Context 'Тип timestamp' {
        It 'Подставляет timestamp в формате по умолчанию' {
            $result = Resolve-Placeholders -Text 'build-{ts}' -PlaceHolders @(
                [pscustomobject]@{ name = 'ts'; type = 'timestamp'; arg = @() }
            )

            $result | Should -Be 'build-20260316140506'
        }

        It 'Подставляет timestamp в пользовательском формате' {
            $result = Resolve-Placeholders -Text 'build-{ts}' -PlaceHolders @(
                [pscustomobject]@{ name = 'ts'; type = 'timestamp'; arg = @('yyyy-MM') }
            )

            $result | Should -Be 'build-2026-03'
        }
    }

    Context 'Тип projectname и поиск SourceDirectory' {
        It 'Берёт имя проекта из SourceDirectory в Script scope' {
            $script:SourceDirectory = 'C:\Repo\MyProject'

            $result = Resolve-Placeholders -Text '{p}' -PlaceHolders @(
                [pscustomobject]@{ name = 'p'; type = 'projectname'; arg = @() }
            )

            $result | Should -Be 'MyProject'
        }

        It 'Берёт имя проекта из SourceDirectory в Scope 1' {
            function Invoke-TestScope1 {
                $SourceDirectory = 'C:\Repo\Scope1Project'
                Resolve-Placeholders -Text '{p}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'p'; type = 'projectname'; arg = @() }
                )
            }

            $result = Invoke-TestScope1
            $result | Should -Be 'Scope1Project'
        }

        It 'Берёт имя проекта из текущей области если Script и Scope1 не заданы' {
            $SourceDirectory = 'C:\Repo\GlobalProject'

            $result = Resolve-Placeholders -Text '{p}' -PlaceHolders @(
                [pscustomobject]@{ name = 'p'; type = 'projectname'; arg = @() }
            )

            $result | Should -Be 'GlobalProject'
        }

        It 'Бросает исключение если SourceDirectory не определён' {
            {
                Resolve-Placeholders -Text '{p}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'p'; type = 'projectname'; arg = @() }
                )
            } | Should -Throw "*не определён SourceDirectory*"
        }
    }

    Context 'Тип guid' {
        It 'Подставляет guid в формате по умолчанию N' {
            $result = Resolve-Placeholders -Text '{g}' -PlaceHolders @(
                [pscustomobject]@{ name = 'g'; type = 'guid'; arg = @() }
            )

            $result | Should -Match '^[0-9a-fA-F]{32}$'
        }

        It 'Подставляет guid в пользовательском формате D' {
            $result = Resolve-Placeholders -Text '{g}' -PlaceHolders @(
                [pscustomobject]@{ name = 'g'; type = 'guid'; arg = @('D') }
            )

            $result | Should -Match '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$'
        }
    }

    Context 'Тип env' {
        It 'Подставляет значение переменной окружения' {
            $env:TEST_PLACEHOLDER_VAR = 'ENV_VALUE'

            $result = Resolve-Placeholders -Text 'x-{e}-y' -PlaceHolders @(
                [pscustomobject]@{ name = 'e'; type = 'env'; arg = @('TEST_PLACEHOLDER_VAR') }
            )

            $result | Should -Be 'x-ENV_VALUE-y'
        }

        It 'Бросает исключение если arg отсутствует' {
            {
                Resolve-Placeholders -Text '{e}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'e'; type = 'env'; arg = @() }
                )
            } | Should -Throw "*нужно указать имя переменной окружения*"
        }

        It 'Бросает исключение если arg[0] пустой' {
            {
                Resolve-Placeholders -Text '{e}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'e'; type = 'env'; arg = @('') }
                )
            } | Should -Throw "*нужно указать имя переменной окружения*"
        }

        It 'Бросает исключение если переменная окружения не найдена' {
            {
                Resolve-Placeholders -Text '{e}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'e'; type = 'env'; arg = @('NO_SUCH_ENV_12345') }
                )
            } | Should -Throw "*не найдена*"
        }
    }

    Context 'Типы username и machine' {
        It 'Подставляет username' {
            $expected = $env:USERNAME

            $result = Resolve-Placeholders -Text '{u}' -PlaceHolders @(
                [pscustomobject]@{ name = 'u'; type = 'username'; arg = @() }
            )

            $result | Should -Be $expected
        }

        It 'Подставляет machine' {
            $expected = $env:COMPUTERNAME

            $result = Resolve-Placeholders -Text '{m}' -PlaceHolders @(
                [pscustomobject]@{ name = 'm'; type = 'machine'; arg = @() }
            )

            $result | Should -Be $expected
        }
    }

    Context 'Тип git-branch' {
        BeforeEach {
            $script:SourceDirectory = 'C:\Repo\MyProject'
        }

        It 'Возвращает имя ветки git' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                'feature/test-branch'
            }

            $result = Resolve-Placeholders -Text '{b}' -PlaceHolders @(
                [pscustomobject]@{ name = 'b'; type = 'git-branch'; arg = @() }
            )

            $result | Should -Be 'feature/test-branch'
        }

        It 'Обрезает пробелы у результата git' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                '  feature/trim-me  '
            }

            $result = Resolve-Placeholders -Text '{b}' -PlaceHolders @(
                [pscustomobject]@{ name = 'b'; type = 'git-branch'; arg = @() }
            )

            $result | Should -Be 'feature/trim-me'
        }

        It 'Бросает исключение если SourceDirectory не определён' {
            Remove-Variable -Name SourceDirectory -Scope Script -ErrorAction SilentlyContinue

            {
                Resolve-Placeholders -Text '{b}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'b'; type = 'git-branch'; arg = @() }
                )
            } | Should -Throw "*не определён SourceDirectory*"
        }

        It 'Бросает исключение если git завершился с ошибкой' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 1
                ''
            }

            {
                Resolve-Placeholders -Text '{b}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'b'; type = 'git-branch'; arg = @() }
                )
            } | Should -Throw "*Не удалось определить git branch*"
        }

        It 'Бросает исключение если git вернул пустую строку' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                ''
            }

            {
                Resolve-Placeholders -Text '{b}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'b'; type = 'git-branch'; arg = @() }
                )
            } | Should -Throw "*Не удалось определить git branch*"
        }
    }

    Context 'Тип git-commit-short' {
        BeforeEach {
            $script:SourceDirectory = 'C:\Repo\MyProject'
        }

        It 'Возвращает короткий commit hash' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                'abc1234'
            }

            $result = Resolve-Placeholders -Text '{c}' -PlaceHolders @(
                [pscustomobject]@{ name = 'c'; type = 'git-commit-short'; arg = @() }
            )

            $result | Should -Be 'abc1234'
        }

        It 'Обрезает пробелы у commit hash' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                '  abc1234  '
            }

            $result = Resolve-Placeholders -Text '{c}' -PlaceHolders @(
                [pscustomobject]@{ name = 'c'; type = 'git-commit-short'; arg = @() }
            )

            $result | Should -Be 'abc1234'
        }

        It 'Бросает исключение если SourceDirectory не определён' {
            Remove-Variable -Name SourceDirectory -Scope Script -ErrorAction SilentlyContinue

            {
                Resolve-Placeholders -Text '{c}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'c'; type = 'git-commit-short'; arg = @() }
                )
            } | Should -Throw "*не определён SourceDirectory*"
        }

        It 'Бросает исключение если git завершился с ошибкой' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 1
                ''
            }

            {
                Resolve-Placeholders -Text '{c}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'c'; type = 'git-commit-short'; arg = @() }
                )
            } | Should -Throw "*Не удалось определить git commit*"
        }

        It 'Бросает исключение если git вернул пустую строку' {
            function git {
                param(
                    [Parameter(ValueFromRemainingArguments = $true)]
                    $Args
                )
                $global:LASTEXITCODE = 0
                ''
            }

            {
                Resolve-Placeholders -Text '{c}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'c'; type = 'git-commit-short'; arg = @() }
                )
            } | Should -Throw "*Не удалось определить git commit*"
        }
    }

    Context 'Неизвестный type' {
        It 'Бросает исключение для неизвестного типа' {
            {
                Resolve-Placeholders -Text '{x}' -PlaceHolders @(
                    [pscustomobject]@{ name = 'x'; type = 'something-unknown'; arg = @() }
                )
            } | Should -Throw "*Неизвестный type*"
        }
    }

    Context 'Замена в тексте' {
        It 'Заменяет несколько разных плейсхолдеров' {
            $env:TEST_PLACEHOLDER_VAR = 'ENV_VALUE'
            $script:SourceDirectory = 'C:\Repo\MyProject'

            $result = Resolve-Placeholders -Text '{d}_{p}_{e}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
                [pscustomobject]@{ name = 'p'; type = 'projectname'; arg = @() }
                [pscustomobject]@{ name = 'e'; type = 'env'; arg = @('TEST_PLACEHOLDER_VAR') }
            )

            $result | Should -Be '2026-03-16_MyProject_ENV_VALUE'
        }

        It 'Заменяет несколько одинаковых вхождений одного плейсхолдера' {
            $result = Resolve-Placeholders -Text '{d}__{d}__{d}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be '2026-03-16__2026-03-16__2026-03-16'
        }

        It 'Не меняет текст если в нём нет соответствующего плейсхолдера' {
            $result = Resolve-Placeholders -Text 'plain-text' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @() }
            )

            $result | Should -Be 'plain-text'
        }

        It 'Корректно обрабатывает спецсимволы в имени плейсхолдера через regex escape' {
            $result = Resolve-Placeholders -Text 'x-{a.b}-y' -PlaceHolders @(
                [pscustomobject]@{ name = 'a.b'; type = 'date'; arg = @('yyyy') }
            )

            $result | Should -Be 'x-2026-y'
        }
    }

    Context 'Normalize-PathSegment' {
        It 'Вызывает Normalize-PathSegment для вычисленного значения' {
            Mock Normalize-PathSegment {
                param([string]$Value)
                "normalized:$Value"
            } -Verifiable

            $result = Resolve-Placeholders -Text '{d}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'date'; arg = @('yyyy') }
            )

            $result | Should -Be 'normalized:2026'
            Should -Invoke Normalize-PathSegment -Times 1 -Exactly
        }

        It 'Использует нормализованное значение при замене' {
            Mock Normalize-PathSegment {
                param([string]$Value)
                $Value -replace ':', '_'
            }

            $result = Resolve-Placeholders -Text '{t}' -PlaceHolders @(
                [pscustomobject]@{ name = 't'; type = 'time'; arg = @('HH:mm:ss') }
            )

            $result | Should -Be '14_05_06'
        }
    }

    Context 'Регистронезависимость type' {
        It 'Обрабатывает type без учёта регистра' {
            $result = Resolve-Placeholders -Text '{d}' -PlaceHolders @(
                [pscustomobject]@{ name = 'd'; type = 'DaTe'; arg = @('yyyy') }
            )

            $result | Should -Be '2026'
        }
    }
}
