/// Route names and paths used across Haven Smart Home GoRouter configuration.
class RouteConstants {
  RouteConstants._();

  // ── Route Names ──
  static const String splash = 'splash';
  static const String welcome = 'welcome';
  static const String onboarding = 'onboarding';
  static const String login = 'login';
  static const String register = 'register';
  static const String forgotPassword = 'forgotPassword';
  static const String emailVerification = 'emailVerification';

  static const String homeSetup = 'homeSetup';
  static const String addRoom = 'addRoom';
  static const String devicePairing = 'devicePairing';
  static const String deviceConfig = 'deviceConfig';

  static const String dashboard = 'dashboard';
  static const String roomDetail = 'roomDetail';
  static const String applianceDetail = 'applianceDetail';

  static const String schedules = 'schedules';
  static const String scheduleCreate = 'scheduleCreate';
  static const String scheduleEdit = 'scheduleEdit';

  static const String activity = 'activity';
  static const String notifications = 'notifications';
  static const String settings = 'settings';

  static const String deviceManagement = 'deviceManagement';
  static const String deviceDetail = 'deviceDetail';
  static const String voiceControl = 'voiceControl';

  static const String profile = 'profile';
  static const String deleteAccount = 'deleteAccount';
  static const String editRoom = 'editRoom';
  static const String notificationSettings = 'notificationSettings';
  static const String pairDevice = 'pairDevice';
  static const String voicePath = '/voice';

  // ── Route Paths ──
  static const String splashPath = '/';
  static const String welcomePath = '/welcome';
  static const String onboardingPath = '/onboarding';
  static const String loginPath = '/login';
  static const String registerPath = '/register';
  static const String forgotPasswordPath = '/forgot-password';
  static const String emailVerificationPath = '/email-verification';

  static const String homeSetupPath = '/home-setup';
  static const String addRoomPath = '/add-room';
  static const String devicePairingPath = '/device-pairing';
  static const String deviceConfigPath = '/device-config';

  static const String dashboardPath = '/dashboard';
  static const String roomDetailPath = '/dashboard/room/:roomId';
  static const String applianceDetailPath = '/dashboard/room/:roomId/appliance/:channelId';

  static const String schedulesPath = '/schedules';
  static const String scheduleCreatePath = '/schedules/create';
  static const String scheduleEditPath = '/schedules/edit/:scheduleId';

  static const String activityPath = '/activity';
  static const String settingsPath = '/settings';
  static const String settingsProfilePath = '/settings/profile';
  static const String settingsDevicesPath = '/settings/devices';
  static const String settingsDeviceDetailPath = '/settings/devices/:deviceId';
  static const String settingsNotificationsPath = '/settings/notifications';
  static const String deleteAccountPath = '/settings/delete-account';

  static const String voiceControlPath = '/voice';
}
