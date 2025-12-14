import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'audio_analysis.dart';
import 'graph_widget.dart';
import 'package:flutter/rendering.dart'; // ← これを追加
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart'; // ✅ 共有全体に必要
// ✅ XFile に必要
import 'package:sax_app/help_page.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sax_app/l10n/app_localizations.dart';
// ← これを使う
import 'package:sound_palette/sound_palette.dart'; // ← pubspec の path 依存で使えるように
import 'tuner/tuner_page.dart';
import 'audio/mic_session_manager.dart';

// ▼ Calibrated/Z-score 表示モード
enum DisplayMode { raw, zscore }

// ▼ 解析が 44.1kHz 前提なら固定。将来、実サンプルレートを持っている場合は置換してください。
const int _kFs = 44100;
const double _kNyq = _kFs / 2.0; // = 22050.0
const double _kRmsRef = 20000.0; // とりあえず 2e4。様子を見て18k〜22kで微調整

// ▼ 画面状態にモードを追加（既定は Calibrated）
DisplayMode _mode = DisplayMode.raw;

// ▼ Calibrated用の値変換（表示専用。元データ results[][] はそのまま Raw）
/* // [HIDDEN] calibrated mapping (kept for future reference)
double _toCalibrated(String metric, double raw) {
  switch (metric) {
    case 'Centroid':
    case 'Bandwidth':
      return (raw / _kNyq).clamp(0.0, 1.0);
    case 'Brightness': // = 0–1 想定
    case 'Symmetry': // 互換のため（UIではBrightness表記でもOK）
      return raw.clamp(0.0, 1.0); // ← ここは割らない
    case 'RMS': // 0–1（線形）
      return (raw / _kRmsRef).clamp(0.0, 1.0);
    case 'ZCR': // すでに cross/s
    default:
      return raw;
  }
}
*/

// ===== BEGIN PATCH: Auto-scale helpers (P5–P95) =====

double _quantileOfSorted(List<double> sorted, double q) {
  if (sorted.isEmpty) return 0.0;
  final n = sorted.length;
  final pos = (q.clamp(0.0, 1.0) * (n - 1));
  final i = pos.floor();
  final f = pos - i;
  if (i + 1 >= n) return sorted.last;
  return sorted[i] * (1 - f) + sorted[i + 1] * f;
}

/// 直近window本の分布（P5–P95）で 0..1 に線形スケーリング（表示専用）
/// - values: 過去→最新の順の配列（BrightnessのRaw）
/// - window: 使う本数の上限（例: 50）
/// - 返り値: 変換後の 0..1 配列（長さはvaluesと同じ）
List<double> _autoScaleP5P95(
  List<double> values, {
  int window = 50,
  double eps = 1e-6,
}) {
  if (values.isEmpty) return const [];
  final take = values.length < window ? values.length : window;
  final recent = values.sublist(values.length - take);
  final sorted = [...recent]..sort();
  final p5 = _quantileOfSorted(sorted, 0.05);
  final p95 = _quantileOfSorted(sorted, 0.95);
  final denom = (p95 - p5).abs();
  return values
      .map((x) {
        if (denom < eps) return 0.0;
        final z = (x - p5) / denom;
        return z.clamp(0.0, 1.0);
      })
      .toList(growable: false);
}

// ===== END PATCH =====

// ▼ Zスコア（1列分の値配列 → Z配列）
List<double> _zScoresOf(List<double> values) {
  if (values.isEmpty) return const [];
  final mean = values.reduce((a, b) => a + b) / values.length;
  final varSum = values.fold(0.0, (s, v) => s + (v - mean) * (v - mean));
  final std = (varSum / values.length).sqrtSafe();
  return values.map((v) => std > 0 ? (v - mean) / std : 0.0).toList();
}

extension DoubleXSqrt on double {
  double sqrtSafe() => (isFinite && this >= 0) ? math.sqrt(this) : 0.0;
}

void main() {
  runApp(const MyApp());
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  final GlobalKey _graphKey = GlobalKey(); // Stateの中で宣言
  final List<GlobalKey> _chartKeys = List.generate(5, (_) => GlobalKey());
  bool _isReady = false;
  bool _listReady = false; // 初回ロード完了フラグ
  bool _busy = false; // 操作直列化ロック
  int _loadGen = 0; // リスト更新の世代ID（競合回避）
  // ▼ カウントダウン関連の状態
  bool _showCountdown = false;
  String _countdownText = '';

  // ← クラスの中、build()より上
  String _modeLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (_mode) {
      case DisplayMode.raw:
        return l10n.displayModeRaw;
      case DisplayMode.zscore:
        return l10n.displayModeZscore;
    }
  }

  // _RecorderPageState 内（build()より上）
  Widget _buildModeBadge(BuildContext context) {
    final modeLabel = _modeLabel(context);
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.black26,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          'Mode: $modeLabel', // 「Mode: 」もARB化したければ l10n.modePrefix を作成
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ),
    );
  }

  // metrics名（results の列と対応）
  static const List<String> _kMetrics = [
    'RMS',
    'ZCR',
    'Centroid',
    'Bandwidth',
    'Brightness',
  ];

  void _openToneMapper(BuildContext context) {
    // 録音中を止めたいならここで（任意）
    // _stopIfRecording();

    Navigator.of(context).pop(); // Drawerを閉じる
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const SoundPalettePage()));
  }

  // Zスコア（既に _zScoresOf があるならそれを使ってOK。無ければこれを置く）
  List<double> _zScoresOf(List<double> values) {
    if (values.isEmpty) return const [];
    final mean = values.reduce((a, b) => a + b) / values.length;
    double varSum = 0.0;
    for (final x in values) {
      final d = x - mean;
      varSum += d * d;
    }
    final std = varSum / values.length;
    final denom = std > 0 ? math.sqrt(std) : 0.0;
    return [for (final x in values) denom > 0 ? (x - mean) / denom : 0.0];
  }

  // モードに応じた「描画用の値」（5本 × labels.length）を作る
  List<List<double>> _buildChartSeriesFor(DisplayMode mode) {
    final n = labels.length;
    final series = List.generate(5, (_) => <double>[]);

    if (mode == DisplayMode.zscore) {
      // 各列の Raw 値から Z を作成
      for (int m = 0; m < 5; m++) {
        final col = <double>[];
        for (int i = 0; i < n; i++) {
          final raw = (results.length > i && results[i].length >= 5)
              ? results[i][m]
              : 0.0;
          col.add(raw);
        }
        series[m] = _zScoresOf(col);
      }
    } else {
      // Raw
      for (int m = 0; m < 5; m++) {
        for (int i = 0; i < n; i++) {
          final raw = (results.length > i && results[i].length >= 5)
              ? results[i][m]
              : 0.0;
          series[m].add(raw);
        }
      }
      // ★ ここで Brightness 列（index=4）だけ 0..1 にオートスケール（表示専用）
      const kBrightnessIndex = 4;
      if (series[kBrightnessIndex].isNotEmpty) {
        series[kBrightnessIndex] = _autoScaleP5P95(
          series[kBrightnessIndex],
          window: 50,
        );
      }
    }
    return series;
  }

  double _niceCeil(double v) {
    if (!(v.isFinite) || v <= 0) return 1.0;
    final log10 = math.log(v) / math.ln10;
    final pow10 = math.pow(10.0, log10.floorToDouble()).toDouble();
    final n = v / pow10; // [1,10)
    double step;
    if (n <= 1.0) {
      step = 1.0;
    } else if (n <= 2.0)
      step = 2.0;
    else if (n <= 5.0)
      step = 5.0;
    else
      step = 10.0;
    return step * pow10;
  }

  // モード別のY軸レンジ（5本ぶん）
  List<double> _minYsFor(DisplayMode mode, List<List<double>> s) {
    if (mode == DisplayMode.zscore) return List.filled(5, -2.0);

    // Raw：絶対値なので0起点で固定（崩れ防止）
    return const [0.0, 0.0, 0.0, 0.0, 0.0];
  }

  List<double> _maxYsFor(DisplayMode mode, List<List<double>> s) {
    if (mode == DisplayMode.zscore) return List.filled(5, 2.0);

    // Raw：列ごとの最大値→5%ヘッドルーム→1/2/5×10^k に丸め
    return List.generate(5, (m) {
      if (m == 4) return 1.0; // ★ Brightness（Raw）は 1.0 固定
      final v = s[m];
      if (v.isEmpty) return 1.0;
      final mx = v.reduce(math.max);
      final up = _niceCeil(mx * 1.05);
      return (up <= 0.0) ? 1.0 : up;
    });
  }

  // 🔽 ネイティブ録音連携用チャンネルとオーディオプレイヤー
  static const MethodChannel _channel = MethodChannel(
    'native_recorder',
  ); // ✅ ここに1回だけ

  final AudioPlayer _player = AudioPlayer();
  String? _selectedRecording;
  final Map<String, Map<String, double>> _analysisResults = {};
  String? _currentFilePath;

  // --- Lock helper（ここに追加） ---
  Future<T?> _withLock<T>(Future<T> Function() task) async {
    if (_busy) return null; // 二重押し無視
    setState(() => _busy = true);
    try {
      return await task();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void initState() {
    super.initState();

    // ★追加：recorder の stop 方法を MicSessionManager に登録
    MicSessionManager.instance.registerOwner(
      MicSessionOwner.recorder,
      () async {
        // 録音中なら止める（録音してないなら何もしない）
        if (isRecording) {
          await _stopRecording();
        }
      },
    );

    // 🔽 初回描画が終わってから UI を使える状態にし、裏で一覧ロード
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessageIfFirstLaunch();
      if (mounted) {
        setState(() {
          _isReady = true;
        }); // まずUIを使える状態に
      }
      _loadRecordings(); // ← awaitしない。裏で実行（_listReady がtrueになるまでボタンは無効）
      // もし unawaited を使うなら:
      // unawaited(_loadRecordings()); // 要: import 'dart:async';
    });
  }

  String _formatRecordLines(int index, {DisplayMode? override}) {
    if (index < 0 || index >= results.length || results[index].length < 5) {
      return AppLocalizations.of(context)!.notAnalyzedOrIncomplete;
    }
    final mode = override ?? _mode;
    final v = results[index];
    const metrics = ['RMS', 'ZCR', 'Centroid', 'Bandwidth', 'Brightness'];

    // ▼ Z-scoreは「Raw列」から直接作る（_toCalibratedは使わない）
    double z(int col) {
      final colVals = <double>[];
      for (final row in results) {
        if (row.length >= 5) {
          colVals.add(row[col]); // Rawをそのまま
        }
      }
      final zs = _zScoresOf(colVals);
      return (index < zs.length) ? zs[index] : 0.0;
    }

    String fmt(String name, int col) {
      if (mode == DisplayMode.zscore) {
        final zv = z(col);
        return '$name: ${zv.toStringAsFixed(2)}';
      } else {
        // Raw 表示（ZCRだけ単位つきで見やすく）
        if (name == 'ZCR') {
          return '$name: ${v[col].round()} cross/s';
        }
        return '$name: ${v[col].toStringAsFixed(3)}';
      }
    }

    return [
      for (var i = 0; i < metrics.length; i++) fmt(metrics[i], i),
    ].join('\n');
  }

  // 共有テキストを3種（Raw / Calibrated / Z-score）で出力し、共有シートを開く
  Future<void> _shareAllAnalysisResultsMulti(GlobalKey boundaryKey) async {
    final dir = await getApplicationDocumentsDirectory();
    final String ts = DateTime.now()
        .toIso8601String()
        .replaceAll(':', '')
        .substring(0, 15);

    String buildSection(DisplayMode m) {
      // ← Calibrated を参照しない2択に変更
      final label = (m == DisplayMode.raw) ? 'Raw' : 'Z-score';

      final body = List.generate(fileNames.length, (i) {
        final name = labels[i];
        final ok = results.length > i && results[i].length == 5;
        final lines = ok
            ? _formatRecordLines(i, /* 現在の描画モードではなく */ override: m)
            : AppLocalizations.of(context)!.notAnalyzedOrIncomplete;
        return '$name\n$lines';
      }).join('\n\n');

      return '[$label]\n$body';
    }

    final textRaw = buildSection(DisplayMode.raw);
    final textZ = buildSection(DisplayMode.zscore);

    // 1) テキストを書き出す（Calibrated抜き）
    final textFile = File('${dir.path}/analysis_results_$ts.txt');
    await textFile.writeAsString([textRaw, textZ].join('\n\n'));

    // 2) チャート画像をキャプチャ（あれば）
    final xfiles = <XFile>[XFile(textFile.path)];
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final chartFile = File('${dir.path}/chart_$ts.png');
      await chartFile.writeAsBytes(pngBytes);
      xfiles.add(XFile(chartFile.path));
    }

    // 個別5枚（GraphWidget内で perChartKeys が RepaintBoundary を持っている前提）
    const names = ['rms', 'zcr', 'centroid', 'bandwidth', 'brightness'];
    await Future.delayed(const Duration(milliseconds: 50)); // レイアウト安定待ち

    for (int i = 0; i < _chartKeys.length; i++) {
      final b =
          _chartKeys[i].currentContext?.findRenderObject()
              as RenderRepaintBoundary?;
      if (b == null) continue;
      final img = await b.toImage(pixelRatio: 3.0);
      final bd = await img.toByteData(format: ui.ImageByteFormat.png);
      if (bd == null) continue;
      final png = bd.buffer.asUint8List();
      final f = File('${dir.path}/chart_${names[i]}_$ts.png');
      await f.writeAsBytes(png);
      xfiles.add(XFile(f.path));
    }

    // 3) 共有シートを開く（share_plus）
    await Share.shareXFiles(
      xfiles,
      text: 'ToneDex analysis (Raw / Calibrated / Z-score) — $ts',
      subject: 'ToneDex analysis $ts',
    );
  }

  Future<void> _shareAllAnalysisResults(GlobalKey boundaryKey) async {
    final dir = await getApplicationDocumentsDirectory();

    // テキストファイルの生成
    final textFile = File('${dir.path}/analysis_results.txt');
    final textContent = List.generate(fileNames.length, (i) {
      final name = labels[i];
      final result = results.length > i && results[i].length == 5
          ? _formatRecordLines(i) // ← フォーマッタ呼び出しに置換
          : '未分析または不完全';
      return '$name\n$result';
    }).join('\n\n');
    await textFile.writeAsString(textContent);

    // グラフ画像のキャプチャ
    final boundary =
        boundaryKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary != null) {
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();
      final chartFile = File('${dir.path}/chart.png');
      await chartFile.writeAsBytes(pngBytes);

      // 共有処理（画像＋テキスト）
      await Share.shareXFiles([
        XFile(textFile.path),
        XFile(chartFile.path),
      ], text: 'ToneDex Analysis Results + Chart');
    } else {
      // fallback（テキストのみ）
      await Share.shareXFiles([
        XFile(textFile.path),
      ], text: 'ToneDex Analysis Results');
    }
  }

  // 🔽 録音ファイルの一覧（追加）
  List<File> _recordings = [];

  Future<void> _loadRecordings() async {
    final myGen = ++_loadGen; // ← このロードの世代ID

    // 既存の保存先を使う。/recordings があればそちらを優先（なければ従来どおり直下）
    final docDir = await getApplicationDocumentsDirectory();
    final recDir = Directory('${docDir.path}/recordings');
    final targetDir = await recDir.exists() ? recDir : docDir;

    // wav/aac のみ列挙（同期ではなく非同期API）
    final files = await targetDir
        .list(followLinks: false)
        .where(
          (e) =>
              e is File && (e.path.endsWith('.wav') || e.path.endsWith('.aac')),
        )
        .cast<File>()
        .toList();

    files.sort((a, b) => a.path.compareTo(b.path));

    if (!mounted) return;
    if (myGen != _loadGen) return; // ← 遅れて来た古い結果は捨てる

    setState(() {
      _recordings = files;
      _listReady = true; // ← 初回ロード完了！
    });
  }

  Future<void> _showWelcomeMessageIfFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch && mounted) {
      // 英語テキストをl10nから取得（AppLocalizations）
      final welcomeText = AppLocalizations.of(context)!.welcomeMessage;

      // 少し遅延してからポップアップ表示（UIができてから）
      Future.delayed(const Duration(milliseconds: 500), () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('ToneDex'),
            content: Text(welcomeText),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });

      // 2回目以降は表示しないよう保存
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  // 🔽 録音ファイル名と分析結果（5指標のリスト）
  List<String> fileNames = [];
  List<String> labels = []; // 表示用のラベル（初期はファイル名と同じ）
  List<List<double>> results = [];

  bool isRecording = false;

  // 🔽 マイクパーミッション確認
  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      throw PlatformException(
        code: 'PERMISSION_DENIED',
        message: 'Microphone permission not granted',
      );
    }
  }

  // 🔽 カウントダウン表示＋録音開始（3→2→1→Start!）
  Future<void> _showCountdownAndRecord() async {
    if (_busy || isRecording) return;
    setState(() {
      _showCountdown = true;
      _countdownText = '';
    });

    // 数字のリスト（必要なら秒数を変更可能）
    const countdownSequence = ['3', '2', '1', 'Start!'];

    for (final text in countdownSequence) {
      if (!mounted) return;
      setState(() => _countdownText = text);
      await Future.delayed(const Duration(seconds: 1));
    }

    // カウントダウン終了で非表示に
    setState(() => _showCountdown = false);

    // 録音開始
    await _startRecordingCore();
  }

  String _generateFileName() {
    final now = DateTime.now();
    final formatted =
        '${now.year}${_pad2(now.month)}${_pad2(now.day)}_${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}';
    return 'recordings/$formatted.wav';
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  // 元の録音処理を_core関数として分離
  Future<void> _startRecordingCore() async {
    try {
      await _checkPermissions();

      // ★追加：録音がマイクを使う前に、他のオーナー（tuner）を止める
      await MicSessionManager.instance.acquire(MicSessionOwner.recorder);

      final dir = await getApplicationDocumentsDirectory();
      final recDir = Directory('${dir.path}/recordings');
      if (!await recDir.exists()) {
        await recDir.create(recursive: true);
      }

      final relPath = _generateFileName(); // 例: recordings/20251001_123456.wav
      final filePath = '${dir.path}/$relPath';

      _currentFilePath = filePath;
      await _channel.invokeMethod('startRecording', {'path': filePath});

      setState(() => isRecording = true);

      // 自動停止
      Future.delayed(const Duration(seconds: 5), () async {
        if (!mounted || !isRecording) return;
        await _stopRecording();
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('録音に失敗しました: $e')));
    }
  }

  // 🔽 録音停止処理（録音フラグを下ろす）
  Future<void> _stopRecording() async {
    try {
      // ★ ネイティブから保存済みのファイルパスを受け取る（.wav）
      final String? savedPath = await _channel.invokeMethod<String>(
        'stopRecording',
      );

      setState(() => isRecording = false);

      // ★追加：録音が止まったのでマイク所有権を解放
      MicSessionManager.instance.release(MicSessionOwner.recorder);

      // ★ 返ってきたパスを優先（_currentFilePath はフォールバック）
      final path = savedPath ?? _currentFilePath;

      if (path != null && File(path).existsSync()) {
        setState(() {
          fileNames.add(path); // 録音終了時に追加

          // ラベルも初期登録（例：20250718_220101）
          final label = path.split('/').last.replaceAll('.wav', '');
          labels.add(label);
        });

        // ヘッダ書き込みのタイミングを安全側に（数十msでOK）
        await Future.delayed(const Duration(milliseconds: 30));

        // 一覧・グラフを再読込
        await _loadRecordings();
      }
    } on PlatformException catch (e) {
      debugPrint('❌ 録音停止失敗: $e');
    }
  }

  // 🔽 再生処理
  Future<void> _play(String path) async {
    await _player.stop();
    await _player.play(DeviceFileSource(path));
  }

  // 🔽 削除処理
  void _delete(String filePath) async {
    final index = fileNames.indexOf(filePath);
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
    setState(() {
      fileNames.removeAt(index);
      labels.removeAt(index);
      results.removeAt(index); // ✅ グラフデータも連動して削除
    });
  }

  void _showRenameDialog(int index) {
    final controller = TextEditingController(text: labels[index]);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          AppLocalizations.of(context)!.editLabel,
        ), // ← localized from "ラベル名を編集 (最大12文字)",
        content: TextField(
          controller: controller,
          maxLength: 12,
          decoration: InputDecoration(hintText: '新しいラベル名'),
        ),
        actions: [
          TextButton(
            child: Text(
              AppLocalizations.of(context)!.cancel,
            ), // ← localized from "キャンセル",
            onPressed: () => Navigator.pop(context),
          ),
          TextButton(
            child: Text('OK'),
            onPressed: () {
              setState(() {
                labels[index] = controller.text;
              });
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  // 🔽 エラーチェック付きの分析処理（分析前に空ファイルや削除済みを回避）
  Future<void> _analyzeRecording(String path) async {
    try {
      final file = File(path);

      if (!await file.exists()) return;

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return;

      setState(() {
        _selectedRecording = null;
      });

      // ファイルパスを使って analyzeAudio を呼び出す
      final results = await analyzeAudio(path);

      setState(() {
        _selectedRecording = path;
        _analysisResults[path] = {
          "RMS": results[0],
          "ZCR": results[1],
          "Centroid": results[2],
          "Bandwidth": results[3],
          "Symmetry": results[4],
        };
      });
    } catch (e) {
      print("分析エラー: $e");
    }
  }

  // 🔽 分析処理（analyzeAudio を実行し、results に追加）
  Future<void> _analyze(String path) async {
    if (!File(path).existsSync()) return;
    final analysis = await analyzeAudio(path);
    final index = fileNames.indexOf(path);
    setState(() {
      if (index < results.length) {
        results[index] = analysis;
      } else {
        results.add(analysis);
      }
    });
  }

  // 🔽 Zスコア計算関数（1指標分）
  List<double> _calculateZScores(List<double> values) {
    final mean = values.reduce((a, b) => a + b) / values.length;
    // 分散 = 平方偏差の平均（pow を使わず掛け算に）
    final variance =
        values
            .map((x) {
              final d = x - mean;
              return d * d;
            })
            .reduce((a, b) => a + b) /
        values.length;

    // 標準偏差
    final std = variance > 0 ? math.sqrt(variance) : 0.0;
    if (std == 0) return List.filled(values.length, 0.0);
    return values.map((x) => (x - mean) / std).toList();
  }

  // 🔽 グラフ描画（5指標すべてをZスコア化して可視化）
  Widget _buildGraph(GlobalKey boundaryKey) {
    // 表示されているファイル分だけ分析（安全性の担保）
    final visibleCount = fileNames.length;
    if (results.length < visibleCount || visibleCount < 2) {
      return Text(AppLocalizations.of(context)!.notEnoughData);
    }

    // 🔽 結果行列（List<List<double>>）を転置して列ごとにZスコア化
    final transposed = List.generate(
      results[0].length,
      (i) => results.map((r) => r[i]).toList(),
    );
    final zScoreList = transposed
        .map((values) => _calculateZScores(values))
        .toList();

    // 🔽 結果行列をモードに応じた描画値へ変換＋Yレンジを用意
    final plotValues = _buildChartSeriesFor(_mode); // 5本 × labels.length
    final minYs = _minYsFor(_mode, plotValues);
    final maxYs = _maxYsFor(_mode, plotValues);

    // ▼ ここからモードに依存する“表示フラグ”は毎回生成（finalにしない）
    final showNumberLabels = List<bool>.generate(5, (i) {
      if (_mode == DisplayMode.zscore) return true; // Z-score: 全表示
      return i == 4; // Raw: Brightnessのみ数値ラベル
    });

    final zeroOneOnly = List<bool>.generate(5, (i) {
      if (_mode == DisplayMode.zscore) return false; // Z-score: 通常目盛
      return i == 4; // Raw: Brightnessのみ 0/1 目盛
    });

    // ✅ グラフ全体をキャプチャ可能にする RepaintBoundary で囲む
    return RepaintBoundary(
      key: boundaryKey,
      child: GraphWidget(
        zScores: plotValues,
        labels: labels,
        titles: [
          AppLocalizations.of(context)!.rmsLabel,
          AppLocalizations.of(context)!.zcrLabel,
          AppLocalizations.of(context)!.centroidLabel,
          AppLocalizations.of(context)!.bandwidthLabel,
          AppLocalizations.of(context)!.brightnessLabel,
        ],
        explanations: [
          AppLocalizations.of(context)!.rmsExplanation,
          AppLocalizations.of(context)!.zcrExplanation,
          AppLocalizations.of(context)!.centroidExplanation,
          AppLocalizations.of(context)!.bandwidthExplanation,
          AppLocalizations.of(context)!.brightnessExplanation,
        ],
        // ★ 追加：各グラフ用のキーを渡す
        perChartKeys: _chartKeys,
        minYs: minYs, // ← 追加
        maxYs: maxYs, // ← 追加
        // ★ 追加（新規）
        showLeftAxisLabels: showNumberLabels,
        zeroOneOnly: zeroOneOnly,
      ),
    );
  }

  // 🔽 メインUI構築（録音・再生・分析・削除 + グラフ表示）
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!; // ✅ ← ここに置く
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          // 置換後（標語を復活）
          children: [
            const Text('ToneDex', style: TextStyle(fontSize: 20)),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.visualizeYourTone, // ARBの標語キー
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<DisplayMode>(
            initialValue: _mode,
            onSelected: (m) => setState(() => _mode = m),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: DisplayMode.raw,
                child: Text(l10n.displayModeRaw),
              ),
              PopupMenuItem(
                value: DisplayMode.zscore,
                child: Text(l10n.displayModeZscore),
              ),
            ],
            icon: const Icon(Icons.tune),
            tooltip: 'Display mode',
          ),
        ],
      ),

      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 録音ボタン
                ElevatedButton(
                  onPressed: isRecording ? null : _showCountdownAndRecord,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isRecording ? Colors.red : null,
                  ),
                  child: Text(
                    isRecording
                        ? AppLocalizations.of(context)!.recording
                        : AppLocalizations.of(context)!.startRecording,
                  ),
                ),

                const SizedBox(height: 8),

                // 共有ボタン（フル幅）＋その直下にMODEバッジ
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!_listReady || _busy)
                        ? null
                        : () => _withLock(
                            () => _shareAllAnalysisResultsMulti(_graphKey),
                          ),
                    child: Text(AppLocalizations.of(context)!.shareResults),
                  ),
                ),
                const SizedBox(height: 6),
                _buildModeBadge(context), // ← context引数は不要

                const SizedBox(height: 16),

                // 録音ファイル一覧
                ...List<Widget>.generate(fileNames.length, (index) {
                  final name = fileNames[index].split('/').last;
                  return Card(
                    child: ListTile(
                      title: Text(labels[index]),
                      subtitle:
                          results.length > index && results[index].length == 5
                          ? Text(_formatRecordLines(index))
                          : Text(
                              AppLocalizations.of(
                                context,
                              )!.notAnalyzedOrIncomplete,
                            ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.play_arrow),
                            onPressed: (!_listReady || _busy)
                                ? null
                                : () =>
                                      _withLock(() => _play(fileNames[index])),
                          ),
                          IconButton(
                            icon: const Icon(Icons.analytics),
                            onPressed: (!_listReady || _busy)
                                ? null
                                : () => _withLock(
                                    () => _analyze(fileNames[index]),
                                  ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: (!_listReady || _busy)
                                ? null
                                : () => _withLock(() async {
                                    _showRenameDialog(index);
                                  }),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: (!_listReady || _busy)
                                ? null
                                : () => _withLock(() async {
                                    _delete(fileNames[index]);
                                    await _loadRecordings(); // リスト更新
                                  }),
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 16),

                _buildGraph(_graphKey),
              ],
            ),
          ),

          // 🔽 カウントダウンオーバーレイ
          if (_showCountdown)
            Container(
              color: Colors.white.withOpacity(0.2), // 背景を少し白く
              child: Center(
                child: Text(
                  _countdownText,
                  style: const TextStyle(
                    fontSize: 60,
                    color: Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),

      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),

            ListTile(
              leading: Icon(Icons.help_outline),
              title: Text(
                AppLocalizations.of(context)!.help,
              ), // ← localized from "Help",
              onTap: () {
                Navigator.of(context).pop(); // drawerを閉じる
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (context) => const HelpPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // ★追加：念のため recorder のマイク所有権を解放
    MicSessionManager.instance.release(MicSessionOwner.recorder);

    // ★推奨：AudioPlayer の破棄（リーク予防）
    _player.dispose();

    super.dispose();
  }
}

// ===================== ここから追加 =====================

class MainTabScaffold extends StatefulWidget {
  const MainTabScaffold({super.key});

  @override
  State<MainTabScaffold> createState() => _MainTabScaffoldState();
}

class _MainTabScaffoldState extends State<MainTabScaffold> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0:
        return const RecorderPage(); // ToneDex
      case 1:
        return const TunerPage(); // ← 本物のチューナー画面
      case 2:
        return const SoundPalettePage(); // Mapper
      default:
        return const RecorderPage();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _buildPage(_currentIndex),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() => _currentIndex = index);
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.graphic_eq),
            label: 'ToneDex',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.tune), label: 'Tuner'),
          BottomNavigationBarItem(
            icon: Icon(Icons.color_lens_outlined),
            label: 'Mapper',
          ),
        ],
      ),
    );
  }
}

// ===================== ここまで追加 =====================

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToneDex',
      //locale: const Locale('en'), // ★ 一時的に日本語を強制する
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
        Locale('ja'),
        Locale('zh'), // 簡体字（中国本土）
        Locale.fromSubtags(
          languageCode: 'zh',
          scriptCode: 'Hant',
        ), // 繁体字（台湾・香港など）
      ],
      // locale: Locale('ja'), // ← 強制日本語化したいときはコメント解除

      // ★ ここを追加：ロケール解決のカスタムロジック
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return supportedLocales.first;

        // 中国語だけ特別扱い
        if (locale.languageCode == 'zh') {
          // 繁体にしたいケース：script=Hant or 国コードが TW/HK/MO
          final isTraditional =
              locale.scriptCode == 'Hant' ||
              locale.countryCode == 'TW' ||
              locale.countryCode == 'HK' ||
              locale.countryCode == 'MO';

          if (isTraditional) {
            // supportedLocales から zh + Hant を探す
            final hant = supportedLocales.firstWhere(
              (l) => l.languageCode == 'zh' && l.scriptCode == 'Hant',
              orElse: () => supportedLocales.first,
            );
            return hant;
          } else {
            // それ以外の zh は簡体
            final simplified = supportedLocales.firstWhere(
              (l) => l.languageCode == 'zh' && l.scriptCode == null,
              orElse: () => supportedLocales.first,
            );
            return simplified;
          }
        }

        // それ以外の言語はデフォルト挙動（言語コードで一致したもの）
        return supportedLocales.firstWhere(
          (l) => l.languageCode == locale.languageCode,
          orElse: () => supportedLocales.first,
        );
      },

      theme: ThemeData(primarySwatch: Colors.blue),
      home: const MainTabScaffold(), // ← ここに差し替え
    );
  }
}
