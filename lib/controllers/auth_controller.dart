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
    try {
      final isAuth = await _authService.isAuthenticated().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('Auth check timeout - checking stored data');
          return true; // Continue to check stored data
        },
      );
      
      if (isAuth) {
        try {
          // Try to get user from API first
          UserModel? user;
          try {
            user = await _authService.getCurrentUser().timeout(
              const Duration(seconds: 5),
              onTimeout: () {
                print('Get user from API timeout - trying stored data');
                return null;
              },
            );
          } catch (e) {
            print('Error getting user from API: $e - trying stored data');
          }
          
          // If API call failed, try to restore from stored data
          if (user == null) {
            print('Attempting to restore user from stored data');
            user = await _authService.getStoredUser();
            if (user != null) {
              print('Successfully restored user from stored data: ${user.email}');
            }
          }
          
          if (user != null) {
            state = AuthStateModel(state: AuthState.authenticated, user: user);
            print('Auth status check: User authenticated - ${user.email}');
          } else {
            // No user found in API or stored data - clear auth
            print('No user found - clearing authentication');
            await _authService.logout();
            state = AuthStateModel(state: AuthState.unauthenticated);
          }
        } catch (e) {
          print('Error getting current user: $e');
          // Try to restore from stored data as last resort
          final storedUser = await _authService.getStoredUser();
          if (storedUser != null) {
            print('Restored user from stored data after error: ${storedUser.email}');
            state = AuthStateModel(state: AuthState.authenticated, user: storedUser);
          } else {
            state = AuthStateModel(state: AuthState.unauthenticated);
          }
        }
      } else {
        // No token found - check if we have stored user data (shouldn't happen, but handle it)
        final storedUser = await _authService.getStoredUser();
        if (storedUser != null) {
          print('Token missing but stored user found - clearing invalid session');
          await _authService.logout();
        }
        state = AuthStateModel(state: AuthState.unauthenticated);
      }
    } catch (e) {
      print('Error checking auth status: $e');
      // Last resort: try to restore from stored data
      final storedUser = await _authService.getStoredUser();
      if (storedUser != null) {
        print('Restored user from stored data after exception: ${storedUser.email}');
        state = AuthStateModel(state: AuthState.authenticated, user: storedUser);
      } else {
        state = AuthStateModel(state: AuthState.unauthenticated);
      }
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
    required bool acceptedTerms,
    required bool acceptedPrivacy,
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
        acceptedTerms: acceptedTerms,
        acceptedPrivacy: acceptedPrivacy,
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
      // Extract more detailed error message
      String errorMessage = 'Registration failed';
      if (e.toString().contains('DioException')) {
        // Try to extract the actual error message from the response
        errorMessage = 'Registration failed. Please check your information and try again.';
      } else {
        errorMessage = e.toString();
      }
      
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: errorMessage,
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

      if (response.success && response.data != null && response.data!.user != null) {
        final user = response.data!.user;
        // Debug: Print user info
        print('Setting authenticated state - User ID: ${user.id}, Role: ${user.role}');
        
        // Ensure state is updated with the user - use a new instance to force rebuild
        state = AuthStateModel(
          state: AuthState.authenticated,
          user: user,
        );
        
        // Force a small delay to ensure state propagation
        await Future.delayed(const Duration(milliseconds: 100));
        
        // Verify state was set
        print('Auth state updated - State: ${state.state}, User: ${state.user?.email}');
        
        return true;
      } else {
        state = AuthStateModel(
          state: AuthState.error,
          errorMessage: response.message.isNotEmpty ? response.message : 'Login failed',
        );
        return false;
      }
    } catch (e) {
      // Extract more detailed error message
      String errorMessage = 'Login failed';
      if (e.toString().contains('DioException')) {
        errorMessage = 'Login failed. Please check your credentials and try again.';
      } else {
        errorMessage = e.toString();
      }
      
      state = AuthStateModel(
        state: AuthState.error,
        errorMessage: errorMessage,
      );
      return false;
    }
  }

  Future<void> logout() async {
    print('Logging out user - clearing all stored data');
    await _authService.logout();
    state = AuthStateModel(state: AuthState.unauthenticated);
    print('Logout complete - user is now unauthenticated');
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

