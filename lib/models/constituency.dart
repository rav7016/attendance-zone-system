import 'package:hive/hive.dart';

part 'constituency.g.dart';

@HiveType(typeId: 11)
class Constituency extends HiveObject {
  @HiveField(0)
  late int constituencyNo;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late int electoralPopulation;

  @HiveField(3)
  late String ethnicMajority;

  @HiveField(4)
  DateTime? createdAt;

  Constituency({
    required this.constituencyNo,
    required this.name,
    required this.electoralPopulation,
    required this.ethnicMajority,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Constituency.fromJson(Map<String, dynamic> json) {
    constituencyNo = json['constituencyNo'];
    name = json['name'];
    electoralPopulation = json['electoralPopulation'];
    ethnicMajority = json['ethnicMajority'];
    createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null;
  }

  Map<String, dynamic> toJson() {
    return {
      'constituencyNo': constituencyNo,
      'name': name,
      'electoralPopulation': electoralPopulation,
      'ethnicMajority': ethnicMajority,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Constituency{constituencyNo: $constituencyNo, name: $name, population: $electoralPopulation}';
  }
}
