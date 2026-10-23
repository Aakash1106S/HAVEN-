/// Global constants for the Haven Smart Home mobile application.
class AppConstants {
  AppConstants._();

  static const String appName = 'Haven';
  static const String appVersion = '1.0.0';

  // Backend command service URL (local development & ESP32 simulator)
  static const String commandServiceUrl = 'http://localhost:8088';

  // MQTT config - replace with your HiveMQ Cloud credentials
  static const String mqttBrokerHost = 'YOUR-HIVEMQ-BROKER.s2.eu.hivemq.cloud';
  static const int mqttBrokerPort = 8883;

  // Command & connection timeouts and retries
  static const int commandTimeoutSeconds = 30;
  static const int maxCommandRetries = 3;
  static const Duration commandExpiry = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);

  // Pagination & limits
  static const int activityPageSize = 20;

  // Local storage keys
  static const String keySelectedHomeId = 'haven_selected_home_id';
  static const String keyAuthToken = 'haven_auth_token';
  static const String keyThemeMode = 'haven_theme_mode';
}
