# Raspberry Pi 5 Camera Streaming Project

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Raspberry Pi 5](https://img.shields.io/badge/Raspberry%20Pi-5-red.svg)](https://www.raspberrypi.org/)
[![Docker](https://img.shields.io/badge/Docker-Containerized-blue.svg)](https://www.docker.com/)
[![OpenVINO AI](https://img.shields.io/badge/OpenVINO-Accelerated-brightgreen.svg)](https://docs.openvino.ai/)
[![System Test](https://img.shields.io/badge/System%20Test-7%2F7%20Passed-success.svg)](./scripts/test-setup.sh)

A professional, sub-500ms low-latency camera streaming solution for **Raspberry Pi 5 with Camera Module 3 (IMX708)**, featuring **OpenVINO FP16 Accelerated YOLO AI Object Detection**, WebRTC support, Docker containerization, and an intuitive web viewer.

**Created by [CiscoPonce](https://github.com/CiscoPonce)**

---

## 🏆 Key Achievements & Verified System Status

```text
[SUCCESS] 7/7 System Diagnostic Tests Passed!
--------------------------------------------------
[✓] Camera hardware: Sony IMX708 (Module 3) @ 60 FPS (PiSP RP1 ISP)
[✓] Docker Engine & Container Orchestration: Active
[✓] SRS Realtime Media Server: Active (WebRTC / RTMP / FLV)
[✓] Web Viewer Interface (Nginx): Accessible on Port 80
[✓] OpenVINO AI WebSocket Service: Active on Port 8765
[✓] Network Port Access: All 5 required ports open
[✓] System Health: CPU 57.85°C | RAM 1.7GB/15GB (13.3GB free)
```

### Highlights
* **Native Pi 5 Hardware ISP (`rpi/pisp`):** Built custom `libcamera v0.7.1` + `rpicam-apps` for Raspberry Pi 5 RP1 CFE controller & PiSP hardware block (`/dev/media0` & `/dev/media1`).
* **Real-time OpenVINO YOLO AI Overlay:** Runs **YOLO11 Small (`yolo11s_openvino_model`)** in OpenVINO FP16 format, streaming live JSON bounding boxes over WebSockets (`ws://...:8765`) without video stutter.
* **Sub-500ms WebRTC Streaming:** Ultra-low latency streaming with automatic high-reliability HTTP-FLV fallback.

---

## 🎯 Project Showcase

This project demonstrates advanced engineering skills in:
- **Embedded Systems Development** with Raspberry Pi 5 & Camera Module 3
- **Edge Computer Vision & AI** using OpenVINO FP16 & YOLO11
- **Real-time Video Streaming** using WebRTC, RTMP, and HTTP-FLV
- **Docker Containerization** for scalable deployment
- **Asynchronous System Architecture** (Decoupled media streaming & AI inference)
- **Performance Optimization** for ARM NEON SIMD vector hardware

---

## 🛠️ Technologies Used

- **Hardware**: Raspberry Pi 5 (16GB), Camera Module 3 (Sony IMX708)
- **AI / Computer Vision**: OpenVINO 2026 FP16 Engine, Ultralytics YOLO11 Small, OpenCV, WebSockets
- **Streaming Engine**: SRS (Simple Realtime Server v5), WebRTC, RTMP, HTTP-FLV
- **Containerization**: Docker, Docker Compose
- **Web Server**: Nginx with optimized reverse proxy
- **Camera Pipeline**: Native Pi 5 PiSP `libcamera v0.7.1`, `rpicam-vid`
- **Video Encoding**: Hardware-accelerated H.264 / FFmpeg
- **Frontend UI**: HTML5, Modern Vanilla CSS, WebRTC API, Canvas Bounding Box Renderer

---

## ✨ Features

- **🚀 Sub-500ms WebRTC Streaming**: Direct WebRTC peer connections with instant HTTP-FLV fallback.
- **🤖 Real-time OpenVINO YOLO11 Overlay**: Live target detection overlay (`person`, `car`, `bicycle`, etc.) toggleable directly from the web browser.
- **🍓 Raspberry Pi 5 PiSP Hardware Native**: Custom compiled `rpi/pisp` driver for the Pi 5 RP1 controller.
- **🐳 Docker Containerized**: Isolated SRS and Nginx web services.
- **🌐 Modern Web Viewer**: Responsive dark-mode UI with live status indicators, mute toggles, and fullscreen mode.
- **⚡ Performance Profiles**: Low-latency (60 FPS), day (1080p), and night profiles.
- **📊 100% Automated Testing**: Diagnostic script (`./scripts/test-setup.sh`) verifying end-to-end component health.

---

## 📋 Network Ports & Service Architecture

| Port | Service | Protocol | Description |
| :--- | :--- | :--- | :--- |
| **80** | Web Viewer | HTTP | Modern HTML5 Pi Camera Viewer UI |
| **8765** | YOLO AI Service | WebSocket | Real-time OpenVINO YOLO detection JSON stream |
| **1935** | RTMP Ingest | TCP | Live video stream ingest |
| **1985** | SRS API | HTTP | WebRTC signaling & server management API |
| **8081** | HTTP Console | HTTP | FLV playback endpoint (`/live/cam.flv`) & console |
| **8000-8100**| WebRTC ICE | UDP | Media candidate negotiation |

---

## 🚀 Quick Start

### 1. Clone & Setup Dependencies
```bash
git clone https://github.com/CiscoPonce/pi-camera-streaming.git
cd pi-camera-streaming

# Install required build tools & Python packages
sudo apt update && sudo apt install -y \
  build-essential git cmake meson ninja-build libboost-dev \
  libgnutls28-dev openssl libtiff-dev pybind11-dev python3-yaml python3-ply \
  libglib2.0-dev libgstreamer-plugins-base1.0-dev libdrm-dev libexif-dev \
  libepoxy-dev libjpeg-dev libpng-dev libpisp-common libpisp1 \
  python3-pip python3-opencv python3-websockets python3-numpy

pip3 install --break-system-packages ultralytics openvino onnxruntime
```

### 2. Build Raspberry Pi 5 PiSP `libcamera` & `rpicam-apps`
```bash
# Build Raspberry Pi libcamera with Pi 5 PiSP support
git clone https://github.com/raspberrypi/libcamera.git /tmp/libcamera
cd /tmp/libcamera
meson setup build --buildtype=release -Dpipelines=rpi/vc4,rpi/pisp -Dipas=rpi/vc4,rpi/pisp -Dv4l2=true -Dpycamera=disabled -Dgstreamer=disabled -Ddocumentation=disabled
ninja -C build && sudo ninja -C build install && sudo ldconfig

# Build rpicam-apps
git clone https://github.com/raspberrypi/rpicam-apps.git /tmp/rpicam-apps
cd /tmp/rpicam-apps
meson setup build --buildtype=release -Denable_libav=disabled -Denable_qt=disabled -Denable_opencv=disabled -Denable_tflite=disabled
ninja -C build && sudo ninja -C build install && sudo ldconfig
```

### 3. Start Streaming & AI Services
```bash
cd pi-camera-streaming

# Start Docker containers (SRS + Nginx)
docker compose up -d

# Launch 60 FPS Hardware Camera Stream
./scripts/start-camera.sh --profile low-latency &

# Launch OpenVINO YOLO AI WebSocket Service
python3 ai_vision/yolo_service.py &
```

### 4. Run System Diagnostic Test
```bash
./scripts/test-setup.sh
```

---

## 🌐 Accessing the Stream

Open your browser from any device on your local network:
* **Web UI (Pi Camera Viewer):** `http://<PI_IP>/`
* **Direct FLV Stream:** `http://<PI_IP>:8081/live/cam.flv`
* **SRS Console:** `http://<PI_IP>:8081/`

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👨‍💻 Author

**CiscoPonce**
- GitHub: [@CiscoPonce](https://github.com/CiscoPonce)
- Repository: [https://github.com/CiscoPonce/pi-camera-streaming](https://github.com/CiscoPonce/pi-camera-streaming)
