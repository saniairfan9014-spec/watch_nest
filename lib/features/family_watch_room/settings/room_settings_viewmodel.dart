import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../rooms/presentation/room_type.dart';
import '../../../core/network/supabase_client.dart';

class RoomSettingsState {
  final RoomType selectedType;
  final String roomName;
  final String roomDescription;
  final bool isPrivate;
  final bool isLoading;
  final bool isSaved;

  const RoomSettingsState({
    this.selectedType = RoomType.general,
    this.roomName = '',
    this.roomDescription = '',
    this.isPrivate = false,
    this.isLoading = false,
    this.isSaved = false,
  });

  RoomSettingsState copyWith({
    RoomType? selectedType,
    String? roomName,
    String? roomDescription,
    bool? isPrivate,
    bool? isLoading,
    bool? isSaved,
  }) {
    return RoomSettingsState(
      selectedType: selectedType ?? this.selectedType,
      roomName: roomName ?? this.roomName,
      roomDescription: roomDescription ?? this.roomDescription,
      isPrivate: isPrivate ?? this.isPrivate,
      isLoading: isLoading ?? this.isLoading,
      isSaved: isSaved ?? this.isSaved,
    );
  }
}

class RoomSettingsViewModel extends Notifier<RoomSettingsState> {
  @override
  RoomSettingsState build() => const RoomSettingsState();

  void setRoomType(RoomType type) {
    state = state.copyWith(selectedType: type);
  }

  void setRoomName(String value) {
    state = state.copyWith(roomName: value);
  }

  void setRoomDescription(String value) {
    state = state.copyWith(roomDescription: value);
  }

  void setPrivacy(bool value) {
    state = state.copyWith(isPrivate: value);
  }

  Future<void> saveSettings(String roomId) async {
    state = state.copyWith(isLoading: true);

    try {
      // Bypass backend update for dummy rooms (which don't have valid UUIDs)
      if (!roomId.startsWith('room-')) {
        final client = ref.read(supabaseClientProvider);
        await client.from('rooms').update({
          'room_type': state.selectedType.name,
          'name': state.roomName,
          'is_private': state.isPrivate,
        }).eq('id', roomId);
      }

      state = state.copyWith(isSaved: true, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false);
      rethrow;
    }
  }
}

final roomSettingsViewModelProvider =
    NotifierProvider<RoomSettingsViewModel, RoomSettingsState>(
  RoomSettingsViewModel.new,
);
