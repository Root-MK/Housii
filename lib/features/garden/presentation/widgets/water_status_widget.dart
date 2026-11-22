import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../data/water_index_service.dart';
import '../../data/models/water_index_config.dart';

/// Widget showing the water status of a garden bed.
/// Displays deficit level with color coding and recommendation.
class WaterStatusWidget extends StatelessWidget {
  final BedWaterStatus status;
  final WaterIndexConfig config;
  final WaterIndexService service;
  final double bedWidthCm;
  final double bedHeightCm;
  final bool compact;

  const WaterStatusWidget({
    super.key,
    required this.status,
    required this.config,
    required this.service,
    required this.bedWidthCm,
    required this.bedHeightCm,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!status.isSeasonActive) {
      return _buildInactiveView(context);
    }

    final maxCapacity = status.maxCapacity;
    final available = status.availableWater;
    final percentage = (available / maxCapacity); // Allow > 1.0 for surplus logic

    // Color based on water level (High is good)
    final color = _getStatusColor(percentage);
    final statusText = _getStatusText(percentage);
    final icon = _getStatusIcon(percentage);

    // Check for flood risk first
    // if (status.floodRisk != FloodRisk.none) {
    //   return _buildFloodWarning(context, status);
    // }

    if (compact) {
      return _buildCompactView(context, color, icon, available);
    }

    return _buildFullView(context, color, icon, available, maxCapacity, statusText, percentage);
  }

  Widget _buildSmallFloodWarning(BuildContext context) {
    final color = _getFloodColor(status.floodRisk);
    final icon = _getFloodIcon(status.floodRisk);
    final title = _getFloodTitle(status.floodRisk);
    final surplus = (status.availableWater - status.maxCapacity).clamp(0.0, double.infinity);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: color, 
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                if (surplus > 0)
                  Text(
                    '${surplus.toStringAsFixed(0)} mm overskud',
                    style: TextStyle(
                      color: color,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getFloodColor(FloodRisk risk) {
    switch (risk) {
      case FloodRisk.warning:
        return Colors.amber; // Gul
      case FloodRisk.danger:
        return Colors.orange; // Orange
      case FloodRisk.critical:
        return Colors.red; // Rød
      case FloodRisk.none:
        return Colors.transparent;
    }
  }

  IconData _getFloodIcon(FloodRisk risk) {
    switch (risk) {
      case FloodRisk.warning:
        return Icons.warning_amber_rounded;
      case FloodRisk.danger:
        return Icons.thunderstorm;
      case FloodRisk.critical:
        return Icons.flood; // or dangerous
      case FloodRisk.none:
        return Icons.check;
    }
  }

  String _getFloodTitle(FloodRisk risk) {
    switch (risk) {
      case FloodRisk.warning:
        return 'Risiko for overvanding';
      case FloodRisk.danger:
        return 'Fare for oversvømmelse';
      case FloodRisk.critical:
        return 'KRITISK VANDSTAND';
      case FloodRisk.none:
        return '';
    }
  }

  Widget _buildInactiveView(BuildContext context) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.schedule, size: 14, color: Colors.grey),
            SizedBox(width: 4),
            Text('Off-season', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sæson ikke aktiv',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                ),
                Text(
                  'Sporing aktiv fra 1. april til 30. september',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactView(
    BuildContext context,
    Color color,
    IconData icon,
    double available,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${available.toStringAsFixed(0)} mm',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullView(
    BuildContext context,
    Color color,
    IconData icon,
    double available,
    double maxCapacity,
    String statusText,
    double percentage,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (status.floodRisk != FloodRisk.none)
            _buildSmallFloodWarning(context),
            
          Row(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      'Vandbeholdning: ${available.toStringAsFixed(1)} / ${maxCapacity.toStringAsFixed(0)} mm',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey.shade700,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tom (0%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
              ),
              Text(
                'Fuld (100%)',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                      fontSize: 10,
                    ),
              ),
            ],
          ),
          if (percentage < 0.6) ...[ // Show recommendation if below 60%
            const SizedBox(height: 8),
            _buildRecommendation(context),
          ],
        ],
      ),
    );
  }

  Widget _buildRecommendation(BuildContext context) {
    final areaM2 = (bedWidthCm / 100) * (bedHeightCm / 100);
    // Target is 90% capacity
    final targetLevel = status.maxCapacity * 0.9;
    final neededMm = targetLevel - status.availableWater;
    
    if (neededMm <= 0) return const SizedBox.shrink();

    final neededLiters = neededMm * areaM2;

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.tips_and_updates, color: Colors.orange, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tilføj ${neededMm.toStringAsFixed(0)} mm (${neededLiters.toStringAsFixed(1)} L) for at fylde op',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(double percentage) {
    if (percentage > 1.0) {
      return Colors.purple; // > 100% is Oversaturated
    } else if (percentage > 0.8) {
      return Colors.teal; // 80-100% is Very Moist
    } else if (percentage > 0.6) {
      return Colors.green; // 60-80% is Optimal
    } else if (percentage > 0.3) {
      return Colors.orange; // 30-60% is Moderate
    } else {
      return Colors.red; // < 30% is Critical
    }
  }

  String _getStatusText(double percentage) {
    if (percentage > 1.0) {
      return 'Overmættet (Overskud)';
    } else if (percentage > 0.8) {
      return 'Meget fugtig';
    } else if (percentage > 0.6) {
      return 'Optimal vandbeholdning';
    } else if (percentage > 0.3) {
      return 'Moderat (Vand snart)';
    } else {
      return 'Kritisk lav vandstand';
    }
  }

  IconData _getStatusIcon(double percentage) {
    if (percentage > 1.0) {
      return Icons.waves;
    } else if (percentage > 0.8) {
      return Icons.water;
    } else if (percentage > 0.6) {
      return Icons.water_drop;
    } else if (percentage > 0.3) {
      return Icons.water_drop_outlined;
    } else {
      return Icons.warning_amber;
    }
  }
}

/// Small badge-style water indicator for lists
class WaterStatusBadge extends StatelessWidget {
  final double deficitMm;
  final double thresholdMm;
  final bool isActive;

  const WaterStatusBadge({
    super.key,
    required this.deficitMm,
    required this.thresholdMm,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isActive) {
      return const SizedBox.shrink();
    }

    final percentage = (deficitMm / thresholdMm).clamp(0.0, 2.0);
    final color = _getColor(percentage);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            percentage >= 1.0 ? Icons.water_drop : Icons.water_drop_outlined,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            deficitMm.toStringAsFixed(0),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(double percentage) {
    if (percentage < 0.5) return Colors.green;
    if (percentage < 1.0) return Colors.orange;
    return Colors.red;
  }
}
