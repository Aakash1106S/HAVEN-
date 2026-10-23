import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/features/devices/providers/esp32_hotspot_provider.dart';
import 'package:haven_mobile/features/devices/providers/relay_names_provider.dart';
import 'package:haven_mobile/features/voice/services/voice_command_parser.dart';
import 'package:haven_mobile/features/schedules/providers/hotspot_schedule_provider.dart';

class VoiceControlScreen extends ConsumerStatefulWidget {
  const VoiceControlScreen({super.key});

  @override
  ConsumerState<VoiceControlScreen> createState() => _VoiceControlScreenState();
}

class _VoiceControlScreenState extends ConsumerState<VoiceControlScreen>
    with SingleTickerProviderStateMixin {
  late stt.SpeechToText _speech;
  late FlutterTts _tts;

  bool _isListening = false;
  bool _speechAvailable = false;
  String _transcription = 'Tap the microphone to speak';
  String? _resultMessage;
  bool? _commandSuccess;
  final _textFallbackCtrl = TextEditingController();

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnimation;
  Timer? _silenceTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _initTts();

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );

    _initSpeech();
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage("en-US");
      await _tts.setPitch(1.0);
      await _tts.setSpeechRate(0.5);
    } catch (_) {}
  }

  Future<void> _speak(String text) async {
    try {
      await _tts.speak(text);
    } catch (_) {}
  }

  Future<void> _initSpeech() async {
    try {
      final micStatus = await Permission.microphone.status;
      if (!micStatus.isGranted) {
        final req = await Permission.microphone.request();
        if (!req.isGranted) {
          if (mounted) {
            setState(() {
              _speechAvailable = false;
              _resultMessage = 'Microphone permission denied. Tap to grant.';
            });
          }
          return;
        }
      }

      final available = await _speech.initialize(
        onError: (val) {
          if (mounted) {
            setState(() {
              _isListening = false;
              if (_transcription == 'Listening...') {
                _transcription = 'Tap microphone to speak';
              }
            });
            _pulseCtrl.stop();
          }
        },
        onStatus: (val) {
          if (val == 'done' || val == 'notListening') {
            if (_isListening && mounted) {
              _finishListening();
            }
          }
        },
      );
      if (mounted) {
        setState(() => _speechAvailable = available);
      }
    } catch (_) {
      if (mounted) setState(() => _speechAvailable = false);
    }
  }

  @override
  void dispose() {
    _silenceTimer?.cancel();
    _pulseCtrl.dispose();
    _textFallbackCtrl.dispose();
    _speech.stop();
    _tts.stop();
    super.dispose();
  }

  Future<void> _toggleListening() async {
    if (_isListening) {
      _finishListening();
    } else {
      _startListening();
    }
  }

  Future<void> _startListening() async {
    // Check & request microphone permission
    final micStatus = await Permission.microphone.status;
    if (!micStatus.isGranted) {
      final req = await Permission.microphone.request();
      if (!req.isGranted) {
        setState(() {
          _resultMessage = 'Microphone permission is required for voice control. Please grant it in app settings.';
          _commandSuccess = false;
        });
        return;
      }
    }

    if (!_speechAvailable) {
      await _initSpeech();
      if (!_speechAvailable) {
        setState(() {
          _resultMessage = 'Speech recognition service is unavailable. You can type commands below.';
          _commandSuccess = false;
        });
        return;
      }
    }

    setState(() {
      _isListening = true;
      _transcription = 'Listening...';
      _resultMessage = null;
      _commandSuccess = null;
    });
    _pulseCtrl.repeat(reverse: true);

    try {
      await _speech.listen(
        onResult: (val) {
          if (!mounted) return;
          setState(() {
            _transcription = val.recognizedWords;
          });

          // If speech recognizer finalized result, execute immediately!
          if (val.finalResult) {
            _finishListening();
            return;
          }

          // Otherwise reset silence timer
          _silenceTimer?.cancel();
          _silenceTimer = Timer(const Duration(milliseconds: 2000), () {
            if (_isListening && mounted) {
              _finishListening();
            }
          });
        },
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          cancelOnError: false,
          partialResults: true,
        ),
      );
    } catch (e) {
      _finishListening();
    }
  }

  void _finishListening() {
    _silenceTimer?.cancel();
    _speech.stop();
    _pulseCtrl.stop();
    if (mounted) {
      setState(() => _isListening = false);
    }
    if (_transcription.isNotEmpty && _transcription != 'Listening...') {
      _executeSpokenCommand(_transcription);
    }
  }

  Future<void> _executeSpokenCommand(String spokenText) async {
    final relayNames = ref.read(relayNamesProvider);
    final parsed = VoiceCommandParser.parse(
      spokenText,
      name1: relayNames.relay1,
      name2: relayNames.relay2,
      name3: relayNames.relay3,
    );

    if (!parsed.isRecognized) {
      setState(() {
        _resultMessage = parsed.explanation;
        _commandSuccess = false;
      });
      _speak("Could not recognize command. Please try again.");
      return;
    }

    final notifier = ref.read(esp32RelayNotifierProvider.notifier);
    final hotspotService = ref.read(esp32HotspotServiceProvider);

    setState(() {
      _resultMessage = 'Executing: ${parsed.explanation}...';
    });

    try {
      switch (parsed.action) {
        case VoiceAction.turnOn:
          final ch = parsed.relayNumber ?? 1;
          await hotspotService.setRelayState(ch, true);
          await notifier.checkConnectionAndRefresh(silent: true);
          final chName = relayNames.getName(ch);
          final msg = '$chName (Relay $ch) turned ON';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.turnOff:
          final ch = parsed.relayNumber ?? 1;
          await hotspotService.setRelayState(ch, false);
          await notifier.checkConnectionAndRefresh(silent: true);
          final chName = relayNames.getName(ch);
          final msg = '$chName (Relay $ch) turned OFF';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.toggle:
          final ch = parsed.relayNumber ?? 1;
          await notifier.toggleRelay(ch);
          final currentState = ref.read(esp32RelayNotifierProvider).relays[ch] ?? false;
          final chName = relayNames.getName(ch);
          final msg = '$chName is now ${currentState ? "ON" : "OFF"}';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.allOn:
          await notifier.setAllRelays(true);
          const msg = 'All relays turned ON';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.allOff:
          await notifier.setAllRelays(false);
          const msg = 'All relays turned OFF';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.checkStatus:
          await notifier.checkConnectionAndRefresh(silent: true);
          final states = ref.read(esp32RelayNotifierProvider).relays;
          final s1 = (states[1] ?? false) ? "ON" : "OFF";
          final s2 = (states[2] ?? false) ? "ON" : "OFF";
          final s3 = (states[3] ?? false) ? "ON" : "OFF";
          final msg = 'Relay 1 is $s1, Relay 2 is $s2, Relay 3 is $s3';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.setTimer:
          final ch = parsed.relayNumber ?? 1;
          final mins = parsed.timerMinutes ?? 30;
          final turnOn = parsed.timerTurnOn ?? false;
          await ref.read(hotspotScheduleProvider.notifier).setTimer(relay: ch, turnOn: turnOn, minutes: mins);
          final chName = relayNames.getName(ch);
          final msg = '$chName will turn ${turnOn ? "ON" : "OFF"} in $mins minutes';
          setState(() {
            _resultMessage = msg;
            _commandSuccess = true;
          });
          _speak(msg);
          break;

        case VoiceAction.unknown:
          break;
      }
    } catch (e) {
      setState(() {
        _resultMessage = 'Command error: $e';
        _commandSuccess = false;
      });
      _speak("Error executing command.");
    }
  }

  @override
  Widget build(BuildContext context) {
    final espState = ref.watch(esp32RelayNotifierProvider);
    final relayNames = ref.watch(relayNamesProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'ESP32 Voice Control',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: Navigator.of(context).canPop()
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              // Connection Status Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: espState.isConnected
                      ? AppColors.online.withValues(alpha: 0.15)
                      : AppColors.warning.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: espState.isConnected ? AppColors.online : AppColors.warning,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: espState.isConnected ? AppColors.online : AppColors.warning,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      espState.isConnected
                          ? 'Connected to ESP32_Relay (192.168.4.1)'
                          : 'Connect phone to ESP32_Relay Wi-Fi',
                      style: TextStyle(
                        color: espState.isConnected ? AppColors.online : AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Animated Pulsing Microphone Button
              GestureDetector(
                onTap: _toggleListening,
                child: ScaleTransition(
                  scale: _isListening
                      ? _pulseAnimation
                      : const AlwaysStoppedAnimation(1.0),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: _isListening
                            ? [AppColors.secondaryAccent, Colors.redAccent]
                            : [AppColors.accent, const Color(0xFF0F3460)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.5)
                              : AppColors.accent.withValues(alpha: 0.4),
                          blurRadius: _isListening ? 30 : 20,
                          spreadRadius: _isListening ? 8 : 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      _isListening ? Icons.mic : Icons.mic_none,
                      color: Colors.white,
                      size: 54,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Text(
                _isListening ? 'Listening... Speak now' : 'Tap to Speak',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 24),

              // Spoken text display
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12),
                ),
                child: Text(
                  _transcription,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _transcription == 'Listening...' ||
                            _transcription == 'Tap the microphone to speak'
                        ? AppColors.mutedText
                        : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              // Result Message & Icon
              if (_resultMessage != null) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: (_commandSuccess == true)
                        ? AppColors.online.withValues(alpha: 0.15)
                        : AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: (_commandSuccess == true)
                          ? AppColors.online.withValues(alpha: 0.4)
                          : AppColors.error.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        (_commandSuccess == true)
                            ? Icons.check_circle
                            : Icons.error_outline,
                        color: (_commandSuccess == true)
                            ? AppColors.online
                            : AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _resultMessage!,
                          style: TextStyle(
                            color: (_commandSuccess == true)
                                ? Colors.white
                                : AppColors.error,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Quick Voice Command Suggestions
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Quick Voice Commands',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _buildCommandChip('Turn on Relay 1', 'Turn on relay 1'),
                  _buildCommandChip('Turn off Relay 1', 'Turn off relay 1'),
                  _buildCommandChip('${relayNames.relay1} ON', 'Turn on ${relayNames.relay1}'),
                  _buildCommandChip('${relayNames.relay2} OFF', 'Turn off ${relayNames.relay2}'),
                  _buildCommandChip('${relayNames.relay3} ON', 'Turn on ${relayNames.relay3}'),
                  _buildCommandChip('All ON', 'All on'),
                  _buildCommandChip('All OFF', 'All off'),
                  _buildCommandChip('Check Status', 'Check status'),
                ],
              ),

              const SizedBox(height: 32),

              // Manual Text Input Fallback
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textFallbackCtrl,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type command (e.g. "Relay 1 on")',
                        hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (txt) {
                        if (txt.trim().isNotEmpty) {
                          _executeSpokenCommand(txt);
                          _textFallbackCtrl.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_textFallbackCtrl.text.trim().isNotEmpty) {
                        _executeSpokenCommand(_textFallbackCtrl.text);
                        _textFallbackCtrl.clear();
                      }
                    },
                    icon: const Icon(Icons.send_rounded, color: AppColors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCommandChip(String label, String command) {
    return ActionChip(
      label: Text(
        label,
        style: const TextStyle(color: Colors.white70, fontSize: 12),
      ),
      backgroundColor: AppColors.surfaceDark,
      side: const BorderSide(color: Colors.white12),
      onPressed: () => _executeSpokenCommand(command),
    );
  }
}
