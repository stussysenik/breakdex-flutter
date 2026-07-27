## ADDED Requirements

### Requirement: Android smoke gate
The repo SHALL provide a repeatable Android smoke gate that builds or launches the Flutter
app against a known Android target.

#### Scenario: Android release candidate is checked
- **WHEN** a release candidate is prepared
- **THEN** the Android smoke gate runs from the repo and exits zero before Android readiness
  is claimed

### Requirement: Device matrix record
Device testing SHALL record the device or emulator matrix used for release validation.

#### Scenario: Multi-device run completes
- **WHEN** the Android/device test suite completes
- **THEN** the artifact records device names, OS versions, test commands, and pass/fail
  status

### Requirement: Critical flows are automated where possible
The release test harness SHALL automate core flows that can be reliably scripted:
launch, local library read, auth entry, sync status, video path handling, and crash-free
navigation.

#### Scenario: Critical flow fails
- **WHEN** a scripted critical flow fails on any device in the matrix
- **THEN** Android release readiness is blocked until the failure is fixed or explicitly
  classified as a non-blocking device-lab issue
