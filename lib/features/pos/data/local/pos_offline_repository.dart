import 'dart:convert';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:uuid/uuid.dart';

import 'pos_local_db.dart';

/// Types of write actions the desktop POS may need to queue while offline.
enum PosQueueActionType { placeOrder, updatePrice, updateStock }

extension on PosQueueActionType {
  String get value => switch (this) {
    PosQueueActionType.placeOrder => 'place_order',
    PosQueueActionType.updatePrice => 'update_price',
    PosQueueActionType.updateStock => 'update_stock',
  };
}

class PosQueueItem {
  final String id;
  final String type;
  final String endpoint;
  final String method;
  final Map<String, dynamic> body;
  final String createdAt;
  final String status;
  final int retries;
  final String? lastError;

  PosQueueItem({
    required this.id,
    required this.type,
    required this.endpoint,
    required this.method,
    required this.body,
    required this.createdAt,
    required this.status,
    required this.retries,
    this.lastError,
  });

  factory PosQueueItem.fromRow(Map<String, Object?> row) => PosQueueItem(
    id: row['id'] as String,
    type: row['type'] as String,
    endpoint: row['endpoint'] as String,
    method: row['method'] as String,
    body: jsonDecode(row['body'] as String) as Map<String, dynamic>,
    createdAt: row['created_at'] as String,
    status: row['status'] as String,
    retries: row['retries'] as int,
    lastError: row['last_error'] as String?,
  );
}

/// Local persistence for the desktop POS offline mode: product cache and a
/// durable write-action queue. Pure data access — no HTTP calls live here so
/// this stays independent from [ApiClient] and easy to unit test.
class PosOfflineRepository {
  PosOfflineRepository._();
  static final PosOfflineRepository instance = PosOfflineRepository._();

  final Uuid _uuid = const Uuid();

  Future<Database> get _db => PosLocalDb.instance.database;

  // ---- Product cache ----------------------------------------------------

  Future<void> cacheProducts(List<Map<String, dynamic>> items) async {
    final db = await _db;
    final batch = db.batch();
    final String now = DateTime.now().toIso8601String();
    for (final item in items) {
      final id = item['id'];
      if (id == null) continue;
      batch.insert('cached_products', {
        'id': id,
        'name': item['name']?.toString(),
        'price': (item['price'] is num) ? item['price'] : null,
        'stock': (item['stock'] is num) ? item['stock'] : null,
        'category_id': (item['category_id'] is num)
            ? item['category_id']
            : null,
        'raw_json': jsonEncode(item),
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  Future<List<Map<String, dynamic>>> getCachedProducts({String? search}) async {
    final db = await _db;
    final rows = await db.query(
      'cached_products',
      where: search != null && search.isNotEmpty ? 'name LIKE ?' : null,
      whereArgs: search != null && search.isNotEmpty ? ['%$search%'] : null,
      orderBy: 'name COLLATE NOCASE ASC',
    );
    return rows
        .map((r) => jsonDecode(r['raw_json'] as String) as Map<String, dynamic>)
        .toList();
  }

  /// Applies a locally-queued price/stock change on top of the cached copy
  /// immediately, so the cashier UI reflects the edit even before the sync
  /// round-trips to the server.
  Future<void> patchCachedProduct(
    int id, {
    double? price,
    int? stock,
  }) async {
    final db = await _db;
    final rows = await db.query('cached_products', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return;
    final Map<String, dynamic> raw =
        jsonDecode(rows.first['raw_json'] as String) as Map<String, dynamic>;
    if (price != null) raw['price'] = price;
    if (stock != null) raw['stock'] = stock;
    await db.update(
      'cached_products',
      {
        if (price != null) 'price': price,
        if (stock != null) 'stock': stock,
        'raw_json': jsonEncode(raw),
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ---- Write-action queue -------------------------------------------------

  /// Enqueues a write action to be sent to [endpoint] via [method] (POST/PUT)
  /// with [body]. Returns the generated queue id.
  Future<String> enqueue({
    required PosQueueActionType type,
    required String endpoint,
    required Map<String, dynamic> body,
    String method = 'POST',
  }) async {
    final db = await _db;
    final String id = _uuid.v4();
    await db.insert('sync_queue', {
      'id': id,
      'type': type.value,
      'endpoint': endpoint,
      'method': method,
      'body': jsonEncode(body),
      'created_at': DateTime.now().toIso8601String(),
      'status': 'pending',
      'retries': 0,
    });
    return id;
  }

  Future<List<PosQueueItem>> getPendingQueue() async {
    final db = await _db;
    final rows = await db.query(
      'sync_queue',
      where: 'status = ?',
      whereArgs: ['pending'],
      orderBy: 'created_at ASC',
    );
    return rows.map(PosQueueItem.fromRow).toList();
  }

  Future<int> countPending() async {
    final db = await _db;
    final result = await db.rawQuery(
      "SELECT COUNT(*) as c FROM sync_queue WHERE status = 'pending'",
    );
    return (result.first['c'] as int?) ?? 0;
  }

  Future<void> markSynced(String queueId) async {
    final db = await _db;
    await db.update(
      'sync_queue',
      {'status': 'synced'},
      where: 'id = ?',
      whereArgs: [queueId],
    );
    await db.update(
      'local_orders',
      {'status': 'synced'},
      where: 'queue_id = ?',
      whereArgs: [queueId],
    );
  }

  Future<void> markFailed(String queueId, String error) async {
    final db = await _db;
    await db.rawUpdate(
      "UPDATE sync_queue SET retries = retries + 1, last_error = ? WHERE id = ?",
      [error, queueId],
    );
  }

  // ---- Local (pending) orders, for the "orders" list screen -------------

  Future<void> recordLocalOrder({
    required String queueId,
    required double total,
    required int itemCount,
    String? customerLabel,
  }) async {
    final db = await _db;
    await db.insert('local_orders', {
      'id': _uuid.v4(),
      'queue_id': queueId,
      'customer_label': customerLabel,
      'total': total,
      'item_count': itemCount,
      'status': 'pending_sync',
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, Object?>>> getLocalOrders() async {
    final db = await _db;
    return db.query('local_orders', orderBy: 'created_at DESC');
  }
}
