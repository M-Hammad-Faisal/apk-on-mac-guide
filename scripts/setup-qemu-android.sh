#!/bin/bash

# QEMU Android Emulator Setup Script for macOS
# This script sets up QEMU for running Android x86 on Mac

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

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

print_status "Starting QEMU Android setup for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check system requirements
print_status "Checking system requirements..."

# Check available disk space (minimum 8GB)
available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
if [[ ${available_space%.*} -lt 8 ]]; then
    print_warning "Low disk space. At least 8GB free space is recommended."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install QEMU
print_status "Installing QEMU via Homebrew..."

if ! command -v qemu-system-x86_64 &> /dev/null; then
    brew install qemu
    print_success "QEMU installed successfully"
else
    print_success "QEMU is already installed"
fi

# Create QEMU Android directory
QEMU_ANDROID_DIR="$HOME/.qemu-android"
mkdir -p "$QEMU_ANDROID_DIR"
print_status "QEMU Android directory: $QEMU_ANDROID_DIR"

# Download Android x86 ISO (if not exists)
ANDROID_ISO="$QEMU_ANDROID_DIR/android-x86_64-9.0-r2.iso"
if [[ ! -f "$ANDROID_ISO" ]]; then
    print_status "Downloading Android x86 ISO (this may take a while)..."
    print_warning "Please download Android x86 manually from: https://www.android-x86.org/"
    print_status "Download the 64-bit ISO and place it at: $ANDROID_ISO"
    read -p "Press Enter after you have downloaded the ISO to the specified location..." -r
    
    if [[ ! -f "$ANDROID_ISO" ]]; then
        print_error "Android x86 ISO not found. Please download it manually."
        exit 1
    fi
else
    print_success "Android x86 ISO found"
fi

# Create virtual disk
ANDROID_IMG="$QEMU_ANDROID_DIR/android.qcow2"
if [[ ! -f "$ANDROID_IMG" ]]; then
    print_status "Creating virtual disk (8GB)..."
    qemu-img create -f qcow2 "$ANDROID_IMG" 8G
    print_success "Virtual disk created"
else
    print_success "Virtual disk already exists"
fi

# Create QEMU launch script
LAUNCH_SCRIPT="$QEMU_ANDROID_DIR/launch-android.sh"
cat > "$LAUNCH_SCRIPT" << 'EOF'
#!/bin/bash

# QEMU Android Launch Script
# This script launches Android x86 in QEMU

QEMU_ANDROID_DIR="$HOME/.qemu-android"
ANDROID_ISO="$QEMU_ANDROID_DIR/android-x86_64-9.0-r2.iso"
ANDROID_IMG="$QEMU_ANDROID_DIR/android.qcow2"

# Default configuration
MEMORY="4096"
CPUS="4"
VNC_PORT="5901"
ADB_PORT="5555"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--memory)
            MEMORY="$2"
            shift 2
            ;;
        -c|--cpus)
            CPUS="$2"
            shift 2
            ;;
        --vnc-port)
            VNC_PORT="$2"
            shift 2
            ;;
        --adb-port)
            ADB_PORT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  -m, --memory     RAM allocation in MB (default: 4096)"
            echo "  -c, --cpus       Number of CPU cores (default: 4)"
            echo "  --vnc-port       VNC port for remote access (default: 5901)"
            echo "  --adb-port       ADB port forwarding (default: 5555)"
            echo "  -h, --help       Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

echo "Starting QEMU Android emulator..."
echo "Memory: ${MEMORY}MB, CPUs: $CPUS"
echo "VNC: localhost:$VNC_PORT, ADB: localhost:$ADB_PORT"
echo ""
echo "To connect via VNC: vnc://localhost:$VNC_PORT"
echo "To connect via ADB: adb connect localhost:$ADB_PORT"
echo ""

# Check if running first time (boot from ISO) or regular boot
if [[ ! -f "$QEMU_ANDROID_DIR/.installed" ]]; then
    echo "First boot - installing Android x86..."
    echo "After installation, create file: touch $QEMU_ANDROID_DIR/.installed"
    BOOT_OPTION="-boot d -cdrom \"$ANDROID_ISO\""
else
    echo "Regular boot from installed system..."
    BOOT_OPTION=""
fi

# Launch QEMU with hardware acceleration
if [[ $(uname -m) == "arm64" ]]; then
    # Apple Silicon Mac
    eval qemu-system-x86_64 \
        -accel hvf \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -hda "\"$ANDROID_IMG\"" \
        $BOOT_OPTION \
        -netdev user,id=net0,hostfwd=tcp::"$ADB_PORT"-:5555 \
        -device rtl8139,netdev=net0 \
        -vnc :"$(($VNC_PORT - 5900))" \
        -display none \
        -vga std
else
    # Intel Mac
    eval qemu-system-x86_64 \
        -accel hvf \
        -m "$MEMORY" \
        -smp "$CPUS" \
        -hda "\"$ANDROID_IMG\"" \
        $BOOT_OPTION \
        -netdev user,id=net0,hostfwd=tcp::"$ADB_PORT"-:5555 \
        -device rtl8139,netdev=net0 \
        -vnc :"$(($VNC_PORT - 5900))" \
        -display none \
        -vga std
fi
EOF

chmod +x "$LAUNCH_SCRIPT"
print_success "Launch script created: $LAUNCH_SCRIPT"

# Create ADB connection script
ADB_SCRIPT="$QEMU_ANDROID_DIR/connect-adb.sh"
cat > "$ADB_SCRIPT" << 'EOF'
#!/bin/bash

# Connect to QEMU Android via ADB
ADB_PORT="5555"

echo "Connecting to QEMU Android via ADB..."
adb connect localhost:$ADB_PORT

echo "Connected devices:"
adb devices

echo ""
echo "Useful ADB commands:"
echo "  adb install app.apk          - Install APK"
echo "  adb shell                    - Open shell"
echo "  adb logcat                   - View logs"
echo "  adb disconnect               - Disconnect"
EOF

chmod +x "$ADB_SCRIPT"
print_success "ADB connection script created: $ADB_SCRIPT"

# Install VNC viewer if not present
if ! command -v open &> /dev/null || ! open -Ra "VNC Viewer" --args --version &> /dev/null; then
    print_status "Installing VNC Viewer for remote access..."
    if ! brew list --cask vnc-viewer &> /dev/null; then
        brew install --cask vnc-viewer
        print_success "VNC Viewer installed"
    fi
fi

print_success "QEMU Android setup completed!"
echo ""
print_status "Next Steps:"
echo "1. Launch Android emulator:"
echo "   $LAUNCH_SCRIPT"
echo ""
echo "2. Connect via VNC to complete Android setup:"
echo "   open vnc://localhost:5901"
echo ""
echo "3. After Android installation, mark as installed:"
echo "   touch $QEMU_ANDROID_DIR/.installed"
echo ""
echo "4. Connect ADB and install APKs:"
echo "   $ADB_SCRIPT"
echo "   adb install your-app.apk"
echo ""
print_warning "Performance Tips:"
echo "- QEMU on Mac may be slower than native emulators"
echo "- Consider using Android Studio AVD for better performance"
echo "- Ensure sufficient RAM allocation (4GB+ recommended)"
echo ""
print_warning "Troubleshooting:"
echo "- If VNC connection fails, check firewall settings"
echo "- For ADB issues, ensure port 5555 is not blocked"
echo "- On Apple Silicon, x86 emulation may be slow"
