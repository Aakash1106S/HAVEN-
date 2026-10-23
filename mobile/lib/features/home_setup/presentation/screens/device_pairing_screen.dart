import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/di/providers.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/device_model.dart';
import 'package:haven_mobile/shared/models/channel_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class DevicePairingScreen extends ConsumerStatefulWidget {
  final String homeId;
  const DevicePairingScreen({super.key, required this.homeId});

  @override
  ConsumerState<DevicePairingScreen> createState() => _DevicePairingScreenState();
}

class _DevicePairingScreenState extends ConsumerState<DevicePairingScreen> {
  int _currentStep = 0;
  String _pairingCode = '';
  String _deviceId = '';
  int _secondsLeft = 300;
  Timer? _countdownTimer;
  bool _isCreating = false;

  final _deviceNameCtrl = TextEditingController(text: 'Main ESP32 Hub');
  final _ch0NameCtrl = TextEditingController(text: 'Room 1 Light');
  final _ch1NameCtrl = TextEditingController(text: 'Room 2 Fan');
  final _ch2NameCtrl = TextEditingController(text: 'Room 3 Appliance');

  String? _ch0RoomId;
  String? _ch1RoomId;
  String? _ch2RoomId;

  @override
  void initState() {
    super.initState();
    _generatePairingCode();
  }

  void _generatePairingCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random();
    _pairingCode = String.fromCharCodes(
      Iterable.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))),
    );
    _deviceId = 'esp32-${_pairingCode.toLowerCase()}';
    _secondsLeft = 300;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        if (_secondsLeft > 0) {
          _secondsLeft--;
        } else {
          timer.cancel();
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _deviceNameCtrl.dispose();
    _ch0NameCtrl.dispose();
    _ch1NameCtrl.dispose();
    _ch2NameCtrl.dispose();
    super.dispose();
  }

  Future<void> _completePairing() async {
    setState(() => _isCreating = true);
    try {
      final effectiveHomeId = widget.homeId.isNotEmpty
          ? widget.homeId
          : ref.read(currentHomeProvider).valueOrNull?.id ?? '';

      final userId = ref.read(currentUserIdProvider) ?? '';
      if (effectiveHomeId.isEmpty || userId.isEmpty) {
        throw Exception('User or home session not found');
      }

      // 1. Create Device
      final device = DeviceModel(
        id: _deviceId,
        homeId: effectiveHomeId,
        name: _deviceNameCtrl.text.trim(),
        ownerId: userId,
        status: DeviceStatus.online,
        channelCount: 3,
        createdAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
      );
      await ref.read(deviceRepositoryProvider).registerDevice(effectiveHomeId, device);

      // 2. Create 3 physical relay channels
      final channels = [
        ChannelModel(
          id: '',
          homeId: effectiveHomeId,
          deviceId: _deviceId,
          roomId: _ch0RoomId,
          channelNumber: 0,
          applianceName: _ch0NameCtrl.text.trim(),
          desiredState: ApplianceState.off,
          reportedState: ApplianceState.off,
          commandStatus: CommandStatus.idle,
          createdAt: DateTime.now(),
        ),
        ChannelModel(
          id: '',
          homeId: effectiveHomeId,
          deviceId: _deviceId,
          roomId: _ch1RoomId,
          channelNumber: 1,
          applianceName: _ch1NameCtrl.text.trim(),
          desiredState: ApplianceState.off,
          reportedState: ApplianceState.off,
          commandStatus: CommandStatus.idle,
          createdAt: DateTime.now(),
        ),
        ChannelModel(
          id: '',
          homeId: effectiveHomeId,
          deviceId: _deviceId,
          roomId: _ch2RoomId,
          channelNumber: 2,
          applianceName: _ch2NameCtrl.text.trim(),
          desiredState: ApplianceState.off,
          reportedState: ApplianceState.off,
          commandStatus: CommandStatus.idle,
          createdAt: DateTime.now(),
        ),
      ];

      for (final ch in channels) {
        await ref.read(channelRepositoryProvider).createChannel(effectiveHomeId, ch);
      }

      if (mounted) {
        showSuccessSnackBar(context, 'Device connected & configured successfully!');
        context.go(RouteConstants.dashboardPath);
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Pairing failed: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(homeRoomsProvider).valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connect ESP32 Hardware',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: _currentStep == 0
              ? _buildStepOne(rooms)
              : _buildStepTwo(rooms),
        ),
      ),
    );
  }

  Widget _buildStepOne(List<dynamic> rooms) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.qr_code_scanner_rounded, size: 48, color: AppColors.accent),
        const SizedBox(height: 16),
        const Text(
          'Hardware Provisioning',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Use this one-time pairing key in your firmware/credentials_config.h file to authenticate your ESP32.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 14, height: 1.5),
        ),
        const SizedBox(height: 24),
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
            decoration: BoxDecoration(
              color: AppColors.cardDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.accent, width: 2),
            ),
            child: Column(
              children: [
                Text(
                  _pairingCode,
                  style: const TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 8,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Expires in $minutes:$seconds',
                  style: TextStyle(
                    color: _secondsLeft < 60 ? AppColors.error : AppColors.mutedText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: TextButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: _pairingCode));
              showSuccessSnackBar(context, 'Pairing code copied to clipboard');
            },
            icon: const Icon(Icons.copy_rounded, color: AppColors.accent, size: 18),
            label: const Text('Copy Code', style: TextStyle(color: AppColors.accent)),
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderDark),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Assigned Device ID',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
              const SizedBox(height: 4),
              SelectableText(_deviceId,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
              const Divider(color: AppColors.borderDark, height: 24),
              const Text('MQTT Broker Host',
                  style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
              const SizedBox(height: 4),
              const SelectableText('YOUR-HIVEMQ-BROKER.s2.eu.hivemq.cloud:8883 (TLS)',
                  style: TextStyle(
                      color: Colors.white, fontFamily: 'monospace', fontSize: 12)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _currentStep = 1),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Next: Configure Channels',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
      ],
    );
  }

  Widget _buildStepTwo(List<dynamic> rooms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Name Device & Channels',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        const SizedBox(height: 8),
        const Text(
          'Assign descriptive names to your 3 hardware channels and link them to rooms.',
          style: TextStyle(color: AppColors.mutedText, fontSize: 14),
        ),
        const SizedBox(height: 20),
        TextFormField(
          controller: _deviceNameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            labelText: 'Device Name',
            labelStyle: const TextStyle(color: AppColors.mutedText),
            filled: true,
            fillColor: AppColors.cardDark,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
        const SizedBox(height: 20),
        _buildChannelSection(0, _ch0NameCtrl, _ch0RoomId, (val) => setState(() => _ch0RoomId = val), rooms),
        const SizedBox(height: 16),
        _buildChannelSection(1, _ch1NameCtrl, _ch1RoomId, (val) => setState(() => _ch1RoomId = val), rooms),
        const SizedBox(height: 16),
        _buildChannelSection(2, _ch2NameCtrl, _ch2RoomId, (val) => setState(() => _ch2RoomId = val), rooms),
        const SizedBox(height: 32),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _currentStep = 0),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: AppColors.borderDark),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Back'),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _isCreating ? null : _completePairing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isCreating
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Complete Setup', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChannelSection(
    int index,
    TextEditingController nameCtrl,
    String? selectedRoom,
    ValueChanged<String?> onRoomChanged,
    List<dynamic> rooms,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderDark),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Channel $index (Relay GPIO ${[26, 27, 14][index]})',
              style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 10),
          TextFormField(
            controller: nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: 'Appliance Name',
              labelStyle: const TextStyle(color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedRoom,
            dropdownColor: AppColors.cardDark,
            style: const TextStyle(color: Colors.white, fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Assign to Room',
              labelStyle: const TextStyle(color: AppColors.mutedText),
              filled: true,
              fillColor: AppColors.cardDark,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
            ),
            items: [
              const DropdownMenuItem(value: null, child: Text('No Room (Unassigned)')),
              ...rooms.map((r) => DropdownMenuItem(value: r.id as String, child: Text(r.name as String))),
            ],
            onChanged: onRoomChanged,
          ),
        ],
      ),
    );
  }
}
