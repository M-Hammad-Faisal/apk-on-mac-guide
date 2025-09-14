#!/bin/bash

# Docker Android Setup Script for macOS
# This script sets up Docker-based Android containers for APK testing

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
    echo "  --container-name NAME    Docker container name (default: android-container)"
    echo "  --android-version VER    Android version (28|29|30|31|32|33) (default: 30)"
    echo "  --vnc-port PORT         VNC port for remote access (default: 6080)"
    echo "  --adb-port PORT         ADB port forwarding (default: 5555)"
    echo "  --appium-port PORT      Appium server port (default: 4723)"
    echo "  --device-model MODEL    Device model (Samsung Galaxy S6|S10|etc) (default: Samsung Galaxy S10)"
    echo "  --start-container       Start container after creation"
    echo "  --install-selenium      Install Selenium Grid support"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 --container-name my-android --android-version 31 --start-container"
    echo "  $0 --device-model \"Samsung Galaxy S10\" --vnc-port 5900"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Default values
CONTAINER_NAME="android-container"
ANDROID_VERSION="30"
VNC_PORT="6080"
ADB_PORT="5555"
APPIUM_PORT="4723"
DEVICE_MODEL="Samsung Galaxy S10"
START_CONTAINER="no"
INSTALL_SELENIUM="no"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --container-name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        --android-version)
            ANDROID_VERSION="$2"
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
        --appium-port)
            APPIUM_PORT="$2"
            shift 2
            ;;
        --device-model)
            DEVICE_MODEL="$2"
            shift 2
            ;;
        --start-container)
            START_CONTAINER="yes"
            shift
            ;;
        --install-selenium)
            INSTALL_SELENIUM="yes"
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

print_status "Starting Docker Android setup for macOS..."

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker Desktop for Mac first:"
    echo "  Download from: https://www.docker.com/products/docker-desktop"
    echo "  Or use Homebrew: brew install --cask docker"
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker Desktop and try again."
    exit 1
fi

print_success "Docker is installed and running"

# Create docker directory for Android
DOCKER_ANDROID_DIR="$HOME/.docker-android"
mkdir -p "$DOCKER_ANDROID_DIR"
print_status "Docker Android directory: $DOCKER_ANDROID_DIR"

# Determine Docker image based on Android version
case $ANDROID_VERSION in
    28)
        DOCKER_IMAGE="budtmo/docker-android-x86-9.0"
        ;;
    29)
        DOCKER_IMAGE="budtmo/docker-android-x86-10.0"
        ;;
    30)
        DOCKER_IMAGE="budtmo/docker-android-x86-11.0"
        ;;
    31)
        DOCKER_IMAGE="budtmo/docker-android-x86-12.0"
        ;;
    32|33)
        DOCKER_IMAGE="budtmo/docker-android-x86-13.0"
        ;;
    *)
        print_error "Unsupported Android version: $ANDROID_VERSION"
        echo "Supported versions: 28, 29, 30, 31, 32, 33"
        exit 1
        ;;
esac

print_status "Docker image: $DOCKER_IMAGE"

# Pull Docker image
print_status "Pulling Docker Android image (this may take a while)..."
if ! docker pull "$DOCKER_IMAGE"; then
    print_error "Failed to pull Docker image"
    exit 1
fi

print_success "Docker image pulled successfully"

# Create docker-compose file for easier management
COMPOSE_FILE="$DOCKER_ANDROID_DIR/docker-compose.yml"
cat > "$COMPOSE_FILE" << EOF
version: '3.8'

services:
  android:
    image: $DOCKER_IMAGE
    container_name: $CONTAINER_NAME
    privileged: true
    ports:
      - "$VNC_PORT:6080"
      - "$ADB_PORT:5555"
      - "$APPIUM_PORT:4723"
    environment:
      - EMULATOR_DEVICE=$DEVICE_MODEL
      - WEB_VNC=true
      - APPIUM=true
      - CONNECT_TO_GRID=false
      - AUTO_RECORD=false
    volumes:
      - $DOCKER_ANDROID_DIR/shared:/root/tmp
      - $DOCKER_ANDROID_DIR/apks:/root/apks
    networks:
      - android-network

networks:
  android-network:
    driver: bridge
EOF

print_success "Docker Compose file created: $COMPOSE_FILE"

# Create shared directories
mkdir -p "$DOCKER_ANDROID_DIR/shared"
mkdir -p "$DOCKER_ANDROID_DIR/apks"

# Create startup script
START_SCRIPT="$DOCKER_ANDROID_DIR/start-android.sh"
cat > "$START_SCRIPT" << 'EOF'
#!/bin/bash

# Docker Android Start Script
# This script starts the Docker Android container

DOCKER_ANDROID_DIR="$HOME/.docker-android"
cd "$DOCKER_ANDROID_DIR"

echo "Starting Docker Android container..."
echo "This may take a few minutes for the Android system to boot up"
echo ""

# Start container using docker-compose
docker-compose up -d

# Wait for container to be ready
echo "Waiting for Android system to boot..."
sleep 10

# Check container status
if docker ps | grep -q "android-container"; then
    echo ""
    echo "✅ Docker Android container is running!"
    echo ""
    echo "🌐 Web VNC Access: http://localhost:6080"
    echo "📱 ADB Connection: adb connect localhost:5555"
    echo "🤖 Appium Server: http://localhost:4723"
    echo ""
    echo "Useful commands:"
    echo "  docker-compose logs -f     # View container logs"
    echo "  docker-compose stop        # Stop container"
    echo "  docker-compose down        # Stop and remove container"
    echo "  docker exec -it android-container bash  # Access container shell"
    echo ""
else
    echo "❌ Failed to start container"
    echo "Check logs with: docker-compose logs"
    exit 1
fi
EOF

chmod +x "$START_SCRIPT"
print_success "Start script created: $START_SCRIPT"

# Create stop script
STOP_SCRIPT="$DOCKER_ANDROID_DIR/stop-android.sh"
cat > "$STOP_SCRIPT" << 'EOF'
#!/bin/bash

# Docker Android Stop Script
# This script stops the Docker Android container

DOCKER_ANDROID_DIR="$HOME/.docker-android"
cd "$DOCKER_ANDROID_DIR"

echo "Stopping Docker Android container..."
docker-compose down

echo "Container stopped successfully"
EOF

chmod +x "$STOP_SCRIPT"
print_success "Stop script created: $STOP_SCRIPT"

# Create APK installer script for Docker
APK_INSTALL_SCRIPT="$DOCKER_ANDROID_DIR/install-apk-docker.sh"
cat > "$APK_INSTALL_SCRIPT" << 'EOF'
#!/bin/bash

# Docker Android APK Installer
# This script installs APK files to Docker Android container

if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <path-to-apk-file>"
    echo ""
    echo "Example: $0 myapp.apk"
    exit 1
fi

APK_FILE="$1"

if [[ ! -f "$APK_FILE" ]]; then
    echo "Error: APK file not found: $APK_FILE"
    exit 1
fi

echo "Installing APK to Docker Android container..."

# Copy APK to shared directory
DOCKER_ANDROID_DIR="$HOME/.docker-android"
APK_NAME=$(basename "$APK_FILE")
cp "$APK_FILE" "$DOCKER_ANDROID_DIR/apks/$APK_NAME"

# Install via ADB
adb connect localhost:5555
sleep 2

if adb devices | grep -q "5555"; then
    adb install "$DOCKER_ANDROID_DIR/apks/$APK_NAME"
    echo "APK installed successfully!"
    
    # Clean up
    rm "$DOCKER_ANDROID_DIR/apks/$APK_NAME"
else
    echo "Error: Could not connect to Android container"
    echo "Make sure the container is running: $DOCKER_ANDROID_DIR/start-android.sh"
fi
EOF

chmod +x "$APK_INSTALL_SCRIPT"
print_success "APK installer script created: $APK_INSTALL_SCRIPT"

# Create status check script
STATUS_SCRIPT="$DOCKER_ANDROID_DIR/status.sh"
cat > "$STATUS_SCRIPT" << 'EOF'
#!/bin/bash

# Docker Android Status Script
# This script shows the status of Docker Android container

DOCKER_ANDROID_DIR="$HOME/.docker-android"
cd "$DOCKER_ANDROID_DIR"

echo "Docker Android Container Status:"
echo "================================="

if docker ps | grep -q "android-container"; then
    echo "Status: ✅ RUNNING"
    echo ""
    echo "Container Details:"
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}" | grep android-container
    echo ""
    echo "Access Methods:"
    echo "  Web VNC: http://localhost:6080"
    echo "  ADB: adb connect localhost:5555"
    echo "  Appium: http://localhost:4723"
    echo ""
    echo "ADB Connection Status:"
    adb devices
else
    echo "Status: ❌ STOPPED"
    echo ""
    echo "To start: $DOCKER_ANDROID_DIR/start-android.sh"
fi
EOF

chmod +x "$STATUS_SCRIPT"
print_success "Status script created: $STATUS_SCRIPT"

# Install ADB tools if not present
if ! command -v adb &> /dev/null; then
    print_status "Installing Android Platform Tools for ADB..."
    if command -v brew &> /dev/null; then
        brew install --cask android-platform-tools
        print_success "ADB tools installed"
    else
        print_warning "Please install ADB tools manually for APK installation"
        echo "  brew install --cask android-platform-tools"
    fi
fi

print_success "Docker Android setup completed!"
echo ""
print_status "Setup Summary:"
echo "  Container Name: $CONTAINER_NAME"
echo "  Android Version: $ANDROID_VERSION"
echo "  Device Model: $DEVICE_MODEL"
echo "  VNC Port: $VNC_PORT"
echo "  ADB Port: $ADB_PORT"
echo "  Appium Port: $APPIUM_PORT"
echo ""
print_status "Management Scripts:"
echo "  Start container: $START_SCRIPT"
echo "  Stop container: $STOP_SCRIPT"
echo "  Check status: $STATUS_SCRIPT"
echo "  Install APK: $APK_INSTALL_SCRIPT <apk-file>"
echo ""
print_status "Quick Start:"
echo "1. Start the container:"
echo "   $START_SCRIPT"
echo ""
echo "2. Access Android via web browser:"
echo "   open http://localhost:$VNC_PORT"
echo ""
echo "3. Install APK files:"
echo "   $APK_INSTALL_SCRIPT myapp.apk"
echo ""

print_warning "Important Notes:"
echo "- Docker Android containers can be resource-intensive"
echo "- Allow 2-3 minutes for Android system to fully boot"
echo "- Web VNC provides full Android UI access"
echo "- Use ADB for programmatic app installation and testing"
echo ""
echo "Troubleshooting:"
echo "- If container fails to start, check Docker Desktop is running"
echo "- For performance issues, allocate more RAM to Docker Desktop"
echo "- Check firewall settings if VNC/ADB connections fail"

# Offer to start container
if [[ "$START_CONTAINER" == "yes" ]]; then
    print_status "Starting container as requested..."
    "$START_SCRIPT"
else
    read -p "Would you like to start the Android container now? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_status "Starting container..."
        "$START_SCRIPT"
    fi
fi
