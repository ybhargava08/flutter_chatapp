/*import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import './DBConstants.dart';
import 'package:chatapp/model/ChatModel.dart';

class DBClass {
  static DBClass _dbClass;

  factory DBClass() => _dbClass ??= DBClass._();
  DBClass._();

  Database _database;

  initDB() async {
    var databasePath = await getDatabasesPath();

    String path = join(databasePath, 'chatapp.db');
    print('init db ' + path);
    _database = await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db.execute(
          'CREATE TABLE IF NOT EXISTS $TABLE_NAME (sysid integer primary key autoincrement,'+
                 '$ID TEXT NOT NULL UNIQUE,$FROM_ID TEXT,$TO_ID TEXT,$CHAT TEXT,' +
              '$CHAT_DATE TEXT,$IS_READ BIT)');
      print('table $TABLE_NAME created');
    });
  }

  insertInDB(ChatModel chat) async {
    if (_database == null) {
      await initDB();
    }
    print('inserting in db ' + chat.toString());
    await _database.rawQuery(
        'INSERT OR REPLACE INTO $TABLE_NAME($ID,$FROM_ID,$TO_ID,$CHAT,$CHAT_DATE,$IS_READ) ' +
            'VALUES(?,?,?,?,?,?)',
        [
          chat.id,
          chat.fromUserId,
          chat.toUserId,
          chat.chat,
          chat.chatDate,
          (chat.isRead) ? 1 : 0
        ]);
  }

 Future<List> getLastChatWithUnreadCount(String id) async {
        if (_database == null) {
           await initDB();
        }
       List<Map> result = await _database.rawQuery('select $CHAT,$CHAT_DATE,$IS_READ,(select count(*) '+
         'from $TABLE_NAME WHERE $IS_READ = 0 AND $FROM_ID = ?) as unread_count from $TABLE_NAME where '
         +'sysid = (select max(sysid) from $TABLE_NAME where $FROM_ID = ? OR $TO_ID = ?)',[id,id,id]);
             print('got result for getLastChatWithUnreadCount id '+id + '  '+result.toString());
                return result;        
  }

  Future<List<ChatModel>> getAllChatsFromDBForUser(String userId) async {
    if (_database == null) {
      await initDB();
    }
    print('getAllChatsFromDBForUser ' + userId);
    List<Map> result = await _database.query(TABLE_NAME,
        columns: [ID, FROM_ID, TO_ID, CHAT, CHAT_DATE, IS_READ],
        where: '$TO_ID = ? OR $FROM_ID = ?',
        whereArgs: [userId, userId]);
    if (result.length > 0) {
      print('getAllChatsFromDBForUser result ' + result.toString());
      return result.map((item) => ChatModel.fromMap(item)).toList();
    }
    print('getAllChatsFromDBForUser result null');
    return [];
  }

  /*markAllChatsRead(String userId) async{
         if(_database == null) {
            await initDB();
         }    
      int count = await _database.rawUpdate('UPDATE $TABLE_NAME SET $IS_READ = 1 WHERE $FROM_ID = ? OR $TO_ID = ?',[userId,userId]);
      print('records marked as read '+count.toString());
  } */

  closeDB() {
    if (null != _database) {
      _database.close();
    }
  }

  deleteDB() async {
    if (_database == null) {
      var databasePath = await getDatabasesPath();

      String path = join(databasePath, 'chatapp.db');

      print('deleting db from path ' + path);
      deleteDatabase(path);
    }
  }
}*/
