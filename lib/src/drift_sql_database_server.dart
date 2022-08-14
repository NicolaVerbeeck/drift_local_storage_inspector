import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:storage_inspector/storage_inspector.dart';

/// Sorts tables based on their name
void _defaultTableSorter(List<SQLTableDefinition> toSort) {
  toSort.sort((a, b) => a.name.compareTo(b.name));
}

/// [SQLDatabaseServer] implementation that wraps
/// drift's [GeneratedDatabase]
class DriftSQLDatabaseServer implements SQLDatabaseServer {
  final GeneratedDatabase _database;

  @override
  final String? icon;

  @override
  final String id;

  @override
  final String name;

  @override
  final Future<List<SQLTableDefinition>> tables;

  @override
  final Future<DateTimeFormat> dateTimeFormat;

  @override
  final Future<String> schema;

  @override
  Future<int?> get schemaVersion => SynchronousFuture(_database.schemaVersion);

  DriftSQLDatabaseServer({
    required this.id,
    required this.name,
    required GeneratedDatabase database,
    this.icon,
    void Function(List<SQLTableDefinition>)? tableSorter = _defaultTableSorter,
  })  : _database = database,
        schema = _buildSchema(database),
        tables = SynchronousFuture(_buildTables(database, tableSorter)),
        dateTimeFormat = SynchronousFuture(const DateTimeFormat(
          accuracyInMicroSeconds: 1000000,
          timezoneOffsetMilliseconds: 0,
        ));

  @override
  Future<QueryResult> query(
    String query,
    List<ValueWithType> variables,
  ) async {
    final select = _database.customSelect(
      query,
      variables: variables.map(_mapVariable).toList(),
    );
    final data = await select.get();

    final columns = <String>{};
    final rows = data.map((row) {
      final rowItem = <String, dynamic>{};
      row.data.forEach((key, dynamic value) {
        columns.add(key);
        rowItem[key] = value;
      });
      return rowItem;
    }).toList();
    return QueryResult(
      columns: columns.toList(),
      rows: rows,
    );
  }

  @override
  Future<int> update(
    String query, {
    required List<String> affectedTables,
    required List<ValueWithType> variables,
  }) async {
    final numUpdated = await _database.customUpdate(
      query,
      updates: _database.allTables
          .where((element) => affectedTables.contains(element.actualTableName))
          .toSet(),
      variables: variables.map(_mapVariable).toList(),
    );
    return numUpdated;
  }
}

List<SQLTableDefinition> _buildTables(
  GeneratedDatabase database,
  void Function(List<SQLTableDefinition>)? tableSorter,
) {
  final tables = database.allTables.map((tableInfo) {
    final extensions = <SQLTableExtension>[];
    if (tableInfo.withoutRowId) {
      extensions.add(SQLTableExtension.withoutRowId);
    }
    final columns = tableInfo.$columns.map((column) {
      return SQLColumnDefinition(
        name: column.$name,
        optional: !column.requiredDuringInsert,
        type: _makeType(column),
        nullable: column.$nullable,
        autoIncrement: column.hasAutoIncrement,
        defaultValueExpression: column.defaultValue?.writeAsString(database),
      );
    }).toList();
    return SQLTableDefinition(
      name: tableInfo.actualTableName,
      extensions: extensions,
      columns: columns,
      primaryKey: tableInfo.$primaryKey.map((column) => column.$name).toList(),
    );
  }).toList();
  if (tableSorter != null) {
    tableSorter(tables);
  }
  return tables;
}

Future<String> _buildSchema(GeneratedDatabase database) async {
  return database.customSelect('SELECT sql from sqlite_schema').get().then(
    (rows) {
      final buffer = StringBuffer();
      for (final row in rows) {
        if (buffer.isNotEmpty) buffer.write('\n');
        buffer
          ..write(row.data['sql'].toString())
          ..write(';');
      }
      return buffer.toString();
    },
  );
}

SQLDataType _makeType(
  GeneratedColumn<dynamic> column,
) {
  final type = column.type;
  switch (type) {
    case DriftSqlType.bool:
      return SQLDataType.boolean;
    case DriftSqlType.string:
      return SQLDataType.text;
    case DriftSqlType.bigInt:
      return SQLDataType.integer;
    case DriftSqlType.int:
      return SQLDataType.integer;
    case DriftSqlType.dateTime:
      return SQLDataType.datetime;
    case DriftSqlType.blob:
      return SQLDataType.blob;
    case DriftSqlType.double:
      return SQLDataType.real;
  }
}

Variable<Object> _mapVariable(
  ValueWithType e,
) {
  if (e.value == null) {
    return const Variable<Object>(null);
  }
  switch (e.type) {
    case StorageType.string:
      return Variable.withString(e.value as String);
    case StorageType.integer:
      return Variable.withInt(e.value as int);
    case StorageType.double:
      return Variable.withReal(e.value as double);
    case StorageType.datetime:
      return Variable.withDateTime(e.value as DateTime);
    case StorageType.binary:
      return Variable.withBlob(e.value as Uint8List);
    case StorageType.boolean:
      return Variable.withBool(e.value as bool);
    case StorageType.stringList:
      throw ArgumentError('String lists are not supported by SQL');
  }
}

extension _ExpressionExtension on Expression {
  String writeAsString(DatabaseConnectionUser db) {
    final context = GenerationContext.fromDb(db);
    writeInto(context);
    return context.buffer.toString();
  }
}
