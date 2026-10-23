import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _deviceOffline = true;
  bool _commandFailure = true;
  bool _scheduleExecuted = false;
  bool _deviceReconnect = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Notification Preferences',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'Hardware & Alert Notifications',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _switchTile(
              title: 'Device Goes Offline',
              subtitle: 'Receive high-priority alert when an ESP32 hub disconnects',
              value: _deviceOffline,
              onChanged: (v) {
                setState(() => _deviceOffline = v);
                showSuccessSnackBar(context, 'Preferences updated');
              },
            ),
            _switchTile(
              title: 'Command Failures',
              subtitle: 'Notify if an appliance command fails to execute or times out',
              value: _commandFailure,
              onChanged: (v) {
                setState(() => _commandFailure = v);
                showSuccessSnackBar(context, 'Preferences updated');
              },
            ),
            _switchTile(
              title: 'Device Reconnected',
              subtitle: 'Notify when a previously offline ESP32 comes back online',
              value: _deviceReconnect,
              onChanged: (v) {
                setState(() => _deviceReconnect = v);
                showSuccessSnackBar(context, 'Preferences updated');
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'Automation Notifications',
              style: TextStyle(
                color: AppColors.mutedText,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            _switchTile(
              title: 'Schedule Executions',
              subtitle: 'Notify each time a timed schedule triggers an appliance action',
              value: _scheduleExecuted,
              onChanged: (v) {
                setState(() => _scheduleExecuted = v);
                showSuccessSnackBar(context, 'Preferences updated');
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.accent,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
