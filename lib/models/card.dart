import 'package:hive/hive.dart';

part 'card.g.dart';

@HiveType(typeId: 1)
enum CardType {
  @HiveField(0)
  nfc,
  @HiveField(1)
  qr,
  @HiveField(2)
  hybrid,
}

@HiveType(typeId: 2)
enum CardState {
  @HiveField(0)
  draft,
  @HiveField(1)
  active,
  @HiveField(2)
  suspended,
  @HiveField(3)
  revoked,
  @HiveField(4)
  expired,
}

@HiveType(typeId: 3)
class Card extends HiveObject {
  @HiveField(0)
  late String cardUid;

  @HiveField(1)
  late int personId;

  @HiveField(2)
  late CardType cardType;

  @HiveField(3)
  late CardState state;

  @HiveField(4)
  late DateTime issueDate;

  @HiveField(5)
  DateTime? expiryDate;

  @HiveField(6)
  DateTime? revokedAt;

  @HiveField(7)
  String? reason;

  Card({
    required this.cardUid,
    required this.personId,
    required this.cardType,
    this.state = CardState.draft,
    DateTime? issueDate,
    this.expiryDate,
    this.revokedAt,
    this.reason,
  }) : issueDate = issueDate ?? DateTime.now();

  Card.fromJson(Map<String, dynamic> json) {
    cardUid = json['cardUid'];
    personId = json['personId'];
    cardType = CardType.values.firstWhere(
      (e) => e.toString().split('.').last == json['cardType'],
    );
    state = CardState.values.firstWhere(
      (e) => e.toString().split('.').last == json['state'],
    );
    issueDate = DateTime.parse(json['issueDate']);
    expiryDate = json['expiryDate'] != null
        ? DateTime.parse(json['expiryDate'])
        : null;
    revokedAt = json['revokedAt'] != null
        ? DateTime.parse(json['revokedAt'])
        : null;
    reason = json['reason'];
  }

  Map<String, dynamic> toJson() {
    return {
      'cardUid': cardUid,
      'personId': personId,
      'cardType': cardType.toString().split('.').last,
      'state': state.toString().split('.').last,
      'issueDate': issueDate.toIso8601String(),
      'expiryDate': expiryDate?.toIso8601String(),
      'revokedAt': revokedAt?.toIso8601String(),
      'reason': reason,
    };
  }

  bool get isActive => state == CardState.active;
  bool get isValid =>
      isActive && (expiryDate == null || expiryDate!.isAfter(DateTime.now()));

  @override
  String toString() {
    return 'Card{cardUid: $cardUid, personId: $personId, state: $state}';
  }
}
