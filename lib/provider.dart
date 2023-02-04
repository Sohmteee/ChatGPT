import 'package:chat_gpt_02/chatmessage.dart';
import 'package:chat_gpt_02/reply_hover_bubble.dart';
import 'package:flutter/material.dart';

class MyProvider extends ChangeNotifier {
  String sender;
  String text;
  void Function(bool);
  void Function(ChatMessage);

  

  ReplyHoverBubble replyHoverBubble = ReplyHoverBubble(sender: sender, text: text, setResponse: setResponse, setReplyMessage: setReplyMessage)

}