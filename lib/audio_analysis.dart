// audio_analysis.dart - compute() 用の isolate 対応バージョン（FFT含む）
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart'; // compute() のために必要

// 複素数クラス定義（FFTで使用）
class Complex {
  final double re;
  final double im;
  const Complex(this.re, this.im);

  double abs() => sqrt(re * re + im * im);
  double get modulus => abs();

  Complex operator +(Complex other) => Complex(re + other.re, im + other.im);
  Complex operator -(Complex other) => Complex(re - other.re, im - other.im);
  Complex operator *(Complex other) =>
      Complex(re * other.re - im * other.im, re * other.im + im * other.re);
}

// 高速フーリエ変換（再帰的）
List<Complex> fft(List<double> input) {
  final n = input.length;
  if (n == 0) return [];
  if (n & (n - 1) != 0) {
    throw ArgumentError("Input length must be a power of 2");
  }

  List<Complex> x = List.generate(n, (i) => Complex(input[i], 0));

  void fft(List<Complex> a) {
    final n = a.length;
    if (n <= 1) return;

    final even = List.generate(n ~/ 2, (i) => a[i * 2]);
    final odd = List.generate(n ~/ 2, (i) => a[i * 2 + 1]);

    fft(even);
    fft(odd);

    for (int k = 0; k < n ~/ 2; k++) {
      final t = Complex(cos(-2 * pi * k / n), sin(-2 * pi * k / n)) * odd[k];
      a[k] = even[k] + t;
      a[k + n ~/ 2] = even[k] - t;
    }
  }

  fft(x);
  return x;
}

// スペクトル重心（Centroid）計算
double calculateSpectralCentroid(List<double> samples, int sampleRate) {
  if (samples.isEmpty || sampleRate <= 0) return 0.0;

  try {
    final n = samples.length;
    final spectrum = fft(samples);
    final freqs = List.generate(n ~/ 2, (i) => i * sampleRate / n);

    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i < freqs.length; i++) {
      final mag = spectrum[i].abs();
      numerator += freqs[i] * mag;
      denominator += mag;
    }

    if (denominator == 0.0) return 0.0;
    return double.parse((numerator / denominator).toStringAsFixed(3));
  } catch (e) {
    print('❌ Centroid 計算中にエラー: $e');
    return 0.0;
  }
}

// スペクトル帯域幅（Bandwidth）計算
double calculateSpectralBandwidth(List<double> samples, int sampleRate) {
  if (samples.isEmpty || sampleRate <= 0) return 0.0;

  try {
    final n = samples.length;
    final spectrum = fft(samples);
    final freqs = List.generate(n ~/ 2, (i) => i * sampleRate / n);
    final centroid = calculateSpectralCentroid(samples, sampleRate);

    double sum = 0.0;
    double weight = 0.0;

    for (int i = 0; i < freqs.length; i++) {
      final mag = spectrum[i].abs();
      final diff = freqs[i] - centroid;
      sum += diff * diff * mag;
      weight += mag;
    }

    print('📊 Bandwidth 中間値: sum=$sum, weight=$weight');

    if (weight == 0.0) return 0.0;
    return double.parse((sqrt(sum / weight)).toStringAsFixed(3));
  } catch (e) {
    print('❌ Bandwidth 計算中にエラー: $e');
    return 0.0;
  }
}

// メイン分析関数：ファイルパスからWAVを読み込み、別スレッドで分析
Future<List<double>> analyzeAudio(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    print('❌ WAVファイルが存在しません: $path');
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  try {
    final bytes = await file.readAsBytes();
    return await analyzeAudioIsolate(bytes);
  } catch (e) {
    print('❌ WAVファイルの読み込みエラー: $e');
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }
}

// compute() を使って分析処理を isolate に移す
Future<List<double>> analyzeAudioIsolate(Uint8List bytes) async {
  return await compute(_analyzeInIsolate, bytes);
}

// analyzeAudioIsolate に渡される分析処理の本体（同期関数）
List<double> _analyzeInIsolate(Uint8List bytes) {
  print('✅ isolate 開始');
  final audioData = bytes.sublist(44);
  final samples = bytesToDoubles(audioData);
  print('✅ bytesToDoubles 完了: ${samples.length} samples');

  final trimmed = _trimSilence(samples, threshold: 200, minLength: 2000);
  print('🔍 サンプル数（トリム後）: ${trimmed.length}');

  if (trimmed.length < 100) {
    print('⚠️ 有効な音声データがほとんどありません');
    return [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  final List<double> decimated = List<double>.generate(
    trimmed.length ~/ 4,
    (i) => trimmed[i * 4],
  );

  int nearestPowerOf2(int x) {
    int p = 1;
    while (p * 2 <= x) {
      p *= 2;
    }
    return p;
  }

  final int fftLen = nearestPowerOf2(decimated.length);
  final List<double> padded = decimated.sublist(0, fftLen);
  print('✅ decimation 完了: ${padded.length} samples');

  double safe(Function f, String label) {
    try {
      print('🔄 $label 計算中');
      final value = f();
      print('✅ $label: $value');
      if (value.isNaN || value.isInfinite) {
        print('❌ $label は無効 (NaNまたはInfinity)');
        return 0.0;
      }
      return value;
    } catch (e) {
      print('❌ $label エラー: $e');
      return 0.0;
    }
  }

  final rms = safe(() => calculateRMS(padded), 'RMS');
  final zcr = safe(() => calculateZCR(padded, 44100), 'ZCR');
  final spectrum = fft(padded);
  final magnitudes = spectrum.map((c) => c.modulus).toList();
  final centroid = safe(
    () => calculateSpectralCentroid(padded, 44100),
    'Centroid',
  );
  final bandwidth = safe(
    () => calculateSpectralBandwidth(padded, 44100),
    'Bandwidth',
  );
  final brightness = safe(
    () => calculateBrightnessIndex(magnitudes, 44100),
    'Brightness',
  );

  print('✅ 全指標計算完了');
  return [rms, zcr, centroid, bandwidth, brightness];
}

// 無音区間をトリミングする関数
List<double> _trimSilence(
  List<double> samples, {
  double threshold = 200,
  int minLength = 2000,
}) {
  int start = samples.indexWhere((s) => s.abs() > threshold);
  int end = samples.lastIndexWhere((s) => s.abs() > threshold);
  if (start == -1 || end == -1 || (end - start) < minLength) {
    return samples;
  }
  return samples.sublist(start, end + 1);
}

// Uint8List を PCM サンプル（double）に変換
List<double> bytesToDoubles(Uint8List bytes) {
  final buffer = ByteData.sublistView(bytes);
  final samples = <double>[];
  for (int i = 0; i < buffer.lengthInBytes; i += 2) {
    samples.add(buffer.getInt16(i, Endian.little).toDouble());
  }
  return samples;
}

// RMS 計算
double calculateRMS(List<double> samples) {
  if (samples.isEmpty) return 0.0;
  final sum = samples.map((x) => x * x).reduce((a, b) => a + b);
  return double.parse((sqrt(sum / samples.length)).toStringAsFixed(3));
}

// ZCR 計算
double calculateZCR(List<double> samples, int sampleRate) {
  if (samples.length < 2) return 0.0;
  int zeroCrossings = 0;
  for (int i = 1; i < samples.length; i++) {
    if ((samples[i - 1] >= 0 && samples[i] < 0) ||
        (samples[i - 1] < 0 && samples[i] >= 0)) {
      zeroCrossings++;
    }
  }
  return double.parse(
    (zeroCrossings / (samples.length / sampleRate)).toStringAsFixed(3),
  );
}

// brightness（明るさ指標）計算
double calculateBrightnessIndex(List<double> magnitudes, int sampleRate) {
  final int fftSize = magnitudes.length * 2;
  final double binFreq = sampleRate / fftSize;

  double energyTotal = 0.0;
  double energyHigh = 0.0;

  for (int i = 0; i < magnitudes.length; i++) {
    final freq = binFreq * i;
    final mag = magnitudes[i];
    energyTotal += mag;
    if (freq > 2000) {
      energyHigh += mag;
    }
  }

  return energyHigh / (energyTotal + 1e-6);
}
