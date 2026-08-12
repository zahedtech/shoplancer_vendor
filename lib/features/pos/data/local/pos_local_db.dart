import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Local SQLite database used by the desktop POS build to work fully
/// offline: it caches the product catalog for browsing/search/scan while
/// offline, and keeps a durable queue of write actions (place order, update
/// price/stock, ...) that failed to reach the server so they can be
/// replayed automatically once connectivity returns.
///
/// Only used on desktop (Windows/macOS) targets. Mobile keeps its existing
/// online-only behaviour untouched.
class PosLocalDb {
  PosLocalDb._();
  static final PosLocalDb instance = PosLocalDb._();

  Database? _db;

  bool get isSupportedPlatform =>
      !kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux);

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    // sqflite on desktop needs the ffi loader instead of the platform channel.
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;

    final Directory dir = await getApplicationSupportDirectory();
    final String dbPath = p.join(dir.path, 'shoplancer_pos_desktop.db');

    return databaseFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE cached_products (
              id INTEGER PRIMARY KEY,
              name TEXT,
              price REAL,
              stock INTEGER,
              category_id INTEGER,
              raw_json TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE sync_queue (
              id TEXT PRIMARY KEY,
              type TEXT NOT NULL,
              endpoint TEXT NOT NULL,
              method TEXT NOT NULL,
              body TEXT NOT NULL,
              created_at TEXT NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending',
              retries INTEGER NOT NULL DEFAULT 0,
              last_error TEXT
            )
          ''');

          await db.execute('''
            CREATE TABLE local_orders (
              id TEXT PRIMARY KEY,
              queue_id TEXT NOT NULL,
              customer_label TEXT,
              total REAL NOT NULL,
              item_count INTEGER NOT NULL,
              status TEXT NOT NULL DEFAULT 'pending_sync',
              created_at TEXT NOT NULL,
              synced_order_id TEXT
            )
          ''');
        },
      ),
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
