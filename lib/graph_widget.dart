import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class GraphWidget extends StatelessWidget {
  final List<List<double>> zScores;
  final List<String> labels;
  final List<String> titles;
  final List<String> explanations; // ← ✅ これが足りない！

  const GraphWidget({
    super.key,
    required this.zScores,
    required this.labels,
    required this.titles,
    required this.explanations, // Changed from Map<String, String> to List<String> // ✅ これが必要
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(zScores.length, (paramIndex) {
          final values = safeZ(zScores, paramIndex, labels.length);
          return Column(
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
                          minY: -2,
                          maxY: 2,
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
                            drawHorizontalLine: true,
                            getDrawingHorizontalLine: (_) {
                              return FlLine(color: Colors.grey, strokeWidth: 1);
                            },
                          ),
                          borderData: FlBorderData(
                            show: true,
                            border: const Border(
                              left: BorderSide(color: Colors.black, width: 1),
                              bottom: BorderSide(color: Colors.black, width: 1),
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                interval: 1,
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
