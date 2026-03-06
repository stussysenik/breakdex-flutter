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
  final DateTime createdAt;
  const Move({
    required this.id,
    required this.name,
    required this.learningState,
    required this.category,
    this.videoPath,
    this.originalVideoName,
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
          other.createdAt == this.createdAt);
}

class MovesCompanion extends UpdateCompanion<Move> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> learningState;
  final Value<String> category;
  final Value<String?> videoPath;
  final Value<String?> originalVideoName;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MovesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.learningState = const Value.absent(),
    this.category = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.originalVideoName = const Value.absent(),
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
  @override
  List<GeneratedColumn> get $columns => [id, name, activeVideoPath];
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
    if (data.containsKey('active_video_path')) {
      context.handle(
        _activeVideoPathMeta,
        activeVideoPath.isAcceptableOrUnknown(
          data['active_video_path']!,
          _activeVideoPathMeta,
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
      activeVideoPath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}active_video_path'],
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
  final String? activeVideoPath;
  const Combo({required this.id, required this.name, this.activeVideoPath});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || activeVideoPath != null) {
      map['active_video_path'] = Variable<String>(activeVideoPath);
    }
    return map;
  }

  CombosCompanion toCompanion(bool nullToAbsent) {
    return CombosCompanion(
      id: Value(id),
      name: Value(name),
      activeVideoPath: activeVideoPath == null && nullToAbsent
          ? const Value.absent()
          : Value(activeVideoPath),
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
      activeVideoPath: serializer.fromJson<String?>(json['activeVideoPath']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'activeVideoPath': serializer.toJson<String?>(activeVideoPath),
    };
  }

  Combo copyWith({
    String? id,
    String? name,
    Value<String?> activeVideoPath = const Value.absent(),
  }) => Combo(
    id: id ?? this.id,
    name: name ?? this.name,
    activeVideoPath: activeVideoPath.present
        ? activeVideoPath.value
        : this.activeVideoPath,
  );
  Combo copyWithCompanion(CombosCompanion data) {
    return Combo(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      activeVideoPath: data.activeVideoPath.present
          ? data.activeVideoPath.value
          : this.activeVideoPath,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Combo(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('activeVideoPath: $activeVideoPath')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, name, activeVideoPath);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Combo &&
          other.id == this.id &&
          other.name == this.name &&
          other.activeVideoPath == this.activeVideoPath);
}

class CombosCompanion extends UpdateCompanion<Combo> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> activeVideoPath;
  final Value<int> rowid;
  const CombosCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.activeVideoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CombosCompanion.insert({
    required String id,
    required String name,
    this.activeVideoPath = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name);
  static Insertable<Combo> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? activeVideoPath,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (activeVideoPath != null) 'active_video_path': activeVideoPath,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CombosCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? activeVideoPath,
    Value<int>? rowid,
  }) {
    return CombosCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      activeVideoPath: activeVideoPath ?? this.activeVideoPath,
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
    if (activeVideoPath.present) {
      map['active_video_path'] = Variable<String>(activeVideoPath.value);
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
          ..write('activeVideoPath: $activeVideoPath, ')
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
    Value<int?> fsrsPreState = const Value.absent(),
    Value<int?> fsrsPostState = const Value.absent(),
  }) => Review(
    id: id ?? this.id,
    rating: rating ?? this.rating,
    reviewType: reviewType ?? this.reviewType,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    moveId: moveId.present ? moveId.value : this.moveId,
    comboId: comboId.present ? comboId.value : this.comboId,
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
  late final MovesDao movesDao = MovesDao(this as AppDatabase);
  late final CombosDao combosDao = CombosDao(this as AppDatabase);
  late final ReviewsDao reviewsDao = ReviewsDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
  late final FsrsCardsDao fsrsCardsDao = FsrsCardsDao(this as AppDatabase);
  late final DecksDao decksDao = DecksDao(this as AppDatabase);
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
                originalVideoName: originalVideoName,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion.insert(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
                originalVideoName: originalVideoName,
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
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (comboMovesRefs) db.comboMoves,
                    if (reviewsRefs) db.reviews,
                    if (deckMovesRefs) db.deckMoves,
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
      })
    >;
typedef $$CombosTableCreateCompanionBuilder =
    CombosCompanion Function({
      required String id,
      required String name,
      Value<String?> activeVideoPath,
      Value<int> rowid,
    });
typedef $$CombosTableUpdateCompanionBuilder =
    CombosCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> activeVideoPath,
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

  ColumnFilters<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
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

  ColumnOrderings<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
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

  GeneratedColumn<String> get activeVideoPath => $composableBuilder(
    column: $table.activeVideoPath,
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
                Value<String?> activeVideoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CombosCompanion(
                id: id,
                name: name,
                activeVideoPath: activeVideoPath,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> activeVideoPath = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CombosCompanion.insert(
                id: id,
                name: name,
                activeVideoPath: activeVideoPath,
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
}
