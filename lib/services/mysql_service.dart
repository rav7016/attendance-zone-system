import 'dart:convert';
import 'package:dio/dio.dart';
import '../models/user.dart';
import '../models/constituency.dart';
import '../models/attendance_event.dart';

class MySQLService {
  static MySQLService? _instance;
  static MySQLService get instance => _instance ??= MySQLService._();
  MySQLService._();

  late Dio _dio;

  // Railway API URL (update this with your actual Railway URL)
  static const String baseUrl =
      'https://attendance-api-production-xxxx.up.railway.app/api';

  void initialize() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  // User operations
  Future<List<User>> getAllUsers() async {
    try {
      final response = await _dio.get('/users');
      final List<dynamic> data = response.data['users'];
      return data.map((json) => User.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching users: $e');
      return [];
    }
  }

  Future<User?> getUserByUsernameOrEmail(String usernameOrEmail) async {
    try {
      final response = await _dio.get(
        '/users/search',
        queryParameters: {'query': usernameOrEmail},
      );
      if (response.data['user'] != null) {
        return User.fromJson(response.data['user']);
      }
      return null;
    } catch (e) {
      print('Error searching user: $e');
      return null;
    }
  }

  Future<bool> saveUser(User user) async {
    try {
      final response = await _dio.post('/users', data: user.toJson());
      return response.statusCode == 201;
    } catch (e) {
      print('Error saving user: $e');
      return false;
    }
  }

  Future<bool> updateUser(User user) async {
    try {
      final response = await _dio.put(
        '/users/${user.userId}',
        data: user.toJson(),
      );
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating user: $e');
      return false;
    }
  }

  // Constituency operations
  Future<List<Constituency>> getAllConstituencies() async {
    try {
      final response = await _dio.get('/constituencies');
      final List<dynamic> data = response.data['constituencies'];
      return data.map((json) => Constituency.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching constituencies: $e');
      return [];
    }
  }

  Future<bool> saveConstituency(Constituency constituency) async {
    try {
      final response = await _dio.post(
        '/constituencies',
        data: constituency.toJson(),
      );
      return response.statusCode == 201;
    } catch (e) {
      print('Error saving constituency: $e');
      return false;
    }
  }

  // Attendance operations
  Future<bool> saveAttendanceEvent(AttendanceEvent event) async {
    try {
      final response = await _dio.post('/attendance', data: event.toJson());
      return response.statusCode == 201;
    } catch (e) {
      print('Error saving attendance: $e');
      return false;
    }
  }

  Future<List<AttendanceEvent>> getAttendanceEvents({
    int? constituencyNo,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{};
      if (constituencyNo != null) queryParams['constituency'] = constituencyNo;
      if (startDate != null)
        queryParams['start_date'] = startDate.toIso8601String();
      if (endDate != null) queryParams['end_date'] = endDate.toIso8601String();

      final response = await _dio.get(
        '/attendance',
        queryParameters: queryParams,
      );
      final List<dynamic> data = response.data['events'];
      return data.map((json) => AttendanceEvent.fromJson(json)).toList();
    } catch (e) {
      print('Error fetching attendance events: $e');
      return [];
    }
  }

  // Health check
  Future<bool> isConnected() async {
    try {
      final response = await _dio.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
