import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'room_details_viewmodel.dart';

class RoomDetailsScreen extends ConsumerStatefulWidget {
  final String roomId;

  const RoomDetailsScreen({super.key, required this.roomId});

  @override
  ConsumerState<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends ConsumerState<RoomDetailsScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(roomDetailsViewModelProvider);
    final viewModel = ref.read(roomDetailsViewModelProvider.notifier);
    final room = state.room;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              room.name,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              '${room.roomType?.name.toUpperCase() ?? 'General'} Mode • ${room.currentMemberCount} Members',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_alt),
            onPressed: () {},
            tooltip: 'Invite Members',
          ),
        ],
      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: _buildMediaPlayer(state),
              ),
              SliverToBoxAdapter(
                child: _buildCurrentlyPlaying(state),
              ),
              SliverToBoxAdapter(
                child: _buildPlaybackControls(state, viewModel),
              ),
            ];
          },
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                tabs: const [
                  Tab(text: 'Queue'),
                  Tab(text: 'Chat'),
                  Tab(text: 'Members'),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildQueueTab(state),
                    _buildChatTab(state, viewModel),
                    _buildMembersTab(state),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMediaPlayer(RoomDetailsState state) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.grey.shade900,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.movie_outlined, size: 64, color: Colors.grey.shade600),
                const SizedBox(height: 12),
                Text(
                  'Current Position: ${_formatDuration(state.currentPosition)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: ${_formatDuration(state.totalDuration)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentlyPlaying(RoomDetailsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No media playing',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  state.isPlaying ? 'Now Playing' : 'Paused',
                  style: TextStyle(
                    fontSize: 14,
                    color: state.isPlaying ? Colors.green : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(
    RoomDetailsState state,
    RoomDetailsViewModel viewModel,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.replay_10),
            iconSize: 36,
            onPressed: viewModel.rewind10,
            tooltip: 'Rewind 10s',
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: Icon(
              state.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
              size: 56,
            ),
            onPressed: viewModel.togglePlayPause,
          ),
          const SizedBox(width: 24),
          IconButton(
            icon: const Icon(Icons.forward_10),
            iconSize: 36,
            onPressed: viewModel.forward10,
            tooltip: 'Forward 10s',
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab(RoomDetailsState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.queue.length,
      itemBuilder: (context, index) {
        final item = state.queue[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text(
              '${item.position}',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          title: Text(item.title),
          subtitle: Text('Added by ${item.addedBy}'),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }

  Widget _buildChatTab(RoomDetailsState state, RoomDetailsViewModel viewModel) {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: state.messages.length,
            itemBuilder: (context, index) {
              final message = state.messages[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          message.senderName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _formatTimestamp(message.timestamp),
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message.text,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    hintText: 'Type a message...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.send),
                onPressed: () {
                  viewModel.sendMessage(_messageController.text);
                  _messageController.clear();
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMembersTab(RoomDetailsState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.members.length,
      itemBuilder: (context, index) {
        final member = state.members[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade200,
            child: Text(
              member.name[0].toUpperCase(),
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          title: Text(member.name),
          subtitle: Text(member.role),
        );
      },
    );
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
