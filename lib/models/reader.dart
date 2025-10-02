import 'package:hive/hive.dart';

part 'reader.g.dart';

@HiveType(typeId: 5)
class Reader extends HiveObject {
  @HiveField(0)
  late String readerId;

  @HiveField(1)
  late int zoneId;

  @HiveField(2)
  String? deviceType;

  @HiveField(3)
  String? firmwareVersion;

  @HiveField(4)
  String? publicKey;

  @HiveField(5)
  DateTime? lastSeen;

  Reader({
    required this.readerId,
    required this.zoneId,
    this.deviceType,
    this.firmwareVersion,
    this.publicKey,
    this.lastSeen,
  });

  Reader.fromJson(Map<String, dynamic> json) {
    readerId = json['readerId'];
    zoneId = json['zoneId'];
    deviceType = json['deviceType'];
    firmwareVersion = json['firmwareVersion'];
    publicKey = json['publicKey'];
    lastSeen = json['lastSeen'] != null
        ? DateTime.parse(json['lastSeen'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'readerId': readerId,
      'zoneId': zoneId,
      'deviceType': deviceType,
      'firmwareVersion': firmwareVersion,
      'publicKey': publicKey,
      'lastSeen': lastSeen?.toIso8601String(),
    };
  }

  bool get isOnline {
    if (lastSeen == null) return false;
    final now = DateTime.now();
    final difference = now.difference(lastSeen!);
    return difference.inMinutes < 5; // Consider online if seen within 5 minutes
  }

  @override
  String toString() {
    return 'Reader{readerId: $readerId, zoneId: $zoneId, deviceType: $deviceType}';
  }
}

