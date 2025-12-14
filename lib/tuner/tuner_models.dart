// lib/tuner_models.dart

/// ピッチ検出サンプル（周波数と取得時刻）を表すクラス。
/// リアルタイムチューナーや録音中のピッチ取得に使用。
class PitchSample {
  /// 検出された基本周波数（Hz）。
  final double frequencyHz;

  /// このサンプルが取得された時刻。
  final DateTime timestamp;

  const PitchSample({required this.frequencyHz, required this.timestamp});

  /// 周波数が0より大きい場合に「有効」とみなす簡易チェック。
  bool get hasValidFrequency => frequencyHz > 0;
}

/// ユーザーが合わせたい目標の音を表すクラス。
/// [label] は「G4」「A3」などの表示用ラベル。
/// [semitoneOffsetFromA4] は A4（基準ピッチ）からの半音数の差。
///  例：A4 → 0、G4 → -2、B4 → +2、A3 → -12 など。
class TargetNote {
  final String label;
  final int semitoneOffsetFromA4;

  const TargetNote({required this.label, required this.semitoneOffsetFromA4});
}

/// 5秒間のピッチチェック結果を保持するクラス。
/// スコア、安定度、平均誤差（cents）、
/// および時間経過ごとの誤差（centsTimeline）を含む。
class TunerResult {
  /// 目標音への近さを表す総合スコア（0〜100）。
  final double score;

  /// 許容範囲内（±しきい値）のピッチであった割合（0〜100%）。
  final double stabilityPercent;

  /// 平均絶対誤差（平均 |Δcents|）。
  final double avgAbsCents;

  /// 時間経過ごとのcents誤差（検出値 − 目標値）。
  /// グラフ表示用。順序は入力サンプルと対応させる想定。
  final List<double> centsTimeline;

  const TunerResult({
    required this.score,
    required this.stabilityPercent,
    required this.avgAbsCents,
    required this.centsTimeline,
  });

  /// 初回表示などで使う空の結果を返すファクトリコンストラクタ。
  factory TunerResult.empty() => const TunerResult(
    score: 0,
    stabilityPercent: 0,
    avgAbsCents: 0,
    centsTimeline: <double>[],
  );

  /// スコア値にもとづき「Excellent / Good / Fair / Needs Work」
  /// といった評価ラベルを返すヘルパー。
  String get ratingLabel {
    if (score >= 90) return 'Excellent';
    if (score >= 75) return 'Good';
    if (score >= 60) return 'Fair';
    return 'Needs Work';
  }
}
