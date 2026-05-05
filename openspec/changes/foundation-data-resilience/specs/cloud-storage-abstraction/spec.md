## ADDED Requirements

### Requirement: CloudStorageProvider interface

The system SHALL define a `CloudStorageProvider` abstract interface with the following methods:

- `Future<void> initialize(Map<String, dynamic> config)` — provider-specific setup
- `Future<void> upload(String remoteKey, Uint8List data)` — upload bytes
- `Future<Uint8List> download(String remoteKey)` — download bytes
- `Future<void> delete(String remoteKey)` — delete remote file
- `Future<bool> exists(String remoteKey)` — check existence
- `Stream<double> downloadProgress(String remoteKey)` — progress stream

#### Scenario: Upload completes

- **WHEN** `upload('moves/abc123.mp4', videoBytes)` is called on a configured provider
- **THEN** the bytes SHALL be stored at the given remote key and the future SHALL complete without error

#### Scenario: Download returns bytes

- **WHEN** `download('moves/abc123.mp4')` is called on a configured provider where that key exists
- **THEN** the future SHALL resolve with the stored bytes

#### Scenario: Delete removes file

- **WHEN** `delete('moves/abc123.mp4')` is called and then `exists('moves/abc123.mp4')` is called
- **THEN** `exists` SHALL return `false`

#### Scenario: Download progress stream

- **WHEN** a download is in progress and `downloadProgress('moves/abc123.mp4')` is subscribed to
- **THEN** the stream SHALL emit values from 0.0 to 1.0 as the download progresses

### Requirement: S3-compatible adapter

The system SHALL provide an `S3StorageProvider` implementing `CloudStorageProvider` for any S3-compatible object storage (AWS S3, Cloudflare R2, MinIO, Backblaze B2).

Configuration SHALL include: `endpoint`, `bucket`, `region`, `accessKey`, `secretKey`.

#### Scenario: S3 configuration is set

- **WHEN** `S3StorageProvider` is initialized with `{endpoint: "https://s3.amazonaws.com", bucket: "breakdex", region: "us-east-1", accessKey: "AKIA...", secretKey: "..." }`
- **THEN** subsequent upload/download calls SHALL target that bucket

### Requirement: iCloud adapter

The system SHALL provide an `ICloudStorageProvider` implementing `CloudStorageProvider` that delegates to the existing native iOS iCloud plugin (`com.breakdex/icloud_sync` method channel).

#### Scenario: iCloud upload delegates to native plugin

- **WHEN** `upload()` is called on `ICloudStorageProvider`
- **THEN** the call SHALL be forwarded to the native `iCloudSyncPlugin` method channel

### Requirement: Google Drive adapter

The system SHALL provide a `GoogleDriveStorageProvider` implementing `CloudStorageProvider` using the existing Google Sign-In and Google APIs integration.

#### Scenario: Google Drive upload uses authenticated client

- **WHEN** `upload()` is called on `GoogleDriveStorageProvider` and the user is authenticated
- **THEN** the upload SHALL use the authenticated `GoogleAPIs` client

### Requirement: Provider registry

The system SHALL maintain a provider registry that maps provider type identifiers to `CloudStorageProvider` instances.

The `AssetSyncEngine` SHALL accept a `CloudStorageProvider` via constructor injection and route operations through it, replacing direct provider-specific code paths.

#### Scenario: Sync engine routes through provider

- **WHEN** `AssetSyncEngine.sync()` is called with an `S3StorageProvider` injected
- **THEN** all upload/download operations SHALL use the `S3StorageProvider` implementation

#### Scenario: Provider switching at runtime

- **WHEN** the active sync provider is changed from `ICloudStorageProvider` to `S3StorageProvider` via settings
- **THEN** subsequent sync operations SHALL use the new provider without app restart
