import 'dart:io';
import 'package:flutter/services.dart';
import '../models/performance_mode.dart';
import '../models/system_info.dart';

class RootService {
  static const MethodChannel _channel =
      MethodChannel('com.example.perfomance_booster_and_saver_app/root');

  static final RootService instance = RootService._();
  RootService._();

  bool _isAndroid() {
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  /// Checks if root (su) binary exists and whether superuser access is granted
  Future<Map<String, dynamic>> checkRoot() async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('checkRoot');
        if (result != null) {
          return {
            'available': result['available'] == true,
            'granted': result['granted'] == true,
            'details': result['details']?.toString() ?? '',
          };
        }
      } catch (e) {
        return {
          'available': false,
          'granted': false,
          'details': 'Error checking root: $e',
        };
      }
    }

    // Fallback for desktop / development
    try {
      final res = await Process.run('su', ['-c', 'id']);
      final granted = res.exitCode == 0 && res.stdout.toString().contains('uid=0');
      return {
        'available': true,
        'granted': granted,
        'details': granted ? 'Root granted (uid=0)' : 'Root prompt denied or su failed',
      };
    } catch (_) {
      return {
        'available': false,
        'granted': false,
        'details': 'Not running on rooted Android environment',
      };
    }
  }

  /// Triggers a root request to prompt Magisk / KernelSU authorization dialog
  Future<Map<String, dynamic>> requestRoot() async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('requestRoot');
        if (result != null) {
          return {
            'granted': result['granted'] == true,
            'stdout': result['stdout']?.toString() ?? '',
            'stderr': result['stderr']?.toString() ?? '',
            'exitCode': (result['exitCode'] as num?)?.toInt() ?? -1,
          };
        }
      } catch (e) {
        return {
          'granted': false,
          'stdout': '',
          'stderr': e.toString(),
          'exitCode': -1,
        };
      }
    }

    try {
      final res = await Process.run('su', ['-c', 'id']);
      final granted = res.exitCode == 0 && res.stdout.toString().contains('uid=0');
      return {
        'granted': granted,
        'stdout': res.stdout.toString(),
        'stderr': res.stderr.toString(),
        'exitCode': res.exitCode,
      };
    } catch (e) {
      return {
        'granted': false,
        'stdout': '',
        'stderr': e.toString(),
        'exitCode': -1,
      };
    }
  }

  /// Runs an arbitrary shell command using su -c
  Future<Map<String, dynamic>> executeCommand(String command) async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'executeCommand',
          {'command': command},
        );
        if (result != null) {
          return {
            'success': result['success'] == true,
            'stdout': result['stdout']?.toString() ?? '',
            'stderr': result['stderr']?.toString() ?? '',
            'exitCode': (result['exitCode'] as num?)?.toInt() ?? -1,
          };
        }
      } catch (e) {
        return {
          'success': false,
          'stdout': '',
          'stderr': e.toString(),
          'exitCode': -1,
        };
      }
    }

    try {
      final res = await Process.run('su', ['-c', command]);
      return {
        'success': res.exitCode == 0,
        'stdout': res.stdout.toString(),
        'stderr': res.stderr.toString(),
        'exitCode': res.exitCode,
      };
    } catch (e) {
      return {
        'success': false,
        'stdout': '',
        'stderr': e.toString(),
        'exitCode': -1,
      };
    }
  }

  /// Applies the specified performance mode (Performance, Balance, Saver)
  /// sets governors (performance, schedutil, powersave) to all CPU cores
  /// and performs mode-specific actions.
  Future<Map<String, dynamic>> applyMode(
    PerformanceMode mode, {
    bool killApps = false,
    bool disableNetwork = false,
    List<String>? customApps,
  }) async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'applyMode',
          {
            'mode': mode.id,
            'killApps': killApps,
            'disableNetwork': disableNetwork,
            'customApps': customApps ?? [
              'com.whatsapp',
              'com.facebook.katana',
              'org.telegram.messenger',
              'com.instagram.android',
            ],
          },
        );

        if (result != null) {
          final logs = <String>[];
          if (result['logs'] is List) {
            for (final l in result['logs'] as List) {
              logs.add(l.toString());
            }
          }
          return {
            'success': result['success'] == true,
            'mode': result['mode']?.toString() ?? mode.id,
            'governor': result['governor']?.toString() ?? mode.governor,
            'battery': result['battery']?.toString() ?? '',
            'timestamp': result['timestamp']?.toString() ?? '',
            'logs': logs,
          };
        }
      } catch (e) {
        return {
          'success': false,
          'mode': mode.id,
          'governor': mode.governor,
          'battery': '',
          'timestamp': DateTime.now().toString(),
          'logs': ['MethodChannel invocation error: $e'],
        };
      }
    }

    // Fallback execution for non-Android / mock
    final gov = mode.governor;
    final cmd = 'echo $gov > /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor && '
        'echo $gov > /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor';
    final res = await executeCommand(cmd);
    return {
      'success': res['success'] == true,
      'mode': mode.id,
      'governor': gov,
      'battery': '100%',
      'timestamp': DateTime.now().toString(),
      'logs': [
        'Executed: $cmd',
        if (res['stdout'].toString().isNotEmpty) 'Stdout: ${res['stdout']}',
        if (res['stderr'].toString().isNotEmpty) 'Stderr: ${res['stderr']}',
      ],
    };
  }

  /// Retrieves real-time battery status using root dumpsys or BatteryManager
  Future<BatteryInfo> getBatteryInfo() async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getBatteryInfo');
        if (result != null) {
          return BatteryInfo.fromMap(result);
        }
      } catch (_) {}
    }

    return const BatteryInfo(
      level: 100,
      temperature: 28.5,
      status: 'Normal',
      health: 'Good',
      voltage: 4100,
      isCharging: false,
    );
  }

  /// Retrieves core count and current governor per CPU core
  Future<CpuInfo> getCpuInfo() async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>('getCpuInfo');
        if (result != null) {
          return CpuInfo.fromMap(result);
        }
      } catch (_) {}
    }

    return const CpuInfo(
      coreCount: 8,
      governors: {
        'cpu0': 'schedutil',
        'cpu1': 'schedutil',
        'cpu2': 'schedutil',
        'cpu3': 'schedutil',
        'cpu4': 'schedutil',
        'cpu5': 'schedutil',
        'cpu6': 'schedutil',
        'cpu7': 'schedutil',
      },
      availableGovernors: ['performance', 'schedutil', 'powersave'],
    );
  }

  /// Force-stops a list of Android package names using su -c am force-stop
  Future<Map<String, dynamic>> forceStopApps(List<String> packages) async {
    if (_isAndroid()) {
      try {
        final result = await _channel.invokeMethod<Map<dynamic, dynamic>>(
          'forceStopApps',
          {'packages': packages},
        );
        if (result != null) {
          final stopped = <String>[];
          if (result['stopped'] is List) {
            for (final s in result['stopped'] as List) {
              stopped.add(s.toString());
            }
          }
          return {
            'success': result['success'] == true,
            'stopped': stopped,
          };
        }
      } catch (e) {
        return {'success': false, 'stopped': <String>[], 'error': e.toString()};
      }
    }

    final stopped = <String>[];
    for (final pkg in packages) {
      final res = await executeCommand('am force-stop $pkg');
      if (res['success'] == true) {
        stopped.add(pkg);
      }
    }
    return {'success': stopped.isNotEmpty, 'stopped': stopped};
  }
}
