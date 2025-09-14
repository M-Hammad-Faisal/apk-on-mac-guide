#!/bin/bash

# BlueStacks Setup Script for macOS
# This script automates the installation of BlueStacks Android emulator

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

print_status "Starting BlueStacks setup for macOS..."

# Check if Homebrew is installed
if ! command -v brew &> /dev/null; then
    print_error "Homebrew is not installed. Please install Homebrew first:"
    echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""
    exit 1
fi

# Check system requirements
print_status "Checking system requirements..."

# Check macOS version
macos_version=$(sw_vers -productVersion | cut -d '.' -f 1-2)
required_version="10.12"

if [[ $(echo "$macos_version >= $required_version" | bc -l) -eq 0 ]]; then
    print_error "macOS $required_version or later is required. You have $macos_version"
    exit 1
fi

# Check available disk space (minimum 5GB)
available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
if [[ ${available_space%.*} -lt 5 ]]; then
    print_warning "Low disk space. At least 5GB free space is recommended."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install BlueStacks
print_status "Installing BlueStacks via Homebrew..."

if ! brew list --cask bluestacks &> /dev/null; then
    # Check if BlueStacks cask is available
    if brew search --cask bluestacks | grep -q "bluestacks"; then
        brew install --cask bluestacks
        print_success "BlueStacks installed successfully"
    else
        print_warning "BlueStacks cask not available via Homebrew. Installing manually..."
        print_status "Please download BlueStacks manually from: https://www.bluestacks.com/"
        print_status "After downloading, run the installer and follow the setup wizard."
        
        # Wait for user to complete manual installation
        read -p "Press Enter after you have installed BlueStacks manually..." -r
        
        # Check if BlueStacks is now installed
        if [[ -d "/Applications/BlueStacks.app" ]]; then
            print_success "BlueStacks installation detected"
        else
            print_error "BlueStacks installation not detected. Please ensure it's properly installed."
            exit 1
        fi
    fi
else
    print_success "BlueStacks is already installed"
fi

# Setup instructions
print_status "BlueStacks Setup Instructions:"
echo ""
echo "1. Launch BlueStacks:"
echo "   open -a 'BlueStacks'"
echo ""
echo "2. Complete the initial setup wizard:"
echo "   - Sign in with Google account (optional but recommended)"
echo "   - Configure performance settings based on your Mac specs"
echo "   - Enable virtualization if prompted"
echo ""
echo "3. To install APK files in BlueStacks:"
echo "   - Method 1: Drag and drop APK file to BlueStacks window"
echo "   - Method 2: Click '+' button in My Games tab and select APK file"
echo "   - Method 3: Use 'Install apk' button in BlueStacks interface"
echo ""
echo "4. Performance Tips:"
echo "   - Allocate at least 4GB RAM to BlueStacks for better performance"
echo "   - Enable hardware acceleration in settings"
echo "   - Close unnecessary applications while running BlueStacks"
echo ""

# Check for virtualization support
print_status "Checking virtualization support..."
if sysctl -n machdep.cpu.features | grep -q VMX; then
    print_success "Hardware virtualization is supported"
else
    print_warning "Hardware virtualization may not be available. Performance may be limited."
fi

# Additional setup for ADB access (optional)
print_status "Setting up ADB access to BlueStacks (optional)..."
echo ""
echo "To use ADB with BlueStacks:"
echo "1. Enable ADB in BlueStacks settings:"
echo "   - Open BlueStacks settings"
echo "   - Go to 'Advanced' section"
echo "   - Enable 'Android Debug Bridge (ADB)'"
echo "   - Note the port number (usually 5555)"
echo ""
echo "2. Connect via ADB:"
echo "   adb connect localhost:5555"
echo ""
echo "3. Install APK via ADB:"
echo "   adb install path/to/your/app.apk"
echo ""

print_success "BlueStacks setup completed!"
echo ""
print_status "Next Steps:"
echo "1. Launch BlueStacks and complete setup"
echo "2. Install your APK files using drag-and-drop"
echo "3. Enjoy running Android apps on your Mac!"
echo ""
print_warning "Note: BlueStacks may require macOS accessibility permissions."
print_warning "Grant permissions when prompted for full functionality."

# Offer to launch BlueStacks
read -p "Would you like to launch BlueStacks now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    print_status "Launching BlueStacks..."
    open -a 'BlueStacks' 2>/dev/null || {
        print_error "Could not launch BlueStacks automatically."
        print_status "Please launch BlueStacks manually from Applications folder."
    }
fi
