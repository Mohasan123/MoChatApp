import 'dart:developer';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gallery_saver/gallery_saver.dart';
import 'package:moha_chat/api/api.dart';
import 'package:moha_chat/helper/my_date_util.dart';

import '../helper/dialogs.dart';
import '../main.dart';
import '../models/message.dart';

class MessageCard extends StatefulWidget {
  final Messages message;

  const MessageCard({super.key, required this.message});

  @override
  State<MessageCard> createState() => _MessageCardState();
}

class _MessageCardState extends State<MessageCard> {
  @override
  Widget build(BuildContext context) {
    bool isMe = APIs.user.uid == widget.message.fromId;
    return GestureDetector(
        onLongPress: () {
          _showBottomSheet(isMe);
        },
        child: isMe ? _receiverMessage() : _senderMessage());
  }

  //sender or another user message
  Widget _senderMessage() {
    //update last read message if sender and receiver are different

    if (widget.message.read.isEmpty) {
      APIs.updateMessageReadStatus(widget.message);
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 221, 245, 255),
                border: Border.all(color: Colors.blueAccent),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                    bottomRight: Radius.circular(25))),
            child: widget.message.type == Type.text
                ?
                //show image
                Text(
                    widget.message.msg,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  )
                :
                //show image
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      imageUrl: widget.message.msg,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ),
        Padding(
          padding: EdgeInsets.only(right: mq.width * .04),
          child: Text(
            MyDataUtil.getFormattedTime(
                context: context, time: widget.message.sent),
            style: TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ),
      ],
    );
  }

  //receiver or another user message
  Widget _receiverMessage() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            //for adding some space
            SizedBox(width: mq.width * .04),
            //double tick blue icon for message read
            if (widget.message.read.isNotEmpty)
              Icon(Icons.done_all, color: Colors.blue, size: 20),
            //for adding some space
            SizedBox(width: 2),
            //sent time
            Text(
              MyDataUtil.getFormattedTime(
                  context: context, time: widget.message.sent),
              style: TextStyle(fontSize: 13, color: Colors.black54),
            ),
          ],
        ),
        Flexible(
          child: Container(
            padding: EdgeInsets.all(widget.message.type == Type.image
                ? mq.width * .03
                : mq.width * .04),
            margin: EdgeInsets.symmetric(
                horizontal: mq.width * .04, vertical: mq.height * .01),
            decoration: BoxDecoration(
                color: Color.fromARGB(255, 218, 255, 176),
                border: Border.all(color: Colors.green),
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(25),
                    topRight: Radius.circular(25),
                    bottomLeft: Radius.circular(25))),
            child: widget.message.type == Type.text
                ?
                //show text
                Text(
                    widget.message.msg,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  )
                :
                // show image
                ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: CachedNetworkImage(
                      placeholder: (context, url) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      imageUrl: widget.message.msg,
                      errorWidget: (context, url, error) =>
                          Icon(Icons.image, size: 70),
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  //bottom sheet for picking a profile picture for user
  void _showBottomSheet(bool isMe) {
    showModalBottomSheet(
        context: context,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20), topRight: Radius.circular(20))),
        builder: (_) {
          return ListView(
            shrinkWrap: true,
            children: [
              Container(
                height: 4,
                margin: EdgeInsets.symmetric(
                    vertical: mq.height * .015, horizontal: mq.width * .4),
                decoration: BoxDecoration(
                    color: Colors.grey, borderRadius: BorderRadius.circular(8)),
              ),

              widget.message.type == Type.text
                  ? //copy option
                  _OptionItem(
                      icon: Icon(
                        Icons.copy,
                        color: Colors.lightBlueAccent,
                        size: 26,
                      ),
                      name: 'Copy Text',
                      onTap: () async {
                        await Clipboard.setData(
                                ClipboardData(text: widget.message.msg))
                            .then((value) {
                          Navigator.pop(context);
                          Dialogs.showSnackBar(context, 'Text Copied!');
                        });
                      })
                  : //copy option
                  _OptionItem(
                      icon: Icon(
                        Icons.download,
                        color: Colors.lightBlueAccent,
                        size: 26,
                      ),
                      name: 'Save Image',
                      onTap: () async {
                        try {
                          log('Image Uri : ${widget.message.msg}');
                          await GallerySaver.saveImage(widget.message.msg,
                                  albumName: 'Mo Chat')
                              .then((success) {
                            Navigator.pop(context);
                            if (success != null && success)
                              Dialogs.showSnackBar(
                                  context, 'Image Successfully Saved!');
                          });
                        } catch (e) {
                          log('ErrorWhileSaving: $e');
                        }
                      }),
              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),

              //edit option
              if (widget.message.type == Type.text && isMe)
                _OptionItem(
                    icon: Icon(
                      Icons.edit,
                      color: Colors.lightBlueAccent,
                    ),
                    name: 'Edit Message',
                    onTap: () {
                      //for hiding bottom sheet
                      Navigator.pop(context);
                      _showMessageUpdateDialog();
                    }),

              //delete option
              if (isMe)
                _OptionItem(
                    icon: Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                      size: 26,
                    ),
                    name: 'Delete Message',
                    onTap: () {
                      APIs.deleteMessage(widget.message).then((value) {
                        Navigator.pop(context);
                      });
                    }),

              Divider(
                color: Colors.black54,
                endIndent: mq.width * .04,
                indent: mq.width * .04,
              ),
              //sent option
              _OptionItem(
                  icon: Icon(
                    Icons.remove_red_eye,
                    color: Colors.lightBlueAccent,
                  ),
                  name:
                      'Sent At: ${MyDataUtil.getMessageTime(context: context, time: widget.message.sent)}',
                  onTap: () {}),

              //read option
              _OptionItem(
                  icon: Icon(Icons.remove_red_eye_outlined,
                      color: Colors.greenAccent),
                  name: widget.message.read.isEmpty
                      ? 'Not seen yet'
                      : 'Read At: ${MyDataUtil.getMessageTime(context: context, time: widget.message.read)}',
                  onTap: () {}),
            ],
          );
        });
  }

  void _showMessageUpdateDialog() {
    String updateMsg = widget.message.msg;

    showDialog(
        context: context,
        builder: (_) => AlertDialog(
          contentPadding: EdgeInsets.only(left: 24, right: 24, top: 20, bottom: 10),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              //title
              title: Row(
                children: [
                  Icon(
                    Icons.message,
                    color: Colors.lightBlue,
                    size: 28,
                  ),
                  Text(' Update Message'),
                ],
              ),
              //content
              content: TextFormField(
                initialValue: updateMsg,
                maxLines: null,
                onChanged: (value) => updateMsg = value,
                decoration: InputDecoration(
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15))),
              ),
              //actions
              actions: [
                MaterialButton(
                  onPressed: () {
                    //hide Alert Dialogs
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ), 
                MaterialButton(
                  onPressed: () {
                    Navigator.pop(context);
                    APIs.updateMessage(widget.message.msg as Messages, updateMsg);
                  },
                  child: Text(
                    'Update',
                    style: TextStyle(color: Colors.blue, fontSize: 16),
                  ),
                ),
              ],
            ));
  }
}

class _OptionItem extends StatelessWidget {
  final Icon icon;
  final String name;
  final VoidCallback onTap;

  const _OptionItem(
      {required this.icon, required this.name, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.only(
            left: mq.width * .05,
            top: mq.height * .015,
            bottom: mq.height * .02),
        child: Row(children: [
          icon,
          Flexible(
              child: Text(
            '      $name',
            style: TextStyle(
                fontSize: 15, color: Colors.black54, letterSpacing: 0.5),
          )),
        ]),
      ),
    );
  }
}
