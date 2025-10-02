import 'package:uuid/uuid.dart';
import '../models/attendance_event.dart';
import '../models/auth_snapshot.dart';
import 'database_service.dart';

class AccessDecisionResult {
  final Decision decision;
  final ReasonCode reasonCode;
  final String? personName;
  final int? personId;
  final int? zoneId;

  AccessDecisionResult({
    required this.decision,
    required this.reasonCode,
    this.personName,
    this.personId,
    this.zoneId,
  });

  bool get isAllow => decision == Decision.allow;
  bool get isDeny => decision == Decision.deny;

  String get message {
    switch (reasonCode) {
      case ReasonCode.success:
        return 'Welcome, ${personName ?? 'User'}!';
      case ReasonCode.unknownCard:
        return 'Unknown card. Please contact admin.';
      case ReasonCode.inactiveCard:
        return 'Card is inactive. Please contact admin.';
      case ReasonCode.wrongZone:
        return 'Access denied. Wrong zone.';
      case ReasonCode.outOfWindow:
        return 'Access denied. Outside time window.';
      case ReasonCode.antiPassback:
        return 'Please wait before scanning again.';
      case ReasonCode.cardReadError:
        return 'Card read error. Please try again.';
      case ReasonCode.deviceUnauthorized:
        return 'Device unauthorized.';
      case ReasonCode.snapshotExpired:
        return 'Authorization expired. Please sync.';
    }
  }
}

class AccessDecisionEngine {
  static const int antiPassbackCooldownSeconds = 30;
  final DatabaseService _db = DatabaseService.instance;
  final Map<String, DateTime> _lastScanTimes = {};

  /// Main decision method that validates card access
  Future<AccessDecisionResult> makeDecision({
    required String cardUid,
    required String readerId,
    bool isOnline = false,
  }) async {
    try {
      // Step 1: Get reader information
      final reader = _db.getReader(readerId);
      if (reader == null) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.deviceUnauthorized,
        );
      }

      // Step 2: Check anti-passback
      if (_isAntiPassback(cardUid)) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.antiPassback,
        );
      }

      // Step 3: Get card information (from snapshot for offline, or database for online)
      AuthSnapshotItem? snapshotItem;
      if (!isOnline) {
        // Offline mode: use authorization snapshot
        final snapshot = _db.getLatestSnapshot();
        if (snapshot == null || snapshot.isExpired) {
          return AccessDecisionResult(
            decision: Decision.deny,
            reasonCode: ReasonCode.snapshotExpired,
          );
        }
        snapshotItem = snapshot.findCard(cardUid);
      } else {
        // Online mode: get from snapshot items (cached)
        snapshotItem = _db.getSnapshotItem(cardUid);
      }

      // Step 4: Validate card existence
      if (snapshotItem == null) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.unknownCard,
        );
      }

      // Step 5: Validate card state
      if (!snapshotItem.isValid) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.inactiveCard,
        );
      }

      // Step 6: Validate zone access
      if (snapshotItem.primaryZoneId != reader.zoneId) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.wrongZone,
          personName: snapshotItem.personName,
          personId: snapshotItem.personId,
          zoneId: reader.zoneId,
        );
      }

      // Step 7: Check time window (optional - can be configured)
      if (!_isWithinTimeWindow()) {
        return AccessDecisionResult(
          decision: Decision.deny,
          reasonCode: ReasonCode.outOfWindow,
          personName: snapshotItem.personName,
          personId: snapshotItem.personId,
          zoneId: reader.zoneId,
        );
      }

      // All checks passed - ALLOW access
      _updateLastScanTime(cardUid);

      return AccessDecisionResult(
        decision: Decision.allow,
        reasonCode: ReasonCode.success,
        personName: snapshotItem.personName,
        personId: snapshotItem.personId,
        zoneId: reader.zoneId,
      );
    } catch (e) {
      // Any unexpected error results in denial
      return AccessDecisionResult(
        decision: Decision.deny,
        reasonCode: ReasonCode.cardReadError,
      );
    }
  }

  /// Creates and saves an attendance event based on the decision
  Future<AttendanceEvent> createAttendanceEvent({
    required String cardUid,
    required String readerId,
    required AccessDecisionResult result,
    bool isOffline = false,
  }) async {
    final reader = _db.getReader(readerId);
    final event = AttendanceEvent(
      eventId: const Uuid().v4(),
      timestampUtc: DateTime.now().toUtc(),
      readerId: readerId,
      zoneId: reader?.zoneId ?? 0,
      personId: result.personId,
      cardUid: cardUid,
      decision: result.decision,
      reasonCode: result.reasonCode,
      offlineFlag: isOffline,
      synced: !isOffline, // Online events are immediately synced
    );

    await _db.saveEvent(event);
    return event;
  }

  /// Check if card was scanned too recently (anti-passback)
  bool _isAntiPassback(String cardUid) {
    final lastScan = _lastScanTimes[cardUid];
    if (lastScan == null) return false;

    final now = DateTime.now();
    final timeDifference = now.difference(lastScan);
    return timeDifference.inSeconds < antiPassbackCooldownSeconds;
  }

  /// Update the last scan time for anti-passback tracking
  void _updateLastScanTime(String cardUid) {
    _lastScanTimes[cardUid] = DateTime.now();
  }

  /// Check if current time is within allowed access window
  /// This is a placeholder - can be configured based on meeting times
  bool _isWithinTimeWindow() {
    // For now, always return true (24/7 access)
    // In production, this would check against configured time windows
    return true;
  }

  /// Clear anti-passback cache (useful for testing or admin override)
  void clearAntiPassbackCache() {
    _lastScanTimes.clear();
  }
}
