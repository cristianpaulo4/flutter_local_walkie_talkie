class WalkieTalkieDevice {
  final String id;
  final String name;
  final String ip;
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
