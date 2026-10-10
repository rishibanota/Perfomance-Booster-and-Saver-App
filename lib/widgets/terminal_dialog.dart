import 'package:flutter/material.dart';
import '../services/root_service.dart';
import '../theme/app_theme.dart';

class TerminalDialog extends StatefulWidget {
  final String? initialCommand;

  const TerminalDialog({super.key, this.initialCommand});

  @override
  State<TerminalDialog> createState() => _TerminalDialogState();
}

class _TerminalDialogState extends State<TerminalDialog> {
  late final TextEditingController _commandController;
  final ScrollController _scrollController = ScrollController();
  final List<String> _outputLines = [];
  bool _isRunning = false;

  final List<String> _quickPresets = [
    'id',
    'dumpsys battery | grep -E "level|status|temp"',
    'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_governor',
    'cat /sys/devices/system/cpu/cpu7/cpufreq/scaling_governor',
    'cat /sys/devices/system/cpu/cpu0/cpufreq/scaling_available_governors',
    'am force-stop com.whatsapp',
  ];

  @override
  void initState() {
    super.initState();
    _commandController = TextEditingController(
      text: widget.initialCommand ?? 'id',
    );
    _outputLines.add('# Antigravity Superuser Shell Ready');
    _outputLines.add('# Commands execute via su -c "<command>"');
    _outputLines.add('');
  }

  @override
  void dispose() {
    _commandController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _runCommand([String? cmdToRun]) async {
    final cmd = (cmdToRun ?? _commandController.text).trim();
    if (cmd.isEmpty) return;

    setState(() {
      _isRunning = true;
      _outputLines.add('\$ su -c "$cmd"');
    });

    final res = await RootService.instance.executeCommand(cmd);

    if (mounted) {
      setState(() {
        _isRunning = false;
        if (res['stdout'].toString().isNotEmpty) {
          _outputLines.add(res['stdout'].toString());
        }
        if (res['stderr'].toString().isNotEmpty) {
          _outputLines.add('[STDERR] ${res['stderr']}');
        }
        _outputLines.add('[Process completed with exit code ${res['exitCode']}]');
        _outputLines.add('');
      });

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: double.infinity,
        height: 540,
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.terminal_rounded,
                  color: AppTheme.balanceAccent,
                  size: 22,
                ),
                const SizedBox(width: 10),
                const Text(
                  'Root Shell Console',
                  style: TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Quick preset chips
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _quickPresets.map((preset) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ActionChip(
                      label: Text(
                        preset.length > 25 ? '${preset.substring(0, 22)}...' : preset,
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                      backgroundColor: AppTheme.surfaceContainer,
                      side: const BorderSide(color: AppTheme.border),
                      onPressed: () {
                        _commandController.text = preset;
                        _runCommand(preset);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
            // Output terminal area
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF070A0F),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.border, width: 1),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  itemCount: _outputLines.length,
                  itemBuilder: (context, index) {
                    final line = _outputLines[index];
                    Color lineColor = Colors.greenAccent;
                    if (line.startsWith('\$')) {
                      lineColor = AppTheme.balanceAccent;
                    } else if (line.startsWith('[STDERR]')) {
                      lineColor = AppTheme.performanceAccent;
                    } else if (line.startsWith('#')) {
                      lineColor = AppTheme.textMuted;
                    } else if (line.startsWith('[Process')) {
                      lineColor = Colors.amberAccent;
                    }

                    return Text(
                      line,
                      style: TextStyle(
                        color: lineColor,
                        fontSize: 12,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Input line
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commandController,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: AppTheme.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'e.g. echo schedutil > ...',
                      hintStyle: const TextStyle(color: AppTheme.textMuted),
                      prefixText: '# su -c  ',
                      prefixStyle: const TextStyle(
                        color: AppTheme.saverAccent,
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      filled: true,
                      fillColor: AppTheme.surfaceContainer,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppTheme.border),
                      ),
                    ),
                    onSubmitted: (_) => _runCommand(),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  onPressed: _isRunning ? null : () => _runCommand(),
                  style: IconButton.styleFrom(
                    backgroundColor: AppTheme.balanceAccent,
                    foregroundColor: Colors.black,
                  ),
                  icon: _isRunning
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.black,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
