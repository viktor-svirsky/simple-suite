# simple-suite

Monorepo for a suite of minimal, beautiful iOS apps.

## Layout

```
apps/              # Xcode projects, one per app
packages/          # Shared Swift Packages
docs/              # Specs, design docs, ADRs
```

## Apps

- **simple-notes** — markdown notes with iCloud sync, folders, tags, images.

## Development

Each app is a standalone Xcode project under `apps/`. Shared code lives in `packages/` as local Swift Packages.
