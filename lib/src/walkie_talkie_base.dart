import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'discovery_manager.dart';
import 'socket_manager.dart';
import 'models/device.dart';
import 'package:network_info_plus/network_info_plus.dart';

/// The main class for handling local Walkie Talkie functionality.
///
/// This class manages device discovery, audio recording, and playback
/// over the local Wi-Fi network.
class WalkieTalkie {
  final DiscoveryManager _discovery = DiscoveryManager();
  final SocketManager _socket = SocketManager();
  final AudioRecorder _recorder = AudioRecorder();
  final FlutterSoundPlayer _player = FlutterSoundPlayer();

  WalkieTalkieDevice? _connectedDevice;
  bool _isInitialized = false;
  bool _isRecording = false;
  int _localPort = 4545;
  StreamSubscription? _recorderSubscription;
  StreamSubscription? _playerSubscription;

  /// Returns a stream of discovered devices on the local network.
  Stream<List<WalkieTalkieDevice>> get discoveredDevices =>
      _discovery.devicesStream;

  /// Returns a stream of raw audio data received from other devices.
  Stream<Uint8List> get receivedAudioStream => _socket.audioStream;

  /// Initializes the Walkie Talkie service.
  ///
  /// [deviceName] is the name that will be visible to other devices.
  /// [port] is the local UDP port to bind to (default is 4545).
  Future<void> init({String? deviceName, int port = 4545}) async {
    if (_isInitialized) return;

    _localPort = await _socket.init(port);
    await _player.openPlayer();

    try {
      await _player.startPlayerFromStream(
        codec: Codec.pcm16,
        numChannels: 1,
        sampleRate: 16000,
        interleaved: true,
        bufferSize: 8192,
      );
    } catch (e) {
      debugPrint("Error starting player stream: $e");
    }

    // Start playing incoming audio stream
    _playerSubscription = _socket.audioStream.listen((data) {
      try {
        if (_isInitialized && _player.isOpen()) {
          _player.uint8ListSink?.add(data);
        }
      } catch (e) {
        debugPrint("Error feeding audio: $e");
      }
    });

    if (deviceName != null) {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();
      await _discovery.registerService(deviceName, _localPort, ip: ip);
    }

    _isInitialized = true;
  }

  /// Starts searching for other Walkie Talkie devices on the local network.
  Future<void> startSearching() async {
    await _discovery.startDiscovery();
  }

  /// Sets the target device for audio transmission.
  void connectToDevice(WalkieTalkieDevice device) {
    _connectedDevice = device;
  }

  /// Sends raw audio data to the connected device.
  void sendAudio(Uint8List data) {
    if (_connectedDevice != null) {
      _socket.sendAudio(data, _connectedDevice!.ip, _connectedDevice!.port);
    }
  }

  /// Starts recording audio and sending it to the connected device.
  ///
  /// Requires microphone permissions to be granted.
  Future<void> startTalking() async {
    if (_connectedDevice == null || _isRecording) return;

    try {
      if (await _recorder.hasPermission()) {
        _isRecording = true;
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: 16000,
            numChannels: 1,
          ),
        );

        _recorderSubscription = stream.listen((data) {
          _socket.sendAudio(
            Uint8List.fromList(data),
            _connectedDevice!.ip,
            _connectedDevice!.port,
          );
        });
      }
    } catch (e) {
      _isRecording = false;
      debugPrint("Error starting record: $e");
    }
  }

  /// Stops recording and sending audio.
  Future<void> stopTalking() async {
    if (!_isRecording) return;

    try {
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      await _recorder.stop();
    } catch (e) {
      debugPrint("Error stopping record: $e");
    } finally {
      _isRecording = false;
    }
  }

  /// Disposes of all resources used by the Walkie Talkie service.
  void dispose() {
    if (!_isInitialized) return;
    _isInitialized = false;

    _playerSubscription?.cancel();
    _playerSubscription = null;
    _recorderSubscription?.cancel();
    _recorderSubscription = null;

    stopTalking();
    _discovery.dispose();
    _socket.dispose();
    _recorder.dispose();
    if (_player.isOpen()) {
      _player.stopPlayer();
      _player.closePlayer();
    }
  }
}
