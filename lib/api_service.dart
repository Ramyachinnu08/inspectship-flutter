import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_config.dart';

class ApiService {
  static String? _token;

  // Token management
  static Future<void> saveToken(String token) async {
    _token = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  static Future<String?> getToken() async {
    if (_token != null) return _token;
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    return _token;
  }

  static Future<void> clearToken() async {
    _token = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('user');
  }

  // User management
  static Future<void> saveUser(Map<String, dynamic> user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user', jsonEncode(user));
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr == null) return null;
    return jsonDecode(userStr);
  }

  static Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // LOGIN
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['access_token'] != null) {
        await saveToken(data['access_token']);
        await saveUser(data['user']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'message': data['detail'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server: $e'};
    }
  }

  // CHANGE PASSWORD
  static Future<Map<String, dynamic>> changePassword(String oldPassword, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        headers: await _headers(),
        body: jsonEncode({'old_password': oldPassword, 'new_password': newPassword}),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        return {'success': true, 'message': data['message'] ?? 'Password changed'};
      }
      return {'success': false, 'message': data['message'] ?? data['detail'] ?? 'Failed to change password'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  // FORGOT PASSWORD - request reset link
  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);
      return {
        'success': data['success'] == true,
        'message': data['message'] ?? '',
        'reset_link': data['reset_link'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  // RESET PASSWORD with token
  static Future<Map<String, dynamic>> resetPassword(String token, String newPassword) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token, 'new_password': newPassword}),
      );
      final data = jsonDecode(res.body);
      return {'success': data['success'] == true, 'message': data['message'] ?? ''};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  // GET my assignments (with real questions)
  static Future<List<dynamic>> getMyAssignments() async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/inspector/assignments'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['data'] ?? [];
      return [];
    } catch (e) {
      return [];
    }
  }

  // Old admin assignments endpoint (kept for compatibility)
  static Future<List<dynamic>> getAssignments() async {
    return getMyAssignments();
  }

  // START/RESUME inspection
  static Future<Map<String, dynamic>?> startInspection(int assignmentId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/inspector/assignments/$assignmentId/start'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['data'];
      return null;
    } catch (e) {
      return null;
    }
  }

  // SAVE answers (draft)
  static Future<bool> saveAnswers(int inspectionId, Map<String, dynamic> answers, {String? masterName, String? masterEmail, String? masterSignature, String? inspectorSignature}) async {
    try {
      final body = <String, dynamic>{'answers': answers};
      if (masterName != null) body['master_name'] = masterName;
      if (masterEmail != null) body['master_email'] = masterEmail;
      if (masterSignature != null) body['master_signature_url'] = masterSignature;
      if (inspectorSignature != null) body['inspector_signature_url'] = inspectorSignature;
      final res = await http.patch(
        Uri.parse('${ApiConfig.baseUrl}/api/inspector/inspections/$inspectionId'),
        headers: await _headers(),
        body: jsonEncode(body),
      );
      return res.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // SUBMIT inspection
  static Future<Map<String, dynamic>?> submitInspection(int inspectionId) async {
    try {
      final res = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/inspector/inspections/$inspectionId/submit'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['data'];
      return null;
    } catch (e) {
      return null;
    }
  }

  // GET inspection detail (for report viewer)
  static Future<Map<String, dynamic>?> getInspectionDetail(int assignmentId) async {
    try {
      final res = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/api/inspector/assignments/$assignmentId/inspection'),
        headers: await _headers(),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) return data['data'];
      return null;
    } catch (e) {
      return null;
    }
  }
}