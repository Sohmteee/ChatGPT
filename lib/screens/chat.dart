import 'dart:developer';
import 'dart:io';

import 'package:auscy/data.dart';
import 'package:auscy/data/colors/colors.dart';
import 'package:auscy/main.dart';
import 'package:auscy/models/chatroom.dart';
import 'package:auscy/providers/chatroom.dart';
import 'package:auscy/screens/sign_in.dart';
import 'package:auscy/widgets/text.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:http/http.dart' as http;
import 'package:iconly/iconly.dart';
import 'package:image_picker/image_picker.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:zoom_tap_animation/zoom_tap_animation.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    required this.chatRoom,
    super.key,
  });

  final ChatRoom chatRoom;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late Map<String, dynamic> chatInDB;

  final gemini = GenerativeModel(
      model: "gemini-1.5-flash",
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        temperature: .7,
      ));
  // double temp = .7;

  final TextEditingController _controller = TextEditingController();
  bool _isTyping = false;
  final types.User auscy = const types.User(
    id: 'auscy',
    firstName: 'Auscy',
    role: types.Role.admin,
  );

  @override
  void initState() {
    _loadChat();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    // final x = widget.chatRoom.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.chatRoom.title),
        actions: [
          ZoomTapAnimation(
            child: IconButton(
              splashColor: Colors.transparent,
              splashRadius: 1,
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (context) {
                      return Dialog(
                        child: Padding(
                          padding: EdgeInsets.all(20.w),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              AppBoldText(
                                'Rename Chat',
                                fontSize: 20.sp,
                              ),
                              SizedBox(height: 20.h),
                              TextField(
                                controller: TextEditingController(
                                    text: widget.chatRoom.title),
                                autofocus: true,
                                decoration: const InputDecoration(
                                  hintText: 'Enter new chat title',
                                ),
                                textCapitalization: TextCapitalization.words,
                                onSubmitted: (value) {
                                  context.read<ChatRoomProvider>().renameChat(
                                        context,
                                        chatRoom: widget.chatRoom,
                                        title: value,
                                      );
                                  Navigator.pop(context);
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    });
              },
              icon: const Icon(
                IconlyLight.edit,
              ),
            ),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.only(
          left: 8.sp,
          right: 8.sp,
          bottom: 8.sp,
        ),
        child: Chat(
          messages: widget.chatRoom.messages,
          scrollPhysics: const BouncingScrollPhysics(),
          onSendPressed: (message) {
            _handleSendPressed(message);
            debugPrint(widget.chatRoom.messages
                .map((e) => e.toJson()['text'])
                .toList()
                .toString());
          },
          user: widget.chatRoom.chat!.user,
          dateHeaderBuilder: (p0) {
            String headerText;
            getDateDifference() {
              final dayDiff = DateTime.now().difference(p0.dateTime).inDays;
              if (dayDiff == 0) {
                return 'Today';
              } else if (dayDiff == 1) {
                return 'Yesterday';
              } else {
                const monthNames = {
                  1: 'January',
                  2: 'February',
                  3: 'March',
                  4: 'April',
                  5: 'May',
                  6: 'June',
                  7: 'July',
                  8: 'August',
                  9: 'September',
                  10: 'October',
                  11: 'November',
                  12: 'December'
                };

                final monthName = monthNames[p0.dateTime.month] ?? '';
                final day = p0.dateTime.day;
                final year = p0.dateTime.year == DateTime.now().year
                    ? ''
                    : ', ${p0.dateTime.year}';

                return '$monthName $day$year';
              }
            }

            headerText = getDateDifference();

            return Container(
              padding: EdgeInsets.only(
                top: 8.sp,
                bottom: 8.sp,
              ),
              child: Center(
                child: Text(
                  headerText,
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            );
          },
          onAttachmentPressed: _handleAttachmentPressed,
          onMessageTap: _handleMessageTap,
          onMessageLongPress: (context, message) {
            debugPrint('Message long pressed: ${message.toJson()['text']}');
          },
          onPreviewDataFetched: _handlePreviewDataFetched,
          emojiEnlargementBehavior: EmojiEnlargementBehavior.multi,
          customBottomWidget: SizedBox(
            child: Column(
              children: [
                if (_isTyping)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        bottom: 8,
                      ),
                      child: Row(
                        children: [
                          const Text(
                            'Auscy is typing',
                            style: TextStyle(
                              color: Colors.grey,
                              // fontSize: 12,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          SpinKitThreeBounce(
                            color: primaryColor,
                            size: 20.sp,
                          ),
                        ],
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        onSubmitted: (value) {
                          _handleSendPressed(
                            types.PartialText(
                              text: value.trim(),
                            ),
                          );
                          _controller.clear();
                        },
                        onChanged: (value) {
                          setState(() {
                            sendIcon = value.trim().isEmpty
                                ? Icons.mic_rounded
                                : IconlyBold.send;
                          });
                        },
                        minLines: 1,
                        maxLines: 4,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText: 'Type a message',
                          hintStyle: const TextStyle(
                            color: Colors.grey,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.sp),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24.sp),
                            borderSide: BorderSide(
                              color: primaryColor,
                              width: 2.sp,
                            ),
                          ),
                          // filled: true,
                          // fillColor: Colors.grey[300],
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 12.h,
                          ),
                          prefixIcon: ZoomTapAnimation(
                            onTap: _handleImageSelection,
                            child: Icon(
                              IconlyLight.image,
                              color: Colors.black,
                              size: 25.sp,
                            ),
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.w),
                      child: ZoomTapAnimation(
                        child: Container(
                          padding: EdgeInsets.only(
                            left: 10.sp,
                            right: (sendIcon == IconlyBold.send ? 12 : 10).sp,
                            top: (sendIcon == IconlyBold.send ? 12 : 10).sp,
                            bottom: 12.sp,
                          ),
                          decoration: const BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            sendIcon,
                            color: Colors.white,
                            size: 25.sp,
                          ),
                        ),
                        onTap: () {
                          if (_controller.text.trim().isNotEmpty) {
                            _handleSendPressed(
                              types.PartialText(
                                text: _controller.text.trim(),
                              ),
                            );
                            _controller.clear();

                            _getResponse();
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String get preResponse {
    return '''
    You are an AI chatbot called Auscy created to be people's chat companions and help with any questions or requests they might ask.
    ''';
  }

  Future<List<Content>> segmentChat({int length = 20}) async {
    final messages =
        widget.chatRoom.messages.take(length).toList().reversed.toList();

    final List<Content> contents = [];

    for (var message in messages) {
      // String role = message.author.id == auscy.id ? 'yam doctor' : 'user';

      if (message is types.TextMessage) {
        contents.add(
          Content.text(message.text),
        );
      } else if (message is types.ImageMessage) {
        contents.add(
            Content.data('image/png', await File(message.uri).readAsBytes()));
      }
    }

    debugPrint(contents.toString());
    return contents;
  }

  void _getResponse() async {
    final messages = await segmentChat();

    setState(() {
      _isTyping = true;
    });

    final response = await gemini
        .generateContent([
          Content.text(preResponse),
          ...messages,
        ])
        .then((value) =>
            value.candidates.first.text?.trim() ??
            'I can\'t help you with that.')
        .catchError((error) =>
            'It looks like an error occurred. Check your internet connection and try again.');

    setState(() {
      _isTyping = false;
    });

    debugPrint(response);

    final message = types.TextMessage(
      id: widget.chatRoom.messages.isEmpty
          ? '0'
          : widget.chatRoom.messages.length.toString(),
      author: auscy,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: response.trim(),
    );

    await _addMessage(message);
  }

  /*  void _getImageResponse(Uint8List image) async {
    setState(() {
      _isTyping = true;
    });

    final response = await gemini
        .textAndImage(
          images: [image],
          text: '''
          Describe the image(s)
          If it contains yam(s), tell the user if the yam is good or bad, if it has any diseases.
          If they aren't pictures of yams, let the user know.
          $preResponse
          ''',
          generationConfig: GenerationConfig(
            temperature: temp,
          ),
        )
        .then((value) => value?.content?.parts?.last.text)
        .catchError((error) => error.toString());

    setState(() {
      _isTyping = false;
    });

    debugPrint(response);
    final message = types.TextMessage(
      id: widget.chatRoom.messages.isEmpty
              ? '0'
              : widget.chatRoom.messages.length.toString(),
      author: auscy,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      text: response ?? 'I cannot help you with that',
    );

    _addMessage(message);
  }
 */
  Future<void> _nameChat() async {
    final messages = await segmentChat(length: 5);

    final response = await gemini
        .generateContent([
          Content.text('''
Please name the chat based on the chat so far. Whatever your response is, it should be nothing more than 5 words. Don't use the word 'chat' in naming. The chat so far is as follows:\n
        '''),
          ...messages,
        ])
        .then((value) => value.candidates.first.text)
        .catchError((error) => 'New Chat');

    debugPrint('Chat Name: $response');
    setState(() {
      context.read<ChatRoomProvider>().renameChat(
            context,
            chatRoom: widget.chatRoom,
            title: response!.trim(),
          );
    });
  }

  Future<void> _addMessage(types.Message message) async {
    try {
      setState(() {
        widget.chatRoom.messages.insert(0, message);
      });
      await usersDB.doc(user!.uid).set(
        {
          'chats':
              (await usersDB.doc(user!.uid).get()).data()!['chats'].map((chat) {
            if (chat['id'] == widget.chatRoom.id) {
              chat['messages'].insert(0, message.toJson());
            }
            return chat;
          }).toList(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      log(e.toString());
    }

    if (widget.chatRoom.title == 'New Chat') {
      print('Name chat..........................................');
      _nameChat();
    }
  }

  void _handleAttachmentPressed() {
    _handleImageSelection();
  }

  /*  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      final message = types.FileMessage(
        author: widget.chatRoom.chat.user,
        createdAt: DateTime.now().millisecondsSinceEpoch,
        id: widget.chatRoom.messages.isEmpty
              ? '0'
              : widget.chatRoom.messages.length.toString(),
        mimeType: lookupMimeType(result.files.single.path!),
        name: result.files.single.name,
        size: result.files.single.size,
        uri: result.files.single.path!,
      );

      await _addMessage(message);
    }
  }
 */
  void _handleImageSelection() async {
    try {
      final result = await ImagePicker().pickImage(
        imageQuality: 70,
        maxWidth: 1440,
        source: ImageSource.gallery,
      );

      if (result != null) {
        final bytes = await result.readAsBytes();
        final image = await decodeImageFromList(bytes);

        final message = types.ImageMessage(
          id: widget.chatRoom.messages.isEmpty
              ? '0'
              : widget.chatRoom.messages.length.toString(),
          author: widget.chatRoom.chat!.user,
          createdAt: DateTime.now().millisecondsSinceEpoch,
          height: image.height.toDouble(),
          name: result.name,
          size: bytes.length,
          uri: result.path,
          width: image.width.toDouble(),
        );

        await _addMessage(message);
        _getResponse();
      }
    } catch (e) {
      print('Error picking image: $e');
    }
  }

  void _handleMessageTap(BuildContext _, types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        try {
          final index = widget.chatRoom.messages
              .indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (widget.chatRoom.messages[index] as types.FileMessage).copyWith(
            isLoading: true,
          );

          setState(() {
            widget.chatRoom.messages[index] = updatedMessage;
          });

          final client = http.Client();
          final request = await client.get(Uri.parse(message.uri));
          final bytes = request.bodyBytes;
          final documentsDir = (await getApplicationDocumentsDirectory()).path;
          localPath = '$documentsDir/${message.name}';

          if (!File(localPath).existsSync()) {
            final file = File(localPath);
            await file.writeAsBytes(bytes);
          }
        } finally {
          final index = widget.chatRoom.messages
              .indexWhere((element) => element.id == message.id);
          final updatedMessage =
              (widget.chatRoom.messages[index] as types.FileMessage).copyWith(
            isLoading: null,
          );

          setState(() {
            widget.chatRoom.messages[index] = updatedMessage;
          });
        }
      }

      await OpenFilex.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final index = widget.chatRoom.messages
        .indexWhere((element) => element.id == message.id);
    final updatedMessage =
        (widget.chatRoom.messages[index] as types.TextMessage).copyWith(
      previewData: previewData,
    );

    setState(() {
      widget.chatRoom.messages[index] = updatedMessage;
    });
  }

  void _handleSendPressed(types.PartialText message) async {
    final textMessage = types.TextMessage(
      author: widget.chatRoom.chat!.user,
      createdAt: DateTime.now().millisecondsSinceEpoch,
      id: const Uuid().v4(),
      text: message.text,
    );

    await _addMessage(textMessage);
  }

  void _loadChat() async {
    chatInDB = await usersDB.doc(user!.uid).get().then((data) {
      return (data.data()!['chats'] as List).singleWhere((chat) {
        return chat['id'] == widget.chatRoom.id;
      });
    });

    setState(() {
      widget.chatRoom.title = chatInDB['title'];
      widget.chatRoom.messages = (chatInDB['messages'] as List)
          .map((e) => types.Message.fromJson(e))
          .toList();
    });
  }
}
