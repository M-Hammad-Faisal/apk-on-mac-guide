#!/bin/bash

# Waydroid Setup Script for macOS
# This script sets up Waydroid (Linux Android container) on Mac via Docker/VM

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
    echo "  --method METHOD          Setup method (docker|multipass|utm) (default: docker)"
    echo "  --distro DISTRO         Linux distribution (ubuntu|debian|arch) (default: ubuntu)"
    echo "  --version VERSION       Distribution version (default: 22.04 for Ubuntu)"
    echo "  --memory RAM            RAM allocation in MB (default: 4096)"
    echo "  --disk DISK            Disk size in GB (default: 20)"
    echo "  --android-version VER   Android version (11|12|13) (default: 11)"
    echo "  --vm-name NAME          VM name (default: waydroid-vm)"
    echo "  --start-vm              Start VM/container after setup"
    echo "  --install-apps          Install common Android apps after setup"
    echo "  -h, --help              Show this help message"
    echo ""
    echo "Methods:"
    echo "  docker      Use Docker with Linux container (fastest setup)"
    echo "  multipass   Use Ubuntu Multipass VM (good balance)"
    echo "  utm         Use UTM virtual machine (best performance)"
    echo ""
    echo "Examples:"
    echo "  $0 --method docker --start-vm"
    echo "  $0 --method multipass --memory 8192 --disk 30"
    echo "  $0 --method utm --vm-name my-waydroid"
}

# Check if running on macOS
if [[ "$OSTYPE" != "darwin"* ]]; then
    print_error "This script is designed for macOS only."
    exit 1
fi

# Default values
METHOD="docker"
DISTRO="ubuntu"
VERSION="22.04"
MEMORY="4096"
DISK="20"
ANDROID_VERSION="11"
VM_NAME="waydroid-vm"
START_VM="no"
INSTALL_APPS="no"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --method)
            METHOD="$2"
            shift 2
            ;;
        --distro)
            DISTRO="$2"
            shift 2
            ;;
        --version)
            VERSION="$2"
            shift 2
            ;;
        --memory)
            MEMORY="$2"
            shift 2
            ;;
        --disk)
            DISK="$2"
            shift 2
            ;;
        --android-version)
            ANDROID_VERSION="$2"
            shift 2
            ;;
        --vm-name)
            VM_NAME="$2"
            shift 2
            ;;
        --start-vm)
            START_VM="yes"
            shift
            ;;
        --install-apps)
            INSTALL_APPS="yes"
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

print_status "Starting Waydroid setup for macOS using method: $METHOD"

# Validate method
if [[ ! "$METHOD" =~ ^(docker|multipass|utm)$ ]]; then
    print_error "Invalid method: $METHOD"
    print_error "Supported methods: docker, multipass, utm"
    exit 1
fi

# Create Waydroid directory
WAYDROID_DIR="$HOME/.waydroid-mac"
mkdir -p "$WAYDROID_DIR"
print_status "Waydroid directory: $WAYDROID_DIR"

# Method-specific setup
case $METHOD in
    "docker")
        setup_docker_waydroid
        ;;
    "multipass")
        setup_multipass_waydroid
        ;;
    "utm")
        setup_utm_waydroid
        ;;
esac

# Function to setup Docker-based Waydroid
setup_docker_waydroid() {
    print_status "Setting up Waydroid via Docker..."
    
    # Check if Docker is installed
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Installing Docker Desktop..."
        if command -v brew &> /dev/null; then
            brew install --cask docker
            print_status "Please start Docker Desktop and run this script again"
            exit 1
        else
            print_error "Please install Docker Desktop manually from: https://www.docker.com/products/docker-desktop"
            exit 1
        fi
    fi
    
    # Check if Docker is running
    if ! docker info &> /dev/null; then
        print_error "Docker is not running. Please start Docker Desktop and try again."
        exit 1
    fi
    
    # Create Docker Compose file for Waydroid
    COMPOSE_FILE="$WAYDROID_DIR/docker-compose.yml"
    cat > "$COMPOSE_FILE" << EOF
version: '3.8'

services:
  waydroid:
    image: lscr.io/linuxserver/webtop:ubuntu-mate
    container_name: waydroid-container
    privileged: true
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=America/New_York
      - SUBFOLDER=/
      - KEYBOARD=en-us-qwerty
      - TITLE=Waydroid
    volumes:
      - $WAYDROID_DIR/config:/config
      - $WAYDROID_DIR/shared:/shared
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "3000:3000"
      - "3001:3001"
    restart: unless-stopped
    shm_size: "1gb"
    devices:
      - /dev/dri:/dev/dri
    networks:
      - waydroid-net

networks:
  waydroid-net:
    driver: bridge
EOF
    
    print_success "Docker Compose file created: $COMPOSE_FILE"
    
    # Create startup script
    START_SCRIPT="$WAYDROID_DIR/start-waydroid.sh"
    cat > "$START_SCRIPT" << 'EOF'
#!/bin/bash

# Waydroid Docker Start Script
WAYDROID_DIR="$HOME/.waydroid-mac"
cd "$WAYDROID_DIR"

echo "Starting Waydroid container..."
docker-compose up -d

echo "Waiting for container to start..."
sleep 10

if docker ps | grep -q "waydroid-container"; then
    echo "✅ Waydroid container is running!"
    echo ""
    echo "🌐 Access via web browser: http://localhost:3000"
    echo "🔧 VNC access: http://localhost:3001"
    echo ""
    echo "To install Waydroid inside the container:"
    echo "1. Open http://localhost:3000 in your browser"
    echo "2. Open terminal in the web desktop"
    echo "3. Run the Waydroid installation commands:"
    echo "   sudo apt update && sudo apt install curl ca-certificates -y"
    echo "   curl https://repo.waydro.id | sudo bash"
    echo "   sudo apt install waydroid -y"
    echo "   sudo waydroid init"
    echo "   waydroid session start &"
    echo "   waydroid show-full-ui"
else
    echo "❌ Failed to start container"
    docker-compose logs
fi
EOF
    
    chmod +x "$START_SCRIPT"
    print_success "Start script created: $START_SCRIPT"
    
    # Create stop script
    STOP_SCRIPT="$WAYDROID_DIR/stop-waydroid.sh"
    cat > "$STOP_SCRIPT" << 'EOF'
#!/bin/bash

WAYDROID_DIR="$HOME/.waydroid-mac"
cd "$WAYDROID_DIR"

echo "Stopping Waydroid container..."
docker-compose down

echo "Container stopped"
EOF
    
    chmod +x "$STOP_SCRIPT"
    
    # Create shared directory
    mkdir -p "$WAYDROID_DIR/config"
    mkdir -p "$WAYDROID_DIR/shared"
    
    print_success "Docker Waydroid setup completed!"
    echo ""
    print_status "Quick Start:"
    echo "1. Start container: $START_SCRIPT"
    echo "2. Open browser: http://localhost:3000"
    echo "3. Install Waydroid in the web desktop terminal"
    echo "4. Stop container: $STOP_SCRIPT"
}

# Function to setup Multipass-based Waydroid  
setup_multipass_waydroid() {
    print_status "Setting up Waydroid via Ubuntu Multipass..."
    
    # Check if Multipass is installed
    if ! command -v multipass &> /dev/null; then
        print_status "Installing Ubuntu Multipass..."
        if command -v brew &> /dev/null; then
            brew install --cask multipass
            print_success "Multipass installed"
        else
            print_error "Please install Multipass manually from: https://multipass.run/"
            exit 1
        fi
    fi
    
    # Create cloud-init file for Waydroid
    CLOUD_INIT="$WAYDROID_DIR/cloud-init.yaml"
    cat > "$CLOUD_INIT" << EOF
#cloud-config
package_update: true
package_upgrade: true
packages:
  - curl
  - wget
  - ca-certificates
  - gnupg
  - lsb-release
  - xfce4
  - xfce4-terminal
  - xrdp
  - firefox

runcmd:
  - systemctl enable xrdp
  - systemctl start xrdp
  - echo "ubuntu:waydroid123" | chpasswd
  - curl https://repo.waydro.id | sudo bash
  - apt update
  - apt install waydroid -y
  - waydroid init -s GAPPS -f
  - systemctl enable waydroid-container
  - echo "Waydroid setup completed" > /home/ubuntu/setup-complete.txt

users:
  - default
  - name: ubuntu
    sudo: ALL=(ALL) NOPASSWD:ALL
    shell: /bin/bash
EOF
    
    # Launch Multipass VM
    print_status "Creating Ubuntu VM with Waydroid..."
    multipass launch $VERSION \
        --name "$VM_NAME" \
        --cpus 4 \
        --mem "${MEMORY}M" \
        --disk "${DISK}G" \
        --cloud-init "$CLOUD_INIT"
    
    print_success "VM created: $VM_NAME"
    
    # Create connection script
    CONNECT_SCRIPT="$WAYDROID_DIR/connect-waydroid.sh"
    cat > "$CONNECT_SCRIPT" << EOF
#!/bin/bash

# Connect to Waydroid VM
VM_NAME="$VM_NAME"

echo "Connecting to Waydroid VM..."
multipass shell "\$VM_NAME"
EOF
    
    chmod +x "$CONNECT_SCRIPT"
    
    # Create RDP connection info
    RDP_SCRIPT="$WAYDROID_DIR/rdp-connect.sh"
    cat > "$RDP_SCRIPT" << EOF
#!/bin/bash

# Connect via Remote Desktop
VM_NAME="$VM_NAME"
VM_IP=\$(multipass info "\$VM_NAME" | grep IPv4 | awk '{print \$2}')

echo "Waydroid VM IP: \$VM_IP"
echo "RDP Connection Details:"
echo "  Address: \$VM_IP:3389"
echo "  Username: ubuntu"
echo "  Password: waydroid123"
echo ""
echo "To connect via RDP:"
echo "  open rdp://ubuntu:waydroid123@\$VM_IP"
echo ""
echo "Or use Microsoft Remote Desktop app from Mac App Store"
EOF
    
    chmod +x "$RDP_SCRIPT"
    
    print_success "Multipass Waydroid setup completed!"
    echo ""
    print_status "VM Management:"
    echo "  Connect shell: $CONNECT_SCRIPT"
    echo "  RDP info: $RDP_SCRIPT"
    echo "  Start VM: multipass start $VM_NAME"
    echo "  Stop VM: multipass stop $VM_NAME"
    echo "  Delete VM: multipass delete $VM_NAME && multipass purge"
}

# Function to setup UTM-based Waydroid
setup_utm_waydroid() {
    print_status "Setting up Waydroid via UTM..."
    
    # Check if UTM is installed
    if [[ ! -d "/Applications/UTM.app" ]]; then
        print_status "Installing UTM..."
        if command -v brew &> /dev/null; then
            brew install --cask utm
            print_success "UTM installed"
        else
            print_error "Please install UTM manually from: https://mac.getutm.app/"
            print_status "Or from Mac App Store"
            exit 1
        fi
    fi
    
    # Create UTM VM configuration guide
    UTM_GUIDE="$WAYDROID_DIR/utm-setup-guide.txt"
    cat > "$UTM_GUIDE" << EOF
UTM Waydroid Setup Guide
========================

1. Manual UTM VM Creation:
   - Open UTM application
   - Click "Create a New Virtual Machine"
   - Choose "Virtualize" (for Apple Silicon) or "Emulate" (for Intel)
   
2. VM Configuration:
   - Operating System: Linux
   - Memory: ${MEMORY}MB
   - Storage: ${DISK}GB
   - ISO: Download Ubuntu $VERSION ISO from https://ubuntu.com/download/desktop
   
3. Ubuntu Installation:
   - Boot from ISO and install Ubuntu
   - Username: ubuntu
   - Password: waydroid123
   
4. Waydroid Installation (run in VM terminal):
   sudo apt update && sudo apt upgrade -y
   curl https://repo.waydro.id | sudo bash
   sudo apt update
   sudo apt install waydroid -y
   sudo waydroid init -s GAPPS -f
   waydroid session start &
   waydroid show-full-ui

5. Post-Installation:
   - Install APK files: waydroid app install /path/to/app.apk
   - Launch apps: waydroid app launch com.package.name
   - Full UI mode: waydroid show-full-ui
   
Network Access:
- VM IP can be used for ADB connection
- Set up port forwarding for external access
- Use 'ip addr' command to find VM IP

Performance Tips:
- Enable hardware acceleration in UTM
- Allocate sufficient RAM (4GB+ recommended)
- Use SSD storage for better performance
- Enable GPU acceleration if available
EOF
    
    print_success "UTM setup guide created: $UTM_GUIDE"
    
    # Create helper scripts for UTM
    HELPER_SCRIPT="$WAYDROID_DIR/utm-helpers.sh"
    cat > "$HELPER_SCRIPT" << 'EOF'
#!/bin/bash

# UTM Waydroid Helper Functions

show_usage() {
    echo "Usage: $0 <command>"
    echo ""
    echo "Commands:"
    echo "  guide       Show setup guide"
    echo "  download    Download Ubuntu ISO"
    echo "  launch      Launch UTM application"
    echo ""
}

case "${1:-help}" in
    guide)
        cat "$HOME/.waydroid-mac/utm-setup-guide.txt"
        ;;
    download)
        echo "Downloading Ubuntu ISO..."
        ISO_URL="https://releases.ubuntu.com/22.04/ubuntu-22.04.3-desktop-amd64.iso"
        curl -L -o "$HOME/.waydroid-mac/ubuntu-22.04-desktop.iso" "$ISO_URL"
        echo "ISO downloaded to: $HOME/.waydroid-mac/ubuntu-22.04-desktop.iso"
        ;;
    launch)
        open -a UTM
        ;;
    help|*)
        show_usage
        ;;
esac
EOF
    
    chmod +x "$HELPER_SCRIPT"
    
    print_success "UTM Waydroid setup completed!"
    echo ""
    print_status "Next Steps:"
    echo "1. Read setup guide: cat $UTM_GUIDE"
    echo "2. Download ISO: $HELPER_SCRIPT download"
    echo "3. Launch UTM: $HELPER_SCRIPT launch"
    echo "4. Create VM manually following the guide"
}

# Create APK installer for Waydroid
APK_INSTALLER="$WAYDROID_DIR/install-apk-waydroid.sh"
cat > "$APK_INSTALLER" << EOF
#!/bin/bash

# Waydroid APK Installer
# This script helps install APK files to Waydroid

if [[ \$# -eq 0 ]]; then
    echo "Usage: \$0 <path-to-apk-file> [waydroid-session]"
    echo ""
    echo "Examples:"
    echo "  \$0 myapp.apk"
    echo "  \$0 myapp.apk --container"     # For Docker method"
    echo "  \$0 myapp.apk --vm-ip 192.168.64.2"  # For VM methods"
    exit 1
fi

APK_FILE="\$1"
METHOD="\${2:-local}"

if [[ ! -f "\$APK_FILE" ]]; then
    echo "Error: APK file not found: \$APK_FILE"
    exit 1
fi

case \$METHOD in
    --container)
        echo "Installing APK via Docker container..."
        docker exec waydroid-container waydroid app install "/shared/\$(basename "\$APK_FILE")"
        ;;
    --vm-ip)
        VM_IP="\$3"
        if [[ -z "\$VM_IP" ]]; then
            echo "Error: VM IP required for --vm-ip option"
            exit 1
        fi
        echo "Installing APK via VM at \$VM_IP..."
        scp "\$APK_FILE" "ubuntu@\$VM_IP:/tmp/"
        ssh ubuntu@\$VM_IP "waydroid app install /tmp/\$(basename "\$APK_FILE")"
        ;;
    *)
        echo "Installing APK to local Waydroid session..."
        waydroid app install "\$APK_FILE"
        ;;
esac

echo "APK installation completed!"
EOF

chmod +x "$APK_INSTALLER"
print_success "APK installer created: $APK_INSTALLER"

# Create status check script
STATUS_SCRIPT="$WAYDROID_DIR/status.sh"
cat > "$STATUS_SCRIPT" << EOF
#!/bin/bash

# Waydroid Status Check Script
METHOD="$METHOD"

echo "Waydroid Setup Status ($METHOD method):"
echo "======================================="

case \$METHOD in
    docker)
        if docker ps | grep -q "waydroid-container"; then
            echo "Status: ✅ RUNNING"
            echo "Web Access: http://localhost:3000"
            echo "VNC Access: http://localhost:3001"
        else
            echo "Status: ❌ STOPPED"
            echo "To start: $WAYDROID_DIR/start-waydroid.sh"
        fi
        ;;
    multipass)
        if multipass info "$VM_NAME" | grep -q "Running"; then
            echo "Status: ✅ RUNNING"
            VM_IP=\$(multipass info "$VM_NAME" | grep IPv4 | awk '{print \$2}')
            echo "VM IP: \$VM_IP"
            echo "RDP: rdp://ubuntu:waydroid123@\$VM_IP"
        else
            echo "Status: ❌ STOPPED"
            echo "To start: multipass start $VM_NAME"
        fi
        ;;
    utm)
        echo "Status: Manual check required"
        echo "Open UTM app to check VM status"
        echo "Guide: cat $UTM_GUIDE"
        ;;
esac
EOF

chmod +x "$STATUS_SCRIPT"

print_success "Waydroid setup completed!"
echo ""
print_status "Setup Summary:"
echo "  Method: $METHOD"
echo "  VM/Container Name: $VM_NAME"
echo "  Memory: ${MEMORY}MB"
echo "  Disk: ${DISK}GB"
echo "  Android Version: $ANDROID_VERSION"
echo ""
print_status "Management Scripts:"
echo "  Status check: $STATUS_SCRIPT"
echo "  Install APK: $APK_INSTALLER <apk-file>"

case $METHOD in
    docker)
        echo "  Start: $WAYDROID_DIR/start-waydroid.sh"
        echo "  Stop: $WAYDROID_DIR/stop-waydroid.sh"
        ;;
    multipass)
        echo "  Connect: $WAYDROID_DIR/connect-waydroid.sh"
        echo "  RDP info: $WAYDROID_DIR/rdp-connect.sh"
        ;;
    utm)
        echo "  Helper: $WAYDROID_DIR/utm-helpers.sh"
        echo "  Guide: cat $UTM_GUIDE"
        ;;
esac

print_warning "Important Notes:"
echo "- Waydroid on Mac requires Linux VM/container (no native support)"
echo "- Performance may vary depending on chosen method"
echo "- Docker method is fastest to set up but may have limitations"
echo "- VM methods provide better compatibility but require more setup"
echo "- Google Play Store requires GAPPS initialization"

# Start VM/container if requested
if [[ "$START_VM" == "yes" ]]; then
    case $METHOD in
        docker)
            print_status "Starting Docker container..."
            "$WAYDROID_DIR/start-waydroid.sh"
            ;;
        multipass)
            print_status "VM created and should be starting..."
            multipass info "$VM_NAME"
            ;;
        utm)
            print_status "Please create and start VM manually using UTM"
            "$WAYDROID_DIR/utm-helpers.sh" launch
            ;;
    esac
fi
