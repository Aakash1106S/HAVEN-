enum VoiceAction {
  turnOn,
  turnOff,
  toggle,
  allOn,
  allOff,
  checkStatus,
  setTimer,
  unknown,
}

class VoiceCommandResult {
  final VoiceAction action;
  final int? relayNumber; // 1, 2, or 3 (null for allOn, allOff, checkStatus)
  final int? timerMinutes; // Duration for countdown timer
  final bool? timerTurnOn; // Target state for timer
  final String rawText;
  final String explanation;
  final bool isRecognized;

  const VoiceCommandResult({
    required this.action,
    this.relayNumber,
    this.timerMinutes,
    this.timerTurnOn,
    required this.rawText,
    required this.explanation,
    required this.isRecognized,
  });

  static VoiceCommandResult unhandled(String raw) => VoiceCommandResult(
        action: VoiceAction.unknown,
        rawText: raw,
        explanation: 'Could not recognize command. Try "Turn on Light", "Fan off", or "All off".',
        isRecognized: false,
      );
}

class VoiceCommandParser {
  /// Parses spoken voice text into an actionable ESP32 relay command.
  static VoiceCommandResult parse(
    String spokenText, {
    String name1 = 'Light',
    String name2 = 'Fan',
    String name3 = 'Socket',
  }) {
    String raw = spokenText.toLowerCase().trim();
    if (raw.isEmpty) {
      return VoiceCommandResult.unhandled(spokenText);
    }

    // 1. Remove punctuation
    String text = raw.replaceAll(RegExp(r'[^\w\s]'), ' ');

    // Normalize multiple spaces
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 2. Normalize homophones and common speech-to-text substitutions
    text = text
        .replaceAll(RegExp(r'\bto\b'), '2')
        .replaceAll(RegExp(r'\btoo\b'), '2')
        .replaceAll(RegExp(r'\btwo\b'), '2')
        .replaceAll(RegExp(r'\bsecond\b'), '2')
        .replaceAll(RegExp(r'\b2nd\b'), '2')
        .replaceAll(RegExp(r'\br2\b'), 'relay 2')
        .replaceAll(RegExp(r'\bch2\b'), 'relay 2')
        .replaceAll(RegExp(r'\bone\b'), '1')
        .replaceAll(RegExp(r'\bwon\b'), '1')
        .replaceAll(RegExp(r'\bfirst\b'), '1')
        .replaceAll(RegExp(r'\b1st\b'), '1')
        .replaceAll(RegExp(r'\br1\b'), 'relay 1')
        .replaceAll(RegExp(r'\bch1\b'), 'relay 1')
        .replaceAll(RegExp(r'\bthree\b'), '3')
        .replaceAll(RegExp(r'\btree\b'), '3')
        .replaceAll(RegExp(r'\bfree\b'), '3')
        .replaceAll(RegExp(r'\bthird\b'), '3')
        .replaceAll(RegExp(r'\b3rd\b'), '3')
        .replaceAll(RegExp(r'\br3\b'), 'relay 3')
        .replaceAll(RegExp(r'\bch3\b'), 'relay 3');

    // 3. Check for ALL ON / ALL OFF commands
    final isAllTarget = text.contains('all') ||
        text.contains('everything') ||
        text.contains('every thing') ||
        text.contains('all relays') ||
        text.contains('all devices') ||
        text.contains('all switches') ||
        text.contains('all appliances') ||
        text.contains('both');

    if (isAllTarget) {
      // Check OFF keywords
      if (_hasOffAction(text)) {
        return VoiceCommandResult(
          action: VoiceAction.allOff,
          rawText: spokenText,
          explanation: 'Turning OFF all relays',
          isRecognized: true,
        );
      }
      // Check ON keywords
      if (_hasOnAction(text)) {
        return VoiceCommandResult(
          action: VoiceAction.allOn,
          rawText: spokenText,
          explanation: 'Turning ON all relays',
          isRecognized: true,
        );
      }
    }

    // Direct exact phrases for all
    if (text == 'all on' || text == 'turn on all' || text == 'everything on') {
      return VoiceCommandResult(
        action: VoiceAction.allOn,
        rawText: spokenText,
        explanation: 'Turning ON all relays',
        isRecognized: true,
      );
    }
    if (text == 'all off' || text == 'turn off all' || text == 'everything off') {
      return VoiceCommandResult(
        action: VoiceAction.allOff,
        rawText: spokenText,
        explanation: 'Turning OFF all relays',
        isRecognized: true,
      );
    }

    // 4. Check for status queries
    if (text.contains('status') ||
        text.contains('check relays') ||
        text.contains('what is on') ||
        text.contains('what is off') ||
        text.contains('state')) {
      return VoiceCommandResult(
        action: VoiceAction.checkStatus,
        rawText: spokenText,
        explanation: 'Checking relay status',
        isRecognized: true,
      );
    }

    // 5. Detect Countdown Timers (e.g. "turn off light in 15 minutes", "fan off in 30 mins")
    int? timerMinutes;
    final matchMinutes = RegExp(r'\b(?:in|after)\s+(\d+)\s*(?:minute|min|mins|minutes|m)\b').firstMatch(text);
    if (matchMinutes != null) {
      timerMinutes = int.tryParse(matchMinutes.group(1)!);
    } else if (text.contains('in half an hour') || text.contains('after half an hour')) {
      timerMinutes = 30;
    } else if (text.contains('in an hour') || text.contains('in 1 hour') || text.contains('after 1 hour')) {
      timerMinutes = 60;
    }

    // 6. Detect Target Relay (1, 2, or 3)
    int? targetRelay = _detectTargetRelay(text, name1, name2, name3);

    // If timer detected with target relay
    if (timerMinutes != null && targetRelay != null) {
      final turnOn = _hasOnAction(text); // default to false (turn off) if off or unspecified
      final displayName = targetRelay == 1
          ? name1
          : targetRelay == 2
              ? name2
              : name3;
      final actionStr = turnOn ? 'ON' : 'OFF';

      return VoiceCommandResult(
        action: VoiceAction.setTimer,
        relayNumber: targetRelay,
        timerMinutes: timerMinutes,
        timerTurnOn: turnOn,
        rawText: spokenText,
        explanation: 'Setting timer: $displayName (Relay $targetRelay) will turn $actionStr in $timerMinutes minutes',
        isRecognized: true,
      );
    }

    // 7. Detect Action (ON, OFF, TOGGLE)
    VoiceAction? action;
    if (_hasOffAction(text)) {
      action = VoiceAction.turnOff;
    } else if (_hasOnAction(text)) {
      action = VoiceAction.turnOn;
    } else if (text.contains('toggle') || text.contains('flip') || text.contains('change')) {
      action = VoiceAction.toggle;
    }

    // If only relay or device was spoken (e.g. "Relay 1" or "Light"), toggle it
    if (targetRelay != null && action == null) {
      action = VoiceAction.toggle;
    }

    if (targetRelay != null && action != null) {
      final actionStr = action == VoiceAction.turnOn
          ? 'Turning ON'
          : action == VoiceAction.turnOff
              ? 'Turning OFF'
              : 'Toggling';

      final displayName = targetRelay == 1
          ? name1
          : targetRelay == 2
              ? name2
              : name3;

      return VoiceCommandResult(
        action: action,
        relayNumber: targetRelay,
        rawText: spokenText,
        explanation: '$actionStr Relay $targetRelay ($displayName)',
        isRecognized: true,
      );
    }

    return VoiceCommandResult.unhandled(spokenText);
  }

  static bool _hasOffAction(String text) {
    final offPatterns = [
      'turn off',
      'switch off',
      'power off',
      'put off',
      'shut down',
      'shut off',
      'close',
      'stop',
      'disable',
      'deactivate',
      'cut off',
      'bandh',
      'off pannu',
    ];

    for (final p in offPatterns) {
      if (text.contains(p)) return true;
    }

    // Standalone "off" (e.g., "relay 1 off", "light off", "off light")
    final words = text.split(' ');
    return words.contains('off');
  }

  static bool _hasOnAction(String text) {
    final onPatterns = [
      'turn on',
      'switch on',
      'power on',
      'put on',
      'start',
      'open',
      'enable',
      'activate',
      'chalu',
      'podu',
      'on pannu',
    ];

    for (final p in onPatterns) {
      if (text.contains(p)) return true;
    }

    // Standalone "on" (e.g., "relay 1 on", "light on", "on light")
    final words = text.split(' ');
    return words.contains('on');
  }

  static int? _detectTargetRelay(String text, String name1, String name2, String name3) {
    // 1. Direct explicit digit checks
    if (text.contains('relay 1') ||
        text.contains('switch 1') ||
        text.contains('channel 1') ||
        text.contains('number 1') ||
        text.contains('no 1') ||
        text.contains('device 1') ||
        text.contains('relay1') ||
        RegExp(r'\b1\b').hasMatch(text)) {
      return 1;
    }

    if (text.contains('relay 2') ||
        text.contains('switch 2') ||
        text.contains('channel 2') ||
        text.contains('number 2') ||
        text.contains('no 2') ||
        text.contains('device 2') ||
        text.contains('relay2') ||
        RegExp(r'\b2\b').hasMatch(text)) {
      return 2;
    }

    if (text.contains('relay 3') ||
        text.contains('switch 3') ||
        text.contains('channel 3') ||
        text.contains('number 3') ||
        text.contains('no 3') ||
        text.contains('device 3') ||
        text.contains('relay3') ||
        RegExp(r'\b3\b').hasMatch(text)) {
      return 3;
    }

    // 2. Custom names matching (exact or substring or plural)
    if (_matchesName(text, name1)) return 1;
    if (_matchesName(text, name2)) return 2;
    if (_matchesName(text, name3)) return 3;

    // 3. Common device categories fallbacks
    // Relay 1 commonly lights
    if (text.contains('light') ||
        text.contains('lights') ||
        text.contains('bulb') ||
        text.contains('bulbs') ||
        text.contains('lamp') ||
        text.contains('lamps') ||
        text.contains('led') ||
        text.contains('tube')) {
      return 1;
    }

    // Relay 2 commonly fans
    if (text.contains('fan') ||
        text.contains('fans') ||
        text.contains('cooler') ||
        text.contains('coolers') ||
        text.contains('exhaust') ||
        text.contains('ventilator')) {
      return 2;
    }

    // Relay 3 commonly sockets, plugs, chargers, appliances
    if (text.contains('socket') ||
        text.contains('sockets') ||
        text.contains('plug') ||
        text.contains('plugs') ||
        text.contains('charger') ||
        text.contains('motor') ||
        text.contains('pump') ||
        text.contains('heater') ||
        text.contains('ac') ||
        text.contains('air conditioner') ||
        text.contains('tv')) {
      return 3;
    }

    return null;
  }

  static bool _matchesName(String text, String targetName) {
    final cleanTarget = targetName.toLowerCase().trim();
    if (cleanTarget.isEmpty) return false;

    // Exact or direct substring
    if (text.contains(cleanTarget)) return true;

    // Plural / singular variants (e.g. "light" vs "lights")
    if (cleanTarget.endsWith('s') && text.contains(cleanTarget.substring(0, cleanTarget.length - 1))) {
      return true;
    }
    if (!cleanTarget.endsWith('s') && text.contains('${cleanTarget}s')) {
      return true;
    }

    // Check individual words if multi-word name (e.g. "Living Light" matches "light")
    final words = cleanTarget.split(RegExp(r'\s+'));
    for (final w in words) {
      if (w.length >= 3 && text.contains(w)) {
        return true;
      }
    }

    return false;
  }
}
