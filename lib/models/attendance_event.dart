import 'package:hive/hive.dart';

part 'attendance_event.g.dart';

@HiveType(typeId: 6)
enum Decision {
  @HiveField(0)
  allow,
  @HiveField(1)
  deny,
}

@HiveType(typeId: 7)
enum ReasonCode {
  @HiveField(0)
  success,
  @HiveField(1)
  unknownCard,
  @HiveField(2)
  inactiveCard,
  @HiveField(3)
  wrongZone,
  @HiveField(4)
  outOfWindow,
  @HiveField(5)
  antiPassback,
  @HiveField(6)
  cardReadError,
  @HiveField(7)
  deviceUnauthorized,
  @HiveField(8)
  snapshotExpired,
}

@HiveType(typeId: 8)
class AttendanceEvent extends HiveObject {
  @HiveField(0)
  late String eventId;

  @HiveField(1)
  late DateTime timestampUtc;

  @HiveField(2)
  late String readerId;

  @HiveField(3)
  late int zoneId;

  @HiveField(4)
  int? personId;

  @HiveField(5)
  late String cardUid;

  @HiveField(6)
  late Decision decision;

  @HiveField(7)
  late ReasonCode reasonCode;

  @HiveField(8)
  late bool offlineFlag;

  @HiveField(9)
  String? syncBatchId;

  @HiveField(10)
  late bool synced;

  AttendanceEvent({
    required this.eventId,
    DateTime? timestampUtc,
    required this.readerId,
    required this.zoneId,
    this.personId,
    required this.cardUid,
    required this.decision,
    required this.reasonCode,
    this.offlineFlag = false,
    this.syncBatchId,
    this.synced = false,
  }) : timestampUtc = timestampUtc ?? DateTime.now().toUtc();

  AttendanceEvent.fromJson(Map<String, dynamic> json) {
    eventId = json['eventId'];
    timestampUtc = DateTime.parse(json['timestampUtc']);
    readerId = json['readerId'];
    zoneId = json['zoneId'];
    personId = json['personId'];
    cardUid = json['cardUid'];
    decision = Decision.values.firstWhere(
      (e) => e.toString().split('.').last == json['decision'],
    );
    reasonCode = ReasonCode.values.firstWhere(
      (e) => e.toString().split('.').last == json['reasonCode'],
    );
    offlineFlag = json['offlineFlag'] ?? false;
    syncBatchId = json['syncBatchId'];
    synced = json['synced'] ?? false;
  }

  Map<String, dynamic> toJson() {
    return {
      'eventId': eventId,
      'timestampUtc': timestampUtc.toIso8601String(),
      'readerId': readerId,
      'zoneId': zoneId,
      'personId': personId,
      'cardUid': cardUid,
      'decision': decision.toString().split('.').last,
      'reasonCode': reasonCode.toString().split('.').last,
      'offlineFlag': offlineFlag,
      'syncBatchId': syncBatchId,
      'synced': synced,
    };
  }

  bool get isAllow => decision == Decision.allow;
  bool get isDeny => decision == Decision.deny;
  bool get needsSync => !synced && offlineFlag;

  String get reasonMessage {
    switch (reasonCode) {
      case ReasonCode.success:
        return 'Access granted';
      case ReasonCode.unknownCard:
        return 'Unknown card';
      case ReasonCode.inactiveCard:
        return 'Inactive card';
      case ReasonCode.wrongZone:
        return 'Wrong zone';
      case ReasonCode.outOfWindow:
        return 'Outside time window';
      case ReasonCode.antiPassback:
        return 'Anti-passback violation';
      case ReasonCode.cardReadError:
        return 'Card read error';
      case ReasonCode.deviceUnauthorized:
        return 'Device unauthorized';
      case ReasonCode.snapshotExpired:
        return 'Authorization expired';
    }
  }

  @override
  String toString() {
    return 'AttendanceEvent{eventId: $eventId, cardUid: $cardUid, decision: $decision, reasonCode: $reasonCode}';
  }
}
