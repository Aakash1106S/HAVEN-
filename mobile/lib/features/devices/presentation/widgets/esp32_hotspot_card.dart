import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/features/devices/providers/esp32_hotspot_provider.dart';
import 'package:haven_mobile/features/devices/providers/relay_names_provider.dart';

class Esp32HotspotCard extends ConsumerWidget {
  const Esp32HotspotCard({super.key});

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
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isNotEmpty) {
                ref.read(relayNamesProvider.notifier).setRelayName(relayNum, ctrl.text.trim());
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.white),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final espState = ref.watch(esp32RelayNotifierProvider);
    final notifier = ref.read(esp32RelayNotifierProvider.notifier);
    final relayNames = ref.watch(relayNamesProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: espState.isConnected
              ? AppColors.accent.withValues(alpha: 0.5)
              : Colors.white10,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: AppColors.accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ESP32 Relay Board',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: espState.isConnected
                                  ? AppColors.online
                                  : AppColors.warning,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            espState.isConnected
                                ? 'Connected • 192.168.4.1'
                                : 'Connect to ESP32_Relay',
                            style: TextStyle(
                              color: espState.isConnected
                                  ? AppColors.online
                                  : AppColors.warning,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.mic_rounded, color: AppColors.accent, size: 24),
                    onPressed: () => context.push(RouteConstants.voicePath),
                    tooltip: 'Voice Control',
                  ),
                  IconButton(
                    icon: espState.isChecking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.accent,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded, color: Colors.white70, size: 22),
                    onPressed: () => notifier.checkConnectionAndRefresh(),
                    tooltip: 'Refresh Status',
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Master Action Buttons (ALL ON / ALL OFF)
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => notifier.setAllRelays(true),
                  icon: const Icon(Icons.flash_on_rounded, size: 16),
                  label: const Text('ALL ON', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent.withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => notifier.setAllRelays(false),
                  icon: const Icon(Icons.flash_off_rounded, size: 16),
                  label: const Text('ALL OFF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondaryAccent.withValues(alpha: 0.85),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3 Relay Controls
          _buildRelayTile(
            context: context,
            ref: ref,
            relayNumber: 1,
            relayName: relayNames.relay1,
            gpio: 25,
            isOn: espState.relays[1] ?? false,
            onToggle: () => notifier.toggleRelay(1),
          ),
          const SizedBox(height: 10),
          _buildRelayTile(
            context: context,
            ref: ref,
            relayNumber: 2,
            relayName: relayNames.relay2,
            gpio: 26,
            isOn: espState.relays[2] ?? false,
            onToggle: () => notifier.toggleRelay(2),
          ),
          const SizedBox(height: 10),
          _buildRelayTile(
            context: context,
            ref: ref,
            relayNumber: 3,
            relayName: relayNames.relay3,
            gpio: 27,
            isOn: espState.relays[3] ?? false,
            onToggle: () => notifier.toggleRelay(3),
          ),

          if (espState.errorMessage != null) ...[
            const SizedBox(height: 10),
            Text(
              espState.errorMessage!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRelayTile({
    required BuildContext context,
    required WidgetRef ref,
    required int relayNumber,
    required String relayName,
    required int gpio,
    required bool isOn,
    required VoidCallback onToggle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isOn
            ? AppColors.accent.withValues(alpha: 0.12)
            : AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOn
              ? AppColors.accent.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.05),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOn
                        ? AppColors.accent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                  ),
                  child: Icon(
                    isOn ? Icons.power_rounded : Icons.power_off_rounded,
                    color: isOn ? AppColors.accent : AppColors.mutedText,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              relayName,
                              style: TextStyle(
                                color: isOn ? Colors.white : AppColors.mutedText,
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          InkWell(
                            onTap: () => _showRenameDialog(context, ref, relayNumber, relayName),
                            borderRadius: BorderRadius.circular(12),
                            child: const Padding(
                              padding: EdgeInsets.all(2.0),
                              child: Icon(Icons.edit_outlined, size: 14, color: AppColors.mutedText),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Relay $relayNumber • GPIO $gpio • ${isOn ? "ACTIVE (ON)" : "INACTIVE (OFF)"}',
                        style: TextStyle(
                          color: isOn ? AppColors.accent : AppColors.mutedText,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Switch(
            value: isOn,
            onChanged: (_) => onToggle(),
            activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
            activeThumbColor: AppColors.accent,
            inactiveThumbColor: AppColors.mutedText,
            inactiveTrackColor: Colors.black26,
          ),
        ],
      ),
    );
  }
}
