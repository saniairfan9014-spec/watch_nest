import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../family_watch_room_viewmodel.dart';

class MoviePlayerWidget extends ConsumerStatefulWidget {
  const MoviePlayerWidget({super.key});

  @override
  ConsumerState<MoviePlayerWidget> createState() => _MoviePlayerWidgetState();
}

class _MoviePlayerWidgetState extends ConsumerState<MoviePlayerWidget> {
  late YoutubePlayerController _controller;
  Timer? _syncTimer;
  bool _isLocalChange = false;
  
  // Keep track of the last synced values to prevent endless loops
  String? _lastQueueItemId;
  bool _lastIsPlaying = false;

  @override
  void initState() {
    super.initState();
    final roomState = ref.read(familyWatchRoomViewModelProvider).room;
    final currentItem = roomState.currentQueueItem;
    
    // Extract video ID from the current queue item's mediaUrl
    final videoId = _extractVideoId(currentItem?.mediaUrl);

    _controller = YoutubePlayerController.fromVideoId(
      videoId: videoId ?? '',
      autoPlay: roomState.playbackState?.isPlaying ?? false,
      startSeconds: currentItem != null
          ? (roomState.playbackState?.currentPosition ?? 0).toDouble()
          : 0.0,
      params: YoutubePlayerParams(
        showControls: roomState.isHost,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    _lastQueueItemId = roomState.playbackState?.currentQueueItemId;
    _lastIsPlaying = roomState.playbackState?.isPlaying ?? false;

    if (roomState.isHost) {
      _startHostSync();
    }

    // Listen to player state changes (host only)
    _controller.listen((event) {
      final room = ref.read(familyWatchRoomViewModelProvider).room;
      if (!room.isHost) return;
      
      final isPlaying = event.playerState == PlayerState.playing;
      if (isPlaying != _lastIsPlaying && !_isLocalChange) {
        _lastIsPlaying = isPlaying;
        _syncToBackend();
      }

      // Auto-play next when video ends
      if (event.playerState == PlayerState.ended && !_isLocalChange) {
        ref.read(familyWatchRoomViewModelProvider.notifier).playNextInQueue();
      }
    });
  }

  void _startHostSync() {
    // Periodically sync current position to backend
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final room = ref.read(familyWatchRoomViewModelProvider).room;
      if (room.currentQueueItem != null) {
        _syncToBackend();
      }
    });
  }

  Future<void> _syncToBackend() async {
    try {
      final position = await _controller.currentTime;
      final playerState = await _controller.playerState;
      final isPlaying = playerState == PlayerState.playing;

      ref.read(familyWatchRoomViewModelProvider.notifier).updatePlaybackState(
        isPlaying: isPlaying,
        currentPosition: position.toInt(),
      );
    } catch (e) {
      // Ignore timeouts when player is not fully initialized or not in widget tree
      debugPrint('Movie sync ignored due to player state: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _controller.close();
    super.dispose();
  }

  /// Extract YouTube video ID from a URL or raw video ID string
  String? _extractVideoId(String? input) {
    if (input == null || input.isEmpty) return null;
    
    // Already a raw 11-char video ID
    if (input.length == 11 && !input.contains('://')) {
      return input;
    }
    
    final id = YoutubePlayerController.convertUrlToId(input);
    if (id != null) return id;

    // Fallback regex
    final RegExp regex = RegExp(
        r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|&v=|\?v=)([^#&?]*).*');
    final Match? match = regex.firstMatch(input);
    if (match != null && match.group(1)?.length == 11) {
      return match.group(1);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(familyWatchRoomViewModelProvider);
    final roomState = state.room;
    final currentItem = roomState.currentQueueItem;
    
    // Listen for realtime sync from other users
    ref.listen(familyWatchRoomViewModelProvider, (previous, next) {
      final room = next.room;
      final newPlayback = room.playbackState;

      // Sync speaker mute/unmute
      final wasMuted = previous?.isSpeakerMuted ?? false;
      final nowMuted = next.isSpeakerMuted;
      if (wasMuted != nowMuted) {
        if (nowMuted) {
          _controller.mute().catchError((e) {
            debugPrint('Error muting player: $e');
          });
        } else {
          _controller.unMute().catchError((e) {
            debugPrint('Error unmuting player: $e');
          });
        }
      }

      if (!room.isHost && newPlayback != null) {
        // Different queue item → load new video
        if (newPlayback.currentQueueItemId != _lastQueueItemId) {
          _lastQueueItemId = newPlayback.currentQueueItemId;
          final newItem = room.currentQueueItem;
          final videoId = _extractVideoId(newItem?.mediaUrl);
          if (videoId != null) {
            _controller.loadVideoById(videoId: videoId).catchError((e) {
              debugPrint('Error loading video during sync: $e');
            });
            _controller.seekTo(
              seconds: newPlayback.currentPosition.toDouble(),
              allowSeekAhead: true,
            ).catchError((e) {
              debugPrint('Error seeking video during sync: $e');
            });
          }
        }
        
        // Play/pause sync
        if (newPlayback.isPlaying != _lastIsPlaying) {
          _lastIsPlaying = newPlayback.isPlaying;
          if (newPlayback.isPlaying) {
            _controller.playVideo().catchError((e) {
              debugPrint('Error playing video during sync: $e');
            });
          } else {
            _controller.pauseVideo().catchError((e) {
              debugPrint('Error pausing video during sync: $e');
            });
          }
        }
      }
    });

    // --- Non-host tap interceptor ---
    void showHostOnlySnackbar() {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Only Host can control playback'),
          duration: Duration(seconds: 2),
        ),
      );
    }

    return Column(
      children: [
        // --- Host URL Input Bar (only for host) ---
        if (roomState.isHost)
          _buildHostUrlBar(context),

        // --- Video Player ---
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.amber.shade700.withValues(alpha: 0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withValues(alpha: 0.1),
                blurRadius: 20,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Stack(
            children: [
              AbsorbPointer(
                absorbing: !roomState.isHost,
                child: YoutubePlayer(
                  controller: _controller,
                  backgroundColor: Colors.black,
                ),
              ),
              // Overlay for non-host tap
              if (!roomState.isHost)
                Positioned.fill(
                  child: GestureDetector(
                    onTap: showHostOnlySnackbar,
                    behavior: HitTestBehavior.translucent,
                    child: const SizedBox.shrink(),
                  ),
                ),
              // Placeholder when nothing is playing
              if (currentItem == null)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      roomState.isHost
                          ? 'Add a video to the queue to start watching'
                          : 'Waiting for host to start a video...',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),

              // ─── 3-Dot Menu (top-right corner, always visible) ───
              Positioned(
                top: 6,
                right: 6,
                child: _buildPlayerMenu(context, roomState.isHost),
              ),
            ],
          ),

        ),

        // --- Now Playing Info ---
        if (currentItem != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Colors.grey.shade900,
            child: Row(
              children: [
                const Icon(Icons.equalizer, size: 16, color: Colors.amber),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    currentItem.title,
                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (roomState.isHost && roomState.queue.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      _isLocalChange = true;
                      ref.read(familyWatchRoomViewModelProvider.notifier).playNextInQueue();
                      Future.delayed(const Duration(seconds: 2), () {
                        _isLocalChange = false;
                      });
                    },
                    icon: const Icon(Icons.skip_next, size: 16, color: Colors.amber),
                    label: const Text('Next', style: TextStyle(color: Colors.amber, fontSize: 12)),
                    style: TextButton.styleFrom(padding: EdgeInsets.zero),
                  ),
              ],
            ),
          ),
        
        // --- Custom Controls for Host ---
        if (roomState.isHost && currentItem != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.replay_10,
                  label: 'Rewind',
                  onTap: () async {
                    try {
                      final currentTime = await _controller.currentTime;
                      await _controller.seekTo(seconds: (currentTime - 10).clamp(0, double.infinity), allowSeekAhead: true);
                    } catch (e) {
                      debugPrint('Error during rewind: $e');
                    }
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onTap: () {
                    _controller.pauseVideo().catchError((e) {
                      debugPrint('Error pausing video: $e');
                    });
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  isPrimary: true,
                  onTap: () {
                    _controller.playVideo().catchError((e) {
                      debugPrint('Error playing video: $e');
                    });
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.forward_10,
                  label: 'Forward',
                  onTap: () async {
                    try {
                      final currentTime = await _controller.currentTime;
                      await _controller.seekTo(seconds: currentTime + 10, allowSeekAhead: true);
                    } catch (e) {
                      debugPrint('Error during forward: $e');
                    }
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isPrimary = false,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(30),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPrimary ? Colors.amber : Colors.grey.shade800,
              shape: BoxShape.circle,
              boxShadow: isPrimary
                  ? [
                      BoxShadow(
                        color: Colors.amber.withOpacity(0.4),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Icon(
              icon,
              color: isPrimary ? Colors.black : Colors.white,
              size: isPrimary ? 32 : 24,
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade400,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ─── Host URL Input Bar ───────────────────────────────────────────────────
  final TextEditingController _hostUrlController = TextEditingController();
  final TextEditingController _hostTitleController = TextEditingController();

  Widget _buildHostUrlBar(BuildContext context) {
    return Container(
      color: Colors.grey.shade900,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // URL field
          Expanded(
            child: TextField(
              controller: _hostUrlController,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Paste YouTube URL or ID...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.link, color: Colors.amber, size: 18),
                filled: true,
                fillColor: Colors.grey.shade800,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                isDense: true,
              ),
              onSubmitted: (_) => _submitHostUrl(context),
            ),
          ),
          const SizedBox(width: 8),
          // Add button
          GestureDetector(
            onTap: () => _submitHostUrl(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Add',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _submitHostUrl(BuildContext context) {
    final url = _hostUrlController.text.trim();
    if (url.isEmpty) return;

    ref.read(familyWatchRoomViewModelProvider.notifier).addToQueue(
      title: _hostTitleController.text.trim().isEmpty ? 'Video' : _hostTitleController.text.trim(),
      mediaUrl: url,
    );

    _hostUrlController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to queue ✓'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.green,
      ),
    );
  }

  // ─── 3-Dot Vertical Menu on Player ───────────────────────────────────────
  Widget _buildPlayerMenu(BuildContext context, bool isHost) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(20),
      ),
      child: PopupMenuButton<String>(
        icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
        color: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        offset: const Offset(0, 36),
        onSelected: (value) {
          if (value == 'add_queue') {
            _showAddToQueueSheet(context);
          } else if (value == 'next') {
            ref.read(familyWatchRoomViewModelProvider.notifier).playNextInQueue();
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem<String>(
            value: 'add_queue',
            child: Row(
              children: [
                const Icon(Icons.add_circle_outline, color: Colors.amber, size: 18),
                const SizedBox(width: 10),
                const Text(
                  'Add to Queue',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          if (isHost) ...[
            const PopupMenuDivider(),
            PopupMenuItem<String>(
              value: 'next',
              child: Row(
                children: [
                  Icon(Icons.skip_next, color: Colors.green.shade400, size: 18),
                  const SizedBox(width: 10),
                  Text(
                    'Play Next',
                    style: TextStyle(color: Colors.green.shade400, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Add to Queue Bottom Sheet ────────────────────────────────────────────
  void _showAddToQueueSheet(BuildContext context) {
    final urlCtrl = TextEditingController();
    final titleCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF1E1E2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle bar
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    const Icon(Icons.queue_music, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Add Video to Queue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // URL field
                TextField(
                  controller: urlCtrl,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'YouTube URL or Video ID',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.link, color: Colors.amber, size: 20),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 10),
                // Title field
                TextField(
                  controller: titleCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Title (optional)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                    prefixIcon: const Icon(Icons.title, color: Colors.white38, size: 20),
                    filled: true,
                    fillColor: Colors.white10,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      final url = urlCtrl.text.trim();
                      if (url.isEmpty) return;
                      ref.read(familyWatchRoomViewModelProvider.notifier).addToQueue(
                        title: titleCtrl.text.trim().isEmpty
                            ? 'Video'
                            : titleCtrl.text.trim(),
                        mediaUrl: url,
                      );
                      Navigator.pop(ctx);
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text(
                      'Add to Queue',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
