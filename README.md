# Raspberry Pi 5 Camera Streaming Project

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi 5](https://img.shields.io/badge/Raspberry%20Pi-5-red.svg)](https://www.raspberrypi.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue.svg)](https://www.docker.com/)

A professional, low-latency camera streaming solution for Raspberry Pi 5 with Camera Module 3, featuring WebRTC support, Docker containerization, and an intuitive web viewer. Built with performance optimization and ease of deployment in mind.

**Created by [CiscoPonce](https://github.com/CiscoPonce)**

## 🎯 Project Showcase

This project demonstrates advanced skills in:
- **Embedded Systems Development** with Raspberry Pi 5
- **Real-time Video Streaming** using WebRTC and modern protocols
- **Docker Containerization** for scalable deployment
- **System Administration** with automated setup and monitoring
- **Web Development** with responsive, modern interfaces
- **Performance Optimization** for resource-constrained environments

Perfect for **IoT applications**, **security monitoring**, **live streaming**, and **educational projects**.

## 🛠️ Technologies Used

- **Hardware**: Raspberry Pi 5, Camera Module 3
- **Streaming**: SRS (Simple Realtime Server), WebRTC, RTMP, HTTP-FLV
- **Containerization**: Docker, Docker Compose
- **Web Server**: Nginx with optimized configuration
- **Camera Interface**: libcamera, rpicam-vid
- **Video Processing**: FFmpeg with hardware acceleration
- **Frontend**: HTML5, JavaScript, WebRTC API
- **System**: Linux, systemd, bash scripting
- **Performance**: Hardware-accelerated encoding, optimized profiles

## ✨ Features

- **🚀 Low Latency Streaming**: WebRTC for sub-500ms latency with HTTP-FLV fallback
- **🍓 Raspberry Pi 5 Optimized**: Specifically designed for Pi 5 with Camera Module 3
- **🐳 Docker Containerized**: Easy deployment and management with Docker Compose
- **🌐 Professional Web Viewer**: Responsive, modern web interface with real-time status
- **📡 Multiple Protocols**: Support for WebRTC, HTTP-FLV, and RTMP streaming
- **🔄 Auto-restart**: Container restart policies for reliability
- **⚡ Performance Profiles**: Day/night/low-latency modes for different use cases
- **🛠️ Easy Setup**: One-command installation with automated configuration
- **📊 System Monitoring**: Built-in health checks and performance monitoring
- **🔧 Highly Configurable**: Environment-based configuration with sensible defaults

## 📋 Requirements

### Hardware
- **Raspberry Pi 5** (4GB+ RAM recommended)
- **Raspberry Pi Camera Module 3**
- **MicroSD card** (32GB+ Class 10 recommended)
- **Network connection** (Ethernet recommended for stability)

### Software
- **Raspberry Pi OS** (64-bit recommended)
- **Docker and Docker Compose**
- **libcamera tools** (included in Pi OS)

## 🚀 Quick Start

### Option 1: Using Make (Easiest)

```bash
# Clone and setup everything
git clone https://github.com/CiscoPonce/pi-camera-streaming.git
cd pi-camera-streaming
make setup

# After reboot, start everything
make start
make start-camera

# View stream at http://<PI_IP>/
```

### Option 2: Automated Setup (Recommended)

1. **Clone the repository**
   ```bash
   git clone https://github.com/CiscoPonce/pi-camera-streaming.git
   cd pi-camera-streaming
   ```

2. **Run the setup script**
   ```bash
   chmod +x scripts/setup.sh
   ./scripts/setup.sh
   ```

3. **Reboot the system** (required for camera and Docker changes)
   ```bash
   sudo reboot
   ```

4. **After reboot, start the services**
   ```bash
   docker-compose up -d
   ```

5. **Start camera streaming**
   ```bash
   ./scripts/start-camera.sh
   ```

6. **Test the setup** (optional)
   ```bash
   ./scripts/test-setup.sh
   ```

7. **View the stream**
   Open your browser and navigate to `http://<PI_IP>/`

### Option 3: Manual Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/CiscoPonce/pi-camera-streaming.git
   cd pi-camera-streaming
   ```

2. **Install dependencies**
   ```bash
   sudo apt update
   sudo apt install -y docker.io docker-compose-plugin libcamera-tools ffmpeg
   sudo usermod -aG docker $USER
   ```

3. **Enable camera interface**
   ```bash
   sudo raspi-config
   # Navigate to: Interface Options > Camera > Enable
   ```

4. **Configure environment**
   ```bash
   cp env.example .env
   # Edit .env with your settings (optional)
   ```

5. **Start the streaming services**
   ```bash
   docker-compose up -d
   ```

6. **Start camera streaming**
   ```bash
   ./scripts/start-camera.sh
   ```

7. **Test the setup** (optional)
   ```bash
   ./scripts/test-setup.sh
   ```

8. **View the stream**
   Open your browser and navigate to `http://<PI_IP>/`

## 🏗️ Architecture

### System Components

- **SRS (Simple Realtime Server)**: Handles WebRTC, HTTP-FLV, and RTMP streaming
- **Nginx**: Serves the professional web viewer interface
- **Camera Publisher**: Uses `rpicam-vid` to capture and stream video with hardware acceleration
- **Docker Containers**: Isolated, scalable, and easy-to-manage services

### Network Architecture

| Port | Service | Protocol | Description |
|------|---------|----------|-------------|
| 80 | Web Viewer | HTTP | Professional web interface |
| 1935 | RTMP | TCP | Real-time streaming protocol |
| 1985 | SRS API | HTTP | Server management and WebRTC signaling |
| 8081 | HTTP Console | HTTP | FLV playback and server console |
| 8000-8100 | WebRTC ICE | UDP | Interactive connectivity establishment |

## Configuration

### Camera Settings

The camera streaming can be configured in `scripts/start-camera.sh`:

```bash
# Resolution and framerate
WIDTH=1280
HEIGHT=720
FPS=30

# Bitrate (adjust based on network capacity)
BITRATE=6000000  # 6 Mbps

# Keyframe interval (affects latency)
GOP=60  # 2 seconds at 30fps
```

### Performance Tuning

For optimal performance on Raspberry Pi 5:

- **Day profile**: 1920×1080 @ 25-30 fps, 8-12 Mbps
- **Night profile**: 1280×720 @ 30-60 fps, 4-8 Mbps
- **Low latency**: Reduce GOP size to 1-2 seconds
- **High quality**: Increase bitrate and resolution

## Usage

### Using Make Commands (Recommended)

```bash
# View all available commands
make help

# Start all services
make start

# Start camera streaming
make start-camera

# Check status
make status

# View logs
make logs

# Run tests
make test

# Stop everything
make stop
```

### Manual Commands

```bash
# Start all services
docker-compose up -d

# Start camera streaming
./scripts/start-camera.sh

# Check status
docker-compose ps
```

### Stopping the Stream

```bash
# Stop camera streaming
pkill rpicam-vid

# Stop all services
docker-compose down
```

### Viewing the Stream

1. **Web Browser**: Navigate to `http://<PI_IP>/`
2. **Direct FLV**: `http://<PI_IP>:8081/live/cam.flv`
3. **WebRTC API**: `http://<PI_IP>:1985/rtc/v1/play/`

## Troubleshooting

### Common Issues

**Setup Issues**
- **Permission denied**: Make sure scripts are executable: `chmod +x scripts/*.sh`
- **Docker not found**: Run `sudo usermod -aG docker $USER` and log out/in
- **Camera not detected**: Enable camera in `sudo raspi-config` and reboot

**No video in browser**
- Check if camera is connected: `libcamera-hello --list-cameras`
- Verify SRS is running: `docker logs srs`
- Check camera streaming: `ps aux | grep rpicam-vid`
- Test direct FLV stream: `http://<PI_IP>:8081/live/cam.flv`

**High CPU usage**
- Use night profile: `./scripts/start-camera.sh --profile night`
- Reduce resolution or framerate
- Lower bitrate settings
- Check for background processes

**Network issues**
- Ensure ports are not blocked by firewall
- Check network connectivity
- Verify router port forwarding (if accessing remotely)
- Test local access first: `http://localhost/`

**Container issues**
- Check container status: `docker-compose ps`
- View logs: `docker logs srs` or `docker logs cam-viewer`
- Restart containers: `docker-compose restart`

### Testing Your Setup

Run the test script to verify everything is working:

```bash
./scripts/test-setup.sh
```

This will check:
- Camera detection and availability
- Docker installation and permissions
- Container status
- SRS API connectivity
- Web viewer accessibility
- Network ports
- System resources (CPU temperature, memory)

### Logs

```bash
# View SRS logs
docker logs srs

# View nginx logs
docker logs cam-viewer

# Check camera streaming
journalctl -u camera-streaming
```

## Development

### Project Structure

```
pi-camera-streaming/
├── Makefile               # Convenient commands for common tasks
├── docker-compose.yml     # Container orchestration
├── env.example            # Environment configuration template
├── viewer/                # Web viewer files
│   ├── index.html        # Main viewer page
│   └── srs.player.js     # SRS WebRTC player
├── scripts/
│   ├── start-camera.sh   # Camera streaming script
│   ├── setup.sh          # Initial setup script
│   └── test-setup.sh     # System verification script
├── config/
│   ├── srs.conf          # SRS streaming server configuration
│   ├── nginx.conf        # Nginx web server configuration
│   └── mediamtx.yml      # MediaMTX configuration (alternative)
└── docs/                 # Additional documentation
    ├── PERFORMANCE.md    # Performance optimization guide
    └── TROUBLESHOOTING.md # Troubleshooting guide
```

### Adding Features

1. **New streaming protocols**: Modify SRS configuration
2. **Enhanced viewer**: Update files in `viewer/` directory
3. **Authentication**: Add nginx auth configuration
4. **Recording**: Integrate with SRS recording features

## Performance Monitoring

### System Metrics

```bash
# CPU and temperature
vcgencmd measure_temp
top -b -n1 | head -20

# Network usage
iftop -i eth0

# Disk usage
df -h
```

### Streaming Metrics

- **Latency**: Measure from camera to viewer
- **Bitrate**: Monitor actual vs configured
- **Frame drops**: Check SRS logs for errors
- **CPU usage**: Should stay below 25% average

## Security Considerations

- **LAN-only exposure**: Streaming services are not exposed to WAN
- **Firewall**: Ensure only necessary ports are open
- **Updates**: Keep system and containers updated
- **Authentication**: Consider adding auth for production use

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly on Raspberry Pi 5
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For issues and questions:
- Check the troubleshooting section
- Review the logs
- Open an issue on GitHub

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**CiscoPonce**
- GitHub: [@CiscoPonce](https://github.com/CiscoPonce)
- Project Link: [https://github.com/CiscoPonce/pi-camera-streaming](https://github.com/CiscoPonce/pi-camera-streaming)

## 🙏 Acknowledgments

- [SRS](https://github.com/ossrs/srs) for the streaming server
- [Raspberry Pi Foundation](https://www.raspberrypi.org/) for the hardware
- [libcamera](https://libcamera.org/) for camera support
- [Docker](https://www.docker.com/) for containerization
- [Nginx](https://nginx.org/) for the web server
