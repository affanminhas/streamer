import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:streamer/pages/director.dart';
import 'package:streamer/pages/participant.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController _channelName = TextEditingController();
  TextEditingController _userName = TextEditingController();
  late int uid;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    getUserUid();
  }

  Future<void> getUserUid() async{
    SharedPreferences preferences = await SharedPreferences.getInstance();
    int? storedUid = preferences.getInt("localUid");
    if(storedUid != null){
      uid = storedUid;
      print("StoredUid: $uid");
    }else{
      // It should only happens once unless user delete the app
      int time = DateTime.now().millisecondsSinceEpoch;
      uid = int.parse(time.toString().substring(1, time.toString().length - 3));
      preferences.setInt("localUid", uid);
      print("SettingUid: $uid");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Image(
              image: AssetImage("images/streamer_logo.png")
            ),
            const Text("Multi Streaming with Friends"),
            const SizedBox(height: 40,),
            SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _userName,
                  decoration: InputDecoration(
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: const BorderSide(color: Colors.grey)
                      ),
                      hintText: "User Name"
                  ),
                )
            ),
            const SizedBox(height: 8,),
            SizedBox(
                width: MediaQuery.of(context).size.width * 0.85,
                child: TextField(
                  controller: _channelName,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15),
                      borderSide: const BorderSide(color: Colors.grey)
                    ),
                    hintText: "Channel Name"
                  ),
                )
            ),
            TextButton(
                onPressed: () async{
                  await [Permission.camera, Permission.microphone].request();
                  // Take us to participant screen
                  Navigator.of(context).push(MaterialPageRoute(builder: (_)=> Participant(
                    channelName: _channelName.text,
                    username: _userName.text,
                    uid: uid,
                  )));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Participant",
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.live_tv)
                  ],
                )),
            TextButton(
                onPressed: () async{
                  await [Permission.camera, Permission.microphone].request();
                  // Take us to director screen
                  Navigator.of(context).push(MaterialPageRoute(builder: (_)=> Director(
                    channelName: _channelName.text,
                    uid: uid,
                  )));
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Text(
                      "Director",
                      style: TextStyle(fontSize: 20),
                    ),
                    Icon(Icons.cut)
                  ],
                )),
          ],
        ),
      ),
    );
  }
}
