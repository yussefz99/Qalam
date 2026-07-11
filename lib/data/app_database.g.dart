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

class $LetterGraphPositionTable extends LetterGraphPosition
    with TableInfo<$LetterGraphPositionTable, LetterGraphPositionData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterGraphPositionTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _currentExerciseIdMeta = const VerificationMeta(
    'currentExerciseId',
  );
  @override
  late final GeneratedColumn<String> currentExerciseId =
      GeneratedColumn<String>(
        'current_exercise_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _clearedCompetenciesMeta =
      const VerificationMeta('clearedCompetencies');
  @override
  late final GeneratedColumn<String> clearedCompetencies =
      GeneratedColumn<String>(
        'cleared_competencies',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _clearedTiersMeta = const VerificationMeta(
    'clearedTiers',
  );
  @override
  late final GeneratedColumn<String> clearedTiers = GeneratedColumn<String>(
    'cleared_tiers',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    letterId,
    currentExerciseId,
    clearedCompetencies,
    clearedTiers,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_graph_position';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterGraphPositionData> instance, {
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
    if (data.containsKey('current_exercise_id')) {
      context.handle(
        _currentExerciseIdMeta,
        currentExerciseId.isAcceptableOrUnknown(
          data['current_exercise_id']!,
          _currentExerciseIdMeta,
        ),
      );
    }
    if (data.containsKey('cleared_competencies')) {
      context.handle(
        _clearedCompetenciesMeta,
        clearedCompetencies.isAcceptableOrUnknown(
          data['cleared_competencies']!,
          _clearedCompetenciesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clearedCompetenciesMeta);
    }
    if (data.containsKey('cleared_tiers')) {
      context.handle(
        _clearedTiersMeta,
        clearedTiers.isAcceptableOrUnknown(
          data['cleared_tiers']!,
          _clearedTiersMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_clearedTiersMeta);
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
  LetterGraphPositionData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterGraphPositionData(
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      currentExerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}current_exercise_id'],
      ),
      clearedCompetencies: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cleared_competencies'],
      )!,
      clearedTiers: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}cleared_tiers'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $LetterGraphPositionTable createAlias(String alias) {
    return $LetterGraphPositionTable(attachedDatabase, alias);
  }
}

class LetterGraphPositionData extends DataClass
    implements Insertable<LetterGraphPositionData> {
  final String letterId;
  final String? currentExerciseId;
  final String clearedCompetencies;
  final String clearedTiers;
  final DateTime updatedAt;
  const LetterGraphPositionData({
    required this.letterId,
    this.currentExerciseId,
    required this.clearedCompetencies,
    required this.clearedTiers,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['letter_id'] = Variable<String>(letterId);
    if (!nullToAbsent || currentExerciseId != null) {
      map['current_exercise_id'] = Variable<String>(currentExerciseId);
    }
    map['cleared_competencies'] = Variable<String>(clearedCompetencies);
    map['cleared_tiers'] = Variable<String>(clearedTiers);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LetterGraphPositionCompanion toCompanion(bool nullToAbsent) {
    return LetterGraphPositionCompanion(
      letterId: Value(letterId),
      currentExerciseId: currentExerciseId == null && nullToAbsent
          ? const Value.absent()
          : Value(currentExerciseId),
      clearedCompetencies: Value(clearedCompetencies),
      clearedTiers: Value(clearedTiers),
      updatedAt: Value(updatedAt),
    );
  }

  factory LetterGraphPositionData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterGraphPositionData(
      letterId: serializer.fromJson<String>(json['letterId']),
      currentExerciseId: serializer.fromJson<String?>(
        json['currentExerciseId'],
      ),
      clearedCompetencies: serializer.fromJson<String>(
        json['clearedCompetencies'],
      ),
      clearedTiers: serializer.fromJson<String>(json['clearedTiers']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'letterId': serializer.toJson<String>(letterId),
      'currentExerciseId': serializer.toJson<String?>(currentExerciseId),
      'clearedCompetencies': serializer.toJson<String>(clearedCompetencies),
      'clearedTiers': serializer.toJson<String>(clearedTiers),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LetterGraphPositionData copyWith({
    String? letterId,
    Value<String?> currentExerciseId = const Value.absent(),
    String? clearedCompetencies,
    String? clearedTiers,
    DateTime? updatedAt,
  }) => LetterGraphPositionData(
    letterId: letterId ?? this.letterId,
    currentExerciseId: currentExerciseId.present
        ? currentExerciseId.value
        : this.currentExerciseId,
    clearedCompetencies: clearedCompetencies ?? this.clearedCompetencies,
    clearedTiers: clearedTiers ?? this.clearedTiers,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LetterGraphPositionData copyWithCompanion(LetterGraphPositionCompanion data) {
    return LetterGraphPositionData(
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      currentExerciseId: data.currentExerciseId.present
          ? data.currentExerciseId.value
          : this.currentExerciseId,
      clearedCompetencies: data.clearedCompetencies.present
          ? data.clearedCompetencies.value
          : this.clearedCompetencies,
      clearedTiers: data.clearedTiers.present
          ? data.clearedTiers.value
          : this.clearedTiers,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterGraphPositionData(')
          ..write('letterId: $letterId, ')
          ..write('currentExerciseId: $currentExerciseId, ')
          ..write('clearedCompetencies: $clearedCompetencies, ')
          ..write('clearedTiers: $clearedTiers, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    letterId,
    currentExerciseId,
    clearedCompetencies,
    clearedTiers,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterGraphPositionData &&
          other.letterId == this.letterId &&
          other.currentExerciseId == this.currentExerciseId &&
          other.clearedCompetencies == this.clearedCompetencies &&
          other.clearedTiers == this.clearedTiers &&
          other.updatedAt == this.updatedAt);
}

class LetterGraphPositionCompanion
    extends UpdateCompanion<LetterGraphPositionData> {
  final Value<String> letterId;
  final Value<String?> currentExerciseId;
  final Value<String> clearedCompetencies;
  final Value<String> clearedTiers;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LetterGraphPositionCompanion({
    this.letterId = const Value.absent(),
    this.currentExerciseId = const Value.absent(),
    this.clearedCompetencies = const Value.absent(),
    this.clearedTiers = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LetterGraphPositionCompanion.insert({
    required String letterId,
    this.currentExerciseId = const Value.absent(),
    required String clearedCompetencies,
    required String clearedTiers,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : letterId = Value(letterId),
       clearedCompetencies = Value(clearedCompetencies),
       clearedTiers = Value(clearedTiers),
       updatedAt = Value(updatedAt);
  static Insertable<LetterGraphPositionData> custom({
    Expression<String>? letterId,
    Expression<String>? currentExerciseId,
    Expression<String>? clearedCompetencies,
    Expression<String>? clearedTiers,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (letterId != null) 'letter_id': letterId,
      if (currentExerciseId != null) 'current_exercise_id': currentExerciseId,
      if (clearedCompetencies != null)
        'cleared_competencies': clearedCompetencies,
      if (clearedTiers != null) 'cleared_tiers': clearedTiers,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LetterGraphPositionCompanion copyWith({
    Value<String>? letterId,
    Value<String?>? currentExerciseId,
    Value<String>? clearedCompetencies,
    Value<String>? clearedTiers,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LetterGraphPositionCompanion(
      letterId: letterId ?? this.letterId,
      currentExerciseId: currentExerciseId ?? this.currentExerciseId,
      clearedCompetencies: clearedCompetencies ?? this.clearedCompetencies,
      clearedTiers: clearedTiers ?? this.clearedTiers,
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
    if (currentExerciseId.present) {
      map['current_exercise_id'] = Variable<String>(currentExerciseId.value);
    }
    if (clearedCompetencies.present) {
      map['cleared_competencies'] = Variable<String>(clearedCompetencies.value);
    }
    if (clearedTiers.present) {
      map['cleared_tiers'] = Variable<String>(clearedTiers.value);
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
    return (StringBuffer('LetterGraphPositionCompanion(')
          ..write('letterId: $letterId, ')
          ..write('currentExerciseId: $currentExerciseId, ')
          ..write('clearedCompetencies: $clearedCompetencies, ')
          ..write('clearedTiers: $clearedTiers, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LetterExerciseRepsTable extends LetterExerciseReps
    with TableInfo<$LetterExerciseRepsTable, LetterExerciseRep> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterExerciseRepsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _exerciseIdMeta = const VerificationMeta(
    'exerciseId',
  );
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
    'exercise_id',
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
  List<GeneratedColumn> get $columns => [
    letterId,
    exerciseId,
    cleanReps,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_exercise_reps';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterExerciseRep> instance, {
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
    if (data.containsKey('exercise_id')) {
      context.handle(
        _exerciseIdMeta,
        exerciseId.isAcceptableOrUnknown(data['exercise_id']!, _exerciseIdMeta),
      );
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
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
  Set<GeneratedColumn> get $primaryKey => {letterId, exerciseId};
  @override
  LetterExerciseRep map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterExerciseRep(
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      exerciseId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_id'],
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
  $LetterExerciseRepsTable createAlias(String alias) {
    return $LetterExerciseRepsTable(attachedDatabase, alias);
  }
}

class LetterExerciseRep extends DataClass
    implements Insertable<LetterExerciseRep> {
  final String letterId;
  final String exerciseId;
  final int cleanReps;
  final DateTime updatedAt;
  const LetterExerciseRep({
    required this.letterId,
    required this.exerciseId,
    required this.cleanReps,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['letter_id'] = Variable<String>(letterId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['clean_reps'] = Variable<int>(cleanReps);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  LetterExerciseRepsCompanion toCompanion(bool nullToAbsent) {
    return LetterExerciseRepsCompanion(
      letterId: Value(letterId),
      exerciseId: Value(exerciseId),
      cleanReps: Value(cleanReps),
      updatedAt: Value(updatedAt),
    );
  }

  factory LetterExerciseRep.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterExerciseRep(
      letterId: serializer.fromJson<String>(json['letterId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      cleanReps: serializer.fromJson<int>(json['cleanReps']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'letterId': serializer.toJson<String>(letterId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'cleanReps': serializer.toJson<int>(cleanReps),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  LetterExerciseRep copyWith({
    String? letterId,
    String? exerciseId,
    int? cleanReps,
    DateTime? updatedAt,
  }) => LetterExerciseRep(
    letterId: letterId ?? this.letterId,
    exerciseId: exerciseId ?? this.exerciseId,
    cleanReps: cleanReps ?? this.cleanReps,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  LetterExerciseRep copyWithCompanion(LetterExerciseRepsCompanion data) {
    return LetterExerciseRep(
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      exerciseId: data.exerciseId.present
          ? data.exerciseId.value
          : this.exerciseId,
      cleanReps: data.cleanReps.present ? data.cleanReps.value : this.cleanReps,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterExerciseRep(')
          ..write('letterId: $letterId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(letterId, exerciseId, cleanReps, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterExerciseRep &&
          other.letterId == this.letterId &&
          other.exerciseId == this.exerciseId &&
          other.cleanReps == this.cleanReps &&
          other.updatedAt == this.updatedAt);
}

class LetterExerciseRepsCompanion extends UpdateCompanion<LetterExerciseRep> {
  final Value<String> letterId;
  final Value<String> exerciseId;
  final Value<int> cleanReps;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const LetterExerciseRepsCompanion({
    this.letterId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.cleanReps = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LetterExerciseRepsCompanion.insert({
    required String letterId,
    required String exerciseId,
    required int cleanReps,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : letterId = Value(letterId),
       exerciseId = Value(exerciseId),
       cleanReps = Value(cleanReps),
       updatedAt = Value(updatedAt);
  static Insertable<LetterExerciseRep> custom({
    Expression<String>? letterId,
    Expression<String>? exerciseId,
    Expression<int>? cleanReps,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (letterId != null) 'letter_id': letterId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (cleanReps != null) 'clean_reps': cleanReps,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LetterExerciseRepsCompanion copyWith({
    Value<String>? letterId,
    Value<String>? exerciseId,
    Value<int>? cleanReps,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return LetterExerciseRepsCompanion(
      letterId: letterId ?? this.letterId,
      exerciseId: exerciseId ?? this.exerciseId,
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
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
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
    return (StringBuffer('LetterExerciseRepsCompanion(')
          ..write('letterId: $letterId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('cleanReps: $cleanReps, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LetterCriterionEvidenceTable extends LetterCriterionEvidence
    with TableInfo<$LetterCriterionEvidenceTable, LetterCriterionEvidenceData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LetterCriterionEvidenceTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _criterionMeta = const VerificationMeta(
    'criterion',
  );
  @override
  late final GeneratedColumn<String> criterion = GeneratedColumn<String>(
    'criterion',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _passedMeta = const VerificationMeta('passed');
  @override
  late final GeneratedColumn<bool> passed = GeneratedColumn<bool>(
    'passed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("passed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _sourceMeta = const VerificationMeta('source');
  @override
  late final GeneratedColumn<String> source = GeneratedColumn<String>(
    'source',
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
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    letterId,
    criterion,
    passed,
    source,
    createdAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'letter_criterion_evidence';
  @override
  VerificationContext validateIntegrity(
    Insertable<LetterCriterionEvidenceData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('letter_id')) {
      context.handle(
        _letterIdMeta,
        letterId.isAcceptableOrUnknown(data['letter_id']!, _letterIdMeta),
      );
    } else if (isInserting) {
      context.missing(_letterIdMeta);
    }
    if (data.containsKey('criterion')) {
      context.handle(
        _criterionMeta,
        criterion.isAcceptableOrUnknown(data['criterion']!, _criterionMeta),
      );
    } else if (isInserting) {
      context.missing(_criterionMeta);
    }
    if (data.containsKey('passed')) {
      context.handle(
        _passedMeta,
        passed.isAcceptableOrUnknown(data['passed']!, _passedMeta),
      );
    } else if (isInserting) {
      context.missing(_passedMeta);
    }
    if (data.containsKey('source')) {
      context.handle(
        _sourceMeta,
        source.isAcceptableOrUnknown(data['source']!, _sourceMeta),
      );
    } else if (isInserting) {
      context.missing(_sourceMeta);
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
  LetterCriterionEvidenceData map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LetterCriterionEvidenceData(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      criterion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}criterion'],
      )!,
      passed: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}passed'],
      )!,
      source: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}created_at'],
      )!,
    );
  }

  @override
  $LetterCriterionEvidenceTable createAlias(String alias) {
    return $LetterCriterionEvidenceTable(attachedDatabase, alias);
  }
}

class LetterCriterionEvidenceData extends DataClass
    implements Insertable<LetterCriterionEvidenceData> {
  final int id;
  final String letterId;
  final String criterion;
  final bool passed;
  final String source;
  final DateTime createdAt;
  const LetterCriterionEvidenceData({
    required this.id,
    required this.letterId,
    required this.criterion,
    required this.passed,
    required this.source,
    required this.createdAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['letter_id'] = Variable<String>(letterId);
    map['criterion'] = Variable<String>(criterion);
    map['passed'] = Variable<bool>(passed);
    map['source'] = Variable<String>(source);
    map['created_at'] = Variable<DateTime>(createdAt);
    return map;
  }

  LetterCriterionEvidenceCompanion toCompanion(bool nullToAbsent) {
    return LetterCriterionEvidenceCompanion(
      id: Value(id),
      letterId: Value(letterId),
      criterion: Value(criterion),
      passed: Value(passed),
      source: Value(source),
      createdAt: Value(createdAt),
    );
  }

  factory LetterCriterionEvidenceData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LetterCriterionEvidenceData(
      id: serializer.fromJson<int>(json['id']),
      letterId: serializer.fromJson<String>(json['letterId']),
      criterion: serializer.fromJson<String>(json['criterion']),
      passed: serializer.fromJson<bool>(json['passed']),
      source: serializer.fromJson<String>(json['source']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'letterId': serializer.toJson<String>(letterId),
      'criterion': serializer.toJson<String>(criterion),
      'passed': serializer.toJson<bool>(passed),
      'source': serializer.toJson<String>(source),
      'createdAt': serializer.toJson<DateTime>(createdAt),
    };
  }

  LetterCriterionEvidenceData copyWith({
    int? id,
    String? letterId,
    String? criterion,
    bool? passed,
    String? source,
    DateTime? createdAt,
  }) => LetterCriterionEvidenceData(
    id: id ?? this.id,
    letterId: letterId ?? this.letterId,
    criterion: criterion ?? this.criterion,
    passed: passed ?? this.passed,
    source: source ?? this.source,
    createdAt: createdAt ?? this.createdAt,
  );
  LetterCriterionEvidenceData copyWithCompanion(
    LetterCriterionEvidenceCompanion data,
  ) {
    return LetterCriterionEvidenceData(
      id: data.id.present ? data.id.value : this.id,
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      criterion: data.criterion.present ? data.criterion.value : this.criterion,
      passed: data.passed.present ? data.passed.value : this.passed,
      source: data.source.present ? data.source.value : this.source,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LetterCriterionEvidenceData(')
          ..write('id: $id, ')
          ..write('letterId: $letterId, ')
          ..write('criterion: $criterion, ')
          ..write('passed: $passed, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, letterId, criterion, passed, source, createdAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LetterCriterionEvidenceData &&
          other.id == this.id &&
          other.letterId == this.letterId &&
          other.criterion == this.criterion &&
          other.passed == this.passed &&
          other.source == this.source &&
          other.createdAt == this.createdAt);
}

class LetterCriterionEvidenceCompanion
    extends UpdateCompanion<LetterCriterionEvidenceData> {
  final Value<int> id;
  final Value<String> letterId;
  final Value<String> criterion;
  final Value<bool> passed;
  final Value<String> source;
  final Value<DateTime> createdAt;
  const LetterCriterionEvidenceCompanion({
    this.id = const Value.absent(),
    this.letterId = const Value.absent(),
    this.criterion = const Value.absent(),
    this.passed = const Value.absent(),
    this.source = const Value.absent(),
    this.createdAt = const Value.absent(),
  });
  LetterCriterionEvidenceCompanion.insert({
    this.id = const Value.absent(),
    required String letterId,
    required String criterion,
    required bool passed,
    required String source,
    required DateTime createdAt,
  }) : letterId = Value(letterId),
       criterion = Value(criterion),
       passed = Value(passed),
       source = Value(source),
       createdAt = Value(createdAt);
  static Insertable<LetterCriterionEvidenceData> custom({
    Expression<int>? id,
    Expression<String>? letterId,
    Expression<String>? criterion,
    Expression<bool>? passed,
    Expression<String>? source,
    Expression<DateTime>? createdAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (letterId != null) 'letter_id': letterId,
      if (criterion != null) 'criterion': criterion,
      if (passed != null) 'passed': passed,
      if (source != null) 'source': source,
      if (createdAt != null) 'created_at': createdAt,
    });
  }

  LetterCriterionEvidenceCompanion copyWith({
    Value<int>? id,
    Value<String>? letterId,
    Value<String>? criterion,
    Value<bool>? passed,
    Value<String>? source,
    Value<DateTime>? createdAt,
  }) {
    return LetterCriterionEvidenceCompanion(
      id: id ?? this.id,
      letterId: letterId ?? this.letterId,
      criterion: criterion ?? this.criterion,
      passed: passed ?? this.passed,
      source: source ?? this.source,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (letterId.present) {
      map['letter_id'] = Variable<String>(letterId.value);
    }
    if (criterion.present) {
      map['criterion'] = Variable<String>(criterion.value);
    }
    if (passed.present) {
      map['passed'] = Variable<bool>(passed.value);
    }
    if (source.present) {
      map['source'] = Variable<String>(source.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LetterCriterionEvidenceCompanion(')
          ..write('id: $id, ')
          ..write('letterId: $letterId, ')
          ..write('criterion: $criterion, ')
          ..write('passed: $passed, ')
          ..write('source: $source, ')
          ..write('createdAt: $createdAt')
          ..write(')'))
        .toString();
  }
}

class $ArcStateRowsTable extends ArcStateRows
    with TableInfo<$ArcStateRowsTable, ArcStateRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ArcStateRowsTable(this.attachedDatabase, [this._alias]);
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
  static const VerificationMeta _activeMeta = const VerificationMeta('active');
  @override
  late final GeneratedColumn<bool> active = GeneratedColumn<bool>(
    'active',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("active" IN (0, 1))',
    ),
  );
  static const VerificationMeta _stepMeta = const VerificationMeta('step');
  @override
  late final GeneratedColumn<String> step = GeneratedColumn<String>(
    'step',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _targetCriterionMeta = const VerificationMeta(
    'targetCriterion',
  );
  @override
  late final GeneratedColumn<String> targetCriterion = GeneratedColumn<String>(
    'target_criterion',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseToRetryMeta = const VerificationMeta(
    'exerciseToRetry',
  );
  @override
  late final GeneratedColumn<String> exerciseToRetry = GeneratedColumn<String>(
    'exercise_to_retry',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
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
    letterId,
    active,
    step,
    targetCriterion,
    exerciseToRetry,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'arc_state_rows';
  @override
  VerificationContext validateIntegrity(
    Insertable<ArcStateRow> instance, {
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
    if (data.containsKey('active')) {
      context.handle(
        _activeMeta,
        active.isAcceptableOrUnknown(data['active']!, _activeMeta),
      );
    } else if (isInserting) {
      context.missing(_activeMeta);
    }
    if (data.containsKey('step')) {
      context.handle(
        _stepMeta,
        step.isAcceptableOrUnknown(data['step']!, _stepMeta),
      );
    } else if (isInserting) {
      context.missing(_stepMeta);
    }
    if (data.containsKey('target_criterion')) {
      context.handle(
        _targetCriterionMeta,
        targetCriterion.isAcceptableOrUnknown(
          data['target_criterion']!,
          _targetCriterionMeta,
        ),
      );
    }
    if (data.containsKey('exercise_to_retry')) {
      context.handle(
        _exerciseToRetryMeta,
        exerciseToRetry.isAcceptableOrUnknown(
          data['exercise_to_retry']!,
          _exerciseToRetryMeta,
        ),
      );
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
  ArcStateRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ArcStateRow(
      letterId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}letter_id'],
      )!,
      active: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}active'],
      )!,
      step: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}step'],
      )!,
      targetCriterion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}target_criterion'],
      ),
      exerciseToRetry: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}exercise_to_retry'],
      ),
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ArcStateRowsTable createAlias(String alias) {
    return $ArcStateRowsTable(attachedDatabase, alias);
  }
}

class ArcStateRow extends DataClass implements Insertable<ArcStateRow> {
  final String letterId;
  final bool active;
  final String step;
  final String? targetCriterion;
  final String? exerciseToRetry;
  final DateTime updatedAt;
  const ArcStateRow({
    required this.letterId,
    required this.active,
    required this.step,
    this.targetCriterion,
    this.exerciseToRetry,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['letter_id'] = Variable<String>(letterId);
    map['active'] = Variable<bool>(active);
    map['step'] = Variable<String>(step);
    if (!nullToAbsent || targetCriterion != null) {
      map['target_criterion'] = Variable<String>(targetCriterion);
    }
    if (!nullToAbsent || exerciseToRetry != null) {
      map['exercise_to_retry'] = Variable<String>(exerciseToRetry);
    }
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ArcStateRowsCompanion toCompanion(bool nullToAbsent) {
    return ArcStateRowsCompanion(
      letterId: Value(letterId),
      active: Value(active),
      step: Value(step),
      targetCriterion: targetCriterion == null && nullToAbsent
          ? const Value.absent()
          : Value(targetCriterion),
      exerciseToRetry: exerciseToRetry == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseToRetry),
      updatedAt: Value(updatedAt),
    );
  }

  factory ArcStateRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ArcStateRow(
      letterId: serializer.fromJson<String>(json['letterId']),
      active: serializer.fromJson<bool>(json['active']),
      step: serializer.fromJson<String>(json['step']),
      targetCriterion: serializer.fromJson<String?>(json['targetCriterion']),
      exerciseToRetry: serializer.fromJson<String?>(json['exerciseToRetry']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'letterId': serializer.toJson<String>(letterId),
      'active': serializer.toJson<bool>(active),
      'step': serializer.toJson<String>(step),
      'targetCriterion': serializer.toJson<String?>(targetCriterion),
      'exerciseToRetry': serializer.toJson<String?>(exerciseToRetry),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ArcStateRow copyWith({
    String? letterId,
    bool? active,
    String? step,
    Value<String?> targetCriterion = const Value.absent(),
    Value<String?> exerciseToRetry = const Value.absent(),
    DateTime? updatedAt,
  }) => ArcStateRow(
    letterId: letterId ?? this.letterId,
    active: active ?? this.active,
    step: step ?? this.step,
    targetCriterion: targetCriterion.present
        ? targetCriterion.value
        : this.targetCriterion,
    exerciseToRetry: exerciseToRetry.present
        ? exerciseToRetry.value
        : this.exerciseToRetry,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ArcStateRow copyWithCompanion(ArcStateRowsCompanion data) {
    return ArcStateRow(
      letterId: data.letterId.present ? data.letterId.value : this.letterId,
      active: data.active.present ? data.active.value : this.active,
      step: data.step.present ? data.step.value : this.step,
      targetCriterion: data.targetCriterion.present
          ? data.targetCriterion.value
          : this.targetCriterion,
      exerciseToRetry: data.exerciseToRetry.present
          ? data.exerciseToRetry.value
          : this.exerciseToRetry,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ArcStateRow(')
          ..write('letterId: $letterId, ')
          ..write('active: $active, ')
          ..write('step: $step, ')
          ..write('targetCriterion: $targetCriterion, ')
          ..write('exerciseToRetry: $exerciseToRetry, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    letterId,
    active,
    step,
    targetCriterion,
    exerciseToRetry,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ArcStateRow &&
          other.letterId == this.letterId &&
          other.active == this.active &&
          other.step == this.step &&
          other.targetCriterion == this.targetCriterion &&
          other.exerciseToRetry == this.exerciseToRetry &&
          other.updatedAt == this.updatedAt);
}

class ArcStateRowsCompanion extends UpdateCompanion<ArcStateRow> {
  final Value<String> letterId;
  final Value<bool> active;
  final Value<String> step;
  final Value<String?> targetCriterion;
  final Value<String?> exerciseToRetry;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ArcStateRowsCompanion({
    this.letterId = const Value.absent(),
    this.active = const Value.absent(),
    this.step = const Value.absent(),
    this.targetCriterion = const Value.absent(),
    this.exerciseToRetry = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ArcStateRowsCompanion.insert({
    required String letterId,
    required bool active,
    required String step,
    this.targetCriterion = const Value.absent(),
    this.exerciseToRetry = const Value.absent(),
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : letterId = Value(letterId),
       active = Value(active),
       step = Value(step),
       updatedAt = Value(updatedAt);
  static Insertable<ArcStateRow> custom({
    Expression<String>? letterId,
    Expression<bool>? active,
    Expression<String>? step,
    Expression<String>? targetCriterion,
    Expression<String>? exerciseToRetry,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (letterId != null) 'letter_id': letterId,
      if (active != null) 'active': active,
      if (step != null) 'step': step,
      if (targetCriterion != null) 'target_criterion': targetCriterion,
      if (exerciseToRetry != null) 'exercise_to_retry': exerciseToRetry,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ArcStateRowsCompanion copyWith({
    Value<String>? letterId,
    Value<bool>? active,
    Value<String>? step,
    Value<String?>? targetCriterion,
    Value<String?>? exerciseToRetry,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ArcStateRowsCompanion(
      letterId: letterId ?? this.letterId,
      active: active ?? this.active,
      step: step ?? this.step,
      targetCriterion: targetCriterion ?? this.targetCriterion,
      exerciseToRetry: exerciseToRetry ?? this.exerciseToRetry,
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
    if (active.present) {
      map['active'] = Variable<bool>(active.value);
    }
    if (step.present) {
      map['step'] = Variable<String>(step.value);
    }
    if (targetCriterion.present) {
      map['target_criterion'] = Variable<String>(targetCriterion.value);
    }
    if (exerciseToRetry.present) {
      map['exercise_to_retry'] = Variable<String>(exerciseToRetry.value);
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
    return (StringBuffer('ArcStateRowsCompanion(')
          ..write('letterId: $letterId, ')
          ..write('active: $active, ')
          ..write('step: $step, ')
          ..write('targetCriterion: $targetCriterion, ')
          ..write('exerciseToRetry: $exerciseToRetry, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ChildProfileMirrorTable extends ChildProfileMirror
    with TableInfo<$ChildProfileMirrorTable, ChildProfileMirrorData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ChildProfileMirrorTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _uidMeta = const VerificationMeta('uid');
  @override
  late final GeneratedColumn<String> uid = GeneratedColumn<String>(
    'uid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strengthsMeta = const VerificationMeta(
    'strengths',
  );
  @override
  late final GeneratedColumn<String> strengths = GeneratedColumn<String>(
    'strengths',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _strugglesMeta = const VerificationMeta(
    'struggles',
  );
  @override
  late final GeneratedColumn<String> struggles = GeneratedColumn<String>(
    'struggles',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _perCriterionMeta = const VerificationMeta(
    'perCriterion',
  );
  @override
  late final GeneratedColumn<String> perCriterion = GeneratedColumn<String>(
    'per_criterion',
    aliasedName,
    false,
    type: DriftSqlType.string,
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
    uid,
    strengths,
    struggles,
    perCriterion,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'child_profile_mirror';
  @override
  VerificationContext validateIntegrity(
    Insertable<ChildProfileMirrorData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uid')) {
      context.handle(
        _uidMeta,
        uid.isAcceptableOrUnknown(data['uid']!, _uidMeta),
      );
    } else if (isInserting) {
      context.missing(_uidMeta);
    }
    if (data.containsKey('strengths')) {
      context.handle(
        _strengthsMeta,
        strengths.isAcceptableOrUnknown(data['strengths']!, _strengthsMeta),
      );
    } else if (isInserting) {
      context.missing(_strengthsMeta);
    }
    if (data.containsKey('struggles')) {
      context.handle(
        _strugglesMeta,
        struggles.isAcceptableOrUnknown(data['struggles']!, _strugglesMeta),
      );
    } else if (isInserting) {
      context.missing(_strugglesMeta);
    }
    if (data.containsKey('per_criterion')) {
      context.handle(
        _perCriterionMeta,
        perCriterion.isAcceptableOrUnknown(
          data['per_criterion']!,
          _perCriterionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_perCriterionMeta);
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
  Set<GeneratedColumn> get $primaryKey => {uid};
  @override
  ChildProfileMirrorData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ChildProfileMirrorData(
      uid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uid'],
      )!,
      strengths: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}strengths'],
      )!,
      struggles: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}struggles'],
      )!,
      perCriterion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}per_criterion'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.dateTime,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ChildProfileMirrorTable createAlias(String alias) {
    return $ChildProfileMirrorTable(attachedDatabase, alias);
  }
}

class ChildProfileMirrorData extends DataClass
    implements Insertable<ChildProfileMirrorData> {
  final String uid;
  final String strengths;
  final String struggles;
  final String perCriterion;
  final DateTime updatedAt;
  const ChildProfileMirrorData({
    required this.uid,
    required this.strengths,
    required this.struggles,
    required this.perCriterion,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['uid'] = Variable<String>(uid);
    map['strengths'] = Variable<String>(strengths);
    map['struggles'] = Variable<String>(struggles);
    map['per_criterion'] = Variable<String>(perCriterion);
    map['updated_at'] = Variable<DateTime>(updatedAt);
    return map;
  }

  ChildProfileMirrorCompanion toCompanion(bool nullToAbsent) {
    return ChildProfileMirrorCompanion(
      uid: Value(uid),
      strengths: Value(strengths),
      struggles: Value(struggles),
      perCriterion: Value(perCriterion),
      updatedAt: Value(updatedAt),
    );
  }

  factory ChildProfileMirrorData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ChildProfileMirrorData(
      uid: serializer.fromJson<String>(json['uid']),
      strengths: serializer.fromJson<String>(json['strengths']),
      struggles: serializer.fromJson<String>(json['struggles']),
      perCriterion: serializer.fromJson<String>(json['perCriterion']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'uid': serializer.toJson<String>(uid),
      'strengths': serializer.toJson<String>(strengths),
      'struggles': serializer.toJson<String>(struggles),
      'perCriterion': serializer.toJson<String>(perCriterion),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  ChildProfileMirrorData copyWith({
    String? uid,
    String? strengths,
    String? struggles,
    String? perCriterion,
    DateTime? updatedAt,
  }) => ChildProfileMirrorData(
    uid: uid ?? this.uid,
    strengths: strengths ?? this.strengths,
    struggles: struggles ?? this.struggles,
    perCriterion: perCriterion ?? this.perCriterion,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ChildProfileMirrorData copyWithCompanion(ChildProfileMirrorCompanion data) {
    return ChildProfileMirrorData(
      uid: data.uid.present ? data.uid.value : this.uid,
      strengths: data.strengths.present ? data.strengths.value : this.strengths,
      struggles: data.struggles.present ? data.struggles.value : this.struggles,
      perCriterion: data.perCriterion.present
          ? data.perCriterion.value
          : this.perCriterion,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ChildProfileMirrorData(')
          ..write('uid: $uid, ')
          ..write('strengths: $strengths, ')
          ..write('struggles: $struggles, ')
          ..write('perCriterion: $perCriterion, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(uid, strengths, struggles, perCriterion, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ChildProfileMirrorData &&
          other.uid == this.uid &&
          other.strengths == this.strengths &&
          other.struggles == this.struggles &&
          other.perCriterion == this.perCriterion &&
          other.updatedAt == this.updatedAt);
}

class ChildProfileMirrorCompanion
    extends UpdateCompanion<ChildProfileMirrorData> {
  final Value<String> uid;
  final Value<String> strengths;
  final Value<String> struggles;
  final Value<String> perCriterion;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const ChildProfileMirrorCompanion({
    this.uid = const Value.absent(),
    this.strengths = const Value.absent(),
    this.struggles = const Value.absent(),
    this.perCriterion = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ChildProfileMirrorCompanion.insert({
    required String uid,
    required String strengths,
    required String struggles,
    required String perCriterion,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : uid = Value(uid),
       strengths = Value(strengths),
       struggles = Value(struggles),
       perCriterion = Value(perCriterion),
       updatedAt = Value(updatedAt);
  static Insertable<ChildProfileMirrorData> custom({
    Expression<String>? uid,
    Expression<String>? strengths,
    Expression<String>? struggles,
    Expression<String>? perCriterion,
    Expression<DateTime>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (uid != null) 'uid': uid,
      if (strengths != null) 'strengths': strengths,
      if (struggles != null) 'struggles': struggles,
      if (perCriterion != null) 'per_criterion': perCriterion,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ChildProfileMirrorCompanion copyWith({
    Value<String>? uid,
    Value<String>? strengths,
    Value<String>? struggles,
    Value<String>? perCriterion,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return ChildProfileMirrorCompanion(
      uid: uid ?? this.uid,
      strengths: strengths ?? this.strengths,
      struggles: struggles ?? this.struggles,
      perCriterion: perCriterion ?? this.perCriterion,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (uid.present) {
      map['uid'] = Variable<String>(uid.value);
    }
    if (strengths.present) {
      map['strengths'] = Variable<String>(strengths.value);
    }
    if (struggles.present) {
      map['struggles'] = Variable<String>(struggles.value);
    }
    if (perCriterion.present) {
      map['per_criterion'] = Variable<String>(perCriterion.value);
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
    return (StringBuffer('ChildProfileMirrorCompanion(')
          ..write('uid: $uid, ')
          ..write('strengths: $strengths, ')
          ..write('struggles: $struggles, ')
          ..write('perCriterion: $perCriterion, ')
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
  late final $LetterGraphPositionTable letterGraphPosition =
      $LetterGraphPositionTable(this);
  late final $LetterExerciseRepsTable letterExerciseReps =
      $LetterExerciseRepsTable(this);
  late final $LetterCriterionEvidenceTable letterCriterionEvidence =
      $LetterCriterionEvidenceTable(this);
  late final $ArcStateRowsTable arcStateRows = $ArcStateRowsTable(this);
  late final $ChildProfileMirrorTable childProfileMirror =
      $ChildProfileMirrorTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    letterMastery,
    childProfiles,
    letterReps,
    letterGraphPosition,
    letterExerciseReps,
    letterCriterionEvidence,
    arcStateRows,
    childProfileMirror,
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
typedef $$LetterGraphPositionTableCreateCompanionBuilder =
    LetterGraphPositionCompanion Function({
      required String letterId,
      Value<String?> currentExerciseId,
      required String clearedCompetencies,
      required String clearedTiers,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LetterGraphPositionTableUpdateCompanionBuilder =
    LetterGraphPositionCompanion Function({
      Value<String> letterId,
      Value<String?> currentExerciseId,
      Value<String> clearedCompetencies,
      Value<String> clearedTiers,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LetterGraphPositionTableFilterComposer
    extends Composer<_$AppDatabase, $LetterGraphPositionTable> {
  $$LetterGraphPositionTableFilterComposer({
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

  ColumnFilters<String> get currentExerciseId => $composableBuilder(
    column: $table.currentExerciseId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clearedCompetencies => $composableBuilder(
    column: $table.clearedCompetencies,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get clearedTiers => $composableBuilder(
    column: $table.clearedTiers,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterGraphPositionTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterGraphPositionTable> {
  $$LetterGraphPositionTableOrderingComposer({
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

  ColumnOrderings<String> get currentExerciseId => $composableBuilder(
    column: $table.currentExerciseId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clearedCompetencies => $composableBuilder(
    column: $table.clearedCompetencies,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get clearedTiers => $composableBuilder(
    column: $table.clearedTiers,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterGraphPositionTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterGraphPositionTable> {
  $$LetterGraphPositionTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<String> get currentExerciseId => $composableBuilder(
    column: $table.currentExerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clearedCompetencies => $composableBuilder(
    column: $table.clearedCompetencies,
    builder: (column) => column,
  );

  GeneratedColumn<String> get clearedTiers => $composableBuilder(
    column: $table.clearedTiers,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LetterGraphPositionTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterGraphPositionTable,
          LetterGraphPositionData,
          $$LetterGraphPositionTableFilterComposer,
          $$LetterGraphPositionTableOrderingComposer,
          $$LetterGraphPositionTableAnnotationComposer,
          $$LetterGraphPositionTableCreateCompanionBuilder,
          $$LetterGraphPositionTableUpdateCompanionBuilder,
          (
            LetterGraphPositionData,
            BaseReferences<
              _$AppDatabase,
              $LetterGraphPositionTable,
              LetterGraphPositionData
            >,
          ),
          LetterGraphPositionData,
          PrefetchHooks Function()
        > {
  $$LetterGraphPositionTableTableManager(
    _$AppDatabase db,
    $LetterGraphPositionTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterGraphPositionTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterGraphPositionTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LetterGraphPositionTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> letterId = const Value.absent(),
                Value<String?> currentExerciseId = const Value.absent(),
                Value<String> clearedCompetencies = const Value.absent(),
                Value<String> clearedTiers = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterGraphPositionCompanion(
                letterId: letterId,
                currentExerciseId: currentExerciseId,
                clearedCompetencies: clearedCompetencies,
                clearedTiers: clearedTiers,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String letterId,
                Value<String?> currentExerciseId = const Value.absent(),
                required String clearedCompetencies,
                required String clearedTiers,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LetterGraphPositionCompanion.insert(
                letterId: letterId,
                currentExerciseId: currentExerciseId,
                clearedCompetencies: clearedCompetencies,
                clearedTiers: clearedTiers,
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

typedef $$LetterGraphPositionTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterGraphPositionTable,
      LetterGraphPositionData,
      $$LetterGraphPositionTableFilterComposer,
      $$LetterGraphPositionTableOrderingComposer,
      $$LetterGraphPositionTableAnnotationComposer,
      $$LetterGraphPositionTableCreateCompanionBuilder,
      $$LetterGraphPositionTableUpdateCompanionBuilder,
      (
        LetterGraphPositionData,
        BaseReferences<
          _$AppDatabase,
          $LetterGraphPositionTable,
          LetterGraphPositionData
        >,
      ),
      LetterGraphPositionData,
      PrefetchHooks Function()
    >;
typedef $$LetterExerciseRepsTableCreateCompanionBuilder =
    LetterExerciseRepsCompanion Function({
      required String letterId,
      required String exerciseId,
      required int cleanReps,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$LetterExerciseRepsTableUpdateCompanionBuilder =
    LetterExerciseRepsCompanion Function({
      Value<String> letterId,
      Value<String> exerciseId,
      Value<int> cleanReps,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$LetterExerciseRepsTableFilterComposer
    extends Composer<_$AppDatabase, $LetterExerciseRepsTable> {
  $$LetterExerciseRepsTableFilterComposer({
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

  ColumnFilters<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
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

class $$LetterExerciseRepsTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterExerciseRepsTable> {
  $$LetterExerciseRepsTableOrderingComposer({
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

  ColumnOrderings<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
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

class $$LetterExerciseRepsTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterExerciseRepsTable> {
  $$LetterExerciseRepsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
    column: $table.exerciseId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get cleanReps =>
      $composableBuilder(column: $table.cleanReps, builder: (column) => column);

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$LetterExerciseRepsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterExerciseRepsTable,
          LetterExerciseRep,
          $$LetterExerciseRepsTableFilterComposer,
          $$LetterExerciseRepsTableOrderingComposer,
          $$LetterExerciseRepsTableAnnotationComposer,
          $$LetterExerciseRepsTableCreateCompanionBuilder,
          $$LetterExerciseRepsTableUpdateCompanionBuilder,
          (
            LetterExerciseRep,
            BaseReferences<
              _$AppDatabase,
              $LetterExerciseRepsTable,
              LetterExerciseRep
            >,
          ),
          LetterExerciseRep,
          PrefetchHooks Function()
        > {
  $$LetterExerciseRepsTableTableManager(
    _$AppDatabase db,
    $LetterExerciseRepsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterExerciseRepsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$LetterExerciseRepsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$LetterExerciseRepsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> letterId = const Value.absent(),
                Value<String> exerciseId = const Value.absent(),
                Value<int> cleanReps = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LetterExerciseRepsCompanion(
                letterId: letterId,
                exerciseId: exerciseId,
                cleanReps: cleanReps,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String letterId,
                required String exerciseId,
                required int cleanReps,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => LetterExerciseRepsCompanion.insert(
                letterId: letterId,
                exerciseId: exerciseId,
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

typedef $$LetterExerciseRepsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterExerciseRepsTable,
      LetterExerciseRep,
      $$LetterExerciseRepsTableFilterComposer,
      $$LetterExerciseRepsTableOrderingComposer,
      $$LetterExerciseRepsTableAnnotationComposer,
      $$LetterExerciseRepsTableCreateCompanionBuilder,
      $$LetterExerciseRepsTableUpdateCompanionBuilder,
      (
        LetterExerciseRep,
        BaseReferences<
          _$AppDatabase,
          $LetterExerciseRepsTable,
          LetterExerciseRep
        >,
      ),
      LetterExerciseRep,
      PrefetchHooks Function()
    >;
typedef $$LetterCriterionEvidenceTableCreateCompanionBuilder =
    LetterCriterionEvidenceCompanion Function({
      Value<int> id,
      required String letterId,
      required String criterion,
      required bool passed,
      required String source,
      required DateTime createdAt,
    });
typedef $$LetterCriterionEvidenceTableUpdateCompanionBuilder =
    LetterCriterionEvidenceCompanion Function({
      Value<int> id,
      Value<String> letterId,
      Value<String> criterion,
      Value<bool> passed,
      Value<String> source,
      Value<DateTime> createdAt,
    });

class $$LetterCriterionEvidenceTableFilterComposer
    extends Composer<_$AppDatabase, $LetterCriterionEvidenceTable> {
  $$LetterCriterionEvidenceTableFilterComposer({
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

  ColumnFilters<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get criterion => $composableBuilder(
    column: $table.criterion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LetterCriterionEvidenceTableOrderingComposer
    extends Composer<_$AppDatabase, $LetterCriterionEvidenceTable> {
  $$LetterCriterionEvidenceTableOrderingComposer({
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

  ColumnOrderings<String> get letterId => $composableBuilder(
    column: $table.letterId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get criterion => $composableBuilder(
    column: $table.criterion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get passed => $composableBuilder(
    column: $table.passed,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get source => $composableBuilder(
    column: $table.source,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LetterCriterionEvidenceTableAnnotationComposer
    extends Composer<_$AppDatabase, $LetterCriterionEvidenceTable> {
  $$LetterCriterionEvidenceTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<String> get criterion =>
      $composableBuilder(column: $table.criterion, builder: (column) => column);

  GeneratedColumn<bool> get passed =>
      $composableBuilder(column: $table.passed, builder: (column) => column);

  GeneratedColumn<String> get source =>
      $composableBuilder(column: $table.source, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);
}

class $$LetterCriterionEvidenceTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LetterCriterionEvidenceTable,
          LetterCriterionEvidenceData,
          $$LetterCriterionEvidenceTableFilterComposer,
          $$LetterCriterionEvidenceTableOrderingComposer,
          $$LetterCriterionEvidenceTableAnnotationComposer,
          $$LetterCriterionEvidenceTableCreateCompanionBuilder,
          $$LetterCriterionEvidenceTableUpdateCompanionBuilder,
          (
            LetterCriterionEvidenceData,
            BaseReferences<
              _$AppDatabase,
              $LetterCriterionEvidenceTable,
              LetterCriterionEvidenceData
            >,
          ),
          LetterCriterionEvidenceData,
          PrefetchHooks Function()
        > {
  $$LetterCriterionEvidenceTableTableManager(
    _$AppDatabase db,
    $LetterCriterionEvidenceTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LetterCriterionEvidenceTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LetterCriterionEvidenceTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LetterCriterionEvidenceTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<String> letterId = const Value.absent(),
                Value<String> criterion = const Value.absent(),
                Value<bool> passed = const Value.absent(),
                Value<String> source = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
              }) => LetterCriterionEvidenceCompanion(
                id: id,
                letterId: letterId,
                criterion: criterion,
                passed: passed,
                source: source,
                createdAt: createdAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                required String letterId,
                required String criterion,
                required bool passed,
                required String source,
                required DateTime createdAt,
              }) => LetterCriterionEvidenceCompanion.insert(
                id: id,
                letterId: letterId,
                criterion: criterion,
                passed: passed,
                source: source,
                createdAt: createdAt,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LetterCriterionEvidenceTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LetterCriterionEvidenceTable,
      LetterCriterionEvidenceData,
      $$LetterCriterionEvidenceTableFilterComposer,
      $$LetterCriterionEvidenceTableOrderingComposer,
      $$LetterCriterionEvidenceTableAnnotationComposer,
      $$LetterCriterionEvidenceTableCreateCompanionBuilder,
      $$LetterCriterionEvidenceTableUpdateCompanionBuilder,
      (
        LetterCriterionEvidenceData,
        BaseReferences<
          _$AppDatabase,
          $LetterCriterionEvidenceTable,
          LetterCriterionEvidenceData
        >,
      ),
      LetterCriterionEvidenceData,
      PrefetchHooks Function()
    >;
typedef $$ArcStateRowsTableCreateCompanionBuilder =
    ArcStateRowsCompanion Function({
      required String letterId,
      required bool active,
      required String step,
      Value<String?> targetCriterion,
      Value<String?> exerciseToRetry,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ArcStateRowsTableUpdateCompanionBuilder =
    ArcStateRowsCompanion Function({
      Value<String> letterId,
      Value<bool> active,
      Value<String> step,
      Value<String?> targetCriterion,
      Value<String?> exerciseToRetry,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ArcStateRowsTableFilterComposer
    extends Composer<_$AppDatabase, $ArcStateRowsTable> {
  $$ArcStateRowsTableFilterComposer({
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

  ColumnFilters<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get targetCriterion => $composableBuilder(
    column: $table.targetCriterion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get exerciseToRetry => $composableBuilder(
    column: $table.exerciseToRetry,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ArcStateRowsTableOrderingComposer
    extends Composer<_$AppDatabase, $ArcStateRowsTable> {
  $$ArcStateRowsTableOrderingComposer({
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

  ColumnOrderings<bool> get active => $composableBuilder(
    column: $table.active,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get step => $composableBuilder(
    column: $table.step,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get targetCriterion => $composableBuilder(
    column: $table.targetCriterion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get exerciseToRetry => $composableBuilder(
    column: $table.exerciseToRetry,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ArcStateRowsTableAnnotationComposer
    extends Composer<_$AppDatabase, $ArcStateRowsTable> {
  $$ArcStateRowsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get letterId =>
      $composableBuilder(column: $table.letterId, builder: (column) => column);

  GeneratedColumn<bool> get active =>
      $composableBuilder(column: $table.active, builder: (column) => column);

  GeneratedColumn<String> get step =>
      $composableBuilder(column: $table.step, builder: (column) => column);

  GeneratedColumn<String> get targetCriterion => $composableBuilder(
    column: $table.targetCriterion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get exerciseToRetry => $composableBuilder(
    column: $table.exerciseToRetry,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ArcStateRowsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ArcStateRowsTable,
          ArcStateRow,
          $$ArcStateRowsTableFilterComposer,
          $$ArcStateRowsTableOrderingComposer,
          $$ArcStateRowsTableAnnotationComposer,
          $$ArcStateRowsTableCreateCompanionBuilder,
          $$ArcStateRowsTableUpdateCompanionBuilder,
          (
            ArcStateRow,
            BaseReferences<_$AppDatabase, $ArcStateRowsTable, ArcStateRow>,
          ),
          ArcStateRow,
          PrefetchHooks Function()
        > {
  $$ArcStateRowsTableTableManager(_$AppDatabase db, $ArcStateRowsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ArcStateRowsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ArcStateRowsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ArcStateRowsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> letterId = const Value.absent(),
                Value<bool> active = const Value.absent(),
                Value<String> step = const Value.absent(),
                Value<String?> targetCriterion = const Value.absent(),
                Value<String?> exerciseToRetry = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ArcStateRowsCompanion(
                letterId: letterId,
                active: active,
                step: step,
                targetCriterion: targetCriterion,
                exerciseToRetry: exerciseToRetry,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String letterId,
                required bool active,
                required String step,
                Value<String?> targetCriterion = const Value.absent(),
                Value<String?> exerciseToRetry = const Value.absent(),
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ArcStateRowsCompanion.insert(
                letterId: letterId,
                active: active,
                step: step,
                targetCriterion: targetCriterion,
                exerciseToRetry: exerciseToRetry,
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

typedef $$ArcStateRowsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ArcStateRowsTable,
      ArcStateRow,
      $$ArcStateRowsTableFilterComposer,
      $$ArcStateRowsTableOrderingComposer,
      $$ArcStateRowsTableAnnotationComposer,
      $$ArcStateRowsTableCreateCompanionBuilder,
      $$ArcStateRowsTableUpdateCompanionBuilder,
      (
        ArcStateRow,
        BaseReferences<_$AppDatabase, $ArcStateRowsTable, ArcStateRow>,
      ),
      ArcStateRow,
      PrefetchHooks Function()
    >;
typedef $$ChildProfileMirrorTableCreateCompanionBuilder =
    ChildProfileMirrorCompanion Function({
      required String uid,
      required String strengths,
      required String struggles,
      required String perCriterion,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$ChildProfileMirrorTableUpdateCompanionBuilder =
    ChildProfileMirrorCompanion Function({
      Value<String> uid,
      Value<String> strengths,
      Value<String> struggles,
      Value<String> perCriterion,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$ChildProfileMirrorTableFilterComposer
    extends Composer<_$AppDatabase, $ChildProfileMirrorTable> {
  $$ChildProfileMirrorTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get strengths => $composableBuilder(
    column: $table.strengths,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get struggles => $composableBuilder(
    column: $table.struggles,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get perCriterion => $composableBuilder(
    column: $table.perCriterion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ChildProfileMirrorTableOrderingComposer
    extends Composer<_$AppDatabase, $ChildProfileMirrorTable> {
  $$ChildProfileMirrorTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get uid => $composableBuilder(
    column: $table.uid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get strengths => $composableBuilder(
    column: $table.strengths,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get struggles => $composableBuilder(
    column: $table.struggles,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get perCriterion => $composableBuilder(
    column: $table.perCriterion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ChildProfileMirrorTableAnnotationComposer
    extends Composer<_$AppDatabase, $ChildProfileMirrorTable> {
  $$ChildProfileMirrorTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get uid =>
      $composableBuilder(column: $table.uid, builder: (column) => column);

  GeneratedColumn<String> get strengths =>
      $composableBuilder(column: $table.strengths, builder: (column) => column);

  GeneratedColumn<String> get struggles =>
      $composableBuilder(column: $table.struggles, builder: (column) => column);

  GeneratedColumn<String> get perCriterion => $composableBuilder(
    column: $table.perCriterion,
    builder: (column) => column,
  );

  GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ChildProfileMirrorTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $ChildProfileMirrorTable,
          ChildProfileMirrorData,
          $$ChildProfileMirrorTableFilterComposer,
          $$ChildProfileMirrorTableOrderingComposer,
          $$ChildProfileMirrorTableAnnotationComposer,
          $$ChildProfileMirrorTableCreateCompanionBuilder,
          $$ChildProfileMirrorTableUpdateCompanionBuilder,
          (
            ChildProfileMirrorData,
            BaseReferences<
              _$AppDatabase,
              $ChildProfileMirrorTable,
              ChildProfileMirrorData
            >,
          ),
          ChildProfileMirrorData,
          PrefetchHooks Function()
        > {
  $$ChildProfileMirrorTableTableManager(
    _$AppDatabase db,
    $ChildProfileMirrorTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ChildProfileMirrorTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ChildProfileMirrorTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ChildProfileMirrorTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> uid = const Value.absent(),
                Value<String> strengths = const Value.absent(),
                Value<String> struggles = const Value.absent(),
                Value<String> perCriterion = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ChildProfileMirrorCompanion(
                uid: uid,
                strengths: strengths,
                struggles: struggles,
                perCriterion: perCriterion,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String uid,
                required String strengths,
                required String struggles,
                required String perCriterion,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ChildProfileMirrorCompanion.insert(
                uid: uid,
                strengths: strengths,
                struggles: struggles,
                perCriterion: perCriterion,
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

typedef $$ChildProfileMirrorTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $ChildProfileMirrorTable,
      ChildProfileMirrorData,
      $$ChildProfileMirrorTableFilterComposer,
      $$ChildProfileMirrorTableOrderingComposer,
      $$ChildProfileMirrorTableAnnotationComposer,
      $$ChildProfileMirrorTableCreateCompanionBuilder,
      $$ChildProfileMirrorTableUpdateCompanionBuilder,
      (
        ChildProfileMirrorData,
        BaseReferences<
          _$AppDatabase,
          $ChildProfileMirrorTable,
          ChildProfileMirrorData
        >,
      ),
      ChildProfileMirrorData,
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
  $$LetterGraphPositionTableTableManager get letterGraphPosition =>
      $$LetterGraphPositionTableTableManager(_db, _db.letterGraphPosition);
  $$LetterExerciseRepsTableTableManager get letterExerciseReps =>
      $$LetterExerciseRepsTableTableManager(_db, _db.letterExerciseReps);
  $$LetterCriterionEvidenceTableTableManager get letterCriterionEvidence =>
      $$LetterCriterionEvidenceTableTableManager(
        _db,
        _db.letterCriterionEvidence,
      );
  $$ArcStateRowsTableTableManager get arcStateRows =>
      $$ArcStateRowsTableTableManager(_db, _db.arcStateRows);
  $$ChildProfileMirrorTableTableManager get childProfileMirror =>
      $$ChildProfileMirrorTableTableManager(_db, _db.childProfileMirror);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The stable account-identity key for the local database — the uid for a real
/// (non-anonymous) account, else a shared `signed-out-guest` namespace.
///
/// This recomputes on every `authStateProvider` (`userChanges()`) emission, but
/// because it returns a plain String, Riverpod only NOTIFIES [appDatabase] when
/// the value actually changes (`==`). A plain token refresh that keeps the same
/// uid — e.g. the Forgot-PIN `reauthenticateWithPassword` step — therefore does
/// NOT churn the database. Watching `authStateProvider` directly here would
/// recreate (and `close()`) the DB on that refresh, tearing down the live DB and
/// its Drift `.watch()` streams mid-interaction and crashing the widget tree
/// (`_dependents.isEmpty`).

@ProviderFor(accountDatabaseId)
final accountDatabaseIdProvider = AccountDatabaseIdProvider._();

/// The stable account-identity key for the local database — the uid for a real
/// (non-anonymous) account, else a shared `signed-out-guest` namespace.
///
/// This recomputes on every `authStateProvider` (`userChanges()`) emission, but
/// because it returns a plain String, Riverpod only NOTIFIES [appDatabase] when
/// the value actually changes (`==`). A plain token refresh that keeps the same
/// uid — e.g. the Forgot-PIN `reauthenticateWithPassword` step — therefore does
/// NOT churn the database. Watching `authStateProvider` directly here would
/// recreate (and `close()`) the DB on that refresh, tearing down the live DB and
/// its Drift `.watch()` streams mid-interaction and crashing the widget tree
/// (`_dependents.isEmpty`).

final class AccountDatabaseIdProvider
    extends $FunctionalProvider<String, String, String>
    with $Provider<String> {
  /// The stable account-identity key for the local database — the uid for a real
  /// (non-anonymous) account, else a shared `signed-out-guest` namespace.
  ///
  /// This recomputes on every `authStateProvider` (`userChanges()`) emission, but
  /// because it returns a plain String, Riverpod only NOTIFIES [appDatabase] when
  /// the value actually changes (`==`). A plain token refresh that keeps the same
  /// uid — e.g. the Forgot-PIN `reauthenticateWithPassword` step — therefore does
  /// NOT churn the database. Watching `authStateProvider` directly here would
  /// recreate (and `close()`) the DB on that refresh, tearing down the live DB and
  /// its Drift `.watch()` streams mid-interaction and crashing the widget tree
  /// (`_dependents.isEmpty`).
  AccountDatabaseIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountDatabaseIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountDatabaseIdHash();

  @$internal
  @override
  $ProviderElement<String> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  String create(Ref ref) {
    return accountDatabaseId(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$accountDatabaseIdHash() => r'7e8de907b06144b0fe4ac83d56e68585d3ff8a51';

/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
/// Rebuilds ONLY when [accountDatabaseId] changes (account identity), never on a
/// bare token refresh — see that provider's note.

@ProviderFor(appDatabase)
final appDatabaseProvider = AppDatabaseProvider._();

/// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
/// Rebuilds ONLY when [accountDatabaseId] changes (account identity), never on a
/// bare token refresh — see that provider's note.

final class AppDatabaseProvider
    extends $FunctionalProvider<AppDatabase, AppDatabase, AppDatabase>
    with $Provider<AppDatabase> {
  /// Riverpod-codegen provider exposing the app database (Riverpod-only — D-11).
  /// Rebuilds ONLY when [accountDatabaseId] changes (account identity), never on a
  /// bare token refresh — see that provider's note.
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

String _$appDatabaseHash() => r'a2206ac0df3fd0f8d0da6932a63514cf295fa8f6';

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
