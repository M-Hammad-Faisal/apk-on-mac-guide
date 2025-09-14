#!/bin/bash

# Custom AVD Setup Script for macOS
# This script creates highly customized Android Virtual Devices

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
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --name NAME          AVD name (required)"
    echo "  --api-level LEVEL    Android API level (default: 31)"
    echo "  --device DEVICE      Device profile (default: pixel_5)"
    echo "  --abi ABI           System image ABI (default: x86_64)"
    echo "  --ram RAM           RAM allocation in MB (default: 4096)"
    echo "  --storage STORAGE   Internal storage in MB (default: 8192)"
    echo "  --sd-card SIZE      SD card size in MB (optional)"
    echo "  --gpu-mode MODE     GPU mode (auto|host|swiftshader_indirect|angle_indirect|guest)"
    echo "  --skin SKIN         Device skin (optional)"
    echo "  --density DPI       Screen density (default: 440)"
    echo "  --resolution WxH    Screen resolution (default: 1080x2340)"
    echo "  --google-apis       Include Google APIs (default: yes)"
    echo "  --play-store        Include Google Play Store"
    echo "  --camera-front CAM  Front camera (webcam0|emulated|none)"
    echo "  --camera-back CAM   Back camera (webcam0|emulated|none)"
    echo "  --network-speed SPD Network speed (full|gsm|hscsd|gprs|edge|umts|hsdpa|lte)"
    echo "  --network-latency LAT Network latency (none|gsm|hscsd|gprs|edge|umts|hsdpa|lte)"
    echo "  --keyboard          Enable hardware keyboard"
    echo "  --snapshot          Enable snapshots for faster boot"
    echo "  --multi-touch       Enable multi-touch support"
    echo "  -h, --help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --name MyCustomAVD --api-level 33 --ram 8192"
    echo "  $0 --name TestDevice --device pixel_6 --play-store --gpu-mode host"
    echo "  $0 --name TabletAVD --device Nexus_9 --resolution 2048x1536 --density 320"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Default values
AVD_NAME=""
API_LEVEL="31"
DEVICE_PROFILE="pixel_5"
ABI="x86_64"
RAM_SIZE="4096"
STORAGE_SIZE="8192"
SD_CARD_SIZE=""
GPU_MODE="auto"
SKIN=""
DENSITY="440"
RESOLUTION="1080x2340"
GOOGLE_APIS="yes"
PLAY_STORE="no"
CAMERA_FRONT="emulated"
CAMERA_BACK="emulated"
NETWORK_SPEED="full"
NETWORK_LATENCY="none"
HARDWARE_KEYBOARD="no"
SNAPSHOTS="yes"
MULTI_TOUCH="yes"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --name)
            AVD_NAME="$2"
            shift 2
            ;;
        --api-level)
            API_LEVEL="$2"
            shift 2
            ;;
        --device)
            DEVICE_PROFILE="$2"
            shift 2
            ;;
        --abi)
            ABI="$2"
            shift 2
            ;;
        --ram)
            RAM_SIZE="$2"
            shift 2
            ;;
        --storage)
            STORAGE_SIZE="$2"
            shift 2
            ;;
        --sd-card)
            SD_CARD_SIZE="$2"
            shift 2
            ;;
        --gpu-mode)
            GPU_MODE="$2"
            shift 2
            ;;
        --skin)
            SKIN="$2"
            shift 2
            ;;
        --density)
            DENSITY="$2"
            shift 2
            ;;
        --resolution)
            RESOLUTION="$2"
            shift 2
            ;;
        --google-apis)
            GOOGLE_APIS="yes"
            shift
            ;;
        --play-store)
            PLAY_STORE="yes"
            GOOGLE_APIS="yes"  # Play Store requires Google APIs
            shift
            ;;
        --camera-front)
            CAMERA_FRONT="$2"
            shift 2
            ;;
        --camera-back)
            CAMERA_BACK="$2"
            shift 2
            ;;
        --network-speed)
            NETWORK_SPEED="$2"
            shift 2
            ;;
        --network-latency)
            NETWORK_LATENCY="$2"
            shift 2
            ;;
        --keyboard)
            HARDWARE_KEYBOARD="yes"
            shift
            ;;
        --snapshot)
            SNAPSHOTS="yes"
            shift
            ;;
        --multi-touch)
            MULTI_TOUCH="yes"
            shift
            ;;
        -h|--help)
            show_usage
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Validate required parameters
if [[ -z "$AVD_NAME" ]]; then
    print_error "AVD name is required. Use --name to specify."
    show_usage
    exit 1
fi

print_status "Starting Custom AVD setup for: $AVD_NAME"

# Check if Android SDK is installed
ANDROID_HOME="${ANDROID_HOME:-$HOME/Library/Android/sdk}"
if [[ ! -d "$ANDROID_HOME" ]]; then
    print_error "Android SDK not found. Please install Android Studio first:"
    echo "  ./setup-android-studio.sh"
    exit 1
fi

# Add Android SDK tools to PATH
export PATH="$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/tools/bin:$ANDROID_HOME/platform-tools:$ANDROID_HOME/emulator"

# Check if SDK tools are available
if ! command -v avdmanager &> /dev/null; then
    print_error "avdmanager not found. Please ensure Android SDK is properly installed."
    exit 1
fi

if ! command -v sdkmanager &> /dev/null; then
    print_error "sdkmanager not found. Please ensure Android SDK is properly installed."
    exit 1
fi

# Determine system image package
if [[ "$PLAY_STORE" == "yes" ]]; then
    SYSTEM_IMAGE_PACKAGE="system-images;android-$API_LEVEL;google_apis_playstore;$ABI"
elif [[ "$GOOGLE_APIS" == "yes" ]]; then
    SYSTEM_IMAGE_PACKAGE="system-images;android-$API_LEVEL;google_apis;$ABI"
else
    SYSTEM_IMAGE_PACKAGE="system-images;android-$API_LEVEL;default;$ABI"
fi

print_status "System image package: $SYSTEM_IMAGE_PACKAGE"

# Download system image if not available
print_status "Checking/downloading system image..."
if ! sdkmanager --list | grep -q "system-images;android-$API_LEVEL"; then
    print_status "Installing system image for API level $API_LEVEL..."
    sdkmanager "$SYSTEM_IMAGE_PACKAGE"
else
    print_success "System image already available"
fi

# List available device definitions
print_status "Available device profiles:"
avdmanager list device | grep "id:" | head -10

# Create AVD
print_status "Creating AVD: $AVD_NAME"

# Check if AVD already exists
if avdmanager list avd | grep -q "Name: $AVD_NAME"; then
    print_warning "AVD '$AVD_NAME' already exists."
    read -p "Overwrite existing AVD? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        avdmanager delete avd -n "$AVD_NAME"
        print_status "Existing AVD deleted"
    else
        print_error "AVD creation cancelled"
        exit 1
    fi
fi

# Create the AVD
avdmanager create avd \
    -n "$AVD_NAME" \
    -k "$SYSTEM_IMAGE_PACKAGE" \
    -d "$DEVICE_PROFILE" \
    --force

print_success "AVD created successfully"

# Configure AVD settings
AVD_CONFIG_PATH="$HOME/.android/avd/$AVD_NAME.avd/config.ini"

if [[ -f "$AVD_CONFIG_PATH" ]]; then
    print_status "Configuring AVD settings..."
    
    # Backup original config
    cp "$AVD_CONFIG_PATH" "$AVD_CONFIG_PATH.backup"
    
    # Update configuration
    {
        echo "# Custom AVD Configuration"
        echo "hw.ramSize=$RAM_SIZE"
        echo "vm.heapSize=512"
        echo "hw.gpu.enabled=yes"
        echo "hw.gpu.mode=$GPU_MODE"
        echo "disk.dataPartition.size=${STORAGE_SIZE}M"
        
        if [[ -n "$SD_CARD_SIZE" ]]; then
            echo "hw.sdCard=yes"
            echo "sdcard.size=${SD_CARD_SIZE}M"
        fi
        
        echo "hw.lcd.density=$DENSITY"
        echo "hw.lcd.width=$(echo $RESOLUTION | cut -d'x' -f1)"
        echo "hw.lcd.height=$(echo $RESOLUTION | cut -d'x' -f2)"
        
        if [[ -n "$SKIN" ]]; then
            echo "skin.name=$SKIN"
        fi
        
        echo "hw.camera.front=$CAMERA_FRONT"
        echo "hw.camera.back=$CAMERA_BACK"
        echo "hw.audioInput=yes"
        echo "hw.audioOutput=yes"
        echo "hw.gps=yes"
        echo "hw.accelerometer=yes"
        echo "hw.gyroscope=yes"
        echo "hw.sensors.proximity=yes"
        echo "hw.sensors.orientation=yes"
        echo "hw.dPad=no"
        echo "hw.trackBall=no"
        echo "hw.keyboard=$([[ $HARDWARE_KEYBOARD == "yes" ]] && echo "yes" || echo "no")"
        echo "hw.keyboard.lid=no"
        echo "hw.cpu.ncore=4"
        echo "hw.device.manufacturer=Google"
        echo "hw.device.name=$DEVICE_PROFILE"
        
        if [[ "$MULTI_TOUCH" == "yes" ]]; then
            echo "hw.mainKeys=no"
            echo "hw.touchScreen=yes"
        fi
        
        if [[ "$SNAPSHOTS" == "yes" ]]; then
            echo "snapshot.present=no"
            echo "fastboot.chosenSnapshotFile="
            echo "fastboot.forceChosenSnapshotBoot=no"
            echo "fastboot.forceColdBoot=no"
            echo "fastboot.forceFastBoot=yes"
        fi
        
        echo "runtime.network.speed=$NETWORK_SPEED"
        echo "runtime.network.latency=$NETWORK_LATENCY"
        
    } >> "$AVD_CONFIG_PATH"
    
    print_success "AVD configuration updated"
fi

# Create launch script for this specific AVD
LAUNCH_SCRIPT="$HOME/.android/avd/launch-$AVD_NAME.sh"
cat > "$LAUNCH_SCRIPT" << EOF
#!/bin/bash

# Custom AVD Launch Script for $AVD_NAME
# Generated by setup-custom-avd.sh

AVD_NAME="$AVD_NAME"
ANDROID_HOME="${ANDROID_HOME}"

# Add Android SDK to PATH
export PATH="\$PATH:\$ANDROID_HOME/emulator:\$ANDROID_HOME/tools:\$ANDROID_HOME/platform-tools"

echo "Launching custom AVD: \$AVD_NAME"
echo "RAM: ${RAM_SIZE}MB, Storage: ${STORAGE_SIZE}MB"
echo "Resolution: $RESOLUTION, DPI: $DENSITY"
echo "GPU Mode: $GPU_MODE"
echo ""

# Launch emulator with optimizations
emulator -avd "\$AVD_NAME" \\
    -memory "$RAM_SIZE" \\
    -gpu "$GPU_MODE" \\
    -skin "$RESOLUTION" \\
    -netdelay "$NETWORK_LATENCY" \\
    -netspeed "$NETWORK_SPEED" \\
    -camera-front "$CAMERA_FRONT" \\
    -camera-back "$CAMERA_BACK" \\
    $([[ "$SNAPSHOTS" == "yes" ]] && echo "-snapshot-save") \\
    $([[ "$HARDWARE_KEYBOARD" == "yes" ]] && echo "-show-kernel") \\
    -verbose &

echo "AVD \$AVD_NAME is starting..."
echo "Use 'adb devices' to verify connection once booted"
echo "To install APK: adb install app.apk"
echo "To stop: kill the emulator process or close the window"
EOF

chmod +x "$LAUNCH_SCRIPT"
print_success "Launch script created: $LAUNCH_SCRIPT"

print_success "Custom AVD setup completed!"
echo ""
print_status "AVD Details:"
echo "  Name: $AVD_NAME"
echo "  API Level: Android $API_LEVEL"
echo "  Device: $DEVICE_PROFILE"
echo "  ABI: $ABI"
echo "  RAM: ${RAM_SIZE}MB"
echo "  Storage: ${STORAGE_SIZE}MB"
echo "  Resolution: $RESOLUTION ($DENSITY DPI)"
echo "  GPU Mode: $GPU_MODE"
if [[ "$PLAY_STORE" == "yes" ]]; then
    echo "  Features: Google Play Store, Google APIs"
elif [[ "$GOOGLE_APIS" == "yes" ]]; then
    echo "  Features: Google APIs"
fi
echo ""
print_status "Launch Commands:"
echo "  Quick launch: $LAUNCH_SCRIPT"
echo "  Manual launch: emulator -avd $AVD_NAME"
echo "  List AVDs: avdmanager list avd"
echo "  Delete AVD: avdmanager delete avd -n $AVD_NAME"
echo ""
print_warning "Performance Tips:"
echo "- Ensure Hardware Acceleration is enabled (Intel HAXM/Apple Hypervisor)"
echo "- Close unnecessary applications while running emulator"
echo "- Use SSD storage for better performance"
echo "- Consider reducing resolution/RAM if performance is poor"

# Offer to launch the AVD
read -p "Would you like to launch the AVD now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Launching $AVD_NAME..."
    "$LAUNCH_SCRIPT"
fi
