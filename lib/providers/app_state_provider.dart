import 'package:flutter/foundation.dart';
import '../models/reader.dart';
import '../models/zone.dart';
import '../models/attendance_event.dart';
import '../services/database_service.dart';

class AppStateProvider extends ChangeNotifier {
  final DatabaseService _db = DatabaseService.instance;

  Reader? _currentReader;
  Zone? _currentZone;
  bool _isOnline = false;
  bool _isScanning = false;
  List<AttendanceEvent> _recentEvents = [];

  // Getters
  Reader? get currentReader => _currentReader;
  Zone? get currentZone => _currentZone;
  bool get isOnline => _isOnline;
  bool get isScanning => _isScanning;
  List<AttendanceEvent> get recentEvents => _recentEvents;
  bool get isConfigured => _currentReader != null && _currentZone != null;

  // Reader configuration
  Future<void> setCurrentReader(String readerId) async {
    _currentReader = _db.getReader(readerId);
    if (_currentReader != null) {
      _currentZone = _db.getZone(_currentReader!.zoneId);
      await _loadRecentEvents();
    }
    notifyListeners();
  }

  // Create a new reader (for initial setup)
  Future<void> createReader({
    required String readerId,
    required int zoneId,
    String? deviceType,
  }) async {
    final reader = Reader(
      readerId: readerId,
      zoneId: zoneId,
      deviceType: deviceType ?? 'Mobile',
      lastSeen: DateTime.now(),
    );

    await _db.saveReader(reader);
    await setCurrentReader(readerId);
  }

  // Online/Offline status
  void setOnlineStatus(bool online) {
    _isOnline = online;
    notifyListeners();
  }

  // Scanning status
  void setScanningStatus(bool scanning) {
    _isScanning = scanning;
    notifyListeners();
  }

  // Load recent events for current zone
  Future<void> _loadRecentEvents() async {
    if (_currentZone != null) {
      final allEvents = _db.getEventsByZone(_currentZone!.zoneId);
      // Get events from last 24 hours
      final cutoff = DateTime.now().subtract(const Duration(hours: 24));
      _recentEvents =
          allEvents
              .where((event) => event.timestampUtc.isAfter(cutoff))
              .toList()
            ..sort((a, b) => b.timestampUtc.compareTo(a.timestampUtc));
    }
  }

  // Add new event and refresh list
  Future<void> addEvent(AttendanceEvent event) async {
    await _db.saveEvent(event);
    await _loadRecentEvents();
    notifyListeners();
  }

  // Get statistics for current zone
  Map<String, dynamic> getCurrentZoneStats() {
    if (_currentZone == null) return {};

    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);
    final todayEvents = _recentEvents
        .where((event) => event.timestampUtc.isAfter(startOfDay.toUtc()))
        .toList();

    final allowedToday = todayEvents.where((e) => e.isAllow).length;
    final deniedToday = todayEvents.where((e) => e.isDeny).length;
    final totalToday = todayEvents.length;

    // Get currently present people (those with ALLOW events but no recent DENY)
    final presentPeople = <int>{};
    for (final event in todayEvents.reversed) {
      if (event.personId != null) {
        if (event.isAllow) {
          presentPeople.add(event.personId!);
        } else if (event.isDeny &&
            event.reasonCode != ReasonCode.antiPassback) {
          presentPeople.remove(event.personId!);
        }
      }
    }

    return {
      'zoneName': _currentZone!.zoneName,
      'capacity': _currentZone!.capacity,
      'currentOccupancy': presentPeople.length,
      'todayTotal': totalToday,
      'todayAllowed': allowedToday,
      'todayDenied': deniedToday,
      'successRate': totalToday > 0
          ? (allowedToday / totalToday * 100).toStringAsFixed(1)
          : '0.0',
    };
  }

  // Get unsynced events count
  int getUnsyncedEventsCount() {
    return _db.getUnsyncedEvents().length;
  }

  // Refresh all data
  Future<void> refresh() async {
    await _loadRecentEvents();
    notifyListeners();
  }
}
