package com.junmiyakawa.tonedex

import android.content.Context
import android.media.MediaRecorder
import android.os.Environment
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.IOException

object RecorderBridge {
    private var mediaRecorder: MediaRecorder? = null
    private var outputFile: String? = null

    fun startRecording(call: MethodCall, result: MethodChannel.Result, context: Context) {
        try {
            val path = call.argument<String>("path")
            if (path == null) {
                result.error("INVALID_PATH", "Path is null", null)
                return
            }

            outputFile = path

            mediaRecorder = MediaRecorder().apply {
                setAudioSource(MediaRecorder.AudioSource.MIC)
                setOutputFormat(MediaRecorder.OutputFormat.THREE_GPP)
                setAudioEncoder(MediaRecorder.AudioEncoder.AMR_NB)
                setOutputFile(outputFile)
                prepare()
                start()
            }

            result.success("Recording started")

        } catch (e: IOException) {
            result.error("IO_ERROR", "Failed to start recording: ${e.message}", null)
        } catch (e: Exception) {
            result.error("RECORDER_ERROR", "Unexpected error: ${e.message}", null)
        }
    }

    fun stopRecording(result: MethodChannel.Result) {
        try {
            mediaRecorder?.apply {
                stop()
                release()
            }
            mediaRecorder = null
            result.success(outputFile)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop recording: ${e.message}", null)
        }
    }
} 
