import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:streamer/controllers/director_controller.dart';
import 'package:streamer/models/director_model.dart';

class Director extends ConsumerStatefulWidget {
  final String channelName;
  final int uid;
  const Director({Key? key, required this.channelName, required this.uid}) : super(key: key);

  @override
  _DirectorState createState() => _DirectorState();
}

class _DirectorState extends ConsumerState<Director> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    ref.read(directorController.notifier).joinCall(
        channelName: widget.channelName, uid: widget.uid
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (BuildContext context, WidgetRef ref, Widget? child) {
        DirectorController directorNotifier = ref.watch(directorController.notifier);
        DirectorModel directorData = ref.watch(directorController);
        Size size = MediaQuery.of(context).size;
        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverList(
                  delegate: SliverChildListDelegate(
                    [
                      const SafeArea(child: Text("Director"))
                    ]
                  )
              ),
              if(directorData.activeUsers.isEmpty)
                SliverList(
                    delegate: SliverChildListDelegate(
                        [
                          Center(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: const Text("Empty Stage"),
                            ),
                          )
                        ]
                    )
                ),
              SliverGrid(
                  delegate: SliverChildBuilderDelegate((BuildContext ctx, index){
                    return Row(
                      children: [
                        // Expanded(
                        //     child: StageUser(directorData: directorData, directorNotifier: directorNotifier, index: index)
                        // )
                      ],
                    );
                  },childCount: directorData.activeUsers.length),
                  gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: size.width/2,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20
                  )
              )
            ],
          )
        );
      },
    );
  }
}
