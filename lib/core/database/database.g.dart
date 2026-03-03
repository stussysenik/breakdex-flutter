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
  final DateTime createdAt;
  const Move({
    required this.id,
    required this.name,
    required this.learningState,
    required this.category,
    this.videoPath,
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
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  Move copyWith({
    String? id,
    String? name,
    String? learningState,
    String? category,
    Value<String?> videoPath = const Value.absent(),
    DateTime? createdAt,
  }) => Move(
    id: id ?? this.id,
    name: name ?? this.name,
    learningState: learningState ?? this.learningState,
    category: category ?? this.category,
    videoPath: videoPath.present ? videoPath.value : this.videoPath,
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
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, learningState, category, videoPath, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Move &&
          other.id == this.id &&
          other.name == this.name &&
          other.learningState == this.learningState &&
          other.category == this.category &&
          other.videoPath == this.videoPath &&
          other.createdAt == this.createdAt);
}

class MovesCompanion extends UpdateCompanion<Move> {
  final Value<String> id;
  final Value<String> name;
  final Value<String> learningState;
  final Value<String> category;
  final Value<String?> videoPath;
  final Value<DateTime> createdAt;
  final Value<int> rowid;
  const MovesCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.learningState = const Value.absent(),
    this.category = const Value.absent(),
    this.videoPath = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  MovesCompanion.insert({
    required String id,
    required String name,
    this.learningState = const Value.absent(),
    this.category = const Value.absent(),
    this.videoPath = const Value.absent(),
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
    Expression<DateTime>? createdAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (learningState != null) 'learning_state': learningState,
      if (category != null) 'category': category,
      if (videoPath != null) 'video_path': videoPath,
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
    Value<DateTime>? createdAt,
    Value<int>? rowid,
  }) {
    return MovesCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      learningState: learningState ?? this.learningState,
      category: category ?? this.category,
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
  @override
  List<GeneratedColumn> get $columns => [
    id,
    rating,
    reviewType,
    reviewedAt,
    moveId,
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
  const Review({
    required this.id,
    required this.rating,
    required this.reviewType,
    required this.reviewedAt,
    this.moveId,
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
    };
  }

  Review copyWith({
    String? id,
    String? rating,
    String? reviewType,
    DateTime? reviewedAt,
    Value<String?> moveId = const Value.absent(),
  }) => Review(
    id: id ?? this.id,
    rating: rating ?? this.rating,
    reviewType: reviewType ?? this.reviewType,
    reviewedAt: reviewedAt ?? this.reviewedAt,
    moveId: moveId.present ? moveId.value : this.moveId,
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
    );
  }

  @override
  String toString() {
    return (StringBuffer('Review(')
          ..write('id: $id, ')
          ..write('rating: $rating, ')
          ..write('reviewType: $reviewType, ')
          ..write('reviewedAt: $reviewedAt, ')
          ..write('moveId: $moveId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, rating, reviewType, reviewedAt, moveId);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Review &&
          other.id == this.id &&
          other.rating == this.rating &&
          other.reviewType == this.reviewType &&
          other.reviewedAt == this.reviewedAt &&
          other.moveId == this.moveId);
}

class ReviewsCompanion extends UpdateCompanion<Review> {
  final Value<String> id;
  final Value<String> rating;
  final Value<String> reviewType;
  final Value<DateTime> reviewedAt;
  final Value<String?> moveId;
  final Value<int> rowid;
  const ReviewsCompanion({
    this.id = const Value.absent(),
    this.rating = const Value.absent(),
    this.reviewType = const Value.absent(),
    this.reviewedAt = const Value.absent(),
    this.moveId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReviewsCompanion.insert({
    required String id,
    required String rating,
    required String reviewType,
    this.reviewedAt = const Value.absent(),
    this.moveId = const Value.absent(),
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
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (rating != null) 'rating': rating,
      if (reviewType != null) 'review_type': reviewType,
      if (reviewedAt != null) 'reviewed_at': reviewedAt,
      if (moveId != null) 'move_id': moveId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReviewsCompanion copyWith({
    Value<String>? id,
    Value<String>? rating,
    Value<String>? reviewType,
    Value<DateTime>? reviewedAt,
    Value<String?>? moveId,
    Value<int>? rowid,
  }) {
    return ReviewsCompanion(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      reviewType: reviewType ?? this.reviewType,
      reviewedAt: reviewedAt ?? this.reviewedAt,
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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $MovesTable moves = $MovesTable(this);
  late final $CombosTable combos = $CombosTable(this);
  late final $ComboMovesTable comboMoves = $ComboMovesTable(this);
  late final $ReviewsTable reviews = $ReviewsTable(this);
  late final $BattleResultsTable battleResults = $BattleResultsTable(this);
  late final $SyncLogTable syncLog = $SyncLogTable(this);
  late final MovesDao movesDao = MovesDao(this as AppDatabase);
  late final CombosDao combosDao = CombosDao(this as AppDatabase);
  late final ReviewsDao reviewsDao = ReviewsDao(this as AppDatabase);
  late final SyncDao syncDao = SyncDao(this as AppDatabase);
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
  ]);
}

typedef $$MovesTableCreateCompanionBuilder =
    MovesCompanion Function({
      required String id,
      required String name,
      Value<String> learningState,
      Value<String> category,
      Value<String?> videoPath,
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
          PrefetchHooks Function({bool comboMovesRefs, bool reviewsRefs})
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
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
                Value<DateTime> createdAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => MovesCompanion.insert(
                id: id,
                name: name,
                learningState: learningState,
                category: category,
                videoPath: videoPath,
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
      PrefetchHooks Function({bool comboMovesRefs, bool reviewsRefs})
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
          PrefetchHooks Function({bool comboMovesRefs})
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
          prefetchHooksCallback: ({comboMovesRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [if (comboMovesRefs) db.comboMoves],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (comboMovesRefs)
                    await $_getPrefetchedData<Combo, $CombosTable, ComboMove>(
                      currentTable: table,
                      referencedTable: $$CombosTableReferences
                          ._comboMovesRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$CombosTableReferences(db, table, p0).comboMovesRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.comboId == item.id),
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
      PrefetchHooks Function({bool comboMovesRefs})
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
      Value<int> rowid,
    });
typedef $$ReviewsTableUpdateCompanionBuilder =
    ReviewsCompanion Function({
      Value<String> id,
      Value<String> rating,
      Value<String> reviewType,
      Value<DateTime> reviewedAt,
      Value<String?> moveId,
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
          PrefetchHooks Function({bool moveId})
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
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion(
                id: id,
                rating: rating,
                reviewType: reviewType,
                reviewedAt: reviewedAt,
                moveId: moveId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String rating,
                required String reviewType,
                Value<DateTime> reviewedAt = const Value.absent(),
                Value<String?> moveId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReviewsCompanion.insert(
                id: id,
                rating: rating,
                reviewType: reviewType,
                reviewedAt: reviewedAt,
                moveId: moveId,
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
                                referencedTable: $$ReviewsTableReferences
                                    ._moveIdTable(db),
                                referencedColumn: $$ReviewsTableReferences
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
      PrefetchHooks Function({bool moveId})
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
}
