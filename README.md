# Flutter Local Walkie Talkie 🎙️

A robust Flutter package for peer-to-peer (P2P) voice communication over local Wi-Fi networks. Ideal for situations without internet access, events, or indoor communication.

## ✨ Features

- **Zero-Configuration**: Automatic device discovery using mDNS (Bonsoir).
- **Stable Connection**: Uses the *IP-in-Attributes* method to avoid name resolution failures on unstable networks.
- **Low-Latency Audio**: UDP transmission using PCM 16-bit at 16kHz for maximum fidelity and stability.
- **Push-to-Talk (PTT)**: Simple API to start and stop audio transmission.
- **Modern Support**: Compatible with Android 13+ and 14 permissions.

## 🛠 Technical Details

- **Network Protocol**: UDP (User Datagram Protocol) on port 4545 (configurable).
- **Discovery**: `_wtalkie._udp` protocol via mDNS.
- **Audio Pipeline**: 
  - Recording: `record` (PCM 16-bit).
  - Playback: `flutter_sound` (PCM Stream).

## 🚀 Getting Started

### 1. Permissions Setup

#### Android (`AndroidManifest.xml`)
Add the necessary permissions for audio and network discovery:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<!-- Required for discovery on recent Android versions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

#### iOS (`Info.plist`)
Add keys for microphone and local network usage:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>We need microphone access for radio communication.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>We use the local network to find other nearby radios.</string>
<key>NSBonjourServices</key>
<array>
    <string>_wtalkie._udp</string>
</array>
```

### 2. Basic Usage

```dart
import 'package:flutter_local_walkie_talkie/flutter_local_walkie_talkie.dart';

// 1. Initialize WalkieTalkie
final walkieTalkie = WalkieTalkie();

void setup() async {
  // Request permissions before starting (use permission_handler)
  await walkieTalkie.init(deviceName: "Radio-Alpha");
  
  // 2. Start searching for other devices
  walkieTalkie.startSearching();
  
  // 3. Listen to the list of discovered devices
  walkieTalkie.discoveredDevices.listen((devices) {
    print("Found ${devices.length} active radios");
  });
}

// 4. Connect to a device and talk!
void onTalkPressed(WalkieTalkieDevice peer) async {
  walkieTalkie.connectToDevice(peer);
  await walkieTalkie.startTalking();
}

void onTalkReleased() async {
  await walkieTalkie.stopTalking();
}
```

## 🔍 Troubleshooting

- **Cannot find other devices?**
  - Check if both are on the **same Wi-Fi**.
  - Some routers have "AP Isolation" enabled, which prevents communication between devices.
  - Ensure "Nearby Devices" permission (Android 13+) has been granted.
- **Audio is silent?**
  - Use **Loopback** mode (connecting to IP `127.0.0.1`) to test your own audio hardware.
  - Check if the device's media volume is turned up.

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.
