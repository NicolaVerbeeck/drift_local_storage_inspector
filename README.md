# SQL file storage inspector for drift databases

[![pub package](https://img.shields.io/pub/v/drift_local_storage_inspector.svg?color=blue)](https://pub.dev/packages/drift_local_storage_inspector)
[![pub points](https://badges.bar/sentry/pub%20points)](https://pub.dev/packages/drift_local_storage_inspector/score)
[![plugin_badge](https://img.shields.io/jetbrains/plugin/v/18231-local-storage-inspector?color=blue&label=IntelliJ%20Plugin)](https://plugins.jetbrains.com/plugin/18231-local-storage-inspector)

Inspector server interface for [drift](https://pub.dev/packages/drift) databases.

Allows for SQL inspection of drift databases with the [local storage inspector](https://pub.dev/packages/storage_inspector) package and associated
[IntelliJ plugin](https://plugins.jetbrains.com/plugin/18231-local-storage-inspector)

### Example
```dart
final driver = StorageServerDriver(
  bundleId: 'com.example.test',
  icon: '<some icon>',
);

final db = NativeDatabase.memory();
final driftDb = MyDatabase(db);

final sqlServer = DriftSQLDatabaseServer(
  id: "1",
  name: "SQL server",
  database: driftDb,
);

driver.addSQLServer(sqlServer);

await driver.start(paused: false);
```