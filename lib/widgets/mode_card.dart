import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/performance_mode.dart';
import '../theme/app_theme.dart';

class ModeCard extends StatelessWidget {
  final PerformanceMode mode;
  final bool isActive;
  final bool isLoading;
  final VoidCallback onApply;

  const ModeCard({
    super.key,
    required this.mode,
    required this.isActive,
    required this.isLoading,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final modeColor = mode.color;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isActive
            ? modeColor.withOpacity(0.08)
            : AppTheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isActive ? modeColor : AppTheme.border,
          width: isActive ? 2.0 : 1.2,
        ),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: modeColor.withOpacity(0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: isLoading
              ? null
              : () {
                  HapticFeedback.mediumImpact();
                  onApply();
                },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Icon, Title, and Active status badge
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Mode Icon container
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            mode.gradientStart.withOpacity(0.25),
                            mode.gradientEnd.withOpacity(0.12),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: modeColor.withOpacity(0.5),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        mode.icon,
                        color: modeColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Title and Governor tag
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                mode.title,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 19,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const Spacer(),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: modeColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: modeColor,
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: modeColor,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ACTIVE',
                                        style: TextStyle(
                                          color: modeColor,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: 0.8,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.border,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.memory_rounded,
                                  size: 13,
                                  color: AppTheme.textMuted,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'governor: ${mode.governor}',
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                    fontFamily: 'monospace',
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Mode description
                Text(
                  mode.description,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 13.5,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 18),
                // Action Button
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: isLoading
                        ? null
                        : () {
                            HapticFeedback.heavyImpact();
                            onApply();
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive
                          ? modeColor.withOpacity(0.2)
                          : modeColor,
                      foregroundColor: isActive
                          ? modeColor
                          : Colors.black,
                      elevation: isActive ? 0 : 4,
                      shadowColor: modeColor.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: modeColor,
                          width: isActive ? 1.5 : 0,
                        ),
                      ),
                    ),
                    child: isLoading
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: isActive ? modeColor : Colors.black,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.check_circle_rounded
                                    : Icons.play_arrow_rounded,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                isActive
                                    ? 'RE-APPLY ${mode.title.toUpperCase()}'
                                    : 'ACTIVATE ${mode.title.toUpperCase()}',
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
