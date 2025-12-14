// lib/tuner_analyzer.dart

import 'dart:math' as math;

import 'tuner_models.dart';

/// 周波数 [freqHz] が目標周波数 [targetHz] と比べて
/// 何 cents（セント）ずれているかを計算する。
/// 0 より大きければ「高い（シャープ）」、0 より小さければ「低い（フラット）」。
/// freqHz または targetHz が 0 以下の場合は 0 を返す。
double hzToCentsError(double freqHz, double targetHz) {
  if (freqHz <= 0 || targetHz <= 0) return 0;
  return 1200.0 * (math.log(freqHz / targetHz) / math.ln2);
}

/// 指定したターゲット音 [note] と基準ピッチ [baseA4Hz]
/// から目標周波数（Hz）を算出する。
/// baseA4Hz は通常 440, 441, 442 などの値を想定。
double targetFrequencyHz(TargetNote note, double baseA4Hz) {
  return baseA4Hz * math.pow(2.0, note.semitoneOffsetFromA4 / 12.0);
}

/// 5秒間のピッチサンプル [samples] を解析し、
/// 目標音 [target] と比較した結果（TunerResult）を返す。
///
/// ・平均絶対誤差（平均|Δcents|）
/// ・スコア（0〜100）
/// ・安定度（±閾値内の割合）
/// ・時間経過ごとのcents誤差
/// をまとめて計算する。
///
/// [stabilityThresholdCents] は「±何cents以内なら安定とみなすか」、
/// [maxErrorForZeroScoreCents] は「このcents誤差でスコア0扱いとするか」を指定する。
TunerResult analyzePitchSequence({
  required List<PitchSample> samples,
  required TargetNote target,
  required double baseA4Hz,
  double stabilityThresholdCents = 10.0,
  double maxErrorForZeroScoreCents = 60.0,
}) {
  if (samples.isEmpty) {
    return TunerResult.empty();
  }

  final targetHz = targetFrequencyHz(target, baseA4Hz);

  final centsTimeline = <double>[];
  double sumAbsCents = 0;
  int validCount = 0;
  int stableCount = 0;

  for (final s in samples) {
    if (!s.hasValidFrequency) {
      // 今のところ無効サンプルは統計には含めない。
      continue;
    }

    final centsError = hzToCentsError(s.frequencyHz, targetHz);
    centsTimeline.add(centsError);

    final absErr = centsError.abs();
    sumAbsCents += absErr;
    validCount++;

    if (absErr <= stabilityThresholdCents) {
      stableCount++;
    }
  }

  if (validCount == 0) {
    return TunerResult.empty();
  }

  final avgAbsCents = sumAbsCents / validCount;

  // 平均誤差を0〜100スコアにマッピング。
  // avgAbsCents = 0   -> 100点
  // avgAbsCents = max -> 0点
  final normalized = (1.0 - (avgAbsCents / maxErrorForZeroScoreCents)).clamp(
    0.0,
    1.0,
  );
  final score = normalized * 100.0;

  // 安定度：有効サンプルのうち、許容範囲内に収まっていた割合。
  final stabilityPercent = (stableCount / validCount) * 100.0;

  return TunerResult(
    score: score,
    stabilityPercent: stabilityPercent,
    avgAbsCents: avgAbsCents,
    centsTimeline: centsTimeline,
  );
}

/// 周波数（Hz）から最も近いノート番号(整数)を返す
/// A4=440Hz を 69 とする（MIDI規格に準拠）
int hzToNoteNumber(double hz) {
  return (69 + 12 * math.log(hz / 440.0) / math.ln2).round();
}

String noteNumberToLabel(int n) {
  const names = [
    'C',
    'C#',
    'D',
    'D#',
    'E',
    'F',
    'F#',
    'G',
    'G#',
    'A',
    'A#',
    'B',
  ];

  final name = names[n % 12];
  final octave = (n ~/ 12) - 1; // MIDI規格のオクターブ
  return '$name$octave';
}

/// 周波数[hz]とノート番号[noteNumber]との差をcentsで返す。
double centsErrorForNoteNumber(double hz, int noteNumber) {
  if (hz <= 0) return 0.0;
  final idealHz = 440.0 * math.pow(2.0, (noteNumber - 69) / 12.0); // A4=69
  // ここで既存の hzToCentsError(実周波数, 目標周波数) を再利用
  return hzToCentsError(hz, idealHz);
}
