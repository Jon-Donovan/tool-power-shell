## Remove-PyCacheFolders

Удаляет каталоги `__pycache__` рекурсивно.

### Описание
Функция находит все папки `__pycache__` в указанной директории и удаляет их вместе с содержимым.

### Параметры
- **Path** *(string)*  
  Корневой путь для поиска. По умолчанию — текущая директория (`.`).

### Примеры

```powershell
Remove-PyCacheFolders
````

Удаляет все `__pycache__` в текущей папке.

```powershell
Remove-PyCacheFolders -Path C:\MyProject
```

Удаляет все `__pycache__` в указанной папке.

