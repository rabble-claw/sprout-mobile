# Sprout Mobile (standalone)

UniFFI-exposed Rust core for Sprout iOS and Android apps, plus minimal Android/iOS shells.

Quick start:

- `just mobile-setup` — installs Rust targets, checks cargo-ndk/JDK/SDK
- `just mobile-android` — builds all 4 ABIs and generates Kotlin bindings
- `./android/gradlew :sproutmobile:assembleDebug` — builds the AAR
- `just mobile-ios` — builds static libs and assembles an XCFramework, generates Swift bindings

This crate depends on `sprout-core` and `sprout-sdk` from the upstream Sprout repo via git.
