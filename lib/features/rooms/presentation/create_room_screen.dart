import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'create_room_viewmodel.dart';
import 'room_type.dart';
import 'room_privacy.dart';

class CreateRoomScreen extends ConsumerStatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  ConsumerState<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends ConsumerState<CreateRoomScreen> {
  final _roomNameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _roomNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    if (!_formKey.currentState!.validate()) return;

    final viewModel = ref.read(createRoomViewModelProvider.notifier);
    await viewModel.createRoom();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRoomViewModelProvider);
    final viewModel = ref.read(createRoomViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Create Room'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Room Name',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roomNameController,
                  decoration: const InputDecoration(
                    hintText: 'Enter room name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter a room name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                const Text(
                  'Room Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12,
                  children: RoomType.values.map((type) {
                    final label = type.name[0].toUpperCase() + type.name.substring(1);
                    return ChoiceChip(
                      label: Text(label),
                      selected: state.selectedType == type,
                      onSelected: (_) => viewModel.setRoomType(type),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Privacy',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 12),
                RadioListTile<RoomPrivacy>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Public'),
                  subtitle: const Text('Anyone can join'),
                  value: RoomPrivacy.public,
                  groupValue: state.selectedPrivacy,
                  onChanged: (v) => viewModel.setPrivacy(v!),
                ),
                RadioListTile<RoomPrivacy>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Private'),
                  subtitle: const Text('Password protected'),
                  value: RoomPrivacy.private,
                  groupValue: state.selectedPrivacy,
                  onChanged: (v) => viewModel.setPrivacy(v!),
                ),
                if (state.selectedPrivacy == RoomPrivacy.private) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Password (Optional)',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: state.obscurePassword,
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          state.obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: viewModel.toggleObscurePassword,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _createRoom,
                    child: state.isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Create Room'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
