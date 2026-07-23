import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider =
    StateNotifierProvider<AuthNotifier, AsyncValue<UserModel?>>((ref) {
      return AuthNotifier(ref.read(authRepositoryProvider));
    });

class AuthNotifier extends StateNotifier<AsyncValue<UserModel?>> {
  final AuthRepository _repository;

  AuthNotifier(this._repository) : super(const AsyncValue.data(null)) {
    _checkInitialAuth();
  }

  Future<void> _checkInitialAuth() async {
    final isLogged = await _repository.isLoggedIn();
    if (isLogged) {
      // You could fetch user profile here if the API provides it
      // For now, we just know token exists; no full user object without profile endpoint.
      // We'll set a dummy placeholder or keep null; UI will rely on token presence.
    }
  }

  Future<void> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final user = await _repository.login(username, password);
      state = AsyncValue.data(user);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AsyncValue.data(null);
  }

  Future<void> updatePassword(
    String userName,
    String oldPassword,
    String newPassword,
  ) async {
    state = const AsyncValue.loading();
    try {
      await _repository.updatePassword(userName, oldPassword, newPassword);
      state = AsyncValue.data(state.value); // keep user logged in
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
