#!/bin/bash

# Genymotion Setup Script for macOS
# This script sets up Genymotion Android emulator for professional testing

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
    echo "  --license-type TYPE      License type (free|personal|business) (default: free)"
    echo "  --install-path PATH      Installation path (default: /Applications)"
    echo "  --create-device          Create sample device after installation"
    echo "  --device-name NAME       Device name for sample device (default: TestDevice)"
    echo "  --android-version VER    Android version (7.0|8.0|9.0|10.0|11.0|12.0|13.0) (default: 11.0)"
    echo "  --device-type TYPE       Device type (phone|tablet) (default: phone)"
    echo "  --skip-registration      Skip Genymotion account registration prompt"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --license-type personal --create-device"
    echo "  $0 --device-name MyTestPhone --android-version 12.0"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Default values
LICENSE_TYPE="free"
INSTALL_PATH="/Applications"
CREATE_DEVICE="no"
DEVICE_NAME="TestDevice"
ANDROID_VERSION="11.0"
DEVICE_TYPE="phone"
SKIP_REGISTRATION="no"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --license-type)
            LICENSE_TYPE="$2"
            shift 2
            ;;
        --install-path)
            INSTALL_PATH="$2"
            shift 2
            ;;
        --create-device)
            CREATE_DEVICE="yes"
            shift
            ;;
        --device-name)
            DEVICE_NAME="$2"
            shift 2
            ;;
        --android-version)
            ANDROID_VERSION="$2"
            shift 2
            ;;
        --device-type)
            DEVICE_TYPE="$2"
            shift 2
            ;;
        --skip-registration)
            SKIP_REGISTRATION="yes"
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

print_status "Starting Genymotion setup for macOS..."

# Check system requirements
print_status "Checking system requirements..."

# Check macOS version
macos_version=$(sw_vers -productVersion | cut -d '.' -f 1-2)
required_version="10.12"

if [[ $(echo "$macos_version >= $required_version" | bc -l) -eq 0 ]]; then
    print_error "macOS $required_version or later is required. You have $macos_version"
    exit 1
fi

# Check available disk space (minimum 4GB)
available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
if [[ ${available_space%.*} -lt 4 ]]; then
    print_warning "Low disk space. At least 4GB free space is recommended."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Check if VirtualBox is installed (required for Genymotion Desktop)
print_status "Checking for VirtualBox..."
if ! command -v VBoxManage &> /dev/null && [[ ! -d "/Applications/VirtualBox.app" ]]; then
    print_warning "VirtualBox not found. Genymotion Desktop requires VirtualBox."
    read -p "Would you like to install VirtualBox? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installing VirtualBox..."
        if command -v brew &> /dev/null; then
            brew install --cask virtualbox
            print_success "VirtualBox installed"
        else
            print_error "Homebrew not found. Please install VirtualBox manually:"
            echo "  Download from: https://www.virtualbox.org/wiki/Downloads"
            exit 1
        fi
    else
        print_warning "Proceeding without VirtualBox. Some features may not work."
    fi
else
    print_success "VirtualBox found"
fi

# Install Genymotion
print_status "Installing Genymotion..."

if [[ ! -d "/Applications/Genymotion.app" ]]; then
    if command -v brew &> /dev/null; then
        print_status "Installing Genymotion via Homebrew..."
        brew install --cask genymotion
        print_success "Genymotion installed successfully"
    else
        print_error "Homebrew not found. Please install Genymotion manually:"
        echo "1. Go to: https://www.genymotion.com/download/"
        echo "2. Create an account and download the installer"
        echo "3. Run the installer and follow the setup wizard"
        read -p "Press Enter after manual installation is complete..." -r
        
        if [[ ! -d "/Applications/Genymotion.app" ]]; then
            print_error "Genymotion installation not detected"
            exit 1
        fi
    fi
else
    print_success "Genymotion is already installed"
fi

# Create Genymotion configuration directory
GENYMOTION_CONFIG_DIR="$HOME/.Genymobile"
mkdir -p "$GENYMOTION_CONFIG_DIR"

# Create helper scripts directory
GENYMOTION_SCRIPTS_DIR="$HOME/.genymotion-scripts"
mkdir -p "$GENYMOTION_SCRIPTS_DIR"

print_status "Configuration directory: $GENYMOTION_CONFIG_DIR"
print_status "Scripts directory: $GENYMOTION_SCRIPTS_DIR"

# Create Genymotion launcher script
LAUNCHER_SCRIPT="$GENYMOTION_SCRIPTS_DIR/launch-genymotion.sh"
cat > "$LAUNCHER_SCRIPT" << 'EOF'
#!/bin/bash

# Genymotion Launcher Script
# This script launches Genymotion with proper environment setup

GENYMOTION_APP="/Applications/Genymotion.app"

if [[ ! -d "$GENYMOTION_APP" ]]; then
    echo "Error: Genymotion not found at $GENYMOTION_APP"
    echo "Please ensure Genymotion is properly installed"
    exit 1
fi

echo "Launching Genymotion..."
open "$GENYMOTION_APP"

# Wait a moment and check if VirtualBox is running if needed
sleep 3
if pgrep -x "VBoxHeadless" > /dev/null; then
    echo "✅ Genymotion virtual devices are running"
elif pgrep -x "Genymotion" > /dev/null; then
    echo "✅ Genymotion application is running"
else
    echo "ℹ️  Genymotion launched - please set up your virtual devices"
fi

echo ""
echo "Useful Genymotion commands:"
echo "  Create device: Use Genymotion UI or gmtool admin create"
echo "  Start device:  gmtool admin start <device-name>"
echo "  Stop device:   gmtool admin stop <device-name>"
echo "  List devices:  gmtool admin list"
EOF

chmod +x "$LAUNCHER_SCRIPT"
print_success "Launcher script created: $LAUNCHER_SCRIPT"

# Create device management script
DEVICE_SCRIPT="$GENYMOTION_SCRIPTS_DIR/manage-devices.sh"
cat > "$DEVICE_SCRIPT" << 'EOF'
#!/bin/bash

# Genymotion Device Management Script
# This script helps manage Genymotion virtual devices

GMTOOL="/Applications/Genymotion.app/Contents/MacOS/gmtool"

if [[ ! -f "$GMTOOL" ]]; then
    echo "Error: Genymotion gmtool not found"
    echo "Please ensure Genymotion is properly installed"
    exit 1
fi

show_usage() {
    echo "Usage: $0 <command> [options]"
    echo ""
    echo "Commands:"
    echo "  list                    List all virtual devices"
    echo "  templates              List available device templates"
    echo "  create <name> <template> Create new virtual device"
    echo "  start <name>           Start virtual device"
    echo "  stop <name>            Stop virtual device"
    echo "  delete <name>          Delete virtual device"
    echo "  status                 Show status of all devices"
    echo ""
    echo "Examples:"
    echo "  $0 list"
    echo "  $0 templates"
    echo "  $0 create MyDevice 'Samsung Galaxy S10 - 10.0 - API 29 - 1080x2280'"
    echo "  $0 start MyDevice"
}

case "${1:-help}" in
    list)
        echo "📱 Genymotion Virtual Devices:"
        "$GMTOOL" admin list
        ;;
    templates)
        echo "📋 Available Device Templates:"
        "$GMTOOL" admin templates
        ;;
    create)
        if [[ $# -lt 3 ]]; then
            echo "Error: Device name and template required"
            echo "Usage: $0 create <name> <template>"
            echo ""
            echo "Available templates:"
            "$GMTOOL" admin templates
            exit 1
        fi
        DEVICE_NAME="$2"
        TEMPLATE="$3"
        echo "Creating device: $DEVICE_NAME"
        echo "Template: $TEMPLATE"
        "$GMTOOL" admin create "$DEVICE_NAME" "$TEMPLATE"
        ;;
    start)
        if [[ $# -lt 2 ]]; then
            echo "Error: Device name required"
            echo "Usage: $0 start <device-name>"
            exit 1
        fi
        DEVICE_NAME="$2"
        echo "Starting device: $DEVICE_NAME"
        "$GMTOOL" admin start "$DEVICE_NAME"
        ;;
    stop)
        if [[ $# -lt 2 ]]; then
            echo "Error: Device name required"
            echo "Usage: $0 stop <device-name>"
            exit 1
        fi
        DEVICE_NAME="$2"
        echo "Stopping device: $DEVICE_NAME"
        "$GMTOOL" admin stop "$DEVICE_NAME"
        ;;
    delete)
        if [[ $# -lt 2 ]]; then
            echo "Error: Device name required"
            echo "Usage: $0 delete <device-name>"
            exit 1
        fi
        DEVICE_NAME="$2"
        echo "Deleting device: $DEVICE_NAME"
        read -p "Are you sure? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            "$GMTOOL" admin delete "$DEVICE_NAME"
        else
            echo "Cancelled"
        fi
        ;;
    status)
        echo "🔍 Device Status:"
        "$GMTOOL" admin list
        echo ""
        echo "VirtualBox VMs:"
        VBoxManage list runningvms 2>/dev/null || echo "No running VMs"
        ;;
    help|*)
        show_usage
        ;;
esac
EOF

chmod +x "$DEVICE_SCRIPT"
print_success "Device management script created: $DEVICE_SCRIPT"

# Create APK installer script for Genymotion
APK_INSTALLER="$GENYMOTION_SCRIPTS_DIR/install-apk.sh"
cat > "$APK_INSTALLER" << 'EOF'
#!/bin/bash

# Genymotion APK Installer Script
# This script installs APK files to running Genymotion devices

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <path-to-apk-file> [device-ip]"
    echo ""
    echo "Examples:"
    echo "  $0 myapp.apk                    # Install to first available device"
    echo "  $0 myapp.apk 192.168.56.101    # Install to specific device"
    exit 1
fi

APK_FILE="$1"
DEVICE_IP="$2"

if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "Installing APK to Genymotion device..."

# Check if ADB is available
if ! command -v adb &> /dev/null; then
    echo "Error: ADB not found. Please install Android SDK tools:"
    echo "  brew install --cask android-platform-tools"
    exit 1
fi

# If device IP not specified, try to find running Genymotion devices
if [[ -z "$DEVICE_IP" ]]; then
    echo "Scanning for Genymotion devices..."
    adb devices
    
    # Look for typical Genymotion IP patterns
    DEVICES=$(adb devices | grep "192.168.56." | awk '{print $1}')
    if [[ -z "$DEVICES" ]]; then
        echo "No Genymotion devices found. Please ensure:"
        echo "1. Genymotion virtual device is running"
        echo "2. ADB is enabled in Genymotion settings"
        exit 1
    fi
    
    DEVICE_IP=$(echo "$DEVICES" | head -n 1)
    echo "Using device: $DEVICE_IP"
fi

# Connect to device if not already connected
if ! adb devices | grep -q "$DEVICE_IP.*device"; then
    echo "Connecting to device: $DEVICE_IP"
    adb connect "$DEVICE_IP"
    sleep 2
fi

# Install APK
if adb -s "$DEVICE_IP" install "$APK_FILE"; then
    echo "✅ APK installed successfully!"
    
    # Try to get package name and offer to launch
    if command -v aapt &> /dev/null; then
        PACKAGE_NAME=$(aapt dump badging "$APK_FILE" | grep "name=" | head -n 1 | sed "s/.*name='\([^']*\)'.*/\1/")
        if [[ -n "$PACKAGE_NAME" ]]; then
            read -p "Launch app now? (y/n): " -n 1 -r
            echo
            if [[ $REPLY =~ ^[Yy]$ ]]; then
                adb -s "$DEVICE_IP" shell monkey -p "$PACKAGE_NAME" -c android.intent.category.LAUNCHER 1
            fi
        fi
    fi
else
    echo "❌ Failed to install APK"
    echo "Check that the device is running and ADB is enabled"
fi
EOF

chmod +x "$APK_INSTALLER"
print_success "APK installer script created: $APK_INSTALLER"

# Add ADB tools if not present
if ! command -v adb &> /dev/null; then
    print_status "Installing Android Platform Tools for ADB..."
    if command -v brew &> /dev/null; then
        brew install --cask android-platform-tools
        print_success "ADB tools installed"
    else
        print_warning "Please install ADB tools manually:"
        echo "  brew install --cask android-platform-tools"
    fi
fi

print_success "Genymotion setup completed!"
echo ""
print_status "Setup Summary:"
echo "  License Type: $LICENSE_TYPE"
echo "  Installation Path: $INSTALL_PATH/Genymotion.app"
echo "  Configuration: $GENYMOTION_CONFIG_DIR"
echo "  Scripts: $GENYMOTION_SCRIPTS_DIR"
echo ""
print_status "Management Scripts:"
echo "  Launch Genymotion:   $LAUNCHER_SCRIPT"
echo "  Manage devices:      $DEVICE_SCRIPT <command>"
echo "  Install APK:         $APK_INSTALLER <apk-file>"
echo ""
print_status "Getting Started:"
echo "1. Launch Genymotion:"
echo "   $LAUNCHER_SCRIPT"
echo ""
if [[ "$SKIP_REGISTRATION" != "yes" ]]; then
    echo "2. Create Genymotion account (if needed):"
    echo "   - Sign up at https://www.genymotion.com/"
    echo "   - Choose your license type: $LICENSE_TYPE"
    echo ""
fi
echo "3. Create virtual device:"
echo "   $DEVICE_SCRIPT templates    # List available templates"
echo "   $DEVICE_SCRIPT create MyDevice '<template-name>'"
echo ""
echo "4. Start device and install APK:"
echo "   $DEVICE_SCRIPT start MyDevice"
echo "   $APK_INSTALLER myapp.apk"
echo ""

print_warning "Important Notes:"
echo "- Genymotion Desktop requires VirtualBox for full functionality"
echo "- Free license has limitations on device creation and features"
echo "- Personal/Business licenses offer more device types and cloud features"
echo "- Enable ADB debugging in Genymotion device settings for APK installation"
echo ""

print_status "Device Templates Available:"
echo "- Phone: Galaxy S10, Pixel 4, iPhone-like devices"
echo "- Tablet: Galaxy Tab, Nexus 9, iPad-like devices"  
echo "- Android versions: 7.0 through 13.0"
echo "- Custom resolutions and hardware configurations"

# Create sample device if requested
if [[ "$CREATE_DEVICE" == "yes" ]]; then
    print_status "Creating sample device..."
    echo "This will open Genymotion for device creation"
    "$LAUNCHER_SCRIPT"
    echo ""
    echo "To create device via command line:"
    echo "1. First get available templates:"
    echo "   $DEVICE_SCRIPT templates"
    echo "2. Create device with chosen template:"
    echo "   $DEVICE_SCRIPT create $DEVICE_NAME '<template-name>'"
fi

# Offer to launch Genymotion
read -p "Would you like to launch Genymotion now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Launching Genymotion..."
    "$LAUNCHER_SCRIPT"
fi
