import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../family_watch_room_viewmodel.dart';
import '../../models/media_queue_item_model.dart';

class QueuePanel extends ConsumerStatefulWidget {
  const QueuePanel({super.key});

  @override
  ConsumerState<QueuePanel> createState() => _QueuePanelState();
}

class _QueuePanelState extends ConsumerState<QueuePanel> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _showAddForm = false;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyWatchRoomViewModelProvider);
    final viewModel = ref.read(familyWatchRoomViewModelProvider.notifier);
    final queue = state.room.queue;
    final isHost = state.room.isHost;
    final currentItemId = state.room.playbackState?.currentQueueItemId;

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // --- Header ---
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey.shade800,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.queue_music, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Queue',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${queue.length} video${queue.length == 1 ? '' : 's'}',
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white, size: 20),
                  onPressed: viewModel.toggleQueuePanel,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // --- Add To Queue Button ---
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _showAddForm ? _buildAddForm(viewModel) : _buildAddButton(),
          ),

          // --- Queue List ---
          if (queue.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Column(
                children: [
                  Icon(Icons.playlist_add, size: 48, color: Colors.grey.shade600),
                  const SizedBox(height: 8),
                  Text(
                    'Queue is empty',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Add a video to get started',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            )
          else
            Flexible(
              child: isHost
                  ? ReorderableListView.builder(
                      shrinkWrap: true,
                      itemCount: queue.length,
                      onReorder: (oldIndex, newIndex) {
                        if (newIndex > oldIndex) newIndex -= 1;
                        viewModel.reorderQueue(oldIndex, newIndex);
                      },
                      itemBuilder: (context, index) {
                        return _buildQueueItem(
                          key: ValueKey(queue[index].id),
                          item: queue[index],
                          index: index,
                          isHost: isHost,
                          isCurrent: queue[index].id == currentItemId,
                          viewModel: viewModel,
                        );
                      },
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: queue.length,
                      itemBuilder: (context, index) {
                        return _buildQueueItem(
                          key: ValueKey(queue[index].id),
                          item: queue[index],
                          index: index,
                          isHost: isHost,
                          isCurrent: queue[index].id == currentItemId,
                          viewModel: viewModel,
                        );
                      },
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildAddButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => setState(() => _showAddForm = true),
        icon: const Icon(Icons.add, size: 18),
        label: const Text('Add Video'),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.amber,
          side: BorderSide(color: Colors.amber.shade700),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }

  Widget _buildAddForm(viewModel) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _titleController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Video title',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _urlController,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'YouTube URL or Video ID',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.grey.shade700,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _showAddForm = false;
                    _urlController.clear();
                    _titleController.clear();
                  });
                },
                child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  final url = _urlController.text.trim();
                  final title = _titleController.text.trim();
                  if (url.isEmpty) return;

                  viewModel.addToQueue(
                    title: title.isEmpty ? 'Untitled Video' : title,
                    mediaUrl: url,
                  );

                  setState(() {
                    _showAddForm = false;
                    _urlController.clear();
                    _titleController.clear();
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Add'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQueueItem({
    required Key key,
    required MediaQueueItem item,
    required int index,
    required bool isHost,
    required bool isCurrent,
    required viewModel,
  }) {
    return Container(
      key: key,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isCurrent ? Colors.amber.withOpacity(0.15) : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(10),
        border: isCurrent
            ? Border.all(color: Colors.amber.shade700, width: 1.5)
            : null,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        leading: Container(
          width: 50,
          height: 38,
          decoration: BoxDecoration(
            color: Colors.grey.shade700,
            borderRadius: BorderRadius.circular(6),
            image: item.thumbnailUrl != null
                ? DecorationImage(
                    image: NetworkImage(item.thumbnailUrl!),
                    fit: BoxFit.cover,
                  )
                : null,
          ),
          child: item.thumbnailUrl == null
              ? Icon(Icons.play_circle_fill, color: Colors.grey.shade500, size: 24)
              : null,
        ),
        title: Text(
          item.title,
          style: TextStyle(
            color: isCurrent ? Colors.amber : Colors.white,
            fontSize: 14,
            fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (isCurrent) ...[
              const Icon(Icons.equalizer, size: 12, color: Colors.amber),
              const SizedBox(width: 4),
              const Text(
                'Now Playing',
                style: TextStyle(color: Colors.amber, fontSize: 11),
              ),
            ] else
              Text(
                '#${index + 1}',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
          ],
        ),
        trailing: isHost
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCurrent)
                    IconButton(
                      icon: const Icon(Icons.play_arrow, color: Colors.green, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        viewModel.updatePlaybackState(
                          currentQueueItemId: item.id,
                          isPlaying: true,
                          currentPosition: 0,
                        );
                      },
                      tooltip: 'Play now',
                    ),
                  const SizedBox(width: 4),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () => viewModel.removeFromQueue(item.id),
                    tooltip: 'Remove',
                  ),
                  if (isHost) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.drag_handle, color: Colors.grey.shade500, size: 20),
                  ],
                ],
              )
            : null,
      ),
    );
  }
}
