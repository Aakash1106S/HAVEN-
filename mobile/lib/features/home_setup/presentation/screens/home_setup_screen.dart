import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/di/providers.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/home_model.dart';
import 'package:haven_mobile/shared/models/room_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

// Providers for home setup form state
final _timezoneProvider = StateProvider<String>((ref) => 'Asia/Kolkata');
final _setupStepProvider = StateProvider<int>((ref) => 0);
final _createdHomeIdProvider = StateProvider<String?>((ref) => null);

class HomeSetupScreen extends ConsumerStatefulWidget {
  const HomeSetupScreen({super.key});
  @override
  ConsumerState<HomeSetupScreen> createState() => _HomeSetupScreenState();
}

class _HomeSetupScreenState extends ConsumerState<HomeSetupScreen> {
  final _homeNameCtrl = TextEditingController();
  bool _isCreating = false;

  @override
  void dispose() { _homeNameCtrl.dispose(); super.dispose(); }

  Future<void> _createHome() async {
    if (_homeNameCtrl.text.trim().isEmpty) {
      showErrorSnackBar(context, 'Please enter a home name');
      return;
    }
    setState(() => _isCreating = true);
    try {
      final userId = ref.read(currentUserIdProvider);
      if (userId == null) throw Exception('Not authenticated');
      final home = HomeModel(
        id: '', name: _homeNameCtrl.text.trim(),
        timezone: ref.read(_timezoneProvider),
        ownerId: userId, memberIds: const [],
        createdAt: DateTime.now(), updatedAt: DateTime.now(),
      );
      final homeId = await ref.read(homeRepositoryProvider).createHome(home);
      ref.read(_createdHomeIdProvider.notifier).state = homeId;
      ref.read(_setupStepProvider.notifier).state = 1;
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to create home: $e');
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = ref.watch(_setupStepProvider);
    return Scaffold(
      backgroundColor: const Color(0xFF1A1B2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent, elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Set Up Your Home',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: i <= step ? const Color(0xFF00B4A0) : const Color(0xFF2A3A5A),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: IndexedStack(
                index: step,
                children: [
                  _StepOne(ctrl: _homeNameCtrl, isLoading: _isCreating, onNext: _createHome),
                  _StepTwo(),
                  _StepThree(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepOne extends ConsumerWidget {
  const _StepOne({required this.ctrl, required this.isLoading, required this.onNext});
  final TextEditingController ctrl;
  final bool isLoading;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 24),
      const Icon(Icons.home_rounded, size: 56, color: Color(0xFF00B4A0)),
      const SizedBox(height: 20),
      const Text('Name your home', style: TextStyle(fontSize: 26,
          fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 8),
      const Text('Give your home a name you\'ll recognize.',
          style: TextStyle(color: Color(0xFF8892A4), fontSize: 14)),
      const SizedBox(height: 32),
      TextFormField(
        controller: ctrl,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Home name (e.g. My Home)',
          labelStyle: const TextStyle(color: Color(0xFF8892A4), fontSize: 14),
          filled: true, fillColor: const Color(0xFF0F3460),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00B4A0), width: 2)),
          contentPadding: const EdgeInsets.all(16),
        ),
      ),
      const SizedBox(height: 20),
      DropdownButtonFormField<String>(
        value: ref.watch(_timezoneProvider),
        dropdownColor: const Color(0xFF0F3460),
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: InputDecoration(
          labelText: 'Timezone',
          labelStyle: const TextStyle(color: Color(0xFF8892A4), fontSize: 14),
          filled: true, fillColor: const Color(0xFF0F3460),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.all(16),
        ),
        items: _timezones.map((tz) => DropdownMenuItem(
            value: tz['value'],
            child: Text(tz['label']!, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) ref.read(_timezoneProvider.notifier).state = v; },
      ),
      const Spacer(),
      SizedBox(width: double.infinity, height: 52,
        child: ElevatedButton(
          onPressed: isLoading ? null : onNext,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4A0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0),
          child: isLoading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    ]),
  );
}

class _StepTwo extends ConsumerStatefulWidget {
  @override
  ConsumerState<_StepTwo> createState() => _StepTwoState();
}

class _StepTwoState extends ConsumerState<_StepTwo> {
  final _nameCtrl = TextEditingController();
  String _icon = 'living_room';
  bool _adding = false;
  final List<String> _added = [];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  Future<void> _add() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    final homeId = ref.read(_createdHomeIdProvider);
    if (homeId == null) return;
    setState(() => _adding = true);
    try {
      final room = RoomModel(id: '', homeId: homeId, name: _nameCtrl.text.trim(),
          icon: _icon, order: _added.length, createdAt: DateTime.now());
      await ref.read(roomRepositoryProvider).createRoom(homeId, room);
      setState(() { _added.add(_nameCtrl.text.trim()); _nameCtrl.clear(); });
    } finally { setState(() => _adding = false); }
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(24),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Icon(Icons.meeting_room_rounded, size: 48, color: Color(0xFF00B4A0)),
      const SizedBox(height: 16),
      const Text('Add rooms', style: TextStyle(fontSize: 24,
          fontWeight: FontWeight.w700, color: Colors.white)),
      const SizedBox(height: 6),
      const Text('Add the rooms in your home.',
          style: TextStyle(color: Color(0xFF8892A4), fontSize: 14)),
      const SizedBox(height: 20),
      TextFormField(
        controller: _nameCtrl,
        style: const TextStyle(color: Colors.white),
        textInputAction: TextInputAction.done,
        onFieldSubmitted: (_) => _add(),
        decoration: InputDecoration(
          labelText: 'Room name',
          labelStyle: const TextStyle(color: Color(0xFF8892A4)),
          filled: true, fillColor: const Color(0xFF0F3460),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF00B4A0), width: 2)),
          contentPadding: const EdgeInsets.all(14),
          suffixIcon: _adding
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00B4A0)),
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.add_circle, color: Color(0xFF00B4A0)),
                  onPressed: _add,
                ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(height: 52, child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: RoomModel.roomIcons.length,
        itemBuilder: (ctx, i) {
          final name = RoomModel.roomIcons[i];
          final sel = name == _icon;
          return GestureDetector(
            onTap: () => setState(() => _icon = name),
            child: Container(
              width: 46, height: 46, margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: sel ? const Color(0xFF00B4A0).withOpacity(0.2) : const Color(0xFF0F3460),
                borderRadius: BorderRadius.circular(10),
                border: sel ? Border.all(color: const Color(0xFF00B4A0), width: 2) : null,
              ),
              child: Icon(RoomModel.getIconData(name),
                  color: sel ? const Color(0xFF00B4A0) : const Color(0xFF8892A4), size: 22),
            ),
          );
        },
      )),
      const SizedBox(height: 12),
      Expanded(child: _added.isEmpty
          ? const Center(child: Text('No rooms added yet',
              style: TextStyle(color: Color(0xFF8892A4))))
          : ListView(children: _added.map((r) => ListTile(
              leading: const Icon(Icons.check_circle, color: Color(0xFF00B4A0), size: 20),
              title: Text(r, style: const TextStyle(color: Colors.white)))).toList())),
      Row(children: [
        Expanded(child: OutlinedButton(
          onPressed: () => ref.read(_setupStepProvider.notifier).state = 2,
          style: OutlinedButton.styleFrom(foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF2A3A5A)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14)),
          child: const Text('Skip'))),
        const SizedBox(width: 12),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: () => ref.read(_setupStepProvider.notifier).state = 2,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4A0),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0),
          child: const Text('Continue', style: TextStyle(fontWeight: FontWeight.w600)))),
      ]),
    ]),
  );
}

class _StepThree extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeId = ref.watch(_createdHomeIdProvider);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.developer_board_rounded, size: 48, color: Color(0xFF00B4A0)),
        const SizedBox(height: 16),
        const Text('Connect a device', style: TextStyle(fontSize: 24,
            fontWeight: FontWeight.w700, color: Colors.white)),
        const SizedBox(height: 8),
        const Text('Connect your ESP32 to start controlling appliances.',
            style: TextStyle(color: Color(0xFF8892A4), fontSize: 14, height: 1.5)),
        const SizedBox(height: 24),
        _Info(Icons.wifi_rounded, 'Wi-Fi Required',
            'Your ESP32 must have internet access.'),
        const SizedBox(height: 12),
        _Info(Icons.vpn_key_rounded, 'Pairing Code',
            'You\'ll get a code to paste into your firmware.'),
        const SizedBox(height: 12),
        _Info(Icons.security_rounded, 'Secure Credentials',
            'Each device gets unique MQTT credentials.'),
        const Spacer(),
        SizedBox(width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (homeId != null) {
                context.pushNamed(RouteConstants.devicePairing, extra: homeId);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF00B4A0),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0),
            child: const Text('Add Device', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(width: double.infinity, height: 52,
          child: TextButton(
            onPressed: () => context.go(RouteConstants.dashboardPath),
            child: const Text('Skip for now', style: TextStyle(color: Color(0xFF8892A4), fontSize: 15)),
          )),
      ]),
    );
  }
}

class _Info extends StatelessWidget {
  const _Info(this.icon, this.title, this.body);
  final IconData icon; final String title, body;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF0F3460),
        borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Icon(icon, color: const Color(0xFF00B4A0), size: 22),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white,
              fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 2),
          Text(body, style: const TextStyle(color: Color(0xFF8892A4),
              fontSize: 12, height: 1.4)),
        ])),
    ]),
  );
}

const _timezones = [
  {'value': 'Asia/Kolkata', 'label': 'India (IST)'},
  {'value': 'America/New_York', 'label': 'Eastern (ET)'},
  {'value': 'America/Chicago', 'label': 'Central (CT)'},
  {'value': 'America/Los_Angeles', 'label': 'Pacific (PT)'},
  {'value': 'Europe/London', 'label': 'London (GMT/BST)'},
  {'value': 'Europe/Paris', 'label': 'Central Europe (CET)'},
  {'value': 'Asia/Dubai', 'label': 'Dubai (GST)'},
  {'value': 'Asia/Singapore', 'label': 'Singapore (SGT)'},
  {'value': 'Asia/Tokyo', 'label': 'Tokyo (JST)'},
  {'value': 'Australia/Sydney', 'label': 'Sydney (AET)'},
  {'value': 'UTC', 'label': 'UTC'},
];
