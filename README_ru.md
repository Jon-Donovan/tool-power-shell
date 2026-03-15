
# tool-power-shell

Модуль PowerShell для упаковки или копирования текущего проекта на основании конфигурационного файла.

Модуль предоставляет две публичные функции:

- Compress-CurrentProject
- Copy-CurrentProject

Поведение определяется файлом `.compress.config.json`, расположенным в корне проекта.

---

## Установка

### Локальная установка модуля

Скопируйте каталог модуля в один из путей модулей PowerShell.

Пример для Windows:

    $HOME\Documents\PowerShell\Modules\tool-power-shell

После этого импортируйте модуль:

    Import-Module tool-power-shell

Проверить установку:

    Get-Command -Module tool-power-shell

---

## Файл конфигурации

Модуль ожидает файл `.compress.config.json` в корне проекта.

Пример:

{
  "ArchivePath": "archives/{projectname}-{datetime}.zip",
  "TargetDirectory": "../build/{projectname}",
  "CleanTargetDirectory": true,
  "Exclude": [
    ".git",
    ".idea",
    "node_modules",
    "*.log",
    "*.tmp"
  ]
}

Поля конфигурации:

ArchivePath — путь к создаваемому архиву (используется функцией Compress-CurrentProject)

TargetDirectory — каталог, в который будет скопирован проект

CleanTargetDirectory — очистить целевой каталог перед копированием

Exclude — маски файлов или каталогов, которые должны быть исключены

---

## Использование

Создание архива:

    Compress-CurrentProject

Копирование проекта:

    Copy-CurrentProject

Предварительный просмотр действий:

    Compress-CurrentProject -WhatIf
    Copy-CurrentProject -WhatIf

---

## Проверки безопасности

Модуль предотвращает опасные операции:

- создание архива внутри каталога исходного проекта
- копирование проекта в его собственный каталог
- очистку корневых каталогов
- удаление исходного проекта

---

## Документация

Подробная документация находится в каталоге `docs/`.
