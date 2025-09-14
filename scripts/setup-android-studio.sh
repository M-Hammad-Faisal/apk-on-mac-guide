#!/bin/bash

# Android Studio Setup Script for macOS
# This script automates the installation and setup of Android Studio and emulator

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

print_status "Starting Android Studio setup for macOS..."

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
required_version="10.14"

if [[ $(echo "$macos_version >= $required_version" | bc -l) -eq 0 ]]; then
    print_error "macOS $required_version or later is required. You have $macos_version"
    exit 1
fi

# Check available disk space (minimum 10GB)
available_space=$(df -h / | awk 'NR==2 {print $4}' | sed 's/Gi//')
if [[ ${available_space%.*} -lt 10 ]]; then
    print_warning "Low disk space. At least 10GB free space is recommended."
    read -p "Continue anyway? (y/n): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

# Install Android Studio
print_status "Installing Android Studio via Homebrew..."

if ! brew list --cask android-studio &> /dev/null; then
    brew install --cask android-studio
    print_success "Android Studio installed successfully"
else
    print_success "Android Studio is already installed"
fi

# Install Java if not present
print_status "Checking for Java installation..."
if ! command -v java &> /dev/null; then
    print_status "Installing Java..."
    brew install --cask temurin
else
    print_success "Java is already installed"
fi

# Set up Android SDK path
ANDROID_HOME="$HOME/Library/Android/sdk"
print_status "Setting up Android SDK path: $ANDROID_HOME"

# Add to shell profile
shell_profile=""
if [[ $SHELL == *"zsh"* ]]; then
    shell_profile="$HOME/.zshrc"
elif [[ $SHELL == *"bash"* ]]; then
    shell_profile="$HOME/.bash_profile"
fi

if [[ -n "$shell_profile" ]]; then
    if ! grep -q "ANDROID_HOME" "$shell_profile"; then
        echo "" >> "$shell_profile"
        echo "# Android SDK" >> "$shell_profile"
        echo "export ANDROID_HOME=$ANDROID_HOME" >> "$shell_profile"
        echo "export PATH=\$PATH:\$ANDROID_HOME/emulator" >> "$shell_profile"
        echo "export PATH=\$PATH:\$ANDROID_HOME/tools" >> "$shell_profile"
        echo "export PATH=\$PATH:\$ANDROID_HOME/tools/bin" >> "$shell_profile"
        echo "export PATH=\$PATH:\$ANDROID_HOME/platform-tools" >> "$shell_profile"
        print_success "Android SDK paths added to $shell_profile"
    else
        print_success "Android SDK paths already configured"
    fi
fi

# Export for current session
export ANDROID_HOME="$HOME/Library/Android/sdk"
export PATH="$PATH:$ANDROID_HOME/emulator"
export PATH="$PATH:$ANDROID_HOME/tools"
export PATH="$PATH:$ANDROID_HOME/tools/bin"
export PATH="$PATH:$ANDROID_HOME/platform-tools"

print_status "Setup completed! Next steps:"
echo ""
echo "1. Open Android Studio:"
echo "   open -a 'Android Studio'"
echo ""
echo "2. Complete the setup wizard and install SDK components"
echo ""
echo "3. Create a new AVD (Android Virtual Device):"
echo "   - Go to Tools → AVD Manager"
echo "   - Click 'Create Virtual Device'"
echo "   - Choose a device (Pixel 5 recommended)"
echo "   - Download a system image (API 31+ recommended)"
echo "   - Configure settings and create AVD"
echo ""
echo "4. To install APK files, use:"
echo "   ./install-apk.sh path/to/your/app.apk"
echo ""
print_success "Android Studio setup script completed!"

# Check if Intel HAXM is available (for Intel Macs)
if [[ $(uname -m) == "x86_64" ]]; then
    print_status "For better performance, consider installing Intel HAXM:"
    echo "  Download from: https://github.com/intel/haxm/releases"
fi

print_warning "Please restart your terminal or source your shell profile to use ADB commands:"
echo "  source $shell_profile"
