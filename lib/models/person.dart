import 'package:hive/hive.dart';

part 'person.g.dart';

@HiveType(typeId: 0)
class Person extends HiveObject {
  @HiveField(0)
  late int personId;

  @HiveField(1)
  late String fullName;

  @HiveField(2)
  String? photoUri;

  @HiveField(3)
  late int primaryZoneId;

  @HiveField(4)
  String? company;

  @HiveField(5)
  late DateTime createdAt;

  Person({
    required this.personId,
    required this.fullName,
    this.photoUri,
    required this.primaryZoneId,
    this.company,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Person.fromJson(Map<String, dynamic> json) {
    personId = json['personId'];
    fullName = json['fullName'];
    photoUri = json['photoUri'];
    primaryZoneId = json['primaryZoneId'];
    company = json['company'];
    createdAt = DateTime.parse(json['createdAt']);
  }

  Map<String, dynamic> toJson() {
    return {
      'personId': personId,
      'fullName': fullName,
      'photoUri': photoUri,
      'primaryZoneId': primaryZoneId,
      'company': company,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Person{personId: $personId, fullName: $fullName, primaryZoneId: $primaryZoneId}';
  }
}
