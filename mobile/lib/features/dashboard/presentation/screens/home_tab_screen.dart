import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/features/devices/presentation/widgets/esp32_hotspot_card.dart';
import 'package:haven_mobile/features/devices/providers/esp32_hotspot_provider.dart';
import 'package:haven_mobile/features/devices/providers/relay_names_provider.dart';
import 'package:haven_mobile/features/voice/services/voice_command_parser.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';
import 'package:haven_mobile/features/schedules/providers/hotspot_schedule_provider.dart';

class HomeTabScreen extends ConsumerWidget {
  const HomeTabScreen({super.key});

  Future<void> _executeQuickCommand(
    BuildContext context,
    WidgetRef ref,
    String commandText,
  ) async {
    final relayNames = ref.read(relayNamesProvider);
    final parsed = VoiceCommandParser.parse(
      commandText,
      name1: relayNames.relay1,
      name2: relayNames.relay2,
      name3: relayNames.relay3,
    );

    if (!parsed.isRecognized) {
      context.push(RouteConstants.voicePath);
      return;
    }

    final notifier = ref.read(esp32RelayNotifierProvider.notifier);
    final hotspotService = ref.read(esp32HotspotServiceProvider);

    try {
      switch (parsed.action) {
        case VoiceAction.turnOn:
          final ch = parsed.relayNumber ?? 1;
          await hotspotService.setRelayState(ch, true);
          await notifier.checkConnectionAndRefresh(silent: true);
          final chName = relayNames.getName(ch);
          if (context.mounted) {
            showSuccessSnackBar(context, '$chName (Relay $ch) turned ON');
          }
          break;

        case VoiceAction.turnOff:
          final ch = parsed.relayNumber ?? 1;
          await hotspotService.setRelayState(ch, false);
          await notifier.checkConnectionAndRefresh(silent: true);
          final chName = relayNames.getName(ch);
          if (context.mounted) {
            showSuccessSnackBar(context, '$chName (Relay $ch) turned OFF');
          }
          break;

        case VoiceAction.toggle:
          final ch = parsed.relayNumber ?? 1;
          await notifier.toggleRelay(ch);
          final cur = ref.read(esp32RelayNotifierProvider).relays[ch] ?? false;
          final chName = relayNames.getName(ch);
          if (context.mounted) {
            showInfoSnackBar(context, '$chName is now ${cur ? "ON" : "OFF"}');
          }
          break;

        case VoiceAction.allOn:
          await notifier.setAllRelays(true);
          if (context.mounted) {
            showSuccessSnackBar(context, 'All relays turned ON');
          }
          break;

        case VoiceAction.allOff:
          await notifier.setAllRelays(false);
          if (context.mounted) {
            showSuccessSnackBar(context, 'All relays turned OFF');
          }
          break;

        case VoiceAction.setTimer:
          final ch = parsed.relayNumber ?? 1;
          final mins = parsed.timerMinutes ?? 30;
          final turnOn = parsed.timerTurnOn ?? false;
          await ref.read(hotspotScheduleProvider.notifier).setTimer(relay: ch, turnOn: turnOn, minutes: mins);
          final chName = relayNames.getName(ch);
          if (context.mounted) {
            showSuccessSnackBar(context, '$chName will turn ${turnOn ? "ON" : "OFF"} in $mins mins');
          }
          break;

        case VoiceAction.checkStatus:
        case VoiceAction.unknown:
          await notifier.checkConnectionAndRefresh();
          if (context.mounted) {
            showInfoSnackBar(context, 'Relay status refreshed');
          }
          break;
      }
    } catch (e) {
      if (context.mounted) {
        showErrorSnackBar(context, 'Command failed: Make sure you are connected to ESP32_Relay');
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final relayNames = ref.watch(relayNamesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Haven Smart Home',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'ESP32 Wi-Fi Hotspot Controller',
                          style: TextStyle(
                            color: AppColors.mutedText,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => context.push(RouteConstants.voicePath),
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic_rounded, color: AppColors.accent, size: 22),
                      ),
                      tooltip: 'Voice Commands',
                    ),
                  ],
                ),
              ),

              // Primary Hero: Dedicated ESP32 Hotspot Control Card
              const Esp32HotspotCard(),

              const SizedBox(height: 4),

              // Quick Schedules & Automation Banner
              Consumer(
                builder: (context, ref, _) {
                  final schedState = ref.watch(hotspotScheduleProvider);
                  final activeCount = schedState.schedules.where((s) => s.enabled).length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.alarm_on_rounded, color: AppColors.accent, size: 18),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  activeCount > 0
                                      ? '$activeCount Schedule${activeCount > 1 ? "s" : ""} Active'
                                      : 'No Schedules Active',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  schedState.isTimeSynced
                                      ? 'ESP32 Clock: ${schedState.esp32Time}'
                                      : 'Connect to Wi-Fi to sync clock',
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () => context.go(RouteConstants.schedulesPath),
                          child: const Text('Manage', style: TextStyle(color: AppColors.accent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 8),

              // Quick Voice Command Shortcuts Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.record_voice_over_rounded, color: AppColors.accent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Voice Quick Actions',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: () => context.push(RouteConstants.voicePath),
                          borderRadius: BorderRadius.circular(8),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            child: Row(
                              children: [
                                Text(
                                  'Speak',
                                  style: TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(Icons.chevron_right_rounded, color: AppColors.accent, size: 16),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildActionChip(
                          context,
                          ref,
                          'Turn on ${relayNames.relay1}',
                          Icons.lightbulb_outline,
                        ),
                        _buildActionChip(
                          context,
                          ref,
                          'Turn off ${relayNames.relay2}',
                          Icons.power_settings_new,
                        ),
                        _buildActionChip(
                          context,
                          ref,
                          'Toggle ${relayNames.relay3}',
                          Icons.swap_horiz_rounded,
                        ),
                        _buildActionChip(
                          context,
                          ref,
                          'All ON',
                          Icons.flash_on_rounded,
                        ),
                        _buildActionChip(
                          context,
                          ref,
                          'All OFF',
                          Icons.flash_off_rounded,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // Quick Connection Guide Card
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.accent, size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Connection & Usage Tips',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildTipItem('1', 'Connect phone Wi-Fi to "ESP32_Relay" (password: 12345678).'),
                    _buildTipItem('2', 'If Android asks "No internet? Stay connected", select YES.'),
                    _buildTipItem('3', 'Tap the pencil icon next to any relay to rename it (e.g. Light, Fan, Socket).'),
                    _buildTipItem('4', 'Tap the mic icon anytime to speak commands naturally.'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionChip(
    BuildContext context,
    WidgetRef ref,
    String label,
    IconData icon,
  ) {
    return InkWell(
      onTap: () => _executeQuickCommand(context, ref, label),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppColors.accent),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTipItem(String num, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.accent.withValues(alpha: 0.15),
            ),
            child: Text(
              num,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
