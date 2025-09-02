#!/bin/bash

# Pi Camera Streaming Setup Script
# Created by CiscoPonce
# Installs dependencies and configures the system for optimal performance

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on Raspberry Pi
check_pi() {
    if ! grep -q "Raspberry Pi" /proc/cpuinfo 2>/dev/null; then
        warning "This script is designed for Raspberry Pi. Continue anyway? (y/N)"
        read -r response
        if [[ ! "$response" =~ ^[Yy]$ ]]; then
            exit 1
        fi
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y
    success "System packages updated"
}

# Install Docker and Docker Compose
install_docker() {
    log "Installing Docker and Docker Compose..."
    
    if command -v docker &> /dev/null; then
        warning "Docker is already installed"
        return
    fi
    
    # Install Docker
    curl -fsSL https://get.docker.com -o get-docker.sh
    sudo sh get-docker.sh
    rm get-docker.sh
    
    # Add user to docker group
    sudo usermod -aG docker $USER
    
    # Install Docker Compose
    sudo apt install -y docker-compose-plugin
    
    success "Docker and Docker Compose installed"
    warning "Please log out and back in for Docker group changes to take effect"
}

# Install camera and streaming dependencies
install_dependencies() {
    log "Installing camera and streaming dependencies..."
    
    # Install libcamera tools
    sudo apt install -y libcamera-tools
    
    # Install FFmpeg
    sudo apt install -y ffmpeg
    
    # Install additional tools
    sudo apt install -y curl wget git
    
    success "Dependencies installed"
}

# Enable camera interface
enable_camera() {
    log "Enabling camera interface..."
    
    # Check if camera is already enabled
    if grep -q "camera_auto_detect=1" /boot/config.txt; then
        success "Camera interface already enabled"
        return
    fi
    
    # Enable camera
    echo "camera_auto_detect=1" | sudo tee -a /boot/config.txt
    
    success "Camera interface enabled"
    warning "Reboot required for camera changes to take effect"
}

# Configure system for optimal performance
configure_system() {
    log "Configuring system for optimal performance..."
    
    # Increase GPU memory split for camera
    if ! grep -q "gpu_mem=" /boot/config.txt; then
        echo "gpu_mem=128" | sudo tee -a /boot/config.txt
    fi
    
    # Enable hardware acceleration
    if ! grep -q "dtoverlay=vc4-kms-v3d" /boot/config.txt; then
        echo "dtoverlay=vc4-kms-v3d" | sudo tee -a /boot/config.txt
    fi
    
    # Set CPU governor to performance
    echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils
    
    success "System configured for optimal performance"
}

# Create systemd service for camera streaming
create_service() {
    log "Creating systemd service for camera streaming..."
    
    local service_file="/etc/systemd/system/pi-camera-streaming.service"
    local script_path="$(pwd)/scripts/start-camera.sh"
    
    sudo tee $service_file > /dev/null << EOF
[Unit]
Description=Pi Camera Streaming Service
After=network.target docker.service
Requires=docker.service

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$(pwd)
ExecStart=$script_path
Restart=always
RestartSec=10
Environment=STREAM_NAME=cam
Environment=SRS_HOST=localhost
Environment=SRS_PORT=1935

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    success "Systemd service created"
    
    log "To enable the service:"
    log "  sudo systemctl enable pi-camera-streaming"
    log "To start the service:"
    log "  sudo systemctl start pi-camera-streaming"
}

# Configure firewall
configure_firewall() {
    log "Configuring firewall..."
    
    if command -v ufw &> /dev/null; then
        # Allow necessary ports
        sudo ufw allow 80/tcp    # Web viewer
        sudo ufw allow 1935/tcp  # RTMP
        sudo ufw allow 1985/tcp  # SRS API
        sudo ufw allow 8081/tcp  # HTTP console
        sudo ufw allow 8000:8100/udp  # WebRTC ICE
        
        success "Firewall configured"
    else
        warning "UFW not installed, skipping firewall configuration"
    fi
}

# Create environment file
create_env_file() {
    log "Creating environment configuration..."
    
    if [ ! -f .env ]; then
        cp env.example .env
        success "Environment file created from template"
        log "Please edit .env file with your specific settings"
    else
        warning "Environment file already exists"
    fi
}

# Test camera
test_camera() {
    log "Testing camera..."
    
    if rpicam-vid --list-cameras &> /dev/null; then
        success "Camera test passed"
    else
        error "Camera test failed. Please check camera connection and configuration"
        return 1
    fi
}

# Main setup function
main() {
    log "Pi Camera Streaming Setup Starting..."
    
    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        error "Please do not run this script as root"
        exit 1
    fi
    
    # Check if running on Pi
    check_pi
    
    # Update system
    update_system
    
    # Install dependencies
    install_docker
    install_dependencies
    
    # Configure system
    enable_camera
    configure_system
    
    # Configure services
    create_service
    configure_firewall
    create_env_file
    
    # Test camera
    test_camera
    
    success "Setup completed successfully!"
    
    log "Next steps:"
    log "1. Edit .env file with your settings"
    log "2. Reboot the system: sudo reboot"
    log "3. After reboot, start the services: docker-compose up -d"
    log "4. Start camera streaming: ./scripts/start-camera.sh"
    log "5. View the stream at: http://$(hostname -I | awk '{print $1}')/"
    
    warning "Remember to log out and back in for Docker group changes to take effect"
}

# Run main function
main "$@"
