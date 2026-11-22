import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/providers/home_provider.dart';
import '../../data/garden_service.dart';
import '../../data/models/water_index_config.dart';
import '../../data/water_index_service.dart';
import '../../data/weather_service.dart';
import 'water_status_widget.dart';
import 'watering_form_sheet.dart';

/// Tab showing water index dashboard for all beds.
class WaterIndexTab extends ConsumerStatefulWidget {
  const WaterIndexTab({super.key});

  @override
  ConsumerState<WaterIndexTab> createState() => _WaterIndexTabState();
}

class _WaterIndexTabState extends ConsumerState<WaterIndexTab> {
  bool _isLoading = true;
  String? _error;
  List<_BedWaterData> _bedWaterData = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final homeState = ref.read(currentHomeProvider);
      final home = homeState.value;
      if (home == null) {
        setState(() {
          _isLoading = false;
          _error = 'Ingen hjem valgt';
        });
        return;
      }

      // First sync weather data
      final weatherService = ref.read(weatherServiceProvider);
      final configAsync = ref.read(waterIndexConfigProvider);
      final config = configAsync.value ?? const WaterIndexConfig();
      final now = DateTime.now();
      final startDate = config.getTrackingStart(now);

      // Sync weather in background
      await weatherService.syncWeatherData(startDate, now);

      // Load all beds
      final bedsState = await ref.read(gardenBedsProvider.future);
      final waterService = ref.read(waterIndexServiceProvider);

      final bedData = <_BedWaterData>[];
      for (final bed in bedsState) {
        try {
          final status = await waterService.calculateBedWaterStatus(
            home.id,
            bed.id,
          );
          bedData.add(_BedWaterData(
            bedId: bed.id,
            bedName: bed.name,
            bedColor: bed.color != null ? Color(bed.color!) : Colors.green,
            status: status,
            widthCm: bed.width,
            heightCm: bed.height,
          ));
        } catch (e) {
          debugPrint('Error calculating water status for bed ${bed.name}: $e');
        }
      }

      // Sort by deficit (highest first)
      bedData.sort((a, b) => b.status.deficit.compareTo(a.status.deficit));

      setState(() {
        _bedWaterData = bedData;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _error = 'Fejl ved indlæsning: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final configAsync = ref.watch(waterIndexConfigProvider);

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Henter vejrdata...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(Icons.refresh),
              label: const Text('Prøv igen'),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          // Config card
          configAsync.when(
            data: (config) => _ConfigCard(config: config, onConfigChanged: _loadData),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('Fejl ved indlæsning af konfiguration: $e'),
          ),
          const SizedBox(height: AppSpacing.md),

          // Summary card
          if (_bedWaterData.isNotEmpty) ...[
            configAsync.when(
              data: (config) => _SummaryCard(bedData: _bedWaterData, config: config),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: AppSpacing.lg),
          ],

          // Beds list
          Text(
            'Bede vandstatus',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: AppSpacing.sm),

          if (_bedWaterData.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Icon(Icons.grass, size: 48, color: Colors.grey),
                    SizedBox(height: 8),
                    Text('Ingen bede fundet'),
                    Text(
                      'Opret bede i fanen "Liste" eller "Visuel"',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
            )
          else
            ..._bedWaterData.map((data) => configAsync.when(
                  data: (config) => _BedWaterCard(
                    data: data,
                    config: config,
                    onWater: () => _openWateringSheet(data),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                )),
        ],
      ),
    );
  }

  void _openWateringSheet(_BedWaterData data) async {
    final bedsState = await ref.read(gardenBedsProvider.future);
    final bed = bedsState.firstWhere((b) => b.id == data.bedId);

    if (!mounted) return;

    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => WateringFormSheet(bed: bed),
    );

    if (result == true) {
      _loadData();
    }
  }
}

class _ConfigCard extends ConsumerWidget {
  final WaterIndexConfig config;
  final VoidCallback onConfigChanged;

  const _ConfigCard({required this.config, required this.onConfigChanged});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Indstillinger',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ],
            ),
            const Divider(),
            // Dev mode toggle
            SwitchListTile(
              title: const Text('Udviklertilstand'),
              subtitle: Text(
                config.devMode
                    ? 'Sporing aktiv hele året'
                    : 'Kun april-september',
                style: const TextStyle(fontSize: 12),
              ),
              value: config.devMode,
              dense: true,
              onChanged: (value) {
                ref.read(waterIndexConfigControllerProvider.notifier).setDevMode(value, config);
                onConfigChanged();
              },
            ),
            // Soil type
            ListTile(
              title: const Text('Jordtype'),
              subtitle: Text(config.soilType.displayName),
              trailing: const Icon(Icons.chevron_right),
              dense: true,
              onTap: () => _showSoilTypeDialog(context, ref),
            ),
            // Formula info
            ExpansionTile(
              title: const Text('Formeldetaljer'),
              dense: true,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Evapotranspiration (ET):',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      Text(
                        'ET = ${config.etCoefficient} × (Tavg + 10) × (sol / ${config.etDivisor.toInt()})',
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vandings-tærskel: ${config.wateringThreshold.toStringAsFixed(0)} mm',
                        style: const TextStyle(fontSize: 12),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        config.soilType.description,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSoilTypeDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Vælg jordtype'),
        children: SoilType.values.map((soil) {
          return RadioListTile<SoilType>(
            title: Text(soil.displayName),
            subtitle: Text(
              'Tærskel: ${soil.wateringThreshold.toStringAsFixed(0)} mm',
              style: const TextStyle(fontSize: 12),
            ),
            value: soil,
            groupValue: config.soilType,
            onChanged: (value) {
              if (value != null) {
                ref.read(waterIndexConfigControllerProvider.notifier).setSoilType(value, config);
                Navigator.pop(context);
                onConfigChanged();
              }
            },
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final List<_BedWaterData> bedData;
  final WaterIndexConfig config;

  const _SummaryCard({required this.bedData, required this.config});

  @override
  Widget build(BuildContext context) {
    final totalCapacity = bedData.fold<double>(0, (sum, d) => sum + d.status.maxCapacity);
    final totalAvailable = bedData.fold<double>(0, (sum, d) => sum + d.status.availableWater);
    final avgRatio = totalCapacity > 0 ? (totalAvailable / totalCapacity) * 100 : 0.0;
    
    final needsWater = bedData
        .where((d) => d.status.availableWater < d.status.maxCapacity * 0.4) // Warning threshold
        .length;

    return Card(
      color: needsWater > 0 ? Colors.orange.shade50 : Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _StatColumn(
                  icon: Icons.grass,
                  label: 'Bede',
                  value: bedData.length.toString(),
                  color: Colors.green,
                ),
                _StatColumn(
                  icon: Icons.water_drop,
                  label: 'Gns. vandstand',
                  value: '${avgRatio.toStringAsFixed(0)}%',
                  color: Colors.blue,
                ),
                _StatColumn(
                  icon: Icons.warning_amber,
                  label: 'Skal vandes',
                  value: needsWater.toString(),
                  color: needsWater > 0 ? Colors.orange : Colors.grey,
                ),
              ],
            ),
            if (needsWater > 0) ...[
              const Divider(),
              Text(
                '$needsWater bed${needsWater == 1 ? '' : 'e'} har brug for vand',
                style: TextStyle(
                  color: Colors.orange.shade800,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatColumn({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _BedWaterCard extends ConsumerWidget {
  final _BedWaterData data;
  final WaterIndexConfig config;
  final VoidCallback onWater;

  const _BedWaterCard({
    required this.data,
    required this.config,
    required this.onWater,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ratio = data.status.availableWater / data.status.maxCapacity;
    final needsWater = ratio < 0.4; // Less than 40% full

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: data.bedColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    data.bedName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ),
                if (needsWater)
                  FilledButton.tonalIcon(
                    onPressed: onWater,
                    icon: const Icon(Icons.water_drop, size: 16),
                    label: const Text('Vand'),
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.blue.shade100,
                      foregroundColor: Colors.blue.shade700,
                    ),
                  )
                else
                  IconButton(
                    onPressed: onWater,
                    icon: const Icon(Icons.water_drop_outlined),
                    tooltip: 'Registrer vanding',
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            WaterStatusWidget(
              status: data.status,
              config: config,
              service: ref.read(waterIndexServiceProvider),
              bedWidthCm: data.widthCm,
              bedHeightCm: data.heightCm,
              compact: false,
            ),
            if (data.status.isSeasonActive && data.status.daysTracked > 0) ...[
              const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.md,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _MiniStat(
                      icon: Icons.wb_sunny,
                      label: 'Fordampning',
                      value: '${data.status.totalEvaporation.toStringAsFixed(0)} mm',
                    ),
                    _MiniStat(
                      icon: Icons.water,
                      label: 'Regn',
                      value: '${data.status.totalRainfall.toStringAsFixed(0)} mm',
                    ),
                    _MiniStat(
                      icon: Icons.shower,
                      label: 'Vandet',
                      value: '${data.status.totalWatering.toStringAsFixed(0)} mm',
                    ),
                  ],
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey),
        const SizedBox(width: 4),
        Text(
          '$label: $value',
          style: const TextStyle(fontSize: 11, color: Colors.grey),
        ),
      ],
    );
  }
}

class _BedWaterData {
  final String bedId;
  final String bedName;
  final Color bedColor;
  final BedWaterStatus status;
  final double widthCm;
  final double heightCm;

  _BedWaterData({
    required this.bedId,
    required this.bedName,
    required this.bedColor,
    required this.status,
    required this.widthCm,
    required this.heightCm,
  });
}
