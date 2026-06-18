import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/auth_repository.dart';

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final authControllerProvider =
NotifierProvider<AuthController, AsyncValue<void>>(
  AuthController.new,
);

class AuthController extends Notifier<AsyncValue<void>> {
  @override
  AsyncValue<void> build() {
    return const AsyncValue.data(null);
  }

  Future<void> signInWithGoogle() async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).signInWithGoogle();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signInWithApple() async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).signInWithApple();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> continueAsGuest() async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).continueAsGuest();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signInWithEmail(String email, String password) async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).signInWithEmail(email, password);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signInWithPhone(String phone) async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).signInWithPhone(phone);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> resetPassword(String email) async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).resetPassword(email);
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();

    try {
      await ref.read(authRepositoryProvider).signOut();
      state = const AsyncValue.data(null);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}