import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ja'),
    Locale('zh'),
    Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'ToneDex'**
  String get appTitle;

  /// No description provided for @visualizeYourTone.
  ///
  /// In en, this message translates to:
  /// **'Visualize Your Tone'**
  String get visualizeYourTone;

  /// No description provided for @startRecording.
  ///
  /// In en, this message translates to:
  /// **'Start Recording (5s Auto stop)'**
  String get startRecording;

  /// No description provided for @play.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @analyze.
  ///
  /// In en, this message translates to:
  /// **'Analyze'**
  String get analyze;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @rename.
  ///
  /// In en, this message translates to:
  /// **'Rename'**
  String get rename;

  /// No description provided for @recordingPermissionRequired.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is required to record'**
  String get recordingPermissionRequired;

  /// No description provided for @help.
  ///
  /// In en, this message translates to:
  /// **'Help'**
  String get help;

  /// No description provided for @analysisResults.
  ///
  /// In en, this message translates to:
  /// **'Analysis Results'**
  String get analysisResults;

  /// No description provided for @whatIsToneDex.
  ///
  /// In en, this message translates to:
  /// **'What is ToneDex?'**
  String get whatIsToneDex;

  /// No description provided for @whatIsToneDexDescription.
  ///
  /// In en, this message translates to:
  /// **'ToneDex is an app that helps instrumentalists analyze and compare the tonal quality of their instrument objectively using audio parameters.'**
  String get whatIsToneDexDescription;

  /// No description provided for @howToUse.
  ///
  /// In en, this message translates to:
  /// **'How to use'**
  String get howToUse;

  /// No description provided for @howToUseDescription.
  ///
  /// In en, this message translates to:
  /// **'Tap the Record button and play a specific note on your instrument. Recording stops automatically after 5 seconds.\nYou can record multiple takes. Try different setups and playing styles.\n\nAll takes are saved in the app. Use the Play button to listen back.\n\nUse the Trash button to delete a take and the Pencil button to rename it.\n\nTap Analyze to compute sound-quality parameters for each take and show the results. If you have multiple takes, a bar chart will compare them. Use the toggle at the top-right to switch between Raw data and Z-score views.\n\nInterpret your instrument’s tone from the numbers and the chart.\n\nBrightness is auto-scaled for readability using the recent data distribution (P5–P95). The stored value remains the raw 0.0–1.0.\n\nYou can share the numeric results and charts via the Share button.'**
  String get howToUseDescription;

  /// No description provided for @analysisParameters.
  ///
  /// In en, this message translates to:
  /// **'Analysis Parameters'**
  String get analysisParameters;

  /// No description provided for @analysisParametersDescription.
  ///
  /// In en, this message translates to:
  /// **'The following 5 parameters are analyzed:\n\n• RMS: Energy or loudness of the sound.\n• ZCR: Zero-crossing rate, related to noise or attack.\n• Spectral Centroid: Indicates brightness or sharpness.\n• Bandwidth: Shows the spread of frequencies.\n• Brightness: High-frequency ratio (0.0–1.0 scale).'**
  String get analysisParametersDescription;

  /// No description provided for @aboutZScore.
  ///
  /// In en, this message translates to:
  /// **'About Z-Score'**
  String get aboutZScore;

  /// No description provided for @aboutZScoreDescription.
  ///
  /// In en, this message translates to:
  /// **'Each parameter is standardized (mean = 0, std dev = 1) using Z-scores for comparison:\n\nZ ≈ 0 → Average\nZ ≈ ±1 → Slightly high/low\nZ ≥ ±2 → Significantly different'**
  String get aboutZScoreDescription;

  /// No description provided for @toneDexMapHelpTitle.
  ///
  /// In en, this message translates to:
  /// **'About ToneDex (Map)'**
  String get toneDexMapHelpTitle;

  /// No description provided for @toneDexMapHelpBody.
  ///
  /// In en, this message translates to:
  /// **'ToneDex (Map) visualizes the relative positions of multiple recordings based on their sound characteristics. It is intended as an overview to compare tonal differences between recordings.\n\nThe horizontal axis represents Focused ↔ Broad, calculated from a combination of Bandwidth and ZCR.\nThe vertical axis represents Warm ↔ Brilliant, calculated from a combination of Centroid and Brightness.\n\nNote: The positions on this map are normalized within the current recording set. Therefore, the map is not intended for direct comparison across different recording sessions.'**
  String get toneDexMapHelpBody;

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesDescription.
  ///
  /// In en, this message translates to:
  /// **'If RMS is too high or low, other values may be affected. Be careful comparing files with very different volume levels.'**
  String get notesDescription;

  /// No description provided for @rmsLabel.
  ///
  /// In en, this message translates to:
  /// **'RMS (Volume)'**
  String get rmsLabel;

  /// No description provided for @zcrLabel.
  ///
  /// In en, this message translates to:
  /// **'ZCR (Noise)'**
  String get zcrLabel;

  /// No description provided for @centroidLabel.
  ///
  /// In en, this message translates to:
  /// **'Centroid (Brightness)'**
  String get centroidLabel;

  /// No description provided for @bandwidthLabel.
  ///
  /// In en, this message translates to:
  /// **'Bandwidth (Spread)'**
  String get bandwidthLabel;

  /// No description provided for @symmetryLabel.
  ///
  /// In en, this message translates to:
  /// **'Symmetry (Balance)'**
  String get symmetryLabel;

  /// No description provided for @notAnalyzed.
  ///
  /// In en, this message translates to:
  /// **'Not analyzed'**
  String get notAnalyzed;

  /// No description provided for @notEnoughData.
  ///
  /// In en, this message translates to:
  /// **'Not enough data to display'**
  String get notEnoughData;

  /// No description provided for @shareResults.
  ///
  /// In en, this message translates to:
  /// **'Share Results'**
  String get shareResults;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @editLabel.
  ///
  /// In en, this message translates to:
  /// **'Edit label (max 8 characters)'**
  String get editLabel;

  /// No description provided for @notAnalyzedOrIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Not analyzed or data incomplete'**
  String get notAnalyzedOrIncomplete;

  /// No description provided for @recording.
  ///
  /// In en, this message translates to:
  /// **'Recording...'**
  String get recording;

  /// No description provided for @rmsExplanation.
  ///
  /// In en, this message translates to:
  /// **'RMS Energy: overall loudness'**
  String get rmsExplanation;

  /// No description provided for @zcrExplanation.
  ///
  /// In en, this message translates to:
  /// **'Zero Crossing Rate: high frequency / noise content'**
  String get zcrExplanation;

  /// No description provided for @centroidExplanation.
  ///
  /// In en, this message translates to:
  /// **'Spectral Centroid: brightness / sharpness'**
  String get centroidExplanation;

  /// No description provided for @bandwidthExplanation.
  ///
  /// In en, this message translates to:
  /// **'Spectral Bandwidth: frequency spread'**
  String get bandwidthExplanation;

  /// No description provided for @symmetryExplanation.
  ///
  /// In en, this message translates to:
  /// **'Symmetry: waveform energy balance'**
  String get symmetryExplanation;

  /// No description provided for @welcomeTitle.
  ///
  /// In en, this message translates to:
  /// **'Welcome to ToneDex!'**
  String get welcomeTitle;

  /// Popup welcome message shown on first launch
  ///
  /// In en, this message translates to:
  /// **'If you\'re new, open the menu and tap \"Help\" to learn how to use the app.'**
  String get welcomeMessage;

  /// No description provided for @gotIt.
  ///
  /// In en, this message translates to:
  /// **'Got it!'**
  String get gotIt;

  /// No description provided for @brightnessLabel.
  ///
  /// In en, this message translates to:
  /// **'Brightness (High-frequency ratio)'**
  String get brightnessLabel;

  /// No description provided for @brightnessExplanation.
  ///
  /// In en, this message translates to:
  /// **'Brightness: Brightness Index'**
  String get brightnessExplanation;

  /// No description provided for @support.
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// No description provided for @supportDescription.
  ///
  /// In en, this message translates to:
  /// **'If you enjoy using ToneDex, consider supporting the developer on Buy Me a Coffee.'**
  String get supportDescription;

  /// No description provided for @buyMeACoffee.
  ///
  /// In en, this message translates to:
  /// **'Buy Me a Coffee'**
  String get buyMeACoffee;

  /// No description provided for @displayModeRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw data'**
  String get displayModeRaw;

  /// No description provided for @displayModeZscore.
  ///
  /// In en, this message translates to:
  /// **'Z-score'**
  String get displayModeZscore;

  /// No description provided for @aboutToneMapper.
  ///
  /// In en, this message translates to:
  /// **'About ToneMapper'**
  String get aboutToneMapper;

  /// No description provided for @howToUseToneMapper.
  ///
  /// In en, this message translates to:
  /// **'ToneMapper visualizes tone changes in real time while you play. It shows parameters such as RMS (Root Mean Square), ZCR (Zero-Crossing Rate), and Brightness (high-frequency ratio). Try playing and see how the tone moves.'**
  String get howToUseToneMapper;

  /// No description provided for @toneMapperTitle.
  ///
  /// In en, this message translates to:
  /// **'ToneMapper'**
  String get toneMapperTitle;

  /// No description provided for @tuner_title.
  ///
  /// In en, this message translates to:
  /// **'ToneDex Tuner'**
  String get tuner_title;

  /// No description provided for @tuner_realtime_tuner.
  ///
  /// In en, this message translates to:
  /// **'Real-time Tuner'**
  String get tuner_realtime_tuner;

  /// No description provided for @tuner_pitch_checker.
  ///
  /// In en, this message translates to:
  /// **'Pitch Checker'**
  String get tuner_pitch_checker;

  /// No description provided for @tuner_target_note.
  ///
  /// In en, this message translates to:
  /// **'Target Note'**
  String get tuner_target_note;

  /// No description provided for @tuner_reference_pitch.
  ///
  /// In en, this message translates to:
  /// **'A4 (Reference Pitch)'**
  String get tuner_reference_pitch;

  /// No description provided for @tuner_measure_5sec.
  ///
  /// In en, this message translates to:
  /// **'Check pitch for 5 seconds'**
  String get tuner_measure_5sec;

  /// No description provided for @tuner_measure_10sec.
  ///
  /// In en, this message translates to:
  /// **'Check pitch for 10 seconds'**
  String get tuner_measure_10sec;

  /// No description provided for @tuner_measuring_now.
  ///
  /// In en, this message translates to:
  /// **'Measuring…'**
  String get tuner_measuring_now;

  /// No description provided for @tuner_pitch_timeline_title.
  ///
  /// In en, this message translates to:
  /// **'Pitch variation over {seconds} seconds (cents)'**
  String tuner_pitch_timeline_title(Object seconds);

  /// No description provided for @tuner_score_label.
  ///
  /// In en, this message translates to:
  /// **'Score'**
  String get tuner_score_label;

  /// No description provided for @tuner_pitch_stability.
  ///
  /// In en, this message translates to:
  /// **'Pitch Stability'**
  String get tuner_pitch_stability;

  /// No description provided for @tuner_average_error.
  ///
  /// In en, this message translates to:
  /// **'Average Error'**
  String get tuner_average_error;

  /// No description provided for @tuner_sample_count.
  ///
  /// In en, this message translates to:
  /// **'Sample Count'**
  String get tuner_sample_count;

  /// No description provided for @tuner_result_header.
  ///
  /// In en, this message translates to:
  /// **'Measurement Result'**
  String get tuner_result_header;

  /// No description provided for @tuner_share_result.
  ///
  /// In en, this message translates to:
  /// **'Share Result'**
  String get tuner_share_result;

  /// No description provided for @tuner_shared_title.
  ///
  /// In en, this message translates to:
  /// **'ToneDex Tuner - Measurement Result'**
  String get tuner_shared_title;

  /// No description provided for @tuner_shared_measured_with.
  ///
  /// In en, this message translates to:
  /// **'Measured with ToneDex Tuner'**
  String get tuner_shared_measured_with;

  /// No description provided for @tuner_pitch_low.
  ///
  /// In en, this message translates to:
  /// **'Left = Flat (Lower)'**
  String get tuner_pitch_low;

  /// No description provided for @tuner_pitch_high.
  ///
  /// In en, this message translates to:
  /// **'Right = Sharp (Higher)'**
  String get tuner_pitch_high;

  /// No description provided for @tuner_pitch_indicator.
  ///
  /// In en, this message translates to:
  /// **'Pitch Indicator'**
  String get tuner_pitch_indicator;

  /// No description provided for @tuner_pitch_axis_hint.
  ///
  /// In en, this message translates to:
  /// **'Left = Flat / Right = Sharp'**
  String get tuner_pitch_axis_hint;

  /// No description provided for @tuner_permission_denied.
  ///
  /// In en, this message translates to:
  /// **'Microphone permission is not granted.'**
  String get tuner_permission_denied;

  /// No description provided for @tuner_permission_request_message.
  ///
  /// In en, this message translates to:
  /// **'Please allow microphone access to start measuring.'**
  String get tuner_permission_request_message;

  /// No description provided for @tuner_start_countdown.
  ///
  /// In en, this message translates to:
  /// **'Starting measurement…'**
  String get tuner_start_countdown;

  /// No description provided for @tuner_countdown_label.
  ///
  /// In en, this message translates to:
  /// **'Recording starts in: {seconds} sec'**
  String tuner_countdown_label(Object seconds);

  /// No description provided for @tuner_measuring_label.
  ///
  /// In en, this message translates to:
  /// **'Measuring… ({seconds} sec)'**
  String tuner_measuring_label(Object seconds);

  /// No description provided for @tuner_select_duration.
  ///
  /// In en, this message translates to:
  /// **'Duration'**
  String get tuner_select_duration;

  /// No description provided for @tuner_seconds_suffix.
  ///
  /// In en, this message translates to:
  /// **'sec'**
  String get tuner_seconds_suffix;

  /// No description provided for @tuner_seconds_5.
  ///
  /// In en, this message translates to:
  /// **'5 sec'**
  String get tuner_seconds_5;

  /// No description provided for @tuner_seconds_10.
  ///
  /// In en, this message translates to:
  /// **'10 sec'**
  String get tuner_seconds_10;

  /// No description provided for @tuner_note_label.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get tuner_note_label;

  /// No description provided for @tuner_current_pitch.
  ///
  /// In en, this message translates to:
  /// **'Current Pitch'**
  String get tuner_current_pitch;

  /// No description provided for @tuner_error_no_pitch_detected.
  ///
  /// In en, this message translates to:
  /// **'No pitch detected. Please try again.'**
  String get tuner_error_no_pitch_detected;

  /// No description provided for @tuner_no_sample.
  ///
  /// In en, this message translates to:
  /// **'No samples available'**
  String get tuner_no_sample;

  /// No description provided for @tuner_no_result.
  ///
  /// In en, this message translates to:
  /// **'No measurement has been taken yet.'**
  String get tuner_no_result;

  /// No description provided for @tuner_dummy_chart_label.
  ///
  /// In en, this message translates to:
  /// **'Pitch variation (dummy)'**
  String get tuner_dummy_chart_label;

  /// No description provided for @tuner_shared_target_note.
  ///
  /// In en, this message translates to:
  /// **'Target Note'**
  String get tuner_shared_target_note;

  /// No description provided for @tuner_shared_base_a4.
  ///
  /// In en, this message translates to:
  /// **'A4 (Reference Pitch)'**
  String get tuner_shared_base_a4;

  /// No description provided for @tuner_shared_pitch_stability.
  ///
  /// In en, this message translates to:
  /// **'Pitch Stability'**
  String get tuner_shared_pitch_stability;

  /// No description provided for @tuner_shared_average_error.
  ///
  /// In en, this message translates to:
  /// **'Average Error'**
  String get tuner_shared_average_error;

  /// No description provided for @tuner_shared_sample_count.
  ///
  /// In en, this message translates to:
  /// **'Sample Count'**
  String get tuner_shared_sample_count;

  /// No description provided for @help_tuner_title.
  ///
  /// In en, this message translates to:
  /// **'About ToneDex Tuner'**
  String get help_tuner_title;

  /// No description provided for @help_tuner_intro.
  ///
  /// In en, this message translates to:
  /// **'The ToneDex Tuner visualizes the pitch accuracy and stability of your instrument through numerical values and graphs. Unlike standard tuners, it quantifies pitch fluctuations and stability for more precise analysis.'**
  String get help_tuner_intro;

  /// No description provided for @help_tuner_howto.
  ///
  /// In en, this message translates to:
  /// **'1. Select the target note (e.g., A, Bb).\n2. Set the reference pitch A4 (typically 440 Hz).\n3. Choose a measurement duration (5 or 10 seconds).\n4. Tap \"Check Pitch\".\n5. Measurement starts after a short countdown.\n6. After measuring, your score, stability, and pitch timeline will be displayed.'**
  String get help_tuner_howto;

  /// No description provided for @help_tuner_about_cent.
  ///
  /// In en, this message translates to:
  /// **'Pitch deviation is displayed in cents. 100 cents equals one semitone. Positive values mean the pitch is sharp, and negative values mean it is flat.'**
  String get help_tuner_about_cent;

  /// No description provided for @help_tuner_scores.
  ///
  /// In en, this message translates to:
  /// **'• The score is calculated from both average error and pitch stability.\n• Average Error: how far the pitch deviated from the target note.\n• Stability: evaluated based on the amount of pitch fluctuation.\n• Higher scores indicate more accurate and stable pitch.'**
  String get help_tuner_scores;

  /// No description provided for @tuner_out_of_range_message.
  ///
  /// In en, this message translates to:
  /// **'The pitch is too far from the target note. Please try again with a more stable pitch.'**
  String get tuner_out_of_range_message;

  /// Title of pitch graph with seconds variable
  ///
  /// In en, this message translates to:
  /// **'Pitch change in {seconds} sec (cents)'**
  String pitchGraphTitle(int seconds);

  /// No description provided for @actionComment1.
  ///
  /// In en, this message translates to:
  /// **'How was today’s challenge?'**
  String get actionComment1;

  /// No description provided for @actionComment2.
  ///
  /// In en, this message translates to:
  /// **'Want to share your results?'**
  String get actionComment2;

  /// No description provided for @actionComment3.
  ///
  /// In en, this message translates to:
  /// **'How did it look? Check Help for how to interpret it.'**
  String get actionComment3;

  /// No description provided for @actionComment4.
  ///
  /// In en, this message translates to:
  /// **'Try comparing multiple recordings—it makes differences clearer.'**
  String get actionComment4;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @tunerActionComment1.
  ///
  /// In en, this message translates to:
  /// **'How was today’s challenge?'**
  String get tunerActionComment1;

  /// No description provided for @tunerActionComment2.
  ///
  /// In en, this message translates to:
  /// **'Would you like to share your results?'**
  String get tunerActionComment2;

  /// No description provided for @tunerActionComment3.
  ///
  /// In en, this message translates to:
  /// **'How did it look? You can find explanations of the metrics in Help.'**
  String get tunerActionComment3;

  /// No description provided for @tunerActionComment4.
  ///
  /// In en, this message translates to:
  /// **'Try testing with other notes as well.'**
  String get tunerActionComment4;

  /// No description provided for @toneDexMapCaption.
  ///
  /// In en, this message translates to:
  /// **'Shows the relative position of each sound within the current recordings'**
  String get toneDexMapCaption;

  /// No description provided for @focusedLabel.
  ///
  /// In en, this message translates to:
  /// **'Focused'**
  String get focusedLabel;

  /// No description provided for @broadLabel.
  ///
  /// In en, this message translates to:
  /// **'Broad'**
  String get broadLabel;

  /// No description provided for @warmLabel.
  ///
  /// In en, this message translates to:
  /// **'Warm'**
  String get warmLabel;

  /// No description provided for @brilliantLabel.
  ///
  /// In en, this message translates to:
  /// **'Brilliant'**
  String get brilliantLabel;

  /// No description provided for @homeIntroLine1.
  ///
  /// In en, this message translates to:
  /// **'Visualize your instrument’s tone with numbers and graphs in just 5 seconds'**
  String get homeIntroLine1;

  /// No description provided for @homeIntroLine2.
  ///
  /// In en, this message translates to:
  /// **'Press “Start Recording” to begin exploring your sound'**
  String get homeIntroLine2;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {

  // Lookup logic when language+script codes are specified.
  switch (locale.languageCode) {
    case 'zh': {
  switch (locale.scriptCode) {
    case 'Hant': return AppLocalizationsZhHant();
   }
  break;
   }
  }

  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
    case 'zh': return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
