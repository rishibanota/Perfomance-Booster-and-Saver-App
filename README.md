# ⚡ Performance Booster & Saver App

A high-performance Android root utility. Dynamically switches CPU scaling governors (`performance`, `schedutil`, `powersave`), terminates heavy background applications, manages device connectivity, tracks real-time hardware telemetry (battery health, temperature, CPU cluster frequencies), and persists active configurations and audit logs in a local SQLite database.

---

## 📦 Two Build Options

This repository includes two ways to build:

| Build Mode | Framework | Target APK Size | Startup Time | Memory Footprint |
| :--- | :--- | :--- | :--- | :--- |
| **Micro Native Mode** | Pure Android SDK (Java/Kotlin) | **~35 KB – 45 KB** | ~10 ms (Instant) | ~8 MB RAM |
| **Flutter Full Mode** | Flutter Material 3 AMOLED | **~4.5 MB** (split ABI) | ~250 ms | ~60 MB RAM |

---

## 🚀 Core Features (Both Modes)

1. **Three Core Profiles**:
   - 🚀 **Performance**: Sets governor to `performance` across all CPU cores (`cpu0`, `cpu7`, and `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor`).
   - ⚖️ **Balance**: Sets governor to `schedutil` for dynamic load-based frequency scaling.
   - 🍃 **Saver**: Sets governor to `powersave`, throttles background drain, and force-stops heavy apps.

2. **Root Superuser Execution**:
   - Asynchronous `su -c` execution compatible with Magisk, KernelSU, and APatch.
   - Live battery level reading (`dumpsys battery`).
   - Live CPU scaling governor reading per core.

3. **Persistent Local Database (`SQLite`)**:
   - Persists your selected active mode in `settings` table across phone reboots and app restarts.
   - Maintains execution history in `mode_history` table.

4. **Background App Killer**:
   - Force-stops resource-heavy apps (`com.whatsapp`, `com.facebook.katana`, `org.telegram.messenger`, `com.instagram.android`).

---

## 🛠️ How to Build on Your Device

### Option A: Build the Micro Native App (Under 50 KB!)
If you want the smallest possible app in **KB only**:

```bash
cd android
./gradlew :micro:assembleRelease
```
The APK will be at:
`android/micro/build/outputs/apk/release/micro-release.apk` (~35 KB).

---

### Option B: Build the Flutter App (Material 3 AMOLED UI)

```bash
# 1. Pull latest fixes
git pull origin main

# 2. Get dependencies
flutter pub get

# 3. Build release APK with size optimizations (R8 minification + per-ABI split)
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=symbols/
```
The optimized APKs will be at:
`build/app/outputs/flutter-apk/app-arm64-v8a-release.apk`
