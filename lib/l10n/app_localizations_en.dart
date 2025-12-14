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
  String get howToUseDescription => 'Tap the Record button and play a specific note on your instrument. Recording stops automatically after 5 seconds.\nYou can record multiple takes. Try different setups and playing styles.\n\nAll takes are saved in the app. Use the Play button to listen back.\n\nUse the Trash button to delete a take and the Pencil button to rename it.\n\nTap Analyze to compute sound-quality parameters for each take and show the results. If you have multiple takes, a bar chart will compare them. Use the toggle at the top-right to switch between Raw data and Z-score views.\n\nInterpret your instrument’s tone from the numbers and the chart.\n\nBrightness is auto-scaled for readability using the recent data distribution (P5–P95). The stored value remains the raw 0.0–1.0.\n\nYou can share the numeric results and charts via the Share button.';

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
  String get notesDescription => 'If RMS is too high or low, other values may be affected. Be careful comparing files with very different volume levels.';

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

  @override
  String get support => 'Support';

  @override
  String get supportDescription => 'If you enjoy using ToneDex, consider supporting the developer on Buy Me a Coffee.';

  @override
  String get buyMeACoffee => 'Buy Me a Coffee';

  @override
  String get displayModeRaw => 'Raw data';

  @override
  String get displayModeZscore => 'Z-score';

  @override
  String get aboutToneMapper => 'About ToneMapper';

  @override
  String get howToUseToneMapper => 'ToneMapper visualizes tone changes in real time while you play. It shows parameters such as RMS (Root Mean Square), ZCR (Zero-Crossing Rate), and Brightness (high-frequency ratio). Try playing and see how the tone moves.';

  @override
  String get toneMapperTitle => 'ToneMapper';

  @override
  String get tuner_title => 'ToneDex Tuner';

  @override
  String get tuner_realtime_tuner => 'Real-time Tuner';

  @override
  String get tuner_pitch_checker => 'Pitch Checker';

  @override
  String get tuner_target_note => 'Target Note';

  @override
  String get tuner_reference_pitch => 'A4 (Reference Pitch)';

  @override
  String get tuner_measure_5sec => 'Check pitch for 5 seconds';

  @override
  String get tuner_measure_10sec => 'Check pitch for 10 seconds';

  @override
  String get tuner_measuring_now => 'Measuring…';

  @override
  String tuner_pitch_timeline_title(Object seconds) {
    return 'Pitch variation over $seconds seconds (cents)';
  }

  @override
  String get tuner_score_label => 'Score';

  @override
  String get tuner_pitch_stability => 'Pitch Stability';

  @override
  String get tuner_average_error => 'Average Error';

  @override
  String get tuner_sample_count => 'Sample Count';

  @override
  String get tuner_result_header => 'Measurement Result';

  @override
  String get tuner_share_result => 'Share Result';

  @override
  String get tuner_shared_title => 'ToneDex Tuner - Measurement Result';

  @override
  String get tuner_shared_measured_with => 'Measured with ToneDex Tuner';

  @override
  String get tuner_pitch_low => 'Left = Flat (Lower)';

  @override
  String get tuner_pitch_high => 'Right = Sharp (Higher)';

  @override
  String get tuner_pitch_indicator => 'Pitch Indicator';

  @override
  String get tuner_pitch_axis_hint => 'Left = Flat / Right = Sharp';

  @override
  String get tuner_permission_denied => 'Microphone permission is not granted.';

  @override
  String get tuner_permission_request_message => 'Please allow microphone access to start measuring.';

  @override
  String get tuner_start_countdown => 'Starting measurement…';

  @override
  String tuner_countdown_label(Object seconds) {
    return 'Recording starts in: $seconds sec';
  }

  @override
  String tuner_measuring_label(Object seconds) {
    return 'Measuring… ($seconds sec)';
  }

  @override
  String get tuner_select_duration => 'Duration';

  @override
  String get tuner_seconds_suffix => 'sec';

  @override
  String get tuner_seconds_5 => '5 sec';

  @override
  String get tuner_seconds_10 => '10 sec';

  @override
  String get tuner_note_label => 'Note';

  @override
  String get tuner_current_pitch => 'Current Pitch';

  @override
  String get tuner_error_no_pitch_detected => 'No pitch detected. Please try again.';

  @override
  String get tuner_no_sample => 'No samples available';

  @override
  String get tuner_no_result => 'No measurement has been taken yet.';

  @override
  String get tuner_dummy_chart_label => 'Pitch variation (dummy)';

  @override
  String get tuner_shared_target_note => 'Target Note';

  @override
  String get tuner_shared_base_a4 => 'A4 (Reference Pitch)';

  @override
  String get tuner_shared_pitch_stability => 'Pitch Stability';

  @override
  String get tuner_shared_average_error => 'Average Error';

  @override
  String get tuner_shared_sample_count => 'Sample Count';

  @override
  String get help_tuner_title => 'About ToneDex Tuner';

  @override
  String get help_tuner_intro => 'The ToneDex Tuner visualizes the pitch accuracy and stability of your instrument through numerical values and graphs. Unlike standard tuners, it quantifies pitch fluctuations and stability for more precise analysis.';

  @override
  String get help_tuner_howto => '1. Select the target note (e.g., A, Bb).\n2. Set the reference pitch A4 (typically 440 Hz).\n3. Choose a measurement duration (5 or 10 seconds).\n4. Tap \"Check Pitch\".\n5. Measurement starts after a short countdown.\n6. After measuring, your score, stability, and pitch timeline will be displayed.';

  @override
  String get help_tuner_about_cent => 'Pitch deviation is displayed in cents. 100 cents equals one semitone. Positive values mean the pitch is sharp, and negative values mean it is flat.';

  @override
  String get help_tuner_scores => '• The score is calculated from both average error and pitch stability.\n• Average Error: how far the pitch deviated from the target note.\n• Stability: evaluated based on the amount of pitch fluctuation.\n• Higher scores indicate more accurate and stable pitch.';

  @override
  String get tuner_out_of_range_message => 'The pitch is too far from the target note. Please try again with a more stable pitch.';

  @override
  String pitchGraphTitle(int seconds) {
    return 'Pitch change in $seconds sec (cents)';
  }
}
