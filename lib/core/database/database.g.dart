// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $MovesTable extends Moves with TableInfo<$MovesTable, Move> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _learningStateMeta = const VerificationMeta(
    'learningState',
  );
  @override
  late final GeneratedColumn<String> learningState = GeneratedColumn<String>(
    'learning_state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('NEW'),
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('default'),
  );
  static const VerificationMeta _videoPathMeta = const VerificationMeta(
    'videoPath',
  );
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
    'video_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _originalVideoNameMeta = const VerificationMeta(
    'originalVideoName',
  );
  @override
  late final GeneratedColumn<String> originalVideoName =
      GeneratedColumn<String>(
        'original_video_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _managedAlbumAssetIdMeta =
      const VerificationMeta('managedAlbumAssetId');
  @override
  late final GeneratedColumn<String> managedAlbumAssetId =
      GeneratedColumn<String>(
        'managed_album_asset_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _managedAlbumFilenameMeta =
      const VerificationMeta('managedAlbumFilename');
  @override
  late final GeneratedColumn<String> managedAlbumFilename =
      GeneratedColumn<String>(
        'managed_album_filename',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _managedAlbumNameMeta = const VerificationMeta(
    'managedAlbumName',
  );
  @override
  late final GeneratedColumn<String> managedAlbumName = GeneratedColumn<String>(
    'managed_album_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archivedAtMeta = const VerificationMeta(
    'archivedAt',
  );
  @override
  late final GeneratedColumn<DateTime> archivedAt = GeneratedColumn<DateTime>(
    'archived_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _archiveReasonMeta = const VerificationMeta(
    'archiveReason',
  );
  @override
  late final GeneratedColumn<String> archiveReason = GeneratedColumn<String>(
    'archive_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _imagePathsMeta = const VerificationMeta(
    'imagePaths',
  );
  @override
  late final GeneratedColumn<String> imagePaths = GeneratedColumn<String>(
    'image_paths',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _countMeta = const VerificationMeta('count');
  @override
  late final GeneratedColumn<int> count = GeneratedColumn<int>(
    'count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(4),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    learningState,
    category,
    videoPath,
    originalVideoName,
    managedAlbumAssetId,
    managedAlbumFilename,
    managedAlbumName,
    archivedAt,
    archiveReason,
    notes,
    imagePaths,
    contentHash,
    count,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<Move> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('learning_state')) {
      context.handle(
        _learningStateMeta,
        learningState.isAcceptableOrUnknown(
          data['learning_state']!,
          _learningStateMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    }
    if (data.containsKey('video_path')) {
      context.handle(
        _videoPathMeta,
        videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta),
      );
    }
    if (data.containsKey('original_video_name')) {
      context.handle(
        _originalVideoNameMeta,
        originalVideoName.isAcceptableOrUnknown(
          data['original_video_name']!,
          _originalVideoNameMeta,
        ),
      );
    }
    if (data.containsKey('managed_album_asset_id')) {
      context.handle(
        _managedAlbumAssetIdMeta,
        managedAlbumAssetId.isAcceptableOrUnknown(
          data['managed_album_asset_id']!,
          _managedAlbumAssetIdMeta,
        ),
      );
    }
    if (data.containsKey('managed_album_filename')) {
      context.handle(
        _managedAlbumFilenameMeta,
        managedAlbumFilename.isAcceptableOrUnknown(
          data['managed_album_filename']!,
          _managedAlbumFilenameMeta,
        ),
      );
    }
    if (data.containsKey('managed_album_name')) {
      context.handle(
        _managedAlbumNameMeta,
        managedAlbumName.isAcceptableOrUnknown(
          data['managed_album_name']!,
          _managedAlbumNameMeta,
        ),
      );
    }
    if (data.containsKey('archived_at')) {
      context.handle(
        _archivedAtMeta,
        archivedAt.isAcceptableOrUnknown(data['archived_at']!, _archivedAtMeta),
      );
    }
    if (data.containsKey('archive_reason')) {
      context.handle(
        _archiveReasonMeta,
        archiveReason.isAcceptableOrUnknown(
          data['archive_reason']!,
          _archiveReasonMeta,
        ),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('image_paths')) {
      context.handle(
        _imagePathsMeta,
        imagePaths.isAcceptableOrUnknown(data['image_paths']!, _imagePathsMeta),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    if (data.containsKey('count')) {
      context.handle(
        _countMeta,
        count.isAcceptableOrUnknown(data['count']!, _countMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Move map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Move(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      learningState: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}learning_state'],
      )!,
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      videoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_path'],
      ),
      originalVideoName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}original_video_name'],
      ),
      managedAlbumAssetId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_album_asset_id'],
      ),
      managedAlbumFilename: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_album_filename'],
      ),
      managedAlbumName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_album_name'],
      ),
      archivedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}archived_at'],
      ),
      archiveReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}archive_reason'],
      ),
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      imagePaths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}image_paths'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
      count: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}count'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MovesTable createAlias(String alias) {
    return $MovesTable(attachedDatabase, alias);
  }
}

class Move extends DataClass implements Insertable<Move> {
  final String id;
  final String name;
  final String learningState;
  final String category;
  final String? videoPath;
  final String? originalVideoName;
  final String? managedAlbumAssetId;
  final String? managedAlbumFilename;
  final String? managedAlbumName;
  final DateTime? archivedAt;
  final String? archiveReason;
  final String? notes;
  final String? imagePaths;
  final String? contentHash;
  final int count;
  final DateTime createdAt;
  const Move({
    required this.id,
    required this.name,
    required this.learningState,
    required this.category,
    this.videoPath,
    this.originalVideoName,
    this.managedAlbumAssetId,
    this.managedAlbumFilename,
    this.managedAlbumName,
    this.archivedAt,
    this.archiveReason,
    this.notes,
    this.imagePaths,
    this.contentHash,
    required this.count,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['learning_state'] = Variable<String>(learningState);
    map['category'] = Variable<String>(category);
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    if (!nullToAbsent || originalVideoName != null) {
      map['original_video_name'] = Variable<String>(originalVideoName);
    }
    if (!nullToAbsent || managedAlbumAssetId != null) {
      map['managed_album_asset_id'] = Variable<String>(managedAlbumAssetId);
    }
    if (!nullToAbsent || managedAlbumFilename != null) {
      map['managed_album_filename'] = Variable<String>(managedAlbumFilename);
    }
    if (!nullToAbsent || managedAlbumName != null) {
      map['managed_album_name'] = Variable<String>(managedAlbumName);
    }
    if (!nullToAbsent || archivedAt != null) {
      map['archived_at'] = Variable<DateTime>(archivedAt);
    }
    if (!nullToAbsent || archiveReason != null) {
      map['archive_reason'] = Variable<String>(archiveReason);
    }
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || imagePaths != null) {
      map['image_paths'] = Variable<String>(imagePaths);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    map['count'] = Variable<int>(count);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MovesCompanion toCompanion(bool nullToAbsent) {
    return MovesCompanion(
      id: Value(id),
      name: Value(name),
      learningState: Value(learningState),
      category: Value(category),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      originalVideoName: originalVideoName == null && nullToAbsent
          ? const Value.absent()
          : Value(originalVideoName),
      managedAlbumAssetId: managedAlbumAssetId == null && nullToAbsent
          ? const Value.absent()
          : Value(managedAlbumAssetId),
      managedAlbumFilename: managedAlbumFilename == null && nullToAbsent
          ? const Value.absent()
          : Value(managedAlbumFilename),
      managedAlbumName: managedAlbumName == null && nullToAbsent
          ? const Value.absent()
          : Value(managedAlbumName),
      archivedAt: archivedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(archivedAt),
      archiveReason: archiveReason == null && nullToAbsent
          ? const Value.absent()
          : Value(archiveReason),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      imagePaths: imagePaths == null && nullToAbsent
          ? const Value.absent()
          : Value(imagePaths),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
      count: Value(count),
      createdAt: Value(createdAt),
    );
  }

  factory Move.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Move(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      learningState: serializer.fromJson<String>(json['learningState']),
      category: serializer.fromJson<String>(json['category']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      originalVideoName: serializer.fromJson<String?>(
        json['originalVideoName'],
      ),
      managedAlbumAssetId: serializer.fromJson<String?>(
        json['managedAlbumAssetId'],
      ),
      managedAlbumFilename: serializer.fromJson<String?>(
        json['managedAlbumFilename'],
      ),
      managedAlbumName: serializer.fromJson<String?>(json['managedAlbumName']),
      archivedAt: serializer.fromJson<DateTime?>(json['archivedAt']),
      archiveReason: serializer.fromJson<String?>(json['archiveReason']),
      notes: serializer.fromJson<String?>(json['notes']),
      imagePaths: serializer.fromJson<String?>(json['imagePaths']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
      count: serializer.fromJson<int>(json['count']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'learningState': serializer.toJson<String>(learningState),
      'category': serializer.toJson<String>(category),
      'videoPath': serializer.toJson<String?>(videoPath),
      'originalVideoName': serializer.toJson<String?>(originalVideoName),
      'managedAlbumAssetId': serializer.toJson<String?>(managedAlbumAssetId),
      'managedAlbumFilename': serializer.toJson<String?>(managedAlbumFilename),
      'managedAlbumName': serializer.toJson<String?>(managedAlbumName),
      'archivedAt': serializer.toJson<DateTime?>(archivedAt),
      'archiveReason': serializer.toJson<String?>(archiveReason),
      'notes': serializer.toJson<String?>(notes),
      'imagePaths': serializer.toJson<String?>(imagePaths),
      'contentHash': serializer.toJson<String?>(contentHash),
      'count': serializer.toJson<int>(count),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Move copyWith({
    String? id,
    String? name,
    String? learningState,
    String? category,
    Value<String?> videoPath = const Value.absent(),
    Value<String?> originalVideoName = const Value.absent(),
    Value<String?> managedAlbumAssetId = const Value.absent(),
    Value<String?> managedAlbumFilename = const Value.absent(),
    Value<String?> managedAlbumName = const Value.absent(),
    Value<DateTime?> archivedAt = const Value.absent(),
    Value<String?> archiveReason = const Value.absent(),
    Value<String?> notes = const Value.absent(),
    Value<String?> imagePaths = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
    int? count,
    DateTime? createdAt,
  }) => Move(
    id: id ?? this.id,
    name: name ?? this.name,
    learningState: learningState ?? this.learningState,
    category: category ?? this.category,
    videoPath: videoPath.present ? videoPath.value : this.videoPath,
    originalVideoName: originalVideoName.present
        ? originalVideoName.value
        : this.originalVideoName,
    managedAlbumAssetId: managedAlbumAssetId.present
        ? managedAlbumAssetId.value
        : this.managedAlbumAssetId,
    managedAlbumFilename: managedAlbumFilename.present
        ? managedAlbumFilename.value
        : this.managedAlbumFilename,
    managedAlbumName: managedAlbumName.present
        ? managedAlbumName.value
        : this.managedAlbumName,
    archivedAt: archivedAt.present ? archivedAt.value : this.archivedAt,
    archiveReason: archiveReason.present
        ? archiveReason.value
        : this.archiveReason,
    notes: notes.present ? notes.value : this.notes,
    imagePaths: imagePaths.present ? imagePaths.value : this.imagePaths,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
    count: count ?? this.count,
    createdAt: createdAt ?? this.createdAt,
  );
  Move copyWithCompanion(MovesCompanion data) {
    return Move(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      learningState: data.learningState.present
          ? data.learningState.value
          : this.learningState,
      category: data.category.present ? data.category.value : this.category,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      originalVideoName: data.originalVideoName.present
          ? data.originalVideoName.value
          : this.originalVideoName,
      managedAlbumAssetId: data.managedAlbumAssetId.present
          ? data.managedAlbumAssetId.value
          : this.managedAlbumAssetId,
      managedAlbumFilename: data.managedAlbumFilename.present
          ? data.managedAlbumFilename.value
          : this.managedAlbumFilename,
      managedAlbumName: data.managedAlbumName.present
          ? data.managedAlbumName.value
          : this.managedAlbumName,
      archivedAt: data.archivedAt.present
          ? data.archivedAt.value
          : this.archivedAt,
      archiveReason: data.archiveReason.present
          ? data.archiveReason.value
          : this.archiveReason,
      notes: data.notes.present ? data.notes.value : this.notes,
      imagePaths: data.imagePaths.present
          ? data.imagePaths.value
          : this.imagePaths,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      count: data.count.present ? data.count.value : this.count,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Move(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('learningState: $learningState, ')
          ..write('category: $category, ')
          ..write('videoPath: $videoPath, ')
          ..write('originalVideoName: $originalVideoName, ')
          ..write('managedAlbumAssetId: $managedAlbumAssetId, ')
          ..write('managedAlbumFilename: $managedAlbumFilename, ')
          ..write('managedAlbumName: $managedAlbumName, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archiveReason: $archiveReason, ')
          ..write('notes: $notes, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('contentHash: $contentHash, ')
          ..write('count: $count, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    learningState,
    category,
    videoPath,
    originalVideoName,
    managedAlbumAssetId,
    managedAlbumFilename,
    managedAlbumName,
    archivedAt,
    archiveReason,
    notes,
    imagePaths,
    contentHash,
    count,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Move &&
          other.id == this.id &&
          other.name == this.name &&
          other.learningState == this.learningState &&
          other.category == this.category &&
          other.videoPath == this.videoPath &&
          other.originalVideoName == this.originalVideoName &&
          other.managedAlbumAssetId == this.managedAlbumAssetId &&
          other.managedAlbumFilename == this.managedAlbumFilename &&
          other.managedAlbumName == this.managedAlbumName &&
          other.archivedAt == this.archivedAt &&
          other.archiveReason == this.archiveReason &&
          other.notes == this.notes &&
          other.imagePaths == this.imagePaths &&
          other.contentHash == this.contentHash &&
          other.count == this.count &&
          other.createdAt == this.createdAt);
}

class MovesCompanion extends UpdateCompanion<Move> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> learningState;
  final Value<String> category;
  final Value<String?> videoPath;
  final Value<String?> originalVideoName;
  final Value<String?> managedAlbumAssetId;
  final Value<String?> managedAlbumFilename;
  final Value<String?> managedAlbumName;
  final Value<DateTime?> archivedAt;
  final Value<String?> archiveReason;
  final Value<String?> notes;
  final Value<String?> imagePaths;
  final Value<String?> contentHash;
  final Value<int> count;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MovesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.learningState = const Value.absent(),
    this.category = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.originalVideoName = const Value.absent(),
    this.managedAlbumAssetId = const Value.absent(),
    this.managedAlbumFilename = const Value.absent(),
    this.managedAlbumName = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archiveReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.count = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovesCompanion.insert({
    required String id,
    required String name,
    this.learningState = const Value.absent(),
    this.category = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.originalVideoName = const Value.absent(),
    this.managedAlbumAssetId = const Value.absent(),
    this.managedAlbumFilename = const Value.absent(),
    this.managedAlbumName = const Value.absent(),
    this.archivedAt = const Value.absent(),
    this.archiveReason = const Value.absent(),
    this.notes = const Value.absent(),
    this.imagePaths = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.count = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Move> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? learningState,
    Expression<String>? category,
    Expression<String>? videoPath,
    Expression<String>? originalVideoName,
    Expression<String>? managedAlbumAssetId,
    Expression<String>? managedAlbumFilename,
    Expression<String>? managedAlbumName,
    Expression<DateTime>? archivedAt,
    Expression<String>? archiveReason,
    Expression<String>? notes,
    Expression<String>? imagePaths,
    Expression<String>? contentHash,
    Expression<int>? count,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (learningState != null) 'learning_state': learningState,
      if (category != null) 'category': category,
      if (videoPath != null) 'video_path': videoPath,
      if (originalVideoName != null) 'original_video_name': originalVideoName,
      if (managedAlbumAssetId != null)
        'managed_album_asset_id': managedAlbumAssetId,
      if (managedAlbumFilename != null)
        'managed_album_filename': managedAlbumFilename,
      if (managedAlbumName != null) 'managed_album_name': managedAlbumName,
      if (archivedAt != null) 'archived_at': archivedAt,
      if (archiveReason != null) 'archive_reason': archiveReason,
      if (notes != null) 'notes': notes,
      if (imagePaths != null) 'image_paths': imagePaths,
      if (contentHash != null) 'content_hash': contentHash,
      if (count != null) 'count': count,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MovesCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? learningState,
    Value<String>? category,
    Value<String?>? videoPath,
    Value<String?>? originalVideoName,
    Value<String?>? managedAlbumAssetId,
    Value<String?>? managedAlbumFilename,
    Value<String?>? managedAlbumName,
    Value<DateTime?>? archivedAt,
    Value<String?>? archiveReason,
    Value<String?>? notes,
    Value<String?>? imagePaths,
    Value<String?>? contentHash,
    Value<int>? count,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MovesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      learningState: learningState ?? this.learningState,
      category: category ?? this.category,
      videoPath: videoPath ?? this.videoPath,
      originalVideoName: originalVideoName ?? this.originalVideoName,
      managedAlbumAssetId: managedAlbumAssetId ?? this.managedAlbumAssetId,
      managedAlbumFilename: managedAlbumFilename ?? this.managedAlbumFilename,
      managedAlbumName: managedAlbumName ?? this.managedAlbumName,
      archivedAt: archivedAt ?? this.archivedAt,
      archiveReason: archiveReason ?? this.archiveReason,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
      contentHash: contentHash ?? this.contentHash,
      count: count ?? this.count,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (learningState.present) {
      map['learning_state'] = Variable<String>(learningState.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (originalVideoName.present) {
      map['original_video_name'] = Variable<String>(originalVideoName.value);
    }
    if (managedAlbumAssetId.present) {
      map['managed_album_asset_id'] = Variable<String>(
        managedAlbumAssetId.value,
      );
    }
    if (managedAlbumFilename.present) {
      map['managed_album_filename'] = Variable<String>(
        managedAlbumFilename.value,
      );
    }
    if (managedAlbumName.present) {
      map['managed_album_name'] = Variable<String>(managedAlbumName.value);
    }
    if (archivedAt.present) {
      map['archived_at'] = Variable<DateTime>(archivedAt.value);
    }
    if (archiveReason.present) {
      map['archive_reason'] = Variable<String>(archiveReason.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (imagePaths.present) {
      map['image_paths'] = Variable<String>(imagePaths.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (count.present) {
      map['count'] = Variable<int>(count.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MovesCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('learningState: $learningState, ')
          ..write('category: $category, ')
          ..write('videoPath: $videoPath, ')
          ..write('originalVideoName: $originalVideoName, ')
          ..write('managedAlbumAssetId: $managedAlbumAssetId, ')
          ..write('managedAlbumFilename: $managedAlbumFilename, ')
          ..write('managedAlbumName: $managedAlbumName, ')
          ..write('archivedAt: $archivedAt, ')
          ..write('archiveReason: $archiveReason, ')
          ..write('notes: $notes, ')
          ..write('imagePaths: $imagePaths, ')
          ..write('contentHash: $contentHash, ')
          ..write('count: $count, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CombosTable extends Combos with TableInfo<$CombosTable, Combo> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CombosTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _activeVideoPathMeta = const VerificationMeta(
    'activeVideoPath',
  );
  @override
  late final GeneratedColumn<String> activeVideoPath = GeneratedColumn<String>(
    'active_video_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    notes,
    activeVideoPath,
    contentHash,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'combos';
  @override
  VerificationContext validateIntegrity(
    Insertable<Combo> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('active_video_path')) {
      context.handle(
        _activeVideoPathMeta,
        activeVideoPath.isAcceptableOrUnknown(
          data['active_video_path']!,
          _activeVideoPathMeta,
        ),
      );
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Combo map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Combo(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      activeVideoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_video_path'],
      ),
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      ),
    );
  }

  @override
  $CombosTable createAlias(String alias) {
    return $CombosTable(attachedDatabase, alias);
  }
}

class Combo extends DataClass implements Insertable<Combo> {
  final String id;
  final String name;
  final String? notes;
  final String? activeVideoPath;
  final String? contentHash;
  const Combo({
    required this.id,
    required this.name,
    this.notes,
    this.activeVideoPath,
    this.contentHash,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || activeVideoPath != null) {
      map['active_video_path'] = Variable<String>(activeVideoPath);
    }
    if (!nullToAbsent || contentHash != null) {
      map['content_hash'] = Variable<String>(contentHash);
    }
    return map;
  }

  CombosCompanion toCompanion(bool nullToAbsent) {
    return CombosCompanion(
      id: Value(id),
      name: Value(name),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      activeVideoPath: activeVideoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVideoPath),
      contentHash: contentHash == null && nullToAbsent
          ? const Value.absent()
          : Value(contentHash),
    );
  }

  factory Combo.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Combo(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      notes: serializer.fromJson<String?>(json['notes']),
      activeVideoPath: serializer.fromJson<String?>(json['activeVideoPath']),
      contentHash: serializer.fromJson<String?>(json['contentHash']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'notes': serializer.toJson<String?>(notes),
      'activeVideoPath': serializer.toJson<String?>(activeVideoPath),
      'contentHash': serializer.toJson<String?>(contentHash),
    };
  }

  Combo copyWith({
    String? id,
    String? name,
    Value<String?> notes = const Value.absent(),
    Value<String?> activeVideoPath = const Value.absent(),
    Value<String?> contentHash = const Value.absent(),
  }) => Combo(
    id: id ?? this.id,
    name: name ?? this.name,
    notes: notes.present ? notes.value : this.notes,
    activeVideoPath: activeVideoPath.present
        ? activeVideoPath.value
        : this.activeVideoPath,
    contentHash: contentHash.present ? contentHash.value : this.contentHash,
  );
  Combo copyWithCompanion(CombosCompanion data) {
    return Combo(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      notes: data.notes.present ? data.notes.value : this.notes,
      activeVideoPath: data.activeVideoPath.present
          ? data.activeVideoPath.value
          : this.activeVideoPath,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Combo(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('activeVideoPath: $activeVideoPath, ')
          ..write('contentHash: $contentHash')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, notes, activeVideoPath, contentHash);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Combo &&
          other.id == this.id &&
          other.name == this.name &&
          other.notes == this.notes &&
          other.activeVideoPath == this.activeVideoPath &&
          other.contentHash == this.contentHash);
}

class CombosCompanion extends UpdateCompanion<Combo> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> notes;
  final Value<String?> activeVideoPath;
  final Value<String?> contentHash;
  final Value<int> rowid;
  const CombosCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.notes = const Value.absent(),
    this.activeVideoPath = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CombosCompanion.insert({
    required String id,
    required String name,
    this.notes = const Value.absent(),
    this.activeVideoPath = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Combo> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? notes,
    Expression<String>? activeVideoPath,
    Expression<String>? contentHash,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (notes != null) 'notes': notes,
      if (activeVideoPath != null) 'active_video_path': activeVideoPath,
      if (contentHash != null) 'content_hash': contentHash,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CombosCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? notes,
    Value<String?>? activeVideoPath,
    Value<String?>? contentHash,
    Value<int>? rowid,
  }) {
    return CombosCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      notes: notes ?? this.notes,
      activeVideoPath: activeVideoPath ?? this.activeVideoPath,
      contentHash: contentHash ?? this.contentHash,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (activeVideoPath.present) {
      map['active_video_path'] = Variable<String>(activeVideoPath.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CombosCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('notes: $notes, ')
          ..write('activeVideoPath: $activeVideoPath, ')
          ..write('contentHash: $contentHash, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ComboMovesTable extends ComboMoves
    with TableInfo<$ComboMovesTable, ComboMove> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ComboMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sequenceIndexMeta = const VerificationMeta(
    'sequenceIndex',
  );
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
    'sequence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _comboIdMeta = const VerificationMeta(
    'comboId',
  );
  @override
  late final GeneratedColumn<String> comboId = GeneratedColumn<String>(
    'combo_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES combos (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [id, sequenceIndex, comboId, moveId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'combo_moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<ComboMove> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
        _sequenceIndexMeta,
        sequenceIndex.isAcceptableOrUnknown(
          data['sequence_index']!,
          _sequenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    if (data.containsKey('combo_id')) {
      context.handle(
        _comboIdMeta,
        comboId.isAcceptableOrUnknown(data['combo_id']!, _comboIdMeta),
      );
    } else if (isInserting) {
      context.missing(_comboIdMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ComboMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ComboMove(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      sequenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_index'],
      )!,
      comboId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}combo_id'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      )!,
    );
  }

  @override
  $ComboMovesTable createAlias(String alias) {
    return $ComboMovesTable(attachedDatabase, alias);
  }
}

class ComboMove extends DataClass implements Insertable<ComboMove> {
  final String id;
  final int sequenceIndex;
  final String comboId;
  final String moveId;
  const ComboMove({
    required this.id,
    required this.sequenceIndex,
    required this.comboId,
    required this.moveId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    map['combo_id'] = Variable<String>(comboId);
    map['move_id'] = Variable<String>(moveId);
    return map;
  }

  ComboMovesCompanion toCompanion(bool nullToAbsent) {
    return ComboMovesCompanion(
      id: Value(id),
      sequenceIndex: Value(sequenceIndex),
      comboId: Value(comboId),
      moveId: Value(moveId),
    );
  }

  factory ComboMove.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ComboMove(
      id: serializer.fromJson<String>(json['id']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
      comboId: serializer.fromJson<String>(json['comboId']),
      moveId: serializer.fromJson<String>(json['moveId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
      'comboId': serializer.toJson<String>(comboId),
      'moveId': serializer.toJson<String>(moveId),
    };
  }

  ComboMove copyWith({
    String? id,
    int? sequenceIndex,
    String? comboId,
    String? moveId,
  }) => ComboMove(
    id: id ?? this.id,
    sequenceIndex: sequenceIndex ?? this.sequenceIndex,
    comboId: comboId ?? this.comboId,
    moveId: moveId ?? this.moveId,
  );
  ComboMove copyWithCompanion(ComboMovesCompanion data) {
    return ComboMove(
      id: data.id.present ? data.id.value : this.id,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
      comboId: data.comboId.present ? data.comboId.value : this.comboId,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ComboMove(')
          ..write('id: $id, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('comboId: $comboId, ')
          ..write('moveId: $moveId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, sequenceIndex, comboId, moveId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ComboMove &&
          other.id == this.id &&
          other.sequenceIndex == this.sequenceIndex &&
          other.comboId == this.comboId &&
          other.moveId == this.moveId);
}

class ComboMovesCompanion extends UpdateCompanion<ComboMove> {
  final Value<String> id;
  final Value<int> sequenceIndex;
  final Value<String> comboId;
  final Value<String> moveId;
  final Value<int> rowid;
  const ComboMovesCompanion({
    this.id = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
    this.comboId = const Value.absent(),
    this.moveId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ComboMovesCompanion.insert({
    required String id,
    required int sequenceIndex,
    required String comboId,
    required String moveId,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       sequenceIndex = Value(sequenceIndex),
       comboId = Value(comboId),
       moveId = Value(moveId);
  static Insertable<ComboMove> custom({
    Expression<String>? id,
    Expression<int>? sequenceIndex,
    Expression<String>? comboId,
    Expression<String>? moveId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
      if (comboId != null) 'combo_id': comboId,
      if (moveId != null) 'move_id': moveId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ComboMovesCompanion copyWith({
    Value<String>? id,
    Value<int>? sequenceIndex,
    Value<String>? comboId,
    Value<String>? moveId,
    Value<int>? rowid,
  }) {
    return ComboMovesCompanion(
      id: id ?? this.id,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      comboId: comboId ?? this.comboId,
      moveId: moveId ?? this.moveId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    if (comboId.present) {
      map['combo_id'] = Variable<String>(comboId.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ComboMovesCompanion(')
          ..write('id: $id, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('comboId: $comboId, ')
          ..write('moveId: $moveId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReviewsTable extends Reviews with TableInfo<$ReviewsTable, Review> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReviewsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _ratingMeta = const VerificationMeta('rating');
  @override
  late final GeneratedColumn<String> rating = GeneratedColumn<String>(
    'rating',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewTypeMeta = const VerificationMeta(
    'reviewType',
  );
  @override
  late final GeneratedColumn<String> reviewType = GeneratedColumn<String>(
    'review_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reviewedAtMeta = const VerificationMeta(
    'reviewedAt',
  );
  @override
  late final GeneratedColumn<DateTime> reviewedAt = GeneratedColumn<DateTime>(
    'reviewed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _comboIdMeta = const VerificationMeta(
    'comboId',
  );
  @override
  late final GeneratedColumn<String> comboId = GeneratedColumn<String>(
    'combo_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES combos (id) ON DELETE SET NULL',
    ),
  );
  static const VerificationMeta _entityIdSnapshotMeta = const VerificationMeta(
    'entityIdSnapshot',
  );
  @override
  late final GeneratedColumn<String> entityIdSnapshot = GeneratedColumn<String>(
    'entity_id_snapshot',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _entityDisplayNameMeta = const VerificationMeta(
    'entityDisplayName',
  );
  @override
  late final GeneratedColumn<String> entityDisplayName =
      GeneratedColumn<String>(
        'entity_display_name',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _entityCategoryMeta = const VerificationMeta(
    'entityCategory',
  );
  @override
  late final GeneratedColumn<String> entityCategory = GeneratedColumn<String>(
    'entity_category',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsPreStateMeta = const VerificationMeta(
    'fsrsPreState',
  );
  @override
  late final GeneratedColumn<int> fsrsPreState = GeneratedColumn<int>(
    'fsrs_pre_state',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _fsrsPostStateMeta = const VerificationMeta(
    'fsrsPostState',
  );
  @override
  late final GeneratedColumn<int> fsrsPostState = GeneratedColumn<int>(
    'fsrs_post_state',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rating,
    reviewType,
    reviewedAt,
    moveId,
    comboId,
    entityIdSnapshot,
    entityType,
    entityDisplayName,
    entityCategory,
    fsrsPreState,
    fsrsPostState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'reviews';
  @override
  VerificationContext validateIntegrity(
    Insertable<Review> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('rating')) {
      context.handle(
        _ratingMeta,
        rating.isAcceptableOrUnknown(data['rating']!, _ratingMeta),
      );
    } else if (isInserting) {
      context.missing(_ratingMeta);
    }
    if (data.containsKey('review_type')) {
      context.handle(
        _reviewTypeMeta,
        reviewType.isAcceptableOrUnknown(data['review_type']!, _reviewTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_reviewTypeMeta);
    }
    if (data.containsKey('reviewed_at')) {
      context.handle(
        _reviewedAtMeta,
        reviewedAt.isAcceptableOrUnknown(data['reviewed_at']!, _reviewedAtMeta),
      );
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    }
    if (data.containsKey('combo_id')) {
      context.handle(
        _comboIdMeta,
        comboId.isAcceptableOrUnknown(data['combo_id']!, _comboIdMeta),
      );
    }
    if (data.containsKey('entity_id_snapshot')) {
      context.handle(
        _entityIdSnapshotMeta,
        entityIdSnapshot.isAcceptableOrUnknown(
          data['entity_id_snapshot']!,
          _entityIdSnapshotMeta,
        ),
      );
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('entity_display_name')) {
      context.handle(
        _entityDisplayNameMeta,
        entityDisplayName.isAcceptableOrUnknown(
          data['entity_display_name']!,
          _entityDisplayNameMeta,
        ),
      );
    }
    if (data.containsKey('entity_category')) {
      context.handle(
        _entityCategoryMeta,
        entityCategory.isAcceptableOrUnknown(
          data['entity_category']!,
          _entityCategoryMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_pre_state')) {
      context.handle(
        _fsrsPreStateMeta,
        fsrsPreState.isAcceptableOrUnknown(
          data['fsrs_pre_state']!,
          _fsrsPreStateMeta,
        ),
      );
    }
    if (data.containsKey('fsrs_post_state')) {
      context.handle(
        _fsrsPostStateMeta,
        fsrsPostState.isAcceptableOrUnknown(
          data['fsrs_post_state']!,
          _fsrsPostStateMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Review map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Review(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      rating: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}rating'],
      )!,
      reviewType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}review_type'],
      )!,
      reviewedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}reviewed_at'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      ),
      comboId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}combo_id'],
      ),
      entityIdSnapshot: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id_snapshot'],
      ),
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      ),
      entityDisplayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_display_name'],
      ),
      entityCategory: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_category'],
      ),
      fsrsPreState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fsrs_pre_state'],
      ),
      fsrsPostState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fsrs_post_state'],
      ),
    );
  }

  @override
  $ReviewsTable createAlias(String alias) {
    return $ReviewsTable(attachedDatabase, alias);
  }
}

class Review extends DataClass implements Insertable<Review> {
  final String id;
  final String rating;
  final String reviewType;
  final DateTime reviewedAt;
  final String? moveId;

  /// FK to combos — set when reviewing a combo. Nullable because most
  /// reviews are move reviews. Added in schema v8 alongside FSRS combo support.
  final String? comboId;

  /// Immutable snapshot of the reviewed card so stats remain readable even if
  /// the underlying move/combo is renamed or deleted later.
  final String? entityIdSnapshot;
  final String? entityType;
  final String? entityDisplayName;
  final String? entityCategory;

  /// FSRS card state *before* this review was processed.
  /// Null for legacy reviews recorded before the streaks redesign.
  /// Values: 0=New, 1=Learning, 2=Review, 3=Relearning.
  final int? fsrsPreState;

  /// FSRS card state *after* this review was processed.
  /// When fsrsPreState != 2 && fsrsPostState == 2, the card "graduated"
  /// (transitioned to Review state), meaning the learner demonstrated recall.
  final int? fsrsPostState;
  const Review({
    required this.id,
    required this.rating,
    required this.reviewType,
    required this.reviewedAt,
    this.moveId,
    this.comboId,
    this.entityIdSnapshot,
    this.entityType,
    this.entityDisplayName,
    this.entityCategory,
    this.fsrsPreState,
    this.fsrsPostState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['rating'] = Variable<String>(rating);
    map['review_type'] = Variable<String>(reviewType);
    map['reviewed_at'] = Variable<DateTime>(reviewedAt);
    if (!nullToAbsent || moveId != null) {
      map['move_id'] = Variable<String>(moveId);
    }
    if (!nullToAbsent || comboId != null) {
      map['combo_id'] = Variable<String>(comboId);
    }
    if (!nullToAbsent || entityIdSnapshot != null) {
      map['entity_id_snapshot'] = Variable<String>(entityIdSnapshot);
    }
    if (!nullToAbsent || entityType != null) {
      map['entity_type'] = Variable<String>(entityType);
    }
    if (!nullToAbsent || entityDisplayName != null) {
      map['entity_display_name'] = Variable<String>(entityDisplayName);
    }
    if (!nullToAbsent || entityCategory != null) {
      map['entity_category'] = Variable<String>(entityCategory);
    }
    if (!nullToAbsent || fsrsPreState != null) {
      map['fsrs_pre_state'] = Variable<int>(fsrsPreState);
    }
    if (!nullToAbsent || fsrsPostState != null) {
      map['fsrs_post_state'] = Variable<int>(fsrsPostState);
    }
    return map;
  }

  ReviewsCompanion toCompanion(bool nullToAbsent) {
    return ReviewsCompanion(
      id: Value(id),
      rating: Value(rating),
      reviewType: Value(reviewType),
      reviewedAt: Value(reviewedAt),
      moveId: moveId == null && nullToAbsent
          ? const Value.absent()
          : Value(moveId),
      comboId: comboId == null && nullToAbsent
          ? const Value.absent()
          : Value(comboId),
      entityIdSnapshot: entityIdSnapshot == null && nullToAbsent
          ? const Value.absent()
          : Value(entityIdSnapshot),
      entityType: entityType == null && nullToAbsent
          ? const Value.absent()
          : Value(entityType),
      entityDisplayName: entityDisplayName == null && nullToAbsent
          ? const Value.absent()
          : Value(entityDisplayName),
      entityCategory: entityCategory == null && nullToAbsent
          ? const Value.absent()
          : Value(entityCategory),
      fsrsPreState: fsrsPreState == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsPreState),
      fsrsPostState: fsrsPostState == null && nullToAbsent
          ? const Value.absent()
          : Value(fsrsPostState),
    );
  }

  factory Review.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Review(
      id: serializer.fromJson<String>(json['id']),
      rating: serializer.fromJson<String>(json['rating']),
      reviewType: serializer.fromJson<String>(json['reviewType']),
      reviewedAt: serializer.fromJson<DateTime>(json['reviewedAt']),
      moveId: serializer.fromJson<String?>(json['moveId']),
      comboId: serializer.fromJson<String?>(json['comboId']),
      entityIdSnapshot: serializer.fromJson<String?>(json['entityIdSnapshot']),
      entityType: serializer.fromJson<String?>(json['entityType']),
      entityDisplayName: serializer.fromJson<String?>(
        json['entityDisplayName'],
      ),
      entityCategory: serializer.fromJson<String?>(json['entityCategory']),
      fsrsPreState: serializer.fromJson<int?>(json['fsrsPreState']),
      fsrsPostState: serializer.fromJson<int?>(json['fsrsPostState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'rating': serializer.toJson<String>(rating),
      'reviewType': serializer.toJson<String>(reviewType),
      'reviewedAt': serializer.toJson<DateTime>(reviewedAt),
      'moveId': serializer.toJson<String?>(moveId),
      'comboId': serializer.toJson<String?>(comboId),
      'entityIdSnapshot': serializer.toJson<String?>(entityIdSnapshot),
      'entityType': serializer.toJson<String?>(entityType),
      'entityDisplayName': serializer.toJson<String?>(entityDisplayName),
      'entityCategory': serializer.toJson<String?>(entityCategory),
      'fsrsPreState': serializer.toJson<int?>(fsrsPreState),
      'fsrsPostState': serializer.toJson<int?>(fsrsPostState),
    };
  }

  Review copyWith({
    String? id,
    String? rating,
    String? reviewType,
    DateTime? reviewedAt,
    Value<String?> moveId = const Value.absent(),
    Value<String?> comboId = const Value.absent(),
    Value<String?> entityIdSnapshot = const Value.absent(),
    Value<String?> entityType = const Value.absent(),
    Value<String?> entityDisplayName = const Value.absent(),
    Value<String?> entityCategory = const Value.absent(),
    Value<int?> fsrsPreState = const Value.absent(),
    Value<int?> fsrsPostState = const Value.absent(),
  }) => Review(
    id: id ?? this.id,
    rating: rating ?? this.rating,
    reviewType: reviewType ?? this.reviewType,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    moveId: moveId.present ? moveId.value : this.moveId,
    comboId: comboId.present ? comboId.value : this.comboId,
    entityIdSnapshot: entityIdSnapshot.present
        ? entityIdSnapshot.value
        : this.entityIdSnapshot,
    entityType: entityType.present ? entityType.value : this.entityType,
    entityDisplayName: entityDisplayName.present
        ? entityDisplayName.value
        : this.entityDisplayName,
    entityCategory: entityCategory.present
        ? entityCategory.value
        : this.entityCategory,
    fsrsPreState: fsrsPreState.present ? fsrsPreState.value : this.fsrsPreState,
    fsrsPostState: fsrsPostState.present
        ? fsrsPostState.value
        : this.fsrsPostState,
  );
  Review copyWithCompanion(ReviewsCompanion data) {
    return Review(
      id: data.id.present ? data.id.value : this.id,
      rating: data.rating.present ? data.rating.value : this.rating,
      reviewType: data.reviewType.present
          ? data.reviewType.value
          : this.reviewType,
      reviewedAt: data.reviewedAt.present
          ? data.reviewedAt.value
          : this.reviewedAt,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      comboId: data.comboId.present ? data.comboId.value : this.comboId,
      entityIdSnapshot: data.entityIdSnapshot.present
          ? data.entityIdSnapshot.value
          : this.entityIdSnapshot,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityDisplayName: data.entityDisplayName.present
          ? data.entityDisplayName.value
          : this.entityDisplayName,
      entityCategory: data.entityCategory.present
          ? data.entityCategory.value
          : this.entityCategory,
      fsrsPreState: data.fsrsPreState.present
          ? data.fsrsPreState.value
          : this.fsrsPreState,
      fsrsPostState: data.fsrsPostState.present
          ? data.fsrsPostState.value
          : this.fsrsPostState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Review(')
          ..write('id: $id, ')
          ..write('rating: $rating, ')
          ..write('reviewType: $reviewType, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('moveId: $moveId, ')
          ..write('comboId: $comboId, ')
          ..write('entityIdSnapshot: $entityIdSnapshot, ')
          ..write('entityType: $entityType, ')
          ..write('entityDisplayName: $entityDisplayName, ')
          ..write('entityCategory: $entityCategory, ')
          ..write('fsrsPreState: $fsrsPreState, ')
          ..write('fsrsPostState: $fsrsPostState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    rating,
    reviewType,
    reviewedAt,
    moveId,
    comboId,
    entityIdSnapshot,
    entityType,
    entityDisplayName,
    entityCategory,
    fsrsPreState,
    fsrsPostState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Review &&
          other.id == this.id &&
          other.rating == this.rating &&
          other.reviewType == this.reviewType &&
          other.reviewedAt == this.reviewedAt &&
          other.moveId == this.moveId &&
          other.comboId == this.comboId &&
          other.entityIdSnapshot == this.entityIdSnapshot &&
          other.entityType == this.entityType &&
          other.entityDisplayName == this.entityDisplayName &&
          other.entityCategory == this.entityCategory &&
          other.fsrsPreState == this.fsrsPreState &&
          other.fsrsPostState == this.fsrsPostState);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<String> id;
  final Value<String> rating;
  final Value<String> reviewType;
  final Value<DateTime> reviewedAt;
  final Value<String?> moveId;
  final Value<String?> comboId;
  final Value<String?> entityIdSnapshot;
  final Value<String?> entityType;
  final Value<String?> entityDisplayName;
  final Value<String?> entityCategory;
  final Value<int?> fsrsPreState;
  final Value<int?> fsrsPostState;
  final Value<int> rowid;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewType = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.moveId = const Value.absent(),
    this.comboId = const Value.absent(),
    this.entityIdSnapshot = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityDisplayName = const Value.absent(),
    this.entityCategory = const Value.absent(),
    this.fsrsPreState = const Value.absent(),
    this.fsrsPostState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewsCompanion.insert({
    required String id,
    required String rating,
    required String reviewType,
    this.reviewedAt = const Value.absent(),
    this.moveId = const Value.absent(),
    this.comboId = const Value.absent(),
    this.entityIdSnapshot = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityDisplayName = const Value.absent(),
    this.entityCategory = const Value.absent(),
    this.fsrsPreState = const Value.absent(),
    this.fsrsPostState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       rating = Value(rating),
       reviewType = Value(reviewType);
  static Insertable<Review> custom({
    Expression<String>? id,
    Expression<String>? rating,
    Expression<String>? reviewType,
    Expression<DateTime>? reviewedAt,
    Expression<String>? moveId,
    Expression<String>? comboId,
    Expression<String>? entityIdSnapshot,
    Expression<String>? entityType,
    Expression<String>? entityDisplayName,
    Expression<String>? entityCategory,
    Expression<int>? fsrsPreState,
    Expression<int>? fsrsPostState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rating != null) 'rating': rating,
      if (reviewType != null) 'review_type': reviewType,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (moveId != null) 'move_id': moveId,
      if (comboId != null) 'combo_id': comboId,
      if (entityIdSnapshot != null) 'entity_id_snapshot': entityIdSnapshot,
      if (entityType != null) 'entity_type': entityType,
      if (entityDisplayName != null) 'entity_display_name': entityDisplayName,
      if (entityCategory != null) 'entity_category': entityCategory,
      if (fsrsPreState != null) 'fsrs_pre_state': fsrsPreState,
      if (fsrsPostState != null) 'fsrs_post_state': fsrsPostState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? rating,
    Value<String>? reviewType,
    Value<DateTime>? reviewedAt,
    Value<String?>? moveId,
    Value<String?>? comboId,
    Value<String?>? entityIdSnapshot,
    Value<String?>? entityType,
    Value<String?>? entityDisplayName,
    Value<String?>? entityCategory,
    Value<int?>? fsrsPreState,
    Value<int?>? fsrsPostState,
    Value<int>? rowid,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      reviewType: reviewType ?? this.reviewType,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      moveId: moveId ?? this.moveId,
      comboId: comboId ?? this.comboId,
      entityIdSnapshot: entityIdSnapshot ?? this.entityIdSnapshot,
      entityType: entityType ?? this.entityType,
      entityDisplayName: entityDisplayName ?? this.entityDisplayName,
      entityCategory: entityCategory ?? this.entityCategory,
      fsrsPreState: fsrsPreState ?? this.fsrsPreState,
      fsrsPostState: fsrsPostState ?? this.fsrsPostState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (rating.present) {
      map['rating'] = Variable<String>(rating.value);
    }
    if (reviewType.present) {
      map['review_type'] = Variable<String>(reviewType.value);
    }
    if (reviewedAt.present) {
      map['reviewed_at'] = Variable<DateTime>(reviewedAt.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (comboId.present) {
      map['combo_id'] = Variable<String>(comboId.value);
    }
    if (entityIdSnapshot.present) {
      map['entity_id_snapshot'] = Variable<String>(entityIdSnapshot.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityDisplayName.present) {
      map['entity_display_name'] = Variable<String>(entityDisplayName.value);
    }
    if (entityCategory.present) {
      map['entity_category'] = Variable<String>(entityCategory.value);
    }
    if (fsrsPreState.present) {
      map['fsrs_pre_state'] = Variable<int>(fsrsPreState.value);
    }
    if (fsrsPostState.present) {
      map['fsrs_post_state'] = Variable<int>(fsrsPostState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReviewsCompanion(')
          ..write('id: $id, ')
          ..write('rating: $rating, ')
          ..write('reviewType: $reviewType, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('moveId: $moveId, ')
          ..write('comboId: $comboId, ')
          ..write('entityIdSnapshot: $entityIdSnapshot, ')
          ..write('entityType: $entityType, ')
          ..write('entityDisplayName: $entityDisplayName, ')
          ..write('entityCategory: $entityCategory, ')
          ..write('fsrsPreState: $fsrsPreState, ')
          ..write('fsrsPostState: $fsrsPostState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BattleResultsTable extends BattleResults
    with TableInfo<$BattleResultsTable, BattleResult> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BattleResultsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scoreMeta = const VerificationMeta('score');
  @override
  late final GeneratedColumn<int> score = GeneratedColumn<int>(
    'score',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _movesReviewedMeta = const VerificationMeta(
    'movesReviewed',
  );
  @override
  late final GeneratedColumn<int> movesReviewed = GeneratedColumn<int>(
    'moves_reviewed',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goodCountMeta = const VerificationMeta(
    'goodCount',
  );
  @override
  late final GeneratedColumn<int> goodCount = GeneratedColumn<int>(
    'good_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _hardCountMeta = const VerificationMeta(
    'hardCount',
  );
  @override
  late final GeneratedColumn<int> hardCount = GeneratedColumn<int>(
    'hard_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _againCountMeta = const VerificationMeta(
    'againCount',
  );
  @override
  late final GeneratedColumn<int> againCount = GeneratedColumn<int>(
    'again_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _longestStreakMeta = const VerificationMeta(
    'longestStreak',
  );
  @override
  late final GeneratedColumn<int> longestStreak = GeneratedColumn<int>(
    'longest_streak',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<String> difficulty = GeneratedColumn<String>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _playedAtMeta = const VerificationMeta(
    'playedAt',
  );
  @override
  late final GeneratedColumn<DateTime> playedAt = GeneratedColumn<DateTime>(
    'played_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    score,
    movesReviewed,
    goodCount,
    hardCount,
    againCount,
    longestStreak,
    difficulty,
    playedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'battle_results';
  @override
  VerificationContext validateIntegrity(
    Insertable<BattleResult> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('score')) {
      context.handle(
        _scoreMeta,
        score.isAcceptableOrUnknown(data['score']!, _scoreMeta),
      );
    } else if (isInserting) {
      context.missing(_scoreMeta);
    }
    if (data.containsKey('moves_reviewed')) {
      context.handle(
        _movesReviewedMeta,
        movesReviewed.isAcceptableOrUnknown(
          data['moves_reviewed']!,
          _movesReviewedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_movesReviewedMeta);
    }
    if (data.containsKey('good_count')) {
      context.handle(
        _goodCountMeta,
        goodCount.isAcceptableOrUnknown(data['good_count']!, _goodCountMeta),
      );
    } else if (isInserting) {
      context.missing(_goodCountMeta);
    }
    if (data.containsKey('hard_count')) {
      context.handle(
        _hardCountMeta,
        hardCount.isAcceptableOrUnknown(data['hard_count']!, _hardCountMeta),
      );
    } else if (isInserting) {
      context.missing(_hardCountMeta);
    }
    if (data.containsKey('again_count')) {
      context.handle(
        _againCountMeta,
        againCount.isAcceptableOrUnknown(data['again_count']!, _againCountMeta),
      );
    } else if (isInserting) {
      context.missing(_againCountMeta);
    }
    if (data.containsKey('longest_streak')) {
      context.handle(
        _longestStreakMeta,
        longestStreak.isAcceptableOrUnknown(
          data['longest_streak']!,
          _longestStreakMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_longestStreakMeta);
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    } else if (isInserting) {
      context.missing(_difficultyMeta);
    }
    if (data.containsKey('played_at')) {
      context.handle(
        _playedAtMeta,
        playedAt.isAcceptableOrUnknown(data['played_at']!, _playedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BattleResult map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BattleResult(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      score: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}score'],
      )!,
      movesReviewed: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}moves_reviewed'],
      )!,
      goodCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}good_count'],
      )!,
      hardCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}hard_count'],
      )!,
      againCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}again_count'],
      )!,
      longestStreak: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}longest_streak'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}difficulty'],
      )!,
      playedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}played_at'],
      )!,
    );
  }

  @override
  $BattleResultsTable createAlias(String alias) {
    return $BattleResultsTable(attachedDatabase, alias);
  }
}

class BattleResult extends DataClass implements Insertable<BattleResult> {
  final String id;
  final int score;
  final int movesReviewed;
  final int goodCount;
  final int hardCount;
  final int againCount;
  final int longestStreak;
  final String difficulty;
  final DateTime playedAt;
  const BattleResult({
    required this.id,
    required this.score,
    required this.movesReviewed,
    required this.goodCount,
    required this.hardCount,
    required this.againCount,
    required this.longestStreak,
    required this.difficulty,
    required this.playedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['score'] = Variable<int>(score);
    map['moves_reviewed'] = Variable<int>(movesReviewed);
    map['good_count'] = Variable<int>(goodCount);
    map['hard_count'] = Variable<int>(hardCount);
    map['again_count'] = Variable<int>(againCount);
    map['longest_streak'] = Variable<int>(longestStreak);
    map['difficulty'] = Variable<String>(difficulty);
    map['played_at'] = Variable<DateTime>(playedAt);
    return map;
  }

  BattleResultsCompanion toCompanion(bool nullToAbsent) {
    return BattleResultsCompanion(
      id: Value(id),
      score: Value(score),
      movesReviewed: Value(movesReviewed),
      goodCount: Value(goodCount),
      hardCount: Value(hardCount),
      againCount: Value(againCount),
      longestStreak: Value(longestStreak),
      difficulty: Value(difficulty),
      playedAt: Value(playedAt),
    );
  }

  factory BattleResult.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BattleResult(
      id: serializer.fromJson<String>(json['id']),
      score: serializer.fromJson<int>(json['score']),
      movesReviewed: serializer.fromJson<int>(json['movesReviewed']),
      goodCount: serializer.fromJson<int>(json['goodCount']),
      hardCount: serializer.fromJson<int>(json['hardCount']),
      againCount: serializer.fromJson<int>(json['againCount']),
      longestStreak: serializer.fromJson<int>(json['longestStreak']),
      difficulty: serializer.fromJson<String>(json['difficulty']),
      playedAt: serializer.fromJson<DateTime>(json['playedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'score': serializer.toJson<int>(score),
      'movesReviewed': serializer.toJson<int>(movesReviewed),
      'goodCount': serializer.toJson<int>(goodCount),
      'hardCount': serializer.toJson<int>(hardCount),
      'againCount': serializer.toJson<int>(againCount),
      'longestStreak': serializer.toJson<int>(longestStreak),
      'difficulty': serializer.toJson<String>(difficulty),
      'playedAt': serializer.toJson<DateTime>(playedAt),
    };
  }

  BattleResult copyWith({
    String? id,
    int? score,
    int? movesReviewed,
    int? goodCount,
    int? hardCount,
    int? againCount,
    int? longestStreak,
    String? difficulty,
    DateTime? playedAt,
  }) => BattleResult(
    id: id ?? this.id,
    score: score ?? this.score,
    movesReviewed: movesReviewed ?? this.movesReviewed,
    goodCount: goodCount ?? this.goodCount,
    hardCount: hardCount ?? this.hardCount,
    againCount: againCount ?? this.againCount,
    longestStreak: longestStreak ?? this.longestStreak,
    difficulty: difficulty ?? this.difficulty,
    playedAt: playedAt ?? this.playedAt,
  );
  BattleResult copyWithCompanion(BattleResultsCompanion data) {
    return BattleResult(
      id: data.id.present ? data.id.value : this.id,
      score: data.score.present ? data.score.value : this.score,
      movesReviewed: data.movesReviewed.present
          ? data.movesReviewed.value
          : this.movesReviewed,
      goodCount: data.goodCount.present ? data.goodCount.value : this.goodCount,
      hardCount: data.hardCount.present ? data.hardCount.value : this.hardCount,
      againCount: data.againCount.present
          ? data.againCount.value
          : this.againCount,
      longestStreak: data.longestStreak.present
          ? data.longestStreak.value
          : this.longestStreak,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      playedAt: data.playedAt.present ? data.playedAt.value : this.playedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BattleResult(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('movesReviewed: $movesReviewed, ')
          ..write('goodCount: $goodCount, ')
          ..write('hardCount: $hardCount, ')
          ..write('againCount: $againCount, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('difficulty: $difficulty, ')
          ..write('playedAt: $playedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    score,
    movesReviewed,
    goodCount,
    hardCount,
    againCount,
    longestStreak,
    difficulty,
    playedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BattleResult &&
          other.id == this.id &&
          other.score == this.score &&
          other.movesReviewed == this.movesReviewed &&
          other.goodCount == this.goodCount &&
          other.hardCount == this.hardCount &&
          other.againCount == this.againCount &&
          other.longestStreak == this.longestStreak &&
          other.difficulty == this.difficulty &&
          other.playedAt == this.playedAt);
}

class BattleResultsCompanion extends UpdateCompanion<BattleResult> {
  final Value<String> id;
  final Value<int> score;
  final Value<int> movesReviewed;
  final Value<int> goodCount;
  final Value<int> hardCount;
  final Value<int> againCount;
  final Value<int> longestStreak;
  final Value<String> difficulty;
  final Value<DateTime> playedAt;
  final Value<int> rowid;
  const BattleResultsCompanion({
    this.id = const Value.absent(),
    this.score = const Value.absent(),
    this.movesReviewed = const Value.absent(),
    this.goodCount = const Value.absent(),
    this.hardCount = const Value.absent(),
    this.againCount = const Value.absent(),
    this.longestStreak = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BattleResultsCompanion.insert({
    required String id,
    required int score,
    required int movesReviewed,
    required int goodCount,
    required int hardCount,
    required int againCount,
    required int longestStreak,
    required String difficulty,
    this.playedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       score = Value(score),
       movesReviewed = Value(movesReviewed),
       goodCount = Value(goodCount),
       hardCount = Value(hardCount),
       againCount = Value(againCount),
       longestStreak = Value(longestStreak),
       difficulty = Value(difficulty);
  static Insertable<BattleResult> custom({
    Expression<String>? id,
    Expression<int>? score,
    Expression<int>? movesReviewed,
    Expression<int>? goodCount,
    Expression<int>? hardCount,
    Expression<int>? againCount,
    Expression<int>? longestStreak,
    Expression<String>? difficulty,
    Expression<DateTime>? playedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (score != null) 'score': score,
      if (movesReviewed != null) 'moves_reviewed': movesReviewed,
      if (goodCount != null) 'good_count': goodCount,
      if (hardCount != null) 'hard_count': hardCount,
      if (againCount != null) 'again_count': againCount,
      if (longestStreak != null) 'longest_streak': longestStreak,
      if (difficulty != null) 'difficulty': difficulty,
      if (playedAt != null) 'played_at': playedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BattleResultsCompanion copyWith({
    Value<String>? id,
    Value<int>? score,
    Value<int>? movesReviewed,
    Value<int>? goodCount,
    Value<int>? hardCount,
    Value<int>? againCount,
    Value<int>? longestStreak,
    Value<String>? difficulty,
    Value<DateTime>? playedAt,
    Value<int>? rowid,
  }) {
    return BattleResultsCompanion(
      id: id ?? this.id,
      score: score ?? this.score,
      movesReviewed: movesReviewed ?? this.movesReviewed,
      goodCount: goodCount ?? this.goodCount,
      hardCount: hardCount ?? this.hardCount,
      againCount: againCount ?? this.againCount,
      longestStreak: longestStreak ?? this.longestStreak,
      difficulty: difficulty ?? this.difficulty,
      playedAt: playedAt ?? this.playedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (score.present) {
      map['score'] = Variable<int>(score.value);
    }
    if (movesReviewed.present) {
      map['moves_reviewed'] = Variable<int>(movesReviewed.value);
    }
    if (goodCount.present) {
      map['good_count'] = Variable<int>(goodCount.value);
    }
    if (hardCount.present) {
      map['hard_count'] = Variable<int>(hardCount.value);
    }
    if (againCount.present) {
      map['again_count'] = Variable<int>(againCount.value);
    }
    if (longestStreak.present) {
      map['longest_streak'] = Variable<int>(longestStreak.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<String>(difficulty.value);
    }
    if (playedAt.present) {
      map['played_at'] = Variable<DateTime>(playedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BattleResultsCompanion(')
          ..write('id: $id, ')
          ..write('score: $score, ')
          ..write('movesReviewed: $movesReviewed, ')
          ..write('goodCount: $goodCount, ')
          ..write('hardCount: $hardCount, ')
          ..write('againCount: $againCount, ')
          ..write('longestStreak: $longestStreak, ')
          ..write('difficulty: $difficulty, ')
          ..write('playedAt: $playedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncLogTable extends SyncLog with TableInfo<$SyncLogTable, SyncLogData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncLogTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTableMeta = const VerificationMeta(
    'entityTable',
  );
  @override
  late final GeneratedColumn<String> entityTable = GeneratedColumn<String>(
    'entity_table',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _actionMeta = const VerificationMeta('action');
  @override
  late final GeneratedColumn<String> action = GeneratedColumn<String>(
    'action',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _changedAtMeta = const VerificationMeta(
    'changedAt',
  );
  @override
  late final GeneratedColumn<DateTime> changedAt = GeneratedColumn<DateTime>(
    'changed_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _syncedMeta = const VerificationMeta('synced');
  @override
  late final GeneratedColumn<bool> synced = GeneratedColumn<bool>(
    'synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("synced" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _videoSyncedMeta = const VerificationMeta(
    'videoSynced',
  );
  @override
  late final GeneratedColumn<bool> videoSynced = GeneratedColumn<bool>(
    'video_synced',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("video_synced" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityId,
    entityTable,
    action,
    changedAt,
    synced,
    videoSynced,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_log';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncLogData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_table')) {
      context.handle(
        _entityTableMeta,
        entityTable.isAcceptableOrUnknown(
          data['entity_table']!,
          _entityTableMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_entityTableMeta);
    }
    if (data.containsKey('action')) {
      context.handle(
        _actionMeta,
        action.isAcceptableOrUnknown(data['action']!, _actionMeta),
      );
    } else if (isInserting) {
      context.missing(_actionMeta);
    }
    if (data.containsKey('changed_at')) {
      context.handle(
        _changedAtMeta,
        changedAt.isAcceptableOrUnknown(data['changed_at']!, _changedAtMeta),
      );
    }
    if (data.containsKey('synced')) {
      context.handle(
        _syncedMeta,
        synced.isAcceptableOrUnknown(data['synced']!, _syncedMeta),
      );
    }
    if (data.containsKey('video_synced')) {
      context.handle(
        _videoSyncedMeta,
        videoSynced.isAcceptableOrUnknown(
          data['video_synced']!,
          _videoSyncedMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId, entityTable, action};
  @override
  SyncLogData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncLogData(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityTable: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_table'],
      )!,
      action: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}action'],
      )!,
      changedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}changed_at'],
      )!,
      synced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}synced'],
      )!,
      videoSynced: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}video_synced'],
      )!,
    );
  }

  @override
  $SyncLogTable createAlias(String alias) {
    return $SyncLogTable(attachedDatabase, alias);
  }
}

class SyncLogData extends DataClass implements Insertable<SyncLogData> {
  final String entityId;
  final String entityTable;
  final String action;
  final DateTime changedAt;
  final bool synced;
  final bool videoSynced;
  const SyncLogData({
    required this.entityId,
    required this.entityTable,
    required this.action,
    required this.changedAt,
    required this.synced,
    required this.videoSynced,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['entity_table'] = Variable<String>(entityTable);
    map['action'] = Variable<String>(action);
    map['changed_at'] = Variable<DateTime>(changedAt);
    map['synced'] = Variable<bool>(synced);
    map['video_synced'] = Variable<bool>(videoSynced);
    return map;
  }

  SyncLogCompanion toCompanion(bool nullToAbsent) {
    return SyncLogCompanion(
      entityId: Value(entityId),
      entityTable: Value(entityTable),
      action: Value(action),
      changedAt: Value(changedAt),
      synced: Value(synced),
      videoSynced: Value(videoSynced),
    );
  }

  factory SyncLogData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncLogData(
      entityId: serializer.fromJson<String>(json['entityId']),
      entityTable: serializer.fromJson<String>(json['entityTable']),
      action: serializer.fromJson<String>(json['action']),
      changedAt: serializer.fromJson<DateTime>(json['changedAt']),
      synced: serializer.fromJson<bool>(json['synced']),
      videoSynced: serializer.fromJson<bool>(json['videoSynced']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'entityTable': serializer.toJson<String>(entityTable),
      'action': serializer.toJson<String>(action),
      'changedAt': serializer.toJson<DateTime>(changedAt),
      'synced': serializer.toJson<bool>(synced),
      'videoSynced': serializer.toJson<bool>(videoSynced),
    };
  }

  SyncLogData copyWith({
    String? entityId,
    String? entityTable,
    String? action,
    DateTime? changedAt,
    bool? synced,
    bool? videoSynced,
  }) => SyncLogData(
    entityId: entityId ?? this.entityId,
    entityTable: entityTable ?? this.entityTable,
    action: action ?? this.action,
    changedAt: changedAt ?? this.changedAt,
    synced: synced ?? this.synced,
    videoSynced: videoSynced ?? this.videoSynced,
  );
  SyncLogData copyWithCompanion(SyncLogCompanion data) {
    return SyncLogData(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityTable: data.entityTable.present
          ? data.entityTable.value
          : this.entityTable,
      action: data.action.present ? data.action.value : this.action,
      changedAt: data.changedAt.present ? data.changedAt.value : this.changedAt,
      synced: data.synced.present ? data.synced.value : this.synced,
      videoSynced: data.videoSynced.present
          ? data.videoSynced.value
          : this.videoSynced,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogData(')
          ..write('entityId: $entityId, ')
          ..write('entityTable: $entityTable, ')
          ..write('action: $action, ')
          ..write('changedAt: $changedAt, ')
          ..write('synced: $synced, ')
          ..write('videoSynced: $videoSynced')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entityId,
    entityTable,
    action,
    changedAt,
    synced,
    videoSynced,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncLogData &&
          other.entityId == this.entityId &&
          other.entityTable == this.entityTable &&
          other.action == this.action &&
          other.changedAt == this.changedAt &&
          other.synced == this.synced &&
          other.videoSynced == this.videoSynced);
}

class SyncLogCompanion extends UpdateCompanion<SyncLogData> {
  final Value<String> entityId;
  final Value<String> entityTable;
  final Value<String> action;
  final Value<DateTime> changedAt;
  final Value<bool> synced;
  final Value<bool> videoSynced;
  final Value<int> rowid;
  const SyncLogCompanion({
    this.entityId = const Value.absent(),
    this.entityTable = const Value.absent(),
    this.action = const Value.absent(),
    this.changedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.videoSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncLogCompanion.insert({
    required String entityId,
    required String entityTable,
    required String action,
    this.changedAt = const Value.absent(),
    this.synced = const Value.absent(),
    this.videoSynced = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId),
       entityTable = Value(entityTable),
       action = Value(action);
  static Insertable<SyncLogData> custom({
    Expression<String>? entityId,
    Expression<String>? entityTable,
    Expression<String>? action,
    Expression<DateTime>? changedAt,
    Expression<bool>? synced,
    Expression<bool>? videoSynced,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (entityTable != null) 'entity_table': entityTable,
      if (action != null) 'action': action,
      if (changedAt != null) 'changed_at': changedAt,
      if (synced != null) 'synced': synced,
      if (videoSynced != null) 'video_synced': videoSynced,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncLogCompanion copyWith({
    Value<String>? entityId,
    Value<String>? entityTable,
    Value<String>? action,
    Value<DateTime>? changedAt,
    Value<bool>? synced,
    Value<bool>? videoSynced,
    Value<int>? rowid,
  }) {
    return SyncLogCompanion(
      entityId: entityId ?? this.entityId,
      entityTable: entityTable ?? this.entityTable,
      action: action ?? this.action,
      changedAt: changedAt ?? this.changedAt,
      synced: synced ?? this.synced,
      videoSynced: videoSynced ?? this.videoSynced,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityTable.present) {
      map['entity_table'] = Variable<String>(entityTable.value);
    }
    if (action.present) {
      map['action'] = Variable<String>(action.value);
    }
    if (changedAt.present) {
      map['changed_at'] = Variable<DateTime>(changedAt.value);
    }
    if (synced.present) {
      map['synced'] = Variable<bool>(synced.value);
    }
    if (videoSynced.present) {
      map['video_synced'] = Variable<bool>(videoSynced.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncLogCompanion(')
          ..write('entityId: $entityId, ')
          ..write('entityTable: $entityTable, ')
          ..write('action: $action, ')
          ..write('changedAt: $changedAt, ')
          ..write('synced: $synced, ')
          ..write('videoSynced: $videoSynced, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $FsrsCardsTable extends FsrsCards
    with TableInfo<$FsrsCardsTable, FsrsCard> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $FsrsCardsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('move'),
  );
  static const VerificationMeta _stabilityMeta = const VerificationMeta(
    'stability',
  );
  @override
  late final GeneratedColumn<double> stability = GeneratedColumn<double>(
    'stability',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _difficultyMeta = const VerificationMeta(
    'difficulty',
  );
  @override
  late final GeneratedColumn<double> difficulty = GeneratedColumn<double>(
    'difficulty',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
    defaultValue: const Constant(0.0),
  );
  static const VerificationMeta _dueMeta = const VerificationMeta('due');
  @override
  late final GeneratedColumn<DateTime> due = GeneratedColumn<DateTime>(
    'due',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _lastReviewMeta = const VerificationMeta(
    'lastReview',
  );
  @override
  late final GeneratedColumn<DateTime> lastReview = GeneratedColumn<DateTime>(
    'last_review',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _repsMeta = const VerificationMeta('reps');
  @override
  late final GeneratedColumn<int> reps = GeneratedColumn<int>(
    'reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _lapsesMeta = const VerificationMeta('lapses');
  @override
  late final GeneratedColumn<int> lapses = GeneratedColumn<int>(
    'lapses',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _fsrsStateMeta = const VerificationMeta(
    'fsrsState',
  );
  @override
  late final GeneratedColumn<int> fsrsState = GeneratedColumn<int>(
    'fsrs_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  List<GeneratedColumn> get $columns => [
    entityId,
    entityType,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    fsrsState,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'fsrs_cards';
  @override
  VerificationContext validateIntegrity(
    Insertable<FsrsCard> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    }
    if (data.containsKey('stability')) {
      context.handle(
        _stabilityMeta,
        stability.isAcceptableOrUnknown(data['stability']!, _stabilityMeta),
      );
    }
    if (data.containsKey('difficulty')) {
      context.handle(
        _difficultyMeta,
        difficulty.isAcceptableOrUnknown(data['difficulty']!, _difficultyMeta),
      );
    }
    if (data.containsKey('due')) {
      context.handle(
        _dueMeta,
        due.isAcceptableOrUnknown(data['due']!, _dueMeta),
      );
    }
    if (data.containsKey('last_review')) {
      context.handle(
        _lastReviewMeta,
        lastReview.isAcceptableOrUnknown(data['last_review']!, _lastReviewMeta),
      );
    }
    if (data.containsKey('reps')) {
      context.handle(
        _repsMeta,
        reps.isAcceptableOrUnknown(data['reps']!, _repsMeta),
      );
    }
    if (data.containsKey('lapses')) {
      context.handle(
        _lapsesMeta,
        lapses.isAcceptableOrUnknown(data['lapses']!, _lapsesMeta),
      );
    }
    if (data.containsKey('fsrs_state')) {
      context.handle(
        _fsrsStateMeta,
        fsrsState.isAcceptableOrUnknown(data['fsrs_state']!, _fsrsStateMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {entityId, entityType};
  @override
  FsrsCard map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return FsrsCard(
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      stability: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}stability'],
      )!,
      difficulty: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}difficulty'],
      )!,
      due: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}due'],
      )!,
      lastReview: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_review'],
      ),
      reps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reps'],
      )!,
      lapses: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lapses'],
      )!,
      fsrsState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}fsrs_state'],
      )!,
    );
  }

  @override
  $FsrsCardsTable createAlias(String alias) {
    return $FsrsCardsTable(attachedDatabase, alias);
  }
}

class FsrsCard extends DataClass implements Insertable<FsrsCard> {
  /// ID of the move or combo this card belongs to.
  final String entityId;

  /// Entity type: 'move' or 'combo'. Defaults to 'move' for backward compat.
  final String entityType;

  /// Memory stability in days — higher means longer retention.
  final double stability;

  /// Item difficulty on a 0–10 scale — higher means harder to remember.
  final double difficulty;

  /// When this card is next due for review (UTC).
  final DateTime due;

  /// When this card was last reviewed (UTC). Null if never reviewed.
  final DateTime? lastReview;

  /// Consecutive successful reviews (resets on lapse).
  final int reps;

  /// Number of times the card lapsed (was forgotten after graduating).
  final int lapses;

  /// FSRS state: 0=New, 1=Learning, 2=Review, 3=Relearning.
  final int fsrsState;
  const FsrsCard({
    required this.entityId,
    required this.entityType,
    required this.stability,
    required this.difficulty,
    required this.due,
    this.lastReview,
    required this.reps,
    required this.lapses,
    required this.fsrsState,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['entity_id'] = Variable<String>(entityId);
    map['entity_type'] = Variable<String>(entityType);
    map['stability'] = Variable<double>(stability);
    map['difficulty'] = Variable<double>(difficulty);
    map['due'] = Variable<DateTime>(due);
    if (!nullToAbsent || lastReview != null) {
      map['last_review'] = Variable<DateTime>(lastReview);
    }
    map['reps'] = Variable<int>(reps);
    map['lapses'] = Variable<int>(lapses);
    map['fsrs_state'] = Variable<int>(fsrsState);
    return map;
  }

  FsrsCardsCompanion toCompanion(bool nullToAbsent) {
    return FsrsCardsCompanion(
      entityId: Value(entityId),
      entityType: Value(entityType),
      stability: Value(stability),
      difficulty: Value(difficulty),
      due: Value(due),
      lastReview: lastReview == null && nullToAbsent
          ? const Value.absent()
          : Value(lastReview),
      reps: Value(reps),
      lapses: Value(lapses),
      fsrsState: Value(fsrsState),
    );
  }

  factory FsrsCard.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return FsrsCard(
      entityId: serializer.fromJson<String>(json['entityId']),
      entityType: serializer.fromJson<String>(json['entityType']),
      stability: serializer.fromJson<double>(json['stability']),
      difficulty: serializer.fromJson<double>(json['difficulty']),
      due: serializer.fromJson<DateTime>(json['due']),
      lastReview: serializer.fromJson<DateTime?>(json['lastReview']),
      reps: serializer.fromJson<int>(json['reps']),
      lapses: serializer.fromJson<int>(json['lapses']),
      fsrsState: serializer.fromJson<int>(json['fsrsState']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'entityId': serializer.toJson<String>(entityId),
      'entityType': serializer.toJson<String>(entityType),
      'stability': serializer.toJson<double>(stability),
      'difficulty': serializer.toJson<double>(difficulty),
      'due': serializer.toJson<DateTime>(due),
      'lastReview': serializer.toJson<DateTime?>(lastReview),
      'reps': serializer.toJson<int>(reps),
      'lapses': serializer.toJson<int>(lapses),
      'fsrsState': serializer.toJson<int>(fsrsState),
    };
  }

  FsrsCard copyWith({
    String? entityId,
    String? entityType,
    double? stability,
    double? difficulty,
    DateTime? due,
    Value<DateTime?> lastReview = const Value.absent(),
    int? reps,
    int? lapses,
    int? fsrsState,
  }) => FsrsCard(
    entityId: entityId ?? this.entityId,
    entityType: entityType ?? this.entityType,
    stability: stability ?? this.stability,
    difficulty: difficulty ?? this.difficulty,
    due: due ?? this.due,
    lastReview: lastReview.present ? lastReview.value : this.lastReview,
    reps: reps ?? this.reps,
    lapses: lapses ?? this.lapses,
    fsrsState: fsrsState ?? this.fsrsState,
  );
  FsrsCard copyWithCompanion(FsrsCardsCompanion data) {
    return FsrsCard(
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      stability: data.stability.present ? data.stability.value : this.stability,
      difficulty: data.difficulty.present
          ? data.difficulty.value
          : this.difficulty,
      due: data.due.present ? data.due.value : this.due,
      lastReview: data.lastReview.present
          ? data.lastReview.value
          : this.lastReview,
      reps: data.reps.present ? data.reps.value : this.reps,
      lapses: data.lapses.present ? data.lapses.value : this.lapses,
      fsrsState: data.fsrsState.present ? data.fsrsState.value : this.fsrsState,
    );
  }

  @override
  String toString() {
    return (StringBuffer('FsrsCard(')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('fsrsState: $fsrsState')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    entityId,
    entityType,
    stability,
    difficulty,
    due,
    lastReview,
    reps,
    lapses,
    fsrsState,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is FsrsCard &&
          other.entityId == this.entityId &&
          other.entityType == this.entityType &&
          other.stability == this.stability &&
          other.difficulty == this.difficulty &&
          other.due == this.due &&
          other.lastReview == this.lastReview &&
          other.reps == this.reps &&
          other.lapses == this.lapses &&
          other.fsrsState == this.fsrsState);
}

class FsrsCardsCompanion extends UpdateCompanion<FsrsCard> {
  final Value<String> entityId;
  final Value<String> entityType;
  final Value<double> stability;
  final Value<double> difficulty;
  final Value<DateTime> due;
  final Value<DateTime?> lastReview;
  final Value<int> reps;
  final Value<int> lapses;
  final Value<int> fsrsState;
  final Value<int> rowid;
  const FsrsCardsCompanion({
    this.entityId = const Value.absent(),
    this.entityType = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  FsrsCardsCompanion.insert({
    required String entityId,
    this.entityType = const Value.absent(),
    this.stability = const Value.absent(),
    this.difficulty = const Value.absent(),
    this.due = const Value.absent(),
    this.lastReview = const Value.absent(),
    this.reps = const Value.absent(),
    this.lapses = const Value.absent(),
    this.fsrsState = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : entityId = Value(entityId);
  static Insertable<FsrsCard> custom({
    Expression<String>? entityId,
    Expression<String>? entityType,
    Expression<double>? stability,
    Expression<double>? difficulty,
    Expression<DateTime>? due,
    Expression<DateTime>? lastReview,
    Expression<int>? reps,
    Expression<int>? lapses,
    Expression<int>? fsrsState,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (entityId != null) 'entity_id': entityId,
      if (entityType != null) 'entity_type': entityType,
      if (stability != null) 'stability': stability,
      if (difficulty != null) 'difficulty': difficulty,
      if (due != null) 'due': due,
      if (lastReview != null) 'last_review': lastReview,
      if (reps != null) 'reps': reps,
      if (lapses != null) 'lapses': lapses,
      if (fsrsState != null) 'fsrs_state': fsrsState,
      if (rowid != null) 'rowid': rowid,
    });
  }

  FsrsCardsCompanion copyWith({
    Value<String>? entityId,
    Value<String>? entityType,
    Value<double>? stability,
    Value<double>? difficulty,
    Value<DateTime>? due,
    Value<DateTime?>? lastReview,
    Value<int>? reps,
    Value<int>? lapses,
    Value<int>? fsrsState,
    Value<int>? rowid,
  }) {
    return FsrsCardsCompanion(
      entityId: entityId ?? this.entityId,
      entityType: entityType ?? this.entityType,
      stability: stability ?? this.stability,
      difficulty: difficulty ?? this.difficulty,
      due: due ?? this.due,
      lastReview: lastReview ?? this.lastReview,
      reps: reps ?? this.reps,
      lapses: lapses ?? this.lapses,
      fsrsState: fsrsState ?? this.fsrsState,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (stability.present) {
      map['stability'] = Variable<double>(stability.value);
    }
    if (difficulty.present) {
      map['difficulty'] = Variable<double>(difficulty.value);
    }
    if (due.present) {
      map['due'] = Variable<DateTime>(due.value);
    }
    if (lastReview.present) {
      map['last_review'] = Variable<DateTime>(lastReview.value);
    }
    if (reps.present) {
      map['reps'] = Variable<int>(reps.value);
    }
    if (lapses.present) {
      map['lapses'] = Variable<int>(lapses.value);
    }
    if (fsrsState.present) {
      map['fsrs_state'] = Variable<int>(fsrsState.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('FsrsCardsCompanion(')
          ..write('entityId: $entityId, ')
          ..write('entityType: $entityType, ')
          ..write('stability: $stability, ')
          ..write('difficulty: $difficulty, ')
          ..write('due: $due, ')
          ..write('lastReview: $lastReview, ')
          ..write('reps: $reps, ')
          ..write('lapses: $lapses, ')
          ..write('fsrsState: $fsrsState, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DecksTable extends Decks with TableInfo<$DecksTable, Deck> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DecksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deckTypeMeta = const VerificationMeta(
    'deckType',
  );
  @override
  late final GeneratedColumn<String> deckType = GeneratedColumn<String>(
    'deck_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('smart'),
  );
  static const VerificationMeta _filterCriteriaMeta = const VerificationMeta(
    'filterCriteria',
  );
  @override
  late final GeneratedColumn<String> filterCriteria = GeneratedColumn<String>(
    'filter_criteria',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sessionSizeMeta = const VerificationMeta(
    'sessionSize',
  );
  @override
  late final GeneratedColumn<int> sessionSize = GeneratedColumn<int>(
    'session_size',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    deckType,
    filterCriteria,
    sessionSize,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'decks';
  @override
  VerificationContext validateIntegrity(
    Insertable<Deck> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('deck_type')) {
      context.handle(
        _deckTypeMeta,
        deckType.isAcceptableOrUnknown(data['deck_type']!, _deckTypeMeta),
      );
    }
    if (data.containsKey('filter_criteria')) {
      context.handle(
        _filterCriteriaMeta,
        filterCriteria.isAcceptableOrUnknown(
          data['filter_criteria']!,
          _filterCriteriaMeta,
        ),
      );
    }
    if (data.containsKey('session_size')) {
      context.handle(
        _sessionSizeMeta,
        sessionSize.isAcceptableOrUnknown(
          data['session_size']!,
          _sessionSizeMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Deck map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Deck(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      deckType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_type'],
      )!,
      filterCriteria: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}filter_criteria'],
      ),
      sessionSize: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}session_size'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $DecksTable createAlias(String alias) {
    return $DecksTable(attachedDatabase, alias);
  }
}

class Deck extends DataClass implements Insertable<Deck> {
  final String id;
  final String name;

  /// 'smart' or 'manual'
  final String deckType;

  /// JSON-encoded filter criteria for smart decks.
  /// Format: {"categories": [...], "fsrsStates": [...], "dueOnly": bool}
  /// Null for manual decks.
  final String? filterCriteria;

  /// Optional session size override. Null = all matching moves.
  final int? sessionSize;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Deck({
    required this.id,
    required this.name,
    required this.deckType,
    this.filterCriteria,
    this.sessionSize,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['deck_type'] = Variable<String>(deckType);
    if (!nullToAbsent || filterCriteria != null) {
      map['filter_criteria'] = Variable<String>(filterCriteria);
    }
    if (!nullToAbsent || sessionSize != null) {
      map['session_size'] = Variable<int>(sessionSize);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  DecksCompanion toCompanion(bool nullToAbsent) {
    return DecksCompanion(
      id: Value(id),
      name: Value(name),
      deckType: Value(deckType),
      filterCriteria: filterCriteria == null && nullToAbsent
          ? const Value.absent()
          : Value(filterCriteria),
      sessionSize: sessionSize == null && nullToAbsent
          ? const Value.absent()
          : Value(sessionSize),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Deck.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Deck(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      deckType: serializer.fromJson<String>(json['deckType']),
      filterCriteria: serializer.fromJson<String?>(json['filterCriteria']),
      sessionSize: serializer.fromJson<int?>(json['sessionSize']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'deckType': serializer.toJson<String>(deckType),
      'filterCriteria': serializer.toJson<String?>(filterCriteria),
      'sessionSize': serializer.toJson<int?>(sessionSize),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Deck copyWith({
    String? id,
    String? name,
    String? deckType,
    Value<String?> filterCriteria = const Value.absent(),
    Value<int?> sessionSize = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Deck(
    id: id ?? this.id,
    name: name ?? this.name,
    deckType: deckType ?? this.deckType,
    filterCriteria: filterCriteria.present
        ? filterCriteria.value
        : this.filterCriteria,
    sessionSize: sessionSize.present ? sessionSize.value : this.sessionSize,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Deck copyWithCompanion(DecksCompanion data) {
    return Deck(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      deckType: data.deckType.present ? data.deckType.value : this.deckType,
      filterCriteria: data.filterCriteria.present
          ? data.filterCriteria.value
          : this.filterCriteria,
      sessionSize: data.sessionSize.present
          ? data.sessionSize.value
          : this.sessionSize,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Deck(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deckType: $deckType, ')
          ..write('filterCriteria: $filterCriteria, ')
          ..write('sessionSize: $sessionSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    name,
    deckType,
    filterCriteria,
    sessionSize,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Deck &&
          other.id == this.id &&
          other.name == this.name &&
          other.deckType == this.deckType &&
          other.filterCriteria == this.filterCriteria &&
          other.sessionSize == this.sessionSize &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class DecksCompanion extends UpdateCompanion<Deck> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> deckType;
  final Value<String?> filterCriteria;
  final Value<int?> sessionSize;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const DecksCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.deckType = const Value.absent(),
    this.filterCriteria = const Value.absent(),
    this.sessionSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DecksCompanion.insert({
    required String id,
    required String name,
    this.deckType = const Value.absent(),
    this.filterCriteria = const Value.absent(),
    this.sessionSize = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Deck> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? deckType,
    Expression<String>? filterCriteria,
    Expression<int>? sessionSize,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (deckType != null) 'deck_type': deckType,
      if (filterCriteria != null) 'filter_criteria': filterCriteria,
      if (sessionSize != null) 'session_size': sessionSize,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DecksCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? deckType,
    Value<String?>? filterCriteria,
    Value<int?>? sessionSize,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return DecksCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      deckType: deckType ?? this.deckType,
      filterCriteria: filterCriteria ?? this.filterCriteria,
      sessionSize: sessionSize ?? this.sessionSize,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (deckType.present) {
      map['deck_type'] = Variable<String>(deckType.value);
    }
    if (filterCriteria.present) {
      map['filter_criteria'] = Variable<String>(filterCriteria.value);
    }
    if (sessionSize.present) {
      map['session_size'] = Variable<int>(sessionSize.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DecksCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('deckType: $deckType, ')
          ..write('filterCriteria: $filterCriteria, ')
          ..write('sessionSize: $sessionSize, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeckMovesTable extends DeckMoves
    with TableInfo<$DeckMovesTable, DeckMove> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeckMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _deckIdMeta = const VerificationMeta('deckId');
  @override
  late final GeneratedColumn<String> deckId = GeneratedColumn<String>(
    'deck_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES decks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  @override
  List<GeneratedColumn> get $columns => [deckId, moveId];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deck_moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeckMove> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('deck_id')) {
      context.handle(
        _deckIdMeta,
        deckId.isAcceptableOrUnknown(data['deck_id']!, _deckIdMeta),
      );
    } else if (isInserting) {
      context.missing(_deckIdMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {deckId, moveId};
  @override
  DeckMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeckMove(
      deckId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deck_id'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      )!,
    );
  }

  @override
  $DeckMovesTable createAlias(String alias) {
    return $DeckMovesTable(attachedDatabase, alias);
  }
}

class DeckMove extends DataClass implements Insertable<DeckMove> {
  final String deckId;
  final String moveId;
  const DeckMove({required this.deckId, required this.moveId});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['deck_id'] = Variable<String>(deckId);
    map['move_id'] = Variable<String>(moveId);
    return map;
  }

  DeckMovesCompanion toCompanion(bool nullToAbsent) {
    return DeckMovesCompanion(deckId: Value(deckId), moveId: Value(moveId));
  }

  factory DeckMove.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeckMove(
      deckId: serializer.fromJson<String>(json['deckId']),
      moveId: serializer.fromJson<String>(json['moveId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'deckId': serializer.toJson<String>(deckId),
      'moveId': serializer.toJson<String>(moveId),
    };
  }

  DeckMove copyWith({String? deckId, String? moveId}) =>
      DeckMove(deckId: deckId ?? this.deckId, moveId: moveId ?? this.moveId);
  DeckMove copyWithCompanion(DeckMovesCompanion data) {
    return DeckMove(
      deckId: data.deckId.present ? data.deckId.value : this.deckId,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeckMove(')
          ..write('deckId: $deckId, ')
          ..write('moveId: $moveId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(deckId, moveId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeckMove &&
          other.deckId == this.deckId &&
          other.moveId == this.moveId);
}

class DeckMovesCompanion extends UpdateCompanion<DeckMove> {
  final Value<String> deckId;
  final Value<String> moveId;
  final Value<int> rowid;
  const DeckMovesCompanion({
    this.deckId = const Value.absent(),
    this.moveId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeckMovesCompanion.insert({
    required String deckId,
    required String moveId,
    this.rowid = const Value.absent(),
  }) : deckId = Value(deckId),
       moveId = Value(moveId);
  static Insertable<DeckMove> custom({
    Expression<String>? deckId,
    Expression<String>? moveId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (deckId != null) 'deck_id': deckId,
      if (moveId != null) 'move_id': moveId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeckMovesCompanion copyWith({
    Value<String>? deckId,
    Value<String>? moveId,
    Value<int>? rowid,
  }) {
    return DeckMovesCompanion(
      deckId: deckId ?? this.deckId,
      moveId: moveId ?? this.moveId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (deckId.present) {
      map['deck_id'] = Variable<String>(deckId.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeckMovesCompanion(')
          ..write('deckId: $deckId, ')
          ..write('moveId: $moveId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetManifestTable extends AssetManifest
    with TableInfo<$AssetManifestTable, AssetManifestData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetManifestTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _fileSizeBytesMeta = const VerificationMeta(
    'fileSizeBytes',
  );
  @override
  late final GeneratedColumn<int> fileSizeBytes = GeneratedColumn<int>(
    'file_size_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _mimeTypeMeta = const VerificationMeta(
    'mimeType',
  );
  @override
  late final GeneratedColumn<String> mimeType = GeneratedColumn<String>(
    'mime_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('video/mp4'),
  );
  static const VerificationMeta _durationMsMeta = const VerificationMeta(
    'durationMs',
  );
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
    'duration_ms',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _widthMeta = const VerificationMeta('width');
  @override
  late final GeneratedColumn<int> width = GeneratedColumn<int>(
    'width',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _heightMeta = const VerificationMeta('height');
  @override
  late final GeneratedColumn<int> height = GeneratedColumn<int>(
    'height',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localPathMeta = const VerificationMeta(
    'localPath',
  );
  @override
  late final GeneratedColumn<String> localPath = GeneratedColumn<String>(
    'local_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _localVerifiedAtMeta = const VerificationMeta(
    'localVerifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> localVerifiedAt =
      GeneratedColumn<DateTime>(
        'local_verified_at',
        aliasedName,
        true,
        type: DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _sourceTypeMeta = const VerificationMeta(
    'sourceType',
  );
  @override
  late final GeneratedColumn<String> sourceType = GeneratedColumn<String>(
    'source_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceNameMeta = const VerificationMeta(
    'sourceName',
  );
  @override
  late final GeneratedColumn<String> sourceName = GeneratedColumn<String>(
    'source_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _importedAtMeta = const VerificationMeta(
    'importedAt',
  );
  @override
  late final GeneratedColumn<DateTime> importedAt = GeneratedColumn<DateTime>(
    'imported_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _deletedAtMeta = const VerificationMeta(
    'deletedAt',
  );
  @override
  late final GeneratedColumn<DateTime> deletedAt = GeneratedColumn<DateTime>(
    'deleted_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _tombstoneReasonMeta = const VerificationMeta(
    'tombstoneReason',
  );
  @override
  late final GeneratedColumn<String> tombstoneReason = GeneratedColumn<String>(
    'tombstone_reason',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _copyCountMeta = const VerificationMeta(
    'copyCount',
  );
  @override
  late final GeneratedColumn<int> copyCount = GeneratedColumn<int>(
    'copy_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  static const VerificationMeta _lastSyncAtMeta = const VerificationMeta(
    'lastSyncAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastSyncAt = GeneratedColumn<DateTime>(
    'last_sync_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    contentHash,
    fileSizeBytes,
    mimeType,
    durationMs,
    width,
    height,
    localPath,
    localVerifiedAt,
    sourceType,
    sourceName,
    importedAt,
    deletedAt,
    tombstoneReason,
    copyCount,
    lastSyncAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_manifest';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetManifestData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('file_size_bytes')) {
      context.handle(
        _fileSizeBytesMeta,
        fileSizeBytes.isAcceptableOrUnknown(
          data['file_size_bytes']!,
          _fileSizeBytesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fileSizeBytesMeta);
    }
    if (data.containsKey('mime_type')) {
      context.handle(
        _mimeTypeMeta,
        mimeType.isAcceptableOrUnknown(data['mime_type']!, _mimeTypeMeta),
      );
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
        _durationMsMeta,
        durationMs.isAcceptableOrUnknown(data['duration_ms']!, _durationMsMeta),
      );
    }
    if (data.containsKey('width')) {
      context.handle(
        _widthMeta,
        width.isAcceptableOrUnknown(data['width']!, _widthMeta),
      );
    }
    if (data.containsKey('height')) {
      context.handle(
        _heightMeta,
        height.isAcceptableOrUnknown(data['height']!, _heightMeta),
      );
    }
    if (data.containsKey('local_path')) {
      context.handle(
        _localPathMeta,
        localPath.isAcceptableOrUnknown(data['local_path']!, _localPathMeta),
      );
    }
    if (data.containsKey('local_verified_at')) {
      context.handle(
        _localVerifiedAtMeta,
        localVerifiedAt.isAcceptableOrUnknown(
          data['local_verified_at']!,
          _localVerifiedAtMeta,
        ),
      );
    }
    if (data.containsKey('source_type')) {
      context.handle(
        _sourceTypeMeta,
        sourceType.isAcceptableOrUnknown(data['source_type']!, _sourceTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceTypeMeta);
    }
    if (data.containsKey('source_name')) {
      context.handle(
        _sourceNameMeta,
        sourceName.isAcceptableOrUnknown(data['source_name']!, _sourceNameMeta),
      );
    }
    if (data.containsKey('imported_at')) {
      context.handle(
        _importedAtMeta,
        importedAt.isAcceptableOrUnknown(data['imported_at']!, _importedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_importedAtMeta);
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    if (data.containsKey('tombstone_reason')) {
      context.handle(
        _tombstoneReasonMeta,
        tombstoneReason.isAcceptableOrUnknown(
          data['tombstone_reason']!,
          _tombstoneReasonMeta,
        ),
      );
    }
    if (data.containsKey('copy_count')) {
      context.handle(
        _copyCountMeta,
        copyCount.isAcceptableOrUnknown(data['copy_count']!, _copyCountMeta),
      );
    }
    if (data.containsKey('last_sync_at')) {
      context.handle(
        _lastSyncAtMeta,
        lastSyncAt.isAcceptableOrUnknown(
          data['last_sync_at']!,
          _lastSyncAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {contentHash};
  @override
  AssetManifestData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetManifestData(
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      fileSizeBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}file_size_bytes'],
      )!,
      mimeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}mime_type'],
      )!,
      durationMs: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}duration_ms'],
      ),
      width: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}width'],
      ),
      height: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}height'],
      ),
      localPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_path'],
      ),
      localVerifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}local_verified_at'],
      ),
      sourceType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_type'],
      )!,
      sourceName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_name'],
      ),
      importedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}imported_at'],
      )!,
      deletedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}deleted_at'],
      ),
      tombstoneReason: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tombstone_reason'],
      ),
      copyCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}copy_count'],
      )!,
      lastSyncAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_sync_at'],
      ),
    );
  }

  @override
  $AssetManifestTable createAlias(String alias) {
    return $AssetManifestTable(attachedDatabase, alias);
  }
}

class AssetManifestData extends DataClass
    implements Insertable<AssetManifestData> {
  /// SHA-256 hex digest of the file contents — serves as the primary key.
  final String contentHash;

  /// File size in bytes at import time.
  final int fileSizeBytes;

  /// MIME type, defaults to video/mp4 for breakdance training clips.
  final String mimeType;

  /// Video duration in milliseconds (populated from metadata when available).
  final int? durationMs;

  /// Video width in pixels.
  final int? width;

  /// Video height in pixels.
  final int? height;

  /// Absolute path to the local copy (null if only exists in cloud).
  final String? localPath;

  /// Last time the local file was verified to match [contentHash].
  final DateTime? localVerifiedAt;

  /// How this asset entered the library.
  /// Values: camera, photos, files, cloud_download, legacy_migration
  final String sourceType;

  /// Human-readable source name (e.g. original filename, album name).
  final String? sourceName;

  /// When this asset was first imported into the library.
  final DateTime importedAt;

  /// Soft-delete timestamp. Non-null means the asset is in the "trash".
  /// The file is retained for a 30-day grace period before hard deletion.
  final DateTime? deletedAt;

  /// Why the asset was soft-deleted: user, replaced, corrupted.
  final String? tombstoneReason;

  /// Number of verified copies (local + cloud). Must be >= 2 before local
  /// deletion is permitted.
  final int copyCount;

  /// Last time any copy was synced to a cloud provider.
  final DateTime? lastSyncAt;
  const AssetManifestData({
    required this.contentHash,
    required this.fileSizeBytes,
    required this.mimeType,
    this.durationMs,
    this.width,
    this.height,
    this.localPath,
    this.localVerifiedAt,
    required this.sourceType,
    this.sourceName,
    required this.importedAt,
    this.deletedAt,
    this.tombstoneReason,
    required this.copyCount,
    this.lastSyncAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['content_hash'] = Variable<String>(contentHash);
    map['file_size_bytes'] = Variable<int>(fileSizeBytes);
    map['mime_type'] = Variable<String>(mimeType);
    if (!nullToAbsent || durationMs != null) {
      map['duration_ms'] = Variable<int>(durationMs);
    }
    if (!nullToAbsent || width != null) {
      map['width'] = Variable<int>(width);
    }
    if (!nullToAbsent || height != null) {
      map['height'] = Variable<int>(height);
    }
    if (!nullToAbsent || localPath != null) {
      map['local_path'] = Variable<String>(localPath);
    }
    if (!nullToAbsent || localVerifiedAt != null) {
      map['local_verified_at'] = Variable<DateTime>(localVerifiedAt);
    }
    map['source_type'] = Variable<String>(sourceType);
    if (!nullToAbsent || sourceName != null) {
      map['source_name'] = Variable<String>(sourceName);
    }
    map['imported_at'] = Variable<DateTime>(importedAt);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<DateTime>(deletedAt);
    }
    if (!nullToAbsent || tombstoneReason != null) {
      map['tombstone_reason'] = Variable<String>(tombstoneReason);
    }
    map['copy_count'] = Variable<int>(copyCount);
    if (!nullToAbsent || lastSyncAt != null) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt);
    }
    return map;
  }

  AssetManifestCompanion toCompanion(bool nullToAbsent) {
    return AssetManifestCompanion(
      contentHash: Value(contentHash),
      fileSizeBytes: Value(fileSizeBytes),
      mimeType: Value(mimeType),
      durationMs: durationMs == null && nullToAbsent
          ? const Value.absent()
          : Value(durationMs),
      width: width == null && nullToAbsent
          ? const Value.absent()
          : Value(width),
      height: height == null && nullToAbsent
          ? const Value.absent()
          : Value(height),
      localPath: localPath == null && nullToAbsent
          ? const Value.absent()
          : Value(localPath),
      localVerifiedAt: localVerifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(localVerifiedAt),
      sourceType: Value(sourceType),
      sourceName: sourceName == null && nullToAbsent
          ? const Value.absent()
          : Value(sourceName),
      importedAt: Value(importedAt),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
      tombstoneReason: tombstoneReason == null && nullToAbsent
          ? const Value.absent()
          : Value(tombstoneReason),
      copyCount: Value(copyCount),
      lastSyncAt: lastSyncAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastSyncAt),
    );
  }

  factory AssetManifestData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetManifestData(
      contentHash: serializer.fromJson<String>(json['contentHash']),
      fileSizeBytes: serializer.fromJson<int>(json['fileSizeBytes']),
      mimeType: serializer.fromJson<String>(json['mimeType']),
      durationMs: serializer.fromJson<int?>(json['durationMs']),
      width: serializer.fromJson<int?>(json['width']),
      height: serializer.fromJson<int?>(json['height']),
      localPath: serializer.fromJson<String?>(json['localPath']),
      localVerifiedAt: serializer.fromJson<DateTime?>(json['localVerifiedAt']),
      sourceType: serializer.fromJson<String>(json['sourceType']),
      sourceName: serializer.fromJson<String?>(json['sourceName']),
      importedAt: serializer.fromJson<DateTime>(json['importedAt']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
      tombstoneReason: serializer.fromJson<String?>(json['tombstoneReason']),
      copyCount: serializer.fromJson<int>(json['copyCount']),
      lastSyncAt: serializer.fromJson<DateTime?>(json['lastSyncAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'contentHash': serializer.toJson<String>(contentHash),
      'fileSizeBytes': serializer.toJson<int>(fileSizeBytes),
      'mimeType': serializer.toJson<String>(mimeType),
      'durationMs': serializer.toJson<int?>(durationMs),
      'width': serializer.toJson<int?>(width),
      'height': serializer.toJson<int?>(height),
      'localPath': serializer.toJson<String?>(localPath),
      'localVerifiedAt': serializer.toJson<DateTime?>(localVerifiedAt),
      'sourceType': serializer.toJson<String>(sourceType),
      'sourceName': serializer.toJson<String?>(sourceName),
      'importedAt': serializer.toJson<DateTime>(importedAt),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
      'tombstoneReason': serializer.toJson<String?>(tombstoneReason),
      'copyCount': serializer.toJson<int>(copyCount),
      'lastSyncAt': serializer.toJson<DateTime?>(lastSyncAt),
    };
  }

  AssetManifestData copyWith({
    String? contentHash,
    int? fileSizeBytes,
    String? mimeType,
    Value<int?> durationMs = const Value.absent(),
    Value<int?> width = const Value.absent(),
    Value<int?> height = const Value.absent(),
    Value<String?> localPath = const Value.absent(),
    Value<DateTime?> localVerifiedAt = const Value.absent(),
    String? sourceType,
    Value<String?> sourceName = const Value.absent(),
    DateTime? importedAt,
    Value<DateTime?> deletedAt = const Value.absent(),
    Value<String?> tombstoneReason = const Value.absent(),
    int? copyCount,
    Value<DateTime?> lastSyncAt = const Value.absent(),
  }) => AssetManifestData(
    contentHash: contentHash ?? this.contentHash,
    fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
    mimeType: mimeType ?? this.mimeType,
    durationMs: durationMs.present ? durationMs.value : this.durationMs,
    width: width.present ? width.value : this.width,
    height: height.present ? height.value : this.height,
    localPath: localPath.present ? localPath.value : this.localPath,
    localVerifiedAt: localVerifiedAt.present
        ? localVerifiedAt.value
        : this.localVerifiedAt,
    sourceType: sourceType ?? this.sourceType,
    sourceName: sourceName.present ? sourceName.value : this.sourceName,
    importedAt: importedAt ?? this.importedAt,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
    tombstoneReason: tombstoneReason.present
        ? tombstoneReason.value
        : this.tombstoneReason,
    copyCount: copyCount ?? this.copyCount,
    lastSyncAt: lastSyncAt.present ? lastSyncAt.value : this.lastSyncAt,
  );
  AssetManifestData copyWithCompanion(AssetManifestCompanion data) {
    return AssetManifestData(
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      fileSizeBytes: data.fileSizeBytes.present
          ? data.fileSizeBytes.value
          : this.fileSizeBytes,
      mimeType: data.mimeType.present ? data.mimeType.value : this.mimeType,
      durationMs: data.durationMs.present
          ? data.durationMs.value
          : this.durationMs,
      width: data.width.present ? data.width.value : this.width,
      height: data.height.present ? data.height.value : this.height,
      localPath: data.localPath.present ? data.localPath.value : this.localPath,
      localVerifiedAt: data.localVerifiedAt.present
          ? data.localVerifiedAt.value
          : this.localVerifiedAt,
      sourceType: data.sourceType.present
          ? data.sourceType.value
          : this.sourceType,
      sourceName: data.sourceName.present
          ? data.sourceName.value
          : this.sourceName,
      importedAt: data.importedAt.present
          ? data.importedAt.value
          : this.importedAt,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
      tombstoneReason: data.tombstoneReason.present
          ? data.tombstoneReason.value
          : this.tombstoneReason,
      copyCount: data.copyCount.present ? data.copyCount.value : this.copyCount,
      lastSyncAt: data.lastSyncAt.present
          ? data.lastSyncAt.value
          : this.lastSyncAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetManifestData(')
          ..write('contentHash: $contentHash, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('localPath: $localPath, ')
          ..write('localVerifiedAt: $localVerifiedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceName: $sourceName, ')
          ..write('importedAt: $importedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tombstoneReason: $tombstoneReason, ')
          ..write('copyCount: $copyCount, ')
          ..write('lastSyncAt: $lastSyncAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    contentHash,
    fileSizeBytes,
    mimeType,
    durationMs,
    width,
    height,
    localPath,
    localVerifiedAt,
    sourceType,
    sourceName,
    importedAt,
    deletedAt,
    tombstoneReason,
    copyCount,
    lastSyncAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetManifestData &&
          other.contentHash == this.contentHash &&
          other.fileSizeBytes == this.fileSizeBytes &&
          other.mimeType == this.mimeType &&
          other.durationMs == this.durationMs &&
          other.width == this.width &&
          other.height == this.height &&
          other.localPath == this.localPath &&
          other.localVerifiedAt == this.localVerifiedAt &&
          other.sourceType == this.sourceType &&
          other.sourceName == this.sourceName &&
          other.importedAt == this.importedAt &&
          other.deletedAt == this.deletedAt &&
          other.tombstoneReason == this.tombstoneReason &&
          other.copyCount == this.copyCount &&
          other.lastSyncAt == this.lastSyncAt);
}

class AssetManifestCompanion extends UpdateCompanion<AssetManifestData> {
  final Value<String> contentHash;
  final Value<int> fileSizeBytes;
  final Value<String> mimeType;
  final Value<int?> durationMs;
  final Value<int?> width;
  final Value<int?> height;
  final Value<String?> localPath;
  final Value<DateTime?> localVerifiedAt;
  final Value<String> sourceType;
  final Value<String?> sourceName;
  final Value<DateTime> importedAt;
  final Value<DateTime?> deletedAt;
  final Value<String?> tombstoneReason;
  final Value<int> copyCount;
  final Value<DateTime?> lastSyncAt;
  final Value<int> rowid;
  const AssetManifestCompanion({
    this.contentHash = const Value.absent(),
    this.fileSizeBytes = const Value.absent(),
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.localPath = const Value.absent(),
    this.localVerifiedAt = const Value.absent(),
    this.sourceType = const Value.absent(),
    this.sourceName = const Value.absent(),
    this.importedAt = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.tombstoneReason = const Value.absent(),
    this.copyCount = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetManifestCompanion.insert({
    required String contentHash,
    required int fileSizeBytes,
    this.mimeType = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.width = const Value.absent(),
    this.height = const Value.absent(),
    this.localPath = const Value.absent(),
    this.localVerifiedAt = const Value.absent(),
    required String sourceType,
    this.sourceName = const Value.absent(),
    required DateTime importedAt,
    this.deletedAt = const Value.absent(),
    this.tombstoneReason = const Value.absent(),
    this.copyCount = const Value.absent(),
    this.lastSyncAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : contentHash = Value(contentHash),
       fileSizeBytes = Value(fileSizeBytes),
       sourceType = Value(sourceType),
       importedAt = Value(importedAt);
  static Insertable<AssetManifestData> custom({
    Expression<String>? contentHash,
    Expression<int>? fileSizeBytes,
    Expression<String>? mimeType,
    Expression<int>? durationMs,
    Expression<int>? width,
    Expression<int>? height,
    Expression<String>? localPath,
    Expression<DateTime>? localVerifiedAt,
    Expression<String>? sourceType,
    Expression<String>? sourceName,
    Expression<DateTime>? importedAt,
    Expression<DateTime>? deletedAt,
    Expression<String>? tombstoneReason,
    Expression<int>? copyCount,
    Expression<DateTime>? lastSyncAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (contentHash != null) 'content_hash': contentHash,
      if (fileSizeBytes != null) 'file_size_bytes': fileSizeBytes,
      if (mimeType != null) 'mime_type': mimeType,
      if (durationMs != null) 'duration_ms': durationMs,
      if (width != null) 'width': width,
      if (height != null) 'height': height,
      if (localPath != null) 'local_path': localPath,
      if (localVerifiedAt != null) 'local_verified_at': localVerifiedAt,
      if (sourceType != null) 'source_type': sourceType,
      if (sourceName != null) 'source_name': sourceName,
      if (importedAt != null) 'imported_at': importedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (tombstoneReason != null) 'tombstone_reason': tombstoneReason,
      if (copyCount != null) 'copy_count': copyCount,
      if (lastSyncAt != null) 'last_sync_at': lastSyncAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetManifestCompanion copyWith({
    Value<String>? contentHash,
    Value<int>? fileSizeBytes,
    Value<String>? mimeType,
    Value<int?>? durationMs,
    Value<int?>? width,
    Value<int?>? height,
    Value<String?>? localPath,
    Value<DateTime?>? localVerifiedAt,
    Value<String>? sourceType,
    Value<String?>? sourceName,
    Value<DateTime>? importedAt,
    Value<DateTime?>? deletedAt,
    Value<String?>? tombstoneReason,
    Value<int>? copyCount,
    Value<DateTime?>? lastSyncAt,
    Value<int>? rowid,
  }) {
    return AssetManifestCompanion(
      contentHash: contentHash ?? this.contentHash,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      durationMs: durationMs ?? this.durationMs,
      width: width ?? this.width,
      height: height ?? this.height,
      localPath: localPath ?? this.localPath,
      localVerifiedAt: localVerifiedAt ?? this.localVerifiedAt,
      sourceType: sourceType ?? this.sourceType,
      sourceName: sourceName ?? this.sourceName,
      importedAt: importedAt ?? this.importedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      tombstoneReason: tombstoneReason ?? this.tombstoneReason,
      copyCount: copyCount ?? this.copyCount,
      lastSyncAt: lastSyncAt ?? this.lastSyncAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (fileSizeBytes.present) {
      map['file_size_bytes'] = Variable<int>(fileSizeBytes.value);
    }
    if (mimeType.present) {
      map['mime_type'] = Variable<String>(mimeType.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (width.present) {
      map['width'] = Variable<int>(width.value);
    }
    if (height.present) {
      map['height'] = Variable<int>(height.value);
    }
    if (localPath.present) {
      map['local_path'] = Variable<String>(localPath.value);
    }
    if (localVerifiedAt.present) {
      map['local_verified_at'] = Variable<DateTime>(localVerifiedAt.value);
    }
    if (sourceType.present) {
      map['source_type'] = Variable<String>(sourceType.value);
    }
    if (sourceName.present) {
      map['source_name'] = Variable<String>(sourceName.value);
    }
    if (importedAt.present) {
      map['imported_at'] = Variable<DateTime>(importedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<DateTime>(deletedAt.value);
    }
    if (tombstoneReason.present) {
      map['tombstone_reason'] = Variable<String>(tombstoneReason.value);
    }
    if (copyCount.present) {
      map['copy_count'] = Variable<int>(copyCount.value);
    }
    if (lastSyncAt.present) {
      map['last_sync_at'] = Variable<DateTime>(lastSyncAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetManifestCompanion(')
          ..write('contentHash: $contentHash, ')
          ..write('fileSizeBytes: $fileSizeBytes, ')
          ..write('mimeType: $mimeType, ')
          ..write('durationMs: $durationMs, ')
          ..write('width: $width, ')
          ..write('height: $height, ')
          ..write('localPath: $localPath, ')
          ..write('localVerifiedAt: $localVerifiedAt, ')
          ..write('sourceType: $sourceType, ')
          ..write('sourceName: $sourceName, ')
          ..write('importedAt: $importedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('tombstoneReason: $tombstoneReason, ')
          ..write('copyCount: $copyCount, ')
          ..write('lastSyncAt: $lastSyncAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AssetCopiesTable extends AssetCopies
    with TableInfo<$AssetCopiesTable, AssetCopy> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AssetCopiesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES asset_manifest (content_hash)',
    ),
  );
  static const VerificationMeta _providerMeta = const VerificationMeta(
    'provider',
  );
  @override
  late final GeneratedColumn<String> provider = GeneratedColumn<String>(
    'provider',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _remotePathMeta = const VerificationMeta(
    'remotePath',
  );
  @override
  late final GeneratedColumn<String> remotePath = GeneratedColumn<String>(
    'remote_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remoteEtagMeta = const VerificationMeta(
    'remoteEtag',
  );
  @override
  late final GeneratedColumn<String> remoteEtag = GeneratedColumn<String>(
    'remote_etag',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _verifiedAtMeta = const VerificationMeta(
    'verifiedAt',
  );
  @override
  late final GeneratedColumn<DateTime> verifiedAt = GeneratedColumn<DateTime>(
    'verified_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('pending'),
  );
  static const VerificationMeta _uploadProgressMeta = const VerificationMeta(
    'uploadProgress',
  );
  @override
  late final GeneratedColumn<double> uploadProgress = GeneratedColumn<double>(
    'upload_progress',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentHash,
    provider,
    remotePath,
    remoteEtag,
    verifiedAt,
    status,
    uploadProgress,
    errorMessage,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'asset_copies';
  @override
  VerificationContext validateIntegrity(
    Insertable<AssetCopy> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('provider')) {
      context.handle(
        _providerMeta,
        provider.isAcceptableOrUnknown(data['provider']!, _providerMeta),
      );
    } else if (isInserting) {
      context.missing(_providerMeta);
    }
    if (data.containsKey('remote_path')) {
      context.handle(
        _remotePathMeta,
        remotePath.isAcceptableOrUnknown(data['remote_path']!, _remotePathMeta),
      );
    }
    if (data.containsKey('remote_etag')) {
      context.handle(
        _remoteEtagMeta,
        remoteEtag.isAcceptableOrUnknown(data['remote_etag']!, _remoteEtagMeta),
      );
    }
    if (data.containsKey('verified_at')) {
      context.handle(
        _verifiedAtMeta,
        verifiedAt.isAcceptableOrUnknown(data['verified_at']!, _verifiedAtMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('upload_progress')) {
      context.handle(
        _uploadProgressMeta,
        uploadProgress.isAcceptableOrUnknown(
          data['upload_progress']!,
          _uploadProgressMeta,
        ),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AssetCopy map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AssetCopy(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      provider: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider'],
      )!,
      remotePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_path'],
      ),
      remoteEtag: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}remote_etag'],
      ),
      verifiedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}verified_at'],
      ),
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      uploadProgress: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}upload_progress'],
      ),
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $AssetCopiesTable createAlias(String alias) {
    return $AssetCopiesTable(attachedDatabase, alias);
  }
}

class AssetCopy extends DataClass implements Insertable<AssetCopy> {
  /// UUID for this copy record.
  final String id;

  /// FK to [AssetManifest.contentHash] — which asset this copy belongs to.
  final String contentHash;

  /// Storage provider: local, icloud, gdrive, s3.
  final String provider;

  /// Provider-specific path or key (e.g. iCloud container path, S3 object key).
  final String? remotePath;

  /// Provider-specific etag or version identifier for cache invalidation.
  final String? remoteEtag;

  /// Last time this copy was verified to exist and match [contentHash].
  final DateTime? verifiedAt;

  /// Copy lifecycle: pending → uploading → verified → failed → deleted.
  final String status;

  /// Upload/download progress as a fraction (0.0–1.0).
  final double? uploadProgress;

  /// Last error message if status is 'failed'.
  final String? errorMessage;

  /// When this copy record was created.
  final DateTime createdAt;

  /// When this copy record was last updated.
  final DateTime updatedAt;
  const AssetCopy({
    required this.id,
    required this.contentHash,
    required this.provider,
    this.remotePath,
    this.remoteEtag,
    this.verifiedAt,
    required this.status,
    this.uploadProgress,
    this.errorMessage,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content_hash'] = Variable<String>(contentHash);
    map['provider'] = Variable<String>(provider);
    if (!nullToAbsent || remotePath != null) {
      map['remote_path'] = Variable<String>(remotePath);
    }
    if (!nullToAbsent || remoteEtag != null) {
      map['remote_etag'] = Variable<String>(remoteEtag);
    }
    if (!nullToAbsent || verifiedAt != null) {
      map['verified_at'] = Variable<DateTime>(verifiedAt);
    }
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || uploadProgress != null) {
      map['upload_progress'] = Variable<double>(uploadProgress);
    }
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  AssetCopiesCompanion toCompanion(bool nullToAbsent) {
    return AssetCopiesCompanion(
      id: Value(id),
      contentHash: Value(contentHash),
      provider: Value(provider),
      remotePath: remotePath == null && nullToAbsent
          ? const Value.absent()
          : Value(remotePath),
      remoteEtag: remoteEtag == null && nullToAbsent
          ? const Value.absent()
          : Value(remoteEtag),
      verifiedAt: verifiedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(verifiedAt),
      status: Value(status),
      uploadProgress: uploadProgress == null && nullToAbsent
          ? const Value.absent()
          : Value(uploadProgress),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory AssetCopy.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AssetCopy(
      id: serializer.fromJson<String>(json['id']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      provider: serializer.fromJson<String>(json['provider']),
      remotePath: serializer.fromJson<String?>(json['remotePath']),
      remoteEtag: serializer.fromJson<String?>(json['remoteEtag']),
      verifiedAt: serializer.fromJson<DateTime?>(json['verifiedAt']),
      status: serializer.fromJson<String>(json['status']),
      uploadProgress: serializer.fromJson<double?>(json['uploadProgress']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contentHash': serializer.toJson<String>(contentHash),
      'provider': serializer.toJson<String>(provider),
      'remotePath': serializer.toJson<String?>(remotePath),
      'remoteEtag': serializer.toJson<String?>(remoteEtag),
      'verifiedAt': serializer.toJson<DateTime?>(verifiedAt),
      'status': serializer.toJson<String>(status),
      'uploadProgress': serializer.toJson<double?>(uploadProgress),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AssetCopy copyWith({
    String? id,
    String? contentHash,
    String? provider,
    Value<String?> remotePath = const Value.absent(),
    Value<String?> remoteEtag = const Value.absent(),
    Value<DateTime?> verifiedAt = const Value.absent(),
    String? status,
    Value<double?> uploadProgress = const Value.absent(),
    Value<String?> errorMessage = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => AssetCopy(
    id: id ?? this.id,
    contentHash: contentHash ?? this.contentHash,
    provider: provider ?? this.provider,
    remotePath: remotePath.present ? remotePath.value : this.remotePath,
    remoteEtag: remoteEtag.present ? remoteEtag.value : this.remoteEtag,
    verifiedAt: verifiedAt.present ? verifiedAt.value : this.verifiedAt,
    status: status ?? this.status,
    uploadProgress: uploadProgress.present
        ? uploadProgress.value
        : this.uploadProgress,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AssetCopy copyWithCompanion(AssetCopiesCompanion data) {
    return AssetCopy(
      id: data.id.present ? data.id.value : this.id,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      provider: data.provider.present ? data.provider.value : this.provider,
      remotePath: data.remotePath.present
          ? data.remotePath.value
          : this.remotePath,
      remoteEtag: data.remoteEtag.present
          ? data.remoteEtag.value
          : this.remoteEtag,
      verifiedAt: data.verifiedAt.present
          ? data.verifiedAt.value
          : this.verifiedAt,
      status: data.status.present ? data.status.value : this.status,
      uploadProgress: data.uploadProgress.present
          ? data.uploadProgress.value
          : this.uploadProgress,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AssetCopy(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('provider: $provider, ')
          ..write('remotePath: $remotePath, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('status: $status, ')
          ..write('uploadProgress: $uploadProgress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentHash,
    provider,
    remotePath,
    remoteEtag,
    verifiedAt,
    status,
    uploadProgress,
    errorMessage,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AssetCopy &&
          other.id == this.id &&
          other.contentHash == this.contentHash &&
          other.provider == this.provider &&
          other.remotePath == this.remotePath &&
          other.remoteEtag == this.remoteEtag &&
          other.verifiedAt == this.verifiedAt &&
          other.status == this.status &&
          other.uploadProgress == this.uploadProgress &&
          other.errorMessage == this.errorMessage &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class AssetCopiesCompanion extends UpdateCompanion<AssetCopy> {
  final Value<String> id;
  final Value<String> contentHash;
  final Value<String> provider;
  final Value<String?> remotePath;
  final Value<String?> remoteEtag;
  final Value<DateTime?> verifiedAt;
  final Value<String> status;
  final Value<double?> uploadProgress;
  final Value<String?> errorMessage;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AssetCopiesCompanion({
    this.id = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.provider = const Value.absent(),
    this.remotePath = const Value.absent(),
    this.remoteEtag = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.uploadProgress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AssetCopiesCompanion.insert({
    required String id,
    required String contentHash,
    required String provider,
    this.remotePath = const Value.absent(),
    this.remoteEtag = const Value.absent(),
    this.verifiedAt = const Value.absent(),
    this.status = const Value.absent(),
    this.uploadProgress = const Value.absent(),
    this.errorMessage = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contentHash = Value(contentHash),
       provider = Value(provider),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<AssetCopy> custom({
    Expression<String>? id,
    Expression<String>? contentHash,
    Expression<String>? provider,
    Expression<String>? remotePath,
    Expression<String>? remoteEtag,
    Expression<DateTime>? verifiedAt,
    Expression<String>? status,
    Expression<double>? uploadProgress,
    Expression<String>? errorMessage,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentHash != null) 'content_hash': contentHash,
      if (provider != null) 'provider': provider,
      if (remotePath != null) 'remote_path': remotePath,
      if (remoteEtag != null) 'remote_etag': remoteEtag,
      if (verifiedAt != null) 'verified_at': verifiedAt,
      if (status != null) 'status': status,
      if (uploadProgress != null) 'upload_progress': uploadProgress,
      if (errorMessage != null) 'error_message': errorMessage,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AssetCopiesCompanion copyWith({
    Value<String>? id,
    Value<String>? contentHash,
    Value<String>? provider,
    Value<String?>? remotePath,
    Value<String?>? remoteEtag,
    Value<DateTime?>? verifiedAt,
    Value<String>? status,
    Value<double?>? uploadProgress,
    Value<String?>? errorMessage,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AssetCopiesCompanion(
      id: id ?? this.id,
      contentHash: contentHash ?? this.contentHash,
      provider: provider ?? this.provider,
      remotePath: remotePath ?? this.remotePath,
      remoteEtag: remoteEtag ?? this.remoteEtag,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      status: status ?? this.status,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      errorMessage: errorMessage ?? this.errorMessage,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (provider.present) {
      map['provider'] = Variable<String>(provider.value);
    }
    if (remotePath.present) {
      map['remote_path'] = Variable<String>(remotePath.value);
    }
    if (remoteEtag.present) {
      map['remote_etag'] = Variable<String>(remoteEtag.value);
    }
    if (verifiedAt.present) {
      map['verified_at'] = Variable<DateTime>(verifiedAt.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (uploadProgress.present) {
      map['upload_progress'] = Variable<double>(uploadProgress.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AssetCopiesCompanion(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('provider: $provider, ')
          ..write('remotePath: $remotePath, ')
          ..write('remoteEtag: $remoteEtag, ')
          ..write('verifiedAt: $verifiedAt, ')
          ..write('status: $status, ')
          ..write('uploadProgress: $uploadProgress, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncProvidersTable extends SyncProviders
    with TableInfo<$SyncProvidersTable, SyncProvider> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncProvidersTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerTypeMeta = const VerificationMeta(
    'providerType',
  );
  @override
  late final GeneratedColumn<String> providerType = GeneratedColumn<String>(
    'provider_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _displayNameMeta = const VerificationMeta(
    'displayName',
  );
  @override
  late final GeneratedColumn<String> displayName = GeneratedColumn<String>(
    'display_name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _enabledMeta = const VerificationMeta(
    'enabled',
  );
  @override
  late final GeneratedColumn<bool> enabled = GeneratedColumn<bool>(
    'enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _configJsonMeta = const VerificationMeta(
    'configJson',
  );
  @override
  late final GeneratedColumn<String> configJson = GeneratedColumn<String>(
    'config_json',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _quotaBytesMeta = const VerificationMeta(
    'quotaBytes',
  );
  @override
  late final GeneratedColumn<int> quotaBytes = GeneratedColumn<int>(
    'quota_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _usedBytesMeta = const VerificationMeta(
    'usedBytes',
  );
  @override
  late final GeneratedColumn<int> usedBytes = GeneratedColumn<int>(
    'used_bytes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _lastAuthAtMeta = const VerificationMeta(
    'lastAuthAt',
  );
  @override
  late final GeneratedColumn<DateTime> lastAuthAt = GeneratedColumn<DateTime>(
    'last_auth_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    providerType,
    displayName,
    enabled,
    configJson,
    quotaBytes,
    usedBytes,
    lastAuthAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_providers';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncProvider> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('provider_type')) {
      context.handle(
        _providerTypeMeta,
        providerType.isAcceptableOrUnknown(
          data['provider_type']!,
          _providerTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_providerTypeMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_displayNameMeta);
    }
    if (data.containsKey('enabled')) {
      context.handle(
        _enabledMeta,
        enabled.isAcceptableOrUnknown(data['enabled']!, _enabledMeta),
      );
    }
    if (data.containsKey('config_json')) {
      context.handle(
        _configJsonMeta,
        configJson.isAcceptableOrUnknown(data['config_json']!, _configJsonMeta),
      );
    }
    if (data.containsKey('quota_bytes')) {
      context.handle(
        _quotaBytesMeta,
        quotaBytes.isAcceptableOrUnknown(data['quota_bytes']!, _quotaBytesMeta),
      );
    }
    if (data.containsKey('used_bytes')) {
      context.handle(
        _usedBytesMeta,
        usedBytes.isAcceptableOrUnknown(data['used_bytes']!, _usedBytesMeta),
      );
    }
    if (data.containsKey('last_auth_at')) {
      context.handle(
        _lastAuthAtMeta,
        lastAuthAt.isAcceptableOrUnknown(
          data['last_auth_at']!,
          _lastAuthAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncProvider map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncProvider(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      providerType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_type'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      )!,
      enabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}enabled'],
      )!,
      configJson: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}config_json'],
      ),
      quotaBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}quota_bytes'],
      ),
      usedBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}used_bytes'],
      ),
      lastAuthAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}last_auth_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $SyncProvidersTable createAlias(String alias) {
    return $SyncProvidersTable(attachedDatabase, alias);
  }
}

class SyncProvider extends DataClass implements Insertable<SyncProvider> {
  /// UUID for this provider configuration.
  final String id;

  /// Provider type identifier: icloud, gdrive, s3.
  final String providerType;

  /// User-facing display name (e.g. "My Google Drive", "Work S3 Bucket").
  final String displayName;

  /// Whether this provider is active for sync operations.
  final bool enabled;

  /// Provider-specific configuration as JSON (e.g. bucket name, endpoint).
  final String? configJson;

  /// Total storage quota in bytes (null if unknown/unlimited).
  final int? quotaBytes;

  /// Used storage in bytes (null if unknown).
  final int? usedBytes;

  /// Last successful authentication timestamp.
  final DateTime? lastAuthAt;

  /// When this provider was first configured.
  final DateTime createdAt;
  const SyncProvider({
    required this.id,
    required this.providerType,
    required this.displayName,
    required this.enabled,
    this.configJson,
    this.quotaBytes,
    this.usedBytes,
    this.lastAuthAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['provider_type'] = Variable<String>(providerType);
    map['display_name'] = Variable<String>(displayName);
    map['enabled'] = Variable<bool>(enabled);
    if (!nullToAbsent || configJson != null) {
      map['config_json'] = Variable<String>(configJson);
    }
    if (!nullToAbsent || quotaBytes != null) {
      map['quota_bytes'] = Variable<int>(quotaBytes);
    }
    if (!nullToAbsent || usedBytes != null) {
      map['used_bytes'] = Variable<int>(usedBytes);
    }
    if (!nullToAbsent || lastAuthAt != null) {
      map['last_auth_at'] = Variable<DateTime>(lastAuthAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  SyncProvidersCompanion toCompanion(bool nullToAbsent) {
    return SyncProvidersCompanion(
      id: Value(id),
      providerType: Value(providerType),
      displayName: Value(displayName),
      enabled: Value(enabled),
      configJson: configJson == null && nullToAbsent
          ? const Value.absent()
          : Value(configJson),
      quotaBytes: quotaBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(quotaBytes),
      usedBytes: usedBytes == null && nullToAbsent
          ? const Value.absent()
          : Value(usedBytes),
      lastAuthAt: lastAuthAt == null && nullToAbsent
          ? const Value.absent()
          : Value(lastAuthAt),
      createdAt: Value(createdAt),
    );
  }

  factory SyncProvider.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncProvider(
      id: serializer.fromJson<String>(json['id']),
      providerType: serializer.fromJson<String>(json['providerType']),
      displayName: serializer.fromJson<String>(json['displayName']),
      enabled: serializer.fromJson<bool>(json['enabled']),
      configJson: serializer.fromJson<String?>(json['configJson']),
      quotaBytes: serializer.fromJson<int?>(json['quotaBytes']),
      usedBytes: serializer.fromJson<int?>(json['usedBytes']),
      lastAuthAt: serializer.fromJson<DateTime?>(json['lastAuthAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'providerType': serializer.toJson<String>(providerType),
      'displayName': serializer.toJson<String>(displayName),
      'enabled': serializer.toJson<bool>(enabled),
      'configJson': serializer.toJson<String?>(configJson),
      'quotaBytes': serializer.toJson<int?>(quotaBytes),
      'usedBytes': serializer.toJson<int?>(usedBytes),
      'lastAuthAt': serializer.toJson<DateTime?>(lastAuthAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  SyncProvider copyWith({
    String? id,
    String? providerType,
    String? displayName,
    bool? enabled,
    Value<String?> configJson = const Value.absent(),
    Value<int?> quotaBytes = const Value.absent(),
    Value<int?> usedBytes = const Value.absent(),
    Value<DateTime?> lastAuthAt = const Value.absent(),
    DateTime? createdAt,
  }) => SyncProvider(
    id: id ?? this.id,
    providerType: providerType ?? this.providerType,
    displayName: displayName ?? this.displayName,
    enabled: enabled ?? this.enabled,
    configJson: configJson.present ? configJson.value : this.configJson,
    quotaBytes: quotaBytes.present ? quotaBytes.value : this.quotaBytes,
    usedBytes: usedBytes.present ? usedBytes.value : this.usedBytes,
    lastAuthAt: lastAuthAt.present ? lastAuthAt.value : this.lastAuthAt,
    createdAt: createdAt ?? this.createdAt,
  );
  SyncProvider copyWithCompanion(SyncProvidersCompanion data) {
    return SyncProvider(
      id: data.id.present ? data.id.value : this.id,
      providerType: data.providerType.present
          ? data.providerType.value
          : this.providerType,
      displayName: data.displayName.present
          ? data.displayName.value
          : this.displayName,
      enabled: data.enabled.present ? data.enabled.value : this.enabled,
      configJson: data.configJson.present
          ? data.configJson.value
          : this.configJson,
      quotaBytes: data.quotaBytes.present
          ? data.quotaBytes.value
          : this.quotaBytes,
      usedBytes: data.usedBytes.present ? data.usedBytes.value : this.usedBytes,
      lastAuthAt: data.lastAuthAt.present
          ? data.lastAuthAt.value
          : this.lastAuthAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncProvider(')
          ..write('id: $id, ')
          ..write('providerType: $providerType, ')
          ..write('displayName: $displayName, ')
          ..write('enabled: $enabled, ')
          ..write('configJson: $configJson, ')
          ..write('quotaBytes: $quotaBytes, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('lastAuthAt: $lastAuthAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    providerType,
    displayName,
    enabled,
    configJson,
    quotaBytes,
    usedBytes,
    lastAuthAt,
    createdAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncProvider &&
          other.id == this.id &&
          other.providerType == this.providerType &&
          other.displayName == this.displayName &&
          other.enabled == this.enabled &&
          other.configJson == this.configJson &&
          other.quotaBytes == this.quotaBytes &&
          other.usedBytes == this.usedBytes &&
          other.lastAuthAt == this.lastAuthAt &&
          other.createdAt == this.createdAt);
}

class SyncProvidersCompanion extends UpdateCompanion<SyncProvider> {
  final Value<String> id;
  final Value<String> providerType;
  final Value<String> displayName;
  final Value<bool> enabled;
  final Value<String?> configJson;
  final Value<int?> quotaBytes;
  final Value<int?> usedBytes;
  final Value<DateTime?> lastAuthAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const SyncProvidersCompanion({
    this.id = const Value.absent(),
    this.providerType = const Value.absent(),
    this.displayName = const Value.absent(),
    this.enabled = const Value.absent(),
    this.configJson = const Value.absent(),
    this.quotaBytes = const Value.absent(),
    this.usedBytes = const Value.absent(),
    this.lastAuthAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncProvidersCompanion.insert({
    required String id,
    required String providerType,
    required String displayName,
    this.enabled = const Value.absent(),
    this.configJson = const Value.absent(),
    this.quotaBytes = const Value.absent(),
    this.usedBytes = const Value.absent(),
    this.lastAuthAt = const Value.absent(),
    required DateTime createdAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       providerType = Value(providerType),
       displayName = Value(displayName),
       createdAt = Value(createdAt);
  static Insertable<SyncProvider> custom({
    Expression<String>? id,
    Expression<String>? providerType,
    Expression<String>? displayName,
    Expression<bool>? enabled,
    Expression<String>? configJson,
    Expression<int>? quotaBytes,
    Expression<int>? usedBytes,
    Expression<DateTime>? lastAuthAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (providerType != null) 'provider_type': providerType,
      if (displayName != null) 'display_name': displayName,
      if (enabled != null) 'enabled': enabled,
      if (configJson != null) 'config_json': configJson,
      if (quotaBytes != null) 'quota_bytes': quotaBytes,
      if (usedBytes != null) 'used_bytes': usedBytes,
      if (lastAuthAt != null) 'last_auth_at': lastAuthAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncProvidersCompanion copyWith({
    Value<String>? id,
    Value<String>? providerType,
    Value<String>? displayName,
    Value<bool>? enabled,
    Value<String?>? configJson,
    Value<int?>? quotaBytes,
    Value<int?>? usedBytes,
    Value<DateTime?>? lastAuthAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return SyncProvidersCompanion(
      id: id ?? this.id,
      providerType: providerType ?? this.providerType,
      displayName: displayName ?? this.displayName,
      enabled: enabled ?? this.enabled,
      configJson: configJson ?? this.configJson,
      quotaBytes: quotaBytes ?? this.quotaBytes,
      usedBytes: usedBytes ?? this.usedBytes,
      lastAuthAt: lastAuthAt ?? this.lastAuthAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (providerType.present) {
      map['provider_type'] = Variable<String>(providerType.value);
    }
    if (displayName.present) {
      map['display_name'] = Variable<String>(displayName.value);
    }
    if (enabled.present) {
      map['enabled'] = Variable<bool>(enabled.value);
    }
    if (configJson.present) {
      map['config_json'] = Variable<String>(configJson.value);
    }
    if (quotaBytes.present) {
      map['quota_bytes'] = Variable<int>(quotaBytes.value);
    }
    if (usedBytes.present) {
      map['used_bytes'] = Variable<int>(usedBytes.value);
    }
    if (lastAuthAt.present) {
      map['last_auth_at'] = Variable<DateTime>(lastAuthAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncProvidersCompanion(')
          ..write('id: $id, ')
          ..write('providerType: $providerType, ')
          ..write('displayName: $displayName, ')
          ..write('enabled: $enabled, ')
          ..write('configJson: $configJson, ')
          ..write('quotaBytes: $quotaBytes, ')
          ..write('usedBytes: $usedBytes, ')
          ..write('lastAuthAt: $lastAuthAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SyncOperationsTable extends SyncOperations
    with TableInfo<$SyncOperationsTable, SyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _contentHashMeta = const VerificationMeta(
    'contentHash',
  );
  @override
  late final GeneratedColumn<String> contentHash = GeneratedColumn<String>(
    'content_hash',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _providerIdMeta = const VerificationMeta(
    'providerId',
  );
  @override
  late final GeneratedColumn<String> providerId = GeneratedColumn<String>(
    'provider_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _operationTypeMeta = const VerificationMeta(
    'operationType',
  );
  @override
  late final GeneratedColumn<String> operationType = GeneratedColumn<String>(
    'operation_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('queued'),
  );
  static const VerificationMeta _priorityMeta = const VerificationMeta(
    'priority',
  );
  @override
  late final GeneratedColumn<int> priority = GeneratedColumn<int>(
    'priority',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _retryCountMeta = const VerificationMeta(
    'retryCount',
  );
  @override
  late final GeneratedColumn<int> retryCount = GeneratedColumn<int>(
    'retry_count',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _maxRetriesMeta = const VerificationMeta(
    'maxRetries',
  );
  @override
  late final GeneratedColumn<int> maxRetries = GeneratedColumn<int>(
    'max_retries',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _errorMessageMeta = const VerificationMeta(
    'errorMessage',
  );
  @override
  late final GeneratedColumn<String> errorMessage = GeneratedColumn<String>(
    'error_message',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bytesTransferredMeta = const VerificationMeta(
    'bytesTransferred',
  );
  @override
  late final GeneratedColumn<int> bytesTransferred = GeneratedColumn<int>(
    'bytes_transferred',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _totalBytesMeta = const VerificationMeta(
    'totalBytes',
  );
  @override
  late final GeneratedColumn<int> totalBytes = GeneratedColumn<int>(
    'total_bytes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startedAtMeta = const VerificationMeta(
    'startedAt',
  );
  @override
  late final GeneratedColumn<DateTime> startedAt = GeneratedColumn<DateTime>(
    'started_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    contentHash,
    providerId,
    operationType,
    status,
    priority,
    retryCount,
    maxRetries,
    errorMessage,
    bytesTransferred,
    totalBytes,
    createdAt,
    startedAt,
    completedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sync_operations';
  @override
  VerificationContext validateIntegrity(
    Insertable<SyncOperation> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('content_hash')) {
      context.handle(
        _contentHashMeta,
        contentHash.isAcceptableOrUnknown(
          data['content_hash']!,
          _contentHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_contentHashMeta);
    }
    if (data.containsKey('provider_id')) {
      context.handle(
        _providerIdMeta,
        providerId.isAcceptableOrUnknown(data['provider_id']!, _providerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_providerIdMeta);
    }
    if (data.containsKey('operation_type')) {
      context.handle(
        _operationTypeMeta,
        operationType.isAcceptableOrUnknown(
          data['operation_type']!,
          _operationTypeMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_operationTypeMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('priority')) {
      context.handle(
        _priorityMeta,
        priority.isAcceptableOrUnknown(data['priority']!, _priorityMeta),
      );
    }
    if (data.containsKey('retry_count')) {
      context.handle(
        _retryCountMeta,
        retryCount.isAcceptableOrUnknown(data['retry_count']!, _retryCountMeta),
      );
    }
    if (data.containsKey('max_retries')) {
      context.handle(
        _maxRetriesMeta,
        maxRetries.isAcceptableOrUnknown(data['max_retries']!, _maxRetriesMeta),
      );
    }
    if (data.containsKey('error_message')) {
      context.handle(
        _errorMessageMeta,
        errorMessage.isAcceptableOrUnknown(
          data['error_message']!,
          _errorMessageMeta,
        ),
      );
    }
    if (data.containsKey('bytes_transferred')) {
      context.handle(
        _bytesTransferredMeta,
        bytesTransferred.isAcceptableOrUnknown(
          data['bytes_transferred']!,
          _bytesTransferredMeta,
        ),
      );
    }
    if (data.containsKey('total_bytes')) {
      context.handle(
        _totalBytesMeta,
        totalBytes.isAcceptableOrUnknown(data['total_bytes']!, _totalBytesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('started_at')) {
      context.handle(
        _startedAtMeta,
        startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SyncOperation(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      contentHash: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content_hash'],
      )!,
      providerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}provider_id'],
      )!,
      operationType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}operation_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      priority: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}priority'],
      )!,
      retryCount: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}retry_count'],
      )!,
      maxRetries: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}max_retries'],
      )!,
      errorMessage: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}error_message'],
      ),
      bytesTransferred: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}bytes_transferred'],
      )!,
      totalBytes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}total_bytes'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      startedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}started_at'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
    );
  }

  @override
  $SyncOperationsTable createAlias(String alias) {
    return $SyncOperationsTable(attachedDatabase, alias);
  }
}

class SyncOperation extends DataClass implements Insertable<SyncOperation> {
  /// UUID for this operation.
  final String id;

  /// Content hash of the asset being operated on.
  final String contentHash;

  /// Which provider this operation targets.
  final String providerId;

  /// What the operation does: upload, download, verify, delete_remote.
  final String operationType;

  /// Lifecycle: queued → in_progress → completed → failed.
  final String status;

  /// Higher priority operations are processed first.
  final int priority;

  /// How many times this operation has been retried.
  final int retryCount;

  /// Maximum retry attempts before giving up.
  final int maxRetries;

  /// Error message from the last failed attempt.
  final String? errorMessage;

  /// Bytes transferred so far (for progress tracking).
  final int bytesTransferred;

  /// Total bytes to transfer (for progress calculation).
  final int totalBytes;

  /// When this operation was queued.
  final DateTime createdAt;

  /// When processing started.
  final DateTime? startedAt;

  /// When the operation completed (successfully or after final failure).
  final DateTime? completedAt;
  const SyncOperation({
    required this.id,
    required this.contentHash,
    required this.providerId,
    required this.operationType,
    required this.status,
    required this.priority,
    required this.retryCount,
    required this.maxRetries,
    this.errorMessage,
    required this.bytesTransferred,
    required this.totalBytes,
    required this.createdAt,
    this.startedAt,
    this.completedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['content_hash'] = Variable<String>(contentHash);
    map['provider_id'] = Variable<String>(providerId);
    map['operation_type'] = Variable<String>(operationType);
    map['status'] = Variable<String>(status);
    map['priority'] = Variable<int>(priority);
    map['retry_count'] = Variable<int>(retryCount);
    map['max_retries'] = Variable<int>(maxRetries);
    if (!nullToAbsent || errorMessage != null) {
      map['error_message'] = Variable<String>(errorMessage);
    }
    map['bytes_transferred'] = Variable<int>(bytesTransferred);
    map['total_bytes'] = Variable<int>(totalBytes);
    map['created_at'] = Variable<DateTime>(createdAt);
    if (!nullToAbsent || startedAt != null) {
      map['started_at'] = Variable<DateTime>(startedAt);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    return map;
  }

  SyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return SyncOperationsCompanion(
      id: Value(id),
      contentHash: Value(contentHash),
      providerId: Value(providerId),
      operationType: Value(operationType),
      status: Value(status),
      priority: Value(priority),
      retryCount: Value(retryCount),
      maxRetries: Value(maxRetries),
      errorMessage: errorMessage == null && nullToAbsent
          ? const Value.absent()
          : Value(errorMessage),
      bytesTransferred: Value(bytesTransferred),
      totalBytes: Value(totalBytes),
      createdAt: Value(createdAt),
      startedAt: startedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(startedAt),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
    );
  }

  factory SyncOperation.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SyncOperation(
      id: serializer.fromJson<String>(json['id']),
      contentHash: serializer.fromJson<String>(json['contentHash']),
      providerId: serializer.fromJson<String>(json['providerId']),
      operationType: serializer.fromJson<String>(json['operationType']),
      status: serializer.fromJson<String>(json['status']),
      priority: serializer.fromJson<int>(json['priority']),
      retryCount: serializer.fromJson<int>(json['retryCount']),
      maxRetries: serializer.fromJson<int>(json['maxRetries']),
      errorMessage: serializer.fromJson<String?>(json['errorMessage']),
      bytesTransferred: serializer.fromJson<int>(json['bytesTransferred']),
      totalBytes: serializer.fromJson<int>(json['totalBytes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      startedAt: serializer.fromJson<DateTime?>(json['startedAt']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'contentHash': serializer.toJson<String>(contentHash),
      'providerId': serializer.toJson<String>(providerId),
      'operationType': serializer.toJson<String>(operationType),
      'status': serializer.toJson<String>(status),
      'priority': serializer.toJson<int>(priority),
      'retryCount': serializer.toJson<int>(retryCount),
      'maxRetries': serializer.toJson<int>(maxRetries),
      'errorMessage': serializer.toJson<String?>(errorMessage),
      'bytesTransferred': serializer.toJson<int>(bytesTransferred),
      'totalBytes': serializer.toJson<int>(totalBytes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'startedAt': serializer.toJson<DateTime?>(startedAt),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
    };
  }

  SyncOperation copyWith({
    String? id,
    String? contentHash,
    String? providerId,
    String? operationType,
    String? status,
    int? priority,
    int? retryCount,
    int? maxRetries,
    Value<String?> errorMessage = const Value.absent(),
    int? bytesTransferred,
    int? totalBytes,
    DateTime? createdAt,
    Value<DateTime?> startedAt = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
  }) => SyncOperation(
    id: id ?? this.id,
    contentHash: contentHash ?? this.contentHash,
    providerId: providerId ?? this.providerId,
    operationType: operationType ?? this.operationType,
    status: status ?? this.status,
    priority: priority ?? this.priority,
    retryCount: retryCount ?? this.retryCount,
    maxRetries: maxRetries ?? this.maxRetries,
    errorMessage: errorMessage.present ? errorMessage.value : this.errorMessage,
    bytesTransferred: bytesTransferred ?? this.bytesTransferred,
    totalBytes: totalBytes ?? this.totalBytes,
    createdAt: createdAt ?? this.createdAt,
    startedAt: startedAt.present ? startedAt.value : this.startedAt,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
  );
  SyncOperation copyWithCompanion(SyncOperationsCompanion data) {
    return SyncOperation(
      id: data.id.present ? data.id.value : this.id,
      contentHash: data.contentHash.present
          ? data.contentHash.value
          : this.contentHash,
      providerId: data.providerId.present
          ? data.providerId.value
          : this.providerId,
      operationType: data.operationType.present
          ? data.operationType.value
          : this.operationType,
      status: data.status.present ? data.status.value : this.status,
      priority: data.priority.present ? data.priority.value : this.priority,
      retryCount: data.retryCount.present
          ? data.retryCount.value
          : this.retryCount,
      maxRetries: data.maxRetries.present
          ? data.maxRetries.value
          : this.maxRetries,
      errorMessage: data.errorMessage.present
          ? data.errorMessage.value
          : this.errorMessage,
      bytesTransferred: data.bytesTransferred.present
          ? data.bytesTransferred.value
          : this.bytesTransferred,
      totalBytes: data.totalBytes.present
          ? data.totalBytes.value
          : this.totalBytes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperation(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('providerId: $providerId, ')
          ..write('operationType: $operationType, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    contentHash,
    providerId,
    operationType,
    status,
    priority,
    retryCount,
    maxRetries,
    errorMessage,
    bytesTransferred,
    totalBytes,
    createdAt,
    startedAt,
    completedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SyncOperation &&
          other.id == this.id &&
          other.contentHash == this.contentHash &&
          other.providerId == this.providerId &&
          other.operationType == this.operationType &&
          other.status == this.status &&
          other.priority == this.priority &&
          other.retryCount == this.retryCount &&
          other.maxRetries == this.maxRetries &&
          other.errorMessage == this.errorMessage &&
          other.bytesTransferred == this.bytesTransferred &&
          other.totalBytes == this.totalBytes &&
          other.createdAt == this.createdAt &&
          other.startedAt == this.startedAt &&
          other.completedAt == this.completedAt);
}

class SyncOperationsCompanion extends UpdateCompanion<SyncOperation> {
  final Value<String> id;
  final Value<String> contentHash;
  final Value<String> providerId;
  final Value<String> operationType;
  final Value<String> status;
  final Value<int> priority;
  final Value<int> retryCount;
  final Value<int> maxRetries;
  final Value<String?> errorMessage;
  final Value<int> bytesTransferred;
  final Value<int> totalBytes;
  final Value<DateTime> createdAt;
  final Value<DateTime?> startedAt;
  final Value<DateTime?> completedAt;
  final Value<int> rowid;
  const SyncOperationsCompanion({
    this.id = const Value.absent(),
    this.contentHash = const Value.absent(),
    this.providerId = const Value.absent(),
    this.operationType = const Value.absent(),
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.bytesTransferred = const Value.absent(),
    this.totalBytes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SyncOperationsCompanion.insert({
    required String id,
    required String contentHash,
    required String providerId,
    required String operationType,
    this.status = const Value.absent(),
    this.priority = const Value.absent(),
    this.retryCount = const Value.absent(),
    this.maxRetries = const Value.absent(),
    this.errorMessage = const Value.absent(),
    this.bytesTransferred = const Value.absent(),
    this.totalBytes = const Value.absent(),
    required DateTime createdAt,
    this.startedAt = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       contentHash = Value(contentHash),
       providerId = Value(providerId),
       operationType = Value(operationType),
       createdAt = Value(createdAt);
  static Insertable<SyncOperation> custom({
    Expression<String>? id,
    Expression<String>? contentHash,
    Expression<String>? providerId,
    Expression<String>? operationType,
    Expression<String>? status,
    Expression<int>? priority,
    Expression<int>? retryCount,
    Expression<int>? maxRetries,
    Expression<String>? errorMessage,
    Expression<int>? bytesTransferred,
    Expression<int>? totalBytes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? startedAt,
    Expression<DateTime>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (contentHash != null) 'content_hash': contentHash,
      if (providerId != null) 'provider_id': providerId,
      if (operationType != null) 'operation_type': operationType,
      if (status != null) 'status': status,
      if (priority != null) 'priority': priority,
      if (retryCount != null) 'retry_count': retryCount,
      if (maxRetries != null) 'max_retries': maxRetries,
      if (errorMessage != null) 'error_message': errorMessage,
      if (bytesTransferred != null) 'bytes_transferred': bytesTransferred,
      if (totalBytes != null) 'total_bytes': totalBytes,
      if (createdAt != null) 'created_at': createdAt,
      if (startedAt != null) 'started_at': startedAt,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SyncOperationsCompanion copyWith({
    Value<String>? id,
    Value<String>? contentHash,
    Value<String>? providerId,
    Value<String>? operationType,
    Value<String>? status,
    Value<int>? priority,
    Value<int>? retryCount,
    Value<int>? maxRetries,
    Value<String?>? errorMessage,
    Value<int>? bytesTransferred,
    Value<int>? totalBytes,
    Value<DateTime>? createdAt,
    Value<DateTime?>? startedAt,
    Value<DateTime?>? completedAt,
    Value<int>? rowid,
  }) {
    return SyncOperationsCompanion(
      id: id ?? this.id,
      contentHash: contentHash ?? this.contentHash,
      providerId: providerId ?? this.providerId,
      operationType: operationType ?? this.operationType,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      retryCount: retryCount ?? this.retryCount,
      maxRetries: maxRetries ?? this.maxRetries,
      errorMessage: errorMessage ?? this.errorMessage,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (contentHash.present) {
      map['content_hash'] = Variable<String>(contentHash.value);
    }
    if (providerId.present) {
      map['provider_id'] = Variable<String>(providerId.value);
    }
    if (operationType.present) {
      map['operation_type'] = Variable<String>(operationType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (priority.present) {
      map['priority'] = Variable<int>(priority.value);
    }
    if (retryCount.present) {
      map['retry_count'] = Variable<int>(retryCount.value);
    }
    if (maxRetries.present) {
      map['max_retries'] = Variable<int>(maxRetries.value);
    }
    if (errorMessage.present) {
      map['error_message'] = Variable<String>(errorMessage.value);
    }
    if (bytesTransferred.present) {
      map['bytes_transferred'] = Variable<int>(bytesTransferred.value);
    }
    if (totalBytes.present) {
      map['total_bytes'] = Variable<int>(totalBytes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<DateTime>(startedAt.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('contentHash: $contentHash, ')
          ..write('providerId: $providerId, ')
          ..write('operationType: $operationType, ')
          ..write('status: $status, ')
          ..write('priority: $priority, ')
          ..write('retryCount: $retryCount, ')
          ..write('maxRetries: $maxRetries, ')
          ..write('errorMessage: $errorMessage, ')
          ..write('bytesTransferred: $bytesTransferred, ')
          ..write('totalBytes: $totalBytes, ')
          ..write('createdAt: $createdAt, ')
          ..write('startedAt: $startedAt, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabsTable extends Labs with TableInfo<$LabsTable, Lab> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labTypeMeta = const VerificationMeta(
    'labType',
  );
  @override
  late final GeneratedColumn<String> labType = GeneratedColumn<String>(
    'lab_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('project'),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('idea'),
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    labType,
    status,
    notes,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'labs';
  @override
  VerificationContext validateIntegrity(
    Insertable<Lab> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('lab_type')) {
      context.handle(
        _labTypeMeta,
        labType.isAcceptableOrUnknown(data['lab_type']!, _labTypeMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Lab map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Lab(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      labType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lab_type'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LabsTable createAlias(String alias) {
    return $LabsTable(attachedDatabase, alias);
  }
}

class Lab extends DataClass implements Insertable<Lab> {
  final String id;
  final String name;

  /// 'project' or 'set'
  final String labType;

  /// 'idea', 'attempting', 'landed', or 'clean'
  final String status;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  const Lab({
    required this.id,
    required this.name,
    required this.labType,
    required this.status,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['lab_type'] = Variable<String>(labType);
    map['status'] = Variable<String>(status);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LabsCompanion toCompanion(bool nullToAbsent) {
    return LabsCompanion(
      id: Value(id),
      name: Value(name),
      labType: Value(labType),
      status: Value(status),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory Lab.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Lab(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      labType: serializer.fromJson<String>(json['labType']),
      status: serializer.fromJson<String>(json['status']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'labType': serializer.toJson<String>(labType),
      'status': serializer.toJson<String>(status),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  Lab copyWith({
    String? id,
    String? name,
    String? labType,
    String? status,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => Lab(
    id: id ?? this.id,
    name: name ?? this.name,
    labType: labType ?? this.labType,
    status: status ?? this.status,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  Lab copyWithCompanion(LabsCompanion data) {
    return Lab(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      labType: data.labType.present ? data.labType.value : this.labType,
      status: data.status.present ? data.status.value : this.status,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Lab(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('labType: $labType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, labType, status, notes, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Lab &&
          other.id == this.id &&
          other.name == this.name &&
          other.labType == this.labType &&
          other.status == this.status &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class LabsCompanion extends UpdateCompanion<Lab> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> labType;
  final Value<String> status;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LabsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.labType = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabsCompanion.insert({
    required String id,
    required String name,
    this.labType = const Value.absent(),
    this.status = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Lab> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? labType,
    Expression<String>? status,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (labType != null) 'lab_type': labType,
      if (status != null) 'status': status,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String>? labType,
    Value<String>? status,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LabsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      labType: labType ?? this.labType,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (labType.present) {
      map['lab_type'] = Variable<String>(labType.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('labType: $labType, ')
          ..write('status: $status, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MilestonesTable extends Milestones
    with TableInfo<$MilestonesTable, Milestone> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MilestonesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labIdMeta = const VerificationMeta('labId');
  @override
  late final GeneratedColumn<String> labId = GeneratedColumn<String>(
    'lab_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<DateTime> completedAt = GeneratedColumn<DateTime>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    labId,
    title,
    notes,
    completedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'milestones';
  @override
  VerificationContext validateIntegrity(
    Insertable<Milestone> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lab_id')) {
      context.handle(
        _labIdMeta,
        labId.isAcceptableOrUnknown(data['lab_id']!, _labIdMeta),
      );
    } else if (isInserting) {
      context.missing(_labIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Milestone map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Milestone(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      labId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lab_id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}completed_at'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MilestonesTable createAlias(String alias) {
    return $MilestonesTable(attachedDatabase, alias);
  }
}

class Milestone extends DataClass implements Insertable<Milestone> {
  final String id;
  final String labId;
  final String title;
  final String? notes;
  final DateTime? completedAt;
  final DateTime createdAt;
  const Milestone({
    required this.id,
    required this.labId,
    required this.title,
    this.notes,
    this.completedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['lab_id'] = Variable<String>(labId);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<DateTime>(completedAt);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MilestonesCompanion toCompanion(bool nullToAbsent) {
    return MilestonesCompanion(
      id: Value(id),
      labId: Value(labId),
      title: Value(title),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Milestone.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Milestone(
      id: serializer.fromJson<String>(json['id']),
      labId: serializer.fromJson<String>(json['labId']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String?>(json['notes']),
      completedAt: serializer.fromJson<DateTime?>(json['completedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'labId': serializer.toJson<String>(labId),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String?>(notes),
      'completedAt': serializer.toJson<DateTime?>(completedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Milestone copyWith({
    String? id,
    String? labId,
    String? title,
    Value<String?> notes = const Value.absent(),
    Value<DateTime?> completedAt = const Value.absent(),
    DateTime? createdAt,
  }) => Milestone(
    id: id ?? this.id,
    labId: labId ?? this.labId,
    title: title ?? this.title,
    notes: notes.present ? notes.value : this.notes,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Milestone copyWithCompanion(MilestonesCompanion data) {
    return Milestone(
      id: data.id.present ? data.id.value : this.id,
      labId: data.labId.present ? data.labId.value : this.labId,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Milestone(')
          ..write('id: $id, ')
          ..write('labId: $labId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, labId, title, notes, completedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Milestone &&
          other.id == this.id &&
          other.labId == this.labId &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.completedAt == this.completedAt &&
          other.createdAt == this.createdAt);
}

class MilestonesCompanion extends UpdateCompanion<Milestone> {
  final Value<String> id;
  final Value<String> labId;
  final Value<String> title;
  final Value<String?> notes;
  final Value<DateTime?> completedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MilestonesCompanion({
    this.id = const Value.absent(),
    this.labId = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MilestonesCompanion.insert({
    required String id,
    required String labId,
    required String title,
    this.notes = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       labId = Value(labId),
       title = Value(title);
  static Insertable<Milestone> custom({
    Expression<String>? id,
    Expression<String>? labId,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<DateTime>? completedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (labId != null) 'lab_id': labId,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (completedAt != null) 'completed_at': completedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MilestonesCompanion copyWith({
    Value<String>? id,
    Value<String>? labId,
    Value<String>? title,
    Value<String?>? notes,
    Value<DateTime?>? completedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MilestonesCompanion(
      id: id ?? this.id,
      labId: labId ?? this.labId,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      completedAt: completedAt ?? this.completedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (labId.present) {
      map['lab_id'] = Variable<String>(labId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<DateTime>(completedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MilestonesCompanion(')
          ..write('id: $id, ')
          ..write('labId: $labId, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('completedAt: $completedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabMovesTable extends LabMoves with TableInfo<$LabMovesTable, LabMove> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabMovesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _labIdMeta = const VerificationMeta('labId');
  @override
  late final GeneratedColumn<String> labId = GeneratedColumn<String>(
    'lab_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceIndexMeta = const VerificationMeta(
    'sequenceIndex',
  );
  @override
  late final GeneratedColumn<int> sequenceIndex = GeneratedColumn<int>(
    'sequence_index',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _addedAtMeta = const VerificationMeta(
    'addedAt',
  );
  @override
  late final GeneratedColumn<DateTime> addedAt = GeneratedColumn<DateTime>(
    'added_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [labId, moveId, sequenceIndex, addedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lab_moves';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabMove> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('lab_id')) {
      context.handle(
        _labIdMeta,
        labId.isAcceptableOrUnknown(data['lab_id']!, _labIdMeta),
      );
    } else if (isInserting) {
      context.missing(_labIdMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('sequence_index')) {
      context.handle(
        _sequenceIndexMeta,
        sequenceIndex.isAcceptableOrUnknown(
          data['sequence_index']!,
          _sequenceIndexMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sequenceIndexMeta);
    }
    if (data.containsKey('added_at')) {
      context.handle(
        _addedAtMeta,
        addedAt.isAcceptableOrUnknown(data['added_at']!, _addedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {labId, moveId};
  @override
  LabMove map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabMove(
      labId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lab_id'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      )!,
      sequenceIndex: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence_index'],
      )!,
      addedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}added_at'],
      )!,
    );
  }

  @override
  $LabMovesTable createAlias(String alias) {
    return $LabMovesTable(attachedDatabase, alias);
  }
}

class LabMove extends DataClass implements Insertable<LabMove> {
  final String labId;
  final String moveId;
  final int sequenceIndex;
  final DateTime addedAt;
  const LabMove({
    required this.labId,
    required this.moveId,
    required this.sequenceIndex,
    required this.addedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['lab_id'] = Variable<String>(labId);
    map['move_id'] = Variable<String>(moveId);
    map['sequence_index'] = Variable<int>(sequenceIndex);
    map['added_at'] = Variable<DateTime>(addedAt);
    return map;
  }

  LabMovesCompanion toCompanion(bool nullToAbsent) {
    return LabMovesCompanion(
      labId: Value(labId),
      moveId: Value(moveId),
      sequenceIndex: Value(sequenceIndex),
      addedAt: Value(addedAt),
    );
  }

  factory LabMove.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabMove(
      labId: serializer.fromJson<String>(json['labId']),
      moveId: serializer.fromJson<String>(json['moveId']),
      sequenceIndex: serializer.fromJson<int>(json['sequenceIndex']),
      addedAt: serializer.fromJson<DateTime>(json['addedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'labId': serializer.toJson<String>(labId),
      'moveId': serializer.toJson<String>(moveId),
      'sequenceIndex': serializer.toJson<int>(sequenceIndex),
      'addedAt': serializer.toJson<DateTime>(addedAt),
    };
  }

  LabMove copyWith({
    String? labId,
    String? moveId,
    int? sequenceIndex,
    DateTime? addedAt,
  }) => LabMove(
    labId: labId ?? this.labId,
    moveId: moveId ?? this.moveId,
    sequenceIndex: sequenceIndex ?? this.sequenceIndex,
    addedAt: addedAt ?? this.addedAt,
  );
  LabMove copyWithCompanion(LabMovesCompanion data) {
    return LabMove(
      labId: data.labId.present ? data.labId.value : this.labId,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      sequenceIndex: data.sequenceIndex.present
          ? data.sequenceIndex.value
          : this.sequenceIndex,
      addedAt: data.addedAt.present ? data.addedAt.value : this.addedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabMove(')
          ..write('labId: $labId, ')
          ..write('moveId: $moveId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('addedAt: $addedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(labId, moveId, sequenceIndex, addedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabMove &&
          other.labId == this.labId &&
          other.moveId == this.moveId &&
          other.sequenceIndex == this.sequenceIndex &&
          other.addedAt == this.addedAt);
}

class LabMovesCompanion extends UpdateCompanion<LabMove> {
  final Value<String> labId;
  final Value<String> moveId;
  final Value<int> sequenceIndex;
  final Value<DateTime> addedAt;
  final Value<int> rowid;
  const LabMovesCompanion({
    this.labId = const Value.absent(),
    this.moveId = const Value.absent(),
    this.sequenceIndex = const Value.absent(),
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabMovesCompanion.insert({
    required String labId,
    required String moveId,
    required int sequenceIndex,
    this.addedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : labId = Value(labId),
       moveId = Value(moveId),
       sequenceIndex = Value(sequenceIndex);
  static Insertable<LabMove> custom({
    Expression<String>? labId,
    Expression<String>? moveId,
    Expression<int>? sequenceIndex,
    Expression<DateTime>? addedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (labId != null) 'lab_id': labId,
      if (moveId != null) 'move_id': moveId,
      if (sequenceIndex != null) 'sequence_index': sequenceIndex,
      if (addedAt != null) 'added_at': addedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabMovesCompanion copyWith({
    Value<String>? labId,
    Value<String>? moveId,
    Value<int>? sequenceIndex,
    Value<DateTime>? addedAt,
    Value<int>? rowid,
  }) {
    return LabMovesCompanion(
      labId: labId ?? this.labId,
      moveId: moveId ?? this.moveId,
      sequenceIndex: sequenceIndex ?? this.sequenceIndex,
      addedAt: addedAt ?? this.addedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (labId.present) {
      map['lab_id'] = Variable<String>(labId.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (sequenceIndex.present) {
      map['sequence_index'] = Variable<int>(sequenceIndex.value);
    }
    if (addedAt.present) {
      map['added_at'] = Variable<DateTime>(addedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabMovesCompanion(')
          ..write('labId: $labId, ')
          ..write('moveId: $moveId, ')
          ..write('sequenceIndex: $sequenceIndex, ')
          ..write('addedAt: $addedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LabEntriesTable extends LabEntries
    with TableInfo<$LabEntriesTable, LabEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LabEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _labIdMeta = const VerificationMeta('labId');
  @override
  late final GeneratedColumn<String> labId = GeneratedColumn<String>(
    'lab_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES labs (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _contentMeta = const VerificationMeta(
    'content',
  );
  @override
  late final GeneratedColumn<String> content = GeneratedColumn<String>(
    'content',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _videoPathMeta = const VerificationMeta(
    'videoPath',
  );
  @override
  late final GeneratedColumn<String> videoPath = GeneratedColumn<String>(
    'video_path',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    labId,
    content,
    videoPath,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'lab_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<LabEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('lab_id')) {
      context.handle(
        _labIdMeta,
        labId.isAcceptableOrUnknown(data['lab_id']!, _labIdMeta),
      );
    }
    if (data.containsKey('content')) {
      context.handle(
        _contentMeta,
        content.isAcceptableOrUnknown(data['content']!, _contentMeta),
      );
    } else if (isInserting) {
      context.missing(_contentMeta);
    }
    if (data.containsKey('video_path')) {
      context.handle(
        _videoPathMeta,
        videoPath.isAcceptableOrUnknown(data['video_path']!, _videoPathMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  LabEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LabEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      labId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}lab_id'],
      ),
      content: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}content'],
      )!,
      videoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}video_path'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LabEntriesTable createAlias(String alias) {
    return $LabEntriesTable(attachedDatabase, alias);
  }
}

class LabEntry extends DataClass implements Insertable<LabEntry> {
  final String id;
  final String? labId;
  final String content;
  final String? videoPath;
  final DateTime createdAt;
  const LabEntry({
    required this.id,
    this.labId,
    required this.content,
    this.videoPath,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || labId != null) {
      map['lab_id'] = Variable<String>(labId);
    }
    map['content'] = Variable<String>(content);
    if (!nullToAbsent || videoPath != null) {
      map['video_path'] = Variable<String>(videoPath);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LabEntriesCompanion toCompanion(bool nullToAbsent) {
    return LabEntriesCompanion(
      id: Value(id),
      labId: labId == null && nullToAbsent
          ? const Value.absent()
          : Value(labId),
      content: Value(content),
      videoPath: videoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(videoPath),
      createdAt: Value(createdAt),
    );
  }

  factory LabEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LabEntry(
      id: serializer.fromJson<String>(json['id']),
      labId: serializer.fromJson<String?>(json['labId']),
      content: serializer.fromJson<String>(json['content']),
      videoPath: serializer.fromJson<String?>(json['videoPath']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'labId': serializer.toJson<String?>(labId),
      'content': serializer.toJson<String>(content),
      'videoPath': serializer.toJson<String?>(videoPath),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LabEntry copyWith({
    String? id,
    Value<String?> labId = const Value.absent(),
    String? content,
    Value<String?> videoPath = const Value.absent(),
    DateTime? createdAt,
  }) => LabEntry(
    id: id ?? this.id,
    labId: labId.present ? labId.value : this.labId,
    content: content ?? this.content,
    videoPath: videoPath.present ? videoPath.value : this.videoPath,
    createdAt: createdAt ?? this.createdAt,
  );
  LabEntry copyWithCompanion(LabEntriesCompanion data) {
    return LabEntry(
      id: data.id.present ? data.id.value : this.id,
      labId: data.labId.present ? data.labId.value : this.labId,
      content: data.content.present ? data.content.value : this.content,
      videoPath: data.videoPath.present ? data.videoPath.value : this.videoPath,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LabEntry(')
          ..write('id: $id, ')
          ..write('labId: $labId, ')
          ..write('content: $content, ')
          ..write('videoPath: $videoPath, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, labId, content, videoPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LabEntry &&
          other.id == this.id &&
          other.labId == this.labId &&
          other.content == this.content &&
          other.videoPath == this.videoPath &&
          other.createdAt == this.createdAt);
}

class LabEntriesCompanion extends UpdateCompanion<LabEntry> {
  final Value<String> id;
  final Value<String?> labId;
  final Value<String> content;
  final Value<String?> videoPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const LabEntriesCompanion({
    this.id = const Value.absent(),
    this.labId = const Value.absent(),
    this.content = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LabEntriesCompanion.insert({
    required String id,
    this.labId = const Value.absent(),
    required String content,
    this.videoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       content = Value(content);
  static Insertable<LabEntry> custom({
    Expression<String>? id,
    Expression<String>? labId,
    Expression<String>? content,
    Expression<String>? videoPath,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (labId != null) 'lab_id': labId,
      if (content != null) 'content': content,
      if (videoPath != null) 'video_path': videoPath,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LabEntriesCompanion copyWith({
    Value<String>? id,
    Value<String?>? labId,
    Value<String>? content,
    Value<String?>? videoPath,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return LabEntriesCompanion(
      id: id ?? this.id,
      labId: labId ?? this.labId,
      content: content ?? this.content,
      videoPath: videoPath ?? this.videoPath,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (labId.present) {
      map['lab_id'] = Variable<String>(labId.value);
    }
    if (content.present) {
      map['content'] = Variable<String>(content.value);
    }
    if (videoPath.present) {
      map['video_path'] = Variable<String>(videoPath.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LabEntriesCompanion(')
          ..write('id: $id, ')
          ..write('labId: $labId, ')
          ..write('content: $content, ')
          ..write('videoPath: $videoPath, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AchievementsTable extends Achievements
    with TableInfo<$AchievementsTable, Achievement> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AchievementsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _tierMeta = const VerificationMeta('tier');
  @override
  late final GeneratedColumn<String> tier = GeneratedColumn<String>(
    'tier',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unlockedAtMeta = const VerificationMeta(
    'unlockedAt',
  );
  @override
  late final GeneratedColumn<DateTime> unlockedAt = GeneratedColumn<DateTime>(
    'unlocked_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    moveId,
    tier,
    unlockedAt,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'achievements';
  @override
  VerificationContext validateIntegrity(
    Insertable<Achievement> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('tier')) {
      context.handle(
        _tierMeta,
        tier.isAcceptableOrUnknown(data['tier']!, _tierMeta),
      );
    } else if (isInserting) {
      context.missing(_tierMeta);
    }
    if (data.containsKey('unlocked_at')) {
      context.handle(
        _unlockedAtMeta,
        unlockedAt.isAcceptableOrUnknown(data['unlocked_at']!, _unlockedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_unlockedAtMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  Achievement map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Achievement(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      )!,
      tier: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}tier'],
      )!,
      unlockedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}unlocked_at'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AchievementsTable createAlias(String alias) {
    return $AchievementsTable(attachedDatabase, alias);
  }
}

class Achievement extends DataClass implements Insertable<Achievement> {
  final String id;
  final String moveId;

  /// 'seed', 'sprouting', 'growing', or 'mastered'
  final String tier;
  final DateTime unlockedAt;
  final DateTime createdAt;
  const Achievement({
    required this.id,
    required this.moveId,
    required this.tier,
    required this.unlockedAt,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['move_id'] = Variable<String>(moveId);
    map['tier'] = Variable<String>(tier);
    map['unlocked_at'] = Variable<DateTime>(unlockedAt);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AchievementsCompanion toCompanion(bool nullToAbsent) {
    return AchievementsCompanion(
      id: Value(id),
      moveId: Value(moveId),
      tier: Value(tier),
      unlockedAt: Value(unlockedAt),
      createdAt: Value(createdAt),
    );
  }

  factory Achievement.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Achievement(
      id: serializer.fromJson<String>(json['id']),
      moveId: serializer.fromJson<String>(json['moveId']),
      tier: serializer.fromJson<String>(json['tier']),
      unlockedAt: serializer.fromJson<DateTime>(json['unlockedAt']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'moveId': serializer.toJson<String>(moveId),
      'tier': serializer.toJson<String>(tier),
      'unlockedAt': serializer.toJson<DateTime>(unlockedAt),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Achievement copyWith({
    String? id,
    String? moveId,
    String? tier,
    DateTime? unlockedAt,
    DateTime? createdAt,
  }) => Achievement(
    id: id ?? this.id,
    moveId: moveId ?? this.moveId,
    tier: tier ?? this.tier,
    unlockedAt: unlockedAt ?? this.unlockedAt,
    createdAt: createdAt ?? this.createdAt,
  );
  Achievement copyWithCompanion(AchievementsCompanion data) {
    return Achievement(
      id: data.id.present ? data.id.value : this.id,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      tier: data.tier.present ? data.tier.value : this.tier,
      unlockedAt: data.unlockedAt.present
          ? data.unlockedAt.value
          : this.unlockedAt,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Achievement(')
          ..write('id: $id, ')
          ..write('moveId: $moveId, ')
          ..write('tier: $tier, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moveId, tier, unlockedAt, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Achievement &&
          other.id == this.id &&
          other.moveId == this.moveId &&
          other.tier == this.tier &&
          other.unlockedAt == this.unlockedAt &&
          other.createdAt == this.createdAt);
}

class AchievementsCompanion extends UpdateCompanion<Achievement> {
  final Value<String> id;
  final Value<String> moveId;
  final Value<String> tier;
  final Value<DateTime> unlockedAt;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AchievementsCompanion({
    this.id = const Value.absent(),
    this.moveId = const Value.absent(),
    this.tier = const Value.absent(),
    this.unlockedAt = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AchievementsCompanion.insert({
    required String id,
    required String moveId,
    required String tier,
    required DateTime unlockedAt,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       moveId = Value(moveId),
       tier = Value(tier),
       unlockedAt = Value(unlockedAt);
  static Insertable<Achievement> custom({
    Expression<String>? id,
    Expression<String>? moveId,
    Expression<String>? tier,
    Expression<DateTime>? unlockedAt,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moveId != null) 'move_id': moveId,
      if (tier != null) 'tier': tier,
      if (unlockedAt != null) 'unlocked_at': unlockedAt,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AchievementsCompanion copyWith({
    Value<String>? id,
    Value<String>? moveId,
    Value<String>? tier,
    Value<DateTime>? unlockedAt,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AchievementsCompanion(
      id: id ?? this.id,
      moveId: moveId ?? this.moveId,
      tier: tier ?? this.tier,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (tier.present) {
      map['tier'] = Variable<String>(tier.value);
    }
    if (unlockedAt.present) {
      map['unlocked_at'] = Variable<DateTime>(unlockedAt.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AchievementsCompanion(')
          ..write('id: $id, ')
          ..write('moveId: $moveId, ')
          ..write('tier: $tier, ')
          ..write('unlockedAt: $unlockedAt, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuraLinksTable extends AuraLinks
    with TableInfo<$AuraLinksTable, AuraLink> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuraLinksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _fromMoveIdMeta = const VerificationMeta(
    'fromMoveId',
  );
  @override
  late final GeneratedColumn<String> fromMoveId = GeneratedColumn<String>(
    'from_move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _toMoveIdMeta = const VerificationMeta(
    'toMoveId',
  );
  @override
  late final GeneratedColumn<String> toMoveId = GeneratedColumn<String>(
    'to_move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _affinityMeta = const VerificationMeta(
    'affinity',
  );
  @override
  late final GeneratedColumn<String> affinity = GeneratedColumn<String>(
    'affinity',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    fromMoveId,
    toMoveId,
    affinity,
    notes,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aura_links';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuraLink> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('from_move_id')) {
      context.handle(
        _fromMoveIdMeta,
        fromMoveId.isAcceptableOrUnknown(
          data['from_move_id']!,
          _fromMoveIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_fromMoveIdMeta);
    }
    if (data.containsKey('to_move_id')) {
      context.handle(
        _toMoveIdMeta,
        toMoveId.isAcceptableOrUnknown(data['to_move_id']!, _toMoveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_toMoveIdMeta);
    }
    if (data.containsKey('affinity')) {
      context.handle(
        _affinityMeta,
        affinity.isAcceptableOrUnknown(data['affinity']!, _affinityMeta),
      );
    } else if (isInserting) {
      context.missing(_affinityMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {fromMoveId, toMoveId};
  @override
  AuraLink map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuraLink(
      fromMoveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}from_move_id'],
      )!,
      toMoveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}to_move_id'],
      )!,
      affinity: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}affinity'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      ),
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuraLinksTable createAlias(String alias) {
    return $AuraLinksTable(attachedDatabase, alias);
  }
}

class AuraLink extends DataClass implements Insertable<AuraLink> {
  final String fromMoveId;
  final String toMoveId;

  /// 'natural', 'possible', or 'stretch'
  final String affinity;
  final String? notes;
  final DateTime createdAt;
  const AuraLink({
    required this.fromMoveId,
    required this.toMoveId,
    required this.affinity,
    this.notes,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['from_move_id'] = Variable<String>(fromMoveId);
    map['to_move_id'] = Variable<String>(toMoveId);
    map['affinity'] = Variable<String>(affinity);
    if (!nullToAbsent || notes != null) {
      map['notes'] = Variable<String>(notes);
    }
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuraLinksCompanion toCompanion(bool nullToAbsent) {
    return AuraLinksCompanion(
      fromMoveId: Value(fromMoveId),
      toMoveId: Value(toMoveId),
      affinity: Value(affinity),
      notes: notes == null && nullToAbsent
          ? const Value.absent()
          : Value(notes),
      createdAt: Value(createdAt),
    );
  }

  factory AuraLink.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuraLink(
      fromMoveId: serializer.fromJson<String>(json['fromMoveId']),
      toMoveId: serializer.fromJson<String>(json['toMoveId']),
      affinity: serializer.fromJson<String>(json['affinity']),
      notes: serializer.fromJson<String?>(json['notes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'fromMoveId': serializer.toJson<String>(fromMoveId),
      'toMoveId': serializer.toJson<String>(toMoveId),
      'affinity': serializer.toJson<String>(affinity),
      'notes': serializer.toJson<String?>(notes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuraLink copyWith({
    String? fromMoveId,
    String? toMoveId,
    String? affinity,
    Value<String?> notes = const Value.absent(),
    DateTime? createdAt,
  }) => AuraLink(
    fromMoveId: fromMoveId ?? this.fromMoveId,
    toMoveId: toMoveId ?? this.toMoveId,
    affinity: affinity ?? this.affinity,
    notes: notes.present ? notes.value : this.notes,
    createdAt: createdAt ?? this.createdAt,
  );
  AuraLink copyWithCompanion(AuraLinksCompanion data) {
    return AuraLink(
      fromMoveId: data.fromMoveId.present
          ? data.fromMoveId.value
          : this.fromMoveId,
      toMoveId: data.toMoveId.present ? data.toMoveId.value : this.toMoveId,
      affinity: data.affinity.present ? data.affinity.value : this.affinity,
      notes: data.notes.present ? data.notes.value : this.notes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuraLink(')
          ..write('fromMoveId: $fromMoveId, ')
          ..write('toMoveId: $toMoveId, ')
          ..write('affinity: $affinity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(fromMoveId, toMoveId, affinity, notes, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuraLink &&
          other.fromMoveId == this.fromMoveId &&
          other.toMoveId == this.toMoveId &&
          other.affinity == this.affinity &&
          other.notes == this.notes &&
          other.createdAt == this.createdAt);
}

class AuraLinksCompanion extends UpdateCompanion<AuraLink> {
  final Value<String> fromMoveId;
  final Value<String> toMoveId;
  final Value<String> affinity;
  final Value<String?> notes;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuraLinksCompanion({
    this.fromMoveId = const Value.absent(),
    this.toMoveId = const Value.absent(),
    this.affinity = const Value.absent(),
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuraLinksCompanion.insert({
    required String fromMoveId,
    required String toMoveId,
    required String affinity,
    this.notes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : fromMoveId = Value(fromMoveId),
       toMoveId = Value(toMoveId),
       affinity = Value(affinity);
  static Insertable<AuraLink> custom({
    Expression<String>? fromMoveId,
    Expression<String>? toMoveId,
    Expression<String>? affinity,
    Expression<String>? notes,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (fromMoveId != null) 'from_move_id': fromMoveId,
      if (toMoveId != null) 'to_move_id': toMoveId,
      if (affinity != null) 'affinity': affinity,
      if (notes != null) 'notes': notes,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuraLinksCompanion copyWith({
    Value<String>? fromMoveId,
    Value<String>? toMoveId,
    Value<String>? affinity,
    Value<String?>? notes,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuraLinksCompanion(
      fromMoveId: fromMoveId ?? this.fromMoveId,
      toMoveId: toMoveId ?? this.toMoveId,
      affinity: affinity ?? this.affinity,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (fromMoveId.present) {
      map['from_move_id'] = Variable<String>(fromMoveId.value);
    }
    if (toMoveId.present) {
      map['to_move_id'] = Variable<String>(toMoveId.value);
    }
    if (affinity.present) {
      map['affinity'] = Variable<String>(affinity.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuraLinksCompanion(')
          ..write('fromMoveId: $fromMoveId, ')
          ..write('toMoveId: $toMoveId, ')
          ..write('affinity: $affinity, ')
          ..write('notes: $notes, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $AuraPresetsTable extends AuraPresets
    with TableInfo<$AuraPresetsTable, AuraPreset> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AuraPresetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDefaultMeta = const VerificationMeta(
    'isDefault',
  );
  @override
  late final GeneratedColumn<int> isDefault = GeneratedColumn<int>(
    'is_default',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, name, isDefault, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'aura_presets';
  @override
  VerificationContext validateIntegrity(
    Insertable<AuraPreset> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('is_default')) {
      context.handle(
        _isDefaultMeta,
        isDefault.isAcceptableOrUnknown(data['is_default']!, _isDefaultMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  AuraPreset map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AuraPreset(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      isDefault: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}is_default'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $AuraPresetsTable createAlias(String alias) {
    return $AuraPresetsTable(attachedDatabase, alias);
  }
}

class AuraPreset extends DataClass implements Insertable<AuraPreset> {
  final String id;
  final String name;

  /// 1 = active aura preset, 0 = inactive
  final int isDefault;
  final DateTime createdAt;
  const AuraPreset({
    required this.id,
    required this.name,
    required this.isDefault,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['is_default'] = Variable<int>(isDefault);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  AuraPresetsCompanion toCompanion(bool nullToAbsent) {
    return AuraPresetsCompanion(
      id: Value(id),
      name: Value(name),
      isDefault: Value(isDefault),
      createdAt: Value(createdAt),
    );
  }

  factory AuraPreset.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AuraPreset(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      isDefault: serializer.fromJson<int>(json['isDefault']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'isDefault': serializer.toJson<int>(isDefault),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  AuraPreset copyWith({
    String? id,
    String? name,
    int? isDefault,
    DateTime? createdAt,
  }) => AuraPreset(
    id: id ?? this.id,
    name: name ?? this.name,
    isDefault: isDefault ?? this.isDefault,
    createdAt: createdAt ?? this.createdAt,
  );
  AuraPreset copyWithCompanion(AuraPresetsCompanion data) {
    return AuraPreset(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      isDefault: data.isDefault.present ? data.isDefault.value : this.isDefault,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AuraPreset(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, isDefault, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AuraPreset &&
          other.id == this.id &&
          other.name == this.name &&
          other.isDefault == this.isDefault &&
          other.createdAt == this.createdAt);
}

class AuraPresetsCompanion extends UpdateCompanion<AuraPreset> {
  final Value<String> id;
  final Value<String> name;
  final Value<int> isDefault;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const AuraPresetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AuraPresetsCompanion.insert({
    required String id,
    required String name,
    this.isDefault = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<AuraPreset> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<int>? isDefault,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (isDefault != null) 'is_default': isDefault,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AuraPresetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<int>? isDefault,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return AuraPresetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (isDefault.present) {
      map['is_default'] = Variable<int>(isDefault.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AuraPresetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('isDefault: $isDefault, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetsTable extends Sets with TableInfo<$SetsTable, BreakdexSet> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(minTextLength: 1),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _learningStateMeta = const VerificationMeta(
    'learningState',
  );
  @override
  late final GeneratedColumn<int> learningState = GeneratedColumn<int>(
    'learning_state',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<DateTime> updatedAt = GeneratedColumn<DateTime>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    description,
    learningState,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'sets';
  @override
  VerificationContext validateIntegrity(
    Insertable<BreakdexSet> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    }
    if (data.containsKey('learning_state')) {
      context.handle(
        _learningStateMeta,
        learningState.isAcceptableOrUnknown(
          data['learning_state']!,
          _learningStateMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BreakdexSet map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BreakdexSet(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      ),
      learningState: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}learning_state'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SetsTable createAlias(String alias) {
    return $SetsTable(attachedDatabase, alias);
  }
}

class BreakdexSet extends DataClass implements Insertable<BreakdexSet> {
  final String id;
  final String name;
  final String? description;
  final int learningState;
  final DateTime createdAt;
  final DateTime updatedAt;
  const BreakdexSet({
    required this.id,
    required this.name,
    this.description,
    required this.learningState,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || description != null) {
      map['description'] = Variable<String>(description);
    }
    map['learning_state'] = Variable<int>(learningState);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  SetsCompanion toCompanion(bool nullToAbsent) {
    return SetsCompanion(
      id: Value(id),
      name: Value(name),
      description: description == null && nullToAbsent
          ? const Value.absent()
          : Value(description),
      learningState: Value(learningState),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory BreakdexSet.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BreakdexSet(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      description: serializer.fromJson<String?>(json['description']),
      learningState: serializer.fromJson<int>(json['learningState']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'description': serializer.toJson<String?>(description),
      'learningState': serializer.toJson<int>(learningState),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  BreakdexSet copyWith({
    String? id,
    String? name,
    Value<String?> description = const Value.absent(),
    int? learningState,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => BreakdexSet(
    id: id ?? this.id,
    name: name ?? this.name,
    description: description.present ? description.value : this.description,
    learningState: learningState ?? this.learningState,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  BreakdexSet copyWithCompanion(SetsCompanion data) {
    return BreakdexSet(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      description: data.description.present
          ? data.description.value
          : this.description,
      learningState: data.learningState.present
          ? data.learningState.value
          : this.learningState,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BreakdexSet(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('learningState: $learningState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, description, learningState, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BreakdexSet &&
          other.id == this.id &&
          other.name == this.name &&
          other.description == this.description &&
          other.learningState == this.learningState &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SetsCompanion extends UpdateCompanion<BreakdexSet> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> description;
  final Value<int> learningState;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const SetsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.description = const Value.absent(),
    this.learningState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetsCompanion.insert({
    required String id,
    required String name,
    this.description = const Value.absent(),
    this.learningState = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<BreakdexSet> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? description,
    Expression<int>? learningState,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (description != null) 'description': description,
      if (learningState != null) 'learning_state': learningState,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? description,
    Value<int>? learningState,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return SetsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      learningState: learningState ?? this.learningState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (learningState.present) {
      map['learning_state'] = Variable<int>(learningState.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<DateTime>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('description: $description, ')
          ..write('learningState: $learningState, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SetItemsTable extends SetItems with TableInfo<$SetItemsTable, SetItem> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SetItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
    'set_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES sets (id)',
    ),
  );
  static const VerificationMeta _itemTypeMeta = const VerificationMeta(
    'itemType',
  );
  @override
  late final GeneratedColumn<String> itemType = GeneratedColumn<String>(
    'item_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _itemIdMeta = const VerificationMeta('itemId');
  @override
  late final GeneratedColumn<String> itemId = GeneratedColumn<String>(
    'item_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, setId, itemType, itemId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'set_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<SetItem> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
        _setIdMeta,
        setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta),
      );
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('item_type')) {
      context.handle(
        _itemTypeMeta,
        itemType.isAcceptableOrUnknown(data['item_type']!, _itemTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_itemTypeMeta);
    }
    if (data.containsKey('item_id')) {
      context.handle(
        _itemIdMeta,
        itemId.isAcceptableOrUnknown(data['item_id']!, _itemIdMeta),
      );
    } else if (isInserting) {
      context.missing(_itemIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SetItem map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SetItem(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      setId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}set_id'],
      )!,
      itemType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_type'],
      )!,
      itemId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}item_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $SetItemsTable createAlias(String alias) {
    return $SetItemsTable(attachedDatabase, alias);
  }
}

class SetItem extends DataClass implements Insertable<SetItem> {
  final String id;
  final String setId;
  final String itemType;
  final String itemId;
  final int position;
  const SetItem({
    required this.id,
    required this.setId,
    required this.itemType,
    required this.itemId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['set_id'] = Variable<String>(setId);
    map['item_type'] = Variable<String>(itemType);
    map['item_id'] = Variable<String>(itemId);
    map['position'] = Variable<int>(position);
    return map;
  }

  SetItemsCompanion toCompanion(bool nullToAbsent) {
    return SetItemsCompanion(
      id: Value(id),
      setId: Value(setId),
      itemType: Value(itemType),
      itemId: Value(itemId),
      position: Value(position),
    );
  }

  factory SetItem.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SetItem(
      id: serializer.fromJson<String>(json['id']),
      setId: serializer.fromJson<String>(json['setId']),
      itemType: serializer.fromJson<String>(json['itemType']),
      itemId: serializer.fromJson<String>(json['itemId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'setId': serializer.toJson<String>(setId),
      'itemType': serializer.toJson<String>(itemType),
      'itemId': serializer.toJson<String>(itemId),
      'position': serializer.toJson<int>(position),
    };
  }

  SetItem copyWith({
    String? id,
    String? setId,
    String? itemType,
    String? itemId,
    int? position,
  }) => SetItem(
    id: id ?? this.id,
    setId: setId ?? this.setId,
    itemType: itemType ?? this.itemType,
    itemId: itemId ?? this.itemId,
    position: position ?? this.position,
  );
  SetItem copyWithCompanion(SetItemsCompanion data) {
    return SetItem(
      id: data.id.present ? data.id.value : this.id,
      setId: data.setId.present ? data.setId.value : this.setId,
      itemType: data.itemType.present ? data.itemType.value : this.itemType,
      itemId: data.itemId.present ? data.itemId.value : this.itemId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SetItem(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, setId, itemType, itemId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SetItem &&
          other.id == this.id &&
          other.setId == this.setId &&
          other.itemType == this.itemType &&
          other.itemId == this.itemId &&
          other.position == this.position);
}

class SetItemsCompanion extends UpdateCompanion<SetItem> {
  final Value<String> id;
  final Value<String> setId;
  final Value<String> itemType;
  final Value<String> itemId;
  final Value<int> position;
  final Value<int> rowid;
  const SetItemsCompanion({
    this.id = const Value.absent(),
    this.setId = const Value.absent(),
    this.itemType = const Value.absent(),
    this.itemId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SetItemsCompanion.insert({
    required String id,
    required String setId,
    required String itemType,
    required String itemId,
    required int position,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       setId = Value(setId),
       itemType = Value(itemType),
       itemId = Value(itemId),
       position = Value(position);
  static Insertable<SetItem> custom({
    Expression<String>? id,
    Expression<String>? setId,
    Expression<String>? itemType,
    Expression<String>? itemId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (setId != null) 'set_id': setId,
      if (itemType != null) 'item_type': itemType,
      if (itemId != null) 'item_id': itemId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SetItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? setId,
    Value<String>? itemType,
    Value<String>? itemId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return SetItemsCompanion(
      id: id ?? this.id,
      setId: setId ?? this.setId,
      itemType: itemType ?? this.itemType,
      itemId: itemId ?? this.itemId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (itemType.present) {
      map['item_type'] = Variable<String>(itemType.value);
    }
    if (itemId.present) {
      map['item_id'] = Variable<String>(itemId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SetItemsCompanion(')
          ..write('id: $id, ')
          ..write('setId: $setId, ')
          ..write('itemType: $itemType, ')
          ..write('itemId: $itemId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ProvenanceEventsTable extends ProvenanceEvents
    with TableInfo<$ProvenanceEventsTable, ProvenanceEvent> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProvenanceEventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityTypeMeta = const VerificationMeta(
    'entityType',
  );
  @override
  late final GeneratedColumn<String> entityType = GeneratedColumn<String>(
    'entity_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _entityIdMeta = const VerificationMeta(
    'entityId',
  );
  @override
  late final GeneratedColumn<String> entityId = GeneratedColumn<String>(
    'entity_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timestampMeta = const VerificationMeta(
    'timestamp',
  );
  @override
  late final GeneratedColumn<DateTime> timestamp = GeneratedColumn<DateTime>(
    'timestamp',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  static const VerificationMeta _metadataMeta = const VerificationMeta(
    'metadata',
  );
  @override
  late final GeneratedColumn<String> metadata = GeneratedColumn<String>(
    'metadata',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    entityType,
    entityId,
    eventType,
    timestamp,
    metadata,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'provenance_events';
  @override
  VerificationContext validateIntegrity(
    Insertable<ProvenanceEvent> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('entity_type')) {
      context.handle(
        _entityTypeMeta,
        entityType.isAcceptableOrUnknown(data['entity_type']!, _entityTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_entityTypeMeta);
    }
    if (data.containsKey('entity_id')) {
      context.handle(
        _entityIdMeta,
        entityId.isAcceptableOrUnknown(data['entity_id']!, _entityIdMeta),
      );
    } else if (isInserting) {
      context.missing(_entityIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('timestamp')) {
      context.handle(
        _timestampMeta,
        timestamp.isAcceptableOrUnknown(data['timestamp']!, _timestampMeta),
      );
    }
    if (data.containsKey('metadata')) {
      context.handle(
        _metadataMeta,
        metadata.isAcceptableOrUnknown(data['metadata']!, _metadataMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ProvenanceEvent map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ProvenanceEvent(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      entityType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_type'],
      )!,
      entityId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}entity_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      timestamp: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}timestamp'],
      )!,
      metadata: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata'],
      ),
    );
  }

  @override
  $ProvenanceEventsTable createAlias(String alias) {
    return $ProvenanceEventsTable(attachedDatabase, alias);
  }
}

class ProvenanceEvent extends DataClass implements Insertable<ProvenanceEvent> {
  final String id;
  final String entityType;
  final String entityId;
  final String eventType;
  final DateTime timestamp;
  final String? metadata;
  const ProvenanceEvent({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.eventType,
    required this.timestamp,
    this.metadata,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['entity_type'] = Variable<String>(entityType);
    map['entity_id'] = Variable<String>(entityId);
    map['event_type'] = Variable<String>(eventType);
    map['timestamp'] = Variable<DateTime>(timestamp);
    if (!nullToAbsent || metadata != null) {
      map['metadata'] = Variable<String>(metadata);
    }
    return map;
  }

  ProvenanceEventsCompanion toCompanion(bool nullToAbsent) {
    return ProvenanceEventsCompanion(
      id: Value(id),
      entityType: Value(entityType),
      entityId: Value(entityId),
      eventType: Value(eventType),
      timestamp: Value(timestamp),
      metadata: metadata == null && nullToAbsent
          ? const Value.absent()
          : Value(metadata),
    );
  }

  factory ProvenanceEvent.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ProvenanceEvent(
      id: serializer.fromJson<String>(json['id']),
      entityType: serializer.fromJson<String>(json['entityType']),
      entityId: serializer.fromJson<String>(json['entityId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      timestamp: serializer.fromJson<DateTime>(json['timestamp']),
      metadata: serializer.fromJson<String?>(json['metadata']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'entityType': serializer.toJson<String>(entityType),
      'entityId': serializer.toJson<String>(entityId),
      'eventType': serializer.toJson<String>(eventType),
      'timestamp': serializer.toJson<DateTime>(timestamp),
      'metadata': serializer.toJson<String?>(metadata),
    };
  }

  ProvenanceEvent copyWith({
    String? id,
    String? entityType,
    String? entityId,
    String? eventType,
    DateTime? timestamp,
    Value<String?> metadata = const Value.absent(),
  }) => ProvenanceEvent(
    id: id ?? this.id,
    entityType: entityType ?? this.entityType,
    entityId: entityId ?? this.entityId,
    eventType: eventType ?? this.eventType,
    timestamp: timestamp ?? this.timestamp,
    metadata: metadata.present ? metadata.value : this.metadata,
  );
  ProvenanceEvent copyWithCompanion(ProvenanceEventsCompanion data) {
    return ProvenanceEvent(
      id: data.id.present ? data.id.value : this.id,
      entityType: data.entityType.present
          ? data.entityType.value
          : this.entityType,
      entityId: data.entityId.present ? data.entityId.value : this.entityId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      timestamp: data.timestamp.present ? data.timestamp.value : this.timestamp,
      metadata: data.metadata.present ? data.metadata.value : this.metadata,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ProvenanceEvent(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, entityType, entityId, eventType, timestamp, metadata);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ProvenanceEvent &&
          other.id == this.id &&
          other.entityType == this.entityType &&
          other.entityId == this.entityId &&
          other.eventType == this.eventType &&
          other.timestamp == this.timestamp &&
          other.metadata == this.metadata);
}

class ProvenanceEventsCompanion extends UpdateCompanion<ProvenanceEvent> {
  final Value<String> id;
  final Value<String> entityType;
  final Value<String> entityId;
  final Value<String> eventType;
  final Value<DateTime> timestamp;
  final Value<String?> metadata;
  final Value<int> rowid;
  const ProvenanceEventsCompanion({
    this.id = const Value.absent(),
    this.entityType = const Value.absent(),
    this.entityId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.timestamp = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ProvenanceEventsCompanion.insert({
    required String id,
    required String entityType,
    required String entityId,
    required String eventType,
    this.timestamp = const Value.absent(),
    this.metadata = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       entityType = Value(entityType),
       entityId = Value(entityId),
       eventType = Value(eventType);
  static Insertable<ProvenanceEvent> custom({
    Expression<String>? id,
    Expression<String>? entityType,
    Expression<String>? entityId,
    Expression<String>? eventType,
    Expression<DateTime>? timestamp,
    Expression<String>? metadata,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (entityType != null) 'entity_type': entityType,
      if (entityId != null) 'entity_id': entityId,
      if (eventType != null) 'event_type': eventType,
      if (timestamp != null) 'timestamp': timestamp,
      if (metadata != null) 'metadata': metadata,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ProvenanceEventsCompanion copyWith({
    Value<String>? id,
    Value<String>? entityType,
    Value<String>? entityId,
    Value<String>? eventType,
    Value<DateTime>? timestamp,
    Value<String?>? metadata,
    Value<int>? rowid,
  }) {
    return ProvenanceEventsCompanion(
      id: id ?? this.id,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      eventType: eventType ?? this.eventType,
      timestamp: timestamp ?? this.timestamp,
      metadata: metadata ?? this.metadata,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (entityType.present) {
      map['entity_type'] = Variable<String>(entityType.value);
    }
    if (entityId.present) {
      map['entity_id'] = Variable<String>(entityId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (timestamp.present) {
      map['timestamp'] = Variable<DateTime>(timestamp.value);
    }
    if (metadata.present) {
      map['metadata'] = Variable<String>(metadata.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ProvenanceEventsCompanion(')
          ..write('id: $id, ')
          ..write('entityType: $entityType, ')
          ..write('entityId: $entityId, ')
          ..write('eventType: $eventType, ')
          ..write('timestamp: $timestamp, ')
          ..write('metadata: $metadata, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $MoveNoteEntriesTable extends MoveNoteEntries
    with TableInfo<$MoveNoteEntriesTable, MoveNoteEntry> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $MoveNoteEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
    'move_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES moves (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: false,
    defaultValue: currentDateAndTime,
  );
  @override
  List<GeneratedColumn> get $columns => [id, moveId, body, createdAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'move_note_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<MoveNoteEntry> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(
        _moveIdMeta,
        moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta),
      );
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  MoveNoteEntry map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return MoveNoteEntry(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      moveId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}move_id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $MoveNoteEntriesTable createAlias(String alias) {
    return $MoveNoteEntriesTable(attachedDatabase, alias);
  }
}

class MoveNoteEntry extends DataClass implements Insertable<MoveNoteEntry> {
  final String id;
  final String moveId;
  final String body;
  final DateTime createdAt;
  const MoveNoteEntry({
    required this.id,
    required this.moveId,
    required this.body,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['move_id'] = Variable<String>(moveId);
    map['body'] = Variable<String>(body);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  MoveNoteEntriesCompanion toCompanion(bool nullToAbsent) {
    return MoveNoteEntriesCompanion(
      id: Value(id),
      moveId: Value(moveId),
      body: Value(body),
      createdAt: Value(createdAt),
    );
  }

  factory MoveNoteEntry.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return MoveNoteEntry(
      id: serializer.fromJson<String>(json['id']),
      moveId: serializer.fromJson<String>(json['moveId']),
      body: serializer.fromJson<String>(json['body']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'moveId': serializer.toJson<String>(moveId),
      'body': serializer.toJson<String>(body),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  MoveNoteEntry copyWith({
    String? id,
    String? moveId,
    String? body,
    DateTime? createdAt,
  }) => MoveNoteEntry(
    id: id ?? this.id,
    moveId: moveId ?? this.moveId,
    body: body ?? this.body,
    createdAt: createdAt ?? this.createdAt,
  );
  MoveNoteEntry copyWithCompanion(MoveNoteEntriesCompanion data) {
    return MoveNoteEntry(
      id: data.id.present ? data.id.value : this.id,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      body: data.body.present ? data.body.value : this.body,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('MoveNoteEntry(')
          ..write('id: $id, ')
          ..write('moveId: $moveId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, moveId, body, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MoveNoteEntry &&
          other.id == this.id &&
          other.moveId == this.moveId &&
          other.body == this.body &&
          other.createdAt == this.createdAt);
}

class MoveNoteEntriesCompanion extends UpdateCompanion<MoveNoteEntry> {
  final Value<String> id;
  final Value<String> moveId;
  final Value<String> body;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MoveNoteEntriesCompanion({
    this.id = const Value.absent(),
    this.moveId = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MoveNoteEntriesCompanion.insert({
    required String id,
    required String moveId,
    required String body,
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       moveId = Value(moveId),
       body = Value(body);
  static Insertable<MoveNoteEntry> custom({
    Expression<String>? id,
    Expression<String>? moveId,
    Expression<String>? body,
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (moveId != null) 'move_id': moveId,
      if (body != null) 'body': body,
      if (createdAt != null) 'created_at': createdAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  MoveNoteEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? moveId,
    Value<String>? body,
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MoveNoteEntriesCompanion(
      id: id ?? this.id,
      moveId: moveId ?? this.moveId,
      body: body ?? this.body,
      createdAt: createdAt ?? this.createdAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('MoveNoteEntriesCompanion(')
          ..write('id: $id, ')
          ..write('moveId: $moveId, ')
          ..write('body: $body, ')
          ..write('createdAt: $createdAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MovesTable moves = $MovesTable(this);
  late final $CombosTable combos = $CombosTable(this);
  late final $ComboMovesTable comboMoves = $ComboMovesTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $BattleResultsTable battleResults = $BattleResultsTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  late final $FsrsCardsTable fsrsCards = $FsrsCardsTable(this);
  late final $DecksTable decks = $DecksTable(this);
  late final $DeckMovesTable deckMoves = $DeckMovesTable(this);
  late final $AssetManifestTable assetManifest = $AssetManifestTable(this);
  late final $AssetCopiesTable assetCopies = $AssetCopiesTable(this);
  late final $SyncProvidersTable syncProviders = $SyncProvidersTable(this);
  late final $SyncOperationsTable syncOperations = $SyncOperationsTable(this);
  late final $LabsTable labs = $LabsTable(this);
  late final $MilestonesTable milestones = $MilestonesTable(this);
  late final $LabMovesTable labMoves = $LabMovesTable(this);
  late final $LabEntriesTable labEntries = $LabEntriesTable(this);
  late final $AchievementsTable achievements = $AchievementsTable(this);
  late final $AuraLinksTable auraLinks = $AuraLinksTable(this);
  late final $AuraPresetsTable auraPresets = $AuraPresetsTable(this);
  late final $SetsTable sets = $SetsTable(this);
  late final $SetItemsTable setItems = $SetItemsTable(this);
  late final $ProvenanceEventsTable provenanceEvents = $ProvenanceEventsTable(
    this,
  );
  late final $MoveNoteEntriesTable moveNoteEntries = $MoveNoteEntriesTable(
    this,
  );
  late final MovesDao movesDao = MovesDao(this as AppDatabase);
  late final CombosDao combosDao = CombosDao(this as AppDatabase);
  late final ReviewsDao reviewsDao = ReviewsDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  late final FsrsCardsDao fsrsCardsDao = FsrsCardsDao(this as AppDatabase);
  late final DecksDao decksDao = DecksDao(this as AppDatabase);
  late final AssetManifestDao assetManifestDao = AssetManifestDao(
    this as AppDatabase,
  );
  late final AssetCopiesDao assetCopiesDao = AssetCopiesDao(
    this as AppDatabase,
  );
  late final SyncOperationsDao syncOperationsDao = SyncOperationsDao(
    this as AppDatabase,
  );
  late final SyncProvidersDao syncProvidersDao = SyncProvidersDao(
    this as AppDatabase,
  );
  late final LabsDao labsDao = LabsDao(this as AppDatabase);
  late final MilestonesDao milestonesDao = MilestonesDao(this as AppDatabase);
  late final LabEntriesDao labEntriesDao = LabEntriesDao(this as AppDatabase);
  late final AchievementsDao achievementsDao = AchievementsDao(
    this as AppDatabase,
  );
  late final AuraDao auraDao = AuraDao(this as AppDatabase);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    moves,
    combos,
    comboMoves,
    reviews,
    battleResults,
    syncLog,
    fsrsCards,
    decks,
    deckMoves,
    assetManifest,
    assetCopies,
    syncProviders,
    syncOperations,
    labs,
    milestones,
    labMoves,
    labEntries,
    achievements,
    auraLinks,
    auraPresets,
    sets,
    setItems,
    provenanceEvents,
    moveNoteEntries,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'combos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('combo_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('combo_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reviews', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'combos',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('reviews', kind: UpdateKind.update)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'decks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deck_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('deck_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'labs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('milestones', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'labs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lab_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lab_moves', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'labs',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('lab_entries', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('achievements', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('aura_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('aura_links', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'moves',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('move_note_entries', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$MovesTableCreateCompanionBuilder =
    MovesCompanion Function({
      required String id,
      required String name,
      Value<String> learningState,
      Value<String> category,
      Value<String?> videoPath,
      Value<String?> originalVideoName,
      Value<String?> managedAlbumAssetId,
      Value<String?> managedAlbumFilename,
      Value<String?> managedAlbumName,
      Value<DateTime?> archivedAt,
      Value<String?> archiveReason,
      Value<String?> notes,
      Value<String?> imagePaths,
      Value<String?> contentHash,
      Value<int> count,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MovesTableUpdateCompanionBuilder =
    MovesCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> learningState,
      Value<String> category,
      Value<String?> videoPath,
      Value<String?> originalVideoName,
      Value<String?> managedAlbumAssetId,
      Value<String?> managedAlbumFilename,
      Value<String?> managedAlbumName,
      Value<DateTime?> archivedAt,
      Value<String?> archiveReason,
      Value<String?> notes,
      Value<String?> imagePaths,
      Value<String?> contentHash,
      Value<int> count,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MovesTableReferences
    extends BaseReferences<_$AppDatabase, $MovesTable, Move> {
  $$MovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ComboMovesTable, List<ComboMove>>
  _comboMovesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.comboMoves,
    aliasName: $_aliasNameGenerator(db.moves.id, db.comboMoves.moveId),
  );

  $$ComboMovesTableProcessedTableManager get comboMovesRefs {
    final manager = $$ComboMovesTableTableManager(
      $_db,
      $_db.comboMoves,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_comboMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewsTable, List<Review>> _reviewsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.reviews,
    aliasName: $_aliasNameGenerator(db.moves.id, db.reviews.moveId),
  );

  $$ReviewsTableProcessedTableManager get reviewsRefs {
    final manager = $$ReviewsTableTableManager(
      $_db,
      $_db.reviews,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$DeckMovesTable, List<DeckMove>>
  _deckMovesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deckMoves,
    aliasName: $_aliasNameGenerator(db.moves.id, db.deckMoves.moveId),
  );

  $$DeckMovesTableProcessedTableManager get deckMovesRefs {
    final manager = $$DeckMovesTableTableManager(
      $_db,
      $_db.deckMoves,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deckMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LabMovesTable, List<LabMove>> _labMovesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.labMoves,
    aliasName: $_aliasNameGenerator(db.moves.id, db.labMoves.moveId),
  );

  $$LabMovesTableProcessedTableManager get labMovesRefs {
    final manager = $$LabMovesTableTableManager(
      $_db,
      $_db.labMoves,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_labMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AchievementsTable, List<Achievement>>
  _achievementsRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.achievements,
    aliasName: $_aliasNameGenerator(db.moves.id, db.achievements.moveId),
  );

  $$AchievementsTableProcessedTableManager get achievementsRefs {
    final manager = $$AchievementsTableTableManager(
      $_db,
      $_db.achievements,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_achievementsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AuraLinksTable, List<AuraLink>>
  _auraLinksFromRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.auraLinks,
    aliasName: $_aliasNameGenerator(db.moves.id, db.auraLinks.fromMoveId),
  );

  $$AuraLinksTableProcessedTableManager get auraLinksFromRefs {
    final manager = $$AuraLinksTableTableManager(
      $_db,
      $_db.auraLinks,
    ).filter((f) => f.fromMoveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_auraLinksFromRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$AuraLinksTable, List<AuraLink>>
  _auraLinksToRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.auraLinks,
    aliasName: $_aliasNameGenerator(db.moves.id, db.auraLinks.toMoveId),
  );

  $$AuraLinksTableProcessedTableManager get auraLinksToRefs {
    final manager = $$AuraLinksTableTableManager(
      $_db,
      $_db.auraLinks,
    ).filter((f) => f.toMoveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_auraLinksToRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$MoveNoteEntriesTable, List<MoveNoteEntry>>
  _moveNoteEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.moveNoteEntries,
    aliasName: $_aliasNameGenerator(db.moves.id, db.moveNoteEntries.moveId),
  );

  $$MoveNoteEntriesTableProcessedTableManager get moveNoteEntriesRefs {
    final manager = $$MoveNoteEntriesTableTableManager(
      $_db,
      $_db.moveNoteEntries,
    ).filter((f) => f.moveId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _moveNoteEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$MovesTableFilterComposer extends Composer<_$AppDatabase, $MovesTable> {
  $$MovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get originalVideoName => $composableBuilder(
    column: $table.originalVideoName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedAlbumAssetId => $composableBuilder(
    column: $table.managedAlbumAssetId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedAlbumFilename => $composableBuilder(
    column: $table.managedAlbumFilename,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedAlbumName => $composableBuilder(
    column: $table.managedAlbumName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get archiveReason => $composableBuilder(
    column: $table.archiveReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> comboMovesRefs(
    Expression<bool> Function($$ComboMovesTableFilterComposer f) f,
  ) {
    final $$ComboMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comboMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComboMovesTableFilterComposer(
            $db: $db,
            $table: $db.comboMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewsRefs(
    Expression<bool> Function($$ReviewsTableFilterComposer f) f,
  ) {
    final $$ReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableFilterComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> deckMovesRefs(
    Expression<bool> Function($$DeckMovesTableFilterComposer f) f,
  ) {
    final $$DeckMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckMovesTableFilterComposer(
            $db: $db,
            $table: $db.deckMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> labMovesRefs(
    Expression<bool> Function($$LabMovesTableFilterComposer f) f,
  ) {
    final $$LabMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabMovesTableFilterComposer(
            $db: $db,
            $table: $db.labMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> achievementsRefs(
    Expression<bool> Function($$AchievementsTableFilterComposer f) f,
  ) {
    final $$AchievementsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.achievements,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AchievementsTableFilterComposer(
            $db: $db,
            $table: $db.achievements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> auraLinksFromRefs(
    Expression<bool> Function($$AuraLinksTableFilterComposer f) f,
  ) {
    final $$AuraLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auraLinks,
      getReferencedColumn: (t) => t.fromMoveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuraLinksTableFilterComposer(
            $db: $db,
            $table: $db.auraLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> auraLinksToRefs(
    Expression<bool> Function($$AuraLinksTableFilterComposer f) f,
  ) {
    final $$AuraLinksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auraLinks,
      getReferencedColumn: (t) => t.toMoveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuraLinksTableFilterComposer(
            $db: $db,
            $table: $db.auraLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> moveNoteEntriesRefs(
    Expression<bool> Function($$MoveNoteEntriesTableFilterComposer f) f,
  ) {
    final $$MoveNoteEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moveNoteEntries,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoveNoteEntriesTableFilterComposer(
            $db: $db,
            $table: $db.moveNoteEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovesTableOrderingComposer
    extends Composer<_$AppDatabase, $MovesTable> {
  $$MovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get originalVideoName => $composableBuilder(
    column: $table.originalVideoName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedAlbumAssetId => $composableBuilder(
    column: $table.managedAlbumAssetId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedAlbumFilename => $composableBuilder(
    column: $table.managedAlbumFilename,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedAlbumName => $composableBuilder(
    column: $table.managedAlbumName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get archiveReason => $composableBuilder(
    column: $table.archiveReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get count => $composableBuilder(
    column: $table.count,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$MovesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MovesTable> {
  $$MovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<String> get originalVideoName => $composableBuilder(
    column: $table.originalVideoName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managedAlbumAssetId => $composableBuilder(
    column: $table.managedAlbumAssetId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managedAlbumFilename => $composableBuilder(
    column: $table.managedAlbumFilename,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managedAlbumName => $composableBuilder(
    column: $table.managedAlbumName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get archivedAt => $composableBuilder(
    column: $table.archivedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get archiveReason => $composableBuilder(
    column: $table.archiveReason,
    builder: (column) => column,
  );

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get imagePaths => $composableBuilder(
    column: $table.imagePaths,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get count =>
      $composableBuilder(column: $table.count, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  Expression<T> comboMovesRefs<T extends Object>(
    Expression<T> Function($$ComboMovesTableAnnotationComposer a) f,
  ) {
    final $$ComboMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comboMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComboMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.comboMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewsRefs<T extends Object>(
    Expression<T> Function($$ReviewsTableAnnotationComposer a) f,
  ) {
    final $$ReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> deckMovesRefs<T extends Object>(
    Expression<T> Function($$DeckMovesTableAnnotationComposer a) f,
  ) {
    final $$DeckMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.deckMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> labMovesRefs<T extends Object>(
    Expression<T> Function($$LabMovesTableAnnotationComposer a) f,
  ) {
    final $$LabMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labMoves,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.labMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> achievementsRefs<T extends Object>(
    Expression<T> Function($$AchievementsTableAnnotationComposer a) f,
  ) {
    final $$AchievementsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.achievements,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AchievementsTableAnnotationComposer(
            $db: $db,
            $table: $db.achievements,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> auraLinksFromRefs<T extends Object>(
    Expression<T> Function($$AuraLinksTableAnnotationComposer a) f,
  ) {
    final $$AuraLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auraLinks,
      getReferencedColumn: (t) => t.fromMoveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuraLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.auraLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> auraLinksToRefs<T extends Object>(
    Expression<T> Function($$AuraLinksTableAnnotationComposer a) f,
  ) {
    final $$AuraLinksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.auraLinks,
      getReferencedColumn: (t) => t.toMoveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AuraLinksTableAnnotationComposer(
            $db: $db,
            $table: $db.auraLinks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> moveNoteEntriesRefs<T extends Object>(
    Expression<T> Function($$MoveNoteEntriesTableAnnotationComposer a) f,
  ) {
    final $$MoveNoteEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.moveNoteEntries,
      getReferencedColumn: (t) => t.moveId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MoveNoteEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.moveNoteEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$MovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MovesTable,
          Move,
          $$MovesTableFilterComposer,
          $$MovesTableOrderingComposer,
          $$MovesTableAnnotationComposer,
          $$MovesTableCreateCompanionBuilder,
          $$MovesTableUpdateCompanionBuilder,
          (Move, $$MovesTableReferences),
          Move,
          PrefetchHooks Function({
            bool comboMovesRefs,
            bool reviewsRefs,
            bool deckMovesRefs,
            bool labMovesRefs,
            bool achievementsRefs,
            bool auraLinksFromRefs,
            bool auraLinksToRefs,
            bool moveNoteEntriesRefs,
          })
        > {
  $$MovesTableTableManager(_$AppDatabase db, $MovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> learningState = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<String?> originalVideoName = const Value.absent(),
                Value<String?> managedAlbumAssetId = const Value.absent(),
                Value<String?> managedAlbumFilename = const Value.absent(),
                Value<String?> managedAlbumName = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> archiveReason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
                originalVideoName: originalVideoName,
                managedAlbumAssetId: managedAlbumAssetId,
                managedAlbumFilename: managedAlbumFilename,
                managedAlbumName: managedAlbumName,
                archivedAt: archivedAt,
                archiveReason: archiveReason,
                notes: notes,
                imagePaths: imagePaths,
                contentHash: contentHash,
                count: count,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> learningState = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<String?> originalVideoName = const Value.absent(),
                Value<String?> managedAlbumAssetId = const Value.absent(),
                Value<String?> managedAlbumFilename = const Value.absent(),
                Value<String?> managedAlbumName = const Value.absent(),
                Value<DateTime?> archivedAt = const Value.absent(),
                Value<String?> archiveReason = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> imagePaths = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> count = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion.insert(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
                originalVideoName: originalVideoName,
                managedAlbumAssetId: managedAlbumAssetId,
                managedAlbumFilename: managedAlbumFilename,
                managedAlbumName: managedAlbumName,
                archivedAt: archivedAt,
                archiveReason: archiveReason,
                notes: notes,
                imagePaths: imagePaths,
                contentHash: contentHash,
                count: count,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$MovesTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                comboMovesRefs = false,
                reviewsRefs = false,
                deckMovesRefs = false,
                labMovesRefs = false,
                achievementsRefs = false,
                auraLinksFromRefs = false,
                auraLinksToRefs = false,
                moveNoteEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (comboMovesRefs) db.comboMoves,
                    if (reviewsRefs) db.reviews,
                    if (deckMovesRefs) db.deckMoves,
                    if (labMovesRefs) db.labMoves,
                    if (achievementsRefs) db.achievements,
                    if (auraLinksFromRefs) db.auraLinks,
                    if (auraLinksToRefs) db.auraLinks,
                    if (moveNoteEntriesRefs) db.moveNoteEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (comboMovesRefs)
                        await $_getPrefetchedData<Move, $MovesTable, ComboMove>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._comboMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).comboMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewsRefs)
                        await $_getPrefetchedData<Move, $MovesTable, Review>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._reviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(db, table, p0).reviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (deckMovesRefs)
                        await $_getPrefetchedData<Move, $MovesTable, DeckMove>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._deckMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).deckMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (labMovesRefs)
                        await $_getPrefetchedData<Move, $MovesTable, LabMove>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._labMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).labMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (achievementsRefs)
                        await $_getPrefetchedData<
                          Move,
                          $MovesTable,
                          Achievement
                        >(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._achievementsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).achievementsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (auraLinksFromRefs)
                        await $_getPrefetchedData<Move, $MovesTable, AuraLink>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._auraLinksFromRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).auraLinksFromRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.fromMoveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (auraLinksToRefs)
                        await $_getPrefetchedData<Move, $MovesTable, AuraLink>(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._auraLinksToRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).auraLinksToRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.toMoveId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (moveNoteEntriesRefs)
                        await $_getPrefetchedData<
                          Move,
                          $MovesTable,
                          MoveNoteEntry
                        >(
                          currentTable: table,
                          referencedTable: $$MovesTableReferences
                              ._moveNoteEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$MovesTableReferences(
                                db,
                                table,
                                p0,
                              ).moveNoteEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.moveId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$MovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MovesTable,
      Move,
      $$MovesTableFilterComposer,
      $$MovesTableOrderingComposer,
      $$MovesTableAnnotationComposer,
      $$MovesTableCreateCompanionBuilder,
      $$MovesTableUpdateCompanionBuilder,
      (Move, $$MovesTableReferences),
      Move,
      PrefetchHooks Function({
        bool comboMovesRefs,
        bool reviewsRefs,
        bool deckMovesRefs,
        bool labMovesRefs,
        bool achievementsRefs,
        bool auraLinksFromRefs,
        bool auraLinksToRefs,
        bool moveNoteEntriesRefs,
      })
    >;
typedef $$CombosTableCreateCompanionBuilder =
    CombosCompanion Function({
      required String id,
      required String name,
      Value<String?> notes,
      Value<String?> activeVideoPath,
      Value<String?> contentHash,
      Value<int> rowid,
    });
typedef $$CombosTableUpdateCompanionBuilder =
    CombosCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> notes,
      Value<String?> activeVideoPath,
      Value<String?> contentHash,
      Value<int> rowid,
    });

final class $$CombosTableReferences
    extends BaseReferences<_$AppDatabase, $CombosTable, Combo> {
  $$CombosTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ComboMovesTable, List<ComboMove>>
  _comboMovesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.comboMoves,
    aliasName: $_aliasNameGenerator(db.combos.id, db.comboMoves.comboId),
  );

  $$ComboMovesTableProcessedTableManager get comboMovesRefs {
    final manager = $$ComboMovesTableTableManager(
      $_db,
      $_db.comboMoves,
    ).filter((f) => f.comboId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_comboMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$ReviewsTable, List<Review>> _reviewsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.reviews,
    aliasName: $_aliasNameGenerator(db.combos.id, db.reviews.comboId),
  );

  $$ReviewsTableProcessedTableManager get reviewsRefs {
    final manager = $$ReviewsTableTableManager(
      $_db,
      $_db.reviews,
    ).filter((f) => f.comboId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_reviewsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$CombosTableFilterComposer
    extends Composer<_$AppDatabase, $CombosTable> {
  $$CombosTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> comboMovesRefs(
    Expression<bool> Function($$ComboMovesTableFilterComposer f) f,
  ) {
    final $$ComboMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comboMoves,
      getReferencedColumn: (t) => t.comboId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComboMovesTableFilterComposer(
            $db: $db,
            $table: $db.comboMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> reviewsRefs(
    Expression<bool> Function($$ReviewsTableFilterComposer f) f,
  ) {
    final $$ReviewsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.comboId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableFilterComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CombosTableOrderingComposer
    extends Composer<_$AppDatabase, $CombosTable> {
  $$CombosTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CombosTableAnnotationComposer
    extends Composer<_$AppDatabase, $CombosTable> {
  $$CombosTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  Expression<T> comboMovesRefs<T extends Object>(
    Expression<T> Function($$ComboMovesTableAnnotationComposer a) f,
  ) {
    final $$ComboMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.comboMoves,
      getReferencedColumn: (t) => t.comboId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ComboMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.comboMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> reviewsRefs<T extends Object>(
    Expression<T> Function($$ReviewsTableAnnotationComposer a) f,
  ) {
    final $$ReviewsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.reviews,
      getReferencedColumn: (t) => t.comboId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReviewsTableAnnotationComposer(
            $db: $db,
            $table: $db.reviews,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$CombosTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $CombosTable,
          Combo,
          $$CombosTableFilterComposer,
          $$CombosTableOrderingComposer,
          $$CombosTableAnnotationComposer,
          $$CombosTableCreateCompanionBuilder,
          $$CombosTableUpdateCompanionBuilder,
          (Combo, $$CombosTableReferences),
          Combo,
          PrefetchHooks Function({bool comboMovesRefs, bool reviewsRefs})
        > {
  $$CombosTableTableManager(_$AppDatabase db, $CombosTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CombosTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CombosTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CombosTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<String?> activeVideoPath = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CombosCompanion(
                id: id,
                name: name,
                notes: notes,
                activeVideoPath: activeVideoPath,
                contentHash: contentHash,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> notes = const Value.absent(),
                Value<String?> activeVideoPath = const Value.absent(),
                Value<String?> contentHash = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CombosCompanion.insert(
                id: id,
                name: name,
                notes: notes,
                activeVideoPath: activeVideoPath,
                contentHash: contentHash,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$CombosTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({comboMovesRefs = false, reviewsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (comboMovesRefs) db.comboMoves,
                    if (reviewsRefs) db.reviews,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (comboMovesRefs)
                        await $_getPrefetchedData<
                          Combo,
                          $CombosTable,
                          ComboMove
                        >(
                          currentTable: table,
                          referencedTable: $$CombosTableReferences
                              ._comboMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CombosTableReferences(
                                db,
                                table,
                                p0,
                              ).comboMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.comboId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (reviewsRefs)
                        await $_getPrefetchedData<Combo, $CombosTable, Review>(
                          currentTable: table,
                          referencedTable: $$CombosTableReferences
                              ._reviewsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$CombosTableReferences(
                                db,
                                table,
                                p0,
                              ).reviewsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.comboId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$CombosTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $CombosTable,
      Combo,
      $$CombosTableFilterComposer,
      $$CombosTableOrderingComposer,
      $$CombosTableAnnotationComposer,
      $$CombosTableCreateCompanionBuilder,
      $$CombosTableUpdateCompanionBuilder,
      (Combo, $$CombosTableReferences),
      Combo,
      PrefetchHooks Function({bool comboMovesRefs, bool reviewsRefs})
    >;
typedef $$ComboMovesTableCreateCompanionBuilder =
    ComboMovesCompanion Function({
      required String id,
      required int sequenceIndex,
      required String comboId,
      required String moveId,
      Value<int> rowid,
    });
typedef $$ComboMovesTableUpdateCompanionBuilder =
    ComboMovesCompanion Function({
      Value<String> id,
      Value<int> sequenceIndex,
      Value<String> comboId,
      Value<String> moveId,
      Value<int> rowid,
    });

final class $$ComboMovesTableReferences
    extends BaseReferences<_$AppDatabase, $ComboMovesTable, ComboMove> {
  $$ComboMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $CombosTable _comboIdTable(_$AppDatabase db) => db.combos.createAlias(
    $_aliasNameGenerator(db.comboMoves.comboId, db.combos.id),
  );

  $$CombosTableProcessedTableManager get comboId {
    final $_column = $_itemColumn<String>('combo_id')!;

    final manager = $$CombosTableTableManager(
      $_db,
      $_db.combos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comboIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.comboMoves.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get moveId {
    final $_column = $_itemColumn<String>('move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ComboMovesTableFilterComposer
    extends Composer<_$AppDatabase, $ComboMovesTable> {
  $$ComboMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  $$CombosTableFilterComposer get comboId {
    final $$CombosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableFilterComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ComboMovesTableOrderingComposer
    extends Composer<_$AppDatabase, $ComboMovesTable> {
  $$ComboMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  $$CombosTableOrderingComposer get comboId {
    final $$CombosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableOrderingComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ComboMovesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ComboMovesTable> {
  $$ComboMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => column,
  );

  $$CombosTableAnnotationComposer get comboId {
    final $$CombosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableAnnotationComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ComboMovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ComboMovesTable,
          ComboMove,
          $$ComboMovesTableFilterComposer,
          $$ComboMovesTableOrderingComposer,
          $$ComboMovesTableAnnotationComposer,
          $$ComboMovesTableCreateCompanionBuilder,
          $$ComboMovesTableUpdateCompanionBuilder,
          (ComboMove, $$ComboMovesTableReferences),
          ComboMove,
          PrefetchHooks Function({bool comboId, bool moveId})
        > {
  $$ComboMovesTableTableManager(_$AppDatabase db, $ComboMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ComboMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ComboMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ComboMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> sequenceIndex = const Value.absent(),
                Value<String> comboId = const Value.absent(),
                Value<String> moveId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ComboMovesCompanion(
                id: id,
                sequenceIndex: sequenceIndex,
                comboId: comboId,
                moveId: moveId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int sequenceIndex,
                required String comboId,
                required String moveId,
                Value<int> rowid = const Value.absent(),
              }) => ComboMovesCompanion.insert(
                id: id,
                sequenceIndex: sequenceIndex,
                comboId: comboId,
                moveId: moveId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ComboMovesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({comboId = false, moveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (comboId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.comboId,
                                referencedTable: $$ComboMovesTableReferences
                                    ._comboIdTable(db),
                                referencedColumn: $$ComboMovesTableReferences
                                    ._comboIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable: $$ComboMovesTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$ComboMovesTableReferences
                                    ._moveIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ComboMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ComboMovesTable,
      ComboMove,
      $$ComboMovesTableFilterComposer,
      $$ComboMovesTableOrderingComposer,
      $$ComboMovesTableAnnotationComposer,
      $$ComboMovesTableCreateCompanionBuilder,
      $$ComboMovesTableUpdateCompanionBuilder,
      (ComboMove, $$ComboMovesTableReferences),
      ComboMove,
      PrefetchHooks Function({bool comboId, bool moveId})
    >;
typedef $$ReviewsTableCreateCompanionBuilder =
    ReviewsCompanion Function({
      required String id,
      required String rating,
      required String reviewType,
      Value<DateTime> reviewedAt,
      Value<String?> moveId,
      Value<String?> comboId,
      Value<String?> entityIdSnapshot,
      Value<String?> entityType,
      Value<String?> entityDisplayName,
      Value<String?> entityCategory,
      Value<int?> fsrsPreState,
      Value<int?> fsrsPostState,
      Value<int> rowid,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<String> id,
      Value<String> rating,
      Value<String> reviewType,
      Value<DateTime> reviewedAt,
      Value<String?> moveId,
      Value<String?> comboId,
      Value<String?> entityIdSnapshot,
      Value<String?> entityType,
      Value<String?> entityDisplayName,
      Value<String?> entityCategory,
      Value<int?> fsrsPreState,
      Value<int?> fsrsPostState,
      Value<int> rowid,
    });

final class $$ReviewsTableReferences
    extends BaseReferences<_$AppDatabase, $ReviewsTable, Review> {
  $$ReviewsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.reviews.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager? get moveId {
    final $_column = $_itemColumn<String>('move_id');
    if ($_column == null) return null;
    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $CombosTable _comboIdTable(_$AppDatabase db) => db.combos.createAlias(
    $_aliasNameGenerator(db.reviews.comboId, db.combos.id),
  );

  $$CombosTableProcessedTableManager? get comboId {
    final $_column = $_itemColumn<String>('combo_id');
    if ($_column == null) return null;
    final manager = $$CombosTableTableManager(
      $_db,
      $_db.combos,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_comboIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReviewsTableFilterComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get reviewType => $composableBuilder(
    column: $table.reviewType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityIdSnapshot => $composableBuilder(
    column: $table.entityIdSnapshot,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityCategory => $composableBuilder(
    column: $table.entityCategory,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fsrsPreState => $composableBuilder(
    column: $table.fsrsPreState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fsrsPostState => $composableBuilder(
    column: $table.fsrsPostState,
    builder: (column) => ColumnFilters(column),
  );

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CombosTableFilterComposer get comboId {
    final $$CombosTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableFilterComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableOrderingComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get rating => $composableBuilder(
    column: $table.rating,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get reviewType => $composableBuilder(
    column: $table.reviewType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityIdSnapshot => $composableBuilder(
    column: $table.entityIdSnapshot,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityCategory => $composableBuilder(
    column: $table.entityCategory,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fsrsPreState => $composableBuilder(
    column: $table.fsrsPreState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fsrsPostState => $composableBuilder(
    column: $table.fsrsPostState,
    builder: (column) => ColumnOrderings(column),
  );

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CombosTableOrderingComposer get comboId {
    final $$CombosTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableOrderingComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ReviewsTable> {
  $$ReviewsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get rating =>
      $composableBuilder(column: $table.rating, builder: (column) => column);

  GeneratedColumn<String> get reviewType => $composableBuilder(
    column: $table.reviewType,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get reviewedAt => $composableBuilder(
    column: $table.reviewedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityIdSnapshot => $composableBuilder(
    column: $table.entityIdSnapshot,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityDisplayName => $composableBuilder(
    column: $table.entityDisplayName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityCategory => $composableBuilder(
    column: $table.entityCategory,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fsrsPreState => $composableBuilder(
    column: $table.fsrsPreState,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fsrsPostState => $composableBuilder(
    column: $table.fsrsPostState,
    builder: (column) => column,
  );

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$CombosTableAnnotationComposer get comboId {
    final $$CombosTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.comboId,
      referencedTable: $db.combos,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$CombosTableAnnotationComposer(
            $db: $db,
            $table: $db.combos,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReviewsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ReviewsTable,
          Review,
          $$ReviewsTableFilterComposer,
          $$ReviewsTableOrderingComposer,
          $$ReviewsTableAnnotationComposer,
          $$ReviewsTableCreateCompanionBuilder,
          $$ReviewsTableUpdateCompanionBuilder,
          (Review, $$ReviewsTableReferences),
          Review,
          PrefetchHooks Function({bool moveId, bool comboId})
        > {
  $$ReviewsTableTableManager(_$AppDatabase db, $ReviewsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReviewsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReviewsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReviewsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> rating = const Value.absent(),
                Value<String> reviewType = const Value.absent(),
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String?> moveId = const Value.absent(),
                Value<String?> comboId = const Value.absent(),
                Value<String?> entityIdSnapshot = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityDisplayName = const Value.absent(),
                Value<String?> entityCategory = const Value.absent(),
                Value<int?> fsrsPreState = const Value.absent(),
                Value<int?> fsrsPostState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                rating: rating,
                reviewType: reviewType,
                reviewedAt: reviewedAt,
                moveId: moveId,
                comboId: comboId,
                entityIdSnapshot: entityIdSnapshot,
                entityType: entityType,
                entityDisplayName: entityDisplayName,
                entityCategory: entityCategory,
                fsrsPreState: fsrsPreState,
                fsrsPostState: fsrsPostState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rating,
                required String reviewType,
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String?> moveId = const Value.absent(),
                Value<String?> comboId = const Value.absent(),
                Value<String?> entityIdSnapshot = const Value.absent(),
                Value<String?> entityType = const Value.absent(),
                Value<String?> entityDisplayName = const Value.absent(),
                Value<String?> entityCategory = const Value.absent(),
                Value<int?> fsrsPreState = const Value.absent(),
                Value<int?> fsrsPostState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                rating: rating,
                reviewType: reviewType,
                reviewedAt: reviewedAt,
                moveId: moveId,
                comboId: comboId,
                entityIdSnapshot: entityIdSnapshot,
                entityType: entityType,
                entityDisplayName: entityDisplayName,
                entityCategory: entityCategory,
                fsrsPreState: fsrsPreState,
                fsrsPostState: fsrsPostState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReviewsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({moveId = false, comboId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable: $$ReviewsTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$ReviewsTableReferences
                                    ._moveIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (comboId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.comboId,
                                referencedTable: $$ReviewsTableReferences
                                    ._comboIdTable(db),
                                referencedColumn: $$ReviewsTableReferences
                                    ._comboIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReviewsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ReviewsTable,
      Review,
      $$ReviewsTableFilterComposer,
      $$ReviewsTableOrderingComposer,
      $$ReviewsTableAnnotationComposer,
      $$ReviewsTableCreateCompanionBuilder,
      $$ReviewsTableUpdateCompanionBuilder,
      (Review, $$ReviewsTableReferences),
      Review,
      PrefetchHooks Function({bool moveId, bool comboId})
    >;
typedef $$BattleResultsTableCreateCompanionBuilder =
    BattleResultsCompanion Function({
      required String id,
      required int score,
      required int movesReviewed,
      required int goodCount,
      required int hardCount,
      required int againCount,
      required int longestStreak,
      required String difficulty,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });
typedef $$BattleResultsTableUpdateCompanionBuilder =
    BattleResultsCompanion Function({
      Value<String> id,
      Value<int> score,
      Value<int> movesReviewed,
      Value<int> goodCount,
      Value<int> hardCount,
      Value<int> againCount,
      Value<int> longestStreak,
      Value<String> difficulty,
      Value<DateTime> playedAt,
      Value<int> rowid,
    });

class $$BattleResultsTableFilterComposer
    extends Composer<_$AppDatabase, $BattleResultsTable> {
  $$BattleResultsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get movesReviewed => $composableBuilder(
    column: $table.movesReviewed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get goodCount => $composableBuilder(
    column: $table.goodCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get hardCount => $composableBuilder(
    column: $table.hardCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get againCount => $composableBuilder(
    column: $table.againCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$BattleResultsTableOrderingComposer
    extends Composer<_$AppDatabase, $BattleResultsTable> {
  $$BattleResultsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get score => $composableBuilder(
    column: $table.score,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get movesReviewed => $composableBuilder(
    column: $table.movesReviewed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get goodCount => $composableBuilder(
    column: $table.goodCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get hardCount => $composableBuilder(
    column: $table.hardCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get againCount => $composableBuilder(
    column: $table.againCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get playedAt => $composableBuilder(
    column: $table.playedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BattleResultsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BattleResultsTable> {
  $$BattleResultsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get score =>
      $composableBuilder(column: $table.score, builder: (column) => column);

  GeneratedColumn<int> get movesReviewed => $composableBuilder(
    column: $table.movesReviewed,
    builder: (column) => column,
  );

  GeneratedColumn<int> get goodCount =>
      $composableBuilder(column: $table.goodCount, builder: (column) => column);

  GeneratedColumn<int> get hardCount =>
      $composableBuilder(column: $table.hardCount, builder: (column) => column);

  GeneratedColumn<int> get againCount => $composableBuilder(
    column: $table.againCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get longestStreak => $composableBuilder(
    column: $table.longestStreak,
    builder: (column) => column,
  );

  GeneratedColumn<String> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get playedAt =>
      $composableBuilder(column: $table.playedAt, builder: (column) => column);
}

class $$BattleResultsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BattleResultsTable,
          BattleResult,
          $$BattleResultsTableFilterComposer,
          $$BattleResultsTableOrderingComposer,
          $$BattleResultsTableAnnotationComposer,
          $$BattleResultsTableCreateCompanionBuilder,
          $$BattleResultsTableUpdateCompanionBuilder,
          (
            BattleResult,
            BaseReferences<_$AppDatabase, $BattleResultsTable, BattleResult>,
          ),
          BattleResult,
          PrefetchHooks Function()
        > {
  $$BattleResultsTableTableManager(_$AppDatabase db, $BattleResultsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BattleResultsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BattleResultsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BattleResultsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<int> score = const Value.absent(),
                Value<int> movesReviewed = const Value.absent(),
                Value<int> goodCount = const Value.absent(),
                Value<int> hardCount = const Value.absent(),
                Value<int> againCount = const Value.absent(),
                Value<int> longestStreak = const Value.absent(),
                Value<String> difficulty = const Value.absent(),
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BattleResultsCompanion(
                id: id,
                score: score,
                movesReviewed: movesReviewed,
                goodCount: goodCount,
                hardCount: hardCount,
                againCount: againCount,
                longestStreak: longestStreak,
                difficulty: difficulty,
                playedAt: playedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required int score,
                required int movesReviewed,
                required int goodCount,
                required int hardCount,
                required int againCount,
                required int longestStreak,
                required String difficulty,
                Value<DateTime> playedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BattleResultsCompanion.insert(
                id: id,
                score: score,
                movesReviewed: movesReviewed,
                goodCount: goodCount,
                hardCount: hardCount,
                againCount: againCount,
                longestStreak: longestStreak,
                difficulty: difficulty,
                playedAt: playedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$BattleResultsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BattleResultsTable,
      BattleResult,
      $$BattleResultsTableFilterComposer,
      $$BattleResultsTableOrderingComposer,
      $$BattleResultsTableAnnotationComposer,
      $$BattleResultsTableCreateCompanionBuilder,
      $$BattleResultsTableUpdateCompanionBuilder,
      (
        BattleResult,
        BaseReferences<_$AppDatabase, $BattleResultsTable, BattleResult>,
      ),
      BattleResult,
      PrefetchHooks Function()
    >;
typedef $$SyncLogTableCreateCompanionBuilder =
    SyncLogCompanion Function({
      required String entityId,
      required String entityTable,
      required String action,
      Value<DateTime> changedAt,
      Value<bool> synced,
      Value<bool> videoSynced,
      Value<int> rowid,
    });
typedef $$SyncLogTableUpdateCompanionBuilder =
    SyncLogCompanion Function({
      Value<String> entityId,
      Value<String> entityTable,
      Value<String> action,
      Value<DateTime> changedAt,
      Value<bool> synced,
      Value<bool> videoSynced,
      Value<int> rowid,
    });

class $$SyncLogTableFilterComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get videoSynced => $composableBuilder(
    column: $table.videoSynced,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncLogTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get action => $composableBuilder(
    column: $table.action,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get changedAt => $composableBuilder(
    column: $table.changedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get synced => $composableBuilder(
    column: $table.synced,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get videoSynced => $composableBuilder(
    column: $table.videoSynced,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncLogTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncLogTable> {
  $$SyncLogTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityTable => $composableBuilder(
    column: $table.entityTable,
    builder: (column) => column,
  );

  GeneratedColumn<String> get action =>
      $composableBuilder(column: $table.action, builder: (column) => column);

  GeneratedColumn<DateTime> get changedAt =>
      $composableBuilder(column: $table.changedAt, builder: (column) => column);

  GeneratedColumn<bool> get synced =>
      $composableBuilder(column: $table.synced, builder: (column) => column);

  GeneratedColumn<bool> get videoSynced => $composableBuilder(
    column: $table.videoSynced,
    builder: (column) => column,
  );
}

class $$SyncLogTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncLogTable,
          SyncLogData,
          $$SyncLogTableFilterComposer,
          $$SyncLogTableOrderingComposer,
          $$SyncLogTableAnnotationComposer,
          $$SyncLogTableCreateCompanionBuilder,
          $$SyncLogTableUpdateCompanionBuilder,
          (
            SyncLogData,
            BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>,
          ),
          SyncLogData,
          PrefetchHooks Function()
        > {
  $$SyncLogTableTableManager(_$AppDatabase db, $SyncLogTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncLogTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncLogTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncLogTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> entityTable = const Value.absent(),
                Value<String> action = const Value.absent(),
                Value<DateTime> changedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> videoSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLogCompanion(
                entityId: entityId,
                entityTable: entityTable,
                action: action,
                changedAt: changedAt,
                synced: synced,
                videoSynced: videoSynced,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                required String entityTable,
                required String action,
                Value<DateTime> changedAt = const Value.absent(),
                Value<bool> synced = const Value.absent(),
                Value<bool> videoSynced = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncLogCompanion.insert(
                entityId: entityId,
                entityTable: entityTable,
                action: action,
                changedAt: changedAt,
                synced: synced,
                videoSynced: videoSynced,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncLogTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncLogTable,
      SyncLogData,
      $$SyncLogTableFilterComposer,
      $$SyncLogTableOrderingComposer,
      $$SyncLogTableAnnotationComposer,
      $$SyncLogTableCreateCompanionBuilder,
      $$SyncLogTableUpdateCompanionBuilder,
      (SyncLogData, BaseReferences<_$AppDatabase, $SyncLogTable, SyncLogData>),
      SyncLogData,
      PrefetchHooks Function()
    >;
typedef $$FsrsCardsTableCreateCompanionBuilder =
    FsrsCardsCompanion Function({
      required String entityId,
      Value<String> entityType,
      Value<double> stability,
      Value<double> difficulty,
      Value<DateTime> due,
      Value<DateTime?> lastReview,
      Value<int> reps,
      Value<int> lapses,
      Value<int> fsrsState,
      Value<int> rowid,
    });
typedef $$FsrsCardsTableUpdateCompanionBuilder =
    FsrsCardsCompanion Function({
      Value<String> entityId,
      Value<String> entityType,
      Value<double> stability,
      Value<double> difficulty,
      Value<DateTime> due,
      Value<DateTime?> lastReview,
      Value<int> reps,
      Value<int> lapses,
      Value<int> fsrsState,
      Value<int> rowid,
    });

class $$FsrsCardsTableFilterComposer
    extends Composer<_$AppDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnFilters(column),
  );
}

class $$FsrsCardsTableOrderingComposer
    extends Composer<_$AppDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get stability => $composableBuilder(
    column: $table.stability,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get due => $composableBuilder(
    column: $table.due,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reps => $composableBuilder(
    column: $table.reps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get lapses => $composableBuilder(
    column: $table.lapses,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fsrsState => $composableBuilder(
    column: $table.fsrsState,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$FsrsCardsTableAnnotationComposer
    extends Composer<_$AppDatabase, $FsrsCardsTable> {
  $$FsrsCardsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<double> get stability =>
      $composableBuilder(column: $table.stability, builder: (column) => column);

  GeneratedColumn<double> get difficulty => $composableBuilder(
    column: $table.difficulty,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get due =>
      $composableBuilder(column: $table.due, builder: (column) => column);

  GeneratedColumn<DateTime> get lastReview => $composableBuilder(
    column: $table.lastReview,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reps =>
      $composableBuilder(column: $table.reps, builder: (column) => column);

  GeneratedColumn<int> get lapses =>
      $composableBuilder(column: $table.lapses, builder: (column) => column);

  GeneratedColumn<int> get fsrsState =>
      $composableBuilder(column: $table.fsrsState, builder: (column) => column);
}

class $$FsrsCardsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $FsrsCardsTable,
          FsrsCard,
          $$FsrsCardsTableFilterComposer,
          $$FsrsCardsTableOrderingComposer,
          $$FsrsCardsTableAnnotationComposer,
          $$FsrsCardsTableCreateCompanionBuilder,
          $$FsrsCardsTableUpdateCompanionBuilder,
          (FsrsCard, BaseReferences<_$AppDatabase, $FsrsCardsTable, FsrsCard>),
          FsrsCard,
          PrefetchHooks Function()
        > {
  $$FsrsCardsTableTableManager(_$AppDatabase db, $FsrsCardsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$FsrsCardsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$FsrsCardsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$FsrsCardsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> entityId = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> fsrsState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FsrsCardsCompanion(
                entityId: entityId,
                entityType: entityType,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                fsrsState: fsrsState,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String entityId,
                Value<String> entityType = const Value.absent(),
                Value<double> stability = const Value.absent(),
                Value<double> difficulty = const Value.absent(),
                Value<DateTime> due = const Value.absent(),
                Value<DateTime?> lastReview = const Value.absent(),
                Value<int> reps = const Value.absent(),
                Value<int> lapses = const Value.absent(),
                Value<int> fsrsState = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => FsrsCardsCompanion.insert(
                entityId: entityId,
                entityType: entityType,
                stability: stability,
                difficulty: difficulty,
                due: due,
                lastReview: lastReview,
                reps: reps,
                lapses: lapses,
                fsrsState: fsrsState,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$FsrsCardsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $FsrsCardsTable,
      FsrsCard,
      $$FsrsCardsTableFilterComposer,
      $$FsrsCardsTableOrderingComposer,
      $$FsrsCardsTableAnnotationComposer,
      $$FsrsCardsTableCreateCompanionBuilder,
      $$FsrsCardsTableUpdateCompanionBuilder,
      (FsrsCard, BaseReferences<_$AppDatabase, $FsrsCardsTable, FsrsCard>),
      FsrsCard,
      PrefetchHooks Function()
    >;
typedef $$DecksTableCreateCompanionBuilder =
    DecksCompanion Function({
      required String id,
      required String name,
      Value<String> deckType,
      Value<String?> filterCriteria,
      Value<int?> sessionSize,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$DecksTableUpdateCompanionBuilder =
    DecksCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> deckType,
      Value<String?> filterCriteria,
      Value<int?> sessionSize,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$DecksTableReferences
    extends BaseReferences<_$AppDatabase, $DecksTable, Deck> {
  $$DecksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$DeckMovesTable, List<DeckMove>>
  _deckMovesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.deckMoves,
    aliasName: $_aliasNameGenerator(db.decks.id, db.deckMoves.deckId),
  );

  $$DeckMovesTableProcessedTableManager get deckMovesRefs {
    final manager = $$DeckMovesTableTableManager(
      $_db,
      $_db.deckMoves,
    ).filter((f) => f.deckId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_deckMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$DecksTableFilterComposer extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deckType => $composableBuilder(
    column: $table.deckType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get filterCriteria => $composableBuilder(
    column: $table.filterCriteria,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sessionSize => $composableBuilder(
    column: $table.sessionSize,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> deckMovesRefs(
    Expression<bool> Function($$DeckMovesTableFilterComposer f) f,
  ) {
    final $$DeckMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckMoves,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckMovesTableFilterComposer(
            $db: $db,
            $table: $db.deckMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableOrderingComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deckType => $composableBuilder(
    column: $table.deckType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get filterCriteria => $composableBuilder(
    column: $table.filterCriteria,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sessionSize => $composableBuilder(
    column: $table.sessionSize,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DecksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DecksTable> {
  $$DecksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get deckType =>
      $composableBuilder(column: $table.deckType, builder: (column) => column);

  GeneratedColumn<String> get filterCriteria => $composableBuilder(
    column: $table.filterCriteria,
    builder: (column) => column,
  );

  GeneratedColumn<int> get sessionSize => $composableBuilder(
    column: $table.sessionSize,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> deckMovesRefs<T extends Object>(
    Expression<T> Function($$DeckMovesTableAnnotationComposer a) f,
  ) {
    final $$DeckMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.deckMoves,
      getReferencedColumn: (t) => t.deckId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DeckMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.deckMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$DecksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DecksTable,
          Deck,
          $$DecksTableFilterComposer,
          $$DecksTableOrderingComposer,
          $$DecksTableAnnotationComposer,
          $$DecksTableCreateCompanionBuilder,
          $$DecksTableUpdateCompanionBuilder,
          (Deck, $$DecksTableReferences),
          Deck,
          PrefetchHooks Function({bool deckMovesRefs})
        > {
  $$DecksTableTableManager(_$AppDatabase db, $DecksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DecksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DecksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DecksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> deckType = const Value.absent(),
                Value<String?> filterCriteria = const Value.absent(),
                Value<int?> sessionSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion(
                id: id,
                name: name,
                deckType: deckType,
                filterCriteria: filterCriteria,
                sessionSize: sessionSize,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> deckType = const Value.absent(),
                Value<String?> filterCriteria = const Value.absent(),
                Value<int?> sessionSize = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DecksCompanion.insert(
                id: id,
                name: name,
                deckType: deckType,
                filterCriteria: filterCriteria,
                sessionSize: sessionSize,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$DecksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({deckMovesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (deckMovesRefs) db.deckMoves],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (deckMovesRefs)
                    await $_getPrefetchedData<Deck, $DecksTable, DeckMove>(
                      currentTable: table,
                      referencedTable: $$DecksTableReferences
                          ._deckMovesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$DecksTableReferences(db, table, p0).deckMovesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.deckId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$DecksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DecksTable,
      Deck,
      $$DecksTableFilterComposer,
      $$DecksTableOrderingComposer,
      $$DecksTableAnnotationComposer,
      $$DecksTableCreateCompanionBuilder,
      $$DecksTableUpdateCompanionBuilder,
      (Deck, $$DecksTableReferences),
      Deck,
      PrefetchHooks Function({bool deckMovesRefs})
    >;
typedef $$DeckMovesTableCreateCompanionBuilder =
    DeckMovesCompanion Function({
      required String deckId,
      required String moveId,
      Value<int> rowid,
    });
typedef $$DeckMovesTableUpdateCompanionBuilder =
    DeckMovesCompanion Function({
      Value<String> deckId,
      Value<String> moveId,
      Value<int> rowid,
    });

final class $$DeckMovesTableReferences
    extends BaseReferences<_$AppDatabase, $DeckMovesTable, DeckMove> {
  $$DeckMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $DecksTable _deckIdTable(_$AppDatabase db) => db.decks.createAlias(
    $_aliasNameGenerator(db.deckMoves.deckId, db.decks.id),
  );

  $$DecksTableProcessedTableManager get deckId {
    final $_column = $_itemColumn<String>('deck_id')!;

    final manager = $$DecksTableTableManager(
      $_db,
      $_db.decks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_deckIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.deckMoves.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get moveId {
    final $_column = $_itemColumn<String>('move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DeckMovesTableFilterComposer
    extends Composer<_$AppDatabase, $DeckMovesTable> {
  $$DeckMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DecksTableFilterComposer get deckId {
    final $$DecksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableFilterComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckMovesTableOrderingComposer
    extends Composer<_$AppDatabase, $DeckMovesTable> {
  $$DeckMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DecksTableOrderingComposer get deckId {
    final $$DecksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableOrderingComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckMovesTableAnnotationComposer
    extends Composer<_$AppDatabase, $DeckMovesTable> {
  $$DeckMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  $$DecksTableAnnotationComposer get deckId {
    final $$DecksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.deckId,
      referencedTable: $db.decks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DecksTableAnnotationComposer(
            $db: $db,
            $table: $db.decks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DeckMovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DeckMovesTable,
          DeckMove,
          $$DeckMovesTableFilterComposer,
          $$DeckMovesTableOrderingComposer,
          $$DeckMovesTableAnnotationComposer,
          $$DeckMovesTableCreateCompanionBuilder,
          $$DeckMovesTableUpdateCompanionBuilder,
          (DeckMove, $$DeckMovesTableReferences),
          DeckMove,
          PrefetchHooks Function({bool deckId, bool moveId})
        > {
  $$DeckMovesTableTableManager(_$AppDatabase db, $DeckMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeckMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeckMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeckMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> deckId = const Value.absent(),
                Value<String> moveId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeckMovesCompanion(
                deckId: deckId,
                moveId: moveId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String deckId,
                required String moveId,
                Value<int> rowid = const Value.absent(),
              }) => DeckMovesCompanion.insert(
                deckId: deckId,
                moveId: moveId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DeckMovesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({deckId = false, moveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (deckId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.deckId,
                                referencedTable: $$DeckMovesTableReferences
                                    ._deckIdTable(db),
                                referencedColumn: $$DeckMovesTableReferences
                                    ._deckIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable: $$DeckMovesTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$DeckMovesTableReferences
                                    ._moveIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DeckMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DeckMovesTable,
      DeckMove,
      $$DeckMovesTableFilterComposer,
      $$DeckMovesTableOrderingComposer,
      $$DeckMovesTableAnnotationComposer,
      $$DeckMovesTableCreateCompanionBuilder,
      $$DeckMovesTableUpdateCompanionBuilder,
      (DeckMove, $$DeckMovesTableReferences),
      DeckMove,
      PrefetchHooks Function({bool deckId, bool moveId})
    >;
typedef $$AssetManifestTableCreateCompanionBuilder =
    AssetManifestCompanion Function({
      required String contentHash,
      required int fileSizeBytes,
      Value<String> mimeType,
      Value<int?> durationMs,
      Value<int?> width,
      Value<int?> height,
      Value<String?> localPath,
      Value<DateTime?> localVerifiedAt,
      required String sourceType,
      Value<String?> sourceName,
      required DateTime importedAt,
      Value<DateTime?> deletedAt,
      Value<String?> tombstoneReason,
      Value<int> copyCount,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });
typedef $$AssetManifestTableUpdateCompanionBuilder =
    AssetManifestCompanion Function({
      Value<String> contentHash,
      Value<int> fileSizeBytes,
      Value<String> mimeType,
      Value<int?> durationMs,
      Value<int?> width,
      Value<int?> height,
      Value<String?> localPath,
      Value<DateTime?> localVerifiedAt,
      Value<String> sourceType,
      Value<String?> sourceName,
      Value<DateTime> importedAt,
      Value<DateTime?> deletedAt,
      Value<String?> tombstoneReason,
      Value<int> copyCount,
      Value<DateTime?> lastSyncAt,
      Value<int> rowid,
    });

final class $$AssetManifestTableReferences
    extends
        BaseReferences<_$AppDatabase, $AssetManifestTable, AssetManifestData> {
  $$AssetManifestTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<$AssetCopiesTable, List<AssetCopy>>
  _assetCopiesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.assetCopies,
    aliasName: $_aliasNameGenerator(
      db.assetManifest.contentHash,
      db.assetCopies.contentHash,
    ),
  );

  $$AssetCopiesTableProcessedTableManager get assetCopiesRefs {
    final manager = $$AssetCopiesTableTableManager($_db, $_db.assetCopies)
        .filter(
          (f) => f.contentHash.contentHash.sqlEquals(
            $_itemColumn<String>('content_hash')!,
          ),
        );

    final cache = $_typedResult.readTableOrNull(_assetCopiesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$AssetManifestTableFilterComposer
    extends Composer<_$AppDatabase, $AssetManifestTable> {
  $$AssetManifestTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get localVerifiedAt => $composableBuilder(
    column: $table.localVerifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tombstoneReason => $composableBuilder(
    column: $table.tombstoneReason,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get copyCount => $composableBuilder(
    column: $table.copyCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> assetCopiesRefs(
    Expression<bool> Function($$AssetCopiesTableFilterComposer f) f,
  ) {
    final $$AssetCopiesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentHash,
      referencedTable: $db.assetCopies,
      getReferencedColumn: (t) => t.contentHash,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCopiesTableFilterComposer(
            $db: $db,
            $table: $db.assetCopies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetManifestTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetManifestTable> {
  $$AssetManifestTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get mimeType => $composableBuilder(
    column: $table.mimeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get width => $composableBuilder(
    column: $table.width,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get height => $composableBuilder(
    column: $table.height,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localPath => $composableBuilder(
    column: $table.localPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get localVerifiedAt => $composableBuilder(
    column: $table.localVerifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tombstoneReason => $composableBuilder(
    column: $table.tombstoneReason,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get copyCount => $composableBuilder(
    column: $table.copyCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AssetManifestTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetManifestTable> {
  $$AssetManifestTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<int> get fileSizeBytes => $composableBuilder(
    column: $table.fileSizeBytes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get mimeType =>
      $composableBuilder(column: $table.mimeType, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
    column: $table.durationMs,
    builder: (column) => column,
  );

  GeneratedColumn<int> get width =>
      $composableBuilder(column: $table.width, builder: (column) => column);

  GeneratedColumn<int> get height =>
      $composableBuilder(column: $table.height, builder: (column) => column);

  GeneratedColumn<String> get localPath =>
      $composableBuilder(column: $table.localPath, builder: (column) => column);

  GeneratedColumn<DateTime> get localVerifiedAt => $composableBuilder(
    column: $table.localVerifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceType => $composableBuilder(
    column: $table.sourceType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sourceName => $composableBuilder(
    column: $table.sourceName,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get importedAt => $composableBuilder(
    column: $table.importedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  GeneratedColumn<String> get tombstoneReason => $composableBuilder(
    column: $table.tombstoneReason,
    builder: (column) => column,
  );

  GeneratedColumn<int> get copyCount =>
      $composableBuilder(column: $table.copyCount, builder: (column) => column);

  GeneratedColumn<DateTime> get lastSyncAt => $composableBuilder(
    column: $table.lastSyncAt,
    builder: (column) => column,
  );

  Expression<T> assetCopiesRefs<T extends Object>(
    Expression<T> Function($$AssetCopiesTableAnnotationComposer a) f,
  ) {
    final $$AssetCopiesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentHash,
      referencedTable: $db.assetCopies,
      getReferencedColumn: (t) => t.contentHash,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetCopiesTableAnnotationComposer(
            $db: $db,
            $table: $db.assetCopies,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$AssetManifestTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetManifestTable,
          AssetManifestData,
          $$AssetManifestTableFilterComposer,
          $$AssetManifestTableOrderingComposer,
          $$AssetManifestTableAnnotationComposer,
          $$AssetManifestTableCreateCompanionBuilder,
          $$AssetManifestTableUpdateCompanionBuilder,
          (AssetManifestData, $$AssetManifestTableReferences),
          AssetManifestData,
          PrefetchHooks Function({bool assetCopiesRefs})
        > {
  $$AssetManifestTableTableManager(_$AppDatabase db, $AssetManifestTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetManifestTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetManifestTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetManifestTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> contentHash = const Value.absent(),
                Value<int> fileSizeBytes = const Value.absent(),
                Value<String> mimeType = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime?> localVerifiedAt = const Value.absent(),
                Value<String> sourceType = const Value.absent(),
                Value<String?> sourceName = const Value.absent(),
                Value<DateTime> importedAt = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> tombstoneReason = const Value.absent(),
                Value<int> copyCount = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetManifestCompanion(
                contentHash: contentHash,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                durationMs: durationMs,
                width: width,
                height: height,
                localPath: localPath,
                localVerifiedAt: localVerifiedAt,
                sourceType: sourceType,
                sourceName: sourceName,
                importedAt: importedAt,
                deletedAt: deletedAt,
                tombstoneReason: tombstoneReason,
                copyCount: copyCount,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String contentHash,
                required int fileSizeBytes,
                Value<String> mimeType = const Value.absent(),
                Value<int?> durationMs = const Value.absent(),
                Value<int?> width = const Value.absent(),
                Value<int?> height = const Value.absent(),
                Value<String?> localPath = const Value.absent(),
                Value<DateTime?> localVerifiedAt = const Value.absent(),
                required String sourceType,
                Value<String?> sourceName = const Value.absent(),
                required DateTime importedAt,
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<String?> tombstoneReason = const Value.absent(),
                Value<int> copyCount = const Value.absent(),
                Value<DateTime?> lastSyncAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetManifestCompanion.insert(
                contentHash: contentHash,
                fileSizeBytes: fileSizeBytes,
                mimeType: mimeType,
                durationMs: durationMs,
                width: width,
                height: height,
                localPath: localPath,
                localVerifiedAt: localVerifiedAt,
                sourceType: sourceType,
                sourceName: sourceName,
                importedAt: importedAt,
                deletedAt: deletedAt,
                tombstoneReason: tombstoneReason,
                copyCount: copyCount,
                lastSyncAt: lastSyncAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetManifestTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({assetCopiesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (assetCopiesRefs) db.assetCopies],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (assetCopiesRefs)
                    await $_getPrefetchedData<
                      AssetManifestData,
                      $AssetManifestTable,
                      AssetCopy
                    >(
                      currentTable: table,
                      referencedTable: $$AssetManifestTableReferences
                          ._assetCopiesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$AssetManifestTableReferences(
                            db,
                            table,
                            p0,
                          ).assetCopiesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.contentHash == item.contentHash,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$AssetManifestTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetManifestTable,
      AssetManifestData,
      $$AssetManifestTableFilterComposer,
      $$AssetManifestTableOrderingComposer,
      $$AssetManifestTableAnnotationComposer,
      $$AssetManifestTableCreateCompanionBuilder,
      $$AssetManifestTableUpdateCompanionBuilder,
      (AssetManifestData, $$AssetManifestTableReferences),
      AssetManifestData,
      PrefetchHooks Function({bool assetCopiesRefs})
    >;
typedef $$AssetCopiesTableCreateCompanionBuilder =
    AssetCopiesCompanion Function({
      required String id,
      required String contentHash,
      required String provider,
      Value<String?> remotePath,
      Value<String?> remoteEtag,
      Value<DateTime?> verifiedAt,
      Value<String> status,
      Value<double?> uploadProgress,
      Value<String?> errorMessage,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AssetCopiesTableUpdateCompanionBuilder =
    AssetCopiesCompanion Function({
      Value<String> id,
      Value<String> contentHash,
      Value<String> provider,
      Value<String?> remotePath,
      Value<String?> remoteEtag,
      Value<DateTime?> verifiedAt,
      Value<String> status,
      Value<double?> uploadProgress,
      Value<String?> errorMessage,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$AssetCopiesTableReferences
    extends BaseReferences<_$AppDatabase, $AssetCopiesTable, AssetCopy> {
  $$AssetCopiesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $AssetManifestTable _contentHashTable(_$AppDatabase db) =>
      db.assetManifest.createAlias(
        $_aliasNameGenerator(
          db.assetCopies.contentHash,
          db.assetManifest.contentHash,
        ),
      );

  $$AssetManifestTableProcessedTableManager get contentHash {
    final $_column = $_itemColumn<String>('content_hash')!;

    final manager = $$AssetManifestTableTableManager(
      $_db,
      $_db.assetManifest,
    ).filter((f) => f.contentHash.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_contentHashTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AssetCopiesTableFilterComposer
    extends Composer<_$AppDatabase, $AssetCopiesTable> {
  $$AssetCopiesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$AssetManifestTableFilterComposer get contentHash {
    final $$AssetManifestTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentHash,
      referencedTable: $db.assetManifest,
      getReferencedColumn: (t) => t.contentHash,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetManifestTableFilterComposer(
            $db: $db,
            $table: $db.assetManifest,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCopiesTableOrderingComposer
    extends Composer<_$AppDatabase, $AssetCopiesTable> {
  $$AssetCopiesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get provider => $composableBuilder(
    column: $table.provider,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$AssetManifestTableOrderingComposer get contentHash {
    final $$AssetManifestTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentHash,
      referencedTable: $db.assetManifest,
      getReferencedColumn: (t) => t.contentHash,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetManifestTableOrderingComposer(
            $db: $db,
            $table: $db.assetManifest,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCopiesTableAnnotationComposer
    extends Composer<_$AppDatabase, $AssetCopiesTable> {
  $$AssetCopiesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get provider =>
      $composableBuilder(column: $table.provider, builder: (column) => column);

  GeneratedColumn<String> get remotePath => $composableBuilder(
    column: $table.remotePath,
    builder: (column) => column,
  );

  GeneratedColumn<String> get remoteEtag => $composableBuilder(
    column: $table.remoteEtag,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get verifiedAt => $composableBuilder(
    column: $table.verifiedAt,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<double> get uploadProgress => $composableBuilder(
    column: $table.uploadProgress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  $$AssetManifestTableAnnotationComposer get contentHash {
    final $$AssetManifestTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.contentHash,
      referencedTable: $db.assetManifest,
      getReferencedColumn: (t) => t.contentHash,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$AssetManifestTableAnnotationComposer(
            $db: $db,
            $table: $db.assetManifest,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AssetCopiesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AssetCopiesTable,
          AssetCopy,
          $$AssetCopiesTableFilterComposer,
          $$AssetCopiesTableOrderingComposer,
          $$AssetCopiesTableAnnotationComposer,
          $$AssetCopiesTableCreateCompanionBuilder,
          $$AssetCopiesTableUpdateCompanionBuilder,
          (AssetCopy, $$AssetCopiesTableReferences),
          AssetCopy,
          PrefetchHooks Function({bool contentHash})
        > {
  $$AssetCopiesTableTableManager(_$AppDatabase db, $AssetCopiesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AssetCopiesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AssetCopiesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AssetCopiesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> provider = const Value.absent(),
                Value<String?> remotePath = const Value.absent(),
                Value<String?> remoteEtag = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> uploadProgress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AssetCopiesCompanion(
                id: id,
                contentHash: contentHash,
                provider: provider,
                remotePath: remotePath,
                remoteEtag: remoteEtag,
                verifiedAt: verifiedAt,
                status: status,
                uploadProgress: uploadProgress,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contentHash,
                required String provider,
                Value<String?> remotePath = const Value.absent(),
                Value<String?> remoteEtag = const Value.absent(),
                Value<DateTime?> verifiedAt = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<double?> uploadProgress = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AssetCopiesCompanion.insert(
                id: id,
                contentHash: contentHash,
                provider: provider,
                remotePath: remotePath,
                remoteEtag: remoteEtag,
                verifiedAt: verifiedAt,
                status: status,
                uploadProgress: uploadProgress,
                errorMessage: errorMessage,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AssetCopiesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({contentHash = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (contentHash) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.contentHash,
                                referencedTable: $$AssetCopiesTableReferences
                                    ._contentHashTable(db),
                                referencedColumn: $$AssetCopiesTableReferences
                                    ._contentHashTable(db)
                                    .contentHash,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AssetCopiesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AssetCopiesTable,
      AssetCopy,
      $$AssetCopiesTableFilterComposer,
      $$AssetCopiesTableOrderingComposer,
      $$AssetCopiesTableAnnotationComposer,
      $$AssetCopiesTableCreateCompanionBuilder,
      $$AssetCopiesTableUpdateCompanionBuilder,
      (AssetCopy, $$AssetCopiesTableReferences),
      AssetCopy,
      PrefetchHooks Function({bool contentHash})
    >;
typedef $$SyncProvidersTableCreateCompanionBuilder =
    SyncProvidersCompanion Function({
      required String id,
      required String providerType,
      required String displayName,
      Value<bool> enabled,
      Value<String?> configJson,
      Value<int?> quotaBytes,
      Value<int?> usedBytes,
      Value<DateTime?> lastAuthAt,
      required DateTime createdAt,
      Value<int> rowid,
    });
typedef $$SyncProvidersTableUpdateCompanionBuilder =
    SyncProvidersCompanion Function({
      Value<String> id,
      Value<String> providerType,
      Value<String> displayName,
      Value<bool> enabled,
      Value<String?> configJson,
      Value<int?> quotaBytes,
      Value<int?> usedBytes,
      Value<DateTime?> lastAuthAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$SyncProvidersTableFilterComposer
    extends Composer<_$AppDatabase, $SyncProvidersTable> {
  $$SyncProvidersTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get usedBytes => $composableBuilder(
    column: $table.usedBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get lastAuthAt => $composableBuilder(
    column: $table.lastAuthAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncProvidersTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncProvidersTable> {
  $$SyncProvidersTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get enabled => $composableBuilder(
    column: $table.enabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get usedBytes => $composableBuilder(
    column: $table.usedBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get lastAuthAt => $composableBuilder(
    column: $table.lastAuthAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncProvidersTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncProvidersTable> {
  $$SyncProvidersTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get providerType => $composableBuilder(
    column: $table.providerType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get enabled =>
      $composableBuilder(column: $table.enabled, builder: (column) => column);

  GeneratedColumn<String> get configJson => $composableBuilder(
    column: $table.configJson,
    builder: (column) => column,
  );

  GeneratedColumn<int> get quotaBytes => $composableBuilder(
    column: $table.quotaBytes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get usedBytes =>
      $composableBuilder(column: $table.usedBytes, builder: (column) => column);

  GeneratedColumn<DateTime> get lastAuthAt => $composableBuilder(
    column: $table.lastAuthAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$SyncProvidersTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncProvidersTable,
          SyncProvider,
          $$SyncProvidersTableFilterComposer,
          $$SyncProvidersTableOrderingComposer,
          $$SyncProvidersTableAnnotationComposer,
          $$SyncProvidersTableCreateCompanionBuilder,
          $$SyncProvidersTableUpdateCompanionBuilder,
          (
            SyncProvider,
            BaseReferences<_$AppDatabase, $SyncProvidersTable, SyncProvider>,
          ),
          SyncProvider,
          PrefetchHooks Function()
        > {
  $$SyncProvidersTableTableManager(_$AppDatabase db, $SyncProvidersTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncProvidersTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncProvidersTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncProvidersTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> providerType = const Value.absent(),
                Value<String> displayName = const Value.absent(),
                Value<bool> enabled = const Value.absent(),
                Value<String?> configJson = const Value.absent(),
                Value<int?> quotaBytes = const Value.absent(),
                Value<int?> usedBytes = const Value.absent(),
                Value<DateTime?> lastAuthAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncProvidersCompanion(
                id: id,
                providerType: providerType,
                displayName: displayName,
                enabled: enabled,
                configJson: configJson,
                quotaBytes: quotaBytes,
                usedBytes: usedBytes,
                lastAuthAt: lastAuthAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String providerType,
                required String displayName,
                Value<bool> enabled = const Value.absent(),
                Value<String?> configJson = const Value.absent(),
                Value<int?> quotaBytes = const Value.absent(),
                Value<int?> usedBytes = const Value.absent(),
                Value<DateTime?> lastAuthAt = const Value.absent(),
                required DateTime createdAt,
                Value<int> rowid = const Value.absent(),
              }) => SyncProvidersCompanion.insert(
                id: id,
                providerType: providerType,
                displayName: displayName,
                enabled: enabled,
                configJson: configJson,
                quotaBytes: quotaBytes,
                usedBytes: usedBytes,
                lastAuthAt: lastAuthAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncProvidersTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncProvidersTable,
      SyncProvider,
      $$SyncProvidersTableFilterComposer,
      $$SyncProvidersTableOrderingComposer,
      $$SyncProvidersTableAnnotationComposer,
      $$SyncProvidersTableCreateCompanionBuilder,
      $$SyncProvidersTableUpdateCompanionBuilder,
      (
        SyncProvider,
        BaseReferences<_$AppDatabase, $SyncProvidersTable, SyncProvider>,
      ),
      SyncProvider,
      PrefetchHooks Function()
    >;
typedef $$SyncOperationsTableCreateCompanionBuilder =
    SyncOperationsCompanion Function({
      required String id,
      required String contentHash,
      required String providerId,
      required String operationType,
      Value<String> status,
      Value<int> priority,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<String?> errorMessage,
      Value<int> bytesTransferred,
      Value<int> totalBytes,
      required DateTime createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });
typedef $$SyncOperationsTableUpdateCompanionBuilder =
    SyncOperationsCompanion Function({
      Value<String> id,
      Value<String> contentHash,
      Value<String> providerId,
      Value<String> operationType,
      Value<String> status,
      Value<int> priority,
      Value<int> retryCount,
      Value<int> maxRetries,
      Value<String?> errorMessage,
      Value<int> bytesTransferred,
      Value<int> totalBytes,
      Value<DateTime> createdAt,
      Value<DateTime?> startedAt,
      Value<DateTime?> completedAt,
      Value<int> rowid,
    });

class $$SyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get priority => $composableBuilder(
    column: $table.priority,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get startedAt => $composableBuilder(
    column: $table.startedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SyncOperationsTable> {
  $$SyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get contentHash => $composableBuilder(
    column: $table.contentHash,
    builder: (column) => column,
  );

  GeneratedColumn<String> get providerId => $composableBuilder(
    column: $table.providerId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get operationType => $composableBuilder(
    column: $table.operationType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get priority =>
      $composableBuilder(column: $table.priority, builder: (column) => column);

  GeneratedColumn<int> get retryCount => $composableBuilder(
    column: $table.retryCount,
    builder: (column) => column,
  );

  GeneratedColumn<int> get maxRetries => $composableBuilder(
    column: $table.maxRetries,
    builder: (column) => column,
  );

  GeneratedColumn<String> get errorMessage => $composableBuilder(
    column: $table.errorMessage,
    builder: (column) => column,
  );

  GeneratedColumn<int> get bytesTransferred => $composableBuilder(
    column: $table.bytesTransferred,
    builder: (column) => column,
  );

  GeneratedColumn<int> get totalBytes => $composableBuilder(
    column: $table.totalBytes,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );
}

class $$SyncOperationsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SyncOperationsTable,
          SyncOperation,
          $$SyncOperationsTableFilterComposer,
          $$SyncOperationsTableOrderingComposer,
          $$SyncOperationsTableAnnotationComposer,
          $$SyncOperationsTableCreateCompanionBuilder,
          $$SyncOperationsTableUpdateCompanionBuilder,
          (
            SyncOperation,
            BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
          ),
          SyncOperation,
          PrefetchHooks Function()
        > {
  $$SyncOperationsTableTableManager(
    _$AppDatabase db,
    $SyncOperationsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SyncOperationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SyncOperationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SyncOperationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> contentHash = const Value.absent(),
                Value<String> providerId = const Value.absent(),
                Value<String> operationType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> bytesTransferred = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion(
                id: id,
                contentHash: contentHash,
                providerId: providerId,
                operationType: operationType,
                status: status,
                priority: priority,
                retryCount: retryCount,
                maxRetries: maxRetries,
                errorMessage: errorMessage,
                bytesTransferred: bytesTransferred,
                totalBytes: totalBytes,
                createdAt: createdAt,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String contentHash,
                required String providerId,
                required String operationType,
                Value<String> status = const Value.absent(),
                Value<int> priority = const Value.absent(),
                Value<int> retryCount = const Value.absent(),
                Value<int> maxRetries = const Value.absent(),
                Value<String?> errorMessage = const Value.absent(),
                Value<int> bytesTransferred = const Value.absent(),
                Value<int> totalBytes = const Value.absent(),
                required DateTime createdAt,
                Value<DateTime?> startedAt = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SyncOperationsCompanion.insert(
                id: id,
                contentHash: contentHash,
                providerId: providerId,
                operationType: operationType,
                status: status,
                priority: priority,
                retryCount: retryCount,
                maxRetries: maxRetries,
                errorMessage: errorMessage,
                bytesTransferred: bytesTransferred,
                totalBytes: totalBytes,
                createdAt: createdAt,
                startedAt: startedAt,
                completedAt: completedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SyncOperationsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SyncOperationsTable,
      SyncOperation,
      $$SyncOperationsTableFilterComposer,
      $$SyncOperationsTableOrderingComposer,
      $$SyncOperationsTableAnnotationComposer,
      $$SyncOperationsTableCreateCompanionBuilder,
      $$SyncOperationsTableUpdateCompanionBuilder,
      (
        SyncOperation,
        BaseReferences<_$AppDatabase, $SyncOperationsTable, SyncOperation>,
      ),
      SyncOperation,
      PrefetchHooks Function()
    >;
typedef $$LabsTableCreateCompanionBuilder =
    LabsCompanion Function({
      required String id,
      required String name,
      Value<String> labType,
      Value<String> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$LabsTableUpdateCompanionBuilder =
    LabsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String> labType,
      Value<String> status,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$LabsTableReferences
    extends BaseReferences<_$AppDatabase, $LabsTable, Lab> {
  $$LabsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$MilestonesTable, List<Milestone>>
  _milestonesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.milestones,
    aliasName: $_aliasNameGenerator(db.labs.id, db.milestones.labId),
  );

  $$MilestonesTableProcessedTableManager get milestonesRefs {
    final manager = $$MilestonesTableTableManager(
      $_db,
      $_db.milestones,
    ).filter((f) => f.labId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_milestonesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LabMovesTable, List<LabMove>> _labMovesRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.labMoves,
    aliasName: $_aliasNameGenerator(db.labs.id, db.labMoves.labId),
  );

  $$LabMovesTableProcessedTableManager get labMovesRefs {
    final manager = $$LabMovesTableTableManager(
      $_db,
      $_db.labMoves,
    ).filter((f) => f.labId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_labMovesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<$LabEntriesTable, List<LabEntry>>
  _labEntriesRefsTable(_$AppDatabase db) => MultiTypedResultKey.fromTable(
    db.labEntries,
    aliasName: $_aliasNameGenerator(db.labs.id, db.labEntries.labId),
  );

  $$LabEntriesTableProcessedTableManager get labEntriesRefs {
    final manager = $$LabEntriesTableTableManager(
      $_db,
      $_db.labEntries,
    ).filter((f) => f.labId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_labEntriesRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$LabsTableFilterComposer extends Composer<_$AppDatabase, $LabsTable> {
  $$LabsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get labType => $composableBuilder(
    column: $table.labType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> milestonesRefs(
    Expression<bool> Function($$MilestonesTableFilterComposer f) f,
  ) {
    final $$MilestonesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestonesTableFilterComposer(
            $db: $db,
            $table: $db.milestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> labMovesRefs(
    Expression<bool> Function($$LabMovesTableFilterComposer f) f,
  ) {
    final $$LabMovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labMoves,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabMovesTableFilterComposer(
            $db: $db,
            $table: $db.labMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> labEntriesRefs(
    Expression<bool> Function($$LabEntriesTableFilterComposer f) f,
  ) {
    final $$LabEntriesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labEntries,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabEntriesTableFilterComposer(
            $db: $db,
            $table: $db.labEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabsTableOrderingComposer extends Composer<_$AppDatabase, $LabsTable> {
  $$LabsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get labType => $composableBuilder(
    column: $table.labType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LabsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabsTable> {
  $$LabsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get labType =>
      $composableBuilder(column: $table.labType, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> milestonesRefs<T extends Object>(
    Expression<T> Function($$MilestonesTableAnnotationComposer a) f,
  ) {
    final $$MilestonesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.milestones,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MilestonesTableAnnotationComposer(
            $db: $db,
            $table: $db.milestones,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> labMovesRefs<T extends Object>(
    Expression<T> Function($$LabMovesTableAnnotationComposer a) f,
  ) {
    final $$LabMovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labMoves,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabMovesTableAnnotationComposer(
            $db: $db,
            $table: $db.labMoves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<T> labEntriesRefs<T extends Object>(
    Expression<T> Function($$LabEntriesTableAnnotationComposer a) f,
  ) {
    final $$LabEntriesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.labEntries,
      getReferencedColumn: (t) => t.labId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabEntriesTableAnnotationComposer(
            $db: $db,
            $table: $db.labEntries,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$LabsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabsTable,
          Lab,
          $$LabsTableFilterComposer,
          $$LabsTableOrderingComposer,
          $$LabsTableAnnotationComposer,
          $$LabsTableCreateCompanionBuilder,
          $$LabsTableUpdateCompanionBuilder,
          (Lab, $$LabsTableReferences),
          Lab,
          PrefetchHooks Function({
            bool milestonesRefs,
            bool labMovesRefs,
            bool labEntriesRefs,
          })
        > {
  $$LabsTableTableManager(_$AppDatabase db, $LabsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String> labType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabsCompanion(
                id: id,
                name: name,
                labType: labType,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String> labType = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabsCompanion.insert(
                id: id,
                name: name,
                labType: labType,
                status: status,
                notes: notes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$LabsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                milestonesRefs = false,
                labMovesRefs = false,
                labEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (milestonesRefs) db.milestones,
                    if (labMovesRefs) db.labMoves,
                    if (labEntriesRefs) db.labEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (milestonesRefs)
                        await $_getPrefetchedData<Lab, $LabsTable, Milestone>(
                          currentTable: table,
                          referencedTable: $$LabsTableReferences
                              ._milestonesRefsTable(db),
                          managerFromTypedResult: (p0) => $$LabsTableReferences(
                            db,
                            table,
                            p0,
                          ).milestonesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.labId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (labMovesRefs)
                        await $_getPrefetchedData<Lab, $LabsTable, LabMove>(
                          currentTable: table,
                          referencedTable: $$LabsTableReferences
                              ._labMovesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$LabsTableReferences(db, table, p0).labMovesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.labId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (labEntriesRefs)
                        await $_getPrefetchedData<Lab, $LabsTable, LabEntry>(
                          currentTable: table,
                          referencedTable: $$LabsTableReferences
                              ._labEntriesRefsTable(db),
                          managerFromTypedResult: (p0) => $$LabsTableReferences(
                            db,
                            table,
                            p0,
                          ).labEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.labId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$LabsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabsTable,
      Lab,
      $$LabsTableFilterComposer,
      $$LabsTableOrderingComposer,
      $$LabsTableAnnotationComposer,
      $$LabsTableCreateCompanionBuilder,
      $$LabsTableUpdateCompanionBuilder,
      (Lab, $$LabsTableReferences),
      Lab,
      PrefetchHooks Function({
        bool milestonesRefs,
        bool labMovesRefs,
        bool labEntriesRefs,
      })
    >;
typedef $$MilestonesTableCreateCompanionBuilder =
    MilestonesCompanion Function({
      required String id,
      required String labId,
      required String title,
      Value<String?> notes,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MilestonesTableUpdateCompanionBuilder =
    MilestonesCompanion Function({
      Value<String> id,
      Value<String> labId,
      Value<String> title,
      Value<String?> notes,
      Value<DateTime?> completedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MilestonesTableReferences
    extends BaseReferences<_$AppDatabase, $MilestonesTable, Milestone> {
  $$MilestonesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LabsTable _labIdTable(_$AppDatabase db) => db.labs.createAlias(
    $_aliasNameGenerator(db.milestones.labId, db.labs.id),
  );

  $$LabsTableProcessedTableManager get labId {
    final $_column = $_itemColumn<String>('lab_id')!;

    final manager = $$LabsTableTableManager(
      $_db,
      $_db.labs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MilestonesTableFilterComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LabsTableFilterComposer get labId {
    final $$LabsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableFilterComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestonesTableOrderingComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LabsTableOrderingComposer get labId {
    final $$LabsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableOrderingComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestonesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MilestonesTable> {
  $$MilestonesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LabsTableAnnotationComposer get labId {
    final $$LabsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableAnnotationComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MilestonesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MilestonesTable,
          Milestone,
          $$MilestonesTableFilterComposer,
          $$MilestonesTableOrderingComposer,
          $$MilestonesTableAnnotationComposer,
          $$MilestonesTableCreateCompanionBuilder,
          $$MilestonesTableUpdateCompanionBuilder,
          (Milestone, $$MilestonesTableReferences),
          Milestone,
          PrefetchHooks Function({bool labId})
        > {
  $$MilestonesTableTableManager(_$AppDatabase db, $MilestonesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MilestonesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MilestonesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MilestonesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> labId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion(
                id: id,
                labId: labId,
                title: title,
                notes: notes,
                completedAt: completedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String labId,
                required String title,
                Value<String?> notes = const Value.absent(),
                Value<DateTime?> completedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MilestonesCompanion.insert(
                id: id,
                labId: labId,
                title: title,
                notes: notes,
                completedAt: completedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MilestonesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({labId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (labId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labId,
                                referencedTable: $$MilestonesTableReferences
                                    ._labIdTable(db),
                                referencedColumn: $$MilestonesTableReferences
                                    ._labIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MilestonesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MilestonesTable,
      Milestone,
      $$MilestonesTableFilterComposer,
      $$MilestonesTableOrderingComposer,
      $$MilestonesTableAnnotationComposer,
      $$MilestonesTableCreateCompanionBuilder,
      $$MilestonesTableUpdateCompanionBuilder,
      (Milestone, $$MilestonesTableReferences),
      Milestone,
      PrefetchHooks Function({bool labId})
    >;
typedef $$LabMovesTableCreateCompanionBuilder =
    LabMovesCompanion Function({
      required String labId,
      required String moveId,
      required int sequenceIndex,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });
typedef $$LabMovesTableUpdateCompanionBuilder =
    LabMovesCompanion Function({
      Value<String> labId,
      Value<String> moveId,
      Value<int> sequenceIndex,
      Value<DateTime> addedAt,
      Value<int> rowid,
    });

final class $$LabMovesTableReferences
    extends BaseReferences<_$AppDatabase, $LabMovesTable, LabMove> {
  $$LabMovesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LabsTable _labIdTable(_$AppDatabase db) =>
      db.labs.createAlias($_aliasNameGenerator(db.labMoves.labId, db.labs.id));

  $$LabsTableProcessedTableManager get labId {
    final $_column = $_itemColumn<String>('lab_id')!;

    final manager = $$LabsTableTableManager(
      $_db,
      $_db.labs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.labMoves.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get moveId {
    final $_column = $_itemColumn<String>('move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LabMovesTableFilterComposer
    extends Composer<_$AppDatabase, $LabMovesTable> {
  $$LabMovesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LabsTableFilterComposer get labId {
    final $$LabsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableFilterComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabMovesTableOrderingComposer
    extends Composer<_$AppDatabase, $LabMovesTable> {
  $$LabMovesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get addedAt => $composableBuilder(
    column: $table.addedAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LabsTableOrderingComposer get labId {
    final $$LabsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableOrderingComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabMovesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabMovesTable> {
  $$LabMovesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get sequenceIndex => $composableBuilder(
    column: $table.sequenceIndex,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get addedAt =>
      $composableBuilder(column: $table.addedAt, builder: (column) => column);

  $$LabsTableAnnotationComposer get labId {
    final $$LabsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableAnnotationComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabMovesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabMovesTable,
          LabMove,
          $$LabMovesTableFilterComposer,
          $$LabMovesTableOrderingComposer,
          $$LabMovesTableAnnotationComposer,
          $$LabMovesTableCreateCompanionBuilder,
          $$LabMovesTableUpdateCompanionBuilder,
          (LabMove, $$LabMovesTableReferences),
          LabMove,
          PrefetchHooks Function({bool labId, bool moveId})
        > {
  $$LabMovesTableTableManager(_$AppDatabase db, $LabMovesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabMovesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabMovesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabMovesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> labId = const Value.absent(),
                Value<String> moveId = const Value.absent(),
                Value<int> sequenceIndex = const Value.absent(),
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabMovesCompanion(
                labId: labId,
                moveId: moveId,
                sequenceIndex: sequenceIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String labId,
                required String moveId,
                required int sequenceIndex,
                Value<DateTime> addedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabMovesCompanion.insert(
                labId: labId,
                moveId: moveId,
                sequenceIndex: sequenceIndex,
                addedAt: addedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LabMovesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({labId = false, moveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (labId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labId,
                                referencedTable: $$LabMovesTableReferences
                                    ._labIdTable(db),
                                referencedColumn: $$LabMovesTableReferences
                                    ._labIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable: $$LabMovesTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$LabMovesTableReferences
                                    ._moveIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LabMovesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabMovesTable,
      LabMove,
      $$LabMovesTableFilterComposer,
      $$LabMovesTableOrderingComposer,
      $$LabMovesTableAnnotationComposer,
      $$LabMovesTableCreateCompanionBuilder,
      $$LabMovesTableUpdateCompanionBuilder,
      (LabMove, $$LabMovesTableReferences),
      LabMove,
      PrefetchHooks Function({bool labId, bool moveId})
    >;
typedef $$LabEntriesTableCreateCompanionBuilder =
    LabEntriesCompanion Function({
      required String id,
      Value<String?> labId,
      required String content,
      Value<String?> videoPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$LabEntriesTableUpdateCompanionBuilder =
    LabEntriesCompanion Function({
      Value<String> id,
      Value<String?> labId,
      Value<String> content,
      Value<String?> videoPath,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$LabEntriesTableReferences
    extends BaseReferences<_$AppDatabase, $LabEntriesTable, LabEntry> {
  $$LabEntriesTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $LabsTable _labIdTable(_$AppDatabase db) => db.labs.createAlias(
    $_aliasNameGenerator(db.labEntries.labId, db.labs.id),
  );

  $$LabsTableProcessedTableManager? get labId {
    final $_column = $_itemColumn<String>('lab_id');
    if ($_column == null) return null;
    final manager = $$LabsTableTableManager(
      $_db,
      $_db.labs,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_labIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$LabEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $LabEntriesTable> {
  $$LabEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$LabsTableFilterComposer get labId {
    final $$LabsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableFilterComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $LabEntriesTable> {
  $$LabEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get content => $composableBuilder(
    column: $table.content,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get videoPath => $composableBuilder(
    column: $table.videoPath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$LabsTableOrderingComposer get labId {
    final $$LabsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableOrderingComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $LabEntriesTable> {
  $$LabEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get content =>
      $composableBuilder(column: $table.content, builder: (column) => column);

  GeneratedColumn<String> get videoPath =>
      $composableBuilder(column: $table.videoPath, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$LabsTableAnnotationComposer get labId {
    final $$LabsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.labId,
      referencedTable: $db.labs,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$LabsTableAnnotationComposer(
            $db: $db,
            $table: $db.labs,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$LabEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LabEntriesTable,
          LabEntry,
          $$LabEntriesTableFilterComposer,
          $$LabEntriesTableOrderingComposer,
          $$LabEntriesTableAnnotationComposer,
          $$LabEntriesTableCreateCompanionBuilder,
          $$LabEntriesTableUpdateCompanionBuilder,
          (LabEntry, $$LabEntriesTableReferences),
          LabEntry,
          PrefetchHooks Function({bool labId})
        > {
  $$LabEntriesTableTableManager(_$AppDatabase db, $LabEntriesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LabEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LabEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LabEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> labId = const Value.absent(),
                Value<String> content = const Value.absent(),
                Value<String?> videoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabEntriesCompanion(
                id: id,
                labId: labId,
                content: content,
                videoPath: videoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> labId = const Value.absent(),
                required String content,
                Value<String?> videoPath = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LabEntriesCompanion.insert(
                id: id,
                labId: labId,
                content: content,
                videoPath: videoPath,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$LabEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({labId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (labId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.labId,
                                referencedTable: $$LabEntriesTableReferences
                                    ._labIdTable(db),
                                referencedColumn: $$LabEntriesTableReferences
                                    ._labIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$LabEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LabEntriesTable,
      LabEntry,
      $$LabEntriesTableFilterComposer,
      $$LabEntriesTableOrderingComposer,
      $$LabEntriesTableAnnotationComposer,
      $$LabEntriesTableCreateCompanionBuilder,
      $$LabEntriesTableUpdateCompanionBuilder,
      (LabEntry, $$LabEntriesTableReferences),
      LabEntry,
      PrefetchHooks Function({bool labId})
    >;
typedef $$AchievementsTableCreateCompanionBuilder =
    AchievementsCompanion Function({
      required String id,
      required String moveId,
      required String tier,
      required DateTime unlockedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AchievementsTableUpdateCompanionBuilder =
    AchievementsCompanion Function({
      Value<String> id,
      Value<String> moveId,
      Value<String> tier,
      Value<DateTime> unlockedAt,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AchievementsTableReferences
    extends BaseReferences<_$AppDatabase, $AchievementsTable, Achievement> {
  $$AchievementsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.achievements.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get moveId {
    final $_column = $_itemColumn<String>('move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AchievementsTableFilterComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AchievementsTableOrderingComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get tier => $composableBuilder(
    column: $table.tier,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AchievementsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AchievementsTable> {
  $$AchievementsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get tier =>
      $composableBuilder(column: $table.tier, builder: (column) => column);

  GeneratedColumn<DateTime> get unlockedAt => $composableBuilder(
    column: $table.unlockedAt,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AchievementsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AchievementsTable,
          Achievement,
          $$AchievementsTableFilterComposer,
          $$AchievementsTableOrderingComposer,
          $$AchievementsTableAnnotationComposer,
          $$AchievementsTableCreateCompanionBuilder,
          $$AchievementsTableUpdateCompanionBuilder,
          (Achievement, $$AchievementsTableReferences),
          Achievement,
          PrefetchHooks Function({bool moveId})
        > {
  $$AchievementsTableTableManager(_$AppDatabase db, $AchievementsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AchievementsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AchievementsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AchievementsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> moveId = const Value.absent(),
                Value<String> tier = const Value.absent(),
                Value<DateTime> unlockedAt = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion(
                id: id,
                moveId: moveId,
                tier: tier,
                unlockedAt: unlockedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String moveId,
                required String tier,
                required DateTime unlockedAt,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AchievementsCompanion.insert(
                id: id,
                moveId: moveId,
                tier: tier,
                unlockedAt: unlockedAt,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AchievementsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({moveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable: $$AchievementsTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$AchievementsTableReferences
                                    ._moveIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AchievementsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AchievementsTable,
      Achievement,
      $$AchievementsTableFilterComposer,
      $$AchievementsTableOrderingComposer,
      $$AchievementsTableAnnotationComposer,
      $$AchievementsTableCreateCompanionBuilder,
      $$AchievementsTableUpdateCompanionBuilder,
      (Achievement, $$AchievementsTableReferences),
      Achievement,
      PrefetchHooks Function({bool moveId})
    >;
typedef $$AuraLinksTableCreateCompanionBuilder =
    AuraLinksCompanion Function({
      required String fromMoveId,
      required String toMoveId,
      required String affinity,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AuraLinksTableUpdateCompanionBuilder =
    AuraLinksCompanion Function({
      Value<String> fromMoveId,
      Value<String> toMoveId,
      Value<String> affinity,
      Value<String?> notes,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$AuraLinksTableReferences
    extends BaseReferences<_$AppDatabase, $AuraLinksTable, AuraLink> {
  $$AuraLinksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $MovesTable _fromMoveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.auraLinks.fromMoveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get fromMoveId {
    final $_column = $_itemColumn<String>('from_move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_fromMoveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static $MovesTable _toMoveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.auraLinks.toMoveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get toMoveId {
    final $_column = $_itemColumn<String>('to_move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_toMoveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$AuraLinksTableFilterComposer
    extends Composer<_$AppDatabase, $AuraLinksTable> {
  $$AuraLinksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get affinity => $composableBuilder(
    column: $table.affinity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MovesTableFilterComposer get fromMoveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableFilterComposer get toMoveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuraLinksTableOrderingComposer
    extends Composer<_$AppDatabase, $AuraLinksTable> {
  $$AuraLinksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get affinity => $composableBuilder(
    column: $table.affinity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MovesTableOrderingComposer get fromMoveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableOrderingComposer get toMoveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuraLinksTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuraLinksTable> {
  $$AuraLinksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get affinity =>
      $composableBuilder(column: $table.affinity, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MovesTableAnnotationComposer get fromMoveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.fromMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  $$MovesTableAnnotationComposer get toMoveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.toMoveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$AuraLinksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuraLinksTable,
          AuraLink,
          $$AuraLinksTableFilterComposer,
          $$AuraLinksTableOrderingComposer,
          $$AuraLinksTableAnnotationComposer,
          $$AuraLinksTableCreateCompanionBuilder,
          $$AuraLinksTableUpdateCompanionBuilder,
          (AuraLink, $$AuraLinksTableReferences),
          AuraLink,
          PrefetchHooks Function({bool fromMoveId, bool toMoveId})
        > {
  $$AuraLinksTableTableManager(_$AppDatabase db, $AuraLinksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuraLinksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuraLinksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuraLinksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> fromMoveId = const Value.absent(),
                Value<String> toMoveId = const Value.absent(),
                Value<String> affinity = const Value.absent(),
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuraLinksCompanion(
                fromMoveId: fromMoveId,
                toMoveId: toMoveId,
                affinity: affinity,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String fromMoveId,
                required String toMoveId,
                required String affinity,
                Value<String?> notes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuraLinksCompanion.insert(
                fromMoveId: fromMoveId,
                toMoveId: toMoveId,
                affinity: affinity,
                notes: notes,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$AuraLinksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({fromMoveId = false, toMoveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (fromMoveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.fromMoveId,
                                referencedTable: $$AuraLinksTableReferences
                                    ._fromMoveIdTable(db),
                                referencedColumn: $$AuraLinksTableReferences
                                    ._fromMoveIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (toMoveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.toMoveId,
                                referencedTable: $$AuraLinksTableReferences
                                    ._toMoveIdTable(db),
                                referencedColumn: $$AuraLinksTableReferences
                                    ._toMoveIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$AuraLinksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuraLinksTable,
      AuraLink,
      $$AuraLinksTableFilterComposer,
      $$AuraLinksTableOrderingComposer,
      $$AuraLinksTableAnnotationComposer,
      $$AuraLinksTableCreateCompanionBuilder,
      $$AuraLinksTableUpdateCompanionBuilder,
      (AuraLink, $$AuraLinksTableReferences),
      AuraLink,
      PrefetchHooks Function({bool fromMoveId, bool toMoveId})
    >;
typedef $$AuraPresetsTableCreateCompanionBuilder =
    AuraPresetsCompanion Function({
      required String id,
      required String name,
      Value<int> isDefault,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$AuraPresetsTableUpdateCompanionBuilder =
    AuraPresetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<int> isDefault,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

class $$AuraPresetsTableFilterComposer
    extends Composer<_$AppDatabase, $AuraPresetsTable> {
  $$AuraPresetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AuraPresetsTableOrderingComposer
    extends Composer<_$AppDatabase, $AuraPresetsTable> {
  $$AuraPresetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get isDefault => $composableBuilder(
    column: $table.isDefault,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AuraPresetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AuraPresetsTable> {
  $$AuraPresetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<int> get isDefault =>
      $composableBuilder(column: $table.isDefault, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$AuraPresetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AuraPresetsTable,
          AuraPreset,
          $$AuraPresetsTableFilterComposer,
          $$AuraPresetsTableOrderingComposer,
          $$AuraPresetsTableAnnotationComposer,
          $$AuraPresetsTableCreateCompanionBuilder,
          $$AuraPresetsTableUpdateCompanionBuilder,
          (
            AuraPreset,
            BaseReferences<_$AppDatabase, $AuraPresetsTable, AuraPreset>,
          ),
          AuraPreset,
          PrefetchHooks Function()
        > {
  $$AuraPresetsTableTableManager(_$AppDatabase db, $AuraPresetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AuraPresetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AuraPresetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AuraPresetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<int> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuraPresetsCompanion(
                id: id,
                name: name,
                isDefault: isDefault,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<int> isDefault = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AuraPresetsCompanion.insert(
                id: id,
                name: name,
                isDefault: isDefault,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AuraPresetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AuraPresetsTable,
      AuraPreset,
      $$AuraPresetsTableFilterComposer,
      $$AuraPresetsTableOrderingComposer,
      $$AuraPresetsTableAnnotationComposer,
      $$AuraPresetsTableCreateCompanionBuilder,
      $$AuraPresetsTableUpdateCompanionBuilder,
      (
        AuraPreset,
        BaseReferences<_$AppDatabase, $AuraPresetsTable, AuraPreset>,
      ),
      AuraPreset,
      PrefetchHooks Function()
    >;
typedef $$SetsTableCreateCompanionBuilder =
    SetsCompanion Function({
      required String id,
      required String name,
      Value<String?> description,
      Value<int> learningState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });
typedef $$SetsTableUpdateCompanionBuilder =
    SetsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> description,
      Value<int> learningState,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

final class $$SetsTableReferences
    extends BaseReferences<_$AppDatabase, $SetsTable, BreakdexSet> {
  $$SetsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$SetItemsTable, List<SetItem>> _setItemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.setItems,
    aliasName: $_aliasNameGenerator(db.sets.id, db.setItems.setId),
  );

  $$SetItemsTableProcessedTableManager get setItemsRefs {
    final manager = $$SetItemsTableTableManager(
      $_db,
      $_db.setItems,
    ).filter((f) => f.setId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_setItemsRefsTable($_db));
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$SetsTableFilterComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> setItemsRefs(
    Expression<bool> Function($$SetItemsTableFilterComposer f) f,
  ) {
    final $$SetItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setItems,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetItemsTableFilterComposer(
            $db: $db,
            $table: $db.setItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetsTableOrderingComposer extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SetsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetsTable> {
  $$SetsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<int> get learningState => $composableBuilder(
    column: $table.learningState,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  Expression<T> setItemsRefs<T extends Object>(
    Expression<T> Function($$SetItemsTableAnnotationComposer a) f,
  ) {
    final $$SetItemsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.setItems,
      getReferencedColumn: (t) => t.setId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetItemsTableAnnotationComposer(
            $db: $db,
            $table: $db.setItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$SetsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetsTable,
          BreakdexSet,
          $$SetsTableFilterComposer,
          $$SetsTableOrderingComposer,
          $$SetsTableAnnotationComposer,
          $$SetsTableCreateCompanionBuilder,
          $$SetsTableUpdateCompanionBuilder,
          (BreakdexSet, $$SetsTableReferences),
          BreakdexSet,
          PrefetchHooks Function({bool setItemsRefs})
        > {
  $$SetsTableTableManager(_$AppDatabase db, $SetsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> description = const Value.absent(),
                Value<int> learningState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion(
                id: id,
                name: name,
                description: description,
                learningState: learningState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> description = const Value.absent(),
                Value<int> learningState = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetsCompanion.insert(
                id: id,
                name: name,
                description: description,
                learningState: learningState,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$SetsTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({setItemsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (setItemsRefs) db.setItems],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (setItemsRefs)
                    await $_getPrefetchedData<BreakdexSet, $SetsTable, SetItem>(
                      currentTable: table,
                      referencedTable: $$SetsTableReferences._setItemsRefsTable(
                        db,
                      ),
                      managerFromTypedResult: (p0) =>
                          $$SetsTableReferences(db, table, p0).setItemsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.setId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$SetsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetsTable,
      BreakdexSet,
      $$SetsTableFilterComposer,
      $$SetsTableOrderingComposer,
      $$SetsTableAnnotationComposer,
      $$SetsTableCreateCompanionBuilder,
      $$SetsTableUpdateCompanionBuilder,
      (BreakdexSet, $$SetsTableReferences),
      BreakdexSet,
      PrefetchHooks Function({bool setItemsRefs})
    >;
typedef $$SetItemsTableCreateCompanionBuilder =
    SetItemsCompanion Function({
      required String id,
      required String setId,
      required String itemType,
      required String itemId,
      required int position,
      Value<int> rowid,
    });
typedef $$SetItemsTableUpdateCompanionBuilder =
    SetItemsCompanion Function({
      Value<String> id,
      Value<String> setId,
      Value<String> itemType,
      Value<String> itemId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$SetItemsTableReferences
    extends BaseReferences<_$AppDatabase, $SetItemsTable, SetItem> {
  $$SetItemsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static $SetsTable _setIdTable(_$AppDatabase db) =>
      db.sets.createAlias($_aliasNameGenerator(db.setItems.setId, db.sets.id));

  $$SetsTableProcessedTableManager get setId {
    final $_column = $_itemColumn<String>('set_id')!;

    final manager = $$SetsTableTableManager(
      $_db,
      $_db.sets,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_setIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$SetItemsTableFilterComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$SetsTableFilterComposer get setId {
    final $$SetsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.sets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetsTableFilterComposer(
            $db: $db,
            $table: $db.sets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemType => $composableBuilder(
    column: $table.itemType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get itemId => $composableBuilder(
    column: $table.itemId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$SetsTableOrderingComposer get setId {
    final $$SetsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.sets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetsTableOrderingComposer(
            $db: $db,
            $table: $db.sets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $SetItemsTable> {
  $$SetItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get itemType =>
      $composableBuilder(column: $table.itemType, builder: (column) => column);

  GeneratedColumn<String> get itemId =>
      $composableBuilder(column: $table.itemId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$SetsTableAnnotationComposer get setId {
    final $$SetsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.setId,
      referencedTable: $db.sets,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$SetsTableAnnotationComposer(
            $db: $db,
            $table: $db.sets,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$SetItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $SetItemsTable,
          SetItem,
          $$SetItemsTableFilterComposer,
          $$SetItemsTableOrderingComposer,
          $$SetItemsTableAnnotationComposer,
          $$SetItemsTableCreateCompanionBuilder,
          $$SetItemsTableUpdateCompanionBuilder,
          (SetItem, $$SetItemsTableReferences),
          SetItem,
          PrefetchHooks Function({bool setId})
        > {
  $$SetItemsTableTableManager(_$AppDatabase db, $SetItemsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SetItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SetItemsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SetItemsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> setId = const Value.absent(),
                Value<String> itemType = const Value.absent(),
                Value<String> itemId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SetItemsCompanion(
                id: id,
                setId: setId,
                itemType: itemType,
                itemId: itemId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String setId,
                required String itemType,
                required String itemId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => SetItemsCompanion.insert(
                id: id,
                setId: setId,
                itemType: itemType,
                itemId: itemId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$SetItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({setId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (setId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.setId,
                                referencedTable: $$SetItemsTableReferences
                                    ._setIdTable(db),
                                referencedColumn: $$SetItemsTableReferences
                                    ._setIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$SetItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $SetItemsTable,
      SetItem,
      $$SetItemsTableFilterComposer,
      $$SetItemsTableOrderingComposer,
      $$SetItemsTableAnnotationComposer,
      $$SetItemsTableCreateCompanionBuilder,
      $$SetItemsTableUpdateCompanionBuilder,
      (SetItem, $$SetItemsTableReferences),
      SetItem,
      PrefetchHooks Function({bool setId})
    >;
typedef $$ProvenanceEventsTableCreateCompanionBuilder =
    ProvenanceEventsCompanion Function({
      required String id,
      required String entityType,
      required String entityId,
      required String eventType,
      Value<DateTime> timestamp,
      Value<String?> metadata,
      Value<int> rowid,
    });
typedef $$ProvenanceEventsTableUpdateCompanionBuilder =
    ProvenanceEventsCompanion Function({
      Value<String> id,
      Value<String> entityType,
      Value<String> entityId,
      Value<String> eventType,
      Value<DateTime> timestamp,
      Value<String?> metadata,
      Value<int> rowid,
    });

class $$ProvenanceEventsTableFilterComposer
    extends Composer<_$AppDatabase, $ProvenanceEventsTable> {
  $$ProvenanceEventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ProvenanceEventsTableOrderingComposer
    extends Composer<_$AppDatabase, $ProvenanceEventsTable> {
  $$ProvenanceEventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get entityId => $composableBuilder(
    column: $table.entityId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get timestamp => $composableBuilder(
    column: $table.timestamp,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadata => $composableBuilder(
    column: $table.metadata,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ProvenanceEventsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ProvenanceEventsTable> {
  $$ProvenanceEventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get entityType => $composableBuilder(
    column: $table.entityType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get entityId =>
      $composableBuilder(column: $table.entityId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<DateTime> get timestamp =>
      $composableBuilder(column: $table.timestamp, builder: (column) => column);

  GeneratedColumn<String> get metadata =>
      $composableBuilder(column: $table.metadata, builder: (column) => column);
}

class $$ProvenanceEventsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ProvenanceEventsTable,
          ProvenanceEvent,
          $$ProvenanceEventsTableFilterComposer,
          $$ProvenanceEventsTableOrderingComposer,
          $$ProvenanceEventsTableAnnotationComposer,
          $$ProvenanceEventsTableCreateCompanionBuilder,
          $$ProvenanceEventsTableUpdateCompanionBuilder,
          (
            ProvenanceEvent,
            BaseReferences<
              _$AppDatabase,
              $ProvenanceEventsTable,
              ProvenanceEvent
            >,
          ),
          ProvenanceEvent,
          PrefetchHooks Function()
        > {
  $$ProvenanceEventsTableTableManager(
    _$AppDatabase db,
    $ProvenanceEventsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ProvenanceEventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ProvenanceEventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ProvenanceEventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> entityType = const Value.absent(),
                Value<String> entityId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProvenanceEventsCompanion(
                id: id,
                entityType: entityType,
                entityId: entityId,
                eventType: eventType,
                timestamp: timestamp,
                metadata: metadata,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String entityType,
                required String entityId,
                required String eventType,
                Value<DateTime> timestamp = const Value.absent(),
                Value<String?> metadata = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ProvenanceEventsCompanion.insert(
                id: id,
                entityType: entityType,
                entityId: entityId,
                eventType: eventType,
                timestamp: timestamp,
                metadata: metadata,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProvenanceEventsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ProvenanceEventsTable,
      ProvenanceEvent,
      $$ProvenanceEventsTableFilterComposer,
      $$ProvenanceEventsTableOrderingComposer,
      $$ProvenanceEventsTableAnnotationComposer,
      $$ProvenanceEventsTableCreateCompanionBuilder,
      $$ProvenanceEventsTableUpdateCompanionBuilder,
      (
        ProvenanceEvent,
        BaseReferences<_$AppDatabase, $ProvenanceEventsTable, ProvenanceEvent>,
      ),
      ProvenanceEvent,
      PrefetchHooks Function()
    >;
typedef $$MoveNoteEntriesTableCreateCompanionBuilder =
    MoveNoteEntriesCompanion Function({
      required String id,
      required String moveId,
      required String body,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });
typedef $$MoveNoteEntriesTableUpdateCompanionBuilder =
    MoveNoteEntriesCompanion Function({
      Value<String> id,
      Value<String> moveId,
      Value<String> body,
      Value<DateTime> createdAt,
      Value<int> rowid,
    });

final class $$MoveNoteEntriesTableReferences
    extends
        BaseReferences<_$AppDatabase, $MoveNoteEntriesTable, MoveNoteEntry> {
  $$MoveNoteEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $MovesTable _moveIdTable(_$AppDatabase db) => db.moves.createAlias(
    $_aliasNameGenerator(db.moveNoteEntries.moveId, db.moves.id),
  );

  $$MovesTableProcessedTableManager get moveId {
    final $_column = $_itemColumn<String>('move_id')!;

    final manager = $$MovesTableTableManager(
      $_db,
      $_db.moves,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_moveIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$MoveNoteEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $MoveNoteEntriesTable> {
  $$MoveNoteEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  $$MovesTableFilterComposer get moveId {
    final $$MovesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableFilterComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveNoteEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $MoveNoteEntriesTable> {
  $$MoveNoteEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  $$MovesTableOrderingComposer get moveId {
    final $$MovesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableOrderingComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveNoteEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $MoveNoteEntriesTable> {
  $$MoveNoteEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  $$MovesTableAnnotationComposer get moveId {
    final $$MovesTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.moveId,
      referencedTable: $db.moves,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$MovesTableAnnotationComposer(
            $db: $db,
            $table: $db.moves,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$MoveNoteEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $MoveNoteEntriesTable,
          MoveNoteEntry,
          $$MoveNoteEntriesTableFilterComposer,
          $$MoveNoteEntriesTableOrderingComposer,
          $$MoveNoteEntriesTableAnnotationComposer,
          $$MoveNoteEntriesTableCreateCompanionBuilder,
          $$MoveNoteEntriesTableUpdateCompanionBuilder,
          (MoveNoteEntry, $$MoveNoteEntriesTableReferences),
          MoveNoteEntry,
          PrefetchHooks Function({bool moveId})
        > {
  $$MoveNoteEntriesTableTableManager(
    _$AppDatabase db,
    $MoveNoteEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$MoveNoteEntriesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$MoveNoteEntriesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$MoveNoteEntriesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> moveId = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoveNoteEntriesCompanion(
                id: id,
                moveId: moveId,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String moveId,
                required String body,
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MoveNoteEntriesCompanion.insert(
                id: id,
                moveId: moveId,
                body: body,
                createdAt: createdAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$MoveNoteEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({moveId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (moveId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.moveId,
                                referencedTable:
                                    $$MoveNoteEntriesTableReferences
                                        ._moveIdTable(db),
                                referencedColumn:
                                    $$MoveNoteEntriesTableReferences
                                        ._moveIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$MoveNoteEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $MoveNoteEntriesTable,
      MoveNoteEntry,
      $$MoveNoteEntriesTableFilterComposer,
      $$MoveNoteEntriesTableOrderingComposer,
      $$MoveNoteEntriesTableAnnotationComposer,
      $$MoveNoteEntriesTableCreateCompanionBuilder,
      $$MoveNoteEntriesTableUpdateCompanionBuilder,
      (MoveNoteEntry, $$MoveNoteEntriesTableReferences),
      MoveNoteEntry,
      PrefetchHooks Function({bool moveId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$MovesTableTableManager get moves =>
      $$MovesTableTableManager(_db, _db.moves);
  $$CombosTableTableManager get combos =>
      $$CombosTableTableManager(_db, _db.combos);
  $$ComboMovesTableTableManager get comboMoves =>
      $$ComboMovesTableTableManager(_db, _db.comboMoves);
  $$ReviewsTableTableManager get reviews =>
      $$ReviewsTableTableManager(_db, _db.reviews);
  $$BattleResultsTableTableManager get battleResults =>
      $$BattleResultsTableTableManager(_db, _db.battleResults);
  $$SyncLogTableTableManager get syncLog =>
      $$SyncLogTableTableManager(_db, _db.syncLog);
  $$FsrsCardsTableTableManager get fsrsCards =>
      $$FsrsCardsTableTableManager(_db, _db.fsrsCards);
  $$DecksTableTableManager get decks =>
      $$DecksTableTableManager(_db, _db.decks);
  $$DeckMovesTableTableManager get deckMoves =>
      $$DeckMovesTableTableManager(_db, _db.deckMoves);
  $$AssetManifestTableTableManager get assetManifest =>
      $$AssetManifestTableTableManager(_db, _db.assetManifest);
  $$AssetCopiesTableTableManager get assetCopies =>
      $$AssetCopiesTableTableManager(_db, _db.assetCopies);
  $$SyncProvidersTableTableManager get syncProviders =>
      $$SyncProvidersTableTableManager(_db, _db.syncProviders);
  $$SyncOperationsTableTableManager get syncOperations =>
      $$SyncOperationsTableTableManager(_db, _db.syncOperations);
  $$LabsTableTableManager get labs => $$LabsTableTableManager(_db, _db.labs);
  $$MilestonesTableTableManager get milestones =>
      $$MilestonesTableTableManager(_db, _db.milestones);
  $$LabMovesTableTableManager get labMoves =>
      $$LabMovesTableTableManager(_db, _db.labMoves);
  $$LabEntriesTableTableManager get labEntries =>
      $$LabEntriesTableTableManager(_db, _db.labEntries);
  $$AchievementsTableTableManager get achievements =>
      $$AchievementsTableTableManager(_db, _db.achievements);
  $$AuraLinksTableTableManager get auraLinks =>
      $$AuraLinksTableTableManager(_db, _db.auraLinks);
  $$AuraPresetsTableTableManager get auraPresets =>
      $$AuraPresetsTableTableManager(_db, _db.auraPresets);
  $$SetsTableTableManager get sets => $$SetsTableTableManager(_db, _db.sets);
  $$SetItemsTableTableManager get setItems =>
      $$SetItemsTableTableManager(_db, _db.setItems);
  $$ProvenanceEventsTableTableManager get provenanceEvents =>
      $$ProvenanceEventsTableTableManager(_db, _db.provenanceEvents);
  $$MoveNoteEntriesTableTableManager get moveNoteEntries =>
      $$MoveNoteEntriesTableTableManager(_db, _db.moveNoteEntries);
}
