import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../devices/providers/relay_names_provider.dart';
import '../../models/esp32_schedule_model.dart';
import '../../providers/hotspot_schedule_provider.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hotspotScheduleProvider.notifier).refresh();
    });
  }

  void _showAddScheduleSheet([Esp32ScheduleModel? existing]) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => _ScheduleFormSheet(existing: existing),
    );
  }

  void _showTimerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => const _QuickTimerDialog(),
    );
  }

  Future<void> _confirmDelete(int id, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Schedule?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete the schedule for $title?',
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
              backgroundColor: AppColors.secondaryAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final success =
          await ref.read(hotspotScheduleProvider.notifier).deleteSchedule(id);
      if (mounted) {
        if (success) {
          showSuccessSnackBar(context, 'Schedule deleted');
        } else {
          showErrorSnackBar(context, 'Failed to delete schedule on ESP32');
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final schedState = ref.watch(hotspotScheduleProvider);
    final relayNames = ref.watch(relayNamesProvider);
    final notifier = ref.read(hotspotScheduleProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Switch Schedules',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Automated On & Off Timers',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.mutedText,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: schedState.isLoading ? null : () => notifier.refresh(),
            icon: schedState.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.accent,
                    ),
                  )
                : const Icon(Icons.refresh_rounded, color: Colors.white70),
            tooltip: 'Sync with ESP32',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddScheduleSheet(),
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => notifier.refresh(),
          color: AppColors.accent,
          backgroundColor: AppColors.surfaceDark,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            children: [
              // 1. ESP32 Clock & Time Sync Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: schedState.isTimeSynced
                        ? AppColors.online.withValues(alpha: 0.4)
                        : AppColors.warning.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: schedState.isTimeSynced
                            ? AppColors.online.withValues(alpha: 0.15)
                            : AppColors.warning.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        schedState.isTimeSynced
                            ? Icons.access_time_filled_rounded
                            : Icons.access_time_rounded,
                        color: schedState.isTimeSynced
                            ? AppColors.online
                            : AppColors.warning,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'ESP32 Clock: ${schedState.esp32Time}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: schedState.isTimeSynced
                                      ? AppColors.online
                                      : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            schedState.isTimeSynced
                                ? 'Synchronized with phone • Keeps ticking offline'
                                : 'Connect to ESP32_Relay Wi-Fi to sync clock',
                            style: TextStyle(
                              color: schedState.isTimeSynced
                                  ? AppColors.mutedText
                                  : AppColors.warning,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        final ok = await notifier.syncTime();
                        if (context.mounted) {
                          if (ok) {
                            showSuccessSnackBar(context, 'ESP32 clock synced!');
                          } else {
                            showErrorSnackBar(context, 'Make sure phone is connected to ESP32_Relay');
                          }
                        }
                      },
                      icon: const Icon(Icons.sync_rounded, size: 16, color: AppColors.accent),
                      label: const Text('Sync', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        backgroundColor: AppColors.accent.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // 2. Active Countdown Timers Card (if any are active)
              if (schedState.timers.isNotEmpty) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hourglass_bottom_rounded, size: 18, color: AppColors.accent),
                        SizedBox(width: 6),
                        Text(
                          'Active Countdown Timers',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: _showTimerDialog,
                      child: const Text('+ Set Timer', style: TextStyle(color: AppColors.accent, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...schedState.timers.map((t) {
                  final name = relayNames.getName(t.relay);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.accent.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.timer_outlined, color: AppColors.accent, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$name (Relay ${t.relay})',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Turning ${t.turnOn ? "ON" : "OFF"} in ${t.remainingFormatted}',
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.cancel_outlined, color: AppColors.secondaryAccent, size: 20),
                          onPressed: () => notifier.cancelTimer(t.relay),
                          tooltip: 'Cancel Timer',
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ] else ...[
                // Quick Timer Bar when no active timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.timer_outlined, color: AppColors.accent, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Quick Sleep Timer',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _showTimerDialog,
                        icon: const Icon(Icons.add, size: 14),
                        label: const Text('Set Timer', style: TextStyle(fontSize: 12)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent.withValues(alpha: 0.2),
                          foregroundColor: AppColors.accent,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 3. Section Title: Daily Schedules
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_month_rounded, size: 18, color: AppColors.accent),
                      const SizedBox(width: 6),
                      const Text(
                        'Daily Schedules',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${schedState.schedules.length}',
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. Schedules List or Empty State
              if (schedState.schedules.isEmpty)
                Container(
                  margin: const EdgeInsets.only(top: 10),
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent.withValues(alpha: 0.1),
                        ),
                        child: const Icon(Icons.alarm_add_rounded, size: 48, color: AppColors.accent),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No Schedules Set',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Set your appliances to turn ON or OFF automatically at specific times every day.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.mutedText,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        onPressed: () => _showAddScheduleSheet(),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add First Schedule'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...schedState.schedules.map((schedule) {
                  final relayName = relayNames.getName(schedule.relay);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.cardDark,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: schedule.enabled
                            ? AppColors.accent.withValues(alpha: 0.3)
                            : Colors.white.withValues(alpha: 0.05),
                        width: 1.2,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          // Time Display & Action Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: schedule.turnOn
                                  ? AppColors.accent.withValues(alpha: 0.15)
                                  : AppColors.secondaryAccent.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  schedule.turnOn ? 'TURN ON' : 'TURN OFF',
                                  style: TextStyle(
                                    color: schedule.turnOn
                                        ? AppColors.accent
                                        : AppColors.secondaryAccent,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  schedule.timeFormatted,
                                  style: TextStyle(
                                    color: schedule.enabled ? Colors.white : AppColors.mutedText,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),

                          // Target Relay & Repeat Summary
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      schedule.relay == 1
                                          ? Icons.lightbulb_outline
                                          : schedule.relay == 2
                                              ? Icons.mode_fan_off_outlined
                                              : Icons.power_outlined,
                                      size: 16,
                                      color: schedule.enabled ? AppColors.accent : AppColors.mutedText,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '$relayName (Relay ${schedule.relay})',
                                        style: TextStyle(
                                          color: schedule.enabled ? Colors.white : AppColors.mutedText,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  schedule.repeatSummary,
                                  style: const TextStyle(
                                    color: AppColors.mutedText,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Action Buttons: Switch & Trash
                          Switch(
                            value: schedule.enabled,
                            onChanged: (_) => notifier.toggleSchedule(schedule.id),
                            activeTrackColor: AppColors.accent.withValues(alpha: 0.4),
                            activeThumbColor: AppColors.accent,
                            inactiveThumbColor: AppColors.mutedText,
                            inactiveTrackColor: Colors.black26,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded,
                                color: AppColors.mutedText, size: 20),
                            onPressed: () => _confirmDelete(
                              schedule.id,
                              '$relayName at ${schedule.timeFormatted}',
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Add / Edit Schedule Bottom Sheet ────────────────────────────────────────
class _ScheduleFormSheet extends ConsumerStatefulWidget {
  final Esp32ScheduleModel? existing;

  const _ScheduleFormSheet({this.existing});

  @override
  ConsumerState<_ScheduleFormSheet> createState() => _ScheduleFormSheetState();
}

class _ScheduleFormSheetState extends ConsumerState<_ScheduleFormSheet> {
  late int _selectedRelay;
  late bool _turnOn;
  late TimeOfDay _time;
  late List<bool> _daysSelected; // Index 0=Sun, 1=Mon, ..., 6=Sat

  @override
  void initState() {
    super.initState();
    _selectedRelay = widget.existing?.relay ?? 1;
    _turnOn = widget.existing?.turnOn ?? true;
    _time = widget.existing != null
        ? TimeOfDay(hour: widget.existing!.hour, minute: widget.existing!.minute)
        : const TimeOfDay(hour: 18, minute: 30);

    final mask = widget.existing?.daysMask ?? 127;
    _daysSelected = List.generate(7, (i) => (mask & (1 << i)) != 0);
  }

  int get _daysMask {
    int mask = 0;
    for (int i = 0; i < 7; i++) {
      if (_daysSelected[i]) mask |= (1 << i);
    }
    return mask;
  }

  void _selectPreset(String preset) {
    setState(() {
      if (preset == 'all') {
        _daysSelected = List.filled(7, true);
      } else if (preset == 'weekdays') {
        // Mon-Fri (1..5)
        _daysSelected = [false, true, true, true, true, true, false];
      } else if (preset == 'weekends') {
        // Sun (0) + Sat (6)
        _daysSelected = [true, false, false, false, false, false, true];
      }
    });
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time,
      builder: (ctx, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              surface: AppColors.surfaceDark,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relayNames = ref.watch(relayNamesProvider);

    final formattedHour = _time.hourOfPeriod == 0 ? 12 : _time.hourOfPeriod;
    final formattedMinute = _time.minute.toString().padLeft(2, '0');
    final period = _time.period == DayPeriod.am ? 'AM' : 'PM';
    final timeStr = '$formattedHour:$formattedMinute $period';

    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.existing != null ? 'Edit Schedule' : 'New Switch Schedule',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.mutedText),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Choose Switch / Relay
            const Text('SELECT SWITCH',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3].map((r) {
                final isSelected = _selectedRelay == r;
                final name = relayNames.getName(r);
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRelay = r),
                    child: Container(
                      margin: EdgeInsets.only(right: r < 3 ? 8 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected ? AppColors.accent : Colors.white10,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            r == 1
                                ? Icons.lightbulb_outline
                                : r == 2
                                    ? Icons.mode_fan_off_outlined
                                    : Icons.power_outlined,
                            color: isSelected ? AppColors.accent : AppColors.mutedText,
                            size: 20,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            name,
                            style: TextStyle(
                              color: isSelected ? Colors.white : AppColors.mutedText,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Relay $r',
                            style: TextStyle(
                              color: isSelected ? AppColors.accent : Colors.white30,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),

            // 2. Choose Action: ON or OFF
            const Text('ACTION',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _turnOn = true),
                    icon: const Icon(Icons.flash_on_rounded, size: 16),
                    label: const Text('TURN ON', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _turnOn
                          ? AppColors.accent
                          : AppColors.backgroundDark,
                      foregroundColor: _turnOn ? Colors.white : AppColors.mutedText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: _turnOn ? AppColors.accent : Colors.white10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => setState(() => _turnOn = false),
                    icon: const Icon(Icons.flash_off_rounded, size: 16),
                    label: const Text('TURN OFF', style: TextStyle(fontWeight: FontWeight.bold)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_turnOn
                          ? AppColors.secondaryAccent
                          : AppColors.backgroundDark,
                      foregroundColor: !_turnOn ? Colors.white : AppColors.mutedText,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: !_turnOn ? AppColors.secondaryAccent : Colors.white10),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // 3. Time Picker
            const Text('TIME',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickTime,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundDark,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.accent.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time_filled_rounded, color: AppColors.accent, size: 22),
                        const SizedBox(width: 12),
                        Text(
                          timeStr,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                    const Row(
                      children: [
                        Text('Change', style: TextStyle(color: AppColors.accent, fontSize: 13, fontWeight: FontWeight.bold)),
                        SizedBox(width: 4),
                        Icon(Icons.edit, size: 14, color: AppColors.accent),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 4. Repeat Days
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('REPEAT ON',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
                Row(
                  children: [
                    _presetChip('Daily', 'all'),
                    const SizedBox(width: 6),
                    _presetChip('Weekdays', 'weekdays'),
                    const SizedBox(width: 6),
                    _presetChip('Weekends', 'weekends'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(7, (i) {
                final isSelected = _daysSelected[i];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _daysSelected[i] = !_daysSelected[i];
                    });
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? AppColors.accent
                          : AppColors.backgroundDark,
                      border: Border.all(
                        color: isSelected ? AppColors.accent : Colors.white12,
                      ),
                    ),
                    child: Text(
                      dayLabels[i],
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppColors.mutedText,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              }),
            ),

            const SizedBox(height: 28),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (_daysMask == 0) {
                    showErrorSnackBar(context, 'Please select at least one day');
                    return;
                  }

                  final notifier = ref.read(hotspotScheduleProvider.notifier);
                  final success = await notifier.addSchedule(
                    id: widget.existing?.id,
                    relay: _selectedRelay,
                    turnOn: _turnOn,
                    hour: _time.hour,
                    minute: _time.minute,
                    daysMask: _daysMask,
                    enabled: true,
                  );

                  if (context.mounted) {
                    Navigator.pop(context);
                    if (success) {
                      showSuccessSnackBar(context, 'Schedule saved and synced to ESP32!');
                    } else {
                      showInfoSnackBar(context, 'Schedule saved! Will sync when connected to ESP32_Relay.');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Save Schedule',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _presetChip(String label, String preset) {
    return InkWell(
      onTap: () => _selectPreset(preset),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: AppColors.backgroundDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.white12),
        ),
        child: Text(
          label,
          style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// ─── Quick Countdown Timer Dialog ───────────────────────────────────────────
class _QuickTimerDialog extends ConsumerStatefulWidget {
  const _QuickTimerDialog();

  @override
  ConsumerState<_QuickTimerDialog> createState() => _QuickTimerDialogState();
}

class _QuickTimerDialogState extends ConsumerState<_QuickTimerDialog> {
  int _selectedRelay = 1;
  bool _turnOn = false; // Default: Turn OFF after timer
  int _minutes = 30;

  @override
  Widget build(BuildContext context) {
    final relayNames = ref.watch(relayNamesProvider);
    final notifier = ref.read(hotspotScheduleProvider.notifier);

    return AlertDialog(
      backgroundColor: AppColors.surfaceDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Text('Set Countdown Timer',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('SELECT SWITCH',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [1, 2, 3].map((r) {
                final isSelected = _selectedRelay == r;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedRelay = r),
                    child: Container(
                      margin: EdgeInsets.only(right: r < 3 ? 6 : 0),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.accent.withValues(alpha: 0.2)
                            : AppColors.backgroundDark,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSelected ? AppColors.accent : Colors.white10),
                      ),
                      child: Column(
                        children: [
                          Text(relayNames.getName(r),
                              style: TextStyle(
                                  color: isSelected ? Colors.white : AppColors.mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                          Text('R$r',
                              style: TextStyle(
                                  color: isSelected ? AppColors.accent : Colors.white30,
                                  fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            const Text('ACTION',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _turnOn = false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: !_turnOn ? AppColors.secondaryAccent : AppColors.backgroundDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Turn OFF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => setState(() => _turnOn = true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _turnOn ? AppColors.accent : AppColors.backgroundDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Turn ON', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            const Text('TIMER DURATION',
                style: TextStyle(color: AppColors.mutedText, fontSize: 11, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [5, 10, 15, 30, 45, 60, 120].map((mins) {
                final isSelected = _minutes == mins;
                return ChoiceChip(
                  label: Text('${mins}m'),
                  selected: isSelected,
                  selectedColor: AppColors.accent,
                  backgroundColor: AppColors.backgroundDark,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : AppColors.mutedText,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  onSelected: (val) {
                    if (val) setState(() => _minutes = mins);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: AppColors.mutedText)),
        ),
        ElevatedButton(
          onPressed: () async {
            final ok = await notifier.setTimer(
              relay: _selectedRelay,
              turnOn: _turnOn,
              minutes: _minutes,
            );
            if (context.mounted) {
              Navigator.pop(context);
              if (ok) {
                showSuccessSnackBar(
                  context,
                  'Timer started: ${relayNames.getName(_selectedRelay)} will turn ${_turnOn ? "ON" : "OFF"} in ${_minutes}m',
                );
              } else {
                showInfoSnackBar(
                  context,
                  'Timer set locally: ${relayNames.getName(_selectedRelay)} (${_minutes}m). Syncs when connected to ESP32_Relay.',
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Start Timer'),
        ),
      ],
    );
  }
}
