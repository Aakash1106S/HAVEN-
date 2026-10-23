import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/channel_model.dart';
import 'package:haven_mobile/shared/models/schedule_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class ScheduleFormScreen extends ConsumerStatefulWidget {
  final String? channelId;
  final String? scheduleId;

  const ScheduleFormScreen({super.key, this.channelId, this.scheduleId});

  @override
  ConsumerState<ScheduleFormScreen> createState() => _ScheduleFormScreenState();
}

class _ScheduleFormScreenState extends ConsumerState<ScheduleFormScreen> {
  String? _selectedChannelId;
  ApplianceState _selectedAction = ApplianceState.on;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);
  final Set<int> _selectedDays = {1, 2, 3, 4, 5}; // Mon-Fri default
  bool _isEnabled = true;
  bool _isSaving = false;
  bool _initialized = false;

  final List<String> _dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

  @override
  void initState() {
    super.initState();
    _selectedChannelId = widget.channelId;
  }

  void _initFromSchedule(ScheduleModel schedule) {
    if (!_initialized) {
      _selectedChannelId = schedule.channelId;
      _selectedAction = schedule.action;
      _isEnabled = schedule.isEnabled;

      // Parse cron e.g. "30 7 * * 1,2,3,4,5"
      final parts = schedule.cronExpression.split(' ');
      if (parts.length >= 5) {
        final minute = int.tryParse(parts[0]) ?? 0;
        final hour = int.tryParse(parts[1]) ?? 0;
        _selectedTime = TimeOfDay(hour: hour, minute: minute);

        final daysPart = parts[4];
        _selectedDays.clear();
        if (daysPart == '*') {
          _selectedDays.addAll([0, 1, 2, 3, 4, 5, 6]);
        } else {
          for (final d in daysPart.split(',')) {
            final dayInt = int.tryParse(d);
            if (dayInt != null) _selectedDays.add(dayInt % 7);
          }
        }
      }
      _initialized = true;
    }
  }

  String _buildCronExpression() {
    final minute = _selectedTime.minute;
    final hour = _selectedTime.hour;
    final days = _selectedDays.isEmpty
        ? '*'
        : (_selectedDays.toList()..sort()).join(',');
    return '$minute $hour * * $days';
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surfaceDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _save() async {
    if (_selectedChannelId == null || _selectedChannelId!.isEmpty) {
      showErrorSnackBar(context, 'Please select an appliance');
      return;
    }

    final home = ref.read(currentHomeProvider).valueOrNull;
    final channels = ref.read(homeChannelsProvider).valueOrNull ?? [];
    final channel = channels.firstWhere(
      (c) => c.id == _selectedChannelId,
      orElse: () => throw Exception('Channel not found'),
    );

    if (home == null) return;

    setState(() => _isSaving = true);
    try {
      final cron = _buildCronExpression();
      final schedule = ScheduleModel(
        id: widget.scheduleId ?? '',
        homeId: home.id,
        channelId: channel.id,
        deviceId: channel.deviceId,
        applianceName: channel.applianceName,
        action: _selectedAction,
        cronExpression: cron,
        timezone: home.timezone,
        isEnabled: _isEnabled,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.scheduleId != null && widget.scheduleId!.isNotEmpty) {
        await ref.read(scheduleRepositoryProvider).updateSchedule(home.id, schedule);
        if (mounted) showSuccessSnackBar(context, 'Schedule updated');
      } else {
        await ref.read(scheduleRepositoryProvider).createSchedule(home.id, schedule);
        if (mounted) showSuccessSnackBar(context, 'Schedule created');
      }

      if (mounted) context.pop();
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to save schedule: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null || widget.scheduleId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Schedule?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to delete this automation schedule?',
            style: TextStyle(color: AppColors.mutedText)),
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(scheduleRepositoryProvider).deleteSchedule(home.id, widget.scheduleId!);
        if (mounted) {
          showSuccessSnackBar(context, 'Schedule deleted');
          context.pop();
        }
      } catch (e) {
        if (mounted) showErrorSnackBar(context, 'Failed to delete schedule: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final channels = ref.watch(homeChannelsProvider).valueOrNull ?? [];
    final schedules = ref.watch(homeSchedulesProvider).valueOrNull ?? [];

    if (widget.scheduleId != null) {
      final existing = schedules.firstWhere(
        (s) => s.id == widget.scheduleId,
        orElse: () => ScheduleModel(
          id: '',
          homeId: '',
          channelId: '',
          deviceId: '',
          applianceName: '',
          action: ApplianceState.on,
          cronExpression: '0 7 * * *',
          timezone: 'Asia/Kolkata',
          isEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
      if (existing.id.isNotEmpty) {
        _initFromSchedule(existing);
      }
    }

    final isEditing = widget.scheduleId != null;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(isEditing ? 'Edit Schedule' : 'New Schedule',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (isEditing)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
              tooltip: 'Delete Schedule',
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Target Appliance
              const Text('Appliance',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedChannelId,
                dropdownColor: AppColors.cardDark,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  hintText: 'Select an appliance',
                  hintStyle: const TextStyle(color: AppColors.mutedText),
                ),
                items: channels.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.applianceName));
                }).toList(),
                onChanged: (val) => setState(() => _selectedChannelId = val),
              ),

              const SizedBox(height: 24),
              // Action (Turn On / Turn Off)
              const Text('Action',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedAction = ApplianceState.on),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedAction == ApplianceState.on
                              ? AppColors.accent.withValues(alpha: 0.2)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAction == ApplianceState.on
                                ? AppColors.accent
                                : AppColors.borderDark,
                            width: _selectedAction == ApplianceState.on ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_rounded,
                                color: _selectedAction == ApplianceState.on
                                    ? AppColors.accent
                                    : AppColors.mutedText),
                            const SizedBox(width: 8),
                            Text('Turn ON',
                                style: TextStyle(
                                  color: _selectedAction == ApplianceState.on
                                      ? AppColors.accent
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: InkWell(
                      onTap: () => setState(() => _selectedAction = ApplianceState.off),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: _selectedAction == ApplianceState.off
                              ? AppColors.secondaryAccent.withValues(alpha: 0.2)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedAction == ApplianceState.off
                                ? AppColors.secondaryAccent
                                : AppColors.borderDark,
                            width: _selectedAction == ApplianceState.off ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.power_off_rounded,
                                color: _selectedAction == ApplianceState.off
                                    ? AppColors.secondaryAccent
                                    : AppColors.mutedText),
                            const SizedBox(width: 8),
                            Text('Turn OFF',
                                style: TextStyle(
                                  color: _selectedAction == ApplianceState.off
                                      ? AppColors.secondaryAccent
                                      : Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
              // Time Picker
              const Text('Execution Time',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              InkWell(
                onTap: _pickTime,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.cardDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderDark),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.access_time_rounded, color: AppColors.accent, size: 24),
                      const SizedBox(width: 14),
                      Text(
                        _selectedTime.format(context),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      const Text('Tap to change',
                          style: TextStyle(color: AppColors.mutedText, fontSize: 12)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
              // Days Selection
              const Text('Repeat Days',
                  style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(7, (i) {
                  final isSelected = _selectedDays.contains(i);
                  return InkWell(
                    onTap: () {
                      setState(() {
                        if (isSelected) {
                          _selectedDays.remove(i);
                        } else {
                          _selectedDays.add(i);
                        }
                      });
                    },
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isSelected ? AppColors.accent : AppColors.cardDark,
                        border: Border.all(
                          color: isSelected ? AppColors.accent : AppColors.borderDark,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          _dayLabels[i],
                          style: TextStyle(
                            color: isSelected ? Colors.white : AppColors.mutedText,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),

              const SizedBox(height: 24),
              // Active toggle
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Schedule Enabled',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    Switch(
                      value: _isEnabled,
                      activeColor: AppColors.accent,
                      onChanged: (val) => setState(() => _isEnabled = val),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEditing ? 'Save Changes' : 'Create Schedule',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
