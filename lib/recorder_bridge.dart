import 'package:flutter/services.dart';

class RecorderBridge {
  static const MethodChannel _channel = MethodChannel('native_recorder');

  static Future<void> startRecording(String path) async {
    try {
      await _channel.invokeMethod('startRecording', {'path': path});
    } on PlatformException catch (e) {
      throw 'Failed to start recording: ${e.message}';
    }
  }

  static Future<void> stopRecording() async {
    try {
      await _channel.invokeMethod('stopRecording');
    } on PlatformException catch (e) {
      throw 'Failed to stop recording: ${e.message}';
    }
  }

  static Future<bool> isRecording() async {
    try {
      final bool result = await _channel.invokeMethod('isRecording');
      return result;
    } on PlatformException catch (e) {
      throw 'Failed to check recording status: ${e.message}';
    }
  }
}
