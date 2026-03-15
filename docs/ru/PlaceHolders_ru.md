
# PlaceHolders

## Общая информация

PlaceHolders — механизм динамической подстановки значений в строки
конфигурации (например, пути к архиву).

Маркер имеет следующий формат:

    {name}

Во время выполнения функция Resolve‑Placeholders вычисляет значение
и заменяет все вхождения маркера.

---

## Структура конфигурации

```json
"PlaceHolders": [
  {
    "name": "date",
    "type": "date",
    "arg": ["yyyy-MM-dd"]
  }
]
```

### Поля

**name** — имя placeholder, используемое в строках `{name}`.

**type** — тип вычисления значения.

Поддерживаемые типы:

- date
- time
- datetime
- timestamp
- projectname
- guid
- env
- username
- machine
- git-branch
- git-commit-short

**arg** — дополнительные аргументы (обычно формат даты или имя переменной окружения).

---

## Алгоритм работы

Resolve‑Placeholders:

1. Проверяет входную строку.
2. Если список PlaceHolders пуст — возвращает исходную строку.
3. При необходимости определяет SourceDirectory.
4. Вычисляет значение каждого placeholder.
5. Нормализует значение через Normalize‑PathSegment.
6. Заменяет `{name}` во всей строке.

---

## Типы placeholder

### date

Текущая дата.

Формат по умолчанию:

yyyy-MM-dd

---

### time

Текущее время.

Формат по умолчанию:

HH-mm-ss

---

### datetime

Дата и время.

Формат по умолчанию:

yyyy-MM-dd_HH-mm-ss

---

### timestamp

Форматированная дата/время.

По умолчанию:

yyyyMMddHHmmss

Важно: это **не Unix timestamp**.

---

### projectname

Имя каталога проекта.

---

### guid

Случайный GUID.

---

### env

Значение переменной окружения.

---

### username

Имя текущего пользователя.

---

### machine

Имя компьютера.

---

### git-branch

Текущая ветка Git.

---

### git-commit-short

Короткий hash текущего коммита Git.
