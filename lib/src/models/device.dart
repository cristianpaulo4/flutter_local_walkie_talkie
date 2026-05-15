/// Represents a discovered Walkie Talkie device on the local network.
class WalkieTalkieDevice {
  /// The unique identifier of the device (usually the service name).
  final String id;

  /// The human-readable name of the device.
  final String name;

  /// The IP address of the device.
  final String ip;

  /// The port on which the device is listening for audio data.
  final int port;

  WalkieTalkieDevice({
    required this.id,
    required this.name,
    required this.ip,
    required this.port,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalkieTalkieDevice &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Device(name: $name, ip: $ip, port: $port)';
}
