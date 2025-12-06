import 'package:flutter/foundation.dart';
import '../models/health_record.dart';
import '../core/database/database_helper.dart';
import 'package:intl/intl.dart';

class HealthProvider with ChangeNotifier {
  List<HealthRecord> _records = [];
  List<HealthRecord> _filteredRecords = [];
  Map<String, int> _todaySummary = {'steps': 0, 'calories': 0, 'water': 0};
  Map<String, int> _totalStats = {
    'steps': 0,
    'calories': 0,
    'water': 0,
    'records': 0,
  };
  List<Map<String, dynamic>> _weeklyData = [];
  bool _isLoading = false;
  int? _currentUserId;

  List<HealthRecord> get records => _filteredRecords;
  Map<String, int> get todaySummary => _todaySummary;
  Map<String, int> get totalStats => _totalStats;
  List<Map<String, dynamic>> get weeklyData => _weeklyData;
  bool get isLoading => _isLoading;

  void setCurrentUser(int userId) {
    _currentUserId = userId;
    loadRecords();
    loadTodaySummary();
    loadWeeklyData();
    loadTotalStatistics();
  }

  // Load all records from database
  Future<void> loadRecords() async {
    if (_currentUserId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      _records = await DatabaseHelper.instance.readAllRecords(_currentUserId!);
      _filteredRecords = List.from(_records);
    } catch (e) {
      debugPrint('Error loading records: $e');
    }

    _isLoading = false;
    notifyListeners();
  }

  // Add new record
  Future<void> addRecord(HealthRecord record) async {
    if (_currentUserId == null) return;

    try {
      final newRecord = await DatabaseHelper.instance.create(
        record,
        _currentUserId!,
      );
      _records.insert(0, newRecord);
      _filteredRecords = List.from(_records);
      await loadTodaySummary();
      await loadWeeklyData();
      await loadTotalStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding record: $e');
    }
  }

  // Update existing record
  Future<void> updateRecord(HealthRecord record) async {
    try {
      await DatabaseHelper.instance.update(record);
      final index = _records.indexWhere((r) => r.id == record.id);
      if (index != -1) {
        _records[index] = record;
        _filteredRecords = List.from(_records);
        await loadTodaySummary();
        await loadWeeklyData();
        await loadTotalStatistics();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error updating record: $e');
    }
  }

  // Delete record
  Future<void> deleteRecord(int id) async {
    try {
      await DatabaseHelper.instance.delete(id);
      _records.removeWhere((record) => record.id == id);
      _filteredRecords = List.from(_records);
      await loadTodaySummary();
      await loadWeeklyData();
      await loadTotalStatistics();
      notifyListeners();
    } catch (e) {
      debugPrint('Error deleting record: $e');
    }
  }

  // Filter records by date
  void filterByDate(String date) {
    if (date.isEmpty) {
      _filteredRecords = List.from(_records);
    } else {
      _filteredRecords = _records
          .where((record) => record.date == date)
          .toList();
    }
    notifyListeners();
  }

  // Clear filter
  void clearFilter() {
    _filteredRecords = List.from(_records);
    notifyListeners();
  }

  // Load today's summary
  Future<void> loadTodaySummary() async {
    if (_currentUserId == null) return;

    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    try {
      _todaySummary = await DatabaseHelper.instance.getTodaySummary(
        today,
        _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading summary: $e');
    }
  }

  // Load weekly data for charts
  Future<void> loadWeeklyData() async {
    if (_currentUserId == null) return;

    try {
      _weeklyData = await DatabaseHelper.instance.getWeeklySummary(
        _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading weekly data: $e');
    }
  }

  // Load total statistics
  Future<void> loadTotalStatistics() async {
    if (_currentUserId == null) return;

    try {
      _totalStats = await DatabaseHelper.instance.getTotalStatistics(
        _currentUserId!,
      );
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading statistics: $e');
    }
  }

  // Get formatted date string
  String getTodayDate() {
    return DateFormat('yyyy-MM-dd').format(DateTime.now());
  }

  // Clear all data on logout
  void clearData() {
    _records = [];
    _filteredRecords = [];
    _todaySummary = {'steps': 0, 'calories': 0, 'water': 0};
    _totalStats = {'steps': 0, 'calories': 0, 'water': 0, 'records': 0};
    _weeklyData = [];
    _currentUserId = null;
    notifyListeners();
  }
}
