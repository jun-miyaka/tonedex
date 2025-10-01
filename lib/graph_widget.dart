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

  const GraphWidget({
    super.key,
    required this.zScores,
    required this.labels,
    required this.titles,
    required this.explanations, // Changed from Map<String, String> to List<String> // ✅ これが必要
    this.perChartKeys, // ★ 追加
    this.minYs, // ★ 追加
    this.maxYs, // ★ 追加
  });

  double _niceCeil(double v) {
    if (!v.isFinite || v <= 0) return 1.0;
    final log10 = math.log(v) / math.ln10;
    final base = math.pow(10.0, log10.floorToDouble()).toDouble();
    final n = v / base; // [1,10)
    double step;
    if (n <= 1.0)
      step = 1.0;
    else if (n <= 2.0)
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
          // ★ 追加：このグラフ（paramIndex）のY軸レンジ＆刻みを決定
          final minYv = (minYs != null && minYs!.length > paramIndex)
              ? minYs![paramIndex]
              : -2.0;
          final maxYv = (maxYs != null && maxYs!.length > paramIndex)
              ? maxYs![paramIndex]
              : 2.0;
          final span = (maxYv - minYv).abs();
          final interval = _niceIntervalForSpan(span);
          final values = safeZ(zScores, paramIndex, labels.length);
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
                            // ← ここを差し替え
                            minY: minYv,
                            maxY: maxYv,
                            // ← ここ以下はあなたの既存設定をそのまま残す
                            barTouchData: BarTouchData(
                              enabled: true,
                              touchTooltipData: BarTouchTooltipData(
                                tooltipBgColor: Colors.black54,
                                getTooltipItem:
                                    (group, groupIndex, rod, rodIndex) {
                                      return BarTooltipItem(
                                        rod.toY.toStringAsFixed(2),
                                        const TextStyle(
                                          fontSize: 10,
                                          color: Colors.white,
                                        ),
                                      );
                                    },
                              ),
                            ),
                            gridData: FlGridData(
                              show: true,
                              horizontalInterval: interval, // ★ 追加：グリッドも同じ刻みに
                              drawHorizontalLine: true,
                              getDrawingHorizontalLine: (_) =>
                                  FlLine(color: Colors.grey, strokeWidth: 1),
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
                                  showTitles: true,
                                  interval: interval, // ★ ここを固定1から置換
                                ),
                              ),
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final index = value.toInt();
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
                              topTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                              rightTitles: AxisTitles(
                                sideTitles: SideTitles(showTitles: false),
                              ),
                            ),
                            barGroups: List.generate(labels.length, (i) {
                              final values = safeZ(
                                zScores,
                                paramIndex,
                                labels.length,
                              );
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
                                showingTooltipIndicators: [0],
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
