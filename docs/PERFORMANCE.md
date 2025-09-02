# Performance Optimization Guide

This document provides detailed guidance on optimizing the Pi Camera Streaming project for different use cases and hardware configurations.

## Hardware Requirements

### Minimum Requirements
- Raspberry Pi 5 (4GB RAM minimum)
- Raspberry Pi Camera Module 3
- 32GB+ MicroSD card (Class 10 or better)
- Ethernet connection (recommended)

### Recommended Requirements
- Raspberry Pi 5 (8GB RAM)
- Raspberry Pi Camera Module 3
- 64GB+ MicroSD card (Class 10 or better)
- Fast Ethernet or WiFi 6 connection
- Active cooling (optional but recommended for sustained high performance)

## Performance Profiles

### Day Profile (High Quality)
```bash
./scripts/start-camera.sh --profile day
```
- **Resolution**: 1920×1080
- **Framerate**: 25 fps
- **Bitrate**: 8 Mbps
- **GOP**: 4 seconds
- **Use case**: High-quality recording, good lighting conditions

### Night Profile (Balanced)
```bash
./scripts/start-camera.sh --profile night
```
- **Resolution**: 1280×720
- **Framerate**: 30 fps
- **Bitrate**: 4 Mbps
- **GOP**: 2 seconds
- **Use case**: Low-light conditions, balanced quality/performance

### Low Latency Profile (Real-time)
```bash
./scripts/start-camera.sh --profile low-latency
```
- **Resolution**: 1280×720
- **Framerate**: 60 fps
- **Bitrate**: 6 Mbps
- **GOP**: 0.5 seconds
- **Use case**: Real-time monitoring, interactive applications

## System Optimization

### CPU Performance
```bash
# Set CPU governor to performance
echo 'GOVERNOR="performance"' | sudo tee /etc/default/cpufrequtils

# Disable unnecessary services
sudo systemctl disable bluetooth
sudo systemctl disable hciuart
```

### Memory Optimization
```bash
# Increase GPU memory split
echo "gpu_mem=128" | sudo tee -a /boot/config.txt

# Optimize swap usage
echo "vm.swappiness=10" | sudo tee -a /etc/sysctl.conf
```

### Network Optimization
```bash
# Optimize network buffers
echo "net.core.rmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.core.wmem_max = 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_rmem = 4096 87380 16777216" | sudo tee -a /etc/sysctl.conf
echo "net.ipv4.tcp_wmem = 4096 65536 16777216" | sudo tee -a /etc/sysctl.conf
```

## Camera Settings

### Exposure and Gain
```bash
# Manual exposure for consistent performance
rpicam-vid --exposure fixed --gain 1.0

# Auto exposure with limits
rpicam-vid --exposure auto --gain auto --metering average
```

### White Balance
```bash
# Fixed white balance for consistent colors
rpicam-vid --awb off --awbgains 1.0,1.0

# Auto white balance
rpicam-vid --awb auto
```

### Focus
```bash
# Fixed focus (recommended for streaming)
rpicam-vid --lens-position 0

# Auto focus (use sparingly)
rpicam-vid --autofocus-mode continuous
```

## Streaming Optimization

### SRS Configuration
```conf
# Optimize for low latency
vhost __defaultVhost__ {
    rtc {
        enabled on;
        rtmp_to_rtc on;
        rtc_to_rtmp on;
    }
    
    tcp_nodelay on;
    min_latency on;
}
```

### WebRTC Settings
```javascript
// Optimize WebRTC connection
const pc = new RTCPeerConnection({
    iceServers: [
        { urls: 'stun:stun.l.google.com:19302' }
    ],
    iceCandidatePoolSize: 10
});
```

## Monitoring Performance

### System Metrics
```bash
# CPU and temperature
vcgencmd measure_temp
top -b -n1 | head -20

# Memory usage
free -h
cat /proc/meminfo

# Network usage
iftop -i eth0
```

### Streaming Metrics
```bash
# SRS statistics
curl -s http://localhost:1985/api/v1/summaries | jq

# Camera process
ps aux | grep rpicam-vid

# Network connections
netstat -tulpn | grep -E "(1935|1985|8081)"
```

## Troubleshooting Performance Issues

### High CPU Usage
1. **Reduce resolution**: Lower from 1080p to 720p
2. **Reduce framerate**: Lower from 60fps to 30fps
3. **Optimize encoding**: Use hardware acceleration
4. **Check background processes**: Disable unnecessary services

### High Memory Usage
1. **Increase GPU memory**: Set `gpu_mem=128` in `/boot/config.txt`
2. **Optimize buffers**: Reduce buffer sizes in configuration
3. **Monitor processes**: Check for memory leaks

### Network Issues
1. **Check bandwidth**: Ensure sufficient network capacity
2. **Optimize bitrate**: Match bitrate to network capacity
3. **Use wired connection**: Ethernet is more stable than WiFi
4. **Check firewall**: Ensure ports are not blocked

### Latency Issues
1. **Reduce GOP size**: Lower keyframe interval
2. **Use WebRTC**: Lower latency than HTTP-FLV
3. **Optimize network**: Use wired connection
4. **Check encoding**: Use low-latency encoding settings

## Benchmarking

### Performance Test Script
```bash
#!/bin/bash
# performance-test.sh

echo "Starting performance test..."

# Test different profiles
profiles=("day" "night" "low-latency")

for profile in "${profiles[@]}"; do
    echo "Testing profile: $profile"
    
    # Start streaming
    ./scripts/start-camera.sh --profile $profile &
    STREAM_PID=$!
    
    # Wait for stream to stabilize
    sleep 10
    
    # Measure performance
    CPU_USAGE=$(top -b -n1 | grep "Cpu(s)" | awk '{print $2}' | cut -d'%' -f1)
    TEMP=$(vcgencmd measure_temp | cut -d'=' -f2 | cut -d"'" -f1)
    MEMORY=$(free | grep Mem | awk '{printf "%.1f", $3/$2 * 100.0}')
    
    echo "Profile: $profile"
    echo "CPU Usage: ${CPU_USAGE}%"
    echo "Temperature: ${TEMP}°C"
    echo "Memory Usage: ${MEMORY}%"
    echo "---"
    
    # Stop streaming
    kill $STREAM_PID
    sleep 5
done
```

## Best Practices

1. **Start with low-latency profile** for real-time applications
2. **Use day profile** for high-quality recording
3. **Monitor system temperature** to prevent throttling
4. **Use wired network** for stable streaming
5. **Regular system updates** for optimal performance
6. **Monitor logs** for performance issues
7. **Test different settings** to find optimal configuration

## Performance Targets

### Latency Targets
- **WebRTC**: < 500ms end-to-end
- **HTTP-FLV**: < 2 seconds
- **HLS**: < 10 seconds

### Resource Usage Targets
- **CPU**: < 25% average
- **Memory**: < 50% usage
- **Temperature**: < 70°C
- **Network**: < 80% of available bandwidth

### Quality Targets
- **1080p**: 8-12 Mbps bitrate
- **720p**: 4-8 Mbps bitrate
- **480p**: 2-4 Mbps bitrate
