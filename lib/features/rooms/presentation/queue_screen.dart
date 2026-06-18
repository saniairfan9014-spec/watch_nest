import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'queue_viewmodel.dart';
import 'media_item_model.dart';

class QueueScreen extends ConsumerStatefulWidget {
  const QueueScreen({super.key});

  @override
  ConsumerState<QueueScreen> createState() => _QueueScreenState();
}

class _QueueScreenState extends ConsumerState<QueueScreen> {
  final _searchController = TextEditingController();
  bool _isEditing = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<bool> _confirmDelete(int index) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from Queue'),
        content: const Text('Are you sure you want to remove this item from the queue?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  void _showAddMediaSheet() {
    final viewModel = ref.read(queueViewModelProvider.notifier);
    _searchController.clear();
    viewModel.setSearchQuery('');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: _AddMediaSheetContent(
                searchController: _searchController,
                scrollController: scrollController,
                onAdd: (media) {
                  viewModel.addItem(media);
                  Navigator.of(context).pop();
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(queueViewModelProvider);
    final viewModel = ref.read(queueViewModelProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Queue'),
        actions: [
          if (state.items.isNotEmpty)
            TextButton(
              onPressed: () => setState(() => _isEditing = !_isEditing),
              child: Text(_isEditing ? 'Done' : 'Edit'),
            ),
        ],
      ),
      body: SafeArea(
        child: state.items.isEmpty
            ? _buildEmptyState()
            : Column(
                children: [
                  Expanded(child: _buildQueueList(state, viewModel)),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _showAddMediaSheet,
                        child: const Text('+ Add To Queue'),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_remove, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              'No media in queue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _showAddMediaSheet,
              child: const Text('Add First Media'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueList(QueueState state, QueueViewModel viewModel) {
    return ReorderableListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: state.items.length,
      onReorder: viewModel.reorder,
      itemBuilder: (context, index) {
        final item = state.items[index];
        return _QueueItemTile(
          key: ValueKey(item.id),
          position: index + 1,
          title: item.title,
          addedBy: item.addedBy,
          isEditing: _isEditing,
          onDelete: () async {
            final confirmed = await _confirmDelete(index);
            if (confirmed) viewModel.removeItem(index);
          },
        );
      },
    );
  }
}

class _QueueItemTile extends StatelessWidget {
  final int position;
  final String title;
  final String addedBy;
  final bool isEditing;
  final VoidCallback onDelete;

  const _QueueItemTile({
    super.key,
    required this.position,
    required this.title,
    required this.addedBy,
    required this.isEditing,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              backgroundColor: Colors.grey.shade200,
              radius: 18,
              child: Text(
                '$position',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 40,
              height: 40,
              color: Colors.grey.shade300,
              child: Icon(Icons.movie_outlined, color: Colors.grey.shade500, size: 20),
            ),
          ],
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text('Added By: $addedBy'),
        trailing: isEditing
            ? IconButton(
                icon: Icon(Icons.delete_outline, color: Colors.red.shade400),
                onPressed: onDelete,
              )
            : const Icon(Icons.drag_handle),
      ),
    );
  }
}

class _AddMediaSheetContent extends ConsumerWidget {
  final TextEditingController searchController;
  final ScrollController scrollController;
  final void Function(MediaItem) onAdd;

  const _AddMediaSheetContent({
    required this.searchController,
    required this.scrollController,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(queueViewModelProvider);
    final viewModel = ref.read(queueViewModelProvider.notifier);
    final filtered = state.filteredMedia;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: const InputDecoration(
              hintText: 'Search media...',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: viewModel.setSearchQuery,
          ),
          const SizedBox(height: 12),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Text(
                      'No results found',
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  )
                : ListView.builder(
                    controller: scrollController,
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final media = filtered[index];
                      return ListTile(
                        leading: Container(
                          width: 48,
                          height: 48,
                          color: Colors.grey.shade300,
                          child: Icon(Icons.movie_outlined, color: Colors.grey.shade500),
                        ),
                        title: Text(media.title),
                        subtitle: Text(media.duration),
                        trailing: IconButton(
                          icon: const Icon(Icons.add_circle_outline),
                          onPressed: () => onAdd(media),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
