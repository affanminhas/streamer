import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamer/models/director_model.dart';
import 'package:streamer/models/user.dart';

import '../utils/app_id.dart';

final directorController =
    StateNotifierProvider.autoDispose<DirectorController, DirectorModel>((ref) {
  return DirectorController(ref.read);
});

class DirectorController extends StateNotifier<DirectorModel> {
  final Reader reader;

  DirectorController(this.reader) : super(DirectorModel());

  Future<void> joinCall({required String channelName, required int uid}) async {
    await _initialize();

    await state.engine?.enableVideo();
    await state.engine?.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await state.engine?.setClientRole(ClientRole.Broadcaster);

    // Callbacks to RTC Engine
    state.engine?.setEventHandler(
        RtcEngineEventHandler(joinChannelSuccess: (channel, uid, elapsed) {
      print("Director $uid");
    }, leaveChannel: (stats) {
      print("Channel Left");
    }, userJoined: (uid, elapsed) {
      print("User Joined ${uid.toString()}");
      addUserToLobby(uid: uid);
    }, userOffline: (uid, reason) {
      removeUser(uid: uid);
    }, remoteAudioStateChanged: (uid, state, reason, elapsed) {
      if (state == AudioRemoteState.Decoding) {
        updateUserAudio(uid: uid, muted: false);
      } else if (state == AudioRemoteState.Stopped) {
        updateUserAudio(uid: uid, muted: true);
      }
    }, remoteVideoStateChanged: (uid, state, reason, elapsed) {
      if (state == VideoRemoteState.Decoding) {
        updateUserVideo(uid: uid, videoDisabled: false);
      } else if (state == VideoRemoteState.Stopped) {
        updateUserVideo(uid: uid, videoDisabled: true);
      }
    }));

    // Callbacks to RTM Client
    state.client?.onMessageReceived = (AgoraRtmMessage message, String peerId) {
      print("Private Message from $peerId: ${message.text}");
    };

    state.client?.onConnectionStateChanged = (int errorState, int reason) {
      print(
          "Connection state changed: ${state.toString()} reason ${reason.toString()}");
      if (errorState == 5) {
        // channel state aborted
        state.channel?.leave();
        state.client?.logout();
        state.client?.destroy();
        print("Logout!!");
      }
    };

    // Join the RTC and RTM channel
    await state.client?.login(null, uid.toString());
    state =
        state.copyWith(channel: await state.client?.createChannel(channelName));
    await state.channel?.join();
    await state.engine?.joinChannel(null, channelName, null, uid);

    // Callbacks to RTM Channel
    state.channel?.onMemberJoined = (AgoraRtmMember member) {
      print("Member Joined: ${member.userId} channel: ${member.channelId}");
    };

    state.channel?.onMemberLeft = (AgoraRtmMember member) {
      print("Member Left: ${member.userId} channel: ${member.channelId}");
    };

    state.channel?.onMessageReceived =
        (AgoraRtmMessage message, AgoraRtmMember member) {
      print("Private message from ${member.userId}: ${message.text}");
    };
  }

  Future<void> _initialize() async {
    RtcEngine _engine =
        await RtcEngine.createWithContext(RtcEngineContext(appId));
    AgoraRtmClient _client = await AgoraRtmClient.createInstance(appId);
    state = DirectorModel(engine: _engine, client: _client);
  }

  Future<void> leaveCall() async {
    state.engine?.leaveChannel();
    state.engine?.destroy();
    state.channel?.leave();
    state.client?.logout();
    state.client?.destroy();
  }

  Future<void> addUserToLobby({required int uid}) async {
    state = state.copyWith(lobbyUsers: {
      ...state.lobbyUsers,
      AgoraUser(
          uid: uid,
          muted: true,
          disableVideo: true,
          name: "Affan",
          backgroundColor: Colors.blue)
    });
  }

  Future<void> promoteToActiveUser({required int uid}) async {
    Set<AgoraUser> _tempLobby = state.lobbyUsers;
    Color? tempColor;
    String? tempName;

    for (int i = 0; i < _tempLobby.length; i++) {
      if (_tempLobby.elementAt(i).uid == uid) {
        tempColor = _tempLobby.elementAt(i).backgroundColor;
        tempName = _tempLobby.elementAt(i).name;
        _tempLobby.remove(_tempLobby.elementAt(i));
      }
    }

    state = state.copyWith(activeUsers: {
      ...state.activeUsers,
      AgoraUser(uid: uid, backgroundColor: tempColor, name: tempName)
    }, lobbyUsers: _tempLobby);
  }

  Future<void> demoteToLobbyUser({required int uid}) async {
    Set<AgoraUser> _tempActive = state.activeUsers;
    Color? tempColor;
    String? tempName;

    for (int i = 0; i < _tempActive.length; i++) {
      if (_tempActive.elementAt(i).uid == uid) {
        tempColor = _tempActive.elementAt(i).backgroundColor;
        tempName = _tempActive.elementAt(i).name;
        _tempActive.remove(_tempActive.elementAt(i));
      }
    }

    state = state.copyWith(lobbyUsers: {
      ...state.lobbyUsers,
      AgoraUser(
          uid: uid,
          backgroundColor: tempColor,
          name: tempName,
          muted: true,
          disableVideo: true)
    }, activeUsers: _tempActive);
  }

  Future<void> removeUser({required int uid}) async {
    Set<AgoraUser> _tempActive = state.activeUsers;
    Set<AgoraUser> _tempLobby = state.lobbyUsers;

    for (int i = 0; i < _tempActive.length; i++) {
      if (_tempActive.elementAt(i).uid == uid) {
        _tempActive.remove(_tempActive.elementAt(i));
      }
    }

    for (int i = 0; i < _tempLobby.length; i++) {
      if (_tempLobby.elementAt(i).uid == uid) {
        _tempLobby.remove(_tempLobby.elementAt(i));
      }
    }
    state = state.copyWith(activeUsers: _tempActive, lobbyUsers: _tempLobby);
  }

  Future<void> updateUserAudio({required int uid, required bool muted}) async {
    AgoraUser _tempUser =
        state.activeUsers.singleWhere((element) => element.uid == uid);
    Set<AgoraUser> _tempSet = state.activeUsers;
    _tempSet.remove(_tempUser);
    _tempSet.add(_tempUser.copyWith(muted: muted));
    state = state.copyWith(activeUsers: _tempSet);
  }

  Future<void> updateUserVideo(
      {required int uid, required bool videoDisabled}) async {
    AgoraUser _tempUser =
        state.activeUsers.singleWhere((element) => element.uid == uid);
    Set<AgoraUser> _tempSet = state.activeUsers;
    _tempSet.remove(_tempUser);
    _tempSet.add(_tempUser.copyWith(disableVideo: videoDisabled));
    state = state.copyWith(activeUsers: _tempSet);
  }

  Future<void> toggleUserAudio(
      {required int index, required bool muted}) async {
    if (muted) {
      // send message to mute
    } else {
      // send message to un-mute
    }
  }
}
