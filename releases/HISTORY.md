# Release History

This file records the deployment source information for published Loong64 Flutter releases. Binary archives are attached to GitHub Releases; they are not stored in git.

## v3.45.0-1.0.pre-174

- Release date: 2026-05-22
- Flutter SDK version: `3.45.0-1.0.pre-174`
- Flutter framework revision: `d2285105069eeaaae77619ddf63627bf646dcbf4`
- Dart SDK version: `3.13.0-127.0.dev`
- Dart SDK revision: `e650d226331b076d4bd008992b9efd39604e3756`
- Flutter Engine source revision: `d2285105069eeaaae77619ddf63627bf646dcbf4`
- Engine content hash: `6f13d76618c7235203458cb1b67b0dbb6fb15af9`
- Engine target: `linux_release_loong64_gtk_current_fc`
- Engine options: Linux GTK release with `--enable-fontconfig`
- Validation:
  - `flutter doctor -v` detects `linux-loong64` on UOS 25.
  - A newly created Flutter Linux app builds with `flutter build linux --release`.
  - The smoke app starts on a LoongArch64 desktop with the software renderer and stays running.
- Assets:
  - `dart-sdk-linux-loong64-3.45.0-1.0.pre-174-e650d226331b.tar.xz`
  - `flutter-engine-linux-loong64-gtk-3.45.0-1.0.pre-174-d2285105069e.tar.xz`
  - `flutter-sdk-linux-loong64-3.45.0-1.0.pre-174-d2285105069e.tar.xz`

## v2026.05.20.1

- Release date: 2026-05-20
- Flutter SDK version: `3.44.0-1.0.pre-616`
- Flutter framework revision: `9b43981fc5d61f877795b4dad64d0cc67671753d`
- Dart SDK revision: `ae9f14de38050f38180626ad07d8252ee2e968f5`
- Flutter Engine source revision: `a7a98649a2c80b8a9839795680853428ff6de311`
- Engine target: `linux_release_loong64_gtk`
- Engine options: Linux GTK release with `--enable-fontconfig`
- Assets:
  - `dart-sdk-linux-loong64-20260520.1-ae9f14de3805.tar.xz`
  - `flutter-engine-linux-loong64-gtk-20260520.1-a7a98649a2c8-dartae9f14de3805-fontconfig.tar.xz`
  - `flutter-sdk-linux-loong64-20260520.1-9b43981fc5d6-dartae9f14de3805-enginea7a98649a2c8-fontconfig.tar.xz`

## v2026.05.20

- Release date: 2026-05-20
- Flutter framework revision: `9b43981fc5d61f877795b4dad64d0cc67671753d`
- Dart SDK revision: `ae9f14de38050f38180626ad07d8252ee2e968f5`
- Flutter Engine source revision: `9566565161822e45062ea333e8a86eb1fd595935`
- Engine target: `linux_release_loong64_gtk`
- Assets:
  - `dart-sdk-linux-loong64-20260520-ae9f14de3805.tar.xz`
  - `flutter-engine-linux-loong64-gtk-20260520-956656516182-dartae9f14de3805.tar.xz`
  - `flutter-sdk-linux-loong64-20260520-9b43981fc5d6-dartae9f14de3805-engine956656516182.tar.xz`
