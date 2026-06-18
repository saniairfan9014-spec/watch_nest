import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'music_track_model.dart';
import 'music_room_viewmodel.dart';

class MusicRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const MusicRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<MusicRoomScreen> createState() => _MusicRoomScreenState();
}

class _MusicRoomScreenState extends ConsumerState<MusicRoomScreen>
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
    final minutes = d.inMinutes.remainder(60);
    final seconds = d.inSeconds.remainder(60);
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(musicRoomViewModelProvider);
    final viewModel = ref.read(musicRoomViewModelProvider.notifier);
    final track = state.currentTrack;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Music & Chill',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            Text(
              'Music Mode • 5 Members',
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
              SliverToBoxAdapter(child: _buildNowPlaying(state, track)),
              SliverToBoxAdapter(child: _buildProgress(state, viewModel, track)),
              SliverToBoxAdapter(child: _buildPlaybackControls(state, viewModel)),
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

  Widget _buildNowPlaying(MusicRoomState state, dynamic track) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 200,
            height: 200,
            color: Colors.grey.shade900,
            child: Center(
              child: Icon(Icons.music_note, size: 80, color: Colors.grey.shade600),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            track.title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            track.artist,
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildProgress(MusicRoomState state, MusicRoomViewModel viewModel, MusicTrack track) {
    final maxMs = track.duration.inMilliseconds.toDouble();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          Slider(
            value: state.currentPosition.inMilliseconds.toDouble().clamp(
                  0, maxMs).toDouble(),
            max: maxMs,
            onChanged: (value) {
              viewModel.seekTo(value / maxMs);
            },
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.currentPosition),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                Text(
                  _formatDuration(track.duration),
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaybackControls(MusicRoomState state, MusicRoomViewModel viewModel) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.skip_previous),
            iconSize: 36,
            onPressed: viewModel.previousTrack,
            tooltip: 'Previous Track',
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
            icon: const Icon(Icons.skip_next),
            iconSize: 36,
            onPressed: viewModel.nextTrack,
            tooltip: 'Next Track',
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTab(MusicRoomState state) {
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
          subtitle: Text(item.artist),
          trailing: const Icon(Icons.drag_handle),
        );
      },
    );
  }

  Widget _buildChatTab(MusicRoomState state, MusicRoomViewModel viewModel) {
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

  Widget _buildMembersTab(MusicRoomState state) {
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
