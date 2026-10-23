import 'package:flutter_test/flutter_test.dart';
import 'package:haven_mobile/features/voice/services/voice_command_parser.dart';

void main() {
  group('VoiceCommandParser', () {
    test('Recognizes numbers and actions', () {
      final r1 = VoiceCommandParser.parse('turn on relay 1');
      expect(r1.isRecognized, true);
      expect(r1.action, VoiceAction.turnOn);
      expect(r1.relayNumber, 1);

      final r2 = VoiceCommandParser.parse('turn off relay 2');
      expect(r2.isRecognized, true);
      expect(r2.action, VoiceAction.turnOff);
      expect(r2.relayNumber, 2);

      final r3 = VoiceCommandParser.parse('relay 3 on');
      expect(r3.isRecognized, true);
      expect(r3.action, VoiceAction.turnOn);
      expect(r3.relayNumber, 3);
    });

    test('Recognizes words for numbers (one, two, to, too, three, first, second)', () {
      final r1 = VoiceCommandParser.parse('turn on relay one');
      expect(r1.action, VoiceAction.turnOn);
      expect(r1.relayNumber, 1);

      final r2 = VoiceCommandParser.parse('switch off relay to');
      expect(r2.action, VoiceAction.turnOff);
      expect(r2.relayNumber, 2);

      final r3 = VoiceCommandParser.parse('turn off relay three');
      expect(r3.action, VoiceAction.turnOff);
      expect(r3.relayNumber, 3);
    });

    test('Recognizes common appliances (light, fan, socket)', () {
      final lightOn = VoiceCommandParser.parse('turn on light');
      expect(lightOn.action, VoiceAction.turnOn);
      expect(lightOn.relayNumber, 1);

      final lightsOff = VoiceCommandParser.parse('lights off');
      expect(lightsOff.action, VoiceAction.turnOff);
      expect(lightsOff.relayNumber, 1);

      final fanOff = VoiceCommandParser.parse('switch off the fan');
      expect(fanOff.action, VoiceAction.turnOff);
      expect(fanOff.relayNumber, 2);

      final socketOn = VoiceCommandParser.parse('plug on');
      expect(socketOn.action, VoiceAction.turnOn);
      expect(socketOn.relayNumber, 3);
    });

    test('Recognizes ALL ON and ALL OFF', () {
      final allOn1 = VoiceCommandParser.parse('all on');
      expect(allOn1.action, VoiceAction.allOn);

      final allOn2 = VoiceCommandParser.parse('turn on all appliances');
      expect(allOn2.action, VoiceAction.allOn);

      final allOff1 = VoiceCommandParser.parse('all off');
      expect(allOff1.action, VoiceAction.allOff);

      final allOff2 = VoiceCommandParser.parse('everything off');
      expect(allOff2.action, VoiceAction.allOff);
    });

    test('Recognizes custom relay names', () {
      final res = VoiceCommandParser.parse(
        'turn on chandelier',
        name1: 'Chandelier',
        name2: 'Exhaust',
        name3: 'Water Pump',
      );
      expect(res.action, VoiceAction.turnOn);
      expect(res.relayNumber, 1);

      final res2 = VoiceCommandParser.parse(
        'pump off',
        name1: 'Chandelier',
        name2: 'Exhaust',
        name3: 'Water Pump',
      );
      expect(res2.action, VoiceAction.turnOff);
      expect(res2.relayNumber, 3);
    });

    test('Recognizes countdown timers', () {
      final t1 = VoiceCommandParser.parse('turn off light in 15 minutes');
      expect(t1.isRecognized, true);
      expect(t1.action, VoiceAction.setTimer);
      expect(t1.relayNumber, 1);
      expect(t1.timerMinutes, 15);
      expect(t1.timerTurnOn, false);

      final t2 = VoiceCommandParser.parse('fan on in 30 mins');
      expect(t2.isRecognized, true);
      expect(t2.action, VoiceAction.setTimer);
      expect(t2.relayNumber, 2);
      expect(t2.timerMinutes, 30);
      expect(t2.timerTurnOn, true);
    });
  });
}
