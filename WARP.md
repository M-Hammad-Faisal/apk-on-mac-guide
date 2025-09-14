# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a comprehensive guide and toolkit for running Android APK files on macOS. The repository provides documentation, automated setup scripts, and troubleshooting guides for various Android emulation methods on Mac.

## Key Commands

### Setup Commands
```bash
# === Standard Emulators ===
# Setup Android Studio emulator (recommended for developers)
./scripts/setup-android-studio.sh

# Setup BlueStacks (easiest for casual users)
./scripts/setup-bluestacks.sh

# Setup Genymotion professional emulator
./scripts/setup-genymotion.sh --license-type personal

# === Advanced Solutions ===
# Create custom AVD with specific configuration
./scripts/setup-custom-avd.sh --name HighEndDevice --ram 8192 --play-store --gpu-mode host

# Setup Docker Android container
./scripts/setup-docker-android.sh --android-version 33 --start-container

# Setup QEMU Android x86 emulation
./scripts/setup-qemu-android.sh

# Setup Waydroid Linux containers
./scripts/setup-waydroid.sh --method docker --start-vm

# === Universal APK Installation ===
# Auto-detect emulator and install APK
./scripts/install-apk.sh path/to/app.apk

# Install with specific options and emulator type
./scripts/install-apk.sh path/to/app.apk --replace --grant --type genymotion

# Install to specific Docker container
./scripts/install-apk.sh path/to/app.apk --docker-container my-android

# Install to QEMU with custom port
./scripts/install-apk.sh path/to/app.apk --qemu-port 5556
```

### Development Commands
```bash
# Make scripts executable
chmod +x scripts/*.sh

# Test Jekyll site locally (if developing GitHub Pages)
bundle exec jekyll serve

# Check script syntax
bash -n scripts/setup-android-studio.sh
```

### ADB Commands (for testing)
```bash
# List connected devices
adb devices

# Install APK via ADB
adb install path/to/app.apk

# Launch app
adb shell am start -n package.name/.MainActivity

# View device logs
adb logcat
```

## Repository Structure

- `scripts/` - Automated setup and installation scripts
  - `setup-android-studio.sh` - Installs Android Studio and configures SDK
  - `setup-bluestacks.sh` - Installs BlueStacks emulator
  - `setup-custom-avd.sh` - Creates highly customized Android Virtual Devices
  - `setup-genymotion.sh` - Installs and configures Genymotion professional emulator
  - `setup-docker-android.sh` - Sets up Docker-based Android containers
  - `setup-qemu-android.sh` - Configures QEMU Android x86 emulation
  - `setup-waydroid.sh` - Sets up Waydroid Linux containers (Docker/VM/UTM)
  - `install-apk.sh` - Universal APK installer with auto-detection for all emulator types
- `README.md` - Main documentation with setup methods
- `index.md` - GitHub Pages homepage
- `TROUBLESHOOTING.md` - Common issues and solutions
- `TESTING.md` - APK testing procedures
- `_config.yml` - Jekyll configuration for GitHub Pages
- `WARP.md` - This file, providing Warp-specific guidance

## Script Architecture

### install-apk.sh Features
- **Universal Emulator Support** - Auto-detects and supports all emulator types
- **Intelligent Detection** - Identifies AVD, Genymotion, Docker, QEMU, and Waydroid automatically
- **APK Analysis** - Uses AAPT tools for package information extraction
- **Multiple Installation Methods** - ADB, Docker exec, SSH, and native Waydroid
- **Flexible Configuration** - Custom ports, containers, IPs, and methods
- **Permission Management** - Automatic permission granting options
- **Interactive Features** - App launching and package management
- **Comprehensive Error Handling** - Context-aware suggestions for each emulator type

### Setup Scripts Pattern
All setup scripts follow consistent patterns:
- macOS compatibility checks
- System requirements validation
- Homebrew dependency management
- Environment variable configuration
- Shell profile updates (zsh/bash)
- Post-installation guidance

## GitHub Pages Integration

This repository uses Jekyll with the Minima theme for GitHub Pages deployment:
- Site URL: `https://m-hammad-faisal.github.io/apk-on-mac-guide`
- Navigation configured in `_config.yml`
- SEO optimization with jekyll-seo-tag plugin

## Development Guidelines

### Script Development
- Use bash for maximum compatibility
- Include colored output functions for better UX
- Validate all prerequisites before execution
- Provide clear error messages with solutions
- Support both interactive and automated modes

### Documentation Updates
- Keep README.md and index.md synchronized
- Update troubleshooting guide with new issues
- Maintain script usage examples
- Include system requirements for all methods

### Testing New Emulators
When adding support for new Android emulators:
1. Create new setup script in `scripts/` directory
2. Test on both Intel and Apple Silicon Macs
3. Update main documentation with new method
4. Add troubleshooting section for common issues
5. Update `install-apk.sh` detection and installation methods
6. Add emulator-specific helper scripts and management tools
7. Update WARP.md with new commands and architecture notes
8. Test universal APK installer with the new emulator type

### Emulator-Specific Testing
**Custom AVD**: Test various configurations (RAM, GPU modes, API levels)
**Docker Android**: Verify container networking and web VNC access
**Genymotion**: Test both free and paid license features
**QEMU**: Validate VNC connections and Android x86 compatibility
**Waydroid**: Test all three methods (Docker, Multipass, UTM)

## Common Use Cases

### For Contributors
- Test scripts on clean macOS installations
- Validate documentation accuracy
- Add support for new emulator solutions
- Improve error handling and user experience

### For Users
- Quick APK testing on Mac development machines
- Setting up Android development environment
- Troubleshooting emulator installation issues
- Running Android apps for compatibility testing

## External Dependencies

- **Homebrew** - Package manager for macOS installations
- **Android SDK** - Required for ADB and AAPT tools
- **Java** - Runtime dependency for Android tools
- **Jekyll** - Static site generator for GitHub Pages

## Environment Variables

Scripts automatically configure these environment variables:
- `ANDROID_HOME` - Android SDK installation path
- `PATH` - Extended with Android SDK tool paths

## Security Considerations

- Scripts validate file existence and permissions
- APK analysis warns about unknown sources
- No sensitive data stored in repository
- All external downloads use official sources
