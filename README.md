# Flutter Local Walkie Talkie 🎙️

Um package Flutter robusto para comunicação de voz ponto a ponto (P2P) em redes Wi-Fi locais. Ideal para situações sem internet, eventos ou comunicação interna em ambientes fechados.

## ✨ Recursos

- **Zero-Configuração**: Descoberta automática de dispositivos usando mDNS (Bonsoir).
- **Conexão Estável**: Utiliza o método *IP-in-Attributes* para evitar falhas de resolução de nomes em redes instáveis.
- **Áudio de Baixa Latência**: Transmissão via UDP utilizando o formato PCM 16-bit a 16kHz para máxima fidelidade e estabilidade.
- **Push-to-Talk (PTT)**: API simples para iniciar e parar a transmissão de áudio.
- **Suporte Moderno**: Compatível com as permissões do Android 13+ e 14.

## 🛠 Detalhes Técnicos

- **Protocolo de Rede**: UDP (User Datagram Protocol) na porta 4545 (configurável).
- **Descoberta**: Protocolo `_wtalkie._udp` via mDNS.
- **Pipeline de Áudio**: 
  - Gravação: `record` (PCM 16-bit).
  - Reprodução: `flutter_sound` (PCM Stream).

## 🚀 Como Começar

### 1. Configuração de Permissões

#### Android (`AndroidManifest.xml`)
Adicione as permissões necessárias para áudio e descoberta de rede:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CHANGE_WIFI_MULTICAST_STATE" />
<uses-permission android:name="android.permission.ACCESS_WIFI_STATE" />
<!-- Necessário para descoberta em versões recentes do Android -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" />
<uses-permission android:name="android.permission.NEARBY_WIFI_DEVICES" />
```

#### iOS (`Info.plist`)
Adicione as chaves para microfone e rede local:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>Precisamos de acesso ao microfone para a comunicação via rádio.</string>
<key>NSLocalNetworkUsageDescription</key>
<string>Usamos a rede local para encontrar outros rádios próximos.</string>
<key>NSBonjourServices</key>
<array>
    <string>_wtalkie._udp</string>
</array>
```

### 2. Uso Básico

```dart
import 'package:flutter_local_walkie_talkie/flutter_local_walkie_talkie.dart';

// 1. Inicialize o WalkieTalkie
final walkieTalkie = WalkieTalkie();

void setup() async {
  // Solicite permissões antes de iniciar (use permission_handler)
  await walkieTalkie.init(deviceName: "Radio-Alpha");
  
  // 2. Comece a procurar por outros dispositivos
  walkieTalkie.startSearching();
  
  // 3. Escute a lista de dispositivos encontrados
  walkieTalkie.discoveredDevices.listen((devices) {
    print("Encontrados ${devices.length} rádios ativos");
  });
}

// 4. Conecte-se a um dispositivo e fale!
void onTalkPressed(WalkieTalkieDevice peer) async {
  walkieTalkie.connectToDevice(peer);
  await walkieTalkie.startTalking();
}

void onTalkReleased() async {
  await walkieTalkie.stopTalking();
}
```

## 🔍 Solução de Problemas

- **Não encontro outros aparelhos?**
  - Verifique se ambos estão no **mesmo Wi-Fi**.
  - Alguns roteadores têm o "Isolamento de AP" ativado, o que impede a comunicação entre dispositivos.
  - Certifique-se de que a permissão de "Dispositivos Próximos" (Android 13+) foi concedida.
- **O áudio está mudo?**
  - Use o modo **Loopback** (conectando-se ao IP `127.0.0.1`) para testar seu próprio hardware de áudio.
  - Verifique se o volume de mídia do aparelho está alto.

## 📄 Licença

Este projeto está licenciado sob a licença MIT - veja o arquivo LICENSE para detalhes.
