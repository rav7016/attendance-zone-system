import 'package:hive/hive.dart';

part 'zone.g.dart';

@HiveType(typeId: 4)
class Zone extends HiveObject {
  @HiveField(0)
  late int zoneId;

  @HiveField(1)
  late String zoneName;

  @HiveField(2)
  String? location;

  @HiveField(3)
  int? capacity;

  @HiveField(4)
  String? marshalUserId;

  Zone({
    required this.zoneId,
    required this.zoneName,
    this.location,
    this.capacity,
    this.marshalUserId,
  });

  Zone.fromJson(Map<String, dynamic> json) {
    zoneId = json['zoneId'];
    zoneName = json['zoneName'];
    location = json['location'];
    capacity = json['capacity'];
    marshalUserId = json['marshalUserId'];
  }

  Map<String, dynamic> toJson() {
    return {
      'zoneId': zoneId,
      'zoneName': zoneName,
      'location': location,
      'capacity': capacity,
      'marshalUserId': marshalUserId,
    };
  }

  @override
  String toString() {
    return 'Zone{zoneId: $zoneId, zoneName: $zoneName, location: $location}';
  }
}
