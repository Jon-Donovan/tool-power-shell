
# Примеры использования PlaceHolders

## Конфигурация

```json
"PlaceHolders": [
  { "name": "date", "type": "date", "arg": ["yyyy-MM-dd"] },
  { "name": "datetime", "type": "datetime" },
  { "name": "projectname", "type": "projectname" },
  { "name": "branch", "type": "git-branch" },
  { "name": "commit", "type": "git-commit-short" }
]
```

---

## Пример пути архива

archives/{projectname}-{date}.zip

Результат:

archives/myproject-2026-03-16.zip

---

## Пример с датой и временем

archives/{projectname}-{datetime}.zip

Результат:

archives/myproject-2026-03-16_14-20-55.zip

---

## Пример с информацией Git

archives/{projectname}-{branch}-{commit}.zip

Результат:

archives/myproject-feature-auth-a1b2c3d.zip

---

## Пример переменной окружения

backup-{user}.zip

Результат:

backup-john.zip

---

## Пример timestamp

build-{timestamp}.zip

Результат:

build-20260316143021.zip
