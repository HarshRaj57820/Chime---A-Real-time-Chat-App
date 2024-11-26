import 'dart:developer';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chime/model/message_model.dart';
import 'package:chime/utils/dialogs.dart';
import 'package:flutter/material.dart';
import 'package:chime/utils/date_utils.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver_updated/gallery_saver.dart';
import '../api/apis.dart';
import '../main.dart';

class MessageCard extends StatefulWidget {
  const MessageCard({required this.message, super.key});
  final MessageModel message;
  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = Apis.user.uid == widget.message.fromId;
    return InkWell(
        onLongPress: () => _showBottomSheet(isMe),
        child: isMe ? _greenCard() : _blueCard());
  }

  @override
  void initState() {

    super.initState();
    if(widget.message.read.isEmpty){
      Apis.updateMessageRead(widget.message);
      log("message read updated");
    }
  }

  Widget _blueCard() {    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            // margin: EdgeInsets.symmetric(horizontal: mq.width * 0.02),
            padding: widget.message.type == Type.text ? EdgeInsets.all(mq.width * 0.04) : EdgeInsets.all(mq.width * 0.03),
          
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 196, 230, 246),
                border: Border.all(color: Colors.lightBlue),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                )),
            child: widget.message.type == Type.text? Text(
              widget.message.message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            )
             : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * 0.02),
                              child: CachedNetworkImage(
                                fit: BoxFit.fill,
                                height: mq.height * 0.23,
                                width: mq.width * 0.5,
                                imageUrl: widget.message.message,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.image,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
          ),
        ),
        Row(
          children: [
            Text(
              MyDateUtils.getFormattedTime(context : context,time: widget.message.sent),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            SizedBox(width: mq.width*0.01,),
            // const Icon(
            //   Icons.done_all_rounded,
            //   size: 20,
            //   color: Colors.blue,
            // )
          ],
        ),
      ],
    );
  }

  Widget _greenCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            // if(widget.message.read.isNotEmpty)
             Icon(Icons.done_all_rounded,size: 20,
            //  color: Colors.blue,
             color: widget.message.read.isEmpty? Colors.black38 : Colors.blue,
            ),
            
            Text(
              MyDateUtils.getFormattedTime(context : context,time: widget.message.sent),
              style: const TextStyle(fontSize: 14, color: Colors.black54),
            ),
            
             ],
        ),
         Flexible(
           child: Container(
            // margin: EdgeInsets.symmetric(horizontal: mq.width * 0.02),
            padding: widget.message.type == Type.text ? EdgeInsets.all(mq.width * 0.04) : EdgeInsets.all(mq.width * 0.03),
           
            decoration: BoxDecoration(
                color: const Color.fromARGB(255, 209, 241, 214),
                border: Border.all(color: Colors.lightGreen),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(25),
                  bottomLeft: Radius.circular(30),
                )),
            child: widget.message.type == Type.text? Text(
              widget.message.message,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            )
             : ClipRRect(
                              borderRadius:
                                  BorderRadius.circular(mq.height * 0.02),
                              child: CachedNetworkImage(
                                fit: BoxFit.fill,
                                height: mq.height * 0.23,
                                width: mq.width * 0.5,
                                imageUrl: widget.message.message,
                                placeholder: (context, url) => const Center(
                                    child: CircularProgressIndicator()),
                                errorWidget: (context, url, error) =>
                                    const Icon(
                                  Icons.image,
                                  color: Colors.blue,
                                ),
                              ),
                            ),
                   ),
         ),
        
        
        
        
      ],
    );
  }

    // bottom sheet for modifying message details
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              //black divider
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: const BoxDecoration(
                    color: Colors.grey,
                    borderRadius: BorderRadius.all(Radius.circular(8))),
              ),

              widget.message.type == Type.text
                  ?
                  //copy option
                  _OptionItem(
                      icon: const Icon(Icons.copy_all_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.message))
                            .then((value) {
                          //for hiding bottom sheet
                          Navigator.pop(context);

                          Dialogs.showSnackBar(context, 'Text Copied!');
                        });
                      }
                      )
                  :
                  //save option
                  _OptionItem(
                      icon: const Icon(Icons.download_rounded,
                          color: Colors.blue, size: 26),
                      name: 'Save Image',
                      onTap: () async {
                        try {
                          log('Image Url: ${widget.message.message}');
                          await GallerySaver.saveImage(widget.message.message,
                                  albumName: 'Chime')
                              .then((success) {
                            //for hiding bottom sheet
                            Navigator.pop(context);
                            if (success != null && success) {
                              Dialogs.showSnackBar(
                                  context, 'Image Successfully Saved!');
                            }
                          });
                        } catch (e) {
                          log('ErrorWhileSavingImg: $e');
                        }
                      }
                      ),

              //separator or divider
              if (isMe)
                Divider(
                  color: Colors.black54,
                  endIndent: mq.width * .04,
                  indent: mq.width * .04,
                ),

              //edit option
              if (widget.message.type == Type.text && isMe)
                _OptionItem(
                    icon: const Icon(Icons.edit, color: Colors.blue, size: 26),
                    name: 'Edit Message',
                    onTap: () {
                      //for hiding bottom sheet
                      Navigator.pop(context);

                      _showMessageUpdateDialog();
                    }
                    ),

              //delete option
              if (isMe)
                _OptionItem(
                    icon: const Icon(Icons.delete_forever,
                        color: Colors.red, size: 26),
                    name: 'Delete Message',
                    onTap: () async {
                      await Apis.deleteMessage(widget.message).then((value) {
                        //for hiding bottom sheet
                        Navigator.pop(context);
                      });
                    }

                    ),

              //separator or divider
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //sent time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.blue),
                  name:
                      'Sent At: ${MyDateUtils.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              //read time
              _OptionItem(
                  icon: const Icon(Icons.remove_red_eye, color: Colors.green),
                  name: widget.message.read.isEmpty
                      ? 'Read At: Not seen yet'
                      : 'Read At: ${MyDateUtils.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  //dialog for updating message content
  void _showMessageUpdateDialog() {
    String updatedMsg = widget.message.message;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              contentPadding: const EdgeInsets.only(
                  left: 24, right: 24, top: 20, bottom: 10),

              shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(20))),

              //title
              title: const Row(
                children: [
                  Icon(
                    Icons.message,
                    color: Colors.blue,
                    size: 28,
                  ),
                  Text(' Edit Message')
                ],
              ),

              //content
              content: TextFormField(
                initialValue: updatedMsg,
                maxLines: null,
                onChanged: (value) => updatedMsg = value,
                decoration: const InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)))),
              ),

              //actions
              actions: [
                //cancel button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                    },
                    child: const Text(
                      'Cancel',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    )),

                //update button
                MaterialButton(
                    onPressed: () {
                      //hide alert dialog
                      Navigator.pop(context);
                      Apis.updateMessage(widget.message, updatedMsg);
                    },
                    child: const Text(
                      'Done',
                      style: TextStyle(color: Colors.blue, fontSize: 16),
                    ))
              ],
            ));
  }

  

}

//custom options card (for copy, edit, delete, etc.)
class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => onTap(),
        child: Padding(
          padding: EdgeInsets.only(
              left: mq.width * .05,
              top: mq.height * .015,
              bottom: mq.height * .015),
          child: Row(children: [
            icon,
            Flexible(
                child: Text('    $name',
                    style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black54,
                        letterSpacing: 0.5)))
          ]),
        ));
  }
}
