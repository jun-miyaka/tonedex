// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'ToneDex';

  @override
  String get visualizeYourTone => 'Visualize Your Tone';

  @override
  String get startRecording => 'Start Recording (5s Auto stop)';

  @override
  String get play => 'Play';

  @override
  String get delete => 'Delete';

  @override
  String get analyze => 'Analyze';

  @override
  String get share => 'Share';

  @override
  String get rename => 'Rename';

  @override
  String get recordingPermissionRequired => 'Microphone permission is required to record';

  @override
  String get help => 'Help';

  @override
  String get analysisResults => 'Analysis Results';

  @override
  String get whatIsToneDex => 'What is ToneDex?';

  @override
  String get whatIsToneDexDescription => 'ToneDex is an app that helps instrumentalists analyze and compare the tonal quality of their instrument objectively using audio parameters.';

  @override
  String get howToUse => 'How to use';

  @override
  String get howToUseDescription => 'Press the recording button and play a note. Recording will stop automatically after 5 seconds. You can record multiple times to compare different settings. Files are saved in the app and can be played, renamed, analyzed, or deleted.';

  @override
  String get analysisParameters => 'Analysis Parameters';

  @override
  String get analysisParametersDescription => 'The following 5 parameters are analyzed:\n\n• RMS: Energy or loudness of the sound.\n• ZCR: Zero-crossing rate, related to noise or attack.\n• Spectral Centroid: Indicates brightness or sharpness.\n• Bandwidth: Shows the spread of frequencies.\n• Brightness: High-frequency ratio (0.0–1.0 scale).';

  @override
  String get aboutZScore => 'About Z-Score';

  @override
  String get aboutZScoreDescription => 'Each parameter is standardized (mean = 0, std dev = 1) using Z-scores for comparison:\n\nZ ≈ 0 → Average\nZ ≈ ±1 → Slightly high/low\nZ ≥ ±2 → Significantly different';

  @override
  String get notes => 'Notes';

  @override
  String get notesDescription => 'If RMS is too high or low, other values may be affected. Be careful comparing files with very different volume levels. Symmetry is experimental and should be interpreted with other parameters.';

  @override
  String get rmsLabel => 'RMS (Volume)';

  @override
  String get zcrLabel => 'ZCR (Noise)';

  @override
  String get centroidLabel => 'Centroid (Brightness)';

  @override
  String get bandwidthLabel => 'Bandwidth (Spread)';

  @override
  String get symmetryLabel => 'Symmetry (Balance)';

  @override
  String get notAnalyzed => 'Not analyzed';

  @override
  String get notEnoughData => 'Not enough data to display';

  @override
  String get shareResults => 'Share Results';

  @override
  String get cancel => 'Cancel';

  @override
  String get editLabel => 'Edit label (max 8 characters)';

  @override
  String get notAnalyzedOrIncomplete => 'Not analyzed or data incomplete';

  @override
  String get recording => 'Recording...';

  @override
  String get rmsExplanation => 'RMS Energy: overall loudness';

  @override
  String get zcrExplanation => 'Zero Crossing Rate: high frequency / noise content';

  @override
  String get centroidExplanation => 'Spectral Centroid: brightness / sharpness';

  @override
  String get bandwidthExplanation => 'Spectral Bandwidth: frequency spread';

  @override
  String get symmetryExplanation => 'Symmetry: waveform energy balance';

  @override
  String get welcomeTitle => 'Welcome to ToneDex!';

  @override
  String get welcomeMessage => 'If you\'re new, open the menu and tap \"Help\" to learn how to use the app.';

  @override
  String get gotIt => 'Got it!';

  @override
  String get brightnessLabel => 'Brightness (High-frequency ratio)';

  @override
  String get brightnessExplanation => 'Brightness: Brightness Index';
}
