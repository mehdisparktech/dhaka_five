import 'package:get_storage/get_storage.dart';

class VoterHistoryService {
  static const String _storageKey = 'voter_search_history';
  final GetStorage _storage = GetStorage();

  /// Save a search result to history
  Future<void> saveSearch({
    required String searchType,
    required String searchValue,
    required String dobDay,
    required String dobMonth,
    required String dobYear,
    required List voters,
  }) async {
    final history = getHistory();
    
    final historyItem = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'timestamp': DateTime.now().toIso8601String(),
      'searchType': searchType,
      'searchValue': searchValue,
      'dobDay': dobDay,
      'dobMonth': dobMonth,
      'dobYear': dobYear,
      'voters': voters,
      'voterCount': voters.length,
    };

    // Add to beginning of list (most recent first)
    history.insert(0, historyItem);

    // Limit to last 100 searches
    if (history.length > 100) {
      history.removeRange(100, history.length);
    }

    await _storage.write(_storageKey, history);
  }

  /// Get all search history
  List<Map<String, dynamic>> getHistory() {
    final data = _storage.read(_storageKey);
    if (data == null) return [];
    if (data is List) {
      return data.cast<Map<String, dynamic>>();
    }
    return [];
  }

  /// Clear all history
  Future<void> clearHistory() async {
    await _storage.remove(_storageKey);
  }

  /// Delete a specific history item
  Future<void> deleteHistoryItem(String id) async {
    final history = getHistory();
    history.removeWhere((item) => item['id'] == id);
    await _storage.write(_storageKey, history);
  }
}
