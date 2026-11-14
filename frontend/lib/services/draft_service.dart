// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:convert';

// Conditionally import localStorage backend only on web
import 'draft_service_stub.dart'
    if (dart.library.html) 'draft_service_web.dart'
    as draft_impl; // ignore: library_prefixes

/// A simple cross-platform draft service.
/// On web, persists drafts in localStorage. On native, no-ops (stub).
class DraftService {
  static const String _key = 'agronexus_produce_drafts';

  static Future<void> saveDraft(Map<String, dynamic> draft) async {
    final all = await loadDrafts();
    // Assign an id if missing
    if (!draft.containsKey('id')) {
      draft['id'] = DateTime.now().millisecondsSinceEpoch.toString();
    }
    draft['savedAt'] = DateTime.now().toIso8601String();
    draft['isDraft'] = true;
    // Replace if same id exists, else append
    final idx = all.indexWhere((d) => d['id'] == draft['id']);
    if (idx >= 0) {
      all[idx] = draft;
    } else {
      all.add(draft);
    }
    draft_impl.writeToStorage(_key, jsonEncode(all));
  }

  static Future<List<Map<String, dynamic>>> loadDrafts() async {
    final raw = draft_impl.readFromStorage(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final List<dynamic> list = jsonDecode(raw);
      return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> deleteDraft(String id) async {
    final all = await loadDrafts();
    all.removeWhere((d) => d['id'] == id);
    draft_impl.writeToStorage(_key, jsonEncode(all));
  }
}
