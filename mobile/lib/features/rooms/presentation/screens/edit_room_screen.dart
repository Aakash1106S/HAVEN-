import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/room_model.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class EditRoomScreen extends ConsumerStatefulWidget {
  final String roomId;
  const EditRoomScreen({super.key, required this.roomId});

  @override
  ConsumerState<EditRoomScreen> createState() => _EditRoomScreenState();
}

class _EditRoomScreenState extends ConsumerState<EditRoomScreen> {
  final _nameCtrl = TextEditingController();
  String _selectedIcon = 'living_room';
  bool _initialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  void _initFromRoom(RoomModel room) {
    if (!_initialized) {
      _nameCtrl.text = room.name;
      _selectedIcon = room.icon;
      _initialized = true;
    }
  }

  Future<void> _save(RoomModel room) async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      showErrorSnackBar(context, 'Please enter a room name');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = room.copyWith(name: name, icon: _selectedIcon);
      await ref.read(roomRepositoryProvider).updateRoom(room.homeId, updated);
      if (mounted) {
        showSuccessSnackBar(context, 'Room updated successfully');
        context.pop();
      }
    } catch (e) {
      if (mounted) showErrorSnackBar(context, 'Failed to update room: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteRoom(RoomModel room) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        title: const Text('Delete Room?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        content: Text(
          'Are you sure you want to delete "${room.name}"? Any connected appliances will be moved to unassigned.',
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
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(roomRepositoryProvider).deleteRoom(room.homeId, room.id);
        if (mounted) {
          showSuccessSnackBar(context, 'Room deleted');
          context.go('/dashboard');
        }
      } catch (e) {
        if (mounted) showErrorSnackBar(context, 'Failed to delete room: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = ref.watch(homeRoomsProvider).valueOrNull ?? [];
    final room = rooms.firstWhere(
      (r) => r.id == widget.roomId,
      orElse: () => RoomModel(
        id: '',
        homeId: '',
        name: '',
        icon: 'living_room',
        order: 0,
        createdAt: DateTime.now(),
      ),
    );

    if (room.id.isNotEmpty) {
      _initFromRoom(room);
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Edit Room',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () => _deleteRoom(room),
            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
            tooltip: 'Delete Room',
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Room Name',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameCtrl,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.cardDark,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.accent, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Room Icon',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600)),
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
                            color: isSelected ? AppColors.accent : AppColors.borderDark,
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
                                color: isSelected ? AppColors.accent : AppColors.mutedText,
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
                  onPressed: _isSaving ? null : () => _save(room),
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
                      : const Text('Save Changes',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
