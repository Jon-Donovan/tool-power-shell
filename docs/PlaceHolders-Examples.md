
# PlaceHolders Usage Examples

## Example Configuration

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

## Example Archive Path

```
archives/{projectname}-{date}.zip
```

Result:

```
archives/myproject-2026-03-16.zip
```

---

## Example With Date and Time

```
archives/{projectname}-{datetime}.zip
```

Result:

```
archives/myproject-2026-03-16_14-20-55.zip
```

---

## Git Information Example

```
archives/{projectname}-{branch}-{commit}.zip
```

Result:

```
archives/myproject-feature-auth-a1b2c3d.zip
```

---

## Environment Variable Example

Configuration:

```json
{
  "name": "user",
  "type": "env",
  "arg": ["USERNAME"]
}
```

Usage:

```
backup-{user}.zip
```

Result:

```
backup-john.zip
```

---

## Timestamp Example

```
build-{timestamp}.zip
```

Result:

```
build-20260316143021.zip
```
