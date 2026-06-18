import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/room_model.dart';
import '../../rooms/data/room_repository.dart';

final roomsProvider = FutureProvider.autoDispose<List<RoomModel>>((ref) {
  return ref.watch(roomRepositoryProvider).fetchRooms();
});

class HomeState {
  final bool isRefreshing;
  final String? error;

  const HomeState({this.isRefreshing = false, this.error});

  HomeState copyWith({bool? isRefreshing, String? error}) {
    return HomeState(
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: error,
    );
  }
}

final homeControllerProvider =
    NotifierProvider<HomeController, HomeState>(HomeController.new);

class HomeController extends Notifier<HomeState> {
  @override
  HomeState build() => const HomeState();

  Future<void> refresh() async {
    state = state.copyWith(isRefreshing: true);
    try {
      ref.invalidate(roomsProvider);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    } finally {
      state = state.copyWith(isRefreshing: false);
    }
  }
}
