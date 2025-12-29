// lib/tuner_page.dart
// Tuner画面全体（3つのパネルを縦に並べる）

import 'package:flutter/material.dart';

import 'tuner_models.dart';
import 'tuner_widgets.dart';

class TunerPage extends StatefulWidget {
  final bool isActive;

  const TunerPage({super.key, required this.isActive});

  @override
  State<TunerPage> createState() => _TunerPageState();
}

class _TunerPageState extends State<TunerPage> {
  TunerResult? _lastResult;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tuner')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // リアルタイムチューナー
            RealTimeTunerPanel(isActive: widget.isActive),
            const SizedBox(height: 24),

            // ピッチチェック（結果表示もこのカードの中で完結）
            PitchCheckControlPanel(
              onResult: (result) {
                setState(() {
                  _lastResult = result;
                });
              },
            ),

            // ↓ ここには「計測結果」カードを追加しない
            // 以前のダミー結果パネルを使っていた行は削除 or コメントアウトでOK
          ],
        ),
      ),
    );
  }
}
