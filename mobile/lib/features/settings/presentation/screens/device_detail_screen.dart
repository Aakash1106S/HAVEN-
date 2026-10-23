import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/device_model.dart';
import 'package:haven_mobile/shared/models/channel_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class DeviceDetailScreen extends ConsumerStatefulWidget {
  final String deviceId;
  const DeviceDetailScreen({super.key, required this.deviceId});

  @override
  ConsumerState<DeviceDetailScreen> createState() => _DeviceDetailScreenState();
}

class _DeviceDetailScreenState extends ConsumerState<DeviceDetailScreen> {
  final _nameCtrl = TextEditingController();
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _initFromDevice(DeviceModel device) {
    if (!_initialized) {
      _nameCtrl.text = device.name;
      _initialized = true;
    }
  }

  Future<void> _updateName(DeviceModel device) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;

    setState(() => _isSaving = true);
    try {
      final updated = device.copyWith(name: name);
      await ref.read(deviceRepositoryProvider).updateDevice(device.homeId, updated);
      if (mounted) showSuccessSnackBar(context, 'Device renamed');
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to update name: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _removeDevice(DeviceModel device) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Unpair Device?',
            style: TextStyle(color: AppColors.error, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to remove "${device.name}"? The hardware will no longer receive commands from this app.',
          style: const TextStyle(color: AppColors.mutedText),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(deviceRepositoryProvider).removeDevice(device.homeId, device.id);
        if (mounted) {
          showSuccessSnackBar(context, 'Device removed');
          context.pop();
        }
      } catch (e) {
        if (mounted) showErrorSnackBar(context, 'Failed to remove device: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final devices = ref.watch(homeDevicesProvider).valueOrNull ?? [];
    final channels = ref.watch(homeChannelsProvider).valueOrNull ?? [];
    final device = devices.firstWhere(
      (d) => d.id == widget.deviceId,
      orElse: () => DeviceModel(
        id: widget.deviceId,
        homeId: '',
        name: 'ESP32 Device',
        ownerId: '',
        status: DeviceStatus.unknown,
        createdAt: DateTime.now(),
      ),
    );

    if (device.homeId.isNotEmpty) {
      _initFromDevice(device);
    }

    final deviceChannels = channels.where((c) => c.deviceId == widget.deviceId).toList();
    final isOnline = device.status == DeviceStatus.online;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Device Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _removeDevice(device),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Remove Device',
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            // Status Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Row(
                children: [
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isOnline ? AppColors.online : AppColors.offline,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    isOnline ? 'Online & Ready' : 'Device Offline',
                    style: TextStyle(
                      color: isOnline ? AppColors.online : AppColors.mutedText,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'v${device.firmwareVersion ?? "1.0.0"}',
                    style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Device Name',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.cardDark,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : () => _updateName(device),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Update'),
                ),
              ],
            ),

            const SizedBox(height: 24),
            const Text('Hardware Specifications',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  _specRow('Microcontroller', 'ESP32 dual-core (240MHz)'),
                  const Divider(color: AppColors.borderDark, height: 20),
                  _specRow('Firmware Protocol', 'MQTT over TLS 1.3 (port 8883)'),
                  const Divider(color: AppColors.borderDark, height: 20),
                  _specRow('Channels Supported', '${device.channelCount} relays'),
                  const Divider(color: AppColors.borderDark, height: 20),
                  _specRow('Device UUID', device.id),
                ],
              ),
            ),

            const SizedBox(height: 24),
            const Text('Assigned Channels',
                style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            ...deviceChannels.map((ch) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
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
                        color: AppColors.cardDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('CH${ch.channelNumber}',
                          style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(ch.applianceName,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600)),
                          Text(
                            'State: ${ch.reportedState.name.toUpperCase()}',
                            style: TextStyle(
                              fontSize: 11,
                              color: ch.reportedState == ApplianceState.on
                                  ? AppColors.online
                                  : AppColors.mutedText,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _specRow(String key, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(key, style: const TextStyle(color: AppColors.mutedText, fontSize: 12)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
