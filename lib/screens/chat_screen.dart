import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chime/api/apis.dart';
import 'package:chime/model/message_model.dart';
import 'package:chime/model/user_model.dart';
import 'package:chime/screens/view_profile_screen.dart';
import 'package:chime/utils/date_utils.dart';
import 'package:chime/widgets/message_card.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../main.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.user});
  final UserModel user;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // message model list fetching from firebase
  List<MessageModel> _messageList = [];
  // user message storage variable
  final TextEditingController _message = TextEditingController();
  // for managing emoji's menu visbility
  bool _showEmoji = false;
  // for showing circular progress indicator while sending photos
  bool _isUploading = false;

  @override
  Widget build(BuildContext context) {
    // SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle( systemNavigationBarColor: Colors.white, statusBarColor: Colors.white));
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Colors.indigo[50],
          appBar: AppBar(
            automaticallyImplyLeading: false,
            flexibleSpace: _appBar(),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Expanded(
                  child: StreamBuilder(
                      stream: Apis.getAllMessages(widget.user),
                      builder: (context, snapshot) {
                        // log("Checking conversation ID: ${Apis.getConversationId(widget.user.id)}");

                        // Listen for messages and log details
                        Apis.getAllMessages(widget.user).listen((snapshot) {
                          // log("Snapshot size: ${snapshot.size}");
                          
                        });
                        if (snapshot.hasData) {
                          // debugPrint(
                          //     'Snapshot data: ${snapshot.data?.docs.map((doc) => doc.data())}');
                        }
                        if (snapshot.hasError) {
                          log("Error happened");
                        }
                        switch (snapshot.connectionState) {
                          case ConnectionState.none:
                          case ConnectionState.waiting:
                            return const Center(
                              // child: CircularProgressIndicator(),
                              child: SizedBox(),
                            );
                          case ConnectionState.active:
                          case ConnectionState.done:
                            final data = snapshot.data!.docs;
                            // log("Data: ${jsonEncode(data![0].data())}");
                            _messageList = data.map((e) {
                              // log("Message : ${e.data()}");
                              return MessageModel.fromJson(e.data());
                            }).toList();

                            debugPrint(
                                'Message List Length: ${_messageList.length}');
                            debugPrint(
                                'Messages: ${_messageList.map((message) => message.message).toList()}');

                            if (_messageList.isNotEmpty) {
                              return ListView.builder(
                                  reverse: true,
                                  physics: const BouncingScrollPhysics(),
                                  itemCount: _messageList.length,
                                  itemBuilder: (context, index) {
                                    return Padding(
                                      padding: EdgeInsets.symmetric(
                                          horizontal: mq.width * 0.02,
                                          vertical: mq.height * 0.002),
                                      child: MessageCard(
                                        message: _messageList[index],
                                      ),
                                    );
                                  });
                            } else {
                              // say hi message for new conversation
                              return const Center(
                                child: Text(
                                  "Say Hii!👋",
                                  style: TextStyle(
                                      fontSize: 25,
                                      fontWeight: FontWeight.w500),
                                ),
                              );
                            }
                        }
                      }),
                ),
                if (_isUploading)
                  Padding(
                    padding: EdgeInsets.all(mq.width * 0.1),
                    child: const Align(
                        alignment: Alignment.centerRight,
                        child: CircularProgressIndicator()),
                  ),
                _chatInputField(),
                

                //show emojis on keyboard emoji button click & vice versa
                if (_showEmoji) _emojiPicker()
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emojiPicker() {
    return SizedBox(
      
        height: mq.height * .35,
        child: EmojiPicker(
          
          textEditingController: _message,
          config: Config(
            viewOrderConfig: const ViewOrderConfig(
              top: EmojiPickerItem.searchBar,
              middle: EmojiPickerItem.emojiView,
              bottom: EmojiPickerItem.categoryBar,
            ),
            emojiViewConfig: EmojiViewConfig(
              columns: 7,
              emojiSizeMax: 32 * (Platform.isIOS ? 1.0 : 0.7),
              verticalSpacing: 0,
              horizontalSpacing: 0,
            ),
            categoryViewConfig: const CategoryViewConfig(
              initCategory: Category.RECENT,
              iconColor: Colors.grey,
              iconColorSelected: Colors.blue,
              indicatorColor: Colors.blue,
              backspaceColor: Colors.blue,
            ),
            skinToneConfig: const SkinToneConfig(),
            bottomActionBarConfig: const BottomActionBarConfig(),
            searchViewConfig: const SearchViewConfig(
              backgroundColor: Colors.white,
            ),
          ),
        ));
  }

  // custom appbar
  Widget _appBar() {
    return InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_)=> ViewProfileScreen(user: widget.user)));
        },
        child: StreamBuilder(
          stream: Apis.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list = data?.map((e) {
              // log(UserModel.fromJson(e.data()).toString());
              return UserModel.fromJson(e.data());}).toList() ?? [];
            return Row(
              children: [
                // back button
                IconButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.arrow_back)),

                // user profile picture
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .045),
                  child: CachedNetworkImage(
                    imageUrl: list.isNotEmpty ? list[0].image : widget.user.image,
                    fit: BoxFit.cover,
                    height: mq.height * 0.05,
                    width: mq.width * 0.1,
                    placeholder: (context, url) =>
                        const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(
                      CupertinoIcons.person,
                      color: Colors.blue,
                    ),
                  ),
                ),
                SizedBox(
                  width: mq.width * 0.03,
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // user name
                    Text(
                      list.isNotEmpty ? list[0].name :
                      widget.user.name,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    // user last activity time
                     Text(
                      list.isNotEmpty ? list[0].isOnline ? "Online" :
                      
                      MyDateUtils.getLastActiveTime(context: context, lastActive: list[0].lastActive) :
                      MyDateUtils.getLastActiveTime(context: context, lastActive: widget.user.lastActive), 
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                          color: Colors.black54),
                    )
                  ],
                )
              ],
            );
          },
        ));
  }

  Widget _chatInputField() {
    return Row(
      children: [
        Expanded(
          child: Card(
            child: Row(
              children: [
                // emoji showing button
                MaterialButton(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() {
                      _showEmoji = !_showEmoji;
                    });
                  },
                  minWidth: 20,
                  padding: const EdgeInsets.all(5),
                  shape: const CircleBorder(),
                  color: Colors.black54.withOpacity(0.4),
                  child: const Icon(
                    Icons.emoji_emotions_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                // message input field
                Expanded(
                  child: TextField(
                    controller: _message,
                    onTap: () {
                      setState(() {
                        if (_showEmoji) {
                          _showEmoji = !_showEmoji;
                        }
                      });
                    },
                    maxLines: null,
                    keyboardType: TextInputType.multiline,
                    decoration: InputDecoration(
                        border: InputBorder.none,
                        hintText: "Type Something...",
                        hintStyle:
                            TextStyle(color: Colors.blue[400], fontSize: 16)),
                  ),
                ),
                // click image from camera button
                MaterialButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    // Pick an image
                    final XFile? image = await picker.pickImage(
                        source: ImageSource.camera, imageQuality: 70);
                    if (image != null) {
                      // log('Image Path: ${image.path}');
                      setState(() {
                        _isUploading = !_isUploading;
                      });
                      await Apis.sendImageMessage(
                          widget.user, File(image.path));
                      setState(() {
                        _isUploading = !_isUploading;
                      });
                    }
                  },
                  minWidth: 20,
                  padding: const EdgeInsets.all(5),
                  shape: const CircleBorder(),
                  color: Colors.black54.withOpacity(0.4),
                  child: const Icon(
                    Icons.camera_alt_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                // click image from galllery button
                MaterialButton(
                  onPressed: () async {
                    final ImagePicker picker = ImagePicker();

                    // Pick an image
                    final List<XFile> images =
                        await picker.pickMultiImage(imageQuality: 70);
                    for (var i in images) {
                      // log('Image Path: ${i.path}');
                      setState(() {
                        _isUploading = !_isUploading;
                      });
                      await Apis.sendImageMessage(widget.user, File(i.path));
                      setState(() {
                        _isUploading = !_isUploading;
                      });
                    }
                  },
                  minWidth: 20,
                  padding: const EdgeInsets.all(5),
                  shape: const CircleBorder(),
                  color: Colors.black54.withOpacity(0.4),
                  child: const Icon(
                    Icons.image_outlined,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                // send message button
                MaterialButton(
                  onPressed: () {
                    if (_message.text.isNotEmpty) {
                      if (_messageList.isEmpty) {
                  //on first message (add user to my_user collection of chat user)
                  Apis.sendFirstMessage(
                      widget.user, _message.text, Type.text);
                } else {
                  //simply send message
                  Apis.sendMessage(
                      widget.user, _message.text, Type.text);
                }
                _message.text = '';
                    }
                  },
                  minWidth: 20,
                  padding: const EdgeInsets.all(5),
                  shape: const CircleBorder(),
                  color: Colors.green,
                  child: const Icon(
                    Icons.send,
                    color: Colors.white,
                    size: 20,
                  ),
                )
              ],
            ),
          ),
        ),
        // SizedBox(),
      ],
    );
  }
}
