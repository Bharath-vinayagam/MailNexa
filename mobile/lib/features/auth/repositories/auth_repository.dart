import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';

class AuthRepository {
  final ApiClient _apiClient;
  AuthRepository(this._apiClient);

  /// Exchanges Google auth code for JWT tokens.
  Future<Map<String, dynamic>> googleAuth(String code) async {
    final response = await _apiClient.post(
      ApiEndpoints.authGoogle,
      data: {'code': code},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Student email login API call.
  Future<Map<String, dynamic>> demoLogin(String email) async {
    final response = await _apiClient.post(
      ApiEndpoints.authDemoLogin,
      data: {'email': email},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Refreshes the access token using the refresh token.
  Future<Map<String, dynamic>> refreshToken(String token) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRefresh,
      data: {'refreshToken': token},
    );
    return response.data as Map<String, dynamic>;
  }

  /// Logs out the current user.
  Future<void> logout() async {
    await _apiClient.post(ApiEndpoints.authLogout);
    await SecureStorage.clearAll();
  }

  /// Fetches the current user's profile.
  Future<UserModel> getProfile() async {
    final response = await _apiClient.get(ApiEndpoints.authProfile);
    return UserModel.fromJson(response.data['data']['user'] as Map<String, dynamic>);
  }

  /// Registers the FCM token for push notifications.
  Future<void> updateFcmToken(String fcmToken) async {
    await _apiClient.put(ApiEndpoints.authFcmToken, data: {'fcmToken': fcmToken});
  }

  /// Updates student profile identifiers (registrationNumber, neoPatId, phone).
  Future<UserModel> updateProfile(Map<String, String> fields) async {
    final response = await _apiClient.patch(ApiEndpoints.authProfile, data: fields);
    return UserModel.fromJson(response.data['data']['user'] as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(apiClientProvider));
});
