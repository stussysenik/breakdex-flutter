# Add Historical Photos Bootstrap

## Summary

Bootstrap move rows from historical Breakdex-managed Photos assets when the local database is empty, regenerated, or missing older rows. The app should restore local video files, create move rows, and attach managed album metadata automatically during startup reconciliation.

## Motivation

Today Breakdex can relink or restore media only for moves that already exist in the local database. If an older app sandbox database is gone, users may still have valid Breakdex Photos assets but no move rows, which makes historical videos invisible.

## Scope

### In scope

- startup bootstrap from regex-matched historical Breakdex albums
- restoring local video files from Photos/iCloud assets
- creating move rows for unmatched historical assets
- deterministic but loose matching for relinking existing rows first

### Out of scope

- discovering a prior iOS sandbox database outside the current container
- server-side Phoenix/Gleam implementation in this change
- replacing backup/export JSON with Protobuf in this change
