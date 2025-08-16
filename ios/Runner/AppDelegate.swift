// ファイル: ios/Runner/AppDelegate.swift
// 目的: Flutter MethodChannel("native_recorder") の iOS側実装を提供
// 既存の Android 実装と同じメソッド群: startRecording(path), stopRecording(), isRecording

import UIKit
import Flutter
import AVFoundation

@main
@objc class AppDelegate: FlutterAppDelegate {
  private var methodChannel: FlutterMethodChannel?
  private let recorder = IOSNativeRecorder()

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let controller = window?.rootViewController as! FlutterViewController
    methodChannel = FlutterMethodChannel(name: "native_recorder",
                                         binaryMessenger: controller.binaryMessenger)

    methodChannel?.setMethodCallHandler { [weak self] (call, result) in
      guard let self = self else { return }
      switch call.method {
      case "startRecording":
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
          result(FlutterError(code: "ARG_ERROR", message: "path is required", details: nil))
          return
        }
        do {
          try self.recorder.startRecording(toPath: path)
          result(nil)
        } catch {
          result(FlutterError(code: "START_FAILED", message: error.localizedDescription, details: nil))
        }

      case "stopRecording":
        self.recorder.stopRecording()
        result(nil)

      case "isRecording":
        result(self.recorder.isRecording)

      default:
        result(FlutterMethodNotImplemented)
      }
    }

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

// MARK: - AVAudioRecorder ラッパー
private final class IOSNativeRecorder: NSObject, AVAudioRecorderDelegate {
  private var audioRecorder: AVAudioRecorder?
  var isRecording: Bool { audioRecorder?.isRecording ?? false }

  func startRecording(toPath path: String) throws {
    let session = AVAudioSession.sharedInstance()
    try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
    try session.setActive(true)

    let url = URL(fileURLWithPath: path)
    try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true, attributes: nil)

    // WAV (LPCM) 44.1kHz mono
    let settings: [String: Any] = [
      AVFormatIDKey: kAudioFormatLinearPCM,
      AVSampleRateKey: 44100,
      AVNumberOfChannelsKey: 1,
      AVLinearPCMBitDepthKey: 16,
      AVLinearPCMIsFloatKey: false,
      AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
    ]

    audioRecorder = try AVAudioRecorder(url: url, settings: settings)
    audioRecorder?.delegate = self
    audioRecorder?.prepareToRecord()
    audioRecorder?.record()
  }

  func stopRecording() {
    audioRecorder?.stop()
    audioRecorder = nil
    try? AVAudioSession.sharedInstance().setActive(false)
  }
}
