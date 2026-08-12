import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get/get.dart';
import 'package:shoplancer_vendor/api/api_client.dart';

import 'pos_offline_repository.dart';

/// Watches connectivity and replays the [PosOfflineRepository] write queue
/// against the server whenever the desktop app comes back online.
///
/// This is intentionally generic: every queued action just carries an
/// endpoint + HTTP method + JSON body, so it works for placed orders, price
/// edits, and stock edits alike without needing per-action replay code.
class PosSyncService extends GetxService {
  PosSyncService({required this.apiClient});

  final ApiClient apiClient;

  final PosOfflineRepository _repo = PosOfflineRepository.instance;

  StreamSubscription<List<ConnectivityResult>>? _connectivitySub;
  bool _isOnline = true;
  bool _isSyncing = false;

  int _pendingCount = 0;
  int get pendingCount => _pendingCount;
  bool get isOnline => _isOnline;

  /// Notified whenever the pending-queue count or online state changes, so
  /// the UI can show a "X orders waiting to sync" badge.
  final RxInt pendingCountRx = 0.obs;
  final RxBool isOnlineRx = true.obs;

  Future<PosSyncService> init() async {
    await _refreshPendingCount();

    final List<ConnectivityResult> initial = await Connectivity()
        .checkConnectivity();
    _isOnline = _hasConnection(initial);
    isOnlineRx.value = _isOnline;

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      final bool nowOnline = _hasConnection(result);
      final bool cameOnline = !_isOnline && nowOnline;
      _isOnline = nowOnline;
      isOnlineRx.value = nowOnline;
      if (cameOnline) {
        syncNow();
      }
    });

    if (_isOnline) {
      // Fire and forget: don't block startup on sync.
      syncNow();
    }
    return this;
  }

  bool _hasConnection(List<ConnectivityResult> result) =>
      result.contains(ConnectivityResult.wifi) ||
      result.contains(ConnectivityResult.ethernet) ||
      result.contains(ConnectivityResult.mobile);

  Future<void> _refreshPendingCount() async {
    _pendingCount = await _repo.countPending();
    pendingCountRx.value = _pendingCount;
  }

  /// Attempts to send every pending queued action to the server, in the
  /// order it was created. Stops retrying an item after it fails so a
  /// single bad request doesn't block the rest of the queue on the next run
  /// — it stays `pending` and is retried on the next connectivity event.
  Future<void> syncNow() async {
    if (_isSyncing) return;
    _isSyncing = true;
    try {
      final items = await _repo.getPendingQueue();
      for (final item in items) {
        try {
          final response = item.method == 'PUT'
              ? await apiClient.putData(item.endpoint, item.body)
              : await apiClient.postData(item.endpoint, item.body, handleError: false);

          final int? code = response.statusCode;
          if (code != null && code >= 200 && code < 300) {
            await _repo.markSynced(item.id);
          } else {
            await _repo.markFailed(
              item.id,
              'HTTP ${response.statusCode}: ${response.statusText}',
            );
          }
        } catch (e) {
          await _repo.markFailed(item.id, e.toString());
        }
      }
    } finally {
      await _refreshPendingCount();
      _isSyncing = false;
    }
  }

  @override
  void onClose() {
    _connectivitySub?.cancel();
    super.onClose();
  }
}
