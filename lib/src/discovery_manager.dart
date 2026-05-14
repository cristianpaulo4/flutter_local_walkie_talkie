import 'dart:async';
import 'package:bonsoir/bonsoir.dart';
import 'models/device.dart';

class DiscoveryManager {
  static const String serviceType = '_wtalkie._udp';
  final _devicesController = StreamController<List<WalkieTalkieDevice>>.broadcast();
  final Set<WalkieTalkieDevice> _foundDevices = {};
  
  BonsoirDiscovery? _discovery;
  BonsoirBroadcast? _broadcast;

  Stream<List<WalkieTalkieDevice>> get devicesStream => _devicesController.stream;

  Future<void> startDiscovery() async {
    _discovery = BonsoirDiscovery(type: serviceType);
    await _discovery!.initialize();
    
    _discovery!.eventStream!.listen((event) {
      if (event is BonsoirDiscoveryServiceFoundEvent) {
        print('Service found: ${event.service.name}. Resolving...');
        event.service.resolve(_discovery!.serviceResolver);
      } else if (event is BonsoirDiscoveryServiceResolvedEvent) {
        final service = event.service;
        
        // Prioritize IP from attributes, then fallback to host
        String? ipFromAttr = service.attributes?['ip'];
        String ipAddress = (ipFromAttr != null && ipFromAttr.isNotEmpty) ? ipFromAttr : (service.host ?? '');
        
        // Clean up the IP if it has leading slash (sometimes happens on Android)
        if (ipAddress.startsWith('/')) {
          ipAddress = ipAddress.substring(1);
        }

        final device = WalkieTalkieDevice(
          id: service.name,
          name: service.name,
          ip: ipAddress, 
          port: service.port,
        );
        
        if (ipAddress.isEmpty) {
          print('Warning: Resolved service ${device.name} but IP is empty.');
        } else {
          print('Successfully resolved: ${device.name} at ${device.ip}:${device.port} (Source: ${ipFromAttr != null ? 'Attribute' : 'Host'})');
        }

        if (!_foundDevices.contains(device)) {
          _foundDevices.add(device);
          _devicesController.add(_foundDevices.toList());
        }
      } else if (event is BonsoirDiscoveryServiceLostEvent) {
        final serviceName = event.service?.name;
        if (serviceName != null) {
          print('Service lost: $serviceName');
          _foundDevices.removeWhere((d) => d.id == serviceName);
          _devicesController.add(_foundDevices.toList());
        }
      }
    });
    
    await _discovery!.start();
  }

  Future<void> stopDiscovery() async {
    if (_discovery != null) {
      await _discovery!.stop();
      _discovery = null;
    }
  }

  Future<void> registerService(String name, int port, {String? ip}) async {
    final Map<String, String> attributes = {
      'info': 'WalkieTalkie Device',
    };
    if (ip != null) {
      attributes['ip'] = ip;
    }

    final service = BonsoirService(
      name: name,
      type: serviceType,
      port: port,
      attributes: attributes,
    );
    _broadcast = BonsoirBroadcast(service: service);
    await _broadcast!.initialize();
    
    _broadcast!.eventStream!.listen((event) {
      print('Broadcast event: $event');
    });

    await _broadcast!.start();
  }

  Future<void> unregisterService() async {
    if (_broadcast != null) {
      await _broadcast!.stop();
      _broadcast = null;
    }
  }

  void dispose() {
    stopDiscovery();
    unregisterService();
    _devicesController.close();
  }
}
