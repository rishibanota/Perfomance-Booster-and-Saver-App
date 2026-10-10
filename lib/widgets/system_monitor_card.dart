import 'package:flutter/material.dart';
import '../models/system_info.dart';
import '../theme/app_theme.dart';

class SystemMonitorCard extends StatelessWidget {
  final BatteryInfo battery;
  final CpuInfo cpu;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  const SystemMonitorCard({
    super.key,
    required this.battery,
    required this.cpu,
    required this.isRefreshing,
    required this.onRefresh,
  });

  Color _getBatteryColor(int level) {
    if (level > 60) return AppTheme.saverAccent;
    if (level > 25) return AppTheme.balanceAccent;
    return AppTheme.performanceAccent;
  }

  Color _getTempColor(double temp) {
    if (temp < 36) return AppTheme.saverAccent;
    if (temp < 43) return Colors.amberAccent;
    return AppTheme.performanceAccent;
  }

  @override
  Widget build(BuildContext context) {
    final batColor = _getBatteryColor(battery.level);
    final tempColor = _getTempColor(battery.temperature);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Refresh action
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.balanceAccent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.monitor_heart_rounded,
                  color: AppTheme.balanceAccent,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Hardware Monitor',
                style: TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: isRefreshing ? null : onRefresh,
                tooltip: 'Refresh System Metrics',
                icon: isRefreshing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.balanceAccent,
                        ),
                      )
                    : const Icon(
                        Icons.refresh_rounded,
                        color: AppTheme.textSecondary,
                        size: 20,
                      ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Battery stats row
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border, width: 0.8),
            ),
            child: Row(
              children: [
                // Battery level circle / indicator
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: CircularProgressIndicator(
                        value: (battery.level / 100.0).clamp(0.0, 1.0),
                        backgroundColor: Colors.white10,
                        color: batColor,
                        strokeWidth: 5.5,
                      ),
                    ),
                    Icon(
                      battery.isCharging
                          ? Icons.bolt_rounded
                          : Icons.battery_std_rounded,
                      color: batColor,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '${battery.level}%',
                            style: TextStyle(
                              color: batColor,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: batColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              battery.status,
                              style: TextStyle(
                                color: batColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${battery.temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              color: tempColor,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•  ${battery.voltage} mV',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            '•  ${battery.health}',
                            style: const TextStyle(
                              color: AppTheme.textMuted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // CPU Cores and Governors
          Row(
            children: [
              const Icon(
                Icons.memory_rounded,
                size: 16,
                color: AppTheme.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                'CPU Cores & Scaling Governors (${cpu.coreCount} Cores detected)',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // CPU Core grid or wrap chips
          cpu.governors.isEmpty
              ? Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'No CPU governor details loaded. Tap refresh to inspect /sys/devices/system/cpu/',
                    style: TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                )
              : Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: cpu.governors.entries.map((entry) {
                    final gov = entry.value;
                    Color govColor = AppTheme.balanceAccent;
                    if (gov == 'performance') govColor = AppTheme.performanceAccent;
                    if (gov == 'powersave') govColor = AppTheme.saverAccent;

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: govColor.withOpacity(0.35),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            entry.key,
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: govColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              gov,
                              style: TextStyle(
                                color: govColor,
                                fontSize: 10.5,
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ],
      ),
    );
  }
}
