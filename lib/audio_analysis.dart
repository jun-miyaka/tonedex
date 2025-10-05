// audio_analysis.dart - compute() 用の isolate 対応バージョン（FFT含む）
import 'dart:math';
import 'dart:io';
import 'package:flutter/foundation.dart'; // compute() のために必要

double _rmsLinear(List<double> x) {
  double s2 = 0.0;
  for (final v in x) {
    s2 += v * v;
  }
  return sqrt(s2 / (x.isEmpty ? 1 : x.length));
}

double _dbfsFromRms(double rmsLinear, {double ref = 32768.0}) {
  if (rmsLinear <= 1e-12) return -120.0;
  return 20.0 * (log(rmsLinear / ref) / ln10);
}

// ▼▼ 追加：RMS影響除去のユーティリティ ▼▼
List<double> levelNormalizeForSpectrum(
  List<double> x, {
  double targetDbFS = -20.0,
  double ref = 32768.0,
  double maxGainDb = 24.0,
}) {
  final rms = _rmsLinear(x);
  if (rms <= 1e-12) return x; // 無音は何もしない
  final curDb = _dbfsFromRms(rms, ref: ref);
  final gainDb = targetDbFS - curDb;
  final clamped = gainDb.clamp(-maxGainDb, maxGainDb);
  final g = pow(10.0, clamped / 20.0) as double;
  return x.map((v) => v * g).toList(growable: false);
}

/// |X[k]| を受け取り、パワー→総和=1 の分布 p[k] に変換
List<double> toProbSpecFromMagnitudes(List<double> magnitudes) {
  final List<double> pwr = List<double>.generate(magnitudes.length, (i) {
    final m = magnitudes[i];
    return m * m; // パワー
  }, growable: false);
  final sum = pwr.fold<double>(0.0, (a, b) => a + b);
  if (sum <= 0) return List<double>.filled(pwr.length, 0.0);
  return List<double>.generate(
    pwr.length,
    (i) => pwr[i] / sum,
    growable: false,
  );
}

// ===== BEGIN PATCH: calculateBrightnessFromSamples (power-of-2 padding) =====

// まだ無ければヘルパー関数も一緒に追加（既に定義済みなら重複しないように）
bool _isPowerOf2(int n) => n > 0 && (n & (n - 1)) == 0;
int _nextPowerOf2(int n) {
  int p = 1;
  while (p < n) {
    p <<= 1;
  }
  return p;
}

/// decimation後の波形から Brightness を計算（FFT長は2の冪に強制）
double calculateBrightnessFromDecimated(
  List<double> decimated,
  int sampleRate,
) {
  if (decimated.isEmpty || sampleRate <= 0) return 0.0;

  // 1) 長さを2の冪に（超過分は切り詰め）
  int fftSize = decimated.length;
  // _floorPowerOf2 の代わりにローカルで計算
  int floorPow2 = 1;
  while ((floorPow2 << 1) <= fftSize) {
    floorPow2 <<= 1;
  }
  if (floorPow2 != fftSize) {
    if (floorPow2 <= 0) return 0.0;
    decimated = List<double>.from(decimated.getRange(0, floorPow2));
    fftSize = floorPow2;
  }

  // 2) FFT → |X[k]|（片側）
  final spectrum = fft(decimated);
  final List<double> mags = List<double>.generate(
    fftSize ~/ 2,
    (i) => spectrum[i].abs(),
    growable: false,
  );

  // 3) p[k] 正規化は calculateBrightnessIndex(...) 内で実施
  return calculateBrightnessIndex(mags, sampleRate);
}
// === END ===

double _binFreq(int k, int sampleRate, int fftSize) =>
    (sampleRate.toDouble() * k) / fftSize;

double centroidFromProbSpec(List<double> p, int sampleRate, int fftSize) {
  double c = 0.0;
  for (int k = 0; k < p.length; k++) {
    c += _binFreq(k, sampleRate, fftSize) * p[k];
  }
  return c;
}

double bandwidthFromProbSpec(
  List<double> p,
  int sampleRate,
  int fftSize, {
  double? centroidHz,
}) {
  final c = centroidHz ?? centroidFromProbSpec(p, sampleRate, fftSize);
  double s = 0.0;
  for (int k = 0; k < p.length; k++) {
    final f = _binFreq(k, sampleRate, fftSize);
    final d = f - c;
    s += (d * d) * p[k];
  }
  return sqrt(s);
}

double brightnessFromProbSpec(
  List<double> p,
  int sampleRate,
  int fftSize, {
  double cutoffHz = 4000.0,
}) {
  double hi = 0.0;
  for (int k = 0; k < p.length; k++) {
    final f = _binFreq(k, sampleRate, fftSize);
    if (f >= cutoffHz) hi += p[k];
  }
  return hi; // 0–1
}
// ▲▲ 追加ここまで ▲▲

// 波形 samples → 正規化 → 2の冪にゼロパディング → FFT → |X[k]| → Brightness
double calculateBrightnessFromSamples(List<double> samples, int sampleRate) {
  // 1) レベル正規化（RMS影響除去の前処理）
  final norm = levelNormalizeForSpectrum(samples, targetDbFS: -20.0);

  // 2) FFT入力長を 2の冪に揃える（足りない分は0パディング）
  final int fftSize = _isPowerOf2(norm.length)
      ? norm.length
      : _nextPowerOf2(norm.length);
  final List<double> buf = (fftSize == norm.length)
      ? norm
      : (() {
          final out = List<double>.filled(fftSize, 0.0);
          out.setRange(0, norm.length, norm);
          return out;
        })();

  // 3) FFT → 片側 |X[k]| を作る
  final spectrum = fft(buf);
  final List<double> mags = List<double>.generate(
    fftSize ~/ 2,
    (i) => spectrum[i].abs(),
    growable: false,
  );

  // 4) ✅ 無限再帰はダメ。Brightnessは magnitudes から計算する
  return calculateBrightnessIndex(mags, sampleRate);
}

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
//従後（RMS非依存の定義へ）
double calculateSpectralCentroid(List<double> samples, int sampleRate) {
  if (samples.isEmpty || sampleRate <= 0) return 0.0;
  try {
    // ① レベル正規化（極端なレベル差の影響を抑える）
    final norm = levelNormalizeForSpectrum(samples, targetDbFS: -20.0);

    // ② FFT → |X[k]| → p[k]
    final n = norm.length;
    final spectrum = fft(norm);
    final magnitudes = List<double>.generate(
      n ~/ 2,
      (i) => spectrum[i].abs(),
      growable: false,
    );
    final p = toProbSpecFromMagnitudes(magnitudes);

    // ③ p[k] で重み付け（RMSから実質独立）
    final c = centroidFromProbSpec(p, sampleRate, n);
    return double.parse(c.toStringAsFixed(3));
  } catch (e) {
    print('❌ Centroid 計算中にエラー: $e');
    return 0.0;
  }
}

// スペクトル帯域幅（Bandwidth）計算
//従後（RMS非依存の定義へ）
double calculateSpectralBandwidth(List<double> samples, int sampleRate) {
  if (samples.isEmpty || sampleRate <= 0) return 0.0;
  try {
    // ① レベル正規化
    final norm = levelNormalizeForSpectrum(samples, targetDbFS: -20.0);

    // ② FFT → |X[k]| → p[k]
    final n = norm.length;
    final spectrum = fft(norm);
    final magnitudes = List<double>.generate(
      n ~/ 2,
      (i) => spectrum[i].abs(),
      growable: false,
    );
    final p = toProbSpecFromMagnitudes(magnitudes);

    // ③ p[k] で帯域幅
    final c = centroidFromProbSpec(p, sampleRate, n);
    final b = bandwidthFromProbSpec(p, sampleRate, n, centroidHz: c);
    return double.parse(b.toStringAsFixed(3));
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
    () => calculateBrightnessFromDecimated(
      decimated,
      44100,
    ), // ← “decimation 完了: 32768 samples” の配列
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
// 従後（RMS非依存：パワー正規化 p[k] を使用）
double calculateBrightnessIndex(List<double> magnitudes, int sampleRate) {
  // magnitudes は |X[k]| を想定（長さ = fftSize/2）
  final int fftSize = magnitudes.length * 2;
  final double binFreq = sampleRate.toDouble() / fftSize;

  // |X[k]| → パワー → 総和=1 の分布 p[k]
  final List<double> p = toProbSpecFromMagnitudes(magnitudes);

  double hi = 0.0;
  for (int i = 0; i < p.length; i++) {
    final double freq = binFreq * i;
    if (freq >= 4000.0) {
      hi += p[i];
    }
  }

  // --- デバッグ用（必要なときだけ） ---
  final int fftSizeDerived = p.length * 2; // pは半分長なのでここから復元
  final int cutoffIndex = ((4000.0 * fftSizeDerived) / sampleRate).floor();
  final double sumP = p.fold<double>(0.0, (a, b) => a + b);

  // 同じpを使ってCentroidを再計算（Centroid側と一致するか検証）
  final double centroidFromSameP = centroidFromProbSpec(
    p,
    sampleRate,
    fftSizeDerived,
  );

  return hi; // 0–1
}
