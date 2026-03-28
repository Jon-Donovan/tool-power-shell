````md
## Remove-PyCacheFolders

Recursively removes `__pycache__` directories.

### Description
The function finds all `__pycache__` folders in the specified directory and deletes them along with their contents.

### Parameters
- **Path** *(string)*  
  Root path to search in. Defaults to the current directory (`.`).

### Examples

```powershell
Remove-PyCacheFolders
````

Removes all `__pycache__` folders in the current directory.

```powershell
Remove-PyCacheFolders -Path C:\MyProject
```

Removes all `__pycache__` folders in the specified directory.

```
```
