import 'package:chime/model/message_model.dart';
import 'package:chime/model/user_model.dart';
import 'package:chime/screens/chat_screen.dart';
import 'package:chime/utils/date_utils.dart';
import 'package:chime/widgets/dialogs/profile_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../api/apis.dart';
import '../main.dart';

class ChatUserCard extends StatefulWidget {
  const ChatUserCard({required this.user, super.key});

  final UserModel user;

  @override
  State<ChatUserCard> createState() => _ChatUserCardState();
}

class _ChatUserCardState extends State<ChatUserCard> {
  MessageModel? _message;
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.symmetric(
          horizontal: mq.width * 0.03, vertical: mq.height * 0.005),
      elevation: 0.5,
      child: InkWell(
        // attaching tap feature to open chat screen
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => ChatScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: Apis.getLastMessage(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => MessageModel.fromJson(e.data())).toList() ??
                    [];
            if (list.isNotEmpty) {
              _message = list[0];
            }

            return ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),

              leading: InkWell(
                onTap: (){
                  showDialog(context: context, builder: (_)=> ProfileDialog(user: widget.user));
                },
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .05),
                  // displaying user image in user log
                  child: CachedNetworkImage(
                    fit: BoxFit.cover,
                    height: mq.height * 0.0475,
                    width: mq.width * 0.1,
                    // scale: 1,
                    imageUrl: widget.user.image,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(
                      CupertinoIcons.person,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
              title: Text(widget.user.name),
              subtitle: Text(
                _message != null ? 
                _message!.type == Type.image ? "Photo" :
                _message!.message : widget.user.about,
                maxLines: 1,
              ),

              trailing: _message == null
                  ? null
                  : _message!.read.isEmpty &&
                          _message!.fromId != Apis.currentUser.id
                      ? Container(
                          height: 10,
                          width: 10,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.greenAccent.shade400),
                        )
                      : Text(MyDateUtils.getLastMessageTime(
                          context: context, time: _message!.sent)),
              // trailing:  Text(widget.user.lastActive, style: const TextStyle(color: Colors.black54),),
            );
          },
        ),
      ),
    );
  }
}
