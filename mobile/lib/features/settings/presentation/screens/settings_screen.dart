import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';
import 'package:haven_mobile/features/devices/providers/esp32_hotspot_provider.dart';
import 'package:haven_mobile/features/devices/providers/relay_names_provider.dart';
import 'package:haven_mobile/features/schedules/providers/hotspot_schedule_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  void _showRenameDialog(BuildContext context, WidgetRef ref, int relayNum, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Rename Relay $relayNum',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'e.g. Light, Fan, Pump, Socket',
            hintStyle: const TextStyle(color: AppColors.mutedText),
            filled: true,
            fillColor: AppColors.backgroundDark,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.accent, width: 2),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await ref.read(relayNamesProvider.notifier).setRelayName(relayNum, newName);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  showSuccessSnackBar(context, 'Relay $relayNum renamed to "$newName"');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmResetNames(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Switch Names?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will reset your switch labels back to the defaults (Light, Relay 2, Socket).',
          style: TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () async {
              await ref.read(relayNamesProvider.notifier).resetToDefaults();
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) {
                showSuccessSnackBar(context, 'Switch names reset to defaults');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.secondaryAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hotspotState = ref.watch(esp32RelayNotifierProvider);
    final hotspotNotifier = ref.read(esp32RelayNotifierProvider.notifier);
    final relayNames = ref.watch(relayNamesProvider);
    final schedState = ref.watch(hotspotScheduleProvider);
    final schedNotifier = ref.read(hotspotScheduleProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Hardware & Settings',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            // 1. ESP32 Hotspot Status Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    AppColors.cardDark,
                    AppColors.surfaceDark,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: hotspotState.isConnected
                      ? AppColors.online.withValues(alpha: 0.5)
                      : AppColors.borderDark,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: (hotspotState.isConnected ? AppColors.online : AppColors.warning)
                              .withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.wifi_tethering_rounded,
                          color: hotspotState.isConnected ? AppColors.online : AppColors.warning,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'ESP32_Relay Hotspot',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              hotspotState.isConnected ? 'Connected • 192.168.4.1' : 'Offline • Connect to ESP32 Wi-Fi',
                              style: TextStyle(
                                color: hotspotState.isConnected ? AppColors.online : AppColors.mutedText,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => hotspotNotifier.checkConnectionAndRefresh(),
                        tooltip: 'Check Connection',
                        icon: const Icon(Icons.refresh_rounded, color: AppColors.accent),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Divider(color: AppColors.borderDark, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _statusChip('Mode', 'Direct Hotspot'),
                      _statusChip('IP', '192.168.4.1'),
                      _statusChip('Port', '80 (HTTP)'),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            _sectionHeader('SWITCH LABELS & GPIO MAPPING'),

            _switchTile(
              relayNum: 1,
              gpioPin: 25,
              name: relayNames.relay1,
              icon: Icons.lightbulb_outline_rounded,
              onRename: () => _showRenameDialog(context, ref, 1, relayNames.relay1),
            ),
            _switchTile(
              relayNum: 2,
              gpioPin: 26,
              name: relayNames.relay2,
              icon: Icons.power_settings_new_rounded,
              onRename: () => _showRenameDialog(context, ref, 2, relayNames.relay2),
            ),
            _switchTile(
              relayNum: 3,
              gpioPin: 27,
              name: relayNames.relay3,
              icon: Icons.electrical_services_rounded,
              onRename: () => _showRenameDialog(context, ref, 3, relayNames.relay3),
            ),

            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmResetNames(context, ref),
                icon: const Icon(Icons.restore_rounded, size: 16, color: AppColors.mutedText),
                label: const Text('Reset Names to Default',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ),
            ),

            const SizedBox(height: 16),
            _sectionHeader('AUTOMATION & TIME SYNC'),

            _actionTile(
              icon: Icons.access_time_rounded,
              title: 'ESP32 Hardware Clock',
              subtitle: 'Current Time: ${schedState.esp32Time}',
              trailing: ElevatedButton(
                onPressed: () async {
                  final ok = await schedNotifier.syncTime();
                  if (context.mounted) {
                    if (ok) {
                      showSuccessSnackBar(context, 'ESP32 clock synced with phone!');
                    } else {
                      showErrorSnackBar(context, 'Make sure phone is connected to ESP32_Relay Wi-Fi');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Sync Time', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),

            _actionTile(
              icon: Icons.calendar_month_rounded,
              title: 'Manage Switch Schedules',
              subtitle: '${schedState.schedules.length} active schedule(s)',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
              onTap: () => context.go(RouteConstants.schedulesPath),
            ),

            const SizedBox(height: 24),
            _sectionHeader('VOICE ASSISTANT'),

            _actionTile(
              icon: Icons.mic_rounded,
              title: 'Voice Controls',
              subtitle: 'Natural language speech recognition & offline timers',
              trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
              onTap: () => context.go(RouteConstants.voicePath),
            ),

            const SizedBox(height: 24),
            _sectionHeader('WI-FI CONNECTION REFERENCE'),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InfoRow('Network SSID:', 'ESP32_Relay'),
                  SizedBox(height: 8),
                  _InfoRow('Wi-Fi Password:', '12345678'),
                  SizedBox(height: 8),
                  _InfoRow('Gateway IP:', '192.168.4.1'),
                  SizedBox(height: 8),
                  _InfoRow('Relay Polarity:', 'Active-LOW (5V Modules)'),
                  SizedBox(height: 8),
                  _InfoRow('Architecture:', '100% Offline • Zero Cloud Backend'),
                ],
              ),
            ),

            const SizedBox(height: 32),
            const Center(
              child: Column(
                children: [
                  Text('Haven Local ESP32 Controller',
                      style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  SizedBox(height: 4),
                  Text('v1.2.0-hotspot • Fully Offline & Private',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 11)),
                ],
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.mutedText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _statusChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 10)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _switchTile({
    required int relayNum,
    required int gpioPin,
    required String name,
    required IconData icon,
    required VoidCallback onRename,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accent.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.accent, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  'Relay $relayNum • GPIO $gpioPin',
                  style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRename,
            tooltip: 'Rename',
            icon: const Icon(Icons.edit_outlined, color: AppColors.accent, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: ListTile(
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        leading: Icon(icon, color: AppColors.accent, size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        trailing: trailing,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
