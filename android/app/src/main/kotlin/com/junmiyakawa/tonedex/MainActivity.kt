package com.junmiyakawa.tonedex

import android.content.Context
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "native_recorder")
            .setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
                try {
                    when (call.method) {
                        "startRecording" -> {
                            RecorderBridge.startRecording(call, result, applicationContext)
                        }
                        "stopRecording" -> {
                            RecorderBridge.stopRecording(result)
                        }
                        else -> {
                            result.notImplemented()
                        }
                    }
                } catch (e: Exception) {
                    result.error("RECORDER_BRIDGE_ERROR", e.message, null)
                }
            }
    }
}