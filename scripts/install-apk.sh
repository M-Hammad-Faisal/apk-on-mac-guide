#!/bin/bash

# APK Installation Script for Android Emulators
# This script installs APK files to running Android emulators

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 <path-to-apk-file> [options]"
    echo ""
    echo "Options:"
    echo "  -d, --device    Specify target device/emulator"
    echo "  -r, --replace   Replace existing app if installed"
    echo "  -g, --grant     Grant all permissions automatically"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 myapp.apk"
    echo "  $0 myapp.apk --replace"
    echo "  $0 myapp.apk --device emulator-5554"
    echo "  $0 myapp.apk --replace --grant"
}

# Parse command line arguments
APK_FILE=""
DEVICE=""
REPLACE_FLAG=""
GRANT_PERMISSIONS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--device)
            DEVICE="$2"
            shift 2
            ;;
        -r|--replace)
            REPLACE_FLAG="-r"
            shift
            ;;
        -g|--grant)
            GRANT_PERMISSIONS="yes"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        -*)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
        *)
            if [[ -z "$APK_FILE" ]]; then
                APK_FILE="$1"
            else
                print_error "Multiple APK files specified. Please specify only one."
                exit 1
            fi
            shift
            ;;
    esac
done

# Check if APK file is provided
if [[ -z "$APK_FILE" ]]; then
    print_error "No APK file specified."
    show_usage
    exit 1
fi

# Check if APK file exists
if [[ ! -f "$APK_FILE" ]]; then
    print_error "APK file not found: $APK_FILE"
    exit 1
fi

# Convert to absolute path
APK_FILE="$(realpath "$APK_FILE")"
print_status "APK file: $APK_FILE"

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    print_error "ADB (Android Debug Bridge) is not installed or not in PATH."
    echo ""
    echo "To install ADB:"
    echo "1. Install Android Studio and SDK tools"
    echo "2. Or install platform-tools directly:"
    echo "   brew install --cask android-platform-tools"
    echo ""
    echo "Make sure to add ADB to your PATH:"
    echo "   export PATH=\"\$PATH:\$ANDROID_HOME/platform-tools\""
    exit 1
fi

# Start ADB server
print_status "Starting ADB server..."
adb start-server

# List available devices
print_status "Checking for available devices..."
devices_output=$(adb devices 2>/dev/null || true)

if ! echo "$devices_output" | grep -q "device$"; then
    print_error "No Android devices or emulators found."
    echo ""
    echo "Please ensure:"
    echo "1. An Android emulator is running, or"
    echo "2. A physical Android device is connected with USB debugging enabled"
    echo ""
    echo "To start Android Studio emulator:"
    echo "   emulator -avd <avd-name>"
    echo ""
    echo "To list available AVDs:"
    echo "   emulator -list-avds"
    exit 1
fi

echo "$devices_output"

# Select target device
if [[ -n "$DEVICE" ]]; then
    # Check if specified device exists
    if ! echo "$devices_output" | grep -q "$DEVICE.*device$"; then
        print_error "Specified device '$DEVICE' not found or not ready."
        exit 1
    fi
    TARGET_DEVICE="$DEVICE"
    print_status "Using specified device: $TARGET_DEVICE"
else
    # Auto-select device if only one is available
    device_count=$(echo "$devices_output" | grep "device$" | wc -l)
    if [[ $device_count -eq 1 ]]; then
        TARGET_DEVICE=$(echo "$devices_output" | grep "device$" | awk '{print $1}')
        print_status "Auto-selected device: $TARGET_DEVICE"
    else
        print_error "Multiple devices found. Please specify target device with -d option."
        echo ""
        echo "Available devices:"
        echo "$devices_output" | grep "device$"
        exit 1
    fi
fi

# Get APK information
print_status "Analyzing APK file..."
if command -v aapt &> /dev/null; then
    package_info=$(aapt dump badging "$APK_FILE" 2>/dev/null | head -n 1 || true)
    if [[ -n "$package_info" ]]; then
        package_name=$(echo "$package_info" | sed -n "s/.*name='\([^']*\)'.*/\1/p")
        version_name=$(echo "$package_info" | sed -n "s/.*versionName='\([^']*\)'.*/\1/p")
        version_code=$(echo "$package_info" | sed -n "s/.*versionCode='\([^']*\)'.*/\1/p")
        
        print_status "Package: $package_name"
        [[ -n "$version_name" ]] && print_status "Version: $version_name"
        [[ -n "$version_code" ]] && print_status "Version Code: $version_code"
    fi
else
    print_warning "AAPT not found. Cannot analyze APK package information."
fi

# Install APK
print_status "Installing APK to device $TARGET_DEVICE..."

install_cmd="adb -s $TARGET_DEVICE install"
[[ -n "$REPLACE_FLAG" ]] && install_cmd="$install_cmd $REPLACE_FLAG"
install_cmd="$install_cmd \"$APK_FILE\""

if eval "$install_cmd"; then
    print_success "APK installed successfully!"
    
    # Grant permissions if requested
    if [[ "$GRANT_PERMISSIONS" == "yes" ]] && [[ -n "$package_name" ]]; then
        print_status "Granting permissions..."
        
        # Common permissions to grant
        permissions=(
            "android.permission.READ_EXTERNAL_STORAGE"
            "android.permission.WRITE_EXTERNAL_STORAGE"
            "android.permission.CAMERA"
            "android.permission.RECORD_AUDIO"
            "android.permission.ACCESS_FINE_LOCATION"
            "android.permission.ACCESS_COARSE_LOCATION"
        )
        
        for permission in "${permissions[@]}"; do
            adb -s "$TARGET_DEVICE" shell pm grant "$package_name" "$permission" 2>/dev/null || true
        done
        
        print_success "Permissions granted (where applicable)"
    fi
    
    # Try to get the main activity and offer to launch
    if [[ -n "$package_name" ]]; then
        print_status "APK package: $package_name"
        
        read -p "Would you like to launch the app now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            print_status "Launching app..."
            if ! adb -s "$TARGET_DEVICE" shell monkey -p "$package_name" -c android.intent.category.LAUNCHER 1 >/dev/null 2>&1; then
                print_warning "Could not auto-launch app. Please launch manually from device."
            else
                print_success "App launched successfully!"
            fi
        fi
    fi
    
else
    print_error "Failed to install APK."
    echo ""
    echo "Common solutions:"
    echo "1. Enable 'Unknown Sources' in device settings"
    echo "2. Use --replace flag if app is already installed"
    echo "3. Ensure device has enough storage space"
    echo "4. Check if APK is compatible with device architecture"
    exit 1
fi

# Show post-installation info
echo ""
print_status "Installation completed!"
echo ""
echo "Useful commands for installed app:"
if [[ -n "$package_name" ]]; then
    echo "  Launch app:     adb -s $TARGET_DEVICE shell am start -n $package_name/.MainActivity"
    echo "  Uninstall app:  adb -s $TARGET_DEVICE uninstall $package_name"
    echo "  App info:       adb -s $TARGET_DEVICE shell dumpsys package $package_name"
    echo "  Clear data:     adb -s $TARGET_DEVICE shell pm clear $package_name"
fi
echo "  List packages:  adb -s $TARGET_DEVICE shell pm list packages"
echo "  Device logs:    adb -s $TARGET_DEVICE logcat"
