import 'package:flutter/material.dart';
import '../models/performance_mode.dart';
import '../models/system_info.dart';
import '../services/database_service.dart';
import '../services/root_service.dart';
import '../theme/app_theme.dart';
import '../widgets/history_bottom_sheet.dart';
import '../widgets/mode_card.dart';
import '../widgets/quick_actions_card.dart';
import '../widgets/system_monitor_card.dart';
import '../widgets/terminal_dialog.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final RootService _root = RootService.instance;
  final DatabaseService _db = DatabaseService.instance;

  PerformanceMode _activeMode = PerformanceMode.balance;
  PerformanceMode? _applyingMode;

  BatteryInfo _battery = const BatteryInfo();
  CpuInfo _cpu = const CpuInfo();

  bool _isCheckingRoot = false;
  bool _isRefreshingMetrics = false;
  bool _isKillingApps = false;

  Map<String, dynamic> _rootStatus = {
    'available': false,
    'granted': false,
    'details': 'Checking...',
  };

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _db.init();

    // 1. Load persisted active mode from local database
    final savedMode = await _db.getActiveMode();
    if (mounted) {
      setState(() => _activeMode = savedMode);
    }

    // 2. Check root permissions
    await _checkRoot();

    // 3. Fetch hardware metrics
    await _refreshMetrics();

    // 4. Auto-apply on startup if user enabled it in settings
    if (_db.autoApplyOnLaunch) {
      _applyMode(_activeMode, isAutoApply: true);
    }
  }

  Future<void> _checkRoot() async {
    setState(() => _isCheckingRoot = true);
    final status = await _root.checkRoot();
    if (mounted) {
      setState(() {
        _rootStatus = status;
        _isCheckingRoot = false;
      });
    }
  }

  Future<void> _requestRoot() async {
    setState(() => _isCheckingRoot = true);
    final res = await _root.requestRoot();
    if (mounted) {
      if (res['granted'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Root access granted successfully!'),
            backgroundColor: AppTheme.saverAccent,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Root request failed: ${res['stderr'] ?? 'Denied'}'),
            backgroundColor: AppTheme.performanceAccent,
          ),
        );
      }
      await _checkRoot();
    }
  }

  Future<void> _refreshMetrics() async {
    setState(() => _isRefreshingMetrics = true);
    final batteryData = await _root.getBatteryInfo();
    final cpuData = await _root.getCpuInfo();
    if (mounted) {
      setState(() {
        _battery = batteryData;
        _cpu = cpuData;
        _isRefreshingMetrics = false;
      });
    }
  }

  Future<void> _applyMode(PerformanceMode mode, {bool isAutoApply = false}) async {
    setState(() => _applyingMode = mode);

    final isSaver = mode == PerformanceMode.saver;
    final killApps = isSaver && _db.killAppsOnSaver;
    final disableNet = isSaver && _db.disableNetworkOnSaver;
    final targetApps = _db.customAppsToKill;

    final result = await _root.applyMode(
      mode,
      killApps: killApps,
      disableNetwork: disableNet,
      customApps: targetApps,
    );

    // Persist option to local SQLite database
    await _db.setActiveMode(mode);

    if (mounted) {
      setState(() {
        _activeMode = mode;
        _applyingMode = null;
      });

      // Refresh CPU and battery metrics to show newly active governors
      _refreshMetrics();

      final success = result['success'] == true;
      if (!isAutoApply) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: success ? AppTheme.saverAccent : AppTheme.performanceAccent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    success
                        ? '${mode.title} activated! Governor set to "${mode.governor}".'
                        : 'Failed to apply ${mode.title}. Check root permissions.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _killBackgroundApps() async {
    setState(() => _isKillingApps = true);
    final apps = _db.customAppsToKill;
    final result = await _root.forceStopApps(apps);

    if (mounted) {
      setState(() => _isKillingApps = false);
      final stopped = result['stopped'] as List<String>? ?? [];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            stopped.isNotEmpty
                ? 'Force-stopped ${stopped.length} apps: ${stopped.join(", ")}'
                : 'No apps were terminated or root denied.',
          ),
          backgroundColor: stopped.isNotEmpty ? AppTheme.saverAccent : AppTheme.border,
        ),
      );
    }
  }

  void _openHistory() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const HistoryBottomSheet(),
    );
  }

  void _openTerminal() {
    showDialog(
      context: context,
      builder: (_) => const TerminalDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isRootGranted = _rootStatus['granted'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(
              Icons.bolt_rounded,
              color: AppTheme.balanceAccent,
              size: 24,
            ),
            SizedBox(width: 8),
            Text('Optimizer & Saver'),
          ],
        ),
        actions: [
          // History Audit Log button
          IconButton(
            onPressed: _openHistory,
            tooltip: 'Mode Audit History',
            icon: const Icon(Icons.history_rounded, size: 22),
          ),
          // Settings button
          IconButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _initialize();
            },
            tooltip: 'Settings & Tweaks',
            icon: const Icon(Icons.tune_rounded, size: 22),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _checkRoot();
          await _refreshMetrics();
        },
        color: AppTheme.balanceAccent,
        backgroundColor: AppTheme.surface,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            // Root Status Badge & Interactive Bar
            InkWell(
              onTap: isRootGranted ? null : _requestRoot,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isRootGranted
                      ? AppTheme.rootGrantedColor.withOpacity(0.12)
                      : AppTheme.rootDeniedColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isRootGranted
                        ? AppTheme.rootGrantedColor.withOpacity(0.35)
                        : AppTheme.rootDeniedColor.withOpacity(0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isRootGranted
                          ? Icons.shield_rounded
                          : Icons.shield_outlined,
                      color: isRootGranted
                          ? AppTheme.rootGrantedColor
                          : AppTheme.rootDeniedColor,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        isRootGranted
                            ? 'Root Permissions: Active (su uid=0)'
                            : 'Root Access Missing. Tap to Authorize.',
                        style: TextStyle(
                          color: isRootGranted
                              ? AppTheme.rootGrantedColor
                              : AppTheme.rootDeniedColor,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    if (_isCheckingRoot)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    else if (!isRootGranted)
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppTheme.rootDeniedColor,
                        size: 20,
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Active Profile Summary Banner
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _activeMode.gradientStart.withOpacity(0.25),
                    _activeMode.gradientEnd.withOpacity(0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _activeMode.color.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _activeMode.color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: _activeMode.color, width: 1.2),
                    ),
                    child: Icon(
                      _activeMode.icon,
                      color: _activeMode.color,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CURRENT ACTIVE PROFILE',
                          style: TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _activeMode.title.toUpperCase(),
                          style: TextStyle(
                            color: _activeMode.color,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Governor: ${_activeMode.governor} (Persisted in LocalDB)',
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Section: The 3 Core Modes
            const Text(
              'SELECT PERFORMANCE PROFILE',
              style: TextStyle(
                color: AppTheme.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(height: 12),

            // 1. Performance Mode Card
            ModeCard(
              mode: PerformanceMode.performance,
              isActive: _activeMode == PerformanceMode.performance,
              isLoading: _applyingMode == PerformanceMode.performance,
              onApply: () => _applyMode(PerformanceMode.performance),
            ),

            // 2. Balance Mode Card
            ModeCard(
              mode: PerformanceMode.balance,
              isActive: _activeMode == PerformanceMode.balance,
              isLoading: _applyingMode == PerformanceMode.balance,
              onApply: () => _applyMode(PerformanceMode.balance),
            ),

            // 3. Saver Mode Card
            ModeCard(
              mode: PerformanceMode.saver,
              isActive: _activeMode == PerformanceMode.saver,
              isLoading: _applyingMode == PerformanceMode.saver,
              onApply: () => _applyMode(PerformanceMode.saver),
            ),

            const SizedBox(height: 12),

            // Hardware Monitor Card (Battery + CPU Cores)
            SystemMonitorCard(
              battery: _battery,
              cpu: _cpu,
              isRefreshing: _isRefreshingMetrics,
              onRefresh: _refreshMetrics,
            ),

            // Quick Actions & Tools
            QuickActionsCard(
              isKillingApps: _isKillingApps,
              onKillApps: _killBackgroundApps,
              onOpenTerminal: _openTerminal,
              onCheckRoot: _checkRoot,
            ),
          ],
        ),
      ),
    );
  }
}
