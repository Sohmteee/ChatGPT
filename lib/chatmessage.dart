import 'package:flutter/material.dart';
import 'package:flutter_chat_bubble/chat_bubble.dart';
import 'package:swipe_to/swipe_to.dart';
import 'package:velocity_x/velocity_x.dart';

import 'data.dart';

class ChatMessage extends StatefulWidget {
  const ChatMessage({
    super.key,
    required this.text,
    required this.sender,
    required this.context,
  });

  final String text;
  final MessageSender sender;
  final BuildContext context;

  @override
  State<ChatMessage> createState() => _ChatMessageState();
}

class _ChatMessageState extends State<ChatMessage> {
  @override
  Widget build(BuildContext context) {
    return SwipeTo(
      onRightSwipe: () {
        setState(() {
          context.
          isResponse = true;
          replyMessage = ChatMessage(
            text: widget.text,
            sender: widget.sender,
            context: context,
          );
          debugPrint("Replying to: ${replyMessage!.text}");
        });
      },
      child: Row(
        mainAxisAlignment: widget.sender == MessageSender.user
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.sender == MessageSender.bot)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Vx.zinc200,
                  backgroundImage: AssetImage("assets/images/chatgpt_icon.png"),
                ),
              ),
            ),
          ChatBubble(
            clipper: ChatBubbleClipper8(
                type: widget.sender == MessageSender.user
                    ? BubbleType.sendBubble
                    : BubbleType.receiverBubble),
            margin: const EdgeInsets.only(top: 20),
            backGroundColor:
                widget.sender == MessageSender.user ? Vx.green500 : Vx.zinc200,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.7,
              ),
              child: Text(
                widget.text.trim(),
                style: TextStyle(
                  color: widget.sender == MessageSender.user
                      ? Colors.white
                      : Colors.black,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (widget.sender == MessageSender.user)
            Padding(
              padding: const EdgeInsets.only(top: 23),
              child: Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                child: const CircleAvatar(
                  radius: 15,
                  backgroundColor: Vx.green500,
                  child: Icon(
                    size: 18,
                    color: Colors.white,
                    Icons.person,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
