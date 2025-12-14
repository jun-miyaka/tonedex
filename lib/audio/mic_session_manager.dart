import 'dart:async';

/// マイク資源の排他制御を行うためのシンプルなマネージャー。
///
/// - MicSessionOwner.tuner    : チューナー画面（tuner_widgets.dart）
/// - MicSessionOwner.recorder : ToneDex の録音画面（main.dart）
///
/// 各オーナーは `registerOwner` で「自分のマイク停止処理」を登録し、
/// マイクを使い始める前に `acquire` を呼び出します。
/// 別オーナーがすでにマイクを握っている場合、その停止処理が呼ばれます。

enum MicSessionOwner { tuner, recorder }

class MicSessionManager {
  MicSessionManager._internal();

  static final MicSessionManager instance = MicSessionManager._internal();

  MicSessionOwner? _currentOwner;
  final Map<MicSessionOwner, FutureOr<void> Function()?> _stopCallbacks = {};

  /// 各オーナーが「自分のマイク停止処理」を登録するためのメソッド。
  /// 例：tuner 側では PitchSource.stop を渡す、recorder 側では stopRecording を渡す。
  void registerOwner(MicSessionOwner owner, FutureOr<void> Function()? onStop) {
    _stopCallbacks[owner] = onStop;
  }

  /// 指定した owner がマイクを使いたいときに呼び出す。
  /// 他の owner がマイクを保持していた場合、その stop コールバックを呼ぶ。
  Future<void> acquire(MicSessionOwner owner) async {
    if (_currentOwner == owner) {
      // すでに自分がオーナーなら何もしない
      return;
    }

    // すでに他のオーナーがマイクを利用している場合は、その停止処理を呼び出す
    if (_currentOwner != null) {
      final current = _currentOwner!;
      final stopper = _stopCallbacks[current];
      if (stopper != null) {
        await stopper();
      }
    }

    _currentOwner = owner;
  }

  /// owner が自発的にマイクを解放するときに呼ぶ。
  /// （画面の dispose 時など）
  void release(MicSessionOwner owner) {
    if (_currentOwner == owner) {
      _currentOwner = null;
    }
  }

  /// 現在どのオーナーがマイクを保持しているか（デバッグ用）。
  MicSessionOwner? get currentOwner => _currentOwner;
}
