# 🚀 Deployment Guide

This guide provides step-by-step instructions for deploying the Pi Camera Streaming system on a Raspberry Pi 5.

## 📋 Prerequisites

### Hardware Requirements
- **Raspberry Pi 5** (4GB+ RAM recommended)
- **Camera Module 3** (Wide or Standard)
- **MicroSD Card** (32GB+ Class 10)
- **Power Supply** (5V 3A USB-C)
- **Network Connection** (Ethernet or WiFi)

### Software Requirements
- **Raspberry Pi OS** (64-bit, latest version)
- **Internet Connection** for initial setup

## 🔧 Installation Steps

### 1. Initial Pi Setup

1. **Flash Raspberry Pi OS** to microSD card using [Raspberry Pi Imager](https://www.raspberrypi.org/downloads/)
2. **Enable SSH** and configure WiFi (if using WiFi) in the imager
3. **Boot the Pi** and connect via SSH or directly

### 2. Clone and Setup

```bash
# Clone the repository
git clone https://github.com/CiscoPonce/pi-camera-streaming.git
cd pi-camera-streaming

# Make scripts executable
chmod +x scripts/*.sh

# Run the automated setup
./scripts/setup.sh
```

### 3. Configure Environment

```bash
# Edit the environment file
nano .env

# Set your preferred settings:
# STREAM_NAME=cam
# CAMERA_WIDTH=1280
# CAMERA_HEIGHT=720
# CAMERA_FPS=30
# CAMERA_BITRATE=6000000
```

### 4. Start Services

```bash
# Start Docker containers
docker compose up -d

# Verify services are running
docker compose ps

# Test the setup
./scripts/test-setup.sh
```

### 5. Start Streaming

```bash
# Start camera streaming
./scripts/start-camera.sh

# Or with specific profile
./scripts/start-camera.sh --profile day
```

## 🌐 Accessing the Stream

Once running, access your stream at:

- **Web Interface**: `http://[PI_IP_ADDRESS]/`
- **Direct Stream**: `http://[PI_IP_ADDRESS]:8081/live/cam.flv`
- **RTMP**: `rtmp://[PI_IP_ADDRESS]:1935/live/cam`

## ⚙️ Configuration Options

### Performance Profiles

| Profile | Resolution | Framerate | Bitrate | Use Case |
|---------|------------|-----------|---------|----------|
| `day` | 1920×1080 | 25 fps | 8 Mbps | High quality, good lighting |
| `night` | 1280×720 | 30 fps | 4 Mbps | Low light conditions |
| `low-latency` | 1280×720 | 60 fps | 6 Mbps | Minimal delay |

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `STREAM_NAME` | `cam` | Stream identifier |
| `CAMERA_WIDTH` | `1280` | Video width |
| `CAMERA_HEIGHT` | `720` | Video height |
| `CAMERA_FPS` | `30` | Frames per second |
| `CAMERA_BITRATE` | `6000000` | Bitrate in bps |
| `SRS_HOST` | `localhost` | SRS server host |
| `SRS_PORT` | `1935` | SRS server port |

## 🔄 Service Management

### Manual Control

```bash
# Start streaming
./scripts/start-camera.sh

# Stop streaming
pkill -f rpicam-vid

# Restart services
docker compose restart

# View logs
docker compose logs -f
```

### Systemd Service

```bash
# Enable auto-start on boot
sudo systemctl enable pi-camera-streaming

# Start service
sudo systemctl start pi-camera-streaming

# Check status
sudo systemctl status pi-camera-streaming

# View logs
sudo journalctl -u pi-camera-streaming -f
```

## 🐛 Troubleshooting

### Common Issues

**Camera not detected**:
```bash
# Check camera connection
./scripts/test-setup.sh

# Verify camera is enabled
sudo raspi-config
# Navigate to: Interface Options > Camera > Enable
```

**Stream not starting**:
```bash
# Check Docker services
docker compose ps

# Restart services
docker compose restart

# Check logs
docker compose logs srs
```

**High latency**:
```bash
# Use low-latency profile
./scripts/start-camera.sh --profile low-latency

# Check network connection
ping -c 4 8.8.8.8
```

**Web interface not loading**:
```bash
# Check nginx container
docker compose logs cam-viewer

# Verify port 80 is accessible
curl -I http://localhost/
```

### Performance Tuning

**For better performance**:
1. Use Ethernet instead of WiFi
2. Ensure adequate power supply (5V 3A)
3. Use high-quality microSD card (Class 10+)
4. Close unnecessary applications
5. Use performance profile for CPU governor

**For lower latency**:
1. Use `low-latency` profile
2. Reduce resolution if needed
3. Ensure stable network connection
4. Use wired connection

## 📊 Monitoring

### System Monitoring

```bash
# Check system resources
htop

# Monitor network usage
iftop

# Check disk usage
df -h

# View system logs
sudo journalctl -f
```

### Stream Monitoring

```bash
# Check stream status
curl -s http://localhost:1985/api/v1/streams/ | jq

# Monitor stream quality
ffprobe http://localhost:8081/live/cam.flv
```

## 🔒 Security Considerations

### Network Security

1. **Change default passwords**
2. **Use SSH keys** instead of passwords
3. **Configure firewall** (UFW is configured by setup script)
4. **Regular updates**: `sudo apt update && sudo apt upgrade`

### Access Control

1. **Limit network access** to trusted networks
2. **Use VPN** for remote access
3. **Monitor access logs**
4. **Regular security updates**

## 📈 Performance Metrics

### Expected Performance

- **Latency**: 200-500ms (WebRTC), 1-2s (FLV)
- **CPU Usage**: 15-25% (Pi 5)
- **Memory**: 200-400MB total
- **Network**: 3-12 Mbps depending on profile
- **Uptime**: 99%+ with auto-recovery

### Optimization Tips

1. **Use performance profile** for CPU governor
2. **Increase GPU memory** if needed
3. **Monitor temperature** and add cooling if necessary
4. **Use high-quality power supply**
5. **Optimize network settings**

---

*For additional support, please refer to the main README.md or create an issue on GitHub.*
