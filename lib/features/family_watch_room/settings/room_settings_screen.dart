import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../rooms/presentation/room_type.dart';
import 'room_settings_viewmodel.dart';
import '../theme/room_theme_manager.dart';

class RoomSettingsScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomSettingsScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomSettingsScreen> createState() => _RoomSettingsScreenState();
}

class _RoomSettingsScreenState extends ConsumerState<RoomSettingsScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _themeManager = RoomThemeManager();

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomSettingsViewModelProvider);
    final viewModel = ref.read(roomSettingsViewModelProvider.notifier);
    final theme = _themeManager.getConfig(state.selectedType);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Room Settings'),
        actions: [
          TextButton(
            onPressed: state.isLoading
                ? null
                : () async {
                    if (!_formKey.currentState!.validate()) return;
                    try {
                      await viewModel.saveSettings(widget.roomId);
                      if (mounted) context.pop();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to save: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
            child: state.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.primarySwatch.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.primarySwatch.shade200),
                ),
                child: Column(
                  children: [
                    Icon(theme.roomIcon, size: 48, color: theme.accentColor),
                    const SizedBox(height: 8),
                    Text(
                      state.selectedType.label,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: theme.primarySwatch.shade700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      theme.backgroundHint,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Room Name',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  hintText: 'Enter room name',
                  border: OutlineInputBorder(),
                ),
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 20),
              const Text(
                'Room Description',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Describe your room',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Privacy',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Private Room'),
                subtitle: Text(
                  state.isPrivate
                      ? 'Only invited members can join'
                      : 'Anyone can join',
                ),
                value: state.isPrivate,
                onChanged: viewModel.setPrivacy,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),
              const Text(
                'Room Type',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 12),
              ...RoomType.values.map((type) {
                final t = _themeManager.getConfig(type);
                final isSelected = state.selectedType == type;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Material(
                    color: isSelected ? t.primarySwatch.shade50 : null,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => viewModel.setRoomType(type),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? t.primarySwatch.shade300
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(t.roomIcon, color: t.accentColor),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    type.label,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    type.subtitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              Icon(Icons.check_circle,
                                  color: t.primarySwatch.shade600),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
