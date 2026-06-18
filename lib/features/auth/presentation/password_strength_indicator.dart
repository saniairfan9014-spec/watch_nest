import 'package:flutter/material.dart';

class PasswordStrengthIndicator extends StatelessWidget {
  final String password;

  const PasswordStrengthIndicator({super.key, required this.password});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Requirement(
            label: 'Minimum 8 characters',
            met: password.length >= 8,
          ),
          const SizedBox(height: 4),
          _Requirement(
            label: 'At least 1 uppercase letter (A-Z)',
            met: RegExp(r'[A-Z]').hasMatch(password),
          ),
          const SizedBox(height: 4),
          _Requirement(
            label: 'At least 1 lowercase letter (a-z)',
            met: RegExp(r'[a-z]').hasMatch(password),
          ),
          const SizedBox(height: 4),
          _Requirement(
            label: 'At least 1 number (0-9)',
            met: RegExp(r'[0-9]').hasMatch(password),
          ),
        ],
      ),
    );
  }
}

class _Requirement extends StatelessWidget {
  final String label;
  final bool met;

  const _Requirement({required this.label, required this.met});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.radio_button_unchecked,
          size: 18,
          color: met ? Colors.green : Colors.grey,
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: met ? Colors.green : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
