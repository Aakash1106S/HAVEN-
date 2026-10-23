import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/room_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class AddRoomScreen extends ConsumerStatefulWidget {
  final String homeId;
  const AddRoomScreen({super.key, required this.homeId});

  @override
  ConsumerState<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends ConsumerState<AddRoomScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'living_room';
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Please enter a room name');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final effectiveHomeId = widget.homeId.isNotEmpty
          ? widget.homeId
          : ref.read(currentHomeProvider).valueOrNull?.id ?? '';

      if (effectiveHomeId.isEmpty) {
        throw Exception('No active home found');
      }

      final rooms = ref.read(homeRoomsProvider).valueOrNull ?? [];
      final room = RoomModel(
        id: '',
        homeId: effectiveHomeId,
        name: name,
        icon: _selectedIcon,
        order: rooms.length,
        createdAt: DateTime.now(),
      );

      await ref.read(roomRepositoryProvider).createRoom(effectiveHomeId, room);
      if (mounted) {
        showSuccessSnackBar(context, 'Room "$name" added successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to add room: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Add Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Room Name',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'e.g. Master Bedroom, Balcony',
                  hintStyle: const TextStyle(color: AppColors.mutedText),
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Select Icon',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: RoomModel.roomIcons.length,
                  itemBuilder: (context, index) {
                    final iconKey = RoomModel.roomIcons[index];
                    final isSelected = iconKey == _selectedIcon;
                    return InkWell(
                      onTap: () => setState(() => _selectedIcon = iconKey),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.accent.withValues(alpha: 0.25)
                              : AppColors.cardDark,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.accent
                                : AppColors.borderDark,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              RoomModel.getIconData(iconKey),
                              color: isSelected ? AppColors.accent : Colors.white,
                              size: 28,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              iconKey.replaceAll('_', ' '),
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                color: isSelected
                                    ? AppColors.accent
                                    : AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Create Room',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
