import 'dart:developer';
import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:moha_chat/helper/my_date_util.dart';
import 'package:moha_chat/models/chat_user.dart';
import 'package:moha_chat/screens/view_profile_screen.dart';

import '../api/api.dart';
import '../main.dart';
import '../models/message.dart';
import '../widgets/message_card.dart';

class ChatScreen extends StatefulWidget {
  final ChatUser user;

  const ChatScreen({super.key, required this.user});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  //for storing all messages
  List<Messages> _list = [];

  //for handling message text changes
  final _textController = TextEditingController();

  //for storing value of emoji and for checking is uploading images or not
  bool _showEmoji = false, _isUploading = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: SafeArea(
        child: PopScope(
          //if emoji is on & back button is pressed then close search
          //or else simple close current screen on back button click
          onPopInvoked: (bool dipPop) async {
            if (_showEmoji) {
              setState(() {
                _showEmoji = !_showEmoji;
              });
              return Future.value(false);
            } else {
              return Future.value(true);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              flexibleSpace: _appBar(),
            ),
            backgroundColor: Color.fromARGB(250, 223, 248, 250),
            body: Column(children: [
              Expanded(
                child: StreamBuilder(
                  stream: APIs.getAllMessages(widget.user),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      //if data is loading
                      case ConnectionState.waiting:
                      case ConnectionState.none:
                        return const Center(child: CircularProgressIndicator());
                      //if some or all data is loaded then show ot
                      case ConnectionState.active:
                      case ConnectionState.done:
                    }

                    final data = snapshot.data?.docs;
                    _list = data
                            ?.map((e) => Messages.fromJson(e.data()))
                            .toList() ??
                        [];

                    if (_list.isNotEmpty) {
                      return ListView.builder(
                          reverse: true,
                          itemCount: _list.length,
                          padding: EdgeInsets.only(top: mq.height * .01),
                          physics: BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            return MessageCard(message: _list[index]);
                          });
                    } else {
                      return Center(
                        child: Text(
                          'Say  Hii 👋😁!!',
                          style: TextStyle(fontSize: 20),
                        ),
                      );
                    }
                  },
                ),
              ),
              //progress indicator for showing uploading
              if (_isUploading)
                Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding:
                          EdgeInsets.symmetric(vertical: 8.0, horizontal: 20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )),
              _chatInput(),

              //show emoji on keyboard emoji button click & vice versa
              if (_showEmoji)
                SizedBox(
                  height: mq.height * .34,
                  child: EmojiPicker(
                    textEditingController: _textController,
                    config: Config(
                      bgColor: Color.fromARGB(255, 234, 248, 255),
                      columns: 8,
                      emojiSizeMax: 32 * (Platform.isAndroid ? 1.30 : 1.0),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _appBar() {
    return InkWell(
      onTap: () {
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ViewProfileScreen(user: widget.user)));
      },
      child: StreamBuilder(
          stream: APIs.getUserInfo(widget.user),
          builder: (context, snapshot) {
            final data = snapshot.data?.docs;
            final list =
                data?.map((e) => ChatUser.fromJson(e.data())).toList() ?? [];
            return Row(
              children: [
                IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.arrow_back,
                      color: Colors.black54,
                    )),
                ClipRRect(
                  borderRadius: BorderRadius.circular(mq.height * .3),
                  child: CachedNetworkImage(
                    width: mq.height * .055,
                    height: mq.height * .055,
                    imageUrl:
                        list.isNotEmpty ? list[0].image : widget.user.image,
                    errorWidget: (context, url, error) =>
                        CircleAvatar(child: Icon(Icons.person)),
                  ),
                ),
                SizedBox(width: 10),
                Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        list.isNotEmpty ? list[0].name : widget.user.name,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        list.isNotEmpty
                            ? list[0].isOnline
                                ? 'Online'
                                : MyDataUtil.getLastActiveTime(
                                    context: context,
                                    lastActive: list[0].lastActive)
                            : MyDataUtil.getLastActiveTime(
                                context: context,
                                lastActive: widget.user.lastActive),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.black54,
                        ),
                      ),
                    ]),
              ],
            );
          }),
    );
  }

  Widget _chatInput() {
    return Padding(
      padding: EdgeInsets.symmetric(
          vertical: mq.height * .01, horizontal: mq.width * .02),
      child: Row(
        children: [
          //input Field & button
          Expanded(
            child: Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  //Pick emoji button
                  IconButton(
                      onPressed: () {
                        FocusScope.of(context).unfocus();
                        setState(() => _showEmoji = !_showEmoji);
                      },
                      icon: Icon(
                        Icons.emoji_emotions,
                        color: Colors.lightBlueAccent,
                        size: 25,
                      )),

                  //for write message
                  Expanded(
                      child: TextField(
                    controller: _textController,
                    keyboardType: TextInputType.multiline,
                    onTap: () {
                      if (_showEmoji) setState(() => _showEmoji = !_showEmoji);
                    },
                    maxLines: null,
                    decoration: InputDecoration(
                        hintText: 'Type Something...',
                        hintStyle: TextStyle(color: Colors.lightBlueAccent),
                        border: InputBorder.none),
                  )),
                  //Pick Image from Gallery Button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick Multiple images.
                        final List<XFile> images =
                            await picker.pickMultiImage(imageQuality: 70);
                        for (var i in images) {
                          log('Image Path: ${i.path} ');
                          setState(() => _isUploading = true);
                          APIs.sendChatImage(widget.user, File(i.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(
                        Icons.image,
                        color: Colors.lightBlueAccent,
                        size: 26,
                      )),
                  //take Image from Camera Button
                  IconButton(
                      onPressed: () async {
                        final ImagePicker picker = ImagePicker();
                        // Pick an image.
                        final XFile? image = await picker.pickImage(
                            source: ImageSource.camera, imageQuality: 70);
                        if (image != null) {
                          log('Image Path: ${image.path} ');
                          setState(() => _isUploading = true);
                          await APIs.sendChatImage(
                              widget.user, File(image.path));
                          setState(() => _isUploading = false);
                        }
                      },
                      icon: Icon(
                        Icons.camera_alt,
                        color: Colors.lightBlueAccent,
                        size: 26,
                      )),
                ],
              ),
            ),
          ),
          //send message button
          MaterialButton(
              shape: CircleBorder(),
              color: Colors.lightBlueAccent,
              onPressed: () {
                if (_textController.text.isNotEmpty) {
                  if (_list.isEmpty) {
                    //on first message (add user to my_user collection of chat user)
                    APIs.sendFirstMessage(
                        widget.user, _textController.text, Type.text);
                  } else {
                    //simply send message
                    APIs.sendMessage(
                        widget.user, _textController.text, Type.text);
                  }
                  _textController.text = '';
                }
              },
              minWidth: 0,
              padding: EdgeInsets.only(top: 10, right: 5, bottom: 10, left: 10),
              child: Icon(Icons.send, color: Colors.white, size: 28)),
          SizedBox(width: mq.width * .02),
        ],
      ),
    );
  }
}
