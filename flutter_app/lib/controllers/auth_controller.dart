import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

enum AuthState {
  unauthenticated,
  authenticating,
  authenticated,
  error,
}

class AuthStateModel {
  final AuthState state;
  final UserModel? user;
  final String? errorMessage;

  AuthStateModel({
    required this.state,
    this.user,
    this.errorMessage,
  });

  AuthStateModel copyWith({
    AuthState? state,
    UserModel? user,
    String? errorMessage,
  }) {
    return AuthStateModel(
      state: state ?? this.state,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class AuthController extends StateNotifier<AuthStateModel> {
  final AuthService _authService;

  AuthController(this._authService) : super(AuthStateModel(state: AuthState.unauthenticated)) {
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final isAuth = await _authService.isAuthenticated();
    if (isAuth) {
      final user = await _authService.getCurrentUser();
      if (user != null) {
        state = AuthStateModel(state: AuthState.authenticated, user: user);
      } else {
        state = AuthStateModel(state: AuthState.unauthenticated);
      }
    } else {
      state = AuthStateModel(state: AuthState.unauthenticated);
    }
  }

  Future<bool> register({
    required String email,
    required String password,
    required String role,
    required String firstName,
    required String lastName,
    String? phone,
    Map<String, dynamic>? lawyerData,
  }) async {
    state = AuthStateModel(state: AuthState.authenticating);

    try {
      final response = await _authService.register(
        email: email,
        password: password,
        role: role,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        lawyerData: lawyerData,
      );

      if (response.success && response.data != null) {
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: response.data!.user,
        );
        return true;
      } else {
        state = AuthStateModel(
          state: AuthState.error,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    state = AuthStateModel(state: AuthState.authenticating);

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response.success && response.data != null) {
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: response.data!.user,
        );
        return true;
      } else {
        state = AuthStateModel(
          state: AuthState.error,
          errorMessage: response.message,
        );
        return false;
      }
    } catch (e) {
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: e.toString(),
      );
      return false;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    state = AuthStateModel(state: AuthState.unauthenticated);
  }

  Future<void> refreshUser() async {
    final user = await _authService.getCurrentUser();
    if (user != null) {
      state = AuthStateModel(state: AuthState.authenticated, user: user);
    }
  }
}

final authServiceProvider = Provider<AuthService>((ref) => AuthService());

final authControllerProvider = StateNotifierProvider<AuthController, AuthStateModel>((ref) {
  return AuthController(ref.read(authServiceProvider));
});

