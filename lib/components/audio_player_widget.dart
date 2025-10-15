import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

class ChatAudioPlayer extends StatefulWidget {
  final String url;
  final bool isCurrentUser;
  const ChatAudioPlayer({
    super.key,
    required this.url,
    required this.isCurrentUser,
});

  @override
  State<ChatAudioPlayer> createState() => _ChatAudioPlayerState();
}

class _ChatAudioPlayerState extends State<ChatAudioPlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();

    _player.onDurationChanged.listen((d) {
      setState(() => _duration = d);
    });

    _player.onPositionChanged.listen((p) {
      setState(() => _position = p);
    });

    _player.onPlayerStateChanged.listen((state) {
      setState(() => _isPlaying = state == PlayerState.playing);
    });
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
    } else {
      await _player.play(UrlSource(widget.url));
    }
  }


  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme
        .of(context)
        .colorScheme;
    final bubbleColor = widget.isCurrentUser
        ? scheme.primaryContainer // мои
        : scheme.secondaryContainer; // чужие
    final accentColor = widget.isCurrentUser
        ? scheme.primary
        : scheme.secondary;

    return Align(
      alignment: widget.isCurrentUser
          ? Alignment.centerRight
          : Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.all(5),
        margin: const EdgeInsets.symmetric(vertical: 2.5, horizontal: 25),
        decoration: BoxDecoration(
          color: bubbleColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: _togglePlay,
              icon: Icon(
                _isPlaying ? Icons.pause : Icons.play_arrow,
                color: accentColor,
              ),
            ),
            Text(
              _format(_position),
              style: TextStyle(color: scheme.onSurface),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: _duration.inSeconds == 0
                    ? 0
                    : _position.inSeconds / _duration.inSeconds,
                color: accentColor,
                backgroundColor: scheme.surfaceVariant,
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}