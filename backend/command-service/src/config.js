require('dotenv').config();

module.exports = {
  port: parseInt(process.env.PORT || '8085', 10),
  firebase: {
    projectId: process.env.FIREBASE_PROJECT_ID || 'YOUR-PROJECT-ID',
    // Admin SDK initialized from GOOGLE_APPLICATION_CREDENTIALS or default credentials
  },
  mqtt: {
    host: process.env.MQTT_BROKER_HOST || 'YOUR-HIVEMQ-BROKER.s2.eu.hivemq.cloud',
    port: parseInt(process.env.MQTT_BROKER_PORT || '8883', 10),
    username: process.env.MQTT_USERNAME || 'REPLACE_WITH_HIVEMQ_USERNAME',
    password: process.env.MQTT_PASSWORD || 'REPLACE_WITH_HIVEMQ_PASSWORD',
    clientId: process.env.MQTT_CLIENT_ID || `haven-command-service-${process.pid}`,
    useTls: process.env.MQTT_USE_TLS !== 'false',
  },
  commandTimeout: parseInt(process.env.COMMAND_TIMEOUT_SECONDS || '30', 10),
  allowedOrigins: (process.env.ALLOWED_ORIGINS || '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  schedulerSecret: process.env.SCHEDULER_SECRET || '',
};
