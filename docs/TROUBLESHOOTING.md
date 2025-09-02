# Troubleshooting Guide

This guide helps you diagnose and resolve common issues with the Pi Camera Streaming project.

## Common Issues

### Camera Not Detected

**Symptoms:**
- Error: "No cameras detected"
- Camera not listed in `rpicam-vid --list-cameras`

**Solutions:**
1. **Check physical connection**
   ```bash
   # Verify camera is properly connected
   lsusb | grep -i camera
   ```

2. **Enable camera interface**
   ```bash
   sudo raspi-config
   # Navigate to: Interface Options > Camera > Enable
   ```

3. **Check camera module**
   ```bash
   # Test camera with simple command
   rpicam-hello --list-cameras
   ```

4. **Verify camera module compatibility**
   - Ensure you're using Camera Module 3
   - Check ribbon cable connection
   - Try reseating the camera module

### High CPU Usage

**Symptoms:**
- System becomes unresponsive
- High CPU usage in `top` or `htop`
- Temperature warnings

**Solutions:**
1. **Reduce video quality**
   ```bash
   # Use night profile for lower CPU usage
   ./scripts/start-camera.sh --profile night
   ```

2. **Optimize camera settings**
   ```bash
   # Use lower resolution and framerate
   ./scripts/start-camera.sh --width 640 --height 480 --fps 15
   ```

3. **Check for background processes**
   ```bash
   # Kill unnecessary processes
   sudo systemctl stop bluetooth
   sudo systemctl stop hciuart
   ```

4. **Monitor temperature**
   ```bash
   # Check CPU temperature
   vcgencmd measure_temp
   
   # If temperature > 80°C, add cooling
   ```

### Network Connection Issues

**Symptoms:**
- Stream not accessible from browser
- Connection timeouts
- Poor video quality

**Solutions:**
1. **Check network connectivity**
   ```bash
   # Test local connectivity
   curl -I http://localhost:8081/live/cam.flv
   
   # Test external connectivity
   curl -I http://$(hostname -I | awk '{print $1}'):8081/live/cam.flv
   ```

2. **Verify port accessibility**
   ```bash
   # Check if ports are open
   netstat -tulpn | grep -E "(80|1935|1985|8081)"
   ```

3. **Check firewall settings**
   ```bash
   # Allow necessary ports
   sudo ufw allow 80/tcp
   sudo ufw allow 1935/tcp
   sudo ufw allow 1985/tcp
   sudo ufw allow 8081/tcp
   sudo ufw allow 8000:8100/udp
   ```

4. **Test with different protocols**
   - Try WebRTC first: `http://<PI_IP>/`
   - Fallback to FLV: `http://<PI_IP>:8081/live/cam.flv`

### Docker Container Issues

**Symptoms:**
- Containers not starting
- Container restart loops
- Permission errors

**Solutions:**
1. **Check Docker status**
   ```bash
   # Verify Docker is running
   sudo systemctl status docker
   
   # Check container status
   docker ps -a
   ```

2. **Restart containers**
   ```bash
   # Stop all containers
   docker-compose down
   
   # Start containers
   docker-compose up -d
   ```

3. **Check container logs**
   ```bash
   # View SRS logs
   docker logs srs
   
   # View nginx logs
   docker logs cam-viewer
   ```

4. **Fix permission issues**
   ```bash
   # Add user to docker group
   sudo usermod -aG docker $USER
   
   # Log out and back in
   ```

### Video Quality Issues

**Symptoms:**
- Blurry or pixelated video
- Choppy playback
- Color issues

**Solutions:**
1. **Adjust camera settings**
   ```bash
   # Use higher quality profile
   ./scripts/start-camera.sh --profile day
   
   # Increase bitrate
   ./scripts/start-camera.sh --bitrate 8000000
   ```

2. **Check lighting conditions**
   ```bash
   # Adjust exposure for better quality
   rpicam-vid --exposure auto --gain auto
   ```

3. **Optimize network settings**
   ```bash
   # Ensure sufficient bandwidth
   # Check network speed: speedtest-cli
   ```

4. **Verify camera focus**
   ```bash
   # Set manual focus
   rpicam-vid --lens-position 0
   ```

### Audio Issues

**Symptoms:**
- No audio in stream
- Audio sync issues
- Audio quality problems

**Solutions:**
1. **Check audio configuration**
   ```bash
   # List audio devices
   arecord -l
   
   # Test audio recording
   arecord -d 5 test.wav
   ```

2. **Enable audio in stream**
   ```bash
   # Add audio to camera stream
   rpicam-vid --audio --audio-device hw:1,0
   ```

3. **Configure SRS for audio**
   ```conf
   # In srs.conf, enable audio
   vhost __defaultVhost__ {
       rtc {
           enabled on;
           rtmp_to_rtc on;
           rtc_to_rtmp on;
       }
   }
   ```

## Diagnostic Commands

### System Health Check
```bash
#!/bin/bash
# system-health.sh

echo "=== System Health Check ==="

# CPU and temperature
echo "CPU Temperature:"
vcgencmd measure_temp

echo "CPU Usage:"
top -b -n1 | head -20

# Memory usage
echo "Memory Usage:"
free -h

# Disk usage
echo "Disk Usage:"
df -h

# Network status
echo "Network Interfaces:"
ip addr show

# Docker status
echo "Docker Status:"
docker ps

# Camera status
echo "Camera Status:"
rpicam-vid --list-cameras

# Streaming status
echo "Streaming Status:"
ps aux | grep rpicam-vid
```

### Network Diagnostics
```bash
#!/bin/bash
# network-diagnostics.sh

echo "=== Network Diagnostics ==="

# Check local connectivity
echo "Local connectivity:"
curl -I http://localhost:8081/live/cam.flv

# Check external connectivity
PI_IP=$(hostname -I | awk '{print $1}')
echo "External connectivity to $PI_IP:"
curl -I http://$PI_IP:8081/live/cam.flv

# Check port accessibility
echo "Port accessibility:"
netstat -tulpn | grep -E "(80|1935|1985|8081)"

# Check firewall
echo "Firewall status:"
sudo ufw status
```

### Performance Monitoring
```bash
#!/bin/bash
# performance-monitor.sh

echo "=== Performance Monitoring ==="

# Monitor for 30 seconds
for i in {1..30}; do
    echo "Sample $i:"
    
    # CPU usage
    CPU=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    echo "  CPU: ${CPU}%"
    
    # Temperature
    TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    echo "  Temperature: ${TEMP}°C"
    
    # Memory usage
    MEM=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    echo "  Memory: ${MEM}%"
    
    # Network usage
    NET=$(cat /proc/net/dev | grep eth0 | awk '{print $2, $10}')
    echo "  Network: RX/TX bytes"
    
    sleep 1
done
```

## Log Analysis

### SRS Logs
```bash
# View SRS logs
docker logs srs

# Follow SRS logs in real-time
docker logs -f srs

# Filter for errors
docker logs srs 2>&1 | grep -i error
```

### System Logs
```bash
# View system logs
journalctl -u pi-camera-streaming

# View camera-related logs
journalctl | grep -i camera

# View network logs
journalctl | grep -i network
```

### Nginx Logs
```bash
# View nginx access logs
docker exec cam-viewer cat /var/log/nginx/access.log

# View nginx error logs
docker exec cam-viewer cat /var/log/nginx/error.log
```

## Recovery Procedures

### Complete System Reset
```bash
#!/bin/bash
# reset-system.sh

echo "Resetting Pi Camera Streaming system..."

# Stop all services
docker-compose down
pkill -f rpicam-vid

# Clean up containers
docker system prune -f

# Restart Docker
sudo systemctl restart docker

# Start services
docker-compose up -d

# Wait for services to start
sleep 10

# Start camera streaming
./scripts/start-camera.sh --profile night

echo "System reset complete"
```

### Camera Reset
```bash
#!/bin/bash
# reset-camera.sh

echo "Resetting camera..."

# Stop camera processes
pkill -f rpicam-vid

# Wait for camera to be released
sleep 2

# Test camera
rpicam-hello --list-cameras

# Start streaming
./scripts/start-camera.sh --profile night

echo "Camera reset complete"
```

## Getting Help

### Before Asking for Help
1. Check this troubleshooting guide
2. Run diagnostic commands
3. Check system logs
4. Verify hardware connections
5. Test with minimal configuration

### Information to Provide
When asking for help, include:
- Raspberry Pi model and OS version
- Camera module type
- Error messages and logs
- Steps to reproduce the issue
- Output of diagnostic commands

### Useful Resources
- [Raspberry Pi Documentation](https://www.raspberrypi.org/documentation/)
- [libcamera Documentation](https://libcamera.org/)
- [SRS Documentation](https://github.com/ossrs/srs)
- [Docker Documentation](https://docs.docker.com/)
