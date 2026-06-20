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
  final TextEditingController _urlController = TextEditingController();
  Timer? _syncTimer;
  bool _isLocalChange = false;
  
  // Keep track of the last synced values to prevent endless loops
  String? _lastVideoId;
  bool _lastIsPlaying = false;

  @override
  void initState() {
    super.initState();
    final roomState = ref.read(familyWatchRoomViewModelProvider).room;
    
    _controller = YoutubePlayerController(
      params: YoutubePlayerParams(
        showControls: roomState.isHost,
        showFullscreenButton: true,
        mute: false,
      ),
    );

    if (roomState.currentVideoId != null) {
      _controller.loadVideoById(
        videoId: roomState.currentVideoId!,
        startSeconds: roomState.currentPosition.toDouble(),
      );
      if (!roomState.isPlaying) {
        _controller.pauseVideo();
      }
      _lastVideoId = roomState.currentVideoId;
      _lastIsPlaying = roomState.isPlaying;
    }

    if (roomState.isHost) {
      _startHostSync();
    }

    // Listen to player state changes
    _controller.listen((event) {
      if (!roomState.isHost) return;
      
      // If the host manually plays/pauses, update backend
      final isPlaying = event.playerState == PlayerState.playing;
      if (isPlaying != _lastIsPlaying && !_isLocalChange) {
        _lastIsPlaying = isPlaying;
        _syncToBackend();
      }
    });
  }

  void _startHostSync() {
    // Periodically sync current position to backend
    _syncTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final roomState = ref.read(familyWatchRoomViewModelProvider).room;
      if (roomState.currentVideoId != null) {
        _syncToBackend();
      }
    });
  }

  Future<void> _syncToBackend() async {
    try {
      final videoId = await _controller.videoData.then((v) => v.videoId);
      if (videoId.isEmpty) return;

      final position = await _controller.currentTime;
      final state = await _controller.playerState;
      final isPlaying = state == PlayerState.playing;

      ref.read(familyWatchRoomViewModelProvider.notifier).updateMovieState(
        videoId,
        isPlaying,
        position.toInt(),
      );
    } catch (e) {
      // Ignore timeouts when player is not fully initialized or not in widget tree
      debugPrint('Movie sync ignored due to player state: $e');
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _urlController.dispose();
    _controller.close();
    super.dispose();
  }

  void _loadVideo() {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    String? videoId;
    
    if (url.length == 11 && !url.contains('://')) {
      videoId = url;
    } else {
      videoId = YoutubePlayerController.convertUrlToId(url);
      if (videoId == null) {
        final RegExp regex = RegExp(
            r'.*(?:youtu.be\/|v\/|u\/\w\/|embed\/|watch\?v=|\&v=|\?v=)([^#\&\?]*).*');
        final Match? match = regex.firstMatch(url);
        if (match != null && match.group(1)?.length == 11) {
          videoId = match.group(1);
        }
      }
    }

    if (videoId != null && videoId.length == 11) {
      _isLocalChange = true;
      
      // Update state instantly so UI mounts the player BEFORE we try to sync
      ref.read(familyWatchRoomViewModelProvider.notifier).updateMovieState(
        videoId,
        true,
        0,
      );
      
      _controller.loadVideoById(videoId: videoId);
      _urlController.clear();
      
      Future.delayed(const Duration(seconds: 2), () {
        _isLocalChange = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL or ID')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(familyWatchRoomViewModelProvider).room;
    
    // Listen for member synchronization
    ref.listen(familyWatchRoomViewModelProvider, (previous, next) {
      final roomState = next.room;
      if (!roomState.isHost) {
        if (roomState.currentVideoId != null && roomState.currentVideoId != _lastVideoId) {
          _lastVideoId = roomState.currentVideoId;
          _controller.loadVideoById(videoId: roomState.currentVideoId!);
          _controller.seekTo(seconds: roomState.currentPosition.toDouble(), allowSeekAhead: true);
        }
        
        if (roomState.isPlaying != _lastIsPlaying) {
          _lastIsPlaying = roomState.isPlaying;
          if (roomState.isPlaying) {
            _controller.playVideo();
          } else {
            _controller.pauseVideo();
          }
        }
      }
    });

    return Column(
      children: [
        if (roomState.isHost)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _urlController,
                    decoration: InputDecoration(
                      hintText: 'Enter YouTube URL or Video ID',
                      filled: true,
                      fillColor: Colors.grey.shade900,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _loadVideo,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  ),
                  child: const Text('Load', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
        Container(
          width: double.infinity,
          height: 250,
          decoration: BoxDecoration(
            color: Colors.black,
            border: Border.all(color: Colors.amber.shade700.withOpacity(0.3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.amber.withOpacity(0.1),
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
              if (roomState.currentVideoId == null)
                Container(
                  color: Colors.black,
                  child: Center(
                    child: Text(
                      roomState.isHost
                          ? 'Load a video to start watching'
                          : 'Waiting for host to load a video...',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Custom Controls for Host
        if (roomState.isHost && roomState.currentVideoId != null)
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            color: Colors.grey.shade900,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildControlButton(
                  icon: Icons.replay_10,
                  label: 'Rewind',
                  onTap: () async {
                    final currentTime = await _controller.currentTime;
                    _controller.seekTo(seconds: (currentTime - 10).clamp(0, double.infinity), allowSeekAhead: true);
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.pause,
                  label: 'Pause',
                  onTap: () {
                    _controller.pauseVideo();
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.play_arrow,
                  label: 'Play',
                  isPrimary: true,
                  onTap: () {
                    _controller.playVideo();
                    Future.delayed(const Duration(milliseconds: 500), _syncToBackend);
                  },
                ),
                const SizedBox(width: 20),
                _buildControlButton(
                  icon: Icons.forward_10,
                  label: 'Forward',
                  onTap: () async {
                    final currentTime = await _controller.currentTime;
                    _controller.seekTo(seconds: currentTime + 10, allowSeekAhead: true);
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
}
