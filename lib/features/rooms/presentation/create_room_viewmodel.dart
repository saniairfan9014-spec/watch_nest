import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'room_type.dart';
import 'room_privacy.dart';
import '../data/room_repository.dart';

class CreateRoomState {
  final RoomType selectedType;
  final RoomPrivacy selectedPrivacy;
  final bool obscurePassword;
  final bool isLoading;

  const CreateRoomState({
    this.selectedType = RoomType.family,
    this.selectedPrivacy = RoomPrivacy.public,
    this.obscurePassword = true,
    this.isLoading = false,
  });

  CreateRoomState copyWith({
    RoomType? selectedType,
    RoomPrivacy? selectedPrivacy,
    bool? obscurePassword,
    bool? isLoading,
  }) {
    return CreateRoomState(
      selectedType: selectedType ?? this.selectedType,
      selectedPrivacy: selectedPrivacy ?? this.selectedPrivacy,
      obscurePassword: obscurePassword ?? this.obscurePassword,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CreateRoomViewModel extends Notifier<CreateRoomState> {
  @override
  CreateRoomState build() => const CreateRoomState();

  void setRoomType(RoomType type) {
    state = state.copyWith(selectedType: type);
  }

  void setPrivacy(RoomPrivacy privacy) {
    state = state.copyWith(selectedPrivacy: privacy);
  }

  void toggleObscurePassword() {
    state = state.copyWith(obscurePassword: !state.obscurePassword);
  }

  Future<void> createRoom({
    required String name,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      await ref.read(roomRepositoryProvider).createRoom(
        name: name,
        hostId: user.id,
        roomType: state.selectedType,
        isPrivate: state.selectedPrivacy == RoomPrivacy.private,
        password: state.selectedPrivacy == RoomPrivacy.private ? password : null,
      );
    } catch (e) {
      rethrow;
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final createRoomViewModelProvider =
    NotifierProvider<CreateRoomViewModel, CreateRoomState>(
  CreateRoomViewModel.new,
);
