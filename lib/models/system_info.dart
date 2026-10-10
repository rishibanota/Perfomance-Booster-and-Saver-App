class BatteryInfo {
  final int level;
  final double temperature;
  final String status;
  final String health;
  final int voltage;
  final bool isCharging;

  const BatteryInfo({
    this.level = 100,
    this.temperature = 25.0,
    this.status = 'Normal',
    this.health = 'Good',
    this.voltage = 4000,
    this.isCharging = false,
  });

  factory BatteryInfo.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const BatteryInfo();
    return BatteryInfo(
      level: (map['level'] as num?)?.toInt() ?? 100,
      temperature: (map['temperature'] as num?)?.toDouble() ?? 25.0,
      status: map['status']?.toString() ?? 'Normal',
      health: map['health']?.toString() ?? 'Good',
      voltage: (map['voltage'] as num?)?.toInt() ?? 4000,
      isCharging: map['isCharging'] == true,
    );
  }
}

class CpuInfo {
  final int coreCount;
  final Map<String, String> governors;
  final List<String> availableGovernors;

  const CpuInfo({
    this.coreCount = 8,
    this.governors = const {},
    this.availableGovernors = const ['performance', 'schedutil', 'powersave'],
  });

  factory CpuInfo.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return const CpuInfo();
    final govMap = <String, String>{};
    if (map['governors'] is Map) {
      (map['governors'] as Map).forEach((k, v) {
        govMap[k.toString()] = v.toString();
      });
    }

    final availList = <String>[];
    if (map['availableGovernors'] is List) {
      for (final item in map['availableGovernors'] as List) {
        availList.add(item.toString());
      }
    }

    return CpuInfo(
      coreCount: (map['coreCount'] as num?)?.toInt() ?? 8,
      governors: govMap,
      availableGovernors: availList.isEmpty ? const ['performance', 'schedutil', 'powersave'] : availList,
    );
  }
}

class HistoryEntry {
  final int id;
  final String mode;
  final String governor;
  final String battery;
  final String timestamp;
  final bool success;
  final String notes;

  const HistoryEntry({
    required this.id,
    required this.mode,
    required this.governor,
    required this.battery,
    required this.timestamp,
    required this.success,
    this.notes = '',
  });

  factory HistoryEntry.fromMap(Map<dynamic, dynamic> map) {
    return HistoryEntry(
      id: (map['id'] as num?)?.toInt() ?? 0,
      mode: map['mode']?.toString() ?? 'balance',
      governor: map['governor']?.toString() ?? 'schedutil',
      battery: map['battery']?.toString() ?? '100%',
      timestamp: map['timestamp']?.toString() ?? '',
      success: map['success'] == true || map['success'] == 1,
      notes: map['notes']?.toString() ?? '',
    );
  }
}
