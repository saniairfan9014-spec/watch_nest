import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'family_watch_room_viewmodel.dart';
import 'family_watch_room_state.dart';
import '../models/voice_seat_model.dart';
import '../models/room_activity_model.dart';
import '../theme/room_theme_config.dart';
import '../theme/room_theme_manager.dart';
import '../../rooms/presentation/room_type.dart';
import 'widgets/movie_player_widget.dart';
import 'widgets/queue_panel.dart';

class FamilyWatchRoomScreen extends ConsumerStatefulWidget {
  final String roomId;

  const FamilyWatchRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<FamilyWatchRoomScreen> createState() =>
      _FamilyWatchRoomScreenState();
}

class _FamilyWatchRoomScreenState
    extends ConsumerState<FamilyWatchRoomScreen> {
  final _chatScrollController = ScrollController();
  final _messageController = TextEditingController();
  final _announcementController = TextEditingController();
  final _searchController = TextEditingController();
  final _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(familyWatchRoomViewModelProvider.notifier).loadRoom(widget.roomId);
    });
  }

  @override
  void dispose() {
    _chatScrollController.dispose();
    _messageController.dispose();
    _announcementController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  final _themeManager = RoomThemeManager();

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyWatchRoomViewModelProvider);
    final viewModel = ref.read(familyWatchRoomViewModelProvider.notifier);

    if (state.isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.amber)),
      );
    }
    final theme = _themeManager.getConfig(state.room.roomType);

    if (state.isEditingAnnouncement &&
        _announcementController.text != state.announcementDraft) {
      _announcementController.text = state.announcementDraft;
    }

    final room = state.room;

    return PopScope(
      canPop: true,
      onPopInvoked: (didPop) {
        ref.read(familyWatchRoomViewModelProvider.notifier).leaveRoom();
      },
      child: Scaffold(
        appBar: _buildAppBar(room, theme),
      body: Stack(
        children: [
          SafeArea(
            child: _buildRoomContent(state, viewModel, theme),
          ),
          if (state.showMembersPanel) _buildMembersPanel(state, viewModel),
          if (state.showInvitePanel) _buildInvitePanel(viewModel),
          if (state.showSettingsPanel) _buildSettingsPanel(viewModel),
          if (state.showSocialPanel) _buildSocialPanel(state, viewModel),
          if (state.showQueuePanel)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.55,
                child: const QueuePanel(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(state, viewModel, theme),
    ),
  );
  }

  Widget _buildRoomContent(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    switch (state.room.roomType) {
      case RoomType.movie:
        return _buildMovieModeContent(state, viewModel, theme);
      default:
        return _buildDefaultModeContent(state, viewModel, theme);
    }
  }

  Widget _buildMovieModeContent(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Column(
      children: [
        const MoviePlayerWidget(),
        // Main scrollable content
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- Inline Queue Section (visible to everyone) ---
                _buildInlineQueueSection(state, viewModel, theme),
                const SizedBox(height: 16),
                _buildVoiceSeatsGrid(state, viewModel, theme),
                const SizedBox(height: 16),
                _buildChatSection(state, viewModel, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineQueueSection(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    final queue = state.room.queue;
    final isHost = state.room.isHost;
    final currentItemId = state.room.playbackState?.currentQueueItemId;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.queue_music, size: 18, color: theme.primarySwatch.shade700),
            const SizedBox(width: 6),
            Text(
              'Queue',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.primarySwatch.shade700,
              ),
            ),
            const Spacer(),
            Text(
              '${queue.length} video${queue.length == 1 ? '' : 's'}',
              style: TextStyle(fontSize: 12, color: theme.primarySwatch.shade400),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // --- Add Video Form (all users) ---
        _QueueAddForm(viewModel: viewModel, theme: theme),

        const SizedBox(height: 10),

        // --- Queue List ---
        if (queue.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: theme.primarySwatch.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Icon(Icons.playlist_add, size: 40, color: theme.primarySwatch.shade300),
                const SizedBox(height: 8),
                Text(
                  'No videos in queue yet',
                  style: TextStyle(color: theme.primarySwatch.shade400, fontSize: 14),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: queue.length,
            separatorBuilder: (_, __) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final item = queue[index];
              final isCurrent = item.id == currentItemId;
              return Container(
                decoration: BoxDecoration(
                  color: isCurrent
                      ? Colors.amber.withValues(alpha: 0.12)
                      : theme.primarySwatch.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: isCurrent
                      ? Border.all(color: Colors.amber.shade600, width: 1.5)
                      : Border.all(color: theme.primarySwatch.shade100),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  leading: Container(
                    width: 48,
                    height: 36,
                    decoration: BoxDecoration(
                      color: theme.primarySwatch.shade100,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: isCurrent
                        ? const Icon(Icons.equalizer, color: Colors.amber, size: 20)
                        : Icon(Icons.play_circle_outline, color: theme.primarySwatch.shade400, size: 20),
                  ),
                  title: Text(
                    item.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.normal,
                      color: isCurrent ? Colors.amber.shade800 : theme.primarySwatch.shade800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    isCurrent ? '▶ Now Playing' : '#${index + 1}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isCurrent ? Colors.amber.shade700 : theme.primarySwatch.shade400,
                    ),
                  ),
                  trailing: isHost
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (!isCurrent)
                              GestureDetector(
                                onTap: () => viewModel.updatePlaybackState(
                                  currentQueueItemId: item.id,
                                  isPlaying: true,
                                  currentPosition: 0,
                                ),
                                child: Icon(Icons.play_arrow, color: Colors.green.shade600, size: 22),
                              ),
                            const SizedBox(width: 6),
                            GestureDetector(
                              onTap: () => viewModel.removeFromQueue(item.id),
                              child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 20),
                            ),
                          ],
                        )
                      : null,
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildDefaultModeContent(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // If general mode, show mode selector
                if (state.room.roomType == RoomType.general) ...[
                  _buildGeneralModeSelector(state, viewModel, theme),
                  const SizedBox(height: 16),
                ],
                _buildVoiceSeatsGrid(state, viewModel, theme),
                const SizedBox(height: 16),
                _buildAnnouncementSection(state, viewModel, theme),
                const SizedBox(height: 16),
                _buildChatSection(state, viewModel, theme),
                const SizedBox(height: 16),
                _buildActivitySection(state.room, theme),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGeneralModeSelector(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.primarySwatch.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.primarySwatch.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Choose Room Mode',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.primarySwatch.shade700),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildModeCard(
                  icon: Icons.movie,
                  label: 'Movie Mode',
                  color: Colors.deepPurple,
                  onTap: () {
                    if (state.room.isHost) {
                      viewModel.setRoomType(RoomType.movie);
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildModeCard(
                  icon: Icons.music_note,
                  label: 'Music Mode',
                  color: Colors.pink,
                  onTap: () {
                    if (state.room.isHost) {
                      viewModel.setRoomType(RoomType.music);
                    }
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildModeCard({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontWeight: FontWeight.w600, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(room, RoomThemeConfig theme) {
    return AppBar(
      backgroundColor: theme.primarySwatch,
      foregroundColor: Colors.white,
      title: Text(
        room.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        InkWell(
          onTap: () => ref
              .read(familyWatchRoomViewModelProvider.notifier)
              .toggleMembersPanel(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, size: 20),
                const SizedBox(height: 2),
                Text(
                  '${room.members.length}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
        if (room.isHost)
          IconButton(
            icon: Icon(room.micLocked ? Icons.lock : Icons.lock_open),
            onPressed: () {
              ref.read(familyWatchRoomViewModelProvider.notifier).lockAllSeats(!room.micLocked);
            },
            tooltip: room.micLocked ? 'Unlock Mics' : 'Lock Mics',
          ),
        PopupMenuButton<String>(
          onSelected: (value) {
            final vm = ref.read(familyWatchRoomViewModelProvider.notifier);
            if (value == 'invite') vm.toggleInvitePanel();
            if (value == 'settings') vm.toggleSettingsPanel();
            if (value == 'leave') {
              vm.leaveRoom();
              context.go('/home');
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(value: 'invite', child: Text('Invite')),
            const PopupMenuItem(value: 'settings', child: Text('Settings')),
            const PopupMenuItem(
              value: 'leave',
              child: Text('Leave Room', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ],
    );
  }



  Widget _buildVoiceSeatsGrid(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Voice Seats',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.primarySwatch.shade700),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            childAspectRatio: 0.85,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: state.room.seats.length,
          itemBuilder: (context, index) {
            return _buildSeatCard(
              state.room.seats[index],
              state.room.isHost,
              state.room.currentUserId,
              viewModel,
              theme,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeatCard(VoiceSeat seat, bool isHost, String currentUserId, viewModel, RoomThemeConfig theme) {
    final isOccupied = seat.status == SeatStatus.occupied;
    final isEmpty = seat.status == SeatStatus.empty;
    final isLocked = seat.status == SeatStatus.locked;

    return GestureDetector(
      onTap: () => _showMicActionsBottomSheet(context, seat, isHost, currentUserId, viewModel, theme),
      child: Container(
        decoration: BoxDecoration(
          color: isOccupied
              ? theme.seatOccupiedColor
              : isLocked
                  ? theme.seatLockedColor
                  : theme.seatEmptyColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isOccupied
                ? theme.primarySwatch.shade200
                : isLocked
                    ? theme.seatLockedColor
                    : theme.primarySwatch.shade100,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${seat.seatNumber}',
              style: TextStyle(fontSize: 12, color: theme.primarySwatch.shade300),
            ),
            const SizedBox(height: 6),
            CircleAvatar(
              radius: 16,
              backgroundColor: isOccupied
                  ? theme.primarySwatch.shade200
                  : isLocked
                      ? theme.seatLockedColor
                      : theme.primarySwatch.shade100,
              backgroundImage: (isOccupied && seat.avatarUrl != null) ? NetworkImage(seat.avatarUrl!) : null,
              child: isOccupied && seat.avatarUrl == null
                  ? Text(
                      (seat.userName ?? '?')[0].toUpperCase(),
                      style: TextStyle(fontSize: 13, color: theme.primarySwatch.shade700),
                    )
                  : !isOccupied ? Icon(
                      isLocked ? Icons.lock : Icons.person_add,
                      size: 16,
                      color: theme.primarySwatch.shade400,
                    ) : null,
            ),
            const SizedBox(height: 4),
            if (isOccupied)
              Text(
                seat.userName ?? '',
                style: TextStyle(
                  fontSize: 10,
                  color: theme.primarySwatch.shade700,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            if (isOccupied)
              Icon(
                seat.isMuted ? Icons.mic_off : Icons.mic,
                size: 10,
                color: seat.isMuted ? Colors.red : Colors.green,
              ),
            if (isEmpty)
              Text(
                'Empty',
                style: TextStyle(fontSize: 10, color: theme.primarySwatch.shade300),
              ),
            if (isLocked)
              Text(
                'Locked',
                style: TextStyle(fontSize: 10, color: theme.seatLockedColor),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementSection(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Announcement',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.primarySwatch.shade700),
        ),
        const SizedBox(height: 8),
        if (state.isEditingAnnouncement)
          Column(
            children: [
              TextField(
                controller: _announcementController,
                onChanged: viewModel.setAnnouncementDraft,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: viewModel.cancelEditAnnouncement,
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: viewModel.saveAnnouncement,
                    child: const Text('Save'),
                  ),
                ],
              ),
            ],
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.primarySwatch.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    state.room.announcement.text,
                    style: TextStyle(
                      fontSize: 14,
                      color: theme.primarySwatch.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
                if (state.room.isHost)
                  IconButton(
                    icon: Icon(Icons.edit, size: 18, color: theme.accentColor),
                    onPressed: viewModel.startEditAnnouncement,
                  ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildChatSection(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    final messages = state.room.messages;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Chat',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.primarySwatch.shade700),
        ),
        const SizedBox(height: 8),
        if (messages.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No messages yet',
                style: TextStyle(color: theme.primarySwatch.shade300),
              ),
            ),
          )
        else
          SizedBox(
            height: 250,
            child: ListView.builder(
              controller: _chatScrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                final msg = messages[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundColor: theme.seatOccupiedColor,
                        backgroundImage: msg.senderAvatarUrl != null ? NetworkImage(msg.senderAvatarUrl!) : null,
                        child: msg.senderAvatarUrl == null ? Text(
                          msg.senderName[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primarySwatch.shade700,
                          ),
                        ) : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  msg.senderName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                    color: theme.primarySwatch.shade700,
                                  ),
                                ),
                                if (msg.isHost) ...[
                                  const SizedBox(width: 4),
                                  Icon(Icons.star,
                                      size: 11, color: theme.accentColor),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Host',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.accentColor,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                                const SizedBox(width: 8),
                                Text(
                                  _formatTimestamp(msg.timestamp),
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.primarySwatch.shade300,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              msg.text,
                              style: TextStyle(fontSize: 14, color: theme.primarySwatch.shade700),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildActivitySection(room, RoomThemeConfig theme) {
    final activities = room.activities;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Room Activity',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: theme.primarySwatch.shade700),
        ),
        const SizedBox(height: 8),
        if (activities.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No recent activity',
                style: TextStyle(color: theme.primarySwatch.shade300),
              ),
            ),
          )
        else
          ...activities.map((activity) {
            String actionText;
            switch (activity.type) {
              case ActivityType.like:
                actionText = 'liked this room ❤️';
                break;
              case ActivityType.join:
                actionText = 'joined the room';
                break;
              case ActivityType.leave:
                actionText = 'left the room';
                break;
              case ActivityType.announcement:
                actionText = 'updated the announcement';
                break;
              default:
                actionText = 'did something';
            }
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: theme.primarySwatch.shade100,
                    child: Text(
                      activity.userName[0],
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.primarySwatch.shade600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${activity.userName} $actionText',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.primarySwatch.shade700,
                      ),
                    ),
                  ),
                  Text(
                    _formatTimestamp(activity.timestamp),
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.primarySwatch.shade300,
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }

  Widget _buildSocialPanel(FamilyWatchRoomState state, viewModel) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.8,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: DefaultTabController(
            length: 3,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(color: Colors.grey.shade200),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Social',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: viewModel.closeAllPanels,
                      ),
                    ],
                  ),
                ),
                const TabBar(
                  tabs: [
                    Tab(text: 'Friends'),
                    Tab(text: 'Requests'),
                    Tab(text: 'Online'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      _buildFriendsTab(state, viewModel),
                      _buildRequestsTab(state, viewModel),
                      _buildOnlineTab(state, viewModel),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFriendsTab(FamilyWatchRoomState state, viewModel) {
    final friends = state.friends;
    if (friends.isEmpty) {
      return Center(
        child: Text('No friends yet', style: TextStyle(color: Colors.grey.shade500)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: friends.length,
      itemBuilder: (context, index) {
        final friend = friends[index];
        final isFollowing = state.followedUserIds.contains(friend.id);
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(
              friend.name[0],
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          title: Text(friend.name),
          subtitle: Text('Score: ${friend.score}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.person_add_alt),
                tooltip: 'Invite to Room',
                onPressed: () => viewModel.inviteFriendToRoom(friend.id),
              ),
              IconButton(
                icon: Icon(
                  isFollowing ? Icons.favorite : Icons.favorite_border,
                  color: isFollowing ? Colors.red : null,
                ),
                onPressed: () => viewModel.toggleFollowUser(friend.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab(FamilyWatchRoomState state, viewModel) {
    final requests = state.friendRequests;
    if (requests.isEmpty) {
      return Center(
        child: Text(
          'No friend requests',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.grey.shade300,
            child: Text(
              request.name[0],
              style: TextStyle(color: Colors.grey.shade700),
            ),
          ),
          title: Text(request.name),
          subtitle: Text('Score: ${request.score}'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.check, color: Colors.green),
                onPressed: () => viewModel.acceptFriendRequest(request.id),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.red),
                onPressed: () => viewModel.declineFriendRequest(request.id),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOnlineTab(FamilyWatchRoomState state, viewModel) {
    final online = state.onlineFriends;
    if (online.isEmpty) {
      return Center(
        child: Text(
          'No friends online',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: online.length,
      itemBuilder: (context, index) {
        final friend = online[index];
        return ListTile(
          leading: Stack(
            children: [
              CircleAvatar(
                backgroundColor: Colors.grey.shade300,
                child: Text(
                  friend.name[0],
                  style: TextStyle(color: Colors.grey.shade700),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          title: Text(friend.name),
          subtitle: const Text('Online'),
          trailing: IconButton(
            icon: const Icon(Icons.person_add_alt),
            tooltip: 'Invite to Room',
            onPressed: () => viewModel.inviteFriendToRoom(friend.id),
          ),
        );
      },
    );
  }

  Widget _buildMembersPanel(FamilyWatchRoomState state, viewModel) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Members',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: viewModel.closeAllPanels,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.room.members.length,
                  itemBuilder: (context, index) {
                    final member = state.room.members[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.grey.shade300,
                        backgroundImage: member.avatarUrl != null ? NetworkImage(member.avatarUrl!) : null,
                        child: member.avatarUrl == null ? Text(
                          member.name[0].toUpperCase(),
                          style: TextStyle(color: Colors.grey.shade700),
                        ) : null,
                      ),
                      title: Row(
                        children: [
                          Text(member.name),
                          if (member.isHost) ...[
                            const SizedBox(width: 6),
                            Icon(Icons.star,
                                size: 14, color: Colors.amber.shade600),
                          ],
                        ],
                      ),
                      subtitle: Text('Score: ${member.score}'),
                      trailing: (state.room.isHost && member.id != state.room.currentUserId)
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.more_vert),
                              onSelected: (value) {
                                if (value == 'invite') {
                                  viewModel.inviteToMic(member.id);
                                } else if (value == 'transfer') {
                                  viewModel.transferHost(member.id);
                                }
                              },
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'invite',
                                  child: Text('Invite to Mic'),
                                ),
                                const PopupMenuItem(
                                  value: 'transfer',
                                  child: Text('Transfer Host'),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInvitePanel(viewModel) {
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Invite',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: viewModel.closeAllPanels,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Text(
                        'Share this room ID with friends:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                '25163166097',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.copy),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.share),
                        label: const Text('Share Invite Link'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsPanel(viewModel) {
    final state = ref.read(familyWatchRoomViewModelProvider);
    return Positioned(
      right: 0,
      top: 0,
      bottom: 0,
      width: MediaQuery.of(context).size.width * 0.75,
      child: Material(
        elevation: 8,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(color: Colors.grey.shade200),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Settings',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: viewModel.closeAllPanels,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    ListTile(
                      leading: const Icon(Icons.design_services_outlined),
                      title: const Text('Room Settings'),
                      subtitle: const Text('Name, type, privacy'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        viewModel.closeAllPanels();
                        context.push('/room/${state.room.id}/settings');
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.volume_up),
                      title: const Text('Voice Settings'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.notifications),
                      title: const Text('Notification Settings'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: const Icon(Icons.people),
                      title: const Text('Member Permissions'),
                      onTap: () {},
                    ),
                    ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.red),
                      title: const Text('Leave Room',
                          style: TextStyle(color: Colors.red)),
                      onTap: () {
                        viewModel.leaveRoom();
                        context.go('/home');
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(FamilyWatchRoomState state, viewModel, RoomThemeConfig theme) {
    return Container(
      padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 8),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: theme.primarySwatch.shade100)),
        color: theme.primarySwatch.shade50,
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: Icon(
                state.isSpeakerMuted ? Icons.volume_off : Icons.volume_up,
                color: state.isSpeakerMuted ? Colors.red : theme.accentColor,
              ),
              tooltip: state.isSpeakerMuted ? 'Unmute Speaker' : 'Mute Speaker',
              onPressed: viewModel.toggleSpeakerMute,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                state.isMuted ? Icons.mic_off : Icons.mic,
                color: state.isMuted ? Colors.red : theme.accentColor,
              ),
              onPressed: viewModel.toggleMute,
              tooltip: state.isMuted ? 'Unmute Mic' : 'Mute Mic',
            ),
            const SizedBox(width: 4),
            // Queue button (movie mode only)
            if (state.room.roomType == RoomType.movie)
              IconButton(
                icon: Icon(
                  Icons.queue_music,
                  color: state.showQueuePanel ? Colors.amber : theme.accentColor,
                ),
                tooltip: 'Queue',
                onPressed: viewModel.toggleQueuePanel,
              ),
            if (state.room.roomType == RoomType.movie)
              const SizedBox(width: 4),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(Icons.emoji_emotions_outlined, color: theme.accentColor),
                    onPressed: () {},
                  ),
                ),
                onChanged: viewModel.setChatInput,
                onSubmitted: (_) => _sendMessage(viewModel),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(Icons.sports_esports, color: theme.accentColor),
              tooltip: 'Games',
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }

  void _sendMessage(viewModel) {
    if (_messageController.text.trim().isEmpty) return;
    viewModel.sendMessage();
    _messageController.clear();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  void _showMicActionsBottomSheet(
    BuildContext context,
    VoiceSeat seat,
    bool isHost,
    String currentUserId,
    viewModel,
    RoomThemeConfig theme,
  ) {
    final isOccupied = seat.status == SeatStatus.occupied;
    final isEmpty = seat.status == SeatStatus.empty;
    final isLocked = seat.status == SeatStatus.locked;
    final isMyOwnSeat = seat.userId == currentUserId;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: theme.primarySwatch.shade50,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.primarySwatch.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            // Header
            Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: isOccupied
                      ? theme.seatOccupiedColor
                      : isLocked
                          ? theme.seatLockedColor
                          : theme.seatEmptyColor,
                  backgroundImage: (isOccupied && seat.avatarUrl != null)
                      ? NetworkImage(seat.avatarUrl!)
                      : null,
                  child: isOccupied && seat.avatarUrl == null
                      ? Text(
                          (seat.userName ?? '?')[0].toUpperCase(),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: theme.primarySwatch.shade700,
                          ),
                        )
                      : Icon(
                          isLocked ? Icons.lock : Icons.person_add,
                          size: 20,
                          color: theme.primarySwatch.shade400,
                        ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seat #${seat.seatNumber}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: theme.primarySwatch.shade800,
                      ),
                    ),
                    Text(
                      isOccupied
                          ? (seat.userName ?? 'Unknown')
                          : isLocked
                              ? 'Locked'
                              : 'Empty',
                      style: TextStyle(
                        fontSize: 13,
                        color: isLocked
                            ? theme.seatLockedColor
                            : theme.primarySwatch.shade400,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isOccupied
                        ? Colors.green.shade50
                        : isLocked
                            ? Colors.red.shade50
                            : theme.primarySwatch.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOccupied
                          ? Colors.green.shade200
                          : isLocked
                              ? Colors.red.shade200
                              : theme.primarySwatch.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isOccupied
                            ? Icons.radio_button_on
                            : isLocked
                                ? Icons.lock_outline
                                : Icons.radio_button_off,
                        size: 10,
                        color: isOccupied
                            ? Colors.green
                            : isLocked
                                ? Colors.red
                                : theme.primarySwatch.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOccupied
                            ? 'Live'
                            : isLocked
                                ? 'Locked'
                                : 'Empty',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isOccupied
                              ? Colors.green
                              : isLocked
                                  ? Colors.red
                                  : theme.primarySwatch.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Divider(height: 1, color: theme.primarySwatch.shade100),
            const SizedBox(height: 8),

            // --- MY OWN SEAT: Leave mic ---
            if (isMyOwnSeat && isOccupied)
              _micActionTile(
                icon: Icons.logout,
                iconColor: Colors.red,
                label: 'Leave Mic',
                subtitle: 'Free up this seat',
                theme: theme,
                onTap: () {
                  Navigator.pop(ctx);
                  viewModel.leaveSeat(seat.seatNumber);
                },
              ),

            // --- EMPTY SEAT: Grab mic (for users on allowed seats) ---
            if (isEmpty && !isHost)
              _micActionTile(
                icon: Icons.mic,
                iconColor: theme.accentColor,
                label: 'Grab the Mic',
                subtitle: 'Join this voice seat',
                theme: theme,
                onTap: () {
                  Navigator.pop(ctx);
                  viewModel.joinSeat(seat.seatNumber);
                },
              ),

            // --- HOST ACTIONS ---
            if (isHost) ...[
              // Grab seat 1 if it is empty
              if (isEmpty && seat.seatNumber == 1)
                _micActionTile(
                  icon: Icons.mic,
                  iconColor: theme.accentColor,
                  label: 'Grab the Mic',
                  subtitle: 'Take the host mic seat',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    viewModel.joinSeat(seat.seatNumber);
                  },
                ),

              // Lock / Unlock empty seat
              if (isEmpty)
                _micActionTile(
                  icon: Icons.lock_outline,
                  iconColor: Colors.orange,
                  label: 'Close Mic',
                  subtitle: 'Lock this seat so no one can join',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    viewModel.toggleLockSeat(seat.seatNumber);
                  },
                ),

              if (isLocked)
                _micActionTile(
                  icon: Icons.lock_open,
                  iconColor: Colors.green,
                  label: 'Open Mic',
                  subtitle: 'Unlock this seat so users can join',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    viewModel.toggleLockSeat(seat.seatNumber);
                  },
                ),

              // Invite a member to an empty seat
              if (isEmpty || isLocked)
                _micActionTile(
                  icon: Icons.person_add_alt_1,
                  iconColor: theme.primarySwatch,
                  label: 'Invite to Mic',
                  subtitle: 'Ask a member to join this seat',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    _showInviteToMicBottomSheet(context, seat.seatNumber, viewModel, theme);
                  },
                ),

              // Mute / Unmute occupied seat
              if (isOccupied && !isMyOwnSeat)
                _micActionTile(
                  icon: seat.isMuted ? Icons.mic : Icons.mic_off,
                  iconColor: seat.isMuted ? Colors.green : Colors.orange,
                  label: seat.isMuted ? 'Unmute User' : 'Mute User',
                  subtitle: seat.isMuted
                      ? 'Allow ${seat.userName ?? 'this user'} to speak'
                      : 'Silence ${seat.userName ?? 'this user'}',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    viewModel.toggleMuteUser(seat.seatNumber);
                  },
                ),

              // Remove user from occupied seat
              if (isOccupied && !isMyOwnSeat)
                _micActionTile(
                  icon: Icons.person_remove,
                  iconColor: Colors.red,
                  label: 'Remove from Mic',
                  subtitle: 'Kick ${seat.userName ?? 'this user'} off the seat',
                  theme: theme,
                  onTap: () {
                    Navigator.pop(ctx);
                    viewModel.leaveSeat(seat.seatNumber);
                  },
                ),
            ],

            // If nothing is applicable (viewer tapping occupied seat of another)
            if (!isHost && isOccupied && !isMyOwnSeat)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text(
                  'This seat is occupied',
                  style: TextStyle(
                    color: theme.primarySwatch.shade400,
                    fontSize: 14,
                  ),
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _micActionTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String subtitle,
    required RoomThemeConfig theme,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withAlpha(25),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: theme.primarySwatch.shade800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.primarySwatch.shade400,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.primarySwatch.shade300),
          ],
        ),
      ),
    );
  }

  void _showInviteToMicBottomSheet(
    BuildContext context,
    int seatNumber,
    viewModel,
    RoomThemeConfig theme,
  ) {
    final state = ref.read(familyWatchRoomViewModelProvider);
    // Filter: members not already on any seat
    final occupiedUserIds = state.room.seats
        .where((s) => s.status == SeatStatus.occupied && s.userId != null)
        .map((s) => s.userId!)
        .toSet();
    final invitable = state.room.members
        .where((m) => !occupiedUserIds.contains(m.id))
        .toList();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        minChildSize: 0.3,
        builder: (_, scrollController) => Container(
          decoration: BoxDecoration(
            color: theme.primarySwatch.shade50,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.primarySwatch.shade200,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Invite to Seat #$seatNumber',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: theme.primarySwatch.shade800,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: theme.primarySwatch.shade400),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, color: theme.primarySwatch.shade100),
              if (invitable.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people_outline,
                            size: 48, color: theme.primarySwatch.shade200),
                        const SizedBox(height: 12),
                        Text(
                          'All members are already on seats',
                          style: TextStyle(color: theme.primarySwatch.shade400),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    itemCount: invitable.length,
                    itemBuilder: (context, index) {
                      final member = invitable[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(14),
                            onTap: () {
                              Navigator.pop(ctx);
                              viewModel.inviteToMic(member.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Row(
                                    children: [
                                      Icon(Icons.mic, color: Colors.white, size: 18),
                                      const SizedBox(width: 8),
                                      Text('Invited ${member.name} to the mic!'),
                                    ],
                                  ),
                                  backgroundColor: theme.accentColor,
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 22,
                                    backgroundColor: theme.primarySwatch.shade100,
                                    backgroundImage: member.avatarUrl != null
                                        ? NetworkImage(member.avatarUrl!)
                                        : null,
                                    child: member.avatarUrl == null
                                        ? Text(
                                            member.name[0].toUpperCase(),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: theme.primarySwatch.shade700,
                                            ),
                                          )
                                        : null,
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              member.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.w600,
                                                color: theme.primarySwatch.shade800,
                                              ),
                                            ),
                                            if (member.isHost) ...[
                                              const SizedBox(width: 6),
                                              Icon(Icons.star,
                                                  size: 13,
                                                  color: Colors.amber.shade600),
                                            ],
                                          ],
                                        ),
                                        Text(
                                          '${member.score} pts',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: theme.primarySwatch.shade400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: theme.accentColor.withAlpha(25),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                          color: theme.accentColor.withAlpha(80)),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.mic,
                                            size: 14, color: theme.accentColor),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Invite',
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: theme.accentColor,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inline "Add Video to Queue" form — visible to ALL users (host + audience).
/// Handles URL extraction and submits via viewModel.addToQueue().
class _QueueAddForm extends ConsumerStatefulWidget {
  final dynamic viewModel;
  final RoomThemeConfig theme;

  const _QueueAddForm({required this.viewModel, required this.theme});

  @override
  ConsumerState<_QueueAddForm> createState() => _QueueAddFormState();
}

class _QueueAddFormState extends ConsumerState<_QueueAddForm> {
  final _urlController = TextEditingController();
  final _titleController = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _urlController.dispose();
    _titleController.dispose();
    super.dispose();
  }

  void _submit() {
    final url = _urlController.text.trim();
    final title = _titleController.text.trim();
    if (url.isEmpty) return;

    widget.viewModel.addToQueue(
      title: title.isEmpty ? 'Video' : title,
      mediaUrl: url,
    );

    _urlController.clear();
    _titleController.clear();
    setState(() => _expanded = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: theme.primarySwatch.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primarySwatch.shade200),
      ),
      child: _expanded
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.add_circle_outline, size: 16, color: theme.accentColor),
                      const SizedBox(width: 6),
                      Text(
                        'Add Video to Queue',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: theme.primarySwatch.shade700,
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => _expanded = false),
                        child: Icon(Icons.close, size: 18, color: theme.primarySwatch.shade400),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'YouTube URL or Video ID',
                      hintStyle: TextStyle(color: theme.primarySwatch.shade300, fontSize: 13),
                      prefixIcon: Icon(Icons.link, size: 18, color: theme.primarySwatch.shade400),
                      filled: true,
                      fillColor: theme.primarySwatch.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: 13, color: theme.primarySwatch.shade800),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'Title (optional)',
                      hintStyle: TextStyle(color: theme.primarySwatch.shade300, fontSize: 13),
                      prefixIcon: Icon(Icons.title, size: 18, color: theme.primarySwatch.shade400),
                      filled: true,
                      fillColor: theme.primarySwatch.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                    style: TextStyle(fontSize: 13, color: theme.primarySwatch.shade800),
                    onSubmitted: (_) => _submit(),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _submit,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add to Queue'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.accentColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : InkWell(
              onTap: () => setState(() => _expanded = true),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline, size: 20, color: theme.accentColor),
                    const SizedBox(width: 10),
                    Text(
                      'Add Video to Queue',
                      style: TextStyle(
                        color: theme.accentColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                    const Spacer(),
                    Icon(Icons.keyboard_arrow_down, size: 20, color: theme.primarySwatch.shade400),
                  ],
                ),
              ),
            ),
    );
  }
}
