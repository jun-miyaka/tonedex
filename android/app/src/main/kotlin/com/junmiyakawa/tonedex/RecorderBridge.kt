package com.junmiyakawa.tonedex

import android.content.Context
import android.media.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileOutputStream
import java.io.IOException
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.concurrent.thread
import kotlin.math.max

object RecorderBridge {
    private var audioRecord: AudioRecord? = null
    @Volatile private var isRecording = false
    private var recordingThread: Thread? = null
    private var outputFilePath: String? = null
    private var bytesWritten: Int = 0

    // 録音パラメータ（audio_analysis と整合）
    private const val SAMPLE_RATE = 44100
    private const val CHANNEL_CONFIG = AudioFormat.CHANNEL_IN_MONO
    private const val AUDIO_FORMAT  = AudioFormat.ENCODING_PCM_16BIT
    private const val BYTES_PER_SAMPLE = 2

    fun startRecording(call: MethodCall, result: MethodChannel.Result, context: Context) {
        try {
            val path = call.argument<String>("path")
            if (path.isNullOrEmpty()) {
                result.error("INVALID_PATH", "Path is null or empty", null)
                return
            }
            // 推奨: .wav 拡張子
            if (!path.lowercase().endsWith(".wav")) {
                result.error("INVALID_EXT", "Please provide a .wav file path", null)
                return
            }
            outputFilePath = path
            bytesWritten = 0

            // 1) AudioSource: UNPROCESSED 優先（なければ MIC）
            val src = if (android.os.Build.VERSION.SDK_INT >= 24) {
                MediaRecorder.AudioSource.UNPROCESSED
            } else {
                MediaRecorder.AudioSource.MIC
            }

            val minBuf = AudioRecord.getMinBufferSize(SAMPLE_RATE, CHANNEL_CONFIG, AUDIO_FORMAT)
            val bufferSize = max(minBuf, SAMPLE_RATE / 5) // 0.2秒分くらい

            val recorder = AudioRecord.Builder()
                .setAudioSource(src)
                .setAudioFormat(
                    AudioFormat.Builder()
                        .setSampleRate(SAMPLE_RATE)
                        .setChannelMask(CHANNEL_CONFIG)
                        .setEncoding(AUDIO_FORMAT)
                        .build()
                )
                .setBufferSizeInBytes(bufferSize)
                .build()

            // 2) 可能なら AGC/NS/AEC を明示的に OFF
            val sessionId = recorder.audioSessionId
            if (android.media.audiofx.AutomaticGainControl.isAvailable()) {
                android.media.audiofx.AutomaticGainControl.create(sessionId)?.enabled = false
            }
            if (android.media.audiofx.NoiseSuppressor.isAvailable()) {
                android.media.audiofx.NoiseSuppressor.create(sessionId)?.enabled = false
            }
            if (android.media.audiofx.AcousticEchoCanceler.isAvailable()) {
                android.media.audiofx.AcousticEchoCanceler.create(sessionId)?.enabled = false
            }

            // 3) WAVファイルを開き、先にダミーヘッダを書いておく
            val outFile = File(outputFilePath!!)
            outFile.parentFile?.mkdirs()
            val fos = FileOutputStream(outFile)
            writeWavHeader(fos, SAMPLE_RATE, 1, BYTES_PER_SAMPLE) // 1ch, 16bit

            // 4) 録音開始 → バッファをそのまま書出し（リニアPCM little-endian）
            recorder.startRecording()
            audioRecord = recorder
            isRecording = true

            recordingThread = thread(start = true, name = "wav-writer") {
                val buf = ByteArray(bufferSize)
                fos.use { stream ->
                    while (isRecording) {
                        val read = recorder.read(buf, 0, buf.size)
                        if (read > 0) {
                            stream.write(buf, 0, read)
                            bytesWritten += read
                        }
                    }
                    // 終了時にWAVヘッダを更新（dataサイズ/ファイルサイズ）
                    updateWavHeader(outFile, SAMPLE_RATE, 1, BYTES_PER_SAMPLE, bytesWritten)
                }
            }

            result.success("Recording started")
        } catch (e: Exception) {
            stopInternal()
            result.error("RECORDER_ERROR", "Failed to start recording: ${e.message}", null)
        }
    }

    fun stopRecording(result: MethodChannel.Result) {
        try {
            stopInternal()
            result.success(outputFilePath)
        } catch (e: Exception) {
            result.error("STOP_ERROR", "Failed to stop recording: ${e.message}", null)
        }
    }

    private fun stopInternal() {
        isRecording = false
        try { recordingThread?.join(300) } catch (_: Throwable) {}
        recordingThread = null
        audioRecord?.apply {
            try { stop() } catch (_: Throwable) {}
            try { release() } catch (_: Throwable) {}
        }
        audioRecord = null
    }

    // ---- WAV utils ----
    private fun writeWavHeader(out: FileOutputStream, sampleRate: Int, channels: Int, bytesPerSample: Int) {
        // 44-byte header with placeholder sizes
        val byteRate = sampleRate * channels * bytesPerSample
        val header = ByteBuffer.allocate(44).order(ByteOrder.LITTLE_ENDIAN)
        header.put("RIFF".toByteArray(Charsets.US_ASCII))
        header.putInt(36)                         // placeholder for file size - 8
        header.put("WAVE".toByteArray(Charsets.US_ASCII))
        header.put("fmt ".toByteArray(Charsets.US_ASCII))
        header.putInt(16)                         // PCM
        header.putShort(1)                        // audio format = 1 (PCM)
        header.putShort(channels.toShort())
        header.putInt(sampleRate)
        header.putInt(byteRate)
        header.putShort((channels * bytesPerSample).toShort()) // block align
        header.putShort((bytesPerSample * 8).toShort())        // bits per sample
        header.put("data".toByteArray(Charsets.US_ASCII))
        header.putInt(0)                          // placeholder for data size
        out.write(header.array())
    }

    private fun updateWavHeader(file: File, sampleRate: Int, channels: Int, bytesPerSample: Int, dataBytes: Int) {
        val raf = java.io.RandomAccessFile(file, "rw")
        raf.use {
            val fileSizeMinus8 = 36 + dataBytes
            it.seek(4)
            it.write(intToLeBytes(fileSizeMinus8))
            it.seek(40)
            it.write(intToLeBytes(dataBytes))
        }
    }

    private fun intToLeBytes(v: Int): ByteArray {
        return byteArrayOf(
            (v and 0xFF).toByte(),
            ((v shr 8) and 0xFF).toByte(),
            ((v shr 16) and 0xFF).toByte(),
            ((v shr 24) and 0xFF).toByte()
        )
    }
}

