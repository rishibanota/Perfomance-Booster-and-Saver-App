import 'package:flutter/material.dart';

enum PerformanceMode {
  performance,
  balance,
  saver;

  String get id => name;

  String get title {
    switch (this) {
      case PerformanceMode.performance:
        return 'Performance';
      case PerformanceMode.balance:
        return 'Balance';
      case PerformanceMode.saver:
        return 'Saver';
    }
  }

  String get governor {
    switch (this) {
      case PerformanceMode.performance:
        return 'performance';
      case PerformanceMode.balance:
        return 'schedutil';
      case PerformanceMode.saver:
        return 'powersave';
    }
  }

  String get description {
    switch (this) {
      case PerformanceMode.performance:
        return 'Locks CPU to peak frequency & maximum responsiveness. Ideal for high FPS gaming, heavy multitasking, and benchmark tests.';
      case PerformanceMode.balance:
        return 'Uses Linux kernel schedutil governor. CPU frequency scales intelligently with scheduler load for optimal speed and battery.';
      case PerformanceMode.saver:
        return 'Locks CPU to minimal powersave frequency. Throttles background battery consumption and keeps device cool for maximum battery endurance.';
    }
  }

  IconData get icon {
    switch (this) {
      case PerformanceMode.performance:
        return Icons.bolt_rounded;
      case PerformanceMode.balance:
        return Icons.tune_rounded;
      case PerformanceMode.saver:
        return Icons.energy_savings_leaf_rounded;
    }
  }

  Color get color {
    switch (this) {
      case PerformanceMode.performance:
        return const Color(0xFFFF5252); // Red / Coral
      case PerformanceMode.balance:
        return const Color(0xFF00E5FF); // Electric Cyan
      case PerformanceMode.saver:
        return const Color(0xFF00E676); // Mint Green
    }
  }

  Color get gradientStart {
    switch (this) {
      case PerformanceMode.performance:
        return const Color(0xFFFF3D00);
      case PerformanceMode.balance:
        return const Color(0xFF00B0FF);
      case PerformanceMode.saver:
        return const Color(0xFF00C853);
    }
  }

  Color get gradientEnd {
    switch (this) {
      case PerformanceMode.performance:
        return const Color(0xFFFF9100);
      case PerformanceMode.balance:
        return const Color(0xFF00E5FF);
      case PerformanceMode.saver:
        return const Color(0xFF69F0AE);
    }
  }

  static PerformanceMode fromString(String? val) {
    if (val == null) return PerformanceMode.balance;
    switch (val.toLowerCase().trim()) {
      case 'performance':
        return PerformanceMode.performance;
      case 'saver':
      case 'powersave':
        return PerformanceMode.saver;
      case 'balance':
      case 'normal':
      case 'schedutil':
      default:
        return PerformanceMode.balance;
    }
  }
}
