

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sound/flutter_sound.dart'  as fs;

import 'package:image_picker/image_picker.dart';
import 'package:p7/components/chat_bubble.dart';
import 'package:p7/components/my_text_field.dart';
import 'package:p7/service/auth.dart';
import 'package:p7/service/chat_service.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../components/audio_player_widget.dart';
import '../models/messenge.dart';
import '../service/cloudinary_service.dart';


class ChatPage extends StatefulWidget {
  final String receiverUsername;
  final String receiverID;

  const ChatPage({
    super.key,
    required this.receiverUsername,
    required this.receiverID,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier(false);

  final ChatService _chatService = ChatService();
  final Auth _auth = Auth();

  bool _isRecording = false;
  final fs.FlutterSoundRecorder _recorder = fs.FlutterSoundRecorder();


  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      _hasTextNotifier.value = _controller.text.trim().isNotEmpty;
    });
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 500), _scrollToBottom);
      }
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _hasTextNotifier.dispose();
    super.dispose();
  }


  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    await _chatService.sendMessage(widget.receiverID, text);
    _controller.clear();
    _scrollToBottom();
  }

  Future<void> sendImageMessage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    try {
      final imageUrl = await CloudinaryService.uploadAvatar(filePath: pickedFile.path);
      if (imageUrl == null) throw Exception('Image upload failed');

      await _chatService.sendMessageWithImage(
        receiverId: widget.receiverID,
        imageUrl: imageUrl,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error uploading image')),
      );
    }
  }



  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Microphone Blocked'),
          content: const Text(
              'Microphone access has been permanently denied.\n'
                  'Please open settings and allow microphone access.'
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Open Settings'),
            ),
          ],
        ),
      );

      if (go == true) {
        await openAppSettings();
      }
      return false;
    }

    if (status.isDenied) {
      status = await Permission.microphone.request();
    }

    return status.isGranted;
  }

  Future<void> _startRecording() async {
    if (!await _checkPermission()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Microphone permission required')),
      );
      return;
    }

    try {
      if (!_recorder.isRecording) {
        final tempDir = await getTemporaryDirectory();
        final path =
            '${tempDir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _recorder.openRecorder();
        await _recorder.startRecorder(
          toFile: path,
          codec: fs.Codec.aacMP4,
          bitRate: 128000,
          sampleRate: 44100,
        );

        setState(() => _isRecording = true);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Recording error: $e')),
      );
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final result = await _recorder.stopRecorder();
      setState(() => _isRecording = false);

      if (result != null) {
        final url = await CloudinaryService.uploadAudio(filePath: result);
        if (url != null) {
          await _chatService.sendMessage(
            widget.receiverID,
            url,
            type: 'audio',
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error stopping recording: $e')),
        );
      }
    } finally {
      await _recorder.closeRecorder();
    }
  }


  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 500), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final myId = _auth.getCurrentUid();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          widget.receiverUsername,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Сообщения
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatService.getMessage(myId, widget.receiverID),
              builder: (ctx, snap) {
                if (snap.hasError) {
                  return Center(child: Text("Ошибка загрузки"));
                }
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(child: Text("Нет сообщений"));
                }
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _scrollToBottom();
                });
                return ListView.builder(
                  controller: _scrollController,
                  itemCount: docs.length,
                  itemBuilder: (_, i) {
                    final doc = docs[i];
                    final data = doc.data()! as Map<String, dynamic>;
                    final msg = Message.fromMap(data);
                    final isMine = msg.senderID == myId;


                    // ➡️ Отображение сообщений
                    if (msg.type == 'audio') {
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatAudioPlayer(url: msg.message, isCurrentUser: isMine,),
                      );
                    } else if (msg.type == 'image') {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Align(
                          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              msg.message,
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      );
                    } else {
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: ChatBubble(
                          message: msg.message,
                          isCurrentUser: isMine,
                          userID: msg.senderID,
                          messageID: doc.id,
                        ),
                      );
                    }
                  },
                );
              },
            ),
          ),

          // Ввод текста и кнопки
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: ValueListenableBuilder<bool>(
              valueListenable: _hasTextNotifier,
              builder: (context, hasText, _) {
                return Row(
                  children: [
                    IconButton(
                      onPressed: sendImageMessage,
                      icon: Icon(Icons.photo, size: 32, color: Theme.of(context).colorScheme.onSurface),
                    ),
                    Expanded(
                      child: MyTextField(
                        textEditingController: _controller,
                        obscureText: false,
                        hintText: "Message",
                        focusNode: _focusNode,
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: hasText
                          ? Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF37aee2), Color(0xFF1E96C8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          onPressed: _sendMessage,
                          icon: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                          splashRadius: 24,
                        ),
                      )
                          : IconButton(
                        onPressed: _isRecording ? _stopRecordingAndSend : _startRecording,
                        icon: Icon(
                          _isRecording ? Icons.stop : Icons.keyboard_voice_sharp,
                          size: 32,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        splashRadius: 24,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}