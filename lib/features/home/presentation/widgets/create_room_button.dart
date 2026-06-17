import 'package:flutter/material.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_text_styles.dart';

class CreateRoomButton extends StatefulWidget {
  final VoidCallback onCreateRoom;
  final VoidCallback onJoinRoom;

  const CreateRoomButton({
    super.key,
    required this.onCreateRoom,
    required this.onJoinRoom,
  });

  @override
  State<CreateRoomButton> createState() => _CreateRoomButtonState();
}

class _CreateRoomButtonState extends State<CreateRoomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: _buildCreateButton(),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: _buildJoinButton(),
          ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: widget.onCreateRoom,
      child: AnimatedBuilder(
        animation: _shimmerController,
        builder: (context, child) {
          return Container(
            height: 54,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: const [
                  AppColors.primary,
                  Color(0xFFB54DFF),
                  AppColors.primary,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                stops: [
                  (_shimmerController.value - 0.3).clamp(0.0, 1.0),
                  _shimmerController.value.clamp(0.0, 1.0),
                  (_shimmerController.value + 0.3).clamp(0.0, 1.0),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 20,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: child,
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Create Room', style: AppTextStyles.button),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinButton() {
    return GestureDetector(
      onTap: widget.onJoinRoom,
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF2E2E42), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.login_rounded, color: AppColors.primaryLight, size: 20),
            const SizedBox(width: 8),
            Text(
              'Join',
              style: AppTextStyles.button.copyWith(
                color: AppColors.primaryLight,
                fontSize: 15,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
