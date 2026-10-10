# ⚡ Performance Booster & Saver App

A high-performance Android root utility built in Flutter. Dynamically switches CPU scaling governors (`performance`, `schedutil`, `powersave`), terminates heavy background applications, manages device connectivity, tracks real-time hardware telemetry (battery health, temperature, CPU cluster frequencies), and persists active configurations and audit logs in a local SQLite database.

---

## 🚀 Features

### 1. Three Core Performance Profiles
- 🚀 **Performance Mode**: Locks CPU scaling governors to `performance` for maximum clock speeds and ultra-low latency during gaming and heavy workloads.
- ⚖️ **Balance Mode**: Applies Linux kernel `schedutil` governor for dynamic load-based CPU scaling and everyday responsiveness.
- 🍃 **Saver Mode**: Applies `powersave` governor to minimize power draw, cool down the processor, and extend battery longevity.

### 2. Root Superuser Automation
- Directly interacts with `/system/bin/su` via Magisk / KernelSU / APatch.
- Applies governor configurations across:
  - `/sys/devices/system/cpu/cpu0/cpufreq/scaling_governor`
  - `/sys/devices/system/cpu/cpu7/cpufreq/scaling_governor`
  - All detected `/sys/devices/system/cpu/cpu*/cpufreq/scaling_governor` and `/sys/devices/system/cpu/cpufreq/policy*/scaling_governor` nodes.
- Option to force-stop resource-heavy background apps (`am force-stop` on WhatsApp, Facebook, Telegram, Instagram, and custom packages).
- Optional network saver toggles (`svc wifi disable`, `svc data disable`).

### 3. Native Local Database Persistence (`SQLite`)
- Stores active profile options (`active_mode`, `kill_apps_on_saver`, `custom_apps`, `auto_apply_on_launch`).
- Stores historical audit logs (`mode_history` table) recording:
  - Selected profile
  - Target scaling governor
  - Battery percentage at the time of execution
  - Exact timestamp
  - Execution success/failure status and diagnostic logs.

### 4. Real-time Telemetry & Root Console
- Live battery gauge (% level, battery temperature in °C, voltage in mV, charging status).
- Live CPU core monitor showing active scaling governors for each CPU core.
- Interactive Root Shell Console allowing direct execution and inspection of shell output.

---

## 🛠️ Build and Run (On Your Device)

Pull the repository on your build machine or Android device and run:

```bash
# Get dependencies
flutter pub get

# Run on connected rooted device
flutter run

# Or build release APK
flutter build apk --release
```

The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.
