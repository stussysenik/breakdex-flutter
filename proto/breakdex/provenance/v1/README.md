# Breakdex Provenance Transport v1

This package is the machine transport contract for Breakdex provenance. It mirrors the stable semantic axes already present in the local provenance journal while adding typed detail messages for recovery, retrieval, crash, and historical asset flows.

Compatibility rules:

- `breakdex.provenance.v1` is the major-version boundary. Breaking changes require a new package path such as `v2`.
- `SchemaVersion.major` must stay `1` for this package.
- `SchemaVersion.minor` increments only for additive, backward-compatible changes.
- Existing field numbers and enum numeric values are append-only and must never be reused.
- Phoenix ingestion should accept the current minor and at least one previous minor during rollout.

Mapping posture:

- The local journal remains the human-readable debug artifact.
- `ProvenanceEnvelope` is the backend-facing source contract for future spooling and upload.
- Event emitters should derive both artifacts from the same emission point so `scope`, `event_type`, `status`, and identity fields stay semantically aligned.
