import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_sound/flutter_sound.dart' as fs;
import 'package:p7/components/chat_bubble.dart';
import 'package:p7/components/my_text_field.dart';
import 'package:p7/service/auth.dart';
import 'package:p7/service/chat_service.dart';
import 'package:p7/service/cloudinary_service.dart';
import '../components/audio_player_widget.dart';
import '../models/messenge.dart';

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

class _ChatPageState extends State<ChatPage> with WidgetsBindingObserver {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  final ValueNotifier<bool> _hasTextNotifier = ValueNotifier(false);

  final ChatService _chatService = ChatService();
  final Auth _auth = Auth();

  bool _isRecording = false;
  bool _isUploading = false;
  final fs.FlutterSoundRecorder _recorder = fs.FlutterSoundRecorder();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _controller.addListener(() {
      _hasTextNotifier.value = _controller.text.trim().isNotEmpty;
    });

    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        Future.delayed(const Duration(milliseconds: 300), _scrollToBottom);
      }
    });

    _markMessagesAsRead();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _focusNode.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _hasTextNotifier.dispose();
    _recorder.closeRecorder();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _markMessagesAsRead();
    }
  }

  Future<void> _markMessagesAsRead() async {
    try {
      await _chatService.markMessagesAsRead(
        _auth.getCurrentUid(),
        widget.receiverID,
      );
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
    }
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    FocusScope.of(context).unfocus();

    try {
      await _chatService.sendMessage(widget.receiverID, text);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showError('Ошибка отправки сообщения');
      }
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);

    try {
      final imageUrl = await CloudinaryService.uploadAvatar(
        filePath: pickedFile.path,
      );

      if (imageUrl == null) throw Exception('Upload failed');

      await _chatService.sendMessageWithImage(
        receiverId: widget.receiverID,
        imageUrl: imageUrl,
      );

      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        _showError('Ошибка загрузки изображения');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  Future<bool> _checkPermission() async {
    var status = await Permission.microphone.status;

    if (status.isPermanentlyDenied) {
      final go = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Микрофон заблокирован'),
          content: const Text(
            'Доступ к микрофону постоянно запрещён.\n'
                'Откройте настройки и разрешите доступ.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Отмена'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Открыть настройки'),
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
      _showError('Требуется доступ к микрофону');
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
      _showError('Ошибка записи: $e');
    }
  }

  Future<void> _stopRecordingAndSend() async {
    try {
      final result = await _recorder.stopRecorder();
      setState(() => _isRecording = false);

      if (result != null) {
        setState(() => _isUploading = true);

        final url = await CloudinaryService.uploadAudio(filePath: result);

        if (url != null) {
          await _chatService.sendMessage(
            widget.receiverID,
            url,
            type: 'audio',
          );
          _scrollToBottom();
        } else {
          _showError('Ошибка загрузки аудио');
        }

        setState(() => _isUploading = false);
      }
    } catch (e) {
      _showError('Ошибка остановки записи: $e');
      setState(() => _isUploading = false);
    } finally {
      await _recorder.closeRecorder();
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;

    Future.delayed(const Duration(milliseconds: 200), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
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
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Divider(
                height: 1,
                thickness: 0.5,
                color: Theme.of(context).colorScheme.primaryContainer,
              ),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _chatService.getMessage(myId, widget.receiverID),
                  builder: (ctx, snap) {
                    if (snap.hasError) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ошибка загрузки',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.error,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    if (snap.connectionState == ConnectionState.waiting) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      );
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 80,
                              color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Нет сообщений',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary,
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Начните общение!',
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.7),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      _scrollToBottom();
                    });

                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final doc = docs[i];
                        final data = doc.data()! as Map<String, dynamic>;
                        final msg = Message.fromMap(data);
                        final isMine = msg.senderID == myId;

                        final showDateSeparator = i == 0 || _shouldShowDateSeparator(
                          docs[i - 1].data() as Map<String, dynamic>,
                          data,
                        );

                        return Column(
                          children: [
                            if (showDateSeparator)
                              _buildDateSeparator(msg.timestamp.toDate()),

                            _buildMessage(msg, isMine, doc.id),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),

              _buildMessageInput(),
            ],
          ),

          if (_isUploading)
            Container(
              color: Colors.black26,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Загрузка...',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  bool _shouldShowDateSeparator(Map<String, dynamic> prevData, Map<String, dynamic> currentData) {
    final prevTime = (prevData['timestamp'] as Timestamp).toDate();
    final currentTime = (currentData['timestamp'] as Timestamp).toDate();

    return prevTime.day != currentTime.day ||
        prevTime.month != currentTime.month ||
        prevTime.year != currentTime.year;
  }

  Widget _buildDateSeparator(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(date.year, date.month, date.day);

    String dateText;
    if (messageDate == today) {
      dateText = 'Сегодня';
    } else if (messageDate == today.subtract(const Duration(days: 1))) {
      dateText = 'Вчера';
    } else {
      dateText = '${date.day}.${date.month}.${date.year}';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          dateText,
          style: TextStyle(
            color: Theme.of(context).colorScheme.secondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildMessage(Message msg, bool isMine, String docId) {
    if (msg.type == 'audio') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ChatAudioPlayer(
            url: msg.message,
            isCurrentUser: isMine,
            timestamp: msg.timestamp,  // Время уже встроено в компонент
          ),
        ),
      );
    } else if (msg.type == 'image') {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          crossAxisAlignment: isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Align(
              alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
              child: GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      child: Stack(
                        children: [
                          InteractiveViewer(
                            child: Center(
                              child: Image.network(msg.message),
                            ),
                          ),
                          Positioned(
                            top: 40,
                            right: 20,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 30),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: msg.message,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            msg.message,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 250,
                                height: 250,
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.error_outline, size: 40),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Ошибка загрузки',
                                      style: TextStyle(
                                        color: Theme.of(context).colorScheme.secondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                        // Время на изображении
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _formatTime(msg.timestamp),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: ChatBubble(
            message: msg.message,
            isCurrentUser: isMine,
            userID: msg.senderID,
            messageID: docId,
            timestamp: msg.timestamp,
          ),
        ),
      );
    }
  }

  String _formatTime(Timestamp timestamp) {
    final date = timestamp.toDate();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.primaryContainer,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              onPressed: _isUploading ? null : () => _pickAndSendImage(ImageSource.gallery),
              icon: Icon(
                Icons.add_circle_outline,
                size: 28,
                color: _isUploading
                    ? Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3)
                    : Theme.of(context).colorScheme.primary,
              ),
              tooltip: 'Прикрепить',
            ),

            Expanded(
              child: ValueListenableBuilder<bool>(
                valueListenable: _hasTextNotifier,
                builder: (context, hasText, _) {
                  return MyTextField(
                    textEditingController: _controller,
                    obscureText: false,
                    hintText: "Сообщение",
                    focusNode: _focusNode,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                  );
                },
              ),
            ),

            const SizedBox(width: 8),

            ValueListenableBuilder<bool>(
              valueListenable: _hasTextNotifier,
              builder: (context, hasText, _) {
                return SizedBox(
                  width: 48,
                  height: 48,
                  child: hasText
                      ? Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Theme.of(context).colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: _isUploading ? null : _sendMessage,
                      icon: Icon(
                        Icons.send_rounded,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 22,
                      ),
                      splashRadius: 24,
                    ),
                  )
                      : AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    child: IconButton(
                      onPressed: _isUploading
                          ? null
                          : (_isRecording
                          ? _stopRecordingAndSend
                          : _startRecording),
                      icon: Icon(
                        _isRecording ? Icons.stop_circle : Icons.mic,
                        size: 28,
                        color: _isUploading
                            ? Theme.of(context)
                            .colorScheme
                            .secondary
                            .withValues(alpha: 0.3)
                            : (_isRecording
                            ? Colors.red
                            : Theme.of(context).colorScheme.primary),
                      ),
                      splashRadius: 24,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}