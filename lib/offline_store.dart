import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'api_service.dart';

/// Handles all offline storage + syncing.
///
/// Boxes:
/// - 'assignments'  : cached assignment list (downloaded when online)
/// - 'inspections'  : local inspection data keyed by assignmentId  (answers/comments/photos)
/// - 'syncQueue'    : list of assignmentIds whose inspections are submitted offline and
///                    need to be pushed to the backend when back online
class OfflineStore {
  OfflineStore._();
  static final OfflineStore instance = OfflineStore._();

  static const String _kAssignments = 'assignments';
  static const String _kInspections = 'inspections';
  static const String _kSyncQueue = 'syncQueue';
  static const String _kMeta = 'meta';
  static const String _kKnowledge = 'knowledge';

  late Box _assignments;
  late Box _inspections;
  late Box _syncQueue;
  late Box _meta;
  late Box _knowledge;

  bool _ready = false;

  Future<void> init() async {
    if (_ready) return;
    await Hive.initFlutter();
    _assignments = await Hive.openBox(_kAssignments);
    _inspections = await Hive.openBox(_kInspections);
    _syncQueue = await Hive.openBox(_kSyncQueue);
    _meta = await Hive.openBox(_kMeta);
    _knowledge = await Hive.openBox(_kKnowledge);
    _ready = true;
  }

  // ─────────────────────────── NETWORK ───────────────────────────
  Future<bool> isOnline() async {
    final result = await Connectivity().checkConnectivity();
    // connectivity_plus 7.x returns a List<ConnectivityResult>
    if (result is List) {
      return result.any((r) => r != ConnectivityResult.none);
    }
    return result != ConnectivityResult.none;
  }

  Stream<bool> onlineStream() {
    return Connectivity().onConnectivityChanged.map((result) {
      if (result is List) {
        return result.any((r) => r != ConnectivityResult.none);
      }
      return result != ConnectivityResult.none;
    });
  }

  // ─────────────────────── OFFLINE KNOWLEDGE ──────────────────────
  /// Save the knowledge base pack (list of {id, title, chunks:[..]}) for offline answering.
  Future<void> cacheKnowledge(List<dynamic> docs) async {
    if (docs.isEmpty) return;
    await _knowledge.put('pack', jsonEncode(docs));
    await _knowledge.put('cachedAt', DateTime.now().toIso8601String());
  }

  /// Number of cached knowledge documents (0 = nothing cached yet).
  int get knowledgeDocCount {
    final raw = _knowledge.get('pack');
    if (raw == null) return 0;
    try {
      return (jsonDecode(raw) as List).length;
    } catch (_) {
      return 0;
    }
  }

  /// Simple keyword search over cached document chunks.
  /// Returns the top matching excerpts as (docTitle, chunkText) maps.
  List<Map<String, String>> searchKnowledge(String query, {int topK = 3}) {
    final raw = _knowledge.get('pack');
    if (raw == null) return [];
    List<dynamic> docs;
    try {
      docs = jsonDecode(raw);
    } catch (_) {
      return [];
    }
    final terms = query
        .toLowerCase()
        .split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 2)
        .toSet();
    if (terms.isEmpty) return [];

    final scored = <({double score, String title, String chunk})>[];
    for (final d in docs) {
      final title = (d['title'] ?? '').toString();
      final chunks = (d['chunks'] as List?) ?? [];
      for (final c in chunks) {
        final text = c.toString();
        final lower = text.toLowerCase();
        double score = 0;
        for (final t in terms) {
          score += RegExp(RegExp.escape(t)).allMatches(lower).length;
        }
        if (score > 0) scored.add((score: score, title: title, chunk: text));
      }
    }
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored
        .take(topK)
        .map((e) => {'title': e.title, 'chunk': e.chunk})
        .toList();
  }

  // ─────────────────────── ASSIGNMENTS CACHE ──────────────────────
  /// Save the assignment list fetched from the backend for offline use.
  Future<void> cacheAssignments(List<dynamic> assignments) async {
    await _assignments.put('list', jsonEncode(assignments));
    await _meta.put('assignments_synced_at', DateTime.now().toIso8601String());
  }

  /// Get cached assignments (used when offline).
  List<dynamic> getCachedAssignments() {
    final raw = _assignments.get('list');
    if (raw == null) return [];
    try {
      return jsonDecode(raw) as List<dynamic>;
    } catch (_) {
      return [];
    }
  }

  String? lastAssignmentsSync() => _meta.get('assignments_synced_at');

  /// Fetch assignments: online → backend + cache; offline → cache.
  Future<List<dynamic>> getAssignments() async {
    if (await isOnline()) {
      try {
        final list = await ApiService.getMyAssignments();
        await cacheAssignments(list);
        // merge in any locally-modified statuses (in_progress/submitted offline)
        return _mergeLocalStatus(list);
      } catch (_) {
        return _mergeLocalStatus(getCachedAssignments());
      }
    }
    return _mergeLocalStatus(getCachedAssignments());
  }

  /// Overlay local inspection status (in_progress / submitted-offline) on the list.
  List<dynamic> _mergeLocalStatus(List<dynamic> list) {
    for (final a in list) {
      final id = a['id']?.toString();
      if (id == null) continue;
      final local = getLocalInspection(id);
      if (local == null || local['_local_status'] == null) continue;

      final backendStatus = (a['status'] ?? '').toString().toLowerCase();
      final localStatus = (local['_local_status'] ?? '').toString().toLowerCase();
      final pending = local['_pending_sync'] == true;

      // Backend is authoritative once it reports submitted/approved/report_ready.
      // Only overlay the local status when there are un-synced offline changes.
      const backendDone = ['submitted', 'approved', 'report_ready', 'completed'];
      if (backendDone.contains(backendStatus)) {
        a['_pending_sync'] = false;
        // clear stale local record so it stops overriding
        continue;
      }

      if (pending) {
        a['status'] = localStatus;
        a['_pending_sync'] = true;
      } else {
        // local not pending and backend not done -> keep backend but note local progress
        if (localStatus == 'in_progress' && backendStatus.isEmpty) {
          a['status'] = 'in_progress';
        }
      }
    }
    return list;
  }

  // ────────────────────── LOCAL INSPECTIONS ───────────────────────
  /// Save an inspection's data locally (answers/comments/photos/cover).
  /// [status] is the local status: 'in_progress' or 'submitted'.
  Future<void> saveLocalInspection(
      String assignmentId, {
        required Map<String, dynamic> answers,
        String? coverImage,
        String localStatus = 'in_progress',
        bool pendingSync = false,
        int? inspectionId,
        String? masterName,
        String? masterEmail,
      }) async {
    final existing = getLocalInspection(assignmentId) ?? {};
    final data = {
      ...existing,
      'assignment_id': assignmentId,
      'answers': answers,
      'cover_image': coverImage ?? existing['cover_image'] ?? '',
      '_local_status': localStatus,
      '_pending_sync': pendingSync,
      'inspection_id': inspectionId ?? existing['inspection_id'],
      'master_name': masterName ?? existing['master_name'] ?? '',
      'master_email': masterEmail ?? existing['master_email'] ?? '',
      'updated_at': DateTime.now().toIso8601String(),
    };
    await _inspections.put(assignmentId, jsonEncode(data));
  }

  Map<String, dynamic>? getLocalInspection(String assignmentId) {
    final raw = _inspections.get(assignmentId);
    if (raw == null) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw));
    } catch (_) {
      return null;
    }
  }

  // ───────────────────────── SYNC QUEUE ───────────────────────────
  /// Mark an inspection as submitted offline → needs sync.
  Future<void> queueForSync(String assignmentId) async {
    final list = pendingSyncIds();
    if (!list.contains(assignmentId)) {
      list.add(assignmentId);
      await _syncQueue.put('ids', list);
    }
  }

  List<String> pendingSyncIds() {
    final raw = _syncQueue.get('ids');
    if (raw == null) return [];
    return List<String>.from(raw);
  }

  int get pendingSyncCount => pendingSyncIds().length;

  Future<void> _removeFromQueue(String assignmentId) async {
    final list = pendingSyncIds();
    list.remove(assignmentId);
    await _syncQueue.put('ids', list);
  }

  String? lastSyncTime() => _meta.get('last_sync_at');

  /// Push all queued inspections to the backend. Returns a summary.
  /// Must be online. Each inspection: start (get inspection_id) → save → submit.
  Future<Map<String, dynamic>> syncNow() async {
    if (!await isOnline()) {
      return {'success': false, 'message': 'No internet connection', 'synced': 0, 'failed': 0};
    }

    final ids = pendingSyncIds();
    int synced = 0;
    int failed = 0;
    final failedIds = <String>[];

    for (final assignmentId in ids) {
      final local = getLocalInspection(assignmentId);
      if (local == null) {
        await _removeFromQueue(assignmentId);
        continue;
      }
      try {
        final intId = int.tryParse(assignmentId) ?? 0;
        // 1) start / resume to get an inspection_id
        int? inspectionId = local['inspection_id'];
        if (inspectionId == null) {
          final startData = await ApiService.startInspection(intId);
          inspectionId = startData?['inspection_id'];
        }
        if (inspectionId == null) {
          failed++;
          failedIds.add(assignmentId);
          continue;
        }

        // build answers incl. cover image
        final answers = Map<String, dynamic>.from(local['answers'] ?? {});
        if ((local['cover_image'] ?? '').toString().isNotEmpty) {
          answers['__cover_image__'] = {'url': local['cover_image']};
        }

        // 2) save answers
        await ApiService.saveAnswers(
          inspectionId,
          answers,
          masterName: local['master_name'],
          masterEmail: local['master_email'],
        );

        // 3) submit
        final result = await ApiService.submitInspection(inspectionId);
        if (result != null) {
          synced++;
          // mark local as synced (no longer pending)
          await saveLocalInspection(
            assignmentId,
            answers: answers,
            coverImage: local['cover_image'],
            localStatus: 'submitted',
            pendingSync: false,
            inspectionId: inspectionId,
            masterName: local['master_name'],
            masterEmail: local['master_email'],
          );
          await _removeFromQueue(assignmentId);
        } else {
          failed++;
          failedIds.add(assignmentId);
        }
      } catch (_) {
        failed++;
        failedIds.add(assignmentId);
      }
    }

    await _meta.put('last_sync_at', DateTime.now().toIso8601String());
    return {
      'success': failed == 0,
      'synced': synced,
      'failed': failed,
      'message': failed == 0
          ? 'Synced $synced inspection(s) successfully'
          : 'Synced $synced, failed $failed. Will retry later.',
    };
  }

  Future<void> clearAll() async {
    await _assignments.clear();
    await _inspections.clear();
    await _syncQueue.clear();
    await _meta.clear();
  }
}