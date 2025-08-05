import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ja.dart';

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
    Locale('ja')
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
  /// **'Press the recording button and play a note. Recording will stop automatically after 5 seconds. You can record multiple times to compare different settings. Files are saved in the app and can be played, renamed, analyzed, or deleted.'**
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

  /// No description provided for @notes.
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notes;

  /// No description provided for @notesDescription.
  ///
  /// In en, this message translates to:
  /// **'If RMS is too high or low, other values may be affected. Be careful comparing files with very different volume levels. Symmetry is experimental and should be interpreted with other parameters.'**
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
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'ja'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'ja': return AppLocalizationsJa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
