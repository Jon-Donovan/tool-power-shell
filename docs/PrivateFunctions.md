
# Private Functions

The module contains several internal helper functions used by public commands.

These functions are not exported and should be considered internal implementation details.

## Path utilities

### Get-NormalizedDirectoryPath
Normalizes directory path for consistent comparisons.

### Get-NormalizedFilePath
Normalizes file path.

### Normalize-PathSegment
Utility used during path normalization.

### Test-PathInsideDirectory
Checks if path is located inside another directory.

---

## Exclusion handling

### Test-Excluded

Determines whether file path matches exclusion masks.

Used by:

- Compress-CurrentProject
- Copy-ProjectItem

---

## Archive safety

### Test-ArchivePathConflicts

Ensures archive is not created inside source directory.

---

## Directory safety

### Assert-SafeTargetDirectoryForCleanup

Prevents destructive cleanup operations.

Checks:

- directory is not source directory
- directory is not filesystem root
- directory is not parent of source

---

## Copy utilities

### Copy-ProjectItem

Recursive copy engine used by Copy-CurrentProject.

Handles:

- directory traversal
- exclusion patterns
- safe file copying

---

## Placeholder resolution

### Resolve-Placeholders

Replaces template placeholders in configuration values.

Supports environment and Git related placeholders.
