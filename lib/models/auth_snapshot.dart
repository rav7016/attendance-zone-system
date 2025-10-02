import 'package:hive/hive.dart';

part 'auth_snapshot.g.dart';

@HiveType(typeId: 9)
class AuthSnapshotItem extends HiveObject {
  @HiveField(0)
  late String cardUid;

  @HiveField(1)
  int? personId;

  @HiveField(2)
  String? personName;

  @HiveField(3)
  late int primaryZoneId;

  @HiveField(4)
  late String cardState;

  @HiveField(5)
  String? photoHash;

  @HiveField(6)
  DateTime? validFrom;

  @HiveField(7)
  DateTime? validTo;

  AuthSnapshotItem({
    required this.cardUid,
    this.personId,
    this.personName,
    required this.primaryZoneId,
    required this.cardState,
    this.photoHash,
    this.validFrom,
    this.validTo,
  });

  AuthSnapshotItem.fromJson(Map<String, dynamic> json) {
    cardUid = json['cardUid'];
    personId = json['personId'];
    personName = json['personName'];
    primaryZoneId = json['primaryZoneId'];
    cardState = json['cardState'];
    photoHash = json['photoHash'];
    validFrom = json['validFrom'] != null
        ? DateTime.parse(json['validFrom'])
        : null;
    validTo = json['validTo'] != null ? DateTime.parse(json['validTo']) : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'cardUid': cardUid,
      'personId': personId,
      'personName': personName,
      'primaryZoneId': primaryZoneId,
      'cardState': cardState,
      'photoHash': photoHash,
      'validFrom': validFrom?.toIso8601String(),
      'validTo': validTo?.toIso8601String(),
    };
  }

  bool get isActive => cardState == 'active';
  bool get isValid {
    final now = DateTime.now();
    return isActive &&
        (validFrom == null || validFrom!.isBefore(now)) &&
        (validTo == null || validTo!.isAfter(now));
  }
}

@HiveType(typeId: 10)
class AuthSnapshot extends HiveObject {
  @HiveField(0)
  late String snapshotId;

  @HiveField(1)
  late int version;

  @HiveField(2)
  late DateTime createdAtUtc;

  @HiveField(3)
  late DateTime validUntilUtc;

  @HiveField(4)
  late String signedBy;

  @HiveField(5)
  late List<AuthSnapshotItem> items;

  @HiveField(6)
  String? signature;

  AuthSnapshot({
    required this.snapshotId,
    required this.version,
    DateTime? createdAtUtc,
    DateTime? validUntilUtc,
    required this.signedBy,
    required this.items,
    this.signature,
  }) : createdAtUtc = createdAtUtc ?? DateTime.now().toUtc(),
       validUntilUtc =
           validUntilUtc ??
           DateTime.now().toUtc().add(const Duration(hours: 24));

  AuthSnapshot.fromJson(Map<String, dynamic> json) {
    snapshotId = json['snapshotId'];
    version = json['version'];
    createdAtUtc = DateTime.parse(json['createdAtUtc']);
    validUntilUtc = DateTime.parse(json['validUntilUtc']);
    signedBy = json['signedBy'];
    items = (json['items'] as List)
        .map((item) => AuthSnapshotItem.fromJson(item))
        .toList();
    signature = json['signature'];
  }

  Map<String, dynamic> toJson() {
    return {
      'snapshotId': snapshotId,
      'version': version,
      'createdAtUtc': createdAtUtc.toIso8601String(),
      'validUntilUtc': validUntilUtc.toIso8601String(),
      'signedBy': signedBy,
      'items': items.map((item) => item.toJson()).toList(),
      'signature': signature,
    };
  }

  bool get isExpired => DateTime.now().toUtc().isAfter(validUntilUtc);
  bool get isValid => !isExpired && signature != null;

  AuthSnapshotItem? findCard(String cardUid) {
    try {
      return items.firstWhere((item) => item.cardUid == cardUid);
    } catch (e) {
      return null;
    }
  }
}
