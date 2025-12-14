// lib/pitch_source.dart
import 'dart:async';

import 'package:audio_streamer/audio_streamer.dart';
import 'package:pitch_detector_dart/pitch_detector.dart';

/// マイク入力からリアルタイムにピッチ(Hz)を流すクラス。
/// audio_streamer で List<double> のPCM(正規化)を取り、それを YIN に渡す。
class PitchSource {
  final _controller = StreamController<double>.broadcast();
  Stream<double> get stream => _controller.stream;

  StreamSubscription<List<double>>? _audioSub;
  late final PitchDetector _detector;

  PitchSource() {
    _detector = PitchDetector(audioSampleRate: 44100, bufferSize: 4096);
  }

  Future<void> start() async {
    // すでに動いていたら二重起動しない
    if (_audioSub != null) return;

    // サンプルレート指定（必ず listen 前に設定）
    AudioStreamer().sampleRate = 44100;

    // audio_streamer のストリームを購読
    _audioSub = AudioStreamer().audioStream.listen(
      (List<double> buffer) async {
        // buffer は -1.0〜+1.0 の正規化PCM。doubleのままYINに渡せる。
        if (buffer.isEmpty) return;

        // pitch_detector_dart の getPitch は List<double> を受け取る
        final result = await _detector.getPitchFromFloatBuffer(buffer);

        if (result.pitched &&
            result.pitch > 20.0 &&
            result.pitch < 2000.0 &&
            !result.pitch.isNaN &&
            result.pitch.isFinite) {
          _controller.add(result.pitch);
        }
      },
      onError: (error) {
        // 必要ならログなど
        // print('audio_streamer error: $error');
      },
      cancelOnError: false,
    );
  }

  void stop() {
    _audioSub?.cancel();
    _audioSub = null;
  }

  void dispose() {
    stop();
    _controller.close();
  }
}
