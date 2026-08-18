import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:dio/dio.dart';
import '../../../core/storage/secure_storage.dart';
import '../models/user_model.dart';
import '../repositories/auth_repository.dart';

// ─── Auth State ───────────────────────────────────────────
class AuthState {
  final bool isAuthenticated;
  final bool isOnboarded;
  final bool isLoading;
  final UserModel? user;
  final String? error;

  const AuthState({
    this.isAuthenticated = false,
    this.isOnboarded = false,
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isOnboarded,
    bool? isLoading,
    UserModel? user,
    String? error,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isOnboarded: isOnboarded ?? this.isOnboarded,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error,
    );
  }
}

// ─── Auth Notifier ────────────────────────────────────────
class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  static final _googleSignIn = GoogleSignIn(
    clientId: '199862061735-85h232jrj0v79b64tk1g2jukl88u5uim.apps.googleusercontent.com',
    serverClientId: '199862061735-85h232jrj0v79b64tk1g2jukl88u5uim.apps.googleusercontent.com',
    forceCodeForRefreshToken: true,
    scopes: [
      'email',
      'profile',
      'https://www.googleapis.com/auth/gmail.readonly',
    ],
  );

  AuthNotifier(this._repository) : super(const AuthState()) {
    _checkAuthStatus();
  }

  /// Checks if user is already logged in (app startup).
  Future<void> _checkAuthStatus() async {
    state = state.copyWith(isLoading: true);
    try {
      final isLoggedIn = await SecureStorage.isLoggedIn();
      if (isLoggedIn) {
        final user = await _repository.getProfile();
        state = state.copyWith(
          isAuthenticated: true,
          isOnboarded: true,
          isLoading: false,
          user: user,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }
    } catch (e) {
      await SecureStorage.clearAll();
      state = state.copyWith(isLoading: false);
    }
  }

  /// Direct email authentication (for student login & quick access).
  Future<void> signInWithEmail(String emailInput) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final email = emailInput.trim().isEmpty ? 'student@university.edu' : emailInput.trim();
      final response = await _repository.demoLogin(email);
      final data = response['data'] as Map<String, dynamic>;

      await SecureStorage.saveTokens(
        accessToken: data['accessToken'] as String,
        refreshToken: data['refreshToken'] as String,
      );

      final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
      await SecureStorage.saveUserInfo(
        userId: user.id,
        email: user.email,
        role: user.role,
      );

      state = state.copyWith(
        isAuthenticated: true,
        isOnboarded: true,
        isLoading: false,
        user: user,
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyDioError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Maps DioException types to friendly user-facing messages.
  String _friendlyDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Could not reach the server. Check your internet connection and try again.';
      case DioExceptionType.receiveTimeout:
        return 'Server is taking too long to respond. Please try again in a moment.';
      case DioExceptionType.sendTimeout:
        return 'Request timed out while sending. Check your connection.';
      case DioExceptionType.connectionError:
        return 'No internet connection. Make sure Wi-Fi or mobile data is on.';
      case DioExceptionType.badResponse:
        final status = e.response?.statusCode;
        final msg = e.response?.data?['message'] as String?;
        if (status == 401) return 'Session expired. Please sign in again.';
        if (status == 403) return 'Access denied.';
        if (status == 500) return 'Server error. Please try again later.';
        return msg ?? 'Something went wrong (code $status).';
      default:
        return 'Connection failed. Please try again.';
    }
  }

  /// Initiates Google Sign-In flow with backend token generation.
  Future<void> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Force Google Play Services to clear cached session & request fresh serverAuthCode
      try {
        await _googleSignIn.signOut();
      } catch (_) {}

      final account = await _googleSignIn.signIn();
      if (account == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      final serverAuthCode = account.serverAuthCode;

      if (serverAuthCode != null) {
        final response = await _repository.googleAuth(serverAuthCode);
        final data = response['data'] as Map<String, dynamic>;

        await SecureStorage.saveTokens(
          accessToken: data['accessToken'] as String,
          refreshToken: data['refreshToken'] as String,
        );

        final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
        await SecureStorage.saveUserInfo(
          userId: user.id,
          email: user.email,
          role: user.role,
        );

        state = state.copyWith(
          isAuthenticated: true,
          isOnboarded: true,
          isLoading: false,
          user: user,
        );
        return;
      }

      // If serverAuthCode is unavailable, report clear error
      state = state.copyWith(
        isLoading: false,
        error: 'Could not obtain Google Authorization Code. Please try again.',
      );
    } on DioException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: _friendlyDioError(e),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceAll('Exception: ', ''),
      );
    }
  }

  /// Completes onboarding.
  void completeOnboarding() {
    state = state.copyWith(isOnboarded: true);
  }

  /// Updates student identifier fields (registrationNumber, neoPatId).
  Future<void> updateProfile(Map<String, String> fields) async {
    try {
      final updatedUser = await _repository.updateProfile(fields);
      state = state.copyWith(user: updatedUser);
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  /// Logs out the user.
  Future<void> logout() async {
    state = state.copyWith(isLoading: true);
    try {
      await _repository.logout();
      await _googleSignIn.signOut();
    } catch (_) {
      await SecureStorage.clearAll();
    }
    await SecureStorage.clearAll();
    state = const AuthState();
  }
}

// ─── Riverpod Providers ───────────────────────────────────
final authStateProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthNotifier(repository);
});
