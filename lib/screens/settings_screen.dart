import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/root_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final DatabaseService _db = DatabaseService.instance;

  bool _killApps = true;
  bool _disableNetwork = false;
  bool _autoApplyOnLaunch = false;
  List<String> _apps = [];
  final TextEditingController _packageController = TextEditingController();

  Map<String, dynamic> _rootStatus = {
    'available': false,
    'granted': false,
    'details': 'Checking...',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkRoot();
  }

  @override
  void dispose() {
    _packageController.dispose();
    super.dispose();
  }

  void _loadSettings() {
    setState(() {
      _killApps = _db.killAppsOnSaver;
      _disableNetwork = _db.disableNetworkOnSaver;
      _autoApplyOnLaunch = _db.autoApplyOnLaunch;
      _apps = List.from(_db.customAppsToKill);
    });
  }

  Future<void> _checkRoot() async {
    final status = await RootService.instance.checkRoot();
    if (mounted) {
      setState(() => _rootStatus = status);
    }
  }

  void _addPackage() {
    final text = _packageController.text.trim();
    if (text.isNotEmpty && !_apps.contains(text)) {
      setState(() {
        _apps.add(text);
        _db.customAppsToKill = _apps;
      });
      _packageController.clear();
    }
  }

  void _removePackage(String pkg) {
    setState(() {
      _apps.remove(pkg);
      _db.customAppsToKill = _apps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isRootGranted = _rootStatus['granted'] == true;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Preferences & Tweaks'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        children: [
          // Root Status Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRootGranted
                  ? AppTheme.rootGrantedColor.withOpacity(0.12)
                  : AppTheme.rootDeniedColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isRootGranted
                    ? AppTheme.rootGrantedColor.withOpacity(0.4)
                    : AppTheme.rootDeniedColor.withOpacity(0.4),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isRootGranted
                      ? Icons.verified_user_rounded
                      : Icons.gpp_bad_rounded,
                  color: isRootGranted
                      ? AppTheme.rootGrantedColor
                      : AppTheme.rootDeniedColor,
                  size: 28,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRootGranted
                            ? 'Root Permissions Active'
                            : 'Root Access Not Granted',
                        style: TextStyle(
                          color: isRootGranted
                              ? AppTheme.rootGrantedColor
                              : AppTheme.rootDeniedColor,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        _rootStatus['details']?.toString() ?? '',
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await RootService.instance.requestRoot();
                    _checkRoot();
                  },
                  child: const Text('Test Root'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 1: Saver Mode Optimizations
          const Text(
            'SAVER MODE ACTIONS',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Force Stop Background Apps',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Executes am force-stop for high-battery background apps when Saver is applied',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _killApps,
                  activeColor: AppTheme.saverAccent,
                  onChanged: (val) {
                    setState(() {
                      _killApps = val;
                      _db.killAppsOnSaver = val;
                    });
                  },
                ),
                const Divider(color: AppTheme.border, height: 1),
                SwitchListTile(
                  title: const Text(
                    'Disable WiFi & Mobile Data',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Runs svc wifi disable and svc data disable in Saver mode',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _disableNetwork,
                  activeColor: AppTheme.saverAccent,
                  onChanged: (val) {
                    setState(() {
                      _disableNetwork = val;
                      _db.disableNetworkOnSaver = val;
                    });
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Manage Apps to Stop
          const Text(
            'BACKGROUND APPS TO TERMINATE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Package identifiers targeted by am force-stop:',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _apps.map((pkg) {
                    return Chip(
                      label: Text(
                        pkg,
                        style: const TextStyle(
                          fontSize: 11.5,
                          fontFamily: 'monospace',
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceContainer,
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () => _removePackage(pkg),
                      side: const BorderSide(color: AppTheme.border),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _packageController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'e.g. com.twitter.android',
                          hintStyle: const TextStyle(color: AppTheme.textMuted),
                          filled: true,
                          fillColor: AppTheme.surfaceContainer,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: AppTheme.border),
                          ),
                        ),
                        onSubmitted: (_) => _addPackage(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _addPackage,
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: const Text('Add'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.balanceAccent,
                        foregroundColor: Colors.black,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: App Startup
          const Text(
            'AUTOMATION & LOCAL STORAGE',
            style: TextStyle(
              color: AppTheme.textMuted,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppTheme.border, width: 1.2),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Auto-Apply Active Mode on App Launch',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Restores your persisted profile governor upon opening the app',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                  value: _autoApplyOnLaunch,
                  activeColor: AppTheme.balanceAccent,
                  onChanged: (val) {
                    setState(() {
                      _autoApplyOnLaunch = val;
                      _db.autoApplyOnLaunch = val;
                    });
                  },
                ),
                const Divider(color: AppTheme.border, height: 1),
                ListTile(
                  leading: const Icon(
                    Icons.storage_rounded,
                    color: AppTheme.balanceAccent,
                  ),
                  title: const Text(
                    'Local Database: performance_booster.db',
                    style: TextStyle(
                      color: AppTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: const Text(
                    'Stores active mode selection & execution history via SQLite',
                    style: TextStyle(color: AppTheme.textMuted, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}
