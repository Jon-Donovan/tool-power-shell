
# Copy-CurrentProject

Copies project files into target directory according to `.compress.config.json`.

## Syntax

```
Copy-CurrentProject [-SourceDirectory] [-ConfigFileName]
```

---

## Parameters

### SourceDirectory

Source project directory.

Default: current directory.

### ConfigFileName

Configuration filename.

Default:

```
.compress.config.json
```

---

## Configuration fields used

| Field | Description |
|------|-------------|
| TargetDirectory | Destination directory |
| CleanTargetDirectory | If true target directory is cleaned before copy |
| Exclude | File exclusion masks |

---

## Copy process

1. Resolve source directory
2. Load configuration
3. Resolve target directory path
4. Validate safety constraints
5. Create target directory if missing
6. Optionally clean target directory
7. Recursively copy files
8. Skip excluded files

---

## Safety checks

The function prevents:

- copying project into itself
- copying into subdirectory of source
- cleaning unsafe directories

---

## Result object

Returned object contains:

```
SourceDirectory
ConfigPath
TargetDirectory
CleanTargetDirectory
Exclude
```
