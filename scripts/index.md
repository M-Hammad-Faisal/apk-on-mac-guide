---
layout: page
title: Setup Scripts
permalink: /scripts/
description: "Automated setup scripts for various Android emulation methods on macOS"
---

# Setup Scripts Collection

This directory contains automated setup scripts for various Android emulation methods on macOS. Each script is designed to work on both Intel and Apple Silicon Macs with comprehensive error handling and user guidance.

## 📦 Available Setup Scripts

### Core Scripts

#### 🔧 [install-apk.sh](install-apk.sh)
**Universal APK Installer with Auto-Detection**
- Auto-detects all supported emulator types
- Supports AVD, Genymotion, Docker, QEMU, and Waydroid
- APK analysis and package information extraction
- Multiple installation methods and permission management

```bash
# Download and use
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/install-apk.sh
chmod +x install-apk.sh
./install-apk.sh path/to/your-app.apk
```

### Emulator Setup Scripts

#### 📱 [setup-android-studio.sh](setup-android-studio.sh)
**Android Studio & SDK Setup (Recommended for Developers)**
- Installs Android Studio and configures SDK
- Sets up environment variables
- Creates optimized AVD configurations

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-android-studio.sh
chmod +x setup-android-studio.sh
./setup-android-studio.sh
```

#### 🎮 [setup-bluestacks.sh](setup-bluestacks.sh)
**BlueStacks Setup (Easiest for Casual Users)**
- Downloads and installs BlueStacks
- Optimizes performance settings
- Provides usage guidance

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-bluestacks.sh
chmod +x setup-bluestacks.sh
./setup-bluestacks.sh
```

#### ⚙️ [setup-custom-avd.sh](setup-custom-avd.sh)
**Custom Android Virtual Device Creator**
- Creates highly customized AVDs
- Advanced configuration options (RAM, GPU, Play Store)
- Multiple device profiles and API levels

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-custom-avd.sh
chmod +x setup-custom-avd.sh
./setup-custom-avd.sh --name HighEndDevice --ram 8192 --play-store --gpu-mode host
```

#### 💼 [setup-genymotion.sh](setup-genymotion.sh)
**Genymotion Professional Emulator**
- Installs Genymotion (both personal and business licenses)
- VirtualBox integration
- Professional emulator features

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-genymotion.sh
chmod +x setup-genymotion.sh
./setup-genymotion.sh --license-type personal
```

#### 🐳 [setup-docker-android.sh](setup-docker-android.sh)
**Docker Android Containers**
- Sets up Docker-based Android environment
- Web VNC access for GUI interaction
- Multiple Android versions support

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-docker-android.sh
chmod +x setup-docker-android.sh
./setup-docker-android.sh --android-version 33 --start-container
```

#### 🖥️ [setup-qemu-android.sh](setup-qemu-android.sh)
**QEMU Android x86 Emulation**
- Native Android x86 emulation with QEMU
- VNC connection support
- Lightweight alternative to full emulators

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-qemu-android.sh
chmod +x setup-qemu-android.sh
./setup-qemu-android.sh
```

#### 📦 [setup-waydroid.sh](setup-waydroid.sh)
**Waydroid Linux Containers (Advanced)**
- Multiple setup methods (Docker, Multipass, UTM)
- Linux container-based Android environment
- Advanced configuration options

```bash
curl -O https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-waydroid.sh
chmod +x setup-waydroid.sh
./setup-waydroid.sh --method docker --start-vm
```

## 🚀 Quick Start

### Method 1: One-Line Setup
Choose your preferred emulator and run the setup script:

```bash
# For beginners - BlueStacks (easiest)
curl -sSL https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-bluestacks.sh | bash

# For developers - Android Studio (recommended)
curl -sSL https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-android-studio.sh | bash

# For advanced users - Custom AVD
curl -sSL https://raw.githubusercontent.com/M-Hammad-Faisal/apk-on-mac-guide/master/scripts/setup-custom-avd.sh | bash
```

### Method 2: Download and Customize
```bash
# Clone the entire repository
git clone https://github.com/M-Hammad-Faisal/apk-on-mac-guide.git
cd apk-on-mac-guide/scripts

# Make all scripts executable
chmod +x *.sh

# Run your preferred setup script
./setup-android-studio.sh
```

## 📋 Prerequisites

All scripts automatically check and install prerequisites, but you may want to ensure you have:

- **macOS 10.15 or later**
- **Homebrew** (scripts will install if missing)
- **Command Line Tools** for Xcode
- **Internet connection** for downloads

## 🔧 Script Features

### Common Features Across All Scripts:
- ✅ **macOS Compatibility** - Works on both Intel and Apple Silicon Macs
- ✅ **Automatic Prerequisites** - Installs dependencies automatically
- ✅ **Error Handling** - Comprehensive error checking and user guidance
- ✅ **Environment Setup** - Configures shell profiles (zsh/bash)
- ✅ **Interactive Mode** - Guided setup with user choices
- ✅ **Help Documentation** - Built-in help with `--help` flag
- ✅ **Logging** - Detailed setup logs for troubleshooting

### Universal APK Installer Features:
- 🔍 **Auto-Detection** - Identifies running emulators automatically
- 📱 **Multi-Platform** - Supports all emulator types in one script
- 🔧 **Flexible Options** - Custom ports, containers, and installation methods
- 📊 **APK Analysis** - Extracts package information before installation
- 🚀 **App Launching** - Can launch apps after installation
- 🛠️ **Error Recovery** - Context-aware suggestions for each emulator type

## 📚 Additional Resources

- **[Main Guide](../)** - Complete setup documentation
- **[Troubleshooting](../TROUBLESHOOTING)** - Common issues and solutions  
- **[Testing Guide](../TESTING)** - APK testing procedures
- **[GitHub Repository](https://github.com/M-Hammad-Faisal/apk-on-mac-guide)** - Source code and issues

## 🤝 Contributing

Found an issue or want to contribute? 

1. **Report Issues**: [GitHub Issues](https://github.com/M-Hammad-Faisal/apk-on-mac-guide/issues)
2. **Submit PRs**: [Pull Requests](https://github.com/M-Hammad-Faisal/apk-on-mac-guide/pulls)
3. **Improve Scripts**: Help us test on different macOS versions

---

<div style="text-align: center; margin-top: 2rem; padding: 1rem; background-color: #f8f9fa; border-radius: 8px;">
<p><strong>Made with ❤️ by <a href="https://github.com/M-Hammad-Faisal">M-Hammad-Faisal</a></strong></p>
<p><em>Star ⭐ this repo if it helped you!</em></p>
</div>
