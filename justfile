# Mobile build tasks for sprout-mobile standalone repo

mobile_lib_name := "libsprout_mobile"
ios_targets := "aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios"
android_jni_root := "android/sproutmobile/src/main/jniLibs"
ios_out := "ios/Frameworks/SproutCore.xcframework"
ios_swift_out := "ios/Sources/SproutMobile"
android_kotlin_out := "android/sproutmobile/src/main/java"

mobile-targets:
    rustup target add aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
    rustup target add aarch64-linux-android armv7-linux-androideabi x86_64-linux-android i686-linux-android

mobile-setup:
    #!/usr/bin/env bash
    set -euo pipefail
    echo "==> Checking mobile build prerequisites…"
    just mobile-targets
    if ! command -v cargo-ndk >/dev/null 2>&1; then
      echo "• cargo-ndk not found — installing…"; cargo install cargo-ndk; fi
    if [ -z "${ANDROID_HOME:-}" ] && [ ! -d "$HOME/Library/Android/sdk" ]; then
      echo "• ANDROID_HOME not set — ensure Android SDK installed"; fi
    if [ -x /usr/libexec/java_home ] && /usr/libexec/java_home -v 17 >/dev/null 2>&1; then
      echo "• JDK 17 OK"; else echo "• Ensure JDK 17 installed"; fi
    if [ ! -x android/gradlew ]; then echo "• Gradle wrapper missing; install gradle and run 'gradle wrapper' in android/"; fi
    echo "✓ Mobile prerequisites checked."

mobile-android:
    #!/usr/bin/env bash
    set -euo pipefail
    cargo ndk -t arm64-v8a -t armeabi-v7a -t x86_64 -t x86 -o "{{android_jni_root}}" build --release
    just mobile-kotlin-bindings

mobile-kotlin-bindings:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p "{{android_kotlin_out}}"
    cargo run --bin uniffi-bindgen --release -- \
      generate --library "target/aarch64-linux-android/release/{{mobile_lib_name}}.so" \
      --language kotlin --out-dir "{{android_kotlin_out}}"

mobile-ios:
    #!/usr/bin/env bash
    set -euo pipefail
    for t in {{ios_targets}}; do cargo build --release --target "$t"; done
    mkdir -p target/ios-sim-universal/release
    lipo -create \
      target/aarch64-apple-ios-sim/release/{{mobile_lib_name}}.a \
      target/x86_64-apple-ios/release/{{mobile_lib_name}}.a \
      -output target/ios-sim-universal/release/{{mobile_lib_name}}.a
    rm -rf {{ios_out}}; mkdir -p $(dirname {{ios_out}})
    xcodebuild -create-xcframework \
      -library target/aarch64-apple-ios/release/{{mobile_lib_name}}.a \
      -library target/ios-sim-universal/release/{{mobile_lib_name}}.a \
      -output {{ios_out}}
    just mobile-swift-bindings

mobile-swift-bindings:
    #!/usr/bin/env bash
    set -euo pipefail
    mkdir -p {{ios_swift_out}}
    cargo run --bin uniffi-bindgen --release -- \
      generate --library target/aarch64-apple-ios/release/{{mobile_lib_name}}.a \
      --language swift --out-dir {{ios_swift_out}}
