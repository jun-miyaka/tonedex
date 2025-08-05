// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Japanese (`ja`).
class AppLocalizationsJa extends AppLocalizations {
  AppLocalizationsJa([String locale = 'ja']) : super(locale);

  @override
  String get appTitle => 'ToneDex';

  @override
  String get visualizeYourTone => '音を見える化';

  @override
  String get startRecording => '録音開始（5秒で自動停止）';

  @override
  String get play => '再生';

  @override
  String get delete => '削除';

  @override
  String get analyze => '分析';

  @override
  String get share => '共有';

  @override
  String get rename => 'ファイル名変更';

  @override
  String get recordingPermissionRequired => '録音にはマイクの許可が必要です';

  @override
  String get help => 'ヘルプ';

  @override
  String get analysisResults => '分析結果';

  @override
  String get whatIsToneDex => 'ToneDexとは？';

  @override
  String get whatIsToneDexDescription => 'TondDexは楽器プレイヤーが、楽器の音質を分析・評価するためのアプリです。これまで「明るい」「暗\nい」「エッジのきいた」「暖かい」など印象だけで語られていた音質を音質パラメーターを用いて、客観的に知\nることができます。';

  @override
  String get howToUse => '使用方法';

  @override
  String get howToUseDescription => 'アプリの録音ボタンを押し、あなたの楽器の特定の一音を鳴らしてください。録音は５秒間で自動停止します。\n録音は複数回行うことができます。楽器のセッティングや演奏の仕方を変えて、複数の録音をしてみてください。\n\n録音したファイルは、アプリの画面上に保存されます。録音された音を再生（ボタン）で確認できます。\n\nまたゴミ箱（ボタン）でファイルを削除できます。\n\nさらにエンピツ（ボタン）でファイル名を変更できます。\n\nそして、分析（ボタン）で各録音ファイルの音質パラメーターを分析し、結果を表示します。さらに複数の録音ファイルがある場合、それぞれを比較した棒グラフを表示します。分析結果の数値やグラフの高低からあなたの楽器の音質の評価を解釈してみてください。\n\n分析の数値結果、グラフについては共有ボタンにより、シェアすることができます。';

  @override
  String get analysisParameters => '分析パラメーター';

  @override
  String get analysisParametersDescription => 'ToneDexでは、録音された音から以下の5つの指標を分析しています。これらは、音の強さや色合い、雑\\n味などを数値化したもので、音質の傾向を客観的に確認するのに役立ちます。\n\n• RMS（Root Mean Square）：音のエネルギー・大きさを表します。強く吹いた音や録音レベルが高い音で大きくなります。\n\n・ZCR（ゼロ交差率）：波形が0を横切る回数です。ザラザラした音、明瞭なアタック音などで高くなります。\n\n• Centroid（スペクトル重心）：音の明るさや鋭さに関係し、高音域に成分が偏ると高くなります。\n\n• Bandwidth（帯域幅）：音のスペクトルがどれくらい広がっているかを示します。複雑で広がった音で高くなります。\n\n• Brightness（高周波成分）：高域エネルギーの比率（0.0〜1.0）。高音が強い音で高くなります。';

  @override
  String get aboutZScore => 'Zスコアについて';

  @override
  String get aboutZScoreDescription => '各パラメーターはZスコアにより標準化され（平均0、標準偏差1）、比較しやすくなっています：\n\nZ ≈ 0 → 平均的\nZ ≈ ±1 → やや高め／低め\nZ ≥ ±2 → 顕著な差あり';

  @override
  String get notes => '注意事項';

  @override
  String get notesDescription => 'RMSが極端に高い・低い場合（Zスコア±2以上）は、他の指標（ZCRなど）にも影響が出る可能性があります。そのため、録音レベルが大きく違うファイル同士の比較には注意が必要です。Symmetryは実験的指標であり、他の指標と併せて参考にしてください。';

  @override
  String get rmsLabel => 'RMS（音量・ラウドネス）';

  @override
  String get zcrLabel => 'ZCR（粗さ・ノイズ）';

  @override
  String get centroidLabel => 'Centroid（明るさ）';

  @override
  String get bandwidthLabel => 'Bandwidth（複雑さ・広がり）';

  @override
  String get symmetryLabel => 'Symmetry（周波数バランス）';

  @override
  String get notAnalyzed => '未分析';

  @override
  String get notEnoughData => '表示するデータがありません';

  @override
  String get shareResults => '結果を共有';

  @override
  String get cancel => 'キャンセル';

  @override
  String get editLabel => 'ラベル名を編集（最大8文字）';

  @override
  String get notAnalyzedOrIncomplete => '未分析';

  @override
  String get recording => '録音中…';

  @override
  String get rmsExplanation => 'RMSエネルギー：音量の大きさ';

  @override
  String get zcrExplanation => 'ゼロ交差率：高域・ノイズ成分の指標';

  @override
  String get centroidExplanation => 'スペクトル重心：音の明るさ・鋭さ';

  @override
  String get bandwidthExplanation => 'スペクトル帯域幅：周波数の広がり';

  @override
  String get symmetryExplanation => '対称性：波形のエネルギーバランス';

  @override
  String get welcomeTitle => 'ToneDexへようこそ！';

  @override
  String get welcomeMessage => '初めての方は、メニューからヘルプを開き、使用方法をご覧ください。';

  @override
  String get gotIt => 'OK';

  @override
  String get brightnessLabel => 'Brightness（高周波）';

  @override
  String get brightnessExplanation => 'Brightness：明るさ指標';
}
