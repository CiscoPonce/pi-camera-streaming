#!/bin/bash

# Pi Camera Streaming Test Script
# Created by CiscoPonce
# Verifies that all components are working correctly

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')]${NC} $1"
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

# Test functions
test_camera() {
    log "Testing camera..."
    
    if command -v rpicam-vid &> /dev/null; then
        if rpicam-vid --list-cameras &> /dev/null; then
            success "Camera detected and available"
            return 0
        else
            error "Camera not detected"
            return 1
        fi
    else
        error "rpicam-vid not found. Install libcamera-tools"
        return 1
    fi
}

test_docker() {
    log "Testing Docker..."
    
    if command -v docker &> /dev/null; then
        if docker ps &> /dev/null; then
            success "Docker is running"
            return 0
        else
            error "Docker is not running or user not in docker group"
            return 1
        fi
    else
        error "Docker not found"
        return 1
    fi
}

test_containers() {
    log "Testing containers..."
    
    if docker-compose ps | grep -q "Up"; then
        success "Containers are running"
        return 0
    else
        warning "Containers not running. Start with: docker-compose up -d"
        return 1
    fi
}

test_srs_api() {
    log "Testing SRS API..."
    
    if curl -s "http://localhost:1985/api/v1/summaries" &> /dev/null; then
        success "SRS API is responding"
        return 0
    else
        error "SRS API not responding"
        return 1
    fi
}

test_web_viewer() {
    log "Testing web viewer..."
    
    if curl -s "http://localhost/" &> /dev/null; then
        success "Web viewer is accessible"
        return 0
    else
        error "Web viewer not accessible"
        return 1
    fi
}

test_network_ports() {
    log "Testing network ports..."
    
    local ports=(80 1935 1985 8081)
    local all_open=true
    
    for port in "${ports[@]}"; do
        if netstat -tuln | grep -q ":$port "; then
            log "Port $port is open"
        else
            warning "Port $port is not open"
            all_open=false
        fi
    done
    
    if $all_open; then
        success "All required ports are open"
        return 0
    else
        warning "Some ports are not open"
        return 1
    fi
}

test_system_resources() {
    log "Testing system resources..."
    
    # Check CPU temperature
    if command -v vcgencmd &> /dev/null; then
        local temp=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
        log "CPU Temperature: ${temp}°C"
        
        if (( $(echo "$temp < 80" | bc -l) )); then
            success "CPU temperature is normal"
        else
            warning "CPU temperature is high: ${temp}°C"
        fi
    fi
    
    # Check memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    log "Memory usage: ${mem_usage}%"
    
    if (( $(echo "$mem_usage < 80" | bc -l) )); then
        success "Memory usage is normal"
    else
        warning "Memory usage is high: ${mem_usage}%"
    fi
}

# Main test function
main() {
    log "Pi Camera Streaming Test Starting..."
    echo
    
    local tests_passed=0
    local total_tests=7
    
    # Run tests
    test_camera && ((tests_passed++))
    echo
    
    test_docker && ((tests_passed++))
    echo
    
    test_containers && ((tests_passed++))
    echo
    
    test_srs_api && ((tests_passed++))
    echo
    
    test_web_viewer && ((tests_passed++))
    echo
    
    test_network_ports && ((tests_passed++))
    echo
    
    test_system_resources && ((tests_passed++))
    echo
    
    # Summary
    log "Test Summary: $tests_passed/$total_tests tests passed"
    
    if [ $tests_passed -eq $total_tests ]; then
        success "All tests passed! System is ready for streaming."
        echo
        log "Next steps:"
        log "1. Start camera streaming: ./scripts/start-camera.sh"
        log "2. View stream at: http://$(hostname -I | awk '{print $1}')/"
    else
        warning "Some tests failed. Please check the issues above."
        echo
        log "Common fixes:"
        log "1. Run setup script: ./scripts/setup.sh"
        log "2. Start containers: docker-compose up -d"
        log "3. Enable camera: sudo raspi-config"
        log "4. Reboot if needed: sudo reboot"
    fi
}

# Run main function
main "$@"
