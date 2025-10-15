import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:audioplayers/audioplayers.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  // Ваш список треков (пути относительно assets/)
  final List<String> _tracks = [
    'audio/Playboi Carti – ILoveUIHateU.mp3',
    'audio/Playboi Carti – Sky.mp3',
    'audio/The Weeknd – Baptized In Fear.mp3',
    'audio/The Weeknd – Cry For Me.mp3',
    'audio/The Weeknd – I Cant Fucking Sing.mp3',
    'audio/The Weeknd – Sao Paulo.mp3',
    'audio/The Weeknd – Until Were Skin and Bones.mp3',
    'audio/The Weeknd – Wake Me Up.mp3',
  ];
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Подписываемся на изменение длительности и позиции
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

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _stop() async {
    await _player.stop();
    setState(() {
      _position = Duration.zero;
      _isPlaying = false;
    });
  }



  void _next() {
    _stop();
    setState(() {
      _currentIndex = (_currentIndex + 1) % _tracks.length;
    });
  }

  void _prev() {
    _stop();
    setState(() {
      _currentIndex =
          (_currentIndex - 1 + _tracks.length) % _tracks.length;
    });
  }


  String _formatTime(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }


  @override
  Widget build(BuildContext context) {
    final fileName = _tracks[_currentIndex].split('/').last;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true,
        title: const Text("M U S I C"),
        foregroundColor: Theme.of(context).colorScheme.primary,
      ),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Анимация
            Container(
              height: 350,
              width: 350,
              padding: const EdgeInsets.all(12),
              child: Lottie.asset("assets/music.json"),
            ),

            const SizedBox(height: 16),

            // Название трека
            Text(
              fileName,
              style: TextStyle(
                fontSize: 20,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Ползунок и время
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Text(_formatTime(_position),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: Theme.of(context).colorScheme.primary,
                        inactiveTrackColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      child: Slider(
                      min: 0,
                      max: _duration.inSeconds.toDouble(),
                      value:
                      _position.inSeconds.toDouble().clamp(0.0, _duration.inSeconds.toDouble()),
                      onChanged: (value) {
                        _player.seek(Duration(seconds: value.toInt()));
                      },
                    ),
                    ),
                  ),
                  Text(_formatTime(_duration),
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface)),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Кнопки управления
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  iconSize: 36,
                  color: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.skip_previous),
                  onPressed: _prev,
                ),

                const SizedBox(width: 24),

                IconButton(
                  iconSize: 64,
                  color: Theme.of(context).colorScheme.primary,
                  icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow),
                  onPressed: () async {
                    if (_isPlaying) {
                      await _player.pause();
                      setState(() => _isPlaying = false);
                    } else {
                      await _player.setSource(
                        AssetSource(_tracks[_currentIndex]),
                      );
                      await _player.resume();
                      setState(() => _isPlaying = true);
                    }
                  },
                ),

                const SizedBox(width: 24),

                IconButton(
                  iconSize: 36,
                  color: Theme.of(context).colorScheme.primary,
                  icon: const Icon(Icons.skip_next),
                  onPressed: _next,
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }
}