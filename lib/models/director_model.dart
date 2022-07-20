import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:streamer/models/user.dart';

class DirectorModel {
  RtcEngine? engine;
  AgoraRtmChannel? channel;
  AgoraRtmClient? client;
  Set<AgoraUser> activeUsers;
  Set<AgoraUser> lobbyUsers;
  AgoraUser? localUsers;

  DirectorModel(
      {this.engine,
      this.channel,
      this.client,
      this.activeUsers = const {},
      this.lobbyUsers = const {},
      this.localUsers});

  DirectorModel copyWith({
    RtcEngine? engine,
    AgoraRtmChannel? channel,
    AgoraRtmClient? client,
    Set<AgoraUser>? activeUsers,
    Set<AgoraUser>? lobbyUsers,
    AgoraUser? localUsers,
  }) {
    return DirectorModel(
        engine: engine ?? this.engine,
        channel: channel ?? this.channel,
        client: client ?? this.client,
        activeUsers: activeUsers ?? this.activeUsers,
        lobbyUsers: lobbyUsers ?? this.lobbyUsers,
        localUsers: localUsers ?? this.localUsers);
  }
}
