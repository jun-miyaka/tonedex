// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => 'ToneDex';

  @override
  String get visualizeYourTone => '可视化你的音色';

  @override
  String get startRecording => '开始录音（5 秒自动停止）';

  @override
  String get play => '播放';

  @override
  String get delete => '删除';

  @override
  String get analyze => '分析';

  @override
  String get share => '分享';

  @override
  String get rename => '重命名';

  @override
  String get recordingPermissionRequired => '需要麦克风权限才能录音';

  @override
  String get help => '帮助';

  @override
  String get analysisResults => '分析结果';

  @override
  String get whatIsToneDex => '什么是 ToneDex？';

  @override
  String get whatIsToneDexDescription => 'ToneDex 是一款帮助乐器演奏者利用声音参数，客观分析和比较自己乐器音色的应用。';

  @override
  String get howToUse => '使用方法';

  @override
  String get howToUseDescription => '点击录音按钮，然后在乐器上演奏指定的音。录音会在 5 秒后自动停止。\n可以录制多次尝试，试试不同的设置和演奏方式。\n\n所有录音都会保存在应用中。使用播放按钮可以回放。\n\n使用垃圾桶按钮删除录音，使用铅笔按钮可以重命名。\n\n点击“分析”即可为每个录音计算音质参数，并显示结果。如果有多个录音，将以条形图进行比较。右上角的切换按钮可以在原始数据和 Z 分数显示之间切换。\n\n通过数值和图表来解读你的乐器音色。\n\n为方便阅读，亮度会根据最近的数据分布（P5–P95）自动缩放显示。存储的值仍然是原始的 0.0–1.0。\n\n你可以通过“分享”按钮分享数值结果和图表。';

  @override
  String get analysisParameters => '分析参数';

  @override
  String get analysisParametersDescription => '会分析以下 5 个参数：\n\n• RMS：声音的能量或响度。\n• ZCR：过零率，与噪声或起音有关。\n• 频谱质心：表示明亮度或锐利度。\n• 频谱带宽：表示频率分布的宽度。\n• 亮度：高频成分的比例（0.0–1.0）。';

  @override
  String get aboutZScore => '关于 Z 分数';

  @override
  String get aboutZScoreDescription => '每个参数都会用 Z 分数进行标准化（平均值=0，标准差=1），便于比较：\n\nZ ≈ 0 → 平均水平\nZ ≈ ±1 → 略高 / 略低\nZ ≥ ±2 → 明显不同';

  @override
  String get notes => '注意事项';

  @override
  String get notesDescription => '如果 RMS 太高或太低，其他数值可能会受到影响。比较音量差异很大的录音时请多加注意。';

  @override
  String get rmsLabel => 'RMS（音量）';

  @override
  String get zcrLabel => 'ZCR（噪声）';

  @override
  String get centroidLabel => '质心（明亮度）';

  @override
  String get bandwidthLabel => '带宽（频谱宽度）';

  @override
  String get symmetryLabel => '对称性（平衡）';

  @override
  String get notAnalyzed => '尚未分析';

  @override
  String get notEnoughData => '数据不足，无法显示';

  @override
  String get shareResults => '分享结果';

  @override
  String get cancel => '取消';

  @override
  String get editLabel => '编辑标签（最多 8 个字符）';

  @override
  String get notAnalyzedOrIncomplete => '尚未分析或数据不完整';

  @override
  String get recording => '录音中…';

  @override
  String get rmsExplanation => 'RMS 能量：整体响度';

  @override
  String get zcrExplanation => '过零率：高频 / 噪声音成分';

  @override
  String get centroidExplanation => '频谱质心：明亮度 / 锐利度';

  @override
  String get bandwidthExplanation => '频谱带宽：频率分布的宽度';

  @override
  String get symmetryExplanation => '对称性：波形能量平衡';

  @override
  String get welcomeTitle => '欢迎使用 ToneDex！';

  @override
  String get welcomeMessage => '如果你是第一次使用，请打开菜单并点击“帮助”来查看使用方法。';

  @override
  String get gotIt => '知道了';

  @override
  String get brightnessLabel => '亮度（高频比例）';

  @override
  String get brightnessExplanation => '亮度：亮度指数';

  @override
  String get support => '支持';

  @override
  String get supportDescription => '如果你喜欢 ToneDex，可以在 Buy Me a Coffee 上支持开发者。';

  @override
  String get buyMeACoffee => '请我喝咖啡';

  @override
  String get displayModeRaw => '原始数据';

  @override
  String get displayModeZscore => 'Z 分数';

  @override
  String get aboutToneMapper => '关于 ToneMapper';

  @override
  String get howToUseToneMapper => 'ToneMapper 可以在你演奏时实时可视化音色变化。它会显示 RMS（均方根）、ZCR（过零率）和亮度（高频比例）等参数。试着演奏不同的音色，看看图像如何移动。';

  @override
  String get toneMapperTitle => 'ToneMapper';
}

/// The translations for Chinese, using the Han script (`zh_Hant`).
class AppLocalizationsZhHant extends AppLocalizationsZh {
  AppLocalizationsZhHant(): super('zh_Hant');

  @override
  String get appTitle => 'ToneDex';

  @override
  String get visualizeYourTone => '視覺化你的音色';

  @override
  String get startRecording => '開始錄音（5 秒自動停止）';

  @override
  String get play => '播放';

  @override
  String get delete => '刪除';

  @override
  String get analyze => '分析';

  @override
  String get share => '分享';

  @override
  String get rename => '重新命名';

  @override
  String get recordingPermissionRequired => '需要麥克風權限才能錄音';

  @override
  String get help => '說明';

  @override
  String get analysisResults => '分析結果';

  @override
  String get whatIsToneDex => '什麼是 ToneDex？';

  @override
  String get whatIsToneDexDescription => 'ToneDex 是一款幫助樂器演奏者利用聲音參數，客觀地分析與比較自己樂器音色的應用程式。';

  @override
  String get howToUse => '使用方式';

  @override
  String get howToUseDescription => '點擊錄音按鈕，然後在樂器上演奏指定的音。錄音會在 5 秒後自動停止。\n可以錄製多個 Take，試試不同的設定與吹奏方式。\n\n所有錄音都會保存在 App 中，可以用播放按鈕回放。\n\n使用垃圾桶按鈕刪除錄音，使用鉛筆按鈕重新命名。\n\n點擊「分析」即可為每個錄音計算音質參數並顯示結果。如果有多個錄音，會用長條圖進行比較。右上角的切換按鈕可以在原始數據與 Z 分數顯示之間切換。\n\n透過數字與圖表來解讀你的樂器音色。\n\n為了方便閱讀，亮度會依照最近的數據分佈（P5–P95）自動縮放顯示。儲存的值仍然是原始的 0.0–1.0。\n\n你可以透過「分享」按鈕分享數值結果與圖表。';

  @override
  String get analysisParameters => '分析參數';

  @override
  String get analysisParametersDescription => '會分析以下 5 個參數：\n\n• RMS：聲音的能量或音量。\n• ZCR：過零率，與雜訊或起音特性相關。\n• 頻譜質心：表示明亮度或銳利度。\n• 頻譜頻寬：表示頻率分佈的寬度。\n• 亮度：高頻成分的比例（0.0–1.0）。';

  @override
  String get aboutZScore => '關於 Z 分數';

  @override
  String get aboutZScoreDescription => '每個參數都會使用 Z 分數標準化（平均值=0，標準差=1），方便比較：\n\nZ ≈ 0 → 一般水準\nZ ≈ ±1 → 稍高 / 稍低\nZ ≥ ±2 → 差異明顯';

  @override
  String get notes => '注意事項';

  @override
  String get notesDescription => '如果 RMS 過高或過低，其他數值可能會受到影響。比較音量差異很大的錄音時請特別留意。';

  @override
  String get rmsLabel => 'RMS（音量）';

  @override
  String get zcrLabel => 'ZCR（雜訊）';

  @override
  String get centroidLabel => '質心（明亮度）';

  @override
  String get bandwidthLabel => '頻寬（頻譜寬度）';

  @override
  String get symmetryLabel => '對稱性（平衡）';

  @override
  String get notAnalyzed => '尚未分析';

  @override
  String get notEnoughData => '資料不足，無法顯示';

  @override
  String get shareResults => '分享結果';

  @override
  String get cancel => '取消';

  @override
  String get editLabel => '編輯標籤（最多 8 個字元）';

  @override
  String get notAnalyzedOrIncomplete => '尚未分析或資料不完整';

  @override
  String get recording => '錄音中…';

  @override
  String get rmsExplanation => 'RMS 能量：整體音量';

  @override
  String get zcrExplanation => '過零率：高頻 / 雜訊成分';

  @override
  String get centroidExplanation => '頻譜質心：明亮度 / 銳利度';

  @override
  String get bandwidthExplanation => '頻譜頻寬：頻率分佈的寬度';

  @override
  String get symmetryExplanation => '對稱性：波形能量平衡';

  @override
  String get welcomeTitle => '歡迎使用 ToneDex！';

  @override
  String get welcomeMessage => '如果你是第一次使用，請打開選單並點擊「說明」，查看使用方式。';

  @override
  String get gotIt => '了解了';

  @override
  String get brightnessLabel => '亮度（高頻比例）';

  @override
  String get brightnessExplanation => '亮度：亮度指標';

  @override
  String get support => '贊助';

  @override
  String get supportDescription => '如果你喜歡 ToneDex，可以在 Buy Me a Coffee 上贊助開發者。';

  @override
  String get buyMeACoffee => '請我喝咖啡';

  @override
  String get displayModeRaw => '原始資料';

  @override
  String get displayModeZscore => 'Z 分數';

  @override
  String get aboutToneMapper => '關於 ToneMapper';

  @override
  String get howToUseToneMapper => 'ToneMapper 可以在你演奏時即時視覺化音色變化。它會顯示 RMS（均方根）、ZCR（過零率）與亮度（高頻比例）等參數。試著吹奏不同的音色，看看圖形如何移動。';

  @override
  String get toneMapperTitle => 'ToneMapper';
}
