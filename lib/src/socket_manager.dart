import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

class SocketManager {
  RawDatagramSocket? _socket;
  final _audioStreamController = StreamController<Uint8List>.broadcast();
  final _statusController = StreamController<String>.broadcast();
  
  Stream<Uint8List> get audioStream => _audioStreamController.stream;
  Stream<String> get statusStream => _statusController.stream;

  Future<int> init(int port) async {
    _socket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, port);
    _socket!.listen((RawSocketEvent event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _socket!.receive();
        if (dg != null) {
          _audioStreamController.add(Uint8List.fromList(dg.data));
        }
      }
    });
    return _socket!.port;
  }

  void sendAudio(Uint8List data, String targetIp, int targetPort) {
    if (_socket != null && targetIp.isNotEmpty) {
      try {
        print('Sending ${data.length} bytes to $targetIp:$targetPort');
        _socket!.send(data, InternetAddress(targetIp), targetPort);
      } catch (e) {
        print("Error sending audio to $targetIp: $e");
        _statusController.add("Error sending audio: $e");
      }
    }
  }

  void dispose() {
    _socket?.close();
    _audioStreamController.close();
    _statusController.close();
  }
}
