import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../../../app/constants/agora_constants.dart';

class AgoraVoiceService {
  RtcEngine? _engine;
  bool _isInitialized = false;
  String? _currentChannelId;

  bool get isInitialized => _isInitialized;

  /// Initializes Agora RTC engine, requests permission, and joins the channel.
  Future<void> initAgora(
    String channelId, {
    required bool isBroadcaster,
    required bool isMuted,
    required bool isSpeakerMuted,
  }) async {
    if (_isInitialized && _currentChannelId == channelId) {
      developer.log("Agora voice system already initialized for channel $channelId");
      // Just update state to match in case it has changed
      await updateVoiceState(
        isBroadcaster: isBroadcaster,
        isMuted: isMuted,
        isSpeakerMuted: isSpeakerMuted,
      );
      return;
    }

    if (_isInitialized) {
      await leaveChannel();
    }

    developer.log("Initializing Agora for channel: $channelId (Broadcaster: $isBroadcaster, Muted: $isMuted)");

    // 1. Request microphone permission
    try {
      final status = await Permission.microphone.request();
      if (!status.isGranted) {
        developer.log("Microphone permission denied.");
        return;
      }
    } catch (e) {
      developer.log("Error requesting microphone permission: $e");
      return;
    }

    // Check if App ID is valid
    if (AgoraConstants.appId.isEmpty || AgoraConstants.appId == 'YOUR_AGORA_APP_ID') {
      developer.log("Agora App ID is not configured.");
      return;
    }

    try {
      // 2. Create the RtcEngine instance
      _engine = createAgoraRtcEngine();
      
      // 3. Initialize engine context
      await _engine!.initialize(const RtcEngineContext(
        appId: AgoraConstants.appId,
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
      ));

      // 4. Register event handlers
      _engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
            developer.log("Successfully joined Agora channel: ${connection.channelId} with uid: ${connection.localUid}");
          },
          onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
            developer.log("Remote user joined: $remoteUid");
          },
          onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
            developer.log("Remote user offline: $remoteUid, reason: $reason");
          },
          onError: (ErrorCodeType err, String msg) {
            developer.log("Agora error: $err, message: $msg");
          },
        ),
      );

      // 5. Enable audio subsystem
      await _engine!.enableAudio();
      
      // By default, enable microphone volume indication
      await _engine!.enableAudioVolumeIndication(interval: 200, smooth: 3, reportVad: true);

      // 6. Pre-configure mute & speaker states
      // Note: muteLocalAudioStream must be called to ensure starting state is accurate
      await _engine!.muteLocalAudioStream(isMuted || !isBroadcaster);
      await _engine!.muteAllRemoteAudioStreams(isSpeakerMuted);

      // 7. Join the channel
      final clientRole = isBroadcaster 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience;

      await _engine!.joinChannel(
        token: '', // Using empty token for App ID testing mode
        channelId: channelId,
        uid: 0, // Auto-assign a UID
        options: ChannelMediaOptions(
          clientRoleType: clientRole,
          publishMicrophoneTrack: isBroadcaster && !isMuted,
          autoSubscribeAudio: !isSpeakerMuted,
        ),
      );

      _currentChannelId = channelId;
      _isInitialized = true;
      developer.log("Agora initialization complete for channel $channelId");
    } catch (e) {
      developer.log("Failed to initialize Agora RTC: $e");
      _isInitialized = false;
      _engine = null;
    }
  }

  /// Updates Agora publish and subscribe states depending on seat status and UI toggles.
  Future<void> updateVoiceState({
    required bool isBroadcaster,
    required bool isMuted,
    required bool isSpeakerMuted,
  }) async {
    final engine = _engine;
    if (engine == null || !_isInitialized) {
      developer.log("Agora voice system not initialized. Cannot update state.");
      return;
    }

    try {
      developer.log("Updating Agora state: Broadcaster=$isBroadcaster, Muted=$isMuted, SpeakerMuted=$isSpeakerMuted");
      
      // 1. Update client role in Agora
      final clientRole = isBroadcaster 
          ? ClientRoleType.clientRoleBroadcaster 
          : ClientRoleType.clientRoleAudience;
      await engine.setClientRole(role: clientRole);

      // 2. Mute/Unmute local microphone stream
      // A user only publishes if they are a broadcaster on a seat and not muted.
      await engine.muteLocalAudioStream(isMuted || !isBroadcaster);

      // 3. Mute/Unmute remote speaker stream
      await engine.muteAllRemoteAudioStreams(isSpeakerMuted);
    } catch (e) {
      developer.log("Error updating Agora voice state: $e");
    }
  }

  /// Leaves the channel and releases the engine resource.
  Future<void> leaveChannel() async {
    final engine = _engine;
    if (engine == null) return;

    developer.log("Leaving Agora channel: $_currentChannelId");
    try {
      await engine.leaveChannel();
      await engine.release();
    } catch (e) {
      developer.log("Error releasing Agora engine: $e");
    }
    
    _engine = null;
    _isInitialized = false;
    _currentChannelId = null;
    developer.log("Agora engine released successfully");
  }
}
