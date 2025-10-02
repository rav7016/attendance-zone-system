import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 12)
enum UserRole {
  @HiveField(0)
  admin,
  @HiveField(1)
  operator,
  @HiveField(2)
  viewer,
}

@HiveType(typeId: 13)
class User extends HiveObject {
  @HiveField(0)
  late String userId;

  @HiveField(1)
  late String username;

  @HiveField(2)
  late String email;

  @HiveField(3)
  late String passwordHash;

  @HiveField(4)
  late String fullName;

  @HiveField(5)
  late UserRole role;

  @HiveField(6)
  late List<int> assignedConstituencies;

  @HiveField(7)
  late bool isActive;

  @HiveField(8)
  DateTime? createdAt;

  @HiveField(9)
  DateTime? lastLoginAt;

  @HiveField(10)
  String? phoneNumber;

  @HiveField(11)
  String? department;

  User({
    required this.userId,
    required this.username,
    required this.email,
    required this.passwordHash,
    required this.fullName,
    required this.role,
    List<int>? assignedConstituencies,
    bool? isActive,
    DateTime? createdAt,
    this.lastLoginAt,
    this.phoneNumber,
    this.department,
  }) : assignedConstituencies = assignedConstituencies ?? [],
       isActive = isActive ?? true,
       createdAt = createdAt ?? DateTime.now();

  User.fromJson(Map<String, dynamic> json) {
    userId = json['userId'];
    username = json['username'];
    email = json['email'];
    passwordHash = json['passwordHash'];
    fullName = json['fullName'];
    role = UserRole.values.firstWhere(
      (e) => e.toString() == 'UserRole.${json['role']}',
      orElse: () => UserRole.viewer,
    );
    assignedConstituencies = List<int>.from(
      json['assignedConstituencies'] ?? [],
    );
    isActive = json['isActive'] ?? true;
    createdAt = json['createdAt'] != null
        ? DateTime.parse(json['createdAt'])
        : null;
    lastLoginAt = json['lastLoginAt'] != null
        ? DateTime.parse(json['lastLoginAt'])
        : null;
    phoneNumber = json['phoneNumber'];
    department = json['department'];
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'username': username,
      'email': email,
      'passwordHash': passwordHash,
      'fullName': fullName,
      'role': role.toString().split('.').last,
      'assignedConstituencies': assignedConstituencies,
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'phoneNumber': phoneNumber,
      'department': department,
    };
  }

  // Helper methods
  bool hasAccessToConstituency(int constituencyNo) {
    return assignedConstituencies.contains(constituencyNo);
  }

  bool get isAdmin => role == UserRole.admin;
  bool get canManageUsers => role == UserRole.admin;
  bool get canViewAllData => role == UserRole.admin;

  String get roleDisplayName {
    switch (role) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.operator:
        return 'Operator';
      case UserRole.viewer:
        return 'Viewer';
    }
  }

  @override
  String toString() {
    return 'User{userId: $userId, username: $username, fullName: $fullName, role: $role}';
  }
}
