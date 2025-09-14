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
    echo "  -t, --type      Force emulator type detection (avd|genymotion|docker|qemu|waydroid)"
    echo "  --docker-container NAME  Specify Docker container name (default: android-container)"
    echo "  --genymotion-ip IP       Specify Genymotion device IP"
    echo "  --qemu-port PORT         QEMU ADB port (default: 5555)"
    echo "  --waydroid-method METHOD Waydroid method (container|vm|local)"
    echo "  -h, --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 myapp.apk                              # Auto-detect emulator"
    echo "  $0 myapp.apk --replace --grant            # Standard options"
    echo "  $0 myapp.apk --device emulator-5554       # Specific AVD device"
    echo "  $0 myapp.apk --type genymotion            # Force Genymotion detection"
    echo "  $0 myapp.apk --docker-container my-android # Specific Docker container"
    echo "  $0 myapp.apk --genymotion-ip 192.168.56.101 # Specific Genymotion IP"
    echo "  $0 myapp.apk --qemu-port 5556             # QEMU with custom port"
    echo "  $0 myapp.apk --waydroid-method vm         # Waydroid in VM"
}

# Parse command line arguments
APK_FILE=""
DEVICE=""
REPLACE_FLAG=""
GRANT_PERMISSIONS=""
EMULATOR_TYPE=""
DOCKER_CONTAINER="android-container"
GENYMOTION_IP=""
QEMU_PORT="5555"
WAYDROID_METHOD="local"

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
        -t|--type)
            EMULATOR_TYPE="$2"
            shift 2
            ;;
        --docker-container)
            DOCKER_CONTAINER="$2"
            shift 2
            ;;
        --genymotion-ip)
            GENYMOTION_IP="$2"
            shift 2
            ;;
        --qemu-port)
            QEMU_PORT="$2"
            shift 2
            ;;
        --waydroid-method)
            WAYDROID_METHOD="$2"
            shift 2
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

# Function to detect emulator type
detect_emulator_type() {
    if [[ -n "$EMULATOR_TYPE" ]]; then
        echo "$EMULATOR_TYPE"
        return
    fi
    
    print_status "Auto-detecting emulator type..."
    
    # Check for Docker containers
    if command -v docker &> /dev/null && docker ps | grep -q "android-container\|waydroid-container"; then
        if docker ps | grep -q "waydroid-container"; then
            echo "waydroid"
        else
            echo "docker"
        fi
        return
    fi
    
    # Check for Genymotion (VirtualBox VMs with specific pattern)
    if command -v VBoxManage &> /dev/null; then
        if VBoxManage list runningvms | grep -q "Genymotion"; then
            echo "genymotion"
            return
        fi
    fi
    
    # Check for QEMU process
    if pgrep -f "qemu-system" > /dev/null; then
        echo "qemu"
        return
    fi
    
    # Check for Waydroid on local system or in VM
    if command -v waydroid &> /dev/null || command -v multipass &> /dev/null; then
        echo "waydroid"
        return
    fi
    
    # Default to AVD (Android Studio emulator)
    echo "avd"
}

# Function to install APK to Docker Android
install_docker_android() {
    print_status "Installing APK to Docker Android container..."
    
    if ! docker ps | grep -q "$DOCKER_CONTAINER"; then
        print_error "Docker container '$DOCKER_CONTAINER' not running"
        echo "To start container: ~/.docker-android/start-android.sh"
        exit 1
    fi
    
    # Copy APK to container
    APK_NAME=$(basename "$APK_FILE")
    docker cp "$APK_FILE" "$DOCKER_CONTAINER:/tmp/$APK_NAME"
    
    # Connect ADB and install
    adb connect localhost:5555
    sleep 2
    
    if adb devices | grep -q "5555.*device"; then
        install_cmd="adb -s localhost:5555 install"
        [[ -n "$REPLACE_FLAG" ]] && install_cmd="$install_cmd $REPLACE_FLAG"
        install_cmd="$install_cmd /tmp/$APK_NAME"
        
        if docker exec "$DOCKER_CONTAINER" $install_cmd; then
            print_success "APK installed to Docker container!"
            # Clean up
            docker exec "$DOCKER_CONTAINER" rm "/tmp/$APK_NAME"
        else
            print_error "Failed to install APK to Docker container"
            exit 1
        fi
    else
        print_error "Could not connect to Docker Android via ADB"
        exit 1
    fi
}

# Function to install APK to Genymotion
install_genymotion() {
    print_status "Installing APK to Genymotion device..."
    
    # Determine Genymotion IP
    if [[ -z "$GENYMOTION_IP" ]]; then
        # Look for typical Genymotion IP patterns
        DEVICES=$(adb devices | grep "192.168.56." | awk '{print $1}')
        if [[ -z "$DEVICES" ]]; then
            print_error "No Genymotion devices found. Please ensure:"
            echo "1. Genymotion virtual device is running"
            echo "2. ADB is enabled in Genymotion settings"
            exit 1
        fi
        GENYMOTION_IP=$(echo "$DEVICES" | head -n 1)
    fi
    
    print_status "Using Genymotion device: $GENYMOTION_IP"
    
    # Connect to device if not already connected
    if ! adb devices | grep -q "$GENYMOTION_IP.*device"; then
        adb connect "$GENYMOTION_IP"
        sleep 2
    fi
    
    # Install APK
    install_cmd="adb -s $GENYMOTION_IP install"
    [[ -n "$REPLACE_FLAG" ]] && install_cmd="$install_cmd $REPLACE_FLAG"
    install_cmd="$install_cmd \"$APK_FILE\""
    
    if eval "$install_cmd"; then
        print_success "APK installed to Genymotion device!"
    else
        print_error "Failed to install APK to Genymotion device"
        exit 1
    fi
}

# Function to install APK to QEMU
install_qemu() {
    print_status "Installing APK to QEMU Android..."
    
    # Connect to QEMU ADB port
    adb connect "localhost:$QEMU_PORT"
    sleep 2
    
    if adb devices | grep -q "$QEMU_PORT.*device"; then
        install_cmd="adb -s localhost:$QEMU_PORT install"
        [[ -n "$REPLACE_FLAG" ]] && install_cmd="$install_cmd $REPLACE_FLAG"
        install_cmd="$install_cmd \"$APK_FILE\""
        
        if eval "$install_cmd"; then
            print_success "APK installed to QEMU Android!"
        else
            print_error "Failed to install APK to QEMU"
            exit 1
        fi
    else
        print_error "Could not connect to QEMU Android"
        echo "Make sure QEMU Android is running: ~/.qemu-android/launch-android.sh"
        exit 1
    fi
}

# Function to install APK to Waydroid
install_waydroid() {
    print_status "Installing APK to Waydroid..."
    
    case $WAYDROID_METHOD in
        "container")
            if docker ps | grep -q "waydroid-container"; then
                APK_NAME=$(basename "$APK_FILE")
                docker cp "$APK_FILE" "waydroid-container:/shared/$APK_NAME"
                if docker exec waydroid-container waydroid app install "/shared/$APK_NAME"; then
                    print_success "APK installed to Waydroid container!"
                    docker exec waydroid-container rm "/shared/$APK_NAME"
                else
                    print_error "Failed to install APK to Waydroid container"
                    exit 1
                fi
            else
                print_error "Waydroid container not running"
                exit 1
            fi
            ;;
        "vm")
            if command -v multipass &> /dev/null; then
                VM_IP=$(multipass info waydroid-vm | grep IPv4 | awk '{print $2}')
                if [[ -n "$VM_IP" ]]; then
                    APK_NAME=$(basename "$APK_FILE")
                    scp "$APK_FILE" "ubuntu@$VM_IP:/tmp/$APK_NAME"
                    if ssh ubuntu@$VM_IP "waydroid app install /tmp/$APK_NAME"; then
                        print_success "APK installed to Waydroid VM!"
                        ssh ubuntu@$VM_IP "rm /tmp/$APK_NAME"
                    else
                        print_error "Failed to install APK to Waydroid VM"
                        exit 1
                    fi
                else
                    print_error "Could not find Waydroid VM IP"
                    exit 1
                fi
            else
                print_error "Multipass not found for VM method"
                exit 1
            fi
            ;;
        "local")
            if command -v waydroid &> /dev/null; then
                if waydroid app install "$APK_FILE"; then
                    print_success "APK installed to local Waydroid!"
                else
                    print_error "Failed to install APK to local Waydroid"
                    exit 1
                fi
            else
                print_error "Waydroid not found on local system"
                exit 1
            fi
            ;;
        *)
            print_error "Unknown Waydroid method: $WAYDROID_METHOD"
            exit 1
            ;;
    esac
}

# Detect emulator type
EMULATOR_TYPE=$(detect_emulator_type)
print_status "Detected emulator type: $EMULATOR_TYPE"

# Handle installation based on emulator type
case $EMULATOR_TYPE in
    "docker")
        install_docker_android
        exit 0
        ;;
    "genymotion")
        install_genymotion
        exit 0
        ;;
    "qemu")
        install_qemu
        exit 0
        ;;
    "waydroid")
        install_waydroid
        exit 0
        ;;
    "avd"|*)
        # Continue with standard AVD installation
        print_status "Using standard AVD installation method"
        ;;
esac

# Start ADB server for AVD installation
print_status "Starting ADB server..."
adb start-server

# List available devices for AVD
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
    echo ""
    echo "Or use one of the other emulator types:"
    echo "   ./scripts/setup-docker-android.sh"
    echo "   ./scripts/setup-genymotion.sh"
    echo "   ./scripts/setup-qemu-android.sh"
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
print_status "Emulator type: $EMULATOR_TYPE"
if [[ "$EMULATOR_TYPE" == "avd" ]]; then
    echo "Useful commands for installed app:"
    if [[ -n "$package_name" ]]; then
        echo "  Launch app:     adb -s $TARGET_DEVICE shell am start -n $package_name/.MainActivity"
        echo "  Uninstall app:  adb -s $TARGET_DEVICE uninstall $package_name"
        echo "  App info:       adb -s $TARGET_DEVICE shell dumpsys package $package_name"
        echo "  Clear data:     adb -s $TARGET_DEVICE shell pm clear $package_name"
    fi
    echo "  List packages:  adb -s $TARGET_DEVICE shell pm list packages"
    echo "  Device logs:    adb -s $TARGET_DEVICE logcat"
else
    echo "Emulator-specific management scripts:"
    case $EMULATOR_TYPE in
        "docker")
            echo "  Container status: ~/.docker-android/status.sh"
            echo "  Stop container:   ~/.docker-android/stop-android.sh"
            echo "  Web access:       http://localhost:6080"
            ;;
        "genymotion")
            echo "  Device management: ~/.genymotion-scripts/manage-devices.sh"
            echo "  Launch Genymotion: ~/.genymotion-scripts/launch-genymotion.sh"
            ;;
        "qemu")
            echo "  Connect ADB:      ~/.qemu-android/connect-adb.sh"
            echo "  VNC access:       vnc://localhost:5901"
            ;;
        "waydroid")
            echo "  Status check:     ~/.waydroid-mac/status.sh"
            if [[ "$WAYDROID_METHOD" == "container" ]]; then
                echo "  Web access:       http://localhost:3000"
            fi
            ;;
    esac
fi
