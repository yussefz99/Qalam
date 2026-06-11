// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppSettingsTable extends AppSettings
    with TableInfo<$AppSettingsTable, AppSetting> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppSettingsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppSetting> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    } else if (isInserting) {
      context.missing(_valueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  AppSetting map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppSetting(
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      )!,
    );
  }

  @override
  $AppSettingsTable createAlias(String alias) {
    return $AppSettingsTable(attachedDatabase, alias);
  }
}

class AppSetting extends DataClass implements Insertable<AppSetting> {
  final String key;
  final String value;
  const AppSetting({required this.key, required this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['key'] = Variable<String>(key);
    map['value'] = Variable<String>(value);
    return map;
  }

  AppSettingsCompanion toCompanion(bool nullToAbsent) {
    return AppSettingsCompanion(key: Value(key), value: Value(value));
  }

  factory AppSetting.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppSetting(
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String>(value),
    };
  }

  AppSetting copyWith({String? key, String? value}) =>
      AppSetting(key: key ?? this.key, value: value ?? this.value);
  AppSetting copyWithCompanion(AppSettingsCompanion data) {
    return AppSetting(
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppSetting(')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppSetting &&
          other.key == this.key &&
          other.value == this.value);
}

class AppSettingsCompanion extends UpdateCompanion<AppSetting> {
  final Value<String> key;
  final Value<String> value;
  final Value<int> rowid;
  const AppSettingsCompanion({
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppSettingsCompanion.insert({
    required String key,
    required String value,
    this.rowid = const Value.absent(),
  }) : key = Value(key),
       value = Value(value);
  static Insertable<AppSetting> custom({
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppSettingsCompanion copyWith({
    Value<String>? key,
    Value<String>? value,
    Value<int>? rowid,
  }) {
    return AppSettingsCompanion(
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppSettingsCompanion(')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LetterMasteryTable extends LetterMastery
    with TableInfo<$LetterMasteryTable, LetterMasteryData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterMasteryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _letterIdMeta = const VerificationMeta(
    'letterId',
  );
  @override
  late final GeneratedColumn<String> letterId = GeneratedColumn<String>(
    'letter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanRepsMeta = const VerificationMeta(
    'cleanReps',
  );
  @override
  late final GeneratedColumn<int> cleanReps = GeneratedColumn<int>(
    'clean_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _masteredAtMeta = const VerificationMeta(
    'masteredAt',
  );
  @override
  late final GeneratedColumn<DateTime> masteredAt = GeneratedColumn<DateTime>(
    'mastered_at',
    aliasedName,
    false,
    type: DriftSqlType.dateTime,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [letterId, cleanReps, masteredAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_mastery';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterMasteryData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('letter_id')) {
      context.handle(
        _letterIdMeta,
        letterId.isAcceptableOrUnknown(data['letter_id']!, _letterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_letterIdMeta);
    }
    if (data.containsKey('clean_reps')) {
      context.handle(
        _cleanRepsMeta,
        cleanReps.isAcceptableOrUnknown(data['clean_reps']!, _cleanRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_cleanRepsMeta);
    }
    if (data.containsKey('mastered_at')) {
      context.handle(
        _masteredAtMeta,
        masteredAt.isAcceptableOrUnknown(data['mastered_at']!, _masteredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_masteredAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {letterId};
  @override
  LetterMasteryData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterMasteryData(
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      cleanReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clean_reps'],
      )!,
      masteredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}mastered_at'],
      )!,
    );
  }

  @override
  $LetterMasteryTable createAlias(String alias) {
    return $LetterMasteryTable(attachedDatabase, alias);
  }
}

class LetterMasteryData extends DataClass
    implements Insertable<LetterMasteryData> {
  final String letterId;
  final int cleanReps;
  final DateTime masteredAt;
  const LetterMasteryData({
    required this.letterId,
    required this.cleanReps,
    required this.masteredAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['letter_id'] = Variable<String>(letterId);
    map['clean_reps'] = Variable<int>(cleanReps);
    map['mastered_at'] = Variable<DateTime>(masteredAt);
    return map;
  }

  LetterMasteryCompanion toCompanion(bool nullToAbsent) {
    return LetterMasteryCompanion(
      letterId: Value(letterId),
      cleanReps: Value(cleanReps),
      masteredAt: Value(masteredAt),
    );
  }

  factory LetterMasteryData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterMasteryData(
      letterId: serializer.fromJson<String>(json['letterId']),
      cleanReps: serializer.fromJson<int>(json['cleanReps']),
      masteredAt: serializer.fromJson<DateTime>(json['masteredAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'letterId': serializer.toJson<String>(letterId),
      'cleanReps': serializer.toJson<int>(cleanReps),
      'masteredAt': serializer.toJson<DateTime>(masteredAt),
    };
  }

  LetterMasteryData copyWith({
    String? letterId,
    int? cleanReps,
    DateTime? masteredAt,
  }) => LetterMasteryData(
    letterId: letterId ?? this.letterId,
    cleanReps: cleanReps ?? this.cleanReps,
    masteredAt: masteredAt ?? this.masteredAt,
  );
  LetterMasteryData copyWithCompanion(LetterMasteryCompanion data) {
    return LetterMasteryData(
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      cleanReps: data.cleanReps.present ? data.cleanReps.value : this.cleanReps,
      masteredAt: data.masteredAt.present
          ? data.masteredAt.value
          : this.masteredAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterMasteryData(')
          ..write('letterId: $letterId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('masteredAt: $masteredAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(letterId, cleanReps, masteredAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterMasteryData &&
          other.letterId == this.letterId &&
          other.cleanReps == this.cleanReps &&
          other.masteredAt == this.masteredAt);
}

class LetterMasteryCompanion extends UpdateCompanion<LetterMasteryData> {
  final Value<String> letterId;
  final Value<int> cleanReps;
  final Value<DateTime> masteredAt;
  final Value<int> rowid;
  const LetterMasteryCompanion({
    this.letterId = const Value.absent(),
    this.cleanReps = const Value.absent(),
    this.masteredAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LetterMasteryCompanion.insert({
    required String letterId,
    required int cleanReps,
    required DateTime masteredAt,
    this.rowid = const Value.absent(),
  }) : letterId = Value(letterId),
       cleanReps = Value(cleanReps),
       masteredAt = Value(masteredAt);
  static Insertable<LetterMasteryData> custom({
    Expression<String>? letterId,
    Expression<int>? cleanReps,
    Expression<DateTime>? masteredAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (letterId != null) 'letter_id': letterId,
      if (cleanReps != null) 'clean_reps': cleanReps,
      if (masteredAt != null) 'mastered_at': masteredAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LetterMasteryCompanion copyWith({
    Value<String>? letterId,
    Value<int>? cleanReps,
    Value<DateTime>? masteredAt,
    Value<int>? rowid,
  }) {
    return LetterMasteryCompanion(
      letterId: letterId ?? this.letterId,
      cleanReps: cleanReps ?? this.cleanReps,
      masteredAt: masteredAt ?? this.masteredAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (letterId.present) {
      map['letter_id'] = Variable<String>(letterId.value);
    }
    if (cleanReps.present) {
      map['clean_reps'] = Variable<int>(cleanReps.value);
    }
    if (masteredAt.present) {
      map['mastered_at'] = Variable<DateTime>(masteredAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LetterMasteryCompanion(')
          ..write('letterId: $letterId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('masteredAt: $masteredAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildProfilesTable extends ChildProfiles
    with TableInfo<$ChildProfilesTable, ChildProfile> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildProfilesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    hasAutoIncrement: true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'PRIMARY KEY AUTOINCREMENT',
    ),
  );
  static const VerificationMeta _nicknameIdMeta = const VerificationMeta(
    'nicknameId',
  );
  @override
  late final GeneratedColumn<String> nicknameId = GeneratedColumn<String>(
    'nickname_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _avatarIdMeta = const VerificationMeta(
    'avatarId',
  );
  @override
  late final GeneratedColumn<String> avatarId = GeneratedColumn<String>(
    'avatar_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _gradeMeta = const VerificationMeta('grade');
  @override
  late final GeneratedColumn<String> grade = GeneratedColumn<String>(
    'grade',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startingLessonIdMeta = const VerificationMeta(
    'startingLessonId',
  );
  @override
  late final GeneratedColumn<String> startingLessonId = GeneratedColumn<String>(
    'starting_lesson_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    nicknameId,
    avatarId,
    grade,
    startingLessonId,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child_profiles';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildProfile> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('nickname_id')) {
      context.handle(
        _nicknameIdMeta,
        nicknameId.isAcceptableOrUnknown(data['nickname_id']!, _nicknameIdMeta),
      );
    } else if (isInserting) {
      context.missing(_nicknameIdMeta);
    }
    if (data.containsKey('avatar_id')) {
      context.handle(
        _avatarIdMeta,
        avatarId.isAcceptableOrUnknown(data['avatar_id']!, _avatarIdMeta),
      );
    } else if (isInserting) {
      context.missing(_avatarIdMeta);
    }
    if (data.containsKey('grade')) {
      context.handle(
        _gradeMeta,
        grade.isAcceptableOrUnknown(data['grade']!, _gradeMeta),
      );
    } else if (isInserting) {
      context.missing(_gradeMeta);
    }
    if (data.containsKey('starting_lesson_id')) {
      context.handle(
        _startingLessonIdMeta,
        startingLessonId.isAcceptableOrUnknown(
          data['starting_lesson_id']!,
          _startingLessonIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startingLessonIdMeta);
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
  ChildProfile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildProfile(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      nicknameId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}nickname_id'],
      )!,
      avatarId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}avatar_id'],
      )!,
      grade: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}grade'],
      )!,
      startingLessonId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}starting_lesson_id'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $ChildProfilesTable createAlias(String alias) {
    return $ChildProfilesTable(attachedDatabase, alias);
  }
}

class ChildProfile extends DataClass implements Insertable<ChildProfile> {
  final int id;
  final String nicknameId;
  final String avatarId;
  final String grade;
  final String startingLessonId;
  final int createdAt;
  const ChildProfile({
    required this.id,
    required this.nicknameId,
    required this.avatarId,
    required this.grade,
    required this.startingLessonId,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['nickname_id'] = Variable<String>(nicknameId);
    map['avatar_id'] = Variable<String>(avatarId);
    map['grade'] = Variable<String>(grade);
    map['starting_lesson_id'] = Variable<String>(startingLessonId);
    map['created_at'] = Variable<int>(createdAt);
    return map;
  }

  ChildProfilesCompanion toCompanion(bool nullToAbsent) {
    return ChildProfilesCompanion(
      id: Value(id),
      nicknameId: Value(nicknameId),
      avatarId: Value(avatarId),
      grade: Value(grade),
      startingLessonId: Value(startingLessonId),
      createdAt: Value(createdAt),
    );
  }

  factory ChildProfile.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildProfile(
      id: serializer.fromJson<int>(json['id']),
      nicknameId: serializer.fromJson<String>(json['nicknameId']),
      avatarId: serializer.fromJson<String>(json['avatarId']),
      grade: serializer.fromJson<String>(json['grade']),
      startingLessonId: serializer.fromJson<String>(json['startingLessonId']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'nicknameId': serializer.toJson<String>(nicknameId),
      'avatarId': serializer.toJson<String>(avatarId),
      'grade': serializer.toJson<String>(grade),
      'startingLessonId': serializer.toJson<String>(startingLessonId),
      'createdAt': serializer.toJson<int>(createdAt),
    };
  }

  ChildProfile copyWith({
    int? id,
    String? nicknameId,
    String? avatarId,
    String? grade,
    String? startingLessonId,
    int? createdAt,
  }) => ChildProfile(
    id: id ?? this.id,
    nicknameId: nicknameId ?? this.nicknameId,
    avatarId: avatarId ?? this.avatarId,
    grade: grade ?? this.grade,
    startingLessonId: startingLessonId ?? this.startingLessonId,
    createdAt: createdAt ?? this.createdAt,
  );
  ChildProfile copyWithCompanion(ChildProfilesCompanion data) {
    return ChildProfile(
      id: data.id.present ? data.id.value : this.id,
      nicknameId: data.nicknameId.present
          ? data.nicknameId.value
          : this.nicknameId,
      avatarId: data.avatarId.present ? data.avatarId.value : this.avatarId,
      grade: data.grade.present ? data.grade.value : this.grade,
      startingLessonId: data.startingLessonId.present
          ? data.startingLessonId.value
          : this.startingLessonId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildProfile(')
          ..write('id: $id, ')
          ..write('nicknameId: $nicknameId, ')
          ..write('avatarId: $avatarId, ')
          ..write('grade: $grade, ')
          ..write('startingLessonId: $startingLessonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, nicknameId, avatarId, grade, startingLessonId, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildProfile &&
          other.id == this.id &&
          other.nicknameId == this.nicknameId &&
          other.avatarId == this.avatarId &&
          other.grade == this.grade &&
          other.startingLessonId == this.startingLessonId &&
          other.createdAt == this.createdAt);
}

class ChildProfilesCompanion extends UpdateCompanion<ChildProfile> {
  final Value<int> id;
  final Value<String> nicknameId;
  final Value<String> avatarId;
  final Value<String> grade;
  final Value<String> startingLessonId;
  final Value<int> createdAt;
  const ChildProfilesCompanion({
    this.id = const Value.absent(),
    this.nicknameId = const Value.absent(),
    this.avatarId = const Value.absent(),
    this.grade = const Value.absent(),
    this.startingLessonId = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  ChildProfilesCompanion.insert({
    this.id = const Value.absent(),
    required String nicknameId,
    required String avatarId,
    required String grade,
    required String startingLessonId,
    required int createdAt,
  }) : nicknameId = Value(nicknameId),
       avatarId = Value(avatarId),
       grade = Value(grade),
       startingLessonId = Value(startingLessonId),
       createdAt = Value(createdAt);
  static Insertable<ChildProfile> custom({
    Expression<int>? id,
    Expression<String>? nicknameId,
    Expression<String>? avatarId,
    Expression<String>? grade,
    Expression<String>? startingLessonId,
    Expression<int>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (nicknameId != null) 'nickname_id': nicknameId,
      if (avatarId != null) 'avatar_id': avatarId,
      if (grade != null) 'grade': grade,
      if (startingLessonId != null) 'starting_lesson_id': startingLessonId,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  ChildProfilesCompanion copyWith({
    Value<int>? id,
    Value<String>? nicknameId,
    Value<String>? avatarId,
    Value<String>? grade,
    Value<String>? startingLessonId,
    Value<int>? createdAt,
  }) {
    return ChildProfilesCompanion(
      id: id ?? this.id,
      nicknameId: nicknameId ?? this.nicknameId,
      avatarId: avatarId ?? this.avatarId,
      grade: grade ?? this.grade,
      startingLessonId: startingLessonId ?? this.startingLessonId,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (nicknameId.present) {
      map['nickname_id'] = Variable<String>(nicknameId.value);
    }
    if (avatarId.present) {
      map['avatar_id'] = Variable<String>(avatarId.value);
    }
    if (grade.present) {
      map['grade'] = Variable<String>(grade.value);
    }
    if (startingLessonId.present) {
      map['starting_lesson_id'] = Variable<String>(startingLessonId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ChildProfilesCompanion(')
          ..write('id: $id, ')
          ..write('nicknameId: $nicknameId, ')
          ..write('avatarId: $avatarId, ')
          ..write('grade: $grade, ')
          ..write('startingLessonId: $startingLessonId, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $LetterRepsTable extends LetterReps
    with TableInfo<$LetterRepsTable, LetterRep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterRepsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _letterIdMeta = const VerificationMeta(
    'letterId',
  );
  @override
  late final GeneratedColumn<String> letterId = GeneratedColumn<String>(
    'letter_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _cleanRepsMeta = const VerificationMeta(
    'cleanReps',
  );
  @override
  late final GeneratedColumn<int> cleanReps = GeneratedColumn<int>(
    'clean_reps',
    aliasedName,
    false,
    type: DriftSqlType.int,
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
  List<GeneratedColumn> get $columns => [letterId, cleanReps, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_reps';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterRep> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('letter_id')) {
      context.handle(
        _letterIdMeta,
        letterId.isAcceptableOrUnknown(data['letter_id']!, _letterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_letterIdMeta);
    }
    if (data.containsKey('clean_reps')) {
      context.handle(
        _cleanRepsMeta,
        cleanReps.isAcceptableOrUnknown(data['clean_reps']!, _cleanRepsMeta),
      );
    } else if (isInserting) {
      context.missing(_cleanRepsMeta);
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
  Set<GeneratedColumn> get $primaryKey => {letterId};
  @override
  LetterRep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterRep(
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      cleanReps: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}clean_reps'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LetterRepsTable createAlias(String alias) {
    return $LetterRepsTable(attachedDatabase, alias);
  }
}

class LetterRep extends DataClass implements Insertable<LetterRep> {
  final String letterId;
  final int cleanReps;
  final DateTime updatedAt;
  const LetterRep({
    required this.letterId,
    required this.cleanReps,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['letter_id'] = Variable<String>(letterId);
    map['clean_reps'] = Variable<int>(cleanReps);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LetterRepsCompanion toCompanion(bool nullToAbsent) {
    return LetterRepsCompanion(
      letterId: Value(letterId),
      cleanReps: Value(cleanReps),
      updatedAt: Value(updatedAt),
    );
  }

  factory LetterRep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterRep(
      letterId: serializer.fromJson<String>(json['letterId']),
      cleanReps: serializer.fromJson<int>(json['cleanReps']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'letterId': serializer.toJson<String>(letterId),
      'cleanReps': serializer.toJson<int>(cleanReps),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LetterRep copyWith({String? letterId, int? cleanReps, DateTime? updatedAt}) =>
      LetterRep(
        letterId: letterId ?? this.letterId,
        cleanReps: cleanReps ?? this.cleanReps,
        updatedAt: updatedAt ?? this.updatedAt,
      );
  LetterRep copyWithCompanion(LetterRepsCompanion data) {
    return LetterRep(
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      cleanReps: data.cleanReps.present ? data.cleanReps.value : this.cleanReps,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterRep(')
          ..write('letterId: $letterId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(letterId, cleanReps, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterRep &&
          other.letterId == this.letterId &&
          other.cleanReps == this.cleanReps &&
          other.updatedAt == this.updatedAt);
}

class LetterRepsCompanion extends UpdateCompanion<LetterRep> {
  final Value<String> letterId;
  final Value<int> cleanReps;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LetterRepsCompanion({
    this.letterId = const Value.absent(),
    this.cleanReps = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LetterRepsCompanion.insert({
    required String letterId,
    required int cleanReps,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : letterId = Value(letterId),
       cleanReps = Value(cleanReps),
       updatedAt = Value(updatedAt);
  static Insertable<LetterRep> custom({
    Expression<String>? letterId,
    Expression<int>? cleanReps,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (letterId != null) 'letter_id': letterId,
      if (cleanReps != null) 'clean_reps': cleanReps,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LetterRepsCompanion copyWith({
    Value<String>? letterId,
    Value<int>? cleanReps,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LetterRepsCompanion(
      letterId: letterId ?? this.letterId,
      cleanReps: cleanReps ?? this.cleanReps,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (letterId.present) {
      map['letter_id'] = Variable<String>(letterId.value);
    }
    if (cleanReps.present) {
      map['clean_reps'] = Variable<int>(cleanReps.value);
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
    return (StringBuffer('LetterRepsCompanion(')
          ..write('letterId: $letterId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $LetterMasteryTable letterMastery = $LetterMasteryTable(this);
  late final $ChildProfilesTable childProfiles = $ChildProfilesTable(this);
  late final $LetterRepsTable letterReps = $LetterRepsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    letterMastery,
    childProfiles,
    letterReps,
  ];
}

typedef $$AppSettingsTableCreateCompanionBuilder =
    AppSettingsCompanion Function({
      required String key,
      required String value,
      Value<int> rowid,
    });
typedef $$AppSettingsTableUpdateCompanionBuilder =
    AppSettingsCompanion Function({
      Value<String> key,
      Value<String> value,
      Value<int> rowid,
    });

class $$AppSettingsTableFilterComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$AppSettingsTableOrderingComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppSettingsTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppSettingsTable> {
  $$AppSettingsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$AppSettingsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppSettingsTable,
          AppSetting,
          $$AppSettingsTableFilterComposer,
          $$AppSettingsTableOrderingComposer,
          $$AppSettingsTableAnnotationComposer,
          $$AppSettingsTableCreateCompanionBuilder,
          $$AppSettingsTableUpdateCompanionBuilder,
          (
            AppSetting,
            BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
          ),
          AppSetting,
          PrefetchHooks Function()
        > {
  $$AppSettingsTableTableManager(_$AppDatabase db, $AppSettingsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppSettingsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppSettingsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppSettingsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> key = const Value.absent(),
                Value<String> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion(key: key, value: value, rowid: rowid),
          createCompanionCallback:
              ({
                required String key,
                required String value,
                Value<int> rowid = const Value.absent(),
              }) => AppSettingsCompanion.insert(
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppSettingsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppSettingsTable,
      AppSetting,
      $$AppSettingsTableFilterComposer,
      $$AppSettingsTableOrderingComposer,
      $$AppSettingsTableAnnotationComposer,
      $$AppSettingsTableCreateCompanionBuilder,
      $$AppSettingsTableUpdateCompanionBuilder,
      (
        AppSetting,
        BaseReferences<_$AppDatabase, $AppSettingsTable, AppSetting>,
      ),
      AppSetting,
      PrefetchHooks Function()
    >;
typedef $$LetterMasteryTableCreateCompanionBuilder =
    LetterMasteryCompanion Function({
      required String letterId,
      required int cleanReps,
      required DateTime masteredAt,
      Value<int> rowid,
    });
typedef $$LetterMasteryTableUpdateCompanionBuilder =
    LetterMasteryCompanion Function({
      Value<String> letterId,
      Value<int> cleanReps,
      Value<DateTime> masteredAt,
      Value<int> rowid,
    });

class $$LetterMasteryTableFilterComposer
    extends Composer<_$AppDatabase, $LetterMasteryTable> {
  $$LetterMasteryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cleanReps => $composableBuilder(
    column: $table.cleanReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterMasteryTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterMasteryTable> {
  $$LetterMasteryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cleanReps => $composableBuilder(
    column: $table.cleanReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterMasteryTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterMasteryTable> {
  $$LetterMasteryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<int> get cleanReps =>
      $composableBuilder(column: $table.cleanReps, builder: (column) => column);

  GeneratedColumn<DateTime> get masteredAt => $composableBuilder(
    column: $table.masteredAt,
    builder: (column) => column,
  );
}

class $$LetterMasteryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterMasteryTable,
          LetterMasteryData,
          $$LetterMasteryTableFilterComposer,
          $$LetterMasteryTableOrderingComposer,
          $$LetterMasteryTableAnnotationComposer,
          $$LetterMasteryTableCreateCompanionBuilder,
          $$LetterMasteryTableUpdateCompanionBuilder,
          (
            LetterMasteryData,
            BaseReferences<
              _$AppDatabase,
              $LetterMasteryTable,
              LetterMasteryData
            >,
          ),
          LetterMasteryData,
          PrefetchHooks Function()
        > {
  $$LetterMasteryTableTableManager(_$AppDatabase db, $LetterMasteryTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterMasteryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterMasteryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LetterMasteryTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> letterId = const Value.absent(),
                Value<int> cleanReps = const Value.absent(),
                Value<DateTime> masteredAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterMasteryCompanion(
                letterId: letterId,
                cleanReps: cleanReps,
                masteredAt: masteredAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String letterId,
                required int cleanReps,
                required DateTime masteredAt,
                Value<int> rowid = const Value.absent(),
              }) => LetterMasteryCompanion.insert(
                letterId: letterId,
                cleanReps: cleanReps,
                masteredAt: masteredAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LetterMasteryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterMasteryTable,
      LetterMasteryData,
      $$LetterMasteryTableFilterComposer,
      $$LetterMasteryTableOrderingComposer,
      $$LetterMasteryTableAnnotationComposer,
      $$LetterMasteryTableCreateCompanionBuilder,
      $$LetterMasteryTableUpdateCompanionBuilder,
      (
        LetterMasteryData,
        BaseReferences<_$AppDatabase, $LetterMasteryTable, LetterMasteryData>,
      ),
      LetterMasteryData,
      PrefetchHooks Function()
    >;
typedef $$ChildProfilesTableCreateCompanionBuilder =
    ChildProfilesCompanion Function({
      Value<int> id,
      required String nicknameId,
      required String avatarId,
      required String grade,
      required String startingLessonId,
      required int createdAt,
    });
typedef $$ChildProfilesTableUpdateCompanionBuilder =
    ChildProfilesCompanion Function({
      Value<int> id,
      Value<String> nicknameId,
      Value<String> avatarId,
      Value<String> grade,
      Value<String> startingLessonId,
      Value<int> createdAt,
    });

class $$ChildProfilesTableFilterComposer
    extends Composer<_$AppDatabase, $ChildProfilesTable> {
  $$ChildProfilesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nicknameId => $composableBuilder(
    column: $table.nicknameId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startingLessonId => $composableBuilder(
    column: $table.startingLessonId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChildProfilesTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildProfilesTable> {
  $$ChildProfilesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nicknameId => $composableBuilder(
    column: $table.nicknameId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get avatarId => $composableBuilder(
    column: $table.avatarId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get grade => $composableBuilder(
    column: $table.grade,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startingLessonId => $composableBuilder(
    column: $table.startingLessonId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildProfilesTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildProfilesTable> {
  $$ChildProfilesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get nicknameId => $composableBuilder(
    column: $table.nicknameId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get avatarId =>
      $composableBuilder(column: $table.avatarId, builder: (column) => column);

  GeneratedColumn<String> get grade =>
      $composableBuilder(column: $table.grade, builder: (column) => column);

  GeneratedColumn<String> get startingLessonId => $composableBuilder(
    column: $table.startingLessonId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$ChildProfilesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildProfilesTable,
          ChildProfile,
          $$ChildProfilesTableFilterComposer,
          $$ChildProfilesTableOrderingComposer,
          $$ChildProfilesTableAnnotationComposer,
          $$ChildProfilesTableCreateCompanionBuilder,
          $$ChildProfilesTableUpdateCompanionBuilder,
          (
            ChildProfile,
            BaseReferences<_$AppDatabase, $ChildProfilesTable, ChildProfile>,
          ),
          ChildProfile,
          PrefetchHooks Function()
        > {
  $$ChildProfilesTableTableManager(_$AppDatabase db, $ChildProfilesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildProfilesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildProfilesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildProfilesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> nicknameId = const Value.absent(),
                Value<String> avatarId = const Value.absent(),
                Value<String> grade = const Value.absent(),
                Value<String> startingLessonId = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
              }) => ChildProfilesCompanion(
                id: id,
                nicknameId: nicknameId,
                avatarId: avatarId,
                grade: grade,
                startingLessonId: startingLessonId,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String nicknameId,
                required String avatarId,
                required String grade,
                required String startingLessonId,
                required int createdAt,
              }) => ChildProfilesCompanion.insert(
                id: id,
                nicknameId: nicknameId,
                avatarId: avatarId,
                grade: grade,
                startingLessonId: startingLessonId,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ChildProfilesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildProfilesTable,
      ChildProfile,
      $$ChildProfilesTableFilterComposer,
      $$ChildProfilesTableOrderingComposer,
      $$ChildProfilesTableAnnotationComposer,
      $$ChildProfilesTableCreateCompanionBuilder,
      $$ChildProfilesTableUpdateCompanionBuilder,
      (
        ChildProfile,
        BaseReferences<_$AppDatabase, $ChildProfilesTable, ChildProfile>,
      ),
      ChildProfile,
      PrefetchHooks Function()
    >;
typedef $$LetterRepsTableCreateCompanionBuilder =
    LetterRepsCompanion Function({
      required String letterId,
      required int cleanReps,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LetterRepsTableUpdateCompanionBuilder =
    LetterRepsCompanion Function({
      Value<String> letterId,
      Value<int> cleanReps,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LetterRepsTableFilterComposer
    extends Composer<_$AppDatabase, $LetterRepsTable> {
  $$LetterRepsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get cleanReps => $composableBuilder(
    column: $table.cleanReps,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterRepsTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterRepsTable> {
  $$LetterRepsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get cleanReps => $composableBuilder(
    column: $table.cleanReps,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterRepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterRepsTable> {
  $$LetterRepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<int> get cleanReps =>
      $composableBuilder(column: $table.cleanReps, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LetterRepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterRepsTable,
          LetterRep,
          $$LetterRepsTableFilterComposer,
          $$LetterRepsTableOrderingComposer,
          $$LetterRepsTableAnnotationComposer,
          $$LetterRepsTableCreateCompanionBuilder,
          $$LetterRepsTableUpdateCompanionBuilder,
          (
            LetterRep,
            BaseReferences<_$AppDatabase, $LetterRepsTable, LetterRep>,
          ),
          LetterRep,
          PrefetchHooks Function()
        > {
  $$LetterRepsTableTableManager(_$AppDatabase db, $LetterRepsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterRepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterRepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LetterRepsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> letterId = const Value.absent(),
                Value<int> cleanReps = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterRepsCompanion(
                letterId: letterId,
                cleanReps: cleanReps,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String letterId,
                required int cleanReps,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LetterRepsCompanion.insert(
                letterId: letterId,
                cleanReps: cleanReps,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LetterRepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterRepsTable,
      LetterRep,
      $$LetterRepsTableFilterComposer,
      $$LetterRepsTableOrderingComposer,
      $$LetterRepsTableAnnotationComposer,
      $$LetterRepsTableCreateCompanionBuilder,
      $$LetterRepsTableUpdateCompanionBuilder,
      (LetterRep, BaseReferences<_$AppDatabase, $LetterRepsTable, LetterRep>),
      LetterRep,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$LetterMasteryTableTableManager get letterMastery =>
      $$LetterMasteryTableTableManager(_db, _db.letterMastery);
  $$ChildProfilesTableTableManager get childProfiles =>
      $$ChildProfilesTableTableManager(_db, _db.childProfiles);
  $$LetterRepsTableTableManager get letterReps =>
      $$LetterRepsTableTableManager(_db, _db.letterReps);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
  AppDatabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'appDatabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$appDatabaseHash();

  @$internal
  @override
  $ProviderElement<AppDatabase> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  AppDatabase create(Ref ref) {
    return appDatabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AppDatabase value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AppDatabase>(value),
    );
  }
}

String _$appDatabaseHash() => r'59cce38d45eeaba199eddd097d8e149d66f9f3e1';

/// The visible persistence seam (D-09): on first read, write a trivial
/// non-sensitive sentinel to the DB, then read it back. Home displays the
/// round-tripped value to prove persistence end-to-end. Stores NOTHING
/// sensitive (threat T-01-02) and the value is never logged (T-01-04).

@ProviderFor(skeletonProof)
final skeletonProofProvider = SkeletonProofProvider._();

/// The visible persistence seam (D-09): on first read, write a trivial
/// non-sensitive sentinel to the DB, then read it back. Home displays the
/// round-tripped value to prove persistence end-to-end. Stores NOTHING
/// sensitive (threat T-01-02) and the value is never logged (T-01-04).

final class SkeletonProofProvider
    extends $FunctionalProvider<AsyncValue<String>, String, FutureOr<String>>
    with $FutureModifier<String>, $FutureProvider<String> {
  /// The visible persistence seam (D-09): on first read, write a trivial
  /// non-sensitive sentinel to the DB, then read it back. Home displays the
  /// round-tripped value to prove persistence end-to-end. Stores NOTHING
  /// sensitive (threat T-01-02) and the value is never logged (T-01-04).
  SkeletonProofProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'skeletonProofProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$skeletonProofHash();

  @$internal
  @override
  $FutureProviderElement<String> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<String> create(Ref ref) {
    return skeletonProof(ref);
  }
}

String _$skeletonProofHash() => r'85fdecf17e316d8855b62b2e6721d3d55aad7136';
