/// 體力條 Widget
/// 顯示目前體力 + 恢復倒數計時
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../config/theme.dart';
import '../../agents/providers/player_provider.dart';

class EnergyBar extends StatefulWidget {
  const EnergyBar({super.key});

  @override
  State<EnergyBar> createState() => _EnergyBarState();
}

class _EnergyBarState extends State<EnergyBar> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // 每秒更新一次體力顯示
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        context.read<PlayerProvider>().refreshStamina();
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatCountdown(PlayerProvider provider) {
    final data = provider.data;
    if (data.stamina >= data.maxStamina) return '已滿';

    final now = DateTime.now();
    final elapsed = now.difference(data.lastStaminaRecover);
    final remaining = const Duration(minutes: 8) - elapsed;

    if (remaining.isNegative) return '恢復中...';

    final minutes = remaining.inMinutes;
    final seconds = remaining.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<PlayerProvider>(
      builder: (_, provider, __) {
        if (!provider.isInitialized) return const SizedBox.shrink();

        final data = provider.data;
        final isFull = data.stamina >= data.maxStamina;
        final percent = data.maxStamina > 0
            ? data.stamina / data.maxStamina
            : 0.0;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          margin: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: AppTheme.bgCard.withAlpha(120),
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 8),
                  Text(
                    '${data.stamina}/${data.maxStamina}',
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const Spacer(),
                  if (!isFull)
                    Text(
                      '下次恢復 ${_formatCountdown(provider)}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 12,
                      ),
                    )
                  else
                    const Text(
                      '體力已滿',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: percent.clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: Colors.white10,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isFull ? Colors.green : Colors.amber.shade600,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
