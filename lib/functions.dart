import 'package:auscy/chatmessage.dart';

import 'data.dart';

jsonToChatMessage(Map<String, dynamic> json) {
  return ChatMessage(
    text: json['text'],
    sender: json['sender'],
    time: json['time'],
  );
}

Future createMessage(
    {required String username}) async {
  final docUser = db.collection('chat').doc(username);

  await docUser.set({
    'messages' : messagesInJSON,
  });

  await db.collection("${mycol}").doc("${mydoc}").update({
    'url': FieldValue.arrayUnion([videos]),
  });
}
