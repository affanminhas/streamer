import 'package:agora_rtc_engine/rtc_engine.dart';
import 'package:agora_rtm/agora_rtm.dart';
import 'package:flutter/material.dart';
import 'package:agora_rtc_engine/rtc_local_view.dart' as RtcLocalView;
import 'package:agora_rtc_engine/rtc_remote_view.dart' as RtcRemoteView;

import '../models/user.dart';
import '../utils/app_id.dart';

class Participant extends StatefulWidget {
  final String username;
  final String channelName;
  final int uid;

  const Participant(
      {Key? key, required this.username, required this.channelName, required this.uid})
      : super(key: key);

  @override
  _ParticipantState createState() => _ParticipantState();
}

class _ParticipantState extends State<Participant> {
  final List<AgoraUser> _users = [];
  late RtcEngine _engine;
  AgoraRtmChannel? _channel;
  AgoraRtmClient? _client;
  bool muted = false;
  bool videoDisabled = false;

  @override
  void dispose() {
    // TODO: implement dispose
    _users.clear();
    _engine.leaveChannel();
    _engine.destroy();
    _channel?.leave();
    _client?.logout();
    _client?.destroy();
    super.dispose();
  }

  @override
  void initState() {
    // TODO: implement initState

  super.initState();
  initializeAgora();
}
  Future<void> initializeAgora() async{
    _engine = await RtcEngine.createWithContext(RtcEngineContext(appId));
    _client = await AgoraRtmClient.createInstance(appId);

    await _engine.enableVideo();
    await _engine.setChannelProfile(ChannelProfile.LiveBroadcasting);
    await _engine.setClientRole(ClientRole.Broadcaster);

    // Callbacks to RTC Engine
    _engine.setEventHandler(RtcEngineEventHandler(
      joinChannelSuccess: (channel, uid, elapsed) {
        setState(() {
          _users.add(AgoraUser(uid: uid));
        });
      },
      leaveChannel: (stats){
        setState(() {
          _users.clear();
        });
      }
    ));

    // Callbacks to RTM Client
    _client?.onMessageReceived = (AgoraRtmMessage message, String peerId){
      print("Private Message from $peerId: ${message.text}");
    };

    _client?.onConnectionStateChanged = (int state, int reason){
      print("Connection state changed: ${state.toString()} reason ${reason.toString()}");
      if(state == 5){
        // channel state aborted
        _channel?.leave();
        _client?.logout();
        _client?.destroy();
        print("Logout!!");
      }
    };

    // Join the RTC and RTM channel
    await _client?.login(null, widget.uid.toString());
    _channel = await _client?.createChannel(widget.channelName);
    await _channel?.join();
    await _engine.joinChannel(null, widget.channelName, null, widget.uid);

    // Callbacks to RTM Channel
    _channel?.onMemberJoined = (AgoraRtmMember member){
      print("Member Joined: ${member.userId} channel: ${member.channelId}");
    };

    _channel?.onMemberLeft = (AgoraRtmMember member){
      print("Member Left: ${member.userId} channel: ${member.channelId}");
    };

    _channel?.onMessageReceived = (AgoraRtmMessage message, AgoraRtmMember member){
      print("Private message from ${member.userId}: ${message.text}");
    };

  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _broadcastView(),
          _toolbar()
        ],
      )
    );
  }

  Widget _broadcastView() {
    if(_users.isEmpty){
      return const Center(
        child: Text("No Users"),
      );
    }
    return const Expanded(
      child: RtcLocalView.SurfaceView(),
    );
  }

  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Row(
        children: [
          RawMaterialButton(
              onPressed: _onToggleMute,
            child: Icon(
              muted? Icons.mic_external_off : Icons.mic,
              color: muted? Colors.white : Colors.blueAccent,
              size: 20,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: muted? Colors.blueAccent:Colors.white,
            padding: const EdgeInsets.all(12),
          ),
          RawMaterialButton(
              onPressed: () => _onCallEnd(context),
            child: const Icon(
              Icons.call_end,
              size: 25,
              color: Colors.white,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.redAccent,
            padding: const EdgeInsets.all(15),
          ),
          RawMaterialButton(
            onPressed: _onToggleVideoDisabled,
            child: Icon(
              videoDisabled? Icons.videocam_off : Icons.videocam,
              color:videoDisabled? Colors.white : Colors.blueAccent,
              size: 20,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: videoDisabled? Colors.blueAccent:Colors.white,
            padding: const EdgeInsets.all(12),
          ),
          RawMaterialButton(
            onPressed: _onSwitchCamera,
            child: const Icon(
              Icons.switch_camera,
              size: 25,
              color: Colors.blueAccent,
            ),
            shape: const CircleBorder(),
            elevation: 2.0,
            fillColor: Colors.white,
            padding: const EdgeInsets.all(15),
          ),
        ],
      ),
    );
  }
  void _onToggleMute(){
    setState(() {
      muted != muted;
    });
    _engine.muteLocalAudioStream(muted);
  }

  void _onToggleVideoDisabled(){
    setState(() {
      videoDisabled != videoDisabled;
    });
    _engine.muteLocalVideoStream(videoDisabled);
  }

  void _onSwitchCamera(){
    _engine.switchCamera();
  }

  void _onCallEnd(BuildContext context){
    Navigator.pop(context);
  }
}
