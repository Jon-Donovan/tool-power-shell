
# Compress-CurrentProject

Creates ZIP archive of a project using configuration from `.compress.config.json`.

## Syntax

```
Compress-CurrentProject [-SourceDirectory] [-ConfigFileName]
```

## Parameters

### SourceDirectory

Path to project root directory.

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
| ArchivePath | Template path for generated archive |
| Exclude | Patterns for files excluded from archive |
| PlaceHolders | Variables used in archive path template |

---

## Archive generation process

1. Resolve source directory
2. Load configuration
3. Resolve placeholders in archive path
4. Normalize paths
5. Check archive path conflicts
6. Create archive directory if required
7. Enumerate files recursively
8. Skip excluded files
9. Add remaining files into ZIP archive

---

## Placeholders

Supported placeholders:

- `{date}`
- `{time}`
- `{datetime}`
- `{timestamp}`
- `{projectname}`
- `{guid}`
- `{env}`
- `{username}`
- `{machine}`
- `{git-branch}`
- `{git-commit-short}`

---

## Result object

Returned object contains:

```
SourceDirectory
ConfigPath
ArchivePath
Exclude
```
