
# tool-power-shell

PowerShell module for packaging or copying the current project according to configuration file `.compress.config.json`.

The module provides two high-level commands:

- **Compress-CurrentProject** – create ZIP archive of project
- **Copy-CurrentProject** – copy project to target directory

Both commands read configuration from `.compress.config.json` located in the project root.

The module is designed to safely operate on project directories and includes protection from destructive operations such as deleting the source directory or archiving inside the source tree.

---

# Installation

## Option 1 — Manual installation

1. Copy the module folder `tool-power-shell` to one of PowerShell module paths:

Typical locations:

Windows PowerShell:

```
$HOME\Documents\WindowsPowerShell\Modules
```

PowerShell 7:

```
$HOME\Documents\PowerShell\Modules
```

Example:

```
Modules/
  tool-power-shell/
      tool-power-shell.psd1
      tool-power-shell.psm1
      Public/
      Private/
```

Then import module:

```
Import-Module tool-power-shell
```

## Option 2 — Local usage from repository

```
Import-Module ./tool-power-shell.psd1
```

---

# Configuration

Project root must contain file:

```
.compress.config.json
```

Example configuration:

```json
{
  "ArchivePath": "dist/{projectname}-{date}.zip",
  "TargetDirectory": "../build",
  "CleanTargetDirectory": true,
  "Exclude": [
    ".git/*",
    "node_modules/*",
    "*.log"
  ],
  "PlaceHolders": {
    "env": "dev"
  }
}
```

Fields:

| Field | Description |
|------|-------------|
| ArchivePath | Path template for generated archive |
| TargetDirectory | Directory for copy operation |
| CleanTargetDirectory | Whether target directory should be cleaned before copying |
| Exclude | File exclusion masks |
| PlaceHolders | Values used in archive path template |

---

# Usage

## Create archive

```
Compress-CurrentProject
```

With explicit path:

```
Compress-CurrentProject -SourceDirectory "C:\projects\app"
```

---

## Copy project

```
Copy-CurrentProject
```

---

# Safety checks

The module prevents dangerous operations:

- archive inside source directory
- copy target inside source directory
- cleaning source directory
- cleaning root filesystem

---

# Output

Both commands return structured object describing operation result:

```
SourceDirectory
ConfigPath
ArchivePath / TargetDirectory
Exclude
```

---

# Documentation

Detailed documentation is located in `docs/` directory.
