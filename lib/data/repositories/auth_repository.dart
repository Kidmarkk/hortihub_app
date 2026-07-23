import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../core/constants/api_constants.dart';
import '../../core/utils/auth_utils.dart';
import '../datasources/remote/api_service.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiService _api = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<UserModel> login(String username, String password) async {
    try {
      final hashedPassword = AuthUtils.hashPassword(password);

      final response = await _api.postForLogin(ApiConstants.login, {
        'username': username,
        'password': hashedPassword,
      });

      final statusCode = response.statusCode;
      final data = response.data;

      // --- Handle non-200 status codes ---
      if (statusCode != 200) {
        String errorMessage;
        if (data is String) {
          // Plain text error from server
          errorMessage = data;
        } else if (data is Map<String, dynamic>) {
          errorMessage =
              data['message'] ??
              data['error'] ??
              data['msg'] ??
              'Invalid credentials. Please check your credentials and try again.';
        } else {
          errorMessage = 'Login failed. Please try again.';
        }
        throw Exception(errorMessage);
      }

      // --- Parse successful login (status 200) ---
      if (data is! Map<String, dynamic>) {
        throw Exception('Invalid response format');
      }

      // Check for error inside 200 response (e.g., success: false)
      if (data.containsKey('success') && data['success'] == false) {
        final errorMsg =
            data['message'] ??
            data['error'] ??
            'Invalid credentials. Please check your credentials and try again.';
        throw Exception(errorMsg);
      }

      // Use the full fromJson to parse all fields including listDistricts and listHubs
      final user = UserModel.fromJson(data);

      // Save token and user
      await _storage.write(key: 'access_token', value: user.token);
      await _storage.write(key: 'user', value: jsonEncode(user.toJson()));

      final freshAuthKey = AuthUtils.generateAuthKey();
      print('✅ Token saved: ${user.token.substring(0, 20)}...');
      print('🔑 LOGIN AUTHKEY: $freshAuthKey');
      print('🔑 LOGIN TOKEN: ${user.token}');
      print('🔍 userDetails: ${data['userDetails']}');

      return user;
    } catch (e) {
      print('❌ Login error: $e');
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'user');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'access_token');
  }

  Future<UserModel?> getUser() async {
    final userJson = await _storage.read(key: 'user');
    if (userJson == null) return null;
    try {
      final Map<String, dynamic> map = jsonDecode(userJson);
      return UserModel.fromJson(map);
    } catch (e) {
      return null;
    }
  }

  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  Future<void> updatePassword(
    String userName,
    String oldPassword,
    String newPassword,
  ) async {
    // Hash old and new passwords using SHA512 then SHA256 (same as login)
    final hashedOld = _hashPasswordForUpdate(oldPassword);
    final hashedNew = _hashPasswordForUpdate(newPassword);

    final response = await _api.postFormData(ApiConstants.updatePassword, {
      'userName': userName,
      'oldPassword': hashedOld,
      'newPassword': hashedNew,
    });

    if (response.statusCode != 200) {
      throw Exception('Password update failed: ${response.data}');
    }
  }

  String _hashPasswordForUpdate(String plainPassword) {
    final sha512Bytes = sha512.convert(utf8.encode(plainPassword)).bytes;
    final sha512Hex = sha512Bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    final sha256Hash = sha256.convert(utf8.encode(sha512Hex));
    return sha256Hash.toString();
  }
}
