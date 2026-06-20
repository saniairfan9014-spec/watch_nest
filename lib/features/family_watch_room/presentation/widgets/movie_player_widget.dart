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
      _controller.loadVideoById(videoId: roomState.currentVideoId!);
      if (!roomState.isPlaying) {
        _controller.pauseVideo();
      }
      _controller.seekTo(seconds: roomState.currentPosition.toDouble(), allowSeekAhead: true);
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
      _syncToBackend();
    });
  }

  Future<void> _syncToBackend() async {
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

    final videoId = YoutubePlayerController.convertUrlToId(url);
    if (videoId != null) {
      _isLocalChange = true;
      _controller.loadVideoById(videoId: videoId);
      _syncToBackend();
      _urlController.clear();
      
      Future.delayed(const Duration(seconds: 2), () {
        _isLocalChange = false;
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomState = ref.watch(familyWatchRoomViewModelProvider).room;
    
    // Member synchronization
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
          child: roomState.currentVideoId == null && roomState.isHost
              ? const Center(
                  child: Text(
                    'Load a video to start watching',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
              : roomState.currentVideoId == null
                  ? const Center(
                      child: Text(
                        'Waiting for host to load a video...',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                  : AbsorbPointer(
                      absorbing: !roomState.isHost,
                      child: YoutubePlayer(
                        controller: _controller,
                        backgroundColor: Colors.black,
                      ),
                    ),
        ),
      ],
    );
  }
}
