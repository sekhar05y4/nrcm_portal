import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/student.dart';

class ApiService {
  // Update to point to your hosted/local engine address.
  static const String baseUrl = "http://127.0.0.1:5000/api";
  static String token = "";

  static Future<Map<String, dynamic>> login(String username, String password, String role) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password, 'role': role}),
    );
    final decoded = jsonDecode(response.body);
    if (response.statusCode == 200) {
      token = decoded['token'] ?? '';
    }
    return {'statusCode': response.statusCode, 'body': decoded};
  }

  static Future<Map<String, dynamic>> registerStudent(Map<String, dynamic> payload) async {
    final response = await http.post(
      Uri.parse('$baseUrl/student/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    return {'statusCode': response.statusCode, 'body': jsonDecode(response.body)};
  }

  static Future<List<Student>> getPendingStudents() async {
    final response = await http.get(Uri.parse('$baseUrl/admin/pending'));
    if (response.statusCode == 200) {
      List data = jsonDecode(response.body);
      return data.map((e) => Student.fromJson(e)).toList();
    }
    return [];
  }

  static Future<bool> handleApproval(String rollNumber, bool approved) async {
    final endpoint = approved ? 'approve' : 'reject';
    final response = await http.post(
      Uri.parse('$baseUrl/admin/$endpoint'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'roll_number': rollNumber}),
    );
    return response.statusCode == 200;
  }

  static Future<List<Map<String, dynamic>>> getRoster(String dept, String year, String section) async {
    final response = await http.get(Uri.parse('$baseUrl/faculty/students?dept=$dept&year=$year&section=$section'));
    if (response.statusCode == 200) {
      return List<Map<String, dynamic>>.from(jsonDecode(response.body));
    }
    return [];
  }

  static Future<bool> submitAttendance(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/faculty/attendance/mark'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': token,
      },
      body: jsonEncode(data),
    );
    return response.statusCode == 201;
  }

  static Future<Map<String, dynamic>> getReport(String date, String dept, String year, String section) async {
    final response = await http.get(Uri.parse('$baseUrl/faculty/attendance/report?date=$date&dept=$dept&year=$year&section=$section'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }
    return {'present': [], 'absent': []};
  }
}