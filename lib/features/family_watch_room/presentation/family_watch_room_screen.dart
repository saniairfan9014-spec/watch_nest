import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'family_watch_room_viewmodel.dart';
import 'family_watch_room_state.dart';
import '../models/voice_seat_model.dart';
import '../models/room_activity_model.dart';
import '../theme/room_theme_config.dart';
import '../theme/room_theme_manager.dart';

class FamilyWatchRoomScreen extends ConsumerStatefulWidget {
  const FamilyWatchRoomScreen({super.key});

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
    final theme = _themeManager.getConfig(state.room.roomType);

    if (state.isEditingAnnouncement &&
        _announcementController.text != state.announcementDraft) {
      _announcementController.text = state.announcementDraft;
    }

    final room = state.room;

    return Scaffold(
      appBar: _buildAppBar(room, theme),
      body: Stack(
        children: [
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildVoiceSeatsGrid(state, viewModel, theme),
                        const SizedBox(height: 16),
                        _buildAnnouncementSection(state, viewModel, theme),
                        const SizedBox(height: 16),
                        _buildChatSection(state, viewModel, theme),
                        const SizedBox(height: 16),
                        _buildActivitySection(room, theme),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (state.showMembersPanel) _buildMembersPanel(state, viewModel),
          if (state.showInvitePanel) _buildInvitePanel(viewModel),
          if (state.showSettingsPanel) _buildSettingsPanel(viewModel),
          if (state.showSocialPanel) _buildSocialPanel(state, viewModel),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(state, viewModel, theme),
    );
  }

  PreferredSizeWidget _buildAppBar(room, RoomThemeConfig theme) {
    return AppBar(
      backgroundColor: theme.primarySwatch,
      foregroundColor: Colors.white,
      automaticallyImplyLeading: false,
      title: Text(
        room.name,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.people_outline),
          tooltip: 'Members (${room.members.length})',
          onPressed: () => ref
              .read(familyWatchRoomViewModelProvider.notifier)
              .toggleMembersPanel(),
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
              viewModel,
              theme,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSeatCard(VoiceSeat seat, bool isHost, viewModel, RoomThemeConfig theme) {
    final isOccupied = seat.status == SeatStatus.occupied;
    final isEmpty = seat.status == SeatStatus.empty;
    final isLocked = seat.status == SeatStatus.locked;

    return GestureDetector(
      onTap: () {
        if (isEmpty) {
          viewModel.joinSeat(seat.seatNumber);
        } else if (isOccupied) {
          if (isHost) {
            viewModel.toggleMuteUser(seat.seatNumber);
          }
        } else if (isLocked && isHost) {
          viewModel.toggleLockSeat(seat.seatNumber);
        }
      },
      onLongPress: () {
        if (isHost && isOccupied) {
          viewModel.leaveSeat(seat.seatNumber);
        }
        if (isHost && isLocked) {
          viewModel.toggleLockSeat(seat.seatNumber);
        }
      },
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
              child: isOccupied
                  ? Text(
                      (seat.userName ?? '?')[0],
                      style: TextStyle(fontSize: 13, color: theme.primarySwatch.shade700),
                    )
                  : Icon(
                      isLocked ? Icons.lock : Icons.person_add,
                      size: 16,
                      color: theme.primarySwatch.shade400,
                    ),
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
                        child: Text(
                          msg.senderName[0],
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.primarySwatch.shade700,
                          ),
                        ),
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
                        child: Text(
                          member.name[0],
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
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
              icon: Icon(Icons.volume_up, color: theme.accentColor),
              tooltip: 'Speaker',
              onPressed: () {},
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: Icon(
                state.isMuted ? Icons.mic_off : Icons.mic,
                color: state.isMuted ? Colors.red : theme.accentColor,
              ),
              onPressed: viewModel.toggleMute,
              tooltip: state.isMuted ? 'Unmute' : 'Mute',
            ),
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
}
