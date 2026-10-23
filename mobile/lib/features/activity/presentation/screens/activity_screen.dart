import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/core/utils/date_utils.dart';
import 'package:haven_mobile/core/utils/snackbar_utils.dart';

class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  Future<void> _markAllRead(BuildContext context, WidgetRef ref) async {
    final home = ref.read(currentHomeProvider).valueOrNull;
    if (home == null) return;
    try {
      await ref.read(activityRepositoryProvider).markAllRead(home.id);
      showSuccessSnackBar(context, 'All activities marked as read');
    } catch (e) {
      showErrorSnackBar(context, 'Failed to update activities: $e');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(homeActivityProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Activity Feed',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        actions: [
          IconButton(
            onPressed: () => _markAllRead(context, ref),
            icon: const Icon(Icons.done_all_rounded, color: AppColors.accent),
            tooltip: 'Mark All Read',
          ),
        ],
      ),
      body: SafeArea(
        child: activityAsync.when(
          data: (events) {
            if (events.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded,
                          size: 48, color: AppColors.mutedText),
                    ),
                    const SizedBox(height: 16),
                    const Text('No Activity Yet',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text(
                      'Appliance controls, schedule events, and hardware\nstatus changes will appear here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.mutedText, fontSize: 13, height: 1.5),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: events.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final ev = events[index];
                final isUnread = !ev.read;

                return InkWell(
                  onTap: () {
                    if (isUnread && home != null) {
                      ref.read(activityRepositoryProvider).markEventRead(home.id, ev.id);
                    }
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isUnread
                          ? AppColors.surfaceDark
                          : AppColors.backgroundDark,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isUnread ? AppColors.accent.withValues(alpha: 0.4) : AppColors.borderDark,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: ev.color.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(ev.icon, color: ev.color, size: 20),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      ev.title,
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    formatRelativeTime(ev.createdAt),
                                    style: const TextStyle(color: AppColors.mutedText, fontSize: 11),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ev.message,
                                style: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                        if (isUnread) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: AppColors.accent,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (err, _) => Center(
            child: Text('Error loading activity: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}
