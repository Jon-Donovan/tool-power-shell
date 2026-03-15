
# PlaceHolders

## Overview

PlaceHolders are a configurable mechanism used to dynamically substitute values
into strings such as archive paths or other configuration fields.

A placeholder is written in text using the following syntax:

    {name}

The actual value is calculated at runtime based on the configuration provided
in `.compress.config.json` and the logic implemented in `Resolve-Placeholders.ps1`.

The system replaces every occurrence of `{name}` with a computed value.

---

## Configuration Structure

The configuration uses an array named `PlaceHolders`:

```json
"PlaceHolders": [
  {
    "name": "date",
    "type": "date",
    "arg": ["yyyy-MM-dd"]
  }
]
```

Each entry defines how a placeholder should be resolved.

### Fields

#### name

The placeholder identifier used inside strings.

Example:

```
{name}
```

This field is required.

If it is missing, the resolver throws an error.

---

#### type

Defines how the placeholder value is generated.

Supported types:

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

This field is required.

---

#### arg

Optional array of additional arguments.

Typically used for:

- date/time formatting
- environment variable names

Example:

```json
{
  "name": "date",
  "type": "date",
  "arg": ["yyyy-MM-dd"]
}
```

---

## Resolution Algorithm

The `Resolve-Placeholders` function performs the following steps:

1. Validate the input text.
2. If the placeholder list is empty, return the original text.
3. Locate `SourceDirectory` if required by certain placeholder types.
4. Iterate through the configured placeholders.
5. Compute the value according to the placeholder type.
6. Normalize the resulting value using `Normalize-PathSegment`.
7. Replace all occurrences of `{name}` in the text.

---

## Supported Placeholder Types

### date

Returns the current date.

Default format:

```
yyyy-MM-dd
```

Example:

```
archive-{date}.zip
```

---

### time

Returns the current time.

Default format:

```
HH-mm-ss
```

---

### datetime

Returns the current date and time.

Default format:

```
yyyy-MM-dd_HH-mm-ss
```

---

### timestamp

Returns a formatted date/time string.

Default format:

```
yyyyMMddHHmmss
```

Note: This is **not** a Unix timestamp.

---

### projectname

Returns the name of the project directory.

Derived from:

```
Split-Path $SourceDirectory -Leaf
```

Requires `SourceDirectory`.

---

### guid

Generates a random GUID.

Default format:

```
N
```

Example result:

```
6f9619ff8b86d011b42d00cf4fc964ff
```

---

### env

Returns the value of an environment variable.

Requires `arg[0]` specifying the variable name.

Example:

```json
{
  "name": "user",
  "type": "env",
  "arg": ["USERNAME"]
}
```

---

### username

Shortcut for the `USERNAME` environment variable.

---

### machine

Returns the computer name (`COMPUTERNAME`).

---

### git-branch

Returns the current Git branch.

Command used:

```
git rev-parse --abbrev-ref HEAD
```

Requires `SourceDirectory`.

---

### git-commit-short

Returns the short Git commit hash.

Command used:

```
git rev-parse --short HEAD
```

Requires `SourceDirectory`.

---

## Path Normalization

Every resolved placeholder value is passed through:

```
Normalize-PathSegment
```

This ensures the resulting value is safe for filesystem paths.

Characters that are invalid in file paths may be replaced or removed.

---

## Error Conditions

The resolver throws an error if:

- `name` is missing
- `type` is missing
- `type` is unknown
- required arguments are missing
- environment variables are not found
- Git commands fail
- `SourceDirectory` is not available when required

---

## Notes

- Placeholder names are defined by configuration.
- Multiple placeholders can be used in the same string.
- All occurrences of a placeholder are replaced.
