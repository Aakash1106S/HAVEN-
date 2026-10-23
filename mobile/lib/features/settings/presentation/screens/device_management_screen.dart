import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haven_mobile/core/theme/app_colors.dart';
import 'package:haven_mobile/core/constants/route_constants.dart';
import 'package:haven_mobile/core/di/repository_providers.dart';
import 'package:haven_mobile/shared/models/device_model.dart';
import 'package:haven_mobile/core/utils/date_utils.dart';

class DeviceManagementScreen extends ConsumerWidget {
  const DeviceManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final devicesAsync = ref.watch(homeDevicesProvider);
    final home = ref.watch(currentHomeProvider).valueOrNull;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Connected Devices',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (home != null) {
            context.pushNamed(RouteConstants.devicePairing, extra: home.id);
          }
        },
        backgroundColor: AppColors.accent,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add ESP32',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      body: SafeArea(
        child: devicesAsync.when(
          data: (devices) {
            if (devices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.developer_board_off_rounded,
                        size: 56, color: AppColors.mutedText),
                    const SizedBox(height: 16),
                    const Text('No Devices Paired',
                        style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    const Text('Connect your ESP32 microcontrollers to automate your home.',
                        style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: devices.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final d = devices[index];
                final isOnline = d.status == DeviceStatus.online;

                return InkWell(
                  onTap: () => context.push('/settings/devices/${d.id}'),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.borderDark),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: isOnline
                                ? AppColors.online.withValues(alpha: 0.15)
                                : AppColors.offline.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.developer_board_rounded,
                            color: isOnline ? AppColors.online : AppColors.offline,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                d.name,
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'ID: ${d.id} • ${d.channelCount} Channels',
                                style: const TextStyle(color: AppColors.mutedText, fontSize: 12),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isOnline
                                    ? 'Online • Last seen ${d.lastSeenAt != null ? formatRelativeTime(d.lastSeenAt!) : "just now"}'
                                    : 'Offline',
                                style: TextStyle(
                                  color: isOnline ? AppColors.online : AppColors.mutedText,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.mutedText),
                      ],
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.accent)),
          error: (err, _) => Center(
            child: Text('Error: $err', style: const TextStyle(color: AppColors.error)),
          ),
        ),
      ),
    );
  }
}
