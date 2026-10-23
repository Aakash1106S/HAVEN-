class Esp32ScheduleModel {
  final int id;
  final int relay; // 1, 2, or 3
  final bool turnOn; // true = ON, false = OFF
  final int hour; // 0-23
  final int minute; // 0-59
  final int daysMask; // bit 0=Sun, 1=Mon, ..., 6=Sat (127=Every day)
  final bool enabled;

  const Esp32ScheduleModel({
    required this.id,
    required this.relay,
    required this.turnOn,
    required this.hour,
    required this.minute,
    this.daysMask = 127,
    this.enabled = true,
  });

  String get timeFormatted {
    final h = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    final m = minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    return '$h:$m $period';
  }

  String get repeatSummary {
    if (daysMask == 127) return 'Every day';
    if (daysMask == 62) return 'Weekdays'; // Mon-Fri: 2+4+8+16+32 = 62
    if (daysMask == 65) return 'Weekends'; // Sun (1) + Sat (64) = 65

    const dayNames = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    final selected = <String>[];
    for (int i = 0; i < 7; i++) {
      if ((daysMask & (1 << i)) != 0) {
        selected.add(dayNames[i]);
      }
    }
    return selected.isEmpty ? 'Never' : selected.join(', ');
  }

  factory Esp32ScheduleModel.fromJson(Map<String, dynamic> json) {
    return Esp32ScheduleModel(
      id: json['id'] as int? ?? 0,
      relay: json['relay'] as int? ?? 1,
      turnOn: (json['action'] as String? ?? 'on') == 'on',
      hour: json['hour'] as int? ?? 0,
      minute: json['minute'] as int? ?? 0,
      daysMask: json['days'] as int? ?? 127,
      enabled: json['enabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'relay': relay,
        'action': turnOn ? 'on' : 'off',
        'hour': hour,
        'minute': minute,
        'days': daysMask,
        'enabled': enabled,
      };

  Esp32ScheduleModel copyWith({
    int? id,
    int? relay,
    bool? turnOn,
    int? hour,
    int? minute,
    int? daysMask,
    bool? enabled,
  }) {
    return Esp32ScheduleModel(
      id: id ?? this.id,
      relay: relay ?? this.relay,
      turnOn: turnOn ?? this.turnOn,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysMask: daysMask ?? this.daysMask,
      enabled: enabled ?? this.enabled,
    );
  }
}

class Esp32TimerModel {
  final int relay;
  final bool turnOn;
  final int remainingSeconds;
  final int totalSeconds;

  const Esp32TimerModel({
    required this.relay,
    required this.turnOn,
    required this.remainingSeconds,
    required this.totalSeconds,
  });

  String get remainingFormatted {
    final m = remainingSeconds ~/ 60;
    final s = remainingSeconds % 60;
    if (m > 0) {
      return '${m}m ${s}s';
    }
    return '${s}s';
  }

  factory Esp32TimerModel.fromJson(Map<String, dynamic> json) {
    return Esp32TimerModel(
      relay: json['relay'] as int? ?? 1,
      turnOn: (json['action'] as String? ?? 'off') == 'on',
      remainingSeconds: json['remaining'] as int? ?? 0,
      totalSeconds: json['total'] as int? ?? 0,
    );
  }
}
