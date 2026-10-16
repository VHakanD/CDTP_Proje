// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $TestReportsTable extends TestReports
    with TableInfo<$TestReportsTable, ReportRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TestReportsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _seqMeta = const VerificationMeta('seq');
  @override
  late final GeneratedColumn<int> seq = GeneratedColumn<int>(
      'seq', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _testIdMeta = const VerificationMeta('testId');
  @override
  late final GeneratedColumn<String> testId = GeneratedColumn<String>(
      'test_id', aliasedName, false,
      type: DriftSqlType.string,
      requiredDuringInsert: true,
      defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'));
  static const VerificationMeta _taskMeta = const VerificationMeta('task');
  @override
  late final GeneratedColumn<String> task = GeneratedColumn<String>(
      'task', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _verdictMeta =
      const VerificationMeta('verdict');
  @override
  late final GeneratedColumn<String> verdict = GeneratedColumn<String>(
      'verdict', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _startedAtMsMeta =
      const VerificationMeta('startedAtMs');
  @override
  late final GeneratedColumn<int> startedAtMs = GeneratedColumn<int>(
      'started_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _durationMsMeta =
      const VerificationMeta('durationMs');
  @override
  late final GeneratedColumn<int> durationMs = GeneratedColumn<int>(
      'duration_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _prevHashMeta =
      const VerificationMeta('prevHash');
  @override
  late final GeneratedColumn<String> prevHash = GeneratedColumn<String>(
      'prev_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _chainHashMeta =
      const VerificationMeta('chainHash');
  @override
  late final GeneratedColumn<String> chainHash = GeneratedColumn<String>(
      'chain_hash', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMsMeta =
      const VerificationMeta('createdAtMs');
  @override
  late final GeneratedColumn<int> createdAtMs = GeneratedColumn<int>(
      'created_at_ms', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        seq,
        testId,
        task,
        verdict,
        startedAtMs,
        durationMs,
        payloadJson,
        prevHash,
        chainHash,
        createdAtMs
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'test_reports';
  @override
  VerificationContext validateIntegrity(Insertable<ReportRow> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('seq')) {
      context.handle(
          _seqMeta, seq.isAcceptableOrUnknown(data['seq']!, _seqMeta));
    } else if (isInserting) {
      context.missing(_seqMeta);
    }
    if (data.containsKey('test_id')) {
      context.handle(_testIdMeta,
          testId.isAcceptableOrUnknown(data['test_id']!, _testIdMeta));
    } else if (isInserting) {
      context.missing(_testIdMeta);
    }
    if (data.containsKey('task')) {
      context.handle(
          _taskMeta, task.isAcceptableOrUnknown(data['task']!, _taskMeta));
    } else if (isInserting) {
      context.missing(_taskMeta);
    }
    if (data.containsKey('verdict')) {
      context.handle(_verdictMeta,
          verdict.isAcceptableOrUnknown(data['verdict']!, _verdictMeta));
    } else if (isInserting) {
      context.missing(_verdictMeta);
    }
    if (data.containsKey('started_at_ms')) {
      context.handle(
          _startedAtMsMeta,
          startedAtMs.isAcceptableOrUnknown(
              data['started_at_ms']!, _startedAtMsMeta));
    } else if (isInserting) {
      context.missing(_startedAtMsMeta);
    }
    if (data.containsKey('duration_ms')) {
      context.handle(
          _durationMsMeta,
          durationMs.isAcceptableOrUnknown(
              data['duration_ms']!, _durationMsMeta));
    } else if (isInserting) {
      context.missing(_durationMsMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('prev_hash')) {
      context.handle(_prevHashMeta,
          prevHash.isAcceptableOrUnknown(data['prev_hash']!, _prevHashMeta));
    } else if (isInserting) {
      context.missing(_prevHashMeta);
    }
    if (data.containsKey('chain_hash')) {
      context.handle(_chainHashMeta,
          chainHash.isAcceptableOrUnknown(data['chain_hash']!, _chainHashMeta));
    } else if (isInserting) {
      context.missing(_chainHashMeta);
    }
    if (data.containsKey('created_at_ms')) {
      context.handle(
          _createdAtMsMeta,
          createdAtMs.isAcceptableOrUnknown(
              data['created_at_ms']!, _createdAtMsMeta));
    } else if (isInserting) {
      context.missing(_createdAtMsMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ReportRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReportRow(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      seq: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}seq'])!,
      testId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}test_id'])!,
      task: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}task'])!,
      verdict: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}verdict'])!,
      startedAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at_ms'])!,
      durationMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_ms'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      prevHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}prev_hash'])!,
      chainHash: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}chain_hash'])!,
      createdAtMs: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}created_at_ms'])!,
    );
  }

  @override
  $TestReportsTable createAlias(String alias) {
    return $TestReportsTable(attachedDatabase, alias);
  }
}

class ReportRow extends DataClass implements Insertable<ReportRow> {
  final int id;

  /// Zincir sira numarasi (1, 2, 3 ...).
  final int seq;
  final String testId;

  /// TestTask.name (staticBalance, guidance, charging, integrated)
  final String task;

  /// Verdict.name (passed, failed, incomplete)
  final String verdict;
  final int startedAtMs;
  final int durationMs;

  /// Raporun tum icerigi (kanonik JSON).
  final String payloadJson;
  final String prevHash;
  final String chainHash;
  final int createdAtMs;
  const ReportRow(
      {required this.id,
      required this.seq,
      required this.testId,
      required this.task,
      required this.verdict,
      required this.startedAtMs,
      required this.durationMs,
      required this.payloadJson,
      required this.prevHash,
      required this.chainHash,
      required this.createdAtMs});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['seq'] = Variable<int>(seq);
    map['test_id'] = Variable<String>(testId);
    map['task'] = Variable<String>(task);
    map['verdict'] = Variable<String>(verdict);
    map['started_at_ms'] = Variable<int>(startedAtMs);
    map['duration_ms'] = Variable<int>(durationMs);
    map['payload_json'] = Variable<String>(payloadJson);
    map['prev_hash'] = Variable<String>(prevHash);
    map['chain_hash'] = Variable<String>(chainHash);
    map['created_at_ms'] = Variable<int>(createdAtMs);
    return map;
  }

  TestReportsCompanion toCompanion(bool nullToAbsent) {
    return TestReportsCompanion(
      id: Value(id),
      seq: Value(seq),
      testId: Value(testId),
      task: Value(task),
      verdict: Value(verdict),
      startedAtMs: Value(startedAtMs),
      durationMs: Value(durationMs),
      payloadJson: Value(payloadJson),
      prevHash: Value(prevHash),
      chainHash: Value(chainHash),
      createdAtMs: Value(createdAtMs),
    );
  }

  factory ReportRow.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReportRow(
      id: serializer.fromJson<int>(json['id']),
      seq: serializer.fromJson<int>(json['seq']),
      testId: serializer.fromJson<String>(json['testId']),
      task: serializer.fromJson<String>(json['task']),
      verdict: serializer.fromJson<String>(json['verdict']),
      startedAtMs: serializer.fromJson<int>(json['startedAtMs']),
      durationMs: serializer.fromJson<int>(json['durationMs']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      prevHash: serializer.fromJson<String>(json['prevHash']),
      chainHash: serializer.fromJson<String>(json['chainHash']),
      createdAtMs: serializer.fromJson<int>(json['createdAtMs']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'seq': serializer.toJson<int>(seq),
      'testId': serializer.toJson<String>(testId),
      'task': serializer.toJson<String>(task),
      'verdict': serializer.toJson<String>(verdict),
      'startedAtMs': serializer.toJson<int>(startedAtMs),
      'durationMs': serializer.toJson<int>(durationMs),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'prevHash': serializer.toJson<String>(prevHash),
      'chainHash': serializer.toJson<String>(chainHash),
      'createdAtMs': serializer.toJson<int>(createdAtMs),
    };
  }

  ReportRow copyWith(
          {int? id,
          int? seq,
          String? testId,
          String? task,
          String? verdict,
          int? startedAtMs,
          int? durationMs,
          String? payloadJson,
          String? prevHash,
          String? chainHash,
          int? createdAtMs}) =>
      ReportRow(
        id: id ?? this.id,
        seq: seq ?? this.seq,
        testId: testId ?? this.testId,
        task: task ?? this.task,
        verdict: verdict ?? this.verdict,
        startedAtMs: startedAtMs ?? this.startedAtMs,
        durationMs: durationMs ?? this.durationMs,
        payloadJson: payloadJson ?? this.payloadJson,
        prevHash: prevHash ?? this.prevHash,
        chainHash: chainHash ?? this.chainHash,
        createdAtMs: createdAtMs ?? this.createdAtMs,
      );
  ReportRow copyWithCompanion(TestReportsCompanion data) {
    return ReportRow(
      id: data.id.present ? data.id.value : this.id,
      seq: data.seq.present ? data.seq.value : this.seq,
      testId: data.testId.present ? data.testId.value : this.testId,
      task: data.task.present ? data.task.value : this.task,
      verdict: data.verdict.present ? data.verdict.value : this.verdict,
      startedAtMs:
          data.startedAtMs.present ? data.startedAtMs.value : this.startedAtMs,
      durationMs:
          data.durationMs.present ? data.durationMs.value : this.durationMs,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      prevHash: data.prevHash.present ? data.prevHash.value : this.prevHash,
      chainHash: data.chainHash.present ? data.chainHash.value : this.chainHash,
      createdAtMs:
          data.createdAtMs.present ? data.createdAtMs.value : this.createdAtMs,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReportRow(')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('testId: $testId, ')
          ..write('task: $task, ')
          ..write('verdict: $verdict, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('prevHash: $prevHash, ')
          ..write('chainHash: $chainHash, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, seq, testId, task, verdict, startedAtMs,
      durationMs, payloadJson, prevHash, chainHash, createdAtMs);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReportRow &&
          other.id == this.id &&
          other.seq == this.seq &&
          other.testId == this.testId &&
          other.task == this.task &&
          other.verdict == this.verdict &&
          other.startedAtMs == this.startedAtMs &&
          other.durationMs == this.durationMs &&
          other.payloadJson == this.payloadJson &&
          other.prevHash == this.prevHash &&
          other.chainHash == this.chainHash &&
          other.createdAtMs == this.createdAtMs);
}

class TestReportsCompanion extends UpdateCompanion<ReportRow> {
  final Value<int> id;
  final Value<int> seq;
  final Value<String> testId;
  final Value<String> task;
  final Value<String> verdict;
  final Value<int> startedAtMs;
  final Value<int> durationMs;
  final Value<String> payloadJson;
  final Value<String> prevHash;
  final Value<String> chainHash;
  final Value<int> createdAtMs;
  const TestReportsCompanion({
    this.id = const Value.absent(),
    this.seq = const Value.absent(),
    this.testId = const Value.absent(),
    this.task = const Value.absent(),
    this.verdict = const Value.absent(),
    this.startedAtMs = const Value.absent(),
    this.durationMs = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.prevHash = const Value.absent(),
    this.chainHash = const Value.absent(),
    this.createdAtMs = const Value.absent(),
  });
  TestReportsCompanion.insert({
    this.id = const Value.absent(),
    required int seq,
    required String testId,
    required String task,
    required String verdict,
    required int startedAtMs,
    required int durationMs,
    required String payloadJson,
    required String prevHash,
    required String chainHash,
    required int createdAtMs,
  })  : seq = Value(seq),
        testId = Value(testId),
        task = Value(task),
        verdict = Value(verdict),
        startedAtMs = Value(startedAtMs),
        durationMs = Value(durationMs),
        payloadJson = Value(payloadJson),
        prevHash = Value(prevHash),
        chainHash = Value(chainHash),
        createdAtMs = Value(createdAtMs);
  static Insertable<ReportRow> custom({
    Expression<int>? id,
    Expression<int>? seq,
    Expression<String>? testId,
    Expression<String>? task,
    Expression<String>? verdict,
    Expression<int>? startedAtMs,
    Expression<int>? durationMs,
    Expression<String>? payloadJson,
    Expression<String>? prevHash,
    Expression<String>? chainHash,
    Expression<int>? createdAtMs,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (seq != null) 'seq': seq,
      if (testId != null) 'test_id': testId,
      if (task != null) 'task': task,
      if (verdict != null) 'verdict': verdict,
      if (startedAtMs != null) 'started_at_ms': startedAtMs,
      if (durationMs != null) 'duration_ms': durationMs,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (prevHash != null) 'prev_hash': prevHash,
      if (chainHash != null) 'chain_hash': chainHash,
      if (createdAtMs != null) 'created_at_ms': createdAtMs,
    });
  }

  TestReportsCompanion copyWith(
      {Value<int>? id,
      Value<int>? seq,
      Value<String>? testId,
      Value<String>? task,
      Value<String>? verdict,
      Value<int>? startedAtMs,
      Value<int>? durationMs,
      Value<String>? payloadJson,
      Value<String>? prevHash,
      Value<String>? chainHash,
      Value<int>? createdAtMs}) {
    return TestReportsCompanion(
      id: id ?? this.id,
      seq: seq ?? this.seq,
      testId: testId ?? this.testId,
      task: task ?? this.task,
      verdict: verdict ?? this.verdict,
      startedAtMs: startedAtMs ?? this.startedAtMs,
      durationMs: durationMs ?? this.durationMs,
      payloadJson: payloadJson ?? this.payloadJson,
      prevHash: prevHash ?? this.prevHash,
      chainHash: chainHash ?? this.chainHash,
      createdAtMs: createdAtMs ?? this.createdAtMs,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (seq.present) {
      map['seq'] = Variable<int>(seq.value);
    }
    if (testId.present) {
      map['test_id'] = Variable<String>(testId.value);
    }
    if (task.present) {
      map['task'] = Variable<String>(task.value);
    }
    if (verdict.present) {
      map['verdict'] = Variable<String>(verdict.value);
    }
    if (startedAtMs.present) {
      map['started_at_ms'] = Variable<int>(startedAtMs.value);
    }
    if (durationMs.present) {
      map['duration_ms'] = Variable<int>(durationMs.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (prevHash.present) {
      map['prev_hash'] = Variable<String>(prevHash.value);
    }
    if (chainHash.present) {
      map['chain_hash'] = Variable<String>(chainHash.value);
    }
    if (createdAtMs.present) {
      map['created_at_ms'] = Variable<int>(createdAtMs.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TestReportsCompanion(')
          ..write('id: $id, ')
          ..write('seq: $seq, ')
          ..write('testId: $testId, ')
          ..write('task: $task, ')
          ..write('verdict: $verdict, ')
          ..write('startedAtMs: $startedAtMs, ')
          ..write('durationMs: $durationMs, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('prevHash: $prevHash, ')
          ..write('chainHash: $chainHash, ')
          ..write('createdAtMs: $createdAtMs')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $TestReportsTable testReports = $TestReportsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [testReports];
}

typedef $$TestReportsTableCreateCompanionBuilder = TestReportsCompanion
    Function({
  Value<int> id,
  required int seq,
  required String testId,
  required String task,
  required String verdict,
  required int startedAtMs,
  required int durationMs,
  required String payloadJson,
  required String prevHash,
  required String chainHash,
  required int createdAtMs,
});
typedef $$TestReportsTableUpdateCompanionBuilder = TestReportsCompanion
    Function({
  Value<int> id,
  Value<int> seq,
  Value<String> testId,
  Value<String> task,
  Value<String> verdict,
  Value<int> startedAtMs,
  Value<int> durationMs,
  Value<String> payloadJson,
  Value<String> prevHash,
  Value<String> chainHash,
  Value<int> createdAtMs,
});

class $$TestReportsTableFilterComposer
    extends Composer<_$AppDatabase, $TestReportsTable> {
  $$TestReportsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get testId => $composableBuilder(
      column: $table.testId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get task => $composableBuilder(
      column: $table.task, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAtMs => $composableBuilder(
      column: $table.startedAtMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get prevHash => $composableBuilder(
      column: $table.prevHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get chainHash => $composableBuilder(
      column: $table.chainHash, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnFilters(column));
}

class $$TestReportsTableOrderingComposer
    extends Composer<_$AppDatabase, $TestReportsTable> {
  $$TestReportsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get seq => $composableBuilder(
      column: $table.seq, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get testId => $composableBuilder(
      column: $table.testId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get task => $composableBuilder(
      column: $table.task, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get verdict => $composableBuilder(
      column: $table.verdict, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAtMs => $composableBuilder(
      column: $table.startedAtMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get prevHash => $composableBuilder(
      column: $table.prevHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get chainHash => $composableBuilder(
      column: $table.chainHash, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => ColumnOrderings(column));
}

class $$TestReportsTableAnnotationComposer
    extends Composer<_$AppDatabase, $TestReportsTable> {
  $$TestReportsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get seq =>
      $composableBuilder(column: $table.seq, builder: (column) => column);

  GeneratedColumn<String> get testId =>
      $composableBuilder(column: $table.testId, builder: (column) => column);

  GeneratedColumn<String> get task =>
      $composableBuilder(column: $table.task, builder: (column) => column);

  GeneratedColumn<String> get verdict =>
      $composableBuilder(column: $table.verdict, builder: (column) => column);

  GeneratedColumn<int> get startedAtMs => $composableBuilder(
      column: $table.startedAtMs, builder: (column) => column);

  GeneratedColumn<int> get durationMs => $composableBuilder(
      column: $table.durationMs, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<String> get prevHash =>
      $composableBuilder(column: $table.prevHash, builder: (column) => column);

  GeneratedColumn<String> get chainHash =>
      $composableBuilder(column: $table.chainHash, builder: (column) => column);

  GeneratedColumn<int> get createdAtMs => $composableBuilder(
      column: $table.createdAtMs, builder: (column) => column);
}

class $$TestReportsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $TestReportsTable,
    ReportRow,
    $$TestReportsTableFilterComposer,
    $$TestReportsTableOrderingComposer,
    $$TestReportsTableAnnotationComposer,
    $$TestReportsTableCreateCompanionBuilder,
    $$TestReportsTableUpdateCompanionBuilder,
    (ReportRow, BaseReferences<_$AppDatabase, $TestReportsTable, ReportRow>),
    ReportRow,
    PrefetchHooks Function()> {
  $$TestReportsTableTableManager(_$AppDatabase db, $TestReportsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TestReportsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TestReportsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TestReportsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<int> seq = const Value.absent(),
            Value<String> testId = const Value.absent(),
            Value<String> task = const Value.absent(),
            Value<String> verdict = const Value.absent(),
            Value<int> startedAtMs = const Value.absent(),
            Value<int> durationMs = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<String> prevHash = const Value.absent(),
            Value<String> chainHash = const Value.absent(),
            Value<int> createdAtMs = const Value.absent(),
          }) =>
              TestReportsCompanion(
            id: id,
            seq: seq,
            testId: testId,
            task: task,
            verdict: verdict,
            startedAtMs: startedAtMs,
            durationMs: durationMs,
            payloadJson: payloadJson,
            prevHash: prevHash,
            chainHash: chainHash,
            createdAtMs: createdAtMs,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required int seq,
            required String testId,
            required String task,
            required String verdict,
            required int startedAtMs,
            required int durationMs,
            required String payloadJson,
            required String prevHash,
            required String chainHash,
            required int createdAtMs,
          }) =>
              TestReportsCompanion.insert(
            id: id,
            seq: seq,
            testId: testId,
            task: task,
            verdict: verdict,
            startedAtMs: startedAtMs,
            durationMs: durationMs,
            payloadJson: payloadJson,
            prevHash: prevHash,
            chainHash: chainHash,
            createdAtMs: createdAtMs,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$TestReportsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $TestReportsTable,
    ReportRow,
    $$TestReportsTableFilterComposer,
    $$TestReportsTableOrderingComposer,
    $$TestReportsTableAnnotationComposer,
    $$TestReportsTableCreateCompanionBuilder,
    $$TestReportsTableUpdateCompanionBuilder,
    (ReportRow, BaseReferences<_$AppDatabase, $TestReportsTable, ReportRow>),
    ReportRow,
    PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$TestReportsTableTableManager get testReports =>
      $$TestReportsTableTableManager(_db, _db.testReports);
}
