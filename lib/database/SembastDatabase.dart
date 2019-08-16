import 'dart:async';
import 'package:chatapp/firebase/FirebaseStorageUtil.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart';

class SembastDatabase {
  
  static SembastDatabase _sembastDatabase;

  factory SembastDatabase() => _sembastDatabase ??= SembastDatabase._();

  SembastDatabase._();

  static Completer<Database> _dbCompleter;

  

  Future<Database> getDatabase() async {
    if (_dbCompleter == null) {
      _dbCompleter = Completer();
      _openDatabase();
    }

    return _dbCompleter.future;
  }

  Future _openDatabase() async {
    final docDir = await getApplicationDocumentsDirectory();

    final dbPath = join(docDir.path, 'chatapp.db');

    await FirebaseStorageUtil().downloadLocalDB(dbPath);

    final database = await databaseFactoryIo.openDatabase(dbPath);

    print('created / opened database at path '+dbPath.toString());

    _dbCompleter.complete(database);
  }
}
