import 'dart:async';
import 'dart:io';
import 'dart:math';
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
import 'l10n/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool _isReady = false;

  // 🔽 ネイティブ録音連携用チャンネルとオーディオプレイヤー
  static const MethodChannel _channel = MethodChannel(
    'native_recorder',
  ); // ✅ ここに1回だけ

  final AudioPlayer _player = AudioPlayer();
  String? _selectedRecording;
  final Map<String, Map<String, double>> _analysisResults = {};
  String? _currentFilePath;

  @override
  void initState() {
    super.initState();

    // 🔹 録音一覧の読み込み（非表示状態で先に準備）
    _loadRecordings();

    // 🔹 初期UI描画が完了したタイミングでフラグを立て、初回メッセージ表示
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showWelcomeMessageIfFirstLaunch();
      setState(() {
        _isReady = true; // UI使用可能状態へ
      });
    });
  }

  Future<void> _shareAllAnalysisResults(GlobalKey boundaryKey) async {
    final dir = await getApplicationDocumentsDirectory();

    // テキストファイルの生成
    final textFile = File('${dir.path}/analysis_results.txt');
    final textContent = List.generate(fileNames.length, (i) {
      final name = labels[i];
      final result = results.length > i && results[i].length == 5
          ? [
              'RMS: ${results[i][0].toStringAsFixed(3)}',
              'ZCR: ${results[i][1].toStringAsFixed(3)}',
              'Centroid: ${results[i][2].toStringAsFixed(3)}',
              'Bandwidth: ${results[i][3].toStringAsFixed(3)}',
              'Brightness: ${results[i][4].toStringAsFixed(3)}',
            ].join('\n')
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
    // 録音ファイルの一覧を読み込む処理（例）
    final directory = await getApplicationDocumentsDirectory();
    final files = directory.listSync().whereType<File>().toList();

    // setStateなどでファイルを反映
    setState(() {
      _recordings = files;
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

  String _generateFileName() {
    final now = DateTime.now();
    final formatted =
        '${now.year}${_pad2(now.month)}${_pad2(now.day)}_${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}';
    return 'recordings/$formatted.wav';
  }

  String _pad2(int n) => n.toString().padLeft(2, '0');

  Future<void> _startRecording() async {
    try {
      await _checkPermissions();

      final dir = await getApplicationDocumentsDirectory();
      final now = DateTime.now();
      final fileName =
          '${now.year}${_pad2(now.month)}${_pad2(now.day)}_${_pad2(now.hour)}${_pad2(now.minute)}${_pad2(now.second)}.wav';
      final filePath = '${dir.path}/$fileName';

      _currentFilePath = filePath; // 🔸 後で stopRecording で使う
      await _channel.invokeMethod('startRecording', {'path': filePath});

      setState(() {
        isRecording = true;
      });

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
      await _channel.invokeMethod('stopRecording');
      setState(() {
        isRecording = false;
      });

      if (_currentFilePath != null && File(_currentFilePath!).existsSync()) {
        setState(() {
          fileNames.add(_currentFilePath!); // 🔸 録音終了時に追加
          // ✅ ラベルも初期登録（例：20250718_220101）
          final label = _currentFilePath!
              .split('/')
              .last
              .replaceAll('.wav', '');
          labels.add(label);
        });
        // 🔽 ここを追加
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
        ), // ← localized from "ラベル名を編集 (最大8文字)",
        content: TextField(
          controller: controller,
          maxLength: 8,
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
    final std = sqrt(
      values.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) /
          values.length,
    );
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

    // ✅ グラフ全体をキャプチャ可能にする RepaintBoundary で囲む
    return RepaintBoundary(
      key: boundaryKey,
      child: GraphWidget(
        zScores: zScoreList,
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
      ),
    );
  }

  // 🔽 メインUI構築（録音・再生・分析・削除 + グラフ表示）
  @override
  Widget build(BuildContext context) {
    if (!_isReady) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ToneDex', style: TextStyle(fontSize: 20)),
            Text(
              AppLocalizations.of(context)!.visualizeYourTone,
              style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 録音ボタン
            ElevatedButton(
              onPressed: isRecording ? null : _startRecording,
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

            // 共有ボタン
            ElevatedButton(
              onPressed: () => _shareAllAnalysisResults(_graphKey),
              child: Text(AppLocalizations.of(context)!.shareResults),
            ),

            const SizedBox(height: 16),

            // 録音ファイル一覧
            ...List<Widget>.generate(fileNames.length, (index) {
              final name = fileNames[index].split('/').last;
              return Card(
                child: ListTile(
                  title: Text(labels[index]),
                  subtitle: results.length > index && results[index].length == 5
                      ? Text(
                          'RMS: ${results[index][0].toStringAsFixed(3)}\n'
                          'ZCR: ${results[index][1].toStringAsFixed(3)}\n'
                          'Centroid: ${results[index][2].toStringAsFixed(3)}\n'
                          'Bandwidth: ${results[index][3].toStringAsFixed(3)}\n'
                          'Brightness: ${results[index][4].toStringAsFixed(3)}',
                        )
                      : Text(
                          AppLocalizations.of(context)!.notAnalyzedOrIncomplete,
                        ), // ← localized from "未分析またはデータ不完全",
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.play_arrow),
                        onPressed: () => _play(fileNames[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.analytics),
                        onPressed: () => _analyze(fileNames[index]),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit),
                        onPressed: () => _showRenameDialog(index),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _delete(fileNames[index]),
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
}

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
      supportedLocales: const [Locale('en'), Locale('ja')],
      // locale: Locale('ja'), // ← 強制日本語化したいときはコメント解除
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const RecorderPage(), // ← あなたのトップ画面
    );
  }
}
