import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../providers/health_provider.dart';
import '../core/constants/app_colors.dart';

class StatisticsScreen extends StatefulWidget {
  const StatisticsScreen({super.key});

  @override
  State<StatisticsScreen> createState() => _StatisticsScreenState();
}

class _StatisticsScreenState extends State<StatisticsScreen> {
  int _selectedMetric = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('Weekly Progress'), elevation: 0),
      body: Consumer<HealthProvider>(
        builder: (context, provider, child) {
          final weeklyData = provider.weeklyData;
          final totalStats = provider.totalStats;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Statistics Cards
                const Text(
                  'Total Statistics',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Steps',
                        _formatNumber(totalStats['steps'] ?? 0),
                        Icons.directions_walk,
                        AppColors.steps,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Records',
                        '${totalStats['records'] ?? 0}',
                        Icons.article,
                        AppColors.primary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildStatCard(
                        'Total Calories',
                        _formatNumber(totalStats['calories'] ?? 0),
                        Icons.local_fire_department,
                        AppColors.calories,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildStatCard(
                        'Total Water',
                        '${_formatNumber(totalStats['water'] ?? 0)}ml',
                        Icons.water_drop,
                        AppColors.water,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Weekly Chart
                const Text(
                  '7-Day Trend',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),

                // Metric Selector
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildMetricButton(
                          'Steps',
                          0,
                          Icons.directions_walk,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricButton(
                          'Calories',
                          1,
                          Icons.local_fire_department,
                        ),
                      ),
                      Expanded(
                        child: _buildMetricButton('Water', 2, Icons.water_drop),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Chart Container
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _getMetricTitle(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: _getMetricColor().withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              _getMetricUnit(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getMetricColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        height: 200,
                        child: weeklyData.isEmpty
                            ? _buildEmptyChart()
                            : _buildChart(weeklyData),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Average Card
                if (weeklyData.isNotEmpty) _buildAverageCard(weeklyData),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricButton(String label, int index, IconData icon) {
    final isSelected = _selectedMetric == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMetric = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChart(List<Map<String, dynamic>> data) {
    final spots = _getChartSpots(data);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: _getInterval(),
          getDrawingHorizontalLine: (value) {
            return FlLine(color: Colors.grey.shade200, strokeWidth: 1);
          },
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return Text(
                  _formatYAxis(value.toInt()),
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.textSecondary,
                  ),
                );
              },
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                if (value.toInt() >= 0 && value.toInt() < data.length) {
                  final date = DateTime.parse(data[value.toInt()]['date']);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      DateFormat('E').format(date).substring(0, 1),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  );
                }
                return const Text('');
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: _getMetricColor(),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                return FlDotCirclePainter(
                  radius: 4,
                  color: Colors.white,
                  strokeWidth: 2,
                  strokeColor: _getMetricColor(),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              color: _getMetricColor().withValues(alpha: .1),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final date = DateTime.parse(data[spot.x.toInt()]['date']);
                return LineTooltipItem(
                  '${DateFormat('MMM dd').format(date)}\n${spot.y.toInt()} ${_getMetricUnit()}',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.show_chart, size: 60, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
          ),
          const SizedBox(height: 8),
          Text(
            'Add records to see your progress',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade400),
          ),
        ],
      ),
    );
  }

  Widget _buildAverageCard(List<Map<String, dynamic>> data) {
    final average = _calculateAverage(data);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_getMetricColor(), _getMetricColor().withValues(alpha: .7)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _getMetricColor().withValues(alpha: .3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: .2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.trending_up, color: Colors.white, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '7-Day Average',
                  style: TextStyle(fontSize: 14, color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '${average.toInt()} ${_getMetricUnit()}',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<FlSpot> _getChartSpots(List<Map<String, dynamic>> data) {
    return List.generate(data.length, (index) {
      final value = _getMetricValue(data[index]);
      return FlSpot(index.toDouble(), value.toDouble());
    });
  }

  int _getMetricValue(Map<String, dynamic> data) {
    switch (_selectedMetric) {
      case 0:
        return data['steps'] ?? 0;
      case 1:
        return data['calories'] ?? 0;
      case 2:
        return data['water'] ?? 0;
      default:
        return 0;
    }
  }

  Color _getMetricColor() {
    switch (_selectedMetric) {
      case 0:
        return AppColors.steps;
      case 1:
        return AppColors.calories;
      case 2:
        return AppColors.water;
      default:
        return AppColors.primary;
    }
  }

  String _getMetricTitle() {
    switch (_selectedMetric) {
      case 0:
        return 'Steps Progress';
      case 1:
        return 'Calories Burned';
      case 2:
        return 'Water Intake';
      default:
        return '';
    }
  }

  String _getMetricUnit() {
    switch (_selectedMetric) {
      case 0:
        return 'steps';
      case 1:
        return 'kcal';
      case 2:
        return 'ml';
      default:
        return '';
    }
  }

  double _getInterval() {
    switch (_selectedMetric) {
      case 0:
        return 2000;
      case 1:
        return 500;
      case 2:
        return 500;
      default:
        return 1000;
    }
  }

  String _formatYAxis(int value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toString();
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }

  double _calculateAverage(List<Map<String, dynamic>> data) {
    if (data.isEmpty) return 0;
    final sum = data.fold<int>(0, (sum, item) => sum + _getMetricValue(item));
    return sum / data.length;
  }
}
