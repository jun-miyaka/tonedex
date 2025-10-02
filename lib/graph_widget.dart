import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' as math;

class GraphWidget extends StatelessWidget {
  final List<List<double>> zScores;
  final List<String> labels;
  final List<String> titles;
  final List<String> explanations; // ← ✅ これが足りない！
  // ★ 追加：各グラフを個別に撮るためのキー（任意）
  final List<GlobalKey>? perChartKeys;

  // ★ 追加：モードごとのY軸レンジ（省略時はZ想定の -2..2）
  final List<double>? minYs;
  final List<double>? maxYs;

  // ★ 追加：モード依存の挙動をbool配列で受ける
  final List<bool>? showLeftAxisLabels; // 指標ごとに左軸の数字を出すか
  final List<bool>? zeroOneOnly; // 指標ごとに 0/1 だけ表示するか

  const GraphWidget({
    super.key,
    required this.zScores,
    required this.labels,
    required this.titles,
    required this.explanations, // Changed from Map<String, String> to List<String> // ✅ これが必要
    this.perChartKeys, // ★ 追加
    this.minYs, // ★ 追加
    this.maxYs, // ★ 追加
    // ★ 追加
    this.showLeftAxisLabels,
    this.zeroOneOnly,
  });

  double _niceCeil(double v) {
    if (!v.isFinite || v <= 0) return 1.0;
    final log10 = math.log(v) / math.ln10;
    final base = math.pow(10.0, log10.floorToDouble()).toDouble();
    final n = v / base; // [1,10)
    double step;
    if (n <= 1.0) {
      step = 1.0;
    } else if (n <= 2.0)
      step = 2.0;
    else if (n <= 5.0)
      step = 5.0;
    else
      step = 10.0;
    return step * base;
  }

  double _niceIntervalForSpan(double span) {
    // 目標を「4分割」くらいにして、きれいに丸める
    final target = span / 4.0;
    // Calibrated の 0..1 の場合は 0.2 くらいが見やすい
    if (span <= 1.0001) return 0.2;
    return _niceCeil(target);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(zScores.length, (paramIndex) {
          // ★ 各チャートのYレンジと刻み計算（既存）
          final minYv = (minYs != null && minYs!.length > paramIndex)
              ? minYs![paramIndex]
              : -2.0;
          final maxYv = (maxYs != null && maxYs!.length > paramIndex)
              ? maxYs![paramIndex]
              : 2.0;
          final span = (maxYv - minYv).abs();
          final interval = _niceIntervalForSpan(span);

          final values = safeZ(zScores, paramIndex, labels.length);

          // ★ 追加：このチャート（paramIndex）の表示ルール（DisplayModeを使わない）
          final bool showLabels =
              (showLeftAxisLabels != null &&
                  showLeftAxisLabels!.length > paramIndex)
              ? showLeftAxisLabels![paramIndex]
              : true;

          final bool only01 =
              (zeroOneOnly != null && zeroOneOnly!.length > paramIndex)
              ? zeroOneOnly![paramIndex]
              : false;

          // ★★★ ここに“差し込み” ★★★
          // Zレンジ（-2..2）や 0/1 表示のときは刻みを 1 に固定
          final bool isZRange = (minYv == -2.0 && maxYv == 2.0);
          final double leftAxisInterval = (only01 || isZRange) ? 1.0 : interval;
          final double gridAxisInterval = (only01 || isZRange) ? 1.0 : interval;
          // ★★★ ここまで差し込み ★★★

          return RepaintBoundary(
            key: (perChartKeys != null && perChartKeys!.length > paramIndex)
                ? perChartKeys![paramIndex]
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titles[paramIndex],
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  explanations[paramIndex],
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 200,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: BarChart(
                          BarChartData(
                            backgroundColor: Colors.transparent,
                            minY: minYv,
                            maxY: maxYv,

                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black54,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) =>
                                        BarTooltipItem(
                                          rod.toY.toStringAsFixed(2),
                                          const TextStyle(
                                            fontSize: 10,
                                            color: Colors.white,
                                          ),
                                        ),
                              ),
                            ),

                            // 横線制御：0/1は 0,0.5,1 ／ Zは整数のみ
                            gridData: FlGridData(
                              show: true, // 念のため明示
                              drawHorizontalLine: true,
                              drawVerticalLine: false, // 仕様：縦グリッドなし
                              // ★ 横線の刻みをモード別に切り替え（checkToShowHorizontalLineは使わない）
                              horizontalInterval: (minYv == -2 && maxYv == 2)
                                  ? 1.0 // Z-score：-2..+2 で整数線
                                  : (((zeroOneOnly?[paramIndex] ?? false) &&
                                            minYv == 0 &&
                                            maxYv == 1)
                                        ? 0.5 // 0–1レンジ(only01)：0, 0.5, 1 を出す
                                        : (gridAxisInterval > 0
                                              ? gridAxisInterval
                                              : 1.0)), // フォールバック
                              // ★ 0.5 の線だけ少し強調（RawのBRT・CalのRMS/CTR/BW/BRT）
                              getDrawingHorizontalLine: (v) {
                                final bool isMid =
                                    ((zeroOneOnly?[paramIndex] ?? false) &&
                                    minYv == 0 &&
                                    maxYv == 1 &&
                                    (v - 0.5).abs() < 1e-6);
                                return FlLine(
                                  color: isMid
                                      ? Colors.black38
                                      : Colors.black26,
                                  strokeWidth: isMid ? 1.5 : 0.8,
                                  dashArray: isMid
                                      ? <int>[4, 4]
                                      : null, // fl_chart は List<int>
                                );
                              },
                            ),

                            borderData: FlBorderData(
                              show: true,
                              border: const Border(
                                left: BorderSide(color: Colors.black, width: 1),
                                bottom: BorderSide(
                                  color: Colors.black,
                                  width: 1,
                                ),
                              ),
                            ),
                            titlesData: FlTitlesData(
                              leftTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: showLabels,
                                  interval: leftAxisInterval, // 0/1やZでは1刻み
                                  reservedSize: 36,
                                  getTitlesWidget: (value, meta) {
                                    if (!showLabels) {
                                      return const SizedBox.shrink();
                                    }
                                    if (only01) {
                                      final iv = value.round();
                                      if (iv == 0 || iv == 1) {
                                        return Text(
                                          '$iv',
                                          style: const TextStyle(fontSize: 10),
                                        );
                                      }
                                      return const SizedBox.shrink();
                                    }
                                    return Text(
                                      value.toStringAsFixed(0),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  },
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
                                    if (index < 0 || index >= labels.length) {
                                      return const SizedBox.shrink();
                                    }
                                    return SideTitleWidget(
                                      axisSide: meta.axisSide,
                                      space: 8,
                                      child: Transform.rotate(
                                        angle: -0.5,
                                        child: Text(
                                          labels[index],
                                          style: const TextStyle(fontSize: 10),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(labels.length, (i) {
                              return BarChartGroupData(
                                x: i,
                                barRods: [
                                  BarChartRodData(
                                    toY: values[i],
                                    width: 16,
                                    borderRadius: BorderRadius.circular(4),
                                    color: Colors.blueAccent,
                                  ),
                                ],
                                showingTooltipIndicators: const [0],
                              );
                            }),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ✅ 重複定義を回避して safeZ を1か所だけ残す
  List<double> safeZ(
    List<List<double>> zScores,
    int paramIndex,
    int expectedLength,
  ) {
    if (paramIndex >= zScores.length) return List.filled(expectedLength, 0.0);
    final target = zScores[paramIndex];
    return List.generate(
      expectedLength,
      (i) => i < target.length ? target[i] : 0.0,
    );
  }
}
