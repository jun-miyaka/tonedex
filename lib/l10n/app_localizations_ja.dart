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
  String get whatIsToneDexDescription => 'ToneDexは楽器プレイヤーが、楽器の音質を分析・評価するためのアプリです。これまで「明るい」「暗\nい」「エッジのきいた」「暖かい」など印象だけで語られていた音質を音質パラメーターを用いて、客観的に知\nることができます。';

  @override
  String get howToUse => '使用方法';

  @override
  String get howToUseDescription => 'アプリの録音ボタンを押し、あなたの楽器の特定の一音を鳴らしてください。録音は５秒間で自動停止します。\n録音は複数回行うことができます。楽器のセッティングや演奏の仕方を変えて、複数の録音をしてみてください。\n\n録音したファイルは、アプリの画面上に保存されます。録音された音を再生（ボタン）で確認できます。\n\nまたゴミ箱（ボタン）でファイルを削除できます。\n\nさらにエンピツ（ボタン）でファイル名を変更できます。\n\nそして、分析（ボタン）で各録音ファイルの音質パラメーターを分析し、結果を表示します。さらに複数の録音ファイルがある場合、それぞれを比較した棒グラフを表示します。数値及び棒グラフは右上トグルスイッチからローデータかZスコアを選んで表示することができます。\n\n分析結果の数値やグラフの高低からあなたの楽器の音質の評価を解釈してみてください。\n\n分析の数値結果、グラフについては共有ボタンにより、シェアすることができます。\n\nなお、Brightnessのローデータのグラフは見やすさのために直近データの分布（P5–P95）でオートスケール表示されますので、ローデータの値とは異なります。\n\n分析の数値結果、グラフについては共有ボタンにより、シェアすることができます。';

  @override
  String get analysisParameters => '分析パラメーター';

  @override
  String get analysisParametersDescription => 'ToneDexでは、録音された音から以下の5つの指標を分析しています。これらは、音の強さや色合い、雑\\n味などを数値化したもので、音質の傾向を客観的に確認するのに役立ちます。\n\n• RMS（Root Mean Square）：音のエネルギー・大きさを表します。強く吹いた音や録音レベルが高い音で大きくなります。\n\n・ZCR（ゼロ交差率）：波形が0を横切る回数です。ザラザラした音、明瞭なアタック音などで高くなります。\n\n• Centroid（スペクトル重心）：音の明るさや鋭さに関係し、高音域に成分が偏ると高くなります。\n\n• Bandwidth（帯域幅）：音のスペクトルがどれくらい広がっているかを示します。複雑で広がった音で高くなります。\n\n• Brightness（高周波成分）：高域エネルギーの比率（0.0〜1.0）。高音が強い音で高くなります。';

  @override
  String get aboutZScore => 'Zスコアについて';

  @override
  String get aboutZScoreDescription => '各パラメーターはZスコアにより標準化され（平均0、標準偏差1）、比較しやすくなっています：\n\nZ ≈ 0 → 平均的\nZ ≈ ±1 → やや高め／低め\nZ ≥ ±2 → 顕著な差あり';

  @override
  String get toneDexMapHelpTitle => 'ToneDex（マップ）について';

  @override
  String get toneDexMapHelpBody => 'ToneDex（マップ）は、複数の録音の音質を「位置関係」として比較する図です。録音同士の音色の違いを俯瞰するための目安として使えます。\n\n横軸は Focused（集中）↔ Broad（分散）を表し、Bandwidth と ZCR の組合せから計算しています。\n縦軸は Warm（落ち着き）↔ Brilliant（きらびやか）を表し、Centroid と Brightness の組合せから計算しています。\n\n※このマップは、今回録音したデータの範囲内で相対的に位置を調整しています。そのため、別の録音セッションのグラフと直接比較する用途には向いていません。';

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

  @override
  String get support => '開発者をサポート';

  @override
  String get supportDescription => 'ToneDexを気に入っていただけたら、Buy Me a Coffeeで開発者を応援してください。';

  @override
  String get buyMeACoffee => 'Buy Me a Coffee';

  @override
  String get displayModeRaw => 'ローデータ';

  @override
  String get displayModeZscore => 'Zスコア';

  @override
  String get aboutToneMapper => 'ToneMapper（トーンマッパー）について';

  @override
  String get howToUseToneMapper => 'ToneMapper（トーンマッパー）は、楽器の音質をリアルタイムで表示します。表示される音質パラメータはRMS（Root Mean Square）、ZCR（ゼロ交差率）、Brightness（高周波）の３つです。演奏しながら、音質がどう変わるか試してみてください。';

  @override
  String get toneMapperTitle => 'ToneMapper(トーンマッパー）';

  @override
  String get tuner_title => 'ToneDex Tuner';

  @override
  String get tuner_realtime_tuner => 'リアルタイムチューナー';

  @override
  String get tuner_pitch_checker => 'ピッチチェッカー';

  @override
  String get tuner_target_note => 'ターゲット音';

  @override
  String get tuner_reference_pitch => 'A4（基準音）';

  @override
  String get tuner_measure_5sec => '5秒間のピッチをチェック';

  @override
  String get tuner_measure_10sec => '10秒間のピッチをチェック';

  @override
  String get tuner_measuring_now => '測定中…';

  @override
  String tuner_pitch_timeline_title(Object seconds) {
    return '$seconds秒間のピッチ推移（cents）';
  }

  @override
  String get tuner_score_label => 'スコア';

  @override
  String get tuner_pitch_stability => 'ピッチの安定度';

  @override
  String get tuner_average_error => '平均誤差';

  @override
  String get tuner_sample_count => 'サンプル数';

  @override
  String get tuner_result_header => '測定結果';

  @override
  String get tuner_share_result => '結果を共有';

  @override
  String get tuner_shared_title => 'ToneDex Tuner - 測定結果';

  @override
  String get tuner_shared_measured_with => 'ToneDex チューナーで測定';

  @override
  String get tuner_pitch_low => '左＝低い（フラット）';

  @override
  String get tuner_pitch_high => '右＝高い（シャープ）';

  @override
  String get tuner_pitch_indicator => 'ピッチ表示';

  @override
  String get tuner_pitch_axis_hint => '左＝低い（フラット） / 右＝高い（シャープ）';

  @override
  String get tuner_permission_denied => 'マイクの権限が許可されていません';

  @override
  String get tuner_permission_request_message => '測定を行うにはマイクへのアクセスを許可してください。';

  @override
  String get tuner_start_countdown => '測定開始します…';

  @override
  String tuner_countdown_label(Object seconds) {
    return '録音開始まで: $seconds 秒';
  }

  @override
  String tuner_measuring_label(Object seconds) {
    return '測定中…（$seconds秒間）';
  }

  @override
  String get tuner_select_duration => '測定時間';

  @override
  String get tuner_seconds_suffix => '秒';

  @override
  String get tuner_seconds_5 => '5秒';

  @override
  String get tuner_seconds_10 => '10秒';

  @override
  String get tuner_note_label => '音名';

  @override
  String get tuner_current_pitch => '現在のピッチ';

  @override
  String get tuner_error_no_pitch_detected => 'ピッチが検出できませんでした。もう一度お試しください。';

  @override
  String get tuner_no_sample => 'サンプルがありません';

  @override
  String get tuner_no_result => 'まだ計測が行われていません。';

  @override
  String get tuner_dummy_chart_label => '5秒間の cents 推移（ダミー表示）';

  @override
  String get tuner_shared_target_note => 'ターゲット音';

  @override
  String get tuner_shared_base_a4 => 'A4（基準音）';

  @override
  String get tuner_shared_pitch_stability => 'ピッチの安定度';

  @override
  String get tuner_shared_average_error => '平均誤差';

  @override
  String get tuner_shared_sample_count => 'サンプル数';

  @override
  String get help_tuner_title => 'ToneDex Tuner について';

  @override
  String get help_tuner_intro => 'ToneDex のチューナー機能は、楽器のピッチ精度と安定度を数値とグラフで可視化する測定ツールです。通常のチューナーでは分かりにくい、ピッチの「揺れ」や「安定性」を定量的に確認できるのが特徴です。';

  @override
  String get help_tuner_howto => '1. ターゲット音（例：A、Bb）を選択します。\n2. 基準ピッチ A4（通常は 440Hz）を設定します。\n3. 計測時間（5秒または10秒）を選びます。\n4. 「Check Pitch」をタップします。\n5. 短いカウントダウンの後、計測が開始されます。\n6. 計測終了後、スコア、安定度、ピッチの推移が表示されます。';

  @override
  String get help_tuner_about_cent => 'ピッチの誤差は “セント（cent）” で表示されます。100 cent が半音に相当し、プラスは高め（シャープ）、マイナスは低め（フラット）を示します。';

  @override
  String get help_tuner_scores => '・スコアは「平均誤差」と「ピッチの安定度」から計算されます。\n・平均誤差：ターゲット音からどれだけずれていたかを示します。\n・安定度：ピッチの揺れ（標準偏差）の小ささを元に評価します。\n・正確で揺れの少ない音ほど高得点になります。';

  @override
  String get tuner_out_of_range_message => '目標音から大きく外れています。もう一度安定した音程でお試しください。';

  @override
  String pitchGraphTitle(int seconds) {
    return '$seconds秒間のピッチ推移（cents）';
  }

  @override
  String get actionComment1 => '今日のチャレンジはどうでしたか？';

  @override
  String get actionComment2 => '結果をシェアしてみませんか？';

  @override
  String get actionComment3 => 'どんな結果でしたか？解釈方法はヘルプにあります';

  @override
  String get actionComment4 => '複数の録音を並べると違いがよく分かります';

  @override
  String get close => '閉じる';

  @override
  String get tunerActionComment1 => '今日のチャレンジはどうでしたか？';

  @override
  String get tunerActionComment2 => '結果をシェアしてみませんか？';

  @override
  String get tunerActionComment3 => 'どんな結果でしたか？指標の説明はヘルプにあります';

  @override
  String get tunerActionComment4 => '他の音でも試してみましょう。';

  @override
  String get toneDexMapCaption => '今回の録音内での音の相対的な位置関係を示します';

  @override
  String get focusedLabel => 'Focused（集中）';

  @override
  String get broadLabel => 'Broad（分散）';

  @override
  String get warmLabel => 'Warm（落ち着き）';

  @override
  String get brilliantLabel => 'Brilliant（きらびやか）';

  @override
  String get homeIntroLine1 => '5秒の録音で、あなたの楽器の音色を数値やグラフで可視化';

  @override
  String get homeIntroLine2 => '「録音開始」を押して、音の探求を始めましょう';
}
