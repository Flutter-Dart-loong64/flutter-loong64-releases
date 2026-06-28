# Release History

This file records the deployment source information for published Loong64 Flutter releases. Binary archives are attached to GitHub Releases; they are not stored in git.

## v3.46.0-1.0.pre-327

- Release date: 2026-06-28
- Flutter SDK version: `3.46.0-1.0.pre-327`
- Flutter framework revision: `69c87127a40b5c0d735611f9026c3b16a2c02369`
- Dart SDK version: `3.13.0-edge.2ea45c8966a8f1769ce4313a80cd829f46144583`
- Dart SDK revision: `2ea45c8966a8f1769ce4313a80cd829f46144583`
- Flutter Engine source revision: `69c87127a40b5c0d735611f9026c3b16a2c02369`
- Engine target: `linux_release_loong64_gtk`
- Engine options: Linux GTK release with `--enable-fontconfig`
- Build host: UOS 25 LoongArch64 new-world
- Validation:
  - `dart --version` reports `linux_loong64`.
  - `flutter --version --suppress-analytics` reports Flutter `3.46.0-1.0.pre-327` and Dart `3.13.0-edge.2ea45c8966a8`.
  - Release archives include Flutter `.git` metadata, Dart SDK, `flutter_tools.snapshot`, and `linux-loong64-release` engine artifacts.
  - `sha256sum -c SHA256SUMS` passes on the UOS 25 build host.
- Assets:
  - `dart-sdk-linux-loong64-3.46.0-1.0.pre-327-2ea45c8966a8.tar.xz`
  - `flutter-engine-linux-loong64-gtk-3.46.0-1.0.pre-327-69c87127a40b.tar.xz`
  - `flutter-sdk-linux-loong64-3.46.0-1.0.pre-327-69c87127a40b.tar.xz`
- SHA256:
  - `5d8de045fc12ba6e51507f76e74f54404b354f5d4bd8d8c68015d9d3682c1c12  dart-sdk-linux-loong64-3.46.0-1.0.pre-327-2ea45c8966a8.tar.xz`
  - `bb1eafb88314885c785e8ad75059c9670c119d3edf44a38d80e6d4f89fab499c  flutter-engine-linux-loong64-gtk-3.46.0-1.0.pre-327-69c87127a40b.tar.xz`
  - `44c3de9444bd9aa895452d174da4ffbfad92f2b2f11c67d54807d0265e67c57c  flutter-sdk-linux-loong64-3.46.0-1.0.pre-327-69c87127a40b.tar.xz`

## v3.45.0-1.0.pre-198

- Release date: 2026-05-24
- Flutter SDK version: `3.45.0-1.0.pre-198`
- Flutter framework revision: `0fed394754392b30db4cbce30170eb91675dc923`
- Dart SDK version: `3.13.0-edge.814677061617134b666f6b5e3bcc42476911014b`
- Dart SDK revision: `814677061617134b666f6b5e3bcc42476911014b`
- Flutter Engine source revision: `0fed394754392b30db4cbce30170eb91675dc923`
- Engine content hash: `a70565e489b0c46279f748952c761e394cea3566`
- Engine target: `linux_release_loong64_gtk`
- Engine options: Linux GTK debug/profile/release with `--enable-fontconfig`
- Validation:
  - `flutter doctor -v` detects `linux-loong64` on UOS 25; Android SDK and Chrome are not installed on the build host.
  - Loong64 debug, profile, and release engine archive targets rebuild successfully after aligning `dart:ui` with the Flutter framework.
  - A newly created Flutter Linux app builds with `flutter build linux --release --target-platform linux-loong64`.
  - The smoke app executable and bundled `libflutter_linux_gtk.so` are LoongArch ELF files.
  - The bundled `libflutter_linux_gtk.so` links to `libfontconfig.so.1`.
- Assets:
  - `dart-sdk-linux-loong64-3.45.0-1.0.pre-198-814677061617.tar.xz`
  - `flutter-engine-linux-loong64-gtk-3.45.0-1.0.pre-198-0fed39475439.tar.xz`
  - `flutter-sdk-linux-loong64-3.45.0-1.0.pre-198-0fed39475439.tar.xz`

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
