import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../data/water_index_service.dart';
import '../../data/models/water_index_config.dart';

class WaterHistoryChart extends ConsumerStatefulWidget {
  final String homeId;
  final String bedId;
  final double wateringThreshold;

  const WaterHistoryChart({
    super.key,
    required this.homeId,
    required this.bedId,
    required this.wateringThreshold,
  });

  @override
  ConsumerState<WaterHistoryChart> createState() => _WaterHistoryChartState();
}

class _WaterHistoryChartState extends ConsumerState<WaterHistoryChart> {
  late Future<List<DailyWaterStatus>> _historyFuture;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() {
    final now = DateTime.now();
    final configAsync = ref.read(waterIndexConfigProvider);
    final config = configAsync.value ?? const WaterIndexConfig();
    final startDate = config.getTrackingStart(now);
    
    _historyFuture = ref.read(waterIndexServiceProvider).getHistoricalDeficit(
      widget.homeId,
      widget.bedId,
      startDate,
      now,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Listen for changes in watering logs to update the chart automatically
    ref.listen(
      bedWateringLogsProvider((homeId: widget.homeId, bedId: widget.bedId)),
      (previous, next) {
        _loadHistory();
        setState(() {});
      },
    );

    final configAsync = ref.watch(waterIndexConfigProvider);
    final config = configAsync.value ?? const WaterIndexConfig();
    final maxCapacity = config.maxDeficit;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      height: 375,
      child: FutureBuilder<List<DailyWaterStatus>>(
        future: _historyFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (snapshot.hasError) {
            return Center(child: Text('Fejl: ${snapshot.error}'));
          }

          final data = snapshot.data ?? [];
          if (data.isEmpty) {
            return const Center(child: Text('Ingen data tilgængelig'));
          }

          // Calculate width based on number of data points to allow scrolling
          final double chartWidth = data.length * 40.0;
          final double minWidth = MediaQuery.of(context).size.width - (AppSpacing.md * 2);
          
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            reverse: true, // Start at the end (today)
            child: Container(
              width: chartWidth < minWidth ? minWidth : chartWidth,
              padding: const EdgeInsets.only(right: 16), // Padding at the end
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: true,
                    verticalInterval: 1, // Draw grid line for every day
                    horizontalInterval: 10,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade200,
                        strokeWidth: 1,
                      );
                    },
                    getDrawingVerticalLine: (value) {
                      return FlLine(
                        color: Colors.grey.shade100,
                        strokeWidth: 1,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1, 
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index >= 0 && index < data.length) {
                            if (index % 2 == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  DateFormat('d/M').format(data[index].date),
                                  style: const TextStyle(
                                    color: Color(0xff68737d),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 10,
                                  ),
                                ),
                              );
                            }
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 10,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            value.toInt().toString(),
                            style: const TextStyle(
                              color: Color(0xff68737d),
                              fontWeight: FontWeight.bold,
                              fontSize: 10,
                            ),
                            textAlign: TextAlign.left,
                          );
                        },
                        reservedSize: 28,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: true,
                    border: Border.all(color: const Color(0xff37434d).withOpacity(0.1)),
                  ),
                  minX: 0,
                  maxX: (data.length - 1).toDouble(),
                  minY: 0,
                  maxY: maxCapacity + 10, // Add some headroom
                  lineBarsData: [
                    LineChartBarData(
                      spots: data.asMap().entries.map((e) {
                        final available = maxCapacity - e.value.deficit;
                        return FlSpot(e.key.toDouble(), available);
                      }).toList(),
                      isCurved: true,
                      color: AppColors.accentBlue,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppColors.accentBlue.withOpacity(0.1),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((LineBarSpot touchedSpot) {
                          final index = touchedSpot.x.toInt();
                          if (index >= 0 && index < data.length) {
                            final status = data[index];
                            final available = maxCapacity - status.deficit;
                            return LineTooltipItem(
                              '${DateFormat('d/M').format(status.date)}\n',
                              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                              children: [
                                TextSpan(
                                  text: 'Vandstand: ${available.toStringAsFixed(1)} mm\n',
                                  style: const TextStyle(color: Colors.lightBlueAccent),
                                ),
                                if (status.rainfall > 0)
                                  TextSpan(
                                    text: 'Regn: ${status.rainfall.toStringAsFixed(1)} mm\n',
                                    style: const TextStyle(color: Colors.lightBlueAccent),
                                  ),
                                if (status.watering > 0)
                                  TextSpan(
                                    text: 'Vanding: ${status.watering.toStringAsFixed(1)} mm',
                                    style: const TextStyle(color: Colors.greenAccent),
                                  ),
                              ],
                            );
                          }
                          return null;
                        }).toList();
                      },
                    ),
                  ),
                  extraLinesData: ExtraLinesData(
                    horizontalLines: [
                      HorizontalLine(
                        y: maxCapacity,
                        color: Colors.green.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.bottomRight,
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          style: TextStyle(color: Colors.green.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                          labelResolver: (line) => 'Max kapacitet',
                        ),
                      ),
                      HorizontalLine(
                        y: maxCapacity - widget.wateringThreshold,
                        color: Colors.orange.withOpacity(0.5),
                        strokeWidth: 1,
                        dashArray: [5, 5],
                        label: HorizontalLineLabel(
                          show: true,
                          alignment: Alignment.topRight,
                          padding: const EdgeInsets.only(right: 5, bottom: 5),
                          style: TextStyle(color: Colors.orange.withOpacity(0.8), fontSize: 10, fontWeight: FontWeight.bold),
                          labelResolver: (line) => 'Vandingsgrænse',
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
