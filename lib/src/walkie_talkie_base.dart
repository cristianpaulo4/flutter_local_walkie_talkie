import 'dart:async';
import 'dart:typed_data';
import 'package:record/record.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'discovery_manager.dart';
import 'socket_manager.dart';
import 'models/device.dart';
import 'package:network_info_plus/network_info_plus.dart';

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

  Stream<List<WalkieTalkieDevice>> get discoveredDevices => _discovery.devicesStream;
  Stream<Uint8List> get receivedAudioStream => _socket.audioStream;

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
      print("Error starting player stream: $e");
    }
    
    // Start playing incoming audio stream
    _playerSubscription = _socket.audioStream.listen((data) {
      try {
        if (_isInitialized && _player.isOpen()) {
          _player.uint8ListSink?.add(data);
        }
      } catch (e) {
        print("Error feeding audio: $e");
      }
    });

    if (deviceName != null) {
      final info = NetworkInfo();
      String? ip = await info.getWifiIP();
      await _discovery.registerService(deviceName, _localPort, ip: ip);
    }
    
    _isInitialized = true;
  }

  Future<void> startSearching() async {
    await _discovery.startDiscovery();
  }

  void connectToDevice(WalkieTalkieDevice device) {
    _connectedDevice = device;
  }

  void sendAudio(Uint8List data) {
    if (_connectedDevice != null) {
      _socket.sendAudio(data, _connectedDevice!.ip, _connectedDevice!.port);
    }
  }

  Future<void> startTalking() async {
    if (_connectedDevice == null || _isRecording) return;
    
    try {
      if (await _recorder.hasPermission()) {
        _isRecording = true;
        final stream = await _recorder.startStream(const RecordConfig(
          encoder: AudioEncoder.pcm16bits,
          sampleRate: 16000,
          numChannels: 1,
        ));

        _recorderSubscription = stream.listen((data) {
          _socket.sendAudio(Uint8List.fromList(data), _connectedDevice!.ip, _connectedDevice!.port);
        });
      }
    } catch (e) {
      _isRecording = false;
      print("Error starting record: $e");
    }
  }

  Future<void> stopTalking() async {
    if (!_isRecording) return;
    
    try {
      await _recorderSubscription?.cancel();
      _recorderSubscription = null;
      await _recorder.stop();
    } catch (e) {
      print("Error stopping record: $e");
    } finally {
      _isRecording = false;
    }
  }

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
