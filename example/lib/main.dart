import 'package:drift/native.dart';
import 'package:drift_local_storage_inspector/drift_local_storage_inspector.dart';
import 'package:flutter/material.dart';
import 'package:storage_inspector/storage_inspector.dart';

import 'db/driftdb.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final driver = StorageServerDriver(
    bundleId: 'com.example.test',
    icon: '<some icon>',
  );

  final db = NativeDatabase.memory();
  final driftDb = MyDatabase(db);

  await driftDb.customSelect("SELECT sql from sqlite_schema").get();

  final sqlServer = DriftSQLDatabaseServer(
    id: "1",
    name: "SQL server",
    database: driftDb,
  );

  driver.addSQLServer(sqlServer);

  await driver.start(paused: false);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text(
              'You have pushed the button this many times:',
            ),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
