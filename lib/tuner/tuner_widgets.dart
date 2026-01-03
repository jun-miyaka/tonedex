// lib/tuner_widgets.dart
// ①②③のパネルをまとめたUI骨組み（ロジックはダミー多め）

import 'package:flutter/material.dart';
import 'dart:async';
import 'tuner_models.dart';
import 'tuner_analyzer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;
import 'pitch_source.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart'; // すでに使っていれば追加不要
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import '../l10n/app_localizations.dart';
import '../audio/mic_session_manager.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/scheduler.dart';

// ★ 追加：アプリ全体で使い回す共有の PitchSource
final PitchSource sharedPitchSource = PitchSource();

// ★ 追加：ToneDexチューナー全体のキャリブレーション（単位：cents）
const double _kTunerCalibrationOffsetCents = -8.0;

// ★追加：リアルタイム／PitchChecker で共有する A4 基準周波数
final ValueNotifier<double> sharedBaseA4Hz = ValueNotifier<double>(440.0);

int hzToNoteNumberWithBaseA4(double hz, double baseA4Hz) {
  // MIDI note: A4 = 69
  final n = 69 + 12 * (math.log(hz / baseA4Hz) / math.ln2);
  return n.round();
}

double centsErrorForNoteNumberWithBaseA4(
  double hz,
  int noteNum,
  double baseA4Hz,
) {
  final targetHz = baseA4Hz * math.pow(2.0, (noteNum - 69) / 12.0);
  return 1200.0 * (math.log(hz / targetHz) / math.ln2);
}

/// リアルタイムチューナー表示用パネル。
class RealTimeTunerPanel extends StatefulWidget {
  const RealTimeTunerPanel({super.key, required this.isActive});

  final bool isActive;

  @override
  State<RealTimeTunerPanel> createState() => _RealTimeTunerPanelState();
}

class _RealTimeTunerPanelState extends State<RealTimeTunerPanel>
    with WidgetsBindingObserver {
  double _currentCents = 0.0;
  double _currentFreqHz = 440.0;
  String _currentNoteLabel = 'A4';
  StreamSubscription<double>? _pitchStreamSub;

  // なめらか表示用の内部状態
  double _smoothedCents = 0.0;
  double _smoothedFreqHz = 440.0;
  bool _hasSmoothedValue = false;

  static const double _maxDisplayCents = 30.0; // 表示レンジ ±30c

  bool _hasRequestedPermission = false;
  bool _isEnsuring = false; // 多重キックのガード（最小）
  bool _stopping = false;

  Future<void> _stopMic({String? reason}) async {
    if (_stopping) return;
    _stopping = true;
    try {
      sharedPitchSource.stop();
    } finally {
      _stopping = false;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initPitchListening();

    // init時点で既にアクティブなら、フレーム後に開始キック
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ensureRunning(reason: 'init-active');
      });
    }
  }

  @override
  void didUpdateWidget(covariant RealTimeTunerPanel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isActive && !widget.isActive) {
      _stopMic(reason: 'tab-inactive');
      return;
    }

    if (!oldWidget.isActive && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ensureRunning(reason: 'tab-active');
      });
    }
  }

  // ★重要：deactivate で stop しない（タブ切替/言語切替等で止めると今回の問題が再発し得る）
  // @override
  // void deactivate() {
  //   sharedPitchSource.stop();
  //   super.deactivate();
  // }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // ★resumeで、Tunerがアクティブなら必ず開始キック
    if (state == AppLifecycleState.resumed && widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ensureRunning(reason: 'resumed');
      });
    }

    // ★方針：inactive/paused で stop しない
  }

  /// ★Tunerタブ表示/復帰で「開始キック」するための関数
  /// - ここで tuner の mic所有権を acquire → endOfFrame → start の順で保証
  Future<void> ensureRunning({String reason = ''}) async {
    if (!mounted) return;
    if (!widget.isActive) return;
    if (_isEnsuring) return;
    _isEnsuring = true;

    try {
      // 0) tuner に mic 所有権を寄せる（main側の順序に依存しない）
      await MicSessionManager.instance.acquire(MicSessionOwner.tuner);

      // 1) マイク権限
      if (!_hasRequestedPermission) {
        _hasRequestedPermission = true;
        final st = await Permission.microphone.request();
        if (!st.isGranted) return;
      } else {
        final st = await Permission.microphone.status;
        if (!st.isGranted) return;
      }

      // 2) 描画完了待ち（start空振り対策 & debugNeedsPaint系の回避）
      await SchedulerBinding.instance.endOfFrame;

      // 3) start を再キック
      await sharedPitchSource.start();
    } finally {
      _isEnsuring = false;
    }
  }

  /// マイク権限を取得してからピッチ検出を開始する（購読セットアップ中心）
  Future<void> _initPitchListening() async {
    // マイク権限リクエスト（初回だけ）
    if (!_hasRequestedPermission) {
      final status = await Permission.microphone.request();
      _hasRequestedPermission = true;
      if (!mounted) return;
      if (!status.isGranted) {
        return;
      }
    }

    // ★ MicSessionManager に「tuner の stop 処理」を登録（stopしない方針）
    void _stopMic({required String reason}) {
      debugPrint('[TUNER] stopMic reason=$reason');
      if (_stopping) return;
      _stopping = true;
      try {
        sharedPitchSource.stop();
        MicSessionManager.instance.release(MicSessionOwner.tuner);
      } finally {
        _stopping = false;
      }
    }

    // 共有の PitchSource からピッチ値を受け取る（多重listen防止）
    _pitchStreamSub ??= sharedPitchSource.stream.listen((hz) {
      final baseA4 = sharedBaseA4Hz.value;

      final noteNum = hzToNoteNumberWithBaseA4(hz, baseA4);

      // ① 生の誤差（baseA4Hz対応）
      final rawCents = centsErrorForNoteNumberWithBaseA4(hz, noteNum, baseA4);

      // ② キャリブレーションを適用した誤差
      final cents = rawCents + _kTunerCalibrationOffsetCents;

      final label = noteNumberToLabel(noteNum);

      // ---- スムージング処理 ----
      const alpha = 0.1; // 値が小さいほどなめらか

      if (!_hasSmoothedValue) {
        // 最初の1回だけはそのまま採用
        _smoothedCents = cents;
        _smoothedFreqHz = hz;
        _hasSmoothedValue = true;
      } else {
        // 前回値から少しずつ追いつく（指数移動平均）
        _smoothedCents = _smoothedCents + alpha * (cents - _smoothedCents);
        _smoothedFreqHz = _smoothedFreqHz + alpha * (hz - _smoothedFreqHz);
      }
      // ---- スムージングここまで ----

      if (!mounted) return;
      setState(() {
        _currentFreqHz = _smoothedFreqHz;
        _currentNoteLabel = label;
        _currentCents = _smoothedCents;
      });
    });

    // ★ここで start しても空振りすることがあるので、
    //   「タブ表示/復帰」で確実にキックする ensureRunning に寄せる
    if (widget.isActive) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ensureRunning(reason: 'initPitchListening-active');
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _pitchStreamSub?.cancel();
    _pitchStreamSub = null;

    // ★方針：disposeでも stop しない
    // sharedPitchSource.stop();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // -_maxDisplayCents〜+_maxDisplayCents を -1.0〜+1.0 に正規化（バー位置用）
    final normalized = (_currentCents / _maxDisplayCents).clamp(-1.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context)!.tuner_realtime_tuner,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // 中央に大きく現在の音名
          Center(
            child: Text(
              _currentNoteLabel,
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 4),

          // 周波数と誤差
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${_currentFreqHz.toStringAsFixed(1)} Hz',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(width: 16),
              Text(
                '${_currentCents.toStringAsFixed(1)} cents',
                style: const TextStyle(fontSize: 14),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // 中央0・左右±30c の水平バー
          SizedBox(
            height: 56,
            child: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      // ベースライン
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade400,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      // ±5c の「OKゾーン」ハイライト
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 60,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      // 0 cents の中央マーカー
                      Align(
                        alignment: Alignment.center,
                        child: Container(
                          width: 2,
                          height: 28,
                          color: Colors.redAccent,
                        ),
                      ),
                      // 現在値のインジケータ（青）
                      Align(
                        alignment: Alignment(normalized, 0),
                        child: Container(
                          width: 10,
                          height: 30,
                          decoration: BoxDecoration(
                            color: Colors.blueAccent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                // 目盛りラベル（-30, -20, -10, 0, +10, +20, +30）
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: const [
                    Text('-30', style: TextStyle(fontSize: 10)),
                    Text('-20', style: TextStyle(fontSize: 10)),
                    Text('-10', style: TextStyle(fontSize: 10)),
                    Text('0', style: TextStyle(fontSize: 10)),
                    Text('+10', style: TextStyle(fontSize: 10)),
                    Text('+20', style: TextStyle(fontSize: 10)),
                    Text('+30', style: TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 4),
          Text(
            AppLocalizations.of(context)!.tuner_pitch_axis_hint,
            style: const TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }
}

// 解析結果を親に渡すためのコールバック。
typedef TunerResultCallback = void Function(TunerResult result);

/// 5秒間のピッチチェック（ターゲット音に対する正確さ＋安定度）を行うパネル。
class PitchCheckControlPanel extends StatefulWidget {
  /// 測定結果を親ウィジェットに渡したい場合のコールバック。
  /// result は dynamic としておき、呼び出し側で自由に扱えるようにする。
  final void Function(dynamic result)? onResult;

  const PitchCheckControlPanel({super.key, this.onResult});

  @override
  State<PitchCheckControlPanel> createState() => _PitchCheckControlPanelState();
}

class _PitchCheckControlPanelState extends State<PitchCheckControlPanel> {
  final GlobalKey _chartKey = GlobalKey();

  // ターゲット音名（オクターブなし表示用）
  final List<String> _availableNoteLabels = [
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

  String _selectedNoteLabel = 'A';

  // A4 基準周波数（440〜443Hzまで選択可能）
  double _baseA4Hz = 440.0;

  bool _isCountingDown = false;
  bool _isMeasuring = false;
  int _countdownSeconds = 3;

  int _measureDurationSeconds = 5; // ← getter ではなく、普通の変数にする // 計測時間（秒）: 初期値 5秒
  int? _lastMeasuredSeconds;

  StreamSubscription<double>? _pitchSub;
  Timer? _countdownTimer;
  Timer? _measureTimer;

  // 測定結果
  List<double> _centsSamples = [];
  int _sampleCount = 0;
  double? _avgAbsErrorCents;
  double? _stabilityPercent;
  int? _score;

  // --- Action comment（結果表示の後に出す） ---
  bool _showActionComment = false;
  String? _actionCommentText;
  int _lastActionCommentIndex = -1;

  String _pickActionComment(AppLocalizations l10n) {
    final comments = <String>[
      l10n.tunerActionComment1,
      l10n.tunerActionComment2,
      l10n.tunerActionComment3,
      l10n.tunerActionComment4,
    ];

    int idx = math.Random().nextInt(comments.length);
    if (comments.length >= 2 && idx == _lastActionCommentIndex) {
      idx = (idx + 1) % comments.length;
    }
    _lastActionCommentIndex = idx;
    return comments[idx];
  }

  // ★ 追加：オクターブ自動判定用の状態
  int? _targetPitchClass; // 0〜11（C〜B）
  int? _autoTargetNoteNumber; // 実際に使うMIDIノート番号（オクターブ込み）
  double? _targetHzForCheck; // そのMIDIノートに対応するHz

  /// 音名（C, C#, D, ...）からピッチクラス（0〜11）を返す。
  int _pitchClassFromLabel(String label) {
    switch (label) {
      case 'C':
        return 0;
      case 'C#':
        return 1;
      case 'D':
        return 2;
      case 'D#':
        return 3;
      case 'E':
        return 4;
      case 'F':
        return 5;
      case 'F#':
        return 6;
      case 'G':
        return 7;
      case 'G#':
        return 8;
      case 'A':
        return 9;
      case 'A#':
        return 10;
      case 'B':
        return 11;
      default:
        return 0;
    }
  }

  @override
  void initState() {
    super.initState();
    _restoreLastPitchCheck();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _measureTimer?.cancel();
    _pitchSub?.cancel();

    super.dispose();
  }

  /// 「5秒間のピッチチェック」ボタン押下時
  Future<void> _startPitchCheck() async {
    if (_isCountingDown || _isMeasuring) return;

    // ★ ここを追加
    //    debugPrint(
    //      'DEBUG: _startPitchCheck called, duration=$_measureDurationSeconds',
    //    );

    // 前回結果をクリア
    setState(() {
      _isCountingDown = true;
      _isMeasuring = false;
      _countdownSeconds = 3;

      _centsSamples = [];
      _sampleCount = 0;
      _avgAbsErrorCents = null;
      _stabilityPercent = null;
      _score = null;

      // ★ ここで保存！
      _lastMeasuredSeconds = _measureDurationSeconds;
    });

    // 念のためマイク権限確認（リアルタイム側で既に許可済みのはずだが保険）
    final status = await Permission.microphone.request();
    if (!mounted) return;

    if (!status.isGranted) {
      setState(() {
        _isCountingDown = false;
      });
      return;
    }

    // カウントダウン開始
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        _countdownSeconds--;
      });

      // ★ カウントダウンのログ
      //      debugPrint('DEBUG: countdown = $_countdownSeconds');

      if (_countdownSeconds <= 0) {
        timer.cancel();
        setState(() {
          _isCountingDown = false;
        });
        _beginMeasurement();
      }
    });
  }

  /// 実際の5秒間測定を開始（オクターブ自動判定版）
  Future<void> _beginMeasurement() async {
    if (_isMeasuring) return;

    setState(() {
      _isMeasuring = true;
    });

    // 共有の PitchSource を利用（既に起動済みなら内部で何もしない想定）
    await sharedPitchSource.start();

    // ユーザーが選んだ音名から「ピッチクラス」（0〜11：C〜B）を計算。
    // ユーザーが選んだ音名（C, D, E, ...）からピッチクラス（0〜11）を決定
    final pc = _pitchClassFromLabel(_selectedNoteLabel);
    _targetPitchClass = pc;
    _autoTargetNoteNumber = null;
    _targetHzForCheck = null;

    _centsSamples = [];
    _pitchSub?.cancel();
    _pitchSub = sharedPitchSource.stream.listen((hz) {
      if (hz <= 0) return;

      // ★ 入ってくるhzの様子を見る
      //      debugPrint('DEBUG: pitch stream hz=$hz');

      // ★ 最初の1回だけ、実際のピッチから「どのオクターブか」を決める
      if (_targetHzForCheck == null) {
        final detectedNoteNum = hzToNoteNumber(hz);
        final pc = _targetPitchClass!;
        int bestNote = detectedNoteNum;
        int bestDist = 999;

        // 検出ノートの前後 3オクターブぶんくらいを候補にして、
        // 同じピッチクラスかつ一番近いノート番号を採用
        for (int n = detectedNoteNum - 36; n <= detectedNoteNum + 36; n++) {
          if (n < 0) continue;
          if (n % 12 == pc) {
            final d = (n - detectedNoteNum).abs();
            if (d < bestDist) {
              bestDist = d;
              bestNote = n;
            }
          }
        }

        _autoTargetNoteNumber = bestNote;
        _targetHzForCheck = _noteNumberToHzWithBaseA4(bestNote, _baseA4Hz);
      }

      final targetHz = _targetHzForCheck!;
      final rawCents = hzToCentsError(hz, targetHz);

      // ★ キャリブレーションを適用
      final cents = rawCents + _kTunerCalibrationOffsetCents;

      // ★ 明らかなオクターブ飛びや外れ値は無視（必要に応じて閾値調整）
      if (cents.abs() > 300) {
        return;
      }

      _centsSamples.add(cents);
    });

    // 選択された秒数後に測定終了
    _measureTimer?.cancel();
    _measureTimer = Timer(
      Duration(seconds: _measureDurationSeconds),
      _finishMeasurement,
    );
  }

  /// 測定終了 → スコア計算
  // lib/tuner_widgets.dart 内
  // PitchCheckControlPanelState にある _finishMeasurement の修正版

  void _finishMeasurement() {
    //    debugPrint(
    //      'DEBUG: _finishMeasurement called, samples=${_centsSamples.length}',
    //    );
    _measureTimer?.cancel();
    _pitchSub?.cancel();
    _pitchSub = null;

    final samples = List<double>.from(_centsSamples);
    _centsSamples = [];

    int count = samples.length;
    double? avgAbs;
    double? stability;
    int? score;

    if (count > 0) {
      double sumAbs = 0.0;
      double sum = 0.0;
      for (final c in samples) {
        sumAbs += c.abs();
        sum += c;
      }
      avgAbs = sumAbs / count;
      final mean = sum / count;

      double variance = 0.0;
      for (final c in samples) {
        final d = c - mean;
        variance += d * d;
      }
      variance /= count;
      final stdDev = math.sqrt(variance);

      // --- 新スコア仕様 ---
      // 1) 平均誤差ベースの accuracyScore（0〜100）
      //    平均誤差 0c → 100点、約17c → 50点、約33c → 0点 のイメージ
      double accuracyScore = 100.0 - avgAbs * 3.0;
      if (accuracyScore < 0) accuracyScore = 0;
      if (accuracyScore > 100) accuracyScore = 100;

      // 2) 安定度（標準偏差ベース）の stabilityScore（0〜100）
      //    stdDev 0c → 100%、約8c → 50%、約17c → 0% のイメージ
      double stabilityScore = 100.0 - stdDev * 6.0;
      if (stabilityScore < 0) stabilityScore = 0;
      if (stabilityScore > 100) stabilityScore = 100;

      // 3) 最終スコア = accuracy 50% + stability 50%
      double finalScore = (accuracyScore * 0.5) + (stabilityScore * 0.5);

      score = finalScore.round();
      stability = stabilityScore;
    }

    if (!mounted) return;

    setState(() {
      _isMeasuring = false;
      _sampleCount = count;
      _avgAbsErrorCents = avgAbs;
      _stabilityPercent = stability;
      _score = score;
      _lastCentsTimeline = samples; // ★ ミニグラフ用に保存

      // ★ 追加：計測が終わったらアクションコメントを出す（結果が出たときだけ）
      final l10n = AppLocalizations.of(context)!;
      _actionCommentText = _pickActionComment(l10n);
      _showActionComment = true;
    });

    // ★ 最後の結果を保存（B案）
    _saveLastPitchCheck();

    // 親ウィジェットへの通知（必要なら使う）
    // ※ サンプルが取れていて、各値がnullでないときだけ通知する
    if (widget.onResult != null &&
        count > 0 &&
        score != null &&
        stability != null &&
        avgAbs != null) {
      widget.onResult!(
        TunerResult(
          score: score.toDouble(),
          stabilityPercent: stability, // double
          avgAbsCents: avgAbs, // double
          centsTimeline: samples, // List<double>
        ),
      );
    }
    if (count == 0) {
      final l10n = AppLocalizations.of(context)!;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.tuner_out_of_range_message),
          duration: const Duration(seconds: 3),
        ),
      );

      setState(() {
        _isMeasuring = false;
        _sampleCount = 0;
        _avgAbsErrorCents = null;
        _stabilityPercent = null;
        _score = null;
        _lastCentsTimeline = const [];
      });
      return;
    }
  }

  /// 計測結果をテキストとして共有
  Future<void> _sharePitchResult() async {
    // ★追加：ローカライズ文字列を取得
    final l10n = AppLocalizations.of(context)!;

    if (_score == null ||
        _avgAbsErrorCents == null ||
        _stabilityPercent == null) {
      // 計測がまだの場合は何もしない
      return;
    }

    // 1) テキスト部分を組み立て
    final buffer = StringBuffer();

    buffer.writeln('');
    buffer.writeln('${l10n.tuner_shared_target_note}: $_selectedNoteLabel');
    buffer.writeln(
      '${l10n.tuner_shared_base_a4}: ${_baseA4Hz.toStringAsFixed(1)} Hz',
    );
    buffer.writeln('');
    buffer.writeln('${l10n.tuner_score_label}: $_score / 100');
    buffer.writeln(
      '${l10n.tuner_shared_pitch_stability}: ${_stabilityPercent!.toStringAsFixed(1)} %',
    );
    buffer.writeln(
      '${l10n.tuner_shared_average_error}: ${_avgAbsErrorCents!.toStringAsFixed(1)} cents',
    );
    buffer.writeln('${l10n.tuner_shared_sample_count}: $_sampleCount');
    buffer.writeln('');
    buffer.writeln(l10n.tuner_shared_measured_with);

    final text = buffer.toString();

    // 2) グラフ部分を画像キャプチャ
    XFile? chartFile;
    try {
      final boundary =
          _chartKey.currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (boundary != null) {
        final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
        final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
        if (byteData != null) {
          final pngBytes = byteData.buffer.asUint8List();

          final dir = await getTemporaryDirectory();
          final file = File('${dir.path}/tuner_pitch_chart.png');
          await file.writeAsBytes(pngBytes);

          chartFile = XFile(
            file.path,
            mimeType: 'image/png',
            name: 'tuner_pitch_chart.png',
          );
        }
      }
    } catch (e) {
      // ここは失敗しても致命的ではないので、テキスト共有だけにフォールバック
      // debugPrint('chart capture error: $e');
    }

    // 3) テキスト＋画像共有（画像が取れなければテキストのみ）
    if (chartFile != null) {
      await Share.shareXFiles(
        [chartFile],
        text: text,
        subject: 'ToneDex Tuner result',
      );
    } else {
      await Share.share(text, subject: 'ToneDex Tuner result');
    }
  }

  /// "A4" などの音名文字列を単純に MIDIノート番号に変換
  /// 例: C4=60, A4=69
  int _noteLabelToMidi(String label) {
    final match = RegExp(r'^([A-G]#?)(-?\d+)$').firstMatch(label);
    if (match == null) {
      // 万一パースできなければ A4 にフォールバック
      return 69;
    }
    final name = match.group(1)!;
    final octave = int.tryParse(match.group(2)!) ?? 4;

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

    final index = names.indexOf(name);
    if (index < 0) {
      return 69;
    }

    // C-1 が 0 になるように計算
    return (octave + 1) * 12 + index;
  }

  /// MIDIノート番号＋基準A4Hzから、その音の理想周波数を求める
  double _noteNumberToHzWithBaseA4(int noteNumber, double baseA4Hz) {
    return baseA4Hz * math.pow(2.0, (noteNumber - 69) / 12.0);
  }

  // 直近の測定での cents 推移（ミニグラフ表示用）
  List<double> _lastCentsTimeline = [];

  // --- Last result persistence (B: restore only the latest) ---
  static const String _kPrefKeyLastPitchCheck = 'last_pitch_check_v1';

  Future<void> _restoreLastPitchCheck() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonStr = prefs.getString(_kPrefKeyLastPitchCheck);
    if (jsonStr == null || jsonStr.trim().isEmpty) return;

    try {
      final m = jsonDecode(jsonStr) as Map<String, dynamic>;

      final timeline = ((m['timeline'] as List?) ?? const [])
          .map((e) => (e as num).toDouble())
          .toList();

      if (!mounted) return;
      setState(() {
        _selectedNoteLabel = (m['note'] as String?) ?? _selectedNoteLabel;
        _baseA4Hz = ((m['baseA4'] as num?)?.toDouble()) ?? _baseA4Hz;
        _measureDurationSeconds =
            ((m['duration'] as num?)?.toInt()) ?? _measureDurationSeconds;
        _lastMeasuredSeconds = (m['lastMeasuredSeconds'] as num?)?.toInt();

        _sampleCount = (m['sampleCount'] as num?)?.toInt() ?? 0;
        _avgAbsErrorCents = (m['avgAbs'] as num?)?.toDouble();
        _stabilityPercent = (m['stability'] as num?)?.toDouble();
        _score = (m['score'] as num?)?.toInt();

        // ★ あなたのコードで使っている「ミニグラフ保存先」
        _lastCentsTimeline = timeline;

        // アクションコメントは「復元時は表示しない」がおすすめ（うるさくならない）
        _showActionComment = false;
        _actionCommentText = null;
      });
    } catch (_) {
      // 壊れてたら無視
    }
  }

  Future<void> _saveLastPitchCheck() async {
    // 結果が無いなら保存しない
    if (_score == null ||
        _avgAbsErrorCents == null ||
        _stabilityPercent == null) {
      return;
    }

    final prefs = await SharedPreferences.getInstance();

    final payload = <String, dynamic>{
      'note': _selectedNoteLabel,
      'baseA4': _baseA4Hz,
      'duration': _measureDurationSeconds,
      'lastMeasuredSeconds': _lastMeasuredSeconds,
      'sampleCount': _sampleCount,
      'avgAbs': _avgAbsErrorCents,
      'stability': _stabilityPercent,
      'score': _score,
      'timeline': _lastCentsTimeline, // List<double>
      'savedAt': DateTime.now().toIso8601String(),
    };

    await prefs.setString(_kPrefKeyLastPitchCheck, jsonEncode(payload));
  }

  @override
  Widget build(BuildContext context) {
    // ★ここで一度だけ取得
    final l10n = AppLocalizations.of(context)!;
    // グラフ用の秒数（最後の計測秒数があればそれ、なければ現在の設定）
    final secondsForGraph = _lastMeasuredSeconds ?? _measureDurationSeconds;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 見出し
          Text(
            l10n.tuner_pitch_checker,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // ターゲット音選択
          Row(
            children: [
              const Text('Target Note: '),
              const SizedBox(width: 8),
              DropdownButton<String>(
                value: _selectedNoteLabel,
                items: _availableNoteLabels
                    .map(
                      (label) => DropdownMenuItem(
                        value: label,
                        child: Text(
                          label,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: _isCountingDown || _isMeasuring
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _selectedNoteLabel = value;
                        });
                      },
              ),
            ],
          ),

          const SizedBox(height: 4),

          // A4 基準周波数選択（440〜443Hz）
          Row(
            children: [
              const Text('A4: '),
              const SizedBox(width: 8),
              DropdownButton<double>(
                value: _baseA4Hz,
                items: const [
                  DropdownMenuItem(value: 440.0, child: Text('440 Hz')),
                  DropdownMenuItem(value: 441.0, child: Text('441 Hz')),
                  DropdownMenuItem(value: 442.0, child: Text('442 Hz')),
                  DropdownMenuItem(value: 443.0, child: Text('443 Hz')),
                ],
                onChanged: _isCountingDown || _isMeasuring
                    ? null
                    : (value) {
                        if (value == null) return;
                        setState(() {
                          _baseA4Hz = value;
                          sharedBaseA4Hz.value = value; // ★追加：リアルタイムにも反映
                        });
                      },
              ),
            ],
          ),

          const SizedBox(height: 8),

          // 状態表示（カウントダウン／計測中）
          if (_isCountingDown)
            Text(
              '${l10n.tuner_start_countdown} $_countdownSeconds${l10n.tuner_seconds_suffix}',
              style: const TextStyle(color: Colors.orange, fontSize: 18),
            ),
          if (_isMeasuring)
            Text(
              l10n.tuner_measuring_now,
              style: const TextStyle(color: Colors.red, fontSize: 18),
            ),
          if (_isCountingDown || _isMeasuring) const SizedBox(height: 4),

          // 計測時間セレクタ（5秒 / 10秒）
          Align(
            alignment: Alignment.centerRight,
            child: ToggleButtons(
              isSelected: [
                _measureDurationSeconds == 5,
                _measureDurationSeconds == 10,
              ],
              onPressed: (_isCountingDown || _isMeasuring)
                  ? null
                  : (index) {
                      setState(() {
                        _measureDurationSeconds = (index == 0) ? 5 : 10;
                      });
                    },
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l10n.tuner_seconds_5),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(l10n.tuner_seconds_10),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // 計測ボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (_isCountingDown || _isMeasuring)
                  ? null
                  : _startPitchCheck,
              child: Text(
                _measureDurationSeconds == 5
                    ? l10n.tuner_measure_5sec
                    : l10n.tuner_measure_10sec,
                style: const TextStyle(fontSize: 16),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // 測定結果表示
          if (_score != null) ...[
            Text(
              'Score: ${_score!.toStringAsFixed(0)} / 100',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            if (_stabilityPercent != null)
              Text(
                '${l10n.tuner_pitch_stability}: '
                '${_stabilityPercent!.toStringAsFixed(1)} %',
                style: const TextStyle(fontSize: 14),
              ),
            Text(
              '${l10n.tuner_average_error}: '
              '${_avgAbsErrorCents!.toStringAsFixed(1)} cents',
              style: const TextStyle(fontSize: 14),
            ),
            Text(
              '${l10n.tuner_sample_count}: $_sampleCount',
              style: const TextStyle(fontSize: 12),
            ),

            const SizedBox(height: 12),

            // グラフ（cents推移）
            if (_lastCentsTimeline.isNotEmpty) ...[
              SizedBox(
                width: double.infinity,
                child: RepaintBoundary(
                  key: _chartKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          l10n.pitchGraphTitle(secondsForGraph),
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(
                        height: 120,
                        child: _CentsTimelineChart(cents: _lastCentsTimeline),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 8),

            // ★ 追加：分析後コメント（×で閉じる）
            if (_showActionComment && (_actionCommentText?.isNotEmpty ?? false))
              Card(
                elevation: 0,
                color: Colors.grey.shade100,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.grey.shade300),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.lightbulb_outline, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _actionCommentText!,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.close, size: 18),
                        tooltip: AppLocalizations.of(context)!.close,
                        onPressed: () {
                          setState(() => _showActionComment = false);
                        },
                      ),
                    ],
                  ),
                ),
              ),

            // 結果を共有ボタン
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _sharePitchResult,
                icon: const Icon(Icons.share),
                label: Text(l10n.tuner_share_result),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 計測結果（スコア・安定度・平均誤差・ミニグラフ）を表示するパネル。
class PitchCheckResultPanel extends StatelessWidget {
  final TunerResult? result;

  const PitchCheckResultPanel({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ★ これが必要！

    if (result == null) {
      return Text(l10n.tuner_no_result);
    }

    final r = result!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // タイトルもローカライズ
          Text(
            l10n.tuner_result_header,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text('Score: ${r.score.toStringAsFixed(1)} / 100 (${r.ratingLabel})'),
          Text(
            '${l10n.tuner_pitch_stability}: ${r.stabilityPercent.toStringAsFixed(1)} %',
          ),
          Text(
            '${l10n.tuner_average_error}: ${r.avgAbsCents.toStringAsFixed(1)} cents',
          ),

          const SizedBox(height: 16),
          // ★ここを Text にする
          Text(
            l10n.tuner_dummy_chart_label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),

          // ミニグラフは今後 fl_chart で実装予定。
          SizedBox(
            height: 120,
            width: double.infinity,
            child: _CentsTimelineChart(cents: r.centsTimeline),
          ),
        ],
      ),
    );
  }
}

/// 5秒間の cents 推移を表示する簡易ラインチャート。
class _CentsTimelineChart extends StatelessWidget {
  final List<double> cents;

  const _CentsTimelineChart({required this.cents});

  static const double _displayRange = 30.0; // 表示レンジ ±30c

  @override
  Widget build(BuildContext context) {
    if (cents.isEmpty) {
      return Container(
        color: Colors.white,
        alignment: Alignment.center,
        child: Text(
          AppLocalizations.of(context)!.tuner_no_sample,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      );
    }

    // X軸用の点（Y値は ±30c でクリップ）
    final spots = <FlSpot>[];
    for (var i = 0; i < cents.length; i++) {
      final clamped = cents[i].clamp(-_displayRange, _displayRange).toDouble();
      spots.add(FlSpot(i.toDouble(), clamped));
    }

    final maxX = (cents.length - 1).toDouble();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: LineChart(
        LineChartData(
          minX: 0,
          maxX: maxX,
          minY: -_displayRange,
          maxY: _displayRange,
          gridData: FlGridData(
            show: true,
            horizontalInterval: 10,
            verticalInterval: (maxX / 4).clamp(1, 20),
            getDrawingHorizontalLine: (v) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 1),
            getDrawingVerticalLine: (v) =>
                FlLine(color: Colors.grey.shade300, strokeWidth: 0.5),
          ),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                interval: 10,
                getTitlesWidget: (v, meta) {
                  return Text(
                    '${v.toInt()}',
                    style: const TextStyle(fontSize: 12),
                  );
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          borderData: FlBorderData(show: true),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 2.0,
              color: Colors.blueAccent,
              dotData: FlDotData(show: false),
            ),
          ],
          extraLinesData: ExtraLinesData(
            horizontalLines: [
              HorizontalLine(y: 0, strokeWidth: 1, color: Colors.redAccent),
            ],
          ),
        ),
      ),
    );
  }
}

/// 5秒間の cents 推移を簡易折れ線で表示するミニグラフ。
/// 中身は fl_chart を使った `_CentsTimelineChart` に委譲する。
class CentsTimelineMiniGraph extends StatelessWidget {
  final List<double> centsTimeline;

  const CentsTimelineMiniGraph({super.key, required this.centsTimeline});

  @override
  Widget build(BuildContext context) {
    if (centsTimeline.isEmpty) {
      return const SizedBox.shrink();
    }

    return _CentsTimelineChart(cents: centsTimeline);
  }
}
