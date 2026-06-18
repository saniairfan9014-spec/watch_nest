import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'queue_item_model.dart';
import 'media_item_model.dart';

class QueueState {
  final List<QueueItem> items;
  final List<MediaItem> availableMedia;
  final String searchQuery;

  const QueueState({
    this.items = const [],
    this.availableMedia = const [],
    this.searchQuery = '',
  });

  List<MediaItem> get filteredMedia {
    if (searchQuery.isEmpty) return availableMedia;
    return availableMedia
        .where((m) => m.title.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();
  }

  QueueState copyWith({
    List<QueueItem>? items,
    List<MediaItem>? availableMedia,
    String? searchQuery,
  }) {
    return QueueState(
      items: items ?? this.items,
      availableMedia: availableMedia ?? this.availableMedia,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class QueueViewModel extends Notifier<QueueState> {
  @override
  QueueState build() {
    return QueueState(
      items: const [
        QueueItem(id: '1', title: 'Spider-Man: No Way Home', addedBy: 'Ali'),
        QueueItem(id: '2', title: 'The Dark Knight', addedBy: 'Sara'),
        QueueItem(id: '3', title: 'Avengers: Endgame', addedBy: 'Ahmed'),
        QueueItem(id: '4', title: 'Interstellar', addedBy: 'Dad'),
      ],
      availableMedia: const [
        MediaItem(id: '101', title: 'Inception', duration: '2:28:00'),
        MediaItem(id: '102', title: 'The Matrix', duration: '2:16:00'),
        MediaItem(id: '103', title: 'Parasite', duration: '2:12:00'),
        MediaItem(id: '104', title: 'Tenet', duration: '2:30:00'),
        MediaItem(id: '105', title: 'Dune', duration: '2:35:00'),
      ],
    );
  }

  void reorder(int oldIndex, int newIndex) {
    final items = [...state.items];
    final item = items.removeAt(oldIndex);
    items.insert(newIndex, item);
    state = state.copyWith(items: items);
  }

  void removeItem(int index) {
    final items = [...state.items]..removeAt(index);
    state = state.copyWith(items: items);
  }

  void addItem(MediaItem media) {
    final newItem = QueueItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: media.title,
      addedBy: 'You',
    );
    state = state.copyWith(items: [...state.items, newItem]);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }
}

final queueViewModelProvider =
    NotifierProvider.autoDispose<QueueViewModel, QueueState>(
  QueueViewModel.new,
);
