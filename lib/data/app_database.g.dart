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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppSettingsTable appSettings = $AppSettingsTable(this);
  late final $LetterMasteryTable letterMastery = $LetterMasteryTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appSettings,
    letterMastery,
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppSettingsTableTableManager get appSettings =>
      $$AppSettingsTableTableManager(_db, _db.appSettings);
  $$LetterMasteryTableTableManager get letterMastery =>
      $$LetterMasteryTableTableManager(_db, _db.letterMastery);
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
