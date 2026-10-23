const mqtt = require('mqtt');
const config = require('../config');
const logger = require('../utils/logger');
const messageHandler = require('./messageHandler');

class MqttClientManager {
  constructor() {
    this.client = null;
    this.isConnected = false;
    this.reconnectAttempts = 0;
    this.maxReconnectDelayMs = 30000;
    this.baseReconnectDelayMs = 1000;
  }

  connect() {
    // Avoid connecting during test runs unless explicitly instructed
    if (process.env.NODE_ENV === 'test' && !process.env.ENABLE_MQTT_TEST) {
      logger.info('MQTT client in test mode: skipping live connection');
      return this;
    }

    if (this.client) {
      return this;
    }

    const options = {
      host: config.mqtt.host,
      port: config.mqtt.port,
      protocol: config.mqtt.useTls ? 'mqtts' : 'mqtt',
      username: config.mqtt.username,
      password: config.mqtt.password,
      clientId: config.mqtt.clientId,
      clean: true,
      connectTimeout: 30000,
      reconnectPeriod: this.baseReconnectDelayMs,
      rejectUnauthorized: true,
    };

    logger.info('Connecting to HiveMQ Cloud MQTT broker', {
      host: config.mqtt.host,
      port: config.mqtt.port,
      protocol: options.protocol,
      clientId: config.mqtt.clientId,
    });

    try {
      this.client = mqtt.connect(options);

      this.client.on('connect', () => {
        this.isConnected = true;
        this.reconnectAttempts = 0;
        logger.info('Successfully connected to HiveMQ MQTT broker');
        this.subscribeToGlobalTopics();
      });

      this.client.on('message', (topic, message) => {
        messageHandler.handleMessage(topic, message).catch((err) => {
          logger.error('Unhandled error in messageHandler', { topic, error: err.message });
        });
      });

      this.client.on('reconnect', () => {
        this.reconnectAttempts += 1;
        const delay = Math.min(
          this.baseReconnectDelayMs * Math.pow(2, this.reconnectAttempts),
          this.maxReconnectDelayMs
        );
        logger.warn(`MQTT reconnecting (attempt ${this.reconnectAttempts}), next delay ~${delay}ms`);
      });

      this.client.on('close', () => {
        this.isConnected = false;
        logger.warn('MQTT connection closed');
      });

      this.client.on('offline', () => {
        this.isConnected = false;
        logger.warn('MQTT client offline');
      });

      this.client.on('error', (err) => {
        logger.error('MQTT client error', { error: err.message, stack: err.stack });
      });
    } catch (error) {
      logger.error('Failed to create MQTT client', { error: error.message });
    }

    return this;
  }

  /**
   * Subscribe to global topics to receive state, ack, and availability messages
   * for all devices managed by this backend service.
   */
  subscribeToGlobalTopics() {
    if (!this.client || !this.isConnected) {
      return;
    }

    const globalTopics = [
      'haven/+/+/state',
      'haven/+/+/state/#',
      'haven/+/+/ack',
      'haven/+/+/availability',
    ];

    this.client.subscribe(globalTopics, { qos: 1 }, (err, granted) => {
      if (err) {
        logger.error('Failed to subscribe to global MQTT topics', { error: err.message });
      } else {
        logger.info('Subscribed to global MQTT topics', {
          topics: granted.map((g) => `${g.topic} (QoS ${g.qos})`),
        });
      }
    });
  }

  /**
   * Subscribes to device-specific topics for a given home and device.
   */
  subscribeToDeviceTopics(homeId, deviceId) {
    if (!this.client || !this.isConnected) {
      logger.warn('Cannot subscribe: MQTT client not connected', { homeId, deviceId });
      return Promise.reject(new Error('MQTT client not connected'));
    }

    const topics = [
      `haven/${homeId}/${deviceId}/state`,
      `haven/${homeId}/${deviceId}/state/#`,
      `haven/${homeId}/${deviceId}/ack`,
      `haven/${homeId}/${deviceId}/availability`,
    ];

    return new Promise((resolve, reject) => {
      this.client.subscribe(topics, { qos: 1 }, (err, granted) => {
        if (err) {
          logger.error('Failed to subscribe to device topics', { homeId, deviceId, error: err.message });
          return reject(err);
        }
        logger.info('Subscribed to device topics', { homeId, deviceId });
        resolve(granted);
      });
    });
  }

  /**
   * Publishes a control command to the device topic:
   * haven/{homeId}/{deviceId}/commands/control
   */
  publishCommand(homeId, deviceId, commandPayload) {
    if (!this.client || !this.isConnected) {
      logger.warn('MQTT client not connected when publishing command', { homeId, deviceId });
      return Promise.reject(new Error('MQTT broker not connected'));
    }

    const topic = `haven/${homeId}/${deviceId}/commands/control`;
    const payload = JSON.stringify(commandPayload);

    return new Promise((resolve, reject) => {
      this.client.publish(topic, payload, { qos: 1 }, (err) => {
        if (err) {
          logger.error('Failed to publish command to MQTT', { topic, error: err.message });
          return reject(err);
        }
        logger.info('Command published to MQTT', { topic, commandId: commandPayload.commandId });
        resolve({ topic, published: true });
      });
    });
  }

  disconnect() {
    return new Promise((resolve) => {
      if (this.client) {
        this.client.end(false, () => {
          this.isConnected = false;
          logger.info('MQTT client disconnected gracefully');
          resolve();
        });
      } else {
        resolve();
      }
    });
  }
}

const mqttClient = new MqttClientManager();

module.exports = mqttClient;
