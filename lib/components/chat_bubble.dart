import 'package:flutter/material.dart';
import 'package:p7/service/chat_service.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final String userID;
  final String messageID;
  final bool isCurrentUser;
  const ChatBubble({super.key,
  required this.message,
  required this.isCurrentUser,
  required this.userID,
  required this.messageID});


  void _showOptions(BuildContext pageCtx) {
    final cs = Theme.of(pageCtx).colorScheme;

    showModalBottomSheet(
      context: pageCtx,
      builder: (sheetCtx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.flag_outlined, color: cs.onSurface),
              title: Text('Report', style: TextStyle(color: cs.onSurface)),
              onTap: () async {
                Navigator.pop(sheetCtx);
                _reportDialog(pageCtx);
              },
            ),
            ListTile(
              leading: Icon(Icons.block_outlined, color: cs.onSurface),
              title: Text('Block user', style: TextStyle(color: cs.onSurface)),
              onTap: () async {
                final confirmed = await _blockDialog(pageCtx);
                Navigator.pop(sheetCtx);
                if (confirmed == true) Navigator.pop(pageCtx);
              },
            ),
            ListTile(
              leading: Icon(Icons.cancel, color: cs.onSurface),
              title: Text('Cancel', style: TextStyle(color: cs.onSurface)),
              onTap: () => Navigator.pop(sheetCtx),
            ),
          ],
        ),
      ),
    );
  }


  void _reportDialog(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Report message', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Are you sure you want to report this message?',
          style: TextStyle(color: cs.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: cs.secondary)),
          ),
          TextButton(
            onPressed: () {
              ChatService().reportUser(messageID, userID);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('Message reported')),
              );
            },
            child: Text('Report', style: TextStyle(color: cs.secondary)),
          ),
        ],
      ),
    );
  }


  Future<bool?> _blockDialog(BuildContext ctx) {
    final cs = Theme.of(ctx).colorScheme;

    return showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text('Block user', style: TextStyle(color: cs.onSurface)),
        content: Text(
          'Are you sure you want to block this user?',
          style: TextStyle(color: cs.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: cs.secondary)),
          ),
          TextButton(
            onPressed: () async {
              await ChatService().blockUser(userID);
              Navigator.pop(ctx, true);
              ScaffoldMessenger.of(ctx).showSnackBar(
                SnackBar(content: Text('User blocked!')),
              );
            },
            child: Text('Block', style: TextStyle(color: cs.secondary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        if (!isCurrentUser) {
          _showOptions(context);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: isCurrentUser ? Theme.of(context).colorScheme.primaryContainer : Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12)
        ),
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
        child: Text(message,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),),
      ),
    );
  }
}
