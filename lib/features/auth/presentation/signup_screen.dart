import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../controllers/auth_controller.dart';
import 'password_strength_indicator.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _passwordValue = '';

  void _log(String message) {
    debugPrint('🟢 SIGNUP_SCREEN: $message');
  }

  @override
  void initState() {
    super.initState();

    _log('SignupScreen initialized');

    _passwordController.addListener(() {
      setState(() => _passwordValue = _passwordController.text);

      _log(
        'Password changed. Length: ${_passwordController.text.length}',
      );
    });
  }

  @override
  void dispose() {
    _log('SignupScreen disposed');

    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();

    super.dispose();
  }

  Future<void> _createAccount() async {
    _log('Create Account button pressed');

    if (!_formKey.currentState!.validate()) {
      _log('Form validation failed');
      return;
    }

    _log('Form validation successful');
    _log('Full Name: ${_fullNameController.text.trim()}');
    _log('Email: ${_emailController.text.trim()}');
    _log('Password Length: ${_passwordController.text.length}');

    try {
      _log('Calling signUpWithEmail()');

      await ref.read(authControllerProvider.notifier).signUpWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _fullNameController.text.trim(),
      );

      _log('signUpWithEmail() completed');
    } catch (e, stackTrace) {
      _log('signUpWithEmail ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final isLoading = authState.isLoading;

    _log(
      'Build triggered | State: ${authState.runtimeType} | Loading: $isLoading',
    );

    ref.listen<AsyncValue<void>>(authControllerProvider, (previous, next) {
      _log(
        'Auth state changed | Previous: ${previous.runtimeType} -> Current: ${next.runtimeType}',
      );

      if (next is AsyncError) {
        _log('Auth Error: ${next.error}');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error.toString()),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next is AsyncData && previous is AsyncLoading) {
        _log('Signup successful');
        _log('Navigating to Login Screen');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created! Check your email to verify.'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );

        context.go('/login');
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 32),

                TextFormField(
                  controller: _fullNameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    hintText: 'Enter your full name',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    _log('Validating Full Name');

                    if (value == null || value.trim().isEmpty) {
                      _log('Full Name validation failed');
                      return 'Please enter your full name';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    hintText: 'Enter your email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    _log('Validating Email');

                    if (value == null || value.trim().isEmpty) {
                      _log('Email validation failed - empty');
                      return 'Please enter your email';
                    }

                    if (!value.contains('@')) {
                      _log('Email validation failed - invalid format');
                      return 'Please enter a valid email';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    hintText: 'Enter your password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        _log('Password visibility toggled');

                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  validator: (value) {
                    _log('Validating Password');

                    if (value == null || value.isEmpty) {
                      _log('Password validation failed - empty');
                      return 'Please enter a password';
                    }

                    if (value.length < 8) {
                      _log('Password validation failed - less than 8 chars');
                      return 'Minimum 8 characters';
                    }

                    if (!RegExp(r'[A-Z]').hasMatch(value)) {
                      _log('Password validation failed - no uppercase');
                      return 'At least 1 uppercase letter (A-Z)';
                    }

                    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
                      _log('Password validation failed - no special character');
                      return 'At least 1 special character';
                    }

                    if (!RegExp(r'[0-9]').hasMatch(value)) {
                      _log('Password validation failed - no number');
                      return 'At least 1 number (0-9)';
                    }

                    return null;
                  },
                ),

                PasswordStrengthIndicator(
                  password: _passwordValue,
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _confirmPasswordController,
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    hintText: 'Confirm your password',
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        _log('Confirm Password visibility toggled');

                        setState(() {
                          _obscureConfirm = !_obscureConfirm;
                        });
                      },
                    ),
                  ),
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  validator: (value) {
                    _log('Validating Confirm Password');

                    if (value == null || value.isEmpty) {
                      _log('Confirm Password validation failed - empty');
                      return 'Please confirm your password';
                    }

                    if (value != _passwordController.text) {
                      _log('Confirm Password validation failed - mismatch');
                      return 'Passwords do not match';
                    }

                    return null;
                  },
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _createAccount,
                    child: isLoading
                        ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                      ),
                    )
                        : const Text('Create Account'),
                  ),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: isLoading
                        ? null
                        : () {
                      _log('Google Sign In button pressed');

                      ref
                          .read(authControllerProvider.notifier)
                          .signInWithGoogle();
                    },
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    label: const Text(
                      'Continue with Google',
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        _log('Login button tapped');
                        context.pop();
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.blue,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}