# Haven Smart Home Automation

> A production-ready smart home automation system for Android and iOS with ESP32 hardware control.

[![Flutter](https://img.shields.io/badge/Flutter-3.41.4-blue.svg)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Latest-orange.svg)](https://firebase.google.com)
[![Node.js](https://img.shields.io/badge/Node.js-22-green.svg)](https://nodejs.org)
[![ESP32](https://img.shields.io/badge/ESP32-Arduino-red.svg)](https://espressif.com)

---

## 📐 Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                         MOBILE APP (Flutter)                         │
│   Authentication │ Dashboard │ Voice │ Schedules │ Notifications     │
└──────────────────────────────┬──────────────────────────────────────┘
                               │ HTTPS + Firebase ID Token
                               ▼
┌─────────────────────────────────────────────────────────────────────┐
│                    COMMAND SERVICE (Cloud Run)                        │
│   Express API │ Auth Middleware │ MQTT Bridge │ Command Expiry       │
└──────────┬───────────────────────────────────┬──────────────────────┘
           │ Firestore real-time               │ MQTT over TLS
           ▼                                   ▼
┌──────────────────┐              ┌─────────────────────────────────┐
│   Firebase       │              │  HiveMQ Cloud MQTT Broker       │
│   Firestore      │              │  (TLS port 8883)                │
│   Auth           │              │  Per-device credentials          │
│   FCM            │              └──────────────┬──────────────────┘
│   App Check      │                             │ MQTT over TLS
└──────────────────┘                             ▼
                               ┌─────────────────────────────────────┐
                               │         ESP32 Firmware               │
                               │  3 Relay channels │ 3 Switch inputs  │
                               │  Wi-Fi │ MQTT │ Command validation    │
                               └─────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────────┐
│                   SCHEDULE SERVICE (Cloud Run)                       │
│   Cloud Scheduler triggers every minute │ Cron evaluation           │
│   Timezone-aware │ Idempotent │ Execution history                   │
└─────────────────────────────────────────────────────────────────────┘
```

---

## 📁 Repository Structure

```
haven/
├── mobile/                    # Flutter application (Android + iOS)
│   ├── android/               # Android project files
│   ├── ios/                   # iOS project files  
│   ├── lib/
│   │   ├── core/              # Theme, routing, DI, constants, services
│   │   ├── features/          # Feature modules
│   │   │   ├── auth/          # Authentication flow
│   │   │   ├── home_setup/    # Onboarding and home creation
│   │   │   ├── dashboard/     # Main dashboard and home tab
│   │   │   ├── rooms/         # Room management
│   │   │   ├── appliances/    # Appliance control detail
│   │   │   ├── devices/       # Device management
│   │   │   ├── schedules/     # Schedule management
│   │   │   ├── voice/         # Voice command processing
│   │   │   ├── notifications/ # Push notifications
│   │   │   ├── activity/      # Activity history
│   │   │   └── settings/      # App settings
│   │   └── shared/            # Models, repositories, widgets
│   ├── test/                  # Flutter tests
│   └── pubspec.yaml
│
├── backend/
│   ├── command-service/       # Cloud Run: API + MQTT bridge
│   └── schedule-service/      # Cloud Run: Schedule execution
│
├── firmware/                  # ESP32 Arduino firmware (PlatformIO)
│   ├── src/
│   │   ├── main.cpp
│   │   ├── hardware_config.h  # ← PIN MAPPING - MUST VERIFY BEFORE FLASHING
│   │   ├── credentials_config.h  # ← DEVICE CREDENTIALS - NOT IN GIT
│   │   └── *.h / *.cpp
│   └── platformio.ini
│
├── firebase/
│   ├── firestore.rules        # Security rules
│   └── firestore.indexes.json
│
├── docs/                      # Additional documentation
├── scripts/                   # Utility scripts
└── README.md
```

---

## 🚀 Quick Start

### Prerequisites

| Tool | Version | Install |
|------|---------|---------|
| Flutter | ≥ 3.41.4 | https://docs.flutter.dev/get-started/install |
| Node.js | ≥ 22 | https://nodejs.org |
| Firebase CLI | Latest | `npm install -g firebase-tools` |
| Git | Latest | https://git-scm.com |
| PlatformIO | Latest | https://platformio.org (for firmware) |

---

## 🔥 Firebase Setup (Required)

### Step 1: Create a Firebase Project

1. Go to https://console.firebase.google.com
2. Click **Add project**
3. Name it `haven-smarthome` (or your choice)
4. Enable Google Analytics (optional)
5. Click **Create project**

### Step 2: Enable Authentication

1. In Firebase console → **Authentication** → **Get started**
2. Under **Sign-in method**, enable:
   - **Email/Password** — Enable both "Email/Password" and "Email link"

### Step 3: Create Firestore Database

1. **Firestore Database** → **Create database**
2. Choose **Start in production mode**
3. Select region: `us-central1` (or your preference)

### Step 4: Register Android App

1. **Project Settings** → **Add app** → Android
2. Android package name: `com.haven.smarthome`
3. Download `google-services.json`
4. Place it at: `mobile/android/app/google-services.json`

### Step 5: Register iOS App

1. **Project Settings** → **Add app** → iOS
2. iOS bundle ID: `com.haven.smarthome`
3. Download `GoogleService-Info.plist`
4. Place it at: `mobile/ios/Runner/GoogleService-Info.plist`

### Step 6: Enable App Check (Recommended for Production)

1. **App Check** → **Get started**
2. Register both apps with their respective providers:
   - Android: **Play Integrity** (or reCAPTCHA for development)
   - iOS: **DeviceCheck** (or App Attest)

### Step 7: Configure Cloud Messaging

1. **Project Settings** → **Cloud Messaging**
2. Note the **Server key** (needed for backend)
3. For iOS: Upload APNs authentication key or certificate

### Step 8: Deploy Security Rules

```bash
cd haven/firebase
firebase login
firebase use --add  # Select your project
firebase deploy --only firestore:rules,firestore:indexes
```

---

## 🌐 MQTT Broker Setup (HiveMQ Cloud)

### Step 1: Create HiveMQ Cloud Account

1. Go to https://www.hivemq.com/mqtt-cloud-broker
2. Create a free account
3. Create a new cluster (free tier supports up to 100 connections)

### Step 2: Note Connection Details

From your HiveMQ dashboard:
- **Broker host**: `your-cluster.s2.eu.hivemq.cloud` (example)
- **Port**: `8883` (TLS)

### Step 3: Create MQTT Credentials

**For the command service:**
1. Go to **Access Management** → **Credentials**
2. Create user: `haven-command-service`
3. Set a strong password
4. Set permissions: Publish and Subscribe to `haven/#`

**For each ESP32 device** (during pairing):
- The pairing API creates per-device credentials automatically
- Pattern: username `device-{deviceId}`, restricted topics

---

## ☁️ Backend Deployment

### Command Service (Cloud Run)

```bash
# Build and deploy
cd haven/backend/command-service

# Create .env from template
cp .env.example .env
# Fill in your values in .env

# Deploy to Cloud Run (requires gcloud CLI)
gcloud run deploy haven-command-service \
  --source . \
  --region us-central1 \
  --platform managed \
  --allow-unauthenticated \
  --set-env-vars FIREBASE_PROJECT_ID=your-project-id \
  --set-env-vars MQTT_BROKER_HOST=your-broker.s2.eu.hivemq.cloud \
  --set-env-vars MQTT_USERNAME=haven-command-service \
  --set-secrets MQTT_PASSWORD=mqtt-command-password:latest

# Note the deployed URL - update AppConstants.commandServiceUrl in mobile app
```

### Schedule Service (Cloud Run)

```bash
cd haven/backend/schedule-service

gcloud run deploy haven-schedule-service \
  --source . \
  --region us-central1 \
  --platform managed \
  --no-allow-unauthenticated \
  --set-env-vars FIREBASE_PROJECT_ID=your-project-id

# Create Cloud Scheduler job (triggers every minute)
gcloud scheduler jobs create http haven-schedule-trigger \
  --schedule="* * * * *" \
  --uri="https://haven-schedule-service-xxxx-uc.a.run.app/execute" \
  --message-body="{}" \
  --headers="Content-Type=application/json" \
  --oidc-service-account-email=your-service-account@your-project.iam.gserviceaccount.com
```

---

## 📱 Flutter Mobile App

### Install Dependencies

```bash
cd haven/mobile
flutter pub get
```

### Configure Firebase

Update the command service URL in:
```
mobile/lib/core/constants/app_constants.dart
```

Add your Firebase config files:
- `mobile/android/app/google-services.json`
- `mobile/ios/Runner/GoogleService-Info.plist`

### Run Development Build

```bash
cd haven/mobile
flutter run  # Runs on connected device/emulator
```

### Android Release Build

```bash
cd haven/mobile

# Create signing keystore (one time)
keytool -genkey -v -keystore android/app/haven-release.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias haven-key

# Create android/key.properties (DO NOT COMMIT)
echo "storePassword=YOUR_KEYSTORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=haven-key
storeFile=haven-release.jks" > android/key.properties

# Build release APK
flutter build apk --release

# Build release AAB (for Play Store)
flutter build appbundle --release

# Output location:
# APK: build/app/outputs/flutter-apk/app-release.apk
# AAB: build/app/outputs/bundle/release/app-release.aab
```

### iOS Build (requires macOS + Xcode)

```bash
cd haven/mobile

# Install CocoaPods dependencies
cd ios && pod install && cd ..

# Build (on macOS only)
flutter build ios --release

# Then open Xcode to sign and archive:
# open ios/Runner.xcworkspace
```

---

## 🔌 ESP32 Firmware

### Prerequisites

- PlatformIO IDE (VS Code extension or CLI)
- ESP32 development board matching your PCB
- USB cable for flashing
- Your PCB schematic for pin verification

### ⚠️ Safety Warning

> **MAINS VOLTAGE DANGER**: This firmware controls relays that may be connected to mains-voltage (120V/240V AC) appliances. NEVER connect mains voltage without qualified electrical verification of all wiring. Incorrectly wired mains voltage can cause fire, electrocution, or death.

### Step 1: Verify Hardware Configuration

Open `firmware/src/hardware_config.h` and verify **every** pin assignment against your PCB schematic:

```cpp
// These MUST match your actual PCB — verify before flashing!
#define RELAY_CH0_PIN  26   // ← Check your schematic
#define RELAY_CH1_PIN  27   // ← Check your schematic
#define RELAY_CH2_PIN  14   // ← Check your schematic
#define SWITCH_CH0_PIN 34   // ← Check your schematic
#define SWITCH_CH1_PIN 35   // ← Check your schematic
#define SWITCH_CH2_PIN 32   // ← Check your schematic
#define RELAY_ACTIVE_HIGH false  // ← Check relay module specs
```

### Step 2: Configure Credentials

1. Create `firmware/src/credentials_config.h` (copy from template or create)
2. Fill in your WiFi, device ID, and MQTT credentials:

```cpp
#define WIFI_SSID      "your_wifi_ssid"
#define WIFI_PASSWORD  "your_wifi_password"
#define DEVICE_ID      "your-device-uuid"   // From Haven app pairing
#define HOME_ID        "your-home-id"        // From Haven app
#define MQTT_USERNAME  "device-your-uuid"    // From Haven app pairing
#define MQTT_PASSWORD  "your-mqtt-password"  // From Haven app pairing
#define MQTT_BROKER_HOST "your-broker.s2.eu.hivemq.cloud"
```

> **Note**: `credentials_config.h` is in `.gitignore` and must NEVER be committed.

### Step 3: Build and Flash

```bash
cd haven/firmware

# Build only (verify compilation)
pio run

# Build and flash to connected ESP32
pio run --target upload

# Monitor serial output
pio device monitor
```

### Step 4: Verify Operation

Watch serial monitor for:
```
[HAVEN] Booting firmware v1.0.0
[HAVEN] Device ID: your-device-uuid
[HAVEN] WiFi connecting...
[HAVEN] WiFi connected. IP: 192.168.x.x
[HAVEN] MQTT connecting...
[HAVEN] MQTT connected
[HAVEN] Initialization complete
```

---

## 🧪 Testing

### Flutter Tests

```bash
cd haven/mobile
flutter test
flutter analyze
```

### Backend Tests

```bash
# Command service tests
cd haven/backend/command-service
npm test

# Schedule service tests
cd haven/backend/schedule-service
npm test
```

### Firebase Emulator (Security Rules Tests)

```bash
# Install Firebase Emulator
npm install -g firebase-tools
firebase login

# Run emulator with rules tests
cd haven/firebase
firebase emulators:start --only firestore
```

---

## 🏗️ Pairing Flow — How to Connect an ESP32

1. **In the Haven app**: Settings → Devices → Add Device
2. **App generates** a 6-character pairing code (e.g., `ABC123`) and displays instructions
3. **Enter code in firmware**: Add `PAIRING_CODE "ABC123"` to `credentials_config.h` and flash
4. **ESP32 connects**: On boot, ESP32 registers with the pairing API
5. **App receives** device credentials and displays them
6. **Re-flash ESP32**: Replace pairing code with received MQTT credentials
7. **Done**: Device appears in the app with 3 controllable channels

---

## 📋 MQTT Topic Reference

| Topic | Direction | QoS | Retained | Description |
|-------|-----------|-----|----------|-------------|
| `haven/{homeId}/{deviceId}/commands/control` | Backend → ESP32 | 1 | No | Control commands |
| `haven/{homeId}/{deviceId}/state/reported` | ESP32 → Backend | 1 | Yes | Full state report |
| `haven/{homeId}/{deviceId}/state/availability` | ESP32 → Backend | 1 | Yes | Online/offline |
| `haven/{homeId}/{deviceId}/ack/command` | ESP32 → Backend | 1 | No | Command acknowledgement |
| `haven/{homeId}/{deviceId}/telemetry` | ESP32 → Backend | 0 | No | RSSI, uptime |

---

## 🔐 Security Model

1. **Mobile → Backend**: Firebase ID token verified on every request. Users cannot publish MQTT commands directly.
2. **Backend → MQTT**: Service-level credentials with full `haven/#` access. Never exposed in mobile app.
3. **ESP32 → MQTT**: Per-device credentials with access only to `haven/{homeId}/{deviceId}/#`.
4. **Firestore**: Security rules prevent cross-user access. State fields updated only by backend.
5. **Command expiry**: Commands have a 30-second TTL. ESP32 checks expiry before executing.
6. **App Check**: Additional layer preventing abuse from unofficial clients.

---

## ⚠️ Known Limitations

1. **iOS build**: Requires macOS with Xcode. Cannot be built on Windows.
2. **Hardware verification**: Pin assignments in `hardware_config.h` use placeholder values and **must** be verified against your PCB schematic before flashing.
3. **Mains voltage**: All mains-connected wiring must be verified by a qualified electrician.
4. **HiveMQ free tier**: Limited to 100 simultaneous connections. Upgrade for more devices.
5. **Physical ESP32 testing**: Firmware has been written and verified for compilation, but real-hardware relay and switch testing requires physical PCB.
6. **iOS Push Notifications**: Requires APNs configuration in Firebase console and Apple Developer account.

---

## 🚦 Production Launch Checklist

- [ ] Firebase project created and configured
- [ ] `google-services.json` and `GoogleService-Info.plist` downloaded and placed
- [ ] Firestore security rules deployed and tested
- [ ] Firestore indexes deployed
- [ ] App Check configured for both platforms
- [ ] HiveMQ Cloud cluster created
- [ ] Command service deployed to Cloud Run
- [ ] Schedule service deployed to Cloud Run  
- [ ] Cloud Scheduler job created (every minute)
- [ ] All secrets stored in Secret Manager (not in code)
- [ ] Android release keystore created and backed up securely
- [ ] iOS provisioning profiles configured (App Store or Ad Hoc)
- [ ] `commandServiceUrl` updated in `app_constants.dart`
- [ ] ESP32 pin assignments verified against PCB schematic
- [ ] Relay polarity verified against relay module datasheet
- [ ] All mains wiring verified by qualified electrician
- [ ] Physical switch behavior tested without internet
- [ ] Schedule timezone behavior tested across midnight
- [ ] Voice command permissions tested on real device
- [ ] FCM notifications tested on both platforms
- [ ] Analytics and crash reporting configured

---

## 📄 License

Haven Smart Home Automation — Private project. All rights reserved.

---

## 🆘 Troubleshooting

### ESP32 not connecting to MQTT
- Check `credentials_config.h` values are correct
- Verify broker hostname (no `https://` prefix)
- Check HiveMQ credentials have correct permissions
- Serial monitor should show connection errors

### App not receiving real-time updates
- Check Firestore security rules allow reads
- Check device is online (verify in Firebase console)
- Check FCM token is registered

### Commands not reaching device
- Check command service is running (Cloud Run logs)
- Check MQTT bridge is connected (command service logs)
- Check device MQTT subscription topics
- Check command hasn't expired (30 second window)

### Voice commands not working
- Check microphone permission is granted in device settings
- Check `speech_to_text` package supports device language
- Ensure appliance names in app match what you're saying
#   H A V E N -  
 