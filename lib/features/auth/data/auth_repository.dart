import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/network/supabase_client.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    supabaseClient: ref.watch(supabaseClientProvider),
  );
});

class AuthRepository {
  final SupabaseClient _supabaseClient;

  AuthRepository({required SupabaseClient supabaseClient})
      : _supabaseClient = supabaseClient;

  Stream<AuthState> get authStateChanges => _supabaseClient.auth.onAuthStateChange;
  User? get currentUser => _supabaseClient.auth.currentUser;

  Future<AuthResponse> signInWithGoogle() async {
    // TODO: Replace with your actual Web Client ID
    const webClientId = 'YOUR_WEB_CLIENT_ID';

    // TODO: Replace with your actual iOS Client ID
    const iosClientId = 'YOUR_IOS_CLIENT_ID';

    final GoogleSignIn googleSignIn = GoogleSignIn(
      clientId: iosClientId,
      serverClientId: webClientId,
    );
    
    final googleUser = await googleSignIn.signIn();
    if (googleUser == null) {
      throw 'Sign in aborted by user';
    }
    
    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    final idToken = googleAuth.idToken;

    if (accessToken == null) {
      throw 'No Access Token found.';
    }
    if (idToken == null) {
      throw 'No ID Token found.';
    }

    final AuthResponse response = await _supabaseClient.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );

    await _checkAndCreateProfile(response.user);
    
    return response;
  }

  Future<void> _checkAndCreateProfile(User? user) async {
    if (user == null) return;

    final profileResponse = await _supabaseClient
        .from('profiles')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (profileResponse == null) {
      // Create new profile
      await _supabaseClient.from('profiles').insert({
        'id': user.id,
        'username': user.userMetadata?['name'] ?? user.email?.split('@').first ?? 'User_${user.id.substring(0, 5)}',
        'avatar_url': user.userMetadata?['avatar_url'],
      });
    }
  }

  Future<void> signInWithApple() async {
    await _supabaseClient.auth.signInWithOAuth(
      OAuthProvider.apple,
    );
  }

  Future<AuthResponse> continueAsGuest() async {
    final AuthResponse response = await _supabaseClient.auth.signInAnonymously();
    await _checkAndCreateProfile(response.user);
    return response;
  }

  Future<AuthResponse> signInWithEmail(String email, String password) async {
    final response = await _supabaseClient.auth.signInWithPassword(
      email: email,
      password: password,
    );
    await _checkAndCreateProfile(response.user);
    return response;
  }

  Future<void> signInWithPhone(String phone) async {
    await _supabaseClient.auth.signInWithOtp(
      phone: phone,
    );
  }

  Future<void> sendOtp(String email) async {
    await _supabaseClient.auth.signInWithOtp(email: email);
  }

  Future<void> verifyOtp(String email, String token) async {
    await _supabaseClient.auth.verifyOTP(
      email: email,
      token: token,
      type: OtpType.email,
    );
  }

  Future<AuthResponse> signUpWithEmail(String email, String password, String fullName) async {
    final response = await _supabaseClient.auth.signUp(
      email: email,
      password: password,
      data: {'name': fullName},
    );
    await _checkAndCreateProfile(response.user);
    return response;
  }

  Future<void> updatePassword(String newPassword) async {
    await _supabaseClient.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  Future<void> signOut() async {
    await GoogleSignIn().signOut();
    await _supabaseClient.auth.signOut();
  }
}
