import 'dart:typed_data';
import 'dart:convert';

class WavReader {
  final Uint8List bytes;
  int sampleRate = 44100;

  WavReader(this.bytes) {
    _parseHeader();
  }

  void _parseHeader() {
    final header = utf8.decode(bytes.sublist(0, 4));
    if (header != 'RIFF') throw FormatException('Not a valid WAV file');
    sampleRate = bytes.buffer.asByteData().getUint32(24, Endian.little);
  }

  List<double> readSamples() {
    final dataStart = _findDataChunkIndex();
    final bytePerSample = 2;
    final samples = <double>[];

    for (int i = dataStart; i + 1 < bytes.length; i += bytePerSample) {
      final sample = bytes.buffer.asByteData().getInt16(i, Endian.little);
      samples.add(sample.toDouble());
    }

    return samples;
  }

  int _findDataChunkIndex() {
    for (int i = 0; i < bytes.length - 4; i++) {
      if (bytes[i] == 0x64 &&
          bytes[i + 1] == 0x61 &&
          bytes[i + 2] == 0x74 &&
          bytes[i + 3] == 0x61) {
        return i + 8; // 'data'の後にサイズ4バイトあるため
      }
    }
    throw FormatException('data chunk not found');
  }
}
