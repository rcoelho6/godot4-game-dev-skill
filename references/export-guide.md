# Guia de Exportação Godot 4

## PC (Windows / Linux / macOS)

1. Editor > Manage Export Templates → Download
2. Project > Export > Add → selecionar plataforma
3. Clicar em **Export Project**

## Android

### Pré-requisitos
- [OpenJDK 17](https://adoptium.net/temurin/releases/?variant=openjdk17&version=17)
- Android Studio (para instalar o SDK)
  - SDK Platform-Tools ≥ 35.0.0
  - Build-Tools 35.0.1
  - Platform 35
  - NDK r28b (28.1.13356709)
  - CMake 3.10.2.4988404

### Configurar no Godot
Editor Settings → Export → Android:
- `Java SDK Path`: caminho do JDK 17
- `Android SDK Path`: caminho do SDK (deve conter `platform-tools/adb`)

### Gerar keystore (necessário para Google Play)
```bash
keytool -v -genkey -keystore mygame.keystore -alias mygame -keyalg RSA -validity 10000
```

### Exportar
- APK: para testes diretos
- AAB: obrigatório para Google Play (requer Gradle build habilitado)

## iOS

### Pré-requisitos
- macOS com Xcode instalado
- Apple Developer account (para distribuição)
- Export Templates instalados no Godot

### Passos
1. Project > Export > Add > iOS
2. Preencher **App Store Team ID** e **Bundle Identifier** (ex: `com.empresa.jogo`)
3. Export Project → gera pasta com projeto Xcode (`.xcodeproj`)
4. Abrir no Xcode → Build & Run ou Archive para App Store

### Observações
- iOS simulator: apenas renderer `Compatibility`
- C# tem suporte experimental; prefira GDScript para evitar problemas
- Para builds frequentes durante dev: linkar a pasta do projeto Godot diretamente no Xcode

## Checklist antes de exportar

- [ ] Ícones configurados (Project Settings > Application > Boot Splash / Icons)
- [ ] Nome e versão do app definidos
- [ ] Física e input testados na resolução alvo
- [ ] Renderer adequado selecionado (Mobile para Android/iOS)
- [ ] Export Templates instalados para a plataforma alvo
