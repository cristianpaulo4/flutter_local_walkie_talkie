import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_local_walkie_talkie/flutter_local_walkie_talkie.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';

void main() {
  runApp(const WalkieTalkieApp());
}

class WalkieTalkieApp extends StatelessWidget {
  const WalkieTalkieApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Walkie Talkie Local',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const WalkieTalkieHome(),
    );
  }
}

class WalkieTalkieHome extends StatefulWidget {
  const WalkieTalkieHome({super.key});

  @override
  State<WalkieTalkieHome> createState() => _WalkieTalkieHomeState();
}

class _WalkieTalkieHomeState extends State<WalkieTalkieHome> {
  final WalkieTalkie _walkieTalkie = WalkieTalkie();
  List<WalkieTalkieDevice> _devices = [];
  WalkieTalkieDevice? _connectedDevice;
  String? _localIp;
  bool _isTalking = false;
  String _status = "Starting...";

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    // Request permissions
    await [
      Permission.microphone,
      Permission.location,
      Permission.nearbyWifiDevices,
    ].request();

    final info = NetworkInfo();
    _localIp = await info.getWifiIP();

    final deviceInfo = DeviceInfoPlugin();
    String name = "Device";
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      name = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      name = iosInfo.name;
    }

    await _walkieTalkie.init(deviceName: name);
    _walkieTalkie.startSearching();

    _walkieTalkie.discoveredDevices.listen((devices) {
      setState(() {
        _devices = devices;
      });
    });

    setState(() {
      _status = "Ready - IP: $_localIp";
    });
  }

  void _connect(WalkieTalkieDevice device) {
    _walkieTalkie.connectToDevice(device);
    setState(() {
      _connectedDevice = device;
      _status = "Connected to ${device.name}";
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Local Walkie Talkie'),
        actions: [
          IconButton(
            icon: const Icon(Icons.phone_callback),
            tooltip: 'Teste Loopback',
            onPressed: () {
              final selfDevice = WalkieTalkieDevice(
                id: 'self',
                name: 'Teste Local (Loopback)',
                ip: '127.0.0.1',
                port: 4545,
              );
              _connect(selfDevice);
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _walkieTalkie.startSearching(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            color: Colors.black26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Status: $_status",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                if (_connectedDevice != null)
                  Text(
                    "Peer: ${_connectedDevice!.ip}:${_connectedDevice!.port}",
                  ),
              ],
            ),
          ),
          Expanded(
            child: _devices.isEmpty
                ? const Center(child: Text("Searching for devices..."))
                : ListView.builder(
                    itemCount: _devices.length,
                    itemBuilder: (context, index) {
                      final device = _devices[index];
                      final isConnected = _connectedDevice?.id == device.id;
                      return ListTile(
                        leading: const Icon(Icons.phone_android),
                        title: Text(device.name),
                        subtitle: Text("${device.ip}:${device.port}"),
                        trailing: ElevatedButton(
                          onPressed: isConnected
                              ? null
                              : () => _connect(device),
                          child: Text(isConnected ? "Connected" : "Connect"),
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 50.0),
            child: GestureDetector(
              onLongPressStart: (_) {
                if (_connectedDevice != null) {
                  setState(() => _isTalking = true);
                  _walkieTalkie.startTalking();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Connect to a device first!")),
                  );
                }
              },
              onLongPressEnd: (_) {
                setState(() => _isTalking = false);
                _walkieTalkie.stopTalking();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: _isTalking ? Colors.red : Colors.deepPurple,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _isTalking
                          ? Colors.redAccent.withAlpha(128)
                          : Colors.black26,
                      blurRadius: _isTalking ? 20 : 10,
                      spreadRadius: _isTalking ? 10 : 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _isTalking ? Icons.mic : Icons.mic_none,
                        size: 50,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isTalking ? "TALKING..." : "HOLD TO TALK",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _walkieTalkie.dispose();
    super.dispose();
  }
}
