import 'dart:math';
import 'package:audioplayers/audioplayers.dart';

class MusicManager {
  static final MusicManager _instance = MusicManager._internal();
  factory MusicManager() => _instance;
  MusicManager._internal();

  final AudioPlayer _player = AudioPlayer();

  final List<String> _playlist = [
    'deimos.mp3',
    'dinosaur.mp3',
    'rare.mp3',
    'you_are_truth.mp3'
  ];

  Future<void> playRandomMusic() async {
    final random = Random();
    final String randomSong = _playlist[random.nextInt(_playlist.length)];

    try {
      await _player.play(AssetSource('music/$randomSong'));
      _player.onPlayerComplete.first.then((_) => playRandomMusic());
    } catch (e) {
      print("Error playing music: $e");
    }
  }

  void stop() => _player.stop();
  void pause() => _player.pause();
  void resume() => _player.resume();
  void setVolume(double volume) => _player.setVolume(volume);
}