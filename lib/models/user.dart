import 'package:flutter/material.dart';

class AgoraUser {
  int uid;
  bool muted;
  bool disableVideo;
  String? name;
  Color? backgroundColor;

  AgoraUser(
      {required this.uid,
      this.muted = false,
      this.disableVideo = false,
      this.name,
      this.backgroundColor});

  AgoraUser copyWith({
    int? uid,
    bool? muted,
    bool? disableVideo,
    String? name,
    Color? backgroundColor,
  }) {
    return AgoraUser(
      uid: uid ?? this.uid,
      muted: muted ?? this.muted,
      disableVideo: disableVideo ?? this.disableVideo,
      name: name ?? this.name,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }
}
